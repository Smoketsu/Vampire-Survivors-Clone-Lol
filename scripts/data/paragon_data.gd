## ParagonData — immutable design data of PARAGON, THE LAST HERO, the boss of
## Liberty Heights and the finale of Act VIII (the Last Line; GDD §15.0
## "Paragon, the Last Hero (Act VIII)"; owner-approved proposal
## docs/act8/PROPOSAL.md "Stage 24: Liberty Heights"). BossParagon
## (scripts/enemies/city/boss_paragon.gd, loaded by name for the boss id
## "paragon") reads BOSS; StageRegistry.BOSS_ARRIVALS and LibertyHeightsStage
## .BOSS read ARRIVAL. He descends from the Heroes' Tower at 17:00 (3:00
## left). Male: the strongest man alive, a white-and-silver suit, a blue cape,
## heat vision (matching the approved concept act8_boss.png; nothing closer to
## a famous hero; no emblem). His collision radius stays within
## CityBlockData.MAX_BODY_RADIUS (the sprite is drawn larger). Three phases:
##   THE HERO (100% -> hope_hp of his health): he FLIES (Enemy.flies: no summon
##        body-blocks him; in the air a grounded melee blow deals
##        aloft_melee_taken of itself) at the necromancer and takes turns
##        between:
##          HEAT VISION: heat_lines red lines from him (one at the necromancer,
##          the others heat_spread rad apart) shown for heat_windup s, then
##          the beams burn heat_time s: every summon and necromancer on a line
##          (heat_width px each side, heat_length px long) is struck once
##          (heat_damage_*), cutting lines through the ring (a ranged City
##          source: Kevlar Bones);
##          THE PUNCH (a summon within punch_reach px; the biggest by max HP):
##          he dives at it (punch_windup s, a red circle on it), strikes
##          (punch_damage) and SENDS IT ACROSS THE ARENA: it flies punch_throw
##          px straight away from him over fling_time s to a free point (an
##          enemy effect on a unit through the held hook, the one place that
##          moves it), and he LANDS for land_time s (every blow lands in full).
##   HOPE (at hope_hp): he rises, immune, and every Super of the stage's roster
##        NOT killed this run (SuperRoster.standing_roster(): the `fallen`
##        list) flies in to his side (SuperRoster.call_super(), hope_dist px
##        around him). He stays immune and keeps his heat vision while any of
##        them stands, at most hope_max s; with none to call it lasts hope_min
##        s ("kill them earlier and this phase is short").
##   NO RESTRAINT (after Hope, to the end): he stops holding back. The sky
##        turns white (ParagonSky: an additive blend-mode rect over the view,
##        fading in over sky_fade s; no shader reads the screen) and every
##        dive_every s he DIVES FROM ORBIT: he rises out of sight (dive_rise s,
##        immune), the craters show (CityShells, THE landing-circle path: one
##        of dive_radius px on the necromancer's spot and dive_extra more of
##        extra_radius px around him, dive_windup s), he lands on the first
##        (dive_damage to every summon and necromancer in each, the city's
##        side spared) and each crater CRACKS THE ARENA (a crack decal,
##        LibertyHeightsDirector.add_crack(); at most crack_max). Faster
##        (p3_speed_mult), his heat vision every heat_every_p3 s.
## Beaten: a short ending text only (ENDING_ANNOUNCE: the world of the living
## has no one left to defend it), no epilogue (owner decision Oct 31, 2026).
## NO MORE HEROES: beaten on Liberty Heights with no Super at his side (Hope
## called none: every roster Super fell before it began) counts
## paragon_no_heroes_kills (MetaData; MetaProgress keeps the lifetime count).
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist) and the abilities' own
## numbers. Damage keys are before the time scaling. The GDD gives no numbers:
## everything is TUNING (not in GDD) unless marked as the owner-approved
## proposal.
class_name ParagonData
extends RefCounted

## His arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "paragon" through LibertyHeightsStage.BOSS, so --boss=paragon and the Codex
## find him). His script is found by the id (boss_paragon.gd).
const ARRIVAL := {
	"id": "paragon",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Paragon, the Last Hero",  # Owner-approved proposal
	"short_name": "Paragon",
	"arrive_banner": "Paragon descends from the Heroes' Tower!",  # TUNING (not in GDD)
	"defeat_banner": "The Last Hero falls. The living have no one left to defend them.",  # Owner-approved proposal ending
	"dead_objective": "No one is left to defend the living. Survive Martial Law... you cannot.",  # TUNING (not in GDD)
}
## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["heat_vision", "punch", "hope", "no_restraint", "dive"]
## Damage source tag of his heat vision (a ranged City source: CityEnemyData
## .RANGED_SOURCES, Kevlar Bones).
const SRC_HEAT: String = "paragon_heat"
## Damage source tag of his punch.
const SRC_PUNCH: String = "paragon_punch"
## Damage source tag of his dives from orbit (the craters).
const SRC_DIVE: String = "paragon_dive"
## Sprite key of his art (BossPoseData pose 1: the heat vision / the punch).
const SPRITE: String = "bosses/paragon"
## Seconds the ending line (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## HUD announcement on his fall (title, line, description): the proposal's
## ending ("When he falls, the world of the living has no one left to defend
## it"), kept short (no epilogue, owner decision Oct 31, 2026).
const ENDING_ANNOUNCE := ["NO ONE LEFT", "The Last Hero falls.", "Paragon lies in the plaza he swore to keep. The towers burn on, and the world of the living has no one left to defend it."]  # Owner-approved proposal ending (TUNING the words)
## Shorter announcement when he falls after 0:00 (Martial Law rages on).
const LATE_ANNOUNCE := ["NO ONE LEFT", "The Last Hero falls.", "Even under Martial Law, the city's last hope is broken."]  # TUNING (not in GDD)
## His design row.
const BOSS := {
	"display_name": "Paragon",
	"max_hp": 9000.0,  # TUNING (not in GDD) before the stage / co-op scaling (Carmilla and the Elder 5,000 + 5,200)
	"move_speed": 62.0,  # TUNING (not in GDD) px/s, flying
	"damage": 13.0,  # TUNING (not in GDD) a punch in melee, before the time scaling
	"attack_interval": 1.0,  # TUNING (not in GDD) s
	"attack_range": 12.0,  # TUNING (not in GDD) px
	"radius": 18.0,  # TUNING (not in GDD) px (<= CityBlockData.MAX_BODY_RADIUS 36; the sprite is drawn larger)
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
	"flies": true,  # Owner-approved proposal: "flight" (Enemy.flies: over the Bone Ring)
	"reward_xp": 1000,  # TUNING (not in GDD) the act's finale (Carmilla 900)
	"reward_crystals": 32,  # TUNING (not in GDD)
	"arrive_time": 2.0,  # TUNING (not in GDD) s he descends (invulnerable)
	"advance_range": 380.0,  # TUNING (not in GDD) px beyond which he flies faster
	"advance_speed_mult": 2.0,  # TUNING (not in GDD)
	"aloft_melee_taken": 0.6,  # TUNING (not in GDD) share of a grounded melee blow that lands while he flies
	# The Hero: heat vision.
	"heat_first": 3.0,  # TUNING (not in GDD) s before the first
	"heat_every": 6.0,  # TUNING (not in GDD) s
	"heat_every_p3": 4.5,  # TUNING (not in GDD) s, No Restraint
	"heat_windup": 0.9,  # TUNING (not in GDD) s the lines show
	"heat_time": 0.5,  # TUNING (not in GDD) s the beams burn (drawn)
	"heat_lines": 2,  # TUNING (not in GDD) beams (his two eyes)
	"heat_spread": 0.35,  # TUNING (not in GDD) rad between two beams
	"heat_length": 380.0,  # TUNING (not in GDD) px
	"heat_width": 12.0,  # TUNING (not in GDD) px each side of a line
	"heat_damage_summon": 20.0,  # TUNING (not in GDD)
	"heat_damage_player": 14.0,  # TUNING (not in GDD)
	# The Hero: the punch.
	"punch_first": 6.0,  # TUNING (not in GDD) s before the first
	"punch_every": 8.0,  # TUNING (not in GDD) s
	"punch_reach": 240.0,  # TUNING (not in GDD) px to the summon
	"punch_windup": 0.6,  # TUNING (not in GDD) s, he dives at it
	"punch_damage": 26.0,  # TUNING (not in GDD)
	"punch_throw": 360.0,  # TUNING (not in GDD) px the summon flies ("sends a summon across the arena")
	"fling_time": 0.45,  # TUNING (not in GDD) s of its flight
	"fling_daze": 0.5,  # TUNING (not in GDD) s held after it lands
	"land_time": 1.4,  # TUNING (not in GDD) s he stands after the punch (every blow lands)
	# Hope.
	"hope_hp": 0.6,  # TUNING (not in GDD) share of his health where Hope begins
	"hope_max": 45.0,  # TUNING (not in GDD) s at most
	"hope_min": 4.0,  # TUNING (not in GDD) s when no Super answers (his call echoes)
	"hope_dist": 90.0,  # TUNING (not in GDD) px around him where they land
	# No Restraint.
	"dive_first": 2.5,  # TUNING (not in GDD) s after No Restraint begins
	"dive_every": 7.5,  # TUNING (not in GDD) s
	"dive_rise": 1.0,  # TUNING (not in GDD) s he climbs out of sight (immune)
	"dive_windup": 1.4,  # TUNING (not in GDD) s the craters show before he lands
	"dive_radius": 70.0,  # TUNING (not in GDD) px of the crater on the necromancer's spot
	"dive_extra": 2,  # TUNING (not in GDD) more craters around him
	"extra_radius": 50.0,  # TUNING (not in GDD) px
	"extra_dist": 130.0,  # TUNING (not in GDD) px from the necromancer
	"dive_damage": 24.0,  # TUNING (not in GDD) to every summon and necromancer in a crater
	"p3_speed_mult": 1.25,  # TUNING (not in GDD) No Restraint: faster
	"p3_damage_mult": 1.25,  # TUNING (not in GDD) No Restraint: his blows harder
	"sky_fade": 4.0,  # TUNING (not in GDD) s the sky takes to turn white (drawn only)
	"sky_alpha": 0.32,  # TUNING (not in GDD) 0..1, the white over the view at full (drawn only)
	"crack_max": 14,  # TUNING (not in GDD) crack decals kept (the oldest fades)
}
