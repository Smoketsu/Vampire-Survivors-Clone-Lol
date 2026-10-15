## EffectsData: the Effects quality setting (Settings > Video > Effects: Full
## or Reduced; GDD §15.0 "Mobile browser support"). Reduced lowers the
## visual load for weak devices (phones and tablets start on it). Every
## knob here is purely visual: it changes what is drawn, never what is
## simulated, spawned or rolled, so a run plays out identically (same-seed
## summaries) on either setting, and the autotest always uses Full.
## Data only, no logic.
class_name EffectsData
extends RefCounted

## Setting values, in the order the Settings row cycles them.
const ORDER: Array[String] = ["full", "reduced"]  # TUNING (not in GDD) mobile
## Setting value -> the word shown on the Settings row.
const LABELS: Dictionary = {"full": "Full", "reduced": "Reduced"}  # TUNING (not in GDD) mobile
## Value used on a desktop when the settings file has none.
const DEFAULT_DESKTOP: String = "full"  # TUNING (not in GDD) mobile
## Value used on a phone or tablet when the settings file has none.
const DEFAULT_MOBILE: String = "reduced"  # TUNING (not in GDD) mobile

## --- What Reduced does ---------------------------------------------------------

## Fraction (0..1) of the cosmetic particles (death pops, XP sparkles, dust;
## FxLayer, its own RNG) that are spawned and drawn.
const REDUCED_PARTICLES: float = 0.4  # TUNING (not in GDD) mobile
## Damage numbers below this damage are not shown (boss hits always are);
## Full shows every number (when Damage numbers is on).
const REDUCED_NUMBER_MIN: float = 40.0  # TUNING (not in GDD) mobile; FxLayer.BIG_HIT, the big numbers only
## Cosmetic effects (pops, slashes, rings, beams; EffectManager) beyond this
## many live ones are still simulated but not drawn. Telegraphs always draw.
const REDUCED_VISIBLE_EFFECTS: int = 70  # TUNING (not in GDD) mobile; EffectManager.MAX_COSMETIC is 220
## Multiplier on the screen shake (when Screen shake is on).
const REDUCED_SHAKE: float = 0.5  # TUNING (not in GDD) mobile
