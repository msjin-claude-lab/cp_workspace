# vocab — 영단어 앱 (초·중·고)

초·중·고 학생이 학교급 × 난이도 9칸의 내장 단어(칸당 50개)와 직접 만든 단어장으로 카드 학습·4지선다 시험·오답 노트를 하고, 진도를 칸별·날짜별로 보는 안드로이드·iOS 앱. 계정 없음, 기록은 기기 안에만.

공통 규칙은 [../CLAUDE.md](../CLAUDE.md)(apps)와 루트 `CLAUDE.md`. Claude Code는 저장소 루트에서 열고 "`projects/apps/vocab`에서 작업한다"로 시작한다.

## 인계 — 새 세션은 여기부터 읽는다

- 지금 단계: **개발 — 카드 학습 화면 만들고 기기에서 확인함** · 2026-11-20 개인 PC
- 카드 학습: 칸 누르기 → `/study/<칸 id>` → 앞면 영단어(카드가 뜰 때 한 번 자동 발음, 🔊 버튼) → 누르면 뒷면 뜻·예문·해석 → 안다/모른다 → 끝나면 결과(안다 N · 모른다 M, 다시 하기, 칸 선택으로). 기록은 sqflite `vocab.db`(`lib/data/study_records.dart` — `study_log`에 답마다 한 줄 + 기기 날짜 `answered_day`, `wrong_notes`에 모른다 단어와 틀린 횟수). **사용자 확정(2026-11-20)**: 카드는 파일 순서(섞지 않음), 안다로 답해도 오답 노트에서 빼지 않음, 중간에 나가면 처음부터, 안다/모른다는 뜻을 본 뒤에만(Anki 방식 — 앞면 판정 안 함)
- 멈춘 곳: 개인 PC에 개발 환경을 처음 설치하고(세 층 SETUP.md, [../SETUP.md](../SETUP.md) "개인 PC 설치 기록") 에뮬레이터에서 칸 선택·카드 학습·자동 발음·소리·기록 저장 유지·오답 노트를 모두 확인([VERIFY.md](VERIFY.md) "마지막 결과" 2026-11-20). 9칸 × 50개 단어는 끝
- 다음 할 일: **4지선다 시험 화면**(영→뜻·뜻→영, 오답 보기는 같은 칸, 답한 뒤 정답·예문, 틀리면 오답 노트) — `/apps:selection-subject vocab`. 화면 확인은 개인 PC 에뮬레이터에서(기본 그래픽으로 빠름). 단어 표본은 원하면 언제든 사용자가 더 볼 수 있다
- 주의할 것:
  - **iOS는 잠정 보류**(2026-11-18 사용자 결정, 추후 지시까지 안드로이드만). 패키지는 iOS도 지원하는 것만 쓴다
  - TTS 소리는 개인 PC에서 귀로 확인함(2026-11-20). 에뮬레이터 미디어 볼륨 기본값 5/15라 작게 들리니 올려서 듣는다. 가끔 깨지는 것은 에뮬레이터 오디오 구간으로 추정(앱 원인 아님, 확인 안 함)
  - 기기 확인은 **에뮬레이터로만**(폰 연결 안 함). **사내망 PC 에뮬레이터는 너무 느려 실용적이지 않다**(2026-11-19) — 사내망 PC는 analyze·test·build까지, 화면을 눌러 보는 확인은 개인 PC에서([../SETUP.md](../SETUP.md) "함정")
  - 개인 PC에서 에뮬레이터 창을 사용자가 직접 누를 수 있다 — adb로 확인할 때 사용자 터치가 섞이니 강제 종료 등은 먼저 알린다
  - 사내망 PC에서는 github.com이 막혀 Gradle 새 버전 등은 밖에서 받아 와야 한다([../../SETUP.md](../../SETUP.md))
  - 시험용 프로젝트 `D:\dev\tmp\vocab_probe`(저장소 밖, 4단계용)는 지워도 된다

## 남은 일

- **단어 데이터 작성** — 9칸 × 50개(명세: Claude가 작성, 예문·해석은 새로 씀, 칸마다 표본을 사람이 확인). 2026-11-20 450개 끝(중등 중·상, 고등 3칸은 사람 표본 확인 없이 에이전트 검토만)
- 화면: ~~카드 학습~~(2026-11-20) → 4지선다 시험 → 오답 노트 → 진도 → 내 단어장
- ~~기기에서 확인: 카드 학습 DB 저장·자동 발음~~ · ~~TTS 소리 귀로 확인~~ · ~~개인 PC 개발 환경 설치~~(모두 2026-11-20 개인 PC)
- iOS 확인(보류 해제 시 — 대안은 [docs/options.md](docs/options.md) "먼저 알아 둘 것")
- release 빌드 확인

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
| 폴더 | **기능별** — `lib/features/<기능>/`(home, 앞으로 study·quiz·wrong_notes·progress·my_words), 공통 데이터는 `lib/data/` | 기능 하나를 고칠 때 그 폴더만 본다 |
| 화면 이동 | **go_router** — 경로 목록은 `lib/router.dart` 한 곳 | 화면 관계를 한 파일에서 본다 |
| 상태 관리 | **Riverpod**(`flutter_riverpod`, 코드 생성 없이) — 시험에서는 `overrideWithValue`로 가짜를 넣는다 | 정형화돼 있고 시험하기 쉽다 |
| 단어 데이터 | **칸별 JSON** `assets/words/<학교급>_<난이도>.json`(필드 `id`·`word`·`meaning`·`example`·`exampleMeaning` — 예문 해석은 2026-11-20 사용자 결정으로 추가), 바뀌는 기록(학습·오답·내 단어장·진도)은 **sqflite** | 단어를 사람이 읽고 고치기 쉽고 git에서 바뀐 것이 보인다. 수만 개 규모가 되면 미리 만든 DB 파일로 바꾼다 |

- 칸은 `lib/data/cell.dart`의 `Cell`(학교급 × 난이도 9개). 화면 이름 `초등 · 하`, 파일 이름 `elementary_easy`
- 단어 읽기는 `lib/data/word_repository.dart`(`cellWordsProvider(cell)`)
- 시험(`test/`)은 기능·데이터마다 하나씩 늘린다

## 파일

- [docs/spec.md](docs/spec.md) — 1단계 명세(deep-interview, 원본 `.omc/specs/deep-interview-vocab.md`)
- [docs/options.md](docs/options.md) — 2단계 후보 4개와 장단점, 3단계에서 고른 것(Flutter)과 이유
- [SETUP.md](SETUP.md) — 이 앱의 개발 환경(패키지·설정·가상 기기·확인 상태). 공통은 [../SETUP.md](../SETUP.md)
- [VERIFY.md](VERIFY.md) — 검증 명령·기대값·함정·마지막 결과

## 진행 이력

덧붙이기만 한다. 1~4단계는 `projects/apps/_drafts/vocab/README.md`에 있던 것을 옮겼다.

- 2026-11-17 사내망 · 후보 · 앱 그룹을 만들며 "캘린더형·기록형(먼저), 게임형(나중)"이 후보로 이야기됨. 영단어 앱은 아직 없음
- 2026-11-18 사내망 · 1단계 시작 · `/apps:new` → `/oh-my-claudecode:deep-interview`로 영단어 앱(초·중·고) 인터뷰
- 2026-11-18 사내망 · 1단계 완료 · 7라운드, 모호도 약 19%(기준 20%). 9칸 × 50단어, 카드 학습·4지선다·오답 노트·진도, 계정 없음, TTS만. 명세 요약은 HANDOFF·`projects/apps/CLAUDE.md`에 적음
- 2026-11-18 사내망 · 수정 · 주제 폴더 방식으로 옮김 — 명세를 `spec.md`로 복사, 진행 상태를 이 README로. HANDOFF·`projects/apps/CLAUDE.md`의 vocab 내용은 정리
- 2026-11-18 사내망 · 수정 · README에 "인계" 절을 둠(주제 인계 규칙). 다음 할 일은 `/apps:selection-subject vocab`로
- 2026-11-18 사내망 · 2단계 완료 · `/apps:selection-subject vocab` → `/oh-my-claudecode:research`(공식 문서 조사 2갈래)로 후보 4개(Expo·Flutter·KMP·.NET MAUI)와 장단점을 `options.md`에. 어느 쪽이든 아이폰 설치에 유료 Apple 계정 또는 Mac 필요
- 2026-11-18 사내망 · 3단계 완료 · **Flutter** 선택. 전제: 무료 위주, 안드로이드 먼저·iOS 보류, 모바일만, 나중에 2D 게임(Flame), AI로 개발. 사용 추세·RN 차이·카드 뒤집기 등을 비교한 뒤 정함(`options.md` "3단계")
- 2026-11-18 사내망 · 4단계 멈춤 · github.com 접속 시간 초과로 사내망 PC 판단 → 개인 PC에서 4단계 필요
- 2026-11-18 사내망 · 수정 · 사용자 요청으로 사내망 PC에 Flutter 3.50.0 stable을 zip으로 설치(storage.googleapis.com, sha256 일치, `D:\dev\flutter`, 사용자 PATH 추가). 임시 프로젝트로 `flutter create`·`pub add flutter_tts sqflite`·`analyze`·`test` 모두 exit 0. 안드로이드 SDK 없음 — 4단계(안드로이드 빌드·에뮬레이터)는 여전히 개인 PC
- 2026-11-18 사내망 · 수정 · 사용자 요청으로 Android Studio Rabbit 2 Patch 1(zip)·command-line tools·SDK(platform-tools, emulator, platforms;android-36, build-tools;36.1.0, 시스템 이미지 36 google_apis x86_64)·가상 기기 `vocab_api36` 설치. 라이선스는 사용자가 직접 동의. Gradle 9.5.0은 services.gradle.org → github.com 리다이렉트로 막혀 사용자가 받아 온 zip(sha256 일치)을 래퍼 캐시에 넣음. 임시 프로젝트 `flutter build apk --debug` exit 0(첫 빌드 약 29.5분). WHPX 꺼짐이라 에뮬레이터 실행은 확인 못 함
- 2026-11-18 사내망 · 수정 · 개발 환경 가이드를 두 층으로 — 공통 `projects/apps/SETUP.md`, 주제별 `setup.md`(vocab 패키지·설정·가상 기기·확인 상태)
- 2026-11-18 사내망 · 4단계 시작 · 사용자 결정으로 사내망 PC에서도 가능한 데까지 진행. 시험용 프로젝트 `D:\dev\tmp\vocab_probe`(flutter_tts·sqflite·TTS manifest). doctor·analyze·test exit 0, build apk는 Kotlin 증분 캐시 실패(D:·C: 드라이브) → `kotlin.incremental=false` 뒤 exit 0. `/oh-my-claudecode:verify`(verifier) 안드로이드 명령 통과. 기기 실행·TTS 소리(WHPX 꺼짐)·iOS(보류) 확인 못 함 → 4단계 통과 아님, `verify.md`
- 2026-11-18 사내망 · 수정 · iOS 잠정 보류 — 추후 지시까지 안드로이드만으로 5단계까지 진행(사용자 결정). 4단계는 안드로이드 기기 실행 확인으로 닫는다
- 2026-11-18 사내망 · 4단계 멈춤 · 기기 실행 확인 시도 — WHPX 여전히 꺼짐, 연결 기기 없음. 사용자 결정: 실제 폰은 앞으로도 연결 안 함 → 에뮬레이터로만(WHPX 켠 PC에서)
- 2026-11-19 사내망 · 4단계 완료 · WHPX 켜고 "다시 시작"으로 재부팅(시스템 종료 후 켜기는 빠른 시작 때문에 적용 안 됨). 에뮬레이터는 기본 그래픽에서 화면이 멈춰 `-gpu swiftshader_indirect`로. 시험 화면을 붙여 앱 실행·저장 유지·TTS 합성·오디오 출력 확인, `/oh-my-claudecode:verify`(verifier) APPROVE. TTS 귀로 듣기는 사무실이라 확인 못 함 → 사용자 결정으로 나중에(개인 PC). **4단계 통과(안드로이드), iOS 잠정 보류**
- 2026-11-19 사내망 · 5단계 완료 · `projects/apps/vocab/`에 Flutter 프로젝트(`flutter create --platforms=android,ios --org dev.cp`) + `flutter_tts`·`sqflite`·`path` + TTS manifest + `kotlin.incremental=false`. 기록을 옮김(verify.md → VERIFY.md, setup.md → SETUP.md, spec·options → docs/, 이 README → CLAUDE.md), `_drafts/vocab/` 지움. VERIFY.md 명령 통과(`/oh-my-claudecode:verify`)
- 2026-11-19 사내망 · 개발 · 코드 구조(기능별 폴더·go_router·Riverpod·칸별 JSON) 결정, 칸 선택 화면과 단어 읽기. 사내망 PC 에뮬레이터는 너무 느려 화면 확인은 개인 PC로
- 2026-11-20 사내망 · 개발 · "단어 먼저". 예문 해석 필드를 더함(사용자 결정, 명세에 추가). 초등 하·중·상 150개 작성(하·중 표본 확인), 단어 파일 검사 시험 4개 — 시험 8개 통과
- 2026-11-20 사내망 · 개발 · 사용자 지시 "단어는 끝까지"로 중등·고등 6칸 300개를 마저 써 450개 완성. code-reviewer 검토로 뜻 20여 곳 수정(incentive "동기"→"유인", scrutiny "감시" 삭제, 보기가 겹치는 뜻 구분). 시험을 "칸마다 정확히 50개"·"같은 칸 같은 뜻 없음"으로 조임 — 시험 9개 통과
- 2026-11-20 사내망 · 개발 · 카드 학습 화면(`lib/features/study/`), 칸 → 학습 연결, TTS(`speaker.dart`), sqflite 학습 기록·오답 노트(`study_records.dart`). code-reviewer REQUEST CHANGES 반영(연타 중복 기록 막기, TTS 오류 삼키기, 진도용 날짜 칸·인덱스, 저장 실패 표시 — 스낵바가 답 버튼을 덮어 화면 안 문구로). 시험 18개 통과, build apk exit 0
- 2026-11-20 개인 PC · 확인 · `/apps:selection-subject vocab`. 학습 세부 3가지 사용자 확정(파일 순서·오답 노트 유지·처음부터) + 판정은 뜻을 본 뒤(Anki 방식). 개인 PC에 Flutter 3.50.0·Android SDK·`vocab_api36` 설치(Android Studio 없이 JDK 21), WHPX 켜고 재부팅. analyze·test(18)·build apk exit 0. 에뮬레이터(기본 그래픽)에서 칸 선택·카드 학습·자동 발음·소리(볼륨 올려서)·저장 유지·오답 노트 모두 확인
