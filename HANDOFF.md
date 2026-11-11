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

## 중단된 작업 — HUD 게이지를 블록 문자로 되돌리기

**증상:** 상태바 게이지가 `[##------]`처럼 ASCII로 나온다. Claude Code 기본 상태바가 쓰던 `[████░░░░░░]` 같은 모양을 원한다.

**원인 (조사 완료):** OMC가 설정이나 터미널 감지 없이 **무조건** 치환한다.

`node_modules/oh-my-claude-sisyphus/dist/hud/sanitize.js:53`

```js
export function replaceUnicodeBlocks(text) {
  return text
    .replace(/█/g, '#')
    .replace(/░/g, '-')
    .replace(/▓/g, '=')
    .replace(/▒/g, '-');
}
```

렌더러(`dist/hud/colors.js:147`, `elements/context.js:113`, `elements/limits.js:258`)는 원래 `█`/`░`로 그린다. 출력 직전 `sanitizeOutput()`이 이 함수를 거치면서 ASCII가 된다.

**OMC가 그렇게 하는 이유** (`sanitize.js` 주석, issue #346): 가변폭 유니코드가 Claude Code의 Ink 렌더러와 겹치면 커서 위치 계산이 틀어져 터미널이 깨진다. `█`(U+2588)·`░`(U+2591)은 동아시아 환경에서 **폭이 모호한(Ambiguous) 문자**라 한국어 로케일 터미널에서 2칸으로 그려질 수 있다 — 이게 실제 위험이다.

**공식 설정으로는 못 바꾼다.** `omc hud`는 `--watch`/`--interval`만 받고, HUD 설정 스키마(`dist/hud/types.d.ts`)에도 게이지 문자 옵션이 없다. `callCountsFormat`은 이모지/ASCII 선택지가 있지만 게이지와는 무관하다.

**다음에 할 일 — 두 가지 방법 중 선택:**

1. **래퍼 스크립트** (권장) — `~/.claude/hud/` 아래에 omc-hud를 호출하고 출력만 후처리하는 스크립트를 두고, `settings.json`의 `statusLine.command`가 그것을 가리키게 한다. npm 업데이트에 지워지지 않는다.
   - 주의: `-`를 통째로 `░`로 바꾸면 안 된다. 브랜치명·모델 ID(`claude-opus-5`)·시간 표기에도 `-`가 쓰인다. **대괄호 안쪽만** 치환해야 한다 (`[`와 `]` 사이가 ANSI 코드와 `#-=`로만 이루어진 구간).
2. **패키지 직접 수정** — `dist/hud/sanitize.js`를 고친다. 간단하지만 `npm i -g` 할 때마다 날아간다.

**검증:** 바꾼 뒤 실제 한국어 로케일 터미널에서 게이지 폭이 밀리지 않는지 눈으로 볼 것. 밀린다면 OMC가 ASCII로 바꾼 판단이 옳았던 것이니 되돌린다.

## 재시작 후 확인할 것

HUD 상태바와 agent teams는 **Claude Code 시작 시** 읽힌다. 이 PC에서 아직 확인 못 했다:

1. 상태바가 2줄 OMC HUD로 나오는지
2. `/team 2:executor "FeeCalculatorTest 실패를 고쳐라"` 가 동작하는지 — 하나로 둘 다 확인된다

## 다른 PC에서 이어가기

절차는 [CLAUDE.md의 "다른 PC로 옮기기"](CLAUDE.md#다른-pc로-옮기기)에 있다. 요약하면:

1. 보내는 PC: `git bundle create cp-workspace.bundle --all`
2. 받는 PC: `git bundle verify cp-workspace.bundle` → `git clone cp-workspace.bundle cp-workspace`
3. `~/.claude/` 전역 설정은 번들에 없으므로 CLAUDE.md의 표대로 새 PC에서 따로 맞춘다

새 세션은 이렇게 시작하면 된다:

```
D:\cp-workspace 에서 작업을 이어서 한다. HANDOFF.md 를 읽고 시작해라.
```
