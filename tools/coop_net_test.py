#!/usr/bin/env python3
"""Two-process co-op network test of Necropathy (CoopNet against the local relay).

Starts tools/coop_relay.py on a free port, then two headless Godot processes (CoopNetTest,
scripts/coop/coop_net_test.gd): the host opens a lobby and prints its code, the join process joins by that
code; they exchange loadouts, start, then send N numbered frames each way, checking order, integrity and the
round-trip times; the guest quits first and the host must see partner_left. A third process then checks the
client's error paths (bad code, no lobby, unreachable relay). Passes when every process reports ok, both got the
same start info (hash), and none printed a SCRIPT ERROR / ERROR / WARNING line.

    python3 tools/coop_net_test.py [--godot PATH] [--frames 10000] [--rate 240] [--relay ws://...]

--relay points both processes at another relay (e.g. `wrangler dev`) instead of starting the local one.
Exit status 0 on success.
"""

import argparse
import os
import re
import subprocess
import sys
import threading
import time

# Repository root (the Godot project).
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Default Godot binary (cloud sessions; CI passes --godot).
DEFAULT_GODOT = os.environ.get("GODOT", "/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64")
# Seconds allowed for the whole test.
TIMEOUT = 300
# Lines that fail the test when a Godot process prints them.
BAD_LINE = re.compile(r"SCRIPT ERROR|^ERROR:|^WARNING:|\bERROR:")


def pump(proc, sink, tag, found):
    """Copies a process's output lines into `sink`, echoing them with `tag`, and notes the lobby code."""
    for raw in proc.stdout:
        line = raw.rstrip("\n")
        sink.append(line)
        print("[%s] %s" % (tag, line), flush=True)
        m = re.match(r"COOP_CODE=([A-Z]{5})", line)
        if m:
            found["code"] = m.group(1)


def godot(args, binary):
    return subprocess.Popen([binary, "--headless", "--max-fps", "120", "--path", ROOT, "--"] + args,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--godot", default=DEFAULT_GODOT)
    ap.add_argument("--frames", type=int, default=10000)
    ap.add_argument("--rate", type=float, default=240.0)
    ap.add_argument("--relay", default="")
    args = ap.parse_args()

    relay_proc = None
    relay = args.relay
    if relay == "":
        relay_proc = subprocess.Popen([sys.executable, os.path.join(ROOT, "tools", "coop_relay.py"), "--port", "0", "--quiet"],
                                      stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
        first = relay_proc.stdout.readline().split()
        if len(first) != 3 or first[0] != "LISTENING":
            print("relay did not start: %s" % first)
            return 1
        relay = "ws://127.0.0.1:%s" % first[2]
    print("relay %s" % relay, flush=True)

    common = ["--relay=" + relay, "--coop-frames=%d" % args.frames, "--coop-rate=%g" % args.rate]
    out_h, out_j, found = [], [], {}
    host = godot(["--coop-net-test=host"] + common, args.godot)
    th = threading.Thread(target=pump, args=(host, out_h, "host", found), daemon=True)
    th.start()
    t0 = time.time()
    while "code" not in found and host.poll() is None and time.time() - t0 < 60:
        time.sleep(0.1)
    if "code" not in found:
        print("FAIL: the host printed no lobby code")
        host.kill()
        if relay_proc:
            relay_proc.kill()
        return 1
    join = godot(["--coop-net-test=join", "--coop-code=" + found["code"]] + common, args.godot)
    tj = threading.Thread(target=pump, args=(join, out_j, "join", found), daemon=True)
    tj.start()
    codes = []
    for p in (host, join):
        try:
            codes.append(p.wait(timeout=max(1, TIMEOUT - (time.time() - t0))))
        except subprocess.TimeoutExpired:
            p.kill()
            codes.append(-1)
    th.join(5)
    tj.join(5)
    # The client's error paths (bad code, no lobby, unreachable relay), against the same relay.
    out_e = []
    errs = godot(["--coop-net-test=errors"] + common, args.godot)
    te = threading.Thread(target=pump, args=(errs, out_e, "errors", found), daemon=True)
    te.start()
    try:
        codes.append(errs.wait(timeout=90))
    except subprocess.TimeoutExpired:
        errs.kill()
        codes.append(-1)
    te.join(5)
    if relay_proc:
        relay_proc.kill()

    fails = []
    hashes = []
    for name, out, code in (("host", out_h, codes[0]), ("join", out_j, codes[1]), ("errors", out_e, codes[2])):
        if code != 0:
            fails.append("%s exit %s" % (name, code))
        if not any(l.startswith("COOP_NET_RESULT") and "ok=true" in l for l in out):
            fails.append("%s reported no ok result" % name)
        bad = [l for l in out if BAD_LINE.search(l)]
        if bad:
            fails.append("%s printed %d error/warning line(s): %s" % (name, len(bad), bad[0]))
        hashes += [l.split("=", 1)[1] for l in out if l.startswith("COOP_START_HASH=")]
    if len(hashes) != 2 or hashes[0] != hashes[1]:
        fails.append("start info differs between the machines: %s" % hashes)
    print("start info identical: %s" % (len(hashes) == 2 and hashes[0] == hashes[1]))
    for l in out_h + out_j + out_e:
        if l.startswith("COOP_NET_RESULT") or l.startswith("COOP_ERROR_CASE"):
            print(l)
    print("PASS" if not fails else "FAIL: " + "; ".join(fails))
    return 0 if not fails else 1


if __name__ == "__main__":
    sys.exit(main())
