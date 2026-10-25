## AbilityManager — the necromancer's skills (GDD §22 "Player /
## AbilityManager: Current skills and effective stat modifiers"):
##   * spell levels + automatic casting of Shadow Bolt, Shadow Orb Shield and
##     Shadow Blast (GDD §8),
##   * passive levels (GDD §34) exposed as values for HordeDirector,
##   * summon ability levels are forwarded to HordeDirector,
##   * level-up card generation (3 weighted random choices, GDD §9.1) with
##     concrete "current -> next" stat deltas and evolution readiness (GDD
##     §10.4 level-up panel), respecting the 6 active / 6 passive slot limits
##     (GDD §6),
##   * spell evolutions (GDD §6.1, EvolutionData): Void Barrage, Eclipse Ward
##     and Abyssal Detonation. Once ready_evolutions() lists one, it is
##     delivered ONLY by the next treasure chest (chest_rewards() grants it
##     first; user decision, the GDD's "special elite reward"), never as a
##     level-up card,
##   * the limited rerolls / banishes and unlimited skips of the level-up
##     panel (GDD §9.1, LevelUpData), plus fallback cards when nothing is left.
##   * summon evolutions (Death Knight, Lich, Profane Bishop; recipes in
##     SummonEvolutionData, runtime in game.horde.evolutions) share the spell
##     evolutions' delivery: ready_evolutions() appends them, chest_rewards()
##     grants them, and the cards / hints / weights call small hooks there.
##     Every granted evolution (spell or summon) is recorded in the Meta
##     recipe book (Meta.discover_recipe(), the pause menu's Recipes view).
## Spell stats are "effective": the level row (or evolution row) with the
## spell passives applied (Soul Conduit damage, Abyssal Focus cooldowns) and
## the meta Shadowcraft upgrades (game.meta, see MetaModifiers); spell_stats()
## also applies the Hyper power-up (x2 damage, halved cooldowns) while it runs.
## The Profane Pact (PactData) is a regular passive here; its card shows the
## combined Pact + Oath penalties and rewards (game.difficulty).
## The four newer spells (Bone Spear, Soul Siphon, Corpse Explosion, Plague
## Cloud) and their evolutions live in scripts/abilities/spells/ behind ONE
## dispatch: `spells` (NecroSpellBook) is ticked from step(), told about
## kills (on_enemy_killed) and adds their passive card lines. Their stats use
## the same spell_stats() path; apply_spell_mods() also applies the new
## spell passives Necrotic Expanse (area) and Lingering Malediction
## (durations).
## The five later spells (Death Mark, Bone Wall, Soul Chains, Wither, Raise
## Dead; GDD §15.0 "Five more spells") join the same NecroSpellBook dispatch
## and the same spell_stats() path; their new passives act in CombatResolver
## (Grim Ledger, Spirit Binding) and HordeDirector.spawn_temporary()
## (Restless Dead).
## The four later horde passives (Bone Plating, Unholy Precision, Unholy
## Resilience, Bound Souls) act in CombatResolver / HordeDirector; their
## card line comes from MinionPassives.card_line().
## Playable characters (game.character, CharacterModifiers): the run starts
## with the character's spell at Lv 1 (CharacterModifiers.starting_spell(),
## Shadow Bolt for the Gravecaller), its spell-area modifier is one more
## category in apply_spell_mods(), every spell level-up is reported to it
## (the Meta unlock rule), and Shadow Blast tells the Voidcaller's Echoing
## Dark innate about each blast (game.innates.on_blast()).
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
## Shadow Bolt aim mode, toggled by the player (toggle_aim: T / controller Y).
## false = "Nearest" (default), true = "Strongest" (highest current HP).
var bolt_aim_strongest: bool = false
## Seconds until the next Shadow Blast.
var _blast_timer: float = 1.0
## "id level" strings of every card picked this run (summary / autotest).
var pick_history: PackedStringArray = PackedStringArray()
## Spell id -> evolution id once evolved (absent = not evolved).
var evolved: Dictionary = {}
## "evolution_id@mm:ss" for every evolution obtained (summary / autotest).
var evolution_history: PackedStringArray = PackedStringArray()
## Level-up rerolls per run: LevelUpData.REROLLS + meta Fate's Thread.
var rerolls_max: int = LevelUpData.REROLLS
## Level-up rerolls left this run.
var rerolls_left: int = LevelUpData.REROLLS
## Level-up banishes per run: LevelUpData.BANISHES + meta Banishing Rite.
var banishes_max: int = LevelUpData.BANISHES
## Level-up banishes left this run.
var banishes_left: int = LevelUpData.BANISHES
## Item id -> true for items banished from the card pool this run.
var banished: Dictionary = {}
## Level-up skips used this run (unlimited).
var skips_used: int = 0
## Spell id -> cached effective stats (cleared whenever a card is applied).
var _eff_cache: Dictionary = {}
## Pending Abyssal Detonation second hits: {"t": s left, "pos": centre, "stats": row}.
var _detonations: Array[Dictionary] = []
## Reusable query buffer.
var _tmp: Array = []
## Reusable [score, enemy] candidate list for Shadow Bolt.
var _cands: Array = []
## The four newer spells (NecroSpellBook; created in setup()).
var spells: NecroSpellBook = null
## Co-op: this player's own random stream for level-up hands and chest draws
## (seeded per slot by CoopSession), so one player's picks never shift the
## other's offers. Null in solo: the run's global stream, as before.
var offer_rng: RandomNumberGenerator = null
## False for a co-op guest: the Profane Pact is the host's pick (it sets the
## run's difficulty), so it is left out of the guest's card pool.
var allow_pact: bool = true
## Co-op: this player's unlocked lockable items (id -> true, from the lobby
## loadout; Unlocks.offerable_with()). Null = this device's own save, as solo.
var offer_unlocks: Variant = null


## Initialises levels: the character's starting spell at level 1 (its Orb
## Shield node too when that is the spell), everything else 0.
func setup(p_game: Game) -> void:
	game = p_game
	spells = NecroSpellBook.new()
	spells.game = game
	add_child(spells)
	for id: String in AbilityData.SPELL_ORDER:
		spell_levels[id] = 0
	for id: String in PassiveData.ORDER:
		passive_levels[id] = 0
	var start := game.character.starting_spell()  # AbilityData.STARTING_SPELL for the Gravecaller.
	spell_levels[start] = 1
	if game.records_here():
		game.codex.meet(CodexData.SPELL, start)  # Codex: the starting spell (records only).
	if start == "orb_shield":
		_create_orb_shield()
	# Fortune tree (GDD §9.2 "rerolls", open question 7): extra charges.
	rerolls_max = LevelUpData.REROLLS + game.meta.int_value("rerolls")
	banishes_max = LevelUpData.BANISHES + game.meta.int_value("banishes")
	rerolls_left = rerolls_max
	banishes_left = banishes_max


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


## Value of passive `id` / `key` at level `lvl` (-1 = current level).
func _passive_value_at(id: String, key: String, lvl: int) -> float:
	var l := passive_level(id) if lvl < 0 else lvl
	if l <= 0:
		return 0.0
	return float(PassiveData.PASSIVES[id]["levels"][l - 1][key])


## Raw stats row of spell `id`: its evolution row once evolved, else the row
## of its current level (empty if not learned). Passives are NOT applied.
func spell_row(id: String) -> Dictionary:
	if evolved.has(id):
		return EvolutionData.EVOLUTIONS[evolved[id]]["stats"]
	var lvl := spell_level(id)
	if lvl <= 0:
		return {}
	return AbilityData.SPELLS[id]["levels"][lvl - 1]


## Effective stats of spell `id` (spell_row() with the spell passives and
## the Hyper power-up applied; empty if not learned). Cached until the next
## card is applied or a Hyper buff starts / ends (invalidate_spell_stats()).
func spell_stats(id: String) -> Dictionary:
	if not _eff_cache.has(id):
		var row := spell_row(id)
		_eff_cache[id] = {} if row.is_empty() else _apply_spell_buffs(apply_spell_mods(row))
	return _eff_cache[id]


## Drops the cached effective spell stats (a timed spell buff changed).
func invalidate_spell_stats() -> void:
	_eff_cache.clear()


## Applies the Hyper power-up (PowerupManager) to an effective stats row in
## place: damage keys x spell_damage_mult(), cooldown keys x
## spell_cooldown_mult(). Returns `out` unchanged while Hyper is off.
func _apply_spell_buffs(out: Dictionary) -> Dictionary:
	var pw := game.powerups  # Owner of the timed buffs.
	if pw == null or not pw.is_active("hyper"):
		return out
	for key: String in ["damage", "pulse_damage"]:
		if out.has(key):
			out[key] = float(out[key]) * pw.spell_damage_mult()
	for key: String in ["cooldown", "recharge", "pulse_interval"]:
		if out.has(key):
			out[key] = float(out[key]) * pw.spell_cooldown_mult()
	return out


## Applies the spell passives and meta upgrades to a stats row (GDD §6.4
## stacking: each passive and each meta stat is its own category, so it
## multiplies the level / evolution value):
##   AbilityData.SPELL_DAMAGE_MULT -> damage, pulse_damage (base balance)
##   Soul Conduit  -> damage, pulse_damage               x (1 + spell_damage)
##   Abyssal Focus -> cooldown, recharge, pulse_interval x (1 - cooldown_reduction)
##   meta spell_damage / spell_cooldown -> the same keys, x (1 +/- value)
##   meta spell_area -> radius, pulse_radius             x (1 + value)
##   Necrotic Expanse -> radius, pulse_radius            x (1 + spell_area)
##   Lingering Malediction -> AbilityData.DURATION_KEYS  x (1 + spell_duration)
##   character spell_area -> radius, pulse_radius        x (1 + value)
## Pass `conduit_lvl` / `focus_lvl` >= 0 to preview other passive levels.
func apply_spell_mods(row: Dictionary, conduit_lvl: int = -1, focus_lvl: int = -1) -> Dictionary:
	var out := row.duplicate()
	var dmg_mult := AbilityData.SPELL_DAMAGE_MULT \
			* (1.0 + _passive_value_at("soul_conduit", "spell_damage", conduit_lvl)) * (1.0 + game.meta.value("spell_damage"))
	var cd_mult := (1.0 - _passive_value_at("abyssal_focus", "cooldown_reduction", focus_lvl)) * (1.0 - game.meta.value("spell_cooldown"))
	var area_mult := (1.0 + game.meta.value("spell_area")) * (1.0 + passive_value("necrotic_expanse", "spell_area")) \
			* (1.0 + game.character.value("spell_area"))  # Playable character (0 for the Gravecaller).
	var dur_mult := 1.0 + passive_value("lingering_malediction", "spell_duration")  # Lingering Malediction.
	for key: String in AbilityData.DURATION_KEYS:
		if out.has(key):
			out[key] = float(out[key]) * dur_mult
	for key: String in ["damage", "pulse_damage"]:
		if out.has(key):
			out[key] = float(out[key]) * dmg_mult
	for key: String in ["cooldown", "recharge", "pulse_interval"]:
		if out.has(key):
			out[key] = float(out[key]) * cd_mult
	for key: String in ["radius", "pulse_radius"]:
		if out.has(key):
			out[key] = float(out[key]) * area_mult
	# --- Act III: the Scrap Wastes --- Conductive Marrow: a longer, wider Death
	# Ray beam (its keys exist only in the Death Ray / Event Horizon rows; the
	# passive's value is 0 while it is not owned).
	if out.has("beam_length"):
		out["beam_length"] = float(out["beam_length"]) * (1.0 + passive_value("conductive_marrow", "beam_length"))
		out["beam_width"] = float(out["beam_width"]) * (1.0 + passive_value("conductive_marrow", "beam_width"))
	# --- Act IV: Mount Olympus --- Titan's Blood: Stolen Thunder chains more
	# hops and charges faster (its keys exist only in the Stolen Thunder /
	# Gigantomachy rows; the passive's values are 0 while it is not owned).
	if out.has("thunder_chains"):
		out["thunder_chains"] = int(out["thunder_chains"]) + int(passive_value(StolenThunderData.TITANS_BLOOD, StolenThunderData.CHAINS_KEY))
		out["thunder_charge"] = float(out["thunder_charge"]) * (1.0 - passive_value(StolenThunderData.TITANS_BLOOD, StolenThunderData.CHARGE_KEY))
	return out


## Display name of spell `id` (its evolution's name once evolved).
func spell_name(id: String) -> String:
	if evolved.has(id):
		return EvolutionData.EVOLUTIONS[evolved[id]]["display_name"]
	return AbilityData.SPELLS[id]["display_name"]


## Evolution ids whose condition currently holds (EvolutionData header):
## base spell at BASE_LEVEL_REQUIRED, not evolved yet, paired passive at
## PASSIVE_LEVEL_REQUIRED (Lv 5), and the run has reached
## EvolutionData.MIN_ELAPSED.
func ready_evolutions() -> PackedStringArray:
	var out := PackedStringArray()
	if not evolutions_unlocked():
		return out
	for evo: String in EvolutionData.ORDER:
		var def: Dictionary = EvolutionData.EVOLUTIONS[evo]
		var base: String = def["base"]
		if evolved.has(base):
			continue
		if spell_level(base) >= EvolutionData.BASE_LEVEL_REQUIRED and passive_level(def["passive"]) >= EvolutionData.PASSIVE_LEVEL_REQUIRED:
			out.append(evo)
	# Summon evolutions: same time gate and chest delivery (SummonEvolutionData).
	out.append_array(game.horde.evolutions.ready_ids())
	return out


## True once the run is old enough for evolutions (EvolutionData.MIN_ELAPSED).
func evolutions_unlocked() -> bool:
	return game.elapsed >= EvolutionData.MIN_ELAPSED


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


## HUD helper: [{icon, level, max}] for owned actives (summons first). An
## evolved spell shows its evolution icon.
func owned_actives() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for cls: String in UnitData.CLASS_ORDER:
		var lvl: int = game.horde.class_levels[cls]
		if lvl > 0:
			out.append({"icon": game.horde.evolutions.class_icon(cls), "level": lvl, "max": 5})
	for id: String in AbilityData.SPELL_ORDER:
		if spell_level(id) > 0:
			var icon: String = EvolutionData.EVOLUTIONS[evolved[id]]["icon"] if evolved.has(id) else AbilityData.SPELLS[id]["icon"]
			out.append({"icon": icon, "level": spell_level(id), "max": (AbilityData.SPELLS[id]["levels"] as Array).size()})
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
	if not _detonations.is_empty():
		_step_detonations(delta)
	spells.step(delta)  # The newer spells (Bone Spear ... Plague Cloud, Death Mark ... Raise Dead).


## Kill hook from CombatResolver._kill_enemy (the enemy is still in place):
## forwarded to the newer spells (corpses, Soul Rapture bursts).
func on_enemy_killed(e: Enemy) -> void:
	spells.on_enemy_killed(e)


## Flips the Shadow Bolt aim mode between Nearest and Strongest.
func toggle_bolt_aim() -> void:
	bolt_aim_strongest = not bolt_aim_strongest


## UI name of the current Shadow Bolt aim mode.
func bolt_aim_name() -> String:
	return "Strongest" if bolt_aim_strongest else "Nearest"


## Shadow Bolt: fires `count` bolts at the best targets within range, ranked
## by the aim mode (lower score = better):
##   Nearest   — nearest enemies, enemies attacking summons first (GDD §33).
##   Strongest — highest current HP (whole HP points; ties go to the nearest),
##               so the boss and elites are favoured only through their HP.
## Extra bolts of multi-bolt levels go to the next-ranked targets. In both
## modes targets already expected to die (overkill reservation) rank last.
## Once evolved into Void Barrage the bolts also split on their first hit.
## Returns false if there was nothing to shoot.
func _cast_bolt(s: Dictionary) -> bool:
	var p := game.player.position
	game.enemy_grid.query(p, float(s["range"]), _tmp)
	_cands.clear()
	for e: Enemy in _tmp:
		if not e.active:
			continue
		var dist := p.distance_to(e.position)
		var score := dist
		if bolt_aim_strongest:
			# Distance (< range, well under 10000) only breaks HP ties.
			score = -roundf(e.hp) * 10000.0 + dist
		elif e.targeting_summon:
			score -= AbilityData.BOLT_PROTECT_BONUS
		if e.hp - e.incoming_damage <= 0.0:
			score += 1.0e9
		_cands.append([score, e])
	if _cands.is_empty():
		return false
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var count: int = s["count"]
	var void_barrage := s.has("split")
	game.player.cast_motion((_cands[0][1] as Enemy).position)  # Engine motion: toward the first target (visual only).
	for i in count:
		var e: Enemy = _cands[i % _cands.size()][1]
		if not void_barrage:
			game.projectiles.fire_friendly(Projectile.Kind.SHADOW_BOLT, p, e, float(s["damage"]), float(s["speed"]), int(s["pierce"]), "bolt")
			continue
		# Void Barrage (GDD §5.1): rapid piercing bolts that split on impact.
		var b := game.projectiles.fire_friendly(Projectile.Kind.VOID_BOLT, p, e, float(s["damage"]), float(s["speed"]), int(s["pierce"]), "void")
		if b != null:
			b.split_count = int(s["split"])
			b.split_damage = float(s["damage"]) * float(s["split_damage"])
			b.split_speed = float(s["split_speed"])
			b.split_life = float(s["split_life"])
	Sfx.play("bolt_cast", p)
	return true


## Shadow Blast: AoE damage + slow around the player. Returns false (retry
## soon) when no enemy is in range so the cooldown is not wasted.
## Abyssal Detonation (evolved, GDD §5.1) adds a short pull toward the centre
## and a second hit `second_delay` s later at the same spot.
func _cast_blast(s: Dictionary) -> bool:
	var p := game.player.position
	var r: float = s["radius"]
	var abyss := s.has("pull")
	game.enemy_grid.query(p, r + 30.0, _tmp)
	var hit := false
	for e: Enemy in _tmp:
		if e.active and e.position.distance_to(p) <= r + e.radius:
			hit = true
			if abyss:
				_pull_enemy(e, p, r, s)
			game.combat.slow_enemy(e, float(s["slow"]), float(s["slow_duration"]))
			game.combat.damage_enemy(e, float(s["damage"]), "abyss" if abyss else "blast")
	if not hit:
		return false
	game.innates.on_blast(p, r, float(s["damage"]))  # Voidcaller's Echoing Dark (no-op otherwise).
	game.player.cast_motion(p)  # Engine motion: a pulse around him (visual only).
	if abyss:
		game.effects.abyss(p, r, "abyssal_detonation")  # The vortex animation when its art exists (visual only).
		_detonations.append({"t": float(s["second_delay"]), "pos": p, "stats": s})
		game.stat_add("abyssal_detonations", 1.0)
	else:
		game.effects.ring(p, r, Palette.VIOLET, 0.35, "shadow_blast")
	game.shake(2.0)
	game.stat_add("shadow_blasts", 1.0)
	return true


## Abyssal Detonation pull: enemies outside the inner core get an inward
## impulse (stronger near the rim, divided by mass; decays like knockback).
func _pull_enemy(e: Enemy, center: Vector2, r: float, s: Dictionary) -> void:
	var to_c := center - e.position
	var d := to_c.length()
	var inner := r * float(s["pull_inner"])
	if d <= inner or d < 0.01:
		return
	var k := clampf((d - inner) / maxf(r - inner, 1.0), 0.0, 1.0)
	e.knockback += to_c / d * float(s["pull"]) * (0.5 + 0.5 * k) / maxf(e.mass, 0.1)


## Counts down pending Abyssal Detonation second hits and releases them.
func _step_detonations(delta: float) -> void:
	var i := 0
	while i < _detonations.size():
		var d: Dictionary = _detonations[i]
		d["t"] = float(d["t"]) - delta
		if float(d["t"]) > 0.0:
			i += 1
			continue
		_detonations.remove_at(i)
		var s: Dictionary = d["stats"]
		var pos: Vector2 = d["pos"]
		var r: float = s["radius"]
		game.enemy_grid.query(pos, r + 30.0, _tmp)
		for e: Enemy in _tmp:
			if e.active and e.position.distance_to(pos) <= r + e.radius:
				game.combat.damage_enemy(e, float(s["damage"]) * float(s["second_damage"]), "abyss")
		game.effects.ring(pos, r, Palette.NECRO_GREEN, 0.3, "abyssal_burst")  # The burst animation when its art exists (visual only).
		game.effects.ring_under(pos, r * 0.55, Palette.VIOLET, 0.4, "abyssal_burst")  # Drawn only without the burst art.
		game.shake(3.0)


# =====================================================================================
# Level-up cards: weighted offers, evolutions, reroll / banish / skip
# =====================================================================================

## Builds up to `n` offers (GDD §9.1 "three randomized choices"):
##   1. weighted draw without replacement from every upgradeable spell,
##      summon class and passive (LevelUpData weights: owned upgrades and
##      evolution paths come up more often, "dead" cards rarely; never only
##      dead cards while a live one exists),
##   2. fallback cards fill any slot left empty (everything maxed / banished).
## Ready evolutions are NOT offered here: treasure chests deliver them
## (chest_rewards()).
func build_offers(n: int) -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	var cands := _candidates({})
	while offers.size() < n and not cands.is_empty():
		offers.append(_draw_weighted(cands))
	_ensure_live_card(offers, cands)
	_fill_fallbacks(offers, n)
	return offers


## Treasure chest contents (ChestData): grants up to `n` rewards one after
## the other and returns their offers in order (already applied):
##   1. every ready evolution first (ready_evolutions(), the eligibility
##      check is unchanged),
##   2. then weighted draws from the normal level-up pool (_candidates(),
##      recomputed after each grant, so one item may rise twice; the Profane
##      Pact is never granted by a chest). Unless ChestData.GRANTS_NEW_ITEMS,
##      only items the player already OWNS are drawn (survivor convention):
##      a chest never fills an empty active or passive slot, so slots stay
##      the player's own level-up choices (_owned_only()),
##   3. if nothing at all can be upgraded, the Dark Restoration heal.
func chest_rewards(n: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []  # Rewards granted, in order.
	for _i in n:
		var o: Dictionary = {}  # Reward to grant next.
		var evos := ready_evolutions()  # Evolutions waiting for a chest.
		if not evos.is_empty():
			o = _evolution_offer(evos[0])
		else:
			var cands := _candidates({PactData.ID: true})  # Pool without the Pact.
			if not ChestData.GRANTS_NEW_ITEMS:
				cands = _owned_only(cands)
			if cands.is_empty():
				break
			o = _draw_weighted(cands)
		apply_offer(o)
		out.append(o)
	if out.is_empty():
		var heal := _fallback_offer("dark_restoration")  # Nothing left to upgrade.
		apply_offer(heal)
		out.append(heal)
	return out


## The entries of `cands` (_candidates() format) that upgrade an item the
## player already owns (offer "from" level > 0): what a treasure chest may
## grant (ChestData.GRANTS_NEW_ITEMS).
static func _owned_only(cands: Array[Dictionary]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []  # Upgrades of owned items only.
	for c in cands:
		if int((c["offer"] as Dictionary)["from"]) > 0:
			out.append(c)
	return out


## Uses one reroll charge. Returns false (nothing happens) when none is left.
func use_reroll() -> bool:
	if rerolls_left <= 0:
		return false
	rerolls_left -= 1
	game.stat_add("levelup_rerolls", 1.0)
	return true


## True if card `o` may be banished (regular items only, not evolutions or
## fallback cards) and a banish charge is left.
func can_banish(o: Dictionary) -> bool:
	return banishes_left > 0 and String(o["kind"]) in ["spell", "summon", "passive"]


## Banishes the item of `offers[idx]` for the rest of the run (it is never
## offered again; levels already owned are kept) and returns a copy of
## `offers` with that card replaced by a fresh weighted draw (or a fallback).
func banish_offer(offers: Array[Dictionary], idx: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = offers.duplicate()
	if idx < 0 or idx >= out.size() or not can_banish(out[idx]):
		return out
	var id: String = out[idx]["id"]
	banished[id] = true
	banishes_left -= 1
	game.stat_add("levelup_banishes", 1.0)
	var exclude := {}
	for o in out:
		exclude[String(o["id"])] = true
	var cands := _candidates(exclude)
	if not cands.is_empty():
		out[idx] = _draw_weighted(cands)
	else:
		out[idx] = _fallback_offer(_unused_fallback(out))
	return out


## Pseudo-offer for skipping a level-up (apply_offer heals a little).
func skip_offer() -> Dictionary:
	return _offer("skip", "skip", "Skip", "", 0, 0, "SKIP", "", PackedStringArray())


## Applies a chosen card (or a skip).
func apply_offer(o: Dictionary) -> void:
	var id: String = o["id"]
	var to: int = o["to"]
	match String(o["kind"]):
		"spell":
			spell_levels[id] = to
			if id == "orb_shield" and orb_shield == null:
				_create_orb_shield()
			if game.records_here():  # Co-op: only this machine's own player records.
				game.character.on_spell_level(id, to)  # Character unlock rule (Meta save).
				game.codex.meet(CodexData.SPELL, id)  # Codex: a spell learned (records only).
		"summon":
			game.horde.set_class_level(id, to)
		"passive":
			var old_caps := game.horde.capacity_snapshot()
			passive_levels[id] = to
			game.horde.recompute_all(old_caps)
		"evolution":
			if SummonEvolutionData.EVOLUTIONS.has(id):
				game.horde.evolutions.apply(id)
			else:
				_apply_evolution(id)
			if game.records_here():
				Meta.discover_recipe(id)  # Recipe book: the pause menu's Recipes view (saved at once).
		"fallback":
			_apply_fallback(id)
		"skip":
			skips_used += 1
			game.combat.heal_player(game.player.max_hp * LevelUpData.SKIP_HEAL_FRACTION)
			game.stat_add("levelup_skips", 1.0)
	_eff_cache.clear()
	if String(o["kind"]) == "evolution":
		pick_history.append("EVOLVE %s" % id)
	elif String(o["kind"]) == "skip" or String(o["kind"]) == "fallback":
		pick_history.append(id)
	else:
		pick_history.append("%s %d" % [id, to])


## Creates the Orb Shield node (the spell was just learned).
func _create_orb_shield() -> void:
	orb_shield = OrbShield.new()
	orb_shield.game = game
	add_child(orb_shield)


## Evolves the base spell of evolution `evo` in place (same active slot).
func _apply_evolution(evo: String) -> void:
	var def: Dictionary = EvolutionData.EVOLUTIONS[evo]
	evolved[String(def["base"])] = evo
	evolution_history.append("%s@%s" % [evo, _clock(game.elapsed)])
	game.stat_add("evolutions", 1.0)
	var p := game.player.position
	game.effects.ring(p, 120.0, Palette.NECRO_GREEN, 0.7)
	game.effects.ring(p, 80.0, Palette.VIOLET, 0.9)
	if game.hud != null:
		game.hud.announce("EVOLUTION", String(def["display_name"]), String(def["description"]), Palette.GOLD)


## Applies fallback card `id` (LevelUpData.FALLBACKS).
func _apply_fallback(id: String) -> void:
	match id:
		"dark_restoration":
			game.combat.heal_player(game.player.max_hp * PlayerData.FALLBACK_HEAL_FRACTION)
		"grave_fortitude":
			game.player.max_hp += LevelUpData.FORTITUDE_MAX_HP
			game.combat.heal_player(LevelUpData.FORTITUDE_MAX_HP)
		"call_of_the_grave":
			game.horde.raise_all_missing()


## Every upgradeable item not banished and not in `exclude` (id -> true), as
## {"offer", "weight", "dead"} entries for the weighted draw. A NEW card of a
## later item (spell, summon class or passive flagged "shared_card_pool")
## weighs LevelUpData.WEIGHT_NEW_LATER, an original spell / passive
## LevelUpData.WEIGHT_NEW and a GDD summon role LevelUpData.WEIGHT_NEW_CORE_SUMMON.
func _candidates(exclude: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var can_new_active := active_count() < PlayerData.ACTIVE_SLOTS
	var can_new_passive := passive_count() < PlayerData.PASSIVE_SLOTS
	var owns_summon := false
	for cls: String in UnitData.CLASS_ORDER:
		owns_summon = owns_summon or int(game.horde.class_levels[cls]) > 0
	var owns_spell := false
	for id: String in AbilityData.SPELL_ORDER:
		owns_spell = owns_spell or spell_level(id) > 0
	for id: String in AbilityData.SPELL_ORDER:
		var lvl := spell_level(id)
		var max_lvl := (AbilityData.SPELLS[id]["levels"] as Array).size()
		if banished.has(id) or exclude.has(id) or evolved.has(id) or lvl >= max_lvl or (lvl == 0 and not can_new_active):
			continue
		if lvl == 0 and not _offerable(id):
			continue  # Act II: locked, or another act's card (Unlocks).
		var w := LevelUpData.WEIGHT_OWNED if lvl > 0 else (LevelUpData.WEIGHT_NEW_LATER if bool(AbilityData.SPELLS[id].get("shared_card_pool", false)) else LevelUpData.WEIGHT_NEW)
		var evo := EvolutionData.for_spell(id)
		if lvl > 0 and evo != "" and passive_level(EvolutionData.EVOLUTIONS[evo]["passive"]) > 0:
			w *= LevelUpData.WEIGHT_EVOLUTION_PATH
		if game.autotest != null:
			w *= game.autotest.card_weight_mult(id)  # Test only: --spells items come up more often.
		out.append({"offer": _spell_offer(id, lvl), "weight": w, "dead": false})
	var evos := game.horde.evolutions  # Summon-evolution card hooks.
	for cls: String in UnitData.CLASS_ORDER:
		var lvl: int = game.horde.class_levels[cls]
		if banished.has(cls) or exclude.has(cls) or lvl >= (UnitData.LEVELS[cls] as Array).size() or (lvl == 0 and not can_new_active):
			continue
		if evos.is_locked(cls):
			continue  # Merged away, or only created by an evolution.
		if lvl == 0 and not _offerable(cls):
			continue  # Act II: locked, or another act's card (Unlocks).
		var w := LevelUpData.WEIGHT_OWNED if lvl > 0 else (LevelUpData.WEIGHT_NEW_LATER if bool(UnitData.UNITS[cls].get("shared_card_pool", false)) else LevelUpData.WEIGHT_NEW_CORE_SUMMON)
		if lvl == 0:
			w *= float(UnitData.UNITS[cls].get("new_card_weight_mult", 1.0))  # The split priest orders share one role's weight.
		if lvl > 0 and evos.on_path(cls):
			w *= LevelUpData.WEIGHT_EVOLUTION_PATH
		out.append({"offer": _summon_offer(cls, lvl), "weight": w, "dead": false})
	for id: String in PassiveData.ORDER:
		var lvl := passive_level(id)
		if banished.has(id) or exclude.has(id) or lvl >= (PassiveData.PASSIVES[id]["levels"] as Array).size() or (lvl == 0 and not can_new_passive):
			continue
		if lvl == 0 and not _offerable(id):
			continue  # Act II: locked, or another act's card (Unlocks).
		if id == PactData.ID and not allow_pact:
			continue  # Co-op guest: the Profane Pact is the host's pick.
		var w := LevelUpData.WEIGHT_OWNED if lvl > 0 else (LevelUpData.WEIGHT_NEW_LATER if bool(PassiveData.PASSIVES[id].get("shared_card_pool", false)) else LevelUpData.WEIGHT_NEW)
		var paired := _paired_spell(id)
		if paired != "" and spell_level(paired) > 0 and not evolved.has(paired):
			w *= LevelUpData.WEIGHT_EVOLUTION_PATH
		elif evos.on_path(id):
			w *= LevelUpData.WEIGHT_EVOLUTION_PATH
		var dead := (id in PassiveData.ARMY_PASSIVES and not owns_summon) or (id in PassiveData.SPELL_PASSIVES and not owns_spell) \
				or evos.passive_dead(id)
		if dead:
			w *= LevelUpData.WEIGHT_DEAD
		if id == PactData.ID:
			w *= PactData.CARD_WEIGHT_MULT  # Modest weight (PactData).
		if game.autotest != null:
			w *= game.autotest.card_weight_mult(id)  # Test only: --spells items come up more often.
		out.append({"offer": _passive_offer(id, lvl), "weight": w, "dead": dead})
	return out


## True when item `id` may be offered as a NEW card: Unlocks.offerable() (this
## device's save), or in co-op this player's own unlocks (offer_unlocks).
func _offerable(id: String) -> bool:
	if offer_unlocks == null:
		return Unlocks.offerable(id, game.stage_def)
	return Unlocks.offerable_with(id, game.stage_def, offer_unlocks as Dictionary)


## Removes and returns one weighted-random offer from `cands`.
func _draw_weighted(cands: Array[Dictionary]) -> Dictionary:
	var total := 0.0
	for c in cands:
		total += float(c["weight"])
	var r := (offer_rng.randf() if offer_rng != null else randf()) * total  # Co-op: the slot's own stream.
	var idx := cands.size() - 1
	for i in cands.size():
		r -= float(cands[i]["weight"])
		if r <= 0.0:
			idx = i
			break
	var picked: Dictionary = cands[idx]
	cands.remove_at(idx)
	var o: Dictionary = picked["offer"]
	o["dead"] = picked["dead"]
	return o


## "Never only dead cards": if every offer is dead and a live candidate is
## left in `cands`, the last dead offer is replaced by a live weighted draw.
func _ensure_live_card(offers: Array[Dictionary], cands: Array[Dictionary]) -> void:
	if offers.is_empty():
		return
	for o in offers:
		if not bool(o.get("dead", false)):
			return
	var live: Array[Dictionary] = []
	for c in cands:
		if not bool(c["dead"]):
			live.append(c)
	if not live.is_empty():
		offers[offers.size() - 1] = _draw_weighted(live)


## Fills `offers` up to `n` cards with fallback cards not already shown.
func _fill_fallbacks(offers: Array[Dictionary], n: int) -> void:
	while offers.size() < n:
		var id := _unused_fallback(offers)
		if id == "":
			return
		offers.append(_fallback_offer(id))


## First fallback id (LevelUpData.FALLBACK_ORDER) not present in `offers`.
func _unused_fallback(offers: Array[Dictionary]) -> String:
	for id: String in LevelUpData.FALLBACK_ORDER:
		var used := false
		for o in offers:
			used = used or String(o["id"]) == id
		if not used:
			return id
	return ""


## Spell evolved by passive `id` ("" if it is not an evolution passive).
static func _paired_spell(id: String) -> String:
	for evo: String in EvolutionData.ORDER:
		if String(EvolutionData.EVOLUTIONS[evo]["passive"]) == id:
			return EvolutionData.EVOLUTIONS[evo]["base"]
	return ""


## Common offer skeleton. `evo_hint` is the optional card footer line (a
## synergy unlock, the evolution card's slot note, the Pact note; evolution
## recipes are no longer spelled out, owner decision GDD §15.0 "Recipe icon
## row"). "evo_recipe" is the evolution id the card's spell / class / passive
## feeds ("" = none): the card shows it as an icon row once that recipe is
## discovered (Meta.is_recipe_discovered(), RecipeIconRow).
func _offer(kind: String, id: String, display_name: String, icon: String, from: int, to: int, tag: String, desc: String, deltas: PackedStringArray, evo_hint: String = "") -> Dictionary:
	return {"kind": kind, "id": id, "name": display_name, "icon": icon, "from": from, "to": to,
		"tag": tag, "description": desc, "deltas": deltas, "evo_hint": evo_hint, "evo_recipe": ""}


## Spell card: lists base stats when new, otherwise every effective stat that
## changes, plus the evolution readiness line.
func _spell_offer(id: String, lvl: int) -> Dictionary:
	var def: Dictionary = AbilityData.SPELLS[id]
	var levels: Array = def["levels"]
	var labels: Dictionary = def["labels"]
	var nxt := apply_spell_mods(levels[lvl])
	var deltas := PackedStringArray()
	for key: String in labels:
		if lvl == 0:
			deltas.append("%s %s" % [labels[key], _fmt_spell(key, nxt[key])])
		else:
			var cur := apply_spell_mods(levels[lvl - 1])
			if not is_equal_approx(float(cur[key]), float(nxt[key])):
				deltas.append("%s %s -> %s" % [labels[key], _fmt_spell(key, cur[key]), _fmt_spell(key, nxt[key])])
	var o := _offer("spell", id, def["display_name"], def["icon"], lvl, lvl + 1, "SPELL", def["description"], deltas)
	o["evo_recipe"] = EvolutionData.for_spell(id)  # Shown as icons only once discovered (owner decision).
	return o


## Evolution card: base spell (level 5, effective) vs evolved effective stats.
## Summon evolutions build their own card (SummonEvolutions.build_offer()).
func _evolution_offer(evo: String) -> Dictionary:
	if SummonEvolutionData.EVOLUTIONS.has(evo):
		return game.horde.evolutions.build_offer(evo)
	var def: Dictionary = EvolutionData.EVOLUTIONS[evo]
	var base: String = def["base"]
	var cur := apply_spell_mods(spell_row(base))
	var nxt := apply_spell_mods(def["stats"])
	var labels: Dictionary = def["labels"]
	var deltas := PackedStringArray()
	for key: String in labels:
		if cur.has(key):
			if not is_equal_approx(float(cur[key]), float(nxt[key])):
				deltas.append("%s %s -> %s" % [labels[key], _fmt_spell(key, cur[key]), _fmt_spell(key, nxt[key])])
		else:
			deltas.append("NEW  %s %s" % [labels[key], _fmt_spell(key, nxt[key])])
	var hint := "Replaces %s in its slot" % AbilityData.SPELLS[base]["display_name"]
	return _offer("evolution", evo, def["display_name"], def["icon"], spell_level(base), spell_level(base), "EVOLUTION", def["description"], deltas, hint)


## Summon card: effective stats now vs next level (passives included). The
## support lines follow the class's kit (heal / ward / ally barrier), so the
## Mender and Warder cards show what each one does.
func _summon_offer(cls: String, lvl: int) -> Dictionary:
	var base: Dictionary = UnitData.UNITS[cls]
	var plural: String = game.horde.evolutions.class_plural(cls)
	var dom := game.horde.bonus_capacity(cls)
	var nxt := game.horde.compute_stats(cls, lvl + 1, false)
	var deltas := PackedStringArray()
	var desc := String(base["description"])  # One-sentence class text (UnitData), at every level like a spell's.
	var support := float(nxt["heal_amount"]) > 0.0 or float(nxt["shield_amount"]) > 0.0  # Mender / Warder kit.
	if lvl == 0:
		deltas.append("%s: %d" % [plural, int(nxt["count"]) + dom])
		deltas.append("Fallen ones return every %ss" % _fmt(game.horde.replenish_interval(cls)))
		deltas.append("HP %s" % _fmt(nxt["max_hp"]))
		if support:
			if float(nxt["heal_amount"]) > 0.0:
				deltas.append("Heals %s HP every %ss (allies and you)" % [_fmt(nxt["heal_amount"]), _fmt(nxt["attack_interval"])])
			if float(nxt["shield_amount"]) > 0.0:
				deltas.append("Wards you for %s HP when you are attacked" % _fmt(nxt["shield_amount"]))
			if float(nxt["ally_shield_amount"]) > 0.0:
				deltas.append("Shields a threatened ally for %s HP every %ss" % [_fmt(nxt["ally_shield_amount"]), _fmt(nxt["ally_shield_cooldown"])])
		elif cls == "warrior":
			deltas.append("Damage %s every %ss" % [_fmt(nxt["damage"]), _fmt(nxt["attack_interval"])])
			deltas.append("Blocks enemies; shield-bash %s dmg every %ss" % [_fmt(nxt["bash_damage"]), _fmt(nxt["bash_cooldown"])])
		else:
			deltas.append("Damage %s every %ss" % [_fmt(nxt["damage"]), _fmt(nxt["attack_interval"])])
		deltas.append_array(SummonBehaviors.card_lines(cls, {}, nxt))  # Class special, if any.
		deltas.append("Range %s px" % _fmt(nxt["attack_range"]))
	else:
		var cur := game.horde.compute_stats(cls, lvl, false)
		_delta_line(deltas, plural, float(int(cur["count"]) + dom), float(int(nxt["count"]) + dom))
		_delta_line(deltas, "Max HP", cur["max_hp"], nxt["max_hp"])
		if support:
			_delta_line(deltas, "Heal per cast", cur["heal_amount"], nxt["heal_amount"])
		else:
			_delta_line(deltas, "Damage", cur["damage"], nxt["damage"])
			_delta_line(deltas, "Shield bash", cur["bash_damage"], nxt["bash_damage"])
		_delta_line(deltas, "Attack interval (s)", cur["attack_interval"], nxt["attack_interval"])
		_delta_line(deltas, "Splash radius", cur["splash_radius"], nxt["splash_radius"])
		_delta_line(deltas, "Arrow pierce", float(cur["pierce"]), float(nxt["pierce"]))
		_delta_line(deltas, "Ward on you (HP)", cur["shield_amount"], nxt["shield_amount"])
		_delta_line(deltas, "Ally barrier (HP)", cur["ally_shield_amount"], nxt["ally_shield_amount"])
		deltas.append_array(SummonBehaviors.card_lines(cls, cur, nxt))  # Class special, if any.
	var hint := ""
	if lvl + 1 == SynergyData.MIN_CLASS_LEVEL:
		hint = game.horde.synergies.unlock_hint(cls)
	var o := _offer("summon", cls, base["display_name"], cls, lvl, lvl + 1, "SUMMON", desc, deltas, hint)
	o["evo_recipe"] = game.horde.evolutions.class_recipe(cls)  # Shown as icons only once discovered.
	return o


## Passive card: passive value now vs next plus one concrete effect line.
func _passive_offer(id: String, lvl: int) -> Dictionary:
	if id == PactData.ID:
		return _pact_offer(lvl)
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
	var warrior := game.horde.compute_stats("warrior", maxi(1, int(game.horde.class_levels["warrior"])), false)
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
		"soul_conduit":
			var row := spell_row("shadow_bolt")
			if not row.is_empty():
				var a := apply_spell_mods(row, lvl, -1)
				var b := apply_spell_mods(row, lvl + 1, -1)
				deltas.append("%s damage %s -> %s" % [spell_name("shadow_bolt"), _fmt(a["damage"]), _fmt(b["damage"])])
		"warding_ritual":
			var hit := 20.0
			deltas.append("A %s-damage hit: %s -> %s" % [_fmt(hit), _fmt(hit * (1.0 - _passive_value_at(id, "damage_reduction", lvl))), _fmt(hit * (1.0 - float(nxt["damage_reduction"])))])
		"abyssal_focus":
			var row := spell_row("shadow_bolt")
			if not row.is_empty():
				var a := apply_spell_mods(row, -1, lvl)
				var b := apply_spell_mods(row, -1, lvl + 1)
				deltas.append("%s cooldown %ss -> %ss" % [spell_name("shadow_bolt"), _fmt(a["cooldown"]), _fmt(b["cooldown"])])
		"forbidden_knowledge", "dark_benediction":
			deltas.append(game.horde.evolutions.passive_effect_line(id, lvl, nxt))
		"bone_plating", "unholy_precision", "unholy_resilience", "bound_souls":
			deltas.append(MinionPassives.card_line(game, id, nxt))  # The later horde passives.
		"blood_scent", "mournsong", "siegecraft":
			deltas.append(ClassPassives.card_line(game, id, nxt))  # The newest classes' passives.
		"fallen_grace":
			deltas.append(SeraphTexts.card_line(game, id, nxt))  # Act II: Fallen Grace (the Fallen Seraph's passive).
		"grave_masonry":
			deltas.append(GolemTexts.card_line(game, id, nxt))  # Content wave 2: the Bone Golem's passive.
		_:
			spells.passive_example(id, nxt, deltas)  # The newer spells' passives.
	var spell := _paired_spell(id)
	var o := _offer("passive", id, def["display_name"], def["icon"], lvl, lvl + 1, "PASSIVE", def["description"], deltas)
	# The evolution this passive feeds (spell, else summon), shown as icons only once discovered.
	o["evo_recipe"] = EvolutionData.for_spell(spell) if spell != "" else game.horde.evolutions.passive_recipe(id)
	return o


## Profane Pact card (tag PACT): every penalty and reward as the COMBINED
## Pact + Oath bonus now -> after this level (game.difficulty adds them).
func _pact_offer(lvl: int) -> Dictionary:
	var def: Dictionary = PassiveData.PASSIVES[PactData.ID]  # The Pact passive definition.
	var labels: Dictionary = def["labels"]  # Key -> [label, format].
	var deltas := PackedStringArray()  # One "label old -> new" line per key.
	for key: String in PactData.KEYS:
		var cur_v := game.difficulty.value(key, lvl)  # Bonus at the current level.
		var nxt_v := game.difficulty.value(key, lvl + 1)  # Bonus after this card.
		deltas.append("%s %s -> %s" % [labels[key][0], _fmt_passive(cur_v, "pct"), _fmt_passive(nxt_v, "pct")])
	var hint := "Raises danger AND rewards. Can be banished."  # Card footer line.
	if game.difficulty.oath_tier() > 0:
		hint = "Includes your Profane Oath %s. Can be banished." % DifficultyModifiers.roman(game.difficulty.oath_tier())
	return _offer("passive", PactData.ID, def["display_name"], def["icon"], lvl, lvl + 1, "PACT", def["description"], deltas, hint)


## Fallback card `id` (LevelUpData.FALLBACKS) with its concrete effect.
func _fallback_offer(id: String) -> Dictionary:
	var def: Dictionary = LevelUpData.FALLBACKS[id]
	var deltas := PackedStringArray()
	match id:
		"dark_restoration":
			deltas.append("Restore %s HP" % _fmt(game.player.max_hp * PlayerData.FALLBACK_HEAL_FRACTION))
		"grave_fortitude":
			deltas.append("Max HP %s -> %s" % [_fmt(game.player.max_hp), _fmt(game.player.max_hp + LevelUpData.FORTITUDE_MAX_HP)])
			deltas.append("Restore %s HP" % _fmt(LevelUpData.FORTITUDE_MAX_HP))
		"call_of_the_grave":
			var missing := game.horde.missing_count()
			deltas.append("Raise %d fallen summons now" % missing if missing > 0 else "Your army is at full strength")
	return _offer("fallback", id, def["display_name"], def["icon"], 0, 0, def["tag"], def["description"], deltas)


## Appends "label a -> b" when the value changes.
func _delta_line(out: PackedStringArray, label: String, a: float, b: float) -> void:
	if not is_equal_approx(a, b):
		out.append("%s %s -> %s" % [label, _fmt(a), _fmt(b)])


## Formats a number compactly: integers without decimals, else 2 decimals max.
static func _fmt(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return str(snappedf(v, 0.01))


## Formats a spell stat (slow and second-hit fractions, and
## AbilityData.PERCENT_KEYS, are shown as %).
static func _fmt_spell(key: String, v: Variant) -> String:
	if key == "slow" or key == "second_damage" or key in AbilityData.PERCENT_KEYS:
		return "%d%%" % int(roundf(float(v) * 100.0))
	return _fmt(float(v))


## Formats a passive value per its label format ("int" / "pct" / "neg_pct" /
## "num").
static func _fmt_passive(v: float, fmt: String) -> String:
	match fmt:
		"pct":
			return "+%d%%" % int(roundf(v * 100.0))
		"neg_pct":
			return "-%d%%" % int(roundf(v * 100.0))
		"num":
			return "+%s" % _fmt(v)
	return "+%d" % int(v)


## Formats seconds as mm:ss.
static func _clock(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [floori(float(s) / 60.0), s % 60]
