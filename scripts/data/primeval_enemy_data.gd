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
## Phase 2's shared kinds, each stage in its own block:
##   bog_croc      — a hunter (male), the Fern Basin's: an ambusher that lies
##                   submerged in the tar and lunges at the rail of the ring.
##   horncharger   — a titan (male), the Great Plain's: a ceratopsian whose
##                   telegraphed straight charge stuns summons; a charge that
##                   runs into a rock leaves it stuck 2 s.
##   clubtail      — a titan (female), the Great Plain's: an ankylosaur, flat
##                   armour 5, a tail sweep that knocks summons back.
##   stormwing     — a flier elite (female), the Last Day's: a great pterosaur
##                   whose wing gust pushes the Bone Ring 100 px away from the
##                   necromancer; she lands to peck (hit her then).
## The Last Day also gives the TYRANT its swallow and its roar (TyrantKit,
## the row's swallow_* / roar_* keys).
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
##   swims      — true: the Fern Basin's tar and river never slow it.
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
# --- Act XIV (temporary number): the Fern Basin ---
## Kind id of the Bog Croc (the ambusher of the tar; a shared row, the Fern Basin's block).
const BOG_CROC: String = "bog_croc"
# --- Act XIV (temporary number): the Great Plain ---
## Kind id of the Horncharger (the charging ceratopsian; a shared row, the Great Plain's block).
const HORNCHARGER: String = "horncharger"
## Kind id of the Clubtail (the armoured ankylosaur; a shared row, the Great Plain's block).
const CLUBTAIL: String = "clubtail"
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
		"damage": 4.0,  # TUNING (not in GDD) one venom bolt, before the time scaling (balance pass 1: was 5, the top killer of the necromancer; now the plain Archer's 4)
		"attack_interval": 3.2,  # TUNING (not in GDD) s (balance pass 1: was 2.6; a lobbed glob, slower than an arrow)
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
	# Burst; Bone Wall; the swallowed summon cuts its way out"). The Stampede
	# of Ash's heavy; the Last Day built its kit (TyrantKit): THE SWALLOW (every
	# swallow_every s a grounded summon in reach is swallowed: held and stunned
	# swallow_time s inside it, taking swallow_dps a second x the time scaling;
	# the Tyrant losing cut_share of its max HP meanwhile cuts it out early)
	# and THE ROAR (every roar_every s, with a summon within roar_radius px, a
	# roar_windup s telegraph, then every grounded summon within roar_radius
	# px is stunned roar_stun s through CombatResolver.stun_unit()).
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
		"swallow_first": 4.0,  # TUNING (not in GDD) s after it comes on
		"swallow_every": 9.0,  # TUNING (not in GDD) s between two swallows
		"swallow_reach": 30.0,  # TUNING (not in GDD) px edge to edge: a summon this close may be swallowed
		"swallow_time": 4.0,  # Owner-approved proposal: "a summon for 4 s"
		"swallow_dps": 5.0,  # TUNING (not in GDD) damage a second to the swallowed summon, before the time scaling
		"cut_share": 0.12,  # Owner-approved proposal: "the swallowed summon cuts its way out"; TUNING (not in GDD) share of its max HP lost that frees it
		"roar_first": 6.0,  # TUNING (not in GDD) s after it comes on
		"roar_every": 12.0,  # TUNING (not in GDD) s between two roars
		"roar_windup": 0.8,  # TUNING (not in GDD) s of telegraph
		"roar_radius": 110.0,  # TUNING (not in GDD) px round it
		"roar_stun": 1.2,  # Owner-approved proposal: "a roar that stuns the ring 1.2 s"
	},  # The Tyrant.
	# --- Act XIV (temporary number): the Fern Basin ---
	# An ambusher (male; owner-approved proposal: "Bog Croc (male) | Ambush |
	# Hides in tar and river tiles; lunges at the rail of the ring | Wither,
	# Area, avoid the tar"). BogCrocKit: it lies SUBMERGED where it came up
	# (untargetable, only its eyes show) until a summon or a necromancer comes
	# within lunge_reach px (or max_wait s pass: enemies always advance), then
	# EMERGES for emerge_time s (a telegraph) and LUNGES lunge_speed px/s up to
	# lunge_len px at the nearest body (the rail of the ring): the first summon
	# or necromancer it touches takes lunge_damage / lunge_player once (x the
	# time scaling); then the shared melee AI. It swims: the tar never slows it.
	"bog_croc": {
		"display_name": "Bog Croc",
		"max_hp": 130.0,  # TUNING (not in GDD) an ambusher worth an Area spell
		"move_speed": 56.0,  # TUNING (not in GDD) px/s on land
		"damage": 8.0,  # TUNING (not in GDD) a bite, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 14.0,  # TUNING (not in GDD) px (~72 x 30 px sprite)
		"armor": 0.2,  # TUNING (not in GDD) scaled hide
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1
		"mass": 3.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "bog_croc",
		"group": "hunters",
		"swims": true,  # The tar and the river never slow it (FernBasinDirector skips it).
		"lunge_reach": 150.0,  # TUNING (not in GDD) px: a body this close wakes it
		"max_wait": 12.0,  # TUNING (not in GDD) s submerged at most (then it comes up and advances)
		"emerge_time": 0.55,  # TUNING (not in GDD) s of telegraph (it rears out of the pool)
		"lunge_speed": 340.0,  # TUNING (not in GDD) px/s
		"lunge_len": 180.0,  # TUNING (not in GDD) px at most
		"lunge_damage": 11.0,  # TUNING (not in GDD) to the summon it seizes, before the time scaling (first pass 14)
		"lunge_player": 9.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	},  # The Bog Croc.
	# --- Act XIV (temporary number): the Great Plain ---
	# The Horncharger (owner-approved proposal: "Horncharger (male) | Heavy |
	# Telegraphed straight charge that stuns summons; stuck in a rock for 2 s on
	# a miss | Dodge by Grave Step; Bone Wall"): a three-horned ceratopsian. The
	# shared melee AI walks it in; every charge_every s, once a summon or
	# necromancer stands within charge_trigger px, it paws the ground for
	# charge_windup s (a line shows the charge) and CHARGES charge_len px at
	# charge_speed px/s: every grounded summon it crosses takes charge_damage (x
	# the time scaling x Thick Marrow) and is STUNNED charge_stun s
	# (CombatResolver.stun_unit()); the necromancer it crosses takes
	# charge_player. A charge that runs into a rock (an obstacle) leaves it
	# STUCK stuck_time s (the counterplay: Grave Step aside). HornchargerKit.
	"horncharger": {
		"display_name": "Horncharger",
		"max_hp": 200.0,  # TUNING (not in GDD) a heavy (between the Bog Croc and the Tyrant; first pass 240)
		"move_speed": 46.0,  # TUNING (not in GDD) px/s walking
		"damage": 6.0,  # TUNING (not in GDD) a horn in reach, before the time scaling (first passes 9, 7)
		"attack_interval": 1.5,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 16.0,  # TUNING (not in GDD) px (~64 x 48 px sprite)
		"armor": 0.2,  # TUNING (not in GDD) a bone frill
		"xp": 8,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1
		"mass": 8.0,  # TUNING (not in GDD) heavy: the ring does not shove it
		"faction": FACTION,
		"kit": "horncharger",
		"group": "titans",
		"charge_first": 2.5,  # TUNING (not in GDD) s after it comes on
		"charge_every": 9.0,  # TUNING (not in GDD) s between two charges (first pass 7: the naive bot died at 6:49 on seed 7, the Horncharger its top damage)
		"charge_trigger": 260.0,  # TUNING (not in GDD) px: a body this close starts a charge
		"charge_windup": 0.9,  # Owner-approved proposal: "telegraphed"; TUNING (not in GDD) s
		"charge_len": 240.0,  # TUNING (not in GDD) px at most
		"charge_speed": 330.0,  # TUNING (not in GDD) px/s
		"charge_damage": 7.0,  # TUNING (not in GDD) to each summon it crosses, before the time scaling (first pass 9)
		"charge_player": 4.0,  # TUNING (not in GDD) to the necromancer, before the time scaling (first passes 8, 5)
		"charge_stun": 0.6,  # Owner-approved proposal: "stuns summons"; TUNING (not in GDD) s (first passes 1.0, 0.8)
		"charge_knock": 30.0,  # TUNING (not in GDD) px a summon it crosses is thrown aside
		"stuck_time": 2.0,  # Owner-approved proposal: "stuck in a rock for 2 s on a miss"
	},  # The Horncharger.
	# The Clubtail (owner-approved proposal: "Clubtail (female) | Heavy | Flat
	# armour 5; a tail sweep that knocks summons back | Siegecraft, Wither,
	# Rot"): an ankylosaur under armour plates with a bone club on her tail.
	# The shared melee AI walks her in; every sweep_every s, once a summon or
	# necromancer stands within sweep_radius px, she swings for sweep_windup s
	# (a circle shows the sweep) and SWEEPS: every grounded summon within
	# sweep_radius px takes sweep_damage (x the time scaling x Thick Marrow)
	# and is KNOCKED BACK sweep_knock px away from her; the necromancer takes
	# sweep_player. Flat armour (the one path: CombatResolver's flat_armor)
	# shrugs off the first 5 of every hit. ClubtailKit.
	"clubtail": {
		"display_name": "Clubtail",
		"max_hp": 160.0,  # TUNING (not in GDD) a heavy (her flat armour is the rest of her toughness; first pass 200)
		"move_speed": 40.0,  # TUNING (not in GDD) px/s; slow
		"damage": 8.0,  # TUNING (not in GDD) a bite in reach, before the time scaling
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 16.0,  # TUNING (not in GDD) px (~64 x 44 px sprite)
		"armor": 0.15,  # TUNING (not in GDD)
		"flat_armor": 5.0,  # Owner-approved proposal: "flat armour 5"
		"xp": 8,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.65,  # TUNING (not in GDD) 0..1
		"mass": 9.0,  # TUNING (not in GDD) heavy
		"faction": FACTION,
		"kit": "clubtail",
		"group": "titans",
		"sweep_first": 2.0,  # TUNING (not in GDD) s after she comes on
		"sweep_every": 5.0,  # TUNING (not in GDD) s between two sweeps
		"sweep_windup": 0.7,  # TUNING (not in GDD) s of telegraph
		"sweep_radius": 54.0,  # TUNING (not in GDD) px round her
		"sweep_damage": 5.0,  # TUNING (not in GDD) to each summon in reach, before the time scaling (first pass 7: 7.7k on the army bot's summons, seed 7)
		"sweep_player": 5.0,  # TUNING (not in GDD) to the necromancer, before the time scaling (first pass 7)
		"sweep_knock": 40.0,  # Owner-approved proposal: "knocks summons back"; TUNING (not in GDD) px (first pass 60)
	},  # The Clubtail.
	# --- Act XIV (temporary number): the Last Day ---
	# The Stormwing (owner-approved proposal: "Stormwing (female) | Flier elite
	# | Wing gust that pushes the ring 100 px; lands to peck | Hit her at the
	# landing circle"): a great pterosaur (a beast: no figure style). StormwingKit:
	# she CIRCLES hover_radius px from the nearest necromancer over the Bone
	# Ring; every gust_every s she beats her wings for gust_windup s (a circle
	# shows the gust round the necromancer), then the GUST: every grounded
	# summon within gust_radius px of him is pushed gust_push px straight away
	# from him (gust_damage x the time scaling x Thick Marrow); then she LANDS
	# at the ring's edge for land_time s (grounded: every blow lands, blockers
	# hold her) and pecks with the shared melee AI, then takes off again.
	"stormwing": {
		"display_name": "Stormwing",
		"max_hp": 150.0,  # TUNING (not in GDD) a flier elite
		"move_speed": 110.0,  # TUNING (not in GDD) px/s in the air
		"damage": 5.0,  # TUNING (not in GDD) a peck, before the time scaling (first pass 7)
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 14.0,  # TUNING (not in GDD) px (~72 x 44 px sprite)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 8,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1
		"mass": 2.0,  # TUNING (not in GDD)
		"flies": true,  # Owner-approved proposal: "Pterosaurs share the flies flag" (grounded while she lands)
		"faction": FACTION,
		"kit": "stormwing",
		"group": "fliers",
		"hover_radius": 190.0,  # TUNING (not in GDD) px from the necromancer she circles (over the ring)
		"hover_orbit": 0.8,  # TUNING (not in GDD) rad/s
		"gust_first": 4.0,  # TUNING (not in GDD) s after she comes on
		"gust_every": 10.0,  # TUNING (not in GDD) s between two gusts
		"gust_windup": 1.0,  # TUNING (not in GDD) s of telegraph
		"gust_radius": 160.0,  # TUNING (not in GDD) px round the necromancer (the Bone Ring is 60-150 px)
		"gust_push": 100.0,  # Owner-approved proposal: "pushes the ring 100 px"
		"gust_damage": 3.0,  # TUNING (not in GDD) to each summon pushed, before the time scaling
		"land_time": 3.0,  # TUNING (not in GDD) s she stands at the landing circle and pecks
		"land_speed": 220.0,  # TUNING (not in GDD) px/s she swoops down to the landing circle
	},  # The Stormwing.
}
