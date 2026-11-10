## SporeMotherKit — the kit of the SPORE MOTHER (female, figure style;
## WildEnemyData "spore_mother"; temporary Act XV, the Turning Year; GDD §15.0
## "The Greenwood (Act XV phase 2)"; owner-approved proposal: "Spore Mother
## (female, figure style) | Support | Spores that rot summons and spread
## blight-killing mould | Kill early"). The plain melee AI walks her in; every
## spore_every s she puffs SPORES round her:
##   * every grounded summon within spore_radius px takes spore_damage (x the
##     time scaling) and ROTS: its strength and speed fall to spore_curse for
##     spore_time s (CombatResolver.curse_unit(), the one summon weakening path);
##   * the MOULD kills the blight within mould_radius px of her, mould_cut a
##     puff (BloomField.mould(), the one path that lowers blight), so the Wild
##     heals there again.
## Determinism: no RNG, no instance ids. Stats: spore_puffs, spore_rots,
## mould_cells.
class_name SporeMotherKit
extends WildKit

## Spore damage tag (stats, the death line, `wild damage`).
const SOURCE: String = "spore_mother_spores"

## Seconds until the next puff.
var cd: float = 0.0
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d.get("spore_first", 2.5)))


func physics(e: Enemy, delta: float) -> bool:
	cd -= delta
	if cd > 0.0:
		return false
	cd = float(d.get("spore_every", 5.0))
	var g := e.game
	var r := float(d.get("spore_radius", 70.0))
	var dmg := float(d.get("spore_damage", 3.0)) * hit_scale(e) * e.undead_damage_mult
	var until := g.elapsed + float(d.get("spore_time", 4.0))
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.airborne or u.flies or u.state == SummonedUnit.State.DEAD or u.position.distance_to(e.position) > r + u.radius:
			continue
		g.combat.damage_unit(u, dmg, SOURCE, e)
		if u.active and g.combat.curse_unit(u, float(d.get("spore_curse", 0.8)), until, SOURCE):
			g.stat_add("spore_rots", 1.0)
	var w := rules(e)
	if w.bloom.enabled:
		g.stat_add("mould_cells", float(w.bloom.mould(e.position, float(d.get("mould_radius", 90.0)), float(d.get("mould_cut", 0.5)))))
	g.stat_add("spore_puffs", 1.0)
	g.effects.ring(e.position, r, Palette.WILD_GOLD_LEAF, 0.4)
	return false
