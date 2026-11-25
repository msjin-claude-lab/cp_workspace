# 단어 늘리기 4차 — 심화 약 3,600개 (CEFR-J 남은 B1 + B2)

상태: **승인 대기**(2026-11-25 사내망 PC — `/oh-my-claudecode:plan` 인터뷰로 작성. 사용자 승인 전에는 실행하지 않는다)

앞 차수: [1차 초등 800](plan-words-phase1.md) · [2차 중등 700](plan-words-phase2.md) · [3차 고등 1,500](plan-words-phase3.md)("4차의 자리"가 이 문서의 출발점)

## 요구 요약 (사용자 결정)

1. **규모는 전부** — 3차에 들지 않은 B1 1,227 + B2 최대 2,386 = **최대 3,613개**에서 `x`를 뺀 것 전부(2026-11-24). 뽑기(자르기)는 없다
2. **넷째 학교급, 화면 이름 "심화"**(2026-11-25). 쉬움 · 중간 · 어려움 3칸, 칸당 약 1,200개(2026-11-24)
3. **gay · suicide · sex · bust는 넣지 않는다(`x`)**(2026-11-25). 3차의 "술·담배·폭력·연애 말은 빼지 않는다"는 그대로 — B2에서 나오는 성·자살 관련 말과 `naked`는 `x` **후보 목록**으로 보여 주고 사용자가 정한다(목록에 올리는 범위는 Claude 해석)
4. **고등에서 빠진 쉬운 일상어(약 320개)는 심화 "쉬움" 칸 맨 앞**에 모으고, 화면 설명에 "고등 이전에 놓친 쉬운 말"임을 적는다(2026-11-24)
5. **작성·검토는 3차와 같게**(2026-11-25): 100개 묶음마다 검사·`wip:` 커밋·push, 에이전트 검토는 300개마다, 사람 확인은 칸마다 무작위 20줄(60줄)
6. 뜻·예문·해석은 Claude가 새로 쓰고(CEFR-J에는 없다) 검토 에이전트가 본다 — 1~3차와 같다

## 확인한 사실 (2026-11-25, 커밋 `ce9b57a`)

- 후보의 B1 쪽은 이미 저장소에 있다: `docs/wordlist/candidates-high.csv`의 B1 2,081줄 중 `high.csv`에 들지 않은 1,227줄. `tiers-high.csv`에 단계(3 · 4)와 이유가 있고 난이도는 일부만 있다. B2는 어느 csv에도 없다(원본에서 새로 읽는다)
- 넣지 않기로 한 넷의 지금 줄: `tiers-high.csv:350` bust(단계 4) · `:1067` gay · `:2195` sex · `:2377` suicide(단계 3). `:1587` naked(단계 3)
- 원본 두 파일은 **사내망 PC에도 있다**: `D:\dev\tmp\wordlist\CEFRJ_wordlist_ver1.6.zip`(1,089,155바이트) · `frequency-alpha-alldicts.txt`(18,740,980바이트) — 크기가 README 값과 같다(SHA-256은 `select.py`가 검사). 두 주소 모두 이 PC에서 HTTP 200(README `:20`의 "사내망 PC에서는 못 받는다"는 낡았다 — `raw.githubusercontent.com`은 열려 있다)
- `tool/wordlist/select.py`: `--stage` 선택지 `elementary|middle|high`(`:504`), 학교급마다 함수(`high` `:405-497`). 고등 후보는 `A1·A2·B1`에서 초등·중등을 뺀 것(`:415-416`), 단계 허용값 `1·2·3·4·x`(`:436`), 칸 크기는 상수 `HIGH`(`:418`·`:488`), 줄 검사 `check_rows`(`:235`), 단계 파일 읽기 `read_tiers`(`:188`)
- `tool/wordlist/cells.py`: `STAGES`(`:42-45`)가 학교급마다 (기준 csv, 앞선 csv들)를 갖고, 첫 번호 = 앞선 csv 줄 수 합 + 1
- `lib/data/cell.dart`: `SchoolLevel` 3값(`:2-10`), `Cell` 9값(`:84-93`), 화면 이름 `'${level.label} [난이도 : ${difficulty.label}]'`(`:107`), 파일 `assets/words/$id.json`(`:109`). `pubspec.yaml:70`은 폴더(`assets/words/`)를 통째로 넣는다 — 파일을 더해도 pubspec은 그대로
- 학교급을 늘리면 자동으로 따라오는 곳: 학교급 고르기(`lib/features/home/home_screen.dart:204`), 경로(`lib/router.dart:38`), 기본 단어장 이름(`lib/data/study_decks.dart:10`)
- 난이도 고르기 버튼의 설명 줄은 지금 `N단어`뿐이다(`home_screen.dart:291-299`의 `detail`)
- 시험: 칸별 기대 개수 `_expectedCount`(`test/data/word_assets_test.dart:14-23`), 묶음 중 스위치 `_filling`(`:30`), 번호 형식 `^w-\d{4}$`(`:34`). "칸은 9개"(`test/data/word_repository_test.dart:26-32`). `similar_words_test.dart:30-31`은 `Cell.values`마다 파일을 읽는다(파일이 없으면 깨진다). `test/widget_test.dart:118`이 `SchoolLevel.values`를 돈다
- 유사어 쌍은 지금 545쌍(`lib/data/similar_words.dart`), 같은 칸 안의 쌍만 둔다
- 옛 번호 기록이 없는 새 칸이다 — `advanced_*`라는 `cell_id`나 `w-3001` 이상 번호는 어느 판 DB에도 없다. DB는 10판 그대로(3단계에서 `migrateLegacy`가 `Cell.values`를 어떻게 쓰는지 확인한다)

## 정한 설계

- **이름**: 스크립트 단계 `advanced`, `SchoolLevel.advanced('심화')`, 칸 `advancedEasy|Medium|Hard`, 파일 `assets/words/advanced_easy|medium|hard.json`, 산출물 `candidates-advanced.csv` · `tiers-advanced.csv` · `advanced.csv`
- **후보**: CEFR-J의 `B1 · B2` 중 `elementary.csv` · `middle.csv` · `high.csv`에 없는 것. A1·A2는 3차까지 모두 들어갔으므로 **남은 A1·A2가 0개인지 검사**한다(1개라도 있으면 종료 코드 1)
- **단계(tier)는 뽑기에 쓰지 않는다** — 값은 셋뿐이다
  - `1` = 고등 이전에 놓친 쉬운 말(B1의 쉬운 구체 명사·사람·직업·자연·동물·파생 부사 등). **난이도는 반드시 1**, 쉬움 칸 맨 앞에 선다
  - `2` = 그 밖의 모든 말
  - `x` = 넣지 않음. gay · suicide · sex · bust는 **`x`가 아니면 종료 코드 1**. 그 밖의 `x`는 사용자가 확인한 것만
- **난이도**(1 · 2 · 3, `x`가 아닌 모든 줄에 있어야 한다): `1` 일상·구체 말 · `2` 흔한 추상어와 B2의 일반 말 · `3` 추상·학술·격식 말, 뜻이 여럿인 말. 수준(B1/B2)으로 강제하지 않는다 — 3차 때의 난이도를 가져오지 않고 심화 기준으로 다시 매긴다(3차에서 남긴 LOW "같은 범주가 단계 3·4로 갈린 줄"도 여기서 정리된다)
- **칸 배정**: `x`가 아닌 N개를 `(난이도, 단계, 빈도 순위, 알파벳)`으로 세워 앞에서부터 `⌈N/3⌉ · … · ⌊N/3⌋`(나머지는 앞 칸부터 하나씩 — 초등 267 · 267 · 266과 같은 방식). **단계 1이 모두 쉬움 칸에 들어가지 않으면 종료 코드 1**. N과 칸 크기는 스크립트가 계산해 출력하고, 2단계가 끝난 뒤 이 문서와 시험 기대값에 적는다
- **번호**: `advanced.csv` 순서대로 `w-3001`부터(최대 `w-6613` — 네 자리 형식 그대로)
- **다시 만들어도 같은 결과**: 심화 단계는 커밋된 csv 셋만 거른다. 초등·중등·고등을 다시 돌려도 그 csv가 그대로여야 한다
- **DB 판은 올리지 않는다**(10판 유지). 3단계에서 근거를 확인해 적는다
- **화면 설명**: 난이도 고르기에서 심화 쉬움 버튼의 설명 줄을 `N단어 · 고등 이전에 놓친 쉬운 말 포함`으로 한다(다른 버튼은 `N단어` 그대로). 문구가 한 줄을 넘으면 3단계에서 줄여 사용자에게 확인받는다
- **덜 찬 칸을 사용자가 보지 않게**: 학교급 코드(`SchoolLevel.advanced`)는 3단계에서 넣는다(시험·검사 도구가 `Cell.values`로 새 파일을 읽어야 한다). 대신 **3단계 커밋부터 4단계가 끝날 때까지 release APK를 만들지 않고 기기에 설치하지 않는다** — 이 금지를 `HANDOFF.md` 인계 맨 위에 적는다. 3차와 달리 DB를 건드리지 않으므로 잘못 설치해도 기록은 잃지 않는다

## 단계

### 1. 선정 스크립트에 심화를 더한다
- `select.py --stage advanced`: 위 설계의 후보·단계·난이도·칸 배정과 검사(어긋나면 종료 코드 1) — 남은 A1·A2 0개, 단계 파일과 후보가 정확히 맞음, 단계는 `1·2·x`만, 넣지 않기로 한 넷이 `x`, `x`가 아닌 줄의 난이도 `1·2·3`, 단계 1의 난이도가 1이고 모두 쉬움 칸, 중복 0, 초등·중등·고등과 겹침 0(`check_rows` 재사용). 출력: 후보 수(B1 · B2), `x` 수, N과 칸 크기, 난이도 분포, 단계 1 개수
- `cells.py`의 `STAGES`에 `"advanced": ("advanced.csv", ("elementary.csv", "middle.csv", "high.csv"))`, 머리 설명
- `docs/wordlist/README.md`: 4차 규칙·파일 표, 빈도 파일을 사내망 PC에서도 받을 수 있다는 사실(`:20`)
- 완료 기준(사내망 PC에서 가능): `python tool/wordlist/select.py --stage elementary --cefrj <zip> --freq <txt> && … --stage middle … && … --stage high … && git diff --exit-code -- 'docs/wordlist/*.csv'` 종료 코드 0, `--stage advanced`가 `candidates-advanced.csv`를 쓰고 후보 수를 출력(B1이 1,227이 아니면 멈추고 이유를 찾는다. B2 수는 이 문서의 "최대 2,386"을 실제 값으로 고친다)

### 2. 단계와 난이도를 매긴다
- `executor`가 `tiers-advanced.csv`(단어, 단계, 이유, 난이도)를 쓴다 — 약 3,600줄을 500~700줄씩 **차례로 이어 쓴다**(한 파일이라 동시에 쓰지 않는다). B1 1,227줄은 `tiers-high.csv`의 이유를 참고하되 단계·난이도는 새 기준으로 다시 매긴다
- `code-reviewer`가 본다: 단계 1에 든 어려운 말·단계 1에서 빠진 쉬운 말, 난이도가 뒤집힌 줄, `x`로 올려야 할 말(욕설·성적 표현·자살 관련)
- `select.py --stage advanced` → `advanced.csv`, 검사 통과(종료 코드 0)
- **사용자 확인**: `x` 후보 목록(넣지 않기로 한 넷 + 검토가 올린 말 — 줄마다 넣을지 뺄지), 단계 1 개수와 예 20개, 칸 크기·난이도 분포, 칸마다 표본 20개

### 3. 코드와 시험을 먼저 바꾼다 (단어를 넣기 전)
- `cell.dart`: `SchoolLevel.advanced('심화')`, `Cell` 세 값, 주석 "9칸" → 12칸(`:83`)
- 빈 단어 파일 셋(`[]`)을 만든다 — `cells.py skeleton`은 쓰지 않는다
- `home_screen.dart`: 심화 쉬움 버튼의 설명 줄(위 "화면 설명")
- 시험: `_expectedCount`에 심화 세 칸(2단계에서 확정한 크기)과 `_filling` = 심화 3칸, `word_repository_test.dart:26-32`의 9 → 12, 학교급 고르기에 `심화`가 보이고 난이도 화면에 설명 줄이 보이는 화면 시험 하나, `widget_test.dart:118` 주변이 넷째 학교급에서도 맞는지 확인
- DB: `migrateLegacy`와 `study_records.dart`가 새 칸 때문에 달라지는 것이 없음을 읽어 확인하고 이 문서 "검토 반영 기록"에 근거(파일:줄)를 적는다. 달라지는 것이 있으면 멈추고 사용자에게 알린다
- 완료 기준: `flutter analyze && flutter test` 종료 코드 0. 커밋할 때 인계 맨 위에 "4단계가 끝날 때까지 release 빌드·기기 설치 금지"를 적는다

### 4. 뜻·예문·해석을 쓴다 (약 3,600개)
- **칸은 한 번에 하나씩**(쉬움 → 중간 → 어려움), 칸마다 **100개 묶음 약 12개**(마지막 묶음은 나머지)
- 묶음마다: `python tool/wordlist/cells.py --stage advanced check && flutter test test/data/word_assets_test.dart test/data/similar_words_test.dart && git add assets/words/advanced_<칸>.json lib/data/similar_words.dart HANDOFF.md && git commit`(`wip:`, 경로를 밝혀서) 뒤 push. 묶음을 끝낼 때마다 인계에 어느 칸 몇 번까지 썼는지 적는다
- 검토: `code-reviewer`가 **300개마다**(칸당 4번) 읽는다 — 뜻 정확성, 예문이 그 단어를 실제로 쓰는지, 예문 수준, 같은 칸 안에서 뜻이 사실상 겹치는 쌍. **칸의 마지막 검토는 칸 전체의 유사어 쌍**도 본다. 고칠 줄은 `docs/wordlist/review-fixes-advanced.txt`에 덧붙이고, **그 검토분만** 임시 파일로 `cells.py --stage advanced fix`에 넘긴다(쓰는 중인 executor가 없을 때만). `fix` 뒤에는 묶음과 같은 검사·시험을 돌리고 커밋한다
- 작성 규칙(3차와 같음): 같은 칸 안에서 쉼표로 나눈 뜻 낱말은 글자까지 달라야 한다. 뜻이 사실상 같은 쌍·어원이 같은 쌍은 두 단어가 같은 칸에 들어간 같은 커밋에서 `similarWordPairs`에 더한다
- 마지막 묶음 뒤 `_filling`을 비우고 `cells.py --stage advanced check --full`

### 5. 사람 표본 확인
- 칸마다 무작위 20줄(60줄)을 보여 주고 고칠 것을 `review-fixes-advanced.txt`로 받아 `fix`로 적용. seed와 사용자 답을 `HANDOFF.md` 진행 이력에 적는다

### 6. 검증하고 기록한다
- 네 학교급 `select.py`를 다시 돌린 뒤 `git diff --exit-code -- 'docs/wordlist/*.csv'`, 이어서 네 학교급 `cells.py check --full`
- 초등·중등·고등 번호가 그대로인지: `ce9b57a`의 `id → 영단어` 3,000쌍이 작업 뒤에도 같은지 스크립트로 비교(다르면 종료 코드 1)
- `flutter analyze && flutter test && flutter build apk --debug`([../VERIFY.md](../VERIFY.md)). 사내망 PC에서는 `build apk`가 막혀 있다(HANDOFF "주의할 것") — 그 PC에서 끝내면 "빌드·에뮬레이터 확인 안 함, 개인 PC에서 필요"로 남긴다
- `/oh-my-claudecode:review` 두 축 검토(단어와 코드)
- 에뮬레이터 확인(개인 PC에서만): 기기 DB 백업 → 덮어 설치 → DB가 10판 그대로이고 기존 단어장·기록 줄 수가 설치 전과 같음, 새 단어장 → `심화` → 쉬움 설명 줄 → 홈 `심화 [난이도 : 쉬움]`과 단어 수, 카드·시험이 열림(약 1,200개 칸에서 화면이 뜨는 데 걸리는 시간도 본다), 설정 "전체 (단어 수)"
- 문서: `HANDOFF.md`, `VERIFY.md`(낡은 "기대값"도 함께 — 시험 개수·칸별 개수·유사어 쌍 수), `docs/wordlist/README.md`, 앱 `CLAUDE.md` `:3`("9칸", 단어 수) · `:33`, `docs/spec.md:54`, 루트 `README.md`의 vocab 단어 수와 "남은 일", `about_screen.dart:49` 주석, `word_assets_test.dart` 머리 주석(`:9-13` · `:27`)

## 완료 기준 (전체)

- 심화 3칸의 개수가 `advanced.csv`와 같고(2단계에서 확정한 크기), 번호가 `w-3001`부터 이어지며, 영단어는 12칸 전체에서 한 번만 나온다
- gay · suicide · sex · bust가 어느 단어 파일에도 없다(`grep`으로 0줄)
- `select.py` 네 단계를 다시 돌려도 `git diff --exit-code -- 'docs/wordlist/*.csv'` 통과, `cells.py` 네 단계 `check --full` 통과
- `flutter analyze` · `flutter test` · `flutter build apk --debug` 종료 코드 0(빌드는 개인 PC)
- 초등·중등·고등 3,000쌍의 번호가 `ce9b57a`와 같다
- 사람 표본 60줄(seed·답), `x` 목록 확인, 두 축 검토 판정이 `HANDOFF.md` 진행 이력에 있다
- 에뮬레이터에서 DB 10판 유지·기존 기록 줄 수 유지·심화 단어장 생성이 확인되고 `VERIFY.md` "마지막 결과"에 적혀 있다(개인 PC)

## 위험과 대응

- **분량(3차의 2.4배, 묶음 약 36개)**: 묶음마다 `wip:` 커밋·push와 인계 갱신 — 끊겨도 잃는 것이 묶음 하나. 두 PC를 오가므로 시작할 때 pull, 인계의 "어느 칸 몇 번까지"를 먼저 읽는다
- **칸 1,200개 안의 뜻 겹침**: 칸이 커져 쉼표로 나눈 뜻 낱말이 겹치기 쉽다 — `cells.py check`와 `word_assets_test`가 묶음마다 잡는다. 뒤 묶음일수록 겹침이 늘어 다시 쓰는 줄이 많아질 수 있다(묶음 시간이 늘어나는 것으로 드러난다 — 한 묶음에서 겹침 수정이 20줄을 넘으면 사용자에게 알리고 규칙을 다시 정한다)
- **B2 수가 예상과 다르다**: 1단계에서 실제 수를 출력해 이 문서를 고친다. 칸 크기는 고정값이 아니라 계산값이라 영향이 없다
- **`x` 판단이 Claude에 치우친다**: `x`는 사용자가 확인한 것만. 후보 목록은 넓게 올린다(성·자살 관련, 욕설, 비하 표현)
- **단계 1(쉬운 말)이 너무 많거나 적다**: 쉬움 칸 크기를 넘으면 스크립트가 멈춘다. 2단계에서 개수와 예를 사용자에게 보여 준다
- **초등·중등·고등 결과가 바뀐다**: 1·6단계의 `git diff --exit-code`와 번호 비교로 막는다
- **`cells.py fix`가 쓰는 중인 칸을 덮어쓴다**: 칸을 한 번에 하나씩 쓰고, 쓰는 중인 executor가 없을 때만 돌린다
- **덜 찬 심화 칸이 기기에 보인다**: 3~4단계 동안 release 빌드·설치 금지(인계 맨 위). 기록 손실은 없다
- **사내망 PC의 `flutter test`**: sqlite3 파일을 `.dart_tool`에 둬야 돈다(HANDOFF "주의할 것"). 3단계를 시작하기 전에 이 PC에서 `flutter test`가 도는지 먼저 확인한다

## 이번 범위가 아닌 것

- release 준비(앱 이름·아이콘·서명 키), 앱 정보 한국어화, iOS
- 두 기관(평가원·교육부) 답에 따른 조정
- 앱 제목·문서의 "초·중·고"라는 말을 바꾸는 것(심화가 생겨도 대상 사용자는 그대로다 — 바꾸려면 따로 정한다)

## 검토 반영 기록

- (critic 검토 뒤에 적는다)
