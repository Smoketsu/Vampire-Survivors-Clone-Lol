## DynastyEnemyData — immutable design data for the kinds THE NECROPOLIS
## DYNASTY fields on every one of its stages (temporary Act XII, final slot
## VII; GDD §15.0 "The Necropolis Dynasty foundation (phase 1)"; proposal
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 3, "Roster"). The oldest empire of
## the dead: every mummy belongs to a god by name, and its priests, guardians
## and gods come to take their dead back. The shared kinds of phase 1 (every
## one used by a rule):
##   mummy          — the wrapped dead (male): slow fodder; REBIRTH; fire
##                    (the mages, burns, the plague) does x1.5.
##   mummy_female   — the wrapped dead (female, figure style): the same, a
##                    faster walker.
##   scarab_swarm   — a sacred beast: a fast swarm of beetles whose bites tear
##                    a summon's barrier; no Rebirth (beasts do not return).
##   khopesh_guard  — the guard (male): a soldier with curved blades and a
##                    telegraphed spinning slash; REBIRTH.
##   heka_priest    — the priesthood (male): writes a HEKA glyph on a summon
##                    (DynastyRules' Heka; a casting circle at his feet).
##   embalmer       — the priesthood (female, figure style): heals soldiers
##                    (the existing enemy-heal path) and hastens every
##                    cartouche near her (REBIRTH: x2, "the timer -3 s").
##   canopic_jar    — a STRUCTURE: holds the Names of every body within 300 px
##                    (REBIRTH: their cartouches cannot be smashed); break it
##                    and its bodies return no more.
##   cartouche      — a 1-hit STRUCTURE row: the gold Name over a fallen
##                    mummy or guardian (Rebirth lays it; the rule's one
##                    object). Not a roster kind: no Codex entry.
## The Reckoning, the Devourer's Hour, has no kind of its own: its heavy is the
## khopesh guard (RECKONING_KIND) with the shared kinds as companions.
## The Necropolis of Sand's block at the end of ENEMIES adds two shared kinds:
##   nile_archer    — the guard (female, figure style): a ranged archer the
##                    Sandstorm silences ("storm_silenced"); no Rebirth.
##   jackal_warrior — the guard (male, jackal-headed): an ELITE in pairs, a
##                    telegraphed lunge (JackalWarriorKit); REBIRTH.
## Each stage's own kinds live in its own file (NecropolisEnemyData,
## LionessTempleEnemyData, TwoTruthsEnemyData; empty until phase 2: the Nile
## Archer, the Jackal Warrior, the Bastet Hunter, the Crocodile Warden, the
## Ushabti Statue, the Sand Colossus, the stage minibosses and the bosses'
## allies); EnemyDirector.enemy_def() looks them up through dynasty_def(),
## this file first, after the Concord's tables.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Dynasty keys (absent = off):
##   faction       — "dynasty" (the Codex's Dynasty tab, the reports).
##   kit           — a CovenantKit id; a Dynasty kit lives in
##                   scripts/enemies/dynasty/<kit>_kit.gd (CovenantKits loads
##                   it by name after the Concord's folder, so kit ids must be
##                   unique across the nine folders). Every Dynasty kind has
##                   one (a DynastyKit).
##   group         — String, one of DynastyRulesData.GROUPS (the Codex and the
##                   report group by it).
##   rebirth       — bool: a fallen body gets a cartouche and may RETURN
##                   (Rebirth). Mummies and guardians only (proposal: "scarabs
##                   and animals do not return").
##   fire_taken    — x a hit tagged with a DynastyRulesData.FIRE_SOURCES
##                   source (DynastyKit.taken_mult()); absent = 1.
##   embalms       — bool: hastens every cartouche within REBIRTH
##                   embalm_radius (x embalm_speed).
##   holds_names   — bool: a Canopic Jar (Rebirth: the cartouches within
##                   REBIRTH jar_radius are sealed while it stands).
##   storm_silenced — bool: it does not shoot while the Sandstorm blows
##                   (phase 2's Nile Archer: "silenced by sandstorms").
##   heka          — Dictionary: the priest's glyph: every (s) between two
##                   writings, range (px to a summon), windup (s of casting).
##   spin          — Dictionary: the khopesh guard's spinning slash: every,
##                   windup (s), radius (px), damage (per body, before the
##                   time scaling).
##   barrier_gnaw  — barrier HP a bite tears off a summon on top of the bite
##                   (before the time scaling; the scarabs).
##   fodder        — true: fodder (reports).
##   figure        — true: a figure-style woman (the art pass's bust rig; no
##                   rule reads it).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal. Tuned for the act's FINAL slot VII (between
## the Shogunate and Olympus), not its temporary number.
class_name DynastyEnemyData
extends RefCounted

## Faction id of the Dynasty's kinds (row "faction").
const FACTION: String = DynastyRulesData.FACTION
## Kind id of the male mummy.
const MUMMY: String = "mummy"
## Kind id of the female mummy.
const MUMMY_FEMALE: String = "mummy_female"
## Kind id of the scarab swarm.
const SCARAB_SWARM: String = "scarab_swarm"
## Kind id of the khopesh guard.
const KHOPESH_GUARD: String = "khopesh_guard"
## Kind id of the Heka priest.
const HEKA_PRIEST: String = "heka_priest"
## Kind id of the Embalmer.
const EMBALMER: String = "embalmer"
## Kind id of the Canopic Jar (a structure row).
const CANOPIC_JAR: String = "canopic_jar"
## Kind id of the cartouche (a 1-hit structure row; Rebirth lays it).
const CARTOUCHE: String = DynastyRulesData.CARTOUCHE
## Sprite folder of the Dynasty's kinds (assets/sprites/dynasty/).
const SPRITE_DIR: String = "dynasty/"
# --- Act XII (temporary number): the Temple of the Lioness ---
## Kind id of the Bastet Hunter (a shared elite row; the Temple fields it first).
const BASTET_HUNTER: String = "bastet_hunter"
## Kind id of the Ushabti Statue (a shared heavy row; the Temple's statues wake as it).
const USHABTI_STATUE: String = "ushabti_statue"

## The Devourer's Hour's heavy (the RECKONING "kind" of every Dynasty stage):
## the guard of the opened tombs.
const RECKONING_KIND: String = KHOPESH_GUARD
## The Devourer's Hour's companions (the RECKONING "companions" of every
## Dynasty stage: "every sarcophagus in the necropolis opens").
const RECKONING_COMPANIONS: Array = [
	{"kind": MUMMY, "count": 8, "growth": 2.0},  # TUNING (not in GDD)
	{"kind": MUMMY_FEMALE, "count": 6, "growth": 1.5},  # TUNING (not in GDD)
	{"kind": SCARAB_SWARM, "count": 3, "growth": 1.0},  # TUNING (not in GDD)
	{"kind": HEKA_PRIEST, "count": 1, "growth": 0.34},  # TUNING (not in GDD) the glyphs never stop
]

## The Dynasty's shared kinds, keyed by kind id.
const ENEMIES := {
	# The wrapped dead (male): slow fodder that RETURNS (Rebirth); fire does
	# x1.5 (owner-approved proposal: "Slow, wrapped, Rebirth; fire (Rot burn,
	# Mages) does x1.5 | Raise it; area damage").
	"mummy": {
		"display_name": "Mummy",
		"max_hp": 20.0,  # TUNING (not in GDD) fodder, a little tougher than an ashigaru (13): it is slow
		"move_speed": 40.0,  # TUNING (not in GDD) px/s; slow
		"damage": 3.5,  # TUNING (not in GDD) a wrapped fist, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px (~40 px sprite)
		"armor": 0.05,  # TUNING (not in GDD) linen
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD) 0..1, fodder
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "mummy",
		"group": "dead",
		"rebirth": true,  # Owner-approved proposal: Rebirth
		"fire_taken": 1.5,  # Owner-approved proposal: fire does x1.5
		"fodder": true,
	},  # The mummy (male).
	# The wrapped dead (female, figure style): the same, a faster walker
	# (owner-approved proposal: "Same, a faster walker").
	"mummy_female": {
		"display_name": "Mummy",
		"max_hp": 16.0,  # TUNING (not in GDD) fodder
		"move_speed": 54.0,  # TUNING (not in GDD) px/s; "a faster walker"
		"damage": 3.0,  # TUNING (not in GDD) before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 8.0,  # TUNING (not in GDD) px (~40 px sprite)
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "mummy_female",
		"group": "dead",
		"rebirth": true,  # Owner-approved proposal: "Same"
		"fire_taken": 1.5,  # Owner-approved proposal: "Same"
		"fodder": true,
		"figure": true,  # Owner rule: every female kind in the figure-redesign style
	},  # The mummy (female).
	# A sacred beast: a fast swarm of beetles that gnaws a summon's barrier
	# (owner-approved proposal: "12 beetles, fast, gnaw a summon's barrier or
	# Orb Shield; no Rebirth | Area damage; Warders recast barriers"). One body
	# is one swarm; they come several swarms at once.
	"scarab_swarm": {
		"display_name": "Scarab Swarm",
		"max_hp": 11.0,  # TUNING (not in GDD) fodder, frail
		"move_speed": 86.0,  # TUNING (not in GDD) px/s; fast
		"damage": 1.5,  # TUNING (not in GDD) a bite, before the time scaling
		"attack_interval": 0.7,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 8.0,  # TUNING (not in GDD) px (~30 px sprite)
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
		"kit": "scarab_swarm",
		"group": "beasts",
		"barrier_gnaw": 4.0,  # TUNING (not in GDD) barrier HP a bite tears off on top of the bite
		"fodder": true,
	},  # The scarab swarm.
	# The guard (male): curved blades and a telegraphed spinning slash that
	# hits every body around him; RETURNS (owner-approved proposal: "Curved
	# blades, a spinning slash; Rebirth | Raise it").
	"khopesh_guard": {
		"display_name": "Khopesh Guard",
		"max_hp": 44.0,  # TUNING (not in GDD) a soldier (Samurai 42)
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 6.0,  # TUNING (not in GDD) a blade cut, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px (~46 px sprite)
		"armor": 0.2,  # TUNING (not in GDD) bronze scales
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.55,  # TUNING (not in GDD) 0..1
		"mass": 1.4,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "khopesh_guard",
		"group": "guard",
		"rebirth": true,  # Owner-approved proposal: Rebirth
		"spin": {
			"every": 6.5,  # TUNING (not in GDD) s between two spins
			"windup": 0.55,  # TUNING (not in GDD) s of telegraph
			"radius": 44.0,  # TUNING (not in GDD) px
			"damage": 8.0,  # TUNING (not in GDD) per body, before the time scaling
		},
	},  # The khopesh guard.
	# The priesthood (male): writes the Heka glyph on a summon from range, a
	# casting circle at his feet (owner-approved proposal: "Writes the glyph;
	# casting circle on his feet | Priority target; Gargoyles"). A support:
	# the enemy-heal behaviour with no heal (he walks in with the column and
	# swings weakly in contact).
	"heka_priest": {
		"display_name": "Heka Priest",
		"max_hp": 34.0,  # TUNING (not in GDD) a support
		"move_speed": 42.0,  # TUNING (not in GDD) px/s
		"damage": 2.0,  # TUNING (not in GDD) a staff swing in contact
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px (~46 px sprite)
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "healer",  # The support walk; he heals nothing (heal_amount 0).
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; "priority target"
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "heka_priest",
		"group": "priests",
		"heka": {
			"every": 7.0,  # TUNING (not in GDD) s between two glyphs (one of his at a time)
			"range": 210.0,  # TUNING (not in GDD) px to the summon he writes on
			"windup": 0.8,  # TUNING (not in GDD) s of casting (the circle at his feet)
		},
	},  # The Heka priest.
	# The priesthood (female, figure style): heals soldiers near her through
	# the existing enemy-heal path and hastens every cartouche near her
	# (owner-approved proposal: "Wraps the fallen: the cartouche timer -3 s
	# nearby and heals soldiers | Priority target").
	"embalmer": {
		"display_name": "Embalmer",
		"max_hp": 38.0,  # TUNING (not in GDD) a support
		"move_speed": 44.0,  # TUNING (not in GDD) px/s
		"damage": 2.0,  # TUNING (not in GDD) a weak swing
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px (~44 px sprite)
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "healer",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 10.0,  # TUNING (not in GDD) HP a heal
		"heal_interval": 2.6,  # TUNING (not in GDD) s
		"heal_radius": 120.0,  # TUNING (not in GDD) px
		"heal_stat": "embalmer_heals",  # The stat her heals count in (Enemy.heal_stat).
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; "priority target"
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "embalmer",
		"group": "priests",
		"embalms": true,  # Owner-approved proposal: the cartouche timer -3 s nearby
		"figure": true,  # Owner rule: every female kind in the figure-redesign style
	},  # The Embalmer.
	# A structure: the Canopic Jar holds the Names of every body within 300 px
	# (owner-approved proposal: "Holds the Names within 300 px | Break it").
	# Rebirth seals the cartouches it holds (they cannot be smashed); broken,
	# its bodies return no more.
	"canopic_jar": {
		"display_name": "Canopic Jar",
		"max_hp": 120.0,  # TUNING (not in GDD)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 11.0,  # TUNING (not in GDD) px (~30 px sprite)
		"armor": 0.1,  # TUNING (not in GDD) fired clay and stone
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1; break the jars
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": FACTION,
		"kit": "canopic_jar",
		"group": "stone",
		"holds_names": true,  # Owner-approved proposal
	},  # The Canopic Jar.
	# The CARTOUCHE (owner-approved proposal: "a gold cartouche floats over the
	# corpse for 6 s. If it is not raised in that time, or smashed (one hit from
	# any source), the body returns"). A 1-hit structure Rebirth lays over the
	# corpse; CartoucheKit counts it down and returns the body; any hit that
	# reaches it smashes it (no kill, no XP: CombatResolver asks
	# Rebirth.smash() before the kill path). Drawn in the dull bronze-gold.
	"cartouche": {
		"display_name": "Cartouche",
		"max_hp": 1.0,  # Set to DynastyRulesData.CARTOUCHE_HP at activation, whatever the scalings.
		"move_speed": 0.0,
		"damage": 0.0,  # It never attacks.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 7.0,  # TUNING (not in GDD) px (the wrapped body under the Name)
		"armor": 0.0,
		"xp": 0,  # No XP: the body already gave its own.
		"behavior": "structure",  # It never moves.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.45,  # TUNING (not in GDD) 0..1; worth a blow before it returns
		"mass": 60.0,  # Immovable.
		"is_structure": true,  # No corpse, no knockback.
		"faction": FACTION,
		"kit": "cartouche",
	},  # The cartouche.
	# --- Act XII (temporary number): the Necropolis of Sand ---
	# The guard (female, figure style): a Nile Archer of the tombs' watch, a
	# linen dress and a recurve bow (owner-approved proposal: "Arrows;
	# silenced by sandstorms | Kill early; wait out the storm"). The shared
	# hostile shot ("ranged"); DynastyKit halves her reach while the Sandstorm
	# blows and her row's "storm_silenced" holds her shot then. No Rebirth: she
	# is the living guard of the dead, not one of them (proposal: "mummies and
	# guardians only" return; she is neither wrapped nor a tomb guardian).
	"nile_archer": {
		"display_name": "Nile Archer",
		"max_hp": 24.0,  # TUNING (not in GDD) ranged (Teppo Gunner 26)
		"move_speed": 46.0,  # TUNING (not in GDD) px/s
		"damage": 4.5,  # TUNING (not in GDD) one arrow, before the time scaling (first pass 6: her arrows were 60% of the seed-7 army run's damage to the necromancer)
		"attack_interval": 2.8,  # TUNING (not in GDD) s (first pass 2.4)
		"attack_range": 260.0,  # TUNING (not in GDD) px (x0.5 while the Sandstorm blows, and silent then)
		"radius": 8.0,  # TUNING (not in GDD) px (~44 px sprite)
		"armor": 0.05,  # TUNING (not in GDD) linen
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 390.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1; "kill early"
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "nile_archer",
		"group": "guard",
		"storm_silenced": true,  # Owner-approved proposal: "silenced by sandstorms"
		"figure": true,  # Owner rule: every female kind in the figure-redesign style
	},  # The Nile Archer.
	# The guard (male, jackal-headed): an ELITE tomb guardian with a spear who
	# hunts in packs of two (the timeline sends them in pairs) and LUNGES
	# (JackalWarriorKit: a telegraphed leap onto his target, the werewolf's
	# model without the turning); RETURNS (owner-approved proposal: "Fast
	# lunge; Rebirth; pack of two | Blockers; raise it").
	"jackal_warrior": {
		"display_name": "Jackal Warrior",
		"max_hp": 96.0,  # TUNING (not in GDD) an elite (Kunoichi 64, Werewolf beast 90): its numbers are final
		"move_speed": 72.0,  # TUNING (not in GDD) px/s; fast
		"damage": 7.0,  # TUNING (not in GDD) a spear thrust, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px (a spear)
		"radius": 11.0,  # TUNING (not in GDD) px (~48 px sprite)
		"armor": 0.15,  # TUNING (not in GDD) bronze scale
		"xp": 7,  # TUNING (not in GDD) an elite's XP
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1
		"mass": 1.8,  # TUNING (not in GDD)
		"always_elite": true,  # Owner-approved proposal: "Jackal Warrior | Elite"
		"faction": FACTION,
		"kit": "jackal_warrior",
		"group": "guard",
		"rebirth": true,  # Owner-approved proposal: Rebirth
		# The lunge (JackalWarriorKit): when its target is lunge_min..
		# lunge_trigger px away (edge to edge) and the lunge is ready, it
		# crouches lunge_windup s (a bronze line to where it lands; the army
		# bot steps off it), leaps there in lunge_time s and strikes its target
		# for lunge_damage (x the time scaling and its own hit multiplier) if
		# it is still within reach. Every lunge_every s.
		"lunge": {
			"every": 5.0,  # TUNING (not in GDD) s
			"windup": 0.45,  # TUNING (not in GDD) s
			"time": 0.22,  # TUNING (not in GDD) s in the air
			"min": 28.0,  # TUNING (not in GDD) px
			"trigger": 140.0,  # TUNING (not in GDD) px
			"damage": 9.0,  # TUNING (not in GDD) before the time scaling
		},
	},  # The Jackal Warrior.
	# --- Act XII (temporary number): the Temple of the Lioness ---
	# The BASTET HUNTER (female, figure style, cat-masked; owner-approved
	# proposal: "Elite | A fast duellist; vanishes into the sand and ambushes a
	# ranged summon | Area damage reveals her"). Elite tier by her numbers.
	# BastetHunterKit: in the sand she runs under the ring at the nearest
	# ranged summon (hits on her cut, a spell hit reveals her), bursts out and
	# strikes it with both daggers, duels, then dives again. No Rebirth (a
	# hunter of the living goddess, not one of the wrapped dead).
	"bastet_hunter": {
		"display_name": "Bastet Hunter",
		"max_hp": 80.0,  # TUNING (not in GDD) an elite (the Vrask Hunter 70)
		"move_speed": 82.0,  # TUNING (not in GDD) px/s; "a fast duellist"
		"damage": 5.0,  # TUNING (not in GDD) a dagger in the duel, before the time scaling
		"attack_interval": 0.8,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px (~44 px sprite)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD) an elite
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "bastet_hunter",
		"group": "guard",  # A temple duellist (the Codex's guard)
		"figure": true,  # Owner rule: every female kind in the figure-redesign style
		"stalk": {
			"speed_mult": 1.4,  # TUNING (not in GDD) x her speed in the sand
			"prey_reach": 640.0,  # TUNING (not in GDD) px: the ranged summon she hunts is within this of her
			"ranged_reach": 60.0,  # TUNING (not in GDD) px: a summon whose attack range is at least this is "ranged"
			"strike_reach": 26.0,  # TUNING (not in GDD) px edge to edge: she bursts out this near her prey
			"strike_radius": 30.0,  # TUNING (not in GDD) px of the ambush circle
			"windup": 0.35,  # TUNING (not in GDD) s of the burst (the circle shows)
			"damage": 12.0,  # TUNING (not in GDD) to the ambushed summon, before the time scaling (first pass 22: Bastet killed ~300 summons in the seed-7 army run)
			"damage_player": 8.0,  # TUNING (not in GDD) to a necromancer in the circle, before the time scaling
			"hidden_taken": 0.5,  # TUNING (not in GDD) share of a non-spell hit she takes in the sand
			"duel_time": 7.0,  # TUNING (not in GDD) s of the duel after an ambush or a reveal
			"vanish_every": 12.0,  # TUNING (not in GDD) s of each later duel before she dives again (first pass 7)
		},
	},  # The Bastet Hunter.
	# The USHABTI STATUE (a stone servant, no sex; owner-approved proposal:
	# "Heavy | A stone servant; wakes from an alcove; no Rebirth; armour 5 |
	# Siegecraft"). On the Temple the Awakening Statues wake it out of a
	# statue row (LionessTempleDirector); UshabtiStatueKit adds nothing to the
	# shared walk. Flat armour 5 (the existing path in
	# CombatResolver.damage_enemy()); no Rebirth (stone does not return).
	"ushabti_statue": {
		"display_name": "Ushabti Statue",
		"max_hp": 90.0,  # TUNING (not in GDD) a heavy (the khopesh guard 44)
		"move_speed": 34.0,  # TUNING (not in GDD) px/s; slow stone
		"damage": 8.0,  # TUNING (not in GDD) a stone fist, before the time scaling
		"attack_interval": 1.5,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px (~46 px sprite, 20 wide)
		"armor": 0.1,  # TUNING (not in GDD)
		"flat_armor": 5.0,  # Owner-approved proposal: "armour 5" (flat, as the Sanctified Sentinel's 6)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.55,  # TUNING (not in GDD) 0..1
		"mass": 3.0,  # TUNING (not in GDD) stone
		"faction": FACTION,
		"kit": "ushabti_statue",
		"group": "stone",
	},  # The Ushabti Statue.
}

# --- Act XII (temporary number): the Necropolis of Sand ---
## Kind id of the Nile Archer (female, figure style; ranged, silenced by the storm).
const NILE_ARCHER: String = "nile_archer"
## Kind id of the Jackal Warrior (male, jackal-headed; elite, lunges, returns).
const JACKAL_WARRIOR: String = "jackal_warrior"
## Damage tag of the Jackal Warrior's lunge (stats, the death line).
const LUNGE_SOURCE: String = "jackal_lunge"
