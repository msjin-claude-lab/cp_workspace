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
    output = restoreGauges(raw);
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
