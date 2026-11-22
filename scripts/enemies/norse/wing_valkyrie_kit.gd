## WingValkyrieKit — the kit of SIGRUN'S VALKYRIE WING (ValgardEnemyData
## "wing_valkyrie"; Valgard, the Hall of Heroes, the Hall of the Slain
## temporarily Act XI; GDD §15.0 "Sigrun, the Shield-Queen (the Hall of the
## Slain)"; owner-approved proposal: "the Charge (spear dives across the ring on
## telegraphed lines with her valkyrie wing)"). A FEMALE flying elite in the
## figure style, drawn with the shared valkyrie's art (norse/valkyrie, its glide
## and idle strips). Everything the shared valkyrie does (NorseValkyrieKit: the
## Night Wings flight, her own spear dive on a telegraph circle, Ragnarök's
## forced dive), plus THE CHARGE: when Sigrun calls it (charge()), she marks a
## LANE from where she hovers across the ring through `through` and
## `overshoot` px past it (EffectManager.telegraph_line(), which the autotest bot
## steps out of) for `windup` s, then dives along it in `time` s: every
## necromancer and summon the lane crosses is struck once (lane(), the one
## charge hit, shared with Sigrun) and the summons are thrown aside; then she
## stands LANDED for her row's landed_time (every blow lands).
## No RNG. Stats: wing_charges, sigrun_charge_hits (with Sigrun's).
class_name WingValkyrieKit
extends NorseValkyrieKit

## Phase: the charge lane shows; she hovers at its start.
const CHARGE_WIND: int = 4
## Phase: the dive along the lane.
const CHARGE_RUN: int = 5

## Where the charge lane starts (world px).
var _c_from: Vector2 = Vector2.ZERO
## Unit direction of the charge lane.
var _c_dir: Vector2 = Vector2.RIGHT
## Length of the charge lane (px).
var _c_len: float = 0.0
## The charge's numbers, handed by Sigrun (SigrunData keys: windup, time,
## width, damage_player, damage_summon, push), already scaled.
var _c: Dictionary = {}
## Bodies this charge already struck (OlympusHits.lane()).
var _c_struck: Dictionary = {}
## Reusable query buffer.
var _c_tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_c_struck.clear()


## SIGRUN'S CHARGE for this valkyrie: a lane from where she hovers through
## world point `through`, `overshoot` px past it; `cfg` holds windup / time
## (s), width (px), damage_player / damage_summon (already scaled), push (px).
## Ignored while she dives on her own or stands landed.
func charge(e: Enemy, through: Vector2, overshoot: float, cfg: Dictionary) -> void:
	if phase != IDLE or not e.active:
		return
	var to := through - e.position
	if to.length() < 1.0:
		to = Vector2.RIGHT
	_c_from = e.position
	_c_dir = to.normalized()
	_c_len = to.length() + overshoot
	_c = cfg
	_c_struck.clear()
	e.game.effects.telegraph_line(_c_from, _c_from + _c_dir * _c_len, float(cfg["width"]), float(cfg["windup"]), e)
	e.game.stat_add("wing_charges", 1.0)
	set_phase(e, CHARGE_WIND)
	hold(e)


func physics(e: Enemy, delta: float) -> bool:
	match phase:
		CHARGE_WIND:
			phase_time += delta
			hold(e)
			if phase_time >= float(_c["windup"]):
				set_phase(e, CHARGE_RUN)
			return true
		CHARGE_RUN:
			phase_time += delta
			var k := clampf(phase_time / maxf(0.01, float(_c["time"])), 0.0, 1.0)  # 0 -> 1 along the lane.
			e.position = _c_from + _c_dir * _c_len * k
			e.velocity = Vector2.ZERO
			e.game.stat_add("sigrun_charge_hits", float(lane(e.game, _c_from, _c_dir, _c_len * k, float(_c["width"]),
					float(_c["damage_player"]), float(_c["damage_summon"]) * e.undead_damage_mult, SigrunData.CHARGE_SOURCE, e,
					float(_c["push"]), _c_struck, _c_tmp)))
			if k >= 1.0:
				set_phase(e, LANDED)
			return true
	return super.physics(e, delta)


## THE ONE CHARGE HIT (Sigrun's lanes and her wing's): every necromancer and
## summon inside the lane from `from` along unit `dir`, `length` px long and
## `width` px wide is struck once (OlympusHits.lane(); `struck` remembers who
## across the ticks of one charge), and each summon struck now is thrown `push`
## px aside, away from the lane's centre line (obstacle-clamped; airborne
## summons are not hit). Returns the summons struck by this call.
static func lane(g: Game, from: Vector2, dir: Vector2, length: float, width: float, dmg_player: float, dmg_summon: float,
		source: String, by: Enemy, push: float, struck: Dictionary, tmp: Array) -> int:
	var before := struck.size()
	var hits := OlympusHits.lane(g, from, dir, length, width, dmg_player, dmg_summon, source, by, struck, tmp)
	if push > 0.0 and struck.size() > before:
		var keys := struck.keys()
		var side := dir.orthogonal()
		for i in range(before, keys.size()):
			var u := keys[i] as SummonedUnit
			if u == null or not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
				continue
			var s := side if (u.position - from).dot(side) >= 0.0 else -side
			u.position += s * g.arena.clear_length(u.position, s, push, u.radius)
	return hits


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: off the charge lane while it shows and while she dives
## (the shared dive's circle otherwise).
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != CHARGE_WIND and phase != CHARGE_RUN:
		return super.danger_push(e, p)
	return lane_push(_c_from, _c_dir, _c_len, float(_c["width"]), p)


## The autotest push out of a lane from `from` along unit `dir`, `length` px
## long and `width` px wide at point `p` (zero outside it, with a margin).
static func lane_push(from: Vector2, dir: Vector2, length: float, width: float, p: Vector2) -> Vector2:
	var rel := p - from
	var along := rel.dot(dir)
	if along < -20.0 or along > length + 20.0:
		return Vector2.ZERO
	var side := dir.orthogonal()
	var off := rel.dot(side)
	var reach := width * 0.5 + 30.0  # The lane's half width plus a step.
	if absf(off) >= reach:
		return Vector2.ZERO
	return (side if off >= 0.0 else -side) * (1.0 - absf(off) / reach) * 2.5


## Her body: the shared valkyrie's art (glide and idle strips through the body
## layer); the shared fallback glyph without it.
func draws_body(_e: Enemy) -> bool:
	return true


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	if not SpriteBank.draw(ci, ValgardEnemyData.WING_SPRITE, Vector2.ZERO, e.flash > 0.0):
		Glyphs.draw_enemy(ci, NorseEnemyData.VALKYRIE, Vector2.ZERO, e.radius, e.flash > 0.0, e.is_elite)
