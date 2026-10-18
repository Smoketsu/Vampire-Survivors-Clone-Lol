## SettingsUiData: tabs, words, sizes and keys of the Settings screen
## (SettingsMenu; menu modernization wave 2, GDD §15.0 "Settings tabs").
## Purely visual: the options themselves, their defaults and how they are
## saved live in the Settings autoload. Sizes are layout px (the 1280x720
## layout, x1.5 in a 1080p window). Data only, no logic.
class_name SettingsUiData
extends RefCounted

# --- Tabs -----------------------------------------------------------------------------

## Tab ids, left to right (SettingsMenu builds one page per id).
const TABS: Array[String] = ["audio", "video", "controls", "save"]  # TUNING (not in GDD); "save" = save backup codes (SaveBackup)
## Tab id -> tab button caption (one word, owner: "less wordy").
const TAB_NAMES: Dictionary = {"audio": "Audio", "video": "Video", "controls": "Controls", "save": "Save"}  # TUNING (not in GDD)
## Key that selects the previous tab (keyboard; Q).
const TAB_PREV_KEY: int = KEY_Q  # TUNING (not in GDD)
## Key that selects the next tab (keyboard; E).
const TAB_NEXT_KEY: int = KEY_E  # TUNING (not in GDD)
## Pad button that selects the previous tab (LB).
const TAB_PREV_PAD: int = JOY_BUTTON_LEFT_SHOULDER  # TUNING (not in GDD)
## Pad button that selects the next tab (RB).
const TAB_NEXT_PAD: int = JOY_BUTTON_RIGHT_SHOULDER  # TUNING (not in GDD)

# --- Layout ---------------------------------------------------------------------------

## Size (layout px) of one tab button.
const TAB_SIZE := Vector2(160, 42)  # TUNING (not in GDD)
## Gap (layout px) between two tab buttons.
const TAB_GAP: int = 8  # TUNING (not in GDD)
## Size (layout px) of the page area inside the ornate panel: every tab has
## the same size, so switching tabs never moves the screen (wide enough for
## the three Controls groups, tall enough for the six Video rows).
const PAGE_SIZE := Vector2(980, 358)  # TUNING (not in GDD) layout fit; 7 rows x 46 + 6 gaps x 6 (Effects row for phones, Volleys row for the bullet heaven pass)
## Height (layout px) of an option row (slider, toggle, zoom).
const ROW_HEIGHT: float = 46.0  # TUNING (not in GDD)
## Gap (layout px) between option rows.
const ROW_GAP: int = 6  # TUNING (not in GDD)
## Width (layout px) of an option row (the page is centred around it).
const ROW_WIDTH: float = 560.0  # TUNING (not in GDD)
## Width (layout px) of a volume row's name.
const VOLUME_LABEL_WIDTH: float = 150.0  # TUNING (not in GDD)
## Width (layout px) of a volume row's "80%" value.
const VOLUME_VALUE_WIDTH: float = 64.0  # TUNING (not in GDD)
## Volume slider step (percent).
const VOLUME_STEP: float = 5.0  # TUNING (not in GDD)
## Gap (layout px) between the three binding groups of the Controls tab.
const GROUP_GAP: int = 28  # TUNING (not in GDD)
## Size (layout px) of a keyboard binding button (holds one key chip).
const KEY_BUTTON_SIZE := Vector2(76, 34)  # TUNING (not in GDD)
## Width (layout px) of the read-only pad binding cell.
const PAD_CELL_WIDTH: float = 46.0  # TUNING (not in GDD)
## Height (layout px) of one binding row.
const BIND_ROW_HEIGHT: float = 38.0  # TUNING (not in GDD)
## Gap (layout px) between two binding rows.
const BIND_ROW_GAP: int = 6  # TUNING (not in GDD)
## Size (layout px) of the Reset keys button.
const RESET_SIZE := Vector2(200, 40)  # TUNING (not in GDD)

# --- Controls tab ---------------------------------------------------------------------

## Binding groups of the Controls tab, left to right: [group label, actions]
## (every Settings.REBINDABLE action once).
const GROUPS: Array = [
	["Move", ["move_up", "move_down", "move_left", "move_right"]],  # TUNING (not in GDD)
	["Actions", ["toggle_aim", "dash", "ultimate", "pause"]],  # TUNING (not in GDD)
	["Stances", ["stance_escort", "stance_onslaught", "stance_spearhead", "stance_bone_ring"]],  # TUNING (not in GDD)
]
## Short row labels (the group names say the rest: "Up" under Move).
const SHORT_LABELS: Dictionary = {
	"move_up": "Up", "move_down": "Down", "move_left": "Left", "move_right": "Right",  # TUNING (not in GDD)
	"toggle_aim": "Bolt aim", "dash": "Grave Step", "ultimate": "Dread Rally", "pause": "Pause",  # TUNING (not in GDD)
	"stance_escort": "Escort", "stance_onslaught": "Onslaught", "stance_spearhead": "Spearhead", "stance_bone_ring": "Bone Ring",  # TUNING (not in GDD)
}
## Caption of a binding button while it waits for a key.
const LISTENING: String = "..."  # TUNING (not in GDD)

# --- Words ----------------------------------------------------------------------------

## Screen title (TITLE tier).
const TITLE: String = "Settings"  # TUNING (not in GDD)
## Bus name -> volume row label.
const VOLUME_ROWS: Dictionary = {"Master": "Master", "Music": "Music", "SFX": "Effects"}  # TUNING (not in GDD)
## Option key -> toggle row label, in Video tab order.
const TOGGLES: Dictionary = {"fullscreen": "Fullscreen", "volleys": "Volleys", "screen_shake": "Screen shake", "damage_numbers": "Damage numbers", "reduce_motion": "Reduce motion"}  # TUNING (not in GDD)
## Web build where the browser has no page fullscreen (iPhone Safari: only videos go
## fullscreen; GDD §15.0 "iPhone sound and fullscreen"): the Fullscreen toggle becomes
## this dim line when the game is the page itself (a home-screen launch is fullscreen).
const FULLSCREEN_HOME_SCREEN: String = "Fullscreen: Share, Add to Home Screen"  # TUNING (not in GDD) mobile
## The same, when the game is embedded in another page (itch.io): nothing can help there.
const FULLSCREEN_UNAVAILABLE: String = "Fullscreen: not in this browser"  # TUNING (not in GDD) mobile
## Zoom row label (its value is ViewData.ZOOM_LEVELS[...]["label"]).
const ZOOM: String = "Zoom"  # TUNING (not in GDD)
## Effects row label (its value is EffectsData.LABELS[...]: Full / Reduced).
const EFFECTS: String = "Effects"  # TUNING (not in GDD) mobile
## Reset keys button.
const RESET: String = "Reset keys"  # TUNING (not in GDD)
## Hint strip words.
const HINT_SELECT: String = "Select"  # TUNING (not in GDD)
## Hint word on the Controls tab (accept = rebind).
const HINT_REBIND: String = "Rebind"  # TUNING (not in GDD)
## Hint word of the cancel chip.
const HINT_BACK: String = "Back"  # TUNING (not in GDD)
## Column captions over each binding group (keyboard, pad).
const COL_KEY: String = "Key"  # TUNING (not in GDD)
## Pad column caption.
const COL_PAD: String = "Pad"  # TUNING (not in GDD)
