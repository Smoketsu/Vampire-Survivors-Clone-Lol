## LinenBind — the Linen Bind spell (AbilityData "linen_bind"; temporary Act
## XII, the Necropolis of Sand; GDD §15.0 "Linen Bind, Eternal Shroud, Natron
## Salts and the Embalmer (Act XII)"; owner-approved proposal: "spectral
## bandages wrap up to 5 enemies and hold them 1.2 s; wrapped enemies that die
## rise as temporary Mummies"; the brief: "through HordeDirector.raise_corpse(),
## so they also steal Names"; unlocked by slaying Anubis, then offered on
## every stage at the later-item card weight). Every `cooldown` s spectral
## bandages WRAP up to `targets` foes within `range` px of the necromancer
## (the nearest first; structures, cartouches and jars are never wrapped):
## each takes `damage` (CombatResolver.damage_enemy(), a spell source) and is
## HELD `hold` s (CombatResolver.stun_enemy(), the one enemy stun path: x
## BOSS_HOLD_MULT on bosses and minibosses, x ELITE_HOLD_MULT on elites), and
## stays WRAPPED `mark` s. A wrapped foe that dies leaving a corpse
## (Enemy.leaves_corpse(): never a structure or a machine) RISES as a
## temporary MUMMY of the necromancer's (HordeDirector.raise_corpse(), THE one
## raise path, the next tick: on the Dynasty it steals the cartouche's Name
## there; a cyborg rises as a Grave Gunner), `life` s (+ the Embalmer's Linen
## Ward, innate value linen_mummy_life), at most `cap` alive (the rest are
## counted and skipped). NATRON SALTS (the paired passive): every binding hits
## bind_bonus harder and holds hold_bonus s longer (0 while not owned).
## Evolved into ETERNAL SHROUD (EvolutionData "eternal_shroud", detected by the
## "burst_wraps" key): more foes, longer holds and Mummies, and when a risen
## Mummy falls (killed or crumbled) its bandages burst and WRAP burst_wraps
## more foes within burst_reach px of where it stood (held and marked the
## same, so the shroud feeds itself). Works the same on every stage (no act
## rule). Determinism: no RNG; the targets are sorted by distance, then
## position. Stats: linen_casts, linen_wraps, linen_held_s, linen_risen,
## linen_risen_capped, linen_shroud_bursts, linen_shroud_wraps,
## linen_natron_bonus_dmg; damage as dmg_linen_bind / dmg_eternal_shroud.
class_name LinenBind
extends NecroSpell

## Wrapped foes: [enemy, its generation, game time the wrap ends].
var _marks: Array = []
## Corpses to raise next tick: [position, rises as a Grave Gunner].
var _pending: Array = []
## Risen Mummies: [unit, its generation, last position].
var _risen: Array = []
## Bandage lines fading (drawn only): [from, to, game time cast].
var _lines: Array = []
## Seconds until the next cast.
var _cd: float = 0.0
## The current effective stats (the last step's row).
var _stats: Dictionary = {}
## True once Eternal Shroud.
var _evolved: bool = false
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Casts on its cooldown; raises the pending corpses; tracks the risen;
## fades the lines and the marks.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	_evolved = stats.has("burst_wraps")
	var now := game.elapsed
	_age(now)
	if not _pending.is_empty():
		_raise_pending()
	_track_risen()
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _cast(game.player.position, int(stats["targets"]), float(stats["range"]), false) > 0 else LinenBindData.WAIT_RETRY
	var busy := not _lines.is_empty() or not _marks.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## THE KILL HOOK (NecroSpellBook.on_enemy_killed()): a wrapped foe `e` fell;
## if it leaves a corpse it rises next tick.
func on_enemy_killed(e: Enemy) -> void:
	for i in _marks.size():
		var m: Array = _marks[i]
		if m[0] == e and int(m[1]) == e.generation:
			_marks.remove_at(i)
			if e.is_boss or not e.leaves_corpse():
				return
			_pending.append([e.position, e.rises_as_gunner()])
			return


## The binding: up to `n` foes within `r` px of `at` (the nearest first; no
## structures, nothing already wrapped) are struck, held and wrapped. `burst`:
## an Eternal Shroud burst (counted apart). Returns how many were wrapped.
func _cast(at: Vector2, n: int, r: float, burst: bool) -> int:
	var found: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, found)
	var cands: Array = []  # [distance, enemy].
	for e: Enemy in found:
		if not is_open_target(e) or e.is_structure or e.untargetable or e.position.distance_to(at) > r + e.radius:
			continue
		if _is_marked(e):
			continue
		cands.append([e.position.distance_to(at), e])
	if cands.is_empty():
		return 0
	cands.sort_custom(func(a: Array, b: Array) -> bool:
		if float(a[0]) != float(b[0]):
			return float(a[0]) < float(b[0])
		var pa := (a[1] as Enemy).position
		var pb := (b[1] as Enemy).position
		return pa.x < pb.x or (pa.x == pb.x and pa.y < pb.y))
	var ab := game.abilities
	var bonus := ab.passive_value(LinenBindData.NATRON_SALTS, LinenBindData.NATRON_DMG_KEY)
	var dmg := float(_stats["damage"]) * (1.0 + bonus) * (0.5 if burst else 1.0)
	var hold := float(_stats["hold"]) + ab.passive_value(LinenBindData.NATRON_SALTS, LinenBindData.NATRON_HOLD_KEY)
	var src := LinenBindData.EVOLVED_SOURCE if _evolved else LinenBindData.SOURCE
	var made := 0
	for k in mini(n, cands.size()):
		var e: Enemy = cands[k][1]
		if not e.active:
			continue
		_marks.append([e, e.generation, game.elapsed + float(_stats["mark"])])
		_lines.append([at, e.position, game.elapsed])
		var gen := e.generation
		if bonus > 0.0:
			game.stat_add("linen_natron_bonus_dmg", float(_stats["damage"]) * bonus * (0.5 if burst else 1.0))
		game.combat.damage_enemy(e, dmg, src)
		if e.active and e.generation == gen:
			game.stat_add("linen_held_s", game.combat.stun_enemy(e, hold, LinenBindData.BOSS_HOLD_MULT, LinenBindData.ELITE_HOLD_MULT))
		made += 1
	while _marks.size() > LinenBindData.MAX_MARKS:
		_marks.remove_at(0)
	game.stat_add("linen_shroud_wraps" if burst else "linen_wraps", float(made))
	if not burst:
		game.stat_add("linen_casts", 1.0)
		Sfx.play("summon_rise", at, 0.6)  # A startup-bank sound: the spell plays on every stage.
	return made


## True while foe `e` is wrapped.
func _is_marked(e: Enemy) -> bool:
	for m: Array in _marks:
		if m[0] == e and int(m[1]) == e.generation:
			return true
	return false


## Drops the faded lines and the ended or stale marks.
func _age(now: float) -> void:
	var i := _lines.size() - 1
	while i >= 0:
		if now - float(_lines[i][2]) > LinenBindData.LINE_FADE:
			_lines.remove_at(i)
		i -= 1
	i = _marks.size() - 1
	while i >= 0:
		var m: Array = _marks[i]
		var e: Enemy = m[0]
		if now > float(m[2]) or not e.active or e.generation != int(m[1]):
			_marks.remove_at(i)
		i -= 1


## Raises the pending corpses as Mummies, up to `cap` alive (the rest skipped).
func _raise_pending() -> void:
	var todo := _pending.duplicate()  # Raising never queues more, but stay safe.
	_pending.clear()
	var cap := int(_stats.get("cap", 4))
	var life := float(_stats["life"]) + game.character.innate_value(LinenBindData.EXTRA_LIFE_KEY)
	for p: Array in todo:
		if _risen.size() >= cap:
			game.stat_add("linen_risen_capped", 1.0)
			continue
		var pos: Vector2 = p[0]
		var u := game.horde.raise_corpse(LinenBindData.RISEN_CLASS, pos, life, LinenBindData.RISEN_HP,
				LinenBindData.RISEN_DAMAGE, LinenBindData.RISEN_TAG, LinenBindData.RISEN_GLYPH, bool(p[1]))
		_risen.append([u, u.generation, u.position])
		game.effects.ring(u.position, 20.0, LinenBindData.GLOW_COLOR, 0.5)
		game.stat_add("linen_risen", 1.0)


## Follows the risen Mummies; one that fell (killed or crumbled) bursts into
## bandages once evolved (Eternal Shroud).
func _track_risen() -> void:
	var i := _risen.size() - 1
	while i >= 0:
		var r: Array = _risen[i]
		var u: SummonedUnit = r[0]
		if u.active and u.generation == int(r[1]) and u.state != SummonedUnit.State.DEAD:
			r[2] = u.position
		else:
			_risen.remove_at(i)
			if _evolved and not _stats.is_empty():
				game.stat_add("linen_shroud_bursts", 1.0)
				game.effects.ring(r[2], float(_stats["burst_reach"]), LinenBindData.LINEN_COLOR, 0.35)
				_cast(r[2], int(_stats["burst_wraps"]), float(_stats["burst_reach"]), true)
		i -= 1


## Autotest counters (NecropolisReport's Linen Bind line).
func summary_extra() -> String:
	var st := game.stats
	return "casts=%d wraps=%d held=%.0fs risen=%d (capped %d) shroud bursts=%d (wraps %d) natron=%d" % [
		int(st.get("linen_casts", 0.0)), int(st.get("linen_wraps", 0.0)), float(st.get("linen_held_s", 0.0)),
		int(st.get("linen_risen", 0.0)), int(st.get("linen_risen_capped", 0.0)),
		int(st.get("linen_shroud_bursts", 0.0)), int(st.get("linen_shroud_wraps", 0.0)),
		int(st.get("linen_natron_bonus_dmg", 0.0))]


## The bandage lines of the last casts and a band of linen round every
## wrapped foe (thin rects: no polygons redrawn every frame).
func _draw() -> void:
	var now := game.elapsed
	for ln: Array in _lines:
		var k := 1.0 - clampf((now - float(ln[2])) / LinenBindData.LINE_FADE, 0.0, 1.0)
		draw_line(ln[0], ln[1], Color(LinenBindData.GLOW_COLOR, 0.5 * k), 3.0)
		draw_line(ln[0], ln[1], Color(LinenBindData.LINEN_COLOR, 0.9 * k), 1.0)
	for m: Array in _marks:
		var e: Enemy = m[0]
		if not e.active or not e.visible:
			continue
		var w := e.radius * 2.2
		var c := e.position + Vector2(-w * 0.5, -e.radius * 0.6)
		draw_rect(Rect2(c, Vector2(w, 2.0)), Color(LinenBindData.LINEN_COLOR, 0.85))
		draw_rect(Rect2(c + Vector2(0.0, e.radius * 0.7), Vector2(w, 2.0)), Color(LinenBindData.LINEN_COLOR, 0.85))
		draw_rect(Rect2(c + Vector2(0.0, -1.0), Vector2(w, 1.0)), Color(LinenBindData.GLOW_COLOR, 0.6))
