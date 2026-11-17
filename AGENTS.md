# cp_workspace

**Generated:** 2026-11-15 · **Updated:** 2026-11-15

## Purpose
Claude Code + oh-my-claudecode(OMC) 연습 워크스페이스. 여러 프로젝트가 공유하는 환경 규칙·hook·도구와, 결함을 일부러 심어 둔 연습 프로젝트(`projects/loan`)가 있다. 개인 PC(`D:\dev\workspace`)와 사내망 PC(`D:\cp_workspace`)에서 Gitea를 통해 이어서 작업한다.

## Key Files
| File | Description |
|------|-------------|
| `CLAUDE.md` | 공통 규칙의 원본 — 망 제약, git 원격, PC 간 이어가기, hook, 작업 규칙. **이 파일과 겹치는 내용은 CLAUDE.md가 우선한다** |
| `HANDOFF.md` | 지금 상태, 연습 과제 진행, PC별 남은 일. 새 세션은 이것부터 읽는다 |
| `README.md` | 사람용 요약 |
| `.omc-workspace` | OMC 상태(`.omc/`)를 이 루트 하나로 모으는 앵커 |
| `.gitignore` | `.omc/*` 무시(`.omc/skills/`만 예외) |

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `projects/` | 개별 프로젝트 (see `projects/AGENTS.md`) |
| `wiki/` | OMC 위키(`/oh-my-claudecode:wiki`) 페이지. `.omc/wiki`가 이 폴더를 가리키는 연결이라 OMC가 쓴 페이지가 곧 커밋 대상이 된다 |
| `env/` | 모든 PC에 맞출 환경 설정의 기준 — HUD·git 설정. 세션 시작·pull 직후 자동 반영 (see `env/AGENTS.md`) |
| `.claude/hooks/` | 세션 시작·대답 종료 시 git 동기화 점검 hook (see `.claude/hooks/AGENTS.md`) |
| `.claude/skills/` | 프로젝트 전용 스킬 — `verify`(이 저장소의 검증 절차), `wiki` |
| `.claude/` | `settings.json`(모든 PC 공통 설정). `.claude/CLAUDE.md`는 OMC 관리 영역이라 손대지 않는다 |

## For AI Agents

### Working In This Directory
- 규칙은 `CLAUDE.md`를 따른다. 특히: push는 Gitea(`origin`)에만, GitHub에 직접 push 금지. 토큰은 채팅·저장소에 넣지 않는다
- 커밋·push는 사용자가 요청할 때만 한다
- 세션을 마칠 때 `HANDOFF.md`를 갱신한다

### Testing Requirements
- `/verify`(`.claude/skills/verify/SKILL.md`)의 명령을 쓴다. 통과는 종료 코드와 새로 생성된 결과 파일로만 판정한다

## Dependencies

### External
- JDK 21, Maven 3.9.x (`projects/loan`), Node.js (hook·HUD 스크립트), OMC(npm 전역 `oh-my-claude-sisyphus`)

## Manual Notes
