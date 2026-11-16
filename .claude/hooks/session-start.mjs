#!/usr/bin/env node
/**
 * SessionStart hook
 *
 * 1. 원격(Gitea)과 로컬을 비교해 결과를 화면에 한 줄로 띄운다. 이 점검은 그 정시 구간의
 *    점검으로 기록되므로, 같은 구간의 Stop hook(sync-check.mjs)은 다시 묻지 않는다.
 *    받을 것·올릴 것이 있으면 Claude가 첫 대답에서 먼저 묻도록 지시를 넘긴다.
 * 2. 저장소 env/ 기준으로 환경 설정을 맞춘다 — HUD는 자동, git 설정은 차이를 알려 묻게 한다.
 * 3. winget에 새 Claude Code 버전이 올라왔으면 알린다(하루 한 번 조회).
 *
 * 직접 pull/push/commit 하지 않는다. 어떤 경우에도 세션 시작을 막지 않는다 — 항상 exit 0.
 */

import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { askInstruction, compare, markChecked, root, summaryLine } from "./sync-core.mjs";
import { checkClaudeUpdate } from "./version-check.mjs";

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

// --- 2. 환경 설정 맞추기 (env/) ------------------------------------------------
// HUD는 자동으로 맞추고, git 설정은 차이만 알려 사용자 승인을 받게 한다(env/sync.mjs 참고).
try {
  const { applyHud, applyWikiLink, diffGit, describeGitDiff } = await import(
    pathToFileURL(join(root, "env", "sync.mjs")).href
  );
  const hudDir = join(process.env.CLAUDE_CONFIG_DIR?.trim() || join(homedir(), ".claude"), "hud");
  if (!existsSync(hudDir)) {
    messages.push("~/.claude/hud/ 없음 — 이 PC에 OMC HUD가 설치되지 않았다(README의 새 PC 체크리스트 참고)");
  } else {
    const changed = applyHud();
    if (changed.length) messages.push(`HUD 설정을 저장소 기준(env/hud)으로 맞춤: ${changed.length}건`);
  }
  const wiki = applyWikiLink();
  if (wiki.length) messages.push(`OMC 위키를 저장소 wiki/ 로 연결함: ${wiki.join(", ")}`);

  const gitDiff = diffGit();
  if (gitDiff.length) {
    messages.push(`git 설정이 저장소 기준(env/git)과 ${gitDiff.length}건 다름 — Claude가 적용 여부를 묻는다`);
    context.push(
      `- git 설정이 env/git/git-config.json 기준과 다르다:\n${describeGitDiff(gitDiff)}\n` +
        "  사용자의 첫 메시지에 답하기 전에, 위 차이를 짧게 보여 주고 AskUserQuestion으로 적용할지 묻는다" +
        "(선택지: 적용 / 지금은 그대로). 적용을 고르면 `node env/sync.mjs --apply git`을 실행한다. " +
        "로그인 방식(helper)이 바뀌면 다음 push 때 한 번 다시 로그인해야 할 수 있다고 알린다. 묻기 전에 적용하지 않는다.",
    );
  }
} catch (e) {
  messages.push(`환경 설정을 맞추지 못함: ${String(e?.message || e).slice(0, 120)}`);
}

// --- 3. Claude Code 업데이트 점검 ----------------------------------------------
try {
  const update = checkClaudeUpdate();
  if (update) {
    messages.push(update);
    context.push(`- ${update}`);
  }
} catch (e) {
  // 알림 하나 때문에 세션 시작을 방해하지 않는다 — 조용히 넘어간다
  void e;
}

context.push("- 이어서 할 일은 HANDOFF.md에 있다.");

const out = { hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: context.join("\n") } };
if (messages.length) out.systemMessage = messages.join(" / ");
process.stdout.write(JSON.stringify(out));
process.exit(0);
