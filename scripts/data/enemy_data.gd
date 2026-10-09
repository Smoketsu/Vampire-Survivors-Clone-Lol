## EnemyData — immutable design data for the Crimson Covenant roster used in
## the prototype (GDD §10 roster, §35 interaction rules) and for the
## placeholder boss Sir Alaric (GDD §11).
##
## The GDD only describes enemies qualitatively ("weak basic infantry",
## "moderate damage resistance", "bonus damage versus undead"...), so every
## number below is TUNING (not in GDD); the behaviour each number expresses
## is cited.
class_name EnemyData
extends RefCounted

## Display / iteration order of regular enemy kinds.
const ORDER := ["recruit", "footman", "archer", "chaplain", "purifier"]

## Regular enemy definitions. Field reference (same keys in every row):
##   display_name        — UI string.
##   max_hp              — HP before time scaling.
##   move_speed          — px/s.
##   damage              — damage per attack before time scaling.
##   attack_interval     — s between attacks.
##   attack_range        — px edge-to-edge (melee) / max firing range (ranged).
##   radius              — body radius px.
##   armor               — fraction of incoming damage ignored (0..0.9).
##   xp                  — XP crystal value dropped on death.
##   behavior            — AI branch: "melee" | "ranged" | "healer" | "purifier".
##   preferred_range     — px from target that ranged/healer units try to keep.
##   projectile_speed    — px/s for ranged attacks.
##   undead_damage_mult  — damage multiplier vs undead summons (not player).
##   heal_amount         — HP healed per cast on another enemy.
##   heal_interval       — s between heals.
##   heal_radius         — px search radius for heal targets.
##   target_priority     — 0..1 "role priority" summons use when scoring this
##                         enemy as a target (healers/casters high).
const ENEMIES := {
	# GDD §10 "Weak basic infantry, mass waves."
	"recruit": {
		"display_name": "Covenant Recruit",
		"max_hp": 18.0,  # TUNING (not in GDD)
		"move_speed": 58.0,  # TUNING (not in GDD)
		"damage": 5.0,  # TUNING (not in GDD)
		"attack_interval": 1.0,  # TUNING (not in GDD)
		"attack_range": 4.0,  # TUNING (not in GDD)
		"radius": 9.0,  # TUNING (not in GDD)
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"preferred_range": 0.0,
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.2,  # TUNING (not in GDD)
	},
	# GDD §10 "Armored melee, moderate damage resistance."
	"footman": {
		"display_name": "Crimson Footman",
		"max_hp": 45.0,  # TUNING (not in GDD)
		"move_speed": 50.0,  # TUNING (not in GDD)
		"damage": 9.0,  # TUNING (not in GDD)
		"attack_interval": 1.2,  # TUNING (not in GDD)
		"attack_range": 5.0,  # TUNING (not in GDD)
		"radius": 11.0,  # TUNING (not in GDD)
		"armor": 0.3,  # TUNING (not in GDD) — "moderate damage resistance"
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"preferred_range": 0.0,
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD)
	},
	# GDD §10 "Ranged projectiles."
	"archer": {
		"display_name": "Zealous Archer",
		"max_hp": 22.0,  # TUNING (not in GDD)
		"move_speed": 55.0,  # TUNING (not in GDD)
		"damage": 7.0,  # TUNING (not in GDD)
		"attack_interval": 2.2,  # TUNING (not in GDD)
		"attack_range": 240.0,  # TUNING (not in GDD) max firing distance
		"radius": 9.0,  # TUNING (not in GDD)
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "ranged",
		"preferred_range": 190.0,  # TUNING (not in GDD)
		"projectile_speed": 230.0,  # TUNING (not in GDD)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # GDD §27 archers prefer enemy archers/casters
	},
	# GDD §10 "Heals enemy allies"; §35 "increase ranged-unit target preference".
	"chaplain": {
		"display_name": "Covenant Chaplain",
		"max_hp": 40.0,  # TUNING (not in GDD)
		"move_speed": 48.0,  # TUNING (not in GDD)
		"damage": 4.0,  # TUNING (not in GDD) weak melee if cornered
		"attack_interval": 1.4,  # TUNING (not in GDD)
		"attack_range": 4.0,  # TUNING (not in GDD)
		"radius": 10.0,  # TUNING (not in GDD)
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 5,  # TUNING (not in GDD)
		"behavior": "healer",
		"preferred_range": 170.0,  # TUNING (not in GDD)
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 10.0,  # TUNING (not in GDD)
		"heal_interval": 2.5,  # TUNING (not in GDD)
		"heal_radius": 150.0,  # TUNING (not in GDD)
		"target_priority": 1.0,  # GDD §27/§35 healers are top archer priority
	},
	# GDD §10 "Bonus damage versus undead summons"; §35 "prioritize undead...
	# relatively vulnerable to ranged focus".
	"purifier": {
		"display_name": "Purifier",
		"max_hp": 30.0,  # TUNING (not in GDD) fragile on purpose (§35)
		"move_speed": 66.0,  # TUNING (not in GDD)
		"damage": 8.0,  # TUNING (not in GDD)
		"attack_interval": 1.0,  # TUNING (not in GDD)
		"attack_range": 5.0,  # TUNING (not in GDD)
		"radius": 10.0,  # TUNING (not in GDD)
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "purifier",
		"preferred_range": 0.0,
		"projectile_speed": 0.0,
		"undead_damage_mult": 2.0,  # TUNING (not in GDD) "bonus damage vs undead"
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD)
	},
}

## Elite modifiers (GDD §11 timeline "05:00 Chaplain elite").
## Multiplier on max HP for elites.
const ELITE_HP_MULT: float = 3.0  # TUNING (not in GDD)
## Multiplier on body radius for elites.
const ELITE_RADIUS_MULT: float = 1.35  # TUNING (not in GDD)
## Multiplier on XP value for elites.
const ELITE_XP_MULT: int = 5  # TUNING (not in GDD)
## Multiplier on heal amount for elite healers.
const ELITE_HEAL_MULT: float = 2.0  # TUNING (not in GDD)

## Search radius (px) in which melee enemies will divert onto a summon that is
## closer than the player ("enemies can still hit allied summons", GDD §26).
const MELEE_DIVERT_RADIUS: float = 50.0  # TUNING (not in GDD)
## Search radius (px) in which Purifiers hunt summons first (GDD §35).
const PURIFIER_HUNT_RADIUS: float = 260.0  # TUNING (not in GDD)
## Enemies within this distance (px) of the player with the player as target
## count as "attacking the player" for warrior threat scoring (GDD §27).
const ATTACKING_PLAYER_RADIUS: float = 120.0  # TUNING (not in GDD)
## Minimum missing-HP fraction before a chaplain will heal an ally.
const HEAL_MIN_MISSING_FRACTION: float = 0.1  # TUNING (not in GDD)
## Strength of enemy-enemy separation steering (fraction of move speed).
const SEPARATION_STRENGTH: float = 0.9  # TUNING (not in GDD)

## Sir Alaric, the Gravebreaker (GDD §11). Only Hammerfall and Divine Charge
## are implemented in the prototype.
##   max_hp ... target_priority — as for ENEMIES.
##   attack_gap         — s between the end of one special and the next.
##   hammer_radius      — px radius of Hammerfall's ground AoE.
##   hammer_telegraph   — s the warning circle is shown before impact.
##   hammer_damage_player / hammer_damage_summon — damage on impact.
##   hammer_max_range   — px; Hammerfall is preferred within this distance.
##   charge_telegraph   — s the warning line is shown before the dash.
##   charge_speed       — px/s during the dash.
##   charge_length      — px travelled by the dash.
##   charge_width       — px; width of the telegraphed lane.
##   charge_damage_player / charge_damage_summon — damage on contact.
##   recover_time       — s the boss stands still after a charge.
##   slow_resist        — fraction of slow effects ignored.
const BOSS := {
	"display_name": "Sir Alaric, the Gravebreaker",  # GDD §11
	"max_hp": 4000.0,  # TUNING (not in GDD)
	"move_speed": 52.0,  # TUNING (not in GDD)
	"damage": 12.0,  # TUNING (not in GDD) basic hammer swing
	"attack_interval": 1.0,  # TUNING (not in GDD)
	"attack_range": 8.0,  # TUNING (not in GDD)
	"radius": 22.0,  # TUNING (not in GDD)
	"armor": 0.15,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"preferred_range": 0.0,
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §32 archers prioritise the boss
	"attack_gap": 2.8,  # TUNING (not in GDD)
	"hammer_radius": 80.0,  # TUNING (not in GDD)
	"hammer_telegraph": 1.2,  # TUNING (not in GDD)
	"hammer_damage_player": 30.0,  # TUNING (not in GDD)
	"hammer_damage_summon": 45.0,  # TUNING (not in GDD)
	"hammer_max_range": 230.0,  # TUNING (not in GDD)
	"charge_telegraph": 0.9,  # TUNING (not in GDD)
	"charge_speed": 620.0,  # TUNING (not in GDD)
	"charge_length": 420.0,  # TUNING (not in GDD)
	"charge_width": 56.0,  # TUNING (not in GDD)
	"charge_damage_player": 28.0,  # TUNING (not in GDD)
	"charge_damage_summon": 40.0,  # TUNING (not in GDD)
	"recover_time": 0.9,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD)
}
