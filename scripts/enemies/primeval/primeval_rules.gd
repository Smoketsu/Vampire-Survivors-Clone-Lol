## PrimevalRules — the Age of Titans' shared rules (temporary Act XIV, final
## slot XIV; GDD §15.0 "The Age of Titans foundation (phase 1)", "Packs",
## "Herds", "Scavengers" and "The Stampede of Ash"), run as `Game.primeval`.
## Null on every other act (created in Game._ready() only for a stage whose
## STAGE has "primeval": true), except that a Titans kind forced onto any other
## stage with --spawn= creates it on its first activation through
## Game.primeval_rules() (PrimevalKit.reset()), so a kind works anywhere; there
## the clocks stay off (`enabled` false: no herds of their own, no Stampede of
## Ash) and only what the kind itself uses runs (its pack, its herd, its dives).
## Owns ONE path per rule:
##   packs       — PackBrain: THE PACKS (steer(), the one steering call of a
##                 pack kind's kit; the alpha's death breaks the pack).
##   herds       — Herds: THE HERDS (the neutral beasts, their stampedes, the
##                 trample, the shelter, the Fossil Giants).
##   scavengers  — Scavengers: THE THEFTS (the dive clock over the crystal
##                 pool; snatch, drop, nest).
##   ash         — StampedeOfAsh: the Reckoning of the first two stages
##                 (RECKONING "stampede_of_ash").
## It also draws every world-space telegraph of the act on one layer (the
## stampedes' dust lines and fronts, the dives' shadows, the bombs; rects and
## disc textures only, redrawn only while one shows).
## Hooks for the future counter-passives (exactly neutral today):
## hoarders_bones_reach() (Hoarder's Bones: the safe radius grows) and
## thick_marrow_mult() (Thick Marrow: summons take less from the trample and
## the bombs); phase 2 builds the passives.
## Stepped by Game after the enemies (and the Host's rules) and before the
## obstacle push-out, so a summon the trample threw is put back out of any
## obstacle before it is drawn.
## Determinism: game time, pure hashes and the seeded gameplay RNG (the herds'
## and bombs' angles), and only while it exists (this act, or a forced Titans
## kind).
class_name PrimevalRules
extends Node2D

## Owning run.
var game: Game
## True on a Titans stage (STAGE "primeval"): the clocks may run; false when a
## forced Titans kind made the rules elsewhere.
var enabled: bool = false
## Packs (the pack predators' hunt).
var packs: PackBrain
## Herds (the neutral giants).
var herds: Herds
## Scavengers (the Skyraiders' thefts).
var scavengers: Scavengers
## The Stampede of Ash (the Reckoning).
var ash: StampedeOfAsh
## Titans kind -> game time (s) of its first activation this run (the
## autotest's "primeval kinds" line).
var first_seen: Dictionary = {}
## Sound event -> game time (s) it last played (rate limits).
var _sound_at: Dictionary = {}
## True when this build draws (never headless).
var _draws: bool = false
## True while the last redraw showed a telegraph (one more redraw clears it).
var _drawn_any: bool = false


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "PrimevalRules"
	z_index = 14  # Over the units, as the Host's Light.
	z_as_relative = false
	enabled = bool(p_game.stage_def.get("primeval", false))
	packs = PackBrain.new(p_game)
	herds = Herds.new(p_game, enabled)
	scavengers = Scavengers.new(p_game)
	ash = StampedeOfAsh.new(p_game, enabled)
	_draws = DisplayServer.get_name() != "headless"


## Per-tick update (Game, after the enemies, before the obstacle push-out):
## the Stampede of Ash's clock, the packs, the herds, the thefts.
func step(delta: float) -> void:
	ash.step(delta)
	packs.step(delta)
	herds.step(delta)
	scavengers.step(delta)
	if _draws:
		var now_shows := herds.showing() or scavengers.showing() or ash.showing()  # A telegraph shows this tick.
		if now_shows or _drawn_any:
			_drawn_any = now_shows
			queue_redraw()


# =====================================================================================
# Hooks (the kits)
# =====================================================================================

## A Titans kind's enemy `e` was activated (PrimevalKit.reset()): its first
## time is recorded, and it joins the rule its row names.
func note_spawn(e: Enemy) -> void:
	if not first_seen.has(e.kind):
		first_seen[e.kind] = game.elapsed
	var d := (e.kit as PrimevalKit).d
	if bool(d.get("pack", false)) and e.kit is RazorclawKit:
		packs.note_spawn(e, e.kit as RazorclawKit)
	if bool(d.get("herd", false)) and e.kit is HerdBeastKit:
		herds.note_spawn(e, e.kit as HerdBeastKit)
	if bool(d.get("scavenger", false)) and e.kit is SkyraiderKit:
		scavengers.note_spawn(e)


## A Titans kind's enemy `e` left the field (PrimevalKit.on_deactivate()).
func note_gone(e: Enemy) -> void:
	var d := (e.kit as PrimevalKit).d
	if bool(d.get("herd", false)):
		herds.note_gone(e)
	if bool(d.get("scavenger", false)):
		scavengers.note_gone(e)


## A Titans kind's enemy `e` was killed (PrimevalKit.on_killed(), before it is
## pooled): an alpha breaks its pack, a herd beast leaves its heavy corpse.
func note_killed(e: Enemy) -> void:
	if e.kit is RazorclawKit:
		packs.on_killed(e, e.kit as RazorclawKit)
	if e.kit is HerdBeastKit:
		herds.on_killed(e)


## Plays the sound of Titans event `event` (PrimevalRulesData.SOUNDS) at `pos`,
## at most once every `gap` game seconds.
func play_sound(event: String, pos: Vector2 = Vector2.INF, gap: float = 0.0) -> void:
	if gap > 0.0:
		if game.elapsed - float(_sound_at.get(event, -INF)) < gap:
			return
		_sound_at[event] = game.elapsed
	var id := String(PrimevalRulesData.SOUNDS.get(event, ""))
	if id != "":
		Sfx.play(id, pos)


## The autotest autopilot's push away from every live Titans telegraph at `p`:
## the stampedes' paths and the bombs.
func danger_push(p: Vector2) -> Vector2:
	return herds.danger_push(p) + ash.danger_push(p)


func _draw() -> void:
	herds.draw(self)
	scavengers.draw(self)
	ash.draw(self)


# =====================================================================================
# Counter-passive hooks (Hoarder's Bones, Thick Marrow: not built in phase 1)
# =====================================================================================

## HOARDER'S BONES (hook): the safe radius (px) the bound player's passive
## gives (proposal: "crystals and drops within 300 px cannot be snatched").
## Exactly 0 while the passive does not exist; Scavengers.safe_radius() reads it.
func hoarders_bones_reach() -> float:
	return game.abilities.passive_value(PrimevalRulesData.HOARDERS_BONES, PrimevalRulesData.HOARDERS_BONES_KEY)


## THICK MARROW (hook): x the trample and the bombs on the bound player's
## summons (1 - the passive's trample_cut; proposal: "summons take less damage
## from trampling, charges and stomps"). Exactly 1 while the passive does not
## exist; Herds._trample() and StampedeOfAsh._land() read it.
func thick_marrow_mult() -> float:
	return clampf(1.0 - game.abilities.passive_value(PrimevalRulesData.THICK_MARROW, PrimevalRulesData.THICK_MARROW_KEY), 0.0, 1.0)
