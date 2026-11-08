## BossVandermere — CAPTAIN CORNELIUS VANDERMERE, MASTER OF THE HOLLOW QUEEN,
## the boss of the Maelstrom, the Black Tide's finale (Act X; GDD §15.0
## "Captain Cornelius Vandermere"; owner-approved proposal: the Crew, the
## Maelstrom, Dead Men's Oath). Loaded by name for the boss id "vandermere"
## (EnemyDirector.CORSAIR_BOSS_DIR + "boss_vandermere.gd"); he arrives at 17:00
## (3:00 left) over the stern rail, lashed to his ship's wheel, and drifts at
## the necromancer with it (enemies always advance), striking with the spokes
## in reach. Extends Boss, so summons, spells and the spatial hash treat him
## like any enemy; a boss on the deck is clamped like any deck body and never
## drowns (DeckBounds). Numbers in VandermereData.BOSS:
##   * DEAD MEN'S OATH (all fight): while the Oath holds he takes only
##     oath_taken of every hit (damage_taken_mult(), the one enemy-side
##     modifier). Every ghost crewman the army RAISES chips it oath_chip (2%:
##     oath_chip(), called by MaelstromDirector on each raise of the
##     Brotherhood's own dead). Empty, it BREAKS: he takes vulnerable_taken of
##     every hit for vulnerable_time s (15 s), then the Oath refills and his
##     crew returns (refill_boats spectral longboats).
##   * THE CREW: every crew_every s (crew_every_p2 in the Maelstrom) he stands
##     crew_cast s calling, and crew_boats spectral longboats come alongside
##     with crew_size drowned crewmen each (BoardingParty.launch_boat() through
##     MaelstromDirector.launch_crew()); the ghost boats circling the gyre are
##     MaelstromDirector's drawing.
##   * HIS LANTERN VOLLEY (own decision): every volley_every s, the necromancer
##     within volley_range px, he stands volley_cast s, then volley_count
##     spectral shots fan at the necromancer (the hostile projectile path).
##   * THE MAELSTROM (below phase2_hp): the Heave peaks (MaelstromDirector
##     .set_peak(): faster, flips sooner, the low rail drowns what is pressed
##     on it), kraken_arms kraken arms surface (CorsairRules.route_spawn()), and
##     every kraken_every s an ownerless strike lands on the LOW rail's band
##     beside the necromancer (SeaStrikes.strike()).
## When he falls the whirlpool closes: the Heave stops and, fallen with the
## Oath broken TALES_BREAKS (2) times or more, the run stat TALES_STAT is set
## (Dead Men Tell Tales, MetaProgress): MaelstromDirector hears his fall
## (EnemyDirector.boss_defeated) and reads `breaks`. The defeat banner is the
## short ending. Slaying him unlocks Anchor Drop with
## Dead Reckoning and the Powder Wraith with Slow Match (UnlockData, boss
## "vandermere").
## Determinism: the seeded gameplay RNG only (the low-rail strikes' scatter).
## Stats: boss_atk_<special>, vandermere_oath_chips, vandermere_oath_breaks,
## vandermere_crew_boats, vandermere_volley_shots, vandermere_kraken_strikes,
## vandermere_maelstrom_at, vandermere_vulnerable_dmg.
class_name BossVandermere
extends Boss

## Boss action phases.
enum Phase { WALK, CREW_CAST, VOLLEY_CAST, RECOVER }

## Current action phase.
var phase: Phase = Phase.WALK
## Seconds spent in the current phase.
var phase_time: float = 0.0
## True once the Maelstrom began (below phase2_hp).
var maelstrom: bool = false
## The Oath's strength (1 = whole, 0 = broken).
var oath: float = 1.0
## Game time (s) until which the Oath is broken (he is vulnerable); 0 = holding.
var vulnerable_until: float = 0.0
## Times the Oath broke this fight.
var breaks: int = 0
## Seconds until his next crew call.
var crew_cd: float = 0.0
## Seconds until his next volley.
var volley_cd: float = 0.0
## Seconds until the next kraken strike on the low rail (the Maelstrom).
var kraken_cd: float = 0.0
## His move speed before the advance stride (px/s).
var _base_speed: float = 32.0


## Sets up Vandermere at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = VandermereData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.WALK
	phase_time = 0.0
	maelstrom = false
	oath = 1.0
	vulnerable_until = 0.0
	breaks = 0
	crew_cd = float(boss_def["first_crew"])
	volley_cd = float(boss_def["first_volley"])
	kraken_cd = 0.0
	_base_speed = move_speed
	game.corsair_rules()  # His crew and the kraken go through the Black Tide's paths (created on another stage too).


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return VandermereData.SPECIALS


## True while he drifts at the necromancer (Boss hook, stuck check).
func is_walking() -> bool:
	return phase == Phase.WALK


## Sprite key of his art (engine-motion pivot): Vandermere at his wheel.
func motion_sprite_key() -> String:
	return "corsair/vandermere"


## True while the Oath is broken (he is vulnerable).
func is_vulnerable() -> bool:
	return vulnerable_until > game.elapsed


## DEAD MEN'S OATH (the one enemy-side modifier, CombatResolver.damage_enemy()):
## oath_taken of a hit while it holds, vulnerable_taken while it is broken.
func damage_taken_mult(source: String) -> float:
	var m := super.damage_taken_mult(source)
	if source == CorsairRulesData.DROWN_SOURCE:
		return m
	if is_vulnerable():
		return m * float(boss_def["vulnerable_taken"])
	return m * float(boss_def["oath_taken"])


## A ghost crewman was raised by the army (MaelstromDirector.on_ghost_died()):
## the Oath loses oath_chip; empty, it breaks.
func oath_chip() -> void:
	if not active or is_vulnerable():
		return
	oath = maxf(0.0, oath - float(boss_def["oath_chip"]))
	game.stat_add("vandermere_oath_chips", 1.0)
	if oath <= 0.0:
		_break_oath()


## The Oath breaks: vulnerable for vulnerable_time s.
func _break_oath() -> void:
	breaks += 1
	vulnerable_until = game.elapsed + float(boss_def["vulnerable_time"])
	game.stat_add("vandermere_oath_breaks", 1.0)
	game.stat_add("boss_atk_oath_break", 1.0)
	game.enemies.show_banner(String(boss_def["oath_banner"]))
	game.effects.impact(position, radius * 3.0, Palette.CORSAIR_SPECTRE_LIGHT)
	game.shake(4.0)
	game.corsair_rules().play_sound("oath_break", position, 0.5)
	queue_redraw()


## The Oath refills after its broken window: his crew returns.
func _refill_oath() -> void:
	vulnerable_until = 0.0
	oath = 1.0
	game.enemies.show_banner(String(boss_def["refill_banner"]))
	var md := game.enemies.maelstrom
	if md != null:
		game.stat_add("vandermere_crew_boats", float(md.launch_crew(int(boss_def["refill_boats"]), int(boss_def["crew_size"]), int(boss_def["crew_gunners"]))))
	queue_redraw()


## Boss physics: the Oath's clock, the Maelstrom's start and strikes, then his
## phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	crew_cd -= delta
	volley_cd -= delta
	if vulnerable_until > 0.0 and game.elapsed >= vulnerable_until:
		_refill_oath()
	if is_vulnerable():
		game.stat_add("vandermere_vulnerable_time", delta)
	if not maelstrom and hp <= max_hp * float(boss_def["phase2_hp"]):
		_start_maelstrom()
	if maelstrom:
		kraken_cd -= delta
		if kraken_cd <= 0.0:
			kraken_cd = float(boss_def["kraken_every"])
			_kraken_strike()
	match phase:
		Phase.WALK:
			_step_walk(delta)
		Phase.CREW_CAST:
			_hold()
			if phase_time >= float(boss_def["crew_cast"]):
				_call_crew()
				_set_phase(Phase.RECOVER)
		Phase.VOLLEY_CAST:
			_hold()
			if phase_time >= float(boss_def["volley_cast"]):
				_fire_volley()
				_set_phase(Phase.RECOVER)
		Phase.RECOVER:
			_hold()
			if phase_time >= float(boss_def["recover_time"]):
				_set_phase(Phase.WALK)


## Drifting at the necromancer (the shared walk and blow, faster when far); a
## crew call or a volley start when ready.
func _step_walk(delta: float) -> void:
	var dist := position.distance_to(game.player.position)  # To the necromancer (px).
	move_speed = _base_speed * (float(boss_def["advance_speed_mult"]) if dist > float(boss_def["advance_range"]) else 1.0)
	super.physics_step(delta)
	if crew_cd <= 0.0:
		crew_cd = float(boss_def["crew_every_p2" if maelstrom else "crew_every"])
		game.stat_add("boss_atk_crew", 1.0)
		motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		game.corsair_rules().play_sound("crew_call", position, 0.5)
		_set_phase(Phase.CREW_CAST)
	elif volley_cd <= 0.0 and dist <= float(boss_def["volley_range"]):
		volley_cd = float(boss_def["volley_every"])
		game.stat_add("boss_atk_volley", 1.0)
		motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		_set_phase(Phase.VOLLEY_CAST)


## Standing still during a cast or recovery.
func _hold() -> void:
	velocity = Vector2.ZERO


## Changes phase, resets its timer and redraws the pose.
func _set_phase(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


## THE CREW: his spectral longboats come alongside.
func _call_crew() -> void:
	var md := game.enemies.maelstrom
	if md == null:
		return
	game.stat_add("vandermere_crew_boats", float(md.launch_crew(int(boss_def["crew_boats"]), int(boss_def["crew_size"]), int(boss_def["crew_gunners"]))))
	game.effects.ring(position, radius * 3.0, Palette.CORSAIR_SPECTRE_LIGHT, 0.4)


## HIS LANTERN VOLLEY: volley_count shots fanned at the necromancer.
func _fire_volley() -> void:
	var to := game.player.position - position
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	var n := int(boss_def["volley_count"])
	var dmg := float(boss_def["volley_damage"]) * game.enemies.damage_mult * hit_mult()
	for i in n:
		var d := dir.rotated((float(i) - float(n - 1) * 0.5) * float(boss_def["volley_spread"]))
		game.projectiles.fire_hostile(position + d * radius, d, dmg, float(boss_def["volley_speed"]), 1.0,
				Projectile.Kind.RADIANT_BOLT, VandermereData.VOLLEY_SOURCE)
	game.stat_add("vandermere_volley_shots", float(n))
	game.effects.ring(position, radius * 1.6, Palette.CORSAIR_SPECTRE_LIGHT, 0.25)


## THE MAELSTROM begins: the Heave peaks and the kraken surfaces.
func _start_maelstrom() -> void:
	maelstrom = true
	kraken_cd = 1.5
	game.stat_add("vandermere_maelstrom_at", game.elapsed)
	game.stat_add("boss_atk_maelstrom", 1.0)
	game.enemies.show_banner(String(boss_def["phase2_banner"]))
	game.shake(5.0)
	var md := game.enemies.maelstrom
	if md != null:
		md.set_peak(true)
	var c := game.corsair_rules()
	if c.routes():
		for i in int(boss_def["kraken_arms"]):
			c.route_spawn("kraken_arm", game.enemies.hp_mult, false, 1.0, false, false)
	c.play_sound("kraken_rise", position, 0.5)


## The kraken strikes the LOW rail's band beside the necromancer (the Heave's
## low side; either rail while the deck is level).
func _kraken_strike() -> void:
	var c := game.corsair
	if c == null or not c.enabled:
		return
	var md := game.enemies.maelstrom
	var side := md.low_side() if md != null else (1 if randf() < 0.5 else -1)
	var deck := game.deck
	var x := game.player.position.x - deck.center.x + (randf() - 0.5) * float(boss_def["kraken_spread"])
	var at := deck.rail_point(x, side) - Vector2(0.0, float(side)) * float(deck.cfg["rail_band"]) * float(boss_def["kraken_inset"])
	c.sea.strike(at, {"radius": float(boss_def["kraken_radius"])})
	game.stat_add("vandermere_kraken_strikes", 1.0)


# =====================================================================================
# Autopilot hint, drawing, summary
# =====================================================================================

## Danger hint for the autotest autopilot: off the line of his volley while he
## raises the lantern.
func danger_push(p: Vector2) -> Vector2:
	if phase != Phase.VOLLEY_CAST:
		return Vector2.ZERO
	var to := p - position
	if to.length() > float(boss_def["volley_range"]) + 40.0:
		return Vector2.ZERO
	return to.normalized().orthogonal() * 0.8 if to.length() > 0.5 else Vector2.RIGHT


## Body layer on `ci`: his sprite at the wheel (a ghost-green wash while the
## Oath is broken); a code shape without art.
func _draw_body(ci: CanvasItem) -> void:
	var tint := Color(1.0, 1.0, 1.0, 1.0) if not is_vulnerable() else Color(1.0, 0.85, 0.85, 1.0)
	if SpriteBank.draw(ci, "corsair/vandermere", Vector2.ZERO, flash > 0.0, tint):
		return
	SpriteBank.draw_disc(ci, Vector2.ZERO, radius, Palette.CORSAIR_INK)
	SpriteBank.draw_disc(ci, Vector2.ZERO, radius - 2.0, Palette.CORSAIR_SPECTRE_DARK if flash <= 0.0 else Color.WHITE)
	SpriteBank.draw_disc(ci, Vector2(0.0, -radius * 0.4), radius * 0.4, Palette.CORSAIR_SPECTRE_LIGHT)


## Overlay layer on `ci`: the Oath shield (a ring whose strength is its
## brightness), a cracked flicker while broken, and the lantern's glow as he
## readies a volley. Textures only.
func _draw_over(ci: CanvasItem) -> void:
	var ring := CityGlyphs.ring_texture()
	var r := radius * 2.1
	if is_vulnerable():
		var left := clampf((vulnerable_until - game.elapsed) / maxf(float(boss_def["vulnerable_time"]), 0.01), 0.0, 1.0)
		ci.draw_texture_rect(ring, Rect2(Vector2(-r, -r), Vector2(r, r) * 2.0), false, Color(Palette.CRIMSON, 0.25 + 0.3 * left))
	else:
		ci.draw_texture_rect(ring, Rect2(Vector2(-r, -r), Vector2(r, r) * 2.0), false, Color(Palette.CORSAIR_SPECTRE_LIGHT, 0.2 + 0.6 * oath))
	if phase == Phase.VOLLEY_CAST or phase == Phase.CREW_CAST:
		SpriteBank.draw_disc(ci, Vector2(0.0, -radius * 1.2), 6.0, Color(Palette.CORSAIR_SPECTRE_LIGHT, 0.7))


## One autotest summary line of his fight.
static func summary_line(st: Dictionary) -> String:
	var m := float(st.get("vandermere_maelstrom_at", -1.0))
	return "crew calls %d (spectral longboats %d) | volleys %d (shots %d) | maelstrom %s (kraken strikes %d) | oath chips %d, breaks %d (vulnerable %.0f s) | dead men tell tales %s | dmg to player %d, summons %d" % [
		int(st.get("boss_atk_crew", 0.0)), int(st.get("vandermere_crew_boats", 0.0)), int(st.get("boss_atk_volley", 0.0)),
		int(st.get("vandermere_volley_shots", 0.0)), EmpireReport._clock(m) if m >= 0.0 else "not reached",
		int(st.get("vandermere_kraken_strikes", 0.0)), int(st.get("vandermere_oath_chips", 0.0)), int(st.get("vandermere_oath_breaks", 0.0)),
		float(st.get("vandermere_vulnerable_time", 0.0)), "EARNED" if float(st.get(VandermereData.TALES_STAT, 0.0)) > 0.0 else "no",
		int(st.get("player_dmg_from_" + VandermereData.VOLLEY_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + VandermereData.VOLLEY_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
