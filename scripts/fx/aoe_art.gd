## AoeArt: draws the necromancer side's ground effects from pixel-art pieces
## (GDD §15.0 "Player AoE art"; pieces made by tools/aoe_art.py, numbers in
## AoeArtData). A ground area must show its real hit radius at any size (levels
## and area passives grow them), so nothing is one stretched image: ring pieces
## are repeated along the rim and turned outward (the Undertow crest pattern),
## cloud puffs are scattered over the area, centre pieces come in a few sizes,
## lane tiles repeat along the lane. Every piece is drawn 1:1 through the
## sharp-pixel shader (SpriteBank.apply_sharp()), only its opacity changes.
## Each drawing function returns false and draws nothing when its art is
## missing, so the caller keeps its code drawing as the fallback. The soft discs
## under some effects are SpriteBank.draw_disc() (a batched texture, no polygon:
## GDD §15.0 "Web GL id leak patch"). Piece counts follow the visual tier
## (AdaptiveQuality.tier(), AoeArtData.TIER_DENSITY). Purely visual: it reads
## its arguments and the game time it is given, never gameplay state or RNG
## (variety comes from a fixed hash of a piece's index).
class_name AoeArt
extends RefCounted

## Piece id -> its texture (a linear-filtered CanvasTexture for the sharp-pixel
## shader), or null when the PNG is missing. Filled on first use.
static var _cache: Dictionary = {}


## The texture of piece `id` (AoeArtData.ROOT + id + ".png"), or null when it
## has no PNG. Loaded and wrapped once; --art-misses records the misses.
static func tex(id: String) -> Texture2D:
	if _cache.has(id):
		if ArtMissLog.on and _cache[id] == null:
			ArtMissLog.miss("aoe/" + id)
		return _cache[id]
	var path := AoeArtData.ROOT + id + ".png"  # Expected file.
	var out: Texture2D = null  # Wrapped texture (null = no art).
	if ResourceLoader.exists(path):
		var raw := load(path) as Texture2D  # The PNG.
		if raw != null:
			var sharp := CanvasTexture.new()  # Linear samples for the sharp-pixel shader (SpriteBank header).
			sharp.diffuse_texture = raw
			sharp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			out = sharp
	_cache[id] = out
	if ArtMissLog.on:
		if out == null:
			ArtMissLog.miss("aoe/" + id)
		else:
			ArtMissLog.hit("aoe/" + id)
	return out


## True when piece `id` has its PNG.
static func has(id: String) -> bool:
	return tex(id) != null


## Piece-count multiplier of the current visual tier (1 on Full).
static func density() -> float:
	return AoeArtData.TIER_DENSITY[clampi(AdaptiveQuality.tier(), 0, AoeArtData.TIER_DENSITY.size() - 1)]


## Draws frame `f` of the `frames`-frame strip `id` centred on `pos`, turned by
## `angle` (rad; the art's +x points along it), opacity `a`, mirrored across its
## x axis when `flip`, scaled by `scale` (1 = 1:1). An unturned, unscaled piece
## lands on whole px. Nothing without the texture.
static func piece(ci: CanvasItem, id: String, frames: int, f: int, pos: Vector2, angle: float, a: float, flip: bool = false, scale: Vector2 = Vector2.ONE) -> void:
	var t := tex(id)  # Strip texture.
	if t == null or a <= 0.003:
		return
	SpriteBank.apply_sharp(ci)
	var fw := float(t.get_width()) / float(maxi(frames, 1))  # Frame width (texels).
	var fh := float(t.get_height())  # Frame height (texels).
	var src := Rect2(fw * float(clampi(f, 0, frames - 1)), 0.0, fw, fh)  # Frame in the strip.
	var size := Vector2(fw, fh)  # Drawn size before the transform (px).
	if angle == 0.0 and not flip and scale == Vector2.ONE:
		ci.draw_texture_rect_region(t, Rect2((pos - size * 0.5).round(), size), src, Color(1.0, 1.0, 1.0, a))
		return
	ci.draw_set_transform(pos, angle, Vector2(scale.x, -scale.y if flip else scale.y))
	ci.draw_texture_rect_region(t, Rect2(-size * 0.5, size), src, Color(1.0, 1.0, 1.0, a))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Draws only the top `rise` (0..1) rows of single-frame sprite `id` with its
## bottom row on `base` (a bone spike growing out of the ground), opacity `a`,
## mirrored when `flip`. Nothing without the texture.
static func rising(ci: CanvasItem, id: String, base: Vector2, rise: float, a: float, flip: bool) -> void:
	var t := tex(id)  # Sprite texture.
	if t == null or a <= 0.003:
		return
	var rows := ceilf(float(t.get_height()) * clampf(rise, 0.0, 1.0))  # Texel rows shown (the tip first).
	if rows <= 0.0:
		return
	SpriteBank.apply_sharp(ci)
	var w := float(t.get_width())  # Sprite width (px).
	var top_left := Vector2(base.x - w * 0.5, base.y - rows).round()  # Whole px.
	if flip:
		ci.draw_set_transform(Vector2(top_left.x * 2.0 + w, 0.0), 0.0, Vector2(-1.0, 1.0))
	ci.draw_texture_rect_region(t, Rect2(top_left, Vector2(w, rows)), Rect2(0.0, 0.0, w, rows), Color(1.0, 1.0, 1.0, a))
	if flip:
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Repeats frame `f` of strip `id` along the circle of radius `r` round `c`, one
## piece per `step` px of rim (scaled by the tier density; at least
## AoeArtData.MIN_RING_PIECES), each turned outward with its outer edge on `r`
## (its +x away from the centre), every other one mirrored, the whole ring
## turned by `phase` rad. `count_r` (> 0) counts the pieces on that radius
## instead (a burst keeps its final count while it rolls out). `alt` > 1 cycles
## the frame f, f+1, ... f+alt-1 round the ring (variants). Opacity `a`.
static func ring(ci: CanvasItem, id: String, frames: int, f: int, c: Vector2, r: float, step: float, a: float, phase: float = 0.0, count_r: float = -1.0, alt: int = 1) -> void:
	var t := tex(id)  # Strip texture.
	if t == null or a <= 0.003 or r <= 1.0:
		return
	var fw := float(t.get_width()) / float(maxi(frames, 1))  # Frame width = radial depth (px).
	var n := maxi(AoeArtData.MIN_RING_PIECES, ceili(TAU * (count_r if count_r > 0.0 else r) / step * density()))  # Pieces.
	var d := maxf(r - (fw * 0.5 - 1.0), 0.0)  # Piece centre distance (its outer edge, past the 1 px border, on r).
	for i in n:
		var ang := phase + TAU * float(i) / float(n)  # This piece's direction (rad).
		piece(ci, id, frames, f + (i % maxi(alt, 1)), c + Vector2.from_angle(ang) * d, ang, a, i % 2 == 1)


## The shared soft disc (SpriteBank.draw_disc: batched, no polygon).
static func fill(ci: CanvasItem, c: Vector2, r: float, color: Color) -> void:
	if color.a > 0.003 and r > 0.5:
		SpriteBank.draw_disc(ci, c, r, color)


## Index of the largest size in `sizes` (ascending) not above `d`, else 0.
static func bucket(sizes: Array[float], d: float) -> int:
	var k := 0
	for i in sizes.size():
		if sizes[i] <= d:
			k = i
	return k


## A fixed 0..1 hash of `i` and `j` (visual variety without RNG).
static func hash01(i: int, j: int = 0) -> float:
	var h := sin(float(i) * 12.9898 + float(j) * 78.233) * 43758.5453
	return h - floorf(h)


# =====================================================================================
# Burst rings (Effect._draw() for EffectManager.art_ring())
# =====================================================================================

## True when burst recipe `id` (AoeArtData.BURSTS) has its crest art.
static func has_burst(id: String) -> bool:
	var rec: Dictionary = AoeArtData.BURSTS.get(id, {})
	return not rec.is_empty() and has(String(rec["crest"]))


## Draws burst recipe `id` of radius `r` at `c` on `ci`, `k` (0..1) through its
## life, its soft disc in `color`. Returns false (nothing drawn) without its art.
static func burst(ci: CanvasItem, id: String, c: Vector2, r: float, k: float, color: Color) -> bool:
	var rec: Dictionary = AoeArtData.BURSTS.get(id, {})
	if rec.is_empty() or not has(String(rec["crest"])):
		return false
	var fade := 1.0 - clampf((k - (1.0 - float(rec["fade"]))) / maxf(float(rec["fade"]), 0.01), 0.0, 1.0)  # Late fade.
	var from := float(rec["from"])  # Start radius fraction.
	var roll := from + (1.0 - from) * (1.0 - (1.0 - k) * (1.0 - k))  # Ease-out roll to the full radius.
	var fc: Color = rec.get("fill_color", color)  # Disc colour: the recipe's own, else the caller's.
	fill(ci, c, r * roll, Color(fc, float(rec["fill"]) * (1.0 - k)))
	var centre := String(rec["centre"])  # Centre piece ("" = none, "crack" = by size).
	if centre != "":
		var cf := int(rec["centre_frames"])  # Centre strip frames.
		var cid := centre  # Piece id.
		if centre == "crack":
			cid = AoeArtData.CRACKS[bucket(AoeArtData.CRACK_SIZES, r * 2.0 * AoeArtData.CRACK_FIT)]
		piece(ci, cid, cf, mini(int(k * float(cf)), cf - 1), c, 0.0, float(rec["centre_alpha"]) * fade)
	var frames := AoeArtData.CREST_FRAMES  # Crest strip frames.
	ring(ci, String(rec["crest"]), frames, mini(int(k * float(frames)), frames - 1), c, r * roll,
			float(rec["step"]), float(rec["alpha"]) * fade, 0.0, r)
	return true


## True when burst recipe `id` draws under the bodies (AoeArtData.BURSTS "under").
static func burst_under(id: String) -> bool:
	return bool(AoeArtData.BURSTS.get(id, {}).get("under", false))


# =====================================================================================
# Telegraphs (summon wind-ups, boulder landings)
# =====================================================================================

## A wind-up telegraph of radius `r` at `at`, `k` (0..1) of the wind-up done:
## the soft area disc and a ring of rim marks (`mark`, AoeArtData.MARK_FRAMES
## frames) whose outer edge is the hit radius; the marks light up one after
## another round the rim as the wind-up runs (a clock sweep from the top, all
## lit at the strike), which replaces the code's growing disc. `color` is the
## caller's code colour. `centre` (optional) is a piece faded in with k (ground
## cracks under a stomp, the frost star under a Deep Freeze). Returns false
## without the mark art.
static func telegraph(ci: CanvasItem, mark: String, at: Vector2, r: float, k: float, color: Color, centre: String = "", centre_frames: int = 1) -> bool:
	var t := tex(mark)  # Mark strip.
	if t == null:
		return false
	var kk := clampf(k, 0.0, 1.0)  # Wind-up progress.
	fill(ci, at, r, Color(color, AoeArtData.TELEGRAPH_FILL + AoeArtData.TELEGRAPH_GROW * kk * 0.5))
	if centre != "":
		piece(ci, centre, centre_frames, 0, at, 0.0, 0.7 * kk)
	var fw := float(t.get_width()) / float(AoeArtData.MARK_FRAMES)  # Mark depth (px).
	var n := maxi(AoeArtData.MIN_RING_PIECES, ceili(TAU * r / AoeArtData.MARK_STEP * density()))  # Marks.
	var d := maxf(r - (fw * 0.5 - 1.0), 0.0)  # Mark centre distance (outer edge on r).
	var lit := int(ceilf(kk * float(n)))  # Marks lit so far.
	for i in n:
		var ang := -PI * 0.5 + TAU * float(i) / float(n)  # From the top, clockwise.
		piece(ci, mark, AoeArtData.MARK_FRAMES, 1 if i < lit else 0, at + Vector2.from_angle(ang) * d, ang, AoeArtData.MARK_ALPHA, i % 2 == 1)
	return true


## The ground-crack piece that fits a stomp of radius `r`.
static func crack_for(r: float) -> String:
	return AoeArtData.CRACKS[bucket(AoeArtData.CRACK_SIZES, r * 2.0 * AoeArtData.CRACK_FIT)]


# =====================================================================================
# Plague Cloud / Pestilence
# =====================================================================================

## A Plague Cloud (or, `pest`, a Pestilence cloud) of radius `r` at `p`: a soft
## disc, puffs scattered inside it slowly turning, a rim of puffs whose outer
## edge is the cloud's edge, rising bubbles (plague) or orbiting soul motes and
## a violet charge rim (Pestilence, brighter as the Death Nova nears). `life`
## runs 1 -> 0, `now` is the game time (s). Returns false without the art.
static func cloud(ci: CanvasItem, p: Vector2, r: float, life: float, now: float, pest: bool) -> bool:
	var ids: Array[String] = AoeArtData.PEST_PUFFS if pest else AoeArtData.PLAGUE_PUFFS  # Puff ids by size.
	if not has(ids[0]) or not has(ids[1]) or not has(ids[2]):
		return false
	var a: float  # Fade in / out (the code's formula).
	if pest:
		a = clampf(life * 6.0, 0.0, 1.0) * clampf((1.0 - life) * 10.0 + 0.4, 0.0, 1.0)
		fill(ci, p, r, Color(SpellGlyphs.PLAGUE_DARK, AoeArtData.PEST_FILL * a))
	else:
		a = clampf(life * 3.0, 0.0, 1.0) * clampf((1.0 - life) * 10.0 + 0.4, 0.0, 1.0)
		fill(ci, p, r, Color(SpellGlyphs.PLAGUE, AoeArtData.PLAGUE_FILL * a))
	var pa := (AoeArtData.PEST_ALPHA if pest else AoeArtData.PLAGUE_ALPHA) * a  # Puff opacity.
	var dens := density()  # Tier multiplier.
	# Inner puffs on a golden-angle spiral (large ones, then medium: one texture after the other batches).
	var m := maxi(2, int(r * r / AoeArtData.PUFF_INNER_AREA * dens))  # Inner puffs.
	for size_i in [2, 1]:
		var half := AoeArtData.PUFF_SIZES[size_i] * 0.5  # This size's radius (px).
		for i in m:
			if (2 if i % 3 != 0 else 1) != size_i:
				continue
			var fr := (float(i) + 0.5) / float(m)  # Area fraction (even spread).
			var ang := float(i) * 2.39996 + now * AoeArtData.PUFF_SPIN * (1.0 if i % 2 == 0 else -0.7)  # Golden angle, turning.
			var d := sqrt(fr) * maxf(r - half * 1.5, 0.0)  # Distance from the centre (px).
			var bob := Vector2(0.0, sin(now * AoeArtData.PUFF_BOB_SPEED + float(i) * 1.7) * AoeArtData.PUFF_BOB)
			piece(ci, ids[size_i], 1, 0, p + Vector2.from_angle(ang) * d + bob, 0.0, pa)
	# Rim puffs, their outer edge on the cloud's edge (small and medium alternating).
	var n := maxi(AoeArtData.MIN_RING_PIECES, ceili(TAU * r / AoeArtData.PUFF_RIM_STEP * dens))  # Rim puffs.
	for size_i in [1, 0]:
		var half := AoeArtData.PUFF_SIZES[size_i] * 0.5  # Radius of this size (px).
		for i in n:
			if i % 2 != (1 - size_i):
				continue
			var ang := TAU * float(i) / float(n) + now * AoeArtData.PUFF_SPIN / 3.0  # Slowly turning.
			var bob := sin(now * AoeArtData.PUFF_BOB_SPEED + float(i) * 2.3) * AoeArtData.PUFF_BOB  # Breathing in and out.
			piece(ci, ids[size_i], 1, 0, p + Vector2.from_angle(ang) * (r - half + bob * 0.5), 0.0, pa)
	if pest:
		var charge := 1.0 - clampf(life * 3.0, 0.0, 1.0)  # Nova build-up in the last third.
		ring(ci, AoeArtData.PEST_CHARGE_CREST, AoeArtData.CREST_FRAMES, 0, p, r, AoeArtData.PEST_CHARGE_STEP,
				(0.25 + 0.65 * charge) * a, now * 0.6)
		for i in 4:
			var q := p + Vector2.from_angle(now * 1.1 + TAU * float(i) / 4.0) * r * 0.6  # Orbiting soul mote.
			piece(ci, AoeArtData.MOTE_SOUL, AoeArtData.MOTE_FRAMES, int(now * 4.0 + float(i)) % 2, q, 0.0, 0.85 * a)
	else:
		for i in 3:
			var rise := fposmod(now * 0.6 + float(i) / 3.0, 1.0)  # 0 -> 1 as a bubble rises.
			var q := p + Vector2(r * (0.4 * float(i) - 0.4), r * 0.3 - rise * r * 0.7)
			piece(ci, AoeArtData.BUBBLE, AoeArtData.MOTE_FRAMES, mini(int(rise * 3.0), 2), q, 0.0, 0.85 * a)
	return true


# =====================================================================================
# Wither / Necrotic Blight aura
# =====================================================================================

## The Wither aura of radius `r` round `p` (the code's draw_wither arguments): a
## soft disc, a turning rim of thorn-and-rune pieces whose thorn tips are the
## aura's edge (brighter on a pulse `flash`, a little when `busy`), drooping
## motes; `blight` = Necrotic Blight (soul green). Returns false without the art.
static func wither(ci: CanvasItem, p: Vector2, r: float, phase: float, flash: float, blight: bool, busy: bool) -> bool:
	var rune := AoeArtData.BLIGHT_RUNE if blight else AoeArtData.WITHER_RUNE  # Rim strip.
	if not has(rune):
		return false
	var col := Palette.NECRO_GREEN if blight else SpellGlyphs.PLAGUE  # Aura colour.
	fill(ci, p, r, Color(col, 0.04 + 0.05 * flash))
	var a := AoeArtData.RUNE_ALPHA + AoeArtData.RUNE_FLASH_ALPHA * flash + (AoeArtData.RUNE_BUSY_ALPHA if busy else 0.0)  # Rim opacity.
	ring(ci, rune, 2, 0, p, r, AoeArtData.RUNE_STEP, minf(a, 1.0), phase * 0.5, -1.0, 2)
	if blight:
		ring(ci, AoeArtData.WITHER_RUNE, 2, 0, p, r * 0.9, AoeArtData.RUNE_STEP * 1.6, 0.3, -phase * 0.4, -1.0, 2)
	var mote := AoeArtData.MOTE_SOUL if blight else AoeArtData.MOTE_PLAGUE  # Drooping motes.
	for i in 5:
		var fall := fposmod(phase * 0.5 + float(i) / 5.0, 1.0)  # 0 -> 1 as a mote droops.
		var q := p + Vector2.from_angle(TAU * float(i) / 5.0 - phase * 0.3) * r * 0.7 + Vector2(0, fall * 10.0)
		piece(ci, mote, AoeArtData.MOTE_FRAMES, mini(int(fall * 3.0), 2), q, 0.0, 0.8 * (1.0 - fall))
	return true


# =====================================================================================
# Grave Eruption spike field, Corpse Explosion accent
# =====================================================================================

## A Grave Eruption bone-spike field of radius `r` at `p` (`life` 1 -> 0: the
## spikes rise in at once and sink at the end; `now` turns the rim): a dark
## disc, a glowing crack in the middle, a ring of rim marks on its edge and two
## rings of bone spikes rising out of the ground. False without the art.
static func spike_field(ci: CanvasItem, p: Vector2, r: float, life: float, now: float) -> bool:
	if not has(AoeArtData.SPIKES[0]) or not has(AoeArtData.SPIKES[1]):
		return false
	var grow := clampf((1.0 - life) * 8.0, 0.0, 1.0)  # Spikes rising.
	var a := clampf(life * 4.0, 0.0, 1.0)  # Fade at the end.
	fill(ci, p, r, Color(0.08, 0.04, 0.1, 0.35 * a))
	piece(ci, AoeArtData.SOUL_CRACKS[bucket(AoeArtData.CRACK_SIZES, r * 2.0 * 0.6)], 1, 0, p, 0.0, 0.5 * a)
	ring(ci, AoeArtData.FIELD_MARK, AoeArtData.MARK_FRAMES, 0, p, r, AoeArtData.MARK_STEP * 1.5, 0.7 * a, now * 0.2)
	var n := maxi(AoeArtData.MIN_RING_PIECES, ceili(TAU * r * AoeArtData.SPIKE_RING / AoeArtData.SPIKE_STEP * density()))  # Outer spikes.
	# Back to front (top of the screen first), so a lower spike overlaps the one above it.
	for pass_i in 2:
		for i in n:
			var ang := TAU * (float(i) + 0.5 * hash01(i, 3)) / float(n)  # Outer spike angle.
			var q := p + Vector2.from_angle(ang) * r * AoeArtData.SPIKE_RING
			if (q.y < p.y) != (pass_i == 0):
				continue
			rising(ci, AoeArtData.SPIKES[i % 2], q + Vector2(0, 4), grow * (0.75 + 0.25 * hash01(i, 5)), a * AoeArtData.SPIKE_ALPHA, i % 3 == 0)
	for i in AoeArtData.SPIKE_INNER_COUNT:
		var q := p + Vector2.from_angle(TAU * float(i) / float(AoeArtData.SPIKE_INNER_COUNT) + 0.6) * r * AoeArtData.SPIKE_INNER
		rising(ci, AoeArtData.SPIKES[1], q + Vector2(0, 5), grow, a * AoeArtData.SPIKE_ALPHA, i % 2 == 0)
	return true


## The Corpse Explosion / Grave Eruption burst accent (the code's draw_bone_burst
## arguments, `t` 0..1): a ring of rubble crests rolling out to `r` (soul-fire
## wisps for an eruption). False without the art.
static func bone_burst(ci: CanvasItem, p: Vector2, r: float, t: float, eruption: bool) -> bool:
	var id := "crest_soul" if eruption else "crest_rubble"  # Crest strip.
	if not has(id):
		return false
	var k := clampf(t, 0.0, 1.0)
	var roll := 0.35 + 0.65 * (1.0 - (1.0 - k) * (1.0 - k))  # Ease-out roll.
	ring(ci, id, AoeArtData.CREST_FRAMES, mini(int(k * 4.0), 3), p, r * roll, 14.0, 0.9 * (1.0 - k * k), 0.0, r)
	return true


# =====================================================================================
# Hellhound fire patches, Ossuary Engine shard fields
# =====================================================================================

## A Hellhound fire patch at `pos` (radius `r`, `k` = life left 1..0): a
## scorch mark scaled to the patch and two flickering flame tongues (one on the
## lower tiers). The flicker runs with the patch's age; the variant comes from
## its position. False without the art.
static func fire_patch(ci: CanvasItem, pos: Vector2, r: float, k: float) -> bool:
	if not has(AoeArtData.FLAMES[0]):
		return false
	var seed := int(floorf(pos.x) * 3.0 + floorf(pos.y) * 7.0)  # Fixed per patch (it never moves).
	var s := r * 2.0 / AoeArtData.SCORCH_SIZES[0]  # Scorch scale to the patch.
	piece(ci, AoeArtData.SCORCH_SMALL, 1, 0, pos, 0.0, AoeArtData.SCORCH_ALPHA * k, false, Vector2(s, s))
	var tick := int((1.0 - k) * AoeArtData.FLAME_FPS * 3.0) + posmod(seed, 4)  # Flicker frame counter.
	var tongues := 2 if density() >= 0.6 else 1  # Flames on this patch.
	for i in tongues:
		var off := Vector2((-0.35 + 0.7 * float(i)) * r if tongues > 1 else 0.0, -r * 0.25 - float(i) * 2.0)  # Tongue base.
		var v := AoeArtData.FLAMES[posmod(seed + i, 3)]  # Flame variant.
		piece(ci, v, AoeArtData.FLAME_FRAMES, posmod(tick + i * 2, AoeArtData.FLAME_FRAMES), pos + off, 0.0, clampf(k * 1.6, 0.0, 1.0))
	return true


## An Ossuary Engine shard field at `pos` (radius `r`, `k` = life left): a large
## scorch mark scaled to the field, bone shards stuck in it at the code's
## places, and a few low flames. False without the art.
static func shard_field(ci: CanvasItem, pos: Vector2, r: float, k: float) -> bool:
	if not has(AoeArtData.SCORCH_LARGE) or not has(AoeArtData.SPIKES[0]):
		return false
	var s := r * 2.0 / AoeArtData.SCORCH_SIZES[1]  # Scorch scale to the field.
	piece(ci, AoeArtData.SCORCH_LARGE, 1, 0, pos, 0.0, AoeArtData.SCORCH_ALPHA * k, false, Vector2(s, s))
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.3  # Shard angle.
		var q := pos + Vector2.from_angle(a) * r * (0.35 + 0.1 * float(i % 3))  # Shard root.
		rising(ci, AoeArtData.SPIKES[i % 2], q, 1.0, k, i % 2 == 1)
	var tick := int((1.0 - k) * AoeArtData.FLAME_FPS * 4.0)  # Flicker frame counter.
	if density() >= 0.6:
		for i in 2:
			var q := pos + Vector2.from_angle(TAU * float(i) / 2.0 + 1.1) * r * 0.55
			piece(ci, AoeArtData.FLAMES[i], AoeArtData.FLAME_FRAMES, posmod(tick + i, AoeArtData.FLAME_FRAMES), q, 0.0, 0.8 * k)
	return true


# =====================================================================================
# Rogue dash lane
# =====================================================================================

## The Rogue's dash lane from the origin along `dir` (unit vector), `length` px
## long and `half` px half-wide, filled to `k` (0..1): body tiles repeated along
## it (charged up to k) and an arrowhead at its end. False without the art.
static func lane(ci: CanvasItem, dir: Vector2, length: float, half: float, k: float) -> bool:
	if not has(AoeArtData.LANE_BODY) or not has(AoeArtData.LANE_HEAD):
		return false
	var ang := dir.angle()  # Lane direction (rad).
	var sy := half * 2.0 / AoeArtData.LANE_ART_WIDTH  # Stretch across the lane.
	var tile := AoeArtData.LANE_TILE  # Tile length (px).
	var body := maxf(length - tile, 0.0)  # Length the body tiles cover (px).
	var n := maxi(1, ceili(body / tile))  # Body tiles.
	for i in n:
		var x := tile * (float(i) + 0.5)  # Tile centre along the lane (px).
		piece(ci, AoeArtData.LANE_BODY, 2, 1 if x <= length * k else 0, dir * x, ang, AoeArtData.LANE_ALPHA, false, Vector2(1.0, sy))
	piece(ci, AoeArtData.LANE_HEAD, 1, 0, dir * (length - tile * 0.5), ang, AoeArtData.LANE_ALPHA, false, Vector2(1.0, sy))
	return true


## The dash streak behind a dashing Rogue (moving along `dir`). False without the art.
static func streak(ci: CanvasItem, dir: Vector2) -> bool:
	if not has(AoeArtData.STREAK):
		return false
	piece(ci, AoeArtData.STREAK, 1, 0, -dir * 13.0, dir.angle(), 0.85)
	return true


# =====================================================================================
# Summon evolution light column
# =====================================================================================

## The light column on a summon evolving in place (body radius `r`, `frac`
## 1 -> 0 over the transform): the column rises from the unit's feet and fades.
## False without the art.
static func transform_glow(ci: CanvasItem, r: float, frac: float) -> bool:
	if not has(AoeArtData.COLUMN):
		return false
	var k := clampf(frac, 0.0, 1.0)
	var t := tex(AoeArtData.COLUMN)  # Column strip (frame height = column height).
	var h := float(t.get_height())  # Column height (px).
	var f := int((1.0 - k) * 10.0) % AoeArtData.COLUMN_FRAMES  # Rising runes.
	piece(ci, AoeArtData.COLUMN, AoeArtData.COLUMN_FRAMES, f, Vector2(0.0, r * AoeArtData.COLUMN_FOOT - h * 0.5), 0.0, AoeArtData.COLUMN_ALPHA * k)
	return true


# =====================================================================================
# Ultimates (UltimateOverlay)
# =====================================================================================

## The halo piece id whose diameter best fits `d` px (Sovereign's Decree).
static func halo_for(d: float) -> String:
	return AoeArtData.HALOS[bucket(AoeArtData.HALO_SIZES, d)]


## True when the Decree halos, the black sun and the Tide edge have their art.
static func has_ultimates() -> bool:
	return has(AoeArtData.HALOS[0]) and has(AoeArtData.BLACK_SUN) and has(AoeArtData.TIDE_EDGE)


## Grave Tide: edge-mist tiles laid along the four edges of world rect `view`,
## opacity `a`, rolling with the game time `now`.
static func tide_edges(ci: CanvasItem, view: Rect2, a: float, now: float) -> void:
	var tw := AoeArtData.TIDE_TILE.x  # Tile length along the edge (px).
	var td := AoeArtData.TIDE_TILE.y  # Tile depth (px).
	var f := int(now * AoeArtData.TIDE_FPS) % 2  # Rolling frame.
	var nx := ceili(view.size.x / tw)  # Tiles along the top / bottom.
	var ny := ceili(view.size.y / tw)  # Tiles along the sides.
	for i in nx:
		var x := view.position.x + tw * (float(i) + 0.5)
		piece(ci, AoeArtData.TIDE_EDGE, 2, (f + i) % 2, Vector2(x, view.position.y + td * 0.5), 0.0, a)
		piece(ci, AoeArtData.TIDE_EDGE, 2, (f + i + 1) % 2, Vector2(x, view.end.y - td * 0.5), PI, a)
	for i in ny:
		var y := view.position.y + tw * (float(i) + 0.5)
		piece(ci, AoeArtData.TIDE_EDGE, 2, (f + i) % 2, Vector2(view.position.x + td * 0.5, y), -PI * 0.5, a)
		piece(ci, AoeArtData.TIDE_EDGE, 2, (f + i + 1) % 2, Vector2(view.end.x - td * 0.5, y), PI * 0.5, a)


# =====================================================================================
# Soul Chains bolts, Eclipse Ward band, chill film, Dirge veil
# =====================================================================================

## A soul-lightning arc along the jagged points `pts` (GraveSpellGlyphs._jagged),
## opacity `al`: one bolt segment sprite per hop, turned along it and stretched
## to its length (2 frames, flickering by hop); `damned` lays the wide soul-green
## under-glow first. False without the art.
static func bolt_arc(ci: CanvasItem, pts: PackedVector2Array, al: float, damned: bool) -> bool:
	if not has(AoeArtData.BOLT) or pts.size() < 2:
		return false
	var t := tex(AoeArtData.BOLT)  # Bolt strip.
	var seg_len := float(t.get_width()) / 2.0 - 2.0  # Drawn length of one segment at scale 1 (px, inside its border).
	for pass_i in (2 if damned else 1):
		var id := AoeArtData.BOLT_GLOW if pass_i == 0 and damned else AoeArtData.BOLT  # Under-glow, then the bolt.
		var a := (0.55 if id == AoeArtData.BOLT_GLOW else 1.0) * al  # Its opacity.
		for i in pts.size() - 1:
			var d := pts[i + 1] - pts[i]  # This hop.
			var l := d.length()  # Its length (px).
			if l < 0.5:
				continue
			piece(ci, id, 2, i % 2, (pts[i] + pts[i + 1]) * 0.5, d.angle(), a, false, Vector2(l / seg_len, 1.0))
	return true


## The Eclipse Ward barrier band on its orbit of radius `r` round `c`, turned by
## `angle` (rad): band pieces with soul runes along the whole orbit. False
## without the art.
static func eclipse_band(ci: CanvasItem, c: Vector2, r: float, angle: float) -> bool:
	if not has(AoeArtData.ECLIPSE_BAND):
		return false
	ring(ci, AoeArtData.ECLIPSE_BAND, 2, 0, c, r + AoeArtData.ECLIPSE_BAND_OUT, AoeArtData.ECLIPSE_BAND_STEP, AoeArtData.ECLIPSE_BAND_ALPHA, angle, -1.0, 2)
	return true


## The frost film over a chilled body of radius `r` at `c` (Frost Wraith chill):
## a faint frost tint and the ice-crust sprite scaled to the body. False without the art.
static func chill(ci: CanvasItem, c: Vector2, r: float) -> bool:
	if not has(AoeArtData.CHILL):
		return false
	fill(ci, c, r * 1.05, Color(Palette.FROST, 0.16))
	var s := r / AoeArtData.OVERLAY_RADIUS  # Scale to this body.
	piece(ci, AoeArtData.CHILL, 1, 0, c, 0.0, 0.9, false, Vector2(s, s))
	return true


## The Dirge mark over a weakened body of radius `r` at `c` (Banshee): the veil
## and tears, with the crossed silence halo while `silenced`. False without the art.
static func dirge(ci: CanvasItem, c: Vector2, r: float, silenced: bool) -> bool:
	var t := tex(AoeArtData.DIRGE)  # Veil strip (2 frames).
	if t == null:
		return false
	var s := r / AoeArtData.OVERLAY_RADIUS  # Scale to this body.
	var h := float(t.get_height())  # Frame height (px).
	# The sprite's body centre sits AoeArtData.DIRGE_CENTRE_Y rows from its top: shift the frame so it lands on `c`.
	var off := Vector2(0.0, (h * 0.5 - AoeArtData.DIRGE_CENTRE_Y) * s)
	piece(ci, AoeArtData.DIRGE, 2, 1 if silenced else 0, c + off, 0.0, 0.85, false, Vector2(s, s))
	return true
