## ArenaData — immutable design data for the solid obstacles of the
## Desecrated Graveyard (GDD §11 art: "crypts, broken tombs, dead trees";
## GDD §26 collision matrix "Units <-> solid world: YES").
##
## The arena is an endless plane, so obstacles are generated per CELL from a
## stable hash (the same layout every run). At most one obstacle lives in a
## cell, and it is kept CELL_MARGIN px away from the cell's edges. Because
## CELL_MARGIN - MAX_HALF_EXTENT is larger than every colliding body radius,
## a body can only ever touch the obstacle of the cell its centre is in:
## collision is one dictionary lookup per body, no broad phase needed.
##
## The GDD has no numbers for obstacles; everything is TUNING (not in GDD).
class_name ArenaData
extends RefCounted

## Side (px) of one obstacle generation cell (at most one obstacle per cell).
const CELL: float = 256.0  # TUNING (not in GDD)
## Chance (0..1) that a cell holds an obstacle; low on purpose ("sparse").
const DENSITY: float = 0.22  # TUNING (not in GDD)
## Minimum distance (px) from an obstacle's centre to its cell's edges.
const CELL_MARGIN: float = 80.0  # TUNING (not in GDD)
## Largest half-extent (px) of any obstacle. CELL_MARGIN - MAX_HALF_EXTENT
## (32 px) must stay above the largest colliding body radius (boss: 22 px).
const MAX_HALF_EXTENT: float = 48.0  # TUNING (not in GDD)
## No obstacle centre within this distance (px) of the run start, so the
## opening seconds are never cramped.
const CLEAR_RADIUS: float = 220.0  # TUNING (not in GDD)
## Seed mixed into the cell hash; change it to re-roll the layout.
const LAYOUT_SEED: int = 7177  # TUNING (not in GDD)

## Obstacle kinds. Field reference:
##   weight      — relative chance among obstacle cells.
##   shape       — "circle" or "rect" (axis-aligned) collision shape.
##   radius_min / radius_max — circle collision radius range (px).
##   long_min / long_max     — rect long side range (px); the orientation
##                             (horizontal / vertical) is picked per cell.
##   short       — rect short side (px).
const KINDS := {
	# Broken tombs and headstones (GDD §11 art).
	"gravestone": {"weight": 0.45, "shape": "circle", "radius_min": 11.0, "radius_max": 15.0},  # TUNING (not in GDD)
	# Dead trees (GDD §11 art); the collision is the trunk, branches are cosmetic.
	"dead_tree": {"weight": 0.25, "shape": "circle", "radius_min": 13.0, "radius_max": 18.0},  # TUNING (not in GDD)
	# Crypt walls (GDD §11 art "crypts").
	"crypt_wall": {"weight": 0.30, "shape": "rect", "long_min": 64.0, "long_max": 96.0, "short": 20.0},  # TUNING (not in GDD)
}

## Seconds a unit keeps the side it picked to walk around an obstacle, so it
## never dithers in front of the middle of a wall.
const SLIDE_MEMORY: float = 0.6  # TUNING (not in GDD)
## Step (px) used when sampling a line for obstacles (charge lanes).
const RAY_STEP: float = 8.0  # TUNING (not in GDD)
## Camera movement (px) that triggers a redraw of the obstacle layer.
const REDRAW_CELL: float = 256.0  # TUNING (not in GDD)
## Half-size (px) of the area drawn around the redraw cell centre.
const DRAW_HALF_EXTENT: float = 1200.0  # TUNING (not in GDD)
