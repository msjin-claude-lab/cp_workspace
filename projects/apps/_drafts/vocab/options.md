# vocab — 2단계 선택안 (언어·플랫폼 후보)

2026-11-18 사내망 PC · `/oh-my-claudecode:research`. 공식 문서를 읽고 "확인(문서)"과 "추정"을 나눴다. 앱 요구는 [spec.md](spec.md): 오프라인 단어 450개, 카드·4지선다·오답 노트·진도, 기기 안 저장, 플랫폼 기능은 TTS만.

## 먼저 알아 둘 것 — 모든 후보 공통

- **iOS를 Windows PC만으로 로컬 빌드하는 방법은 없다.** 어느 후보든 Mac(Xcode) 또는 클라우드 macOS 빌드가 필요하다 (확인(문서): 각 후보 아래)
- **실제 아이폰 설치에는 서명이 필요하다.** Mac 없이 가는 길(EAS 클라우드 빌드, Codemagic, MAUI Hot Restart)은 모두 **유료 Apple Developer Program(연 $99)**을 요구한다. 무료 Apple ID는 Mac의 Xcode에서 직접 설치할 때만(Flutter 문서) — 3단계 전에 정할 것
- iOS 시뮬레이터는 Windows에서 불가 (확인(문서): Expo 환경 설정 문서)
- 안드로이드는 네 후보 모두 Windows에서 빌드·에뮬레이터 가능
- 사내망 PC(github.com 차단)에서 실제 설치가 되는지는 **아무 후보도 시험하지 않았다** — 고른 뒤 첫 설치로 확인

## 후보 1 — React Native + Expo (TypeScript)

- iOS: 로컬 빌드는 Mac 필요. **EAS 클라우드 빌드는 Windows에서 가능** — 네 후보 중 유일하게 Mac 없이 iOS 빌드 경로가 문서화됨. 무료 등급은 월 빌드 수 제한(저우선순위). Expo Go로 아이폰 시험도 이제 유료 Apple 계정 + TestFlight 필요 (확인(문서): docs.expo.dev create-a-build, expo-go, billing/plans)
- TTS: `expo-speech` — Android·iOS·Web, Expo Go 포함. Android는 pause/resume 없음, iOS는 무음 모드에서 소리 안 남 (확인(문서): docs.expo.dev sdk/speech)
- 저장소: `expo-sqlite` — Expo Go 포함, 단어 DB를 앱에 넣어 배포 가능(`assetSource`) (확인(문서): sdk/sqlite). AsyncStorage(추정)
- github.com: 설치는 npm(`npx create-expo-app`, `eas-cli`). 템플릿 출처가 npm인지 GitHub인지 문서에 없음 (추정 — 사내망에서 시험 필요)
- Windows 설정: Node 설치 → `npx create-expo-app` → 안드로이드 에뮬레이터. 배우기: JS/TS를 알면 쉬움 (추정)
- 장점: Mac 없이 iOS까지 가는 길이 가장 분명. TTS·저장소가 공식 모듈로 다 있음. npm이 사내망에서 열려 있음
- 단점: 아이폰 시험·배포에 유료 Apple 계정 필수, 무료 클라우드 빌드 수 제한

## 후보 2 — Flutter (Dart)

- iOS: Mac + Xcode 필요, Windows 대안은 문서에 없음 (확인(문서): docs.flutter.dev platform-integration/ios/setup). 클라우드는 Codemagic이 macOS에서 iOS 빌드, 서명에 유료 Apple 계정 필요 (확인(문서): docs.codemagic.io)
- TTS: `flutter_tts` 4.2.5 — Android·iOS 지원, Android minSdk 21 + manifest `TTS_SERVICE` queries (확인(문서): pub.dev)
- 저장소: `sqflite` — Android·iOS (확인(문서): Flutter cookbook). 450개면 JSON 자산으로도 충분 (추정)
- github.com: Windows 수동 설치는 zip 압축 해제 (확인(문서)). 그러나 SDK가 git 저장소라 `flutter upgrade`·채널 변경은 github.com이 필요할 것 (추정) — **사내망 PC에서는 버전 고정 zip으로만**. zip 호스트(storage.googleapis.com 추정)는 확인 못 함
- Windows 설정: Git + SDK zip(또는 VS Code 확장) → Android Studio → `flutter doctor`. 배우기: Dart는 새 언어지만 문서가 좋음 (추정)
- 장점: 생태계·문서 큼, 화면이 양쪽에서 같게 그려짐
- 단점: Mac 없는 iOS는 Codemagic 같은 외부 서비스 의존. 사내망 PC의 SDK 업그레이드 제약

## 후보 3 — Kotlin Multiplatform + Compose Multiplatform (Kotlin)

- iOS: "iOS 앱을 만들려면 Xcode가 설치된 macOS 필요" (확인(문서): kotlinlang.org quickstart). 클라우드 macOS CI(추정, GitHub Actions는 사내망에서 못 씀)
- TTS: 공식 멀티플랫폼 라이브러리 없음 — Android `TextToSpeech` + iOS `AVSpeechSynthesizer`를 expect/actual로 직접 작성 (추정)
- 저장소: SQLDelight 2.4.0 — Android·iOS (확인(문서)). Room KMP는 iOS에서 미리 넣은 DB 불가, 버전이 알파 (확인(문서))
- github.com: Gradle·Maven Central·Google Maven(열려 있음). Kotlin/Native 도구 호스트는 확인 못 함 (추정)
- 성숙도: Compose Multiplatform iOS 1.8.0(2025-05) 안정판 (확인(문서): JetBrains 블로그)
- 장점: Maven 생태계라 사내망과 잘 맞음, 안드로이드는 네이티브 수준
- 단점: **Windows에서 iOS 쪽은 빌드도 시험도 못 함**, TTS를 직접 작성

## 후보 4 — .NET MAUI (C#)

- iOS: Mac 필요(Pair to Mac). Hot Restart로 Mac 없이 USB 아이폰에 디버그 설치 가능하나 유료 Apple 계정 필요, 릴리스 빌드 불가, **Visual Studio 2026에서 미지원** (확인(문서): learn.microsoft.com maui/ios/hot-restart, pair-to-mac)
- TTS: MAUI Essentials `TextToSpeech` 내장 — Android·iOS (확인(문서))
- 저장소: `sqlite-net-pcl`, 미리 넣은 DB 복사 방법 문서화 (확인(문서))
- github.com: `dotnet workload install maui`는 NuGet(nuget.org) — github.com 의존 없음 (확인(문서), 실제 설치는 안 해 봄)
- 장점: TTS가 기본 포함, 설치 경로에 github.com 없음
- 단점: Windows→iOS 경로가 줄어드는 중(Hot Restart가 VS 2026 미지원). Visual Studio 설치가 무거움

## 비교 한 줄

- Mac 없이 iOS까지: **Expo(EAS)** > Flutter(Codemagic) > MAUI(Hot Restart, 줄어드는 중) > KMP(불가)
- TTS 준비: Expo·Flutter·MAUI는 패키지, KMP는 직접 작성
- 사내망 설치: MAUI·KMP가 문서상 github.com과 무관, Expo는 npm(템플릿 출처 미확인), Flutter는 zip 고정 필요

## 3단계 — 고른 것과 이유

2026-11-18 사내망 PC · **Flutter**

- 전제(사용자 결정): **비용은 무료 위주**, **안드로이드 먼저 · iOS는 보류**(유료 Apple 계정·Mac은 나중에 정함), **모바일 앱만**, 앞으로 **게임 앱(고정 화면·횡스크롤 2D)**도 만듦, 개발은 **AI로**
- 이유:
  - vocab 자체는 어느 후보로도 충분하다(목록·카드·퀴즈·로컬 DB·TTS). 선택은 다음 앱까지 보고 정했다
  - 2D 게임을 같은 도구로 이어 갈 수 있다 — Flutter 게임 엔진 Flame(카메라·패럴랙스·타일맵·충돌, 물리는 `flame_forge2d`) (추정, 게임 주제 2단계에서 확인)
  - AI 개발의 검증 고리가 SDK에 다 있다 — `flutter analyze`·`flutter test`(에뮬레이터 없이 위젯 테스트)·`flutter doctor`. AI가 코드를 쓰므로 Dart를 새로 배우는 부담은 작다
  - 사용 추세 1위(크로스플랫폼 개발자 약 46%, 업체 블로그 인용 수치라 대략)
  - 카드 뒤집기 같은 애니메이션을 추가 패키지 없이 만들고, 양쪽 화면이 똑같이 그려진다
  - 앱마다 같은 도구를 쓰면 SDK 설치·검증 명령·함정 기록(그룹 VERIFY.md)을 한 번만 쌓는다
- 고르지 않은 것:
  - Expo — 2위, vocab엔 충분하지만 게임 생태계가 약하고 버전 변화가 잦음
  - KMP·.NET MAUI — 모바일만 만들면 이점이 없고, Windows에서 iOS 길이 더 막힘
- 감수할 것:
  - 사내망 PC는 SDK를 버전 고정 zip으로만 쓴다(`flutter upgrade`가 github.com에 걸릴 것으로 추정). 사내망 PC는 원래 코드 수정만 하므로 영향이 작다
  - iOS는 Mac(무료 Apple ID, 7일 재설치) 또는 유료 Apple 계정 + Codemagic이 생길 때까지 "확인 못 함" — **잠정 보류, 추후 지시까지 안드로이드만으로 5단계까지 진행**(2026-11-18 사용자 결정)
