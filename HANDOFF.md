# 이어서 작업하기

마지막 갱신: 2026-11-12

워크스페이스 구성은 끝났다. 이 문서는 **다음에 이어서 할 일**과 **중단된 작업의 조사 결과**만 담는다.
환경 사실·규칙은 [CLAUDE.md](CLAUDE.md), 연습 과제는 [projects/loan/PRACTICE.md](projects/loan/PRACTICE.md)에 있다.

## 지금 상태

| 항목 | 상태 |
|---|---|
| 워크스페이스 구성 | 완료 |
| OMC | npm 전역 5.8.4, 글로벌·로컬 `CLAUDE.md` 모두 설치됨 |
| 원격 저장소 | Gitea(기준) → GitHub(푸시 미러, 읽기 전용). 두 PC 모두 `origin` = Gitea. 구성은 [CLAUDE.md의 "git"](CLAUDE.md#git) |
| Claude Code 설정 | 프로젝트 `.claude/settings.json`에 둠 — agent teams, HUD 상태바, hook. 모든 PC 공통 ([CLAUDE.md의 "PC 간 이어가기"](CLAUDE.md#pc-간-이어가기--설정작업진행-현황)) |
| 연습 프로젝트 | `projects/loan/` — 결함 심어둔 상태 그대로, 고친 것 없음 |
| `mvn -q test` | **14개 중 13개 통과, 1개 실패가 정상** |

마지막으로 실제 실행해 확인한 실패 (개인 PC, JDK 21.0.13 / Maven 3.9.16, 2026-11-11):

```
FeeCalculatorTest.chargesOnlyDaysBeyondGrace:41  expected: <1000> but was: <2500>
```

유예기간(grace) 이후 일수만 과금해야 하는데 전체 일수를 과금하고 있다.

## 남은 일

| 할 일 | 사내망 PC | 개인 PC |
|---|---|---|
| 프로젝트 설정·hook 받기 (커밋 `839895d` 이후) | **남음** — `git pull` 후 Claude Code 재시작. 처음에 프로젝트 hook 허용을 물으면 허용 | 완료 |
| HUD 상태바 눈으로 확인 | 남음 | 남음 |
| `/team` 동작 확인 + 첫 연습 과제 | 남음 | 남음 |

HUD와 `/team`은 사람이 직접 봐야 한다. 둘 다 Claude Code **시작 시** 읽힌다.

1. 상태바가 2줄 OMC HUD로 나오고 게이지가 `[██░░░░░░]` 모양인지, 폭이 밀리지 않는지
2. `/team 2:executor "FeeCalculatorTest 실패를 고쳐라"` 가 동작하는지 — 하나로 agent teams 확인과 첫 연습 과제가 같이 된다

## 해결된 것 — 기록

### 개인 PC — JDK 21이 `java`로 잡히지 않던 문제 (2026-11-12 해결)

Microsoft OpenJDK 21.0.13(`C:\Java\jdk-21.0.13.0.2+1`)과 Maven 3.9.16(`C:\Java\apache-maven-3.9.16`)을 설치하고 사용자 환경 변수(`JAVA_HOME`, `Path` 앞쪽)에 등록했는데도 `java -version`이 17로 나왔다.

원인: **시스템 `Path`**에 `C:\Java\jdk-17\bin`이 있었다. Windows는 시스템 `Path`를 사용자 `Path`보다 앞에 둔다. (처음 조사 때 `[Environment]::GetEnvironmentVariable('Path','Machine')`로는 보이지 않아 놓쳤다 — 레지스트리를 `GetValue(..., 'DoNotExpandEnvironmentNames')`로 직접 읽어야 했다.)

조치: 관리자 권한으로 시스템 `Path`의 그 항목을 `C:\Java\jdk-21.0.13.0.2+1\bin`으로 바꿨다. 바꾸기 전 값은 `C:\Users\User\machine-path-backup.txt`. 새로 읽은 셸에서 `java -version` = 21.0.13 확인. 이미 떠 있던 프로그램(Zed 등)은 로그아웃·재로그인 후 반영된다.

Maven은 그 전에도 `JAVA_HOME`을 따라 JDK 21로 돌았다. JDK 17 폴더는 지우지 않았다.

### 사내망 PC — Gitea 원격 전환 (2026-11-12 완료)

번들 시점(`079f999`)에 멈춰 있던 저장소를 Gitea `origin`으로 전환했다. 사내망에서 `222.112.172.253:9080`으로 clone·fetch·push가 되는 것을 실측했다(커밋 `f0948af`). 처음 쓰던 `gitea.msjin.workers.dev` 주소는 더 이상 쓰지 않는다.

### HUD 게이지 — 래퍼 스크립트

게이지가 `[##------]`로 나오던 것을 `[██░░░░░░]`로 되돌렸다. 사용법은 [CLAUDE.md의 "HUD 게이지"](CLAUDE.md#hud-게이지)에 있다.

- 스크립트: `tools/omc-hud-gauge.mjs`
- 설치 위치: `~/.claude/hud/omc-hud-gauge.mjs` — 세션 시작 hook이 저장소 버전을 복사한다. 프로젝트 `.claude/settings.json`의 `statusLine.command`가 이걸 가리킨다

원인은 `dist/hud/sanitize.js`의 `replaceUnicodeBlocks()`가 설정·터미널 감지 없이 `█`→`#`, `░`→`-`로 무조건 치환하는 것이었다. 공식 설정으로는 끌 수 없어 출력을 후처리한다.

**아직 눈으로 확인 못 한 것:** `█`(U+2588)·`░`(U+2591)은 동아시아 환경에서 **폭이 모호한(Ambiguous) 문자**다. 한국어 로케일 터미널이 2칸으로 그리면 게이지 폭이 밀린다 — OMC가 ASCII로 바꾼 진짜 이유가 이것이다(`sanitize.js` 주석, issue #346). 밀리면 프로젝트 `.claude/settings.json`의 `statusLine.command`에서 `omc-hud-gauge.mjs`를 `omc-hud.mjs`로 되돌린다.

## 다른 PC에서 이어가기

절차는 [CLAUDE.md의 "다른 PC로 옮기기"](CLAUDE.md#다른-pc로-옮기기)에 있다. 요약하면:

1. 받는 PC: `git clone http://222.112.172.253:9080/msjin-claude-lab/cp_workspace.git D:/dev/workspace` — 공개 저장소라 clone·pull은 로그인 없이 된다
2. push는 **Gitea에만** 한다. 처음 push할 때 Gitea 계정 이름 + 액세스 토큰으로 로그인한다. GitHub는 Gitea 푸시 미러가 맞춘다
3. 작업 중에는 정시 구간마다 sync-check hook이 Gitea와 비교해 pull/push 여부를 묻는다. 마칠 때는 이 문서를 갱신하고 push한다
4. Claude Code 설정은 저장소에 있다. 새 PC에서 한 번 할 일(로그인, OMC·JDK·Maven 설치, Gitea 토큰)은 [CLAUDE.md의 표](CLAUDE.md#저장소에-들어-있지-않은-것--새-pc에서-한-번)를 따른다

Gitea에 접근할 수 없으면 CLAUDE.md의 "예비 수단 — git bundle"을 쓴다.

새 세션은 이렇게 시작하면 된다:

```
D:\dev\workspace 에서 작업을 이어서 한다. HANDOFF.md 를 읽고 시작해라.      (개인 PC)
D:\cp_workspace 에서 작업을 이어서 한다. HANDOFF.md 를 읽고 시작해라.      (사내망 PC)
```
