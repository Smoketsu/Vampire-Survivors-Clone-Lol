## UshabtiSentinelBehavior — the Ushabti Sentinel's kit ("reassemble", UnitData
## "ushabti_sentinel"; temporary Act XII, the Hall of Two Truths' finale reward;
## GDD §15.0 "The Ushabti Sentinel, Eternal Guard and Answering Words";
## owner-approved proposal: "Finale summon class: the Ushabti Sentinel, a stone
## servant that reassembles once every 25 s when slain, at half health
## (evolution Eternal Guard). It is a class special, so it works everywhere").
## A mummiform stone shabti, the necromancer's own servant (soul-teal eyes), a
## blocker on the Bone Ring. It works the same on every stage (owner rule:
## summons never get act-only rules):
##   * IT REASSEMBLES: the blow that would slay it (CombatResolver.damage_unit(),
##     THE one hit path, asks on_lethal() before the death) instead breaks it
##     into RUBBLE when its reassembly is ready (once every
##     reassemble_cooldown s, the class special's clock): it lies where it fell
##     for rubble_time s, still a body on the ring (it blocks) but
##     taking no damage (damage_taken_mult() 0), then stands again at
##     reassemble_hp of its max HP with a stone shockwave: reform_damage to the
##     foes within reform_radius px (its own source, REFORM_SOURCE /
##     EVOLVED_REFORM_SOURCE) and the class volley (VolleyDirector.on_special()).
##     With the reassembly spent, the blow slays it as any summon.
##   * Recalled while it lies in rubble (the FSM wins over every special), it
##     stands at once, with the same health and no shockwave.
## Eternal Guard (its evolution) reassembles more often and stronger (its
## special_set keys); Answering Words (the paired passive) hastens every class
## special's *_cooldown keys (HordeDirector._special_stats(), its own
## category), the reassembly included. Other deaths (a temporary summon's time
## running out, a summon eaten or dissolved) are not blows: no reassembly.
## Determinism: no RNG beyond the shared first-cooldown stagger (SummonBehavior
## .reset()). Stats: ushabti_reassembled, ushabti_reform_hits,
## ushabti_rubble_blocked (hits it took as rubble), ushabti_slain.
class_name UshabtiSentinelBehavior
extends SummonBehavior

## Class id (UnitData, UnlockData, mastery).
const CLASS_ID: String = "ushabti_sentinel"
## Its evolution's id (SummonEvolutionData).
const EVOLUTION_ID: String = "eternal_guard"
## Damage-source tag of the reform shockwave (the base Sentinel).
const REFORM_SOURCE: String = "ushabti_reform"
## Damage-source tag of Eternal Guard's shockwave.
const EVOLVED_REFORM_SOURCE: String = "eternal_guard_reform"
## Passive id of Answering Words (its paired passive; PassiveData, UnlockData).
const ANSWERING: String = "answering_words"
## Answering Words' level-row key: share every class special's *_cooldown keys
## are hastened by (HordeDirector._special_stats()).
const ANSWERING_KEY: String = "answer_haste"
## Phase: lying in rubble.
const RUBBLE: int = 1
## Px the rubble lies flattened (drawing only).
const RUBBLE_SQUASH: float = 0.45  # TUNING (not in GDD) drawing only

## Reusable enemy query buffer.
var _buf: Array = []


## Full reassembly cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("reassemble_cooldown", 25.0))


## True when the reassembly is ready (the class special's clock has run).
func ready_to_reassemble() -> bool:
	return special_cd <= 0.0 and phase == IDLE


## The blow that would slay it (CombatResolver.damage_unit()): with the
## reassembly ready it breaks into rubble instead (true: the death is
## skipped); false lets it die.
func on_lethal(u: SummonedUnit) -> bool:
	if not ready_to_reassemble() or u.state == SummonedUnit.State.SPAWNING:
		u.game.stat_add("ushabti_slain", 1.0)
		return false
	u.hp = 1.0
	begin_special(u, RUBBLE)
	u.game.effects.pop(u.position, Palette.DYN_SAND, u.radius * 2.0)
	return true


## No hit lands on the rubble (it still blocks on the ring).
func damage_taken_mult(u: SummonedUnit, _source: String) -> float:
	if phase == RUBBLE:
		u.game.stat_add("ushabti_rubble_blocked", 1.0)
		return 0.0
	return 1.0


## The rubble lies still; when its time is up it stands again.
func step_special(u: SummonedUnit, _delta: float) -> bool:
	u.velocity = Vector2.ZERO
	if phase_time >= float(u.special.get("rubble_time", 1.2)):
		_reform(u, true)
		end_special(u, SummonedUnit.State.FOLLOWING)
	return true


## Recalled while in rubble: it stands at once (no shockwave).
func on_cancel(u: SummonedUnit) -> void:
	if phase == RUBBLE:
		_reform(u, false)


## Stands again at reassemble_hp of its max HP; with `wave` the stone shockwave
## strikes round it and the class volley fires.
func _reform(u: SummonedUnit, wave: bool) -> void:
	var g := u.game
	u.hp = maxf(u.hp, u.max_hp * float(u.special.get("reassemble_hp", 0.5)))
	special_cd = cooldown(u)
	g.stat_add("ushabti_reassembled", 1.0)
	g.effects.ring(u.position, float(u.special.get("reform_radius", 50.0)), Palette.DYN_SAND_LIGHT, 0.3)
	u.queue_redraw()
	if not wave:
		return
	var evolved := u.special.has("eternal")
	var src := EVOLVED_REFORM_SOURCE if evolved else REFORM_SOURCE
	var dmg := float(u.special.get("reform_damage", 20.0))
	var r := float(u.special.get("reform_radius", 50.0))
	g.enemy_grid.query(u.position, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var hits := 0
	for e: Enemy in _buf:
		if e.active and e.position.distance_to(u.position) <= r + e.radius:
			g.combat.damage_enemy(e, dmg, src)
			hits += 1
	g.stat_add("ushabti_reform_hits", float(hits))
	g.shake(1.0)
	g.volleys.on_special(u, u.position, u.position + Vector2.RIGHT, dmg)  # Bullet heaven: the showpiece.


## The rubble lies low: the body is drawn sunk (no height while it lies).
func body_lift(_u: SummonedUnit) -> float:
	return 0.0


## The rubble under the body while it lies broken (a sand-stone heap).
func draw_under(u: SummonedUnit) -> void:
	if phase != RUBBLE:
		return
	world_space(u)
	var r := u.radius * 1.6
	u.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r * RUBBLE_SQUASH), Vector2(r * 2.0, r * 2.0 * RUBBLE_SQUASH)), false, Color(Palette.DYN_SAND_DARK, 0.85))
	u.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r * 0.6, -r * 0.5), Vector2(r * 1.2, r * 0.6)), false, Palette.DYN_SAND)
	body_space(u)
