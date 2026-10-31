## FallenAngelKit — the kit of the Fallen Angel (PandemoniumEnemyData
## "fallen_angel"; Act VI, Pandemonium; GDD §15.0 "Pandemonium (Act VI phase
## 2)"; owner-approved proposal: "Fallen Angel | Elite | Dives from above with
## a burning spear | Gargoyles, ranged"): the elite in the approved Act VI
## figure style (female). A DEMON (the pits spare her) and a FLIER (over the
## pits and obstacles). Her numbers are her row's.
##   * ALOFT (every phase but LANDED): she hangs above the fray. A blow from a
##     GROUNDED MELEE summon (a class whose UnitData attack_profile is "melee"
##     and whose behavior is not the gargoyle's "swoop", or its evolution, or a
##     warrior's bash) only grazes her: she takes aloft_melee_taken of it
##     (CovenantKit.taken_mult(), the one generic read in
##     Enemy.damage_taken_mult()). The gargoyles, every ranged and caster
##     class, the spells, the volleys and the hazards land in full: those are
##     what answer her.
##   * THE DIVE: when it is ready and her target (a summon or the necromancer)
##     is within dive_trigger px, she RISES for dive_rise s while a burning
##     circle (the shared telegraph circle, which the autotest bot steps out
##     of) marks where it stood; then she streaks down onto the mark in
##     dive_fall s (never stopped by an obstacle: she flies) and LANDS: every
##     summon in dive_radius px takes dive_damage (x undead_damage_mult) and is
##     thrown dive_push px back, the necromancer takes the blow, and on an Act
##     VI stage her burning spear leaves a short Hell Pit
##     (HellPits.open_pit(), tag "fallen_angel"). Then she stands LANDED for
##     landed_time s, open to every blow, before she takes to the air again.
## No RNG. Stats: fallen_angel_dives, fallen_angel_dive_hits (summons),
## fallen_angel_dive_player_hits, fallen_angel_grazed (blows that only grazed
## her aloft), fallen_angel_landed_hits (blows taken while landed).
class_name FallenAngelKit
extends InfernoKit

## Phase: she climbs while the landing ring is marked.
const RISE: int = 1
## Phase: the dive onto the mark.
const FALL: int = 2
## Phase: on the ground after the landing (open to every blow).
const LANDED: int = 3
## px of reach the autotest bot keeps from the landing ring beyond its radius.
const DANGER_REACH: float = 16.0  # TUNING (not in GDD) autotest hint only

## Source tag -> true when it is a grounded melee summon's blow (cache of
## grounded_melee(); the answer never changes in a run).
static var _melee_cache: Dictionary = {}

## Seconds until the next dive may start.
var _cd: float = 0.0
## Where she will land (world px; locked when she rises).
var _at: Vector2 = Vector2.ZERO
## Where the dive started (world px).
var _from: Vector2 = Vector2.ZERO
## Bodies in the landing (scratch).
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("dive_every", 7.0)) * 0.5)


func physics(e: Enemy, delta: float) -> bool:
	_cd -= delta
	match phase:
		RISE:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("dive_rise", 0.8)):
				_from = e.position
				set_phase(e, FALL)
			return true
		FALL:
			phase_time += delta
			var k := clampf(phase_time / maxf(0.01, float(d.get("dive_fall", 0.25))), 0.0, 1.0)  # 0 -> 1 down to the mark.
			e.position = _from.lerp(_at, k)
			e.velocity = Vector2.ZERO
			if k >= 1.0:
				_land(e)
				set_phase(e, LANDED)
			return true
		LANDED:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("landed_time", 1.4)):
				set_phase(e, IDLE)
			return true
	if _cd > 0.0:
		return false
	var g := e.game
	var t: Node2D = e.target if e.target != null and is_instance_valid(e.target) else g.player
	if e.position.distance_to(t.position) > float(d.get("dive_trigger", 230.0)):
		return false
	if t == g.player and g.ultimates.player_untargetable():
		return false
	_cd = float(d.get("dive_every", 7.0))
	_at = t.position
	g.effects.telegraph_circle(_at, float(d.get("dive_radius", 34.0)), float(d.get("dive_rise", 0.8)) + float(d.get("dive_fall", 0.25)), e)
	g.stat_add("fallen_angel_dives", 1.0)
	set_phase(e, RISE)
	hold(e)
	return true


## The landing: the burning spear strikes every body in the circle, throws the
## summons back and (on an Act VI stage) leaves a short pit.
func _land(e: Enemy) -> void:
	var g := e.game
	var r := float(d.get("dive_radius", 34.0))
	var dmg := float(d.get("dive_damage", 9.0)) * hit_scale(e)
	var push := float(d.get("dive_push", 22.0))
	g.effects.impact(_at, r, Palette.INFERNO_LAVA)
	g.shake(2.5)
	rules(e).play_sound("brute_slam", _at)
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(_at) <= r + pl.radius:
			g.combat.damage_player(dmg, PandemoniumEnemyData.DIVE_SOURCE, pl)
			g.stat_add("fallen_angel_dive_player_hits", 1.0)
	g.ally_grid.query(_at, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING:
			continue
		if u.position.distance_to(_at) > r + u.radius:
			continue
		g.combat.damage_unit(u, dmg * e.undead_damage_mult, PandemoniumEnemyData.DIVE_SOURCE, e)
		g.stat_add("fallen_angel_dive_hits", 1.0)
		if u.active and u.state != SummonedUnit.State.DEAD and push > 0.0 and not u.airborne:
			var away := (u.position - _at).normalized() if u.position.distance_squared_to(_at) > 1.0 else Vector2.RIGHT
			u.position += away * g.arena.clear_length(u.position, away, push, u.radius)
	var pr := float(d.get("pit_radius", 0.0))
	var inf := g.inferno
	if pr > 0.0 and inf != null and inf.enabled:
		inf.pits.open_pit(_at, pr, float(d.get("pit_life", 3.0)), {"telegraph": 0.0, "tag": "fallen_angel", "silent": true})


## Share of a friendly hit she takes: aloft, a grounded melee blow only grazes
## her (aloft_melee_taken); landed, every blow lands in full.
func taken_mult(e: Enemy, source: String) -> float:
	if not grounded_melee(source):
		return 1.0
	if phase == LANDED:
		e.game.stat_add("fallen_angel_landed_hits", 1.0)
		return 1.0
	e.game.stat_add("fallen_angel_grazed", 1.0)
	return float(d.get("aloft_melee_taken", 0.35))


## True when damage source `source` is a grounded melee summon's own blow: a
## summon class (or its evolution, or a warrior's bash) whose UnitData
## attack_profile is "melee" and whose behavior is not the gargoyle's "swoop".
## The gargoyles, the ranged and caster classes, the classes' specials, the
## spells and the hazards are not.
static func grounded_melee(source: String) -> bool:
	if _melee_cache.has(source):
		return bool(_melee_cache[source])
	var cls := source
	if cls == "bash":
		cls = "warrior"
	elif cls.ends_with("_bash"):
		cls = cls.trim_suffix("_bash")
	if SummonEvolutionData.EVOLUTIONS.has(cls):
		var bases: Array = (SummonEvolutionData.EVOLUTIONS[cls] as Dictionary).get("bases", [])
		cls = String(bases[0]) if not bases.is_empty() else cls
	var row: Dictionary = UnitData.UNITS.get(cls, {})
	var res := not row.is_empty() and String(row.get("attack_profile", "")) == "melee" and String(row.get("behavior", "")) != "swoop"
	_melee_cache[source] = res
	return res


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the marked landing ring while she rises and dives.
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if phase != RISE and phase != FALL:
		return Vector2.ZERO
	var reach := float(d.get("dive_radius", 34.0)) + DANGER_REACH
	var off := p - _at
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.0


## While she rises, her shadow waits on the mark and a burning spear-line
## points down at it. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != RISE:
		return
	unmirror(e, ci)
	var to := _at - e.position  # The mark, from her centre (px).
	var k := clampf(phase_time / maxf(float(d.get("dive_rise", 0.8)), 0.01), 0.0, 1.0)
	ci.draw_line(Vector2.ZERO, to, Color(Palette.INFERNO_LAVA, 0.2 + 0.4 * k), 1.0)
	var s := 6.0 + 6.0 * k  # Shadow half-width (px).
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(to - Vector2(s, s * 0.5), Vector2(s * 2.0, s)), false, Color(0.0, 0.0, 0.0, 0.25 + 0.3 * k))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
