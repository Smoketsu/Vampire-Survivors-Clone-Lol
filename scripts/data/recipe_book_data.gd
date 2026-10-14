## RecipeBookData — texts of the pause menu's Recipes view (RecipesPanel;
## owner decision "Evolution recipe book", GDD §15.0: evolutions are meant
## to be discovered, so the game gives no card or HUD hints; the only
## reference is this list of the combinations the player has already
## obtained in some run, saved in the Meta [recipes] section). Undiscovered
## recipes show as locked placeholders with no names or ingredients. Data
## only (no logic). Format strings use `%s` / `%d`.
class_name RecipeBookData
extends RefCounted

## Pause menu button and view title.
const TITLE: String = "Recipes"  # TUNING (not in GDD)
## Discovery count under the title: discovered, total.
const COUNT: String = "%d / %d discovered"  # TUNING (not in GDD)
## One ingredient of a discovered recipe: name, level required ("Soul Conduit Lv 5").
const INGREDIENT: String = "%s Lv %d"  # TUNING (not in GDD)
## Joins two ingredients.
const PLUS: String = "+"  # TUNING (not in GDD)
## Separates the ingredients from the evolution's name.
const ARROW: String = "->"  # TUNING (not in GDD)
## Tag of a discovered recipe by kind / mode (right of its name).
const TAGS: Dictionary = {
	"spell": "Spell evolution",  # TUNING (not in GDD)
	"transform": "Summon evolution",  # TUNING (not in GDD)
	"merge": "Summon merge",  # TUNING (not in GDD)
}
## Name line of a locked (undiscovered) recipe.
const LOCKED_NAME: String = "???"  # TUNING (not in GDD)
## Second line of a locked recipe.
const LOCKED_TEXT: String = "Undiscovered: obtain this evolution in a run to record its recipe."  # TUNING (not in GDD)
## Glyph drawn on a locked recipe's dark tile.
const LOCKED_GLYPH: String = "?"  # TUNING (not in GDD)
## Opacity of a locked recipe row (0..1).
const LOCKED_ALPHA: float = 0.6  # TUNING (not in GDD)
