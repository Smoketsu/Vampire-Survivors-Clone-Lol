## InRunUiData: the numbers of the in-run screens' presentation (menu
## modernization, wave 2 "in-run panels and HUD"): the level-up cards, the
## treasure-chest reveal, the pause screen, the results card (end screen),
## the HUD banner queue and the HUD bars. Purely cosmetic: none of these
## values reach gameplay, the seeded RNG or the autotest (every motion here is
## instant under the autotest and with "Reduce motion", UiMotion.enabled()).
## Sizes are layout px of the 1280x720 layout (x1.5 in a 1080p window); times
## are seconds (real time for panel effects, game time for HUD banners);
## art scales are whole numbers (layout px per art px). Data only, no logic.
class_name InRunUiData
extends RefCounted

# --- Effect strips in the UI (UiFx) ------------------------------------------------------

## Effect strip id -> real seconds one UI play-through takes (the strips of
## assets/sprites/effects/, AnimData; the UI plays them on its own clock).
const FX_TIME: Dictionary = {
	"level_up": 0.8,  # TUNING (not in GDD) the level-up title pillars (8 frames)
	"evolution": 0.9,  # TUNING (not in GDD) the evolution card / reward burst (10 frames)
	"chest_open": 0.6,  # TUNING (not in GDD) the chest bursting open (8 frames)
}

# --- Level-up panel (LevelUpPanel) ----------------------------------------------------------

## Opacity of the level-up backdrop (0..1): dark enough that nothing of the
## HUD competes with the cards.
const LEVEL_BACKDROP: float = 0.78  # TUNING (not in GDD)
## Card width (px; fixed so the text wraps predictably).
const CARD_WIDTH: float = 270.0  # TUNING (not in GDD)
## Card minimum height (px); cards grow to fit and the row stretches all three
## to the tallest.
const CARD_MIN_HEIGHT: float = 320.0  # TUNING (not in GDD)
## Card inner padding left / right (px).
const CARD_PAD_X: int = 14  # TUNING (not in GDD)
## Card inner padding top / bottom (px).
const CARD_PAD_Y: int = 12  # TUNING (not in GDD)
## Card icon side (px): the 32 art px badge icons at x2, crisp.
const CARD_ICON: float = 64.0  # TUNING (not in GDD)
## Gap between cards (px).
const CARD_GAP: int = 18  # TUNING (not in GDD)
## Width of an action-bar button (px; its key chip sits inside, left).
const ACTION_WIDTH: float = 210.0  # TUNING (not in GDD)
## Height of an action-bar button (px).
const ACTION_HEIGHT: float = 40.0  # TUNING (not in GDD)
## Distance (px) of each level-up light pillar outside the card row's left /
## right edge (the `level_up` column rises at both sides of the cards).
const PILLAR_MARGIN: float = 42.0  # TUNING (not in GDD)
## Whole-number scale of the level-up pillars (2 = the strip's 192 px frames
## drawn 384 px tall, about the card height).
const PILLAR_SCALE: int = 2  # TUNING (not in GDD)
## Seconds the right pillar starts after the left one.
const PILLAR_STAGGER: float = 0.08  # TUNING (not in GDD)
## Whole-number scale of the evolution burst over an evolution card's icon.
const EVO_FX_SCALE: int = 1  # TUNING (not in GDD)
## Gold sheen sweeping across an evolution card: colour (alpha = peak opacity).
const SHIMMER_COLOR := Color(1.0, 0.86, 0.45, 0.16)  # TUNING (not in GDD)
## Seconds between the starts of two sheen sweeps.
const SHIMMER_PERIOD: float = 2.6  # TUNING (not in GDD)
## Seconds one sheen sweep takes to cross the card.
const SHIMMER_SWEEP: float = 0.7  # TUNING (not in GDD)
## Width (px) of the sheen band.
const SHIMMER_BAND: float = 46.0  # TUNING (not in GDD)
## Seconds after the panel opens before the first sheen sweep.
const SHIMMER_DELAY: float = 0.6  # TUNING (not in GDD)

# --- Level pips (LevelPips) ------------------------------------------------------------------

## One level pip (px): width x height.
const PIP_SIZE := Vector2(16.0, 6.0)  # TUNING (not in GDD)
## Gap between two pips (px).
const PIP_GAP: float = 3.0  # TUNING (not in GDD)
## Colour of a level already owned.
const PIP_OWNED := Color(0.62, 0.42, 0.95)  # TUNING (not in GDD) violet: what you have
## Colour of the level this card grants (soul-teal = new).
const PIP_NEW := Color(0.45, 1.0, 0.78)  # TUNING (not in GDD) soul-teal: new
## Colour of an empty pip (a level still to come).
const PIP_EMPTY := Color(0.16, 0.12, 0.22)  # TUNING (not in GDD)
## Border colour of an empty pip.
const PIP_EMPTY_EDGE := Color(0.32, 0.24, 0.42)  # TUNING (not in GDD)
## Pulse speed (rad / s, real time) of the new pip's glow.
const PIP_PULSE: float = 5.0  # TUNING (not in GDD)

# --- Treasure chest (ChestPanel) ---------------------------------------------------------------

## Opacity of the chest backdrop (0..1).
const CHEST_BACKDROP: float = 0.78  # TUNING (not in GDD)
## Width of the chest panel's content column (px).
const CHEST_WIDTH: float = 440.0  # TUNING (not in GDD)
## Height of the chest stage (px): the chest, its glow and rays, the burst.
const CHEST_STAGE_HEIGHT: float = 132.0  # TUNING (not in GDD)
## Whole-number scale of the chest sprite (pickups/chest.png, 32 x 29 art px).
const CHEST_SCALE: int = 3  # TUNING (not in GDD)
## Art rows (from the top of chest.png) that form the lid; the lid lifts off
## the body when the chest opens.
const CHEST_LID_ROWS: int = 12  # TUNING (not in GDD)
## How far (art px) the lid rises when open.
const CHEST_LID_LIFT: int = 4  # TUNING (not in GDD)
## Seconds the closed chest rattles before it opens.
const CHEST_SHAKE_TIME: float = 0.32  # TUNING (not in GDD)
## Rattle amplitude (layout px, whole px steps).
const CHEST_SHAKE_PX: float = 2.0  # TUNING (not in GDD)
## Rattle frequency (rad / s).
const CHEST_SHAKE_FREQ: float = 60.0  # TUNING (not in GDD)
## Whole-number scale of the chest_open burst (1 = its 192 px frames).
const CHEST_FX_SCALE: int = 1  # TUNING (not in GDD)
## Number of light rays behind the open chest.
const RAY_COUNT: int = 10  # TUNING (not in GDD)
## Length (px) of a long vertical ray; short rays are RAY_SHORT of it (it
## ends inside the stage, so the rays never meet its clipped top edge).
const RAY_LENGTH: float = 60.0  # TUNING (not in GDD)
## Extra length of the sideways rays, as a fraction of RAY_LENGTH at the
## horizontal (the glow fans out wide across the stage).
const RAY_WIDEN: float = 1.4  # TUNING (not in GDD)
## Short-ray length as a fraction of RAY_LENGTH.
const RAY_SHORT: float = 0.62  # TUNING (not in GDD)
## Half-angle (rad) of one ray wedge.
const RAY_HALF_ANGLE: float = 0.07  # TUNING (not in GDD)
## Turn speed (rad / s, real time) of the rays.
const RAY_SPIN: float = 0.18  # TUNING (not in GDD)
## Ray colour (alpha = opacity at full open).
const RAY_COLOR := Color(1.0, 0.82, 0.4, 0.2)  # TUNING (not in GDD)
## Glow disc colour under the chest (alpha = opacity at full open).
const GLOW_COLOR := Color(0.95, 0.7, 0.3, 0.16)  # TUNING (not in GDD)
## Radius (px) of the glow under the chest.
const GLOW_RADIUS: float = 64.0  # TUNING (not in GDD)
## Seconds from opening the panel to the first reward row (the chest has
## rattled and burst by then).
const ROWS_START: float = 0.62  # TUNING (not in GDD)
## Seconds between two reward rows rising in.
const ROW_INTERVAL: float = 0.2  # TUNING (not in GDD)
## Reward row width (px).
const ROW_WIDTH: float = 400.0  # TUNING (not in GDD)
## Reward row icon side (px).
const ROW_ICON: float = 40.0  # TUNING (not in GDD)
## Start offset of a reward row's entrance (px): below, so it rises.
const ROW_RISE := Vector2(0.0, 14.0)  # TUNING (not in GDD)

# --- Pause screen (PauseMenu) -------------------------------------------------------------

## Width of the run-info column (px).
const PAUSE_INFO_WIDTH: float = 470.0  # TUNING (not in GDD)
## Width of the button column (px).
const PAUSE_BUTTON_WIDTH: float = 240.0  # TUNING (not in GDD)
## Height of a pause button (px).
const PAUSE_BUTTON_HEIGHT: float = 42.0  # TUNING (not in GDD)
## Gap between the two pause columns (px).
const PAUSE_GAP: int = 22  # TUNING (not in GDD)
## Build icon size on the pause screen (px; the icon square, pips below it).
const PAUSE_ICON: float = 32.0  # TUNING (not in GDD)

# --- Results card (EndScreen) -------------------------------------------------------------

## Width of the portrait column (px).
const END_PORTRAIT_WIDTH: float = 196.0  # TUNING (not in GDD)
## Height of the portrait frame (px).
const END_PORTRAIT_HEIGHT: float = 200.0  # TUNING (not in GDD)
## Whole-number scale the character sprite is drawn at (the largest that fits
## the frame is used when this is too big).
const END_PORTRAIT_SCALE: int = 3  # TUNING (not in GDD)
## Width of the stats + build column (px).
const END_STATS_WIDTH: float = 352.0  # TUNING (not in GDD)
## Width of the Soul Ash column (px).
const END_ASH_WIDTH: float = 312.0  # TUNING (not in GDD)
## Gap between the three columns (px).
const END_GAP: int = 22  # TUNING (not in GDD)
## Height of one stat tile (px).
const END_TILE_HEIGHT: float = 58.0  # TUNING (not in GDD)
## Build / army icon size on the results card (px).
const END_ICON: float = 32.0  # TUNING (not in GDD)
## Width of a results button (px).
const END_BUTTON_WIDTH: float = 230.0  # TUNING (not in GDD)
## Width (px) of the ribbon holding the Victory / Defeat title.
const END_RIBBON_WIDTH: float = 380.0  # TUNING (not in GDD)
## Seconds after the panel opens before the Soul Ash lines start ticking in.
const ASH_LINES_DELAY: float = 0.35  # TUNING (not in GDD)
## Seconds between two Soul Ash lines ticking in.
const ASH_LINE_INTERVAL: float = 0.09  # TUNING (not in GDD)
## Seconds after the panel opens before the unlock plates rise in.
const TOAST_DELAY: float = 1.05  # TUNING (not in GDD)
## Stage id -> floor tile drawn (darkened) behind the character portrait.
const STAGE_TILES: Dictionary = {
	"graveyard": "tiles/graveyard",  # TUNING (not in GDD)
	"crimson_march": "tiles/march_road",  # TUNING (not in GDD)
	"sanctum": "tiles/sanctum_courtyard",  # TUNING (not in GDD)
}
## Darkening of the portrait's floor tile (0 = as is, 1 = black).
const PORTRAIT_TILE_DARKEN: float = 0.25  # TUNING (not in GDD)

# --- HUD banners (HudBanners) ---------------------------------------------------------------

## Top of the banner stack (px from the screen top): under the timer, zone
## and objective lines.
const BANNER_TOP: float = 112.0  # TUNING (not in GDD)
## Widest one-line headline (px) on the ribbon; a longer one is split at its
## colon (the rest becomes the sub-line), then drawn in a smaller tier.
const BANNER_MAX_WIDTH: float = 640.0  # TUNING (not in GDD)
## Game seconds an announcement (evolution, synergy, zone) stays fully shown.
const ANNOUNCE_HOLD: float = 3.5  # TUNING (not in GDD) the old ANNOUNCE_TIME
## Game seconds a banner fades / rises in.
const BANNER_IN: float = 0.25  # TUNING (not in GDD)
## Game seconds a banner fades / rises out.
const BANNER_OUT: float = 0.35  # TUNING (not in GDD)
## Distance (px) a banner rises while it fades in (it starts this far lower).
const BANNER_RISE: float = 10.0  # TUNING (not in GDD)
## Distance (px) a banner rises further while it fades out.
const BANNER_RISE_OUT: float = 6.0  # TUNING (not in GDD)
## Game seconds a banner is guaranteed on screen before a queued one may cut it short.
const BANNER_MIN_SHOW: float = 1.4  # TUNING (not in GDD)
## Most banners waiting in the queue (the oldest waiting one is dropped beyond this).
const BANNER_QUEUE_MAX: int = 3  # TUNING (not in GDD)
## Announcement titles containing one of these words get the gold ribbon
## (evolutions, synergies); other announcements are violet.
const GOLD_TITLE_WORDS: Array[String] = ["EVOLUTION", "SYNERGY"]  # TUNING (not in GDD)
## Event banners containing one of these words are good news for the player
## (violet ribbon); every other event banner is a Covenant / boss event (crimson).
const CALM_EVENT_WORDS: Array[String] = ["destroyed", "shatters", "crumbles", "cleansed", "spoils", "got away", "rots away", "extinguished", "falls", "slain", "answers"]  # TUNING (not in GDD)

# --- HUD bars (Hud, HudBar) --------------------------------------------------------------------

## XP bar inset from the screen's left / right edges (px).
const XP_INSET_X: float = 6.0  # TUNING (not in GDD)
## XP bar top (px from the screen top; its kit frame sits 1 px outside it).
const XP_TOP: float = 4.0  # TUNING (not in GDD)
## XP bar height (px): room for the 19 px numbers without touching the frame.
const XP_HEIGHT: float = 15.0  # TUNING (not in GDD)
## HP bar size (px).
const HP_SIZE := Vector2(240.0, 20.0)  # TUNING (not in GDD)
## Size (px) of the Act II Dread meter under the HP bar.
const DREAD_SIZE := Vector2(240.0, 12.0)  # TUNING (not in GDD)
## HP bar notches: one dark notch every this fraction of the bar (0 = none).
const HP_NOTCH: float = 0.25  # TUNING (not in GDD)
## Seconds (real time) the HP bar's damage trail waits before it drains.
const TRAIL_HOLD: float = 0.35  # TUNING (not in GDD)
## Fraction of the bar per second (real time) the damage trail drains.
const TRAIL_DRAIN: float = 0.9  # TUNING (not in GDD)
## Damage trail colour (the HP just lost).
const TRAIL_COLOR := Color(1.0, 0.9, 0.75, 0.85)  # TUNING (not in GDD)
