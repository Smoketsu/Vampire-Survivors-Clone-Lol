## VargrData — immutable design data for VARGR, THE MOON-EATER, the boss of
## Ravensmoor (Act VII, Stage 19; GDD §15.0 "Vargr, the Moon-Eater (Act VII)";
## owner-approved proposal docs/act7/PROPOSAL.md: "the werewolf king. He calls
## his own Blood Moon at each phase: the Hunt (he circles the ring and lunges
## at the weakest summon), the Turning (his pack transforms around him and he
## leaps over the ring at the necromancer), the Moon-Eater (he swallows the
## moon: the arena goes dark except a red circle around him, and every hit he
## lands feeds him)"). BossVargr (scripts/enemies/court/boss_vargr.gd, loaded
## by name for the boss id "vargr") reads it. Three phases by his HP, each
## calling his own moon through BloodMoon.force() (no banner of the moon's: his
## own):
##   * The Hunt (100% to phase2_hp): he CIRCLES the Bone Ring circle_radius px
##     from the necromancer (circle_speed rad/s) and bites what he touches;
##     every lunge_cooldown s he crouches lunge_windup s (a red line to his
##     mark) and LUNGES at the WEAKEST summon within lunge_reach px (the least
##     HP left; the necromancer when no summon is in reach), biting it for
##     lunge_damage (a feeding blow).
##   * The Turning (phase2_hp to phase3_hp): he HOWLS: every werewolf within
##     howl_radius px turns into the beast at once (WerewolfKit.howl_turn())
##     and pack_count werewolves step out around him already turned (under the
##     hard cap, at most pack_cap of his standing), again every howl_every s;
##     he walks at the necromancer and every leap_cooldown s LEAPS OVER THE
##     RING at him: a circle of leap_radius px shows where he lands for
##     leap_windup s, he flies there in leap_time s, and every necromancer and
##     summon in it is hit (feeding) and thrown leap_push px out.
##   * The Moon-Eater (below phase3_hp): he swallows the moon: the arena goes
##     dark except a red circle of dark_radius px around him (VargrDark: a
##     texture with a hole, no screen-reading shader); faster and harder, he
##     lunges and leaps both, and every hit he lands FEEDS him (Bloodfeast's
##     share feeds_p3, through the one Bloodfeast path; feeds before it).
## Killing him drops a big XP burst and the boss chest; slaying him unlocks the
## Moonfang spell and Pack Blood (UnlockData, boss "vargr"). The GDD gives no
## numbers: everything is TUNING (not in GDD) unless marked as the
## owner-approved proposal.
class_name VargrData
extends RefCounted

## Vargr's arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "vargr" through RavensmoorStage.BOSS, so --boss=vargr and the Codex find him).
const ARRIVAL := {
	"id": "vargr",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Vargr, the Moon-Eater",  # Owner-approved proposal
	"short_name": "Vargr",
	"arrive_banner": "Vargr, the Moon-Eater, howls the moon red!",  # TUNING (not in GDD)
	"defeat_banner": "Vargr falls, and the moon pales! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Vargr is dead. Survive the Endless Feast... you cannot.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["lunge", "howl", "leap", "moon_eater"]

## Damage tag of his lunge's bite.
const LUNGE_SOURCE: String = "vargr_lunge"
## Damage tag of his leap's landing.
const LEAP_SOURCE: String = "vargr_leap"
## Sprite key of his art (assets/sprites/bosses/vargr.png).
const SPRITE: String = "bosses/vargr"

## Vargr's base max HP (x the boss HP multiplier and the stage's HP multiplier:
## 19,425 on Ravensmoor). Moloch 8,500 (14,875 on the Burning Gate); higher,
## because his Hunt keeps him off the ring's blockers and the army's ranged
## classes are what reach him.
const MAX_HP: float = 10500.0  # TUNING (not in GDD) first pass 7500: the seed-7 army run with Moonfang killed him in 60 s, all three phases in 36 s

## Vargr's design row.
const BOSS := {
	"display_name": "Vargr, the Moon-Eater",
	"max_hp": MAX_HP,
	"move_speed": 60.0,  # TUNING (not in GDD) px/s; a hunting wolf
	"damage": 13.0,  # TUNING (not in GDD) a bite of his jaws in reach
	"attack_interval": 1.2,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 26.0,  # TUNING (not in GDD) px; a huge wolf-man
	"armor": 0.15,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 12.0,  # TUNING (not in GDD) shoves warriors aside
	"faction": CourtEnemyData.FACTION,
	"feeds": 0.25,  # Owner-approved (Oct 31, 2026): not a vampire: 25% (Bloodfeast.share_of() reads boss_def "feeds")
	"feeds_p3": 0.6,  # TUNING (not in GDD) the Moon-Eater: "every hit he lands feeds him", harder than any vampire
	"reward_xp": 600,  # TUNING (not in GDD) as Moloch
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.5,  # TUNING (not in GDD) s he stands after a special
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 1.7,  # TUNING (not in GDD)
	# Phases (HP shares) and his own moons (BloodMoon.force()).
	"phase2_hp": 0.66,  # TUNING (not in GDD) the Turning below this
	"phase3_hp": 0.33,  # TUNING (not in GDD) the Moon-Eater below this
	"moon_hunt": 35.0,  # TUNING (not in GDD) s of the moon he calls when he arrives (the Hunt)
	"moon_turning": 35.0,  # TUNING (not in GDD) s of the moon he calls at the Turning
	"moon_eater_hold": 4.0,  # TUNING (not in GDD) s the Moon-Eater's moon is held ahead (re-forced each second while he lives)
	"hunt_banner": "Vargr hunts: he circles your ring for the weakest of your dead!",  # TUNING (not in GDD)
	"phase2_banner": "THE TURNING: Vargr's pack becomes beasts around him!",  # TUNING (not in GDD)
	"phase3_banner": "VARGR SWALLOWS THE MOON: every bite feeds him!",  # TUNING (not in GDD)
	# The Hunt: the circling and the lunge at the weakest summon.
	"circle_radius": 230.0,  # TUNING (not in GDD) px from the necromancer (the ring is 60-150 px)
	"circle_speed": 0.55,  # TUNING (not in GDD) rad/s around the necromancer
	"first_lunge": 4.0,  # TUNING (not in GDD) s after arrival
	"lunge_cooldown": 6.0,  # TUNING (not in GDD) s, the Hunt
	"lunge_cooldown_p3": 5.0,  # TUNING (not in GDD) s, the Moon-Eater
	"lunge_windup": 0.7,  # TUNING (not in GDD) s of the crouch (a red line to his mark)
	"lunge_time": 0.3,  # TUNING (not in GDD) s of the leap
	"lunge_reach": 300.0,  # TUNING (not in GDD) px: the weakest summon within this of him
	"lunge_damage": 24.0,  # TUNING (not in GDD) to a summon, before the time scaling
	"lunge_damage_player": 12.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	# The Turning: the howl and the leap over the ring.
	"howl_radius": 360.0,  # TUNING (not in GDD) px: werewolves he turns at once
	"howl_every": 22.0,  # TUNING (not in GDD) s between two howls
	"pack_count": 2,  # TUNING (not in GDD) werewolves stepping out with each howl, turned
	"pack_cap": 4,  # TUNING (not in GDD) most of his pack standing at once
	"pack_dist": 70.0,  # TUNING (not in GDD) px from him they step out
	"first_leap": 3.0,  # TUNING (not in GDD) s after the Turning
	"leap_cooldown": 9.0,  # TUNING (not in GDD) s, the Turning
	"leap_cooldown_p3": 8.0,  # TUNING (not in GDD) s, the Moon-Eater
	"leap_windup": 1.1,  # TUNING (not in GDD) s the landing circle shows
	"leap_time": 0.5,  # TUNING (not in GDD) s in the air
	"leap_height": 70.0,  # TUNING (not in GDD) px of the arc (drawn only)
	"leap_radius": 64.0,  # TUNING (not in GDD) px of the landing
	"leap_damage_player": 13.0,  # TUNING (not in GDD) before the time scaling
	"leap_damage_summon": 16.0,  # TUNING (not in GDD) before the time scaling
	"leap_push": 34.0,  # TUNING (not in GDD) px the summons are thrown out
	# The Moon-Eater.
	"eater_speed": 70.0,  # TUNING (not in GDD) px/s
	"eater_damage": 16.0,  # TUNING (not in GDD) per bite
	"dark_radius": 180.0,  # TUNING (not in GDD) px of the red circle of light around him
	"dark_alpha": 0.82,  # TUNING (not in GDD) darkness outside it (drawn only)
}
