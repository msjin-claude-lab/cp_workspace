# practice.loan (main)

**Parent context:** `../../../../../AGENTS.md`
**Generated:** 2026-11-15 · **Updated:** 2026-11-15

## Purpose
도서 대출 모듈의 운영 코드. 모든 상태는 메모리에만 있고 저장하지 않는다.

## Key Files
| File | Description |
|------|-------------|
| `LoanService.java` | 대출·반납 처리. 대출 기록을 메모리 목록 하나에 둔다. 대출 시 정지 → 대출 중 → 5권 한도 순서로 검사하고 반납일은 +14일. 반납 시 진행 중인 대출을 회원 ID·ISBN으로 찾아 닫고 연체료를 돌려준다 |
| `FeeCalculator.java` | 연체료: 유예 3일, 넘긴 일수 × 500원, 최대 10,000원 |
| `RenewalPolicy.java` | 연장 가능 여부와 새 반납일(기존 반납일 +14일, 최대 2회). **아직 어디서도 호출하지 않는다** |
| `AdminGate.java` | 관리자 인증. 과제 4에서 보안 결함을 고쳤다(2026-11-16) — 토큰은 생성자·환경변수 `LOAN_ADMIN_TOKEN`, 로그·감사 기록엔 회원 id만, 검색은 자리표시자 쿼리 |
| `Loan.java` | 대출 기록. `returnedOn`이 있으면 반납된 것. `dueDate`·`renewalCount`는 바꿀 수 있다 |
| `Book.java` | ISBN·제목(고정), `available`(바뀜) |
| `Member.java` | ID·이름·이메일(고정), `suspended`(바뀜) |

## For AI Agents

### Working In This Directory
- 회원은 ID 문자열, 책은 ISBN 문자열로 구분한다(객체 동일성이 아님)
- 하지 않는 것: 저장, 연장 연결, 연체료 청구, 날짜 순서 확인, 동시성 보호. 바꾸려면 과제·지시가 있어야 한다
- Java 8 문법 범위로 쓴다(타깃 8). `var`, `List.of` 등은 컴파일되지 않는다

### Testing Requirements
- 테스트는 `../../../../test/java/practice/loan/`. 동작을 바꾸면 그 규정을 담은 테스트를 먼저 쓴다

## Dependencies

### External
- JDK 표준 라이브러리만(`java.time`, `java.util`, `java.util.logging`)

## Manual Notes
