## BoneBeetles — the Bone Beetles spell (AbilityData "bone_beetles"; Act IX,
## the Crash Site; GDD §15.0 "Bone Beetles, Hive of Bone, Chitin and the
## Broodbound (Act IX)"; owner-approved proposal: "slain enemies burst into
## bone beetles that bite the next enemy"; unlocked by slaying the Hive Mother,
## then offered on every stage at the later-item card weight). It has no
## cooldown: it rides the kill path (NecroSpellBook.on_enemy_killed()). Every
## foe slain within `range` px of the necromancer BURSTS into `beetles` bone
## beetles (plus the Broodbound's Swarm Bride, innate value beetle_extra),
## while fewer than `cap` beetles live (and BoneBeetlesData.MAX_BEETLES). Each
## beetle scuttles at `speed` px/s to its PREY, the nearest open foe within
## `seek` px of it (not the fallen one), and BITES it once for `damage`
## through CombatResolver.damage_enemy(); a beetle with no prey, or whose time
## (`life` s) runs out, crumbles. A foe slain by a beetle's bite does not burst
## (no chains). Evolved into HIVE OF BONE (EvolutionData "hive_of_bone",
## detected by the "bites" key): each beetle bites `bites` foes in turn (a new
## prey after each bite), and a foe it kills DOES burst (the hive feeds
## itself, still under the cap). CHITIN (the paired passive): every bite deals
## bite_bonus more (0 while not owned). Works the same on every stage (no act
## rule). Determinism: no RNG; prey by distance in the spatial hash's order.
## Stats: beetle_bursts, beetle_spawned, beetle_extra, beetle_bites,
## beetle_capped, beetle_chitin_bonus_dmg; damage as dmg_bone_beetles /
## dmg_hive_of_bone.
class_name BoneBeetles
extends NecroSpell

## Live beetles: {pos (world px), prey (Enemy or null), gen (its pooling
## generation), t_end (game s it crumbles), bites (left), dir (unit, its
## heading)}.
var beetles: Array[Dictionary] = []
## The spell's stats at the last step (the kill hook reads them).
var _stats: Dictionary = {}
## True while one of this spell's bites is being dealt (a kill it causes does
## not burst, unless the hive is evolved).
var _biting: bool = false
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false


## Moves every beetle, bites and retargets; keeps the stats for the kill hook.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	var now := game.elapsed
	var i := 0
	while i < beetles.size():
		if _scuttle(beetles[i], delta, now):
			beetles.remove_at(i)
			continue
		i += 1
	var busy := not beetles.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## THE KILL HOOK (NecroSpellBook.on_enemy_killed()): foe `e` fell; within
## range of the necromancer it bursts into beetles.
func on_enemy_killed(e: Enemy) -> void:
	if _stats.is_empty():
		return
	var evolved := _stats.has("bites")
	if _biting and not evolved:
		return  # A beetle's own kill: no chain (Hive of Bone feeds itself).
	if e.position.distance_to(game.player.position) > float(_stats["range"]):
		return
	var base := int(_stats["beetles"])
	var n := base + roundi(game.character.innate_value(BoneBeetlesData.EXTRA_BEETLES_KEY))
	var cap := mini(int(_stats["cap"]), BoneBeetlesData.MAX_BEETLES)
	var made := 0
	for k in n:
		if beetles.size() >= cap:
			game.stat_add("beetle_capped", float(n - k))
			break
		var dir := Vector2.from_angle(TAU * float(k) / float(maxi(1, n)) + float(e.think_slot))  # No RNG.
		beetles.append({"pos": e.position + dir * BoneBeetlesData.SCATTER, "prey": null, "gen": 0, "skip": e,
			"t_end": game.elapsed + float(_stats["life"]), "bites": int(_stats.get("bites", 1)), "dir": dir})
		made += 1
	if made <= 0:
		return
	game.stat_add("beetle_bursts", 1.0)
	game.stat_add("beetle_spawned", float(made))
	if n > base:
		game.stat_add("beetle_extra", float(mini(made, n - base)))


## One beetle `b` this tick. True when it is done (bitten out, crumbled).
func _scuttle(b: Dictionary, delta: float, now: float) -> bool:
	if now >= float(b["t_end"]):
		return true
	var prey: Enemy = b["prey"]
	if prey == null or not prey.active or prey.generation != int(b["gen"]) or prey.untargetable:
		prey = _find_prey(b["pos"], b.get("skip", null))
		if prey == null:
			return true  # Nothing to bite: it crumbles.
		b["prey"] = prey
		b["gen"] = prey.generation
	var to := prey.position - (b["pos"] as Vector2)
	var dist := to.length()
	var step := float(_stats["speed"]) * delta
	if dist <= prey.radius + BoneBeetlesData.BITE_REACH + step:
		_bite(b, prey)
		b["bites"] = int(b["bites"]) - 1
		b["skip"] = prey  # Its next prey is another foe.
		b["prey"] = null
		return int(b["bites"]) <= 0
	b["dir"] = to / dist
	b["pos"] = (b["pos"] as Vector2) + to / dist * step
	return false


## The nearest open foe within `seek` px of `at` (not `skip`, not
## untargetable, not a civilian), or null.
func _find_prey(at: Vector2, skip: Variant) -> Enemy:
	var reach := float(_stats["seek"])
	game.enemy_grid.query(at, reach, _tmp)
	var best: Enemy = null
	var best_d := INF
	var seen := 0
	for e: Enemy in _tmp:
		if not is_open_target(e) or e.untargetable or e.civilian or e == skip:
			continue
		var dd := at.distance_squared_to(e.position)
		if dd <= reach * reach and dd < best_d:
			best_d = dd
			best = e
		seen += 1
		if seen >= BoneBeetlesData.PREY_SAMPLES:
			break
	return best


## Beetle `b` bites `prey`: damage x Chitin, through the one damage path.
func _bite(b: Dictionary, prey: Enemy) -> void:
	var dmg := float(_stats["damage"])
	var chitin := game.abilities.passive_value(BoneBeetlesData.CHITIN, BoneBeetlesData.CHITIN_KEY)  # 0 when not owned.
	var src := BoneBeetlesData.EVOLVED_SOURCE if _stats.has("bites") else BoneBeetlesData.SOURCE
	_biting = true
	var dealt := game.combat.damage_enemy(prey, dmg * (1.0 + chitin), src)
	_biting = false
	if chitin > 0.0 and dealt > 0.0:
		game.stat_add("beetle_chitin_bonus_dmg", dealt * chitin / (1.0 + chitin))
	game.stat_add("beetle_bites", 1.0)
	b["pos"] = prey.position


## Autotest counters (CrashSiteReport's Bone Beetles line).
func summary_extra() -> String:
	var st := game.stats
	return "bursts=%d beetles=%d (extra %d, capped %d) bites=%d" % [int(st.get("beetle_bursts", 0.0)), int(st.get("beetle_spawned", 0.0)),
		int(st.get("beetle_extra", 0.0)), int(st.get("beetle_capped", 0.0)), int(st.get("beetle_bites", 0.0))]


## The beetles: each its sprite turned along its heading (a scuttle bob on game
## time), else a small bone-white shape. Visual only.
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	var evolved := _stats.has("bites")
	var tint := Color(1.0, 0.95, 0.8) if evolved else Color.WHITE  # The hive's beetles a warmer bone.
	for b in beetles:
		var p: Vector2 = b["pos"]
		var dir: Vector2 = b["dir"]
		var bob := Vector2(0.0, -1.0) if fmod(now, BoneBeetlesData.SCUTTLE_TIME * 2.0) < BoneBeetlesData.SCUTTLE_TIME else Vector2.ZERO
		if SpriteBank.draw_flat(self, BoneBeetlesData.SPRITE, p + bob, dir.angle(), tint):
			continue
		SpriteBank.draw_disc(self, p + bob, 3.5, Palette.CONCORD_INK)
		SpriteBank.draw_disc(self, p + bob, 2.6, Palette.BONE)
		SpriteBank.draw_disc(self, p + bob + dir * 2.5, 1.4, Palette.BONE)
