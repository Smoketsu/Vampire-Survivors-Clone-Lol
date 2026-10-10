## PactData — designer-tunable data for the two opt-in DIFFICULTY modifiers
## (user request; the Vampire Survivors "Curse" idea, GDD §8.5 "optional run
## modifiers" gives no numbers, so every value here is TUNING):
##   * Profane Pact — an in-run PASSIVE item (5 levels). It is offered on
##     level-up cards like the other passives, takes a passive slot and can
##     be banished. PassiveData.PASSIVES["profane_pact"] is PASSIVE below.
##   * Profane Oath — a meta upgrade bought in the Ossuary (5 tiers, defined
##     in MetaData.UPGRADES["profane_oath"]). Its per-tier effect is
##     OATH_PER_TIER below; the player may lower or disable the active tier.
## Both raise the danger AND the rewards:
##   penalties  enemy_spawn  trickle rate and soft cap (max_alive) of the wave
##                           segments (EnemyDirector._spawn_trickle)
##              enemy_hp     enemy HP multiplier (EnemyDirector.hp_mult; also
##                           the Reckoning; Sir Alaric gets BOSS_HP_SHARE of it)
##              enemy_damage enemy damage multiplier (EnemyDirector.damage_mult)
##   rewards    xp_gain      XP gain (Game.add_xp)
##              ash_gain     Soul Ash earned (Meta.compute_ash bonus lines)
##              drop_chance  power-up drop chance (PowerupManager)
## Stacking (user decision, GDD §6.4 "add like-category bonuses, multiply
## separate categories"): the Pact level row and the Oath tier bonus are the
## SAME category, so they ADD:
##   bonus(key) = PASSIVE.levels[pact_level - 1][key] + oath_tier * OATH_PER_TIER[key]
## and the sum is applied once as (1 + bonus), multiplying the time scaling,
## the meta upgrades and every other category. DifficultyModifiers is the one
## place that computes it.
class_name PactData
extends RefCounted

## Passive id of the Profane Pact (PassiveData.ORDER / PASSIVES key).
const ID: String = "profane_pact"
## Meta upgrade id of the Profane Oath (MetaData.UPGRADES key).
const OATH_ID: String = "profane_oath"
## Every difficulty key, penalties first (card / HUD / Ossuary line order).
const KEYS := ["enemy_spawn", "enemy_hp", "enemy_damage", "xp_gain", "ash_gain", "drop_chance"]
## Keys that make the run harder (shown as penalties, the rest are rewards).
const PENALTY_KEYS := ["enemy_spawn", "enemy_hp", "enemy_damage"]

## Draw-weight multiplier of the Pact card on top of the usual LevelUpData
## weights (a modest weight: it shows up now and then, not every hand).
const CARD_WEIGHT_MULT: float = 0.4  # TUNING (not in GDD)

## The Profane Pact passive definition, in the PassiveData.PASSIVES format
## (display_name, icon, description, labels, levels with ABSOLUTE values).
## Per level: spawn +5%, HP +5%, damage +3%; XP +8%, Soul Ash +12%, drops
## +15%. Post-merge retune: +10 / +10 / +6 per level (ash +10%) made a Lv 5
## Pact a trap: the army bot, swamped by +50% spawns of +50% HP, never killed
## Sir Alaric (63,000 HP); at +6 / +5 / +4 it still left him at 0-16k HP.
const PASSIVE := {
	"display_name": "Profane Pact",
	"icon": "profane_pact",
	"description": "Swear a dark pact: the Covenant sends more and stronger soldiers, and you reap more from every death.",
	"labels": {
		"enemy_spawn": ["Foes: spawn rate", "pct"],
		"enemy_hp": ["Foes: HP", "pct"],
		"enemy_damage": ["Foes: damage", "pct"],
		"xp_gain": ["Reward: XP", "pct"],
		"ash_gain": ["Reward: Soul Ash", "pct"],
		"drop_chance": ["Reward: drop chance", "pct"],
	},
	"levels": [
		{"enemy_spawn": 0.05, "enemy_hp": 0.05, "enemy_damage": 0.03, "xp_gain": 0.08, "ash_gain": 0.12, "drop_chance": 0.15},  # TUNING (not in GDD)
		{"enemy_spawn": 0.10, "enemy_hp": 0.10, "enemy_damage": 0.06, "xp_gain": 0.16, "ash_gain": 0.24, "drop_chance": 0.30},  # TUNING (not in GDD)
		{"enemy_spawn": 0.15, "enemy_hp": 0.15, "enemy_damage": 0.09, "xp_gain": 0.24, "ash_gain": 0.36, "drop_chance": 0.45},  # TUNING (not in GDD)
		{"enemy_spawn": 0.20, "enemy_hp": 0.20, "enemy_damage": 0.12, "xp_gain": 0.32, "ash_gain": 0.48, "drop_chance": 0.60},  # TUNING (not in GDD)
		{"enemy_spawn": 0.25, "enemy_hp": 0.25, "enemy_damage": 0.15, "xp_gain": 0.40, "ash_gain": 0.60, "drop_chance": 0.75},  # TUNING (not in GDD)
	],
}

## Bonus added per active Profane Oath tier (applies from the first second;
## unchanged in the post-merge retune: Oath V is meant as a hard mode, the
## army bot never dies but kills Sir Alaric in about 1 run in 4).
const OATH_PER_TIER := {
	"enemy_spawn": 0.06,  # TUNING (not in GDD)
	"enemy_hp": 0.05,  # TUNING (not in GDD)
	"enemy_damage": 0.04,  # TUNING (not in GDD)
	"xp_gain": 0.05,  # TUNING (not in GDD)
	"ash_gain": 0.10,  # TUNING (not in GDD)
	"drop_chance": 0.10,  # TUNING (not in GDD)
}

## Fraction of the combined enemy_hp bonus that also applies to Sir Alaric
## (his base HP is not time-scaled, so the full bonus made him a wall: a
## Lv 5 Pact took him from 42,000 to 63,000 HP).
const BOSS_HP_SHARE: float = 0.2  # TUNING (not in GDD) Lv 5 Pact: 42,000 -> 44,100 HP

## Short HUD / Ossuary names of the keys.
const SHORT := {"enemy_spawn": "spawn", "enemy_hp": "HP", "enemy_damage": "dmg",
	"xp_gain": "XP", "ash_gain": "Ash", "drop_chance": "drops"}
