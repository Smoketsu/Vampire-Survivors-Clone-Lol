## BansheeBehavior — the Banshee's attacks ("dirge", UnitData).
##   * Shriek bolts: the class's attack_profile "dirge" is released here as a
##     spectral bolt (Projectile.Kind.PRIEST_BOLT, source = the unit's
##     dmg_source: "banshee" / "keening_lady").
##   * Dirge: think() starts it when the Dirge is ready, the target is in bolt
##     range, not a Reckoning enemy or a structure, not already weakened for
##     long (REFRESH_WINDOW), and it either stands in a crowd
##     (dirge_min_enemies inside dirge_radius), is an elite / miniboss / the
##     boss, or is next to a necromancer in danger. A pale spectral circle is
##     telegraphed on the target's spot for dirge_windup s (CASTING), then the
##     wail weakens every enemy inside dirge_radius through
##     CombatResolver.weaken_enemy() (the one debuff path): a dirge_slow slow
##     and a dirge_cut cut to the damage of its hits for dirge_duration s
##     (bosses and minibosses dirge_boss_mult of both; Reckoning enemies and
##     structures immune). Slows never make an enemy flee.
##   * Target preference: enemies closing on the player ("dirge" weights),
##     unweakened ones first (score_bonus()), so the Dirge spreads.
##   * Floating: the body is drawn FLOAT_LIFT px above a ground shadow; it is
##     not airborne (enemies can target and hit it; see UnitData).
## Keening Lady (summon evolution; keys from SummonEvolutionData
## "special_set", absent / 0 on the base Banshee, which keeps exactly the
## behaviour above): the wail repeats in `waves` waves wave_interval s apart
## (phase WAVES, still CASTING), wave i reaching dirge_radius x (1 + i x
## wave_growth), and every wave silences what it reaches (weaken_enemy
## `silence`: its heals fail for the Dirge duration).
## Synergies: each Dirge (its first wave) calls SynergyManager.on_dirge()
## (Baying of the Damned: the hounds' frenzy); Requiem's mage bonus on
## weakened foes and its stretch live in SynergyManager.hit_mult().
## Stats: banshee_dirges, banshee_dirge_hits (enemies weakened per wave),
## keening_waves (extra waves), dirge_debuffs / dirge_debuff_seconds /
## keening_silenced / keening_heals_silenced (CombatResolver).
class_name BansheeBehavior
extends SummonBehavior

## Phase: the wail is telegraphed.
const CAST: int = 1
## Phase: Keening Lady repeat waves.
const WAVES: int = 2
## A target still weakened for longer than this (s) is not wailed at again.
const REFRESH_WINDOW: float = 1.0
## px the floating body is drawn above its shadow.
const FLOAT_LIFT: float = 5.0

## World point the current Dirge is centred on (locked at cast start).
var wail_point: Vector2 = Vector2.ZERO
## Waves already released by the running Dirge.
var _waves_done: int = 0
## Reusable enemy query buffer.
var _buf: Array = []


## Full Dirge cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("dirge_cooldown", 6.0))


## Starts a Dirge on the current target when it is worth it.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0 or not u.target_alive():
		return false
	var t := u.target
	if t.is_reckoning or t.is_structure or t.weaken_until > u.game.elapsed + REFRESH_WINDOW:
		return false
	if u.position.distance_to(t.position) > u.attack_range + t.radius:
		return false
	var near_player := t.position.distance_to(u.game.player.position) <= UnitData.DANGER_RADIUS  # Target is on the necromancer.
	var worth := t.is_elite or t.is_boss or t.is_miniboss or (near_player and u.director.player_in_danger)
	if not worth:
		worth = count_enemies(u.game, t.position, float(u.special["dirge_radius"]), _buf) >= int(u.special["dirge_min_enemies"])
	if not worth:
		return false
	wail_point = t.position
	_waves_done = 0
	begin_special(u, CAST)
	return true


## Windup, the wail, then (Keening Lady) the repeat waves.
func step_special(u: SummonedUnit, _delta: float) -> bool:
	u.velocity = Vector2.ZERO
	var waves := maxi(1, int(u.special.get("waves", 1)))  # Wails in this Dirge.
	match phase:
		CAST:
			if phase_time >= float(u.special["dirge_windup"]):
				_wail(u, 0)
				u.game.stat_add("banshee_dirges", 1.0)
				u.director.synergies.on_dirge()  # Baying of the Damned (no-op without it).
				if waves > 1:
					next_phase(WAVES)
				else:
					_end(u)
		WAVES:
			if phase_time >= float(u.special["wave_interval"]):
				next_phase(WAVES)  # Restart the interval for the next wave.
				_wail(u, _waves_done)
				u.game.stat_add("keening_waves", 1.0)
				if _waves_done >= waves:
					_end(u)
	return true


## Hands the unit back to the shared FSM.
func _end(u: SummonedUnit) -> void:
	end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)


## Releases wave `i` (0 = the first): weakens every enemy inside its radius.
func _wail(u: SummonedUnit, i: int) -> void:
	var game := u.game
	u.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)  # Engine motion: the wail (visual only).
	var r := wave_radius(u, i)  # This wave's radius (px).
	var silence := int(u.special.get("silence", 0)) > 0  # Keening Lady.
	game.enemy_grid.query(wail_point, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var hits := 0  # Enemies weakened.
	for e: Enemy in _buf:
		if e.active and e.position.distance_to(wail_point) <= r + e.radius * 0.5:
			if game.combat.weaken_enemy(e, float(u.special["dirge_slow"]), float(u.special["dirge_cut"]),
					float(u.special["dirge_duration"]), float(u.special["dirge_boss_mult"]), silence):
				hits += 1
	_waves_done = i + 1
	game.volleys.on_special(u, wail_point, wail_point + Vector2.RIGHT, u.damage)  # Bullet heaven: the Dirge's rings.
	game.stat_add("banshee_dirge_hits", float(hits))
	game.effects.art_ring(wail_point, r, WarbandGlyphs.WAIL, 0.45, "wail")  # Pixel-art sound rings when their art exists (AoeArt).
	game.effects.art_ring_under(wail_point, r * 0.65, Palette.VIOLET, 0.35, "wail")
	if silence:
		game.effects.art_ring(wail_point, r * 0.85, WarbandGlyphs.SILENCE, 0.4, "silence")
	Juice.fx.burst(wail_point, WarbandGlyphs.WAIL, Palette.VIOLET, 8, r * 1.4, 0.5, 2.0)
	Sfx.play("banshee_wail", wail_point, 1.0 + 0.12 * float(i))


## Radius (px) of wave `i` of the Dirge (wave 0 = dirge_radius).
static func wave_radius(u: SummonedUnit, i: int) -> float:
	return float(u.special["dirge_radius"]) * (1.0 + float(u.special.get("wave_growth", 0.0)) * float(i))


## "dirge" attack profile: a spectral shriek bolt at the target.
func release_attack(u: SummonedUnit) -> void:
	if not u.target_alive():
		return
	u.game.projectiles.fire_friendly(Projectile.Kind.PRIEST_BOLT, u.position, u.target, u.damage, u.projectile_speed, 0, u.dmg_source)


## Unweakened enemies first, so the Dirge spreads over the crowd.
func score_bonus(u: SummonedUnit, e: Enemy, _dp: float) -> float:
	return float(u.special["unweakened_bonus"]) if e.weaken_until <= u.game.elapsed else 0.0


## The body floats above its shadow.
func body_lift(_u: SummonedUnit) -> float:
	return FLOAT_LIFT


## Ground shadow (it floats) and the Dirge telegraph on the target spot.
func draw_under(u: SummonedUnit) -> void:
	u.draw_set_transform(Vector2(0, u.radius * 0.95), 0.0, Vector2(1.0, 0.4))
	u.draw_circle(Vector2.ZERO, u.radius * 0.8, Color(0, 0, 0, 0.3))
	body_space(u)
	if phase != CAST:
		return
	world_space(u)
	var at := wail_point - u.position  # Circle centre in world-aligned local space.
	var r := float(u.special["dirge_radius"])  # Dirge radius (px).
	var k := clampf(phase_time / maxf(float(u.special["dirge_windup"]), 0.01), 0.0, 1.0)  # Windup progress.
	if not AoeArt.telegraph(u, "mark_wail", at, r, k, WarbandGlyphs.WAIL):  # Pixel-art rim marks (AoeArt).
		u.draw_circle(at, r, Color(WarbandGlyphs.WAIL, 0.08))
		u.draw_circle(at, r * k, Color(Palette.VIOLET, 0.16))
		u.draw_arc(at, r, 0.0, TAU, 36, Color(WarbandGlyphs.WAIL, 0.75), 1.5)
	u.draw_line(Vector2(0, -FLOAT_LIFT), at, Color(WarbandGlyphs.WAIL, 0.3), 1.5)
	body_space(u)
