## StanceData — designer-tunable data for the ARMY STANCES (owner-approved
## feature, GDD §15.0): the player picks one of four stances for the whole
## undead army. A stance is only a set of OVERRIDES on numbers the horde AI
## already uses; no unit gets new behaviour code:
##   * the formation post shape (HordeDirector._calculate_formation_anchors()
##     and StanceFormations): "escort" is exactly the pre-stance formation,
##   * the engagement / chase distance (UnitData.ENGAGE_RADIUS today) and the
##     soft recall (UnitData.SOFT_RECALL today), both still scaled by Bound
##     Souls in HordeDirector.compute_stats(),
##   * the formation pull (w_formation multiplier).
## The hard recall (UnitData.HARD_RECALL) never changes: it is the safety net.
## Escort's numbers are IDENTICAL to the pre-stance game, so balance and the
## bot baselines do not move while Escort is held.
## Optional flavour bonuses exist as data but are OFF (BONUSES_ENABLED false):
## a later balance pass can switch them on; they already flow through the
## single paths (compute_stats for attack speed / push, CombatResolver for
## damage taken).
## Spearhead is unlocked in the Ossuary (MetaData "spearhead_doctrine", read
## through MetaModifiers.unlocks()). The stance resets to Escort every run.
## No logic here (ArmyStance owns the state, StanceFormations the shapes).
class_name StanceData
extends RefCounted

## Stance ids in key / HUD order (keys 1-4, right-stick up / right / down / left).
const ORDER := ["escort", "onslaught", "spearhead", "bone_ring"]
## Stance the army holds at the start of every run (and on Restart).
const DEFAULT_ID: String = "escort"
## Input action of each stance, same order as ORDER (project.godot; the
## keyboard key is rebindable in Settings like the other actions).
const ACTIONS := ["stance_escort", "stance_onslaught", "stance_spearhead", "stance_bone_ring"]

## Stance definitions.
##   display_name    — UI name (HUD banner word is its upper-case form).
##   icon            — icon kind (StanceGlyphs; icon art icons/<icon>.png wins).
##   color           — accent colour (HUD, banner, ground outline).
##   description     — one-line pause-menu description.
##   shape           — formation shape: "escort" (today's formation),
##                     "onslaught", "spearhead" or "ring" (StanceFormations).
##   engage_radius   — px; chase / engagement leash (UnitData.ENGAGE_RADIUS
##                     is 220 today), times Bound Souls.
##   soft_recall     — px; beyond it a unit drops its target and RETURNs
##                     (UnitData.SOFT_RECALL is 320 today), times Bound Souls.
##   formation_pull  — multiplier on every class's w_formation (1 = today).
##   jitter          — multiplier on UnitData.FORMATION_JITTER_ANGLE (lower =
##                     a crisper shape).
##   unlock_stat     — MetaData.STATS key that must be owned (>= 1) to use the
##                     stance ("" = available from the first run).
##   bonus           — flavour bonus applied only while BONUSES_ENABLED:
##                     attack_speed (+fraction army attack speed),
##                     front_push (+fraction block mass and bash knockback of
##                     the "front" classes, the wedge tip),
##                     damage_taken_reduction (fraction off army damage taken).
const STANCES := {
	"escort": {"display_name": "Escort", "icon": "stance_escort", "color": Palette.NECRO_GREEN,
		"description": "The default: blockers face the threat, the rest guard you in bands.",
		"shape": "escort",
		"engage_radius": UnitData.ENGAGE_RADIUS,  # GDD §24 (unchanged: Escort is today's game)
		"soft_recall": UnitData.SOFT_RECALL,  # GDD §24 (unchanged)
		"formation_pull": 1.0,  # TUNING (not in GDD) 1 = today's pull
		"jitter": 1.0,  # TUNING (not in GDD) 1 = today's jitter
		"unlock_stat": "",
		"bonus": {}},
	"onslaught": {"display_name": "Onslaught", "icon": "stance_onslaught", "color": Palette.FLAME,
		"description": "Loose: the army surges at the nearest enemy groups, priests trail the fight. Exposes you.",
		"shape": "onslaught",
		"engage_radius": 440.0,  # TUNING (not in GDD) owner proposal: twice today's chase distance
		"soft_recall": 540.0,  # TUNING (not in GDD) raised to match: engage + today's 100 px margin
		"formation_pull": 1.0 / 3.0,  # TUNING (not in GDD) owner proposal: pull cut to a third
		"jitter": 1.0,  # TUNING (not in GDD)
		"unlock_stat": "",
		"bonus": {"attack_speed": 0.10}},  # TUNING (not in GDD) owner proposal +10% (off while BONUSES_ENABLED is false)
	"spearhead": {"display_name": "Spearhead", "icon": "stance_spearhead", "color": Palette.VIOLET,
		"description": "A wedge pointed where you move: blockers at the tip, skirmishers on the flanks. The rear is open.",
		"shape": "spearhead",
		"engage_radius": 150.0,  # TUNING (not in GDD) owner proposal
		"soft_recall": UnitData.SOFT_RECALL,  # GDD §24 (unchanged)
		"formation_pull": 1.0,  # TUNING (not in GDD)
		"jitter": 0.25,  # TUNING (not in GDD) crisp wedge
		"unlock_stat": "stance_spearhead",
		"bonus": {"front_push": 0.30}},  # TUNING (not in GDD) owner proposal +30% push on the tip (off while BONUSES_ENABLED is false)
	"bone_ring": {"display_name": "Bone Ring", "icon": "stance_bone_ring", "color": Palette.COLD_BLUE,
		"description": "A closed circle of blockers around you, ranged and priests inside. Safest, fewest kills.",
		"shape": "ring",
		"engage_radius": 110.0,  # TUNING (not in GDD) owner proposal: only fight what reaches the ring
		"soft_recall": UnitData.SOFT_RECALL,  # GDD §24 (unchanged)
		"formation_pull": 1.0,  # TUNING (not in GDD)
		"jitter": 0.15,  # TUNING (not in GDD) evenly spaced blockers
		"unlock_stat": "",
		"bonus": {"damage_taken_reduction": 0.10}},  # TUNING (not in GDD) owner proposal -10% army damage taken (off while BONUSES_ENABLED is false)
}

## Master switch of the flavour bonuses above (owner decision: no stat
## bonuses at first; a later balance pass may switch them on).
const BONUSES_ENABLED: bool = false  # TUNING (not in GDD) owner decision: off

# --- Switching ---------------------------------------------------------------------

## Game seconds after a stance change before the next change is accepted.
const SWITCH_LOCKOUT: float = 1.5  # TUNING (not in GDD) owner proposal
## Right stick: an axis pushed past this (0..1) toward a stance's binding is
## a flick (ArmyStance reads the axes itself; the stance actions' deadzone
## in project.godot is the same value).
const STICK_FLICK: float = 0.6  # TUNING (not in GDD)
## Right stick: every stance action must fall back under this strength
## (0..1) before the next flick counts (re-arm, one flick = one switch).
const STICK_REARM: float = 0.25  # TUNING (not in GDD)

# --- Feedback ----------------------------------------------------------------------

## Seconds the one-word stance banner stays fully visible.
const BANNER_TIME: float = 1.0  # TUNING (not in GDD)
## Seconds the banner then takes to fade out.
const BANNER_FADE: float = 0.5  # TUNING (not in GDD)
## Seconds the (longer) locked-stance banner stays fully visible.
const LOCKED_BANNER_TIME: float = 2.5  # TUNING (not in GDD)
## Seconds the faint ground outline of the new shape stays around the necromancer.
const OUTLINE_TIME: float = 1.0  # TUNING (not in GDD) owner proposal
## Peak alpha (0..1) of the ground outline.
const OUTLINE_ALPHA: float = 0.45  # TUNING (not in GDD)
## Sound effect id played on a stance change (SoundData).
const SOUND_ID: String = "stance_command"
## Banner shown (once per run) when a locked stance's key is pressed.
const LOCKED_TEXT: String = "Locked: unlock Spearhead in the Ossuary"

# --- Shapes (StanceFormations; px from the necromancer) ----------------------------

## Onslaught: enemies within this radius of the necromancer are grouped.
const ONSLAUGHT_SCAN: float = 440.0  # TUNING (not in GDD) = Onslaught's chase distance
## Onslaught: angular sectors used to group enemies around the necromancer.
const ONSLAUGHT_SECTORS: int = 8  # TUNING (not in GDD)
## Onslaught: at most this many enemy groups get a share of the army.
const ONSLAUGHT_GROUPS: int = 3  # TUNING (not in GDD)
## Onslaught: fighters' posts stop this far short of their group's centre.
const ONSLAUGHT_STANDOFF: float = 30.0  # TUNING (not in GDD)
## Onslaught: nearest post distance of a fighter.
const ONSLAUGHT_POST_MIN: float = 90.0  # TUNING (not in GDD)
## Onslaught: farthest post distance of a fighter (inside the 440 px leash).
const ONSLAUGHT_POST_MAX: float = 320.0  # TUNING (not in GDD)
## Onslaught: ranged fighters post this much closer than the melee ones.
const ONSLAUGHT_RANGED_BACK: float = 70.0  # TUNING (not in GDD)
## Onslaught: lateral spacing between fighters of one group.
const ONSLAUGHT_SPACING: float = 34.0  # TUNING (not in GDD)
## Onslaught: priests post at this fraction of the main group's post distance
## (between the necromancer and the fighting).
const ONSLAUGHT_PRIEST_FRACTION: float = 0.45  # TUNING (not in GDD)
## Onslaught: with no enemy in reach, every band is widened by this factor
## (a loose, spread-out escort).
const ONSLAUGHT_IDLE_SPREAD: float = 1.6  # TUNING (not in GDD)

## Spearhead: how fast (per second, 0..) the wedge turns toward a new
## movement direction, so jittery steering does not spin the wedge.
const SPEAR_TURN_RATE: float = 3.0  # TUNING (not in GDD)
## Spearhead: distance of the wedge tip ahead of the necromancer.
const SPEAR_TIP: float = 115.0  # TUNING (not in GDD)
## Spearhead: each step down an arm of the wedge goes this far back ...
const SPEAR_STEP_BACK: float = 22.0  # TUNING (not in GDD)
## ... and this far to the side (34 px between neighbours on an arm).
const SPEAR_STEP_SIDE: float = 26.0  # TUNING (not in GDD)
## Spearhead: blockers per wedge layer (tip + 4 per arm); more start a second
## wedge behind the first.
const SPEAR_LAYER_SIZE: int = 9  # TUNING (not in GDD)
## Spearhead: each extra wedge layer sits this far behind the previous one.
const SPEAR_LAYER_BACK: float = 36.0  # TUNING (not in GDD)
## Spearhead: lateral distance of the flank posts (melee "mid" classes).
const SPEAR_FLANK_SIDE: float = 80.0  # TUNING (not in GDD)
## Spearhead: the first flank post sits this far ahead of the necromancer ...
const SPEAR_FLANK_FORWARD: float = 30.0  # TUNING (not in GDD)
## ... and each further one on that flank this far behind the previous one.
const SPEAR_FLANK_STEP: float = 32.0  # TUNING (not in GDD)
## Spearhead: ranged units and priests stand in this band around the necromancer.
const SPEAR_INNER_MIN: float = 30.0  # TUNING (not in GDD)
## Outer edge of that inner band.
const SPEAR_INNER_MAX: float = 60.0  # TUNING (not in GDD)

## Bone Ring: smallest ring radius (owner proposal: 60-90 px out).
const RING_MIN: float = 60.0  # TUNING (not in GDD) owner proposal
## Bone Ring: largest ring radius.
const RING_MAX: float = 90.0  # TUNING (not in GDD) owner proposal
## Bone Ring: ring radius grows by this much per unit inside the ring (room
## for the ranged and priests), from RING_MIN up to RING_MAX.
const RING_PER_INNER: float = 3.0  # TUNING (not in GDD)
## Bone Ring: ring units sit within +/- this many px of the ring radius.
const RING_DEPTH: float = 6.0  # TUNING (not in GDD)
## Bone Ring: inner units keep at least this far inside the ring.
const RING_INNER_GAP: float = 30.0  # TUNING (not in GDD)
## Bone Ring: inner units never closer to the necromancer than this.
const RING_INNER_MIN: float = 24.0  # TUNING (not in GDD)

# --- Autotest stance bot (StanceBot) -----------------------------------------------

## Game seconds between two stance decisions of the bot.
const BOT_INTERVAL: float = 1.0  # TUNING (not in GDD)
## Bone Ring while the stage boss is alive within this many px.
const BOT_BOSS_CLOSE: float = 260.0  # TUNING (not in GDD)
## "Near" radius (px) for the bot's enemy count.
const BOT_NEAR_RADIUS: float = 220.0  # TUNING (not in GDD)
## Onslaught only while at most this many enemies are near.
const BOT_FEW_ENEMIES: int = 6  # TUNING (not in GDD)
## "Screen nearly clear": at most this many enemies within BOT_SCREEN_RADIUS.
const BOT_CLEAR_COUNT: int = 10  # TUNING (not in GDD)
## Radius (px) counted as "the screen" for that check.
const BOT_SCREEN_RADIUS: float = 480.0  # TUNING (not in GDD)
## Onslaught when a stage structure (outpost, generator, cart) is this close.
const BOT_STRUCTURE_RADIUS: float = 420.0  # TUNING (not in GDD) = the autopilot's objective reach
## Spearhead (when owned) toward a chest or power-up drop this close.
const BOT_LOOT_RADIUS: float = 300.0  # TUNING (not in GDD) = the autopilot's drop reach
## Policies that keep Escort for the whole run (their long-standing baseline;
## --stance=ID still forces a stance for them).
const BOT_ESCORT_POLICIES := ["naive", "pact"]
## Game seconds between two army-spread samples (summary stat).
const SPREAD_SAMPLE: float = 0.25  # TUNING (not in GDD)


## Definition of stance `id` (the default stance for an unknown id).
static func def(id: String) -> Dictionary:
	return STANCES.get(id, STANCES[DEFAULT_ID])


## Index of stance `id` in ORDER (-1 if unknown).
static func index_of(id: String) -> int:
	return ORDER.find(id)
