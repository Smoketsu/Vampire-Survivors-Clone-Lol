## BoneMines — the Bone Mines spell (AbilityData "bone_mines"; Act VIII, Fort
## Kessler; GDD §15.0 "Bone Mines, Killing Ground, Tripwire and the Fallen
## Sergeant (Act VIII)"; owner-approved proposal: "bone mines dropped along the
## necromancer's path, triggered by enemies"; unlocked by slaying General
## Harrow, then offered on every stage at the later-item card weight). Every
## `cooldown` s, once the necromancer stands at least `spacing` px from every
## bone mine already laid, a BONE MINE drops where he stands (plus the Fallen
## Sergeant's Sapper's Hands, innate value bone_mines_extra: more mines beside
## it), at most `max_mines` laid (the oldest crumbles), each lasting `life` s.
## A mine arms in BoneMinesData.ARM_TIME s; then the first ENEMY within
## `trigger` px (its body counts; never a summon, never a flier or a body that
## phases over the ground) sets it off at once: `damage` to every enemy within
## `radius` px (NecroSpell.damage_area(), CombatResolver.damage_enemy()). Summons
## never set it off and never take its damage. Evolved into KILLING GROUND
## (EvolutionData "killing_ground", detected by the "shards" key): bigger,
## harder mines, and each blast throws `shards` bone shards outward that land
## `shard_reach` px off on a ring and hit every enemy within `shard_radius` px
## for shard_share x the damage. TRIPWIRE (the paired passive) widens every
## mine's trigger by trip_reach px and slows every foe caught in a blast by
## trip_slow for BoneMinesData.TRIP_SLOW_TIME s (CombatResolver.slow_enemy(),
## the one slow path). Works the same on every stage (no act rule).
## Determinism: no RNG; the mines are checked in the order they were laid.
## Stats: bone_mines_laid, bone_mines_extra, bone_mines_blown,
## bone_mines_hits, bone_mines_expired, bone_mines_shards, tripwire_slowed;
## damage as dmg_bone_mines / dmg_killing_ground / dmg_killing_ground_shards.
class_name BoneMines
extends NecroSpell

## World position of each laid mine.
var _pos: PackedVector2Array = PackedVector2Array()
## Game time (s) each was laid.
var _born: PackedFloat32Array = PackedFloat32Array()
## Blasts fading (drawn only): {at, t (game s), r, evolved}.
var _fading: Array[Dictionary] = []
## Seconds until the next drop.
var _cd: float = 0.0
## Seconds toward the next trigger check.
var _check_acc: float = 0.0
## The current effective stats (the last step's row).
var _stats: Dictionary = {}
## True once Killing Ground (drawing).
var _evolved: bool = false
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Drops mines on its cooldown; checks the triggers; crumbles old mines.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	_evolved = stats.has("shards")
	var now := game.elapsed
	var life := float(stats["life"])
	var i := 0
	while i < _pos.size():
		if now >= _born[i] + life:
			_remove(i)
			game.stat_add("bone_mines_expired", 1.0)
			continue
		i += 1
	i = 0
	while i < _fading.size():
		if now >= float(_fading[i]["t"]) + BoneMinesData.FADE_TIME:
			_fading.remove_at(i)
			continue
		i += 1
	_check_acc += delta
	if _check_acc >= BoneMinesData.CHECK_EVERY:
		_check_acc = 0.0
		_trigger()
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _drop(stats) else BoneMinesData.WAIT_RETRY
	var busy := not _pos.is_empty() or not _fading.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## One drop where the necromancer stands (and the Fallen Sergeant's extra
## mines beside it). False while he stands within `spacing` px of a mine.
func _drop(stats: Dictionary) -> bool:
	var at := game.player.position
	var spacing := float(stats["spacing"])
	for p in _pos:
		if p.distance_to(at) < spacing:
			return false
	var extra := roundi(game.character.innate_value(BoneMinesData.EXTRA_MINES_KEY))
	var side := Vector2.RIGHT
	if game.player.velocity.length() > 1.0:
		side = game.player.velocity.normalized().orthogonal()
	_lay(at, int(stats["max_mines"]))
	for k in extra:
		var sgn := 1.0 if (k % 2) == 0 else -1.0
		_lay(at + side * sgn * BoneMinesData.PAIR_OFFSET * float(1 + k / 2), int(stats["max_mines"]))
	game.stat_add("bone_mines_laid", float(1 + extra))
	if extra > 0:
		game.stat_add("bone_mines_extra", float(extra))
	return true


## Lays one mine at `at` (the oldest crumbles past `cap`).
func _lay(at: Vector2, cap: int) -> void:
	while _pos.size() >= maxi(1, cap):
		_remove(0)
	_pos.append(at)
	_born.append(game.elapsed)


## Drops mine `i`.
func _remove(i: int) -> void:
	_pos.remove_at(i)
	_born.remove_at(i)


## THE TRIGGER: each armed mine with an enemy's foot on it goes off.
func _trigger() -> void:
	if _pos.is_empty():
		return
	var now := game.elapsed
	var reach := float(_stats["trigger"]) + game.abilities.passive_value(BoneMinesData.TRIPWIRE, BoneMinesData.TRIP_REACH_KEY)
	var i := 0
	while i < _pos.size():
		if now < _born[i] + BoneMinesData.ARM_TIME:
			i += 1
			continue
		var at := _pos[i]
		var hit := false
		game.enemy_grid.query(at, reach + ProjectileManager.MAX_BODY_RADIUS, _tmp)
		for e: Enemy in _tmp:
			if e.active and not e.flies and not e.phases_obstacles and e.position.distance_to(at) <= reach + e.radius:
				hit = true
				break
		if hit:
			_remove(i)
			_blow(at)
			continue
		i += 1


## A mine blows at `at`: its blast, Tripwire's slow, Killing Ground's shards.
func _blow(at: Vector2) -> void:
	var r := float(_stats["radius"])
	var dmg := float(_stats["damage"])
	var src := BoneMinesData.EVOLVED_SOURCE if _evolved else BoneMinesData.SOURCE
	game.stat_add("bone_mines_blown", 1.0)
	game.stat_add("bone_mines_hits", float(damage_area(at, r, dmg, src)))
	var slow := game.abilities.passive_value(BoneMinesData.TRIPWIRE, BoneMinesData.TRIP_SLOW_KEY)
	if slow > 0.0:
		var caught: Array = []  # Own buffer.
		game.enemy_grid.query(at, r + ProjectileManager.MAX_BODY_RADIUS, caught)
		for e: Enemy in caught:
			if e.active and e.position.distance_to(at) <= r + e.radius:
				game.combat.slow_enemy(e, slow, BoneMinesData.TRIP_SLOW_TIME)
				game.stat_add("tripwire_slowed", 1.0)
	_fading.append({"at": at, "t": game.elapsed, "r": r, "evolved": _evolved})
	game.effects.ring(at, r, Palette.BONE, 0.25)
	if _evolved:
		var n := int(_stats["shards"])
		var reach := float(_stats["shard_reach"])
		var sr := float(_stats["shard_radius"])
		var sd := dmg * float(_stats["shard_share"])
		for k in n:
			var p := at + Vector2.from_angle(TAU * float(k) / float(maxi(1, n))) * reach
			damage_area(p, sr, sd, BoneMinesData.SHARD_SOURCE)
			_fading.append({"at": p, "t": game.elapsed, "r": sr, "evolved": true})
		game.stat_add("bone_mines_shards", float(n))
	Sfx.play("corpse_explode", at, 0.5)  # A startup-bank sound: the spell plays on every stage.


## Autotest counters (FortKesslerReport's Bone Mines line).
func summary_extra() -> String:
	var st := game.stats
	return "laid=%d (extra %d) blown=%d hits=%d expired=%d shards=%d" % [int(st.get("bone_mines_laid", 0.0)), int(st.get("bone_mines_extra", 0.0)),
		int(st.get("bone_mines_blown", 0.0)), int(st.get("bone_mines_hits", 0.0)), int(st.get("bone_mines_expired", 0.0)),
		int(st.get("bone_mines_shards", 0.0))]


## The mines: a bone disc with a soft violet lamp blinking slowly (at most 1
## Hz), then a fading blast ring (bone, violet once evolved). Textures only.
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	for i in _pos.size():
		var at := _pos[i]
		var armed := now >= _born[i] + BoneMinesData.ARM_TIME
		var k := 0.5 + 0.5 * sin(TAU * BoneMinesData.BLINK_HZ * (now - _born[i]))  # 0..1, a soft fade.
		if not SpriteBank.draw(self, "spells/bone_mine", at, false):
			SpriteBank.draw_disc(self, at, 6.0, Color(0.1, 0.08, 0.12, 0.9))
			SpriteBank.draw_disc(self, at, 4.5, Palette.BONE)
		SpriteBank.draw_disc(self, at + Vector2(0.0, -1.0), 2.0 + (2.5 * k if armed else 0.0), Color(Palette.VIOLET, 0.35 + 0.5 * k if armed else 0.25))
	for f in _fading:
		var a := clampf(1.0 - (now - float(f["t"])) / BoneMinesData.FADE_TIME, 0.0, 1.0)
		var c: Color = Palette.VIOLET if bool(f["evolved"]) else Palette.BONE
		SpriteBank.draw_disc(self, f["at"], float(f["r"]) * (0.6 + 0.4 * (1.0 - a)), Color(c, 0.3 * a))
