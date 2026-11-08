## BarrowGrasp — the Barrow Grasp spell (AbilityData "barrow_grasp"; the Barrow
## Fields, the Hall of the Slain, temporarily Act XI; GDD §15.0 "Barrow Grasp,
## Barrow-Lord's Embrace, Grave Frost and the Rune-Seer"; owner-approved
## proposal: "cold hands burst from the ground in a ring and hold enemies";
## unlocked by slaying Hrimgar, then offered on every stage at the later-item
## card weight). Every `cooldown` s `hands` cold hands (plus the Rune-Seer's
## Rune of Binding, innate value grasp_extra_hands) burst from the ground on a
## ring `ring` px around the necromancer (evenly spread, the ring turned by
## BarrowGraspData.RING_TURN each cast: no RNG). Each hand GRABS every foe
## within `radius` px of it once as it bursts up: `damage` through
## CombatResolver.damage_enemy() and a HOLD of `hold` s through
## CombatResolver.stun_enemy() (THE enemy hold path: a boss or miniboss keeps
## BOSS_HOLD_MULT of it, an elite ELITE_HOLD_MULT; the berserk, the Reckoning
## and structures shrug it off there). GRAVE FROST (the paired passive): every
## hand hits frost_bonus harder and holds frost_bonus longer (0 while not
## owned). Evolved into BARROW-LORD'S EMBRACE (EvolutionData
## "barrow_lords_embrace", detected by the "linger" key): `rings` rings (each
## inner one at ring_step of the last), and every hand LINGERS `linger` s,
## grabbing again every LINGER_TICK s for LINGER_SHARE of the damage, holding
## what walks into it. Works the same on every stage (no act rule).
## Determinism: no RNG; foes in the spatial hash's order. Stats: grasp_casts,
## grasp_hands, grasp_extra_hands, grasp_grabs, grasp_holds,
## grasp_frost_bonus_dmg; damage as dmg_barrow_grasp / dmg_barrow_lords_embrace.
class_name BarrowGrasp
extends NecroSpell

## Standing hands: {pos (world px), t0 (game s it burst), t_end (game s it
## sinks), next (game s of its next grab; INF when done)}.
var hands: Array[Dictionary] = []
## Seconds until the next cast.
var _cd: float = 0.0
## Casts so far (turns the ring).
var _casts: int = 0
## The spell's stats at the last step.
var _stats: Dictionary = {}
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Casts on the cooldown; the hands grab and sink.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"])
		_cast()
	var now := game.elapsed
	var i := 0
	while i < hands.size():
		var h := hands[i]
		if now >= float(h["t_end"]):
			hands.remove_at(i)
			continue
		if now >= float(h["next"]):
			_grab(h, float(h["next"]) > float(h["t0"]))
		i += 1
	var busy := not hands.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One cast: the rings of hands around the necromancer.
func _cast() -> void:
	var p := game.player.position
	var evolved := _stats.has("linger")
	var per := int(_stats["hands"]) + roundi(game.character.innate_value(BarrowGraspData.EXTRA_HANDS_KEY))
	var rings := int(_stats.get("rings", 1))
	var r := float(_stats["ring"])
	var life := float(_stats["linger"]) if evolved else BarrowGraspData.HAND_LIFE
	var base := float(_casts) * BarrowGraspData.RING_TURN
	var made := 0
	for ring in rings:
		var n := maxi(1, per - ring * 2)  # Inner rings carry a little fewer.
		for k in n:
			if hands.size() >= BarrowGraspData.MAX_HANDS:
				break
			var a := base + TAU * float(k) / float(n) + float(ring) * PI / float(n)
			var at := p + Vector2.from_angle(a) * r
			hands.append({"pos": at, "t0": game.elapsed, "t_end": game.elapsed + life, "next": game.elapsed})
			made += 1
		r *= float(_stats.get("ring_step", 0.6))
	_casts += 1
	game.stat_add("grasp_casts", 1.0)
	game.stat_add("grasp_hands", float(made))
	if per > int(_stats["hands"]):
		game.stat_add("grasp_extra_hands", float(per - int(_stats["hands"])))
	Sfx.play("deep_freeze", p, 0.3)


## Hand `h` grabs every foe in reach (`again`: a lingering hand's later grab,
## LINGER_SHARE of the damage).
func _grab(h: Dictionary, again: bool) -> void:
	var evolved := _stats.has("linger")
	h["next"] = float(h["next"]) + BarrowGraspData.LINGER_TICK if evolved else INF
	var frost := game.abilities.passive_value(BarrowGraspData.GRAVE_FROST, BarrowGraspData.GRAVE_FROST_KEY)  # 0 when not owned.
	var dmg := float(_stats["damage"]) * (1.0 + frost) * (BarrowGraspData.LINGER_SHARE if again else 1.0)
	var hold := float(_stats["hold"]) * (1.0 + frost)
	var src := BarrowGraspData.EVOLVED_SOURCE if evolved else BarrowGraspData.SOURCE
	var at: Vector2 = h["pos"]
	var r := float(_stats["radius"])
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, _tmp)
	var seen := 0
	for e: Enemy in _tmp.duplicate():
		if not e.active or e.untargetable or e.civilian or e.position.distance_to(at) > r + e.radius:
			continue
		var dealt := game.combat.damage_enemy(e, dmg, src)
		if frost > 0.0 and dealt > 0.0:
			game.stat_add("grasp_frost_bonus_dmg", dealt * frost / (1.0 + frost))
		game.stat_add("grasp_grabs", 1.0)
		if e.active and game.combat.stun_enemy(e, hold, BarrowGraspData.BOSS_HOLD_MULT, BarrowGraspData.ELITE_HOLD_MULT) > 0.0:
			game.stat_add("grasp_holds", 1.0)
		seen += 1
		if seen >= BarrowGraspData.GRAB_SAMPLES:
			break


## Autotest counters (BarrowFieldsReport's Barrow Grasp line).
func summary_extra() -> String:
	var st := game.stats
	return "casts=%d hands=%d (extra %d) grabs=%d holds=%d" % [int(st.get("grasp_casts", 0.0)), int(st.get("grasp_hands", 0.0)),
		int(st.get("grasp_extra_hands", 0.0)), int(st.get("grasp_grabs", 0.0)), int(st.get("grasp_holds", 0.0))]


## The hands: a pale frost-blue palm and four grasping fingers bursting up out
## of a ring of snow, sinking at the end (disc textures; the evolved hands a
## colder rune blue). Visual only.
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	var evolved := _stats.has("linger")
	var col := Palette.NORSE_RUNE if evolved else Palette.NORSE_DRAUGR_LIGHT
	for h in hands:
		var p: Vector2 = h["pos"]
		var t0 := float(h["t0"])
		var t1 := float(h["t_end"])
		var rise := clampf((now - t0) / BarrowGraspData.RISE_TIME, 0.0, 1.0)
		var sink := clampf((t1 - now) / BarrowGraspData.RISE_TIME, 0.0, 1.0)
		var k := minf(rise, sink)  # How far out of the ground (0..1).
		SpriteBank.draw_disc(self, p + Vector2(0.0, 3.0), 9.0, Color(Palette.NORSE_FROST, 0.45))  # Broken snow.
		var top := p + Vector2(0.0, -10.0 * k)
		SpriteBank.draw_disc(self, top + Vector2(0.0, 3.0), 4.5 * k + 1.0, Color(Palette.NORSE_INK, 0.8))
		SpriteBank.draw_disc(self, top + Vector2(0.0, 3.0), 3.6 * k + 0.8, col)  # The palm.
		for f in 4:
			var fx := -3.6 + 2.4 * float(f)
			var fy := -3.0 - (1.5 if f == 1 or f == 2 else 0.0)
			SpriteBank.draw_disc(self, top + Vector2(fx, fy) * k, 1.3 * k + 0.4, col)  # The fingers.
