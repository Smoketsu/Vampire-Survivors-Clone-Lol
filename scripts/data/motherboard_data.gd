## MotherboardData — immutable design data for THE MOTHERBOARD, the boss of the
## Assembly Halls (Act III, Stage 8; GDD §15.0 "The Assembly Halls (Act III
## phase 2)"; owner-approved proposal: "the factory's construction titan, mother
## of every soldier on the line, with two crane arms. It grabs your summons and
## hurls them, drops press-stamps on telegraphed squares, magnet-pulls the army
## out of the ring, and builds turrets mid-fight"). BossMotherboard
## (scripts/enemies/empire/boss_motherboard.gd, loaded by name for the boss id
## "motherboard") reads it. One fight in three parts:
##   * Online (from its arrival): Crane Grab (each arm seizes a summon and hurls
##     it at the necromancer's spot, a telegraphed landing circle) and
##     Press-Stamp (telegraphed squares around the necromancer and the army).
##   * Full Load (below load_hp): adds the Magnet Pull (the army is dragged out
##     of the Bone Ring toward the titan) and Build Turrets (Motherboard Turrets,
##     AssemblyEnemyData, rise around it).
##   * Overclock (below overclock_hp): faster specials, more stamps.
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist, attack_gap, first_special,
## recover_time, advance_range, advance_speed_mult) and the specials' own
## numbers below. The GDD gives no numbers: everything is TUNING (not in GDD).
class_name MotherboardData
extends RefCounted

## The Motherboard's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "motherboard", so --boss=motherboard and the Codex find it).
const ARRIVAL := {
	"id": "motherboard",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "The Motherboard",  # Owner-approved proposal
	"short_name": "Motherboard",
	"arrive_banner": "THE MOTHERBOARD BOOTS UP: every machine in the halls answers to it!",  # TUNING (not in GDD)
	"defeat_banner": "The Motherboard crashes! The line falls silent... Hold out until the end.",  # TUNING (not in GDD)
	"dead_objective": "The Motherboard is down. Survive until the countdown ends.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["grab", "stamp", "magnet", "build"]
## Specials it uses from its arrival.
const ONLINE_SPECIALS := ["grab", "stamp"]
## Specials it uses below load_hp (Full Load) and Overclock.
const LOADED_SPECIALS := ["grab", "stamp", "magnet", "build"]
## Damage source tags (CombatResolver stats; the stamp is an area hit for Unholy Resilience).
const STAMP_SOURCE: String = "motherboard_stamp"
## Damage source tag of a hurled summon landing (on the necromancer and on the summons it lands among).
const HURL_SOURCE: String = "motherboard_hurl"

## The Motherboard's design row.
const BOSS := {
	"display_name": "The Motherboard",
	"max_hp": 20000.0,  # TUNING (not in GDD) x the stage HP multiplier (27,000 in the Assembly Halls); Vhal'Neth 20,000 x 1.2. Act III balance: 24,000 -> 20,000 (the army bot left it alive in 3 of 8 runs at 32,400 with the stage's HP x1.35; Kestrel 17,000, Deus Ex Machina 16,000)
	"move_speed": 24.0,  # TUNING (not in GDD) px/s; a titan on treads
	"damage": 16.0,  # TUNING (not in GDD) its chassis in reach
	"attack_interval": 1.4,  # TUNING (not in GDD) s
	"attack_range": 10.0,  # TUNING (not in GDD) px
	"radius": 36.0,  # TUNING (not in GDD) px
	"armor": 0.2,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 30.0,  # TUNING (not in GDD) nothing shoves it
	"body": "machine",  # Steel has no soul: a machine (EmpireEnemyData.MACHINE).
	"reward_xp": 560,  # TUNING (not in GDD) a little more than Merrow's 520
	"reward_crystals": 24,  # TUNING (not in GDD)
	"slow_resist": 0.6,  # TUNING (not in GDD) heavier than the other bosses (0.5)
	# Pacing.
	"first_special": 2.5,  # TUNING (not in GDD) s after arrival
	"attack_gap": 2.8,  # TUNING (not in GDD) s between the end of one special and the next
	"recover_time": 0.7,  # TUNING (not in GDD) s it stands after a special
	"advance_range": 300.0,  # TUNING (not in GDD) px; farther than this it rolls faster
	"advance_speed_mult": 2.4,  # TUNING (not in GDD) 24 -> 58 px/s (the necromancer runs at 110)
	# Phases.
	"load_hp": 0.6,  # TUNING (not in GDD) HP share below which it goes to Full Load
	"overclock_hp": 0.25,  # TUNING (not in GDD) HP share below which it overclocks
	"overclock_gap_mult": 0.65,  # TUNING (not in GDD) shorter gaps between specials
	"load_banner": "FULL LOAD: the Motherboard magnetises the floor and builds its guns!",  # TUNING (not in GDD)
	"overclock_banner": "OVERCLOCK: the Motherboard runs past every safety limit!",  # TUNING (not in GDD)
	# Crane Grab: each crane arm reaches for a summon, lifts it and hurls it at
	# the necromancer's spot (a telegraphed landing circle).
	"grab_weight": 1.2,  # TUNING (not in GDD) choice weight
	"grab_cooldown": 9.0,  # TUNING (not in GDD) s
	"grab_reach": 300.0,  # TUNING (not in GDD) px from its centre to a summon it can seize
	"grab_arms": 2,  # Owner-approved proposal: "two crane arms"
	"grab_telegraph": 0.9,  # TUNING (not in GDD) s the claws aim (a line to each victim)
	"grab_slack": 40.0,  # TUNING (not in GDD) px a victim may walk off its aim and still be caught
	"grab_lift": 0.5,  # TUNING (not in GDD) s a seized summon hangs from the claw
	"hurl_flight": 0.7,  # TUNING (not in GDD) s it flies (its landing circle shows this long)
	"hurl_radius": 40.0,  # TUNING (not in GDD) px landing circle
	"hurl_damage_player": 14.0,  # TUNING (not in GDD) before time scaling, if he is still in the circle
	"hurl_damage_summon": 8.0,  # TUNING (not in GDD) before time scaling, to each summon it lands among
	"hurl_self_share": 0.3,  # TUNING (not in GDD) share of its max HP the hurled summon loses on landing
	"hurl_max_throw": 340.0,  # TUNING (not in GDD) px; it never throws farther (aimed short of a far necromancer)
	# Press-Stamp: telegraphed squares around the necromancer and the army.
	"stamp_weight": 1.0,  # TUNING (not in GDD)
	"stamp_cooldown": 7.0,  # TUNING (not in GDD) s
	"stamp_range": 520.0,  # TUNING (not in GDD) px; used on a necromancer this close
	"stamp_count": 3,  # TUNING (not in GDD) squares (one on the necromancer)
	"stamp_count_overclock": 5,  # TUNING (not in GDD) squares while overclocked
	"stamp_size": 72.0,  # TUNING (not in GDD) px square side
	"stamp_scatter": 150.0,  # TUNING (not in GDD) px around the necromancer the other squares land within (on the army when it is there)
	"stamp_telegraph": 1.3,  # TUNING (not in GDD) s
	"stamp_damage_player": 20.0,  # TUNING (not in GDD) before time scaling
	"stamp_damage_summon": 22.0,  # TUNING (not in GDD) before time scaling
	# Magnet Pull (Full Load): the army is dragged toward the titan.
	"magnet_weight": 0.9,  # TUNING (not in GDD)
	"magnet_cooldown": 15.0,  # TUNING (not in GDD) s
	"magnet_telegraph": 1.0,  # TUNING (not in GDD) s its coils charge
	"magnet_duration": 1.6,  # TUNING (not in GDD) s the pull lasts
	"magnet_radius": 460.0,  # TUNING (not in GDD) px
	"magnet_speed": 150.0,  # TUNING (not in GDD) px/s summons are dragged at
	"magnet_stop": 34.0,  # TUNING (not in GDD) px off its body a dragged summon stops
	# Build Turrets (Full Load): Motherboard Turrets rise around it.
	"build_weight": 0.8,  # TUNING (not in GDD)
	"build_cooldown": 20.0,  # TUNING (not in GDD) s
	"build_telegraph": 1.6,  # TUNING (not in GDD) s the construction frames stand
	"build_count": 2,  # TUNING (not in GDD) turrets per build
	"build_max": 4,  # TUNING (not in GDD) turrets standing at most
	"build_distance": 150.0,  # TUNING (not in GDD) px from its centre
}
