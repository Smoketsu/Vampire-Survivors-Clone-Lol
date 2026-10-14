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
## Draw weight of a NEW card for one of the GDD's summon roles (Archer, Mage,
## Mender, Warder: classes without UnitData "shared_card_pool"; the Warrior is
## owned from the start). The Mender and Warder, one Priest role split in
## two, take half each (UnitData "new_card_weight_mult"). Combined balance pass: at WEIGHT_NEW (1.0) a core
## class was about 1 card in 7 at the start, so a summoner could go 15+
## level-ups without being offered Mages (one Graveyard army run never saw a
## Mage or Warder card in 24 level-ups and collapsed). "The army is your
## weapon" (GDD pillar), so the roles come up half again as often as a spell.
const WEIGHT_NEW_CORE_SUMMON: float = 1.5  # TUNING (not in GDD)
## Draw weight of a NEW card for one of the later items: the spells, summon
## classes and passives flagged "shared_card_pool" in AbilityData, UnitData and
## PassiveData (every spell after Orb Shield / Shadow Blast, every class after
## the GDD roles, every horde / spell passive added after the first twelve).
## Half an original item's WEIGHT_NEW, so the GDD summon roles still lead
## early hands (the reason these items were held back), but each later item
## keeps its own weight however many there are. Owner decision (Oct 2026
## playtest, "I rarely ever see the newer additions"): replaces three shared
## pools (spells 2.0, classes 1.5, passives 2.0 split between every unowned
## later item), which had fallen to ~0.2 per item (~2% of hands each) as the
## roster grew to 9 / 7 / 10 later items; at 0.5 each is offered in ~5% of hands.
const WEIGHT_NEW_LATER: float = 0.5  # TUNING (not in GDD) owner decision
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
