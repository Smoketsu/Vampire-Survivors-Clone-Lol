## DrawCuts — THE DRAW (iaijutsu), the second of the Shogunate's shared rules
## (Act V; GDD §15.0 "The Draw"; owner-approved proposal: "Samurai elites stop,
## hand on the hilt, and a thin white line flashes from them for 0.8 s; then one
## cut hits every body on the line (summons or the necromancer)"), owned by
## Game.shogunate. The melee cousin of Act III's LockOn, built the same way. THE
## one path of every Draw line:
##   draw(source, from, dir, opts) starts a line (false when refused), and the
##   line then lives here:
##   * flashing: a thin white line from `from` along `dir` for `flash` s (it does
##     not track: step out of it, Grave Step through it, or let it cut a summon);
##   * cut: one cut hits EVERY body on the line, the necromancer (co-op: either)
##     and every summon, through CombatResolver (damage_player(),
##     damage_unit()); Warriors physically block nothing here. The drawer then
##     dashes `dash` of the way along the line (never through an obstacle);
##   * cancelled: the drawer died or was pooled before the cut; while it is
##     frozen or stunned its line waits with it.
## At most DRAW max_lines lines flash at once; a draw beyond it is refused
## (counted; the samurai retries). BOSS OVERRIDE (documented for phase 2: the
## Shogun's iai duel, faster cuts and a triple cut of three lines at once):
## opts "boss_override" true ignores max_lines (up to boss_max_lines) and lets
## one drawer flash several lines; opts "flash" sets a faster cut.
## opts keys (all optional; absent = ShogunateRulesData.DRAW):
##   flash, length, width, dmg_player, dmg_summon (base damage: x the enemies'
##   damage scaling and the drawer's Enemy.hit_mult() at the cut), dash,
##   boss_override (bool), tag (the damage source; default the drawer's kind,
##   else "draw_cut").
## UNBENDING hook (the future Act V counter-passive; not built in phase 1):
## unbending_mult() cuts the damage a summon takes (exactly 1 while the passive
## does not exist).
## Lines are stored in packed arrays (no nodes, no instance ids), the drawer
## guarded by its pooling generation. Drawn above the night's darkness (z 19):
## thin and white, brighter as the cut nears. Stats: draw_lines,
## draw_on_player, draw_refused, draw_cancelled, draw_cuts, draw_cut_you,
## draw_dodged, draw_cut_<summon class>, draw_dmg_summons, draw_dmg_you.
class_name DrawCuts
extends Node2D

## Owning run.
var game: Game
## Flashing lines now (indices [0, count) of every array below).
var count: int = 0
## Most lines flashing at once this run (the autotest's "the draw" line).
var peak: int = 0
## Drawer of each line (null for a free-standing line: then never cancelled).
var _owner: Array[Enemy] = []
## Generation of each drawer when it drew (stale guard).
var _owner_gen: PackedInt32Array = PackedInt32Array()
## Start point (world px) of each line.
var _from: PackedVector2Array = PackedVector2Array()
## Unit direction of each line.
var _dir: PackedVector2Array = PackedVector2Array()
## Seconds each line has flashed.
var _time: PackedFloat32Array = PackedFloat32Array()
## Flash time (s) of each line before its cut.
var _flash: PackedFloat32Array = PackedFloat32Array()
## Length (px) of each line.
var _len: PackedFloat32Array = PackedFloat32Array()
## Cut width (px) of each line.
var _width: PackedFloat32Array = PackedFloat32Array()
## Base damage to the necromancer of each line's cut.
var _dmg_p: PackedFloat32Array = PackedFloat32Array()
## Base damage to each summon of each line's cut.
var _dmg_s: PackedFloat32Array = PackedFloat32Array()
## Share (0..1) of each line the drawer dashes along with the cut.
var _dash: PackedFloat32Array = PackedFloat32Array()
## Damage tag of each line's cut.
var _src: PackedStringArray = PackedStringArray()
## 1 when a necromancer stood on the line as it began (the bot's "dodged" count).
var _aimed: PackedByteArray = PackedByteArray()
## Hard cap on lines (DRAW boss_max_lines).
var _cap: int = 0
## Recent cuts drawn as a fading white slash: [a, b, until (game s)] each.
var _slashes: Array = []
## Bodies struck by the current cut (scratch).
var _tmp: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false


## Builds the line store for `p_game` (ShogunateRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "DrawCuts"
	z_index = 19  # Above the night's darkness: the lines must read clearly.
	z_as_relative = false
	_cap = int(ShogunateRulesData.DRAW["boss_max_lines"])
	_owner.resize(_cap)
	_owner_gen.resize(_cap)
	_from.resize(_cap)
	_dir.resize(_cap)
	_time.resize(_cap)
	_flash.resize(_cap)
	_len.resize(_cap)
	_width.resize(_cap)
	_dmg_p.resize(_cap)
	_dmg_s.resize(_cap)
	_dash.resize(_cap)
	_src.resize(_cap)
	_aimed.resize(_cap)


## UNBENDING (the future Act V counter-passive; the one read): the share of a
## Draw cut summon `u` still takes, 1 - PassiveData row UNBENDING's value of the
## player who owns it (co-op: its army's slot). Exactly 1 while the passive does
## not exist.
func unbending_mult(u: SummonedUnit) -> float:
	var ab := game.abilities  # The bound player's passives.
	if game.coop != null and u != null:
		for s in game.coop.slots:
			if s.horde == u.director:
				ab = s.abilities
				break
	return maxf(0.0, 1.0 - ab.passive_value(ShogunateRulesData.UNBENDING, ShogunateRulesData.UNBENDING_KEY))


## THE Draw: starts a line from world point `from` along unit vector `dir`,
## drawn by `source` (an Enemy, or null for a free-standing line), with the
## options `opts` (see the header). Refused (false) when the drawer already
## flashes a line or max_lines flash (unless opts "boss_override").
func draw(source: Enemy, from: Vector2, dir: Vector2, opts: Dictionary = {}) -> bool:
	var boss := bool(opts.get("boss_override", false))  # The boss override.
	if source != null and not boss and has_line(source):
		return false
	var limit := _cap if boss else mini(_cap, int(ShogunateRulesData.DRAW["max_lines"]))  # Lines allowed now.
	if count >= limit:
		game.stat_add("draw_refused", 1.0)
		return false
	var d: Dictionary = ShogunateRulesData.DRAW
	var i := count
	count += 1
	peak = maxi(peak, count)
	_owner[i] = source
	_owner_gen[i] = source.generation if source != null else 0
	_from[i] = from
	_dir[i] = dir.normalized() if dir.length_squared() > 0.0001 else Vector2.RIGHT
	_time[i] = 0.0
	_flash[i] = float(opts.get("flash", d["flash"]))
	_len[i] = float(opts.get("length", d["length"]))
	_width[i] = float(opts.get("width", d["width"]))
	_dmg_p[i] = float(opts.get("dmg_player", d["dmg_player"]))
	_dmg_s[i] = float(opts.get("dmg_summon", d["dmg_summon"]))
	_dash[i] = float(opts.get("dash", d["dash"]))
	_src[i] = String(opts.get("tag", source.kind if source != null else "draw_cut"))
	var aimed := 0
	for pl in game.all_players:
		if _seg_dist(pl.position, from, from + _dir[i] * _len[i]) <= _width[i] * 0.5 + pl.radius:
			aimed = 1
	_aimed[i] = aimed
	game.stat_add("draw_lines", 1.0)
	if aimed == 1:
		game.stat_add("draw_on_player", 1.0)
	game.shogunate.play_sound("draw_flash", from)
	return true


## True while `source` flashes a line.
func has_line(source: Enemy) -> bool:
	for i in count:
		if _owner[i] == source and _owner_gen[i] == source.generation:
			return true
	return false


## Removes line `i` (the last line moves into its slot).
func _remove(i: int) -> void:
	var last := count - 1
	if i != last:
		_owner[i] = _owner[last]
		_owner_gen[i] = _owner_gen[last]
		_from[i] = _from[last]
		_dir[i] = _dir[last]
		_time[i] = _time[last]
		_flash[i] = _flash[last]
		_len[i] = _len[last]
		_width[i] = _width[last]
		_dmg_p[i] = _dmg_p[last]
		_dmg_s[i] = _dmg_s[last]
		_dash[i] = _dash[last]
		_src[i] = _src[last]
		_aimed[i] = _aimed[last]
	_owner[last] = null
	count = last


## Ages every line (ShogunateRules.step()): cancels the lines whose drawer is
## gone, cuts the ones whose flash is over.
func step(delta: float) -> void:
	var i := 0
	while i < count:
		var o := _owner[i]
		if o != null and (not o.active or o.generation != _owner_gen[i]):
			game.stat_add("draw_cancelled", 1.0)  # Killed before the cut.
			_remove(i)
			continue
		if o != null and o.frozen:
			i += 1
			continue  # Held by Stasis, a Deep Freeze or a stun: the line waits.
		_time[i] += delta
		if _time[i] >= _flash[i]:
			_cut(i)
			_remove(i)
			continue
		i += 1
	var t := game.elapsed
	var k := _slashes.size() - 1
	while k >= 0:
		if t >= float(_slashes[k][2]):
			_slashes.remove_at(k)
		k -= 1
	var busy := count > 0 or not _slashes.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Line `i` cuts: every necromancer and every summon on it, then the drawer's dash.
func _cut(i: int) -> void:
	var a := _from[i]
	var b := a + _dir[i] * _len[i]
	var hw := _width[i] * 0.5  # Half the cut's width (px).
	var o := _owner[i]
	var hm := o.hit_mult() if o != null else 1.0  # The drawer's damage multiplier (auras, Dirge).
	var dm := game.enemies.damage_mult * hm  # Damage scaling of this cut.
	var src := _src[i]
	game.stat_add("draw_cuts", 1.0)
	var hit_player := false
	for pl in game.all_players:
		if _seg_dist(pl.position, a, b) <= hw + pl.radius:
			hit_player = true
			var before := pl.hp
			game.combat.damage_player(_dmg_p[i] * dm, src, pl)
			game.stat_add("draw_cut_you", 1.0)
			game.stat_add("draw_dmg_you", maxf(0.0, before - pl.hp))
	if _aimed[i] == 1 and not hit_player:
		game.stat_add("draw_dodged", 1.0)  # It stood on the line as it began, and was off it at the cut.
	var mid := a.lerp(b, 0.5)
	game.ally_grid.query(mid, _len[i] * 0.5 + hw + PantheonRulesData.SUMMON_SLACK, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.DEAD:
			continue
		if _seg_dist(u.position, a, b) > hw + u.radius:
			continue
		var cls := u.unit_class
		var hp0 := u.hp
		game.combat.damage_unit(u, _dmg_s[i] * dm * unbending_mult(u), src)
		game.stat_add("draw_cut_" + cls, 1.0)
		game.stat_add("draw_dmg_summons", maxf(0.0, hp0 - maxf(u.hp, 0.0)))
	_slashes.append([a, b, game.elapsed + 0.18])
	game.shogunate.play_sound("draw_cut", mid)
	game.shake(1.5)
	if o != null and o.active and _dash[i] > 0.0:
		var want := _len[i] * _dash[i]  # How far the drawer dashes (px).
		var go := game.arena.clear_length(o.position, _dir[i], want, o.radius)  # Never through an obstacle.
		o.position += _dir[i] * go
		o.motion_lunge(_dir[i], MotionData.POWER_MELEE)
		o.queue_redraw()


## Distance (px) from `p` to the segment `a`-`b`.
static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


## Autopilot hint (the autotest bot): a push sideways off every flashing line
## passing within its half-width plus DRAW danger_reach px of `p`, stronger as
## the cut nears.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for i in count:
		var a := _from[i]
		var d := _dir[i]
		var along := (p - a).dot(d)  # Distance down the line (px).
		if along < -game.player.radius or along > _len[i] + game.player.radius:
			continue
		var reach := _width[i] * 0.5 + float(ShogunateRulesData.DRAW["danger_reach"]) + game.player.radius  # Danger band (px).
		var side := (p - a) - d * along  # Offset from the line.
		var dist := side.length()
		if dist >= reach:
			continue
		var urgency := clampf(_time[i] / maxf(_flash[i], 0.01), 0.4, 1.0)  # Stronger as it cuts.
		var n := side / dist if dist > 0.01 else d.orthogonal()
		push += n * (1.0 - dist / reach) * 2.5 * urgency
	return push


## Draws every flashing line (thin and white, a glint at its start, thicker
## and brighter as the cut nears) and every fresh cut (a bright fading slash).
## On game time. Visual only.
func _draw() -> void:
	for i in count:
		var a := _from[i]
		var b := a + _dir[i] * _len[i]
		var k := clampf(_time[i] / maxf(_flash[i], 0.01), 0.0, 1.0)  # 0 drawn .. 1 cut.
		var blink := k > 0.7 and fmod(game.elapsed * 14.0, 1.0) < 0.5  # The last moment blinks.
		draw_line(a, b, Color(Palette.SHOGUN_INDIGO_DARK, 0.35), 3.0 + 2.0 * k)
		draw_line(a, b, Color(1.0, 1.0, 1.0, 0.55 + 0.4 * k if not blink else 1.0), 1.0 + 1.0 * k)
		SpriteBank.draw_disc(self, a, 2.5 + 2.0 * k, Color(1.0, 1.0, 1.0, 0.9))  # The blade's glint at the hilt.
	var t := game.elapsed
	for s: Array in _slashes:
		var left := clampf((float(s[2]) - t) / 0.18, 0.0, 1.0)  # Fades out.
		draw_line(s[0], s[1], Color(Palette.SHOGUN_LACQUER_LIGHT, 0.5 * left), 6.0 * left + 1.0)
		draw_line(s[0], s[1], Color(1.0, 1.0, 1.0, left), 3.0 * left + 1.0)
