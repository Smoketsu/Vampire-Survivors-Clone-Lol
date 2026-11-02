## CourtKit — base class of the Sanguine Court's kits (Act VII; GDD §15.0 "Act
## VII foundation (phase 1)"), a CovenantKit plugged into the shared Enemy AI
## like every kit. Kits load by name from scripts/enemies/court/<id>_kit.gd
## (CovenantKits, after the Eye's, the Empire's, the Pantheon's, the
## Shogunate's and the Inferno's folders; an id must not repeat theirs). What
## every Court kind shares:
##   * creating the shared rules on first use (Game.court_rules()), so a Court
##     kind forced onto any stage with --spawn= still feeds and flies there (the
##     Blood Moon and the Endless Feast stay off off Act VII);
##   * the row flags as helpers: feed_share() (row "feeds": Bloodfeast's share;
##     a kit may override it, e.g. by form), is_flier() (row "flies": Night
##     Wings), is_werebeast() (row "werebeast"), is_noble() (row "noble");
##   * NIGHT WINGS for a flier (physics(): the hunt, the swoop, the bite, the
##     landing; taken_mult(): only airborne, ranged and spell hits in flight;
##     draw_under(): its ground shadow; NightWings documents the rule);
##   * the Silver Bones hook for a werebeast or noble (taken_mult():
##     CourtRules.silver_bones_mult(), exactly 1 while the passive does not
##     exist);
##   * the blood shield ring over a feeder that banked one (draw_over();
##     Bloodfeast).
## Phase 2 kinds extend this class: override physics() for a special and call
## super.physics() first when the kind flies (a flier's swoop owns the tick
## while it runs); call super.reset() / super.taken_mult() / super.draw_under()
## / super.draw_over() when they override those.
## Determinism: no RNG, no instance ids.
class_name CourtKit
extends CovenantKit

## Night Wings phase of a flier (NightWings.AIR / SWOOP / LANDED).
var wing_phase: int = NightWings.AIR
## Seconds in the current Night Wings phase.
var wing_t: float = 0.0
## The swoop's target (a summon or a necromancer; null in the air).
var _wing_target: Node2D = null
## Pool generation of a summon swoop target (stale guard; 0 for a necromancer).
var _wing_gen: int = 0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	wing_phase = NightWings.AIR
	wing_t = 0.0
	_wing_target = null
	e.game.court_rules().note_spawn(e)  # The shared rules exist wherever a Court kind walks.


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	wing_phase = NightWings.AIR
	_wing_target = null


## The shared rules (created on first use).
static func rules(e: Enemy) -> CourtRules:
	return e.game.court_rules()


## Bloodfeast share (0..1) of this kind now: the row's "feeds" (owner-approved:
## vampires 0.5, the others 0.25). Override to change it by form.
func feed_share(_e: Enemy) -> float:
	return float(d.get("feeds", 0.0))


## True for a flier (row "flies"): Night Wings.
func is_flier() -> bool:
	return bool(d.get("flies", false))


## True for a werebeast (row "werebeast"): it transforms (WerewolfKit).
func is_werebeast() -> bool:
	return bool(d.get("werebeast", false))


## True for a noble (row "noble"): mist form (VampireNobleKit).
func is_noble() -> bool:
	return bool(d.get("noble", false))


## True while a flier is in the air (no grounded melee blow lands).
func in_flight() -> bool:
	return is_flier() and wing_phase == NightWings.AIR


# =====================================================================================
# Night Wings (fliers)
# =====================================================================================

## Per-tick hook: a flier's Night Wings (see NightWings); false for any other
## kind (subclasses add their specials after calling this).
func physics(e: Enemy, delta: float) -> bool:
	if not is_flier():
		return false
	return _wings(e, delta)


## A flier's tick: the swoop and the landing own it; in the air it keeps its
## prey (the necromancer, or a priest inside the ring) and swoops when its blow
## is ready and its target within reach.
func _wings(e: Enemy, delta: float) -> bool:
	match wing_phase:
		NightWings.SWOOP:
			wing_t += delta
			hold(e)
			_follow(e, delta)  # It dives after its prey.
			e.queue_redraw()  # The shadow grows under it.
			if wing_t >= float(d.get("swoop_time", 0.5)):
				_bite(e)
				wing_phase = NightWings.LANDED
				wing_t = 0.0
			return true
		NightWings.LANDED:
			wing_t += delta
			hold(e)
			if wing_t >= float(d.get("landed_time", 0.5)):
				wing_phase = NightWings.AIR
				wing_t = 0.0
				e.queue_redraw()
			return true
	var g := e.game
	if e.target is SummonedUnit and not rules(e).wings.is_prey((e.target as SummonedUnit).unit_class):
		e._set_target(g.player)  # Over the ring: the necromancer is the prey.
		g.stat_add("night_wings_retargets", 1.0)
	if e.attack_cd > 0.0 or not e._target_valid():
		return false
	var t := e.target
	var edge := e.position.distance_to(t.position) - e.radius - body_radius(e, t)
	if edge > e.attack_range + float(d.get("swoop_reach", 6.0)):
		return false
	if t == g.player and g.ultimates.player_untargetable():
		return false
	_wing_target = t
	_wing_gen = (t as SummonedUnit).generation if t is SummonedUnit else 0
	wing_phase = NightWings.SWOOP
	wing_t = 0.0
	g.stat_add("night_wings_swoops", 1.0)
	rules(e).play_sound("bat_screech", e.position, 0.4)
	hold(e)
	return true


## During the swoop the flier dives after its target: it closes to its reach
## at swoop_follow x its move speed (it never overshoots the body's edge).
func _follow(e: Enemy, delta: float) -> void:
	var t := _wing_target
	if t == null or not is_instance_valid(t):
		return
	var to := t.position - e.position
	var dist := to.length()
	var gap := dist - e.radius - body_radius(e, t) - e.attack_range  # px still to close.
	if gap <= 0.0 or dist < 0.01:
		return
	e.position += to / dist * minf(gap, e.move_speed * float(d.get("swoop_follow", 1.5)) * delta)


## The swoop lands: the shared melee blow on its target if it is still in reach
## (Bloodfeast feeds through it), else a miss.
func _bite(e: Enemy) -> void:
	var g := e.game
	var t := _wing_target
	_wing_target = null
	var ok := t != null and is_instance_valid(t)
	if ok and t is SummonedUnit:
		var u := t as SummonedUnit
		ok = u.active and u.generation == _wing_gen and u.state != SummonedUnit.State.DEAD
	elif ok:
		ok = not (t as Necromancer).dead
	if ok:
		var to := t.position - e.position
		var edge := to.length() - e.radius - body_radius(e, t)
		ok = edge <= e.attack_range + float(d.get("swoop_reach", 6.0)) * 2.0
		if ok:
			e._melee_hit(t, to.normalized() if to.length() > 0.01 else Vector2.RIGHT)
			g.stat_add("night_wings_bites_summons" if t is SummonedUnit else "night_wings_bites_you", 1.0)
			return
	e.attack_cd = e.attack_interval
	g.stat_add("night_wings_bites_missed", 1.0)


# =====================================================================================
# Hits (Night Wings, Silver Bones)
# =====================================================================================

## Share of a friendly hit tagged `source` this kind takes: a flier's Night
## Wings rule (NightWings.taken_mult()), times Silver Bones on a werebeast or
## noble (CourtRules.silver_bones_mult()). Exactly 1 for a grounded kind with
## no such passive in play.
func taken_mult(e: Enemy, source: String) -> float:
	var m := 1.0
	if is_flier():
		m *= rules(e).wings.taken_mult(wing_phase, source)
	if is_werebeast() or is_noble():
		m *= CourtRules.silver_bones_mult(e, source)
	return m


func is_busy() -> bool:
	return phase != IDLE or wing_phase != NightWings.AIR


# =====================================================================================
# Drawing (visual only)
# =====================================================================================

## A flier's ground shadow: small and faint below it in the air, growing and
## darkening under it as it swoops, dark under it while landed.
func draw_under(e: Enemy) -> void:
	if not is_flier():
		return
	var cfg := rules(e).wings.cfg
	var k := 0.0  # 0 high in the air .. 1 on the ground.
	if wing_phase == NightWings.SWOOP:
		k = clampf(wing_t / maxf(float(d.get("swoop_time", 0.5)), 0.01), 0.0, 1.0)
	elif wing_phase == NightWings.LANDED:
		k = 1.0
	var lift := lerpf(float(cfg["shadow_lift"]), e.radius * 0.6, k)  # px below the body.
	var a := lerpf(float(cfg["shadow_alpha_air"]), float(cfg["shadow_alpha_land"]), k)
	var w := e.radius * lerpf(0.8, 1.3, k)  # Shadow half-width (px).
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-w, lift - w * 0.4), Vector2(w * 2.0, w * 0.8)), false, Color(0.0, 0.0, 0.0, a))


## The blood shield's ring over a feeder that banked one (Bloodfeast).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if e.blood_shield > 0.0:
		CourtGlyphs.draw_blood_shield(ci, e.radius, e.blood_shield / maxf(e.max_hp * float(CourtRulesData.BLOODFEAST["shield_cap"]), 0.01))
