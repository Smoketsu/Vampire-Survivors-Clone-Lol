## RelicUiData — layout numbers and words of the relic and Grave Offering screens
## (Ossuary expansion steps 5 and 6a, GDD §15.0 "Relics and Grave Offerings"): the
## Ossuary's Relics and Offerings tabs (OssuaryRelicsPanel, OssuaryOfferingsPanel),
## the pre-run setup screen's Rites strip (PreRunRites) and its picker
## (RitePicker), and their tiles (RelicTile). Few words, one line each (menu
## rules); sizes in layout px at 1280 x 720 (phones shrink the screen to fit,
## TouchSupport.fit_to_screen()). Data only.
class_name RelicUiData
extends RefCounted

# --- Tiles ---------------------------------------------------------------------------

## Inner padding (px) of a tile: x left / right, y top / bottom.
const TILE_PAD := Vector2(8, 4)  # TUNING (not in GDD)
## Gap (px) between a tile's badge and its texts.
const TILE_ICON_GAP: int = 8  # TUNING (not in GDD)

# --- Ossuary: Relics tab ----------------------------------------------------------------

## Width (px) of the panels: the Ossuary's four tree columns (4 x 282 + 3 x 24).
const PANEL_WIDTH: float = 1200.0  # TUNING (not in GDD) = OssuaryUiData.TILE_SIZE.x x 4 + COLUMN_GAP x 3
## Relic tiles per row of the grid.
const GRID_COLUMNS: int = 5  # TUNING (not in GDD) 15 relics = 3 rows
## Size (px) of one relic tile (5 x 228 + 4 x 15 = 1200).
const RELIC_TILE := Vector2(228, 56)  # TUNING (not in GDD)
## Gaps (px) between grid tiles: x across, y down.
const GRID_GAP := Vector2i(15, 6)  # TUNING (not in GDD)
## Gap (px) between the panel's blocks (slot row, grid, detail panel).
const BLOCK_GAP: int = 10  # TUNING (not in GDD)
## Badge size (px) in the detail panel (32 art px at x2).
const DETAIL_ICON: float = 64.0  # TUNING (not in GDD)
## Width (px) of the slot row's label.
const SLOT_LABEL_WIDTH: float = 110.0  # TUNING (not in GDD)

## The slot row's label.
const SLOTS_LABEL: String = "Relic slots"  # TUNING (not in GDD)
## A slot tile's name (%d = its number).
const SLOT_NAME: String = "Slot %d"  # TUNING (not in GDD)
## A slot tile's word once owned.
const SLOT_OWNED: String = "Open"  # TUNING (not in GDD)
## The line of the next slot to buy.
const SLOT_NEXT_LINE: String = "One more relic in every run"  # TUNING (not in GDD)
## The line of a slot after the next one.
const SLOT_LATER_LINE: String = "Buy the slot before it first"  # TUNING (not in GDD)
## The line of an owned slot.
const SLOT_OWNED_LINE: String = "Yours"  # TUNING (not in GDD)
## A bought relic's corner word.
const OWNED: String = "Owned"  # TUNING (not in GDD)
## Detail panel line of a bought relic.
const OWNED_LINE: String = "Owned: equip it on the setup screen."  # TUNING (not in GDD)
## Detail panel line of a slot (%d = its number).
const SLOT_DETAIL: String = "Relic slot %d: equip one more relic before each run."  # TUNING (not in GDD)
## Detail panel line of a slot whose earlier slot is not bought (%d = that one).
const SLOT_DETAIL_LATER: String = "Buy slot %d first."  # TUNING (not in GDD)
## The relic count beside the slot row (owned / all).
const SPENT: String = "%d / %d relics"  # TUNING (not in GDD)

# --- Ossuary: Offerings tab -------------------------------------------------------------

## Offering tiles per row.
const OFFERING_COLUMNS: int = 2  # TUNING (not in GDD)
## Size (px) of one offering tile (2 x 594 + 12 = 1200).
const OFFERING_TILE := Vector2(594, 60)  # TUNING (not in GDD)
## Gaps (px) between offering tiles: x across, y down.
const OFFERING_GAP := Vector2i(12, 8)  # TUNING (not in GDD)
## The tab's one header line.
const OFFERINGS_LINE: String = "One per run, chosen on the setup screen and paid as the run starts."  # TUNING (not in GDD)
## Detail line while an offering is too expensive.
const OFFERING_SHORT: String = "Not enough Soul Ash yet."  # TUNING (not in GDD)

# --- Pre-run setup: the Rites strip ------------------------------------------------------

## The strip's section label (LABEL tier, over the tiles).
const RITES_LABEL: String = "Rites"  # TUNING (not in GDD)
## The setup panel's last row holds the ultimate picker (narrow tiles) and the
## strip side by side, so the screen keeps its height at 1280 x 720 (it was at
## the bottom hint strip already): gap (px) between the two blocks.
const ULT_RITES_GAP: int = 24  # TUNING (not in GDD)
## Width (px) of the ultimate block there (4 x UltimateData.PICKER_TILE 86 + 3 x 6).
const ULT_BLOCK_WIDTH: float = 362.0  # TUNING (not in GDD)
## Size (px) of one strip tile: the badge and a price tag (4 x 96 + 3 x 6 = 402 px;
## 362 + 24 + 402 = 788 px of the panel's 806).
const STRIP_TILE := Vector2(96, 42)  # TUNING (not in GDD)
## Badge size (px) on a strip tile.
const STRIP_ICON: float = 32.0  # TUNING (not in GDD) badges are 32 art px
## Gap (px) between strip tiles.
const STRIP_GAP: int = 6  # TUNING (not in GDD)
## Width (px) of the strip's one detail line (the tiles' width).
const STRIP_DETAIL_WIDTH: float = 402.0  # TUNING (not in GDD)
## The detail line with nothing focused and nothing chosen.
const STRIP_HINT: String = "Relics and an offering for this run."  # TUNING (not in GDD)
## The detail line of a relic slot (%d = the slot, %s = the relic, %s = its short effect).
const STRIP_RELIC: String = "%d: %s · %s"  # TUNING (not in GDD)
## The detail line of an open, empty slot (%d = the slot).
const STRIP_EMPTY: String = "%d: empty · choose a relic"  # TUNING (not in GDD)
## The detail line of a slot not bought yet (%d = the slot, %d = its price).
const STRIP_LOCKED: String = "%d: locked · %d Soul Ash in the Ossuary"  # TUNING (not in GDD)
## The detail line of the chosen offering (%s = its name, %s = its short effect).
const STRIP_OFFERING: String = "%s · %s"  # TUNING (not in GDD)
## The detail line of the offering tile with none chosen.
const STRIP_NO_OFFERING: String = "Offering: none · paid as the run starts"  # TUNING (not in GDD)
## An open strip slot with no relic.
const EMPTY: String = "Empty"  # TUNING (not in GDD)
## The offering tile's name with no offering chosen.
const NO_OFFERING: String = "Offering"  # TUNING (not in GDD)
## The picker's "none" tile name.
const NONE: String = "None"  # TUNING (not in GDD)
## The offering tile's tag while the Borrowed Relic lends a relic.
const BORROWED_TAG: String = "+1 lent"  # TUNING (not in GDD)
## Tooltip / detail of a locked strip slot.
const LOCKED_SLOT_TIP: String = "Buy this slot in the Ossuary (Relics)."  # TUNING (not in GDD)
## Tooltip of an empty strip slot.
const EMPTY_SLOT_TIP: String = "Choose a relic for this run."  # TUNING (not in GDD)
## Tooltip of an empty strip slot while no relic is owned.
const NO_RELICS_TIP: String = "Buy relics in the Ossuary (Relics)."  # TUNING (not in GDD)
## Tooltip of the offering tile with no offering chosen.
const OFFERING_TIP: String = "One Grave Offering, paid as the run starts."  # TUNING (not in GDD)

# --- The picker (over the setup screen) --------------------------------------------------

## Picker tiles per row.
const PICKER_COLUMNS: int = 3  # TUNING (not in GDD)
## Size (px) of one picker tile.
const PICKER_TILE := Vector2(270, 56)  # TUNING (not in GDD)
## Gaps (px) between picker tiles.
const PICKER_GAP := Vector2i(10, 6)  # TUNING (not in GDD)
## The relic picker's title (%d = the slot).
const PICK_RELIC: String = "Relic for slot %d"  # TUNING (not in GDD)
## The offering picker's title.
const PICK_OFFERING: String = "Grave Offering"  # TUNING (not in GDD)
## A picker tile's tag for a relic in another slot (%d = that slot).
const IN_SLOT: String = "Slot %d"  # TUNING (not in GDD)
## The relic picker's "none" line.
const NONE_LINE: String = "Leave it empty"  # TUNING (not in GDD)
## The offering picker's "none" line.
const NO_OFFERING_LINE: String = "No offering this run"  # TUNING (not in GDD)
## Why the Borrowed Relic cannot be chosen (every owned relic equipped).
const BORROW_NONE: String = "No relic left to lend."  # TUNING (not in GDD)
