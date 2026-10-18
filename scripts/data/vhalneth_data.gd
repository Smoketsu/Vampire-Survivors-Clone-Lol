## VhalnethData — immutable design data for VHAL'NETH, THE DREAMING MOTHER,
## the final boss of Act II (Ul-Thalos, the Risen Spire; GDD §15.0
## "Ul-Thalos, the Risen Spire", owner-approved proposal). BossVhalneth reads
## BOSS; StageRegistry.BOSS_ARRIVALS and SpireStage.BOSS read ARRIVAL.
## She is colossal and mostly off screen: the boss body is her FACE, out in
## the sea beside the island, and the army fights her ARMS (SpireEnemyData
## "vhalneth_arm", ArmKit) rising out of the surf at the shore. Three phases:
##   Dreaming  (100% -> stirring_hp_fraction): her face lies under the water,
##             eyes shut, out of reach (untargetable, no damage); dream_arms_base
##             arms plus one per dream pillar still standing (SpireDirector)
##             rise around the island and slam telegraphed lanes. Each arm
##             severed wounds her for dream_wound_share / arms of her max HP;
##             the last one severed ends the phase.
##   Stirring  (-> waking_hp_fraction): the face surfaces just beyond the shore
##             (now in reach), her eyes open, and her GAZE rests on the island:
##             a telegraphed circle that drifts after the necromancer; inside
##             it his Dread climbs fast (game.dread.add(.., "gaze")) and the
##             undead wither, so the army has to move. Stirring arms keep
##             slamming and regrow.
##   Waking    (-> 0): the face rises out of the sea onto the shore and becomes
##             the weak point (waking_damage_taken), ringed by her arms; she
##             roars (a telegraphed nova around her face) and her gaze comes
##             faster.
## Killing her plays the finale: the necromancer raises the dead god and the
## Eye's own ritual binds her to him (ENDING_ANNOUNCE, the defeat banner).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless tagged.
class_name VhalnethData
extends RefCounted

## Her special ability ids in report order (the autotest "boss attacks" line
## reads the boss_atk_<id> stats).
const SPECIALS := ["slam", "gaze", "roar", "arms"]

## Boss row: Enemy row keys plus her ability numbers (see the header).
const BOSS := {
	"display_name": "Vhal'Neth, the Dreaming Mother",
	"max_hp": 20000.0,  # TUNING (not in GDD) x the stage HP multiplier (25,000 in Ul-Thalos, Seraphine 23,100 in the Sanctum), split between her arms and her face (balance passes: 34,000 -> 28,000 -> 24,000 -> 20,000, a 1-2 min fight)
	"move_speed": 0.0,  # She glides along the coast (glide_speed), she never walks.
	"damage": 14.0,  # TUNING (not in GDD) a bite of the face in reach (Waking)
	"attack_interval": 1.4,  # TUNING (not in GDD)
	"attack_range": 10.0,  # TUNING (not in GDD)
	"radius": 44.0,  # TUNING (not in GDD) px: her face, the weak point
	"armor": 0.1,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 40.0,  # TUNING (not in GDD) nothing shoves a god
	"slow_resist": 1.0,  # Never slowed (she does not walk).
	"reward_xp": 600,  # TUNING (not in GDD) the act's last boss: more than Seraphine's 500
	"reward_crystals": 28,  # TUNING (not in GDD)
	# Where the face sits: px beyond the shoreline (negative = on the island).
	"submerged_offset": 170.0,  # TUNING (not in GDD) Dreaming: far out under the water, out of every reach
	"stirring_offset": 22.0,  # TUNING (not in GDD) Stirring: just beyond the shore, her face in melee reach (radius 44)
	"waking_offset": -36.0,  # TUNING (not in GDD) Waking: risen onto the shore
	"glide_speed": 0.10,  # TUNING (not in GDD) rad/s she glides along the coast toward the necromancer's bearing
	"waking_glide_speed": 0.05,  # TUNING (not in GDD) rad/s in the Waking (heavier, slower)
	"fallback_radius": 420.0,  # TUNING (not in GDD) px: the "shore" circle around her arrival point on a stage with no sinking (--boss=vhalneth)
	"rise_time": 2.5,  # TUNING (not in GDD) s her arrival takes (the face rises, nothing attacks yet)
	# Phases.
	"stirring_hp_fraction": 0.7,  # TUNING (not in GDD) the Dreaming arms carry the first 30%
	"waking_hp_fraction": 0.35,  # TUNING (not in GDD)
	"waking_damage_taken": 1.4,  # TUNING (not in GDD) the face is the weak point once it has risen
	"phase_time": 2.0,  # TUNING (not in GDD) s of a phase change (she is invulnerable, the arms hold still)
	"stirring_banner": "Vhal'Neth stirs: her eyes open upon the island!",  # TUNING (not in GDD)
	"waking_banner": "THE MOTHER WAKES: her face rises out of the sea!",  # TUNING (not in GDD)
	# Her arms (SpireEnemyData "vhalneth_arm", ArmKit).
	"dream_arms_base": 2,  # TUNING (not in GDD) Dreaming arms with every dream pillar toppled
	"dream_arm_hp": 0.08,  # TUNING (not in GDD) fraction of her max HP per Dreaming arm
	"dream_wound_share": 0.3,  # TUNING (not in GDD) fraction of her max HP the Dreaming arms carry, split between them
	"stirring_arms": 2,  # TUNING (not in GDD)
	"waking_arms": 4,  # TUNING (not in GDD) proposal: "ringed by her arms"
	"later_arm_hp": 0.035,  # TUNING (not in GDD) fraction of her max HP per Stirring / Waking arm
	"later_wound": 0.5,  # TUNING (not in GDD) fraction of a later arm's HP its severing takes off her
	"arm_regrow": 16.0,  # TUNING (not in GDD) s before a severed Stirring / Waking arm rises again
	"waking_ring_radius": 120.0,  # TUNING (not in GDD) px from her face to the arms that ring it
	"arm_spread_min": 0.45,  # TUNING (not in GDD) rad: the least angle between two arms on the coast
	"slam_pace": [1.0, 1.15, 1.45],  # TUNING (not in GDD) slam rate per phase (divides the arm's interval)
	# Her gaze (Stirring and Waking; VhalnethHazards).
	"gaze_first": 3.0,  # TUNING (not in GDD) s into the Stirring
	"gaze_interval": 10.0,  # TUNING (not in GDD) s from one gaze to the next
	"gaze_interval_waking": 7.0,  # TUNING (not in GDD)
	"gaze_telegraph": 1.4,  # TUNING (not in GDD) s the eye opens over the spot before it rests
	"gaze_rest": 5.0,  # TUNING (not in GDD) s the gaze rests (and drifts)
	"gaze_radius": 120.0,  # TUNING (not in GDD) px
	"gaze_radius_waking": 140.0,  # TUNING (not in GDD) px
	"gaze_lead": 0.6,  # TUNING (not in GDD) s of necromancer movement the spot leads by
	"gaze_drift": 30.0,  # TUNING (not in GDD) px/s it follows the necromancer while resting (he outruns it)
	"gaze_dread": 14.0,  # TUNING (not in GDD) Dread per second inside (proposal: "climbs fast")
	"gaze_tick": 0.5,  # TUNING (not in GDD) s between gaze damage ticks
	"gaze_summon_damage": 1.0,  # TUNING (not in GDD) per summon per tick, before time scaling: the undead wither in it (balance pass 1: 3 -> 1, the gaze rests on the Bone Ring and wiped the army)
	"gaze_player_damage": 2.0,  # TUNING (not in GDD) per tick on a stage without Dread (--boss on Act I), before time scaling
	# Her roar (Waking): a nova around the face.
	"roar_first": 4.0,  # TUNING (not in GDD) s into the Waking
	"roar_interval": 11.0,  # TUNING (not in GDD)
	"roar_telegraph": 1.8,  # TUNING (not in GDD) long enough to walk out of the ring (balance pass 2: 1.3 -> 1.8)
	"roar_radius": 165.0,  # TUNING (not in GDD) px around the face (balance pass 2: 190 -> 165)
	"roar_damage_player": 10.0,  # TUNING (not in GDD) before time scaling (balance passes 2 and 4: 20 -> 14 -> 10, two roars took the bot to 4 HP)
	"roar_damage_summon": 12.0,  # TUNING (not in GDD) before time scaling
	"roar_knockback": 70.0,  # TUNING (not in GDD) px summons are thrown out of the ring
	# The finale.
	"finale_time": 6.0,  # TUNING (not in GDD) s the binding plays (drawing; the run goes on)
}

## Her arrival (keys as GraveyardStage.BOSS): StageRegistry.BOSS_ARRIVALS
## and SpireStage.BOSS. The defeat banner is the ending text.
const ARRIVAL := {
	"id": "vhalneth",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Vhal'Neth, the Dreaming Mother",
	"short_name": "Vhal'Neth",
	"arrive_banner": "Vhal'Neth, the Dreaming Mother, stirs beneath the spire!",  # TUNING (not in GDD)
	"defeat_banner": "The god is dead, and the dead serve you: the Eye's own ritual binds Vhal'Neth to her new master.",  # Proposal ending: "the necromancer raises her"
	"dead_objective": "The Dreaming Mother is yours. Survive until the countdown ends.",  # TUNING (not in GDD)
}

## Seconds the ending text (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## HUD announcement on her death (title, line, description).
const ENDING_ANNOUNCE := ["THE DEAD GOD SERVES", "The necromancer raises Vhal'Neth", "The Ancient Eye's own ritual binds the Dreaming Mother to you."]  # Proposal ending
## Shorter announcement when she falls after 0:00 (the Waking already rages).
const LATE_ANNOUNCE := ["THE MOTHER FALLS", "Even in the Waking, she is yours", "The dead god's dream breaks over the drowning island."]  # TUNING (not in GDD)
## Radius (px) of the binding rings of the finale (drawing only).
const BINDING_RADIUS: float = 220.0  # TUNING (not in GDD)
