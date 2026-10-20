## FeedbackButton — the one wiring of the Feedback buttons (owner request, GDD
## §15.0 "Feedback button (owner request, Oct 2026)") in the main menu, the
## pause menu and the results card. A screen makes its button with make() (or
## hands its own Button to wire()) only while FeedbackReport.enabled(); with
## no form link set there is no button at all, so the focus wiring and the
## layouts stay as they were. The button's press-down arms the link on the Web
## build and its press opens the form (FeedbackReport.arm() / open()); the
## report is built at that moment from `context`, a Callable returning one of
## FeedbackReport's *_context() dictionaries. The click / back sounds are the
## shared ones (Sfx hooks every Button). Opening never pauses, resumes or
## changes the run.
class_name FeedbackButton
extends RefCounted


## A new one-word Feedback button wired to `context` (see the header).
static func make(context: Callable) -> Button:
	var b := Button.new()
	b.text = FeedbackData.BUTTON_TEXT
	wire(b, context)
	return b


## Wires `b` as a Feedback button: tooltip, press-down arms (Web), press opens.
static func wire(b: Button, context: Callable) -> void:
	b.tooltip_text = FeedbackData.TOOLTIP
	FeedbackReport.web_prepare()  # Web: the page listener knows this press's position.
	b.button_down.connect(func() -> void: FeedbackReport.arm(context.call() as Dictionary))
	b.pressed.connect(func() -> void: FeedbackReport.open(context.call() as Dictionary))
