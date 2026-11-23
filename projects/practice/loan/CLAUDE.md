# projects/practice/loan

OMC 연습용 도서 대출 모듈. Java 21 타깃(과제 8에서 8 → 21), Maven, JUnit 5.

```bash
cd projects/practice/loan
mvn -q test
```

## 이 프로젝트의 결함은 의도적이다

`FeeCalculator`의 계산 오류, `RenewalPolicy`의 미구현, `LoanService`의 지저분한 구조, `AdminGate`의 보안 문제는 **연습 재료로 일부러 심어 둔 것**이다.

지시받지 않은 채로 고치지 말 것. 어떤 과제에 어떤 스킬을 쓰는지는 [PRACTICE.md](PRACTICE.md)에 있다.

**과제 1(`FeeCalculator` 계산 오류)·2(`RenewalPolicy` 구현)는 2026-11-13, 과제 3(`LoanService` 정리)은 2026-11-15, 과제 4(`AdminGate` 보안)는 2026-11-16, 과제 5~9는 2026-11-17까지 끝냈다. 현재 테스트는 41개 모두 통과한다.** 나머지 결함은 테스트로 드러나지 않으므로 green이라고 해서 다 고쳐진 것이 아니다.

## 작업할 때

- 연습으로 바꾼 것은 `git checkout projects/practice/loan`으로 되돌린다
- 어떤 과제를 처리하든, 끝나고 `mvn -q test`로 **의도하지 않은 테스트가 깨지지 않았는지** 확인한다
- 컴파일 타깃은 과제 8(2026-11-17)에서 Java 8 → 11 → 21로 올렸다. 다시 연습하려면 `git checkout af2c8ad -- projects/loan/pom.xml`로 8 상태를 되살린다
- **이 폴더는 2026-11-24에 `projects/loan`에서 `projects/practice/loan`으로 옮겼다.** 그 전 커밋에는 옛 경로만 있어서, 위처럼 옛 커밋을 가리키는 `git checkout <커밋> -- projects/loan…` 명령은 파일을 **옛 자리(`projects/loan/`)에** 되살린다 — 되살린 파일을 이 폴더로 옮겨 쓴다(옮긴 뒤 이 방법을 직접 시험하지는 않았다)

워크스페이스 공통 규칙은 루트 [CLAUDE.md](../../../CLAUDE.md)에 있다.
