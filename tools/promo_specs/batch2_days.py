# batch2_days.py: the 14 clips of batch 2 (exec'd by make_specs2.py, which provides add()). shot = (stage, seed, start s, extra autotest args, what it shows).
add(1, "vampires, bats, werewolves, and a blood moon", 3, [
    ("castle_sanguis", 4, 106, ["--spawn=vampire_bat@100x40"], "vampire bats"),
    ("ravensmoor", 5, 124, ["--spawn=vampire_noble@100x10"], "vampire nobles"),
    ("ravensmoor", 4, 114, ["--spawn=werewolf@100x10"], "werewolf hunters marching in a column"),
    ("ravensmoor", 4, 246, ["--spawn=werewolf@236x12"], "werewolves after the blood moon rises")])
add(2, "36 playable characters. here are 4 of them", 3, [
    ("province", 3, 30, ["--character=grave_kunoichi"], "Grave Kunoichi"),
    ("kurogane", 3, 30, ["--character=ronin_revenant"], "Ronin Revenant"),
    ("ravensmoor", 3, 30, ["--character=moon_huntress"], "Moon Huntress"),
    ("ark", 3, 30, ["--character=starborn"], "Starborn")])
add(6, "the gatekeeper comes wrapped in chains", 3, [
    ("burning_gate", 4, 92, ["--spawn=gatekeeper@60"], "Gatekeeper chains"),
    ("burning_gate", 5, 92, ["--spawn=gatekeeper@60"], "Gatekeeper chains"),
    ("burning_gate", 6, 92, ["--spawn=gatekeeper@60"], "Gatekeeper chains"),
    ("burning_gate", 7, 92, ["--spawn=gatekeeper@60"], "Gatekeeper chains")])
add(7, "the iron citadel has a laser grid", 3, [
    ("citadel", 4, 330, [], "diagonal lasers"),
    ("citadel", 5, 330, [], "diagonal lasers"),
    ("citadel", 7, 330, [], "diagonal lasers"),
    ("citadel", 8, 330, [], "diagonal lasers")])
add(8, "superheroes show up in the last act", 3, [
    ("liberty_heights", 4, 68, ["--spawn=blitz@55x2,aurora@55x2,nightjar@55x2,atlas@55x2"], "Blitz, Aurora, Nightjar, Atlas with name tags"),
    ("liberty_heights", 5, 68, ["--spawn=blitz@55x2,aurora@55x2,nightjar@55x2,atlas@55x2"], "the same four heroes, other seed"),
    ("liberty_heights", 6, 68, ["--spawn=blitz@55x2,aurora@55x2,nightjar@55x2,atlas@55x2"], "the same four heroes, other seed"),
    ("liberty_heights", 7, 68, ["--spawn=blitz@55x2,aurora@55x2,nightjar@55x2,atlas@55x2"], "the same four heroes, other seed")])
add(3, "alien beams cut through my whole army", 3, [
    ("ark", 4, 58, ["--spells=bone_wall", "--spawn=lumen_sentinel@40x8,prism@40x4,grey_drone@40x10"], "beams and bone walls"),
    ("ark", 5, 62, ["--spells=bone_wall", "--spawn=lumen_sentinel@40x8,prism@40x4,grey_drone@40x10"], "beams and bone walls"),
    ("ark", 6, 62, ["--spells=bone_wall", "--spawn=lumen_sentinel@40x8,prism@40x4,grey_drone@40x10"], "beams and bone walls"),
    ("ark", 7, 62, ["--spells=bone_wall", "--spawn=lumen_sentinel@40x8,prism@40x4,grey_drone@40x10"], "beams and bone walls")])
add(4, "hellhounds leave a trail of fire", 3, [
    ("crimson_march", 5, 600, ["--policy=summon", "--classes=bone_hound", "--passives=blood_scent"], "hellhounds"),
    ("crimson_march", 6, 600, ["--policy=summon", "--classes=bone_hound", "--passives=blood_scent"], "hellhounds"),
    ("sanctum", 5, 640, ["--policy=summon", "--classes=bone_hound", "--passives=blood_scent"], "hellhounds"),
    ("graveyard", 6, 640, ["--policy=summon", "--classes=bone_hound", "--passives=blood_scent"], "hellhounds")])
add(5, "my army has corpse catapults", 3, [
    ("harbour", 9, 520, ["--classes=corpse_catapult"], "catapults"),
    ("graveyard", 9, 400, ["--classes=corpse_catapult"], "catapults"),
    ("crimson_march", 9, 400, ["--classes=corpse_catapult"], "catapults"),
    ("sanctum", 9, 400, ["--classes=corpse_catapult"], "catapults")])
add(9, "act 4 has amazons and cyclopes", 3, [
    ("olympus", 5, 72, ["--spawn=amazon@50x5"], "amazons"),
    ("ilion", 4, 80, ["--spawn=cyclops@50x3"], "cyclopes"),
    ("olympus", 5, 77, ["--spawn=amazon@50x5"], "amazons"),
    ("ilion", 5, 80, ["--spawn=cyclops@50x3"], "cyclopes")])
add(10, "banshees float with my army and wail", 3, [
    ("graveyard", 9, 330, ["--classes=banshee"], "banshees"),
    ("crimson_march", 9, 330, ["--classes=banshee"], "banshees"),
    ("sanctum", 9, 450, ["--classes=banshee"], "banshees"),
    ("ravensmoor", 9, 330, ["--classes=banshee"], "banshees")])
add(11, "kitsune only come out at night", 3, [
    ("sun_road", 4, 806, ["--spawn=kitsune@790x8"], "kitsune at night"),
    ("sun_road", 5, 806, ["--spawn=kitsune@790x8,fox_fire@790x8"], "kitsune and fox fire at night"),
    ("sun_road", 6, 806, ["--spawn=kitsune@790x8"], "kitsune at night"),
    ("sun_road", 7, 806, ["--spawn=kitsune@790x8,fox_fire@790x8"], "kitsune and fox fire at night")])
add(12, "the brood matriarch and her eggs", 3, [
    ("crash_site", 4, 106, ["--spawn=brood_matriarch@50,brood_egg@50x6"], "matriarch and eggs"),
    ("crash_site", 5, 106, ["--spawn=brood_matriarch@50,brood_egg@50x6"], "matriarch and eggs"),
    ("crash_site", 6, 106, ["--spawn=brood_matriarch@50,brood_egg@50x6"], "matriarch and eggs"),
    ("crash_site", 7, 106, ["--spawn=brood_matriarch@50,brood_egg@50x6"], "matriarch and eggs")])
add(13, "online co-op: two necromancers, one fight", 3, [
    ("graveyard", 4, 45, ["--coop-bot", "--character2=bone_oracle"], "P2 beside P1 on the Graveyard"),
    ("crimson_march", 4, 45, ["--coop-bot", "--character=doomsayer", "--character2=wither_witch"], "two necromancers, Crimson March"),
    ("ravensmoor", 4, 45, ["--coop-bot", "--character=plague_scholar", "--character2=soulbinder"], "two necromancers, Ravensmoor"),
    ("citadel", 4, 45, ["--coop-bot", "--character=barrow_warden", "--character2=grave_kunoichi"], "two necromancers, Iron Citadel")])
add(14, "every stage ends with a boss. this is moloch", 2, [
    ("burning_gate", 5, 1060, [], "Moloch"),
    ("burning_gate", 6, 1060, [], "Moloch"),
    ("burning_gate", 6, 1085, [], "Moloch with its telegraphed beams"),
    ("burning_gate", 5, 1085, [], "dropped from the cut: Moloch off screen here")])
