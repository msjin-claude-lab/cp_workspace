#!/usr/bin/env node
/**
 * 환경 설정 동기화 — 저장소의 env/ 를 기준으로 이 PC의 설정을 맞춘다.
 *
 * 대상
 *   hud  ~/.claude/hud/omc-hud-gauge.mjs        ← env/hud/omc-hud-gauge.mjs
 *        ~/.claude/.omc/hud-config.json          ← env/hud/hud-config.json
 *        ~/.claude/settings.json 의 omcHud 키    ← 제거(있으면 hud-config.json보다 우선해 기준을 가린다)
 *   git  git config (전역·저장소)                ← env/git/git-config.json
 *
 * 적용 방식이 다르다.
 *   - hud: 자동 적용. 세션 시작 hook과 상태줄 래퍼가 부른다(pull 직후 다음 상태줄 갱신에 반영).
 *   - git: 차이만 보고하고, 사람이 승인한 뒤 `node env/sync.mjs --apply git`으로 적용한다.
 *          로그인 방식이 바뀌면 다시 로그인해야 할 수 있고, 사내망 PC 환경 변경은 먼저 묻는 것이 규칙이다.
 *
 * 덮어쓰기 전 원본은 `<파일>.before-env-sync`로 백업한다(직전 것 하나만 남는다).
 *
 * CLI
 *   node env/sync.mjs                 차이만 보고
 *   node env/sync.mjs --apply hud     HUD 맞추기
 *   node env/sync.mjs --apply git     git 설정 맞추기
 *   node env/sync.mjs --apply all     둘 다
 */

import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

export const ENV_DIR = dirname(fileURLToPath(import.meta.url));
export const REPO_ROOT = resolve(ENV_DIR, "..");

const configDir = () => process.env.CLAUDE_CONFIG_DIR?.trim() || join(homedir(), ".claude");
const read = (p) => (existsSync(p) ? readFileSync(p, "utf8") : null);

function backupAndWrite(path, content) {
  if (existsSync(path)) copyFileSync(path, `${path}.before-env-sync`);
  writeFileSync(path, content);
}

// ---------------------------------------------------------------------------
// HUD
// ---------------------------------------------------------------------------

/** @returns {{file: string, target: string, apply: () => void}[]} 기준과 다른 항목 */
export function diffHud() {
  const out = [];
  const hudDir = join(configDir(), "hud");
  if (!existsSync(hudDir)) return out; // OMC HUD가 설치되지 않은 PC — 맞출 대상이 없다

  const pairs = [
    [join(ENV_DIR, "hud", "omc-hud-gauge.mjs"), join(hudDir, "omc-hud-gauge.mjs")],
    [join(ENV_DIR, "hud", "hud-config.json"), join(configDir(), ".omc", "hud-config.json")],
  ];
  for (const [src, dst] of pairs) {
    const want = read(src);
    if (want !== null && read(dst) !== want) {
      out.push({ file: src, target: dst, apply: () => backupAndWrite(dst, want) });
    }
  }

  const settingsPath = join(configDir(), "settings.json");
  const settingsText = read(settingsPath);
  if (settingsText) {
    let settings = null;
    try {
      settings = JSON.parse(settingsText);
    } catch {
      /* 깨진 settings.json은 건드리지 않는다 */
    }
    if (settings && Object.prototype.hasOwnProperty.call(settings, "omcHud")) {
      out.push({
        file: "(omcHud 제거)",
        target: `${settingsPath} 의 omcHud`,
        apply: () => {
          delete settings.omcHud;
          backupAndWrite(settingsPath, JSON.stringify(settings, null, 2) + "\n");
        },
      });
    }
  }
  return out;
}

/** HUD를 기준에 맞춘다. @returns {string[]} 바꾼 대상 */
export function applyHud() {
  const changed = [];
  for (const d of diffHud()) {
    d.apply();
    changed.push(d.target);
  }
  return changed;
}

// ---------------------------------------------------------------------------
// git
// ---------------------------------------------------------------------------

function gitGetAll(scope, key) {
  const args = scope === "global" ? ["config", "--global", "--get-all", key] : ["config", "--local", "--get-all", key];
  const r = spawnSync("git", args, { cwd: REPO_ROOT, encoding: "utf8", windowsHide: true, timeout: 5000 });
  if (r.status !== 0) return []; // 없음(1) 포함
  return r.stdout.replace(/\r/g, "").split("\n").slice(0, -1);
}

function gitSetAll(scope, key, values) {
  const flag = scope === "global" ? "--global" : "--local";
  spawnSync("git", ["config", flag, "--unset-all", key], { cwd: REPO_ROOT, windowsHide: true });
  for (const v of values) {
    const r = spawnSync("git", ["config", flag, "--add", key, v], { cwd: REPO_ROOT, encoding: "utf8", windowsHide: true });
    if (r.status !== 0) throw new Error(`git config ${flag} --add ${key} 실패: ${r.stderr.trim()}`);
  }
}

/** @returns {{scope: string, key: string, now: string[], want: string[], why: string}[]} 기준과 다른 항목 */
export function diffGit() {
  const spec = JSON.parse(readFileSync(join(ENV_DIR, "git", "git-config.json"), "utf8"));
  const out = [];
  for (const item of spec.settings) {
    const now = gitGetAll(item.scope, item.key);
    if (JSON.stringify(now) !== JSON.stringify(item.values)) {
      out.push({ scope: item.scope, key: item.key, now, want: item.values, why: item.why });
    }
  }
  return out;
}

/** git 설정을 기준에 맞춘다. @returns {string[]} 바꾼 키 */
export function applyGit() {
  const changed = [];
  for (const d of diffGit()) {
    gitSetAll(d.scope, d.key, d.want);
    changed.push(`${d.scope} ${d.key}`);
  }
  return changed;
}

const show = (vals) => (vals.length ? vals.map((v) => (v === "" ? '""' : v)).join(", ") : "(없음)");

/** 사람이 읽을 git 차이 목록 */
export function describeGitDiff(diffs) {
  return diffs.map((d) => `  - [${d.scope}] ${d.key}: ${show(d.now)} → ${show(d.want)}  (${d.why})`).join("\n");
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

const isMain = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  const i = process.argv.indexOf("--apply");
  const what = i === -1 ? null : process.argv[i + 1] || "all";

  if (what === "hud" || what === "all") {
    const c = applyHud();
    console.log(c.length ? `HUD 맞춤:\n${c.map((t) => `  - ${t}`).join("\n")}` : "HUD: 이미 기준과 같음");
  }
  if (what === "git" || what === "all") {
    const c = applyGit();
    console.log(c.length ? `git 설정 맞춤:\n${c.map((t) => `  - ${t}`).join("\n")}` : "git: 이미 기준과 같음");
  }
  if (!what) {
    const h = diffHud();
    const g = diffGit();
    console.log(h.length ? `HUD 차이:\n${h.map((d) => `  - ${d.target}`).join("\n")}` : "HUD: 기준과 같음");
    console.log(g.length ? `git 차이:\n${describeGitDiff(g)}` : "git: 기준과 같음");
  }
}
