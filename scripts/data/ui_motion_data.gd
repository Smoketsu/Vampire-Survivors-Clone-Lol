## UiMotionData: every timing, distance, scale and easing of the shared UI
## motion layer (UiMotion: panel open / close, staggered entrances, card and
## tile lift, button press squash, number count-ups, and the fade through
## black between the main menu and a run). UI motion is purely cosmetic: it
## runs on unscaled real time, never touches Engine.time_scale or the seeded
## gameplay RNG, and is instant under the autotest and with the "Reduce
## motion" setting, so none of these values can change a run.
## Times are real seconds; distances are layout px (the 1280x720 layout, x1.5
## in a 1080p window); scales are factors of the rest size (1 = rest).
## Data only, no logic.
class_name UiMotionData
extends RefCounted

# --- Driver ----------------------------------------------------------------------------

## Longest real-time step (s) the motion driver advances UI tweens by in one
## frame: a frame hitch (building a run, a slow first draw) slows a motion
## down instead of skipping it. 0.05 = 20 fps.
const MAX_STEP: float = 0.05  # TUNING (not in GDD)

# --- Panel open / close (UiMotion.open / close / hide) ----------------------------------

## Seconds a panel takes to open: its backdrop and content fade in while the
## content rises and grows to rest.
const OPEN_TIME: float = 0.18  # TUNING (not in GDD)
## Seconds of OPEN_TIME the fade-in of the whole screen (backdrop included)
## takes (0..OPEN_TIME); shorter than the rise so the panel is legible early.
const OPEN_FADE_TIME: float = 0.12  # TUNING (not in GDD)
## Distance (px) below its rest position the content starts its open rise.
const OPEN_RISE: float = 6.0  # TUNING (not in GDD)
## Content scale at the start of the open (0..1; grows to 1 around its centre).
const OPEN_SCALE: float = 0.96  # TUNING (not in GDD)
## Easing transition of the open (Tween.TRANS_*): quartic = quick start, soft landing.
const OPEN_TRANS: Tween.TransitionType = Tween.TRANS_QUART  # TUNING (not in GDD)
## Seconds a panel takes to close (a quick fade; the screen is freed / hidden after it).
const CLOSE_TIME: float = 0.1  # TUNING (not in GDD)
## Content scale the close shrinks towards (0..1).
const CLOSE_SCALE: float = 0.98  # TUNING (not in GDD)
## Distance (px) the content sinks while it closes.
const CLOSE_DROP: float = 3.0  # TUNING (not in GDD)
## Easing transition of the close (Tween.TRANS_*), eased out (it reacts on the very
## first frame, so Back feels instant).
const CLOSE_TRANS: Tween.TransitionType = Tween.TRANS_QUAD  # TUNING (not in GDD)

# --- Staggered entrance (UiMotion.stagger) -----------------------------------------------

## Seconds between two children starting their entrance (cards, rows, tiles).
const STAGGER_INTERVAL: float = 0.055  # TUNING (not in GDD)
## Seconds one child's entrance takes (fade, rise and grow to rest).
const STAGGER_TIME: float = 0.2  # TUNING (not in GDD)
## Default start offset (px) of a child from its rest position: below it, so
## it rises into place. Lists that slide in from the side pass their own.
const STAGGER_OFFSET: Vector2 = Vector2(0.0, 12.0)  # TUNING (not in GDD)
## Start offset (px) of list rows that slide in from the left instead of rising
## (the chest reward rows).
const LIST_SLIDE_OFFSET: Vector2 = Vector2(-14.0, 0.0)  # TUNING (not in GDD)
## Child scale at the start of its entrance (0..1; grows to 1 around its bottom centre).
const STAGGER_SCALE: float = 0.94  # TUNING (not in GDD)
## Easing transition of an entrance (Tween.TRANS_*): a slight overshoot settles it.
const STAGGER_TRANS: Tween.TransitionType = Tween.TRANS_BACK  # TUNING (not in GDD)

# --- Focus / hover lift (cards and tiles; automatic hook) --------------------------------

## Distance (px) a hovered or focused card / tile rises.
const LIFT_PX: float = 3.0  # TUNING (not in GDD)
## Seconds the lift (and its return) takes.
const LIFT_TIME: float = 0.09  # TUNING (not in GDD)
## Brightness factor of a lifted card's own frame (self_modulate RGB; 1 = unchanged).
const LIFT_BRIGHT: float = 1.12  # TUNING (not in GDD)
## A button lifts automatically when it is at least this tall (px)...
## (stage cards, Ossuary tiles, character tiles, difficulty cards; not plain
## buttons, toggles or key rows). Meta "ui_lift" true / false forces it.
const LIFT_MIN_HEIGHT: float = 56.0  # TUNING (not in GDD)
## ...and at most this wide (px): full-width menu bars and list rows do not lift.
const LIFT_MAX_WIDTH: float = 420.0  # TUNING (not in GDD)

# --- Press squash (every button; automatic hook) ------------------------------------------

## Smallest press scale (0..1): small buttons and tiles squash to this.
const PRESS_SCALE: float = 0.94  # TUNING (not in GDD)
## Largest inward travel (px per side) of the squash along a button's longer
## side, so wide buttons squash a few px instead of a big percentage.
const PRESS_MAX_PX: float = 4.0  # TUNING (not in GDD)
## Seconds the squash takes on press.
const PRESS_TIME: float = 0.05  # TUNING (not in GDD)
## Seconds the spring back to rest takes on release (with a small overshoot).
const RELEASE_TIME: float = 0.16  # TUNING (not in GDD)

# --- Number count-up (UiMotion.count_up) --------------------------------------------------

## Seconds a count-up takes from its start value to its end value.
const COUNT_TIME: float = 0.9  # TUNING (not in GDD)
## Seconds a count-up waits before it starts (lets its panel open first).
const COUNT_DELAY: float = 0.25  # TUNING (not in GDD)
## Pitch of the tick sound at the end of a count-up (it rises from 1.0 at the start).
const COUNT_TICK_PITCH_END: float = 1.5  # TUNING (not in GDD)

# --- Fade through black (UiMotion.transition: main menu <-> run, Restart) -----------------

## Seconds the screen takes to fade to black before the switch.
const FADE_OUT_TIME: float = 0.2  # TUNING (not in GDD)
## Seconds the screen stays black after the switch (covers the frame that builds
## the new run or menu).
const FADE_HOLD_TIME: float = 0.06  # TUNING (not in GDD)
## Seconds the screen takes to fade back in from black.
const FADE_IN_TIME: float = 0.3  # TUNING (not in GDD)
## Colour of the fade (the menu backdrop's near-black violet, fully opaque).
const FADE_COLOR: Color = Color(0.02, 0.0, 0.04, 1.0)  # TUNING (not in GDD)
## CanvasLayer index of the fade (above the run UI, layer 10, and the menu).
const FADE_LAYER: int = 120  # TUNING (not in GDD)
