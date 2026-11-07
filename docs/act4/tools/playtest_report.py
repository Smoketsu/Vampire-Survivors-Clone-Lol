"""Act IV balance playtest report: one row per autotest log of playtest_batch.sh, then a per stage x build
summary. usage: python3 docs/act4/tools/playtest_report.py <log dir> [<log dir> ...]
Columns: result (WIN = reached 0:00, DIED = died before it), when it ended, lowest HP before 0:00 (from the
minute lines), boss slain and when, kills, level, build complete, evolutions (count and first), chests opened,
Soul Ash, errors (SCRIPT ERROR / ERROR: / WARNING: lines) and stuck units."""
import glob
import os
import re
import sys
from collections import defaultdict


def mmss(sec: float) -> str:
    return "%d:%02d" % (int(sec) // 60, int(sec) % 60)


def parse(path: str) -> dict:
    s = open(path, errors="replace").read()
    name = os.path.basename(path)[:-4]
    stage, build, seed = re.match(r"(.+)_(\w+?)_s(\d+)$", name).groups()
    g = lambda pat, d="": (re.search(pat, s).group(1) if re.search(pat, s) else d)
    res = g(r"result: ([A-Z ]+)").strip()
    hps = [int(m.group(2)) for m in re.finditer(r"\[autotest\] t=(\d\d):\d\d .*? hp=(\d+)", s) if int(m.group(1)) < 20]
    boss_at = g(r"boss defeated: yes at ([\d.]+)")
    evo = g(r"\[autotest\] evolutions: (.*)")
    evos = [e for e in evo.split(", ") if "@" in e]
    return {
        "stage": stage, "build": build, "seed": int(seed),
        "result": "WIN" if res.startswith("VICTORY") else "DIED" if res else "?",
        "ended": g(r"time reached: ([\d:]+)"),
        "min_hp": min(hps) if hps else -1,
        "boss": mmss(float(boss_at)) if boss_at else "-",
        "kills": int(g(r"kills: (\d+)", "0")), "level": int(g(r"\| level: (\d+)", "0")),
        "build_done": g(r"build complete: at ([\d:]+)", "-"),
        "evos": len(evos), "first_evo": evos[0].split("@")[1] if evos else "-",
        "chests": int(g(r"chests: spawned \d+, opened (\d+)", "0")),
        "ash": int(g(r"soul ash: \+(\d+)", "0")),
        "errors": len(re.findall(r"SCRIPT ERROR|ERROR:|WARNING:", s)),
        "stuck": int(g(r"stuck_units=(\d+)", "-1")),
    }


def main() -> None:
    rows = [parse(p) for d in sys.argv[1:] for p in sorted(glob.glob(os.path.join(d, "*.log")))]
    hdr = ["stage", "build", "seed", "result", "ended", "min_hp", "boss", "kills", "level", "build_done", "evos",
           "first_evo", "chests", "ash", "errors", "stuck"]
    print("| " + " | ".join(hdr) + " |\n|" + "---|" * len(hdr))
    for r in rows:
        print("| " + " | ".join(str(r[h]) for h in hdr) + " |")
    print("\nSummary per stage and build (deaths before 0:00, boss kills, mean lowest HP, mean kills, mean Soul Ash):\n")
    agg = defaultdict(list)
    for r in rows:
        agg[(r["stage"], r["build"])].append(r)
        agg[(r["stage"], "ALL")].append(r)
    print("| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |\n|---|---|---|---|---|---|---|---|")
    for (st, b), rs in sorted(agg.items()):
        n = len(rs)
        print("| %s | %s | %d | %d | %d | %.0f | %.0f | %.0f |" % (st, b, n, sum(r["result"] == "DIED" for r in rs),
              sum(r["boss"] != "-" for r in rs), sum(r["min_hp"] for r in rs) / n, sum(r["kills"] for r in rs) / n,
              sum(r["ash"] for r in rs) / n))


if __name__ == "__main__":
    main()
