## MasteryUiData: layout and wording of the Ossuary's Masteries tab
## (OssuaryMasteriesPanel, MasteryTile; Ossuary expansion step 4, GDD §15.0
## "Ossuary Masteries"). Purely visual: nothing here changes a price, a level or
## a stat (those live in MasteryData). Sizes are layout px (the 1280x720 layout);
## times are real seconds. Colours and tile geometry reuse OssuaryUiData so the
## tab reads like the Trees. Data only, no logic.
class_name MasteryUiData
extends RefCounted

## Tiles per row (17 classes make 5 rows; four columns of OssuaryUiData.TILE_SIZE
## fill 1200 of the 1280 px layout, like the four trees).
const COLUMNS: int = 4  # TUNING (not in GDD) layout fit
## Height (layout px) the panel reserves for its detail strip (the 64 px icon plus
## the ornate frame), so the tile grid does not jump when the text changes.
const DETAIL_HEIGHT: float = 108.0  # TUNING (not in GDD) layout fit
## Gap (layout px) between the tile grid and the detail strip.
const DETAIL_GAP: int = 10  # TUNING (not in GDD)
## Length (s) of the "denied" shake of a tile's contents.
const SHAKE_TIME: float = 0.22  # TUNING (not in GDD)
## Amplitude (layout px) of that shake.
const SHAKE_PX: float = 3.0  # TUNING (not in GDD)
## Shake oscillations per second.
const SHAKE_HZ: float = 22.0  # TUNING (not in GDD)
## Length (s) of the purchase flash over a tile.
const FLASH_TIME: float = 0.28  # TUNING (not in GDD)
## Peak brightness added by that flash (modulate over-bright, 0 = none).
const FLASH_BOOST: float = 0.6  # TUNING (not in GDD)

## Tile word of a mastery whose class has not reached level 5 yet (dim).
const LOCKED_WORD: String = "Lv 5"  # TUNING (not in GDD)
## Detail line of a locked mastery: the class name fills %s.
const LOCKED_LINE: String = "Take %s to level 5 in a run"  # TUNING (not in GDD) owner brief wording
## Detail-panel stat labels (first value, second value).
const HP_LABEL: String = "HP"  # TUNING (not in GDD)
const DAMAGE_LABEL: String = "Damage"  # TUNING (not in GDD)
## Buy hint word beside the accept chip.
const BUY: String = "Buy"  # TUNING (not in GDD)
## Detail-panel / tile word once all three levels are bought.
const MAXED: String = "Maxed"  # TUNING (not in GDD)
## Tab title (the tab bar reads it).
const TAB_TITLE: String = "Masteries"  # TUNING (not in GDD)
