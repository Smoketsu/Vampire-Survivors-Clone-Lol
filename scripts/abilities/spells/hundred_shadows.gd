## HundredShadows — the Hundred Shadows spell (AbilityData "hundred_shadows";
## Act V, the Burning Province; owner-approved Act V proposal "Rewards": "shadow
## clones of the necromancer that echo your next spell cast"). Unlocked by
## slaying Kage (UnlockData), then offered on every stage; driven by
## NecroSpellBook's one dispatch (PROVINCE_IDS) with its EFFECTIVE stats
## (AbilityManager.spell_stats(): Soul Conduit, Abyssal Focus...).
##   * Every `cooldown` s (start to start; AbilityData.SPELL_RETRY while no foe
##     is within `range` px) `clones` shadow clones of the necromancer step out
##     of his shadow to posts HundredShadowsData.POST_RADIUS px around him and
##     follow him there for `life` s. Each throws a SHADOW KUNAI at once at the
##     foe nearest to it (its own blow: the spell works alone, as the Grave
##     Kunoichi's starting spell).
##   * THE ECHO (own decision on "echo your next spell cast": a spell's cast is
##     known by its first hit): each clone holds `echoes` echo charges (1; more
##     once evolved). The necromancer's next SPELL HIT (any spell's damage,
##     HundredShadowsData.is_spell_source(), reported once per hit by
##     CombatResolver.damage_enemy() through NecroSpellBook.on_spell_hit()) is
##     echoed: every clone with a charge throws a shadow kunai at that hit's
##     foe (or the foe nearest to the clone within `range` when it is out of
##     reach), dealing `damage` + `echo_share` x the hit's damage; a clone echoes
##     at most once every HundredShadowsData.ECHO_GAP s.
##   * A kunai flies HundredShadowsData.FLIGHT s and strikes through
##     CombatResolver.damage_enemy() as a SHOT from its clone's post (its
##     origin: a clone behind a foe strikes it from behind, Mortal Heel and
##     the phalanx fronts read it).
##   * The Grave Kunoichi's innate (CharacterData "shadow_extra_clones"): more
##     clones.
## Evolved into Thousand Shadows (EvolutionData "thousand_shadows", detected by
## the "burst_radius" key): more clones that echo several times, and every
## clone bursts into a ring of shadow blades when its life ends or the next
## clones replace it (burst_share x damage to every foe within burst_radius px).
## Drawn as the necromancer's own sprite in violet-black shadow at each post,
## the kunai as short violet streaks. Deterministic: no RNG (targets by
## distance, then spawn order). Stats: shadow_splits, shadow_clones,
## shadow_kunai, shadow_echoes, shadow_hits, shadow_bursts, shadow_kills,
## kunoichi_extra_clones.
class_name HundredShadows
extends NecroSpell

## One shadow clone at its post.
class Clone:
	extends RefCounted
	## Offset of its post from the necromancer (px).
	var offset: Vector2 = Vector2.ZERO
	## Seconds it still stands.
	var life: float = 0.0
	## Seconds it stands in all (its look fades in and out with it).
	var life_total: float = 1.0
	## Echo charges left.
	var echoes: int = 0
	## Seconds until it may echo again.
	var gap: float = 0.0

## One shadow kunai in flight (pooled through `_pool`).
class Kunai:
	extends RefCounted
	## Its target.
	var target: Enemy = null
	## Generation of `target` when it was thrown (stale / death guard).
	var gen: int = 0
	## Where it left the clone (world px; the hit's origin).
	var from: Vector2 = Vector2.ZERO
	## Seconds flown.
	var t: float = 0.0
	## Damage of its strike.
	var damage: float = 0.0
	## Damage source tag.
	var source: String = ""
	## Its current position (world px; drawing).
	var pos: Vector2 = Vector2.ZERO

## Seconds until the next clones may step out.
var _timer: float = HundredShadowsData.FIRST_SPLIT
## The clones standing now.
var _clones: Array[Clone] = []
## Kunai in flight.
var _kunai: Array[Kunai] = []
## Idle Kunai records ready for reuse.
var _pool: Array[Kunai] = []
## Effective stats of the last step (the echo reads them between steps).
var _stats: Dictionary = {}
## Own query buffer of the target search.
var _cand: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false


func _ready() -> void:
	z_index = 3


## Calls the clones on cooldown, ages them, flies the kunai.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _split(stats) else AbilityData.SPELL_RETRY
	var i := 0
	while i < _clones.size():
		var c := _clones[i]
		c.life -= delta
		c.gap -= delta
		if c.life <= 0.0:
			if stats.has("burst_radius"):
				_burst(c, stats)
			_clones.remove_at(i)
			continue
		i += 1
	i = 0
	while i < _kunai.size():
		var k := _kunai[i]
		if _fly(k, delta):
			i += 1
		else:
			_kunai[i] = _kunai[_kunai.size() - 1]
			_kunai.pop_back()
			k.target = null
			_pool.append(k)
	var busy := not _clones.is_empty() or not _kunai.is_empty()  # Something to draw.
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## The clones step out (see the header). False when no foe is in range.
func _split(stats: Dictionary) -> bool:
	var p := game.player.position
	if _nearest(p, float(stats["range"])) == null:
		return false
	var extra := int(game.character.innate_value("shadow_extra_clones"))  # The Grave Kunoichi (0 for everyone else).
	var n := mini(int(stats["clones"]) + extra, HundredShadowsData.MAX_CLONES)
	if extra > 0:
		game.stat_add("kunoichi_extra_clones", float(extra))
	if stats.has("burst_radius"):
		for old in _clones:
			_burst(old, stats)  # Thousand Shadows: the old shadows burst as the new ones step out.
	_clones.clear()
	var turn := float(game.stats.get("shadow_splits", 0.0)) * 0.9  # Each split turns its posts (no RNG).
	for j in n:
		var c := Clone.new()
		c.offset = Vector2.from_angle(turn + TAU * float(j) / float(n)) * HundredShadowsData.POST_RADIUS
		c.life = float(stats["life"])
		c.life_total = c.life
		c.echoes = int(stats.get("echoes", 1))
		c.gap = 0.0
		_clones.append(c)
		var t := _nearest(p + c.offset, float(stats["range"]))
		if t != null:
			_throw(p + c.offset, t, float(stats["damage"]))
	game.stat_add("shadow_splits", 1.0)
	game.stat_add("shadow_clones", float(n))
	game.player.cast_motion(p)  # Engine motion: a pulse as the shadows step out (visual only).
	Sfx.play("bolt_cast", p, 0.7)
	return true


## THE ECHO (NecroSpellBook.on_spell_hit() from CombatResolver.damage_enemy()):
## spell hit `amount` on `e`; every clone with a charge throws at it (see the header).
func on_spell_hit(e: Enemy, amount: float) -> void:
	if _clones.is_empty() or _stats.is_empty():
		return
	var p := game.player.position
	var reach := float(_stats["range"])
	var dmg := float(_stats["damage"]) + float(_stats["echo_share"]) * amount
	for c in _clones:
		if c.echoes <= 0 or c.gap > 0.0:
			continue
		var at := p + c.offset
		var t := e if e.active and at.distance_to(e.position) <= reach + e.radius else _nearest(at, reach)
		if t == null:
			continue
		c.echoes -= 1
		c.gap = HundredShadowsData.ECHO_GAP
		_throw(at, t, dmg)
		game.stat_add("shadow_echoes", 1.0)


## Throws one shadow kunai from `from` at `t` dealing `dmg`.
func _throw(from: Vector2, t: Enemy, dmg: float) -> void:
	if _kunai.size() >= HundredShadowsData.MAX_KUNAI:
		return
	var k: Kunai = Kunai.new() if _pool.is_empty() else _pool.pop_back()
	k.target = t
	k.gen = t.generation
	k.from = from
	k.pos = from
	k.t = 0.0
	k.damage = dmg
	k.source = HundredShadowsData.EVOLVED_SOURCE if _stats.has("burst_radius") else HundredShadowsData.SOURCE
	_kunai.append(k)
	game.stat_add("shadow_kunai", 1.0)


## Flies kunai `k`; it strikes when its flight ends. False when it is spent.
func _fly(k: Kunai, delta: float) -> bool:
	if not k.target.active or k.target.generation != k.gen:
		return false  # The foe fell first: the kunai fades.
	k.t += delta
	var f := clampf(k.t / HundredShadowsData.FLIGHT, 0.0, 1.0)
	k.pos = k.from.lerp(k.target.position, f)
	if f < 1.0:
		return true
	var was_alive := k.target.active
	game.combat.damage_enemy(k.target, k.damage, k.source, -1, k.from, true)
	game.stat_add("shadow_hits", 1.0)
	if was_alive and not k.target.active:
		game.stat_add("shadow_kills", 1.0)
	return false


## Thousand Shadows: a clone whose life ends bursts into a ring of shadow blades.
func _burst(c: Clone, stats: Dictionary) -> void:
	var at := game.player.position + c.offset
	var n := damage_area(at, float(stats["burst_radius"]), float(stats["damage"]) * float(stats["burst_share"]), HundredShadowsData.EVOLVED_SOURCE)
	game.stat_add("shadow_bursts", 1.0)
	game.stat_add("shadow_burst_hits", float(n))
	game.effects.ring(at, float(stats["burst_radius"]), HundredShadowsData.GLOW, 0.3)


## The live foe nearest to `at` within `reach` px (null = none).
func _nearest(at: Vector2, reach: float) -> Enemy:
	game.enemy_grid.query(at, reach + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var best: Enemy = null
	var best_d := INF
	for e: Enemy in _cand:
		if not is_open_target(e) or e.untargetable:
			continue
		var d := at.distance_to(e.position)
		if d <= reach + e.radius and d < best_d:
			best_d = d
			best = e
	return best


func summary_extra() -> String:
	var st := game.stats
	return "splits=%d clones=%d kunai=%d echoes=%d hits=%d kills=%d bursts=%d" % [int(st.get("shadow_splits", 0.0)), int(st.get("shadow_clones", 0.0)),
		int(st.get("shadow_kunai", 0.0)), int(st.get("shadow_echoes", 0.0)), int(st.get("shadow_hits", 0.0)), int(st.get("shadow_kills", 0.0)),
		int(st.get("shadow_bursts", 0.0))]


## The clones (the necromancer's sprite in shadow, fading in and out) and the
## kunai's violet streaks. Visual only.
func _draw() -> void:
	var p := caster_pos()
	var cid := game.character.id if game.character != null else CharacterData.DEFAULT_ID
	var key := String((CharacterData.CHARACTERS.get(cid, {}) as Dictionary).get("sprite", "player/necromancer"))  # The caster's own art.
	for c in _clones:
		var k := clampf(minf(c.life, c.life_total - c.life) / 0.25, 0.0, 1.0)  # Fade in / out (0.25 s).
		var tint := Color(HundredShadowsData.TINT.r, HundredShadowsData.TINT.g, HundredShadowsData.TINT.b, HundredShadowsData.TINT.a * k)
		if not SpriteBank.draw(self, key, p + c.offset, false, tint):
			SpriteBank.draw_disc(self, p + c.offset, 9.0, tint)
	for kn in _kunai:
		var d := (kn.pos - kn.from).normalized() if kn.pos.distance_to(kn.from) > 0.5 else Vector2.RIGHT
		draw_line(kn.pos - d * 9.0, kn.pos, Color(HundredShadowsData.GLOW, 0.8), 2.0)
		SpriteBank.draw_disc(self, kn.pos, 2.0, Color(0.87, 0.74, 1.0))
