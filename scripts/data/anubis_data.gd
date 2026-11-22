## AnubisData — immutable design data for ANUBIS, OPENER OF THE WAY, the boss
## of the Necropolis of Sand (temporary Act XII, the Necropolis Dynasty, final
## slot VII; GDD §15.0 "Anubis, Opener of the Way (Act XII phase 2)";
## owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 3: "the
## Procession: he leads a funeral march of mummies; every jar must be broken
## to end Rebirth. The Embalmer: he wraps the fallen on the whole map; the
## cartouche timer is 3 s while he does. The Jackal: he drops the wrapped pose
## and duels: fast, with afterimage lunges"). BossAnubis
## (scripts/enemies/dynasty/boss_anubis.gd, loaded by name for the boss id
## "anubis") reads it. A male jackal-headed god in the dull bronze-gold and
## the night blue (art `dynasty/anubis`, 90 px, with its walk strip). Three
## phases by his HP:
##   * THE PROCESSION (100% to phase2_hp): he walks in at the head of a
##     funeral march (the shared melee AI, his crook in reach). On arrival
##     procession_jars Canopic Jars rise round the necromancer
##     (procession_jar_min..max px, at even angles turned by his think slot,
##     each beside a tomb when one stands near: NecropolisDirector's one jar
##     placer, Rebirth.place_jar()), and Rebirth runs the PROCESSION
##     (Rebirth.set_procession(true)): every jar holds every Name on the map
##     and only a held body gets a cartouche, so while one jar stands every
##     fallen mummy and guard is sealed (it cannot be smashed: raise it, or
##     break the jars), and once every jar is broken Rebirth ends for the
##     phase. Every march_every s a column of the march (march: groups of
##     {kind, count}) walks in from the spawn ring behind him, two abreast.
##   * THE EMBALMER (phase2_hp to phase3_hp): the Procession ends (Rebirth's
##     normal jar radius again); he halts every wrap_every s for wrap_windup s
##     (cast pose) and WRAPS THE FALLEN: wrap_count wrapped dead
##     (wrap_kinds, in turn) rise out of the sand wrap_min..wrap_max px round
##     the necromancer; for the whole phase every cartouche on the map runs
##     its timer in embalm_timer s (DynastyRules.embalm_all: the one haste
##     read, DynastyRules.embalm_rate()).
##   * THE JACKAL (below phase3_hp): he drops the wrapped pose (the haste
##     ends) and DUELS: x jackal_speed_mult faster, he lunges straight at the
##     necromancer every lunge_every s: lunge_windup s of crouch (a bronze line
##     telegraph, aimed lunge_lead of the dash ahead of a moving target), then
##     a dash at lunge_speed px/s up to lunge_reach px over the ring (a
##     position move: no body-block stops it), leaving afterimages
##     (afterimages ghosts, drawn only); every summon the dash passes within
##     lunge_width px of takes lunge_damage_summon (once a dash) and the
##     necromancer lunge_damage if the dash reaches him (time-scaled).
## Beaten: a short ending text (ENDING_ANNOUNCE; no epilogue part until the
## reorder pass, docs/last_acts/PLAN.md). Killing him drops a big XP burst and
## the boss chest; slaying him unlocks Linen Bind, Natron Salts and so the
## Embalmer (UnlockData, boss "anubis"); NO JARS LEFT is judged by
## NecropolisDirector when he falls. The GDD gives no numbers: everything is
## TUNING (not in GDD) unless marked as the owner-approved proposal.
class_name AnubisData
extends RefCounted

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["procession", "march", "embalmer", "wrap", "jackal", "lunge"]

## Sprite key of his art (assets/sprites/dynasty/anubis.png, 90 px, walk strip).
const SPRITE: String = "dynasty/anubis"
## Damage tag of his lunge (stats, the death line).
const LUNGE_SOURCE: String = "anubis_lunge"
## Seconds the ending line (the arrival's defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## The short ending text shown when he falls (HUD announce: title, line, text).
const ENDING_ANNOUNCE := ["THE WAY IS SHUT", "Anubis, Opener of the Way, falls.", "The procession breaks on the tomb road, and the jackal's scales stand empty. Deeper in the Black Land, older masters stir."]  # TUNING (not in GDD) the words
## The ending text when he falls during the Devourer's Hour.
const LATE_ANNOUNCE := ["THE WAY IS SHUT", "Anubis falls as the sarcophagi open.", "The dead he led wander the dunes without a master, and the Devourer eats its fill."]  # TUNING (not in GDD) the words

## Anubis's base max HP (x the boss HP multiplier and the stage's HP multiplier).
const MAX_HP: float = 30000.0  # TUNING (not in GDD) first pass 12000: the seed-7 army bot slew him 41 s after he arrived, every phase in 15 s; 26000: 73 s with Linen Bind (x the stage's 1.5: 45,000)

## Anubis's design row.
const BOSS := {
	"display_name": "Anubis, Opener of the Way",
	"max_hp": MAX_HP,
	"move_speed": 44.0,  # TUNING (not in GDD) px/s; the head of a slow procession
	"damage": 12.0,  # TUNING (not in GDD) his crook in reach, before the time scaling
	"attack_interval": 1.3,  # TUNING (not in GDD) s
	"attack_range": 14.0,  # TUNING (not in GDD) px
	"radius": 20.0,  # TUNING (not in GDD) px (the sprite 90 px tall)
	"armor": 0.2,  # TUNING (not in GDD) a god's bronze
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 12.0,  # TUNING (not in GDD)
	"faction": DynastyEnemyData.FACTION,
	"group": "guard",  # The god of the tombs leads their guard (the reports).
	"reward_xp": 600,  # TUNING (not in GDD) as the Hive Mother
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.4,  # TUNING (not in GDD) s he stands after a special
	"advance_range": 420.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 1.8,  # TUNING (not in GDD)
	# Phases (HP shares).
	"phase2_hp": 0.66,  # TUNING (not in GDD) the Embalmer below this
	"phase3_hp": 0.33,  # TUNING (not in GDD) the Jackal below this
	"phase1_banner": "THE PROCESSION: while one Canopic Jar stands, every fallen Name is held. Break the jars!",  # TUNING (not in GDD)
	"phase2_banner": "THE EMBALMER: Anubis wraps the fallen across the sands! Every Name stands again in 3 s: raise them or smash them!",  # TUNING (not in GDD)
	"phase3_banner": "THE JACKAL: Anubis casts off his wrappings and comes for you!",  # TUNING (not in GDD)
	# The Procession.
	"procession_jars": 4,  # TUNING (not in GDD) jars that rise when he arrives
	"procession_jar_min": 240.0,  # TUNING (not in GDD) px from the necromancer
	"procession_jar_max": 360.0,  # TUNING (not in GDD) px
	"march_first": 4.0,  # TUNING (not in GDD) s after he arrives
	"march_every": 11.0,  # TUNING (not in GDD) s between two columns of the march
	"march": [{"kind": "mummy", "count": 6}, {"kind": "mummy_female", "count": 4}, {"kind": "khopesh_guard", "count": 2}],  # TUNING (not in GDD) one column
	# The Embalmer.
	"embalm_timer": 3.0,  # Owner-approved proposal: "the cartouche timer is 3 s while he does"
	"wrap_first": 2.0,  # TUNING (not in GDD) s after the phase begins
	"wrap_every": 8.0,  # TUNING (not in GDD) s between two wrappings
	"wrap_windup": 0.9,  # TUNING (not in GDD) s he halts (cast pose)
	"wrap_count": 6,  # TUNING (not in GDD) wrapped dead a wrapping
	"wrap_min": 170.0,  # TUNING (not in GDD) px from the necromancer (beyond the ring)
	"wrap_max": 260.0,  # TUNING (not in GDD) px
	"wrap_kinds": ["mummy", "mummy_female", "mummy", "jackal_warrior"],  # TUNING (not in GDD) in turn (a jackal now and then)
	# The Jackal.
	"jackal_speed_mult": 1.6,  # TUNING (not in GDD) x his speed
	"lunge_first": 1.5,  # TUNING (not in GDD) s after the phase begins
	"lunge_every": 3.4,  # TUNING (not in GDD) s between two lunges
	"lunge_windup": 0.55,  # TUNING (not in GDD) s of crouch (the telegraph)
	"lunge_lead": 0.5,  # TUNING (not in GDD) share of the dash a moving necromancer is led by
	"lunge_speed": 900.0,  # TUNING (not in GDD) px/s
	"lunge_reach": 300.0,  # TUNING (not in GDD) px at most a dash
	"lunge_min": 60.0,  # TUNING (not in GDD) px; closer than this he strikes in reach
	"lunge_width": 26.0,  # TUNING (not in GDD) px each side of the dash line that summons are struck
	"lunge_damage": 13.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"lunge_damage_summon": 10.0,  # TUNING (not in GDD) to each summon passed, before the time scaling
	"afterimages": 4,  # TUNING (not in GDD) drawing only: ghosts a dash leaves
	"afterimage_fade": 0.45,  # TUNING (not in GDD) drawing only: s a ghost lasts
}
