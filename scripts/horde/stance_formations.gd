## StanceFormations — the army's formation posts (StanceData; GDD §15.0 "Bone Ring is
## the only formation"). HordeDirector._calculate_formation_anchors() calls assign() at
## 4 Hz. It only writes each unit's `anchor_offset` (its post relative to the
## necromancer); every unit keeps its shared AI, so no class gets new behaviour. Every
## post is resolved with Arena.free_point(), so a post inside an obstacle is moved out.
## Unit roles: "front" (Warriors and UnitData formation "front": Abominations,
## Gargoyles), "support" (Mender, Warder, Profane Bishop, and the formation "back" siege
## artillery, the Corpse Catapults), and the rest split into melee "flank" units (Rogues,
## Bone Hounds) and "ranged" units (Archers, Mages, Frost Wraiths, Banshees).
##   ring — blockers, flankers and ranged units evenly spaced on one closed circle around
##          the necromancer, its radius set by how many posts it holds
##          (StanceData.RING_SPACING, within RING_MIN..RING_MAX; two deep when overfull),
##          so their volleys fly outward in every direction; priests and siege inside.
## Deterministic: no RNG, only unit order and the per-unit jitter values set at activation.
class_name StanceFormations
extends RefCounted


## Writes the posts of every unit for `shape` ("ring"). `jitter` scales
## UnitData.FORMATION_JITTER_ANGLE.
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
# Bone Ring
# =====================================================================================

## Bone Ring posts (see header): blockers, flankers and ranged units share one closed
## circle; its radius fits the posts it holds (RING_SPACING of arc each) and the units
## inside (RING_PER_INNER each), within RING_MIN..RING_MAX. More posts than fit at
## RING_MAX: every second one steps RING_LAYER inward (two deep). Priests and siege
## artillery stand in a band inside the ring.
static func _ring(d: HordeDirector, front: Array[SummonedUnit], flank: Array[SummonedUnit],
		ranged: Array[SummonedUnit], support: Array[SummonedUnit], jitter: float) -> void:
	var blockers: Array[SummonedUnit] = []  # Melee posts (blockers, then flankers).
	blockers.append_array(front)
	blockers.append_array(flank)
	var ring := _interleave(blockers, ranged)  # Posts on the circle, melee spread evenly between the ranged.
	var inner: Array[SummonedUnit] = support  # Priests and siege inside the ring.
	var n := ring.size()
	var fit := float(n) * StanceData.RING_SPACING / TAU  # Radius at which n posts close the circle (px).
	var room := StanceData.RING_MIN + StanceData.RING_PER_INNER * float(inner.size())  # Radius that leaves room inside (px).
	var r := clampf(maxf(fit, room), StanceData.RING_MIN, StanceData.RING_MAX)  # Ring radius (px).
	var two_deep := fit > StanceData.RING_MAX  # Overfull: alternate posts step inward.
	d.ring_radius = r  # Act III: read by the Scrap Swarm spell (its orbit is outside the ring).
	for i in n:
		var u := ring[i]
		var angle := -PI * 0.5 + TAU * float(i) / float(n) + _jit(u, jitter)
		var depth := (u.band_jitter - 0.5) * 2.0 * StanceData.RING_DEPTH  # Small radial wobble (px).
		if two_deep and i % 2 == 1:
			depth -= StanceData.RING_LAYER
		_place(d, u, Vector2.from_angle(angle) * (r + depth))
	var inner_max := maxf(StanceData.RING_INNER_MIN, r - StanceData.RING_INNER_GAP - (StanceData.RING_LAYER if two_deep else 0.0))
	_inner_band(d, inner, PI / maxf(1.0, float(inner.size())), StanceData.RING_INNER_MIN, inner_max, jitter)


## `a` and `b` merged in proportion (each next post comes from the list that is furthest
## behind its share), so both spread evenly around the ring. Order within each list kept.
static func _interleave(a: Array[SummonedUnit], b: Array[SummonedUnit]) -> Array[SummonedUnit]:
	var out: Array[SummonedUnit] = []
	var ia := 0  # Next index in a.
	var ib := 0  # Next index in b.
	while ia < a.size() or ib < b.size():
		# Progress of each list through its own length (a finished list never wins).
		var pa := float(ia) / float(a.size()) if ia < a.size() else INF
		var pb := float(ib) / float(b.size()) if ib < b.size() else INF
		if pa <= pb:
			out.append(a[ia])
			ia += 1
		else:
			out.append(b[ib])
			ib += 1
	return out
