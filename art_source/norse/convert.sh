#!/bin/bash
# convert.sh <key> [pix]: source art_source/norse/<key>.png -> assets/sprites/norse/<key>.png (pix = pixelate first)
# The three playable characters (rune_seer, shield_maiden_hero, berserker_hero) live in assets/sprites/player/ since the
# wave 1 integration: convert them to player/<key> (their HEIGHTS, KEY_RAMPS and rigs are keyed player/<key>).
cd /home/user/wt/norse-art
k=$1; S=/tmp/claude-0/-home-user/9462c562-c5ac-539a-9c62-d10b49b002f0/scratchpad/n
H=$(grep "\"norse/$k\"" scripts/data/sprite_data.gd | sed 's/.*: \([0-9]*\)\.0.*/\1/')
src=art_source/norse/$k.png; cp $src $S/src_$k.png
if [ "$2" = pix ]; then python3 tools/pixelate_source.py $src $H $S/px/$k.png >/dev/null; python3 tools/prepare_sprite.py $S/px/$k.png norse/$k --ink-l 0.15 --no-prune --no-cleanup --no-levels > $S/px/$k.log 2>&1; cp $S/src_$k.png $src
else python3 tools/prepare_sprite.py $src norse/$k --ink-l 0.15 --no-prune > $S/px/$k.log 2>&1; fi
tail -2 $S/px/$k.log | head -1
