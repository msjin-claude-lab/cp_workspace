# cp_workspace

Claude Code + [oh-my-claudecode](https://www.npmjs.com/package/oh-my-claude-sisyphus)(OMC) 연습용 워크스페이스. 여러 프로젝트가 공유하는 환경 규칙과, 결함을 일부러 심어 둔 연습 프로젝트가 들어 있다.

## 구성

```
cp_workspace/
├── README.md              ← 이 파일. 요약
├── CLAUDE.md              ← 공통 환경 사실·규칙 (망 제약, git 원격, 다른 PC로 옮기기, HUD)
├── HANDOFF.md             ← 이어서 할 일, PC별 남은 일
├── tools/
│   └── omc-hud-gauge.mjs  ← OMC HUD 게이지를 블록 문자(█░)로 되돌리는 래퍼
├── projects/
│   └── loan/              ← 연습 프로젝트 (Java 21 / Maven, 결함 의도적으로 심음)
├── .claude/
│   ├── settings.json      ← Claude Code 프로젝트 설정 (모든 PC 공통: agent teams, HUD, hook)
│   ├── hooks/             ← 세션 시작 HUD 갱신, 정시 구간별 pull/push 점검
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

## 연습 프로젝트 — `projects/loan`

도서 대출 모듈. 코드의 결함은 **전부 의도적**이며 OMC 스킬로 찾아 고치는 연습에 쓴다. 과제 목록은 [PRACTICE.md](projects/loan/PRACTICE.md).

```bash
cd projects/loan
mvn -q test     # 14개 모두 통과 (과제 1 완료 후. 처음은 13개 통과·1개 실패)
```

필요한 도구: JDK 21, Maven 3.9.x.

## 지금 남은 일

[HANDOFF.md](HANDOFF.md)에 PC별로 정리돼 있다. 요약:

- 사내망 PC: 프로젝트 설정·hook 받기(`git pull` 후 재시작)
- 두 PC 공통: HUD 상태바 모양 확인, `/team` 동작 확인
- 연습 과제: 1번 완료, 다음은 2번(`/tdd` — `RenewalPolicy`)
