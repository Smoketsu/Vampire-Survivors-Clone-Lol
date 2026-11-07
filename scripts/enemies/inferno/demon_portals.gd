## DemonPortals — THE PORTALS, the second of the Inferno's shared rules (Act VI;
## GDD §15.0 "Portals"; owner-approved proposal: "Demon portals are structures
## that pour out a squad every few seconds. They can be destroyed by damage, or
## sealed: the necromancer standing inside a portal's ring for 3 s closes it at
## once and pays a Soul Ash bounty. It forces him to walk into danger, which no
## other act asks"), owned by Game.inferno. THE one path of every portal:
##   * open(at, opts): THE public call. A `demon_portal` structure (PORTALS
##     kind; InfernoEnemyData) rises at `at`, out of obstacles, kept clear of
##     new obstacles (Arena.keep_clear()), never recycled (Enemy.is_objective).
##     The stage timelines place portals through the event type "portal"
##     (start_event(): `count` portals around the necromancer between
##     distance_min and distance_max px, spaced, at seeded angles); the Last
##     Judgment opens its own at 0:00.
##   * POUR: pour_first s after it opens, then every pour_every s (x the Last
##     Judgment's pour_mult in the Reckoning), a portal pours a squad from its
##     table (opts "table", else the stage's STAGE "portals" table, else
##     PORTALS table: rows {kind, count, weight}, a seeded weighted pick) out of
##     its edge, while the hard cap leaves room and a necromancer is within
##     pour_reach px (no off-screen flood).
##   * DESTROYED by damage (the shared CombatResolver path: its XP, no bounty).
##   * SEALED: while a necromancer (either one, in co-op) stands with his centre
##     inside seal_radius px of the portal, its seal fills; seal_time s seals it
##     at once (it is taken off the field without a kill) and pays ash_per_seal
##     Soul Ash through the objective bounty path (stat "objective_ash", as
##     Ilion's towers and the Wastes' pylons). Outside the ring the seal drains
##     at seal_decay s per s. Drawn as a dotted ring with a progress arc of
##     disc textures (no polygons).
##   * The autotest bot's one sealing behaviour: seek_point() (the autotest
##     walks into a ring when its army holds and it is calm).
## A stage's STAGE "portals" dictionary overrides any InfernoRulesData.PORTALS
## key ({} = the defaults). Determinism: the seeded gameplay RNG only (placement
## angles, squad picks), only on an Act VI stage or a forced portal. Stats:
## portals_opened, portals_destroyed, portals_sealed, portal_seal_ash,
## portal_squads, portal_units, portal_squads_capped, portals_reckoning.
class_name DemonPortals
extends Node2D

## One standing portal.
class Portal:
	extends RefCounted
	## The portal's Enemy node.
	var enemy: Enemy = null
	## Generation of `enemy` when it opened (stale / death guard).
	var gen: int = 0
	## Last known world position.
	var pos: Vector2 = Vector2.ZERO
	## Game time (s) of its next squad.
	var next_pour: float = 0.0
	## s between two squads.
	var pour_every: float = 7.0
	## Its squad table (rows {kind, count, weight}).
	var table: Array = []
	## Seal progress (s of a necromancer standing in its ring).
	var seal: float = 0.0
	## True for a portal the Last Judgment opened (stats).
	var reckoning: bool = false


## Owning run.
var game: Game
## The portals' numbers (InfernoRulesData.PORTALS, then the stage's "portals").
var cfg: Dictionary = {}
## Standing portals.
var portals: Array[Portal] = []
## Portals opened this run.
var opened: int = 0
## Portals destroyed by damage this run.
var destroyed: int = 0
## Portals sealed this run.
var sealed: int = 0
## Soul Ash paid by sealed portals this run.
var seal_ash: float = 0.0
## Squads poured this run.
var squads: int = 0
## "m:ss" of each seal (the autotest line).
var seal_times: PackedStringArray = PackedStringArray()
## True while open() spawns its portal (adopt() then leaves it to open()).
var _opening: bool = false
## True when this build draws (never headless).
var _draws: bool = false
## True if the last redraw showed something.
var _drawn: bool = false


## Builds the portals for `p_game` (InfernoRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "DemonPortals"
	z_index = -7  # The rings lie on the ground, under the bodies.
	z_as_relative = false
	cfg = InfernoRulesData.PORTALS.duplicate()
	var over: Dictionary = p_game.stage_def.get("portals", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# Public API
# =====================================================================================

## THE public call (phase 2 and the Last Judgment): opens a portal at world
## point `at`. opts (all optional): "table" (its squad rows), "pour_every"
## (s), "pour_first" (s), "reckoning" (bool: the Last Judgment's), "silent"
## (bool: no sound). Returns its Enemy, or null when max_open portals stand.
func open(at: Vector2, opts: Dictionary = {}) -> Enemy:
	if portals.size() >= int(cfg["max_open"]) and not bool(opts.get("reckoning", false)):
		game.stat_add("portals_refused", 1.0)
		return null
	var kind := String(cfg["kind"])
	_opening = true
	var e := game.enemies.spawn_at(kind, at, false)
	_opening = false
	if e == null:
		return null
	e.is_objective = true  # Never recycled: it stands until destroyed or sealed.
	game.arena.keep_clear(e.position, e.radius + ArenaData.MAX_HALF_EXTENT * 1.5)
	var p := Portal.new()
	p.enemy = e
	p.gen = e.generation
	p.pos = e.position
	p.table = opts.get("table", cfg["table"])
	p.pour_every = float(opts.get("pour_every", cfg["pour_every"]))
	p.next_pour = game.elapsed + float(opts.get("pour_first", cfg["pour_first"]))
	p.reckoning = bool(opts.get("reckoning", false))
	portals.append(p)
	opened += 1
	game.stat_add("portals_opened", 1.0)
	if p.reckoning:
		game.stat_add("portals_reckoning", 1.0)
	game.effects.spawn_ring(e.position, Palette.INFERNO_CHARM)
	if not bool(opts.get("silent", false)) and game.inferno != null:
		game.inferno.play_sound("portal_open", e.position)
	return e


## A demon_portal enemy `e` that did not come through open() (one forced with
## --spawn=demon_portal@T, or spawned by a phase 2 script with spawn_at()) is
## taken in as a portal with the default numbers (DemonPortalKit.reset() calls
## it), so every demon portal pours and can be sealed.
func adopt(e: Enemy) -> void:
	if _opening:
		return
	e.is_objective = true
	var p := Portal.new()
	p.enemy = e
	p.gen = e.generation
	p.pos = e.position
	p.table = cfg["table"]
	p.pour_every = float(cfg["pour_every"])
	p.next_pour = game.elapsed + float(cfg["pour_first"])
	portals.append(p)
	opened += 1
	game.stat_add("portals_opened", 1.0)


## A timeline "portal" event (EnemyDirector forwards it): `count` portals around
## the necromancer, spread evenly from a seeded angle, between distance_min and
## distance_max px (PORTALS dist_min / dist_max when absent), spaced; then the
## banner. Event keys: count, banner, distance_min, distance_max, table,
## pour_every (all optional but count).
func start_event(ev: Dictionary) -> void:
	var n := int(ev.get("count", 1))
	var p := game.player.position
	var offset := randf() * TAU  # Angle of the first portal.
	var placed: Array[Vector2] = []
	var r := float(game.enemies.enemy_def(String(cfg["kind"]))["radius"])  # Portal body radius.
	var opts := {}
	if ev.has("table"):
		opts["table"] = ev["table"]
	if ev.has("pour_every"):
		opts["pour_every"] = ev["pour_every"]
	var made := 0
	for i in n:
		var best := p
		for _try in int(cfg["placement_tries"]):
			var a := offset + TAU * float(i) / float(maxi(1, n)) + randf_range(-0.35, 0.35)
			var d := randf_range(float(ev.get("distance_min", cfg["dist_min"])), float(ev.get("distance_max", cfg["dist_max"])))
			var pos := game.arena.free_point(p + Vector2.from_angle(a) * d, r)
			var spaced := true
			for q in placed:
				spaced = spaced and q.distance_to(pos) >= float(cfg["spacing"])
			best = pos
			if spaced:
				break
		placed.append(best)
		if open(best, opts) != null:
			made += 1
	if made > 0 and String(ev.get("banner", "")) != "":
		game.enemies.show_banner(String(ev["banner"]))


## Autotest bot (the one sealing behaviour): the nearest standing portal within
## `reach` px of `p` (its centre: standing there seals it), or Vector2.INF. A
## portal whose seal is under way counts as half as far (the bot finishes it).
func seek_point(p: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	for pt in portals:
		var d := p.distance_to(pt.pos) * (0.5 if pt.seal > 0.0 else 1.0)  # Effective distance (px).
		if d < best_d:
			best = pt.pos
			best_d = d
	return best


## Portals standing now.
func standing() -> int:
	return portals.size()


## Seal progress (0..1) of the portal nearest `p` within its seal ring (0 = none).
func seal_progress_at(p: Vector2) -> float:
	for pt in portals:
		if p.distance_to(pt.pos) <= float(cfg["seal_radius"]):
			return clampf(pt.seal / maxf(float(cfg["seal_time"]), 0.01), 0.0, 1.0)
	return 0.0


# =====================================================================================
# Per tick
# =====================================================================================

## Per-tick update (InfernoRules.step()): fallen portals, seals, squads.
func step(delta: float) -> void:
	var i := 0
	var now := game.elapsed
	var reck := game.inferno != null and game.inferno.judgment.running()  # The Last Judgment pours faster.
	while i < portals.size():
		var pt := portals[i]
		var e := pt.enemy
		if not e.active or e.generation != pt.gen:
			_on_destroyed(pt)
			portals.remove_at(i)
			continue
		pt.pos = e.position
		var inside := false
		var near := false  # A necromancer within pour_reach (the portal pours only then).
		for pl in game.all_players:
			if pl.dead:
				continue
			var dist := pl.position.distance_to(pt.pos)
			near = near or dist <= float(cfg["pour_reach"])
			if dist <= float(cfg["seal_radius"]):
				inside = true
		if inside:
			pt.seal += delta
			if pt.seal >= float(cfg["seal_time"]):
				_on_sealed(pt)
				portals.remove_at(i)
				continue
		else:
			pt.seal = maxf(0.0, pt.seal - float(cfg["seal_decay"]) * delta)
		if now >= pt.next_pour:
			if near:
				_pour(pt)
			var every := pt.pour_every
			if reck and game.inferno != null:
				every *= float(game.inferno.judgment.cfg["pour_mult"])
			pt.next_pour = now + every
		i += 1
	if _draws:
		var busy := not portals.is_empty()
		if busy or _drawn:
			queue_redraw()
		_drawn = busy


## Portal `pt` pours one squad (a seeded weighted pick of its table) out of its
## edge, while the hard cap leaves room.
func _pour(pt: Portal) -> void:
	if pt.table.is_empty():
		return
	var total := 0.0
	for row: Dictionary in pt.table:
		total += float(row.get("weight", 1.0))
	var roll := randf() * total
	var pick: Dictionary = pt.table[pt.table.size() - 1]
	for row: Dictionary in pt.table:
		roll -= float(row.get("weight", 1.0))
		if roll <= 0.0:
			pick = row
			break
	var n := int(pick.get("count", 1))
	if game.enemies.regular_alive() + n + int(cfg["cap_margin"]) > game.enemies.hard_cap():
		game.stat_add("portal_squads_capped", 1.0)
		return
	var kind := String(pick["kind"])
	var base := randf() * TAU
	var r := pt.enemy.radius + float(cfg["pour_spread"])
	for k in n:
		var at := pt.pos + Vector2.from_angle(base + TAU * float(k) / float(maxi(1, n))) * r
		game.enemies.spawn_at(kind, at, bool(pick.get("elite", false)))
	squads += 1
	game.stat_add("portal_squads", 1.0)
	game.stat_add("portal_units", float(n))
	if kind == InfernoEnemyData.IMP and game.inferno != null:
		game.inferno.play_sound("imp_cackle", pt.pos)


## A portal fell to damage (its XP came through the kill).
func _on_destroyed(pt: Portal) -> void:
	destroyed += 1
	game.stat_add("portals_destroyed", 1.0)
	game.effects.impact(pt.pos, 60.0, Palette.INFERNO_LAVA)


## A necromancer sealed portal `pt`: it closes at once (no kill) and pays its
## Soul Ash bounty through the objective path.
func _on_sealed(pt: Portal) -> void:
	sealed += 1
	var ash := float(cfg["ash_per_seal"])
	seal_ash += ash
	seal_times.append(EmpireReport._clock(game.elapsed))
	game.stat_add("portals_sealed", 1.0)
	game.stat_add("portal_seal_ash", ash)
	game.stat_add("objective_ash", ash)  # The bounty path every stage objective pays through.
	game.effects.impact(pt.pos, 70.0, Palette.INFERNO_CHARM_LIGHT)
	game.shake(3.0)
	if game.inferno != null:
		game.inferno.play_sound("portal_seal", pt.pos)
	game.enemies.show_banner("A portal is sealed! +%d Soul Ash" % int(ash))
	game.enemies.despawn(pt.enemy)


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## Each portal's sealing ring (a dotted ring of disc textures on the ground) and,
## while a necromancer stands in it, the seal's progress (brighter, bigger dots
## filling clockwise from the top).
func _draw() -> void:
	var sr := float(cfg["seal_radius"])
	var st := maxf(float(cfg["seal_time"]), 0.01)
	var n := InfernoRulesData.SEAL_DOTS
	var spin := game.elapsed * 0.6  # The ring turns slowly (rad).
	for pt in portals:
		var k := clampf(pt.seal / st, 0.0, 1.0)  # Seal progress.
		for i in n:
			var a := spin + TAU * float(i) / float(n)
			SpriteBank.draw_disc(self, pt.pos + Vector2.from_angle(a) * sr, 1.6, Color(Palette.INFERNO_CHARM, 0.35))
		if k <= 0.0:
			continue
		var lit := ceili(k * float(n))  # Dots of progress.
		for i in lit:
			var a := -PI * 0.5 + TAU * float(i) / float(n)
			SpriteBank.draw_disc(self, pt.pos + Vector2.from_angle(a) * sr, 3.4, Color(InfernoRulesData.SEAL_COLOR, 0.95))
		SpriteBank.draw_disc(self, pt.pos, sr * (0.3 + 0.7 * k), Color(InfernoRulesData.SEAL_COLOR, 0.12 + 0.1 * k))
