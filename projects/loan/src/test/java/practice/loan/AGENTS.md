# practice.loan (test)

**Parent context:** `../../../../../AGENTS.md`
**Generated:** 2026-11-15 · **Updated:** 2026-11-15

## Purpose
JUnit 5 테스트. 각 클래스 javadoc의 규정을 테스트로 옮겨 둔 것이다.

## Key Files
| File | Description |
|------|-------------|
| `FeeCalculatorTest.java` | 연체료 6개 — 당일·조기 반납, 유예 경계, 유예 뺀 부과, 상한, null 거부 |
| `LoanServiceTest.java` | 대출·반납 10개 — 반납일, 대출 중·정지·한도 거부, 반납, 활성 목록, null 거부, 같은 ISBN 다른 객체 반납, `findActiveLoans(null)` |
| `RenewalPolicyTest.java` | 연장 10개 — 최대 횟수, 연체, 정지, 예약, 새 반납일, null 거부 |

## For AI Agents

### Working In This Directory
- 기대값은 javadoc 규정에서 가져온다. 구현이 내는 값을 그대로 옮긴 테스트는 검사가 아니다
- 버그를 고칠 때는 그 버그를 드러내는 실패 테스트부터 쓴다
- 알려진 빈틈: 대부분 예외 **종류**만 보고 메시지·우선순위는 보지 않는다. `AdminGate` 테스트는 없다. 연체 상태 반납을 `LoanService`로 확인하는 테스트도 없다

### Testing Requirements
- `projects/loan`에서 `mvn -q clean test`. 한 클래스만: `mvn -q -o test -Dtest=LoanServiceTest`

## Dependencies

### External
- JUnit Jupiter 5.7.0 (`assertEquals`, `assertThrows`, `@DisplayName`)

## Manual Notes
