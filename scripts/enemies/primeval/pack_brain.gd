## PackBrain — PACKS, the first (headline) shared rule of the Age of Titans
## (temporary Act XIV; GDD §15.0 "Packs"; owner-approved proposal: "Predators
## hunt in packs with an alpha. A pack circles the ring for a moment, holds
## 1.5 s, and rushes together with +40% speed and a flank path. Kill the alpha
## and the pack loses its bonus and charges straight in, uncoordinated. A pack
## is a group in the spawn timeline with one alpha flagged. One path:
## PackBrain, a per-group steering state the enemy kit reads"), owned by
## Game.primeval as `packs`. THE one path:
##   * FORMING (note_spawn()): a pack kind (row "pack") that comes onto the
##     field within PACKS form_window s of the newest pack's opening joins it
##     (a timeline group spawns in one tick), up to max_size; else it opens a
##     new pack and is its ALPHA.
##   * THE HUNT, one state per pack (step()):
##       STALK  — the default AI (enemies always advance) until the alpha is
##                within `engage` px of the nearest standing necromancer, who
##                becomes the pack's prey;
##       CIRCLE — `circle_time` s: every member runs to its post on a circle
##                `circle_radius` px round the prey (posts `spread` rad apart
##                round the alpha's angle, the flanks), the circle turning
##                `orbit` rad/s;
##       HOLD   — `hold` s: the pack stands, facing its prey;
##       RUSH   — up to `rush_time` s: every member runs straight at the prey
##                from its post, at x rush_mult speed;
##       DONE   — the default AI (each member fights where it stands).
##     A member a blocker holds (Enemy.engaged_timer) fights at once.
##   * THE ALPHA (on_killed()): when the alpha is killed the pack is BROKEN:
##     no circle, no hold, no rush bonus: every member charges straight in
##     through the default AI. A pack whose alpha merely left the field (pooled
##     at the run's end, recycled) is broken too, without the kill.
##   * steer(e, kit, delta) is THE one call a pack kind's kit makes in
##     physics(): true while the pack owns the member's tick.
## Off the act (a forced Razorclaw elsewhere) the packs still form and hunt:
## the rule is the kind's. Summons never get a rule here: Bone Hounds' Pack
## Hunt is a summon feature and unrelated. Determinism: no RNG (the circle's
## angle is the alpha's own bearing); packs are an ordered list with pooling
## generations. Stats (the "packs" line): packs_formed, pack_circles,
## pack_rushes, pack_alphas_slain, pack_broken_members.
class_name PackBrain
extends RefCounted

## Pack state: the default AI until the alpha comes within `engage` px.
const STALK: int = 0
## Pack state: running to the posts of the circle.
const CIRCLE: int = 1
## Pack state: standing on the circle.
const HOLD: int = 2
## Pack state: the rush.
const RUSH: int = 3
## Pack state: the hunt is over (the default AI).
const DONE: int = 4


## One pack: its members in joining order (the first is its alpha).
class Pack:
	## Members in joining order (live and gone; check `gens`).
	var members: Array[Enemy] = []
	## Pool generation of each member when it joined (same order).
	var gens: Array[int] = []
	## The alpha (the first member).
	var alpha: Enemy = null
	## The alpha's pool generation when it joined.
	var alpha_gen: int = 0
	## True once the alpha fell or left: no circle, no bonus.
	var broken: bool = false
	## STALK, CIRCLE, HOLD, RUSH or DONE.
	var state: int = 0
	## Game seconds spent in the current state.
	var state_t: float = 0.0
	## Game time (s) the pack opened (the forming window).
	var opened_at: float = 0.0
	## The prey: the necromancer the circle rings (null while stalking).
	var prey: Necromancer = null
	## Angle (rad) of the alpha's post on the circle, turning `orbit` rad/s.
	var angle: float = 0.0


## Owning run.
var game: Game
## The packs' numbers (PACKS with the STAGE's "packs").
var cfg: Dictionary = {}
## Live packs, in opening order.
var packs: Array[Pack] = []
## Packs formed this run.
var formed: int = 0
## Circles begun this run.
var circles: int = 0
## Rushes begun this run.
var rushes: int = 0
## Alphas killed this run (a pack broken by its alpha's death).
var alphas_slain: int = 0
## Members that charged in uncoordinated (left in a broken pack).
var broken_members: int = 0
## Most packs alive at once (the report).
var peak: int = 0


## Builds Packs for `p_game` (PrimevalRules keeps it).
func _init(p_game: Game) -> void:
	game = p_game
	cfg = PrimevalRulesData.PACKS.duplicate()
	var over: Dictionary = p_game.stage_def.get("packs", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]


## A pack kind's enemy `e` came onto the field (PrimevalRules.note_spawn()):
## it joins the newest pack while that one is forming, else opens one.
func note_spawn(e: Enemy, kit: RazorclawKit) -> void:
	var p: Pack = null
	if not packs.is_empty():
		var last := packs[packs.size() - 1]
		if game.elapsed - last.opened_at <= float(cfg["form_window"]) and last.members.size() < int(cfg["max_size"]) \
				and last.state == STALK and not last.broken:
			p = last
	if p == null:
		p = Pack.new()
		p.opened_at = game.elapsed
		p.alpha = e
		p.alpha_gen = e.generation
		packs.append(p)
		formed += 1
		game.stat_add("packs_formed", 1.0)
		peak = maxi(peak, packs.size())
	p.members.append(e)
	p.gens.append(e.generation)
	kit.pack = p


## A pack kind's enemy `e` was killed (PrimevalRules.note_killed()): the
## alpha's death breaks its pack.
func on_killed(e: Enemy, kit: RazorclawKit) -> void:
	var p := kit.pack
	if p == null or p.broken or p.alpha != e or p.alpha_gen != e.generation:
		return
	alphas_slain += 1
	game.stat_add("pack_alphas_slain", 1.0)
	game.primeval.play_sound("alpha_slain", e.position, 0.3)
	_break(p)


## Breaks pack `p`: its living members charge straight in.
func _break(p: Pack) -> void:
	p.broken = true
	var n := 0
	for i in p.members.size():
		var m := p.members[i]
		if m.active and m.generation == p.gens[i] and m != p.alpha:
			n += 1
	broken_members += n
	game.stat_add("pack_broken_members", float(n))


## Per tick (PrimevalRules.step()): every pack's hunt moves on; empty packs
## are dropped.
func step(delta: float) -> void:
	var i := packs.size() - 1
	while i >= 0:
		var p := packs[i]
		if not _alive(p):
			packs.remove_at(i)
			i -= 1
			continue
		if not p.broken and (not p.alpha.active or p.alpha.generation != p.alpha_gen):
			_break(p)  # The alpha left the field without a kill.
		if not p.broken:
			_advance(p, delta)
		i -= 1


## True while pack `p` has a living member.
func _alive(p: Pack) -> bool:
	for i in p.members.size():
		if p.members[i].active and p.members[i].generation == p.gens[i]:
			return true
	return false


## Moves pack `p`'s hunt on by `delta` s.
func _advance(p: Pack, delta: float) -> void:
	p.state_t += delta
	match p.state:
		STALK:
			var pl := game.nearest_player(p.alpha.position)
			if pl != null and not pl.dead and pl.position.distance_to(p.alpha.position) <= float(cfg["engage"]):
				p.prey = pl
				p.angle = (p.alpha.position - pl.position).angle()
				_enter(p, CIRCLE)
				circles += 1
				game.stat_add("pack_circles", 1.0)
				game.primeval.play_sound("pack_circle", p.alpha.position, 0.5)
		CIRCLE:
			p.angle += float(cfg["orbit"]) * delta
			if p.prey == null or p.prey.dead:
				_enter(p, DONE)
			elif p.state_t >= float(cfg["circle_time"]):
				_enter(p, HOLD)
				game.primeval.play_sound("pack_hold", p.alpha.position, 0.5)
		HOLD:
			if p.prey == null or p.prey.dead:
				_enter(p, DONE)
			elif p.state_t >= float(cfg["hold"]):
				_enter(p, RUSH)
				rushes += 1
				game.stat_add("pack_rushes", 1.0)
				game.primeval.play_sound("pack_rush", p.alpha.position, 0.4)
		RUSH:
			if p.prey == null or p.prey.dead or p.state_t >= float(cfg["rush_time"]):
				_enter(p, DONE)


## Pack `p` enters state `s`.
func _enter(p: Pack, s: int) -> void:
	p.state = s
	p.state_t = 0.0


## THE one steering call of a pack kind's kit (RazorclawKit.physics()): true
## while the pack owns member `e`'s tick (the circle, the hold, the rush);
## false hands the tick to the default AI (stalking, done, broken, held by a
## blocker).
func steer(e: Enemy, kit: RazorclawKit, delta: float) -> bool:
	var p := kit.pack
	if p == null or p.broken or p.state == STALK or p.state == DONE or e.engaged_timer > 0.0:
		return false
	if p.prey == null or p.prey.dead:
		return false
	var idx := p.members.find(e)  # Its place in the pack: its post on the circle.
	if idx < 0:
		return false
	match p.state:
		CIRCLE:
			var off := (float(idx) - float(p.members.size() - 1) * 0.5) * float(cfg["spread"])  # Round the alpha's angle, both flanks.
			var post := p.prey.position + Vector2.from_angle(p.angle + off) * float(cfg["circle_radius"])
			var to := post - e.position
			if to.length() <= float(cfg["post_reach"]):
				e.velocity = Vector2.ZERO
			else:
				PrimevalKit.move(e, to.normalized(), e.move_speed, delta)
		HOLD:
			kit.hold(e)
		RUSH:
			var to := p.prey.position - e.position
			if to.length() <= e.radius + p.prey.radius + e.attack_range + 4.0:
				return false  # At its prey: the default AI's bite.
			if to.length() > 0.5:
				PrimevalKit.move(e, to.normalized(), e.move_speed * float(cfg["rush_mult"]), delta)
	return true


## Packs alive now.
func live() -> int:
	return packs.size()
