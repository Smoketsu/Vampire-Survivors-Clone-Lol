## HiveMotherData — immutable design data for THE HIVE MOTHER, the boss of the
## Crash Site (Act IX, Stage 25; GDD §15.0 "The Hive Mother (Act IX)";
## owner-approved proposal docs/act9/PROPOSAL.md: "the Hive Mother: a vast
## queen grown into the crater. The Brood (egg waves and burrowers from every
## side), the Burrow (she dives under the arena and erupts beneath the ring on
## a telegraph), the Flight (she tears loose and takes to the air, raining
## acid)"; the brief: female, figure style, a short ending text only, no
## epilogue). BossHiveMother (scripts/enemies/concord/boss_hive_mother.gd,
## loaded by name for the boss id "hive_mother") reads it. A vast female insect
## queen in her own purple chitin (the `hive` ramp, never the necromancer's
## violet) that covers her completely, wings, a horned helm and an egg-sac
## abdomen. Three phases by her HP:
##   * The Brood (100% to phase2_hp): she walks in with the shared AI, her
##     bone claws in reach. Every egg_every s she rears (cast pose, egg_windup
##     s) and lays an EGG WAVE: egg_count Infestation eggs on a ring egg_min..
##     egg_max px around the nearest necromancer, through the one egg path
##     (CrashSiteDirector.lay_anywhere(), tag "wave"; the egg cap applies).
##     Every burrowers_every s BURROWERS come from every side: burrowers_count
##     of them on the spawn ring at even angles (they tunnel in: BurrowerKit),
##     under the hard cap.
##   * The Burrow (phase2_hp to phase3_hp): her cycle: she DIVES (dive_time s,
##     sinking: untargetable from its start), travels UNDER the arena
##     (under_time s at under_speed px/s toward the necromancer; untargetable
##     and passing under the ring), then a big MOUND shows where he stood when
##     it began (mound_time s, the telegraph; mound_radius px drawn) and she
##     ERUPTS there: every grounded summon within erupt_radius px takes
##     erupt_damage_summon and every necromancer erupt_damage (time-scaled,
##     once), and the ground she broke turns to live alien turf
##     (Terraforming.seed(), tag "eruption", erupt_turf px; the turf never
##     heals her: boss_mult). She then stays up surface_time s (claws in reach,
##     every hit lands) before she dives again. Burrowers keep coming every
##     burrowers_every s.
##   * The Flight (below phase3_hp): she tears loose and takes to the air
##     (Enemy.flies while airborne: no summon body-blocks her; a grounded melee
##     blow deals flight_melee_taken of itself): she circles the nearest
##     necromancer at hover_radius px (hover_turn rad/s, fly_speed px/s) and
##     RAINS ACID: every acid_every s acid_globs globs fall through THE ACID
##     PATH (ConcordRules.acid, AcidPools.lob(): the Acid Spitter's puddles),
##     the first on the necromancer's spot, the rest acid_min..acid_max px
##     around him (fixed angles turned by the volley count, no RNG).
## Beaten: a short ending text only (ENDING_ANNOUNCE; no epilogue part, owner).
## Killing her drops a big XP burst and the boss chest; slaying her unlocks
## Bone Beetles, Chitin and so the Broodbound (UnlockData, boss "hive_mother"),
## and NOTHING HATCHED is judged by CrashSiteDirector. The GDD gives no
## numbers: everything is TUNING (not in GDD) unless marked as the
## owner-approved proposal.
class_name HiveMotherData
extends RefCounted

## The Hive Mother's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "hive_mother" through CrashSiteStage.BOSS, so
## --boss=hive_mother and the Codex find her).
const ARRIVAL := {
	"id": "hive_mother",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "The Hive Mother",  # Owner-approved proposal
	"short_name": "Hive Mother",
	"arrive_banner": "The Hive Mother tears loose from the crater!",  # TUNING (not in GDD)
	"defeat_banner": "The Hive Mother falls, and the swarm falters! Hold out until the end...",  # TUNING (not in GDD)
	"dead_objective": "The Hive Mother is dead. Survive the Final Harvest... you cannot.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["egg_wave", "burrowers", "burrow", "eruption", "flight", "acid_rain"]

## Sprite key of her art (assets/sprites/bosses/hive_mother.png; the
## foundation's 96 px still, glide and idle strips; poses in BossPoseData).
const SPRITE: String = "bosses/hive_mother"
## Sprite key of her Flight form (wings spread, egg sac tucked; its own glide
## strip `_walk`), drawn while she is airborne.
const FLIGHT_SPRITE: String = "bosses/hive_mother_flight"
## Damage tag of her eruption.
const ERUPT_SOURCE: String = "hive_eruption"
## Damage tag of her acid rain's splash (the puddles are ConcordRulesData.ACID_SOURCE).
const ACID_SOURCE: String = "hive_acid"
## Seconds the ending line (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## The short ending text shown when she falls (HUD announce: title, line,
## text). Owner (brief): a short ending text only, no epilogue.
const ENDING_ANNOUNCE := ["THE HIVE IS SILENT", "The Hive Mother falls.", "The crater cools around her, and her last eggs go dark. Beyond the clouds the mothership waits, and watches."]  # TUNING (not in GDD) the words
## The ending text when she falls during the Final Harvest.
const LATE_ANNOUNCE := ["THE HIVE IS SILENT", "The Hive Mother falls under the open eye.", "The swarm scatters into the ruins, and the harvest goes on without its queen."]  # TUNING (not in GDD) the words

## The Hive Mother's base max HP (x the boss HP multiplier and the stage's HP
## multiplier 2.15; Don Marrow 15,000 x 2.0, Paragon on Liberty Heights).
const MAX_HP: float = 12500.0  # TUNING (not in GDD) she is out of reach part of the Burrow (first pass 14000: the seed-2 army bot had not slain her by 0:00)

## The Hive Mother's design row.
const BOSS := {
	"display_name": "The Hive Mother",
	"max_hp": MAX_HP,
	"move_speed": 40.0,  # TUNING (not in GDD) px/s; a vast, slow queen
	"damage": 12.0,  # TUNING (not in GDD) her bone claws in reach
	"attack_interval": 1.4,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 24.0,  # TUNING (not in GDD) px (the sprite 96 px tall, drawn larger)
	"armor": 0.2,  # TUNING (not in GDD) chitin
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 14.0,  # TUNING (not in GDD)
	"faction": ConcordEnemyData.FACTION,
	"race": "brood",  # The Brood's queen (the reports group her there).
	"reward_xp": 600,  # TUNING (not in GDD) as Don Marrow
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.4,  # TUNING (not in GDD) s she stands after a special
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this she strides faster
	"advance_speed_mult": 1.8,  # TUNING (not in GDD)
	# Phases (HP shares).
	"phase2_hp": 0.66,  # TUNING (not in GDD) the Burrow below this
	"phase3_hp": 0.33,  # TUNING (not in GDD) the Flight below this
	"phase2_banner": "THE BURROW: the Hive Mother dives under the ruins! Step off the mound before she erupts!",  # TUNING (not in GDD)
	"phase3_banner": "THE FLIGHT: the Hive Mother tears loose and takes to the air! Out of the acid!",  # TUNING (not in GDD)
	# The Brood: egg waves and burrowers.
	"egg_first": 3.0,  # TUNING (not in GDD) s after she arrives
	"egg_every": 10.0,  # TUNING (not in GDD) s between two egg waves
	"egg_windup": 0.8,  # TUNING (not in GDD) s she rears (cast pose)
	"egg_count": 6,  # TUNING (not in GDD) eggs a wave
	"egg_min": 70.0,  # TUNING (not in GDD) px from the necromancer
	"egg_max": 150.0,  # TUNING (not in GDD) px (the ring is 60-150 px)
	"burrowers_first": 6.0,  # TUNING (not in GDD) s after she arrives
	"burrowers_every": 20.0,  # TUNING (not in GDD) s between two burrower waves (the Brood and the Burrow; first pass 14: her fight broke the seed-2 army's ring)
	"burrowers_count": 4,  # Owner-approved proposal: "burrowers from every side" (four sides); TUNING (not in GDD) the count
	# The Burrow.
	"dive_time": 0.8,  # TUNING (not in GDD) s she sinks
	"under_time": 1.4,  # TUNING (not in GDD) s under the arena before the mound shows
	"under_speed": 240.0,  # TUNING (not in GDD) px/s underground
	"mound_time": 1.4,  # TUNING (not in GDD) s the mound shows before she erupts (the telegraph)
	"mound_radius": 44.0,  # TUNING (not in GDD) px of the mound drawn (the Burrower's 18, larger)
	"erupt_radius": 70.0,  # TUNING (not in GDD) px
	"erupt_damage": 14.0,  # TUNING (not in GDD) to a necromancer, before the time scaling, once
	"erupt_damage_summon": 20.0,  # TUNING (not in GDD) to a summon, before the time scaling, once
	"erupt_turf": 64.0,  # TUNING (not in GDD) px of live alien turf the eruption leaves (Terraforming.seed())
	"surface_time": 5.0,  # TUNING (not in GDD) s she stays up after an eruption
	# The Flight.
	"fly_speed": 72.0,  # TUNING (not in GDD) px/s
	"hover_radius": 170.0,  # TUNING (not in GDD) px from the necromancer
	"hover_turn": 0.35,  # TUNING (not in GDD) rad/s she circles
	"flight_melee_taken": 0.5,  # TUNING (not in GDD) share of a grounded melee blow she takes aloft (she swoops low)
	"acid_first": 2.0,  # TUNING (not in GDD) s after the phase begins
	"acid_every": 3.6,  # TUNING (not in GDD) s between two acid volleys (first pass 3.2)
	"acid_globs": 5,  # TUNING (not in GDD) globs a volley
	"acid_min": 60.0,  # TUNING (not in GDD) px from the necromancer
	"acid_max": 140.0,  # TUNING (not in GDD) px
	"acid_flight": 1.0,  # TUNING (not in GDD) s each glob falls (its landing telegraph shows as long)
	"acid_radius": 32.0,  # TUNING (not in GDD) px (the Acid Spitter's 28, larger)
	"acid_life": 4.0,  # TUNING (not in GDD) s
	"acid_dps": 3.0,  # TUNING (not in GDD) before the time scaling (first pass 4)
	"acid_impact": 3.0,  # TUNING (not in GDD) the splash, before the time scaling (first pass 6: the seed-1 army bot fell to 43% in her Flight, 68 HP from the splashes)
}
