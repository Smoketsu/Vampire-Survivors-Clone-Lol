## LastClaim — THE LAST CLAIM, the Green Mother's third phase (temporary Act XV,
## the World-Tree, the campaign finale; GDD §15.0 "The Last Claim"; owner-approved
## proposal: "she remembers every power that ever claimed the dead, and the arena
## replays one signature rule of every act ... She can be hurt throughout"; owner
## answers, Nov 2026: "a random 7 of the 14 acts, picked with the run's seeded RNG,
## each act at most once, in a seeded order; 8 s each, from a third of her HP";
## the Norse slot is Berserkergang). Owned by BossGreenMother (`claim`), numbers
## in GreenMotherData.LAST_CLAIM / SLOTS.
## begin() picks the slots (the gameplay RNG: a shuffle of the fourteen, the
## first `slots`; --last-claim= forces a list for the autotest, GameState
## autotest_last_claim) and step() runs them one after another: each slot shows
## its banner, fires its call at each of its "pulses" (slot seconds) and lasts
## slot_time s, with `gap` s between two. Each call goes through that act's ONE
## existing path, reached through its forced-kind switch game.<key>_rules(): on
## the World-Tree the STAGE has none of those keys, so the act's rules object is
## built with its clocks off (`enabled` false: no Blood Moon timer, no
## escalation, no herds of their own, no Reckoning) and only this call does
## anything; nothing here runs on any other stage (only the Green Mother owns a
## LastClaim), so no other stage's same-seed summary can change. A rules object
## stays alive but inert after its slot (its own report line then prints too).
##   covenant           EnemyDirector.spawn_formation() with the Crimson March
##                      kinds (Act I has no rules object: the march is its path)
##   black_tide         spawn_formation() of Grapplers and a Boatswain, their
##                      CorsairKit bringing the rules (BoardingParty.launch_boat()
##                      refuses without a deck: no boat off the Black Tide)
##   sanguine_court     game.court_rules().moon.force(t) (the bosses' own moon
##                      call) and a pack of werewolves through spawn_formation()
##                      (the moon turns them: off the Court nobody else feeds)
##   last_line          spawn_formation() of the escalation's top tier (SWAT,
##                      riflemen), their CityKit bringing the rules (Escalation
##                      has no force call)
##   shogunate          game.shogunate_rules().draws.draw(null, from, dir, opts):
##                      free-standing iai lines across each necromancer
##   hall_of_the_slain  game.norse_rules().enter_fury(e, true) on every Wild
##                      enemy in reach (Berserkergang; never a boss, a miniboss
##                      or a structure)
##   necropolis_dynasty game.dynasty_rules() and the Dynasty's own dead through
##                      spawn_formation(): each that falls gets its cartouche
##                      through Rebirth.on_death() (a Wild kind carries no Name)
##   olympian_republic  game.pantheon_rules().wrath.strike(kind, at)
##   inferno            game.inferno_rules().pits.open_pit(at, r, life)
##   celestial_host     game.host_rules().judgment.send_wave(n) (the scales stay
##                      empty off the Host: Judgment.fill() refuses)
##   ancient_eye        game.claims_rules().mark(u, until, life, tint, name) on
##                      the summons nearest each necromancer: one that falls in
##                      the slot rises as her Thrall (HordeDirector.claim_fallen())
##   electronic_empire  game.empire_rules().lock_on.paint(boss, target, ...),
##                      three lines at once (the boss override)
##   concord            game.concord_rules().beams.fire(null, dir, style, ...):
##                      ownerless beams aimed through each necromancer
##   age_of_titans      game.primeval_rules().herds.spawn_herd(at, n, kinds, at
##                      the necromancer): launched at once
## Every effect keeps its own act's damage tag (so the `wild damage` line shows
## which replay hurt most); co-op runs the same calls in the lockstep simulation
## (game.all_players, spawn_formation()'s own copies; no machine-local state).
## Determinism: the seeded gameplay RNG (the pick, the angles), game time.
## Stats: last_claim_slots, last_claim_<id> (each slot's effects: bodies
## spawned, lines drawn, pits opened, furies, marks, beams...).
class_name LastClaim
extends RefCounted

## The boss who claims (null after the fight; generation-checked by the boss).
var boss: Enemy = null
## Slot rows picked for this fight (GreenMotherData.SLOTS rows, in run order).
var picked: Array[Dictionary] = []
## Index into `picked` of the slot running or next (picked.size() = done).
var index: int = 0
## True once begin() ran.
var started: bool = false
## Game time (s) it began.
var started_at: float = 0.0
## Game time (s) the current slot began (INF while waiting for the next).
var slot_at: float = INF
## Game time (s) the next slot begins.
var next_at: float = 0.0
## Pulses of the current slot already fired.
var pulses_done: int = 0
## Slot id -> effects counted (the report).
var effects: Dictionary = {}
## True when the slot list came from --last-claim= (the report says so).
var forced: bool = false


## Builds the Last Claim of boss `p_boss`.
func _init(p_boss: Enemy) -> void:
	boss = p_boss


## The slot row of id `id` ({} when unknown).
static func slot_of(id: String) -> Dictionary:
	for s: Dictionary in GreenMotherData.SLOTS:
		if String(s["id"]) == id:
			return s
	return {}


## True while a slot runs (the boss rests her Turning and Burial).
func in_slot() -> bool:
	return started and slot_at != INF


## True once every picked slot ran.
func done() -> bool:
	return started and index >= picked.size()


## THE LAST CLAIM begins: the slots are picked (see the header).
func begin() -> void:
	var g := boss.game
	started = true
	started_at = g.elapsed
	var want: Array = GameState.autotest_last_claim if GameState.autotest else []
	if not want.is_empty():
		forced = true
		for id: String in want:
			var row := slot_of(id)
			if not row.is_empty():
				picked.append(row)
	else:
		var pool: Array[Dictionary] = GreenMotherData.SLOTS.duplicate()
		for i in range(pool.size() - 1, 0, -1):  # Fisher-Yates with the seeded gameplay RNG.
			var j := randi() % (i + 1)
			var t := pool[i]
			pool[i] = pool[j]
			pool[j] = t
		for k in mini(int(GreenMotherData.LAST_CLAIM["slots"]), pool.size()):
			picked.append(pool[k])
	next_at = g.elapsed
	g.stat_add("boss_atk_last_claim", 1.0)
	g.enemies.show_banner(String(GreenMotherData.LAST_CLAIM["banner"]))
	g.shake(8.0)


## Per tick (the boss's physics): opens the next slot on time, fires its
## pulses, closes it after slot_time s.
func step() -> void:
	if not started or done():
		return
	var g := boss.game
	var now := g.elapsed
	if slot_at == INF:
		if now < next_at:
			return
		slot_at = now
		pulses_done = 0
		var row := picked[index]
		effects[String(row["id"])] = int(effects.get(String(row["id"]), 0))
		g.stat_add("last_claim_slots", 1.0)
		g.enemies.show_banner(String(row["banner"]))
		g.effects.ring(boss.position, boss.radius * 3.0, GreenMotherData.BLOOM, 0.6)
	var row := picked[index]
	var pulses: Array = row["pulses"]
	while pulses_done < pulses.size() and now - slot_at >= float(pulses[pulses_done]):
		pulses_done += 1
		var n := _call(row)
		effects[String(row["id"])] = int(effects[String(row["id"])]) + n
		g.stat_add("last_claim_" + String(row["id"]), float(n))
	if now - slot_at >= float(GreenMotherData.LAST_CLAIM["slot_time"]):
		slot_at = INF
		index += 1
		next_at = now + float(GreenMotherData.LAST_CLAIM["gap"])


## The boss fell: the claim ends where it stands.
func stop() -> void:
	slot_at = INF
	index = picked.size()


## Fires slot `row`'s call once; returns its effects (see the header).
func _call(row: Dictionary) -> int:
	var g := boss.game
	match String(row["id"]):
		"covenant", "black_tide", "last_line":
			return _formation(row)
		"sanguine_court":
			g.court_rules().moon.force(float(row["moon"]))
			return 1 + _formation(row)
		"necropolis_dynasty":
			g.dynasty_rules()  # Rebirth listens from now on (DynastyRules.on_enemy_died()).
			return _formation(row)
		"shogunate":
			var draws := g.shogunate_rules().draws
			var n := 0
			for pl in g.all_players:
				if pl.dead:
					continue
				for k in int(row["lines"]):
					var dir := Vector2.from_angle(randf() * TAU)
					var ln := float(row["length"])  # px
					if draws.draw(null, pl.position - dir * ln * 0.5, dir, {"flash": float(row["flash"]), "length": ln, "boss_override": true}):
						n += 1
			return n
		"hall_of_the_slain":
			var norse := g.norse_rules()
			var n := 0
			for e in g.enemies.active:
				if n >= int(row["most"]):
					break
				if not e.active or e.berserk or e.is_boss or e.is_miniboss or e.is_structure or not (e.kit is WildKit):
					continue
				var near := g.nearest_player(e.position)
				if near != null and near.position.distance_to(e.position) <= float(row["reach"]):
					norse.enter_fury(e, true)
					n += 1
			return n
		"olympian_republic":
			var wrath := g.pantheon_rules().wrath
			var n := 0
			for pl in g.all_players:
				if not pl.dead:
					n += wrath.strike(String(row["wrath"]), pl.position)
			return n
		"inferno":
			var pits := g.inferno_rules().pits
			var n := 0
			for pl in g.all_players:
				if pl.dead:
					continue
				var a0 := randf() * TAU
				for k in int(row["pits"]):
					var at := pl.position + Vector2.from_angle(a0 + TAU * float(k) / float(row["pits"])) * float(row["pit_ring"])
					if pits.open_pit(at, float(row["pit_radius"]), float(row["pit_life"])):
						n += 1
			return n
		"celestial_host":
			return g.host_rules().judgment.send_wave(int(row["judges"]))
		"ancient_eye":
			var claims := g.claims_rules()
			var until := g.elapsed + float(GreenMotherData.LAST_CLAIM["slot_time"])
			var n := 0
			for i in g.all_hordes.size():
				var pl := g.all_players[mini(i, g.all_players.size() - 1)]  # The army's necromancer (all_players and all_hordes share the slot order).
				var marked := 0
				for u in _nearest_summons(g.all_hordes[i], pl.position, int(row["marks"])):
					claims.mark(u, until, float(row["thrall_life"]), row["tint"], String(row["name"]))
					g.effects.ring(u.position, u.radius * 1.8, row["tint"], 0.4)
					marked += 1
				n += marked
			return n
		"electronic_empire":
			var lock := g.empire_rules().lock_on
			var dmg := float(row["damage"]) * g.enemies.damage_mult * boss.hit_mult()
			var targets: Array[Node2D] = []
			for pl in g.all_players:
				if not pl.dead:
					targets.append(pl)
			for hd in g.all_hordes:
				for u in _nearest_summons(hd, boss.position, int(row["lines"])):
					if targets.size() < int(row["lines"]) * g.all_players.size():
						targets.append(u)
			var n := 0
			for t in targets:
				if n >= int(row["lines"]) * g.all_players.size():
					break
				if lock.paint(boss, t, dmg, float(row["speed"]), float(row["reach"]), String(row["tag"]), true):
					n += 1
			return n
		"concord":
			var beams := g.concord_rules().beams
			var n := 0
			for pl in g.all_players:
				if pl.dead:
					continue
				for k in int(row["beams"]):
					var dir := Vector2.from_angle(randf() * TAU)
					var origin := pl.position - dir * float(row["beam_ring"])
					if beams.fire(null, dir, String(row["style"]), {"origin": origin, "length": float(row["length"]), "side": 1 if k % 2 == 0 else -1}, true):
						n += 1
			return n
		"age_of_titans":
			var herds := g.primeval_rules().herds
			var n := 0
			for pl in g.all_players:
				if pl.dead:
					continue
				var at := g.arena.free_point(pl.position + Vector2.from_angle(randf() * TAU) * float(row["herd_dist"]), 24.0)
				var h := herds.spawn_herd(at, int(row["herd"]), row["herd_kinds"], pl.position)
				n += h.members.size()
			return n
	return 0


## A formation wave of the slot's groups (EnemyDirector.spawn_formation(); co-op
## copies its own); returns the enemies it brought.
func _formation(row: Dictionary) -> int:
	var g := boss.game
	var before := g.enemies.active.size()
	g.enemies.spawn_formation(String(row["formation"]), row["groups"])
	return maxi(0, g.enemies.active.size() - before)


## Up to `n` grounded living summons of army `hd` nearest `from` (in the
## army's order for ties).
func _nearest_summons(hd: HordeDirector, from: Vector2, n: int) -> Array[SummonedUnit]:
	var out: Array[SummonedUnit] = []
	var cand: Array[SummonedUnit] = []
	for u in hd.units:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.state != SummonedUnit.State.DEAD and not u.airborne:
			cand.append(u)
	while out.size() < n and not cand.is_empty():
		var best := 0
		for k in range(1, cand.size()):
			if cand[k].position.distance_to(from) < cand[best].position.distance_to(from):
				best = k
		out.append(cand[best])
		cand.remove_at(best)
	return out


## One autotest summary line of the claim.
func summary_line() -> String:
	if not started:
		return "never began"
	var parts := PackedStringArray()
	for i in picked.size():
		var id := String(picked[i]["id"])
		parts.append("%s %s" % [id, str(effects[id]) if effects.has(id) else "-"])
	return "began %s%s | slots %d of %d ran: %s" % [EmpireReport._clock(started_at), " (forced)" if forced else "",
		effects.size(), picked.size(), ", ".join(parts)]
