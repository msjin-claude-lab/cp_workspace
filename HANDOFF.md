# 이어서 작업하기

마지막 갱신: 2026-11-11

워크스페이스 구성은 끝났다. 이 문서는 **다음에 이어서 할 일**과 **중단된 작업의 조사 결과**만 담는다.
환경 사실·규칙은 [CLAUDE.md](CLAUDE.md), 연습 과제는 [projects/loan/PRACTICE.md](projects/loan/PRACTICE.md)에 있다.

## 지금 상태

| 항목 | 상태 |
|---|---|
| 워크스페이스 구성 | 완료 (커밋 `7703204`, `caabcb0`) |
| OMC | npm 전역 5.8.4, 글로벌·로컬 `CLAUDE.md` 모두 설치됨 |
| 연습 프로젝트 | `projects/loan/` — 결함 심어둔 상태 그대로, 고친 것 없음 |
| `mvn -q test` | **14개 중 13개 통과, 1개 실패가 정상** |

마지막으로 실제 실행해 확인한 실패:

```
FeeCalculatorTest.chargesOnlyDaysBeyondGrace:41  expected: <1000> but was: <2500>
```

유예기간(grace) 이후 일수만 과금해야 하는데 전체 일수를 과금하고 있다.

## HUD 게이지 — 해결됨 (래퍼 스크립트)

게이지가 `[##------]`로 나오던 것을 `[██░░░░░░]`로 되돌렸다. 사용법은 [CLAUDE.md의 "HUD 게이지"](CLAUDE.md#hud-게이지)에 있다.

- 스크립트: `tools/omc-hud-gauge.mjs` (저장소에 있으므로 번들에 실린다)
- 설치 위치: `~/.claude/hud/omc-hud-gauge.mjs`, `settings.json`의 `statusLine.command`가 이걸 가리킨다

원인은 `dist/hud/sanitize.js`의 `replaceUnicodeBlocks()`가 설정·터미널 감지 없이 `█`→`#`, `░`→`-`로 무조건 치환하는 것이었다. 공식 설정으로는 끌 수 없어 출력을 후처리한다.

**아직 눈으로 확인 못 한 것:** `█`(U+2588)·`░`(U+2591)은 동아시아 환경에서 **폭이 모호한(Ambiguous) 문자**다. 한국어 로케일 터미널이 2칸으로 그리면 게이지 폭이 밀린다 — OMC가 ASCII로 바꾼 진짜 이유가 이것이다(`sanitize.js` 주석, issue #346). 재시작 후 상태바에서 폭이 밀리지 않는지 볼 것. 밀리면 `statusLine.command`를 `omc-hud.mjs`로 되돌린다.

## 재시작 후 확인할 것

HUD 상태바와 agent teams는 **Claude Code 시작 시** 읽힌다. 이 PC에서 아직 확인 못 했다:

1. 상태바가 2줄 OMC HUD로 나오는지
2. `/team 2:executor "FeeCalculatorTest 실패를 고쳐라"` 가 동작하는지 — 하나로 둘 다 확인된다

## 다른 PC에서 이어가기

절차는 [CLAUDE.md의 "다른 PC로 옮기기"](CLAUDE.md#다른-pc로-옮기기)에 있다. 요약하면:

1. 받는 PC: `git clone https://gitea.msjin.workers.dev/msjin-claude-lab/cp_workspace.git D:/dev/workspace` (Gitea 계정 + 액세스 토큰으로 로그인)
2. 작업 전 `git pull`, 작업 후 `git push`
3. `~/.claude/` 전역 설정은 저장소에 없으므로 CLAUDE.md의 표대로 새 PC에서 따로 맞춘다

Gitea에 접근할 수 없으면 CLAUDE.md의 "예비 수단 — git bundle"을 쓴다.

새 세션은 이렇게 시작하면 된다:

```
D:\dev\workspace 에서 작업을 이어서 한다. HANDOFF.md 를 읽고 시작해라.
```
