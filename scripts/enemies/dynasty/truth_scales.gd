## TruthScales — THE SCALES, the Hall of Two Truths' stage mechanic (temporary
## Act XII, the Necropolis Dynasty; GDD §15.0 "The Hall of Two Truths
## (Necropolis Dynasty phase 2)"; owner-approved proposal: "A great pair of
## scales stands in the hall, and a Balance bar appears on the HUD. Each
## Rebirth tips the scale toward the Dynasty; each raise tips it toward the
## necromancer. Past a threshold either way: toward the necromancer, Dynasty
## enemies deal -15% damage (Ma'at's favour); toward the Dynasty, they gain
## +15% and Rebirth timers are 2 s shorter. Raising the dead is the way to win
## the scale"), owned by TwoTruthsDirector (`scales`). THE one balance:
##   * `balance` runs from -limit (toward the necromancer) to +limit (toward
##     the Dynasty). Each tick it reads Rebirth's own counters (no second hook
##     in the rule): every body that RETURNED tips it return_tip toward the
##     Dynasty; every RAISE (Rebirth.raises: HordeDirector.raise_corpse(), the
##     one raise path) raise_tip toward the necromancer, and a raise that STOLE
##     a Name steal_tip more; every cartouche SMASHED smash_tip toward the
##     necromancer (a Name denied, a lighter weight than a Name taken: own
##     decision so an army without raises can hold the scale level). Outside
##     the Weighing it SETTLES back toward level at `settle` per second.
##   * FAVOUR (favour()): +1 past +threshold (the Dynasty's: every Dynasty
##     enemy's hits x dynasty_mult through Enemy.hit_mult(), the one read, and
##     every cartouche rebirth_bonus s shorter through
##     Rebirth.set_duration_bonus("scales", ..), the one duration path); -1
##     past -threshold (Ma'at's: their hits x maat_mult); 0 between.
##   * THE WEIGHING (BossOsiris): begin_weighing() stops the settling (every
##     raise and every Rebirth counts) and end_weighing() returns the side it
##     ended on (sign of the balance: +1 the Dynasty, -1 the necromancer, 0
##     dead level).
## Drawn by ScalesBar on the HUD (a bar, never a screen effect). Determinism:
## game time and Rebirth's counters only. Stats: scales_* (the report line).
class_name TruthScales
extends RefCounted

## Owning run.
var game: Game
## The Scales' numbers (TwoTruthsStage.TWO_TRUTHS "scales").
var cfg: Dictionary = {}
## The balance now: -limit (the necromancer) .. +limit (the Dynasty).
var balance: float = 0.0
## The favour now: +1 the Dynasty's, -1 Ma'at's (the necromancer's), 0 none.
var favour_now: int = 0
## True while the necromancer's heart is on the Scales (no settling).
var weighing: bool = false
## Game time (s) the Weighing began (-1 = never).
var weighing_at: float = -1.0
## Most toward the Dynasty the balance went (>= 0).
var peak_dynasty: float = 0.0
## Most toward the necromancer the balance went (<= 0).
var peak_necro: float = 0.0
## Times the favour turned to the Dynasty / to Ma'at.
var tipped_dynasty: int = 0
## Times the favour turned to Ma'at (the necromancer).
var tipped_maat: int = 0
## Seconds spent in each favour: [Ma'at's, none, the Dynasty's].
var favour_time: Array[float] = [0.0, 0.0, 0.0]
## Rebirth's counters read so far (returns, raises, steals, smashes).
var _seen: Array[int] = [0, 0, 0, 0]
## Balance moved by each cause so far: [returns, raises, steals, smashes].
var moved: Array[float] = [0.0, 0.0, 0.0, 0.0]


## Builds the Scales for `p_game` with numbers `p_cfg`.
func _init(p_game: Game, p_cfg: Dictionary) -> void:
	game = p_game
	cfg = p_cfg


## Per tick (TwoTruthsDirector.step()): Rebirth's new returns, raises, steals
## and smashes tip the balance; it settles outside the Weighing; the favour
## follows the thresholds.
func step(delta: float) -> void:
	if game.dynasty == null:
		return
	var rb := game.dynasty.rebirth
	var now: Array[int] = [rb.returned[0] + rb.returned[1] + rb.returned[2], rb.raises, rb.stolen,
			int(rb.smashed.get("spell", 0)) + int(rb.smashed.get("summon", 0)) + int(rb.smashed.get("other", 0))]
	var tips: Array[float] = [float(cfg["return_tip"]), -float(cfg["raise_tip"]), -float(cfg["steal_tip"]), -float(cfg["smash_tip"])]
	for i in 4:
		var n := now[i] - _seen[i]
		if n > 0:
			_seen[i] = now[i]
			balance += tips[i] * float(n)
			moved[i] += tips[i] * float(n)
	if not weighing:
		balance = move_toward(balance, 0.0, float(cfg["settle"]) * delta)
	var lim := float(cfg["limit"])
	balance = clampf(balance, -lim, lim)
	peak_dynasty = maxf(peak_dynasty, balance)
	peak_necro = minf(peak_necro, balance)
	var f := 0
	if balance >= float(cfg["threshold"]):
		f = 1
	elif balance <= -float(cfg["threshold"]):
		f = -1
	favour_time[f + 1] += delta
	if f != favour_now:
		_turn(f)


## The favour turns to `f`: Rebirth's timers follow, a banner says so.
func _turn(f: int) -> void:
	favour_now = f
	game.dynasty.rebirth.set_duration_bonus("scales", float(cfg["rebirth_bonus"]) if f == 1 else 0.0)
	if f == 1:
		tipped_dynasty += 1
		game.stat_add("scales_tipped_dynasty", 1.0)
		game.enemies.show_banner(String(cfg["dynasty_banner"]))
		game.dynasty.play_sound("scales_dynasty", game.player.position, 2.0)
	elif f == -1:
		tipped_maat += 1
		game.stat_add("scales_tipped_maat", 1.0)
		game.enemies.show_banner(String(cfg["maat_banner"]))
		game.dynasty.play_sound("scales_maat", game.player.position, 2.0)


## x a Dynasty enemy's hits now (Enemy.hit_mult(), the one read).
func enemy_mult() -> float:
	if favour_now == 1:
		return float(cfg["dynasty_mult"])
	if favour_now == -1:
		return float(cfg["maat_mult"])
	return 1.0


## The favour now (+1 the Dynasty's, -1 Ma'at's, 0 none).
func favour() -> int:
	return favour_now


## The balance as a share of its limit (-1 .. +1; the HUD bar).
func share() -> float:
	return balance / maxf(float(cfg["limit"]), 0.01)


## The Weighing begins (BossOsiris): the Scales stop settling.
func begin_weighing() -> void:
	weighing = true
	weighing_at = game.elapsed


## The Weighing ends (BossOsiris): the side it ended on (+1 the Dynasty, -1
## the necromancer, 0 dead level); the Scales settle again.
func end_weighing() -> int:
	weighing = false
	if balance > 0.0:
		return 1
	if balance < 0.0:
		return -1
	return 0
