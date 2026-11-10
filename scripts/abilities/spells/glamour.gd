## Glamour — the GLAMOUR spell (AbilityData "glamour"; temporary Act XV, the Fae
## Court; GDD §15.0 "Glamour, Court of Masks, Changeling and the Changeling
## Princess"; owner-approved proposal: "illusory copies of the necromancer draw
## enemy attacks"). Unlocked by slaying the Summer Queen (UnlockData), then
## offered on every stage; driven by NecroSpellBook's one dispatch
## (FAE_COURT_IDS, stepped only) with its EFFECTIVE stats
## (AbilityManager.spell_stats(): the shattering's reach is the row's "radius",
## so every spell-area modifier widens it).
##   * Every `cooldown` s, once a foe stands within `range` px, `copies`
##     ILLUSORY COPIES of the necromancer step out of him to posts
##     GlamourData.POST_RADIUS px round him (turning with each cast). Each is a
##     temporary summon (HordeDirector.spawn_temporary(), the one path, so
##     Restless Dead and the Grave Herald's Restless lengthen it too) of
##     GlamourData.COPY_CLASS with `hp` x that class's HP, living `life` s,
##     drawn as the caster's own art in the glamour's light (glyph kind
##     GlamourData.GLYPH_PREFIX + his sprite key). It never strikes (its blows
##     wait GlamourData.NO_BLOWS s and deal nothing); it DRAWS ENEMY ATTACKS: a
##     taunt reach of `taunt` px (its special's taunt_radius, read by
##     ColossusKit.refresh(), the one taunt path) and the Warrior's blocking body.
##   * When a copy falls or fades it SHATTERS: every foe within `radius` px takes
##     `damage` (CombatResolver.damage_enemy()).
##   * Changeling (its paired passive, PassiveData "changeling", read only
##     here): + copy_life s and x 1 + copy_hp on every copy.
##   * The Changeling Princess's Many Faces (CharacterData "glamour_copies"):
##     copies more in every cast (0 for every other character).
## Evolved into COURT OF MASKS (EvolutionData "court_of_masks", detected by the
## "bewilder" key): more and sturdier copies, and each shattering also
## bewilders the foes it strikes for `bewilder` s (CombatResolver.weaken_enemy(),
## the one debuff path: BEWILDER_SLOW slower, BEWILDER_CUT weaker; half on
## bosses and minibosses).
## Deterministic: no RNG; copies generation-checked. Stats: glamour_casts,
## glamour_copies, glamour_shatters, glamour_hits, glamour_innate_copies,
## glamour_taunts (ColossusKit.taunt_stat()); damage as dmg_glamour /
## dmg_court_of_masks.
class_name Glamour
extends NecroSpell

## Slow (0..1) a Court of Masks shattering lays on each foe it strikes.
const BEWILDER_SLOW: float = 0.3  # TUNING (not in GDD)
## Damage cut (0..1) a Court of Masks shattering lays on each foe it strikes.
const BEWILDER_CUT: float = 0.2  # TUNING (not in GDD)
## Share of the bewildering a boss or a miniboss takes.
const BEWILDER_BOSS: float = 0.5  # TUNING (not in GDD)

## Seconds until the next cast may start.
var _cd: float = 0.0
## Casts so far (each turns the posts a little).
var _casts: int = 0
## Copies standing: [SummonedUnit, generation, last position (Vector2)] each.
var _copies: Array = []
## Shatters still showing: [position (Vector2), game s it began] each (drawing only).
var _bursts: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false
## px of the shattering's reach (the last step's effective "radius"; for drawing).
var _radius: float = 50.0


func _ready() -> void:
	z_index = 3


## Casts on the cooldown; watches its copies and shatters the fallen.
func step(delta: float, stats: Dictionary) -> void:
	_radius = float(stats["radius"])
	_watch(stats)
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var i := 0
	while i < _bursts.size():
		if game.elapsed - float(_bursts[i][1]) > 0.3:
			_bursts.remove_at(i)
		else:
			i += 1
	var busy := not _bursts.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One cast: the copies step out round him. Returns false when no foe is near
## (the spell then waits) or the copies already stand at their most.
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # The necromancer.
	if _nearest_foe(p, float(stats["range"])) == null:
		return false
	var extra := int(game.character.innate_value(GlamourData.INNATE_KEY))
	var n := mini(int(stats["copies"]) + extra, GlamourData.MAX_COPIES - _copies.size())
	if n <= 0:
		return false
	var life := float(stats["life"]) + game.abilities.passive_value(GlamourData.CHANGELING, GlamourData.LIFE_KEY)
	var hp := float(stats["hp"]) * (1.0 + game.abilities.passive_value(GlamourData.CHANGELING, GlamourData.HP_KEY))
	var cid := game.character.id if game.character != null else CharacterData.DEFAULT_ID
	var key := String((CharacterData.CHARACTERS.get(cid, {}) as Dictionary).get("sprite", "player/necromancer"))  # The caster's own art.
	var src := GlamourData.EVOLVED_SOURCE if stats.has("bewilder") else GlamourData.SOURCE
	var turn := float(_casts) * 0.6
	_casts += 1
	for k in n:
		var at := p + Vector2.from_angle(turn + TAU * float(k) / float(n)) * GlamourData.POST_RADIUS
		var u := game.horde.spawn_temporary(GlamourData.COPY_CLASS, at, life, hp, 0.0)
		if u == null:
			continue
		u.glyph_kind = GlamourData.GLYPH_PREFIX + key
		u.dmg_source = src
		u.attack_cd = GlamourData.NO_BLOWS  # An illusion never strikes.
		u.bash_damage = 0.0
		u.special["taunt_radius"] = float(stats["taunt"])  # It draws the foes round it (ColossusKit).
		_copies.append([u, u.generation, u.position])
		game.stat_add("glamour_copies", 1.0)
	game.stat_add("glamour_casts", 1.0)
	if extra > 0:
		game.stat_add("glamour_innate_copies", float(extra))
	Sfx.play("lance_cast", p, GlamourData.CAST_PITCH)  # A startup-bank sound: the spell plays on every stage.
	return true


## The foe nearest `p` within `reach` px (null when none).
func _nearest_foe(p: Vector2, reach: float) -> Enemy:
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, _tmp)
	var best: Enemy = null
	var best_d := INF
	for e: Enemy in _tmp:
		if not e.active or e.untargetable or e.civilian:
			continue
		var dd := p.distance_to(e.position) - e.radius
		if dd <= reach and dd < best_d:
			best_d = dd
			best = e
	return best


## Each copy's place is remembered; a copy that fell or faded shatters there.
func _watch(stats: Dictionary) -> void:
	var i := 0
	while i < _copies.size():
		var c: Array = _copies[i]
		var u: SummonedUnit = c[0]
		if u.active and u.generation == int(c[1]) and u.state != SummonedUnit.State.DEAD:
			c[2] = u.position
			i += 1
			continue
		_copies.remove_at(i)
		_shatter(c[2], stats)


## A copy shatters at `at` (see the header).
func _shatter(at: Vector2, stats: Dictionary) -> void:
	var evolved := stats.has("bewilder")
	var src := GlamourData.EVOLVED_SOURCE if evolved else GlamourData.SOURCE
	var r := float(stats["radius"])
	var hits: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, hits)
	var n := 0
	for e: Enemy in hits:
		if not e.active or e.untargetable or e.civilian or e.position.distance_to(at) > r + e.radius:
			continue
		game.combat.damage_enemy(e, float(stats["damage"]), src)
		n += 1
		if evolved and e.active:
			game.combat.weaken_enemy(e, BEWILDER_SLOW, BEWILDER_CUT, float(stats["bewilder"]), BEWILDER_BOSS, false)
	game.stat_add("glamour_shatters", 1.0)
	game.stat_add("glamour_hits", float(n))
	_bursts.append([at, game.elapsed])


## Autotest counters (FaeCourtReport's Glamour line).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d copies=%d shatters=%d hits=%d taunts=%d innate_copies=%d" % [int(st.get("glamour_casts", 0.0)),
		int(st.get("glamour_copies", 0.0)), int(st.get("glamour_shatters", 0.0)), int(st.get("glamour_hits", 0.0)),
		int(st.get("glamour_taunts", 0.0)), int(st.get("glamour_innate_copies", 0.0))]


## The shatterings (a ring of violet-pink glass shards flying out). Visual only:
## rects and disc textures, in world axes (the spell node sits at the origin).
func _draw() -> void:
	for b: Array in _bursts:
		var at: Vector2 = b[0]
		var k := clampf((game.elapsed - float(b[1])) / 0.3, 0.0, 1.0)
		SpriteBank.draw_disc(self, at, _radius * (0.4 + 0.6 * k), Color(GlamourData.SHATTER, 0.25 * (1.0 - k)))
		for j in 8:
			var d := Vector2.from_angle(TAU * float(j) / 8.0)
			draw_rect(Rect2(at + d * _radius * k - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(GlamourData.SHATTER, 1.0 - k))  # A shard.
