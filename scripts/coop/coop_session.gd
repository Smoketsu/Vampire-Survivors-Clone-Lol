## CoopSession — the simulation half of online co-op (docs/coop/DESIGN.md): two
## player slots (CoopSlot) in ONE deterministic run. It exists only in a co-op
## run (`game.coop`); a solo run never creates it, so solo plays bit-for-bit as
## before.
##
## BINDING (the one path for "which player"). Game keeps its per-player fields
## (player, horde, abilities, grave_step, dread_rally, ultimates, stance,
## character, innates, meta, volleys, dread, rewards; the bot as `autotest`; the
## power-up buff timers) pointing at the BOUND slot. bind(i) swaps them all, so
## the existing code that reads `game.player` / `game.abilities` acts for the
## slot being stepped without knowing about co-op:
##   * per-player systems step once per slot, in the fixed order 0, 1, with
##     their slot bound (player, rally, ultimate, formation, Dread, spells,
##     innate, army; the spells' after-physics; the volleys);
##   * shared systems step once (enemies, projectiles, Empire rules, pickups,
##     power-ups, chests, effects, stage directors) with the PRIMARY slot bound
##     (the lowest-index standing one), except where they act for a player:
##       - each enemy (bosses and kits included) steps with its NEAREST
##         standing necromancer bound (EnemyDirector.step() -> bind_nearest()),
##         so every enemy advances on the nearest necromancer and its attacks,
##         aims and telegraphs read that one; downed necromancers are no targets;
##       - CombatResolver binds the owner of a hit: damage_unit() the hit
##         summon's army, damage_player() / heal_player() the target
##         necromancer, damage_enemy() an explicit owner slot (a shield bash
##         from inside an enemy's step, a Soul Nova); a friendly projectile
##         carries its owner slot (Projectile.owner_slot);
##       - hazards that test "is the necromancer inside?" test every one of
##         Game.all_players.
## Shared run state stays on Game: the clock, the ONE XP bar and level, the
## kill count, the stats, the boss. XP per pickup is scaled by CoopData (x0.5)
## through DifficultyModifiers.coop_mult(), the one co-op scaling path, which
## also doubles the trickle and the caps and raises boss / miniboss HP.
##
## Co-op rules here: downed and revive (the army crumbles; the partner standing
## within REVIVE_RADIUS for REVIVE_TIME s raises him at half HP, his army queued
## to rise again; both down ends the run: a defeat before 0:00, a victory after),
## the shared level-up (every pending level gives EACH slot one pick; the
## simulation does not step until both picked; in this milestone the bots pick),
## chests opened by whoever walks over them (no pause), and the per-slot report.
## Randomness: each slot's level-up / chest offers draw from its own seeded
## stream (AbilityManager.offer_rng), so one player's picks never shift the
## other's offers; everything else uses the run's shared streams in the fixed
## stepping order. Hit-stop is off in co-op (Juice).
class_name CoopSession
extends RefCounted

## Owning run.
var game: Game
## The players, in stepping order (index = slot).
var slots: Array[CoopSlot] = []
## Index of the slot whose objects Game's per-player fields point at (-1 = none yet).
var bound: int = -1
## The slot this machine shows and controls (camera, HUD, input). The autotest
## follows slot 0.
var view_slot: int = 0
## True when both slots are driven by the autotest bots (--coop-bot).
var bots: bool = false
## Seed of the run (the offer streams derive from it).
var run_seed: int = 0
## Round-robin counter of spawn_anchor() (which player the next trickle spawn rings).
var _anchor_turn: int = 0
## Revives done this run (both slots).
var revives: int = 0
## Game time (s) both necromancers were down at once (-1 = never).
var wipe_time: float = -1.0
## Level-up rounds resolved (each gives every slot one pick).
var level_rounds: int = 0
## Most enemies alive at once.
var peak_enemies: int = 0
## True once the --coop-down test knocked slot 1 down.
var _test_down_done: bool = false
## The online lockstep driver (CoopLockstep; null in the one-process
## --coop-bot run, where both slots are bots and nothing travels).
var lockstep: CoopLockstep = null


## Builds the session for loadouts `loadouts` (one Dictionary per slot, see
## CoopSlot.loadout); `p_view` is this machine's slot, `p_bots` true for the
## --coop-bot autotest.
func _init(p_game: Game, loadouts: Array, p_view: int, p_bots: bool, p_seed: int) -> void:
	game = p_game
	view_slot = p_view
	bots = p_bots
	run_seed = p_seed
	for i in mini(loadouts.size(), CoopData.SLOTS):
		var s := CoopSlot.new()
		s.index = i
		s.loadout = loadouts[i]
		s.display_name = String(s.loadout.get("name", "P%d" % (i + 1)))
		slots.append(s)


# =====================================================================================
# Building the slots (Game._ready)
# =====================================================================================

## The Ossuary upgrades of slot `i` (its loadout's meta_levels; under the
## autotest the --meta profile, like solo), with that player's own relics and
## Grave Offering attached (the loadout's relics / offering / borrowed, already
## checked on his machine: RelicEffects; under the autotest the --relics flags).
func meta_for(i: int) -> MetaModifiers:
	var lo := slots[i].loadout
	if GameState.autotest or not lo.has("meta_levels"):
		return Meta.run_modifiers()
	var t: Dictionary = (lo["meta_levels"] as Dictionary).duplicate()
	t[PactData.OATH_ID] = int(slots[0].loadout.get("meta_levels", {}).get(PactData.OATH_ID, 0)) if i == 0 else 0  # Only the host's Oath sets the run's.
	var m := MetaModifiers.from_tiers(t, lo.get("mastery_levels", {}) as Dictionary)  # Each player's own Masteries.
	m.attach_rites(RelicEffects.build(lo.get("relics", []), String(lo.get("offering", "")), String(lo.get("borrowed", ""))))
	return m


## The character of slot `i` (its loadout's character_id).
func character_for(i: int) -> CharacterModifiers:
	return CharacterModifiers.for_id(String(slots[i].loadout.get("character_id", CharacterData.DEFAULT_ID)))


## Takes Game's freshly built per-player objects as slot 0's (Game._ready built
## them the solo way, with slot 0's meta and character).
func adopt_slot0() -> void:
	var s := slots[0]
	s.player = game.player
	s.horde = game.horde
	s.abilities = game.abilities
	s.grave_step = game.grave_step
	s.dread_rally = game.dread_rally
	s.ultimates = game.ultimates
	s.stance = game.stance
	s.character = game.character
	s.innates = game.innates
	s.meta = game.meta
	s.volleys = game.volleys
	s.dread = game.dread
	s.rewards = game.rewards
	s.bot = game.autotest if lockstep == null else null  # Online: no slot bot (each machine's bot sends its inputs; a takeover bot comes with a drop).
	s.powerup_timers = game.powerups.timers
	_finish_slot(s)
	bound = 0


## Builds slot `i`'s own objects beside slot 0's (same node layers: each new
## node is added right after slot 0's matching node), in Game._ready's order.
func build_slot(i: int) -> void:
	var s := slots[i]
	var s0 := slots[0]
	bound = -2  # Building: no slot is bound (Game.records_here() is false for the new slot's setup).
	s.meta = meta_for(i)
	s.character = character_for(i)
	game.meta = s.meta  # Read while the new nodes set up (GraveStep, AbilityManager).
	game.character = s.character
	s.dread_rally = DreadRally.new(game)
	s.ultimates = UltimateSystem.new(game, _resolve_ultimate(s))
	s.stance = ArmyStance.new(game)
	if s0.dread != null:
		s.dread = DreadMeter.new(game)  # Act II only (slot 0 has one exactly then).
	s.horde = HordeDirector.new()
	s.horde.game = game
	s.horde.slot = i
	s.horde.y_sort_enabled = true
	s0.horde.add_sibling(s.horde)
	s.grave_step = GraveStep.new()
	s.grave_step.game = game
	s0.grave_step.add_sibling(s.grave_step)
	s.player = Necromancer.new()
	s.player.game = game
	s0.player.add_sibling(s.player)
	s.meta.apply_to_player(s.player)
	s.character.apply_to_player(s.player)
	game.difficulty.apply_to_player(s.player)
	s.innates = CharacterInnates.new()
	s.innates.game = game
	s0.innates.add_sibling(s.innates)
	s.player.skin_id = String(s.loadout.get("skin_id", ""))
	if s.player.skin_id != "" and not SkinData.skins_for(s.character.id).has(s.player.skin_id):
		s.player.skin_id = ""  # A skin of another character: the default look.
	# Cosmetic only (RecolourData): the partner's palette swap rides in the loadout. It is never read by the simulation or the checksum.
	var rc_skin := s.player.skin_id if s.player.skin_id != "" else SkinData.default_skin(s.character.id)  # Skin that wears it.
	var rc := String(s.loadout.get("recolour_id", ""))  # Requested recolour.
	s.player.recolour_id = rc if RecolourData.offered(rc_skin, rc) else ""
	SkinGlyphs.warm(s.player.skin_id, s.character.id, s.player.recolour_id)
	s.abilities = AbilityManager.new()
	s0.abilities.add_sibling(s.abilities)
	s.abilities.setup(game)
	s.volleys = VolleyDirector.new()
	s0.volleys.add_sibling(s.volleys)
	s.volleys.setup(game)
	s.rewards = RunRewards.new(game)
	if bots:
		s.bot = Autotest.new()
		s.bot.game = game
		s.bot.init_bot(i)  # Sets its slot first, so its _ready() skips the run setup.
		game.add_child(s.bot)  # Freed with the run.
	for kind: String in PowerupData.TIMED:
		s.powerup_timers[kind] = 0.0
	_finish_slot(s)
	bound = -1
	bind(0)


## Per-slot setup common to both slots: the offer stream, the start position,
## the character id the necromancer is drawn as, his dash.
func _finish_slot(s: CoopSlot) -> void:
	s.abilities.offer_rng = RandomNumberGenerator.new()
	s.abilities.offer_rng.seed = hash("coop_offers:%d:%d" % [run_seed, s.index])
	if s.index > 0:
		s.abilities.allow_pact = false  # The host picks the Profane Pact (docs/coop/DESIGN.md).
	if s.loadout.has("unlocks") and not GameState.autotest:
		var u := {}  # The player's own unlocks (their card pool).
		for id: String in s.loadout["unlocks"]:
			u[id] = true
		s.abilities.offer_unlocks = u
	s.player.position = CoopData.START_POSITIONS[s.index]
	s.player.character_id = s.character.id
	s.player.dash = s.grave_step
	s.grave_step.who = s.player


## The ultimate slot `i` casts (Game._ready builds slot 0's with it: on the
## guest's machine the host's choice, never a lock check of the local save).
func ultimate_for(i: int) -> String:
	return _resolve_ultimate(slots[i])


## The ultimate slot `s` casts: its loadout's ultimate_id when known (the
## autotest's --ultimate= for a bot), else Dread Rally.
func _resolve_ultimate(s: CoopSlot) -> String:
	var uid := GameState.autotest_ultimate if GameState.autotest else String(s.loadout.get("ultimate_id", UltimateData.DEFAULT_ID))
	return uid if UltimateData.ULTIMATES.has(uid) else UltimateData.DEFAULT_ID


## Lists every slot's player and army in Game.all_players / all_hordes and
## hooks the downed rule (Game._ready, after the slots exist).
func finish_setup() -> void:
	game.all_players.clear()
	game.all_hordes.clear()
	for s in slots:
		game.all_players.append(s.player)
		game.all_hordes.append(s.horde)
		s.player.died.connect(_on_player_down.bind(s.index))
		s.min_hp = s.player.hp


# =====================================================================================
# Binding (the one path for "which player")
# =====================================================================================

## Points Game's per-player fields at slot `i`'s objects (no-op when bound).
func bind(i: int) -> void:
	if i == bound or i < 0 or i >= slots.size():
		return
	var s := slots[i]
	if bound >= 0:
		slots[bound].stasis_total = game.powerups.stasis_total  # Keep the slot's own Stasis length.
	bound = i
	game.player = s.player
	game.horde = s.horde
	game.abilities = s.abilities
	game.grave_step = s.grave_step
	game.dread_rally = s.dread_rally
	game.ultimates = s.ultimates
	game.stance = s.stance
	game.character = s.character
	game.innates = s.innates
	game.meta = s.meta
	game.volleys = s.volleys
	game.dread = s.dread
	game.rewards = s.rewards
	if bots:
		game.autotest = s.bot
	game.powerups.timers = s.powerup_timers
	game.powerups.stasis_total = s.stasis_total


## The slot of necromancer `p` (-1 when none).
func slot_of(p: Necromancer) -> int:
	for s in slots:
		if s.player == p:
			return s.index
	return -1


## Index of the standing slot nearest to `pos` (the primary slot when none stands).
func nearest_slot(pos: Vector2) -> int:
	var best := -1
	var best_d := INF
	for s in slots:
		if not s.alive():
			continue
		var d := pos.distance_squared_to(s.player.position)
		if d < best_d:
			best_d = d
			best = s.index
	return best if best >= 0 else primary()


## Binds the standing slot nearest to `pos` (the enemy step's targeting rule).
func bind_nearest(pos: Vector2) -> void:
	bind(nearest_slot(pos))


## The lowest-index standing slot (0 when none stands): what shared systems
## (stage directors, spawns, the run-level events) act around.
func primary() -> int:
	for s in slots:
		if s.alive():
			return s.index
	return 0


## Binds the primary slot.
func bind_primary() -> void:
	bind(primary())


## The standing necromancer nearest to `pos` (the primary one when none stands).
func nearest_player(pos: Vector2) -> Necromancer:
	return slots[nearest_slot(pos)].player


## Where the next trickle spawn rings: each standing necromancer in turn.
func spawn_anchor() -> Vector2:
	var alive: Array[int] = []
	for s in slots:
		if s.alive():
			alive.append(s.index)
	if alive.is_empty():
		return slots[primary()].player.position
	_anchor_turn += 1
	return slots[alive[_anchor_turn % alive.size()]].player.position


## Indexes of the standing slots, in order (formation waves ring each).
func alive_slots() -> Array[int]:
	var out: Array[int] = []
	for s in slots:
		if s.alive():
			out.append(s.index)
	return out


## Movement input of the bound slot for this tick (a networked slot's lockstep
## input; zero for a bot, which steers itself through Autotest).
func move_input() -> Vector2:
	return slots[bound].move if bound >= 0 else Vector2.ZERO


## A taunt that pulls enemy `e` onto another army's summon (Sovereign's Decree,
## then a Bone Colossus), checked across every slot after the bound one's
## (Enemy._pick_target()). Null when none applies.
func taunt_target(e: Enemy) -> SummonedUnit:
	for s in slots:
		if s.index == bound:
			continue
		var t := s.ultimates.taunt_target(e)
		if t != null:
			return t
		t = s.horde.colossi.taunt_target(e)
		if t != null:
			return t
	return null


## Widest blocker reach of every army (Enemy.resolve_blocking()).
func block_query_radius() -> float:
	var r := 0.0
	for s in slots:
		r = maxf(r, s.horde.block_query_radius)
	return r


## True while a Stasis power-up of any player holds `e` (a global time stop).
func stasis_freezes(e: Enemy) -> bool:
	for s in slots:
		var total := game.powerups.stasis_total if s.index == bound else s.stasis_total
		if PowerupManager.stasis_holds(s.powerup_timers, total, e):
			return true
	return false


# =====================================================================================
# The co-op tick (Game._physics_process)
# =====================================================================================

## One simulation tick of a co-op run, in a fixed order (see the header).
func step(delta: float) -> void:
	var pf := game.perf  # --perf: section laps (reads the clock only; null otherwise).
	var tl := Time.get_ticks_usec() if pf != null else 0  # Start of the current section (usec).
	game.elapsed += delta
	_rebuild_grids()
	var army := 0  # Summons alive across both armies (victory card).
	for s in slots:
		bind(s.index)
		s.player.step(delta)
		if not s.downed:
			s.dread_rally.step(delta)
			s.ultimates.step(delta)
		s.stance.step(delta)
		if s.dread != null:
			s.dread.step(delta)
		if not s.downed:
			s.abilities.step(delta)
			s.innates.step(delta)
			s.horde.step(delta)
		army += s.horde.units.size()
		s.peak_army = maxi(s.peak_army, s.horde.units.size())
	game.peak_army = maxi(game.peak_army, army)
	if pf != null:
		tl = pf.lap(PerfProbe.SEC_ARMY, tl)
	bind_primary()
	game.enemies.step(delta)  # Binds each enemy's nearest necromancer.
	peak_enemies = maxi(peak_enemies, game.enemies.active.size())
	if game.pantheon != null:
		bind_primary()
		game.pantheon.step(delta)  # Act IV: the gods' wrath and shield walls (before the push-out, as in solo).
	if game.shogunate != null:
		bind_primary()
		game.shogunate.step(delta)  # Act V: the Sun's Course, ambushes, the Draw (before the push-out, as in solo).
	if game.inferno != null:
		bind_primary()
		game.inferno.step(delta)  # Act VI: the Hell Pits, the portals, Temptation (before the push-out, as in solo).
	if pf != null:
		tl = pf.lap(PerfProbe.SEC_ENEMIES, tl)
	bind_primary()
	game.arena.resolve_all(delta)
	for s in slots:
		bind(s.index)
		s.abilities.spells.after_physics(delta)
	if pf != null:
		tl = pf.lap(PerfProbe.SEC_OBSTACLES, tl)
	bind_primary()
	game.projectiles.step(delta)  # Binds each friendly projectile's owner.
	bind_primary()
	if game.empire != null:
		game.empire.step(delta)
	if pf != null:
		tl = pf.lap(PerfProbe.SEC_PROJECTILES, tl)
	for s in slots:
		bind(s.index)
		s.volleys.echoes_on = not s.downed
		s.volleys.step(delta)
	if pf != null:
		tl = pf.lap(PerfProbe.SEC_VOLLEYS, tl)
	bind_primary()
	game.pickups.step(delta)
	game.powerups.step_drops(delta)
	for s in slots:
		bind(s.index)
		game.powerups.tick_buffs(delta)
	bind_primary()
	game.chests.step(delta)
	game.effects.step(delta)
	_step_downed(delta)
	if GameState.autotest and GameState.autotest_coop_down >= 0.0 and not _test_down_done and game.elapsed >= GameState.autotest_coop_down:
		_test_down()
	for s in slots:
		if game.elapsed < WaveData.RUN_DURATION and not s.downed:
			s.min_hp = minf(s.min_hp, s.player.hp)
	bind(view_slot)
	if pf != null:
		pf.lap(PerfProbe.SEC_PICKUPS, tl)


## --coop-bot: the bots of the slots past 0 drive their dash and ultimate and
## track their own numbers (slot 0's bot is Game's autotest, stepped first).
func step_bots(delta: float) -> void:
	for s in slots:
		if s.index == 0 or s.bot == null:
			continue
		bind(s.index)
		s.bot.step_slot(delta)
	bind(view_slot)


## Re-inserts every living enemy and every army's summons into the spatial
## hashes (Game._rebuild_grids() for both armies: enemies target any summon).
func _rebuild_grids() -> void:
	game.enemy_grid.clear()
	game.enemies.release_retired()  # Same retirement boundary as solo; neither army can see a recycled old entry.
	for e in game.enemies.active:
		if e.active and not e.untargetable:
			game.enemy_grid.insert(e, e.position)
	game.ally_grid.clear()
	for s in slots:
		for u in s.horde.units:
			if not u.airborne and not u.charmed:  # Act VI: a charmed summon is parked (Temptation).
				game.ally_grid.insert(u, u.position)


# =====================================================================================
# Downed and revive
# =====================================================================================

## Necromancer of slot `i` reached 0 HP (Necromancer.died): he lies downed and
## his army crumbles; with every slot down the run ends (a victory after 0:00,
## a defeat before, as solo).
func _on_player_down(i: int) -> void:
	var s := slots[i]
	if s.downed:
		return
	s.downed = true
	s.downs += 1
	s.revive_progress = 0.0
	s.player.modulate = Color(0.55, 0.55, 0.6, 0.8)  # Lying downed (visual only).
	game.stat_add("coop_downs", 1.0)
	var prev := bound
	bind(i)
	for u in s.horde.units.duplicate():
		s.horde.on_unit_died(u, false)  # The army crumbles (no death effects, no claims).
	bind(prev)
	game.effects.ring(s.player.position, 70.0, Palette.CRIMSON, 0.6)
	if GameState.autotest:
		print("[autotest] %s coop down: slot %d" % [Autotest._clock(game.elapsed), i])
	if game.hud != null:
		var lines: Array = CoopData.DOWN_BANNER_SELF if i == view_slot else CoopData.DOWN_BANNER_PARTNER  # This machine's own player, or the partner.
		game.hud.announce(String(lines[0]), String(lines[1]).replace("{name}", s.display_name), String(lines[2]), Palette.CRIMSON)
	if alive_slots().is_empty():
		wipe_time = game.elapsed
		if game.countdown_finished():
			game.end_run(true, "run_complete")
		else:
			game.end_run(false, "defeat")


## --coop-down test: knocks slot 1's (or --coop-down-slot='s) necromancer down with one lethal hit
## (through CombatResolver, as any hit), whatever his invulnerability.
func _test_down() -> void:
	_test_down_done = true
	var k := GameState.autotest_coop_down_slot if GameState.autotest_coop_down_slot in range(slots.size()) else slots.size() - 1  # --coop-down-slot= (default: the last slot).
	var p := slots[k].player
	var was := p.invulnerable
	p.invulnerable = false
	p.iframes = 0.0
	p.shield_hp = 0.0
	p.revives_left = 0
	game.combat.damage_player(p.max_hp * 100.0, "coop_test_down", p)
	p.invulnerable = was
	print("[autotest] %s coop test: slot %d knocked down (downed: %s)" % [Autotest._clock(game.elapsed), k, str(slots[k].downed)])


## Builds revive progress for every downed slot whose partner stands close,
## and raises the ones that are done.
func _step_downed(delta: float) -> void:
	for s in slots:
		if not s.downed:
			continue
		s.downed_time += delta
		var helper: CoopSlot = null  # A standing partner in revive reach.
		for o in slots:
			if o != s and o.alive() and o.player.position.distance_to(s.player.position) <= CoopData.REVIVE_RADIUS:
				helper = o
				break
		if helper == null:
			s.revive_progress = maxf(0.0, s.revive_progress - CoopData.REVIVE_DECAY * delta)
			continue
		s.revive_progress += delta
		if s.revive_progress >= CoopData.REVIVE_TIME:
			_revive(s, helper)


## Raises downed slot `s` (helped by `helper`): half HP, brief i-frames, every
## missing summon queued to rise at once.
func _revive(s: CoopSlot, helper: CoopSlot) -> void:
	var p := s.player
	s.downed = false
	s.revive_progress = 0.0
	p.dead = false
	p.hp = p.max_hp * CoopData.REVIVE_HP_FRACTION
	p.iframes = CoopData.REVIVE_IFRAMES
	p.modulate = Color.WHITE
	helper.revives_given += 1
	revives += 1
	if GameState.autotest:
		print("[autotest] %s coop revive: slot %d raised by slot %d" % [Autotest._clock(game.elapsed), s.index, helper.index])
	game.stat_add("coop_revives", 1.0)
	var prev := bound
	bind(s.index)
	s.horde.raise_all_missing()
	bind(prev)
	game.effects.ring(p.position, CoopData.REVIVE_RADIUS * 1.5, Palette.NECRO_GREEN, 0.6)
	if game.hud != null:
		var lines: Array = CoopData.RAISED_BANNER_SELF if s.index == view_slot else CoopData.RAISED_BANNER_PARTNER
		game.hud.announce(String(lines[0]), String(lines[1]).replace("{name}", s.display_name), String(lines[2]), Palette.NECRO_GREEN)


## Revive pull for the bot of the bound slot: toward a downed partner (zero
## when none is down). Autotest.get_move_vector() adds it.
func revive_vector(p: Necromancer) -> Vector2:
	for s in slots:
		if s.downed and s.player != p:
			var to := s.player.position - p.position
			if to.length() <= CoopData.BOT_REVIVE_HOLD:
				return Vector2.ZERO
			return to.normalized()
	return Vector2.ZERO


## True when the bound slot's bot stands in revive reach of a downed partner
## (it then holds its ground instead of fleeing).
func holding_revive(p: Necromancer) -> bool:
	for s in slots:
		if s.downed and s.player != p and s.player.position.distance_to(p.position) <= CoopData.BOT_REVIVE_HOLD:
			return true
	return false


## Cohesion pull for the bound slot's bot: toward the partner when farther
## than BOT_COHESION_RADIUS (zero otherwise).
func cohesion_vector(p: Necromancer) -> Vector2:
	for s in slots:
		if s.player != p and s.alive():
			var to := s.player.position - p.position
			if to.length() > CoopData.BOT_COHESION_RADIUS:
				return to.normalized()
	return Vector2.ZERO


# =====================================================================================
# Level-ups and chests
# =====================================================================================

## The shared bar crossed one or more levels: every pending level gives each
## slot one pick, slot 0 first. The simulation does not step until all picks
## are made (the bots pick at once; a human slot would wait for its panel and
## the partner's pick from the network: the next milestone).
func resolve_level_ups() -> void:
	while game.pending_level_ups > 0:
		for s in slots:
			bind(s.index)
			_bot_pick(s)
		game.pending_level_ups -= 1
		level_rounds += 1
	bind(view_slot)


## The bot of slot `s` picks one card (bound), with rerolls and banishes like
## the level-up panel's autotest path (LevelUpPanel._autoplay()).
func _bot_pick(s: CoopSlot) -> void:
	var ab := s.abilities
	var offers := ab.build_offers(PlayerData.CARDS_PER_LEVEL)
	for _guard in 64:
		if s.bot == null:
			ab.apply_offer(offers[0])
			return
		var act := s.bot.choose_action(offers)
		match String(act["action"]):
			"reroll":
				if ab.use_reroll():
					offers = ab.build_offers(PlayerData.CARDS_PER_LEVEL)
					continue
				ab.apply_offer(offers[0])
			"banish":
				var i := int(act["index"])
				if i >= 0 and i < offers.size() and ab.can_banish(offers[i]):
					offers = ab.banish_offer(offers, i)
					continue
				ab.apply_offer(offers[0])
			"skip":
				ab.apply_offer(ab.skip_offer())
			_:
				ab.apply_offer(offers[clampi(int(act["index"]), 0, offers.size() - 1)])
		return
	ab.apply_offer(offers[0])


## A treasure chest collected at `pos` by the bound slot: its rewards follow
## that player's build and apply at once. Online (lockstep) the opener's screen
## then shows the reveal and the run waits for his confirm on both machines
## (CoopLockstep.on_chest_opened()); the --coop-bot run never waits.
func open_chest(pos: Vector2) -> void:
	var s := slots[bound]
	var count := game.chests.roll_count()
	var rewards := game.abilities.chest_rewards(count)
	game.chests.record_opened(count, rewards)
	s.chests_opened += 1
	game.effects.ring(pos, 90.0, Palette.GOLD, 0.6, "chest_open")
	for o: Dictionary in rewards:
		if String(o["kind"]) == "evolution":
			game.effects.burst(Vector2.ZERO, AnimData.EVOLUTION_RADIUS, "evolution", game.player)
			break
	if lockstep != null:
		lockstep.on_chest_opened(s.index, rewards, count)  # Online: the opener's reveal holds both (CoopLockstep).


## A kill was dealt while the bound slot acted (CombatResolver._kill_enemy()).
func on_kill() -> void:
	if bound >= 0:
		slots[bound].kills += 1


# =====================================================================================
# Autotest report
# =====================================================================================

## Per-slot summary lines and the `coop` line (Autotest.finish()).
func print_report() -> void:
	for s in slots:
		var ab := s.abilities
		var picks := ab.pick_history
		var tail := picks.slice(maxi(0, picks.size() - 10))  # Last picks (the full list is long).
		print("[autotest] coop slot %d (%s, %s, policy %s): level %d | kills %d | min HP before 0:00 %d / %d | downs %d (%.0f s down), revives given %d | army %d alive, peak %d | chests %d | evolutions: %s | picks %d (last: %s)" % [
			s.index, s.display_name, s.character.id, "net" if lockstep != null else (s.bot.policy() if s.bot != null else "human"),
			game.level, s.kills, int(s.min_hp), int(s.player.max_hp), s.downs, s.downed_time, s.revives_given,
			s.horde.units.size(), s.peak_army, s.chests_opened,
			", ".join(ab.evolution_history) if not ab.evolution_history.is_empty() else "none",
			picks.size(), ", ".join(tail)])
		print("[autotest] coop slot %d build: actives %s | passives %s | volleys %s" % [
			s.index, _actives_line(s), _passives_line(s), s.volleys.summary_line()])
	var alive := alive_slots()
	print("[autotest] coop: slots %d | shared level %d (rounds %d) | kills %d | revives %d | downs %d | wipe %s | standing at end %d | peak enemies %d (hard cap %d) | xp mult %.2f, spawn x%.1f, boss HP x%.2f, miniboss HP x%.2f" % [
		slots.size(), game.level, level_rounds, game.kills, revives, int(game.stats.get("coop_downs", 0.0)),
		"at %s" % Autotest._clock(wipe_time) if wipe_time >= 0.0 else "never", alive.size(), peak_enemies, game.enemies.hard_cap(),
		game.difficulty.coop_mult("xp"), game.difficulty.coop_mult("enemy_spawn"), game.difficulty.coop_mult("boss_hp"),
		game.difficulty.coop_mult("miniboss_hp")])


## "id Lv" of slot `s`'s summon classes and spells (evolutions by name).
func _actives_line(s: CoopSlot) -> String:
	var out := PackedStringArray()
	for cls: String in UnitData.CLASS_ORDER:
		var lvl := int(s.horde.class_levels[cls])
		if lvl > 0:
			out.append("%s %d" % [s.horde.evolutions.class_plural(cls), lvl])
	for id: String in AbilityData.SPELL_ORDER:
		if s.abilities.spell_level(id) > 0:
			out.append("%s %d" % [s.abilities.spell_name(id), s.abilities.spell_level(id)])
	return ", ".join(out) if not out.is_empty() else "none"


## "id Lv" of slot `s`'s passives.
func _passives_line(s: CoopSlot) -> String:
	var out := PackedStringArray()
	for id: String in PassiveData.ORDER:
		if s.abilities.passive_level(id) > 0:
			out.append("%s %d" % [id, s.abilities.passive_level(id)])
	return ", ".join(out) if not out.is_empty() else "none"
