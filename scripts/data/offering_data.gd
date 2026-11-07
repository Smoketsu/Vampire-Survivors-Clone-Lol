## OfferingData — designer-tunable data for the GRAVE OFFERINGS (Ossuary expansion
## step 6a, owner decision 5 "include them but make them expensive", GDD §15.0
## "Relics and Grave Offerings"). An offering is a single-run boon chosen on the
## pre-run setup screen (the "Rites" strip), at most one per run. It is PAID WHEN
## THE RUN STARTS (Game._ready(), RelicLedger.pay_offering()): a choice that never
## reaches a run (Back, a closed lobby) costs nothing, and an offering the balance
## can no longer pay is dropped. Restart, Again and Next start without it (it is
## for one run; Main clears it once spent). The Ossuary's Offerings tab only lists
## them. Prices are about 40-70% of a good Necromancer run's pay (877 Soul Ash,
## docs/ossuary/ECONOMY.md): a Soul Ash sink for players who own everything.
## Effects use the relic path (RelicEffects, the same `stats` / `special` keys as
## RelicData, read through game.meta); `borrow` lends a relic for one run.
## Data only. Every price and value is TUNING (not in GDD).
class_name OfferingData
extends RefCounted

## A good Necromancer run's Soul Ash (docs/ossuary/ECONOMY.md, the mean of the nine
## stages): the reference the prices are a share of (ossuary_check prints the shares).
const GOOD_RUN_ASH: int = 877  # docs/ossuary/ECONOMY.md (measured)
## Elapsed game seconds at which Gilded Coffer's chest is placed (6:00 elapsed, the
## timer at 14:00: after the first build steps, before evolutions open at 8:00).
const COFFER_TIME: float = 360.0  # TUNING (not in GDD)
## Where that chest is placed, relative to the necromancer (px; the arena moves it
## out of obstacles).
const COFFER_OFFSET := Vector2(0.0, -70.0)  # TUNING (not in GDD)

## Display order of the offerings (Ossuary list, pre-run picker).
const ORDER := ["tithe_of_insight", "gilded_coffer", "borrowed_relic", "blood_vigil", "second_breath", "war_horn"]

## Offering definitions.
##   display_name — UI name.
##   icon         — IconGlyph kind (assets/sprites/icons/<icon>.png, a 32 px badge).
##   short        — the effect in a few words.
##   description  — flavour + the full effect.
##   price        — Soul Ash paid when the run starts (x RelicData.COST_SCALE).
##   stats / special — as RelicData (RelicEffects adds them for this run).
##   borrow       — true: a random owned relic that is not equipped fills a 4th
##                  slot for this run (drawn when the run is confirmed; needs one).
const OFFERINGS := {
	"tithe_of_insight": {"display_name": "Tithe of Insight", "icon": "offering_tithe_of_insight",
		"short": "+10% XP this run",
		"description": "Burn ash for understanding: +10% XP for one run.",
		"price": 450, "stats": {"xp_gain": 0.10}, "special": {}, "borrow": false},  # TUNING (not in GDD) owner-approved proposal
	"gilded_coffer": {"display_name": "Gilded Coffer", "icon": "offering_gilded_coffer",
		"short": "One extra chest at 6:00",
		"description": "Buy the grave's silence: one extra chest appears beside you at 6:00 elapsed.",
		"price": 500, "stats": {}, "special": {"extra_chest": 1.0}, "borrow": false},  # TUNING (not in GDD) owner-approved proposal
	"borrowed_relic": {"display_name": "Borrowed Relic", "icon": "offering_borrowed_relic",
		"short": "A random relic in a 4th slot",
		"description": "Lend a relic to the dark: a random relic you own (not equipped) fills a fourth slot for one run.",
		"price": 550, "stats": {}, "special": {}, "borrow": true},  # TUNING (not in GDD) owner-approved proposal
	"blood_vigil": {"display_name": "Blood Vigil", "icon": "offering_blood_vigil",
		"short": "+2 rerolls, +2 banishes",
		"description": "A night of vigil before the battle: +2 level-up rerolls and +2 banishes for one run.",
		"price": 400, "stats": {"rerolls": 2.0, "banishes": 2.0}, "special": {}, "borrow": false},  # TUNING (not in GDD)
	"second_breath": {"display_name": "Second Breath", "icon": "offering_second_breath",
		"short": "+1 revival this run",
		"description": "Pay the ferryman in advance: rise once more in this run.",
		"price": 600, "stats": {"revives": 1.0}, "special": {}, "borrow": false},  # TUNING (not in GDD)
	"war_horn": {"display_name": "War Horn", "icon": "offering_war_horn",
		"short": "Ultimate starts full",
		"description": "Sound the horn before the first blow: the soul meter starts full.",
		"price": 350, "stats": {}, "special": {"ult_start": 1.0}, "borrow": false},  # TUNING (not in GDD)
}


## Soul Ash price of offering `id` (x RelicData.COST_SCALE; 0 for "" or an unknown id).
static func price(id: String) -> int:
	if not OFFERINGS.has(id):
		return 0
	return RelicData._scaled(int(OFFERINGS[id]["price"]))


## True for a known offering id.
static func has(id: String) -> bool:
	return OFFERINGS.has(id)
