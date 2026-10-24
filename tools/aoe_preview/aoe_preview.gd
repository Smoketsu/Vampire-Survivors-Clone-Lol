## aoe_preview.gd: renders the player AoE art (AoeArt) at game size on the
## Graveyard floor, for tuning and the owner's review sheets (GDD §15.0 "Player
## AoE art"). Not part of the game: tools/ is ignored by Godot, so
## tools/aoe_preview.py copies this scene into a temporary res://_aoe_preview/
## folder, runs it in a window (xvfb) and removes it again.
## Arguments (after --): --page=N (which sheet), --out=PATH (PNG to save),
## --frames=N (frames to wait before saving), --code (draw the code fallbacks:
## the "before" look, with AoeArt's cache primed with misses).
extends Node2D

## Sheet number to draw (see _draw()).
var page: int = 0
## Where the screenshot is saved.
var out_path: String = "user://aoe_preview.png"
## Frames to wait before the screenshot (textures loaded, one stable frame).
var wait_frames: int = 4
## Frames drawn so far.
var frames: int = 0
## True: draw the code fallbacks instead of the art (the "before" sheet).
var code_only: bool = false
## Fixed game time (s) the animated pieces are drawn at.
const NOW: float = 3.7


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--page="):
			page = a.get_slice("=", 1).to_int()
		elif a.begins_with("--out="):
			out_path = a.get_slice("=", 1)
		elif a.begins_with("--frames="):
			wait_frames = a.get_slice("=", 1).to_int()
		elif a == "--code":
			code_only = true
	if code_only:
		# Prime AoeArt's cache with misses, so every helper returns false (the code look).
		for f in DirAccess.get_files_at(AoeArtData.ROOT):
			if f.ends_with(".png"):
				AoeArt._cache[f.get_basename()] = null
	queue_redraw()


func _process(_d: float) -> void:
	frames += 1
	queue_redraw()
	if frames == wait_frames:
		var img := get_viewport().get_texture().get_image()
		img.save_png(out_path)
		print("[aoe-preview] ", out_path)
		get_tree().quit()


## The Graveyard floor tiled over the view.
func _floor() -> void:
	var t := SpriteBank.texture("tiles/graveyard")
	if t == null:
		draw_rect(Rect2(0, 0, 1280, 720), Palette.GROUND)
		return
	for y in range(0, 720, t.get_height()):
		for x in range(0, 1280, t.get_width()):
			draw_texture(t, Vector2(x, y))


## A label at `p`.
func _label(p: Vector2, s: String) -> void:
	draw_string(ThemeDB.fallback_font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 0.6, 0.9))


## A sprite for scale at `p`.
func _unit(key: String, p: Vector2) -> void:
	SpriteBank.draw(self, key, p, false)


## One burst recipe at `c`, radius `r`, progress `k`, the code ring if no art.
func _burst(id: String, c: Vector2, r: float, k: float, col: Color) -> void:
	if not AoeArt.burst(self, id, c, r, k, col):
		draw_circle(c, r * (0.3 + 0.7 * k), Color(col, 0.22 * (1.0 - k)))
		draw_arc(c, r * (0.3 + 0.7 * k), 0.0, TAU, 40, Color(col, 1.0 - k), 3.0)


func _draw() -> void:
	_floor()
	match page:
		0:
			_page_zones()
		1:
			_page_bursts()
		2:
			_page_misc()


## Sheet 0: clouds, auras, the spike field.
func _page_zones() -> void:
	SpellGlyphs.draw_plague(self, Vector2(110, 120), 60.0, 0.6, NOW)
	_label(Vector2(60, 200), "Plague Cloud r60")
	SpellGlyphs.draw_plague(self, Vector2(290, 120), 75.0, 0.5, NOW + 2.0)
	_label(Vector2(240, 210), "Plague Cloud r75")
	SpellGlyphs.draw_pestilence(self, Vector2(510, 130), 95.0, 0.7, NOW)
	_label(Vector2(470, 240), "Pestilence r95")
	SpellGlyphs.draw_pestilence(self, Vector2(760, 130), 95.0, 0.1, NOW + 1.0)
	_label(Vector2(700, 240), "Pestilence charged")
	SpellGlyphs.draw_spike_field(self, Vector2(1080, 130), 90.0, 0.6, NOW)
	_label(Vector2(1030, 240), "Grave Eruption r90")
	GraveSpellGlyphs.draw_wither(self, Vector2(150, 420), 90.0, NOW, 0.0, false, false)
	_unit("player/necromancer", Vector2(150, 420))
	_label(Vector2(110, 530), "Wither r90")
	GraveSpellGlyphs.draw_wither(self, Vector2(420, 420), 105.0, NOW, 0.8, true, true)
	_unit("player/necromancer", Vector2(420, 420))
	_label(Vector2(370, 545), "Necrotic Blight r105 (pulse)")
	for i in 8:
		WarbandGlyphs.draw_fire_patch(self, Vector2(640 + i * 20, 400 + (i % 3) * 14), 14.0, 1.0 - float(i) * 0.1)
	_label(Vector2(640, 470), "Hellhound fire patches r14")
	WarbandGlyphs.draw_shard_field(self, Vector2(900, 420), 30.0, 0.9)
	_label(Vector2(860, 470), "Shard field r30")
	SpellGlyphs.draw_bone_burst(self, Vector2(1100, 420), 70.0, 0.35, false)
	SpellGlyphs.draw_bone_burst(self, Vector2(1100, 600), 70.0, 0.35, true)
	_label(Vector2(1040, 520), "Corpse burst accent")
	_unit("summons/warrior", Vector2(560, 620))
	_unit("enemies/recruit", Vector2(600, 620))


## Sheet 1: burst rings at three moments each.
func _page_bursts() -> void:
	var rows := [["stomp", 64.0, Palette.BONE], ["freeze", 52.0, Palette.COLD_BLUE], ["wail", 72.0, WarbandGlyphs.WAIL],
			["splash", 40.0, Palette.VIOLET], ["dive", 50.0, Palette.VIOLET], ["boulder", 36.0, Palette.BONE],
			["spore_nova", 70.0, Palette.NECRO_GREEN], ["soul_ring", 60.0, Palette.NECRO_GREEN], ["violet_ring", 50.0, Palette.VIOLET],
			["shrapnel", 60.0, Palette.BONE], ["silence", 60.0, WarbandGlyphs.SILENCE], ["stun", 40.0, Palette.IVORY]]
	var x := 70.0
	var y := 90.0
	for row in rows:
		var r: float = row[1]
		for k in [0.15, 0.45, 0.75]:
			_burst(String(row[0]), Vector2(x, y), r, k, row[2])
			x += r * 2.0 + 14.0
		_label(Vector2(x - (r * 2.0 + 14.0) * 3.0, y + r + 12.0), String(row[0]))
		x += 16.0
		if x > 1000.0:
			x = 70.0
			y += 175.0


## Sheet 2: telegraphs, the lane, the column, the ultimates.
func _page_misc() -> void:
	var tel := [["mark_bone", 64.0, Palette.CORPSE_FLESH, "crack_2"], ["mark_ice", 52.0, Palette.COLD_BLUE, "frost_star"],
			["mark_wail", 72.0, WarbandGlyphs.WAIL, ""], ["mark_violet", 50.0, Palette.VIOLET, ""], ["mark_bone", 36.0, Palette.BONE, ""]]
	var x := 80.0
	for t in tel:
		var r: float = t[1]
		var c := Vector2(x, 100)
		if not AoeArt.telegraph(self, String(t[0]), c, r, 0.6, t[2], String(t[3]), 3 if t[3] == "frost_star" else 1):
			draw_circle(c, r, Color(t[2], 0.10))
			draw_circle(c, r * 0.6, Color(t[2], 0.22))
			draw_arc(c, r, 0.0, TAU, 40, Color(t[2], 0.75), 2.0)
		_label(c + Vector2(-r, r + 12), String(t[0]))
		x += r * 2.0 + 30.0
	# Rogue lane.
	draw_set_transform(Vector2(80, 300))
	if not AoeArt.lane(self, Vector2.RIGHT, 130.0, 12.0, 0.55):
		var v := Vector2.RIGHT * 130.0
		var perp := Vector2(0, 12)
		draw_colored_polygon(PackedVector2Array([perp, v + perp, v - perp, -perp]), Color(Palette.VIOLET, 0.12))
		draw_polyline(PackedVector2Array([perp, v + perp, v - perp, -perp, perp]), Color(Palette.VIOLET, 0.8), 1.5)
	draw_set_transform(Vector2.ZERO)
	_unit("summons/rogue", Vector2(80, 300))
	_label(Vector2(80, 330), "Rogue lane")
	# Evolution column.
	draw_set_transform(Vector2(340, 320))
	SummonGlyphs.draw_transform_glow(self, 14.0, 0.7)
	draw_set_transform(Vector2.ZERO)
	_unit("summons/warrior", Vector2(340, 320))
	_label(Vector2(310, 350), "Transform")
	# Ultimates' pieces.
	if AoeArt.has_ultimates():
		AoeArt.piece(self, AoeArtData.BLACK_SUN, 1, 0, Vector2(480, 290), 0.0, 1.0)
		for i in 3:
			AoeArt.piece(self, AoeArtData.HALOS[i], 1, 0, Vector2(580 + i * 70, 300), 0.0, 0.8)
		AoeArt.tide_edges(self, Rect2(860, 220, 380, 200), 0.5, NOW)
	_label(Vector2(460, 350), "Eclipse / Decree / Tide")
	# Soul Chains arcs (plain and Damned).
	GraveSpellGlyphs.draw_lightning(self, Vector2(80, 480), Vector2(260, 430), 3, 0.9, false)
	GraveSpellGlyphs.draw_lightning(self, Vector2(80, 560), Vector2(260, 520), 5, 0.9, true)
	_label(Vector2(80, 600), "Soul Chains / Damned")
	# Chilled and weakened soldiers.
	for i in 3:
		var p := Vector2(360 + i * 50, 500)
		_unit("enemies/recruit", p)
		SummonGlyphs.draw_chill(self, p, 10.0 + 3.0 * float(i))
		var q := Vector2(360 + i * 50, 580)
		_unit("enemies/footman", q)
		WarbandGlyphs.draw_dirge(self, q, 12.0, i == 2)
	_label(Vector2(350, 620), "Chill film / Dirge mark")
	# Eclipse Ward band (orbit radius 60).
	if not AoeArt.eclipse_band(self, Vector2(720, 520), 60.0, 0.4):
		draw_arc(Vector2(720, 520), 60.0, 0.0, TAU, 64, Color(0.05, 0.0, 0.08, 0.45), 9.0)
	_unit("player/necromancer", Vector2(720, 520))
	_label(Vector2(680, 600), "Eclipse Ward band")
