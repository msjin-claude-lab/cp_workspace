# OMC 연습 코스

도서 대출 모듈이다. **코드의 결함은 전부 의도적으로 심어 둔 것**이다. 고쳐진 상태로 두지 말고, 스킬을 직접 돌려서 찾는 데 쓴다.

```bash
cd projects/loan
mvn -q test
```

지금 상태: **14개 모두 통과** — 1번 과제를 2026-11-13에 풀었다. 처음 상태는 13개 통과·1개 실패였다. 1번을 다시 연습하려면 `git checkout a3f27b4 -- projects/loan`으로 결함을 되살린다.

언제든 되돌릴 수 있다:

```bash
git checkout projects/loan
```

---

## 1. 실패하는 테스트 하나 — `/debug`

```
FeeCalculatorTest.chargesOnlyDaysBeyondGrace:41 expected: <1000> but was: <2500>
```

연체료 규정은 `FeeCalculator`의 javadoc에 적혀 있다. 규정과 구현이 어긋나 있다.

| 해볼 것 | 기대 |
|---|---|
| `/debug 연체료 테스트가 실패한다` | 원인 한 줄을 짚어낸다 |
| `/trace` | 가설을 여러 개 세우고 증거로 좁혀 간다 |
| `/why FeeCalculator의 유예 기간 처리` | 코드가 왜 이 모양인지 증거 기반으로 답한다 |

고친 뒤 `/verify`로 확인하면 4번 과제와 이어진다.

## 2. 구현되지 않은 기능 — `/tdd`

`RenewalPolicy`는 javadoc에 규정만 있고 본문은 `UnsupportedOperationException`이다. 테스트도 없다.

| 해볼 것 | 기대 |
|---|---|
| `/tdd RenewalPolicy를 구현한다` | 테스트 먼저 쓰고 red → green 순서로 진행한다 |
| `/sdd` | 인터뷰 → 수용 기준 → 계획 → 테스트 우선 구현 |

규정에 경계 조건이 일부러 들어 있다 (연장 횟수 상한, 연체 중 연장 금지, 새 반납일의 기준 날짜). 테스트가 이것들을 덮는지 본다.

## 3. 지저분한 코드 — `/omc-review`

`LoanService`는 **동작은 한다.** 대신 중첩 분기, 복사된 검증 코드, 코드를 그대로 읽어 주는 주석, 매직 넘버가 들어 있다.

| 해볼 것 | 기대 |
|---|---|
| `/omc-review` | 심각도를 매긴 지적 목록 |
| `/simplify` | 동작을 바꾸지 않고 정리 — 끝나고 `mvn -q test`가 여전히 전부 통과여야 한다 |
| `/ai-slop-cleaner` | 설명형 주석 같은 AI 슬롭 패턴 제거 |

`/simplify` 뒤에 테스트가 더 깨졌다면 그것도 연습 재료다.

## 4. 보안 문제 — `/security-review`

`AdminGate` 한 파일에 여러 개가 들어 있다. 몇 개를 찾아내는지 본다.

| 해볼 것 | 기대 |
|---|---|
| `/security-review` | 하드코딩 비밀, 로그에 남는 개인정보, 문자열 결합 질의 등 |

## 5. 검증 습관 — `/verify`

| 해볼 것 | 기대 |
|---|---|
| `/verify` | "다 됐다"를 증거로 판정한다. 실패 1개가 남아 있으면 통과를 선언하면 안 된다 |
| `/create-verification-skill` | 이 프로젝트 전용 verify 스킬을 만든다 (`mvn -q test`를 직접 실행해 명령을 찾아낸다) |

## 6. 문서가 없는 코드 — `/how`, `/wiki`

이 프로젝트에는 설명 문서가 없다 (이 파일은 연습 안내지 설계 문서가 아니다).

| 해볼 것 | 기대 |
|---|---|
| `/how 대출과 반납은 어떻게 동작하나` | 코드를 인용한 설명 |
| `/deepinit` | 계층형 AGENTS.md 생성 |
| `/wiki` | 세션을 넘어 쌓이는 지식 베이스 |
| `/teach` | 설명 + 결정 배경 |

## 7. 변경 파급 — `/blast-radius`, `/architect`

`Book`·`Member`·`Loan`은 평범한 값 객체다. 바꾸면 여러 곳이 흔들린다.

| 해볼 것 | 기대 |
|---|---|
| `/blast-radius Loan에 상태 필드를 추가한다면` | diff 밖에서 깨질 곳을 찾아 실제로 검증한다 |
| `/architect` | 타입·모듈 경계를 먼저 정한다 |

## 8. 레거시 버전 올리기 — `/triage`, `/to-java21`

`pom.xml`의 컴파일 타깃이 **Java 8**이다. 코드도 그 시절 스타일(인덱스 for 루프, `new ArrayList<Loan>()`)이다. 실제 JDK는 21이다.

| 해볼 것 | 기대 |
|---|---|
| `/triage` | 버전·빌드도구·위험 요소 진단 보고서 |
| `/to-java21` | 단계적 승급. 각 단계마다 테스트가 green인지 확인 |

## 9. 여러 작업 한 번에 — `/team`, `/execute`

위 과제들 중 **서로 겹치지 않는** 것을 골라 동시에 돌려 본다. 예: 2번(`RenewalPolicy`) + 4번(`AdminGate`)은 파일이 달라 충돌하지 않는다.

| 해볼 것 | 기대 |
|---|---|
| `/team 2:executor "..."` | 에이전트 2개가 작업 목록을 나눠 가진다 |
| `/plan` → `/execute` → `/omc-review` → `/verify` | OMC 기본 워크플로 한 바퀴 |

> `/team`은 Claude Code 재시작 후에 동작한다 (agent teams 설정이 시작 시 읽힌다).
