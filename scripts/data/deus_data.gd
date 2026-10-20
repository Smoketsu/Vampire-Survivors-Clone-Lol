## DeusData — immutable design data for DEUS EX MACHINA, the final boss of Act III
## and of the campaign (the Iron Citadel; GDD §15.0 "The Iron Citadel (Act III
## phase 2)", owner-approved proposal "Necropathy: Act III Proposal (The
## Electronic Empire)", "The final boss: Deus Ex Machina"). A walking fortress the
## height of the screen with the Empire's founder, VARN, THE ROOT USER, wired into
## its core. BossDeusExMachina reads BOSS; StageRegistry.BOSS_ARRIVALS and
## CitadelStage.BOSS read ARRIVAL. Three phases:
##   The Walker     (100% -> siege_hp_fraction): it strides at the necromancer
##                  on four legs, each carrying an armour plate (CitadelEnemyData
##                  "deus_leg_plate") the army breaks one by one, like Vhal'Neth's
##                  arms. While a plate stands the body is armoured
##                  (plated_damage_taken) and never falls below
##                  siege_hp_fraction; each plate broken wounds it (plate_wound).
##                  Breaking all four brings it to its knees: phase 2. Attacks:
##                  the CHAINGUN SWEEP (a long arc of fire through EmpireShots:
##                  Line of Fire applies, the army standing between shields him),
##                  the MISSILE SALVO (four Lock-On lines at once through
##                  LockOn's boss_override, then the rockets), FOOTFALLS (a
##                  shockwave ring under each foot as it lands) and a heavy STOMP
##                  when the army crowds its legs.
##   The Siege Core (-> founder_hp_fraction): it plants itself and becomes a
##                  fortress. SHIELD DRONES (CitadelEnemyData "deus_shield_drone")
##                  orbit it and make the core immune until they are all shot
##                  down; then it is exposed for exposed_time s and redeploys
##                  them. The JUDGMENT LANCE: a huge telegraphed beam that sweeps
##                  the arena; the first summon standing in the beam takes the
##                  hit and the necromancer is safe behind it. HANGAR DOORS open
##                  and release Line Troopers and Valkyrie Duelists.
##   The Founder    (-> 0): the core cracks open and Varn's mind takes the whole
##                  frame. OVERLOAD PULSES roll out every few seconds, each one
##                  stronger (the fight's clock), and it TELEPORTS in short
##                  bursts and fires everything at once (a ring of fire, two
##                  missiles, a stomp).
## When it falls the necromancer tears Varn's soul from the broken core: the
## banner "Nothing is deathless. Everything is mine." (owner-approved proposal),
## the ending text, and the Empire's machines go dark around him.
## The GDD gives no numbers: everything is TUNING (not in GDD) unless tagged.
class_name DeusData
extends RefCounted

## Its special ability ids in report order (the autotest "boss attacks" line
## reads the boss_atk_<id> stats).
const SPECIALS := ["chaingun", "salvo", "footfall", "stomp", "lance", "hangar", "drones", "pulse", "teleport"]

## Offsets (px, world axes, from the body centre) of the four legs: front left,
## front right, rear left, rear right. Each carries a plate in the Walker phase;
## footfalls land here.
const LEGS := [Vector2(-50.0, -6.0), Vector2(50.0, -6.0), Vector2(-42.0, 30.0), Vector2(42.0, 30.0)]  # TUNING (not in GDD) art-matched

## Boss row: Enemy row keys plus its ability numbers (see the header).
const BOSS := {
	"display_name": "Deus Ex Machina",
	"max_hp": 20000.0,  # TUNING (not in GDD) x the stage HP multiplier (27,000 in the Citadel; Vhal'Neth 24,000 on Ul-Thalos), a 1-2 min fight for a strong army (proposal)
	"move_speed": 30.0,  # TUNING (not in GDD) px/s: a slow, heavy stride (the Walker)
	"damage": 14.0,  # TUNING (not in GDD) a kick of a leg in melee reach
	"attack_interval": 1.6,  # TUNING (not in GDD)
	"attack_range": 14.0,  # TUNING (not in GDD)
	"radius": 40.0,  # TUNING (not in GDD) px: the hull (drawn far bigger)
	"armor": 0.15,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 0.7,  # TUNING (not in GDD) its chaingun rounds and missiles on a summon (your dead are cover)
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 40.0,  # TUNING (not in GDD) a walking fortress shoves anything
	"slow_resist": 0.8,  # TUNING (not in GDD)
	"reward_xp": 700,  # TUNING (not in GDD) the campaign's last boss: more than Vhal'Neth's 600
	"reward_crystals": 30,  # TUNING (not in GDD)
	"arrive_time": 2.5,  # TUNING (not in GDD) s its descent takes (it lands, nothing attacks yet)
	# Phases.
	"siege_hp_fraction": 0.66,  # Owner-approved proposal: "The Walker (100% to 66% HP)"
	"founder_hp_fraction": 0.33,  # Owner-approved proposal: "The Siege Core (66% to 33%)"
	"phase_time": 2.2,  # TUNING (not in GDD) s of a phase change (invulnerable, it transforms)
	"siege_banner": "DEUS EX MACHINA KNEELS: the Siege Core plants itself!",  # TUNING (not in GDD)
	"founder_banner": "THE CORE CRACKS OPEN: Varn, the Root User, takes the frame!",  # TUNING (not in GDD)
	"attack_gap": 3.0,  # TUNING (not in GDD) s between two specials (Walker, Founder)
	"first_special": 3.0,  # TUNING (not in GDD) s after it lands
	# The Walker: leg plates.
	"plate_hp": 0.045,  # TUNING (not in GDD) fraction of its max HP per leg plate
	"plate_wound": 0.06,  # TUNING (not in GDD) fraction of its max HP each plate broken takes off it
	"plated_damage_taken": 0.35,  # TUNING (not in GDD) the body's damage taken while a plate stands
	# The Walker: chaingun sweep (EmpireShots style "chaingun").
	"chaingun_telegraph": 0.9,  # TUNING (not in GDD) s the swept arc is shown first
	"chaingun_arc": 2.1,  # TUNING (not in GDD) rad swept (about 120 degrees)
	"chaingun_time": 2.2,  # TUNING (not in GDD) s the sweep takes
	"chaingun_gap": 0.07,  # TUNING (not in GDD) s between two rounds
	"chaingun_damage": 3.0,  # TUNING (not in GDD) per round, before the time scaling (Line Trooper 4)
	"chaingun_speed": 640.0,  # TUNING (not in GDD) px/s
	"chaingun_range": 600.0,  # TUNING (not in GDD) px
	# The Walker: missile salvo (LockOn boss_override, style "missile").
	"salvo_lines": 4,  # Owner-approved proposal: "four Lock-On lines at once"
	"salvo_paint": 1.8,  # TUNING (not in GDD) s the lines are painted (Spotters 1.5)
	"salvo_damage": 13.0,  # TUNING (not in GDD) per missile, before the time scaling
	"salvo_speed": 720.0,  # TUNING (not in GDD) px/s
	"salvo_range": 720.0,  # TUNING (not in GDD) px
	# The Walker: footfalls and the heavy stomp.
	"footfall_interval": 1.4,  # TUNING (not in GDD) s between two footfalls while it walks (alternating legs)
	"footfall_telegraph": 0.6,  # TUNING (not in GDD) s
	"footfall_radius": 56.0,  # TUNING (not in GDD) px
	"footfall_damage_player": 7.0,  # TUNING (not in GDD) before the time scaling
	"footfall_damage_summon": 6.0,  # TUNING (not in GDD)
	"footfall_knockback": 34.0,  # TUNING (not in GDD) px summons are thrown out of the ring
	"stomp_trigger": 130.0,  # TUNING (not in GDD) px: the necromancer this close (or 4+ summons) makes it stomp
	"stomp_telegraph": 0.9,  # TUNING (not in GDD) s
	"stomp_radius": 110.0,  # TUNING (not in GDD) px around each front foot
	"stomp_damage_player": 13.0,  # TUNING (not in GDD)
	"stomp_damage_summon": 12.0,  # TUNING (not in GDD)
	"stomp_knockback": 64.0,  # TUNING (not in GDD) px
	"stomp_cooldown": 8.0,  # TUNING (not in GDD) s
	# The Siege Core: shield drones.
	"drones": 6,  # TUNING (not in GDD)
	"drone_hp": 0.022,  # TUNING (not in GDD) fraction of its max HP per drone
	"drone_orbit": 120.0,  # TUNING (not in GDD) px from the core
	"drone_speed": 0.8,  # TUNING (not in GDD) rad/s around the core
	"exposed_time": 14.0,  # TUNING (not in GDD) s the core stays open once every drone is down
	"exposed_damage_taken": 1.25,  # TUNING (not in GDD) the open core is the weak point
	"redeploy_time": 1.5,  # TUNING (not in GDD) s the new drones take to launch (the core is still open)
	# The Siege Core: Judgment Lance.
	"lance_first": 3.0,  # TUNING (not in GDD) s into the phase
	"lance_interval": 10.0,  # TUNING (not in GDD) s
	"lance_telegraph": 1.5,  # TUNING (not in GDD) s the swept arc and beam path are shown first
	"lance_arc": 1.4,  # TUNING (not in GDD) rad swept (about 80 degrees)
	"lance_time": 2.4,  # TUNING (not in GDD) s the sweep takes
	"lance_reach": 760.0,  # TUNING (not in GDD) px: "a huge beam that sweeps the arena"
	"lance_width": 30.0,  # TUNING (not in GDD) px
	"lance_damage_player": 22.0,  # TUNING (not in GDD) once per sweep, before the time scaling
	"lance_damage_summon": 6.0,  # TUNING (not in GDD) per tick on the summon standing in the beam
	"lance_tick": 0.3,  # TUNING (not in GDD) s between two hits on the summon in the beam
	# The Siege Core: hangar doors.
	"hangar_first": 6.0,  # TUNING (not in GDD) s into the phase
	"hangar_interval": 13.0,  # TUNING (not in GDD) s
	"hangar_telegraph": 1.0,  # TUNING (not in GDD) s the doors glow before they open
	"hangar_offset": 64.0,  # TUNING (not in GDD) px the two doors sit either side of the core
	"hangar_groups": [{"kind": "line_trooper", "count": 3, "elite": false}, {"kind": "valkyrie_duelist", "count": 1, "elite": false}],  # Owner-approved proposal: "release Line Troopers and Valkyrie Duelists"
	# The Founder: overload pulses and teleports.
	"founder_damage_taken": 1.15,  # TUNING (not in GDD) the cracked core
	"founder_speed": 26.0,  # TUNING (not in GDD) px/s it drags itself between teleports
	"pulse_first": 3.0,  # TUNING (not in GDD) s into the phase
	"pulse_interval": 5.5,  # TUNING (not in GDD) s between pulses at first ...
	"pulse_interval_step": 0.35,  # TUNING (not in GDD) ... shorter by this for every pulse ...
	"pulse_interval_min": 3.0,  # TUNING (not in GDD) ... down to this
	"pulse_charge": 0.8,  # TUNING (not in GDD) s it glows before the pulse rolls out (the telegraph)
	"pulse_speed": 260.0,  # TUNING (not in GDD) px/s the ring rolls out
	"pulse_reach": 470.0,  # TUNING (not in GDD) px: beyond it the pulse fades
	"pulse_front": 26.0,  # TUNING (not in GDD) px thick wave front
	"pulse_damage_player": 6.0,  # TUNING (not in GDD) the first pulse, before the time scaling ...
	"pulse_damage_summon": 8.0,  # TUNING (not in GDD)
	"pulse_growth": 0.2,  # Owner-approved proposal "each one stronger": +20% per pulse ...
	"pulse_growth_max": 3.0,  # TUNING (not in GDD) ... up to x3
	"teleport_first": 4.0,  # TUNING (not in GDD) s into the phase
	"teleport_interval": 8.0,  # TUNING (not in GDD) s
	"teleport_glow": 0.9,  # TUNING (not in GDD) s the destination glows first
	"teleport_min": 220.0,  # TUNING (not in GDD) px from the necromancer
	"teleport_max": 320.0,  # TUNING (not in GDD) px
	"volley_rounds": 20,  # TUNING (not in GDD) chaingun rounds in the ring it fires on arrival ("fires everything at once")
	"volley_missiles": 2,  # TUNING (not in GDD) Lock-On lines painted on arrival
	"volley_stomp_radius": 100.0,  # TUNING (not in GDD) px of the stomp ring on arrival
	# The ending.
	"machines_dark_radius": 900.0,  # TUNING (not in GDD) px: its machines within this go dark when it falls (proposal "his machines go dark")
	"finale_time": 6.0,  # TUNING (not in GDD) s the finale draws (the run goes on)
}

## Its arrival (keys as GraveyardStage.BOSS): StageRegistry.BOSS_ARRIVALS and
## CitadelStage.BOSS. The defeat banner is the owner-approved ending line.
const ARRIVAL := {
	"id": "deus_ex_machina",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Deus Ex Machina",
	"short_name": "Deus Ex Machina",
	"arrive_banner": "Deus Ex Machina descends, Varn, the Root User, at the controls!",  # TUNING (not in GDD)
	"defeat_banner": "Nothing is deathless. Everything is mine.",  # Owner-approved proposal: the banner when it falls
	"dead_objective": "The god of steel is yours. Survive until the countdown ends.",  # TUNING (not in GDD)
}

## Seconds the ending line (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## HUD announcement on its death (title, line, description): the proposal's
## ending ("the necromancer reaches into the broken core and finds the one thing
## the Empire forgot to delete: Varn's soul").
const ENDING_ANNOUNCE := ["NOTHING IS DEATHLESS", "Everything is mine.", "You reach into the broken core and take the one thing the Empire forgot to delete: Varn's soul. His machines go dark across the realm."]  # Owner-approved proposal ending
## Shorter announcement when it falls after 0:00 (the Purge Protocol rages on).
const LATE_ANNOUNCE := ["THE GOD OF STEEL FALLS", "Everything is mine.", "Even under the Purge, Varn's soul is yours."]  # TUNING (not in GDD)
## Radius (px) of the soul-binding rings of the finale (drawing only).
const BINDING_RADIUS: float = 220.0  # TUNING (not in GDD)
