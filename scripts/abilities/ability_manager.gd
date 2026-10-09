## AbilityManager — the necromancer's skills (GDD §22 "Player /
## AbilityManager: Current skills and effective stat modifiers"):
##   * spell levels + automatic casting of Shadow Bolt, Shadow Orb Shield and
##     Shadow Blast (GDD §8),
##   * passive levels (GDD §34) exposed as values for HordeDirector,
##   * summon ability levels are forwarded to HordeDirector,
##   * level-up card generation (3 random choices, GDD §15) with concrete
##     "current -> next" stat deltas (GDD §16 level-up panel), respecting the
##     6 active / 6 passive slot limits (GDD §6).
class_name AbilityManager
extends Node2D

## Owning run.
var game: Game
## Spell id -> level (0 = not learned).
var spell_levels: Dictionary = {}
## Passive id -> level (0 = not learned).
var passive_levels: Dictionary = {}
## Orb Shield node once learned (null before).
var orb_shield: OrbShield = null
## Seconds until the next Shadow Bolt volley.
var _bolt_timer: float = 0.5
## Seconds until the next Shadow Blast.
var _blast_timer: float = 1.0
## "id level" strings of every card picked this run (summary / autotest).
var pick_history: PackedStringArray = PackedStringArray()
## Reusable query buffer.
var _tmp: Array = []
## Reusable [score, enemy] candidate list for Shadow Bolt.
var _cands: Array = []


## Initialises levels: the starting spell at level 1, everything else 0.
func setup(p_game: Game) -> void:
	game = p_game
	for id: String in AbilityData.SPELL_ORDER:
		spell_levels[id] = 0
	for id: String in PassiveData.ORDER:
		passive_levels[id] = 0
	spell_levels[AbilityData.STARTING_SPELL] = 1


# =====================================================================================
# Queries
# =====================================================================================

## Level of spell `id`.
func spell_level(id: String) -> int:
	return spell_levels.get(id, 0)


## Level of passive `id`.
func passive_level(id: String) -> int:
	return passive_levels.get(id, 0)


## Current value of `key` for passive `id` (0 if not learned).
func passive_value(id: String, key: String) -> float:
	var lvl := passive_level(id)
	if lvl <= 0:
		return 0.0
	return float(PassiveData.PASSIVES[id]["levels"][lvl - 1][key])


## Stats row of spell `id` at its current level (empty if not learned).
func spell_stats(id: String) -> Dictionary:
	var lvl := spell_level(id)
	if lvl <= 0:
		return {}
	return AbilityData.SPELLS[id]["levels"][lvl - 1]


## Number of occupied active slots (learned spells + learned summon classes).
func active_count() -> int:
	var n := 0
	for id: String in AbilityData.SPELL_ORDER:
		if spell_level(id) > 0:
			n += 1
	for cls: String in UnitData.CLASS_ORDER:
		if int(game.horde.class_levels[cls]) > 0:
			n += 1
	return n


## Number of occupied passive slots.
func passive_count() -> int:
	var n := 0
	for id: String in PassiveData.ORDER:
		if passive_level(id) > 0:
			n += 1
	return n


## HUD helper: [{icon, level, max}] for owned actives (summons first).
func owned_actives() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for cls: String in UnitData.CLASS_ORDER:
		var lvl: int = game.horde.class_levels[cls]
		if lvl > 0:
			out.append({"icon": cls, "level": lvl, "max": 5})
	for id: String in AbilityData.SPELL_ORDER:
		if spell_level(id) > 0:
			out.append({"icon": AbilityData.SPELLS[id]["icon"], "level": spell_level(id), "max": (AbilityData.SPELLS[id]["levels"] as Array).size()})
	return out


## HUD helper: [{icon, level, max}] for owned passives.
func owned_passives() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in PassiveData.ORDER:
		if passive_level(id) > 0:
			out.append({"icon": PassiveData.PASSIVES[id]["icon"], "level": passive_level(id), "max": (PassiveData.PASSIVES[id]["levels"] as Array).size()})
	return out


## Orb Shield projectile interception hook used by ProjectileManager.
func try_intercept(pos: Vector2, r: float) -> bool:
	return orb_shield != null and orb_shield.try_intercept(pos, r)


# =====================================================================================
# Spell casting
# =====================================================================================

## Ticks spell cooldowns and casts automatically.
func step(delta: float) -> void:
	if spell_level("shadow_bolt") > 0:
		_bolt_timer -= delta
		if _bolt_timer <= 0.0:
			var s := spell_stats("shadow_bolt")
			_bolt_timer = float(s["cooldown"]) if _cast_bolt(s) else 0.1
	if spell_level("shadow_blast") > 0:
		_blast_timer -= delta
		if _blast_timer <= 0.0:
			var s := spell_stats("shadow_blast")
			_blast_timer = float(s["cooldown"]) if _cast_blast(s) else 0.25
	if orb_shield != null:
		orb_shield.step(delta, spell_stats("orb_shield"))


## Shadow Bolt: fires `count` bolts at the best nearby targets. Prefers the
## nearest enemies, enemies attacking summons (GDD §33) and avoids targets
## already expected to die. Returns false if there was nothing to shoot.
func _cast_bolt(s: Dictionary) -> bool:
	var p := game.player.position
	game.enemy_grid.query(p, float(s["range"]), _tmp)
	_cands.clear()
	for e: Enemy in _tmp:
		if not e.active:
			continue
		var score := p.distance_to(e.position)
		if e.targeting_summon:
			score -= AbilityData.BOLT_PROTECT_BONUS
		if e.hp - e.incoming_damage <= 0.0:
			score += 1000.0
		_cands.append([score, e])
	if _cands.is_empty():
		return false
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var count: int = s["count"]
	for i in count:
		var e: Enemy = _cands[i % _cands.size()][1]
		game.projectiles.fire_friendly(Projectile.Kind.SHADOW_BOLT, p, e, float(s["damage"]), float(s["speed"]), int(s["pierce"]), "bolt")
	return true


## Shadow Blast: AoE damage + slow around the player. Returns false (retry
## soon) when no enemy is in range so the cooldown is not wasted.
func _cast_blast(s: Dictionary) -> bool:
	var p := game.player.position
	var r: float = s["radius"]
	game.enemy_grid.query(p, r + 30.0, _tmp)
	var hit := false
	for e: Enemy in _tmp:
		if e.active and e.position.distance_to(p) <= r + e.radius:
			hit = true
			game.combat.slow_enemy(e, float(s["slow"]), float(s["slow_duration"]))
			game.combat.damage_enemy(e, float(s["damage"]), "blast")
	if not hit:
		return false
	game.effects.ring(p, r, Palette.VIOLET, 0.35)
	game.shake(2.0)
	game.stat_add("shadow_blasts", 1.0)
	return true


# =====================================================================================
# Level-up cards
# =====================================================================================

## Builds up to `n` random offers from every upgradeable spell, summon class
## and passive. Falls back to a heal card when nothing is left.
func build_offers(n: int) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	var can_new_active := active_count() < PlayerData.ACTIVE_SLOTS
	var can_new_passive := passive_count() < PlayerData.PASSIVE_SLOTS
	for id: String in AbilityData.SPELL_ORDER:
		var lvl := spell_level(id)
		var max_lvl := (AbilityData.SPELLS[id]["levels"] as Array).size()
		if lvl >= max_lvl or (lvl == 0 and not can_new_active):
			continue
		pool.append(_spell_offer(id, lvl))
	for cls: String in UnitData.CLASS_ORDER:
		var lvl: int = game.horde.class_levels[cls]
		if lvl >= (UnitData.LEVELS[cls] as Array).size() or (lvl == 0 and not can_new_active):
			continue
		pool.append(_summon_offer(cls, lvl))
	for id: String in PassiveData.ORDER:
		var lvl := passive_level(id)
		if lvl >= (PassiveData.PASSIVES[id]["levels"] as Array).size() or (lvl == 0 and not can_new_passive):
			continue
		pool.append(_passive_offer(id, lvl))
	pool.shuffle()
	var offers: Array[Dictionary] = []
	for i in mini(n, pool.size()):
		offers.append(pool[i])
	if offers.is_empty():
		offers.append(_heal_offer())
	return offers


## Applies a chosen card.
func apply_offer(o: Dictionary) -> void:
	var id: String = o["id"]
	var to: int = o["to"]
	match String(o["kind"]):
		"spell":
			spell_levels[id] = to
			if id == "orb_shield" and orb_shield == null:
				orb_shield = OrbShield.new()
				orb_shield.game = game
				add_child(orb_shield)
		"summon":
			game.horde.set_class_level(id, to)
		"passive":
			passive_levels[id] = to
			game.horde.recompute_all()
		"heal":
			game.combat.heal_player(game.player.max_hp * PlayerData.FALLBACK_HEAL_FRACTION)
	pick_history.append("%s %d" % [id, to])


## Common offer skeleton.
func _offer(kind: String, id: String, display_name: String, icon: String, from: int, to: int, tag: String, desc: String, deltas: PackedStringArray) -> Dictionary:
	return {"kind": kind, "id": id, "name": display_name, "icon": icon, "from": from, "to": to,
		"tag": tag, "description": desc, "deltas": deltas}


## Spell card: lists base stats when new, otherwise every stat that changes.
func _spell_offer(id: String, lvl: int) -> Dictionary:
	var def: Dictionary = AbilityData.SPELLS[id]
	var levels: Array = def["levels"]
	var labels: Dictionary = def["labels"]
	var nxt: Dictionary = levels[lvl]
	var deltas := PackedStringArray()
	for key: String in labels:
		if lvl == 0:
			deltas.append("%s %s" % [labels[key], _fmt_spell(key, nxt[key])])
		else:
			var cur: Dictionary = levels[lvl - 1]
			if cur[key] != nxt[key]:
				deltas.append("%s %s -> %s" % [labels[key], _fmt_spell(key, cur[key]), _fmt_spell(key, nxt[key])])
	return _offer("spell", id, def["display_name"], def["icon"], lvl, lvl + 1, "SPELL", def["description"], deltas)


## Summon card: effective stats now vs next level (passives included).
func _summon_offer(cls: String, lvl: int) -> Dictionary:
	var base: Dictionary = UnitData.UNITS[cls]
	var plural: String = base["plural"]
	var dom := int(passive_value("grave_dominion", "capacity_per_class"))
	var nxt := game.horde.compute_stats(cls, lvl + 1)
	var deltas := PackedStringArray()
	var desc := ""
	if lvl == 0:
		desc = "Raise %s to fight for you. Fallen ones return every %ss." % [plural.to_lower(), _fmt(game.horde.replenish_interval(cls))]
		deltas.append("%s: %d" % [plural, int(nxt["count"]) + dom])
		deltas.append("HP %s" % _fmt(nxt["max_hp"]))
		if cls == "priest":
			deltas.append("Heals %s HP every %ss" % [_fmt(nxt["heal_amount"]), _fmt(nxt["attack_interval"])])
		else:
			deltas.append("Damage %s every %ss" % [_fmt(nxt["damage"]), _fmt(nxt["attack_interval"])])
		deltas.append("Range %s px" % _fmt(nxt["attack_range"]))
	else:
		desc = "Strengthen your %s." % plural.to_lower()
		var cur := game.horde.compute_stats(cls, lvl)
		_delta_line(deltas, plural, float(int(cur["count"]) + dom), float(int(nxt["count"]) + dom))
		_delta_line(deltas, "Max HP", cur["max_hp"], nxt["max_hp"])
		if cls == "priest":
			_delta_line(deltas, "Heal per cast", cur["heal_amount"], nxt["heal_amount"])
		else:
			_delta_line(deltas, "Damage", cur["damage"], nxt["damage"])
		_delta_line(deltas, "Attack interval (s)", cur["attack_interval"], nxt["attack_interval"])
		_delta_line(deltas, "Splash radius", cur["splash_radius"], nxt["splash_radius"])
		_delta_line(deltas, "Arrow pierce", float(cur["pierce"]), float(nxt["pierce"]))
		if bool(nxt["heals_player"]) and not bool(cur["heals_player"]):
			deltas.append("Now heals YOU below %d%% HP" % int(UnitData.PLAYER_HEAL_THRESHOLD * 100.0))
	return _offer("summon", cls, base["display_name"], cls, lvl, lvl + 1, "SUMMON", desc, deltas)


## Passive card: passive value now vs next plus one concrete effect line.
func _passive_offer(id: String, lvl: int) -> Dictionary:
	var def: Dictionary = PassiveData.PASSIVES[id]
	var levels: Array = def["levels"]
	var labels: Dictionary = def["labels"]
	var nxt: Dictionary = levels[lvl]
	var deltas := PackedStringArray()
	for key: String in labels:
		var label: String = labels[key][0]
		var fmt: String = labels[key][1]
		var cur_v := 0.0 if lvl == 0 else float(levels[lvl - 1][key])
		var nxt_v := float(nxt[key])
		deltas.append("%s %s -> %s" % [label, _fmt_passive(cur_v, fmt), _fmt_passive(nxt_v, fmt)])
	# One concrete, player-visible consequence (GDD §34 "player-visible").
	var warrior := game.horde.compute_stats("warrior", maxi(1, int(game.horde.class_levels["warrior"])))
	match id:
		"grave_dominion":
			deltas.append("Army capacity %d -> %d" % [game.horde.total_capacity(lvl), game.horde.total_capacity(lvl + 1)])
		"necrotic_vigor":
			var cur_b := passive_value(id, "minion_hp")
			var hp_next := float(warrior["max_hp"]) / (1.0 + cur_b) * (1.0 + float(nxt["minion_hp"]))
			deltas.append("Warrior HP %s -> %s" % [_fmt(warrior["max_hp"]), _fmt(hp_next)])
		"dark_command":
			var cur_d := passive_value(id, "minion_damage")
			var dmg_next := float(warrior["damage"]) / (1.0 + cur_d) * (1.0 + float(nxt["minion_damage"]))
			deltas.append("Warrior damage %s -> %s" % [_fmt(warrior["damage"]), _fmt(dmg_next)])
		"soul_recycling":
			var base_i: float = UnitData.UNITS["warrior"]["replenish_interval"]
			var cur_i := base_i * (1.0 - passive_value(id, "replace_reduction"))
			var nxt_i := base_i * (1.0 - float(nxt["replace_reduction"]))
			deltas.append("Warrior respawn %ss -> %ss" % [_fmt(cur_i), _fmt(nxt_i)])
	return _offer("passive", id, def["display_name"], def["icon"], lvl, lvl + 1, "PASSIVE", def["description"], deltas)


## Fallback card when every ability is maxed (or no slot is free).
func _heal_offer() -> Dictionary:
	var amount := game.player.max_hp * PlayerData.FALLBACK_HEAL_FRACTION
	var deltas := PackedStringArray(["Restore %s HP" % _fmt(amount)])
	return _offer("heal", "dark_restoration", "Dark Restoration", "heal", 0, 0, "RESTORE", "Drain the fallen to mend your body.", deltas)


## Appends "label a -> b" when the value changes.
func _delta_line(out: PackedStringArray, label: String, a: float, b: float) -> void:
	if not is_equal_approx(a, b):
		out.append("%s %s -> %s" % [label, _fmt(a), _fmt(b)])


## Formats a number compactly: integers without decimals, else 2 decimals max.
static func _fmt(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return str(snappedf(v, 0.01))


## Formats a spell stat (slow is shown as a percentage).
static func _fmt_spell(key: String, v: Variant) -> String:
	if key == "slow":
		return "%d%%" % int(roundf(float(v) * 100.0))
	return _fmt(float(v))


## Formats a passive value per its label format ("int" / "pct" / "neg_pct").
static func _fmt_passive(v: float, fmt: String) -> String:
	match fmt:
		"pct":
			return "+%d%%" % int(roundf(v * 100.0))
		"neg_pct":
			return "-%d%%" % int(roundf(v * 100.0))
	return "+%d" % int(v)
