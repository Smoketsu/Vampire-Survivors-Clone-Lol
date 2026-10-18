## DreadData — DREAD, the Ancient Eye's one new status (GDD §15.0 "Act II: the
## Ancient Eye"; owner-approved at this strength). A 0..MAX meter on the
## NECROMANCER only, on a stage whose STAGE has "dread": true (Act II). It
## rises in the Eye's hazards (spore clouds, ink, the god's gaze: each calls
## DreadMeter.add()) and falls by FALL_PER_KILL per kill, since souls steady
## the mind. Every STEP of Dread adds TAKEN_PER_STEP damage taken (+20% at
## MAX), applied in CombatResolver.damage_player() as its own multiplier. The
## screen edges darken with it (DreadVignette): purely visual, lighter under
## Reduce motion and Effects = Reduced, and it never takes control away.
## The paired counter-passive Iron Mind (Act II, unlocked by an achievement)
## reads IRON_MIND's level values RISE_KEY and FALL_KEY when it exists.
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name DreadData
extends RefCounted

## Most Dread the meter holds.
const MAX: float = 100.0  # TUNING (not in GDD) owner-approved proposal "a 0-100 meter"
## Dread lost per kill (any kill the necromancer's side makes).
const FALL_PER_KILL: float = 1.0  # TUNING (not in GDD) owner-approved proposal "falls by 1 per kill"
## Dread per step of the damage-taken bonus.
const STEP: float = 25.0  # TUNING (not in GDD) owner-approved proposal "each 25 Dread"
## Extra damage taken per full STEP (fraction: 0.05 = +5%).
const TAKEN_PER_STEP: float = 0.05  # TUNING (not in GDD) owner-approved proposal "+5% damage taken (+20% at 100)"

## Passive id of the Iron Mind counter-passive (PassiveData, Act II).
const IRON_MIND: String = "iron_mind"
## Iron Mind level key: fraction by which Dread rises slower (0.1 = 10% slower).
const RISE_KEY: String = "dread_rise_reduction"
## Iron Mind level key: multiplier on the Dread a kill removes (1 = unchanged).
const FALL_KEY: String = "dread_fall_mult"

# --- The look (DreadVignette, HUD; drawing only) ---------------------------------------

## Colour of the darkening at the screen edges.
const VIGNETTE_COLOR: Color = Color(0.03, 0.05, 0.08)  # TUNING (not in GDD) abyssal near-black
## Edge darkness (alpha 0..1) at MAX Dread.
const VIGNETTE_MAX_ALPHA: float = 0.55  # TUNING (not in GDD) visual
## The vignette's alpha with Reduce motion or Effects = Reduced, as a fraction
## of the full look.
const VIGNETTE_REDUCED: float = 0.5  # TUNING (not in GDD) visual
## Fraction of the screen's half-size the darkening reaches in from each edge at MAX.
const VIGNETTE_REACH: float = 0.35  # TUNING (not in GDD) visual
## Hz of the slow "whisper" pulse of the edges (0 under Reduce motion).
const VIGNETTE_PULSE_HZ: float = 0.35  # TUNING (not in GDD) visual
## Depth of that pulse (fraction of the alpha).
const VIGNETTE_PULSE: float = 0.18  # TUNING (not in GDD) visual
## Dread below which nothing is drawn.
const VIGNETTE_FROM: float = 5.0  # TUNING (not in GDD) visual
## HUD meter fill colour (bioluminescent violet; never the UI's soul-teal).
const BAR_COLOR: Color = Color(0.56, 0.38, 0.92)  # TUNING (not in GDD) EyePalette violet
## HUD meter colour from the second step up (the bonus is biting).
const BAR_HOT_COLOR: Color = Color(0.82, 0.30, 0.62)  # TUNING (not in GDD) visual
## Seconds over which the HUD meter's shown value follows the real one (drawing only).
const BAR_EASE: float = 0.25  # TUNING (not in GDD) visual
