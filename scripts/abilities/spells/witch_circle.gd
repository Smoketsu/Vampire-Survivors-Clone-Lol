## WitchCircle — the Hex Circle spell (AbilityData "witch_circle"; Act VII, the
## Witchwood; GDD §15.0 "Hex Circle, Witches' Sabbath, Moonlit Rite and the
## Hedge Witch (Act VII)"; owner-approved proposal: "Hex Circle: a crimson
## circle under the necromancer that drains every enemy inside"; unlocked by
## slaying Isolde, then offered on every stage at the later-item card weight).
## A crimson circle of `radius` px (x 1 + the Hedge Witch's Hedge Lore, innate
## value witch_circle_radius) follows the necromancer. Every `cooldown` s it
## DRAINS: `damage` to every foe inside (CombatResolver.damage_enemy(), tag
## witch_circle), and the necromancer heals `drain` x the damage it dealt,
## never more than `heal_cap` HP per second (a leaky budget banking at most
## WitchCircleData.BUDGET_SECONDS of it; through CombatResolver.heal_player(),
## the one heal path). Evolved into WITCHES' SABBATH (EvolutionData
## "witches_sabbath", detected by the "sabbath_circles" key): the circle grows,
## and `sabbath_circles` smaller circles of `sabbath_radius` px orbit it
## `sabbath_orbit` px out at `sabbath_speed` rad/s, each draining like the
## first (tag witches_sabbath). MOONLIT RITE (the paired passive) is read by
## CombatResolver.damage_enemy() through in_circle() below. Pulses cost nothing
## when no foe is inside (no cooldown wasted). Works the same on every stage.
## Determinism: no RNG; the orbit turns on game time. Stats: witch_circle_pulses,
## witch_circle_hits, witch_circle_healed, sabbath_hits; damage as
## dmg_witch_circle / dmg_witches_sabbath.
class_name WitchCircle
extends NecroSpell

## Seconds until the next pulse.
var _timer: float = 0.4
## Heal HP still allowed by the per-second cap.
var _budget: float = 0.0
## The main circle's radius now (px; drawing, in_circle()).
var _radius: float = 0.0
## True once Witches' Sabbath (drawing, in_circle()).
var _sabbath: bool = false
## Orbiting circles' centres (world px; drawing, in_circle()).
var _sats: PackedVector2Array = PackedVector2Array()
## Orbiting circles' radius (px).
var _sat_r: float = 0.0
## 1 right after a pulse, fading to 0 (drawing).
var _flash: float = 0.0
## Own query buffer for the pulse (kills may query the grid too).
var _hit: Array = []


func _ready() -> void:
	z_index = -3


## Accrues the heal budget, moves the orbit, pulses on cooldown.
func step(delta: float, stats: Dictionary) -> void:
	_sabbath = stats.has("sabbath_circles")
	var wide := 1.0 + game.character.innate_value(WitchCircleData.RADIUS_KEY)  # Hedge Lore (0 for every other character).
	_radius = float(stats["radius"]) * wide
	var cap := float(stats["heal_cap"])  # HP/s.
	_budget = minf(_budget + cap * delta, cap * WitchCircleData.BUDGET_SECONDS)
	_flash = maxf(0.0, _flash - delta / WitchCircleData.FLASH_FADE)
	var p := game.player.position
	_sats = PackedVector2Array()
	if _sabbath:
		_sat_r = float(stats["sabbath_radius"]) * wide
		var n := int(stats["sabbath_circles"])
		var turn := game.elapsed * float(stats["sabbath_speed"])
		for i in n:
			_sats.append(p + Vector2.from_angle(turn + TAU * float(i) / float(n)) * float(stats["sabbath_orbit"]) * wide)
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"])
		_pulse(stats)
	queue_redraw()  # The circle follows the necromancer.


## One drain: every foe inside a circle takes the damage once per circle; the
## necromancer drinks a share of it.
func _pulse(stats: Dictionary) -> void:
	var dealt := 0.0
	var hits := _drain(game.player.position, _radius, float(stats["damage"]), WitchCircleData.EVOLVED_SOURCE if _sabbath else WitchCircleData.SOURCE)
	dealt += hits.y
	for c in _sats:
		var h := _drain(c, _sat_r, float(stats["damage"]), WitchCircleData.EVOLVED_SOURCE)
		dealt += h.y
		game.stat_add("sabbath_hits", h.x)
	if dealt <= 0.0:
		return
	game.stat_add("witch_circle_pulses", 1.0)
	_flash = 1.0
	var want := minf(dealt * float(stats["drain"]), _budget)  # Heal allowed this pulse.
	if want > 0.0:
		var healed := game.combat.heal_player(want)  # HP the necromancer took.
		_budget -= healed
		game.stat_add("witch_circle_healed", healed)


## Damages every open foe within `r` px of `c` for `dmg` (tag `src`). Returns
## (hits, damage dealt).
func _drain(c: Vector2, r: float, dmg: float, src: String) -> Vector2:
	game.enemy_grid.query(c, r + ProjectileManager.MAX_BODY_RADIUS, _hit)
	var victims: Array[Enemy] = []  # Own copy: damage may trigger kill hooks.
	for e: Enemy in _hit:
		if is_open_target(e) and e.position.distance_to(c) <= r + e.radius * 0.5:
			victims.append(e)
	var dealt := 0.0
	for e in victims:
		if e.active:
			dealt += game.combat.damage_enemy(e, dmg, src)
	game.stat_add("witch_circle_hits", float(victims.size()))
	return Vector2(float(victims.size()), dealt)


## True when world point `p` (a body of radius `r`) stands inside one of the
## spell's circles now.
func inside(p: Vector2, r: float) -> bool:
	if p.distance_to(caster_pos()) <= _radius + r * 0.5:
		return true
	for c in _sats:
		if p.distance_to(c) <= _sat_r + r * 0.5:
			return true
	return false


## MOONLIT RITE's circle test (CombatResolver.damage_enemy(), the one read):
## true when foe `e` stands inside one of the bound necromancer's hex circles.
static func in_circle(g: Game, e: Enemy) -> bool:
	var node: NecroSpell = g.abilities.spells.nodes.get(WitchCircleData.ID)  # The spell's node, if it ever stepped.
	return node is WitchCircle and g.abilities.spell_level(WitchCircleData.ID) > 0 and (node as WitchCircle).inside(e.position, e.radius)


## Autotest counters (WitchwoodReport's Hex Circle line).
func summary_extra() -> String:
	var st := game.stats
	return "pulses=%d hits=%d (sabbath %d) healed=%d radius=%d" % [int(st.get("witch_circle_pulses", 0.0)), int(st.get("witch_circle_hits", 0.0)),
		int(st.get("sabbath_hits", 0.0)), int(st.get("witch_circle_healed", 0.0)), int(_radius)]


## The crimson circle (a faint fill, the Court's ring, six turning runes) and
## the Sabbath's orbiting circles. Textures only. Visual only.
func _draw() -> void:
	if game == null:
		return
	var c := caster_pos()
	var t := game.elapsed
	_circle(c, _radius, t)
	for s in _sats:
		_circle(s, _sat_r, -t * 1.3)


## One circle at `c` of radius `r`, its runes turned by `turn` rad.
func _circle(c: Vector2, r: float, turn: float) -> void:
	if r <= 0.0:
		return
	SpriteBank.draw_disc(self, c, r, Color(Palette.COURT_BLOOD, 0.10 + 0.10 * _flash))
	draw_texture_rect(CourtGlyphs.ring_texture(), Rect2(c - Vector2(r, r) / 0.9, Vector2(r, r) * 2.0 / 0.9), false, Color(Palette.COURT_BLOOD_LIGHT, 0.55 + 0.35 * _flash))
	if _sabbath:
		draw_texture_rect(CourtGlyphs.ring_texture(), Rect2(c - Vector2(r, r) * 0.7 / 0.9, Vector2(r, r) * 1.4 / 0.9), false, Color(Palette.GOLD, 0.35))
	for n in 6:
		var p := c + Vector2.from_angle(turn + TAU * float(n) / 6.0) * r * 0.85
		SpriteBank.draw_disc(self, p, 2.5, Color(Palette.COURT_BLOOD_LIGHT, 0.8))
