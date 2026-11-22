## DeckBounds — THE DECK, the second of the Black Tide's shared rules (Act X;
## GDD §15.0 "The Deck"; owner-approved proposal: "The necromancer, every summon
## and every boarder stay on the boat. The deck is the arena"). Owned by
## Game.corsair and set as `Game.deck` on a stage whose STAGE has "corsair" and
## a "deck" (null everywhere else). ONE BOUNDS PATH:
##   * THE SHAPE: a convex outline in arena coordinates (CorsairRulesData.DECK
##     + the STAGE "deck"): a rectangle `length` x `beam` with a tapered bow at
##     +x and a chamfered stern at -x. violation() is the one inside test (the
##     largest signed distance past an edge, the edges pushed in by a body's
##     radius); clamp_point() moves a point onto the deck (inset by a radius; a
##     negative radius is a band OUTSIDE the rail: the fliers'), and
##     walkable_point() slides a point inward along the line to another point.
##   * CONTAIN (contain_all(), the last step of Arena.resolve_all(), the slot
##     where the obstacle push-out already runs, as Ul-Thalos's shore):
##       - the necromancer (co-op: both) and every walking summon stop at the
##         rail (no damage, no loss);
##       - a FLIER (a summon that is airborne or flies: Gargoyles, Banshees,
##         Fallen Seraphs, Grave Drones; an enemy that flies) may hover up to
##         `flier_band` px past the rail and is pulled back when it leaves it
##         (a world rule for every flier on this map, not a class rule);
##       - every deck enemy (anything not in the water) is clamped too, but a
##         deck enemy pushed PAST THE RAIL drowns: its centre `drown_slack` px
##         beyond the rail line (a Bone Wall's push, a blast), or pressed
##         against the rail while its knockback carries it outward at
##         `drown_knock` px/s or more. It dies through
##         CombatResolver.damage_enemy() (source "overboard"; the one kill
##         path, so its XP drops at the rail). Bosses, minibosses, structures
##         and objectives never drown (they stop at the rail);
##       - SWIMMERS and BOATS (CorsairKit.in_water) ignore the deck;
##       - drops (XP crystals, power-ups, chests) that land in the water are
##         moved onto the deck every contain_interval ticks.
##   * Arena.free_point() clamps every placement onto the deck (spawns,
##     recalls, landings); StanceFormations moves each Bone Ring post through
##     walkable_point() (a post over the water slides inward toward the
##     necromancer: beside the rail the ring becomes a half-ring facing the
##     water; on the 360 px Cutter it flattens fore and aft).
##   * THE CAMERA (camera_point(), Game._process(), visual only): a deck that
##     fits the view keeps the camera still over it; a larger deck scrolls with
##     the necromancer, clamped to the deck plus water_margin px of sea.
## The rail and the rail band: rail_point() / nearest_rail() / rail_depth()
## (BoardingParty's boarding points, SeaStrikes' rail band, BlackTide's wave).
## The perimeter: perimeter_point() / perimeter_normal() (swimmers circle it).
## Determinism: geometry only, no RNG. Stats: deck_clamps_player /
## _summons / _enemies, deck_flier_pulls, overboard_<kind>, overboard_total,
## deck_drops_moved.
class_name DeckBounds
extends RefCounted

## Owning run.
var game: Game
## The deck's numbers (CorsairRulesData.DECK merged with the STAGE "deck").
var cfg: Dictionary = {}
## The deck's centre (world px).
var center: Vector2 = Vector2.ZERO
## Half the deck's length (px, along x).
var half_length: float = 480.0
## Half the deck's beam (px, along y).
var half_beam: float = 180.0
## The outline's corners (world px), in order around the deck (convex).
var outline: PackedVector2Array = PackedVector2Array()
## Outward unit normal of edge i (outline[i] -> outline[i + 1]).
var normals: PackedVector2Array = PackedVector2Array()
## Arc length (px) from outline[0] to the start of edge i (the perimeter).
var _edge_s: PackedFloat32Array = PackedFloat32Array()
## Total perimeter length (px).
var perimeter_length: float = 0.0
## Physics ticks since the run started (drop containment pacing).
var _frame: int = 0
## Enemies drowned this run (the report).
var drowned: int = 0
## Bone Ring posts asked for through walkable_point() (the report).
var posts: int = 0
## Of those, posts that hung over the water and slid inward (the report).
var posts_slid: int = 0
## Scratch: deck enemies found past the rail this tick (drowned after the loop).
var _drown: Array[Enemy] = []


## Builds the deck for `p_game` from `stage_deck` (the STAGE "deck"; any key of
## CorsairRulesData.DECK).
func _init(p_game: Game, stage_deck: Dictionary) -> void:
	game = p_game
	cfg = CorsairRulesData.DECK.duplicate()
	for k: String in stage_deck:
		cfg[k] = stage_deck[k]
	center = cfg["center"]
	half_length = float(cfg["length"]) * 0.5
	half_beam = float(cfg["beam"]) * 0.5
	_build()


## The convex outline: the stern's chamfered corners at -x, the straight rails,
## the bow's two-step taper to `bow_tip` at +x.
func _build() -> void:
	var hx := half_length
	var hy := half_beam
	var c := float(cfg["stern_cut"])
	var bow := float(cfg["bow"])
	var tip := float(cfg["bow_tip"])
	var bulge := tip + (hy - tip) * 0.75  # Half-beam at the bow's mid point (an outward curve).
	var pts := [Vector2(-hx, -hy + c), Vector2(-hx + c, -hy), Vector2(hx - bow, -hy), Vector2(hx - bow * 0.45, -bulge),
		Vector2(hx, -tip), Vector2(hx, tip), Vector2(hx - bow * 0.45, bulge), Vector2(hx - bow, hy), Vector2(-hx + c, hy),
		Vector2(-hx, hy - c)]
	outline = PackedVector2Array()
	for p: Vector2 in pts:
		outline.append(center + p)
	normals = PackedVector2Array()
	_edge_s = PackedFloat32Array()
	var s := 0.0
	var n := outline.size()
	for i in n:
		var a := outline[i]
		var b := outline[(i + 1) % n]
		var t := (b - a).normalized()
		var nn := Vector2(t.y, -t.x)  # One perpendicular ...
		if nn.dot((a + b) * 0.5 - center) < 0.0:
			nn = -nn  # ... pointing away from the centre (the outline is convex).
		normals.append(nn)
		_edge_s.append(s)
		s += a.distance_to(b)
	perimeter_length = s


# =====================================================================================
# Geometry
# =====================================================================================

## The largest signed distance (px) of `p` past an edge pushed in by `r`
## (> 0: outside that inset outline; <= 0: inside). `r` < 0 is a band outside.
func violation(p: Vector2, r: float) -> float:
	var worst := -INF
	for i in outline.size():
		worst = maxf(worst, normals[i].dot(p - outline[i]) + r)
	return worst


## Index of the edge `p` lies farthest past (the rail it is nearest to or beyond).
func _worst_edge(p: Vector2) -> int:
	var worst := -INF
	var at := 0
	for i in outline.size():
		var f := normals[i].dot(p - outline[i])
		if f > worst:
			worst = f
			at = i
	return at


## True when a body of radius `r` at `p` stands wholly on the deck.
func inside(p: Vector2, r: float) -> bool:
	return violation(p, r) <= 0.0


## True when `p` is over the water (past the rail line).
func is_water(p: Vector2) -> bool:
	return violation(p, 0.0) > 0.0


## `p` moved onto the deck for a body of radius `r` (unchanged when it already
## is): each edge it is past pushes it straight back in (a few passes settle
## the corners of the convex outline). A negative `r` keeps `p` within that
## many px OUTSIDE the rail (the fliers' band).
func clamp_point(p: Vector2, r: float) -> Vector2:
	var q := p
	for _pass in 3:
		var moved := false
		for i in outline.size():
			var f := normals[i].dot(q - outline[i]) + r
			if f > 0.0:
				q -= normals[i] * f
				moved = true
		if not moved:
			break
	return q


## THE RING-POST PATH (StanceFormations): a point `p` for a body of radius `r`
## that would hang over the water slides inward along the line to `toward`
## (the necromancer, on the deck) to the first point where it stands on the
## planks (exact: the line's entry into the inset outline). Unchanged when it
## is already on the deck.
func walkable_point(p: Vector2, toward: Vector2, r: float) -> Vector2:
	posts += 1
	if inside(p, r):
		return p
	posts_slid += 1
	var to := clamp_point(toward, r)  # The far end, on the deck.
	var t_in := 0.0  # Share of the line already outside an edge.
	for i in outline.size():
		var f0 := normals[i].dot(p - outline[i]) + r
		if f0 <= 0.0:
			continue
		var f1 := normals[i].dot(to - outline[i]) + r
		if f1 < f0:
			t_in = maxf(t_in, f0 / (f0 - f1))
	return clamp_point(p.lerp(to, clampf(t_in, 0.0, 1.0)), r)


## Distance (px) from `p` in to the nearest rail (> 0 on the deck, < 0 past it).
func rail_depth(p: Vector2) -> float:
	return -violation(p, 0.0)


## The point of the straight rail at `x` px along the deck from its centre, on
## side `side` (-1 = the upper rail, +1 = the lower), clamped to the straight
## part (stern_cut .. bow).
func rail_point(x: float, side: int) -> Vector2:
	var lo := -half_length + float(cfg["stern_cut"]) + 10.0
	var hi := half_length - float(cfg["bow"]) - 10.0
	return center + Vector2(clampf(x, lo, hi), half_beam * (1.0 if side > 0 else -1.0))


## Length (px) of each straight rail (the part a boat can lie against).
func straight_rail_length() -> float:
	return maxf(0.0, (half_length - float(cfg["bow"]) - 10.0) - (-half_length + float(cfg["stern_cut"]) + 10.0))


## [nearest point on the rail line, its outward normal] for `p` (on or off the deck).
func nearest_rail(p: Vector2) -> Array:
	var best := Vector2.ZERO
	var best_n := Vector2.UP
	var best_d := INF
	var n := outline.size()
	for i in n:
		var q := Geometry2D.get_closest_point_to_segment(p, outline[i], outline[(i + 1) % n])
		var d := q.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = q
			best_n = normals[i]
	return [best, best_n]


## The perimeter's point at arc length `s` px (wrapped) from outline[0].
func perimeter_point(s: float) -> Vector2:
	var i := _edge_at(s)
	var n := outline.size()
	var a := outline[i]
	var b := outline[(i + 1) % n]
	var len_i := a.distance_to(b)
	return a.lerp(b, clampf((fposmod(s, perimeter_length) - _edge_s[i]) / maxf(len_i, 0.01), 0.0, 1.0))


## The outward normal of the perimeter at arc length `s` px.
func perimeter_normal(s: float) -> Vector2:
	return normals[_edge_at(s)]


## Arc length (px) of the perimeter point nearest `p`.
func perimeter_s(p: Vector2) -> float:
	var best_s := 0.0
	var best_d := INF
	var n := outline.size()
	for i in n:
		var a := outline[i]
		var b := outline[(i + 1) % n]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := q.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best_s = _edge_s[i] + a.distance_to(q)
	return best_s


## Index of the edge holding arc length `s`.
func _edge_at(s: float) -> int:
	var w := fposmod(s, perimeter_length)
	var i := _edge_s.size() - 1
	while i > 0 and _edge_s[i] > w:
		i -= 1
	return i


## Where the camera looks for a view of `view` px (visual only): over the deck
## when it fits the view on an axis, else following `p` within the deck plus
## water_margin px of sea.
func camera_point(p: Vector2, view: Vector2) -> Vector2:
	var m := float(cfg["water_margin"])
	var out := p
	var ext := Vector2(half_length, half_beam) + Vector2(m, m)  # Half the area worth showing.
	for axis in 2:
		var half_view := view[axis] * 0.5
		if ext[axis] <= half_view:
			out[axis] = center[axis]
		else:
			out[axis] = clampf(p[axis], center[axis] - ext[axis] + half_view, center[axis] + ext[axis] - half_view)
	return out


# =====================================================================================
# Containment (Arena.resolve_all(), last step)
# =====================================================================================

## THE DECK RULE (see the header): players and summons stop at the rail,
## fliers keep to their band, deck enemies are clamped or drown, swimmers and
## boats are left to the sea.
func contain_all() -> void:
	_frame += 1
	var band := -float(cfg["flier_band"])  # A negative inset: the band outside the rail.
	for p in game.all_players:  # (Co-op: each necromancer.)
		var q := clamp_point(p.position, p.radius)
		if q != p.position:
			p.position = q
			game.stat_add("deck_clamps_player", 1.0)
	var n_s := 0  # Summons the rail stopped this tick.
	var n_f := 0  # Fliers pulled back into their band.
	for h in game.all_hordes:  # (Co-op: every army.)
		for u in h.units:
			if not u.active:
				continue
			var flier := u.airborne or u.flies
			var uq := clamp_point(u.position, band if flier else u.radius)
			if uq != u.position:
				u.position = uq
				if flier:
					n_f += 1
				else:
					n_s += 1
	if n_s > 0:
		game.stat_add("deck_clamps_summons", float(n_s))
	if n_f > 0:
		game.stat_add("deck_flier_pulls", float(n_f))
	_drown.clear()
	var n_e := 0  # Deck enemies the rail stopped this tick.
	var slack := float(cfg["drown_slack"])
	var knock := float(cfg["drown_knock"])
	for e in game.enemies.active:
		if not e.active or CorsairKit.is_in_water(e):
			continue  # A swimmer or a boat: the sea is its own.
		if e.flies:
			var fq := clamp_point(e.position, band)  # An enemy flier keeps to the band too.
			if fq != e.position:
				e.position = fq
			continue
		if violation(e.position, e.radius) <= 0.0:
			continue
		if _can_drown(e):
			var i := _worst_edge(e.position)
			var past := normals[i].dot(e.position - outline[i])  # px of its centre past the rail line.
			if past > slack or e.knockback.dot(normals[i]) >= knock:
				_drown.append(e)
				continue
		e.position = clamp_point(e.position, e.radius)
		n_e += 1
	if n_e > 0:
		game.stat_add("deck_clamps_enemies", float(n_e))
	for e in _drown:
		_overboard(e)
	if _frame % int(cfg["contain_interval"]) == 0:
		_contain_drops()


## True when deck enemy `e` can be knocked overboard (never a boss, a
## miniboss, a structure or an objective).
static func _can_drown(e: Enemy) -> bool:
	return not (e.is_boss or e.is_miniboss or e.is_structure or e.is_objective)


## Deck enemy `e` goes over the rail: set at the rail line, then the drowning
## blow through CombatResolver.damage_enemy() (its XP drops at the rail). A
## body that survives it (an immunity) is clamped back aboard.
func _overboard(e: Enemy) -> void:
	if not e.active:
		return
	var rail: Array = nearest_rail(e.position)
	e.position = (rail[0] as Vector2) - (rail[1] as Vector2) * 2.0
	var kind := e.kind
	var hit := e.max_hp * float(cfg["drown_hp_mult"]) + e.holy_shield + e.blood_shield  # Drowned outright.
	game.combat.damage_enemy(e, hit, CorsairRulesData.DROWN_SOURCE)
	if e.active:
		e.position = clamp_point(e.position, e.radius)
		e.knockback = Vector2.ZERO
		game.stat_add("overboard_survived", 1.0)
		return
	drowned += 1
	game.stat_add("overboard_total", 1.0)
	game.stat_add("overboard_" + kind, 1.0)
	game.effects.ring(rail[0], 18.0, Palette.CORSAIR_FOAM, 0.35)
	if game.corsair != null:
		game.corsair.play_sound("overboard", rail[0], 0.15)


## Moves every drop the water reached back onto the deck.
func _contain_drops() -> void:
	var moved := 0  # Drops moved this pass.
	for c in game.pickups.active:
		if c.active and violation(c.position, 6.0) > 0.0:
			c.position = clamp_point(c.position, 8.0)
			moved += 1
	for d in game.powerups.active:
		if d.active and violation(d.position, 10.0) > 0.0:
			d.position = clamp_point(d.position, 12.0)
			moved += 1
	for ch in game.chests.active:
		if ch.active and violation(ch.position, 14.0) > 0.0:
			ch.position = clamp_point(ch.position, 16.0)
			moved += 1
	if moved > 0:
		game.stat_add("deck_drops_moved", float(moved))


## The autotest bot's push away from the rail (inside rail_avoid px of it):
## the rail band is where the sea strikes and the boarders come over.
func danger_push(p: Vector2) -> Vector2:
	var reach := float(cfg["rail_avoid"])
	var depth := rail_depth(p)
	if depth >= reach:
		return Vector2.ZERO
	var rail: Array = nearest_rail(p)
	return -(rail[1] as Vector2) * (1.0 - clampf(depth / reach, 0.0, 1.0)) * 1.6
