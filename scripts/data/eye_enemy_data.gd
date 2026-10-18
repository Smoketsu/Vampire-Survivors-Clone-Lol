## EyeEnemyData — immutable design data for the kinds the ANCIENT EYE fields on
## every Act II stage (GDD §15.0 "Act II: the Ancient Eye"; owner-approved
## proposal "The Drowned Choir", faction renamed the Ancient Eye by the owner),
## and the rules of CLAIMS, the act's core idea: the Covenant destroyed your
## dead, the Eye steals them.
##   eye_initiate   — Initiate of the Eye: robed, slow fodder that comes in
##                    big crowds (the Act II Recruit).
##   eye_chanter    — Chanter: the leader of an Initiate squad. A summon that
##                    dies within its claim reach is CLAIMED (EyeClaims).
##   drowned_thrall — a claimed summon, risen hostile for CLAIM.thrall_life s,
##                    wearing that summon's sprite, tinted (EyeThrallKit). It
##                    gives no XP; killing it returns its soul as Dread Rally
##                    charge (CLAIM.thrall_rally_points).
## Each stage's own kinds live in its own file (HarbourEnemyData,
## ArchiveEnemyData, SpireEnemyData); EnemyDirector.enemy_def() looks them up
## after the Act I tables, this file first.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Eye keys:
##   faction       — "eye" (the Codex's Ancient Eye category, the Thrall tint).
##   claim_radius  — px; a summon dying this close to the enemy is claimed
##                   (0 / absent = none).
##   kit           — a CovenantKit id; an Eye kit lives in
##                   scripts/enemies/eye/<kit>_kit.gd (CovenantKits loads it).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name EyeEnemyData
extends RefCounted

## Faction id of the Ancient Eye's kinds (row "faction").
const FACTION: String = "eye"

## Kind id of the Drowned Thrall (EyeClaims spawns it; never in a timeline).
const THRALL: String = "drowned_thrall"

## The Ancient Eye's shared kinds, keyed by kind id.
const ENEMIES := {
	# The Act II Recruit: a little sturdier than a Recruit and a little slower
	# (the act starts above the Sanctum), always in crowds.
	"eye_initiate": {
		"display_name": "Initiate of the Eye",
		"max_hp": 17.0,  # TUNING (not in GDD) Recruit 14
		"move_speed": 52.0,  # TUNING (not in GDD) px/s; "robed and slow" (Recruit 58)
		"damage": 3.0,  # TUNING (not in GDD) Recruit 3; Act II integration: 3.5 made the Initiate swarm the naive bot's top killer on all three stages
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.2,  # TUNING (not in GDD) 0..1, fodder
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
	},
	# Leads an Initiate squad and claims the dead around it. High target
	# priority: the archers and mages should drop it first, which is the
	# counterplay to Claims.
	"eye_chanter": {
		"display_name": "Chanter of the Eye",
		"max_hp": 46.0,  # TUNING (not in GDD) a squad leader (Footman 36)
		"move_speed": 50.0,  # TUNING (not in GDD) px/s; keeps pace with its squad
		"damage": 4.0,  # TUNING (not in GDD)
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; kill it before it claims your dead
		"mass": 1.2,  # TUNING (not in GDD)
		"faction": FACTION,
		"claim_radius": 90.0,  # TUNING (not in GDD) px; about the reach of a squad around it (Act II integration: 120 let a losing army feed the Eye a stream of Thralls)
	},
	# A claimed summon. Its HP, damage and speed are set from the summon it
	# was (EyeClaims, CLAIM below); these are the floors and the rest of the row.
	"drowned_thrall": {
		"display_name": "Drowned Thrall",
		"max_hp": 20.0,  # TUNING (not in GDD) floor; the Thrall takes CLAIM.thrall_hp_mult x the summon's max HP
		"move_speed": 56.0,  # TUNING (not in GDD) px/s floor; CLAIM.thrall_speed_mult x the summon's speed
		"damage": 3.5,  # TUNING (not in GDD) before the enemy time scaling, like every foe's
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge (every Thrall fights in melee)
		"radius": 10.0,  # TUNING (not in GDD) px; replaced by the summon's own body radius
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 0,  # Your own dead give no XP (no farming).
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1; worth freeing early
		"mass": 1.2,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "thrall",
	},
}

## Claims (EyeClaims; on when the stage's "claims" key is true). A summon that
## dies within a claimer's reach (an enemy with a claim_radius, or one a Scribe
## has marked: Enemy.claimer_until, reach curse_radius) rises as a Thrall: its
## HP from the summon, its hit damage from the Thrall row (time-scaled like
## every foe's: a late Death Knight does not come back hitting like one).
##   thrall_life          — s a Thrall stays risen before its soul slips back
##                          (it leaves without a kill: no XP, no Rally charge).
##   thrall_hp_mult       — Thrall max HP = this x the summon's max HP (before
##                          the enemy time scaling, which it does not get).
##   thrall_speed_mult    — Thrall move speed = this x the summon's move speed.
##   curse_radius         — px reach of a marked (cursed) cultist's claim.
##   query_radius         — px searched around a fallen summon for claimers
##                          (at least the largest claim reach).
##   thrall_rally_points  — Dread Rally soul points when a Thrall is killed
##                          ("its soul comes back"; a regular kill is 1).
##   max_thralls          — most Thralls risen at once (a wiped army cannot
##                          flood the field with itself).
##   temporary_claimable  — whether temporary summons (Risen, Legion,
##                          reinforcements) can be claimed.
##   tint                 — colour multiplied over the summon's sprite.
##   rise_color           — colour of the rising burst.
const CLAIM := {
	"thrall_life": 15.0,  # TUNING (not in GDD) owner-approved proposal "rises for 15 s"
	"thrall_hp_mult": 0.6,  # TUNING (not in GDD) a weakened copy
	"thrall_speed_mult": 0.75,  # TUNING (not in GDD) shambling: the army can catch it
	"curse_radius": 90.0,  # TUNING (not in GDD) px
	"query_radius": 160.0,  # TUNING (not in GDD) px; >= every claim_radius
	"thrall_rally_points": 4.0,  # TUNING (not in GDD) an elite's worth of soul
	"max_thralls": 5,  # TUNING (not in GDD) Act II integration: 8 let a weak army snowball into defeat (the Archive's seed 7, the naive bot everywhere)
	"temporary_claimable": false,  # TUNING (not in GDD) only your real army is fought over
	"tint": Color(0.45, 0.85, 0.78),  # TUNING (not in GDD) drowned teal (EyePalette)
	"rise_color": Color(0.30, 0.75, 0.68),  # TUNING (not in GDD) drowned teal
}
