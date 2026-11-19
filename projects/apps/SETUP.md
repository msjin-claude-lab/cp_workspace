# 앱 개발 환경 구성 가이드 (Flutter · Android)

`projects/apps/` 아래 모든 앱이 쓰는 **공통** 개발 환경이다. 앱이 아닌 프로젝트까지 해당하는 내용(github.com 파일, Gradle, `!` 입력)은 한 층 위 [projects/SETUP.md](../SETUP.md)에 있다. 앱(주제)마다 다른 것 — 패키지, 패키지별 설정, 가상 기기, 확인 상태 — 은 주제 폴더의 `setup.md`(완성된 앱은 앱 폴더 `SETUP.md`)에 둔다. 예: [vocab/SETUP.md](vocab/SETUP.md). 여러 앱에 해당하게 된 항목은 이 파일로 옮긴다(VERIFY.md와 같은 방식).

도구 선택 근거는 [vocab/docs/options.md](vocab/docs/options.md) "3단계" — Flutter, 안드로이드 먼저, iOS 보류.

- **기준 PC**: 사내망 PC(Windows 11)에서 2026-11-18에 실제로 설치·확인했다. "확인함"이 붙은 것만 실제로 실행한 것이다
- **개인 PC**: 아직 이 순서로 설치하지 않았다. github.com이 열려 있으므로 "사내망만" 표시된 우회는 필요 없을 것(추정)
- **iOS**: 보류. Mac(무료 Apple ID) 또는 유료 Apple Developer Program이 필요하다([options.md](vocab/docs/options.md) "먼저 알아 둘 것")

## 설치 결과 (사내망 PC, 2026-11-18)

| 구성 요소 | 버전 | 위치 |
|---|---|---|
| Flutter SDK | 3.50.0 stable (Dart 3.14.0) | `D:\dev\flutter` — 사용자 PATH에 `D:\dev\flutter\bin` |
| Android Studio | Rabbit 2 Patch 1 (2026.2.2.9), zip판 | `D:\dev\android-studio` — Java는 안의 `jbr` 사용 |
| Android SDK | platform-tools, emulator, platforms;android-36, build-tools;36.1.0(+빌드가 자동 설치한 36.0.0, ndk), system-images;android-36;google_apis;x86_64 | `D:\dev\android-sdk` — 사용자 환경 변수 `ANDROID_HOME` |
| 가상 기기 | `vocab_api36` (pixel_7, Android 36) | `~/.android/avd` |
| Gradle | 9.5.0-all (Flutter 3.50.0 템플릿 기본) | `~/.gradle/wrapper/dists/gradle-9.5.0-all/aca6g93cdtcf0oapcfka748qh/` |

경로는 짧게 둔다(Windows 경로 260자). 관리자 권한이 필요 없도록 설치 프로그램 대신 zip을 푼다.

## 순서

모든 내려받은 파일은 공식 sha256과 대조한 뒤 푼다. bash 예시는 Claude Code의 Bash(또는 Git Bash) 기준이다.

### 1. Flutter SDK — 확인함

1. 최신 stable 정보: `https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json`의 `current_release.stable` → 해당 항목의 `archive`·`sha256`
2. 받기: `https://storage.googleapis.com/flutter_infra_release/releases/<archive>` (약 1.9GB)
3. 풀기: `tar -xf flutter_windows_<버전>-stable.zip -C D:\dev` (Windows 기본 `tar`, 약 3.3GB)
4. 사용자 PATH에 `D:\dev\flutter\bin` 추가 → **새 터미널부터** 적용
5. 확인: `flutter --version`, `flutter doctor`

사내망만: `flutter upgrade`·채널 변경은 github.com이 필요해 안 된다. 버전을 올릴 때는 새 zip으로 바꾼다.

### 2. Android Studio + command-line tools — 확인함

1. https://developer.android.com/studio 의 "Command line tools only"·"Android Studio (zip)" 표에서 파일 이름과 SHA-256 확인
2. Studio zip → `D:\dev`에 풀기 (`D:\dev\android-studio`)
3. command-line tools zip → 안의 `cmdline-tools` 폴더를 `D:\dev\android-sdk\cmdline-tools\latest`로 옮긴다(`latest` 이름이 필요)
4. 환경: 사용자 환경 변수 `ANDROID_HOME=D:\dev\android-sdk`, 그리고
   `flutter config --android-sdk D:\dev\android-sdk --android-studio-dir D:\dev\android-studio`

### 3. SDK 라이선스 동의 + 패키지 설치 — 확인함

라이선스는 **사용자가 직접** 동의한다. 동의와 설치를 한 명령으로 해야 다시 막히지 않는다(아래 "함정").

```bash
export JAVA_HOME=D:/dev/android-studio/jbr
yes | /d/dev/android-sdk/cmdline-tools/latest/bin/sdkmanager.bat --sdk_root=D:/dev/android-sdk \
  "platform-tools" "emulator" "platforms;android-36" "build-tools;36.1.0" \
  "system-images;android-36;google_apis;x86_64"
```

설치할 최신 버전은 `sdkmanager.bat --list`로 고른다.

### 4. 가상 기기 — 확인함(실행은 2026-11-19)

```bash
echo no | /d/dev/android-sdk/cmdline-tools/latest/bin/avdmanager.bat create avd \
  -n vocab_api36 -k "system-images;android-36;google_apis;x86_64" -d pixel_7
flutter emulators            # vocab_api36이 보이면 됨
```

실행하려면 **Windows 하이퍼바이저 플랫폼(WHPX)**이 켜져 있어야 한다. 관리자 PowerShell에서 켜고 **"다시 시작"으로** 재부팅한다(아래 "함정" — 시스템 종료 후 켜기는 재부팅이 아니다). 사내망 PC는 2026-11-19에 켬.

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform
```

확인: `(Get-CimInstance Win32_ComputerSystem).HypervisorPresent`가 `True`, `D:\dev\android-sdk\emulator\emulator.exe -accel-check`가 "WHPX(…) is installed and usable".

실행(사내망 PC는 소프트웨어 그래픽으로 — 아래 "함정"):

```bash
/d/dev/android-sdk/emulator/emulator.exe -avd vocab_api36 -gpu swiftshader_indirect   # 첫 부팅 약 4~13분
```

**Play 스토어용 가상 기기 `play_api36`**(사내망 PC, 2026-11-19, 일반 APK·스토어 앱 시험용 — 앱 개발은 `vocab_api36`): 이미지 `system-images;android-36;google_apis_playstore;x86_64`, `avdmanager create avd -n play_api36 … -d pixel_7`. avdmanager로 만들면 `config.ini`에 `PlayStore.enabled=no`로 들어가 **`yes`로 고쳐야 한다**. 같은 파일에 `hw.gpu.enabled=yes`, `hw.gpu.mode=swiftshader_indirect`도 넣어 둠(Android Studio에서 켜도 화면이 멈추지 않게, 확인 안 함). 바탕화면 바로가기 "Android 에뮬레이터 (Play)" = `emulator.exe -avd play_api36 -gpu swiftshader_indirect` — 더블클릭으로 부팅 466초, 홈 화면에 Play Store 확인. 스토어 로그인·사내망 접속은 확인 안 함

화면 캡처는 `adb exec-out screencap`이 검은 화면만 줄 때가 있다 — `adb emu screenrecord screenshot <절대경로.png>`(에뮬레이터 쪽 캡처)를 쓴다.

### 5. Gradle — 사내망만, 확인함

Gradle 배포 파일은 github.com으로 넘겨져 사내망에서 못 받는다 — 받아 오는 법과 래퍼 캐시에 넣는 법은 모든 Gradle 프로젝트 공통이라 [projects/SETUP.md](../SETUP.md) "Gradle 배포 파일"에 있다. Flutter에서 필요한 버전은 `android/gradle/wrapper/gradle-wrapper.properties`의 `distributionUrl`(Flutter 3.50.0 템플릿은 `gradle-9.5.0-all`, 사내망 PC 캐시에 넣어 둠)

## 확인 (새 PC나 업데이트 뒤)

| 명령 | 기대 | 2026-11-18 사내망 |
|---|---|---|
| `flutter doctor` | Flutter ✓, Android toolchain ✓ | ✓ (Visual Studio ✗는 Windows 앱용이라 무시, Network ✗는 사내망 github.com 차단) |
| 빈 프로젝트 `flutter create --platforms=android,ios <이름>` | exit 0 | exit 0 |
| `flutter pub add flutter_tts sqflite` | exit 0 (pub.dev) | exit 0 |
| `flutter analyze` | No issues | exit 0 |
| `flutter test` | All tests passed | exit 0 |
| `flutter build apk --debug` | exit 0 + `build/app/outputs/flutter-apk/app-debug.apk` 새로 생김 | exit 0, 첫 빌드 약 29.5분 |
| `emulator -avd vocab_api36 -gpu swiftshader_indirect` | 가상 폰이 뜸 | 2026-11-19 뜸(부팅 266초), 기본 그래픽은 화면 멈춤 |

## 함정 (실제로 겪은 것, 2026-11-18 사내망 PC)

- 모든 프로젝트 공통 함정(github.com 리다이렉트, Gradle 배포 파일, `!` 입력은 bash)은 [projects/SETUP.md](../SETUP.md)
- **`flutter doctor --android-licenses`가 "Unable to locate Android SDK"** — SDK 폴더에 `platform-tools`가 없으면 Flutter가 SDK로 인식하지 않는다(추정). `sdkmanager --licenses`나 위 3번처럼 동의한다
- **라이선스를 따로 동의해도 설치 때 다시 묻는다** — `--licenses`로 동의한 뒤 `yes` 없이 설치했더니 "licenses … were not accepted"로 아무것도 설치되지 않았다(exit 0인데도). 동의와 설치를 한 명령으로
- **`avdmanager`의 `devices.xml` 오류** — "Could not load devices from …devices.xml"이 떠도 기기는 정상 생성됐다(`flutter emulators`로 확인)
- **첫 `flutter build apk`는 오래 걸린다**(약 29.5분) — Maven 의존성과 build-tools 36.0.0·NDK를 자동으로 받는다. 백그라운드로 돌린다
- `sdkmanager`가 "deprecated, Android CLI(`android sdk`)를 쓰라"는 경고를 낸다 — 이번에는 그대로 동작했다
- **프로젝트가 D:, pub 캐시가 C:면 Kotlin 플러그인 빌드가 실패한다** — `flutter_tts`처럼 Kotlin 코드가 있는 패키지에서 `:<패키지>:compileDebugKotlin`이 "Could not close incremental caches"로 실패(vocab 4단계). **새 Flutter 앱마다 `android/gradle.properties`에 `kotlin.incremental=false`를 넣는다**(넣은 뒤 빌드 exit 0). 원인은 드라이브가 다른 경로를 Kotlin 증분 캐시가 다루지 못하는 것으로 추정 — C: 드라이브 프로젝트는 이 설정 없이 성공했다. `projects/apps/`가 D:에 있으므로 모든 앱에 해당
- **WHPX를 켠 뒤 "시스템 종료 → 켜기"로는 적용되지 않는다**(2026-11-19) — Windows "빠른 시작"이 켜져 있으면 시스템 종료는 최대 절전에 가까워 실제 부팅이 아니다(마지막 부팅 시각 `(Get-CimInstance Win32_OperatingSystem).LastBootUpTime`이 그대로). **시작 → 전원 → 다시 시작**으로 한다
- **기본 그래픽 모드면 에뮬레이터 화면이 멈춘다**(2026-11-19 사내망 PC) — 로그에 "unsupported Vulkan API level (1.3.235, min required: 1.3.240, Intel Iris Xe)". 앱은 실행 중인데 화면이 갱신되지 않았다. `-gpu swiftshader_indirect`(소프트웨어 그래픽)로 띄우자 정상. 그래픽 드라이버를 올리면 필요 없을 수 있음(확인 안 함)
- **사내망 PC에서 에뮬레이터는 실용적이지 않다**(2026-11-19 사용자 판단) — 소프트웨어 그래픽이라 매우 느리고 "응답 없음" 창이 계속 뜬다. 부팅 후에도 부하(load 40 안팎)가 오래가 앱 화면이 몇 분씩 안 뜨거나 검은 화면이 된다. 이 PC에서는 analyze·test·build로 확인하고 화면을 눌러 보는 확인은 개인 PC에서 한다. 개선 후보(확인 안 함): 해상도 낮은 기기, 가벼운 이미지(API 34), Intel 그래픽 드라이버 업데이트
- **첫 부팅 직후 "System UI isn't responding" 창이 여러 번 뜬다** — 부팅 직후 부하 때문(load 40 안팎). "Wait"를 누르고 부하가 내려갈 때까지 기다린다. `adb shell settings put global hide_error_dialogs 1`로 숨길 수 있다(시험용)
- **에뮬레이터를 띄운 채 `flutter run`의 첫 빌드는 매우 느리다**(약 25분, Kotlin 데몬 연결 실패 후 대체 방식) — 에뮬레이터가 CPU를 많이 쓴다. 빌드(`flutter build apk`)를 먼저 하고 에뮬레이터를 띄우는 편이 낫다(추정)

## 정리할 것

- 내려받은 zip(Flutter·Studio·command-line tools)은 풀고 나서 지웠다. 사용자가 받아 온 `C:\Users\M\Downloads\gradle-9.5.0-all.zip`은 캐시에 복사해 두었으므로 지워도 된다
