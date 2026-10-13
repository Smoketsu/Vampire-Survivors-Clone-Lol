## EnvironmentArtData: keys and drawing numbers of the environment art (the art
## pass's zone floor tiles and obstacle sprites; docs/art/ART_BIBLE.md
## "Environments", GDD §15.0 "Art pass (true pixel art)" and "Art pass grid:
## 1 art px = 1 screen px"). Read by EnvironmentArt, Ground / MarchGround /
## SanctumGround and Arena. Every PNG is optional: without it the code-drawn
## floor or obstacle glyph is drawn exactly as before, so the art lands piece
## by piece. Environment art is always grid art (1 art px = 1 layout px, drawn
## through the sharp-pixel shader) and is drawn at its own texel size, so a
## tile or sprite's size is whatever its PNG is (the manifest sizes). Purely
## visual: nothing here can change a run. The obstacle collision sizes
## themselves are gameplay data and live in the stage files' "kinds"
## (`sizes`). Data only, no logic.
##
## Key scheme (paths under SpriteData.ROOT, without ".png"):
##   tiles/<zone>             base floor tile of a zone, 128x128 art px,
##                            seamless: tiles/graveyard, tiles/march_<style>
##                            (burned, checkpoint, camp, fortress),
##                            tiles/sanctum_<style> (courtyard, halls,
##                            cloisters, sanctuary). <style> is the zone's
##                            ZONES "ground" style.
##   tiles/<zone>_2, _3       optional variants of that tile (TILE_VARIANT_SUFFIXES,
##                            same size), each shown in TILE_VARIANT_CHANCE of
##                            the tile cells, picked from the floor's cell hash.
##   tiles/march_road         the March road strip along y = 0, 140 art px tall
##                            (the road's full width), any width, tiling
##                            left-right; tiles/march_road_<style> overrides it
##                            in one zone (the paved tiles/march_road_fortress).
##   obstacles/<kind>_<size>  one sprite per obstacle kind and fixed size
##                            variant: <size> from OBSTACLE_SIZE_SUFFIXES
##                            (s / l for two variants, s / m / l for three),
##                            e.g. obstacles/gravestone_s, obstacles/crypt_wall_l.
##                            Long walls are whole fixed-length sprites too (no
##                            caps-and-middle assembly): one PNG per length.
##   obstacles/<kind>_<size>_v  a rect obstacle laid out vertically (long side
##                            along y); without it a vertical rect keeps its
##                            code glyph. Circles have no _v.
class_name EnvironmentArtData
extends RefCounted

# --- Floor tiles ---------------------------------------------------------------------

## Folder prefix of the floor tile keys.
const TILE_PREFIX: String = "tiles/"  # TUNING (not in GDD) ART_BIBLE manifest
## Suffixes of a zone tile's optional variants, in order (key = base + suffix).
## Only the variants whose PNG exists are used; at most these two.
const TILE_VARIANT_SUFFIXES: Array[String] = ["_2", "_3"]  # TUNING (not in GDD)
## Chance (0..1) that a tile cell shows each present variant instead of the
## base tile (two variants: 2 x this; the base tile keeps the rest).
const TILE_VARIANT_CHANCE: float = 0.2  # TUNING (not in GDD)
## Bit shift of the cell hash used for the variant roll (bits 22+; the code
## decorations read h % 1000, h >> 10 and h >> 17, so the roll stays apart).
const TILE_VARIANT_HASH_SHIFT: int = 22  # TUNING (not in GDD)
## Road strip key (MarchGround); "<ROAD_KEY>_<style>" overrides it per zone.
const ROAD_KEY: String = "tiles/march_road"  # TUNING (not in GDD) ART_BIBLE manifest

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
## the sprite covers the collision shape and the rest of the sprite (a stone's
## face, a canopy) stands above it. Positive = lower. Per-key overrides in
## OBSTACLE_FOOT_OFFSETS (e.g. a tree whose roots spread past its trunk).
const OBSTACLE_FOOT_OFFSET: float = 0.0  # TUNING (not in GDD)
## Per-key overrides of OBSTACLE_FOOT_OFFSET (key -> layout px); none yet.
const OBSTACLE_FOOT_OFFSETS: Dictionary = {}  # TUNING (not in GDD)
## Drop shadow under an obstacle sprite (the sprites carry no cast shadow):
## a flattened ellipse hugging the footprint's base line.
## Width as a multiple of the footprint width.
const SHADOW_WIDTH: float = 1.1  # TUNING (not in GDD)
## Height as a fraction of the shadow width.
const SHADOW_SQUASH: float = 0.4  # TUNING (not in GDD)
## How far (fraction 0..1 of the shadow height) the shadow's centre sits above
## the sprite's base line: 0.5 = the shadow's bottom edge on the base line.
const SHADOW_RISE: float = 0.35  # TUNING (not in GDD)
## Opacity (0..1), the code glyphs' shadow alpha.
const SHADOW_ALPHA: float = 0.35  # TUNING (not in GDD)
## Offset (layout px) of the shadow from its base position (light from the top-left).
const SHADOW_OFFSET: Vector2 = Vector2(3.0, 0.0)  # TUNING (not in GDD)
