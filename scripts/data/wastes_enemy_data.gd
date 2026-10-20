## WastesEnemyData — immutable design data for the Electronic Empire kinds that join
## on the Scrap Wastes (Stage 7) (Act III; GDD §15.0 "Act III foundation (phase 1)"
## and "The Scrap Wastes (Act III phase 2)"; owner-approved proposal "Necropathy:
## Act III Proposal (The Electronic Empire)"):
##   aegis_bot      — Aegis Bot (soldier, a MACHINE, melee): a squat chrome walker
##                    behind a frontal energy shield that stops your projectiles
##                    (AegisKit, Enemy.shield_blocks()). Hit it from the side or
##                    above, with area spells or stomps; the shield breaks after
##                    absorbing enough and comes back a few seconds later.
##   mortar_walker  — Mortar Walker (heavy, a MACHINE, long range): a four-legged
##                    walker that lobs arcing shells onto a landing circle
##                    (MortarKit through EmpireKit.fire_arc_at(): arcing shots
##                    ignore Line of Fire, so keep moving).
## and the stage's objects and specials:
##   signal_pylon   — Signal Pylon (structure, a MACHINE): while it stands, Empire
##                    shooters near it fire from 30% farther; destroyed, it pays a
##                    Soul Ash bounty and their range in that area SHRINKS for the
##                    rest of the run (WastesDirector.reach_mult_at(), read by
##                    EmpireKit's reach: one path).
##   trojan_horse   — the Trojan Horse: the stage miniboss (9:00 left), a
##                    four-legged drone tank with missile pods (TrojanKit): slow
##                    homing rockets your summons can intercept, a stomp, and at
##                    low HP its hull splits open and Scout Drones pour out.
##   trojan_rocket  — Swarm Rocket: one of the Trojan Horse's rockets (RocketKit):
##                    a slow homing missile that bursts on the first body it
##                    touches (a summon in its path intercepts it), and that your
##                    summons can shoot down. A MACHINE; no XP.
##   kestrel_decoy  — Decoy Drone: Kestrel's hologram projector (DecoyKit): a
##                    hovering drone that shows a false Kestrel, draws your army's
##                    fire (top target priority) and plinks at it for a while.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.empire_def() looks these rows up after
## EmpireEnemyData. Rows have every key of an EmpireEnemyData.ENEMIES row (same
## meaning; "kit" ids load scripts/enemies/empire/<kit>_kit.gd; "body" is
## "machine" or "cyborg") plus their kit's numbers (documented on each kit and
## row). The GDD gives no numbers: everything is TUNING (not in GDD) unless
## marked as the owner-approved proposal.
class_name WastesEnemyData
extends RefCounted

## Kind id of the Signal Pylon (WastesDirector places them).
const PYLON: String = "signal_pylon"
## Kind id of the Trojan Horse (the stage miniboss).
const TROJAN: String = "trojan_horse"
## Kind id of a Swarm Rocket (the Trojan Horse launches them).
const ROCKET: String = "trojan_rocket"
## Kind id of a Decoy Drone (Kestrel releases them).
const DECOY: String = "kestrel_decoy"

## Kind id -> design row.
const ENEMIES := {
	# Soldier: a squat two-legged chrome walker carrying a big glowing energy
	# shield in front. It walks in front of the riflemen (enemies always
	# advance) and soaks your arrows and bolts from the front.
	"aegis_bot": {
		"display_name": "Aegis Bot",
		"max_hp": 38.0,  # TUNING (not in GDD) a soldier behind its shield (Footman 36; first pass 44 piled up 45 alive by 5:00)
		"move_speed": 48.0,  # TUNING (not in GDD) px/s; it keeps pace with the Line Troopers it screens
		"damage": 5.0,  # TUNING (not in GDD) a shield bash in contact, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 6.0,  # TUNING (not in GDD) px edge to edge
		"radius": 11.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 2,  # TUNING (not in GDD) a soldier's XP (a pass at 1 starved the army: the army bot died at 5:00-6:00 in 2 of 2 runs)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.35,  # TUNING (not in GDD) 0..1, a soldier
		"mass": 1.8,  # TUNING (not in GDD) heavier than a trooper: it leans into the warriors
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"kit": "aegis",
		# The frontal shield (AegisKit): every friendly PROJECTILE (arrows, bolts,
		# orbs, volley shots) arriving within shield_half_angle of its facing
		# (toward the necromancer) is stopped by the shield, which loses the
		# shot's damage from its shield HP; at 0 it breaks for shield_recharge s.
		# Melee, area spells, beams and stomps ignore it.
		"shield_hp": 16.0,  # TUNING (not in GDD) shield HP at 0:00, scaled with the bot's own HP (time scaling, elites); first pass 34 left the early army unable to break a line, 22 absorbed 150k damage in an army run
		"shield_half_angle": 1.05,  # TUNING (not in GDD) rad each side of its facing (about 120 degrees in all): "frontal"
		"shield_recharge": 6.0,  # TUNING (not in GDD) s a broken shield stays down
		"shield_turn": 3.0,  # TUNING (not in GDD) rad/s the shield turns toward the necromancer
	},
	# Heavy: a low four-legged chrome walker with a stubby mortar tube on its
	# back. It walks on (enemies always advance) and lobs shells high over the
	# army onto a red landing circle.
	"mortar_walker": {
		"display_name": "Mortar Walker",
		"max_hp": 150.0,  # TUNING (not in GDD) a heavy (Spawn of the Deep 260 is a melee bruiser)
		"move_speed": 30.0,  # TUNING (not in GDD) px/s; a slow walker
		"damage": 7.0,  # TUNING (not in GDD) per shell burst, before the time scaling (first pass 9 x 0.9: shells dealt the army as much as all the Line Troopers)
		"attack_interval": 5.5,  # TUNING (not in GDD) s between shells
		"attack_range": 470.0,  # TUNING (not in GDD) px; "long, arcing" (the riflemen fire from 400)
		"radius": 15.0,  # TUNING (not in GDD) px
		"armor": 0.25,  # TUNING (not in GDD) chrome plate
		"xp": 5,  # TUNING (not in GDD) a heavy's XP
		"behavior": "ranged",
		"projectile_speed": 0.0,  # Shells fly on a fixed flight time (mortar_flight).
		"undead_damage_mult": 0.7,  # TUNING (not in GDD) a shell lands in the packed Bone Ring: each summon in the splash takes less
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1, a heavy behind the line
		"mass": 3.0,  # TUNING (not in GDD)
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"kit": "mortar",
		"shot_style": "mortar",  # EmpireRulesData.SHOT_STYLES: arcing, splash 48 px, a landing circle
		"mortar_flight": 1.5,  # TUNING (not in GDD) s from the tube to the landing circle
		"mortar_lead": 0.6,  # TUNING (not in GDD) fraction of the flight a moving target is led by
	},
	# Structure: a tall chrome signal mast on a tripod, a red beacon at its tip
	# and amber dishes. While it stands the Empire's guns reach farther around it.
	"signal_pylon": {
		"display_name": "Signal Pylon",
		"max_hp": 300.0,  # TUNING (not in GDD) before the time / stage scaling (a dream pillar 520)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 16.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is WastesDirector's XP burst and Soul Ash bounty.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) worth breaking
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"kit": "pylon",
	},
	# The miniboss: a four-legged drone tank, chrome hull, missile pods on its
	# back and a red sensor eye. Its hull opens at low HP and Scout Drones pour out.
	"trojan_horse": {
		"display_name": "The Trojan Horse",
		"max_hp": 2600.0,  # TUNING (not in GDD) before the time / stage scaling (the Harbourmaster 1700)
		"move_speed": 34.0,  # TUNING (not in GDD) px/s; a slow, heavy walker
		"damage": 14.0,  # TUNING (not in GDD) a hoof kick in reach
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px edge to edge
		"radius": 28.0,  # TUNING (not in GDD) px
		"armor": 0.25,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is the XP burst below.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers prioritise it like a boss
		"mass": 14.0,  # TUNING (not in GDD) shoves warriors aside
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"kit": "trojan",
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"reward_xp": 170,  # TUNING (not in GDD) XP burst on death (the Harbourmaster's)
		"reward_crystals": 12,  # TUNING (not in GDD)
		# Walking (TrojanKit): it never kites and is never left behind.
		"advance_range": 520.0,  # TUNING (not in GDD) px beyond which it strides faster
		"advance_speed_mult": 1.8,  # TUNING (not in GDD)
		"first_special": 3.0,  # TUNING (not in GDD) s after arriving before its first special
		"attack_gap": 2.2,  # TUNING (not in GDD) s between two specials
		"recover_time": 0.5,  # TUNING (not in GDD) s it stands after a special
		# Rocket volley: the pods glow for volley_telegraph s, then volley_rockets
		# Swarm Rockets launch fanned over volley_spread rad, curving onto the
		# necromancer (RocketKit). Owner-approved proposal: "slow homing rockets
		# your summons can intercept".
		"volley_cooldown": 7.5,  # TUNING (not in GDD) s
		"volley_telegraph": 0.8,  # TUNING (not in GDD) s
		"volley_rockets": 4,  # TUNING (not in GDD) rockets per volley
		"volley_spread": 1.6,  # TUNING (not in GDD) rad over which the rockets fan out at launch
		"volley_range": 620.0,  # TUNING (not in GDD) px; fires while the necromancer is this close
		# Stomp: a circle around it for stomp_telegraph s, then its hooves come
		# down: summons inside are hurt and pushed out, the necromancer hit.
		"stomp_cooldown": 6.0,  # TUNING (not in GDD) s
		"stomp_range": 110.0,  # TUNING (not in GDD) px; stomps when the necromancer or 3+ summons are this close
		"stomp_min_summons": 3,  # TUNING (not in GDD) summons inside stomp_range that make a stomp worth it
		"stomp_radius": 100.0,  # TUNING (not in GDD) px
		"stomp_telegraph": 0.9,  # TUNING (not in GDD) s
		"stomp_damage_summon": 18.0,  # TUNING (not in GDD) before the time scaling
		"stomp_damage_player": 14.0,  # TUNING (not in GDD) before the time scaling
		"stomp_push": 55.0,  # TUNING (not in GDD) px summons are thrown out
		# Hull split (owner-approved proposal: "Badly damaged, its hull splits
		# open and a swarm of Scout Drones pours out"): once, below split_hp.
		"split_hp": 0.4,  # TUNING (not in GDD) fraction of its max HP
		"split_drones": 12,  # TUNING (not in GDD) Scout Drones released
		"split_volley_mult": 0.6,  # TUNING (not in GDD) x the volley cooldown once split
		"split_rockets": 6,  # TUNING (not in GDD) rockets per volley once split
	},
	# One of the Trojan Horse's rockets: a stubby chrome missile with an amber
	# warhead light and a short flame. Slow, homing, and fragile.
	"trojan_rocket": {
		"display_name": "Swarm Rocket",
		"max_hp": 10.0,  # TUNING (not in GDD) one arrow or bolt brings it down (time-scaled)
		"move_speed": 105.0,  # TUNING (not in GDD) px/s; "slow" (a rifle round flies 560)
		"damage": 10.0,  # TUNING (not in GDD) burst damage to the necromancer, before the time scaling
		"attack_interval": 99.0,  # Unused: it bursts on contact (RocketKit).
		"attack_range": 0.0,
		"radius": 6.0,  # TUNING (not in GDD) px
		"armor": 0.0,
		"xp": 0,  # A rocket shot down drops nothing.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.4,  # TUNING (not in GDD) x on a summon that intercepts it (14 before the time scaling)
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) summons shoot rockets down before they land
		"mass": 0.3,  # TUNING (not in GDD)
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"kit": "rocket",
		"phases": true,  # Flies over obstacles.
		"floating": true,
		"rocket_turn": 1.7,  # TUNING (not in GDD) rad/s it curves toward the necromancer ("homing", but slowly)
		"rocket_life": 7.0,  # TUNING (not in GDD) s before it bursts on its own
		"rocket_splash": 34.0,  # TUNING (not in GDD) px burst radius
		"rocket_arm": 0.3,  # TUNING (not in GDD) s after launch before it can burst (clears the pods)
	},
	# Kestrel's decoy: a small chrome projector drone that shows a flickering
	# hologram of her. Your army shoots the hologram first.
	"kestrel_decoy": {
		"display_name": "Decoy Drone",
		"max_hp": 60.0,  # TUNING (not in GDD) before the time scaling (the boss's decoys are not scaled by her HP); pass 2: 80 -> 60
		"move_speed": 62.0,  # TUNING (not in GDD) px/s
		"damage": 3.0,  # TUNING (not in GDD) per round, before the time scaling
		"attack_interval": 2.4,  # TUNING (not in GDD) s between bursts
		"attack_range": 380.0,  # TUNING (not in GDD) px
		"radius": 13.0,  # TUNING (not in GDD) px (the hologram's body)
		"armor": 0.0,
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "ranged",
		"projectile_speed": 540.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 1.0,  # Owner-approved proposal "decoy drones": they draw your army's fire first
		"mass": 0.8,  # TUNING (not in GDD)
		"faction": EmpireEnemyData.FACTION,
		"body": EmpireEnemyData.MACHINE,
		"kit": "decoy",
		"phases": true,
		"floating": true,
		"shot_style": "round",
		"burst_rounds": 2,  # TUNING (not in GDD)
		"burst_gap": 0.15,  # TUNING (not in GDD) s
		"burst_spread": 0.05,  # TUNING (not in GDD) rad
		"decoy_life": 16.0,  # TUNING (not in GDD) s before it fizzles out (despawned, no kill)
	},
}

## Damage sources of the Scrap Wastes' kinds and Kestrel that are RANGED hits
## although their tag is not a "ranged" kind id (Lead-Lined Bones,
## CombatResolver.is_ranged_source(); every kind whose row has behavior
## "ranged" counts already, its shots being tagged with its kind id). The
## Spotter's rail is the shared kinds' and "archer_arrow" a Covenant archer's arrow
## (ProjectileManager's default tag), listed here so the passive covers them.
const RANGED_EXTRA_SOURCES := ["trojan_rocket", "kestrel_rail", "kestrel_rifle", "spotter_rail", "archer_arrow"]
