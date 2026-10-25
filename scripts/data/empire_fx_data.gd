## EmpireFxData: sprite keys and drawing numbers of the Act III ground effects,
## beams and zones (GDD §15.0 "Act III AoE art", docs/art/ART_BIBLE.md "Act III
## AoE art"): the Empire's warning set (orbital strikes, guns, mortar landings,
## Deus's rings, the Motherboard's stamps, every shared Effect telegraph on an
## Act III stage), the Death Ray, the laser grid and the Judgment Lance, the
## Shield Gate walls, the furnace channels and conveyor belts, the scrap storm
## veil, the Juggernaut's flame, the Arc Engineer's static field, Deus's pulse,
## shocks, hangars and the finale's binding, the Motherboard's magnets and claws,
## the Lock-On reticles. The art is made on the grid by tools/empire_aoe_art.py;
## EmpireFx draws it (band pieces tiled at 1:1 along the exact hit edge, a hex
## fill laid as clipped rows, scrolled beam bodies, small stills) and every
## drawing site keeps its code shape as the fallback when a PNG is missing.
## Purely visual: nothing here touches gameplay state, timing, sizes or RNG.
## Data only, no logic.
class_name EmpireFxData
extends RefCounted

# --- The Empire's warning set ------------------------------------------------------

## Warning band piece (10 x 6 art px, row 0 outside): hazard-striped red and amber.
const EDGE: String = "empire_fx/edge"  # TUNING (not in GDD)
## The band piece with a cyan-white targeting tick pointing into the danger.
const EDGE_TICK: String = "empire_fx/edge_tick"  # TUNING (not in GDD)
## Every Nth band piece carries a tick.
const TICK_EVERY: int = 2  # TUNING (not in GDD)
## Row of the band piece laid exactly on the hit edge (art px from its outer row:
## the hazard stripes are rows 2-3, so the edge runs through their middle).
const EDGE_ROW: float = 3.0  # TUNING (not in GDD)
## Timing front (8 x 3): a cyan-white scan line.
const FRONT: String = "empire_fx/front"  # TUNING (not in GDD)
## Row of the front piece laid on the timing radius (its middle row).
const FRONT_ROW: float = 1.5  # TUNING (not in GDD)
## The Empire's fill: a seamless red hex grid (14 x 24), laid as clipped rows.
const HEX: String = "empire_fx/hex"  # TUNING (not in GDD)
## Double chevron (13 x 13, pointing +x): lane and sweep direction marks.
const CHEVRON: String = "empire_fx/chevron"  # TUNING (not in GDD)
## Impact point crosshair (15 x 15) at the centre of a warning circle.
const TARGET: String = "empire_fx/target"  # TUNING (not in GDD)
## Targeting box corner (9 x 9, the corner pixel at the top left).
const BRACKET: String = "empire_fx/bracket"  # TUNING (not in GDD)
## Orbital uplink column (16 x 96, base on the bottom row).
const UPLINK: String = "empire_fx/uplink"  # TUNING (not in GDD)
## Opacity (0-1) of the hex fill over the whole danger area.
const HEX_ALPHA: float = 0.22  # TUNING (not in GDD)
## Opacity (0-1) of the hex fill inside the part the timing has filled.
const FILL_ALPHA: float = 0.5  # TUNING (not in GDD)
## Opacity (0-1) of the soft warning-red base tint under the whole area.
const BASE_ALPHA: float = 0.07  # TUNING (not in GDD)
## Opacity (0-1) of the soft tint added under the filled part.
const FILL_TINT: float = 0.12  # TUNING (not in GDD)
## Opacity (0-1) of the band on the edge.
const EDGE_ALPHA: float = 0.95  # TUNING (not in GDD)
## Opacity (0-1) of the timing front.
const FRONT_ALPHA: float = 0.95  # TUNING (not in GDD)
## Opacity (0-1) of the impact crosshair.
const TARGET_ALPHA: float = 0.9  # TUNING (not in GDD)
## Smallest warning circle (px) that gets the crosshair.
const TARGET_MIN_RADIUS: float = 26.0  # TUNING (not in GDD)
## Smallest warning circle (px) that gets the targeting box brackets.
const BRACKET_MIN_RADIUS: float = 30.0  # TUNING (not in GDD)
## Where the brackets start, as a multiple of the area's half-size; they close
## to 1.0 (the bounding box) as the timing runs.
const BRACKET_FROM: float = 1.45  # TUNING (not in GDD)
## Opacity (0-1) of the brackets.
const BRACKET_ALPHA: float = 0.9  # TUNING (not in GDD)
## Gap (px) between two lane chevrons.
const CHEVRON_PITCH: float = 30.0  # TUNING (not in GDD)
## Opacity (0-1) of a chevron the timing has not reached / has passed.
const CHEVRON_ALPHA := Vector2(0.35, 0.95)  # TUNING (not in GDD)
## Uplink: the last fraction of an orbital strike's telegraph it shows in.
const UPLINK_FROM: float = 0.72  # TUNING (not in GDD)
## Uplink height (px above the strike centre) and its opacity at its brightest.
const UPLINK_HEIGHT: float = 420.0  # TUNING (not in GDD)
## Opacity (0-1) of the uplink column at the strike.
const UPLINK_ALPHA: float = 0.8  # TUNING (not in GDD)

# --- Impact strips (EffectManager.impact(..., anim); AnimData) ------------------------

## Amber strike / slam landing strip (effects/<id>).
const BLAST: String = "empire_blast"  # TUNING (not in GDD)
## Warning-red landing strip (overloads, heavy hits).
const BLAST_RED: String = "empire_blast_red"  # TUNING (not in GDD)
## Chrome / cyan-white landing strip (energy pops).
const BLAST_CHROME: String = "empire_blast_chrome"  # TUNING (not in GDD)
## An Empire stage boss falling (instead of the Covenant's holy boss_death on Act III stages).
const BOSS_DEATH: String = "empire_boss_death"  # TUNING (not in GDD)

# --- Beams -------------------------------------------------------------------------------

## Death Ray body (16 x 10 tile = its base width), glow (8 x 12) and tip burst (4 frames of 24 px).
const RAY_BODY: String = "empire_fx/ray_body"  # TUNING (not in GDD)
## Death Ray glow piece.
const RAY_GLOW: String = "empire_fx/ray_glow"  # TUNING (not in GDD)
## Death Ray tip burst strip.
const RAY_TIP: String = "empire_fx/ray_tip"  # TUNING (not in GDD)
## Frames in a tip burst strip, and its frame rate (frames/s).
const TIP_FRAMES: int = 4  # TUNING (not in GDD)
## Tip burst frame rate (frames/s).
const TIP_FPS: float = 14.0  # TUNING (not in GDD)
## Scroll speed (px/s) of the Death Ray's flow streaks (outward).
const RAY_SCROLL: float = 180.0  # TUNING (not in GDD)
## Glow width as a multiple of the beam width (the code's w + 4 glow line).
const RAY_GLOW_MULT: float = 2.0  # TUNING (not in GDD)
## Opacity (0-1) of the glow under the beam.
const RAY_GLOW_ALPHA: float = 0.55  # TUNING (not in GDD)
## Opacity (0-1) of the nearest afterglow copy (each later one loses AFTER_STEP).
const AFTER_ALPHA: float = 0.42  # TUNING (not in GDD)
## Opacity lost per afterglow copy (4 copies, as the code).
const AFTER_STEP: float = 0.09  # TUNING (not in GDD)
## Laser grid body (16 x 10 = its width), glow, sight dash and emitter caps.
const LASER_BODY: String = "empire_fx/laser_body"  # TUNING (not in GDD)
## Laser grid glow piece.
const LASER_GLOW: String = "empire_fx/laser_glow"  # TUNING (not in GDD)
## Telegraphed laser sight dash (8 x 3).
const LASER_WARN: String = "empire_fx/laser_warn"  # TUNING (not in GDD)
## Laser emitter caps (2 frames of 16 px: armed, firing).
const LASER_CAP: String = "empire_fx/laser_cap"  # TUNING (not in GDD)
## Radius (art px) of the emitter cap's housing (the code's 4-7 px end circles).
const LASER_CAP_R: float = 7.0  # TUNING (not in GDD)
## Laser glow width as a multiple of the beam width (the code's 2.6).
const LASER_GLOW_MULT: float = 2.6  # TUNING (not in GDD)
## Scroll speed (px/s) of the laser's flow streaks.
const LASER_SCROLL: float = 260.0  # TUNING (not in GDD)
## Opacity (0-1) of the hex fill over a laser's sweep band at its faintest /
## extra at full telegraph (the code's 0.06 + 0.08 x tele red film).
const BAND_ALPHA := Vector2(0.3, 0.35)  # TUNING (not in GDD)
## Gap (px) between two sweep chevrons along a laser's band.
const BAND_CHEVRON_PITCH: float = 120.0  # TUNING (not in GDD)
## Judgment Lance body (16 x 30 = its width), glow and head (4 frames of 32 px).
const LANCE_BODY: String = "empire_fx/lance_body"  # TUNING (not in GDD)
## Judgment Lance glow piece.
const LANCE_GLOW: String = "empire_fx/lance_glow"  # TUNING (not in GDD)
## Judgment Lance head strip.
const LANCE_TIP: String = "empire_fx/lance_tip"  # TUNING (not in GDD)
## Lance glow width as a multiple of its width (the code's 1.8).
const LANCE_GLOW_MULT: float = 1.8  # TUNING (not in GDD)

# --- Citadel: Shield Gates -------------------------------------------------------------

## Gate wall body (22 x 18 = the 18 px wall), glow (8 x 28), end post, cable.
const GATE_WALL: String = "empire_fx/gate_wall"  # TUNING (not in GDD)
## Gate wall outer glow piece (thickness + 10 px).
const GATE_GLOW: String = "empire_fx/gate_glow"  # TUNING (not in GDD)
## Gate end emitter (22 x 22).
const GATE_POST: String = "empire_fx/gate_post"  # TUNING (not in GDD)
## Generator cable piece (8 x 5).
const GATE_CABLE: String = "empire_fx/gate_cable"  # TUNING (not in GDD)
## Scroll speed (px/s) of the wall's lattice (the code's 30) and the cable's pulse.
const GATE_SCROLL: float = 30.0  # TUNING (not in GDD)
## Cable pulse scroll speed (px/s, toward the wall).
const CABLE_SCROLL: float = 40.0  # TUNING (not in GDD)

# --- Assembly: belts and furnace channels ----------------------------------------------

## Belt repeat tile by belt width (px): exact for the stage's three widths; any
## other width keeps the code drawing.
const BELTS: Dictionary = {68: "empire_fx/belt_68", 72: "empire_fx/belt_72", 80: "empire_fx/belt_80"}  # TUNING (not in GDD)
## Furnace slag (64 px seamless), the glowing seams over it, the 3 molten frames.
const FURNACE_SLAG: String = "empire_fx/furnace_slag"  # TUNING (not in GDD)
## Glowing seam overlay of a channel's slag.
const FURNACE_EMBERS: String = "empire_fx/furnace_embers"  # TUNING (not in GDD)
## Molten metal frames (seamless; they flicker every FURNACE_FLICKER s).
const FURNACE_MOLTEN: Array[String] = ["empire_fx/furnace_molten_0", "empire_fx/furnace_molten_1", "empire_fx/furnace_molten_2"]  # TUNING (not in GDD)
## Seconds per molten frame (the code's 0.1 s flame flicker, doubled: slower metal).
const FURNACE_FLICKER: float = 0.2  # TUNING (not in GDD)
## Flow speed (px/s) of the molten metal along a burning channel.
const FURNACE_FLOW: float = 16.0  # TUNING (not in GDD)
## Channel rim (12 x 3, the code's 3 px RAIL_W) and warning edge (10 x 2).
const FURNACE_RIM: String = "empire_fx/furnace_rim"  # TUNING (not in GDD)
## Warning stripes on a channel's edges before it flares.
const FURNACE_WARN: String = "empire_fx/furnace_warn"  # TUNING (not in GDD)
## Heat haze (8 x 6, row 0 at the rim) and flame tongues (4 frames of 9 x 14).
const FURNACE_HAZE: String = "empire_fx/furnace_haze"  # TUNING (not in GDD)
## Flame tongue strip licking up from a burning channel.
const FURNACE_FLAME: String = "empire_fx/furnace_flame"  # TUNING (not in GDD)
## Frames in the flame strip, and its frame rate (frames/s).
const FURNACE_FLAME_FRAMES: int = 4  # TUNING (not in GDD)
## Flame tongue frame rate (frames/s).
const FURNACE_FLAME_FPS: float = 10.0  # TUNING (not in GDD)
## Gap (px) between two flame tongues along a burning channel (Full effects;
## the lower visual tiers draw none).
const FURNACE_FLAME_PITCH: float = 44.0  # TUNING (not in GDD)

# --- Wastes: storm veil, pylon stump ---------------------------------------------------

## Storm veil grey mask (256 px) and its grit tile (128 px seamless).
const STORM_VEIL: String = "empire_fx/storm_veil"  # TUNING (not in GDD)
## Storm grit tile.
const STORM_GRIT: String = "empire_fx/storm_grit"  # TUNING (not in GDD)
## Radius of the veil's clear hole as a fraction of its half-size (the tool's
## 0.2393 = the stage's 230 px clear radius / the 961 px veil of a 1280 x 720 view).
const STORM_HOLE: float = 0.2393  # TUNING (not in GDD)
## Opacity (0-1) of the grit at full storm (the code's 0.35 streaks).
const STORM_GRIT_ALPHA: float = 0.42  # TUNING (not in GDD)
## Grit drift (px/s along the wind; the code's 260-420 px/s streaks).
const STORM_GRIT_SPEED := Vector2(320.0, 90.0)  # TUNING (not in GDD)
## A fallen pylon's toppled mast decal (30 x 14).
const PYLON_STUMP: String = "empire_fx/pylon_stump"  # TUNING (not in GDD)

# --- Kits -----------------------------------------------------------------------------

## Juggernaut flame billows by size (10 / 16 / 22 px, 4 frames each).
const JUG_FLAMES: Array[String] = ["empire_fx/jug_flame_0", "empire_fx/jug_flame_1", "empire_fx/jug_flame_2"]  # TUNING (not in GDD)
## Billows along the stream (the code's 7 circle pairs; fewer on lower tiers).
const JUG_BILLOWS: int = 9  # TUNING (not in GDD)
## Frames of a billow strip, and their frame rate (frames/s).
const JUG_FRAMES: int = 4  # TUNING (not in GDD)
## Billow frame rate (frames/s).
const JUG_FPS: float = 12.0  # TUNING (not in GDD)
## Arc Engineer field rim (10 x 5) and spark (2 frames of 7 px).
const STATIC_EDGE: String = "empire_fx/static_edge"  # TUNING (not in GDD)
## Static spark strip.
const SPARK: String = "empire_fx/spark"  # TUNING (not in GDD)
## Mortar shell in flight (2 frames of 10 px) and its spin rate (frames/s).
const MORTAR_SHELL: String = "empire_fx/mortar_shell"  # TUNING (not in GDD)
## Mortar shell spin (frames/s).
const MORTAR_SPIN: float = 10.0  # TUNING (not in GDD)
## Lock-On reticles (2 frames: red, white-hot): painting (ring r 12) and locked (r 9).
const LOCK_OPEN: String = "empire_fx/lock_open"  # TUNING (not in GDD)
## Locked reticle strip.
const LOCK_LOCKED: String = "empire_fx/lock_locked"  # TUNING (not in GDD)
## Ring radius (art px) of LOCK_OPEN (it is scaled by the code's radius / this).
const LOCK_OPEN_R: float = 12.0  # TUNING (not in GDD)

# --- Deus Ex Machina, the Motherboard ----------------------------------------------------

## Footfall shock ring piece (10 x 4), overload pulse front (12 x 26), charge ring (8 x 3).
const SHOCK_EDGE: String = "empire_fx/shock_edge"  # TUNING (not in GDD)
## Overload pulse front piece (row 13 on the front's radius).
const PULSE_FRONT: String = "empire_fx/pulse_front"  # TUNING (not in GDD)
## Row of the pulse front piece laid on the front's radius (its middle row).
const PULSE_FRONT_ROW: float = 13.0  # TUNING (not in GDD)
## Overload charge ring piece.
const PULSE_CHARGE: String = "empire_fx/pulse_charge"  # TUNING (not in GDD)
## The finale's soul binding chain piece (10 x 5).
const BINDING_EDGE: String = "empire_fx/binding_edge"  # TUNING (not in GDD)
## Hangar door (3 frames of 36 x 24: shut, opening, open).
const HANGAR_DOOR: String = "empire_fx/hangar_door"  # TUNING (not in GDD)
## Motherboard magnet ring piece (10 x 3) and crane claw (2 frames of 16 px).
const MAGNET_EDGE: String = "empire_fx/magnet_edge"  # TUNING (not in GDD)
## Crane claw strip (open, clamped; the cable joins its top row's centre).
const CLAW: String = "empire_fx/claw"  # TUNING (not in GDD)
