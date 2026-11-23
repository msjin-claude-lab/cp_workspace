"""초등 단어 파일의 뼈대를 만들고 검사한다 (docs/plan-words-phase1.md 4단계).

    python tool/wordlist/cells.py skeleton          # elementary.csv 순서대로 번호를 붙인 빈 뼈대를 쓴다
    python tool/wordlist/cells.py check [칸 ...]    # 채운 파일을 검사한다(칸을 주지 않으면 초등 3칸)
    python tool/wordlist/cells.py fix <글 파일>     # 검토가 낸 `번호|필드|새 값|근거` 줄을 적용한다

번호는 elementary.csv의 줄 순서대로 w-0001부터 붙는다(쉬움 → 중간 → 어려움). 뜻·예문·해석은 사람이
(에이전트가) 채운다 — 뼈대를 다시 만들면 채운 내용이 지워지므로, 채우기 시작한 뒤에는 skeleton을 돌리지 않는다.

check가 보는 것(같은 것을 test/data/word_assets_test.dart도 본다 — 이것은 칸 하나만 빨리 보는 용도):
번호·영단어·순서가 elementary.csv와 같은지, 필드가 비지 않았는지, 예문에 그 영단어가 들어 있는지,
뜻을 쉼표로 나눈 낱말이 같은 칸 안에서 겹치지 않는지. 어긋나면 종료 코드 1.
"""

import csv
import json
import sys
from pathlib import Path

APP = Path(__file__).resolve().parents[2]
CSV = APP / "docs" / "wordlist" / "elementary.csv"
WORDS = APP / "assets" / "words"
CELLS = ["elementary_easy", "elementary_medium", "elementary_hard"]
FIELDS = ["id", "word", "meaning", "example", "exampleMeaning"]


def planned():
    """{칸: [(번호, 영단어)]} — elementary.csv 순서."""
    with open(CSV, encoding="utf-8", newline="") as f:
        rows = list(csv.reader(line for line in f if not line.startswith("#")))[1:]
    out = {cell: [] for cell in CELLS}
    for n, row in enumerate(rows, start=1):
        out[row[3]].append((f"w-{n:04d}", row[0]))
    return out


def dump(cell, entries):
    """한 줄에 단어 하나(지금 파일들과 같은 모양)."""
    lines = ["  " + json.dumps(e, ensure_ascii=False) for e in entries]
    (WORDS / f"{cell}.json").write_text("[\n" + ",\n".join(lines) + "\n]\n", encoding="utf-8", newline="\n")


def skeleton():
    for cell, pairs in planned().items():
        dump(cell, [{"id": i, "word": w, "meaning": "", "example": "", "exampleMeaning": ""} for i, w in pairs])
        print(f"{cell}: 뼈대 {len(pairs)}개")


def check(cells):
    plan = planned()
    bad = 0
    for cell in cells:
        problems = []
        entries = json.loads((WORDS / f"{cell}.json").read_text(encoding="utf-8"))
        if [(e.get("id"), e.get("word")) for e in entries] != plan[cell]:
            problems.append("번호·영단어·순서가 elementary.csv와 다르다")
        seen = {}
        for e in entries:
            tag = f'{e.get("id")}({e.get("word")})'
            if list(e) != FIELDS:
                problems.append(f"{tag}: 필드가 {FIELDS}가 아니다")
                continue
            empty = [k for k in FIELDS if not str(e[k]).strip()]
            if empty:
                problems.append(f"{tag}: 빈 필드 {empty}")
                continue
            if e["word"].lower() not in e["example"].lower():
                problems.append(f'{tag}: 예문에 "{e["word"]}"가 없다 — {e["example"]}')
            for part in (p.strip() for p in e["meaning"].split(",")):
                if part in seen:
                    problems.append(f'{tag}: 뜻 "{part}"가 {seen[part]}와 겹친다')
                seen[part] = tag
        print(f"{cell}: {len(entries)}개, 문제 {len(problems)}건")
        for p in problems[:60]:
            print("  " + p)
        bad += len(problems)
    sys.exit(1 if bad else 0)


def fix(path):
    """검토가 낸 고칠 줄(`번호|필드|새 값|근거`, UTF-8 글 파일)을 단어 파일에 적용한다."""
    fixes = []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        parts = [p.strip() for p in line.split("|")]
        if len(parts) >= 3 and parts[0].startswith("w-"):
            fixes.append(parts[:3])
    done, unknown = 0, []
    for cell in CELLS:
        entries = json.loads((WORDS / f"{cell}.json").read_text(encoding="utf-8"))
        by_id = {e["id"]: e for e in entries}
        for wid, field, value in fixes:
            if wid in by_id:
                if field not in FIELDS[2:] or not value or '"' in value:
                    unknown.append((wid, field))
                    continue
                by_id[wid][field] = value
                done += 1
        dump(cell, entries)
    known = {e[0] for cell in planned().values() for e in cell}
    unknown += [(wid, field) for wid, field, _ in fixes if wid not in known]
    print(f"고칠 줄 {len(fixes)}개 중 {done}개 적용, 적용 못 함 {unknown}")
    sys.exit(1 if unknown else 0)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    if len(sys.argv) >= 3 and sys.argv[1] == "fix":
        fix(sys.argv[2])
    elif len(sys.argv) >= 2 and sys.argv[1] == "skeleton":
        skeleton()
    elif len(sys.argv) >= 2 and sys.argv[1] == "check":
        check(sys.argv[2:] or CELLS)
    else:
        sys.exit(__doc__)
