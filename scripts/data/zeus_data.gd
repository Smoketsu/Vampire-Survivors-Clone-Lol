## ZeusData — immutable design data for ZEUS, KING OF THE GODS, the boss of
## Mount Olympus, the Pantheon Trial (Act IV, Stage 11; GDD §15.0 "Mount
## Olympus (Act IV phase 2)" and "Zeus, King of the Gods"; owner-approved
## proposal docs/act4/PROPOSAL.md: "Zeus (stage boss): lightning storms, the
## thunderbolt beam, and in phase 3 he takes his true colossal form").
## BossZeus (scripts/enemies/pantheon/boss_zeus.gd, loaded by name for the boss
## id "zeus") reads it. Three phases by his HP:
##   * The Thunderer (100% to phase2_hp): he walks at the necromancer and
##     strikes in reach; every storm_cooldown s he raises his bolt (storm_cast
##     s) and calls a LIGHTNING STORM: storm_count bolts on marked circles around
##     the necromancer through the Wrath of the Gods' own strike entry
##     (DivineWrath.strike("lightning", ...): the same telegraph, the same
##     chains to bronze); every beam_cooldown s the THUNDERBOLT BEAM: a lane
##     toward the necromancer telegraphed beam_telegraph s, then a white beam
##     for beam_time s that hits everything in it once.
##   * The Storm Throne (phase2_hp to phase3_hp): storms come faster and
##     bigger, the beam splits into beam_fan_p2 lanes beam_fan_angle apart.
##   * The True Form (below phase3_hp): he stands colossus_time s while he
##     grows into his COLOSSAL FORM (body x colossus_size, the colossus sprite),
##     then walks slower and hits harder, rains bolts on the shortest cooldown,
##     and adds the THUNDER STOMP: a circle of stomp_radius px around him
##     (stomp_telegraph s), then a shock that hurts and throws out what is in it.
## Also here: the gods of the Pantheon Trial share his HP (GOD_HP_SHARE, the
## owner-approved "each about a third of a normal stage boss's HP"), read by
## the god kinds' rows in OlympusEnemyData. The GDD gives no numbers:
## everything is TUNING (not in GDD) unless marked as the owner-approved
## proposal.
class_name ZeusData
extends RefCounted

## Zeus's arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "zeus" through OlympusStage.BOSS, so --boss=zeus and the Codex find him).
const ARRIVAL := {
	"id": "zeus",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left; owner-approved proposal "3:00 Zeus")
	"display_name": "Zeus, King of the Gods",  # Owner-approved proposal
	"short_name": "Zeus",
	"arrive_banner": "Zeus descends from the summit in a crack of thunder!",  # TUNING (not in GDD)
	"defeat_banner": "Zeus falls, and the storm goes quiet! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "The King of the Gods has fallen. Survive until the countdown ends.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["storm", "thunderbolt", "colossus", "stomp"]

## Zeus's base max HP (x the boss HP multiplier and the stage's HP multiplier:
## 26,100 on Olympus). Kestrel 17,000, the Motherboard 20,000, Deus Ex Machina
## 16,000: Act IV is a step harder, and the trial's gods take a share of it.
const MAX_HP: float = 18000.0  # TUNING (not in GDD)
## Share (0..1) of MAX_HP each god of the Pantheon Trial has (Ares, Artemis,
## Poseidon), with the boss's HP scaling (OlympusEnemyData rows, their kits).
const GOD_HP_SHARE: float = 0.33  # Owner-approved proposal: "each of the first three gods has about a third of a normal stage boss's HP"

## Zeus's design row.
const BOSS := {
	"display_name": "Zeus, King of the Gods",
	"max_hp": MAX_HP,
	"move_speed": 50.0,  # TUNING (not in GDD) px/s; a stately walk
	"damage": 14.0,  # TUNING (not in GDD) a blow of his fist in reach
	"attack_interval": 1.2,  # TUNING (not in GDD) s
	"attack_range": 10.0,  # TUNING (not in GDD) px
	"radius": 20.0,  # TUNING (not in GDD) px (x colossus_size in his true form)
	"armor": 0.2,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 9.0,  # TUNING (not in GDD) shoves warriors aside
	"faction": PantheonEnemyData.FACTION,
	"reward_xp": 600,  # TUNING (not in GDD) above Kestrel's 540
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.6,  # TUNING (not in GDD) s he stands after a special
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 1.6,  # TUNING (not in GDD)
	# Phases (HP shares).
	"phase2_hp": 0.66,  # TUNING (not in GDD) the Storm Throne below this
	"phase3_hp": 0.33,  # TUNING (not in GDD) the True Form below this
	"phase2_banner": "Zeus takes the Storm Throne: the bolts fall faster!",  # TUNING (not in GDD)
	"phase3_banner": "ZEUS TAKES HIS TRUE FORM: a colossus of storm and marble!",  # TUNING (not in GDD) owner-approved proposal "his true colossal form"
	# Lightning storms (owner-approved "lightning storms"), through
	# DivineWrath.strike("lightning"): storm_count bolts, the first near the
	# necromancer, the others around him (and the storm still favours bronze).
	"first_storm": 2.5,  # TUNING (not in GDD) s after arrival
	"storm_cast": 0.7,  # TUNING (not in GDD) s he stands with the bolt raised before the circles appear
	"storm_cooldown": 8.0,  # TUNING (not in GDD) s, the Thunderer
	"storm_cooldown_p2": 5.5,  # TUNING (not in GDD) s, the Storm Throne
	"storm_cooldown_p3": 3.8,  # TUNING (not in GDD) s, the True Form's rain
	"storm_count": 5,  # TUNING (not in GDD) bolts per storm, the Thunderer
	"storm_count_p2": 7,  # TUNING (not in GDD)
	"storm_count_p3": 6,  # TUNING (not in GDD)
	"storm_telegraph": 1.2,  # Owner-approved proposal: the wrath's "1.2 s warning"
	"storm_radius": 48.0,  # TUNING (not in GDD) px each circle (the wrath's 44)
	"storm_near": 110.0,  # TUNING (not in GDD) px: the first bolt lands within this of the necromancer
	"storm_scatter": 260.0,  # TUNING (not in GDD) px: the others within this
	# The thunderbolt beam (owner-approved "the thunderbolt beam").
	"first_beam": 6.0,  # TUNING (not in GDD) s after arrival
	"beam_cooldown": 9.0,  # TUNING (not in GDD) s
	"beam_cooldown_p2": 7.0,  # TUNING (not in GDD) s
	"beam_telegraph": 1.1,  # TUNING (not in GDD) s the lane shows before the beam
	"beam_length": 540.0,  # TUNING (not in GDD) px (cut short by nothing: a god's bolt)
	"beam_width": 34.0,  # TUNING (not in GDD) px
	"beam_width_p3": 52.0,  # TUNING (not in GDD) px in his true form
	"beam_time": 0.45,  # TUNING (not in GDD) s the beam burns (each body hit once)
	"beam_damage_player": 18.0,  # TUNING (not in GDD) before the time scaling
	"beam_damage_summon": 26.0,  # TUNING (not in GDD) before the time scaling
	"beam_fan_p2": 3,  # TUNING (not in GDD) lanes from the Storm Throne on
	"beam_fan_angle": 0.38,  # TUNING (not in GDD) rad between two lanes
	# The True Form (owner-approved "in phase 3 he takes his true colossal form").
	"colossus_time": 2.0,  # TUNING (not in GDD) s he stands growing (a window for the army)
	"colossus_size": 1.55,  # TUNING (not in GDD) x his body radius
	"colossus_speed": 40.0,  # TUNING (not in GDD) px/s, heavier
	"colossus_damage": 22.0,  # TUNING (not in GDD) per blow
	"colossus_mass": 16.0,  # TUNING (not in GDD)
	# The Thunder Stomp (True Form only).
	"stomp_cooldown": 6.0,  # TUNING (not in GDD) s
	"stomp_range": 150.0,  # TUNING (not in GDD) px; stomps when the necromancer or stomp_min_summons summons stand this close
	"stomp_min_summons": 3,  # TUNING (not in GDD)
	"stomp_telegraph": 1.0,  # TUNING (not in GDD) s
	"stomp_radius": 130.0,  # TUNING (not in GDD) px
	"stomp_damage_player": 16.0,  # TUNING (not in GDD) before the time scaling
	"stomp_damage_summon": 24.0,  # TUNING (not in GDD) before the time scaling
	"stomp_push": 50.0,  # TUNING (not in GDD) px summons are thrown out
}
