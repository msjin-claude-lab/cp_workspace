# cp_workspace

Claude Code + [oh-my-claudecode](https://www.npmjs.com/package/oh-my-claude-sisyphus)(OMC) 워크스페이스. 여러 프로젝트가 공유하는 환경 규칙과, 결함을 일부러 심어 둔 연습 프로젝트(`projects/practice/loan`), 그리고 실제로 만드는 앱(`projects/apps` — 첫 앱은 영단어 앱 `vocab`)이 들어 있다.

## 구성

```
cp_workspace/
├── README.md              ← 이 파일. 요약
├── CLAUDE.md              ← 공통 환경 사실·규칙 (망 제약, git 원격, 다른 PC로 옮기기, HUD)
├── HANDOFF.md             ← 이어서 할 일, PC별 남은 일
├── AGENTS.md              ← 에이전트용 폴더 안내 (CLAUDE.md와 겹치면 CLAUDE.md가 우선)
├── docs/                  ← 워크스페이스 공통 문서 (Gitea 점검 기록)
├── wiki/                  ← OMC 위키 페이지 (.omc/wiki가 여기를 가리킨다. PC 간 공유)
├── env/                   ← 모든 PC에 맞출 환경 설정의 기준 (세션 시작·pull 직후 자동 반영)
│   ├── sync.mjs           ← 비교·적용 공통 코드. `node env/sync.mjs`로 차이 확인
│   ├── hud/               ← HUD 래퍼, HUD 표시 항목(hud-config.json)
│   └── git/               ← git 설정 기준 (적용 전에 Claude가 묻는다)
├── projects/
│   ├── SETUP.md           ← 모든 프로젝트 공통 개발 환경
│   ├── practice/          ← 연습 그룹
│   │   └── loan/          ← 연습 프로젝트 (Java 21 / Maven, 결함 의도적으로 심음)
│   └── apps/              ← 앱 그룹
│       ├── CLAUDE.md      ← 앱 공통 규칙 (새 앱 시작 순서, 주제 인계, PC 역할)
│       ├── SETUP.md       ← 앱 공통 개발 환경 (Flutter·Android SDK)
│       ├── _drafts/       ← 진행 중 주제·후보 목록
│       └── vocab/         ← 영단어 앱 (Flutter). 인계는 vocab/HANDOFF.md
├── plugins/
│   └── apps/              ← 앱 작업용 스킬 플러그인 (/apps:new · selection-subject · view-subjects · config)
├── .claude-plugin/        ← 위 플러그인을 설치하는 로컬 마켓플레이스 정의
├── .claude/
│   ├── settings.json      ← Claude Code 프로젝트 설정 (모든 PC 공통: agent teams, HUD, hook)
│   ├── hooks/             ← 세션 시작 환경 맞추기, 정시 구간별 pull/push 점검
│   ├── skills/            ← 저장소 전용 스킬 (verify — projects/practice/loan 검증, wiki)
│   └── CLAUDE.md          ← OMC 관리 영역. 손대지 않는다
└── .omc-workspace         ← OMC 상태 루트 앵커
```

## 원격 저장소

| 원격 | 주소 | 역할 |
|---|---|---|
| 개인 Gitea | `http://222.112.172.253:9080/msjin-claude-lab/cp_workspace.git` | **기준 저장소.** 모든 PC가 여기에만 push |
| GitHub | `https://github.com/msjin-claude-lab/cp_workspace.git` | 읽기 전용 사본. Gitea 푸시 미러가 자동으로 맞춘다 |

GitHub에 직접 push하지 않는다 — 미러가 덮어써서 사라진다. 사내망 PC는 github.com이 막혀 있어 Gitea만 쓴다. 자세한 구성은 [CLAUDE.md의 "git"](CLAUDE.md#git).

## 시작하기

```bash
git clone http://222.112.172.253:9080/msjin-claude-lab/cp_workspace.git D:/dev/workspace
```

- clone·pull은 로그인 없이 된다(공개 저장소). push할 때만 Gitea 계정 + 액세스 토큰이 필요하다. 주소가 `http`라 토큰이 평문으로 오간다.
- Claude Code 설정(agent teams, HUD 상태바, hook)은 프로젝트 `.claude/settings.json`에 있어 clone하면 같이 온다. 새 PC에서 한 번 할 일(로그인, OMC·JDK·Maven 설치, Gitea 토큰)은 [CLAUDE.md의 "저장소에 들어 있지 않은 것"](CLAUDE.md#저장소에-들어-있지-않은-것--새-pc에서-한-번) 표에 있다.
- 작업 중에는 정시 구간마다 한 번 Claude가 Gitea와 비교해, 받을 것이나 올릴 것이 있을 때만 pull/push 여부를 묻는다. 마칠 때는 HANDOFF.md를 갱신하고 push한다([CLAUDE.md의 "PC 간 이어가기"](CLAUDE.md#pc-간-이어가기--설정작업진행-현황)).
- Gitea에 접근할 수 없으면 git bundle을 메일로 주고받는다([CLAUDE.md의 "예비 수단"](CLAUDE.md#예비-수단--git-bundle)).

Claude Code 새 세션은 이렇게 시작한다:

```
D:\dev\workspace 에서 작업을 이어서 한다. HANDOFF.md 를 읽고 시작해라.      (개인 PC)
D:\cp_workspace 에서 작업을 이어서 한다. HANDOFF.md 를 읽고 시작해라.      (사내망 PC)
```

## 연습 프로젝트 — `projects/practice/loan`

도서 대출 모듈. 코드의 결함은 **전부 의도적**이며 OMC 스킬로 찾아 고치는 연습에 쓴다. 과제 목록은 [PRACTICE.md](projects/practice/loan/PRACTICE.md).

```bash
cd projects/practice/loan
mvn -q test     # 41개 모두 통과 (과제 9 완료 후. 처음은 13개 통과·1개 실패)
```

필요한 도구: JDK 21, Maven 3.9.x.

## 앱 — `projects/apps`

실제로 만드는 앱을 두는 그룹이다. 공통 규칙은 [projects/apps/CLAUDE.md](projects/apps/CLAUDE.md)(새 앱 시작 순서: 앱 정의 → 선택안 → 선택 → 검증 → 최종 결정), 개발 환경은 [projects/apps/SETUP.md](projects/apps/SETUP.md).

| 하려는 일 | 입력 |
|---|---|
| 주제 목록·진행 보기 | `/apps:view-subjects` |
| 주제 골라 이어 가기 | `/apps:selection-subject <주제>` |
| 새 주제 시작 | `/apps:new <주제>` |

앱마다 인계는 그 앱 폴더의 `HANDOFF.md`에 있다. 에뮬레이터 실행 확인은 개인 PC에서만 한다(사내망 PC는 analyze·test·build까지).

### 영단어 앱 — `projects/apps/vocab`

초·중·고 학생용 영단어 앱(Flutter, 지금은 안드로이드만 — iOS는 보류). 학교급 × 난이도로 이름 붙인 단어장을 만들어 카드 학습·4지선다 시험·오답 노트를 하고 진도를 본다. 계정 없이 기록은 기기 안에만 둔다.

- 단어: 초등 800개(쉬움 267 · 중간 267 · 어려움 266, CEFR-J Wordlist 기준 — 2026-11-24), 중등 700개(CEFR-J 기준, 234 · 233 · 233), 고등은 칸당 50개(늘릴 예정)
- 규칙·명령·코드 구조는 [vocab/CLAUDE.md](projects/apps/vocab/CLAUDE.md), 지금 상태와 다음 할 일은 [vocab/HANDOFF.md](projects/apps/vocab/HANDOFF.md), 검증 방법과 마지막 결과는 [vocab/VERIFY.md](projects/apps/vocab/VERIFY.md)

```bash
cd projects/apps/vocab
flutter analyze && flutter test     # 168개 통과 (2026-11-23)
flutter build apk --debug
```

필요한 도구: Flutter(`D:\dev\flutter`), Android SDK(`D:\dev\android-sdk`).

## 지금 남은 일

워크스페이스 쪽은 [HANDOFF.md](HANDOFF.md)에 PC별로, 앱은 그 앱의 `HANDOFF.md`에 정리돼 있다. 요약:

- 영단어 앱: 단어 늘리기 2차(중등 700) · 3차(고등 1,500 + 심화), 출시 준비(앱 이름·아이콘·서명 키) — [vocab/HANDOFF.md](projects/apps/vocab/HANDOFF.md) "이어서 할 일"
- 사내망 PC: npm 방식 OMC 복사본 정리(플러그인으로 전환 완료)
- 두 PC 공통: HUD 상태바 모양 확인, `/team` 동작 확인
- 연습 과제: 1~9번 모두 완료(2026-11-17)
