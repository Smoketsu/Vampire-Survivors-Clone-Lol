## CasketUiData: layout, timing, colour and word numbers of the Ossuary's Caskets
## tab (OssuaryCasketsPanel; GDD §15.0 "Recolour Caskets (owner request, Oct
## 2026)"). Purely visual: the price, tiers and odds live in CasketData. Sizes are
## layout px (the 1280x720 layout); times are real seconds (UI motion, unscaled;
## instant under the autotest and with Reduce motion). Data only, no logic.
class_name CasketUiData
extends RefCounted

# --- Layout -----------------------------------------------------------------------------

## Width (layout px) of the whole tab (like the Relics tab: the tree columns' width).
const PANEL_WIDTH: float = 1200.0  # TUNING (not in GDD) = RelicUiData.PANEL_WIDTH
## Gap (layout px) between the stage panel and the info column.
const COLUMN_GAP: int = 24  # TUNING (not in GDD)
## Size (layout px) of the reveal stage (the casket, its light and the prize).
const STAGE_SIZE := Vector2(560, 380)  # TUNING (not in GDD) fits the 548 px page with the name lines
## Width (layout px) of the info column right of the stage panel.
const INFO_WIDTH: float = 560.0  # TUNING (not in GDD)
## Gap (layout px) between the info column's blocks.
const INFO_GAP: int = 10  # TUNING (not in GDD)
## Size (layout px) of the Open and Wear buttons.
const BUTTON_SIZE := Vector2(190, 44)  # TUNING (not in GDD) one NAME-tier word and a chip
## Gap (layout px) between the Open and Wear buttons.
const BUTTON_GAP: int = 12  # TUNING (not in GDD)
## Gap (layout px) between two tier odds on the odds line.
const ODDS_GAP: int = 18  # TUNING (not in GDD)

# --- The casket on the stage ------------------------------------------------------------

## Sprite key of the casket art (the treasure chest; no new art).
const CASKET_SPRITE: String = "pickups/chest"  # TUNING (not in GDD) reuses the chest art
## Whole-number scale (layout px per art px) of the casket art (32 x 29 art px).
const CASKET_SCALE: int = 5  # TUNING (not in GDD)
## Distance (layout px) from the stage's bottom edge to the casket's bottom.
const CASKET_BOTTOM: float = 28.0  # TUNING (not in GDD)
## Art rows (from the top) that are the lid (as InRunUiData.CHEST_LID_ROWS).
const LID_ROWS: int = 12  # TUNING (not in GDD) the chest art's lid
## How far (art px) the lid flies up as it opens.
const LID_FLY: float = 26.0  # TUNING (not in GDD)
## Turn (radians) of the flying lid at the end of its flight.
const LID_SPIN: float = 0.35  # TUNING (not in GDD)
## Side (layout px) of the prize portrait box (the skin drawn inside it).
const PORTRAIT_BOX := Vector2(196, 196)  # TUNING (not in GDD) a 56 px character sprite at x3
## Height (layout px) the portrait settles at, its centre below the stage's top edge.
const PORTRAIT_Y: float = 120.0  # TUNING (not in GDD)
## Portrait scale while it leaves the casket (grows to 1).
const PORTRAIT_START_SCALE: float = 0.35  # TUNING (not in GDD)
## Radius (layout px) of the soft glow behind the casket / the prize.
const GLOW_RADIUS: float = 120.0  # TUNING (not in GDD)
## Share (0..1) of GLOW_RADIUS the glow has before a casket is opened (it grows
## to the full radius as the casket rattles; small enough to stay inside the stage).
const GLOW_IDLE_SCALE: float = 0.78  # TUNING (not in GDD)
## Steps of that glow (stepped discs, the pixel look).
const GLOW_STEPS: int = 4  # TUNING (not in GDD)
## Glow opacity (0..1) before a casket is opened (violet, waiting).
const GLOW_IDLE_ALPHA: float = 0.16  # TUNING (not in GDD)
## Glow opacity (0..1) at its peak, in the tier colour.
const GLOW_ALPHA: float = 0.32  # TUNING (not in GDD)
## Colour of the idle glow (soul violet).
const GLOW_IDLE := Color(0.55, 0.36, 0.9)  # TUNING (not in GDD) palette violet
## Number of light rays behind the prize.
const RAY_COUNT: int = 12  # TUNING (not in GDD)
## Length (layout px) of a long ray (short rays are RAY_SHORT of it).
const RAY_LENGTH: float = 210.0  # TUNING (not in GDD)
## Short-ray length as a fraction of RAY_LENGTH.
const RAY_SHORT: float = 0.6  # TUNING (not in GDD)
## Half-width (radians) of a ray.
const RAY_HALF_ANGLE: float = 0.06  # TUNING (not in GDD)
## Ray turning speed (radians per second, during the reveal only).
const RAY_SPIN: float = 0.5  # TUNING (not in GDD)
## Ray opacity (0..1), in the tier colour.
const RAY_ALPHA: float = 0.2  # TUNING (not in GDD)
## Whole-number scale of the `chest_open` burst strip over the casket.
const BURST_SCALE: int = 2  # TUNING (not in GDD)
## Stage ground colour (behind everything).
const STAGE_BG := Color(0.03, 0.02, 0.05, 0.9)  # TUNING (not in GDD)
## Tint of the casket while no prize is left (an empty, dimmed casket).
const EMPTY_TINT := Color(0.45, 0.42, 0.52)  # TUNING (not in GDD)

# --- Reveal timing (real seconds; under ~1.5 s in all) ------------------------------------

## The casket rattles this long, harder and harder, before it opens.
const SHAKE_TIME: float = 0.45  # TUNING (not in GDD)
## Peak rattle (layout px).
const SHAKE_PX: float = 4.0  # TUNING (not in GDD)
## Rattle speed (radians per second of the sine).
const SHAKE_FREQ: float = 58.0  # TUNING (not in GDD)
## The lid's flight after the rattle.
const LID_TIME: float = 0.3  # TUNING (not in GDD)
## The prize rising out of the casket to its place, after the rattle.
const RISE_TIME: float = 0.45  # TUNING (not in GDD)
## The prize's name and tier fade in this long, once the prize has risen.
const TEXT_TIME: float = 0.25  # TUNING (not in GDD)
## Total reveal length: rattle + rise + text (about 1.15 s).
const REVEAL_TIME: float = SHAKE_TIME + RISE_TIME + TEXT_TIME  # TUNING (not in GDD)

# --- Sounds (existing ids, Sfx.play_ui()) --------------------------------------------------

## Played as the casket starts to rattle.
const SOUND_START: String = "panel_open"  # TUNING (not in GDD)
## Tier id -> the sound as the casket bursts open (a bigger one for Epic and up).
const SOUND_REVEAL := {"common": "purchase", "rare": "purchase", "epic": "chest_open", "legendary": "chest_open"}  # TUNING (not in GDD)

# --- Words (few) ----------------------------------------------------------------------------

## Header of the info column.
const HEADER: String = "Recolour Caskets"  # TUNING (not in GDD)
## The one line under it.
const LINE: String = "Each casket holds a recolour you don't own yet. Never a duplicate."  # TUNING (not in GDD)
## The Open button.
const OPEN: String = "Open"  # TUNING (not in GDD)
## The Wear button (after a reveal).
const WEAR: String = "Wear"  # TUNING (not in GDD)
## The Wear button once the prize is worn.
const WORN: String = "Worn"  # TUNING (not in GDD)
## Stage caption before anything was opened (this visit).
const IDLE_NAME: String = "A sealed casket"  # TUNING (not in GDD)
## Stage caption when every prize is found.
const EMPTY_NAME: String = "Every recolour found"  # TUNING (not in GDD)
## Status line: the balance cannot pay a casket.
const SHORT_LINE: String = "Not enough Soul Ash."  # TUNING (not in GDD)
## Status line: no prize left.
const EMPTY_LINE: String = "Nothing left to find: every casket is empty."  # TUNING (not in GDD)
## Status line on a touchscreen after the first tap.
const TAP_AGAIN: String = "Tap again to open."  # TUNING (not in GDD)
## Odds line label (LABEL tier).
const ODDS_LABEL: String = "Odds"  # TUNING (not in GDD)
## One tier on the odds line: tier name, chance in percent.
const ODDS_ENTRY: String = "%s %d%%"  # TUNING (not in GDD)
## Pity line (%d = caskets left, counting the pity one).
const PITY_LINE: String = "Epic or better within %d"  # TUNING (not in GDD)
## Pity line when the next casket is the pity one.
const PITY_NEXT: String = "Next casket: Epic or better"  # TUNING (not in GDD)
## Collection line (owned recolours / all of the unlocked skins').
const COLLECTION: String = "Recolours %d / %d"  # TUNING (not in GDD)
## Collection line part for casket-only skins (shown only once some exist).
const COLLECTION_SKINS: String = "Skins %d / %d"  # TUNING (not in GDD)
## Tooltip of the Wear button.
const WEAR_TIP: String = "Wear it on that skin next run"  # TUNING (not in GDD)
