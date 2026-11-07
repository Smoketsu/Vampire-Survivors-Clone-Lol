## GeneralKit — THE GENERAL OF THE LEFT, Castle Kurogane's miniboss
## (KuroganeEnemyData "general_left"; Act V, GDD §15.0 "Castle Kurogane (Act V
## phase 2)"; owner-approved proposal: "Miniboss, the General of the Left: a
## mounted samurai who charges through the ring"). Spawned once by
## KuroganeDirector (the "general_left" timeline event, 9:00 left) through the
## normal spawn path; it registers as EnemyDirector.miniboss (the HUD's
## miniboss bar; ChestManager drops the miniboss chest). A KibaKit:
##   * The charge THROUGH the ring — the Kiba-musha's charge with his row's
##       numbers: a long, wide lane aimed at the necromancer that runs well
##       past him (charge_length), so it cuts through the Bone Ring; below
##       rage_hp of his HP he charges rage_charges times in a row.
##   * The left wing — after each charge (at most every riders_every s, while
##       fewer than riders_max_alive of his riders ride) he calls riders_count
##       Kiba-musha at his side.
##   * The forced march — beyond advance_range px he rides advance_speed_mult
##       faster (he never kites and is never left behind).
## On death: an XP burst (reward_xp in reward_crystals) and the miniboss chest.
## No RNG. Stats: general_spawned, general_charges, general_charge_hits_summon,
## general_charge_hits_player, general_riders_called, general_rage_at,
## general_kills, general_ttk.
class_name GeneralKit
extends KibaKit

## Seconds until his riders may be called again.
var riders_cd: float = 0.0
## True once he raged (below rage_hp).
var raged: bool = false
## His riders (the Kiba-musha he called) and their generations.
var _riders: Array[Enemy] = []
## Generation of each rider when it was called.
var _rider_gen: PackedInt32Array = PackedInt32Array()
## Walking speed before the forced march (px/s; -1 = not read yet).
var _base_speed: float = -1.0
## Game time he arrived (time-to-kill stat).
var _spawned_at: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	charge_cd = 2.0
	riders_cd = float(def["riders_every"]) * 0.5
	raged = false
	_riders.clear()
	_rider_gen = PackedInt32Array()
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("general_spawned", 1.0)


func stat_prefix() -> String:
	return "general"


func charge_source() -> String:
	return KuroganeEnemyData.GENERAL_CHARGE_SOURCE


func charges_in_row(e: Enemy) -> int:
	if not raged and e.hp <= e.max_hp * float(d["rage_hp"]):
		raged = true
		e.game.stat_add("general_rage_at", e.game.elapsed)
		e.game.enemies.show_banner("The General of the Left spurs his horse: he charges again and again!")
	return int(d["rage_charges"]) if raged else 1


## After a chain of charges: his riders when they are due.
func on_charge_end(e: Enemy) -> void:
	if riders_cd > 0.0 or _riders_alive() >= int(d["riders_max_alive"]):
		return
	riders_cd = float(d["riders_every"])
	var g := e.game
	var n := int(d["riders_count"])
	var side := _dir.orthogonal()
	var called := 0
	for i in n:
		if g.enemies.regular_alive() >= g.enemies.hard_cap():
			break
		var at := e.position + side * (float(i) - float(n - 1) * 0.5) * 34.0 - _dir * 30.0
		var r := g.enemies.spawn_at(KuroganeEnemyData.KIBA_MUSHA, at, false)
		_riders.append(r)
		_rider_gen.append(r.generation)
		called += 1
	g.stat_add("general_riders_called", float(called))
	g.effects.ring(e.position, 70.0, Palette.SHOGUN_LACQUER_LIGHT, 0.4)
	rules(e).play_sound("taiko_hit", e.position)


## The charge machine, the riders' timer and the forced march.
func physics(e: Enemy, delta: float) -> bool:
	riders_cd -= delta
	e.knockback = Vector2.ZERO  # Like a boss: blows do not shove his horse.
	if _base_speed < 0.0:
		_base_speed = e.move_speed
	if phase == IDLE:
		var far := e.position.distance_to(e.game.player.position) > float(d["advance_range"])
		e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if far else 1.0)
	return super.physics(e, delta)


## His riders still riding (stale entries dropped).
func _riders_alive() -> int:
	var i := 0
	while i < _riders.size():
		if _riders[i].active and _riders[i].generation == _rider_gen[i]:
			i += 1
		else:
			_riders.remove_at(i)
			_rider_gen.remove_at(i)
	return _riders.size()


## The XP burst, banner and stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (26.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.SHOGUN_LACQUER_LIGHT)
	g.shake(10.0)
	g.enemies.show_banner("The General of the Left falls from his horse: the left wing breaks!")
	g.stat_add("general_kills", 1.0)
	g.stat_add("general_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)
