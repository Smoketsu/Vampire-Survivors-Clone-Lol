## CasketData — designer data for the RECOLOUR CASKETS (owner request, Oct 2026,
## GDD §15.0 "Recolour Caskets (owner request, Oct 2026)"): the Ossuary's fifth
## tab, a small gamble that replaced buying skin recolours directly. One casket
## costs PRICE Soul Ash and always holds ONE prize the player does not own yet:
##   * a RECOLOUR of an unlocked skin (each (skin, recolour) pair the skin offers,
##     RecolourData.ids_for()), in the tier RECOLOUR_TIERS gives its recolour, or
##   * a CASKET-ONLY SKIN (a SkinData.CASKET_SKINS row) not won yet, in the
##     Legendary tier (CASKET_SKIN_TIER).
## No duplicates ever: a won prize leaves the pool; an empty pool cannot be
## opened (nothing is charged). The roll (CasketLedger.roll()): a tier by WEIGHT
## among the tiers that still hold a prize (weights renormalised), then one prize
## of that tier, uniformly. PITY: after PITY_AFTER caskets in a row below
## PITY_TIER, the next one is the best non-empty tier at PITY_TIER or above (when
## such a prize exists). Every opening seeds its own RandomNumberGenerator from
## the save's casket seed and the opened count (never gameplay RNG, never the
## clock), so a save's results are reproducible; the seed is randomised once per
## save (AUTOTEST_SEED under the autotest). Purely cosmetic: nothing here touches
## a stat or a run. Caskets are kept for good: Refund all never returns them.
##
## HOW TO ADD A CASKET-ONLY SKIN (future skins): add one row to
## SkinData.CASKET_SKINS (the ACHIEVEMENT_SKINS keys without `unlock` /
## `unlock_text`: character, display_name, look, unlock_short, tint, accent, glow,
## emblem) and its art "player/<character>_<skin id>.png" (walk / idle strips as
## for any skin). Nothing else: it joins its character's skin row, enters the
## Legendary tier while not won, unlocks when won ([casket_skins]) and then offers
## its four recolours as further prizes. (The pre-run skin row fits five skins of a
## character in the hero panel, FrontDoorData.SKIN_TILES_FULL: check that row when
## a character gets a sixth.)
## Data only, no logic.
class_name CasketData
extends RefCounted

## Soul Ash price of one casket (a luxury sink: about 40% of a good Act I run).
const PRICE: int = 350  # TUNING (not in GDD) lead decision

## Rarity tier ids, lowest first (the roll, the pity floor and the UI order).
const TIER_ORDER: Array[String] = ["common", "rare", "epic", "legendary"]  # TUNING (not in GDD)

## Tier id -> its row. Keys:
##   display_name  UI word (one word).
##   weight        relative chance (> 0) while the tier holds a prize; the tiers
##                 that hold none are left out and the rest renormalised.
##   color         UI colour of the tier (bone-white, soul-teal, gold, gold).
##   shimmer       true: the reveal adds the gold sheen (UiShimmer).
const TIERS := {
	"common": {
		"display_name": "Common",  # TUNING (not in GDD)
		"weight": 60.0,  # TUNING (not in GDD) lead decision
		"color": Color(0.91, 0.88, 0.78),  # TUNING (not in GDD) bone-white
		"shimmer": false,
	},
	"rare": {
		"display_name": "Rare",  # TUNING (not in GDD)
		"weight": 30.0,  # TUNING (not in GDD) lead decision
		"color": Color(0.36, 0.88, 0.66),  # TUNING (not in GDD) soul-teal (palette soul, lightened for text)
		"shimmer": false,
	},
	"epic": {
		"display_name": "Epic",  # TUNING (not in GDD)
		"weight": 10.0,  # TUNING (not in GDD) lead decision
		"color": Color(1.0, 0.84, 0.4),  # TUNING (not in GDD) gold (UiTheme.TEXT_GOLD)
		"shimmer": false,
	},
	"legendary": {
		"display_name": "Legendary",  # TUNING (not in GDD)
		"weight": 3.0,  # TUNING (not in GDD) lead decision; counts only while a legendary prize exists
		"color": Color(1.0, 0.84, 0.4),  # TUNING (not in GDD) gold, with the sheen
		"shimmer": true,
	},
}

## RecolourData id -> the tier its prizes are in (Bone common; Blood and Abyss
## rare; Gilded and Verdant epic). A recolour missing here is common.
const RECOLOUR_TIERS := {
	"bone": "common",  # TUNING (not in GDD) lead decision
	"blood": "rare",  # TUNING (not in GDD) lead decision
	"abyss": "rare",  # TUNING (not in GDD) lead decision
	"gilded": "epic",  # TUNING (not in GDD) lead decision
	"verdant": "epic",  # TUNING (not in GDD) lead decision
}
## Tier of a casket-only skin prize (SkinData.CASKET_SKINS, while not won).
const CASKET_SKIN_TIER: String = "legendary"  # TUNING (not in GDD) lead decision

## Pity: after this many caskets in a row below PITY_TIER, the next one is
## PITY_TIER or better (the 10th).
const PITY_AFTER: int = 9  # TUNING (not in GDD) lead decision
## The pity floor tier (Epic).
const PITY_TIER: String = "epic"  # TUNING (not in GDD) lead decision

## Casket seed used under the autotest (and by tools/ossuary_check), so its
## results are fixed. Any non-zero int.
const AUTOTEST_SEED: int = 7340117  # TUNING (not in GDD)
