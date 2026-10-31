## LastJudgment — THE LAST JUDGMENT, the shared Act VI Reckoning (GDD §15.0
## "Act VI foundation (phase 1)"; owner-approved proposal: "Reckoning, the Last
## Judgment: at 0:00 every portal opens at once, the ground turns to pits, and
## the Adversary's hand reaches up through the floor"), owned by Game.inferno.
## On a stage whose RECKONING has a "last_judgment" dictionary (its keys
## override InfernoRulesData.LAST_JUDGMENT; absent = off), from 0:00:
##   * EVERY PORTAL OPENS AT ONCE: `portals` new portals around each standing
##     necromancer (DemonPortals.open(), opts "reckoning"), and every portal
##     pours at pour_mult x its interval (DemonPortals reads it);
##   * THE GROUND TURNS TO PITS: HellPits opens its telegraphed pits on this
##     clock instead (pit_interval(): pit_every, x pit_speedup per minute past
##     0:00, down to pit_every_min);
##   * THE ADVERSARY'S HAND: every hand_every s (x hand_speedup per minute, down
##     to hand_every_min) a telegraphed grab (the shared telegraph circle for
##     hand_windup s) under the necromancer (a hand_on_player share of the
##     grabs) or a seeded summon of his army; then the hand reaches up and hits
##     what is under it through CombatResolver: the necromancer, the summons,
##     and every enemy the pits would burn (HellPits.burns_enemy(): demons are
##     spared). The Reckoning's heavy (demon_brute) is the stage's RECKONING
##     "kind", spawned by EnemyDirector like every Reckoning.
## Drawn above the bodies (a claw reaching up for a moment); nothing headless.
## Determinism: the seeded gameplay RNG only, only in an Act VI Reckoning.
## Stats: judgment_portals, hand_grabs, hand_hits_you, hand_hits_summons,
## hand_hits_enemies, hand_dodged.
class_name LastJudgment
extends Node2D

## Owning run.
var game: Game
## The Last Judgment's numbers ({} = off on this stage).
var cfg: Dictionary = {}
## True once 0:00 passed and the Last Judgment began.
var started: bool = false
## Game time (s) it began.
var started_at: float = 0.0
## Game time (s) of the next grab.
var _next_hand: float = 0.0
## Pending grabs: world point (px) of each.
var _hand_at: PackedVector2Array = PackedVector2Array()
## Game time (s) each pending grab lands.
var _hand_due: PackedFloat32Array = PackedFloat32Array()
## 1 when the necromancer stood in the grab as it was aimed (the "dodged" count).
var _hand_aimed: PackedByteArray = PackedByteArray()
## Recent grabs drawn as a claw: [world point, until (game s)] each.
var _claws: Array = []
## Grid query buffer.
var _tmp: Array = []
## True when this build draws (never headless).
var _draws: bool = false
## True if the last redraw showed something.
var _drawn: bool = false


## Builds the Last Judgment for `p_game` (InfernoRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "LastJudgment"
	z_index = 18  # Above the bodies: the hand reaches up over them.
	z_as_relative = false
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if bool(p_game.stage_def.get("inferno", false)) and r.has("last_judgment"):
		cfg = InfernoRulesData.LAST_JUDGMENT.duplicate()
		var over: Dictionary = r["last_judgment"]
		for key: String in over:
			cfg[key] = over[key]
	_draws = DisplayServer.get_name() != "headless"


## True while the Last Judgment runs (after 0:00 on a stage that has one).
func running() -> bool:
	return started


## Minutes past 0:00 (0 before).
func _minutes() -> float:
	return maxf(0.0, game.elapsed - started_at) / 60.0 if started else 0.0


## Seconds between two telegraphed pits in the Last Judgment (HellPits).
func pit_interval() -> float:
	return maxf(float(cfg["pit_every_min"]), float(cfg["pit_every"]) * pow(float(cfg["pit_speedup"]), _minutes()))


## Seconds between two grabs of the hand now.
func _hand_interval() -> float:
	return maxf(float(cfg["hand_every_min"]), float(cfg["hand_every"]) * pow(float(cfg["hand_speedup"]), _minutes()))


## Per-tick update (InfernoRules.step()).
func step(_delta: float) -> void:
	if cfg.is_empty():
		return
	if not started:
		if game.countdown_finished():
			_begin()
		return
	var now := game.elapsed
	if now >= _next_hand:
		_aim_hand()
		_next_hand = now + _hand_interval()
	var i := 0
	while i < _hand_at.size():
		if now >= _hand_due[i]:
			_grab(i)
			_hand_at.remove_at(i)
			_hand_due.remove_at(i)
			_hand_aimed.remove_at(i)
			continue
		i += 1
	var k := _claws.size() - 1
	while k >= 0:
		if now >= float(_claws[k][1]):
			_claws.remove_at(k)
		k -= 1
	if _draws:
		var busy := not _claws.is_empty()
		if busy or _drawn:
			queue_redraw()
		_drawn = busy


## 0:00: every portal opens at once around each standing necromancer.
func _begin() -> void:
	started = true
	started_at = game.elapsed
	_next_hand = game.elapsed + float(cfg["hand_every"]) * 0.5
	var n := int(cfg["portals"])
	for pl in game.all_players:
		if pl.dead:
			continue
		var offset := randf() * TAU
		for k in n:
			var at := game.arena.free_point(pl.position + Vector2.from_angle(offset + TAU * float(k) / float(maxi(1, n))) * float(cfg["portal_dist"]), 24.0)
			if game.inferno.portals.open(at, {"reckoning": true, "pour_first": 1.0}) != null:
				game.stat_add("judgment_portals", 1.0)


## Aims one grab: under a necromancer, or under a seeded summon of an army.
func _aim_hand() -> void:
	var at := Vector2.INF
	var alive: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			alive.append(pl)
	if alive.is_empty():
		return
	var pl: Necromancer = alive[randi() % alive.size()]
	if randf() >= float(cfg["hand_on_player"]):
		var units := game.horde.units if game.coop == null else game.coop.slots[game.coop.slot_of(pl)].horde.units  # His army.
		var picks: Array[SummonedUnit] = []
		for u in units:
			if u.active and not u.charmed and not u.airborne:
				picks.append(u)
		if not picks.is_empty():
			at = picks[randi() % picks.size()].position
	if at == Vector2.INF:
		at = pl.position
	var r := float(cfg["hand_radius"])
	var windup := float(cfg["hand_windup"])
	_hand_at.append(at)
	_hand_due.append(game.elapsed + windup)
	var aimed := 0
	for p in game.all_players:
		if not p.dead and p.position.distance_to(at) <= r + p.radius:
			aimed = 1
	_hand_aimed.append(aimed)
	game.effects.telegraph_circle(at, r, windup)
	game.stat_add("hand_grabs", 1.0)


## Grab `i` lands: the hand hits what is under it.
func _grab(i: int) -> void:
	var at := _hand_at[i]
	var r := float(cfg["hand_radius"])
	var dm := game.enemies.damage_mult
	var src := InfernoRulesData.HAND_SOURCE
	var hit_you := false
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(at) <= r + pl.radius:
			game.combat.damage_player(float(cfg["hand_dmg_player"]) * dm, src, pl)
			game.stat_add("hand_hits_you", 1.0)
			hit_you = true
	if _hand_aimed[i] == 1 and not hit_you:
		game.stat_add("hand_dodged", 1.0)
	game.ally_grid.query(at, r + PantheonRulesData.SUMMON_SLACK, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.DEAD or u.position.distance_to(at) > r + u.radius:
			continue
		game.combat.damage_unit(u, float(cfg["hand_dmg_summon"]) * dm, src)
		game.stat_add("hand_hits_summons", 1.0)
	game.enemy_grid.query(at, r + 24.0, _tmp)
	for e: Enemy in _tmp:
		if HellPits.burns_enemy(e) and e.position.distance_to(at) <= r + e.radius:
			game.combat.damage_enemy(e, float(cfg["hand_dmg_enemy"]) * game.enemies.hp_mult, src)
			game.stat_add("hand_hits_enemies", 1.0)
	game.effects.impact(at, r, Palette.INFERNO_LAVA)
	game.shake(3.0)
	if game.inferno != null:
		game.inferno.play_sound("hand_grab", at)
	_claws.append([at, game.elapsed + 0.45])


## Autopilot hint (the autotest bot): out of every pending grab.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var reach := float(cfg.get("hand_radius", 0.0)) + 18.0 + game.player.radius
	for at in _hand_at:
		push += HellPits._push_from(p, at, reach)
	return push


## Draws each fresh grab: a dark claw of four fingers reaching up out of the
## floor, fading. Visual only.
func _draw() -> void:
	var now := game.elapsed
	for c: Array in _claws:
		var k := clampf((float(c[1]) - now) / 0.45, 0.0, 1.0)  # 1 fresh .. 0 gone.
		InfernoGlyphs.draw_hand(self, c[0], float(cfg["hand_radius"]), k)
