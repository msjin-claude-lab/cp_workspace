/**
 * Claude Code 업데이트 점검 (winget으로 설치한 PC 전용)
 *
 * winget 설치는 자동 갱신되지 않는다. 그런데 Claude Code가 띄우는 "업데이트 가능" 배너는
 * Anthropic 서버를 기준으로 하므로, winget 저장소에 아직 없는 버전까지 알린다. 그러면
 * `winget upgrade`가 "업그레이드 없음"을 돌려주고 배너만 계속 남는다(2026-11-16 실제로 겪음).
 *
 * 그래서 여기서는 **winget 저장소에 실제로 올라온 버전**만 본다. 이 알림이 뜨면 그때는
 * `winget upgrade`가 실제로 동작한다.
 *
 * - `winget list`만 쓴다. `winget upgrade`는 조회가 아니라 설치를 수행하므로 hook에서 쓰지 않는다
 * - 하루 한 번만 조회한다 (기록: `.git/cp-version-check.json`, 커밋되지 않음)
 * - winget이 없거나·느리거나·실패하면 조용히 넘어간다. 세션 시작을 막지 않는다
 */

import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { isAbsolute, join } from "node:path";
import { git, root } from "./sync-core.mjs";

const PACKAGE_ID = "Anthropic.ClaudeCode";
const WINGET_TIMEOUT = 8000;

function stateFile() {
  const gitDir = git(["rev-parse", "--git-dir"]);
  return join(isAbsolute(gitDir) ? gitDir : join(root, gitDir), "cp-version-check.json");
}

function today(now = new Date()) {
  const pad = (n) => String(n).padStart(2, "0");
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
}

/** a가 b보다 높은 버전이면 true. "2.1.318" 같은 점 구분 숫자만 다룬다 */
function isNewer(a, b) {
  const x = a.split(".").map(Number);
  const y = b.split(".").map(Number);
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    const d = (x[i] ?? 0) - (y[i] ?? 0);
    if (d) return d > 0;
  }
  return false;
}

/**
 * `winget list --id <id> --exact`의 해당 줄에서 버전을 읽는다.
 * 업그레이드가 있으면 "버전"과 "사용 가능" 두 개가 나온다. 표 머리글은 로캘을 타므로
 * 숫자 패턴으로만 판별한다.
 *
 * @returns {{installed: string, available: string|null}|null} 실패하면 null
 */
function queryWinget() {
  let out;
  try {
    out = execFileSync(
      "winget",
      ["list", "--id", PACKAGE_ID, "--exact", "--disable-interactivity", "--accept-source-agreements"],
      { timeout: WINGET_TIMEOUT, encoding: "utf8", windowsHide: true, stdio: ["ignore", "pipe", "pipe"] },
    );
  } catch {
    return null; // winget 없음 / 시간 초과 / winget으로 설치하지 않음
  }

  const line = out.split(/\r?\n/).find((l) => l.includes(PACKAGE_ID));
  if (!line) return null;

  const versions = line.match(/\d+(?:\.\d+)+/g) || [];
  if (!versions.length) return null;
  return { installed: versions[0], available: versions[1] ?? null };
}

/**
 * 하루 한 번 점검해, winget에 더 높은 버전이 올라왔을 때만 알릴 한 줄을 돌려준다.
 * @returns {string|null} 알릴 것이 없으면 null
 */
export function checkClaudeUpdate() {
  if (process.platform !== "win32") return null;

  let cached = null;
  try {
    cached = JSON.parse(readFileSync(stateFile(), "utf8"));
  } catch {
    /* 기록 없음 — 조회한다 */
  }

  let result;
  if (cached?.day === today()) {
    result = cached;
  } else {
    result = queryWinget();
    if (!result) return null; // 실패는 기록하지 않는다. 다음 세션에 다시 조회한다
    try {
      writeFileSync(stateFile(), JSON.stringify({ day: today(), ...result, at: new Date().toISOString() }));
    } catch {
      /* 기록 실패는 무시 */
    }
  }

  if (!result.available || !isNewer(result.available, result.installed)) return null;
  return `Claude Code ${result.installed} → ${result.available} 올라옴 — 종료 후 \`winget upgrade ${PACKAGE_ID}\``;
}
