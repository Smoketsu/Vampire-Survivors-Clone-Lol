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
## The later spells' innates are read by those spells through
## game.character.innate_value() (keys in CharacterData.INNATE_KEYS):
##   Doomsayer        Ill Omen        DeathMark._brand(): death_mark_slow
##                    through CombatResolver.slow_enemy (ill_omen_slows)
##   Barrow Warden    Stonebone       BoneWall._cast(): bone_wall_duration
##                    (stonebone_extra_seconds)
##   Soulbinder       Conductor       SoulChains._cast():
##                    soul_chains_extra_jumps (conductor_extra_jumps)
##   Wither Witch     Creeping Rot    Wither._pulse(): wither_rot for
##                    wither_rot_linger s through CombatResolver.rot_enemy
##                    (creeping_rot_applied)
## The Grave Herald's Restless counts restless_extra_seconds.
## Act III, the Iron Citadel:
##   Rust Prophet     Scrap Prophecy  on_temporary_spawned() (HordeDirector
##                    .spawn_temporary, the one temporary-summon path: every
##                    temporary Risen is armed) and step(): each armed Risen
##                    fires a scrap bolt (Projectile.Kind.SCRAP_BOLT, source
##                    "scrap_bolt", a minion special source) every
##                    risen_bolt_interval s at the nearest foe within
##                    ScrapSwarmData.PROPHET_RANGE px; stat prophet_scrap_bolts.
## Act IV, Mount Olympus:
##   Oathbreaker      Kinslayer       StolenThunder._hit(): thunder_divine_bonus
##                    more Stolen Thunder damage on bosses, minibosses (the
##                    gods) and Heroes (kinslayer_hits).
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
# --- Act III: the Iron Citadel ---
## Scrap Prophecy: armed temporary Risen, each [SummonedUnit, generation,
## seconds until its next scrap bolt].
var _armed: Array = []


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
	elif _innate == "scrap_prophecy":
		_step_scrap(delta)  # Act III: the Rust Prophet's armed Risen.


# =====================================================================================
# Hooks called by the existing systems
# =====================================================================================

## Scrap Prophecy (Rust Prophet; Act III): every temporary Risen
## (HordeDirector.spawn_temporary()) is armed with a scrap launcher.
func on_temporary_spawned(u: SummonedUnit) -> void:
	if _innate != "scrap_prophecy":
		return
	_armed.append([u, u.generation, game.character.innate_value("risen_bolt_interval") * 0.5])


## Scrap Prophecy: each armed Risen still standing fires on its interval at the
## nearest foe in range; crumbled or fallen ones are dropped.
func _step_scrap(delta: float) -> void:
	var interval := game.character.innate_value("risen_bolt_interval")  # s between two bolts.
	var dmg := game.character.innate_value("risen_bolt_damage")  # Damage per bolt.
	var i := _armed.size() - 1
	while i >= 0:
		var rec: Array = _armed[i]
		var u: SummonedUnit = rec[0]
		if not u.active or u.generation != int(rec[1]):
			_armed.remove_at(i)
			i -= 1
			continue
		rec[2] = float(rec[2]) - delta
		if float(rec[2]) <= 0.0:
			var best: Enemy = null
			var best_d := ScrapSwarmData.PROPHET_RANGE
			game.enemy_grid.query(u.position, best_d, _tmp)
			for e: Enemy in _tmp:
				if not e.active or e.untargetable:
					continue
				var d := u.position.distance_to(e.position)
				if d < best_d:
					best_d = d
					best = e
			if best == null:
				rec[2] = 0.3
			else:
				rec[2] = interval
				game.projectiles.fire_friendly(Projectile.Kind.SCRAP_BOLT, u.position, best, dmg, ScrapSwarmData.PROPHET_BOLT_SPEED, 0, ScrapSwarmData.PROPHET_SOURCE)
				game.stat_add("prophet_scrap_bolts", 1.0)
		i -= 1


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
				if SpriteBank.draw_flat(self, MarkerArtData.ORACLE_SHARD, c, a + PI * 0.5):
					continue  # Pixel-art shard, its tip along the orbit (the faint glow above stays drawn).
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
			counters = "temporary summons %d, extra seconds %d" % [game.horde.temp_spawned, int(st.get("restless_extra_seconds", 0.0))]
		"ill_omen":
			counters = "brands slowed %d (brands %d)" % [int(st.get("ill_omen_slows", 0.0)), int(st.get("death_mark_brands", 0.0))]
		"stonebone":
			counters = "extra wall seconds %d (walls %d, hold seconds %d)" % [int(st.get("stonebone_extra_seconds", 0.0)), int(float(st.get("walls_raised", 0.0)) + float(st.get("bastions_raised", 0.0))), int(st.get("wall_hold_seconds", 0.0))]
		"conductor":
			counters = "extra jumps %d (casts %d)" % [int(st.get("conductor_extra_jumps", 0.0)), int(st.get("chains_casts", 0.0))]
		"creeping_rot":
			counters = "rot applied %d (rot bonus dmg %d)" % [int(st.get("creeping_rot_applied", 0.0)), int(st.get("rot_bonus_dmg", 0.0))]
		# --- Act II: Gullhaven Harbour ---
		"riptide":
			counters = "extra shallows %d (patches %d, waves %d)" % [int(st.get("riptide_extra_shallows", 0.0)), int(st.get("undertow_shallows", 0.0)), int(st.get("undertow_waves", 0.0))]
		# --- Act II: the Hollow Archive ---
		"illuminated_margins":
			counters = "ink bursts %d (burst dmg %d)" % [int(st.get("verse_bursts", 0.0)), int(st.get("dmg_ink_burst", 0.0))]
		# --- Act III: the Scrap Wastes ---
		"storm_litany":
			counters = "extra sparks %d (beam kills %d)" % [int(st.get("abbess_extra_sparks", 0.0)), int(st.get("ray_kills", 0.0))]
		# --- Act III: the Iron Citadel ---
		"scrap_prophecy":
			counters = "scrap bolts %d, bolt dmg %d, kills %d (temporary summons %d)" % [int(st.get("prophet_scrap_bolts", 0.0)), int(st.get("dmg_" + ScrapSwarmData.PROPHET_SOURCE, 0.0)),
				int(st.get("kills_by_" + ScrapSwarmData.PROPHET_SOURCE, 0.0)), game.horde.temp_spawned]
		# --- Act IV: Mount Olympus ---
		"kinslayer":
			counters = "kinslayer hits %d (thunder strikes %d)" % [int(st.get("kinslayer_hits", 0.0)), int(st.get("thunder_strikes", 0.0))]
	out += " | innate: %s" % ("none" if _innate == "" else "%s: %s" % [ch.innate_name(), counters])
	out += " | characters unlocked this run: %s" % (", ".join(ch.unlocked_this_run) if not ch.unlocked_this_run.is_empty() else "none")
	var open := PackedStringArray()  # Characters unlocked in the Meta profile now.
	for cid: String in CharacterData.ORDER:
		if Meta.is_character_unlocked(cid):
			open.append(cid)
	out += " | unlocked in the profile: %s (saved: %s)" % [", ".join(open), str(Meta.can_write())]
	return out
