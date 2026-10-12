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
## Total draw weight shared by the NEW cards of the later summon classes
## (UnitData "shared_card_pool": Abomination, Rogue, Gargoyle, Frost Wraith):
## each unowned one gets min(WEIGHT_NEW, this / number of them). The GDD's
## summon roles (Archer, Mage, Mender, Warder) get WEIGHT_NEW_CORE_SUMMON
## (they had the full WEIGHT_NEW like a spell until the combined balance
## pass). A single pool over all eight classes (3.0, the first version) left
## each core class at 0.375: an army build could go most of a run without
## being offered Mages or a priest order, and collapsed on the Crimson March.
## Locked classes (the evolution-only Profane Bishop, merged Menders /
## Warders) are never offered and do not count.
const NEW_SUMMON_POOL_WEIGHT: float = 1.5  # TUNING (not in GDD)
## Draw weight of a NEW card for one of the GDD's summon roles (Archer, Mage,
## Mender, Warder: classes without UnitData "shared_card_pool"; the Warrior is
## owned from the start). The Mender and Warder, one Priest role split in
## two, take half each (UnitData "new_card_weight_mult"). Combined balance pass: at WEIGHT_NEW (1.0) a core
## class was about 1 card in 7 at the start, so a summoner could go 15+
## level-ups without being offered Mages (one Graveyard army run never saw a
## Mage or Warder card in 24 level-ups and collapsed). "The army is your
## weapon" (GDD pillar), so the roles come up half again as often as a spell.
const WEIGHT_NEW_CORE_SUMMON: float = 1.5  # TUNING (not in GDD)
## Total draw weight shared by the NEW cards of the four newer spells
## (AbilityData "shared_card_pool": Bone Spear, Soul Siphon, Corpse
## Explosion, Plague Cloud), like NEW_SUMMON_POOL_WEIGHT for the later
## classes: each unowned one gets min(WEIGHT_NEW, this / number of them).
## The GDD spells (Orb Shield, Shadow Blast) keep WEIGHT_NEW. Combined
## balance pass: with six new spells at full weight, new spells were about a
## quarter of every early hand and crowded the summon roles out.
## At the start: 2 (GDD spells) + 2 (newer spells) new-spell weight against
## 3 x 1.5 (Archer, Mage, Priest orders) + 1.5 (later classes) new-summon
## weight, beside about 12 of passives and 5 of owned upgrades.
const NEW_SPELL_POOL_WEIGHT: float = 2.0  # TUNING (not in GDD)
## Total draw weight shared by the NEW cards of the four later horde passives
## (PassiveData "shared_card_pool": Bone Plating, Unholy Precision, Unholy
## Resilience, Bound Souls), like NEW_SPELL_POOL_WEIGHT: each unowned one
## gets min(WEIGHT_NEW, this / number of them). At full weight they would add
## 4 to the about 12 of passive weight at the start and crowd the summon
## roles and spells out of early hands; owned ones level at WEIGHT_OWNED.
const NEW_PASSIVE_POOL_WEIGHT: float = 2.0  # TUNING (not in GDD)
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
