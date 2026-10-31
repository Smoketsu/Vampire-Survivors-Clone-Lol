## BurningGateEnemyData — immutable design data for the Inferno kinds that
## join on the Burning Gate (Stage 16) (Act VI; GDD §15.0 "Act VI foundation
## (phase 1)" and "The Burning Gate (Act VI phase 2)"; owner-approved proposal
## docs/act6/PROPOSAL.md, "Roster" and "Stage 16: The Burning Gate"):
##   lava_hound  — HELLHOUND (owner-approved roster "Hellhound: Pack, lava
##                 hounds; leave a short fire trail"): fast pack fodder that
##                 leaves a trail of small Hell Pits behind it (HellPits
##                 .open_pit(), the one pit path); a DEMON (its own fire spares
##                 it). The id is lava_hound because "hellhound" is already the
##                 Bone Hounds' summon evolution (an enemy kind must never share
##                 a summon id).
##   pit_cultist — PIT CULTIST (roster "Support: living humans who open new
##                 portals; priority target"): a robed living man (he burns in
##                 the pits) who stops to chant a rite that tears a demon portal
##                 open beside him (DemonPortals.open(), the one portal path).
##                 Kill him during the chant and no portal opens.
##   gatekeeper  — THE GATEKEEPER, the stage's miniboss (owner-approved: "a
##                 chained giant that drags the damned in"): chains flung in a
##                 fan hook the first summon or damned soul they meet and drag
##                 it to him (GatekeeperKit.pull(), the one pull path); a
##                 dragged summon is crushed, a dragged soul is devoured (it
##                 heals him); a telegraphed slam; he hauls in a coffle of the
##                 damned on his chains. A DEMON.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.inferno_def() looks these rows up after
## InfernoEnemyData. Rows have every key of an InfernoEnemyData.ENEMIES row
## (same meaning; "kit" ids load scripts/enemies/inferno/<kit>_kit.gd, unique
## across the Eye, Empire, Pantheon, Shogunate and Inferno folders; "demon",
## "flier", "charmer", "damned" switch the shared rules on for the kind). Kit
## numbers are row keys documented on each row.
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name BurningGateEnemyData
extends RefCounted

## Kind id of the Hellhound (the enemy pack; not the Bone Hounds' evolution).
const LAVA_HOUND: String = "lava_hound"
## Kind id of the Pit Cultist.
const PIT_CULTIST: String = "pit_cultist"
## Kind id of the Gatekeeper (the stage's miniboss).
const GATEKEEPER: String = "gatekeeper"
## Stats tag of a Hellhound's trail pits (HellPits opts "tag": pits_opened_hound_trail).
const TRAIL_TAG: String = "hound_trail"
## Damage tag of the Gatekeeper's chains (stats player_dmg_from_ /
## summon_dmg_from_gatekeeper_chain).
const CHAIN_SOURCE: String = "gatekeeper_chain"
## Damage tag of the Gatekeeper's slam.
const SLAM_SOURCE: String = "gatekeeper_slam"

## Kind id -> design row.
const ENEMIES := {
	# Pack fodder: a lava hound, black-crusted hide cracked with glowing lava.
	# Its TRAIL: while it runs, every trail_every s it leaves a small pit of
	# trail_radius px behind it (a short glow of trail_telegraph s, then it
	# burns trail_life s at trail_dps_mult x the pits' burn), only on an Act VI
	# stage (the pits burn there) and only while trail_room slots of the pits'
	# hard cap stay free (the stage's and the bosses' pits come first).
	#   trail_every     — s between two trail pits of one hound.
	#   trail_radius    — px of a trail pit.
	#   trail_telegraph — s of a trail pit's glow before it burns.
	#   trail_life      — s a trail pit burns.
	#   trail_dps_mult  — x the Hell Pits' burn.
	#   trail_room      — pit slots (of PITS max_pits) a hound leaves free.
	#   trail_min_move  — px it must have run since its last pit.
	#   trail_reach     — px from the nearest necromancer within which it trails.
	"lava_hound": {
		"display_name": "Hellhound",  # Owner-approved roster
		"max_hp": 20.0,  # TUNING (not in GDD) pack fodder (a damned 14)
		"move_speed": 94.0,  # TUNING (not in GDD) px/s; the fastest of the act on foot
		"damage": 3.5,  # TUNING (not in GDD) a burning bite, before the time scaling
		"attack_interval": 0.85,  # TUNING (not in GDD) s
		"attack_range": 5.0,  # TUNING (not in GDD) px edge to edge
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.35,  # TUNING (not in GDD) 0..1
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": InfernoEnemyData.FACTION,
		"kit": "lava_hound",
		"demon": true,  # A hound of the Pit: its own fire spares it.
		"fodder": true,
		"trail_every": 2.2,  # TUNING (not in GDD) s; first pass 0.8 (489 hounds laid 4621 pits in one run), second 1.6
		"trail_radius": 14.0,  # TUNING (not in GDD) px ("small pits")
		"trail_telegraph": 0.3,  # TUNING (not in GDD) s
		"trail_life": 1.8,  # TUNING (not in GDD) s ("a short fire trail"); first pass 2.2
		"trail_dps_mult": 0.4,  # TUNING (not in GDD) first pass 0.6 (the pits were the army's top killer)
		"trail_room": 16,  # TUNING (not in GDD) slots left free (first pass 10)
		"trail_min_move": 18.0,  # TUNING (not in GDD) px
		"trail_reach": 600.0,  # TUNING (not in GDD) px: it trails only this close to a necromancer (where the army walks)
	},
	# Support: a living man in a ragged red robe and a horned mask, a ritual
	# dagger and a smoking censer. His RITE: when it is ready, a necromancer
	# stands within rite_range px and fewer than PORTALS max_open portals
	# stand, he stops and chants for rite_time s (a charm-pink summoning circle
	# under the spot, rite_ahead px toward the necromancer); if he lives to the
	# end a demon portal opens there (DemonPortals.open()). Killing him during
	# the chant stops it: the priority target.
	#   rite_first — s after he appears before his first rite.
	#   rite_every — s between two rites of one cultist (from the last chant's end).
	#   rite_range — px: he chants only this close to a necromancer.
	#   rite_time  — s of the chant (the telegraph).
	#   rite_ahead — px toward the necromancer the portal opens.
	"pit_cultist": {
		"display_name": "Pit Cultist",  # Owner-approved roster
		"max_hp": 34.0,  # TUNING (not in GDD) a frail human
		"move_speed": 46.0,  # TUNING (not in GDD) px/s
		"damage": 3.0,  # TUNING (not in GDD) a ritual dagger, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 5.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 5,  # TUNING (not in GDD) a priority target pays
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # Owner-approved roster: "Priority target"
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": InfernoEnemyData.FACTION,
		"kit": "pit_cultist",
		"rite_first": 4.0,  # TUNING (not in GDD) s
		"rite_every": 24.0,  # TUNING (not in GDD) s
		"rite_range": 420.0,  # TUNING (not in GDD) px
		"rite_time": 3.0,  # TUNING (not in GDD) s, as long as a seal: the army has time to answer
		"rite_ahead": 40.0,  # TUNING (not in GDD) px
	},
	# Miniboss: a chained giant of the gate, iron collar and manacles, long
	# chains trailing from both wrists, ash-grey demon hide. Spawned once by
	# BurningGateDirector (the "gatekeeper" event, 9:00 left).
	#   advance_range / advance_speed_mult — beyond this px he strides faster.
	#   chain_every     — s between two chain throws.
	#   chain_count     — chains in one throw (a fan toward the necromancer).
	#   chain_spread    — rad between two chains of the fan.
	#   chain_range     — px a chain flies.
	#   chain_width     — px of a chain's lane (its telegraph).
	#   chain_telegraph — s the lanes show before the chains fly.
	#   chain_speed     — px/s of a flying chain.
	#   chain_damage_player — damage to the necromancer a chain strikes (it
	#                     never drags him).
	#   chain_damage_summon — damage to a summon a chain hooks.
	#   drag_speed      — px/s a hooked body is dragged toward him.
	#   drag_hold       — s at most a chain holds its body.
	#   crush_damage    — damage to a summon dragged to his feet.
	#   devour_heal     — share of his max HP a devoured damned soul heals.
	#   slam_every / slam_trigger / slam_windup / slam_radius /
	#   slam_damage_player / slam_damage_summon / slam_push — his slam (as
	#                     the Demon Brute's, bigger).
	#   coffle_every    — s between two coffles of the damned he hauls in.
	#   coffle_count    — damned souls in a coffle.
	"gatekeeper": {
		"display_name": "The Gatekeeper",  # Owner-approved proposal
		"max_hp": 2300.0,  # TUNING (not in GDD) before the time / stage scaling (the General of the Left 2600); first pass 2800 lived 6 min
		"move_speed": 40.0,  # TUNING (not in GDD) px/s; a chained giant
		"damage": 15.0,  # TUNING (not in GDD) a manacled fist in reach
		"attack_interval": 1.5,  # TUNING (not in GDD) s
		"attack_range": 16.0,  # TUNING (not in GDD) px
		"radius": 28.0,  # TUNING (not in GDD) px
		"armor": 0.25,  # TUNING (not in GDD)
		"flat_armor": 2.0,  # TUNING (not in GDD) iron collar and manacles
		"xp": 0,  # Its reward is the XP burst below.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers prioritise it like a boss
		"mass": 16.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"faction": InfernoEnemyData.FACTION,
		"kit": "gatekeeper",
		"demon": true,
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"reward_xp": 190,  # TUNING (not in GDD) XP burst on death (the General 180)
		"reward_crystals": 12,  # TUNING (not in GDD)
		"advance_range": 480.0,  # TUNING (not in GDD) px
		"advance_speed_mult": 1.8,  # TUNING (not in GDD)
		"chain_every": 8.0,  # TUNING (not in GDD) s; first pass 6.5
		"chain_count": 3,  # TUNING (not in GDD)
		"chain_spread": 0.32,  # TUNING (not in GDD) rad
		"chain_range": 320.0,  # TUNING (not in GDD) px
		"chain_width": 16.0,  # TUNING (not in GDD) px
		"chain_telegraph": 0.7,  # TUNING (not in GDD) s
		"chain_speed": 540.0,  # TUNING (not in GDD) px/s
		"chain_damage_player": 9.0,  # TUNING (not in GDD) before the time scaling
		"chain_damage_summon": 6.0,  # TUNING (not in GDD) before the time scaling
		"drag_speed": 230.0,  # TUNING (not in GDD) px/s
		"drag_hold": 2.5,  # TUNING (not in GDD) s
		"crush_damage": 14.0,  # TUNING (not in GDD) before the time scaling
		"devour_heal": 0.006,  # TUNING (not in GDD) of his max HP per soul; first pass 0.015 (healed 2555 in one fight)
		"slam_every": 8.0,  # TUNING (not in GDD) s
		"slam_trigger": 60.0,  # TUNING (not in GDD) px edge to edge
		"slam_windup": 1.0,  # TUNING (not in GDD) s
		"slam_radius": 88.0,  # TUNING (not in GDD) px
		"slam_damage_player": 12.0,  # TUNING (not in GDD) before the time scaling
		"slam_damage_summon": 12.0,  # TUNING (not in GDD) before the time scaling; first pass 16
		"slam_push": 36.0,  # TUNING (not in GDD) px
		"coffle_every": 20.0,  # TUNING (not in GDD) s
		"coffle_count": 6,  # TUNING (not in GDD)
	},
}
