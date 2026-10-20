#!/bin/bash
# usage: gate.sh TREE OUTDIR
TREE=$1; OUT=$2; mkdir -p $OUT
G=/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64
run() { name=$1; shift; timeout 900 $G --headless --path $TREE --fixed-fps 60 --quit-after 15000 -- --autotest --seed=7 "$@" > $OUT/$name.log 2>&1; echo "exit $?" >> $OUT/$name.log; }
run gy_default &
run gy_army --policy=army &
run harbour_army --policy=army --stage=harbour &
wait
run spire_army --policy=army --stage=spire &
wait
for f in $OUT/*.log; do grep -E "^\[autotest\]|^\[metric\]" $f > ${f%.log}.sum; done
echo done
