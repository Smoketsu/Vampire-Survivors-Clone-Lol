## SynergyManager — army synergies (GDD §6.3, numbers in SynergyData). Owned
## by HordeDirector, which calls evaluate() whenever a summon level changes and
## step() every tick. Activation is automatic (SynergyData header rule); on
## activation it announces the synergy on the HUD banner. The autotest's
## --synergies=off (GameState.autotest_synergies_off) keeps every synergy off.
## Requirements (SynergyData): `requires` entries are class ids or arrays of
## class ids (any one of them); a class whose UnitData row lists `counts_as`
## (the Profane Bishop) satisfies those classes too. `distinct` counts real
## classes (only those in `distinct_of` when given), so the Bishop counts once.
## Effects and where they are applied:
##   Shieldwall of the Damned  barrier HP on warriors (here; needs a living
##                             Warder or Bishop), absorbed in
##                             CombatResolver.damage_unit().
##   Volley of the Fallen      mage explosions mark enemies, archers deal bonus
##                             damage to marked ones (ProjectileManager).
##   March of the Deathless    move speed (HordeDirector.compute_stats) and
##                             regeneration (here).
##   The Unholy Host           attack speed (compute_stats), damage reduction
##                             (CombatResolver.damage_unit), aura drawn on
##                             every summon (SummonedUnit._draw).
## The newer classes' synergies (setter / finisher, SynergyData header):
##   marks        mark_staggered() (AbominationBehavior stomp) and
##                mark_swooped() (GargoyleBehavior dive) write the timed
##                Enemy tags, only while a synergy that reads them is active
##                (so nothing changes without one); chill, Deep Freeze and the
##                Dirge's weakening are the existing statuses.
##   hit bonus    hit_mult(), called ONCE from CombatResolver.damage_enemy()
##                for every hit: the source's class (SynergyData.SOURCE_CLASS),
##                the highest mark bonus of the active synergies that class
##                finishes (BOSS_MARK_MULT on the stage boss), times the
##                Charnel Menagerie's own damage category for the newer
##                classes. record_hit() counts what the hit dealt. A Requiem
##                hit also stretches the weakening (CombatResolver.
##                extend_weaken()).
##   behaviour    catapult aim (CatapultBehavior.score_bonus: Killing Field,
##                Shatterfall), Pack Hunt prey (BoneHoundBehavior: The Wild
##                Hunt), rogue dash preference and dash reset (RogueBehavior:
##                Cold Blood, Death from Above), the Baying frenzy (on_dirge()
##                from BansheeBehavior; frenzy_value() read by
##                HordeDirector.compute_stats()) and the Menagerie's
##                replenishment (replenish_mult(), HordeDirector.
##                replenish_interval()).
## Stats (autotest "synergy bonus" line, summary_line()): syn_<id>_hits and
## syn_<id>_bonus_dmg per synergy with a hit bonus (the share of the dealt
## damage its own multiplier added), syn_staggered_marks, syn_swooped_marks,
## syn_dfa_resets, syn_requiem_extend_s, syn_baying_frenzies.
class_name SynergyManager
extends RefCounted

## Seconds between Deathless regeneration ticks (heals are batched).
const REGEN_TICK: float = 1.0  # TUNING (not in GDD)
## Synergies with a per-hit bonus, reported in summary_line() (display order).
const HIT_IDS := ["flesh_rampart", "killing_field", "death_from_above", "wild_hunt",
		"cold_blood", "shatterfall", "requiem", "charnel_menagerie"]
## Content wave 2: hit synergies kept OUT of summary_line(), so the "synergy
## bonus" line keeps its text in every run (none since Bone Bastion replaced
## Charnel House: Bone Bastion is an aura, not a hit bonus).
const WAVE2_HIT_IDS: Array = []

## Owning horde director.
var director: HordeDirector
## Summon class whose Golems project Bone Bastion (UnitData id).
const BASTION_CLASS: String = "bone_golem"
## Bone Bastion: [position (Vector2), planted (bool)] of every live Golem this
## tick (_refresh_bastions(); empty while the synergy is off).
var _bastions: Array = []
## Synergy id -> true while active.
var active: Dictionary = {}
## "synergy_id@mm:ss" for every activation this run (summary / autotest).
var activation_log: PackedStringArray = PackedStringArray()
## Seconds until the next Shieldwall barrier refresh.
var _barrier_timer: float = 0.0
## Seconds accumulated toward the next Deathless regeneration tick.
var _regen_accum: float = 0.0
## Finisher class id -> Array of the ACTIVE synergy ids whose mark bonus its
## hits can take (rebuilt by evaluate(); empty while no such synergy is on).
var _finishers: Dictionary = {}
## Mark kind (SynergyData "mark") -> true while an active synergy reads it.
var _marks: Dictionary = {}
## Charnel Menagerie damage fraction (0 while inactive).
var _menagerie_dmg: float = 0.0
## Synergy id -> its stat keys [hits, bonus damage] (built once).
var _keys: Dictionary = {}
## Synergy id of the mark bonus the last hit_mult() call applied ("" = none).
var _last_id: String = ""
## Mark bonus fraction the last hit_mult() call applied (after the boss share).
var _last_mark: float = 0.0
## Menagerie fraction the last hit_mult() call applied (0 = none).
var _last_cap: float = 0.0
## Game time (s) until which the Baying frenzy runs (0 = never / over).
var _frenzy_until: float = 0.0
## True while the Baying frenzy's stats are applied to its class.
var _frenzy_on: bool = false


func _init(p_director: HordeDirector) -> void:
	director = p_director
	for id: String in HIT_IDS + WAVE2_HIT_IDS:
		_keys[id] = ["syn_%s_hits" % id, "syn_%s_bonus_dmg" % id]


## True while synergy `id` is active.
func is_active(id: String) -> bool:
	return active.has(id)


## Effect value `key` of synergy `id` while active, else 0.
func value(id: String, key: String) -> float:
	if not active.has(id):
		return 0.0
	return float(SynergyData.SYNERGIES[id][key])


## Active synergy ids in display order.
func active_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in SynergyData.ORDER:
		if active.has(id):
			out.append(id)
	return out


## Re-checks every synergy against the current summon levels. Newly active
## ones are announced; any change rebuilds the hit-bonus tables, recomputes
## summon stats (move / attack speed) and redraws summons (Unholy Host aura).
## With --synergies=off nothing ever activates.
func evaluate() -> void:
	var changed := false
	var off := GameState.autotest and GameState.autotest_synergies_off  # Autotest A/B switch.
	for id: String in SynergyData.ORDER:
		var now := not off and requirements_met(id, director.class_levels)
		if now == active.has(id):
			continue
		changed = true
		if now:
			active[id] = true
			_on_activated(id)
		else:
			active.erase(id)
	if not changed:
		return
	_rebuild_tables()
	director.recompute_all(director.capacity_snapshot())
	for u in director.units:
		u.queue_redraw()


## Rebuilds the finisher and mark tables and the Menagerie fraction from the
## active synergies.
func _rebuild_tables() -> void:
	_finishers.clear()
	_marks.clear()
	for id: String in active:
		var def: Dictionary = SynergyData.SYNERGIES[id]
		if def.has("mark"):
			_marks[String(def["mark"])] = true
		if def.has("finisher"):
			var fin := String(def["finisher"])  # Finisher class id.
			if not _finishers.has(fin):
				_finishers[fin] = []
			(_finishers[fin] as Array).append(id)
	_menagerie_dmg = value("charnel_menagerie", "damage")


## True if `levels` (class id -> summon level) meets synergy `id`.
static func requirements_met(id: String, levels: Dictionary) -> bool:
	var def: Dictionary = SynergyData.SYNERGIES[id]
	var distinct: int = def["distinct"]
	if distinct > 0:
		var pool: Array = def.get("distinct_of", UnitData.CLASS_ORDER)  # Classes counted.
		var n := 0
		for cls: String in pool:
			if int(levels.get(cls, 0)) >= SynergyData.MIN_CLASS_LEVEL:
				n += 1
		return n >= distinct
	return classes_met(def["requires"], levels, SynergyData.MIN_CLASS_LEVEL)


## True if every entry of `reqs` is owned at `min_level`+ in `levels`. An
## entry is a class id or an Array of class ids (any one of them). A class
## is also satisfied by any class whose UnitData row lists it in `counts_as`
## (the Profane Bishop stands in for the Mender and the Warder). Also used for
## the Dread Sovereign achievement (Game._on_boss_defeated).
static func classes_met(reqs: Array, levels: Dictionary, min_level: int) -> bool:
	for entry: Variant in reqs:
		var options: Array = entry if entry is Array else [entry]
		var ok := false
		for cls: String in options:
			ok = ok or class_level(cls, levels) >= min_level
		if not ok:
			return false
	return true


## Level at which class `cls` counts in `levels`: its own level, or the level
## of a class that `counts_as` it, whichever is higher.
static func class_level(cls: String, levels: Dictionary) -> int:
	var lvl := int(levels.get(cls, 0))
	for other: String in UnitData.CLASS_ORDER:
		var stands_in: Array = UnitData.UNITS[other].get("counts_as", [])
		if cls in stands_in:
			lvl = maxi(lvl, int(levels.get(other, 0)))
	return lvl


## Level-up card hint: names the synergies that raising `cls` to
## MIN_CLASS_LEVEL would activate ("" if none, or with --synergies=off).
func unlock_hint(cls: String) -> String:
	if GameState.autotest and GameState.autotest_synergies_off:
		return ""
	var levels := director.class_levels.duplicate()
	levels[cls] = maxi(int(levels[cls]), SynergyData.MIN_CLASS_LEVEL)
	var names := PackedStringArray()
	for id: String in SynergyData.ORDER:
		if not active.has(id) and requirements_met(id, levels):
			names.append(String(SynergyData.SYNERGIES[id]["display_name"]))
	return "" if names.is_empty() else "Activates synergy: " + ", ".join(names)


## Announces a newly active synergy (HUD banner + ring) and logs it.
func _on_activated(id: String) -> void:
	var game := director.game
	var def: Dictionary = SynergyData.SYNERGIES[id]
	activation_log.append("%s@%s" % [id, AbilityManager._clock(game.elapsed)])
	game.stat_add("synergies_activated", 1.0)
	if id == "shieldwall":
		_barrier_timer = 0.0
	if game.player != null:
		game.effects.ring(game.player.position, 100.0, Palette.NECRO_GREEN, 0.6)
	if game.hud != null:
		game.hud.announce("SYNERGY AWAKENED", String(def["display_name"]), String(def["description"]), Palette.NECRO_GREEN)


## Per-tick synergy effects (barriers, regeneration, the Baying frenzy's end,
## Bone Bastion's list of Golems).
func step(delta: float) -> void:
	_refresh_bastions()
	if active.has("shieldwall"):
		_barrier_timer -= delta
		if _barrier_timer <= 0.0:
			_barrier_timer = value("shieldwall", "barrier_interval")
			_raise_barriers()
	if active.has("deathless"):
		_regen_accum += delta
		if _regen_accum >= REGEN_TICK:
			_regenerate(_regen_accum)
			_regen_accum = 0.0
	if _frenzy_on and (director.game.elapsed >= _frenzy_until or not active.has("baying")):
		_frenzy_on = false
		_refresh_frenzy_class()


## Bone Bastion (content wave 2): rebuilds the list of live Golems once a
## tick (empty while the synergy is off), so damage_unit() checks a short list.
func _refresh_bastions() -> void:
	_bastions.clear()
	if not active.has("bone_bastion"):
		return
	for g in director.units:
		if g.active and g.unit_class == BASTION_CLASS and g.state != SummonedUnit.State.SPAWNING \
				and g.state != SummonedUnit.State.DEAD:
			var b := g.behavior as GolemBehavior  # Its kit, for the planted state.
			_bastions.append([g.position, b != null and b.planted_left > 0.0])


## Bone Bastion's damage-taken cut (0..1) for summon `u` (0 while the synergy
## is off, for a Golem itself and outside every Golem's reach): the planted cut
## when the nearest bastion in reach is planted, else the base cut; the best wins.
func bastion_reduction(u: SummonedUnit) -> float:
	if _bastions.is_empty() or u.unit_class == BASTION_CLASS:
		return 0.0
	var def: Dictionary = SynergyData.SYNERGIES["bone_bastion"]
	var r := float(def["radius"])  # Bastion reach (px).
	var best := 0.0  # Best cut found.
	for entry: Array in _bastions:
		if (entry[0] as Vector2).distance_to(u.position) <= r:
			best = maxf(best, float(def["planted_reduction"]) if bool(entry[1]) else float(def["reduction"]))
	return best


## Shieldwall: while a Warder (or a Profane Bishop) lives, every warrior's
## barrier is refreshed to barrier_fraction of its max HP (not stacked).
func _raise_barriers() -> void:
	if director.count_of("warder") + director.count_of("bishop") <= 0:
		return
	var frac := value("shieldwall", "barrier_fraction")
	for u in director.units:
		if u.unit_class == "warrior" and u.active:
			var b := u.max_hp * frac
			if b > u.barrier_hp:
				u.barrier_hp = b
				u.queue_redraw()
	director.game.stat_add("shieldwall_barriers", 1.0)


## Deathless: heals every living summon regen_per_s of max HP per second.
func _regenerate(seconds: float) -> void:
	var frac := value("deathless", "regen_per_s") * seconds
	var total := 0.0
	for u in director.units:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.hp < u.max_hp:
			total += director.game.combat.heal_unit(u, u.max_hp * frac)
	director.game.stat_add("deathless_regen", total)


# =====================================================================================
# The newer classes' synergies: marks, the hit bonus, behaviour hooks
# =====================================================================================

## Abomination / Bone Colossus stomp hit `e`: it is staggered for
## SynergyData.STAGGER_DURATION s, while a synergy reads the mark (Flesh
## Rampart, Killing Field). Structures and Reckoning enemies are never marked.
func mark_staggered(e: Enemy) -> void:
	if not _marks.has("staggered") or not e.active or e.is_structure or e.is_reckoning:
		return
	var game := director.game
	e.staggered_until = maxf(e.staggered_until, game.elapsed + SynergyData.STAGGER_DURATION)
	game.stat_add("syn_staggered_marks", 1.0)


## Gargoyle / Cathedral Horror dive hit `e`: it is swooped for
## SynergyData.SWOOPED_DURATION s, while a synergy reads the mark (Death from
## Above, The Wild Hunt); a new mark re-arms its Death from Above dash reset.
## Structures and Reckoning enemies are never marked.
func mark_swooped(e: Enemy) -> void:
	if not _marks.has("swooped") or not e.active or e.is_structure or e.is_reckoning:
		return
	var game := director.game
	e.swooped_until = maxf(e.swooped_until, game.elapsed + SynergyData.SWOOPED_DURATION)
	e.swoop_reset_spent = false
	game.stat_add("syn_swooped_marks", 1.0)


## Damage multiplier the synergies give a hit of `source` on `e` (1 = none),
## called once per hit by CombatResolver.damage_enemy(): (1 + the highest
## mark bonus of the active synergies the source's class finishes, halved on
## the stage boss) x (1 + the Charnel Menagerie's bonus for a newer class).
## A Requiem hit also stretches the foe's weakening. Remembers what it
## applied for record_hit().
func hit_mult(source: String, e: Enemy) -> float:
	_last_id = ""
	_last_mark = 0.0
	_last_cap = 0.0
	if _finishers.is_empty() and _menagerie_dmg <= 0.0:
		return 1.0
	var cls: String = SynergyData.SOURCE_CLASS.get(source, "")  # Class of this hit ("" = none).
	if cls == "":
		return 1.0
	if _finishers.has(cls):
		for id: String in _finishers[cls]:
			var b := _mark_bonus(id, source, e)  # This synergy's bonus on this hit.
			if b > _last_mark:
				_last_mark = b
				_last_id = id
		if _last_mark > 0.0 and e.is_boss:
			_last_mark *= SynergyData.BOSS_MARK_MULT
		if _last_id == "requiem":
			var game := director.game
			game.stat_add("syn_requiem_extend_s", game.combat.extend_weaken(e, value("requiem", "extend_seconds")))
	if _menagerie_dmg > 0.0 and cls in SynergyData.NEWER_CLASSES:
		_last_cap = _menagerie_dmg
	return (1.0 + _last_mark) * (1.0 + _last_cap)


## Mark bonus (0..1) of active synergy `id` on a hit of `source` on `e`.
func _mark_bonus(id: String, source: String, e: Enemy) -> float:
	var def: Dictionary = SynergyData.SYNERGIES[id]
	if def.has("sources") and not source in (def["sources"] as Array):
		return 0.0
	var now := director.game.elapsed  # Run time (s).
	match String(def["mark"]):
		"staggered":
			return float(def["bonus"]) if e.staggered_until > now else 0.0
		"swooped":
			return float(def["bonus"]) if e.swooped_until > now else 0.0
		"chilled":
			return float(def["bonus"]) if e.chill_timer > 0.0 or e.freeze_timer > 0.0 else 0.0
		"frozen":
			if e.freeze_timer > 0.0:
				return float(def["bonus"])
			return float(def["bonus_chilled"]) if e.chill_timer > 0.0 else 0.0
		"weakened":
			return float(def["bonus"]) if e.weaken_until > now else 0.0
	return 0.0


## Counts the hit hit_mult() just raised: it dealt `dealt` HP (after every
## other modifier); each multiplier is credited the share it added.
func record_hit(dealt: float) -> void:
	var game := director.game
	if _last_mark > 0.0:
		var k: Array = _keys[_last_id]  # [hits key, bonus damage key].
		game.stat_add(k[0], 1.0)
		game.stat_add(k[1], dealt * _last_mark / ((1.0 + _last_mark) * (1.0 + _last_cap)))
	if _last_cap > 0.0:
		var kc: Array = _keys["charnel_menagerie"]  # [hits key, bonus damage key].
		game.stat_add(kc[0], 1.0)
		game.stat_add(kc[1], dealt * _last_cap / (1.0 + _last_cap))


## Catapult target-score bonus for `e` (CatapultBehavior): the larger of
## Killing Field's (a staggered foe) and Shatterfall's (a Deep-Frozen foe)
## aim bonus; 0 while neither applies.
func catapult_aim_bonus(e: Enemy) -> float:
	var out := 0.0  # Best aim bonus.
	if active.has("killing_field") and e.staggered_until > director.game.elapsed:
		out = value("killing_field", "aim_bonus")
	if active.has("shatterfall") and e.freeze_timer > 0.0:
		out = maxf(out, value("shatterfall", "aim_bonus"))
	return out


## Baying of the Damned: a Dirge was released; the frenzy class's units
## attack and move faster for frenzy_duration s (a new Dirge refreshes it).
## Stats are recomputed only when the frenzy starts or ends.
func on_dirge() -> void:
	if not active.has("baying"):
		return
	var game := director.game
	_frenzy_until = maxf(_frenzy_until, game.elapsed + value("baying", "frenzy_duration"))
	game.stat_add("syn_baying_frenzies", 1.0)
	if not _frenzy_on:
		_frenzy_on = true
		_refresh_frenzy_class()


## Baying frenzy bonus `key` ("attack_speed" / "move_speed") of class `cls`
## while the frenzy runs (0 otherwise); its own stacking category in
## HordeDirector.compute_stats().
func frenzy_value(cls: String, key: String) -> float:
	if not _frenzy_on or not active.has("baying"):
		return 0.0
	if String(SynergyData.SYNERGIES["baying"]["frenzy_class"]) != cls:
		return 0.0
	return value("baying", key)


## Pushes the frenzy class's fresh stats to its living units (no capacity
## change, HP % kept).
func _refresh_frenzy_class() -> void:
	var cls := String(SynergyData.SYNERGIES["baying"]["frenzy_class"])  # Frenzied class.
	if int(director.class_levels.get(cls, 0)) > 0:
		director.recompute_all(director.capacity_snapshot())


## Charnel Menagerie: replenishment interval multiplier of class `cls`
## (1 / (1 + replenish_speed) for a newer class while active, else 1).
func replenish_mult(cls: String) -> float:
	if not active.has("charnel_menagerie") or not cls in SynergyData.NEWER_CLASSES:
		return 1.0
	return 1.0 / (1.0 + value("charnel_menagerie", "replenish_speed"))


## Autotest "synergy bonus" line: per hit synergy its hits and bonus damage,
## then the marks, dash resets, Requiem seconds and Baying frenzies.
static func summary_line(st: Dictionary) -> String:
	var parts := PackedStringArray()  # One part per synergy.
	for id: String in HIT_IDS:
		parts.append("%s hits=%d dmg=%d" % [id, int(st.get("syn_%s_hits" % id, 0.0)), int(st.get("syn_%s_bonus_dmg" % id, 0.0))])
	parts.append("baying frenzies=%d" % int(st.get("syn_baying_frenzies", 0.0)))
	parts.append("marks staggered=%d swooped=%d | dash resets=%d | requiem +%ds" % [
		int(st.get("syn_staggered_marks", 0.0)), int(st.get("syn_swooped_marks", 0.0)),
		int(st.get("syn_dfa_resets", 0.0)), int(st.get("syn_requiem_extend_s", 0.0))])
	return " | ".join(parts)
