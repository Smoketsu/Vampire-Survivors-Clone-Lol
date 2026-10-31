## MorningStarData — immutable design data of THE MORNING STAR, the Adversary,
## the boss of Pandemonium and the last of Part One (Act VI, Stage 18; GDD §15.0
## "The Morning Star (Act VI phase 2)"; owner-approved proposal
## docs/act6/PROPOSAL.md "Stage 18: Pandemonium", with the owner's decision of
## Oct 26, 2026: "His Throne phase is cut for now. He has two phases: the Angel,
## then the Beast"). BossMorningStar (scripts/enemies/inferno/
## boss_morning_star.gd, loaded by name for the boss id "morning_star") reads
## BOSS; StageRegistry.BOSS_ARRIVALS and PandemoniumStage.BOSS read ARRIVAL. He
## rises from the throne at 17:00 (3:00 left). His two phases:
##   THE ANGEL (100% -> beast_hp): beautiful, six burnt wings, a burning sword.
##        He walks at the necromancer (enemies always advance) and fights with
##        the BURNING SWORD (a cone of sword_range px, sword_arc degrees each
##        side, telegraphed sword_telegraph s, when a body is within
##        sword_trigger px), and turns between LIGHT and DARK BEAMS:
##          LIGHT: light_count lines light_length px long, light_spread
##          degrees apart, fanned at the necromancer from him, telegraphed
##          light_telegraph s (HOLY);
##          DARK: dark_count lines dark_length px long, spread evenly around a
##          point dark_offset px to one side of the necromancer (crossing his
##          army), telegraphed dark_telegraph s (AREA).
##   THE TRANSFORMATION (change_time s, invulnerable): the angel burns away;
##        the throne-skull Beast rises in his place.
##   THE BEAST (beast_hp -> 0): huge (beast_radius px), slow
##        (beast_speed_mult), slamming. His SLAM: a circle of slam_radius px
##        on the necromancer (or his nearest summon pack), telegraphed
##        slam_telegraph s; every body in it is struck, summons thrown
##        slam_push px back, and a Hell Pit (slam_pit_radius, slam_pit_life)
##        opens where it fell. THE ARENA TURNS TO PITS: every pits_every s a
##        ring of pits_count telegraphed pits (pits_radius px, pits_life s)
##        opens pits_ring px around the necromancer, the gaps between them
##        the only way out (HellPits.open_pit(), tag "morning_star").
## He is invulnerable while he rises and transforms, and never falls below
## beast_hp while the Angel stands. When he FALLS, the necromancer takes the
## throne (ENDING_ANNOUNCE; no epilogue, owner decision Oct 31, 2026).
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist) and the abilities' own
## numbers. The GDD gives no numbers: everything is TUNING (not in GDD) unless
## marked as the owner-approved proposal.
class_name MorningStarData
extends RefCounted

## His arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "morning_star" through PandemoniumStage.BOSS, so --boss=morning_star and the
## Codex find him). The defeat banner is the ending line.
const ARRIVAL := {
	"id": "morning_star",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "The Morning Star",  # Owner-approved proposal
	"short_name": "The Morning Star",
	"arrive_banner": "The Morning Star rises from his throne!",  # TUNING (not in GDD)
	"defeat_banner": "The Morning Star falls. The throne of hell stands empty... and waits for you.",  # Owner-approved proposal ("When he falls, the necromancer takes the throne")
	"dead_objective": "The throne is yours. Now survive the Last Judgment... you cannot.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["burning_sword", "light_beams", "dark_beams", "transform", "beast_slam", "pit_ring"]

## Damage source tag of the burning sword (the Angel).
const SRC_SWORD: String = "morning_star_sword"
## Damage source tag of a light beam (HOLY).
const SRC_LIGHT: String = "morning_star_light"
## Damage source tag of a dark beam (AREA).
const SRC_DARK: String = "morning_star_dark"
## Damage source tag of the Beast's slam (AREA).
const SRC_SLAM: String = "morning_star_slam"

## Sprite key of the Angel (BossPoseData pose 1: the sword raised).
const SPRITE_ANGEL: String = "bosses/morning_star"
## Sprite key of the Beast (its own still; the throne-skull form).
const SPRITE_BEAST: String = "bosses/morning_star_beast"

## Seconds the ending line (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## HUD announcement on his defeat (title, line, description): the proposal's
## ending ("When he falls, the necromancer takes the throne"), kept short (the
## owner holds the epilogue until the act order is settled).
const ENDING_ANNOUNCE := ["THE THRONE IS YOURS", "The Morning Star falls.", "You climb the burning steps and sit. The dead of heaven, earth and hell kneel, and answer to you."]  # Owner-approved proposal ending (TUNING the words)
## Shorter announcement when he falls after 0:00 (the Last Judgment rages on).
const LATE_ANNOUNCE := ["THE THRONE IS YOURS", "The Morning Star falls.", "Even in the Last Judgment, hell kneels to its new lord."]  # TUNING (not in GDD)

## His design row.
const BOSS := {
	"display_name": "The Morning Star",
	"max_hp": 14000.0,  # TUNING (not in GDD) x the stage HP multiplier (24,500 on Pandemonium; Amaterasu 14,000 on the Road)
	"move_speed": 44.0,  # TUNING (not in GDD) px/s; the Angel walks, the Beast lumbers (beast_speed_mult)
	"damage": 14.0,  # TUNING (not in GDD) a blow in reach, before the time scaling
	"attack_interval": 1.3,  # TUNING (not in GDD) s
	"attack_range": 16.0,  # TUNING (not in GDD) px
	"radius": 24.0,  # TUNING (not in GDD) px (the Angel; the Beast grows to beast_radius)
	"armor": 0.15,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 1.0,
	"mass": 24.0,  # TUNING (not in GDD) shoves the ring aside
	"slow_resist": 0.7,  # TUNING (not in GDD) like every boss
	"reward_xp": 900,  # TUNING (not in GDD) as Amaterasu
	"reward_crystals": 30,  # TUNING (not in GDD)
	"arrive_time": 2.0,  # TUNING (not in GDD) s he rises (invulnerable)
	"advance_range": 380.0,  # TUNING (not in GDD) px beyond which he strides faster
	"advance_speed_mult": 2.0,  # TUNING (not in GDD)
	"beast_hp": 0.5,  # Owner decision Oct 26 (two phases); TUNING the split
	"change_time": 3.0,  # TUNING (not in GDD) s of the transformation (invulnerable)
	# The Angel.
	"sword_trigger": 90.0,  # TUNING (not in GDD) px: he swings at a body this close
	"sword_cooldown": 4.0,  # TUNING (not in GDD) s
	"sword_range": 110.0,  # TUNING (not in GDD) px
	"sword_arc": 60.0,  # TUNING (not in GDD) degrees each side
	"sword_telegraph": 0.8,  # TUNING (not in GDD) s
	"sword_damage_player": 14.0,  # TUNING (not in GDD) before the time scaling
	"sword_damage_summon": 16.0,  # TUNING (not in GDD) before the time scaling
	"sword_push": 34.0,  # TUNING (not in GDD) px
	"beam_first": 3.0,  # TUNING (not in GDD) s after the Angel begins
	"beam_cooldown": 5.0,  # TUNING (not in GDD) s between two beam attacks (light and dark take turns)
	"light_count": 3,  # TUNING (not in GDD) lines
	"light_spread": 14.0,  # TUNING (not in GDD) degrees between two light lines
	"light_length": 420.0,  # TUNING (not in GDD) px
	"light_width": 22.0,  # TUNING (not in GDD) px
	"light_telegraph": 1.0,  # TUNING (not in GDD) s
	"light_damage_player": 12.0,  # TUNING (not in GDD) before the time scaling
	"light_damage_summon": 11.0,  # TUNING (not in GDD) before the time scaling
	"dark_count": 4,  # TUNING (not in GDD) lines through one point
	"dark_length": 340.0,  # TUNING (not in GDD) px
	"dark_width": 26.0,  # TUNING (not in GDD) px
	"dark_offset": 60.0,  # TUNING (not in GDD) px beside the necromancer (they cross his army)
	"dark_telegraph": 1.2,  # TUNING (not in GDD) s
	"dark_damage_player": 11.0,  # TUNING (not in GDD) before the time scaling
	"dark_damage_summon": 13.0,  # TUNING (not in GDD) before the time scaling
	# The Beast.
	"beast_radius": 34.0,  # TUNING (not in GDD) px (drawn huge)
	"beast_speed_mult": 0.75,  # TUNING (not in GDD) x his walk
	"slam_first": 2.0,  # TUNING (not in GDD) s after the Beast rises
	"slam_cooldown": 4.5,  # TUNING (not in GDD) s
	"slam_radius": 70.0,  # TUNING (not in GDD) px
	"slam_telegraph": 1.1,  # TUNING (not in GDD) s
	"slam_damage_player": 16.0,  # TUNING (not in GDD) before the time scaling
	"slam_damage_summon": 18.0,  # TUNING (not in GDD) before the time scaling
	"slam_push": 40.0,  # TUNING (not in GDD) px
	"slam_pit_radius": 40.0,  # TUNING (not in GDD) px
	"slam_pit_life": 8.0,  # TUNING (not in GDD) s
	"pits_first": 4.0,  # TUNING (not in GDD) s after the Beast rises
	"pits_every": 9.0,  # TUNING (not in GDD) s
	"pits_count": 5,  # TUNING (not in GDD) pits in the ring
	"pits_ring": 150.0,  # TUNING (not in GDD) px from the necromancer
	"pits_radius": 46.0,  # TUNING (not in GDD) px
	"pits_life": 10.0,  # TUNING (not in GDD) s
	"pits_telegraph": 1.5,  # Owner-approved proposal: a pit's "glowing rim for 1.5 s"
}
