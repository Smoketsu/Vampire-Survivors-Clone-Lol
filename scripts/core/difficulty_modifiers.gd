## DifficultyModifiers — the ONE path through which every difficulty choice
## reaches a run:
##   * the DIFFICULTY LEVEL (GDD §8.4, DifficultyData; RunConfig.difficulty_id),
##   * the optional RUN MODIFIERS (GDD §8.5, RunModifierData; RunConfig.modifiers),
##   * the in-run Profane Pact passive (AbilityManager passive level),
##   * the Profane Oath meta upgrade (active tier, read from game.meta), and
##   * HYPER mode (HyperData; RunConfig.hyper), an opt-in toggle that
##     stacks on the level.
## Game owns one instance (`game.difficulty`). The stat code asks it for
## multipliers instead of checking any of these itself:
##   enemy_spawn_mult()   EnemyDirector._spawn_trickle (rate and max_alive)
##   enemy_hp_mult()      EnemyDirector.step (hp_mult; also the Reckoning)
##   hp_scaling()         EnemyDirector.step (growth part of the HP time scaling)
##   enemy_damage_mult()  EnemyDirector.step (damage_mult)
##   damage_scaling()     EnemyDirector.step (growth part of the damage scaling)
##   enemy_speed_mult()   EnemyDirector._spawn_enemy_def (move speed)
##   elite_chance()       EnemyDirector._spawn_trickle (trickle elites)
##   trickle_weights()    EnemyDirector._spawn_trickle (Purge the Unholy)
##   boss_hp_mult()       the stage boss's HP (a share of the HP bonus)
##   xp_mult()            Game.add_xp
##   drop_mult()          PowerupManager (power-up drop chance)
##   powerup_weight() / feast_heal_mult()   PowerupManager (Scarcity)
##   minion_hp_mult() / minion_damage_mult() HordeDirector.compute_stats (Vengeful Dead)
##   apply_to_player()    Game._ready (Frail Master)
##   radiant_*()          CombatResolver._kill_enemy (Holy Retribution)
##   ash_parts()          Game.build_summary -> Meta.compute_ash bonus lines
##
## HOW THEY COMBINE (GDD §6.4 "add like-category bonuses, multiply separate
## categories"; recorded in GDD §15.0):
##   * The difficulty LEVEL is its own category: its multiplier applies once.
##   * The OPT-IN modifiers (the Profane Pact, the Profane Oath and the §8.5
##     run modifiers) are ONE category per key: their bonuses ADD.
##   * So for enemy spawn / HP / damage:
##       mult(key) = level[key] x (1 + pact + oath + sum of run modifiers)
##     and that multiplies the time scaling, the stage multipliers and every
##     other category. The level's hp_scaling / damage_scaling scale only the
##     growth part of the time scaling. The boss gets level boss_hp x
##     (1 + BOSS_HP_SHARE x the opt-in HP bonus).
##   * HYPER is its own category too, applied once on top of the level:
##     hp_scaling / damage_scaling x HyperData.GROWTH_MULT (the growth part
##     only, so the Reckoning, built from the same time scaling, grows too)
##     and boss_hp x HyperData.BOSS_HP_MULT.
##   * XP: level xp_mult x (1 + Pact + Oath XP reward), next to Grave Tithe.
##   * Soul Ash: each source pays its own floored line on the run subtotal
##     (all lines add): Ash Harvest, Pact, Oath, the stage bonus, the
##     difficulty line ((ash_mult - 1) x subtotal, negative on Initiate) and
##     one "Run modifiers" line (the summed ash_gain of the active modifiers),
##     plus one "Hyper" line (HyperData.ASH_BONUS x subtotal) when Hyper is on.
##     The setup screen shows level ash_mult + modifier ash (+ Hyper) as the
##     run's total reward multiplier.
## With the Necromancer level, no run modifier, Hyper off, no Pact level and
## Oath tier 0 every multiplier is exactly 1 (and the extra elite roll is
## skipped), so the run plays bit-for-bit as before.
class_name DifficultyModifiers
extends RefCounted

## Owning run.
var game: Game
## DifficultyData id of this run's level.
var _level_id: String = DifficultyData.DEFAULT_ID
## DifficultyData row of this run's level.
var _level: Dictionary = {}
## Active run modifier ids (RunModifierData.ORDER order).
var _mods: PackedStringArray = PackedStringArray()
## True when Hyper mode is on this run (RunConfig.hyper).
var _hyper: bool = false


func _init(p_game: Game) -> void:
	game = p_game
	var cfg: RunConfig = game.run_config if game != null else null  # Pre-run choices (null = defaults).
	if cfg != null:
		_level_id = cfg.difficulty_id if DifficultyData.LEVELS.has(cfg.difficulty_id) else DifficultyData.DEFAULT_ID
		for id: String in cfg.modifiers:
			if RunModifierData.MODIFIERS.has(id):
				_mods.append(id)
		_hyper = cfg.hyper
	_level = DifficultyData.LEVELS[_level_id]


# =====================================================================================
# Static helpers (also used by the pre-run setup screen, without a run)
# =====================================================================================

## Sum of bonus `key` over the run modifiers `ids` (0 when none has it).
static func modifiers_sum(ids: PackedStringArray, key: String) -> float:
	var total := 0.0  # Summed bonus.
	for id: String in ids:
		total += float(RunModifierData.MODIFIERS[id]["effects"].get(key, 0.0))
	return total


## Product of factor `key` over the run modifiers `ids` (1 when none has it).
static func modifiers_factor(ids: PackedStringArray, key: String) -> float:
	var f := 1.0  # Combined factor.
	for id: String in ids:
		f *= float(RunModifierData.MODIFIERS[id]["effects"].get(key, 1.0))
	return f


## Summed Soul Ash reward (fraction of the subtotal) of the run modifiers `ids`.
static func modifiers_ash(ids: PackedStringArray) -> float:
	var total := 0.0  # Summed ash_gain.
	for id: String in ids:
		total += float(RunModifierData.MODIFIERS[id]["ash_gain"])
	return total


## Total Soul Ash multiplier of a difficulty level plus run modifiers (and
## Hyper when `hyper`; the number the setup screen shows): 1 + (ash_mult - 1)
## + modifier ash (+ HyperData.ASH_BONUS). The Oath, Pact, stage bonus and
## Ash Harvest add their own lines on top.
static func reward_mult(level_id: String, ids: PackedStringArray, hyper: bool = false) -> float:
	var lv: Dictionary = DifficultyData.LEVELS.get(level_id, DifficultyData.LEVELS[DifficultyData.DEFAULT_ID])
	return float(lv["ash_mult"]) + modifiers_ash(ids) + (HyperData.ASH_BONUS if hyper else 0.0)


## Hyper's factor on the growth part of the time scaling (1 when off).
static func hyper_growth(hyper: bool) -> float:
	return HyperData.GROWTH_MULT if hyper else 1.0


## Enemy multipliers of a level plus run modifiers, without the Pact / Oath
## (setup screen): {"enemy_hp", "enemy_damage" (at the start), "enemy_hp_end",
## "enemy_damage_end" (vs the standard game when the countdown ends, the
## level's faster / slower growth included), "enemy_spawn", "enemy_speed",
## "boss_hp", "elite_chance"}. `hyper` adds Hyper's growth and boss HP.
static func preview(level_id: String, ids: PackedStringArray, hyper: bool = false) -> Dictionary:
	var lv: Dictionary = DifficultyData.LEVELS.get(level_id, DifficultyData.LEVELS[DifficultyData.DEFAULT_ID])
	var m := WaveData.RUN_DURATION / 60.0  # Minutes elapsed at 0:00 on the countdown.
	var hp_g := m * WaveData.HP_SCALE_PER_MINUTE + m * m * WaveData.HP_SCALE_PER_MINUTE_SQ  # Standard HP growth then.
	var dmg_g := m * WaveData.DAMAGE_SCALE_PER_MINUTE + m * m * WaveData.DAMAGE_SCALE_PER_MINUTE_SQ  # Standard damage growth then.
	var hp := float(lv["enemy_hp"]) * (1.0 + modifiers_sum(ids, "enemy_hp"))  # Flat HP multiplier.
	var dmg := float(lv["enemy_damage"]) * (1.0 + modifiers_sum(ids, "enemy_damage"))  # Flat damage multiplier.
	var hg := hyper_growth(hyper)  # Hyper growth factor (1 when off).
	return {
		"enemy_hp": hp,
		"enemy_damage": dmg,
		"enemy_hp_end": hp * (1.0 + hp_g * float(lv["hp_scaling"]) * hg) / (1.0 + hp_g),
		"enemy_damage_end": dmg * (1.0 + dmg_g * float(lv["damage_scaling"]) * hg) / (1.0 + dmg_g),
		"enemy_spawn": float(lv["enemy_spawn"]) * (1.0 + modifiers_sum(ids, "enemy_spawn")),
		"enemy_speed": float(lv["enemy_speed"]),
		"boss_hp": float(lv["boss_hp"]) * (1.0 + modifiers_sum(ids, "enemy_hp") * PactData.BOSS_HP_SHARE) * (HyperData.BOSS_HP_MULT if hyper else 1.0),
		"elite_chance": float(lv["elite_chance"]),
	}


# =====================================================================================
# Level and run modifiers
# =====================================================================================

## DifficultyData id of this run's level.
func difficulty_id() -> String:
	return _level_id


## UI name of this run's level ("Lich").
func difficulty_name() -> String:
	return String(_level["display_name"])


## True when Hyper mode is on this run.
func is_hyper() -> bool:
	return _hyper


## UI name of the level with Hyper appended when on ("Lich + Hyper").
func difficulty_label() -> String:
	return difficulty_name() + (" + " + HyperData.DISPLAY_NAME if _hyper else "")


## Value `key` of this run's level row (DifficultyData keys).
func level_value(key: String) -> float:
	return float(_level[key])


## Active run modifier ids (RunModifierData.ORDER order).
func modifier_ids() -> PackedStringArray:
	return _mods


## True when run modifier `id` is active.
func has_modifier(id: String) -> bool:
	return _mods.has(id)


## True when the level is not the standard one, any run modifier is on or
## Hyper is on.
func has_run_setup() -> bool:
	return _level_id != DifficultyData.DEFAULT_ID or not _mods.is_empty() or _hyper


# =====================================================================================
# Profane Pact / Oath
# =====================================================================================

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


## Combined Pact + Oath bonus of `key` (they add). Pass `pact_lvl` to
## preview another Pact level (level-up card deltas).
func value(key: String, pact_lvl: int = -1) -> float:
	return pact_value(key, pact_lvl) + oath_value(key)


## The whole opt-in bonus of `key`: Pact + Oath + run modifiers (one
## category, they add).
func optional_value(key: String) -> float:
	return value(key) + modifiers_sum(_mods, key)


# =====================================================================================
# Multipliers read by the stat code
# =====================================================================================

## Multiplier on the trickle spawn rate and the segment soft cap.
func enemy_spawn_mult() -> float:
	return float(_level["enemy_spawn"]) * (1.0 + optional_value("enemy_spawn"))


## Multiplier on enemy max HP (time-scaled enemies and the Reckoning).
func enemy_hp_mult() -> float:
	return float(_level["enemy_hp"]) * (1.0 + optional_value("enemy_hp"))


## Multiplier on the growth part of the enemy HP time scaling: the level's,
## times HyperData.GROWTH_MULT when Hyper is on (exactly the level's when off).
func hp_scaling() -> float:
	var s := float(_level["hp_scaling"])  # Level growth factor.
	return s * HyperData.GROWTH_MULT if _hyper else s


## Multiplier on the stage boss's HP: the level's boss_hp times only
## PactData.BOSS_HP_SHARE of the opt-in HP bonus, times
## HyperData.BOSS_HP_MULT when Hyper is on.
func boss_hp_mult() -> float:
	var m := float(_level["boss_hp"]) * (1.0 + optional_value("enemy_hp") * PactData.BOSS_HP_SHARE)  # Without Hyper.
	return m * HyperData.BOSS_HP_MULT if _hyper else m


## Multiplier on every enemy hit (applied through EnemyDirector.damage_mult).
func enemy_damage_mult() -> float:
	return float(_level["enemy_damage"]) * (1.0 + optional_value("enemy_damage"))


## Multiplier on the growth part of the enemy damage time scaling: the
## level's, times HyperData.GROWTH_MULT when Hyper is on.
func damage_scaling() -> float:
	var s := float(_level["damage_scaling"])  # Level growth factor.
	return s * HyperData.GROWTH_MULT if _hyper else s


## Multiplier on enemy move speed (level "aggression"; not the stage boss).
func enemy_speed_mult() -> float:
	return float(_level["enemy_speed"])


## Chance 0..1 that a trickle-spawned soldier is promoted to an elite.
func elite_chance() -> float:
	return float(_level["elite_chance"])


## Trickle segment weights with Purge the Unholy applied: the Purifier
## weight times purifier_weight, plus purifier_add in segments without
## Purifiers from purifier_from s on. Returns `weights` itself (no copy)
## when the modifier is off, so the draw is unchanged.
func trickle_weights(weights: Dictionary, t: float) -> Dictionary:
	if not has_modifier("purge_the_unholy"):
		return weights
	var fx: Dictionary = RunModifierData.MODIFIERS["purge_the_unholy"]["effects"]
	var out := weights.duplicate()  # Modified weights.
	if out.has("purifier"):
		out["purifier"] = float(out["purifier"]) * float(fx["purifier_weight"])
	elif t >= float(fx["purifier_from"]):
		out["purifier"] = float(fx["purifier_add"])
	return out


## Multiplier on XP gained: the level's xp_mult times the Pact / Oath XP
## reward (its own category next to the meta Grave Tithe).
func xp_mult() -> float:
	return float(_level["xp_mult"]) * (1.0 + value("xp_gain"))


## Multiplier on the power-up drop chances (not on the pity timer or the
## guaranteed boss drop). Pact / Oath only.
func drop_mult() -> float:
	return 1.0 + value("drop_chance")


## Draw weight of power-up `kind` given its data weight `w` (Scarcity makes
## Grave Feast rarer).
func powerup_weight(kind: String, w: float) -> float:
	if kind == "feast":
		return w * modifiers_factor(_mods, "feast_weight")
	return w


## Multiplier on the HP a Grave Feast restores (Scarcity).
func feast_heal_mult() -> float:
	return modifiers_factor(_mods, "feast_heal")


## Multiplier on summon max HP (Vengeful Dead; own category).
func minion_hp_mult() -> float:
	return 1.0 + modifiers_sum(_mods, "minion_hp")


## Multiplier on summon damage (Vengeful Dead; own category).
func minion_damage_mult() -> float:
	return 1.0 + modifiers_sum(_mods, "minion_damage")


## Multiplier on the necromancer's starting max HP (Frail Master).
func player_hp_mult() -> float:
	return modifiers_factor(_mods, "player_hp")


## Run-start player stats (after MetaModifiers.apply_to_player): Frail
## Master lowers max HP (rounded) and starts him full. No-op otherwise.
func apply_to_player(p: Necromancer) -> void:
	var f := player_hp_mult()  # Max HP factor.
	if f == 1.0:
		return
	p.max_hp = maxf(1.0, roundf(p.max_hp * f))
	p.hp = p.max_hp


## Radiant bolts an elite fires when it dies (Holy Retribution; 0 = off).
func radiant_bolts() -> int:
	return int(modifiers_sum(_mods, "radiant_bolts"))


## Base damage of one radiant bolt (before EnemyDirector.damage_mult).
func radiant_damage() -> float:
	return float(RunModifierData.MODIFIERS["holy_retribution"]["effects"]["radiant_damage"])


## Radiant bolt speed (px/s).
func radiant_speed() -> float:
	return float(RunModifierData.MODIFIERS["holy_retribution"]["effects"]["radiant_speed"])


## True when the Pact or the Oath changes anything this run.
func is_active() -> bool:
	return pact_level() > 0 or oath_tier() > 0


## Soul Ash bonus fractions for Meta.compute_ash, each paid as its own
## floored line on the run's subtotal: {"pact", "oath", "difficulty"
## (ash_mult - 1, negative on easier levels), "modifiers" (summed ash_gain),
## "hyper" (HyperData.ASH_BONUS when on, else 0)}.
func ash_parts() -> Dictionary:
	return {"pact": pact_value("ash_gain"), "oath": oath_value("ash_gain"),
		"difficulty": float(_level["ash_mult"]) - 1.0, "modifiers": modifiers_ash(_mods),
		"hyper": HyperData.ASH_BONUS if _hyper else 0.0}


## Display names of the active run modifiers.
func modifier_names() -> PackedStringArray:
	var out := PackedStringArray()  # "Hardened Faith"...
	for id: String in _mods:
		out.append(String(RunModifierData.MODIFIERS[id]["display_name"]))
	return out


# =====================================================================================
# HUD / summary text
# =====================================================================================

## HUD Modifiers area: the difficulty level and run modifiers (with the total
## Soul Ash multiplier), then the Pact / Oath lines (describe_lines()). The
## HUD shows it only when the run differs from the standard one.
func hud_lines() -> PackedStringArray:
	var out := PackedStringArray()  # HUD lines.
	var shorts := PackedStringArray()  # One word per active run modifier.
	for id: String in _mods:
		shorts.append(String(RunModifierData.MODIFIERS[id]["short_name"]))
	out.append("Difficulty: %s" % difficulty_label())  # First line ("Lich + Hyper"); no "Modifiers: none" noise.
	if not shorts.is_empty():
		out.append("Modifiers: " + ", ".join(shorts))
	if has_run_setup():
		out.append("Soul Ash x%.2f" % reward_mult(_level_id, _mods, _hyper))
	out.append_array(describe_lines())
	return out


## Pact / Oath HUD lines: "" when inactive, else a title line, a penalty
## line and a reward line, e.g. "Profane Pact Lv 2 + Oath III".
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


## One-line description of the effective multipliers (autotest summary).
func summary_line() -> String:
	return "difficulty: %s (%s) | modifiers: %s | foes: HP x%.3f (growth x%.2f), dmg x%.3f (growth x%.2f), spawn x%.3f, speed x%.2f, elite chance %.3f, boss HP x%.3f | XP x%.3f | soul ash: difficulty %+d%%, modifiers +%d%%, total x%.2f" % [
		difficulty_name(), _level_id, ", ".join(_mods) if not _mods.is_empty() else "none",
		enemy_hp_mult(), hp_scaling(), enemy_damage_mult(), damage_scaling(), enemy_spawn_mult(), enemy_speed_mult(),
		elite_chance(), boss_hp_mult(), xp_mult(), roundi((level_value("ash_mult") - 1.0) * 100.0),
		roundi(modifiers_ash(_mods) * 100.0), reward_mult(_level_id, _mods)]


## Roman numeral for a tier 0..10 ("-" for 0).
static func roman(n: int) -> String:
	var numerals := ["-", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]  # Index = tier.
	return numerals[clampi(n, 0, numerals.size() - 1)]
