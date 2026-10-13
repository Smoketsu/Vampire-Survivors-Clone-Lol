## UnitDissolve: one pooled death dissolve (GDD §15.0 "Art pass", engine
## motion tier 0). A dying unit returns to its pool at once, so this node
## takes a snapshot of its look (what it is, its size, facing and pivot) and
## draws that look in its own body layer, collapsing it about the feet
## (squash down, widen, fade toward bone dust or holy ash) over
## MotionData.DISSOLVE_TIME while dust motes rise (FxLayer.dust()).
## Pooled by MotionDirector; it holds no reference to the dead unit, so a
## recycled unit can never be affected. Purely visual, no RNG.
class_name UnitDissolve
extends Node2D

## What the snapshot draws.
enum Look { ENEMY, SUMMON }

## True while playing (false = sitting in the pool).
var active: bool = false
## Seconds since the dissolve started (game time).
var t: float = 0.0
## Which glyph family draws the look.
var look: Look = Look.ENEMY
## Enemy kind or summon glyph kind drawn.
var key: String = ""
## Body radius of the dead unit (px; the glyph size).
var radius: float = 10.0
## Elite flag of a dead enemy (its gold ring).
var elite: bool = false
## Height the body was drawn above its origin (px; a floating Banshee).
var lift: float = 0.0
## Pivot: the feet line (local px) the body collapses onto.
var feet: float = 0.0
## Colour the body fades toward (MotionData.BONE_FADE_TINT / ASH_FADE_TINT).
var fade_tint: Color = Color.WHITE
## Layer that draws the snapshot (it is the part that collapses).
var body: UnitLayer


func _ready() -> void:
	body = UnitLayer.new()
	body.draw_fn = _draw_look
	add_child(body)


## Starts the dissolve at `pos` facing `facing` (+1 / -1) for the look
## described by the arguments (see the member comments).
func start(pos: Vector2, facing: float, p_look: Look, p_key: String, p_radius: float, p_elite: bool, p_lift: float, p_feet: float, undead: bool) -> void:
	position = pos
	scale = Vector2(facing, 1.0)
	look = p_look
	key = p_key
	radius = p_radius
	elite = p_elite
	lift = p_lift
	feet = p_feet
	fade_tint = MotionData.BONE_FADE_TINT if undead else MotionData.ASH_FADE_TINT
	t = 0.0
	active = true
	visible = true
	body.transform = Transform2D.IDENTITY
	body.modulate = Color.WHITE
	body.queue_redraw()


## Advances by `dt` game seconds; returns false once finished (hidden).
func advance(dt: float) -> bool:
	t += dt
	var u := t / MotionData.DISSOLVE_TIME  # Progress 0..1.
	if u >= 1.0:
		active = false
		visible = false
		return false
	var e := u * u  # Ease in: slow start, then the body gives way.
	var sy := 1.0 - MotionData.DISSOLVE_SQUASH * e  # Height left.
	var sx := 1.0 + MotionData.DISSOLVE_WIDEN * u  # Width gained.
	body.transform = Transform2D(Vector2(sx, 0.0), Vector2(0.0, sy), Vector2(0.0, feet * (1.0 - sy)))
	var c := Color.WHITE.lerp(fade_tint, minf(1.0, u * 2.0))  # Drained toward dust.
	c.a = 1.0 - e
	body.modulate = c
	return true


## Draws the snapshot look on the body layer `ci` (never flashing).
func _draw_look(ci: CanvasItem) -> void:
	if look == Look.ENEMY:
		Glyphs.draw_enemy(ci, key, Vector2.ZERO, radius, false, elite)
	else:
		Glyphs.draw_summon(ci, key, Vector2(0.0, -lift), radius, false)
