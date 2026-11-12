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
| `222.112.172.253:9080` (개인 Gitea) | 가용 — git clone·fetch 정상 (2026-11-12 실측) | 가용 |
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

### 저장소에 들어 있지 않은 것

OMC 전역 설정은 `~/.claude/` 아래에 있어서 git 저장소에 포함되지 않는다. 새 PC에서는 따로 맞춰야 한다:

| 항목 | 새 PC에서 할 일 |
|---|---|
| OMC 설치 | `npm i -g oh-my-claude-sisyphus` |
| HUD 상태바 | `/oh-my-claudecode:hud setup` |
| HUD 게이지 문자 | 아래 "HUD 게이지" 참고. 스크립트는 저장소의 `tools/`에 있으므로 clone하면 같이 온다 |
| agent teams | `~/.claude/settings.json`의 `env`에 `"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"` |
| `.omc/` 작업 상태 | 옮기지 않는다. PC별 로컬 상태이며 git에서도 제외돼 있다 |

### HUD 게이지

OMC는 상태바 게이지를 `[##------]`처럼 ASCII로 그린다. 블록 문자(`[██░░░░░░]`)로 되돌리려면 `tools/omc-hud-gauge.mjs`를 쓴다.

OMC가 출력 직전 `sanitizeOutput()`에서 블록 문자를 무조건 치환하는데(`dist/hud/sanitize.js`의 `replaceUnicodeBlocks`), **설정으로 끌 수 없다.** `omc hud`에는 관련 옵션이 없고 HUD 설정 스키마에도 게이지 문자 항목이 없다. 그래서 출력을 후처리하는 래퍼를 둔다. 패키지를 직접 고치면 `npm i -g` 할 때마다 날아가므로 래퍼가 맞다.

새 PC에서:

```bash
cp tools/omc-hud-gauge.mjs ~/.claude/hud/
```

그리고 `~/.claude/settings.json`의 `statusLine.command`를 그 경로로 바꾼다:

```json
"statusLine": { "type": "command", "command": "node C:/Users/M/.claude/hud/omc-hud-gauge.mjs" }
```

되돌리려면 `omc-hud.mjs`를 가리키게 하면 된다.

> `/oh-my-claudecode:hud setup`을 다시 돌리면 `statusLine`이 `omc-hud.mjs`로 되돌아간다. 그때는 위 경로로 다시 바꾼다.

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
