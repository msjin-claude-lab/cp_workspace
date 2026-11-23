# loan

**Parent context:** `../../AGENTS.md`
**Generated:** 2026-11-15 · **Updated:** 2026-11-15

## Purpose
OMC 스킬 연습용 도서 대출 모듈. 대출·반납·연체료·연장 규칙이 있다. **결함은 연습 재료로 일부러 심어 둔 것**이며, 과제 목록과 진행은 `PRACTICE.md`·루트 `HANDOFF.md`에 있다.

## Key Files
| File | Description |
|------|-------------|
| `CLAUDE.md` | 이 프로젝트의 규칙 — 결함을 지시 없이 고치지 말 것 |
| `PRACTICE.md` | 연습 과제 1~9와 각 과제에 쓰는 스킬 |
| `pom.xml` | Maven 설정. 컴파일 타깃 Java 21(`maven.compiler.release`), JUnit 5.7, compiler 3.16 / surefire 3.2.5 |

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `src/main/java/practice/loan/` | 운영 코드 (see `src/main/java/practice/loan/AGENTS.md`) |
| `src/test/java/practice/loan/` | JUnit 5 테스트 (see `src/test/java/practice/loan/AGENTS.md`) |
| `target/` | 빌드 산출물. 커밋하지 않는다. `surefire-reports/`에 지난 실행 결과가 남는다 |

## For AI Agents

### Working In This Directory
- 지시받은 과제의 결함만 고친다. 연습으로 바꾼 것은 `git checkout projects/practice/loan`으로 되돌린다
- 남은 연습 결함(과제 5~8)은 테스트로 드러나지 않는다 — 테스트 green이 "결함 없음"이 아니다

### Testing Requirements
- `mvn -q clean test`(이 폴더에서). 현재 41개 (FeeCalculator 6, LoanService 13, RenewalPolicy 10, AdminGate 12) 통과
- 종료 코드로 판정한다. `target/surefire-reports`의 결과 파일은 빌드가 중간에 멈춰도 지난 것이 남아 있다
- `-o`(오프라인)에서 `clean`은 clean 플러그인을 한 번 내려받은 뒤에만 된다

### Common Patterns
- 규정은 각 클래스 javadoc에 적고, 테스트의 기대값은 그 규정에서 가져온다(코드가 내는 값을 그대로 옮기지 않는다)
- 잘못된 인자는 `IllegalArgumentException("<이름>는 필수다")`, 규칙 위반은 `IllegalStateException`

## Dependencies

### External
- JDK 21로 빌드(타깃 21), Maven 3.9.x, JUnit Jupiter 5.7.0

## Manual Notes
