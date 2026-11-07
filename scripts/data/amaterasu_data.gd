## AmaterasuData — immutable design data for AMATERASU, THE SUN GODDESS, the
## boss of the Road to the Sun and of Act V (Stage 15; GDD §15.0 "The Road to
## the Sun (Act V phase 2)" and "Amaterasu, the Sun Goddess"; owner-approved
## proposal docs/act5/PROPOSAL.md: "Her place in the sky is the phase").
## BossAmaterasu (scripts/enemies/shogunate/boss_amaterasu.gd, loaded by name
## for the boss id "amaterasu") reads BOSS and SKY; StageRegistry.BOSS_ARRIVALS
## and SunRoadStage.BOSS read ARRIVAL. She never walks: she hangs in the sky,
## gliding to her place around the necromancer, and her place IS the phase:
##   DAWN (100% -> noon_hp): she RISES ON THE EAST EDGE (sky_distance px east of
##        the necromancer): slow sweeping beams from her mirror (a beam
##        mirror_length px long sweeping mirror_sweep rad across mirror_time s
##        after a mirror_telegraph s warning, burning every body it crosses
##        each mirror_tick s) and SUN-DISC MINES (mine_count discs on a ring
##        mine_ring_min..mine_ring_max px around him; armed after mine_arm s,
##        each bursts when a body comes within mine_trigger px or at mine_fuse s).
##   NOON (noon_hp -> sunset_hp): DIRECTLY OVERHEAD (zenith_distance px north
##        of him): the whole arena bright and hot. Beams fall straight down on
##        MARKED CIRCLES (zenith_count circles, one on him, the rest on his army
##        within zenith_reach px, each zenith_radius px, falling after
##        zenith_telegraph s) and every glare_cooldown s the NOON GLARE builds
##        for glare_windup s, then scorches every body in the open. THE SHADOWS
##        OF OBSTACLES ARE THE ONLY SAFE GROUND: a body standing in an
##        obstacle's noon shadow (its footprint grown by shade_pad px) takes
##        neither the beams nor the glare.
##   SUNSET (sunset_hp -> 0): she SINKS TO THE WEST EDGE (sky_distance px west):
##        a WIDE SETTING-SUN BEAM (sunset_width px wide, sunset_length long,
##        from her across the arena through the necromancer's place) after a
##        sunset_telegraph s warning, and her mirror's sweeps on a slower
##        rhythm; the light turns red and night closes in (the sky's ambient
##        falls from SKY sunset ambient to sunset_ambient_end as her HP runs out).
## Her sky is the Sun's Course's ONE override (SunCourse.set_override(), the
## SKY rows); when she falls the sun goes out (SunCourse.clear_override(): the
## night returns, then the Reckoning is the Endless Night). The ending line is
## ARRIVAL defeat_banner and ENDING_ANNOUNCE, like Hades' and Vhal'Neth's.
## Keys: every key of an EnemyData.ENEMIES row (same meaning), the shared boss
## keys (reward_xp, reward_crystals, slow_resist) and the abilities' own
## numbers. The GDD gives no numbers: everything is TUNING (not in GDD) unless
## marked as the owner-approved proposal.
class_name AmaterasuData
extends RefCounted

## Her arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "amaterasu" through SunRoadStage.BOSS, so --boss=amaterasu and the Codex
## find her). The defeat banner is the ending line.
const ARRIVAL := {
	"id": "amaterasu",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Amaterasu, the Sun Goddess",  # Owner-approved proposal
	"short_name": "Amaterasu",
	"arrive_banner": "Amaterasu rises in the east: the sun returns to the night!",  # Owner-approved proposal ("she rises on the arena's east edge")
	"defeat_banner": "Amaterasu falls, and the sun goes out.",  # Owner-approved proposal ("When she falls, the sun goes out")
	"dead_objective": "The sun is out. Survive the Endless Night... you will not.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["mirror_beam", "sun_mines", "zenith_beams", "noon_glare", "sunset_beam"]

## Damage source tags of her attacks (all HOLY or AREA for Unholy Resilience,
## PassiveData.AREA_HOLY_SOURCES).
const SRC_MIRROR: String = "amaterasu_mirror"
## Damage source of a sun-disc mine's burst.
const SRC_MINE: String = "amaterasu_mine"
## Damage source of a noon beam on a marked circle.
const SRC_ZENITH: String = "amaterasu_zenith"
## Damage source of the noon glare.
const SRC_GLARE: String = "amaterasu_glare"
## Damage source of the setting-sun beam.
const SRC_SUNSET: String = "amaterasu_sunset"

## Seconds the ending line (ARRIVAL defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## HUD announcement on her defeat (title, line, description): the proposal's
## ending ("When she falls, the sun goes out").
const ENDING_ANNOUNCE := ["THE SUN GOES OUT", "Amaterasu falls.", "The goddess sinks below the edge of the world and her light goes with her. No dawn will come again: only the night, and the dead who walk in it."]  # Owner-approved proposal ending (TUNING the words)
## Shorter announcement when she falls after 0:00 (the Endless Night rages on).
const LATE_ANNOUNCE := ["THE SUN GOES OUT", "Amaterasu falls.", "In the Endless Night, the last light dies."]  # TUNING (not in GDD)

## Her sky in each phase: the Sun's Course override (SunCourse.set_override()
## keys: phase, ambient 0..1, dusk 0..1 (the wash and the shadows' length),
## tint, tint_alpha, shadow_dir: away from where she stands).
const SKY := {
	"dawn": {"phase": ShogunateRulesData.Phase.DAY, "ambient": 0.82, "dusk": 0.6, "tint": Color(1.0, 0.66, 0.62),  # TUNING (not in GDD) a pink-gold dawn
		"tint_alpha": 0.16, "shadow_dir": Vector2(-0.95, 0.3)},  # Owner-approved proposal: she rises in the EAST (the shadows fall west)
	"noon": {"phase": ShogunateRulesData.Phase.DAY, "ambient": 1.0, "dusk": 0.3, "tint": Color(1.0, 0.96, 0.80),  # TUNING (not in GDD) white heat
		"tint_alpha": 0.28, "shadow_dir": Vector2(0.0, 1.0)},  # Owner-approved proposal: directly overhead (short shadows straight down)
	"sunset": {"phase": ShogunateRulesData.Phase.DUSK, "ambient": 0.55, "dusk": 1.0, "tint": Color(0.95, 0.28, 0.16),  # TUNING (not in GDD) the light turns red
		"tint_alpha": 0.24, "shadow_dir": Vector2(0.95, 0.3)},  # Owner-approved proposal: she sinks in the WEST (the shadows fall east)
}

## Her design row.
const BOSS := {
	"display_name": "Amaterasu, the Sun Goddess",
	"max_hp": 14000.0,  # TUNING (not in GDD) x the stage HP multiplier (23,100 on the Road; Hades 24,000): she hangs at the army's reach, never in the middle of it
	"move_speed": 0.0,  # She never walks: she glides to her place in the sky (glide_speed).
	"damage": 0.0,  # No blow in reach: the sun strikes from the sky.
	"attack_interval": 1.0,
	"attack_range": 0.0,
	"radius": 22.0,  # TUNING (not in GDD) px; a goddess (drawn bigger)
	"armor": 0.15,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 40.0,  # TUNING (not in GDD) the sun is not shoved
	"faction": ShogunateEnemyData.FACTION,
	"reward_xp": 800,  # TUNING (not in GDD) Act V's last boss: more than Hades' 760
	"reward_crystals": 34,  # TUNING (not in GDD)
	"slow_resist": 1.0,  # TUNING (not in GDD) the sun's course cannot be slowed
	"arrive_time": 2.5,  # TUNING (not in GDD) s she rises (invulnerable)
	"change_time": 2.2,  # TUNING (not in GDD) s she crosses the sky between two phases (invulnerable)
	"glide_speed": 120.0,  # TUNING (not in GDD) px/s toward her place in the sky
	"sky_distance": 210.0,  # TUNING (not in GDD) px east / west of the necromancer (the army's reach: outside the Bone Ring, inside archer range)
	"zenith_distance": 110.0,  # TUNING (not in GDD) px north of him at noon ("directly overhead": the army's melee reaches her)
	"noon_hp": 0.66,  # TUNING (not in GDD) noon begins
	"sunset_hp": 0.33,  # TUNING (not in GDD) sunset begins
	# Dawn: the mirror's sweeping beam (also at sunset, slower).
	"mirror_cooldown": 6.5,  # TUNING (not in GDD) s
	"mirror_first": 2.0,  # TUNING (not in GDD) s into the phase
	"mirror_telegraph": 1.0,  # TUNING (not in GDD) s
	"mirror_time": 2.4,  # TUNING (not in GDD) s the beam burns while it sweeps
	"mirror_sweep": 1.1,  # TUNING (not in GDD) rad swept ("slow sweeping beams")
	"mirror_length": 760.0,  # TUNING (not in GDD) px
	"mirror_width": 20.0,  # TUNING (not in GDD) px
	"mirror_tick": 0.25,  # TUNING (not in GDD) s between two burns of a body in it
	"mirror_damage_player": 3.0,  # TUNING (not in GDD) per tick, before the time scaling
	"mirror_damage_summon": 2.0,  # TUNING (not in GDD) per tick, before the time scaling (Act V integration balance: 3.5 -> 2; the sweep crosses the whole Bone Ring, ~1,950 summon damage in her first minute)
	"sunset_mirror_mult": 1.4,  # TUNING (not in GDD) x mirror_cooldown at sunset
	# Dawn: sun-disc mines.
	"mine_cooldown": 9.0,  # TUNING (not in GDD) s
	"mine_first": 4.5,  # TUNING (not in GDD) s into the phase
	"mine_count": 5,  # TUNING (not in GDD)
	"mine_ring_min": 80.0,  # TUNING (not in GDD) px from the necromancer
	"mine_ring_max": 210.0,  # TUNING (not in GDD) px
	"mine_arm": 1.1,  # TUNING (not in GDD) s before a disc is armed
	"mine_trigger": 20.0,  # TUNING (not in GDD) px a body must come within (edge to edge)
	"mine_fuse": 6.0,  # TUNING (not in GDD) s: it bursts by itself then
	"mine_radius": 46.0,  # TUNING (not in GDD) px of the burst
	"mine_damage_player": 9.0,  # TUNING (not in GDD) before the time scaling
	"mine_damage_summon": 6.0,  # TUNING (not in GDD) before the time scaling (Act V integration balance: 10 -> 6; the discs lie on the ring)
	# Noon: beams on marked circles.
	"zenith_cooldown": 3.4,  # TUNING (not in GDD) s
	"zenith_first": 1.5,  # TUNING (not in GDD) s into the phase
	"zenith_count": 4,  # TUNING (not in GDD) circles (one on the necromancer)
	"zenith_reach": 190.0,  # TUNING (not in GDD) px around him for the others (on his army)
	"zenith_radius": 40.0,  # TUNING (not in GDD) px
	"zenith_telegraph": 1.3,  # TUNING (not in GDD) s
	"zenith_damage_player": 8.0,  # TUNING (not in GDD) before the time scaling (Act V integration balance: 12 -> 8, ~53 a hit at 17:00 took the army bot to 8 HP)
	"zenith_damage_summon": 8.0,  # TUNING (not in GDD) before the time scaling (Act V integration balance: 12 -> 8; three of four circles fall on the army)
	# Noon: the glare.
	"glare_cooldown": 12.0,  # TUNING (not in GDD) s
	"glare_first": 5.0,  # TUNING (not in GDD) s into the phase
	"glare_windup": 3.0,  # TUNING (not in GDD) s it builds (time to reach a shadow)
	"glare_damage_player": 7.0,  # TUNING (not in GDD) before the time scaling (Act V integration balance: 10 -> 7; ~40 a glare at 17:00, a third of the necromancer's life when a shadow is not in reach)
	"glare_damage_summon": 4.0,  # TUNING (not in GDD) before the time scaling (the ring cannot all hide)
	"shade_pad": 16.0,  # TUNING (not in GDD) px an obstacle's noon shadow reaches past its footprint
	"shade_offset": 4.0,  # TUNING (not in GDD) px the noon shadow lies south of the obstacle (drawn and tested alike)
	# Sunset: the setting-sun beam.
	"sunset_cooldown": 8.0,  # TUNING (not in GDD) s
	"sunset_first": 2.5,  # TUNING (not in GDD) s into the phase
	"sunset_telegraph": 1.6,  # TUNING (not in GDD) s
	"sunset_burn": 0.6,  # TUNING (not in GDD) s the beam shows after it struck (visual only)
	"sunset_width": 90.0,  # TUNING (not in GDD) px ("a wide setting-sun beam")
	"sunset_length": 1500.0,  # TUNING (not in GDD) px ("crosses the arena")
	"sunset_damage_player": 15.0,  # TUNING (not in GDD) before the time scaling
	"sunset_damage_summon": 14.0,  # TUNING (not in GDD) before the time scaling
	"sunset_ambient_end": 0.15,  # TUNING (not in GDD) ambient light as her HP runs out ("night closes in")
	"sunset_sky_every": 1.5,  # TUNING (not in GDD) s between two updates of the darkening sky
	# The ending.
	"finale_time": 12.0,  # TUNING (not in GDD) s the dark sun hangs where she fell (visual only)
}
