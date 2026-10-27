## KageData — immutable design data for KAGE, MISTRESS OF THE HIDDEN HAND, the
## boss of the Burning Province (Act V, Stage 13; GDD §15.0 "Kage, Mistress of
## the Hidden Hand (Act V)"; owner-approved proposal docs/act5/PROPOSAL.md:
## "the ninja grandmaster. Splits into shadow clones (only one is real,
## revealed by light), plants smoke fields, and throws chained kunai that pull
## a summon out of the ring"; figure-redesign style, female). BossKage
## (scripts/enemies/shogunate/boss_kage.gd, loaded by name for the boss id
## "kage") reads it. Her kit, every part telegraphed:
##   * SHADOW CLONES — every split_cooldown s she stands split_cast s in a
##     swirl of smoke, then vanishes and steps out at one of clone_count + 1
##     points split_radius px around the necromancer (a seeded pick); her
##     clones (ProvinceEnemyData "kage_clone") step out at the others. Only
##     she is real. A clone that stands in light (SunCourse.light_at() at least
##     reveal_light, for reveal_time s: the necromancer's own pool, a lit stone
##     lantern) is REVEALED as false and dissolves over clone_fade s (no kill,
##     no drop); an unrevealed clone fades after clone_life s.
##   * SMOKE FIELDS — every smoke_cooldown s she plants a smoke field of
##     smoke_radius px at a point on the Bone Ring (smoke_ring px from the
##     necromancer, toward her); for smoke_life s every summon inside is
##     BLINDED (CombatResolver.blind_unit(), the one summon blind path), the
##     blind refreshed to smoke_blind s every smoke_check s.
##   * CHAINED KUNAI — every kunai_cooldown s at a summon within kunai_range px
##     (the one farthest out on the ring toward her) she throws: a lane of
##     kunai_width px shows kunai_telegraph s, then the kunai flies at
##     kunai_speed px/s up to kunai_length px and HOOKS the first summon on its
##     line (kunai_damage_summon): the chain holds it through the ONE compel
##     path (SummonedUnit.compel() with no speed: it neither thinks nor
##     fights) and reels it to her side at pull_speed px/s (at most pull_hold
##     s), out of the ring; there it takes pull_damage. The necromancer in the
##     lane takes kunai_damage_player (the kunai stops on him). An enemy effect
##     on a unit, the same on every stage (no summon rule).
##   * Phases: below phase2_hp she splits into more clones (clone_count[1]) and
##     throws kunai_pair kunai at once; below phase3_hp, "a hundred shadows":
##     clone_count[2] clones, split_cooldown x phase3_cd_mult.
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist, recover_time, advance_range,
## advance_speed_mult) and the abilities' own numbers below. The GDD gives no
## numbers: everything is TUNING (not in GDD) unless marked as the
## owner-approved proposal.
class_name KageData
extends RefCounted

## Kage's arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "kage" through ProvinceStage.BOSS, so --boss=kage and the Codex find her).
const ARRIVAL := {
	"id": "kage",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Kage, Mistress of the Hidden Hand",  # Owner-approved proposal
	"short_name": "Kage",
	"arrive_banner": "Kage, Mistress of the Hidden Hand, steps out of the smoke: only one of her is real!",  # TUNING (not in GDD)
	"defeat_banner": "Kage falls, her shadows with her! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Kage is dead. Survive until the night ends... it will not.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["split", "smoke", "kunai"]
## Sprite key of her art (assets/sprites/bosses/kage.png); her clones wear it too.
const SPRITE: String = "bosses/kage"
## Damage source tag of the chained kunai (the hook and the reel).
const KUNAI_SOURCE: String = "kage_kunai"

## Kage's design row.
const BOSS := {
	"display_name": "Kage, Mistress of the Hidden Hand",
	"max_hp": 11000.0,  # TUNING (not in GDD) x the stage HP multiplier (17,050 on the Province); her clones and smoke make her tougher than the number reads (Achilles 12,000)
	"move_speed": 66.0,  # TUNING (not in GDD) px/s; quick
	"damage": 13.0,  # TUNING (not in GDD) a ninjato cut in reach
	"attack_interval": 0.9,  # TUNING (not in GDD) s
	"attack_range": 12.0,  # TUNING (not in GDD) px
	"radius": 14.0,  # TUNING (not in GDD) px
	"armor": 0.15,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 6.0,  # TUNING (not in GDD)
	"faction": ShogunateEnemyData.FACTION,
	"reward_xp": 580,  # TUNING (not in GDD) a step above Achilles' 560
	"reward_crystals": 24,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.45,  # TUNING (not in GDD) s she stands after a throw
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this she runs
	"advance_speed_mult": 1.7,  # TUNING (not in GDD)
	# Shadow clones (owner-approved "splits into shadow clones, only one is real, revealed by light").
	"first_split": 4.0,  # TUNING (not in GDD) s after she arrives
	"split_cooldown": 15.0,  # TUNING (not in GDD) s
	"split_cast": 0.8,  # TUNING (not in GDD) s she stands in her smoke before vanishing
	"split_radius": 210.0,  # TUNING (not in GDD) px around the necromancer (just outside his light pool, 150)
	"clone_count": [2, 3, 4],  # TUNING (not in GDD) clones per split in phases 1 / 2 / 3
	"clone_life": 12.0,  # TUNING (not in GDD) s an unrevealed clone lasts
	"reveal_light": 0.55,  # TUNING (not in GDD) 0..1 light that reveals a clone (SunCourse.light_at())
	"reveal_time": 0.4,  # TUNING (not in GDD) s in light before it shows as false
	"clone_fade": 0.6,  # TUNING (not in GDD) s a revealed clone takes to dissolve
	# Smoke fields (owner-approved "plants smoke fields").
	"first_smoke": 7.0,  # TUNING (not in GDD) s after she arrives
	"smoke_cooldown": 9.0,  # TUNING (not in GDD) s
	"smoke_cast": 0.5,  # TUNING (not in GDD) s she stands planting it
	"smoke_ring": 80.0,  # TUNING (not in GDD) px from the necromancer: on the Bone Ring
	"smoke_radius": 72.0,  # TUNING (not in GDD) px
	"smoke_life": 6.0,  # TUNING (not in GDD) s
	"smoke_check": 0.5,  # TUNING (not in GDD) s between two blinds of the field
	"smoke_blind": 1.0,  # TUNING (not in GDD) s each blind lasts (refreshed while inside)
	"smoke_max": 3,  # TUNING (not in GDD) fields at once
	# Chained kunai (owner-approved "throws chained kunai that pull a summon out of the ring").
	"first_kunai": 2.5,  # TUNING (not in GDD) s after she arrives
	"kunai_cooldown": 6.5,  # TUNING (not in GDD) s
	"kunai_range": 360.0,  # TUNING (not in GDD) px to the summon she aims at
	"kunai_telegraph": 0.55,  # TUNING (not in GDD) s
	"kunai_speed": 560.0,  # TUNING (not in GDD) px/s
	"kunai_length": 400.0,  # TUNING (not in GDD) px
	"kunai_width": 12.0,  # TUNING (not in GDD) px
	"kunai_damage_summon": 10.0,  # TUNING (not in GDD) the hook, before the time scaling
	"kunai_damage_player": 9.0,  # TUNING (not in GDD) before the time scaling
	"pull_speed": 300.0,  # TUNING (not in GDD) px/s the chain reels
	"pull_hold": 2.0,  # TUNING (not in GDD) s at most a hooked summon is held
	"pull_damage": 8.0,  # TUNING (not in GDD) when it arrives at her side, before the time scaling
	"kunai_pair": 2,  # TUNING (not in GDD) kunai per throw from phase 2
	# Phases.
	"phase2_hp": 0.6,  # TUNING (not in GDD) HP share
	"phase3_hp": 0.3,  # TUNING (not in GDD) HP share
	"phase3_cd_mult": 0.75,  # TUNING (not in GDD) x the split cooldown in phase 3
	"phase2_banner": "Kage's shadows multiply: find the real one in the light!",  # TUNING (not in GDD)
	"phase3_banner": "A HUNDRED SHADOWS: Kage is everywhere at once!",  # TUNING (not in GDD)
}
