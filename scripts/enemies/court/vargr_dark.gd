## VargrDark — the darkness of the Moon-Eater, Vargr's third phase (Act VII,
## Ravensmoor; GDD §15.0 "Vargr, the Moon-Eater (Act VII)"; owner-approved
## proposal: "he swallows the moon: the arena goes dark except a red circle
## around him"). Created by BossVargr when he swallows the moon (never
## headless), freed when he falls. Visual only: it changes nothing in the run.
## Drawn over the world (under the HUD) as ONE made texture, a black square
## with a soft hole and a blood-red rim in its middle, stretched over a circle
## of `radius` px around him, plus four black rects filling the rest of the
## view: no shader reads the screen and no polygon is redrawn every frame (the
## Web rules in CLAUDE.md). The darkness fades in over FADE s.
class_name VargrDark
extends Node2D

## Side (px) of the made hole texture.
const TEX_SIZE: int = 96
## Seconds the darkness takes to fall.
const FADE: float = 1.5  # TUNING (not in GDD) drawn only
## The hole texture (made on first use; shared by every run).
static var _hole: Texture2D = null

## The boss the circle follows (its generation guards a pooled reuse).
var boss: Enemy = null
## Radius (px) of the red circle of light.
var radius: float = 180.0
## Darkness outside the circle at full strength (0..1).
var alpha: float = 0.82
## Game time (s) the darkness began.
var _since: float = 0.0
## Owning run.
var _game: Game = null


## Builds the darkness for `game` around `p_boss` (`r` px of light, `a` the
## darkness's strength). The caller adds it to the world.
func _init(game: Game, p_boss: Enemy, r: float, a: float) -> void:
	_game = game
	boss = p_boss
	radius = r
	alpha = a
	_since = game.elapsed
	name = "VargrDark"
	z_index = 19  # Over the bodies, the threads and the moon's wash; under the HUD.
	z_as_relative = false


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if boss == null or not boss.active:
		return
	var k := clampf((_game.elapsed - _since) / FADE, 0.0, 1.0)  # The darkness falling.
	var col := Color(1.0, 1.0, 1.0, alpha * k)
	var c := boss.position
	var hole := Rect2(c - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
	draw_texture_rect(_texture(), hole, false, col)
	var v := _view().grow(64.0)
	var dark := Color(0.0, 0.0, 0.0, alpha * k)
	draw_rect(Rect2(v.position, Vector2(v.size.x, maxf(0.0, hole.position.y - v.position.y))), dark)  # Above.
	draw_rect(Rect2(Vector2(v.position.x, hole.end.y), Vector2(v.size.x, maxf(0.0, v.end.y - hole.end.y))), dark)  # Below.
	draw_rect(Rect2(Vector2(v.position.x, hole.position.y), Vector2(maxf(0.0, hole.position.x - v.position.x), hole.size.y)), dark)  # Left.
	draw_rect(Rect2(Vector2(hole.end.x, hole.position.y), Vector2(maxf(0.0, v.end.x - hole.end.x), hole.size.y)), dark)  # Right.


## The visible world rect around the camera.
func _view() -> Rect2:
	var cam := _game.camera
	var zoom := cam.zoom if cam != null else Vector2.ONE
	var sz := get_viewport_rect().size / zoom  # World px on screen.
	var c := cam.get_screen_center_position() if cam != null else _game.player.position
	return Rect2(c - sz * 0.5, sz)


## The hole texture: clear in the middle, a blood-red rim, black at the edge.
static func _texture() -> Texture2D:
	if _hole != null:
		return _hole
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var half := float(TEX_SIZE) * 0.5
	var rim := Palette.COURT_BLOOD
	for y in TEX_SIZE:
		for x in TEX_SIZE:
			var d := Vector2(float(x) + 0.5 - half, float(y) + 0.5 - half).length() / half  # 0 centre .. 1 edge.
			var a := smoothstep(0.72, 0.98, d)  # Darkness.
			var r := clampf(1.0 - absf(d - 0.8) / 0.12, 0.0, 1.0) * 0.55  # The red rim.
			var c := Color(0.0, 0.0, 0.0, a).lerp(Color(rim, maxf(a, r)), r)
			img.set_pixel(x, y, c if d < 1.0 else Color(0.0, 0.0, 0.0, 1.0))
	_hole = ImageTexture.create_from_image(img)
	return _hole
