## FirstSpring — THE FIRST SPRING, the World-Tree's ending and the campaign's
## (temporary Act XV; GDD §15.0 "The First Spring (the World-Tree's ending)";
## owner-approved proposal: "beaten, she does not die. She takes the
## necromancer's dead back into the soil and gives him the one claim left: the
## dead are planted, and in spring they rise to him. The campaign ends on the
## first spring"), owned by Game.wild as `first_spring` beside `returns`. On a
## stage whose RECKONING has a "first_spring" dictionary (its keys override
## WildRulesData.FIRST_SPRING; absent = off), once the countdown reaches 0:00
## AND the Green Mother was beaten before it (run stat GreenMotherData.
## BEATEN_STAT, set by BossGreenMother):
##   1. SPRING: the year is held at Spring (SeasonCycle.set_override()), the
##      blight is wiped (BloomField.wipe()) and Spring Returns never starts
##      (WildRules.step() skips it);
##   2. THE PLANTED DEAD RISE: `rise` temporary summons on a ring round each
##      standing necromancer, for him (HordeDirector.raise_corpse(), the one
##      raise path; co-op binds each one's slot);
##   3. VICTORY: `end_after` s later the run ends in victory (Game.end_run(true,
##      WildRulesData.FIRST_SPRING_END)). Dying after 0:00 is a victory anyway.
## The Reckoning's Treants still come (EnemyDirector), and the risen meet them.
## Summons get no rule of their own: the risen are temporary summons through
## the one raise path. Determinism: game time and positions only (no RNG).
## Stats: first_spring_risen, first_spring_ended.
class_name FirstSpring
extends RefCounted

## Owning run.
var game: Game
## The First Spring's numbers ({} = off on this stage).
var cfg: Dictionary = {}
## True once it began (0:00, the Green Mother beaten).
var started: bool = false
## Game time (s) it began.
var started_at: float = 0.0
## Planted dead risen.
var risen: int = 0


## Builds the First Spring for `p_game`; `enabled`: a Wild stage.
func _init(p_game: Game, enabled: bool) -> void:
	game = p_game
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if enabled and r.has("first_spring"):
		cfg = WildRulesData.FIRST_SPRING.duplicate()
		var over: Dictionary = r["first_spring"]
		for key: String in over:
			cfg[key] = over[key]


## True once the First Spring took the Reckoning's place.
func running() -> bool:
	return started


## Per tick (WildRules.step(), before Spring Returns).
func step(_delta: float) -> void:
	if cfg.is_empty() or game.run_state == Game.RunState.ENDED:
		return
	var now := game.elapsed
	if not started:
		if game.countdown_finished() and float(game.stats.get(GreenMotherData.BEATEN_STAT, 0.0)) > 0.0:
			_begin(now)
		return
	if now >= started_at + float(cfg["end_after"]):
		game.stat_add("first_spring_ended", 1.0)
		game.end_run(true, WildRulesData.FIRST_SPRING_END)


## Spring, the wipe and the rising (see the header).
func _begin(now: float) -> void:
	started = true
	started_at = now
	game.wild.seasons.set_override(WildRulesData.SPRING, now + float(cfg["end_after"]) + 60.0)
	game.wild.bloom.wipe()
	var n := maxi(1, int(cfg["rise"]))
	for i in game.all_players.size():
		var pl := game.all_players[i]
		if pl.dead:
			continue
		var prev := -1
		if game.coop != null:
			prev = game.coop.bound
			game.coop.bind(i)
		for k in n:
			var at := game.arena.free_point(pl.position + Vector2.from_angle(TAU * float(k) / float(n)) * float(cfg["ring"]), 10.0)
			if game.horde.raise_corpse(String(cfg["rise_class"]), at, float(cfg["life"]), float(cfg["rise_hp"]), float(cfg["rise_dmg"]),
					String(cfg["tag"]), "", false) != null:
				risen += 1
				game.stat_add("first_spring_risen", 1.0)
			game.effects.spawn_ring(at, GreenMotherData.BLOOM, "summon_rise")
		if prev >= 0:
			game.coop.bind(prev)
	game.enemies.show_banner(String(cfg["banner"]))
	game.wild.play_sound("spring_returns", game.player.position, 1.0)


## One autotest summary line ("" while it never began).
func summary_line() -> String:
	if not started:
		return ""
	return "began %s | planted dead risen %d | ended the run %s" % [EmpireReport._clock(started_at), risen,
		"yes" if float(game.stats.get("first_spring_ended", 0.0)) > 0.0 else "no"]
