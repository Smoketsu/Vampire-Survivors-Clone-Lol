## ArchfiendBehavior — the Archfiend's HELLFIRE CLEAVE ("hellfire", UnitData
## "archfiend"; Act VI, Pandemonium's finale reward; GDD §15.0 "The Archfiend,
## the Prince of Hell and Crown of Horns"; owner-approved proposal: "the
## finale's Archfiend (a winged heavy demon; evolution Prince of Hell)"). The
## Archfiend itself is an ordinary melee "guard" summon and a physical blocker
## (block_radius / block_mass, like the Abomination) on the Bone Ring's front
## posts. On top of its blade blows:
##   1. think(): when the cleave is ready and its target (or any foe) stands
##      within cleave_trigger px of it (edge to edge), it spreads its wings and
##      raises the cleaver (CASTING): a sector of cleave_radius px and
##      cleave_arc degrees each side is marked toward the foe for
##      cleave_windup s;
##   2. the sweep: every foe in the sector takes cleave_damage (source
##      "archfiend_cleave", a minion special) and is knocked back
##      cleave_knockback (px/s, divided by its mass); evolved into the PRINCE OF
##      HELL (SummonEvolutionData "prince_of_hell", special_set cleave_arc 180:
##      the sweep is a full circle; dread_cut / dread_duration), every foe it
##      strikes is also cowed: its blows deal dread_cut less for dread_duration
##      s through the one debuff path, CombatResolver.weaken_enemy() (bosses
##      and minibosses DREAD_BOSS of it);
##   3. it stands for cleave_recover s, then rejoins the shared FSM.
## Works the same on every stage (owner rule: summons never get act-only rules).
## Its paired passive Crown of Horns (CROWN) is read by
## HordeDirector._special_stats() (every class special hits harder).
## Determinism: no RNG (the first foe in reach in the spatial hash's order).
## Stats: archfiend_cleaves, archfiend_cleave_hits, prince_dreads; damage as
## dmg_archfiend_cleave.
class_name ArchfiendBehavior
extends SummonBehavior

## Phase: the cleaver is raised (the sector marked).
const WINDUP: int = 1
## Phase: the sweep landed; a short recovery.
const RECOVER: int = 2
## Damage source tag of the cleave (a minion special, PassiveData).
const CLEAVE_SOURCE: String = "archfiend_cleave"
## Share of the Prince's dread a boss or a miniboss suffers.
const DREAD_BOSS: float = 0.5  # TUNING (not in GDD)
## Passive id of Crown of Horns (PassiveData, UnlockData; read by
## HordeDirector._special_stats()).
const CROWN: String = "crown_of_horns"
## Its level-row key: extra share (0..1) of every class special's damage.
const CROWN_KEY: String = "special_damage"

## Unit direction of the raised cleave (locked at the windup).
var _dir: Vector2 = Vector2.RIGHT
## Reusable enemy query buffer.
var _buf: Array = []


## Full cleave cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("cleave_cooldown", 6.0))


## Raises the cleaver when a foe is in reach.
func think(u: SummonedUnit) -> bool:
	if is_busy() or special_cd > 0.0:
		return false
	var reach := float(u.special["cleave_trigger"]) + u.radius
	var foe: Enemy = u.target if u.target_alive() else null
	if foe == null or foe.position.distance_to(u.position) > reach + foe.radius:
		foe = null
		u.game.enemy_grid.query(u.position, reach + ProjectileManager.MAX_BODY_RADIUS, _buf)
		for e: Enemy in _buf:
			if e.active and not e.untargetable and e.position.distance_to(u.position) <= reach + e.radius:
				foe = e
				break
	if foe == null:
		return false
	var to := foe.position - u.position
	_dir = to.normalized() if to.length() > 0.5 else Vector2.RIGHT
	begin_special(u, WINDUP)
	return true


## Windup -> sweep -> recovery.
func step_special(u: SummonedUnit, _delta: float) -> bool:
	u.velocity = Vector2.ZERO
	match phase:
		WINDUP:
			if phase_time >= float(u.special["cleave_windup"]):
				_sweep(u)
				next_phase(RECOVER)
		RECOVER:
			if phase_time >= float(u.special["cleave_recover"]):
				end_special(u, SummonedUnit.State.ENGAGING if u.target_alive() else SummonedUnit.State.FOLLOWING)
	return true


## The sweep: damage and knockback to every foe in the sector (and the
## Prince's dread).
func _sweep(u: SummonedUnit) -> void:
	var game := u.game
	var r := float(u.special["cleave_radius"])
	var half := deg_to_rad(float(u.special["cleave_arc"]))
	var dmg := float(u.special["cleave_damage"])
	var kb := float(u.special.get("cleave_knockback", 0.0))
	var cut := float(u.special.get("dread_cut", 0.0))  # The Prince's dread (0 for the Archfiend).
	var dread := float(u.special.get("dread_duration", 0.0))
	u.motion_lunge(_dir, MotionData.POWER_MELEE)
	var hits: Array = []  # Own buffer: a kill may query the grid again.
	game.enemy_grid.query(u.position, r + ProjectileManager.MAX_BODY_RADIUS, hits)
	var n := 0
	var dreads := 0
	for e: Enemy in hits:
		if not e.active or e.untargetable:
			continue
		if not CovenantKit.in_sector(u.position, _dir, r, half, u.radius, e.position, e.radius):
			continue
		n += 1
		if cut > 0.0 and game.combat.weaken_enemy(e, 0.0, cut, dread, DREAD_BOSS, false):
			dreads += 1
		var away := e.position - u.position
		if kb > 0.0 and not e.is_boss:
			e.knockback += (away / away.length() if away.length() > 0.01 else _dir) * kb / maxf(e.mass, 0.1)
		game.combat.damage_enemy(e, dmg, CLEAVE_SOURCE, u.director.slot, u.position)
	game.effects.slash(u.position + _dir * r * 0.5, _dir, Palette.NECRO_GREEN if cut <= 0.0 else Palette.VIOLET, r)
	if half >= PI - 0.01:
		game.effects.art_ring(u.position, r, Palette.NECRO_GREEN, 0.35, "stomp")  # The Prince's full circle.
	game.shake(2.0)
	Sfx.play("abom_stomp", u.position, 1.15)  # A startup-bank sound: the class plays on every stage.
	game.volleys.on_special(u, u.position, u.position + _dir, dmg)  # Bullet heaven: hellfire embers.
	game.stat_add("archfiend_cleaves", 1.0)
	game.stat_add("archfiend_cleave_hits", float(n))
	if dreads > 0:
		game.stat_add("prince_dreads", float(dreads))


## Telegraph: the sector the cleaver will sweep, filling in. Visual only.
func draw_under(u: SummonedUnit) -> void:
	if phase != WINDUP:
		return
	var r := float(u.special["cleave_radius"])
	var half := deg_to_rad(float(u.special["cleave_arc"]))
	var k := clampf(phase_time / maxf(float(u.special["cleave_windup"]), 0.01), 0.0, 1.0)  # Windup progress.
	var d := _dir * Vector2(u.scale.x, 1.0)  # The sweep's direction in the unit's (mirrored) frame.
	if half >= PI - 0.01:
		u.draw_texture_rect(SpriteBank.disc(), Rect2(-Vector2(r, r), Vector2(r, r) * 2.0), false, Color(Palette.NECRO_GREEN, 0.10 + 0.15 * k))
		return
	var c := d * r * 0.55  # The marked sector, drawn as a soft disc toward the foe (a texture, not a polygon: the Web GL rule).
	var w := r * 0.6
	u.draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(w, w), Vector2(w, w) * 2.0), false, Color(Palette.NECRO_GREEN, 0.10 + 0.15 * k))
