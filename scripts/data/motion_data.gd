## MotionData: numbers of the tier-0 "engine motion" (GDD §15.0 "Art pass
## (true pixel art)": step bob, lean, turn squash, attack lunge and recoil,
## hit squash, summon rise, death dissolve). Every unit is one still image or
## glyph; UnitMotion deforms it around its feet so it reads as alive at
## 40-60 px. All of it is purely visual (MotionDirector applies it to the
## units' body layers), so none of these values can change a run.
## Deformations are fractions of the body size (scale) or shear factors
## (horizontal px per px of height above the feet; 0.09 is about 5 degrees).
## Data only, no logic.
class_name MotionData
extends RefCounted

# --- Size and pivot -------------------------------------------------------------------

## Body radius (px) at which a unit gets the full motion amplitude; bigger
## bodies get REF_RADIUS / radius of it (heavies, minibosses, bosses move less).
const REF_RADIUS: float = 13.0  # TUNING (not in GDD)
## Smallest amplitude factor the size rule can give (0..1).
const MIN_SIZE_SCALE: float = 0.45  # TUNING (not in GDD)
## Extra amplitude factor of the three stage bosses (0..1; on top of the size rule).
const BOSS_SCALE: float = 0.6  # TUNING (not in GDD)
## Extra amplitude factor of a miniboss (Cathedral Guardian; 0..1).
const MINIBOSS_SCALE: float = 0.75  # TUNING (not in GDD)
## Amplitude factor of a structure's hit squash (0..1; structures get only the hit reaction).
const STRUCTURE_SCALE: float = 0.6  # TUNING (not in GDD)
## Feet line of a sprite as a fraction of its drawn height below its origin:
## SpriteBank's drop-shadow centre (SpriteData.CENTER_OFFSET -0.12 + 0.46),
## so the shadow sits on the pivot and barely moves.
const FEET_FRACTION: float = 0.34  # TUNING (not in GDD)
## Feet line of a code-drawn glyph (no sprite yet), as a multiple of the body radius.
const GLYPH_FEET: float = 1.0  # TUNING (not in GDD)

# --- Step bob ---------------------------------------------------------------------------

## Peak vertical stretch of the step bob (fraction of height, +- around 1);
## the width moves the other way by BOB_VOLUME of it.
const BOB_STRETCH: float = 0.05  # TUNING (not in GDD)
## Share of the bob stretch taken back from the width (0 = none, 1 = area kept).
const BOB_VOLUME: float = 0.5  # TUNING (not in GDD)
## Speed (px/s) below which a unit counts as standing (no bob).
const BOB_MIN_SPEED: float = 12.0  # TUNING (not in GDD)
## Speed (px/s) at which the bob reaches its full height.
const BOB_FULL_SPEED: float = 55.0  # TUNING (not in GDD)
## Stride (px travelled per bob) of a body of radius 0; grows with the radius.
const STRIDE_BASE: float = 14.0  # TUNING (not in GDD)
## Extra stride (px) per px of body radius (big units take longer steps).
const STRIDE_PER_RADIUS: float = 1.0  # TUNING (not in GDD)
## Rate (1/s) at which the measured speed follows the real movement
## (smooths the 0-or-2-ticks-per-frame jitter and crowd shoving).
const SPEED_SMOOTH: float = 10.0  # TUNING (not in GDD)
## A jump longer than this (px) between two frames is a teleport (recall,
## Seraphine's blink, a recycled enemy): it resets the speed instead of
## counting as movement.
const TELEPORT_PX: float = 48.0  # TUNING (not in GDD)

# --- Lean -------------------------------------------------------------------------------

## Largest lean into the movement (shear; 0.09 is about 5 degrees).
const LEAN_MAX: float = 0.09  # TUNING (not in GDD)
## Horizontal speed (px/s) at which the lean is full.
const LEAN_FULL_SPEED: float = 90.0  # TUNING (not in GDD)
## Rate (1/s) at which the lean follows its target.
const LEAN_RATE: float = 9.0  # TUNING (not in GDD)

# --- Turn squash -----------------------------------------------------------------------

## Seconds of the horizontal squash when the facing flips.
const TURN_TIME: float = 0.08  # TUNING (not in GDD)
## Peak width lost during a turn (fraction).
const TURN_SQUASH: float = 0.22  # TUNING (not in GDD)
## A flip sooner than this (s) after the last squashed one does not squash
## again (units dithering left / right would otherwise twitch).
const TURN_MIN_GAP: float = 0.3  # TUNING (not in GDD)

# --- Hit squash ------------------------------------------------------------------------

## Seconds of the squash (and its small spring back) after a hit.
const HIT_TIME: float = 0.16  # TUNING (not in GDD)
## Peak height lost on a hit (fraction); the width grows by HIT_WIDEN of it.
const HIT_SQUASH: float = 0.16  # TUNING (not in GDD)
## Share of the hit squash added to the width.
const HIT_WIDEN: float = 0.6  # TUNING (not in GDD)
## A hit sooner than this (s) after the last squash does not squash again
## (damage over time and hit streams pulse instead of shaking).
const HIT_MIN_GAP: float = 0.25  # TUNING (not in GDD)

# --- Attack lunge and recoil ---------------------------------------------------------

## Seconds of one lunge: the push toward the target, then back with a small recoil.
const LUNGE_TIME: float = 0.22  # TUNING (not in GDD)
## Fraction of LUNGE_TIME spent pushing forward (the rest returns).
const LUNGE_PEAK: float = 0.3  # TUNING (not in GDD)
## Peak forward shear of a horizontal lunge at power 1 (about 9 degrees).
const LUNGE_SHEAR: float = 0.16  # TUNING (not in GDD)
## Peak forward stretch of a horizontal lunge (fraction of width).
const LUNGE_STRETCH: float = 0.07  # TUNING (not in GDD)
## Peak vertical stretch of a lunge straight up (a lunge down squashes instead).
const LUNGE_LIFT: float = 0.07  # TUNING (not in GDD)
## Peak squash of a lunge without a direction (stomps, wails, novas, landings).
const SLAM_SQUASH: float = 0.15  # TUNING (not in GDD)
## A new lunge is ignored until this fraction of the previous one has played.
const LUNGE_RETRIGGER: float = 0.6  # TUNING (not in GDD)
## Lunge power (0..1) of a melee strike or a class special.
const POWER_MELEE: float = 1.0  # TUNING (not in GDD)
## Lunge power of a shot (arrows, bolts, boulders).
const POWER_SHOT: float = 0.6  # TUNING (not in GDD)
## Lunge power of a cast (heals, wards, auras, Sanctum rites).
const POWER_CAST: float = 0.5  # TUNING (not in GDD)
## Lunge power of one of the necromancer's own spells (they fire often).
const POWER_PLAYER_CAST: float = 0.45  # TUNING (not in GDD)

# --- Summon rise ------------------------------------------------------------------------

## Seconds a new summon takes to rise out of the ground.
const RISE_TIME: float = 0.3  # TUNING (not in GDD)
## Extra width at the start of the rise (fraction; it narrows as it emerges).
const RISE_WIDEN: float = 0.3  # TUNING (not in GDD)
## Height overshoot at the end of the rise (fraction; a small pop).
const RISE_OVERSHOOT: float = 0.08  # TUNING (not in GDD)
## Grave-dust motes kicked up by a rising summon.
const RISE_DUST: int = 6  # TUNING (not in GDD)

# --- Death dissolve ------------------------------------------------------------------

## Seconds a dead unit takes to collapse into dust.
const DISSOLVE_TIME: float = 0.4  # TUNING (not in GDD)
## Height lost by the end of the collapse (fraction).
const DISSOLVE_SQUASH: float = 0.85  # TUNING (not in GDD)
## Width gained by the end of the collapse (fraction).
const DISSOLVE_WIDEN: float = 0.35  # TUNING (not in GDD)
## Dust motes released per dissolve (bigger bodies release up to x2).
const DISSOLVE_DUST: int = 7  # TUNING (not in GDD)
## Dissolves playing at once above which new ones are skipped (cost cap).
const MAX_DISSOLVES: int = 48  # TUNING (not in GDD)
## Bone dust of a fallen undead: main and alternate mote colour.
const BONE_DUST: Color = Color(0.82, 0.79, 0.68)  # TUNING (not in GDD)
## Darker bone-dust motes.
const BONE_DUST_DARK: Color = Color(0.45, 0.47, 0.44)  # TUNING (not in GDD)
## Holy ash of a fallen Covenant soldier: pale ash motes.
const HOLY_ASH: Color = Color(0.86, 0.84, 0.78)  # TUNING (not in GDD)
## Holy-ash embers (gold).
const HOLY_EMBER: Color = Color(1.0, 0.8, 0.38)  # TUNING (not in GDD)
## Colour a collapsing undead body fades toward (modulate).
const BONE_FADE_TINT: Color = Color(0.75, 0.75, 0.72)  # TUNING (not in GDD)
## Colour a collapsing Covenant body fades toward (modulate; burns to ash).
const ASH_FADE_TINT: Color = Color(1.0, 0.9, 0.7)  # TUNING (not in GDD)
## Dust mote rise speed (px/s) and its random spread (fraction).
const DUST_RISE: float = 30.0  # TUNING (not in GDD)
## Dust mote sideways speed (px/s at most, either side).
const DUST_SPREAD: float = 26.0  # TUNING (not in GDD)
## Dust mote life (s).
const DUST_LIFE: float = 0.55  # TUNING (not in GDD)
## Dust mote size (px, one art pixel at the 2x grid).
const DUST_SIZE: float = 2.0  # TUNING (not in GDD)

# --- Cost ---------------------------------------------------------------------------------

## Units farther than this (px) outside the camera view are not animated
## this frame (they keep their last pose until they come back in view).
const CULL_MARGIN: float = 96.0  # TUNING (not in GDD)
