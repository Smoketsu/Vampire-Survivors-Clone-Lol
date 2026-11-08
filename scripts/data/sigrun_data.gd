## SigrunData — immutable design data for SIGRUN, THE SHIELD-QUEEN, the boss of
## Valgard, the Hall of Heroes (the Hall of the Slain, temporarily Act XI, final
## slot VI; Stage 17 in the final order; GDD §15.0 "Sigrun, the Shield-Queen
## (the Hall of the Slain)"; the act's section "Stage 17: Valgard, the Hall of
## Heroes" of docs/proposals/LAST_SIX_ACTS.md, with the owner decisions of Nov
## 7, 2026: her last phase is "the Doors of the Hall: every Einherjar of the
## hall marches out at her side", a scripted wave). BossSigrun
## (scripts/enemies/norse/boss_sigrun.gd, loaded by name for the boss id
## "sigrun") reads it. A FEMALE valkyrie captain in the figure-redesign style
## (the art pass's norse/sigrun, wings, spear and shield, with walk and idle
## strips). Three phases by her HP:
##   * THE CHARGE (100% to phase2_hp): every charge_every s (the first
##     charge_first s after she lands) she and her VALKYRIE WING (wing_count
##     wing valkyries brought with her, ValgardEnemyData "wing_valkyrie") mark
##     LINES across the ring (EffectManager.telegraph_line(): hers through the
##     necromancer, the wing's offset by wing_offset px to either side) for
##     charge_windup s, then dive along them in charge_time s: every
##     necromancer and summon a lane crosses takes charge_damage_* once
##     (OlympusHits.lane(), source CHARGE_SOURCE) and the summons are thrown
##     charge_push px aside. Between charges she walks and thrusts (the shared
##     melee).
##   * THE HOLMGANG (phase2_hp to phase3_hp): at once, then every duel_gap s
##     after a duel ends, a SQUARE OF HAZEL RODS (Holmgang, holmgang_half px
##     half side) closes around her and the necromancer for holmgang_time s:
##     summons and every other enemy are pushed out and cannot enter, the
##     necromancer cannot leave, and only spell hits land on her
##     (HundredShadowsData.is_spell_source(); every other hit deals 0). Inside,
##     she fights him with her spear: the shared thrust and a telegraphed
##     LUNGE along a lane every lunge_every s. If his spells take yield_share
##     of her max HP before the time is up she YIELDS (the duel is won: the
##     rods fall, she is staggered won_stagger s and takes won_taken more for
##     won_time s); else she wins it and heals lost_heal of her max HP
##     (CombatResolver.heal_enemy()). A duel won without a single Grave Step
##     sets HOLMGANG_STAT (the achievement Holmgang). Between duels she charges.
##   * THE DOORS OF THE HALL (below phase3_hp): the doors swing open and every
##     Einherjar of the hall marches out at her side: doors_count Einherjar
##     (ValgardEnemyData "einherjar", gold heroes through
##     NorseKit.make_einherjar()) in two files from the spawn ring beyond her,
##     and every seated Einherjar at the tables near the necromancer wakes
##     (ValgardDirector.wake_feast(), the Feast); she charges every
##     charge_every_p3 s until she falls.
## The autotest bot steps out of her lanes and the lunge (BossSigrun.danger_push()).
## The GDD gives no numbers: everything is TUNING (not in GDD), tuned for the
## act's final slot VI, unless marked as the owner-approved proposal.
class_name SigrunData
extends RefCounted

## Sigrun's arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "sigrun" through ValgardStage.BOSS, so --boss=sigrun and the Codex find
## her). Her script is scripts/enemies/norse/boss_sigrun.gd (loaded by id).
const ARRIVAL := {
	"id": "sigrun",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Sigrun, the Shield-Queen",  # Owner-approved proposal
	"short_name": "Sigrun",
	"arrive_banner": "Sigrun, the Shield-Queen, leads her valkyrie wing down!",  # TUNING (not in GDD)
	"defeat_banner": "Sigrun falls, and the hall's doors swing shut! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Sigrun is dead. Survive Ragnarok... you cannot.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["charge", "holmgang", "lunge", "yield", "doors"]

## Damage tag of the Charge's lanes (hers and her wing's).
const CHARGE_SOURCE: String = "sigrun_charge"
## Damage tag of her spear lunge in the Holmgang.
const LUNGE_SOURCE: String = "sigrun_lunge"
## Sprite key of her art (still, walk and idle strips: the art pass).
const SPRITE: String = "norse/sigrun"
## Run stat set to 1 when a Holmgang was won without a Grave Step (the
## achievement Holmgang; MetaProgress counts the runs, lifetime holmgang_runs).
const HOLMGANG_STAT: String = "valgard_holmgang_clean"
## Kind id of her valkyrie wing (ValgardEnemyData).
const WING_KIND: String = "wing_valkyrie"

## Her base max HP (x the boss HP multiplier and the stage's HP multiplier).
const MAX_HP: float = 12500.0  # TUNING (not in GDD) a step under Vrask'Tal's 14,500: the Holmgang shuts the army out for 15 s at a time

## Sigrun's design row.
const BOSS := {
	"display_name": "Sigrun, the Shield-Queen",
	"max_hp": MAX_HP,
	"move_speed": 62.0,  # TUNING (not in GDD) px/s
	"damage": 7.0,  # TUNING (not in GDD) a spear thrust, before the time scaling
	"attack_interval": 1.1,  # TUNING (not in GDD) s
	"attack_range": 20.0,  # TUNING (not in GDD) px (the spear's reach)
	"radius": 24.0,  # TUNING (not in GDD) px (an 80 px sprite with wings)
	"armor": 0.2,  # TUNING (not in GDD) her shield and mail
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 12.0,  # TUNING (not in GDD)
	"faction": NorseEnemyData.FACTION,
	"group": "hall",  # The report and the Codex group her with the hall.
	"reward_xp": 650,  # TUNING (not in GDD) as Vrask'Tal
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"advance_range": 460.0,  # TUNING (not in GDD) px; farther than this she moves faster
	"advance_speed_mult": 1.7,  # TUNING (not in GDD)
	# Phases (HP shares).
	"phase2_hp": 0.7,  # TUNING (not in GDD) the Holmgang below this
	"phase3_hp": 0.35,  # TUNING (not in GDD) the Doors of the Hall below this
	"charge_banner": "THE CHARGE: Sigrun and her valkyrie wing dive across your ring. Step off the marked lines!",  # TUNING (not in GDD)
	"holmgang_banner": "THE HOLMGANG: Sigrun challenges you! The hazel rods close. Only your spells reach her in the square",  # TUNING (not in GDD)
	"doors_banner": "THE DOORS OF THE HALL swing open: every Einherjar of the hall marches out at Sigrun's side!",  # TUNING (not in GDD)
	"won_banner": "Sigrun yields the Holmgang! Her guard is down",  # TUNING (not in GDD)
	"lost_banner": "The Holmgang is hers: the hall cheers and her wounds close",  # TUNING (not in GDD)
	# The Charge (phase 1; also between duels and in phase 3).
	"wing_count": 3,  # TUNING (not in GDD) wing valkyries she brings (owner-approved proposal: "with her valkyrie wing")
	"wing_spread": 70.0,  # TUNING (not in GDD) px from her where the wing lands with her
	"charge_first": 4.0,  # TUNING (not in GDD) s after her arrival
	"charge_every": 9.0,  # TUNING (not in GDD) s
	"charge_every_p3": 7.0,  # TUNING (not in GDD) s, the Doors of the Hall
	"charge_reach": 520.0,  # TUNING (not in GDD) px: she charges only from this near (farther she walks)
	"charge_windup": 1.1,  # TUNING (not in GDD) s the lines show
	"charge_time": 0.55,  # TUNING (not in GDD) s the dive along the line takes
	"charge_overshoot": 180.0,  # TUNING (not in GDD) px past the necromancer the lane runs
	"charge_width": 36.0,  # TUNING (not in GDD) px, the lane's width
	"wing_offset": 72.0,  # TUNING (not in GDD) px each wing lane runs beside hers
	"charge_damage_player": 8.0,  # TUNING (not in GDD) before the time scaling
	"charge_damage_summon": 11.0,  # TUNING (not in GDD) before the time scaling
	"charge_push": 26.0,  # TUNING (not in GDD) px the summons are thrown aside
	"recover_time": 0.6,  # TUNING (not in GDD) s she stands after a charge (open to every blow)
	# The Holmgang (phase 2).
	"holmgang_half": 150.0,  # TUNING (not in GDD) px, half the square's side (owner-approved proposal: "a square of hazel rods")
	"holmgang_time": 15.0,  # Owner-approved proposal: "for 15 s"
	"holmgang_close": 0.6,  # TUNING (not in GDD) s the rods take to close (drawing; the rule holds at once)
	"duel_gap": 16.0,  # TUNING (not in GDD) s between the end of a duel and the next
	"duel_offset": 90.0,  # TUNING (not in GDD) px from the necromancer she stands when the square closes
	"yield_share": 0.06,  # TUNING (not in GDD) of her max HP his spells must take in the square
	"won_stagger": 2.5,  # TUNING (not in GDD) s she reels after yielding
	"won_taken": 0.25,  # TUNING (not in GDD) + share of every hit she takes after yielding
	"won_time": 8.0,  # TUNING (not in GDD) s her guard stays down
	"lost_heal": 0.04,  # TUNING (not in GDD) of her max HP when she wins the duel
	"lunge_every": 3.5,  # TUNING (not in GDD) s
	"lunge_windup": 0.75,  # TUNING (not in GDD) s the lane shows
	"lunge_length": 170.0,  # TUNING (not in GDD) px
	"lunge_width": 30.0,  # TUNING (not in GDD) px
	"lunge_time": 0.2,  # TUNING (not in GDD) s
	"lunge_damage": 9.0,  # TUNING (not in GDD) before the time scaling
	# The Doors of the Hall (phase 3).
	"doors_count": 10,  # TUNING (not in GDD) Einherjar marching out at her side (owner decision Nov 7, 2026: "a scripted wave")
	"doors_spacing": 34.0,  # TUNING (not in GDD) px between two heroes of a file
	"doors_files": 26.0,  # TUNING (not in GDD) px from the files' centre line to each file
}
