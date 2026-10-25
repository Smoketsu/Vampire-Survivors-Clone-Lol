## EpilogueData — the CAMPAIGN EPILOGUE (GDD §15.0 "Ul-Thalos, the Risen
## Spire": the owner-approved proposal's "The Dead God Serves unlocks the
## campaign epilogue", which also closes Dawn Extinguished's old "the campaign
## epilogue" hook; illustrated in content wave 2, GDD §15.0 "Illustrated
## epilogue (content wave 2)"). A short text in two parts, one per act, each
## opened by its act's last achievement (MetaData.ACHIEVEMENTS): the Act I
## part by Dawn Extinguished (Seraphine slain), the Act II part by The Dead
## God Serves (Vhal'Neth slain and raised). Every paragraph has its own
## pixel-art picture panel (`panels`, assets/sprites/epilogue/<id>.png, made by
## tools/epilogue_panel.py; docs/art/ART_BIBLE.md "Epilogue panels") with a
## slow pan; a closing card per act (CLOSINGS) hints at the sequel. The
## main menu shows its Epilogue button once either part is open
## (FrontDoorData.MENU_ITEMS); EpilogueScreen plays the slides, and plays the
## parts the player has not seen yet once on their own after a run (Meta
## [epilogue] seen_<id>). Sizes are layout px on the 1280x720 layout, times
## are REAL seconds (UI motion never runs on game time). Data only.
class_name EpilogueData
extends RefCounted

## The parts in reading order: `id` (its Meta [epilogue] seen_<id> flag),
## achievement id that opens it, the act's name, heading, its paragraphs, and
## one picture panel per paragraph: [SpriteData key, pan start, pan end]; a pan
## point is the window's place over the picture as a fraction (0..1) of the
## picture's slack on each axis (0, 0 = top-left corner of the art in view).
const PARTS := [
	{
		"id": "act1",  # TUNING (not in GDD)
		"achievement": "dawn_extinguished",
		"act": "Act I: The Crimson Covenant",
		"heading": "When the Dawn Went Out",
		"lines": [
			"The Sanctum burned for three nights. When the relic shattered, the light that had ruled the realm for a thousand years went out like a candle in a crypt.",
			"Across the land the other holy orders took up arms, but there was no Covenant left to lead them. The dead walked the pilgrim roads, and the living learned to bar their doors at dusk.",
			"The necromancer did not sit the empty throne. Something else was calling the dead now, from far beneath the sea, and the army began to drift toward the coast.",
		],
		"panels": [
			["epilogue/act1_1", Vector2(0.5, 0.0), Vector2(0.5, 0.75)],  # TUNING (not in GDD) the burning Sanctum, tilting down to the shattered relic
			["epilogue/act1_2", Vector2(1.0, 0.1), Vector2(0.0, 0.9)],  # TUNING (not in GDD) the dying sun, down the pilgrim road
			["epilogue/act1_3", Vector2(0.0, 0.7), Vector2(1.0, 0.3)],  # TUNING (not in GDD) from the cliff out to the glow beneath the sea
		],
	},
	{
		"id": "act2",  # TUNING (not in GDD)
		"achievement": "the_dead_god_serves",
		"act": "Act II: The Ancient Eye",
		"heading": "The Dead God Serves",
		"lines": [
			"The Eye's faithful had prayed for the Dreaming Mother to wake and claim every corpse as her vessel. They had not prayed for who would answer.",
			"Vhal'Neth was dead long before her city sank, and the dead belong to the necromancer. The Eye's own ritual, sung by a thousand drowned throats, bound her to a new master.",
			"Ul-Thalos sinks back beneath the waves. Somewhere far below, a god dreams of the necromancer's will, and the sea gives up its dead whenever it is asked.",
			"The Covenant is ash. The Eye is blind. The army is endless, and it is only beginning.",
		],
		"panels": [
			["epilogue/act2_1", Vector2(0.0, 0.2), Vector2(1.0, 0.0)],  # TUNING (not in GDD) Gullhaven: the tide pulled back, up to the eye
			["epilogue/act2_2", Vector2(0.5, 0.0), Vector2(0.5, 0.9)],  # TUNING (not in GDD) the Archive's last page burning, down to the lectern
			["epilogue/act2_3", Vector2(1.0, 0.0), Vector2(0.4, 0.8)],  # TUNING (not in GDD) Ul-Thalos sinking, down to the watchers
			["epilogue/act2_4", Vector2(0.0, 0.8), Vector2(1.0, 0.3)],  # TUNING (not in GDD) from the necromancer across to Vhal'Neth kneeling
		],
	},
	ACT3_PART,  # Act III, "The Machines Go Dark" (its row and panels below).
	ACT4_PART,  # Act IV, "The Gods Are Silent" (its row and panels below; opened by Empty Throne).
]
# --- Act III: the Iron Citadel ---
## HOOK for the Act III part of the epilogue (owner-approved proposal: "a third
## epilogue part, 'The Machines Go Dark' (illustrated like Acts I and II), opened
## by the Act III achievement"). The last row of PARTS (GDD §15.0 "Act III
## epilogue and the new closing card"): its four panels (tools/epilogue_panel.py,
## art_source/epilogue/act3_<n>) are filled, one per line, so the epilogue
## screen, the main menu's Epilogue button (any_open()) and the autoplay-once
## flow pick it up with no other change. `achievement` is MetaData "nothing_is_deathless" (Deus Ex
## Machina slain in the Iron Citadel); its Meta flag is [epilogue] seen_act3.
## The text follows the proposal's ending ("Nothing is deathless. Everything is
## mine."; Varn's soul taken from the broken core; the machines go dark).
const ACT3_PART := {
	"id": "act3",  # TUNING (not in GDD)
	"achievement": "nothing_is_deathless",
	"act": "Act III: The Electronic Empire",
	"heading": "The Machines Go Dark",  # Owner-approved proposal
	"lines": [
		"The Empire had conquered death with steel. Its citizens were never buried; they were rebuilt, and rebuilt again, and called it forever.",  # TUNING (not in GDD)
		"In the Core of the Iron Citadel the god they built fell to its knees, and the necromancer reached into the broken engine for the one thing the Empire forgot to delete: Varn's soul.",  # Owner-approved proposal ending
		"Nothing is deathless. Everything is mine. Across the realm the machines went dark, rank after rank, and their founder rose to serve a new master.",  # Owner-approved proposal ending
		"Covenant, Eye and Empire are ash, blind and silent. The dead are the only empire left.",  # TUNING (not in GDD)
	],
	"panels": [
		["epilogue/act3_1", Vector2(0.0, 0.1), Vector2(1.0, 0.9)],  # TUNING (not in GDD) the chrome towers, down the avenue of steel citizens to the rebuilding cradle
		["epilogue/act3_2", Vector2(1.0, 0.2), Vector2(0.2, 0.6)],  # TUNING (not in GDD) from the kneeling mech across to the necromancer reaching for Varn's soul
		["epilogue/act3_3", Vector2(1.0, 0.3), Vector2(0.0, 0.8)],  # TUNING (not in GDD) along the dead ranks to Varn bowing to the necromancer
		["epilogue/act3_4", Vector2(0.5, 0.0), Vector2(0.5, 0.9)],  # TUNING (not in GDD) the three acts' ruins, down to the army of the dead
	],
}
# --- Act IV: the Asphodel Underworld ---
## The Act IV part of the epilogue (now in PARTS; its four panels were made at
## integration, GDD §15.0 "Act IV epilogue and the Sun Still Rises card"; the
## original hook note follows).
## HOOK for the Act IV part of the epilogue (owner-approved proposal: "Epilogue
## parts: The Gods Are Silent (Act IV)"; "Empty Throne (beat Hades; opens the Act
## IV epilogue)"). The Asphodel Underworld's agent leaves it OUT of PARTS: the
## lead makes its panels at integration (tools/epilogue_panel.py,
## art_source/epilogue/act4_<n>), fills `panels` (one per line), then appends
## this row to PARTS after ACT3_PART, so the epilogue screen, the main menu's
## Epilogue button (any_open()) and the autoplay-once flow pick it up with no
## other change; the closing card "The Sun Still Rises" (CLOSINGS, after
## "act4") then follows it. `achievement` is MetaData "empty_throne" (Hades
## beaten in the Asphodel Underworld); its Meta flag will be [epilogue]
## seen_act4. The text follows the proposal's story (the necromancer's army
## emptied the Underworld; the gods came for the dead; Olympus fell; Hades
## kneels and gives up his crown).
const ACT4_PART := {
	"id": "act4",  # TUNING (not in GDD)
	"achievement": "empty_throne",
	"act": "Act IV: The Olympian Republic",
	"heading": "The Gods Are Silent",  # Owner-approved proposal
	"lines": [
		"The army of the dead had grown so vast that the Underworld stood empty. Hades complained to Olympus that his kingdom was a desert, and the gods came down to take the dead back.",  # Owner-approved proposal story
		"Their legions broke on the shore of Ilion, and one by one the gods of the mountain fell silent: Ares, Artemis, Poseidon, and at last Zeus himself.",  # Owner-approved proposal story
		"Below the world, in the grey fields of asphodel, the Lord of the Dead rose from his throne to fight for what was his. Beaten, he did not die. He knelt, and laid his crown at the necromancer's feet.",  # Owner-approved proposal ending
		"The Styx runs again, and every soul it carries answers to one master. The gods are silent. The throne below is empty.",  # TUNING (not in GDD)
	],
	"panels": [
		["epilogue/act4_1", Vector2(0.0, 0.6), Vector2(1.0, 0.3)],  # TUNING (not in GDD) across the asphodel fields and the dry Styx, from the necromancer along his army
		["epilogue/act4_2", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) the descending gods in gold, down to the undead line
		["epilogue/act4_3", Vector2(0.0, 0.5), Vector2(1.0, 0.5)],  # TUNING (not in GDD) from the necromancer across to Hades kneeling with his crown
		["epilogue/act4_4", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) the empty marble thrones of Olympus, down to the army and the necromancer
	],
}
## The closing cards, one per act, in reading order (owner: "tie everything
## together nicely"; docs/act4/PROPOSAL.md "Closing cards"; GDD §15.0 "Closing
## cards, one per act"). Each names the next enemy without showing it, and
## follows the PARTS row its `after` key names: it is shown right after that
## part's slides, once that part is open (and in the main menu's Epilogue
## button and the autoplay-once flow alike). Keys: after (PARTS id), act (the
## small label), heading, line (the closing text), tag (small dim line under
## it), panel ([SpriteData key, pan start, pan end] as PARTS panels).
## The card after Act II is the set-up of Act III (owner, wave 2 art review:
## "redo with electronic empire vibes"; GDD §15.0 "Act III epilogue and the new
## closing card"): the beacons lit for the dead are seen by the Electronic
## Empire, which nobody called. It still closes Act II once Act III is open.
## The card after Act III sets up Act IV, the Olympian Republic.
const CLOSINGS := [
	{
		"after": "act2",  # TUNING (not in GDD) id of the PARTS row the card follows (Act II, also once Act III is open)
		"act": "Beyond the realm",  # TUNING (not in GDD)
		"heading": "The Beacons Burn",  # TUNING (not in GDD)
		"line": "Far beyond the mountains, the holy orders the Covenant once led are lighting their beacons. They remember how to march, and they are marching on the dead.",  # TUNING (not in GDD) two lines; the banners name the orders. Owner decision (Act III art review round 4): the knights card stays, its blue star repainted gold; the Empire version is kept only as art_source/epilogue/close_empire.png
		"tag": "To be continued.",  # TUNING (not in GDD) small dim line under the closing text
		"panel": ["epilogue/close", Vector2(0.0, 0.0), Vector2(1.0, 0.85)],  # TUNING (not in GDD) the beacons, down to the knights at the gate
	},
	# --- Act IV: the Olympian Republic ---
	{
		"after": "act3",  # TUNING (not in GDD) follows the Act III part ("The Machines Go Dark")
		"act": "Beneath the world",  # TUNING (not in GDD)
		"heading": "The River Runs Dry",  # Owner-approved proposal (docs/act4/PROPOSAL.md "Closing cards")
		"line": "Far below the world, the river of the dead has run dry, and its ferryman has no one left to carry. On a mountain of marble, the gods have noticed.",  # Owner-approved proposal
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_act3", Vector2(0.5, 0.0), Vector2(0.4, 1.0)],  # TUNING (not in GDD) the gods on the marble mountain, down to the empty ferry and the lantern
	},
	# --- Act IV: the Asphodel Underworld ---
	# The card after Act IV sets up Act V, the Shogunate of the Rising Sun. It
	# shows once the Act IV part (ACT4_PART, appended to PARTS by the lead) is
	# open; its panel "epilogue/close_act4" is made by the lead at integration.
	{
		"after": "act4",  # TUNING (not in GDD) follows the Act IV part ("The Gods Are Silent")
		"act": "Across the eastern sea",  # TUNING (not in GDD)
		"heading": "The Sun Still Rises",  # Owner-approved proposal (docs/act4/PROPOSAL.md "Closing cards")
		"line": "Olympus is silent and Hades kneels. Only one light still burns against the dead: across the eastern sea, a goddess opens her eyes.",  # Owner-approved proposal
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_act4", Vector2(0.0, 0.8), Vector2(1.0, 0.1)],  # TUNING (not in GDD) from the ruined throne across the dark sea to the torii and the opening eyes
	},
]
## Line shown in place of a part that is still sealed.
const SEALED: String = "Sealed. %s to read on."  # TUNING (not in GDD) %s = the achievement's goal
## Heading of a sealed part's slide.
const SEALED_HEADING: String = "Sealed"  # TUNING (not in GDD)
## Screen title (kept for the Codex / menu wording).
const TITLE: String = "Epilogue"  # TUNING (not in GDD)

# ------------------------------------------------------------------ layout

## Size of a picture panel PNG (art px = layout px, 16:9; tools/epilogue_panel.py PANEL_W / PANEL_H).
const PANEL_ART := Vector2(1024.0, 576.0)  # TUNING (not in GDD)
## The picture window (layout px): the part of the panel in view, panned over
## it. With the header, the frame and three text lines the column is about
## 590 px tall (fits the 600 px of a phone's mobile layout).
const WINDOW := Vector2(944.0, 424.0)  # TUNING (not in GDD)
## Inner padding (px) of the picture's frame around the window.
const FRAME_PAD: float = 6.0  # TUNING (not in GDD)
## Height (px) reserved for the paragraph under the picture (three NAME lines).
const TEXT_HEIGHT: float = 96.0  # TUNING (not in GDD)
## Gap (px) between the column's rows (header, picture, text).
const ROW_GAP: int = 8  # TUNING (not in GDD)
## Gap (px) between the header row's heading, act label and Skip button.
const HEADER_GAP: int = 14  # TUNING (not in GDD)
## Gap (px) between the paragraph and the closing card's tag line.
const TAG_GAP: int = 2  # TUNING (not in GDD)
## Width (px) of the Skip button (top right; touch players have no Esc key).
const SKIP_WIDTH: float = 96.0  # TUNING (not in GDD)
## Height (px) of the Skip button.
const SKIP_HEIGHT: float = 34.0  # TUNING (not in GDD)
## Opacity (0..1) of the black backdrop: the epilogue is a cutscene, the menu
## diorama does not show through.
const BACKDROP_ALPHA: float = 1.0  # TUNING (not in GDD)
## Colour of the picture window while its panel PNG is missing.
const EMPTY_COLOUR := Color("#160A21")  # TUNING (not in GDD) ink_violet
## Multiply colour of a sealed part's first panel: a dark violet silhouette
## (the Codex's way of showing what is not met yet), panning like the rest.
const SEALED_TINT := Color(0.08, 0.06, 0.12)  # TUNING (not in GDD)

# ------------------------------------------------------------------ timing (real seconds)

## A slide lasts this long plus SLIDE_PER_CHAR per character of its text
## before it moves on by itself (s); the pan spans the whole slide.
const SLIDE_BASE: float = 6.0  # TUNING (not in GDD)
## Extra slide time per character of the paragraph (s): reading time.
const SLIDE_PER_CHAR: float = 0.045  # TUNING (not in GDD) a 185-character paragraph shows ~14 s
## Crossfade (s) between two slides' pictures (instant with Reduce motion).
const PICTURE_FADE: float = 0.9  # TUNING (not in GDD)
## Delay (s) after a slide starts before its text fades in.
const TEXT_DELAY: float = 0.5  # TUNING (not in GDD)
## Fade-in time (s) of a slide's text.
const TEXT_FADE: float = 1.1  # TUNING (not in GDD)
## Fade (s) of the whole screen at open and close (UiMotion handles the open).
const CLOSE_FADE: float = 0.6  # TUNING (not in GDD)
## Presses within this long (s) of the previous advance are ignored (a tap
## arrives as a touch and an emulated click; a held key repeats).
const ADVANCE_GUARD: float = 0.3  # TUNING (not in GDD)


## True when part `part` (a PARTS row) is open in the save.
static func is_open(part: Dictionary) -> bool:
	return Meta.achievements.has(String(part["achievement"]))


## True when at least one part is open (the main menu shows its button).
static func any_open() -> bool:
	for part: Dictionary in PARTS:
		if is_open(part):
			return true
	return false


## Seconds slide text `text` stays before the next slide (SLIDE_BASE + reading time).
static func slide_time(text: String) -> float:
	return SLIDE_BASE + SLIDE_PER_CHAR * float(text.length())


## The closing card that follows part `part_id` (a PARTS id), or an empty
## Dictionary when that part has none.
static func closing_after(part_id: String) -> Dictionary:
	for c: Dictionary in CLOSINGS:
		if String(c["after"]) == part_id:
			return c
	return {}
