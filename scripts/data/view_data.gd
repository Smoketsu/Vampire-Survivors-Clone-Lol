## ViewData: camera zoom levels and the player's ground marker. Data only.
## The camera zoom is a player setting (Settings.zoom_id, Settings menu "Zoom").
## Gameplay never depends on the chosen zoom below GAMEPLAY_ZOOM: the enemy
## spawn ring and other "just off-screen" distances use the visible area at
## GAMEPLAY_ZOOM, or the real visible area when the player zooms further out
## (so nothing pops into view). Close and Normal therefore play identically, and
## the autotest always uses GAMEPLAY_ZOOM.
class_name ViewData
extends RefCounted

## Zoom level id -> {label: menu text, zoom: Camera2D zoom (1 = 1 world px per screen px)}.
const ZOOM_LEVELS: Dictionary = {
	"close": {"label": "Close", "zoom": 1.25},  # TUNING (not in GDD)
	"normal": {"label": "Normal", "zoom": 1.0},  # TUNING (not in GDD) user decision: was a fixed 1.5
	"far": {"label": "Far", "zoom": 0.8},  # TUNING (not in GDD)
}
## Order the Settings menu cycles through the zoom levels.
const ZOOM_ORDER: Array = ["close", "normal", "far"]
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
