# Quick-cut a long promo clip: hook (2.2 s over shot 1), 1.5 s from up to MAXCUTS later shots, last 2 s of the end card.
# Usage: python3 tools/promo_quickcut.py <spec.json> <long.mp4> <out.mp4> [max_cuts]
#   max_cuts (optional, default 3): how many later shots get a 1.5 s cut; Day 6 passes 4 so all five bosses appear.
import json, subprocess, sys
spec, src, out = sys.argv[1:4]
HOOK = 2.2   # s: the hook line's on-screen time (matches the spec's text "to")
CUT = 1.5    # s: each later shot's cut, owner request
SKIP = 0.4   # s: skipped at a shot's start so a cut never opens on the switch frame
END = 2.0    # s: tail of the end card kept
MAXCUTS = int(sys.argv[4]) if len(sys.argv) > 4 else 3  # later shots used (optional 4th argument), 3 keeps the clip near 7-8 s
shots = json.load(open(spec))["shots"]
offs, t = [], 0.0
for s in shots: offs.append(t); t += s["seconds"]
segs = [(0.0, HOOK)] + [(o + SKIP, o + SKIP + CUT) for o in offs[1:-1][:MAXCUTS]] + [(t - END, t)]
f = []
for i, (a, b) in enumerate(segs):
    f.append(f"[0:v]trim={a:.3f}:{b:.3f},setpts=PTS-STARTPTS[v{i}];[0:a]atrim={a:.3f}:{b:.3f},asetpts=PTS-STARTPTS,afade=t=in:d=0.05,afade=t=out:st={b-a-0.08:.3f}:d=0.08[a{i}]")
f.append("".join(f"[v{i}][a{i}]" for i in range(len(segs))) + f"concat=n={len(segs)}:v=1:a=1[v][a]")
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", src, "-filter_complex", ";".join(f), "-map", "[v]", "-map", "[a]",
    "-c:v", "libx264", "-profile:v", "high", "-pix_fmt", "yuv420p", "-tune", "animation", "-crf", "14",
    "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", out], check=True)
print(out, f"{sum(b - a for a, b in segs):.1f} s, {len(segs) - 2} extra cuts")
