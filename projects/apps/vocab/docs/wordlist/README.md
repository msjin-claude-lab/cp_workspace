# 단어 선정 기록

앱에 넣을 영단어를 어떤 자료에서 어떻게 골랐는지 적는다. 계획은 [../plan-words-phase1.md](../plan-words-phase1.md).
여기의 CSV에는 **뜻·예문이 없다**(뜻·예문·해석은 `assets/words/*.json`에 직접 새로 쓴다).

## 쓴 자료

원본 파일은 저장소에 넣지 않는다. 아래 주소에서 다시 받아 SHA-256을 맞춘다.

### CEFR-J Wordlist Version 1.6 — 단어 선정 기준

- 주소: <https://www.cefr-j.org/download.html> → `https://www.cefr-j.org/data/CEFRJ_wordlist_ver1.6.zip`
- 받은 날: 2026-11-23 (개인 PC). zip 1,089,155바이트, SHA-256 `c837d2c00ab8954ed8db48e79afd8ef37099570295fec36950dbf9322303a37a`
- 이용 조건(엑셀 README 시트, 2026-11-23 직접 읽음): 저작권은 東京外国語大学投野研究室. "適切な引用を行っていただければ研究教育および商用においても無償で利用できる。" / "本語彙表を改変して別の語彙表を作ることはかまわないが、必ず本語彙表を適切に引用しなければならない。" 원본을 그대로 다시 배포해도 되는지는 적혀 있지 않다 — 그래서 원본을 넣지 않는다
- 인용 형식(README가 정한 것): `The CEFR-J Wordlist Version 1.6. Compiled by Yukio Tono, Tokyo University of Foreign Studies. Retrieved from https://www.cefr-j.org/download.html on 23/11/26.`
- 내용: 'ALL' 시트에 표제어·품사·수준(A1~B2) 7,801줄, 표제어 6,868개

### Google Books Ngram 기반 빈도 목록 (gwordlist) — 같은 단계 안의 순서

- 주소: <https://github.com/hackerb9/gwordlist> → `frequency-alpha-alldicts.txt`(`https://raw.githubusercontent.com/hackerb9/gwordlist/master/frequency-alpha-alldicts.txt`). **github에서만 받을 수 있다 — 사내망 PC에서는 못 받는다**
- 받은 날: 2026-11-23 (개인 PC). 18,740,980바이트, SHA-256 `4ba1c1e1fe8eb29eed128bb906bb6ee11ed40c19233321b6ad75cbd7139702d6`
- 이용 조건: 저장소 README(2026-11-23 직접 읽음) — "While my programs are licensed under the GNU GPL ≥3, I'm explicitly releasing the data produced under the same license as Google granted me: Creative Commons Attribution 3.0." 원본인 Google Books Ngram 데이터 페이지(<https://storage.googleapis.com/books/ngrams/books/datasetsv3.html>)의 문구는 "This compilation is licensed under a Creative Commons Attribution 3.0 Unported License"(조사 에이전트가 확인)
- 내용: 책(1880~2020)에서 센 영어 단어형 246,590개를 빈도가 높은 순으로. 표제어가 아니라 단어형이다
- **한계**: 책에서 센 빈도라 어린이가 먼저 배우는 말(`cake`, `rabbit`, `bus`)이 낮게, 글에 많이 쓰는 말(`case`, `section`)이 높게 나온다. 그래서 난이도는 아래 "단계"로 먼저 나누고 빈도는 같은 단계 안의 순서에만 쓴다. `May`(5월)처럼 다른 낱말과 철자가 같은 단어의 순위는 믿을 수 없다
- 탈락한 후보(2026-11-23 조사): wordfreq·FrequencyWords·Wiktionary 빈도 목록·NGSL은 동일조건 변경허락(ShareAlike) 조건, SUBTLEX-US·BNC 목록·COCA 표본·Norvig 목록은 데이터의 상업 이용 조건을 확인하지 못함

## 만드는 법

```
python tool/wordlist/select.py --stage elementary --cefrj <CEFRJ_wordlist_ver1.6.zip> --freq <frequency-alpha-alldicts.txt>
python tool/wordlist/select.py --stage middle --cefrj <CEFRJ_wordlist_ver1.6.zip> --freq <frequency-alpha-alldicts.txt>
python tool/wordlist/select.py --stage high --cefrj <CEFRJ_wordlist_ver1.6.zip> --freq <frequency-alpha-alldicts.txt>
python tool/wordlist/cells.py --stage middle check          # 단어 파일이 middle.csv의 앞부분과 같은지(묶음 중)
python tool/wordlist/cells.py --stage middle check --full   # 끝까지·개수까지 같은지
python tool/wordlist/cells.py --stage high check            # 고등(high.csv, 번호 w-1501부터)
```

파이썬 표준 라이브러리만 쓴다. `--stage`를 빼면 `elementary`. 같은 입력이면 같은 결과가 나오고, 개수나 중복이 어긋나면 종료 코드 1.
`select.py`는 `--cefrj`(zip)와 `--freq`의 SHA-256을 위 "쓴 자료"의 값과 비교해 다르면 종료 코드 1로 멈춘다(값은 스크립트의 `EXPECTED_SHA256`에도 있다 — 바꿀 때는 둘 다). zip에서 꺼낸 `.xlsx`를 `--cefrj`로 주면 그 값이 여기 없으므로 검사를 건너뛰고 그렇다고 출력한다.
거를 단어는 지금 단어 파일이 아니라 커밋된 csv에서 읽고(초등: `overlap.csv`의 중등·고등 줄, 중등: `elementary.csv`와 `overlap.csv`의 고등 줄, 고등: `elementary.csv`와 `middle.csv`), 단계마다 자기 이름의 파일만 쓴다 — 그래서 뒤 단계를 진행해도 앞 단계를 다시 돌리면 같은 csv가 나온다. `overlap.csv`는 어느 단계도 다시 쓰지 않는다(1차 작업 시점 기록).

## 고르는 규칙 (1차 — 초등 800개)

1. CEFR-J 표제어에서 뺀다(`excluded.csv`에 이유와 함께): **기능어**(품사가 대명사·한정사·조동사·be/do/have 동사·감탄사뿐인 표제어) 104개, **약어** 17개, **두 단어 이상** 표제어 129개 → 남는 것 6,618개(A1 966 · A2 1,184 · B1 2,082 · B2 2,386). 빼면 어느 칸에도 카드로 나오지 않는다. **수사·전치사·접속사는 넣는다**(2026-11-23 사용자 결정 — 단어장에 흔히 싣는 말. 처음에는 이것까지 193개를 뺐다)
2. 철자 변이(`color/colour`)는 앞 철자 하나만 쓴다
3. 초등 후보 = 남은 것 중 **A1** 930개(`candidates.csv`). 중등·고등 칸에 아직 남아 있는 기존 단어 34개는 뺀 수다(영단어는 앱 전체에서 한 번만 — 그 칸은 차례가 올 때 교체한다)
4. 후보마다 **단계**를 매긴다(`tiers.csv`): `1` 쉬움 · `2` 중간 · `3` 어려움 · `x` 초등에 넣지 않음. Claude가 매기고 검토받았다 — 기준은 한국 초등 3~6학년이 배우는 순서(구체적이고 기초적인 말이 먼저, 추상적인 말이 나중)
5. 단계 → 빈도 순위 → 알파벳 순으로 줄을 세워 앞에서부터 267 · 267 · 266개를 쉬움 · 중간 · 어려움에 넣는다(`elementary.csv`). 줄 끝에 남는 단어는 중등 차례에 쓴다

기존에 직접 골랐던 초등 150개는 쓰지 않는다(2026-11-23 사용자 결정 — CEFR-J로만). 그중 어떤 단어가 CEFR-J의 어느 수준인지는 `overlap.csv`에 남아 있다.

## 고르는 규칙 (2차 — 중등 700개, [../plan-words-phase2.md](../plan-words-phase2.md))

1. 1차 1·2번과 같이 빼고 앞 철자 하나만 쓴다(앞 철자가 같은 표제어는 가장 낮은 수준)
2. 중등 후보 = **A1 + A2** 중 `elementary.csv`에 없고 `overlap.csv`의 고등 줄(3차까지 남는 기존 고등 150개)에도 없는 것 1,333개(A1 164 · A2 1,169, `candidates-middle.csv`). 기존 중등 150개는 지우므로 후보에서 빼지 않는다
3. 후보 전부에 단계를 매긴다(`tiers-middle.csv`, 1 · 2 · 3 · 4 · x). 기준은 한국 중학교 1~3학년이 배우는 순서(일상의 구체적인 말이 먼저). **`4`는 학술·격식·공문서 말**(committee, court, political, latter, upon 등) — 중등에서 맨 뒤로 미루고 고등(3차)에서 쓴다(2026-11-24 사용자 결정). A1에는 `4`를 쓰지 않는다(A1은 전부 뽑힌다). 초등에서 "어린이 앱에 부적절"로 뺀 9개는 `x`. 단계 파일과 후보가 정확히 맞지 않으면 종료 코드 1
4. 뽑기: `x`가 아닌 A1 전부 + A2를 단계(숫자로 비교 — `4`가 맨 뒤) → 빈도 순위 → 알파벳 순으로 세워 700개가 될 때까지. 남는 A2는 고등(3차) 차례에 쓴다
5. 칸 배정: 뽑힌 700개를 **난이도**(`tiers-middle.csv`의 넷째 열 `difficulty`) → 빈도 순위 → 알파벳 순으로 세워 앞에서부터 234 · 233 · 233개를 쉬움 · 중간 · 어려움에(`middle.csv`, `difficulty` 열 포함). 단계와 수준(A1/A2)은 뽑기에만 쓴다(2026-11-24 사용자 결정 — 단계로 나누면 어려움 칸이 빈도가 낮은 쉬운 구체 명사로 찼다). 난이도는 `1` 쉬움(중1 — 일상의 구체적인 말) · `2` 중간(중2 — 일반적인 말) · `3` 어려움(추상어, 감정·상태, 덜 흔한 동사, 격식·교과 말, 뜻이 여럿인 말). 구체 명사는 드물어도 1~2. `x`가 아닌 줄은 모두 1·2·3이어야 하고 아니면 종료 코드 1. 뽑히지 않은 줄은 `min(단계, 3)`을 기본값으로 둔다 번호는 `middle.csv` 순서대로 `w-0801`부터

## 고르는 규칙 (3차 — 고등 1,500개, [../plan-words-phase3.md](../plan-words-phase3.md))

1. 1차 1·2번과 같이 빼고 앞 철자 하나만 쓴다(앞 철자가 같은 표제어는 가장 낮은 수준)
2. 고등 후보 = **A1 + A2 + B1** 중 `elementary.csv`·`middle.csv`에 없는 것 2,727개(A1 9 · A2 637 · B1 2,081, `candidates-high.csv`). `overlap.csv`의 고등 줄(기존 고등 150개)은 지우는 단어라 거르지 않는다 — CEFR-J A2·B1이면 후보로 돌아온다. B1이 1차 1번의 2,082보다 하나 적은 것은 `March`(A1)와 `march`(B1)가 앞 철자로 합쳐졌기 때문이다. B2는 3차에 넣지 않는다(4차 심화)
3. 후보 전부에 단계를 매긴다(`tiers-high.csv`, 1 · 2 · 3 · 4 · x). 기준은 한국 고등학교(공통영어 수준)에서 먼저 배울 순서. **`4`는 심화로 미루는 말**(B1에만 쓴다). 실제로 쓴 범주: 일상에서 드문 구체 명사, 드문 격식어, 전문 분야 말, 문학적·드문 말, 드문 파생어, 다른 말의 변화형, 영국 생활·제도 말, 구어·속어 등. **변화형 기준**(2026-11-24 사용자 결정): 원형이 이미 앱에 있는 -ing·과거분사형(paid·working·hidden·opening)은 변화형으로 `4`. 단 원형과 따로 굳은 뜻이 있는 말(finding 발견, setting 배경, provided = if)은 변화형으로 보지 않는다. **선정 방향**(2026-11-24 사용자 결정): B1 자리(854)가 모자라 수능·교과서 빈출어를 먼저 넣는다. 대부분 아는 쉬운 일상어(bakery·dolphin·robot·passport 등)는 단계 3으로 두어 4차 심화 "쉬움" 칸 맨 앞에서 쓴다. **`x`는 욕설·성적 표현만**(사용자 확인 뒤). A1·A2는 전부 뽑히므로 단계는 기록용이고 `4`를 쓰지 않는다. 초등·중등에서 "어린이 앱에 부적절"로 뺀 9개(`tiers-middle.csv`의 `x`)는 고등에 넣는다 — 여기서 `x`면 종료 코드 1(2026-11-24 사용자 결정). 단계 파일과 후보가 정확히 맞지 않으면 종료 코드 1
4. 뽑기: `x`가 아닌 A1·A2 전부 + B1을 단계(숫자로 비교) → 빈도 순위 → 알파벳 순으로 세워 1,500개가 될 때까지. 뽑힌 것에 단계 `4`가 있으면 종료 코드 1(단계 1~3인 B1이 모자라다는 뜻 — 단계를 다시 매긴다). 남는 B1은 4차(심화) 차례에 쓴다
5. 칸 배정: 뽑힌 1,500개를 **난이도**(`tiers-high.csv`의 넷째 열 `difficulty`) → 빈도 순위 → 알파벳 순으로 세워 앞에서부터 500 · 500 · 500개를 쉬움 · 중간 · 어려움에(`high.csv`). 난이도는 `1` 쉬움(고1이 대부분 아는 일상·일반 말 — 흔한 추상어·교과 이름(ability·knowledge·oxygen)도 1일 수 있다) · `2` 중간(덜 익숙한 일반 말, 흔한 추상어) · `3` 어려움(추상어, 학술·격식 말, 뜻이 여럿인 말). 같은 어원 짝은 난이도를 맞춘다(economic·economy). 중등 때의 난이도를 그대로 가져오지 않고 고등 기준으로 다시 매긴다. 뽑힌 줄은 1·2·3이어야 하고, 뽑히지 않은 줄은 비워도 되지만 적었다면 1·2·3(아니면 종료 코드 1). 번호는 `high.csv` 순서대로 `w-1501`부터

## 파일

| 파일 | 내용 |
|---|---|
| `excluded.csv` | CEFR-J에서 뺀 표제어와 이유 |
| `overlap.csv` | 1차 작업 시점에 앱에 들어 있던 단어가 CEFR-J의 어느 수준인지(고정 기록 — 다시 만들지 않는다) |
| `candidates.csv` | 초등 후보(A1)와 빈도 순위 |
| `tiers.csv` | 초등 후보의 난이도 단계와 근거(사람이 고치는 파일) |
| `elementary.csv` | 초등 800개와 배정 칸(스크립트가 만든다 — 직접 고치지 않는다) |
| `candidates-middle.csv` | 중등 후보(A1·A2)와 수준·빈도 순위 |
| `tiers-middle.csv` | 중등 후보의 난이도 단계와 근거(사람이 고치는 파일) |
| `middle.csv` | 중등 700개와 수준·배정 칸(스크립트가 만든다 — 직접 고치지 않는다) |
| `candidates-high.csv` | 고등 후보(A1·A2·B1)와 수준·빈도 순위 |
| `tiers-high.csv` | 고등 후보의 단계·근거·난이도(사람이 고치는 파일) |
| `high.csv` | 고등 1,500개와 수준·배정 칸(스크립트가 만든다 — 직접 고치지 않는다) |
| `review-fixes-high.txt` | 고등 검토(칸마다 두 번 + 표본 두 축 + 명사·동사 겸용어 점검)가 낸 고칠 줄. 검토마다 그 부분만 `cells.py --stage high fix`로 적용했다(누적 파일을 통째로 다시 넘기지 않는다) |
| `review-fixes.txt` · `-2` · `-3` · `-4` | 초등 검토가 낸 고칠 줄(`cells.py fix`로 적용) |
| `review-fixes-middle.txt` | 중등 검토가 낸 고칠 줄(`cells.py --stage middle fix`로 적용) |
