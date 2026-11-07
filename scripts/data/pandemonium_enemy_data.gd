## PandemoniumEnemyData — immutable design data for the Inferno kinds that
## join on Pandemonium (Stage 18, the finale of Part One; Act VI; GDD §15.0
## "Act VI foundation (phase 1)" and "Pandemonium (Act VI phase 2)";
## owner-approved proposal docs/act6/PROPOSAL.md "Stage 18: Pandemonium" and
## its roster):
##   fallen_angel   — Fallen Angel: ELITE (female, the approved Act VI figure
##                    style), a DEMON and a FLIER. Her DIVE (FallenAngelKit):
##                    she climbs out of reach, a burning ring marks where she
##                    will land, then she dives with her burning spear. ALOFT
##                    (between dives) the grounded melee blows of the army only
##                    graze her: gargoyles (they fly), the ranged classes and
##                    spells answer her (owner-approved proposal: "Gargoyles,
##                    ranged").
##   seraph_general — the Fallen Seraph General, the stage MINIBOSS
##                    (SeraphGeneralKit; PandemoniumDirector sends him): four
##                    burnt wings, a burning greatsword, the Judgment Cleave,
##                    the Wings of Ruin and, at half health, the Fallen Host
##                    (a flight of Fallen Angels from above).
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.inferno_def() looks these rows up after
## InfernoEnemyData. Rows have every key of an InfernoEnemyData.ENEMIES row
## (same meaning; "kit" ids load scripts/enemies/inferno/<kit>_kit.gd, unique
## across the Eye, Empire, Pantheon, Shogunate and Inferno folders; "demon",
## "flier", "charmer", "damned" switch the shared rules on for the kind) plus
## their kit's numbers, documented on each row.
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name PandemoniumEnemyData
extends RefCounted

## Kind id of the Fallen Angel (elite flier).
const FALLEN_ANGEL: String = "fallen_angel"
## Kind id of the Fallen Seraph General (the stage miniboss).
const SERAPH_GENERAL: String = "seraph_general"
## Damage source tag of the Fallen Angel's dive (her burning spear landing).
const DIVE_SOURCE: String = "fallen_angel_dive"
## Damage source tag of the General's Judgment Cleave.
const CLEAVE_SOURCE: String = "seraph_cleave"
## Damage source tag of the General's Wings of Ruin (burnt feathers).
const FEATHER_SOURCE: String = "seraph_feathers"

## Kind id -> design row.
const ENEMIES := {
	# Elite (female, figure style): silver hair, a cracked gold halo, black
	# wings, a black corset bodysuit with gold, thigh-high boots, a burning
	# spear. She hovers at the army (the shared melee AI; enemies always
	# advance) and DIVES:
	#   dive_every        — s between two dives (after her first: half).
	#   dive_trigger      — px: she dives only at a body within this range.
	#   dive_rise         — s she climbs out of reach while the landing ring
	#                       is marked (the circle is telegraphed for
	#                       dive_rise + dive_fall s).
	#   dive_fall         — s of the dive itself (she streaks to the mark).
	#   dive_radius       — px of the landing.
	#   dive_damage       — damage to every body in the landing (before the
	#                       time scaling; summons x undead_damage_mult).
	#   dive_push         — px each summon in the landing is thrown back.
	#   landed_time       — s she stands on the ground after the landing
	#                       (every blow lands in full).
	#   aloft_melee_taken — share (0..1) of a grounded melee summon's blow she
	#                       takes ALOFT (gargoyles, ranged classes, spells and
	#                       hazards always land in full).
	#   pit_radius / pit_life — px / s of the short Hell Pit her burning spear
	#                       leaves (only on an Act VI stage; 0 = none).
	"fallen_angel": {
		"display_name": "Fallen Angel",
		"max_hp": 96.0,  # TUNING (not in GDD) an elite (Succubus 72): she is hard to reach aloft
		"move_speed": 58.0,  # TUNING (not in GDD) px/s
		"damage": 5.0,  # TUNING (not in GDD) a spear thrust in reach, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px; the spear
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 10,  # TUNING (not in GDD) an elite's XP (Succubus 8)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; archers pick her out
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": InfernoEnemyData.FACTION,
		"kit": "fallen_angel",
		"demon": true,  # The pits spare her (she fell; she does not burn).
		"flier": true,  # Owner-approved proposal: "dives from above"
		"phases": true,  # A flier crosses obstacles (Arena.resolve_all() skips it).
		"floating": true,  # Drawn hovering.
		"dive_every": 7.0,  # TUNING (not in GDD) s
		"dive_trigger": 230.0,  # TUNING (not in GDD) px
		"dive_rise": 0.8,  # TUNING (not in GDD) s
		"dive_fall": 0.25,  # TUNING (not in GDD) s
		"dive_radius": 34.0,  # TUNING (not in GDD) px
		"dive_damage": 9.0,  # TUNING (not in GDD) before the time scaling
		"dive_push": 22.0,  # TUNING (not in GDD) px
		"landed_time": 1.4,  # TUNING (not in GDD) s
		"aloft_melee_taken": 0.35,  # Owner-approved proposal ("Gargoyles, ranged" answer her); TUNING the share
		"pit_radius": 22.0,  # TUNING (not in GDD) px
		"pit_life": 3.0,  # TUNING (not in GDD) s
	},
	# The MINIBOSS (male): a fallen archangel warlord, four burnt wings, a
	# broken halo crown, black and gold armour, a burning greatsword. He walks
	# at the necromancer (enemies always advance), strides faster when left
	# behind, shrugs off knockback like a boss, and takes turns between two
	# attacks (attack_gap s apart):
	#   JUDGMENT CLEAVE (a body within cleave_trigger px): a cone of
	#     cleave_range px, cleave_arc degrees each side, toward it, telegraphed
	#     cleave_telegraph s; every body in it is struck (cleave_damage_*,
	#     HOLY), summons thrown cleave_push px back; on an Act VI stage the
	#     blade's tip cracks the ground: a Hell Pit (cleave_pit_radius px,
	#     cleave_pit_life s) at the end of the cone.
	#   WINGS OF RUIN: feather_rays lines of burnt feathers feather_length px
	#     long around him (feather_width px wide), the first at the
	#     necromancer, telegraphed feather_telegraph s; every body on one is
	#     struck (feather_damage_*).
	#   THE FALLEN HOST (once, below host_hp of his health): host_count Fallen
	#     Angels land around the necromancer, host_distance px out.
	"seraph_general": {
		"display_name": "The Fallen Seraph General",
		"max_hp": 2500.0,  # TUNING (not in GDD) before the time / stage scaling (the Kirin 2300, Polyphemus 2500)
		"move_speed": 44.0,  # TUNING (not in GDD) px/s
		"damage": 13.0,  # TUNING (not in GDD) a blow in reach, before the time scaling
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 16.0,  # TUNING (not in GDD) px
		"radius": 24.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD) black and gold plate
		"xp": 0,  # His reward is the XP burst below.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers prioritise him like a boss
		"mass": 14.0,  # TUNING (not in GDD) shoves warriors aside
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"faction": InfernoEnemyData.FACTION,
		"kit": "seraph_general",
		"demon": true,  # The pits spare him.
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"reward_xp": 220,  # TUNING (not in GDD) XP burst on death (the Kirin 200)
		"reward_crystals": 12,  # TUNING (not in GDD)
		"reward_ash": 15,  # TUNING (not in GDD) Soul Ash bounty (objective_ash; the Kirin 14)
		"advance_range": 420.0,  # TUNING (not in GDD) px beyond which he strides faster
		"advance_speed_mult": 1.9,  # TUNING (not in GDD)
		"first_attack": 2.5,  # TUNING (not in GDD) s after he arrives
		"attack_gap": 2.0,  # TUNING (not in GDD) s between the end of one attack and the next
		"recover_time": 0.5,  # TUNING (not in GDD) s he stands after an attack
		"cleave_trigger": 110.0,  # TUNING (not in GDD) px: he cleaves at a body this close, else the feathers
		"cleave_range": 120.0,  # TUNING (not in GDD) px
		"cleave_arc": 55.0,  # TUNING (not in GDD) degrees each side
		"cleave_telegraph": 0.9,  # TUNING (not in GDD) s
		"cleave_damage_player": 13.0,  # TUNING (not in GDD) before the time scaling
		"cleave_damage_summon": 12.0,  # TUNING (not in GDD) before the time scaling
		"cleave_push": 30.0,  # TUNING (not in GDD) px
		"cleave_pit_radius": 30.0,  # TUNING (not in GDD) px
		"cleave_pit_life": 6.0,  # TUNING (not in GDD) s
		"feather_rays": 8,  # TUNING (not in GDD)
		"feather_length": 260.0,  # TUNING (not in GDD) px
		"feather_width": 16.0,  # TUNING (not in GDD) px
		"feather_telegraph": 1.0,  # TUNING (not in GDD) s
		"feather_damage_player": 9.0,  # TUNING (not in GDD) before the time scaling
		"feather_damage_summon": 8.0,  # TUNING (not in GDD) before the time scaling
		"host_hp": 0.5,  # TUNING (not in GDD) share of his health that calls the Fallen Host
		"host_count": 3,  # TUNING (not in GDD) Fallen Angels
		"host_distance": 200.0,  # TUNING (not in GDD) px from the necromancer they land
	},
}
