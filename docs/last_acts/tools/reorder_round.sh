#!/bin/bash
# Reorder pass part 3 playtest round (copied from docs/act7/tools/playtest_round.sh): runs the NEXT (up to) PAR missing logs of the playtest batch in parallel and waits, so each call
# stays short (~2-4 min) and can run in the foreground. Call it again until it prints "all done".
# usage: playtest_round.sh <outdir> [stages...]   (default: the three Act VII stages)
# OUT    = the log directory (one <stage>_<build>_s<seed>.log per run, ending with an "exit N" line when finished).
# STAGES = the stage ids to cover; SEEDS = the seeds per build; BUILDS = build id -> autotest flags (as the Act IV batch).
OUT=$1; shift; STAGES=${@:-ravensmoor witchwood castle_sanguis}; SEEDS=${SEEDS:-"3 7"}  # Seeds per build (two by default for the 21-stage reorder batch; SEEDS="3 7 11" for the full set).
PAR=${PAR:-4}  # Runs at once (CLAUDE.md: at most 4 Godot processes on the 4-core machine).
mkdir -p "$OUT"
G=/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64
TREE=$(cd "$(dirname "$0")/../../.." && pwd)  # Repository root.
declare -A BUILDS=(
  [army]="--policy=army"
  [evolve]="--policy=evolve"
  [summon]="--policy=summon"
  [newclasses]="--policy=army --classes=abomination,rogue,gargoyle,frost_wraith"
  [newspells]="--policy=evolve --spells=bone_spear,soul_siphon,corpse_explosion,plague_cloud"
)
todo=()  # The runs still missing a finished log, as "stage build seed".
for st in $STAGES; do for b in army evolve summon newclasses newspells; do for s in $SEEDS; do
  f="$OUT/${st}_${b}_s${s}.log"
  [ -f "$f" ] && grep -q "^exit" "$f" && continue
  todo+=("$st $b $s")
done; done; done
[ ${#todo[@]} -eq 0 ] && { echo "all done"; exit 0; }
for job in "${todo[@]:0:$PAR}"; do
  read -r st b s <<< "$job"
  f="$OUT/${st}_${b}_s${s}.log"
  ( timeout 1200 $G --headless --path "$TREE" --fixed-fps 60 --quit-after 15000 -- --autotest --mortal \
      --stage=$st --seed=$s ${BUILDS[$b]} > "$f" 2>&1; echo "exit $?" >> "$f" ) &
done
wait
echo "round done; $(( ${#todo[@]} > PAR ? ${#todo[@]} - PAR : 0 )) left"
