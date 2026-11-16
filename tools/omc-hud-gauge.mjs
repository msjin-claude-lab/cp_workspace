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

import { existsSync, writeSync } from "node:fs";
import { Readable } from "node:stream";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * 감쌀 대상인 omc-hud.mjs 를 찾는다.
 *
 * 보통은 이 스크립트 옆에 있다(~/.claude/hud/). 저장소의 tools/ 사본처럼
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
  const name = text.match(/Model: ([^\x1b\n|]+)/)?.[1]?.trim() ?? null;
  const level = text.match(/effort:([a-z]+)/)?.[1] ?? null;

  let rest = text;
  rest = rest.replace(new RegExp(`${LEAD_SEP}(?:\\x1b\\[[0-9;]*m)*Model: [^\\x1b\\n|]+(?:\\x1b\\[[0-9;]*m)*`), "");
  rest = rest.replace(new RegExp(`${LEAD_SEP}(?:\\x1b\\[[0-9;]*m)*effort:[a-z]+(?:\\x1b\\[[0-9;]*m)*`), "");

  if (!name) return { text, model: null };
  const effort = level ? ` ${DIM}${level[0].toUpperCase()}${level.slice(1)}${RESET}` : "";
  return { text: rest, model: `${CYAN}${name}${RESET}${effort}` };
}

/**
 * ctx 구간을 잘라낸다. OMC가 줄 맨 끝에 두므로 `ctx:` 부터 줄 끝까지가 한 덩어리다.
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
  if (!head.trim()) return { text, ctx: null }; // ctx뿐인 줄이면 옮길 이유가 없다

  lines[row] = head;
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
 * 줄 배치를 다시 짠다.
 *
 *   1줄: ctx
 *   2줄: [OMC#x] | 모델 effort | branch | git 상태
 *   3줄: 나머지(사용량 게이지 등)
 *
 * 못 찾은 조각은 건너뛰고, 아무것도 못 찾으면 원본을 그대로 돌려준다.
 */
export function moveCtxFirst(text, claudeVersion = null) {
  const c = takeCtx(text);
  const m = takeModel(c.text);
  const l = takeLabel(m.text, claudeVersion);
  if (!c.ctx && !m.model && !l.label) return text;

  const rest = l.text.split("\n").map((s) => s.trimEnd()).filter((s) => s.replace(/\x1b\[[0-9;]*m/g, "").trim());
  const branchIdx = rest.findIndex((s) => s.includes("branch:"));
  const branch = branchIdx === -1 ? null : rest.splice(branchIdx, 1)[0];

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
    output = moveCtxFirst(restoreGauges(raw), claudeVersion);
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
if (!process.stdin.isTTY) {
  try {
    let input = "";
    process.stdin.setEncoding("utf8");
    for await (const chunk of process.stdin) input += chunk;
    Object.defineProperty(process, "stdin", {
      value: Readable.from([Buffer.from(input, "utf8")], { objectMode: false }),
      configurable: true,
    });
    claudeVersion = JSON.parse(input).version ?? null;
  } catch {
    /* 버전을 못 얻어도 라벨만 기존대로 나간다 */
  }
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
