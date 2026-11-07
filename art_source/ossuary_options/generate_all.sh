#!/bin/bash
# Generates the raw symbol image of every Ossuary step 3 badge that has none yet
# (art_source/ossuary_options/raw/<icon>.png), one gen_image.py call each, with the
# Shadow Bolt anchor and the icon's tree emblem as references. Run from the repo root;
# GEN_LEDGER names the cost ledger (the shared one in the main checkout). raw/ is scratch:
# tools/prepare_sprite.py archives each source in art_source/icons/<icon>.png when it
# converts it to symbols/<icon>.png (26 art px: --art-height 26 --no-center --no-prune
# --no-levels; 25 for bone_reserve, 23 for tree_dominion so they fit the box; --no-cleanup
# for elite_bounty, dark_tithe, commanders_presence and chosen_vanguard's skull faces), and
# make_badges.py composites the badges.
set -u
declare -A TREE=(
  [bone_reserve]=tree_necromancy [commanders_presence]=tree_necromancy
  [echo_weaving]=tree_shadowcraft [dark_tithe]=tree_shadowcraft
  [last_rites]=tree_survival [grave_ward]=tree_survival
  [gilded_chests]=tree_fortune [elite_bounty]=tree_fortune
  [head_start]=tree_survival [chosen_vanguard]=tree_necromancy [patient_grave]=tree_shadowcraft
  [tree_dominion]=tree_necromancy
)
D=art_source/ossuary_options
for icon in "${!TREE[@]}"; do
  if [ -f "$D/raw/$icon.png" ]; then
    continue
  fi
  python3 tools/gen_image.py "$D/prompts/$icon.txt" "$D/raw/$icon.png" \
    --ref assets/sprites/icons/shadow_bolt.png --ref "assets/sprites/icons/${TREE[$icon]}.png" --key "icons/$icon"
done
