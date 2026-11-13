/**
 * 원격(Gitea)과 로컬을 비교하는 공통 로직. session-start.mjs 와 sync-check.mjs 가 쓴다.
 *
 * - pull 대상: 원격에만 있는 커밋
 * - push 대상: 로컬에만 있는 커밋, 커밋하지 않은 변경
 * - fetch 실패(인증·연결)는 항상 보고한다 — 원격을 못 봤는데 "같다"고 말하지 않기 위해
 *
 * 점검 단위는 시계의 정시 구간(예: 14:00:00 ~ 14:59:59)이며, 기록은 .git/cp-sync-check.json
 * (커밋되지 않음)에 둔다. 직접 pull/push/commit 하지 않는다.
 */

import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { isAbsolute, join } from "node:path";

export const root = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const gitEnv = { ...process.env, GIT_TERMINAL_PROMPT: "0", GCM_INTERACTIVE: "never" };

export function git(args, timeout = 5000) {
  return execFileSync("git", args, { cwd: root, env: gitEnv, timeout, encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim();
}

function pad(n) {
  return String(n).padStart(2, "0");
}

export function currentHourKey(now = new Date()) {
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} ${pad(now.getHours())}`;
}

function stateFile() {
  const gitDir = git(["rev-parse", "--git-dir"]);
  return join(isAbsolute(gitDir) ? gitDir : join(root, gitDir), "cp-sync-check.json");
}

export function alreadyCheckedThisHour() {
  try {
    return JSON.parse(readFileSync(stateFile(), "utf8")).hour === currentHourKey();
  } catch {
    return false;
  }
}

export function markChecked() {
  writeFileSync(stateFile(), JSON.stringify({ hour: currentHourKey(), at: new Date().toISOString() }));
}

function firstLine(e) {
  const s = String(e?.stderr || e?.message || e).trim();
  return (s.split(/\r?\n/).find((l) => l && !/unencrypted HTTP/i.test(l)) || "알 수 없는 오류").slice(0, 160);
}

/**
 * @returns {{ok: boolean, upstream?: string, behind: number, ahead: number, dirty: string[],
 *            fetchError: string, askPull: boolean, askPush: boolean}}
 */
export function compare() {
  let upstream;
  try {
    upstream = git(["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"]);
  } catch {
    return { ok: false, behind: 0, ahead: 0, dirty: [], fetchError: "", askPull: false, askPush: false };
  }

  let fetchError = "";
  try {
    git(["fetch", "--quiet", upstream.split("/")[0]], 15000);
  } catch (e) {
    fetchError = firstLine(e);
  }

  const [ahead, behind] = git(["rev-list", "--left-right", "--count", `HEAD...${upstream}`]).split(/\s+/).map(Number);
  const dirty = git(["status", "--porcelain"]).split(/\r?\n/).filter(Boolean);
  return { ok: true, upstream, behind, ahead, dirty, fetchError, askPull: behind > 0, askPush: ahead > 0 || dirty.length > 0 };
}

/** 사용자에게 보일 한 줄 요약 */
export function summaryLine(r) {
  const parts = [];
  if (r.askPull) parts.push(`받을 커밋 ${r.behind}개`);
  if (r.ahead) parts.push(`push 안 한 커밋 ${r.ahead}개`);
  if (r.dirty.length) parts.push(`커밋 안 한 변경 ${r.dirty.length}개`);
  const head = r.fetchError ? `⚠ 원격 확인 실패: ${r.fetchError}` : null;
  if (!parts.length) return head ? `${head} (로컬에는 올릴 것 없음)` : "✓ git 동기화: 원격과 같음";
  return [head, `git 동기화: ${parts.join(", ")}`].filter(Boolean).join(" / ");
}

/** Claude에게 넘길 상세 사실 + 질문 지시 */
export function askInstruction(r, when) {
  const facts = [];
  if (r.askPull) facts.push(`원격(${r.upstream})에만 있는 커밋 ${r.behind}개 — pull 대상:\n${git(["log", "--oneline", "-5", `HEAD..${r.upstream}`])}`);
  if (r.ahead) facts.push(`로컬에만 있는 커밋 ${r.ahead}개 — push 대상:\n${git(["log", "--oneline", "-5", `${r.upstream}..HEAD`])}`);
  if (r.dirty.length) facts.push(`커밋하지 않은 변경 ${r.dirty.length}개:\n${r.dirty.slice(0, 10).join("\n")}${r.dirty.length > 10 ? "\n..." : ""}`);
  if (r.fetchError) facts.push(`(주의: git fetch 실패 — ${r.fetchError}. 원격 비교가 오래된 정보일 수 있다.)`);

  const options = [];
  if (r.askPull) options.push(r.ahead > 0 ? "pull (로컬 커밋도 있어 갈라진 상태 — rebase 또는 merge 방식을 함께 확인)" : "pull (fast-forward)");
  if (r.askPush) options.push(r.dirty.length ? "커밋 후 push (커밋 메시지를 제안하고 확인받기)" : "push");
  if (r.askPull && r.askPush) options.push("pull 후 push");
  options.push("지금은 그대로 두기");

  return [
    `[git 동기화 점검 · ${currentHourKey()}시 구간 · ${when}] 원격과 로컬에 차이가 있다.`,
    "",
    ...facts,
    "",
    "위 상황을 사용자에게 짧게 요약하고 AskUserQuestion으로 어떻게 할지 물어라. 선택지:",
    ...options.map((o) => `- ${o}`),
    "",
    "사용자가 고른 것만 실행한다. 묻기 전에 pull/push/commit 하지 않는다. GitHub에는 push하지 않는다(origin = Gitea).",
  ].join("\n");
}
