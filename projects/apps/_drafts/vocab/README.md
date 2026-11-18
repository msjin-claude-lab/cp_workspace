# vocab — 영단어 앱 (초·중·고)

초·중·고 학생이 학교급 × 난이도 9칸의 내장 단어(칸당 50개)와 직접 만든 단어장으로 카드 학습·4지선다 시험·오답 노트를 하고, 진도를 칸별·날짜별로 보는 안드로이드·iOS 앱. 계정 없음, 기록은 기기 안에만.

## 인계 — 새 세션은 여기부터 읽는다

- 지금 단계: **4. 검증 (진행 중 — 안드로이드 명령 통과, 기기 실행·iOS 남음)** · 2026-11-18 사내망 PC
- 멈춘 곳: 사내망 PC에서 4단계를 할 수 있는 데까지 함 — `verify.md` "마지막 결과": doctor·analyze·test·build apk 통과(`/oh-my-claudecode:verify`), 에뮬레이터 실행·화면·TTS 소리는 WHPX가 꺼져 확인 못 함, iOS 보류
- 다음 할 일: 기기 실행 확인 — **개인 PC**에서(또는 사내망 PC에서 WHPX를 켠 뒤) `/apps:selection-subject vocab` → 4단계 이어서: `setup.md`대로 시험용 프로젝트 준비 → `flutter emulators --launch vocab_api36` → `flutter run`으로 화면·TTS 소리 확인 → `verify.md`에 PC를 밝혀 기록. 개인 PC는 설치부터(세 층 SETUP.md)
- 주의할 것: **iOS는 잠정 보류 — 추후 지시가 있을 때까지 안드로이드만으로 5단계까지 진행**(2026-11-18 사용자 결정). 안드로이드 기기 실행이 확인되면 4단계를 "안드로이드 통과, iOS 잠정 보류"로 닫고 5단계로 간다. 코드는 iOS도 지원하는 패키지만 쓰고, iOS 확인은 앱의 남은 일로 넘긴다. **새 Flutter 프로젝트마다 `android/gradle.properties`에 `kotlin.incremental=false`**(D:·C: 드라이브 문제, apps/SETUP.md). 사내망 PC에는 Flutter 3.50.0을 zip으로 설치함(`D:\dev\flutter`, 사용자 PATH). 거기서는 `flutter upgrade` 대신 새 zip으로 바꾼다. `flutter doctor`의 "Network resources ✗(github.com)"는 사내망 차단이라 무시. 사내망 PC에는 Android Studio(`D:\dev\android-studio`)·SDK 36(`D:\dev\android-sdk`, `ANDROID_HOME`)·가상 기기 `vocab_api36`도 있고 `flutter build apk` 됨. 단 **Gradle 배포 파일은 github.com으로 넘겨져 사내망에서 못 받는다** — 새 Gradle 버전이 필요하면 사내망 밖에서 받아 `~/.gradle/wrapper/dists/<이름>/<해시>/`에 넣는다(지금 9.5.0 넣어 둠). 에뮬레이터 실행은 WHPX를 켜야 함(지금 꺼짐)

## 파일

- [spec.md](spec.md) — 1단계 명세(deep-interview 원본 `.omc/specs/deep-interview-vocab.md` 복사)
- [options.md](options.md) — 2단계 후보 4개와 장단점, 3단계에서 고른 것(Flutter)과 이유
- [setup.md](setup.md) — vocab 개발 환경(패키지 `flutter_tts`·`sqflite`와 설정, 가상 기기, 확인 상태). 공통은 [../../SETUP.md](../../SETUP.md)
- [verify.md](verify.md) — 4단계 검증 기록(명령·기대값·함정·마지막 결과, PC별)

## 진행 이력

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
