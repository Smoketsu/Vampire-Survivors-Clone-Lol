## SynergyManager — army synergies (GDD §6.3, numbers in SynergyData). Owned
## by HordeDirector, which calls evaluate() whenever a summon level changes and
## step() every tick. Activation is automatic (SynergyData header rule); on
## activation it announces the synergy on the HUD banner.
## Requirements (SynergyData): `requires` entries are class ids or arrays of
## class ids (any one of them); a class whose UnitData row lists `counts_as`
## (the Profane Bishop) satisfies those classes too. `distinct` counts real
## classes, so the Bishop counts once.
## Effects and where they are applied:
##   Shieldwall of the Damned  barrier HP on warriors (here; needs a living
##                             Warder or Bishop), absorbed in
##                             CombatResolver.damage_unit().
##   Volley of the Fallen      mage explosions mark enemies, archers deal bonus
##                             damage to marked ones (ProjectileManager).
##   March of the Deathless    move speed (HordeDirector.compute_stats) and
##                             regeneration (here).
##   The Unholy Host           attack speed (compute_stats), damage reduction
##                             (CombatResolver.damage_unit), aura drawn on
##                             every summon (SummonedUnit._draw).
class_name SynergyManager
extends RefCounted

## Seconds between Deathless regeneration ticks (heals are batched).
const REGEN_TICK: float = 1.0  # TUNING (not in GDD)

## Owning horde director.
var director: HordeDirector
## Synergy id -> true while active.
var active: Dictionary = {}
## "synergy_id@mm:ss" for every activation this run (summary / autotest).
var activation_log: PackedStringArray = PackedStringArray()
## Seconds until the next Shieldwall barrier refresh.
var _barrier_timer: float = 0.0
## Seconds accumulated toward the next Deathless regeneration tick.
var _regen_accum: float = 0.0


func _init(p_director: HordeDirector) -> void:
	director = p_director


## True while synergy `id` is active.
func is_active(id: String) -> bool:
	return active.has(id)


## Effect value `key` of synergy `id` while active, else 0.
func value(id: String, key: String) -> float:
	if not active.has(id):
		return 0.0
	return float(SynergyData.SYNERGIES[id][key])


## Active synergy ids in display order.
func active_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in SynergyData.ORDER:
		if active.has(id):
			out.append(id)
	return out


## Re-checks every synergy against the current summon levels. Newly active
## ones are announced; any change recomputes summon stats (move / attack
## speed) and redraws summons (Unholy Host aura).
func evaluate() -> void:
	var changed := false
	for id: String in SynergyData.ORDER:
		var now := requirements_met(id, director.class_levels)
		if now == active.has(id):
			continue
		changed = true
		if now:
			active[id] = true
			_on_activated(id)
		else:
			active.erase(id)
	if not changed:
		return
	director.recompute_all(director.capacity_snapshot())
	for u in director.units:
		u.queue_redraw()


## True if `levels` (class id -> summon level) meets synergy `id`.
static func requirements_met(id: String, levels: Dictionary) -> bool:
	var def: Dictionary = SynergyData.SYNERGIES[id]
	var distinct: int = def["distinct"]
	if distinct > 0:
		var n := 0
		for cls: String in UnitData.CLASS_ORDER:
			if int(levels.get(cls, 0)) >= SynergyData.MIN_CLASS_LEVEL:
				n += 1
		return n >= distinct
	return classes_met(def["requires"], levels, SynergyData.MIN_CLASS_LEVEL)


## True if every entry of `reqs` is owned at `min_level`+ in `levels`. An
## entry is a class id or an Array of class ids (any one of them). A class
## is also satisfied by any class whose UnitData row lists it in `counts_as`
## (the Profane Bishop stands in for the Mender and the Warder). Also used for
## the Dread Sovereign achievement (Game._on_boss_defeated).
static func classes_met(reqs: Array, levels: Dictionary, min_level: int) -> bool:
	for entry: Variant in reqs:
		var options: Array = entry if entry is Array else [entry]
		var ok := false
		for cls: String in options:
			ok = ok or class_level(cls, levels) >= min_level
		if not ok:
			return false
	return true


## Level at which class `cls` counts in `levels`: its own level, or the level
## of a class that `counts_as` it, whichever is higher.
static func class_level(cls: String, levels: Dictionary) -> int:
	var lvl := int(levels.get(cls, 0))
	for other: String in UnitData.CLASS_ORDER:
		var stands_in: Array = UnitData.UNITS[other].get("counts_as", [])
		if cls in stands_in:
			lvl = maxi(lvl, int(levels.get(other, 0)))
	return lvl


## Level-up card hint: names the synergies that raising `cls` to
## MIN_CLASS_LEVEL would activate ("" if none).
func unlock_hint(cls: String) -> String:
	var levels := director.class_levels.duplicate()
	levels[cls] = maxi(int(levels[cls]), SynergyData.MIN_CLASS_LEVEL)
	var names := PackedStringArray()
	for id: String in SynergyData.ORDER:
		if not active.has(id) and requirements_met(id, levels):
			names.append(String(SynergyData.SYNERGIES[id]["display_name"]))
	return "" if names.is_empty() else "Activates synergy: " + ", ".join(names)


## Announces a newly active synergy (HUD banner + ring) and logs it.
func _on_activated(id: String) -> void:
	var game := director.game
	var def: Dictionary = SynergyData.SYNERGIES[id]
	activation_log.append("%s@%s" % [id, AbilityManager._clock(game.elapsed)])
	game.stat_add("synergies_activated", 1.0)
	if id == "shieldwall":
		_barrier_timer = 0.0
	if game.player != null:
		game.effects.ring(game.player.position, 100.0, Palette.NECRO_GREEN, 0.6)
	if game.hud != null:
		game.hud.announce("SYNERGY AWAKENED", String(def["display_name"]), String(def["description"]), Palette.NECRO_GREEN)


## Per-tick synergy effects (barriers, regeneration).
func step(delta: float) -> void:
	if active.has("shieldwall"):
		_barrier_timer -= delta
		if _barrier_timer <= 0.0:
			_barrier_timer = value("shieldwall", "barrier_interval")
			_raise_barriers()
	if active.has("deathless"):
		_regen_accum += delta
		if _regen_accum >= REGEN_TICK:
			_regenerate(_regen_accum)
			_regen_accum = 0.0


## Shieldwall: while a Warder (or a Profane Bishop) lives, every warrior's
## barrier is refreshed to barrier_fraction of its max HP (not stacked).
func _raise_barriers() -> void:
	if director.count_of("warder") + director.count_of("bishop") <= 0:
		return
	var frac := value("shieldwall", "barrier_fraction")
	for u in director.units:
		if u.unit_class == "warrior" and u.active:
			var b := u.max_hp * frac
			if b > u.barrier_hp:
				u.barrier_hp = b
				u.queue_redraw()
	director.game.stat_add("shieldwall_barriers", 1.0)


## Deathless: heals every living summon regen_per_s of max HP per second.
func _regenerate(seconds: float) -> void:
	var frac := value("deathless", "regen_per_s") * seconds
	var total := 0.0
	for u in director.units:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.hp < u.max_hp:
			total += director.game.combat.heal_unit(u, u.max_hp * frac)
	director.game.stat_add("deathless_regen", total)
