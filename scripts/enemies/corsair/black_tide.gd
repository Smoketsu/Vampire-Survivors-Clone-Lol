## BlackTide — THE BLACK TIDE, the shared Reckoning of the pirate act (Act X;
## GDD §15.0 "The Black Tide"; owner-approved proposal: "at 0:00 every boat in
## the sea closes on the ship at once, the whole rail is a boarding point,
## gunboats shell in lines, and the kraken surfaces. The rail band is struck
## every 3 s and a great wave shoves everything toward the far rail every 20
## s"). Owned by Game.corsair; runs from the first Reckoning wave on a stage
## whose RECKONING has a "black_tide" dictionary (CorsairRulesData.BLACK_TIDE
## overrides), never elsewhere. Its parts, each through the act's own paths:
##   * THE BOATS: BoardingParty reads running(): the whole rail boards,
##     tide_max_boats at once, a shorter lane and pour (the Reckoning's heavy,
##     the Boarding Bruiser, and its companions come by boat through the one
##     spawn route).
##   * THE RAIL STRIKES: every strike_every s (x strike_speedup per minute past
##     0:00, never under strike_min) an ownerless strike (SeaStrikes.strike())
##     on the rail band beside a standing necromancer (seeded point).
##   * THE GREAT WAVE: every wave_every s a foam line shows on one rail
##     (wave_telegraph s; the side alternates, the first one seeded), then for
##     wave_time s everything is shoved toward the far rail: the necromancer
##     and the army through TerrainSlow.push_player() / push_summon() (they
##     stop at the rail: x Sea Legs for the army), every deck enemy through its
##     knockback (kept at wave_knock px/s outward), so the far rail drowns
##     them (DeckBounds); bosses, minibosses and structures stand. It deals
##     wave_damage once to every summon and necromancer.
##   * THE GUNBOATS (Act X, the Treasure Galleon's block): with a
##     "gunboat_every" > 0 (the Galleon's RECKONING) a gunboat comes alongside
##     every gunboat_every s (GunboatKit.launch(), capped) and shells the deck
##     in lines. The kraken's surfacing is the Maelstrom's.
## Determinism: the seeded gameplay RNG only (the strike points, the first
## wave's side). Stats: black_tide_strikes, black_tide_waves,
## black_tide_wave_pushes (enemies shoved), black_tide_drowned (overboard
## during a wave).
class_name BlackTide
extends RefCounted

## Owning run.
var game: Game
## True when this stage's Reckoning is the Black Tide.
var enabled: bool = false
## The Black Tide's numbers (CorsairRulesData.BLACK_TIDE + the RECKONING "black_tide").
var cfg: Dictionary = {}
## Game time (s) it began (-1 = not yet).
var started_at: float = -1.0
## Game time (s) of the next rail strike.
var _next_strike: float = 0.0
## Game time (s) the next wave's telegraph starts.
var _next_wave: float = 0.0
## The wave's side: the rail it comes from (+1 lower, -1 upper; it shoves toward the other).
var _side: int = 1
## Game time (s) the current wave starts shoving (telegraph before it; -1 = none).
var _wave_at: float = -1.0
## Rail strikes landed so far (the report).
var strikes: int = 0
## Waves rolled so far (the report).
var waves: int = 0
## Game time (s) of the next gunboat (Act X, the Treasure Galleon; INF = none).
var _next_gunboat: float = INF
## True once the current wave's start (its damage) has run.
var _wave_hit: bool = false
## Overboard count when the current wave started (the report's wave drownings).
var _drowned_before: int = 0


## Builds the Black Tide for `p_game`; `p_enabled` false off Act X.
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	var r: Dictionary = p_game.stage_def.get("reckoning", {})
	enabled = p_enabled and r.has("black_tide")
	if enabled:
		cfg = CorsairRulesData.BLACK_TIDE.duplicate()
		var over: Dictionary = r["black_tide"]
		for k: String in over:
			cfg[k] = over[k]


## True once the Black Tide began (0:00).
func running() -> bool:
	return started_at >= 0.0


## Per-tick update (CorsairRules.step(), before the boats).
func step(delta: float) -> void:
	if not enabled:
		return
	var now := game.elapsed
	if not running():
		if game.enemies.reckoning_wave <= 0:
			return
		started_at = now
		_next_strike = now + float(cfg["strike_every"])
		_next_wave = now + float(cfg["wave_every"]) - float(cfg["wave_telegraph"])
		_side = 1 if randf() < 0.5 else -1
		if float(cfg.get("gunboat_every", 0.0)) > 0.0:
			_next_gunboat = now + float(cfg["gunboat_every"]) * 0.5  # Act X, the Treasure Galleon: the gunboats.
	if now >= _next_gunboat:
		_next_gunboat = now + float(cfg["gunboat_every"])
		if GunboatKit.launch(game, game.enemies.hp_mult, 1.0, true) != null:
			game.stat_add("black_tide_gunboats", 1.0)
	if now >= _next_strike:
		_rail_strike()
		var mins := (now - started_at) / 60.0
		_next_strike = now + maxf(float(cfg["strike_min"]), float(cfg["strike_every"]) * pow(float(cfg["strike_speedup"]), mins))
	if _wave_at < 0.0 and now >= _next_wave:
		_wave_at = now + float(cfg["wave_telegraph"])
		_wave_hit = false
	if _wave_at >= 0.0 and now >= _wave_at:
		if not _wave_hit:
			_wave_hit = true
			_wave_start()
		_wave_push(delta)
		if now >= _wave_at + float(cfg["wave_time"]):
			_wave_at = -1.0
			_next_wave = now + float(cfg["wave_every"]) - float(cfg["wave_telegraph"])
			_side = -_side
			game.stat_add("black_tide_drowned", float(game.deck.drowned - _drowned_before))


## One ownerless strike on the rail band beside a standing necromancer.
func _rail_strike() -> void:
	var pl := game.nearest_player(game.deck.center)
	var side := 1 if randf() < 0.5 else -1
	var x := pl.position.x - game.deck.center.x + (randf() - 0.5) * 240.0
	var at := game.deck.rail_point(x, side) - Vector2(0.0, float(side)) * float(game.deck.cfg["rail_band"]) * (0.25 + 0.5 * randf())
	game.corsair.sea.strike(at, {"radius": float(cfg["strike_radius"])})
	strikes += 1
	game.stat_add("black_tide_strikes", 1.0)


## The wave hits: its damage, once.
func _wave_start() -> void:
	waves += 1
	_drowned_before = game.deck.drowned
	game.stat_add("black_tide_waves", 1.0)
	game.shake(3.0)
	game.corsair.play_sound("wave_crash", game.player.position, 1.0)
	var dm := game.enemies.damage_mult
	for pl in game.all_players:
		if not pl.dead:
			game.combat.damage_player(float(cfg["wave_damage"]) * dm, CorsairRulesData.WAVE_SOURCE, pl)
	for h in game.all_hordes:
		for u in h.units:
			if u.active and not u.airborne and not u.flies:
				game.combat.damage_unit(u, float(cfg["wave_damage"]) * dm, CorsairRulesData.WAVE_SOURCE)


## The shove toward the far rail, this tick.
func _wave_push(delta: float) -> void:
	var dir := Vector2(0.0, -float(_side))  # From the wave's rail toward the far one.
	var v := dir * float(cfg["wave_push"])
	for pl in game.all_players:
		if not pl.dead and not game.grave_step.is_dashing():
			pl.position += v * delta
	for h in game.all_hordes:
		for u in h.units:
			TerrainSlow.push_summon(game, u, v * game.corsair.sea_legs_mult(u), delta)
	var knock := float(cfg["wave_knock"])
	var n := 0
	for e in game.enemies.active:
		if not e.active or e.is_boss or e.is_miniboss or e.is_structure or e.untargetable or CorsairKit.is_in_water(e):
			continue
		var along := e.knockback.dot(dir)
		if along < knock:
			e.knockback += dir * (knock - along)
			n += 1
	game.stat_add("black_tide_wave_pushes", float(n))


## The autotest autopilot's push away from the far rail while a wave is due.
func danger_push(_p: Vector2) -> Vector2:
	if _wave_at < 0.0:
		return Vector2.ZERO
	return Vector2(0.0, float(_side)) * 0.6  # Lean into the wave (toward the rail it comes from).


## The wave's foam line on its rail while it telegraphs and rolls (visual only).
func draw(ci: CanvasItem) -> void:
	if _wave_at < 0.0:
		return
	var deck := game.deck
	var t := game.elapsed
	var k := clampf(1.0 - (_wave_at - t) / maxf(float(cfg["wave_telegraph"]), 0.01), 0.0, 1.0)
	var y := deck.center.y + deck.half_beam * float(_side)
	if t >= _wave_at:
		var roll := clampf((t - _wave_at) / maxf(float(cfg["wave_time"]), 0.01), 0.0, 1.0)
		y -= float(_side) * deck.half_beam * 2.0 * roll  # The crest crosses the deck.
	var x0 := deck.center.x - deck.half_length
	var x1 := deck.center.x + deck.half_length
	ci.draw_rect(Rect2(Vector2(x0, y - 4.0), Vector2(x1 - x0, 8.0)), Color(Palette.CORSAIR_SEA_LIGHT, 0.3 + 0.3 * k))
	ci.draw_line(Vector2(x0, y), Vector2(x1, y), Color(Palette.CORSAIR_FOAM_LIGHT, 0.5 + 0.5 * k), 2.0)
