# vocab — 개발 환경 (앱별)

공통 환경(Flutter SDK·Android Studio·SDK·Gradle·함정)은 [../SETUP.md](../SETUP.md)를 먼저 따른다. 여기에는 **vocab에만 해당하는 것**만 둔다.

## 전제 (3단계 결정, [docs/options.md](docs/options.md))

- Flutter 3.50.0 stable · 안드로이드 먼저 · iOS 보류 · 모바일만
- 플랫폼 기능은 TTS만, 저장은 기기 안([docs/spec.md](docs/spec.md))
- 프로젝트: `flutter create --platforms=android,ios --org dev.cp --project-name vocab` → 패키지 `dev.cp.vocab` (2026-11-19). **2026-11-28 `kr.msjin.vocab`으로 바꿈**(Play 등록용 사용자 결정 — `android/app/build.gradle.kts`의 namespace·applicationId, `kotlin/kr/msjin/vocab/MainActivity.kt`)
- 앱 이름 `Vocara`(`AndroidManifest.xml` label + `lib/app_info.dart`), 아이콘 원본 `assets/icon/`(고친 뒤 `dart run flutter_launcher_icons`)
- **release 서명(개인 PC만)**: Play 업로드 키 `D:\dev\keys\vocab-upload.jks`(저장소 밖, alias `upload`, PKCS12) + `android/key.properties`(gitignore — `storeFile`·`keyAlias`·`storePassword`·`keyPassword`). 이 파일이 없는 PC에서는 release도 디버그 키로 서명된다. 키·비밀번호 백업은 사용자가 따로 한다. 키를 잃으면 Play Console에서 업로드 키 재설정을 요청한다

## 패키지

| 패키지 | 용도 | 추가 설정 | 상태 |
|---|---|---|---|
| `flutter_tts` | 영어 발음(TTS) — Android·iOS | Android: `minSdkVersion` 21 이상, `AndroidManifest.xml`에 `<queries><intent><action android:name="android.intent.action.TTS_SERVICE"/></intent></queries>` (pub.dev 문서) | manifest 설정 포함 빌드 확인함(2026-11-18 사내망, 4단계 시험용 프로젝트, 기본 minSdk 24). 에뮬레이터에서 영어 합성·오디오 출력 확인함(2026-11-19), 귀로 듣기는 **아직**(사무실). Kotlin 패키지라 아래 `kotlin.incremental=false` 필요, KGP 경고 있음(VERIFY.md "함정"). 앱 프로젝트에 manifest 설정 넣음(2026-11-19) |
| `sqflite` (+ `path`) | 기기 안 저장(학습 기록·오답 노트·진도) — Android·iOS | 없음 | 빌드 확인함(같은 날). 에뮬레이터에서 쓰기 → 앱 강제 종료·재실행 뒤 남아 있음 확인(2026-11-19) |
| `shared_preferences` | 작은 설정 값(고른 학교급) — Android·iOS, Flutter 팀 공식 | 없음(`SharedPreferencesAsync` 사용) | 2026-11-20 추가, 에뮬레이터에서 재실행 후 유지 확인 |
| `sqflite_common_ffi` (dev) | PC 시험에서 실제 sqflite 코드를 돌림 | 없음 — Windows에서 별도 sqlite 설치 없이 동작(2026-11-20 개인 PC) | 시험 전용, 앱에는 안 들어감 |

```bash
flutter pub add flutter_tts sqflite path shared_preferences
flutter pub add --dev sqflite_common_ffi
```

`android/gradle.properties`에 `kotlin.incremental=false` — 프로젝트(D:)와 pub 캐시(C:)가 다른 드라이브라서. 이유는 [apps/SETUP.md](../SETUP.md) "함정". 앱 프로젝트에 넣음(2026-11-19)

## 가상 기기

- `vocab_api36` — pixel_7, `system-images;android-36;google_apis;x86_64`. 만들기는 공통 SETUP.md 4번
- 이 이미지에 Google TTS 엔진(`com.google.android.tts`)이 들어 있고, 영어(en-US) 음성이 내장돼 있다 — 추가 설치 없이 `flutter_tts`가 합성함(2026-11-19 확인)
- 사내망 PC에서는 `-gpu swiftshader_indirect`로 띄운다(apps/SETUP.md "함정")

## 확인 상태

| 항목 | 사내망 PC (2026-11-18~19) | 개인 PC |
|---|---|---|
| 앱 프로젝트 `projects/apps/vocab` analyze·test·build apk | exit 0 (2026-11-19) | exit 0 (2026-11-20) |
| 패키지 추가 + `flutter analyze`·`flutter test` | exit 0 (4단계 시험용 프로젝트 `D:\dev\tmp\vocab_probe`) | 앱 프로젝트로 확인(위 줄) |
| `flutter build apk --debug` | exit 0 (`kotlin.incremental=false` 뒤) | exit 0, 391초 |
| 가상 기기 실행 · 화면 · 저장 유지 | 확인함(2026-11-19, WHPX 켠 뒤) | 확인함(2026-11-20, 기본 그래픽) |
| TTS 소리 | 합성·오디오 출력은 확인함, 귀로 듣기는 확인 못 함(사무실) | 귀로 확인함(2026-11-20) — 에뮬레이터 미디어 볼륨을 15로 올려서 |
| iOS | 보류 | 보류 |

검증 기록은 [VERIFY.md](VERIFY.md)에 둔다. 이 파일은 "무엇을 어떻게 설치·설정하나", VERIFY.md는 "실제로 돌려 본 결과"다.
