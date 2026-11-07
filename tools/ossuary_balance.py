#!/usr/bin/env python3
"""Ossuary expansion balance batch: runs the --mortal autotest over a config matrix and summarises it.

Matrix (the default batch, 104 runs): meta {none, max} x policy {army, naive} x stage {graveyard, harbour, citadel}
x seeds 1-8, plus `--meta=max --policy=army --difficulty=deathlord` on the Citadel x 8 seeds. Every run is a plain
`--autotest --mortal` (never --meta-save, so no save is touched). Logs are kept, so a re-run resumes where it stopped
and `--parse-only` rebuilds the tables from the logs without running Godot.

Per config it reports: deaths before 0:00, boss kills, lowest HP before 0:00 (median, min, in HP and % of max HP),
build-complete time (median), seconds survived past 0:00 (median, range), Soul Ash (median), and for meta max the
new systems that fired (the `ossuary options`, `masteries` and `rites` lines of the first seed).

Usage:
    python3 tools/ossuary_balance.py [--godot PATH] [--out DIR] [--jobs 4] [--seeds 1,2,...,8]
                                     [--only SUBSTRING] [--parse-only]
Outputs (in --out, default build/ossuary_balance): runs.csv, table.md, logs/*.log
"""
import argparse
import csv
import re
import statistics
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

DEFAULT_GODOT = "/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64"
STAGES = ["graveyard", "harbour", "citadel"]
RECKONING_AT = 1200.0  # Game seconds at which the countdown ends (20:00).


def plan(seeds):
    """All run descriptions (dicts): the 3 stages x 2 metas x 2 policies grid plus the Deathlord Citadel row."""
    runs = []
    for meta in ("none", "max"):
        for policy in ("army", "naive"):
            for stage in STAGES:
                for seed in seeds:
                    runs.append(dict(stage=stage, meta=meta, policy=policy, difficulty="necromancer", seed=seed))
    for seed in seeds:
        runs.append(dict(stage="citadel", meta="max", policy="army", difficulty="deathlord", seed=seed))
    runs += key_plan(seeds)
    return runs


# The KEY test (owner's "too strong" bar): everything bought AND Hyper + full Oath + Pact (--hyper --oath=5 --pact, the
# army / summon / evolve / naive bots take the Pact first with --pact) must fail (die before 0:00) in at least a third of
# the runs. Build families of 8 runs each: stage / difficulty rotate through STAGE_CYCLE, the seed is 1..8.
STAGE_CYCLE = [("graveyard", "necromancer"), ("harbour", "necromancer"), ("citadel", "necromancer"), ("citadel", "deathlord")]
FAMILIES = {
    "army": ["--policy=army"],
    "summon": ["--policy=summon"],
    "evolve": ["--policy=evolve"],
    "naive": ["--policy=naive"],
    "pact": ["--policy=pact"],
    "classes_a": ["--policy=summon", "--classes=abomination,rogue,gargoyle,frost_wraith"],
    "classes_b": ["--policy=summon", "--classes=bone_hound,banshee,corpse_catapult"],
    "spells_a": ["--policy=evolve", "--spells=bone_spear,soul_siphon,corpse_explosion,plague_cloud"],
    "spells_b": ["--policy=evolve", "--spells=death_mark,bone_wall,soul_chains"],
    "characters": ["--policy=army"],  # plus a --character rotating through CHARACTERS
}
CHARACTERS = ["bone_oracle", "wither_witch", "tide_widow", "rust_prophet"]  # Core, Core, Act II, Act III.


def key_plan(seeds, meta="max", families=None):
    runs = []
    for fam, flags in FAMILIES.items():
        if families and fam not in families:
            continue
        for i, seed in enumerate(seeds):
            stage, diff = STAGE_CYCLE[i % len(STAGE_CYCLE)]
            extra = list(flags)
            if fam == "characters":
                extra.append("--character=" + CHARACTERS[i % len(CHARACTERS)])
            policy = next(f.split("=")[1] for f in extra if f.startswith("--policy="))
            runs.append(dict(stage=stage, meta=meta, policy=policy, difficulty=diff, seed=seed, family=fam, extra=extra))
    return runs


def config_key(r):
    if r.get("family"):
        return "KEY Hyper+Oath5+Pact, meta %s, %s" % (r["meta"], r["family"])
    return "%s, meta %s, %s, %s" % (r["stage"], r["meta"], r["policy"], r["difficulty"])


def run_name(r):
    if r.get("family"):
        return "key%s_%s_%s_%s_s%d" % ("" if r["meta"] == "max" else "-" + r["meta"], r["family"], r["stage"], r["difficulty"], r["seed"])
    return "%s_%s_%s_%s_s%d" % (r["stage"], r["meta"], r["policy"], r["difficulty"], r["seed"])


def command(godot, r):
    cmd = [godot, "--headless", "--fixed-fps", "60", "--quit-after", "40000", "--", "--autotest",
           "--seed=%d" % r["seed"], "--stage=" + r["stage"], "--policy=" + r["policy"], "--difficulty=" + r["difficulty"],
           "--meta=" + r["meta"], "--mortal"]
    if r.get("family"):
        cmd += ["--hyper", "--oath=5", "--pact"] + [f for f in r["extra"] if not f.startswith("--policy=")]
    return cmd


def parse(text):
    """One autotest log -> dict, or None when the summary is missing."""
    m = re.search(r"time reached: (\S+) elapsed \(([\d.]+) s game time, ([\d.]+) s real time\); past 0:00: ([\d.]+) s", text)
    if not m:
        return None
    out = {"game_s": float(m.group(2)), "real_s": float(m.group(3)), "past": float(m.group(4))}
    out["died_before_0"] = out["game_s"] < RECKONING_AT - 0.5
    mb = re.search(r"boss defeated: (yes|no)", text)
    out["boss_killed"] = bool(mb and mb.group(1) == "yes")
    mh = re.search(r"min_hp_before_0=(-?\d+)", text)
    out["min_hp"] = int(mh.group(1)) if mh else -1
    mx = re.search(r"player max HP at start: (\d+)", text)
    out["max_hp"] = int(mx.group(1)) if mx else 0
    mc = re.search(r"build complete: at (\d+):(\d+)", text)
    out["build_s"] = int(mc.group(1)) * 60 + int(mc.group(2)) if mc else None
    ma = re.search(r"soul ash: \+(-?\d+) ", text)
    out["ash"] = int(ma.group(1)) if ma else 0
    ml = re.search(r"\| level: (\d+)", text)
    out["level"] = int(ml.group(1)) if ml else 0
    out["errors"] = len(re.findall(r"SCRIPT ERROR|^ERROR:|^WARNING:", text, re.M))
    ms = re.search(r"stuck_units=(\d+)", text)
    out["stuck"] = int(ms.group(1)) if ms else -1
    for key, rx in (("options", r"\[autotest\] ossuary options: (.*)"), ("masteries", r"\[autotest\] masteries: (.*)"),
                    ("rites", r"\[autotest\] rites: (.*)")):
        mm = re.search(rx, text)
        out[key] = mm.group(1).strip() if mm else ""
    return out


def execute(args, r):
    log = Path(args.out) / "logs" / (run_name(r) + ".log")
    done = log.exists() and parse(log.read_text(errors="replace")) is not None
    if not args.parse_only and not done:
        print("running", run_name(r), flush=True)
        with open(log, "w") as fh:
            try:
                subprocess.run(command(args.godot, r), stdout=fh, stderr=subprocess.STDOUT, timeout=2400, check=False)
            except subprocess.TimeoutExpired:
                fh.write("\n[ossuary_balance] TIMEOUT\n")
    text = log.read_text(errors="replace") if log.exists() else ""
    p = parse(text)
    if p is None:
        print("FAILED (no summary):", run_name(r), flush=True)
    return r, p


def mm(clock_s):
    return "-" if clock_s is None else "%d:%02d" % (clock_s // 60, clock_s % 60)


def med(v):
    return statistics.median(v) if v else None


def write_outputs(args, results):
    out = Path(args.out)
    cols = ["stage", "meta", "policy", "difficulty", "seed", "game_s", "past", "died_before_0", "boss_killed", "min_hp", "max_hp",
            "build_s", "ash", "level", "real_s", "stuck", "errors"]
    with open(out / "runs.csv", "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=cols, extrasaction="ignore")
        w.writeheader()
        for r, p in results:
            if p:
                w.writerow({**r, **p})
    groups = {}
    for r, p in results:
        groups.setdefault(config_key(r), []).append((r, p))
    lines = ["# Ossuary balance batch", "",
             "`--mortal`, seeds %s. Generated by `tools/ossuary_balance.py`." % args.seeds, "",
             "| Config | Runs | Deaths <0:00 | Boss kills | Min HP before 0:00 (median / min, % of max) | Build complete (median) | Past 0:00 s (median, range) | Soul Ash (median) | Errors / stuck |",
             "|---|---|---|---|---|---|---|---|---|"]
    detail = []
    for key, items in groups.items():
        ps = [p for _, p in items if p]
        n = len(items)
        if not ps:
            lines.append("| %s | 0/%d | - | - | - | - | - | - | - |" % (key, n))
            continue
        deaths = sum(1 for p in ps if p["died_before_0"])
        boss = sum(1 for p in ps if p["boss_killed"])
        hp = [p["min_hp"] for p in ps]
        pct = [100.0 * p["min_hp"] / p["max_hp"] for p in ps if p["max_hp"]]
        build = [p["build_s"] for p in ps if p["build_s"] is not None]
        past = [p["past"] for p in ps if not p["died_before_0"]]
        ash = [p["ash"] for p in ps]
        errs = sum(p["errors"] for p in ps)
        stuck = sum(1 for p in ps if p["stuck"] > 0)
        lines.append("| %s | %d/%d | %d | %d | %d / %d (%.0f%% / %.0f%%) | %s (%d/%d) | %s | %d | %d / %d |" % (
            key, len(ps), n, deaths, boss, med(hp), min(hp), med(pct) if pct else 0, min(pct) if pct else 0,
            mm(int(med(build))) if build else "-", len(build), len(ps),
            ("%.0f (%.0f-%.0f)" % (med(past), min(past), max(past))) if past else "-", med(ash), errs, stuck))
        if "meta max" in key:
            first = ps[0]
            detail.append("### %s (seed %s)\n- options: %s\n- masteries: %s\n- rites: %s\n" % (key, items[0][0]["seed"], first["options"], first["masteries"], first["rites"]))
    keyrows = [(r, p) for r, p in results if r.get("family") and p]
    if keyrows:
        d = sum(1 for _, p in keyrows if p["died_before_0"])
        lines += ["", "## KEY test overall: %d of %d runs died before 0:00 (%.0f%%; pass = at least one third)" % (d, len(keyrows), 100.0 * d / len(keyrows)), "",
                  "| Family | Stage / difficulty | Seed | Outcome | Min HP | Boss |", "|---|---|---|---|---|---|"]
        for r, p in keyrows:
            outcome = ("DIED at " + mm(int(p["game_s"]))) if p["died_before_0"] else "survived, +%.0f s past 0:00" % p["past"]
            lines.append("| %s | %s / %s | %d | %s | %d/%d | %s |" % (r["family"], r["stage"], r["difficulty"], r["seed"], outcome,
                                                                      p["min_hp"], p["max_hp"], "yes" if p["boss_killed"] else "no"))
    lines += ["", "Build complete shows `median (runs that completed / runs)`. Past 0:00 is over the runs that reached 0:00.", ""]
    lines += detail
    (out / "table.md").write_text("\n".join(lines) + "\n")
    print("\n".join(lines))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--godot", default=DEFAULT_GODOT)
    ap.add_argument("--out", default="build/ossuary_balance")
    ap.add_argument("--jobs", type=int, default=4, help="parallel Godot processes (max 4)")
    ap.add_argument("--seeds", default="1,2,3,4,5,6,7,8")
    ap.add_argument("--only", default="", help="substring of the run name to restrict to (e.g. citadel_max)")
    ap.add_argument("--order", default="", help="comma list of substrings; runs matching earlier ones go first")
    ap.add_argument("--parse-only", action="store_true", help="rebuild the tables from existing logs (runs without a log are skipped)")
    ap.add_argument("--no-key", action="store_true", help="leave the KEY families out of the default grid")
    ap.add_argument("--key-meta", default="max", help="run ONLY the KEY families at this meta (none|mid|max) instead of the grid")
    ap.add_argument("--families", default="", help="comma list of KEY families to keep")
    args = ap.parse_args()
    (Path(args.out) / "logs").mkdir(parents=True, exist_ok=True)
    seeds = [int(s) for s in args.seeds.split(",")]
    fams = [f for f in args.families.split(",") if f]
    base = key_plan(seeds, args.key_meta, fams) if args.key_meta != "max" or fams else plan(seeds)
    runs = [r for r in base if args.only in run_name(r) and not (args.no_key and r.get("family"))]
    if args.parse_only:
        runs = [r for r in runs if (Path(args.out) / "logs" / (run_name(r) + ".log")).exists()]
    if args.order:
        keys = args.order.split(",")
        runs.sort(key=lambda r: next((i for i, k in enumerate(keys) if k in run_name(r)), len(keys)))
    with ThreadPoolExecutor(max_workers=max(1, min(args.jobs, 4))) as ex:
        results = list(ex.map(lambda r: execute(args, r), runs))
    write_outputs(args, results)
    return 0


if __name__ == "__main__":
    sys.exit(main())
