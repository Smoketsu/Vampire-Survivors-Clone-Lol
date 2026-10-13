## AnimBursts — art-only one-shot effect animations (docs/art/ART_BIBLE.md
## "Effects"): the Shadow Bolt hit splash, the level-up column and the
## evolution flash. These had no drawn shape before the art, so without their
## PNG nothing is drawn (today's look) and play() returns at once.
## One node draws every live burst in ONE _draw() call from fixed-size ring
## buffers of packed arrays (the FxLayer pattern): no node per burst, the
## cost is bounded, and when the buffer is full the oldest burst is
## overwritten. Owned by EffectManager (EffectManager.burst()), stepped with
## the effects, so it pauses with the run. It is NOT part of the cosmetic
## Effect pool: bursts never count toward EffectManager.active / created, so
## the autotest's effect counts (and same-seed summaries) are unchanged.
## Purely visual: no RNG, no gameplay state; a followed node is only read.
class_name AnimBursts
extends Node2D

## World position of each burst (px), or its offset from the followed node.
var _pos := PackedVector2Array()
## Gameplay radius of each burst (px); the strip is drawn radius * 2 * fill wide.
var _radius := PackedFloat32Array()
## Seconds each burst has played.
var _t := PackedFloat32Array()
## Total play time of each burst (s); a slot is live while _t < _dur.
var _dur := PackedFloat32Array()
## AnimData id of each burst.
var _anim := PackedStringArray()
## Node each burst follows (its position + _pos), or null for a fixed burst.
var _follow: Array[Node2D] = []
## Next slot to write (ring buffer, oldest overwritten when full).
var _next: int = 0
## True while at least one burst was live at the last step (redraw needed).
var _live: bool = false


func _ready() -> void:
	z_index = 5  # Same layer as the cosmetic effects: above units.
	var n := AnimData.BURST_CAPACITY  # Ring-buffer size.
	_pos.resize(n)
	_radius.resize(n)
	_t.resize(n)
	_dur.resize(n)  # Zero-filled: every slot starts finished.
	_anim.resize(n)
	_follow.resize(n)


## Plays animation `anim` once, centred on `pos` (or, with `follow`, on that
## node's position + `pos`), drawn for a gameplay radius of `radius` px.
## Does nothing when the animation's art is missing.
func play(pos: Vector2, radius: float, anim: String, follow: Node2D = null) -> void:
	if _dur.is_empty() or not SpriteBank.has_anim(anim):
		return
	var i := _next  # Slot to fill.
	_next = (_next + 1) % _dur.size()
	_pos[i] = pos
	_radius[i] = radius
	_t[i] = 0.0
	_dur[i] = float(AnimData.ANIMS.get(anim, {}).get("duration", AnimData.DEFAULT_DURATION))
	_anim[i] = anim
	_follow[i] = follow
	_live = true
	queue_redraw()


## Advances every live burst by `delta` seconds and redraws while any plays.
func step(delta: float) -> void:
	if not _live:
		return
	var any := false  # A burst is still playing after this step.
	for i in _dur.size():
		if _t[i] < _dur[i]:
			_t[i] += delta
			any = any or _t[i] < _dur[i]
	_live = any
	queue_redraw()


func _draw() -> void:
	for i in _dur.size():
		if _t[i] >= _dur[i]:
			continue
		var at := _pos[i]  # Draw centre (px).
		var f := _follow[i]  # Followed node, or null.
		if f != null:
			if not is_instance_valid(f):
				continue
			at += f.position
		var fill: float = AnimData.ANIMS.get(_anim[i], {}).get("fill", AnimData.DEFAULT_FILL)  # Diameter multiple.
		SpriteBank.draw_anim(self, _anim[i], at, _radius[i] * 2.0 * fill, _t[i] / _dur[i])
