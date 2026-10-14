## InputHintData: numbers and names of the on-screen input hints (InputHints:
## key / pad-button chips drawn from the current bindings, and the hint strip
## at the bottom of screens; menu modernization, GDD §15.0 "Input hints").
## Data only, no logic. Pad glyphs are Xbox-style letters (A / B / X / Y, LB /
## RB, Start...), the most common layout.
class_name InputHintData
extends RefCounted

## --- Last-device tracking ------------------------------------------------

## A pad stick or trigger counts as "the pad was used" past this deflection
## (0..1), so a resting, drifting stick never flips the hints.
const AXIS_THRESHOLD: float = 0.5  # TUNING (not in GDD) input hints

## A mouse move counts as "keyboard / mouse was used" only past this many
## screen px in one event, so a bumped desk does not flip the hints back.
const MOUSE_MOVE_MIN: float = 6.0  # TUNING (not in GDD) input hints

## --- Chip geometry (layout px; 1 texel of the chip frame = 1 layout px) ---

## Height of a chip (layout px). Holds one BODY-tier (19 px) Jersey line.
const CHIP_HEIGHT: int = 20  # TUNING (not in GDD) input hints
## Minimum chip width (layout px): one-letter keys stay square-ish.
const CHIP_MIN_WIDTH: int = 20  # TUNING (not in GDD) input hints
## Space (layout px) left and right of a chip's text inside its frame.
const CHIP_PAD_X: int = 5  # TUNING (not in GDD) input hints
## Corner cut (layout px) of a key / shoulder chip (owner rule: cut corners).
const CHIP_CUT: int = 2  # TUNING (not in GDD) input hints
## Corner cut (layout px) of a face-button chip (A / B / X / Y): deep enough
## that the chip reads as a round button while staying an octagon.
const FACE_CUT: int = 6  # TUNING (not in GDD) input hints
## Baseline of a chip's text (layout px from the chip's top): Jersey 10's
## capitals are 10 px tall at 19 px, so 15 centres them in a 20 px chip.
const CHIP_BASELINE: int = 15  # TUNING (not in GDD) input hints
## Width (layout px) of the small direction arrow drawn after a stick name
## ("RS" + an up arrow for a right-stick flick).
const ARROW_W: int = 7  # TUNING (not in GDD) input hints

## --- Hint strip ------------------------------------------------------------

## Space (layout px) between two chips of one hint ("1" "2" "3").
const CHIP_GAP: int = 3  # TUNING (not in GDD) input hints
## Space (layout px) between a hint's chips and its word.
const WORD_GAP: int = 6  # TUNING (not in GDD) input hints
## Space (layout px) between two hints of a strip.
const HINT_GAP: int = 22  # TUNING (not in GDD) input hints
## Gap (layout px) between a bottom strip (InputHints.bottom_strip()) and the
## bottom edge of its full-screen parent.
const STRIP_BOTTOM_MARGIN: float = 14.0  # TUNING (not in GDD) input hints

## --- Colours ---------------------------------------------------------------

## Fill of every chip (dark keycap).
const CHIP_FILL := Color(0.1, 0.07, 0.15)  # TUNING (not in GDD) input hints
## Border and text of a keyboard key chip (bone).
const KEY_COLOR := Color(0.88, 0.84, 0.74)  # TUNING (not in GDD) input hints
## Bottom edge of a key chip (the keycap's shadow row).
const KEY_SHADOW := Color(0.45, 0.4, 0.36)  # TUNING (not in GDD) input hints
## Border and text of a pad chip that is not a face button (LB, Start, LS...).
const PAD_COLOR := Color(0.78, 0.76, 0.84)  # TUNING (not in GDD) input hints
## Face-button colours (border and letter), the usual Xbox colours.
const FACE_COLORS: Dictionary = {
	"A": Color(0.45, 0.8, 0.3),  # TUNING (not in GDD) input hints
	"B": Color(0.92, 0.33, 0.3),  # TUNING (not in GDD) input hints
	"X": Color(0.35, 0.58, 0.95),  # TUNING (not in GDD) input hints
	"Y": Color(0.98, 0.8, 0.25),  # TUNING (not in GDD) input hints
}
## Colour of a hint's word in a strip.
const WORD_COLOR := Color(0.68, 0.64, 0.74)  # TUNING (not in GDD) input hints

## --- Names -----------------------------------------------------------------

## Pad button index (JoyButton) -> its chip text (Xbox names; the D-pad
## buttons show "D" plus a drawn arrow, see PAD_DIRECTIONS).
const PAD_BUTTONS: Dictionary = {
	0: "A", 1: "B", 2: "X", 3: "Y", 4: "Back", 5: "Guide", 6: "Start",
	7: "LS", 8: "RS", 9: "LB", 10: "RB", 11: "D", 12: "D", 13: "D", 14: "D",
}
## D-pad button index -> the direction of its drawn arrow.
const PAD_DIRECTIONS: Dictionary = {11: Vector2.UP, 12: Vector2.DOWN, 13: Vector2.LEFT, 14: Vector2.RIGHT}
## Pad axis index (JoyAxis) -> its chip text (sticks get a drawn arrow for
## the direction of the binding; triggers do not).
const PAD_AXES: Dictionary = {0: "LS", 1: "LS", 2: "RS", 3: "RS", 4: "LT", 5: "RT"}

## Key names (OS.get_keycode_string()) shortened for a chip.
const KEY_SHORT: Dictionary = {
	"Escape": "Esc", "Backspace": "Bksp", "Delete": "Del", "Insert": "Ins",
	"PageUp": "PgUp", "PageDown": "PgDn", "Kp Enter": "Enter", "Space": "Space",
	"Ctrl": "Ctrl", "Shift": "Shift", "Alt": "Alt", "CapsLock": "Caps",
	"Up": "Up", "Down": "Down", "Left": "Left", "Right": "Right",
}

## The four move actions in WASD order (up, left, down, right), shown
## together by the "move" hint (keyboard: the four keys; pad: the left stick).
const MOVE_ACTIONS: Array[String] = ["move_up", "move_left", "move_down", "move_right"]
