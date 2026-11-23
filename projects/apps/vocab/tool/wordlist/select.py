"""초등 단어 선정 목록을 만든다 (docs/plan-words-phase1.md 2단계).

파이썬 표준 라이브러리만 쓴다. 원본 파일은 저장소에 없다 — docs/wordlist/README.md의 주소에서 받아
경로를 인자로 준다.

    python tool/wordlist/select.py --cefrj <CEFRJ_wordlist_ver1.6.zip 또는 .xlsx> [--freq <빈도 파일>]

초등 단어는 CEFR-J A1에서만 고른다(2026-11-23 사용자 결정 — 기존에 직접 고른 초등 150개는 쓰지 않는다).
중등·고등 칸에 아직 남아 있는 기존 단어와는 겹치지 않게 한다(그 칸은 차례가 올 때 교체한다).

--freq 없이 돌리면 뺀 표제어(excluded.csv), 기존 단어의 겹침(overlap.csv), 후보(candidates.csv)만 만든다.
--freq는 빈도가 높은 순으로 한 줄에 단어 하나가 있는 글 파일이다(줄 앞의 순위 숫자와 뒤의 횟수는 무시).
1차에서 쓴 것은 gwordlist의 frequency-alpha-alldicts.txt (docs/wordlist/README.md).

난이도: docs/wordlist/tiers.csv(단어, 단계 1·2·3 또는 x, 이유)가 있으면 그 단계를 먼저 보고 같은 단계 안에서는
빈도 순으로 줄을 세운다. 없으면 빈도 순서만 쓴다(초안). 줄 세운 뒤 앞에서부터 267 · 267 · 266개를
쉬움 · 중간 · 어려움에 넣는다. 단계가 x인 단어와 줄 끝에 남는 단어는 초등에 넣지 않는다.

산출물은 모두 docs/wordlist/ 에 쓴다. 같은 입력이면 늘 같은 결과가 나온다(정렬 순서 고정).
끝에 검사(개수·중복)를 하고, 어긋나면 종료 코드 1.
"""

import argparse
import csv
import hashlib
import io
import json
import re
import sys
import zipfile
from collections import Counter, defaultdict
from pathlib import Path
from xml.etree import ElementTree as ET

APP = Path(__file__).resolve().parents[2]
OUT = APP / "docs" / "wordlist"
WORDS = APP / "assets" / "words"

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

# 칸: (파일 이름, 초등 1차 목표 개수)
ELEMENTARY = [("elementary_easy", 267), ("elementary_medium", 267), ("elementary_hard", 266)]
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


def read_existing():
    """지금 앱에 든 단어: [(칸, id, 영단어)]."""
    out = []
    for cell in ALL_CELLS:
        for w in json.loads((WORDS / f"{cell}.json").read_text(encoding="utf-8")):
            out.append((cell, w["id"], w["word"]))
    return out


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


def main():
    # Windows 콘솔에서도 한글이 깨지지 않게(-I로 돌리면 PYTHONIOENCODING이 무시된다)
    sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser()
    ap.add_argument("--cefrj", required=True)
    ap.add_argument("--freq")
    args = ap.parse_args()

    print(f"CEFR-J 파일 SHA-256: {sha256(args.cefrj)}")
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
    write_csv("excluded.csv", ["headword", "level", "pos", "reason"], excluded)

    # 철자 변이(color/colour)는 어느 쪽으로도 찾을 수 있게 한다. 쓰는 철자는 앞의 것.
    level_of = {}
    for head, entries in by_head.items():
        lv = lowest_level(entries, False)
        for form in head.split("/"):
            key = form.strip().lower()
            if key not in level_of or LEVELS[lv] < LEVELS[level_of[key]]:
                level_of[key] = lv

    existing = read_existing()
    overlap = [(cell, wid, word, level_of.get(word.lower(), "")) for cell, wid, word in existing]
    write_csv("overlap.csv", ["cell", "id", "word", "cefrj_level"], overlap)
    print("지금 앱에 든 단어의 CEFR-J 수준(칸별):")
    for cell in ALL_CELLS:
        c = Counter(lv or "목록에 없음" for cl, _, _, lv in overlap if cl == cell)
        print(f"  {cell}: {dict(sorted(c.items()))}")

    # 초등 후보: A1 전부. 단, 중등·고등 칸에 아직 남아 있는 단어는 뺀다(영단어는 전체에서 한 번만).
    others = {word.lower() for cl, _, word in existing if not cl.startswith("elementary")}
    # 철자 변이 표제어(practice / practice/practise)가 같은 앞 철자로 겹치면 하나로 본다
    a1 = sorted(
        {head.split("/")[0].lower(): head.split("/")[0] for head, lv in sorted(kept.items()) if lv == "A1"}.values(),
        key=str.lower,
    )
    held = [w for w in a1 if w.lower() in others]
    candidates = [w for w in a1 if w.lower() not in others]
    total = sum(target for _, target in ELEMENTARY)
    print(f"A1 {len(a1)}개 중 중등·고등에 남아 있어 뺀 것 {len(held)}개 → 후보 {len(candidates)}개(필요 {total})")

    rank = read_freq(args.freq) if args.freq else {}
    if args.freq:
        print(f"빈도 파일 SHA-256: {sha256(args.freq)} · 단어 {len(rank)}개")
        missing = [w for w in candidates if w.lower() not in rank]
        print(f"빈도 자료에 없는 후보 {len(missing)}개: {', '.join(missing[:40])}")
    write_csv(
        "candidates.csv",
        ["word", "freq_rank"],
        [(w, rank.get(w.lower(), "")) for w in candidates],
    )
    if not args.freq:
        print("--freq가 없어 여기까지만 한다(excluded.csv, overlap.csv, candidates.csv).")
        return

    tiers, reasons = {}, {}
    tiers_file = OUT / "tiers.csv"
    if tiers_file.exists():
        for word, tier, reason in read_rows(tiers_file):
            tiers[word.lower()] = tier
            reasons[word.lower()] = reason
        unknown = sorted(set(tiers) - {w.lower() for w in candidates})
        untiered = [w for w in candidates if w.lower() not in tiers]
        print(f"tiers.csv {len(tiers)}줄 · 단계 {dict(sorted(Counter(tiers.values()).items()))}")
        if unknown or untiered:
            print(f"검사 실패:\n  후보에 없는 단어 {unknown[:10]}\n  단계가 없는 후보 {untiered[:10]}")
            sys.exit(1)
    else:
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
    write_csv("elementary.csv", ["word", "freq_rank", "tier", "cell", "tier_reason"], rows)
    left = usable[pos:]
    print(f"초등에 넣지 않고 남는 후보 {len(left)}개(중등으로): {', '.join(left[:30])}")

    # 검사
    problems = []
    per_cell = Counter(r[3] for r in rows)
    for cell, target in ELEMENTARY:
        if per_cell[cell] != target:
            problems.append(f"{cell}: {per_cell[cell]}개(목표 {target})")
    words = [r[0].lower() for r in rows]
    dup = [w for w, n in Counter(words).items() if n > 1]
    if dup:
        problems.append(f"초등 안 중복: {dup[:10]}")
    clash = sorted(set(words) & others)
    if clash:
        problems.append(f"중등·고등과 중복: {clash[:10]}")
    if problems:
        print("검사 실패:", *problems, sep="\n  ")
        sys.exit(1)
    print(f"elementary.csv {len(rows)}줄 — 검사 통과")


if __name__ == "__main__":
    main()
