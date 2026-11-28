/// 앱 제목과 버전. ☰ 메뉴 맨 위에 `Vocara v1.0.0`처럼 보인다(2026-11-20 사용자 결정,
/// 이름은 2026-11-28 사용자 결정 — `AndroidManifest.xml`의 `android:label`과 같게 둔다).
///
/// 버전은 `pubspec.yaml`의 `version:`(빌드 번호 `+N` 앞부분)과 같아야 한다 —
/// 올릴 때 두 곳을 함께 고친다. 어긋나면 `test/app_info_test.dart`가 잡는다.
const String appTitle = 'Vocara';
const String appVersion = '1.0.0';
