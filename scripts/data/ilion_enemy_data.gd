## IlionEnemyData — immutable design data for the Olympian Republic kinds that
## join on the Shores of Ilion (Stage 10) (Act IV; GDD §15.0 "Act IV foundation
## (phase 1)" and "The Shores of Ilion (Act IV phase 2)"; owner-approved
## proposal docs/act4/PROPOSAL.md "Roster" and "Stage 10: The Shores of Ilion"):
##   legionary    — Legionary (soldier, male): scutum and gladius. PHALANX and
##                  BRONZE like the Hoplite, plus the TESTUDO (row "testudo"):
##                  while locked, its shields also roof and wall the line, so
##                  a SHOT from anywhere but behind and an ARCING hit from
##                  above are cut like a front shot (Phalanx.directed_hit_mult(),
##                  the one front path). Melee, stomps and shots from behind
##                  beat it (LegionaryKit draws the raised shields).
##   wolf_of_rome — Wolf of Rome (fodder pack): a bronze statue wolf come
##                  alive. Every wolf that is not itself spawned as a packmate
##                  brings pack_size - 1 more ("packs of 5", WolfKit); fast
##                  lunges at what it hunts. FODDER (the waves drown it) and
##                  BRONZE.
##   cyclops      — Cyclops (heavy, male): a one-eyed giant who hurls boulders
##                  onto telegraphed landing circles (CyclopsKit) and wears
##                  FLAT ARMOUR (Enemy.flat_armor: Wither and Siegecraft
##                  answer it). The miniboss's lesser kin.
## and the stage's objects and specials:
##   polyphemus   — Polyphemus the Cyclops: the stage miniboss (9:00 left),
##                  the chieftain of the cyclopes (PolyphemusKit): a volley of
##                  boulders on landing circles, a ground stomp, flat armour,
##                  and a rage below half HP (faster throws, more boulders).
##   siege_tower  — Siege Tower (structure): a wooden tower on wheels rolling
##                  past the necromancer toward the walls of Troy (IlionDirector,
##                  behavior "cart"). Destroyed, it spills its garrison and
##                  pays a Soul Ash bounty; if it reaches the walls its garrison
##                  marches out stronger and no bounty is paid.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.pantheon_def() looks these rows up after
## PantheonEnemyData. Rows have every key of a PantheonEnemyData.ENEMIES row
## (same meaning; "kit" ids load scripts/enemies/pantheon/<kit>_kit.gd, unique
## across the Eye, Empire and Pantheon folders; "bronze", "phalanx", "hero",
## "fodder" switch the shared rules on for the kind) plus their kit's numbers
## (documented on each row). The GDD gives no numbers: everything is TUNING
## (not in GDD) unless marked as the owner-approved proposal.
class_name IlionEnemyData
extends RefCounted

## Kind id of the Legionary.
const LEGIONARY: String = "legionary"
## Kind id of the Wolf of Rome.
const WOLF: String = "wolf_of_rome"
## Kind id of the Cyclops.
const CYCLOPS: String = "cyclops"
## Kind id of Polyphemus (the stage miniboss).
const POLYPHEMUS: String = "polyphemus"
## Kind id of the Siege Tower (IlionDirector rolls them).
const SIEGE_TOWER: String = "siege_tower"
## Damage source tag of a cyclops boulder landing (CyclopsKit).
const BOULDER_SOURCE: String = "cyclops_boulder"
## Damage source tag of Polyphemus's boulders (PolyphemusKit).
const POLY_BOULDER_SOURCE: String = "polyphemus_boulder"
## Damage source tag of Polyphemus's stomp (PolyphemusKit).
const POLY_STOMP_SOURCE: String = "polyphemus_stomp"
## Damage source tag of a Wolf of Rome's lunge bite (WolfKit).
const WOLF_LUNGE_SOURCE: String = "wolf_lunge"

## Kind id -> design row.
const ENEMIES := {
	# Soldier: a Roman legionary of the gods' army, a tall curved Aegean-blue
	# scutum covering him from chin to knee, a short gladius. Locks shields like
	# the Hoplite, and under the testudo his line is roofed against volleys.
	"legionary": {
		"display_name": "Legionary",
		"max_hp": 38.0,  # TUNING (not in GDD) a soldier, a little tougher than the Hoplite (34): the scutum
		"move_speed": 40.0,  # TUNING (not in GDD) px/s; a disciplined march, slower than the Hoplite (42)
		"damage": 5.0,  # TUNING (not in GDD) a gladius stab, before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s; the short sword is quick
		"attack_range": 6.0,  # TUNING (not in GDD) px; shorter reach than the spear
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD) bronze bands
		"xp": 2,  # TUNING (not in GDD) a soldier's XP
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.4,  # TUNING (not in GDD) 0..1
		"mass": 1.6,  # TUNING (not in GDD) braced behind the scutum
		"faction": PantheonEnemyData.FACTION,
		"kit": "legionary",
		"phalanx": true,  # Locks shields (Phalanx).
		"bronze": true,  # Draws Zeus's lightning.
		# The testudo (Phalanx.directed_hit_mult(), only while locked): a shot
		# arriving from anywhere outside the rear cone of testudo_rear_half_angle
		# rad each side of straight behind deals testudo_shot_mult (the front's
		# share) and breaks nothing; an arcing hit from above (a catapult
		# boulder: CombatResolver.FROM_ABOVE) deals testudo_above_mult.
		"testudo": true,  # Owner-approved proposal: "locks the testudo against arrows and volleys from above"
		"testudo_rear_half_angle": 0.9,  # TUNING (not in GDD) rad (~52 degrees each side of straight behind)
		"testudo_shot_mult": 0.1,  # TUNING (not in GDD) as the Phalanx's front_shot_mult
		"testudo_above_mult": 0.3,  # TUNING (not in GDD) a boulder still bruises the roof of shields
	},
	# Fodder pack: a bronze statue wolf come alive, glowing pale Aegean eyes,
	# bared teeth. Packs of five lope in fast and lunge.
	"wolf_of_rome": {
		"display_name": "Wolf of Rome",
		"max_hp": 12.0,  # TUNING (not in GDD) fodder, bronze-tough (Shade 9)
		"move_speed": 96.0,  # TUNING (not in GDD) px/s; fast (Shade 86)
		"damage": 2.5,  # TUNING (not in GDD) a bite, before the time scaling
		"attack_interval": 0.9,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px, melee
		"radius": 8.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD) bronze
		"xp": 1,  # TUNING (not in GDD) fodder
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.25,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.7,  # TUNING (not in GDD) light: the ring's blockers hold it
		"faction": PantheonEnemyData.FACTION,
		"kit": "wolf",
		"fodder": true,  # Poseidon's waves drown it.
		"bronze": true,  # Draws Zeus's lightning.
		# The pack (WolfKit): a wolf spawned on its own (the trickle, a wave)
		# leads a pack and brings pack_size - 1 packmates around it (never past
		# the hard cap); packmates bring none.
		"pack_size": 5,  # Owner-approved proposal: "packs of 5"
		"pack_spread": 26.0,  # TUNING (not in GDD) px around the leader the packmates appear
		# Lunge (owner-approved "fast lunges"): within lunge_range px of what it
		# hunts it crouches lunge_windup s, then leaps lunge_time s at
		# lunge_speed px/s; the first body it reaches takes lunge_damage (x the
		# time scaling). Every lunge_cooldown s.
		"lunge_range": 90.0,  # TUNING (not in GDD) px
		"lunge_windup": 0.3,  # TUNING (not in GDD) s
		"lunge_time": 0.28,  # TUNING (not in GDD) s
		"lunge_speed": 320.0,  # TUNING (not in GDD) px/s
		"lunge_damage": 4.0,  # TUNING (not in GDD) before the time scaling
		"lunge_cooldown": 3.2,  # TUNING (not in GDD) s
		"first_lunge": 1.0,  # TUNING (not in GDD) s after it spawns (staggered by its think slot)
	},
	# Heavy: a hulking one-eyed giant with stony marble-pale skin, a boulder
	# held up beside his head. Hurls it onto a red landing circle.
	"cyclops": {
		"display_name": "Cyclops",
		"max_hp": 190.0,  # TUNING (not in GDD) a heavy (Mortar Walker 150; flat armour on top)
		"move_speed": 32.0,  # TUNING (not in GDD) px/s; lumbering
		"damage": 11.0,  # TUNING (not in GDD) a fist in reach, before the time scaling
		"attack_interval": 1.7,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px edge to edge
		"radius": 16.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"flat_armor": 3.0,  # Owner-approved proposal "flat armour"; TUNING (not in GDD) the number (Sanctified Sentinel 6)
		"xp": 6,  # TUNING (not in GDD) a heavy's XP
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1, a heavy
		"mass": 4.0,  # TUNING (not in GDD) shoves the warriors
		"faction": PantheonEnemyData.FACTION,
		"kit": "cyclops",
		# Boulder throw (CyclopsKit): within throw_min..throw_range px of the
		# necromancer it stands throw_windup s with the boulder raised, then
		# hurls it: a red landing circle of boulder_radius px shows where it
		# falls (led by boulder_lead of the flight on a moving target) and it
		# lands boulder_flight s later: boulder_damage_player to the
		# necromancer inside, boulder_damage_summon to each summon inside.
		# `boulders` circles boulder_spread px apart around the aim point.
		"throw_range": 420.0,  # TUNING (not in GDD) px
		"throw_min": 90.0,  # TUNING (not in GDD) px; closer than this it just punches
		"throw_cooldown": 7.5,  # TUNING (not in GDD) s (smoke run: 6.0)
		"first_throw": 2.5,  # TUNING (not in GDD) s after it spawns
		"throw_windup": 0.7,  # TUNING (not in GDD) s
		"boulder_flight": 1.2,  # TUNING (not in GDD) s from the hand to the ground (the landing circle's warning)
		"boulder_lead": 0.6,  # TUNING (not in GDD) share of the flight a moving target is led by
		"boulder_radius": 40.0,  # TUNING (not in GDD) px (smoke run: 46)
		"boulder_damage_player": 7.0,  # TUNING (not in GDD) before the time scaling (smoke run: 9)
		"boulder_damage_summon": 4.0,  # TUNING (not in GDD) before the time scaling; a boulder lands in the packed Bone Ring (smoke run: 10 made boulders the army bot's top summon killer, 1,500 a minute)
		"boulders": 1,  # TUNING (not in GDD) boulders per throw (Polyphemus throws more)
		"boulder_spread": 0.0,  # TUNING (not in GDD) px between the landing circles of one throw's boulders
		"recover_time": 0.5,  # TUNING (not in GDD) s it stands after a throw
	},
	# The miniboss: Polyphemus, chieftain of the cyclopes: a giant with a ram
	# fleece cloak and a single huge eye, a boulder lifted over his head.
	"polyphemus": {
		"display_name": "Polyphemus the Cyclops",
		"max_hp": 2500.0,  # TUNING (not in GDD) before the time / stage scaling (the Trojan Horse 2600; smoke run: 2800 lived 9 minutes)
		"move_speed": 34.0,  # TUNING (not in GDD) px/s
		"damage": 16.0,  # TUNING (not in GDD) a fist in reach
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px edge to edge
		"radius": 30.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"flat_armor": 4.0,  # Owner-approved proposal "flat armour"; TUNING (not in GDD) (the Sanctified Sentinel 6; smoke run: 6)
		"xp": 0,  # Its reward is the XP burst below.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers prioritise it like a boss
		"mass": 16.0,  # TUNING (not in GDD) shoves warriors aside
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"faction": PantheonEnemyData.FACTION,
		"kit": "polyphemus",
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"reward_xp": 180,  # TUNING (not in GDD) XP burst on death (the Trojan Horse 170)
		"reward_crystals": 12,  # TUNING (not in GDD)
		"advance_range": 520.0,  # TUNING (not in GDD) px beyond which he strides faster
		"advance_speed_mult": 1.8,  # TUNING (not in GDD)
		# Boulder volley (the cyclops throw, bigger; keys as the Cyclops row).
		"throw_range": 520.0,  # TUNING (not in GDD) px
		"throw_min": 0.0,  # TUNING (not in GDD) he throws at any distance
		"throw_cooldown": 8.0,  # TUNING (not in GDD) s (smoke run: 6.5)
		"first_throw": 3.0,  # TUNING (not in GDD) s after arriving
		"throw_windup": 0.9,  # TUNING (not in GDD) s
		"boulder_flight": 1.3,  # TUNING (not in GDD) s
		"boulder_lead": 0.6,  # TUNING (not in GDD)
		"boulder_radius": 52.0,  # TUNING (not in GDD) px (smoke run: 64)
		"boulder_damage_player": 11.0,  # TUNING (not in GDD) before the time scaling (smoke run: 14)
		"boulder_damage_summon": 6.0,  # TUNING (not in GDD) before the time scaling (smoke run: 16 dealt 2,000 a minute to the ring)
		"boulders": 3,  # TUNING (not in GDD) per volley
		"boulder_spread": 110.0,  # TUNING (not in GDD) px
		"recover_time": 0.6,  # TUNING (not in GDD) s
		# Stomp: a circle around him for stomp_telegraph s when the necromancer
		# or stomp_min_summons summons are within stomp_range, then his feet come
		# down: summons inside take stomp_damage_summon and are thrown out
		# stomp_push px, the necromancer inside takes stomp_damage_player.
		"stomp_cooldown": 7.0,  # TUNING (not in GDD) s
		"stomp_range": 110.0,  # TUNING (not in GDD) px
		"stomp_min_summons": 3,  # TUNING (not in GDD)
		"stomp_radius": 105.0,  # TUNING (not in GDD) px
		"stomp_telegraph": 0.9,  # TUNING (not in GDD) s
		"stomp_damage_summon": 12.0,  # TUNING (not in GDD) before the time scaling (smoke run: 18)
		"stomp_damage_player": 14.0,  # TUNING (not in GDD) before the time scaling
		"stomp_push": 55.0,  # TUNING (not in GDD) px
		# Rage (below rage_hp of his max HP, once): his throws come rage_cd_mult
		# as often with rage_boulders boulders.
		"rage_hp": 0.5,  # TUNING (not in GDD) share of his max HP
		"rage_cd_mult": 0.65,  # TUNING (not in GDD)
		"rage_boulders": 4,  # TUNING (not in GDD) (smoke run: 5)
	},
	# Structure: a tall wooden siege tower on four wheels, its front plated in
	# bronze, a drawbridge folded against its top storey, an Aegean banner.
	"siege_tower": {
		"display_name": "Siege Tower",
		"max_hp": 380.0,  # TUNING (not in GDD) before the time / stage scaling (a Signal Pylon 300, a supply cart 240; smoke run: 520 let 7 of 8 towers reach the walls)
		"move_speed": 24.0,  # TUNING (not in GDD) px/s; slow enough to catch (a supply cart 26)
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 22.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD) bronze plates on its front
		"xp": 0,  # Its reward is IlionDirector's XP burst and Soul Ash bounty.
		"behavior": "cart",  # Rolls toward Enemy.post_pos (the walls) like a supply cart.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1, worth breaking
		"mass": 30.0,  # TUNING (not in GDD) warriors cannot stop it
		"is_structure": true,
		"phases": true,  # Rolls over the beach's low obstacles (nothing there stops a tower).
		"faction": PantheonEnemyData.FACTION,
		"kit": "siege_tower",
	},
}
