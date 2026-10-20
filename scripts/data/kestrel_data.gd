## KestrelData — immutable design data for KESTREL, THE DEAD PIXEL, the boss of
## the Scrap Wastes (Act III, Stage 7; GDD §15.0 "The Scrap Wastes (Act III
## phase 2)"; owner-approved proposal: "the Empire's sniper commander, a cyborg
## markswoman (figure-redesign style) who never misses by a single pixel. She
## jumps between sniper perches, fires triple Lock-On lines, releases decoy
## drones, and in her last phase drops the rifle for twin blades and
## charges"). BossKestrel (scripts/enemies/empire/boss_kestrel.gd, loaded by
## name for the boss id "kestrel") reads it. Three parts of one fight:
##   * Marksman (100% to decoy_hp): she walks in firing three-round rifle
##     bursts (EmpireShots: Line of Fire, the army is your cover) and every
##     perch_gap s leaps to a sniper PERCH (a telegraphed landing marker)
##     perch_min..perch_max px from the necromancer, where she paints a TRIPLE
##     Lock-On (three lines through LockOn's boss override, staggered so one
##     Grave Step does not dodge them all), then holds the perch for perch_time s.
##   * Decoys (decoy_hp to blades_hp): the same, and every decoy_interval s she
##     releases decoy_count Decoy Drones (WastesEnemyData "kestrel_decoy": a
##     hologram of her that draws the army's fire).
##   * Twin Blades (below blades_hp): she drops the rifle (draw_time s), moves
##     faster, slashes in reach, and CHARGES along a telegraphed lane; a
##     blocker heavy enough (block_mass >= charge_block_mass: Warriors, the
##     Golem, Abominations) stops the charge cold.
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist, recover_time, advance_range,
## advance_speed_mult) and the abilities' own numbers below. The GDD gives no
## numbers: everything is TUNING (not in GDD) unless marked as the
## owner-approved proposal.
class_name KestrelData
extends RefCounted

## Kestrel's arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "kestrel" through WastesStage.BOSS, so --boss=kestrel and the Codex find her).
const ARRIVAL := {
	"id": "kestrel",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Kestrel, the Dead Pixel",  # Owner-approved proposal (boss names: "puns on the machine stuff")
	"short_name": "Kestrel",
	"arrive_banner": "Kestrel, the Dead Pixel, drops in: she never misses by a single pixel!",  # TUNING (not in GDD)
	"defeat_banner": "Kestrel goes dark: SIGNAL LOST. Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "The Dead Pixel is deleted. Survive until the countdown ends.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["perch", "triple_lock", "decoys", "charge"]

## Kestrel's design row.
const BOSS := {
	"display_name": "Kestrel, the Dead Pixel",
	"max_hp": 17000.0,  # TUNING (not in GDD) x the stage HP multiplier (21,250 on the Wastes); Merrow 26,000, Vhal'Neth 20,000: she is mobile (perches) and her decoys draw the army's fire (pass 2: 21,000 survived an army run with 7,800 HP left)
	"move_speed": 54.0,  # TUNING (not in GDD) px/s walking with the rifle
	"damage": 10.0,  # TUNING (not in GDD) a rifle-butt blow in reach
	"attack_interval": 1.1,  # TUNING (not in GDD) s
	"attack_range": 8.0,  # TUNING (not in GDD) px
	"radius": 16.0,  # TUNING (not in GDD) px; slim
	"armor": 0.15,  # TUNING (not in GDD) chrome plating
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss (her decoys outrank her: 1.0)
	"mass": 6.0,  # TUNING (not in GDD) lighter than the other bosses, she still shoves warriors
	"body": EmpireEnemyData.CYBORG,  # Owner-approved proposal: "a cyborg markswoman"
	"faction": EmpireEnemyData.FACTION,
	"reward_xp": 540,  # TUNING (not in GDD) between Merrow's 520 and the Act III finale
	"reward_crystals": 24,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.6,  # TUNING (not in GDD) s she stands after a charge
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this she strides faster
	"advance_speed_mult": 1.6,  # TUNING (not in GDD)
	# Rifle (Marksman and Decoys): marching fire at the necromancer while she
	# walks, through EmpireShots (Line of Fire: the army is your cover).
	"rifle_interval": 2.2,  # TUNING (not in GDD) s between bursts
	"rifle_rounds": 3,  # TUNING (not in GDD) rounds per burst (the Line Trooper's three)
	"rifle_gap": 0.1,  # TUNING (not in GDD) s between two rounds
	"rifle_spread": 0.03,  # TUNING (not in GDD) rad the rounds fan by
	"rifle_damage": 5.0,  # TUNING (not in GDD) per round, before the time scaling (proposal: rifle shots 4-6)
	"rifle_speed": 640.0,  # TUNING (not in GDD) px/s
	"rifle_range": 480.0,  # TUNING (not in GDD) px
	# Perches: every perch_gap s of walking she leaps to a sniper perch (a
	# landing marker telegraphed leap_windup s), flying leap_time s; there she
	# paints the triple Lock-On and holds for perch_time s.
	"first_perch": 2.5,  # TUNING (not in GDD) s after arrival before her first perch
	"perch_gap": 6.5,  # TUNING (not in GDD) s of walking between two perches (pass 3: 5.0)
	"perch_min": 230.0,  # TUNING (not in GDD) px from the necromancer: inside the army's reach (pass 3: 360-460 left her out of it, 9,000 HP left at the end)
	"perch_max": 300.0,  # TUNING (not in GDD) px
	"perch_turn_min": 0.7,  # TUNING (not in GDD) rad the perch moves around him at least
	"perch_turn_max": 1.5,  # TUNING (not in GDD) rad at most
	"leap_windup": 0.6,  # TUNING (not in GDD) s the landing marker shows before she jumps
	"leap_time": 0.55,  # TUNING (not in GDD) s in the air
	"leap_height": 46.0,  # TUNING (not in GDD) px the drawn arc rises (visual only)
	"perch_time": 4.0,  # TUNING (not in GDD) s she holds the perch (the army's window to reach her)
	# Triple Lock-On (owner-approved "fires triple Lock-On lines"): three lines
	# at once through LockOn's boss override, two on the necromancer and one
	# on the summon nearest him (or a third on him when he stands alone),
	# painted lock_paint_1..3 s so the rails come one after another.
	"lock_paint_1": 1.4,  # TUNING (not in GDD) s (the shared Spotter paint is 1.5)
	"lock_paint_2": 1.9,  # TUNING (not in GDD) s
	"lock_paint_3": 2.4,  # TUNING (not in GDD) s
	"lock_damage": 18.0,  # TUNING (not in GDD) per rail, before the time scaling (Spotter 16)
	"lock_speed": 1250.0,  # TUNING (not in GDD) px/s rail speed
	"lock_reach": 620.0,  # TUNING (not in GDD) px (past the perch distance)
	# Decoys (owner-approved "releases decoy drones").
	"decoy_hp": 0.65,  # TUNING (not in GDD) HP share below which she uses decoys
	"decoy_interval": 14.0,  # TUNING (not in GDD) s between two releases
	"decoy_count": 3,  # TUNING (not in GDD) drones per release
	"decoy_cast": 0.6,  # TUNING (not in GDD) s she stands releasing them
	"decoy_banner": "Kestrel releases decoy drones: your dead fire at holograms!",  # TUNING (not in GDD)
	# Twin Blades (owner-approved "in her last phase drops the rifle for twin
	# blades and charges").
	"blades_hp": 0.3,  # TUNING (not in GDD) HP share below which she draws the blades
	"draw_time": 1.2,  # TUNING (not in GDD) s she stands drawing them
	"blades_banner": "Kestrel drops the rifle: TWIN BLADES! Put a blocker in her path!",  # TUNING (not in GDD)
	"blade_speed": 112.0,  # TUNING (not in GDD) px/s (fast)
	"blade_damage": 15.0,  # TUNING (not in GDD) a slash in reach
	"blade_interval": 0.55,  # TUNING (not in GDD) s between slashes
	"charge_cooldown": 4.5,  # TUNING (not in GDD) s
	"charge_min": 110.0,  # TUNING (not in GDD) px; charges at a necromancer this far ...
	"charge_max": 420.0,  # TUNING (not in GDD) px ... up to this far
	"charge_length": 380.0,  # TUNING (not in GDD) px (cut short by obstacles)
	"charge_width": 40.0,  # TUNING (not in GDD) px
	"charge_telegraph": 0.85,  # TUNING (not in GDD) s
	"charge_speed": 780.0,  # TUNING (not in GDD) px/s
	"charge_damage_player": 20.0,  # TUNING (not in GDD) before the time scaling
	"charge_damage_summon": 24.0,  # TUNING (not in GDD) before the time scaling
	"charge_push": 40.0,  # TUNING (not in GDD) px summons in the lane are thrown aside
	"charge_block_mass": 3.0,  # TUNING (not in GDD) a summon this heavy stops the charge (the Templar's rule)
	"charge_stagger": 0.7,  # TUNING (not in GDD) s she stands after a blocked charge
}
