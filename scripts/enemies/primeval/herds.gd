## Herds — HERDS, the second shared rule of the Age of Titans (temporary Act
## XIV; GDD §15.0 "Herds"; owner-approved proposal: "Big herbivores (Longnecks,
## Duckbills) wander the arena as neutral bodies. They do not attack. They drop
## big XP and a heavy corpse when killed, and they stampede when hurt or when a
## fight is close: a living front 600 px wide runs in a telegraphed straight
## direction (dust line 2 s ahead), trampling everyone it crosses, both armies.
## Rocks and fossil arches are shelter. A heavy corpse raises as a Fossil Giant
## (a temporary summon: HP x4, lasts 30 s, at most 2 alive) through
## HordeDirector.raise_corpse() / spawn_temporary(). One path: Herds"), owned by
## Game.primeval as `herds`. THE one path:
##   * THE HERDS COME (step(); a Titans stage only): the first `first` s in,
##     then every `every` s while fewer than `cap` beasts graze, a herd of
##     `size` beasts (`kinds`, cycled) comes on `spawn_dist` px from a standing
##     necromancer at a seeded angle (EnemyDirector.spawn_at()). A herd kind
##     forced elsewhere (--spawn=) forms its own herd (`form_window`).
##   * GRAZING (steer(), the herd kit's every tick: a herd beast never
##     attacks): each beast drifts at x graze_mult speed, its drift turning
##     every `drift_every` s (pure hashes), held near its herd and drawn back
##     toward the nearest necromancer past `graze_radius` px.
##   * THE STAMPEDE (launch()): when one beast is hurt, or one stands within
##     its row's `fright` px of a standing necromancer, its whole herd
##     stampedes (once every `cooldown` s): the run's line points from the
##     herd's centre AWAY from what frightened it (owner answer, Nov 9, 2026:
##     "stampedes run away from whatever hurt the herd"; _fright_point(): for
##     a hurt beast the nearest summon within fright_probe px of it when one
##     is nearer than the necromancer, else that necromancer); the Stampede of
##     Ash and the bosses aim theirs (launch() takes the point to run at); for
##     `lead` s the dust line shows
##     where the front will be (WARN: the beasts paw the ground), then the
##     front runs `run_length` px at `run_speed` px/s (RUN: each beast runs the
##     line, over the ring: Enemy.vehicle, the Convoy's flag, while it runs).
##   * THE TRAMPLE (_trample()): every body the front crosses (`width` x
##     `depth` px round its centre line) is hit once a run, both armies:
##     summons (trample_summon x the time scaling x Thick Marrow's hook, thrown
##     `knock` px along the run), the necromancer (trample_player; Grave Step's
##     i-frames dodge it) and every other enemy (trample_enemy_share of its max
##     HP: lure the hunters into it; bosses, minibosses, structures and
##     objectives are never trampled). SHELTER: a body with an obstacle within
##     `shelter_len` px upstream (toward the oncoming front:
##     Arena.clear_length()) is passed around.
##   * THE HEAVY CORPSE (on_killed()): a herd beast killed within giant
##     `reach` px of a standing necromancer rises for him as a FOSSIL GIANT
##     (HordeDirector.raise_corpse(): giant `class` x hp_mult, `life` s), at
##     most giant `cap` alive; the corpse path's own gates apply
##     (Enemy.leaves_corpse()).
##   * THE TAR (Act XIV, the Fern Basin): a beast the tar holds
##     (HerdBeastKit.stuck_until, FernBasinDirector) stands where it is in
##     every state and never frightens its herd: a free kill.
## The Stampede of Ash (the Reckoning) brings its own herds through
## spawn_herd(..., launch) over the cap. Summons never get a rule here: the
## trample is a hazard through CombatResolver, and the Fossil Giant a temporary
## summon of an existing class through the one raise path. Determinism: game
## time, pure hashes and the seeded gameplay RNG (the herds' angle); herds are
## an ordered list with pooling generations. Stats (the "herds" line):
## herds_spawned, herd_stampedes, trample_summons, trample_summon_dmg,
## trample_player, trample_enemies, trample_kills, trample_sheltered,
## herd_kills, fossil_giants, fossil_giants_capped, fossil_giants_far.
class_name Herds
extends RefCounted

## Herd state: the beasts graze.
const GRAZE: int = 0
## Herd state: the dust line shows; the beasts paw the ground.
const WARN: int = 1
## Herd state: the front runs.
const RUN: int = 2


## One herd: its beasts in joining order and its stampede.
class Herd:
	## Beasts in joining order (live and gone; check `gens`).
	var members: Array[Enemy] = []
	## Pool generation of each beast when it joined (same order).
	var gens: Array[int] = []
	## GRAZE, WARN or RUN.
	var state: int = 0
	## Game seconds spent in the current state.
	var state_t: float = 0.0
	## Game time (s) the herd opened (the forming window).
	var opened_at: float = 0.0
	## Game time (s) before which it cannot stampede again.
	var ready_at: float = 0.0
	## The run's direction (unit).
	var dir: Vector2 = Vector2.RIGHT
	## The front's centre at the start of the run (px).
	var origin: Vector2 = Vector2.ZERO
	## Bodies (SummonedUnit, Necromancer, Enemy) the front already hit this run.
	var hit: Array = []
	## True for a Stampede of Ash herd (launched as it came; over the cap).
	var ash: bool = false


## Owning run.
var game: Game
## True on a Titans stage: the herds come on their own.
var enabled: bool = false
## The herds' numbers (HERDS with the STAGE's "herds").
var cfg: Dictionary = {}
## Live herds, in opening order.
var herds: Array[Herd] = []
## Herd beasts alive now (note_spawn() / note_gone()).
var alive: int = 0
## Most herd beasts alive at once (the report).
var peak: int = 0
## Herds that came this run (the clock's and the Reckoning's).
var spawned: int = 0
## Stampedes launched this run.
var stampedes: int = 0
## Live Fossil Giants: [SummonedUnit, its generation] each.
var giants: Array = []
## The herd that spawn_herd() is filling now (its beasts join it; null between calls).
var _forming: Herd = null
## Game time (s) of the next herd (INF = the clock is off).
var _next: float = INF
## True when this build draws (never headless).
var _draws: bool = false
## Scratch buffer for grid queries (_fright_point()).
var _buf: Array = []


## Builds Herds for `p_game`; `p_enabled`: a Titans stage.
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	enabled = p_enabled
	cfg = PrimevalRulesData.HERDS.duplicate()
	var over: Dictionary = p_game.stage_def.get("herds", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	if enabled and int(cfg["cap"]) > 0:
		_next = float(cfg["first"])
	_draws = DisplayServer.get_name() != "headless"


## True while a herd's dust line or front shows (PrimevalRules redraws).
func showing() -> bool:
	if not _draws:
		return false
	for h in herds:
		if h.state != GRAZE:
			return true
	return false


## A herd kind's enemy `e` came onto the field: it joins the herd being
## spawned, else the newest one while it is forming, else opens one.
func note_spawn(e: Enemy, kit: HerdBeastKit) -> void:
	var h := _forming
	if h == null and not herds.is_empty():
		var last := herds[herds.size() - 1]
		if game.elapsed - last.opened_at <= float(cfg["form_window"]) and last.state == GRAZE:
			h = last
	if h == null:
		h = _open(false)
	h.members.append(e)
	h.gens.append(e.generation)
	kit.herd = h
	kit.last_hp = e.hp
	kit.hurt = false
	alive += 1
	peak = maxi(peak, alive)


## A herd beast left the field (killed, recycled away, pooled).
func note_gone(_e: Enemy) -> void:
	alive = maxi(0, alive - 1)


## Opens a new herd (`ash`: a Stampede of Ash herd).
func _open(ash: bool) -> Herd:
	var h := Herd.new()
	h.opened_at = game.elapsed
	h.ash = ash
	herds.append(h)
	return h


## Brings a herd of `n` beasts (`kinds`, cycled) on round `center`; when
## `launch_at` is not INF it stampedes at once toward that point (the
## Stampede of Ash). Returns the herd (empty when nothing could spawn).
func spawn_herd(center: Vector2, n: int, kinds: Array, launch_at: Vector2 = Vector2.INF) -> Herd:
	var h := _open(launch_at != Vector2.INF)
	_forming = h
	var spread := float(cfg["spawn_spread"])
	for i in n:
		var at := center + Vector2.from_angle(TAU * float(i) / float(maxi(1, n))) * spread * (0.0 if i == 0 else 1.0)
		var kind := String(kinds[i % kinds.size()])
		game.enemies.spawn_at(kind, game.arena.free_point(at, 24.0), false)
	_forming = null
	if h.members.is_empty():
		herds.erase(h)
		return h
	spawned += 1
	game.stat_add("herds_spawned", 1.0)
	if launch_at != Vector2.INF:
		launch(h, launch_at)
	return h


## Per tick (PrimevalRules.step()): the herds' clock, each herd's stampede.
func step(delta: float) -> void:
	if game.elapsed >= _next:
		_next = game.elapsed + float(cfg["every"])
		if alive + int(cfg["size"]) <= int(cfg["cap"]):
			_spawn_auto()
	var i := herds.size() - 1
	while i >= 0:
		var h := herds[i]
		if not _alive(h):
			herds.remove_at(i)
			i -= 1
			continue
		h.state_t += delta
		match h.state:
			GRAZE:
				if game.elapsed >= h.ready_at:
					var from := _frightened_by(h)
					if from != Vector2.INF:
						launch(h, centre(h) * 2.0 - from)  # Owner answer: away from what frightened the herd.
			WARN:
				if h.state_t >= float(cfg["lead"]):
					h.state = RUN
					h.state_t = 0.0
					_set_running(h, true)
					game.primeval.play_sound("stampede_run", h.origin, 0.5)
			RUN:
				_trample(h)
				if h.state_t * float(cfg["run_speed"]) >= float(cfg["run_length"]):
					h.state = GRAZE
					h.state_t = 0.0
					h.ready_at = game.elapsed + float(cfg["cooldown"])
					_set_running(h, false)
		i -= 1
	giants = giants.filter(func(g: Array) -> bool: return (g[0] as SummonedUnit).active and (g[0] as SummonedUnit).generation == int(g[1]))


## The clock's herd: round a standing necromancer at a seeded angle.
func _spawn_auto() -> void:
	var standing: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			standing.append(pl)
	if standing.is_empty():
		return
	var pl: Necromancer = standing[randi() % standing.size()]
	var at := pl.position + Vector2.from_angle(randf() * TAU) * float(cfg["spawn_dist"])
	spawn_herd(at, int(cfg["size"]), cfg["kinds"])


## True while herd `h` has a living beast.
func _alive(h: Herd) -> bool:
	for i in h.members.size():
		if h.members[i].active and h.members[i].generation == h.gens[i]:
			return true
	return false


## The point that frightens herd `h` (Vector2.INF = none): for a beast hurt
## since the last tick, or one within its row's `fright` px of a standing
## necromancer, _fright_point() of the first such beast. Clears the beasts'
## hurt flags. A beast the tar holds frightens nobody (Act XIV, the Fern Basin).
func _frightened_by(h: Herd) -> Vector2:
	var from := Vector2.INF
	for i in h.members.size():
		var m := h.members[i]
		if not m.active or m.generation != h.gens[i]:
			continue
		var kit := m.kit as HerdBeastKit
		var pl := game.nearest_player(m.position)
		if pl == null or pl.dead or kit.stuck_until > game.elapsed:
			kit.hurt = false
			continue
		if from == Vector2.INF and kit.hurt:
			from = _fright_point(m, pl)
		elif from == Vector2.INF and m.position.distance_to(pl.position) <= float(kit.d.get("fright", 0.0)):
			from = pl.position
		kit.hurt = false
	return from


## What hurt beast `m` (owner answer: the stampede runs away from it): the
## nearest live summon within fright_probe px of it when that summon is
## nearer than necromancer `pl`, else `pl`'s position (his spells, his ring).
func _fright_point(m: Enemy, pl: Necromancer) -> Vector2:
	var best := pl.position
	var best_d := m.position.distance_to(pl.position)
	game.ally_grid.query(m.position, float(cfg["fright_probe"]), _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD:
			continue
		var dd := u.position.distance_to(m.position)
		if dd < best_d:
			best_d = dd
			best = u.position
	return best


## THE stampede: herd `h` runs at `toward` (see the header).
func launch(h: Herd, toward: Vector2) -> void:
	var c := centre(h)
	var to := toward - c
	h.dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	h.origin = c - h.dir * float(cfg["front_back"])
	h.state = WARN
	h.state_t = 0.0
	h.hit.clear()
	stampedes += 1
	game.stat_add("herd_stampedes", 1.0)
	game.primeval.play_sound("stampede_warn", c, 0.6)


## The centre of herd `h`'s living beasts.
func centre(h: Herd) -> Vector2:
	var sum := Vector2.ZERO
	var n := 0
	for i in h.members.size():
		if h.members[i].active and h.members[i].generation == h.gens[i]:
			sum += h.members[i].position
			n += 1
	return sum / float(n) if n > 0 else h.origin


## Marks herd `h`'s beasts as running over the ring (Enemy.vehicle) or not.
func _set_running(h: Herd, on: bool) -> void:
	for i in h.members.size():
		if h.members[i].active and h.members[i].generation == h.gens[i]:
			h.members[i].vehicle = on


## The front's centre line now (WARN: where it starts).
func front(h: Herd) -> Vector2:
	if h.state == RUN:
		return h.origin + h.dir * float(cfg["run_speed"]) * h.state_t
	return h.origin


## True when a body of radius `r` at `p` stands in herd `h`'s front.
func in_front(h: Herd, p: Vector2, r: float) -> bool:
	var rel := p - front(h)
	return absf(rel.dot(h.dir)) <= float(cfg["depth"]) * 0.5 + r and absf(rel.dot(h.dir.orthogonal())) <= float(cfg["width"]) * 0.5


## True when a body of radius `r` at `p` is sheltered from herd `h` (an
## obstacle within shelter_len px upstream).
func sheltered(h: Herd, p: Vector2, r: float) -> bool:
	var reach := float(cfg["shelter_len"])  # px looked upstream.
	return game.arena.clear_length(p, -h.dir, reach, maxf(2.0, r * 0.5)) < reach - 0.5


## One trample tick of running herd `h` (see the header).
func _trample(h: Herd) -> void:
	var ts := game.enemies.damage_mult  # The time scaling (and the difficulty).
	var any := false
	for hd in game.all_hordes:
		for u in hd.units:
			if not u.active or u.state == SummonedUnit.State.SPAWNING or u.airborne or u.flies or h.hit.has(u):
				continue
			if not in_front(h, u.position, u.radius):
				continue
			h.hit.append(u)
			if sheltered(h, u.position, u.radius):
				game.stat_add("trample_sheltered", 1.0)
				continue
			var dmg := float(cfg["trample_summon"]) * ts * game.primeval.thick_marrow_mult()  # Thick Marrow: exactly 1 until phase 2 builds it.
			game.combat.damage_unit(u, dmg, PrimevalRulesData.TRAMPLE_SOURCE)
			u.position += h.dir * float(cfg["knock"])
			game.stat_add("trample_summons", 1.0)
			game.stat_add("trample_summon_dmg", dmg)
			any = true
	for pl in game.all_players:
		if pl.dead or h.hit.has(pl) or not in_front(h, pl.position, pl.radius):
			continue
		h.hit.append(pl)
		if sheltered(h, pl.position, pl.radius):
			game.stat_add("trample_sheltered", 1.0)
			continue
		game.combat.damage_player(float(cfg["trample_player"]) * ts, PrimevalRulesData.TRAMPLE_SOURCE, pl)
		game.stat_add("trample_player", 1.0)
		any = true
	for e in game.enemies.active:
		if not e.active or e.kit is HerdBeastKit or e.is_boss or e.is_miniboss or e.is_structure or e.is_objective or h.hit.has(e):
			continue
		if not in_front(h, e.position, e.radius):
			continue
		h.hit.append(e)
		if sheltered(h, e.position, e.radius):
			game.stat_add("trample_sheltered", 1.0)
			continue
		game.combat.damage_enemy(e, e.max_hp * float(cfg["trample_enemy_share"]), PrimevalRulesData.TRAMPLE_SOURCE)
		game.stat_add("trample_enemies", 1.0)
		if not e.active:
			game.stat_add("trample_kills", 1.0)
		any = true
	if any:
		game.primeval.play_sound("trample", front(h), 0.25)


## THE one steering call of a herd kit (HerdBeastKit.physics(); always owns the
## tick: a herd beast never attacks).
func steer(e: Enemy, kit: HerdBeastKit, delta: float) -> bool:
	if e.hp < kit.last_hp - 0.001:
		kit.hurt = true
	kit.last_hp = e.hp
	var h := kit.herd
	kit.trapped = kit.stuck_until > game.elapsed
	if h == null or kit.trapped:
		kit.hold(e)  # No herd, or the tar holds it (Act XIV, the Fern Basin).
		return true
	match h.state:
		WARN:
			kit.hold(e)
		RUN:
			PrimevalKit.move(e, h.dir, float(cfg["run_speed"]), delta)
		_:
			var dir := _drift(e)
			var c := centre(h)
			if e.position.distance_to(c) > float(cfg["spawn_spread"]) * 1.5:
				dir = (dir + (c - e.position).normalized()).normalized()
			var pl := game.nearest_player(e.position)
			if pl != null and e.position.distance_to(pl.position) > float(cfg["graze_radius"]):
				dir = (dir * 0.3 + (pl.position - e.position).normalized()).normalized()
			PrimevalKit.move(e, dir, e.move_speed * float(cfg["graze_mult"]), delta)
	return true


## Beast `e`'s grazing drift now (unit; a pure hash of its slot, its pool
## generation and the drift period, so it turns every drift_every s).
func _drift(e: Enemy) -> Vector2:
	var period := int(floorf((game.elapsed + float(e.think_slot) * 0.37) / float(cfg["drift_every"])))
	var hv := absi(hash(Vector3i(e.think_slot, e.generation, period)))
	return Vector2.from_angle(float(hv % 3600) / 3600.0 * TAU)


## A herd beast was killed (HerdBeastKit.on_killed()): its heavy corpse may
## rise as a Fossil Giant (see the header).
func on_killed(e: Enemy) -> void:
	game.stat_add("herd_kills", 1.0)
	if (e.kit as HerdBeastKit).stuck_until > game.elapsed:
		game.stat_add("herd_kills_trapped", 1.0)  # Act XIV, the Fern Basin: a free kill in the tar.
	if not e.leaves_corpse():
		return
	var gc: Dictionary = cfg["giant"]
	var pl := game.nearest_player(e.position)
	if pl == null or pl.dead or pl.position.distance_to(e.position) > float(gc["reach"]):
		game.stat_add("fossil_giants_far", 1.0)
		return
	if giants.size() >= int(gc["cap"]):
		game.stat_add("fossil_giants_capped", 1.0)
		return
	var prev := -1
	if game.coop != null:
		prev = game.coop.bound
		game.coop.bind_nearest(e.position)
	var glyph := "fossil_giant" if SpriteBank.has(String(gc["sprite"])) else ""  # Its art once the art pass adds it; the class's look until then.
	var u := game.horde.raise_corpse(String(gc["class"]), e.position, float(gc["life"]), float(gc["hp_mult"]), float(gc["dmg_mult"]),
			String(gc["tag"]), glyph, false)
	if prev >= 0:
		game.coop.bind(prev)
	if u == null:
		return
	giants.append([u, u.generation])
	game.stat_add("fossil_giants", 1.0)
	game.effects.ring(u.position, 28.0, Palette.PRIMEVAL_BONE, 0.5)
	game.primeval.play_sound("fossil_rise", u.position, 0.5)


## The autotest autopilot's push sideways out of every stampede's path at `p`
## (toward the nearer edge of the front), unless an obstacle shelters it.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for h in herds:
		if h.state == GRAZE:
			continue
		var rel := p - front(h)
		var along := rel.dot(h.dir)
		var lat := rel.dot(h.dir.orthogonal())
		var left := float(cfg["run_length"]) - (float(cfg["run_speed"]) * h.state_t if h.state == RUN else 0.0)  # px the front still runs.
		if along < -float(cfg["depth"]) or along > left or absf(lat) > float(cfg["width"]) * 0.5 + 30.0:
			continue
		if sheltered(h, p, 10.0):
			continue
		push += h.dir.orthogonal() * (1.5 if lat >= 0.0 else -1.5)
	return push


## Draws every stampede on `ci` (PrimevalRules' layer): the dust line `lead` s
## ahead of the front and, while it runs, the front's dust (rotated rects only).
func draw(ci: CanvasItem) -> void:
	var w := float(cfg["width"])
	var depth := float(cfg["depth"])
	for h in herds:
		if h.state == GRAZE:
			continue
		var ahead := float(cfg["run_speed"]) * (h.state_t if h.state == WARN else float(cfg["lead"]))  # The dust line: where the front is in `lead` s.
		ci.draw_set_transform(front(h), h.dir.angle(), Vector2.ONE)
		ci.draw_rect(Rect2(Vector2(ahead - 1.5, -w * 0.5), Vector2(3.0, w)), Color(Palette.PRIMEVAL_OCHRE, 0.8))
		if h.state == RUN:
			ci.draw_rect(Rect2(Vector2(-depth * 0.5, -w * 0.5), Vector2(depth, w)), Color(Palette.PRIMEVAL_OCHRE_DARK, 0.3))
			ci.draw_rect(Rect2(Vector2(depth * 0.1, -w * 0.5), Vector2(depth * 0.4, w)), Color(Palette.PRIMEVAL_OCHRE, 0.25))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
