#!/usr/bin/env python3
"""Measures how much Soul Ash a finished autotest run pays (Ossuary expansion, step 1).

Runs the headless autotest (never with --meta-save, so the real save is untouched), parses the
`[autotest] soul ash:` line plus the `difficulty` / `stage` / `hyper` lines of each run, and writes
a CSV (one row per run) and a markdown table (median Soul Ash per stage x configuration).

Usage:
    python3 tools/ash_measure.py [--godot PATH] [--out DIR] [--jobs 2] [--only ARMY|NAIVE|ALL]
                                 [--seeds 1,2] [--parse-only]

Outputs (in --out, default build/ash_measure):
    runs.csv      one row per run (stage, difficulty, hyper, policy, meta, seed, total, parts, bonus lines)
    table.md      median total per stage x configuration, plus the naive lower bound
    logs/*.log    the raw autotest output of every run (re-parsed by --parse-only)

Run matrix (the owner asked to keep it to about 80 runs):
    army:  9 stages x {necromancer, lich, deathlord, deathlord+hyper} x seeds 1,2   (--policy=army --meta=mid --mortal)
    naive: 9 stages x necromancer x seed 1                                          (--policy=naive --meta=none --mortal)
"""
import argparse
import csv
import re
import statistics
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

# The nine stages in campaign order (act, stage number within the act).
STAGES = ["graveyard", "crimson_march", "sanctum", "harbour", "archive", "spire", "wastes", "assembly", "citadel"]
# Difficulty / Hyper configurations measured with the army bot.
ARMY_CONFIGS = [("necromancer", False), ("lich", False), ("deathlord", False), ("deathlord", True)]
DEFAULT_GODOT = "/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64"

# `[autotest] soul ash: +TOTAL (time N [..] + kills N [N] + elites N [N] + boss N + reckoning N [x s] (+ objectives N) = SUB,
#   bonus +P% = +B, pact +X, oath +Y) | bounty N | new total N | saved: ...`
RE_ASH = re.compile(
    r"soul ash: \+(?P<total>-?\d+) \(time (?P<time>\d+) \[(?P<tclock>[^\]]*)\] \+ kills (?P<kills>\d+) \[(?P<nk>\d+)\]"
    r" \+ elites (?P<elites>\d+) \[(?P<ne>\d+)\] \+ boss (?P<boss>\d+) \+ reckoning (?P<reck>\d+) \[(?P<rs>[\d.]+) s\]"
    r"(?: \+ objectives (?P<obj>\d+))? = (?P<sub>\d+), bonus \+(?P<bpct>-?\d+)% = \+(?P<bonus>\d+),"
    r" pact \+(?P<pact>\d+), oath \+(?P<oath>\d+)\) \| bounty (?P<bounty>\d+)")
RE_DIFF = re.compile(r"difficulty results: soul ash difficulty (?P<diff>[+-]\d+), modifiers \+(?P<mods>\d+)")
RE_STAGE = re.compile(r"soul ash stage bonus \+(?P<stage>\d+) \(x(?P<mult>[\d.]+)\)")
RE_HYPER = re.compile(r"soul ash hyper \+(?P<hyper>\d+) \(\+(?P<hpct>\d+)%\)")


def plan(seeds):
    """The list of run descriptions (dicts)."""
    runs = []
    for stage in STAGES:
        for diff, hyper in ARMY_CONFIGS:
            for seed in seeds:
                runs.append(dict(stage=stage, difficulty=diff, hyper=hyper, policy="army", meta="mid", seed=seed))
    for stage in STAGES:
        runs.append(dict(stage=stage, difficulty="necromancer", hyper=False, policy="naive", meta="none", seed=1))
    return runs


def run_name(r):
    return "%s_%s%s_%s_%s_s%d" % (r["stage"], r["difficulty"], "+hyper" if r["hyper"] else "", r["policy"], r["meta"], r["seed"])


def command(godot, r):
    cmd = [godot, "--headless", "--fixed-fps", "60", "--quit-after", "40000", "--", "--autotest",
           "--seed=%d" % r["seed"], "--stage=" + r["stage"], "--policy=" + r["policy"],
           "--difficulty=" + r["difficulty"], "--meta=" + r["meta"], "--mortal"]
    if r["hyper"]:
        cmd.append("--hyper")
    return cmd


def parse(text):
    """Parses one autotest log into a dict of numbers, or None when the Soul Ash line is missing."""
    m = RE_ASH.search(text)
    if not m:
        return None
    out = {k: (int(v) if v is not None and re.fullmatch(r"-?\d+", v) else v) for k, v in m.groupdict().items() if v is not None}
    out.setdefault("obj", 0)
    out["time_clock"] = out.pop("tclock")
    for rx, keys in ((RE_DIFF, ("diff", "mods")), (RE_STAGE, ("stage", "mult")), (RE_HYPER, ("hyper", "hpct"))):
        mm = rx.search(text)
        for k in keys:
            out["b_" + k] = mm.group(k) if mm else "0"
    out["errors"] = len(re.findall(r"SCRIPT ERROR|^ERROR:|^WARNING:", text, re.M))
    ms = re.search(r"stuck_units=(\d+)", text)
    out["stuck"] = ms.group(1) if ms else ""
    mr = re.search(r"\[autotest\] result: ([A-Za-z]+)", text)  # VICTORY / DEFEAT ...
    out["outcome"] = mr.group(1) if mr else ""
    return out


def execute(args, r):
    log = Path(args.out) / "logs" / (run_name(r) + ".log")
    done = log.exists() and parse(log.read_text(errors="replace")) is not None  # A finished log is reused (resume).
    if not args.parse_only and not done:
        print("running", run_name(r), flush=True)
        with open(log, "w") as fh:
            try:
                subprocess.run(command(args.godot, r), stdout=fh, stderr=subprocess.STDOUT, timeout=1500, check=False)
            except subprocess.TimeoutExpired:
                fh.write("\n[ash_measure] TIMEOUT\n")
    text = log.read_text(errors="replace") if log.exists() else ""
    parsed = parse(text)
    if parsed is None:
        print("FAILED (no soul ash line):", run_name(r), flush=True)
    return r, parsed


def med(values):
    return statistics.median(values) if values else None


def write_outputs(args, results):
    out = Path(args.out)
    cols = ["stage", "difficulty", "hyper", "policy", "meta", "seed", "total", "sub", "time", "kills", "nk", "elites", "ne", "boss",
            "reck", "rs", "obj", "bpct", "bonus", "pact", "oath", "b_stage", "b_mult", "b_diff", "b_mods", "b_hyper", "bounty",
            "time_clock", "outcome", "stuck", "errors"]
    with open(out / "runs.csv", "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        for r, p in results:
            if p is not None:
                w.writerow({**r, **p})
    failed = [run_name(r) for r, p in results if p is None]

    def cell(policy, diff, hyper, stage):
        vals = [p["total"] for r, p in results if p and r["policy"] == policy and r["difficulty"] == diff
                and r["hyper"] == hyper and r["stage"] == stage]
        return med(vals), vals

    lines = ["# Soul Ash per run (median over seeds)", "",
             "Army bot, `--meta=mid`, `--mortal`, seeds %s. Naive: `--policy=naive --meta=none`, seed 1. Generated by `tools/ash_measure.py`." % args.seeds, "",
             "| Stage | Necromancer | Lich | Deathlord | Deathlord + Hyper | Naive (Necromancer, no meta) |", "|---|---|---|---|---|---|"]
    for stage in STAGES:
        row = [stage]
        for diff, hyper in ARMY_CONFIGS:
            m, v = cell("army", diff, hyper, stage)
            row.append("-" if m is None else ("%d (%s)" % (m, "/".join(str(x) for x in v))))
        m, v = cell("naive", "necromancer", False, stage)
        row.append("-" if m is None else str(m))
        lines.append("| " + " | ".join(row) + " |")
    lines += ["", "Cells are `median (each seed)`. Failed runs (no Soul Ash line): %s" % (", ".join(failed) if failed else "none")]
    (out / "table.md").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--godot", default=DEFAULT_GODOT)
    ap.add_argument("--out", default="build/ash_measure")
    ap.add_argument("--jobs", type=int, default=2, help="parallel Godot processes (the machine is shared: max 2)")
    ap.add_argument("--seeds", default="1,2", help="seeds of the army runs")
    ap.add_argument("--only", default="ALL", choices=["ALL", "ARMY", "NAIVE"])
    ap.add_argument("--parse-only", action="store_true", help="re-parse existing logs without running Godot")
    args = ap.parse_args()
    (Path(args.out) / "logs").mkdir(parents=True, exist_ok=True)
    seeds = [int(s) for s in args.seeds.split(",")]
    runs = [r for r in plan(seeds) if args.only == "ALL" or r["policy"].upper() == args.only]
    with ThreadPoolExecutor(max_workers=max(1, min(args.jobs, 2))) as ex:
        results = list(ex.map(lambda r: execute(args, r), runs))
    write_outputs(args, results)
    return 0


if __name__ == "__main__":
    sys.exit(main())
