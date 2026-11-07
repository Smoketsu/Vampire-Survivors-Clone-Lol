## RecolourData — designer data for SKIN RECOLOURS (Ossuary expansion step 6b,
## GDD §15.0 "Ossuary recolours"): a Soul Ash sink for players who own
## everything. A recolour is a palette swap of a skin the player already owns
## (default, Hyper, achievement and universal skins alike): the same sprite,
## walk and idle strips with every colour mapped to another colour family
## (Bone, Blood, Abyss, Gilded, Verdant). No art files: Recolour remaps the
## sprite's pixels once per sprite and recolour and caches the result; the one
## draw path is SpriteBank.draw()'s `recolour` parameter, so the world, the
## pre-run screen, the portraits and the co-op bust all follow.
##
## PURELY COSMETIC (CLAUDE.md, GDD §15.0 resolves open question 42): a recolour
## never touches a stat, a rule or the simulation; it is not in the co-op
## checksum (it only travels in the loadout so the partner sees it).
## Owned per skin (each skin owns its own recolours) and kept for good. Since
## the Recolour Caskets (owner request, Oct 2026, GDD §15.0 "Recolour Caskets
## (owner request, Oct 2026)") recolours are NOT bought: they are won from the
## Ossuary's Caskets tab (CasketData, CasketLedger), where each recolour has a
## RARITY (CasketData.RECOLOUR_TIERS: Bone common, Blood / Abyss rare, Gilded /
## Verdant epic) instead of the old price; recolours an older save bought stay
## owned. The pre-run screen's skin row wears an owned one and previews the rest
## (PreRunHyperSkins). Meta keeps the owned set and the choice per skin
## ([recolours], [recolour_pick]).
##
## The remap (Recolour.color()), per pixel in HSV, uses the numbers below:
##   * the hue of a coloured pixel moves to `hue`, keeping a share `spread` of
##     its distance from the necromancer's purple (REF_HUE), so a skin keeps
##     some variety (gold trim stays warmer than the robe) inside the family;
##   * grey pixels (outlines, bone) get the family's tint: their saturation
##     becomes `tint_sat` at `hue`; coloured pixels' saturation is multiplied
##     by `sat_mul`; value is multiplied by `val_mul` and lifted by `val_add`.
## No logic here beyond lookups; Meta decides what is owned.
class_name RecolourData
extends RefCounted

## Hue (0..1) the necromancer art is drawn around: the purple robe and staff
## (the Gravecaller's sprite); a pixel's distance from it is what `spread` keeps.
const REF_HUE: float = 0.75  # TUNING (not in GDD)
## How fast a pixel counts as coloured rather than grey: its weight is
## min(1, saturation x NEUTRAL_GAIN), so saturation 0.25 and above is fully
## coloured and greys (bone highlights, outlines) take the family's tint.
const NEUTRAL_GAIN: float = 4.0  # TUNING (not in GDD)

## Recolour ids in UI (and rarity) order. "gilded" is offered on every skin but
## the Hyper skins (already gold), "verdant" only on those (see ids_for()).
const ORDER: Array[String] = ["bone", "blood", "abyss", "gilded", "verdant"]  # TUNING (not in GDD)

## Recolour id -> its row (its rarity is CasketData.RECOLOUR_TIERS). Keys:
##   display_name  UI name (one word).
##   swatch        UI chip colour (the family's mid tone).
##   hue           target hue 0..1 of coloured pixels (HSV).
##   spread        0..1 share of a pixel's hue offset from REF_HUE that survives.
##   sat_mul       multiplier of a coloured pixel's saturation.
##   tint_sat      saturation 0..1 given to grey pixels (the family's cast).
##   val_mul       multiplier of every pixel's value (brightness).
##   val_add       extra value as a fraction of the pixel's own value (brightens
##                 mid and light tones, leaves outlines dark).
const RECOLOURS := {
	"bone": {
		"display_name": "Bone",  # TUNING (not in GDD) a near-greyscale ivory (common)
		"swatch": Color(0.86, 0.82, 0.68),
		"hue": 0.11, "spread": 0.05, "sat_mul": 0.18, "tint_sat": 0.12, "val_mul": 1.08, "val_add": 0.0,
	},
	"blood": {
		"display_name": "Blood",  # TUNING (not in GDD) rare
		"swatch": Color(0.78, 0.14, 0.2),
		"hue": 0.985, "spread": 0.18, "sat_mul": 1.05, "tint_sat": 0.20, "val_mul": 0.95, "val_add": 0.0,
	},
	"abyss": {
		"display_name": "Abyss",  # TUNING (not in GDD) rare
		"swatch": Color(0.16, 0.55, 0.68),
		"hue": 0.52, "spread": 0.20, "sat_mul": 0.95, "tint_sat": 0.25, "val_mul": 0.92, "val_add": 0.0,
	},
	"gilded": {
		"display_name": "Gilded",  # TUNING (not in GDD) epic, with Verdant
		"swatch": Color(0.92, 0.72, 0.2),
		"hue": 0.115, "spread": 0.15, "sat_mul": 1.1, "tint_sat": 0.35, "val_mul": 1.18, "val_add": 0.02,
	},
	"verdant": {
		"display_name": "Verdant",  # TUNING (not in GDD) epic; takes Gilded's place on the (gold) Hyper skins
		"swatch": Color(0.2, 0.7, 0.35),
		"hue": 0.34, "spread": 0.20, "sat_mul": 1.0, "tint_sat": 0.22, "val_mul": 0.95, "val_add": 0.0,
	},
}


## True when `id` is a recolour id ("" is not: it means no recolour).
static func has(id: String) -> bool:
	return RECOLOURS.has(id)


## UI name of recolour `id` ("Default" for "" or an unknown id).
static func display_name(id: String) -> String:
	return String((RECOLOURS[id] as Dictionary)["display_name"]) if RECOLOURS.has(id) else "Default"


## UI chip colour of recolour `id` (white for "" / unknown: the skin's own palette).
static func swatch(id: String) -> Color:
	if not RECOLOURS.has(id):
		return Color.WHITE
	var row: Dictionary = RECOLOURS[id]  # The recolour's row.
	return row["swatch"]


## The recolours skin `skin_id` offers, in ORDER: four of the five. The Hyper
## skins (already gilded) offer Verdant instead of Gilded. [] for an unknown skin.
static func ids_for(skin_id: String) -> PackedStringArray:
	var row := SkinData.skin(skin_id)  # The skin ({} = unknown).
	if row.is_empty():
		return PackedStringArray()
	return ids_for_kind(String(row.get("kind", "")))


## The recolours a skin of SkinData kind `kind` offers, in ORDER (the "hyper"
## kind: Verdant in place of Gilded). The casket check passes rows of its own.
static func ids_for_kind(kind: String) -> PackedStringArray:
	var out := PackedStringArray()  # Recolour ids.
	var hyper := kind == "hyper"  # A gold Hyper skin.
	for id: String in ORDER:
		if (id == "gilded" and hyper) or (id == "verdant" and not hyper):
			continue
		out.append(id)
	return out


## True when skin `skin_id` offers recolour `id`.
static func offered(skin_id: String, id: String) -> bool:
	return ids_for(skin_id).has(id)
