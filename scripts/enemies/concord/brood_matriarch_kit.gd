## BroodMatriarchKit — THE BROOD MATRIARCH, the Crash Site's miniboss
## (CrashSiteEnemyData "brood_matriarch"; Act IX, the Brood; GDD §15.0 "The
## Crash Site (Act IX phase 2)"; owner-approved proposal: "a winged queen-guard
## who spits egg sacs over the ring"). An insect creature in the Brood's
## green-black chitin (female by name, drawn as an insect), spawned by
## CrashSiteDirector's "matriarch" event; she registers as
## EnemyDirector.miniboss (the HUD's miniboss bar; ChestManager drops the
## miniboss chest on her fall: the row's "miniboss"). A FLIER (row "flies":
## Night Wings, ConcordKit.taken_mult(): a grounded melee blow deals her row's
## flight_melee_taken). The shared melee AI flies her in over the ring and she
## claws in reach. Her special:
##   * EGG SACS: every sac_every s (the first after half of it) she rears for
##     sac_windup s (she hangs still), then spits `sacs` sacs that arc over the
##     Bone Ring for sac_flight s, each to a point sac_min..sac_max px from the
##     nearest standing necromancer (evenly spread, turned by her think slot
##     and her volley count: no RNG), with a landing telegraph
##     (EffectManager.telegraph_circle()). Each lands as an INFESTATION EGG
##     through the one egg path (CrashSiteDirector.lay_anywhere(), tag "sac";
##     the egg cap applies). Sacs still in the air when she falls are lost.
## On death: an XP burst (reward_xp in reward_crystals), the miniboss chest.
## Determinism: no RNG. Stats: matriarch_volleys, matriarch_sacs,
## matriarch_sacs_landed, matriarch_kills, matriarch_ttk.
class_name BroodMatriarchKit
extends ConcordKit

## Phase: she rears to spit (hangs still).
const REAR: int = 1

## Seconds until her next volley of sacs.
var sac_cd: float = 0.0
## Volleys spat this life (turns the next volley's spread).
var volleys: int = 0
## Sacs in the air: [from (world px), to (world px), t0 (game s), land (game s)].
var sacs: Array = []
## Game time (s) she arrived (her time to kill).
var spawned_at: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	sac_cd = first_cd(e, float(def.get("sac_every", 6.5)) * 0.5)
	volleys = 0
	sacs.clear()
	spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)


## Every tick: her sacs fly on; she rears and spits on her cooldown.
func physics(e: Enemy, delta: float) -> bool:
	if super.physics(e, delta):
		return true
	_fly_sacs(e)
	sac_cd -= delta
	if phase == REAR:
		phase_time += delta
		hold(e)
		if phase_time >= float(d.get("sac_windup", 0.7)):
			_spit(e)
			set_phase(e, IDLE)
		return true
	if sac_cd <= 0.0:
		sac_cd = float(d.get("sac_every", 6.5))
		set_phase(e, REAR)
		hold(e)
		rules(e).play_sound("brood_chitter", e.position, 0.5)
		return true
	return false


## She spits her volley: `sacs` sacs arc to points around the nearest necromancer.
func _spit(e: Enemy) -> void:
	var g := e.game
	var pl := g.nearest_player(e.position)
	var n := maxi(1, int(d.get("sacs", 3)))
	var base := float(e.think_slot) * 0.7 + float(volleys) * 1.1  # Turns each volley (no RNG).
	var flight := float(d.get("sac_flight", 1.1))
	for k in n:
		var a := base + TAU * float(k) / float(n)
		var dist := lerpf(float(d.get("sac_min", 50.0)), float(d.get("sac_max", 130.0)), float(k % 2))
		var to := g.arena.free_point(pl.position + Vector2.from_angle(a) * dist, 8.0)
		sacs.append([e.position, to, g.elapsed, g.elapsed + flight])
		g.effects.telegraph_circle(to, float(d.get("sac_radius", 12.0)), flight)
	volleys += 1
	g.stat_add("matriarch_volleys", 1.0)
	g.stat_add("matriarch_sacs", float(n))
	g.stat_add("boss_atk_egg_sacs", 1.0)


## The sacs in the air land as Infestation eggs when their time is up.
func _fly_sacs(e: Enemy) -> void:
	if sacs.is_empty():
		return
	var g := e.game
	var i := 0
	while i < sacs.size():
		var s: Array = sacs[i]
		if g.elapsed >= float(s[3]):
			sacs.remove_at(i)
			if CrashSiteDirector.lay_anywhere(g, s[1], "sac") != null:
				g.stat_add("matriarch_sacs_landed", 1.0)
			continue
		i += 1
	e.queue_redraw()


## The XP burst and the stats of her fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.CONCORD_PLASMA)
	g.shake(8.0)
	g.stat_add("matriarch_kills", 1.0)
	g.stat_add("matriarch_ttk", g.elapsed - spawned_at)
	rules(e).play_sound("hive_scream", e.position, 0.5)


## Releases the HUD bar; sacs still in the air are lost.
func on_deactivate(e: Enemy) -> void:
	sacs.clear()
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


func is_busy() -> bool:
	return phase != IDLE


## Her egg sacs in the air (a green-black sac on its arc, in world axes from
## her centre). Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if sacs.is_empty():
		return
	var now := e.game.elapsed
	ci.draw_set_transform_matrix(CourtGlyphs.unmirror_xf(e))
	for s: Array in sacs:
		var k := clampf((now - float(s[2])) / maxf(float(s[3]) - float(s[2]), 0.01), 0.0, 1.0)
		var p: Vector2 = (s[0] as Vector2).lerp(s[1], k) + Vector2(0.0, -70.0 * 4.0 * k * (1.0 - k)) - e.position
		SpriteBank.draw_disc(ci, p, 5.0, Palette.CONCORD_INK)
		SpriteBank.draw_disc(ci, p, 4.0, Palette.CONCORD_CHITIN_LIGHT)
		SpriteBank.draw_disc(ci, p + Vector2(-1.0, -1.0), 1.6, Palette.CONCORD_PLASMA)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)
