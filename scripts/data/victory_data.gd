## VictoryData — texts, timings and sizes of the victory screen (content wave 2,
## GDD §15.0 "Victory screen (content wave 2)"; owner-approved Proposal 1). A won
## run (the necromancer fell after 0:00) ends on two beats:
##   * the LAST STAND (LastStand): a ~3 s visual beat after the death is already
##     counted: the frozen world drains of colour, the surviving army turns
##     outward and kneels in the Bone Ring, a gold wash rises and the stage's
##     title card fades in. Real time; skipped (instant) under the autotest and
##     with Reduce motion; any key, button or tap skips it;
##   * the VICTORY RESULTS CARD (EndScreen's victory path, VictoryResults): the
##     stage title and boss line, a stage seal (the stage-select vignette, gold on
##     a Hyper clear), the time survived past 0:00 with the stage's Best record and
##     a "New record" ribbon, the run highlights, the unlock plates and the Soul Ash
##     breakdown, and Next / Again / Menu.
## Data only, no logic. Every value is visual or text: nothing here touches a run.
class_name VictoryData
extends RefCounted

# --- Stage titles (Proposal 1 table) -------------------------------------------------

## Stage id -> {title, boss_line}: the victory title (TITLE tier, title case) and
## the second line shown when the stage boss fell in the run. A stage missing
## here uses DEFAULT_TITLE and no boss line.
const STAGES := {
	"graveyard": {"title": "The Graveyard Is Yours", "boss_line": "Sir Alaric's oath dies with him."},  # GDD §15.0 (content wave 2)
	"crimson_march": {"title": "The March Ends in Ash", "boss_line": "Marshal Vael's banners burn."},  # GDD §15.0 (content wave 2)
	"sanctum": {"title": "The Dawn Goes Out", "boss_line": "The relic lies shattered."},  # GDD §15.0 (content wave 2)
	"harbour": {"title": "The Tide Turns", "boss_line": "Abbot Merrow sinks with his sermon."},  # GDD §15.0 (content wave 2)
	"archive": {"title": "The Last Page Burns", "boss_line": "The Archivist's book is closed."},  # GDD §15.0 (content wave 2)
	"spire": {"title": "The Dead God Serves", "boss_line": "Vhal'Neth kneels."},  # GDD §15.0 (content wave 2)
	# --- Act III: the Electronic Empire (placeholders until each stage is built) ---
	"wastes": {"title": "Signal Lost", "boss_line": "Kestrel's last pixel goes dark."},  # TUNING (not in GDD) Act III placeholder
	"assembly": {"title": "The Line Stops", "boss_line": "The Motherboard crashes for good."},  # TUNING (not in GDD) Act III placeholder
	"citadel": {"title": "Steel Bows to Bone", "boss_line": "Deus Ex Machina falls, and Varn with it."},  # TUNING (not in GDD) Act III placeholder
	# --- Act IV: the Olympian Republic (placeholders until each stage is built) ---
	"ilion": {"title": "The Walls Fall", "boss_line": "Achilles dies at the heel."},  # TUNING (not in GDD) Act IV placeholder
	"olympus": {"title": "Olympus Is Silent", "boss_line": "Zeus's thunder dies on the summit."},  # TUNING (not in GDD) Act IV placeholder
	"underworld": {"title": "The Empty Throne", "boss_line": "Hades kneels and gives up his crown."},  # TUNING (not in GDD) Act IV placeholder
}
## Title of a victory on a stage missing from STAGES.
const DEFAULT_TITLE: String = "Victory"  # TUNING (not in GDD)
## Act number -> the line under the title (the first line of the card; the boss
## line follows it when the boss fell). Absent act = act 1's line.
const ACT_LINES := {
	1: "You outlasted the Covenant. The Reckoning claimed you at last.",  # TUNING (not in GDD; the old shared subtitle)
	2: "You outlasted the Eye. The Reckoning claimed you at last.",  # TUNING (not in GDD)
	3: "You outlasted the Empire. The Purge Protocol deleted you at last.",  # TUNING (not in GDD) Act III
	4: "You outlasted the gods. Their twilight buried you at last.",  # TUNING (not in GDD) Act IV
}

# --- The last stand (LastStand; seconds of real time from its start) ----------------

## Whole length of the last stand before the results card opens (s).
const LAST_STAND_TIME: float = 3.0  # TUNING (not in GDD; Proposal 1: "about 3 s")
## Seconds the world takes to drain to DESATURATE (the freeze; eases out, so the
## change slows to a stop).
const FREEZE_TIME: float = 0.7  # TUNING (not in GDD)
## How far the world drains toward DRAIN_COLOR (0 = none, 1 = all the way).
const DESATURATE: float = 0.8  # TUNING (not in GDD)
## Start of the first summon's kneel (s).
const KNEEL_START: float = 0.3  # TUNING (not in GDD)
## Extra delay of the summon farthest from the necromancer (s): the kneel ripples
## outward through the Bone Ring, nearest first.
const KNEEL_RIPPLE: float = 0.55  # TUNING (not in GDD)
## Seconds one summon takes to kneel.
const KNEEL_TIME: float = 0.4  # TUNING (not in GDD)
## Body scale of a kneeling summon about its feet (x widen, y crouch; 1 = standing).
const KNEEL_SCALE: Vector2 = Vector2(1.1, 0.7)  # TUNING (not in GDD)
## Brightness of a kneeling summon's body (1 = unchanged): the army bows into the gold.
const KNEEL_DIM: float = 0.85  # TUNING (not in GDD)
## Most summons animated (the nearest first; the rest stay as they stand).
const KNEEL_MAX: int = 160  # TUNING (not in GDD)
## Start of the gold wash (s).
const WASH_START: float = 0.6  # TUNING (not in GDD)
## Seconds the gold wash takes to rise to WASH_STRENGTH.
const WASH_TIME: float = 1.1  # TUNING (not in GDD)
## Strength of the gold wash (0..1, the share of the gold tint).
const WASH_STRENGTH: float = 0.7  # TUNING (not in GDD)
## Colour of the gold wash (the UI's victory gold, a little warmer).
const WASH_COLOR: Color = Color(1.0, 0.78, 0.36)  # TUNING (not in GDD)
## Warm grey the frozen world is multiplied toward as it drains (DESATURATE of
## the way): a multiply cannot desaturate, so the drain dims and warms instead
## (no screen-reading shader: GDD §15.0 "Web death crash: no screen-reading shaders").
const DRAIN_COLOR: Color = Color(0.8, 0.76, 0.7)  # TUNING (not in GDD)
## Gain on WASH_COLOR in the gold multiply (1.3 = the old shader's tint; each
## channel clamps at 1, so red stays and blue drops).
const WASH_TINT_GAIN: float = 1.3  # TUNING (not in GDD)
## Share of WASH_COLOR added over the screen at the full wash (lifts the darks).
const WASH_LIFT: float = 0.22  # TUNING (not in GDD)
## Seconds the HUD takes to fade out at the start.
const HUD_FADE: float = 0.4  # TUNING (not in GDD)
## Start of the title card's fade-in (s).
const CARD_START: float = 1.2  # TUNING (not in GDD)
## Seconds the title card takes to fade in.
const CARD_FADE: float = 0.6  # TUNING (not in GDD)
## Pixels the title card rises while it fades in.
const CARD_RISE: float = 10.0  # TUNING (not in GDD)
## Longest time (s) input is swallowed after a key / tap skipped the beat (until
## that press is released), so the press never also hits a results-card button.
const SKIP_GUARD_TIME: float = 1.0  # TUNING (not in GDD)
## Height of the title card's centre as a share of the screen height (0 = top):
## above the army, which kneels around the necromancer at the centre.
const CARD_Y: float = 0.26  # TUNING (not in GDD)
## Width (layout px) of the title card's ribbon.
const CARD_RIBBON_WIDTH: float = 560.0  # TUNING (not in GDD)

# --- The victory results card ---------------------------------------------------------

## Width (layout px) of the ribbon behind the stage title.
const RIBBON_WIDTH: float = 520.0  # TUNING (not in GDD)
## Width (layout px) of the middle column (time past 0:00, stat tiles, highlights).
const MIDDLE_WIDTH: float = 372.0  # TUNING (not in GDD)
## Width (layout px) of the Soul Ash column on the victory card.
const ASH_WIDTH: float = 300.0  # TUNING (not in GDD)
## Gap (layout px) between the card's columns.
const COLUMN_GAP: int = 18  # TUNING (not in GDD)
## Height (layout px) of one small stat tile (slain, level, army).
const TILE_HEIGHT: float = 52.0  # TUNING (not in GDD)
## Width (layout px) of each of the three buttons.
const BUTTON_WIDTH: float = 190.0  # TUNING (not in GDD)
## Height (layout px) of each button.
const BUTTON_HEIGHT: float = 44.0  # TUNING (not in GDD)
## Most evolution rows in the highlights (the rest are summed up in one "+N more").
const MAX_EVOLUTION_ROWS: int = 3  # TUNING (not in GDD)
## Seconds after the card opens before the "New record" ribbon stamps in.
const RECORD_DELAY: float = 0.5  # TUNING (not in GDD)

## The stage seal: a Hyper clear (a victory with Hyper mode on) stamps the seal
## in gold (frame, wash and the Hyper badge); any other victory in violet.
const SEAL_HYPER_ACCENT: String = "gold"  # GDD §15.0 (content wave 2): gold on a Hyper clear
## Frame accent of the seal on a victory without Hyper.
const SEAL_ACCENT: String = "violet"  # TUNING (not in GDD)
## Gold wash over the seal's vignette on a Hyper clear (0..1 alpha).
const SEAL_HYPER_WASH: float = 0.18  # TUNING (not in GDD)

## Texts of the card (few words, owner UI rule).
const TEXT_PAST_ZERO: String = "Past 0:00"  # TUNING (not in GDD)
## Best record line (%s = the best time past 0:00 as m:ss).
const TEXT_BEST: String = "Best +%s"  # TUNING (not in GDD)
## Ribbon when this run beat the stage's best time past 0:00.
const TEXT_NEW_RECORD: String = "New record"  # TUNING (not in GDD)
## Survived line beside the time past 0:00 (%s = the whole run time).
const TEXT_SURVIVED: String = "Survived %s"  # TUNING (not in GDD)
## Caption of the highlights list.
const TEXT_HIGHLIGHTS: String = "Highlights"  # TUNING (not in GDD)
## Highlight captions.
const HL_TOP_DAMAGE: String = "Top damage"  # TUNING (not in GDD)
## Caption of an evolution row (the evolution's name and game time follow).
const HL_EVOLUTION: String = "Evolution"  # TUNING (not in GDD)
## Summary row of the evolutions past MAX_EVOLUTION_ROWS (%d = how many more).
const HL_MORE_EVOLUTIONS: String = "+%d more"  # TUNING (not in GDD)
## Caption of the chests row.
const HL_CHESTS: String = "Chests opened"  # TUNING (not in GDD)
## Caption of the largest army row.
const HL_ARMY: String = "Largest army"  # TUNING (not in GDD)
## Caption of the boss kill row (%s = the boss's short name).
const HL_BOSS: String = "%s slain"  # TUNING (not in GDD)
## Button words (one word each, owner UI rule).
const BUTTON_NEXT: String = "Next"  # TUNING (not in GDD)
## Again: the same stage with the same pre-run config (Restart).
const BUTTON_AGAIN: String = "Again"  # TUNING (not in GDD)
## Menu: back to the main menu.
const BUTTON_MENU: String = "Menu"  # TUNING (not in GDD)

# --- The debug preview (--victory-preview; GameState) -------------------------------

## Game seconds a --victory-preview run plays before the scripted victory (lets
## the starting army rise).
const PREVIEW_DELAY: float = 6.0  # TUNING (not in GDD; debug only)
## Seconds past 0:00 the preview run reports.
const PREVIEW_OVERTIME: float = 83.0  # TUNING (not in GDD; debug only)
## Game time (s) the preview run reports for the boss kill.
const PREVIEW_BOSS_TIME: float = 1093.0  # TUNING (not in GDD; debug only)
## Summon class levels the preview run raises at its start (a fuller ring to kneel).
const PREVIEW_CLASSES := {"warrior": 5, "archer": 4, "mage": 3, "mender": 2}  # TUNING (not in GDD; debug only)
## Evolutions the preview run lists ([evolution id, game time m:ss]; ids from
## EvolutionData / SummonEvolutionData).
const PREVIEW_EVOLUTIONS := [["void_barrage", "10:42"], ["death_knight", "12:05"], ["soul_rapture", "13:30"], ["lich", "15:12"]]  # TUNING (not in GDD; debug only)
## Chests opened the preview run reports.
const PREVIEW_CHESTS: int = 7  # TUNING (not in GDD; debug only)
