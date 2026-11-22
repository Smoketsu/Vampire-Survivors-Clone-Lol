#!/bin/bash
# Necropolis Dynasty same-seed gate (adapted from docs/act9/tools/gate.sh, plus the Ark).
# usage: gate.sh TREE OUTDIR [NAME...]
# Runs seed 7 on the Graveyard (default and army), Gullhaven, Ul-Thalos, the Iron Citadel, the Asphodel Underworld,
# the Road to the Sun, Pandemonium, Castle Sanguis, Liberty Heights and the Ark (army): stages 1-27. ONE Godot process
# at a time (docs/last_acts/PLAN.md: several agents share the 4 cores). Give run names to run only those (e.g. to split
# the gate over several calls). Keeps only the [autotest] / [metric] lines (OUTDIR/<name>.sum). Compare two OUTDIRs
# with docs/act3/tools/same_seed_gate.py A.log B.log (it masks the wall-clock bits).
TREE=$1; OUT=$2; shift 2; mkdir -p $OUT
G=/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64
declare -A ARGS=(
	[gy_default]=""
	[gy_army]="--policy=army"
	[harbour_army]="--policy=army --stage=harbour"
	[spire_army]="--policy=army --stage=spire"
	[citadel_army]="--policy=army --stage=citadel"
	[underworld_army]="--policy=army --stage=underworld"
	[sun_road_army]="--policy=army --stage=sun_road"
	[pandemonium_army]="--policy=army --stage=pandemonium"
	[castle_sanguis_army]="--policy=army --stage=castle_sanguis"
	[liberty_heights_army]="--policy=army --stage=liberty_heights"
	[ark_army]="--policy=army --stage=ark"
)
ALL="gy_default gy_army harbour_army spire_army citadel_army underworld_army sun_road_army pandemonium_army castle_sanguis_army liberty_heights_army ark_army"
NAMES=${*:-$ALL}
for name in $NAMES; do
	timeout 1200 $G --headless --path $TREE --fixed-fps 60 --quit-after 15000 -- --autotest --seed=7 ${ARGS[$name]} > $OUT/$name.log 2>&1
	echo "exit $?" >> $OUT/$name.log
	grep -E "^\[autotest\]|^\[metric\]" $OUT/$name.log > $OUT/$name.sum
done
echo done
