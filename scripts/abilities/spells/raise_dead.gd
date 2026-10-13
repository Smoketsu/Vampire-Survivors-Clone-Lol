## RaiseDead — the Raise Dead spell (AbilityData "raise_dead", GDD §15.0
## "Five more spells"): every `cooldown` s, `count` temporary skeletons claw
## up beside the enemies nearest the necromancer (within `range` px), each
## on the necromancer's side of its enemy, and fight for `life` s. They are
## temporary summons (HordeDirector.spawn_temporary(), the Lich raise path):
## outside the army cap, never replaced, drawn as "risen", with
## `skeleton_hp` / `skeleton_damage` of a Skeleton Warrior's current stats
## (so Dark Command and the warrior level still raise them; Restless Dead
## lengthens their life and raises their damage). At most
## GraveSpellData.RAISE_DEAD_MAX stand at once; a cast skips the rest. With
## fewer enemies than skeletons, the nearest enemies get more than one.
## Evolved into Legion of Bones (EvolutionData "legion_of_bones", detected by
## the "damage" key): six skeletons (cap RAISE_DEAD_MAX_EVOLVED), and each
## bursts into bone shards when it crumbles or falls: `damage` to every
## enemy within `radius` px of where it stood ("legion_burst").
## Skeletons are tracked as [SummonedUnit, generation, last position]; one
## whose generation changed or that is no longer active has expired or died.
class_name RaiseDead
extends NecroSpell

## Seconds until the next cast.
var _timer: float = 1.0
## Living raised skeletons as [SummonedUnit, generation, last position, legion].
var _raised: Array = []
## Candidate [distance, enemy] pairs of a cast.
var _cands: Array = []


## Tracks the skeletons (Legion bursts) and casts on cooldown.
func step(delta: float, stats: Dictionary) -> void:
	_track(stats)
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY


## Raises up to `count` skeletons. Returns false when no enemy is in range or
## the cap is full (the cooldown is not spent).
func _cast(stats: Dictionary) -> bool:
	var legion := stats.has("damage")  # Evolved into Legion of Bones.
	var cap := GraveSpellData.RAISE_DEAD_MAX_EVOLVED if legion else GraveSpellData.RAISE_DEAD_MAX  # Most alive at once.
	var room := cap - _raised.size()  # Skeletons the cap still allows.
	if room <= 0:
		return false
	var p := game.player.position  # Necromancer.
	var reach := float(stats["range"])  # Search radius (px).
	game.enemy_grid.query(p, reach, _tmp)
	_cands.clear()
	for e: Enemy in _tmp:
		if not e.active or e.is_structure:
			continue
		var d := p.distance_to(e.position)
		if d <= reach:
			_cands.append([d, e])
	if _cands.is_empty():
		return false
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var n := mini(int(stats["count"]), room)  # Skeletons this cast.
	var r := float(UnitData.UNITS[GraveSpellData.RAISE_DEAD_CLASS]["radius"])  # Skeleton body radius (px).
	for k in n:
		var e: Enemy = _cands[k % _cands.size()][1]
		var to_p := p - e.position  # Enemy -> necromancer.
		var side := to_p.normalized() if to_p.length() > 0.01 else Vector2.RIGHT
		# Later skeletons beside the same enemy fan out around it.
		var lap := floorf(float(k) / float(_cands.size()))  # Earlier skeletons beside this enemy.
		side = side.rotated(lap * GraveSpellData.RAISE_DEAD_FAN * (1.0 if k % 2 == 0 else -1.0))
		var at := e.position + side * (e.radius + r + GraveSpellData.RAISE_DEAD_OFFSET)  # Claw-up point.
		var u := game.horde.spawn_temporary(GraveSpellData.RAISE_DEAD_CLASS, at, float(stats["life"]),
				float(stats["skeleton_hp"]), float(stats["skeleton_damage"]))
		u.dmg_source = "raised_dead"
		u.glyph_kind = "risen"
		u.queue_redraw()
		_raised.append([u, u.generation, u.position, legion])
		game.effects.ring(u.position, 20.0, Palette.NECRO_GREEN, 0.45, "raise_dead")
	game.stat_add("raise_dead_casts", 1.0)
	game.stat_add("raise_dead_skeletons", float(n))
	Sfx.play("summon_rise", p)
	game.player.cast_motion(p)  # Engine motion: a pulse as they rise (visual only).
	return true


## Updates every tracked skeleton's last position and drops the ones that
## expired or fell; a Legion skeleton bursts where it stood.
func _track(stats: Dictionary) -> void:
	var i := _raised.size() - 1
	while i >= 0:
		var rec: Array = _raised[i]
		var u: SummonedUnit = rec[0]
		if u.active and u.generation == int(rec[1]):
			rec[2] = u.position
		else:
			_raised.remove_at(i)
			if bool(rec[3]) and stats.has("damage"):
				_burst(rec[2], float(stats["damage"]), float(stats["radius"]))
		i -= 1


## Legion of Bones: a skeleton's bone burst at `pos`.
func _burst(pos: Vector2, dmg: float, r: float) -> void:
	damage_area(pos, r, dmg, "legion_burst")
	game.effects.ring(pos, r, Palette.BONE, 0.3, "legion_burst")
	game.effects.pop(pos, Palette.NECRO_GREEN, 8.0)
	game.stat_add("legion_bursts", 1.0)
	Sfx.play("corpse_burst", pos)


## Autotest counters (NecroSpellBook.later_summary_line()).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d skeletons=%d skeleton_dmg=%d skeleton_kills=%d bursts=%d" % [int(st.get("raise_dead_casts", 0.0)),
		int(st.get("raise_dead_skeletons", 0.0)), int(st.get("dmg_raised_dead", 0.0)), int(st.get("kills_by_raised_dead", 0.0)),
		int(st.get("legion_bursts", 0.0))]
