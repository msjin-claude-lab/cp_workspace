"""학교급마다 단어 선정 목록을 만든다 (docs/plan-words-phase1.md 2단계, docs/plan-words-phase2.md 1단계,
docs/plan-words-phase3.md 1단계).

파이썬 표준 라이브러리만 쓴다. 원본 파일은 저장소에 없다 — docs/wordlist/README.md의 주소에서 받아
경로를 인자로 준다.

    python tool/wordlist/select.py [--stage elementary|middle|high] --cefrj <CEFRJ_wordlist_ver1.6.zip 또는 .xlsx> [--freq <빈도 파일>]

--freq는 빈도가 높은 순으로 한 줄에 단어 하나가 있는 글 파일이다(줄 앞의 순위 숫자와 뒤의 횟수는 무시).
1차에서 쓴 것은 gwordlist의 frequency-alpha-alldicts.txt (docs/wordlist/README.md).

원본 확인: --cefrj(zip)와 --freq의 SHA-256이 README에 적힌 값(아래 EXPECTED_SHA256)과 다르면 종료 코드 1로 멈춘다.
--cefrj에 zip에서 꺼낸 .xlsx를 주면 README에 그 값이 없으므로 검사를 건너뛰고 그렇다고 출력한다.

다시 만들어도 같은 결과(2차 계획 "설계 결정"): 거를 단어는 지금 단어 파일이 아니라 커밋된 csv에서 읽고,
단계마다 자기 이름의 파일만 쓴다. overlap.csv(1차 작업 시점에 앱에 들어 있던 단어)는 어느 단계도 다시 쓰지 않는다.

--stage elementary (기본, 1차 — 초등 800개)
  초등 단어는 CEFR-J A1에서만 고른다(2026-11-23 사용자 결정 — 기존에 직접 고른 초등 150개는 쓰지 않는다).
  overlap.csv의 중등·고등 줄(1차 작업 시점에 그 칸에 있던 단어)과는 겹치지 않게 한다.
  쓰는 파일: excluded.csv, candidates.csv, (--freq가 있으면) elementary.csv.
  난이도: tiers.csv(단어, 단계 1·2·3 또는 x, 이유)가 있으면 그 단계를 먼저 보고 같은 단계 안에서는
  빈도 순으로 줄을 세운다. 없으면 빈도 순서만 쓴다(초안). 줄 세운 뒤 앞에서부터 267 · 267 · 266개를
  쉬움 · 중간 · 어려움에 넣는다. 단계가 x인 단어와 줄 끝에 남는 단어는 초등에 넣지 않는다.

--stage middle (2차 — 중등 700개)
  후보 = A1 + A2 중 elementary.csv에 없고 overlap.csv의 고등 줄에도 없는 것(candidates-middle.csv).
  tiers-middle.csv(단어, 단계, 이유, 난이도)는 후보와 정확히 맞아야 한다. 없으면 후보까지만 만든다.
  단계는 1·2·3·4·x. 4는 학술·격식·공문서 말로 중등에서 맨 뒤로 미룬다(대개 뽑히지 않고 고등 3차에서 쓴다).
  A1에는 4를 쓰지 않는다(A1은 전부 뽑힌다). 단계는 숫자로 비교한다.
  뽑기: 단계가 x가 아닌 A1 전부 + A2를 (단계, 빈도 순위, 알파벳) 순으로 700개가 될 때까지.
  난이도(difficulty)는 1·2·3이고 x가 아닌 줄에는 반드시 있어야 한다(없거나 다른 값이면 종료 코드 1).
  단계는 뽑기에, 난이도는 칸 나누기에 쓴다(2026-11-24 사용자 결정 — 실제로 얼마나 어려운가로 칸을 나눈다).
  칸 배정: 뽑힌 700개를 (난이도, 빈도 순위, 알파벳)으로 세워 앞에서부터 234 · 233 · 233(middle.csv).

--stage high (3차 — 고등 1,500개)
  후보 = A1 + A2 + B1 중 elementary.csv·middle.csv에 없는 것(candidates-high.csv). overlap.csv의 고등 줄은
  거르지 않는다(지우는 단어라 후보로 돌아온다). tiers-high.csv(단어, 단계, 이유, 난이도)가 없으면 후보까지만 만든다.
  단계는 1·2·3·4·x. A1·A2는 전부 뽑히므로 단계는 기록용이고 4를 쓰지 않는다. 중등에서 x였던 단어
  (tiers-middle.csv의 x 줄)는 여기서 x가 아니어야 한다(2026-11-24 사용자 결정 — 고등에 넣는다).
  뽑기: x가 아닌 A1·A2 전부 + B1을 (단계, 빈도 순위, 알파벳) 순으로 1,500개가 될 때까지. 뽑힌 것에 단계 4가
  있으면 종료 코드 1(B1의 단계 1~3이 모자라다는 뜻). 난이도는 뽑힌 줄만 1·2·3이 있어야 하고, 뽑히지 않은 줄은
  비워도 되지만 적었다면 1·2·3. 칸 배정: 뽑힌 1,500개를 (난이도, 빈도 순위, 알파벳)으로 세워 500 · 500 · 500(high.csv).

--freq 없이 돌리면 후보 파일까지만 만든다. 같은 입력이면 늘 같은 결과가 나온다(정렬 순서 고정).
끝에 검사(개수·중복·다른 학교급과 겹침)를 하고, 어긋나면 종료 코드 1.
"""

import argparse
import csv
import hashlib
import io
import re
import sys
import zipfile
from collections import Counter, defaultdict
from pathlib import Path
from xml.etree import ElementTree as ET

APP = Path(__file__).resolve().parents[2]
OUT = APP / "docs" / "wordlist"

CITATION = (
    "The CEFR-J Wordlist Version 1.6. Compiled by Yukio Tono, Tokyo University of "
    "Foreign Studies. Retrieved from https://www.cefr-j.org/download.html on 23/11/26."
)

M = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
LEVELS = {"A1": 1, "A2": 2, "B1": 3, "B2": 4}

# 품사가 이것뿐인 표제어는 기능어로 보고 뺀다 — 어느 칸에도 카드로 나오지 않는다.
# 수사·전치사·접속사는 넣는다(2026-11-23 사용자 결정 — 단어장에 흔히 싣는 말).
FUNCTION_POS = {
    "determiner", "pronoun", "modal auxiliary",
    "be-verb", "do-verb", "have-verb", "infinitive-to", "interjection",
}

# 칸: (파일 이름, 목표 개수)
ELEMENTARY = [("elementary_easy", 267), ("elementary_medium", 267), ("elementary_hard", 266)]
MIDDLE = [("middle_easy", 234), ("middle_medium", 233), ("middle_hard", 233)]
HIGH = [("high_easy", 500), ("high_medium", 500), ("high_hard", 500)]

# 원본 두 파일의 SHA-256 — docs/wordlist/README.md "쓴 자료"에 적힌 값과 같다(바꾸면 README도 함께 고친다)
EXPECTED_SHA256 = {
    "CEFR-J": "c837d2c00ab8954ed8db48e79afd8ef37099570295fec36950dbf9322303a37a",  # CEFRJ_wordlist_ver1.6.zip
    "빈도": "4ba1c1e1fe8eb29eed128bb906bb6ee11ed40c19233321b6ad75cbd7139702d6",  # frequency-alpha-alldicts.txt
}
ALL_CELLS = [
    f"{level}_{diff}"
    for level in ("elementary", "middle", "high")
    for diff in ("easy", "medium", "hard")
]
NO_RANK = 10**9  # 빈도 자료에 없는 단어는 같은 단계의 맨 뒤


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def read_cefrj(path):
    """(표제어, 품사, 수준) 줄을 'ALL' 시트(둘째 시트)에서 읽는다."""
    data = Path(path).read_bytes()
    if zipfile.is_zipfile(io.BytesIO(data)):
        z = zipfile.ZipFile(io.BytesIO(data))
        inner = [n for n in z.namelist() if n.lower().endswith(".xlsx")]
        if inner:  # 받은 zip 안의 엑셀
            data = z.read(inner[0])
    x = zipfile.ZipFile(io.BytesIO(data))
    shared = [
        "".join(t.text or "" for t in si.iter(M + "t"))
        for si in ET.fromstring(x.read("xl/sharedStrings.xml")).findall(M + "si")
    ]
    rows = []
    for r in ET.fromstring(x.read("xl/worksheets/sheet2.xml")).iter(M + "row"):
        cells = {}
        for c in r.findall(M + "c"):
            v = c.find(M + "v")
            col = re.sub(r"\d", "", c.get("r"))
            cells[col] = "" if v is None else (shared[int(v.text)] if c.get("t") == "s" else v.text)
        rows.append((cells.get("A", "").strip(), cells.get("B", "").strip(), cells.get("C", "").strip()))
    if rows[0] != ("headword", "pos", "CEFR"):
        sys.exit(f"예상한 머리줄이 아니다: {rows[0]}")
    return rows[1:]


def exclusion_reason(headword, entries):
    """뺄 이유. 쓸 단어면 None."""
    first = headword.split("/")[0]
    if "." in headword:
        return "약어"
    if first.isupper() and len(first) > 1 and first.isalpha():
        return "약어"
    if len(first) == 1 or first.startswith("'"):
        return "기능어"
    if all(pos.lower() in FUNCTION_POS for pos, _ in entries):
        return "기능어"
    if " " in first:
        return "두 단어 이상"  # 1차에서는 뺀다(계획 "표제어 다루기")
    return None


def lowest_level(entries, content_only):
    levels = [lv for pos, lv in entries if not content_only or pos.lower() not in FUNCTION_POS]
    return min(levels, key=lambda lv: LEVELS.get(lv, 9))


def read_rows(path):
    """머리의 # 줄을 뺀 CSV 줄(머리줄 제외)."""
    with open(path, encoding="utf-8", newline="") as f:
        return list(csv.reader(line for line in f if not line.startswith("#")))[1:]


def write_csv(name, header, rows):
    OUT.mkdir(parents=True, exist_ok=True)
    with open(OUT / name, "w", encoding="utf-8", newline="") as f:
        f.write(f"# {CITATION}\n")
        f.write("# 위 목록을 고쳐 만든 것이다(tool/wordlist/select.py). 뜻·예문은 들어 있지 않다.\n")
        w = csv.writer(f, lineterminator="\n")
        w.writerow(header)
        w.writerows(rows)


def read_freq(path):
    """빈도 파일 → {단어(소문자): 순위(1부터)}. 같은 단어는 처음 나온 순위."""
    rank = {}
    for line in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("#"):
            continue
        # 줄에서 처음 나오는 영단어(앞에 순위 숫자가 있는 형식도 읽는다: "1  the  109,892,...")
        for part in line.split():
            word = part.lower()
            if re.fullmatch(r"[a-z][a-z'\-]*", word):
                if word not in rank:
                    rank[word] = len(rank) + 1
                break
    return rank


def read_overlap():
    """overlap.csv(1차 작업 시점에 앱에 들어 있던 단어): [(칸, id, 영단어, CEFR-J 수준)]."""
    return [tuple(r) for r in read_rows(OUT / "overlap.csv")]


def read_tiers(name, candidates, allowed):
    """단계 파일 → ({단어: 단계}, {단어: 이유}, {단어: 넷째 열(중등의 difficulty, 없으면 "")}).
    후보와 정확히 맞지 않거나 allowed 밖의 단계가 있으면 종료 코드 1. 파일이 없으면 None."""
    tiers, reasons, extra = {}, {}, {}
    path = OUT / name
    if not path.exists():
        return None
    for word, tier, reason, *rest in read_rows(path):
        tiers[word.lower()] = tier
        reasons[word.lower()] = reason
        extra[word.lower()] = rest[0] if rest else ""
    unknown = sorted(set(tiers) - {w.lower() for w in candidates})
    untiered = [w for w in candidates if w.lower() not in tiers]
    bad = sorted(w for w, t in tiers.items() if t not in allowed)
    print(f"{name} {len(tiers)}줄 · 단계 {dict(sorted(Counter(tiers.values()).items()))}")
    if unknown or untiered or bad:
        print(
            f"검사 실패:\n  후보에 없는 단어 {unknown[:10]}\n  단계가 없는 후보 {untiered[:10]}\n"
            f"  쓸 수 없는 단계({'·'.join(allowed)} 밖) {bad[:10]}"
        )
        sys.exit(1)
    return tiers, reasons, extra


def check_sha256(label, path):
    """원본 파일의 SHA-256을 README 값(EXPECTED_SHA256)과 비교한다. 다르면 종료 코드 1."""
    got = sha256(path)
    print(f"{label} 파일 SHA-256: {got}")
    if label == "CEFR-J" and Path(path).suffix.lower() == ".xlsx":
        print("  .xlsx라 검사를 건너뛴다(README에는 zip의 값만 있다)")
        return
    if got != EXPECTED_SHA256[label]:
        print(f"검사 실패:\n  {label} 파일이 README의 원본과 다르다(기대 {EXPECTED_SHA256[label]})")
        sys.exit(1)


def print_freq(args, rank, candidates):
    print(f"빈도 파일 단어 {len(rank)}개")
    missing = [w for w in candidates if w.lower() not in rank]
    print(f"빈도 자료에 없는 후보 {len(missing)}개: {', '.join(missing[:40])}")


def check_rows(rows, header, cells, label, others, others_label):
    """칸 개수·중복·다른 학교급과 겹침. 어긋나면 종료 코드 1."""
    cell_col = header.index("cell")
    problems = []
    per_cell = Counter(r[cell_col] for r in rows)
    for cell, target in cells:
        if per_cell[cell] != target:
            problems.append(f"{cell}: {per_cell[cell]}개(목표 {target})")
    words = [r[0].lower() for r in rows]
    dup = [w for w, n in Counter(words).items() if n > 1]
    if dup:
        problems.append(f"{label} 안 중복: {dup[:10]}")
    clash = sorted(set(words) & others)
    if clash:
        problems.append(f"{others_label}과 중복: {clash[:10]}")
    if problems:
        print("검사 실패:", *problems, sep="\n  ")
        sys.exit(1)


def elementary(args, kept):
    overlap = read_overlap()
    print("1차 작업 시점에 앱에 든 단어의 CEFR-J 수준(칸별, overlap.csv):")
    for cell in ALL_CELLS:
        c = Counter(lv or "목록에 없음" for cl, _, _, lv in overlap if cl == cell)
        print(f"  {cell}: {dict(sorted(c.items()))}")

    # 초등 후보: A1 전부. 단, 1차 작업 시점에 중등·고등 칸에 있던 단어는 뺀다(영단어는 전체에서 한 번만).
    others = {word.lower() for cl, _, word, _ in overlap if not cl.startswith("elementary")}
    # 철자 변이 표제어(practice / practice/practise)가 같은 앞 철자로 겹치면 하나로 본다
    a1 = sorted(
        {head.split("/")[0].lower(): head.split("/")[0] for head, lv in sorted(kept.items()) if lv == "A1"}.values(),
        key=str.lower,
    )
    held = [w for w in a1 if w.lower() in others]
    candidates = [w for w in a1 if w.lower() not in others]
    total = sum(target for _, target in ELEMENTARY)
    print(f"A1 {len(a1)}개 중 중등·고등에 있어 뺀 것 {len(held)}개 → 후보 {len(candidates)}개(필요 {total})")

    rank = read_freq(args.freq) if args.freq else {}
    if args.freq:
        print_freq(args, rank, candidates)
    write_csv(
        "candidates.csv",
        ["word", "freq_rank"],
        [(w, rank.get(w.lower(), "")) for w in candidates],
    )
    if not args.freq:
        print("--freq가 없어 여기까지만 한다(excluded.csv, candidates.csv).")
        return

    loaded = read_tiers("tiers.csv", candidates, ("1", "2", "3", "x"))
    if loaded:
        tiers, reasons, _ = loaded
    else:
        tiers, reasons = {}, {}
        print("tiers.csv가 없어 빈도 순서만으로 나눈다(초안)")

    usable = [w for w in candidates if tiers.get(w.lower(), "1") != "x"]
    usable.sort(key=lambda w: (tiers.get(w.lower(), "1"), rank.get(w.lower(), NO_RANK), w.lower()))
    if len(usable) < total:
        print(f"검사 실패:\n  쓸 수 있는 후보가 {len(usable)}개뿐이다(필요 {total})")
        sys.exit(1)

    rows, pos = [], 0
    for cell, target in ELEMENTARY:
        for word in usable[pos: pos + target]:
            key = word.lower()
            rows.append((word, rank.get(key, ""), tiers.get(key, ""), cell, reasons.get(key, "")))
        pos += target
    header = ["word", "freq_rank", "tier", "cell", "tier_reason"]
    write_csv("elementary.csv", header, rows)
    left = usable[pos:]
    print(f"초등에 넣지 않고 남는 후보 {len(left)}개(중등으로): {', '.join(left[:30])}")

    check_rows(rows, header, ELEMENTARY, "초등", others, "중등·고등")
    print(f"elementary.csv {len(rows)}줄 — 검사 통과")


def merged_levels(kept):
    """앞 철자가 같은 표제어(철자 변이)는 하나로 보고 가장 낮은 수준을 쓴다 → ({소문자: 수준}, {소문자: 앞 철자})."""
    level, form = {}, {}
    for head, lv in sorted(kept.items()):
        first = head.split("/")[0]
        key = first.lower()
        form[key] = first
        if key not in level or LEVELS[lv] < LEVELS[level[key]]:
            level[key] = lv
    return level, form


def middle(args, kept):
    # 거를 단어: 초등 800(elementary.csv)과 1차 작업 시점의 고등 칸(overlap.csv 고등 줄 — 3차까지 남는다)
    for name in ("elementary.csv", "overlap.csv"):
        if not (OUT / name).exists():
            sys.exit(f"{name}이 없다 — 먼저 --stage elementary로 만든다(overlap.csv는 저장소에 있다)")
    elem = {r[0].lower() for r in read_rows(OUT / "elementary.csv")}
    high = {word.lower() for cl, _, word, _ in read_overlap() if cl.startswith("high")}
    print(f"거를 단어: elementary.csv {len(elem)}개, overlap.csv 고등 줄 {len(high)}개")

    level, form = merged_levels(kept)
    a12 = sorted((k for k, lv in level.items() if lv in ("A1", "A2")), key=lambda k: form[k].lower())
    in_elem = [k for k in a12 if k in elem]
    in_high = [k for k in a12 if k in high]
    candidates = [form[k] for k in a12 if k not in elem and k not in high]
    by_level = Counter(level[w.lower()] for w in candidates)
    total = sum(target for _, target in MIDDLE)
    print(
        f"A1·A2 {len(a12)}개 중 초등 {len(in_elem)}개 · 고등 {len(in_high)}개를 빼 "
        f"후보 {len(candidates)}개 {dict(sorted(by_level.items()))}(필요 {total})"
    )

    rank = read_freq(args.freq) if args.freq else {}
    if args.freq:
        print_freq(args, rank, candidates)
    write_csv(
        "candidates-middle.csv",
        ["word", "level", "freq_rank"],
        [(w, level[w.lower()], rank.get(w.lower(), "")) for w in candidates],
    )
    if not args.freq:
        print("--freq가 없어 여기까지만 한다(candidates-middle.csv).")
        return

    loaded = read_tiers("tiers-middle.csv", candidates, ("1", "2", "3", "4", "x"))
    if not loaded:
        print("tiers-middle.csv가 없어 여기까지만 한다(candidates-middle.csv). middle.csv는 쓰지 않는다.")
        return
    tiers, reasons, difficulty = loaded
    # 칸 나누기 난이도(넷째 열): x가 아닌 줄은 1·2·3이어야 한다
    bad = sorted(w for w, t in tiers.items() if t != "x" and difficulty[w] not in ("1", "2", "3"))
    if bad:
        print(f"검사 실패:\n  difficulty가 1·2·3이 아닌 줄 {len(bad)}개 {bad[:10]}")
        sys.exit(1)

    def order(w):
        # 단계는 숫자로 비교한다(4 = 학술·격식 말, 맨 뒤)
        return (int(tiers[w.lower()]), rank.get(w.lower(), NO_RANK), w.lower())

    usable = [w for w in candidates if tiers[w.lower()] != "x"]
    a1 = [w for w in usable if level[w.lower()] == "A1"]
    a1_tier4 = [w for w in a1 if tiers[w.lower()] == "4"]
    if a1_tier4:  # A1은 어차피 전부 뽑히므로 4단계를 쓰지 않는다
        print(f"검사 실패:\n  4단계인 A1 {a1_tier4[:10]}")
        sys.exit(1)
    a2 = sorted((w for w in usable if level[w.lower()] == "A2"), key=order)
    if len(a1) + len(a2) < total or len(a1) > total:
        print(f"검사 실패:\n  쓸 수 있는 후보 A1 {len(a1)} · A2 {len(a2)}개(필요 {total})")
        sys.exit(1)
    # 칸 배정은 단계가 아니라 난이도로(2026-11-24 사용자 결정 — 단계는 뽑기에만 쓴다)
    chosen = sorted(
        a1 + a2[: total - len(a1)],
        key=lambda w: (int(difficulty[w.lower()]), rank.get(w.lower(), NO_RANK), w.lower()),
    )
    print(f"뽑은 것: A1 {len(a1)}개 + A2 {total - len(a1)}개 · 남는 A2 {len(a2) - (total - len(a1))}개(고등으로)")
    print(f"뽑은 것의 난이도: {dict(sorted(Counter(difficulty[w.lower()] for w in chosen).items()))}")

    rows, pos = [], 0
    for cell, target in MIDDLE:
        for word in chosen[pos: pos + target]:
            key = word.lower()
            rows.append((word, level[key], rank.get(key, ""), tiers[key], difficulty[key], cell, reasons[key]))
        pos += target
    header = ["word", "level", "freq_rank", "tier", "difficulty", "cell", "tier_reason"]
    write_csv("middle.csv", header, rows)

    check_rows(rows, header, MIDDLE, "중등", elem | high, "초등·고등")
    print(f"middle.csv {len(rows)}줄 — 검사 통과")


def high(args, kept):
    # 거를 단어: 초등 800과 중등 700(커밋된 csv). overlap.csv의 고등 줄은 거르지 않는다(지우는 단어라 후보로 돌아온다)
    for name, stage in (("elementary.csv", "elementary"), ("middle.csv", "middle")):
        if not (OUT / name).exists():
            sys.exit(f"{name}이 없다 — 먼저 --stage {stage}로 만든다")
    elem = {r[0].lower() for r in read_rows(OUT / "elementary.csv")}
    mid = {r[0].lower() for r in read_rows(OUT / "middle.csv")}
    print(f"거를 단어: elementary.csv {len(elem)}개, middle.csv {len(mid)}개")

    level, form = merged_levels(kept)
    pool = sorted((k for k, lv in level.items() if lv in ("A1", "A2", "B1")), key=lambda k: form[k].lower())
    candidates = [form[k] for k in pool if k not in elem and k not in mid]
    by_level = Counter(level[w.lower()] for w in candidates)
    total = sum(target for _, target in HIGH)
    print(
        f"A1·A2·B1 {len(pool)}개 중 초등·중등 {len(pool) - len(candidates)}개를 빼 "
        f"후보 {len(candidates)}개 {dict(sorted(by_level.items()))}(필요 {total})"
    )

    rank = read_freq(args.freq) if args.freq else {}
    if args.freq:
        print_freq(args, rank, candidates)
    write_csv(
        "candidates-high.csv",
        ["word", "level", "freq_rank"],
        [(w, level[w.lower()], rank.get(w.lower(), "")) for w in candidates],
    )
    if not args.freq:
        print("--freq가 없어 여기까지만 한다(candidates-high.csv).")
        return

    loaded = read_tiers("tiers-high.csv", candidates, ("1", "2", "3", "4", "x"))
    if not loaded:
        print("tiers-high.csv가 없어 여기까지만 한다(candidates-high.csv). high.csv는 쓰지 않는다.")
        return
    tiers, reasons, difficulty = loaded

    # A1·A2는 전부 뽑히므로 단계는 기록용 — 4를 쓰지 않는다
    a12_tier4 = sorted(w for w, t in tiers.items() if t == "4" and level[w] in ("A1", "A2"))
    # 중등에서 "어린이 앱에 부적절"로 x였던 단어는 고등에 넣는다(2026-11-24 사용자 결정)
    middle_x = {r[0].lower() for r in read_rows(OUT / "tiers-middle.csv") if r[1] == "x"}
    still_x = sorted(w for w in middle_x if tiers.get(w) == "x")
    if a12_tier4 or still_x:
        print(f"검사 실패:\n  4단계인 A1·A2 {a12_tier4[:10]}\n  중등에서 x였는데 여기서도 x {still_x}")
        sys.exit(1)

    usable = [w for w in candidates if tiers[w.lower()] != "x"]
    a12 = [w for w in usable if level[w.lower()] in ("A1", "A2")]
    b1 = sorted(
        (w for w in usable if level[w.lower()] == "B1"),
        key=lambda w: (int(tiers[w.lower()]), rank.get(w.lower(), NO_RANK), w.lower()),
    )
    if len(a12) + len(b1) < total or len(a12) > total:
        print(f"검사 실패:\n  쓸 수 있는 후보 A1·A2 {len(a12)} · B1 {len(b1)}개(필요 {total})")
        sys.exit(1)
    b1_chosen = b1[: total - len(a12)]
    chosen = a12 + b1_chosen
    tier4 = [w for w in b1_chosen if tiers[w.lower()] == "4"]
    if tier4:  # 단계 1~3인 B1이 모자라다 — 단계를 다시 매긴다
        print(f"검사 실패:\n  뽑힌 것에 4단계 {len(tier4)}개 {tier4[:10]}")
        sys.exit(1)
    # 난이도: 뽑힌 줄은 1·2·3이어야 하고, 뽑히지 않은 줄은 비워도 되지만 적었다면 1·2·3
    picked = {w.lower() for w in chosen}
    bad = sorted(
        w for w, d in difficulty.items() if d not in ("1", "2", "3") and (w in picked or d != "")
    )
    if bad:
        print(f"검사 실패:\n  difficulty가 1·2·3이 아닌 줄 {len(bad)}개 {bad[:10]}")
        sys.exit(1)

    last = b1_chosen[-1] if b1_chosen else None
    print(f"뽑은 것: A1·A2 {len(a12)}개 + B1 {len(b1_chosen)}개 · 남는 B1 {len(b1) - len(b1_chosen)}개(심화로)")
    print(f"뽑은 B1의 단계: {dict(sorted(Counter(tiers[w.lower()] for w in b1_chosen).items()))}")
    if last:
        t = tiers[last.lower()]
        same = [w for w in b1 if tiers[w.lower()] == t]
        print(f"B1 경계: 단계 {t}의 {same.index(last) + 1}번째/{len(same)}개까지 뽑았다(마지막 {last})")
    chosen.sort(key=lambda w: (int(difficulty[w.lower()]), rank.get(w.lower(), NO_RANK), w.lower()))
    print(f"뽑은 것의 난이도: {dict(sorted(Counter(difficulty[w.lower()] for w in chosen).items()))}")

    rows, pos = [], 0
    for cell, target in HIGH:
        for word in chosen[pos: pos + target]:
            key = word.lower()
            rows.append((word, level[key], rank.get(key, ""), tiers[key], difficulty[key], cell, reasons[key]))
        pos += target
    header = ["word", "level", "freq_rank", "tier", "difficulty", "cell", "tier_reason"]
    write_csv("high.csv", header, rows)

    check_rows(rows, header, HIGH, "고등", elem | mid, "초등·중등")
    print(f"high.csv {len(rows)}줄 — 검사 통과")


def main():
    # Windows 콘솔에서도 한글이 깨지지 않게(-I로 돌리면 PYTHONIOENCODING이 무시된다)
    sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser()
    ap.add_argument("--stage", choices=["elementary", "middle", "high"], default="elementary")
    ap.add_argument("--cefrj", required=True)
    ap.add_argument("--freq")
    args = ap.parse_args()

    print(f"단계: {args.stage}")
    check_sha256("CEFR-J", args.cefrj)
    if args.freq:
        check_sha256("빈도", args.freq)
    by_head = defaultdict(list)
    for head, pos, level in read_cefrj(args.cefrj):
        by_head[head].append((pos, level))
    print(f"표제어 {len(by_head)}개(줄 {sum(len(v) for v in by_head.values())})")

    kept, excluded = {}, []
    for head in sorted(by_head, key=str.lower):
        entries = by_head[head]
        reason = exclusion_reason(head, entries)
        if reason:
            excluded.append((head, lowest_level(entries, False), "|".join(sorted({p for p, _ in entries})), reason))
        else:
            kept[head] = lowest_level(entries, True)
    print("뺀 것:", dict(Counter(r[3] for r in excluded)))
    print("남은 것:", len(kept), dict(sorted(Counter(kept.values()).items())))

    if args.stage == "elementary":
        write_csv("excluded.csv", ["headword", "level", "pos", "reason"], excluded)
        elementary(args, kept)
    elif args.stage == "middle":
        middle(args, kept)
    else:
        high(args, kept)


if __name__ == "__main__":
    main()
