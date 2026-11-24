# 단어 늘리기 2차 — 중등 700개 (CEFR-J 기준)

상태: **승인됨**(2026-11-24 사내망 PC, 사용자 — `/oh-my-claudecode:plan` 인터뷰 → critic REVISE → 재검토 APPROVE)

1차 [plan-words-phase1.md](plan-words-phase1.md)와 같은 방식이다. 선정 규칙·자료·이용 조건은 [wordlist/README.md](wordlist/README.md). 기준 커밋(작업 전): **`e45b1c3`**.

## 요구 요약 (사용자 결정, 2026-11-24)

1. 중등은 **700개**, 칸마다 **234 · 233 · 233**(쉬움 · 중간 · 어려움). 기존 중등 150개(`me-`·`mm-`·`mh-`)는 지우고 CEFR-J로 바꾼다(2026-11-23 결정 — "그 칸의 기존 50개씩을 지우고 CEFR-J로", 옛 번호 기록을 지우는 DB 판도 함께)
2. 후보 = **초등에 들어가지 않은 A1 + A2**. A1을 먼저 넣고 A2로 채운다. 남는 A2는 고등(3차) 차례에 쓴다
3. 초등에서 `x`로 뺀 A1 59개 중 **어린이 앱에 부적절한 9개만 계속 뺀다**(`tiers.csv` 이유 "어린이 앱에 부적절"). 파생어·뜻이 같은 말·고유 이름 등 나머지는 중등 후보로 되살린다
4. 난이도 = **단계(Claude가 매기고 검토) → 빈도 순위 → 알파벳**(1차와 같음)
5. 뜻·예문·해석은 Claude가 새로 쓰고 칸마다 검토 에이전트가 본다. **사람 확인은 칸마다 무작위 20줄(60줄)**

## 코드·자료에서 확인한 사실 (2026-11-24, critic이 다시 확인)

- 후보 수(초등 800 뺀 뒤, 기능어·약어·두 단어 표제어 뺌): A1 **164**(초등 단계를 매겼으나 줄 끝에 남은 71 + `x` 59 + 중등 칸에 있어 1차 후보에서 빠졌던 34) · A2 1,182 · B1 2,082 · B2 2,386
- 기존 중등 150 = A1 34 · A2 89 · B1 24 · B2 3(`docs/wordlist/overlap.csv`) → 지우므로 그 A1·A2는 다시 후보가 된다. 기존 고등 150 = A2 13 · B1 58 · B2 46 + 목록에 없음 33 → **3차까지 남으므로 중등 후보에서 뺀다**(영단어는 앱 전체에서 한 번만 — `test/data/word_assets_test.dart:93-102`)
- 쓸 수 있는 후보 = A1 155(164 − 부적절 9) + A2 1,169(1,182 − 고등 13) = **1,324** ≥ 700. 실제로 들어가는 A2는 545개
- `tool/wordlist/select.py`는 초등 전용이다: 초등 후보를 **지금 단어 파일**의 중등·고등 단어로 거른다(`others`, `:119-125`·`:204`·`:211`), `tiers.csv`와 후보가 정확히 맞아야 한다(`:236-240`), 산출 `excluded.csv`·`overlap.csv`·`candidates.csv`·`elementary.csv`를 덮어쓴다
- `tool/wordlist/cells.py check`는 파일 전체가 csv와 같은지 본다(`:55`), 빈 필드를 막는다(`:63`)
- 개수 검사 `test/data/word_assets_test.dart:12-21`(`_expectedCount`), 묶음 중 범위 검사 `:42` `inInclusiveRange(50, expected)`, 번호 형식 `:29`(`w-0801`~`w-1500` 통과), 같은 칸 뜻 겹침 `:49-63`(쉼표로 나눈 낱말이 **글자까지 같을 때만** 잡음)
- DB `lib/data/study_records.dart:165` `schemaVersion = 8`, `:231` `_upgradeToV8`. `test/data/study_records_test.dart`는 중등 번호를 69줄에서 쓰고, `:166-189`(1판에서 올림)는 `mm-002`가 남는다고, `:412-482`(7→8)는 `getVersion() == 8`과 `me-001`·`mh-033`·`mm-007`이 남는다고 본다. 도우미는 `createV7`까지
- 유사어 쌍 시험(`test/data/similar_words_test.dart:27-39`)은 쌍의 두 단어가 같은 칸에 있어야 한다
- 앱 정보 화면 문구 "초등 단어의 선정과 난이도 구분은…"(`lib/features/about/about_screen.dart:49`, `:59`)

## 설계 결정

- **줄 세우기(요구 2·4를 함께)**:
  - 뽑기: 단계가 `x`가 아닌 A1 전부 + A2를 `(단계, 빈도 순위, 알파벳)` 순으로 세워 700개가 될 때까지
  - 칸 배정: 뽑힌 700개를 `(난이도, 빈도 순위, 알파벳)`으로 세워 앞에서부터 234 · 233 · 233. 수준(A1/A2)은 뽑기에만 쓰고 칸 배정에는 쓰지 않는다
  - **난이도 열(2026-11-24 사용자 결정 "칸 배정을 난이도 위주로")**: 처음에는 칸도 `(단계, 빈도)`로 나눴으나, 어려움 칸이 빈도가 낮은 쉬운 구체 명사(mushroom·mug·pea)로 찼다. 단계는 **뽑기**(어떤 단어를 넣나), `tiers-middle.csv`의 새 열 `difficulty`(1 · 2 · 3)는 **칸 나누기**(실제로 얼마나 어려운가 — 추상어·격식어·복잡한 동사는 3, 구체 명사는 빈도가 낮아도 1~2)에 쓴다. `x`가 아닌 줄은 모두 `difficulty`가 있어야 한다
  - 단계는 **후보 1,333개 전부**에 매긴다(쓸 수 있는 1,324 + 부적절 9개 — 9개는 스크립트가 후보로 내고 단계 파일에서 `x`. 1차 판정 `select.py:236-240`과 같게 — 단계 파일과 후보가 정확히 맞아야 한다)
- **다시 만들어도 같은 결과**: 초등 단계는 거를 단어(`others`)를 지금 단어 파일이 아니라 커밋된 `overlap.csv`의 중등·고등 줄(1차 작업 시점)에서 읽는다. 중등 단계는 `elementary.csv`·`overlap.csv`의 고등 줄에서 읽는다. 단계별 산출물은 이름을 나눈다: `candidates-middle.csv`, `tiers-middle.csv`, `middle.csv`. 초등 단계는 `overlap.csv`를 다시 쓰지 않는다. 3차(고등)도 같은 규칙: 앞 단계의 csv에서 읽고 자기 이름의 파일만 쓴다
- **번호**: `middle.csv` 순서대로 `w-0801`~`w-1500`

## 단계

### 1. 선정 스크립트를 학교급마다 돌게 넓힌다
- `select.py --stage elementary|middle`(기본 elementary), 위 "다시 만들어도 같은 결과" 규칙대로. 중등 검사: 칸 개수, 중복, 초등·고등과 겹침 0, 단계 파일과 후보가 정확히 맞음
- `cells.py --stage elementary|middle`. `check`는 파일이 csv의 **앞부분**과 같으면 통과(`entries == plan[cell][:len(entries)]`) — 묶음 중에도 쓸 수 있게. `check --full`은 끝까지 같아야 통과(개수까지) — 4단계 마지막과 6단계에서 쓴다
- 두 파일의 머리 설명, README "만드는 법" 명령과 파일 표를 고친다
- 완료 기준: `python tool/wordlist/select.py --stage elementary --cefrj D:/dev/tmp/wordlist/CEFRJ_wordlist_ver1.6.zip --freq D:/dev/tmp/wordlist/frequency-alpha-alldicts.txt && git diff --exit-code -- 'docs/wordlist/*.csv'` 종료 코드 0(README 변경은 csv가 아니라 이 비교에 들지 않는다)

### 2. 중등 단계를 매긴다
- Claude가 후보 1,333개마다 단계 1 · 2 · 3 · x를 이유와 함께 `tiers-middle.csv`에(기준: 한국 중학교 1~3학년이 배우는 순서, 부적절 9개는 `x`). `code-reviewer`가 단계표를 본다
- `select.py --stage middle --freq …` → `middle.csv` 700줄, 검사 통과(종료 코드 0)
- 사용자 확인: **칸마다 표본 20개**(1차와 같음)와 `x` 목록

### 3. 시험·DB를 먼저 바꾼다 (단어를 넣기 전)
- `word_assets_test.dart`: 중등 기대값 234 · 233 · 233, 머리 주석의 "중등 50". 묶음 중 스위치(`_filling`, `:41-42` — 지금은 9칸 전체에 걸림)를 **칸별로** 바꾼다: 묶음 중에는 중등 3칸만 `0 ~ 기대값`, 초등·고등은 늘 정확히 기대값
- DB 9판: `schemaVersion = 9`, `_upgradeToV9`(`me-`·`mm-`·`mh-`의 `study_log`·`quiz_log`·`wrong_notes` 줄 삭제), `onCreate`·`schemaVersion` 설명 주석(`study_records.dart:152-165`)
- `study_records_test.dart`: `createV8` 도우미를 더하고, 7→8 시험은 8판에서 멈춰 확인하게, 옛 판에서 올리는 시험의 중등 견본 번호는 `he-`나 `w-`로. 새 8→9 시험: 중등 옛 줄만 지워지고 초등·고등 줄은 그대로, 중등 칸으로 만든 단어장의 `deck_N` 기록 줄도 지워지고 `study_decks` 행은 남는다
- 완료 기준: `flutter analyze` 문제없음 `&&` `flutter test` 통과
- **3단계 커밋부터 4단계가 끝날 때까지 기기에 설치하지 않는다**(9판이 아직 화면에 있는 옛 중등 단어의 기록을 지운다)

### 4. 뜻·예문·해석을 쓴다 (700개)
- **첫 커밋에서 옛 중등 150개를 지운다**(세 파일을 빈 목록으로 두고 첫 묶음부터 넣는다)
- 칸마다 50~70개 묶음으로 `executor`가 쓰고, 묶음마다 `code-reviewer`가 그 칸 전체를 본다(뜻 정확성, 중등 수준 예문, 같은 칸 안에서 뜻이 사실상 겹치는 쌍, 예문이 그 단어를 실제로 쓰는지)
- 작성 규칙: **같은 칸 안에서 쉼표로 나눈 뜻 낱말은 글자까지 달라야 한다**(mommy·mum이 같은 칸이면 둘 다 "엄마"로 쓰지 않는다). 그래도 뜻이 사실상 같은 쌍은 두 단어가 같은 칸에 들어간 **같은 커밋에서** `similarWordPairs`에 더한다
- 묶음마다 `python tool/wordlist/cells.py --stage middle check && flutter test test/data/word_assets_test.dart test/data/similar_words_test.dart && git commit`(`wip:`)
- 마지막 묶음 뒤 범위 검사 스위치를 끄고(정확히 기대값) `cells.py --stage middle check --full`

### 5. 사람 표본 확인
- 칸마다 무작위 20줄을 보여 주고 고칠 것을 `docs/wordlist/review-fixes-middle.txt`로 받아 `cells.py --stage middle fix`로 적용

### 6. 검증하고 기록한다
- `select.py --stage elementary`와 `--stage middle`을 1단계 완료 기준과 같은 `--cefrj … --freq …`로 다시 돌린 뒤 `git diff --exit-code -- 'docs/wordlist/*.csv'`, 이어서 `cells.py --stage elementary check --full && cells.py --stage middle check --full`
- `flutter analyze` `&&` `flutter test` `&&` `flutter build apk --debug`([../VERIFY.md](../VERIFY.md))
- 초등·고등 번호가 그대로인지: `e45b1c3`의 `id → 영단어` 쌍(초등 800 + 고등 150)이 작업 뒤에도 같은지 스크립트로 비교
- `/oh-my-claudecode:review` 두 축 검토
- 에뮬레이터 확인(개인 PC에서만 — `projects/apps/CLAUDE.md` "PC 역할"): 기기 DB 백업 → 덮어 설치 → 8 → 9판 이행, 중등 단어장 홈 `234단어`, 카드·시험이 열림. 사내망 PC에서 끝내면 인계에 "에뮬레이터 확인 안 함, 개인 PC에서 필요"
- 문서: `HANDOFF.md`, `VERIFY.md`, `docs/wordlist/README.md`(2차 규칙·파일 표), 앱 `CLAUDE.md` 첫 줄, `docs/spec.md`의 개수, 앱 정보 화면 문구(`about_screen.dart:49`, `:59` — "초등" → 초·중등)와 그 시험

## 완료 기준 (전체)

- 중등 3칸이 234 · 233 · 233개, 번호 `w-0801`~`w-1500`, 영단어는 9칸 전체에서 한 번만
- `select.py` 두 단계 모두 다시 돌려도 `git diff --exit-code -- 'docs/wordlist/*.csv'` 통과, `cells.py` 두 단계 `check --full` 통과
- DB 9판 이행 시험 통과, `flutter analyze`·`flutter test`·`build apk` 통과
- 사람 표본 60줄 확인과 두 축 검토를 받았다

## 위험과 대응

- **초등 결과가 바뀐다**: 1·6단계 모두 `git diff --exit-code docs/wordlist/`로 막는다
- **같은 칸 안 유사어**(뜻이 같은 말도 넣기로 함): 뜻 글자를 다르게 쓰는 작성 규칙 + `cells.py check`·시험의 같은 칸 뜻 겹침 검사 + 검토 항목 + `similarWordPairs`
- **중등 단어장 기록이 사라진다**: 사용자 결정. 3~4단계 동안 기기에 설치하지 않고, 개인 PC 확인 전 DB 백업
- **남는 A2가 3차와 겹친다**: 3차 계획에서 다룬다

## 이번 범위가 아닌 것

- 고등 1,500 + 심화(3차), 기존 고등 150개 교체
- 처음 설치 시작 화면 기기 확인(사용자 결정 — 고등 작업 종료 뒤까지 보류)
- 두 기관(평가원·교육부) 답에 따른 조정

## 검토 반영 기록

- 2026-11-24 critic REVISE 9건 모두 반영: 초등 재생성이 중등 변경 뒤 깨짐(고정 기준에서 읽기 + 산출물 이름 나눔), `cells.py check` 앞부분 비교 + 옛 150개 삭제 시점 + 하한, DB 9판이 깨는 기존 시험과 `createV8`, 줄 세우기 식과 단계 범위, 숫자(A1 34 · 164 · 155 · 1,324), 고칠 문서(앱 정보 문구 등), 같은 칸 뜻 글자 규칙, 기준 커밋 `e45b1c3`, 3~4단계 사이 설치 금지
- 2026-11-24 critic 재검토 **APPROVE**(지난 9건 해결 확인, overlap.csv의 중등·고등 300개가 지금 파일과 같아 초등 재현됨을 확인). MINOR 5건 반영: 단계 파일 1,333줄(부적절 9개 `x` 포함), diff를 csv로 좁힘, 명령에 `--freq`, `check --full`, 묶음 중 하한 0은 중등 칸만
