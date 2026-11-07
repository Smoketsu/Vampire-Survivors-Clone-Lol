## SunCourse — THE SUN'S COURSE, the first of the Shogunate's shared rules (Act
## V; GDD §15.0 "The Sun's Course"; owner-approved proposal docs/act5/PROPOSAL.md
## "The mechanic you were stuck on: the Sun's Course"), owned by Game.shogunate.
## ONE path reading the run clock; every Act V system asks it, nothing else
## keeps its own idea of the time of day:
##   phase()      — DAY (20:00-13:00 left), DUSK (13:00-7:00), NIGHT (7:00-0:00)
##                  and ENDLESS_NIGHT (the Reckoning, when the stage's RECKONING
##                  has "endless_night"); boundaries in ShogunateRulesData.SUN,
##                  per stage through its STAGE "sun" dictionary ({} = defaults).
##   light_at(p)  — the light (0..1) at world point p: the ambient light of the
##                  phase (blended over SUN blend s of game time) or a light
##                  pool, whichever is brighter. Pools: each necromancer's
##                  (light_radius x lantern_mult()) and, at night, every lit
##                  stone lantern's. ShadowAmbush reads it (a puff in light shows
##                  earlier) and in_lit_pool() (never a puff in a lantern's pool);
##                  phase 2's kitsune decoys are revealed in light the same way.
##   lantern_mult() — the PAPER LANTERNS hook (the future Act V counter-passive;
##                  not built in phase 1): 1 + PassiveData row PAPER_LANTERNS's
##                  value for that necromancer (exactly 1 while no such passive
##                  exists); the one read, used for its light radius and its
##                  ambush warnings.
##   timeline_weights(seg) / filter_groups(groups) — THE timeline helper: night
##                  kinds (row "night") join the trickle (a segment's
##                  "night_weights") and the waves only at night; a night kind
##                  in a segment's day "weights" is dropped by day and at dusk.
## Stone lanterns: at night every `stone_lantern` obstacle within SUN
## lantern_scan px of a necromancer lights up and stays lit for the whole night
## (the simulation scans the arena's gameplay cells every scan_every s; the
## drawing only reads the list). `nightfall` plays when night falls.
## THE LOOK (drawing only; no RNG, no gameplay state): day is clear; dusk washes
## the view orange and lengthens the obstacles' shadows (drawn by the Arena
## through ShogunateGlyphs.draw_long_shadow()); at night everything beyond the
## light pools goes dark: a small darkness texture (one texel per SUN cell px,
## its alpha 0 inside a pool and SUN darkness (~0.55) beyond, updated each frame
## from the same pools as light_at()) stretched over the view with linear
## filtering, plus light-pool sprites drawn ADDITIVELY (a child node with an ADD
## CanvasItemMaterial): warm on the lit lanterns, a faint pale one on each
## necromancer's pool so it reads even on a dark floor. No shader reads the screen and
## no polygon is redrawn every frame (GDD §15.0 "Web GL id leak patch"). Units in
## the dark are dimmed, never hidden. Nothing is drawn headless.
## Inert off Act V: `enabled` is false unless the STAGE has "shogunate": phase()
## is DAY, light_at() is 1 and nothing draws.
## --- Act V: the Road to the Sun --- THE SKY OVERRIDE (the one entry a boss
## that changes the sky uses; Amaterasu, BossAmaterasu): set_override(opts)
## puts the sky under her (opts: phase, ambient, dusk, tint, tint_alpha,
## shadow_dir; each change blends over SUN blend s from what shows now) and
## clear_override() hands it back to the clock (blending back the same way).
## phase(), ambient() and so light_at(), the darkness and the dusk wash all
## read it, so there is no second lighting path. The Endless Night outranks
## it: from 0:00 on a stage with one, the override is ignored. Changes it
## causes show no phase banner (the boss shows her own).
class_name SunCourse
extends Node2D

## Light-pool sprites drawn additively above the darkness (the lit lanterns'
## warm glow): a child node with an ADD material that calls back into its
## SunCourse to draw.
class GlowLayer:
	extends Node2D
	## The Sun's Course that draws through this layer.
	var sun: SunCourse

	func _draw() -> void:
		if sun != null:
			sun.draw_glows(self)

## Owning run.
var game: Game
## True when the stage runs the Sun's Course (STAGE "shogunate"); false for a
## Shogunate kind forced onto another act's stage (always day there).
var enabled: bool = false
## The stage's Sun's Course numbers (ShogunateRulesData.SUN with the STAGE's
## "sun" overrides).
var cfg: Dictionary = {}
## The stage's Endless Night numbers (ShogunateRulesData.ENDLESS_NIGHT with the
## RECKONING's "endless_night" overrides; {} = no Endless Night on this stage).
var endless: Dictionary = {}
## The phase at the last step (ShogunateRulesData.Phase; -1 before the first).
var current: int = -1
## Game time (s) each phase began this run (Phase -> s; the autotest's "sun's
## course" line).
var phase_started: Dictionary = {}
## Lit stone lanterns now: arena cell (Vector2i) -> the lantern's centre (world px).
var lit: Dictionary = {}
## Every lantern lit this run (arena cell Vector2i -> true; the autotest count).
var ever_lit: Dictionary = {}
## Game time (s) of the next lantern scan.
var _scan_at: float = 0.0
# --- Act V: the Road to the Sun (the sky override) ---
## The sky override now ({} = none; see set_override()): phase (Phase),
## ambient (0..1), dusk (0..1, the wash and the long shadows), tint (Color of
## the wash), tint_alpha (0..1 at dusk 1), shadow_dir (unit Vector2), plus the
## blend bookkeeping t0 (game time s the last change began) and from_ambient /
## from_dusk (what showed then).
var override: Dictionary = {}
## Game time (s) the override was cleared (-1 = never): the sky blends back
## to the clock's from release_ambient / release_dusk over SUN blend s.
var _release_t: float = -1.0
## Ambient light (0..1) showing when the override was cleared.
var _release_ambient: float = 1.0
## Dusk wash amount (0..1) showing when the override was cleared.
var _release_dusk: float = 0.0
## True while a phase change the override caused is being entered (no banner).
var _quiet: bool = false
## Game time (s) of the next arena redraw while a phase blends (the long shadows).
var _shadow_redraw_at: float = 0.0
## Cached timeline weights: the segment dictionary they were built from.
var _tw_seg: Dictionary = {}
## Cached timeline weights: whether they were built at night.
var _tw_night: bool = false
## Cached timeline weights (timeline_weights()).
var _tw: Dictionary = {}
# --- Drawing (visual only) ---
## True when this run draws the look (false headless).
var _draws: bool = false
## The darkness image (one texel per SUN cell px; alpha = darkness).
var _img: Image
## The darkness texture drawn over the view (updated from _img each frame).
var _tex: ImageTexture
## Texels across / down of the darkness image.
var _cols: int = 0
## Texels down of the darkness image.
var _rows: int = 0
## World px of the darkness image's top-left texel corner.
var _origin: Vector2 = Vector2.ZERO
## True if the darkness or the tint was drawn last frame (one more clears it).
var _drawn: bool = false
## The additive light-pool layer (null headless).
var _glow: GlowLayer = null
## Soft radial light-pool sprite (white centre fading to clear), made once.
var _pool_tex: ImageTexture = null


## Builds the Sun's Course for `p_game` (ShogunateRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "SunCourse"
	z_index = 18  # Above the units, the shots and the effects; under the Draw lines, the puffs and the HUD.
	z_as_relative = false
	enabled = bool(p_game.stage_def.get("shogunate", false))
	cfg = ShogunateRulesData.SUN.duplicate()
	var over: Dictionary = p_game.stage_def.get("sun", {})  # The stage's own Sun's Course overrides.
	for key: String in over:
		cfg[key] = over[key]
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if enabled and r.has("endless_night"):
		endless = ShogunateRulesData.ENDLESS_NIGHT.duplicate()
		var eo: Dictionary = r["endless_night"]  # The stage's own Endless Night overrides.
		for key: String in eo:
			endless[key] = eo[key]
	_draws = enabled and DisplayServer.get_name() != "headless"
	if _draws:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # Bilinear between darkness texels: smooth pools.
		_glow = GlowLayer.new()
		_glow.sun = self
		_glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD  # Light pools brighten what is under them.
		_glow.material = mat
		add_child(_glow)


# =====================================================================================
# The clock
# =====================================================================================

## The phase now (ShogunateRulesData.Phase): DAY off Act V.
func phase() -> int:
	return phase_at(game.elapsed)


## The phase at game time `t` (s).
func phase_at(t: float) -> int:
	if not enabled:
		return ShogunateRulesData.Phase.DAY
	if t >= WaveData.RUN_DURATION and not endless.is_empty():
		return ShogunateRulesData.Phase.ENDLESS_NIGHT
	if _ov_active():
		return int(override["phase"])  # Act V, the Road to the Sun: the sky is the boss's.
	if t >= float(cfg["night_at"]):
		return ShogunateRulesData.Phase.NIGHT
	if t >= float(cfg["dusk_at"]):
		return ShogunateRulesData.Phase.DUSK
	return ShogunateRulesData.Phase.DAY


## True at night and in the Endless Night.
func is_night() -> bool:
	return phase() >= ShogunateRulesData.Phase.NIGHT


## True from dusk on (ambushes begin).
func is_dusk_or_later() -> bool:
	return phase() >= ShogunateRulesData.Phase.DUSK


## Blend factor 0..1 of a change that began at game time `start` (s).
func _blend(start: float) -> float:
	return clampf((game.elapsed - start) / maxf(float(cfg["blend"]), 0.01), 0.0, 1.0)


## The ambient light now (0..1), blended across the phase changes.
func ambient() -> float:
	if not enabled:
		return 1.0
	if _ov_active():
		return lerpf(float(override["from_ambient"]), float(override["ambient"]), _blend(float(override["t0"])))
	if _release_t >= 0.0 and game.elapsed - _release_t < float(cfg["blend"]):
		return lerpf(_release_ambient, _clock_ambient(), _blend(_release_t))
	return _clock_ambient()


## The clock's ambient light now (0..1), without the sky override.
func _clock_ambient() -> float:
	var t := game.elapsed
	var day := float(cfg["ambient_day"])
	var dusk := float(cfg["ambient_dusk"])
	if t < float(cfg["dusk_at"]):
		return day
	if t < float(cfg["night_at"]):
		return lerpf(day, dusk, _blend(float(cfg["dusk_at"])))
	return lerpf(dusk, float(cfg["ambient_night"]), _blend(float(cfg["night_at"])))


## How much of the dusk wash shows now (0..1): it rises at dusk and fades as
## night falls.
func dusk_amount() -> float:
	if not enabled:
		return 0.0
	if _ov_active():
		return lerpf(float(override["from_dusk"]), float(override["dusk"]), _blend(float(override["t0"])))
	if _release_t >= 0.0 and game.elapsed - _release_t < float(cfg["blend"]):
		return lerpf(_release_dusk, _clock_dusk(), _blend(_release_t))
	return _clock_dusk()


## The clock's dusk wash amount now (0..1), without the sky override.
func _clock_dusk() -> float:
	var t := game.elapsed
	if t < float(cfg["dusk_at"]):
		return 0.0
	if t < float(cfg["night_at"]):
		return _blend(float(cfg["dusk_at"]))
	return 1.0 - _blend(float(cfg["night_at"]))


## Alpha (0..1) of the darkness where no light falls: SUN darkness at night,
## deepening to the Endless Night's, times (1 - ambient light).
func darkness_alpha() -> float:
	var dark := float(cfg["darkness"])  # Darkness at ambient 0.
	if not endless.is_empty() and game.elapsed >= WaveData.RUN_DURATION:
		dark = lerpf(dark, float(endless["darkness"]), _blend(WaveData.RUN_DURATION))
	return dark * (1.0 - ambient())


## Minutes past 0:00 (0 before).
func _minutes_past() -> float:
	return maxf(0.0, game.elapsed - WaveData.RUN_DURATION) / 60.0


## x the light radii now: 1, shrinking each minute of the Endless Night.
func endless_light_mult() -> float:
	if endless.is_empty() or game.elapsed < WaveData.RUN_DURATION:
		return 1.0
	return maxf(float(endless["min_light_mult"]), pow(float(endless["light_shrink"]), _minutes_past()))


## x the move speed of a Reckoning enemy spawned now: 1, growing each minute of
## the Endless Night ("faster each minute"); exactly 1 without one.
func endless_speed_mult() -> float:
	if endless.is_empty() or game.elapsed < WaveData.RUN_DURATION:
		return 1.0
	return minf(float(endless["max_speed_mult"]), 1.0 + float(endless["speed_per_min"]) * _minutes_past())


# =====================================================================================
# The sky override (Act V, the Road to the Sun: Amaterasu)
# =====================================================================================

## True while the sky override rules the sky (set, and not outranked by the
## Endless Night).
func _ov_active() -> bool:
	if override.is_empty():
		return false
	return endless.is_empty() or game.elapsed < WaveData.RUN_DURATION


## THE SKY OVERRIDE: a boss that changes the sky (Amaterasu) takes it with
## `opts` (any of: phase (ShogunateRulesData.Phase, the time of day every
## system reads), ambient (0..1), dusk (0..1: the wash and the long shadows),
## tint (Color of the wash), tint_alpha (0..1 at dusk 1), shadow_dir (unit
## Vector2, the way the shadows fall)); keys left out keep their current
## override value (or the clock's). Every call blends from what shows now over
## SUN blend s. No phase banner shows for the changes it causes. Inert off Act V.
func set_override(opts: Dictionary) -> void:
	if not enabled:
		return
	var amb := ambient()  # What shows now (the blend start).
	var dk := dusk_amount()
	var ov := override.duplicate()
	if ov.is_empty():
		ov = {"phase": phase(), "ambient": amb, "dusk": dk, "tint": cfg["dusk_tint"],
			"tint_alpha": float(cfg["dusk_tint_alpha"]), "shadow_dir": cfg["sun_dir"]}
	for key: String in opts:
		ov[key] = opts[key]
	ov["t0"] = game.elapsed
	ov["from_ambient"] = amb
	ov["from_dusk"] = dk
	override = ov
	_release_t = -1.0
	game.stat_add("sun_overrides", 1.0)
	game.arena.queue_redraw()  # The shadows follow (drawing only).


## Hands the sky back to the clock (the override's boss fell): it blends back
## from what shows now over SUN blend s; the phase change it causes shows no
## banner (the boss shows its own).
func clear_override() -> void:
	if override.is_empty():
		return
	_release_ambient = ambient()
	_release_dusk = dusk_amount()
	_release_t = game.elapsed
	override = {}
	game.arena.queue_redraw()


## Colour of the dusk wash now (the override's tint while it rules the sky).
func tint_color() -> Color:
	return override["tint"] if _ov_active() else cfg["dusk_tint"]


## Alpha (0..1) of the dusk wash at dusk 1 now (the override's while it rules).
func tint_alpha() -> float:
	return float(override["tint_alpha"]) if _ov_active() else float(cfg["dusk_tint_alpha"])


## Unit direction the obstacles' shadows fall now (SUN sun_dir, or the
## override's: away from where its sun stands).
func shadow_dir() -> Vector2:
	return override["shadow_dir"] if _ov_active() else cfg["sun_dir"]


# =====================================================================================
# Light
# =====================================================================================

## PAPER LANTERNS (the future Act V counter-passive; the one read): x the light
## radius and the lit part of the ambush warning of necromancer `pl` (null =
## the bound one): 1 + PassiveData row PAPER_LANTERNS's value in that
## necromancer's own build (co-op: each player's). Exactly 1 while the passive
## does not exist.
func lantern_mult(pl: Necromancer = null) -> float:
	var k := 0 if game.coop == null or pl == null else game.coop.slot_of(pl)  # Its slot.
	var prev := game.bind_index(k)
	var v := game.abilities.passive_value(ShogunateRulesData.PAPER_LANTERNS, ShogunateRulesData.PAPER_LANTERNS_KEY)
	game.unbind(prev)
	return 1.0 + v


## Radius (px) of necromancer `pl`'s light pool now.
func light_radius(pl: Necromancer) -> float:
	return float(cfg["light_radius"]) * lantern_mult(pl) * endless_light_mult()


## Radius (px) of a lit stone lantern's light pool now.
func lantern_radius() -> float:
	return float(cfg["lantern_radius"]) * endless_light_mult()


## Light (0..1) of a pool of radius `r` centred on `c` at world point `p`: 1
## inside, fading to 0 across its soft rim.
func _pool(p: Vector2, c: Vector2, r: float) -> float:
	var d := p.distance_to(c)
	if d >= r:
		return 0.0
	var inner := r * (1.0 - float(cfg["soft"]))  # Fully lit inside this (px).
	if d <= inner:
		return 1.0
	return smoothstep(r, inner, d)


## Light (0..1) of the lit lanterns' pools at `p` (0 when none is lit).
func lantern_light(p: Vector2) -> float:
	var best := 0.0
	var r := lantern_radius()
	for key: Vector2i in lit:
		best = maxf(best, _pool(p, lit[key], r))
	return best


## THE light at world point `p` (0..1): the phase's ambient light, or the
## brightest light pool there (each necromancer's, each lit lantern's).
func light_at(p: Vector2) -> float:
	var best := ambient()
	if best >= 1.0:
		return 1.0
	for pl in game.all_players:
		best = maxf(best, _pool(p, pl.position, light_radius(pl)))
	return maxf(best, lantern_light(p))


## True when `p` lies inside a lit stone lantern's pool (light at least SUN
## pool_light): ShadowAmbush never places a puff there. Own decision: the
## necromancer's own light is not a "lit pool" for this rule (it reveals the
## puffs inside the Bone Ring earlier instead), so ring ambushes stay possible.
func in_lit_pool(p: Vector2) -> bool:
	return lantern_light(p) >= float(cfg["pool_light"])


# =====================================================================================
# The timeline helper (night kinds only at night)
# =====================================================================================

## True for a night-only kind (its row's "night").
static func is_night_kind(kind: String) -> bool:
	return bool(EnemyDirector.shogunate_def(kind).get("night", false))


## THE timeline helper for the trickle: segment `seg`'s kind weights now. Its
## "weights" without the night kinds by day and at dusk; at night, its
## "weights" plus its optional "night_weights" (the night kinds join). Cached
## per segment and time of day (the trickle asks for every spawn).
func timeline_weights(seg: Dictionary) -> Dictionary:
	var night := is_night()
	if is_same(seg, _tw_seg) and night == _tw_night and not _tw.is_empty():
		return _tw
	var out: Dictionary = {}  # Kind -> weight.
	var w: Dictionary = seg["weights"]
	for k: String in w:
		if night or not is_night_kind(k):
			out[k] = w[k]
	if night:
		var nw: Dictionary = seg.get("night_weights", {})  # The night kinds of this segment.
		for k: String in nw:
			out[k] = float(out.get(k, 0.0)) + float(nw[k])
	if out.is_empty():
		out = w  # Never an empty table (a segment of night kinds only, by day).
	_tw_seg = seg
	_tw_night = night
	_tw = out
	return out


## THE timeline helper for the waves: `groups` ({kind, count, elite} each)
## without the night kinds by day and at dusk (a copy only when one is dropped).
func filter_groups(groups: Array) -> Array:
	if is_night():
		return groups
	var out: Array = []
	for g: Dictionary in groups:
		if not is_night_kind(String(g["kind"])):
			out.append(g)
	if out.size() != groups.size():
		game.stat_add("sun_night_groups_held", float(groups.size() - out.size()))
	return out


# =====================================================================================
# The simulation step
# =====================================================================================

## Per-tick update (ShogunateRules): phase changes (banners, `nightfall`, the
## stats) and, at night, the lantern scan.
func step(_delta: float) -> void:
	if not enabled:
		return
	var ph := phase()
	if ph != current:
		_quiet = _ov_active() or (_release_t >= 0.0 and game.elapsed - _release_t < 0.5)  # The sky override's own change: no banner.
		_enter_phase(ph)
		_quiet = false
	var t := game.elapsed
	if ph >= ShogunateRulesData.Phase.NIGHT and t >= _scan_at:
		_scan_at = t + float(cfg["scan_every"])
		_scan_lanterns()
	# While a phase blends, redraw the arena now and then so the long dusk
	# shadows grow and fade (drawing only).
	var blending := (t >= float(cfg["dusk_at"]) and t <= float(cfg["dusk_at"]) + float(cfg["blend"]) + 0.5) \
			or (t >= float(cfg["night_at"]) and t <= float(cfg["night_at"]) + float(cfg["blend"]) + 0.5) \
			or (not override.is_empty() and t <= float(override["t0"]) + float(cfg["blend"]) + 0.5) \
			or (_release_t >= 0.0 and t <= _release_t + float(cfg["blend"]) + 0.5)  # Act V, the Road to the Sun: the sky override blends.
	if blending and t >= _shadow_redraw_at:
		_shadow_redraw_at = t + 0.5
		game.arena.queue_redraw()


## Phase `ph` begins: the record, the banner and the sound.
func _enter_phase(ph: int) -> void:
	current = ph
	if not phase_started.has(ph):
		phase_started[ph] = game.elapsed  # The first time (the sky override may bring a phase back).
	game.stat_add("sun_phase_" + String(ShogunateRulesData.PHASE_NAMES[ph]).replace(" ", "_"), 1.0)
	match ph:
		ShogunateRulesData.Phase.DUSK:
			if game.elapsed > 0.5 and not _quiet:
				game.enemies.show_banner(String(cfg.get("dusk_banner", ShogunateRulesData.SUN_BANNERS["dusk"])))
		ShogunateRulesData.Phase.NIGHT:
			if game.elapsed > 0.5 and not _quiet:
				game.enemies.show_banner(String(cfg.get("night_banner", ShogunateRulesData.SUN_BANNERS["night"])))
			if game.shogunate != null and not _quiet:
				game.shogunate.play_sound("nightfall")
			_scan_at = game.elapsed
		ShogunateRulesData.Phase.ENDLESS_NIGHT:
			if game.shogunate != null:
				game.shogunate.play_sound("nightfall")


## Lights every stone lantern within lantern_scan px of a necromancer (each
## stays lit for the night); beyond max_lanterns the farthest from the primary
## necromancer goes out (it relights when someone comes back).
func _scan_lanterns() -> void:
	var reach := float(cfg["lantern_scan"])  # Scan radius (px).
	var cell := ArenaData.CELL
	var span := ceili(reach / cell)  # Cells each side.
	var lit_any := false
	for pl in game.all_players:
		var c := Vector2i(floori(pl.position.x / cell), floori(pl.position.y / cell))
		for dy in range(-span, span + 1):
			for dx in range(-span, span + 1):
				var key := c + Vector2i(dx, dy)
				if lit.has(key):
					continue
				var o := game.arena.obstacle_at(Vector2((float(key.x) + 0.5) * cell, (float(key.y) + 0.5) * cell))
				if o == null or o.kind != ShogunateGlyphs.LANTERN or o.center.distance_to(pl.position) > reach:
					continue
				lit[key] = o.center
				lit_any = true
				if not ever_lit.has(key):
					ever_lit[key] = true
					game.stat_add("sun_lanterns_lit", 1.0)
				if game.shogunate != null:
					game.shogunate.play_sound("lantern_lit", o.center)
	var cap := int(cfg["max_lanterns"])
	while lit.size() > cap:
		var far_key := Vector2i.ZERO
		var far_d := -1.0
		for key: Vector2i in lit:
			var d := (lit[key] as Vector2).distance_squared_to(game.player.position)
			if d > far_d:
				far_d = d
				far_key = key
		lit.erase(far_key)
		lit_any = true
	if lit_any:
		game.arena.queue_redraw()  # The lit lantern sprites (drawing only).


## True when the stone lantern at arena cell `key` is lit (its lit sprite).
func is_lit(key: Vector2i) -> bool:
	return lit.has(key)


# =====================================================================================
# Drawing (visual only)
# =====================================================================================

func _process(_delta: float) -> void:
	if not _draws:
		return
	var dark := darkness_alpha()
	var tint := dusk_amount()
	var busy := dark > 0.005 or tint > 0.005
	if busy:
		_update_darkness(dark)
	if busy or _drawn:
		queue_redraw()
		_glow.queue_redraw()
	_drawn = busy


## The visible world rect around the camera.
func _view() -> Rect2:
	var cam := game.camera
	var zoom := cam.zoom if cam != null else Vector2.ONE
	var sz := get_viewport_rect().size / zoom  # World px on screen.
	var c := cam.get_screen_center_position() if cam != null else game.player.position
	return Rect2(c - sz * 0.5, sz)


## Rebuilds the darkness image for this frame: every texel at `dark` alpha,
## then each light pool in view carves its soft hole (the lowest alpha wins).
func _update_darkness(dark: float) -> void:
	var cell := float(cfg["cell"])
	var view := _view().grow(cell * 2.0)
	_origin = (view.position / cell).floor() * cell
	var cols := ceili(view.size.x / cell) + 2
	var rows := ceili(view.size.y / cell) + 2
	var col: Color = cfg["night_color"]
	if _img == null or cols != _cols or rows != _rows:
		_cols = cols
		_rows = rows
		_img = Image.create(_cols, _rows, false, Image.FORMAT_RGBA8)
		_img.fill(Color(col, dark))
		_tex = ImageTexture.create_from_image(_img)
	_img.fill(Color(col, dark))
	if dark > 0.005:
		for pl in game.all_players:
			_carve(pl.position, light_radius(pl), dark, col)
		var lr := lantern_radius()
		for key: Vector2i in lit:
			var c: Vector2 = lit[key]
			if view.grow(lr).has_point(c):
				_carve(c, lr, dark, col)
	_tex.update(_img)


## Carves one light pool (centre `c`, radius `r` px) into the darkness image.
func _carve(c: Vector2, r: float, dark: float, col: Color) -> void:
	var cell := float(cfg["cell"])
	var x0 := maxi(0, floori((c.x - r - _origin.x) / cell))
	var x1 := mini(_cols - 1, ceili((c.x + r - _origin.x) / cell))
	var y0 := maxi(0, floori((c.y - r - _origin.y) / cell))
	var y1 := mini(_rows - 1, ceili((c.y + r - _origin.y) / cell))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var p := _origin + (Vector2(float(x), float(y)) + Vector2(0.5, 0.5)) * cell  # Texel centre (world px).
			var a := dark * (1.0 - _pool(p, c, r))  # Darkness left here.
			if a < _img.get_pixel(x, y).a:
				_img.set_pixel(x, y, Color(col, a))


## A soft radial light-pool sprite (white, alpha 1 at the centre fading to 0 at
## the rim), made once.
func _pool_texture() -> ImageTexture:
	if _pool_tex == null:
		var n := 64  # Texture size (px).
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		var c := (float(n) - 1.0) * 0.5
		for y in n:
			for x in n:
				var d := Vector2(float(x) - c, float(y) - c).length() / (float(n) * 0.5)  # 0 centre, 1 rim.
				var a := clampf(1.0 - d, 0.0, 1.0)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a * a))
		_pool_tex = ImageTexture.create_from_image(img)
	return _pool_tex


func _draw() -> void:
	var view := _view()
	var tint := dusk_amount()
	if tint > 0.005:
		draw_rect(view, Color(tint_color(), tint_alpha() * tint))  # The dusk wash (the sky override's colour while it rules).
	if _tex != null and darkness_alpha() > 0.005:
		draw_texture_rect(_tex, Rect2(_origin, Vector2(float(_cols), float(_rows)) * float(cfg["cell"])), false)


## Draws the light pools' sprites on `layer` (the additive child): a faint pale
## glow on each necromancer's pool (so it reads even on a dark floor) and the
## lit lanterns' warm pools. Visual only.
func draw_glows(layer: CanvasItem) -> void:
	var dark := darkness_alpha()
	if dark <= 0.005:
		return
	var view := _view()
	var k := clampf(dark / maxf(float(cfg["darkness"]), 0.01), 0.0, 1.0)  # Glow strength with the night.
	var pale := Color(ShogunateRulesData.NECRO_GLOW_COLOR, ShogunateRulesData.NECRO_GLOW_ALPHA * k)
	for pl in game.all_players:
		var pr := light_radius(pl)
		layer.draw_texture_rect(_pool_texture(), Rect2(pl.position - Vector2(pr, pr), Vector2(pr, pr) * 2.0), false, pale)
	var r := lantern_radius()
	var warm := Color(Palette.FLAME, ShogunateRulesData.LANTERN_GLOW_ALPHA * k)
	for key: Vector2i in lit:
		var c: Vector2 = lit[key]
		if view.grow(r).has_point(c):
			layer.draw_texture_rect(_pool_texture(), Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, warm)
