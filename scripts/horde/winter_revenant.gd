## WinterRevenant — runtime of the Winter Revenant summon evolution (Frost
## Wraith Lv 5 + Soul Recycling Lv 5; owner-approved). Owned by
## SummonEvolutions (`winter`); numbers in SummonEvolutionData.EVOLUTIONS
## ["winter_revenant"]. The evolution's stat overlay (HP, damage, size and the
## +35% Deep Freeze radius through "special_mult") goes through the ONE
## summon-stat path (SummonEvolutions.modify_stats()); FrostWraithBehavior
## keeps running the frost bolts and the Deep Freeze. This file adds:
##   * Shatter (on_enemy_killed(), the CombatResolver kill hook): an enemy
##     that dies while Deep-Frozen (Enemy.freeze_timer > 0; a Stasis power-up
##     freeze does not count, bosses and Crimson March structures never
##     shatter) splashes damage_fraction of ITS max HP onto every enemy within
##     the shatter radius (source "winter_revenant_shatter") and chills the
##     survivors (CombatResolver.chill_enemy()).
##     Chain guard: a shatter never triggers another shatter. Kills dealt by
##     shatter damage do not shatter, and neither does any kill made while a
##     shatter is resolving (on-kill effects such as a Soul Rapture burst that
##     land inside it), via the `_resolving` flag. On top of that at most
##     max_per_frame shatters resolve per physics tick (perf cap; the rest are
##     skipped and counted in wr_shatters_capped).
##   * Death nova (HordeDirector.summon_died): a Winter Revenant that dies
##     (not a temporary summon, not a unit dissolved without a death) releases
##     a freezing nova: damage_mult x its frost-bolt damage to every enemy in
##     the nova radius (source "winter_revenant_nova"), then a Deep Freeze of
##     freeze_duration s on the survivors (CombatResolver.freeze_enemy(): boss
##     / elite multipliers of the class, Reckoning enemies immune). Enemies the
##     nova kills while already frozen shatter as usual. Soul Recycling brings
##     the Revenant back quickly, so every death is a freeze bomb.
## Everything goes through CombatResolver (damage, chill, freeze) and is
## deterministic: no RNG; the per-tick cap keys on game.elapsed.
## Stats: wr_shatters, wr_shatters_capped, wr_shatter_hits, wr_novas,
## wr_nova_hits, wr_nova_freezes, dmg_winter_revenant_shatter,
## dmg_winter_revenant_nova (summary_line() for the autotest).
class_name WinterRevenant
extends RefCounted

## Evolution id of this kit (SummonEvolutionData key).
const ID: String = "winter_revenant"
## Damage-source tag of a shatter splash (CombatResolver stats).
const SRC_SHATTER: String = "winter_revenant_shatter"
## Damage-source tag of a death nova (CombatResolver stats).
const SRC_NOVA: String = "winter_revenant_nova"

## Owning horde director (a Node: holding it instead of the SummonEvolutions
## that owns this object avoids a RefCounted reference cycle).
var director: HordeDirector
## True while a shatter is resolving (re-entrancy / chain guard).
var _resolving: bool = false
## game.elapsed (s) of the tick the shatter count below belongs to.
var _frame_time: float = -1.0
## Shatters resolved during the tick at _frame_time (0..max_per_frame).
var _frame_shatters: int = 0
## Reusable enemy query buffer of the shatter.
var _shatter_buf: Array = []
## Reusable enemy query buffer of the death nova (separate from the shatter
## buffer: a nova kill may shatter while the nova loop is still running).
var _nova_buf: Array = []


func _init(p_director: HordeDirector) -> void:
	director = p_director
	director.summon_died.connect(_on_summon_died)


## True once the Winter Revenant evolution has been granted this run.
func is_active() -> bool:
	return director.evolutions.done.has(ID)


# =====================================================================================
# Shatter (CombatResolver kill hook, through SummonEvolutions.on_enemy_killed)
# =====================================================================================

## Kill hook, called before the enemy `e` is removed (it is still active with
## hp <= 0). Shatters it if it was Deep-Frozen (see the header for the rules).
func on_enemy_killed(e: Enemy, source: String) -> void:
	if not is_active() or _resolving or source == SRC_SHATTER:
		return  # Not evolved, or a kill inside / by a shatter (no chains).
	if e.freeze_timer <= 0.0 or e.is_boss or e.is_structure:
		return
	var game := director.game
	var def: Dictionary = SummonEvolutionData.EVOLUTIONS[ID]["shatter"]
	if game.elapsed != _frame_time:
		_frame_time = game.elapsed
		_frame_shatters = 0
	if _frame_shatters >= int(def["max_per_frame"]):
		game.stat_add("wr_shatters_capped", 1.0)
		return
	_frame_shatters += 1
	_resolving = true
	var r := float(def["radius"])  # Splash radius (px).
	var dmg := e.max_hp * float(def["damage_fraction"])  # Damage to each enemy hit.
	var slow := float(def["chill_slow"])  # Chill slow fraction.
	var chill := float(def["chill_duration"])  # Chill time (s).
	var at := e.position  # Shatter centre.
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, _shatter_buf)
	for o: Enemy in _shatter_buf:
		if o == e or not o.active or o.position.distance_to(at) > r + o.radius * 0.5:
			continue
		game.combat.damage_enemy(o, dmg, SRC_SHATTER)
		game.stat_add("wr_shatter_hits", 1.0)
		if o.active and o.hp > 0.0:
			game.combat.chill_enemy(o, slow, chill)
	_resolving = false
	game.stat_add("wr_shatters", 1.0)
	game.effects.ring(at, r, SummonGlyphs.REVENANT_GLOW, 0.3, "frost_shatter")
	game.effects.ring(at, r * 0.45, PowerupGlyphs.ICE, 0.25)
	Juice.fx.burst(at, PowerupGlyphs.ICE, SummonGlyphs.REVENANT_GLOW, 6, r * 2.2, 0.4, 2.0)
	Sfx.play("frost_bolt", at)


# =====================================================================================
# Death nova (HordeDirector.summon_died)
# =====================================================================================

## A summon died (it is already deactivated; its position, class, evolution
## and damage are kept). A Winter Revenant releases its freezing nova.
func _on_summon_died(u: SummonedUnit) -> void:
	if u.is_temporary or u.evolution != ID:
		return
	var game := director.game
	var def: Dictionary = SummonEvolutionData.EVOLUTIONS[ID]["nova"]
	var r := float(def["radius"])  # Nova radius (px).
	var dmg := u.damage * float(def["damage_mult"])  # Damage to each enemy hit.
	var dur := float(def["freeze_duration"])  # Freeze time (s) before boss / elite multipliers.
	var boss_mult := float(u.special.get("freeze_boss_mult", 0.2))  # Class boss freeze multiplier.
	var elite_mult := float(u.special.get("freeze_elite_mult", 0.6))  # Class elite freeze multiplier.
	var at := u.position  # Nova centre.
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, _nova_buf)
	for e: Enemy in _nova_buf:
		if not e.active or e.position.distance_to(at) > r + e.radius * 0.5:
			continue
		game.combat.damage_enemy(e, dmg, SRC_NOVA)
		game.stat_add("wr_nova_hits", 1.0)
		if e.active and e.hp > 0.0 and game.combat.freeze_enemy(e, dur, boss_mult, elite_mult) > 0.0:
			game.stat_add("wr_nova_freezes", 1.0)
	game.stat_add("wr_novas", 1.0)
	game.effects.ring(at, r, SummonGlyphs.REVENANT_GLOW, 0.45, "frost_nova")
	game.effects.ring(at, r * 0.6, Palette.COLD_BLUE, 0.55)
	Juice.fx.burst(at, PowerupGlyphs.ICE, Palette.COLD_BLUE, 14, r * 1.8, 0.6, 2.5)
	Sfx.play("deep_freeze", at)


# =====================================================================================
# Card and autotest helpers
# =====================================================================================

## Evolution-card lines (SummonEvolutions.build_offer) from the current
## stats `cur` and the evolved preview `nxt` of the Frost Wraith class.
static func offer_lines(deltas: PackedStringArray, cur: Dictionary, nxt: Dictionary, def: Dictionary) -> void:
	var a: Dictionary = cur.get("special", {})  # Current special numbers.
	var b: Dictionary = nxt.get("special", {})  # Evolved special numbers.
	if a.has("freeze_radius") and b.has("freeze_radius"):
		SummonEvolutions._delta(deltas, "Deep Freeze radius", a["freeze_radius"], b["freeze_radius"])
	if def.has("shatter"):
		var s: Dictionary = def["shatter"]
		deltas.append("NEW  Shatter: frozen foes that die burst for %d%% of their max HP within %s px" % [
				int(roundf(float(s["damage_fraction"]) * 100.0)), AbilityManager._fmt(s["radius"])])
	if def.has("nova"):
		var n: Dictionary = def["nova"]
		deltas.append("NEW  Death nova: %s dmg + %ss freeze within %s px" % [
				AbilityManager._fmt(float(nxt["damage"]) * float(n["damage_mult"])), AbilityManager._fmt(n["freeze_duration"]),
				AbilityManager._fmt(n["radius"])])


## One autotest summary line from the run statistics `st`.
static func summary_line(st: Dictionary) -> String:
	return "shatters %d (capped %d), shatter hits %d, shatter dmg %d | death novas %d, nova hits %d, nova freezes %d, nova dmg %d" % [
			int(st.get("wr_shatters", 0.0)), int(st.get("wr_shatters_capped", 0.0)), int(st.get("wr_shatter_hits", 0.0)),
			int(st.get("dmg_" + SRC_SHATTER, 0.0)), int(st.get("wr_novas", 0.0)), int(st.get("wr_nova_hits", 0.0)),
			int(st.get("wr_nova_freezes", 0.0)), int(st.get("dmg_" + SRC_NOVA, 0.0))]
