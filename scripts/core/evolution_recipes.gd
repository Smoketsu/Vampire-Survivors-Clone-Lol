## EvolutionRecipes — read-only view of every evolution recipe, built from
## EvolutionData (spell evolutions) and SummonEvolutionData (summon
## evolutions) so that new recipes in either file appear automatically
## (user decision "Evolution recipe book", GDD §15.0). Used by the Meta
## [recipes] save section (which evolutions were discovered), the pause
## menu's Recipes view (RecipesPanel) and the autotest summary. It never
## checks or changes eligibility; that stays AbilityManager.ready_evolutions().
##
## A normalised recipe (recipe()) is a Dictionary:
##   id          — evolution id,
##   kind        — "spell" (EvolutionData) | "summon" (SummonEvolutionData),
##   mode        — "transform" (spells and transform classes) | "merge",
##   name, icon  — the evolution's display name and IconGlyph kind,
##   ingredients — Array of {id, name, icon, level}: the bases first (spell
##                 display name, or class plural as the cards read
##                 "Warders"), then the paired passive; `level` is the level
##                 each one needs (5 for every recipe today).
class_name EvolutionRecipes
extends RefCounted


## Every evolution id: the spell evolutions, then the summon evolutions,
## each in its data file's ORDER (the Recipes view keeps this order).
static func ids() -> PackedStringArray:
	var out := PackedStringArray(EvolutionData.ORDER)  # Spell evolutions first.
	out.append_array(PackedStringArray(SummonEvolutionData.ORDER))
	return out


## True if `id` is a known evolution id (spell or summon).
static func has(id: String) -> bool:
	return EvolutionData.EVOLUTIONS.has(id) or SummonEvolutionData.EVOLUTIONS.has(id)


## Normalised recipe of evolution `id` (see the header). `id` must be known.
static func recipe(id: String) -> Dictionary:
	var ingredients: Array[Dictionary] = []  # Bases first, then the passive.
	if EvolutionData.EVOLUTIONS.has(id):
		var d: Dictionary = EvolutionData.EVOLUTIONS[id]  # Spell evolution definition.
		var base: String = d["base"]
		ingredients.append({"id": base, "name": String(AbilityData.SPELLS[base]["display_name"]),
			"icon": String(AbilityData.SPELLS[base]["icon"]), "level": EvolutionData.BASE_LEVEL_REQUIRED})
		ingredients.append(_passive(String(d["passive"]), EvolutionData.PASSIVE_LEVEL_REQUIRED))
		return {"id": id, "kind": "spell", "mode": "transform", "name": String(d["display_name"]),
			"icon": String(d["icon"]), "ingredients": ingredients}
	var s: Dictionary = SummonEvolutionData.EVOLUTIONS[id]  # Summon evolution definition.
	for cls: String in s["bases"]:
		ingredients.append({"id": cls, "name": String(UnitData.UNITS[cls]["plural"]), "icon": cls,
			"level": SummonEvolutionData.BASE_LEVEL_REQUIRED})
	ingredients.append(_passive(String(s["passive"]), int(s["passive_level"])))
	return {"id": id, "kind": "summon", "mode": String(s["mode"]), "name": String(s["display_name"]),
		"icon": String(s["icon"]), "ingredients": ingredients}


## Ingredient entry of passive `id` needed at level `lvl`.
static func _passive(id: String, lvl: int) -> Dictionary:
	var p: Dictionary = PassiveData.PASSIVES[id]  # Passive definition.
	return {"id": id, "name": String(p["display_name"]), "icon": String(p["icon"]), "level": lvl}
