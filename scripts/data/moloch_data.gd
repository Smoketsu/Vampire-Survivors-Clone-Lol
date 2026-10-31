## MolochData — immutable design data for MOLOCH, THE FURNACE KING, the boss of
## the Burning Gate (Act VI, Stage 16; GDD §15.0 "Moloch, the Furnace King (Act
## VI)"; owner-approved proposal docs/act6/PROPOSAL.md: "a colossal bull-headed
## demon with a furnace for a belly. He swallows summons (they come back
## burning, as his for 6 s), vents fire waves, and cracks the arena into
## pits"). BossMoloch (scripts/enemies/inferno/boss_moloch.gd, loaded by name for
## the boss id "moloch") reads it. Three phases by his HP:
##   * The Furnace King (100% to phase2_hp): he walks at the necromancer and
##     strikes in reach. THE SWALLOW every swallow_cooldown s: his belly door
##     opens and he inhales for swallow_windup s (a cone of swallow_reach px in
##     front of him, swallow_arc rad each side); then up to swallow_max summons
##     still in the cone are dragged into the furnace and come back BURNING, as
##     his, for swallow_time s through the one charm path (HordeDirector
##     .charm() with opts ignore_cap, tint, name, source: Temptation's hostile
##     body, tinted furnace orange, steps out of his belly; breaking it frees the
##     summon; his death breaks every swallow). THE FIRE WAVE every wave_cooldown
##     s: wave_count lanes toward the necromancer glow wave_telegraph s, then a
##     wall of fire runs down each at wave_speed px/s for wave_length px,
##     hitting every necromancer and summon it passes once. THE CRACK every
##     crack_cooldown s: he stamps (crack_windup s) and the ground splits into
##     crack_count Hell Pits around the necromancer (HellPits.open_pit(), the one
##     pit path; tag "moloch"; the pits' own 1.5 s glow; crack_life s).
##   * The Furnace Opens (phase2_hp to phase3_hp): swallows hold more, the
##     waves fan into wave_count_p2 lanes, the cracks split more ground.
##   * The Molten King (below phase3_hp): his body runs molten (faster, harder
##     blows), three-lane waves come every wave_cooldown_p3 s, and every crack
##     also opens a pit under him that follows his steps (molten footprints:
##     a pit every footprint_every s where he walks).
## Killing him drops a big XP burst and the boss chest; slaying him unlocks the
## Brimstone spell and Furnace Heart (UnlockData, boss "moloch"). The GDD gives
## no numbers: everything is TUNING (not in GDD) unless marked as the
## owner-approved proposal.
class_name MolochData
extends RefCounted

## Moloch's arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "moloch" through BurningGateStage.BOSS, so --boss=moloch and the Codex find him).
const ARRIVAL := {
	"id": "moloch",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Moloch, the Furnace King",  # Owner-approved proposal
	"short_name": "Moloch",
	"arrive_banner": "Moloch, the Furnace King, rises from the burning gate!",  # TUNING (not in GDD)
	"defeat_banner": "Moloch's furnace gutters out! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Moloch is dead. Survive the Last Judgment... you cannot.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["swallow", "fire_wave", "crack", "molten"]

## Damage tag of his fire waves.
const WAVE_SOURCE: String = "moloch_wave"
## Stats / charm source tag of his swallow (charm_by_moloch_swallow).
const SWALLOW_SOURCE: String = "moloch_swallow"
## HellPits stats tag of his cracks (pits_opened_moloch).
const CRACK_TAG: String = "moloch"
## Colour multiplied over a swallowed summon's body while it burns as his.
const SWALLOW_TINT := Color(1.0, 0.55, 0.25)  # TUNING (not in GDD) furnace orange

## Moloch's base max HP (x the boss HP multiplier and the stage's HP multiplier:
## 14,875 on the Burning Gate). Kage 11,000 (17,050 on the Province): lower,
## because every swallow turns his attackers into his guards for 6 s.
const MAX_HP: float = 8500.0  # TUNING (not in GDD) first pass 10500: the army bot's seed-7 run left him 5186 HP at 0:00

## Moloch's design row.
const BOSS := {
	"display_name": "Moloch, the Furnace King",
	"max_hp": MAX_HP,
	"move_speed": 44.0,  # TUNING (not in GDD) px/s; colossal and slow
	"damage": 15.0,  # TUNING (not in GDD) a blow of his fist in reach
	"attack_interval": 1.4,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 30.0,  # TUNING (not in GDD) px; colossal
	"armor": 0.2,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 14.0,  # TUNING (not in GDD) shoves warriors aside
	"faction": InfernoEnemyData.FACTION,
	"reward_xp": 600,  # TUNING (not in GDD) a step above Kage's 580
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.6,  # TUNING (not in GDD) s he stands after a special
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 1.7,  # TUNING (not in GDD)
	# Phases (HP shares).
	"phase2_hp": 0.66,  # TUNING (not in GDD) the Furnace Opens below this
	"phase3_hp": 0.33,  # TUNING (not in GDD) the Molten King below this
	"phase2_banner": "Moloch's furnace roars open: it hungers for more!",  # TUNING (not in GDD)
	"phase3_banner": "MOLOCH RUNS MOLTEN: the ground burns where he walks!",  # TUNING (not in GDD)
	# The swallow (owner-approved "he swallows summons; they come back burning,
	# as his for 6 s"), through HordeDirector.charm().
	"first_swallow": 5.0,  # TUNING (not in GDD) s after arrival
	"swallow_cooldown": 13.0,  # TUNING (not in GDD) s; first pass 11
	"swallow_cooldown_p2": 11.0,  # TUNING (not in GDD) s; first pass 9
	"swallow_windup": 1.1,  # TUNING (not in GDD) s of the inhale (the cone shows)
	"swallow_reach": 130.0,  # TUNING (not in GDD) px from his centre
	"swallow_arc": 0.75,  # TUNING (not in GDD) rad each side of his facing
	"swallow_max": 2,  # TUNING (not in GDD) summons per swallow, the Furnace King
	"swallow_max_p2": 3,  # TUNING (not in GDD) from the Furnace Opens
	"swallow_time": 6.0,  # Owner-approved proposal: "as his for 6 s"
	"swallow_trigger": 3,  # TUNING (not in GDD) summons in the cone before he bothers (or the necromancer within reach)
	# The fire waves (owner-approved "vents fire waves").
	"first_wave": 8.0,  # TUNING (not in GDD) s after arrival
	"wave_cooldown": 9.0,  # TUNING (not in GDD) s
	"wave_cooldown_p3": 6.5,  # TUNING (not in GDD) s, the Molten King
	"wave_count": 1,  # TUNING (not in GDD) lanes, the Furnace King
	"wave_count_p2": 3,  # TUNING (not in GDD) lanes from the Furnace Opens
	"wave_spread": 0.42,  # TUNING (not in GDD) rad between two lanes
	"wave_telegraph": 1.0,  # TUNING (not in GDD) s the lanes glow
	"wave_length": 560.0,  # TUNING (not in GDD) px a wave runs
	"wave_width": 54.0,  # TUNING (not in GDD) px
	"wave_speed": 420.0,  # TUNING (not in GDD) px/s
	"wave_damage_player": 10.0,  # TUNING (not in GDD) before the time scaling; first pass 12
	"wave_damage_summon": 9.0,  # TUNING (not in GDD) before the time scaling; first pass 12
	# The crack (owner-approved "cracks the arena into pits"), through HellPits.open_pit().
	"first_crack": 13.0,  # TUNING (not in GDD) s after arrival
	"crack_cooldown": 12.0,  # TUNING (not in GDD) s
	"crack_windup": 0.8,  # TUNING (not in GDD) s he stands with a hoof raised
	"crack_count": 3,  # TUNING (not in GDD) pits, the Furnace King
	"crack_count_p2": 5,  # TUNING (not in GDD) from the Furnace Opens
	"crack_radius_min": 30.0,  # TUNING (not in GDD) px
	"crack_radius_max": 48.0,  # TUNING (not in GDD) px
	"crack_near": 60.0,  # TUNING (not in GDD) px: the nearest pit's least distance from the necromancer
	"crack_far": 260.0,  # TUNING (not in GDD) px: the farthest
	"crack_life": 9.0,  # TUNING (not in GDD) s each pit burns
	# The Molten King.
	"molten_speed": 54.0,  # TUNING (not in GDD) px/s
	"molten_damage": 18.0,  # TUNING (not in GDD) per blow
	"footprint_every": 2.0,  # TUNING (not in GDD) s between two molten footprints; first pass 1.2
	"footprint_radius": 26.0,  # TUNING (not in GDD) px
	"footprint_life": 4.0,  # TUNING (not in GDD) s
}
