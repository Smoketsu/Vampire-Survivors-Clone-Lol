#!/usr/bin/env bash
# Rebuilds the Necropathy complete-game inventory from the game's data files in one command.
#
# Role: runs the three inventory steps in order:
#   1. tools/inventory_extract.py   scripts/data/*.gd + assets/  ->  <out-dir>/model.json
#   2. tools/inventory_render.py    model.json  ->  <out-dir>/necropathy_inventory_plain.html
#                                                   and docs/INVENTORY.md (the Markdown twin)
#   3. tools/make_inventory_page.py plain page + sprites  ->  <out-dir>/necropathy_inventory.html
#                                                   (the final page with lazy sprite thumbnails)
# Needs only python3 (no Godot, no network, no saves touched).
#
# Usage: tools/rebuild_inventory.sh <out-dir>
#   <out-dir>  folder for the generated files (created if missing); keep it outside the repo.
set -euo pipefail
if [ $# -ne 1 ]; then
  echo "usage: tools/rebuild_inventory.sh <out-dir>" >&2
  exit 2
fi
OUT="$1"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$OUT"
python3 "$HERE/inventory_extract.py" --out-dir "$OUT"
python3 "$HERE/inventory_render.py" --model "$OUT/model.json" --out-dir "$OUT"
python3 "$HERE/make_inventory_page.py" --in "$OUT/necropathy_inventory_plain.html" \
  --out "$OUT/necropathy_inventory.html" --model "$OUT/model.json"
