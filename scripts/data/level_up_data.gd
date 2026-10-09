## LevelUpData — designer-tunable rules of the level-up panel (GDD §9.1
## "XP crystals -> level-ups -> three randomized choices ... Limited rerolls,
## skips and banishes", §10.4 level-up panel):
##   * reroll / banish charges per run and the skip reward (GDD open question 7
##     gives no counts; prototype decision recorded in GDD §15.0),
##   * card weights for the weighted (not uniform) offer draw,
##   * the fallback cards offered once nothing is left to upgrade (GDD open
##     question 8, "situational boosts").
## All numbers are TUNING (not in GDD).
class_name LevelUpData
extends RefCounted

## Rerolls per run: redraws every card of the current level-up.
const REROLLS: int = 2  # TUNING (not in GDD) decision for open question 7
## Banishes per run: removes one offered item from the run and redraws that card.
const BANISHES: int = 2  # TUNING (not in GDD) decision for open question 7
## Skips are unlimited; each skip heals this fraction of the necromancer's max HP.
const SKIP_HEAL_FRACTION: float = 0.08  # TUNING (not in GDD)

## Draw weight of a card for an item not owned yet.
const WEIGHT_NEW: float = 1.0  # TUNING (not in GDD)
## Draw weight of an upgrade to an item already owned (owned items come up more).
const WEIGHT_OWNED: float = 2.5  # TUNING (not in GDD)
## Weight multiplier for a card on an evolution path: the paired passive of an
## owned spell, or an owned spell whose paired passive is owned.
const WEIGHT_EVOLUTION_PATH: float = 1.5  # TUNING (not in GDD)
## Weight multiplier for a "dead" card (no current effect on the build, e.g.
## an army passive with no summon class owned). At most CARDS-1 dead cards are
## offered while a live card exists.
const WEIGHT_DEAD: float = 0.2  # TUNING (not in GDD)

## Max-HP bonus of the "Grave Fortitude" fallback card (also heals that much).
const FORTITUDE_MAX_HP: float = 10.0  # TUNING (not in GDD)

## Fallback cards, in the order they fill empty card slots when fewer real
## upgrades than cards remain (everything maxed, banished or slots full).
## Dark Restoration heals PlayerData.FALLBACK_HEAL_FRACTION of max HP.
const FALLBACK_ORDER := ["dark_restoration", "grave_fortitude", "call_of_the_grave"]

## Fallback card definitions (display_name, icon, description, tag).
const FALLBACKS := {
	"dark_restoration": {
		"display_name": "Dark Restoration",
		"icon": "heal",
		"description": "Drain the fallen to mend your body.",
		"tag": "RESTORE",
	},
	"grave_fortitude": {
		"display_name": "Grave Fortitude",
		"icon": "grave_fortitude",
		"description": "Bind a sliver of grave-earth to your flesh.",
		"tag": "BOON",
	},
	"call_of_the_grave": {
		"display_name": "Call of the Grave",
		"icon": "call_of_the_grave",
		"description": "Every fallen summon claws its way back at once.",
		"tag": "BOON",
	},
}
