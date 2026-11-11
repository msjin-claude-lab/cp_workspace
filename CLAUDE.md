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

**차단된 것은 `github.com` 하나뿐이다.** 패키지 레지스트리는 열려 있다 (2026-11-11 실측).

| 호스트 | 상태 |
|---|---|
| `github.com` | 차단 |
| `registry.npmjs.org` | 가용 |
| `repo.maven.apache.org` | 가용 |

따라서 npm·Maven 의존성은 자유롭게 추가해도 된다. GitHub에서 받아오는 것만 안 된다.

### 사용할 수 없는 스킬

`gh` CLI 미설치 + GitHub 차단이라 아래는 이 워크스페이스에서 동작하지 않는다. 시도하지 말 것:

`/pr` · `/babysit` · `/fix-ci` · `/get-pr-comments` · `/review`(GitHub PR용 — 작업 중인 diff 리뷰는 `/omc-review`를 쓴다)

## git

**로컬 전용이다.** 원격을 추가하거나 push 하지 않는다. 커밋·브랜치·rebase 등 로컬 작업은 모두 정상이다.

## 다른 PC로 옮기기

GitHub이 막혀 있으므로 **git bundle**을 쓴다. 저장소 전체(이력 포함)가 파일 하나가 되므로 USB·사내 공유 폴더·메일 어느 쪽으로든 옮길 수 있다. 아래 절차는 실제로 왕복 검증했다 (2026-11-11).

**전달 수단은 메일 첨부다.** 번들은 추적되는 파일만 담으므로 `target/`·`node_modules/` 같은 빌드 산출물이 자동으로 빠진다. 전체 번들이 22KB였다 — 용량 걱정은 없다.

> 메일 게이트웨이가 모르는 확장자를 막는 경우가 있다. `.bundle`이 반송되면 **확장자만 `.txt`로 바꿔서** 보내고 받는 쪽에서 되돌린다. 내용은 바이너리 그대로이므로 이름만 바뀐다. 압축해도 되지만 이미 압축된 형식이라 거의 줄지 않는다.

### 처음 한 번 — 통째로 옮기기

보내는 PC:

```bash
git bundle create cp-workspace.bundle --all
```

받는 PC (번들 파일을 옮긴 뒤):

```bash
git bundle verify cp-workspace.bundle     # 이력이 온전한지 확인
git clone cp-workspace.bundle cp-workspace
```

### 그 다음부터 — 바뀐 것만 옮기기

전체를 다시 보낼 필요 없다. 상대 PC가 이미 가진 마지막 커밋 해시를 기준으로 증분 번들을 만든다 (커밋 1개면 수백 바이트다):

```bash
git bundle create update.bundle master ^<상대가 가진 마지막 커밋 해시>
```

받는 쪽:

```bash
git pull update.bundle master
```

> 양쪽에서 각자 커밋했다면 `git pull`에서 충돌이 날 수 있다. 일반 병합과 똑같이 처리하면 된다.

### 사내 git 서버나 공유 폴더가 있다면

그쪽이 더 편하다. 공유 폴더에 bare 저장소를 두고 평범한 remote로 쓸 수 있다:

```bash
git clone --bare cp-workspace //서버/공유/cp-workspace.git
git remote add origin //서버/공유/cp-workspace.git
```

사내 GitLab·Gitea·Bitbucket·Azure DevOps가 있다면 그것을 remote로 쓴다. **차단된 것은 GitHub뿐이다.**

### 저장소에 들어 있지 않은 것

OMC 전역 설정은 `~/.claude/` 아래에 있어서 번들에 포함되지 않는다. 새 PC에서는 따로 맞춰야 한다:

| 항목 | 새 PC에서 할 일 |
|---|---|
| OMC 설치 | `npm i -g oh-my-claude-sisyphus` |
| HUD 상태바 | `/oh-my-claudecode:hud setup` |
| HUD 게이지 문자 | 아래 "HUD 게이지" 참고. 스크립트는 저장소의 `tools/`에 있으므로 번들에 실려 온다 |
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
