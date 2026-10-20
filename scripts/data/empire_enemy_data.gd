## EmpireEnemyData — immutable design data for the kinds the ELECTRONIC EMPIRE
## fields on every Act III stage (GDD §15.0 "Act III foundation (phase 1)";
## owner-approved proposal "Necropathy: Act III Proposal (The Electronic
## Empire)"). The Empire conquered death with steel: its citizens are rebuilt,
## not reborn, and about 60% of its soldiers attack from range (Act I: under
## 20%). Each shot is weak, but there are many, fired from just off screen, and
## every one travels as a real projectile that the undead body-block (Line of
## Fire, EmpireShots). The shared kinds of phase 1:
##   scout_drone   — Scout Drone: fast flying fodder in swarms; short-range
##                   zaps; flies over obstacles. A MACHINE.
##   line_trooper  — Line Trooper: the Empire's rifleman; three-round bursts
##                   from 400 px while it keeps marching ("marching fire"). A
##                   CYBORG: raised, it rises as a Grave Gunner.
##   spotter       — Spotter: an elite marksman that paints a Lock-On line on
##                   a target for 1.5 s, then fires a heavy rail shot down it
##                   (LockOn). A CYBORG.
##   kill_drone    — Kill-Drone: the shared Purge Protocol Reckoning kind
##                   (stages name it as their Reckoning "kind"). A MACHINE.
## Each stage's own kinds live in its own file (WastesEnemyData,
## AssemblyEnemyData, CitadelEnemyData; empty until phase 2);
## EnemyDirector.enemy_def() looks them up through empire_def(), this file first.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Empire keys (absent = off):
##   faction        — "empire" (the Codex's Electronic Empire tab, the reports).
##   body           — "machine" or "cyborg" (Steel has no soul: a machine
##                    leaves no corpse to raise; a raised cyborg keeps its
##                    weapon as a Grave Gunner; Enemy.leaves_corpse() /
##                    rises_as_gunner(), EmpireRulesData.STEEL).
##   kit            — a CovenantKit id; an Empire kit lives in
##                    scripts/enemies/empire/<kit>_kit.gd (CovenantKits loads it
##                    by name, so phase 2 adds kits as new files).
##   phases         — true: flies over obstacles (Arena skips it), as the
##                    Archive's Ink Wraith.
##   floating       — true: drawn hovering (visual only).
##   shot_style     — EmpireRulesData.SHOT_STYLES id of its shots (look, hit
##                    radius, Line of Fire on / off).
##   burst_rounds / burst_gap / burst_spread — rounds per burst, s between two,
##                    rad of aim spread across the burst (EmpireKit.fire_burst()).
##   lock_on        — true: fires through a Lock-On line (SpotterKit, LockOn).
## A "ranged" Empire kind advances on the necromancer like every ranged kind
## (enemies always advance; nobody kites) and fires through its kit's
## fire_ranged() hook into EmpireShots instead of ProjectileManager.
## The GDD gives no numbers: everything is TUNING (not in GDD), except the
## owner-approved ones (rifle shots 4-6 damage, 380-520 px range, the 1.5 s
## Lock-On paint).
class_name EmpireEnemyData
extends RefCounted

## Faction id of the Electronic Empire's kinds (row "faction").
const FACTION: String = "empire"
## Body "machine": drones, turrets, mechs; leaves no corpse (row "body").
const MACHINE: String = "machine"
## Body "cyborg": rebuilt soldiers; a raised one keeps its weapon (row "body").
const CYBORG: String = "cyborg"
## Kind id of the shared Purge Protocol Reckoning kind (stages' RECKONING "kind").
const KILL_DRONE: String = "kill_drone"

## The Electronic Empire's shared kinds, keyed by kind id.
const ENEMIES := {
	# Fodder: a palm-sized chrome drone with one amber eye. Comes in swarms,
	# fast, frail, flies over obstacles and zaps whatever is close.
	"scout_drone": {
		"display_name": "Scout Drone",
		"max_hp": 10.0,  # TUNING (not in GDD) frail fodder (Recruit 14)
		"move_speed": 88.0,  # TUNING (not in GDD) px/s; fast (Recruit 58)
		"damage": 1.5,  # TUNING (not in GDD) per zap, before the time scaling (first pass 2.5 every 1.1 s shredded the early army; 2.0 still bled a weak army's necromancer to death by 3:30)
		"attack_interval": 1.4,  # TUNING (not in GDD) s between zaps
		"attack_range": 110.0,  # TUNING (not in GDD) px; "short range"
		"radius": 8.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 420.0,  # TUNING (not in GDD) px/s zap speed
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.25,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.6,  # TUNING (not in GDD) light: warriors hold it easily
		"faction": FACTION,
		"body": MACHINE,
		"kit": "drone",
		"phases": true,  # Flies over obstacles (Arena skips it).
		"floating": true,  # Drawn hovering.
		"shot_style": "zap",
	},
	# Soldier: a cyborg rifleman in chrome plate with an amber visor. Marches
	# straight at the necromancer firing three-round bursts from 400 px.
	"line_trooper": {
		"display_name": "Line Trooper",
		"max_hp": 28.0,  # TUNING (not in GDD) a soldier (Footman 36, Archer 22)
		"move_speed": 44.0,  # TUNING (not in GDD) px/s; a steady march
		"damage": 4.0,  # Owner-approved proposal: rifle shots 4-6 damage (before the time scaling)
		"attack_interval": 4.0,  # TUNING (not in GDD) s between bursts (first pass 2.8 s: 3x an Act I archer's fire, the army bot's army fell to 2 by 2:00)
		"attack_range": 400.0,  # Owner-approved proposal: "Long (400 px)"
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD) chrome plate
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 560.0,  # TUNING (not in GDD) px/s rifle round
		"undead_damage_mult": 0.75,  # TUNING (not in GDD) your dead are cover: a round on a summon hurts it less than one on you
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.45,  # TUNING (not in GDD) 0..1; a ranged soldier
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": FACTION,
		"body": CYBORG,
		"kit": "trooper",
		"shot_style": "round",
		"burst_rounds": 3,  # Owner-approved proposal: "three-round bursts"
		"burst_gap": 0.12,  # TUNING (not in GDD) s between two rounds of a burst
		"burst_spread": 0.035,  # TUNING (not in GDD) rad; the rounds fan a little
	},
	# Elite: a long-coated cyborg marksman with a red sensor eye and a long rail
	# rifle. Paints a Lock-On line, then fires the heavy rail shot down it.
	"spotter": {
		"display_name": "Spotter",
		"max_hp": 110.0,  # TUNING (not in GDD) an elite (Siren 120)
		"move_speed": 40.0,  # TUNING (not in GDD) px/s
		"damage": 16.0,  # TUNING (not in GDD) the heavy rail shot (before the time scaling)
		"attack_interval": 6.5,  # TUNING (not in GDD) s between two Lock-On paints
		"attack_range": 520.0,  # Owner-approved proposal: "Very long" (380-520 px)
		"radius": 11.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 16,  # TUNING (not in GDD) an elite's XP
		"behavior": "ranged",
		"projectile_speed": 1150.0,  # TUNING (not in GDD) px/s rail shot
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # Owner-approved proposal: spotters rank high on every summon's target list
		"mass": 1.2,  # TUNING (not in GDD)
		"faction": FACTION,
		"body": CYBORG,
		"kit": "spotter",
		"always_elite": true,  # Owner-approved proposal: tier Elite
		"shot_style": "rail",
		"lock_on": true,
	},
	# The Purge Protocol's kill-drone (Reckoning kind): an armoured drone with a
	# red eye that pours in from every edge once the countdown ends.
	"kill_drone": {
		"display_name": "Kill-Drone",
		"max_hp": 60.0,  # TUNING (not in GDD) before the Reckoning's own growth (Reckoning Inquisitor 70)
		"move_speed": 96.0,  # TUNING (not in GDD) px/s
		"damage": 7.0,  # TUNING (not in GDD) per zap, before the Reckoning's growth
		"attack_interval": 0.9,  # TUNING (not in GDD) s
		"attack_range": 140.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 480.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD)
		"mass": 1.4,  # TUNING (not in GDD)
		"faction": FACTION,
		"body": MACHINE,
		"kit": "drone",
		"phases": true,
		"floating": true,
		"shot_style": "zap",
	},
}
