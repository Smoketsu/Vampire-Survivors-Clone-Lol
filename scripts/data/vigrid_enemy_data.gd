## VigridEnemyData — immutable design data for the Norse kinds that join on
## Vigrid, the Last Field (Stage 18 in the final order; the Hall of the Slain,
## temporarily Act XI, final slot VI; GDD §15.0 "The Hall of the Slain
## foundation (phase 1)" and "Vigrid, the Last Field (phase 2)"; the act's
## section "Stage 18: Vigrid, the Last Field" of docs/proposals/LAST_SIX_ACTS.md).
## EnemyDirector.norse_def() looks these rows up after NorseEnemyData. Three
## kinds, each with its own NorseKit:
##   muspel_giant — the MINIBOSS, a Fire-Giant of the south (male; the art
##                  pass's norse/fire_giant sprite, hotter): the shared
##                  fire-giant's stomp (FireGiantKit), and BURNING TRACKS: every
##                  track_every s while he walks he leaves a burning patch on the
##                  ground behind him (EnemyDirector.province_hazards()
##                  .add_fire(), THE pooled enemy fire path: it burns the
##                  necromancer and the summons, never the enemies); his stomp
##                  sets the ground burning around him too (MuspelGiantKit).
##   fenrir       — FENRIR, the great wolf (a beast; Odin's companion in the
##                  boss fight, BossOdin, shown on the HUD's miniboss bar): he
##                  hunts the ring and SWALLOWS a summon whole (an enemy hold
##                  through the existing hooks: SummonedUnit.held_until renewed
##                  each tick, one CombatResolver.stun_unit(), out of reach
##                  inside him), spitting it out swallow_hold s later, hurt
##                  (FenrirKit). Spawned only by
##                  BossOdin (or --spawn=fenrir: then he hunts alone).
##   odin_raven   — ODIN'S RAVENS (Huginn and Muninn; birds): fliers that make
##                  for the necromancer and MARK him on touch (BossOdin
##                  .mark_player(): his next Gungnir is thrown at the
##                  necromancer himself); a raven killed on the way marks
##                  nobody (OdinRavenKit). Sent by BossOdin in pairs.
## Rows have every key of a NorseEnemyData.ENEMIES row (same meaning; "kit" ids
## load scripts/enemies/norse/<kit>_kit.gd, unique across every kit folder;
## none here is a "warrior": Berserkergang drives none of them). The GDD gives
## no numbers: everything is TUNING (not in GDD), tuned for the act's final
## slot VI (the Shogunate / Olympus level).
class_name VigridEnemyData
extends RefCounted

## Kind id of the miniboss, the Fire-Giant of the south.
const MUSPEL_GIANT: String = "muspel_giant"
## Kind id of Fenrir (Odin's wolf).
const FENRIR: String = "fenrir"
## Kind id of Odin's ravens.
const RAVEN: String = "odin_raven"
## Sprite key the miniboss wears (the art pass's fire-giant of the south,
## norse/fire_giant, with its walk strip; MuspelGiantKit draws it).
const MUSPEL_SPRITE: String = "norse/fire_giant"
## Sprite key of a raven (a still; OdinRavenKit spins it as it flies).
const RAVEN_SPRITE: String = "norse/raven"
## Damage tag of the miniboss's burning tracks and burning stomp ground.
const TRACK_SOURCE: String = "muspel_tracks"
## Damage tag of Fenrir's maw (the summon he spits out).
const MAW_SOURCE: String = "fenrir_maw"
## Damage tag of Fenrir's lunge (the bite that swallows, or a bite on the
## necromancer when no summon is in reach).
const LUNGE_SOURCE: String = "fenrir_lunge"

## Kind id -> design row.
const ENEMIES := {
	# The Fire-Giant of the south (see the header): Vigrid's miniboss, in the
	# Giants' March (the "muspel_giant" timeline event, VigridDirector).
	"muspel_giant": {
		"display_name": "Fire-Giant of the South",
		"max_hp": 2400.0,  # TUNING (not in GDD) a miniboss (Warbeast 2,100, Mammoth 2,200; x the stage and time scaling)
		"move_speed": 40.0,  # TUNING (not in GDD) px/s; a heavy stride
		"damage": 12.0,  # TUNING (not in GDD) a blow of his burning blade, before the time scaling
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 18.0,  # TUNING (not in GDD) px
		"radius": 22.0,  # TUNING (not in GDD) px (x 1.35 as an elite = 29.7; the 80 px sprite)
		"armor": 0.2,  # TUNING (not in GDD) iron and cinders
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1
		"mass": 40.0,  # TUNING (not in GDD) heavy
		"slow_resist": 0.6,  # TUNING (not in GDD) like a miniboss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"faction": NorseEnemyData.FACTION,
		"kit": "muspel_giant",
		"group": "wilds",
		"stomp_every": 5.5,  # TUNING (not in GDD) s (the shared fire-giant's stomp, FireGiantKit)
		"stomp_radius": 72.0,  # TUNING (not in GDD) px
		"stomp_windup": 0.8,  # TUNING (not in GDD) s
		"stomp_damage": 9.0,  # TUNING (not in GDD) before the time scaling
		"stomp_push": 34.0,  # TUNING (not in GDD) px
		"track_every": 0.7,  # TUNING (not in GDD) s between two burning footprints while he walks
		"track_min_step": 18.0,  # TUNING (not in GDD) px he must have moved since the last footprint
		"track_radius": 24.0,  # TUNING (not in GDD) px of a footprint's fire
		"track_life": 6.0,  # TUNING (not in GDD) s a footprint burns
		"track_tick": 0.5,  # TUNING (not in GDD) s between two burns
		"track_dmg_player": 1.6,  # TUNING (not in GDD) per burn on the necromancer, before the time scaling
		"track_dmg_summon": 2.4,  # TUNING (not in GDD) per burn on a summon, before the time scaling
		"stomp_fire_radius": 54.0,  # TUNING (not in GDD) px: the ground his stomp sets burning
		"stomp_fire_life": 4.0,  # TUNING (not in GDD) s
		"reward_xp": 280,  # TUNING (not in GDD) a miniboss (Warbeast 260)
		"reward_crystals": 12,  # TUNING (not in GDD)
	},  # The Fire-Giant of the south (Vigrid).
	# Fenrir (see the header): BossOdin brings him; his HP is set by the boss
	# (this row's max_hp x the boss's HP scaling), shown on the miniboss bar.
	"fenrir": {
		"display_name": "Fenrir",
		"max_hp": 8500.0,  # TUNING (not in GDD) a --spawn=fenrir alone (BossOdin sets his HP from OdinData "fenrir_hp")
		"move_speed": 74.0,  # TUNING (not in GDD) px/s; the great wolf runs the ring down
		"damage": 10.0,  # TUNING (not in GDD) a bite in reach, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 26.0,  # TUNING (not in GDD) px (the 100 px long sprite)
		"armor": 0.15,  # TUNING (not in GDD) a hide of black fur
		"xp": 0,  # The boss's burst pays the fight.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1
		"mass": 60.0,  # TUNING (not in GDD) the ring barely slows him
		"slow_resist": 0.7,  # TUNING (not in GDD) like a boss
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, never recycled, the chest).
		"faction": NorseEnemyData.FACTION,
		"kit": "fenrir",
		"group": "wilds",
		"swallow_first": 4.0,  # TUNING (not in GDD) s after he is loosed
		"swallow_every": 9.0,  # TUNING (not in GDD) s
		"swallow_every_ragnarok": 7.0,  # TUNING (not in GDD) s in Ragnarok
		"swallow_reach": 220.0,  # TUNING (not in GDD) px edge to edge: a summon this close may be swallowed
		"swallow_windup": 0.7,  # TUNING (not in GDD) s (a line to his prey)
		"swallow_time": 0.35,  # TUNING (not in GDD) s of the lunge
		"swallow_hold": 4.0,  # Owner-approved proposal: "spits it out 4 s later"
		"spit_share": 0.18,  # TUNING (not in GDD) share of its max HP a summon loses when he spits it out
		"spit_dist": 80.0,  # TUNING (not in GDD) px he spits it out in front of him
		"lunge_damage_player": 9.0,  # TUNING (not in GDD) a lunge that finds the necromancer, before the time scaling
	},  # Fenrir (Vigrid, Odin's wolf).
	# Odin's ravens (see the header): sent in pairs by BossOdin.
	"odin_raven": {
		"display_name": "Raven of Odin",
		"max_hp": 26.0,  # TUNING (not in GDD) a bird (x the time scaling): a volley or a spell brings it down
		"move_speed": 150.0,  # TUNING (not in GDD) px/s; fast on the wing
		"damage": 0.0,  # It only marks.
		"attack_interval": 9.0,
		"attack_range": 0.0,
		"radius": 6.0,  # TUNING (not in GDD) px (the 18 px sprite)
		"armor": 0.0,
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.4,  # TUNING (not in GDD) 0..1
		"mass": 0.3,  # TUNING (not in GDD)
		"faction": NorseEnemyData.FACTION,
		"kit": "odin_raven",
		"group": "hall",
		"flies": true,  # The Night Wings test (Enemy.flies; over obstacles).
		"phases": true,  # It flies over the obstacles.
		"flight_melee_taken": 0.5,  # TUNING (not in GDD) a grounded blow still clips a low bird
		"mark_reach": 14.0,  # TUNING (not in GDD) px edge to edge: it marks the necromancer this close
		"mark_time": 9.0,  # TUNING (not in GDD) s the mark lasts (BossOdin reads it)
		"life": 14.0,  # TUNING (not in GDD) s before it flies home unmarked
	},  # A raven of Odin (Vigrid).
}
