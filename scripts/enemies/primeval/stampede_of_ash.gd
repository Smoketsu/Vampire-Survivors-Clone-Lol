## StampedeOfAsh — THE STAMPEDE OF ASH, the Reckoning of the Age of Titans'
## first two stages (temporary Act XIV; GDD §15.0 "The Stampede of Ash";
## owner-approved proposal: "at 0:00 the sky burns. Every herd stampedes at
## once from every side, volcanic bombs fall on telegraphed circles, packs
## double and Tyrants roam"), owned by Game.primeval as `ash`. On a stage whose
## RECKONING has a "stampede_of_ash" dictionary (its keys override
## PrimevalRulesData.ASH; absent = off), from 0:00 (`first` s after it):
##   * HERDS FROM EVERY SIDE: every `stampede_every` s a herd of
##     `stampede_size` beasts comes on `stampede_ring` px from each standing
##     necromancer at a seeded side and stampedes at him at once
##     (Herds.spawn_herd(..., launch): over the herd cap; the dust line, the
##     trample and the shelter are the Herds rule's own);
##   * VOLCANIC BOMBS: every `bomb_every` s, `bombs` circles per standing
##     necromancer within `bomb_spread` px of him; each lands after
##     `bomb_warn` s and hits every body inside `bomb_radius` px, both armies
##     (summons bomb_summon, the necromancer bomb_player, enemies
##     bomb_enemy_share of their max HP; bosses, minibosses, structures and
##     objectives spared);
## while the RECKONING's "kind" (the Tyrant) and its companions (doubled
## packs) are spawned by EnemyDirector like every Reckoning. Phase 2 replaces
## it on the Last Day with the Extinction. Determinism: game time and the
## seeded gameplay RNG (sides, bomb points), only on a Titans stage. Stats:
## ash_stampedes, ash_bombs, ash_bomb_summon_hits, ash_bomb_player_hits,
## ash_bomb_enemy_hits.
class_name StampedeOfAsh
extends RefCounted

## Owning run.
var game: Game
## The Stampede of Ash's numbers ({} = off on this stage).
var cfg: Dictionary = {}
## True once 0:00 passed and the sky burns.
var started: bool = false
## Game time (s) it began.
var started_at: float = 0.0
## Live bombs: [landing point (Vector2), game s it lands] each; a landed bomb
## stays (drawn) bomb_show s.
var bombs: Array = []
## Herds it brought this run.
var stampedes: int = 0
## Bombs that landed this run.
var bombs_landed: int = 0
## Game time (s) of the next stampede.
var _next_stampede: float = INF
## Game time (s) of the next bombs.
var _next_bombs: float = INF
## Stampedes brought so far (their kinds and sides cycle on it).
var _count: int = 0


## Builds the Stampede of Ash for `p_game`; `enabled`: a Titans stage.
func _init(p_game: Game, enabled: bool) -> void:
	game = p_game
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if enabled and r.has("stampede_of_ash"):
		cfg = PrimevalRulesData.ASH.duplicate()
		var over: Dictionary = r["stampede_of_ash"]
		for key: String in over:
			cfg[key] = over[key]


## True while the Stampede of Ash runs (after 0:00 on a stage that has it).
func running() -> bool:
	return started


## Per tick (PrimevalRules.step()).
func step(_delta: float) -> void:
	if cfg.is_empty():
		return
	var now := game.elapsed
	if not started:
		if game.countdown_finished():
			started = true
			started_at = now
			_next_stampede = now + float(cfg["first"])
			_next_bombs = now + float(cfg["first"])
			game.primeval.play_sound("ash_stampede", game.player.position, 1.0)
		return
	if now >= _next_stampede:
		_next_stampede = now + float(cfg["stampede_every"])
		_stampede()
	if now >= _next_bombs:
		_next_bombs = now + float(cfg["bomb_every"])
		_throw()
	var i := bombs.size() - 1
	while i >= 0:
		var b: Array = bombs[i]
		var lands := float(b[1])
		if now >= lands and b.size() == 2:
			_land(b[0])
			b.append(true)  # Landed (drawn as a burst until bomb_show passes).
		if now >= lands + float(cfg["bomb_show"]):
			bombs.remove_at(i)
		i -= 1


## A herd from a seeded side of each standing necromancer, launched at him.
func _stampede() -> void:
	var kinds: Array = cfg["stampede_kinds"]
	var a0 := randf() * TAU
	for pl in game.all_players:
		if pl.dead:
			continue
		var at := pl.position + Vector2.from_angle(a0) * float(cfg["stampede_ring"])
		var list: Array = []
		for k in int(cfg["stampede_size"]):
			list.append(kinds[(_count + k) % kinds.size()])
		var h := game.primeval.herds.spawn_herd(at, list.size(), list, pl.position)
		if not h.members.is_empty():
			stampedes += 1
			game.stat_add("ash_stampedes", 1.0)
	_count += 1


## The bombs' circles round each standing necromancer.
func _throw() -> void:
	var spread := float(cfg["bomb_spread"])
	for pl in game.all_players:
		if pl.dead:
			continue
		for _k in int(cfg["bombs"]):
			var at := pl.position + Vector2.from_angle(randf() * TAU) * spread * sqrt(randf())
			bombs.append([at, game.elapsed + float(cfg["bomb_warn"])])
	game.primeval.play_sound("bomb_warn", game.player.position, 0.8)


## A bomb lands at `at` (see the header).
func _land(at: Vector2) -> void:
	bombs_landed += 1
	game.stat_add("ash_bombs", 1.0)
	var r := float(cfg["bomb_radius"])
	var ts := game.enemies.damage_mult  # The time scaling (and the difficulty).
	for hd in game.all_hordes:
		for u in hd.units:
			if u.active and u.state != SummonedUnit.State.SPAWNING and not u.airborne and u.position.distance_to(at) <= r + u.radius:
				game.combat.damage_unit(u, float(cfg["bomb_summon"]) * ts * game.primeval.thick_marrow_mult(), PrimevalRulesData.BOMB_SOURCE)
				game.stat_add("ash_bomb_summon_hits", 1.0)
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(at) <= r + pl.radius:
			game.combat.damage_player(float(cfg["bomb_player"]) * ts, PrimevalRulesData.BOMB_SOURCE, pl)
			game.stat_add("ash_bomb_player_hits", 1.0)
	for e in game.enemies.active:
		if e.active and not e.is_boss and not e.is_miniboss and not e.is_structure and not e.is_objective \
				and e.position.distance_to(at) <= r + e.radius:
			game.combat.damage_enemy(e, e.max_hp * float(cfg["bomb_enemy_share"]), PrimevalRulesData.BOMB_SOURCE)
			game.stat_add("ash_bomb_enemy_hits", 1.0)
	game.primeval.play_sound("bomb_land", at, 0.2)


## The autotest autopilot's push out of every bomb circle at `p`.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var r := float(cfg.get("bomb_radius", 0.0)) + 24.0
	for b: Array in bombs:
		if b.size() > 2:
			continue
		var rel := p - (b[0] as Vector2)
		if rel.length() < r:
			push += (rel.normalized() if rel.length() > 0.5 else Vector2.RIGHT) * 1.5
	return push


## True while a bomb shows (PrimevalRules redraws).
func showing() -> bool:
	return not bombs.is_empty()


## Draws every bomb on `ci` (PrimevalRules' layer): a filling circle, then a
## burst (disc textures only).
func draw(ci: CanvasItem) -> void:
	var r := float(cfg.get("bomb_radius", 0.0))
	var warn := maxf(0.01, float(cfg.get("bomb_warn", 1.0)))
	for b: Array in bombs:
		var at: Vector2 = b[0]
		if b.size() > 2:
			SpriteBank.draw_disc(ci, at, r, Color(Palette.PRIMEVAL_LAVA, 0.55))
			continue
		var k := clampf(1.0 - (float(b[1]) - game.elapsed) / warn, 0.0, 1.0)  # 0 -> 1 as it falls.
		SpriteBank.draw_disc(ci, at, r, Color(Palette.PRIMEVAL_LAVA, 0.14))
		SpriteBank.draw_disc(ci, at, r * k, Color(Palette.PRIMEVAL_LAVA, 0.3))
