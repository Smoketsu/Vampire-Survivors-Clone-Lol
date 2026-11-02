## IsoldeData — immutable design data for ISOLDE VANE, THE WITCH OF THE RED MOON,
## the boss of the Witchwood (Act VII, Stage 20; GDD §15.0 "Isolde Vane, the
## Witch of the Red Moon (Act VII)"; owner-approved proposal docs/act7/PROPOSAL.md:
## "phase 1, hex circles on the ring and cauldron bombs that leave healing pools
## for her thralls; phase 2, she splits into three sisters, and all three must
## fall within 10 s of each other or the fallen ones rise again; phase 3, she
## calls the Blood Moon and keeps it up until she falls"). BossIsolde
## (scripts/enemies/court/boss_isolde.gd, loaded by name for the boss id
## "isolde") reads it. Female, in the figure-redesign style. Three phases:
##   * THE WITCH (100% to phase2_hp): she walks at the necromancer and strikes
##     with her cauldron-staff in reach. HEX CIRCLES ON THE RING every
##     circle_every s: circle_count circles under summons of the ring (spread
##     around it), each glowing circle_windup s, then biting circle_time s
##     through WitchHexes.cast_circle() (the witches' one circle path: it heals
##     the Court inside and drains the summons). CAULDRON BOMBS every
##     bomb_every s: bomb_count bombs lobbed at and around the necromancer
##     (a telegraphed circle, bomb_fall s), a splash on landing and a BLOOD POOL
##     (WitchHexes.open_pool(), the one pool path) that heals her thralls; she
##     calls thrall_count blood thralls every thrall_every s to drink them.
##   * THE THREE SISTERS (at phase2_hp): she splits into three sisters
##     (WitchwoodEnemyData "isolde_sister", their HP the bar between phase2_hp
##     and phase3_hp in three), herself hidden and untouchable among them.
##     ALL THREE MUST FALL WITHIN sisters_window s OF EACH OTHER: a sister down
##     longer than that while another still stands RISES AGAIN where she fell
##     with rise_hp of her life (x rise_decay for every earlier rise). After
##     sabbath_wane s the sabbath wanes: the fallen no longer rise (own
##     decision, a floor so a fight always ends). The bar is her phase 3 share
##     plus what the sisters have left. Killing the three within coven_break s
##     earns The Coven Breaks (owner-approved: "kill Isolde's three sisters
##     within 1 s").
##   * THE RED MOON (below phase3_hp, when the sisters fell together): she
##     reforms among them and calls the Blood Moon, keeping it up until she
##     falls (BloodMoon.force(), every tick: the moon's x2 feeding, werebeasts
##     turned, covens casting); her circles and bombs come faster and more.
## Killing her drops a big XP burst and the boss chest; slaying her unlocks the
## Hex Circle spell and Moonlit Rite (UnlockData, boss "isolde"). The GDD gives
## no numbers: everything is TUNING (not in GDD) unless marked as the
## owner-approved proposal.
class_name IsoldeData
extends RefCounted

## Isolde's arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "isolde" through WitchwoodStage.BOSS, so --boss=isolde and the Codex find her).
const ARRIVAL := {
	"id": "isolde",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Isolde Vane, the Witch of the Red Moon",  # Owner-approved proposal
	"short_name": "Isolde",
	"arrive_banner": "Isolde Vane, the Witch of the Red Moon, steps out of the cauldron smoke!",  # TUNING (not in GDD)
	"defeat_banner": "Isolde falls, her coven with her! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "Isolde is dead. Survive the Endless Feast... you cannot.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["hex_circle", "cauldron_bomb", "thrall_call", "sisters", "red_moon"]

## Kind id of her three sisters (WitchwoodEnemyData).
const SISTER: String = "isolde_sister"
## Damage tag of her cauldron bombs' splash.
const BOMB_SOURCE: String = "isolde_bomb"
## WitchHexes stats tag of her circles (hex_circle_heal_isolde, hex_casts_isolde).
const CIRCLE_TAG: String = "isolde"
## WitchHexes stats tag of her sisters' circles.
const SISTER_TAG: String = "sister"
## WitchHexes stats tag of her bombs' pools (blood_pools_opened_cauldron).
const POOL_TAG: String = "cauldron"
## Colour multiplied over each sister (her blood red, her velvet, her moon).
const SISTER_TINTS: Array[Color] = [Color(1.0, 0.82, 0.82), Color(0.86, 0.80, 1.0), Color(0.86, 0.94, 1.0)]  # TUNING (not in GDD)

## Isolde's base max HP (x the boss HP multiplier and the stage's HP
## multiplier: 25,900 on the Witchwood). Moloch 8500 (14,875 on the Burning
## Gate): the Witchwood's army bot, with nothing healing her, burned the first
## pass's 8000 (14,800) in 32 s, sisters and all.
const MAX_HP: float = 14000.0  # TUNING (not in GDD) first pass 8000

## Isolde's design row.
const BOSS := {
	"display_name": "Isolde Vane, the Witch of the Red Moon",
	"max_hp": MAX_HP,
	"move_speed": 50.0,  # TUNING (not in GDD) px/s
	"damage": 13.0,  # TUNING (not in GDD) a blow of her cauldron-staff in reach
	"attack_interval": 1.3,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 18.0,  # TUNING (not in GDD) px
	"armor": 0.1,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 8.0,  # TUNING (not in GDD)
	"faction": CourtEnemyData.FACTION,
	"feeds": 0.25,  # Owner-approved (Oct 31, 2026): the Court's kinds that are not vampires feed 25% (a witch; Bloodfeast.share_of() reads a boss's "feeds")
	"reward_xp": 620,  # TUNING (not in GDD) a step above Moloch's 600
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.5,  # TUNING (not in GDD) s she stands after a special
	"advance_range": 380.0,  # TUNING (not in GDD) px; farther than this she strides faster
	"advance_speed_mult": 1.7,  # TUNING (not in GDD)
	# Phases (HP shares).
	"phase2_hp": 0.66,  # TUNING (not in GDD) she splits into three sisters below this
	"phase3_hp": 0.33,  # TUNING (not in GDD) the Red Moon below this
	"phase2_banner": "Isolde SPLITS INTO THREE SISTERS: they must fall within 10 seconds of each other!",  # TUNING (not in GDD)
	"rise_banner": "A fallen sister rises again: strike them down together!",  # TUNING (not in GDD)
	"wane_banner": "The sabbath wanes: the fallen sisters no longer rise!",  # TUNING (not in GDD)
	"phase3_banner": "THE COVEN FALLS... ISOLDE CALLS THE BLOOD MOON: it will not set while she lives!",  # TUNING (not in GDD)
	"coven_break_banner": "THE COVEN BREAKS: all three sisters fell as one!",  # TUNING (not in GDD)
	# Hex circles on the ring (WitchHexes.cast_circle()).
	"first_circle": 4.0,  # TUNING (not in GDD) s after arrival
	"circle_every": 13.0,  # TUNING (not in GDD) s
	"circle_every_p3": 8.0,  # TUNING (not in GDD) s, the Red Moon
	"circle_count": 2,  # TUNING (not in GDD) circles, the Witch
	"circle_count_p3": 3,  # TUNING (not in GDD) circles, the Red Moon
	"circle_radius": 70.0,  # TUNING (not in GDD) px
	"circle_windup": 1.2,  # TUNING (not in GDD) s
	"circle_time": 5.0,  # TUNING (not in GDD) s
	"circle_heal": 0.05,  # TUNING (not in GDD) share of max HP per s for the Court inside
	"circle_drain": 3.5,  # TUNING (not in GDD) per s per summon, before the time scaling; first pass 6 (her circles and bombs broke the army to 6 summons)
	"circle_reach": 260.0,  # TUNING (not in GDD) px from her: the summons she may curse
	"cast_windup": 0.7,  # TUNING (not in GDD) s she stands with her hand raised
	# Cauldron bombs (WitchHexes.open_pool()).
	"first_bomb": 7.0,  # TUNING (not in GDD) s after arrival
	"bomb_every": 9.0,  # TUNING (not in GDD) s
	"bomb_every_p3": 6.5,  # TUNING (not in GDD) s, the Red Moon
	"bomb_count": 2,  # TUNING (not in GDD) bombs, the Witch
	"bomb_count_p3": 4,  # TUNING (not in GDD) bombs, the Red Moon
	"bomb_fall": 1.1,  # TUNING (not in GDD) s a bomb flies (its circle glows)
	"bomb_radius": 44.0,  # TUNING (not in GDD) px of the splash
	"bomb_scatter": 150.0,  # TUNING (not in GDD) px around the necromancer the other bombs fall
	"bomb_damage_player": 9.0,  # TUNING (not in GDD) before the time scaling
	"bomb_damage_summon": 5.0,  # TUNING (not in GDD) before the time scaling; first pass 8
	"pool_radius": 50.0,  # TUNING (not in GDD) px of the healing pool a bomb leaves
	"pool_life": 7.0,  # TUNING (not in GDD) s
	# Her thralls.
	"first_thralls": 10.0,  # TUNING (not in GDD) s after arrival
	"thrall_every": 16.0,  # TUNING (not in GDD) s
	"thrall_count": 6,  # TUNING (not in GDD) blood thralls (under the hard cap)
	# The three sisters.
	"sister_spread": 46.0,  # TUNING (not in GDD) px from her centre each sister appears
	"sisters_window": 10.0,  # Owner-approved proposal: "all three must fall within 10 s of each other"
	"rise_hp": 0.5,  # TUNING (not in GDD) share of a sister's life she rises with
	"rise_decay": 0.75,  # TUNING (not in GDD) x the rise share for every earlier rise of hers
	"rise_min": 0.15,  # TUNING (not in GDD) least share she rises with
	"sabbath_wane": 100.0,  # TUNING (not in GDD) s after the split the fallen stop rising (own decision: a floor)
	"coven_break": 1.0,  # Owner-approved achievement "The Coven Breaks": "within 1 s"
	# The Red Moon.
	"moon_hold": 1.5,  # TUNING (not in GDD) s the moon is forced ahead each tick (BloodMoon.force()); it sets this long after she falls
	"red_moon_speed": 58.0,  # TUNING (not in GDD) px/s
	"red_moon_damage": 16.0,  # TUNING (not in GDD) per blow
}
