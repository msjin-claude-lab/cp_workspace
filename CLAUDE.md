# cp-workspace

모든 프로젝트의 **공통 뼈대**다. 여기에는 프로젝트 전부가 공유하는 환경 사실과 규칙만 둔다.
개별 프로젝트는 `projects/<name>/` 아래에 두고, 그 프로젝트에만 해당하는 규칙은 거기의 `CLAUDE.md`에 쓴다.

```
cp-workspace/
├── CLAUDE.md            ← 이 파일. 모든 프로젝트가 공유하는 규칙
├── .omc-workspace       ← OMC 상태 루트 앵커
├── .claude/CLAUDE.md    ← OMC 코디네이터 관리 영역. 손대지 말 것
└── projects/
    └── loan/            ← 개별 프로젝트
```

`.omc-workspace` 마커 때문에 `projects/` 아래 프로젝트가 **자체 git 저장소**가 되더라도 OMC 상태(`.omc/`)는 여기 하나로 모인다. 프로젝트마다 상태가 흩어지지 않는다.

## 네트워크 제약

PC에 따라 다르다. **사내망 PC에서는 `github.com`이 차단**되고, 개인 PC에서는 열려 있다. 패키지 레지스트리는 양쪽 모두 열려 있다 (2026-11-11 실측).

| 호스트 | 사내망 PC | 개인 PC |
|---|---|---|
| `github.com` | 차단 | 가용 |
| `222.112.172.253:9080` (개인 Gitea) | 가용 — git clone·fetch·push 정상 (2026-11-12 실측) | 가용 |
| `registry.npmjs.org` | 가용 | 가용 |
| `repo.maven.apache.org` | 가용 | 가용 |

따라서 npm·Maven 의존성은 자유롭게 추가해도 된다. 사내망 PC에서 GitHub에서 받아오는 것만 안 된다.

### 사용할 수 없는 스킬

`gh` CLI 미설치 + (사내망) GitHub 차단이라 아래는 이 워크스페이스에서 동작하지 않는다. 시도하지 말 것:

`/pr` · `/babysit` · `/fix-ci` · `/get-pr-comments` · `/review`(GitHub PR용 — 작업 중인 diff 리뷰는 `/omc-review`를 쓴다)

## git

원격 저장소는 두 곳이다. 기본 브랜치는 원격 모두 `main`이다.

| 원격 | 주소 | 용도 |
|---|---|---|
| 개인 Gitea | `http://222.112.172.253:9080/msjin-claude-lab/cp_workspace.git` | **기준 저장소.** 사내망·개인 PC 모두 접근 가능 |
| GitHub | `https://github.com/msjin-claude-lab/cp_workspace.git` | **읽기 전용 사본.** Gitea 푸시 미러가 자동으로 맞춘다 |

**모든 PC는 Gitea 하나에만 push한다.** Gitea에 push가 들어오면 푸시 미러가 GitHub로 자동 복사한다(Gitea 저장소 설정 → 미러 설정, 커밋 푸시 시 동기화 + 8시간 주기).

**GitHub에 직접 push하지 않는다.** 푸시 미러는 GitHub를 Gitea와 똑같이 덮어쓰므로, GitHub에만 있는 커밋은 다음 동기화 때 사라진다.

PC별 원격 구성:

- **사내망 PC** — `origin` = Gitea 하나만 둔다. GitHub 원격은 두지 않는다(차단돼 있다).
- **개인 PC** — `origin` = Gitea. GitHub는 미러 확인용 `github` 원격으로 두되 push 주소를 막아 둔다.

```bash
# 개인 PC 설정
git remote add origin http://222.112.172.253:9080/msjin-claude-lab/cp_workspace.git
git remote add github https://github.com/msjin-claude-lab/cp_workspace.git
git remote set-url --push github DISABLED-gitea-mirror-only
```

미러가 멈추면(대개 Gitea에 넣은 GitHub 토큰 만료) GitHub만 뒤처진다. `git fetch github` 후 `git log -1 github/main`이 `origin/main`과 다르면 Gitea 미러 설정에서 토큰을 갱신한다.

인증은 Gitea 계정 이름 + **액세스 토큰**(Gitea 설정 → 애플리케이션, 권한 `repository: 읽기/쓰기`)이다. 처음 clone·push 할 때 Git Credential Manager 창에 입력하면 저장된다. GCM이 호스트 종류를 못 알아내 느려지면 `git config --global credential.http://222.112.172.253:9080.provider generic`.

주소가 `https`가 아니라 **`http`**다. 토큰이 평문으로 오간다 — 이 저장소 외의 자격 증명을 같은 주소에 쓰지 않는다.

## 다른 PC로 옮기기

**Gitea에서 clone한다.**

```bash
git clone http://222.112.172.253:9080/msjin-claude-lab/cp_workspace.git D:/dev/workspace
```

이후로는 평범하게 `git pull` / `git push`.

### 예비 수단 — git bundle

Gitea에 접근할 수 없을 때만 쓴다. 저장소 전체(이력 포함)가 파일 하나가 되므로 USB·사내 공유 폴더·메일 어느 쪽으로든 옮길 수 있다. 아래 절차는 실제로 왕복 검증했다 (2026-11-11).

**전달 수단은 메일 첨부다.** 번들은 추적되는 파일만 담으므로 `target/`·`node_modules/` 같은 빌드 산출물이 자동으로 빠진다. 전체 번들이 22KB였다 — 용량 걱정은 없다.

> 메일 게이트웨이가 모르는 확장자를 막는 경우가 있다. `.bundle`이 반송되면 **확장자만 `.txt`로 바꿔서** 보내고 받는 쪽에서 되돌린다. 내용은 바이너리 그대로이므로 이름만 바뀐다. 압축해도 되지만 이미 압축된 형식이라 거의 줄지 않는다.

#### 처음 한 번 — 통째로 옮기기

보내는 PC:

```bash
git bundle create cp-workspace.bundle --all
```

받는 PC (번들 파일을 옮긴 뒤):

```bash
git bundle verify cp-workspace.bundle     # 이력이 온전한지 확인
git clone cp-workspace.bundle cp-workspace
```

#### 그 다음부터 — 바뀐 것만 옮기기

전체를 다시 보낼 필요 없다. 상대 PC가 이미 가진 마지막 커밋 해시를 기준으로 증분 번들을 만든다 (커밋 1개면 수백 바이트다):

```bash
git bundle create update.bundle main ^<상대가 가진 마지막 커밋 해시>
```

받는 쪽:

```bash
git pull update.bundle main
```

> 양쪽에서 각자 커밋했다면 `git pull`에서 충돌이 날 수 있다. 일반 병합과 똑같이 처리하면 된다.

## PC 간 이어가기 — 설정·작업·진행 현황

어느 PC에서든 같은 상태로 이어가도록, PC에 묶이지 않는 것은 전부 저장소에 둔다.

| 대상 | 어디에 | 이어지는 방법 |
|---|---|---|
| Claude Code 설정 (agent teams, HUD 상태바, 언어·스피너, hook) | 프로젝트 `.claude/settings.json` | 저장소와 함께 온다. `~/.claude/settings.json`보다 우선한다 |
| 작업 (코드·문서) | git | Gitea push/pull. 하다 만 작업도 `wip:` 커밋으로 push한다 |
| 진행 현황 (한 일, 멈춘 곳, 다음 할 일, 알아낸 것) | `HANDOFF.md` | 세션을 마칠 때 갱신하고 push한다. 새 세션은 HANDOFF.md를 읽고 시작한다 |
| 공통 규칙 | 이 파일 | Claude 자동 메모리(`~/.claude/projects/…/memory`)는 PC별이라 넘어가지 않는다. 모든 PC가 알아야 할 사실은 여기에 쓴다 |

Claude 대화 자체는 PC 간에 이어지지 않는다. 대화에서 정한 것은 HANDOFF.md나 이 파일에 남겨야 다른 PC가 안다.

### hook (`.claude/hooks/`)

| hook | 언제 | 하는 일 |
|---|---|---|
| `session-start.mjs` | 세션 시작·재개 | `tools/omc-hud-gauge.mjs`를 `~/.claude/hud/`에 맞춰 복사 |
| `sync-check.mjs` | Claude가 대답을 마칠 때 | **정시 구간(예: 14:00:00~14:59:59)마다 한 번** Gitea를 fetch해 비교한다. 원격에만 커밋이 있으면 pull을, 로컬에만 커밋이 있거나 커밋 안 한 변경이 있으면 push를 묻게 한다. 둘 다 없으면 묻지 않는다. 그 구간에 이미 점검했으면 건너뛴다(기록: `.git/cp-sync-check.json`, 커밋되지 않음) |

hook은 직접 pull/push/commit 하지 않는다. 물어서 사람이 고른 것만 Claude가 실행한다. hook과 설정은 Claude Code를 **시작할 때** 읽히므로 바꾼 뒤에는 재시작해야 반영된다.

### 저장소에 들어 있지 않은 것 — 새 PC에서 한 번

| 항목 | 새 PC에서 할 일 |
|---|---|
| Claude Code 로그인 | `claude` 실행 후 로그인 |
| OMC 설치 | `npm i -g oh-my-claude-sisyphus` 후 `/oh-my-claudecode:omc-setup` (`~/.claude/hud/omc-hud.mjs`가 생긴다) |
| JDK 21, Maven 3.9.x | 연습 프로젝트 빌드용 |
| Gitea 액세스 토큰 | 처음 push할 때 Git Credential Manager 창에 입력. 저장소에 넣지 않는다 |
| `.omc/` 작업 상태 | 옮기지 않는다. PC별 실행 상태(세션 기록·잠금·로그)이며 `.gitignore`로 제외한다. 예외: `.omc/skills/`(프로젝트 스킬)는 커밋한다 |

## 작업 규칙

- **사내망 PC의 저장소 경로는 `D:\cp_workspace`, 개인 PC는 `D:\dev\workspace`다.**
- **회사 IT에 접근 허용을 요청하는 것은 불가능한 구조다.** 대안을 제시할 때 "IT에 요청"을 넣지 않는다.
- **사내망 차단을 우회하지 않는다.** IP 직접 지정, DNS 변경, 프록시, GitHub 우회 프록시(`git.msjin.workers.dev` 등)는 쓰지도 제안하지도 않는다. 막혔으면 오류 문구를 그대로 보고하고 사람이 정한다.
- 사내망 PC에서 환경을 바꾸는 작업(원격 전환 등)은 읽기 전용 점검까지만 먼저 하고, 결과를 보고한 뒤 사람의 승인을 받고 진행한다.

### HUD 게이지

OMC는 상태바 게이지를 `[##------]`처럼 ASCII로 그린다. 블록 문자(`[██░░░░░░]`)로 되돌리려면 `tools/omc-hud-gauge.mjs`를 쓴다.

OMC가 출력 직전 `sanitizeOutput()`에서 블록 문자를 무조건 치환하는데(`dist/hud/sanitize.js`의 `replaceUnicodeBlocks`), **설정으로 끌 수 없다.** `omc hud`에는 관련 옵션이 없고 HUD 설정 스키마에도 게이지 문자 항목이 없다. 그래서 출력을 후처리하는 래퍼를 둔다. 패키지를 직접 고치면 `npm i -g` 할 때마다 날아가므로 래퍼가 맞다.

**새 PC에서 따로 할 일은 없다.** `session-start.mjs` hook이 래퍼를 `~/.claude/hud/`에 복사하고, 프로젝트 `.claude/settings.json`의 `statusLine`이 홈 경로를 스스로 찾아 그 파일을 실행한다(PC마다 홈 경로가 달라도 된다).

되돌리려면 프로젝트 `.claude/settings.json`의 `statusLine.command`에서 `omc-hud-gauge.mjs`를 `omc-hud.mjs`로 바꾼다. `/oh-my-claudecode:hud setup`은 `~/.claude/settings.json`만 고치므로 프로젝트 설정에는 영향이 없다.

## 설치된 도구

| 도구 | 버전 |
|---|---|
| JDK | 21.0.11 (LTS) |
| Maven | 3.9.11 |
| Node | 24.18.0 / npm 11.16.0 |
| Python | 3.12.10 |

**`jq`는 없다.** JSON 파일은 Read/Edit 도구로 수정한다. `jq`에 의존하는 셸 스크립트는 실패하므로(OMC의 `setup-progress.sh`가 그렇다) 같은 변경을 Edit로 직접 재현한다.

`gradle`, `gh`도 없다.

## 새 프로젝트를 추가할 때

1. `projects/<name>/` 생성
2. 프로젝트 고유 규칙·빌드 명령은 `projects/<name>/CLAUDE.md`에
3. 모든 프로젝트에 해당하는 사실을 알게 되면 이 파일에 추가한다
