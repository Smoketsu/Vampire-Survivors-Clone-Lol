## Headless check (godot --headless --script tools/evo_frame_check.gd): every spell and
## summon evolution icon must carry the gold evolution frame (UI rule: gold = evolution).
extends SceneTree

## Gold of the frame (Palette.GOLD as baked into the icons).
const GOLD := Color8(224, 169, 46)

func _initialize() -> void:
	var bad := 0
	var ids: Array = []
	ids.append_array(EvolutionData.ORDER)
	ids.append_array(SummonEvolutionData.ORDER)
	for id: String in ids:
		var def: Dictionary = EvolutionData.EVOLUTIONS[id] if EvolutionData.EVOLUTIONS.has(id) else SummonEvolutionData.EVOLUTIONS[id]
		var img: Image = load("res://assets/sprites/icons/%s.png" % String(def["icon"])).get_image()
		var ok := true
		for x in range(5, 27):  # Top edge between the chamfered corners.
			ok = ok and img.get_pixel(x, 0).is_equal_approx(GOLD)
		for y in range(5, 27):
			ok = ok and img.get_pixel(0, y).is_equal_approx(GOLD)
		print("%s %s" % [id, "gold frame" if ok else "MISSING FRAME"])
		if not ok:
			bad += 1
	print("evolutions: %d, missing frame: %d" % [ids.size(), bad])
	quit(1 if bad > 0 else 0)
