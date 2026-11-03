## SoulCaster — the Soul Caster spell (AbilityData "soul_caster"; Act IX, the
## Proving Moon; GDD §15.0 "Soul Caster, Apex Predator, Trophy Rack and the
## Blooded (Act IX)"; owner-approved proposal: "a shoulder cannon that locks
## three targets with three dots and fires"; unlocked by slaying Vrask'Tal,
## then offered on every stage at the later-item card weight). Every `cooldown`
## s a shoulder cannon over the necromancer LOCKS up to `targets` enemies
## within `range` px (the strongest first: the most HP left, then the nearest;
## plus the Blooded's First Blood, innate value soul_caster_extra_targets):
## three dots in the spell's own soul colour (SoulCasterData.SOUL_COLOR, never
## the Vrask's red) sit on each for `lock` s, then it FIRES: `damage` to each
## locked target still standing (CombatResolver.damage_enemy(), a spell
## source: it reveals cloaked hunters and burns the alien turf like every
## spell). TROPHY RACK (the paired passive): every enemy its shots kill hangs a
## trophy, +trophy_dmg of its damage each, up to trophy_cap trophies (for the
## run). Evolved into APEX PREDATOR (EvolutionData "apex_predator", detected by
## the "refund" key): more targets and damage, elites, minibosses and bosses
## take x elite_mult, and every kill gives back `refund` s of its cooldown.
## Works the same on every stage (no act rule).
## Determinism: no RNG; the targets are sorted by HP, distance, then position.
## Stats: soul_caster_locks, soul_caster_targets, soul_caster_shots,
## soul_caster_kills, soul_caster_trophies, soul_caster_refunds,
## soul_caster_extra; damage as dmg_soul_caster / dmg_apex_predator.
class_name SoulCaster
extends NecroSpell

## Locked targets (generation-checked).
var _locked: Array[Enemy] = []
## Pool generation of each entry of `_locked`.
var _locked_gen: PackedInt32Array = PackedInt32Array()
## Seconds left of the current lock (<= 0: no lock running).
var _lock_left: float = 0.0
## Seconds until the next lock may start.
var _cd: float = 0.0
## Trophies hung this run (Trophy Rack; counted even without the passive).
var trophies: int = 0
## Shots fading (drawn only): {from, to, t (game s)}.
var _shots: Array[Dictionary] = []
## The current effective stats (the last step's row).
var _stats: Dictionary = {}
## True once Apex Predator (drawing, the elite multiplier, the refund).
var _evolved: bool = false
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Locks on its cooldown; fires when the lock ends; fades the shots.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	_evolved = stats.has("refund")
	var now := game.elapsed
	var i := 0
	while i < _shots.size():
		if now >= float(_shots[i]["t"]) + SoulCasterData.SHOT_FADE:
			_shots.remove_at(i)
			continue
		i += 1
	if _lock_left > 0.0:
		_lock_left -= delta
		if _lock_left <= 0.0:
			_fire()
	else:
		_cd -= delta
		if _cd <= 0.0:
			_cd = float(stats["cooldown"]) if _lock() else SoulCasterData.WAIT_RETRY
	var busy := _lock_left > 0.0 or not _shots.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## The lock: the strongest enemies in range (see the header). False when none.
func _lock() -> bool:
	var at := game.player.position
	var r := float(_stats["range"])
	var extra := roundi(game.character.innate_value(SoulCasterData.EXTRA_TARGETS_KEY))
	var n := int(_stats["targets"]) + extra
	var found: Array = []  # Own buffer.
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, found)
	var cands: Array = []  # [hp left, distance, enemy].
	for e: Enemy in found:
		if not is_open_target(e) or e.position.distance_to(at) > r + e.radius:
			continue
		cands.append([e.hp - e.incoming_damage, e.position.distance_to(at), e])
	if cands.is_empty():
		return false
	cands.sort_custom(func(a: Array, b: Array) -> bool:
		if float(a[0]) != float(b[0]):
			return float(a[0]) > float(b[0])
		if float(a[1]) != float(b[1]):
			return float(a[1]) < float(b[1])
		var pa := (a[2] as Enemy).position
		var pb := (b[2] as Enemy).position
		return pa.x < pb.x or (pa.x == pb.x and pa.y < pb.y))
	_locked.clear()
	_locked_gen.clear()
	for k in mini(n, cands.size()):
		var e: Enemy = cands[k][2]
		_locked.append(e)
		_locked_gen.append(e.generation)
	_lock_left = float(_stats["lock"])
	game.stat_add("soul_caster_locks", 1.0)
	game.stat_add("soul_caster_targets", float(_locked.size()))
	if extra > 0:
		game.stat_add("soul_caster_extra", float(extra))
	return true


## The shot: each locked target still standing takes the damage (x Trophy
## Rack's trophies; x elite_mult on elites and bosses once evolved); each kill
## hangs a trophy (and, evolved, gives back `refund` s of the cooldown).
func _fire() -> void:
	var src := SoulCasterData.EVOLVED_SOURCE if _evolved else SoulCasterData.SOURCE
	var ab := game.abilities
	var cap := int(ab.passive_value(SoulCasterData.TROPHY_RACK, SoulCasterData.TROPHY_CAP_KEY))
	var per := ab.passive_value(SoulCasterData.TROPHY_RACK, SoulCasterData.TROPHY_DMG_KEY)
	var dmg := float(_stats["damage"]) * (1.0 + per * float(mini(trophies, cap)))
	var from := game.player.position + SoulCasterData.SHOULDER
	for k in _locked.size():
		var e := _locked[k]
		if not e.active or e.generation != _locked_gen[k]:
			continue
		var hit := dmg
		if _evolved and (e.is_elite or e.is_boss or e.is_miniboss):
			hit *= float(_stats["elite_mult"])
		var gen := e.generation
		_shots.append({"from": from, "to": e.position, "t": game.elapsed})
		game.combat.damage_enemy(e, hit, src)
		game.stat_add("soul_caster_shots", 1.0)
		if not e.active or e.generation != gen:
			trophies += 1
			game.stat_add("soul_caster_kills", 1.0)
			if per > 0.0 and trophies <= cap:
				game.stat_add("soul_caster_trophies", 1.0)
			if _evolved:
				_cd -= float(_stats["refund"])
				game.stat_add("soul_caster_refunds", 1.0)
	_locked.clear()
	_locked_gen.clear()
	Sfx.play("lance_cast", from, 0.8)  # A startup-bank sound: the spell plays on every stage.


## Autotest counters (ProvingMoonReport's Soul Caster line).
func summary_extra() -> String:
	var st := game.stats
	return "locks=%d targets=%d (extra %d) shots=%d kills=%d trophies=%d refunds=%d" % [int(st.get("soul_caster_locks", 0.0)),
		int(st.get("soul_caster_targets", 0.0)), int(st.get("soul_caster_extra", 0.0)), int(st.get("soul_caster_shots", 0.0)),
		int(st.get("soul_caster_kills", 0.0)), int(st.get("soul_caster_trophies", 0.0)), int(st.get("soul_caster_refunds", 0.0))]


## The lock's three soul dots on each target (they close in as the lock ends),
## then each shot's fading line. Textures only (a stretched disc for the line).
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	if _lock_left > 0.0:
		var full := maxf(0.01, float(_stats.get("lock", 0.6)))
		var k := clampf(_lock_left / full, 0.0, 1.0)  # 1 at the lock's start, 0 at the shot.
		var spread := SoulCasterData.DOT_SPREAD * (0.5 + k)
		for i in _locked.size():
			var e := _locked[i]
			if not e.active or e.generation != _locked_gen[i]:
				continue
			for j in 3:
				var p := e.position + Vector2.from_angle(-PI * 0.5 + TAU * float(j) / 3.0) * spread
				SpriteBank.draw_disc(self, p, SoulCasterData.DOT_RADIUS + 0.8, Color(0.02, 0.05, 0.06, 0.8))
				SpriteBank.draw_disc(self, p, SoulCasterData.DOT_RADIUS, SoulCasterData.SOUL_COLOR)
	for s in _shots:
		var a := clampf(1.0 - (now - float(s["t"])) / SoulCasterData.SHOT_FADE, 0.0, 1.0)
		var from: Vector2 = s["from"]
		var to: Vector2 = s["to"]
		var d := to - from
		var len := d.length()
		if len < 1.0:
			continue
		draw_set_transform(from, d.angle(), Vector2.ONE)
		draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(0.0, -2.0), Vector2(len, 4.0)), false, Color(SoulCasterData.SOUL_COLOR, 0.85 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		SpriteBank.draw_disc(self, to, 5.0 * a + 2.0, Color(SoulCasterData.SOUL_COLOR, 0.6 * a))
