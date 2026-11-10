## SeasonCycle — THE TURNING YEAR, the Turning Year's headline rule (temporary
## Act XV; GDD §15.0 "The Turning Year (seasons)"; owner-approved proposal: "the
## 20:00 clock is one year: four seasons of 5 minutes, on one SeasonCycle path,
## shown as a wheel on the HUD. Each season changes the arena for both
## armies"), owned by Game.wild as `seasons`. THE one season path: everything
## that asks "which season is it" calls season() here.
##   SPRING   roots grab every body that stands still `still_time` s (moved
##            under `still_px`) and hold it `hold` s: a summon through
##            SummonedUnit.held_until (it still strikes), the necromancer as a
##            strong slow through TerrainSlow (Grave Step breaks free), an
##            enemy through Enemy.apply_slow() (never a boss, a miniboss, a
##            structure or a flier). Spring Returns keeps them, faster.
##   SUMMER   wildfires: every `every` s a front `width` px wide starts
##            `spawn_dist` px from each standing necromancer at a seeded side
##            and runs through him; its smoke line shows `lead` s first; it
##            burns every body it crosses once (summons, the necromancer,
##            enemies by a share of their max HP; bosses, minibosses and
##            structures spared) and burns the thickets it crosses
##            (Thickets.burn_line()).
##   AUTUMN   corpses rot in `corpse_life` s (corpse_life(), read by
##            CorpseExplosion, the one corpse store) and the blight spreads
##            (BloomField reads the season); the leaves are the ground's tint.
##   WINTER   snow slows everyone `snow_slow` (TerrainSlow for the necromancer
##            and summons, Enemy.apply_slow() for enemies); blizzards cut
##            sight to `sight` px (drawing only in phase 1); the Winter Court
##            comes (rows with "season": "winter").
##   RETURNS  after 0:00 on a stage whose RECKONING has "spring_returns":
##            Spring Returns (SpringReturns; the roots grab at its still_time).
## Who comes: THE timeline helper timeline_weights() / filter_groups() keeps a
## row whose "season" is another season out of the trickle and the waves, and
## adds a segment's "season_weights"[season] (EnemyDirector calls them, as the
## Shogunate's night kinds).
## set_override(season, until) forces a season (phase 2: the Winter Prince's
## minute of winter, the Green Mother's Turning, the Last Claim's slots).
## Each season repaints the arena (Game.ground.modulate; drawing only) and the
## HUD wheel (SeasonWheel) shows the year. Off the act (a forced Wild kind on
## another stage) the clock is off: season() is -1 and nothing here runs.
## Determinism: game time and the seeded gameplay RNG (the fronts' sides).
## Stats: season_turns, roots_you / roots_summons / roots_enemies,
## wildfire_fronts, wildfire_summons / wildfire_summon_dmg / wildfire_player /
## wildfire_enemies / wildfire_kills, snow_slows, blizzards.
class_name SeasonCycle
extends RefCounted

## Owning run.
var game: Game
## True on a Wild stage (STAGE "wild"): the year turns; false off the act.
var enabled: bool = false
## The year's numbers (WildRulesData.SEASONS + the stage's "seasons").
var cfg: Dictionary = {}
## The season entered last (WildRulesData.SPRING..RETURNS; -1 before the first tick).
var current: int = -1
## Seasons entered this run, in order: [season index, game s] each (the report).
var entered: Array = []
## Forced season (set_override(); -1 = none).
var _override: int = -1
## Game time (s) the forced season ends.
var _override_until: float = 0.0
## Body -> [generation, anchor (Vector2), game s it stood still from] (the
## roots' stillness memory; rebuilt every sample from the live bodies).
var _still: Dictionary = {}
## Game time (s) of the next roots sample.
var _next_roots: float = 0.0
## Points where roots show (warning or holding), rebuilt every sample (drawing).
var roots_drawn: PackedVector2Array = PackedVector2Array()
## Live wildfire fronts: {origin, dir, t0 (game s the run starts), hit (Array of bodies)} each.
var fronts: Array = []
## Game time (s) of the next wildfire.
var _next_fire: float = INF
## Game time (s) of the next snow refresh.
var _next_snow: float = 0.0
## Game time (s) of the next blizzard.
var _next_blizzard: float = INF
## Game time (s) the current blizzard ends (0 = none).
var blizzard_until: float = 0.0
## Fronts started this run.
var fires: int = 0
## Blizzards this run.
var blizzards: int = 0


## Builds the year for `p_game`; `p_enabled`: a Wild stage.
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	enabled = p_enabled
	cfg = WildRulesData.SEASONS.duplicate()
	var over: Dictionary = p_game.stage_def.get("seasons", {})
	for key: String in over:
		cfg[key] = over[key]


## THE season now (WildRulesData.SPRING..RETURNS), or -1 off the act.
func season() -> int:
	if not enabled:
		return -1
	if _override >= 0 and game.elapsed < _override_until:
		return _override
	if game.countdown_finished() and game.wild.returns.on():
		return WildRulesData.RETURNS
	return int(floorf(game.elapsed / maxf(1.0, float(cfg["length"])))) % 4


## Id of the season now ("" off the act).
func season_id() -> String:
	var s := season()
	return WildRulesData.SEASON_IDS[s] if s >= 0 else ""


## Share (0..1) of the current season passed (the HUD wheel's hand); 0 after 0:00.
func season_fraction() -> float:
	if not enabled or game.countdown_finished():
		return 0.0
	var period := maxf(1.0, float(cfg["length"]))  # s, one season.
	return fmod(game.elapsed, period) / period


## Forces season `s` until game time `until` (phase 2: the Winter Prince, the
## Green Mother's Turning, the Last Claim). -1 clears it.
func set_override(s: int, until: float) -> void:
	_override = s
	_override_until = until


## Seconds a corpse lasts now (CorpseExplosion): `base` (AbilityData.CORPSE_LIFE)
## outside Autumn and Spring Returns.
func corpse_life(base: float) -> float:
	match season():
		WildRulesData.AUTUMN:
			return float(WildRulesData.AUTUMN_RULES["corpse_life"])
		WildRulesData.RETURNS:
			return float(game.wild.returns.cfg.get("corpse_life", base))
	return base


## True while a blizzard blows.
func blizzard() -> bool:
	return game.elapsed < blizzard_until


# =====================================================================================
# The timeline helper (EnemyDirector)
# =====================================================================================

## True when kind `kind` may come in season `s` (its row's "season", absent = any).
static func comes_in(kind: String, s: int) -> bool:
	var only := String(EnemyDirector.wild_def(kind).get("season", ""))
	return only == "" or s < 0 or (s < WildRulesData.SEASON_IDS.size() and WildRulesData.SEASON_IDS[s] == only)


## THE timeline helper for the trickle: segment `seg`'s kind weights in this
## season (its "weights" without other seasons' kinds, plus its
## "season_weights"[season id]). Off the act: the weights unchanged.
func timeline_weights(seg: Dictionary) -> Dictionary:
	var w: Dictionary = seg["weights"]
	var s := season()
	if s < 0:
		return w
	var out: Dictionary = {}
	for k: String in w:
		if comes_in(k, s):
			out[k] = w[k]
	var sw: Dictionary = (seg.get("season_weights", {}) as Dictionary).get(WildRulesData.SEASON_IDS[s], {})
	for k: String in sw:
		out[k] = float(out.get(k, 0.0)) + float(sw[k])
	return out if not out.is_empty() else w


## THE timeline helper for the waves: `groups` without other seasons' kinds (a
## copy only when one is dropped).
func filter_groups(groups: Array) -> Array:
	var s := season()
	if s < 0:
		return groups
	var out: Array = []
	for g: Dictionary in groups:
		if comes_in(String(g["kind"]), s):
			out.append(g)
	if out.size() != groups.size():
		game.stat_add("season_groups_held", float(groups.size() - out.size()))
	return out


# =====================================================================================
# The simulation step
# =====================================================================================

## Per tick (WildRules.step()).
func step(_delta: float) -> void:
	var s := season()
	if s < 0:
		return
	if s != current:
		_enter(s)
	var now := game.elapsed
	if s == WildRulesData.SPRING or s == WildRulesData.RETURNS:
		if now >= _next_roots:
			_next_roots = now + float(WildRulesData.ROOTS["sample"])
			_roots_sample(game.wild.returns.still_time() if s == WildRulesData.RETURNS else float(WildRulesData.ROOTS["still_time"]))
	elif not roots_drawn.is_empty():
		roots_drawn = PackedVector2Array()
		_still.clear()
	if s == WildRulesData.SUMMER and now >= _next_fire:
		_next_fire = now + float(cfg.get("wildfire_every", WildRulesData.WILDFIRE["every"]))  # A stage may space its fronts (the Fae Court's endless summer: STAGE "seasons" "wildfire_every").
		_start_fires()
	_step_fronts()
	if s == WildRulesData.WINTER:
		if now >= _next_snow:
			_next_snow = now + float(WildRulesData.WINTER_RULES["snow_every"])
			_snow()
		if now >= _next_blizzard:
			_next_blizzard = now + float(WildRulesData.WINTER_RULES["blizzard_every"])
			blizzard_until = now + float(WildRulesData.WINTER_RULES["blizzard_time"])
			blizzards += 1
			game.stat_add("blizzards", 1.0)
			game.wild.play_sound("blizzard", game.player.position, 1.0)


## Season `s` begins: the schedules, the banner, the arena's tint, the stats.
func _enter(s: int) -> void:
	var first := current < 0  # The run's first spring (no banner over the opening).
	current = s
	entered.append([s, game.elapsed])
	var now := game.elapsed
	_next_fire = now + float(WildRulesData.WILDFIRE["first"]) if s == WildRulesData.SUMMER else INF
	_next_blizzard = now + float(WildRulesData.WINTER_RULES["blizzard_first"]) if s == WildRulesData.WINTER else INF
	if s != WildRulesData.WINTER:
		blizzard_until = 0.0
	game.wild.tint_ground(WildRulesData.SEASON_TINTS[s])
	if first:
		return
	game.stat_add("season_turns", 1.0)
	game.enemies.show_banner(WildRulesData.SEASON_BANNERS[s])
	game.wild.play_sound("spring_returns" if s == WildRulesData.RETURNS else "season_turn", game.player.position, 1.0)


# --- Spring: the roots ---------------------------------------------------------------

## One stillness check of every body (see the header): a body still for
## `still_time` s is grabbed, then may not be grabbed again until it has stood
## still that long after the hold.
func _roots_sample(still_time: float) -> void:
	var now := game.elapsed
	var next: Dictionary = {}
	roots_drawn = PackedVector2Array()
	var grabbed := 0
	for pl in game.all_players:
		if not pl.dead:
			grabbed += _track(next, pl, 0, pl.position, now, still_time, 0)
	for hd in game.all_hordes:
		for u in hd.units:
			if u.active and u.state != SummonedUnit.State.SPAWNING and u.state != SummonedUnit.State.DEAD and not u.airborne and not u.flies:
				grabbed += _track(next, u, u.generation, u.position, now, still_time, 1)
	for e in game.enemies.active:
		if e.active and not e.is_boss and not e.is_miniboss and not e.is_structure and not e.is_objective \
				and not e.flies and not e.floating and not e.untargetable:
			grabbed += _track(next, e, e.generation, e.position, now, still_time, 2)
	_still = next
	if grabbed > 0:
		game.wild.play_sound("roots_grab", game.player.position, 1.0)


## Tracks one body (`type` 0 = necromancer, 1 = summon, 2 = enemy) into `next`;
## returns 1 when the roots grabbed it now.
func _track(next: Dictionary, body: Node2D, gen: int, pos: Vector2, now: float, still_time: float, type: int) -> int:
	var anchor := pos
	var since := now
	var prev: Variant = _still.get(body)
	if prev != null and int((prev as Array)[0]) == gen and ((prev as Array)[1] as Vector2).distance_to(pos) <= float(WildRulesData.ROOTS["still_px"]):
		anchor = (prev as Array)[1]
		since = float((prev as Array)[2])
	var hold := float(WildRulesData.ROOTS["hold"])
	var out := 0
	if now - since >= still_time:
		_grab(body, type, hold)
		since = now + hold  # Free again only after the hold, then still_time more.
		out = 1
	if (now - since >= still_time - float(WildRulesData.ROOTS["warn"]) or since > now) and roots_drawn.size() < 96:
		roots_drawn.append(pos)
	next[body] = [gen, anchor, since]
	return out


## The roots grab `body` for `hold` s (see the header).
func _grab(body: Node2D, type: int, hold: float) -> void:
	match type:
		0:
			if game.wild.slow_player(body as Necromancer, float(WildRulesData.ROOTS["player_slow"]), hold):
				game.stat_add("roots_you", 1.0)
		1:
			var u := body as SummonedUnit
			u.held_until = maxf(u.held_until, game.elapsed + hold * game.wild.deadwood_mult())
			game.stat_add("roots_summons", 1.0)
		_:
			(body as Enemy).apply_slow(float(WildRulesData.ROOTS["enemy_slow"]), hold)
			game.stat_add("roots_enemies", 1.0)


# --- Summer: the wildfires ------------------------------------------------------------

## A front from a seeded side of each standing necromancer, aimed through him.
func _start_fires() -> void:
	var cf := WildRulesData.WILDFIRE
	for pl in game.all_players:
		if pl.dead:
			continue
		var origin := pl.position + Vector2.from_angle(randf() * TAU) * float(cf["spawn_dist"])
		fronts.append({"origin": origin, "dir": (pl.position - origin).normalized(), "t0": game.elapsed + float(cf["lead"]), "hit": []})
		fires += 1
		game.stat_add("wildfire_fronts", 1.0)
	game.wild.play_sound("wildfire_warn", game.player.position, 1.0)


## Where front `f` burns now (its origin until it runs).
func front_pos(f: Dictionary) -> Vector2:
	var run := maxf(0.0, game.elapsed - float(f["t0"]))
	return (f["origin"] as Vector2) + (f["dir"] as Vector2) * float(WildRulesData.WILDFIRE["speed"]) * run


## True when a body of radius `r` at `p` stands in front `f`'s fire.
func _in_fire(f: Dictionary, p: Vector2, r: float) -> bool:
	var rel := p - front_pos(f)
	var dir: Vector2 = f["dir"]
	return absf(rel.dot(dir)) <= float(WildRulesData.WILDFIRE["depth"]) * 0.5 + r and absf(rel.dot(dir.orthogonal())) <= float(WildRulesData.WILDFIRE["width"]) * 0.5


## Runs every front one tick: the burn, the thickets, the end of the run.
func _step_fronts() -> void:
	var cf := WildRulesData.WILDFIRE
	var i := fronts.size() - 1
	while i >= 0:
		var f: Dictionary = fronts[i]
		var run := game.elapsed - float(f["t0"])
		if run >= float(cf["length"]) / float(cf["speed"]):
			fronts.remove_at(i)
		elif run >= 0.0:
			_burn(f)
		i -= 1


## One burn tick of front `f` (each body once a front).
func _burn(f: Dictionary) -> void:
	var cf := WildRulesData.WILDFIRE
	var ts := game.enemies.damage_mult  # The time scaling (and the difficulty).
	var hit: Array = f["hit"]
	var any := false
	for hd in game.all_hordes:
		for u in hd.units:
			if not u.active or u.state == SummonedUnit.State.SPAWNING or u.airborne or hit.has(u) or not _in_fire(f, u.position, u.radius):
				continue
			hit.append(u)
			var dmg := float(cf["burn_summon"]) * ts
			game.combat.damage_unit(u, dmg, WildRulesData.WILDFIRE_SOURCE)
			game.stat_add("wildfire_summons", 1.0)
			game.stat_add("wildfire_summon_dmg", dmg)
			any = true
	for pl in game.all_players:
		if pl.dead or hit.has(pl) or not _in_fire(f, pl.position, pl.radius):
			continue
		hit.append(pl)
		game.combat.damage_player(float(cf["burn_player"]) * ts, WildRulesData.WILDFIRE_SOURCE, pl)
		game.stat_add("wildfire_player", 1.0)
		any = true
	for e in game.enemies.active:
		if not e.active or e.is_boss or e.is_miniboss or e.is_structure or e.is_objective or hit.has(e) or not _in_fire(f, e.position, e.radius):
			continue
		hit.append(e)
		game.combat.damage_enemy(e, e.max_hp * float(cf["burn_enemy_share"]), WildRulesData.WILDFIRE_SOURCE)
		game.stat_add("wildfire_enemies", 1.0)
		if not e.active:
			game.stat_add("wildfire_kills", 1.0)
		any = true
	game.wild.thickets.burn_line(front_pos(f), f["dir"], float(cf["width"]), float(cf["depth"]))
	if any:
		game.wild.play_sound("wildfire_burn", front_pos(f), 0.3)


# --- Winter: the snow -----------------------------------------------------------------

## One snow refresh: every body on the ground slowed `snow_slow` until the next.
func _snow() -> void:
	var cw := WildRulesData.WINTER_RULES
	var f := float(cw["snow_slow"])
	var linger := float(cw["snow_every"]) + 0.25  # To the next refresh and a little more.
	for pl in game.all_players:
		if not pl.dead:
			game.wild.slow_player(pl, f, linger)
	for hd in game.all_hordes:
		for u in hd.units:
			if u.active and not u.airborne and not u.flies and u.state != SummonedUnit.State.SPAWNING and u.state != SummonedUnit.State.DEAD:
				TerrainSlow.slow_summon(game, u, f, linger)
	for e in game.enemies.active:
		if e.active and not e.is_boss and not e.is_miniboss and not e.is_structure and not e.flies and not e.floating:
			e.apply_slow(f, linger)
	game.stat_add("snow_slows", 1.0)


# =====================================================================================
# The autotest and the drawing
# =====================================================================================

## The autotest autopilot's push sideways out of every wildfire's path at `p`.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var cf := WildRulesData.WILDFIRE
	for f: Dictionary in fronts:
		var dir: Vector2 = f["dir"]
		var rel := p - front_pos(f)
		var along := rel.dot(dir)
		var lat := rel.dot(dir.orthogonal())
		var left := float(cf["length"]) - float(cf["speed"]) * maxf(0.0, game.elapsed - float(f["t0"]))  # px the front still runs.
		if along < -float(cf["depth"]) or along > left or absf(lat) > float(cf["width"]) * 0.5 + 30.0:
			continue
		push += dir.orthogonal() * (1.5 if lat >= 0.0 else -1.5)
	return push


## True while something of the year shows on the over layer.
func showing() -> bool:
	return not fronts.is_empty() or not roots_drawn.is_empty() or blizzard()


## Draws the roots, the fronts and the blizzard on `ci` (WildRules' layer;
## rects, disc textures and one radial texture only).
func draw(ci: CanvasItem, blizzard_tex: Texture2D) -> void:
	for p: Vector2 in roots_drawn:
		for k in 3:
			var a := float(k) * 2.1 + p.x * 0.01
			ci.draw_rect(Rect2(p + Vector2(cos(a), sin(a) * 0.5) * 9.0 - Vector2(1.0, 3.0), Vector2(2.0, 6.0)), Color(Palette.WILD_BARK, 0.85))  # A root shoot.
	var cf := WildRulesData.WILDFIRE
	var w := float(cf["width"])
	var depth := float(cf["depth"])
	for f: Dictionary in fronts:
		var run := game.elapsed - float(f["t0"])
		var ahead := float(cf["speed"]) * (float(cf["lead"]) if run >= 0.0 else float(cf["lead"]) + run)  # The smoke line: where the fire is in `lead` s.
		ci.draw_set_transform(front_pos(f), (f["dir"] as Vector2).angle(), Vector2.ONE)
		ci.draw_rect(Rect2(Vector2(ahead - 1.5, -w * 0.5), Vector2(3.0, w)), Color(Palette.WILD_ASH, 0.75))
		if run >= 0.0:
			ci.draw_rect(Rect2(Vector2(-depth * 0.5, -w * 0.5), Vector2(depth, w)), Color(Palette.WILD_FIRE, 0.4))
			ci.draw_rect(Rect2(Vector2(depth * 0.1, -w * 0.5), Vector2(depth * 0.4, w)), Color(Palette.WILD_GOLD_LEAF, 0.35))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if blizzard() and blizzard_tex != null:
		var sight := float(WildRulesData.WINTER_RULES["sight"])
		var c := game.player.position
		var outer := sight * 1.6  # The texture's edge: fully white from here out.
		var snow := Color(Palette.WILD_FROST, 0.82)
		ci.draw_texture_rect(blizzard_tex, Rect2(c - Vector2.ONE * outer, Vector2.ONE * outer * 2.0), false, snow)
		var far := 2400.0  # px: beyond any view.
		ci.draw_rect(Rect2(c + Vector2(-far, -far), Vector2(far * 2.0, far - outer)), snow)
		ci.draw_rect(Rect2(c + Vector2(-far, outer), Vector2(far * 2.0, far - outer)), snow)
		ci.draw_rect(Rect2(c + Vector2(-far, -outer), Vector2(far - outer, outer * 2.0)), snow)
		ci.draw_rect(Rect2(c + Vector2(outer, -outer), Vector2(far - outer, outer * 2.0)), snow)
