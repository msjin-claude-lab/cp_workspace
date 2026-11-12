#!/usr/bin/env node
/**
 * Stop hook — 정시 구간마다 한 번, 원격과 로컬을 비교해 pull/push 여부를 묻게 한다.
 *
 * - 점검 단위는 시계의 정시 구간(예: 14:00:00 ~ 14:59:59)이다. 그 구간에 이미
 *   점검했으면 아무것도 하지 않는다. 기록은 .git/ 안에 두어 커밋되지 않는다.
 * - pull: 원격에 아직 받지 않은 커밋이 있을 때만 묻는다.
 * - push: 로컬에만 있는 커밋이나 커밋하지 않은 변경이 있을 때만 묻는다.
 * - 둘 다 없으면 조용히 끝난다.
 *
 * 물을 것이 있으면 Stop을 막고(decision: block) Claude에게 질문을 맡긴다.
 * 직접 pull/push 하지 않는다 — 사람이 고른 것만 Claude가 실행한다.
 */

import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { isAbsolute, join } from "node:path";

const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const gitEnv = { ...process.env, GIT_TERMINAL_PROMPT: "0", GCM_INTERACTIVE: "never" };

function git(args, timeout = 5000) {
  return execFileSync("git", args, { cwd: root, env: gitEnv, timeout, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim();
}

function readStdin() {
  try {
    return JSON.parse(readFileSync(0, "utf8") || "{}");
  } catch {
    return {};
  }
}

function pad(n) {
  return String(n).padStart(2, "0");
}

try {
  // 이 hook이 막아서 이어진 대답의 끝이면 다시 막지 않는다(무한 반복 방지).
  if (readStdin().stop_hook_active) process.exit(0);

  const now = new Date();
  const hourKey = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}`;

  const gitDir = git(["rev-parse", "--git-dir"]);
  const stateFile = join(isAbsolute(gitDir) ? gitDir : join(root, gitDir), "cp-sync-check.json");
  let state = {};
  try {
    state = JSON.parse(readFileSync(stateFile, "utf8"));
  } catch {}
  if (state.hour === hourKey) process.exit(0);
  // 결과와 상관없이 이 구간은 점검한 것으로 기록한다(원격이 느려도 매 대답마다 다시 기다리지 않게).
  writeFileSync(stateFile, JSON.stringify({ hour: hourKey, at: now.toISOString() }));

  let upstream;
  try {
    upstream = git(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"]);
  } catch {
    process.exit(0); // 추적 브랜치 없음 — 비교할 원격이 없다
  }

  let fetchError = "";
  try {
    git(["fetch", "--quiet", upstream.split("/")[0]], 15000);
  } catch (e) {
    fetchError = String(e?.stderr || e?.message || e).split(/\r?\n/).find((l) => l && !/unencrypted HTTP/i.test(l)) || "알 수 없는 오류";
  }

  const [ahead, behind] = git(["rev-list", "--left-right", "--count", `HEAD...${upstream}`]).split(/\s+/).map(Number);
  const dirtyFiles = git(["status", "--porcelain"]).split(/\r?\n/).filter(Boolean);

  const askPull = behind > 0;
  const askPush = ahead > 0 || dirtyFiles.length > 0;
  if (!askPull && !askPush) process.exit(0);

  const facts = [];
  if (askPull) {
    const log = git(["log", "--oneline", "-5", `HEAD..${upstream}`]);
    facts.push(`원격(${upstream})에만 있는 커밋 ${behind}개 — pull 대상:\n${log}`);
  }
  if (ahead > 0) {
    const log = git(["log", "--oneline", "-5", `${upstream}..HEAD`]);
    facts.push(`로컬에만 있는 커밋 ${ahead}개 — push 대상:\n${log}`);
  }
  if (dirtyFiles.length) {
    facts.push(`커밋하지 않은 변경 ${dirtyFiles.length}개:\n${dirtyFiles.slice(0, 10).join("\n")}${dirtyFiles.length > 10 ? "\n..." : ""}`);
  }
  if (fetchError) facts.push(`(주의: git fetch 실패 — ${fetchError.slice(0, 160)}. 원격 비교가 오래된 정보일 수 있다.)`);

  const options = [];
  if (askPull) options.push(ahead > 0 ? "pull (로컬 커밋도 있어 갈라진 상태 — rebase 또는 merge 방식을 함께 확인)" : "pull (fast-forward)");
  if (askPush) options.push(dirtyFiles.length ? "커밋 후 push (커밋 메시지를 제안하고 확인받기)" : "push");
  if (askPull && askPush) options.push("pull 후 push");
  options.push("지금은 그대로 두기");

  const reason = [
    `[git 동기화 점검 · ${hourKey}시 구간] 원격과 로컬에 차이가 있다.`,
    "",
    ...facts,
    "",
    "지금 하던 대답은 끝났다. 위 상황을 사용자에게 짧게 요약하고 AskUserQuestion으로 어떻게 할지 물어라. 선택지:",
    ...options.map((o) => `- ${o}`),
    "",
    "사용자가 고른 것만 실행한다. 묻기 전에 pull/push/commit 하지 않는다. GitHub에는 push하지 않는다(origin = Gitea).",
  ].join("\n");

  process.stdout.write(JSON.stringify({ decision: "block", reason }));
} catch {
  // git 저장소가 아니거나 git 실패 — 대화를 막지 않는다
}
process.exit(0);
