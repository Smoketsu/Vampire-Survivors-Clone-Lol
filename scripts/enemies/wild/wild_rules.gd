## WildRules — the Turning Year's shared rules (temporary Act XV, final slot
## XV, the campaign finale; GDD §15.0 "The Turning Year foundation (phase 1)",
## "The Turning Year (seasons)", "Bloom and Blight", "Overgrowth" and "Spring
## Returns"), run as `Game.wild`. Null on every other act (created in
## Game._ready() only for a stage whose STAGE has "wild": true), except that a
## Wild kind forced onto any other stage with --spawn= creates it on its first
## activation through Game.wild_rules() (WildKit.reset()), so a kind works
## anywhere; there the clocks stay off (`enabled` false: no seasons, no blight,
## no Spring Returns) and only what the kind itself uses runs (a dryad's seeds).
## Owns ONE path per rule:
##   seasons   — SeasonCycle: THE TURNING YEAR (season(), the one season read;
##               the roots, the wildfires, the rot, the snow and the blizzards;
##               the timeline helper for who comes).
##   bloom     — BloomField: BLOOM AND BLIGHT (blight_at(), the one ground
##               read; the Wild's heal on living ground).
##   thickets  — Thickets: OVERGROWTH (plant(), the one planting path; the
##               catches, the spread, the burning and the withering).
##   returns   — SpringReturns: the Reckoning (RECKONING "spring_returns").
## It draws the act's world-space marks on two layers: the UNDER layer (a child
## Node2D under the units: the blight and the sprouts, redrawn each bloom
## sample or while a sprout shows) and its own OVER layer (the roots, the
## wildfire fronts, the blizzard; rects, disc textures and one radial texture,
## redrawn only while one shows). It also shows the year on the HUD
## (SeasonWheel, never headless) and repaints the arena each season
## (tint_ground(); drawing only).
## Hooks for the future counter-passives (exactly neutral today):
## deadwood_mult() (Deadwood: roots and thickets hold summons half as long) and
## fallow_mult() (Fallow Ground: blight spreads twice as fast); phase 2 builds
## the passives.
## Stepped by Game after the enemies (and the Titans' rules) and before the
## obstacle push-out, so a body inside a thicket that just grew is pushed out
## before it is drawn.
## Determinism: game time, pure hashes and the seeded gameplay RNG (the fronts'
## sides, the burials), and only while it exists (this act, or a forced Wild kind).
class_name WildRules
extends Node2D

## Owning run.
var game: Game
## True on a Wild stage (STAGE "wild"): the clocks may run; false when a forced
## Wild kind made the rules elsewhere.
var enabled: bool = false
## The Turning Year (the seasons).
var seasons: SeasonCycle
## Bloom and Blight (the living ground).
var bloom: BloomField
## Overgrowth (the thorn thickets).
var thickets: Thickets
## Spring Returns (the Reckoning).
var returns: SpringReturns
## Wild kind -> game time (s) of its first activation this run (the autotest's
## "wild kinds" line).
var first_seen: Dictionary = {}
## Sound event -> game time (s) it last played (rate limits).
var _sound_at: Dictionary = {}
## True when this build draws (never headless).
var _draws: bool = false
## True while the last over-layer redraw showed a mark (one more redraw clears it).
var _drawn_any: bool = false
## The under layer (blight, sprouts), a child drawn below the units.
var _under: Node2D = null
## Game time (s) of the next under-layer redraw.
var _under_at: float = 0.0
## The blizzard's radial snow texture (null headless).
var _blizzard_tex: GradientTexture2D = null
## The HUD's season wheel (null headless or off the act).
var _wheel: SeasonWheel = null
# --- Act XV (temporary number): the Fae Court --- the Summer Queen's bargain (take_bargain()).
## Army damage share a struck bargain adds (0 while none holds).
var bargain_bonus: float = 0.0
## Game time (s) a struck bargain ends (0 = none holds).
var bargain_until: float = 0.0
## True while a struck bargain forbids the army's healing.
var bargain_no_heal: bool = false


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "WildRules"
	z_index = 14  # Over the units, as the Titans' telegraphs.
	z_as_relative = false
	enabled = bool(p_game.stage_def.get("wild", false))
	seasons = SeasonCycle.new(p_game, enabled)
	bloom = BloomField.new(p_game, enabled)
	thickets = Thickets.new(p_game)
	returns = SpringReturns.new(p_game, enabled)
	_draws = DisplayServer.get_name() != "headless"
	if _draws:
		_under = Node2D.new()
		_under.name = "WildUnder"
		_under.z_as_relative = false
		_under.z_index = -8  # Over the floor (-10), under the obstacles (-6) and the units.
		_under.draw.connect(_draw_under)
		add_child(_under)
		var g := Gradient.new()  # Clear inside the sight, snow beyond.
		var k := float(WildRulesData.WINTER_RULES["sight"]) / (float(WildRulesData.WINTER_RULES["sight"]) * 1.6)  # The sight's share of the texture's radius.
		g.set_offset(0, 0.0)
		g.set_color(0, Color(1, 1, 1, 0))
		g.set_offset(1, 1.0)
		g.set_color(1, Color(1, 1, 1, 1))
		g.add_point(k, Color(1, 1, 1, 0))
		_blizzard_tex = GradientTexture2D.new()
		_blizzard_tex.gradient = g
		_blizzard_tex.fill = GradientTexture2D.FILL_RADIAL
		_blizzard_tex.fill_from = Vector2(0.5, 0.5)
		_blizzard_tex.fill_to = Vector2(1.0, 0.5)
		_blizzard_tex.width = 128
		_blizzard_tex.height = 128


## Per-tick update (Game, after the enemies, before the obstacle push-out):
## Spring Returns' clock, the year, the ground, the thickets; then the redraws.
func step(delta: float) -> void:
	if bargain_until > 0.0 and game.elapsed >= bargain_until:
		bargain_until = 0.0  # The Summer Queen's bargain lapses (the Fae Court).
		bargain_bonus = 0.0
		bargain_no_heal = false
		_recompute_armies()
	returns.step(delta)
	seasons.step(delta)
	bloom.step(delta)
	thickets.step(delta)
	if not _draws:
		return
	if enabled and _wheel == null and game.hud != null:
		_wheel = SeasonWheel.new()
		_wheel.game = game
		_wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		game.hud.add_child(_wheel)
	if _wheel != null:
		_wheel.refresh()
	var now_shows := seasons.showing()  # A mark shows on the over layer this tick.
	if now_shows or _drawn_any:
		_drawn_any = now_shows
		queue_redraw()
	if game.elapsed >= _under_at or thickets.showing():
		_under_at = game.elapsed + float(bloom.cfg["sample"])
		_under.queue_redraw()


# =====================================================================================
# Hooks (the kits, the rules' parts)
# =====================================================================================

## A Wild kind's enemy `e` was activated (WildKit.reset()): its first time is recorded.
func note_spawn(e: Enemy) -> void:
	if not first_seen.has(e.kind):
		first_seen[e.kind] = game.elapsed


## Plays the sound of Wild event `event` (WildRulesData.SOUNDS) at `pos`, at
## most once every `gap` game seconds.
func play_sound(event: String, pos: Vector2 = Vector2.INF, gap: float = 0.0) -> void:
	if gap > 0.0:
		if game.elapsed - float(_sound_at.get(event, -INF)) < gap:
			return
		_sound_at[event] = game.elapsed
	var id := String(WildRulesData.SOUNDS.get(event, ""))
	if id != "":
		Sfx.play(id, pos)


## Slows necromancer `pl` by `fraction` for at least `linger` s through
## TerrainSlow (the one ground-slow path; it reads the bound slot, so co-op binds
## `pl`'s first). True when it took.
func slow_player(pl: Necromancer, fraction: float, linger: float) -> bool:
	var prev := -1
	if game.coop != null:
		prev = game.coop.bound
		game.coop.bind(game.coop.slot_of(pl))
	var took := TerrainSlow.slow_player(game, fraction, linger) > 0.0
	if prev >= 0:
		game.coop.bind(prev)
	return took


## Repaints the arena for a season: the floor's tint (drawing only).
func tint_ground(c: Color) -> void:
	if _draws and game.ground != null:
		game.ground.modulate = c


## The autotest autopilot's push away from every live Wild telegraph at `p`
## (the wildfires' paths).
func danger_push(p: Vector2) -> Vector2:
	return seasons.danger_push(p)


func _draw() -> void:
	seasons.draw(self, _blizzard_tex)


## Draws the under layer: the blight round the necromancer, then the sprouts.
func _draw_under() -> void:
	bloom.draw(_under, game.player.position, 1100.0)
	thickets.draw(_under)


# =====================================================================================
# Counter-passive hooks (Deadwood, Fallow Ground: not built in phase 1)
# =====================================================================================

## DEADWOOD (hook): x every root and thicket hold on the bound player's
## summons (1 - the passive's hold_cut; proposal: "roots and thickets hold
## summons half as long"). Exactly 1 while the passive does not exist;
## SeasonCycle._grab(), Thickets._catch() and SpringReturns._bury() read it.
func deadwood_mult() -> float:
	return clampf(1.0 - game.abilities.passive_value(WildRulesData.DEADWOOD, WildRulesData.DEADWOOD_KEY), 0.0, 1.0)


## FALLOW GROUND (hook): x the blight's rise under the bound player's army
## (1 + the passive's blight_rise; proposal: "blight spreads twice as fast").
## Exactly 1 while the passive does not exist; BloomField._rise() reads it.
func fallow_mult() -> float:
	return 1.0 + game.abilities.passive_value(WildRulesData.FALLOW_GROUND, WildRulesData.FALLOW_GROUND_KEY)


# =====================================================================================
# The Summer Queen's bargain (the Fae Court; Act XV phase 2)
# =====================================================================================

## THE one bargain path (BossSummerQueen.answer_bargain()): for `time` s every
## army deals `damage` more (HordeDirector.compute_stats() reads
## bargain_damage(), its own category) and, when `no_heal`, heals no more
## (CombatResolver.heal_unit() reads heal_barred()). A new bargain replaces the
## one holding. Off the Fae Court nothing calls it, so both reads stay neutral.
func take_bargain(damage: float, time: float, no_heal: bool) -> void:
	bargain_bonus = damage
	bargain_until = game.elapsed + time
	bargain_no_heal = no_heal
	_recompute_armies()


## Army damage share of the bargain holding now (0 when none).
func bargain_damage() -> float:
	return bargain_bonus if game.elapsed < bargain_until else 0.0


## True while a bargain forbids the army's healing.
func heal_barred() -> bool:
	return bargain_no_heal and game.elapsed < bargain_until


## Every army's summons take their stats again (the bargain began or ended;
## co-op: each slot bound in turn).
func _recompute_armies() -> void:
	if game.coop == null:
		game.horde.recompute_all(game.horde.capacity_snapshot())
		return
	var prev := game.coop.bound
	for i in game.coop.slots.size():
		game.coop.bind(i)
		game.horde.recompute_all(game.horde.capacity_snapshot())
	game.coop.bind(prev)
