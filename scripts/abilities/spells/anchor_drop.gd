## AnchorDrop — the Anchor Drop spell (AbilityData "anchor_drop"; Act X, the
## Maelstrom; GDD §15.0 "Anchor Drop, Abyssal Mooring, Dead Reckoning and the
## Ghost Helmsman"; owner-approved proposal: "a spectral anchor slams the
## strongest enemy, stuns it and shocks a ring around it (no pull)"; unlocked
## by defeating Vandermere, then offered on every stage at the later-item card
## weight). Every `cooldown` s a spectral anchor (plus the Ghost Helmsman's
## Second Anchor innate, at most AnchorDropData.MAX_ANCHORS; `anchors` from the
## evolution) comes down on the STRONGEST open foe within AIM_RANGE px of the
## necromancer (the most HP left; the next strongest for each more anchor) and
## lands FALL_TIME s later: `damage` to it (CombatResolver.damage_enemy(), the
## friendly damage path) and a STUN of anchor_stun s (CombatResolver
## .stun_enemy(): bosses and minibosses STUN_BOSS_MULT, elites
## STUN_ELITE_MULT), and a SHOCK RING: every other foe within ring_radius px
## takes ring_share x the damage. Nothing is pulled or moved (the act's spells
## knock, chain and bombard; none pull). Evolved into ABYSSAL MOORING
## (EvolutionData "abyssal_mooring", detected by the "moor" key): two anchors,
## harder and wider, and each stays MOORED `moor` s where it fell, shocking
## the foes within moor_radius px every moor_every s for moor_share x the
## damage. DEAD RECKONING (the paired passive): its cooldown share and its stun
## share are applied by AbilityManager.apply_spell_mods() on the spell's own
## keys.
## Determinism: no RNG; the strongest foes by HP, ties in the spatial hash's
## order; on game time. Stats: anchor_casts, anchor_slams, anchor_stuns,
## anchor_ring_hits, anchor_moor_pulses; damage as dmg_anchor_drop /
## dmg_anchor_drop_shock / dmg_abyssal_mooring / dmg_abyssal_mooring_shock.
class_name AnchorDrop
extends NecroSpell

## Seconds until the next cast.
var _cd: float = 0.0
## Anchors coming down: {target (Enemy), gen (int), at (world px), t (s)}.
var anchors: Array[Dictionary] = []
## Moored anchors (Abyssal Mooring): {at, until (game s), next (game s), dmg, r}.
var moored: Array[Dictionary] = []
## Shock rings drawn fading: {at, r, t (game s)}.
var _rings: Array[Dictionary] = []
## True if the last frame drew anything (one more redraw clears it).
var _drawn: bool = false


## Casts when ready; brings the anchors down; pulses the moored ones.
func step(delta: float, stats: Dictionary) -> void:
	_cd -= delta
	if _cd <= 0.0:
		var n := mini(int(stats.get("anchors", 1)) + int(game.character.innate_value(AnchorDropData.EXTRA_KEY)), AnchorDropData.MAX_ANCHORS)
		if _cast(n):
			_cd = float(stats["cooldown"])
		else:
			_cd = AbilityData.SPELL_RETRY
	_step_anchors(delta, stats)
	_step_moored()
	while not _rings.is_empty() and game.elapsed - float(_rings[0]["t"]) > 0.35:
		_rings.pop_front()
	var busy := not anchors.is_empty() or not moored.is_empty() or not _rings.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Picks the `n` strongest open foes within reach and drops an anchor on each.
## False when none is in reach.
func _cast(n: int) -> bool:
	var p := game.player.position
	game.enemy_grid.query(p, AnchorDropData.AIM_RANGE, _tmp)
	var picked: Array[Enemy] = []
	for _k in n:
		var best: Enemy = null
		for e: Enemy in _tmp:
			if not is_open_target(e) or e.civilian or picked.has(e) or e.position.distance_to(p) > AnchorDropData.AIM_RANGE:
				continue
			if best == null or e.hp > best.hp:
				best = e
		if best == null:
			break
		picked.append(best)
	if picked.is_empty():
		return false
	for e in picked:
		anchors.append({"target": e, "gen": e.generation, "at": e.position, "t": 0.0})
	game.stat_add("anchor_casts", 1.0)
	return true


## The anchors fall; each lands FALL_TIME s after its cast.
func _step_anchors(delta: float, stats: Dictionary) -> void:
	var i := 0
	while i < anchors.size():
		var a := anchors[i]
		var e: Enemy = a["target"]
		var alive := e != null and e.active and e.generation == int(a["gen"])
		if alive:
			a["at"] = e.position
		a["t"] = float(a["t"]) + delta
		if float(a["t"]) < AnchorDropData.FALL_TIME:
			i += 1
			continue
		anchors.remove_at(i)
		_land(e if alive else null, a["at"], stats)


## An anchor lands at `at` on `e` (null when it died meanwhile): the slam and
## the stun, then the shock ring; Abyssal Mooring moors it there.
func _land(e: Enemy, at: Vector2, stats: Dictionary) -> void:
	var evolved := stats.has("moor")
	var dmg := float(stats["damage"])
	var ring := float(stats.get("ring_radius", 56.0))
	game.shake(1.5)
	if game.corsair != null:
		game.corsair.play_sound("anchor_drop", at, 0.15)
	else:
		Sfx.play("gargoyle_dive", at)
	if e != null:
		game.combat.damage_enemy(e, dmg, AnchorDropData.EVOLVED_SOURCE if evolved else AnchorDropData.SOURCE)
		game.stat_add("anchor_slams", 1.0)
		if e.active and game.combat.stun_enemy(e, float(stats.get("anchor_stun", 1.0)), AnchorDropData.STUN_BOSS_MULT, AnchorDropData.STUN_ELITE_MULT) > 0.0:
			game.stat_add("anchor_stuns", 1.0)
	var hits: Array = []
	game.enemy_grid.query(at, ring + ProjectileManager.MAX_BODY_RADIUS, hits)
	var share := dmg * float(stats.get("ring_share", 0.4))
	for o: Enemy in hits:
		if o != e and o.active and o.position.distance_to(at) <= ring + o.radius:
			game.combat.damage_enemy(o, share, AnchorDropData.RING_SOURCE)
			game.stat_add("anchor_ring_hits", 1.0)
	game.effects.ring(at, ring, Palette.GOLD if evolved else Palette.NECRO_GREEN, 0.3)
	_rings.append({"at": at, "r": ring, "t": game.elapsed})
	if evolved:
		moored.append({"at": at, "until": game.elapsed + float(stats["moor"]), "next": game.elapsed + float(stats["moor_every"]),
			"dmg": dmg * float(stats["moor_share"]), "r": float(stats["moor_radius"]), "every": float(stats["moor_every"])})


## Abyssal Mooring: every moored anchor shocks its ring on its own clock.
func _step_moored() -> void:
	var now := game.elapsed
	var i := 0
	while i < moored.size():
		var m := moored[i]
		if now >= float(m["until"]):
			moored.remove_at(i)
			continue
		if now >= float(m["next"]):
			m["next"] = float(m["next"]) + float(m["every"])
			damage_area(m["at"], float(m["r"]), float(m["dmg"]), AnchorDropData.MOOR_SOURCE)
			game.stat_add("anchor_moor_pulses", 1.0)
			_rings.append({"at": m["at"], "r": float(m["r"]), "t": now})
		i += 1


## Autotest counters (the Anchor Drop line of MaelstromReport).
func summary_extra() -> String:
	var st := game.stats
	return "casts=%d slams=%d stuns=%d ring_hits=%d moor_pulses=%d" % [int(st.get("anchor_casts", 0.0)), int(st.get("anchor_slams", 0.0)),
		int(st.get("anchor_stuns", 0.0)), int(st.get("anchor_ring_hits", 0.0)), int(st.get("anchor_moor_pulses", 0.0))]


## The anchors falling (the spell's badge art, else a code shape), the moored
## anchors and the shock rings. Textures and rects only. Visual only.
func _draw() -> void:
	if game == null:
		return
	var evolved := game.abilities.evolved.has(AnchorDropData.ID)
	var tex := SpriteBank.texture(AnchorDropData.ANCHOR_ICON)
	var sz := AnchorDropData.ANCHOR_SIZE
	var glow := Palette.GOLD if evolved else Palette.NECRO_GREEN
	for a in anchors:
		var k := clampf(float(a["t"]) / AnchorDropData.FALL_TIME, 0.0, 1.0)
		var at: Vector2 = a["at"]
		SpriteBank.draw_disc(self, at, sz * 0.9 * k, Color(0.0, 0.0, 0.0, 0.25))  # Its shadow grows.
		_anchor(tex, at + Vector2(0.0, -90.0 * (1.0 - k)), sz, Color(1.0, 1.0, 1.0, 0.4 + 0.6 * k), glow)
	for m in moored:
		var left := clampf((float(m["until"]) - game.elapsed) / 0.5, 0.0, 1.0)
		SpriteBank.draw_disc(self, m["at"], float(m["r"]), Color(glow, 0.08 * left))
		_anchor(tex, m["at"], sz, Color(1.0, 1.0, 1.0, 0.85 * left), glow)
	var ring := CityGlyphs.ring_texture()
	for r in _rings:
		var k := clampf((game.elapsed - float(r["t"])) / 0.35, 0.0, 1.0)
		var rr := float(r["r"]) * (0.6 + 0.4 * k)
		draw_texture_rect(ring, Rect2((r["at"] as Vector2) - Vector2(rr, rr), Vector2(rr, rr) * 2.0), false, Color(glow, 0.6 * (1.0 - k)))


## One anchor at `at`: the badge art (`tex`), else a code shape.
func _anchor(tex: Texture2D, at: Vector2, sz: float, mod: Color, glow: Color) -> void:
	if tex != null:
		draw_texture_rect(tex, Rect2(at - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), false, mod)
		return
	draw_rect(Rect2(at + Vector2(-1.5, -sz * 0.45), Vector2(3.0, sz * 0.8)), Color(glow, mod.a))
	draw_rect(Rect2(at + Vector2(-sz * 0.35, sz * 0.25), Vector2(sz * 0.7, 3.0)), Color(glow, mod.a))
