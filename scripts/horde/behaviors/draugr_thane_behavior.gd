## DraugrThaneBehavior — the Draugr Thane's FROST-AXE ("frost_axe", UnitData
## "draugr_thane"; Vigrid, the Hall of the Slain's finale reward; GDD §15.0
## "The Draugr Thane, the Barrow King and Cold Iron"; owner-approved proposal:
## "the finale summon class the Draugr Thane: a heavy undead jarl, a blocker
## whose frost-axe slows what it hits (evolution Barrow King)"). The thane is
## an ordinary melee "guard" summon and a physical blocker (block_radius /
## block_mass, like the Abomination). On top of its axe blows:
##   1. EVERY BLOW CHILLS: a foe its axe strikes is slowed axe_slow for
##      axe_slow_duration s (CombatResolver.chill_enemy(), the Frost Wraith's one
##      chill path: Spirit Binding and Mournsong lengthen it; a berserk Norse
##      warrior shrugs it off as every slow);
##   2. THE FROST CLEAVE (think(): when ready and a foe stands within
##      cleave_trigger px, edge to edge): it raises the axe (CASTING) for
##      cleave_windup s, a sector of cleave_radius px telegraphed before it,
##      then sweeps it: every foe in the sector takes cleave_damage (source
##      "thane_cleave", a minion special) and is chilled cleave_slow for
##      cleave_slow_duration s; evolved into the BARROW KING (SummonEvolutionData
##      "barrow_king", special_set cleave_freeze_duration), the sweep also FREEZES what
##      it strikes for cleave_freeze_duration s (CombatResolver.freeze_enemy(): bosses
##      and minibosses FREEZE_BOSS of it, elites FREEZE_ELITE) and is tagged
##      "barrow_king_cleave";
##   3. it stands still for cleave_recover s, then rejoins the shared FSM.
## Works the same on every stage (owner rule: summons never get act-only
## rules). Its paired passive Cold Iron (COLD_IRON) is read by
## CombatResolver.damage_enemy() (every summon blow on a slowed foe hits
## harder). Stats: draugr_thane_chills, draugr_thane_cleaves,
## draugr_thane_cleave_hits, barrow_king_freezes; damage as dmg_draugr_thane /
## dmg_barrow_king / dmg_thane_cleave / dmg_barrow_king_cleave.
class_name DraugrThaneBehavior
extends SummonBehavior

## Phase: the axe is raised (the sector telegraphed).
const WINDUP: int = 1
## Phase: the sweep landed; a short recovery.
const RECOVER: int = 2
## Class id (UnitData, UnlockData, MasteryData).
const CLASS_ID: String = "draugr_thane"
## Damage source tag of the thane's frost cleave (a minion special, PassiveData).
const CLEAVE_SOURCE: String = "thane_cleave"
## Damage source tag of the Barrow King's cleave (a minion special, PassiveData).
const EVOLVED_CLEAVE_SOURCE: String = "barrow_king_cleave"
## Half-angle (rad) of the cleave's sector.
const CLEAVE_HALF_ANGLE: float = 1.05  # TUNING (not in GDD) about 120 degrees in all
## Share of the freeze a boss or a miniboss suffers.
const FREEZE_BOSS: float = 0.25  # TUNING (not in GDD)
## Share of the freeze an elite suffers.
const FREEZE_ELITE: float = 0.5  # TUNING (not in GDD)
## Passive id of Cold Iron (PassiveData, UnlockData; read by
## CombatResolver.damage_enemy()).
const COLD_IRON: String = "cold_iron"
## Cold Iron's level key: + share of summon damage to a slowed foe.
const COLD_IRON_KEY: String = "iron_damage"
## The frost's colour (telegraph and burst; drawing only).
const FROST: Color = Color(0.72, 0.88, 1.0)  # TUNING (not in GDD) visual only

## The cleave's direction (unit vector; locked at the windup).
var _dir: Vector2 = Vector2.RIGHT
## Reusable enemy query buffer.
var _buf: Array = []


## Full cleave cooldown (s).
func cooldown(u: SummonedUnit) -> float:
	return float(u.special.get("cleave_cooldown", 6.0))


## Every axe blow chills what it strikes.
func on_melee_hit(u: SummonedUnit, e: Enemy, _dealt: float) -> void:
	if e == null or not e.active or e.is_structure:
		return
	u.game.combat.chill_enemy(e, float(u.special["axe_slow"]), float(u.special["axe_slow_duration"]))
	u.game.stat_add("draugr_thane_chills", 1.0)


## Raises the axe when a foe is in reach.
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


## The sweep: damage and a chill to every foe in the sector (and the Barrow
## King's freeze).
func _sweep(u: SummonedUnit) -> void:
	var game := u.game
	var r := float(u.special["cleave_radius"])
	var dmg := float(u.special["cleave_damage"])
	var freeze := float(u.special.get("cleave_freeze_duration", 0.0))  # The Barrow King's (0 for the thane).
	var src := EVOLVED_CLEAVE_SOURCE if freeze > 0.0 else CLEAVE_SOURCE
	u.motion_lunge(_dir, MotionData.POWER_MELEE)
	var hits: Array = []  # Own buffer: a kill may query the grid again.
	game.enemy_grid.query(u.position, r + ProjectileManager.MAX_BODY_RADIUS, hits)
	var n := 0
	for e: Enemy in hits:
		if not e.active or e.untargetable:
			continue
		if not CovenantKit.in_sector(u.position, _dir, r, CLEAVE_HALF_ANGLE, u.radius, e.position, e.radius):
			continue
		game.combat.chill_enemy(e, float(u.special["cleave_slow"]), float(u.special["cleave_slow_duration"]))
		if freeze > 0.0 and game.combat.freeze_enemy(e, freeze, FREEZE_BOSS, FREEZE_ELITE) > 0.0:
			game.stat_add("barrow_king_freezes", 1.0)
		game.combat.damage_enemy(e, dmg, src, u.director.slot, u.position)
		n += 1
	game.effects.slash(u.position + _dir * r * 0.5, _dir, FROST, r * 1.2)
	Juice.fx.burst(u.position + _dir * r * 0.6, FROST, Palette.BONE, 8, r * 1.6, 0.4, 2.5)
	Sfx.play("warrior_bash", u.position, 0.8)  # A startup-bank sound: the class plays on every stage.
	game.volleys.on_special(u, u.position, u.position + _dir * r, dmg)  # Bullet heaven: frost shards.
	game.stat_add("draugr_thane_cleaves", 1.0)
	game.stat_add("draugr_thane_cleave_hits", float(n))


## Telegraph: the sector the axe will sweep, filling in. Textures only; visual only.
func draw_under(u: SummonedUnit) -> void:
	if phase != WINDUP:
		return
	var r := float(u.special["cleave_radius"])
	var k := clampf(phase_time / maxf(float(u.special["cleave_windup"]), 0.01), 0.0, 1.0)  # Windup progress.
	var dir := _dir * Vector2(u.scale.x, 1.0)  # In the unit's (mirrored) frame.
	for i in 3:
		var a := dir.angle() + (float(i) - 1.0) * CLEAVE_HALF_ANGLE * 0.6
		var c := Vector2.from_angle(a) * r * 0.6
		u.draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(r, r) * 0.45, Vector2(r, r) * 0.9), false, Color(FROST, 0.08 + 0.14 * k))
