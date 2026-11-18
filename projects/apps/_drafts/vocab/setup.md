# vocab — 개발 환경 (주제별)

공통 환경(Flutter SDK·Android Studio·SDK·Gradle·함정)은 [../../SETUP.md](../../SETUP.md)를 먼저 따른다. 여기에는 **vocab에만 해당하는 것**만 둔다. 5단계에서 앱 폴더의 `SETUP.md`로 옮긴다.

## 전제 (3단계 결정, [options.md](options.md))

- Flutter 3.50.0 stable · 안드로이드 먼저 · iOS 보류 · 모바일만
- 플랫폼 기능은 TTS만, 저장은 기기 안([spec.md](spec.md))

## 패키지

| 패키지 | 용도 | 추가 설정 | 상태 |
|---|---|---|---|
| `flutter_tts` | 영어 발음(TTS) — Android·iOS | Android: `minSdkVersion` 21 이상, `AndroidManifest.xml`에 `<queries><intent><action android:name="android.intent.action.TTS_SERVICE"/></intent></queries>` (pub.dev 문서) | 추가·빌드 확인함(2026-11-18 사내망, 임시 프로젝트). manifest 설정·실제 발음은 **아직** |
| `sqflite` | 기기 안 저장(학습 기록·오답 노트·진도) — Android·iOS | 없음 | 추가·빌드 확인함(같은 날). 실제 읽기·쓰기는 **아직** |

```bash
flutter pub add flutter_tts sqflite
```

## 가상 기기

- `vocab_api36` — pixel_7, `system-images;android-36;google_apis;x86_64`. 만들기는 공통 SETUP.md 4번
- TTS 소리를 들으려면 Google APIs 이미지(지금 것)에서 기기 설정의 TTS 엔진이 있어야 한다(추정 — 실행 때 확인)

## 확인 상태

| 항목 | 사내망 PC (2026-11-18) | 개인 PC |
|---|---|---|
| 패키지 추가 + `flutter analyze`·`flutter test` | exit 0 (임시 프로젝트) | 아직 |
| `flutter build apk --debug` | exit 0 (임시 프로젝트, 첫 빌드 약 29.5분) | 아직 |
| 가상 기기 실행 · TTS 소리 | 확인 못 함(WHPX 꺼짐) | 아직 — 4단계 |
| iOS | 보류 | 보류 |

4단계 검증 기록은 [verify.md](verify.md)(아직 없음)에 둔다. 이 파일은 "무엇을 어떻게 설치·설정하나", verify.md는 "실제로 돌려 본 결과"다.
