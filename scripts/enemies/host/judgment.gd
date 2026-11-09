## Judgment — JUDGMENT, the Celestial Host's headline rule (temporary Act XIII;
## GDD §15.0 "Judgment"; proposal: "A pair of scales on the HUD weighs the
## necromancer's sins. Every corpse he raises and every summon he replaces adds
## weight. At each third, a Judge descends: an elite angel who goes for the
## necromancer himself. When the scales are full, the Verdict: a pillar of
## light falls on the necromancer every 5 s for 20 s, then the scales reset.
## Killing Judges lightens them. One path, like Act II's DreadMeter but read as
## a summons, never as damage taken"), owned by Game.host as `judgment`.
##   * add(): THE ONE WRITE of the weight. The sins: on_raise() (from
##     HordeDirector.raise_corpse(), every raise of a corpse) and on_replace()
##     (from the horde's replacement timer, every summon replaced after it
##     fell); fill() (the Last Trumpet: the scales full at once); phase 2's
##     bosses (Seraiel's Trial) call add() too.
##   * THE THIRDS: crossing each JUDGMENT "thirds" share sends judges_per_third
##     Judges (send_judges(): HostEnemyData "judge", landing judge_distance px
##     from each standing necromancer at a seeded angle), once a cycle (a
##     third is not sent again until the scales reset). on_judge_died() takes
##     judge_lighten off.
##   * THE VERDICT (full): for verdict_duration s, every verdict_every s a
##     pillar falls on each standing necromancer: a ring for pillar_warn s at
##     the spot he stood, then the pillar: pillar_player_damage to a
##     necromancer still inside (Grave Step's i-frames dodge it),
##     pillar_summon_damage to every summon inside (x the time scaling); no
##     sin is weighed while it runs; then the scales reset to empty.
## The weight is never read as damage taken: it only summons Judges and the
## Verdict. Off a Host stage (a forced Host kind) the scales stay empty
## (`enabled` false). The HUD shows it through JudgmentBar (a bar and a line,
## never a screen effect). Drawn: the pillars' rings and columns (textures and
## rects), z 15. Determinism: game time and the seeded gameplay RNG (the
## Judges' angles), only on a Host stage.
class_name Judgment
extends Node2D

## Owning run.
var game: Game
## True on a Host stage (the scales weigh); false for a forced Host kind elsewhere.
var enabled: bool = false
## Judgment's numbers (HostRulesData.JUDGMENT, the stage's "judgment" over it).
var cfg: Dictionary = {}
## The weight on the scales now (0..capacity).
var weight: float = 0.0
## Thirds crossed in this cycle (0..thirds.size()).
var thirds_passed: int = 0
## Game time (s) the running Verdict ends (-1 = none running).
var verdict_until: float = -1.0
## Game time (s) of the Verdict's next pillar.
var _next_pillar: float = INF
## Live pillars: [centre (Vector2), game time it falls, fallen (bool)].
var pillars: Array = []
## Corpses raised this run (each a sin).
var raised: int = 0
## Summons replaced this run (each a sin).
var replaced: int = 0
## Judges sent / slain this run.
var judges_sent: int = 0
## Judges killed this run (each lightened the scales).
var judges_slain: int = 0
## Verdicts this run (each a full scales).
var verdicts: int = 0
## Game times (s) each Verdict began (the report).
var verdict_times: PackedStringArray = PackedStringArray()
## Pillars fallen this run.
var pillars_fallen: int = 0
## Highest weight this run.
var peak: float = 0.0
## Sins refused while a Verdict ran (not weighed).
var refused: int = 0
## The HUD widget (created on the first step that has a HUD).
var _bar: JudgmentBar = null
## True when this build draws (never headless).
var _draws: bool = false
## True while the last redraw showed a pillar (one more redraw clears it).
var _drawn_any: bool = false
## Ally query buffer.
var _tmp: Array = []


## Builds the scales for `p_game`; `p_enabled`: a Host stage.
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	name = "Judgment"
	z_index = 15  # Over the units; under the Light's shafts.
	z_as_relative = false
	enabled = p_enabled
	cfg = HostRulesData.JUDGMENT.duplicate()
	var over: Dictionary = p_game.stage_def.get("judgment", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	_draws = DisplayServer.get_name() != "headless"


## The weight as a share of the capacity (0..1; the HUD).
func share() -> float:
	return clampf(weight / maxf(float(cfg["capacity"]), 0.01), 0.0, 1.0)


## True while the Verdict runs.
func verdict_running() -> bool:
	return verdict_until >= 0.0


## A corpse was raised (HordeDirector.raise_corpse()): a sin (x Absolution,
## HostRules.absolution_mult(): exactly 1 until phase 2 builds it).
func on_raise() -> void:
	if add(float(cfg["raise_weight"]) * game.host.absolution_mult()):
		raised += 1


## A summon was replaced after it fell (HordeDirector's replacement timer): a sin.
func on_replace() -> void:
	if add(float(cfg["replace_weight"]) * game.host.absolution_mult()):
		replaced += 1


## THE ONE WRITE: `amount` weight on the scales (false when not weighed: off
## a Host stage, before JUDGMENT start, or while a Verdict runs). Crossing a
## third sends Judges; reaching the capacity begins the Verdict.
func add(amount: float) -> bool:
	if not enabled or game.elapsed < float(cfg["start"]):
		return false
	if verdict_running():
		refused += 1
		return false
	weight = minf(weight + amount, float(cfg["capacity"]))
	peak = maxf(peak, weight)
	var thirds: Array = cfg["thirds"]
	while thirds_passed < thirds.size() and share() >= float(thirds[thirds_passed]):
		thirds_passed += 1
		send_judges()
	if weight >= float(cfg["capacity"]):
		_begin_verdict()
	return true


## The Last Trumpet (LastTrumpet): the scales full at once (a Verdict that
## runs already is lengthened instead).
func fill() -> void:
	if not enabled:
		return
	if verdict_running():
		verdict_until = maxf(verdict_until, game.elapsed + float(cfg["verdict_duration"]))
		return
	weight = float(cfg["capacity"])
	peak = weight
	_begin_verdict()


## A Judge was killed (JudgeKit.on_killed()): the scales lighten (a third
## already sent stays sent: no second Judge for it until the scales reset).
func on_judge_died(e: Enemy) -> void:
	judges_slain += 1
	if not enabled or verdict_running():
		return
	weight = maxf(0.0, weight - float(cfg["judge_lighten"]))
	game.host.play_sound("judge_slain", e.position, 0.2)


## Sends judges_per_third Judges at every standing necromancer, each landing
## judge_distance px from him at a seeded angle (the gameplay RNG).
func send_judges() -> void:
	var kind := String(cfg["judge_kind"])
	for pl in game.all_players:
		if pl.dead:
			continue
		for i in int(cfg["judges_per_third"]):
			var at := pl.position + Vector2.from_angle(randf() * TAU) * float(cfg["judge_distance"])
			if game.enemies.spawn_at(kind, game.arena.free_point(at, 12.0), false) != null:
				judges_sent += 1
				game.stat_add("judges_sent", 1.0)
	game.enemies.show_banner("The scales tip: a Judge descends for you!")
	game.host.play_sound("judge_descend", game.player.position, 0.5)


## The scales are full: the Verdict begins.
func _begin_verdict() -> void:
	verdicts += 1
	verdict_times.append(EmpireReport._clock(game.elapsed))
	verdict_until = game.elapsed + float(cfg["verdict_duration"])
	_next_pillar = game.elapsed
	game.enemies.show_banner("THE VERDICT: the light falls on you!")
	game.host.play_sound("verdict", game.player.position, 1.0)


## Per tick (HostRules.step()): the Verdict's pillars, its end, the HUD bar.
func step(_delta: float) -> void:
	if not enabled:
		return
	var now := game.elapsed
	if game.hud != null:
		if _bar == null:
			_bar = JudgmentBar.new()
			_bar.setup(game, self)
			game.hud.add_child(_bar)
		_bar.refresh()
	if verdict_running():
		if now >= _next_pillar and now < verdict_until:
			_next_pillar = now + float(cfg["verdict_every"])
			for pl in game.all_players:
				if not pl.dead:
					pillars.append([pl.position, now + float(cfg["pillar_warn"]), false])
		if now >= verdict_until and pillars.is_empty():
			verdict_until = -1.0
			weight = 0.0
			thirds_passed = 0
			game.stat_add("judgment_resets", 1.0)
	var i := pillars.size() - 1
	while i >= 0:
		var p: Array = pillars[i]
		if not bool(p[2]) and now >= float(p[1]):
			p[2] = true
			_fall(p[0])
		if now >= float(p[1]) + float(cfg["pillar_show"]):
			pillars.remove_at(i)
		i -= 1
	if _draws and (not pillars.is_empty() or _drawn_any):
		_drawn_any = not pillars.is_empty()
		queue_redraw()


## A pillar falls at `c`: the necromancers and the summons inside are struck.
func _fall(c: Vector2) -> void:
	pillars_fallen += 1
	var r := float(cfg["pillar_radius"])
	var ts := game.enemies.damage_mult  # The time scaling (and the difficulty).
	game.host.play_sound("pillar_fall", c, 0.2)
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(c) <= r + pl.radius:
			game.combat.damage_player(float(cfg["pillar_player_damage"]) * ts, HostRulesData.VERDICT_SOURCE, pl)
			game.stat_add("verdict_player_hits", 1.0)
	game.ally_grid.query(c, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(c) > r + u.radius:
			continue
		game.combat.damage_unit(u, float(cfg["pillar_summon_damage"]) * ts, HostRulesData.VERDICT_SOURCE)
		game.stat_add("verdict_summon_hits", 1.0)


## The autotest autopilot's push out of every pillar's ring that has not fallen.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var r := float(cfg["pillar_radius"]) + 26.0
	for pi in pillars:
		if bool(pi[2]):
			continue
		var off: Vector2 = p - (pi[0] as Vector2)
		var d := off.length()
		if d < r:
			push += (off / d if d > 0.01 else Vector2.RIGHT) * (1.0 - d / r) * 1.5
	return push


## Every pillar: a starlight ring that tightens while it warns, then a white
## column of light (disc textures and rects only).
func _draw() -> void:
	var now := game.elapsed
	var r := float(cfg["pillar_radius"])
	for p in pillars:
		var c: Vector2 = p[0]
		var fall := float(p[1])
		if not bool(p[2]):
			var k := clampf(1.0 - (fall - now) / maxf(float(cfg["pillar_warn"]), 0.01), 0.0, 1.0)
			draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(r, r * 0.5), Vector2(r * 2.0, r)), false, Color(Palette.HOST_CERULEAN, 0.12 + 0.2 * k))
			var ri := r * (1.0 - 0.6 * k)
			draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(ri, ri * 0.5), Vector2(ri * 2.0, ri)), false, Color(Palette.HOST_STARLIGHT, 0.18 + 0.3 * k))
		else:
			var a := clampf(1.0 - (now - fall) / maxf(float(cfg["pillar_show"]), 0.01), 0.0, 1.0)
			draw_rect(Rect2(c - Vector2(r * 0.6, 420.0), Vector2(r * 1.2, 420.0)), Color(Palette.HOST_STARLIGHT, 0.55 * a))
			draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(r, r * 0.5), Vector2(r * 2.0, r)), false, Color(Palette.HOST_STARLIGHT, 0.7 * a))
