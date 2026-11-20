# vocab — 검증 기록

형식은 `/apps:new` "검증 기록". `/oh-my-claudecode:verify`를 부르기 전에 이 파일을 읽고 명령·기대값을 넘기고, 끝나면 "마지막 결과"에 적는다. 설치·설정 방법은 [SETUP.md](SETUP.md)와 세 층 SETUP.md([projects/](../../SETUP.md) → [apps/](../SETUP.md)).

## 명령

작업 위치: `projects/apps/vocab`. PATH에 `D:\dev\flutter\bin`(사내망 PC).

| 대상 | 명령 | 통과 판정 | 걸린 시간(사내망 PC) |
|---|---|---|---|
| 환경 | `flutter doctor` | Flutter ✓, Android toolchain ✓ | 98초 |
| 정적 분석 | `flutter analyze` | exit 0, "No issues found" | 75초 |
| 테스트 | `flutter test` | exit 0, "All tests passed" | 114초 |
| 안드로이드 빌드 | `flutter build apk --debug` | exit 0 + `build/app/outputs/flutter-apk/app-debug.apk` 새로 생김(먼저 `build/app/outputs` 지움) | 263초(이 프로젝트 첫 빌드, Gradle 캐시 있음) |
| 기기 실행 | `D:\dev\android-sdk\emulator\emulator.exe -avd vocab_api36 -gpu swiftshader_indirect` → `flutter run -d emulator-5554` | 앱이 뜸 + 아래 "기기에서 볼 것" | 부팅 266초, 에뮬레이터를 띄운 채 첫 `flutter run` 빌드 약 25분 |

기기에서 볼 것(adb `D:\dev\android-sdk\platform-tools\adb.exe`, Git Bash는 `MSYS_NO_PATHCONV=1`):
- 화면: `adb emu screenrecord screenshot <절대경로.png>`(`screencap`은 검은 화면일 때가 있음)
- TTS: 발음 버튼 뒤 logcat `GoogleTTSServiceImpl: TTS dispatch: en-us-x-…`, `AudioTrack: stop(…): called with N frames delivered`
- 저장 유지: 저장하는 동작 → `adb shell am force-stop dev.cp.vocab` → `adb shell am start -W -n dev.cp.vocab/.MainActivity` → 값이 그대로

4단계(2026-11-18~19)에는 저장소 밖 시험용 프로젝트 `D:\dev\tmp\vocab_probe`(패키지 `dev.cp.vocab_probe`, 시험 화면: SPEAK apple·ADD ROW·행 수 표시)로 같은 명령을 돌렸다. 아래 "마지막 결과"의 2026-11-19 이전 항목은 그 프로젝트 결과다.

## 기대값

- 테스트 36개(2026-11-20): 칸·단어 읽기 3개(`test/data/word_repository_test.dart`), 실제 단어 파일 검사 5개(`test/data/word_assets_test.dart` — 칸마다 정확히 50개, id 형식, 빈 필드 없음, 칸 사이 영단어 중복 없음, 예문에 단어 포함, 같은 칸 같은 뜻 없음), **실제 DB 2개**(`test/data/study_records_test.dart` — sqflite_common_ffi, 새 설치 2판 표·시험 기록·오답 노트, 1판 → 2판 이행 시 기록 유지), 첫 화면 6개(`test/widget_test.dart` — 첫 실행 학교급 선택·저장, 저장된 학교급으로 시작, ☰ 메뉴로 변경, 메뉴 빠른 두 번 누름, 저장 실패 알림, 칸 → 학습/시험 창), 카드 학습 9개(`test/features/study_screen_test.dart`), 시험 11개(`test/features/quiz_test.dart` — 20문제·서로 다른 단어·보기 4개 같은 칸, 매번 새로 섞기, 두 방향, 단어 적을 때, 맞힘·틀림 기록, 한 번만 답함, 영→뜻만 자동 발음, 결과·다시 하기 새로 섞기, 저장 실패, 50단어면 20문제, 4개 미만 안내). 기능을 넣으면 늘린다
- sqflite 실제 저장은 PC에서 sqflite_common_ffi로 시험한다(Windows에서 별도 설치 없이 동작함, 2026-11-20). 기기 저장 유지는 에뮬레이터에서 확인. DB 내용은 `adb exec-out run-as dev.cp.vocab cat databases/vocab.db > <파일>` 후 sqlite로 읽는다
- APK 약 158MB(debug, 시험용 프로젝트 기준)

## 함정

- **Kotlin 증분 캐시 실패**(2026-11-18 사내망 PC) — 프로젝트가 D:, pub 캐시가 C:(`%LOCALAPPDATA%\Pub\Cache`)일 때 `:flutter_tts:compileDebugKotlin`이 "Could not close incremental caches"로 실패. `android/gradle.properties`에 `kotlin.incremental=false`를 넣자 성공. 같은 날 C: 드라이브(임시 폴더)의 프로젝트는 이 설정 없이 `flutter_tts` 포함 빌드가 성공했다 — 드라이브가 다른 것이 원인이라는 **추정**과 맞지만, 같은 조건을 바꿔 가며 확인하지는 않았다. 다른 앱에도 해당 → [apps/SETUP.md](../SETUP.md)
- **`flutter_tts`가 Kotlin Gradle Plugin(KGP)을 적용한다는 경고** — "Future versions of Flutter will fail to build". 지금은 빌드됨. Flutter를 올릴 때 `flutter_tts` 새 버전 확인
- `flutter doctor`는 "문제없음"이 아니다 — Visual Studio ✗(Windows 데스크톱용, 무관), Network resources !(사내망 github.com 차단)
- 에뮬레이터 쪽 함정(재부팅은 "다시 시작"으로, 기본 그래픽이면 화면 멈춤 → `-gpu swiftshader_indirect`, 부팅 직후 System UI ANR 창, 에뮬레이터를 띄운 채 첫 빌드가 느림)은 모든 앱에 해당 → [apps/SETUP.md](../SETUP.md) "함정"

## 명령으로 못 잡는 것

- 앱이 에뮬레이터에서 뜨는지, 화면(실제 폰은 연결하지 않는다 — `projects/apps/CLAUDE.md` "PC 역할") — 위 "기기에서 볼 것"으로 adb로 확인
- TTS 영어 발음이 **귀에 들리는지** — 합성·오디오 출력은 logcat으로 보이지만 소리는 사람이 들어야 한다
- sqflite에 쓰고 앱을 껐다 켠 뒤 남아 있는지 — 위 "기기에서 볼 것"으로 확인

## 마지막 결과

- **2026-11-20 개인 PC — 4지선다 시험·학교급 선택**
  - `flutter analyze` exit 0(No issues), `flutter test` exit 0(36개 통과), `flutter build apk --debug` exit 0 + `app-debug.apk` 22:07 새로 생김(171,285,100바이트)
  - code-reviewer(별도 에이전트) APPROVE — MEDIUM 2건(메뉴 연타로 첫 화면이 닫힘, 실제 DB·이행 시험 없음)과 LOW 1건(저장 실패 문구) 반영
  - 에뮬레이터: 덮어 설치 → **첫 실행 학교급 선택 화면** → 중등 → 앱 강제 종료·재실행 → **"영단어 · 중등" 3칸으로 바로 시작** → 칸 → "카드 학습 / 4지선다 시험" 창 → 시험 **1/10, 영→뜻 문제와 보기 4개**(캡처, 이때는 10문항 — 같은 날 20문항으로 바꾼 뒤 다시 설치해 **1/20** 확인)
  - **DB 이행: 통과** — 기기 DB `user_version` 2, 기존 `study_log` 기록 유지(71건), 사용자가 푼 시험 4문제가 `quiz_log`에 기록(맞힘 1 · 틀림 3)
  - 소리: 빌드·시험을 돌리는 동안 에뮬레이터 소리가 깨지고 끝나면 정상(사용자 보고). 안드로이드 쪽 끊김 기록 0건 → 앱 원인 아님으로 추정
- **2026-11-20 개인 PC — 첫 환경 설치 후, 카드 학습 기기 확인** (i9-10900K · RTX 3080 · Windows 10 Home)
  - `flutter analyze` exit 0(No issues), `flutter test` exit 0(18개 통과), `flutter build apk --debug` exit 0 + `app-debug.apk` 21:35 새로 생김(160,914,167바이트) — 391초(build-tools 36.0.0 자동 설치 포함)
  - 에뮬레이터: **기본 그래픽(GPU host, RTX 3080)으로 정상** — `-gpu swiftshader_indirect` 불필요. 부팅 71초
  - **칸 선택 화면 → 카드 학습: 통과** — 9칸 표시(캡처), 초등·하 → 1/50 apple, 뒤집기 → 안다/모른다 → 다음 카드
  - **자동 발음: 통과** — 카드가 뜰 때 logcat `TTS dispatch: en-us-x-iog-lstm-embedded`, `Utterance ID has started` → `has completed`
  - **TTS 귀로 듣기: 통과**(사용자 확인). 에뮬레이터 미디어 볼륨 기본값 5/15라 작게 들림 → 15로 올리자 충분. 가끔 소리가 깨짐 — 안드로이드 쪽 underrun 0건이라 에뮬레이터→Windows 오디오 구간으로 추정(확인 안 함)
  - **기록 저장·유지: 통과** — `study_log` 8건 → `am force-stop` → `am start` → 8건 그대로. 이후 사용자가 눌러 48건(안다 24 · 모른다 24)
  - **오답 노트: 통과** — 모른다 단어 23개 담김, 같은 단어를 두 번 모른다 하면 `hh-003` 틀린 횟수 2
- **2026-11-19 사내망 PC — 5단계, 앱 프로젝트 `projects/apps/vocab`** — `/oh-my-claudecode:verify`(verifier 판정 APPROVE, analyze·test를 다시 돌려 확인)
  - `flutter analyze` exit 0(No issues), `flutter test` exit 0(1개 통과), `flutter build apk --debug` exit 0 + `app-debug.apk` 14:05 새로 생김(158,301,662바이트)
  - 앱 설정 확인: manifest `TTS_SERVICE`, `kotlin.incremental=false`, pubspec `flutter_tts` ^4.2.5·`sqflite` ^2.4.6·`path` ^1.9.1
  - 기기 실행은 이 프로젝트로는 아직(화면 코드 없음) — 4단계 시험용 프로젝트에서 확인함
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
  - **iOS: 확인 못 함** — 보류(사용자 결정, 무료 위주). 대안은 [docs/options.md](docs/options.md) "먼저 알아 둘 것"(Mac + 무료 Apple ID, 또는 유료 Apple 계정 + Codemagic)
  - **4단계 판정: 통과 아님** — 안드로이드 기기 실행이 확인되기 전까지. iOS는 잠정 보류(같은 날 사용자 결정 — 추후 지시까지 안드로이드만으로 5단계까지), 기기 실행이 확인되면 "안드로이드 통과, iOS 잠정 보류"로 닫는다
