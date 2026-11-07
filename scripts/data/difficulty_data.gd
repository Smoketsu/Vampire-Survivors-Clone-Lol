## DifficultyData — designer-tunable data for the four DIFFICULTY LEVELS of
## GDD §8.4 (Initiate "easier scaling", Necromancer "standard", Lich
## "increased HP / aggression", Deathlord "hardest, with more elites"). The
## GDD names them but gives no numbers (open question 37), so every number
## here is TUNING. No logic here: DifficultyModifiers (the one difficulty
## path) reads it, and the pre-run setup screen (PreRunSetup) shows it.
##
## The chosen level lives in RunConfig.difficulty_id. NECROMANCER is the
## current game: every multiplier is exactly 1 and every chance 0, so a
## Necromancer run with no run modifiers plays bit-for-bit like before
## difficulty levels existed.
##
## Keys of a level row (multipliers are x; 1 = unchanged):
##   display_name     UI name (GDD §8.4 name).
##   tagline          short UI line (GDD §8.4 "Effect" column, expanded).
##   enemy_hp         x enemy max HP (time-scaled soldiers and the Reckoning),
##                    on top of the time scaling.
##   hp_scaling       x the GROWTH part of the enemy HP time scaling
##                    (WaveData: HP x (1 + hp_scaling * (0.10 m + 0.013 m^2))).
##                    Below 1 = "easier scaling" (GDD §8.4 Initiate).
##   enemy_damage     x every enemy hit (applied through EnemyDirector.damage_mult).
##   damage_scaling   x the GROWTH part of the enemy damage time scaling.
##   enemy_spawn      x the trickle spawn rate and the segment soft cap
##                    (max_alive); WaveData.HARD_CAP still applies.
##   enemy_speed      x enemy move speed ("aggression": they close faster).
##                    Not the stage boss (its kit has its own pacing).
##   elite_chance     chance 0..1 that a trickle-spawned soldier is promoted
##                    to an elite (GDD §8.4 Deathlord "more elites"). Only
##                    rolled when above 0, so lower levels keep the RNG stream.
##                    A promoted elite has elite HP and size but the base
##                    soldier's XP and no elite chest / power-up chance (a
##                    threat, not a loot source).
##   boss_hp          x the stage boss's HP (Sir Alaric, Marshal Vael).
##   ash_mult         x Soul Ash: paid as its own end-screen line worth
##                    (ash_mult - 1) x the run subtotal (negative below 1).
##   xp_mult          x XP gained (its own category, next to Grave Tithe and
##                    the Pact / Oath reward).
class_name DifficultyData
extends RefCounted

## Level ids from easiest to hardest (UI order, --difficulty= values).
const ORDER := ["initiate", "necromancer", "lich", "deathlord"]
## The standard level: today's game (RunConfig default, fresh saves).
const DEFAULT_ID: String = "necromancer"

## Every level (see the header for the keys).
const LEVELS := {
	"initiate": {
		"display_name": "Initiate",  # GDD §8.4
		"tagline": "Easier scaling. The Covenant grows stronger more slowly and hits softer.",  # GDD §8.4 "Easier scaling"
		"enemy_hp": 0.9,  # TUNING (not in GDD)
		"hp_scaling": 0.75,  # TUNING (not in GDD) 20 min: HP x8.2 -> x5.8 (x0.70 with enemy_hp)
		"enemy_damage": 0.8,  # TUNING (not in GDD)
		"damage_scaling": 0.75,  # TUNING (not in GDD) 20 min: damage x3.6 -> x2.4 (x0.66)
		"enemy_spawn": 1.0,  # TUNING (not in GDD) x0.9 meant fewer kills, less XP and builds complete at 18-19 min
		"enemy_speed": 1.0,  # TUNING (not in GDD)
		"elite_chance": 0.0,  # TUNING (not in GDD)
		"boss_hp": 0.8,  # TUNING (not in GDD)
		"ash_mult": 0.8,  # TUNING (not in GDD) an easier run pays less
		"xp_mult": 1.0,  # TUNING (not in GDD)
	},
	"necromancer": {
		"display_name": "Necromancer",  # GDD §8.4
		"tagline": "Standard. The Covenant as it was meant to be fought.",  # GDD §8.4 "Standard"
		"enemy_hp": 1.0,  # GDD §8.4 standard (today's game)
		"hp_scaling": 1.0,  # GDD §8.4 standard
		"enemy_damage": 1.0,  # GDD §8.4 standard
		"damage_scaling": 1.0,  # GDD §8.4 standard
		"enemy_spawn": 1.0,  # GDD §8.4 standard
		"enemy_speed": 1.0,  # GDD §8.4 standard
		"elite_chance": 0.0,  # GDD §8.4 standard (elites only from the timeline)
		"boss_hp": 1.0,  # GDD §8.4 standard
		"ash_mult": 1.0,  # GDD §8.4 standard
		"xp_mult": 1.0,  # GDD §8.4 standard
	},
	"lich": {
		"display_name": "Lich",  # GDD §8.4
		"tagline": "Increased HP and aggression. Tougher soldiers close in faster.",  # GDD §8.4 "Increased HP / aggression"
		"enemy_hp": 1.05,  # TUNING (not in GDD)
		"hp_scaling": 1.25,  # TUNING (not in GDD) 20 min: HP x8.2 -> x10.5 (x1.28 with enemy_hp)
		"enemy_damage": 1.05,  # TUNING (not in GDD)
		"damage_scaling": 1.2,  # TUNING (not in GDD) 20 min: damage x3.6 -> x4.3 (x1.20)
		"enemy_spawn": 1.0,  # TUNING (not in GDD) more spawns pay more XP: builds completed early
		"enemy_speed": 1.05,  # TUNING (not in GDD) "aggression"
		"elite_chance": 0.0,  # TUNING (not in GDD)
		"boss_hp": 1.15,  # TUNING (not in GDD)
		"ash_mult": 1.5,  # TUNING (not in GDD) owner decision Oct 2026 (was 1.25), GDD §15.0 "Ossuary expansion: owner decisions"
		"xp_mult": 1.0,  # TUNING (not in GDD)
	},
	"deathlord": {
		"display_name": "Deathlord",  # GDD §8.4
		"tagline": "The hardest. Stronger, faster soldiers, and elites march among them.",  # GDD §8.4 "Hardest, with more elites"
		"enemy_hp": 1.05,  # TUNING (not in GDD) gentle at first: an early army collapse never recovers
		"hp_scaling": 1.4,  # TUNING (not in GDD) 20 min: HP x8.2 -> x11.6 (x1.42 with enemy_hp)
		"enemy_damage": 1.05,  # TUNING (not in GDD)
		"damage_scaling": 1.4,  # TUNING (not in GDD) 20 min: damage x3.6 -> x4.9 (x1.35)
		"enemy_spawn": 1.0,  # TUNING (not in GDD) x1.1 / x1.2: the extra kills' XP completed builds early
		"enemy_speed": 1.06,  # TUNING (not in GDD)
		"elite_chance": 0.008,  # TUNING (not in GDD) ~1 trickle soldier in 125 is an elite
		"boss_hp": 1.3,  # TUNING (not in GDD)
		"ash_mult": 2.0,  # TUNING (not in GDD) owner decision Oct 2026 (was 1.5), GDD §15.0 "Ossuary expansion: owner decisions"
		"xp_mult": 1.0,  # TUNING (not in GDD) an XP bonus completed builds by 15:00
	},
}

## Keys that are multipliers (1 = unchanged), in UI order, with their short
## UI label. elite_chance (a chance) is shown separately.
const MULT_KEYS := ["enemy_hp", "enemy_damage", "enemy_spawn", "enemy_speed", "boss_hp", "ash_mult", "xp_mult"]
## Short UI label of each key (setup screen, HUD, autotest).
const SHORT := {
	"enemy_hp": "HP", "hp_scaling": "HP growth", "enemy_damage": "dmg", "damage_scaling": "dmg growth",
	"enemy_spawn": "spawn", "enemy_speed": "speed", "elite_chance": "elites",
	"boss_hp": "boss HP", "ash_mult": "Soul Ash", "xp_mult": "XP",
}
