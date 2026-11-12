#!/usr/bin/env node
/**
 * SessionStart hook — 저장소의 HUD 게이지 래퍼를 ~/.claude/hud/ 에 맞춰 둔다.
 *
 * statusLine이 ~/.claude/hud/omc-hud-gauge.mjs 를 쓰는데, 원본은 저장소의
 * tools/ 에 있다. 저장소 버전이 바뀌면 시작할 때 복사해 모든 PC를 맞춘다.
 *
 * git pull/push 는 여기서 하지 않는다 — sync-check.mjs(Stop hook)가 정시 구간마다
 * 원격과 비교해 사람에게 묻는다.
 *
 * 어떤 경우에도 세션 시작을 막지 않는다 — 항상 exit 0.
 */

import { copyFileSync, existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const notes = [];
try {
  const src = join(root, "tools", "omc-hud-gauge.mjs");
  const hudDir = join(process.env.CLAUDE_CONFIG_DIR?.trim() || join(homedir(), ".claude"), "hud");
  const dst = join(hudDir, "omc-hud-gauge.mjs");
  if (existsSync(src) && existsSync(hudDir)) {
    if (!existsSync(dst) || readFileSync(src, "utf8") !== readFileSync(dst, "utf8")) {
      copyFileSync(src, dst);
      notes.push("HUD 게이지 래퍼를 저장소 버전으로 갱신했다(~/.claude/hud/omc-hud-gauge.mjs). 상태바는 다음 갱신부터 반영된다.");
    }
  } else if (!existsSync(hudDir)) {
    notes.push("~/.claude/hud/ 가 없다 — 이 PC에 OMC HUD가 설치되지 않았다. README의 새 PC 체크리스트를 따른다.");
  }
} catch (e) {
  notes.push(`HUD 래퍼를 맞추지 못했다. (${firstLine(e)})`);
}

const context = [
  "[cp_workspace 세션 시작 점검]",
  ...notes.map((n) => `- ${n}`),
  "- git pull/push 여부는 정시 구간마다 sync-check hook이 원격과 비교해 묻게 한다.",
  "- 이어서 할 일은 HANDOFF.md에 있다.",
].join("\n");

const out = { hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: context } };
if (notes.length) out.systemMessage = notes.join(" / ");
process.stdout.write(JSON.stringify(out));
process.exit(0);

function firstLine(e) {
  const s = String(e?.stderr || e?.message || e).trim();
  return s.split(/\r?\n/).find((l) => l && !/unencrypted HTTP/i.test(l))?.slice(0, 160) ?? "";
}
