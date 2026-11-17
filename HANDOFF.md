# 이어서 작업하기

마지막 갱신: 2026-11-17 (사내망 PC)

워크스페이스 구성은 끝났다. 이 문서는 **다음에 이어서 할 일**과 **중단된 작업의 조사 결과**만 담는다.
환경 사실·규칙은 [CLAUDE.md](CLAUDE.md), 연습 과제는 [projects/loan/PRACTICE.md](projects/loan/PRACTICE.md)에 있다.

## 지금 상태

| 항목 | 상태 |
|---|---|
| 워크스페이스 구성 | 완료 |
| OMC | npm 전역 5.8.4, 글로벌·로컬 `CLAUDE.md` 모두 설치됨. 두 PC 모두 **플러그인**으로 씀(`/oh-my-claudecode:` 접두사). 사내망 PC는 GitHub 차단 때문에 npm 패키지 폴더를 로컬 마켓플레이스로 등록해 설치(2026-11-17) — [CLAUDE.md의 "답변 형식"](CLAUDE.md#답변-형식--모든-pc-공통) |
| 원격 저장소 | Gitea(기준) → GitHub(푸시 미러, 읽기 전용). 두 PC 모두 `origin` = Gitea. 구성은 [CLAUDE.md의 "git"](CLAUDE.md#git) |
| Claude Code 설정 | 프로젝트 `.claude/settings.json`에 둠 — agent teams, HUD 상태바, hook. 모든 PC 공통 ([CLAUDE.md의 "PC 간 이어가기"](CLAUDE.md#pc-간-이어가기--설정작업진행-현황)) |
| 연습 프로젝트 | `projects/loan/` — **과제 1~6 완료**(2026-11-13~17). 과제 7~9는 남음 |
| `mvn -q test` | **37개 모두 통과** (과제 4 완료 후. 연체료 6 + 대출·반납 10 + 연장 10 + 관리자 11) |

## 연습 과제 진행 ([PRACTICE.md](projects/loan/PRACTICE.md))

| 과제 | 상태 | 기록 |
|---|---|---|
| 1. 실패하는 테스트 — `/debug` | **완료** (2026-11-13, 개인 PC) | 아래 |
| 2. 미구현 기능 — `/tdd` | **완료** (2026-11-13, 개인 PC) | 아래 |
| 3. 지저분한 코드 — review·simplify·tdd·ai-slop-cleaner | **완료** (2026-11-15, 개인 PC) | 아래 |
| 4. 보안 문제 — `/security-review` | **완료** (2026-11-16, 사내망 PC) | 아래 |
| 5. 검증 습관 — `/verify`, `/create-verification-skill` | **완료** (2026-11-15, 개인 PC) | 아래 |
| 6. 문서 없는 코드 — `/how`, `/deepinit`, `/wiki`, `/teach` | **완료** (2026-11-15 개인 PC · 2026-11-17 사내망 PC) | 아래 |
| 7. 변경 파급 — `/blast-radius`, `/architect` | **다음** | |
| 8~9 | 남음 | |

### 과제 1 — 연체료 테스트 실패

- 증상: `FeeCalculatorTest.chargesOnlyDaysBeyondGrace:41 expected: <1000> but was: <2500>` — 예외가 아니라 결과값 불일치(Failures 1, Errors 0)
- 원인: `FeeCalculator.java:41`이 유예 3일을 빼지 않고 연체 일수 전체에 부과했다(5일 × 500 = 2500). 37줄의 유예 판정은 맞았다
- 수정: `fee = (daysLate - GRACE_DAYS) * DAILY_FEE` 한 줄. 이후 `mvn -q test` 14/14 통과
- 결함이 드러나는 범위: 4일 이상·상한(10,000원) 미만 연체만. 0~3일은 37줄에서 끝나고 365일은 상한에 걸려 결과가 같다
- 하지 않은 것: 경계값 테스트(4일 연체 → 500원) 추가는 선택으로 남겼다
- 참고: 실행한 `/debug`는 Claude Code 내장 명령(세션 디버그 로그)이었다. OMC 스킬은 `/oh-my-claudecode:debug`, `/oh-my-claudecode:trace`처럼 접두사를 붙여야 한다
- 원래 결함 상태로 되돌려 다시 연습하려면: `git checkout a3f27b4 -- projects/loan`

### 과제 2 — `RenewalPolicy` 구현 (`/oh-my-claudecode:tdd`)

- 테스트할 곳(seam)을 먼저 합의: `canRenew`, `renew` 두 메서드. 외부 의존 없는 순수 계산. null 처리도 포함하기로 정함
- 기대값의 근거: `RenewalPolicy` javadoc 규정 5가지(최대 2회, 연체 중 불가, 정지 회원 불가, 타인 예약 시 불가, 기존 반납일 +14일). null 처리만 규정에 없어 `FeeCalculator` 방식(IllegalArgumentException)을 따름
- 진행: 테스트 하나 → 실패(red) 확인 → 최소 구현 → 통과(green)를 10번 반복. `RenewalPolicyTest` 10개
- 결과: `mvn -q test` 24/24 통과 (기존 14개도 깨지지 않음)
- 남긴 것: 음수 연장 횟수는 테스트 안 함 / `renew`는 `canRenew`를 다시 확인하지 않음 / 아직 `RenewalPolicy`를 쓰는 곳이 없음
- 원래 상태로 되돌려 다시 연습하려면: `git checkout 52a0a00 -- projects/loan` 후 `projects/loan/src/test/java/practice/loan/RenewalPolicyTest.java` 삭제

### 과제 3 — `LoanService` 정리 (2026-11-15, 개인 PC)

순서: review(점검) → simplify(정리) → tdd(버그 수정) → ai-slop-cleaner(군더더기 제거) → ai-slop-cleaner `--review`(독립 검토)

- review: 지저분한 코드 5종(복사된 null 검사, 3번 반복된 반복문, 겹친 if/else, 매직 넘버 5·14, 코드를 읽어 주는 주석)과 **PRACTICE.md에 없던 버그 2개**를 찾음. 버그는 `jshell`로 재현
  - ① 같은 ISBN의 다른 `Book` 객체로 반납하면 빌려 간 책이 계속 대출 불가로 남음
  - ② `findActiveLoans(null)`이 거부하지 않음 — 대출 기록이 없으면 오류 없이 빈 목록, 있으면 NPE
- simplify: 4관점(재사용·단순화·효율·구조 위치) 검토 후 정리. 125줄 → 86줄. 정리 중 조건 순서를 바꿔 null 동작이 달라진 것을 재현 스크립트로 잡아 되돌림(테스트 24개로는 안 잡혔다)
- tdd: 버그마다 테스트를 먼저 쓰고 red 확인 후 수정. ①은 `target.getBook().setAvailable(true)`, ②는 null 검사 추가. `LoanServiceTest` 8 → 10개
- ai-slop-cleaner: simplify 때 넣은 작업 기록 주석 1줄만 삭제
- `--review` 독립 검토(code-reviewer): 승인. 의도한 버그 수정 2개 외 동작 변경 없음
- 남긴 것(검토자 권장): 오류 **메시지**와 우선순위(정지 회원 + 대출 중 도서), `returnBook`의 null 거부, 같은 ISBN 중복 대출 시 선택을 고정하는 테스트가 없음. 지금 테스트는 예외 종류만 본다
- 원래 상태로 되돌려 다시 연습하려면: `git checkout fb42bcc -- projects/loan`

### 과제 4 — `AdminGate` 보안 (2026-11-16, 사내망 PC)

- `/security-review AdminGate.java`: 변경 사항이 없어서 diff 대신 파일 전체를 검토했다. 결함 5개를 찾았지만, 확신도 8 이상만 보고하는 규칙 때문에 보고서에는 3개만 남았다(SQL 인젝션 7점, 개인정보 로그 6점은 빠짐). 연습용 결함을 다 보려면 이 기준을 감안해야 한다
- 찾은 결함: ① 관리자 토큰 하드코딩(14행) ② 입력 토큰을 인증 판정 전에 로그에 기록(18-21·32행) ③ 감사 기록에 실제 토큰 포함(43행) ④ 이름·이메일 로그 기록 ⑤ 검색어를 SQL에 이어 붙임(38행)
- 고침: 토큰은 생성자 또는 환경변수 `LOAN_ADMIN_TOKEN`에서 받고, 없으면 전부 거부한다. 비교는 `MessageDigest.isEqual`(상수 시간). 로그와 감사 기록에는 회원 id만 남긴다. 검색은 `buildMemberQuery()`(자리표시자) + `memberSearchParam()`(LIKE 이스케이프)로 나눴다
- 테스트 우선: `AdminGateTest` 11개를 먼저 쓰고 실패(컴파일 실패)를 확인한 뒤 고쳤다. `mvn -q clean test` 37/37 통과
- 바뀐 API: `buildMemberQuery(String)` → `buildMemberQuery()` + `memberSearchParam(String)`, `auditLine` 형식 `id | 행위`. 호출하는 곳이 없어 다른 코드는 영향 없음
- 원래 결함 상태로 되돌려 다시 연습하려면: `git checkout f993665 -- projects/loan/src/main/java/practice/loan/AdminGate.java` 후 `AdminGateTest.java` 삭제

### 과제 5 — 검증 습관 (2026-11-15, 개인 PC)

- `/oh-my-claudecode:verify`로 과제 3의 완료 주장을 다시 확인. 처음 실행은 `mvn -o clean`이 플러그인 미설치로 시작도 못 했는데, **지난 실행의 결과 파일 때문에 "26개 통과"로 보였다** — 종료 코드(1)로 잡아냄. `target`을 지우고 다시 돌려 통과 확인
- `/oh-my-claudecode:create-verification-skill`로 이 저장소 전용 `/verify` 스킬(`.claude/skills/verify/SKILL.md`)을 만듦. 명령은 모두 실행해 확인, 판정은 종료 코드 + 새로 생성된 결과 파일

### 과제 6 — 문서 없는 코드 (2026-11-15 개인 PC · 2026-11-17 사내망 PC)

- `/oh-my-claudecode:how 대출과 반납은 어떻게 동작하나`: 탐색 에이전트가 줄 번호 지도를 만들고, 그 지도로 설명을 씀 (2026-11-15)
- `/oh-my-claudecode:deepinit`: 의미 있는 폴더 7곳에 `AGENTS.md` 생성 (2026-11-15). 하위 폴더 AGENTS.md는 OMC hook이 켜져 있어야 읽힌다
- `/oh-my-claudecode:wiki`: 소스 7개를 읽고 `wiki_ingest`로 [wiki/loan.md](wiki/loan.md)(대출·반납·연체료·연장 구조) 작성. `wiki_lint` 깨진 링크·모순 0 (2026-11-17)
- `/oh-my-claudecode:teach 대출과 반납`: 수준 질문("Java 익숙, 도메인 처음") → How(코드 줄 인용) → Why 4가지(유예일 뺀 부과, 연장은 기존 예정일 기준, 반납은 대출 기록의 `Book`을 되돌림, 연장 정책이 서비스와 분리) → 예측 질문. 4일 연체 500원·연체 중 `canRenew` false 모두 맞힘 (2026-11-17)
- 수업 중 드러난 것: 연체료 **납부 개념이 없다**(반납 때 금액만 계산). 유예 3일은 연체료에만 적용되고 연장에는 안 된다(예정일 하루만 지나도 `canRenew` false). **예약 기능이 없다** — `reservedByOther`는 `canRenew` 매개변수뿐이라 반납된 예약 도서를 아무나 `checkout`할 수 있다. 과제 7 재료로 쓸 만하다

## 남은 일

| 할 일 | 사내망 PC | 개인 PC |
|---|---|---|
| 환경 설정 공통화 받기 (`env/`, `wiki/`, 답변 형식 — 2026-11-16 개인 PC) | 완료 (2026-11-17). 처음 한 번은 설치돼 있던 이전 HUD 래퍼에 자동 맞춤 코드가 없어 `node env/sync.mjs --apply hud`로 수동 적용. `wincred` 적용 시 GCM이 남긴 OAuth 항목 3개를 `cmdkey /delete`로 지우고 토큰을 다시 넣음 | 완료 |
| git HTTP 경고 끄기 (`credential.allowUnsafeRemotes`) | 완료 (2026-11-16) | 완료 (2026-11-16, `env/git` 기준으로 적용) |
| OMC를 플러그인으로 전환 | 완료 (2026-11-17) — `claude plugin marketplace add <npm 전역>\oh-my-claude-sisyphus` → `claude plugin install oh-my-claudecode@omc`. npm 방식 복사본(`~/.claude/skills/` OMC 스킬 84개, `~/.claude/agents/` 19개, `~/.claude/hooks/`와 `settings.json`의 OMC hook 8개)은 플러그인과 겹쳐 `~/.claude/backup-npm-omc-2026-11-17/`로 옮김(2026-11-17). 이후 저장소 전용 `/verify`가 OMC `verify`에 가려지지 않는다. `npm i -g oh-my-claude-sisyphus`로 OMC를 올린 뒤 복사본이 다시 생기면 같은 방식으로 정리 | 확인 필요 — 같은 중복이 있는지 |
| HUD 상태바 눈으로 확인 — 1줄 `ctx \| 모델 \| main M2 +1 ↑1`(ctx는 하늘색·주황·자홍, 버전 라벨 없음 — 2026-11-17 변경), 2줄 5H·WK·Fable(초록·노랑·빨강) | 남음 | 남음 |
| `/team` 동작 확인 | 남음 | 남음 |

### 사내망 PC에서 받는 순서 (환경 설정 공통화)

1. `git pull`
2. **Claude Code를 새로 시작한다.** 답변 형식 규칙(`CLAUDE.md`)은 세션을 시작할 때 읽힌다 — 기존 대화를 이어가면 반영되지 않는다
3. 세션 시작 hook이 자동으로 맞춘다(`env/sync.mjs`)
   - HUD 래퍼와 표시 항목(`env/hud/`) — session·callCounts 표시가 꺼지고, `~/.claude/settings.json`의 `omcHud`가 있으면 백업 후 지워진다
   - `D:\cp_workspace\.omc\wiki`가 `D:\cp_workspace\wiki`를 가리키는 연결(정션)로 바뀐다. 이미 만든 위키 페이지는 `wiki/`로 옮겨지고, 같은 이름인데 내용이 다르면 `.omc/wiki-local-backup/`에 남는다
4. git 설정 차이(`env/git/` — 특히 로그인 방식 `wincred`)가 있으면 Claude가 적용할지 묻는다. `wincred`를 적용하면 **별도 PowerShell 창**에서 `git push`(또는 `git fetch`)를 한 번 해서 계정 + Gitea 토큰을 넣는다
5. 이후 사내망 PC에서 만든 위키 페이지는 `wiki/`에 저장된다. 다른 파일처럼 **커밋·push해야** 개인 PC로 넘어간다
6. 확인: `node env/sync.mjs` → `HUD`, `위키 공유`, `git`이 모두 "기준과 같음"

주의: 사내망 PC에 `OMC_STATE_DIR` 환경 변수가 있으면 OMC가 `.omc`를 다른 곳에 두므로 위키 연결이 쓰이지 않는다(개인 PC에는 없음, 사내망 PC는 미확인).

HUD와 `/team`은 사람이 직접 봐야 한다. 둘 다 Claude Code **시작 시** 읽힌다.

1. 상태바가 2줄 OMC HUD로 나오고 게이지가 `[██░░░░░░]` 모양인지, 폭이 밀리지 않는지
2. `/team` 이 동작하는지 — 과제 1은 끝났으니 PRACTICE.md 9번 과제(여러 작업 한 번에)에서 `/team 2:executor "..."`로 확인한다

## 해결된 것 — 기록

### 개인 PC — JDK 21이 `java`로 잡히지 않던 문제 (2026-11-12 해결)

Microsoft OpenJDK 21.0.13(`C:\Java\jdk-21.0.13.0.2+1`)과 Maven 3.9.16(`C:\Java\apache-maven-3.9.16`)을 설치하고 사용자 환경 변수(`JAVA_HOME`, `Path` 앞쪽)에 등록했는데도 `java -version`이 17로 나왔다.

원인: **시스템 `Path`**에 `C:\Java\jdk-17\bin`이 있었다. Windows는 시스템 `Path`를 사용자 `Path`보다 앞에 둔다. (처음 조사 때 `[Environment]::GetEnvironmentVariable('Path','Machine')`로는 보이지 않아 놓쳤다 — 레지스트리를 `GetValue(..., 'DoNotExpandEnvironmentNames')`로 직접 읽어야 했다.)

조치: 관리자 권한으로 시스템 `Path`의 그 항목을 `C:\Java\jdk-21.0.13.0.2+1\bin`으로 바꿨다. 바꾸기 전 값은 `C:\Users\User\machine-path-backup.txt`. 새로 읽은 셸에서 `java -version` = 21.0.13 확인. 이미 떠 있던 프로그램(Zed 등)은 로그아웃·재로그인 후 반영된다.

Maven은 그 전에도 `JAVA_HOME`을 따라 JDK 21로 돌았다. JDK 17 폴더는 지우지 않았다.

### 사내망 PC — Gitea 원격 전환 (2026-11-12 완료)

번들 시점(`079f999`)에 멈춰 있던 저장소를 Gitea `origin`으로 전환했다. 사내망에서 `222.112.172.253:9080`으로 clone·fetch·push가 되는 것을 실측했다(커밋 `f0948af`). 연결이 안 될 때의 점검 절차는 [docs/gitea-check.md](docs/gitea-check.md)에 있다.

### HUD 게이지 — 래퍼 스크립트

게이지가 `[##------]`로 나오던 것을 `[██░░░░░░]`로 되돌렸다. 사용법은 [CLAUDE.md의 "HUD 게이지"](CLAUDE.md#hud-게이지)에 있다.

- 스크립트: `env/hud/omc-hud-gauge.mjs` (2026-11-16 `tools/`에서 옮김, 환경 설정 공통화)
- 설치 위치: `~/.claude/hud/omc-hud-gauge.mjs` — 세션 시작 hook이 저장소 버전을 복사한다. 프로젝트 `.claude/settings.json`의 `statusLine.command`가 이걸 가리킨다

원인은 `dist/hud/sanitize.js`의 `replaceUnicodeBlocks()`가 설정·터미널 감지 없이 `█`→`#`, `░`→`-`로 무조건 치환하는 것이었다. 공식 설정으로는 끌 수 없어 출력을 후처리한다.

**아직 눈으로 확인 못 한 것:** `█`(U+2588)·`░`(U+2591)은 동아시아 환경에서 **폭이 모호한(Ambiguous) 문자**다. 한국어 로케일 터미널이 2칸으로 그리면 게이지 폭이 밀린다 — OMC가 ASCII로 바꾼 진짜 이유가 이것이다(`sanitize.js` 주석, issue #346). 밀리면 프로젝트 `.claude/settings.json`의 `statusLine.command`에서 `omc-hud-gauge.mjs`를 `omc-hud.mjs`로 되돌린다.

## 다른 PC에서 이어가기

절차는 [CLAUDE.md의 "다른 PC로 옮기기"](CLAUDE.md#다른-pc로-옮기기)에 있다. 요약하면:

1. 받는 PC: `git clone http://222.112.172.253:9080/msjin-claude-lab/cp_workspace.git D:/dev/workspace` — 공개 저장소라 clone·pull은 로그인 없이 된다
2. push는 **Gitea에만** 한다. 처음 push할 때 Gitea 계정 이름 + 액세스 토큰으로 로그인한다. GitHub는 Gitea 푸시 미러가 맞춘다
3. 작업 중에는 정시 구간마다 sync-check hook이 Gitea와 비교해 pull/push 여부를 묻는다. 마칠 때는 이 문서를 갱신하고 push한다
4. Claude Code 설정은 저장소에 있다. 새 PC에서 한 번 할 일(로그인, OMC·JDK·Maven 설치, Gitea 토큰)은 [CLAUDE.md의 표](CLAUDE.md#저장소에-들어-있지-않은-것--새-pc에서-한-번)를 따른다

Gitea에 접근할 수 없으면 CLAUDE.md의 "예비 수단 — git bundle"을 쓴다.

새 세션은 이렇게 시작하면 된다:

```
D:\dev\workspace 에서 작업을 이어서 한다. HANDOFF.md 를 읽고 시작해라.      (개인 PC)
D:\cp_workspace 에서 작업을 이어서 한다. HANDOFF.md 를 읽고 시작해라.      (사내망 PC)
```
