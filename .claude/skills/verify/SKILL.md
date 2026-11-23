---
name: verify
description: cp_workspace 전용 검증 절차 — projects/practice/loan의 빌드·테스트와 hook 스크립트 문법을 실제 명령으로 확인하고, "통과"를 종료 코드와 새로 만들어진 결과 파일로만 판정한다. 작업을 끝냈다고 말하기 전, 커밋 전에 쓴다.
---

# verify (cp_workspace)

검증만 한다. 고치지 않는다 — 실패하면 원인 분석은 `/oh-my-claudecode:debug`, 수정은 `/oh-my-claudecode:execute`로 넘긴다.

## 명령 (2026-11-15 개인 PC에서 모두 실행해 확인)

| # | 대상 | 명령 (작업 위치) | 통과 판정 | 걸린 시간 |
|---|---|---|---|---|
| 1 | loan 빌드+테스트 | `mvn -q clean test` (`projects/practice/loan`) | **종료 코드 0** + 출력 없음 + `target/surefire-reports/*.txt`가 방금 시각에 생성 + 모두 `Failures: 0, Errors: 0` | 약 4초 |
| 2 | loan 컴파일만 | `mvn -q -o compile` (`projects/practice/loan`) | 종료 코드 0 | 약 2초 |
| 3 | hook·도구 스크립트 문법 | `node --check <파일>` — `.claude/hooks/*.mjs`, `env/sync.mjs`, `env/hud/*.mjs` | 각각 종료 코드 0 | 1초 미만 |

현재 기대값: 테스트 **41개** (FeeCalculatorTest 6, LoanServiceTest 13, RenewalPolicyTest 10, AdminGateTest 12). 과제를 하며 늘어나면 이 숫자를 갱신한다.

## 함정 (실제로 겪은 것)

- **오래된 결과 파일**: 빌드가 테스트 전에 멈춰도 `target/surefire-reports`에는 지난 실행 결과가 남아 "통과"로 보인다. 결과 파일만 보고 판정하지 말고 **종료 코드와 파일 생성 시각**을 같이 본다. 그래서 1번은 `clean`을 붙인다.
- **오프라인 `-o`와 `clean`**: `maven-clean-plugin`을 한 번도 내려받지 않은 PC에서는 `mvn -q -o clean test`가 시작하자마자 실패한다(`Cannot access central ... in offline mode`). 처음 한 번은 `-o` 없이 실행한다.
- **`mvn -q`는 성공하면 아무것도 출력하지 않는다.** 출력이 없다는 것만으로는 판정하지 않고 종료 코드를 본다.
- 테스트가 실패하면 `Failures`(기대값 불일치)와 `Errors`(예외)를 구분해 보고한다.
- **검증과 커밋을 한 명령에 묶을 때는 `&&`만 쓴다.** `mvn ... ; git commit`처럼 `;`로 이으면 실패해도 커밋된다. 2026-11-17에 `test exit=1`인 채 커밋·push한 적이 있다(이후 재실행은 green, 원인 미확인).
- 사내망 PC는 경로가 `D:\cp_workspace`, JDK 21.0.11 / Maven 3.9.11이다. 명령은 같다.

## 명령으로 확인할 수 없는 것 (사람이 본다)

- HUD 상태바: Claude Code 시작 후 2줄 OMC HUD, 게이지가 `[██░░░░░░]` 모양인지
- hook 동작: 세션 시작 때 `[cp_workspace 세션 시작 점검]` 한 줄이 뜨는지, 대답이 끝날 때 정시 구간 점검이 한 번만 도는지
- Gitea push/pull: 로그인이 필요하다. 저장된 로그인이 만료되면 사람이 `! git push`로 다시 로그인한다

## 무엇을 잡고 무엇을 못 잡나

| 검사 | 잡는 것 | 못 잡는 것 |
|---|---|---|
| 1. `mvn clean test` | 컴파일 오류, 테스트가 있는 규정 위반(연체료·연장·대출/반납) | 테스트 없는 동작: 오류 **메시지**·우선순위, 같은 ISBN 중복 대출 선택, `AdminGate` 전부(테스트 없음, 보안 문제는 테스트로 안 드러남) |
| 2. `mvn -o compile` | 컴파일 오류만 | 동작 전부 |
| 3. `node --check` | hook 스크립트 문법 오류 | hook이 실제로 맞게 동작하는지(git 비교 결과, 메시지) |

테스트가 다 통과해도 `projects/practice/loan`의 남은 연습 결함(PRACTICE.md 4번 이후)은 그대로다 — green이 "결함 없음"을 뜻하지 않는다.

## 보고 형식

확인한 것 / 실행한 명령과 종료 코드 / 통과한 것 / 실패하거나 확인 못 한 것. 확인하지 않은 것을 확인했다고 쓰지 않는다.
