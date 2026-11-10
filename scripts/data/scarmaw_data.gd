## ScarmawData — immutable design data for SCARMAW, THE GREAT RAPTOR, the boss of
## the Fern Basin (temporary Act XIV, the Age of Titans, final slot XIV; GDD
## §15.0 "Scarmaw, the Great Raptor (Act XIV phase 2)"; owner-approved proposal
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 2, "Stage A: The Fern Basin":
## "Boss: Scarmaw, the Great Raptor (female alpha). The Hunt: she commands three
## packs in turn and leaps over the ring. The Ambush: she vanishes into marked
## fern patches and lunges from one every 8 s. Blood Up: at half health her pack
## respawns for every kill and she moves faster; kill her alpha-guard to end
## it."). BossScarmaw (scripts/enemies/primeval/boss_scarmaw.gd, loaded by name
## for the boss id "scarmaw") reads it. A huge feathered raptor with a bone
## crest and a scarred muzzle (art `primeval/scarmaw`, 72x60; a beast: no
## figure style). Her fight, by her HP:
##   * THE HUNT (all fight): every hunt_every s she calls a pack of hunt_size
##     Razorclaws onto the spawn ring, each from the next of three sides in
##     turn (120 degrees apart; a group that comes in one tick is a pack with
##     its alpha, PackBrain); at most hunt_cap Razorclaws alive. While she is
##     not hiding, every leap_every s (once the necromancer is within
##     leap_trigger px) she crouches leap_windup s and LEAPS OVER THE RING in
##     leap_time s (a landing circle shows) to a point leap_land px from the
##     necromancer on her side: every grounded summon and necromancer within
##     leap_radius px of the landing takes leap_damage_summon / leap_damage (x
##     the time scaling).
##   * THE AMBUSH (below ambush_hp): she VANISHES (untargetable: nothing aims
##     at or hits her) and marks `patches` fern patches patch_dist px round the
##     necromancer (seeded angles, drawn); every ambush_every s one patch
##     rustles for rustle_time s and she LUNGES out of it at the necromancer at
##     lunge_speed px/s, up to lunge_len px: the first summon or necromancer she
##     touches takes lunge_damage_summon / lunge_damage; then she fights in the
##     open for exposed_time s before she vanishes again (new patches round the
##     necromancer).
##   * BLOOD UP (below blood_hp): her ALPHA-GUARD (FernBasinEnemyData
##     "scarmaw_guard") comes to her side; while the guard lives every
##     Razorclaw killed comes back on the spawn ring (at most blood_cap alive,
##     one every blood_gap s at most) and she moves x blood_speed faster. Kill
##     the guard and Blood Up ends.
## Beaten: a short ending text (no epilogue part until the reorder pass).
## Killing her drops a big XP burst and the boss chest; slaying her unlocks Pack
## Leap, Pack Instinct and so the Fern Huntress (UnlockData, boss "scarmaw").
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name ScarmawData
extends RefCounted

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["hunt", "leap", "ambush", "lunge", "blood_up", "blood_respawn"]

## Sprite key of her art (assets/sprites/primeval/scarmaw.png, 72x60, walk
## strip, pose 1 the leap).
const SPRITE: String = "primeval/scarmaw"
## Damage tag of her leap's landing (stats, the death line).
const LEAP_SOURCE: String = "scarmaw_leap"
## Damage tag of her ambush lunge (stats, the death line).
const LUNGE_SOURCE: String = "scarmaw_lunge"
## Seconds the ending line (the arrival's defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## The short ending text shown when she falls (HUD announce: title, line, text).
const ENDING_ANNOUNCE := ["THE PACK SCATTERS", "Scarmaw, the Great Raptor, falls among the ferns.", "Out on the plain the herds are restless, and the white streak in the sky is brighter."]  # TUNING (not in GDD) the words
## The ending text when she falls during the Stampede of Ash.
const LATE_ANNOUNCE := ["THE PACK SCATTERS", "Scarmaw falls as the sky burns.", "Her hunters are gone, but every beast of the basin is running."]  # TUNING (not in GDD) the words

## Scarmaw's base max HP (x the boss HP multiplier and the stage's HP multiplier).
const MAX_HP: float = 10500.0  # TUNING (not in GDD) the Hive Mother's 12,500 (x2.15) is out of reach part of her fight too; here x2.2

## Scarmaw's design row.
const BOSS := {
	"display_name": "Scarmaw, the Great Raptor",
	"max_hp": MAX_HP,
	"move_speed": 64.0,  # TUNING (not in GDD) px/s; a raptor's stride
	"damage": 12.0,  # TUNING (not in GDD) a rake in reach, before the time scaling
	"attack_interval": 1.1,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 20.0,  # TUNING (not in GDD) px (the sprite 72x60)
	"armor": 0.2,  # TUNING (not in GDD) feathered hide
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 10.0,  # TUNING (not in GDD)
	"faction": PrimevalEnemyData.FACTION,
	"group": "hunters",  # The great alpha leads the hunters (the reports).
	"reward_xp": 600,  # TUNING (not in GDD) as Seraiel
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.5,  # TUNING (not in GDD) s she stands after a special
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this she strides faster
	"advance_speed_mult": 1.8,  # TUNING (not in GDD)
	"arrive_banner": "THE HUNT: Scarmaw calls her packs and leaps over your ring!",  # TUNING (not in GDD)
	# The Hunt.
	"hunt_first": 4.0,  # TUNING (not in GDD) s after she arrives
	"hunt_every": 18.0,  # TUNING (not in GDD) s between two packs
	"hunt_size": 4,  # TUNING (not in GDD) Razorclaws a pack
	"hunt_cap": 12,  # TUNING (not in GDD) Razorclaws alive at most for a pack to come
	"hunt_turn": 120.0,  # Owner-approved proposal: "three packs in turn"; degrees between two packs' sides
	"leap_first": 6.0,  # TUNING (not in GDD) s after she arrives
	"leap_every": 9.0,  # TUNING (not in GDD) s between two leaps
	"leap_trigger": 420.0,  # TUNING (not in GDD) px to the necromancer for a leap to start
	"leap_windup": 0.7,  # TUNING (not in GDD) s she crouches (the landing circle shows)
	"leap_time": 0.6,  # TUNING (not in GDD) s in the air
	"leap_land": 70.0,  # Owner-approved proposal: "leaps over the ring"; TUNING (not in GDD) px from the necromancer she lands (inside the ring)
	"leap_radius": 44.0,  # TUNING (not in GDD) px of the landing
	"leap_damage": 9.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"leap_damage_summon": 10.0,  # TUNING (not in GDD) to each summon, before the time scaling
	# The Ambush.
	"ambush_hp": 0.7,  # TUNING (not in GDD) HP share below which she hides in the ferns
	"ambush_banner": "THE AMBUSH: Scarmaw vanishes into the ferns! Watch the patch that rustles!",  # TUNING (not in GDD)
	"patches": 4,  # TUNING (not in GDD) marked fern patches
	"patch_dist": 230.0,  # TUNING (not in GDD) px from the necromancer (outside the ring)
	"patch_radius": 30.0,  # TUNING (not in GDD) px, drawing only
	"ambush_every": 8.0,  # Owner-approved proposal: "lunges from one every 8 s"
	"rustle_time": 1.0,  # TUNING (not in GDD) s the chosen patch rustles before she lunges
	"exposed_time": 4.5,  # TUNING (not in GDD) s she fights in the open after a lunge (then she hides again)
	"lunge_speed": 420.0,  # TUNING (not in GDD) px/s
	"lunge_len": 260.0,  # TUNING (not in GDD) px at most
	"lunge_damage": 10.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"lunge_damage_summon": 16.0,  # TUNING (not in GDD) to the summon she seizes, before the time scaling
	# Blood Up.
	"blood_hp": 0.5,  # Owner-approved proposal: "at half health"
	"blood_banner": "BLOOD UP: Scarmaw's pack comes back for every kill! Kill her alpha-guard!",  # TUNING (not in GDD)
	"blood_end_banner": "The alpha-guard is down: Scarmaw's blood cools!",  # TUNING (not in GDD)
	"blood_speed": 1.25,  # Owner-approved proposal: "she moves faster"; TUNING (not in GDD) x
	"blood_cap": 10,  # TUNING (not in GDD) Razorclaws alive at most for one to come back
	"blood_gap": 1.0,  # TUNING (not in GDD) s between two returns at most
	"guard_dist": 40.0,  # TUNING (not in GDD) px beside her the guard comes in
}
