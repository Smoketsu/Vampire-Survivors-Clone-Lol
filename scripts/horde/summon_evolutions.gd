## SummonEvolutions — runtime of the summon evolutions (user request; recipes
## and numbers in SummonEvolutionData). Owned by HordeDirector (`evolutions`).
##   * Eligibility: ready_ids() lists every recipe that holds; the time gate
##     (EvolutionData.MIN_ELAPSED) and the delivery are the spell evolutions'
##     own: AbilityManager.ready_evolutions() appends these ids, so the next
##     treasure chest grants them first (chest_rewards()) and the chest pity
##     timer shortens while one waits.
##   * Stats: modify_stats() is called at the end of
##     HordeDirector.compute_stats() (the ONE summon-stat path). It applies the
##     summon-evolution passives (Forbidden Knowledge, Dark Benediction; each
##     its own stacking category, GDD §6.4) and the evolution overlay of a
##     transformed class (SummonEvolutionData "mult" / "set", and
##     "special_mult" / "special_set" on its class-special numbers).
##   * Transformation ("transform"): the class keeps its id, level, slot and
##     capacity; every unit is re-statted in place, healed to full and plays
##     the transformation glow. Its HUD row, slot icon and plural change.
##   * Merge ("merge", Menders + Warders -> Profane Bishops): both bases drop
##     to level 0 and are locked (never offered again; one active slot is
##     freed), the result class is set to RESULT_LEVEL, and existing units
##     convert in place up to the result's capacity; the rest dissolve (not
##     counted as deaths) and missing ones spawn at once.
##   * Lich raise-the-dead: on_enemy_killed() (called by CombatResolver for
##     every kill) raises a temporary skeleton for a Lich kill, with a
##     deterministic accumulator instead of an RNG roll.
## Card helpers (offer, hints, dead-card and evolution-path checks) keep
## AbilityManager's changes to one-line hooks.
class_name SummonEvolutions
extends RefCounted

## Passive value key -> effective-stat keys it multiplies (x (1 + value))
## for the classes listed in the passive's "classes" (PassiveData).
const PASSIVE_STAT_KEYS := {
	"mage_damage": ["damage"],
	"mage_splash": ["splash_radius"],
	"support_power": ["heal_amount", "shield_amount", "ally_shield_amount", "aura_heal"],
}

## Owning horde director.
var director: HordeDirector
## Base class id -> evolution id of every class transformed in place.
var evolved: Dictionary = {}
## Base class id -> evolution id of every class merged away (locked).
var merged: Dictionary = {}
## Evolution id -> true once granted this run.
var done: Dictionary = {}
## Lich raise accumulator: + chance per Lich kill, a skeleton rises at 1.0.
var _raise_accum: float = 0.0
## Living Lich-raised skeletons as [SummonedUnit, generation] pairs.
var _risen: Array = []
## Skeletons raised by Liches this run.
var risen_total: int = 0


func _init(p_director: HordeDirector) -> void:
	director = p_director


# =====================================================================================
# Queries
# =====================================================================================

## Evolution id of class `cls` ("" if it has not transformed).
func evolution_of(cls: String) -> String:
	return String(evolved.get(cls, ""))


## True if class `cls` may never be offered on a card: merged away, or a
## class that only an evolution creates (UnitData "evolved_only").
func is_locked(cls: String) -> bool:
	return merged.has(cls) or bool(UnitData.UNITS[cls].get("evolved_only", false))


## UI plural of class `cls` (its evolution's plural once transformed).
func class_plural(cls: String) -> String:
	var evo := evolution_of(cls)
	if evo != "":
		return String(SummonEvolutionData.EVOLUTIONS[evo]["plural"])
	return String(UnitData.UNITS[cls]["plural"])


## IconGlyph kind of class `cls` (its evolution's icon once transformed).
func class_icon(cls: String) -> String:
	var evo := evolution_of(cls)
	if evo != "":
		return String(SummonEvolutionData.EVOLUTIONS[evo]["icon"])
	return cls


## True if evolution `evo` has not been granted and its recipe holds: every
## base class at BASE_LEVEL_REQUIRED and the paired passive at its level.
## (The time gate is checked by AbilityManager.ready_evolutions().)
func requirements_met(evo: String) -> bool:
	if done.has(evo):
		return false
	var def: Dictionary = SummonEvolutionData.EVOLUTIONS[evo]
	for cls: String in def["bases"]:
		if int(director.class_levels[cls]) < SummonEvolutionData.BASE_LEVEL_REQUIRED:
			return false
	return director.game.abilities.passive_level(String(def["passive"])) >= int(def["passive_level"])


## Summon evolutions whose recipe holds now, in SummonEvolutionData.ORDER.
func ready_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for evo: String in SummonEvolutionData.ORDER:
		if requirements_met(evo):
			out.append(evo)
	return out


## Living Lich-raised skeletons (stale entries are dropped).
func risen_alive() -> int:
	var i := _risen.size() - 1
	while i >= 0:
		var u: SummonedUnit = _risen[i][0]
		if not u.active or u.generation != int(_risen[i][1]):
			_risen.remove_at(i)
		i -= 1
	return _risen.size()


# =====================================================================================
# Effective stats (called by HordeDirector.compute_stats)
# =====================================================================================

## Applies the summon-evolution passives and, if `with_evolution`, the
## evolution overlay of class `cls` to the effective stats `out` in place.
func modify_stats(cls: String, out: Dictionary, with_evolution: bool) -> void:
	var ab := director.game.abilities
	for id: String in PassiveData.ORDER:
		var pdef: Dictionary = PassiveData.PASSIVES[id]
		if not pdef.has("classes") or not cls in (pdef["classes"] as Array):
			continue
		var lvl := ab.passive_level(id)
		if lvl <= 0:
			continue
		var row: Dictionary = pdef["levels"][lvl - 1]
		for key: String in row:
			for stat: String in PASSIVE_STAT_KEYS.get(key, []):
				out[stat] = float(out[stat]) * (1.0 + float(row[key]))
	var evo := evolution_of(cls)
	if not with_evolution or evo == "":
		return
	var def: Dictionary = SummonEvolutionData.EVOLUTIONS[evo]
	var mult: Dictionary = def.get("mult", {})
	for key: String in mult:
		out[key] = float(out[key]) * float(mult[key])
	var set_v: Dictionary = def.get("set", {})
	for key: String in set_v:
		out[key] = set_v[key]
	# Class-special overlays (Shadow Reaper, Cathedral Horror): on the scaled
	# special numbers; special_set values are final.
	var sp: Dictionary = out["special"]  # Fresh per compute_stats() call.
	var sp_mult: Dictionary = def.get("special_mult", {})
	for key: String in sp_mult:
		sp[key] = float(sp[key]) * float(sp_mult[key])
	var sp_set: Dictionary = def.get("special_set", {})
	for key: String in sp_set:
		sp[key] = sp_set[key]
	out["evolution"] = evo


# =====================================================================================
# Granting an evolution (AbilityManager.apply_offer, kind "evolution")
# =====================================================================================

## Grants summon evolution `evo`: transforms or merges, logs it in
## AbilityManager.evolution_history, re-evaluates synergies and announces it.
func apply(evo: String) -> void:
	var def: Dictionary = SummonEvolutionData.EVOLUTIONS[evo]
	var game := director.game
	done[evo] = true
	game.abilities.evolution_history.append("%s@%s" % [evo, AbilityManager._clock(game.elapsed)])
	game.stat_add("evolutions", 1.0)
	game.stat_add("summon_evolutions", 1.0)
	if String(def["mode"]) == "merge":
		_merge(evo, def)
	else:
		_transform(evo, def)
	director.synergies.evaluate()
	var p := game.player.position
	game.effects.ring(p, 120.0, Palette.NECRO_GREEN, 0.7)
	game.effects.ring(p, 80.0, Palette.VIOLET, 0.9)
	Sfx.play("summon_rise", p)
	if game.hud != null:
		game.hud.announce("SUMMON EVOLUTION", String(def["display_name"]), String(def["description"]), Palette.GOLD)


## "transform": overlays the evolution on the base class and re-stats every
## living unit of it in place (full heal + glow). Temporary summons keep
## their base kit.
func _transform(evo: String, def: Dictionary) -> void:
	var cls: String = def["bases"][0]
	evolved[cls] = evo
	director.recompute_all(director.capacity_snapshot())
	for u in director.units:
		if u.unit_class == cls and not u.is_temporary:
			u.hp = u.max_hp
			_transform_fx(u)


## "merge": removes the base classes (level 0, locked: their active slots
## are freed), raises the result class at RESULT_LEVEL and converts living
## base units into it up to its capacity; the rest dissolve without counting
## as deaths, and any shortfall spawns at once.
func _merge(evo: String, def: Dictionary) -> void:
	var result: String = def["result"]
	var bases: Array = def["bases"]
	for cls: String in bases:
		merged[cls] = evo
		director.class_levels[cls] = 0
		director.replenish_timer[cls] = 0.0
		director.immediate_spawns[cls] = 0
	director.class_levels[result] = SummonEvolutionData.RESULT_LEVEL
	var stats := director.compute_stats(result, SummonEvolutionData.RESULT_LEVEL)
	director.class_stats[result] = stats
	var cap := director.capacity(result)
	var converted := 0
	var leftovers: Array[SummonedUnit] = []
	for u in director.units:
		if u.is_temporary or not u.unit_class in bases:
			continue
		if converted >= cap:
			leftovers.append(u)
			continue
		u._drop_target()  # Releases heal reservations made as a Mender.
		u._enter(SummonedUnit.State.FOLLOWING)
		director.class_counts[u.unit_class] = maxi(0, int(director.class_counts[u.unit_class]) - 1)
		u.unit_class = result
		u.apply_stats(stats, false)
		u.hp = u.max_hp
		director.class_counts[result] = int(director.class_counts[result]) + 1
		converted += 1
		_transform_fx(u)
	for u in leftovers:
		director.game.effects.ring(u.position, u.radius * 2.5, Palette.NECRO_GREEN, 0.5)
		director.on_unit_died(u, false)
	director.immediate_spawns[result] = maxi(0, cap - converted)
	director.replenish_timer[result] = 0.0
	director.game.stat_add("merge_converted", float(converted))
	director.game.stat_add("merge_dissolved", float(leftovers.size()))
	director.summon_cap_changed.emit()
	director.summon_count_changed.emit()


## Transformation feedback on one unit: glow timer plus two rings.
func _transform_fx(u: SummonedUnit) -> void:
	u.transform_time = SummonEvolutionData.TRANSFORM_FX_TIME
	u.queue_redraw()
	director.game.effects.spawn_ring(u.position, Palette.VIOLET)
	director.game.effects.ring(u.position, u.radius * 3.0, Palette.NECRO_GREEN, 0.6)


# =====================================================================================
# Lich raise-the-dead (CombatResolver kill hook)
# =====================================================================================

## Kill hook (CombatResolver.damage_enemy, before the enemy is removed): a
## kill by a Lich ("lich" damage) adds the raise chance to the accumulator;
## at 1.0 a temporary skeleton rises where the enemy fell (base class kit,
## tagged "lich_risen"), unless max_alive of them already stand.
func on_enemy_killed(e: Enemy, source: String) -> void:
	if source != "lich" or e.is_structure:
		return  # Not a Lich kill, or a Crimson March structure (no body to raise).
	var raise: Dictionary = SummonEvolutionData.EVOLUTIONS["lich"]["raise"]
	_raise_accum += float(raise["chance"])
	if _raise_accum < 1.0:
		return
	_raise_accum -= 1.0
	var game := director.game
	if risen_alive() >= int(raise["max_alive"]):
		game.stat_add("lich_raise_capped", 1.0)
		return
	var u := director.spawn_temporary(String(raise["class"]), e.position, float(raise["duration"]),
			float(raise["hp_mult"]), float(raise["damage_mult"]))
	u.dmg_source = "lich_risen"
	u.glyph_kind = "risen"
	u.queue_redraw()
	_risen.append([u, u.generation])
	risen_total += 1
	game.effects.ring(u.position, 22.0, Palette.VIOLET, 0.5)
	game.stat_add("lich_raised", 1.0)


# =====================================================================================
# Level-up card helpers (AbilityManager)
# =====================================================================================

## Evolution card for `evo` (kind "evolution"): current vs evolved effective
## stats of the class(es), the new abilities and what happens to the slot.
func build_offer(evo: String) -> Dictionary:
	var ab := director.game.abilities
	var def: Dictionary = SummonEvolutionData.EVOLUTIONS[evo]
	var bases: Array = def["bases"]
	var deltas := PackedStringArray()
	var hint := ""
	if String(def["mode"]) == "merge":
		var result: String = def["result"]
		var nxt := director.compute_stats(result, SummonEvolutionData.RESULT_LEVEL, false)
		var cur_m := director.compute_stats("mender", int(director.class_levels["mender"]), false)
		var cur_w := director.compute_stats("warder", int(director.class_levels["warder"]), false)
		var new_cap := int(director.level_row(result, SummonEvolutionData.RESULT_LEVEL)["count"]) + director.bonus_capacity(result)
		deltas.append("%s %d + %s %d -> %s %d" % [UnitData.UNITS["mender"]["plural"], director.capacity("mender"),
				UnitData.UNITS["warder"]["plural"], director.capacity("warder"), def["plural"], new_cap])
		_delta(deltas, "Max HP", cur_m["max_hp"], nxt["max_hp"])
		_delta(deltas, "Heal per cast", cur_m["heal_amount"], nxt["heal_amount"])
		_delta(deltas, "Ward on you (HP)", cur_w["shield_amount"], nxt["shield_amount"])
		_delta(deltas, "Ally barrier (HP)", cur_w["ally_shield_amount"], nxt["ally_shield_amount"])
		deltas.append("NEW  Aura every %ss: heals %s, burns foes for %s" % [
				AbilityManager._fmt(nxt["aura_interval"]), AbilityManager._fmt(nxt["aura_heal"]), AbilityManager._fmt(nxt["aura_damage"])])
		deltas.append("Frees one active slot")
		hint = "Merges your Menders and Warders"
	else:
		var cls: String = bases[0]
		var lvl := int(director.class_levels[cls])
		var cur := director.compute_stats(cls, lvl, false)
		evolved[cls] = evo  # Preview the overlay without granting it.
		var nxt := director.compute_stats(cls, lvl, false)
		evolved.erase(cls)
		_delta(deltas, "Max HP", cur["max_hp"], nxt["max_hp"])
		_delta(deltas, "Damage", cur["damage"], nxt["damage"])
		_delta(deltas, "Shield bash", cur["bash_damage"], nxt["bash_damage"])
		_delta(deltas, "Attack interval (s)", cur["attack_interval"], nxt["attack_interval"])
		_delta(deltas, "Splash radius", cur["splash_radius"], nxt["splash_radius"])
		if float(nxt["cleave_radius"]) > 0.0:
			deltas.append("NEW  Cleave: %d%% of each hit within %s px" % [int(roundf(float(nxt["cleave_fraction"]) * 100.0)), AbilityManager._fmt(nxt["cleave_radius"])])
		if float(nxt["lifesteal"]) > 0.0:
			deltas.append("NEW  Life drain: %d%% of melee damage" % int(roundf(float(nxt["lifesteal"]) * 100.0)))
		if float(nxt["engaged_speed_mult"]) < float(cur["engaged_speed_mult"]):
			deltas.append("Dread: foes in contact slowed to %d%%" % int(roundf(float(nxt["engaged_speed_mult"]) * 100.0)))
		if def.has("raise"):
			var raise: Dictionary = def["raise"]
			deltas.append("NEW  1 in %d foes it slays rises for %ss (max %d)" % [
					int(roundf(1.0 / float(raise["chance"]))), AbilityManager._fmt(raise["duration"]), int(raise["max_alive"])])
		deltas.append_array(SpecialEvolutions.card_lines(evo, cur, nxt))  # Shadow Reaper / Cathedral Horror.
		hint ="Transforms your %s in place" % String(UnitData.UNITS[cls]["plural"]).to_lower()
	var lvl_from := int(SummonEvolutionData.BASE_LEVEL_REQUIRED)
	return ab._offer("evolution", evo, String(def["display_name"]), String(def["icon"]), lvl_from, lvl_from, "EVOLUTION",
			String(def["description"]), deltas, hint)


## Summon card hint for class `cls` going from `lvl` to `lvl` + 1: its
## evolution path, or "Evolution ready" ("" if none / already evolved).
func class_hint(cls: String, lvl: int) -> String:
	var ab := director.game.abilities
	for evo: String in SummonEvolutionData.ORDER:
		var def: Dictionary = SummonEvolutionData.EVOLUTIONS[evo]
		var bases: Array = def["bases"]
		if done.has(evo) or not cls in bases:
			continue
		var others_ready := true
		var partners := PackedStringArray()
		for b: String in bases:
			if b != cls:
				partners.append(String(UnitData.UNITS[b]["plural"]))
				others_ready = others_ready and int(director.class_levels[b]) >= SummonEvolutionData.BASE_LEVEL_REQUIRED
		var passive: String = def["passive"]
		var need := int(def["passive_level"])
		if lvl + 1 >= SummonEvolutionData.BASE_LEVEL_REQUIRED and others_ready and ab.passive_level(passive) >= need:
			return "Evolution ready: %s%s" % [def["display_name"], ab._evo_unlock_note()]
		var p_text := _passive_text(passive, need)
		if partners.is_empty():
			return "Evolves into %s at Lv %d with %s%s" % [def["plural"], SummonEvolutionData.BASE_LEVEL_REQUIRED, p_text, AbilityManager._evo_source_note()]
		return "Merges with %s into %s (both Lv %d) with %s%s" % [" + ".join(partners), def["plural"],
				SummonEvolutionData.BASE_LEVEL_REQUIRED, p_text, AbilityManager._evo_source_note()]
	return ""


## Passive card hint for passive `id` going from `lvl` to `lvl` + 1: the
## summon evolution it unlocks ("" if it pairs with none).
func passive_hint(id: String, lvl: int) -> String:
	var ab := director.game.abilities
	for evo: String in SummonEvolutionData.ORDER:
		var def: Dictionary = SummonEvolutionData.EVOLUTIONS[evo]
		if String(def["passive"]) != id:
			continue
		if done.has(evo):
			return "%s already evolved" % def["display_name"]
		var parts := PackedStringArray()
		var bases_ready := true
		for b: String in def["bases"]:
			var bl := int(director.class_levels[b])
			bases_ready = bases_ready and bl >= SummonEvolutionData.BASE_LEVEL_REQUIRED
			parts.append("%s (Lv %d/%d)" % [UnitData.UNITS[b]["plural"], bl, SummonEvolutionData.BASE_LEVEL_REQUIRED])
		var need := int(def["passive_level"])
		if bases_ready and lvl + 1 >= need:
			return "Evolution ready: %s%s" % [def["display_name"], ab._evo_unlock_note()]
		var at := " once this is Lv %d" % need if need > 1 else ""
		return "Evolves %s into %s%s%s" % [" + ".join(parts), def["plural"], at, AbilityManager._evo_source_note()]
	return ""


## One concrete effect line for summon-evolution passive `id` going from
## `lvl` to `lvl` + 1 with level row `nxt` ("" for other passives).
func passive_effect_line(id: String, lvl: int, nxt: Dictionary) -> String:
	var ab := director.game.abilities
	match id:
		"forbidden_knowledge":
			var m := director.compute_stats("mage", maxi(1, int(director.class_levels["mage"])), false)
			var cur := ab.passive_value(id, "mage_damage")
			return "Mage damage %s -> %s" % [AbilityManager._fmt(m["damage"]), AbilityManager._fmt(float(m["damage"]) / (1.0 + cur) * (1.0 + float(nxt["mage_damage"])))]
		"dark_benediction":
			var cls := "warder" if int(director.class_levels["warder"]) > 0 and int(director.class_levels["mender"]) <= 0 else "mender"
			if int(director.class_levels["bishop"]) > 0:
				cls = "bishop"
			var s := director.compute_stats(cls, maxi(1, int(director.class_levels[cls])), false)
			var key := "shield_amount" if cls == "warder" else "heal_amount"
			var cur := ab.passive_value(id, "support_power")
			var label := "%s ward" % UnitData.UNITS[cls]["display_name"] if cls == "warder" else "%s heal" % UnitData.UNITS[cls]["display_name"]
			return "%s %s -> %s" % [label, AbilityManager._fmt(s[key]), AbilityManager._fmt(float(s[key]) / (1.0 + cur) * (1.0 + float(nxt["support_power"])))]
	return ""


## True if passive `id` affects only summon classes (PassiveData "classes")
## and none of them is owned: a "dead" card.
func passive_dead(id: String) -> bool:
	var pdef: Dictionary = PassiveData.PASSIVES[id]
	if not pdef.has("classes"):
		return false
	for cls: String in pdef["classes"]:
		if int(director.class_levels[cls]) > 0:
			return false
	return true


## True if item `id` (summon class or passive) is on a pending summon
## evolution path: the paired passive while a base class is owned, or a base
## class while the paired passive is owned (LevelUpData.WEIGHT_EVOLUTION_PATH).
func on_path(id: String) -> bool:
	var ab := director.game.abilities
	for evo: String in SummonEvolutionData.ORDER:
		if done.has(evo):
			continue
		var def: Dictionary = SummonEvolutionData.EVOLUTIONS[evo]
		if id == String(def["passive"]):
			for b: String in def["bases"]:
				if int(director.class_levels[b]) > 0:
					return true
		elif id in (def["bases"] as Array) and ab.passive_level(String(def["passive"])) > 0:
			return true
	return false


## "Dark Command Lv 5" for hints (just the name if `need` is 1, "owned";
## every recipe now needs Lv 5).
static func _passive_text(passive: String, need: int) -> String:
	var p_name := String(PassiveData.PASSIVES[passive]["display_name"])
	return "%s Lv %d" % [p_name, need] if need > 1 else p_name


## Appends "label a -> b" when the value changes.
static func _delta(out: PackedStringArray, label: String, a: Variant, b: Variant) -> void:
	if not is_equal_approx(float(a), float(b)):
		out.append("%s %s -> %s" % [label, AbilityManager._fmt(float(a)), AbilityManager._fmt(float(b))])
