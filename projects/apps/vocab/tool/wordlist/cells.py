"""학교급마다 단어 파일의 뼈대를 만들고 검사한다 (docs/plan-words-phase1.md 4단계, docs/plan-words-phase2.md).

    python tool/wordlist/cells.py [--stage elementary|middle] skeleton        # csv 순서대로 번호를 붙인 빈 뼈대를 쓴다
    python tool/wordlist/cells.py [--stage elementary|middle] check [--full] [칸 ...]
                                                                            # 채운 파일을 검사한다(칸을 주지 않으면 그 학교급 3칸)
    python tool/wordlist/cells.py [--stage elementary|middle] fix <글 파일>  # 검토가 낸 `번호|필드|새 값|근거` 줄을 적용한다

--stage(기본 elementary)가 기준 csv와 칸을 정한다: elementary → docs/wordlist/elementary.csv, 번호 w-0001부터 /
middle → docs/wordlist/middle.csv, 번호 w-0801부터. 번호는 csv 줄 순서대로 붙는다(쉬움 → 중간 → 어려움).
뜻·예문·해석은 사람이(에이전트가) 채운다. skeleton은 대상 파일에 채운 뜻이 하나라도 있으면 쓰지 않고 멈춘다.

check가 보는 것(같은 것을 test/data/word_assets_test.dart도 본다 — 이것은 칸 하나만 빨리 보는 용도):
번호·영단어·순서가 csv의 앞부분과 같은지(묶음으로 채우는 중에도 쓴다 — --full이면 끝까지, 개수까지 같아야 한다),
필드가 비지 않았는지, 예문에 그 영단어가 들어 있는지, 뜻을 쉼표로 나눈 낱말이 같은 칸 안에서 겹치지 않는지.
어긋나면 종료 코드 1.
"""

import csv
import json
import sys
from pathlib import Path

APP = Path(__file__).resolve().parents[2]
WORDLIST = APP / "docs" / "wordlist"
WORDS = APP / "assets" / "words"
# 학교급: (기준 csv, 첫 번호)
STAGES = {"elementary": ("elementary.csv", 1), "middle": ("middle.csv", 801)}
FIELDS = ["id", "word", "meaning", "example", "exampleMeaning"]

STAGE = "elementary"


def cells():
    return [f"{STAGE}_{diff}" for diff in ("easy", "medium", "hard")]


def planned():
    """{칸: [(번호, 영단어)]} — 기준 csv 순서."""
    name, first = STAGES[STAGE]
    if not (WORDLIST / name).exists():
        sys.exit(f"{name}이 없다 — 먼저 select.py --stage {STAGE}로 만든다")
    with open(WORDLIST / name, encoding="utf-8", newline="") as f:
        reader = csv.reader(line for line in f if not line.startswith("#"))
        header = next(reader)
        rows = list(reader)
    col = header.index("cell")
    out = {cell: [] for cell in cells()}
    for n, row in enumerate(rows, start=first):
        out[row[col]].append((f"w-{n:04d}", row[0]))
    return out


def dump(cell, entries):
    """한 줄에 단어 하나(지금 파일들과 같은 모양)."""
    lines = ["  " + json.dumps(e, ensure_ascii=False) for e in entries]
    (WORDS / f"{cell}.json").write_text("[\n" + ",\n".join(lines) + "\n]\n", encoding="utf-8", newline="\n")


def skeleton():
    plan = planned()
    filled = []
    for cell in plan:
        path = WORDS / f"{cell}.json"
        if path.exists():
            entries = json.loads(path.read_text(encoding="utf-8"))
            n = sum(1 for e in entries if str(e.get("meaning", "")).strip())
            if n:
                filled.append(f"{cell}({n}개)")
    if filled:
        sys.exit(f"뜻이 채워진 파일이 있어 뼈대를 쓰지 않는다: {', '.join(filled)}")
    for cell, pairs in plan.items():
        dump(cell, [{"id": i, "word": w, "meaning": "", "example": "", "exampleMeaning": ""} for i, w in pairs])
        print(f"{cell}: 뼈대 {len(pairs)}개")


def check(targets, full):
    plan = planned()
    name = STAGES[STAGE][0]
    bad = 0
    for cell in targets:
        problems = []
        entries = json.loads((WORDS / f"{cell}.json").read_text(encoding="utf-8"))
        got = [(e.get("id"), e.get("word")) for e in entries]
        want = plan[cell] if full else plan[cell][: len(entries)]
        if got != want:
            problems.append(f"번호·영단어·순서가 {name}{'' if full else '의 앞부분'}과 다르다")
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
        print(f"{cell}: {len(entries)}개/{len(plan[cell])}, 문제 {len(problems)}건")
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
    for cell in cells():
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
    argv = sys.argv[1:]
    if len(argv) >= 2 and argv[0] == "--stage":
        if argv[1] not in STAGES:
            sys.exit(f"--stage는 {' 또는 '.join(STAGES)}: {argv[1]}")
        STAGE = argv[1]
        argv = argv[2:]
    if len(argv) >= 2 and argv[0] == "fix":
        fix(argv[1])
    elif argv[:1] == ["skeleton"]:
        skeleton()
    elif argv[:1] == ["check"]:
        full = "--full" in argv[1:]
        check([a for a in argv[1:] if a != "--full"] or cells(), full)
    else:
        sys.exit(__doc__)
