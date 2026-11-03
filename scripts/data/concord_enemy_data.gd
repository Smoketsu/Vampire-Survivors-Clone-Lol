## ConcordEnemyData — immutable design data for the kinds THE CONCORD OF STARS
## fields on every Act IX stage (GDD §15.0 "Act IX foundation (phase 1)";
## owner-approved proposal docs/act9/PROPOSAL.md "Act IX: The Concord of
## Stars"). Long ago something out in the dark seeded life on this world and
## comes back to reap the dead; the necromancer has taken every soul, and the
## Concord (a coalition of alien races under the Harvesters who rule it) comes
## to find out why. One coalition (owner): the Brood lead Stage 25, the Vrask
## Stage 26, the Harvesters Stage 27, the Luminous in every stage. The shared
## kinds of phase 1 (one or two of each race, every one used by a rule):
##   broodling      — the Brood: fodder; small, fast insects in swarms of 12.
##   grey_drone     — the Harvesters: fodder; small greys in squads, a probe
##                    that fires a short beam (BEAMS).
##   saucer         — the Harvesters: an elite FLIER that hovers over the ring
##                    and lifts a summon in a tractor beam (ABDUCTION); in
##                    flight only airborne summons, ranged attacks, casters,
##                    spells and volleys hit it (the Act VII Night Wings test).
##   vrask_hunter   — the Vrask: an elite hunter, male; CLOAKED while it moves
##                    (a shimmer), a three-dot plasma lock, then one shot (a
##                    short beam).
##   lumen_sentinel — the Luminous: ranged, male; sweeping beams; a shield that
##                    soaks the first hits (the existing holy shield path).
##   prism          — the Luminous: support, the Star-Seer (female, figure
##                    style); a beam that passes through her splits into three.
##   concord_terraformer — a landing pod (a STRUCTURE row) that roots and grows
##                    alien ground around it (TERRAFORMING); Terraforming drops
##                    it, this row names it, carries its look and lets
##                    --spawn= drop one to test.
## The Reckoning, the Final Harvest, has no kind of its own: its heavy is the
## saucer (RECKONING_KIND) with the shared kinds as companions
## (RECKONING_COMPANIONS), and its eye is a beam (ConcordRulesData.EYE_SOURCE).
## Each stage's own kinds live in its own file (CrashSiteEnemyData,
## ProvingMoonEnemyData, ArkEnemyData; empty until phase 2: the Burrower and
## the Acid Spitter, the Warbeast, the Grey Overseer and the Luminous Archon,
## the bosses' allies); EnemyDirector.enemy_def() looks them up through
## concord_def(), this file first, after the Last Line's tables.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Concord keys (absent = off):
##   faction       — "concord" (the Codex's Concord tab, the reports).
##   kit           — a CovenantKit id; a Concord kit lives in
##                   scripts/enemies/concord/<kit>_kit.gd (CovenantKits loads it
##                   by name after the City's folder, so kit ids must be unique
##                   across the eight folders). Every Concord kind has one (a
##                   ConcordKit).
##   race          — String, one of ConcordRulesData.RACES (the Codex and the
##                   report group by it).
##   beam          — Dictionary: the kind's beam: "style" (a
##                   ConcordRulesData.BEAM_STYLES id) plus any of that style's
##                   keys to override its numbers; absent = it fires none.
##   abducts       — bool: a tractor beam (ABDUCTION; Abduction.lift()). Keys:
##                   hover_radius (px from the nearest necromancer it hovers,
##                   over the ring's edge), hover_turn (rad/s it circles there),
##                   lift_range (px from it a summon can be picked), lift_every
##                   (s between two lifts), carry_drift (px/s it drifts outward
##                   while it holds a summon).
##   cloak         — Dictionary: the Vrask cloak (absent = none): alpha (the
##                   shimmer's opacity), cloaked_taken (share of a summon's or
##                   a hazard's hit it takes while cloaked), reveal_time (s a
##                   spell hit or its own shot reveals it), min_speed (px/s it
##                   must move to stay cloaked).
##   heals_on_turf — bool: heals on live alien ground (TERRAFORMING); absent =
##                   true for every Concord kind but a structure.
##   flight_melee_taken — share of a GROUNDED MELEE summon's blow a flier takes
##                   in flight (FallenAngelKit.grounded_melee(); 0 = it finds
##                   only air), the Night Wings test.
##   lumen_shield  — share of its max HP its shield soaks before it is hurt
##                   (Enemy.holy_shield, the existing path; never renewed).
##   prism         — true: a beam whose line passes through it splits into
##                   three (ConcordBeams; once per beam).
##   fodder        — true: fodder (reports).
##   elite_kind    — true: an elite of the roster (reports; it is NOT spawned
##                   as an elite: its own row is already strong).
##   figure        — true: a figure-style woman (the art pass's bust rig; no
##                   rule reads it).
## Flying uses the existing "flies" / "phases" / "floating" keys and the shield
## the existing holy shield path: no second one.
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name ConcordEnemyData
extends RefCounted

## Faction id of the Concord's kinds (row "faction").
const FACTION: String = "concord"
## Kind id of the Brood's fodder.
const BROODLING: String = "broodling"
## Kind id of the Harvesters' fodder.
const GREY_DRONE: String = "grey_drone"
## Kind id of the Harvesters' abducting flier (the Final Harvest's heavy).
const SAUCER: String = "saucer"
## Kind id of the Vrask's hunter.
const VRASK_HUNTER: String = "vrask_hunter"
## Kind id of the Luminous's ranged sentinel.
const LUMEN_SENTINEL: String = "lumen_sentinel"
## Kind id of the Luminous's Star-Seer.
const PRISM: String = "prism"
## Kind id of the landing pod (a structure row; Terraforming drops it).
const TERRAFORMER: String = "concord_terraformer"
## Sprite key of the landing pod (assets/sprites/structures/).
const TERRAFORMER_SPRITE: String = "structures/concord_terraformer"
## Sprite key of a destroyed landing pod.
const TERRAFORMER_DEAD_SPRITE: String = "structures/concord_terraformer_dead"
## Sprite folder of the Concord's kinds (assets/sprites/concord/).
const SPRITE_DIR: String = "concord/"
## Ranged damage tags of the Concord beyond its "ranged" rows' kind ids (a
## future counter-passive may read them; the beams' sources are their kinds').
const RANGED_SOURCES: Array[String] = [ConcordRulesData.EYE_SOURCE]

## The Final Harvest's heavy (the RECKONING "kind" of every Act IX stage):
## the saucers fill the sky.
const RECKONING_KIND: String = SAUCER
## The Final Harvest's companions (the RECKONING "companions" of every Act IX
## stage; brief: broodlings, grey drones, a Vrask hunter, a Lumen Sentinel).
const RECKONING_COMPANIONS: Array = [
	{"kind": BROODLING, "count": 12, "growth": 2.0},  # TUNING (not in GDD) a swarm
	{"kind": GREY_DRONE, "count": 4, "growth": 1.0},  # TUNING (not in GDD) a squad
	{"kind": VRASK_HUNTER, "count": 1, "growth": 0.34},  # TUNING (not in GDD) brief: a Vrask hunter
	{"kind": LUMEN_SENTINEL, "count": 1, "growth": 0.34},  # TUNING (not in GDD) brief: a Lumen Sentinel
]

## The Concord's shared kinds, keyed by kind id.
const ENEMIES := {
	# The Brood, fodder: small, fast insects in swarms of 12 (owner-approved
	# proposal: "Fast swarms of 12 | Anything").
	"broodling": {
		"display_name": "Broodling",
		"max_hp": 9.0,  # TUNING (not in GDD) fodder, frail (the Vampire Bat 9)
		"move_speed": 82.0,  # TUNING (not in GDD) px/s; fast
		"damage": 2.0,  # TUNING (not in GDD) a claw, before the time scaling
		"attack_interval": 0.9,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 6.0,  # TUNING (not in GDD) px (~22 px sprite)
		"armor": 0.0,
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.2,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.5,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "broodling",
		"race": "brood",  # Owner: the Brood lead Stage 25
		"fodder": true,
	},  # The broodling.
	# The Harvesters, fodder: small greys in squads with a glowing probe that
	# fires a short beam (BEAMS "probe": a 1 s aiming line, then a short, thin
	# beam that sweeps a little). Ranged: it advances and probes from range.
	"grey_drone": {
		"display_name": "Grey Drone",
		"max_hp": 14.0,  # TUNING (not in GDD) fodder
		"move_speed": 46.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # Unused: its probe beam's dps (BEAM_STYLES "probe").
		"attack_interval": 3.6,  # TUNING (not in GDD) s between two probes (after the beam ends)
		"attack_range": 130.0,  # TUNING (not in GDD) px (the probe beam reaches 150)
		"radius": 8.0,  # TUNING (not in GDD) px (~28 px sprite)
		"armor": 0.0,
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 0.0,  # Unused: a beam, not a projectile.
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.35,  # TUNING (not in GDD) 0..1
		"mass": 0.8,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "grey_drone",
		"race": "harvesters",  # Owner-approved proposal: the Harvesters
		"fodder": true,
		"beam": {"style": "probe"},  # Brief: a probe that fires a short beam (Beams)
	},  # The grey drone.
	# The Harvesters, an elite FLIER (Night Wings: no summon body-blocks it,
	# grounded melee blows find only air; "phases": it passes over the
	# obstacles; "floating": the ground spares it). It hovers over the ring's
	# edge, picks the nearest liftable summon, shows a green tractor cone for
	# the windup and lifts it (ABDUCTION; Abduction.lift()). It never attacks
	# otherwise. Owner-approved proposal: "Elite, flying | Abduction |
	# Gargoyles, Archers, spells".
	"saucer": {
		"display_name": "Saucer",
		"max_hp": 110.0,  # TUNING (not in GDD) an elite flier
		"move_speed": 74.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # Never strikes: the tractor beam only.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 18.0,  # TUNING (not in GDD) px (~64 px sprite, top-down)
		"armor": 0.15,  # TUNING (not in GDD) a hull
		"xp": 8,  # TUNING (not in GDD)
		"behavior": "melee",  # Unused: its kit flies it.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; shoot it down in time
		"mass": 3.0,  # TUNING (not in GDD)
		"slow_resist": 0.5,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "saucer",
		"race": "harvesters",  # Owner-approved proposal: the Harvesters
		"elite_kind": true,  # Brief: an elite flier
		"flies": true,  # Brief: row "flies" (the Act VII Night Wings rule)
		"phases": true,  # A flier crosses obstacles (Arena.resolve_all() skips it).
		"floating": true,  # Over the ground (the terrain slows and fires spare it).
		"flight_melee_taken": 0.0,  # Brief: grounded melee blows deal 0 in flight
		"abducts": true,  # Owner-approved proposal: Abduction
		"hover_radius": 170.0,  # TUNING (not in GDD) px from the necromancer (the ring is 60-150 px)
		"hover_turn": 0.25,  # TUNING (not in GDD) rad/s it circles
		"lift_range": 150.0,  # TUNING (not in GDD) px
		"lift_every": 7.0,  # TUNING (not in GDD) s between two lifts
		"carry_drift": 10.0,  # TUNING (not in GDD) px/s outward while it holds a summon
	},  # The saucer.
	# The Vrask, an elite hunter (male): CLOAKED while it moves (a shimmer: its
	# body drawn at the cloak's alpha; while cloaked a summon's or a hazard's
	# hit deals cloaked_taken of itself, and a SPELL hit reveals it for
	# reveal_time s: "Area damage reveals it"); it stops to aim its shoulder
	# caster: a three-dot plasma lock on its target for the aim, then one shot
	# (BEAM_STYLES "lock": a 0.15 s pulse), uncloaked while it aims and fires.
	"vrask_hunter": {
		"display_name": "Vrask Hunter",
		"max_hp": 70.0,  # TUNING (not in GDD) an elite
		"move_speed": 56.0,  # TUNING (not in GDD) px/s
		"damage": 4.0,  # TUNING (not in GDD) a glaive blow in reach, before the time scaling (its lock is a beam)
		"attack_interval": 4.5,  # TUNING (not in GDD) s between two locks (after the shot)
		"attack_range": 260.0,  # TUNING (not in GDD) px (the lock beam reaches 300)
		"radius": 11.0,  # TUNING (not in GDD) px (~46 px sprite)
		"armor": 0.15,  # TUNING (not in GDD) dark armour
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 0.0,  # Unused: a beam.
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1
		"mass": 2.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "vrask_hunter",
		"race": "vrask",  # Owner: the Vrask lead Stage 26
		"elite_kind": true,  # Owner-approved proposal: "Vrask Hunter | Elite"
		"beam": {"style": "lock"},  # Owner-approved proposal: "a three-dot plasma caster lock, then a shot"
		"cloak": {"alpha": 0.22, "cloaked_taken": 0.5, "reveal_time": 2.0, "min_speed": 8.0},  # TUNING (not in GDD) owner-approved proposal: "Cloaked (a shimmer while it moves) ... Area damage reveals it"
	},  # The Vrask hunter.
	# The Luminous, ranged (male): a being of white-gold light in crystal armour
	# with a beam staff: SWEEPING BEAMS (BEAM_STYLES "sweep") and a SHIELD that
	# soaks the first hits (Enemy.holy_shield, the existing path: lumen_shield
	# of its max HP, never renewed). Owner-approved proposal: "Reflect its
	# beams; Wither".
	"lumen_sentinel": {
		"display_name": "Lumen Sentinel",
		"max_hp": 58.0,  # TUNING (not in GDD)
		"move_speed": 40.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # Unused: its beam's dps (BEAM_STYLES "sweep").
		"attack_interval": 6.5,  # TUNING (not in GDD) s between two sweeps (after the beam ends; first pass 5)
		"attack_range": 220.0,  # TUNING (not in GDD) px (the sweep reaches 260)
		"radius": 11.0,  # TUNING (not in GDD) px (~46 px sprite)
		"armor": 0.1,  # TUNING (not in GDD) crystal armour
		"xp": 5,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 0.0,  # Unused: a beam.
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1
		"mass": 1.6,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "lumen_sentinel",
		"race": "luminous",  # Owner: the Luminous are mixed into every stage
		"beam": {"style": "sweep"},  # Owner-approved proposal: "Sweeping beams"
		"lumen_shield": 0.3,  # TUNING (not in GDD) owner-approved proposal: "a shield that soaks the first hits" (first pass 0.5)
	},  # The Lumen Sentinel.
	# The Luminous, support: THE STAR-SEER (female, figure style; pale lavender
	# skin, white-gold hair, a floating prism, an opaque high-necked gown). She
	# fires nothing: a Concord beam whose line passes through her ends there
	# and splits into three (ConcordBeams; once per beam). She keeps to the
	# beams' lines from range (behavior "ranged" with no shot).
	"prism": {
		"display_name": "Star-Seer",
		"max_hp": 44.0,  # TUNING (not in GDD)
		"move_speed": 42.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # Fires nothing.
		"attack_interval": 2.0,
		"attack_range": 200.0,  # TUNING (not in GDD) px (where she hangs back)
		"radius": 10.0,  # TUNING (not in GDD) px (~44 px sprite)
		"armor": 0.0,
		"xp": 5,  # TUNING (not in GDD)
		"behavior": "ranged",  # Advances and hangs back like a caster; its kit fires nothing.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1; "kill it before the beams line up"
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "prism",
		"race": "luminous",  # Owner: the Luminous are mixed into every stage
		"prism": true,  # Owner-approved proposal: "Splits any beam that passes through it into three"
		"figure": true,  # Owner-approved proposal: the Star-Seer, figure style
	},  # The Star-Seer.
	# A LANDING POD (a structure): it falls on a telegraphed streak, roots and
	# grows alien ground around it, one ring of cells at a time
	# (TERRAFORMING). Destroyed, it stops growing; its ground stays until
	# burnt. Never healed by the turf.
	"concord_terraformer": {
		"display_name": "Terraformer Pod",
		"max_hp": 150.0,  # TUNING (not in GDD)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 16.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD) a hull
		"xp": 8,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.65,  # TUNING (not in GDD) 0..1; break the pods
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": FACTION,
		"kit": "concord_terraformer",
		"race": "harvesters",  # The Harvesters' terraforming (the report lists it with them).
		"heals_on_turf": false,  # Brief: false for structures
	},  # The landing pod.
}
