#!/bin/sh
# Rebuilds the Act V shared kinds from their sources (run from the repo root): convert, then the scripted touch-ups
# (touchups.py is NOT idempotent: always run it right after a fresh conversion), then the walk strips.
R=lacquer,indigo,sakura,grey,gold,skin,brown
for n in ashigaru samurai teppo_gunner oni; do python3 tools/prepare_sprite.py art_source/shogunate/$n.png shogunate/$n --ink-l 0.22 --ramps $R; done
python3 tools/prepare_sprite.py art_source/shogunate/ninja.png shogunate/ninja --ink-l 0.15 --ramps indigo,lacquer,grey,gold
python3 tools/prepare_sprite.py art_source/shogunate/onryo.png shogunate/onryo --art-height 34 --ink-l 0.3 --ramps marble,indigo
python3 tools/prepare_sprite.py art_source/shogunate/stone_lantern.png obstacles/stone_lantern --ink-l 0.2 --ramps grey,gold
python3 art_source/shogunate/touchups.py
