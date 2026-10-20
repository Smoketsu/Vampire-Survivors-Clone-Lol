## Unlocks — the ONE path that says whether a level-up item may be offered
## (GDD §15.0 "Act II: the Ancient Eye", unlockable spells and passives):
##   is_open(id)       — unlocked (UnlockData; Meta [unlocks]), or not lockable
##                       at all (every Act I item), or opened for the autotest.
##   act_allows(id, stage) — the item's own card row has no "act" key, or the
##                       run's stage belongs to that act (Act II's
##                       counter-passives are offered only in Act II).
##   offerable(id, stage) — both: AbilityManager's card pool asks this.
## The autotest never reads or writes the player's save (CLAUDE.md), so its
## Meta is a fresh one: an item is open there when --unlocks=all was given or
## when --spells= / --passives= / --classes= forces it (GameState).
class_name Unlocks
extends RefCounted


## True when item `id` may appear in a run (see the header).
static func is_open(id: String) -> bool:
	if not UnlockData.UNLOCKS.has(id):
		return true
	if GameState.autotest and GameState.autotest_forces(id):
		return true
	if GameState.autotest and GameState.autotest_unlock_all and not is_reward(id):
		return true  # --unlocks=all opens the card pool only (not titles, skins, ultimates).
	return Meta.is_item_unlocked(id)


# --- Content wave 2: B. Achievement rewards ---

## True when lockable item `id` is an achievement reward (UnlockData.REWARD_TYPES:
## an ultimate, a title or a skin), not a level-up card.
static func is_reward(id: String) -> bool:
	return UnlockData.REWARD_TYPES.has(item_type(id))


## UnlockData type of item `id` ("" when it is not lockable).
static func item_type(id: String) -> String:
	return String((UnlockData.UNLOCKS.get(id, {}) as Dictionary).get("type", ""))


## UI name of lockable item `id`: an ultimate's row `name`, a title's
## TitleData name, a skin family's SkinData name, else the card row's name.
static func item_name(id: String) -> String:
	var row: Dictionary = UnlockData.UNLOCKS.get(id, {})
	match String(row.get("type", "")):
		"ultimate":
			return String(row.get("name", id))
		"title":
			return TitleData.display_text(id)
		"skin":
			return SkinData.universal_name(id)
	return String(card_row(id).get("display_name", id))


## Ids of the UnlockData rows that achievement `achievement` unlocks, in
## table order (the Codex's reward column).
static func rewards_of(achievement: String) -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in UnlockData.UNLOCKS:
		if String((UnlockData.UNLOCKS[id] as Dictionary).get("achievement", "")) == achievement:
			out.append(id)
	return out


## Ids of every UnlockData row of type `type` (e.g. "title"), in table order.
static func ids_of_type(type: String) -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in UnlockData.UNLOCKS:
		if item_type(id) == type:
			out.append(id)
	return out


## True when item `id`'s card row allows stage `stage_def`'s act.
static func act_allows(id: String, stage_def: Dictionary) -> bool:
	var row := card_row(id)
	if not row.has("act"):
		return true
	return int(row["act"]) == int(stage_def.get("act", 1))


## True when item `id` may be offered on stage `stage_def`.
static func offerable(id: String, stage_def: Dictionary) -> bool:
	return is_open(id) and act_allows(id, stage_def)


## Co-op: as offerable(), but with a partner's own unlocks `unlocked` (id ->
## true, from the lobby loadout) instead of this device's save, so each
## player's card pool follows their own progress.
static func offerable_with(id: String, stage_def: Dictionary, unlocked: Dictionary) -> bool:
	var open := not UnlockData.UNLOCKS.has(id) or unlocked.has(id) or (GameState.autotest and GameState.autotest_forces(id))
	return open and act_allows(id, stage_def)


## The card row of item `id` (spell, passive or summon class; {} if none).
static func card_row(id: String) -> Dictionary:
	if AbilityData.SPELLS.has(id):
		return AbilityData.SPELLS[id]
	if PassiveData.PASSIVES.has(id):
		return PassiveData.PASSIVES[id]
	if UnitData.UNITS.has(id):
		return UnitData.UNITS[id]
	return {}


## The unlock condition of item `id` ("" when it is not lockable).
static func lock_text(id: String) -> String:
	if not UnlockData.UNLOCKS.has(id):
		return ""
	return String((UnlockData.UNLOCKS[id] as Dictionary).get("text", ""))


## Items a finished run unlocks, given the boss it slew (`boss_id`, "" when
## none) and the achievements now earned (`achieved`, id -> true). Items
## already unlocked are skipped. Pure: the caller records them.
static func newly_unlocked(boss_id: String, achieved: Dictionary, already: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in UnlockData.UNLOCKS:
		if already.has(id):
			continue
		var row: Dictionary = UnlockData.UNLOCKS[id]
		if row.has("boss") and boss_id != "" and String(row["boss"]) == boss_id:
			out.append(id)
		elif row.has("achievement") and achieved.has(String(row["achievement"])):
			out.append(id)
	return out
