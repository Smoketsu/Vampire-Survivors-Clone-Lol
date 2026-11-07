## DynastyRules — the Necropolis Dynasty's shared rules (temporary Act XII,
## final slot VII; GDD §15.0 "The Necropolis Dynasty foundation (phase 1)",
## "Rebirth", "The Black Land", "Heka" and "The Devourer's Hour"), run as
## `Game.dynasty`. Null on every other act (created in Game._ready() only for
## a stage whose STAGE has "dynasty": true), except that a Dynasty kind forced
## onto any other stage with --spawn= creates it on its first activation
## through Game.dynasty_rules() (DynastyKit.reset()), so a kind works anywhere
## (as the Act III to IX kinds do); there the clocks stay off (`enabled`
## false: no quicksand, no Sandstorm, no stub jars, no Devourer's Hour) and
## only what the kind itself uses (its Rebirth, its glyphs) runs.
## Owns ONE path per rule:
##   rebirth   — Rebirth: THE CARTOUCHE (on_death(): every fallen mummy or
##               guardian), the return, the steal by a raise (on_raise(), from
##               HordeDirector.raise_corpse()), the smash (smash(), from
##               CombatResolver.damage_enemy()), the Canopic Jars, the
##               Embalmers' haste.
##   quicksand — Quicksand: the Black Land's ground (fixed patches, add_patch()
##               for phase 2), slowing everyone through FenWater.wade() and
##               TerrainSlow.
##   sandstorm — Sandstorm: THE CLOCK (every 5:00 for 40 s), is_up() / the
##               reach multipliers every reader asks.
##   heka      — Heka: THE GLYPHS (write(), the jumps, the cleanses), each
##               curse through CombatResolver.curse_unit().
##   devourer  — DevourersHour: the act's Reckoning (RECKONING
##               "devourers_hour"): Rebirth unlimited, the endless storm, the
##               lanes.
## Hooks for the future counter-passives (exactly 1 today): embalmed_shed_mult(),
## embalmed_taken_mult() (Embalmed Bones), dune_slow_mult(), dune_reach_kept()
## (Dune Walkers).
## Stepped by Game after the enemies (and the Concord's rules) and before the
## obstacle push-out, so a returned body or a risen jar is pushed out of any
## obstacle before it is drawn.
## Determinism: game time, pure hashes and the seeded gameplay RNG (the jars'
## points, the lanes), and only while it exists (this act, or a forced
## Dynasty kind).
class_name DynastyRules
extends Node2D

## Owning run.
var game: Game
## True on a Dynasty stage (STAGE "dynasty"): the clocks may run; false when a
## forced Dynasty kind made the rules elsewhere.
var enabled: bool = false
## Rebirth (the cartouches, the jars; no drawing of its own: the cartouches
## and jars are enemies and draw themselves).
var rebirth: Rebirth
## The quicksand (child node: drawn on the ground).
var quicksand: Quicksand
## The Sandstorm (child node: the sand wash and the veil).
var sandstorm: Sandstorm
## The Heka glyphs (child node: the sigils over the cursed heads).
var heka: Heka
## The Devourer's Hour (child node: its lanes).
var devourer: DevourersHour
## Live Embalmers (rows with "embalms"), in activation order (DynastyKit
## registers / unregisters them): Rebirth's haste reads them.
var embalmers: Array[Enemy] = []
## Dynasty kind -> game time (s) of its first activation this run (the
## autotest's "dynasty kinds" line).
var first_seen: Dictionary = {}
## Sound event -> game time (s) it last played (rate limits).
var _sound_at: Dictionary = {}


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "DynastyRules"
	enabled = bool(p_game.stage_def.get("dynasty", false))
	quicksand = Quicksand.new(p_game, enabled)
	add_child(quicksand)
	rebirth = Rebirth.new(p_game, enabled)
	heka = Heka.new(p_game)
	add_child(heka)
	sandstorm = Sandstorm.new(p_game, enabled)
	add_child(sandstorm)
	devourer = DevourersHour.new(p_game, enabled)
	add_child(devourer)


## Per-tick update (Game, after the enemies, before the obstacle push-out):
## the Devourer's Hour's clock, the Sandstorm, the cartouches and jars, the
## glyphs, the quicksand.
func step(delta: float) -> void:
	devourer.step(delta)
	sandstorm.step(delta)
	rebirth.step(delta)
	heka.step(delta)
	quicksand.step(delta)


# =====================================================================================
# Hooks (CombatResolver, HordeDirector, kits)
# =====================================================================================

## Called ONCE from CombatResolver.damage_enemy() when enemy `e` was killed,
## before the raise paths (the Lich's raise finds the cartouche already
## there): Rebirth lays a cartouche over a fallen mummy or guardian.
func on_enemy_died(e: Enemy) -> void:
	rebirth.on_death(e)


## A Dynasty kind's enemy `e` was activated (DynastyKit.reset()): its first
## time is recorded; an Embalmer joins the haste list; a jar joins Rebirth's.
func note_spawn(e: Enemy) -> void:
	if not first_seen.has(e.kind):
		first_seen[e.kind] = game.elapsed
	var d := (e.kit as DynastyKit).d
	if bool(d.get("embalms", false)) and not embalmers.has(e):
		embalmers.append(e)
	if bool(d.get("holds_names", false)):
		rebirth.note_jar(e)


## A Dynasty kind's enemy `e` left the field (DynastyKit.on_deactivate()): it
## leaves the haste list; a jar's sealed cartouches crumble; a priest's glyph
## fades (Heka.on_priest_gone()).
func note_gone(e: Enemy) -> void:
	embalmers.erase(e)
	rebirth.on_jar_gone(e)
	heka.on_priest_gone(e)


## x the cartouche timer at `p`: REBIRTH embalm_speed while a live Embalmer
## stands within embalm_radius, else 1.
func embalm_rate(p: Vector2) -> float:
	var r := float(rebirth.cfg["embalm_radius"])
	for m in embalmers:
		if m.active and m.position.distance_to(p) <= r:
			return float(rebirth.cfg["embalm_speed"])
	return 1.0


## x every ENEMY ranged reach now (DynastyKit): the Sandstorm's reach_mult
## while it blows, else 1.
func reach_mult() -> float:
	return sandstorm.reach_mult()


## x the ARMY's ranged reach now (the ranged summons' attack range in
## HordeDirector.compute_stats(), the spells' "range" in AbilityManager, the
## volleys' flight in VolleyDirector), for the bound player: the Sandstorm's
## loss, of which Dune Walkers keeps a share (dune_reach_kept(); 0 today).
func army_reach_mult() -> float:
	var r := sandstorm.reach_mult()
	if r >= 1.0:
		return 1.0
	return r + (1.0 - r) * dune_reach_kept()


## The Sandstorm rose or fell (Sandstorm): every army's effective stats and
## every player's spell stats are recomputed, so the ranged reach follows it
## (each slot bound in turn: its own passives). Only on a Dynasty run.
func on_storm_changed() -> void:
	for k in game.all_hordes.size():
		var prev := game.bind_index(k)
		game.horde.recompute_all(game.horde.capacity_snapshot())
		game.abilities.invalidate_spell_stats()
		game.unbind(prev)
	game.stat_add("sandstorm_reach_refreshes", 1.0)


## Plays the sound of Dynasty event `event` (DynastyRulesData.SOUNDS) at
## `pos`, at most once every `gap` game seconds.
func play_sound(event: String, pos: Vector2 = Vector2.INF, gap: float = 0.0) -> void:
	if gap > 0.0:
		if game.elapsed - float(_sound_at.get(event, -INF)) < gap:
			return
		_sound_at[event] = game.elapsed
	var id := String(DynastyRulesData.SOUNDS.get(event, ""))
	if id != "":
		Sfx.play(id, pos)


## The autotest autopilot's push away from every live Dynasty telegraph at
## `p`: the Devourer's lanes.
func danger_push(p: Vector2) -> Vector2:
	return devourer.danger_push(p)


# =====================================================================================
# Counter-passive hooks (Embalmed Bones, Dune Walkers: not built in phase 1)
# =====================================================================================

## The passives of the player whose army summon `u` is (co-op: its slot; the
## bound player's otherwise).
func _owner_abilities(u: SummonedUnit) -> AbilityManager:
	var ab := game.abilities  # The bound player's passives.
	if game.coop != null and u != null:
		for s in game.coop.slots:
			if s.horde == u.director:
				ab = s.abilities
				break
	return ab


## EMBALMED BONES (hook): x the time a glyph lasts on summon `u` (1 - the
## passive's glyph_shed). Exactly 1 while the passive does not exist.
func embalmed_shed_mult(u: SummonedUnit) -> float:
	return clampf(1.0 - _owner_abilities(u).passive_value(DynastyRulesData.EMBALMED_BONES,
			DynastyRulesData.EMBALMED_SHED_KEY), 0.1, 1.0)


## EMBALMED BONES (hook): the share of a hit a CURSED summon `u` takes (1 - the
## passive's cursed_damage_cut). Exactly 1 while the passive does not exist;
## phase 2 reads it from CombatResolver.damage_unit() when it builds the passive.
func embalmed_taken_mult(u: SummonedUnit) -> float:
	return clampf(1.0 - _owner_abilities(u).passive_value(DynastyRulesData.EMBALMED_BONES,
			DynastyRulesData.EMBALMED_TAKEN_KEY), 0.0, 1.0)


## DUNE WALKERS (hook): x the quicksand slow on the bound player's summons (1 -
## the passive's sand_slow_cut). Exactly 1 while the passive does not exist.
func dune_slow_mult() -> float:
	return clampf(1.0 - game.abilities.passive_value(DynastyRulesData.DUNE_WALKERS, DynastyRulesData.DUNE_SLOW_KEY), 0.0, 1.0)


## DUNE WALKERS (hook): the share (0..1) of the Sandstorm's reach loss the
## bound player's army keeps. Exactly 0 while the passive does not exist.
func dune_reach_kept() -> float:
	return clampf(game.abilities.passive_value(DynastyRulesData.DUNE_WALKERS, DynastyRulesData.DUNE_REACH_KEY), 0.0, 1.0)
