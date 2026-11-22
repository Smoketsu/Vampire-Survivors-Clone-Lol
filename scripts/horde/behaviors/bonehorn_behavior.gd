## BonehornBehavior — the Bonehorn's TRAMPLING CHARGE ("trample_charge",
## UnitData "bonehorn"; temporary Act XIV, the Last Day's finale reward; GDD
## §15.0 "The Bonehorn, Fossil Tyrant and Petrified Horns"; owner-approved
## proposal: "Finale summon class: the Bonehorn, a skeletal ceratopsian that
## charges in a straight line through a pack, trampling and knocking back,
## then trots back to the ring (evolution Fossil Tyrant). It is a class
## special, so it works on every stage."). A skeletal horned charger with
## soul-teal eye sockets, the necromancer's own, fighting in melee on the Bone
## Ring's front posts between charges. Its special, the same on every stage
## (owner rule: summons never get act-only rules), a ground body all the way
## (the arena's push-out keeps it out of the obstacles, enemies can hit it):
##   1. think(): with the charge ready, it picks the DENSEST PACK within
##      charge_range px of its necromancer (the enemy with the most foes within
##      PACK_RADIUS px, of at most SCAN enemies; charge_min_enemies, or an
##      elite / the boss alone);
##   2. PAW: it lowers its horns for charge_windup s, standing;
##   3. CHARGE: it runs straight at the pack at charge_speed px/s, through it
##      and charge_past px beyond (at most MAX_CHARGE s, never farther than
##      CHARGE_LEASH px from its necromancer, stopping at an obstacle),
##      trampling every foe under its horns once: charge_damage (its own
##      source, SOURCE / EVOLVED_SOURCE) and a knockback along the run
##      (charge_knockback / mass);
##   4. evolved into FOSSIL TYRANT (SummonEvolutionData "fossil_tyrant",
##      special_set tyrant / roar_radius / roar_stun): where the charge ends it
##      ROARS: every foe within roar_radius px is stunned roar_stun s
##      (CombatResolver.stun_enemy());
##   5. the class volley where the charge ends (VolleyDirector.on_special()),
##      then the shared FSM again: it trots back to its post on the ring.
## Leash and recall stay in charge: a recall cancels the charge
## (SummonBehavior.physics()). Petrified Horns (its paired passive, PassiveData
## "petrified_horns", read only here): x 1 + horns_damage on the charge
## damage, the cooldown / (1 + horns_haste).
## Determinism: no RNG (the densest pack, ties in the spatial hash's order).
## Stats: bonehorn_charges, bonehorn_hits, fossil_tyrant_roars,
## fossil_tyrant_stuns, dmg_bonehorn_charge / dmg_fossil_tyrant_charge,
## summon_special_end_blocked (a charge ending inside an obstacle: must be 0).
class_name BonehornBehavior
extends SummonBehavior

## Class id (UnitData, UnlockData, mastery).
const CLASS_ID: String = "bonehorn"
## Its evolution's id (SummonEvolutionData).
const EVOLUTION_ID: String = "fossil_tyrant"
## Damage-source tag of the charge (the base Bonehorn; a minion special, PassiveData).
const SOURCE: String = "bonehorn_charge"
## Damage-source tag of Fossil Tyrant's charge.
const EVOLVED_SOURCE: String = "fossil_tyrant_charge"
## Passive id of Petrified Horns (its paired passive; PassiveData, UnlockData).
const HORNS: String = "petrified_horns"
## Petrified Horns' level-row key: share more charge damage (0..1).
const HORNS_DAMAGE_KEY: String = "horns_damage"
## Petrified Horns' level-row key: share the charge cooldown is hastened by (0..1).
const HORNS_HASTE_KEY: String = "horns_haste"
## Phase: lowering its horns.
const PAW: int = 1
## Phase: charging straight through the pack.
const CHARGE: int = 2
## Enemies scanned for the densest pack (cost bound).
const SCAN: int = 24  # TUNING (not in GDD)
## Px round a candidate within which its pack is counted.
const PACK_RADIUS: float = 60.0  # TUNING (not in GDD)
## Most seconds of one charge.
const MAX_CHARGE: float = 1.2  # TUNING (not in GDD)
## Px from its necromancer past which a charge stops (under the soft recall, so
## the leash never cancels a charge on its own).
const CHARGE_LEASH: float = 280.0  # TUNING (not in GDD) UnitData.SOFT_RECALL is 320
## Stun share kept on a boss / an elite (Fossil Tyrant's roar).
const STUN_BOSS_MULT: float = 0.3  # TUNING (not in GDD)
## Stun share kept on an elite (Fossil Tyrant's roar).
const STUN_ELITE_MULT: float = 0.6  # TUNING (not in GDD)

## The pack's enemy it charges at (null once it died / was recycled).
var charge_target: Enemy = null
## Generation of `charge_target` at the pick (stale-reference guard).
var charge_gen: int = 0
## Unit direction of the charge.
var _dir: Vector2 = Vector2.RIGHT
## Px still to run.
var _left: float = 0.0
## Foes trampled in this charge: [Enemy, generation] pairs.
var _struck: Array = []
## Reusable enemy query buffer.
var _buf: Array = []
## Second reusable enemy query buffer (the pack counts).
var _buf2: Array = []


## Full charge cooldown (s), hastened by Petrified Horns.
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("charge_cooldown", 7.0)) / (1.0 + u.game.abilities.passive_value(HORNS, HORNS_HASTE_KEY))


## Picks the densest pack near its necromancer and lowers its horns.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0:
		return false
	var e := _densest(u, u.game.player.position, float(u.special["charge_range"]))
	if e == null:
		return false
	charge_target = e
	charge_gen = e.generation
	_struck.clear()
	begin_special(u, PAW)
	u.game.stat_add("bonehorn_charges", 1.0)
	return true


## The enemy with the most foes within PACK_RADIUS px, of the first SCAN
## enemies within `reach` px of `from`; null without a pack
## (charge_min_enemies, or an elite / the boss alone).
func _densest(u: SummonedUnit, from: Vector2, reach: float) -> Enemy:
	var game := u.game
	game.enemy_grid.query(from, reach, _buf)
	var best: Enemy = null
	var best_n := 0
	var seen := 0
	var need := int(u.special["charge_min_enemies"])
	for e: Enemy in _buf:
		if seen >= SCAN:
			break
		if not e.active or e.untargetable or e.is_structure or e.civilian or e.position.distance_to(from) > reach:
			continue
		seen += 1
		var n := count_enemies(game, e.position, PACK_RADIUS, _buf2)
		if e.is_elite or e.is_boss:
			n = maxi(n, need)
		if n > best_n:
			best_n = n
			best = e
	return best if best_n >= need else null


## Paw -> charge -> the FSM again.
func step_special(u: SummonedUnit, delta: float) -> bool:
	var p := u.game.player.position
	match phase:
		PAW:
			u.velocity = Vector2.ZERO
			if phase_time >= float(u.special["charge_windup"]):
				var at := charge_target.position if charge_target != null and charge_target.active and charge_target.generation == charge_gen else p
				var to := at - u.position
				_dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
				_left = to.length() + float(u.special["charge_past"])
				Sfx.play("abom_stomp", u.position, 0.8)  # A startup-bank sound: the class plays on every stage.
				next_phase(CHARGE)
		CHARGE:
			var step_len := float(u.special["charge_speed"]) * delta
			var nxt := u.position + _dir * step_len
			if _left <= 0.0 or phase_time >= MAX_CHARGE or nxt.distance_to(p) > CHARGE_LEASH or u.game.arena.is_blocked(nxt, u.radius):
				u.velocity = Vector2.ZERO
				_finish(u)
				return true
			u.velocity = _dir * float(u.special["charge_speed"])
			_left -= step_len
			_trample(u)
	return true


## Tramples every foe under its horns not yet struck this charge.
func _trample(u: SummonedUnit) -> void:
	var game := u.game
	var reach := u.radius + float(u.special["charge_rim"])
	var dmg := float(u.special["charge_damage"]) * (1.0 + game.abilities.passive_value(HORNS, HORNS_DAMAGE_KEY))
	var src := EVOLVED_SOURCE if u.special.has("tyrant") else SOURCE
	var kb := float(u.special["charge_knockback"])
	var hits: Array = []  # Own buffer: a kill may query the grid again.
	game.enemy_grid.query(u.position, reach + ProjectileManager.MAX_BODY_RADIUS, hits)
	var n := 0
	for e: Enemy in hits:
		if not e.active or e.untargetable or e.civilian or e.position.distance_to(u.position) > reach + e.radius:
			continue
		var seen := false
		for h: Array in _struck:
			if h[0] == e and int(h[1]) == e.generation:
				seen = true
				break
		if seen:
			continue
		_struck.append([e, e.generation])
		e.knockback += _dir * kb / maxf(e.mass, 0.1)
		game.combat.damage_enemy(e, dmg, src, u.director.slot, u.position)
		n += 1
	if n > 0:
		game.stat_add("bonehorn_hits", float(n))


## The charge ended: Fossil Tyrant's roar, the class volley, then back to the
## shared FSM (on a free point: it never ends inside an obstacle).
func _finish(u: SummonedUnit) -> void:
	var g := u.game
	if g.arena.is_blocked(u.position, u.radius):
		u.position = g.arena.free_point(u.position, u.radius)
		if g.arena.is_blocked(u.position, u.radius):
			g.stat_add("summon_special_end_blocked", 1.0)
	if u.special.has("tyrant"):
		var r := float(u.special["roar_radius"])
		var near: Array = []  # Own buffer: the stuns never kill, but stay safe.
		g.enemy_grid.query(u.position, r + ProjectileManager.MAX_BODY_RADIUS, near)
		var n := 0
		for e: Enemy in near:
			if e.active and not e.untargetable and not e.civilian and e.position.distance_to(u.position) <= r + e.radius \
					and g.combat.stun_enemy(e, float(u.special["roar_stun"]), STUN_BOSS_MULT, STUN_ELITE_MULT) > 0.0:
				n += 1
		g.stat_add("fossil_tyrant_roars", 1.0)
		g.stat_add("fossil_tyrant_stuns", float(n))
		g.effects.ring(u.position, r, Palette.BONE, 0.3)
	else:
		g.effects.ring(u.position, u.radius * 3.0, Palette.BONE, 0.25)
	g.volleys.on_special(u, u.position, u.position + _dir, float(u.special["charge_damage"]))  # Bullet heaven: a burst of bone shards.
	charge_target = null
	_struck.clear()
	end_special(u, SummonedUnit.State.FOLLOWING)  # It trots back to the ring.


## A recall interrupted the charge: drop it (the arena's push-out keeps it
## out of the obstacles).
func on_cancel(_u: SummonedUnit) -> void:
	charge_target = null
	_struck.clear()


## While it charges: a short dust trail behind it (textures only).
func draw_under(u: SummonedUnit) -> void:
	if phase != CHARGE:
		return
	world_space(u)
	for k in 3:
		var at := -_dir * (u.radius * (1.0 + 0.9 * float(k)))
		var r := u.radius * (0.8 - 0.2 * float(k))
		u.draw_texture_rect(SpriteBank.disc(), Rect2(at - Vector2(r, r * 0.5), Vector2(r * 2.0, r)), false, Color(Palette.BONE, 0.22 - 0.06 * float(k)))
	body_space(u)
