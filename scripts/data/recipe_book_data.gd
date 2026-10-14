## RecipeBookData — texts and layout of the pause menu's Recipes view (RecipesPanel;
## owner decision "Evolution recipe book", GDD §15.0: evolutions are meant
## to be discovered, so the game gives no card or HUD hints; the only
## reference is this list of the combinations the player has already
## obtained in some run, saved in the Meta [recipes] section). Undiscovered
## recipes show as locked placeholders with no names or ingredients. Data
## only (no logic). Format strings use `%s` / `%d`. Since the menu
## modernization (wave 2, GDD §15.0 "Recipes book grid") the view is a grid
## of tiles: sizes are layout px (the 1280x720 layout).
class_name RecipeBookData
extends RefCounted

## View title (TITLE tier).
const TITLE: String = "Recipes"  # TUNING (not in GDD)
## The count's big part ("7 / 23", HEADER tier): discovered, total.
const COUNT_NUM: String = "%d / %d"  # TUNING (not in GDD)
## The count's word after the number (LABEL tier).
const COUNT_WORD: String = "discovered"  # TUNING (not in GDD)
## One ingredient of a discovered recipe: name, level required ("Soul Conduit Lv 5").
const INGREDIENT: String = "%s Lv %d"  # TUNING (not in GDD)
## Joins two ingredients in the detail line.
const PLUS: String = "+"  # TUNING (not in GDD)
## Tag of a discovered recipe by kind / mode (right of its name).
const TAGS: Dictionary = {
	"spell": "Spell evolution",  # TUNING (not in GDD)
	"transform": "Summon evolution",  # TUNING (not in GDD)
	"merge": "Summon merge",  # TUNING (not in GDD)
}
## Detail line of a focused locked recipe (no hint: owner rule).
const LOCKED_TEXT: String = "Undiscovered"  # TUNING (not in GDD)
## Glyph drawn in the result socket of a locked recipe's dark tile.
const LOCKED_GLYPH: String = "?"  # TUNING (not in GDD)

# --- Grid (menu modernization wave 2) ---------------------------------------------------

## Tiles per grid row.
const COLUMNS: int = 5  # TUNING (not in GDD) layout fit (23 recipes = 5 rows)
## Size (layout px) of one recipe tile: holds a four-icon merge row
## (RecipeIconRow: 4 x 32 px badges, 3 signs) with a little padding.
const TILE_SIZE := Vector2(204, 54)  # TUNING (not in GDD)
## Gap (layout px) between two tiles, both ways.
const TILE_GAP: int = 8  # TUNING (not in GDD)
## Side (layout px) of an empty socket on an undiscovered tile.
const SOCKET: float = 28.0  # TUNING (not in GDD)
## Gap (layout px) between the sockets of an undiscovered tile.
const SOCKET_GAP: float = 16.0  # TUNING (not in GDD)
## Fill of an empty socket (a dark recess).
const SOCKET_FILL := Color(0.07, 0.05, 0.1)  # TUNING (not in GDD)
## Rim of an empty socket.
const SOCKET_RIM := Color(0.2, 0.16, 0.28)  # TUNING (not in GDD)
## Colour of the dim "+" / "=" marks between the sockets.
const SOCKET_MARK := Color(0.28, 0.22, 0.38)  # TUNING (not in GDD)
## Height (layout px) kept for the detail line under the grid (name row and
## recipe row), so the panel never jumps between tiles.
const DETAIL_HEIGHT: float = 52.0  # TUNING (not in GDD)
## Back button caption (it carries the Esc / B chip).
const BACK: String = "Back"  # TUNING (not in GDD)
