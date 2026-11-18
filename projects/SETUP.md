# projects 공통 — 개발 환경

`projects/` 아래 **모든 프로젝트**에 해당하는 환경 내용만 둔다. 그룹 공통은 그룹 폴더(예: [apps/SETUP.md](apps/SETUP.md)), 그 프로젝트·앱에만 해당하는 것은 그 폴더에 둔다. 아래 층에서 쓰던 내용이 다른 프로젝트에도 해당하게 되면 이 파일로 옮기고 아래 층에는 링크만 남긴다.

망 제약(사내망 PC는 github.com 차단, npm·Maven 등은 열림)은 루트 [CLAUDE.md](../CLAUDE.md) "네트워크 제약"이 원본이다.

## github.com에서만 받을 수 있는 파일 (사내망 PC)

설치·빌드 중 다운로드가 github.com으로 넘어가 막히면(시간 초과, curl exit 28) 미러로 우회하지 않고 **사용자가 사내망 밖에서 받아 온다**(2026-11-18 사용자 결정).

1. 막힌 주소를 확인한다: `curl -sI <주소>` → `Location: https://github.com/...`
2. 공식 sha256을 찾는다 — 체크섬 파일은 github.com 밖에 있는 경우가 많다(예: Gradle은 `<주소>.sha256`)
3. 사용자에게 **파일 이름 · 원래 주소 · sha256 · 이 PC에 둘 경로**를 알려 준다
4. 받아 오면 `sha256sum`으로 대조한 뒤 쓴다

## Gradle 배포 파일 — 확인함 (2026-11-18 사내망 PC)

Gradle 래퍼(`gradlew`, Flutter 안드로이드 빌드 포함)는 `services.gradle.org/distributions/gradle-<버전>-<bin|all>.zip`을 받는데, 이 주소와 `downloads.gradle.org`가 **github.com으로 넘겨진다(307)**. 체크섬(`….zip.sha256`)은 사내망에서 받아진다.

받아 온 zip은 래퍼 캐시에 넣는다. 그러면 프로젝트 설정을 고치지 않아도 된다.

1. 필요한 버전: 프로젝트의 `gradle/wrapper/gradle-wrapper.properties`(Flutter는 `android/gradle/wrapper/`) `distributionUrl`
2. 캐시 폴더 이름은 `distributionUrl` 문자열의 MD5를 36진수로 바꾼 것:
   ```bash
   node -e 'const c=require("crypto");const d=c.createHash("md5").update(process.argv[1]).digest("hex");console.log(BigInt("0x"+d).toString(36))' "https://services.gradle.org/distributions/gradle-9.5.0-all.zip"
   # → aca6g93cdtcf0oapcfka748qh
   cp gradle-9.5.0-all.zip ~/.gradle/wrapper/dists/gradle-9.5.0-all/<위 값>/
   ```
3. 그 폴더에 실패한 빌드가 남긴 `.part`·`.lck`가 있으면 지운다

지금 사내망 PC 캐시에 있는 것: `gradle-9.5.0-all`(Flutter 3.50.0 템플릿 기본).

Maven(`repo.maven.apache.org`)·Google Maven·`plugins.gradle.org`는 사내망에서 열려 있어 의존성 다운로드는 막히지 않았다.

## Claude Code `!` 입력은 bash다

입력란의 `! <명령>`은 bash로 실행된다. PowerShell 문법(`$env:X = ...`, `D:\경로`)은 안 된다(2026-11-18 사내망 PC). bash로 쓰거나(`export X=...`, `/d/경로` 또는 `D:/경로`), PowerShell 명령은 Claude Code 바깥 PowerShell 창에서 실행한다. 키 입력이 필요한 명령(라이선스 `y` 등)은 `!` 안에서 응답할 수 없으므로 `yes |`를 붙인다.
