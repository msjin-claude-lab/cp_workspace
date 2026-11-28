# vocara — 영단어 앱 Vocara (초·중·고)

초·중·고 학생이 학교급 × 난이도 12칸의 내장 단어(CEFR-J 기준 초등 800개 · 중등 700개 · 고등 1,500개 · 심화 3,528개 — [docs/plan-words-phase1.md](docs/plan-words-phase1.md) · [phase2](docs/plan-words-phase2.md) · [phase3](docs/plan-words-phase3.md) · [phase4](docs/plan-words-phase4.md))를 이름 붙인 단어장으로 등록해 카드 학습·4지선다 시험·오답 노트를 하고, 진도를 단어장별·날짜별로 보는 안드로이드·iOS 앱. 계정 없음, 기록은 기기 안에만. 목록 화면 아래에 AdMob 배너(모두 어린이 처리).

공통 규칙은 [../CLAUDE.md](../CLAUDE.md)(apps)와 루트 `CLAUDE.md`. Claude Code는 저장소 루트에서 열고 "`projects/apps/vocara`에서 작업한다"로 시작한다.

**지금 상태·다음 할 일·남은 일·진행 이력은 [HANDOFF.md](HANDOFF.md)에 있다.** 이 앱을 이어 갈 때는 그 파일의 "인계"부터 읽는다(이어 가기: `/apps:selection-subject vocara`). 이 파일에는 규칙·명령·코드 구조만 둔다.

## 명령

PATH에 `D:\dev\flutter\bin`(두 PC 같은 경로). 작업 위치: `projects/apps/vocara`. 에뮬레이터 `-gpu swiftshader_indirect`는 사내망 PC만 — 개인 PC는 빼고 띄운다.

| 무엇 | 명령 |
|---|---|
| 의존성 | `flutter pub get` |
| 정적 분석 | `flutter analyze` |
| 테스트 | `flutter test` |
| 안드로이드 빌드 | `flutter build apk --debug` |
| Play용 빌드(개인 PC만 — 업로드 키, [SETUP.md](SETUP.md) "release 서명") | `flutter build appbundle --release` |
| 에뮬레이터 | `D:\dev\android-sdk\emulator\emulator.exe -avd vocab_api36 -gpu swiftshader_indirect` |
| 실행 | `flutter run -d emulator-5554` |

**검증은 [VERIFY.md](VERIFY.md)를 읽고 `/oh-my-claudecode:verify`로 한다.** 통과는 종료 코드와 새로 생긴 결과 파일로만 판정한다.

## 코드 구조 (2026-11-19 사용자 결정 — "추천대로")

| 무엇 | 정한 것 | 이유 |
|---|---|---|
| 폴더 | **기능별** — `lib/features/<기능>/`(home·study·quiz·wrong_notes·progress·settings·common), 공통 데이터는 `lib/data/` | 기능 하나를 고칠 때 그 폴더만 본다 |
| 화면 이동 | **go_router** — 경로 목록은 `lib/router.dart` 한 곳 | 화면 관계를 한 파일에서 본다 |
| 상태 관리 | **Riverpod**(`flutter_riverpod`, 코드 생성 없이) — 시험에서는 `overrideWithValue`로 가짜를 넣는다 | 정형화돼 있고 시험하기 쉽다 |
| 단어 데이터 | **칸별 JSON** `assets/words/<학교급>_<난이도>.json`(필드 `id`·`word`·`meaning`·`example`·`exampleMeaning` — 예문 해석은 2026-11-20 사용자 결정으로 추가), 바뀌는 기록(학습·시험·오답·단어장)은 **sqflite** | 단어를 사람이 읽고 고치기 쉽고 git에서 바뀐 것이 보인다. 수만 개 규모가 되면 미리 만든 DB 파일로 바꾼다 |

- 칸은 `lib/data/cell.dart`의 `Cell`(학교급 초등·중등·고등·심화 × 난이도 = 12개). 화면 이름 `초등 [난이도 : 쉬움]`, 파일 이름 `elementary_easy`. 학교급을 숨기려면 `hiddenLevelsProvider`(`lib/data/word_repository.dart`, 지금 빈 집합)
- 단어 읽기는 `lib/data/word_repository.dart`(`cellWordsProvider(cell)`)
- 고른 단어장 번호는 **shared_preferences**, 기록과 단어장별 설정은 sqflite(옛 공통 설정 `card_count`·`quiz_count`는 shared_preferences에서 읽기만 한다). DB 판을 올릴 때는 `SqfliteStudyRecords.schemaVersion`과 onUpgrade의 `oldVersion < N` 단계를 더하고 `test/data/study_records_test.dart`(sqflite_common_ffi)에 이행 시험을 더한다. 멈춘 판에서 시험해야 하는 단계는 `@visibleForTesting`으로 공개한다(예: `upgradeToV8`)
- 시험 섞기는 `quizRandomProvider` — 시험에서는 씨앗을 고정한 Random을 넣는다
- **오늘의 단어**(2026-11-28): `lib/features/today/`(고르기 `daily_pick.dart` 순수 함수, `todayWordsProvider`, 섞기 `dailyRandomProvider`), 화면은 `StudyScreen(today: true)`·경로 `/today/:deckId`. 저장은 DB 11판 `daily_words`(단어장·날짜별 단어 순서·본 단어·완료)와 `study_decks.daily_count`. 지금 시각은 `nowProvider`(시험에서 바꿔 넣음)
- **매일 알림**(2026-11-28): `lib/features/reminder/`(다음 시각 `reminder_schedule.dart` 순수 함수, 알림 패키지는 `ReminderNotifications` 뒤에 — 시험은 가짜, `ReminderHost`가 앱을 감싸 처음 실행 권한·눌러서 열기·다시 예약), 설정은 `lib/data/reminder_settings.dart`(shared_preferences, 기본 20:00). 패키지 `flutter_local_notifications` 22.3.3(23은 compileSdk 37 필요)·`timezone`, Android desugaring 켬
- **광고**(2026-11-29 사용자 결정): AdMob 배너 하나, `google_mobile_ads` 9.2.0, `lib/features/ads/`. 배너는 `BottomBanner`를 `Scaffold.bottomNavigationBar`에 넣는다 — 홈·오답 노트·진도·설정·단어장이 없을 때의 시작 화면·새 단어장 만들기(학교급·난이도)에만, **공부 화면(카드·오늘의 단어·시험·오답 시험)과 앱 정보에는 넣지 않는다**. 불러오기에 성공해야 자리가 생긴다(오프라인이면 자리 없음). **광고는 Android만** — `startAds()`가 Android가 아니면 바로 `false`(iOS는 Info.plist에 `GADApplicationIdentifier`가 없어 initialize가 앱을 끝낸다. iOS를 다시 시작할 때 앱 ID·`SKAdNetworkItems`를 넣는다). SDK는 `BannerAds` 뒤에 — 시험은 `bannerAdsProvider`를 가짜로, 시작(`startAds()`)이 실패하면 `NoBannerAds`
  - **모든 이용자를 어린이로 처리**(나이 확인 화면 없음 — 사용자 결정): `childDirectedRequestConfiguration()`(`ageRestrictedTreatment.child` + `tagForChildDirectedTreatment.yes` + 등급 G)을 `initialize()` 전에 넣는다. 맞춤 광고로 바꾸지 않는다
  - **ID**: debug = Google 테스트 ID, release = 실제 ID. 앱 ID는 `android/app/build.gradle.kts`의 `manifestPlaceholders["admobAppId"]`(debug/release 따로), 배너 단위는 `lib/features/ads/ad_ids.dart`(`kReleaseMode`로 고름). **release를 기기에 깔았을 때 광고를 누르지 않는다**(부정 클릭으로 계정이 막힐 수 있다)
  - **권한**: `android/app/src/main/AndroidManifest.xml`에서 `AD_ID`·`ACCESS_ADSERVICES_*` 3개를 `tools:node="remove"`로 뺀다(가족 정책). 광고 SDK가 `INTERNET`·`ACCESS_NETWORK_STATE`·`WAKE_LOCK`·`FOREGROUND_SERVICE`를 넣는다. 권한·광고 위치를 바꾸면 `store/`(처리방침·정책 답안·설명)를 함께 고친다
- 시험(`test/`)은 기능·데이터마다 하나씩 늘린다

## 파일

- [docs/spec.md](docs/spec.md) — 1단계 명세(deep-interview, 원본 `.omc/specs/deep-interview-vocab.md`)
- [docs/options.md](docs/options.md) — 2단계 후보 4개와 장단점, 3단계에서 고른 것(Flutter)과 이유
- [SETUP.md](SETUP.md) — 이 앱의 개발 환경(패키지·설정·가상 기기·확인 상태). 공통은 [../SETUP.md](../SETUP.md)
- [VERIFY.md](VERIFY.md) — 검증 명령·기대값·함정·마지막 결과
- [HANDOFF.md](HANDOFF.md) — 인계(지금 단계·다음 할 일·주의할 것), 남은 일, 진행 이력
