# vocab — 영단어 앱 (초·중·고)

초·중·고 학생이 학교급 × 난이도 9칸의 내장 단어(칸당 50개)와 직접 만든 단어장으로 카드 학습·4지선다 시험·오답 노트를 하고, 진도를 칸별·날짜별로 보는 안드로이드·iOS 앱. 계정 없음, 기록은 기기 안에만.

공통 규칙은 [../CLAUDE.md](../CLAUDE.md)(apps)와 루트 `CLAUDE.md`. Claude Code는 저장소 루트에서 열고 "`projects/apps/vocab`에서 작업한다"로 시작한다.

## 인계 — 새 세션은 여기부터 읽는다

- 지금 단계: **5. 최종 결정 끝 — 앱 폴더를 만들고 개발 시작 전** · 2026-11-19 사내망 PC
- 멈춘 곳: Flutter 프로젝트 뼈대(템플릿 카운터 앱 + `flutter_tts`·`sqflite`·`path`, TTS manifest, `kotlin.incremental=false`)를 만들고 VERIFY.md 명령(analyze·test·build apk)을 통과시킴. 화면 코드는 아직 없음
- 다음 할 일: **코드 구조의 큰 틀을 사용자와 정한다** — 폴더 나누기, 화면 이동 방식, 상태 관리, 내장 단어 데이터 형식. 정한 것은 아래 "코드 구조"에 적는다. 그다음 화면을 하나씩 만들고(첫 화면: 칸 선택) 에뮬레이터 캡처로 보여 주며 디자인을 정한다
- 주의할 것:
  - **iOS는 잠정 보류**(2026-11-18 사용자 결정, 추후 지시까지 안드로이드만). 패키지는 iOS도 지원하는 것만 쓴다
  - **TTS 소리를 귀로 확인하지 않았다** — 합성·오디오 출력까지만 확인(사무실). 개인 PC에서 들어 본다. 안 들리면 그때 설정·코드를 고친다(사용자 결정)
  - 기기 확인은 **에뮬레이터로만**(폰 연결 안 함). 사내망 PC는 `-gpu swiftshader_indirect`로 띄운다([../SETUP.md](../SETUP.md) "함정")
  - 사내망 PC에서는 github.com이 막혀 Gradle 새 버전 등은 밖에서 받아 와야 한다([../../SETUP.md](../../SETUP.md))
  - 시험용 프로젝트 `D:\dev\tmp\vocab_probe`(저장소 밖, 4단계용)는 지워도 된다

## 남은 일

- TTS 소리 귀로 확인(개인 PC)
- iOS 확인(보류 해제 시 — 대안은 [docs/options.md](docs/options.md) "먼저 알아 둘 것")
- 개인 PC 개발 환경 설치(세 층 SETUP.md) 후 VERIFY.md 명령 확인
- release 빌드 확인

## 명령

PATH에 `D:\dev\flutter\bin`(사내망 PC). 작업 위치: `projects/apps/vocab`.

| 무엇 | 명령 |
|---|---|
| 의존성 | `flutter pub get` |
| 정적 분석 | `flutter analyze` |
| 테스트 | `flutter test` |
| 안드로이드 빌드 | `flutter build apk --debug` |
| 에뮬레이터 | `D:\dev\android-sdk\emulator\emulator.exe -avd vocab_api36 -gpu swiftshader_indirect` |
| 실행 | `flutter run -d emulator-5554` |

**검증은 [VERIFY.md](VERIFY.md)를 읽고 `/oh-my-claudecode:verify`로 한다.** 통과는 종료 코드와 새로 생긴 결과 파일로만 판정한다.

## 코드 구조

아직 정하지 않음 — "다음 할 일" 참고. 정해지면 여기에 적는다.

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
