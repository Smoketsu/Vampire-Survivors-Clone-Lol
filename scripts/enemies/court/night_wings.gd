## NightWings — NIGHT WINGS, the second Sanguine Court rule (Act VII; GDD §15.0
## "Night Wings"; owner-approved proposal: "Bats and bat-folk fly over the Bone
## Ring: the ring cannot body-block them, so they reach the necromancer and the
## priests inside. They must land to bite (a 0.5 s swoop shown by a shadow on
## the ground), and in flight only airborne summons, ranged attacks and spells
## can hit them ... One flag on the enemy row (flies) read by the existing
## body-block code"). Owned by Game.court as `wings`: the rule's counters and
## its documentation. THE one path, all of it on the ENEMY (no summon gets an
## act rule):
##   * THE FLAG: the row's "flies" -> Enemy.flies (set in Enemy.activate()).
##     Enemy.resolve_blocking() returns at once for a flier, so no blocker
##     body-blocks it (the same skip as Act V's ethereal onryo). The row also
##     sets "phases" (it crosses obstacles) and "floating" (the ground's slows
##     and fires spare it).
##   * THE HUNT, THE SWOOP AND THE BITE: CourtKit.physics() (every Court kit,
##     so phase 2's Chiropterans fly the same way): in flight a flier drops a
##     summon target that is not a priest (NIGHT_WINGS prey_classes) for the
##     necromancer; when its blow is ready and its target within reach it
##     SWOOPS for the row's swoop_time s (its ground shadow grows), bites
##     through the shared melee blow (Enemy._melee_hit(): Bloodfeast feeds it),
##     stays LANDED for landed_time s and takes off again. Its own melee blow
##     never fires in flight.
##   * THE HITS: CourtKit.taken_mult() (the generic kit read in
##     Enemy.damage_taken_mult(), as Act VI's Fallen Angel): in flight a
##     GROUNDED MELEE summon's blow (FallenAngelKit.grounded_melee(), the shared
##     test) deals flight_melee_taken of itself (0); the gargoyles' swoops, the
##     ranged and caster classes, the spells, the volleys and the hazards land
##     in full, and on the ground (the swoop and the landing) every blow does.
## Determinism: no RNG (the kit's phases run on game time). Stats (summary
## "night wings" line): night_wings_swoops, night_wings_bites_you,
## night_wings_bites_summons, night_wings_bites_missed, night_wings_air_hits
## (allowed hits in flight), night_wings_air_whiffs (grounded melee blows that
## found only air), night_wings_landed_hits, night_wings_retargets.
class_name NightWings
extends RefCounted

## Phase of a flier: in the air (the kit's IDLE).
const AIR: int = 0
## Phase of a flier: swooping down to bite.
const SWOOP: int = 1
## Phase of a flier: on the ground after the bite.
const LANDED: int = 2

## Owning run.
var game: Game
## Night Wings numbers (CourtRulesData.NIGHT_WINGS).
var cfg: Dictionary = {}


## Builds Night Wings for `p_game` (CourtRules keeps it).
func _init(p_game: Game) -> void:
	game = p_game
	cfg = CourtRulesData.NIGHT_WINGS.duplicate()


## True when summon class `cls` is prey a flier keeps as its target (a priest
## inside the ring); any other summon target is dropped for the necromancer.
func is_prey(cls: String) -> bool:
	return (cfg["prey_classes"] as Array).has(cls)


## Share of a friendly hit tagged `source` a flier in phase `ph` takes (see the
## header): a grounded melee blow in flight deals flight_melee_taken; every
## other hit, and every hit on the ground, lands in full. Counts the hit.
func taken_mult(ph: int, source: String) -> float:
	if ph != AIR:
		game.stat_add("night_wings_landed_hits", 1.0)
		return 1.0
	if FallenAngelKit.grounded_melee(source):
		game.stat_add("night_wings_air_whiffs", 1.0)
		return float(cfg["flight_melee_taken"])
	game.stat_add("night_wings_air_hits", 1.0)
	return 1.0
