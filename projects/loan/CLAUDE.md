# projects/loan

OMC 연습용 도서 대출 모듈. Java 8 타깃, Maven, JUnit 5.

```bash
cd projects/loan
mvn -q test
```

## 이 프로젝트의 결함은 의도적이다

`FeeCalculator`의 계산 오류, `RenewalPolicy`의 미구현, `LoanService`의 지저분한 구조, `AdminGate`의 보안 문제는 **연습 재료로 일부러 심어 둔 것**이다.

지시받지 않은 채로 고치지 말 것. 어떤 과제에 어떤 스킬을 쓰는지는 [PRACTICE.md](PRACTICE.md)에 있다.

**과제 1(`FeeCalculator` 계산 오류)은 2026-11-13에 고쳤다. 현재 테스트는 14개 모두 통과한다.** 나머지 결함(`RenewalPolicy`, `LoanService`, `AdminGate`)은 테스트로 드러나지 않으므로 green이라고 해서 다 고쳐진 것이 아니다.

## 작업할 때

- 연습으로 바꾼 것은 `git checkout projects/loan`으로 되돌린다
- 어떤 과제를 처리하든, 끝나고 `mvn -q test`로 **의도하지 않은 테스트가 깨지지 않았는지** 확인한다
- 컴파일 타깃이 Java 8인 것도 의도적이다 (`/triage`, `/to-java21` 재료). 임의로 올리지 말 것

워크스페이스 공통 규칙은 루트 [CLAUDE.md](../../CLAUDE.md)에 있다.
