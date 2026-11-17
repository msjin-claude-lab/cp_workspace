# env

**Parent context:** `../AGENTS.md`
**Generated:** 2026-11-16 · **Updated:** 2026-11-16

## Purpose
모든 PC에 똑같이 둘 **환경 설정의 기준**. 각 PC의 사용자 설정(`~/.claude/…`, git config)은 여기를 기준으로 맞춰진다. 환경 설정을 바꾸려면 PC에서 직접 고치지 말고 여기를 고쳐 커밋한다.

## Key Files
| File | 맞추는 대상 | 적용 |
|------|-------------|------|
| `sync.mjs` | 아래 전부. 비교·적용 공통 코드. `node env/sync.mjs`(차이 보고), `--apply hud|git|all` | — |
| `hud/omc-hud-gauge.mjs` | `~/.claude/hud/omc-hud-gauge.mjs` — HUD 래퍼(게이지 문자 복원, 줄 배치, git 상태 `main M2 +1 ↑1 ↓2`) | 자동 |
| `hud/hud-config.json` | `~/.claude/.omc/hud-config.json` — HUD에 보일 항목과 순서 | 자동 |
| (없음) | `~/.claude/settings.json`의 `omcHud` 키 — **제거**. 있으면 OMC가 hud-config.json보다 먼저 읽어 기준을 가린다 | 자동 |
| (없음) | `.omc/wiki` → 저장소 `wiki/` 연결(Windows 정션). OMC는 위키 위치를 바꾸는 설정이 없어 연결로 저장소에 둔다. `.omc/wiki`가 진짜 폴더면 파일을 `wiki/`로 옮긴 뒤 연결로 바꾸고, 내용이 다른 같은 이름 파일은 `.omc/wiki-local-backup/`에 남긴다 | 자동 |
| `git/git-config.json` | git config — Gitea 로그인 방식(`wincred`), `provider generic`, `allowUnsafeRemotes`, `origin` 주소 | **물어본 뒤** |

## 언제 맞춰지나
- **세션 시작**: `.claude/hooks/session-start.mjs`가 HUD와 위키 연결을 맞추고, git 설정 차이가 있으면 Claude가 적용 여부를 묻게 한다
- **pull 직후**: 상태줄 래퍼가 갱신될 때마다 작업 폴더에서 저장소를 찾아 HUD와 위키 연결을 맞춘다 → 재시작 없이 반영. 래퍼 자체가 바뀐 경우는 그다음 갱신부터 보인다
- 정시 점검 hook(`sync-check.mjs`)이 원격 변경을 찾아 pull을 묻는다 → pull → 위 자동 반영으로 이어진다
- 덮어쓰기 전 원본은 `<파일>.before-env-sync`로 백업된다(직전 하나만)

## For AI Agents

### Working In This Directory
- **HUD 2줄 구조는 고정이다(2026-11-17 사용자 결정).** 1줄 `ctx:[…]N% | 모델 effort | 브랜치 git 상태`, 2줄 `⠀5H:[…] WK:[…] Fable:[…]`. 줄 끝에 항목이 덧붙는 것은 괜찮지만, ctx를 1줄에서 빼거나 사용량 줄을 2줄에서 밀어내는 등 이 구조를 깨는 변경은 요청받아도 거부하고 이유를 말한다. 래퍼(`moveCtxFirst`)가 OMC 출력이 잘려도 이 구조를 다시 세운다
- **HUD 모양 미리보기는 상태줄로 한다.** 대화창의 `!` 출력은 ANSI 색을 그리지 않는다. Claude Code가 Zed 터미널에서 돌 때(`TERM_PROGRAM=zed`) 색 속성 진단은 Zed 새 터미널 탭에서 `!` 없이 실행한다. 자세한 사실은 `wiki/hud.md`
- HUD를 바꿔 달라는 요청은 `env/hud/`를 고친다. `/oh-my-claudecode:hud`나 `~/.claude/.omc/hud-config.json` 직접 수정은 다음 동기화 때 기준으로 덮어써진다
- git 설정은 자동 적용하지 않는다. 로그인 방식이 바뀌면 다시 로그인해야 할 수 있고, 사내망 PC 환경 변경은 먼저 묻는 것이 규칙이다(루트 CLAUDE.md)
- 작성자 이름·이메일, GitHub 원격(개인 PC만)처럼 PC마다 달라야 하는 것은 넣지 않는다

### Testing Requirements
- `node --check env/sync.mjs env/hud/omc-hud-gauge.mjs`
- `node env/sync.mjs` — 차이 보고(아무것도 바꾸지 않음)
- 래퍼 확인: 상태줄 명령을 샘플 입력으로 실행해 줄 배치를 본다. 모양은 사람이 화면에서 최종 확인한다

## Dependencies

### External
- OMC HUD(`~/.claude/hud/omc-hud.mjs`), Node.js, git

## Manual Notes
