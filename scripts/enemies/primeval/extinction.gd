## Extinction — THE EXTINCTION, the Last Day's own Reckoning (temporary Act XIV,
## the Age of Titans' finale; GDD §15.0 "The Extinction (the Last Day's
## Reckoning)"; owner-approved Option A: "at 0:00 the necromancer's meteor
## lands as the Reckoning: a 5 s white-out under a one-time ward, every enemy
## on the map dies, every corpse rises as a temporary Fossil Host, and the run
## ends in victory"; owner answer, Nov 9, 2026: it lasts 30 s, the Fossil
## Host's lifetime), owned by Game.primeval as `extinction`. On a stage whose
## RECKONING has an "extinction" dictionary (its keys override
## PrimevalRulesData.EXTINCTION; absent = off), once the countdown reaches 0:00:
##   1. THE FALL (`warn` s): the sky whites out (a ParagonSky: one additive
##      flat rect over the view, never a screen read), a shock ring spreads
##      from each standing necromancer every `ring_every` s, and every
##      necromancer stands under a ONE-TIME WARD (his i-frames held up, so
##      nothing hurts him until the impact).
##   2. THE IMPACT: every enemy on the map dies through the one kill path
##      (CombatResolver.damage_enemy(), source SOURCE: XP, kills and drops as
##      usual; a body no hit can reach is taken off the field without a kill,
##      EnemyDirector.despawn()). A stage boss still alive drops to
##      `boss_hp_share` of his max HP instead and, when his script has
##      on_extinction() (Old Gravejaw), lies broken out of reach: his spell
##      was for the one who slew him before the fall.
##   3. THE DEAD RISE: every corpse within `host_reach` px of a standing
##      necromancer (Enemy.leaves_corpse(), the one corpse gate), in the
##      field's order, rises for the nearest necromancer as a FOSSIL HOST
##      (HordeDirector.raise_corpse(): a temporary summon of an existing class
##      by the beast's group, `host_classes`, x host_hp_mult HP, `host_life`
##      s), at most `host_cap`.
##   4. VICTORY: `host_life` s after the impact the run ends in victory
##      (Game.end_run(true, END_REASON)). Dying at any point after 0:00 is a
##      victory anyway (the run structure).
## THE DAY THE SKY FELL (the act's achievement: "reach the Extinction with no
## summon lost"): at the impact, with an army raised this run and not one of
## the necromancers' own summons lost, the run stat DAY_THE_SKY_FELL_STAT is
## set (MetaProgress counts it; it only records the clear until the reorder).
## The 20:00 clock, the boss at 3:00 and "dying after 0:00 is a victory" stay.
## Summons get no rule of their own here: the Fossil Host is a temporary summon
## through the one raise path. Determinism: game time and the field's order
## only (no RNG). Stats: extinction_kills, extinction_despawned,
## extinction_host, extinction_host_capped, extinction_host_far,
## extinction_boss_hp, extinction_ended.
class_name Extinction
extends RefCounted

## Game.end_run() reason of a run the Extinction ended (FeedbackData words).
const END_REASON: String = "extinction"
## Run stat set (1) by a run that reached the impact with no summon lost (The
## Day the Sky Fell; MetaProgress counts it).
const DAY_THE_SKY_FELL_STAT: String = "last_day_sky_fell"

## Owning run.
var game: Game
## The Extinction's numbers ({} = off on this stage).
var cfg: Dictionary = {}
## True once 0:00 passed and the meteor falls.
var started: bool = false
## Game time (s) the fall began.
var started_at: float = 0.0
## True once the meteor struck.
var landed: bool = false
## Game time (s) of the impact (INF before).
var landed_at: float = INF
## Enemies the impact killed.
var killed: int = 0
## Fossil Host raised.
var raised: int = 0
## Max-HP share the boss was left on (-1 = no boss alive at the impact).
var boss_left: float = -1.0
## The white sky (null before the fall and headless).
var _sky: ParagonSky = null
## Game time (s) of the next shock ring.
var _next_ring: float = INF


## Builds the Extinction for `p_game`; `enabled`: a Titans stage.
func _init(p_game: Game, enabled: bool) -> void:
	game = p_game
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if enabled and r.has("extinction"):
		cfg = PrimevalRulesData.EXTINCTION.duplicate()
		var over: Dictionary = r["extinction"]
		for key: String in over:
			cfg[key] = over[key]


## True once the meteor began to fall (after 0:00 on a stage that has it).
func running() -> bool:
	return started


## True while the one-time ward holds (the fall, before the impact).
func warding() -> bool:
	return started and not landed


## Per tick (PrimevalRules.step()).
func step(_delta: float) -> void:
	if cfg.is_empty() or game.run_state == Game.RunState.ENDED:
		return
	var now := game.elapsed
	if not started:
		if game.countdown_finished():
			_begin(now)
		return
	if not landed:
		for pl in game.all_players:
			if not pl.dead:
				pl.iframes = maxf(pl.iframes, 0.25)  # THE ONE-TIME WARD (see the header).
		if now >= _next_ring:
			_next_ring = now + float(cfg["ring_every"])
			for pl in game.all_players:
				if not pl.dead:
					game.effects.ring(pl.position, float(cfg["ring_radius"]), Palette.PRIMEVAL_BONE, float(cfg["ring_every"]))
		if now >= started_at + float(cfg["warn"]):
			_impact(now)
		return
	if now >= landed_at + float(cfg["host_life"]):
		game.stat_add("extinction_ended", 1.0)
		if _sky != null:
			_sky.release()
		game.end_run(true, END_REASON)


## THE FALL begins (see the header).
func _begin(now: float) -> void:
	started = true
	started_at = now
	_next_ring = now
	game.stats["extinction_began_at"] = now
	if DisplayServer.get_name() != "headless":
		_sky = ParagonSky.new(game, null, float(cfg["warn"]), float(cfg["white_alpha"]))
		game.add_child(_sky)
	game.primeval.play_sound("extinction_fall", game.player.position, 1.0)


## THE IMPACT (see the header).
func _impact(now: float) -> void:
	landed = true
	landed_at = now
	var lost := 0  # Summons of the necromancers' own armies lost this run.
	for hd in game.all_hordes:
		lost += hd.total_deaths
	if lost == 0 and game.peak_army > 0:
		game.stats[DAY_THE_SKY_FELL_STAT] = 1.0
	var reach := float(cfg["host_reach"])
	var corpses: Array = []  # [position, group] of each body that leaves a corpse near a necromancer.
	for e: Enemy in game.enemies.active.duplicate():
		if not e.active:
			continue
		if e.is_boss:
			e.hp = minf(e.hp, e.max_hp * float(cfg["boss_hp_share"]))
			boss_left = e.hp / maxf(e.max_hp, 1.0)
			game.stats["extinction_boss_hp"] = boss_left
			if e.has_method("on_extinction"):
				e.call("on_extinction")
			continue
		var near := game.nearest_player(e.position)
		var corpse := e.leaves_corpse() and near != null and near.position.distance_to(e.position) <= reach
		var pos := e.position
		var grp := (e.kit as PrimevalKit).group() if e.kit is PrimevalKit else ""
		var gen := e.generation
		game.combat.damage_enemy(e, (e.hp + e.max_hp) * 100.0 / maxf(0.05, 1.0 - e.armor), PrimevalRulesData.EXTINCTION_SOURCE)
		if e.active and e.generation == gen:
			game.enemies.despawn(e)  # A body no hit reaches (submerged, haloed): gone without a kill.
			game.stat_add("extinction_despawned", 1.0)
		else:
			killed += 1
			game.stat_add("extinction_kills", 1.0)
		if corpse:
			corpses.append([pos, grp])
		elif e.leaves_corpse():
			game.stat_add("extinction_host_far", 1.0)
	_raise(corpses)
	for pl in game.all_players:
		if not pl.dead:
			game.effects.impact(pl.position, float(cfg["ring_radius"]) * 0.5, Palette.PRIMEVAL_LAVA)
	game.shake(Juice.MAX_SHAKE_PX)
	game.enemies.show_banner(String(cfg["impact_banner"]))
	game.primeval.play_sound("extinction_impact", game.player.position, 1.0)


## THE DEAD RISE: each corpse in `corpses` ([position, group]) rises for the
## nearest necromancer as a Fossil Host, at most host_cap.
func _raise(corpses: Array) -> void:
	var classes: Dictionary = cfg["host_classes"]
	var cap := int(cfg["host_cap"])
	for c: Array in corpses:
		if raised >= cap:
			game.stat_add("extinction_host_capped", 1.0)
			continue
		var at: Vector2 = c[0]
		var cls := String(classes.get(String(c[1]), classes[""]))
		var prev := -1
		if game.coop != null:
			prev = game.coop.bound
			game.coop.bind_nearest(at)
		var u := game.horde.raise_corpse(cls, at, float(cfg["host_life"]), float(cfg["host_hp_mult"]), float(cfg["host_dmg_mult"]),
				String(cfg["tag"]), "", false)
		if prev >= 0:
			game.coop.bind(prev)
		if u != null:
			raised += 1
			game.stat_add("extinction_host", 1.0)
			game.effects.ring(u.position, 20.0, Palette.PRIMEVAL_BONE, 0.5)
	game.primeval.play_sound("fossil_rise", game.player.position, 0.5)
