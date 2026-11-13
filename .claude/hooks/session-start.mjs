#!/usr/bin/env node
/**
 * SessionStart hook
 *
 * 1. 원격(Gitea)과 로컬을 비교해 결과를 화면에 한 줄로 띄운다. 이 점검은 그 정시 구간의
 *    점검으로 기록되므로, 같은 구간의 Stop hook(sync-check.mjs)은 다시 묻지 않는다.
 *    받을 것·올릴 것이 있으면 Claude가 첫 대답에서 먼저 묻도록 지시를 넘긴다.
 * 2. 저장소의 HUD 게이지 래퍼를 ~/.claude/hud/ 에 맞춰 둔다(statusLine이 그 파일을 쓴다).
 *
 * 직접 pull/push/commit 하지 않는다. 어떤 경우에도 세션 시작을 막지 않는다 — 항상 exit 0.
 */

import { copyFileSync, existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { askInstruction, compare, markChecked, root, summaryLine } from "./sync-core.mjs";

const messages = [];
const context = ["[cp_workspace 세션 시작 점검]"];

// --- 1. git 동기화 점검 --------------------------------------------------------
try {
  const r = compare();
  markChecked();
  if (r.ok) {
    messages.push(summaryLine(r));
    if (r.askPull || r.askPush) {
      context.push(askInstruction(r, "세션 시작"));
      context.push("사용자의 첫 메시지에 답하기 전에 이 질문부터 한다.");
    } else {
      context.push(`- ${summaryLine(r)}`);
    }
  }
} catch (e) {
  messages.push(`⚠ git 동기화 점검 실패: ${String(e?.message || e).slice(0, 120)}`);
}

// --- 2. HUD 게이지 래퍼 맞추기 ------------------------------------------------
try {
  const src = join(root, "tools", "omc-hud-gauge.mjs");
  const hudDir = join(process.env.CLAUDE_CONFIG_DIR?.trim() || join(homedir(), ".claude"), "hud");
  const dst = join(hudDir, "omc-hud-gauge.mjs");
  if (existsSync(src) && existsSync(hudDir)) {
    if (!existsSync(dst) || readFileSync(src, "utf8") !== readFileSync(dst, "utf8")) {
      copyFileSync(src, dst);
      messages.push("HUD 게이지 래퍼를 저장소 버전으로 갱신함");
    }
  } else if (!existsSync(hudDir)) {
    messages.push("~/.claude/hud/ 없음 — 이 PC에 OMC HUD가 설치되지 않았다(README의 새 PC 체크리스트 참고)");
  }
} catch (e) {
  messages.push(`HUD 래퍼를 맞추지 못함: ${String(e?.message || e).slice(0, 120)}`);
}

context.push("- 이어서 할 일은 HANDOFF.md에 있다.");

const out = { hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: context.join("\n") } };
if (messages.length) out.systemMessage = messages.join(" / ");
process.stdout.write(JSON.stringify(out));
process.exit(0);
