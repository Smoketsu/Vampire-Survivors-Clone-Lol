## CastleSanguisEnemyData — immutable design data for the Court kinds that join
## on Castle Sanguis (Stage 21, the finale of Act VII; GDD §15.0 "Act VII
## foundation (phase 1)" and "Castle Sanguis (Act VII phase 2)"; owner-approved
## proposal docs/act7/PROPOSAL.md "Stage 21: Castle Sanguis" and its roster):
##   chiropteran_king — the Chiropteran King, the stage MINIBOSS
##                      (ChiropteranKingKit; CastleSanguisDirector sends him): a
##                      giant bat-man who flies over the ring (Night Wings),
##                      CARRIES summons off over it and drops them outside
##                      (an enemy effect on units, through the held hook
##                      SummonedUnit.held_until), shrieks a wide stunning cone
##                      and, at half health, calls a swarm of bats.
##   blood_bearer     — a Blood Bearer: a thrall with a chalice of blood
##                      (BloodBearerKit). While Queen Carmilla kneels at the
##                      Elder's coffin (the Waking) they come from the edge of
##                      the fight and walk to HER, not to the necromancer; one
##                      that reaches her pours its blood into the Elder (the
##                      existing enemy heal path). Kill them on the way
##                      (owner-approved proposal: "killing the thralls that
##                      bring her blood" interrupts her).
## The fourth new Court kind of the proposal's roster built by this stage, the
## CHIROPTERAN (elite, flier, sonic shriek), is a row of the shared table
## (CourtEnemyData "chiropteran", the block "# --- Act VII: Castle Sanguis ---"
## at its end: any stage may use it); its kit is ChiropteranKit and its
## constants are here (CHIROPTERAN, SHRIEK_SOURCE, SHRIEK_STUN).
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.court_def() looks these rows up after
## CourtEnemyData. Rows have every key of a CourtEnemyData.ENEMIES row (same
## meaning; "kit" ids load scripts/enemies/court/<kit>_kit.gd, unique across the
## Eye, Empire, Pantheon, Shogunate, Inferno and Court folders; "feeds",
## "flies", "werebeast", "noble" switch the shared rules on for the kind) plus
## their kit's numbers, documented on each row.
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name CastleSanguisEnemyData
extends RefCounted

## Kind id of the Chiropteran (the shared elite flier, CourtEnemyData's row).
const CHIROPTERAN: String = "chiropteran"
## Kind id of the Chiropteran King (the stage miniboss).
const KING: String = "chiropteran_king"
## Kind id of the Blood Bearer (Carmilla's Waking).
const BEARER: String = "blood_bearer"
## Damage source tag of a Chiropteran's sonic shriek (on the necromancer).
const SHRIEK_SOURCE: String = "chiropteran_shriek"
## Damage source tag of the King's great shriek (on the necromancer).
const KING_SHRIEK_SOURCE: String = "king_shriek"
## Damage source tag of a carried summon's fall (the King drops it).
const DROP_SOURCE: String = "king_drop"
## Stun source tag of a Chiropteran's shriek (CombatResolver.stun_unit() stats).
const SHRIEK_STUN: String = "chiropteran_shriek"
## Stun source tag of the King's great shriek.
const KING_STUN: String = "king_shriek"

## Kind id -> design row.
const ENEMIES := {
	# The MINIBOSS (male): a giant bat-man, leathery black-violet wings, grey
	# fur, a crown of bone on his brow. A FLIER (Night Wings: the ring never
	# body-blocks him) who never bites in a swoop of his own: his attacks take
	# turns, attack_gap s apart, and his own claw blow is the shared melee
	# blow. In flight a grounded melee summon's blow deals aloft_melee_taken of
	# itself (a miniboss must stay within the army's reach; the bats take none).
	#   CARRY-OFF (a summon within grab_range px of him): he swoops on up to
	#     grab_count summons around the nearest one (grab_radius px),
	#     telegraphed grab_telegraph s (a dark circle), lifts them and FLIES
	#     carry_time s straight away from the necromancer (at most carry_speed
	#     px/s) toward carry_out px beyond the Bone Ring, then DROPS them there
	#     (drop_damage each, time-scaled; held drop_daze s more). While carried
	#     a summon is held (SummonedUnit.held_until, the Netcaster's hold) and
	#     moved with him. Killing him drops them at once. After the drop he flies
	#     back to the Bone Ring's edge and LANDS there (after a shriek where
	#     he is) for land_time s: every blow lands in full.
	#   GREAT SHRIEK: a cone of shriek_range px, shriek_arc degrees each side,
	#     at the necromancer, telegraphed shriek_telegraph s: every summon in it
	#     is stunned shriek_stun s (CombatResolver.stun_unit()), the
	#     necromancer struck for shriek_damage.
	#   THE COLONY (once, below swarm_hp of his health): swarm_count Vampire
	#     Bats burst from his wings around him (the hard cap respected).
	"chiropteran_king": {
		"display_name": "The Chiropteran King",
		"max_hp": 1200.0,  # TUNING (not in GDD) before the time / stage scaling; 2600 lived 488 s, 1800 451 s, 1500 497 s 1300 (landing where he dropped them) and 800 outlived the run: he landed out of the army's reach; he now lands at the ring's edge in the seed-7 army run (he flies out of reach)
		"move_speed": 60.0,  # TUNING (not in GDD) px/s; he flies
		"damage": 12.0,  # TUNING (not in GDD) a claw blow, before the time scaling
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 24.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 0,  # His reward is the XP burst below.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers prioritise him like a boss
		"mass": 12.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"faction": CourtEnemyData.FACTION,
		"kit": "chiropteran_king",
		"feeds": 0.25,  # Owner-approved (Oct 31, 2026): bat-folk, not a vampire: 25%
		"flies": true,  # Owner-approved proposal: he carries summons off "over the ring" (Night Wings)
		"phases": true,  # A flier crosses obstacles.
		"floating": true,  # Over the ground.
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,
		"reward_xp": 220,  # TUNING (not in GDD) XP burst on death (the Fallen Seraph General 220)
		"reward_crystals": 12,  # TUNING (not in GDD)
		"reward_ash": 15,  # TUNING (not in GDD) Soul Ash bounty (objective_ash)
		"aloft_melee_taken": 0.7,  # TUNING (not in GDD) share of a grounded melee blow he takes in flight; first pass 0.5
		"advance_range": 420.0,  # TUNING (not in GDD) px beyond which he flies faster
		"advance_speed_mult": 1.8,  # TUNING (not in GDD)
		"first_attack": 3.0,  # TUNING (not in GDD) s after he arrives
		"attack_gap": 3.5,  # TUNING (not in GDD) s between the end of one attack and the next; first pass 2.2 (96 carry-offs in one run)
		"grab_range": 140.0,  # TUNING (not in GDD) px: he carries off a summon this close, else he shrieks
		"grab_count": 2,  # TUNING (not in GDD) summons a carry-off lifts
		"grab_radius": 40.0,  # TUNING (not in GDD) px around the first one
		"grab_telegraph": 0.8,  # TUNING (not in GDD) s (a dark circle where he will strike)
		"carry_time": 1.6,  # TUNING (not in GDD) s in the air
		"carry_out": 100.0,  # TUNING (not in GDD) px beyond the Bone Ring's outer edge he drops them; first pass 170 (he spent the fight out of the army's reach)
		"carry_speed": 260.0,  # TUNING (not in GDD) px/s at most while carrying
		"drop_damage": 10.0,  # TUNING (not in GDD) to each dropped summon, before the time scaling
		"drop_daze": 0.8,  # TUNING (not in GDD) s a dropped summon stays held where it fell
		"land_time": 2.5,  # TUNING (not in GDD) s he stands on the ground after a drop or a shriek, every blow landing in full (first pass 0.5 s in the air: he lived ~8 minutes)
		"shriek_range": 170.0,  # TUNING (not in GDD) px
		"shriek_arc": 45.0,  # TUNING (not in GDD) degrees each side
		"shriek_telegraph": 0.9,  # TUNING (not in GDD) s
		"shriek_stun": 1.5,  # Owner-approved proposal (the Chiropterans' 1.5 s)
		"shriek_damage": 9.0,  # TUNING (not in GDD) to a necromancer in the cone, before the time scaling
		"swarm_hp": 0.5,  # TUNING (not in GDD) share of his health that calls the colony
		"swarm_count": 10,  # Owner-approved proposal: bats come in swarms of 10
	},
	# A Blood Bearer (male): a pale thrall in a servant's coat carrying a gold
	# chalice of blood. Only Carmilla's Waking sends them (BossCarmilla): it
	# walks at bearer_speed px/s straight to the kneeling Queen, never fights,
	# and when it reaches her (pour_reach px edge to edge) it pours: the Elder
	# gains the boss's bearer_heal share of his health (BossCarmilla.pour(), the
	# enemy heal path) and the bearer is gone (no kill, no XP). Kill it on the
	# way. Away from a Waking it walks at the necromancer like a thrall and
	# never strikes.
	"blood_bearer": {
		"display_name": "Blood Bearer",
		"max_hp": 34.0,  # TUNING (not in GDD) a sturdy thrall (Blood Thrall 15): the army needs a moment for each
		"move_speed": 44.0,  # TUNING (not in GDD) px/s (the walk when no Queen kneels)
		"damage": 0.0,  # It never fights.
		"attack_interval": 1.0,  # Unused (it never strikes).
		"attack_range": 0.0,  # Unused.
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1: the army hunts them first
		"mass": 0.8,  # TUNING (not in GDD)
		"faction": CourtEnemyData.FACTION,
		"kit": "blood_bearer",
		"wears": "court/blood_thrall",  # The Blood Thrall's art (BloodBearerKit draws the chalice over it).
		"fodder": true,
		"bearer_speed": 56.0,  # TUNING (not in GDD) px/s toward the kneeling Queen
		"pour_reach": 20.0,  # TUNING (not in GDD) px edge to edge: it pours at her side
	},
}
