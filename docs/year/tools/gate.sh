#!/bin/bash
# Turning Year same-seed gate (adapted from docs/titans/tools/gate.sh).
# usage: gate.sh TREE OUTDIR [NAME...]
# Runs seed 7 on the Graveyard (default and army), Gullhaven, Ul-Thalos, the Iron Citadel, the Asphodel Underworld,
# the Road to the Sun, Pandemonium, Castle Sanguis, Liberty Heights, the Ark, the Maelstrom, Vigrid, the Necropolis of
# Sand, the Hall of Two Truths, the Silver Stair, the Fern Basin, the Great Plain, the Last Day, the Greenwood and the Fae Court (army): stages 1-44 (the Silver Stair stands for the Host stages). ONE Godot process per call (docs/last_acts/PLAN.md: several
# agents share the 4 cores); give run names to run only those (e.g. to split the gate over several calls). Keeps only
# the [autotest] / [metric] lines (OUTDIR/<name>.sum). Compare two OUTDIRs with docs/act3/tools/same_seed_gate.py
# A.log B.log (it masks the wall-clock bits).
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
	[maelstrom_army]="--policy=army --stage=maelstrom"
	[vigrid_army]="--policy=army --stage=vigrid"
	[necropolis_army]="--policy=army --stage=necropolis"
	[two_truths_army]="--policy=army --stage=two_truths"
	[silver_stair_army]="--policy=army --stage=silver_stair"
	[fern_basin_army]="--policy=army --stage=fern_basin"
	[great_plain_army]="--policy=army --stage=great_plain"
	[last_day_army]="--policy=army --stage=last_day"
	[greenwood_army]="--policy=army --stage=greenwood"
	[fae_court_army]="--policy=army --stage=fae_court"
)
ALL="gy_default gy_army harbour_army spire_army citadel_army underworld_army sun_road_army pandemonium_army castle_sanguis_army liberty_heights_army ark_army maelstrom_army vigrid_army necropolis_army two_truths_army silver_stair_army fern_basin_army great_plain_army last_day_army greenwood_army fae_court_army"
NAMES=${*:-$ALL}
for name in $NAMES; do
	timeout 1200 $G --headless --path $TREE --fixed-fps 60 --quit-after 15000 -- --autotest --seed=7 ${ARGS[$name]} > $OUT/$name.log 2>&1
	echo "exit $?" >> $OUT/$name.log
	grep -E "^\[autotest\]|^\[metric\]" $OUT/$name.log > $OUT/$name.sum
done
echo done
