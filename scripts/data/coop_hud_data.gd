## CoopHudData: numbers, colours and texts of the co-op visuals (docs/coop/DESIGN.md
## "Camera, HUD and input"; GDD §15.0 "Co-op HUD and visuals"). Everything here
## is drawing only: the partner's HP plate on the HUD (CoopPartnerBar), the
## edge arrow toward an off-screen partner (CoopArrows), the downed marker with
## its revive ring and radius circle in the world (CoopMarkers), the "your
## partner can raise you" plate (CoopUi), the non-blocking waiting panel
## (CoopWaiting), the co-op column of the results card (CoopResults) and the
## debug sequence that shows each state for screenshots (CoopUiTest). Nothing
## of it exists in a solo run (Game.coop is null). The revive numbers
## themselves (radius, time) are gameplay and live in CoopData; these only
## draw them. Sizes are layout px (1280 x 720 design layout) unless named
## world px or CSS px. Data only, no logic.
class_name CoopHudData
extends RefCounted

# --- Colours (UI colour language: violet base, crimson = danger, soul-teal = the partner / focus) ---

## The partner's identity colour (soul-teal, like the touch joystick and the
## focus ring): the arrow badge rim and pointer, the plate's name.
const PARTNER := Color(0.42, 0.95, 0.75)  # TUNING (not in GDD)
## Lit soul-teal of the arrow pointer's top edge and its pulse ring.
const PARTNER_LIGHT := Color(0.75, 1.0, 0.88)  # TUNING (not in GDD)
## Crimson of a downed necromancer (marker, plate, arrow): danger.
const DOWNED := Color(0.86, 0.2, 0.24)  # TUNING (not in GDD) Palette.CRIMSON, a little lighter so it reads on dark floors
## Lit crimson of the downed marker's edges and the "Downed" text.
const DOWNED_LIGHT := Color(1.0, 0.55, 0.52)  # TUNING (not in GDD)
## Revive progress (the ring and the plate's bar while raising): the necro
## green the game already uses for "RAISED" (CoopSession._revive()).
const REVIVE := Color(0.42, 0.95, 0.55)  # TUNING (not in GDD) Palette.NECRO_GREEN
## Dark rim under every code-drawn shape, so it reads on the light floors.
const INK := Color(0.07, 0.04, 0.09)  # TUNING (not in GDD)
## Dark plate inside the arrow badge (behind the partner's bust).
const PLATE := Color(0.08, 0.05, 0.12, 0.95)  # TUNING (not in GDD) UiTheme.BG

# --- Partner plate on the HUD (top right, under the kill count) --------------------------

## Size (px) of the partner's bust portrait in its kit slot frame.
const PLATE_PORTRAIT := Vector2(40.0, 40.0)  # TUNING (not in GDD)
## Drop (px) of the bust inside the portrait: the sprite's centre sits this far
## below the frame's top, so the head and shoulders show (the frame clips the rest).
const PORTRAIT_DROP: float = 27.0  # TUNING (not in GDD) 56 px sprites: head and shoulders in 40 px
## Size (px) of the partner's HP bar (compact: half the width of the local one).
const PLATE_BAR := Vector2(170.0, 10.0)  # TUNING (not in GDD)
## Gap (px) between the portrait and the name / bar column.
const PLATE_GAP: int = 6  # TUNING (not in GDD)
## Text after the name while the partner lies downed (crimson).
const TEXT_DOWNED: String = "Downed"  # TUNING (not in GDD)
## Text after the name while the local player stands raising the partner.
const TEXT_RAISING: String = "Raising"  # TUNING (not in GDD)
## Period (s, real time) of the downed plate's slow crimson pulse (still with
## Reduce motion and under the autotest).
const PLATE_PULSE_PERIOD: float = 1.2  # TUNING (not in GDD)
## Lowest opacity (0-1) of the downed plate's pulse.
const PLATE_PULSE_MIN: float = 0.55  # TUNING (not in GDD)

# --- Off-screen partner arrow (layout px; laid out like the chest arrows, ChestBeacon) ---

## Radius (px) of the round arrow badge (the partner's bust inside it).
const ARROW_BADGE_RADIUS: float = 16.0  # TUNING (not in GDD) larger than the 10 px chest badge: a face must read on a phone
## Width (px) of the badge's soul-teal (crimson when downed) rim.
const ARROW_RIM: float = 2.0  # TUNING (not in GDD)
## Width (px) and opacity (0-1) of the soft dark halo round the badge, so it
## reads over a crowd of units.
const ARROW_HALO: float = 5.0  # TUNING (not in GDD)
const ARROW_HALO_ALPHA: float = 0.5  # TUNING (not in GDD)
## Distance (px) from the badge centre to the pointer's base.
const ARROW_POINTER_GAP: float = 17.0  # TUNING (not in GDD) just outside the badge
## Length (px) of the pointer triangle, base to tip.
const ARROW_POINTER_LENGTH: float = 13.0  # TUNING (not in GDD)
## Half-width (px) of the pointer's base.
const ARROW_POINTER_HALF_WIDTH: float = 9.0  # TUNING (not in GDD)
## Drop (px) of the bust inside the badge (as PORTRAIT_DROP, for the 32 px badge).
const ARROW_BUST_DROP: float = 20.0  # TUNING (not in GDD)
## World px past the view edge at which the arrow is at its faintest.
const ARROW_FAR_DISTANCE: float = 1200.0  # TUNING (not in GDD)
## Opacity (0-1) of the arrow just off screen and at ARROW_FAR_DISTANCE or beyond
## (never fainter: the partner always stays findable).
const ARROW_ALPHA_NEAR: float = 1.0  # TUNING (not in GDD)
const ARROW_ALPHA_FAR: float = 0.7  # TUNING (not in GDD) the faintest the arrow gets
## Seconds (real time) of one pulse ring out of the badge while the partner is
## downed (no ring with Reduce motion or Effects: Reduced).
const ARROW_PULSE_PERIOD: float = 1.0  # TUNING (not in GDD)
## Radius (px) of that pulse ring as it starts and as it has faded out.
const ARROW_PULSE_START: float = 17.0  # TUNING (not in GDD)
const ARROW_PULSE_END: float = 34.0  # TUNING (not in GDD) radius when the ring has faded out
## Push (px) of the badge toward the partner at the top of its nudge (real
## time, still with Reduce motion).
const ARROW_NUDGE: float = 3.0  # TUNING (not in GDD)
## Seconds (real time) of one nudge out and back.
const ARROW_NUDGE_PERIOD: float = 0.9  # TUNING (not in GDD)
## Height (world px) of the partner's name tag baseline above his centre while
## he is on screen (over his 56 px figure's head; scaled by the camera zoom).
const TAG_LIFT: float = 34.0  # TUNING (not in GDD)

# --- Downed marker in the world (world px; CoopMarkers) ----------------------------------

## Draw layer (z_index) of the markers: above the units and effects, beside the
## chest beacon (18), under the damage numbers (FxLayer 20).
const MARKER_Z: int = 19  # TUNING (not in GDD)
## Radius (world px) of the revive progress ring round the downed necromancer.
const RING_RADIUS: float = 24.0  # TUNING (not in GDD) round a 56 px figure's middle
## Width (world px) of the progress ring; its dark track is this + 2.
const RING_WIDTH: float = 4.0  # TUNING (not in GDD)
## Opacity (0-1) of the ring's empty track.
const RING_TRACK_ALPHA: float = 0.55  # TUNING (not in GDD)
## Points on a full ring arc.
const RING_POINTS: int = 40  # TUNING (not in GDD)
## Opacity (0-1) of the faint circle drawn at CoopData.REVIVE_RADIUS (the reach
## the partner must stand in), and its fill.
const RADIUS_ALPHA: float = 0.45  # TUNING (not in GDD)
const RADIUS_FILL_ALPHA: float = 0.07  # TUNING (not in GDD) the circle's faint fill
## The radius circle is drawn as this many dashes.
const RADIUS_DASHES: int = 24  # TUNING (not in GDD)
## Height (world px) of the downed marker (a crimson down-chevron) above the
## necromancer's centre, at the bottom of its bob.
const MARKER_LIFT: float = 44.0  # TUNING (not in GDD) over a 56 px figure's head
## Height (world px, whole) of the marker's bob; seconds (real time) of one bob.
const MARKER_BOB: float = 3.0  # TUNING (not in GDD)
const MARKER_BOB_PERIOD: float = 1.0  # TUNING (not in GDD)
## Half-width and height (world px) of the downed chevron.
const MARKER_HALF_WIDTH: float = 9.0  # TUNING (not in GDD)
const MARKER_HEIGHT: float = 11.0  # TUNING (not in GDD)

# --- "Your partner can raise you" plate (the local player downed) ------------------------

## Kicker and line of the plate shown to a downed local player.
const SELF_DOWNED_TITLE: String = "Downed"  # TUNING (not in GDD)
const SELF_DOWNED_TEXT: String = "Your partner can raise you"  # TUNING (not in GDD)
## Line while the partner is raising (stands in reach).
const SELF_RAISING_TEXT: String = "Your partner is raising you"  # TUNING (not in GDD)
## Line when both are down (the run is ending).
const SELF_ALONE_TEXT: String = "Both fallen"  # TUNING (not in GDD)
## Distance (px) of the plate's centre below the screen's middle: under the
## necromancer (the camera centre) and his revive circle, clear of the banner
## slot above him (the "has fallen" banner) and of the ability bar below.
const SELF_PLATE_DROP: float = 112.0  # TUNING (not in GDD)
## Width (px) of the plate's progress bar.
const SELF_BAR_WIDTH: float = 220.0  # TUNING (not in GDD)

# --- Waiting panel (CoopUi.show_waiting) -------------------------------------------------

## Headline of the waiting panel (the caller's text is the line under it).
const WAITING_TITLE: String = "Waiting for partner"  # TUNING (not in GDD)
## CanvasLayer of the waiting panel: over the HUD and the run's panels (UI
## layer 10), so a "Your partner is choosing a card" shows over a closed or
## open panel alike; it is small and never takes input.
const WAITING_LAYER: int = 11  # TUNING (not in GDD)
## Distance (px) of the panel's bottom above the screen's bottom edge: over the
## ability bar and the Grave Step / ultimate meters (130 px), between the touch
## joystick and the buttons on a phone.
const WAITING_BOTTOM: float = 150.0  # TUNING (not in GDD)
## Minimum width (px) of the waiting panel.
const WAITING_WIDTH: float = 360.0  # TUNING (not in GDD)
## Soul dots of the waiting animation, their radius and spacing (px).
const WAITING_DOTS: int = 3  # TUNING (not in GDD)
const WAITING_DOT_RADIUS: float = 3.0  # TUNING (not in GDD)
const WAITING_DOT_SPACING: float = 12.0  # TUNING (not in GDD)
## Seconds (real time) of one wave through the dots (they hold still with
## Reduce motion and under the autotest).
const WAITING_DOT_PERIOD: float = 1.2  # TUNING (not in GDD)
## Opacity (0-1) of a resting dot and of the lit one.
const WAITING_DOT_DIM: float = 0.3  # TUNING (not in GDD)
const WAITING_DOT_LIT: float = 1.0  # TUNING (not in GDD)

# --- Notices (CoopUi.notice, through the HUD banner queue) -------------------------------

## Kicker of a co-op notice banner.
const NOTICE_KICKER: String = "Co-op"  # TUNING (not in GDD)
## Seconds (game time) a notice banner holds.
const NOTICE_HOLD: float = 4.0  # TUNING (not in GDD)

# --- Results card, co-op column (CoopResults) --------------------------------------------

## Width (px) of the co-op column (it takes the portrait / seal column's place).
const RESULTS_WIDTH: float = 340.0  # TUNING (not in GDD)
## Size (px) of each player's bust portrait on the results card.
const RESULTS_PORTRAIT := Vector2(52.0, 52.0)  # TUNING (not in GDD)
## Drop (px) of the bust in the results portrait (as PORTRAIT_DROP).
const RESULTS_PORTRAIT_DROP: float = 30.0  # TUNING (not in GDD)
## Side (px) of the build icons (spells, then passives) on a player card.
const RESULTS_ICON: float = 22.0  # TUNING (not in GDD) 12 icons in a 340 px column
## Most build icons in one row on a player card (spells and passives share it).
const RESULTS_ICONS_PER_ROW: int = 12  # TUNING (not in GDD)
## Tag on the local player's card.
const TEXT_YOU: String = "You"  # TUNING (not in GDD)

# --- Debug sequence (--coop-ui-test / --coop-shots; CoopUiTest) --------------------------

## Game second of each step of the debug sequence (shots in this order): the
## HUD with the partner on screen; the waiting panel and its texts; a notice
## banner; the downed partner (the run's --coop-down= decides when; the shot
## waits until the ring is part-filled, up to DOWNED_UNTIL); then the
## off-screen arrow (searched at the Close zoom once nobody is down, until
## ARROW_UNTIL: the bots often walk together, so the search is long); the end
## of the run (the results card).
const TEST_HUD_AT: float = 22.0  # TUNING (not in GDD) debug only
const TEST_WAITING_AT: float = 26.0  # TUNING (not in GDD) debug only
const TEST_NOTICE_AT: float = 33.0  # TUNING (not in GDD) debug only
const TEST_DOWNED_UNTIL: float = 90.0  # TUNING (not in GDD) debug only
const TEST_ARROW_UNTIL: float = 420.0  # TUNING (not in GDD) debug only
## World px past the view edge the partner must be for the arrow shot (off
## screen, not a figure cut through the middle by the edge).
const TEST_ARROW_MIN_PAST: float = 24.0  # TUNING (not in GDD) debug only
const TEST_END_DELAY: float = 2.0  # TUNING (not in GDD) debug only: s after the arrow shot
## Seconds (game time) each waiting text stays before the next one.
const TEST_WAITING_STEP: float = 1.5  # TUNING (not in GDD) debug only
## The waiting texts the sequence cycles through (the lockstep driver's states).
const TEST_WAITING_TEXTS: Array[String] = ["Your partner is choosing a card", "Paused by your partner", "Connection is slow"]  # TUNING (not in GDD) debug only
## The notice the sequence raises.
const TEST_NOTICE_TEXT: String = "Your partner left. A bot took over."  # TUNING (not in GDD) debug only
## Revive progress share (0-1 of CoopData.REVIVE_TIME) the downed shot waits for.
const TEST_RING_SHARE: float = 0.4  # TUNING (not in GDD) debug only
## Real seconds the Web build holds the world still at each shot (time scale 0,
## drawing goes on), so a browser screenshot catches it.
const TEST_WEB_HOLD: float = 6.0  # TUNING (not in GDD) debug only
## Real seconds a native window waits after a step before saving its PNG
## (the panel and banner settle; motion is instant under the autotest).
const TEST_SHOT_DELAY: float = 0.3  # TUNING (not in GDD) debug only
