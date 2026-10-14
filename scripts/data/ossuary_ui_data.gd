## OssuaryUiData: layout, timing and colour numbers of the Ossuary screen
## (OssuaryMenu, OssuaryTile, menu modernization wave 2, GDD §15.0 "Ossuary
## redesign"). Purely visual: nothing here changes a cost, a tier or a stat
## (those live in MetaData). Sizes are layout px (the 1280x720 layout, x1.5 in
## a 1080p window); times are real seconds (UI motion, unscaled). Data only,
## no logic.
class_name OssuaryUiData
extends RefCounted

# --- Layout ---------------------------------------------------------------------------

## Size (layout px) of one upgrade tile: icon, name, level pips and cost. Four
## columns of 282 + three 24 px gaps fill 1200 of the 1280 px layout.
const TILE_SIZE := Vector2(282, 56)  # TUNING (not in GDD) layout fit
## Gap (layout px) between two tree columns.
const COLUMN_GAP: int = 24  # TUNING (not in GDD) layout fit
## Gap (layout px) between two tiles of one column (six Necromancy tiles fit).
const ROW_GAP: int = 5  # TUNING (not in GDD) layout fit
## Side (layout px) of the upgrade icon on a tile: the 32 art px badge, 1:1.
const TILE_ICON: float = 32.0  # TUNING (not in GDD) art pass badges are 32 art px
## Side (layout px) of the icon in the detail panel: the badge at x2.
const DETAIL_ICON: float = 64.0  # TUNING (not in GDD) art pass badges are 32 art px
## Side (layout px) of a tree emblem in its header band (the badge, 1:1).
const TREE_ICON: float = 32.0  # TUNING (not in GDD)
## Side (layout px) of the Soul Ash badge next to the balance (the badge, 1:1).
const BALANCE_ICON: float = 32.0  # TUNING (not in GDD)
## Side (layout px) of the small bare Soul Ash symbol next to a cost.
const COST_ICON: float = 16.0  # TUNING (not in GDD) icons/soul_ash_small is 16 art px
## Inner padding (layout px) of a tile: left / right and top / bottom.
const TILE_PAD := Vector2(10, 6)  # TUNING (not in GDD)
## Gap (layout px) between a tile's icon and its texts.
const TILE_ICON_GAP: int = 10  # TUNING (not in GDD)
## Height (layout px) of the bottom-row buttons (Lower Oath, Refund all, Back).
const BUTTON_HEIGHT: float = 40.0  # TUNING (not in GDD) holds one NAME-tier line
## Gap (layout px) between the screen's main blocks (title, trees, bottom).
const BLOCK_GAP: int = 12  # TUNING (not in GDD)
## Top margin (layout px) of the screen's content.
const TOP_MARGIN: float = 14.0  # TUNING (not in GDD)

# --- Level pips -------------------------------------------------------------------------

## Size (layout px) of one level pip on a tile (cut corners, 1 px).
const PIP_SIZE := Vector2i(10, 5)  # TUNING (not in GDD)
## Size (layout px) of one level pip in the detail panel.
const PIP_SIZE_BIG := Vector2i(16, 7)  # TUNING (not in GDD)
## Gap (layout px) between two pips.
const PIP_GAP: int = 3  # TUNING (not in GDD)
## Fill of an owned tier's pip (soul teal: bought power).
const PIP_OWNED := Color(0.24, 0.8, 0.58)  # TUNING (not in GDD) palette soul #3DCC94
## Fill of every pip once the upgrade is maxed (gold: complete).
const PIP_MAXED := Color(0.88, 0.66, 0.18)  # TUNING (not in GDD) palette gold #E0A92E
## Fill of an Oath tier that is owned and active (crimson: the Oath).
const PIP_OATH := Color(0.86, 0.16, 0.2)  # TUNING (not in GDD) palette crimson
## Fill of an Oath tier that is owned but lowered (inactive).
const PIP_OATH_IDLE := Color(0.42, 0.1, 0.14)  # TUNING (not in GDD) palette crimson_dark
## Fill of a tier not bought yet (an empty socket).
const PIP_EMPTY := Color(0.11, 0.08, 0.16)  # TUNING (not in GDD)
## 1 px rim of an empty pip socket.
const PIP_RIM := Color(0.4, 0.32, 0.55)  # TUNING (not in GDD)

# --- Colours ----------------------------------------------------------------------------

## Colour of the Soul Ash balance and of costs (ember orange, the currency).
const ASH_COLOR := Color(1.0, 0.66, 0.38)  # TUNING (not in GDD) MetaGlyphs.EMBER lightened
## Colour of a cost the player cannot afford yet.
const COST_SHORT := Color(0.84, 0.46, 0.46)  # TUNING (not in GDD)
## Colour of a locked upgrade's prerequisite line and the "denied" flash.
const DENIED := Color(0.95, 0.35, 0.35)  # TUNING (not in GDD)
## Tint of a locked upgrade's icon (dark, desaturated look).
const LOCKED_ICON_TINT := Color(0.42, 0.4, 0.48)  # TUNING (not in GDD)
## Colour of the padlock drawn on a locked tile's icon.
const LOCK_COLOR := Color(0.78, 0.74, 0.66)  # TUNING (not in GDD) bone
## Colour of the padlock's dark outline.
const LOCK_INK := Color(0.09, 0.06, 0.05)  # TUNING (not in GDD) ink_warm

# --- Purchase feedback (real time, instant with Reduce motion) -------------------------

## Length (s) of the bright flash over a tile when one of its tiers is bought.
const FLASH_TIME: float = 0.28  # TUNING (not in GDD)
## Peak opacity (0..1) of that flash.
const FLASH_ALPHA: float = 0.55  # TUNING (not in GDD)
## Colour of the purchase flash (soul glow).
const FLASH_COLOR := Color(0.66, 1.0, 0.82)  # TUNING (not in GDD) palette soul_glow
## Number of pixel sparks in a purchase burst.
const BURST_COUNT: int = 14  # TUNING (not in GDD)
## Life (s) of a burst spark.
const BURST_TIME: float = 0.5  # TUNING (not in GDD)
## Launch speed range (layout px / s) of a burst spark.
const BURST_SPEED := Vector2(70.0, 150.0)  # TUNING (not in GDD)
## Downward pull (layout px / s^2) on burst sparks (they arc and fall).
const BURST_GRAVITY: float = 260.0  # TUNING (not in GDD)
## Side (layout px) of a burst spark (2 = one readable pixel blob).
const BURST_PX: float = 2.0  # TUNING (not in GDD)
## Burst spark colours (soul teal, soul glow, ember, bone), picked at random
## by the tile's private cosmetic RNG.
const BURST_COLORS: Array[Color] = [Color(0.24, 0.8, 0.58), Color(0.66, 1.0, 0.82), Color(1.0, 0.55, 0.15), Color(0.91, 0.88, 0.78)]  # TUNING (not in GDD) palette
## Length (s) of the "denied" shake of a tile (locked, too expensive, maxed).
const SHAKE_TIME: float = 0.24  # TUNING (not in GDD)
## Amplitude (layout px) of that shake.
const SHAKE_PX: float = 3.0  # TUNING (not in GDD)
## Shake oscillations per second.
const SHAKE_HZ: float = 22.0  # TUNING (not in GDD)
## Length (s) of the Soul Ash balance counting down after a purchase (or up
## after a refund).
const COUNT_TIME: float = 0.45  # TUNING (not in GDD)
## Length (s) the "-N" spent number floats up and fades next to the balance.
const SPENT_FLOAT_TIME: float = 0.8  # TUNING (not in GDD)
## Start height (layout px) of the "-N" spent number above the balance's top.
const SPENT_FLOAT_START: float = 16.0  # TUNING (not in GDD)
## Distance (layout px) the "-N" spent number rises while it fades.
const SPENT_FLOAT_RISE: float = 18.0  # TUNING (not in GDD)

# --- Words (kept short: owner "less wordy") --------------------------------------------

## Screen title (TITLE tier, title case for Jacquard).
const TITLE: String = "The Ossuary"  # TUNING (not in GDD)
## Tile cost label once the upgrade is maxed.
const MAXED: String = "MAX"  # TUNING (not in GDD)
## Detail-panel cost line once the upgrade is maxed.
const MAXED_LONG: String = "Maxed"  # TUNING (not in GDD)
## Detail-panel line of a locked upgrade: prerequisite name, tier numeral.
const NEEDS: String = "Needs %s %s"  # TUNING (not in GDD)
## Buy hint word (next to the accept chip) in the detail panel.
const BUY: String = "Buy"  # TUNING (not in GDD)
## Raise hint word for a lowered Profane Oath (free).
const RAISE: String = "Raise"  # TUNING (not in GDD)
## Detail-panel cost text of a free Oath raise.
const FREE: String = "Free"  # TUNING (not in GDD)
## Bottom-row button: lowers the active Oath tier (free, reversible).
const LOWER: String = "Lower Oath"  # TUNING (not in GDD)
## Bottom-row button: refunds every upgrade (asks first).
const REFUND: String = "Refund all"  # TUNING (not in GDD)
## Bottom-row button: closes the screen.
const BACK: String = "Back"  # TUNING (not in GDD)
## Refund confirmation title.
const REFUND_ASK: String = "Refund every upgrade?"  # TUNING (not in GDD)
## Refund confirmation line: the Soul Ash returned.
const REFUND_GAIN: String = "+%d"  # TUNING (not in GDD)
## Refund confirmation buttons.
const REFUND_YES: String = "Refund"  # TUNING (not in GDD)
## Refund confirmation cancel button.
const REFUND_NO: String = "Cancel"  # TUNING (not in GDD)
## Oath effect labels (value row): enemy HP and Soul Ash gain.
const OATH_HP: String = "Foe HP"  # TUNING (not in GDD)
## Soul Ash label of the Oath value row.
const OATH_ASH: String = "Ash"  # TUNING (not in GDD)
## One-line Oath effect (the data description is two lines long).
const OATH_LINE: String = "Opt-in difficulty: stronger Covenant, richer XP, Soul Ash and power-ups."  # TUNING (not in GDD)
