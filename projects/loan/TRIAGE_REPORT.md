# TRIAGE_REPORT — projects/loan

진단일: 2026-11-17 (사내망 PC) · 도구: `/triage` (루트에 `triage.sh` 없음 → 직접 grep 스캔)

## 판단: **Java 21 직행 후보**

이미 Java 8이고, 소스가 작고(메인 7개 파일), 마이그레이션 위험 요소가 0건이다. 단계(8 → 11 → 21)를 밟을 이유가 없다. 최종 확인은 21로 올린 뒤 `mvn clean test` green으로 한다.

## 빌드 도구·버전

| 항목 | 값 | 근거 |
|---|---|---|
| 빌드 도구 | Maven | `pom.xml` |
| 현재 컴파일 타깃 | **Java 8** | `maven.compiler.source` / `target` = `8` (pom.xml 18–19행, 주석: "의도적으로 낮은 타깃") |
| `release` 설정 | 없음 | — |
| 실행 JDK | OpenJDK 21.0.11 | `java -version` |
| Maven | 3.9.11 | `mvn -v` |
| 플러그인 | compiler 3.13.0, surefire 3.2.5 | 둘 다 Java 21 지원 버전 |
| 의존성 | JUnit Jupiter 5.7.0 (test) | Java 21에서 동작. 5.10+로 올리는 것은 선택 |

## 위험 요소 스캔 (src/, target 제외)

| 항목 | 결과 |
|---|---|
| `sun.*` / `com.sun.*` 내부 API | 0건 |
| 제거된 Java EE 모듈 (`javax.xml.bind`, `javax.xml.ws`, `javax.annotation`, `javax.activation`, `org.omg.*`) | 0건 |
| applet (`java.applet`, `extends Applet/JApplet`) | 0건 |
| Nashorn (`jdk.nashorn`, `getEngineByName`) | 0건 |
| SecurityManager | 0건 |
| 예약어 식별자 (`assert`, `enum`) | 0건 |

## 현재 빌드 상태 (JDK 21 + 타깃 8)

`mvn clean test` → **BUILD SUCCESS, 37/37 통과**. 경고 4종이 나온다(컴파일 단계마다 2번씩):

- `source value 8 is obsolete and will be removed in a future release`
- `target value 8 is obsolete and will be removed in a future release`
- `bootstrap class path not set in conjunction with -source 8`
- `To suppress warnings about obsolete options, use -Xlint:-options.`

→ 지금은 동작하지만 이후 JDK에서 `-source 8`이 제거되면 빌드가 깨진다. 버전을 올릴 이유가 된다.

## 올릴 때 할 일 (to-java21 입력)

1. `maven.compiler.source/target` → `maven.compiler.release` = `21` 하나로 (bootstrap 경고도 사라진다)
2. `mvn clean test` 37/37 green 확인
3. (선택) 21 문법으로 정리할 곳 — 동작 변경 없이: `switch`/`instanceof` 패턴은 해당 없음. `Loan`·`Book`·`Member`는 가변 필드가 있어 `record` 전환 대상이 아니다(`Book.available`, `Loan.returnedOn`). 순수 값 객체가 생기면 그때 검토
4. (선택) JUnit 5.7.0 → 5.10.x

## 참고

- PRACTICE.md는 "인덱스 for 루프, `new ArrayList<Loan>()`" 같은 옛 스타일을 재료로 적었지만, 과제 3 정리 후 메인 소스에는 남아 있지 않다(grep 0건)
- 대시보드(`assistant/server/cli.js`)는 개인 PC 경로(`D:\dev\workspace\assistant`)에만 있어 이 PC에서는 등록하지 않았다
