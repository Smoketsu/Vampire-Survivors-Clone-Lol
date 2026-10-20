#!/usr/bin/env python3
"""Co-op determinism gate of Necropathy: two headless Godot processes play ONE co-op run through the lockstep.

Starts tools/coop_relay.py on a free port (optionally with test latency / jitter), then two headless autotest
processes (`--autotest --coop-net=host|join`, scripts/coop/coop_net_bot.gd): the host opens a lobby and prints its
code, the join process joins it; the host starts with --seed, and each process's army bot plays ITS slot through
CoopLockstep (only the inputs travel). Both run the whole simulation and compare a state checksum every 60 ticks.

Passes when: both processes exit with the same code; neither printed a SCRIPT ERROR / ERROR / WARNING line; neither
reported a desync; both ran the same number of ticks with the same checksum chain and final state; the per-slot
`coop slot` lines and the `coop:` line match; stuck_units=0 on both. Prints the frames each side sent (the bundling).

    python3 tools/coop_lockstep_gate.py [--godot PATH] [--seed 7] [--speed 8] [--stage graveyard]
        [--delay-ms 0 --jitter-ms 0] [--kill-join-at SECONDS] [--timeout-game SECONDS] [--] [extra autotest flags]

--kill-join-at T kills the join process (SIGKILL, no goodbye) once it reports game time T: the drop test. The host
must then finish the run alone with the bot steering the guest's slot (`partner lost ... bot took over`).
--timeout-game T ends both runs at game second T (`--timeout=`), for a shorter CI gate.
--real-time paces both by the clock (with --speed 1: a real 60 Hz game, for the latency test).
--web-join prints the join command line instead of starting it (the Web build joins by hand, see README).
Exit status 0 on success.
"""

import argparse
import os
import re
import signal
import subprocess
import sys
import threading
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_GODOT = os.environ.get("GODOT", "/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64")
BAD_LINE = re.compile(r"SCRIPT ERROR|^ERROR:|^WARNING:|\bERROR:")
CLOCK = re.compile(r"^\[autotest\] t=(\d+):(\d+) ")


def pump(proc, sink, tag, found, echo):
    for raw in proc.stdout:
        line = raw.rstrip("\n")
        sink.append(line)
        if echo or line.startswith("[coop]") or line.startswith("COOP_") or BAD_LINE.search(line) \
                or "lockstep" in line or CLOCK.match(line):
            print("[%s] %s" % (tag, line), flush=True)
        m = re.match(r"COOP_CODE=([A-Z]{5})", line)
        if m:
            found["code"] = m.group(1)
        m = CLOCK.match(line)
        if m:
            found[tag + "_t"] = int(m.group(1)) * 60 + int(m.group(2))


def godot(binary, args, real_time=False):
    pace = [] if real_time else ["--fixed-fps", "60"]  # --fixed-fps: as fast as the CPU goes; without it, real time.
    return subprocess.Popen([binary, "--headless", "--path", ROOT] + pace + ["--"] + args,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)


def pick(lines, prefix):
    return [l for l in lines if l.startswith(prefix)]


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--godot", default=DEFAULT_GODOT)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--speed", type=float, default=8.0)
    ap.add_argument("--stage", default="graveyard")
    ap.add_argument("--delay-ms", type=float, default=0.0)
    ap.add_argument("--jitter-ms", type=float, default=0.0)
    ap.add_argument("--kill-join-at", type=float, default=-1.0)
    ap.add_argument("--timeout-game", type=float, default=0.0)
    ap.add_argument("--wall-timeout", type=float, default=1800.0)
    ap.add_argument("--host-character", default="gravecaller")
    ap.add_argument("--join-character", default="bone_oracle")
    ap.add_argument("--relay", default="", help="use this relay instead of starting the local one")
    ap.add_argument("--web-join", action="store_true", help="start only the host and print the code (a Web page joins)")
    ap.add_argument("--echo", action="store_true", help="echo every line of both processes")
    ap.add_argument("--real-time", action="store_true",
                    help="pace both processes by the clock (no --fixed-fps; with --speed 1 a real 60 Hz game)")
    ap.add_argument("extra", nargs="*", help="extra autotest flags for both processes")
    args = ap.parse_args()

    relay_proc = None
    relay = args.relay
    if relay == "":
        cmd = [sys.executable, os.path.join(ROOT, "tools", "coop_relay.py"), "--port", "0", "--quiet",
               "--delay-ms", str(args.delay_ms), "--jitter-ms", str(args.jitter_ms), "--seed", str(args.seed)]
        relay_proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        first = relay_proc.stdout.readline().split()
        if len(first) != 3 or first[0] != "LISTENING":
            print("relay did not start: %s" % first)
            return 1
        relay = "ws://127.0.0.1:%s" % first[2]
    print("relay %s (delay %g ms, jitter %g ms)" % (relay, args.delay_ms, args.jitter_ms), flush=True)

    common = ["--autotest", "--relay=" + relay, "--seed=%d" % args.seed, "--speed=%g" % args.speed,
              "--stage=" + args.stage, "--policy=army"] + args.extra
    if args.timeout_game > 0:
        common.append("--timeout=%g" % args.timeout_game)
    out_h, out_j, found = [], [], {}
    t0 = time.time()
    host = godot(args.godot, common + ["--coop-net=host", "--character=" + args.host_character], args.real_time)
    th = threading.Thread(target=pump, args=(host, out_h, "host", found, args.echo), daemon=True)
    th.start()
    while "code" not in found and host.poll() is None and time.time() - t0 < 90:
        time.sleep(0.1)
    if "code" not in found:
        print("FAIL: the host printed no lobby code")
        host.kill()
        if relay_proc:
            relay_proc.kill()
        return 1
    join_args = common + ["--coop-net=join", "--coop-code=" + found["code"], "--character=" + args.join_character]
    if args.web_join:
        print("JOIN_FLAGS=" + ",".join(a for a in join_args if not a.startswith("--relay=") and a != "--autotest"), flush=True)
        code = host.wait(timeout=args.wall_timeout)
        th.join(5)
        if relay_proc:
            relay_proc.kill()
        print("host exit %s" % code)
        for l in pick(out_h, "[autotest] coop") + pick(out_h, "[coop]"):
            print(l)
        return 0 if code in (0, 1) else 1
    join = godot(args.godot, join_args, args.real_time)
    tj = threading.Thread(target=pump, args=(join, out_j, "join", found, args.echo), daemon=True)
    tj.start()
    killed = False
    codes = {}
    while time.time() - t0 < args.wall_timeout:
        if args.kill_join_at >= 0 and not killed and found.get("join_t", -1) >= args.kill_join_at:
            join.send_signal(signal.SIGKILL)
            killed = True
            print("[gate] join process killed at game time %d s" % found.get("join_t", -1), flush=True)
        for name, p in (("host", host), ("join", join)):
            if name not in codes and p.poll() is not None:
                codes[name] = p.returncode
        if len(codes) == 2:
            break
        time.sleep(0.2)
    for name, p in (("host", host), ("join", join)):
        if name not in codes:
            p.kill()
            codes[name] = -999
    th.join(5)
    tj.join(5)
    if relay_proc:
        relay_proc.kill()
    wall = time.time() - t0

    fails = []
    for name, out in (("host", out_h), ("join", out_j)):
        bad = [l for l in out if BAD_LINE.search(l)]
        if bad:
            fails.append("%s printed %d error/warning line(s): %s" % (name, len(bad), bad[0]))
        if any("DESYNC" in l for l in out):
            fails.append("%s reported a desync: %s" % (name, [l for l in out if "DESYNC" in l][0]))
        stuck = [l for l in out if l.startswith("[autotest] stuck_units=")]
        if stuck and not stuck[0].startswith("[autotest] stuck_units=0 "):
            fails.append("%s: %s" % (name, stuck[0]))
    ls_h = pick(out_h, "[autotest] coop lockstep:")
    ls_j = pick(out_j, "[autotest] coop lockstep:")
    end_h = pick(out_h, "[coop] run ended")
    end_j = pick(out_j, "[coop] run ended")
    if not ls_h:
        fails.append("host printed no lockstep line")
    if killed:
        if codes["host"] not in (0, 1):
            fails.append("host exit %s after the drop" % codes["host"])
        if ls_h and "bot took over" not in ls_h[0]:
            fails.append("host did not hand the dropped slot to the bot")
    else:
        if not ls_j:
            fails.append("join printed no lockstep line")
        if codes["host"] != codes["join"]:
            fails.append("exit codes differ: host %s, join %s" % (codes["host"], codes["join"]))
        if end_h != end_j or not end_h:
            fails.append("final state differs: %s vs %s" % (end_h, end_j))

        def chain(l):
            m = re.search(r"ticks (\d+) .*chain ([0-9a-f]+)", l)
            return m.groups() if m else None
        if ls_h and ls_j and chain(ls_h[0]) != chain(ls_j[0]):
            fails.append("ticks / checksum chain differ: %s vs %s" % (chain(ls_h[0]), chain(ls_j[0])))
        sl_h = pick(out_h, "[autotest] coop slot") + pick(out_h, "[autotest] coop: ")
        sl_j = pick(out_j, "[autotest] coop slot") + pick(out_j, "[autotest] coop: ")
        if sl_h != sl_j or not sl_h:
            diff = [(a, b) for a, b in zip(sl_h, sl_j) if a != b]
            fails.append("per-slot summary differs: %s" % (diff[:1] if diff else "missing lines"))
    print("--- result (wall %.0f s) ---" % wall)
    print("exit codes: host %s, join %s%s" % (codes["host"], codes["join"], " (killed)" if killed else ""))
    for l in end_h + end_j + ls_h + ls_j:
        print(l)
    for l in pick(out_h, "[autotest] coop: "):
        print(l)
    print("PASS" if not fails else "FAIL: " + "; ".join(fails))
    return 0 if not fails else 1


if __name__ == "__main__":
    sys.exit(main())
