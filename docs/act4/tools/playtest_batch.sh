#!/bin/bash
# Act IV balance playtest batch (owner, Oct 2026: "varied builds, no naive builds"; the numbers feed the
# owner's balance decisions). One stage, the five builds x the seeds below, ONE Godot process at a time
# (four of these may run in parallel on the 4-core machine), all `--mortal`.
# usage: playtest_batch.sh <stage> <outdir> [seeds...]   (default seeds 3 7 11)
STAGE=$1; OUT=$2; shift 2; SEEDS=${@:-3 7 11}; mkdir -p "$OUT"
G=/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64
TREE=$(cd "$(dirname "$0")/../../.." && pwd)
# Build id -> autotest flags. No naive policy (owner): army, the spell build, the summon-evolution build,
# a newer-classes army and a newer-spells spell build.
declare -A BUILDS=(
  [army]="--policy=army"
  [evolve]="--policy=evolve"
  [summon]="--policy=summon"
  [newclasses]="--policy=army --classes=abomination,rogue,gargoyle,frost_wraith"
  [newspells]="--policy=evolve --spells=bone_spear,soul_siphon,corpse_explosion,plague_cloud"
)
for b in army evolve summon newclasses newspells; do
  for s in $SEEDS; do
    f="$OUT/${STAGE}_${b}_s${s}.log"
    [ -f "$f" ] && grep -q "^exit" "$f" && continue  # Done already (rerunnable).
    timeout 1500 $G --headless --path "$TREE" --fixed-fps 60 --quit-after 15000 -- --autotest --mortal \
      --stage=$STAGE --seed=$s ${BUILDS[$b]} > "$f" 2>&1
    echo "exit $?" >> "$f"
  done
done
echo "batch done: $STAGE"
