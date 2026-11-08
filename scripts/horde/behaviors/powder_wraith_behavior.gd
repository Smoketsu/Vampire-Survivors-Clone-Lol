## PowderWraithBehavior — the Powder Wraith's KEG BURST ("keg_burst", UnitData
## "powder_wraith"; Act X, the Maelstrom's finale reward; GDD §15.0 "The Powder
## Wraith, Magazine Lord and Slow Match"; owner-approved proposal: "a skeleton
## carrying a lit keg that walks into a pack and bursts (area damage and a 60 px
## knockback), then reforms at the ring after 12 s (evolution Magazine Lord). It
## is a class special, so it works on every stage"). An undead skeleton (no sex)
## that fights with a short blade on the Bone Ring's front posts between kegs.
## Its special works the same on every stage (owner rule: summons never get
## act-only rules; on a deck the burst's knockback drowns foes by itself):
##   1. think(): with the keg ready, it picks the DENSEST PACK within keg_range
##      px of its necromancer (the enemy with the most foes within keg_radius
##      px, of at most SCAN; a pack of keg_min_enemies, or an elite / the boss
##      alone), LIGHTS THE FUSE and MARCHES at it at keg_speed px/s (tracking
##      it) for at most keg_march s;
##   2. THE BURST, within keg_trigger px of the foe (or when the march runs
##      out): keg_damage to every enemy within keg_radius px and a knockback
##      of keg_knockback px (the impulse that carries a body that far, divided
##      by its mass; bosses, minibosses and structures stand); Magazine Lord
##      (special_set "kegs" 2) marches on to the next pack within chain_range
##      px for a second burst;
##   3. SPENT: the burst scatters it. It is `airborne` (out of the ally grid:
##      enemies neither target nor hit it; Arena.resolve_all() skips it),
##      hidden, and carried with its necromancer for reform_time s (12 s;
##      Magazine Lord 8 s), the special_time bounded per REFORM_STEP so the
##      autotest's overtime check sees a bounded hold, as the Gargoyle's stone
##      phase does;
##   4. REFORM: it stands again at its ring post (Arena.free_point() round the
##      necromancer at its formation offset) and rejoins the shared FSM; the
##      next keg is ready keg_cooldown s later.
## Leash and recall stay in charge: a recall cancels the march (no burst) or,
## while spent, reforms it at once (SummonBehavior.physics()). Slow Match (its
## paired passive) lengthens every class special's *_knockback in
## HordeDirector._special_stats() (the one path).
## Determinism: no RNG (the densest pack, ties in the spatial hash's order).
## Stats: powder_wraith_kegs, powder_wraith_keg_hits, powder_wraith_reforms,
## magazine_lord_chains, dmg_powder_wraith_keg / dmg_magazine_lord_keg,
## summon_special_end_blocked (a reform inside an obstacle: must be 0).
class_name PowderWraithBehavior
extends SummonBehavior

## Phase: marching at the pack with the fuse lit.
const MARCH: int = 1
## Phase: spent (scattered, hidden), waiting to reform.
const SPENT: int = 2
## Enemies scanned for the densest pack (cost bound).
const SCAN: int = 24  # TUNING (not in GDD)
## Seconds of the spent hold after which its special_time restarts (bounded
## hold; see the header).
const REFORM_STEP: float = 3.0  # TUNING (not in GDD)
## Damage-source tag of the burst.
const SOURCE: String = "powder_wraith_keg"
## Damage-source tag of Magazine Lord's burst.
const EVOLVED_SOURCE: String = "magazine_lord_keg"
## Passive id of Slow Match (PassiveData, UnlockData; read by
## HordeDirector._special_stats()).
const SLOW_MATCH: String = "slow_match"
## Its level-row key: extra share (0..) of every class special's knockback
## (its *_knockback keys).
const SLOW_MATCH_KEY: String = "special_push"

## The pack's enemy it marches at (null once it died / was recycled).
var keg_target: Enemy = null
## Generation of `keg_target` at the pick (stale-reference guard).
var keg_gen: int = 0
## World point it marches at (follows the target while it lives).
var keg_point: Vector2 = Vector2.ZERO
## Bursts left this march (Magazine Lord 2).
var kegs_left: int = 0
## Seconds of the spent hold so far.
var _spent: float = 0.0
## Reusable enemy query buffer.
var _buf: Array = []
## Second reusable enemy query buffer (the pack counts).
var _buf2: Array = []


## Full keg cooldown (s), counted from the reform.
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("keg_cooldown", 3.0))


## Lights the fuse at the densest pack within reach of its necromancer.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0:
		return false
	var e := _densest(u, u.game.player.position, float(u.special["keg_range"]), [])
	if e == null:
		return false
	_aim(e)
	kegs_left = int(u.special.get("kegs", 1))
	begin_special(u, MARCH)
	u.game.stat_add("powder_wraith_kegs", 1.0)
	if u.game.corsair != null:
		u.game.corsair.play_sound("keg_lit", u.position, 0.3)
	else:
		Sfx.play("fuse_hiss", u.position)
	return true


## Marks `e` as the march's target.
func _aim(e: Enemy) -> void:
	keg_target = e
	keg_gen = e.generation
	keg_point = e.position


## The enemy with the most foes within keg_radius px, of the first SCAN
## enemies within `reach` px of `from` (none in `skip`); null without a pack.
func _densest(u: SummonedUnit, from: Vector2, reach: float, skip: Array) -> Enemy:
	var game := u.game
	var r := float(u.special["keg_radius"])
	game.enemy_grid.query(from, reach, _buf)
	var best: Enemy = null
	var best_n := 0
	var seen := 0
	for e: Enemy in _buf:
		if seen >= SCAN:
			break
		if not e.active or e.is_structure or e.civilian or e.untargetable or skip.has(e) or e.position.distance_to(from) > reach:
			continue
		seen += 1
		var n := count_enemies(game, e.position, r, _buf2)
		if e.is_elite or e.is_boss:
			n = maxi(n, int(u.special["keg_min_enemies"]))
		if n > best_n:
			best_n = n
			best = e
	return best if best_n >= int(u.special["keg_min_enemies"]) else null


## The march -> the burst (-> Magazine Lord's next pack) -> spent -> reform.
func step_special(u: SummonedUnit, delta: float) -> bool:
	match phase:
		MARCH:
			if keg_target != null and keg_target.active and keg_target.generation == keg_gen:
				keg_point = keg_target.position
			else:
				keg_target = null
			var to := keg_point - u.position
			if to.length() <= float(u.special["keg_trigger"]) or phase_time >= float(u.special["keg_march"]):
				u.velocity = Vector2.ZERO
				var gen := u.generation
				var hit := _burst(u, u.position)
				if not u.active or u.generation != gen or u.state == SummonedUnit.State.DEAD:
					return true  # Its own blast set off a foe's keg that felled it (a Powder Runner; the body may already be reused).
				kegs_left -= 1
				if kegs_left > 0:
					var e := _densest(u, u.position, float(u.special["chain_range"]), hit)
					if e != null:
						_aim(e)
						u.game.stat_add("magazine_lord_chains", 1.0)
						next_phase(MARCH)
						return true
				_scatter(u)
			else:
				u.velocity = to / to.length() * float(u.special["keg_speed"])
		SPENT:
			u.velocity = Vector2.ZERO
			u.position = u.game.player.position  # Carried with its necromancer (never leashed away).
			_spent += delta
			if special_time >= REFORM_STEP:
				special_time = 0.0  # A bounded hold (see the header).
			if _spent >= float(u.special["reform_time"]):
				_reform(u)
				end_special(u, SummonedUnit.State.FOLLOWING)
	return true


## THE BURST at `pos`: AoE damage and the knockback. Returns the enemies hit.
func _burst(u: SummonedUnit, pos: Vector2) -> Array:
	var game := u.game
	var r := float(u.special["keg_radius"])
	var dmg := float(u.special["keg_damage"])  # Read once: a foe's death in the loop may fell the wraith (its keys go).
	var shake := float(u.special["keg_shake"])
	var src := EVOLVED_SOURCE if u.evolution != "" else SOURCE
	var gen := u.generation  # The body may be felled and reused inside the loop (see step_special()).
	var v := sqrt(2.0 * EnemyData.KNOCKBACK_DECAY * float(u.special["keg_knockback"]))  # px/s that carries a body keg_knockback px.
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var hit: Array = []
	for e: Enemy in _buf.duplicate():
		if not e.active or e.untargetable or e.position.distance_to(pos) > r + e.radius:
			continue
		hit.append(e)
		if not (e.is_boss or e.is_miniboss or e.is_structure):
			var away := e.position - pos
			e.knockback += (away / away.length() if away.length() > 0.01 else Vector2.UP) * v / maxf(e.mass, 0.1)
		game.combat.damage_enemy(e, dmg, src)
	game.effects.impact(pos, r, Palette.CORSAIR_LANTERN)
	Juice.fx.burst(pos, Palette.CORSAIR_LANTERN_LIGHT, Palette.NECRO_GREEN, 10, r * 2.0, 0.4, 2.5)
	game.shake(shake)
	if game.corsair != null:
		game.corsair.play_sound("keg_burst", pos, 0.1)
	else:
		Sfx.play("powder_blast", pos)
	if u.active and u.generation == gen:
		game.volleys.on_special(u, pos, pos + Vector2.RIGHT, dmg)  # Bullet heaven: the showpiece.
	game.stat_add("powder_wraith_keg_hits", float(hit.size()))
	return hit


## The burst scatters it: spent, hidden and out of the fight until it reforms.
func _scatter(u: SummonedUnit) -> void:
	keg_target = null
	_spent = 0.0
	special_time = 0.0
	u.airborne = true
	u.visible = false
	next_phase(SPENT)


## It stands again at its ring post (a free point round its necromancer).
func _reform(u: SummonedUnit) -> void:
	var p := u.game.player.position
	u.position = u.game.arena.free_point(p + u.anchor_offset, u.radius)
	if u.game.deck != null:
		u.position = u.game.deck.clamp_point(u.position, u.radius)  # Act X: onto the planks (the Deck's one path).
	u.airborne = false
	u.visible = true
	special_cd = cooldown(u)
	u.game.stat_add("powder_wraith_reforms", 1.0)
	u.game.effects.ring(u.position, 16.0, Palette.NECRO_GREEN, 0.35)
	if u.game.arena.is_blocked(u.position, u.radius):
		u.game.stat_add("summon_special_end_blocked", 1.0)


## A recall interrupted it: a march ends without a burst; a spent one reforms.
func on_cancel(u: SummonedUnit) -> void:
	keg_target = null
	if phase == SPENT:
		_reform(u)


## Called when the unit dies / is pooled: never left hidden.
func on_deactivate(u: SummonedUnit) -> void:
	super.on_deactivate(u)
	u.airborne = false
	u.visible = true


## Cluster preference while the keg is ready.
func score_bonus(u: SummonedUnit, e: Enemy, _dp: float) -> float:
	if is_busy() or special_cd > 0.0:
		return 0.0
	var n := count_enemies(u.game, e.position, float(u.special["keg_radius"]), _buf2)
	return float(u.special["cluster_bonus"]) * clampf(float(n) / maxf(float(u.special["keg_min_enemies"]), 1.0), 0.0, 1.0)


## While it marches: the fuse's spark over its keg and the burst's reach at
## its target (textures).
func draw_under(u: SummonedUnit) -> void:
	if phase != MARCH:
		return
	var flick := 0.6 + 0.4 * absf(sin(u.game.elapsed * 22.0))
	SpriteBank.draw_disc(u, Vector2(u.radius * 0.5, -u.radius * 1.6), 3.0 * flick, Color(Palette.CORSAIR_LANTERN_LIGHT, 0.9))
	world_space(u)
	var at := keg_point - u.position
	var rr := float(u.special["keg_radius"])
	if not AoeArt.telegraph(u, "mark_violet", at, rr, 0.0, Palette.CORSAIR_LANTERN):
		u.draw_texture_rect(SpriteBank.disc(), Rect2(at - Vector2(rr, rr), Vector2(rr, rr) * 2.0), false, Color(Palette.CORSAIR_LANTERN, 0.1))
	body_space(u)
