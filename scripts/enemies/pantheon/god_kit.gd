## GodKit — the shared base of the PANTHEON TRIAL's gods (Act IV, Mount
## Olympus; GDD §15.0 "The Pantheon Trial"; owner-approved proposal: "Each of
## the first three gods has about a third of a normal stage boss's HP and leaves
## a chest"): AresKit, ArtemisKit, PoseidonKit extend it. Not loaded by a kind
## id of its own (no row names the kit "god"). What every god shares:
##   * HP: on arrival its max HP is set to ZeusData.MAX_HP x the row's
##     god_hp_share x the BOSS's HP multipliers (DifficultyModifiers
##     .boss_hp_mult() x the stage's enemy_hp_mult), never the regular time
##     scaling, so "a third of a stage boss" holds whenever it arrives.
##   * the HUD's one miniboss bar (EnemyDirector.set_miniboss(); the director
##     hands the bar back to an older god still alive when this one falls,
##     OlympusDirector) and the miniboss chest (ChestManager's miniboss rule).
##   * a boss's walk: knockback immunity, striding faster beyond advance_range
##     (it never kites and is never left behind; enemies always advance).
##   * the XP burst on death (reward_xp in reward_crystals), a banner, stats
##     olympus_god_kills_<kind>, olympus_god_ttk_<kind>.
## Subclasses keep their special state machine (CovenantKit phases) and call
## walk() while IDLE. Determinism: no RNG here.
class_name GodKit
extends PantheonKit

## Its walking speed before the forced march (px/s; read on the first tick so
## the difficulty's speed multiplier is included; -1 = not read yet).
var _base_speed: float = -1.0
## Game time it arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## Reusable query buffer.
var _tmp: Array = []
## Who a running lane or circle already struck (OlympusHits).
var _struck: Dictionary = {}


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	GodKit.apply_god_hp(e, def)
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	_struck.clear()
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("olympus_gods_arrived", 1.0)


## Sets a god's max HP (and HP) to its share of Zeus's, with the boss's HP
## scaling (see the header). Also used for any row with "god_hp_share".
static func apply_god_hp(e: Enemy, def: Dictionary) -> void:
	var share := float(def.get("god_hp_share", 0.0))  # Share of Zeus's HP.
	if share <= 0.0:
		return
	e.max_hp = ZeusData.MAX_HP * share * e.game.difficulty.boss_hp_mult() * float(e.game.stage_def.get("enemy_hp_mult", 1.0))
	e.hp = e.max_hp


## The god's walk while no special runs (call from physics() when IDLE):
## immune to knockback, striding faster when far. Returns false (the shared
## melee / ranged AI moves it).
func walk(e: Enemy) -> bool:
	if _base_speed < 0.0:
		_base_speed = e.move_speed
	var far := e.position.distance_to(e.game.player.position) > float(d.get("advance_range", 520.0))  # Left behind.
	e.move_speed = _base_speed * (float(d.get("advance_speed_mult", 1.0)) if far else 1.0)
	return false


func physics(e: Enemy, delta: float) -> bool:
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	return super.physics(e, delta)


## The XP burst, banner and stats of its fall (the chest is ChestManager's,
## the trial's record OlympusDirector's).
func on_killed(e: Enemy) -> void:
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 1)))
	var each := maxi(1, floori(float(d.get("reward_xp", 0)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (26.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.GOLD)
	g.shake(10.0)
	g.enemies.show_banner("%s falls! The trial goes on." % e.display_name)
	g.stat_add("olympus_god_kills_" + e.kind, 1.0)
	g.stat_add("olympus_god_ttk_" + e.kind, g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


## The scaled damage of a special hit (`key` in the row): the time scaling
## (and difficulty) times the god's buffs.
func scaled(e: Enemy, key: String) -> float:
	return float(d[key]) * CovenantKit.hit_scale(e)


## A gold ring under a god, so the trial's champions read as gods. Visual only.
func draw_under(e: Enemy) -> void:
	unmirror(e)
	e.draw_arc(Vector2(0, e.radius * 0.6), e.radius * 1.3, 0.0, TAU, 28, Color(Palette.GOLD, 0.45), 2.0)
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
