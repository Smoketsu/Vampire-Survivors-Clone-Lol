## FeedbackData: where the Feedback buttons send a player and the words of the
## report they carry (owner request "Can we add a feedback button to the
## game?", GDD §15.0 "Feedback button (owner request, Oct 2026)"). The buttons
## sit in the main menu, the pause menu and the results card; they open the
## owner's Google Form in the browser with its "Details (filled in by the game)"
## question prefilled with a short plain-text report (FeedbackReport). While
## FORM_URL is empty the buttons are hidden and nothing else changes. Data only,
## no logic.
class_name FeedbackData
extends RefCounted

# ------------------------------------------------------------------ destination

## The Google Form's public link, ending in ".../viewform" (no "?" part).
## "" = not set up yet: every Feedback button is hidden. A debug run can set
## one with --feedback-url= (GameState) without changing this file.
const FORM_URL: String = "https://docs.google.com/forms/d/e/1FAIpQLSclf76qjx7-CUY4vb8zZXBaQDQP_5lE8oG08LA3k1nhFpvtCQ/viewform"  # TUNING (not in GDD) owner's "Necropathy Feedback" Google Form (Oct 2026)
## The prefill field id of the form's "Details (filled in by the game)"
## question, e.g. "entry.123456789" (Google Forms: ⋮ > Get pre-filled link).
## "" = the form opens without the report filled in. --feedback-entry= sets
## one for a debug run.
const DETAILS_ENTRY: String = "entry.190257876"  # TUNING (not in GDD) the form's "Details (filled in by the game)" question
## Query text put between FORM_URL and the prefilled field: Google Forms'
## "pre-filled link" marker, then the field separator.
const PREFILL_QUERY: String = "?usp=pp_url&"  # TUNING (not in GDD) Google Forms' prefill format

# ------------------------------------------------------------------ report

## Longest report (characters, before URL encoding): a longer one is cut, so
## the opened URL (about 1.3x this once encoded) stays far inside every
## browser's limit.
const REPORT_MAX_CHARS: int = 1500  # TUNING (not in GDD)
## Longest browser user agent (characters) quoted in the report's first line.
const USER_AGENT_MAX_CHARS: int = 220  # TUNING (not in GDD)
## Name of the game at the start of the report's first line.
const GAME_NAME: String = "Necropathy"  # TUNING (not in GDD)
## Separator between the parts of one report line.
const SEP: String = " | "  # TUNING (not in GDD)
## Words of the report's "Where:" line, per place the button was pressed.
const WHERE_NAMES: Dictionary = {
	"menu": "main menu",  # TUNING (not in GDD)
	"pause": "pause",  # TUNING (not in GDD)
	"results": "results",  # TUNING (not in GDD)
}
## Results card: Game.end_run() reason -> the words used in the report.
const REASON_NAMES: Dictionary = {
	"run_complete": "died in the Reckoning",  # TUNING (not in GDD)
	"defeat": "died before 0:00",  # TUNING (not in GDD)
	"timeout": "time limit",  # TUNING (not in GDD) autotest only
}
## Text appended to a report that REPORT_MAX_CHARS cut short.
const CUT_MARK: String = "..."  # TUNING (not in GDD)

# ------------------------------------------------------------------ buttons

## Caption of every Feedback button (one word, owner rule).
const BUTTON_TEXT: String = "Feedback"  # TUNING (not in GDD)
## Tooltip of the Feedback buttons (desktop hover): where it goes.
const TOOLTIP: String = "Opens the feedback form in your browser."  # TUNING (not in GDD)
## MaskIconData icon on the main-menu Feedback button (a quill and ink: it
## leaves the game for the browser), its scale (layout px per art px) and its
## inset (px) from the button's left edge.
const MENU_ICON: String = "quill"  # TUNING (not in GDD)
const MENU_ICON_SCALE: int = 2  # TUNING (not in GDD)
const MENU_ICON_INSET: float = 10.0  # TUNING (not in GDD)
## Results card: the small Feedback button (px; Restart / Main Menu are
## InRunUiData.END_BUTTON_WIDTH x 44, Next / Again / Menu VictoryData.BUTTON_*),
## dim kit style, BODY text, and the extra gap (px) before it in the row.
const RESULTS_BUTTON_SIZE: Vector2 = Vector2(116.0, 36.0)  # TUNING (not in GDD)
const RESULTS_BUTTON_ACCENT: String = "dim"  # TUNING (not in GDD) not a primary action
const RESULTS_BUTTON_GAP: float = 14.0  # TUNING (not in GDD)

# ------------------------------------------------------------------ Web build

## Web build: seconds an armed link stays waiting for the release of the press
## that armed it (FeedbackReport.arm(): the page opens the tab inside that
## release event, so pop-up blockers see a real gesture).
const WEB_ARM_SECONDS: float = 3.0  # TUNING (not in GDD)
## Web build: a press whose release lands farther than this (CSS px) from
## where it went down was a drag off the button: the armed link is dropped.
const WEB_TAP_SLOP_PX: float = 24.0  # TUNING (not in GDD)
