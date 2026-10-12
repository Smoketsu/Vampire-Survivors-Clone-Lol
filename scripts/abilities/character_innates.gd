## CharacterInnates — runs the INNATE passive of the playable character
## (CharacterData, read through game.character, the one character path).
## Game creates one per run (`game.innates`, never null) and steps it right
## after the spells. The existing systems call a few small hooks; each one
## returns at once unless the run's character owns that innate, so the
## Gravecaller (no innate) plays exactly as before: no RNG, no stats, no
## state change.
##   Umbral Warden    Eclipsed Guard  eclipsed_guard()  (ProjectileManager:
##                    an orb, charged or not, destroys a hostile projectile
##                    it touches; stat eclipsed_guard_destroyed)
##   Voidcaller       Echoing Dark    on_blast()        (AbilityManager
##                    ._cast_blast: a ring bursts again blast_echo_delay s
##                    later for blast_echo_damage of the blast; source "echo",
##                    stat echo_bursts)
##   Bone Oracle      Ossuary Ward    on_enemy_killed() (a Bone Spear / Ossuary
##                    Lance kill grows a shard, at most one per
##                    spear_shard_cooldown s, up to spear_shard_max) and
##                    try_block_hit() (CombatResolver.damage_player: a shard
##                    absorbs a whole hit and grants the normal hit i-frames;
##                    stats oracle_shards_grown / oracle_shards_blocked)
##   Carrion Lord     Grave Harvest   on_summon_died()  (HordeDirector: a summon
##                    that falls leaves a corpse in Corpse Explosion's ring
##                    buffer; an expired temporary summon leaves none; stats
##                    carrion_summon_corpses / carrion_summon_bursts)
##   Fallen Confessor Stolen Grace    on_player_healed() (CombatResolver
##                    .heal_player: grace_share of the HP healed goes to the
##                    nearest wounded summons, up to grace_targets within
##                    grace_range px; stat grace_healing)
##   Plague Scholar   Contagion       on_enemy_killed() (an enemy dying while
##                    Rotting rots the nearest enemy within contagion_range
##                    for contagion_duration s, through CombatResolver
##                    .rot_enemy; stat contagion_spreads)
##   Grave Herald     Restless        HordeDirector.spawn_temporary reads
##                    temp_summon_duration directly.
## The later spells' innates (Doomsayer, Barrow Warden, Soulbinder, Wither
## Witch) are read by those spells through game.character.innate_value()
## (keys in CharacterData.INNATE_KEYS).
class_name CharacterInnates
extends Node2D

## Owning run.
var game: Game
## Pending Echoing Dark bursts: {"t": s left, "pos": centre, "r": radius px,
## "dmg": damage per enemy}.
var _echoes: Array[Dictionary] = []
## Ossuary Ward shards held (0..spear_shard_max).
var shards: int = 0
## Seconds before the next shard may grow.
var _shard_cd: float = 0.0
## Orbit angle (radians) of the shards (visual only).
var _shard_angle: float = 0.0
## Reusable query buffer.
var _tmp: Array = []
## Innate id of the run's character ("" = none: every hook is a no-op).
var _innate: String = ""


func _ready() -> void:
	z_index = 3
	_innate = game.character.innate_id()


## Ticks the innates that need time: Echoing Dark bursts and the shard
## cooldown and orbit.
func step(delta: float) -> void:
	if _innate == "":
		return
	if not _echoes.is_empty():
		_step_echoes(delta)
	if _innate == "ossuary_ward":
		_shard_cd = maxf(0.0, _shard_cd - delta)
		_shard_angle = wrapf(_shard_angle + CharacterData.SHARD_ORBIT_SPEED * delta, 0.0, TAU)
		position = game.player.position
		queue_redraw()
	elif _innate == "echoing_dark":
		queue_redraw()


# =====================================================================================
# Hooks called by the existing systems
# =====================================================================================

## Echoing Dark (Voidcaller): a Shadow Blast (or Abyssal Detonation) of
## `damage` at `pos` with radius `r` queues an echo burst.
func on_blast(pos: Vector2, r: float, damage: float) -> void:
	if _innate != "echoing_dark":
		return
	var ch := game.character  # Innate numbers.
	_echoes.append({"t": ch.innate_value("blast_echo_delay"), "pos": pos, "r": r,
		"dmg": damage * ch.innate_value("blast_echo_damage")})


## Eclipsed Guard (Umbral Warden): true (and the projectile is destroyed by
## the caller) when any orb touches a hostile projectile at `pos` (radius
## `r`), whatever its intercept charge.
func eclipsed_guard(pos: Vector2, r: float) -> bool:
	if _innate != "eclipsed_guard":
		return false
	var orbs := game.abilities.orb_shield  # Null until the spell exists.
	if orbs == null or not orbs.touches(pos, r):
		return false
	game.stat_add("eclipsed_guard_destroyed", 1.0)
	return true


## Kill hook (CombatResolver.damage_enemy, `e` still active and in place):
## Ossuary Ward shards from Bone Spear / Ossuary Lance kills, Contagion from
## rotting enemies. `source` is the killing blow's damage tag.
func on_enemy_killed(e: Enemy, source: String) -> void:
	match _innate:
		"ossuary_ward":
			if source == "spear" or source == "lance":
				_grow_shard()
		"contagion":
			if e.rot_until > game.elapsed:
				_spread_rot(e)


## Ossuary Ward: a shard absorbs this hit on the necromancer (the caller
## then ignores it). False when no shard is held, or the hit would be
## ignored anyway (i-frames, death), so shards are never wasted.
func try_block_hit() -> bool:
	if _innate != "ossuary_ward" or shards <= 0:
		return false
	var p := game.player  # The necromancer.
	if p.dead or p.iframes > 0.0:
		return false
	shards -= 1
	p.iframes = PlayerData.IFRAMES  # Like a real hit: one shard per i-frame window.
	game.stat_add("oracle_shards_blocked", 1.0)
	game.effects.pop(p.position, Palette.BONE, 14.0)
	queue_redraw()
	return true


## Grave Harvest (Carrion Lord): summon `u` just fell (HordeDirector, still in
## place) and leaves a corpse for Corpse Explosion; an expired temporary
## summon crumbles without one.
func on_summon_died(u: SummonedUnit) -> void:
	if _innate != "grave_harvest" or (u.is_temporary and u.temp_life <= 0.0):
		return
	var ce: CorpseExplosion = game.abilities.spells.nodes.get("corpse_explosion")  # Null until learned.
	if ce == null:
		return
	ce.add_summon_corpse(u.position)
	game.stat_add("carrion_summon_corpses", 1.0)


## Stolen Grace (Fallen Confessor): the necromancer was healed for `healed`
## HP; grace_share of it mends the nearest wounded summons (nearest first,
## the rest spilling to the next, up to grace_targets summons within
## grace_range px). Rising and airborne summons are skipped.
func on_player_healed(healed: float) -> void:
	if _innate != "stolen_grace" or healed <= 0.0:
		return
	var ch := game.character  # Innate numbers.
	var left := healed * ch.innate_value("grace_share")  # HP still to give.
	var p := game.player.position
	game.ally_grid.query(p, ch.innate_value("grace_range"), _tmp)
	var cands: Array = []  # [distance, unit] of wounded summons in range.
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.DEAD and u.state != SummonedUnit.State.SPAWNING \
				and not u.airborne and u.hp < u.max_hp:
			cands.append([p.distance_to(u.position), u])
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var n := mini(cands.size(), int(ch.innate_value("grace_targets")))  # Summons healed at most.
	for i in n:
		if left <= 0.01:
			break
		var mended := game.combat.heal_unit(cands[i][1], left)  # HP this summon took.
		left -= mended
		game.stat_add("grace_healing", mended)


# =====================================================================================
# Innate logic
# =====================================================================================

## Counts down the Echoing Dark bursts and releases the due ones.
func _step_echoes(delta: float) -> void:
	var i := 0  # Index into _echoes.
	while i < _echoes.size():
		var ec: Dictionary = _echoes[i]
		ec["t"] = float(ec["t"]) - delta
		if float(ec["t"]) > 0.0:
			i += 1
			continue
		_echoes.remove_at(i)
		var pos: Vector2 = ec["pos"]
		var r := float(ec["r"])  # Burst radius (px).
		var hits: Array = []  # Own buffer: kills may trigger other hooks.
		game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, hits)
		for e: Enemy in hits:
			if e.active and e.position.distance_to(pos) <= r + e.radius:
				game.combat.damage_enemy(e, float(ec["dmg"]), "echo")
		game.effects.ring(pos, r, Color(Palette.VIOLET, 0.8), 0.3)
		game.stat_add("echo_bursts", 1.0)


## Ossuary Ward: grows one shard unless full or still on cooldown.
func _grow_shard() -> void:
	var ch := game.character  # Innate numbers.
	if shards >= int(ch.innate_value("spear_shard_max")) or _shard_cd > 0.0:
		return
	shards += 1
	_shard_cd = ch.innate_value("spear_shard_cooldown")
	game.stat_add("oracle_shards_grown", 1.0)


## Contagion: the rotting enemy `e` (dying) passes its Rot to the nearest
## other live enemy within contagion_range px (ties: grid order, which is
## deterministic).
func _spread_rot(e: Enemy) -> void:
	var ch := game.character  # Innate numbers.
	var reach := ch.innate_value("contagion_range")  # px.
	game.enemy_grid.query(e.position, reach + ProjectileManager.MAX_BODY_RADIUS, _tmp)
	var best: Enemy = null  # Nearest other live enemy.
	var best_d := INF  # Its distance (px).
	for o: Enemy in _tmp:
		if o == e or not o.active or o.is_structure:
			continue
		var d := e.position.distance_to(o.position)
		if d <= reach and d < best_d:
			best_d = d
			best = o
	if best == null:
		return
	# The dying enemy's full Rot (a boss only held ROT_BOSS_MULT of it).
	var amp := e.rot_amp / (AbilityData.ROT_BOSS_MULT if e.is_boss else 1.0)
	game.combat.rot_enemy(best, amp, game.elapsed + ch.innate_value("contagion_duration"))
	game.stat_add("contagion_spreads", 1.0)
	game.effects.ring(best.position, best.radius + 6.0, Color(0.7, 0.86, 0.3, 0.8), 0.25)


func _draw() -> void:
	match _innate:
		"ossuary_ward":
			for i in shards:
				var a := _shard_angle + TAU * float(i) / maxf(1.0, float(shards))  # This shard's angle.
				var c := Vector2(0.0, CharacterData.SHARD_ORBIT_LIFT) + Vector2.from_angle(a) * CharacterData.SHARD_ORBIT_RADIUS  # Local centre.
				var d := Vector2.from_angle(a + PI * 0.5) * 7.0  # Half-length along the orbit.
				draw_circle(c, 7.0, Color(Palette.BONE, 0.18))
				draw_line(c - d, c + d, Color(0, 0, 0, 0.6), 5.0)
				draw_line(c - d, c + d, Palette.BONE, 3.0)
				draw_circle(c + d, 2.2, Palette.BONE)
		"echoing_dark":
			for ec: Dictionary in _echoes:
				var k := clampf(float(ec["t"]) / maxf(game.character.innate_value("blast_echo_delay"), 0.01), 0.0, 1.0)  # 1 -> 0 until the burst.
				draw_arc(ec["pos"], float(ec["r"]) * (0.4 + 0.6 * (1.0 - k)), 0.0, TAU, 40, Color(Palette.VIOLET, 0.25 + 0.35 * (1.0 - k)), 2.0)


## One autotest summary line: the character, its starting spell and level,
## the innate and its counters, and the characters this run unlocked.
func summary_line() -> String:
	var ch := game.character  # The run's character.
	var st := game.stats  # Run counters.
	var sp := ch.starting_spell()  # Starting spell id.
	var out := "%s (%s) | starting spell %s Lv %d%s | %s" % [ch.id, ch.display_name(), sp, game.abilities.spell_level(sp),
		" EVOLVED" if game.abilities.evolved.has(sp) else "", CharacterModifiers.stats_text(ch.id)]
	var counters := ""  # Innate counters.
	match _innate:
		"eclipsed_guard":
			counters = "projectiles destroyed %d (charged intercepts %d)" % [int(st.get("eclipsed_guard_destroyed", 0.0)), int(st.get("orb_intercepts", 0.0))]
		"echoing_dark":
			counters = "echo bursts %d, echo dmg %d (blasts %d)" % [int(st.get("echo_bursts", 0.0)), int(st.get("dmg_echo", 0.0)), int(float(st.get("shadow_blasts", 0.0)) + float(st.get("abyssal_detonations", 0.0)))]
		"ossuary_ward":
			counters = "shards grown %d, hits blocked %d, held at end %d" % [int(st.get("oracle_shards_grown", 0.0)), int(st.get("oracle_shards_blocked", 0.0)), shards]
		"grave_harvest":
			counters = "summon corpses %d, summon corpses detonated %d (all bursts %d)" % [int(st.get("carrion_summon_corpses", 0.0)), int(st.get("carrion_summon_bursts", 0.0)), int(st.get("corpse_bursts", 0.0))]
		"stolen_grace":
			counters = "grace healing to summons %d (player healing %d)" % [int(st.get("grace_healing", 0.0)), int(st.get("player_healing", 0.0))]
		"contagion":
			counters = "contagion spreads %d (rot bonus dmg %d)" % [int(st.get("contagion_spreads", 0.0)), int(st.get("rot_bonus_dmg", 0.0))]
		"restless":
			counters = "temporary summons %d" % game.horde.temp_spawned
	out += " | innate: %s" % ("none" if _innate == "" else "%s: %s" % [ch.innate_name(), counters])
	out += " | characters unlocked this run: %s" % (", ".join(ch.unlocked_this_run) if not ch.unlocked_this_run.is_empty() else "none")
	var open := PackedStringArray()  # Characters unlocked in the Meta profile now.
	for cid: String in CharacterData.ORDER:
		if Meta.is_character_unlocked(cid):
			open.append(cid)
	out += " | unlocked in the profile: %s (saved: %s)" % [", ".join(open), str(Meta.can_write())]
	return out
