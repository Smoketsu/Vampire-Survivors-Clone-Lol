#!/bin/sh
# Rebuilds the Burning Province's art from its API sources (Act V phase 2; run from the repo root):
# the units, Kage and the Grave Kunoichi with her skins, then the walk / idle strips, the obstacles
# and icons (province_build.py) and the four zone floors (make_tile.py recipes province_*).
# shuten_doji.png is stored mirrored (the API drew him facing left).
python3 tools/prepare_sprite.py art_source/shogunate/kunoichi.png shogunate/kunoichi --ink-l 0.15 --ramps indigo,lacquer,sakura,grey,gold,skin
python3 tools/prepare_sprite.py art_source/shogunate/kappa.png shogunate/kappa --ink-l 0.22 --ramps moss,brown,gold,indigo,grey
python3 tools/prepare_sprite.py art_source/shogunate/shuten_doji.png shogunate/shuten_doji --ink-l 0.22 --ramps lacquer,indigo,sakura,grey,gold,skin,brown,marble
python3 tools/prepare_sprite.py art_source/bosses/kage.png bosses/kage --ink-l 0.12 --no-levels --ramps indigo,lacquer,grey,gold,skin,marble
python3 tools/prepare_sprite.py art_source/player/grave_kunoichi.png player/grave_kunoichi --ink-l 0.20 --ramps violet,bone,soul,grey
python3 tools/prepare_sprite.py art_source/player/grave_kunoichi_hyper.png player/grave_kunoichi_hyper --ink-l 0.20 --no-levels --ramps violet,bone,gold,grey
python3 tools/prepare_sprite.py art_source/player/grave_kunoichi_untouchable.png player/grave_kunoichi_untouchable --ink-l 0.20 --ramps bone,soul,grey,violet
python3 tools/prepare_sprite.py art_source/player/grave_kunoichi_deathlord.png player/grave_kunoichi_deathlord --ink-l 0.20 --ramps violet,crimson,steel,grey,bone
K="shogunate/kunoichi shogunate/kappa shogunate/shuten_doji bosses/kage player/grave_kunoichi player/grave_kunoichi_hyper player/grave_kunoichi_untouchable player/grave_kunoichi_deathlord"
# Fishnets (Act V art review round 1): the converter cannot hold a 1-px net, so it is painted on after conversion.
# Kunoichi / Kage: every 8c6040 skin pixel below a row; the Grave Kunoichi and her skins: the net area of the
# API still (art_source/shogunate/fishnet/*.py, run from the repo root with PYTHONPATH=art_source/shogunate/fishnet).
export PYTHONPATH=art_source/shogunate/fishnet
python3 art_source/shogunate/fishnet/fishc.py shogunate/kunoichi 8c6040 26 e0a882 1c110b
python3 art_source/shogunate/fishnet/fishc.py bosses/kage 8c6040 30 e0a882 1c110b
for v in "" _hyper _untouchable _deathlord; do python3 art_source/shogunate/fishnet/fish.py art_source/player/grave_kunoichi$v.png player/grave_kunoichi$v 0.5 b4aa8a 160a21; done
python3 tools/walk_cycle.py build $K
python3 tools/walk_cycle.py idle shogunate/kunoichi bosses/kage player/grave_kunoichi player/grave_kunoichi_hyper player/grave_kunoichi_untouchable player/grave_kunoichi_deathlord
python3 art_source/shogunate/province_build.py
python3 tools/make_tile.py build province_paddies province_bamboo province_village province_shrine
