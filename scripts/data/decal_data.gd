## DecalData: keys and drawing numbers of the floor decals of the art pass
## (docs/art/ART_BIBLE.md "Decals", GDD §15.0 "Floor decals"). Read by
## EnvironmentArt.draw_decal() / draw_strip() for Ground, MarchGround and
## SanctumGround. Data only, no logic; purely visual (nothing here can change
## a run).
##
## The code floors scatter small decorations by a stable cell hash (one per
## 128 px cell at most, at a hashed point p, chosen by a hashed roll). On a
## zone's TILE floor (its tiles/<zone>.png exists) each decoration is either
##   (a) a pixel-art decal, decals/<zone>_<name>.png (plus optional look or size
##       variants <key>_2, <key>_3), drawn flat at its own texel size (1 art px =
##       1 layout px, sharp-pixel shader) and centred on p + OFFSETS[key], the
##       same hashed point and roll as the code decoration, so the layout and
##       determinism are unchanged;
##   (b) dropped (DROPPED) when the tile already shows it; or
##   (c) still code-drawn: a soft translucent effect pixel art cannot do
##       better (the Graveyard fog patches, the Fortress Approach tower
##       shadows, the Final Sanctuary's stained-glass light pools), or any
##       decal whose PNG is missing (the fallback).
## Without the zone's tile PNG every decoration is code-drawn exactly as before.
## The Graveyard's solid-looking tombstone, stone cross and dead tree stay
## skipped on the tile floor (Ground.SOLID_DECOR_ROLL).
##
## Decisions per zone (decoration: decal key or decision):
##   Graveyard: fog = code; grass tufts = graveyard_grass (3 variants); open
##     grave = graveyard_grave (2).
##   March I, Burned Road: ash drift = march_burned_ash (2); charred stump =
##     march_burned_stump (2, cut flush with the ground); embers =
##     march_burned_embers (2); spent arrow = march_arrow (2, also the odd arrow
##     on the road in every March zone); broken plank = march_burned_plank (2).
##   March II, Checkpoint: grass and mud dropped (the tile is grass with mud
##     patches); sharpened stakes = march_checkpoint_stakes (2, fallen flat: the
##     standing stakes are an obstacle kind); pennant =
##     march_checkpoint_pennant (2, trampled flat).
##   March III, Siege Camp: trampled dirt dropped (the tile variants are
##     trampled patches); campfire = march_camp_campfire (2, a burnt-out ring,
##     its glow included); rope and peg = march_camp_rope (2); small crate =
##     march_camp_crate (2, smashed flat: crates are an obstacle kind).
##   March IV, Fortress Approach: cobbles and rubble dropped (the tile is
##     cobbles and grit; rubble is an obstacle kind); banner post =
##     march_fortress_banner (2, a trampled banner cloth); tower shadow = code.
##   Sanctum I, Courtyards: crack and paler slab dropped (the flagstone tile has
##     its own cracks and slab shades); moss = sanctum_courtyard_moss (2); gold
##     inlay star = sanctum_courtyard_star (2); petals =
##     sanctum_courtyard_petals (2).
##   Sanctum II, Halls: gold tesserae and diamond inlay dropped (the mosaic
##     tile has its tesserae and a diamond lattice with gold nodes); rosette =
##     sanctum_halls_rosette (2, snapped to the tile's 8 px tesserae); carpet
##     runner = the strip sanctum_halls_carpet (CARPET_KEY).
##   Sanctum III, Cloisters: turf dropped (the tile is turf inside stone
##     walks); flowers = sanctum_cloisters_flowers (2); sundial ring =
##     sanctum_cloisters_sundial (2); leaves = sanctum_cloisters_leaves (2).
##   Sanctum IV, Final Sanctuary: stained-glass light pools = code; marble vein
##     dropped (the marble tile has its veins); inlaid square =
##     sanctum_sanctuary_inlay.
##   Gullhaven Harbour (harbour placeholder art pass): tide puddles = code (soft
##     translucent pools, on every zone); shells = harbour_mudflats_shells (2),
##     kelp = harbour_mudflats_kelp (2); scales = harbour_market_scales (2), rope
##     coil = harbour_market_rope (2), dropped fish = harbour_market_fish (2);
##     coral crust = harbour_chapel_coral (2), barnacles =
##     harbour_chapel_barnacles (2), the Eye's sigil = harbour_chapel_sigil;
##     mooring ring = harbour_seawall_ring, rusted chain = harbour_seawall_chain
##     (2), gull feather = harbour_seawall_feather (2).
## The Sanctum corruption overlay is drawn over the decals as over the tiles
## (SanctumGround._draw()).
class_name DecalData
extends RefCounted

## Folder prefix of the decal keys (under SpriteData.ROOT, without ".png").
const PREFIX: String = "decals/"  # TUNING (not in GDD) ART_BIBLE "Decals"
## Suffixes of a decal's optional variants, in order (key = base + suffix);
## only the variants whose PNG exists are used.
const VARIANT_SUFFIXES: Array[String] = ["_2", "_3"]  # TUNING (not in GDD)
## Bit shift of the cell hash used to pick a decal variant ((h >> this) %
## count): bits the decoration's roll (h % 1000) and point (h >> 10, h >> 17)
## barely touch, so variants spread evenly over every kind.
const VARIANT_HASH_SHIFT: int = 4  # TUNING (not in GDD)

## Decal key -> offset (layout px) from the code decoration's hashed point p
## to the decal's centre: the centre of what the code draws there (e.g. the
## spent arrow runs from p to p + (9, -9)). Keys not listed are centred on p.
const OFFSETS: Dictionary = {
	"graveyard_grass": Vector2(0.0, -3.0),  # TUNING (not in GDD) code tufts rise 7 px above p
	"march_arrow": Vector2(4.0, -4.0),  # TUNING (not in GDD) code arrow p -> p + (9, -9)
	"march_burned_plank": Vector2(5.0, 2.0),  # TUNING (not in GDD) code plank Rect2(p, 10 x 4)
	"march_checkpoint_stakes": Vector2(1.0, -5.0),  # TUNING (not in GDD) code stakes x -7..9, 10 px tall
	"march_checkpoint_pennant": Vector2(5.0, -9.0),  # TUNING (not in GDD) code pole 18 px, flag 10 px wide
	"march_camp_rope": Vector2(8.0, -3.0),  # TUNING (not in GDD) code rope p -> p + (16, -6)
	"march_camp_crate": Vector2(6.0, 5.0),  # TUNING (not in GDD) code crate Rect2(p, 12 x 10)
	"march_fortress_banner": Vector2(5.0, -11.0),  # TUNING (not in GDD) code post 22 px, flag 9 px wide
	"sanctum_courtyard_petals": Vector2(6.0, 2.0),  # TUNING (not in GDD) code petals x 0..12
	"sanctum_cloisters_flowers": Vector2(14.0, 4.0),  # TUNING (not in GDD) code flowers x 0..28
	"sanctum_cloisters_leaves": Vector2(9.0, 3.0),  # TUNING (not in GDD) code leaves x 0..18
	"sanctum_sanctuary_inlay": Vector2(9.0, 9.0),  # TUNING (not in GDD) code inlay Rect2(p, 18 x 18)
	# Gullhaven Harbour (harbour placeholder art pass): the centre of each code decoration.
	"harbour_mudflats_shells": Vector2(6.0, 2.0),  # TUNING (not in GDD) code shells x 0..12, y 0..5
	"harbour_mudflats_kelp": Vector2(11.0, -1.0),  # TUNING (not in GDD) code kelp p -> p + (22, -3)
	"harbour_market_scales": Vector2(12.0, 8.0),  # TUNING (not in GDD) code scales x 0..24, y 0..16
	"harbour_market_fish": Vector2(7.0, 0.0),  # TUNING (not in GDD) code fish p -> p + (14, 0)
	"harbour_chapel_coral": Vector2(3.0, -2.0),  # TUNING (not in GDD) code crust at p and p + (6, -4)
	"harbour_chapel_barnacles": Vector2(8.0, 2.0),  # TUNING (not in GDD) code barnacles x 0..15, y 0..5
	"harbour_seawall_chain": Vector2(10.0, 0.0),  # TUNING (not in GDD) code links x 0..21
	"harbour_seawall_feather": Vector2(5.0, -1.0),  # TUNING (not in GDD) code feather p -> p + (10, -3)
}

## Decal key -> grid (layout px) its top-left corner snaps to (floored), so an
## inlay sits on the tile's own joints: the Sanctified Halls' mosaic has 8 px
## tesserae from the world origin.
const SNAP: Dictionary = {
	"sanctum_halls_rosette": 8.0,  # TUNING (not in GDD) sanctum_halls tile: 8 px tesserae
}

## Decorations dropped on the tile floor (no decal, no code drawing): the tile
## already shows them (see the header).
const DROPPED: Array[String] = [
	"march_checkpoint_grass",  # TUNING (not in GDD) the tile is forest grass
	"march_checkpoint_mud",  # TUNING (not in GDD) tile variants: mud with boot prints
	"march_camp_trampled",  # TUNING (not in GDD) tile variants: trampled patches
	"march_fortress_cobbles",  # TUNING (not in GDD) the tile is cobbles
	"march_fortress_rubble",  # TUNING (not in GDD) tile grit; rubble is an obstacle kind
	"sanctum_courtyard_crack",  # TUNING (not in GDD) the slabs have their own cracks
	"sanctum_courtyard_slab",  # TUNING (not in GDD) the slabs have their own shades
	"sanctum_halls_tesserae",  # TUNING (not in GDD) the tile is tesserae
	"sanctum_halls_diamond",  # TUNING (not in GDD) the tile has a diamond lattice
	"sanctum_cloisters_turf",  # TUNING (not in GDD) the tile is turf inside walks
	"sanctum_sanctuary_vein",  # TUNING (not in GDD) the marble tile has veins
]

## The Sanctified Halls' carpet runner: a strip piece (128 x 36 art px)
## repeating left-right, one piece per decoration cell along every fourth
## cell row, centred on the code runner's centre line.
const CARPET_KEY: String = "sanctum_halls_carpet"  # TUNING (not in GDD) ART_BIBLE "Decals"
