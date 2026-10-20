## AssemblyEnemyData — immutable design data for the Electronic Empire kinds that
## join on the Assembly Halls (Stage 8) (Act III; GDD §15.0 "Act III foundation
## (phase 1)" and "The Assembly Halls (Act III phase 2)"; owner-approved
## proposal "Necropathy: Act III Proposal (The Electronic Empire)"):
##   arc_engineer       — Arc Engineer (support, a CYBORG, medium range): fires
##                        arc bolts through EmpireShots (Line of Fire), repairs
##                        the machines around it and briefly JAMS the summons
##                        near it (2 s, the one suppression path
##                        HordeDirector.add_suppression()); a priority target
##                        like the High Confessor (ArcEngineerKit).
##   juggernaut         — Juggernaut (heavy elite, a MACHINE, short range): an
##                        armoured flamethrower walker with flat armour like the
##                        Sanctified Sentinel (CombatResolver's flat-armour stat);
##                        a telegraphed flame cone (JuggernautKit).
##   fabricator         — a Fabricator (a structure, a MACHINE): builds a new
##                        enemy every few seconds until it is smashed; each one
##                        destroyed thins the waves for the rest of the run
##                        (FabricatorKit, AssemblyDirector).
##   beta_build         — THE BETA BUILD, the stage miniboss (9:00 left): an
##                        unfinished mech that keeps patching itself from every
##                        fabricator still standing (BetaBuildKit).
##   motherboard_turret — a Motherboard Turret (a structure, a MACHINE): the
##                        boss's own small turret, built mid-fight by the
##                        Motherboard (BossMotherboard); fixed, it fires bolts
##                        through EmpireShots (MotherboardTurretKit). Not the
##                        Citadel's Sentry Turret.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.empire_def() looks these rows up after
## EmpireEnemyData. Rows have every key of an EmpireEnemyData.ENEMIES row (same
## meaning; "kit" ids load scripts/enemies/empire/<kit>_kit.gd; "body" is
## "machine" or "cyborg") plus each kit's own numbers, documented on the kit.
## Every walking kind keeps advancing on the necromancer (the shared AI); the
## structures are the one exception (they never move).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name AssemblyEnemyData
extends RefCounted

## Kind id of the Arc Engineer (timeline, autotest report).
const ARC_ENGINEER: String = "arc_engineer"
## Kind id of the Juggernaut.
const JUGGERNAUT: String = "juggernaut"
## Kind id of a Fabricator (AssemblyDirector places them).
const FABRICATOR: String = "fabricator"
## Kind id of the Beta Build miniboss.
const BETA_BUILD: String = "beta_build"
## Kind id of the Motherboard's own turret (BossMotherboard builds them).
const MB_TURRET: String = "motherboard_turret"

## Kind id -> design row.
const ENEMIES := {
	# Support: a cyborg engineer in a chrome harness with a welding visor, an arc
	# emitter on one arm and a toolkit drum on the back. Medium range.
	"arc_engineer": {
		"display_name": "Arc Engineer",
		"max_hp": 64.0,  # TUNING (not in GDD) a support (High Confessor 90, Line Trooper 28)
		"move_speed": 42.0,  # TUNING (not in GDD) px/s; keeps pace behind the troopers
		"damage": 3.0,  # TUNING (not in GDD) an arc bolt, before the time scaling (its real worth is the repairs and the jam)
		"attack_interval": 3.2,  # TUNING (not in GDD) s between arc bolts
		"attack_range": 240.0,  # Owner-approved proposal: "Medium" range
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 5,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 430.0,  # TUNING (not in GDD) px/s arc bolt
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # Owner-approved proposal: "Priority target, like the High Confessor"
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.CYBORG,  # Owner-approved proposal: "Cyborg"
		"kit": "arc_engineer",
		"shot_style": "arc_bolt",  # EmpireRulesData.SHOT_STYLES (the Assembly Halls' block)
		# Repairs (ArcEngineerKit): the most damaged machines near it regain HP.
		"repair_first": 3.0,  # TUNING (not in GDD) s after it spawns (plus the think-slot stagger)
		"repair_interval": 5.0,  # TUNING (not in GDD) s between two repairs (4 s with 6% repaired 50k HP in an army run, seed 1)
		"repair_radius": 170.0,  # TUNING (not in GDD) px
		"repair_targets": 3,  # TUNING (not in GDD) machines repaired at once (the most damaged)
		"repair_share": 0.04,  # TUNING (not in GDD) share of the machine's max HP restored (first pass 0.06)
		"repair_min": 10.0,  # TUNING (not in GDD) HP restored at least (cheap drones heal fully)
		# Jam (ArcEngineerKit): a telegraphed static field on the nearest summons.
		"jam_first": 5.0,  # TUNING (not in GDD) s after it spawns
		"jam_cooldown": 11.0,  # TUNING (not in GDD) s between two jams
		"jam_trigger": 220.0,  # TUNING (not in GDD) px; a summon this close starts it
		"jam_radius": 80.0,  # TUNING (not in GDD) px of the static field
		"jam_duration": 2.0,  # Owner-approved proposal: "briefly jams nearby summons (2 s)"
		"jam_telegraph": 0.8,  # TUNING (not in GDD) s the field arms before it jams
		"jam_damage_mult": 0.6,  # TUNING (not in GDD) jammed summons hit at 60% (the suppression path's damage_mult)
		"jam_hold": 0.5,  # TUNING (not in GDD) s it stands still casting the jam
	},
	# Heavy elite: an armoured chrome walker on two thick hydraulic legs with a
	# flamethrower arm and fuel tanks on its back. Flat armour like the Sentinel.
	"juggernaut": {
		"display_name": "Juggernaut",
		"max_hp": 520.0,  # TUNING (not in GDD) a heavy elite (Spotter 110, Sentinel 120 + flat armour)
		"move_speed": 32.0,  # TUNING (not in GDD) px/s; a slow walker
		"damage": 10.0,  # TUNING (not in GDD) its steel fist in contact
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px edge to edge
		"radius": 18.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 22,  # TUNING (not in GDD) an elite's XP
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD)
		"mass": 9.0,  # TUNING (not in GDD) shoves warriors aside
		"slow_resist": 0.3,  # TUNING (not in GDD) like the Sentinel
		"flat_armor": 6.0,  # Owner-approved proposal: "flat armour, like the Sanctified Sentinel" (its 6)
		"always_elite": true,  # Owner-approved proposal: tier "Heavy elite"
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,  # Owner-approved proposal: "Machine"
		"kit": "juggernaut",
		# Flamethrower (JuggernautKit): a telegraphed cone, then a burning stream.
		"flame_first": 3.0,  # TUNING (not in GDD) s after it spawns
		"flame_cooldown": 8.0,  # TUNING (not in GDD) s between two streams (first pass 6.5 s: its flames were the top killer of the army bot's archers)
		"flame_trigger": 110.0,  # TUNING (not in GDD) px edge to edge; flames a target this close
		"flame_range": 130.0,  # TUNING (not in GDD) px cone reach from its centre
		"flame_half_angle": 0.42,  # TUNING (not in GDD) rad each side (~48 degrees in all)
		"flame_telegraph": 0.75,  # TUNING (not in GDD) s the cone is shown before the fuel lights
		"flame_duration": 1.4,  # TUNING (not in GDD) s the stream burns
		"flame_tick": 0.2,  # TUNING (not in GDD) s between two burn ticks
		"flame_damage_summon": 2.2,  # TUNING (not in GDD) per tick, before time scaling (7 ticks: ~15; first pass 3.0)
		"flame_damage_player": 3.0,  # TUNING (not in GDD) per tick, before time scaling
		"flame_recover": 0.5,  # TUNING (not in GDD) s it stands after the stream
	},
	# Structures (AssemblyDirector places and tracks them).
	# A fabricator: a squat chrome build bay with a robotic arm, a glowing amber
	# build frame and warning lights. Builds a new enemy every few seconds.
	"fabricator": {
		"display_name": "Fabricator",
		"max_hp": 620.0,  # TUNING (not in GDD) ~850 HP at 3:00 after time scaling (a bell buoy has 380)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 24.0,  # TUNING (not in GDD) px
		"armor": 0.25,  # TUNING (not in GDD) armoured bay
		"xp": 0,  # Its reward is AssemblyDirector's XP burst.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) archers and catapults go for it
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"kit": "fabricator",
		# Build cycle (FabricatorKit): one enemy every build_interval s while the
		# necromancer is within build_radius and the trickle's soft cap has room.
		"build_first": 2.5,  # TUNING (not in GDD) s after it is placed
		"build_interval": 6.0,  # Owner-approved proposal: "builds a new enemy every few seconds"
		"build_radius": 900.0,  # TUNING (not in GDD) px; it idles while the necromancer is farther
		"build_kinds": ["scout_drone"],  # TUNING (not in GDD) what it builds off the Assembly Halls (a timeline event names its own)
	},
	# The miniboss: an unfinished mech, half its plating missing, cables hanging
	# out, one arm a welding rig and one a rivet cannon, a test-pattern screen.
	"beta_build": {
		"display_name": "The Beta Build",  # Owner-approved proposal
		"max_hp": 2100.0,  # TUNING (not in GDD) x the time / stage HP scaling (~x2.6 at 11:00); the Harbourmaster has 1,700
		"move_speed": 30.0,  # TUNING (not in GDD) px/s; heavy
		"damage": 14.0,  # TUNING (not in GDD) its fist in reach
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 28.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is BetaBuildKit's XP burst.
		"behavior": "melee",
		"projectile_speed": 520.0,  # TUNING (not in GDD) px/s rivet shots
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers focus it like a boss
		"mass": 14.0,  # TUNING (not in GDD) shoves warriors aside
		"slow_resist": 0.5,  # TUNING (not in GDD) like the bosses
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"kit": "beta_build",
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"shot_style": "rivet",  # EmpireRulesData.SHOT_STYLES (the Assembly Halls' block)
		"reward_xp": 180,  # TUNING (not in GDD) XP burst on death
		"reward_crystals": 10,  # TUNING (not in GDD)
		# Patching (owner-approved proposal: "keeps patching itself from any
		# fabricator still standing"): every patch_tick s it regains patch_rate
		# of its max HP for every standing fabricator (at most patch_max of them).
		"patch_tick": 0.5,  # TUNING (not in GDD) s
		"patch_rate": 0.006,  # TUNING (not in GDD) share of its max HP per second per fabricator (~13 HP/s each)
		"patch_max": 4,  # TUNING (not in GDD) fabricators counted at most
		"patch_beam_reach": 900.0,  # TUNING (not in GDD) px; beams to fabricators this close are drawn (the patch works at any distance)
		# Pacing (like the Harbourmaster).
		"first_special": 2.5,  # TUNING (not in GDD) s after arrival
		"attack_gap": 3.4,  # TUNING (not in GDD) s between the end of one special and the next
		"recover_time": 0.7,  # TUNING (not in GDD) s it stands after a special
		"advance_range": 260.0,  # TUNING (not in GDD) px; farther than this it strides faster
		"advance_speed_mult": 2.0,  # TUNING (not in GDD) 30 -> 60 px/s
		# Weld swipe: a sector toward the necromancer, then the welding arm sweeps it.
		"swipe_cooldown": 7.0,  # TUNING (not in GDD) s
		"swipe_range": 150.0,  # TUNING (not in GDD) px; used on a necromancer this close
		"swipe_radius": 100.0,  # TUNING (not in GDD) px
		"swipe_half_angle": 1.0,  # TUNING (not in GDD) rad
		"swipe_telegraph": 0.9,  # TUNING (not in GDD) s
		"swipe_damage_summon": 12.0,  # TUNING (not in GDD) before time scaling
		"swipe_damage_player": 16.0,  # TUNING (not in GDD) before time scaling
		"swipe_knockback": 44.0,  # TUNING (not in GDD) px summons are thrown out
		# Rivet spray: a fan of rivets through EmpireShots (Line of Fire).
		"rivets_cooldown": 8.0,  # TUNING (not in GDD) s
		"rivets_range": 420.0,  # TUNING (not in GDD) px; used on a necromancer this close (and the shots' reach)
		"rivets_count": 5,  # TUNING (not in GDD) rivets in the fan
		"rivets_spread": 0.16,  # TUNING (not in GDD) rad between two rivets
		"rivets_telegraph": 0.7,  # TUNING (not in GDD) s the cannon charges
		"rivets_damage": 6.0,  # TUNING (not in GDD) per rivet, before time scaling
	},
	# The Motherboard's own turret (BossMotherboard builds them): a small chrome
	# turret on a tripod with one amber lens and a short twin barrel.
	"motherboard_turret": {
		"display_name": "Motherboard Turret",
		"max_hp": 380.0,  # TUNING (not in GDD) a quick siege target (x the time scaling when built)
		"move_speed": 0.0,
		"damage": 6.0,  # TUNING (not in GDD) per bolt, before time scaling
		"attack_interval": 1.8,  # TUNING (not in GDD) s between bolts
		"attack_range": 430.0,  # TUNING (not in GDD) px; "Long", like the Empire's guns
		"radius": 13.0,  # TUNING (not in GDD) px
		"armor": 0.3,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 540.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) archers shoot the guns down
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"kit": "motherboard_turret",
		"shot_style": "turret_bolt",  # EmpireRulesData.SHOT_STYLES (the Assembly Halls' block)
		"first_shot": 1.2,  # TUNING (not in GDD) s after it is built
	},
}
