## LavaHoundKit — the kit of the HELLHOUND (BurningGateEnemyData "lava_hound";
## Act VI, the Burning Gate; GDD §15.0 "The Burning Gate (Act VI phase 2)";
## owner-approved roster: "Hellhound: Pack. Lava hounds; leave a short fire
## trail"). Fast pack fodder of the Pit, a DEMON (the pits spare it). Its
## TRAIL: while it runs (it moved at least trail_min_move px since its last
## pit), every trail_every s it leaves a small Hell Pit of trail_radius px
## where it stood, through the ONE pit path (HellPits.open_pit(), tag
## "hound_trail": a trail_telegraph s glow, then trail_life s of burning at
## trail_dps_mult x the pits' burn, silent). The trail burns summons, the
## necromancer and every living enemy (the damned, the cultists) like any pit;
## the Bone Ring flows around it (HellPits.avoid_point()). Only where the pits
## burn (InfernoRules.enabled: an Act VI stage) and only while trail_room slots
## of the pits' hard cap stay free, so a pack never crowds out the stage's and
## the bosses' pits, and only within trail_reach px of the necromancer (where
## the army walks). No RNG. Stats: hound_trail_pits, hound_trail_skipped.
class_name LavaHoundKit
extends InfernoKit

## Seconds until the next trail pit.
var _trail_cd: float = 0.0
## World point of the last trail pit (or of the spawn).
var _last: Vector2 = Vector2.ZERO


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_trail_cd = first_cd(e, float(def.get("trail_every", 0.8)))
	_last = e.position


func physics(e: Enemy, delta: float) -> bool:
	_trail_cd -= delta
	if _trail_cd > 0.0:
		return false
	_trail_cd = float(d.get("trail_every", 0.8))
	var inf := rules(e)
	if not inf.enabled or e.position.distance_to(_last) < float(d.get("trail_min_move", 18.0)):
		return false
	if e.position.distance_to(e.game.player.position) > float(d.get("trail_reach", 600.0)):
		return false  # Far from the army: no trail where nobody walks.
	var pits := inf.pits
	if pits.count >= int(pits.cfg["max_pits"]) - int(d.get("trail_room", 10)):
		e.game.stat_add("hound_trail_skipped", 1.0)
		return false
	if pits.open_pit(e.position, float(d.get("trail_radius", 14.0)), float(d.get("trail_life", 2.2)), {
			"telegraph": float(d.get("trail_telegraph", 0.3)), "tag": BurningGateEnemyData.TRAIL_TAG,
			"dps_mult": float(d.get("trail_dps_mult", 0.6)), "silent": true}):
		e.game.stat_add("hound_trail_pits", 1.0)
		_last = e.position
	return false
