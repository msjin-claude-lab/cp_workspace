#!/usr/bin/env node
/**
 * Gitea 번들 pull — `git pull` 이 막힐 때 쓴다.
 *
 * 사내망 PC에서 `git fetch`/`git clone`이 HTTP 524로 실패한다 (2026-11-12 실측).
 * 짧은 GET(웹·API·/info/refs·archive)은 전부 2초 안에 200이 오는데, 본문이 실린
 * POST(/git-upload-pack)만 100초 후 524가 난다. 프로토콜 v0·v2, HTTP/1.1·HTTP/2
 * 네 조합 모두 같다. Cloudflare Worker가 POST 본문을 Gitea로 넘기지 못하는 것으로
 * 보이며, 사내망 차단은 아니다 — CF-Cache-Status가 DYNAMIC이라 NAS까지 실제로
 * 다녀온 응답이다.
 *
 * Gitea는 브랜치를 git bundle 파일로 내려주는 GET 엔드포인트를 제공한다.
 * 번들은 이력과 커밋 해시를 그대로 보존하므로 결과가 `git fetch`와 같다.
 *
 *   node tools/gitea-pull.mjs [브랜치]     # 기본값: 현재 브랜치
 *
 * 받기 전용이다. push는 같은 벽(본문 실린 POST)에 막히므로 이 스크립트로 대체할 수
 * 없다. 근본 해결은 Worker를 Cloudflare Tunnel로 바꾸는 것이고, 개인 PC에서 할 일이다.
 */

import { execFileSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

/** 사용자에게 보여줄 실패. 스택 트레이스 없이 한 줄로 끝낸다. */
class Fail extends Error {}

function fail(message) {
  throw new Fail(message);
}

/**
 * git을 돌리고 stdout을 돌려준다. 실패하면 stderr를 담아 던진다.
 *
 * credential.helper 를 끄는 이유: 이 스크립트는 인증이 필요한 일을 하지 않는다
 * (번들은 fetch()로 받고, bundle fetch는 로컬 파일이며, 공개 저장소의 ls-remote는
 * 익명으로 된다). 그런데 Git Credential Manager가 끼어들면 창이 뜨거나 실패한다.
 * GIT_TERMINAL_PROMPT=0 은 그래도 남은 프롬프트가 터미널을 막지 않게 한다.
 */
function git(...args) {
  try {
    return execFileSync("git", ["-c", "credential.helper=", ...args], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
      env: { ...process.env, GIT_TERMINAL_PROMPT: "0" },
    }).trim();
  } catch (error) {
    const detail = (error.stderr || error.message || "").toString().trim();
    throw new Error(`git ${args.join(" ")}\n  ${detail}`);
  }
}

/**
 * origin 주소에서 번들 URL을 만든다.
 *
 * 주소를 하드코딩하지 않는 이유: 원격이 바뀌어도(예: Tunnel 전환) 그대로 따라간다.
 *   https://host/owner/repo.git  ->  https://host/owner/repo/archive/<branch>.bundle
 */
function bundleUrl(remoteUrl, branch) {
  const base = remoteUrl.replace(/\.git$/, "").replace(/\/$/, "");
  if (!/^https?:\/\//.test(base)) {
    fail(`origin이 HTTP(S) 주소가 아니다: ${remoteUrl}\n  이 스크립트는 Gitea의 archive 엔드포인트를 쓴다.`);
  }
  return `${base}/archive/${encodeURIComponent(branch)}.bundle`;
}

/**
 * 번들을 받아 디스크에 쓴다.
 *
 * 실패 응답에서도 본문을 반드시 비운다. 안 그러면 소켓이 열린 채 남아
 * Windows에서 종료 시 libuv 단언에 걸린다.
 */
async function download(url, destination) {
  console.log(`받는 중: ${url}`);
  let response;
  try {
    response = await fetch(url, { redirect: "follow" });
  } catch (error) {
    fail(`연결하지 못했다: ${error?.cause?.message || error.message}\n  주소: ${url}`);
  }

  if (!response.ok) {
    await response.body?.cancel().catch(() => {});
    const hint =
      response.status >= 520 && response.status <= 530
        ? "\n  5xx 계열은 Cloudflare가 NAS에 닿지 못한 것이다. NAS가 올라왔는지 확인할 것."
        : "";
    fail(`HTTP ${response.status} — 번들을 받지 못했다.\n  주소: ${url}${hint}`);
  }

  const bytes = Buffer.from(await response.arrayBuffer());
  if (bytes.length === 0) fail("번들이 비어 있다.");
  writeFileSync(destination, bytes);
  console.log(`  ${bytes.length.toLocaleString()} bytes`);
}

/** 받은 번들을 origin/<branch> 로 반영하고, 번들이 가리키는 커밋을 돌려준다. */
function applyBundle(bundlePath, branch) {
  // 손상된 번들을 그대로 fetch하면 저장소에 쓰레기 객체가 남을 수 있다.
  git("bundle", "verify", bundlePath);
  console.log("  번들 검증 통과");

  // Gitea는 refs/heads/bundle 로 넣어 주지만, 버전에 따라 다를 수 있으므로 직접 읽는다.
  const heads = git("bundle", "list-heads", bundlePath)
    .split("\n")
    .map((line) => line.trim().split(/\s+/))
    .filter(([sha, ref]) => sha && ref?.startsWith("refs/heads/"));
  if (heads.length === 0) fail("번들에 브랜치 ref가 없다.");

  const [tipSha] = heads[0];
  git("fetch", bundlePath, `${heads[0][1]}:refs/remotes/origin/${branch}`);
  console.log(`  origin/${branch} -> ${tipSha.slice(0, 7)}`);
  return tipSha;
}

/**
 * 받은 번들이 서버 최신인지 독립적으로 확인한다.
 *
 * ls-remote는 짧은 GET이라 524를 피해 간다. 조회가 실패해도 치명적이지 않으므로
 * 경고만 하고 넘어간다 — 번들 자체는 이미 검증했다.
 */
function compareWithServer(branch, tipSha) {
  let serverSha;
  try {
    serverSha = git("ls-remote", "origin", `refs/heads/${branch}`).split(/\s+/)[0];
  } catch {
    console.log("  (서버 해시 대조 건너뜀 — ls-remote 실패)");
    return;
  }
  if (!serverSha) {
    console.log(`  (서버에 ${branch} 가 없다)`);
  } else if (serverSha !== tipSha) {
    console.log(`  주의: 서버는 ${serverSha.slice(0, 7)}, 번들은 ${tipSha.slice(0, 7)} 다.`);
    console.log("  캐시된 번들일 수 있다. 잠시 후 다시 실행할 것.");
  } else {
    console.log("  서버 해시와 일치");
  }
}

/** 안전할 때만 fast-forward 한다. 막히면 다음에 칠 명령을 알려준다. */
function mergeIfSafe(branch) {
  const current = git("rev-parse", "--abbrev-ref", "HEAD");
  if (current !== branch) {
    console.log(`\n${branch} 가 아니라 ${current} 에 있다. origin/${branch} 만 갱신했다.`);
    console.log(`병합하려면: git checkout ${branch} && git merge --ff-only origin/${branch}`);
    return;
  }
  if (git("status", "--porcelain") !== "") {
    console.log(`\n커밋되지 않은 변경이 있어 병합하지 않았다. origin/${branch} 만 갱신했다.`);
    console.log(`정리한 뒤: git merge --ff-only origin/${branch}`);
    return;
  }
  // ff-only: 로컬 커밋이 있으면 멈춘다. 조용히 병합 커밋을 만들지 않는다.
  try {
    console.log(`\n${git("merge", "--ff-only", `refs/remotes/origin/${branch}`)}`);
  } catch {
    console.log(`\nfast-forward 불가 — 로컬에만 있는 커밋이 있다. origin/${branch} 는 갱신됐다.`);
    console.log(`확인: git log --oneline origin/${branch}..${branch}`);
    console.log(`이어서: git rebase origin/${branch}`);
  }
}

// ---------------------------------------------------------------------------

let workDir = null;
try {
  const branch = process.argv[2] || git("rev-parse", "--abbrev-ref", "HEAD");
  if (branch === "HEAD") {
    fail("detached HEAD 상태다. 브랜치를 인자로 넘기거나 먼저 체크아웃할 것.");
  }

  let remoteUrl;
  try {
    remoteUrl = git("remote", "get-url", "origin");
  } catch {
    fail("origin 원격이 없다. 먼저 `git remote add origin <Gitea 주소>` 할 것.");
  }

  workDir = mkdtempSync(join(tmpdir(), "gitea-pull-"));
  const bundlePath = join(workDir, `${branch.replace(/[^\w.-]/g, "_")}.bundle`);

  await download(bundleUrl(remoteUrl, branch), bundlePath);
  const tipSha = applyBundle(bundlePath, branch);
  compareWithServer(branch, tipSha);
  mergeIfSafe(branch);

  console.log(`\n현재: ${git("log", "--oneline", "-1")}`);
} catch (error) {
  console.error(`\n[실패] ${error instanceof Fail ? error.message : error.message}`);
  // process.exit() 를 쓰지 않는다. 열린 소켓이 있으면 Windows에서 libuv 단언에 걸린다.
  process.exitCode = 1;
} finally {
  if (workDir) rmSync(workDir, { recursive: true, force: true });
}
