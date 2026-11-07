## LilithHazards — Lilith's world-space pieces (Act VI, the Palace of Silk and
## Ash; GDD §15.0 "Lilith, Queen of the Night (Act VI)"), a child of the
## EnemyDirector made by BossLilith (numbers in LilithData.BOSS):
##   * THE KISS: hearts she blows at the necromancer fly straight (kiss_speed
##     px/s, kiss_range px). The first SUMMON a heart touches catches it (the
##     Bone Ring body-blocks it: it breaks harmlessly); a NECROMANCER it touches
##     is MARKED for mark_time s (Necromancer.kiss_marked_until, read by the one
##     heal path, CombatResolver.heal_player(): every heal on him turned into
##     damage). In co-op it marks whichever necromancer it reaches.
##   * Drawing only: the charm wave's arc of hearts on the ground while it is
##     marked (BossLilith's wave fields), the wing storm's ring of feathers, and
##     a pink broken heart over every marked necromancer.
## Determinism: no RNG; a heart checks the summons in the ally grid's fixed
## order. Stats: lilith_kisses_blocked, lilith_kisses_landed,
## lilith_kisses_missed (LilithData.KISS_SOURCE damage is CombatResolver's).
class_name LilithHazards
extends Node2D

## One flying heart.
class Heart:
	extends RefCounted
	## World position (px).
	var pos: Vector2 = Vector2.ZERO
	## Unit direction of its flight.
	var dir: Vector2 = Vector2.RIGHT
	## Distance (px) of flight left.
	var left: float = 0.0

## Owning run.
var game: Game
## The boss (her data and her wave / storm fields for the drawing).
var boss: BossLilith = null
## Hearts in flight.
var hearts: Array[Heart] = []
## The upper layer (the hearts and the marks over the bodies).
var _over: Node2D = null
## True when this build draws (never headless).
var _draws: bool = false
## Reusable query buffer.
var _buf: Array = []


func _ready() -> void:
	z_index = -1  # The wave's arc lies on the ground.
	_draws = DisplayServer.get_name() != "headless"
	_over = Node2D.new()
	_over.z_index = 19  # Above the bodies (like the Draw lines).
	_over.z_as_relative = false
	add_child(_over)
	_over.draw.connect(_draw_over)


## A heart blown from `from` along `dir` (BossLilith's kiss).
func blow(from: Vector2, dir: Vector2) -> void:
	var h := Heart.new()
	h.pos = from
	h.dir = dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	h.left = float(boss.boss_def["kiss_range"])
	hearts.append(h)


## Per-tick update (BossLilith.physics_step()): the hearts fly and land.
func step(delta: float) -> void:
	var b := boss.boss_def
	var hit := float(b["kiss_hit"])
	var i := hearts.size() - 1
	while i >= 0:
		var h := hearts[i]
		var stepd := minf(float(b["kiss_speed"]) * delta, h.left)
		h.pos += h.dir * stepd
		h.left -= stepd
		if _caught(h, hit):
			hearts.remove_at(i)
		elif h.left <= 0.0:
			game.stat_add("lilith_kisses_missed", 1.0)
			hearts.remove_at(i)
		i -= 1
	if _draws:
		queue_redraw()
		_over.queue_redraw()


## True when heart `h` landed: on a summon (blocked) or on a necromancer (marked).
func _caught(h: Heart, hit: float) -> bool:
	game.ally_grid.query(h.pos, hit + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.airborne or u.charmed or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING:
			continue
		if u.position.distance_to(h.pos) <= hit + u.radius:
			game.stat_add("lilith_kisses_blocked", 1.0)
			game.effects.pop(h.pos, Palette.INFERNO_CHARM_LIGHT, 10.0)
			return true
	for pl in game.all_players:
		if pl.dead or pl.position.distance_to(h.pos) > hit + pl.radius:
			continue
		if game.ultimates.player_untargetable():
			continue  # Sovereign's Decree: the kiss passes through him.
		pl.kiss_marked_until = game.elapsed + float(boss.boss_def["mark_time"])
		game.stat_add("lilith_kisses_landed", 1.0)
		game.effects.ring(pl.position, 26.0, Palette.INFERNO_CHARM, 0.4)
		if game.inferno != null:
			game.inferno.play_sound("charm_kiss", pl.position)
		return true
	return false


## Every heart drops (her death).
func clear_all() -> void:
	hearts.clear()
	queue_redraw()
	_over.queue_redraw()


## Autopilot hint: sideways off a heart's path while it flies at him.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for h in hearts:
		var rel := p - h.pos
		var along := rel.dot(h.dir)
		if along < 0.0 or along > 160.0:
			continue
		var side := rel - h.dir * along
		if side.length() < 30.0:
			push += (side.normalized() if side.length() > 0.5 else h.dir.orthogonal()) * 2.0
	return push


## Ground layer: the charm wave's arc of hearts and the wing storm's ring.
## Visual only.
func _draw() -> void:
	if boss == null or not boss.active:
		return
	if boss.wave_marked():
		var k := boss.wave_progress()  # 0 .. 1 over the cast.
		var col := Color(Palette.INFERNO_CHARM, 0.35 + 0.5 * k)
		var c := boss.wave_center
		var a0 := boss.wave_dir.angle()
		var half := boss.wave_half
		var inner := float(boss.boss_def["wave_inner"])
		var outer := float(boss.boss_def["wave_outer"])
		var n := LilithData.ARC_HEARTS
		for i in n + 1:
			var a := a0 - half + 2.0 * half * float(i) / float(n)
			InfernoGlyphs.draw_heart(self, c + Vector2.from_angle(a) * outer, 4.0, col)  # The outer edge.
			InfernoGlyphs.draw_heart(self, c + Vector2.from_angle(a) * inner, 3.0, col)  # The inner edge.
		for j in 4:
			var r := lerpf(inner, outer, float(j + 1) / 5.0)
			InfernoGlyphs.draw_heart(self, c + Vector2.from_angle(a0 - half) * r, 3.0, col)  # The two side edges.
			InfernoGlyphs.draw_heart(self, c + Vector2.from_angle(a0 + half) * r, 3.0, col)
		var mid := c + Vector2.from_angle(a0) * (inner + outer) * 0.5
		draw_texture_rect(SpriteBank.disc(), Rect2(mid - Vector2(40, 40), Vector2(80, 80)), false, Color(Palette.INFERNO_CHARM, 0.12 * k))
	if boss.storm_marked():
		var r := float(boss.boss_def["storm_radius"])
		var k2 := boss.storm_progress()
		for i in 24:
			var a := TAU * float(i) / 24.0 + k2 * 0.6
			SpriteBank.draw_disc(self, boss.position + Vector2.from_angle(a) * r, 2.5, Color(Palette.INFERNO_DEMON_LIGHT, 0.4 + 0.5 * k2))


## Upper layer: the flying hearts and the broken heart over a marked
## necromancer. Visual only.
func _draw_over() -> void:
	for h in hearts:
		InfernoGlyphs.draw_heart(_over, h.pos, 6.0, Palette.INFERNO_CHARM)
		InfernoGlyphs.draw_heart(_over, h.pos - h.dir * 9.0, 3.0, Color(Palette.INFERNO_CHARM_LIGHT, 0.6))
	for pl in game.all_players:
		if pl.kiss_marked_until > game.elapsed:
			var blink := 0.6 + 0.4 * float(int(game.elapsed * 6.0) % 2)
			InfernoGlyphs.draw_heart(_over, pl.position + Vector2(0, -pl.radius * 3.2), 5.0, Color(Palette.INFERNO_CHARM, blink))
			_over.draw_line(pl.position + Vector2(-2, -pl.radius * 3.2 - 4), pl.position + Vector2(2, -pl.radius * 3.2 + 3), Palette.INFERNO_OBSIDIAN_INK, 1.0)  # The crack.
