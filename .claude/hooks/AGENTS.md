# .claude/hooks

**Parent context:** `../../AGENTS.md`
**Generated:** 2026-11-15 · **Updated:** 2026-11-15

## Purpose
Claude Code hook 스크립트. Gitea(`origin`)와 로컬을 비교해, 받을 커밋·올릴 커밋·커밋 안 한 변경이 있으면 Claude가 사용자에게 pull/push를 묻게 한다. `.claude/settings.json`의 `hooks`에서 등록한다.

## Key Files
| File | Description |
|------|-------------|
| `sync-core.mjs` | 공통 비교 로직. `git fetch` 후 로컬·원격 차이를 계산하고, 정시 구간(예: 14:00~14:59) 기록을 `.git/cp-sync-check.json`에 둔다. 비대화식으로 실행(`GIT_TERMINAL_PROMPT=0`, `GCM_INTERACTIVE=never`) |
| `session-start.mjs` | SessionStart(startup·resume). 점검 결과를 한 줄로 띄우고, 차이가 있으면 첫 대답에서 먼저 묻게 한다. `env/sync.mjs`로 환경 설정을 맞춘다 — HUD는 자동, git 설정은 차이가 있으면 Claude가 묻게 한다 |
| `sync-check.mjs` | Stop(대답 종료). 정시 구간마다 한 번만 점검하고 결과를 한 줄로 띄운다. 차이가 있으면 대답을 막고 AskUserQuestion으로 묻게 한다. `stop_hook_active`면 다시 막지 않는다 |
| `version-check.mjs` | winget 저장소에 더 높은 Claude Code 버전이 올라왔을 때만 알린다. 하루 한 번 조회하며 기록은 `.git/cp-version-check.json`. `session-start.mjs`가 쓴다 |

## For AI Agents

### Working In This Directory
- hook은 묻게만 한다. 사용자가 고르기 전에 pull/push/commit 하지 않는다
- 조회와 설치를 섞지 않는다. `winget upgrade`는 조회가 아니라 설치를 수행하므로 hook에서 쓰지 않는다(`winget list`만 쓴다)
- fetch가 인증 실패·시간 초과로 실패해도 오류로 멈추지 않고 "원격 확인 실패"로 알린다. Gitea 로그인(OAuth) 출입증이 만료되면 이 상태가 된다
- 반복 실행(loop·cron) 방식은 사용자가 거부했다. 정시 구간 단위 점검을 유지한다

### Testing Requirements
- `node --check <파일>`(문법). 동작은 세션을 다시 시작하거나 대답을 마쳐서 화면의 `[git 동기화 점검 · N시]` 줄로 확인한다

## Dependencies

### Internal
- `../settings.json`(등록), `../../env/sync.mjs`(환경 설정 맞추기)

### External
- git, Node.js

## Manual Notes
