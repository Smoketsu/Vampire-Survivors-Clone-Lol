## ConfirmData — texts and sizes of the confirm dialogs (ConfirmDialog; GDD
## §15.0 "Confirm dialogs"): one short question, one short consequence line
## (owner: fewer words), the confirm button's word. Data only, no logic.
class_name ConfirmData
extends RefCounted

## Width (layout px) of a dialog's content column.
const WIDTH: float = 420.0  # TUNING (not in GDD)
## Size (layout px) of each dialog button.
const BUTTON_SIZE := Vector2(170.0, 44.0)  # TUNING (not in GDD)
## Gap (layout px) between the two buttons.
const BUTTON_GAP: int = 20  # TUNING (not in GDD)
## Opacity (0..1) of the backdrop behind a dialog.
const BACKDROP_ALPHA: float = 0.62  # TUNING (not in GDD)
## Word on the cancel button (Sfx plays the back sound for it).
const CANCEL: String = "Cancel"  # TUNING (not in GDD)

## The wired dialogs: id -> [title, body, confirm word]. Titles are the
## Jacquard TITLE tier (title case).
const QUIT := ["Quit?", "Close Necropathy and return to the desktop.", "Quit"]  # TUNING (not in GDD)
## Pause menu Restart (the run in progress is lost).
const RESTART := ["Restart?", "This run ends here: no Soul Ash is earned.", "Restart"]  # TUNING (not in GDD)
## Pause menu Main Menu (the run in progress is lost).
const MAIN_MENU := ["Abandon the Run?", "Return to the main menu: no Soul Ash is earned.", "Abandon"]  # TUNING (not in GDD)
## Ossuary Refund all (%d = the Soul Ash refunded). Unused while the Ossuary keeps its own
## refund dialog (it shows the Soul Ash icon); kept for a switch to the shared dialog.
const REFUND := ["Refund All?", "Every upgrade returns to tier 0 and %d Soul Ash comes back.", "Refund"]  # TUNING (not in GDD)
## Settings Reset keys.
const RESET_KEYS := ["Reset Keys?", "Every key binding returns to its default.", "Reset"]  # TUNING (not in GDD)
