# 이어서 작업하기

마지막 갱신: 2026-11-12

워크스페이스 구성은 끝났다. 이 문서는 **다음에 이어서 할 일**과 **중단된 작업의 조사 결과**만 담는다.
환경 사실·규칙은 [CLAUDE.md](CLAUDE.md), 연습 과제는 [projects/loan/PRACTICE.md](projects/loan/PRACTICE.md)에 있다.

## 지금 상태

| 항목 | 상태 |
|---|---|
| 워크스페이스 구성 | 완료 (커밋 `7703204`, `caabcb0`) |
| OMC | npm 전역 5.8.4, 글로벌·로컬 `CLAUDE.md` 모두 설치됨 |
| 원격 저장소 | Gitea(기준) → GitHub(푸시 미러, 읽기 전용). 구성은 [CLAUDE.md의 "git"](CLAUDE.md#git) |
| 연습 프로젝트 | `projects/loan/` — 결함 심어둔 상태 그대로, 고친 것 없음 |
| `mvn -q test` | **14개 중 13개 통과, 1개 실패가 정상** |

마지막으로 실제 실행해 확인한 실패 (개인 PC, JDK 21.0.13 / Maven 3.9.16, 2026-11-11):

```
FeeCalculatorTest.chargesOnlyDaysBeyondGrace:41  expected: <1000> but was: <2500>
```

유예기간(grace) 이후 일수만 과금해야 하는데 전체 일수를 과금하고 있다.

## PC별 남은 일

| 할 일 | 사내망 PC | 개인 PC |
|---|---|---|
| Gitea 원격으로 전환 | **남음** — [docs/handoff/office-pc.md](docs/handoff/office-pc.md) | 완료 |
| HUD 상태바 눈으로 확인 | 남음 | 남음 |
| `/team` 동작 확인 + 연습 과제 | 남음 | 남음 |
| JDK 21·Maven이 새 셸에서 잡히는지 | 해당 없음(원래 설치됨) | **남음** — 아래 참고 |

### 사내망 PC — Gitea 전환

**사내망에서 Gitea에 접근되는지는 아직 확인하지 않았다.** [docs/handoff/office-pc.md](docs/handoff/office-pc.md)의 0단계(읽기 전용 점검)만 먼저 하고, 결과를 사람에게 보고한 뒤 **진행 여부를 묻는다.** 사람이 진행하라고 할 때만 1단계부터 이어간다.

접근이 안 되면 저장소를 건드리지 않고 오류 문구를 그대로 보고한다. 회사 IT에 허용을 요청하는 것은 불가능한 구조이고, 차단 우회(IP 직접 지정, DNS 변경, 프록시)는 쓰지 않는다. 남는 대안은 git bundle 메일 전달, 또는 개인 도메인 + Cloudflare Tunnel이다. 결정은 사람이 한다.

### 개인 PC — JDK 21·Maven 환경 변수

2026-11-11에 Microsoft OpenJDK 21.0.13을 `C:\Java\jdk-21.0.13.0.2+1`, Maven 3.9.16을 `C:\Java\apache-maven-3.9.16`에 설치하고 사용자 환경 변수(`JAVA_HOME`, `Path` 앞쪽)에 등록했다.

Claude Code를 Zed 터미널에서 띄우면 Zed가 시작될 때의 환경 변수를 물려준다. Zed를 완전히 종료했다가 다시 연 뒤 `java -version`이 21, `mvn --version`이 3.9.16인지 확인한다. 여전히 JDK 17(`C:\Java\jdk-17\bin`)이 먼저 잡히면 그 경로를 넣는 곳을 찾아야 한다 — 레지스트리 `Path`와 PowerShell 프로필에는 없었다.

## HUD 게이지 — 해결됨 (래퍼 스크립트)

게이지가 `[##------]`로 나오던 것을 `[██░░░░░░]`로 되돌렸다. 사용법은 [CLAUDE.md의 "HUD 게이지"](CLAUDE.md#hud-게이지)에 있다.

- 스크립트: `tools/omc-hud-gauge.mjs` (저장소에 있으므로 clone하면 같이 온다)
- 설치 위치: `~/.claude/hud/omc-hud-gauge.mjs`, `settings.json`의 `statusLine.command`가 이걸 가리킨다 (개인 PC는 2026-11-11에 설치·설정 완료)

원인은 `dist/hud/sanitize.js`의 `replaceUnicodeBlocks()`가 설정·터미널 감지 없이 `█`→`#`, `░`→`-`로 무조건 치환하는 것이었다. 공식 설정으로는 끌 수 없어 출력을 후처리한다.

**아직 눈으로 확인 못 한 것:** `█`(U+2588)·`░`(U+2591)은 동아시아 환경에서 **폭이 모호한(Ambiguous) 문자**다. 한국어 로케일 터미널이 2칸으로 그리면 게이지 폭이 밀린다 — OMC가 ASCII로 바꾼 진짜 이유가 이것이다(`sanitize.js` 주석, issue #346). 재시작 후 상태바에서 폭이 밀리지 않는지 볼 것. 밀리면 `statusLine.command`를 `omc-hud.mjs`로 되돌린다.

## 재시작 후 확인할 것

HUD 상태바와 agent teams는 **Claude Code 시작 시** 읽힌다. 두 PC 모두 아직 확인 못 했다:

1. 상태바가 2줄 OMC HUD로 나오는지
2. `/team 2:executor "FeeCalculatorTest 실패를 고쳐라"` 가 동작하는지 — 하나로 둘 다 확인된다

## 다른 PC에서 이어가기

절차는 [CLAUDE.md의 "다른 PC로 옮기기"](CLAUDE.md#다른-pc로-옮기기)에 있다. 요약하면:

1. 받는 PC: `git clone https://gitea.msjin.workers.dev/msjin-claude-lab/cp_workspace.git D:/dev/workspace` — 공개 저장소라 clone·pull은 로그인 없이 된다
2. 작업 전 `git pull`, 작업 후 `git push` — push는 **Gitea에만** 한다. 처음 push할 때 Gitea 계정 이름 + 액세스 토큰으로 로그인한다. GitHub는 Gitea 푸시 미러가 맞춘다
3. `~/.claude/` 전역 설정은 저장소에 없으므로 CLAUDE.md의 표대로 새 PC에서 따로 맞춘다

이미 저장소가 있는 PC(사내망 PC)는 clone 대신 [docs/handoff/office-pc.md](docs/handoff/office-pc.md)를 따른다. Gitea에 접근할 수 없으면 CLAUDE.md의 "예비 수단 — git bundle"을 쓴다.

새 세션은 이렇게 시작하면 된다:

```
D:\dev\workspace 에서 작업을 이어서 한다. HANDOFF.md 를 읽고 시작해라.
```
