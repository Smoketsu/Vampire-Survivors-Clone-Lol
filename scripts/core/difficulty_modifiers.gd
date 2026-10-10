## DifficultyModifiers — the ONE path through which the opt-in difficulty
## modifiers reach a run (user request, data in PactData):
##   * the in-run Profane Pact passive (AbilityManager passive level), and
##   * the Profane Oath meta upgrade (active tier, read from game.meta).
## Game owns one instance (`game.difficulty`). The stat code asks it for
## multipliers instead of checking the Pact or the Oath itself:
##   enemy_spawn_mult()   EnemyDirector._spawn_trickle (rate and max_alive)
##   enemy_hp_mult()      EnemyDirector.step (hp_mult; also the Reckoning)
##   boss_hp_mult()       Sir Alaric's HP (a share of the HP bonus)
##   enemy_damage_mult()  EnemyDirector.step (damage_mult)
##   xp_mult()            Game.add_xp
##   drop_mult()          PowerupManager (power-up drop chance)
##   ash_parts()          Game.build_summary -> Meta.compute_ash bonus lines
## Pact and Oath bonuses of the same key ADD (one category, PactData
## header); the sum is applied as (1 + bonus). With no Pact level and Oath
## tier 0 every multiplier is exactly 1, so the run plays as before.
class_name DifficultyModifiers
extends RefCounted

## Owning run.
var game: Game


func _init(p_game: Game) -> void:
	game = p_game


## Current Profane Pact level (0 = not taken).
func pact_level() -> int:
	return game.abilities.passive_level(PactData.ID) if game.abilities != null else 0


## Active Profane Oath tier for this run (0 = off).
func oath_tier() -> int:
	return game.meta.int_value("oath_tier")


## Pact share of bonus `key` at Pact level `lvl` (-1 = current level).
func pact_value(key: String, lvl: int = -1) -> float:
	var l := pact_level() if lvl < 0 else lvl  # Pact level to read.
	if l <= 0:
		return 0.0
	return float(PactData.PASSIVE["levels"][l - 1][key])


## Oath share of bonus `key` (active tier x OATH_PER_TIER).
func oath_value(key: String) -> float:
	return float(oath_tier()) * float(PactData.OATH_PER_TIER[key])


## Combined bonus of `key` (Pact + Oath, they add). Pass `pact_lvl` to
## preview another Pact level (level-up card deltas).
func value(key: String, pact_lvl: int = -1) -> float:
	return pact_value(key, pact_lvl) + oath_value(key)


## Multiplier on the trickle spawn rate and the segment soft cap.
func enemy_spawn_mult() -> float:
	return 1.0 + value("enemy_spawn")


## Multiplier on enemy max HP (time-scaled enemies and the Reckoning).
func enemy_hp_mult() -> float:
	return 1.0 + value("enemy_hp")


## Multiplier on Sir Alaric's HP: only PactData.BOSS_HP_SHARE of the HP
## bonus applies to him.
func boss_hp_mult() -> float:
	return 1.0 + value("enemy_hp") * PactData.BOSS_HP_SHARE


## Multiplier on every enemy hit (applied through EnemyDirector.damage_mult).
func enemy_damage_mult() -> float:
	return 1.0 + value("enemy_damage")


## Multiplier on XP gained (its own category next to the meta Grave Tithe).
func xp_mult() -> float:
	return 1.0 + value("xp_gain")


## Multiplier on the power-up drop chances (not on the pity timer or the
## guaranteed boss drop).
func drop_mult() -> float:
	return 1.0 + value("drop_chance")


## True when the Pact or the Oath changes anything this run.
func is_active() -> bool:
	return pact_level() > 0 or oath_tier() > 0


## Soul Ash bonus fractions for Meta.compute_ash: {"pact": f, "oath": f}.
## Each is paid as its own floored bonus line on the run's subtotal.
func ash_parts() -> Dictionary:
	return {"pact": pact_value("ash_gain"), "oath": oath_value("ash_gain")}


## HUD lines: "" when inactive, else a title line, a penalty line and a
## reward line, e.g. "Profane Pact Lv 2 + Oath III".
func describe_lines() -> PackedStringArray:
	var out := PackedStringArray()  # HUD lines.
	if not is_active():
		return out
	var names := PackedStringArray()  # "Profane Pact Lv N" / "Profane Oath III".
	if pact_level() > 0:
		names.append("Profane Pact Lv %d" % pact_level())
	if oath_tier() > 0:
		names.append("Profane Oath %s" % roman(oath_tier()))
	out.append(" + ".join(names))
	var pen := PackedStringArray()  # "spawn +20%" per penalty key.
	var rew := PackedStringArray()  # "XP +16%" per reward key.
	for key: String in PactData.KEYS:
		var part := "%s +%d%%" % [PactData.SHORT[key], int(roundf(value(key) * 100.0))]  # "HP +20%".
		if key in PactData.PENALTY_KEYS:
			pen.append(part)
		else:
			rew.append(part)
	out.append("Foes: " + ", ".join(pen))
	out.append("Rewards: " + ", ".join(rew))
	return out


## Roman numeral for a tier 0..10 ("-" for 0).
static func roman(n: int) -> String:
	var numerals := ["-", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]  # Index = tier.
	return numerals[clampi(n, 0, numerals.size() - 1)]
