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
| 연습 프로젝트 | `projects/loan/` — **과제 1~9 모두 완료**(2026-11-13~17). 컴파일 타깃은 Java 21 |
| `mvn -q test` | **41개 모두 통과** (과제 9 완료 후. 연체료 6 + 대출·반납 13 + 연장 10 + 관리자 12) |
| 앱 (`projects/apps/`) | 그룹·공통 규칙만 있음. **다음: 1단계 만들 앱 정하기** — 아래 "앱" 절, [projects/apps/CLAUDE.md](projects/apps/CLAUDE.md) |

## 연습 과제 진행 ([PRACTICE.md](projects/loan/PRACTICE.md))

| 과제 | 상태 | 기록 |
|---|---|---|
| 1. 실패하는 테스트 — `/debug` | **완료** (2026-11-13, 개인 PC) | 아래 |
| 2. 미구현 기능 — `/tdd` | **완료** (2026-11-13, 개인 PC) | 아래 |
| 3. 지저분한 코드 — review·simplify·tdd·ai-slop-cleaner | **완료** (2026-11-15, 개인 PC) | 아래 |
| 4. 보안 문제 — `/security-review` | **완료** (2026-11-16, 사내망 PC) | 아래 |
| 5. 검증 습관 — `/verify`, `/create-verification-skill` | **완료** (2026-11-15, 개인 PC) | 아래 |
| 6. 문서 없는 코드 — `/how`, `/deepinit`, `/wiki`, `/teach` | **완료** (2026-11-15 개인 PC · 2026-11-17 사내망 PC) | 아래 |
| 7. 변경 파급 — `/blast-radius`, `/architect` | **완료** (2026-11-17, 사내망 PC) | 아래 |
| 8. 레거시 버전 올리기 — `/triage`, `/to-java21` | **완료** (2026-11-17, 사내망 PC) | 아래 |
| 9. 여러 작업 한 번에 — `/team` | **완료** (2026-11-17, 사내망 PC) | 아래 |

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

### 과제 7 — 변경 파급 (2026-11-17, 사내망 PC)

주제는 과제 6 수업에서 드러난 "예약 기능 없음"을 이어받았다.

- `/oh-my-claudecode:blast-radius Book에 예약자 필드를 추가한다면`: 쓰는 곳을 확실(`new Book` 테스트 4곳, `checkout`)·가능성 높음(`returnBook`, `canRenew`의 `reservedByOther`, `Loan.getBook`)·낮음으로 나눔. scratchpad 복사본에서 실제 실행: 필드만 추가 → 37/37 통과 / 생성자 변경 → 테스트 4곳 컴파일 실패(예측과 일치) / `checkout`에 예약 검사 → **탐침 실패**: 같은 ISBN의 다른 `Book` 객체로 예약을 우회
- `/oh-my-claudecode:architect 예약 기능 — 별도 예약 기록만 둘지, 서지·소장본까지 나눌지`: architect 에이전트 3개로 A(Book 필드+정규화 맵)·B(ISBN 키 예약 대장)·C(서지·소장본 분리) 비교 → **B로 결정**. 결정 기록은 [wiki/isbn.md](wiki/isbn.md)
- 덤으로 확인한 기존 버그: 같은 ISBN의 다른 `Book` 객체로 **대출 중인 책을 또 빌릴 수 있다**(탐침 `Tests run: 38, Failures: 1`). 결정 기록의 "허용한 변경 1"로 남김
- 하지 않은 것: 예약 기능 구현(과제 범위 밖). 하려면 결정 기록의 탐침 2개를 첫 테스트로 `/oh-my-claudecode:tdd`
- 주의: 에이전트 보고서의 줄 번호는 실제 파일과 맞지 않았다. 결정 기록에는 직접 확인한 근거만 적었다

### 과제 8 — 레거시 버전 올리기 (2026-11-17, 사내망 PC)

- `/triage projects/loan` → [projects/loan/TRIAGE_REPORT.md](projects/loan/TRIAGE_REPORT.md). 위험 요소(`sun.*`, Java EE 모듈, applet, Nashorn, SecurityManager, 예약어) 0건 → **21 직행 후보**. 루트에 `triage.sh`가 없어 grep으로 스캔. 대시보드 CLI는 개인 PC에만 있어 등록 생략
- `/to-java21 projects/loan`: 스킬은 SVN 기준이지만 이 저장소는 git이라 `git diff`로 대신함
  - 8 기준선: `source/target` → `maven.compiler.release=8`. 37/37, bootstrap 경고 사라짐
  - 11: 37/37, 경고 없음. 추가할 의존성 없음
  - 21: OpenRewrite `UpgradeToJava21` dryRun → 제안은 `release=21`, compiler 플러그인 3.13.0 → 3.16.0뿐(소스 변경 0). 적용 후 37/37, `Book.class` major version 65
- 실수 1건: pom.xml 주석에 `--`를 넣어 XML 파싱 실패 → 주석 수정
- 문서: `projects/loan/CLAUDE.md`·`AGENTS.md` 2개의 "Java 8 타깃, 올리지 말 것"을 현재 상태로 고침
- 다시 연습하려면: `git checkout af2c8ad -- projects/loan/pom.xml`(8 상태)
- **`/triage`·`/to-java21`은 OMC 스킬이 아니다.** 사내망 PC의 사용자 명령(`~/.claude/commands/triage.md`, `to-java21.md`, 2026-08-11 생성)으로, 사내 JDK 마이그레이션(SVN, `D:\dev\workspace\assistant` 대시보드) 업무용으로 보인다(추정). 저장소에는 없어 git으로 넘어가지 않는다 — 개인 PC에 같은 파일이 있는지 확인 필요

### 과제 9 — 여러 작업 한 번에 (2026-11-17, 사내망 PC)

주제는 앞 과제에서 남은, 파일이 겹치지 않는 두 가지: ① 과제 4 검토 지적(`AdminGate`) ② 과제 7에서 확인한 이중 대출(`LoanService`).

- `/oh-my-claudecode:team 2:executor`: worker-1(`AdminGate`·`AdminGateTest`·`pom.xml`), worker-2(`LoanService`·`LoanServiceTest`). 같은 폴더에서 동시에 `mvn`을 돌리면 `target/`이 꼬이므로 **각자 git worktree**에서 작업 → 리더가 cherry-pick으로 main에 합침
  - worker-1: `LIKE ? ESCAPE '!'`(MySQL/MariaDB에서 `\`는 문자열 이스케이프라 부적합), `!`→`!!` 먼저 이스케이프. H2 2.2.224(test)로 실제 쿼리 검증. red: 문자열 단정 2건 실패
  - worker-2: `checkout`의 "대출 중" 판정을 대출 기록 ISBN 조회(`isOnLoan`)로. 테스트 3개 추가. red: 이중 대출 2건 `nothing was thrown`
- team-verify(verifier 에이전트): **PASS-with-notes**. 지적 ① H2 테스트에 `!`·`\` 행이 없어 `!` 이스케이프 누락을 못 잡음 ② worker-1이 `pom.xml`·`AdminGate.java` 전체를 CRLF로 바꿔 diff가 280줄로 불어남
- team-fix(리더): LF 복원, H2에 `a!b`·`ab`·`a\b` 행과 단정 추가. **변이 실험**: `!` 이스케이프 줄을 지우면 H2 테스트까지 실패(`Failures: 2`) → 원복 후 green
- 결과: `mvn -q clean test` 41/41, exit 0. worktree 2개·브랜치 2개 정리
- 알게 된 것: executor가 줄 끝을 바꿀 수 있다 → 병합 전 `git diff --ignore-space-at-eol --stat`와 비교해 볼 것. verifier가 "통과하지만 잡지 못하는" 테스트를 짚어 냈고, 변이 실험으로 보강 효과를 확인함

### 세션 회고 — `/oh-my-claudecode:reflect` (2026-11-17, 사내망 PC)

검토 에이전트 3개(도구·판단·다른 길)가 오늘 대화 기록을 인용해 발견 9개 → 반복될 교훈 5개로 정리, 모두 반영:

- 백슬래시·한글 파일은 Edit 도구로(heredoc+Python에서 `\a`·`\b`가 제어 문자로 바뀌어 커밋 2번 다시 함) → [CLAUDE.md "작업 규칙"](CLAUDE.md)
- 테스트와 커밋은 `&&`로만(`;`로 이어 `test exit=1`인 채 push함) → CLAUDE.md, `.claude/skills/verify/SKILL.md`
- 화면 결과는 사용자 확인 전 "적용함, 화면 확인 필요"로만 보고, 안내할 방법은 먼저 직접 시험 → CLAUDE.md
- "기존대로" 정한 항목은 직접 언급 전까지 안 바꿈 → CLAUDE.md "답변 형식"
- HUD 렌더링 사실(`!`는 색 없음, Zed는 묶은 SGR을 버림, 줄 앞 공백 trim, OMC 4줄 자르기) → `env/AGENTS.md`, [wiki/hud.md](wiki/hud.md)
- 보류: 고정 입력 HUD 시험 스크립트, `commit-if-green` 스크립트(규칙으로 충분하다고 봄)
- 미해결: 커밋할 때마다 `geometric-repack` … `Permission denied`(`.git/objects/pack` 쓰기). 커밋·push는 정상

## 앱 (`projects/apps/`)

시작 기준은 [projects/apps/CLAUDE.md](projects/apps/CLAUDE.md)(시작하는 법·지금 상태·순서). 여기에는 단계별 자세한 기록만 쌓는다.

- 2026-11-17 사내망 PC: `projects/apps/` 그룹과 공통 규칙(새 앱 시작 순서 5단계, PC 역할) 마련. 앱은 아직 없음 — **1단계(만들 앱 정하기) 대기**. 이야기된 후보: 캘린더형·기록형(먼저), 게임형(나중). 언어·플랫폼은 1단계 뒤에 선택안으로 제시(참고로 비교했던 것: Flutter·React Native/Expo·Kotlin Multiplatform — 결정 아님)

## 남은 일

| 할 일 | 사내망 PC | 개인 PC |
|---|---|---|
| **앱 1단계 — 만들 앱 정하기** ([projects/apps/CLAUDE.md](projects/apps/CLAUDE.md)) | 어느 PC에서든 가능(이야기만) | 〃 |
| `/apps:` 플러그인 — **스킬은 필요할 때마다 하나씩 만든다(2026-11-18 사용자 결정).** 2026-11-18 사내망 PC에서 플러그인 `apps`와 빈 스킬 `new`(내용은 나중에 채움)를 만들어 설치함: `plugins/apps/.claude-plugin/plugin.json` + `plugins/apps/skills/new/SKILL.md` + 루트 `.claude-plugin/marketplace.json`(마켓플레이스 `cp-workspace`). 둘 다 `claude plugin validate` 통과. **설치(PC마다 한 번, 루트에서)**: `claude plugin marketplace add ./`(`.`만 쓰면 `Invalid marketplace source format`) → `claude plugin install apps@cp-workspace`. 원본 폴더를 그대로 읽으므로(`Read from: D:\cp_workspace\plugins\apps`) 스킬 수정은 재설치 없이 다음 세션·`/reload-plugins`로 반영. 개인 범위(user), `claude plugin uninstall apps@cp-workspace`로 삭제 | 설치함, `/apps:new` 화면 확인 필요 · `new` 내용 채우기 | 설치 필요 |
| OMC npm 복사본이 플러그인과 겹치는지 확인 | 완료 (2026-11-17, 아래 기록) | **확인 필요** |
| `/triage`·`/to-java21` 명령 파일(`~/.claude/commands/`)이 있는지 | 있음 | **확인 필요** — 없으면 과제 8 재연습 불가 |
| HUD 눈으로 확인 — 1줄 `ctx \| 모델 \| git \| 계정 이메일`, 2줄 `⠀5H·WK·Fable`(10칸) | 완료 (2026-11-17) | 남음 — pull 후 상태줄 확인 |
| `wiki/environment.md` — OMC 프로젝트 자동 감지가 세션 시작 때마다 내용 없는 페이지(`scripts: [object Object]`)를 만들어 "커밋 안 한 변경"으로 잡힌다. 지금은 매번 커밋에서 뺌 | `.gitignore`에 넣을지 결정 필요 | 〃 |
| 커밋 뒤 `geometric-repack … Permission denied` — git 자동 정리가 간헐적으로 실패(파일 잠금 추정). 커밋·push는 정상. 남은 임시 pack은 `git count-objects -v`의 garbage로 확인 후 삭제 | 가끔 발생 | 미확인 |
| Zed 1.28.1 설치 — 서명 확인(Zed Industries, Valid)한 설치 파일 `~\Downloads\Zed-x86_64.exe` | 설치 여부 미확인 | — |

## 해결된 것 — 기록

### 사내망 PC — 환경 설정 공통화 받기 (2026-11-17)

- `git pull` 후 HUD가 안 맞았던 것: 설치돼 있던 **이전** 래퍼에는 자동 맞춤 코드가 없어 처음 한 번은 `node env/sync.mjs --apply hud`로 수동 적용. 이후는 pull 직후 자동
- `wincred` 적용: GCM이 남긴 OAuth 항목 3개(`OAUTH_USER@…`, 주소, `refresh_token.…`)를 `cmdkey /delete`로 지우고 별도 창 `git push`에서 계정 + 액세스 토큰을 다시 넣음. 확인: `git credential fill`의 username이 `OAUTH_USER`가 아니라 계정 이름
- OMC 플러그인 전환: `claude plugin marketplace add <npm root -g>\oh-my-claude-sisyphus` → `claude plugin install oh-my-claudecode@omc`. npm 방식 복사본(`~/.claude/skills/` OMC 스킬 84개, `~/.claude/agents/` 19개, `~/.claude/hooks/`와 `settings.json`의 OMC hook 8개)은 `~/.claude/backup-npm-omc-2026-11-17/`로 옮김 → 저장소 `/verify`가 OMC `verify`에 가려지지 않게 됨. `npm i -g`로 OMC를 올린 뒤 복사본이 다시 생기면 같은 방식으로 정리
- `/team`: 과제 9에서 실제로 사용(executor 2개, worktree 격리) — 동작 확인됨

### 개인 PC — JDK 21이 `java`로 잡히지 않던 문제 (2026-11-12 해결)

Microsoft OpenJDK 21.0.13(`C:\Java\jdk-21.0.13.0.2+1`)과 Maven 3.9.16(`C:\Java\apache-maven-3.9.16`)을 설치하고 사용자 환경 변수(`JAVA_HOME`, `Path` 앞쪽)에 등록했는데도 `java -version`이 17로 나왔다.

원인: **시스템 `Path`**에 `C:\Java\jdk-17\bin`이 있었다. Windows는 시스템 `Path`를 사용자 `Path`보다 앞에 둔다. (처음 조사 때 `[Environment]::GetEnvironmentVariable('Path','Machine')`로는 보이지 않아 놓쳤다 — 레지스트리를 `GetValue(..., 'DoNotExpandEnvironmentNames')`로 직접 읽어야 했다.)

조치: 관리자 권한으로 시스템 `Path`의 그 항목을 `C:\Java\jdk-21.0.13.0.2+1\bin`으로 바꿨다. 바꾸기 전 값은 `C:\Users\User\machine-path-backup.txt`. 새로 읽은 셸에서 `java -version` = 21.0.13 확인. 이미 떠 있던 프로그램(Zed 등)은 로그아웃·재로그인 후 반영된다.

Maven은 그 전에도 `JAVA_HOME`을 따라 JDK 21로 돌았다. JDK 17 폴더는 지우지 않았다.

### 사내망 PC — Gitea 원격 전환 (2026-11-12 완료)

번들 시점(`079f999`)에 멈춰 있던 저장소를 Gitea `origin`으로 전환했다. 사내망에서 `222.112.172.253:9080`으로 clone·fetch·push가 되는 것을 실측했다(커밋 `f0948af`). 연결이 안 될 때의 점검 절차는 [docs/gitea-check.md](docs/gitea-check.md)에 있다.

### HUD 게이지 — 래퍼 스크립트

게이지가 `[##------]`로 나오던 것을 `[██░░░░░░]`로 되돌렸다. 기준과 적용 방식은 [CLAUDE.md의 "환경 설정 공통화"](CLAUDE.md)와 [env/AGENTS.md](env/AGENTS.md), 렌더링 사실은 [wiki/hud.md](wiki/hud.md).

- 스크립트: `env/hud/omc-hud-gauge.mjs` → `~/.claude/hud/`(세션 시작·pull 직후 자동 복사). 프로젝트 `.claude/settings.json`의 `statusLine.command`가 이걸 가리킨다
- 원인은 `dist/hud/sanitize.js`의 `replaceUnicodeBlocks()`가 `█`→`#`, `░`→`-`로 무조건 치환하는 것. 공식 설정으로 끌 수 없어 출력을 후처리한다
- 2026-11-17 사내망 PC(Zed 터미널)에서 블록 문자 폭이 밀리지 않음을 눈으로 확인. 밀리는 PC가 생기면 `statusLine.command`를 `omc-hud.mjs`로 되돌린다(`█`·`░`는 동아시아 환경에서 폭이 모호한 문자, OMC issue #346)
- 2026-11-17 변경: 2줄 구조 고정(1줄 ctx·모델·git·계정, 2줄 5H·WK·Fable), ctx 색 하늘색·주황·자홍, 버전 라벨 제거, 게이지 모두 10칸, OMC가 ctx를 잘라도 사용률로 다시 그림

## 다른 PC에서 이어가기

절차는 [CLAUDE.md의 "다른 PC로 옮기기"](CLAUDE.md#다른-pc로-옮기기)에 있다. 요약하면:

1. 받는 PC: `git clone http://222.112.172.253:9080/msjin-claude-lab/cp_workspace.git D:/dev/workspace` — 공개 저장소라 clone·pull은 로그인 없이 된다
2. push는 **Gitea에만** 한다. 처음 push할 때 Gitea 계정 이름 + 액세스 토큰으로 로그인한다. GitHub는 Gitea 푸시 미러가 맞춘다
3. 작업 중에는 정시 구간마다 sync-check hook이 Gitea와 비교해 pull/push 여부를 묻는다. 마칠 때는 이 문서를 갱신하고 push한다
4. Claude Code 설정은 저장소에 있다. 새 PC에서 한 번 할 일: Claude Code 로그인, OMC 설치(플러그인 — [CLAUDE.md "답변 형식"](CLAUDE.md)의 설치 명령), JDK 21·Maven 3.9, Gitea 액세스 토큰(`wincred`)

Gitea에 접근할 수 없으면 CLAUDE.md의 "예비 수단 — git bundle"을 쓴다.

새 세션은 이렇게 시작하면 된다:

```
D:\dev\workspace 에서 작업을 이어서 한다. HANDOFF.md 를 읽고 시작해라.      (개인 PC)
D:\cp_workspace 에서 작업을 이어서 한다. HANDOFF.md 를 읽고 시작해라.      (사내망 PC)
projects/apps/CLAUDE.md 를 읽고 앱 작업을 이어서 한다.                        (앱 작업만 할 때, 루트에서 연 뒤)
```
