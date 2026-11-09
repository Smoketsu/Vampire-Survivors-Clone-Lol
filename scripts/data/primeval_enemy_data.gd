## PrimevalEnemyData — immutable design data for the kinds THE AGE OF TITANS
## fields on every one of its stages (temporary Act XIV, final slot XIV; GDD
## §15.0 "The Age of Titans foundation (phase 1)"; design
## docs/proposals/LAST_SIX_ACTS.md section XIV and
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 2, "Roster"). No gods, no armies,
## no walls: only animals the size of houses, fern green, volcanic orange, tar
## black, dust ochre and bone white. No human fights in this act. The shared
## kinds of phase 1 (each one feeds a rule or the Reckoning):
##   scuttler      — the swarm: fast, tiny, chittering, in swarms of 12; fodder.
##   razorclaw     — a hunter: the pack predator (PACKS; the first of each pack
##                   is its alpha, the female; the others are males).
##   frill_spitter — a hunter (male): lobs a venom bolt from range (the plain
##                   ranged attack; phase 2 may add the puddle).
##   longneck      — a herd beast (male / female mix): huge, slow, neutral,
##                   bleeds big XP and a heavy corpse; stampedes (HERDS).
##   duckbill      — a herd beast: smaller; its crest horn hears a fight from
##                   farther off (a wider "fright"), so its herd runs sooner.
##   skyraider     — a flier (male), a thief: dives on crystal piles and flies
##                   them to its nest (SCAVENGERS); it never bites.
##   tyrant        — a titan (female / male): the Reckoning's heavy (the
##                   Stampede of Ash: "Tyrants roam"); phase 2 (the Last Day)
##                   gives it the swallow and the roar.
## Each stage's own kinds live in its own file (FernBasinEnemyData,
## GreatPlainEnemyData, LastDayEnemyData; empty until phase 2: the Bog Croc,
## the Horncharger, the Clubtail, the Stormwing, the stage minibosses and the
## bosses' allies); EnemyDirector.enemy_def() looks them up through
## primeval_def(), this file first, after the Celestial Host's tables.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Age of Titans keys (absent = off):
##   faction    — "primeval" (the Codex's Titans tab, the reports).
##   kit        — a CovenantKit id; an Age of Titans kit lives in
##                scripts/enemies/primeval/<kit>_kit.gd (CovenantKits loads it
##                by name after the Host's folder, so kit ids must be unique
##                across every kit folder). Every kind has one (a PrimevalKit).
##   group      — String, one of PrimevalRulesData.GROUPS.
##   pack       — bool: a pack predator (PackBrain steers it; PACKS).
##   alpha_sprite — the alpha's own art key (drawn when it exists; the kind's
##                art with the alpha's mark until then).
##   herd       — bool: a neutral herd beast (Herds owns its every tick: it
##                grazes, never attacks, stampedes; its kill raises a Fossil
##                Giant; HERDS).
##   fright     — px: a herd beast this close to a standing necromancer
##                frightens its herd into a stampede (being hurt always does).
##   scavenger  — bool: a crystal thief (Scavengers schedules its dives;
##                SCAVENGERS).
##   fodder     — true: fodder (reports).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal. Tuned for the act's FINAL slot XIV (above the
## Concord of Stars), not its temporary number.
class_name PrimevalEnemyData
extends RefCounted

## Faction id of the Age of Titans' kinds (row "faction").
const FACTION: String = PrimevalRulesData.FACTION
## Kind id of the Scuttler.
const SCUTTLER: String = "scuttler"
## Kind id of the Razorclaw (the pack predator).
const RAZORCLAW: String = "razorclaw"
## Kind id of the Frill-Spitter.
const FRILL_SPITTER: String = "frill_spitter"
## Kind id of the Longneck (a herd beast).
const LONGNECK: String = "longneck"
## Kind id of the Duckbill (a herd beast).
const DUCKBILL: String = "duckbill"
## Kind id of the Skyraider (the crystal thief).
const SKYRAIDER: String = "skyraider"
## Kind id of the Tyrant (the Reckoning's heavy).
const TYRANT: String = "tyrant"
## Sprite folder of the Age of Titans' kinds (assets/sprites/primeval/).
const SPRITE_DIR: String = "primeval/"

## The Stampede of Ash's heavy (the RECKONING "kind" of every Titans stage; "Tyrants roam").
const RECKONING_KIND: String = TYRANT
## The Stampede of Ash's companions (the RECKONING "companions"; "packs double":
## the Razorclaws' growth).
const RECKONING_COMPANIONS: Array = [
	{"kind": SCUTTLER, "count": 12, "growth": 2.0},  # TUNING (not in GDD) a swarm of 12, as the roster says
	{"kind": RAZORCLAW, "count": 4, "growth": 4.0},  # Owner-approved proposal: "packs double"; TUNING (not in GDD) counts
	{"kind": FRILL_SPITTER, "count": 2, "growth": 1.0},  # TUNING (not in GDD)
]

## The Age of Titans' shared kinds, keyed by kind id.
const ENEMIES := {
	# The swarm (owner-approved proposal: "Scuttler (swarm of 12) | Fodder |
	# Fast, tiny, chittering swarm | Anything; area damage").
	"scuttler": {
		"display_name": "Scuttler",
		"max_hp": 10.0,  # TUNING (not in GDD) fodder (a broodling 9; slot XIV is above the Concord)
		"move_speed": 84.0,  # TUNING (not in GDD) px/s; fast
		"damage": 2.5,  # TUNING (not in GDD) a nip, before the time scaling
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
		"mass": 0.4,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "scuttler",
		"group": "swarm",
		"fodder": true,
	},  # The Scuttler.
	# A hunter: the pack predator (owner-approved proposal: "Razorclaw (female
	# alpha, males in the pack) | Soldier | Pack leap over the first blocker,
	# rakes the nearest summon | Kill the alpha first"). PACKS steers it; the
	# leap is phase 2's.
	"razorclaw": {
		"display_name": "Razorclaw",
		"max_hp": 46.0,  # TUNING (not in GDD) a soldier
		"move_speed": 66.0,  # TUNING (not in GDD) px/s (x1.4 in a pack's rush)
		"damage": 6.5,  # TUNING (not in GDD) a rake, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px (~44 px sprite)
		"armor": 0.1,  # TUNING (not in GDD) feathered hide
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "razorclaw",
		"group": "hunters",
		"pack": true,  # Owner-approved proposal: Packs
		"alpha_sprite": "primeval/razorclaw_alpha",  # The female alpha's art (ART_MANIFEST); the kind's art with the mark until then
	},  # The Razorclaw.
	# A hunter (male): spits venom from range (owner-approved proposal:
	# "Frill-Spitter (male) | Ranged | Lobs a venom bolt that leaves a short
	# puddle; arcing | Kill on approach; Wither"). The plain ranged attack in
	# phase 1; phase 2 may add the puddle.
	"frill_spitter": {
		"display_name": "Frill-Spitter",
		"max_hp": 30.0,  # TUNING (not in GDD) ranged
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 5.0,  # TUNING (not in GDD) one venom bolt, before the time scaling
		"attack_interval": 2.6,  # TUNING (not in GDD) s
		"attack_range": 250.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px (~40 px sprite)
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 300.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.65,  # TUNING (not in GDD) 0..1; "kill on approach"
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "frill_spitter",
		"group": "hunters",
	},  # The Frill-Spitter.
	# A herd beast (male / female mix; owner-approved proposal: "Longneck |
	# Herd (neutral) | Huge, slow, bleeds XP; stampedes | Shelter, lure, kill
	# for the corpse"). HERDS owns its every tick; it never attacks (damage 0).
	"longneck": {
		"display_name": "Longneck",
		"max_hp": 420.0,  # TUNING (not in GDD) huge (it takes the army a while: the corpse is the prize)
		"move_speed": 40.0,  # TUNING (not in GDD) px/s grazing base (x graze_mult; a stampede runs at run_speed)
		"damage": 0.0,  # Owner-approved proposal: "they do not attack" (the stampede tramples)
		"attack_interval": 2.0,
		"attack_range": 0.0,
		"radius": 22.0,  # TUNING (not in GDD) px (~96 px sprite)
		"armor": 0.15,  # TUNING (not in GDD) thick hide
		"xp": 24,  # Owner-approved proposal: "drop big XP"; TUNING (not in GDD) value
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.1,  # TUNING (not in GDD) 0..1: every threat comes first
		"mass": 6.0,  # TUNING (not in GDD)
		"slow_resist": 0.5,  # TUNING (not in GDD) a giant shrugs off half of a slow
		"faction": FACTION,
		"kit": "longneck",
		"group": "herds",
		"herd": true,  # Owner-approved proposal: Herds
		"fright": 230.0,  # TUNING (not in GDD) px: "when a fight is close"
	},  # The Longneck.
	# A herd beast (owner-approved proposal: "Duckbill | Herd (neutral) |
	# Smaller herd; the crest horn calls the whole herd to run | Same").
	"duckbill": {
		"display_name": "Duckbill",
		"max_hp": 200.0,  # TUNING (not in GDD)
		"move_speed": 48.0,  # TUNING (not in GDD) px/s grazing base
		"damage": 0.0,  # Owner-approved proposal: neutral
		"attack_interval": 2.0,
		"attack_range": 0.0,
		"radius": 16.0,  # TUNING (not in GDD) px (~68 px sprite)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 12,  # TUNING (not in GDD) big XP, smaller beast
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.1,  # TUNING (not in GDD) 0..1
		"mass": 4.0,  # TUNING (not in GDD)
		"slow_resist": 0.3,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "duckbill",
		"group": "herds",
		"herd": true,  # Owner-approved proposal: Herds
		"fright": 320.0,  # Owner-approved proposal: "the crest horn calls the whole herd to run": it hears a fight from farther off; TUNING (not in GDD) px
	},  # The Duckbill.
	# A flier (male), a thief (owner-approved proposal: "Skyraider (male) |
	# Flier, thief | Dives, snatches a pile (Scavengers) | Archers, Gargoyles,
	# spells"). Row "flies": it passes over the Bone Ring; it never bites, so
	# its threat is the economy, not the army.
	"skyraider": {
		"display_name": "Skyraider",
		"max_hp": 34.0,  # TUNING (not in GDD) a flier worth shooting down
		"move_speed": 120.0,  # TUNING (not in GDD) px/s (its circle; the dive and the flight have their own speeds)
		"damage": 0.0,  # Owner-approved proposal: "steal pickups instead of biting"
		"attack_interval": 2.0,
		"attack_range": 0.0,
		"radius": 11.0,  # TUNING (not in GDD) px (~56 px sprite, wings spread)
		"armor": 0.0,
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1; shoot it down
		"mass": 0.6,  # TUNING (not in GDD)
		"flies": true,  # Owner-approved proposal: "Pterosaurs share the flies flag"
		"faction": FACTION,
		"kit": "skyraider",
		"group": "fliers",
		"scavenger": true,  # Owner-approved proposal: Scavengers
	},  # The Skyraider.
	# A titan (female / male; owner-approved proposal: "Tyrant | Miniboss kind
	# | Bite that swallows a summon for 4 s; a roar that stuns the ring 1.2 s |
	# Burst; Bone Wall; the swallowed summon cuts its way out"). Phase 1: the
	# Stampede of Ash's heavy, a plain heavy biter; phase 2 (the Last Day)
	# builds the swallow and the roar in its kit.
	"tyrant": {
		"display_name": "Tyrant",
		"max_hp": 520.0,  # TUNING (not in GDD) a titan
		"move_speed": 52.0,  # TUNING (not in GDD) px/s
		"damage": 16.0,  # TUNING (not in GDD) a bite, before the time scaling
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 20.0,  # TUNING (not in GDD) px (~88 px sprite)
		"armor": 0.25,  # TUNING (not in GDD)
		"xp": 20,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1
		"mass": 5.0,  # TUNING (not in GDD)
		"cleave_radius": 26.0,  # TUNING (not in GDD) px: the bite catches the bodies beside its target
		"cleave_targets": 2,  # TUNING (not in GDD)
		"cleave_mult": 0.5,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "tyrant",
		"group": "titans",
	},  # The Tyrant.
}
