## ScrapSwarm — the Scrap Swarm spell (AbilityData "scrap_swarm"; Act III, the
## Iron Citadel; GDD §15.0 "Scrap Swarm, Machine Soul and the Rust Prophet";
## owner-approved proposal; unlocked by defeating Deus Ex Machina, then offered
## on every stage at the later-item card weight): a cloud of bone-and-scrap
## drones, the Empire's own machines turned to the necromancer's will, orbiting
## OUTSIDE the Bone Ring: ScrapSwarmData.RING_GAP px past its outer edge
## (HordeDirector.ring_radius + RING_EDGE), so the orbit widens as the army
## grows (owner: inside the ring it would do nothing). The orbit eases to its
## radius at ORBIT_EASE px/s and turns at `orbit_speed` rad/s.
##   * `drones` drones, evenly spaced. Each fires every `cooldown` s (staggered
##     round the orbit) a bolt (Projectile.Kind.SCRAP_BOLT, ProjectileManager:
##     the friendly-projectile path, damage reservation included) at the
##     nearest foe within `range` px of it that has NOT reached the army yet
##     (farther from the necromancer than the orbit minus INSIDE_SLACK): they
##     shoot enemies before they reach your army. `damage` per bolt.
## Evolved into DEATHLESS SWARM (EvolutionData "deathless_swarm", detected by the
## "kill_drones" key): more drones, harder bolts, and every foe a drone's bolt
## KILLS launches one more drone for KILL_DRONE_LIFE s (owner-approved: "each kill
## adds one for 10 s"; at most `kill_drones` extra, MAX_DRONES in all), counted
## from the kills_by_deathless_swarm stat each tick.
## The Rust Prophet's innate (his scrap bolts) lives in CharacterInnates.
## Determinism: no RNG; targets by distance, ties in the spatial hash's order.
## Stats: scrap_bolts, scrap_kill_drones (extra drones launched), the peak
## drone count (summary); damage as dmg_scrap_swarm / dmg_deathless_swarm.
class_name ScrapSwarm
extends NecroSpell

## Current orbit radius (px, eased toward the ring's).
var _orbit: float = 0.0
## Orbit angle (rad) of drone 0.
var _spin: float = 0.0
## Per drone (base and extra, in order): seconds until it fires again.
var _cd: PackedFloat32Array = PackedFloat32Array()
## Expiry game time of each extra (kill) drone (Deathless Swarm).
var _extra: PackedFloat32Array = PackedFloat32Array()
## kills_by_deathless_swarm seen at the last tick (new kills = the difference).
var _kills_seen: int = 0
## Rotor frames shown per second by the drone art (2-frame strips; visual only).
const ROTOR_FPS: float = 14.0  # TUNING (not in GDD) Hz
## Drones on the orbit this tick (drawing, summary).
var _count: int = 0
## Most drones on the orbit at once this run (summary).
var peak: int = 0


## Eases the orbit, launches kill drones, fires every ready drone.
func step(delta: float, stats: Dictionary) -> void:
	var p := game.player.position
	var want := game.horde.ring_radius + ScrapSwarmData.RING_EDGE + ScrapSwarmData.RING_GAP  # Orbit radius the ring asks for (px).
	if _orbit <= 0.0:
		_orbit = want
	_orbit = move_toward(_orbit, want, ScrapSwarmData.ORBIT_EASE * delta)
	_spin = wrapf(_spin + float(stats["orbit_speed"]) * delta, -PI, PI)
	var evolved := stats.has("kill_drones")  # Deathless Swarm.
	var src := ScrapSwarmData.EVOLVED_SOURCE if evolved else ScrapSwarmData.SOURCE
	if evolved:
		_step_kill_drones(stats)
	var base := int(stats["drones"])
	_count = mini(ScrapSwarmData.MAX_DRONES, base + _extra.size())
	peak = maxi(peak, _count)
	if _cd.size() != _count:
		var old := _cd.size()
		_cd.resize(_count)
		for i in range(old, _count):
			_cd[i] = float(stats["cooldown"]) * float(i) / float(maxi(1, _count))  # Staggered round the orbit.
	var reach := float(stats["range"])
	for i in _count:
		_cd[i] -= delta
		if _cd[i] > 0.0:
			continue
		var at := p + Vector2.from_angle(_spin + TAU * float(i) / float(_count)) * _orbit  # This drone (world px).
		var e := _target(at, p, reach)
		if e == null:
			_cd[i] = AbilityData.SPELL_RETRY
			continue
		_cd[i] = float(stats["cooldown"])
		game.projectiles.fire_friendly(Projectile.Kind.SCRAP_BOLT, at, e, float(stats["damage"]), ScrapSwarmData.BOLT_SPEED, 0, src)
		game.stat_add("scrap_bolts", 1.0)
	queue_redraw()


## The nearest open foe within `reach` px of the drone at `at` that has not
## reached the army yet (farther from the necromancer at `p` than the orbit
## minus INSIDE_SLACK); null when none.
func _target(at: Vector2, p: Vector2, reach: float) -> Enemy:
	var best: Enemy = null
	var best_d := reach
	var inner := _orbit - ScrapSwarmData.INSIDE_SLACK  # Foes closer to him than this are the army's.
	game.enemy_grid.query(at, reach, _tmp)
	for e: Enemy in _tmp:
		if not is_open_target(e) or e.untargetable:
			continue
		if e.position.distance_to(p) < inner:
			continue
		var d := at.distance_to(e.position)
		if d < best_d:
			best_d = d
			best = e
	return best


## Deathless Swarm: every new kill by its bolts launches a drone for
## KILL_DRONE_LIFE s (at most `kill_drones` at once); expired ones leave.
func _step_kill_drones(stats: Dictionary) -> void:
	var now := game.elapsed
	var i := _extra.size() - 1
	while i >= 0:
		if now >= _extra[i]:
			_extra.remove_at(i)
		i -= 1
	var kills := int(game.stats.get("kills_by_" + ScrapSwarmData.EVOLVED_SOURCE, 0.0))
	var fresh := kills - _kills_seen  # Kills since the last tick.
	_kills_seen = kills
	for _k in fresh:
		if _extra.size() >= int(stats["kill_drones"]):
			break
		_extra.append(now + ScrapSwarmData.KILL_DRONE_LIFE)
		game.stat_add("scrap_kill_drones", 1.0)


## Autotest counters (NecroSpellBook's Act III line).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "bolts=%d kill_drones=%d peak_drones=%d orbit=%d" % [int(st.get("scrap_bolts", 0.0)), int(st.get("scrap_kill_drones", 0.0)), peak, int(_orbit)]


## The drones on their orbit: bone-and-scrap bodies with a violet eye (the
## necromancer's spell colour), the extra kill drones brighter. Visual only.
func _draw() -> void:
	if game == null or _count <= 0:
		return
	var p := game.player.position
	var base := _count - _extra.size()
	for i in _count:
		var at := p + Vector2.from_angle(_spin + TAU * float(i) / float(_count)) * _orbit
		# Art: the 2-frame rotor strips (Act III missing sprites): the plain drone, the
		# brighter violet-rotor one for a Deathless Swarm kill drone (i >= base). Game
		# time picks the frame, so a run is unchanged.
		var spin := int(game.elapsed * ROTOR_FPS) + i  # Rotor frame (drones out of step).
		var key := "projectiles/scrap_drone_bright" if i >= base else "projectiles/scrap_drone"  # Strip key.
		if SpriteBank.draw_flat_frame(self, key, 2, spin, at, 0.0):
			continue
		if not SpriteBank.draw_flat_frame(self, "projectiles/scrap_drone", 2, spin, at, 0.0):
			ScrapSwarm.draw_drone(self, at, ScrapSwarmData.DRONE_RADIUS, i >= base)  # No art at all.
		elif i >= base:
			draw_arc(at, ScrapSwarmData.DRONE_RADIUS + 3.0, 0.0, TAU, 12, Color(Palette.VIOLET, 0.6), 1.0)  # Plain art only: the old ring marks a kill drone.


## A scrap drone without art at `at` (radius `r`): a bone-white wedge of scrap
## with a violet eye; `bright` marks a Deathless Swarm kill drone.
static func draw_drone(ci: CanvasItem, at: Vector2, r: float, bright: bool) -> void:
	ci.draw_circle(at, r + 1.0, Glyphs.OUTLINE)
	ci.draw_circle(at, r, Palette.BONE)
	ci.draw_line(at + Vector2(-r * 1.6, -r * 0.4), at + Vector2(r * 1.6, -r * 0.4), Palette.UNDEAD_STEEL, 1.5)  # Rotor blade of scrap.
	ci.draw_circle(at, r * 0.45, Palette.VIOLET.lightened(0.4) if bright else Palette.VIOLET)
