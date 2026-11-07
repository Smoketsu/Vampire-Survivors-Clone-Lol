## VandermereData — immutable design data of CAPTAIN CORNELIUS VANDERMERE,
## MASTER OF THE HOLLOW QUEEN, the Maelstrom's boss (Act X, the Black Tide's
## finale; GDD §15.0 "Captain Cornelius Vandermere"; owner-approved proposal
## docs/proposals/NEW_ACTS_AND_ORDER.md Part 1: "The Crew: his spectral crew
## works the ship; ghost boats circle the gyre. The Maelstrom: the tilt peaks.
## The kraken's arms strike the low rail whenever the deck leans toward them.
## Dead Men's Oath: he is lashed to the wheel behind an Oath shield. Every ghost
## crewman the army raises chips the Oath (2% each). When it is empty he is
## vulnerable for 15 s, then the Oath refills and the crew returns ... When he
## falls, the whirlpool closes and the sea is calm"). Read by BossVandermere
## (scripts/enemies/corsair/boss_vandermere.gd). No logic here. The GDD gives no
## numbers: everything is TUNING (not in GDD) unless marked as the owner-approved
## proposal. Tuned for the act's FINAL slot II (an early act).
class_name VandermereData
extends RefCounted

## His arrival (keys as GraveyardStage.BOSS; StageRegistry BOSS_ARRIVALS
## "vandermere" through MaelstromStage.BOSS, so --boss=vandermere and the Codex
## find him). The defeat banner is the stage's short ending (the proposal: "the
## whirlpool closes and the sea is calm"; no epilogue part, docs/last_acts/PLAN.md).
const ARRIVAL := {
	"id": "vandermere",
	"time": 1020.0,  # GDD §15.0: every stage boss arrives at 17:00 (3:00 left)
	"display_name": "Captain Cornelius Vandermere, Master of the Hollow Queen",  # Owner-approved proposal
	"short_name": "Vandermere",
	"arrive_banner": "Vandermere takes the wheel: his crew of the dead works the Hollow Queen!",  # TUNING (not in GDD)
	"defeat_banner": "Vandermere lets go of the wheel. The whirlpool closes, and the sea is calm.",  # Owner-approved proposal: the short ending
	"dead_objective": "The Hollow Queen is still. Survive the Black Tide... you cannot.",  # TUNING (not in GDD)
}

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["crew", "volley", "maelstrom", "oath_break"]

## His base max HP (x the boss HP multiplier and the stage's HP multiplier:
## 30,000 on the Maelstrom). Seraphine 21,000 x 1.1; Dead Men's Oath cuts what he
## takes while it holds, so his effective HP is far higher until it breaks.
const MAX_HP: float = 20000.0  # TUNING (not in GDD) first pass 9,000: the seed-7 army bot slew him in 54 s

## Run stat set when he fell with his Oath broken at least TALES_BREAKS times
## (MetaProgress counts it for Dead Men Tell Tales).
const TALES_STAT: String = "vandermere_tales_kills"
## Oath breaks the achievement asks (owner-approved proposal: "beat Vandermere
## with the Oath broken three times").
const TALES_BREAKS: int = 3  # Owner-approved proposal

## Damage-source tag of his spectral lantern volley.
const VOLLEY_SOURCE: String = "vandermere_volley"

## Boss row: Enemy row keys plus his ability numbers.
const BOSS := {
	"display_name": "Captain Cornelius Vandermere",
	"max_hp": MAX_HP,
	"move_speed": 32.0,  # TUNING (not in GDD) px/s; the wheel drifts with him (enemies always advance)
	"damage": 12.0,  # TUNING (not in GDD) a blow of the spoked wheel in reach
	"attack_interval": 1.4,  # TUNING (not in GDD) s
	"attack_range": 10.0,  # TUNING (not in GDD) px
	"radius": 22.0,  # TUNING (not in GDD) px (a 100 px hover still)
	"armor": 0.15,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 12.0,  # TUNING (not in GDD)
	"floating": true,  # A ghost: the ground's hazards spare him
	"faction": CorsairEnemyData.FACTION,
	"reward_xp": 520,  # TUNING (not in GDD) an early act's finale (Seraphine's league)
	"reward_crystals": 24,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.5,  # TUNING (not in GDD) s he stands after a special
	"advance_range": 380.0,  # TUNING (not in GDD) px; farther than this he drifts faster
	"advance_speed_mult": 1.8,  # TUNING (not in GDD)
	# Dead Men's Oath (owner-approved proposal: "Every ghost crewman the army
	# raises chips the Oath (2% each). When it is empty he is vulnerable for 15
	# s, then the Oath refills and the crew returns").
	"oath_chip": 0.02,  # Owner-approved proposal: 2% of the Oath per ghost crewman raised
	"oath_taken": 0.35,  # TUNING (not in GDD) share of a hit he takes while the Oath holds
	"vulnerable_time": 15.0,  # Owner-approved proposal: vulnerable for 15 s
	"vulnerable_taken": 1.5,  # TUNING (not in GDD) share of a hit he takes while it is broken
	"refill_boats": 3,  # TUNING (not in GDD) ghost boats that come when the Oath refills ("the crew returns")
	# The Crew (owner-approved proposal: "his spectral crew works the ship;
	# ghost boats circle the gyre"): every crew_every s spectral longboats
	# with his drowned crew come alongside (BoardingParty.launch_boat()).
	"first_crew": 2.0,  # TUNING (not in GDD) s after arrival
	"crew_every": 15.0,  # TUNING (not in GDD) s, the Crew
	"crew_every_p2": 12.0,  # TUNING (not in GDD) s, in the Maelstrom
	"crew_boats": 2,  # TUNING (not in GDD) spectral longboats a call
	"crew_size": 8,  # TUNING (not in GDD) drowned crewmen a boat
	"crew_gunners": 2,  # TUNING (not in GDD) of them Ghost Gunners
	"crew_cast": 0.8,  # TUNING (not in GDD) s he stands calling them
	# His lantern volley (own decision: the proposal gives him no blow of his
	# own; a threat to the necromancer while his crew boards): volley_count
	# spectral shots fanned volley_spread rad apart at the necromancer through
	# the hostile projectile path, after a volley_cast s windup.
	"first_volley": 5.0,  # TUNING (not in GDD) s after arrival
	"volley_every": 7.5,  # TUNING (not in GDD) s
	"volley_cast": 0.8,  # TUNING (not in GDD) s
	"volley_count": 5,  # TUNING (not in GDD)
	"volley_spread": 0.2,  # TUNING (not in GDD) rad between two shots
	"volley_damage": 7.0,  # TUNING (not in GDD) per shot, x the damage scaling
	"volley_speed": 210.0,  # TUNING (not in GDD) px/s
	"volley_range": 420.0,  # TUNING (not in GDD) px: he fires when the necromancer is this close
	# The Maelstrom (owner-approved proposal: "the tilt peaks. The kraken's arms
	# strike the low rail whenever the deck leans toward them"): below
	# phase2_hp the Heave peaks (MaelstromStage.MAELSTROM heave peak_mult /
	# peak_period), kraken_arms kraken arms surface, and every kraken_every s an
	# ownerless strike (SeaStrikes.strike()) lands on the LOW rail's band beside
	# the necromancer.
	"phase2_hp": 0.55,  # TUNING (not in GDD)
	"phase2_banner": "THE MAELSTROM: the whirlpool tightens, and the kraken strikes the low rail!",  # TUNING (not in GDD)
	"kraken_arms": 2,  # TUNING (not in GDD) kraken arms that surface at the Maelstrom's start
	"kraken_every": 2.6,  # TUNING (not in GDD) s between two strikes on the low rail
	"kraken_radius": 42.0,  # TUNING (not in GDD) px each strike
	"kraken_spread": 260.0,  # TUNING (not in GDD) px along the rail round the necromancer's x
	"kraken_inset": 0.45,  # TUNING (not in GDD) share of the rail band inside the rail a strike lands (centre)
	"oath_banner": "THE OATH BREAKS! Vandermere is bound no more: strike now!",  # TUNING (not in GDD)
	"refill_banner": "The Oath binds him again, and his crew returns from the deep!",  # TUNING (not in GDD)
}
