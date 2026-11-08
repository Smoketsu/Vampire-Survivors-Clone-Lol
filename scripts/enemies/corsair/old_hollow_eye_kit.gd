## OldHollowEyeKit — OLD HOLLOW-EYE, the Treasure Galleon's miniboss
## (GalleonEnemyData "old_hollow_eye"; Act X, the Black Tide; a creature, the
## kraken; GDD §15.0 "Old Hollow-Eye (Act X)"; brief: "the kraken's arm
## (tentacles in the rail band, every tentacle grabs: SeaStrikes with a
## boss-sized tentacle)"). Brought by GalleonDirector's "hollow_eye" event
## through SeaStrikes.spawn_swimmer() (forced past the swimmer cap). A
## swimmer like the Kraken Arm, moved only by SeaStrikes:
##   * its strike is the shared TENTACLE (row "strike": a 46 px circle on the
##     rail band every ~4 s, a grab through held_until + one stun_unit(), the
##     drag overboard), so it is hittable only while surfaced (the telegraph,
##     the surface time, a grab's 3 s);
##   * every "arm_every" s, while fewer than "arms_max" Kraken Arms swim, it
##     raises one more (SeaStrikes.spawn_swimmer(), forced): every tentacle
##     grabs;
##   * it registers as the HUD's miniboss (EnemyDirector.set_miniboss(); the
##     miniboss chest is ChestManager's).
##   * after "tire_after" s it TIRES (the lead's cap on its kill time): no more
##     strikes or arms; it comes up at the hull beside the necromancer and stays
##     there surfaced (hittable) until it dies, so it falls near the other minibosses' kill times.
## Dead: an XP burst (reward_xp in reward_crystals at the rail nearest it),
## the banner; its arms stay (kill them as usual).
## Determinism: no RNG of its own (SeaStrikes' seeded points and jitter).
## Stats: hollow_eye_spawned, hollow_eye_arms, hollow_eye_kills, hollow_eye_ttk,
## hollow_eye_tired.
class_name OldHollowEyeKit
extends CorsairKit

## Seconds until it raises its next arm.
var _arm_cd: float = 0.0
## Game time (s) it arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## True once it has tired ("tire_after"): surfaced for good, no strikes or arms.
var _tired: bool = false


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_arm_cd = float(d.get("arm_every", 11.0)) * 0.5
	_spawned_at = e.game.elapsed
	_tired = false
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("hollow_eye_spawned", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	if in_water and e.game.corsair != null and e.game.corsair.enabled:
		var now := e.game.elapsed
		var tire := float(d.get("tire_after", 0.0))  # s after its arrival it tires (0 = never).
		if not _tired and tire > 0.0 and now - _spawned_at >= tire and not striking:
			_tired = true
			e.game.stat_add("hollow_eye_tired", 1.0)
			# It drifts up beside the necromancer (the bound slot) and holds there:
			# SeaStrikes keeps a "striking" swimmer still at the hull.
			swim_s = e.game.deck.perimeter_s(e.game.player.position)
			e.position = e.game.corsair.sea.swim_point(e, swim_s)
			striking = true
		if _tired:
			surfaced_until = now + 1.0  # Stays up at the hull: hittable until it dies.
			next_strike = now + 1.0  # No more tentacles.
			return super.physics(e, delta)
		_arm_cd -= delta
		if _arm_cd <= 0.0:
			_arm_cd = float(d.get("arm_every", 11.0))
			if _arms(e) < int(d.get("arms_max", 3)):
				if e.game.corsair.sea.spawn_swimmer("kraken_arm", e.game.enemies.hp_mult, false, 1.0, false, true):
					e.game.stat_add("hollow_eye_arms", 1.0)
					rules(e).play_sound("kraken_rise", e.position, 0.5)
	return super.physics(e, delta)


## Kraken Arms swimming now.
static func _arms(e: Enemy) -> int:
	var n := 0
	for s: Array in e.game.corsair.sea.swimmers:
		var o: Enemy = s[0]
		if o.active and o.generation == int(s[1]) and o.kind == "kraken_arm":
			n += 1
	return n


## While surfaced: a wide churn of foam round the beast (visual only).
func draw_under(e: Enemy) -> void:
	if in_water and surfaced(e):
		SpriteBank.draw_disc(e, Vector2.ZERO, e.radius * 1.8, Color(Palette.CORSAIR_FOAM, 0.3))


## The XP burst, the banner and the stats.
func on_killed(e: Enemy) -> void:
	var g := e.game
	super.on_killed(e)
	var n := maxi(1, int(d.get("reward_crystals", 14)))
	var each := maxi(1, floori(float(d.get("reward_xp", 300)) / float(n)))  # XP per crystal.
	var at := e.position
	if g.deck != null:
		var rail: Array = g.deck.nearest_rail(e.position)
		at = (rail[0] as Vector2) - (rail[1] as Vector2) * 50.0  # On the deck, by the rail.
	for i in n:
		g.pickups.spawn(at + Vector2.from_angle(TAU * float(i) / float(n)) * (22.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.CORSAIR_KRAKEN)
	g.shake(6.0)
	g.enemies.show_banner(String(GalleonData.HOLLOW_EYE["banner_dead"]))
	g.stat_add("hollow_eye_kills", 1.0)
	g.stat_add("hollow_eye_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)
