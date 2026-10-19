## RunRewards — the few counters ONE run keeps for the content-wave-2
## achievements (owner-approved Proposal 2, GDD §15.0 "Achievement rewards
## (content wave 2)"; owned by Game as `game.rewards`). It only READS the run
## (no RNG, no gameplay state is changed), so runs stay deterministic, and it
## writes its results into the run's stats, which MetaProgress.award_run()
## turns into lifetime counters and achievements:
##   * rw_min_hp_frac — the lowest share of max HP the necromancer was left
##     at by a hit before 0:00 (0..1; 1 = never hit; 0 = a killing hit, even
##     one Undying Will or the autotest's immortality survived). Fed by
##     CombatResolver.damage_player() through note_player_hit() (Untouchable),
##   * rw_boss_kill_secs — game seconds from the stage boss's arrival
##     (EnemyDirector.boss_spawned) to its death (boss_defeated); absent
##     when the boss did not fall (Swift Judgment),
##   * rw_temp_raised — temporary undead raised this run (Raise Dead, Death
##     Mark, Lich raises, Grave Tide...: HordeDirector.temp_spawned, the ONE
##     spawn_temporary() counter), written by write_stats() at the run's end
##     (Mass Grave).
## Full Ossuary reads the existing "evolutions" stat (spell and summon
## evolutions; they are never lost in a run, so the count at the end is the
## most held at once). Deathlord's Due reads the summary's difficulty.
class_name RunRewards
extends RefCounted

## The run.
var game: Game = null
## Lowest max-HP share left by a hit before 0:00 (0..1; 1 = untouched).
var min_hp_frac: float = 1.0
## Game second the stage boss arrived (-1 = not yet).
var boss_arrived_at: float = -1.0


func _init(p_game: Game) -> void:
	game = p_game
	game.enemies.boss_spawned.connect(_on_boss_spawned)
	game.enemies.boss_defeated.connect(_on_boss_defeated)


## CombatResolver.damage_player(): a hit took `lost` HP from `hp_before`
## (max HP `max_hp`). Counted only before 0:00.
func note_player_hit(hp_before: float, lost: float, max_hp: float) -> void:
	if lost <= 0.0 or max_hp <= 0.0 or game.countdown_finished():
		return
	var frac := clampf((hp_before - lost) / max_hp, 0.0, 1.0)  # HP share left by this hit.
	if frac < min_hp_frac:
		min_hp_frac = frac
		game.stats["rw_min_hp_frac"] = min_hp_frac


## The stage boss arrived: start the Swift Judgment clock.
func _on_boss_spawned(_boss: Boss) -> void:
	if boss_arrived_at < 0.0:
		boss_arrived_at = game.elapsed


## The stage boss fell: record how long it lasted after its arrival.
func _on_boss_defeated() -> void:
	if boss_arrived_at >= 0.0 and not game.stats.has("rw_boss_kill_secs"):
		game.stats["rw_boss_kill_secs"] = maxf(0.0, game.elapsed - boss_arrived_at)


## Game.end_run(), before the summary is built: the end-of-run counters.
func write_stats() -> void:
	game.stats["rw_temp_raised"] = float(game.horde.temp_spawned)
	game.stats["rw_min_hp_frac"] = min_hp_frac


## The autotest's rewards counters (one line's middle part).
func summary_text(st: Dictionary) -> String:
	return "temp raised %d, min HP before 0:00 %d%%, evolutions %d, boss slain %s after arrival" % [
		int(float(st.get("rw_temp_raised", 0.0))), roundi(float(st.get("rw_min_hp_frac", 1.0)) * 100.0),
		int(float(st.get("evolutions", 0.0))),
		("%.1f s" % float(st["rw_boss_kill_secs"])) if st.has("rw_boss_kill_secs") else "never"]
