## CharmedKit — the kit of a charmed summon's hostile body (InfernoEnemyData
## "charmed"; Act VI, GDD §15.0 "Temptation"). Temptation spawns the body when
## HordeDirector.charm() takes hold: it wears the summon's art tinted charm
## pink (Enemy.wears, the Claims pattern) and fights for hell through the shared
## melee AI. This kit only reports its death to Temptation (on_killed(): the
## summon is freed, weakened) and draws the pink hearts rising over it; Temptation decides
## when it leaves (the charm's end, the charmer's death). Not a demon: the
## pits burn it like the summon it is. No RNG; the hearts run on game time.
class_name CharmedKit
extends InfernoKit

## Game time (s) the charm ends (set by Temptation; the hearts thin out near it).
var charm_ends: float = 0.0
## Last heart frame drawn (redraw only when it changes).
var _frame: int = -1


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	charm_ends = 0.0
	_frame = -1


## Broken by the army or the necromancer: its summon is freed (Temptation).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if e.game != null and e.game.inferno != null:
		e.game.inferno.temptation.on_body_killed(e)


## Redraws when the hearts move (about 12 times a second).
func physics(e: Enemy, _delta: float) -> bool:
	var f := int(e.game.elapsed * 12.0)
	if f != _frame:
		_frame = f
		e.queue_redraw()
	return false


## Pink hearts rising over the charmed summon. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	unmirror(e, ci)
	var top := e.marker_y(-e.radius * 2.0)  # Over its head (px).
	var every := float(InfernoRulesData.TEMPTATION["heart_every"])
	for i in 3:
		var k := fmod(e.game.elapsed / (every * 3.0) + float(i) / 3.0, 1.0)  # 0 rising .. 1 gone.
		var x := sin((k + float(i)) * TAU) * e.radius * 0.5
		InfernoGlyphs.draw_heart(ci, Vector2(x, top - k * 16.0), 5.0, Color(Palette.INFERNO_CHARM_LIGHT if i == 0 else Palette.INFERNO_CHARM, 1.0 - k * 0.8))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
