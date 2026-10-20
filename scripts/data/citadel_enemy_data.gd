## CitadelEnemyData — immutable design data for the Electronic Empire kinds that join
## on the Iron Citadel (Stage 9, the campaign finale) (Act III; GDD §15.0 "Act III
## foundation (phase 1)" and "The Iron Citadel (Act III phase 2)"; owner-approved
## proposal "Necropathy: Act III Proposal (The Electronic Empire)").
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.empire_def() looks these rows up after
## EmpireEnemyData. Rows have every key of an EmpireEnemyData.ENEMIES row (same
## meaning; "kit" ids load scripts/enemies/empire/<kit>_kit.gd; "body" is
## "machine" or "cyborg"). The Citadel's kinds:
##   valkyrie_duelist   — Valkyrie Duelist (elite, CYBORG, female, figure-redesign
##                        style): a melee duelist whose jet-assisted LUNGE drives
##                        through the Bone Ring at the necromancer with an arm
##                        blade; a blocker in the lane stops it (DuelistKit).
##   sentry_turret      — Sentry Turret (structure, MACHINE): a fixed gun
##                        emplacement, the one exception to "enemies always
##                        advance"; aimed bolts through EmpireShots, a Soul Ash
##                        bounty (SentryKit, CitadelDirector).
##   shield_generator   — Shield generator (structure, MACHINE): two hold each
##                        Shield Gate up (CitadelDirector); a Soul Ash bounty.
##   valkyrie_prime     — VALKYRIE 2.0, the stage's miniboss (CYBORG, female,
##                        figure-redesign style): jet dash, shield bash, blade
##                        storm (ValkyrieKit); one HUD miniboss bar, a chest.
##   deus_leg_plate     — an armour plate on one of Deus Ex Machina's four legs
##                        (structure, MACHINE; DeusPlateKit): breakable one by
##                        one, like Vhal'Neth's arms (BossDeusExMachina).
##   deus_shield_drone  — a shield drone of the Siege Core (MACHINE, flying;
##                        DeusDroneKit): while one orbits, the core is immune.
## Row keys beyond EmpireEnemyData's are each kit's own numbers (documented on
## the row). The GDD gives no numbers: everything is TUNING (not in GDD), except
## the owner-approved ones (tagged "Owner-approved proposal").
class_name CitadelEnemyData
extends RefCounted

## Kind id of the Valkyrie Duelist (timelines, the Codex, the hangar doors).
const DUELIST: String = "valkyrie_duelist"
## Kind id of the Sentry Turret (CitadelDirector emplacements).
const TURRET: String = "sentry_turret"
## Kind id of a Shield Gate's generator (CitadelDirector).
const GENERATOR: String = "shield_generator"
## Kind id of Valkyrie 2.0, the miniboss (CitadelDirector "valkyrie" event).
const VALKYRIE: String = "valkyrie_prime"
## Kind id of a Deus Ex Machina leg plate (BossDeusExMachina).
const PLATE: String = "deus_leg_plate"
## Kind id of a Siege Core shield drone (BossDeusExMachina).
const SHIELD_DRONE: String = "deus_shield_drone"

## Kind id -> design row.
const ENEMIES := {
	# Elite: a cyborg duellist in polished chrome armour over a signal-red bodysuit,
	# twin jet thrusters on her back, a long arm blade. She closes in, then LUNGES
	# straight through the ring at the necromancer; blockers stop her.
	"valkyrie_duelist": {
		"display_name": "Valkyrie Duelist",
		"max_hp": 95.0,  # TUNING (not in GDD) an elite (Spotter 110, Siren 120)
		"move_speed": 60.0,  # TUNING (not in GDD) px/s; walks a little faster than a trooper
		"damage": 7.0,  # TUNING (not in GDD) per arm-blade slash in melee, before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px edge to edge (a long blade)
		"radius": 11.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD) chrome plate
		"xp": 12,  # TUNING (not in GDD) an elite's XP
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 0.9,  # TUNING (not in GDD)
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1; a duellist that dives the necromancer is a priority
		"mass": 1.6,  # TUNING (not in GDD)
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.CYBORG,  # Owner-approved proposal: "Cyborg (female, figure-redesign style)"
		"kit": "duelist",
		"always_elite": true,  # Owner-approved proposal: tier Elite
		# The lunge (DuelistKit): jet-assisted, through the ring at the necromancer.
		"lunge_range_min": 90.0,  # TUNING (not in GDD) px; closer than this she simply fights
		"lunge_range_max": 300.0,  # TUNING (not in GDD) px; she lunges from about two rings out
		"lunge_length": 330.0,  # TUNING (not in GDD) px the jets carry her at most (obstacles cut it)
		"lunge_speed": 560.0,  # TUNING (not in GDD) px/s
		"lunge_telegraph": 0.55,  # TUNING (not in GDD) s the amber lane is shown first
		"lunge_cooldown": 6.5,  # TUNING (not in GDD) s between lunges
		"lunge_first": 2.0,  # TUNING (not in GDD) s after she arrives (plus the think-slot stagger)
		"lunge_width": 20.0,  # TUNING (not in GDD) px wide lane
		"lunge_damage": 11.0,  # TUNING (not in GDD) on the necromancer, before the time scaling
		"lunge_summon_damage": 6.0,  # TUNING (not in GDD) on each summon she slices through
		"lunge_block_mass": 3.0,  # TUNING (not in GDD) a summon with this block mass stops her (Warriors 3 and every heavier blocker: proposal "blockers stop the lunge")
		"lunge_stagger": 0.9,  # TUNING (not in GDD) s she stands, staggered, after a blocker stopped her
		"lunge_knockback": 26.0,  # TUNING (not in GDD) px a sliced (non-blocking) summon is shoved aside
	},
	# Structure: a squat chrome gun emplacement on a tripod base, one long barrel
	# and an amber sensor eye. Fixed in place (the one exception to "always
	# advance"); fires aimed bolts at the nearest of the necromancer and his dead.
	"sentry_turret": {
		"display_name": "Sentry Turret",
		"max_hp": 210.0,  # TUNING (not in GDD) x the time scaling: a structure to siege
		"move_speed": 0.0,  # Owner-approved proposal: "they never move"
		"damage": 5.0,  # TUNING (not in GDD) per bolt, before the time scaling (proposal: rifle shots 4-6)
		"attack_interval": 3.6,  # TUNING (not in GDD) s between two-bolt bursts (Act III balance: 2.6 -> 3.6, in step with the Line Troopers' slower fire: the first gate's turret was the third killer of the army bot's opening deaths)
		"attack_range": 460.0,  # Owner-approved proposal: "Long" (380-520 px)
		"radius": 15.0,  # TUNING (not in GDD) px
		"armor": 0.25,  # TUNING (not in GDD) armoured emplacement
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 600.0,  # TUNING (not in GDD) px/s bolt
		"undead_damage_mult": 0.8,  # TUNING (not in GDD)
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1; catapults and archers siege it
		"mass": 50.0,  # TUNING (not in GDD) bolted to the floor
		"slow_resist": 1.0,  # It never moves.
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"kit": "sentry",
		"is_structure": true,
		"construct": true,
		"shot_style": "bolt",
		"burst_rounds": 2,  # TUNING (not in GDD) bolts per burst
		"burst_gap": 0.16,  # TUNING (not in GDD) s between the two
		"burst_spread": 0.05,  # TUNING (not in GDD) rad
		"aim_time": 0.45,  # TUNING (not in GDD) s its sensor flares (a telegraph) before a burst
		"turn_rate": 2.4,  # TUNING (not in GDD) rad/s the barrel turns toward its target (drawing and aim)
		"first_shot": 1.6,  # TUNING (not in GDD) s after it is placed (plus the think-slot stagger)
		"bounty_ash": 3,  # TUNING (not in GDD) Soul Ash when destroyed (proposal: "each drops a Soul Ash bounty")
	},
	# Structure: a chrome pylon with a humming amber core, cables of light running
	# to the energy wall it holds up (two per Shield Gate).
	"shield_generator": {
		"display_name": "Shield Generator",
		"max_hp": 260.0,  # TUNING (not in GDD) x the time scaling
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 99.0,
		"attack_range": 0.0,
		"radius": 16.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 14,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; the army goes for the gate's generators
		"mass": 60.0,  # TUNING (not in GDD)
		"slow_resist": 1.0,
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"is_structure": true,
		"construct": true,
	},
	# Miniboss: VALKYRIE 2.0, the upgraded leader of the Valkyrie Duelists: taller,
	# heavier chrome armour, a big jet pack, a tower shield on one arm and the
	# arm blade on the other. Jet dash, shield bash, blade storm.
	"valkyrie_prime": {
		"display_name": "Valkyrie 2.0",
		"max_hp": 1050.0,  # TUNING (not in GDD) x the time scaling (about x5.8 at 12:30 on the Citadel); the Cathedral Guardian is 1,400 at 5:30
		"move_speed": 52.0,  # TUNING (not in GDD) px/s
		"damage": 12.0,  # TUNING (not in GDD) arm blade in melee, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 16.0,  # TUNING (not in GDD) px
		"radius": 24.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is ValkyrieKit's XP burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers focus it like a boss
		"mass": 12.0,  # TUNING (not in GDD) shoves warriors aside
		"slow_resist": 0.5,  # TUNING (not in GDD) like the bosses
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.CYBORG,
		"kit": "valkyrie",
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"reward_xp": 180,  # TUNING (not in GDD) XP burst on death (the Cathedral Guardian 160)
		"reward_crystals": 10,  # TUNING (not in GDD) crystals it is split into
		"reward_ash": 12,  # TUNING (not in GDD) Soul Ash bounty (objective_ash)
		# Pacing between specials.
		"first_special": 2.5,  # TUNING (not in GDD) s after arrival
		"attack_gap": 2.8,  # TUNING (not in GDD) s between the end of one special and the next
		"recover_time": 0.6,  # TUNING (not in GDD) s she stands after a special
		"advance_range": 280.0,  # TUNING (not in GDD) px; farther than this she strides faster (never left behind)
		"advance_speed_mult": 2.2,  # TUNING (not in GDD) speed factor while left behind
		# Jet dash: a telegraphed lane, then she rockets along it.
		"dash_range_min": 120.0,  # TUNING (not in GDD) px
		"dash_range_max": 420.0,  # TUNING (not in GDD) px
		"dash_length": 440.0,  # TUNING (not in GDD) px at most (obstacles cut it)
		"dash_speed": 760.0,  # TUNING (not in GDD) px/s
		"dash_telegraph": 0.8,  # TUNING (not in GDD) s
		"dash_width": 34.0,  # TUNING (not in GDD) px
		"dash_damage_player": 16.0,  # TUNING (not in GDD) before the time scaling
		"dash_damage_summon": 10.0,  # TUNING (not in GDD) before the time scaling
		"dash_knockback": 46.0,  # TUNING (not in GDD) px summons in the lane are thrown aside
		"dash_block_mass": 6.0,  # TUNING (not in GDD) only a heavy blocker (Spawn of the Deep 6, Abomination 8, Golem 10) stops her dash
		"dash_cooldown": 7.0,  # TUNING (not in GDD) s
		# Shield bash: a frontal cone in melee reach.
		"bash_range": 90.0,  # TUNING (not in GDD) px; she bashes when the necromancer or 3+ summons are this close
		"bash_reach": 78.0,  # TUNING (not in GDD) px cone length
		"bash_half_arc": 0.9,  # TUNING (not in GDD) rad each side
		"bash_telegraph": 0.5,  # TUNING (not in GDD) s
		"bash_damage_player": 13.0,  # TUNING (not in GDD) before the time scaling
		"bash_damage_summon": 12.0,  # TUNING (not in GDD) before the time scaling
		"bash_knockback": 70.0,  # TUNING (not in GDD) px
		"bash_cooldown": 5.0,  # TUNING (not in GDD) s
		# Blade storm: she spins with both blades out, hitting all around her.
		"storm_radius": 85.0,  # TUNING (not in GDD) px (first pass 105: it covered the whole Bone Ring)
		"storm_telegraph": 1.0,  # TUNING (not in GDD) s the ring is shown first
		"storm_time": 1.8,  # TUNING (not in GDD) s of spinning
		"storm_tick": 0.35,  # TUNING (not in GDD) s between two hits on each body inside
		"storm_damage_player": 4.0,  # TUNING (not in GDD) per tick, before the time scaling
		"storm_damage_summon": 3.0,  # TUNING (not in GDD) per tick, before the time scaling (first pass 7: 2,000 summon damage in a minute)
		"storm_move_mult": 0.45,  # TUNING (not in GDD) share of her speed she drifts at while spinning
		"storm_cooldown": 11.0,  # TUNING (not in GDD) s
	},
	# Structure: one armour plate bolted over a knee of Deus Ex Machina. It rides on
	# its leg (DeusPlateKit keeps it at the leg's offset) and carries the missile
	# pods of the salvo.
	"deus_leg_plate": {
		"display_name": "Leg Plate",
		"max_hp": 400.0,  # Overridden by BossDeusExMachina (a share of the boss's max HP).
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 99.0,
		"attack_range": 0.0,
		"radius": 15.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 0,
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) the army goes for the plates first
		"mass": 60.0,  # TUNING (not in GDD)
		"slow_resist": 1.0,
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"kit": "deus_plate",
		"is_structure": true,
		"construct": true,
	},
	# A small chrome shield drone with an amber emitter, tethered to the Siege Core
	# by a beam of light; while one orbits, the core is immune.
	"deus_shield_drone": {
		"display_name": "Shield Drone",
		"max_hp": 300.0,  # Overridden by BossDeusExMachina (a share of the boss's max HP).
		"move_speed": 0.0,  # It orbits the core (DeusDroneKit), it never walks.
		"damage": 0.0,
		"attack_interval": 99.0,
		"attack_range": 0.0,
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 0,
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 1.0,  # TUNING (not in GDD) shoot the drones down first
		"mass": 20.0,  # TUNING (not in GDD)
		"slow_resist": 1.0,
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"kit": "deus_drone",
		"is_structure": true,
		"construct": true,
		"phases": true,  # Flies over obstacles.
		"floating": true,
	},
}
