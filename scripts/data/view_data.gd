## ViewData: camera zoom levels and the player's ground marker. Data only.
## The camera zoom is a player setting (Settings.zoom_id, Settings menu "Zoom").
## Gameplay never depends on the chosen zoom: the enemy spawn ring and other
## "just off-screen" distances use the visible area at GAMEPLAY_ZOOM (Normal),
## never the smaller Close view, so Close and Normal play identically, and the
## autotest always uses GAMEPLAY_ZOOM. Owner decisions (art pass): only Normal
## x1 and Close x2, whole multiples of the grid art's 1 art px = 1 px (1 and 2
## px per art px; the sharp-pixel shader keeps other window scales even); the
## old Far x0.8 is dropped and a saved "far" (or any unknown id) loads as Normal
## (Settings.load_settings()).
class_name ViewData
extends RefCounted

## Zoom level id -> {label: menu text, zoom: Camera2D zoom (1 = 1 world px per screen px)}.
const ZOOM_LEVELS: Dictionary = {
	"normal": {"label": "Normal", "zoom": 1.0},  # TUNING (not in GDD) user decision: was a fixed 1.5
	"close": {"label": "Close", "zoom": 2.0},  # TUNING (not in GDD) owner decision (art pass grid 1:1): was 1.5 (1.25 before); 1 art px = 2 px
}
## Order the Settings menu cycles through the zoom levels (ZOOM_LEVELS ids).
const ZOOM_ORDER: Array = ["normal", "close"]
## Zoom level used on a fresh install and by the autotest.
const DEFAULT_ZOOM: String = "normal"
## Reference zoom for gameplay distances (spawn ring, off-screen checks): the
## visible area is never treated as smaller than at this zoom.
const GAMEPLAY_ZOOM: float = 1.0  # TUNING (not in GDD)

## Player ground marker (a soft ring under the necromancer so the player is
## easy to find in a crowd): ellipse half-width in world px.
const PLAYER_RING_RADIUS: float = 22.0  # TUNING (not in GDD)
## Ellipse height as a fraction of its width (top-down three-quarter view).
const PLAYER_RING_SQUASH: float = 0.45  # TUNING (not in GDD)
## Ring line width in px.
const PLAYER_RING_WIDTH: float = 2.0  # TUNING (not in GDD)
## Ring colour (necrotic green, Palette.NECRO_GREEN) and opacity.
const PLAYER_RING_COLOR: Color = Color(0.42, 0.95, 0.55, 0.75)  # TUNING (not in GDD)
## Translucent fill inside the ring.
const PLAYER_RING_FILL: Color = Color(0.42, 0.95, 0.55, 0.12)  # TUNING (not in GDD)
## Vertical offset (world px) of the ring centre below the player's origin (at the feet).
const PLAYER_RING_OFFSET: float = 20.0  # TUNING (not in GDD)
