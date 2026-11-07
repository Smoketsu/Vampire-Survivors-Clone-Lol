## HadesHazards — the world-space side of HADES, LORD OF THE DEAD (BossHades;
## Act IV, the Asphodel Underworld; GDD §15.0 "The Asphodel Underworld (Act IV
## phase 2)"): what he leaves on the field, stepped by his physics (gameplay)
## and drawn here (visual only):
##   * FOOTPRINTS of the Helm of Darkness: while cloaked he leaves a print every
##     footprint_every s that fades over footprint_life s (the only sign of him;
##     owner-approved proposal: "invisible except for his footprints in the
##     asphodel"). Drawing only.
##   * HIS MARKS: a pale sigil over each summon he marked, shrinking as the mark
##     resolves (BossHades.marks; drawing only).
##   * GOD SHADES (the Reclaiming): a god of Olympus risen as a shade
##     (HadesData.GOD_SHADES) gathers god_telegraph s near the necromancer,
##     makes its one attack and fades. Ares' CHARGE: a telegraphed lane from the
##     shade through the necromancer, charge_length px, everything in it hit
##     once; Artemis's VOLLEY: a telegraphed cone of moonlit arrows; Poseidon's
##     wave and Zeus's bolts are Wrath of the Gods strikes BossHades starts
##     through DivineWrath (the shade only shows who called them). The shade is
##     drawn with the god's own art when it exists (the first of its row's
##     `sprites` keys), tinted pale; else the generic shade glyph, scaled up.
##   * THE FINALE: Hades kneeling where he fell, his crown laid at the
##     necromancer's feet, for kneel_time s (BossHades._on_defeated()).
## Every hit goes through CombatResolver (sources BossHades.SRC_GOD). Two
## layers: this node under the bodies (prints, lanes, cones) and an `_over`
## child above them (the sigils, the shades, the kneeling figure).
## Determinism: no RNG; gameplay only in step(), on game time.
class_name HadesHazards
extends Node2D

## Owning run.
var game: Game
## The boss (its data, its marks).
var boss: BossHades = null
## Footprints: {pos, dir (unit, walk direction), t (game time), side (+1 / -1)}.
var prints: Array[Dictionary] = []
## God shades: {row (GOD_SHADES row), pos, t0 (attack game time), until (fade
## end game time), key (art key, "" = glyph), dir (unit, toward the
## necromancer at its rising), done (bool: attacked)}.
var gods: Array[Dictionary] = []
## Game time the finale began (-1 = not yet).
var finale_at: float = -1.0
## Where he kneels (world px).
var finale_pos: Vector2 = Vector2.ZERO
## Where his crown comes to rest (the necromancer's feet, world px).
var crown_to: Vector2 = Vector2.ZERO
## The upper layer (sigils, shades, the kneeling figure).
var _over: Node2D = null
## Alternating foot of the next print (+1 / -1).
var _side: float = 1.0
## Reusable query buffer.
var _buf: Array = []


func _ready() -> void:
	z_index = -1  # Prints, lanes and cones lie on the ground.
	_over = Node2D.new()
	_over.z_index = 3  # Sigils and shades over the bodies.
	_over.z_as_relative = false
	add_child(_over)
	_over.draw.connect(_draw_over)


## Gameplay tick (BossHades.physics_step()): the god shades' attacks.
func step() -> void:
	var t := game.elapsed
	for g in gods:
		if not bool(g["done"]) and t >= float(g["t0"]):
			g["done"] = true
			_god_attack(g)
	var i := gods.size() - 1
	while i >= 0:
		if t >= float(gods[i]["until"]):
			gods.remove_at(i)
		i -= 1


## Visual upkeep: old prints fade out, both layers redraw while anything shows.
func _process(_delta: float) -> void:
	if game == null:
		return
	var t := game.elapsed
	var life := float(HadesData.BOSS["footprint_life"])
	while not prints.is_empty() and t - float(prints[0]["t"]) > life:
		prints.remove_at(0)
	queue_redraw()
	_over.queue_redraw()


## A footprint at `pos` (he walks along `vel`).
func add_footprint(pos: Vector2, vel: Vector2) -> void:
	var dir := vel.normalized() if vel.length() > 1.0 else Vector2.RIGHT
	prints.append({"pos": pos, "dir": dir, "t": game.elapsed, "side": _side})
	_side = -_side


## A god of Olympus rises as a shade at `at` (row of HadesData.GOD_SHADES):
## its telegraph starts now, its attack after god_telegraph s.
func raise_god(row: Dictionary, at: Vector2) -> void:
	var b := HadesData.BOSS
	var key := ""
	for k: String in row["sprites"]:
		if SpriteBank.has(k):
			key = k
			break
	if key != "":
		game.stats["hades_god_art_" + String(row["id"])] = 1.0
	var to := game.player.position - at
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	var t0 := game.elapsed + float(b["god_telegraph"])
	gods.append({"row": row, "pos": at, "t0": t0, "until": t0 + float(b["god_fade"]), "key": key, "dir": dir, "done": false})
	match String(row["attack"]):
		"charge":
			game.effects.telegraph_line(at, at + dir * float(b["charge_length"]), float(b["charge_width"]), float(b["god_telegraph"]))
		"volley":
			game.effects.telegraph_cone(at, dir, float(b["volley_range"]), float(b["volley_half_arc"]), float(b["god_telegraph"]))
	game.effects.spawn_ring(at, Palette.PANTHEON_AEGEAN_LIGHT, "summon_rise")


## God shade `g` makes its one attack (the charge or the volley; the wave and
## the bolts are DivineWrath's, started when it rose).
func _god_attack(g: Dictionary) -> void:
	var b := HadesData.BOSS
	var at: Vector2 = g["pos"]
	var dir: Vector2 = g["dir"]
	var mult := game.enemies.damage_mult * (boss.hit_mult() if boss != null and boss.active else 1.0)  # Time scaling x his buffs.
	match String((g["row"] as Dictionary)["attack"]):
		"charge":
			var length := float(b["charge_length"])
			var hw := float(b["charge_width"]) * 0.5
			var end := at + dir * length
			g["pos"] = end  # The shade ends its charge at the far end of the lane.
			game.effects.slash(at.lerp(end, 0.5), dir, Palette.PANTHEON_MARBLE_LIGHT, length * 0.5)
			game.shake(4.0)
			Sfx.play("bident_sweep", at, 0.8)
			for pl in game.all_players:
				if DivineWrath._seg_dist(pl.position, at, end) <= hw + pl.radius:
					game.combat.damage_player(float(b["charge_damage_player"]) * mult, BossHades.SRC_GOD, pl)
			game.ally_grid.query(at.lerp(end, 0.5), length * 0.5 + hw + UnitData.MAX_BLOCK_RADIUS, _buf)
			for u: SummonedUnit in _buf:
				if u.active and not u.airborne and DivineWrath._seg_dist(u.position, at, end) <= hw + u.radius:
					game.combat.damage_unit(u, float(b["charge_damage_summon"]) * mult, BossHades.SRC_GOD, boss)
		"volley":
			var reach := float(b["volley_range"])
			var half := float(b["volley_half_arc"])
			for k in 5:
				var q := at + dir.rotated(half * (float(k) - 2.0) * 0.5) * reach * 0.6
				game.effects.pop(q, Palette.PANTHEON_AEGEAN_LIGHT, 10.0)
			Sfx.play("moon_volley", at)
			for pl in game.all_players:
				if CovenantKit.in_sector(at, dir, reach, half, 0.0, pl.position, pl.radius):
					game.combat.damage_player(float(b["volley_damage_player"]) * mult, BossHades.SRC_GOD, pl)
			game.ally_grid.query(at, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
			for u: SummonedUnit in _buf:
				if u.active and not u.airborne and CovenantKit.in_sector(at, dir, reach, half, 0.0, u.position, u.radius):
					game.combat.damage_unit(u, float(b["volley_damage_summon"]) * mult, BossHades.SRC_GOD, boss)


## Starts the finale: he kneels at `pos`, his crown rolls to `to`.
func start_finale(pos: Vector2, to: Vector2) -> void:
	finale_at = game.elapsed
	finale_pos = pos
	crown_to = to + Vector2(0.0, 14.0)
	gods.clear()


## Autopilot hint: out of a telegraphed god lane or cone.
func danger_push(p: Vector2) -> Vector2:
	var b := HadesData.BOSS
	var push := Vector2.ZERO
	for g in gods:
		if bool(g["done"]):
			continue
		var at: Vector2 = g["pos"]
		var dir: Vector2 = g["dir"]
		match String((g["row"] as Dictionary)["attack"]):
			"charge":
				var rel := p - at
				var along := rel.dot(dir)
				var side := rel - dir * along
				if along > -20.0 and along < float(b["charge_length"]) + 20.0 and side.length() < float(b["charge_width"]) * 0.5 + 30.0:
					push += side.normalized() if side.length() > 0.5 else dir.orthogonal()
			"volley":
				if CovenantKit.in_sector(at, dir, float(b["volley_range"]) + 20.0, float(b["volley_half_arc"]) + 0.15, 0.0, p, 12.0):
					var rel := p - at
					push += dir.orthogonal() * (1.0 if rel.cross(dir) < 0.0 else -1.0)
	return push


## Ground layer: the footprints (dark prints edged in pale light, fading).
func _draw() -> void:
	if game == null:
		return
	var t := game.elapsed
	var life := float(HadesData.BOSS["footprint_life"])
	for fp in prints:
		var k := 1.0 - clampf((t - float(fp["t"])) / life, 0.0, 1.0)  # 1 fresh -> 0 gone.
		var dir: Vector2 = fp["dir"]
		var side := dir.orthogonal() * 5.0 * float(fp["side"])
		UnderworldGlyphs.draw_footprint(self, (fp["pos"] as Vector2) + side + Vector2(0.0, 18.0), dir, k)


## Upper layer: the sigils over marked summons, the god shades, the finale.
func _draw_over() -> void:
	if game == null:
		return
	var t := game.elapsed
	if boss != null:
		for m: Array in boss.marks:
			var u: SummonedUnit = m[0]
			if u.active and u.generation == int(m[1]):
				var k := clampf((float(m[2]) - t) / maxf(0.01, float(HadesData.BOSS["mark_time"])), 0.0, 1.0)  # 1 fresh -> 0 taken.
				UnderworldGlyphs.draw_hades_mark(_over, u.position + Vector2(0.0, -u.radius * 2.6), k, t)
	for g in gods:
		var rise := clampf(1.0 - (float(g["t0"]) - t) / maxf(0.01, float(HadesData.BOSS["god_telegraph"])), 0.0, 1.0)  # 0 -> 1 as it gathers.
		var fade := 1.0 if not bool(g["done"]) else clampf((float(g["until"]) - t) / maxf(0.01, float(HadesData.BOSS["god_fade"])), 0.0, 1.0)
		UnderworldGlyphs.draw_god_shade(_over, g["pos"], String(g["key"]), String((g["row"] as Dictionary)["name"]), rise * fade, t)
	if finale_at >= 0.0:
		var e := t - finale_at  # Seconds since he knelt.
		var life := float(HadesData.BOSS["kneel_time"])
		if e < life:
			var a := clampf((life - e) / 2.0, 0.0, 1.0)  # Fades in its last 2 s.
			UnderworldGlyphs.draw_kneeling_hades(_over, finale_pos, a)
			var k := clampf(e / 2.0, 0.0, 1.0)  # The crown's roll (2 s).
			var at := finale_pos.lerp(crown_to, k) + Vector2(0.0, -12.0 * sin(k * PI))
			UnderworldGlyphs.draw_crown(_over, at, a)
