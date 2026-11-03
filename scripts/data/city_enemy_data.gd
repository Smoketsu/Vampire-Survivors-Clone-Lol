## CityEnemyData — immutable design data for the kinds THE LAST LINE fields on
## every Act VIII stage (GDD §15.0 "Act VIII foundation (phase 1)"; owner-
## approved proposal docs/act8/PROPOSAL.md "Act VIII: The Last Line"). The last
## great cities of the living fight back, in rising order (the escalation, a
## plain clock): the gangs who own the blocks, then the police, then SWAT and
## the Guard, then the army, and at the end the superheroes. The shared kinds
## of phase 1:
##   civilian       — not a fighter: flees through the streets, never attacks;
##                    the army kills them like any enemy and each drops XP
##                    (CIVILIANS; male and female looks).
##   street_thug    — gangs: fodder with bats and pipes, in crowds.
##   gang_gunner    — gangs: ranged fodder; pistols sprayed sideways while
##                    walking in, poor aim, many bullets.
##   riot_cop       — police: a soldier with a riot shield (a front: ARMOUR)
##                    and a baton, in a line.
##   squad_car      — police: a VEHICLE (ARMOUR): drives a street lane and runs
##                    over what is in it; the light bar pulses slowly.
##   swat_breacher  — SWAT: a soldier; a flashbang that stuns summons in a
##                    circle for 1 s, and a shotgun.
##   field_medic    — SWAT: support (female, figure style); heals soldiers near
##                    her through the existing enemy-heal path ("healer").
##   rifleman       — army: ranged, squads of 4, short bursts while advancing.
##   tank           — army: a VEHICLE with front armour and flat armour; a
##                    cannon shell with a landing circle; the Reckoning's heavy.
##   blitz          — heroes: the reference SUPER, a male speedster who dashes
##                    through the ring and cannot turn mid-dash ("Fast. Can't
##                    turn."): a dash that ends on a building face, a wreck, a
##                    Bone Wall segment or a blocker summon exposes him.
##   city_wreck     — the burning wreck of a vehicle (a STRUCTURE row: Convoy
##                    places the wreck itself; this row names it, carries its
##                    look and lets --spawn= drop one to test).
## Each stage's own kinds live in its own file (SkidRowEnemyData,
## FortKesslerEnemyData, LibertyHeightsEnemyData; empty until phase 2);
## EnemyDirector.enemy_def() looks them up through city_def(), this file first,
## after the Court's tables.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional City keys (absent = off):
##   faction       — "city" (the Codex's Last Line tab, the reports).
##   kit           — a CovenantKit id; a City kit lives in
##                   scripts/enemies/city/<kit>_kit.gd (CovenantKits loads it
##                   by name after the Court's folder, so kit ids must be unique
##                   across the seven folders). Every City kind has one (a
##                   CityKit; a Super a SuperKit).
##   tier          — String, one of CityRulesData.TIERS: the escalation tier
##                   the kind belongs to (the Codex and the report group by it).
##   armour_front  — float 0..1: the share cut from a hit landing on the front
##                   (+-60 degrees of the facing; Armour, the one path); 0 /
##                   absent = no front. Flat armour is the existing "flat_armor"
##                   key and path (no second one).
##   vehicle       — bool: drives the street lanes, runs over what is in its
##                   lane, leaves a wreck (Convoy). Keys: half_length /
##                   half_width (px, its body along / across its lane; the
##                   run-over box), run_damage (a run-over hit, before the time
##                   scaling; "damage" is unused); optional ram_damage (share
##                   of its max HP a wreck ram costs it; absent = CityRulesData
##                   .CONVOY's; Act VIII, Skid Row's limo).
##   super         — Dictionary: the Super's plate and weakness: "power" and
##                   "weakness" (the two short plate lines), and optional
##                   "stun" / "exposed_time" overrides of CityRulesData.SUPERS.
##   civilian      — bool: flees, never attacks, never body-blocks the ring,
##                   never hit by the city's own forces (Civilians).
##   fodder        — true: fodder (reports).
##   figure        — true: a figure-style woman (the art pass's bust rig; no
##                   rule reads it).
## Kit numbers (the spray, the burst, the flashbang, the shell, the dash) are
## row keys documented on each row. The GDD gives no numbers: everything is
## TUNING (not in GDD) unless marked as the owner-approved proposal.
class_name CityEnemyData
extends RefCounted

## Faction id of the City's kinds (row "faction").
const FACTION: String = "city"
## Kind id of a civilian.
const CIVILIAN: String = "civilian"
## Kind id of the gangs' fodder.
const STREET_THUG: String = "street_thug"
## Kind id of the gangs' ranged fodder.
const GANG_GUNNER: String = "gang_gunner"
## Kind id of the police's soldier.
const RIOT_COP: String = "riot_cop"
## Kind id of the police's vehicle.
const SQUAD_CAR: String = "squad_car"
## Kind id of SWAT's soldier.
const SWAT_BREACHER: String = "swat_breacher"
## Kind id of SWAT's support.
const FIELD_MEDIC: String = "field_medic"
## Kind id of the army's ranged soldier.
const RIFLEMAN: String = "rifleman"
## Kind id of the army's vehicle and the Martial Law heavy.
const TANK: String = "tank"
## Kind id of the reference Super.
const BLITZ: String = "blitz"
## Kind id of a burning wreck (a structure row; Convoy places wrecks).
const WRECK: String = "city_wreck"
## Sprite key of a woman civilian (assets/sprites/city/).
const CIVILIAN_WOMAN_SPRITE: String = "city/civilian_woman"
## Sprite key of a burning wreck (assets/sprites/structures/).
const WRECK_SPRITE: String = "structures/city_wreck"
## Sprite key of a burnt-out wreck.
const WRECK_BURNT_SPRITE: String = "structures/city_wreck_burnt"
## Damage tag of the tank's cannon shell.
const SHELL_SOURCE: String = "tank_shell"
## Damage tag of a breacher's flashbang (stuns only).
const FLASH_SOURCE: String = "flashbang"
## Damage tag of Martial Law's artillery.
const ARTILLERY_SOURCE: String = "artillery"
## Damage tag of a wreck's explosion.
const WRECK_SOURCE: String = "wreck_blast"
## Damage tag of Blitz's dash.
const DASH_SOURCE: String = "blitz_dash"
## Ranged damage tags of the City beyond its "ranged" rows' kind ids (Kevlar
## Bones' hook reads them through Armour.kevlar_mult()).
const RANGED_SOURCES: Array[String] = ["tank_shell", "artillery",
	# --- Act VIII: Skid Row --- the limo crew's sprays, Don Marrow's revolver and gold minigun.
	"limo_spray", "marrow_revolver", "marrow_minigun",
	# --- Act VIII: Liberty Heights --- (Aurora's energy blasts, Atlas's thrown wreck, Paragon's heat vision)
	"aurora_blast", "atlas_throw", "paragon_heat"]

## The City's shared kinds, keyed by kind id.
const ENEMIES := {
	# Not a fighter: a civilian who runs from the dead (owner: "fleeing
	# civilians fill the streets at the start of a run ... the army kills them
	# like any enemy, and each one drops XP. There is no sparing"). It flees
	# from the nearest necromancer and summon along the streets, never attacks,
	# never body-blocks the ring, and leaves (no XP) once 900 px from every
	# necromancer (Civilians, CivilianKit). Summons rank every threat above it
	# (target_priority 0).
	"civilian": {
		"display_name": "Civilian",
		"max_hp": 8.0,  # TUNING (not in GDD) one blow
		"move_speed": 50.0,  # TUNING (not in GDD) px/s; a panicked run, slower than most summons (they can be caught)
		"damage": 0.0,  # Never attacks.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 8.0,  # TUNING (not in GDD) px
		"armor": 0.0,
		"xp": 1,  # Owner-approved: "let them drop XP" (the fodder value)
		"behavior": "melee",  # Unused: its kit owns every tick.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.0,  # Brief: every threat ranks above a civilian
		"mass": 0.5,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "civilian",
		"tier": "gangs",  # Here from 0:00 (the report groups it there; the Codex lists it apart).
		"civilian": true,  # Owner-approved: Civilians, the third shared rule
		"fodder": true,
	},  # The civilian.
	# Gangs, fodder: bats and pipes, in crowds.
	"street_thug": {
		"display_name": "Street Thug",
		"max_hp": 16.0,  # TUNING (not in GDD) fodder (the Blood Thrall 15)
		"move_speed": 52.0,  # TUNING (not in GDD) px/s
		"damage": 3.0,  # TUNING (not in GDD) a bat, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 5.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.2,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "street_thug",
		"tier": "gangs",  # Owner-approved proposal: ★ Gangs
		"fodder": true,
	},  # The street thug.
	# Gangs, ranged fodder: two pistols sprayed sideways while walking in.
	# Every shot is a SPRAY of `spray` bullets, each aimed off by up to
	# spray_spread rad (poor aim, many bullets); it keeps walking in.
	"gang_gunner": {
		"display_name": "Gang Gunner",
		"max_hp": 14.0,  # TUNING (not in GDD) fodder
		"move_speed": 46.0,  # TUNING (not in GDD) px/s
		"damage": 1.4,  # TUNING (not in GDD) per bullet, before the time scaling
		"attack_interval": 1.7,  # TUNING (not in GDD) s between two sprays
		"attack_range": 170.0,  # TUNING (not in GDD) px
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 300.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.35,  # TUNING (not in GDD) 0..1
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "gang_gunner",
		"tier": "gangs",  # Owner-approved proposal: ★ Gangs
		"fodder": true,
		"spray": 4,  # TUNING (not in GDD) bullets a spray ("many bullets")
		"spray_spread": 0.5,  # TUNING (not in GDD) rad each side ("poor aim")
	},  # The gang gunner.
	# Police, soldier: a riot shield in front (ARMOUR: a hit on the front is cut
	# by armour_front; flank the line) and a baton. TEAR GAS (Act VIII phase 2,
	# Skid Row; owner-approved proposal: "tear gas that slows summons"): every
	# gas_every s, with a summon within gas_range px, it lobs a canister at the
	# nearest one; after gas_flight s a cloud of gas_radius px hangs there for
	# gas_time s and slows every summon in it by gas_slow (TerrainSlow
	# .slow_summon(), the one ground-slow path, refreshed gas_linger s each
	# gas_tick s). No damage; never the necromancer (RiotCopKit).
	"riot_cop": {
		"display_name": "Riot Cop",
		"max_hp": 54.0,  # TUNING (not in GDD) a soldier (the Blood Knight 44)
		"move_speed": 42.0,  # TUNING (not in GDD) px/s; a shield line is slow
		"damage": 4.5,  # TUNING (not in GDD) a baton, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 11.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD) riot armour
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD) 0..1
		"mass": 2.2,  # TUNING (not in GDD) shield braced
		"faction": FACTION,
		"kit": "riot_cop",
		"tier": "police",  # Owner-approved proposal: ★★ Police
		"armour_front": 0.7,  # TUNING (not in GDD) the riot shield cuts 70% from the front ("flank the line")
		# --- Act VIII: Skid Row --- the tear gas (RiotCopKit).
		"gas_every": 16.0,  # TUNING (not in GDD) s between two canisters (first pass 14)
		"gas_range": 200.0,  # TUNING (not in GDD) px to the summon it lobs at
		"gas_flight": 0.6,  # TUNING (not in GDD) s the canister flies
		"gas_time": 4.0,  # TUNING (not in GDD) s the cloud hangs
		"gas_radius": 44.0,  # TUNING (not in GDD) px
		"gas_slow": 0.3,  # TUNING (not in GDD) share of move speed the summons in it lose (first pass 0.35)
		"gas_linger": 0.5,  # TUNING (not in GDD) s the slow lasts after a summon leaves the cloud
		"gas_tick": 0.25,  # TUNING (not in GDD) s between two slow refreshes
	},  # The riot cop.
	# Police, vehicle: a squad car. CONVOY: it drives straight along a street
	# lane toward the necromancer's street with its headlights 1 s ahead, runs
	# over every summon and the necromancer in the lane, turns at the lane's
	# end and comes again; dead, it leaves a burning wreck that explodes.
	#   half_length / half_width — px of its body along / across the lane.
	#   run_damage               — a run-over hit, before the time scaling.
	#   siren                    — its light bar pulses (CityRulesData.SIREN_PULSE_HZ).
	"squad_car": {
		"display_name": "Squad Car",
		"max_hp": 170.0,  # TUNING (not in GDD)
		"move_speed": 150.0,  # TUNING (not in GDD) px/s; a car
		"damage": 0.0,  # Unused: run_damage.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 16.0,  # TUNING (not in GDD) px (targeting body; the run-over box is half_length x half_width)
		"armor": 0.2,  # TUNING (not in GDD) a steel body
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "melee",  # Unused: its kit drives it.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1
		"mass": 30.0,  # TUNING (not in GDD) a car
		"slow_resist": 0.5,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "squad_car",
		"tier": "police",  # Owner-approved proposal: ★★ Police (squad cars)
		"vehicle": true,  # Owner-approved proposal: Armour (Convoy)
		"half_length": 26.0,  # TUNING (not in GDD) px (~64 px sprite)
		"half_width": 13.0,  # TUNING (not in GDD) px
		"run_damage": 5.0,  # TUNING (not in GDD) before the time scaling (first pass 9: 54 summons run over on Liberty Heights, seed 7)
		"siren": true,  # Owner rule: the light bar pulses slowly (at most 1 Hz)
	},  # The squad car.
	# SWAT, soldier: a shotgun (a short-range spray of `pellets` pellets within
	# pellet_spread rad) and a FLASHBANG: every flash_every s, with a summon
	# within flash_range px, it lobs one onto the summon; after flash_windup s
	# (a landing circle) every summon within flash_radius px is stunned for
	# flash_stun s (CombatResolver.stun_unit(), the one summon stun path).
	"swat_breacher": {
		"display_name": "SWAT Breacher",
		"max_hp": 72.0,  # TUNING (not in GDD) a soldier
		"move_speed": 44.0,  # TUNING (not in GDD) px/s
		"damage": 1.3,  # TUNING (not in GDD) per pellet, before the time scaling (first pass 2.0: SWAT broke the seed-7 army at 9:00)
		"attack_interval": 2.4,  # TUNING (not in GDD) s; a pump shotgun
		"attack_range": 96.0,  # TUNING (not in GDD) px; close range
		"radius": 11.0,  # TUNING (not in GDD) px
		"armor": 0.25,  # TUNING (not in GDD) a vest
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 340.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1; "kill first"
		"mass": 1.8,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "swat_breacher",
		"tier": "swat",  # Owner-approved proposal: ★★★ SWAT and the Guard
		"pellets": 4,  # TUNING (not in GDD) (first pass 5)
		"pellet_spread": 0.35,  # TUNING (not in GDD) rad each side
		"flash_every": 12.0,  # TUNING (not in GDD) s (first pass 9)
		"flash_range": 190.0,  # TUNING (not in GDD) px
		"flash_windup": 0.7,  # TUNING (not in GDD) s (its landing circle)
		"flash_radius": 44.0,  # TUNING (not in GDD) px (first pass 52)
		"flash_stun": 1.0,  # Owner-approved proposal: "stun summons in a circle for 1 s"
	},  # The SWAT breacher.
	# SWAT, support (female, figure style): heals soldiers near her through the
	# existing enemy-heal path (behavior "healer": Enemy._try_heal() ->
	# CombatResolver.heal_enemy()); a weak swing in reach. Never heals a
	# civilian (Enemy._pick_heal_target()).
	"field_medic": {
		"display_name": "Field Medic",
		"max_hp": 46.0,  # TUNING (not in GDD)
		"move_speed": 46.0,  # TUNING (not in GDD) px/s
		"damage": 2.0,  # TUNING (not in GDD) a weak swing
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "healer",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 14.0,  # TUNING (not in GDD) HP a heal
		"heal_interval": 2.4,  # TUNING (not in GDD) s
		"heal_radius": 130.0,  # TUNING (not in GDD) px
		"heal_stat": "medic_heals",  # The stat her heals count in (Enemy.heal_stat).
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; "priority target"
		"mass": 0.9,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "field_medic",
		"tier": "swat",  # Owner-approved proposal: ★★★ medics
		"figure": true,  # Owner rule: every female kind in the figure-redesign style
	},  # The field medic.
	# Army, ranged: rifle squads of 4 that fire short BURSTS (`burst` rounds,
	# burst_gap s apart) while advancing.
	"rifleman": {
		"display_name": "Rifleman",
		"max_hp": 42.0,  # TUNING (not in GDD)
		"move_speed": 42.0,  # TUNING (not in GDD) px/s
		"damage": 1.125,  # TUNING (not in GDD) per round, before the time scaling (first pass 2.2; was 1.5, Act VIII pass 1, owner: Softer riflemen, -25%)
		"attack_interval": 2.2,  # TUNING (not in GDD) s between bursts
		"attack_range": 230.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD) a helmet and vest
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 430.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.55,  # TUNING (not in GDD) 0..1
		"mass": 1.4,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "rifleman",
		"tier": "army",  # Owner-approved proposal: ★★★★ the army
		"burst": 3,  # TUNING (not in GDD) rounds a burst ("short bursts")
		"burst_gap": 0.12,  # TUNING (not in GDD) s
		"burst_spread": 0.08,  # TUNING (not in GDD) rad each side
	},  # The rifleman.
	# Army, vehicle: a tank. CONVOY like the squad car, with FRONT ARMOUR
	# (armour_front) and FLAT ARMOUR (the existing flat_armor path), and a
	# CANNON: every shell_every s, with a target within shell_range px, it
	# fires a shell that lands after shell_windup s on the target's spot (a
	# landing circle; summons and the necromancer within shell_radius px take
	# shell_damage). It is the Martial Law Reckoning's heavy.
	"tank": {
		"display_name": "Tank",
		"max_hp": 700.0,  # TUNING (not in GDD) a heavy (first pass 950)
		"move_speed": 66.0,  # TUNING (not in GDD) px/s; treads
		"damage": 0.0,  # Unused: run_damage and the shell.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 24.0,  # TUNING (not in GDD) px
		"armor": 0.25,  # TUNING (not in GDD)
		"flat_armor": 4.0,  # TUNING (not in GDD) the existing flat armour path ("flat armour"; Siegecraft, Wither)
		"xp": 24,  # TUNING (not in GDD)
		"behavior": "melee",  # Unused: its kit drives it.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD) 0..1
		"mass": 80.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "tank",
		"tier": "army",  # Owner-approved proposal: ★★★★ tanks
		"vehicle": true,  # Owner-approved proposal: Armour rules
		"armour_front": 0.6,  # TUNING (not in GDD) front armour
		"half_length": 34.0,  # TUNING (not in GDD) px (~80 px sprite)
		"half_width": 22.0,  # TUNING (not in GDD) px
		"run_damage": 9.0,  # TUNING (not in GDD) before the time scaling (first pass 16)
		"shell_every": 8.0,  # TUNING (not in GDD) s (first pass 6, then 7)
		"shell_range": 380.0,  # TUNING (not in GDD) px
		"shell_windup": 1.3,  # TUNING (not in GDD) s (its landing circle)
		"shell_radius": 32.0,  # TUNING (not in GDD) px (first pass 44, then 36)
		"shell_damage": 5.0,  # TUNING (not in GDD) before the time scaling (first pass 16: 53 summons in one Skid Row run, seed 7; then 8: still the top killer)
	},  # The tank.
	# Heroes, the reference SUPER (male speedster): "Fast. Can't turn." A
	# DASH: every dash_every s, with a target within dash_range px, he crouches
	# dash_windup s (a line along his street), then runs dash_length px
	# straight down the street at dash_speed px/s through the ring, hitting
	# every summon and the necromancer he passes (dash_damage, once each); he
	# cannot turn. A dash that ends on a building face, a wreck, a Bone Wall
	# segment or a blocker summon EXPOSES him (SuperKit.expose()).
	"blitz": {
		"display_name": "Blitz",
		"max_hp": 1300.0,  # TUNING (not in GDD) an elite Super
		"move_speed": 86.0,  # TUNING (not in GDD) px/s; fast even on foot
		"damage": 6.0,  # TUNING (not in GDD) a punch, before the time scaling
		"attack_interval": 0.8,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 12.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 40,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1
		"mass": 3.0,  # TUNING (not in GDD)
		"slow_resist": 0.5,  # TUNING (not in GDD)
		"always_elite": true,  # A Super is an elite (owner-approved proposal: "the act's elites")
		"faction": FACTION,
		"kit": "blitz",
		"tier": "heroes",  # Owner-approved proposal: ★★★★★ the heroes
		"super": {"power": "Fast.", "weakness": "Can't turn."},  # Owner-approved proposal: the plate ("Fast. Can't turn.")
		"dash_every": 5.0,  # TUNING (not in GDD) s
		"dash_range": 420.0,  # TUNING (not in GDD) px
		"dash_windup": 0.6,  # TUNING (not in GDD) s
		"dash_speed": 560.0,  # TUNING (not in GDD) px/s
		"dash_length": 540.0,  # TUNING (not in GDD) px
		"dash_damage": 9.0,  # TUNING (not in GDD) before the time scaling
		"dash_width": 14.0,  # TUNING (not in GDD) px each side of his line that he hits
	},  # Blitz.
	# Structure: a burning wreck. Convoy places a vehicle's wreck itself
	# (CityBlocks.add_wreck(), Convoy.wreck_vehicle()); a wreck "spawned" by
	# --spawn=city_wreck@T places one at that point the same way and leaves the
	# field at once (CityWreckKit). Its numbers are CityRulesData.WRECK's.
	"city_wreck": {
		"display_name": "Burning Wreck",
		"max_hp": 1.0,
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 18.0,  # TUNING (not in GDD) px
		"armor": 0.0,
		"xp": 0,
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.0,
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": FACTION,
		"kit": "city_wreck",
		"tier": "army",  # A vehicle's remains (the report lists it with the army).
	},  # The burning wreck.
	# --- Act VIII: Fort Kessler ---
	# Army, heavy ranged (owner-approved proposal: "Machine Gunner | Heavy
	# ranged (four stars) | Sets up and sweeps a telegraphed fire lane | Grave
	# Step; Bone Wall in the lane"; built by Fort Kessler, any stage may field
	# him). He walks in like a rifleman; when his attack is due (the shared
	# ranged attack: attack_range / attack_interval) he SETS UP: for setup_time
	# s he kneels behind his gun and the FIRE LANE shows (a gradient strip
	# lane_length px long, lane_half px each side of its centre line, at its
	# start angle, the swept arc faint behind it); then he SWEEPS it through
	# sweep_arc rad across his target over sweep_time s, every `tick` s hitting
	# every summon and necromancer inside the lane for tick_damage (source
	# CityEnemyData.MG_SOURCE, a ranged source: Kevlar Bones' hook), and packs
	# up for pack_time s. A Bone Wall segment in the lane (BoneWall.covers(),
	# any necromancer's) stops the lane there; Grave Step's i-frames dodge it
	# (damage_player()). MachineGunnerKit.
	"machine_gunner": {
		"display_name": "Machine Gunner",
		"max_hp": 66.0,  # TUNING (not in GDD) a heavy (the rifleman 42)
		"move_speed": 36.0,  # TUNING (not in GDD) px/s; he carries the gun
		"damage": 0.0,  # Unused: tick_damage (his kit fires the lane).
		"attack_interval": 9.0,  # TUNING (not in GDD) s between two set-ups (first pass 7.5)
		"attack_range": 250.0,  # TUNING (not in GDD) px: he sets up this close
		"radius": 11.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD) a helmet, a vest and a gun shield
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 0.0,  # Unused: the lane is not a projectile.
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1
		"mass": 2.2,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "machine_gunner",
		"tier": "army",  # Owner-approved proposal: four stars, the army
		"setup_time": 1.4,  # TUNING (not in GDD) s: the telegraph (the lane shows; first pass 1.2)
		"sweep_time": 2.2,  # TUNING (not in GDD) s the sweep lasts
		"sweep_arc": 0.8,  # TUNING (not in GDD) rad swept, centred on his target (first pass 0.9)
		"lane_length": 300.0,  # TUNING (not in GDD) px
		"lane_half": 10.0,  # TUNING (not in GDD) px each side of the lane's centre line
		"tick": 0.25,  # TUNING (not in GDD) s between two hits of the lane (first pass 0.2)
		"tick_damage": 0.7,  # TUNING (not in GDD) per hit, before the time scaling (first pass 1.4: the gunners' lanes wiped the seed-7 army ring at 10:00 on Fort Kessler)
		"pack_time": 0.6,  # TUNING (not in GDD) s he stands after the sweep
	},  # The machine gunner.
	# Army, a flying VEHICLE (owner-approved proposal: "Attack Helicopter |
	# Vehicle, flying (four stars) | Strafing runs over the ring, rocket pods |
	# Gargoyles, Archers and spells"; built by Fort Kessler). A "vehicle" (the
	# Convoy counts it, its run-over box is the bot's lane hint, a dead one
	# leaves a wreck) that never drives the streets and never runs anything
	# over: it FLIES (row "flies": no summon body-blocks it). STRAFING RUNS:
	# it picks the street lane through the necromancer (CityBlocks.lane(); a
	# straight line off a blocks stage), comes in from run_half px behind him,
	# flies the lane at its move_speed to run_half px past him, firing a ROCKET
	# POD every rocket_every s: a landing circle (CityShells, the one shell
	# path) rocket_lead px ahead of it on the lane, rocket_radius px, landing
	# after rocket_windup s for rocket_damage (summons and the necromancer only;
	# source HELI_ROCKET_SOURCE, ranged); then it banks round for turn_time s
	# and runs the other axis. Its rotors keep it out of a sword's reach: a
	# MELEE summon's hit deals melee_mult (a summon class whose base attack
	# range is under PassiveData.OVERCLOCK_MIN_RANGE, except the Gargoyle's
	# dive); Archers, Mages, Gargoyles, every ranged class and every spell hit
	# it in full. Shot down over a building it crashes onto the nearest street
	# (its wreck takes a street cell, never a roof). AttackHelicopterKit.
	"attack_helicopter": {
		"display_name": "Attack Helicopter",
		"max_hp": 260.0,  # TUNING (not in GDD) a vehicle (the squad car 170, the tank 700; first pass 380: none was shot down in the seed-7 army run)
		"move_speed": 170.0,  # TUNING (not in GDD) px/s on its strafing run
		"damage": 0.0,  # Unused: the rockets.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 18.0,  # TUNING (not in GDD) px (targeting body)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 14,  # TUNING (not in GDD)
		"behavior": "melee",  # Unused: its kit flies it.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) 0..1
		"mass": 20.0,  # TUNING (not in GDD)
		"slow_resist": 0.7,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "attack_helicopter",
		"tier": "army",  # Owner-approved proposal: four stars, the army
		"vehicle": true,  # Owner-approved proposal: a vehicle (Convoy: counted, wrecked)
		"flies": true,  # Owner-approved proposal: flying (no summon body-blocks it)
		"phases": true,  # It flies over the roofs (Enemy.phases_obstacles: no push-out)
		"half_length": 30.0,  # TUNING (not in GDD) px (the bot's lane hint; it runs nothing over)
		"half_width": 14.0,  # TUNING (not in GDD) px
		"run_half": 520.0,  # TUNING (not in GDD) px before and past the necromancer on a run
		"turn_time": 2.4,  # TUNING (not in GDD) s it banks round between two runs
		"rocket_every": 0.55,  # TUNING (not in GDD) s between two rockets on a run
		"rocket_lead": 150.0,  # TUNING (not in GDD) px ahead of it a rocket lands
		"rocket_windup": 0.9,  # TUNING (not in GDD) s (its landing circle)
		"rocket_radius": 30.0,  # TUNING (not in GDD) px
		"rocket_damage": 3.0,  # TUNING (not in GDD) before the time scaling (first pass 4)
		"rocket_reach": 360.0,  # TUNING (not in GDD) px: it fires only this near the necromancer's line
		"melee_mult": 0.5,  # TUNING (not in GDD) share of a melee summon's hit it takes (rotor height)
	},  # The attack helicopter.
	# --- Act VIII: Liberty Heights ---
	# The three Supers Liberty Heights builds (GDD §15.0 "Atlas, Aurora and
	# Nightjar (Act VIII)"; owner-approved proposal: "Atlas (a strongman who
	# throws wrecks; a long wind-up), Aurora (a flying energy blaster, figure
	# style; falls out of the sky when stunned), Nightjar (a gadget vigilante
	# who grapples summons out of the ring; must land to strike)"; owner:
	# open parody nods, no names, logos, emblems or exact costumes). Rows of
	# the shared table, so any stage may use them; on Liberty Heights each
	# leads a zone as its miniboss (LibertyHeightsDirector). Each is a
	# SuperKit: guarded (x0.6) until its weakness calls expose().
	# Heroes, a SUPER (male strongman): "Strong. Slow to throw." Every
	# throw_every s, with the necromancer within throw_range px, he lifts the
	# nearest wreck within lift_range px (CityBlocks.remove_wreck(): the wreck
	# leaves the street) or, with none, a parked car, and WINDS UP for
	# throw_windup s (his mark on the ground where it will land: the
	# necromancer's spot); then he throws it: a CityShells landing circle of
	# throw_radius px lands throw_flight s later (throw_damage) and, on a
	# blocks layout, the car lands as a new wreck there. A STUN (or a Deep
	# Freeze) during the wind-up EXPOSES him (SuperKit.expose(), "stun") and
	# the throw is dropped at his feet.
	"atlas": {
		"display_name": "Atlas",
		"max_hp": 1700.0,  # TUNING (not in GDD) the strongman (Blitz 1300)
		"move_speed": 58.0,  # TUNING (not in GDD) px/s; heavy
		"damage": 10.0,  # TUNING (not in GDD) a haymaker, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 16.0,  # TUNING (not in GDD) px (x1.35 as an elite = 21.6 <= CityBlockData.MAX_BODY_RADIUS 36)
		"armor": 0.25,  # TUNING (not in GDD)
		"xp": 50,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1
		"mass": 40.0,  # TUNING (not in GDD) hard to shove
		"slow_resist": 0.6,  # TUNING (not in GDD)
		"always_elite": true,  # A Super is an elite (owner-approved proposal: "the act's elites")
		"faction": FACTION,
		"kit": "atlas",
		"tier": "heroes",  # Owner-approved proposal: the heroes
		"super": {"power": "Strong.", "weakness": "Slow to throw."},  # Owner-approved proposal ("a long wind-up"); brief: the plate
		"throw_every": 7.0,  # TUNING (not in GDD) s between throws
		"throw_first": 3.0,  # TUNING (not in GDD) s before his first throw
		"throw_range": 380.0,  # TUNING (not in GDD) px to the necromancer
		"lift_range": 260.0,  # TUNING (not in GDD) px within which he lifts a wreck (else a parked car)
		"throw_windup": 1.6,  # TUNING (not in GDD) s, the long wind-up (the weakness's window)
		"throw_flight": 0.8,  # TUNING (not in GDD) s of the landing circle after the throw
		"throw_radius": 46.0,  # TUNING (not in GDD) px
		"throw_damage": 16.0,  # TUNING (not in GDD) before the time scaling
		"throw_half": 26.0,  # TUNING (not in GDD) px, half length of the wreck he leaves (CityBlocks.add_wreck())
	},  # Atlas.
	# Heroes, a SUPER (female energy blaster, figure style; she flies, row
	# "flies": no summon body-blocks her): "Flies. Falls when stunned." She
	# hovers hover_dist px from the necromancer, drifting round him, and every
	# blast_every s fires blast_count energy blasts (hostile bolts tagged
	# aurora_blast, a ranged City source: Kevlar Bones) at the necromancer or
	# the nearest summon. In the air a grounded melee summon's blow deals
	# aloft_melee_taken of itself (FallenAngelKit.grounded_melee()). ANY STUN
	# (or a Deep Freeze) DROPS HER OUT OF THE SKY: she falls, lands (no longer
	# "flies": blockers hold her and every blow lands in full) and is EXPOSED
	# (SuperKit.expose(), "stun") until she rises again, grounded_time s later.
	"aurora": {
		"display_name": "Aurora",
		"max_hp": 1100.0,  # TUNING (not in GDD) the flier (Blitz 1300)
		"move_speed": 90.0,  # TUNING (not in GDD) px/s in the air
		"damage": 7.0,  # TUNING (not in GDD) one energy blast (her shared ranged attack is unused), before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s, her blow when grounded
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 12.0,  # TUNING (not in GDD) px (x1.35 as an elite = 16.2)
		"armor": 0.05,  # TUNING (not in GDD)
		"xp": 45,  # TUNING (not in GDD)
		"behavior": "melee",  # Her kit flies and blasts; on the ground she strikes in melee.
		"projectile_speed": 300.0,  # TUNING (not in GDD) px/s of a blast
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1
		"mass": 3.0,  # TUNING (not in GDD)
		"slow_resist": 0.5,  # TUNING (not in GDD)
		"always_elite": true,  # A Super is an elite (owner-approved proposal: "the act's elites")
		"faction": FACTION,
		"kit": "aurora",
		"tier": "heroes",  # Owner-approved proposal: the heroes
		"flies": true,  # Owner-approved proposal: "a flying energy blaster" (Enemy.flies: over the Bone Ring)
		"figure": true,  # Female, the figure-redesign style (art only)
		"super": {"power": "Flies.", "weakness": "Falls when stunned.", "exposed_time": 3.5},  # Owner-approved proposal; exposed_time TUNING (not in GDD): exposed until she rises (stun 1 s + 3.5 s = grounded_time)
		"hover_dist": 150.0,  # TUNING (not in GDD) px from the necromancer (over the ring's outer posts)
		"hover_speed": 0.45,  # TUNING (not in GDD) rad/s she drifts round him
		"blast_every": 1.8,  # TUNING (not in GDD) s
		"blast_count": 2,  # TUNING (not in GDD) bolts a volley
		"blast_spread": 0.12,  # TUNING (not in GDD) rad between two bolts
		"blast_range": 360.0,  # TUNING (not in GDD) px
		"blast_damage": 7.0,  # TUNING (not in GDD) a bolt, before the time scaling
		"aloft_melee_taken": 0.5,  # TUNING (not in GDD) share of a grounded melee blow that lands in flight
		"grounded_time": 4.5,  # TUNING (not in GDD) s she lies grounded after a stun (expose stun 1 s + exposed_time)
		"fall_time": 0.4,  # TUNING (not in GDD) s of the fall (drawn)
	},  # Aurora.
	# Heroes, a SUPER (male gadget vigilante, the cowled night watchman; no
	# bat shapes or emblems): "Grapples. Must land to strike." He swings over
	# the ring (row "flies") and every grapple_every s fires his GRAPPLE at a
	# summon within grapple_range px (a telegraphed line, grapple_windup s):
	# the summon is reeled pull_time s out to pull_out px beyond the Bone
	# Ring's outer edge, away from the necromancer, through THE HELD HOOK
	# (SummonedUnit.held_until renewed each tick, the one place that moves it:
	# carry(), as the Chiropteran King's carry-off), then dropped (drop_daze s
	# more). He then LANDS beside it to strike (land_time s, no longer "flies":
	# his blows land, and every blow on him lands in full). While he is
	# LANDED, a BLOCKER summon touching him (a block radius) or a STUN EXPOSES
	# him (SuperKit.expose(), "blocker" / "stun"). In the air a grounded melee
	# blow deals aloft_melee_taken of itself.
	"nightjar": {
		"display_name": "Nightjar",
		"max_hp": 1400.0,  # TUNING (not in GDD) the vigilante
		"move_speed": 96.0,  # TUNING (not in GDD) px/s swinging
		"damage": 9.0,  # TUNING (not in GDD) a gauntlet strike when landed, before the time scaling
		"attack_interval": 0.7,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 13.0,  # TUNING (not in GDD) px (x1.35 as an elite = 17.6)
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 45,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1
		"mass": 4.0,  # TUNING (not in GDD)
		"slow_resist": 0.5,  # TUNING (not in GDD)
		"always_elite": true,  # A Super is an elite (owner-approved proposal: "the act's elites")
		"faction": FACTION,
		"kit": "nightjar",
		"tier": "heroes",  # Owner-approved proposal: the heroes
		"flies": true,  # He swings over the ring between strikes (owner-approved proposal: "must land to strike")
		"super": {"power": "Grapples.", "weakness": "Must land to strike."},  # Owner-approved proposal; brief: the plate
		"grapple_every": 6.0,  # TUNING (not in GDD) s
		"grapple_first": 2.5,  # TUNING (not in GDD) s before the first
		"grapple_range": 230.0,  # TUNING (not in GDD) px to the summon
		"grapple_windup": 0.7,  # TUNING (not in GDD) s, the line shows
		"pull_time": 0.9,  # TUNING (not in GDD) s the summon is reeled
		"pull_out": 90.0,  # TUNING (not in GDD) px beyond the Bone Ring's outer edge
		"drop_daze": 0.6,  # TUNING (not in GDD) s held after the drop
		"land_time": 3.2,  # TUNING (not in GDD) s he stands landed to strike (the weakness's window)
		"strike_damage": 12.0,  # TUNING (not in GDD) his landing strike on the reeled summon, before the time scaling
		"aloft_melee_taken": 0.5,  # TUNING (not in GDD) share of a grounded melee blow that lands in flight
	},  # Nightjar.
}

# --- Act VIII: Fort Kessler ---
## Kind id of the army's heavy ranged soldier (Fort Kessler builds it).
const MACHINE_GUNNER: String = "machine_gunner"
## Kind id of the army's flying vehicle (Fort Kessler builds it).
const ATTACK_HELICOPTER: String = "attack_helicopter"
## Damage tag of the machine gunner's fire lane (ranged).
const MG_SOURCE: String = "machine_gun"
## Damage tag of the attack helicopter's rocket pods (ranged).
const HELI_ROCKET_SOURCE: String = "heli_rocket"
## Ranged damage tags Fort Kessler adds to RANGED_SOURCES' (Kevlar Bones'
## hook, Armour.kevlar_mult(), reads both lists): the machine gun, the
## helicopter's rockets, General Harrow's carpet bombs and Mammoth's turret
## shells. (A list of its own so the three stages' additions merge cleanly.)
const FORT_KESSLER_RANGED_SOURCES: Array[String] = ["machine_gun", "heli_rocket", "carpet_bomb", "mammoth_shell"]

# --- Act VIII: Liberty Heights ---
## Kind id of Atlas, the strongman Super.
const ATLAS: String = "atlas"
## Kind id of Aurora, the flying blaster Super (female).
const AURORA: String = "aurora"
## Kind id of Nightjar, the gadget vigilante Super.
const NIGHTJAR: String = "nightjar"
## Damage tag of Atlas's thrown wreck (a ranged City source: RANGED_SOURCES).
const THROW_SOURCE: String = "atlas_throw"
## Damage tag of Aurora's energy blasts (a ranged City source: RANGED_SOURCES).
const BLAST_SOURCE: String = "aurora_blast"
## Damage tag of a summon Nightjar drops after his grapple.
const GRAPPLE_SOURCE: String = "nightjar_drop"
## Damage tag of Nightjar's landing strike.
const STRIKE_SOURCE: String = "nightjar_strike"
## Damage tags of the three Supers' specials, in report order (LibertyHeightsReport
## sums their player_dmg_from_ / summon_dmg_from_ stats).
const SUPER_TAGS: Array[String] = ["atlas_throw", "aurora_blast", "nightjar_drop", "nightjar_strike"]
