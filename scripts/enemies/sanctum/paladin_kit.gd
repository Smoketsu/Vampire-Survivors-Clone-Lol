## PaladinKit — the Sun Paladin's sun ward aura (owner brief; GDD §8.3
## "Elite paladins"). The Paladin itself is an armoured Templar Knight: the
## shared "templar" AI with its telegraphed charge (SanctumEnemyData keys
## charge_*). At the 5 Hz think rate it wards every OTHER living Covenant
## soldier within ward_radius px (the boss and minibosses included,
## structures and the Reckoning excepted): Enemy.ward_until is refreshed to
## now + SanctumEnemyData.WARD_LINGER and Enemy.ward_resist set to its
## ward_resist. CombatResolver.damage_enemy() is the one path that applies
## it (a Soul Nova ignores it). A soldier holds ONE ward: overlapping
## Paladins keep the strongest value, they never stack.
## Stats: paladin_ward_pulses (soldier-refreshes), paladin_ward_dmg_prevented
## (CombatResolver), templar_charges (the shared charge counter).
class_name PaladinKit
extends CovenantKit

## Reusable query buffer.
var _tmp: Array = []


## Refreshes the ward on every soldier in reach.
func think(e: Enemy) -> void:
	var g := e.game
	var r := float(d["ward_radius"])  # Aura reach (px).
	var resist := float(d["ward_resist"])  # Damage fraction the ward removes.
	var now := g.elapsed  # Run time (s).
	g.enemy_grid.query(e.position, r, _tmp)
	var warded := 0  # Soldiers refreshed this pulse (stat).
	for o: Enemy in _tmp:
		if o == e or not o.active or o.is_structure or o.is_reckoning:
			continue
		if o.position.distance_to(e.position) > r:
			continue
		if o.ward_until <= now:
			o.ward_resist = resist
			o.queue_redraw()  # The ward pip appears.
		else:
			o.ward_resist = maxf(o.ward_resist, resist)
		o.ward_until = now + SanctumEnemyData.WARD_LINGER
		warded += 1
	if warded > 0:
		g.stat_add("paladin_ward_pulses", float(warded))
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)  # Engine motion: the ward pulse (visual only).


## The sun aura's reach under the body.
func draw_under(e: Enemy) -> void:
	SanctumGlyphs.draw_sun_aura(e, float(d["ward_radius"]))
