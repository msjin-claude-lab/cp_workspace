# vocab — 4단계 검증 기록

형식은 `/apps:new` "검증 기록"(앱 VERIFY.md와 같음). 5단계에서 앱 폴더 `VERIFY.md`로 옮긴다. 설치·설정 방법은 [setup.md](setup.md)와 세 층 SETUP.md([projects/](../../../SETUP.md) → [apps/](../../SETUP.md)).

## 명령

시험용 프로젝트(저장소 밖): `D:\dev\tmp\vocab_probe` — `flutter create --platforms=android,ios --org dev.cp vocab_probe` + `flutter pub add flutter_tts sqflite path` + AndroidManifest `TTS_SERVICE` queries + `lib/probe.dart`(두 패키지 사용) + `android/gradle.properties`에 `kotlin.incremental=false`. PATH에 `D:\dev\flutter\bin`.

| 대상 | 명령(작업 위치: 시험용 프로젝트) | 통과 판정 | 걸린 시간(사내망 PC) |
|---|---|---|---|
| 환경 | `flutter doctor` | Flutter ✓, Android toolchain ✓ | 98초 |
| 정적 분석 | `flutter analyze` | exit 0, "No issues found" | 30초 |
| 테스트 | `flutter test` | exit 0, "All tests passed" | 47초 |
| 안드로이드 빌드 | `flutter build apk --debug` | exit 0 + `build/app/outputs/flutter-apk/app-debug.apk` 새로 생김(먼저 `build/app/outputs` 지움) | 128초(Gradle 캐시 있을 때), 첫 빌드는 약 29.5분 |
| 기기 실행 | `flutter emulators --launch vocab_api36` → `flutter run` | 앱이 뜸 | — |

## 기대값

- 테스트 1개(템플릿 카운터 테스트). 앱 코드를 넣으면 늘린다
- APK 약 158MB(debug)

## 함정

- **Kotlin 증분 캐시 실패**(2026-11-18 사내망 PC) — 프로젝트가 D:, pub 캐시가 C:(`%LOCALAPPDATA%\Pub\Cache`)일 때 `:flutter_tts:compileDebugKotlin`이 "Could not close incremental caches"로 실패. `android/gradle.properties`에 `kotlin.incremental=false`를 넣자 성공. 같은 날 C: 드라이브(임시 폴더)의 프로젝트는 이 설정 없이 `flutter_tts` 포함 빌드가 성공했다 — 드라이브가 다른 것이 원인이라는 **추정**과 맞지만, 같은 조건을 바꿔 가며 확인하지는 않았다. 다른 앱에도 해당 → [apps/SETUP.md](../../SETUP.md)
- **`flutter_tts`가 Kotlin Gradle Plugin(KGP)을 적용한다는 경고** — "Future versions of Flutter will fail to build". 지금은 빌드됨. Flutter를 올릴 때 `flutter_tts` 새 버전 확인
- `flutter doctor`는 "문제없음"이 아니다 — Visual Studio ✗(Windows 데스크톱용, 무관), Network resources !(사내망 github.com 차단)

## 명령으로 못 잡는 것

- 앱이 에뮬레이터에서 뜨는지, 화면(실제 폰은 연결하지 않는다 — `projects/apps/CLAUDE.md` "PC 역할")
- TTS 영어 발음이 실제로 나오는지(기기 TTS 엔진 필요)
- sqflite에 쓰고 앱을 껐다 켠 뒤 남아 있는지

## 마지막 결과

- **2026-11-18 사내망 PC** — `/oh-my-claudecode:verify`(verifier 에이전트 판정)
  - **안드로이드 명령: 통과** — doctor(Flutter·Android toolchain ✓), analyze exit 0, test exit 0(verifier가 다시 돌려 둘 다 exit 0), build apk 1차 exit 1(위 Kotlin 함정) → `kotlin.incremental=false` 뒤 exit 0, `app-debug.apk` 18:17 생성, sha1 일치
  - **안드로이드 기기 실행·화면·TTS 소리: 확인 못 함** — 이 PC는 Windows 하이퍼바이저(WHPX)가 꺼져 있어 에뮬레이터를 띄울 수 없다
  - **iOS: 확인 못 함** — 보류(사용자 결정, 무료 위주). 대안은 [options.md](options.md) "먼저 알아 둘 것"(Mac + 무료 Apple ID, 또는 유료 Apple 계정 + Codemagic)
  - **4단계 판정: 통과 아님** — 안드로이드 기기 실행이 확인되기 전까지. iOS는 잠정 보류(같은 날 사용자 결정 — 추후 지시까지 안드로이드만으로 5단계까지), 기기 실행이 확인되면 "안드로이드 통과, iOS 잠정 보류"로 닫는다
