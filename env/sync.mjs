#!/usr/bin/env node
/**
 * 환경 설정 동기화 — 저장소의 env/ 를 기준으로 이 PC의 설정을 맞춘다.
 *
 * 대상
 *   hud  ~/.claude/hud/omc-hud-gauge.mjs        ← env/hud/omc-hud-gauge.mjs
 *        ~/.claude/.omc/hud-config.json          ← env/hud/hud-config.json
 *        ~/.claude/settings.json 의 omcHud 키    ← 제거(있으면 hud-config.json보다 우선해 기준을 가린다)
 *   wiki .omc/wiki → 저장소 wiki/ 연결(정션)     ← OMC 위키를 저장소에 두고 PC 간에 공유
 *   git  git config (전역·저장소)                ← env/git/git-config.json
 *
 * 적용 방식이 다르다.
 *   - hud·wiki: 자동 적용. 세션 시작 hook과 상태줄 래퍼가 부른다(pull 직후 다음 상태줄 갱신에 반영).
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
import {
  copyFileSync, existsSync, lstatSync, mkdirSync, readFileSync, readdirSync, readlinkSync,
  renameSync, rmSync, symlinkSync, writeFileSync,
} from "node:fs";
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
// 위키 공유 — 실제 파일은 저장소의 wiki/, .omc/wiki 는 그 폴더를 가리키는 연결(정션)
// ---------------------------------------------------------------------------
// OMC는 위키 위치를 <OMC 루트>/wiki 로 고정한다(설정 없음, dist/hooks/wiki/storage.js).
// 그래서 .omc/wiki 를 저장소 wiki/ 로 연결해 OMC가 쓰는 파일이 곧 커밋 대상이 되게 한다.
// .omc/wiki 가 진짜 폴더면(이 처리 전에 OMC가 만든 것) 안의 파일을 wiki/ 로 옮긴 뒤 연결로 바꾼다.
// 같은 이름이 이미 wiki/ 에 있고 내용이 다르면 덮어쓰지 않고 .omc/wiki-local-backup/ 에 남긴다.

export const WIKI_DIR = join(REPO_ROOT, "wiki");
const OMC_WIKI = join(REPO_ROOT, ".omc", "wiki");

function linkTarget(p) {
  try {
    if (!lstatSync(p).isSymbolicLink()) return null;
    return resolve(dirname(p), readlinkSync(p));
  } catch {
    return null;
  }
}

/** @returns {boolean} 맞출 필요가 있으면 true */
export function needsWikiLink() {
  if (!existsSync(join(REPO_ROOT, ".omc"))) return false;
  const t = linkTarget(OMC_WIKI);
  return !(t && resolve(t).toLowerCase() === resolve(WIKI_DIR).toLowerCase());
}

/** @returns {string[]} 한 일 */
export function applyWikiLink() {
  if (!needsWikiLink()) return [];
  const done = [];
  mkdirSync(WIKI_DIR, { recursive: true });

  let isDir = false;
  try {
    isDir = lstatSync(OMC_WIKI).isDirectory() && !lstatSync(OMC_WIKI).isSymbolicLink();
  } catch {
    /* 없음 */
  }
  if (isDir) {
    const backup = join(REPO_ROOT, ".omc", "wiki-local-backup");
    for (const name of readdirSync(OMC_WIKI)) {
      const from = join(OMC_WIKI, name);
      const to = join(WIKI_DIR, name);
      if (!existsSync(to)) {
        renameSync(from, to);
        done.push(`옮김 ${name}`);
      } else if (readFileSync(from, "utf8") === readFileSync(to, "utf8")) {
        rmSync(from, { force: true });
      } else {
        mkdirSync(backup, { recursive: true });
        renameSync(from, join(backup, name));
        done.push(`내용이 달라 백업 ${name} → .omc/wiki-local-backup/`);
      }
    }
    rmSync(OMC_WIKI, { recursive: true, force: true });
  } else if (linkTarget(OMC_WIKI) !== null) {
    rmSync(OMC_WIKI, { force: true }); // 다른 곳을 가리키는 연결
  }
  symlinkSync(WIKI_DIR, OMC_WIKI, process.platform === "win32" ? "junction" : "dir");
  done.push(".omc/wiki → wiki/ 연결");
  return done;
}

/** 묻지 않고 맞추는 것 전부(HUD + 위키 공유). 세션 시작 hook과 상태줄 래퍼가 부른다. */
export function applyAuto() {
  return [...applyHud(), ...applyWikiLink()];
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
    const c = applyAuto();
    console.log(c.length ? `HUD·위키 공유 맞춤:\n${c.map((t) => `  - ${t}`).join("\n")}` : "HUD·위키 공유: 이미 기준과 같음");
  }
  if (what === "git" || what === "all") {
    const c = applyGit();
    console.log(c.length ? `git 설정 맞춤:\n${c.map((t) => `  - ${t}`).join("\n")}` : "git: 이미 기준과 같음");
  }
  if (!what) {
    const h = diffHud();
    const g = diffGit();
    console.log(h.length ? `HUD 차이:\n${h.map((d) => `  - ${d.target}`).join("\n")}` : "HUD: 기준과 같음");
    console.log(needsWikiLink() ? "위키 공유 차이: .omc/wiki 가 저장소 wiki/ 를 가리키지 않음" : "위키 공유: 기준과 같음");
    console.log(g.length ? `git 차이:\n${describeGitDiff(g)}` : "git: 기준과 같음");
  }
}
