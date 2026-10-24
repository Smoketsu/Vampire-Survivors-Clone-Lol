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

## --- Visual tiers (AdaptiveQuality; GDD §15.0 "Adaptive quality") ---------------------
## Index = tier: 0 Full, 1 Reduced (also the Effects setting), 2 Light and 3 Minimal
## (reached only by the adaptive quality while frames stay slow). Purely visual, like
## everything in this file: what is drawn, never what is simulated.

## Tier names, by tier (MonitorProbe lines, the autotest).
const TIER_NAMES: Array[String] = ["full", "reduced", "light", "minimal"]  # TUNING (not in GDD) mobile
## Volley shots drawn at most per army, by tier (Full draws every shot).
const TIER_SHOTS: Array[int] = [VolleyData.SHOT_CAP, VolleyData.DRAW_CAP_REDUCED, 96, 48]  # TUNING (not in GDD) mobile
## Volley bursts (impacts and launch flashes) drawn at most per army, by tier.
const TIER_BURSTS: Array[int] = [VolleyData.FX_CAP, VolleyData.FX_DRAW_REDUCED, 10, 0]  # TUNING (not in GDD) mobile
## Whether a volley shot's soft glow disc is drawn under its art, by tier.
const TIER_SHOT_GLOW: Array[bool] = [true, true, false, false]  # TUNING (not in GDD) mobile
## A cosmetic effect (EffectManager) spawned while this many or more are live is
## simulated but not drawn, by tier (Full: 220 = EffectManager.MAX_COSMETIC, all drawn).
const TIER_VISIBLE_EFFECTS: Array[int] = [220, REDUCED_VISIBLE_EFFECTS, 40, 20]  # TUNING (not in GDD) mobile
## Fraction (0..1) of the cosmetic particles spawned and drawn, by tier.
const TIER_PARTICLES: Array[float] = [1.0, REDUCED_PARTICLES, 0.2, 0.1]  # TUNING (not in GDD) mobile
## Damage numbers below this damage (and not big hits) are not drawn, by tier
## (Full 0 = all; Minimal draws none: a huge value).
const TIER_NUMBER_MIN: Array[float] = [0.0, REDUCED_NUMBER_MIN, REDUCED_NUMBER_MIN, 1.0e12]  # TUNING (not in GDD) mobile
## Whether the big-hit numbers are drawn at all, by tier (Minimal: none).
const TIER_BIG_NUMBERS: Array[bool] = [true, true, true, false]  # TUNING (not in GDD) mobile
## Animation bursts (AnimBursts: bolt hits, evolution flashes) drawn at most, newest
## first, by tier (AnimData.BURST_CAPACITY = all).
const TIER_ANIM_BURSTS: Array[int] = [AnimData.BURST_CAPACITY, AnimData.BURST_CAPACITY, 24, 12]  # TUNING (not in GDD) mobile

## --- The adaptive quality controller (AdaptiveQuality) ---------------------------------

## Highest adaptive level (= the last tier index).
const ADAPT_MAX_TIER: int = 3  # TUNING (not in GDD) mobile
## Rolling window (s, real time) whose median frame interval is judged.
const ADAPT_WINDOW_S: float = 2.0  # TUNING (not in GDD) mobile
## Real seconds between two evaluations of the window.
const ADAPT_EVAL_S: float = 0.5  # TUNING (not in GDD) mobile
## Ring-buffer size of the frame samples (>= 2 s at 60 fps, with room).
const ADAPT_SAMPLES: int = 160  # TUNING (not in GDD) mobile
## Fewest samples in the window before it is judged (a just-resumed run waits).
const ADAPT_MIN_FRAMES: int = 20  # TUNING (not in GDD) mobile
## Median frame interval (ms) above which the tier steps down one: slower than
## ~24 fps. iOS Low Power Mode caps the page at 30 fps (33.3 ms), which stays under it.
const ADAPT_DOWN_MS: float = 42.0  # TUNING (not in GDD) mobile
## Median frame interval (ms) under which, held for the recovery wait, the tier
## steps back up one (a 30 fps cap, 33.3 ms, counts as recovered).
const ADAPT_UP_MS: float = 36.0  # TUNING (not in GDD) mobile
## Recovery wait (s, real time) before a step back up.
const ADAPT_RECOVER_S: float = 8.0  # TUNING (not in GDD) mobile
## Longest recovery wait (s) after repeated undone step ups.
const ADAPT_RECOVER_MAX_S: float = 64.0  # TUNING (not in GDD) mobile
## A step down within this many seconds (real time) after a step up doubles the wait.
const ADAPT_BOUNCE_S: float = 6.0  # TUNING (not in GDD) mobile
## A frame interval longer than this (ms) is a pause, a load or a trip to another app,
## not the steady frame rate: it is left out of the window.
const ADAPT_HITCH_MS: float = 250.0  # TUNING (not in GDD) mobile
