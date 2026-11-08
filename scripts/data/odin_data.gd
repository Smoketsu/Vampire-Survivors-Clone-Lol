## OdinData — immutable design data of ODIN AND FENRIR, the boss of Vigrid,
## the Last Field, and the finale of the Hall of the Slain (the Norse act,
## temporarily Act XI, final slot VI; GDD §15.0 "Odin and Fenrir (Vigrid)";
## owner-approved proposal docs/proposals/LAST_SIX_ACTS.md "Stage 18: Vigrid":
## "Odin and Fenrir (the one-eyed god, male, and the great wolf): the Wolf
## (Fenrir breaks his chain and hunts the ring; he swallows a summon whole and
## spits it out 4 s later), the All-Father (Odin's spear that never misses: a
## throw at the strongest summon that no blocker stops, dodged only by Grave
## Step or a Bone Wall; his ravens mark the necromancer), Ragnarök (both at
## once, the arena burning, until one falls; the other follows within 30 s)").
## BossOdin (scripts/enemies/norse/boss_odin.gd, loaded by name for the boss
## id "odin") reads BOSS; StageRegistry.BOSS_ARRIVALS and VigridStage.BOSS read
## ARRIVAL. Odin is the Boss body (the HUD's boss bar); Fenrir is the kind
## "fenrir" (VigridEnemyData, FenrirKit) he brings, on the miniboss bar, with
## fenrir_hp x the boss's HP scaling. Three phases:
##   THE WOLF (arrival -> Fenrir at fenrir_retreat_hp of his health, or
##        wolf_max s): Fenrir breaks his chain and hunts the ring (the swallow,
##        FenrirKit); Odin stands watch watch_dist px off, beyond reach
##        (untargetable, unharmed).
##   THE ALL-FATHER (-> Odin at ragnarok_hp of his health, or allfather_max s):
##        the wounded wolf is chained at his side (untargetable, unharmed) and
##        Odin walks at the necromancer: every gungnir_every s he throws
##        GUNGNIR (a telegraphed line, then a spear that flies gungnir_speed
##        px/s and HOMES on its mark: no blocker stops it, only a Bone Wall
##        segment across its path (EmpireShots.wall_block_t(), THE wall loop)
##        or Grave Step's i-frames on the necromancer): at the STRONGEST summon
##        (the most max HP within gungnir_range px), or at the necromancer
##        himself while his RAVENS have marked him; every raven_every s he sends
##        `ravens` ravens (VigridEnemyData "odin_raven", OdinRavenKit) that fly
##        at the necromancer and mark him for their mark_time on touch.
##   RAGNARÖK (to the end): Fenrir is loosed again (frenzied: he swallows
##        more often) and both fight at once; THE ARENA BURNS: every fire_every
##        s a ring of fire_points burning patches fire_ring px round the
##        necromancer (EnemyDirector.province_hazards().add_fire(), THE pooled
##        enemy fire path). When ONE FALLS THE OTHER FOLLOWS WITHIN 30 s
##        (doom_time): the survivor takes doom_taken of every hit, and when the
##        doom runs out it falls (a killing hit tagged DOOM_SOURCE). Odin's fall
##        is the boss kill (the unlock chain, Twilight of the Wolf).
## Beaten: a short ending text only (no epilogue part or closing card until
## the reorder pass, docs/last_acts/PLAN.md). Keys: every key of an
## EnemyData.ENEMIES row (same meaning), the shared boss keys (reward_xp,
## reward_crystals, slow_resist) and the abilities' own numbers. Damage keys
## are before the time scaling. The GDD gives no numbers: everything is
## TUNING (not in GDD) unless marked as the owner-approved proposal.
class_name OdinData
extends RefCounted

## Its arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "odin" through VigridStage.BOSS, so --boss=odin and the Codex find it). Its
## script is found by the id (boss_odin.gd).
const ARRIVAL := {
	"id": "odin",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Odin and Fenrir",  # Owner-approved proposal (real names)
	"short_name": "Odin",
	"arrive_banner": "Odin rides out to the Last Field, and Fenrir breaks his chain!",  # TUNING (not in GDD)
	"defeat_banner": "The All-Father falls on the Last Field!",  # TUNING (not in GDD)
	"dead_objective": "The gods are dead. Survive Ragnarok... you cannot.",  # TUNING (not in GDD)
}
## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["wolf", "allfather", "gungnir", "ravens", "ragnarok", "burning"]
## Sprite key of Odin's art (norse/odin with its glide strip).
const SPRITE: String = "norse/odin"
## Damage tag of Gungnir (his spear).
const SRC_GUNGNIR: String = "odin_gungnir"
## Damage tag of the burning arena of Ragnarok.
const SRC_FIRE: String = "ragnarok_fire"
## Damage tag of the doom of Ragnarok (the survivor's fall).
const DOOM_SOURCE: String = "ragnarok_doom"
## The Twilight of the Wolf's report stat (the kill time).
const KILL_TIME_STAT: String = "odin_kill_time"
## Seconds the ending line stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## HUD announcement on Odin's fall (title, line, description), short (no
## epilogue part until the reorder pass).
const ENDING_ANNOUNCE := ["TWILIGHT OF THE WOLF", "The All-Father falls.", "The last god of the north lies on the field he chose for the end of the world, and no hall is left to take him."]  # TUNING (not in GDD)
## Shorter announcement when he falls after 0:00 (Ragnarok goes on).
const LATE_ANNOUNCE := ["TWILIGHT OF THE WOLF", "The All-Father falls.", "Even as the sun is swallowed, the god who waited for this day is gone."]  # TUNING (not in GDD)

## Its design row.
const BOSS := {
	"display_name": "Odin",
	"max_hp": 11500.0,  # TUNING (not in GDD) before the stage / co-op scaling (x1.65 on Vigrid = 18,975; Fenrir beside him); first pass 8,200 fell in 64 s on seed 7
	"move_speed": 50.0,  # TUNING (not in GDD) px/s, an old god's stride
	"damage": 10.0,  # TUNING (not in GDD) a blow of the spear-shaft in melee, before the time scaling
	"attack_interval": 1.3,  # TUNING (not in GDD) s
	"attack_range": 16.0,  # TUNING (not in GDD) px
	"radius": 18.0,  # TUNING (not in GDD) px (the 72 px sprite)
	"armor": 0.2,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 1.0,
	"mass": 40.0,  # TUNING (not in GDD)
	"slow_resist": 0.7,  # TUNING (not in GDD) like every boss
	"reward_xp": 1100,  # TUNING (not in GDD) the act's finale (the Harvester 1,100)
	"reward_crystals": 34,  # TUNING (not in GDD)
	"arrive_time": 2.0,  # TUNING (not in GDD) s both stand at the field's edge (unharmed)
	"advance_range": 380.0,  # TUNING (not in GDD) px beyond which he strides faster
	"advance_speed_mult": 2.0,  # TUNING (not in GDD)
	# Fenrir.
	"fenrir_hp": 8500.0,  # TUNING (not in GDD) Fenrir's max HP before the boss's HP scaling (x1.65 = 14,025); first pass 6,200
	"fenrir_offset": 70.0,  # TUNING (not in GDD) px beside Odin he comes in / is chained
	# The Wolf.
	"watch_dist": 330.0,  # TUNING (not in GDD) px from the necromancer Odin stands watch
	"fenrir_retreat_hp": 0.55,  # TUNING (not in GDD) share of Fenrir's health where the All-Father steps in
	"wolf_max": 70.0,  # TUNING (not in GDD) s at most before he steps in anyway
	# The All-Father.
	"ragnarok_hp": 0.5,  # TUNING (not in GDD) share of Odin's health where Ragnarok begins
	"allfather_max": 75.0,  # TUNING (not in GDD) s at most before Ragnarok comes anyway
	"gungnir_first": 2.5,  # TUNING (not in GDD) s after the All-Father begins
	"gungnir_every": 7.0,  # TUNING (not in GDD) s
	"gungnir_every_ragnarok": 9.0,  # TUNING (not in GDD) s (Fenrir hunts beside him)
	"gungnir_windup": 1.1,  # TUNING (not in GDD) s of the telegraphed line
	"gungnir_speed": 950.0,  # TUNING (not in GDD) px/s; it homes on its mark ("the spear that never misses")
	"gungnir_range": 560.0,  # TUNING (not in GDD) px: summons this close may be its mark
	"gungnir_damage_summon": 46.0,  # TUNING (not in GDD) before the time scaling
	"gungnir_damage_player": 9.0,  # TUNING (not in GDD) before the time scaling (first pass 14: two hits took 60 of the seed-7 bot's 120 HP)
	"gungnir_push": 30.0,  # TUNING (not in GDD) px a struck summon is thrown
	"raven_first": 4.0,  # TUNING (not in GDD) s after the All-Father begins
	"raven_every": 12.0,  # TUNING (not in GDD) s
	"ravens": 2,  # Owner-approved proposal ("his ravens"): Huginn and Muninn
	"raven_spread": 30.0,  # TUNING (not in GDD) px apart as they leave him
	# Ragnarok.
	"fire_first": 2.0,  # TUNING (not in GDD) s after Ragnarok begins
	"fire_every": 8.0,  # TUNING (not in GDD) s between two rings of fire
	"fire_ring": 175.0,  # TUNING (not in GDD) px from the necromancer (just past the Bone Ring)
	"fire_points": 7,  # TUNING (not in GDD) patches a ring
	"fire_patch": 34.0,  # TUNING (not in GDD) px of each patch
	"fire_life": 7.0,  # TUNING (not in GDD) s a patch burns
	"fire_dmg_player": 2.0,  # TUNING (not in GDD) per burn (every 0.5 s), before the time scaling
	"fire_dmg_summon": 3.0,  # TUNING (not in GDD) per burn, before the time scaling
	"ragnarok_speed_mult": 1.2,  # TUNING (not in GDD) Odin strides faster in Ragnarok
	"doom_time": 30.0,  # Owner-approved proposal: "the other follows within 30 s"
	"doom_taken": 1.5,  # TUNING (not in GDD) x every hit on the doomed survivor
}
