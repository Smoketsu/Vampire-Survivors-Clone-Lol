## ArenaData — structural, stage-independent data for the solid obstacles
## (GDD §26 collision matrix "Units <-> solid world: YES"). Each stage's own
## layout (density, clear radius, layout seed, obstacle kinds) lives in its
## stage file (`arena` key, e.g. GraveyardStage.ARENA; see StageRegistry).
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
## Minimum distance (px) from an obstacle's centre to its cell's edges.
const CELL_MARGIN: float = 80.0  # TUNING (not in GDD)
## Largest half-extent (px) of any obstacle. CELL_MARGIN - MAX_HALF_EXTENT
## (32 px) must stay above the largest colliding body radius (boss: 22 px).
const MAX_HALF_EXTENT: float = 48.0  # TUNING (not in GDD)

## Seconds a unit keeps the side it picked to walk around an obstacle, so it
## never dithers in front of the middle of a wall.
const SLIDE_MEMORY: float = 0.6  # TUNING (not in GDD)
## Step (px) used when sampling a line for obstacles (charge lanes).
const RAY_STEP: float = 8.0  # TUNING (not in GDD)
## Extra distance (px) Arena.free_point() adds to every push-out. Positions
## are 32-bit floats: far from the origin a sub-pixel penetration push can
## round away to nothing, leaving the point inside the obstacle after every
## retry (seen once as a Rogue dash ending inside an obstacle).
const FREE_POINT_MARGIN: float = 0.5  # TUNING (not in GDD)
## Camera movement (px) that triggers a redraw of the obstacle layer.
const REDRAW_CELL: float = 256.0  # TUNING (not in GDD)
## Half-size (px) of the area drawn around the redraw cell centre.
const DRAW_HALF_EXTENT: float = 1200.0  # TUNING (not in GDD)
