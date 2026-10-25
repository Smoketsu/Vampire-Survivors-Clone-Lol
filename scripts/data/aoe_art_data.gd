## AoeArtData: the pixel-art pieces of the necromancer side's ground effects
## (GDD §15.0 "Player AoE art"; docs/art/ART_BIBLE.md "Player AoE art"). The
## spells' clouds and auras, the summon specials' telegraphs and impacts, the
## fire and shard patches, the Rogue's lane, the summon evolution column and the
## ultimates' overlays used to be flat code discs, rings and polygons; they are
## now built by AoeArt from small pieces drawn 1:1 on the art grid (made by
## tools/aoe_art.py), so the drawn area matches the real hit radius at any size.
## Each piece is res://assets/sprites/aoe/<id>.png; without it the code drawing
## stays (AoeArt's functions return false). Purely visual: none of these numbers
## touches gameplay, timing, sizes or RNG. Data only, no logic.
class_name AoeArtData
extends RefCounted

## Folder of the piece PNGs (one file per piece id).
const ROOT: String = "res://assets/sprites/aoe/"  # TUNING (not in GDD)

## Piece-count multiplier by visual tier (AdaptiveQuality.tier(): 0 Full, 1
## Reduced, 2 Light, 3 Minimal): rings space their pieces wider and clouds
## scatter fewer puffs on the lower tiers (drawing only).
const TIER_DENSITY: Array[float] = [1.0, 0.6, 0.45, 0.3]  # TUNING (not in GDD) mobile
## Fewest pieces a ring ever has (small radii, low tiers).
const MIN_RING_PIECES: int = 6  # TUNING (not in GDD)

# --- Burst rings (EffectManager.art_ring(); Effect._draw() -> AoeArt.burst()) ------------

## Frames in every burst crest strip (fresh -> broken up).
const CREST_FRAMES: int = 4  # TUNING (not in GDD) tools/aoe_art.py CREST_FRAMES
## Burst recipe id -> how its pieces play over the effect's own lifetime k (0..1):
##   crest: ring piece strip (CREST_FRAMES frames, +x outward), rolled from
##          `from` x the radius out to the radius (ease-out), one piece per
##          `step` px of the final rim (scaled by TIER_DENSITY);
##   alpha: opacity of the pieces (0-1), fading over the last `fade` of k;
##   fill:  peak opacity (0-1) of the soft disc under it, in the effect's colour
##          (the shared disc texture: batched, no polygon), fading with k;
##   fill_color (optional): the disc's colour instead of the effect's;
##   centre / centre_frames / centre_alpha: optional centre piece ("crack" picks
##          the largest CRACKS size that fits the radius), its frame by k;
##   under: drawn under the bodies (z -5, like a telegraph) instead of over them.
const BURSTS: Dictionary = {
	"stomp": {"crest": "crest_stomp", "from": 0.3, "step": 14.0, "alpha": 0.95, "fade": 0.35, "fill": 0.12, "centre": "crack", "centre_frames": 1, "centre_alpha": 0.85, "under": true},  # TUNING (not in GDD) Abomination / Bone Colossus stomp
	"shrapnel": {"crest": "crest_bone", "from": 0.3, "step": 14.0, "alpha": 0.95, "fade": 0.35, "fill": 0.1, "centre": "crack", "centre_frames": 1, "centre_alpha": 0.7, "under": true},  # TUNING (not in GDD) Bone Colossus death shrapnel
	"boulder": {"crest": "crest_bone", "from": 0.3, "step": 13.0, "alpha": 0.9, "fade": 0.35, "fill": 0.1, "centre": "crack", "centre_frames": 1, "centre_alpha": 0.75, "under": true},  # TUNING (not in GDD) Corpse Catapult / Ossuary Engine boulder landing
	"freeze": {"crest": "crest_frost", "from": 0.3, "step": 11.0, "alpha": 0.95, "fade": 0.3, "fill": 0.14, "centre": "frost_star", "centre_frames": 3, "centre_alpha": 0.9, "under": true},  # TUNING (not in GDD) Frost Wraith Deep Freeze
	"dive": {"crest": "crest_stone", "from": 0.3, "step": 14.0, "alpha": 0.95, "fade": 0.35, "fill": 0.1, "centre": "flash_violet", "centre_frames": 3, "centre_alpha": 0.8, "under": true},  # TUNING (not in GDD) Gargoyle / Cathedral Horror dive impact
	"stun": {"crest": "crest_ivory", "from": 0.4, "step": 14.0, "alpha": 0.85, "fade": 0.4, "fill": 0.0, "centre": "", "centre_frames": 1, "centre_alpha": 0.0, "under": false},  # TUNING (not in GDD) Cathedral Horror stun shock
	"wail": {"crest": "crest_wail", "from": 0.25, "step": 14.0, "alpha": 0.9, "fade": 0.4, "fill": 0.1, "centre": "flash_wail", "centre_frames": 3, "centre_alpha": 0.45, "under": false},  # TUNING (not in GDD) Banshee / Keening Lady Dirge wave
	"silence": {"crest": "crest_wail_violet", "from": 0.3, "step": 14.0, "alpha": 0.85, "fade": 0.4, "fill": 0.0, "centre": "", "centre_frames": 1, "centre_alpha": 0.0, "under": false},  # TUNING (not in GDD) Keening Lady silence ring
	"splash": {"crest": "crest_arcane", "from": 0.3, "step": 11.0, "alpha": 0.95, "fade": 0.35, "fill": 0.12, "centre": "flash_arcane", "centre_frames": 3, "centre_alpha": 0.85, "under": false, "fill_color": Color(0.31, 0.47, 0.92)},  # TUNING (not in GDD) Mage / Lich orb splash
	"spore_nova": {"crest": "crest_spore", "from": 0.3, "step": 13.0, "alpha": 0.9, "fade": 0.35, "fill": 0.1, "centre": "", "centre_frames": 1, "centre_alpha": 0.0, "under": false},  # TUNING (not in GDD) Pestilence death nova
	"violet_ring": {"crest": "crest_violet", "from": 0.3, "step": 12.0, "alpha": 0.9, "fade": 0.4, "fill": 0.08, "centre": "", "centre_frames": 1, "centre_alpha": 0.0, "under": false},  # TUNING (not in GDD) violet soul-fire ring (Pestilence nova core, evolutions, Echoing Dark)
	"soul_ring": {"crest": "crest_soul", "from": 0.3, "step": 12.0, "alpha": 0.9, "fade": 0.4, "fill": 0.08, "centre": "", "centre_frames": 1, "centre_alpha": 0.0, "under": false},  # TUNING (not in GDD) soul-teal ring (summon transforms, evolutions, heal pulses, Bastion)
}
## Ground-crack centre piece ids by size, smallest first, and their diameters (art px).
const CRACKS: Array[String] = ["crack_0", "crack_1", "crack_2"]  # TUNING (not in GDD) tools/aoe_art.py CRACK_SIZES
## Diameters (art px) of CRACKS, same order.
const CRACK_SIZES: Array[float] = [32.0, 48.0, 64.0]  # TUNING (not in GDD)
## Glowing (soul) crack ids by size, same sizes (Grave Eruption field).
const SOUL_CRACKS: Array[String] = ["crack_soul_0", "crack_soul_1", "crack_soul_2"]  # TUNING (not in GDD)
## A centre crack is the largest that fits this fraction of the burst's diameter.
const CRACK_FIT: float = 0.95  # TUNING (not in GDD)

# --- Telegraphs (summon wind-ups, boulder landings; AoeArt.telegraph()) ------------------

## Frames of a telegraph rim-mark strip (0 plain, 1 lit for the last moment).
const MARK_FRAMES: int = 2  # TUNING (not in GDD)
## Rim px between two telegraph marks.
const MARK_STEP: float = 12.0  # TUNING (not in GDD)
## Opacity (0-1) of the rim marks.
const MARK_ALPHA: float = 0.95  # TUNING (not in GDD)
## Opacity (0-1) of the whole-area disc under a telegraph (the code's 0.10).
const TELEGRAPH_FILL: float = 0.045  # TUNING (not in GDD)
## Opacity (0-1) the area disc gains over the wind-up, doubled (it reaches
## TELEGRAPH_FILL + half of this at the strike; the code grew a 0.22 disc).
const TELEGRAPH_GROW: float = 0.07  # TUNING (not in GDD)

# --- Plague Cloud / Pestilence (AoeArt.cloud()) ------------------------------------------

## Cloud puff ids by size (small, medium, large): Plague Cloud.
const PLAGUE_PUFFS: Array[String] = ["puff_plague_0", "puff_plague_1", "puff_plague_2"]  # TUNING (not in GDD)
## Cloud puff ids by size: Pestilence.
const PEST_PUFFS: Array[String] = ["puff_pest_0", "puff_pest_1", "puff_pest_2"]  # TUNING (not in GDD)
## Puff diameters (art px), same order (tools/aoe_art.py PUFF_SIZES + 2 px border).
const PUFF_SIZES: Array[float] = [20.0, 28.0, 36.0]  # TUNING (not in GDD)
## Rim px between two rim puffs (their outer edge sits on the cloud radius).
const PUFF_RIM_STEP: float = 16.0  # TUNING (not in GDD)
## Cloud area (px^2) per inner puff.
const PUFF_INNER_AREA: float = 300.0  # TUNING (not in GDD) ~ one inner puff per 17 x 17 px
## Opacity (0-1) of the Plague Cloud puffs at full strength.
const PLAGUE_ALPHA: float = 0.42  # TUNING (not in GDD)
## Opacity (0-1) of the Pestilence puffs at full strength.
const PEST_ALPHA: float = 0.55  # TUNING (not in GDD)
## Opacity (0-1) of the Plague Cloud's soft disc (the code's 0.08).
const PLAGUE_FILL: float = 0.07  # TUNING (not in GDD)
## Opacity (0-1) of the Pestilence cloud's dark disc (the code's 0.42).
const PEST_FILL: float = 0.3  # TUNING (not in GDD)
## Turning speed (rad/s) of the inner puffs (the rim turns at a third of it).
const PUFF_SPIN: float = 0.22  # TUNING (not in GDD)
## Bob (px) of each puff, and its speed (rad/s).
const PUFF_BOB: float = 1.5  # TUNING (not in GDD)
## Bob speed (rad/s).
const PUFF_BOB_SPEED: float = 1.6  # TUNING (not in GDD)
## Rising bubble strip (3 frames: small, big, pop) and the soul / plague / violet mote strips.
const BUBBLE: String = "bubble_plague"  # TUNING (not in GDD)
## Soul mote strip (3 frames: glow, bright, shrunk).
const MOTE_SOUL: String = "mote_soul"  # TUNING (not in GDD)
## Plague mote strip (Wither's drooping motes).
const MOTE_PLAGUE: String = "mote_plague"  # TUNING (not in GDD)
## Frames of the bubble and mote strips.
const MOTE_FRAMES: int = 3  # TUNING (not in GDD)
## Pestilence charge rim: crest strip (frame 0) repeated on the rim, px between two pieces.
const PEST_CHARGE_CREST: String = "crest_violet"  # TUNING (not in GDD)
## Rim px between two charge-rim pieces.
const PEST_CHARGE_STEP: float = 12.0  # TUNING (not in GDD)

# --- Wither / Necrotic Blight aura (AoeArt.wither()) -------------------------------------

## Rune-rim strip of the Wither aura (2 frames = 2 variants, alternated).
const WITHER_RUNE: String = "rune_plague"  # TUNING (not in GDD)
## Rune-rim strip of the Necrotic Blight aura.
const BLIGHT_RUNE: String = "rune_soul"  # TUNING (not in GDD)
## Rim px between two rune pieces.
const RUNE_STEP: float = 15.0  # TUNING (not in GDD)
## Opacity (0-1) of the rune rim at rest, and what a pulse flash adds.
const RUNE_ALPHA: float = 0.5  # TUNING (not in GDD)
## Opacity a pulse flash adds to the rune rim (0-1).
const RUNE_FLASH_ALPHA: float = 0.4  # TUNING (not in GDD)
## Opacity a crowd inside the aura adds to the rune rim (0-1; the code thickened it).
const RUNE_BUSY_ALPHA: float = 0.1  # TUNING (not in GDD)

# --- Grave Eruption spike field, fire patches, shard fields ------------------------------

## Bone spike sprite ids (two variants; base on the bottom row).
const SPIKES: Array[String] = ["spike_0", "spike_1"]  # TUNING (not in GDD)
## Rim px between two outer spikes of a Grave Eruption field (at SPIKE_RING x radius).
const SPIKE_STEP: float = 22.0  # TUNING (not in GDD)
## Outer spike ring radius, as a fraction of the field radius (the code's 0.75).
const SPIKE_RING: float = 0.78  # TUNING (not in GDD)
## Inner spike ring radius fraction (the code's 0.35) and its spike count.
const SPIKE_INNER: float = 0.38  # TUNING (not in GDD)
## Opacity (0-1) of the Grave Eruption spikes (several fields overlap late in a run).
const SPIKE_ALPHA: float = 0.8  # TUNING (not in GDD)
## Spikes on the inner ring.
const SPIKE_INNER_COUNT: int = 6  # TUNING (not in GDD)
## Rim mark strip of the eruption field (soul dial marks on its edge).
const FIELD_MARK: String = "mark_soul"  # TUNING (not in GDD)
## Flame tongue loop ids (3 variants, FLAME_FRAMES frames each).
const FLAMES: Array[String] = ["flame_0", "flame_1", "flame_2"]  # TUNING (not in GDD)
## Frames in a flame loop.
const FLAME_FRAMES: int = 4  # TUNING (not in GDD)
## Flame loop frames per second of patch life (the loop runs with the patch's age).
const FLAME_FPS: float = 9.0  # TUNING (not in GDD)
## Scorch mark ids: under a Hellhound fire patch, under an Ossuary shard field.
const SCORCH_SMALL: String = "scorch_0"  # TUNING (not in GDD)
## Scorch mark under an Ossuary Engine shard field.
const SCORCH_LARGE: String = "scorch_1"  # TUNING (not in GDD)
## Diameters (art px) of SCORCH_SMALL and SCORCH_LARGE (scaled to the patch radius).
const SCORCH_SIZES: Array[float] = [28.0, 60.0]  # TUNING (not in GDD)
## Opacity (0-1) of a scorch mark at full life.
const SCORCH_ALPHA: float = 0.8  # TUNING (not in GDD)

# --- Rogue dash lane (AoeArt.lane()) -----------------------------------------------------

## Lane body tile strip (frame 0 faint lane, frame 1 charged) and the head cap.
const LANE_BODY: String = "lane_body"  # TUNING (not in GDD)
## The lane's arrowhead cap.
const LANE_HEAD: String = "lane_head"  # TUNING (not in GDD)
## Tile length (art px) along the lane and the lane width the art is drawn for (px).
const LANE_TILE: float = 8.0  # TUNING (not in GDD)
## Lane width the tiles are drawn for (px; UnitData dash_width); other widths stretch across.
const LANE_ART_WIDTH: float = 24.0  # TUNING (not in GDD)
## Opacity (0-1) of the lane tiles.
const LANE_ALPHA: float = 0.8  # TUNING (not in GDD)
## The dash streak sprite (points +x), drawn behind the dashing Rogue.
const STREAK: String = "dash_streak"  # TUNING (not in GDD)

# --- Summon evolution column (AoeArt.transform_glow()) -----------------------------------

## The light column strip (COLUMN_FRAMES frames), its base on the frame's bottom row.
const COLUMN: String = "transform_column"  # TUNING (not in GDD)
## Frames in the light column strip.
const COLUMN_FRAMES: int = 4  # TUNING (not in GDD)
## Opacity (0-1) of the column at its brightest.
const COLUMN_ALPHA: float = 0.6  # TUNING (not in GDD)
## How far (px) below the unit's centre the column's base sits, per px of body radius.
const COLUMN_FOOT: float = 0.9  # TUNING (not in GDD)

# --- Ultimates (UltimateOverlay) ---------------------------------------------------------

## Sovereign's Decree taunt halo ids by size, smallest first, and their diameters (art px).
const HALOS: Array[String] = ["halo_0", "halo_1", "halo_2"]  # TUNING (not in GDD)
## Diameters (art px) of HALOS.
const HALO_SIZES: Array[float] = [30.0, 42.0, 58.0]  # TUNING (not in GDD)
## Eclipse: the black sun sprite above the necromancer.
const BLACK_SUN: String = "black_sun"  # TUNING (not in GDD)
## Grave Tide: the edge-mist tile strip (2 frames) laid along the view's edges.
const TIDE_EDGE: String = "tide_edge"  # TUNING (not in GDD)
## Grave Tide tile size (art px): along the edge x depth into the view.
const TIDE_TILE: Vector2 = Vector2(24.0, 40.0)  # TUNING (not in GDD)
## Grave Tide: opacity (0-1) of the edge-mist tiles at full strength.
const TIDE_ALPHA: float = 0.5  # TUNING (not in GDD)
## Grave Tide mist frames per second (the tiles roll between their two frames).
const TIDE_FPS: float = 3.0  # TUNING (not in GDD)

# --- Soul Chains, Eclipse Ward, chill film, Dirge mark -----------------------------------

## Soul Chains bolt segment strip (2 frames), stretched along each hop of the arc.
const BOLT: String = "bolt_violet"  # TUNING (not in GDD)
## Chains of the Damned's wide soul-green under-glow segment strip.
const BOLT_GLOW: String = "bolt_soul_glow"  # TUNING (not in GDD)
## Eclipse Ward band piece strip (2 rune variants), repeated along the orbit.
const ECLIPSE_BAND: String = "eclipse_band"  # TUNING (not in GDD)
## How far (px) the band's outer edge sits outside the orbit radius (the code's 9 px band, centred).
const ECLIPSE_BAND_OUT: float = 5.0  # TUNING (not in GDD)
## Orbit px between two band pieces (the 14 px pieces overlap a little).
const ECLIPSE_BAND_STEP: float = 12.0  # TUNING (not in GDD)
## Opacity (0-1) of the band.
const ECLIPSE_BAND_ALPHA: float = 0.8  # TUNING (not in GDD)
## Chill film sprite (ice crust for a body of OVERLAY_RADIUS, scaled to others).
const CHILL: String = "chill_film"  # TUNING (not in GDD)
## Dirge veil strip (frame 0 plain, frame 1 silenced), drawn for a body of OVERLAY_RADIUS.
const DIRGE: String = "dirge_veil"  # TUNING (not in GDD)
## Body radius (px) the chill film and the Dirge veil are drawn for (tools/aoe_art.py OVERLAY_R).
const OVERLAY_RADIUS: float = 12.0  # TUNING (not in GDD)
## Row (art px from the top) of the body centre in the Dirge veil frame (tools/aoe_art.py VEIL_CY).
const DIRGE_CENTRE_Y: float = 26.0  # TUNING (not in GDD)
