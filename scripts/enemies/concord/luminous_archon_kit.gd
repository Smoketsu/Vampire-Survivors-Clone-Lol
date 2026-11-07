## LuminousArchonKit — the kit of THE LUMINOUS ARCHON, the Ark of the Concord's
## miniboss (ArkEnemyData "luminous_archon"; Act IX, the Luminous; GDD §15.0
## "The Ark of the Concord (Act IX phase 2)"; owner-approved proposal:
## "Miniboss, the Luminous Archon, a being of pure light whose every attack is
## a beam to reflect"). Male, as the Lumen Sentinel but larger, in white-gold
## crystal. ArkDirector sends it (the "luminous_archon" event); on activation
## it registers for the HUD's miniboss bar (EnemyDirector.set_miniboss()) and
## the ChestManager drops its chest when it falls (row "miniboss"). Its shield
## is the existing holy shield (row "lumen_shield", ConcordKit.reset()). It
## never strikes in melee: EVERY ATTACK IS A CONCORD BEAM through
## ConcordBeams.fire() with the boss override (THE beam path; Orb Shields and
## barriers send them back into it, the shared reflection):
##   * THE LANCES: every lance_every s a fan of lance_beams "sweep" beams at
##     the necromancer, lance_spread rad apart (the style with
##     lance_overrides);
##   * THE HALO: every halo_every s a ring of halo_beams short "probe" beams
##     all round it (halo_overrides), each aimed at a fixed turn of the
##     circle (the halo count, no RNG).
## While any of its beams aims or holds, it stands still (ConcordKit.physics()).
## Determinism: no RNG. Stats: archon_spawned, archon_lances, archon_halos,
## archon_kill_time.
class_name LuminousArchonKit
extends ConcordKit

## Seconds until its next fan of lances.
var lance_cd: float = 0.0
## Seconds until its next halo.
var halo_cd: float = 0.0
## Halos cast so far (turns the next halo by half a step: no RNG).
var halos: int = 0
## Game time (s) it arrived (the report's kill time).
var arrived_at: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	lance_cd = float(d.get("first_attack", 2.0))
	halo_cd = float(d.get("halo_first", 7.0))
	halos = 0
	arrived_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("archon_spawned", 1.0)
	rules(e).play_sound("harvest_eye", e.position, 1.0)


func on_deactivate(e: Enemy) -> void:
	e.game.enemies.clear_miniboss(e)
	super.on_deactivate(e)


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	g.stats["archon_kill_time"] = g.elapsed - arrived_at
	g.effects.ring(e.position, 120.0, Palette.CONCORD_LUMEN, 0.6)
	g.effects.impact(e.position, 70.0, Palette.CONCORD_LUMEN)
	rules(e).play_sound("beam_reflect", e.position, 0.2)


## Per tick: its beams hold it still; otherwise the halo, then the lances.
func physics(e: Enemy, delta: float) -> bool:
	lance_cd -= delta
	halo_cd -= delta
	if super.physics(e, delta):
		return true
	var g := e.game
	if g.ultimates.player_untargetable():
		return false
	if halo_cd <= 0.0:
		halo_cd = float(d.get("halo_every", 13.0))
		_halo(e)
		return true
	var pl := g.nearest_player(e.position)
	if lance_cd <= 0.0 and pl.position.distance_to(e.position) <= float((d.get("lance_overrides", {}) as Dictionary).get("length", 320.0)) + 40.0:
		lance_cd = float(d.get("lance_every", 5.0))
		_lances(e, pl)
		return true
	return false


## A fan of sweep beams at the necromancer `pl`.
func _lances(e: Enemy, pl: Necromancer) -> void:
	var to := pl.position - e.position
	var base := to.angle() if to.length() > 1.0 else 0.0
	var n := int(d.get("lance_beams", 3))
	var spread := float(d.get("lance_spread", 0.3))
	var fired := 0
	for i in n:
		var off := (float(i) - float(n - 1) * 0.5) * spread
		var over: Dictionary = (d.get("lance_overrides", {}) as Dictionary).duplicate()
		if absf(off) < 0.001:
			over["target"] = pl  # The middle lance tracks him.
		if rules(e).beams.fire(e, Vector2.from_angle(base + off), "sweep", over, true):
			fired += 1
	if fired > 0:
		e.game.stat_add("archon_lances", 1.0)
		e.game.stat_add("boss_atk_archon_lance", 1.0)
		motion_lunge_safe(e, to)


## A halo of short beams all round it.
func _halo(e: Enemy) -> void:
	var n := maxi(1, int(d.get("halo_beams", 6)))
	var turn := float(halos) * PI / float(n)  # Half a step each halo (no RNG).
	halos += 1
	for i in n:
		var over: Dictionary = (d.get("halo_overrides", {}) as Dictionary).duplicate()
		rules(e).beams.fire(e, Vector2.from_angle(turn + TAU * float(i) / float(n)), "probe", over, true)
	e.game.stat_add("archon_halos", 1.0)
	e.game.effects.ring(e.position, 40.0, Palette.CONCORD_LUMEN, 0.4)


## A small cast lunge toward `dir` (engine motion; visual only).
static func motion_lunge_safe(e: Enemy, dir: Vector2) -> void:
	if dir.length() > 0.5:
		e.motion_lunge(dir.normalized(), MotionData.POWER_CAST)


func is_busy() -> bool:
	return true  # Its beams own its turns (the stuck check skips it).


## A white-gold glow over its crystal body (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var a := 0.22 + 0.12 * sin(e.game.elapsed * 2.2)
	SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 1.2), e.radius * 0.9, Color(Palette.CONCORD_LUMEN, a))
