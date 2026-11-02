#!/bin/sh
# Rebuilds the Witchwood's art from its API sources (Act VII phase 2; run from the repo root). Prompts beside this file
# (<id>.txt), raw API images in raw/, references in refs/. The female figures go through pixelate_source.py first (the
# figure route), then prepare_sprite.py without cleanup or pruning; the thrall and the Bog Mother convert straight.
G=${TMPDIR:-/tmp}
W=art_source/witchwood
fig() { python3 tools/pixelate_source.py $W/raw/$1.png $2 $G/$1_px.png && \
	python3 tools/prepare_sprite.py $G/$1_px.png $3 --ink-l 0.15 --no-cleanup --no-prune --ramps $4; }
fig crimson_witch 52 court/crimson_witch blood,velvet,gold,skin,brown,moonlight
fig isolde 104 bosses/isolde blood,velvet,gold,skin,grey,moonlight
fig hedge_witch 56 player/hedge_witch violet,moss,skin,brown,blood,bone
fig hedge_witch_hyper 56 player/hedge_witch_hyper velvet,gold,moss,skin,brown
fig hedge_witch_untouchable 56 player/hedge_witch_untouchable marble,soul,grey,skin
fig hedge_witch_deathlord 56 player/hedge_witch_deathlord crimson,obsidian,steel,bone,skin,moss
python3 tools/prepare_sprite.py $W/raw/bloated_thrall.png court/bloated_thrall --ink-l 0.15 --ramps skin,blood,brown,moonlight
python3 art_source/burning_gate/brighten.py $W/raw/bog_mother.png $G/bog_mother_lit.png 1.5  # Lifted: the drowned witch read too dark.
python3 tools/prepare_sprite.py $G/bog_mother_lit.png court/bog_mother --ink-l 0.15 --no-levels --ramps drowned,moss,velvet,brown,blood,moonlight
# The untouched sources are kept as the archives (prepare_sprite archived the pixelated grids over them).
for k in court/bog_mother court/crimson_witch bosses/isolde player/hedge_witch player/hedge_witch_hyper player/hedge_witch_untouchable player/hedge_witch_deathlord; do
	cp $W/raw/$(basename $k).png art_source/$k.png; done
# Props, hex stones and badges: split the sheets, then convert (make_art.py).
mkdir -p $G/ww_split
for s in props_long icons_violet icons_gold; do python3 art_source/burning_gate/split_sheet.py $W/raw/$s.png $G/ww_split/$s; done
python3 art_source/burning_gate/split_sheet.py $W/raw/props_round.png $G/ww_split/props_round --gap 3
python3 $W/make_art.py $G/ww_split
# Floors (tile sources stored opaque in art_source/tiles/witchwood_<style>.png).
python3 tools/make_tile.py build witchwood_fen witchwood_hanging_wood witchwood_standing_stones witchwood_cauldron
# Walk / glide / idle strips (rigs in tools/walk_cycle.py under "Act VII: the Witchwood").
python3 tools/walk_cycle.py build court/crimson_witch court/bloated_thrall court/bog_mother bosses/isolde player/hedge_witch \
	player/hedge_witch_hyper player/hedge_witch_untouchable player/hedge_witch_deathlord
python3 tools/walk_cycle.py idle court/crimson_witch bosses/isolde player/hedge_witch player/hedge_witch_hyper \
	player/hedge_witch_untouchable player/hedge_witch_deathlord
