## CovenantFxData: sprite keys and drawing numbers of the Act I enemy-side
## area-effect art (GDD §15.0 "Act I enemy AoE art", docs/art/ART_BIBLE.md
## "Act I enemy AoE art"): the shared boss / elite telegraphs (every act), the
## holy zones, sanctified and cleansed chambers, suppression seals, altar
## sigils, Seraphine's hazards, the Cathedral Guardian's beam and fists, the
## High Confessor's pillar and shield, Alaric's Wrath halo, the aura rings,
## the zone-change smoke and the Graveyard fog. The art is made on the grid by
## tools/covenant_aoe_art.py; CovenantFx draws it (tiles repeated along a shape
## at 1:1, discs baked at the radii the game uses, small stills) and every
## drawing site keeps its code shape as the fallback when a PNG is missing.
## The old rule "rings, telegraphs, zones and glows stay in code" (ART_BIBLE
## "Placeholder art batch") is retired for these effects.
## Purely visual: nothing here touches gameplay state, timing, sizes or RNG.
## Data only, no logic.
class_name CovenantFxData
extends RefCounted

# --- Shared telegraphs (Effect.Kind.TELEGRAPH_CIRCLE / LINE / CONE) ----------------

## Warning band piece (10 x 6 art px, row 0 outside), tiled along every edge.
const T_EDGE: String = "telegraphs/edge"  # TUNING (not in GDD)
## The band piece with a crimson tooth pointing into the danger.
const T_EDGE_TOOTH: String = "telegraphs/edge_tooth"  # TUNING (not in GDD)
## Every Nth band piece carries a tooth (1 = all, 2 = every other one).
const T_TOOTH_EVERY: int = 2  # TUNING (not in GDD)
## Row of the band piece laid exactly on the danger edge (art px from its outer
## row: rows 1-4 are the gold band, so the hit edge runs through its middle).
const T_EDGE_ROW: float = 3.0  # TUNING (not in GDD)
## Timing front (8 x 3): tiled at radius x progress, or across a lane.
const T_FRONT: String = "telegraphs/front"  # TUNING (not in GDD)
## Warning hatch (8 x 8 seamless tile), laid row by row inside the danger shape.
const T_HATCH: String = "telegraphs/hatch"  # TUNING (not in GDD)
## Direction chevron (11 x 13, pointing +x) along a charge lane.
const T_CHEVRON: String = "telegraphs/chevron"  # TUNING (not in GDD)
## Impact point mark (13 x 13) at the centre of a warning circle.
const T_TARGET: String = "telegraphs/target"  # TUNING (not in GDD)
## Height (px) of one hatch row: the fill is laid as horizontal strips this
## tall clipped to the shape, so its edge follows a circle or cone to 2 px.
const T_HATCH_ROW: float = 2.0  # TUNING (not in GDD)
## Opacity (0-1) of the hatch over the whole danger area (the code drew a 12% fill).
const T_HATCH_ALPHA: float = 0.24  # TUNING (not in GDD)
## Opacity (0-1) of the hatch inside the part the timing has filled (the
## code's growing 28% fill), laid over the first.
const T_FILL_ALPHA: float = 0.55  # TUNING (not in GDD)
## Opacity (0-1) of the soft tint under the filled part (circle and lane), in
## the telegraph colour, on top of T_BASE_ALPHA.
const T_FILL_TINT: float = 0.12  # TUNING (not in GDD)
## Opacity (0-1) of the soft base tint under the hatch (shared disc texture /
## plain rects, in the telegraph colour).
const T_BASE_ALPHA: float = 0.08  # TUNING (not in GDD)
## Opacity (0-1) of the band along the edge (the code outline was 0.85).
const T_EDGE_ALPHA: float = 0.95  # TUNING (not in GDD)
## Opacity (0-1) of the timing front.
const T_FRONT_ALPHA: float = 0.9  # TUNING (not in GDD)
## Gap (px) between two direction chevrons along a lane.
const T_CHEVRON_PITCH: float = 30.0  # TUNING (not in GDD)
## Opacity (0-1) of a chevron the timing has not reached yet / has passed.
const T_CHEVRON_ALPHA := Vector2(0.35, 0.95)  # TUNING (not in GDD)
## Opacity (0-1) of the impact point mark.
const T_TARGET_ALPHA: float = 0.85  # TUNING (not in GDD)
## Smallest warning circle (px) that gets the impact point mark.
const T_TARGET_MIN_RADIUS: float = 30.0  # TUNING (not in GDD)

## CovenantFx's soft white disc mask (512 px, a 3 px soft rim): every
## translucent fill of this art, smooth up to the 640 px nova.
const SOFT_DISC: String = "holy/soft_disc"  # TUNING (not in GDD)
## Radius (px) below which a fill uses the 64 px shared disc instead.
const SOFT_DISC_MIN_R: float = 64.0  # TUNING (not in GDD)

# --- Sanctified ground (holy zones, chambers, seals, altars) -----------------------

## Holy zone discs by baked radius (px): StageDirector draws the one nearest
## its zone's radius, scaled to it (exact at 62 / 85 / 105).
const ZONE_DISCS: Dictionary = {62: "holy/zone_62", 85: "holy/zone_85", 105: "holy/zone_105"}  # TUNING (not in GDD)
## Opacity (0-1) of an armed holy zone's sigil (times its fade-out).
const ZONE_ALPHA: float = 0.85  # TUNING (not in GDD)
## Glints running round an armed holy zone's rune ribbon.
const ZONE_GLINTS: int = 8  # TUNING (not in GDD)
## Their orbit: px inside the zone's radius (the middle of the ribbon).
const ZONE_GLINT_INSET: float = 5.5  # TUNING (not in GDD)
## Four-point star glint (7 x 7).
const GLINT: String = "holy/glint"  # TUNING (not in GDD)
## Sanctified chamber floor circles by baked radius (px).
const CHAMBER_DISCS: Dictionary = {220: "holy/chamber_220"}  # TUNING (not in GDD)
## Cleansed chamber stains by baked radius (px).
const CLEANSED_DISCS: Dictionary = {220: "holy/cleansed_220"}  # TUNING (not in GDD)
## Opacity (0-1) of the chamber's floor circle.
const CHAMBER_ALPHA: float = 0.8  # TUNING (not in GDD)
## Rune turning round a chamber (9 x 9), on the code's 12 squares' orbit.
const RUNE: String = "holy/rune"  # TUNING (not in GDD)
## Their orbit: px inside the chamber's radius (the code's squares sat at 18).
const CHAMBER_RUNE_INSET: float = 19.0  # TUNING (not in GDD)
## Thin light ray piece (8 x 5), scrolled along a ward crystal's beam.
const LIGHT_BEAM: String = "holy/light_beam"  # TUNING (not in GDD)
## Scroll speed (px/s) of the light-ray pieces (toward the chamber's centre).
const LIGHT_BEAM_SCROLL: float = 24.0  # TUNING (not in GDD)
## Suppression seals by baked radius (px).
const SEAL_DISCS: Dictionary = {160: "holy/seal_160", 220: "holy/seal_220"}  # TUNING (not in GDD)
## Cross turning round a suppression seal (7 x 9).
const SEAL_CROSS: String = "holy/seal_cross"  # TUNING (not in GDD)
## Their orbit: px inside the seal's radius (between its ribbon and its dashed ring).
const SEAL_CROSS_INSET: float = 20.0  # TUNING (not in GDD)
## Altar sigils by baked radius (px; 2.4 x the altar's 20 px body).
const ALTAR_DISCS: Dictionary = {48: "holy/altar_48"}  # TUNING (not in GDD)
## Short gold ray (10 x 4, pointing +x): altar and Judgment rays, sun ticks.
const RAY: String = "holy/ray"  # TUNING (not in GDD)

# --- Marks and auras -------------------------------------------------------------

## Crimson ring piece (8 x 3): a Call to Arms ring, a Sister's zeal ring.
const RALLY_EDGE: String = "holy/rally_edge"  # TUNING (not in GDD)
## Faint aura dash piece (12 x 2: a 6 px dash and its gap), tiled along an aura ring.
const AURA_DASH: String = "holy/aura_dash"  # TUNING (not in GDD)
## Opacity (0-1) of an aura ring's dashes (Banner Bearer / Holy Standard, Paladin).
const AURA_ALPHA: float = 0.42  # TUNING (not in GDD)

# --- Covenant casters and the Cathedral Guardian -----------------------------------

## Casting sunburst (18 x 18).
const SUNBURST: String = "holy/sunburst"  # TUNING (not in GDD)
## A raised stone fist of the Guardian (16 x 15).
const GUARDIAN_FIST: String = "holy/guardian_fist"  # TUNING (not in GDD)
## Great beam body piece (16 x 24), scrolled along the beam.
const BEAM_CORE: String = "holy/beam_core"  # TUNING (not in GDD)
## Soft glow piece (8 x 16) stretched to twice a great beam's width under it.
const BEAM_GLOW: String = "holy/beam_glow"  # TUNING (not in GDD)
## Great beam head (32 x 32).
const BEAM_CAP: String = "holy/beam_cap"  # TUNING (not in GDD)
## Scroll speed (px/s) of the great beams' flow streaks (outward).
const BEAM_SCROLL: float = 140.0  # TUNING (not in GDD)
## Opacity (0-1) of the glow under a great beam (times its flicker).
const BEAM_GLOW_ALPHA: float = 0.9  # TUNING (not in GDD)
## Light column (24 x 64, base on the bottom row): revival pillar, teleport landing.
const LIGHT_COLUMN: String = "holy/light_column"  # TUNING (not in GDD)
## High Confessor's holy shield bubble (40 x 40; ring radius 18 art px).
const HOLY_SHIELD: String = "overlays/holy_shield"  # TUNING (not in GDD)
## Ring radius (art px) of the shield bubble art: scaled so it sits on r x 1.35.
const HOLY_SHIELD_RING: float = 18.0  # TUNING (not in GDD)
## Sister of the Scourge's lash cord piece (6 x 4).
const LASH: String = "holy/lash"  # TUNING (not in GDD)
## Sir Alaric's Wrath halo by its flame ring's baked radius (px): 1.6 x his
## 22 px body; drawn scaled to 1.6 x his radius.
const WRATH_DISCS: Dictionary = {35: "holy/wrath_halo"}  # TUNING (not in GDD)

# --- Seraphine's hazards ------------------------------------------------------------

## Pulse ring dash (12 x 3) of the charging Judgment nova.
const NOVA_WAVE: String = "holy/nova_wave"  # TUNING (not in GDD)
## Safe circle ground discs and their bright rims, by baked radius (px).
const SAFE_DISCS: Dictionary = {62: "holy/safe_62"}  # TUNING (not in GDD)
const SAFE_RIMS: Dictionary = {62: "holy/safe_rim_62"}  # TUNING (not in GDD)
## Safe circle countdown piece (6 x 4).
const SAFE_TICK: String = "holy/safe_tick"  # TUNING (not in GDD)
## Dashed warning piece (8 x 3) of a beam that has not ignited yet.
const WARN_LINE: String = "holy/warn_line"  # TUNING (not in GDD)
## Collapsing arena edge piece (12 x 6, row 0 in the fire).
const COLLAPSE_EDGE: String = "holy/collapse_edge"  # TUNING (not in GDD)
## Flame tongue strip (6 frames of 12 x 30, base on the bottom row).
const COLLAPSE_FLAME: String = "holy/collapse_flame"  # TUNING (not in GDD)
## Frames in the flame tongue strip, and its frame rate (frames/s).
const COLLAPSE_FLAME_FRAMES: int = 6  # TUNING (not in GDD)
const COLLAPSE_FLAME_FPS: float = 10.0  # TUNING (not in GDD)
## Gap (px) between two flame tongues along the collapse edge.
const COLLAPSE_FLAME_PITCH: float = 13.0  # TUNING (not in GDD)
## Burning ground beyond the collapse edge (512 px square, a hole of
## COLLAPSE_SCORCH_HOLE px radius scaled to the arena).
const COLLAPSE_SCORCH: String = "holy/collapse_scorch"  # TUNING (not in GDD)
const COLLAPSE_SCORCH_HOLE: float = 128.0  # TUNING (not in GDD)
## Colour of the burn beyond the scorch texture (its outer step: crimson, 25%).
const COLLAPSE_FAR := Color(0.78, 0.10, 0.16, 0.25)  # TUNING (not in GDD)
## Tongues of the Last Light flame ring round Seraphine.
const LAST_LIGHT_TONGUES: int = 14  # TUNING (not in GDD)

# --- Zone change, Dawn's Wrath, Graveyard fog --------------------------------------

## Smoke bank grey masks of the zone-change sweep (tinted with the bank colour,
## drawn 1:1: 120-176 px wide, the code drew 180 px discs).
const SMOKE_BANKS: Array[String] = ["holy/smoke_bank", "holy/smoke_bank_2", "holy/smoke_bank_3"]  # TUNING (not in GDD)
## One shaft of Dawn's Wrath (64 x 240, root at the bottom).
const DAWN_SHAFT: String = "holy/dawn_shaft"  # TUNING (not in GDD)
## Opacity (0-1) of a dawn shaft.
const DAWN_SHAFT_ALPHA: float = 0.9  # TUNING (not in GDD)
