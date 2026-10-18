## MerrowData — immutable design data for ABBOT SILAS MERROW, VOICE OF THE DEEP,
## the boss of Gullhaven Harbour (Act II, GDD §15.0 "Gullhaven Harbour (Act II
## phase 2)"; owner-approved proposal: "The town's priest, halfway through his
## transformation"). BossMerrow (scripts/enemies/eye/boss_merrow.gd, loaded by
## name for the boss id "merrow") reads it. Three parts of one fight:
##   * Robed (from his arrival): Sermon (he preaches from a pulpit, buffing every
##     cultist around him through the one aura-buff path, Enemy.buff_*; enough
##     damage breaks it off) and Brine Wave (a cone of water that throws the
##     army back).
##   * The Change (below change_hp): he sheds his robes and fights hand to hand
##     with long, whipping limbs: Limb Lash (three lanes fanned at the
##     necromancer) and Whirl (a circle around him).
##   * High Water (below high_water_hp): he calls the tide in early: the
##     TideDirector shrinks the dry ground to the seawall's top
##     (TideDirector.start_high_water()); his specials come faster.
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist, attack_gap, first_special,
## recover_time, advance_range, advance_speed_mult) and the specials' own
## numbers below. The GDD gives no numbers: everything is TUNING (not in GDD).
class_name MerrowData
extends RefCounted

## Abbot Merrow's arrival (keys as GraveyardStage.BOSS; StageRegistry
## BOSS_ARRIVALS "merrow", so --boss=merrow and the Codex find him).
const ARRIVAL := {
	"id": "merrow",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Abbot Silas Merrow, Voice of the Deep",  # owner-approved proposal
	"short_name": "Abbot Merrow",
	"arrive_banner": "Abbot Silas Merrow, Voice of the Deep, climbs his pulpit!",  # TUNING (not in GDD)
	"defeat_banner": "Abbot Merrow sinks into the deep. The tide of Gullhaven ebbs... for now.",  # TUNING (not in GDD)
	"dead_objective": "The Voice of the Deep is silenced. Survive until the countdown ends.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["sermon", "wave", "lash", "whirl"]
## Specials of each form.
const ROBED_SPECIALS := ["sermon", "wave"]
const CHANGED_SPECIALS := ["lash", "whirl"]

## Abbot Merrow's design row.
const BOSS := {
	"display_name": "Abbot Silas Merrow, Voice of the Deep",
	"max_hp": 22000.0,  # TUNING (not in GDD) x the stage HP multiplier (25,300 at Gullhaven); Seraphine 21,000, Vael 19,200
	"move_speed": 46.0,  # TUNING (not in GDD) robed; The Change raises it (change_speed_mult)
	"damage": 12.0,  # TUNING (not in GDD) a blow in reach
	"attack_interval": 1.1,  # TUNING (not in GDD) s
	"attack_range": 8.0,  # TUNING (not in GDD) px
	"radius": 22.0,  # TUNING (not in GDD) px
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
	"reward_xp": 520,  # TUNING (not in GDD) a little more than Seraphine's 500
	"reward_crystals": 24,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss (he also swims: HarbourStage.TIDE)
	# Pacing.
	"first_special": 2.5,  # TUNING (not in GDD) s after arrival
	"attack_gap": 3.2,  # TUNING (not in GDD) s between the end of one special and the next
	"recover_time": 0.8,  # TUNING (not in GDD) s he stands after a special
	"advance_range": 280.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 1.8,  # TUNING (not in GDD)
	# Sermon (robed): he preaches; every cultist within sermon_radius is
	# buffed (refreshed every sermon_pulse s, lingering sermon_linger s after).
	"sermon_weight": 1.0,  # TUNING (not in GDD) choice weight
	"sermon_cooldown": 16.0,  # TUNING (not in GDD) s
	"sermon_duration": 4.0,  # TUNING (not in GDD) s he preaches
	"sermon_radius": 650.0,  # TUNING (not in GDD) px; about the screen
	"sermon_pulse": 0.5,  # TUNING (not in GDD) s
	"sermon_linger": 4.0,  # TUNING (not in GDD) s the buff outlasts a pulse
	"sermon_damage_mult": 1.25,  # TUNING (not in GDD) buffed cultists hit harder
	"sermon_speed_mult": 1.2,  # TUNING (not in GDD) ... walk faster
	"sermon_taken_mult": 0.85,  # TUNING (not in GDD) ... and take less damage
	"sermon_break": 0.04,  # TUNING (not in GDD) share of his max HP lost during a sermon that breaks it off
	# Brine Wave (robed): a cone of water toward the necromancer.
	"wave_weight": 1.0,  # TUNING (not in GDD)
	"wave_cooldown": 7.0,  # TUNING (not in GDD) s
	"wave_range": 260.0,  # TUNING (not in GDD) px; used on a necromancer this close
	"wave_radius": 230.0,  # TUNING (not in GDD) px
	"wave_half_angle": 0.6,  # TUNING (not in GDD) rad
	"wave_telegraph": 1.1,  # TUNING (not in GDD) s
	"wave_damage_summon": 10.0,  # TUNING (not in GDD) before time scaling
	"wave_damage_player": 14.0,  # TUNING (not in GDD) before time scaling
	"wave_push": 70.0,  # TUNING (not in GDD) px summons are thrown back
	# The Change.
	"change_hp": 0.6,  # TUNING (not in GDD) HP share at which he sheds his robes
	"change_time": 1.4,  # TUNING (not in GDD) s he stands transforming
	"change_speed_mult": 1.5,  # TUNING (not in GDD) faster on his new limbs
	"change_attack_mult": 0.8,  # TUNING (not in GDD) attack interval multiplier
	"change_banner": "Abbot Merrow sheds his robes: THE CHANGE takes him!",  # TUNING (not in GDD)
	# Limb Lash (changed): three lanes fanned at the necromancer.
	"lash_weight": 1.2,  # TUNING (not in GDD)
	"lash_cooldown": 5.0,  # TUNING (not in GDD) s
	"lash_range": 230.0,  # TUNING (not in GDD) px
	"lash_count": 3,  # TUNING (not in GDD) lanes
	"lash_spread": 0.38,  # TUNING (not in GDD) rad between two lanes
	"lash_length": 210.0,  # TUNING (not in GDD) px
	"lash_width": 26.0,  # TUNING (not in GDD) px
	"lash_telegraph": 0.9,  # TUNING (not in GDD) s
	"lash_damage_summon": 12.0,  # TUNING (not in GDD) before time scaling
	"lash_damage_player": 16.0,  # TUNING (not in GDD) before time scaling
	# Whirl (changed): a circle around him.
	"whirl_weight": 1.0,  # TUNING (not in GDD)
	"whirl_cooldown": 8.0,  # TUNING (not in GDD) s
	"whirl_range": 140.0,  # TUNING (not in GDD) px; used on a necromancer this close
	"whirl_radius": 120.0,  # TUNING (not in GDD) px
	"whirl_telegraph": 1.0,  # TUNING (not in GDD) s
	"whirl_damage_summon": 10.0,  # TUNING (not in GDD) before time scaling
	"whirl_damage_player": 14.0,  # TUNING (not in GDD) before time scaling
	"whirl_knockback": 50.0,  # TUNING (not in GDD) px summons are thrown out
	# High Water.
	"high_water_hp": 0.3,  # TUNING (not in GDD) HP share at which he calls the tide in
	"high_water_gap_mult": 0.7,  # TUNING (not in GDD) shorter gaps between specials
	"high_water_banner": "HIGH WATER! The Abbot calls the tide in: hold the seawall!",  # TUNING (not in GDD)
}
