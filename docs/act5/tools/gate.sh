#!/bin/bash
# Act V same-seed gate (adapted from docs/act4/tools/gate.sh).
# usage: gate.sh TREE OUTDIR
# Runs seed 7 on the Graveyard (default and army), Gullhaven, Ul-Thalos, the Iron Citadel and the Asphodel Underworld (army), at most two
# Godot processes at a time, and keeps only the [autotest] / [metric] lines (OUTDIR/<name>.sum). Compare two
# OUTDIRs with docs/act3/tools/same_seed_gate.py A.log B.log (it masks the wall-clock bits).
TREE=$1; OUT=$2; mkdir -p $OUT
G=/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64
run() { name=$1; shift; timeout 1200 $G --headless --path $TREE --fixed-fps 60 --quit-after 15000 -- --autotest --seed=7 "$@" > $OUT/$name.log 2>&1; echo "exit $?" >> $OUT/$name.log; }
run gy_default &
run gy_army --policy=army &
wait
run harbour_army --policy=army --stage=harbour &
run spire_army --policy=army --stage=spire &
wait
run citadel_army --policy=army --stage=citadel &
run underworld_army --policy=army --stage=underworld &
wait
for f in $OUT/*.log; do grep -E "^\[autotest\]|^\[metric\]" $f > ${f%.log}.sum; done
echo done
