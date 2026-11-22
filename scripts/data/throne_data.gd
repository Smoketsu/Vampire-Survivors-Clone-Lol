## ThroneData — immutable design data for THE THRONE, the boss of the Wheel of
## Thrones (temporary Act XIII, the Celestial Host, final slot X; GDD §15.0
## "The Throne (Act XIII phase 2)"; owner-approved proposal
## docs/proposals/LAST_SIX_ACTS.md section X: "Boss, the Throne (a colossal
## wheel within a wheel, rims covered in eyes): the Rolling (it crosses the
## arena in straight lines and rebounds), the Gaze (every eye opens: beams from
## the rim toward the necromancer that only shadows stop), the Core (the wheels
## open and a burning eye at the centre can be hurt for 10 s at a time)").
## BossThrone (scripts/enemies/host/boss_throne.gd, loaded by name for the boss
## id "throne") reads it. A colossal wheel within a wheel of silver and blue
## fire, its rims covered in eyes (art `host/throne`, 96 px, and
## `host/throne_core`; no crimson, no warm gold). It loops one cycle:
##   * THE ROLLING: it marks its line for roll_windup s, then rolls straight at
##     roll_speed px/s for roll_time s; once it is more than roll_bound px from
##     the nearest necromancer and still rolling away, it REBOUNDS (its line is
##     mirrored about the line back to him), so it crosses and recrosses the
##     ring. Every summon and necromancer under its rim (radius + roll_reach)
##     takes roll_damage_summon / roll_damage every roll_tick s (x the time
##     scaling).
##   * THE GAZE: it stops for gaze_cast s (its eyes open), then every eye looks:
##     gaze_beams shafts of Hallowed Light start on its rim and sweep toward the
##     necromancer, gaze_spread degrees apart, gaze_width px wide, running
##     gaze_past px beyond him (HallowedLight.add_shaft(), the Light's one
##     path: only shade and barriers stop a shaft). The Light's max_live is
##     raised by the beams while they run.
##   * THE CORE: the wheels open for core_time s (the owner-approved 10 s) and
##     the burning eye at the centre takes full damage; at every other time the
##     rims take only rim_mult of every hit (BossThrone.damage_taken_mult()).
##   * Below phase2_hp (EVERY EYE OPENS): it rolls faster (roll_speed_p2) and
##     looks with more beams (gaze_beams_p2).
## Beaten: a short ending text (ENDING_ANNOUNCE; no epilogue part until the
## reorder pass). Killing it drops a big XP burst and the boss chest; slaying it
## unlocks Wheel of Eyes, All-Seeing and so the Blind Saint (UnlockData, boss
## "throne"); THE WHEEL BREAKS is judged by WheelOfThronesDirector when it falls
## (BossThrone.wheel_breaks(): the killing blow on the open Core and at least
## WHEEL_BREAKS_SHARE of its health lost while the Core was open).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name ThroneData
extends RefCounted

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["roll", "rebound", "gaze", "core"]

## Sprite key of its art (assets/sprites/host/throne.png, 96 px, roll strip).
const SPRITE: String = "host/throne"
## Sprite key of the burning eye at its centre (assets/sprites/host/throne_core.png, 32 px).
const CORE_SPRITE: String = "host/throne_core"
## Damage tag of its rolling rim (stats, the death line).
const ROLL_SOURCE: String = "throne_roll"
## Share (0..1) of the Throne's lost health that must fall while the Core is
## open, with the killing blow on the open Core, for THE WHEEL BREAKS (own
## reading of "beat the Throne by its core alone": the rims can be chipped, so
## "alone" is a share, not every point).
const WHEEL_BREAKS_SHARE: float = 0.8  # TUNING (not in GDD)
## Seconds the ending line (the arrival's defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## The short ending text shown when it falls (HUD announce: title, line, text).
const ENDING_ANNOUNCE := ["THE WHEEL STOPS", "The Throne breaks on its own rims, and every eye on them closes.", "The spheres turn on without it. Above them, a white rose of light is waiting."]  # TUNING (not in GDD) the words
## The ending text when it falls during the Last Trumpet.
const LATE_ANNOUNCE := ["THE WHEEL STOPS", "The Throne breaks as the trumpets sound.", "Its eyes close, but the whole Host is still coming down the spheres."]  # TUNING (not in GDD) the words

## The Throne's base max HP (x the boss HP multiplier and the stage's HP
## multiplier). Lower than Seraiel's 16,000 because the rims take only
## rim_mult outside the Core (about half the damage over a whole cycle).
const MAX_HP: float = 7000.0  # TUNING (not in GDD) first passes 10,000 and 8,500: most army bot fights ran past 0:00

## The Throne's design row.
const BOSS := {
	"display_name": "The Throne",
	"max_hp": MAX_HP,
	"move_speed": 36.0,  # TUNING (not in GDD) px/s while it turns toward the necromancer between rolls
	"damage": 12.0,  # TUNING (not in GDD) a blow of the rim in reach, before the time scaling
	"attack_interval": 1.4,  # TUNING (not in GDD) s
	"attack_range": 16.0,  # TUNING (not in GDD) px
	"radius": 30.0,  # TUNING (not in GDD) px (the sprite 96 px wide)
	"armor": 0.2,  # TUNING (not in GDD) silver rims
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 30.0,  # TUNING (not in GDD) the ring never shoves a throne
	"faction": HostEnemyData.FACTION,
	"group": "guardians",  # The Throne leads the guardians (the reports).
	"reward_xp": 600,  # TUNING (not in GDD) as Seraiel
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	# The cycle.
	"walk_time": 3.0,  # TUNING (not in GDD) s it turns toward the necromancer after the Core (and when it arrives)
	"phase2_hp": 0.5,  # TUNING (not in GDD) EVERY EYE OPENS below this share of its HP
	"phase1_banner": "THE ROLLING: the Throne rolls across the spheres! Step out of its line!",  # TUNING (not in GDD)
	"phase2_banner": "EVERY EYE OPENS: the Throne rolls faster and looks with every eye!",  # TUNING (not in GDD)
	"core_banner": "THE CORE: the wheels open! Strike the burning eye!",  # TUNING (not in GDD)
	"gaze_banner": "THE GAZE: every eye on the rims opens! Find shade!",  # TUNING (not in GDD)
	# The Rolling.
	"roll_windup": 0.9,  # TUNING (not in GDD) s its line is marked before it rolls
	"roll_time": 6.0,  # TUNING (not in GDD) s it rolls
	"roll_speed": 230.0,  # TUNING (not in GDD) px/s
	"roll_speed_p2": 280.0,  # TUNING (not in GDD) px/s below phase2_hp
	"roll_bound": 360.0,  # TUNING (not in GDD) px from the nearest necromancer past which it rebounds
	"roll_reach": 6.0,  # TUNING (not in GDD) px beyond its radius its rim strikes
	"roll_tick": 0.35,  # TUNING (not in GDD) s between two strikes on the same bodies
	"roll_damage": 8.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"roll_damage_summon": 7.0,  # TUNING (not in GDD) to each summon under the rim, before the time scaling
	# The Gaze.
	"gaze_cast": 1.0,  # TUNING (not in GDD) s its eyes open before the beams
	"gaze_hold": 2.0,  # TUNING (not in GDD) s it stands after the beams start
	"gaze_beams": 2,  # TUNING (not in GDD) shafts at once
	"gaze_beams_p2": 3,  # TUNING (not in GDD) shafts below phase2_hp ("every eye opens")
	"gaze_spread": 24.0,  # TUNING (not in GDD) degrees between two beams
	"gaze_width": 40.0,  # TUNING (not in GDD) px, each beam's width
	"gaze_past": 240.0,  # TUNING (not in GDD) px a beam runs beyond the necromancer
	# The Core.
	"core_time": 10.0,  # Owner-approved proposal: "can be hurt for 10 s at a time"
	"rim_mult": 0.2,  # TUNING (not in GDD) share of every hit the closed wheels take
}
