## LilimWitchKit — the kit of the Lilim Witch (SilkPalaceEnemyData "lilim_witch";
## Act VI, the Palace of Silk and Ash; GDD §15.0 "The Palace of Silk and Ash (Act
## VI phase 2)"; owner-approved proposal: "Lilim Witch | Support (figure style) |
## Opens small pits under the ring; heals demons near a portal | Kill first").
## A white-haired demon sorceress (female, the approved Act VI figure style), a
## DEMON (the pits spare her). She walks at the necromancer with the shared
## melee AI (enemies always advance) and has two rites:
##   * THE PIT CURSE: when it is ready and the necromancer is within pit_trigger
##     px, she raises her eye-staff for pit_windup s (a pink-orange glow in it),
##     then opens pit_count small Hell Pits UNDER THE BONE RING through the one
##     pit path (HellPits.open_pit(), tag SilkPalaceEnemyData.LILIM_PIT_TAG):
##     the first on the ring summon nearest her (within RING_REACH px of the
##     necromancer), else on the ring toward her; the next pit_spread px to its
##     side. Each glows pit_telegraph s (the shared rim the ring flows around),
##     then burns pit_life s. Off Act VI (a forced kind) the pits do not burn
##     (HellPits steps only on an Inferno stage).
##   * THE PORTAL RITE: every rite_every s, while a standing demon portal
##     (DemonPortals) is within portal_reach px of her, every DEMON within
##     rite_radius px of that portal heals rite_amount x the enemies' HP scaling
##     through CombatResolver.heal_enemy() (healer = her, so a Keening Lady's
##     silence stops it); a pink thread links her to the portal while it runs.
## Determinism: no RNG; ties in the spatial hash's fixed order. Stats:
## lilim_curses, lilim_pits, lilim_rites, lilim_healed.
class_name LilimWitchKit
extends InfernoKit

## Phase: the staff is raised (the curse's windup).
const CURSE: int = 1
## px from the necromancer within which a summon counts as "on the ring".
const RING_REACH: float = 150.0  # TUNING (not in GDD) the Bone Ring's outer posts
## px from the necromancer of the fallback pit (no summon on the ring).
const FALLBACK_DIST: float = 80.0  # TUNING (not in GDD) on the ring's middle
## s the pink thread to a healed portal stays drawn (visual only).
const THREAD_TIME: float = 0.6  # TUNING (not in GDD) visual

## Seconds until the next curse may start.
var _cd: float = 0.0
## Seconds until the next portal rite.
var _heal_cd: float = 0.0
## World px of the portal her last rite fed (drawing only).
var _thread_to: Vector2 = Vector2.ZERO
## Game time (s) her last rite ran (drawing only).
var _thread_at: float = -INF
## Summons on the ring (scratch).
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("pit_every", 9.0)) * 0.5)
	_heal_cd = first_cd(e, float(def.get("rite_every", 3.0)))
	_thread_at = -INF


func physics(e: Enemy, delta: float) -> bool:
	_cd -= delta
	_heal_cd -= delta
	if _heal_cd <= 0.0:
		_heal_cd = float(d["rite_every"])
		_rite(e)
	if phase == CURSE:
		phase_time += delta
		hold(e)
		if phase_time >= float(d["pit_windup"]):
			_curse(e)
			set_phase(e, IDLE)
		return true
	if _cd > 0.0:
		return false
	if e.position.distance_to(e.game.player.position) > float(d["pit_trigger"]):
		return false
	_cd = float(d["pit_every"])
	set_phase(e, CURSE)
	hold(e)
	return true


## The curse lands: pit_count small pits under the ring (see the header).
func _curse(e: Enemy) -> void:
	var g := e.game
	var p := g.player.position
	var toward := (e.position - p).normalized() if e.position.distance_squared_to(p) > 1.0 else Vector2.RIGHT
	var at := p + toward * FALLBACK_DIST
	g.ally_grid.query(p, RING_REACH, _tmp)
	var best := INF
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.charmed or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(p) > RING_REACH:
			continue
		var dist := u.position.distance_to(e.position)  # The ring summon nearest her.
		if dist < best:
			best = dist
			at = u.position
	var side := toward.orthogonal()
	var n := maxi(1, int(d["pit_count"]))
	var opened := 0
	for i in n:
		var off := (float(i) - float(n - 1) * 0.5) * float(d["pit_spread"])  # Spread across the ring.
		if rules(e).pits.open_pit(at + side * off, float(d["pit_radius"]), float(d["pit_life"]),
				{"telegraph": float(d["pit_telegraph"]), "tag": SilkPalaceEnemyData.LILIM_PIT_TAG, "silent": i > 0}):
			opened += 1
	g.stat_add("lilim_curses", 1.0)
	g.stat_add("lilim_pits", float(opened))
	e.motion_lunge(toward * -1.0, MotionData.POWER_CAST)


## The portal rite: heals the demons around the nearest standing portal in reach.
func _rite(e: Enemy) -> void:
	var g := e.game
	var inf := rules(e)
	var portal: Enemy = null
	var best := float(d["portal_reach"])
	for pt in inf.portals.portals:
		if not pt.enemy.active or pt.enemy.generation != pt.gen:
			continue
		var dist := e.position.distance_to(pt.enemy.position)
		if dist <= best:
			best = dist
			portal = pt.enemy
	if portal == null:
		return
	var amount := float(d["rite_amount"]) * g.enemies.hp_mult
	var r := float(d["rite_radius"])
	g.enemy_grid.query(portal.position, r, _tmp)
	var healed := 0.0
	for o: Enemy in _tmp:
		if not o.active or o.is_structure or o.position.distance_to(portal.position) > r:
			continue
		if not (o.kit is InfernoKit and (o.kit as InfernoKit).is_demon()):
			continue
		healed += g.combat.heal_enemy(o, amount, e)
	g.stat_add("lilim_rites", 1.0)
	g.stat_add("lilim_healed", healed)
	_thread_to = portal.position
	_thread_at = g.elapsed
	e.queue_redraw()


func is_busy() -> bool:
	return phase == CURSE


## Her raised staff's glow while she curses, and the pink thread to the portal
## she feeds. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var g := e.game
	var thread := g.elapsed - _thread_at < THREAD_TIME
	if phase != CURSE and not thread:
		return
	unmirror(e, ci)
	if phase == CURSE:
		var k := clampf(phase_time / maxf(0.01, float(d["pit_windup"])), 0.0, 1.0)
		SpriteBank.draw_disc(ci, Vector2(e.radius * 1.1, -e.radius * 2.4), 2.5 + 3.0 * k, Color(Palette.INFERNO_LAVA_LIGHT, 0.5 + 0.4 * k))
		SpriteBank.draw_disc(ci, Vector2(e.radius * 1.1, -e.radius * 2.4), 1.5 + 1.5 * k, Color(Palette.INFERNO_CHARM, 0.9))
	if thread:
		var a := 1.0 - (g.elapsed - _thread_at) / THREAD_TIME
		ci.draw_line(Vector2(0, -e.radius), _thread_to - e.position, Color(Palette.INFERNO_CHARM, 0.6 * a), 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
