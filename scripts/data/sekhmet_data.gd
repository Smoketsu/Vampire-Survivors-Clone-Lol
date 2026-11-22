## SekhmetData — immutable design data for SEKHMET, THE LIONESS OF RETRIBUTION,
## the boss of the Temple of the Lioness (temporary Act XII, the Necropolis
## Dynasty, final slot VII; GDD §15.0 "Sekhmet, the Lioness of Retribution
## (Dynasty phase 2)"; proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 3,
## "Stage B": "female, lioness-masked, figure style. The Hunt: she leaps between
## pillars and rakes the ring on a landing circle. The Red Wind: she calls a
## Sandstorm early and the Heka glyph spreads at double speed. The Feast:
## enraged, she cannot be stopped. Three red-wine jars (structures) fill the
## arena; break all three while she drinks from each and she stumbles for 4 s,
## which is when she can be hurt"). BossSekhmet
## (scripts/enemies/dynasty/boss_sekhmet.gd, loaded by name for the boss id
## "sekhmet" from EnemyDirector.DYNASTY_BOSS_DIR) reads it. Three phases by her
## HP:
##   * THE HUNT (100% to red_wind_hp): she PERCHES by a pillar of the temple
##     (perch_radius px from the necromancer: the nearest obstacle to her perch
##     point when one stands there, else the point itself) for perch_time s,
##     then crouches leap_windup s while a landing circle of leap_radius px
##     shows on the Bone Ring (on the necromancer), LEAPS there in leap_time s
##     and RAKES: every necromancer and summon in the circle is struck (and the
##     summons thrown leap_push px out), and rake_count more rakes follow every
##     rake_gap s in rake_radius px around her; then she leaps back out to the
##     next pillar (perch_turn rad on around the necromancer).
##   * THE RED WIND (red_wind_hp to feast_hp): she calls the Sandstorm early
##     (Sandstorm.force(red_wind_storm), re-forced while the phase lasts) and the
##     Heka glyph spreads at double speed (Heka.set_jump_speed(red_wind_jump),
##     reset to 1 when the phase ends or she falls); she writes her own glyph
##     on a summon every glyph_every s (Heka.write(), the one call), and hunts
##     faster (perch_time_p2).
##   * THE FEAST (below feast_hp): enraged, she CANNOT BE STOPPED (no damage
##     taken, no slow, stun or shove) and three RED-WINE JARS (the structure
##     row LionessTempleEnemyData "wine_jar") stand jar_dist px around the
##     necromancer on fixed angles; she runs to each in turn and DRINKS for
##     drink_time s: a jar still standing when she finishes is drained (she
##     heals drain_heal of her max HP, at most back to feast_hp). When the last
##     jar of the set is gone: if the army broke all three, she STUMBLES for
##     stumble_time s (owner-approved: 4 s), the only window she can be hurt
##     (x stumble_taken); a new set of jars stands refill_time s later either
##     way. Between jars she bites (her shared melee at feast_speed).
## Killing her drops a big XP burst and the boss chest; slaying her unlocks the
## Burning Eye spell and Desert Fury (UnlockData, boss "sekhmet"). The GDD
## gives no numbers: everything is TUNING (not in GDD) unless marked as the
## owner-approved proposal. Tuned for the act's FINAL slot VII (between the
## Shogunate and Olympus).
class_name SekhmetData
extends RefCounted

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["leap", "rake", "red_wind", "glyph", "feast", "drink", "stumble"]

## Damage tag of her leap's landing.
const LEAP_SOURCE: String = "sekhmet_leap"
## Damage tag of the rakes that follow it.
const RAKE_SOURCE: String = "sekhmet_rake"
## Sprite key of her art (assets/sprites/dynasty/sekhmet.png, its walk and idle strips).
const SPRITE: String = "dynasty/sekhmet"

## Sekhmet's base max HP (x the boss HP multiplier and the stage's HP
## multiplier). Vargr 14,000, Vrask'Tal 14,500; a little lower, because only
## her stumbles hurt her in the Feast (the last feast_hp of the bar).
const MAX_HP: float = 12500.0  # TUNING (not in GDD)

## Sekhmet's design row.
const BOSS := {
	"display_name": "Sekhmet, the Lioness of Retribution",
	"max_hp": MAX_HP,
	"move_speed": 64.0,  # TUNING (not in GDD) px/s; a lioness
	"damage": 12.0,  # TUNING (not in GDD) a bite in reach (the Feast's walk), before the time scaling
	"attack_interval": 1.1,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 24.0,  # TUNING (not in GDD) px; a 92 px goddess
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
	"faction": DynastyRulesData.FACTION,
	"reward_xp": 600,  # TUNING (not in GDD) as Vargr
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.45,  # TUNING (not in GDD) s she stands after a special
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this she strides faster (the Feast's walk)
	"advance_speed_mult": 1.7,  # TUNING (not in GDD)
	# Phases (HP shares).
	"red_wind_hp": 0.66,  # TUNING (not in GDD) the Red Wind below this
	"feast_hp": 0.3,  # TUNING (not in GDD) the Feast below this
	"hunt_banner": "Sekhmet hunts: she leaps from pillar to pillar onto your ring!",  # TUNING (not in GDD)
	"red_wind_banner": "THE RED WIND: Sekhmet calls the sand, and her glyph runs twice as fast!",  # TUNING (not in GDD)
	"feast_banner": "THE FEAST: nothing stops her now. Break her three wine jars before she drinks them!",  # TUNING (not in GDD)
	"stumble_banner": "The jars are broken: Sekhmet stumbles! Strike now!",  # TUNING (not in GDD)
	"drained_banner": "Sekhmet drains a jar and roars: new jars are brought!",  # TUNING (not in GDD)
	# The Hunt: perches by the pillars and leaps onto the ring.
	"perch_radius": 280.0,  # TUNING (not in GDD) px from the necromancer (the ring is 60-150 px)
	"perch_turn": 2.1,  # TUNING (not in GDD) rad on around the necromancer each perch (about 120 degrees)
	"pillar_search": 200.0,  # TUNING (not in GDD) px: the nearest obstacle this near the perch point (its cell and the eight round it) is her pillar
	"perch_time": 2.4,  # TUNING (not in GDD) s on her perch, the Hunt
	"perch_time_p2": 1.7,  # TUNING (not in GDD) s on her perch, the Red Wind
	"first_perch": 1.5,  # TUNING (not in GDD) s on her first perch after she arrives
	"leap_windup": 1.0,  # TUNING (not in GDD) s the landing circle shows
	"leap_time": 0.5,  # TUNING (not in GDD) s in the air (in and out)
	"leap_height": 80.0,  # TUNING (not in GDD) px of the arc (drawn only)
	"land_offset": 64.0,  # TUNING (not in GDD) px from the necromancer toward her where she lands (on the Bone Ring)
	"leap_radius": 62.0,  # TUNING (not in GDD) px of the landing
	"leap_damage_player": 12.0,  # TUNING (not in GDD) before the time scaling
	"leap_damage_summon": 10.0,  # TUNING (not in GDD) before the time scaling (first pass 12)
	"leap_push": 30.0,  # TUNING (not in GDD) px the summons are thrown out
	"rake_count": 2,  # TUNING (not in GDD) rakes after the landing
	"rake_gap": 0.35,  # TUNING (not in GDD) s between two rakes
	"rake_radius": 54.0,  # TUNING (not in GDD) px around her
	"rake_damage_player": 7.0,  # TUNING (not in GDD) before the time scaling
	"rake_damage_summon": 6.0,  # TUNING (not in GDD) before the time scaling (first pass 9: 61 summons raked to death in the seed-7 army run)
	# The Red Wind.
	"red_wind_storm": 40.0,  # TUNING (not in GDD) s of Sandstorm she calls (re-forced while the phase lasts)
	"red_wind_jump": 2.0,  # Owner-approved proposal: "the Heka glyph spreads at double speed"
	"glyph_every": 6.0,  # TUNING (not in GDD) s between two glyphs of her own
	"glyph_reach": 320.0,  # TUNING (not in GDD) px: the nearest summon within this takes it
	# The Feast.
	"feast_speed": 92.0,  # TUNING (not in GDD) px/s; enraged
	"feast_damage": 15.0,  # TUNING (not in GDD) per bite, enraged
	"jar_count": 3,  # Owner-approved proposal: three red-wine jars
	"jar_dist": 140.0,  # TUNING (not in GDD) px from the necromancer (on the Bone Ring's edge, within the army's reach; first pass 175: 17 of 21 jars drained)
	"drink_reach": 30.0,  # TUNING (not in GDD) px edge to edge: she drinks once this near her jar
	"drink_time": 4.5,  # TUNING (not in GDD) s she drinks from a jar (first pass 3.2)
	"drain_heal": 0.04,  # TUNING (not in GDD) share of her max HP a drained jar gives back (at most back to feast_hp)
	"stumble_time": 4.0,  # Owner-approved proposal: "she stumbles for 4 s"
	"jar_hp_share": 0.012,  # TUNING (not in GDD) a wine jar's max HP as a share of hers (set at spawn, whatever the time scaling: three must break in her drinking time)
	"stumble_taken": 1.6,  # TUNING (not in GDD) x the damage she takes while she stumbles (the only window)
	"refill_time": 2.5,  # TUNING (not in GDD) s before a new set of jars stands
	"feast_cap": 90.0,  # TUNING (not in GDD) s of Feast after which every hit lands (x feast_cap_taken): a failsafe, the run must end
	"feast_cap_taken": 0.35,  # TUNING (not in GDD) x the damage she takes once the Feast passed feast_cap
}
