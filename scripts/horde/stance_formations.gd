## StanceFormations — formation post shapes of the non-Escort army stances
## (StanceData, ArmyStance). HordeDirector._calculate_formation_anchors()
## calls assign() at 4 Hz instead of its own (Escort) layout while another
## stance is held. It only writes each unit's `anchor_offset` (its post
## relative to the necromancer); every unit keeps its shared AI, so no class
## gets new behaviour. Like the Escort anchors, every post is resolved with
## Arena.free_point(), so a post inside an obstacle is moved out of it.
## Unit roles (same split as the Escort formation): "front" (Warriors and
## UnitData formation "front": Abominations, Gargoyles), "support" (Mender,
## Warder, Profane Bishop, and the formation "back" siege artillery, the
## Corpse Catapults, so they post with the priests BEHIND the fighting), and
## the rest split into melee "flank" units (Rogues, Bone Hounds) and
## "ranged" units (Archers, Mages, Frost Wraiths, Banshees).
##   onslaught — enemies within StanceData.ONSLAUGHT_SCAN are grouped by
##               angular sector; fighters spread over the biggest groups
##               (posts short of each group's centre, ranged a little back),
##               priests post between the necromancer and the main group.
##               With no enemy in reach: the Escort bands, widened.
##   spearhead — a wedge pointed along the necromancer's last movement
##               direction: blockers on a V (tip ahead, arms sweeping back),
##               flank units on both sides, ranged and priests in a small
##               band around the necromancer. The rear is open.
##   ring      — blockers and flank units evenly spaced on a closed circle
##               (StanceData.RING_MIN-RING_MAX out), ranged and priests inside.
## Deterministic: no RNG, only unit order, the per-unit jitter values set at
## activation and enemy-grid query order.
class_name StanceFormations
extends RefCounted


## Writes the posts of every unit for `shape` ("onslaught", "spearhead",
## "ring"). `jitter` scales UnitData.FORMATION_JITTER_ANGLE.
static func assign(d: HordeDirector, shape: String, jitter: float) -> void:
	var front: Array[SummonedUnit] = []  # Blockers.
	var flank: Array[SummonedUnit] = []  # Melee non-blockers (Rogues).
	var ranged: Array[SummonedUnit] = []  # Archers, Mages, Frost Wraiths.
	var support: Array[SummonedUnit] = []  # Priests.
	for u in d.units:
		match role(u.unit_class):
			"front":
				front.append(u)
			"support":
				support.append(u)
			_:
				if u.attack_profile == "melee":
					flank.append(u)
				else:
					ranged.append(u)
	match shape:
		"onslaught":
			_onslaught(d, front, flank, ranged, support, jitter)
		"spearhead":
			_spearhead(d, front, flank, ranged, support, jitter)
		"ring":
			_ring(d, front, flank, ranged, support, jitter)


## Formation role of class `cls`: "front", "support" or "mid" (the Escort
## formation's split, HordeDirector._calculate_formation_anchors(); a
## formation "back" class posts as "support" here).
static func role(cls: String) -> String:
	match cls:
		"warrior":
			return "front"
		"mender", "warder", "bishop":
			return "support"
	match String(UnitData.UNITS[cls].get("formation", "mid")):
		"front":
			return "front"
		"back":
			return "support"
	return "mid"


## Sets `u`'s post to `offset` from the necromancer, moved out of obstacles.
static func _place(d: HordeDirector, u: SummonedUnit, offset: Vector2) -> void:
	var pp := d.game.player.position
	u.anchor_offset = d.game.arena.free_point(pp + offset, u.radius) - pp


## Per-unit angular jitter (radians) scaled by `jitter`.
static func _jit(u: SummonedUnit, jitter: float) -> float:
	return (u.slot_jitter - 0.5) * UnitData.FORMATION_JITTER_ANGLE * jitter


## Spreads `list` evenly over an arc of `spread` radians centred on
## `center_angle`, each unit at lerp(r_min, r_max, its band jitter).
static func _arc(d: HordeDirector, list: Array[SummonedUnit], center_angle: float, spread: float,
		r_min: float, r_max: float, jitter: float) -> void:
	var n := list.size()
	for i in n:
		var u := list[i]
		var t := (float(i) + 0.5) / float(n) - 0.5  # -0.5..0.5 along the arc.
		var angle := center_angle + t * spread + _jit(u, jitter)
		_place(d, u, Vector2.from_angle(angle) * lerpf(r_min, r_max, u.band_jitter))


## Two-ring band of `list` around the necromancer between `r_min` and `r_max`:
## every other unit takes the outer radius, so a crowd stays separated.
static func _inner_band(d: HordeDirector, list: Array[SummonedUnit], start_angle: float, r_min: float,
		r_max: float, jitter: float) -> void:
	var n := list.size()
	for i in n:
		var u := list[i]
		var angle := start_angle + TAU * (float(i) + 0.5) / float(n) + _jit(u, jitter)
		var r := r_max if i % 2 == 0 else lerpf(r_min, r_max, 0.35)  # Alternate outer / inner radius.
		_place(d, u, Vector2.from_angle(angle) * r)


# =====================================================================================
# Onslaught
# =====================================================================================

## Onslaught posts (see header).
static func _onslaught(d: HordeDirector, front: Array[SummonedUnit], flank: Array[SummonedUnit],
		ranged: Array[SummonedUnit], support: Array[SummonedUnit], jitter: float) -> void:
	var groups := _enemy_groups(d)  # [{"dir": Vector2, "dist": float, "count": int}], biggest first.
	if groups.is_empty():
		_onslaught_idle(d, front, flank, ranged, support, jitter)
		return
	var total := 0  # Enemies in all groups.
	for g: Dictionary in groups:
		total += int(g["count"])
	# Share each role between the groups by enemy count (cumulative split), so
	# every group gets its part of the blockers, the flank and the ranged.
	var members: Array = []  # Group index -> Array[SummonedUnit].
	for _g in groups:
		members.append([])
	for list: Array[SummonedUnit] in [front, flank, ranged]:
		var n := list.size()
		for i in n:
			var at := (float(i) + 0.5) / float(n) * float(total)  # Position in the cumulative count.
			var k := 0  # Group this fighter joins.
			var acc := float(groups[0]["count"])  # Cumulative count up to group k.
			while at > acc and k < groups.size() - 1:
				k += 1
				acc += float(groups[k]["count"])
			(members[k] as Array).append(list[i])
	for k in groups.size():
		var g: Dictionary = groups[k]
		var dir: Vector2 = g["dir"]
		var side := dir.orthogonal()  # Lateral spread direction.
		var post := clampf(float(g["dist"]) - StanceData.ONSLAUGHT_STANDOFF, StanceData.ONSLAUGHT_POST_MIN, StanceData.ONSLAUGHT_POST_MAX)  # px.
		var list: Array = members[k]
		var m := list.size()
		for j in m:
			var u: SummonedUnit = list[j]
			var lateral := (float(j) - float(m - 1) * 0.5) * StanceData.ONSLAUGHT_SPACING  # px left / right.
			var dist := post if u.attack_profile == "melee" else maxf(StanceData.ONSLAUGHT_POST_MIN, post - StanceData.ONSLAUGHT_RANGED_BACK)
			var off := dir.rotated(_jit(u, jitter)) * dist + side * lateral
			_place(d, u, off)
	# Priests trail the frontline: between the necromancer and the main group.
	var main: Dictionary = groups[0]
	var main_post := clampf(float(main["dist"]) - StanceData.ONSLAUGHT_STANDOFF, StanceData.ONSLAUGHT_POST_MIN, StanceData.ONSLAUGHT_POST_MAX)
	var pr := main_post * StanceData.ONSLAUGHT_PRIEST_FRACTION  # Priest post distance (px).
	var main_dir: Vector2 = main["dir"]
	var ns := support.size()
	for j in ns:
		var u := support[j]
		var lateral := (float(j) - float(ns - 1) * 0.5) * StanceData.ONSLAUGHT_SPACING
		_place(d, u, main_dir * pr + main_dir.orthogonal() * lateral)


## Onslaught with no enemy in reach: the Escort layout's bands, widened by
## StanceData.ONSLAUGHT_IDLE_SPREAD (blockers and the rest on full rings).
static func _onslaught_idle(d: HordeDirector, front: Array[SummonedUnit], flank: Array[SummonedUnit],
		ranged: Array[SummonedUnit], support: Array[SummonedUnit], jitter: float) -> void:
	var k := StanceData.ONSLAUGHT_IDLE_SPREAD
	var rot := d.threat_dir.angle()  # Orientation of the rings.
	var mid: Array[SummonedUnit] = []  # Flank + ranged units share the midline ring.
	mid.append_array(flank)
	mid.append_array(ranged)
	for pair: Array in [[front, 0.0], [mid, PI / maxf(1.0, float(mid.size()))], [support, PI * 0.5]]:
		var list: Array[SummonedUnit] = pair[0]
		for i in list.size():
			var u := list[i]
			var angle := rot + float(pair[1]) + TAU * (float(i) + 0.5) / float(list.size()) + _jit(u, jitter)
			var r := lerpf(u.band_min, u.band_max, 0.2 + 0.6 * u.band_jitter) * k
			_place(d, u, Vector2.from_angle(angle) * r)


## Groups the enemies within StanceData.ONSLAUGHT_SCAN of the necromancer by
## angular sector and returns the StanceData.ONSLAUGHT_GROUPS biggest ones,
## biggest first (ties: lower sector first), each as {"dir": unit vector to
## the group's centre, "dist": px to it, "count": enemies}. Structures
## (outposts, carts...) count too: they are worth the push.
static func _enemy_groups(d: HordeDirector) -> Array[Dictionary]:
	var p := d.game.player.position
	var sectors := StanceData.ONSLAUGHT_SECTORS
	var counts: Array[int] = []  # Sector -> enemy count.
	var sums: Array[Vector2] = []  # Sector -> sum of offsets from the player.
	for _s in sectors:
		counts.append(0)
		sums.append(Vector2.ZERO)
	var found: Array = []  # Reusable query result.
	d.game.enemy_grid.query(p, StanceData.ONSLAUGHT_SCAN, found)
	for e: Enemy in found:
		if not e.active:
			continue
		var off := e.position - p
		if off.length_squared() > StanceData.ONSLAUGHT_SCAN * StanceData.ONSLAUGHT_SCAN:
			continue
		var s := int(floorf(fposmod(off.angle(), TAU) / TAU * float(sectors))) % sectors  # Sector index.
		counts[s] += 1
		sums[s] += off
	var out: Array[Dictionary] = []
	var used: Array[bool] = []  # Sector already picked.
	for _s in sectors:
		used.append(false)
	for _g in StanceData.ONSLAUGHT_GROUPS:
		var best := -1
		for s in sectors:
			if not used[s] and counts[s] > 0 and (best < 0 or counts[s] > counts[best]):
				best = s
		if best < 0:
			break
		used[best] = true
		var c := sums[best] / float(counts[best])  # Group centre (offset from the player).
		var dist := c.length()
		var dir := c / dist if dist > 1.0 else Vector2.from_angle((float(best) + 0.5) / float(sectors) * TAU)
		out.append({"dir": dir, "dist": dist, "count": counts[best]})
	return out


# =====================================================================================
# Spearhead
# =====================================================================================

## Spearhead posts (see header).
static func _spearhead(d: HordeDirector, front: Array[SummonedUnit], flank: Array[SummonedUnit],
		ranged: Array[SummonedUnit], support: Array[SummonedUnit], jitter: float) -> void:
	var dir := d.game.stance.move_dir  # Wedge direction.
	var side := dir.orthogonal()  # Lateral direction.
	# Blockers on a V: layers of SPEAR_LAYER_SIZE, each centred on the axis.
	var nf := front.size()
	var per := StanceData.SPEAR_LAYER_SIZE
	for i in nf:
		var layer := floori(float(i) / float(per))  # Wedge layer (0 = front-most).
		var in_layer := mini(per, nf - layer * per)  # Units in this layer.
		var m := float(i % per) - float(in_layer - 1) * 0.5  # Signed step from the axis.
		var u := front[i]
		var fwd := StanceData.SPEAR_TIP - float(layer) * StanceData.SPEAR_LAYER_BACK - absf(m) * StanceData.SPEAR_STEP_BACK
		_place(d, u, (dir * fwd + side * m * StanceData.SPEAR_STEP_SIDE).rotated(_jit(u, jitter)))
	# Flank units: alternate sides, each further one a step behind.
	for i in flank.size():
		var u := flank[i]
		var sgn := 1.0 if i % 2 == 0 else -1.0  # Right / left flank.
		var row := float(floori(float(i) / 2.0))  # Position along that flank.
		var fwd := StanceData.SPEAR_FLANK_FORWARD - row * StanceData.SPEAR_FLANK_STEP
		_place(d, u, dir * fwd + side * sgn * StanceData.SPEAR_FLANK_SIDE)
	# Ranged and priests: a small band around the necromancer.
	var inner: Array[SummonedUnit] = []
	inner.append_array(ranged)
	inner.append_array(support)
	_inner_band(d, inner, dir.angle(), StanceData.SPEAR_INNER_MIN, StanceData.SPEAR_INNER_MAX, jitter)


# =====================================================================================
# Bone Ring
# =====================================================================================

## Bone Ring posts (see header). The ring grows with the number of units it
## has to hold inside (StanceData.RING_PER_INNER), within RING_MIN-RING_MAX.
static func _ring(d: HordeDirector, front: Array[SummonedUnit], flank: Array[SummonedUnit],
		ranged: Array[SummonedUnit], support: Array[SummonedUnit], jitter: float) -> void:
	var ring: Array[SummonedUnit] = []  # Blockers and flank units on the circle.
	ring.append_array(front)
	ring.append_array(flank)
	var inner: Array[SummonedUnit] = []  # Ranged and priests inside.
	inner.append_array(ranged)
	inner.append_array(support)
	var r := clampf(StanceData.RING_MIN + StanceData.RING_PER_INNER * float(inner.size()), StanceData.RING_MIN, StanceData.RING_MAX)  # Ring radius (px).
	var n := ring.size()
	for i in n:
		var u := ring[i]
		var angle := -PI * 0.5 + TAU * float(i) / float(n) + _jit(u, jitter)  # Evenly spaced, slot 0 on top.
		_place(d, u, Vector2.from_angle(angle) * (r + (u.band_jitter - 0.5) * 2.0 * StanceData.RING_DEPTH))
	var inner_max := maxf(StanceData.RING_INNER_MIN, r - StanceData.RING_INNER_GAP)
	_inner_band(d, inner, PI / maxf(1.0, float(inner.size())), StanceData.RING_INNER_MIN, inner_max, jitter)
