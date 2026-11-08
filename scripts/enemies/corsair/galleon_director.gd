## GalleonDirector — the stage systems of the Treasure Galleon (Stage 29 until
## the reorder; Act X, the Black Tide; GDD §15.0 "The Treasure Galleon (Act X
## phase 2)"; owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md
## Part 1 "Stage 2: the Treasure Galleon"), owned and stepped by EnemyDirector
## on a stage whose STAGE has a "galleon" config (GalleonStage.GALLEON; null
## elsewhere). Boarding, the Deck, the sea's strikes and the Black Tide are the
## shared CorsairRules'. Here:
##   * THE ZONES (GalleonStage.ZONES, clock-driven): the Convoy Lane, the
##     Reef, the Storm, the Gun Deck. At each start the banner shows,
##     GalleonGround switches its look (set_zone()) and the broadside rhythm
##     changes. The map never changes (the camera scrolls the one deck).
##   * BROADSIDES (GalleonData.BROADSIDE; owner-approved proposal "every 70
##     s an enemy galleon alongside fires a 6-line broadside: 1.5 s telegraph,
##     both armies, knockback on enemies"): every zone's "broadside_every" s
##     (the first at BROADSIDE "first") an enemy galleon shows alongside a
##     seeded rail and its lanes run straight across the deck round the
##     nearest necromancer (a seeded offset, so standing still is not safe),
##     telegraphed (EffectManager.telegraph_line()); then every lane is hit at
##     once: summons and necromancers through OlympusHits.lane(), deck enemies
##     through CombatResolver.damage_enemy() and a knockback toward the far
##     rail (DeckBounds drowns them there). broadside() is also Admiral
##     Marrec's (the Fleet: her flagship's 30 s rhythm).
##   * THE DECK CANNONS (GalleonData.CANNONS; a WORLD rule, never a class
##     rule): the eight "deck_cannon" obstacles of the fixed layout. Any summon
##     or necromancer within `reach` px of a cannon's footprint mans it; manned
##     for `charge` s it fires once at the nearest boat, gunboat or surfaced
##     swimmer in `range` (a seeded pick between near-equals) through
##     CombatResolver.damage_enemy() (source deck_cannon), with a splash that
##     knocks the boarders at that rail toward the sea; then it cools.
##   * OLD HOLLOW-EYE ("hollow_eye" event): the miniboss swimmer, forced past
##     the sea's swimmer cap with "arms" Kraken Arms beside it
##     (OldHollowEyeKit registers the HUD bar).
##   * The HUD objective: the Admiral's plank, a broadside's telegraph, Old
##     Hollow-Eye while it lives.
##   * danger_push() for the autotest bot (out of the broadside lanes),
##     added to CorsairRules.danger_push().
## Drawing: the enemy galleon alongside, each cannon's charge ring and the
## cannonballs' tracers (textures; z -5: on the deck, under the bodies).
## Deterministic: the seeded gameplay RNG only (the broadside's rail and
## offset, the lane jitter, the cannon's pick). Stats: broadsides,
## broadside_lane_hits (summons), broadside_enemy_hits, broadside_enemy_dmg,
## cannon_shots, cannon_dmg, cannon_kills, cannon_splash_hits, cannon_manned_s,
## hollow_eye_* (and the kits').
class_name GalleonDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (GalleonStage.GALLEON).
var config: Dictionary = {}
## Log of Galleon events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Index of the current zone in the STAGE "zones" (-1 before the first).
var zone_index: int = -1
## Game time (s) of the next zone broadside.
var _next_broadside: float = 0.0
## Game time (s) the telegraphed broadside lands (-1 = none).
var _bs_land: float = -1.0
## The telegraphed broadside's rail (+1 lower, -1 upper; the galleon's side).
var _bs_side: int = 1
## The telegraphed broadside's lane centres (x, world px).
var _bs_lanes: PackedFloat32Array = PackedFloat32Array()
## Game time (s) until which the enemy galleon is drawn alongside.
var _ship_until: float = -1.0
## x (world px) of the enemy galleon alongside.
var _ship_x: float = 0.0
## The deck cannons: each {at (Vector2), half (Vector2 footprint half-size),
## charge (s), cool (s left), manned (bool)}.
var cannons: Array[Dictionary] = []
## Cannonball tracers (drawn only): each {from, to, t (game s)}.
var _shots: Array[Dictionary] = []
## Old Hollow-Eye once spawned (null before / after; generation-checked).
var _eye: Enemy = null
## Generation of `_eye` when it spawned.
var _eye_gen: int = 0
## "m:ss" Old Hollow-Eye fell ("" while alive / never spawned).
var eye_time: String = ""
## Scratch query buffer.
var _buf: Array = []
## True when something was drawn last frame (one more redraw clears it).
var _drawn: bool = false


func _ready() -> void:
	z_index = -5  # On the deck and the sea, under every body (as CorsairRules).
	_next_broadside = float(GalleonData.BROADSIDE["first"])
	for f: Dictionary in (game.stage_def["arena"] as Dictionary).get("fixed", []):
		if String(f["kind"]) != GalleonData.CANNON_KIND:
			continue
		var def: Dictionary = (game.stage_def["arena"] as Dictionary)["kinds"][GalleonData.CANNON_KIND]
		var sizes: Array = def["sizes"]
		var long_half := float(sizes[clampi(int(f.get("size", 0)), 0, sizes.size() - 1)]) * 0.5
		var short_half := float(def["short"]) * 0.5
		var half := Vector2(short_half, long_half) if bool(f.get("vertical", false)) else Vector2(long_half, short_half)
		cannons.append({"at": (f["at"] as Vector2).round(), "half": half, "charge": 0.0, "cool": 0.0, "manned": false})


## Per-tick update (EnemyDirector): the zones, the broadsides, the cannons,
## Old Hollow-Eye's fall.
func step(delta: float) -> void:
	if game.deck == null:
		return
	_update_zone()
	var now := game.elapsed
	if _bs_land < 0.0 and now >= _next_broadside and game.enemies.boss == null:
		var every := float(_zone().get("broadside_every", 0.0))
		_next_broadside = now + (every if every > 0.0 else INF)
		if every > 0.0:
			broadside(1 if randf() < 0.5 else -1, "zone")
	if _bs_land >= 0.0 and now >= _bs_land:
		_fire_broadside()
	_step_cannons(delta)
	if _eye != null and not (_eye.active and _eye.generation == _eye_gen):
		_eye = null
		eye_time = _clock()
		_log("hollow_eye_down")
	var i := 0
	while i < _shots.size():
		if now >= float(_shots[i]["t"]) + float(GalleonData.CANNONS["shot_time"]):
			_shots.remove_at(i)
			continue
		i += 1
	var busy := not _shots.is_empty() or now < _ship_until or _any_charge()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## The current zone's row (the STAGE "zones" entry; {} before the first).
func _zone() -> Dictionary:
	var zones: Array = game.stage_def.get("zones", [])
	return zones[zone_index] if zone_index >= 0 and zone_index < zones.size() else {}


## Advances to the last zone whose start has come: banner, floor look, rhythm.
func _update_zone() -> void:
	var zones: Array = game.stage_def.get("zones", [])
	var moved := false
	while zone_index + 1 < zones.size() and game.elapsed >= float(zones[zone_index + 1]["start"]):
		zone_index += 1
		moved = true
	if not moved:
		return
	var z := _zone()
	if zone_index > 0:
		game.enemies.show_banner(String(z.get("banner", z["name"])))
		var every := float(z.get("broadside_every", 0.0))
		if every > 0.0 and _bs_land < 0.0:
			_next_broadside = minf(_next_broadside, game.elapsed + every)
	if game.ground is GalleonGround:
		(game.ground as GalleonGround).set_zone(z.get("ground", {}))
	game.stat_add("galleon_zones", 1.0)
	_log("zone_" + String(z["id"]))


# =====================================================================================
# Broadsides
# =====================================================================================

## AN ENEMY GALLEON'S BROADSIDE from rail `side` (+1 lower, -1 upper), its
## lanes round the nearest necromancer (see the header). `by` names who fired
## it for the stats ("zone" or "marrec"). False when one is already telegraphed.
func broadside(side: int, by: String) -> bool:
	if _bs_land >= 0.0 or game.deck == null:
		return false
	var b := GalleonData.BROADSIDE
	var deck := game.deck
	var pl := game.nearest_player(deck.center)
	var n := int(b["lines"])
	var spacing := float(b["spacing"])
	var shift := (randf() - 0.5) * spacing  # The lanes do not centre on him: standing still is not safe.
	var lo := deck.center.x - deck.half_length + 30.0
	var hi := deck.center.x + deck.half_length - 30.0
	_bs_lanes.clear()
	for i in n:
		var x := pl.position.x + shift + (float(i) - float(n - 1) * 0.5) * spacing + (randf() * 2.0 - 1.0) * float(b["jitter"])
		_bs_lanes.append(clampf(x, lo, hi))
	_bs_side = side
	var tel := float(b["telegraph"])
	_bs_land = game.elapsed + tel
	_ship_x = pl.position.x + shift
	_ship_until = game.elapsed + float(b["ship_time"])
	var y0 := deck.center.y + deck.half_beam * float(side)
	for x in _bs_lanes:
		game.effects.telegraph_line(Vector2(x, y0), Vector2(x, y0 - float(side) * deck.half_beam * 2.0), float(b["width"]), tel)
	game.stat_add("broadsides", 1.0)
	game.stat_add("broadsides_" + by, 1.0)
	_log("broadside_" + by)
	if game.corsair != null:
		game.corsair.play_sound("cannon_fire", Vector2(_ship_x, y0), 0.5)
	return true


## The broadside lands: every lane at once (see the header).
func _fire_broadside() -> void:
	_bs_land = -1.0
	var b := GalleonData.BROADSIDE
	var deck := game.deck
	var y0 := deck.center.y + deck.half_beam * float(_bs_side)
	var dir := Vector2(0.0, -float(_bs_side))  # Across the deck, toward the far rail.
	var length := deck.half_beam * 2.0
	var width := float(b["width"])
	var dm := game.enemies.damage_mult
	var hp := game.enemies.hp_mult
	var struck := {}
	for x in _bs_lanes:
		var from := Vector2(x, y0)
		game.stat_add("broadside_lane_hits", float(OlympusHits.lane(game, from, dir, length, width, float(b["dmg_player"]) * dm,
				float(b["dmg_summon"]) * dm, GalleonData.BROADSIDE_SOURCE, null, struck, _buf)))
		for k in 3:
			game.effects.impact(from + dir * length * (0.2 + 0.3 * float(k)), 16.0, Palette.CORSAIR_LANTERN)
	var hits: Array[Enemy] = []
	for e in game.enemies.active:
		if not e.active or e.is_boss or e.is_miniboss or e.is_structure or e.untargetable or CorsairKit.is_in_water(e):
			continue
		for x in _bs_lanes:
			if absf(e.position.x - x) <= width * 0.5 + e.radius:
				hits.append(e)
				break
	var knock := float(b["knock"])
	for e in hits:
		if not e.active:
			continue
		e.knockback += dir * knock / maxf(e.mass * 0.5, 1.0)
		game.stat_add("broadside_enemy_dmg", game.combat.damage_enemy(e, float(b["dmg_enemy"]) * hp, GalleonData.BROADSIDE_SOURCE))
		game.stat_add("broadside_enemy_hits", 1.0)
	game.shake(3.0)
	if game.corsair != null:
		game.corsair.play_sound("cannon_hit", game.player.position, 0.3)


## True while a broadside is telegraphed (the HUD objective, BossMarrec).
func broadside_pending() -> bool:
	return _bs_land >= 0.0


# =====================================================================================
# The deck cannons
# =====================================================================================

## Charges every manned cannon and fires the full ones (see the header).
func _step_cannons(delta: float) -> void:
	var cfg := GalleonData.CANNONS
	var reach := float(cfg["reach"])
	for c in cannons:
		var at: Vector2 = c["at"]
		var half: Vector2 = c["half"]
		if float(c["cool"]) > 0.0:
			c["cool"] = float(c["cool"]) - delta
			c["manned"] = false
			continue
		var manned := false
		for pl in game.all_players:
			if not pl.dead and _rect_dist(pl.position, at, half) <= reach + pl.radius:
				manned = true
				break
		if not manned:
			game.ally_grid.query(at, half.length() + reach + UnitData.MAX_BLOCK_RADIUS, _buf)
			for u: SummonedUnit in _buf:
				if u.active and u.state != SummonedUnit.State.DEAD and not u.airborne and _rect_dist(u.position, at, half) <= reach + u.radius:
					manned = true
					break
		c["manned"] = manned
		if manned:
			c["charge"] = minf(float(cfg["charge"]), float(c["charge"]) + delta)
			game.stat_add("cannon_manned_s", delta)
		else:
			c["charge"] = maxf(0.0, float(c["charge"]) - delta * float(cfg["drain"]))
		if float(c["charge"]) >= float(cfg["charge"]):
			var t := _cannon_target(at, float(cfg["range"]))
			if t != null:
				_fire_cannon(c, t)


## Distance (px) from `p` to the rect of half-size `half` centred on `at` (0 inside).
static func _rect_dist(p: Vector2, at: Vector2, half: Vector2) -> float:
	var dx := maxf(absf(p.x - at.x) - half.x, 0.0)
	var dy := maxf(absf(p.y - at.y) - half.y, 0.0)
	return sqrt(dx * dx + dy * dy)


## The cannon's mark: the nearest boat, gunboat or surfaced swimmer within
## `reach` px of `at`, a seeded pick among those within 40 px of the nearest; null when none.
func _cannon_target(at: Vector2, reach: float) -> Enemy:
	var cands: Array = []
	var best := INF
	for e in game.enemies.active:
		if not e.active or e.untargetable or not CorsairKit.is_in_water(e) or e.is_boss:
			continue
		var dist := e.position.distance_to(at)
		if dist <= reach:
			cands.append([dist, e])
			best = minf(best, dist)
	var near: Array[Enemy] = []
	for c: Array in cands:
		if float(c[0]) <= best + 40.0:
			near.append(c[1])
	if near.is_empty():
		return null
	return near[randi() % near.size()]


## Cannon `c` fires at `t` (the hit lands at once; the tracer is drawn).
func _fire_cannon(c: Dictionary, t: Enemy) -> void:
	var cfg := GalleonData.CANNONS
	var hp := game.enemies.hp_mult
	c["charge"] = 0.0
	c["cool"] = float(cfg["cooldown"])
	var at: Vector2 = c["at"]
	var hit_at := t.position
	_shots.append({"from": at, "to": hit_at, "t": game.elapsed})
	var gen := t.generation
	game.stat_add("cannon_dmg", game.combat.damage_enemy(t, float(cfg["damage"]) * hp, GalleonData.CANNON_SOURCE))
	game.stat_add("cannon_shots", 1.0)
	if not t.active or t.generation != gen:
		game.stat_add("cannon_kills", 1.0)
	var out := Vector2.ZERO  # Toward the sea at that rail.
	if game.deck != null:
		out = (game.deck.nearest_rail(hit_at)[1] as Vector2)
	game.enemy_grid.query(hit_at, float(cfg["splash"]) + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var splash: Array[Enemy] = []
	for e: Enemy in _buf:
		if e.active and not e.is_structure and not e.is_boss and not e.is_miniboss and not CorsairKit.is_in_water(e) and e.position.distance_to(hit_at) <= float(cfg["splash"]) + e.radius:
			splash.append(e)
	for e in splash:
		if not e.active:
			continue
		e.knockback += out * float(cfg["splash_knock"]) / maxf(e.mass * 0.5, 1.0)
		game.combat.damage_enemy(e, float(cfg["splash_dmg"]) * hp, GalleonData.CANNON_SOURCE)
		game.stat_add("cannon_splash_hits", 1.0)
	game.effects.impact(hit_at, float(cfg["splash"]), Palette.CORSAIR_LANTERN)
	if game.corsair != null:
		game.corsair.play_sound("cannon_fire", at, 0.15)


## True while any cannon holds part of a charge (drawing).
func _any_charge() -> bool:
	for c in cannons:
		if float(c["charge"]) > 0.0:
			return true
	return false


# =====================================================================================
# Old Hollow-Eye and the timeline's events
# =====================================================================================

## Runs a Galleon timeline event (EnemyDirector forwards the "hollow_eye" type).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"hollow_eye":
			var sea := game.corsair.sea if game.corsair != null else null
			if sea != null and sea.spawn_swimmer(String(ev.get("kind", GalleonEnemyData.HOLLOW_EYE)), game.enemies.hp_mult, false, 1.0, false, true):
				var last: Array = sea.swimmers[sea.swimmers.size() - 1]
				_eye = last[0]
				_eye_gen = int(last[1])
				for k in int(ev.get("arms", 0)):
					sea.spawn_swimmer("kraken_arm", game.enemies.hp_mult, false, 1.0, false, true)
				game.shake(5.0)
				game.corsair.play_sound("kraken_rise", _eye.position)
				_log("hollow_eye_rises")
	game.enemies.show_banner(String(ev["banner"]))


## HUD objective for the live Galleon objective ("" if none): the Admiral's
## plank, a telegraphed broadside, then Old Hollow-Eye.
func objective_override() -> String:
	var boss := game.enemies.boss
	if boss != null and boss.active and boss is BossMarrec and (boss as BossMarrec).on_plank():
		return String(config["plank_objective"])
	if _bs_land >= 0.0:
		return String(config["broadside_objective"])
	if _eye != null:
		return String(config["hollow_eye_objective"])
	return ""


## Autotest hint: sideways out of a telegraphed broadside lane.
func danger_push(p: Vector2) -> Vector2:
	if _bs_land < 0.0:
		return Vector2.ZERO
	var half := float(GalleonData.BROADSIDE["width"]) * 0.5 + float(GalleonData.BROADSIDE["danger_margin"]) + game.player.radius
	var push := Vector2.ZERO
	for x in _bs_lanes:
		var dx := p.x - x
		if absf(dx) < half:
			push.x += (signf(dx) if absf(dx) > 0.5 else 1.0) * (1.0 - absf(dx) / half) * 2.4
	return push


# =====================================================================================
# Summary and drawing
# =====================================================================================

## One-line autotest summary.
func summary_line() -> String:
	return "zones %d | broadsides %d (zone %d, marrec %d) | old hollow-eye %s | events %s" % [
		zone_index + 1, int(game.stats.get("broadsides", 0.0)), int(game.stats.get("broadsides_zone", 0.0)),
		int(game.stats.get("broadsides_marrec", 0.0)),
		("killed at " + eye_time) if eye_time != "" else ("alive" if _eye != null else "not spawned"),
		", ".join(fired) if not fired.is_empty() else "-"]


## Records a Galleon event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]


## The enemy galleon alongside, the cannons' charge rings, the tracers.
func _draw() -> void:
	if game == null or game.deck == null:
		return
	var now := game.elapsed
	var deck := game.deck
	if now < _ship_until:
		var y := deck.center.y + (deck.half_beam + float(GalleonData.BROADSIDE["ship_off"])) * float(_bs_side)
		var at := Vector2(_ship_x, y)
		if not SpriteBank.draw_flat(self, GalleonData.SHIP_SPRITE, at, 0.0, Color(0.85, 0.85, 0.9), float(GalleonData.BROADSIDE["ship_scale"])):
			draw_rect(Rect2(at - Vector2(130.0, 34.0), Vector2(260.0, 68.0)), Palette.CORSAIR_OAK_DARK)
	var ring := CityGlyphs.ring_texture()
	var full := float(GalleonData.CANNONS["charge"])
	for c in cannons:
		var k := float(c["charge"]) / full
		if k <= 0.0:
			continue
		var r := 16.0 + 14.0 * k
		var at: Vector2 = c["at"]
		draw_texture_rect(ring, Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(Palette.CORSAIR_LANTERN, 0.35 + 0.55 * k))
	for s in _shots:
		var a := clampf(1.0 - (now - float(s["t"])) / float(GalleonData.CANNONS["shot_time"]), 0.0, 1.0)
		var from: Vector2 = s["from"]
		var to: Vector2 = s["to"]
		var p := from.lerp(to, 1.0 - a)
		SpriteBank.draw_disc(self, p, 4.0, Color(Palette.CORSAIR_INK, a))
		SpriteBank.draw_disc(self, p, 2.0, Color(Palette.CORSAIR_LANTERN_LIGHT, a))
