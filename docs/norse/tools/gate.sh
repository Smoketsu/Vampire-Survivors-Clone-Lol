#!/bin/bash
# Hall of the Slain (Act XI for now) same-seed gate (adapted from docs/act9/tools/gate.sh, plus the Ark).
# usage: gate.sh TREE OUTDIR
# Runs seed 7 on the Graveyard (default and army), Gullhaven, Ul-Thalos, the Iron Citadel, the Asphodel Underworld,
# the Road to the Sun, Pandemonium, Castle Sanguis, Liberty Heights and the Ark (army), ONE Godot process at a time
# (other agents share the 4 cores), and keeps only the [autotest] / [metric] lines (OUTDIR/<name>.sum). Compare two
# OUTDIRs with docs/act3/tools/same_seed_gate.py A.log B.log (it masks the wall-clock bits).
TREE=$1; OUT=$2; mkdir -p $OUT
G=/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64
run() { name=$1; shift; timeout 2400 $G --headless --path $TREE --fixed-fps 60 --quit-after 15000 -- --autotest --seed=7 "$@" > $OUT/$name.log 2>&1; echo "exit $?" >> $OUT/$name.log; }
run gy_default
run gy_army --policy=army
run harbour_army --policy=army --stage=harbour
run spire_army --policy=army --stage=spire
run citadel_army --policy=army --stage=citadel
run underworld_army --policy=army --stage=underworld
run sun_road_army --policy=army --stage=sun_road
run pandemonium_army --policy=army --stage=pandemonium
run castle_sanguis_army --policy=army --stage=castle_sanguis
run liberty_heights_army --policy=army --stage=liberty_heights
run ark_army --policy=army --stage=ark
for f in $OUT/*.log; do grep -E "^\[autotest\]|^\[metric\]" $f > ${f%.log}.sum; done
echo done
