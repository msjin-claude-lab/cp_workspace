#!/usr/bin/env node
/**
 * OMC HUD - 게이지 문자 복원 래퍼
 *
 * OMC는 출력 직전 sanitizeOutput()에서 블록 문자를 ASCII로 무조건 치환한다
 * (node_modules/oh-my-claude-sisyphus/dist/hud/sanitize.js 의 replaceUnicodeBlocks).
 * 설정으로 끌 수 없어 여기서 되돌린다.
 *
 *   #  ->  █      =  ->  ▓      -  ->  ░
 *
 * 왜 래퍼인가: 패키지를 직접 고치면 `npm i -g` 할 때마다 날아간다.
 * 왜 스폰이 아닌가: 같은 프로세스에서 stdout만 가로채면 node 기동 비용이 한 번 더 들지 않는다.
 *
 * 되돌리려면 settings.json 의 statusLine.command 를
 * `node C:/Users/M/.claude/hud/omc-hud.mjs` 로 바꾸면 된다.
 */

import { spawnSync } from "node:child_process";
import { existsSync, writeSync } from "node:fs";
import { Readable } from "node:stream";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * 감쌀 대상인 omc-hud.mjs 를 찾는다.
 *
 * 보통은 이 스크립트 옆에 있다(~/.claude/hud/). 저장소의 env/hud/ 사본처럼
 * 다른 위치에서 실행되면 형제 파일이 없으므로 설정 디렉터리도 본다.
 * 둘 다 없으면 던지지 않고 null 을 돌려준다 — 상태바가 스택 트레이스와 함께
 * 빈 채로 남는 것보다 한 줄짜리 안내가 낫다.
 */
function findHud() {
  const configDir = process.env.CLAUDE_CONFIG_DIR?.trim() || join(homedir(), ".claude");
  for (const candidate of [join(__dirname, "omc-hud.mjs"), join(configDir, "hud", "omc-hud.mjs")]) {
    if (existsSync(candidate)) return candidate;
  }
  return null;
}

// 게이지 한 칸: ANSI SGR 시퀀스(\x1b[...m) 또는 ASCII 게이지 문자.
// 대괄호 안이 '오직' 그것들로만 이루어졌을 때에만 게이지로 인정한다.
//
// 안쪽만 보는 이유: `-` 는 브랜치명(feat-x), 모델 ID(claude-opus-5), 날짜(2026-11-11)
// 에도 쓰인다. 통째로 치환하면 그런 텍스트가 깨진다.
// `[OMC#5.8.4]` 처럼 글자·점이 섞인 대괄호는 이 패턴에 걸리지 않는다.
const GAUGE_SPAN = /\[((?:\x1b\[[0-9;]*m|[#=-])+)\]/g;

const CELL = { "#": "\u2588", "=": "\u2593", "-": "\u2591" };

export function restoreGauges(text) {
  return text.replace(GAUGE_SPAN, (span, inner) => {
    // ANSI 시퀀스는 건드리지 않고 게이지 문자만 바꾼다.
    const restored = inner.replace(/\x1b\[[0-9;]*m|[#=-]/g, (token) =>
      token.startsWith("\x1b") ? token : CELL[token],
    );
    return `[${restored}]`;
  });
}

// ---------------------------------------------------------------------------
// 첫 줄 재구성
// ---------------------------------------------------------------------------
// 상태창은 상태줄이 여러 줄이면 **첫 줄 하나만** 보여 주고 나머지를 `… (+N more lines)`
// 로 접는다(Claude Code 내부: `(+${lines.length - 1} more lines)`).
// 그래서 늘 보고 싶은 값은 전부 첫 줄에 있어야 한다.
//
// OMC는 ctx를 둘째 줄 맨 끝에, 모델과 effort를 따로 둔다. 여기서 끌어올리고 합친다.

const SEP = "\x1b[2m | \x1b[0m";
const CYAN = "\x1b[36m";
const DIM = "\x1b[2m";
const RESET = "\x1b[0m";

/** 앞의 구분자(' | ', ANSI 포함)까지 함께 지우기 위한 접두 패턴 */
const LEAD_SEP = "(?:(?:\\x1b\\[[0-9;]*m|\\s)*\\|(?:\\x1b\\[[0-9;]*m|\\s)*)?";

/**
 * 모델과 effort를 하나로 합쳐 `Opus 5 Medium` 형태로 만든다. effort는 흐리게(dim) 둔다.
 * 둘 다 원래 자리에서 지우고, 합친 문자열을 돌려준다.
 *
 * @returns {{text: string, model: string|null}}
 */
function takeModel(text) {
  // 공백 자리에 U+00A0(줄바꿈 금지 공백)이 오는 PC가 있다(개인 PC 실측). JS의 \s는 U+00A0도 잡는다.
  const name = text.match(/Model:\s*([^\x1b\n|]+)/)?.[1]?.trim() ?? null;
  const level = text.match(/effort:([a-z]+)/)?.[1] ?? null;

  let rest = text;
  rest = rest.replace(new RegExp(`${LEAD_SEP}(?:\\x1b\\[[0-9;]*m)*Model:\\s*[^\\x1b\\n|]+(?:\\x1b\\[[0-9;]*m)*`), "");
  rest = rest.replace(new RegExp(`${LEAD_SEP}(?:\\x1b\\[[0-9;]*m)*effort:[a-z]+(?:\\x1b\\[[0-9;]*m)*`), "");

  if (!name) return { text, model: null };
  const effort = level ? ` ${DIM}${level[0].toUpperCase()}${level.slice(1)}${RESET}` : "";
  return { text: rest, model: `${CYAN}${name}${RESET}${effort}` };
}

/**
 * ctx 구간을 잘라낸다. `ctx:` 부터 줄 끝까지가 한 덩어리다.
 * OMC는 hud-config.json 배치에 따라 ctx를 다른 항목 뒤에 붙이기도 하고(사내망 PC),
 * 혼자 한 줄에 두기도 한다(개인 PC). 어느 쪽이든 잘라내 맨 위로 올린다.
 *
 * @returns {{text: string, ctx: string|null}}
 */
function takeCtx(text) {
  const lines = text.split("\n");
  const row = lines.findIndex((l) => l.includes("ctx:"));
  if (row === -1) return { text, ctx: null };

  const at = lines[row].indexOf("ctx:");
  const ctx = lines[row].slice(at).trimEnd();
  const head = lines[row].slice(0, at).replace(/(?:\x1b\[[0-9;]*m|\s)*\|(?:\x1b\[[0-9;]*m|\s)*$/, "");

  lines[row] = head; // ctx뿐인 줄이면 빈 줄이 되고, moveCtxFirst가 빈 줄을 버린다
  return { text: lines.join("\n"), ctx };
}

/**
 * `[OMC#x.y.z]` 라벨을 잘라낸다. Claude Code 버전을 알면 `[Claude#a.b.c | OMC#x.y.z]`로 만든다.
 */
function takeLabel(text, claudeVersion) {
  const re = new RegExp(`(?:\\x1b\\[[0-9;]*m)*\\[OMC#[^\\]]*\\](?:\\x1b\\[[0-9;]*m)*${"(?:(?:\\x1b\\[[0-9;]*m|\\s)*\\|(?:\\x1b\\[[0-9;]*m|\\s)*)?"}`);
  const m = text.match(re);
  if (!m) return { text, label: null };
  let label = m[0].replace(/(?:\x1b\[[0-9;]*m|\s)*\|(?:\x1b\[[0-9;]*m|\s)*$/, "");
  if (claudeVersion) label = label.replace("[OMC#", `[Claude#${claudeVersion} | OMC#`);
  return { text: text.replace(m[0], ""), label };
}

/**
 * `git status --porcelain=v2 --branch` 출력을 `main M2 +1 ↑1 ↓2` 형태로 만든다.
 *
 *   MN  커밋 안 한 변경이 있는 파일(수정·삭제·이름 변경·git add 한 새 파일). VS Code의 M과 같은 뜻
 *   +N  새 파일(아직 git add 안 함)
 *   ↑N  올릴 커밋(원격보다 앞섬)    ↓N  받을 커밋(원격보다 뒤짐, 마지막 fetch 기준)
 *
 * 기호는 영문 글자로 둔다. ✎ 같은 기호는 동아시아 터미널에서 폭이 모호해 뒤 글자와 겹쳐 보였다.
 * 깨끗하면 브랜치 이름만 남는다.
 *
 * @returns {string|null} 브랜치를 못 읽으면 null
 */
function formatGit(porcelain) {
  const head = porcelain.match(/^# branch\.head (.+)$/m)?.[1]?.trim();
  if (!head) return null;
  const ab = porcelain.match(/^# branch\.ab \+(\d+) -(\d+)$/m);
  const ahead = ab ? Number(ab[1]) : 0;
  const behind = ab ? Number(ab[2]) : 0;
  let changed = 0;
  let untracked = 0;
  for (const line of porcelain.split("\n")) {
    if (/^[12u] /.test(line)) changed++;
    else if (line.startsWith("? ")) untracked++;
  }

  const YELLOW = "\x1b[33m";
  const GREEN = "\x1b[32m";
  const parts = [`${CYAN}${head === "(detached)" ? "HEAD" : head}${RESET}`];
  if (changed) parts.push(`${YELLOW}M${changed}${RESET}`);
  if (untracked) parts.push(`${GREEN}+${untracked}${RESET}`);
  if (ahead) parts.push(`${CYAN}↑${ahead}${RESET}`);
  if (behind) parts.push(`${CYAN}↓${behind}${RESET}`);
  return parts.join(" ");
}

/**
 * 줄 배치를 다시 짠다.
 *
 *   1줄: ctx
 *   2줄: [OMC#x] | 모델 effort | branch | git 상태
 *   3줄: 나머지(사용량 게이지 등)
 *
 * 못 찾은 조각은 건너뛰고, 아무것도 못 찾으면 원본을 그대로 돌려준다.
 */
export function moveCtxFirst(text, claudeVersion = null, gitPorcelain = null) {
  const c = takeCtx(text);
  const m = takeModel(c.text);
  const l = takeLabel(m.text, claudeVersion);
  if (!c.ctx && !m.model && !l.label) return text;

  const rest = l.text.split("\n").map((s) => s.trimEnd()).filter((s) => s.replace(/\x1b\[[0-9;]*m/g, "").trim());
  const branchIdx = rest.findIndex((s) => s.includes("branch:"));
  const omcBranch = branchIdx === -1 ? null : rest.splice(branchIdx, 1)[0];
  // OMC의 `branch:main | !2` 줄을 직접 조회한 git 상태로 바꾼다. 조회에 실패하면 OMC 것을 그대로 쓴다.
  const branch = (gitPorcelain && formatGit(gitPorcelain)) || omcBranch;

  const out = [
    c.ctx,
    [l.label, m.model, branch].filter(Boolean).join(SEP) || null,
    ...rest,
  ].filter(Boolean);
  return out.join("\n") + (text.endsWith("\n") ? "\n" : "");
}

// ---------------------------------------------------------------------------
// stdout 가로채기
// ---------------------------------------------------------------------------
// HUD는 비동기로 동작하고 console.log 로 여러 번 쓸 수 있다. 조각마다 변환하면
// 게이지가 조각 경계에 걸쳤을 때 놓치므로, 전부 모았다가 종료 직전에 한 번 변환한다.

const chunks = [];
const originalWrite = process.stdout.write.bind(process.stdout);

process.stdout.write = (chunk, encoding, callback) => {
  chunks.push(typeof chunk === "string" ? chunk : Buffer.from(chunk).toString("utf8"));
  if (typeof encoding === "function") encoding();
  else if (typeof callback === "function") callback();
  return true;
};

let flushed = false;
function flush() {
  if (flushed) return;
  flushed = true;
  process.stdout.write = originalWrite;

  const raw = chunks.join("");
  if (!raw) return;

  let output;
  try {
    output = moveCtxFirst(restoreGauges(raw), claudeVersion, readGitStatus());
  } catch {
    output = raw; // 변환이 실패하면 원본을 그대로 내보낸다. 상태바가 비는 것보다 낫다.
  }

  // writeSync: 'exit' 핸들러에서는 비동기 쓰기가 유실될 수 있다.
  try {
    writeSync(1, output);
  } catch {
    originalWrite(output);
  }
}

process.on("exit", flush);

// ---------------------------------------------------------------------------
// stdin 미리 읽기 — Claude Code 버전을 라벨에 쓰기 위해
// ---------------------------------------------------------------------------
// Claude Code는 상태줄 입력(JSON)의 `version`에 자기 버전을 넣어 준다. OMC도 같은 stdin을
// 읽어야 하므로, 여기서 다 읽은 뒤 같은 내용을 담은 스트림으로 바꿔 끼워 넘긴다.
let claudeVersion = null;
let workDir = null;

/**
 * 작업 폴더의 git 상태를 읽는다. fetch는 하지 않는다(↓는 마지막 fetch 기준).
 * git이 없거나 저장소가 아니거나 느리면 null — 그때는 OMC의 표시를 그대로 쓴다.
 */
function readGitStatus() {
  try {
    const r = spawnSync("git", ["status", "--porcelain=v2", "--branch"], {
      cwd: workDir || process.cwd(),
      encoding: "utf8",
      timeout: 1500,
      windowsHide: true,
    });
    return r.status === 0 ? r.stdout : null;
  } catch {
    return null;
  }
}

if (!process.stdin.isTTY) {
  try {
    let input = "";
    process.stdin.setEncoding("utf8");
    for await (const chunk of process.stdin) input += chunk;
    Object.defineProperty(process, "stdin", {
      value: Readable.from([Buffer.from(input, "utf8")], { objectMode: false }),
      configurable: true,
    });
    const info = JSON.parse(input);
    claudeVersion = info.version ?? null;
    workDir = info.workspace?.current_dir ?? info.cwd ?? null;
  } catch {
    /* 버전을 못 얻어도 라벨만 기존대로 나간다 */
  }
}

// ---------------------------------------------------------------------------
// 저장소 기준으로 HUD 맞추기 — pull 직후 재시작 없이 반영되게
// ---------------------------------------------------------------------------
// 작업 폴더에서 위로 올라가며 cp_workspace(env/sync.mjs + .omc-workspace)를 찾는다.
// 찾으면 래퍼와 hud-config.json을 저장소 기준으로 맞춘다. OMC를 불러오기 전에 하므로
// 설정 변경은 이번 갱신부터, 래퍼 변경은 다음 갱신부터 보인다. 실패해도 상태줄은 그대로 나간다.
try {
  let dir = workDir || process.cwd();
  for (let i = 0; i < 8 && dir; i++) {
    const sync = join(dir, "env", "sync.mjs");
    if (existsSync(sync) && existsSync(join(dir, ".omc-workspace"))) {
      const { applyHud } = await import(pathToFileURL(sync).href);
      applyHud();
      break;
    }
    const up = dirname(dir);
    if (up === dir) break;
    dir = up;
  }
} catch {
  /* 동기화 실패로 상태줄을 비우지 않는다 */
}

const hudPath = findHud();
if (!hudPath) {
  chunks.push(
    "[OMC HUD] omc-hud.mjs 를 찾을 수 없다. " +
      "이 스크립트는 omc-hud.mjs 옆(~/.claude/hud/)에 두어야 한다.\n",
  );
} else {
  try {
    await import(pathToFileURL(hudPath).href);
  } catch (error) {
    const detail = error?.message ? String(error.message).replace(/\s+/g, " ").trim() : String(error);
    chunks.push(`[OMC HUD] 로드 실패: ${detail.slice(0, 120)}\n`);
  }
}
