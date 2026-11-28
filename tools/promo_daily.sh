#!/bin/sh
# promo_daily.sh: renders one daily TikTok clip from tools/promo_specs/daily_days.py.
# Usage: tools/promo_daily.sh DATE [OUT]
#   DATE  the clip's key in daily_days.py, "YYYY-MM-DD"
#   OUT   output folder (default build/promo/daily): <OUT>/DATE.mp4 is the long cut, <OUT>/DATE_tiktok.mp4 the
#         quick cut to post, <OUT>/storyboard.png the contact sheet to check by eye
# Needs the Godot 4.3 binary (GODOT, default /home/user/tools/godot/...), ffmpeg, xvfb-run, python3 + Pillow.
set -e
cd "$(dirname "$0")/.."
DATE="$1"                          # clip key (date text)
OUT="${2:-build/promo/daily}"      # output folder
SPEC="tools/promo_specs/daily/$DATE.json"  # spec JSON written by make_specs2.py
GODOT="${GODOT:-/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64}"  # Godot 4.3 binary
# A fresh clone has no import cache: without it the game records blank frames and never reaches its spans.
test -d .godot/imported || "$GODOT" --headless --import >/dev/null 2>&1 || true
python3 tools/promo_specs/make_specs2.py daily_days.py daily
test -f "$SPEC" || { echo "no add(\"$DATE\", ...) in tools/promo_specs/daily_days.py" >&2; exit 1; }
python3 tools/make_promo_clip.py --spec "$SPEC" --out "$OUT" --work "$OUT/work" --jobs 3
CUTS=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['cuts'])" "$SPEC")  # later shots the quick cut keeps
python3 tools/promo_quickcut.py "$SPEC" "$OUT/$DATE.mp4" "$OUT/${DATE}_tiktok.mp4" "$CUTS"
