## CutterEnemyData — the kinds of the Smuggler's Cutter only (Act X, the Black
## Tide; GDD §15.0 "Act X foundation: the Black Tide (phase 1)" and "The
## Smuggler's Cutter (Act X phase 2)"; owner-approved proposal
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 1, "Stage A: The Smuggler's
## Cutter"). Rows as CorsairEnemyData's (every key documented there), kits in
## scripts/enemies/corsair/. EnemyDirector.corsair_def() looks them up after
## CorsairEnemyData.
##   powder_barrel — the stage mechanic (owner-approved proposal: "Barrels stack
##                   against the rails. Any hit breaks one: a blast that hurts
##                   both sides and knocks everyone 120 px (overboard if near
##                   the rail)"): a 1 HP STRUCTURE (PowderBarrelKit) that
##                   CutterDirector sets along the rails at the start of every
##                   zone; any hit that reaches it sets it off through THE
##                   powder blast (CorsairRules.powder_blast(), row "keg").
##   bosun_gorran  — the stage MINIBOSS (male; owner-approved proposal: "Bosun
##                   Gorran and the Ram Longboat ... A heavy longboat rams the
##                   hull (a stagger that knocks every summon back) before it
##                   boards"; BosunGorranKit; CutterDirector's "gorran" event
##                   brings him in his ram longboat).
##   ram_longboat  — Gorran's heavy battering longboat (a boat STRUCTURE in the
##                   water: row "boat"; CutterDirector rams it into the hull
##                   and pours its crew; sunk, the crew still aboard drowns).
##   crow_sloop    — Captain Crow's sloop alongside during his Broadside (a
##                   boat STRUCTURE in the water; BossCrow places it; sink it
##                   and he swings aboard at once). Drawn with the raider
##                   ship's art (CorsairGlyphs, the Cutter's block).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal. Tuned for the act's FINAL slot II.
class_name CutterEnemyData
extends RefCounted

## Kind id of the powder barrel (CutterDirector, PowderBarrelKit).
const BARREL: String = "powder_barrel"
## Kind id of the miniboss (CutterDirector's "gorran" event).
const GORRAN: String = "bosun_gorran"
## Kind id of Gorran's ram longboat (CutterDirector).
const RAM_LONGBOAT: String = "ram_longboat"
## Kind id of Captain Crow's sloop (BossCrow's Broadside).
const CROW_SLOOP: String = "crow_sloop"
## Sprite key a powder barrel is drawn with (the deck furniture's two lashed
## barrels; SpriteData.HEIGHTS has its height).
const BARREL_SPRITE: String = "obstacles/deck_barrels_s"
## Sprite key Crow's sloop is drawn with (the raider ship's art: the sloop has
## none of its own).
const SLOOP_SPRITE: String = "corsair/raider_ship"
## Damage source tag of a hull ram's stagger (CutterDirector.ram_stagger():
## stats summon_dmg_from_hull_ram).
const RAM_SOURCE: String = "hull_ram"
## Max HP a powder barrel is set to at activation, whatever the HP scalings
## (owner-approved proposal: "any hit breaks one").
const BARREL_HP: float = 0.01  # Owner-approved proposal: any hit breaks one

## The stage's own kinds, keyed by kind id.
const ENEMIES := {
	# THE POWDER BARREL (the stage mechanic): a lashed pair of powder barrels
	# against the rail. A 1 HP structure (set to BARREL_HP at activation): any
	# hit sets it off. It never moves or attacks, gives no XP and is never a
	# kill for the achievements' counts (the blast's kills are). Drawn with the
	# deck furniture's barrel art (obstacles/deck_barrels_s).
	"powder_barrel": {
		"display_name": "Powder Barrel",
		"max_hp": 1.0,  # Owner-approved proposal: any hit breaks one (set to BARREL_HP)
		"move_speed": 0.0,
		"damage": 0.0,  # It never attacks.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 10.0,  # TUNING (not in GDD) px (the 30 x 21 barrel art)
		"armor": 0.0,
		"xp": 0,  # No XP: the blast is the reward.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.0,  # TUNING (not in GDD) 0..1: the army aims at the crew first (a stray hit still sets it off)
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": CorsairEnemyData.FACTION,
		"kit": "powder_barrel",
		"barrel": true,  # The Cutter's powder barrel (PowderBarrelKit)
		# Owner-approved proposal: "a blast that hurts both sides and knocks everyone 120 px"; TUNING (not in GDD) the rest.
		"keg": {"radius": 78.0, "push": 120.0, "dmg_summon": 8.0, "dmg_player": 5.0, "dmg_enemy": 36.0},  # first pass dmg_summon 9, dmg_player 7
	},  # The Powder Barrel.
	# BOSUN GORRAN, the stage MINIBOSS (male; owner-approved proposal): an
	# enormous scarred bosun bellowing orders, a ship's iron chain-hook in his
	# fist. He steps off his ram longboat after it rams the hull and fights with
	# the shared melee AI (the chain-hook in reach). His specials:
	#   * THE CHAIN SWEEP: every sweep_every s he whirls the chain (sweep_windup
	#     s, a lantern-amber telegraph ring of sweep_radius px), then every
	#     grounded summon in reach takes sweep_damage and is knocked
	#     sweep_push px away (TerrainSlow.push_summon() x Sea Legs, the act's
	#     one shove path) and the necromancer takes sweep_damage_player.
	#   * THE BELLOW: every bellow_every s his crew within bellow_radius px move
	#     bellow_speed x faster for bellow_time s (Enemy.apply_buff(), the one
	#     aura buff path), as a Boatswain's.
	# He registers on the HUD's miniboss bar (EnemyDirector.set_miniboss());
	# killed, he drops an XP burst (reward_xp in reward_crystals) and the
	# miniboss chest. He never drowns (a miniboss: DeckBounds).
	"bosun_gorran": {
		"display_name": "Bosun Gorran",
		"max_hp": 1250.0,  # TUNING (not in GDD) a slot II miniboss (the Brood Matriarch 1300 at x2.15; this x1.3)
		"move_speed": 46.0,  # TUNING (not in GDD) px/s
		"damage": 9.0,  # TUNING (not in GDD) the chain-hook in reach, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 18.0,  # TUNING (not in GDD) px (the 62 x 64 art)
		"armor": 0.2,  # TUNING (not in GDD)
		"flat_armor": 2.0,  # TUNING (not in GDD) scarred hide (the Bruiser's 3 is the heavy's)
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the miniboss first
		"mass": 9.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # Enemy.is_miniboss: the HUD bar, the chest; never drowns.
		"faction": CorsairEnemyData.FACTION,
		"kit": "bosun_gorran",
		"crew": true,  # A boarder (he comes aboard off his own boat).
		"sweep_every": 7.0,  # TUNING (not in GDD) s between two chain sweeps
		"sweep_windup": 0.8,  # TUNING (not in GDD) s the chain whirls (the telegraph)
		"sweep_radius": 74.0,  # TUNING (not in GDD) px
		"sweep_damage": 10.0,  # TUNING (not in GDD) per summon hit, before the time scaling
		"sweep_damage_player": 8.0,  # TUNING (not in GDD) before the time scaling
		"sweep_push": 70.0,  # TUNING (not in GDD) px a summon is knocked (x Sea Legs)
		"bellow_every": 10.0,  # TUNING (not in GDD) s
		"bellow_radius": 220.0,  # TUNING (not in GDD) px
		"bellow_speed": 1.25,  # TUNING (not in GDD) x crew move speed
		"bellow_time": 4.0,  # TUNING (not in GDD) s
		"reward_xp": 200,  # TUNING (not in GDD) as the Brood Matriarch's 220, an early act
		"reward_crystals": 10,  # TUNING (not in GDD)
	},  # Bosun Gorran.
	# GORRAN'S RAM LONGBOAT (owner-approved proposal: "A heavy longboat rams the
	# hull (a stagger that knocks every summon back) before it boards"): a boat
	# STRUCTURE in the water that CutterDirector brings to a boarding point,
	# rams into the hull and lays alongside while its crew pours off (bypassing
	# BoardingParty's queue: GDD row). Sunk, the crew still aboard drowns.
	"ram_longboat": {
		"display_name": "Ram Longboat",
		"max_hp": 600.0,  # TUNING (not in GDD) twice a longboat's 300 (owner-approved: "a heavy longboat")
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 30.0,  # TUNING (not in GDD) px (the 96 x 48 art)
		"armor": 0.25,  # TUNING (not in GDD) the iron-capped ram
		"xp": 8,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.35,  # TUNING (not in GDD) 0..1
		"mass": 60.0,
		"faction": CorsairEnemyData.FACTION,
		"kit": "corsair_boat",
		"is_structure": true,
		"water": true,  # It lies in the water, its hull over the rail line.
		"boat": true,  # A boat (the Barnacle Bones hook, the Codex's Boats).
	},  # The Ram Longboat.
	# CAPTAIN CROW'S SLOOP (owner-approved proposal: "Broadside: his sloop pulls
	# alongside"): a boat STRUCTURE in the water that BossCrow brings alongside
	# for his Broadside; Crow commands from its deck (out of reach). Sink it and
	# he swings aboard at once (the Duel). Its HP x the boss's HP multipliers.
	"crow_sloop": {
		"display_name": "The Gull King's Sloop",
		"max_hp": 2600.0,  # TUNING (not in GDD) x the stage's HP scaling at his arrival
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 40.0,  # TUNING (not in GDD) px (the raider ship's 126 x 64 art)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 20,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD) 0..1
		"mass": 60.0,
		"faction": CorsairEnemyData.FACTION,
		"kit": "corsair_boat",
		"is_structure": true,
		"water": true,  # It lies in the water, its hull over the rail line.
		"boat": true,  # A boat (the Barnacle Bones hook).
	},  # Captain Crow's sloop.
}
