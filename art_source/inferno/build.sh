#!/bin/sh
# Rebuilds the Act VI shared kinds from their sources (run from the repo root): convert, then the scripted touch-ups
# (touchups.py is NOT idempotent: always run it right after a fresh conversion), then the walk / idle strips
# (python3 tools/walk_cycle.py build ... / idle ...). The sources are the AI images beside this file (prompts in <id>.txt).
R=obsidian,lava,demon,charm,grey,skin,brown
G=${TMPDIR:-/tmp}
python3 tools/prepare_sprite.py art_source/inferno/damned.png inferno/damned --ink-l 0.15 --ramps $R
python3 tools/prepare_sprite.py art_source/inferno/imp.png inferno/imp --art-height 30 --ink-l 0.15 --ramps $R
python3 tools/prepare_sprite.py art_source/inferno/hell_knight.png inferno/hell_knight --ink-l 0.15 --no-levels --ramps $R
python3 tools/prepare_sprite.py art_source/inferno/demon_brute.png inferno/demon_brute --ink-l 0.15 --no-levels --ramps $R
# The succubus (a detailed figure) goes onto the art grid first (ART_BIBLE "Converting small figures").
python3 tools/pixelate_source.py art_source/inferno/succubus.png 56 $G/succubus_grid.png
python3 tools/prepare_sprite.py $G/succubus_grid.png inferno/succubus --art-height 56 --ink-l 0.15 --no-cleanup --no-prune --ramps $R
python3 art_source/inferno/touchups.py
python3 tools/prepare_sprite.py art_source/inferno/demon_portal.png structures/demon_portal --ink-l 0.15 --no-levels --ramps obsidian,lava,demon,charm
