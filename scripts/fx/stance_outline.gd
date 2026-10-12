## StanceOutline — the faint ground outline of the army's new shape, shown
## around the necromancer for StanceData.OUTLINE_TIME s of game time after a
## stance change (ArmyStance.changed_at). Purely cosmetic: it reads the run
## state and never changes it. Drawn on the ground layer, under the units
## (same z as the ground telegraphs).
class_name StanceOutline
extends Node2D

## Owning run.
var game: Game


func _ready() -> void:
	z_index = -5


func _process(_delta: float) -> void:
	if game == null or game.stance == null:
		return
	var age := game.elapsed - game.stance.changed_at  # Seconds since the last change.
	var on := age >= 0.0 and age <= StanceData.OUTLINE_TIME
	if on or visible:
		position = game.player.position
		visible = on
		queue_redraw()


func _draw() -> void:
	var st := game.stance
	var k := 1.0 - clampf((game.elapsed - st.changed_at) / StanceData.OUTLINE_TIME, 0.0, 1.0)  # 1 -> 0 fade.
	var col: Color = st.def()["color"]
	col.a = StanceData.OUTLINE_ALPHA * k
	var facing := st.move_dir if st.current == "spearhead" else game.horde.threat_dir  # Shape orientation.
	StanceGlyphs.draw_outline(self, st.current, facing, col)
