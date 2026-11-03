## ConcordRules — the Concord of Stars' shared rules (Act IX; GDD §15.0 "Act IX
## foundation (phase 1)", "Beams", "Abduction", "Terraforming" and "The Final
## Harvest"), run as `Game.concord`. Null on Acts I to VIII (created in
## Game._ready() only for a stage whose STAGE has "concord": true), except that
## a Concord kind forced onto any other stage with --spawn= creates it on its
## first activation through Game.concord_rules() (ConcordKit.reset()), so a
## kind works anywhere (as the Act III to VIII kinds do); there the terraformer
## pods and the Final Harvest stay off (`enabled` false: they read the STAGE
## "concord" key) and only what the kind itself uses (its beams, its
## abduction, its heal on any turf) runs.
## Owns ONE path per rule:
##   beams       — ConcordBeams: THE BEAM PATH (fire(): every Concord beam:
##                 the drones' probes, the Vrask lock, the Sentinels' sweeps,
##                 the Final Harvest's eye, phase 2's bosses), the reflection
##                 (Orb Shields, Warder / Bishop barriers) and the prism split.
##   abduction   — Abduction: THE LIFT (lift(): every abduction: the saucers,
##                 phase 2's Harvester, the Final Harvest), the hold through
##                 SummonedUnit.held_until (carry(), the one place that moves a
##                 lifted summon), the rescue, the summon taken, the cap.
##   terraforming — Terraforming: THE GROUND (the pods, the cells, seed() for
##                 phase 2), the heal on live turf (CombatResolver.heal_enemy()),
##                 the burn (burn(), from the ONE check burns_ground()).
##   harvest     — FinalHarvest: the shared Act IX Reckoning (RECKONING
##                 "final_harvest"): the mothership's eye, the cap lifted.
##   acid        — AcidPools (Act IX phase 2, the Crash Site): THE ACID PATH
##                 (lob(): the Acid Spitter's lobs, the Hive Mother's acid
##                 rain): arcing globs that leave burning puddles hurting
##                 summons and the necromancer, never enemies.
## Hooks for the future counter-passives (exactly 1 / false today):
## mirror_reflect_mult(), mirror_taken_mult() (Mirror Bones),
## anchored_hold_mult(), anchored_breaks() (Anchored).
## Stepped by Game after the enemies (and the City's rules) and before the
## obstacle push-out, so a pod landed this tick is pushed out of any obstacle
## before it is drawn; a lifted summon is set under its saucer here (the
## push-out may nudge it; it is set again next tick).
## Determinism: game time and the seeded gameplay RNG only (the pods' landing
## points and the eye's angle), and only while it exists (Act IX, or a forced
## Concord kind).
class_name ConcordRules
extends Node2D

## Owning run.
var game: Game
## True on an Act IX stage (STAGE "concord"): the pods and the Final Harvest
## may run; false when a forced Concord kind made the rules elsewhere.
var enabled: bool = false
## The beams (child node: drawn above the units).
var beams: ConcordBeams
## Abduction (the lifts and holds; draws through the beams' node).
var abduction: Abduction
## Terraforming (child node: drawn on the ground).
var terraforming: Terraforming
## The Final Harvest (child node: the sky overlay).
var harvest: FinalHarvest
## Live Star-Seers (prism kinds) the beams split on, in activation order
## (ConcordKit registers / unregisters them).
var prisms: Array[Enemy] = []
## Concord kind -> game time (s) of its first activation this run (the
## autotest's "concord kinds" line).
var first_seen: Dictionary = {}
## Saucers activated since the Final Harvest began (its report line).
var harvest_saucers: int = 0
## Sound event -> game time (s) it last played (rate limits).
var _sound_at: Dictionary = {}


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "ConcordRules"
	enabled = bool(p_game.stage_def.get("concord", false))
	terraforming = Terraforming.new(p_game, enabled)
	add_child(terraforming)
	beams = ConcordBeams.new(p_game)
	add_child(beams)
	abduction = Abduction.new(p_game)
	harvest = FinalHarvest.new(p_game, enabled)
	add_child(harvest)
	# --- Act IX: the Crash Site --- the acid puddles (on the ground, z -1).
	acid = AcidPools.new(p_game)
	add_child(acid)


## Per-tick update (Game, after the enemies, before the obstacle push-out): the
## Final Harvest's clock, the beams, the lifted summons, the ground.
func step(delta: float) -> void:
	harvest.step(delta)
	beams.step(delta)
	abduction.step(delta)
	terraforming.step(delta)
	acid.step(delta)  # Act IX, the Crash Site: lobs land, puddles burn.


# =====================================================================================
# Hooks (CombatResolver, kits)
# =====================================================================================

## THE ONE BURN CHECK (brief: "Nothing else burns the ground, and summons never
## do"): true when damage tagged `source` burns the alien ground, i.e. it is
## one of the necromancer's SPELLS (HundredShadowsData.is_spell_source(), the
## one spell list).
static func burns_ground(source: String) -> bool:
	return HundredShadowsData.is_spell_source(source)


## Called ONCE at the end of CombatResolver.damage_enemy() (only while
## Game.concord exists) for a hit on `e` tagged `source` that dealt damage: a
## spell hit burns every cell within burn_radius of the enemy it hit.
func on_enemy_hit(e: Enemy, source: String) -> void:
	if burns_ground(source):
		terraforming.burn(e.position, float(terraforming.cfg["burn_radius"]))


## A Concord kind's enemy `e` was activated (ConcordKit.reset()): its first time
## is recorded; a prism joins the split list; a saucer during the Final
## Harvest is counted.
func note_spawn(e: Enemy) -> void:
	if not first_seen.has(e.kind):
		first_seen[e.kind] = game.elapsed
	if bool((e.kit as ConcordKit).d.get("prism", false)) and not prisms.has(e):
		prisms.append(e)
	if e.kind == ConcordEnemyData.SAUCER and harvest.running():
		harvest_saucers += 1


## A Concord kind's enemy `e` left the field (ConcordKit.on_deactivate()): it
## leaves the prism list; a saucer drops what it holds (Abduction.rescue()).
func note_gone(e: Enemy) -> void:
	prisms.erase(e)
	abduction.release_all(e)


## Plays the sound of Concord event `event` (ConcordRulesData.SOUNDS) at `pos`,
## at most once every `gap` game seconds.
func play_sound(event: String, pos: Vector2 = Vector2.INF, gap: float = 0.0) -> void:
	if gap > 0.0:
		if game.elapsed - float(_sound_at.get(event, -INF)) < gap:
			return
		_sound_at[event] = game.elapsed
	var id := String(ConcordRulesData.SOUNDS.get(event, ""))
	if id != "":
		Sfx.play(id, pos)


## The autotest autopilot's push away from every live Concord telegraph at
## `p`: the aiming lines and live beams (ConcordBeams), the acid puddles and
## landing circles (AcidPools; Act IX, the Crash Site). The kits' own
## telegraphs (a Burrower's mound) are read through their kits'
## danger_push(), the Hive Mother's through her Boss.danger_push().
func danger_push(p: Vector2) -> Vector2:
	return beams.danger_push(p) + acid.danger_push(p)


# =====================================================================================
# Counter-passive hooks (Mirror Bones, Anchored: not built in phase 1)
# =====================================================================================

## MIRROR BONES (hook): x the damage a beam reflected by the bound player's
## Orb Shield or his army's barrier deals (1 + the passive's reflect_damage;
## exactly 1 while the passive does not exist).
func mirror_reflect_mult() -> float:
	return 1.0 + game.abilities.passive_value(ConcordRulesData.MIRROR_BONES, ConcordRulesData.MIRROR_REFLECT_KEY)


## MIRROR BONES (hook): the share of a beam's hit summon `u` takes (1 - the
## passive's beam_reduction of the player who owns it; co-op: its army's
## slot). Exactly 1 while the passive does not exist.
func mirror_taken_mult(u: SummonedUnit) -> float:
	var ab := game.abilities  # The bound player's passives.
	if game.coop != null and u != null:
		for s in game.coop.slots:
			if s.horde == u.director:
				ab = s.abilities
				break
	return clampf(1.0 - ab.passive_value(ConcordRulesData.MIRROR_BONES, ConcordRulesData.MIRROR_TAKEN_KEY), 0.0, 1.0)


## ANCHORED (hook): x the hold of an abduction of summon `u` (1 - the passive's
## hold_cut of the player who owns it). Exactly 1 while the passive does not
## exist.
func anchored_hold_mult(u: SummonedUnit) -> float:
	var ab := game.abilities  # The bound player's passives.
	if game.coop != null and u != null:
		for s in game.coop.slots:
			if s.horde == u.director:
				ab = s.abilities
				break
	return clampf(1.0 - ab.passive_value(ConcordRulesData.ANCHORED, ConcordRulesData.ANCHORED_KEY), 0.0, 1.0)


## ANCHORED (hook): true when damage to a saucer breaks its hold on summon `u`
## (the passive owned by the player whose army `u` is). Always false while the
## passive does not exist.
func anchored_breaks(u: SummonedUnit) -> bool:
	return anchored_hold_mult(u) < 1.0


# --- Act IX: the Crash Site ---
## The acid puddles (child node: drawn on the ground): THE acid path (see the header).
var acid: AcidPools
# --- Act IX: the Proving Moon ---
# LOW GRAVITY (GDD §15.0 "The Proving Moon (Act IX phase 2)"; owner-approved
# proposal: "knockback goes twice as far for everyone, both armies, and leaps
# are longer (one value in the stage data, read by the existing knockback
# code)"). THE ONE ACCESSOR of the STAGE key "gravity" (the Proving Moon's
# 2.0; 1.0 on every other stage, and when a Concord kind made these rules
# elsewhere). Read only through game.concord, so nothing reads it while
# game.concord is null (Acts I to VIII). Its reads, each a multiply or a
# divide by exactly 1.0 off the moon:
#   * Enemy._tick_timers(): the one enemy knockback decay
#     (EnemyData.KNOCKBACK_DECAY) is divided by it (linear decay: twice the
#     distance);
#   * Enemy._rush_move(): the shared rush's charge_knockback shove on a summon
#     is multiplied by it;
#   * the Proving Moon's own kits (WarbeastKit, BossVraskTal): their shoves on
#     summons and the necromancer and their leaps' reach are multiplied by it.
# Grave Step is a shadow step, not a leap: it never reads it.

## The stage's low-gravity multiplier (STAGE "gravity"; 1.0 when absent), read
## once at creation (a run never changes stage).
var _gravity: float = -1.0


## THE LOW-GRAVITY MULTIPLIER (see the block header): the STAGE's "gravity"
## (2.0 on the Proving Moon), 1.0 when the stage has none.
func gravity() -> float:
	if _gravity < 0.0:
		_gravity = maxf(0.01, float(game.stage_def.get("gravity", 1.0)))
	return _gravity
