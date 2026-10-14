## PlayerAbilityData — designer-tunable numbers for the necromancer's two
## manual abilities (GDD §3.1 / §5.5: Shift = dash, Space = ultimate, "cooldown
## shown on HUD"; open question 10, resolved in GDD §15.0):
##   Grave Step  — the dash (GraveStep, scripts/player/grave_step.gd): a short
##                 shadow step with a moment of invulnerability. Available
##                 from the first run; the Ossuary sells a second charge
##                 (Twin Shadow) and a shorter cooldown (Restless Shade)
##                 through MetaModifiers ("dash_charges" / "dash_cooldown").
##   Dread Rally — the ultimate (DreadRally, scripts/player/dread_rally.gd): a
##                 soul meter filled by kills; when full, Space calls the army
##                 to the necromancer, heals it, buffs its damage and attack
##                 speed for a while and knocks nearby enemies back.
## The GDD gives no numbers for either ability, so everything here is TUNING.
## Data only, no logic.
class_name PlayerAbilityData
extends RefCounted

# --- Grave Step (dash) --------------------------------------------------------------

## Length of one Grave Step in px (shortened by obstacles in the way:
## Arena.clear_length, the end is always a free point).
const DASH_DISTANCE: float = 110.0  # TUNING (not in GDD) owner brief
## Duration of the step in seconds (the necromancer travels DASH_DISTANCE /
## DASH_DURATION = ~733 px/s; movement input is ignored meanwhile).
const DASH_DURATION: float = 0.15  # TUNING (not in GDD) owner brief
## Invulnerability in seconds from the start of the step (hits during it are
## ignored and counted as dash_hits_avoided).
const DASH_IFRAMES: float = 0.2  # TUNING (not in GDD) owner brief
## Seconds to recharge one charge (charges recharge one at a time). The
## Restless Shade upgrade (meta "dash_cooldown") shortens it by its %.
const DASH_COOLDOWN: float = 5.0  # TUNING (not in GDD) owner brief
## Charges with no upgrades (Twin Shadow, meta "dash_charges", adds to it).
const DASH_CHARGES: int = 1  # TUNING (not in GDD) owner brief
## Shortest cooldown in seconds any combination of bonuses may reach.
const DASH_MIN_COOLDOWN: float = 1.0  # TUNING (not in GDD)
## A step shorter than this (px, obstacle right ahead) is not taken and keeps
## its charge.
const DASH_MIN_LENGTH: float = 12.0  # TUNING (not in GDD)
## Seconds between two shadow afterimages left along the step (cosmetic).
const TRAIL_INTERVAL: float = 0.025  # TUNING (not in GDD)
## Seconds an afterimage takes to fade out (cosmetic).
const TRAIL_LIFE: float = 0.35  # TUNING (not in GDD)
## Opacity (0..1) of a fresh afterimage (cosmetic).
const TRAIL_ALPHA: float = 0.55  # TUNING (not in GDD)
## Radius (px) of the departure puff (EffectManager.ring, anim
## "grave_step_trail"; cosmetic).
const TRAIL_PUFF_RADIUS: float = 18.0  # TUNING (not in GDD)
## Screen shake request (px) when stepping (cosmetic).
const DASH_SHAKE: float = 1.5  # TUNING (not in GDD)

# --- Dread Rally (ultimate) ---------------------------------------------------------

## Soul points that fill the meter. Measured with the autotest (Graveyard,
## seed 1, --mortal): between 6:00 and 12:00 the army bot kills ~205 enemies
## per minute and the naive bot ~165, so 240 points take ~70 s (army) to
## ~90 s (naive) at mid-game kill rates, slower early on.
const KILLS_TO_FILL: float = 240.0  # TUNING (not in GDD) owner brief: full in ~60-90 s mid-game
## Soul points per regular kill.
const POINTS_PER_KILL: float = 1.0  # TUNING (not in GDD)
## Soul points per elite kill (gold-ringed enemies; Crimson March structures count as elites).
const POINTS_PER_ELITE: float = 8.0  # TUNING (not in GDD)
## Soul points for slaying the stage boss.
const POINTS_PER_BOSS: float = 60.0  # TUNING (not in GDD)
## False: kills made while the rally buff runs do not charge the meter (no
## back-to-back rallies in a big fight).
const CHARGE_DURING_BUFF: bool = false  # TUNING (not in GDD)
## Seconds the army gets +RALLY_DAMAGE_BONUS damage and +RALLY_ATTACK_SPEED_BONUS
## attack speed (HordeDirector.compute_stats, its own category).
const RALLY_DURATION: float = 8.0  # TUNING (not in GDD) owner brief
## Damage bonus of every summon while the rally runs (+40%).
const RALLY_DAMAGE_BONUS: float = 0.4  # TUNING (not in GDD) owner brief
## Attack-speed bonus of every summon while the rally runs (+40%).
const RALLY_ATTACK_SPEED_BONUS: float = 0.4  # TUNING (not in GDD) owner brief
## Fraction of its max HP every summon heals when the rally starts
## (CombatResolver.heal_unit).
const RALLY_HEAL_FRACTION: float = 0.3  # TUNING (not in GDD) owner brief
## True: the rally also raises the WHOLE army: every missing unit of every
## owned class comes back at once (HordeDirector.raise_all_missing(), the same
## path as the "Call of the Grave" card), at full HP and with the rally buff.
## Owner decision (Oct 2026 playtest): "the ultimate should res your whole army".
const RALLY_RAISES_ARMY: bool = true  # TUNING (not in GDD) owner decision
## Seconds of the surge: summons outside their formation band drop their
## target and return to the necromancer, and every summon moves faster.
const SURGE_DURATION: float = 1.5  # TUNING (not in GDD)
## Move-speed bonus of every summon during the surge (+120%; no teleport).
const SURGE_SPEED_BONUS: float = 1.2  # TUNING (not in GDD)
## Radius (px) around the necromancer in which enemies are knocked back.
const KNOCKBACK_RADIUS: float = 120.0  # TUNING (not in GDD) owner brief
## Outward impulse (px/s, divided by the enemy's mass, so bosses resist) of
## the knockback; MetaData.REVIVE_PUSH_FORCE is 420 for comparison.
const KNOCKBACK_FORCE: float = 460.0  # TUNING (not in GDD)
## Screen shake request (px) of the rally burst (Juice caps it at MAX_SHAKE_PX).
const RALLY_SHAKE: float = 9.0  # TUNING (not in GDD)
## Duration (s) of the drawn burst rings when the "dread_rally" animation art
## is missing (with art, AnimData's duration is used).
const RALLY_RING_TIME: float = 0.6  # TUNING (not in GDD)

# --- Autotest bots ------------------------------------------------------------------

## The bots dash when this many enemies are within BOT_DASH_RADIUS px ...
const BOT_DASH_CROWD: int = 3  # TUNING (not in GDD)
## ... of the necromancer (px), ...
const BOT_DASH_RADIUS: float = 45.0  # TUNING (not in GDD)
## ... or when he was hit within the last BOT_DASH_HIT_WINDOW s while
## HordeDirector.player_in_danger is set, or when a boss telegraph pushes him.
const BOT_DASH_HIT_WINDOW: float = 0.6  # TUNING (not in GDD)
## Boss / stage danger push (Autotest autopilot units) above which the bots
## dash out of a telegraph.
const BOT_DASH_DANGER_PUSH: float = 0.5  # TUNING (not in GDD)
## Directions the bots try for a step (evenly spread; the safest wins).
const BOT_DASH_DIRECTIONS: int = 12  # TUNING (not in GDD)
## Radius (px) around a candidate step's end in which enemies count against it.
const BOT_DASH_LANDING_RADIUS: float = 70.0  # TUNING (not in GDD)
## The bots rally when the meter is full and the living army's average HP is
## below this fraction of max, or ...
const BOT_RALLY_ARMY_HP: float = 0.6  # TUNING (not in GDD)
## ... fewer than this fraction of the army's capacity is alive, or the
## player is in danger, or the stage boss is alive.
const BOT_RALLY_ARMY_ALIVE: float = 0.7  # TUNING (not in GDD)
