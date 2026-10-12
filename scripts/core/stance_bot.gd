## StanceBot — the autotest's army-stance driver (owner-approved Army
## Stances, StanceData). Autotest.step() calls step() every simulation step.
##   * --stance=ID: that stance is forced at the first step (ignoring the
##     Spearhead unlock) and held for the whole run.
##   * naive / pact (StanceData.BOT_ESCORT_POLICIES): Escort all run, so
##     their long-standing baselines (and the CI runs) do not move.
##   * army / summon / evolve: every StanceData.BOT_INTERVAL game seconds
##     the bot picks, in this order:
##       1. Bone Ring  — the necromancer is in danger
##                       (HordeDirector.player_in_danger) or the stage boss
##                       is alive within BOT_BOSS_CLOSE px;
##       2. Onslaught  — at most BOT_FEW_ENEMIES enemies within
##                       BOT_NEAR_RADIUS px, and a Crimson March structure
##                       (outpost, ward generator, supply cart) is within
##                       BOT_STRUCTURE_RADIUS px or the screen is nearly
##                       clear (at most BOT_CLEAR_COUNT enemies within
##                       BOT_SCREEN_RADIUS px);
##       3. Spearhead  — when unlocked (Ossuary, --meta=mid|max) and a
##                       treasure chest or power-up drop is within
##                       BOT_LOOT_RADIUS px (the autopilot walks to it);
##       4. Escort     — otherwise.
##     The request goes through ArmyStance.request() like a key press, so
##     the 1.5 s switch lockout applies.
## Deterministic: it only reads the simulation (no RNG, no wall clock).
class_name StanceBot
extends RefCounted

## Game time of the next decision.
var _next_decision: float = 0.0
## True once the forced --stance was applied (or found unnecessary).
var _forced_done: bool = false
## Reusable enemy-grid query buffer.
var _tmp: Array = []


## How the run's stance is driven: "forced <id>", "escort (policy
## baseline)" or "bot switching".
static func mode() -> String:
	if GameState.autotest_stance != "":
		return "forced " + GameState.autotest_stance
	if GameState.autotest_policy in StanceData.BOT_ESCORT_POLICIES:
		return "escort (policy baseline)"
	return "bot switching"


## Called by Autotest every simulation step.
func step(game: Game) -> void:
	if GameState.autotest_stance != "":
		if not _forced_done:
			_forced_done = true
			game.stance.request(GameState.autotest_stance, true)
		return
	if GameState.autotest_policy in StanceData.BOT_ESCORT_POLICIES:
		return
	if game.elapsed < _next_decision:
		return
	_next_decision = game.elapsed + StanceData.BOT_INTERVAL
	var want := choose(game)  # Stance the rule asks for.
	if want != game.stance.current:
		game.stance.request(want)


## The bot's rule (see the header): the stance it wants right now.
func choose(game: Game) -> String:
	var p := game.player.position
	var boss := game.enemies.boss
	if game.horde.player_in_danger:
		return "bone_ring"
	if boss != null and boss.active and boss.position.distance_to(p) <= StanceData.BOT_BOSS_CLOSE + boss.radius:
		return "bone_ring"
	if _count_within(game, p, StanceData.BOT_NEAR_RADIUS) <= StanceData.BOT_FEW_ENEMIES:
		var structure := game.enemies.march != null and game.enemies.march.seek_point(p, StanceData.BOT_STRUCTURE_RADIUS) != Vector2.INF
		if structure or _count_within(game, p, StanceData.BOT_SCREEN_RADIUS) <= StanceData.BOT_CLEAR_COUNT:
			return "onslaught"
	if game.stance.is_unlocked("spearhead"):
		var loot := game.chests.nearest_chest(p, StanceData.BOT_LOOT_RADIUS) != null \
				or game.powerups.nearest_drop(p, StanceData.BOT_LOOT_RADIUS) != null  # Something worth a push.
		if loot:
			return "spearhead"
	return "escort"


## Living enemies within `r` px of `p`.
func _count_within(game: Game, p: Vector2, r: float) -> int:
	game.enemy_grid.query(p, r, _tmp)
	var n := 0
	for e: Enemy in _tmp:
		if e.active and e.position.distance_squared_to(p) <= r * r:
			n += 1
	return n
