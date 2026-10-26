## StolenThunder — the Stolen Thunder spell (AbilityData "stolen_thunder"; Act
## IV, Mount Olympus; GDD §15.0 "Stolen Thunder, Titan's Blood and the
## Oathbreaker"; owner-approved proposal: "a charged bolt on the strongest enemy
## that chains to armoured foes"). Unlocked by slaying Zeus (UnlockData), then
## offered on every stage at the later-item card weight; driven by
## NecroSpellBook's one dispatch (OLYMPUS_IDS) with its EFFECTIVE stats
## (AbilityManager.spell_stats(): Soul Conduit, Abyssal Focus, Titan's Blood's
## thunder_chains / thunder_charge...).
##   * Every `cooldown` s (start to start) the stolen bolt CHARGES over the
##     necromancer for `thunder_charge` s (a crackling orb), then strikes the
##     STRONGEST foe within `range` px (the most HP left; bosses and the gods
##     count) for `damage`.
##   * The bolt then CHAINS hop by hop to the nearest ARMOURED foe not yet
##     struck within `chain_range` px (armour >= ARMOUR_MIN, flat armour, or
##     bronze-clad: the Republic's hoplites and heroes, Sentinels, Aegis Bots),
##     up to `thunder_chains` hops, each hop dealing `chain_falloff` less.
##     Armoured foes take `armour_bonus` more (the thunder melts bronze).
## Evolved into GIGANTOMACHY (EvolutionData "gigantomachy", detected by the
## "giants" key): the war of the giants. Each strike also hurls `giants` more
## bolts at the next strongest foes (each chaining the same way), and every
## hop cracks a THUNDERCLAP: `clap_share` of the hop's damage to every foe within
## `clap_radius` px (source "thunderclap").
## The Oathbreaker's innate Kinslayer: every Stolen Thunder hit on a boss, a
## miniboss (the gods) or a Hero deals thunder_divine_bonus more (CharacterData).
## Determinism: no RNG (targets by HP and distance, ties in the spatial hash's
## order; jag patterns from a counter). Stats: thunder_strikes, thunder_hops,
## thunder_armoured_hits, thunder_claps, kinslayer_hits; damage as
## dmg_stolen_thunder / dmg_gigantomachy / dmg_thunderclap.
class_name StolenThunder
extends NecroSpell

## One drawn lightning arc.
class Arc:
	extends RefCounted
	## Start (world px).
	var a: Vector2 = Vector2.ZERO
	## End (world px).
	var b: Vector2 = Vector2.ZERO
	## Seconds left visible.
	var time_left: float = 0.0
	## Jag pattern seed (a counter).
	var jag_seed: int = 0
	## True for the main bolt from the sky (drawn thicker).
	var sky: bool = false

## Seconds until the next charge may start.
var _timer: float = StolenThunderData.FIRST_CHARGE
## Seconds left of the running charge (< 0 = not charging).
var _charge_left: float = -1.0
## Length (s) of the running charge (drawing).
var _charge_len: float = 1.0
## Effective stats of the current cast (spell_stats()).
var _stats: Dictionary = {}
## Visible lightning arcs.
var _arcs: Array[Arc] = []
## Lightning casts so far (jag seeds).
var _jags: int = 0
## Enemies struck by the current strike (all its bolts), in order.
var _struck: Array[Enemy] = []
## Own query buffer of the target search.
var _cand: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false


func _ready() -> void:
	z_index = 3


## Charges on cooldown, strikes when charged, fades the arcs.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	if _charge_left >= 0.0:
		_charge_left -= delta
		if _charge_left < 0.0:
			_strike(stats)
	else:
		_timer -= delta
		if _timer <= 0.0:
			if _strongest(game.player.position, float(stats["range"]), []) != null:
				_timer = float(stats["cooldown"])
				_charge_len = maxf(0.05, float(stats["thunder_charge"]))
				_charge_left = _charge_len
				Sfx.play("bolt_cast", game.player.position, StolenThunderData.CHARGE_PITCH)  # The startup bank: the spell is offered on every stage.
			else:
				_timer = AbilityData.SPELL_RETRY
	var i := 0  # Index into _arcs (swap-remove).
	while i < _arcs.size():
		_arcs[i].time_left -= delta
		if _arcs[i].time_left > 0.0:
			i += 1
		else:
			_arcs[i] = _arcs[_arcs.size() - 1]
			_arcs.pop_back()
	var busy := _charge_left >= 0.0 or not _arcs.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## The charged bolt strikes the strongest foe in range (and, evolved, the next
## strongest ones), each chaining to armoured foes.
func _strike(stats: Dictionary) -> void:
	var p := game.player.position
	_struck.clear()
	var evolved := stats.has("giants")  # Gigantomachy.
	var bolts := 1 + (int(stats["giants"]) if evolved else 0)  # Bolts this strike.
	var src := StolenThunderData.EVOLVED_SOURCE if evolved else StolenThunderData.SOURCE
	var struck_any := false
	for b in bolts:
		var e := _strongest(p, float(stats["range"]), _struck)
		if e == null:
			break
		struck_any = true
		_add_arc(e.position + Vector2(0.0, -300.0), e.position, true)
		_bolt(e, float(stats["damage"]), stats, src, evolved)
	if struck_any:
		game.stat_add("thunder_strikes", 1.0)
		Sfx.play("mage_burst", p, StolenThunderData.STRIKE_PITCH)
		game.shake(2.0)


## One bolt: `first` takes `dmg`, then the chain hops to armoured foes.
func _bolt(first: Enemy, dmg: float, stats: Dictionary, src: String, evolved: bool) -> void:
	var e := first
	var hit := dmg
	var hops := int(stats["thunder_chains"])
	var falloff := float(stats["chain_falloff"])
	var reach := float(stats["chain_range"])
	for h in hops + 1:
		_struck.append(e)
		_hit(e, hit, stats, src)
		if evolved:
			_clap(e.position, hit * float(stats["clap_share"]), float(stats["clap_radius"]))
		if h >= hops:
			break
		var nxt := _armoured_near(e.position, reach)
		if nxt == null:
			break
		_add_arc(e.position, nxt.position, false)
		game.stat_add("thunder_hops", 1.0)
		hit *= 1.0 - falloff
		e = nxt


## One hit of the bolt on `e`: armoured foes take armour_bonus more, the
## Oathbreaker's Kinslayer more again on bosses, the gods and Heroes.
func _hit(e: Enemy, dmg: float, stats: Dictionary, src: String) -> void:
	if not e.active:
		return
	var d := dmg
	if StolenThunder.is_armoured(e):
		d *= 1.0 + float(stats["armour_bonus"])
		game.stat_add("thunder_armoured_hits", 1.0)
	var kin := game.character.innate_value(StolenThunderData.DIVINE_KEY)  # 0 unless the Oathbreaker.
	if kin > 0.0 and (e.is_boss or e.is_miniboss or (e.kit is PantheonKit and (e.kit as PantheonKit).is_hero())):
		d *= 1.0 + kin
		game.stat_add("kinslayer_hits", 1.0)
	game.combat.damage_enemy(e, d, src)


## Gigantomachy's thunderclap at `at`: `dmg` to every foe within `r` px.
func _clap(at: Vector2, dmg: float, r: float) -> void:
	damage_area(at, r, dmg, StolenThunderData.CLAP_SOURCE)
	game.stat_add("thunder_claps", 1.0)
	game.effects.ring(at, r, Palette.PANTHEON_AEGEAN_LIGHT, 0.2)


## The open foe with the most HP left within `reach` px of `p`, not in
## `skip`; null when none.
func _strongest(p: Vector2, reach: float, skip: Array) -> Enemy:
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var best: Enemy = null
	var best_hp := 0.0
	for e: Enemy in _cand:
		if not is_open_target(e) or e.untargetable or skip.has(e):
			continue
		if e.position.distance_to(p) > reach + e.radius:
			continue
		if e.hp > best_hp:
			best_hp = e.hp
			best = e
	return best


## The nearest armoured open foe within `reach` px of `from` not yet struck.
func _armoured_near(from: Vector2, reach: float) -> Enemy:
	game.enemy_grid.query(from, reach + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var best: Enemy = null
	var best_d := INF
	for e: Enemy in _cand:
		if not is_open_target(e) or e.untargetable or _struck.has(e) or not StolenThunder.is_armoured(e):
			continue
		var d := from.distance_to(e.position)
		if d <= reach + e.radius and d < best_d:
			best_d = d
			best = e
	return best


## True for an ARMOURED foe (the chain's prey): armour >= ARMOUR_MIN, flat
## armour, or bronze-clad.
static func is_armoured(e: Enemy) -> bool:
	if e.armor >= StolenThunderData.ARMOUR_MIN or e.flat_armor > 0.0:
		return true
	return e.kit is PantheonKit and (e.kit as PantheonKit).is_bronze()


## Records a drawn arc (the oldest goes beyond MAX_ARCS).
func _add_arc(a: Vector2, b: Vector2, sky: bool) -> void:
	if _arcs.size() >= StolenThunderData.MAX_ARCS:
		_arcs.remove_at(0)
	var arc := Arc.new()
	arc.a = a
	arc.b = b
	arc.time_left = StolenThunderData.ARC_TIME
	arc.jag_seed = _jags
	arc.sky = sky
	_jags += 1
	_arcs.append(arc)


## Autotest counters (OlympusReport's item line).
func summary_extra() -> String:
	var st := game.stats
	return "strikes=%d hops=%d armoured_hits=%d claps=%d kinslayer_hits=%d" % [int(st.get("thunder_strikes", 0.0)), int(st.get("thunder_hops", 0.0)),
		int(st.get("thunder_armoured_hits", 0.0)), int(st.get("thunder_claps", 0.0)), int(st.get("kinslayer_hits", 0.0))]


## The charging orb over the necromancer (white-blue sparks gathering) and
## the bolts and chains as jagged white-blue lines. Visual only.
func _draw() -> void:
	if game == null:
		return
	if _charge_left >= 0.0:
		var k := clampf(1.0 - _charge_left / _charge_len, 0.0, 1.0)  # 0 -> 1 as it charges.
		var c := caster_pos() + Vector2(0.0, -StolenThunderData.ORB_LIFT)
		draw_circle(c, 3.0 + 5.0 * k, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.35 + 0.4 * k))
		draw_circle(c, 1.5 + 2.5 * k, Palette.PANTHEON_MARBLE_LIGHT)
		for s in 4:
			var a := float(s) * TAU / 4.0 + k * 6.0
			draw_line(c + Vector2.from_angle(a) * (6.0 + 6.0 * k), c + Vector2.from_angle(a + 0.6) * (12.0 + 4.0 * k), Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.7), 1.0)
	for arc in _arcs:
		var fade := clampf(arc.time_left / StolenThunderData.ARC_TIME, 0.0, 1.0)
		var n := 7 if arc.sky else 5  # Zigzag segments.
		var side := (arc.b - arc.a).orthogonal().normalized()
		var prev := arc.a
		for s in range(1, n + 1):
			var q := arc.a.lerp(arc.b, float(s) / float(n))
			if s < n:
				q += side * (6.0 if (s + arc.jag_seed) % 2 == 0 else -6.0)
			draw_line(prev, q, Color(Palette.PANTHEON_AEGEAN_LIGHT, 0.8 * fade), 5.0 if arc.sky else 3.0)
			draw_line(prev, q, Color(Palette.PANTHEON_MARBLE_LIGHT, fade), 2.0 if arc.sky else 1.0)
			prev = q
