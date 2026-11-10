## MeteorCall — the METEOR CALL spell (AbilityData "meteor_call"; temporary Act
## XIV, the Last Day; GDD §15.0 "Meteor Call, Extinction Event, Cosmic Dust and
## the Skywatcher"; owner-approved proposal: "a telegraphed meteor lands on the
## densest group"). Unlocked by slaying Old Gravejaw before the impact
## (UnlockData), then offered on every stage; driven by NecroSpellBook's one
## dispatch (LAST_DAY_IDS, stepped only) with its EFFECTIVE stats
## (AbilityManager.spell_stats(): its "radius" widens with every spell-area
## modifier).
##   * Every `cooldown` s, once a foe stands within `range` px, it calls a
##     meteor on the DENSEST GROUP in reach (of the first AIM_SAMPLES foes, the
##     one with the most foes within AIM_RADIUS px): a soul-teal circle of
##     `radius` px shows for `delay` s, then the meteor strikes every foe
##     inside it once: `damage` through CombatResolver.damage_enemy() and a
##     knockback away from its centre. It never hurts the necromancer's own.
##   * Cosmic Dust (its paired passive, PassiveData "cosmic_dust", read only
##     here): x 1 + dust_bonus on the damage, + dust_radius px.
##   * The Skywatcher's Star Reader (CharacterData "meteor_radius_bonus"): x 1
##     + bonus on the radius (0 for every other character).
## Evolved into EXTINCTION EVENT (EvolutionData "extinction_event", detected
## by the "meteors" key): `meteors` meteors a cast, each on a distinct dense
## group (SPACING px apart; the densest first).
## Deterministic: no RNG; the foes in the spatial hash's order. Stats:
## meteor_call_casts, meteor_call_meteors, meteor_call_hits,
## meteor_call_innate_px; damage as dmg_meteor_call / dmg_extinction_event.
class_name MeteorCall
extends NecroSpell

## Seconds until the next cast may start.
var _cd: float = 0.0
## Meteors falling: [centre (Vector2), game s it strikes, radius (px)] each.
var _falling: Array = []
## Own query buffer (kill hooks may query the grid again).
var _cand: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false
## The last step's effective delay (s; for drawing).
var _delay: float = 0.8


func _ready() -> void:
	z_index = 3


## Casts on the cooldown; the meteors strike on their clocks.
func step(delta: float, stats: Dictionary) -> void:
	_delay = float(stats["delay"])
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var i := _falling.size() - 1
	while i >= 0:
		var m: Array = _falling[i]
		if game.elapsed >= float(m[1]):
			_strike(stats, m[0], float(m[2]))
			_falling.remove_at(i)
		i -= 1
	var busy := not _falling.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One cast: a meteor (or Extinction Event's several) on the densest groups in
## reach. Returns false when no foe is near (the spell then waits).
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # The necromancer.
	var reach := float(stats["range"])
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var picks: Array = []  # [count, position] of the aim candidates.
	var seen := 0
	for e: Enemy in _cand:
		if not e.active or e.untargetable or e.civilian or p.distance_to(e.position) - e.radius > reach:
			continue
		picks.append([count_enemies(e.position, MeteorCallData.AIM_RADIUS), e.position])
		seen += 1
		if seen >= MeteorCallData.AIM_SAMPLES:
			break
	if picks.is_empty():
		return false
	var bonus := game.character.innate_value(MeteorCallData.INNATE_KEY)
	var r := (float(stats["radius"]) + game.abilities.passive_value(MeteorCallData.COSMIC_DUST, MeteorCallData.RADIUS_KEY)) * (1.0 + bonus)
	var want := int(stats.get("meteors", 1))
	var chosen: Array[Vector2] = []
	while chosen.size() < want:
		var best_i := -1
		for k in picks.size():
			var at: Vector2 = picks[k][1]
			var free := true
			for c in chosen:
				if c.distance_to(at) < MeteorCallData.SPACING:
					free = false
					break
			if free and (best_i < 0 or int(picks[k][0]) > int(picks[best_i][0])):
				best_i = k
		if best_i < 0:
			break
		chosen.append(picks[best_i][1])
	for at in chosen:
		if _falling.size() >= MeteorCallData.MAX_FALLING:
			break
		_falling.append([at, game.elapsed + float(stats["delay"]), r])
		game.stat_add("meteor_call_meteors", 1.0)
	game.stat_add("meteor_call_casts", 1.0)
	if bonus > 0.0:
		game.stat_add("meteor_call_innate_px", float(stats["radius"]) * bonus)
	game.player.cast_motion(chosen[0])  # Engine motion: toward the call (visual only).
	Sfx.play("lance_cast", p, MeteorCallData.CAST_PITCH)  # A startup-bank sound: the spell plays on every stage.
	return true


## A meteor strikes at `at` (`r` px): every foe inside takes the damage once.
func _strike(stats: Dictionary, at: Vector2, r: float) -> void:
	var src := MeteorCallData.EVOLVED_SOURCE if stats.has("meteors") else MeteorCallData.SOURCE
	var dmg := float(stats["damage"]) * (1.0 + game.abilities.passive_value(MeteorCallData.COSMIC_DUST, MeteorCallData.DAMAGE_KEY))
	var near: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, near)
	for o: Enemy in near:
		if not o.active or o.untargetable or o.civilian or o.position.distance_to(at) > r + o.radius:
			continue
		var off := o.position - at
		game.combat.damage_enemy(o, dmg, src)
		game.stat_add("meteor_call_hits", 1.0)
		if o.active:
			o.knockback += (off.normalized() if off.length() > 0.5 else Vector2.RIGHT) * MeteorCallData.KNOCK / maxf(o.mass, 0.1)
	game.effects.impact(at, r, MeteorCallData.FIRE)
	if game.wild != null:
		game.wild.thickets.burn_at(at, r)  # Act XV: fire burns the thorn thickets back (Overgrowth's one burn hook).
	Sfx.play("abom_stomp", at, 0.7)  # A startup-bank sound.


## Autotest counters (LastDayReport's Meteor Call line).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d meteors=%d hits=%d innate_px=%d" % [int(st.get("meteor_call_casts", 0.0)), int(st.get("meteor_call_meteors", 0.0)),
		int(st.get("meteor_call_hits", 0.0)), int(st.get("meteor_call_innate_px", 0.0))]


## The falling meteors: a filling soul-teal circle and the stone coming down.
## Visual only: disc textures in world axes (the spell node sits at the origin).
func _draw() -> void:
	for m: Array in _falling:
		var at: Vector2 = m[0]
		var r := float(m[2])
		var k := clampf(1.0 - (float(m[1]) - game.elapsed) / maxf(_delay, 0.01), 0.0, 1.0)  # 0 -> 1 as it falls.
		SpriteBank.draw_disc(self, at, r, Color(MeteorCallData.FIRE, 0.12))
		SpriteBank.draw_disc(self, at, r * k, Color(MeteorCallData.FIRE, 0.22))
		var stone := at + Vector2(-1.0, -1.6) * r * (1.0 - k) * 2.0  # It comes down from the upper left.
		SpriteBank.draw_disc(self, stone, 6.0, Color(MeteorCallData.FIRE, 0.85))
		SpriteBank.draw_disc(self, stone, 3.0, MeteorCallData.CORE)
