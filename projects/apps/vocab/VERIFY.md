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

- **지금(2026-11-24 중등 700개 뒤)**: `flutter test` 169개 통과. 단어 파일 검사는 초등 800(267 · 267 · 266) · 중등 700(234 · 233 · 233) · 고등 칸당 50개, 유사어 쌍 71쌍(같은 칸 안). 아래 개수는 그때그때의 기록이다

- 테스트 46개(2026-11-20 화면 구조·오답 노트 뒤): 아래 36개를 바꾸고 늘림 — 첫 화면 7개(`test/widget_test.dart` — 학교급 → 난이도 세로 선택·저장·칸 홈, 저장된 칸으로 시작·오답 수, ☰ 2단계 메뉴, 메뉴 빠른 두 번 누름, 저장 실패, 칸 홈 → 학습·시험·오답 노트·⌂ 홈·← 뒤로·칸 바꾸기, 모른다 뒤 오답 수 갱신), 오답 노트 5개(`test/features/wrong_notes_test.dart`), 시험에 오답 시험 2개, 카드 학습에 다시 보기 1개, 실제 DB에 오답 노트 읽기·최근순·빼기 1개. 시험용 가짜는 `test/fakes.dart`
- (이전) 테스트 36개(2026-11-20): 칸·단어 읽기 3개(`test/data/word_repository_test.dart`), 실제 단어 파일 검사 5개(`test/data/word_assets_test.dart` — 칸마다 정확히 50개, id 형식, 빈 필드 없음, 칸 사이 영단어 중복 없음, 예문에 단어 포함, 같은 칸 같은 뜻 없음), **실제 DB 2개**(`test/data/study_records_test.dart` — sqflite_common_ffi, 새 설치 2판 표·시험 기록·오답 노트, 1판 → 2판 이행 시 기록 유지), 첫 화면 6개(`test/widget_test.dart` — 첫 실행 학교급 선택·저장, 저장된 학교급으로 시작, ☰ 메뉴로 변경, 메뉴 빠른 두 번 누름, 저장 실패 알림, 칸 → 학습/시험 창), 카드 학습 9개(`test/features/study_screen_test.dart`), 시험 11개(`test/features/quiz_test.dart` — 20문제·서로 다른 단어·보기 4개 같은 칸, 매번 새로 섞기, 두 방향, 단어 적을 때, 맞힘·틀림 기록, 한 번만 답함, 영→뜻만 자동 발음, 결과·다시 하기 새로 섞기, 저장 실패, 50단어면 20문제, 4개 미만 안내). 기능을 넣으면 늘린다
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

- **2026-11-24 저녁 개인 PC — 2차 중등 700개 + DB 9판**(커밋 `ea83d5f` 내용)
  - `flutter analyze` "No issues found", `flutter test` "All tests passed"(**169개**), `flutter build apk --debug` "Built …app-debug.apk"(19:58 새로 생김, 201,246,681바이트, Gradle 31초). 세 명령을 한 줄로 이어 돌려 종료 코드는 마지막(빌드) 0만 잡았다 — 앞의 둘은 출력 문구로 판정. `build/app/outputs`를 먼저 지우지는 않았다(파일 시각으로 확인). 사내망 PC에서 막혔던 debug 빌드(Android용 sqlite3 파일)는 개인 PC에서 그냥 된다
  - **에뮬레이터 시작 상태가 인계와 달랐다**: 기기 DB가 8판이 아니라 **7판**(앱 설치 시각 2026-11-23 21:58, `study_log` 147 · `quiz_log` 62 · `wrong_notes` 1 — 11-23 밤 8판 설치 전과 같은 숫자). 에뮬레이터가 이전 스냅샷으로 되돌아간 것으로 추정(원인 확인 안 함). 그래서 이번 설치는 7 → 8 → 9판을 한 번에 탔다
  - **DB 이행: 통과** — 설치 전 DB 사본(`D:\dev\tmp\vocab_db_backup\before_v9\vocab.db`)에서 남아야 할 줄 수를 파이썬으로 따로 계산 → `adb install -r` → 실행 뒤 다시 꺼낸 DB(`after_v9.db`)와 일치: `user_version` 7 → 9, `study_log` 147 → 59(남은 것은 모두 `high_hard`의 `hh-` 번호) · `quiz_log` 62 → 0 · `wrong_notes` 1 → 0, 옛 초등·중등 번호 줄 0건, 단어장 4개 그대로
  - **화면(adb로 누름, 접근성 노드 + 캡처 — 사람이 직접 써 본 것은 아니다)**: 새 등록 → 중등 → 난이도 버튼 `쉬움 / 234단어` · `중간 / 233단어` · `어려움 / 233단어` → 단어장 `mid1` 홈 `중등 [난이도 : 쉬움]` · `234단어` · `한 번에 카드 50장 · 시험 20문제` / 카드 학습 `1 / 50` `sausage`, 뒷면 `소시지`와 예문·해석, 다음 `2 / 50`, 뒤로 → "그만할까요?" / 시험 20문제를 끝까지(두 방향 모두 나옴) → 결과 `20문제 중 6문제 맞혔습니다` · 틀린 단어 14개 → 홈 `오답 노트 · 14단어`(DB `quiz_log` 20 · `wrong_notes` 14와 같음) / 앱 정보 "단어 출처" 문구 `초·중등 단어의 선정과 난이도 구분은 …`과 인용 두 개. logcat의 flutter 오류 0건
  - **유사어 쌍**: 기록한 17문제(4~20번)의 보기를 `similarWordPairs` 71쌍(중등 쉬움 안 16쌍)과 대조해 함께 나온 것 0건, 1~3번은 눈으로 봄. 다만 20문제로는 무작위로도 겹칠 일이 드물어 **규칙이 기기에서 도는 증거로는 약하다** — 근거는 여전히 자동 시험
  - **안 본 것**: 중등 중간·어려움 칸의 카드·시험, 진도 화면, 소리, 처음 설치의 시작 화면
  - 확인에 쓴 단어장 `mid1`(중등 쉬움)은 지우지 않았고 홈이 `mid1`이다(시작할 때 홈은 `😀`). 확인 뒤 DB 사본 `after_v9_checked.db`

- **2026-11-23 밤 개인 PC — release APK(설치 파일)**
  - `flutter build apk --release` exit 0 → `build/app/outputs/flutter-apk/app-release.apk` 50.3MB(23:54 새로 생김, 빌드 약 74초). 디버그 키 서명(`android/app/build.gradle.kts`의 Flutter 기본값)
  - APK 안: `.db`·`.sqlite` 파일 0개, `assets/words/` 단어 파일 9개(`unzip -l`로 확인) — 기록은 기기에서 첫 실행 때 빈 DB로 생긴다
  - 에뮬레이터: 디버그 빌드 위에 `adb install -r` 성공(같은 키라 데이터 유지), 홈과 카드 학습(`1 / 25`)이 뜸, DEBUG 띠 없음, 앱 오류 로그 0건. 처음 설치의 시작 화면은 보지 않음
  - 사본: `D:\dev\tmp\vocab_apk\vocab-1.0.0-release.apk`(SHA-256 `951c2932…b33d58`)
- **2026-11-23 밤 개인 PC — DB 8판(옛 초등 번호 `ee-`·`em-`·`eh-`의 기록 지우기)**(커밋 전 작업 폴더)
  - `flutter analyze` exit 0(No issues), `flutter test` exit 0(**168개** — 7판 → 8판 실제 DB 시험 포함), `flutter build apk --debug` exit 0
  - **에뮬레이터: 통과**(설치 전 DB `D:\dev\tmp\vocab_db_backup\after_words800.db` → `adb install -r` → 실행): `user_version` 7 → 8, `study_log` 147 → 60 · `quiz_log` 62 → 33 · `wrong_notes` 1 → 0(옛 초등 번호 줄 0건, 계산한 값과 같음), 단어장 4개와 설정 그대로. 초등 쉬움 단어장 진도가 `아직 시작하지 않았습니다` · `외운 단어 0/267` · `오답 노트 0단어`(캡처) — 홈·오답 노트 화면의 0단어와 맞는다. logcat의 flutter 오류 0건. 설치 뒤 DB 사본 `after_v8.db`
  - 검토: code-reviewer APPROVE(LOW 2건 고침 — 2026-11-23). 확인 뒤 홈을 `ddxd`로 되돌리는 조작을 했다(되돌아갔는지 캡처로 보지는 않음)
- **2026-11-23 밤 개인 PC — 초등 800개(CEFR-J) + 유사어 쌍 보기 규칙 · 카드 뽑기 2:8 · 뜻 보충 17줄**(커밋 `2e85dff`)
  - `flutter analyze` exit 0(No issues), `flutter test` exit 0(**167개**), `python tool/wordlist/cells.py check` 3칸 문제 0건(267 · 267 · 266), `flutter build apk --debug` exit 0
  - 검토: `/oh-my-claudecode:review` 두 축(둘 다 COMMENT, 막는 지적 없음) → 지적을 고침. 고친 것은 다시 검토받지 않았다
  - **에뮬레이터: 통과, 어긋남 1건**(설치 전 기기 DB 백업 `D:\dev\tmp\vocab_db_backup\before_words800\vocab.db` → `adb install -r` → adb로 누르고 캡처로 확인 — 사람이 직접 써 본 것은 아니다)
    - 홈: `ddxd` 초등 어려움 `266단어`, 초등 쉬움 단어장 `267단어`. 카드 학습 `1 / 25`(첫 카드 `smart`), 시험 `1 / 20`(`college` — 보기 과학자·양동이·대학·~의)이 열림
    - 앱 정보: "단어 출처"에 CEFR-J 인용과 빈도 자료 인용이 보임
    - 기기 DB: `user_version` 7, `study_log` 147 · `quiz_log` 62 · `wrong_notes` 1 · 단어장 4개 그대로. logcat의 flutter 오류 0건
    - **어긋남 — 옛 번호 기록**: 초등 쉬움 단어장(`deck_1`)에는 옛 번호 기록이 있다(`quiz_log` ee-010 맞힘·ee-037 틀림, `wrong_notes` ee-037). 앱은 깨지지 않지만 **진도 화면은 `외운 단어 1/267` · `오답 노트 1단어`로 세고, 홈은 `오답 노트 · 0단어`, 오답 노트 화면은 비어 있다**(지금 단어 파일에 없는 번호라 목록에 못 그림). 고치지 않았다 — 옛 번호 기록을 지울지, 진도가 지금 단어만 세게 할지는 사용자 결정
    - 안 본 것: 카드를 넘긴 뒤 다시 열었을 때 안 본 단어가 먼저 나오는지(자동 시험만), 유사어 쌍이 보기에 함께 안 나오는지(자동 시험만), 뒷면의 보충한 뜻, 소리
    - 확인 뒤 홈은 처음과 같은 `ddxd`로 되돌렸다. 설치 뒤 DB 사본은 `D:\dev\tmp\vocab_db_backup\after_words800.db`
- **2026-11-23 개인 PC — 문구 통일(`읽지 못했습니다`, 맨 끝 마침표 빼기)**
  - `flutter analyze` exit 0(No issues), `flutter test` exit 0(145개), `flutter build apk --debug` exit 0 + `app-debug.apk` 20:52 새로 생김
  - **에뮬레이터**: 덮어 설치(20:54) 뒤 설정 화면의 안내 문구 `…있는 단어를 모두 씁니다`(맨 끝 마침표 없음)를 캡처로 확인, logcat의 flutter 오류 0건. 나가기 확인 창·단어장 지우기 확인 창·난이도 버튼의 `읽지 못했습니다`는 기기에서 안 봄(앞의 둘은 자동 시험이 문구를 확인)

- **2026-11-23 개인 PC — UX 점검의 사소한 지적 5건 + 그 검토 지적 3건**
  - `flutter analyze` exit 0(No issues), `flutter test` exit 0(145개 — 첫 카드·첫 문제의 진행 막대, 뒷면 발음 버튼, "다음 문제" 버튼 자리, 낮은 화면에서 풀이까지 스크롤·다음 문제는 맨 위, 가로로 낮은 화면의 카드 뒷면이 늘어남), `flutter build apk --debug` exit 0 + `app-debug.apk` 20:41 새로 생김
  - 새 시험이 고치기 전에 실패하는지는 따로 돌려 보지 않았다(코드와 시험을 함께 씀)
  - **에뮬레이터: 통과**(개인 PC, `bac3a63` 빌드를 덮어 설치, adb로 누르고 캡처로 확인 — 사람이 직접 써 본 것은 아니다): 카드 학습 첫 카드의 진행 막대(`1 / 25`만큼 참), 뒷면 발음 버튼(누르면 logcat `TTS dispatch` 1건, 카드는 뒷면 그대로), `학교급을 고르세요`·`난이도를 고르세요`, 시험 첫 문제의 진행 막대, 답한 뒤 `다음 문제` 버튼이 1·2번 문제에서 같은 자리(화면 맨 아래), 가로 화면에서 답하면 풀이와 버튼이 함께 보이게 내려가고 다음 문제는 맨 위에서 시작, 오답 노트 `1회 틀림`. logcat의 flutter 오류 0건
  - 확인은 임시 단어장 `zzcheck`(초등 쉬움)에서 했고 끝난 뒤 지웠다. 홈은 처음과 같은 `ddxd`로 되돌렸다. 가로 화면을 보려고 에뮬레이터의 자동 회전을 껐다(`accelerometer_rotation` 0 — 바꾸기 전 값은 적어 두지 못했다)
  - **확인 안 한 것**: 카드 뒷면의 가로 화면(자동 시험만), 소리를 귀로 듣기, 오답 시험 흐름

- **2026-11-22 개인 PC — 단어장별 설정 검토 지적 8건 수정**
  - `flutter analyze` exit 0(No issues), `flutter test` exit 0(139개 — 시험을 안 푼 날의 날짜 줄, 설정 읽기 실패 뒤 다시 읽기, 두 설정을 잇달아 바꾸기 시험이 늘어남), `flutter build apk --debug` exit 0 + `app-debug.apk` 21:53 새로 생김
  - 동작이 바뀐 3건은 시험이 먼저 실패하는 것을 executor가 확인했다고 보고. Claude가 다시 돌린 것은 최종 통과뿐이다
  - **기기 확인 안 함** — 에뮬레이터에는 `930fd32` 빌드가 그대로다(사용자가 쓰는 중이라 다시 설치하지 않음)

- **2026-11-22 개인 PC — 단어장별 설정 + DB 7판**
  - `flutter analyze` exit 0(No issues), `flutter test` exit 0(137개 — 규칙(고유 → 옛 공통 → 기본) 시험, 실제 DB 6 → 7판·단어장별 저장, 실제 라우터로 단어장 A·B 설정이 따로인지 등이 늘어남), `flutter build apk --debug` exit 0 + `app-debug.apk` 21:17 새로 생김
  - 새 시험은 구현 전에 컴파일 단계에서 실패했다고 executor가 보고(새 API가 없어서 — 단정이 틀려 실패한 것은 아님). 새 설치와 1·3·6판에서 올린 DB의 `sqlite_master` 비교 시험 통과(새 설치도 같은 `ALTER TABLE`을 밟는다)
  - **에뮬레이터: 통과** — 설치 전 기기 DB 백업(`D:\dev\tmp\vocab_db_backup\before_v7\vocab.db`) → 덮어 설치 → `user_version` 7, `study_log` 147·`quiz_log` 62·`wrong_notes` 1 그대로, `study_decks`에 두 열이 NULL로 생김. 설정 화면 제목 `초등 중간 - 설정`·안내 문구 `이 단어장에만 적용됩니다. …`, 옛 공통값을 물려받아 `직접 입력 (25)`. "초등 중간"만 10으로 바꾸니 그 단어장 카드 학습 `1 / 10`, DB 그 줄만 `card_count = 10`, 다른 단어장(`😀`)은 설정·카드 학습 모두 25. logcat 오류 0건. 확인 뒤 25로 되돌림(그 단어장은 이제 고유 값 25)
  - **확인 안 한 것**: 새 단어장이 50/20으로 시작하는지는 기기에서 안 봄(자동 시험만), 시험 문항 수 쪽 기기 확인, 별도 코드 검토

- **2026-11-22 개인 PC — 남은 검토 지적(LOW) 9건 수정**
  - `flutter analyze` exit 0(No issues), `flutter test` exit 0(122개 — 오답 시험 문항 수 2개, 이전으로 돌아온 뒤 나가기 확인, 경로별 `sqlite_master` 비교 등이 늘어남), `flutter build apk --debug` exit 0 + `app-debug.apk` 21:06 새로 생김
  - 동작이 바뀐 것은 시험이 먼저 실패하는 것을 executor가 확인했다고 보고(단어장 삭제 시 기록 `Expected: <0> Actual: <1>`, 달력 문구, 나가기 확인). Claude가 다시 돌린 것은 최종 통과뿐이다
  - **기기 확인 안 함** — 에뮬레이터에는 `6505547` 빌드가 그대로다

- **2026-11-22 개인 PC — 에뮬레이터에서 DB 6판 이행과 눌러 보지 않았던 화면 확인** (커밋 `6505547` 빌드, `adb install -r`로 덮어 설치)
  - **DB 6판 이행: 통과** — 설치 전에 기기 DB를 꺼내 두고(`D:\dev\tmp\vocab_db_backup\before_v6\vocab.db`, 기기와 md5 일치) 남아야 할 오답 노트를 앱 SQL과 따로 파이썬으로 계산 → 설치·실행 뒤 다시 꺼낸 DB와 일치. `user_version` 5 → 6, `word_books`·`book_words`·인덱스 `book_words_book` 사라짐, `wrong_notes` 40 → 1줄(남은 것은 `deck_1`의 시험 오답 1개 — 지워진 39줄은 옛 카드 '모른다', 그중 36줄은 등록 안 한 칸 `high_hard`·`elementary_hard`), `study_log` 146줄·`quiz_log` 47줄·`study_decks` 3개 그대로. 설정(카드 수 직접 입력 25, 시험 20)도 유지
  - **화면(adb로 눌러 확인, 접근성 노드 + 캡처)**: 새 등록(이름 창 `다음` → `새 단어장 - <이름>`·`학교급을 골라 주세요` → `난이도를 골라 주세요` → 새 단어장이 홈) / 메뉴 ⋮ 이름 바꾸기·지우기(확인 창 문구, 지운 뒤 메뉴에서 사라짐) / 카드 학습 다음 → 이전 → 다음 뒤 진도에 `카드 1장`(중복 기록 안 함) / 학습·시험 도중 **시스템 뒤로 키** → "그만할까요?" → 계속하기·나가기, 결과 화면에서는 묻지 않고 나감 / 설정 직접 입력(0은 `1에서 999 사이의 숫자를 입력하세요`, 5는 `직접 입력 (5)`로 저장되고 시험이 `1 / 5`) / 시험 결과(점수·퍼센트·이번에 틀린 단어·버튼 3개) / **결과의 `오답 노트 보기` → 방금 틀린 단어까지 5단어, `홈으로` → 홈 `오답 노트 · 9단어`**(`d442292`에서 고친 회귀) / 오답 지우기 → 스낵바 `되돌리기` → 5단어로 복원 / 진도(진행 1일차, 외운 단어 5/50, 달력 22일에 점, `카드 1장 · 시험 맞힘 5문제`). logcat에 Flutter 오류 0건
  - 확인에 쓴 단어장("Night2")은 지웠고 시험 문항 수는 20으로 되돌렸다. 지운 단어장의 `study_log` 1줄·`quiz_log` 15줄(`deck_5`)은 DB에 남는다 — `deleteDeck`이 원래 그렇게 한다
  - **확인 안 한 것**: 오답 시험(`/review/quiz`)을 기기에서 풀어 보기, 뒤로 **제스처**(키만 확인), 소리(TTS), 처음 설치의 시작 화면, 단어장을 모두 지웠을 때

- **2026-11-22 개인 PC — 직접 단어장 삭제 + DB 6판**
  - `flutter analyze` exit 0(No issues), `flutter test` exit 0(118개 — 직접 단어장 시험 2파일을 지워 줄고, 5 → 6판 이행 시험 1개와 옮긴 오답 시험 막힘 시험 1개가 늘어남), `flutter build apk --debug` exit 0 + `app-debug.apk` 20:24 새로 생김(171,370,080바이트, `build/app/outputs`를 지운 뒤)
  - 이행 시험은 구현 전에 실패를 먼저 확인함(`Expected: <6> Actual: <5>`, 틀린 횟수 `<3> instead of <1>`). 실제 DB(sqflite_common_ffi)로 1·2·4·5판 → 6판을 본다
  - 같은 날 두 축 코드 검토(둘 다 COMMENT) 뒤 정리 기준을 "노트가 생긴 뒤의 시험 오답만"으로 고침 — 이행 시험 2개가 먼저 실패(`last_missed_at is <200> instead of <3>`), 고친 뒤 analyze exit 0 · test exit 0(118개) · build apk exit 0(`app-debug.apk` 20:38 새로 생김). 검토자가 확인한 것: 이행은 한 트랜잭션(sqflite_common 2.5.17 소스), 새 설치와 1~5판 경로의 최종 스키마가 같음(같은 SQL을 sqlite로 재현)
  - **기기 DB 이행: 확인 안 함** — 에뮬레이터(지금 5판)에 설치하지 않았다. 설치하면 오답 노트 정리와 표 삭제가 실제로 돈다(되돌릴 수 없음). 고친 정리 기준은 다시 검토받지 않았다

- **2026-11-22 개인 PC — 검토 지적 2건 수정(시험 결과 뒤 오답 노트 갱신, 카드 중복 기록)**
  - `flutter analyze` exit 0(No issues), `flutter test` exit 0(130개 — 실제 라우터로 홈 → 시험 → `오답 노트 보기`/`홈으로` 2개, 학습 화면 다음 → 이전 → 다음 1개가 늘어남), `flutter build apk --debug` exit 0 + `app-debug.apk` 20:09 새로 생김(171,392,376바이트, `build/app/outputs`를 지운 뒤)
  - 새 시험 3개는 고치기 전에 실패하는 것을 먼저 확인함(홈에 `오답 노트 · 4단어` 없음, 기록 `['ee-001', 'ee-001']`)
  - **기기 실행: 확인 안 함** — 에뮬레이터에 설치하지 않았고 눌러 보지 않았다. 고친 뒤 별도 검토 에이전트도 돌리지 않았다

- **2026-11-21 개인 PC — 내 단어장**
  - `flutter analyze` exit 0, `flutter test` exit 0(70개 — 실제 DB `test/data/word_books_test.dart` 5개, 화면 `test/features/my_words_test.dart` 11개, 보기 글자 겹침 2개가 늘어남), `flutter build apk --debug` exit 0
  - code-reviewer REQUEST CHANGES(HIGH 1 · MEDIUM 1) → 고친 뒤 시험 통과. 고친 뒤 다시 검토받지는 않았다
  - 에뮬레이터: ☰ 메뉴에 "내 단어장"(캡처), **기기 DB `user_version` 4, 시험 기록 18건 유지, `word_books`·`book_words` 생김**. 단어장 만들기 → 단어 추가 → 시험은 기기에서 눌러 보지 않음

- **2026-11-20 개인 PC — 화면 이름 정리·진도 화면**
  - `flutter analyze` exit 0, `flutter test` exit 0(52개 — 진도 화면 2개, 실제 DB에 2 → 3판 이행·진도 집계·연속 학습일 3개, 버전 표시 1개 등이 늘어남), `flutter build apk --debug` exit 0
  - 에뮬레이터: 홈(제목 `중등 [난이도 : 중간]`, 시험 버튼, 맨 아래 고정 메인화면), 메뉴(`영단어 v1.0.0`, 쉬움·중간·어려움), 메인화면(제목 가운데, 안내 문구, ← 뒤로 없음), **진도**(연속 학습 1일, 9줄, 지금 칸 강조, 중등 중간 외움 9/50) 캡처로 확인
  - **DB 이행: 통과** — 기기 DB `user_version` 3, 시험 기록 18건 유지
  - 진도 화면은 별도 검토 에이전트를 돌리지 않았다

- **2026-11-20 개인 PC — 화면 구조(학교급 → 난이도 → 칸 홈)·오답 노트**
  - `flutter analyze` exit 0, `flutter test` exit 0(46개), `flutter build apk --debug` exit 0 + `app-debug.apk` 22:37 새로 생김
  - code-reviewer APPROVE(오답 노트) — MEDIUM 2건(다시 보기·오답 시험 중복 열림, 다시 보기 목록이 회차 중 바뀜)과 LOW(맞힌 단어 표시 시점, 문구, 테스트 빈틈 3건) 반영
  - 에뮬레이터: 학교급·난이도 고르기가 세로 버튼(캡처) → 중등 · 중 → 앱 강제 종료·재실행 → **"중등 · 중" 칸 홈이 바로 뜸** → ☰ 메뉴가 학교급 ▸ 난이도 2단계, 지금 학교급 펼침(캡처). 직전 버전에서 사용자가 오답 시험을 풀어 **맞힌 단어가 `wrong_notes`에서 빠지고 `quiz_log`는 남음**(DB 확인)
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
