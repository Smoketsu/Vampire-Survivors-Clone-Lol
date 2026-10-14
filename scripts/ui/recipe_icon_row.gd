## RecipeIconRow — a level-up card's evolution recipe drawn as icons (owner
## decision, GDD §15.0 "Recipe icon row"): [base] + [passive] = [evolution],
## or [Menders] + [Warders] + [Dark Benediction] = [Profane Bishop] for a merge.
## It replaces the old "Evolves X ... into Y" card text, and the card shows it
## only once that recipe is discovered (Meta.is_recipe_discovered()), so
## evolutions stay something to find. Ingredients and order come from
## EvolutionRecipes.recipe() (bases first, then the passive), the icons from
## IconGlyph (32 px badge art; a summon class draws its summon art, as in the
## HUD slots). Purely visual.
class_name RecipeIconRow
extends HBoxContainer

## Side (px) of each icon: the badge icons' own 32 art px, drawn 1:1.
const ICON: float = 32.0
## Gap (px) between an icon and a "+" / "=" sign.
const GAP: int = 4


## The icon row for evolution `evo_id`, or null when the card must show
## nothing about it (no recipe, or not discovered yet).
static func for_card(evo_id: String) -> RecipeIconRow:
	if evo_id == "" or not EvolutionRecipes.has(evo_id) or not Meta.is_recipe_discovered(evo_id):
		return null
	var row := RecipeIconRow.new()
	row.build(evo_id)
	return row


## Fills the row with recipe `evo_id`: ingredients joined by "+", then "=",
## then the evolution.
func build(evo_id: String) -> void:
	var r := EvolutionRecipes.recipe(evo_id)  # Normalised recipe.
	alignment = BoxContainer.ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", GAP)
	var first := true
	for ing: Dictionary in r["ingredients"]:
		if not first:
			add_child(_sign("+"))
		first = false
		add_child(_icon(String(ing["icon"])))
	add_child(_sign("="))
	add_child(_icon(String(r["icon"])))


## One recipe icon.
static func _icon(kind: String) -> IconGlyph:
	var g := IconGlyph.new(kind, Vector2(ICON, ICON))
	g.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return g


## A "+" or "=" sign between the icons.
static func _sign(s: String) -> Label:
	var l := UiTheme.tier_label(s, UiTheme.Tier.NAME, UiTheme.TEXT_GOLD)  # Jersey 28, the x1.5 size.
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l
