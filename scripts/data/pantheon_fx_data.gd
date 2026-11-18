## PantheonFxData: sprite keys and drawing numbers of the Olympian Republic's
## effect art (GDD §15.0 "Missing art round wired"; the art made by
## art_source/missing_art/make_missing_art.py, the wiring plan in
## docs/art/missing_art_round/WIRING.md): Divine Wrath's waves, bolts, chains
## and fissures, Stolen Thunder's orb and arcs, River Styx / Lethe's Flood.
## PantheonFx draws it; every drawing site keeps its code shape as the fallback
## when a PNG is missing. Alphas are baked into the PNGs (stepped), so most
## pieces draw at full white. Purely visual: nothing here touches gameplay
## state, timing, sizes or RNG. Data only, no logic.
class_name PantheonFxData
extends RefCounted

# --- The warning band (bolt circles, the wave's starting line) --------------------

## Warning band piece (10 x 6 art px, row 0 outside, the hit edge on row 3).
const EDGE: String = "pantheon_fx/edge"  # TUNING (not in GDD)
## The band piece with a tick pointing into the danger.
const EDGE_TICK: String = "pantheon_fx/edge_tick"  # TUNING (not in GDD)
## Every Nth band piece is the tick piece.
const TICK_EVERY: int = 2  # TUNING (not in GDD)
## Row of the band piece laid exactly on the hit edge (art px from its outer row).
const EDGE_ROW: float = 3.0  # TUNING (not in GDD)
## Modulate alpha of the band (0..1).
const EDGE_ALPHA: float = 0.9  # TUNING (not in GDD)

# --- Waves (Poseidon) ---------------------------------------------------------------

## Direction chevron (13 x 13; the art points -x, so it is turned half round
## past the wave's heading) of the wave telegraph.
const CHEVRON: String = "pantheon_fx/chevron"  # TUNING (not in GDD)
## Modulate alpha of a chevron (0..1).
const CHEVRON_ALPHA: float = 0.85  # TUNING (not in GDD)
## px between two chevrons along the wave's starting line (art and fallback alike).
const CHEVRON_STEP: float = 120.0  # TUNING (not in GDD)
## The wave front (24 x 16, tiles along x, the advancing edge at the bottom).
const WAVE_FRONT: String = "pantheon_fx/wave_front"  # TUNING (not in GDD)
## Row of the front laid on the wave's front line (its foam edge; art px from the top).
const WAVE_FRONT_ROW: float = 13.0  # TUNING (not in GDD)
## The water behind the front (32 x 32, seamless, scrolled with the wave).
const WAVE_BODY: String = "pantheon_fx/wave_body"  # TUNING (not in GDD)

# --- Lightning (Zeus) and the chains ------------------------------------------------

## Seamless danger fill (16 x 16) inside a bolt circle, laid as clipped rows.
const FILL: String = "pantheon_fx/fill"  # TUNING (not in GDD)
## Modulate alpha of the fill over the whole circle (0..1).
const FILL_BASE_ALPHA: float = 0.22  # TUNING (not in GDD)
## Modulate alpha of the fill again inside radius x timing (0..1).
const FILL_ALPHA: float = 0.5  # TUNING (not in GDD)
## Impact point (15 x 15) at the centre of a bolt circle.
const TARGET: String = "pantheon_fx/target"  # TUNING (not in GDD)
## Smallest circle radius (px) that shows the impact point.
const TARGET_MIN_RADIUS: float = 26.0  # TUNING (not in GDD)
## The bolt from the sky (16 x 96, its base on the bottom row).
const BOLT_COLUMN: String = "pantheon_fx/bolt_column"  # TUNING (not in GDD)
## Telegraph timing (0..1) from which the bolt column comes down.
const BOLT_COLUMN_FROM: float = 0.72  # TUNING (not in GDD)
## Thin lightning segment (20 x 9, seamless along x, the bolt on the middle row): ground chains.
const ARC_THIN: String = "pantheon_fx/arc_thin"  # TUNING (not in GDD)
## Thick lightning segment (20 x 13): bolts from the sky.
const ARC_THICK: String = "pantheon_fx/arc_thick"  # TUNING (not in GDD)
## Effect animation of a bolt landing (AnimData "wrath_strike", 8 frames of 96 px).
const STRIKE_ANIM: String = "wrath_strike"  # TUNING (not in GDD)
## Seconds a Divine Wrath chain flash takes to fade (its longest life, 0.25 s).
const FLASH_FADE: float = 0.25  # TUNING (not in GDD)

# --- Fissures (Hades) ---------------------------------------------------------------

## Fissure telegraph (12 x 6, tiles along x): a crimson crack with ember dashes.
const FISSURE_WARN: String = "pantheon_fx/fissure_warn"  # TUNING (not in GDD)
## Most the telegraph is enlarged (x art size) when the crack opens (1 -> this by its timing).
const FISSURE_WARN_GROW: float = 3.0  # TUNING (not in GDD)
## Open crack (16 x 22 tile, an 18 px opening on centre row 11).
const FISSURE_BODY: String = "pantheon_fx/fissure_body"  # TUNING (not in GDD)
## Crack end (10 x 22, the left cap; turned half round for the right end).
const FISSURE_CAP: String = "pantheon_fx/fissure_cap"  # TUNING (not in GDD)
## Opening (art px) of the crack art: a fissure `width` px wide draws it x width / this.
const FISSURE_OPENING: float = 18.0  # TUNING (not in GDD)

# --- Stolen Thunder ------------------------------------------------------------------

## Charge orb strip (4 frames of 16 x 16, by charge fraction).
const THUNDER_ORB: String = "pantheon_fx/thunder_orb"  # TUNING (not in GDD)
## Frames in THUNDER_ORB.
const THUNDER_ORB_FRAMES: int = 4  # TUNING (not in GDD)

# --- River Styx / Lethe's Flood -------------------------------------------------------

## River water (32 x 32, seamless), River Styx.
const STYX_WATER: String = "pantheon_fx/styx_water"  # TUNING (not in GDD)
## River water, Lethe's Flood (evolved).
const LETHE_WATER: String = "pantheon_fx/lethe_water"  # TUNING (not in GDD)
## River bank piece (16 x 4, row 0 outside), River Styx.
const STYX_BANK: String = "pantheon_fx/styx_bank"  # TUNING (not in GDD)
## River bank piece, Lethe's Flood.
const LETHE_BANK: String = "pantheon_fx/lethe_bank"  # TUNING (not in GDD)
## Row of the bank piece laid on the river's edge (2 px outside, 2 inside: the
## code banks' 2 px margin).
const BANK_ROW: float = 2.0  # TUNING (not in GDD)
## px/s the water's pattern drifts along the river (the code drift ticks' speed).
const RIVER_SCROLL: float = 30.0  # TUNING (not in GDD)
