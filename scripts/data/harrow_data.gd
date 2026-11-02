## HarrowData — immutable design data for GENERAL VANCE HARROW, "THE HAMMER",
## the boss of Fort Kessler (Act VIII, Stage 23; GDD §15.0 "General Vance
## Harrow, the Hammer (Act VIII)"; owner-approved proposal docs/act8/PROPOSAL.md:
## "phase 1, he commands from a command vehicle and calls carpet-bombing lines
## across the arena; phase 2, a tank column and his own power armour; phase 3,
## Broken Arrow: he orders a strike on his own position, a 30 s countdown on
## screen. Kill him in time and it is called off; fail and the blast hits
## everything on screen (his army included), leaving the necromancer badly
## hurt and most of the army gone"). BossHarrow
## (scripts/enemies/city/boss_harrow.gd, loaded by name for the boss id
## "harrow") reads it. Three phases by his HP:
##   * COMMAND (100% to phase2_hp): he rides his COMMAND VEHICLE (his body is
##     the vehicle: radius 30 px, drawn as the armoured car), keeping
##     standoff_min .. standoff_max px from the necromancer (he never charges:
##     he commands); every carpet_every s he calls a CARPET-BOMBING LINE: a
##     street lane through the necromancer's street (CityBlocks.lane(), the
##     axis alternating; a straight line off a blocks stage), carpet_shells
##     landing circles carpet_spacing px apart starting carpet_offset px behind
##     him, each landing carpet_walk s after the last after a carpet_warn s
##     telegraph (CityShells, the one shell path; both sides hurt, never
##     civilians; source CARPET_SOURCE, ranged); every squad_every s a rifle
##     squad of squad_count comes in on the spawn ring.
##   * THE HAMMER (phase2_hp to phase3_hp): he climbs out in his POWER ARMOUR
##     (its front cuts armour_front of a hit from inside +-60 degrees of his
##     facing: Armour.front_mult() through city_armour_front() / city_facing(),
##     the act's one front test; Armour-Piercing Bones pierces it like any
##     front), walks at the necromancer and every slam_every s SLAMS his hammer
##     where his target stands (a landing circle of slam_radius px for
##     slam_windup s, then slam_damage to every summon and necromancer in it);
##     a TANK COLUMN rolls in every column_every s (column_count tanks along one
##     street from the spawn ring, the Convoy's own vehicles, at most
##     column_cap of his standing); the carpet lines keep coming, slower.
##   * BROKEN ARROW (below phase3_hp): he orders a strike on his own position.
##     A broken_arrow_time s COUNTDOWN shows as HUD TEXT only (the HUD
##     objective, FortKesslerDirector.objective_override(); a banner every 10
##     s; never a screen effect). He fights on (the Hammer's kit, the carpet
##     lines every carpet_every_p3 s). KILL HIM IN TIME and the strike is called
##     off (the run stat fort_kessler_broken_arrow: the achievement Broken
##     Arrow). FAIL and THE STRIKE lands (BossHarrow._strike(), the ONE
##     documented path): every necromancer is left at strike_hp_left of his max
##     HP (damage_player() with his i-frames cleared first: Grave Step does not
##     dodge it; never lethal by itself: no damage when he is already below
##     it), every summon within the view of a necromancer takes
##     strike_summon_share of its max HP (damage_unit(): most of the army gone),
##     and every enemy there (his army included; never a civilian, a boss or a
##     structure) takes strike_enemy_share of its max HP. HARROW HIMSELF (own
##     decision): his power armour takes the blast: he survives it, loses
##     strike_self_share of the HP he has left and his armour front for good
##     (armour_front_broken), and fights on to the end; there is no second
##     strike.
## Killing him drops a big XP burst and the boss chest; slaying him unlocks the
## Bone Mines spell and Tripwire (UnlockData, boss "harrow"). The GDD gives no
## numbers: everything is TUNING (not in GDD) unless marked as the
## owner-approved proposal.
class_name HarrowData
extends RefCounted

## General Harrow's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "harrow" through FortKesslerStage.BOSS, so --boss=harrow and
## the Codex find him).
const ARRIVAL := {
	"id": "harrow",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "General Vance Harrow, the Hammer",  # Owner-approved proposal
	"short_name": "General Harrow",
	"arrive_banner": "General Harrow takes command of the line!",  # TUNING (not in GDD)
	"defeat_banner": "The Hammer falls! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Fort Kessler is yours. Survive Martial Law... you cannot.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["carpet", "squad", "dismount", "slam", "column", "broken_arrow", "strike"]

## Damage tag of his carpet-bombing lines (ranged: Kevlar Bones).
const CARPET_SOURCE: String = "carpet_bomb"
## Damage tag of his hammer's slam.
const SLAM_SOURCE: String = "harrow_slam"
## Damage tag of Broken Arrow's strike.
const STRIKE_SOURCE: String = "broken_arrow"
## Sprite key of his art in the command vehicle (phase 1).
const SPRITE_VEHICLE: String = "bosses/harrow_command"
## Sprite key of his art in his power armour (phases 2 and 3).
const SPRITE: String = "bosses/harrow"
## Run stat set to 1 when Broken Arrow was called off (he fell in time): the
## achievement Broken Arrow (MetaProgress counts the runs).
const STOPPED_STAT: String = "fort_kessler_broken_arrow"

## His base max HP (x the boss HP multiplier and the stage's HP multiplier).
const MAX_HP: float = 15000.0  # TUNING (not in GDD) Vargr 14,000; his three phases and the countdown need time

## General Harrow's design row.
const BOSS := {
	"display_name": "General Vance Harrow, the Hammer",
	"max_hp": MAX_HP,
	"move_speed": 52.0,  # TUNING (not in GDD) px/s: the command vehicle
	"damage": 12.0,  # TUNING (not in GDD) a blow in reach (the power armour)
	"attack_interval": 1.3,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 30.0,  # TUNING (not in GDD) px (under CityBlockData.MAX_BODY_RADIUS 36; the sprite is drawn larger)
	"armor": 0.2,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 14.0,  # TUNING (not in GDD)
	"faction": CityEnemyData.FACTION,
	"reward_xp": 650,  # TUNING (not in GDD) Vargr 600
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.5,  # TUNING (not in GDD) s he stands after a slam
	"advance_range": 460.0,  # TUNING (not in GDD) px; farther than this he moves faster
	"advance_speed_mult": 1.7,  # TUNING (not in GDD)
	# Phases (HP shares).
	"phase2_hp": 0.6,  # TUNING (not in GDD) the Hammer below this
	"phase3_hp": 0.3,  # TUNING (not in GDD) Broken Arrow below this
	"command_banner": "General Harrow commands from his armoured car: carpet bombing!",  # TUNING (not in GDD)
	"phase2_banner": "THE HAMMER: Harrow climbs out in power armour, and the tanks roll in!",  # TUNING (not in GDD)
	"phase3_banner": "BROKEN ARROW: Harrow calls a strike on his own position! Kill him before it lands!",  # TUNING (not in GDD)
	"called_off_banner": "Broken Arrow called off: the Hammer is dead.",  # TUNING (not in GDD)
	"strike_banner": "BROKEN ARROW: the strike lands on everything!",  # TUNING (not in GDD)
	"countdown_banner": "Broken Arrow: %d s",  # TUNING (not in GDD) every 10 s of the countdown
	# Command: the command vehicle, the carpet lines, the rifle squads.
	"standoff_min": 260.0,  # TUNING (not in GDD) px: nearer than this the vehicle stops
	"standoff_max": 380.0,  # TUNING (not in GDD) px: farther than this it rolls in
	"first_carpet": 3.0,  # TUNING (not in GDD) s after he arrives
	"carpet_every": 7.0,  # TUNING (not in GDD) s, Command
	"carpet_every_p2": 11.0,  # TUNING (not in GDD) s, the Hammer
	"carpet_every_p3": 8.0,  # TUNING (not in GDD) s, Broken Arrow
	"carpet_shells": 9,  # TUNING (not in GDD) circles in a line (Martial Law's 8)
	"carpet_spacing": 70.0,  # TUNING (not in GDD) px
	"carpet_walk": 0.2,  # TUNING (not in GDD) s between two circles landing
	"carpet_warn": 1.3,  # TUNING (not in GDD) s the first circle shows
	"carpet_radius": 44.0,  # TUNING (not in GDD) px
	"carpet_damage": 9.0,  # TUNING (not in GDD) before the time scaling (both sides)
	"carpet_offset": 320.0,  # TUNING (not in GDD) px behind the necromancer the line starts
	"squad_every": 20.0,  # TUNING (not in GDD) s
	"squad_count": 4,  # Owner-approved proposal: riflemen in squads of 4
	# The Hammer: the power armour, the slam, the tank column.
	"armour_front": 0.5,  # TUNING (not in GDD) his power armour's front (phases 2 and 3)
	"hammer_speed": 58.0,  # TUNING (not in GDD) px/s on foot in the armour
	"first_slam": 2.0,  # TUNING (not in GDD) s after he climbs out
	"slam_every": 6.0,  # TUNING (not in GDD) s
	"slam_reach": 220.0,  # TUNING (not in GDD) px: he slams only this near his target
	"slam_windup": 1.0,  # TUNING (not in GDD) s the landing circle shows
	"slam_radius": 62.0,  # TUNING (not in GDD) px
	"slam_damage_player": 12.0,  # TUNING (not in GDD) before the time scaling
	"slam_damage_summon": 11.0,  # TUNING (not in GDD) before the time scaling (first pass 16: his slams killed 36 summons in the seed-7 army run)
	"slam_push": 30.0,  # TUNING (not in GDD) px the summons are thrown out
	"first_column": 1.0,  # TUNING (not in GDD) s after he climbs out
	"column_every": 24.0,  # TUNING (not in GDD) s
	"column_count": 2,  # TUNING (not in GDD) tanks a column
	"column_cap": 3,  # TUNING (not in GDD) most of his tanks standing at once
	"column_gap": 90.0,  # TUNING (not in GDD) px between two tanks of a column
	# Broken Arrow.
	"broken_arrow_time": 30.0,  # Owner-approved proposal: "a 30 s countdown on screen"
	"strike_hp_left": 0.25,  # TUNING (not in GDD) the lead's suggestion: the necromancer is left at this share of his max HP (never lethal)
	"strike_summon_share": 0.85,  # TUNING (not in GDD) of each summon's max HP: "most of the army gone"
	"strike_enemy_share": 1.5,  # TUNING (not in GDD) of each enemy's max HP: his army on screen dies with it
	"strike_self_share": 0.4,  # TUNING (not in GDD) own decision: of the HP he has left (his armour takes it)
	"strike_margin": 120.0,  # TUNING (not in GDD) px beyond the view's edge the strike reaches
}
