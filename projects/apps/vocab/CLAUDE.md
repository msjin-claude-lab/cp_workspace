# vocab — 영단어 앱 (초·중·고)

초·중·고 학생이 학교급 × 난이도 9칸의 내장 단어(CEFR-J 기준 초등 800개 · 중등 700개 · 고등 1,500개 — [docs/plan-words-phase1.md](docs/plan-words-phase1.md) · [phase2](docs/plan-words-phase2.md) · [phase3](docs/plan-words-phase3.md))를 이름 붙인 단어장으로 등록해 카드 학습·4지선다 시험·오답 노트를 하고, 진도를 단어장별·날짜별로 보는 안드로이드·iOS 앱. 계정 없음, 기록은 기기 안에만.

공통 규칙은 [../CLAUDE.md](../CLAUDE.md)(apps)와 루트 `CLAUDE.md`. Claude Code는 저장소 루트에서 열고 "`projects/apps/vocab`에서 작업한다"로 시작한다.

**지금 상태·다음 할 일·남은 일·진행 이력은 [HANDOFF.md](HANDOFF.md)에 있다.** 이 앱을 이어 갈 때는 그 파일의 "인계"부터 읽는다(이어 가기: `/apps:selection-subject vocab`). 이 파일에는 규칙·명령·코드 구조만 둔다.

## 명령

PATH에 `D:\dev\flutter\bin`(두 PC 같은 경로). 작업 위치: `projects/apps/vocab`. 에뮬레이터 `-gpu swiftshader_indirect`는 사내망 PC만 — 개인 PC는 빼고 띄운다.

| 무엇 | 명령 |
|---|---|
| 의존성 | `flutter pub get` |
| 정적 분석 | `flutter analyze` |
| 테스트 | `flutter test` |
| 안드로이드 빌드 | `flutter build apk --debug` |
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

- 칸은 `lib/data/cell.dart`의 `Cell`(학교급 × 난이도 9개). 화면 이름 `초등 · 하`, 파일 이름 `elementary_easy`
- 단어 읽기는 `lib/data/word_repository.dart`(`cellWordsProvider(cell)`)
- 고른 단어장 번호는 **shared_preferences**, 기록과 단어장별 설정은 sqflite(옛 공통 설정 `card_count`·`quiz_count`는 shared_preferences에서 읽기만 한다). DB 판을 올릴 때는 `SqfliteStudyRecords.schemaVersion`과 onUpgrade의 `oldVersion < N` 단계를 더하고 `test/data/study_records_test.dart`(sqflite_common_ffi)에 이행 시험을 더한다. 멈춘 판에서 시험해야 하는 단계는 `@visibleForTesting`으로 공개한다(예: `upgradeToV8`)
- 시험 섞기는 `quizRandomProvider` — 시험에서는 씨앗을 고정한 Random을 넣는다
- 시험(`test/`)은 기능·데이터마다 하나씩 늘린다

## 파일

- [docs/spec.md](docs/spec.md) — 1단계 명세(deep-interview, 원본 `.omc/specs/deep-interview-vocab.md`)
- [docs/options.md](docs/options.md) — 2단계 후보 4개와 장단점, 3단계에서 고른 것(Flutter)과 이유
- [SETUP.md](SETUP.md) — 이 앱의 개발 환경(패키지·설정·가상 기기·확인 상태). 공통은 [../SETUP.md](../SETUP.md)
- [VERIFY.md](VERIFY.md) — 검증 명령·기대값·함정·마지막 결과
- [HANDOFF.md](HANDOFF.md) — 인계(지금 단계·다음 할 일·주의할 것), 남은 일, 진행 이력
