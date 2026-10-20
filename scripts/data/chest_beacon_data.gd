## ChestBeaconData: numbers, colours and sprite keys of the chest beacon (owner
## request, Oct 2026: "Chests are a bit hard to see, can we add an indicator that
## sits above them ... show you if you missed one. Or if it's slightly off
## screen"; GDD §15.0 "Chest beacon"). Three pieces, all drawn by ChestBeacon /
## ChestArrows:
##   * a gold chevron bobbing over every chest (world space, above the units),
##   * a soft gold ground glow and an expanding pulse ring under the chest
##     (Chest._draw() through ChestBeacon.draw_ground(), under the chest),
##   * an edge badge with a pointer for every chest off screen (a CanvasLayer
##     over the world, under the HUD and the menus), clamped to an inset rect
##     that keeps out of the HUD's top bars, the ability bar, the army list and,
##     on phones, the touch controls.
## Gold is the chest's colour in the UI colour language; every gold shape has a
## dark ink rim so it reads on the light Sanctum floors too. Motion runs on real
## time and stops with Reduce motion; Effects: Reduced drops the pulse ring.
## Purely visual: nothing here touches gameplay state or the RNG, and nothing is
## drawn headless. Sizes are layout px (1280 x 720 layout) unless named world
## px or CSS px. Data only, no logic.
class_name ChestBeaconData
extends RefCounted

# --- Art --------------------------------------------------------------------------------

## Gold down-chevron over a chest (19 x 15 art px, tools/chest_beacon_art.py).
const BEACON_KEY: String = "markers/chest_beacon"  # TUNING (not in GDD)
## Round edge badge with a little gold chest in it (21 x 21 art px, same tool).
const BADGE_KEY: String = "markers/chest_badge"  # TUNING (not in GDD)

# --- Colours ----------------------------------------------------------------------------

## Gold of the code-drawn shapes (palette gold #E0A92E: the chest colour).
const GOLD := Color(0.878, 0.663, 0.18)  # TUNING (not in GDD)
## Lit gold of the code-drawn shapes' top edges and the pulse ring (gold_light #FFDC66).
const GOLD_LIGHT := Color(1.0, 0.863, 0.4)  # TUNING (not in GDD)
## Dark rim of every code-drawn shape (ink_warm #1C110B), so gold reads on light floors.
const INK := Color(0.11, 0.067, 0.043)  # TUNING (not in GDD)
## Dark plate inside the code-drawn fallback badge (brown #4F3320).
const PLATE := Color(0.31, 0.2, 0.125)  # TUNING (not in GDD)

# --- Chevron over the chest (world px) -----------------------------------------------------

## Height (world px) of the chevron's centre above the chest's centre at the
## bottom of its bob (the chest sprite is 29 px tall, centred on the chest:
## its lid top is at -14.5; the 15 px chevron then floats 4 px above it).
const BEACON_LIFT: float = 26.0  # TUNING (not in GDD)
## Height (world px) of the bob above BEACON_LIFT at its top (whole px: the
## chevron is drawn on whole px, so it steps instead of swimming).
const BOB_HEIGHT: float = 3.0  # TUNING (not in GDD)
## Seconds (real time) of one bob up and down.
const BOB_PERIOD: float = 1.2  # TUNING (not in GDD)
## Draw layer (z_index) of the chevrons: above the units, projectiles and
## cosmetic effects (5), under the damage numbers (FxLayer 20).
const BEACON_Z: int = 18  # TUNING (not in GDD)

# --- Ground glow and pulse ring under the chest (world px) ---------------------------------

## Drop (world px) of the glow's centre below the chest's centre: the chest's base.
const GROUND_DROP: float = 8.0  # TUNING (not in GDD)
## Half-width (world px) of the steady ground glow ellipse.
const GLOW_RADIUS: float = 22.0  # TUNING (not in GDD)
## Height of the ground ellipses as a fraction of their width (top-down
## three-quarter view, like the player's ring, ViewData.PLAYER_RING_SQUASH).
const GROUND_SQUASH: float = 0.5  # TUNING (not in GDD)
## Opacity (0-1) of the steady glow's gold fill.
const GLOW_ALPHA: float = 0.24  # TUNING (not in GDD)
## Opacity (0-1) of the steady glow's thin gold rim (with its dark under-rim).
const GLOW_RIM_ALPHA: float = 0.75  # TUNING (not in GDD)
## Half-width (world px) of the pulse ring when it starts and when it fades out.
const PULSE_START: float = 14.0  # TUNING (not in GDD)
const PULSE_END: float = 38.0  # TUNING (not in GDD) half-width when the ring has faded out
## Seconds (real time) of one pulse ring growing out and fading.
const PULSE_PERIOD: float = 1.6  # TUNING (not in GDD)
## Opacity (0-1) of the pulse ring as it starts (it fades to 0).
const PULSE_ALPHA: float = 0.85  # TUNING (not in GDD)
## Line width (world px) of the gold rings; the dark under-rim is this + 2.
const RING_WIDTH: float = 2.0  # TUNING (not in GDD)
## Points per ground ellipse (smooth enough at a 38 px half-width).
const ELLIPSE_POINTS: int = 32  # TUNING (not in GDD)

# --- Off-screen arrows (layout px) -----------------------------------------------------------

## CanvasLayer of the edge arrows: over the world and the power-up tint (8),
## beside the hurt vignette (9), under the HUD and every menu (Game's UI layer 10).
const ARROW_LAYER: int = 9  # TUNING (not in GDD)
## A chest counts as on screen while its centre is at least this far inside
## the visible area (px); nearer the edge (or outside) it gets an arrow.
const ON_SCREEN_INSET: float = 8.0  # TUNING (not in GDD)
## The arrows sit on the edge of an inset rect: this far from the left and
## right screen edges (badge radius 10.5 + pointer 20 + room).
const EDGE_SIDE: float = 40.0  # TUNING (not in GDD)
## ... this far below the top edge: under the HUD's top bars (XP bar, level and
## HP, the timer, zone, objective and boss bar block, kills and modifiers).
const EDGE_TOP: float = 150.0  # TUNING (not in GDD)
## While the HUD's top-centre block reaches lower (the boss and miniboss
## bars), the top margin is its bottom + this (px): an arrow pointing up (badge
## radius 10, pointer gap 11 and length 11) stays clear of the bars.
const TOP_HUD_GAP: float = 34.0  # TUNING (not in GDD)
## ... and this far above the bottom edge: over the ability bar and the
## Grave Step / ultimate meters (they start 130 px above it).
const EDGE_BOTTOM: float = 150.0  # TUNING (not in GDD)
## Size (px) of the bottom-left corner kept free: the army list (16-300 px
## wide, up to 206 px tall). An arrow that would land in a kept-free corner
## slides along its edge out of it.
const KEEP_BOTTOM_LEFT := Vector2(316.0, 214.0)  # TUNING (not in GDD)
## Phones and tablets (InputHints on TOUCH): the corners kept free for the touch
## controls, in CSS px (converted with TouchSupport.layout_per_css(); TouchData):
## bottom-left = the joystick's rest ring (centre 118 x 150, radius 52) and room
## for the thumb; bottom-right = the Grave Step, ultimate and aim buttons (their
## hit areas reach 206 x 158).
const TOUCH_KEEP_BOTTOM_LEFT := Vector2(200.0, 230.0)  # TUNING (not in GDD) mobile
const TOUCH_KEEP_BOTTOM_RIGHT := Vector2(222.0, 174.0)  # TUNING (not in GDD) mobile; the buttons' corner
## Phones and tablets: the top-right corner kept free for the touch pause
## button (centre 34 x 34, hit radius 30, CSS px).
const TOUCH_KEEP_TOP_RIGHT := Vector2(76.0, 76.0)  # TUNING (not in GDD) mobile
## Most arrows drawn at once (nearest chests first); the others fold into
## their nearest arrow as count pips.
const MAX_ARROWS: int = 4  # TUNING (not in GDD)
## Two arrows nearer than this (px) merge into one (the nearer chest's), with a pip.
const MERGE_DISTANCE: float = 30.0  # TUNING (not in GDD)
## World px past the view edge at which an arrow is at its faintest (it never
## fades further, so a chest left far behind stays findable).
const FAR_DISTANCE: float = 1600.0  # TUNING (not in GDD)
## Opacity (0-1) of an arrow just off screen and at FAR_DISTANCE or beyond.
const ARROW_ALPHA_NEAR: float = 1.0  # TUNING (not in GDD)
const ARROW_ALPHA_FAR: float = 0.55  # TUNING (not in GDD) never fully invisible
## Pointer size factor just off screen and at FAR_DISTANCE (it shrinks a little).
const POINTER_SCALE_NEAR: float = 1.0  # TUNING (not in GDD)
const POINTER_SCALE_FAR: float = 0.7  # TUNING (not in GDD)
## Distance (px) from the badge centre to the pointer's base.
const POINTER_GAP: float = 11.0  # TUNING (not in GDD) just outside the 21 px badge
## Length (px) of the pointer triangle at full size, base to tip.
const POINTER_LENGTH: float = 11.0  # TUNING (not in GDD)
## Half-width (px) of the pointer's base at full size.
const POINTER_HALF_WIDTH: float = 7.0  # TUNING (not in GDD)
## Width (px) of the pointer's dark rim.
const POINTER_RIM: float = 2.0  # TUNING (not in GDD)
## Radius (px) of the code-drawn badge (the fallback when the PNG is missing).
const BADGE_RADIUS: float = 10.0  # TUNING (not in GDD)
## Radius (px) of the gold pulse ring round a badge as it starts and as it has
## faded out (it shares the ground pulse's PULSE_PERIOD and PULSE_ALPHA x this).
const BADGE_PULSE_START: float = 11.0  # TUNING (not in GDD)
const BADGE_PULSE_END: float = 21.0  # TUNING (not in GDD) radius when the badge's ring has faded out
## Opacity factor (0-1, x PULSE_ALPHA) of the badge's pulse ring.
const BADGE_PULSE_ALPHA: float = 0.8  # TUNING (not in GDD)
## How far (px) an arrow nudges toward its chest and back (real time).
const NUDGE: float = 3.0  # TUNING (not in GDD)
## Seconds (real time) of one nudge out and back.
const NUDGE_PERIOD: float = 1.0  # TUNING (not in GDD)
## Size (px) of one merged-chest pip under a badge, the gap between pips, and the
## most pips shown.
const PIP_SIZE: float = 4.0  # TUNING (not in GDD)
const PIP_GAP: float = 2.0  # TUNING (not in GDD) between two pips
const MAX_PIPS: int = 3  # TUNING (not in GDD)
