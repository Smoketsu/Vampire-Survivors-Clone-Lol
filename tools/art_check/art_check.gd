## ArtCheck: renders one sprite at its real in-game size on every stage floor,
## for tools/art_check.py (the art pass check sheet, docs/art/ART_BIBLE.md).
## NOT part of the game: it lives in tools/art_check/, which Godot ignores
## (tools/.gdignore), so it is never imported or exported. art_check.py copies
## the project to a scratch folder, puts this folder at res://_art_check/ there
## and runs this scene under xvfb with the OpenGL renderer:
##   godot --path <copy> res://_art_check/art_check.tscn -- --key=<sprite key> --out=<dir>
## For each of the 9 floors (the Graveyard, the 4 Crimson March zones, the 4
## Sanctum zones, drawn by the game's own Ground / MarchGround / SanctumGround)
## and each zoom (Normal x1, Close x1.5) it renders one SubViewport with the
## sprite under test (SpriteBank.draw, nearest filtering) next to the
## necromancer, a Skeleton Warrior and a Covenant Recruit (drawn by the game's
## Glyphs functions: their current art or glyph), then saves each panel to
## <out>/panel_<floor>_<zoom>.png and quits. Purely visual, never in a run.
extends Node

## Camera zooms rendered: label -> Camera2D zoom (GDD 15.0: Normal x1, Close x1.5).
const ZOOMS: Dictionary = {"x1": 1.0, "x1.5": 1.5}
## Gap between two units in a panel (world px).
const UNIT_GAP: float = 18.0
## Empty world px kept around the row of units (left / right and above).
const MARGIN: float = 22.0
## World px of floor kept under the feet (the shadow and a strip of ground).
const FOOT_ROOM: float = 14.0
## World position the panels look at: off the March road (y = 0, half width 70),
## so the units stand on the zone's soil with the road edge in view below at x1.
const FOCUS: Vector2 = Vector2(260.0, -140.0)
## Frames to wait before capturing (the ground redraws on its first frame).
const SETTLE_FRAMES: int = 4

## Sprite key under test (e.g. "player/necromancer").
var _key: String = ""
## Output folder for the panel PNGs (absolute path).
var _out: String = ""
## Rendered panels: [{viewport, name}].
var _panels: Array = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--key="):
			_key = arg.substr(6)
		elif arg.begins_with("--out="):
			_out = arg.substr(6)
	if _key == "" or _out == "":
		push_error("art_check: pass -- --key=<sprite key> --out=<dir>")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	for floor_def in _floors():
		for zoom_label: String in ZOOMS:
			_build_panel(floor_def, zoom_label, float(ZOOMS[zoom_label]))
	for i in SETTLE_FRAMES:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	for p: Dictionary in _panels:
		var vp: SubViewport = p["viewport"]
		var img := vp.get_texture().get_image()
		img.save_png(_out.path_join("panel_%s.png" % p["name"]))
	print("art_check: %d panels -> %s" % [_panels.size(), _out])
	get_tree().quit(0)


## The 9 floors: id, label, ground script and zone look.
func _floors() -> Array:
	var out: Array = [{"id": "graveyard", "label": "Graveyard", "script": Ground, "look": {}}]
	var march: Array = CrimsonMarchStage.ZONES
	for i in march.size():
		out.append({"id": "march%d" % (i + 1), "label": "March %s %s" % [march[i]["numeral"], march[i]["name"]],
			"script": MarchGround, "look": march[i]["ground"]})
	var sanctum: Array = SanctumStage.ZONES
	for i in sanctum.size():
		out.append({"id": "sanctum%d" % (i + 1), "label": "Sanctum %s %s" % [sanctum[i]["numeral"], sanctum[i]["name"]],
			"script": SanctumGround, "look": sanctum[i]["ground"]})
	return out


## The units of one panel, left to right: [{draw: Callable(ci, o), w, h, key}].
## `h` / `w` are the drawn size in world px (sprite size, or the glyph's rough size).
func _units() -> Array:
	var units: Array = [_unit_for_key(_key, func(ci: CanvasItem, o: Vector2) -> void: SpriteBank.draw(ci, _key, o, false))]
	var refs: Array = [
		["player/necromancer", func(ci: CanvasItem, o: Vector2) -> void: Glyphs.draw_necromancer(ci, o, PlayerData.RADIUS, false)],
		["summons/warrior", func(ci: CanvasItem, o: Vector2) -> void: Glyphs.draw_summon(ci, "warrior", o, float(UnitData.UNITS["warrior"]["radius"]), false)],
		["enemies/recruit", func(ci: CanvasItem, o: Vector2) -> void: Glyphs.draw_enemy(ci, "recruit", o, float(EnemyData.ENEMIES["recruit"]["radius"]), false, false)],
	]
	for r: Array in refs:
		if r[0] != _key:
			units.append(_unit_for_key(r[0], r[1]))
	return units


## Size and filter of the unit drawn for sprite `key` by `draw`.
func _unit_for_key(key: String, draw: Callable) -> Dictionary:
	var h: float = SpriteData.HEIGHTS.get(key, SpriteData.DEFAULT_HEIGHT)  # Drawn height (world px).
	var tex := SpriteBank.texture(key)  # Art, or null (glyph fallback).
	var w := h * 0.6  # Glyph width estimate (world px).
	var grid := key == _key  # Grid art (sharp) or old smooth art / glyph.
	if tex != null:
		w = h * float(tex.get_width()) / float(tex.get_height())
		grid = grid or is_equal_approx(float(tex.get_height()) * 2.0, h)
	return {"draw": draw, "w": w, "h": h, "key": key, "sharp": grid, "sprite": tex != null}


## Builds one SubViewport panel: the floor, the units and a camera at `zoom`.
func _build_panel(floor_def: Dictionary, zoom_label: String, zoom: float) -> void:
	var units := _units()
	var world_w := MARGIN * 2.0 + UNIT_GAP * float(units.size() - 1)
	var tallest := 0.0
	for u: Dictionary in units:
		world_w += float(u["w"])
		tallest = maxf(tallest, float(u["h"]))
	var world_h := tallest + MARGIN + FOOT_ROOM
	var vp := SubViewport.new()
	vp.size = Vector2i(ceili(world_w * zoom), ceili(world_h * zoom))
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var ground: Ground = floor_def["script"].new()
	vp.add_child(ground)
	if not (floor_def["look"] as Dictionary).is_empty():
		ground.set_zone(floor_def["look"])
	ground.update_view(FOCUS)
	var cam := Camera2D.new()
	cam.position = FOCUS
	cam.zoom = Vector2(zoom, zoom)
	vp.add_child(cam)
	cam.make_current()
	# Units in a row, feet on one baseline.
	var feet_y := FOCUS.y + world_h * 0.5 - FOOT_ROOM
	var x := FOCUS.x - world_w * 0.5 + MARGIN
	for u: Dictionary in units:
		var stand := ArtCheckStand.new()
		stand.draw_fn = u["draw"]
		var h := float(u["h"])
		# SpriteBank centres the sprite at o + h * CENTER_OFFSET, so its feet are at o.y + h * (0.5 + CENTER_OFFSET);
		# a glyph's feet are about its radius (h / 4) below o.
		var feet_off := h * (0.5 + SpriteData.CENTER_OFFSET) if u["sprite"] else h * 0.25
		stand.position = Vector2(x + float(u["w"]) * 0.5, feet_y - feet_off)
		stand.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if u["sharp"] else CanvasItem.TEXTURE_FILTER_LINEAR
		vp.add_child(stand)
		x += float(u["w"]) + UNIT_GAP
	_panels.append({"viewport": vp, "name": "%s_%s" % [floor_def["id"], zoom_label]})
