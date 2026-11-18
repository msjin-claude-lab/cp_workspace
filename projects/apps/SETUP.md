# 앱 개발 환경 구성 가이드 (Flutter · Android)

`projects/apps/` 아래 모든 앱이 쓰는 개발 환경이다. 도구 선택 근거는 [_drafts/vocab/options.md](_drafts/vocab/options.md) "3단계" — Flutter, 안드로이드 먼저, iOS 보류.

- **기준 PC**: 사내망 PC(Windows 11)에서 2026-11-18에 실제로 설치·확인했다. "확인함"이 붙은 것만 실제로 실행한 것이다
- **개인 PC**: 아직 이 순서로 설치하지 않았다. github.com이 열려 있으므로 "사내망만" 표시된 우회는 필요 없을 것(추정)
- **iOS**: 보류. Mac(무료 Apple ID) 또는 유료 Apple Developer Program이 필요하다([options.md](_drafts/vocab/options.md) "먼저 알아 둘 것")

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

### 4. 가상 기기 — 만들기 확인함, 실행은 확인 못 함

```bash
echo no | /d/dev/android-sdk/cmdline-tools/latest/bin/avdmanager.bat create avd \
  -n vocab_api36 -k "system-images;android-36;google_apis;x86_64" -d pixel_7
flutter emulators            # vocab_api36이 보이면 됨
```

실행하려면 **Windows 하이퍼바이저 플랫폼(WHPX)**이 켜져 있어야 한다. 사내망 PC는 꺼져 있다(BIOS 가상화는 켜짐). 관리자 PowerShell에서 켜고 재부팅한다(회사 정책으로 막힐 수 있음). 그 뒤 `flutter emulators --launch vocab_api36` — **아직 확인 못 함**.

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform
```

### 5. Gradle — 사내망만, 확인함

Flutter의 안드로이드 빌드는 Gradle 래퍼가 `services.gradle.org/distributions/gradle-<버전>-all.zip`을 받는데, 이 주소가 **github.com으로 넘겨진다(307)** → 사내망에서 막힌다.

1. 필요한 버전: 프로젝트의 `android/gradle/wrapper/gradle-wrapper.properties` `distributionUrl`
2. 공식 sha256: `https://services.gradle.org/distributions/gradle-<버전>-all.zip.sha256` (이건 사내망에서 받아진다)
3. zip은 **사내망 밖에서** 받아 온다
4. 래퍼 캐시에 넣는다 — 폴더 이름은 `distributionUrl` 문자열의 MD5를 36진수로 바꾼 것:
   ```bash
   node -e 'const c=require("crypto");const d=c.createHash("md5").update("https://services.gradle.org/distributions/gradle-9.5.0-all.zip").digest("hex");console.log(BigInt("0x"+d).toString(36))'
   # → aca6g93cdtcf0oapcfka748qh
   cp gradle-9.5.0-all.zip ~/.gradle/wrapper/dists/gradle-9.5.0-all/<위 값>/
   ```
   그 폴더에 실패한 빌드가 남긴 `.part`·`.lck`가 있으면 지운다. 이렇게 하면 프로젝트마다 설정을 고치지 않아도 된다

## 확인 (새 PC나 업데이트 뒤)

| 명령 | 기대 | 2026-11-18 사내망 |
|---|---|---|
| `flutter doctor` | Flutter ✓, Android toolchain ✓ | ✓ (Visual Studio ✗는 Windows 앱용이라 무시, Network ✗는 사내망 github.com 차단) |
| 빈 프로젝트 `flutter create --platforms=android,ios <이름>` | exit 0 | exit 0 |
| `flutter pub add flutter_tts sqflite` | exit 0 (pub.dev) | exit 0 |
| `flutter analyze` | No issues | exit 0 |
| `flutter test` | All tests passed | exit 0 |
| `flutter build apk --debug` | exit 0 + `build/app/outputs/flutter-apk/app-debug.apk` 새로 생김 | exit 0, 첫 빌드 약 29.5분 |
| `flutter emulators --launch vocab_api36` | 가상 폰이 뜸 | 확인 못 함(WHPX 꺼짐) |

## 함정 (실제로 겪은 것, 2026-11-18 사내망 PC)

- **Gradle 배포 파일이 github.com으로 리다이렉트** → 위 5번. `downloads.gradle.org`도 같다
- **`flutter doctor --android-licenses`가 "Unable to locate Android SDK"** — SDK 폴더에 `platform-tools`가 없으면 Flutter가 SDK로 인식하지 않는다(추정). `sdkmanager --licenses`나 위 3번처럼 동의한다
- **라이선스를 따로 동의해도 설치 때 다시 묻는다** — `--licenses`로 동의한 뒤 `yes` 없이 설치했더니 "licenses … were not accepted"로 아무것도 설치되지 않았다(exit 0인데도). 동의와 설치를 한 명령으로
- **Claude Code의 `!` 입력은 bash다** — PowerShell 문법(`$env:`, 백슬래시 경로)은 안 된다. PowerShell 명령은 바깥 PowerShell 창에서
- **`avdmanager`의 `devices.xml` 오류** — "Could not load devices from …devices.xml"이 떠도 기기는 정상 생성됐다(`flutter emulators`로 확인)
- **첫 `flutter build apk`는 오래 걸린다**(약 29.5분) — Maven 의존성과 build-tools 36.0.0·NDK를 자동으로 받는다. 백그라운드로 돌린다
- `sdkmanager`가 "deprecated, Android CLI(`android sdk`)를 쓰라"는 경고를 낸다 — 이번에는 그대로 동작했다

## 정리할 것

- 내려받은 zip(Flutter·Studio·command-line tools)은 풀고 나서 지웠다. 사용자가 받아 온 `C:\Users\M\Downloads\gradle-9.5.0-all.zip`은 캐시에 복사해 두었으므로 지워도 된다
