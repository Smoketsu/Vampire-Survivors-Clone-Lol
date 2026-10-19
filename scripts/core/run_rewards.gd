## RunRewards — the few counters ONE run keeps for the content-wave-2
## achievements (owner-approved Proposal 2, GDD §15.0 "Achievement rewards
## (content wave 2)"; owned by Game as `game.rewards`). It only READS the run
## (no RNG, no gameplay state, not even the stats Dictionary is changed, so
## runs and their autotest summaries stay exactly as before). Game.build_summary()
## hands its counters() to MetaProgress.award_run() as summary "run_rewards",
## which turns them into lifetime counters and achievements:
##   * min_hp_frac — the lowest share of max HP the necromancer was left at by
##     a hit before 0:00 (0..1; 1 = never hit; 0 = a killing hit, even one
##     Undying Will or the autotest's immortality survived). Fed by
##     CombatResolver.damage_player() through note_player_hit() (Untouchable),
##   * boss_kill_secs — game seconds from the stage boss's arrival
##     (EnemyDirector.boss_spawned) to its death (boss_defeated); -1 when the
##     boss did not fall (Swift Judgment),
##   * temp_raised — temporary undead raised this run (Raise Dead, Death Mark,
##     Lich raises, Grave Tide...: HordeDirector.temp_spawned, the ONE
##     spawn_temporary() counter) (Mass Grave),
##   * evolutions — evolutions obtained, spell and summon (the "evolutions"
##     stat; they are never lost in a run, so the count at the end is the
##     most held at once) (Full Ossuary).
## Deathlord's Due reads the summary's difficulty and victory.
class_name RunRewards
extends RefCounted

## The run.
var game: Game = null
## Lowest max-HP share left by a hit before 0:00 (0..1; 1 = untouched).
var min_hp_frac: float = 1.0
## Game second the stage boss arrived (-1 = not yet).
var boss_arrived_at: float = -1.0
## Game seconds the stage boss lasted after arriving (-1 = it did not fall).
var boss_kill_secs: float = -1.0


func _init(p_game: Game) -> void:
	game = p_game
	game.enemies.boss_spawned.connect(_on_boss_spawned)
	game.enemies.boss_defeated.connect(_on_boss_defeated)


## CombatResolver.damage_player(): a hit took `lost` HP from `hp_before`
## (max HP `max_hp`). Counted only before 0:00.
func note_player_hit(hp_before: float, lost: float, max_hp: float) -> void:
	if lost <= 0.0 or max_hp <= 0.0 or game.countdown_finished():
		return
	min_hp_frac = minf(min_hp_frac, clampf((hp_before - lost) / max_hp, 0.0, 1.0))


## The stage boss arrived: start the Swift Judgment clock.
func _on_boss_spawned(_boss: Boss) -> void:
	if boss_arrived_at < 0.0:
		boss_arrived_at = game.elapsed


## The stage boss fell: record how long it lasted after its arrival.
func _on_boss_defeated() -> void:
	if boss_arrived_at >= 0.0 and boss_kill_secs < 0.0:
		boss_kill_secs = maxf(0.0, game.elapsed - boss_arrived_at)


## The run's counters (summary "run_rewards"; keys in the header).
func counters() -> Dictionary:
	return {
		"min_hp_frac": min_hp_frac,
		"boss_kill_secs": boss_kill_secs,
		"temp_raised": float(game.horde.temp_spawned),
		"evolutions": float(game.stats.get("evolutions", 0.0)),
	}


## The autotest's rewards counters (one line's middle part) from summary
## counters `c` (counters()).
static func summary_text(c: Dictionary) -> String:
	var secs := float(c.get("boss_kill_secs", -1.0))  # Boss lifetime after arrival (-1 = survived).
	return "temp raised %d, min HP before 0:00 %d%%, evolutions %d, boss slain %s after arrival" % [
		int(float(c.get("temp_raised", 0.0))), roundi(float(c.get("min_hp_frac", 1.0)) * 100.0),
		int(float(c.get("evolutions", 0.0))), ("%.1f s" % secs) if secs >= 0.0 else "never"]
