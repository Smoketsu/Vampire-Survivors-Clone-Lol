## EnvironmentArtData: keys, sizes and drawing numbers of the environment art
## (the art pass's zone floor tiles and obstacle sprites; docs/art/ART_BIBLE.md
## "Environments", GDD §15.0 "Art pass (true pixel art)" and "Art pass grid:
## 1 art px = 1 screen px"). Read by EnvironmentArt, Ground / MarchGround /
## SanctumGround and Arena. Every PNG is optional: without it the code-drawn
## floor or obstacle glyph is drawn exactly as before, so the art lands piece
## by piece. Environment art is always grid art (1 art px = 1 layout px, drawn
## through the sharp-pixel shader). Purely visual: nothing here can change a
## run. The obstacle collision sizes themselves are gameplay data and live in
## the stage files' "kinds" (`sizes`). Data only, no logic.
##
## Key scheme (paths under SpriteData.ROOT, without ".png"):
##   tiles/<zone>             base floor tile of a zone, TILE_SIZE square,
##                            seamless: tiles/graveyard, tiles/march_<style>
##                            (burned, checkpoint, camp, fortress),
##                            tiles/sanctum_<style> (courtyard, halls,
##                            cloisters, sanctuary).
##   tiles/<zone>_2, _3       optional variants of that tile (TILE_VARIANT_SUFFIXES),
##                            each chosen for TILE_VARIANT_CHANCE of the cells.
##   tiles/march_road         the March road strip along y = 0, ROAD_HEIGHT tall,
##                            any width, tiling left-right;
##                            tiles/march_road_<style> overrides it in one zone
##                            (the paved tiles/march_road_fortress).
##   obstacles/<kind>_<size>  one sprite per obstacle kind and fixed size
##                            variant: <size> from OBSTACLE_SIZE_SUFFIXES
##                            (s / l for two variants, s / m / l for three),
##                            e.g. obstacles/gravestone_s, obstacles/crypt_wall_l.
##   obstacles/<kind>_<size>_v  a rect obstacle laid out vertically (long side
##                            along y); without it a vertical rect keeps its
##                            code glyph. Circles have no _v.
class_name EnvironmentArtData
extends RefCounted

# --- Floor tiles ---------------------------------------------------------------------

## Folder prefix of the floor tile keys.
const TILE_PREFIX: String = "tiles/"  # TUNING (not in GDD) ART_BIBLE manifest
## Side (layout px = art px) of one floor tile; equal to Ground.CELL, so each
## decoration cell is exactly one tile and the tile variant comes from the
## same cell hash as its decoration.
const TILE_SIZE: float = 128.0  # TUNING (not in GDD) ART_BIBLE "Zone floors" 128x128 art px
## Suffixes of a zone tile's optional variants, in order (key = base + suffix).
## Only the variants whose PNG exists are used; at most these two.
const TILE_VARIANT_SUFFIXES: Array[String] = ["_2", "_3"]  # TUNING (not in GDD)
## Chance (0..1) that a cell shows each present variant instead of the base
## tile (two variants: 2 x this; the base tile keeps the rest).
const TILE_VARIANT_CHANCE: float = 0.2  # TUNING (not in GDD)
## Bit shift of the cell hash used for the variant roll (bits 22+; the code
## decorations read h % 1000, h >> 10 and h >> 17, so the roll stays apart).
const TILE_VARIANT_HASH_SHIFT: int = 22  # TUNING (not in GDD)
## Road strip key (MarchGround); "<ROAD_KEY>_<style>" overrides it per zone.
const ROAD_KEY: String = "tiles/march_road"  # TUNING (not in GDD) ART_BIBLE manifest
## Height (layout px = art px) the road strip is drawn: the road's full width
## (2 x CrimsonMarchStage.MARCH road_half_width), centred on y = 0.
const ROAD_HEIGHT: float = 140.0  # TUNING (not in GDD) ART_BIBLE "march_road" 140 art px

# --- Obstacles ------------------------------------------------------------------------

## Folder prefix of the obstacle sprite keys.
const OBSTACLE_PREFIX: String = "obstacles/"  # TUNING (not in GDD) ART_BIBLE manifest
## Size suffixes by the number of fixed size variants a kind has (its
## `sizes` list in the stage file, smallest first): index i of `sizes` is
## suffix i here.
const OBSTACLE_SIZE_SUFFIXES: Dictionary = {
	1: ["m"],  # TUNING (not in GDD) (no kind has one size today)
	2: ["s", "l"],  # TUNING (not in GDD) ART_BIBLE Anchor 5 gravestone_s / _l
	3: ["s", "m", "l"],  # TUNING (not in GDD)
}
## Suffix of a vertical rect obstacle's sprite (long side along y).
const VERTICAL_SUFFIX: String = "_v"  # TUNING (not in GDD)
## Feet rule: the sprite is centred horizontally on the collision shape and
## its bottom edge sits this many layout px below the shape's bottom edge
## (centre.y + radius, or + half height), so the footprint drawn at the base of
## the sprite covers the collision shape. Positive = lower. Per-key overrides
## in OBSTACLE_FOOT_OFFSETS (e.g. a tree whose roots spread past its trunk).
const OBSTACLE_FOOT_OFFSET: float = 0.0  # TUNING (not in GDD)
## Per-key overrides of OBSTACLE_FOOT_OFFSET (key -> layout px); none yet.
const OBSTACLE_FOOT_OFFSETS: Dictionary = {}  # TUNING (not in GDD)
## Drop shadow under an obstacle sprite (the sprites carry no cast shadow):
## a flattened ellipse hugging the footprint's base line.
## Width as a multiple of the footprint width.
const SHADOW_WIDTH: float = 1.1  # TUNING (not in GDD)
## Height as a fraction of the shadow width.
const SHADOW_SQUASH: float = 0.45  # TUNING (not in GDD)
## Opacity (0..1), the code glyphs' shadow alpha.
const SHADOW_ALPHA: float = 0.35  # TUNING (not in GDD)
## Offset (layout px) of the shadow from the base line's centre (light from the top-left).
const SHADOW_OFFSET: Vector2 = Vector2(3.0, 0.0)  # TUNING (not in GDD)
