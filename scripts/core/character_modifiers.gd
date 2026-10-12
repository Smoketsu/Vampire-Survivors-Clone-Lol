## CharacterModifiers — the ONE path through which the chosen playable
## character (CharacterData, RunConfig.character_id) reaches a run. Game
## builds one instance at run start (`game.character`, never null) and keeps
## it for the whole run; the existing code reads it in a handful of places:
##   starting_spell()        AbilityManager.setup (the spell at Lv 1)
##   apply_to_player(p)      Game._ready, once, after the Soul Ash upgrades
##                           (max HP flat, move speed %)
##   value("spell_area")     AbilityManager.apply_spell_mods (radius keys)
##   innate_value(key)       every innate hook (CharacterInnates, HordeDirector
##                           .spawn_temporary, and the later spells' code)
##   on_spell_level(id, lv)  AbilityManager.apply_offer: records the spell
##                           level in the Meta save (the unlock rule) and
##                           collects the characters this run unlocked.
## The default character (the Gravecaller) has no innate and no stat
## modifiers: every value is 0 and apply_to_player() does nothing, so a
## Gravecaller run plays bit-for-bit like before characters existed.
## The static helpers answer UI questions (is a character known, playable in
## this build, unlocked; its stat text) for the picker and the autotest.
class_name CharacterModifiers
extends RefCounted

## CharacterData id of this run's character.
var id: String = CharacterData.DEFAULT_ID
## Its CharacterData row.
var _def: Dictionary = {}
## Innate value key -> number (empty for the Gravecaller).
var _innate: Dictionary = {}
## Stat modifier key -> number (empty = baseline stats).
var _stats: Dictionary = {}
## Character ids this run unlocked (first Lv UNLOCK_LEVEL of their spell), in
## the order it happened; shown on the end screen.
var unlocked_this_run: PackedStringArray = PackedStringArray()


## Builds the modifiers of character `p_id`; an unknown id, or one whose
## starting spell is not in this build, falls back to the default.
static func for_id(p_id: String) -> CharacterModifiers:
	var m := CharacterModifiers.new()
	m.id = p_id if is_available(p_id) else CharacterData.DEFAULT_ID
	m._def = CharacterData.CHARACTERS[m.id]
	var inn: Dictionary = m._def["innate"]  # {} = no innate.
	if not inn.is_empty():
		m._innate = (inn["values"] as Dictionary).duplicate()
	m._stats = (m._def["stats"] as Dictionary).duplicate()
	return m


# =====================================================================================
# Run queries
# =====================================================================================

## True for the default character (no innate, baseline stats).
func is_default() -> bool:
	return id == CharacterData.DEFAULT_ID


## UI name of the character.
func display_name() -> String:
	return String(_def["display_name"])


## AbilityData id of the spell the run starts with (Lv 1).
func starting_spell() -> String:
	return String(_def["spell"])


## True when the character has an innate passive.
func has_innate() -> bool:
	return not _innate.is_empty()


## Innate id ("" when none).
func innate_id() -> String:
	return "" if not has_innate() else String(_def["innate"]["id"])


## Innate UI name ("" when none).
func innate_name() -> String:
	return "" if not has_innate() else String(_def["innate"]["name"])


## Value of innate key `key` (CharacterData.INNATE_KEYS) for this character:
## 0 unless this character's innate defines it. Every innate hook asks this.
func innate_value(key: String) -> float:
	return float(_innate.get(key, 0.0))


## Stat modifier `stat` (CharacterData.STAT_LABELS key); 0 = unchanged.
func value(stat: String) -> float:
	return float(_stats.get(stat, 0.0))


## Sets the necromancer's character stats once at run start, after
## MetaModifiers.apply_to_player(): + flat max HP (HP refilled) and x move
## speed. Does nothing for a baseline character.
func apply_to_player(p: Necromancer) -> void:
	if _stats.is_empty():
		return
	if value("max_hp") != 0.0:
		p.max_hp = maxf(1.0, p.max_hp + value("max_hp"))
		p.hp = p.max_hp
	if value("move_speed") != 0.0:
		p.move_speed *= 1.0 + value("move_speed")


## Spell level hook (AbilityManager.apply_offer): records that spell `spell`
## reached level `lvl` in the Meta save (the unlock rule) and remembers the
## characters that unlocked through it.
func on_spell_level(spell: String, lvl: int) -> void:
	for cid: String in Meta.record_spell_level(spell, lvl):
		if not unlocked_this_run.has(cid):
			unlocked_this_run.append(cid)


# =====================================================================================
# Static helpers (picker, autotest, RunConfig)
# =====================================================================================

## The CharacterData row of `p_id` (the default's for an unknown id).
static func def(p_id: String) -> Dictionary:
	return CharacterData.CHARACTERS.get(p_id, CharacterData.CHARACTERS[CharacterData.DEFAULT_ID])


## True when `p_id` is a CharacterData id.
static func is_known(p_id: String) -> bool:
	return CharacterData.CHARACTERS.has(p_id)


## True when `p_id` is known and its starting spell exists in this build
## (the five later spells' characters stay hidden until those spells merge).
static func is_available(p_id: String) -> bool:
	return is_known(p_id) and AbilityData.SPELLS.has(String(CharacterData.CHARACTERS[p_id]["spell"]))


## Every playable character id in this build, in CharacterData.ORDER.
static func available_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for cid: String in CharacterData.ORDER:
		if is_available(cid):
			out.append(cid)
	return out


## Characters that unlock through spell `spell` (normally one).
static func unlocked_by_spell(spell: String) -> PackedStringArray:
	var out := PackedStringArray()
	for cid: String in CharacterData.ORDER:
		var d: Dictionary = CharacterData.CHARACTERS[cid]
		if not bool(d["starts_unlocked"]) and String(d["spell"]) == spell:
			out.append(cid)
	return out


## UI name of the starting spell of `p_id` (its id when the spell is missing).
static func spell_name(p_id: String) -> String:
	var sid := String(def(p_id)["spell"])  # Starting spell id.
	return String(AbilityData.SPELLS[sid]["display_name"]) if AbilityData.SPELLS.has(sid) else sid


## How `p_id` unlocks, for the picker ("" when open from the start).
static func unlock_text(p_id: String) -> String:
	if bool(def(p_id)["starts_unlocked"]):
		return ""
	return "Reach Lv %d with %s in any run." % [CharacterData.UNLOCK_LEVEL, spell_name(p_id)]


## One line of every stat modifier of `p_id` with the resulting value, e.g.
## "Max HP 135 (+15)   Move speed -5%" ("Baseline stats" when none).
static func stats_text(p_id: String) -> String:
	var st: Dictionary = def(p_id)["stats"]
	if st.is_empty():
		return "Baseline stats (Max HP %d, move speed %d)" % [int(PlayerData.MAX_HP), int(PlayerData.MOVE_SPEED)]
	var parts := PackedStringArray()  # One chunk per modifier.
	for key: String in CharacterData.STAT_LABELS:
		if not st.has(key):
			continue
		var v := float(st[key])  # Modifier value.
		var label: String = CharacterData.STAT_LABELS[key][0]
		if String(CharacterData.STAT_LABELS[key][1]) == "pct":
			parts.append("%s %+d%%" % [label, roundi(v * 100.0)])
		elif key == "max_hp":
			parts.append("%s %d (%+d)" % [label, int(PlayerData.MAX_HP + v), int(v)])
		else:
			parts.append("%s %+d" % [label, int(v)])
	return "   ".join(parts)
