# tools

**Parent context:** `../AGENTS.md`
**Generated:** 2026-11-15 · **Updated:** 2026-11-15

## Purpose
저장소에 두고 각 PC의 사용자 설정 폴더로 복사해 쓰는 보조 스크립트.

## Key Files
| File | Description |
|------|-------------|
| `omc-hud-gauge.mjs` | OMC HUD 상태바 래퍼. OMC가 출력 직전에 블록 문자를 ASCII(`#`, `=`, `-`)로 바꾸는 것을 `█▓░`로 되돌린다. 같은 프로세스에서 stdout만 가로챈다 |

## For AI Agents

### Working In This Directory
- 실제로 실행되는 사본은 `~/.claude/hud/omc-hud-gauge.mjs`다. `.claude/hooks/session-start.mjs`가 세션 시작 때 이 파일을 그 위치로 맞춰 복사한다 — 여기를 고치면 다음 세션부터 반영된다
- 상태바 설정(`statusLine`)은 `.claude/settings.json`에 있다

### Testing Requirements
- `node --check omc-hud-gauge.mjs`(문법). 모양은 Claude Code를 다시 시작해 사람이 눈으로 확인한다(2줄 HUD, `[██░░░░░░]` 게이지)

## Dependencies

### External
- OMC HUD(`~/.claude/hud/omc-hud.mjs`), Node.js

## Manual Notes
