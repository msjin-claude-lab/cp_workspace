# 단어 늘리기 4차 — 심화 3,613개에서 뺄 것을 뺀 전부 (CEFR-J 남은 B1 + B2)

상태: **승인됨 — 실행 중**(2026-11-25 사내망 PC — `/oh-my-claudecode:plan` 인터뷰로 작성 → critic REVISE 반영 → 재검토 APPROVE → 사용자 승인 "1단계부터 시작". 어디까지 했는지는 [../HANDOFF.md](../HANDOFF.md) 인계)

앞 차수: [1차 초등 800](plan-words-phase1.md) · [2차 중등 700](plan-words-phase2.md) · [3차 고등 1,500](plan-words-phase3.md)("4차의 자리"가 이 문서의 출발점)

## 요구 요약 (사용자 결정)

1. **규모는 전부** — 3차에 들지 않은 B1 1,227 + B2 2,386 = **3,613개**에서 `x`를 뺀 것 전부(2026-11-24). 뽑기(자르기)는 없다
2. **넷째 학교급, 화면 이름 "심화"**(2026-11-25). 쉬움 · 중간 · 어려움 3칸, 칸당 약 1,200개(2026-11-24)
3. **gay · suicide · sex · bust는 넣지 않는다(`x`)**(2026-11-25). 3차의 "술·담배·폭력·연애 말은 빼지 않는다"는 그대로 — B2에서 나오는 성·자살 관련 말·욕설과 `naked`는 `x` **후보 목록**으로 보여 주고 사용자가 정한다(목록에 올리는 범위는 Claude 해석)
   - **2단계 사용자 확인 ①(2026-11-25): 후보 25개는 "다 넣는다"** — 성 관련 sexual · sexy · rape · sexism · naked / 욕설·비속어 damn · bum · bloody · hell · suck · pee · prick · daft / 비하로 쓰일 수 있는 말 gook · retard · cripple · queer · tramp · dumb · idiot · lame · freak · dwarf · ghetto / 지명에나 남은 말 ness. **`x`는 넷뿐이다**(N = 3,609, 칸 크기 1,203 × 3). 4단계에서 이 말들의 뜻은 사전의 중립적인 뜻으로 쓰고, 비하·욕설로 쓰이는 말은 뜻에 그 사실을 밝힌다(Claude 해석 — 5단계 사람 표본에 이 25개를 따로 넣어 보여 준다)
4. **고등에서 빠진 쉬운 일상어(약 320개)는 심화 "쉬움" 칸 맨 앞**에 모으고, 화면 설명에 "고등 이전에 놓친 쉬운 말"임을 적는다(2026-11-24)
5. **작성·검토는 3차와 같게**(2026-11-25): 100개 묶음마다 검사·`wip:` 커밋·push, 에이전트 검토는 300개마다, 사람 확인은 칸마다 무작위 20줄(60줄)
6. 뜻·예문·해석은 Claude가 새로 쓰고(CEFR-J에는 없다) 검토 에이전트가 본다 — 1~3차와 같다

## 확인한 사실 (2026-11-25, 커밋 `ce9b57a`)

- **후보 수**: `candidates-high.csv`의 B1 2,081줄 중 `high.csv`에 없는 줄 1,227(`tiers-high.csv`에서 단계 3이 991 · 4가 236, 난이도 1이 444 · 2가 428 · 3이 119 · 빈칸 236). B2는 2,386 — critic이 원본과 `select.py`의 함수로 셌다(빈도 자료에 없는 B2 37개: X-ray · pH · cyberpet 등 — 빈도 순서에서 맨 뒤로 간다). 남은 A1·A2는 0개. 1단계에서 스크립트 출력으로 다시 확인한다
- 넣지 않기로 한 넷의 지금 줄: `tiers-high.csv:350` bust(단계 4) · `:1067` gay · `:2195` sex · `:2377` suicide(단계 3). `:1587` naked(단계 3). B2에서 `x` 후보로 오를 말(critic이 찾음): rape · sexual · sexy · sexism · damn · hell
- 원본 두 파일은 **사내망 PC에도 있다**: `D:\dev\tmp\wordlist\CEFRJ_wordlist_ver1.6.zip` · `frequency-alpha-alldicts.txt` — SHA-256이 `select.py`의 `EXPECTED_SHA256`과 같다(critic 확인). 두 주소 모두 이 PC에서 HTTP 200(머리만 요청해 확인 — README `:20`의 "사내망 PC에서는 못 받는다"는 낡았다)
- `tool/wordlist/select.py`: `--stage` 선택지 `elementary|middle|high`(`:504`), 학교급마다 함수(`high` `:405-497`). 고등 후보는 `A1·A2·B1`에서 초등·중등을 뺀 것(`:415-416`), 단계 허용값 `1·2·3·4·x`(`:436`), 칸 크기는 상수 `HIGH`(`:418`·`:488`), 줄 검사 `check_rows`(`:235`), 단계 파일 읽기 `read_tiers`(`:188`)
- `tool/wordlist/cells.py`: `STAGES`(`:42-45`)가 학교급마다 (기준 csv, 앞선 csv들)를 갖는다. **번호는 기준 csv의 줄 순서로 붙는다**(`:59`·`:68`). `check`는 채운 파일의 번호·영단어·순서가 csv와 다르면 막고(`:104-106`), `fix`는 뜻·예문·해석만 고친다(`:143` — 영단어·번호는 못 고친다). 빈 파일 `[]`은 `check`를 통과한다
- `lib/data/cell.dart`: `SchoolLevel` 3값(`:2-10`), `Cell` 9값(`:84-93`), 화면 이름 `'${level.label} [난이도 : ${difficulty.label}]'`(`:107`), 파일 `assets/words/$id.json`(`:109`). `pubspec.yaml:70`은 폴더를 통째로 넣는다 — 파일을 더해도 pubspec은 그대로
- 학교급을 늘리면 자동으로 따라오는 곳: 학교급 고르기(`lib/features/home/home_screen.dart:204`), 경로(`lib/router.dart:38`). `lib/`에서 `Cell.values`를 쓰는 곳은 없다
- 고르기 버튼 `_PickButton`은 `Row(Expanded(이름), Text(설명))`이고 설명은 줄바꿈하지 않는다(`home_screen.dart:151-155`). 난이도 버튼의 설명은 지금 `N단어`뿐이다(`:291-299`)
- 시험: 칸별 기대 개수 `_expectedCount`(`test/data/word_assets_test.dart:14-23`), 묶음 중 스위치 `_filling`(`:30`), 번호 형식 `^w-\d{4}$`(`:34`). "칸은 9개"(`test/data/word_repository_test.dart:27`·`:32`). `similar_words_test.dart:30-31`은 `Cell.values`마다 파일을 읽는다(파일이 없으면 깨진다). `test/widget_test.dart:118`이 `SchoolLevel.values`를 돌고, 화면 시험의 단어는 `FakeRepository`(`:29-40`)가 준다
- 유사어 쌍은 지금 545쌍(`lib/data/similar_words.dart`), 같은 칸 안의 쌍만 둔다
- **DB 판을 올릴 이유가 없다**(critic이 코드로 확인): `migrateLegacy`(`lib/data/study_decks.dart:147-187`)는 옛 저장값에서 `Cell.byId`로 찾은 칸만 받는데 옛 판에는 `advanced_*` 값이 있을 수 없다. `decks()`(`:64`)는 모르는 칸을 건너뛴다(옛 APK로 되돌려도 기록이 남는다). `study_records.dart`는 `Cell`을 쓰지 않는다. `study_decks.dart:10`은 옛 기록을 옮길 때 쓰는 단어장 이름이다
- 사내망 PC: 시험이 쓰는 `sqlite3.dll`이 `.dart_tool/hooks_runner/shared/sqlite3/build/download-643956b0/`에 있다. Android용 `libsqlite3.*.android.so` 4개도 `download-*/`에 있으나(11-24) `build apk`가 되는지는 아무도 확인하지 않았다. 이 PC에서 `flutter test`를 오늘 돌려 보지는 않았다

## 정한 설계

- **이름**: 스크립트 단계 `advanced`, `SchoolLevel.advanced('심화')`, 칸 `advancedEasy|Medium|Hard`, 파일 `assets/words/advanced_easy|medium|hard.json`, 산출물 `candidates-advanced.csv` · `tiers-advanced.csv` · `advanced.csv`
- **후보**: CEFR-J의 `B1 · B2` 중 `elementary.csv` · `middle.csv` · `high.csv`에 없는 것. **B1 1,227 · B2 2,386 · 남은 A1·A2 0이 아니면 종료 코드 1**
- **단계(tier)는 뽑기에 쓰지 않는다** — 값은 셋뿐이다
  - `1` = 고등 이전에 놓친 쉬운 말(쉬운 구체 명사·사람·직업·자연·동물·파생 부사 등). **B1만**, **난이도는 반드시 1**, 쉬움 칸 맨 앞에 선다
  - `2` = 그 밖의 모든 말
  - `x` = 넣지 않음. gay · suicide · sex · bust는 **`x`가 아니면 종료 코드 1**. 그 밖의 `x`는 사용자가 확인한 것만. `x` 줄의 난이도는 비운다
- **난이도**(1 · 2 · 3, `x`가 아닌 모든 줄에 있어야 한다): `1` 일상·구체 말 · `2` 흔한 추상어와 B2의 일반 말 · `3` 추상·학술·격식 말, 뜻이 여럿인 말. 수준(B1/B2)으로 강제하지 않는다 — 3차 때의 값을 가져오지 않고 심화 기준으로 다시 매긴다
- **칸 배정**: `x`가 아닌 N개를 `(난이도, 단계, 빈도 순위, 알파벳)`으로 세워 앞에서부터 `⌈N/3⌉ · … · ⌊N/3⌋`(나머지는 앞 칸부터 하나씩 — 초등 267 · 267 · 266과 같은 방식). 단계 1은 난이도 1이라 늘 맨 앞에 선다. **단계 1의 수가 쉬움 칸 크기를 넘으면 종료 코드 1**
- **번호**: `advanced.csv` 순서대로 `w-3001`부터(최대 `w-6613` — 네 자리 형식 그대로)
- **목록은 2단계 끝에 고정한다**: 번호와 칸 경계가 `advanced.csv`의 줄 순서에서 나오므로, 단어 하나가 `x`로 바뀌면 그 뒤 번호가 모두 하나씩 밀리고 칸 경계도 바뀐다. 그래서 `x`를 사용자가 확정한 **뒤에** `select.py`를 돌려 `tiers-advanced.csv` · `advanced.csv`를 커밋하고 "고정"이라고 적는다. 4단계부터는 이 두 파일을 고치지 않는다
  - 고정 뒤에 빼야 할 말이 나오면(4단계 검토·5단계 사람 표본) **멈추고 사용자에게 묻는다**. 빼기로 하면: `tiers-advanced.csv`에서 `x`로 → `select.py` 재실행 → 이미 쓴 항목을 영단어 기준으로 새 번호·새 칸에 다시 놓는 스크립트(뜻·예문·해석은 그대로) → `_expectedCount` 고치기 → 묶음 검사·시험 → 커밋. 넣지 않은 말을 지키는 시험은 `tiers-advanced.csv`의 `x` 줄을 직접 읽으므로 따로 고칠 목록이 없다
  - 이 절차는 **심화가 화면에 숨겨져 있어 기기에 기록이 없을 때만** 쓴다. 4차가 끝나 심화를 연 뒤에 단어를 바꾸려면 옛 번호 기록을 지우는 새 DB 판이 필요하다(HANDOFF "칸의 단어를 바꿀 때는 같은 삭제 단계를 새 판으로 더한다")
- **다시 만들어도 같은 결과**: 심화 단계는 커밋된 csv 셋과 단계 파일만 읽는다. 초등·중등·고등을 다시 돌려도 그 csv가 그대로여야 한다
- **DB 판은 올리지 않는다**(10판 유지 — 근거는 위 "확인한 사실")
- **덜 찬 칸은 코드로 숨긴다**(설치 금지 문구에 기대지 않는다): `hiddenLevelsProvider = Provider<Set<SchoolLevel>>((_) => {SchoolLevel.advanced})`를 두고, 학교급 고르기(`home_screen.dart:204`)가 `ref.watch`로 거르고 난이도 고르기(`DifficultyPickerScreen`)가 숨긴 학교급이면 `없는 학교급입니다`를 그린다(경로 빌더 `router.dart:38`에는 `ref`가 없어 화면 쪽에서 본다). 시험은 `overrideWithValue`로 바꿔 넣는다. 시험과 검사 도구는 `Cell.values`로 새 파일을 그대로 읽는다. **5단계(사람 표본)까지 끝난 뒤 6단계 첫 줄에서 비운다**(`_filling`은 4단계 끝에). 그동안 기기에 설치하거나 release 준비를 해도 심화는 보이지 않고, 4차를 중간에 멈춰도 앱은 지금과 같다
  - 숨기는 것은 고르기 화면뿐이다. `/study/advanced_easy` 같은 칸 주소는 `_withDeck`(`router.dart:99`)가 `Cell.byId`로 그대로 연다 — 앱 안에 그 주소로 가는 길이 없어 영향은 없다
- **화면 설명**: 심화 쉬움 버튼에만 이름 아래 작은 글씨로 둘째 줄 `고등 이전에 놓친 쉬운 말 포함`을 둔다(`_PickButton`에 선택 값을 하나 더한다). 오른쪽 설명은 다른 버튼과 같이 `N단어` 그대로이고, 둘째 줄은 단어를 읽는 중이거나 못 읽었을 때도 보인다. 한 줄에 `N단어 · …`로 이으면 폭 360 화면에서 넘친다(어림 270px, 쓸 수 있는 폭 약 264px)

## 단계

### 1. 선정 스크립트에 심화를 더한다
- `select.py --stage advanced`: 위 설계의 후보·단계·난이도·칸 배정과 검사(어긋나면 종료 코드 1) — 후보 수(B1 1,227 · B2 2,386 · A1·A2 0), 단계 파일과 후보가 정확히 맞음, 단계는 `1·2·x`만, 단계 1은 B1이고 난이도 1, 넣지 않기로 한 넷이 `x`, `x`가 아닌 줄의 난이도 `1·2·3`, 단계 1의 수 ≤ 쉬움 칸 크기, 중복 0, 초등·중등·고등과 겹침 0(`check_rows` 재사용). 출력: 후보 수, `x` 수, N과 칸 크기, 난이도 분포, 단계 1 개수
- `cells.py`의 `STAGES`에 `"advanced": ("advanced.csv", ("elementary.csv", "middle.csv", "high.csv"))`, 머리 설명
- `docs/wordlist/README.md`: 4차 규칙·파일 표, 빈도 파일을 사내망 PC에서도 받을 수 있다는 사실(`:20`)
- 완료 기준(사내망 PC에서 가능): `python tool/wordlist/select.py --stage elementary --cefrj <zip> --freq <txt> && … --stage middle … && … --stage high … && git diff --exit-code -- 'docs/wordlist/*.csv' && python tool/wordlist/select.py --stage advanced --cefrj <zip> --freq <txt>` 종료 코드 0(후보 3,613개는 스크립트가 검사한다)
- `select.py --stage advanced --partial`: 쓰는 중인 `tiers-advanced.csv`의 **쓴 줄만** 본다 — 단계 값 `1·2·x`, 난이도 값, 후보에 있는 말인지, 중복. 어긋나면 종료 코드 1(`advanced.csv`는 쓰지 않는다)
- 끝나면 커밋·push, 인계 갱신

### 2. 단계와 난이도를 매기고 목록을 고정한다
1. `executor`가 `tiers-advanced.csv`(단어, 단계, 이유, 난이도)를 쓴다 — 3,613줄을 500~700줄씩 **차례로 이어 쓴다**(한 파일이라 동시에 쓰지 않는다). 이어 쓸 때마다 `select.py --stage advanced --partial …`이 종료 코드 0인 것을 보고 `wip:` 커밋·push와 인계 갱신(몇 줄까지 썼는지). B1 1,227줄은 `tiers-high.csv`의 이유를 참고하되 단계·난이도는 새 기준으로 매긴다
2. `code-reviewer`가 **약 900줄씩 네 번에 나눠** 본다: 단계 1에 든 어려운 말·단계 1에서 빠진 쉬운 말, 난이도가 뒤집힌 줄, `x`로 올려야 할 말(욕설·성적 표현·자살 관련·비하 표현)
3. **사용자 확인 ①**: `x` 후보 목록(넣지 않기로 한 넷 + naked · rape · sexual · sexy · sexism · damn · hell + 검토가 올린 말 — 줄마다 넣을지 뺄지), 단계 1 개수와 예 20개
4. 답을 `tiers-advanced.csv`에 반영 → `select.py --stage advanced` → `advanced.csv`, 검사 통과(종료 코드 0)
5. **사용자 확인 ②**: 칸 크기·난이도 분포, 칸마다 표본 20개. 고칠 것이 있으면 4번으로 돌아간다
6. `tiers-advanced.csv` · `advanced.csv`를 커밋·push하고 이 문서와 인계에 **N과 칸 크기, "목록 고정"**을 적는다

**2단계 결과 — 목록 고정(2026-11-25 사내망 PC)**: `x` 4개(넷뿐) → **N = 3,609, 칸 크기 1,203 · 1,203 · 1,203**, 번호 `w-3001`~`w-6609`. 단계 1이 323개(모두 쉬움 칸), 난이도 1,290 · 1,315 · 1,004 — 쉬움 칸은 모두 난이도 1, 중간 칸은 난이도 1이 87 + 2가 1,116, 어려움 칸은 난이도 2가 199 + 3이 1,004(같은 난이도 안에서는 빈도가 낮은 말이 뒤 칸으로 간다). 사용자 확인: ① `x` 후보 25개 "다 넣는다" ② 칸마다 표본 20개(seed 20261125) "이대로 고정", 단계 1 표본 20개 "맞다".

계획과 다르게 한 것: ⓐ 단계표를 한 executor가 차례로 쓰지 않고 6덩이를 따로 쓴 뒤 덩이 순서대로 검사해 붙였다(한 파일을 동시에 고치지 않는 것과 덩이마다 `--partial` 검사·커밋은 같다) ⓑ 검토 뒤 300줄 구간마다 쉬움 비율이 20%~49%로 달라, 치우친 네 구간(1,501~1,800 · 2,401~2,700 · 3,001~3,613번째 줄)을 다른 구간에서 뽑은 기준 줄에 맞추는 작업을 더했다(324줄). 맞춘 뒤 구간별 쉬움 비율은 26%~43%, 어려움 비율은 23%~38%다 — 구간 사이 차이가 다 없어지지는 않았다

### 3. 코드와 시험을 먼저 바꾼다 (단어를 넣기 전)
- 먼저 이 PC에서 `flutter analyze && flutter test`가 지금 통과하는지 확인한다(안 되면 그것부터 고치거나 개인 PC로 넘긴다)
- `cell.dart`: `SchoolLevel.advanced('심화')`, `Cell` 세 값, 주석 "9칸" → 12칸(`:83`). `hiddenLevelsProvider`(위 설계)
- `home_screen.dart`: 학교급 고르기(`:204`)가 숨긴 학교급을 거르고, 난이도 고르기가 숨긴 학교급이면 `없는 학교급입니다`. `_PickButton`에 둘째 줄, 심화 쉬움 버튼에 문구
- 빈 단어 파일 셋(`[]`)을 만든다 — `cells.py skeleton`은 쓰지 않는다
- 시험
  - `word_assets_test.dart`: `_expectedCount`에 심화 세 칸(2단계에서 고정한 크기), `_filling` = 심화 3칸, **넣지 않기로 한 말이 12칸 어디에도 영단어로 없다**는 시험 — 목록은 `docs/wordlist/tiers-advanced.csv`의 `x` 줄을 직접 읽고, gay · suicide · sex · bust가 그 안에 있는지도 함께 본다
  - `word_repository_test.dart:27`·`:32`의 9 → 12
  - 화면 시험: ① 숨긴 동안 학교급 고르기에 `심화`가 없고 `/pick/advanced`가 `없는 학교급입니다` ② `hiddenLevelsProvider`를 빈 집합으로 바꿔 넣었을 때 `심화` → 난이도 화면의 쉬움 버튼에 둘째 줄이 보이고 **폭 360에서 넘침 오류가 없다**. `FakeRepository`에 심화 칸 단어를 더한다. `widget_test.dart:118` 주변이 넷째 학교급에서도 맞는지 확인
- 완료 기준: `flutter analyze && flutter test` 종료 코드 0. 커밋·push, 인계 갱신

**3단계 결과(2026-11-25 사내망 PC)**: 시험 177 → 180개(전체 통과는 구현한 executor의 보고다. 그 뒤 시험 한 줄을 고친 다음의 전체 재실행은 `flutter test` 도중에 사용자 지시로 멈췄고 `wip:`로 커밋했다 — **4단계를 시작하기 전에 `flutter analyze && flutter test`를 다시 돌린다**). `hiddenLevelsProvider`는 `cell.dart`가 아니라 `lib/data/word_repository.dart`에 뒀다(`cell.dart`는 riverpod를 쓰지 않는 데이터 파일이라 — 다른 데이터 provider가 있는 곳). 넣지 않은 말 시험은 `tiers-advanced.csv`의 `x` 줄을 읽고 넷이 들어 있는지 본다(`containsAll`). `study_records.dart`·`migrateLegacy`는 고치지 않았다. 폭 360 넘침은 화면 시험에서만 확인했다(기기 확인은 6단계)

### 4. 뜻·예문·해석을 쓴다
- **칸은 한 번에 하나씩**(쉬움 → 중간 → 어려움), 칸마다 **100개 묶음**(약 12개, 마지막 묶음은 나머지)
- 묶음마다: `python tool/wordlist/cells.py --stage advanced check && flutter test test/data/word_assets_test.dart test/data/similar_words_test.dart && git add assets/words/advanced_<칸>.json lib/data/similar_words.dart HANDOFF.md && git commit`(`wip:`, 경로를 밝혀서) 뒤 push. 묶음을 끝낼 때마다 인계에 어느 칸 몇 번까지 썼는지 적는다
- 검토: `code-reviewer`가 **묶음 3 · 6 · 9 뒤와 마지막 묶음 뒤**(칸당 4번, 그사이에 쓴 것 전부) 읽는다 — 뜻 정확성, 예문이 그 단어를 실제로 쓰는지, 예문 수준, 같은 칸 안에서 뜻이 사실상 겹치는 쌍. **마지막 검토는 칸 전체의 유사어 쌍**도 본다. 고칠 줄은 `docs/wordlist/review-fixes-advanced.txt`에 덧붙이고, **그 검토분만** 임시 파일로 `cells.py --stage advanced fix`에 넘긴다(쓰는 중인 executor가 없을 때만). `fix` 뒤에는 묶음과 같은 검사·시험을 돌리고 커밋한다. 검토가 "빼야 할 말"을 내면 위 "목록은 2단계 끝에 고정한다"의 절차대로 멈추고 묻는다
- 작성 규칙(3차와 같음): 같은 칸 안에서 쉼표로 나눈 뜻 낱말은 글자까지 달라야 한다. 뜻이 사실상 같은 쌍·어원이 같은 쌍은 두 단어가 같은 칸에 들어간 같은 커밋에서 `similarWordPairs`에 더한다
- 마지막 묶음 뒤: `_filling`을 비우고 `cells.py --stage advanced check --full && flutter analyze && flutter test`. 심화는 아직 숨긴 채 둔다(5단계에서 빼야 할 말이 나올 수 있다)

**4단계 결과(2026-11-25~27, 두 PC)**: 세 칸을 100개 묶음으로 executor가 쓰고 칸마다 code-reviewer 네 번(모두 COMMENT, 마지막 어려움 칸 검토 포함). 검토가 낸 뺄 말을 사용자가 고를 때마다 목록을 다시 만들어(`x` → `select.py` 네 단계 → 쓴 항목 번호 다시 놓기) **모두 81개를 더 빼 3,528개(1,176 · 1,176 · 1,176, `w-3001`~`w-6528`)**. 계획과 다른 점: 목록을 고정한 뒤에도 사용자 결정으로 여러 번 뺐고, 그때마다 칸 경계가 밀려 옮긴 말의 겹침을 Claude가 고쳤다. 끝에 `_filling` 비움, `check --full` 0건·analyze 문제없음·시험 180개.

### 5. 사람 표본 확인
- 칸마다 무작위 20줄(60줄)을 보여 주고 고칠 것을 `review-fixes-advanced.txt`로 받아 `fix`로 적용. seed와 사용자 답을 `HANDOFF.md` 진행 이력에 적는다

**5단계 결과(2026-11-27 사내망 PC)**: 칸마다 20줄(seed 20261127) → 사용자 "Claude가 짚은 3줄만 고치고 확정", 넣기로 한 민감한 말 25개(모두 심화에 있음)를 따로 보여 "dwarf만 고치고 확정".

### 6. 검증하고 기록한다
- **심화를 연다**: `hiddenLevelsProvider`를 빈 집합으로 바꾸고 숨김 시험 ①을 "심화가 보인다"로 고친다. 이때부터 단어를 바꾸려면 새 DB 판이 필요하다
- 네 학교급 `select.py`를 다시 돌린 뒤 `git diff --exit-code -- 'docs/wordlist/*.csv'`, 이어서 네 학교급 `cells.py check --full`
- 초등·중등·고등 단어 파일이 그대로인지: `git diff --exit-code ce9b57a -- assets/words/elementary_*.json assets/words/middle_*.json assets/words/high_*.json`
- `flutter analyze && flutter test && flutter build apk --debug`([../VERIFY.md](../VERIFY.md)). 사내망 PC의 `build apk`는 **되는지 확인한 적이 없다** — 한 번 시도해 보고, 안 되면 "빌드·에뮬레이터 확인 안 함, 개인 PC에서 필요"로 남긴다
- `/oh-my-claudecode:review` 두 축 검토(단어와 코드)
- 에뮬레이터 확인(개인 PC에서만): 기기 DB 백업 → 덮어 설치 → DB가 10판 그대로이고 기존 단어장·기록 줄 수가 설치 전과 같음, 새 단어장 → `심화` → 쉬움 버튼의 둘째 줄 → 홈 `심화 [난이도 : 쉬움]`과 단어 수, 카드·시험이 열림(약 1,200개 칸에서 화면이 뜨는 데 걸리는 시간도 본다), 설정 "전체 (단어 수)"
- 문서: `HANDOFF.md`, `VERIFY.md`(낡은 "기대값"도 함께 — 시험 개수·칸별 개수·유사어 쌍 수), `docs/wordlist/README.md`, 앱 `CLAUDE.md` `:3`("9칸", 단어 수) · `:33`, `docs/spec.md:26` · `:32` · `:54`, 루트 `README.md`의 vocab 단어 수와 "남은 일", `about_screen.dart:49` 주석, `word_assets_test.dart` 머리 주석(`:9-13` · `:27`)

**6단계 결과(2026-11-27 사내망 PC — 개인 PC 몫 남음)**: 숨김 해제(시험은 "기본으로 보인다"와 "숨긴 학교급은 안 보인다"로 나눠 181개) → 네 학교급 `select.py` 뒤 csv diff 0 · 초·중·고 단어 파일 `ce9b57a`와 같음 · 네 학교급 `check --full` 0건 → `flutter analyze` 문제없음 · `flutter test` 181개 통과 → **`flutter build apk --debug`는 사내망 PC에서 실패**(sqlite3 native assets를 github.com에서 받다 막힘 — 예상대로) → 두 축 검토: 코드 APPROVE(LOW 3 — 낡은 주석·빈 단언은 고침, 숨긴 학교급 화면에 AppBar 없음은 지금 영향 없어 둠), 단어(칸을 옮긴 말 85개와 새 칸) REQUEST CHANGES → 쌍 25개·해석 3줄 반영 → 문서 갱신. **개인 PC 몫(2026-11-28)**: debug 빌드 통과 → 에뮬레이터 덮어 설치, DB 10판·기존 줄 수 그대로, 새 단어장 → 심화 → 쉬움 `1176단어` · 카드 · 시험 · 설정 `전체 (1176)`, flutter 오류 0건 → `VERIFY.md` "마지막 결과". **4차 끝.**

## 완료 기준 (전체)

- 심화 3칸의 개수가 `advanced.csv`와 같고(2단계에서 고정한 크기), 번호가 `w-3001`부터 이어지며, 영단어는 12칸 전체에서 한 번만 나온다 — `cells.py --stage advanced check --full`과 `flutter test` 종료 코드 0
- 넣지 않기로 한 말이 어느 단어 파일에도 없다 — `word_assets_test`의 시험이 통과
- `select.py` 네 단계를 다시 돌려도 `git diff --exit-code -- 'docs/wordlist/*.csv'` 통과, `cells.py` 네 단계 `check --full` 통과
- `flutter analyze` · `flutter test` · `flutter build apk --debug` 종료 코드 0(빌드는 되는 PC에서)
- 초등·중등·고등 단어 파일 9개가 `ce9b57a`와 한 바이트도 다르지 않다(`git diff --exit-code`)
- `hiddenLevelsProvider`의 값과 `_filling`이 비어 있다
- 사람 표본 60줄(seed·답), `x` 목록 확인, 두 축 검토 판정이 `HANDOFF.md` 진행 이력에 있다
- 에뮬레이터에서 DB 10판 유지·기존 기록 줄 수 유지·심화 단어장 생성이 확인되고 `VERIFY.md` "마지막 결과"에 적혀 있다(개인 PC)

## 위험과 대응

- **분량(3차의 2.4배, 묶음 약 36개)**: 묶음마다 `wip:` 커밋·push와 인계 갱신 — 끊겨도 잃는 것이 묶음 하나. 두 PC를 오가므로 시작할 때 pull, 인계의 "어느 칸 몇 번까지"를 먼저 읽는다
- **쓰기 시작한 뒤 목록이 바뀐다**: 2단계 끝에 고정하고, 바꿔야 하면 멈추고 묻는다(위 "목록은 2단계 끝에 고정한다"). `x` 후보를 2단계에서 넓게 올려 뒤에 나올 일을 줄인다
- **칸 1,200개 안의 뜻 겹침**: 칸이 커져 쉼표로 나눈 뜻 낱말이 겹치기 쉽다 — `cells.py check`와 `word_assets_test`가 묶음마다 잡는다. 한 묶음에서 겹침 때문에 다시 쓴 줄이 20줄을 넘으면 사용자에게 알리고 규칙을 다시 정한다
- **`similar_words_test`가 느려진다**: 쌍이 늘수록 길어진다(씨앗 200개 × 쌍 전체). 묶음 검사가 2분을 넘으면 알리고, 묶음 때는 씨앗 수를 줄이고 칸 끝에서 전체를 도는 식으로 바꿀지 묻는다
- **`x` 판단이 Claude에 치우친다**: `x`는 사용자가 확인한 것만. 후보 목록은 넓게 올린다
- **단계 1(쉬운 말)이 너무 많거나 적다**: 쉬움 칸 크기를 넘으면 스크립트가 멈춘다. 2단계에서 개수와 예를 사용자에게 보여 준다
- **초등·중등·고등 결과가 바뀐다**: 1·6단계의 `git diff --exit-code`로 막는다
- **`cells.py fix`가 쓰는 중인 칸을 덮어쓴다**: 칸을 한 번에 하나씩 쓰고, 쓰는 중인 executor가 없을 때만 돌린다
- **덜 찬 심화 칸이 기기에 보인다**: `hiddenLevelsProvider`로 숨긴다(숨김을 화면 시험이 지킨다)
- **사내망 PC의 `flutter test`**: 3단계 첫 줄에서 먼저 확인한다

## 이번 범위가 아닌 것

- release 준비(앱 이름·아이콘·서명 키), 앱 정보 한국어화, iOS — 심화를 숨겨 두므로 4차 도중에 따로 진행해도 된다
- 두 기관(평가원·교육부) 답에 따른 조정
- 앱 제목·문서의 "초·중·고"라는 말을 바꾸는 것(심화가 생겨도 대상 사용자는 그대로다 — 바꾸려면 따로 정한다)

## 검토 반영 기록

- 2026-11-25 critic **REVISE**(CRITICAL 0 · MAJOR 2 · MINOR 9) — 모두 반영
  - MAJOR ① 쓰기 시작한 뒤 단어가 `x`로 바뀌면 번호·칸 경계가 밀리는데 절차가 없음(`cells.py:59`·`:68`·`:104-106`·`:143`) → "목록은 2단계 끝에 고정한다"와 바뀔 때의 절차, 2단계 순서를 "`x` 확정 → select → 커밋"으로
  - MAJOR ② 덜 찬 칸을 설치 금지 문구로만 막고 되돌릴 길이 없음 → `hiddenLevels`로 고르기 화면·경로에서 숨김(설치 금지 삭제)
  - MINOR: 넣지 않은 말 확인을 `grep`(robust·sexual에 걸리고 0줄이면 종료 코드 1) 대신 시험으로 / 후보 수를 스크립트가 검사(B2 2,386 확정) / 설명 문구가 폭 360에서 넘침 → 둘째 줄 + 폭 360 화면 시험 / 화면 시험의 가짜 단어와 로딩·오류 때의 문구 / 단계 1은 B1만, `x` 줄 난이도는 비움, 검토 시점을 묶음 3·6·9·마지막으로 / 1~3단계의 커밋·인계 시점과 2단계 검토 나누기 / 사내망 `build apk`는 "확인 안 함" / 문서 목록에 `spec.md:26`·`:32`, `study_decks.dart:10` 설명 고침 / 번호 비교를 `git diff --exit-code ce9b57a -- …`로
- 2026-11-25 critic 재검토 **APPROVE**(지난 지적 모두 해결 확인, CRITICAL·MAJOR 없음). 새 MINOR 5건 반영: 숨김을 `const`가 아니라 `hiddenLevelsProvider`로(시험에서 바꿔 넣기) / 심화를 여는 시점을 4단계 끝에서 6단계 첫 줄로(5단계에서 뺄 말이 나와도 절차를 쓸 수 있게) / 넣지 않은 말 시험이 `tiers-advanced.csv`의 `x` 줄을 직접 읽음 / 단계표를 이어 쓸 때마다 `--partial` 검사 / 후보 수 완료 기준을 스크립트 검사로, 숨긴 칸도 칸 주소로는 열린다는 사실. 이 5건을 반영한 판은 다시 검토받지 않았다
  - critic이 맞다고 확인한 것(1차): 파일:줄 인용 전부, B1 1,227 · B2 2,386 · A1·A2 0, 원본 SHA-256, "DB 판은 올리지 않는다", 칸 배정 규칙에 모순 없음, "다시 만들어도 같은 결과". 확인 못 한 것: 지금 `flutter test` 통과 여부, `similar_words_test` 실행 시간, 사내망 `build apk`
