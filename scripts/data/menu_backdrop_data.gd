## MenuBackdropData: every number of the main-menu diorama (MenuBackdrop,
## scripts/ui/menu_backdrop.gd; GDD §15.0 "Menu diorama"; art in
## assets/sprites/menu/, built by art_source/menu/make_menu_art.py, see
## docs/art/ART_BIBLE.md "Menu diorama"). A living pixel-art graveyard at night
## behind every out-of-run screen: a sky with a moon, stars and clouds, far
## hills with the Covenant's cathedral, a mid graveyard of existing obstacle
## art, the near ground on the Graveyard tile, drifting fog, rising soul
## wisps, flickering lanterns and candles, and undead shuffling past on their
## walk strips. Purely cosmetic: real time, a private RNG, no gameplay state.
##
## Coordinates are DESIGN px on the 1280x720 layout (1 art px = 1 layout px):
## x is an offset from the screen's centre line (negative = left), so a wider
## window (aspect "expand") reveals more of the scene at both sides; y runs
## from the top of a 720 px tall design frame whose BOTTOM is pinned to the
## screen's bottom (a taller window shows more sky). Data only, no logic.
class_name MenuBackdropData
extends RefCounted

## Sprite key prefix of the diorama's own art (SpriteData.ROOT + "menu/<id>.png").
const ART: String = "menu/"

## Design frame height (layout px): y values below are in this frame.
const DESIGN_H: float = 720.0  # TUNING (not in GDD) the 1280x720 layout

# ------------------------------------------------------------------ depth layers

## Parallax factor per depth layer (0 = fixed to the sky, 1 = moves with the
## camera drift): the slow camera sway moves near layers more than far ones.
const PARALLAX: Dictionary = {
	"sky": 0.0,  # TUNING (not in GDD) moon, stars and clouds stay put
	"far": 0.2,  # TUNING (not in GDD) far hills and the cathedral
	"mid": 0.5,  # TUNING (not in GDD) the graveyard props
	"near": 1.0,  # TUNING (not in GDD) the ground, near props, walkers
}

## Camera drift amplitude (layout px, the near layer's sway each side; 0 = off).
const DRIFT_PX: float = 9.0  # TUNING (not in GDD) a barely noticed slow sway
## Camera drift period (s, one full sway left-right-left).
const DRIFT_PERIOD: float = 46.0  # TUNING (not in GDD)
## Vertical part of the drift as a share of the horizontal (0-1).
const DRIFT_Y_SHARE: float = 0.25  # TUNING (not in GDD)

# ------------------------------------------------------------------ sky

## Sky band edges: design y (layout px) where each band of MOODS[..].sky ends,
## top to bottom; the last band runs to the horizon and down behind the hills.
## Flat bands of colour, no gradient (pixel-art sky).
const SKY_BAND_ENDS: Array = [120.0, 220.0, 300.0, 370.0, 430.0, 480.0, 720.0]  # TUNING (not in GDD)

## Moon centre (design px: x from the centre line, y from the top).
const MOON_POS: Vector2 = Vector2(395.0, 140.0)  # TUNING (not in GDD) upper right, clear of the logo
## Halo breathing: amplitude of the halo alpha swing (share of its alpha, 0-1).
const HALO_PULSE: float = 0.18  # TUNING (not in GDD)
## Halo breathing period (s).
const HALO_PERIOD: float = 9.0  # TUNING (not in GDD)

## Stars per 10,000 px² of sky above STAR_MAX_Y.
const STAR_DENSITY: float = 1.3  # TUNING (not in GDD) about 70 stars at 1280x720
## Lowest design y of a star (layout px; stars thin out toward it).
const STAR_MAX_Y: float = 400.0  # TUNING (not in GDD)
## Radius around the moon kept free of stars (layout px).
const STAR_MOON_CLEAR: float = 120.0  # TUNING (not in GDD)
## Share of stars drawn as the small plus (frame 1) and as the bright plus
## (frame 2); the rest are single-pixel dots (frame 0).
const STAR_PLUS_SHARE: float = 0.18  # TUNING (not in GDD)
const STAR_BRIGHT_SHARE: float = 0.03  # TUNING (not in GDD)
## Twinkle: each star's alpha swings by up to this share (0-1) ...
const STAR_TWINKLE: float = 0.45  # TUNING (not in GDD)
## ... at a speed picked between these (rad/s).
const STAR_TWINKLE_SPEED: Vector2 = Vector2(0.6, 2.4)  # TUNING (not in GDD)
## Seed of the star field (fixed, so the sky looks the same on every visit).
const STAR_SEED: int = 7177  # TUNING (not in GDD)

## Shooting stars: seconds between two (random in this range), the first
## one's delay, flight speed (px/s), life (s), tail length (px) and the
## design y range of their start.
const METEOR_INTERVAL: Vector2 = Vector2(10.0, 22.0)  # TUNING (not in GDD) rare: a small reward for watching
const METEOR_FIRST: float = 6.5  # TUNING (not in GDD)
const METEOR_SPEED: float = 420.0  # TUNING (not in GDD)
const METEOR_LIFE: float = 0.55  # TUNING (not in GDD)
const METEOR_TAIL: float = 34.0  # TUNING (not in GDD)
const METEOR_Y: Vector2 = Vector2(30.0, 220.0)  # TUNING (not in GDD)

## Slope range of a shooting star's flight (down per px across; random).
const METEOR_SLOPE: Vector2 = Vector2(0.3, 0.55)  # TUNING (not in GDD)
## Star height bias: >1 packs the stars toward the top of the sky.
const STAR_HIGH_BIAS: float = 1.6  # TUNING (not in GDD)

## Drifting clouds: [art id, design y, start x (from the centre), speed px/s,
## alpha 0-1]. They wrap around the screen; one crosses the moon now and then.
const CLOUDS: Array = [
	["cloud_2", 96.0, 160.0, 4.0, 0.85],  # TUNING (not in GDD)
	["cloud_1", 182.0, -420.0, 2.6, 0.7],  # TUNING (not in GDD)
	["cloud_3", 62.0, -80.0, 5.5, 0.6],  # TUNING (not in GDD)
	["cloud_1", 268.0, 520.0, 3.2, 0.55],  # TUNING (not in GDD)
]
## Extra margin (layout px) beyond each screen edge where clouds wrap.
const CLOUD_WRAP_MARGIN: float = 320.0  # TUNING (not in GDD)

## Bats: a small flock now and then crosses the sky (over the moon at times).
## Seconds between two flocks (random in this range); the first comes early.
const BAT_INTERVAL: Vector2 = Vector2(9.0, 18.0)  # TUNING (not in GDD)
const BAT_FIRST: float = 3.0  # TUNING (not in GDD)
## Bats per flock (random, inclusive range).
const BAT_COUNT: Vector2i = Vector2i(1, 3)  # TUNING (not in GDD)
## Flight speed (px/s, random per flock) and the design y range of a flock's path.
const BAT_SPEED: Vector2 = Vector2(55.0, 80.0)  # TUNING (not in GDD)
const BAT_Y: Vector2 = Vector2(70.0, 300.0)  # TUNING (not in GDD)
## Flutter: vertical bob amplitude (px) and wing beats per second (2-frame strip).
const BAT_BOB: float = 4.0  # TUNING (not in GDD)
const BAT_FLAP_FPS: float = 9.0  # TUNING (not in GDD)
## Spacing between the bats of a flock (px, random) and their scatter around
## the flock's path (± px), and each bat's speed scatter (± share, 0-1).
const BAT_SPACING: Vector2 = Vector2(18.0, 34.0)  # TUNING (not in GDD)
const BAT_Y_JITTER: float = 14.0  # TUNING (not in GDD)
const BAT_SPEED_JITTER: float = 0.08  # TUNING (not in GDD)
## Most flocks in the sky at once.
const BAT_MAX_FLOCKS: int = 1  # TUNING (not in GDD)

# ------------------------------------------------------------------ far layer

## Far hill strip (tinted silhouette, repeats left-right): bottom edge design y.
const HILLS_FAR_BOTTOM: float = 560.0  # TUNING (not in GDD)
## Mid hill strip (darker silhouette in front): bottom edge design y.
const HILLS_MID_BOTTOM: float = 616.0  # TUNING (not in GDD)

## Far set pieces: [sprite key, x (from the centre), base design y (the
## sprite's bottom edge), mirrored, brightness 0-1 (times the mood's far
## tint: light art such as stone is pushed back into the night)]. Drawn
## tinted BEFORE the far hill strip, so a base below the hill ridge sinks into it.
const FAR_PROPS: Array = [
	["menu/cathedral", -420.0, 548.0, false, 1.0],  # TUNING (not in GDD) the Covenant's cathedral on the horizon
	["obstacles/tower_base_m", 520.0, 552.0, false, 0.42],  # TUNING (not in GDD) a ruined tower on the right hills, balancing the cathedral
	["obstacles/dead_tree_s", 300.0, 534.0, true, 0.6],  # TUNING (not in GDD)
	["obstacles/cypress_l", -700.0, 530.0, false, 0.5],  # TUNING (not in GDD) shown on wide windows
	["obstacles/cypress_s", 760.0, 530.0, false, 0.5],  # TUNING (not in GDD) shown on wide windows
]
## Covenant torches on the horizon (GDD §11: red torches advance): [x, y]
## design px, a small warm glow each, flickering.
const TORCHES: Array = [
	Vector2(-482.0, 532.0), Vector2(-362.0, 530.0), Vector2(-430.0, 520.0),  # TUNING (not in GDD) around the cathedral
]
## Torch glow size (share of the glow sprite's size) and alpha (0-1).
const TORCH_GLOW_SCALE: float = 0.38  # TUNING (not in GDD)
const TORCH_GLOW_ALPHA: float = 0.7  # TUNING (not in GDD)

# ------------------------------------------------------------------ mid layer

## Mid graveyard props: [sprite key, x (from the centre), base design y,
## mirrored]. Existing obstacle art plus the mausoleum, tinted by the mood's
## mid tint (night light). Drawn in list order (back to front).
const MID_PROPS: Array = [
	["obstacles/dead_tree_l", -600.0, 596.0, true],  # TUNING (not in GDD)
	["obstacles/crypt_wall_l", -505.0, 596.0, false],  # TUNING (not in GDD)
	["menu/mausoleum", -400.0, 594.0, false],  # TUNING (not in GDD)
	["obstacles/gravestone_l", -330.0, 598.0, false],  # TUNING (not in GDD)
	["obstacles/gravestone_s", -292.0, 600.0, true],  # TUNING (not in GDD)
	["obstacles/cypress_l", 262.0, 596.0, false],  # TUNING (not in GDD)
	["obstacles/saint_statue_m", 318.0, 596.0, false],  # TUNING (not in GDD) a graveyard angel
	["obstacles/gravestone_l", 392.0, 598.0, true],  # TUNING (not in GDD)
	["obstacles/gravestone_s", 432.0, 600.0, false],  # TUNING (not in GDD)
	["obstacles/dead_tree_m", 548.0, 596.0, false],  # TUNING (not in GDD)
	["obstacles/crypt_wall_s", 640.0, 598.0, true],  # TUNING (not in GDD) at the right edge
	# Beyond 1280 px: only on wide windows.
	["obstacles/gravestone_l", -720.0, 598.0, false],  # TUNING (not in GDD)
	["obstacles/dead_tree_s", -800.0, 596.0, false],  # TUNING (not in GDD)
	["obstacles/gravestone_s", 720.0, 600.0, true],  # TUNING (not in GDD)
	["obstacles/dead_tree_l", 840.0, 596.0, true],  # TUNING (not in GDD)
	["obstacles/crypt_wall_m", -900.0, 598.0, false],  # TUNING (not in GDD)
	["obstacles/gravestone_l", 960.0, 598.0, false],  # TUNING (not in GDD)
]
## Wrought-iron fence runs behind the mid props: [x from, x to, base design y].
const FENCES: Array = [
	[-580.0, -440.0, 592.0],  # TUNING (not in GDD)
	[300.0, 620.0, 592.0],  # TUNING (not in GDD)
	[-1000.0, -760.0, 592.0],  # TUNING (not in GDD)
	[760.0, 1000.0, 592.0],  # TUNING (not in GDD)
]

## Grave lanterns: [x (from the centre), base design y, depth layer]. Each
## burns a soul flame (soul-teal: the undead's colour) with a pulsing glow.
const LANTERNS: Array = [
	[-452.0, 600.0, "mid"],  # TUNING (not in GDD)
	[478.0, 600.0, "mid"],  # TUNING (not in GDD)
	[-548.0, 704.0, "near"],  # TUNING (not in GDD)
]
## Flame centre above a lantern's base (layout px, inside the cage).
const LANTERN_FLAME_UP: float = 33.0  # TUNING (not in GDD) matches the cage in menu/lantern.png
## Candle clusters: [x (from the centre), base design y, depth layer]; warm flames.
const CANDLES: Array = [
	[-344.0, 600.0, "mid"],  # TUNING (not in GDD) at the large gravestone
	[406.0, 600.0, "mid"],  # TUNING (not in GDD)
	[566.0, 708.0, "near"],  # TUNING (not in GDD)
]
## Wick tops of a candle cluster (layout px from the cluster's bottom-left
## corner): where the three small flames sit.
const CANDLE_WICKS: Array = [Vector2(3.0, -11.0), Vector2(7.0, -8.0), Vector2(11.0, -10.0)]  # TUNING (not in GDD) matches menu/candles.png
## Flame frame rate (frames per s; each flame starts at a random phase).
const FLAME_FPS: float = 7.0  # TUNING (not in GDD)
## Glow sizes (share of the glow sprite) and alpha (0-1) around a lantern
## flame and a candle cluster; the alpha flickers by FLICKER.
const LANTERN_GLOW_SCALE: float = 1.25  # TUNING (not in GDD)
const LANTERN_GLOW_ALPHA: float = 0.32  # TUNING (not in GDD)
const CANDLE_GLOW_SCALE: float = 0.9  # TUNING (not in GDD)
const CANDLE_GLOW_ALPHA: float = 0.26  # TUNING (not in GDD)
## Glow colour of the soul fire (lanterns, wisps): the palette's soul_glow.
const SOUL_GLOW: Color = Color("a8ffd2")  # TUNING (not in GDD) palette soul_glow
## Glow colour of the candle clusters (warm, between flame and gold_light).
const CANDLE_GLOW: Color = Color(1.0, 0.72, 0.36)  # TUNING (not in GDD)
## Centre of a candle cluster's glow from the cluster's bottom-left corner (px).
const CANDLE_GLOW_OFFSET: Vector2 = Vector2(7.0, -10.0)  # TUNING (not in GDD) over the three wicks
## Flicker depth of a glow (share of its alpha, 0-1).
const FLICKER: float = 0.3  # TUNING (not in GDD)

# ------------------------------------------------------------------ near layer

## Ground: the Graveyard floor tile fills from this design y to the bottom,
## topped by the menu/ground_lip strip (its top edge here minus its height).
const GROUND_TOP: float = 610.0  # TUNING (not in GDD)
## Floor tile key (EnvironmentArt, repeating) under the near layer.
const GROUND_TILE: String = "tiles/graveyard"  # TUNING (not in GDD)

## Near props (foreground, drawn over the ground, darker): [sprite key, x,
## base design y, mirrored]. Partly cropped by the screen's bottom edge.
const NEAR_PROPS: Array = [
	["obstacles/dead_tree_l", -606.0, 736.0, false],  # TUNING (not in GDD) a dark foreground tree at the left edge
	["obstacles/gravestone_l", 594.0, 716.0, false],  # TUNING (not in GDD)
	["obstacles/gravestone_s", 548.0, 712.0, true],  # TUNING (not in GDD)
	["obstacles/rubble_s", -470.0, 722.0, false],  # TUNING (not in GDD)
	["obstacles/gravestone_s", -500.0, 714.0, false],  # TUNING (not in GDD)
	["obstacles/gravestone_l", -860.0, 716.0, true],  # TUNING (not in GDD) wide windows
	["obstacles/dead_tree_m", 900.0, 740.0, true],  # TUNING (not in GDD) wide windows
]

## Floor decals on the near ground (the Graveyard's own decals, flat on the
## ground): [sprite key, x (from the centre), design y of the decal's centre].
## Kept clear of the menu column so the hints stay readable.
const NEAR_DECALS: Array = [
	["decals/graveyard_grave", -430.0, 670.0],  # TUNING (not in GDD) an open grave
	["decals/graveyard_grass", -560.0, 640.0],  # TUNING (not in GDD)
	["decals/graveyard_grass_3", -330.0, 702.0],  # TUNING (not in GDD)
	["decals/graveyard_grass_2", -250.0, 648.0],  # TUNING (not in GDD)
	["decals/graveyard_grave_2", 430.0, 676.0],  # TUNING (not in GDD)
	["decals/graveyard_grass", 300.0, 706.0],  # TUNING (not in GDD)
	["decals/graveyard_grass_3", 500.0, 640.0],  # TUNING (not in GDD)
	["decals/graveyard_grass_2", 640.0, 690.0],  # TUNING (not in GDD)
	["decals/graveyard_grave", -780.0, 680.0],  # TUNING (not in GDD) wide windows
	["decals/graveyard_grass", 820.0, 660.0],  # TUNING (not in GDD) wide windows
]

# ------------------------------------------------------------------ fog

## Fog banks (tintable, repeating left-right): [art id, bottom design y,
## speed px/s (negative = drifts left), alpha 0-1, drawn after this depth layer].
const FOG: Array = [
	["fog_1", 540.0, 5.0, 0.16, "far"],  # TUNING (not in GDD) haze over the far hills
	["fog_2", 612.0, -8.0, 0.20, "mid"],  # TUNING (not in GDD) around the gravestones' feet
	["fog_1", 736.0, 12.0, 0.13, "near"],  # TUNING (not in GDD) low over the near ground, in front of the walkers
]
## Fog swell: each bank's alpha also breathes by this share (0-1) ...
const FOG_PULSE: float = 0.25  # TUNING (not in GDD)
## ... over this period (s).
const FOG_PERIOD: float = 13.0  # TUNING (not in GDD)

# ------------------------------------------------------------------ soul wisps

## Graves the soul wisps rise from: [x, design y, depth layer]. A wisp may
## also rise from a random spot of the near ground (WISP_GROUND_SHARE).
const WISP_SOURCES: Array = [
	[-330.0, 580.0, "mid"], [-292.0, 588.0, "mid"], [-394.0, 572.0, "mid"],  # TUNING (not in GDD)
	[392.0, 580.0, "mid"], [432.0, 588.0, "mid"], [318.0, 588.0, "mid"],  # TUNING (not in GDD)
	[594.0, 700.0, "near"], [548.0, 702.0, "near"], [-600.0, 590.0, "mid"],  # TUNING (not in GDD)
]
## Share of wisps that rise from a random point of the near ground instead.
const WISP_GROUND_SHARE: float = 0.3  # TUNING (not in GDD)
## Design y range of a wisp rising from the near ground (WISP_GROUND_SHARE).
const WISP_GROUND_Y: Vector2 = Vector2(630.0, 710.0)  # TUNING (not in GDD)
## Sideways scatter (± px) of a wisp's start around its grave.
const WISP_SOURCE_JITTER: float = 6.0  # TUNING (not in GDD)
## Height (px) of a wisp's glow centre above the wisp's base.
const WISP_GLOW_UP: float = 6.0  # TUNING (not in GDD)
## Seconds between two wisps (random in this range).
const WISP_INTERVAL: Vector2 = Vector2(0.45, 1.1)  # TUNING (not in GDD)
## Most wisps alive at once.
const WISP_MAX: int = 12  # TUNING (not in GDD) keeps it calm (and the draw count small)
## Rise speed (px/s, random in this range).
const WISP_RISE: Vector2 = Vector2(9.0, 17.0)  # TUNING (not in GDD)
## Life (s, random in this range): fades in over the first WISP_FADE_IN s, out over the last WISP_FADE_OUT.
const WISP_LIFE: Vector2 = Vector2(3.5, 6.5)  # TUNING (not in GDD)
const WISP_FADE_IN: float = 0.6  # TUNING (not in GDD)
const WISP_FADE_OUT: float = 1.6  # TUNING (not in GDD)
## Sideways sway amplitude (px, random in this range) and its speed (rad/s).
const WISP_SWAY: Vector2 = Vector2(3.0, 8.0)  # TUNING (not in GDD)
const WISP_SWAY_SPEED: Vector2 = Vector2(1.2, 2.2)  # TUNING (not in GDD)
## Wisp flicker animation (frames per s through the 4-frame strip).
const WISP_FPS: float = 8.0  # TUNING (not in GDD)
## Glow under a wisp: size (share of the glow sprite) and alpha (0-1).
const WISP_GLOW_SCALE: float = 0.75  # TUNING (not in GDD)
const WISP_GLOW_ALPHA: float = 0.34  # TUNING (not in GDD)
## A mid-layer wisp is drawn at this alpha share (farther away, 0-1).
const WISP_MID_ALPHA: float = 0.7  # TUNING (not in GDD)

# ------------------------------------------------------------------ walkers

## Troupes of undead that shuffle across the near ground, one sprite key per
## member (still + "_walk" strip, WalkData), leader first. Picked at random.
const TROUPES: Array = [
	["summons/warrior", "summons/warrior", "summons/archer"],  # TUNING (not in GDD)
	["summons/mage"],  # TUNING (not in GDD)
	["summons/bone_hound", "summons/bone_hound"],  # TUNING (not in GDD)
	["player/necromancer", "summons/warrior", "summons/archer", "summons/mage"],  # TUNING (not in GDD) rare: the master and his army
	["summons/risen", "summons/risen"],  # TUNING (not in GDD)
	["summons/archer", "summons/warrior"],  # TUNING (not in GDD)
	["summons/rogue"],  # TUNING (not in GDD)
]
## Relative pick weight of each TROUPES entry (same order).
const TROUPE_WEIGHTS: Array = [3.0, 2.0, 1.5, 0.8, 1.5, 2.0, 1.0]  # TUNING (not in GDD)
## Walk speed (px/s) per troupe (a troupe keeps step); the hounds trot faster.
const TROUPE_SPEED: Vector2 = Vector2(22.0, 30.0)  # TUNING (not in GDD) random in this range
## Speed of a troupe of hounds (px/s).
const HOUND_SPEED: float = 46.0  # TUNING (not in GDD)
## Spacing between troupe members (px, random in this range).
const TROUPE_GAP: Vector2 = Vector2(30.0, 42.0)  # TUNING (not in GDD)
## Least clearance (px) between two troupe members beyond the front one's width.
const TROUPE_MIN_CLEARANCE: float = 4.0  # TUNING (not in GDD)
## Walk-cycle offset per px of a member's gap (frames shift by gap x this /
## STRIDE_PER_FRAME), so a troupe does not step in perfect unison.
const TROUPE_STEP_SHIFT: float = 0.37  # TUNING (not in GDD)
## Margin (px) beyond the screen edge where walkers and bats enter and leave
## (scaled a little per use so nobody pops in or out on screen).
const EDGE_MARGIN: float = 40.0  # TUNING (not in GDD)
## Walk lanes: feet design y and a tint factor (the farther lane is darker).
const LANES: Array = [
	[664.0, 0.86],  # TUNING (not in GDD) the far lane
	[694.0, 1.0],  # TUNING (not in GDD) the near lane
]
## Seconds before the first troupe enters (so a still screenshot or a short
## visit already shows one).
const FIRST_TROUPE_DELAY: float = 0.6  # TUNING (not in GDD)
## Seconds between a troupe leaving the frame and the next one entering
## (random in this range).
const TROUPE_INTERVAL: Vector2 = Vector2(3.0, 9.0)  # TUNING (not in GDD)
## Most troupes walking at once (different lanes).
const TROUPE_MAX: int = 2  # TUNING (not in GDD) never crowd the menu
## Walk strip frame advance: px walked per frame of the 8-frame cycle.
const STRIDE_PER_FRAME: float = 3.6  # TUNING (not in GDD) ~7 fps at 26 px/s, like the in-game cadence
## Body bob (px) on top of the strip's own dip: 0 = the strip alone.
const WALKER_BOB: float = 0.0  # TUNING (not in GDD)
## Drop shadow under a walker: width share of its height, squash, alpha.
const WALKER_SHADOW: Vector3 = Vector3(0.5, 0.3, 0.4)  # TUNING (not in GDD)

# ------------------------------------------------------------------ shade

## Darker band behind the menu column (a horizontal fade): its full width
## (layout px), centre x offset from the screen centre and peak alpha (0-1).
const BAND_WIDTH: float = 820.0  # TUNING (not in GDD) the 420 px menu column plus a soft margin
const BAND_CENTER_X: float = 0.0  # TUNING (not in GDD)
const BAND_ALPHA: float = 0.5  # TUNING (not in GDD)
## Edge vignette: alpha (0-1) at the screen corners (radial fade from the centre).
const VIGNETTE_ALPHA: float = 0.34  # TUNING (not in GDD)
## Alpha stops of the column band across its width: (position 0-1, alpha
## share 0-1 of BAND_ALPHA); soft edges, the darkest part in the middle.
const BAND_RAMP: Array = [Vector2(0.0, 0.0), Vector2(0.3, 0.75), Vector2(0.5, 1.0), Vector2(0.7, 0.75), Vector2(1.0, 0.0)]  # TUNING (not in GDD)
## Alpha stops of the vignette from the centre (0) to the corners (1):
## (position 0-1, alpha share 0-1 of VIGNETTE_ALPHA).
const VIGNETTE_RAMP: Array = [Vector2(0.0, 0.0), Vector2(0.55, 0.25), Vector2(1.0, 1.0)]  # TUNING (not in GDD)
## Dim over the whole diorama while a sub-screen covers the menu (0-1 alpha).
const DIM_ALPHA: float = 0.3  # TUNING (not in GDD)
## Seconds for the dim (and the menu content's fade) to settle.
const DIM_TIME: float = 0.25  # TUNING (not in GDD)
## Colour of the band, vignette and dim (alpha set by the values above).
const SHADE_COLOR: Color = Color(0.02, 0.01, 0.04)  # TUNING (not in GDD) the UI's near-black violet

## A sub-screen's own full-screen scrim (its UiTheme.backdrop ColorRect) is
## lowered to at most this alpha while it sits over the main menu, so the
## dimmed diorama stays visible around the panel (MainMenu does this).
const OVERLAY_SCRIM_ALPHA: float = 0.4  # TUNING (not in GDD)

# ------------------------------------------------------------------ moods

## Mood colour sets (set_mood() fades between them over MOOD_FADE s). "graveyard"
## is the default night. Hook for later screens: e.g. the stage select could
## call set_mood("crimson_march") while a stage card is focused.
##   sky: band colours top to bottom (SKY_BAND_ENDS); moon: moon tint;
##   halo: halo colour (alpha = strength); cloud: cloud tint (alpha = opacity);
##   star: star colour (alpha = brightness); far / far_hills / mid_hills: tints
##   of the far props, the far hill and mid hill silhouettes; mid / near: tints
##   of the mid and near props (night light); ground: floor tile tint;
##   fog: fog colour; torch: horizon torch colour; actor: walker tint.
const MOODS: Dictionary = {
	"graveyard": {
		"sky": [Color("08060f"), Color("0c0918"), Color("110d20"), Color("161229"), Color("1c1732"), Color("231d3c"), Color("2a2344")],
		"moon": Color(1.0, 1.0, 1.0),
		"halo": Color(0.65, 0.72, 0.95, 0.10),
		"cloud": Color(0.24, 0.21, 0.36, 0.9),
		"star": Color(0.9, 0.93, 1.0, 1.0),
		"far": Color(0.62, 0.62, 0.78),
		"far_hills": Color("17152a"),
		"mid_hills": Color("0d0d17"),
		"mid": Color(0.6, 0.62, 0.78),
		"near": Color(0.55, 0.56, 0.7),
		"ground": Color(1.1, 1.1, 1.25),
		"fog": Color(0.62, 0.68, 0.86),
		"torch": Color(1.0, 0.5, 0.2),
		"actor": Color(0.92, 0.94, 1.05),
	},
	"crimson_march": {
		"sky": [Color("0a0407"), Color("12060a"), Color("1b080d"), Color("260b10"), Color("341014"), Color("461717"), Color("552018")],
		"moon": Color(1.0, 0.78, 0.66),
		"halo": Color(0.95, 0.45, 0.35, 0.12),
		"cloud": Color(0.22, 0.09, 0.1, 0.9),
		"star": Color(1.0, 0.85, 0.8, 0.6),
		"far": Color(0.6, 0.45, 0.45),
		"far_hills": Color("221016"),
		"mid_hills": Color("120a0d"),
		"mid": Color(0.62, 0.52, 0.55),
		"near": Color(0.45, 0.36, 0.38),
		"ground": Color(0.9, 0.8, 0.8),
		"fog": Color(0.8, 0.55, 0.5),
		"torch": Color(1.0, 0.45, 0.15),
		"actor": Color(0.9, 0.8, 0.82),
	},
	"sanctum": {
		"sky": [Color("0c0c1c"), Color("141428"), Color("1e1c34"), Color("2a2640"), Color("3a3246"), Color("4c3f48"), Color("5c4a46")],
		"moon": Color(1.0, 0.97, 0.88),
		"halo": Color(1.0, 0.86, 0.55, 0.12),
		"cloud": Color(0.28, 0.25, 0.34, 0.85),
		"star": Color(1.0, 0.96, 0.85, 0.5),
		"far": Color(0.7, 0.66, 0.72),
		"far_hills": Color("231f30"),
		"mid_hills": Color("13111c"),
		"mid": Color(0.7, 0.68, 0.78),
		"near": Color(0.5, 0.48, 0.58),
		"ground": Color(0.92, 0.9, 0.95),
		"fog": Color(0.9, 0.84, 0.75),
		"torch": Color(1.0, 0.75, 0.3),
		"actor": Color(0.9, 0.88, 0.95),
	},
}
## Default mood (the menu's night graveyard).
const DEFAULT_MOOD: String = "graveyard"  # TUNING (not in GDD)
## Seconds for set_mood() to fade from one mood to the next.
const MOOD_FADE: float = 1.2  # TUNING (not in GDD)
