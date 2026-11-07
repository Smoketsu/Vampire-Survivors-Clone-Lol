## AcidPools — THE ACID PATH of the Concord of Stars (Act IX, the Crash Site;
## GDD §15.0 "The Crash Site (Act IX phase 2)"; owner-approved proposal: "Acid
## Spitter | Brood | Ranged | Lobs acid that leaves a burning puddle; arcing,
## so it ignores the ring | Kill it on approach"; the Hive Mother's Flight:
## "raining acid"). Owned by Game.concord as `acid` (created with the shared
## rules, so the Acid Spitter works on any stage a --spawn= puts it). ONE pooled
## store of entries, each first a LOB, then a PUDDLE:
##   * lob(from, to, opts): a glob of acid thrown from `from` arcs to `to` (a
##     point fixed at the throw) in opts "flight" s; it is ARCING, so the Bone
##     Ring, Bone Walls and Orb Shields never stop it. A landing telegraph
##     (EffectManager.telegraph_circle(), the shared look) shows where it
##     falls. On landing it SPLASHES (opts "impact", once, to every summon and
##     necromancer within its radius) and leaves a PUDDLE of opts "radius" px
##     for opts "life" s.
##   * A puddle burns every ConcordRulesData.ACID tick s: each summon in it
##     takes opts "dps" x tick (x the thrower's undead mult) through
##     CombatResolver.damage_unit(), each necromancer dps x tick through
##     damage_player() (Grave Step's i-frames dodge it there). It never hurts
##     an enemy. Airborne summons (a Gargoyle in its swoop, a lifted summon)
##     are above it.
## Its damage is fixed at the throw (already scaled by the thrower's
## CovenantKit.hit_scale()). At most ACID cap entries; a lob over the cap is
## refused and counted. Packed arrays, no nodes, no instance ids; drawn on the
## ground (z -1, under the units) as textures: the art pass's
## `effects/acid_pool` when present (tinted acid green), else a soft blob
## texture made once in code; the lob in flight as a small disc on its arc.
## Nothing is drawn headless. Determinism: game time only, no RNG.
## Stats: acid_lobs, acid_lobs_refused, acid_splash_hits, acid_puddle_hits,
## acid_on_you, summon_dmg_from_acid_pool / player_dmg_from_acid_pool (the
## resolver's per-source counters).
class_name AcidPools
extends Node2D

## Sprite key of a puddle's art (grey tint mask, the art pass).
const POOL_ART: String = "effects/acid_pool"
## Colour of the acid (the Brood's acid green, Palette.CONCORD_PLASMA's hue).
## Tint of a puddle's texture: white, because the art itself is baked in the Concord plasma greens (#1FA84A rim, #3CFF6A body;
## Act IX art review round 1: "should be green since it's acid"; it was a grey mask under ACID_COLOR). Drawing only.
const POOL_TINT := Color(1.0, 1.0, 1.0)  # TUNING (not in GDD) drawing only
const ACID_COLOR := Color(0.55, 1.0, 0.25)  # TUNING (not in GDD) drawing only

## Owning run.
var game: Game
## Live entries (indices [0, count) of every array below).
var count: int = 0
## Most entries at once this run (the report).
var peak: int = 0
## Lobs thrown this run.
var thrown: int = 0
## Hard cap (ACID cap): the arrays' size.
var _cap: int = 0
## Where each lob was thrown from (world px).
var _from: PackedVector2Array = PackedVector2Array()
## Where each lob lands / its puddle lies (world px).
var _at: PackedVector2Array = PackedVector2Array()
## Game time (s) each lob was thrown.
var _t0: PackedFloat32Array = PackedFloat32Array()
## Game time (s) each lob lands (its puddle starts).
var _land: PackedFloat32Array = PackedFloat32Array()
## Game time (s) each puddle dries up (its fade ends).
var _end: PackedFloat32Array = PackedFloat32Array()
## Radius (px) of each puddle.
var _r: PackedFloat32Array = PackedFloat32Array()
## Damage per second of each puddle (already scaled at the throw).
var _dps: PackedFloat32Array = PackedFloat32Array()
## Splash damage of each lob on landing (already scaled; 0 = none).
var _impact: PackedFloat32Array = PackedFloat32Array()
## x each entry's damage on a summon (its thrower's undead_damage_mult).
var _umult: PackedFloat32Array = PackedFloat32Array()
## 1 once the entry landed (it is a puddle), else 0 (a lob in flight).
var _landed: PackedByteArray = PackedByteArray()
## Damage tag of each lob's splash (the thrower's kind id).
var _src: PackedStringArray = PackedStringArray()
## Seconds toward the next puddle damage tick (one clock for every puddle).
var _tick_acc: float = 0.0
## Reusable grid query buffer.
var _tmp: Array = []
## The soft blob texture (made on first use; drawing only).
static var _blob_tex: Texture2D = null
## True when this build draws (never headless).
var _draws: bool = false
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Builds the store for `p_game` (ConcordRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "AcidPools"
	z_index = -1  # On the ground, under the units (the terraforming turf is lower still).
	_cap = int(ConcordRulesData.ACID["cap"])
	_from.resize(_cap)
	_at.resize(_cap)
	_t0.resize(_cap)
	_land.resize(_cap)
	_end.resize(_cap)
	_r.resize(_cap)
	_dps.resize(_cap)
	_impact.resize(_cap)
	_umult.resize(_cap)
	_landed.resize(_cap)
	_src.resize(_cap)
	_draws = DisplayServer.get_name() != "headless"


## THE ONE CALL: throws a glob of acid from `from` to `to`. `opts`: "flight"
## (s in the air), "radius" (px of the puddle), "life" (s the puddle lasts),
## "dps" (puddle damage per second, already scaled), "impact" (splash damage
## on landing, already scaled; default 0), "umult" (x on a summon; default 1),
## "source" (the splash's damage tag; default ACID_SOURCE), "telegraph" (bool,
## default true: the landing circle). Returns false when refused (the cap).
func lob(from: Vector2, to: Vector2, opts: Dictionary) -> bool:
	if count >= _cap:
		game.stat_add("acid_lobs_refused", 1.0)
		return false
	var i := count
	count += 1
	peak = maxi(peak, count)
	thrown += 1
	var flight := maxf(0.05, float(opts.get("flight", 0.9)))
	_from[i] = from
	_at[i] = to
	_t0[i] = game.elapsed
	_land[i] = game.elapsed + flight
	_end[i] = _land[i] + maxf(0.1, float(opts.get("life", 4.0)))
	_r[i] = float(opts.get("radius", 30.0))
	_dps[i] = float(opts.get("dps", 0.0))
	_impact[i] = float(opts.get("impact", 0.0))
	_umult[i] = float(opts.get("umult", 1.0))
	_landed[i] = 0
	_src[i] = String(opts.get("source", ConcordRulesData.ACID_SOURCE))
	if bool(opts.get("telegraph", true)):
		game.effects.telegraph_circle(to, _r[i], flight)
	game.stat_add("acid_lobs", 1.0)
	return true


## Removes entry `i` (the last entry moves into its slot).
func _remove(i: int) -> void:
	var last := count - 1
	if i != last:
		_from[i] = _from[last]
		_at[i] = _at[last]
		_t0[i] = _t0[last]
		_land[i] = _land[last]
		_end[i] = _end[last]
		_r[i] = _r[last]
		_dps[i] = _dps[last]
		_impact[i] = _impact[last]
		_umult[i] = _umult[last]
		_landed[i] = _landed[last]
		_src[i] = _src[last]
	count = last


## Per-tick update (ConcordRules.step()): lobs land and splash, puddles burn on
## their shared tick, dried puddles go.
func step(delta: float) -> void:
	var now := game.elapsed
	var i := 0
	while i < count:
		if now >= _end[i]:
			_remove(i)
			continue
		if _landed[i] == 0 and now >= _land[i]:
			_landed[i] = 1
			_splash(i)
		i += 1
	_tick_acc += delta
	var tick := float(ConcordRulesData.ACID["tick"])
	if _tick_acc >= tick:
		_tick_acc -= tick
		for k in count:
			if _landed[k] == 1 and now < _end[k] - float(ConcordRulesData.ACID["fade_time"]):
				_burn(k, tick)
	if _draws:
		if count > 0 or _drawn:
			queue_redraw()
		_drawn = count > 0


## Lob `i` lands: its splash hits every summon and necromancer within its radius once.
func _splash(i: int) -> void:
	var at := _at[i]
	var r := _r[i]
	if game.concord != null:
		game.concord.play_sound("acid_spit", at, 0.25)
	if _impact[i] <= 0.0:
		return
	_hit_all(at, r, _impact[i], _umult[i], _src[i], "acid_splash_hits")


## One damage tick of puddle `i`.
func _burn(i: int, tick: float) -> void:
	if _dps[i] <= 0.0:
		return
	_hit_all(_at[i], _r[i], _dps[i] * tick, _umult[i], ConcordRulesData.ACID_SOURCE, "acid_puddle_hits")


## Hits every grounded summon and every standing necromancer within `r` px of
## `at` (their body radius counts) once for `dmg` (x `umult` on a summon),
## tagged `src`; counts the summon hits in stat `stat`.
func _hit_all(at: Vector2, r: float, dmg: float, umult: float, src: String, stat: String) -> void:
	game.ally_grid.query(at, r + float(ConcordRulesData.ACID["summon_slack"]), _tmp)
	for u: SummonedUnit in _tmp.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		if u.position.distance_to(at) > r + u.radius:
			continue
		game.combat.damage_unit(u, dmg * umult, src)
		game.stat_add(stat, 1.0)
	for pl in game.all_players:
		if pl.dead or pl.position.distance_to(at) > r + pl.radius:
			continue
		game.combat.damage_player(dmg, src, pl)
		game.stat_add("acid_on_you", 1.0)


## True when world point `p` (a body of radius `rad`) stands in a burning puddle.
func in_acid(p: Vector2, rad: float = 0.0) -> bool:
	for i in count:
		if _landed[i] == 1 and p.distance_to(_at[i]) <= _r[i] + rad:
			return true
	return false


## Autopilot hint (ConcordRules.danger_push()): a push out of every burning
## puddle and every landing circle within its radius plus ACID danger_margin
## of `p`, stronger toward the centre.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var margin := float(ConcordRulesData.ACID["danger_margin"])
	for i in count:
		var reach := _r[i] + margin + game.player.radius
		var rel := p - _at[i]
		var dist := rel.length()
		if dist >= reach:
			continue
		var n := rel / dist if dist > 0.01 else Vector2.RIGHT
		push += n * (1.0 - dist / reach) * (2.0 if _landed[i] == 1 else 1.5)
	return push


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## Every puddle as a green blob texture (spreading in, fading out, a slow
## shimmer on game time), then every lob in flight as a small glob on its arc.
func _draw() -> void:
	var now := game.elapsed
	var tex := SpriteBank.texture(POOL_ART)  # The art pass's puddle, or null.
	var tint := POOL_TINT  # White for the baked art; the white fallback blob takes the acid colour.
	if tex == null:
		tex = blob_texture()
		tint = ACID_COLOR
	var grow := float(ConcordRulesData.ACID["grow_time"])
	var fade := float(ConcordRulesData.ACID["fade_time"])
	for i in count:
		if _landed[i] == 0:
			continue
		var k := clampf((now - _land[i]) / maxf(grow, 0.01), 0.0, 1.0)  # Spread 0 -> 1.
		var a := clampf((_end[i] - now) / maxf(fade, 0.01), 0.0, 1.0)  # Fade 1 -> 0.
		var r := _r[i] * (0.4 + 0.6 * k)
		var shimmer := 0.85 + 0.15 * sin(now * 3.0 + float(i))
		draw_texture_rect(tex, Rect2(_at[i] - Vector2(r, r * 0.8), Vector2(r * 2.0, r * 1.6)), false, Color(tint, 0.85 * a * shimmer))
	var lift := float(ConcordRulesData.ACID["arc_height"])
	for i in count:
		if _landed[i] == 1:
			continue
		var k := clampf((now - _t0[i]) / maxf(_land[i] - _t0[i], 0.01), 0.0, 1.0)
		var p := _from[i].lerp(_at[i], k) + Vector2(0.0, -lift * 4.0 * k * (1.0 - k))
		SpriteBank.draw_disc(self, p, 4.0, Color(ACID_COLOR, 0.95))
		SpriteBank.draw_disc(self, p + Vector2(-1.0, -1.0), 1.5, Color(1.0, 1.0, 0.85, 0.9))


## The soft blob texture: 32 x 32 white, an uneven round blob with a soft rim
## (tinted when drawn). Made once.
static func blob_texture() -> Texture2D:
	if _blob_tex != null:
		return _blob_tex
	var n := 32
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(15.5, 15.5)
	for y in n:
		for x in n:
			var rel := Vector2(float(x), float(y)) - c
			var ang := rel.angle()
			var edge := 14.0 + 1.6 * sin(ang * 3.0) + 1.0 * sin(ang * 5.0 + 1.3)  # A wobbly rim (no RNG).
			var dd := rel.length()
			var a := 0.0
			if dd <= edge:
				a = 0.55 + 0.45 * clampf((edge - dd) / 3.0, 0.0, 1.0) * (0.7 if dd < edge * 0.5 else 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_blob_tex = ImageTexture.create_from_image(img)
	return _blob_tex
