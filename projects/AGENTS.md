# projects

**Parent context:** `../AGENTS.md`
**Generated:** 2026-11-15 · **Updated:** 2026-11-15

## Purpose
개별 프로젝트를 담는 폴더. 각 프로젝트의 고유 규칙은 그 폴더의 `CLAUDE.md`에 있고, 공통 규칙은 루트 `CLAUDE.md`에 있다.

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `loan/` | OMC 연습용 도서 대출 모듈, Java/Maven (see `loan/AGENTS.md`) |
| `apps/` | 앱 그룹. 앱은 `apps/<앱>/`에 둔다. 아직 앱·공통 규칙 없음(`.gitkeep`만 있음) |

## For AI Agents

### Working In This Directory
- 새 앱은 `projects/apps/<앱>/`에, 그 밖의 프로젝트는 `projects/<name>/`에 만들고 그 안에 `CLAUDE.md`를 둔다(구조는 루트 `CLAUDE.md`의 "앱을 여러 개 만들 때"). 프로젝트가 자체 git 저장소여도 OMC 상태는 루트 `.omc/`로 모인다(`.omc-workspace` 앵커)

## Manual Notes
