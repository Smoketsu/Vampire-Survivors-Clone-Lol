## ConcordBeams — BEAMS, the first of the Concord of Stars' shared rules (Act
## IX; GDD §15.0 "Beams"; owner-approved proposal: "Concord weapons are
## continuous beams, not bullets: a thin aiming line for 1 s, then a beam that
## holds and sweeps for about 1.5 s, cutting through every body on its line.
## Unlike Act III's shots, the ring cannot block them, so the army has to get
## out of the line. The necromancer's answer: Orb Shields and Warder barriers
## reflect a beam back along its line, into whoever fired it. At most 6 beams
## at once. One path, ConcordBeams, never through ProjectileManager"). Owned by
## Game.concord. THE one path of every Concord beam:
##   fire(owner, dir, style, overrides, boss_override)
## (the drones' probes, the Vrask lock, the Sentinels' sweeps, the Final
## Harvest's eye, phase 2's bosses; never ProjectileManager or EmpireShots).
## A beam lives here in two phases:
##   * AIM (style "aim" s): a thin magenta aiming line from the muzzle (the
##     Vrask "lock" style shows three red dots on the target instead). It
##     tracks its target (overrides "target") at BEAMS track_rate and stops
##     turning for the last lock_time s. While the owner is frozen or stunned
##     the beam waits with it; if the owner dies or is pooled the beam is
##     cancelled.
##   * HOLD (style "hold" s): the beam holds and sweeps `sweep` degrees across
##     the locked line (its side from the owner's think slot, no RNG). Every
##     `tick` s each summon and each necromancer on its line takes dps x tick
##     (x the firer's damage scaling, x its undead mult on a summon, x Mirror
##     Bones' mirror_taken_mult()), each AT MOST ONCE A TICK, through
##     CombatResolver.damage_unit() / damage_player() (Grave Step's i-frames
##     dodge it there). THE RING DOES NOT BLOCK IT. Enemies are never hit by
##     a Concord beam, except a reflected one.
## Along the line, the first of these from the muzzle ENDS the beam there:
##   * A BONE WALL (owner answer, Nov 3, 2026; Act IX phase 2, the Crash
##     Site): the first Bone Wall segment touching the line (the spell's walls,
##     Bastion rings and an Ossuary Titan's wall alike; co-op: every player's),
##     found with Act III's Line of Fire test (EmpireShots.wall_block_t() ->
##     BoneWall.shot_block_t(), the one segment test, never a copy). The beam
##     stops there: no reflection and no split past it (an Orb Shield behind
##     the wall is not even asked, so it spends no charge). It applies to every
##     Concord beam (the prisms' split beams and the Final Harvest's eye too),
##     never to a reflected beam (the necromancer's). Counted once per beam
##     (beam_wall_stops); the hit flare is drawn at the wall, the aiming line
##     stops there too, and danger_push() reads the shortened line.
##   * REFLECTION. An Orb Shield (the Umbral Warden's Eclipsed Guard, else one
##     charge of AbilityManager.try_intercept(); once per beam, as
##     EmpireShots._orb_stops(); co-op: every standing necromancer's orbs, his
##     slot bound): the beam is caught at that distance for the rest of its
##     hold. A summon with a Warder / Bishop barrier (barrier_hp > 0; its
##     barrier takes that tick's hit as usual through damage_unit()), tested
##     every tick. A REFLECTED BEAM runs back from the reflection point to the
##     muzzle and hits every enemy on it (the firer included) through
##     CombatResolver.damage_enemy() with the reflection point as `origin`,
##     source ConcordRulesData.REFLECT_SOURCE: BEAMS reflect_dps x tick x the
##     enemies' HP scaling x Mirror Bones' mirror_reflect_mult().
##   * A PRISM (a Star-Seer, row "prism"): the beam ends on her and splits into
##     three beams of the remaining length (the line and +-prism_angle), once
##     per beam. The split beams are derived each tick from their parent (they
##     never count toward the cap, never reflect and never split again).
## CAP: at most BEAMS cap beams at once (a beam over it is refused and counted;
## the kit retries); a boss override goes up to boss_cap, as LockOn's.
## Storage: packed arrays with the owner's and the target's pooling
## generations (no nodes, no instance ids). Drawn by this one node at z 3 as
## textures (the `effects/beam_line` / `effects/beam_hit` strips when present,
## tinted laser magenta; else a soft line texture made once in code): no
## polygon redrawn every frame. Nothing is drawn headless.
## Mirror Bones hooks: ConcordRules.mirror_reflect_mult(), mirror_taken_mult().
## Stats: beams_fired, beams_fired_<style>, beams_refused, beams_cancelled,
## beam_hits_summons, beam_dmg_summons, beam_hits_you, beam_dmg_you,
## beam_reflect_orb, beam_reflect_barrier, beam_reflect_hits, beam_reflect_dmg,
## beam_prism_splits, beam_wall_stops.
class_name ConcordBeams
extends Node2D

## Reflection kind of a beam: none.
const REFLECT_NONE: int = 0
## Reflection kind of a beam: an Orb Shield caught it (kept for its hold).
const REFLECT_ORB: int = 1
## Reflection kind of a beam: a summon's barrier caught it (this tick).
const REFLECT_BARRIER: int = 2
## Flag bit: this beam's orb reflection was counted.
const FLAG_ORB: int = 1
## Flag bit: this beam's barrier reflection was counted.
const FLAG_BARRIER: int = 2
## Flag bit: this beam's prism split was counted.
const FLAG_PRISM: int = 4
# --- Act IX: the Crash Site ---
## End kind of a beam's line: a Bone Wall segment stopped it (the prism's
## split is 3; REFLECT_* 1 / 2; 0 = its full length).
const WALL_STOP: int = 4
## Flag bit: this beam's Bone Wall stop was counted (beam_wall_stops).
const FLAG_WALL: int = 8
## Sprite key of the beam's body strip (a grey tint mask, the art pass).
const LINE_ART: String = "effects/beam_line"
## Sprite key of the beam's hit flare strip (a grey tint mask, the art pass).
const HIT_ART: String = "effects/beam_hit"

## Owning run.
var game: Game
## Live beams (indices [0, count) of every array below).
var count: int = 0
## Most beams at once this run (the autotest's "beams" line).
var peak: int = 0
## Beams fired this run by style id (the report).
var fired_by: Dictionary = {}
## Hard cap (BEAMS boss_cap): the arrays' size.
var _cap: int = 0
## Owner enemy of each beam (null for an ownerless beam: the Final Harvest's eye).
var _owner: Array[Enemy] = []
## Generation of each owner when it fired (stale guard; 0 for no owner).
var _owner_gen: PackedInt32Array = PackedInt32Array()
## Fixed muzzle (world px) of an ownerless beam.
var _origin: PackedVector2Array = PackedVector2Array()
## Target each beam tracks while it aims (a Necromancer or a SummonedUnit; may be null).
var _target: Array[Node2D] = []
## Generation of each summon target (0 for a necromancer or none).
var _target_gen: PackedInt32Array = PackedInt32Array()
## Unit direction of each beam now.
var _dir: PackedVector2Array = PackedVector2Array()
## Angle (rad) of the locked line at the start of the hold (the sweep's centre).
var _lock_angle: PackedFloat32Array = PackedFloat32Array()
## Seconds since each beam was fired (aim, then hold).
var _time: PackedFloat32Array = PackedFloat32Array()
## Aim time (s) of each beam.
var _aim: PackedFloat32Array = PackedFloat32Array()
## Hold time (s) of each beam.
var _hold: PackedFloat32Array = PackedFloat32Array()
## Sweep (rad, signed: its side) of each beam over its hold.
var _sweep: PackedFloat32Array = PackedFloat32Array()
## Length (px) of each beam.
var _len: PackedFloat32Array = PackedFloat32Array()
## Width (px) of each beam.
var _width: PackedFloat32Array = PackedFloat32Array()
## Damage per second of each beam (already scaled by its firer).
var _dps: PackedFloat32Array = PackedFloat32Array()
## Damage tick (s) of each beam.
var _tick: PackedFloat32Array = PackedFloat32Array()
## Seconds toward each beam's next damage tick.
var _tick_acc: PackedFloat32Array = PackedFloat32Array()
## x each beam's damage on a summon (its firer's undead_damage_mult).
var _umult: PackedFloat32Array = PackedFloat32Array()
## 1 for the "dots" aim look (the Vrask lock), else 0.
var _dots: PackedByteArray = PackedByteArray()
## 1 for a boss-override beam (does not count against the normal cap), else 0.
var _boss: PackedByteArray = PackedByteArray()
## Style id of each beam.
var _style: PackedStringArray = PackedStringArray()
## Damage tag of each beam.
var _src: PackedStringArray = PackedStringArray()
## Distance (px) along the line where an Orb Shield caught each beam (-1 = none).
var _orb_d: PackedFloat32Array = PackedFloat32Array()
## Co-op slot of the necromancer whose orbs caught each beam (-1 = none / solo).
var _orb_slot: PackedInt32Array = PackedInt32Array()
## Counted-once flags of each beam (FLAG_*).
var _flags: PackedInt32Array = PackedInt32Array()
## This tick's geometry of each beam: the main line's end distance (px).
var _end_d: PackedFloat32Array = PackedFloat32Array()
## This tick's geometry: what ended it (REFLECT_* or 3 = a prism, 0 = its length).
var _end_kind: PackedInt32Array = PackedInt32Array()
## This tick's geometry: the prism (world px) a beam split on (if _end_kind 3).
var _split_at: PackedVector2Array = PackedVector2Array()
# --- Act IX: the Crash Site ---
## This tick's geometry of each beam's three split beams (if _end_kind 3):
## their lengths (px) after the Bone Wall test, at [3 i + k] for the split
## k = 0, 1, 2 (angles -prism_angle, 0, +prism_angle).
var _split_end: PackedFloat32Array = PackedFloat32Array()
## Reusable grid query buffer.
var _tmp: Array = []
## Bodies hit this tick by the beam being resolved (each at most once a tick).
var _hit: Dictionary = {}
## The soft line texture (made on first use; drawing only).
static var _line_tex: Texture2D = null
## True when this build draws (never headless).
var _draws: bool = false
## True if the last redraw showed beams (one more redraw clears them).
var _drawn: bool = false


## Builds the beam store for `p_game` (ConcordRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "ConcordBeams"
	z_index = 3  # Above the units and the shots: the lines must read clearly (as LockOn).
	z_as_relative = false
	_cap = int(ConcordRulesData.BEAMS["boss_cap"])
	_owner.resize(_cap)
	_owner_gen.resize(_cap)
	_origin.resize(_cap)
	_target.resize(_cap)
	_target_gen.resize(_cap)
	_dir.resize(_cap)
	_lock_angle.resize(_cap)
	_time.resize(_cap)
	_aim.resize(_cap)
	_hold.resize(_cap)
	_sweep.resize(_cap)
	_len.resize(_cap)
	_width.resize(_cap)
	_dps.resize(_cap)
	_tick.resize(_cap)
	_tick_acc.resize(_cap)
	_umult.resize(_cap)
	_dots.resize(_cap)
	_boss.resize(_cap)
	_style.resize(_cap)
	_src.resize(_cap)
	_orb_d.resize(_cap)
	_orb_slot.resize(_cap)
	_flags.resize(_cap)
	_end_d.resize(_cap)
	_end_kind.resize(_cap)
	_split_at.resize(_cap)
	_split_end.resize(_cap * 3)  # Act IX, the Crash Site: the split beams' wall-stopped lengths.
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# Firing
# =====================================================================================

## THE ONE CALL: fires a Concord beam from `owner` (an Enemy; null for an
## ownerless beam, whose muzzle is overrides "origin") along unit direction
## `dir`, in style `style` (ConcordRulesData.BEAM_STYLES id). `overrides` may
## replace any style key and add: "target" (Node2D the aim tracks), "source"
## (damage tag; default the owner's kind, else "concord_beam"), "scale" (x its
## dps; default the owner's CovenantKit.hit_scale(), else the enemies' damage
## scaling), "origin" (Vector2: an ownerless beam's muzzle). `boss_override`
## lifts the normal cap up to BEAMS boss_cap. Returns false when refused (the
## cap; counted) or when the owner already fires a beam (without the override).
func fire(owner: Enemy, dir: Vector2, style: String, overrides: Dictionary = {}, boss_override: bool = false) -> bool:
	if owner != null and not boss_override and has_beam(owner):
		return false
	var limit := _cap if boss_override else mini(_cap, int(ConcordRulesData.BEAMS["cap"]))  # Beams allowed now.
	if (boss_override and count >= limit) or (not boss_override and _normal_count() >= limit) or count >= _cap:
		game.stat_add("beams_refused", 1.0)
		return false
	var row: Dictionary = ConcordRulesData.BEAM_STYLES.get(style, ConcordRulesData.BEAM_STYLES["probe"])  # The style's numbers.
	var i := count
	count += 1
	peak = maxi(peak, count)
	_owner[i] = owner
	_owner_gen[i] = owner.generation if owner != null else 0
	_origin[i] = Vector2(overrides.get("origin", owner.position if owner != null else Vector2.ZERO))
	var t: Node2D = overrides.get("target", null)
	_target[i] = t
	_target_gen[i] = (t as SummonedUnit).generation if t is SummonedUnit else 0
	_dir[i] = dir.normalized() if dir.length_squared() > 0.0001 else Vector2.RIGHT
	_lock_angle[i] = _dir[i].angle()
	_time[i] = 0.0
	_aim[i] = float(overrides.get("aim", row["aim"]))
	_hold[i] = float(overrides.get("hold", row["hold"]))
	var side := 1.0  # Sweep side: from the owner's think slot (no RNG).
	if owner != null and owner.think_slot % 2 == 1:
		side = -1.0
	elif owner == null and int(overrides.get("side", 1)) < 0:
		side = -1.0
	_sweep[i] = deg_to_rad(float(overrides.get("sweep", row["sweep"]))) * side
	_len[i] = float(overrides.get("length", row["length"]))
	_width[i] = float(overrides.get("width", row["width"]))
	var scale := float(overrides.get("scale", CovenantKit.hit_scale(owner) if owner != null else game.enemies.damage_mult))
	_dps[i] = float(overrides.get("dps", row["dps"])) * scale
	_tick[i] = maxf(0.05, float(overrides.get("tick", row["tick"])))
	_tick_acc[i] = 0.0
	_umult[i] = owner.undead_damage_mult if owner != null else 1.0
	_dots[i] = 1 if bool(overrides.get("dots", row.get("dots", false))) else 0
	_boss[i] = 1 if boss_override else 0
	_style[i] = style
	_src[i] = String(overrides.get("source", owner.kind if owner != null else "concord_beam"))
	_orb_d[i] = -1.0
	_orb_slot[i] = -1
	_flags[i] = 0
	_end_d[i] = _len[i]
	_end_kind[i] = 0
	_split_at[i] = Vector2.ZERO
	fired_by[style] = int(fired_by.get(style, 0)) + 1
	game.stat_add("beams_fired", 1.0)
	game.stat_add("beams_fired_" + style, 1.0)
	_play("beam_charge", _muzzle(i), 0.3)
	return true


## Beams alive now that count against the normal cap (boss beams do not).
func _normal_count() -> int:
	var n := 0
	for i in count:
		if _boss[i] == 0:
			n += 1
	return n


## True while `owner` has a beam aiming or holding (its kit holds still).
func has_beam(owner: Enemy) -> bool:
	for i in count:
		if _owner[i] == owner and _owner_gen[i] == owner.generation:
			return true
	return false


## True while `owner`'s beam is holding (fired), false while it only aims.
func is_firing(owner: Enemy) -> bool:
	for i in count:
		if _owner[i] == owner and _owner_gen[i] == owner.generation:
			return _time[i] >= _aim[i]
	return false


## Removes beam `i` (the last beam moves into its slot).
func _remove(i: int) -> void:
	var last := count - 1
	if i != last:
		_owner[i] = _owner[last]
		_owner_gen[i] = _owner_gen[last]
		_origin[i] = _origin[last]
		_target[i] = _target[last]
		_target_gen[i] = _target_gen[last]
		_dir[i] = _dir[last]
		_lock_angle[i] = _lock_angle[last]
		_time[i] = _time[last]
		_aim[i] = _aim[last]
		_hold[i] = _hold[last]
		_sweep[i] = _sweep[last]
		_len[i] = _len[last]
		_width[i] = _width[last]
		_dps[i] = _dps[last]
		_tick[i] = _tick[last]
		_tick_acc[i] = _tick_acc[last]
		_umult[i] = _umult[last]
		_dots[i] = _dots[last]
		_boss[i] = _boss[last]
		_style[i] = _style[last]
		_src[i] = _src[last]
		_orb_d[i] = _orb_d[last]
		_orb_slot[i] = _orb_slot[last]
		_flags[i] = _flags[last]
		_end_d[i] = _end_d[last]
		_end_kind[i] = _end_kind[last]
		_split_at[i] = _split_at[last]
		for k in 3:
			_split_end[i * 3 + k] = _split_end[last * 3 + k]  # Act IX, the Crash Site.
	_owner[last] = null
	_target[last] = null
	count = last


# =====================================================================================
# Update
# =====================================================================================

## Ages every beam (ConcordRules.step()): cancels the beams whose owner is
## gone, aims, then holds, sweeps, resolves the line and deals the ticks.
func step(delta: float) -> void:
	var lock := float(ConcordRulesData.BEAMS["lock_time"])  # Last aim seconds without tracking.
	var rate := float(ConcordRulesData.BEAMS["track_rate"])  # Tracking turn rate (rad/s).
	var i := 0
	while i < count:
		var o := _owner[i]
		if o != null and (not o.active or o.generation != _owner_gen[i]):
			game.stat_add("beams_cancelled", 1.0)  # Its firer died first.
			_remove(i)
			continue
		if o != null and o.frozen:
			i += 1
			continue  # Held by Stasis, a Deep Freeze or a stun: the beam waits.
		_time[i] += delta
		if _time[i] < _aim[i]:
			if _time[i] < _aim[i] - lock and _target_alive(i):
				var want := (_target[i].position - _muzzle(i)).angle()  # Toward the target.
				var cur := _dir[i].angle()
				_dir[i] = Vector2.from_angle(cur + clampf(wrapf(want - cur, -PI, PI), -rate * delta, rate * delta))
			_lock_angle[i] = _dir[i].angle()
			_aim_line(i)  # Act IX, the Crash Site: the aiming line stops at a Bone Wall too.
			i += 1
			continue
		var k := clampf((_time[i] - _aim[i]) / maxf(_hold[i], 0.001), 0.0, 1.0)  # 0 -> 1 through the hold.
		if _time[i] - delta < _aim[i]:
			_play("beam_fire", _muzzle(i), 0.25)
		_dir[i] = Vector2.from_angle(_lock_angle[i] + _sweep[i] * (k - 0.5))
		_resolve_line(i)
		_tick_acc[i] += delta
		if _tick_acc[i] >= _tick[i]:
			_tick_acc[i] -= _tick[i]
			_deal_tick(i)
		if _time[i] >= _aim[i] + _hold[i]:
			_remove(i)
			continue
		i += 1
	if _draws:
		if count > 0 or _drawn:
			queue_redraw()
		_drawn = count > 0


## True if beam `i`'s target is still the same living body.
func _target_alive(i: int) -> bool:
	var t := _target[i]
	if t == null or not is_instance_valid(t):
		return false
	if t is SummonedUnit:
		var u := t as SummonedUnit
		return u.active and u.generation == _target_gen[i] and u.state != SummonedUnit.State.DEAD
	if t is Necromancer:
		return not (t as Necromancer).dead
	return true


## The muzzle (world px) of beam `i`: its owner's centre moved along the line,
## or the fixed origin of an ownerless beam.
func _muzzle(i: int) -> Vector2:
	var o := _owner[i]
	if o == null:
		return _origin[i]
	return o.position + _dir[i] * float(ConcordRulesData.BEAMS["muzzle"])


## This tick's line of beam `i`: where its main segment ends and why (an Orb
## Shield, a summon's barrier, a prism, or its full length). An Orb Shield is
## spent once per beam (it then holds the reflection for the rest of the hold).
func _resolve_line(i: int) -> void:
	var a := _muzzle(i)
	var d := _dir[i]
	var length := _len[i]
	var half := _width[i] * 0.5
	var end := length  # Main segment's end distance (px).
	var kind := 0  # What ended it (0 = its length).
	# 0. Act IX, the Crash Site: a Bone Wall segment on the line stops it there
	# (nothing past the wall is asked: no orb charge is spent behind it).
	var wd := wall_d(a, d, length, half)  # Distance of the first wall touch (-1 = none).
	if wd >= 0.0:
		end = wd
		kind = WALL_STOP
	# 1. An Orb Shield already caught it: the reflection holds.
	if _orb_d[i] >= 0.0:
		if _orb_d[i] < end:
			end = _orb_d[i]
			kind = REFLECT_ORB
	else:
		var od := _orb_on_line(i, a, d, end, half)  # Distance of the first charged orb that caught it (-1 = none).
		if od >= 0.0:
			end = od
			kind = REFLECT_ORB
	# 2. A summon with a barrier nearer than that.
	game.ally_grid.query(a + d * (end * 0.5), end * 0.5 + half + float(ConcordRulesData.BEAMS["summon_slack"]), _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.barrier_hp <= 0.0:
			continue
		var rel := u.position - a
		var along := rel.dot(d)
		if along < 0.0 or along > end:
			continue
		if absf(rel.cross(d)) <= u.radius + half:
			var face := maxf(0.0, along - u.radius)  # Where the beam meets its barrier.
			if face < end:
				end = face
				kind = REFLECT_BARRIER
	# 3. A prism nearer than that (split once per beam; split beams are derived).
	var rules := game.concord
	if rules != null:
		for p: Enemy in rules.prisms:
			if not p.active:
				continue
			var rel := p.position - a
			var along := rel.dot(d)
			if along <= 0.0 or along >= end:
				continue
			if absf(rel.cross(d)) <= p.radius + half + float(ConcordRulesData.BEAMS["prism_radius"]) * 0.5:
				end = along
				kind = 3
				_split_at[i] = p.position
	_end_d[i] = end
	_end_kind[i] = kind
	if kind == REFLECT_BARRIER and (_flags[i] & FLAG_BARRIER) == 0:
		_flags[i] |= FLAG_BARRIER
		game.stat_add("beam_reflect_barrier", 1.0)
		_play("beam_reflect", a + d * end, 0.2)
	if kind == 3 and (_flags[i] & FLAG_PRISM) == 0:
		_flags[i] |= FLAG_PRISM
		game.stat_add("beam_prism_splits", 1.0)
	# --- Act IX: the Crash Site --- the split beams stop at a Bone Wall too.
	var walled := kind == WALL_STOP  # A wall stopped this beam (main line or a split).
	if kind == 3:
		var rest := length - end  # The split beams' full length (px).
		var spread := deg_to_rad(float(ConcordRulesData.BEAMS["prism_angle"]))
		for k in 3:
			var sd := wall_d(_split_at[i], d.rotated(spread * float(k - 1)), rest, half)  # Its wall touch (-1 = none).
			_split_end[i * 3 + k] = sd if sd >= 0.0 else rest
			walled = walled or sd >= 0.0
	if walled and (_flags[i] & FLAG_WALL) == 0:
		_flags[i] |= FLAG_WALL
		game.stat_add("beam_wall_stops", 1.0)


## Distance along beam `i`'s line of the first ORB SHIELD that catches it, or
## -1. The nearest orb touching the line (co-op: of every standing
## necromancer) is tested once: the Eclipsed Guard innate, else one charge of
## AbilityManager.try_intercept() (that necromancer's slot bound). Caught, the
## beam keeps that reflection for the rest of its hold.
func _orb_on_line(i: int, a: Vector2, d: Vector2, length: float, half: float) -> float:
	var best := INF  # Nearest orb's distance along the line.
	var best_slot := -1  # Its necromancer's slot (co-op).
	var best_p := Vector2.ZERO  # Its position.
	var reach := AbilityData.ORB_RADIUS + half + float(ConcordRulesData.BEAMS["orb_slack"])  # Orb reach to the line (px).
	for k in game.all_players.size():
		var prev := game.bind_index(k)
		var orbs := game.abilities.orb_shield  # Null until the spell exists.
		if orbs != null and not game.player.dead:
			for op in orbs.orb_positions:
				var rel := op - a
				var along := rel.dot(d)
				if along < 0.0 or along > length or along >= best:
					continue
				if absf(rel.cross(d)) <= reach:
					best = along
					best_slot = k
					best_p = op
		game.unbind(prev)
	if best == INF:
		return -1.0
	var prev2 := game.bind_index(best_slot)
	var caught := game.innates.eclipsed_guard(best_p, half) or game.abilities.try_intercept(best_p, half)
	game.unbind(prev2)
	if not caught:
		return -1.0
	_orb_d[i] = best
	_orb_slot[i] = best_slot if game.coop != null else -1
	if (_flags[i] & FLAG_ORB) == 0:
		_flags[i] |= FLAG_ORB
		game.stat_add("beam_reflect_orb", 1.0)
	_play("beam_reflect", best_p, 0.2)
	return best


## One damage tick of beam `i`: every summon and necromancer on its main line
## (up to its end) and on its split beams, each once; then the reflected beam
## on every enemy between the reflection point and the muzzle.
func _deal_tick(i: int) -> void:
	_hit.clear()
	var a := _muzzle(i)
	var d := _dir[i]
	var tick := _tick[i]
	var end := _end_d[i]
	_hit_line(i, a, d, end + 1.0, tick)
	if _end_kind[i] == 3:
		var spread := deg_to_rad(float(ConcordRulesData.BEAMS["prism_angle"]))
		var from := _split_at[i]
		for k in 3:
			_hit_line(i, from, d.rotated(spread * float(k - 1)), _split_end[i * 3 + k], tick)  # Each split beam's length after its wall test.
	elif _end_kind[i] == REFLECT_ORB or _end_kind[i] == REFLECT_BARRIER:
		_reflect_tick(i, a + d * end, a, tick)


## Hits every summon and necromancer within beam `i`'s half width of the
## segment from `a` along `d` for `length` px, each once this tick.
func _hit_line(i: int, a: Vector2, d: Vector2, length: float, tick: float) -> void:
	if length <= 0.0:
		return
	var half := _width[i] * 0.5
	var dmg := _dps[i] * tick  # This tick's hit (before the summon multipliers).
	var rules := game.concord
	game.ally_grid.query(a + d * (length * 0.5), length * 0.5 + half + float(ConcordRulesData.BEAMS["summon_slack"]), _tmp)
	for u: SummonedUnit in _tmp.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or _hit.has(u):
			continue
		var rel := u.position - a
		var along := rel.dot(d)
		if along < -u.radius or along > length + u.radius or absf(rel.cross(d)) > u.radius + half:
			continue
		_hit[u] = true
		var hp0 := u.hp
		var mt := rules.mirror_taken_mult(u) if rules != null else 1.0  # Mirror Bones (1 today).
		game.combat.damage_unit(u, dmg * _umult[i] * mt, _src[i])
		game.stat_add("beam_hits_summons", 1.0)
		game.stat_add("beam_dmg_summons", maxf(0.0, hp0 - maxf(u.hp, 0.0)))
	for pl in game.all_players:
		if pl.dead or _hit.has(pl):
			continue
		var rel := pl.position - a
		var along := rel.dot(d)
		if along < -pl.radius or along > length + pl.radius or absf(rel.cross(d)) > pl.radius + half:
			continue
		_hit[pl] = true
		var before := float(game.stats.get("damage_to_player", 0.0))  # To count what landed.
		game.combat.damage_player(dmg, _src[i], pl)
		game.stat_add("beam_hits_you", 1.0)
		game.stat_add("beam_dmg_you", float(game.stats.get("damage_to_player", 0.0)) - before)


## The REFLECTED beam of beam `i` this tick: from the reflection point `from`
## back to its muzzle `to`, every enemy on it (the firer included) takes BEAMS
## reflect_dps x tick x the enemies' HP scaling x Mirror Bones, with `from` as
## the hit's origin (co-op: as the slot whose orbs caught it).
func _reflect_tick(i: int, from: Vector2, to: Vector2, tick: float) -> void:
	var v := to - from
	var length := v.length()
	if length < 1.0:
		return
	var d := v / length
	var half := _width[i] * 0.5
	var slot := _orb_slot[i] if _end_kind[i] == REFLECT_ORB else -1  # Co-op: whose orbs caught it (-1 = the bound player's).
	var prev := game.bind_index(slot) if slot >= 0 else -1
	var mult := game.concord.mirror_reflect_mult() if game.concord != null else 1.0  # Mirror Bones (1 today).
	game.unbind(prev)
	var dmg := float(ConcordRulesData.BEAMS["reflect_dps"]) * tick * game.enemies.hp_mult * mult
	game.enemy_grid.query(from + d * (length * 0.5), length * 0.5 + half + 40.0, _tmp)
	for e: Enemy in _tmp.duplicate():
		if not e.active or _hit.has(e):
			continue
		var rel := e.position - from
		var along := rel.dot(d)
		if along < -e.radius or along > length + e.radius or absf(rel.cross(d)) > e.radius + half:
			continue
		_hit[e] = true
		var dealt := game.combat.damage_enemy(e, dmg, ConcordRulesData.REFLECT_SOURCE, slot, from)
		game.stat_add("beam_reflect_hits", 1.0)
		game.stat_add("beam_reflect_dmg", dealt)


## Plays Concord sound event `event` at `pos` (rate-limited by `gap` s).
func _play(event: String, pos: Vector2, gap: float) -> void:
	if game.concord != null:
		game.concord.play_sound(event, pos, gap)


# =====================================================================================
# Autotest hint
# =====================================================================================

## Autopilot hint (the autotest bot's one danger_push()-style behaviour): a push
## sideways out of every aiming line and live beam passing within danger_reach
## px (plus the beam's half width) of `p`, stronger as the beam nears its hold.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for i in count:
		var a := _muzzle(i)
		var d := _dir[i]
		var along := (p - a).dot(d)  # Distance down the line (px).
		if along < 0.0 or along > _end_d[i]:
			continue  # Past its end (a Bone Wall, a reflector or a prism stops it there; Act IX, the Crash Site).
		var reach := float(ConcordRulesData.BEAMS["danger_reach"]) + _width[i] * 0.5 + game.player.radius  # Danger band (px).
		var side := (p - a) - d * along  # Offset from the line.
		var dist := side.length()
		if dist >= reach:
			continue
		var urgency := clampf(_time[i] / maxf(_aim[i], 0.01), 0.3, 1.0)  # Stronger as it fires.
		var n := side / dist if dist > 0.01 else d.orthogonal()
		push += n * (1.0 - dist / reach) * 2.0 * urgency
	return push


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## Draws every beam: the thin aiming line (or the Vrask lock's three red dots on
## its target), then the held beam to its end, its split beams, its reflected
## beam and a flare where it ends. Pulses run on game time.
func _draw() -> void:
	var now := game.elapsed
	for i in count:
		var a := _muzzle(i)
		var d := _dir[i]
		if _time[i] < _aim[i]:
			var locked := _time[i] >= _aim[i] - float(ConcordRulesData.BEAMS["lock_time"])
			if _dots[i] == 1 and _target_alive(i):
				var t := _target[i].position
				var r := 7.0 if locked else 11.0 - 4.0 * _time[i] / maxf(_aim[i], 0.01)  # The three dots close in.
				for k in 3:
					var q := t + Vector2.from_angle(TAU * float(k) / 3.0 + now * 3.0) * r
					SpriteBank.draw_disc(self, q, 2.0, Palette.CITY_SIREN_RED)  # Three red dots (the Vrask lock).
				_line(a, t, 1.0, Color(Palette.CITY_SIREN_RED, 0.25))
			else:
				var blink := locked and fmod(now * 10.0, 1.0) < 0.5
				var w := 2.0 if locked else 1.0
				_line(a, a + d * _end_d[i], w, Color(Palette.CONCORD_LASER, float(ConcordRulesData.BEAMS["aim_alpha"]) * (1.0 if blink or not locked else 0.6)))
				if _end_kind[i] == WALL_STOP:
					_flare(a + d * _end_d[i], 8.0, Palette.BONE)  # Act IX, the Crash Site: the wall will stop it.
			continue
		var w2 := _width[i]
		var pulse := 0.85 + 0.15 * sin(now * 30.0 + float(i))  # A buzz along the beam.
		var end := a + d * _end_d[i]
		_beam(a, end, w2 * pulse)
		if _end_kind[i] == 3:
			var rest := _len[i] - _end_d[i]
			var spread := deg_to_rad(float(ConcordRulesData.BEAMS["prism_angle"]))
			for k in 3:
				var se := _split_end[i * 3 + k]  # This split beam's length after its wall test.
				var sdir := d.rotated(spread * float(k - 1))
				_beam(_split_at[i], _split_at[i] + sdir * se, w2 * 0.7 * pulse)
				if se < rest - 0.5:
					_flare(_split_at[i] + sdir * se, w2 * 1.2, Palette.BONE)  # Act IX, the Crash Site: a Bone Wall stopped it.
			_flare(_split_at[i], w2 * 1.6, Palette.CONCORD_LUMEN)
		elif _end_kind[i] == WALL_STOP:
			_flare(end, w2 * 1.5, Palette.BONE)  # Act IX, the Crash Site: the beam breaks on the Bone Wall.
		elif _end_kind[i] == REFLECT_ORB or _end_kind[i] == REFLECT_BARRIER:
			_line(end, a, w2 * 0.6, Color(Palette.CONCORD_LUMEN, 0.75))  # The reflected beam back at its firer.
			_flare(end, w2 * 1.8, Palette.CONCORD_LUMEN)
		else:
			_flare(end, w2 * 1.2, Palette.CONCORD_LASER)


## A held beam from `a` to `b`, `w` px wide: the `effects/beam_line` strip
## stretched along it when present (tinted laser magenta), else the made line
## texture with a bright core.
func _beam(a: Vector2, b: Vector2, w: float) -> void:
	var tex := SpriteBank.texture(LINE_ART)  # The art pass's strip, or null.
	if tex != null:
		_textured(tex, a, b, w * 1.6, Palette.CONCORD_LASER)
		return
	_line(a, b, w * 1.6, Color(Palette.CONCORD_LASER, 0.35))
	_line(a, b, w, Color(Palette.CONCORD_LASER, 0.9))
	_line(a, b, maxf(1.0, w * 0.35), Color(1.0, 0.85, 0.95, 0.95))


## A flare where a beam ends: the `effects/beam_hit` strip's first square
## frame when present, else a soft disc (both tinted `col`).
func _flare(at: Vector2, size: float, col: Color) -> void:
	var tex := SpriteBank.texture(HIT_ART)  # The art pass's strip, or null.
	if tex != null:
		var fh := float(tex.get_height())  # A square frame's side (texels).
		var frames := maxi(1, int(float(tex.get_width()) / maxf(fh, 1.0)))
		var f := int(game.elapsed * 14.0) % frames
		draw_texture_rect_region(tex, Rect2(at - Vector2(size, size) * 0.5, Vector2(size, size)), Rect2(fh * float(f), 0.0, fh, fh), col)
		return
	SpriteBank.draw_disc(self, at, size * 0.5, Color(col, 0.55))
	SpriteBank.draw_disc(self, at, size * 0.25, Color(1.0, 1.0, 1.0, 0.8))


## A soft line texture `w` px wide from `a` to `b` in `col` (no polygon).
func _line(a: Vector2, b: Vector2, w: float, col: Color) -> void:
	_textured(line_texture(), a, b, w, col)


## Texture `tex` stretched from `a` to `b`, `w` px across, tinted `col`.
func _textured(tex: Texture2D, a: Vector2, b: Vector2, w: float, col: Color) -> void:
	var v := b - a
	var length_px := v.length()
	if length_px < 1.0 or col.a <= 0.01:
		return
	draw_set_transform(a, v.angle(), Vector2.ONE)
	draw_texture_rect(tex, Rect2(Vector2(0.0, -w * 0.5), Vector2(length_px, w)), false, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The soft line texture: 8 x 6 white, soft at the edges across its width
## (tinted when drawn). Made once.
static func line_texture() -> Texture2D:
	if _line_tex != null:
		return _line_tex
	var img := Image.create(8, 6, false, Image.FORMAT_RGBA8)
	var rows := [0.2, 0.7, 1.0, 1.0, 0.7, 0.2]  # Alpha of each row (soft edges).
	for y in 6:
		for x in 8:
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, rows[y]))
	_line_tex = ImageTexture.create_from_image(img)
	return _line_tex


# --- Act IX: the Crash Site ---
## The Bone Wall stop (owner answer, Nov 3, 2026): distance (px) along the line
## from `a` in unit direction `d` at which a Bone Wall segment first touches a
## beam `half` px wide over `length` px, or -1 when none does. The ONE segment
## test is Act III's (EmpireShots.wall_block_t() -> BoneWall.shot_block_t(),
## every player's walls); this only turns its path fraction into a distance.
func wall_d(a: Vector2, d: Vector2, length: float, half: float) -> float:
	if length <= 0.0:
		return -1.0
	var t := EmpireShots.wall_block_t(game, a, a + d * length, half)  # Path fraction of the first touch (INF = none).
	if t == INF:
		return -1.0
	return clampf(t, 0.0, 1.0) * length


## While beam `i` aims: its line's end this tick (a Bone Wall stops the aiming
## line and danger_push() reads it; nothing else ends a line before it fires).
func _aim_line(i: int) -> void:
	var wd := wall_d(_muzzle(i), _dir[i], _len[i], _width[i] * 0.5)  # The first wall touch (-1 = none).
	_end_d[i] = wd if wd >= 0.0 else _len[i]
	_end_kind[i] = WALL_STOP if wd >= 0.0 else 0
