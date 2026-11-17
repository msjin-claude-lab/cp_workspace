# cp-workspace

모든 프로젝트의 **공통 뼈대**다. 여기에는 프로젝트 전부가 공유하는 환경 사실과 규칙만 둔다.
개별 프로젝트는 `projects/<name>/` 아래에 두고, 그 프로젝트에만 해당하는 규칙은 거기의 `CLAUDE.md`에 쓴다.

```
cp-workspace/
├── CLAUDE.md            ← 이 파일. 모든 프로젝트가 공유하는 규칙
├── .omc-workspace       ← OMC 상태 루트 앵커
├── .claude/CLAUDE.md    ← OMC 코디네이터 관리 영역. 손대지 말 것
└── projects/
    ├── loan/            ← 개별 프로젝트
    └── apps/<앱>/        ← 앱 그룹 (아래 "앱을 여러 개 만들 때")
```

`.omc-workspace` 마커 때문에 `projects/` 아래 프로젝트가 **자체 git 저장소**가 되더라도 OMC 상태(`.omc/`)는 여기 하나로 모인다. 프로젝트마다 상태가 흩어지지 않는다.

### 앱을 여러 개 만들 때 — `projects/<그룹>/<앱>/` (2026-11-17 정함. 첫 그룹 `projects/apps/`, 아직 만든 앱 없음)

```
projects/
├── loan/                  ← 기존 연습 프로젝트 (그룹 없이 그대로)
└── <그룹>/                ← 예: apps/
    ├── CLAUDE.md          ← 그룹 공통 규칙이 생겼을 때만 만든다 (같은 스택·배포 방식 등)
    ├── .gitkeep           ← 앱도 규칙도 없을 때 빈 폴더를 git에 남기는 빈 파일. Claude가 읽지 않는다
    └── <앱>/
        └── CLAUDE.md      ← 앱 고유 규칙 + 빌드·테스트 명령
```

- CLAUDE.md는 작업 위치에서 위로 올라가며 읽히므로 규칙이 **루트 → 그룹 → 앱** 순으로 겹친다. 같은 내용은 가장 위 한 곳에만 쓴다
- **그룹 `CLAUDE.md`는 공통 규칙이 생길 때 만든다.** 내용 없는 CLAUDE.md도 그 아래 작업 때마다 읽히므로, 그전에는 `.gitkeep`만 둔다(`projects/apps/`가 지금 이 상태)
- **검증 명령은 앱마다** 그 앱 CLAUDE.md에 적는다. 저장소 `/verify` 스킬(`.claude/skills/verify`)은 지금 `projects/loan` 전용이라, 앱이 생기면 각 앱 명령을 참조하도록 고친다
- **git은 저장소 하나로 시작한다.** 배포 주기·공개 범위가 다른 앱만 나중에 분리한다(분리해도 OMC 상태는 위 앵커 덕에 루트에 모인다)
- 이름은 짧게 짓는다. Windows 경로 260자 제한에 `node_modules`가 걸릴 수 있다
- **Claude는 루트(`D:\cp_workspace`)에서 열고** "`projects/<그룹>/<앱>`에서 작업한다"로 시작한다. 앱 폴더에서 열면 공식 문서 기준(2026-11-17 확인, PC에서 직접 시험은 아직)으로 이렇게 된다:
  - **빠진다**: 루트 `.claude/settings.json` — 실행한 폴더에서만 읽고 위로 찾지 않는다(settings 문서 "to use a file committed at the repository root, start Claude Code there"). 이 저장소의 **HUD 상태줄·git 동기화 hook·agent teams가 꺼진다**
  - **그대로 된다**: 저장소 스킬·에이전트(`.claude/skills`·`.claude/agents`를 저장소 루트까지 올라가며 찾음), 상위 CLAUDE.md(루트 → 그룹 → 앱), 자동 메모리(git 저장소 단위로 공유)
  - **따로 쌓인다**: 대화 기록(실행 폴더별). 앱 폴더의 `claude --continue`에는 루트 대화가 안 보인다
  - 앱 폴더에서 열어야 한다면 `claude --settings D:\cp_workspace\.claude\settings.json`(상태줄·hook 경로까지 동작하는지는 미확인). 실제로 무엇이 읽혔는지는 `/status`의 Setting sources와 `/context all`로 본다

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

그래서 GCM이 git 명령마다 `warning: use of unencrypted HTTP remote URLs is not recommended`를 띄운다. 경고만 끄려면 PC마다 한 번 실행한다(2026-11-16 사내망 PC 적용):

```bash
git config --global credential.allowUnsafeRemotes true
```

경고만 사라지고 평문 전송은 그대로다. 근본 해결은 HTTPS인데, 공인 인증서는 도메인에 발급되고 NAS 도메인은 사내망에서 차단돼 IP로 접속하는 지금 구조에서는 쓸 수 없다.

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
| `session-start.mjs` | 세션 시작·재개 | Gitea와 비교해 결과를 화면에 한 줄로 띄운다(`✓ 원격과 같음` / 받을 것·올릴 것 / `⚠ 원격 확인 실패`). 받을 것이나 올릴 것이 있으면 Claude가 첫 대답에서 먼저 묻는다. 이 점검은 그 정시 구간의 점검으로 기록된다. 또 `env/` 기준으로 환경 설정을 맞춘다(아래 "환경 설정 공통화") |
| `sync-check.mjs` | Claude가 대답을 마칠 때 | **정시 구간(예: 14:00:00~14:59:59)마다 한 번** Gitea를 fetch해 비교한다. 원격에만 커밋이 있으면 pull을, 로컬에만 커밋이 있거나 커밋 안 한 변경이 있으면 push를 묻게 한다. 점검할 때마다 결과를 `[git 동기화 점검 · N시] …` 한 줄로 띄운다(원격과 같음 / 차이 → 질문 / 원격 확인 실패). 그 구간에 이미 점검했으면 건너뛴다(기록: `.git/cp-sync-check.json`, 커밋되지 않음) |
| `sync-core.mjs` | — | 위 두 hook이 쓰는 비교 로직 |

### 환경 설정 공통화 (`env/`)

PC마다 사용자 폴더에 저장돼 git으로 넘어가지 않는 설정은 `env/`에 **기준**을 두고 각 PC를 거기에 맞춘다. 바꾸려면 PC에서 직접 고치지 말고 `env/`를 고쳐 커밋한다. 자세한 대상은 [env/AGENTS.md](env/AGENTS.md).

| 대상 | 기준 파일 | 적용 |
|---|---|---|
| HUD 래퍼 | `env/hud/omc-hud-gauge.mjs` → `~/.claude/hud/` | 자동 — 세션 시작 때, 그리고 pull 직후 다음 상태줄 갱신 때 |
| HUD 표시 항목 | `env/hud/hud-config.json` → `~/.claude/.omc/hud-config.json` (`~/.claude/settings.json`의 `omcHud`는 제거) | 자동 — 위와 같음 |
| OMC 위키 | 실제 파일은 저장소 `wiki/`, `.omc/wiki`는 그 연결(정션) | 자동 — 위와 같음 |
| git 설정 | `env/git/git-config.json` — Gitea 로그인 방식(`wincred`), `provider generic`, `allowUnsafeRemotes`, `origin` | **묻고 적용** — 세션 시작 때 차이가 있으면 Claude가 묻는다. 수동: `node env/sync.mjs --apply git` |

`node env/sync.mjs`는 차이만 보여 준다. 덮어쓴 원본은 `<파일>.before-env-sync`로 남는다.

**HUD 2줄 구조는 고정이다(2026-11-17).** 1줄 `ctx | 모델 | git`, 2줄 `5H · WK · Fable`. 덧붙는 항목은 괜찮고, 이 구조를 깨는 변경은 거부한다. 자세한 규칙은 [env/AGENTS.md](env/AGENTS.md).

## 작업 규칙 — 2026-11-17 회고에서 정함

- **백슬래시나 한글이 든 파일은 Edit 도구로 고친다.** bash heredoc + Python·sed로 치환하지 않는다. 셸과 Python을 거치며 `\a`가 BEL, `\b`가 백스페이스로 바뀌어 커밋을 두 번 다시 했다. 일괄 치환을 했다면 제어 문자(`\x00-\x08`)가 0개인지 확인한다
- **테스트와 커밋은 `&&`로만 잇는다.** `;`로 이으면 테스트가 실패해도 커밋·push가 진행된다(`test exit=1`인 채 push한 적 있음)
- **화면에 보이는 결과(HUD 등)는 사용자가 확인하기 전까지 "적용함, 화면 확인 필요"로만 보고한다.** 출력 바이트가 맞아도 Claude Code가 다시 가공한다(줄 앞 공백 trim 등)
- **사용자에게 안내할 방법은 먼저 직접 시험한다.** 시험하지 못했으면 "확인하지 않음"이라고 밝힌다

## 답변 형식 — 모든 PC 공통

사용자가 정한 형식이다. Claude 자동 메모리는 PC별이라 넘어가지 않으므로 여기에 둔다(2026-11-13~15 개인 PC에서 정함).

- **본문은 짧게.** 장황하면 오히려 헷갈린다. 본문 중간에 상태·결과를 표로 나열하지 않는다
- **맨 끝에 `**요약**`을 반드시 붙인다.** 결과만 적지 않고, 요약만 읽어도 내용을 알 수 있게 쓴다: 무엇을 했나 / 왜 / 무엇을 이용했나(스킬·도구·기준 규정) / 근거(무엇으로 성공을 판단했나) / 사용자가 다음에 할 일
- **git 작업(커밋·push)은 요약에서 성공·실패와 할 일만** 적는다. 커밋에 들어간 파일 목록은 쓰지 않는다
- **단계별 진행(연습 과제 등)은 다음 단계 하나만** 보여준다. 전체 목록을 다 보여주지 않는다
- 다음 단계는 요약 아래에 **한 줄 표**(헤더 + 1행)로 보여준다. 이 표가 답변에서 쓰는 유일한 표다

  | 진행 | 주제 | 입력 | 왜 연습하나 | 언제 쓰나 |
  |---|---|---|---|---|
  | 6/9 | 문서 없는 코드 이해 | `/oh-my-claudecode:how ...` | 이 연습을 하는 이유 | 실무에서 이 스킬을 쓰는 때 |

- 연습 과제의 **단계(과제 번호와 스킬 순서)는 PRACTICE.md 그대로** 진행한다. 바꾸는 것은 스킬에 넘기는 **주제(인자)뿐**이며, 앞 단계 결과를 이어받아 정한다. 주제를 바꿀 때는 "무엇을 보고 왜 바꿨는지"를 한 줄로 밝힌다(2026-11-17 사내망 PC에서 정함)
- 사용자가 **"기존대로"라고 정한 항목은 그 항목을 직접 말하기 전까지 바꾸지 않는다.** "N번 기준으로" 같은 짧은 지시는 바꾸는 범위를 한 줄로 밝히고 적용한다(2026-11-17 회고 — "[]는 기존대로" 뒤 "9번 기준"을 테두리까지로 읽어 되돌림)

- OMC 스킬은 입력란에 `/oh-my-claudecode:` 접두사까지 적는다. 붙이지 않으면 Claude Code 기본 명령이 실행될 수 있다(예: `/debug`)
  - 접두사는 OMC를 **플러그인**으로 설치해야 생긴다. npm 전역 설치만 하면 스킬이 `~/.claude/skills/`에 접두사 없이 들어가 `/oh-my-claudecode:wiki`가 `Unknown command`가 되고, `/debug`처럼 기본 명령과 이름이 겹치는 스킬은 쓸 수 없다
  - 사내망 PC는 GitHub 마켓플레이스를 쓸 수 없으므로, npm 패키지 안의 마켓플레이스 파일로 설치한다(2026-11-17 사내망 PC 적용). 패키지는 npm 레지스트리에서 받은 것이라 차단 우회가 아니다:

    ```bash
    claude plugin marketplace add "<npm root -g>/oh-my-claude-sisyphus"
    claude plugin install oh-my-claudecode@omc
    ```
