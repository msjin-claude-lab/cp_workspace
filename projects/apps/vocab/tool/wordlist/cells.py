"""학교급마다 단어 파일의 뼈대를 만들고 검사한다 (docs/plan-words-phase1.md 4단계, docs/plan-words-phase2.md,
docs/plan-words-phase3.md).

    python tool/wordlist/cells.py [--stage elementary|middle|high] skeleton        # csv 순서대로 번호를 붙인 빈 뼈대를 쓴다
    python tool/wordlist/cells.py [--stage elementary|middle|high] check [--full] [칸 ...]
                                                                            # 채운 파일을 검사한다(칸을 주지 않으면 그 학교급 3칸)
    python tool/wordlist/cells.py [--stage elementary|middle|high] fix <글 파일>  # 검토가 낸 `번호|필드|새 값|근거` 줄을 적용한다

--stage(기본 elementary)는 명령 앞뒤 어디에 줘도 되고, 기준 csv와 칸을 정한다: elementary → docs/wordlist/elementary.csv,
번호 w-0001부터 / middle → docs/wordlist/middle.csv, 번호는 elementary.csv의 줄 수 다음부터(w-0801) /
high → docs/wordlist/high.csv, 번호는 elementary.csv + middle.csv 줄 수 다음부터(w-1501) /
advanced → docs/wordlist/advanced.csv, 번호는 앞 세 csv 줄 수 다음부터(w-3001, docs/plan-words-phase4.md).
번호는 csv 줄 순서대로 붙는다(쉬움 → 중간 → 어려움). 고른 학교급에 없는 칸 이름을 주면 메시지를 내고 멈춘다.
뜻·예문·해석은 사람이(에이전트가) 채운다. skeleton은 대상 파일에 뜻·예문·해석 중 채운 것이 하나라도 있으면 쓰지 않고 멈춘다.

check가 보는 것(같은 것을 test/data/word_assets_test.dart도 본다 — 이것은 칸 하나만 빨리 보는 용도):
번호·영단어·순서가 csv의 앞부분과 같은지(묶음으로 채우는 중에도 쓴다 — --full이면 끝까지, 개수까지 같아야 한다),
필드가 비지 않았는지, 예문에 그 영단어가 들어 있는지, 뜻을 쉼표로 나눈 낱말이 같은 칸 안에서 겹치지 않는지.
어긋나면 종료 코드 1.
"""

import argparse
import csv
import json
import sys
from pathlib import Path

APP = Path(__file__).resolve().parents[2]
WORDLIST = APP / "docs" / "wordlist"
WORDS = APP / "assets" / "words"


def _total(name):
    """앞 학교급 csv의 줄 수(초등 800, 중등 700). 뒤 학교급 번호는 그 다음부터 붙는다."""
    path = WORDLIST / name
    if not path.exists():
        sys.exit(f"{name}이 없다 — 먼저 select.py --stage {name.removesuffix('.csv')}로 만든다")
    with open(path, encoding="utf-8", newline="") as f:
        return sum(1 for _ in csv.reader(line for line in f if not line.startswith("#"))) - 1


# 학교급: (기준 csv, 번호가 이 csv들의 줄 수 합 다음부터 붙는 앞 학교급)
STAGES = {
    "elementary": ("elementary.csv", ()),
    "middle": ("middle.csv", ("elementary.csv",)),
    "high": ("high.csv", ("elementary.csv", "middle.csv")),
    "advanced": ("advanced.csv", ("elementary.csv", "middle.csv", "high.csv")),
}
FIELDS = ["id", "word", "meaning", "example", "exampleMeaning"]

STAGE = "elementary"


def cells():
    return [f"{STAGE}_{diff}" for diff in ("easy", "medium", "hard")]


def planned():
    """{칸: [(번호, 영단어)]} — 기준 csv 순서."""
    name, before = STAGES[STAGE]
    first = sum(_total(n) for n in before) + 1  # 초등 w-0001, 중등 w-0801, 고등 w-1501
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
            n = sum(1 for e in entries if any(str(e.get(k, "")).strip() for k in FIELDS[2:]))
            if n:
                filled.append(f"{cell}({n}개)")
    if filled:
        sys.exit(f"뜻·예문·해석이 채워진 파일이 있어 뼈대를 쓰지 않는다: {', '.join(filled)}")
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


def main():
    global STAGE
    sys.stdout.reconfigure(encoding="utf-8")
    # --stage는 명령 앞뒤 어디에 와도 된다(SUPPRESS: 뒤에 안 줬을 때 앞의 값을 덮어쓰지 않는다)
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--stage", choices=list(STAGES), default=argparse.SUPPRESS)
    ap = argparse.ArgumentParser(description="학교급 단어 파일의 뼈대를 만들고 검사한다", parents=[common])
    sub = ap.add_subparsers(dest="command", required=True)
    sub.add_parser("skeleton", parents=[common], help="csv 순서대로 번호를 붙인 빈 뼈대를 쓴다")
    p_check = sub.add_parser("check", parents=[common], help="채운 파일을 검사한다")
    p_check.add_argument("cells", nargs="*", metavar="칸")
    p_check.add_argument("--full", action="store_true")
    p_fix = sub.add_parser("fix", parents=[common], help="검토가 낸 고칠 줄을 적용한다")
    p_fix.add_argument("file", metavar="파일")
    args = ap.parse_args()
    STAGE = getattr(args, "stage", "elementary")

    if args.command == "skeleton":
        skeleton()
    elif args.command == "check":
        unknown = [c for c in args.cells if c not in cells()]
        if unknown:
            sys.exit(f"{STAGE}에 없는 칸: {', '.join(unknown)} (이 학교급의 칸: {', '.join(cells())})")
        check(args.cells or cells(), args.full)
    else:
        fix(args.file)


if __name__ == "__main__":
    main()
