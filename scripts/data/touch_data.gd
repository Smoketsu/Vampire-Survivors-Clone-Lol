## TouchData: numbers, words and colours of the phone / tablet support
## (GDD §15.0 "Mobile browser support"): the in-run touch controls
## (TouchControls), the mobile UI scale and the portrait "rotate" overlay
## (TouchSupport, RotateOverlay). Data only, no logic.
## Sizes of the touch controls are in CSS px (the browser's device-independent
## px, about 1/160 inch on a phone): TouchControls converts them to layout px
## for the current screen, so a button is as big under the thumb on a 360 CSS
## px tall phone as on a 768 CSS px tall tablet. Positions are measured from
## the screen edge or corner named in the comment.
class_name TouchData
extends RefCounted

# --- Detection ------------------------------------------------------------------------

## JavaScript expression (Web build) that is true on a phone or tablet: the
## primary pointer is a finger (coarse), or the browser reports touch points
## with no fine pointer at all (iPadOS Safari reports a desktop user agent).
## A desktop with a touchscreen keeps a fine primary pointer, so it starts
## with the keyboard hints and switches to touch on its first real touch.
const MOBILE_QUERY: String = "(window.matchMedia && (window.matchMedia('(pointer: coarse)').matches || (navigator.maxTouchPoints > 0 && !window.matchMedia('(any-pointer: fine)').matches)))"  # TUNING (not in GDD) mobile

## JavaScript expression (Web build) that is true when the browser can put the page in
## fullscreen (the Fullscreen API; false on iPhone Safari, where only videos can).
const FULLSCREEN_QUERY: String = "!!(document.fullscreenEnabled || document.webkitFullscreenEnabled)"  # TUNING (not in GDD) mobile
## JavaScript expression (Web build) that is true when the page runs as a home-screen app
## (iOS standalone launch or an installed web app: already fullscreen).
const STANDALONE_QUERY: String = "(navigator.standalone === true || (window.matchMedia && window.matchMedia('(display-mode: standalone), (display-mode: fullscreen)').matches))"  # TUNING (not in GDD) mobile
## JavaScript expression (Web build) that is true when the game is embedded in another
## page (an iframe, e.g. the itch.io game page).
const EMBEDDED_QUERY: String = "(window.self !== window.top)"  # TUNING (not in GDD) mobile

# --- Mobile UI scale --------------------------------------------------------------------

## The menus and the HUD are laid out for 1280 x 720 layout px. On a phone the
## window is short (about 360-430 CSS px tall), so the 720 px layout shrinks
## to about half size. The mobile UI scale (Window.content_scale_factor)
## enlarges everything until the visible layout area is no smaller than
## UI_SCALE_MIN_SIZE: wide phones (about 2.2 : 1) gain up to this much.
## Layout px of the smallest visible area every screen is checked to fit.
const UI_SCALE_MIN_SIZE := Vector2(1280.0, 600.0)  # TUNING (not in GDD) mobile; every screen fits 1280 x 600 once the key-hint strips hide
## Largest mobile UI scale factor (x).
const UI_SCALE_MAX: float = 1.2  # TUNING (not in GDD) mobile
## The UI scale applies only while the window is at most this many CSS px
## tall (a phone in landscape; tablets keep the desktop layout).
const UI_SCALE_MAX_CSS_HEIGHT: float = 540.0  # TUNING (not in GDD) mobile
## A screen whose content is taller (or wider) than the visible area shrinks
## to fit (TouchSupport.fit_to_screen()): this many layout px stay free at
## each edge. Never needed at the desktop's 720 px layout.
const FIT_MARGIN: float = 6.0  # TUNING (not in GDD) mobile

# --- Phone resolution cap (GDD §15.0 "Phone resolution cap") ---------------------------

## Highest device px per CSS px the Web page draws the canvas at on a phone or
## tablet (TouchSupport asks web/mobile_shell.html for it; 0 = no cap). iPhones
## report 3, so an 844 x 390 CSS px landscape page was a 2532 x 1170 px buffer that
## the GPU filled every frame; at 2 it is 1688 x 780 px (44% of the pixels) and every
## art pixel still covers at least one device px (the layout is about 600 px tall on
## a phone with the mobile UI scale). Desktops are never capped.
const CANVAS_DPR_CAP: float = 2.0  # TUNING (not in GDD) mobile

# --- Portrait overlay --------------------------------------------------------------------

## Title of the "rotate your device" overlay (TITLE tier).
const ROTATE_TITLE: String = "Turn your device"  # TUNING (not in GDD) mobile
## Line under it (BODY tier).
const ROTATE_TEXT: String = "Necropathy plays in landscape."  # TUNING (not in GDD) mobile
## Backdrop colour of the overlay (opaque: the squeezed game is hidden).
const ROTATE_BACKDROP := Color(0.05, 0.03, 0.08, 1.0)  # TUNING (not in GDD) mobile
## The overlay's content is one block laid out in layout px at the type
## tiers (title, line, two phone outlines), then scaled as a whole (like the
## UI scale) to fill ROTATE_FILL of the screen width: a portrait phone shows
## the 1280 px wide layout only about 400 CSS px wide.
## Size (layout px) of the block before scaling.
const ROTATE_BLOCK := Vector2(520.0, 330.0)  # TUNING (not in GDD) mobile
## Fraction (0..1) of the screen width (and at most the height) the block fills.
const ROTATE_FILL: float = 0.95  # TUNING (not in GDD) mobile
## Size (layout px) of a drawn phone outline held upright (drawn twice:
## upright, then turned to landscape after an arrow).
const ROTATE_PHONE_SIZE := Vector2(70.0, 120.0)  # TUNING (not in GDD) mobile
## Gap (layout px) between the two phone outlines (the arrow sits in it).
const ROTATE_GAP: float = 90.0  # TUNING (not in GDD) mobile
## Colour of the phone outlines and the arrow (soul teal: the thing to do).
const ROTATE_COLOR := Color(0.42, 0.95, 0.75)  # TUNING (not in GDD) mobile

# --- Touch controls: shared look --------------------------------------------------------

## Opacity of the touch controls while idle (they must not hide the action).
const IDLE_ALPHA: float = 0.42  # TUNING (not in GDD) mobile
## Opacity of a control while a finger holds it.
const ACTIVE_ALPHA: float = 0.8  # TUNING (not in GDD) mobile
## Fill of a button face (dark violet glass).
const FACE_FILL := Color(0.08, 0.05, 0.12, 0.85)  # TUNING (not in GDD) mobile
## Fill of a button face while pressed.
const FACE_PRESSED := Color(0.3, 0.16, 0.42, 0.95)  # TUNING (not in GDD) mobile
## Border of a button (violet, like the kit buttons).
const BORDER := Color(0.55, 0.38, 0.85)  # TUNING (not in GDD) mobile
## Border width (layout px).
const BORDER_WIDTH: float = 2.0  # TUNING (not in GDD) mobile
## Corner cut of every button and stick face, as a fraction of its half
## size (owner rule: cut corners; 0.42 makes an octagon that still reads as a
## round thumb button).
const CUT_FRACTION: float = 0.42  # TUNING (not in GDD) mobile
## Darkening over a button whose action is not ready (cooldown sweep).
const SHADE := Color(0.0, 0.0, 0.0, 0.62)  # TUNING (not in GDD) mobile
## Layout px per CSS px is at least this (a big tablet keeps thumb-sized controls).
const MIN_LAYOUT_PER_CSS: float = 1.0  # TUNING (not in GDD) mobile

# --- Joystick (left half) ----------------------------------------------------------------

## A finger landing left of this fraction of the screen width starts the
## floating joystick there (0..1).
const STICK_ZONE: float = 0.5  # TUNING (not in GDD) mobile
## Radius (CSS px) the knob can travel from the stick centre (full speed there).
const STICK_RADIUS: float = 52.0  # TUNING (not in GDD) mobile; about a thumb's comfortable reach
## Dead zone (fraction of STICK_RADIUS) in which the stick gives no input.
const STICK_DEAD_ZONE: float = 0.14  # TUNING (not in GDD) mobile
## Half size (CSS px) of the knob.
const KNOB_HALF: float = 22.0  # TUNING (not in GDD) mobile
## When the finger moves past STICK_RADIUS x this, the stick centre follows
## it (the stick drifts with the thumb instead of saturating far away).
const STICK_FOLLOW: float = 1.35  # TUNING (not in GDD) mobile
## Rest hint (drawn while no finger holds the stick): its centre in CSS px
## from the bottom-left corner (x right, y up), above the army list.
const STICK_REST := Vector2(118.0, 150.0)  # TUNING (not in GDD) mobile
## Opacity multiplier of the rest hint (x IDLE_ALPHA).
const STICK_REST_ALPHA: float = 0.55  # TUNING (not in GDD) mobile
## Colour of the stick ring and knob border (soul teal: the player's input).
const STICK_COLOR := Color(0.42, 0.95, 0.75)  # TUNING (not in GDD) mobile

# --- Buttons (right side) ----------------------------------------------------------------

## Button ids, each with:
##   action : the InputMap action it injects (the same path as the keys);
##   icon   : Glyphs.draw_icon() kind ("" = a drawn pause sign);
##   centre : CSS px of its centre from the corner `corner` (x left, y in);
##   half   : half size (CSS px) of the drawn face;
##   hit    : radius (CSS px) of its round hit area (>= 24 = a 48 CSS px target);
##   corner : "bottom_right" or "top_right".
const BUTTONS: Dictionary = {
	"dash": {"action": "dash", "icon": "grave_step", "centre": Vector2(74.0, 72.0), "half": 34.0, "hit": 46.0, "corner": "bottom_right"},  # TUNING (not in GDD) mobile; the main thumb button
	"ultimate": {"action": "ultimate", "icon": "dread_rally", "centre": Vector2(166.0, 50.0), "half": 28.0, "hit": 38.0, "corner": "bottom_right"},  # TUNING (not in GDD) mobile
	"toggle_aim": {"action": "toggle_aim", "icon": "shadow_bolt", "centre": Vector2(176.0, 128.0), "half": 22.0, "hit": 30.0, "corner": "bottom_right"},  # TUNING (not in GDD) mobile
	"pause": {"action": "pause", "icon": "", "centre": Vector2(34.0, 34.0), "half": 20.0, "hit": 30.0, "corner": "top_right"},  # TUNING (not in GDD) mobile
}
## Draw order of the buttons.
const BUTTON_ORDER: Array[String] = ["dash", "ultimate", "toggle_aim", "pause"]  # TUNING (not in GDD) mobile

# --- HUD room -----------------------------------------------------------------------------

## While the touch controls show, the HUD's top-right block (kills,
## modifiers) moves this many CSS px left, clear of the pause button.
const HUD_TOP_RIGHT_SHIFT: float = 62.0  # TUNING (not in GDD) mobile
