## AchillesData — immutable design data for ACHILLES, THE UNKILLABLE, the boss of
## the Shores of Ilion (Act IV, Stage 10; GDD §15.0 "The Shores of Ilion (Act IV
## phase 2)"; owner-approved proposal docs/act4/PROPOSAL.md: "Hits to his front
## deal 10%; hits from behind (or to his heel: a gold mark under him) deal full
## damage and stagger him. The Bone Ring surrounding him is the answer, and
## Rogue dashes and Gargoyle dives shine. Phases: the duel, the Myrmidon charge
## (he summons his guard), the rage after Patroclus (a fast, wild last phase)").
## BossAchilles (scripts/enemies/pantheon/boss_achilles.gd, loaded by name for
## the boss id "achilles") reads it. Three parts of one fight:
##   * The Duel (100% to guard_hp): he walks at the necromancer behind his
##     shield, turning slowly (turn_rate) to keep his front on what he fights,
##     and every lunge_cooldown s LUNGES along a telegraphed lane with his
##     spear (summons in the lane are thrown aside: the Unkillable is not
##     stopped).
##   * The Myrmidon Charge (guard_hp to rage_hp): he calls his guard, a squad of
##     guard_count Hoplites in a shield wall in front of him (guard_elites of
##     them elite), and again every guard_interval s while fewer than
##     guard_max_alive of them stand; he keeps lunging.
##   * The Rage after Patroclus (below rage_hp): helmet and shield gone, he moves
##     rage_speed_mult faster, strikes rage_attack_mult as often, lunges twice
##     in a row (rage_lunges), whirls his spear in a telegraphed circle
##     (whirl_*) and his guard is down: his front takes rage_front_mult.
## THE HEEL (the one directional rule, BossAchilles.directed_hit_mult(), asked
## by PantheonRules.directed_hit_mult() from CombatResolver.damage_enemy()):
##   front (within front_half_angle of his facing)      -> front_mult (10%)
##   back (within back_half_angle of straight behind),
##   or a hit from within heel_radius of the heel mark  -> full, and a STAGGER
##     (he stands stagger_time s and cannot turn; at most every stagger_cooldown s)
##   the flanks between                                 -> flank_mult
##   undirected hits (area spells, stomps, damage over
##   time) and arcing hits from above                   -> undirected_mult
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist, recover_time, advance_range,
## advance_speed_mult) and the abilities' own numbers below. The GDD gives no
## numbers: everything is TUNING (not in GDD) unless marked as the
## owner-approved proposal.
class_name AchillesData
extends RefCounted

## Achilles' arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "achilles" through IlionStage.BOSS, so --boss=achilles and the Codex find him).
const ARRIVAL := {
	"id": "achilles",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Achilles, the Unkillable",  # Owner-approved proposal
	"short_name": "Achilles",
	"arrive_banner": "Achilles, the Unkillable, leaps from the ships: strike him from behind!",  # TUNING (not in GDD)
	"defeat_banner": "Achilles falls, struck at the heel! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Achilles is dead. Survive until the countdown ends.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["lunge", "guard", "whirl"]

## Achilles' design row.
const BOSS := {
	"display_name": "Achilles, the Unkillable",
	"max_hp": 12000.0,  # TUNING (not in GDD) x the stage HP multiplier (16,800 on Ilion); Kestrel 17,000: his front and the undirected cut make him far tougher than the number reads
	"move_speed": 58.0,  # TUNING (not in GDD) px/s; a swift hero
	"damage": 14.0,  # TUNING (not in GDD) a spear thrust in reach
	"attack_interval": 1.0,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px; the spear's reach
	"radius": 17.0,  # TUNING (not in GDD) px
	"armor": 0.2,  # TUNING (not in GDD) divine bronze and gold
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 9.0,  # TUNING (not in GDD) he shoves the warriors aside
	"faction": PantheonEnemyData.FACTION,
	"reward_xp": 560,  # TUNING (not in GDD) a step above Kestrel's 540
	"reward_crystals": 24,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.55,  # TUNING (not in GDD) s he stands after a lunge
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 1.7,  # TUNING (not in GDD)
	# The heel (see the header).
	"turn_rate": 1.5,  # TUNING (not in GDD) rad/s he turns his front toward what he fights (the Phalanx's 2.4): a ring around him finds his back
	"front_half_angle": 1.0,  # TUNING (not in GDD) rad each side of his facing (~115 degrees in all)
	"back_half_angle": 1.1,  # TUNING (not in GDD) rad each side of straight behind
	"front_mult": 0.1,  # Owner-approved proposal: "Hits to his front deal 10%"
	"flank_mult": 0.5,  # TUNING (not in GDD) the flanks between
	"undirected_mult": 0.5,  # TUNING (not in GDD) area spells, stomps and damage over time (they reach his heel only now and then)
	"heel_offset": 14.0,  # TUNING (not in GDD) px behind his centre the gold heel mark lies (owner-approved "a gold mark under him")
	"heel_radius": 16.0,  # TUNING (not in GDD) px; a blow from within it strikes the heel
	"stagger_time": 0.45,  # TUNING (not in GDD) s he stands after a blow to the back or heel (owner-approved "and stagger him")
	"stagger_cooldown": 2.2,  # TUNING (not in GDD) s; at most one stagger this often (a swarm on his back cannot lock him)
	# Lunge (every phase): a lane of lunge_width px telegraphed lunge_telegraph s,
	# then he runs it at lunge_speed px/s for up to lunge_length px: the
	# necromancer in it takes lunge_damage_player once, each summon in it
	# lunge_damage_summon and is thrown lunge_push px aside.
	"first_lunge": 2.5,  # TUNING (not in GDD) s after arrival
	"lunge_cooldown": 5.0,  # TUNING (not in GDD) s
	"lunge_min": 70.0,  # TUNING (not in GDD) px; lunges at a necromancer this far ...
	"lunge_max": 340.0,  # TUNING (not in GDD) px ... up to this far
	"lunge_length": 300.0,  # TUNING (not in GDD) px (cut short by obstacles)
	"lunge_width": 36.0,  # TUNING (not in GDD) px
	"lunge_telegraph": 0.75,  # TUNING (not in GDD) s
	"lunge_speed": 720.0,  # TUNING (not in GDD) px/s
	"lunge_damage_player": 18.0,  # TUNING (not in GDD) before the time scaling
	"lunge_damage_summon": 22.0,  # TUNING (not in GDD) before the time scaling
	"lunge_push": 36.0,  # TUNING (not in GDD) px
	# The Myrmidon Charge (owner-approved "he summons his guard").
	"guard_hp": 0.65,  # TUNING (not in GDD) HP share below which he calls his guard
	"guard_kind": PantheonEnemyData.HOPLITE,  # Own decision: his Myrmidons are the act's Hoplites (they lock a shield wall)
	"guard_count": 6,  # TUNING (not in GDD) Hoplites per call
	"guard_elites": 2,  # TUNING (not in GDD) of them elite
	"guard_interval": 16.0,  # TUNING (not in GDD) s between two calls
	"guard_max_alive": 10,  # TUNING (not in GDD) no new call while this many of his guard stand
	"guard_ahead": 70.0,  # TUNING (not in GDD) px in front of him the guard's line forms
	"guard_cast": 0.8,  # TUNING (not in GDD) s he stands calling them
	"guard_banner": "Achilles calls his Myrmidons: a shield wall forms before him!",  # TUNING (not in GDD)
	# The Rage after Patroclus (owner-approved "a fast, wild last phase").
	"rage_hp": 0.3,  # TUNING (not in GDD) HP share below which he rages
	"rage_roar": 1.1,  # TUNING (not in GDD) s he stands roaring as it begins
	"rage_banner": "Patroclus is dead: ACHILLES RAGES! His guard is down!",  # TUNING (not in GDD)
	"rage_speed_mult": 1.55,  # TUNING (not in GDD)
	"rage_attack_mult": 0.6,  # TUNING (not in GDD) x his attack interval (faster)
	"rage_front_mult": 0.3,  # TUNING (not in GDD) his front in the rage: no shield
	"rage_lunges": 2,  # TUNING (not in GDD) lunges in a row
	"rage_lunge_cooldown": 3.6,  # TUNING (not in GDD) s
	"whirl_cooldown": 6.0,  # TUNING (not in GDD) s
	"whirl_radius": 92.0,  # TUNING (not in GDD) px
	"whirl_telegraph": 0.65,  # TUNING (not in GDD) s
	"whirl_damage_player": 14.0,  # TUNING (not in GDD) before the time scaling
	"whirl_damage_summon": 18.0,  # TUNING (not in GDD) before the time scaling
	"whirl_push": 40.0,  # TUNING (not in GDD) px
	"whirl_min_summons": 3,  # TUNING (not in GDD) summons inside whirl_radius that make a whirl worth it (or the necromancer)
}
