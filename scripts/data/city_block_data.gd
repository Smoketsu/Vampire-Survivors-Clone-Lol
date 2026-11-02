## CityBlockData — the numbers of THE CITY-BLOCK LAYOUT (Act VIII, the Last
## Line; GDD §15.0 "City blocks"; owner: "let's try to make the maps on this
## stage a series of blocks and rectangular streets with alleys rather than our
## normal"). CityBlocks (scripts/core/city_blocks.gd) builds the layout from
## these defaults, the stage's STAGE "blocks" dictionary on top, and the zone
## layout's "blocks" dictionary on top of that (looks and open-lot share only).
##
## THE GRID. The plane is tiled with LOTS of one building each (axis-aligned
## rects). Along each axis the gaps between buildings alternate: a STREET
## (`street` px between faces: a `roadway` px roadway and two `sidewalk` px
## sidewalks), then an ALLEY (`alley` px between faces), then a street, ... So a
## BLOCK is 2 x 2 buildings with a cross of alleys through it, and streets run
## around every block. A lot is a building plus half of each gap beside it:
##   lot pitch x = building_w + (street + alley) / 2   (392 px by default)
##   lot pitch y = building_h + (street + alley) / 2   (328 px by default)
## Lot ix spans [ix * pitch_x, (ix + 1) * pitch_x); an EVEN lot has its street
## half on its low side (the building starts street / 2 into it), an ODD lot its
## alley half (the building starts alley / 2 into it). Street centre lines lie
## at x = k * 2 * pitch_x and y = k * 2 * pitch_y, alley centre lines at the
## odd multiples of the pitch, so (0, 0), the run's start, is a crossing of two
## streets.
##
## THE ONE-LOOKUP INVARIANT. Half an alley (alley / 2 = 40 px) is more than any
## body radius (MAX_BODY_RADIUS = 36 px), so a body can only ever touch the
## building of the lot its centre is in: collision stays one cached lookup per
## body, analytically (no broad phase). CityBlocks push_error()s at stage load
## for any kind on the stage whose radius is above MAX_BODY_RADIUS.
##
## WRECKS. A destroyed vehicle leaves a burning wreck (CityBlocks.add_wreck()):
## a rect of half-size at most WRECK_HALF_MAX, snapped to the centre of its
## WRECK_CELL px wreck cell. Wreck cells tile each STREET's centre strip (a cell
## is WRECK_CELL px along the street and the street's width across it), so a
## snapped wreck always sits on the lane's centre line, clear of both building
## faces; its cell's half length minus WRECK_HALF_MAX (64 - 28 = 36 px) keeps
## the one-lookup invariant along the street. At most one wreck per cell, none
## within WRECK_CROSSING_CLEAR px of a crossing (vehicles turn there), at most
## WRECK_MAX in all (the oldest burns away).
##
## Data only (CLAUDE.md rule 2). The GDD gives no numbers: every value is
## TUNING (not in GDD) unless marked as the owner-approved proposal.
class_name CityBlockData
extends RefCounted

## Largest body radius (px) any kind on a `blocks` stage may have: below half
## an alley, so the one-lookup invariant holds (see the header). Bosses on a
## blocks stage must stay within it too (phase 2).
const MAX_BODY_RADIUS: float = 36.0  # TUNING (not in GDD) (alley / 2 = 40 px leaves 4 px of float slack)

## The layout's defaults. A stage's STAGE "blocks" dictionary overrides any key
## (the grid keys only there); a zone layout's "blocks" may override the looks
## (`styles`, `open_share`, `open_styles`) and never moves a street.
##   building_w   — px, a building's width (x).
##   building_h   — px, a building's height (y).
##   street       — px between two building faces across a street.
##   roadway      — px of asphalt in a street (the rest is two sidewalks).
##   sidewalk     — px of one sidewalk (street = roadway + 2 x sidewalk).
##   alley        — px between two building faces across an alley.
##   open_share   — share (0..1) of lots with no building (plazas, parking,
##                  parks), rolled per lot from the layout seed.
##   styles       — rooftop style -> weight (CityGlyphs.draw_building(): the
##                  tiles/city_roof_<style> PNGs when present).
##   open_styles  — open-lot look -> weight (CityGround: plaza, parking, park).
##   start_open   — the lot forced open next to the run's start crossing
##                  (Vector2i lot index; the start sits on a street crossing).
const DEFAULTS := {
	"building_w": 256.0,  # TUNING (not in GDD) brief: buildings 256 x 192 px
	"building_h": 192.0,  # TUNING (not in GDD)
	"street": 192.0,  # TUNING (not in GDD) brief: a 144 px roadway and two 24 px sidewalks
	"roadway": 144.0,  # TUNING (not in GDD)
	"sidewalk": 24.0,  # TUNING (not in GDD)
	"alley": 80.0,  # TUNING (not in GDD) brief: 80 px between faces
	"open_share": 0.2,  # TUNING (not in GDD) brief: a seeded share of 0.2
	"styles": {"tenement": 0.4, "warehouse": 0.3, "tower": 0.2, "bunker": 0.1},  # TUNING (not in GDD) the art pass's four roofs
	"open_styles": {"plaza": 0.4, "parking": 0.4, "park": 0.2},  # TUNING (not in GDD)
	"start_open": Vector2i(0, 0),  # TUNING (not in GDD) the lot down-right of the start crossing
}

## Rooftop styles CityGlyphs knows (the art pass's tiles/city_roof_<style>).
const ROOF_STYLES: Array[String] = ["tenement", "warehouse", "bunker", "tower"]
## Open-lot looks CityGround knows.
const OPEN_STYLES: Array[String] = ["plaza", "parking", "park"]

# --- Street steering (CityBlocks.street_dir(), read by Enemy.physics_step()) -----------------

## Ticks between two street-steering decisions of one enemy (staggered by its
## think slot; between them it keeps its last street direction, or goes
## straight at its goal when that was clear). A cost cap: the decision probes
## the layout a few times.
const STEER_EVERY: int = 4  # TUNING (not in GDD)
## px of clear straight line that keep an enemy going straight at its goal.
const STEER_LOOK: float = 96.0  # TUNING (not in GDD)
## px of clear straight line an enemy that left the straight line needs to go
## straight again (hysteresis: no flip-flop at the edge of the look-ahead).
const STEER_LOOK_BACK: float = 160.0  # TUNING (not in GDD)
## px of slack within which a body counts as touching a building or wreck for
## the steering (CityBlocks.street_dir(): a body pressed against a face whose
## straight line runs into it is routed, never sent straight; the integration
## fix for the co-op corner trap).
const STEER_CONTACT_SLACK: float = 1.5  # TUNING (not in GDD) px

# --- Wrecks (CityBlocks.add_wreck(); Convoy places them) ---------------------------------------

## px: the length (along its street) of one wreck cell.
const WRECK_CELL: float = 128.0  # TUNING (not in GDD) brief: 128 px wreck cells
## px: most half-size a wreck rect may have on either axis.
const WRECK_HALF_MAX: float = 28.0  # TUNING (not in GDD) brief: half-size at most 28 px
## px: the across-the-street half-size of a wreck (its along-the-street half is
## the vehicle's own, clamped to WRECK_HALF_MAX).
const WRECK_HALF_ACROSS: float = 18.0  # TUNING (not in GDD) a car's half width
## Most wrecks standing at once (the oldest burns away when one more is placed).
const WRECK_MAX: int = 24  # TUNING (not in GDD) brief: at most 24 in all
## px: no wreck centre within this distance (along the street) of a crossing's
## edge, so vehicles can still turn there.
const WRECK_CROSSING_CLEAR: float = 16.0  # TUNING (not in GDD) (first pass 40: most dead vehicles left no wreck)

# --- Drawing (CityGround, CityGlyphs; visual only) ----------------------------------------

## px: length of one dash of a street's centre line, and the gap between two.
const LANE_DASH: float = 24.0  # TUNING (not in GDD)
## px: the gap between two dashes of the centre line.
const LANE_GAP: float = 20.0  # TUNING (not in GDD)
## px: width of a lane line and of a crosswalk stripe.
const LANE_LINE_W: float = 3.0  # TUNING (not in GDD)
## px: depth of a crosswalk (along the street, at each crossing's edge).
const CROSSWALK_DEPTH: float = 22.0  # TUNING (not in GDD)
## px: the spacing of the crosswalk's stripes.
const CROSSWALK_STEP: float = 10.0  # TUNING (not in GDD)
## px: a curb's lit edge on the street side of a sidewalk.
const CURB_W: float = 2.0  # TUNING (not in GDD)
## px: a rooftop parapet's width (the code glyph, and the edge tiles' expected size).
const PARAPET: float = 8.0  # TUNING (not in GDD)
