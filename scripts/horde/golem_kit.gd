## GolemKit — the Bone Golem's army-wide rules (content wave 2, GDD §15.0
## "Bone Golem (content wave 2)"; numbers in UnitData "bone_golem" special and
## SummonEvolutionData "ossuary_titan" special_set). Owned by HordeDirector
## (`golems`) and created on the first Golem's activation (golem_kit()), so a
## run without a Golem never makes one and never calls into it.
##   * Ossuary Hunger: on_summon_died() (HordeDirector.on_unit_died(), every
##     real death of a non-Golem summon, and a temporary summon that was KILLED;
##     one that crumbled at the end of its life is not a fallen body): the
##     nearest living Golem within its hunger_reach px absorbs the body
##     (GolemBehavior.absorb(): +max HP, a bigger body). Same on every stage
##     (owner rule: no act-specific summon mechanics; an Ancient Eye claim of
##     the same body is independent of it).
##   * The Ossuary Titan (the evolution): an absorbed body also heals it
##     absorb_heal x its max HP, and (at most every barrier_cooldown s per
##     Titan) every other summon within barrier_reach px gets a barrier of
##     barrier_amount HP through the Warder's barrier path
##     (SummonAbilities.grant_barrier(): the stronger barrier wins, absorbed
##     in CombatResolver.damage_unit()). When a Titan falls it collapses into a
##     straight bone wall of wall_segments segments across the line from the
##     necromancer to it, standing wall_duration s (the Bone Wall spell's
##     segment system, BoneWall.raise_wall(): enemies only are pushed out, no
##     segment inside an obstacle, bosses / minibosses / Reckoning foes /
##     structures are not held), its spikes dealing wall_damage x the Titan's
##     damage per tick (source "titan_wall").
## Determinism: positions, game time and the units array's order only.
## Stats: golem_absorbed, golem_absorb_growth_pct (sum of growth gained, %),
## golem_max_growth_pct, titan_heal, titan_barriers, titan_barrier_hp,
## titan_walls, titan_wall_segments (plus the Bone Wall node's
## titan_wall_hits / titan_wall_pushes).
class_name GolemKit
extends RefCounted

## Class id of the Bone Golem (UnitData).
const CLASS_ID: String = "bone_golem"
## Evolution id of the Ossuary Titan (SummonEvolutionData).
const EVOLUTION_ID: String = "ossuary_titan"
## Damage source tag of the Titan's collapse wall spikes.
const WALL_SOURCE: String = "titan_wall"

## Owning horde director.
var director: HordeDirector
## Golems activated this run (statistics).
var risen: int = 0
## Highest Ossuary Hunger growth any Golem reached this run (fraction).
var max_growth: float = 0.0
## Reusable ally query buffer.
var _buf: Array = []


func _init(p_director: HordeDirector) -> void:
	director = p_director


## A Golem rose (GolemBehavior.reset()).
func on_golem_risen(_u: SummonedUnit) -> void:
	risen += 1


## Death hook (HordeDirector.on_unit_died(), before `u` is pooled; real deaths
## and expired temporaries): a fallen Titan collapses into its wall; any other
## fallen summon is absorbed by the nearest Golem in reach.
func on_summon_died(u: SummonedUnit) -> void:
	if u.unit_class == CLASS_ID:
		if u.evolution == EVOLUTION_ID and not u.is_temporary:
			_collapse(u)
		return
	if u.is_temporary and u.hp > 0.0:
		return  # Crumbled at the end of its life, not slain: nothing to absorb.
	var best: SummonedUnit = null  # Nearest Golem in reach.
	var best_d := INF  # Its distance (px).
	for g in director.units:
		if g == u or not g.active or g.unit_class != CLASS_ID or g.state == SummonedUnit.State.SPAWNING:
			continue
		var d := g.position.distance_to(u.position)  # Centre distance (px).
		if d <= float(g.special.get("hunger_reach", 140.0)) and d < best_d:
			best_d = d
			best = g
	if best == null:
		return
	var b := best.behavior as GolemBehavior  # Its kit (always a GolemBehavior).
	if b == null:
		return
	_absorb_fx(u.position, best)
	var gained := b.absorb(best)  # Growth fraction gained (0 at the cap).
	var game := director.game
	game.stat_add("golem_absorbed", 1.0)
	game.stat_add("golem_absorb_growth_pct", gained * 100.0)
	if b.growth > max_growth:
		max_growth = b.growth
		game.stats["golem_max_growth_pct"] = max_growth * 100.0
	if best.evolution == EVOLUTION_ID:
		_titan_absorb(best, b)


## The Ossuary Titan's absorb: a heal, then (off cooldown) barriers around it.
func _titan_absorb(t: SummonedUnit, b: GolemBehavior) -> void:
	var game := director.game
	var sp := t.special  # Titan numbers (special_set, final).
	game.stat_add("titan_heal", game.combat.heal_unit(t, t.max_hp * float(sp.get("absorb_heal", 0.0))))
	if game.elapsed < b.barrier_ready_at:
		return
	b.barrier_ready_at = game.elapsed + float(sp.get("barrier_cooldown", 2.0))
	var amount := float(sp.get("barrier_amount", 0.0))  # Barrier HP.
	var reach := float(sp.get("barrier_reach", 100.0))  # Barrier reach (px).
	if amount <= 0.0:
		return
	game.ally_grid.query(t.position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	var n := 0  # Summons shielded.
	for a: SummonedUnit in _buf:
		if a == t or not a.active or a.state == SummonedUnit.State.SPAWNING or a.position.distance_to(t.position) > reach + a.radius:
			continue
		var gained := SummonAbilities.grant_barrier(a, amount)  # Barrier HP added.
		if gained > 0.0:
			n += 1
			game.stat_add("titan_barrier_hp", gained)
	if n > 0:
		game.effects.ring(t.position, reach, Palette.COLD_BLUE, 0.4)
		game.stat_add("titan_barriers", 1.0)


## A fallen Titan becomes a bone wall across the necromancer's side of it.
func _collapse(t: SummonedUnit) -> void:
	var game := director.game
	var sp := t.special  # Titan numbers (special_set, final).
	var away := t.position - game.player.position  # Necromancer -> Titan.
	var dir := away.normalized() if away.length() > 1.0 else director.threat_dir
	var across := dir.orthogonal()  # Along the wall.
	var n := int(sp.get("wall_segments", 7))  # Segments wanted.
	var r := GraveSpellData.BONE_WALL_SEGMENT_RADIUS  # Segment radius (px).
	var segs := PackedVector2Array()  # Segment centres that fit.
	for k in n:
		var q := t.position + across * (float(k) - float(n - 1) * 0.5) * GraveSpellData.BONE_WALL_SPACING
		if not game.arena.is_blocked(q, r):
			segs.append(q)
	if segs.is_empty():
		return
	var wall := game.abilities.spells.bone_wall_node()  # The Bone Wall segment system (created if needed).
	var dmg := t.damage * float(sp.get("wall_damage", 0.0))  # Spike damage per tick.
	if wall.raise_wall(segs, -dir, float(sp.get("wall_duration", 6.0)), dmg, WALL_SOURCE):
		game.stat_add("titan_walls", 1.0)
		game.stat_add("titan_wall_segments", float(segs.size()))
		game.effects.ring(t.position, r * 5.0, Palette.BONE, 0.4)
		game.shake(2.5)


## The bones of a fallen summon streaming into the Golem (visual only).
func _absorb_fx(from: Vector2, g: SummonedUnit) -> void:
	var game := director.game
	game.effects.beam(from, g.position, Palette.BONE)
	game.effects.ring(g.position, g.radius * 1.6, Palette.NECRO_GREEN, 0.3)
