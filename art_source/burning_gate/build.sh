#!/bin/sh
# Rebuilds the Burning Gate's art from its API sources (Act VI phase 2; run from the repo root). Prompts beside this
# file (<id>.txt), raw API images in raw/ (furnace_priest.png is stored mirrored: the API drew him facing left).
# The dark figures are lifted first (brighten.py) to pass art_check.py's lightness rule; the cultist and the priest
# snap without the obsidian ramp (their black robes snap to its two darkest shades otherwise, L 0.32).
G=${TMPDIR:-/tmp}
B=art_source/burning_gate
R=obsidian,lava,demon,charm,grey,skin,brown
python3 tools/prepare_sprite.py $B/raw/lava_hound.png inferno/lava_hound --ink-l 0.15 --ramps $R,bone
python3 $B/brighten.py $B/raw/pit_cultist.png $G/pit_cultist_lit.png 1.5
python3 tools/prepare_sprite.py $G/pit_cultist_lit.png inferno/pit_cultist --ink-l 0.15 --no-levels --ramps grey,lava,demon,skin,brown,bone,gold
python3 $B/brighten.py $B/raw/gatekeeper.png $G/gatekeeper_lit.png 1.15
python3 tools/prepare_sprite.py $G/gatekeeper_lit.png inferno/gatekeeper --ink-l 0.15 --no-levels --ramps $R,bone,steel
python3 $B/brighten.py $B/raw/moloch.png $G/moloch_lit.png 1.2
python3 tools/prepare_sprite.py $G/moloch_lit.png bosses/moloch --ink-l 0.15 --no-levels --ramps $R,steel
python3 $B/brighten.py $B/raw/furnace_priest.png $G/furnace_priest_lit.png 1.5
python3 tools/prepare_sprite.py $G/furnace_priest_lit.png player/furnace_priest --ink-l 0.2 --no-levels --ramps violet,lava,grey,bone,steel
python3 tools/prepare_sprite.py $B/raw/furnace_priest_hyper.png player/furnace_priest_hyper --art-height 56 --ink-l 0.2 --no-levels --ramps violet,obsidian,gold,grey,bone,lava
python3 tools/prepare_sprite.py $B/raw/furnace_priest_untouchable.png player/furnace_priest_untouchable --art-height 56 --ink-l 0.2 --no-levels --ramps marble,soul,grey
python3 tools/prepare_sprite.py $B/raw/furnace_priest_deathlord.png player/furnace_priest_deathlord --art-height 56 --ink-l 0.2 --ramps crimson,obsidian,grey,bone,steel
python3 tools/walk_cycle.py build inferno/lava_hound inferno/pit_cultist inferno/gatekeeper bosses/moloch player/furnace_priest \
	player/furnace_priest_hyper player/furnace_priest_untouchable player/furnace_priest_deathlord
# Props and badges: split the sheets, then convert (make_art.py).
mkdir -p $G/bg_split
for s in props_long icons_violet icons_gold; do python3 $B/split_sheet.py $B/raw/$s.png $G/bg_split/$s; done
python3 $B/make_art.py $G/bg_split
# Floors (tile sources stored opaque in art_source/tiles/burning_gate_<style>.png).
python3 tools/make_tile.py build burning_gate_ash_plain burning_gate_cages burning_gate_river burning_gate_gate
