## LongWinter — THE LONG WINTER, the first of the Hall of the Slain's shared
## rules (the Norse act, temporarily Act XI; GDD §15.0 "The Long Winter"; owner
## decision Nov 7, 2026, replacing the proposal's Choosing: "The cold closes in
## ... Braziers are warmth ... Outside warmth, the necromancer's side suffers,
## the Norse do not ... Braziers go out"), owned by Game.norse as `winter`. THE
## ONE PATH of the cold and of every brazier (a brazier is not an Enemy: nothing
## targets, hurts or kills it; it is placed, drawn and run here):
##   * THE COLD LEVEL rises with the 20:00 clock: level() = game time /
##     step_every, at most max_level (0 at the start; a banner each step).
##   * BRAZIERS: `count` lit braziers placed at the run's first step (the
##     STAGE "long_winter" "points": offsets from the start, else a seeded ring
##     between ring_min and ring_max px), moved out of obstacles and kept clear
##     of new ones (Arena.keep_clear()); place(at) is THE public call (phase 2,
##     --spawn=brazier through BrazierKit). Within warm_radius px of a LIT
##     brazier everything is warm.
##   * OUT OF WARMTH (every `tick` s, each slot bound in co-op): the necromancer
##     and every summon of his army out of warmth are slowed by slow_by_level
##     of the level through TerrainSlow (THE one ground-slow path, as
##     Gullhaven's water: Brinewalker applies; a world rule, not a class rule),
##     the summons times the Fur-Lined Bones hook (fur_mult(), exactly 1 while
##     the counter-passive does not exist); from the level where bite_by_level
##     is above 0 the summons also take frostbite (that share of their max HP a
##     second, CombatResolver.damage_unit(), FROSTBITE_SOURCE). Norse kinds are
##     born to the cold: nothing here ever reads an enemy.
##   * DOUSING: a Norse kind whose row "douses" (the frost giant, the seer)
##     turns aside to a lit brazier within douse_seek px and stands at it
##     (NorseKit.douse_step()); a lit brazier with a douser within douse_radius
##     px gutters (a flicker, the douse's
##     telegraph); douse_time s of it staying within 1.5 x douse_radius puts the
##     brazier OUT.
##   * RELIGHTING: a standing necromancer within relight_radius px of a brazier
##     that is out fills its ring (relight_time s; drains at relight_decay s
##     per s when he leaves) and relights it; the first ash_relights_max
##     relights pay ash_per_relight Soul Ash through the objective bounty path
##     (stat "objective_ash").
##   * THE FROST: a vignette of frost creeping in from the view's edges, its band
##     frost_px x level / max_level wide (four TextureRects with a gradient on a
##     CanvasLayer: static, rebuilt only when the level changes; no shader reads
##     the screen). Never headless.
##   * The autotest bot's one cold behaviour: bot_point() (the nearest lit
##     brazier while the bot stands cold, else a doused one to relight).
## Off a Norse stage (a forced Norse kind made the rules) the cold stays at 0
## and no brazier is placed (one --spawn=brazier still burns).
## Determinism: game time and the seeded gameplay RNG only (the ring's angles
## and distances, once), only while the Norse rules exist. Stats:
## winter_level, braziers_placed, braziers_doused, braziers_doused_by_<kind>,
## braziers_relit, winter_relight_ash, winter_player_cold_s,
## winter_summon_cold_s (summon-seconds), frostbite_dmg (summon_dmg_from_
## frostbite), winter_slows.
class_name LongWinter
extends Node2D

## One brazier.
class Brazier:
	extends RefCounted
	## World position (px).
	var pos: Vector2 = Vector2.ZERO
	## True while it burns (warmth around it).
	var lit: bool = true
	## Relight progress (s of a necromancer standing by it while it is out).
	var relight: float = 0.0
	## Douse progress (s of a douser standing by it while it gutters).
	var douse: float = 0.0
	## The enemy dousing it (null when none).
	var douser: Enemy = null
	## Generation of `douser` when it began (stale guard).
	var douser_gen: int = 0
	## Game time (s) it went out (only meaningful while out).
	var out_since: float = 0.0


## Owning run.
var game: Game
## The Long Winter's numbers (LONG_WINTER, then the stage's "long_winter").
var cfg: Dictionary = {}
## True on a Norse stage: the cold rises and the braziers are placed.
var enabled: bool = false
## The braziers, in placing order.
var braziers: Array[Brazier] = []
## The cold level now (0..max_level).
var level: int = 0
## Highest cold level reached this run.
var peak_level: int = 0
## Braziers doused this run.
var doused: int = 0
## Braziers relit this run.
var relit: int = 0
## Soul Ash the relights paid this run.
var relight_ash: float = 0.0
## Longest time (s) a brazier stayed out this run (the Keep the Fires
## achievement reads it; the one running now counts too: longest_out()).
var max_out: float = 0.0
## True once the first step placed the braziers.
var _placed: bool = false
## Seconds until the next cold check.
var _tick_left: float = 0.0
## Scratch for the grid queries.
var _tmp: Array = []
## Brazier bodies to take off the field on the next step ([Enemy,
## generation] pairs; BrazierKit, --spawn=brazier).
var _discard: Array = []
## True when this build draws (never headless).
var _draws: bool = false
## The frost vignette's layer (null headless or before the first level).
var _frost: CanvasLayer = null
## Level the frost vignette was built for (-1 = none).
var _frost_level: int = -1


## Builds the Long Winter for `p_game`; `p_enabled`: a Norse stage.
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	enabled = p_enabled
	name = "LongWinter"
	z_index = -6  # The braziers and their rings lie on the ground layer, under the bodies.
	z_as_relative = false
	cfg = NorseRulesData.LONG_WINTER.duplicate()
	var over: Dictionary = p_game.stage_def.get("long_winter", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# Public API
# =====================================================================================

## THE public call: a lit brazier at world point `at` (moved out of obstacles).
## Returns its index.
func place(at: Vector2) -> int:
	var b := Brazier.new()
	var r := float(cfg["brazier_radius"])
	b.pos = game.arena.free_point(at, r)
	game.arena.keep_clear(b.pos, r + ArenaData.MAX_HALF_EXTENT * 1.5)
	braziers.append(b)
	game.stat_add("braziers_placed", 1.0)
	if _draws:
		queue_redraw()
	return braziers.size() - 1


## A brazier ENEMY body `e` (BrazierKit) handed its spot to place(): it leaves
## the field without a kill on the next step.
func discard_body(e: Enemy) -> void:
	_discard.append([e, e.generation])


## True when world point `p` lies within warm_radius px of a lit brazier.
func is_warm(p: Vector2) -> bool:
	var wr := float(cfg["warm_radius"])
	for b in braziers:
		if b.lit and b.pos.distance_squared_to(p) <= wr * wr:
			return true
	return false


## Slow share out of warmth at the current level (0 at level 0).
func cold_slow() -> float:
	var arr: Array = cfg["slow_by_level"]
	return float(arr[clampi(level, 0, arr.size() - 1)])


## Frostbite share of max HP per s out of warmth at the current level.
func cold_bite() -> float:
	var arr: Array = cfg["bite_by_level"]
	return float(arr[clampi(level, 0, arr.size() - 1)])


## FUR-LINED BONES (hook; the act's counter-passive, owner decision Nov 7,
## 2026: "the cold slows summons half as much"): x the cold's slow on summons
## of the BOUND player's army (1 - the passive's cold_slow_cut). Exactly 1
## while the passive does not exist.
func fur_mult() -> float:
	return clampf(1.0 - game.abilities.passive_value(NorseRulesData.FUR_LINED_BONES, NorseRulesData.FUR_KEY), 0.0, 1.0)


## Longest time (s) a brazier stayed out this run, counting the one out now.
func longest_out() -> float:
	var m := max_out
	for b in braziers:
		if not b.lit:
			m = maxf(m, game.elapsed - b.out_since)
	return m


## Index of the nearest LIT brazier within `reach` px of `p` (a douser's
## detour, NorseKit.douse_step()), or -1.
func nearest_lit(p: Vector2, reach: float) -> int:
	var best := -1
	var best_d := reach * reach
	for i in braziers.size():
		var b := braziers[i]
		if not b.lit:
			continue
		var dsq := b.pos.distance_squared_to(p)
		if dsq < best_d:
			best_d = dsq
			best = i
	return best


## Lit braziers now.
func lit_count() -> int:
	var n := 0
	for b in braziers:
		if b.lit:
			n += 1
	return n


## Autotest bot (the one cold behaviour): while `p` is cold (level above 0),
## the nearest lit brazier within `reach` px; else (or with none lit in reach)
## the nearest brazier that is out within `reach` px (relight it); else
## Vector2.INF.
func bot_point(p: Vector2, reach: float) -> Vector2:
	if braziers.is_empty():
		return Vector2.INF
	var best := Vector2.INF
	var best_d := reach * reach
	if level > 0 and not is_warm(p):
		for b in braziers:
			var dsq := b.pos.distance_squared_to(p)
			if b.lit and dsq < best_d:
				best_d = dsq
				best = b.pos
		if best != Vector2.INF:
			return best
	best_d = reach * reach
	for b in braziers:
		var dsq := b.pos.distance_squared_to(p)
		if not b.lit and dsq < best_d:
			best_d = dsq
			best = b.pos
	return best


# =====================================================================================
# Per tick
# =====================================================================================

## Per-tick update (NorseRules.step()): placing, the level, relights, and every
## `tick` s the douses and the cold.
func step(delta: float) -> void:
	for pair: Array in _discard:
		var body: Enemy = pair[0]
		if body.active and body.generation == int(pair[1]):
			game.enemies.despawn(body)
	_discard.clear()
	if not enabled and braziers.is_empty():
		return
	if enabled and not _placed:
		_placed = true
		_place_start()
	if enabled:
		var lv := mini(int(cfg["max_level"]), floori(game.elapsed / maxf(float(cfg["step_every"]), 1.0)))
		if lv != level:
			level = lv
			if level > peak_level:
				peak_level = level
				game.stat_add("winter_level", 1.0)
				game.enemies.show_banner("The Long Winter deepens: cold level %d. Stay by the braziers!" % level)
				if game.norse != null:
					game.norse.play_sound("cold_rises", game.player.position)
	_relights(delta)
	_tick_left -= delta
	if _tick_left <= 0.0:
		var t := float(cfg["tick"])
		_tick_left += t
		_douses(t)
		if level > 0:
			if game.coop == null:
				_chill_slot(t)
			else:
				var prev := game.coop.bound  # Co-op: each army's own cold (its own Fur-Lined Bones).
				for i in game.coop.slots.size():
					game.coop.bind(i)
					_chill_slot(t)
				game.coop.bind(prev)
	if _draws:
		if Engine.get_physics_frames() % 6 == 0 or _busy():
			queue_redraw()
		if level != _frost_level:
			_build_frost()


## The run's braziers: the stage's "points" (offsets from the start), else a
## seeded ring around the start.
func _place_start() -> void:
	var start := game.player.position
	var pts: Array = cfg.get("points", [])
	if not pts.is_empty():
		for off: Vector2 in pts:
			place(start + off)
		return
	var n := int(cfg["count"])
	var offset := randf() * TAU  # Angle of the first brazier.
	for i in n:
		var a := offset + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.25, 0.25)
		var dd := randf_range(float(cfg["ring_min"]), float(cfg["ring_max"]))
		place(start + Vector2.from_angle(a) * dd)


## Relighting: a standing necromancer within relight_radius of a brazier that is
## out fills its ring; relight_time s relights it.
func _relights(delta: float) -> void:
	var rr := float(cfg["relight_radius"])
	for b in braziers:
		if b.lit:
			continue
		var near := false
		for pl in game.all_players:
			if not pl.dead and pl.position.distance_squared_to(b.pos) <= rr * rr:
				near = true
				break
		if near:
			b.relight += delta
			if b.relight >= float(cfg["relight_time"]):
				_relight(b)
		elif b.relight > 0.0:
			b.relight = maxf(0.0, b.relight - float(cfg["relight_decay"]) * delta)


## Brazier `b` burns again; the first relights pay a little Soul Ash.
func _relight(b: Brazier) -> void:
	max_out = maxf(max_out, game.elapsed - b.out_since)
	b.lit = true
	b.relight = 0.0
	b.douse = 0.0
	b.douser = null
	relit += 1
	game.stat_add("braziers_relit", 1.0)
	game.effects.ring(b.pos, 40.0, Palette.NORSE_HEARTH, 0.5)
	if game.norse != null:
		game.norse.play_sound("brazier_relight", b.pos, 0.5)
	if relit <= int(cfg["ash_relights_max"]):
		var ash := float(cfg["ash_per_relight"])
		relight_ash += ash
		game.stat_add("winter_relight_ash", ash)
		game.stat_add("objective_ash", ash)  # The bounty path every stage objective pays through.
		game.enemies.show_banner("The brazier burns again! +%d Soul Ash" % int(ash))
	else:
		game.enemies.show_banner("The brazier burns again!")


## Dousing (every `t` s): a douser near a lit brazier makes it gutter; staying
## douse_time s puts it out.
func _douses(t: float) -> void:
	var dr := float(cfg["douse_radius"])
	for b in braziers:
		if not b.lit:
			continue
		if b.douser != null:
			var e := b.douser
			if e.active and e.generation == b.douser_gen and e.position.distance_squared_to(b.pos) <= (dr * 1.5) * (dr * 1.5):
				b.douse += t
				if b.douse >= float(cfg["douse_time"]):
					_douse(b, e.kind)
				continue
			b.douser = null
			b.douse = 0.0
		game.enemy_grid.query(b.pos, dr + 30.0, _tmp)
		for e: Enemy in _tmp:
			if e.active and e.kit is NorseKit and bool((e.kit as NorseKit).d.get("douses", false)) \
					and e.position.distance_squared_to(b.pos) <= dr * dr:
				b.douser = e
				b.douser_gen = e.generation
				b.douse = 0.0
				break


## Brazier `b` goes out (doused by a `kind`).
func _douse(b: Brazier, kind: String) -> void:
	b.lit = false
	b.douse = 0.0
	b.douser = null
	b.relight = 0.0
	b.out_since = game.elapsed
	doused += 1
	game.stat_add("braziers_doused", 1.0)
	game.stat_add("braziers_doused_by_" + kind, 1.0)
	game.effects.ring(b.pos, 30.0, Palette.NORSE_FROST, 0.5)
	game.enemies.show_banner("A brazier is doused! Stand by it to relight it")
	if game.norse != null:
		game.norse.play_sound("brazier_douse", b.pos, 0.5)


## The cold on the BOUND slot (every `t` s): its necromancer and its summons out
## of warmth are slowed (TerrainSlow, the one ground-slow path; the summons x
## fur_mult()) and, from the biting levels, the summons take frostbite.
func _chill_slot(t: float) -> void:
	var slow := cold_slow()
	var bite := cold_bite()
	var linger := t * 1.6  # The slow outlasts the tick a little (no flicker).
	var pl := game.player
	if not pl.dead and not is_warm(pl.position):
		game.stat_add("winter_player_cold_s", t)
		if slow > 0.0 and TerrainSlow.slow_player(game, slow, linger) > 0.0:
			game.stat_add("winter_slows", 1.0)
	var fur := fur_mult()
	for u in game.horde.units:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING:
			continue
		if is_warm(u.position):
			continue
		game.stat_add("winter_summon_cold_s", t)
		if slow * fur > 0.0:
			TerrainSlow.slow_summon(game, u, slow * fur, linger)
		if bite > 0.0:
			game.combat.damage_unit(u, u.max_hp * bite * t, NorseRulesData.FROSTBITE_SOURCE)


## True while a brazier gutters or a relight is under way (smooth redraws).
func _busy() -> bool:
	for b in braziers:
		if b.douser != null or b.relight > 0.0:
			return true
	return false


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## Each brazier: its warmth ring while lit (faint amber dots), a flicker while
## it gutters, its relight ring with the progress while out, and the brazier
## itself (its sprite, else its glyph).
func _draw() -> void:
	var n := NorseRulesData.CAPTURE_DOTS
	var wr := float(cfg["warm_radius"])
	var rr := float(cfg["relight_radius"])
	for b in braziers:
		if b.lit:
			for i in n * 2:
				var a := TAU * float(i) / float(n * 2)
				SpriteBank.draw_disc(self, b.pos + Vector2.from_angle(a) * wr, 1.4, Color(Palette.NORSE_HEARTH, 0.22))
			var flick := 0.5 + 0.5 * sin(game.elapsed * 30.0) if b.douser != null else 1.0  # Guttering while doused.
			SpriteBank.draw_disc(self, b.pos + Vector2(0.0, -6.0), 22.0, Color(Palette.NORSE_HEARTH, 0.18 * flick))
		else:
			for i in n:
				var a := TAU * float(i) / float(n)
				SpriteBank.draw_disc(self, b.pos + Vector2.from_angle(a) * rr, 1.5, Color(Palette.NORSE_FROST, 0.35))
			var k := clampf(b.relight / maxf(float(cfg["relight_time"]), 0.01), 0.0, 1.0)  # Relight progress.
			for i in ceili(k * float(n)):
				var a := -PI * 0.5 + TAU * float(i) / float(n)
				SpriteBank.draw_disc(self, b.pos + Vector2.from_angle(a) * rr, 3.0, Color(Palette.NORSE_HEARTH, 0.95))
		var key := NorseRulesData.BRAZIER_SPRITE if b.lit else NorseRulesData.BRAZIER_OUT_SPRITE
		if not SpriteBank.draw(self, key, b.pos, false):
			NorseGlyphs.draw_brazier(self, b.pos, float(cfg["brazier_radius"]), b.lit)


## (Re)builds the frost vignette for the current level: four gradient bands
## creeping in from the view's edges, frost_px x level / max_level wide, on a
## CanvasLayer under the HUD (static Controls: nothing is redrawn per frame).
func _build_frost() -> void:
	_frost_level = level
	if _frost == null:
		_frost = CanvasLayer.new()
		_frost.layer = 1  # Over the world, under the HUD.
		_frost.name = "LongWinterFrost"
		add_child(_frost)
	for c: Node in _frost.get_children():
		c.queue_free()
	var w := float(cfg["frost_px"]) * float(level) / maxf(float(cfg["max_level"]), 1.0)  # Band width (px).
	if w <= 0.0:
		return
	var tint := NorseRulesData.FROST_TINT
	for side in 4:
		var g := Gradient.new()
		g.set_color(0, tint)
		g.set_color(1, Color(tint, 0.0))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.width = 64
		gt.height = 64
		var tr := TextureRect.new()
		tr.texture = gt
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		match side:
			0:  # Top: opaque at the top edge.
				gt.fill_from = Vector2(0.5, 0.0)
				gt.fill_to = Vector2(0.5, 1.0)
				tr.set_anchors_preset(Control.PRESET_TOP_WIDE)
				tr.offset_bottom = w
			1:  # Bottom.
				gt.fill_from = Vector2(0.5, 1.0)
				gt.fill_to = Vector2(0.5, 0.0)
				tr.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
				tr.offset_top = -w
			2:  # Left.
				gt.fill_from = Vector2(0.0, 0.5)
				gt.fill_to = Vector2(1.0, 0.5)
				tr.set_anchors_preset(Control.PRESET_LEFT_WIDE)
				tr.offset_right = w
			_:  # Right.
				gt.fill_from = Vector2(1.0, 0.5)
				gt.fill_to = Vector2(0.0, 0.5)
				tr.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
				tr.offset_left = -w
		_frost.add_child(tr)
	_add_frost_edges(w)


## The art pass's frost edge (NorseRulesData.FROST_SPRITE) tiled along each
## edge of the view over the gradient bands, as deep as the band (at most its
## art height): flipped for the bottom, turned a quarter for the sides. Static
## TextureRects rebuilt with the band (and when the view is resized); nothing
## without the PNG (the plain bands stay). Visual only.
func _add_frost_edges(w: float) -> void:
	var tex := SpriteBank.texture(NorseRulesData.FROST_SPRITE)  # The frost edge strip, or null.
	if tex == null:
		return
	var vp := get_viewport()
	if not vp.size_changed.is_connected(_on_view_resized):
		vp.size_changed.connect(_on_view_resized)
	var view := vp.get_visible_rect().size  # Canvas-layer px.
	var h := minf(w, float(tex.get_height()))  # Strip depth (px).
	for side in 4:
		var tr := TextureRect.new()
		tr.texture = tex
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.modulate = Color(1.0, 1.0, 1.0, NorseRulesData.FROST_SPRITE_ALPHA)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		match side:
			0:  # Top: the strip as drawn (its frost edge on top).
				tr.position = Vector2.ZERO
				tr.size = Vector2(view.x, h)
			1:  # Bottom: flipped.
				tr.flip_v = true
				tr.position = Vector2(0.0, view.y - h)
				tr.size = Vector2(view.x, h)
			2:  # Left: a quarter turn back, its top row on the left edge.
				tr.position = Vector2(0.0, view.y)
				tr.size = Vector2(view.y, h)
				tr.rotation = -PI * 0.5
			_:  # Right: a quarter turn, its top row on the right edge.
				tr.position = Vector2(view.x, 0.0)
				tr.size = Vector2(view.y, h)
				tr.rotation = PI * 0.5
		_frost.add_child(tr)


## The view was resized: the side strips are laid out in px, so rebuild.
func _on_view_resized() -> void:
	if _frost != null and _frost_level > 0:
		_build_frost()
