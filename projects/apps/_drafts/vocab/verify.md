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
| 기기 실행 | `emulator -avd vocab_api36 -gpu swiftshader_indirect` → `flutter run -d emulator-5554` | 앱이 뜸 + 아래 "기기에서 볼 것" | 부팅 266초, 에뮬레이터를 띄운 채 첫 `flutter run` 빌드 약 25분 |

시험 화면(`lib/main.dart`, 2026-11-19): 버튼 SPEAK apple(`speakWord` → 완료 핸들러 결과 표시), ADD ROW(`wrong_notes`에 1행), 시작할 때 DB에서 읽은 행 수 표시. `test/widget_test.dart`는 이 화면 기준(버튼 2개).

기기에서 볼 것(adb, Git Bash는 `MSYS_NO_PATHCONV=1`):
- 화면: `adb emu screenrecord screenshot <절대경로.png>`(`screencap`은 검은 화면일 때가 있음)
- TTS: SPEAK 뒤 화면 `TTS: completed`, logcat `GoogleTTSServiceImpl: TTS dispatch: en-us-x-…`, `AudioTrack: stop(…): called with N frames delivered`
- 저장 유지: ADD ROW → `adb shell am force-stop dev.cp.vocab_probe` → `am start -W -n dev.cp.vocab_probe/.MainActivity` → 행 수가 그대로

## 기대값

- 테스트 1개(템플릿 카운터 테스트). 앱 코드를 넣으면 늘린다
- APK 약 158MB(debug)

## 함정

- **Kotlin 증분 캐시 실패**(2026-11-18 사내망 PC) — 프로젝트가 D:, pub 캐시가 C:(`%LOCALAPPDATA%\Pub\Cache`)일 때 `:flutter_tts:compileDebugKotlin`이 "Could not close incremental caches"로 실패. `android/gradle.properties`에 `kotlin.incremental=false`를 넣자 성공. 같은 날 C: 드라이브(임시 폴더)의 프로젝트는 이 설정 없이 `flutter_tts` 포함 빌드가 성공했다 — 드라이브가 다른 것이 원인이라는 **추정**과 맞지만, 같은 조건을 바꿔 가며 확인하지는 않았다. 다른 앱에도 해당 → [apps/SETUP.md](../../SETUP.md)
- **`flutter_tts`가 Kotlin Gradle Plugin(KGP)을 적용한다는 경고** — "Future versions of Flutter will fail to build". 지금은 빌드됨. Flutter를 올릴 때 `flutter_tts` 새 버전 확인
- `flutter doctor`는 "문제없음"이 아니다 — Visual Studio ✗(Windows 데스크톱용, 무관), Network resources !(사내망 github.com 차단)
- 에뮬레이터 쪽 함정(재부팅은 "다시 시작"으로, 기본 그래픽이면 화면 멈춤 → `-gpu swiftshader_indirect`, 부팅 직후 System UI ANR 창, 에뮬레이터를 띄운 채 첫 빌드가 느림)은 모든 앱에 해당 → [apps/SETUP.md](../../SETUP.md) "함정"

## 명령으로 못 잡는 것

- 앱이 에뮬레이터에서 뜨는지, 화면(실제 폰은 연결하지 않는다 — `projects/apps/CLAUDE.md` "PC 역할") — 위 "기기에서 볼 것"으로 adb로 확인
- TTS 영어 발음이 **귀에 들리는지** — 합성·오디오 출력은 logcat으로 보이지만 소리는 사람이 들어야 한다
- sqflite에 쓰고 앱을 껐다 켠 뒤 남아 있는지 — 위 "기기에서 볼 것"으로 확인

## 마지막 결과

- **2026-11-19 사내망 PC — 4단계 통과(안드로이드), iOS 잠정 보류** — 재부팅으로 WHPX 켬(`HypervisorPresent=True`, `emulator -accel-check` "WHPX(10.0.26200) is installed and usable"). `/oh-my-claudecode:verify`(verifier 에이전트 판정 APPROVE)
  - `flutter analyze`·`flutter test` exit 0(시험 화면으로 바꾼 뒤)
  - **앱 실행·화면: 통과** — 에뮬레이터에서 시험 화면이 그려짐(캡처). 기본 그래픽 모드에서는 화면이 멈춰 `-gpu swiftshader_indirect`로 다시 띄움
  - **저장 유지: 통과** — ADD ROW 뒤 `rows: 1` → `am force-stop`(프로세스 없어짐 확인) → `am start -W`(Status ok) → `rows: 1`(DB에서 다시 읽은 값). 1행·1회만 확인
  - **TTS: 합성·오디오 출력 통과, 귀로 듣기는 확인 못 함** — 화면 `TTS: completed`(완료 핸들러), logcat `TTS dispatch: en-us-x-iog-lstm-embedded`, `AudioTrack: stop(19): called with 14040 frames delivered`(이 로그는 화면 캡처 때와 다른, 뒤의 SPEAK 실행분). 엔진 `com.google.android.tts`, 영어 음성 내장. 사무실이라 소리를 들을 수 없음 → **개인 PC에서 귀로 확인**(사용자 결정: 나중에 해도 됨, 안 들리면 그때 설정·코드 수정 — 도구 선택에는 영향 없음)
  - debug 빌드만 확인. release 빌드는 5단계 이후
  - **4단계 판정: 통과** — 안드로이드 기기 실행까지 확인. iOS는 잠정 보류(2026-11-18 사용자 결정), 앱의 남은 일로
- **2026-11-18 사내망 PC** — `/oh-my-claudecode:verify`(verifier 에이전트 판정)
  - **안드로이드 명령: 통과** — doctor(Flutter·Android toolchain ✓), analyze exit 0, test exit 0(verifier가 다시 돌려 둘 다 exit 0), build apk 1차 exit 1(위 Kotlin 함정) → `kotlin.incremental=false` 뒤 exit 0, `app-debug.apk` 18:17 생성, sha1 일치
  - **안드로이드 기기 실행·화면·TTS 소리: 확인 못 함** — 이 PC는 Windows 하이퍼바이저(WHPX)가 꺼져 있어 에뮬레이터를 띄울 수 없다
  - **iOS: 확인 못 함** — 보류(사용자 결정, 무료 위주). 대안은 [options.md](options.md) "먼저 알아 둘 것"(Mac + 무료 Apple ID, 또는 유료 Apple 계정 + Codemagic)
  - **4단계 판정: 통과 아님** — 안드로이드 기기 실행이 확인되기 전까지. iOS는 잠정 보류(같은 날 사용자 결정 — 추후 지시까지 안드로이드만으로 5단계까지), 기기 실행이 확인되면 "안드로이드 통과, iOS 잠정 보류"로 닫는다
