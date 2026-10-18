## EpilogueData — the CAMPAIGN EPILOGUE (GDD §15.0 "Ul-Thalos, the Risen
## Spire": the owner-approved proposal's "The Dead God Serves unlocks the
## campaign epilogue", which also closes Dawn Extinguished's old "the campaign
## epilogue" hook). A short text in two parts, one per act, each opened by its
## act's last achievement (MetaData.ACHIEVEMENTS): the Act I part by Dawn
## Extinguished (Seraphine slain), the Act II part by The Dead God Serves
## (Vhal'Neth slain and raised). The main menu shows its Epilogue button once
## either part is open (FrontDoorData.MENU_ITEMS, EpilogueScreen). Data only.
class_name EpilogueData
extends RefCounted

## The parts in reading order: achievement id that opens it, heading, the
## act's name, and its paragraphs.
const PARTS := [
	{
		"achievement": "dawn_extinguished",
		"act": "Act I: The Crimson Covenant",
		"heading": "When the Dawn Went Out",
		"lines": [
			"The Sanctum burned for three nights. When the relic shattered, the light that had ruled the realm for a thousand years went out like a candle in a crypt.",
			"Across the land the other holy orders took up arms, but there was no Covenant left to lead them. The dead walked the pilgrim roads, and the living learned to bar their doors at dusk.",
			"The necromancer did not sit the empty throne. Something else was calling the dead now, from far beneath the sea, and the army began to drift toward the coast.",
		],
	},
	{
		"achievement": "the_dead_god_serves",
		"act": "Act II: The Ancient Eye",
		"heading": "The Dead God Serves",
		"lines": [
			"The Eye's faithful had prayed for the Dreaming Mother to wake and claim every corpse as her vessel. They had not prayed for who would answer.",
			"Vhal'Neth was dead long before her city sank, and the dead belong to the necromancer. The Eye's own ritual, sung by a thousand drowned throats, bound her to a new master.",
			"Ul-Thalos sinks back beneath the waves. Somewhere far below, a god dreams of the necromancer's will, and the sea gives up its dead whenever it is asked.",
			"The Covenant is ash. The Eye is blind. The army is endless, and it is only beginning.",
		],
	},
]
## Line shown in place of a part that is still sealed.
const SEALED: String = "Sealed. %s to read on."  # TUNING (not in GDD) %s = the achievement's goal
## Screen title (TITLE tier).
const TITLE: String = "Epilogue"  # TUNING (not in GDD)
## Outer size of the screen's ornate panel (px; fits 1280 x 600, phones).
const PANEL_SIZE := Vector2(980.0, 560.0)  # TUNING (not in GDD)
## Opacity (0..1) of the backdrop over the main menu.
const BACKDROP_ALPHA: float = 0.96  # TUNING (not in GDD)
## Width (px) of the Back button.
const BACK_WIDTH: float = 120.0  # TUNING (not in GDD)
## Height (px) of the Back button.
const BACK_HEIGHT: float = 42.0  # TUNING (not in GDD)


## True when part `part` (a PARTS row) is open in the save.
static func is_open(part: Dictionary) -> bool:
	return Meta.achievements.has(String(part["achievement"]))


## True when at least one part is open (the main menu shows its button).
static func any_open() -> bool:
	for part: Dictionary in PARTS:
		if is_open(part):
			return true
	return false
