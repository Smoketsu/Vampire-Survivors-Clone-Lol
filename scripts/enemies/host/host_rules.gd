## HostRules — the Celestial Host's shared rules (temporary Act XIII, final
## slot X; GDD §15.0 "The Celestial Host foundation (phase 1)", "Judgment",
## "Hallowed Light", "Grace" and "The Last Trumpet"), run as `Game.host`. Null
## on every other act (created in Game._ready() only for a stage whose STAGE
## has "host": true), except that a Host kind forced onto any other stage with
## --spawn= creates it on its first activation through Game.host_rules()
## (HostKit.reset()), so a kind works anywhere; there the clocks stay off
## (`enabled` false: no scales, no shafts, no Last Trumpet) and only what the
## kind itself uses (its halo) runs.
## Owns ONE path per rule:
##   judgment — Judgment: THE SCALES (add(): the sins from
##              HordeDirector.raise_corpse() and the replacement timer; the
##              Judges at each third; the Verdict when full; the HUD bar).
##   light    — HallowedLight: THE SHAFTS (the clock, the burn, the heal) and
##              its CloudShade (the shadows).
##   grace    — Grace: THE HALOS (absorbs(), called once from
##              CombatResolver.damage_enemy(); the Dominions' regrowth).
##   trumpet  — LastTrumpet: the act's Reckoning (RECKONING "last_trumpet").
## Hooks for the future counter-passives (exactly 1 today): absolution_mult()
## (Absolution: the scales fill slower) and smoked_glass_mult() (Smoked Glass:
## the Light burns summons for less); phase 2 builds the passives.
## Stepped by Game after the enemies (and the Dynasty's rules) and before the
## obstacle push-out, so a summon a Herald pushed is put back out of any
## obstacle before it is drawn.
## Determinism: game time, pure hashes and the seeded gameplay RNG (the
## Judges' and shafts' angles), and only while it exists (this act, or a forced
## Host kind).
class_name HostRules
extends Node2D

## Owning run.
var game: Game
## True on a Host stage (STAGE "host"): the clocks may run; false when a
## forced Host kind made the rules elsewhere.
var enabled: bool = false
## The scales of Judgment (child node: the Verdict's pillars).
var judgment: Judgment
## Hallowed Light (child node: the shafts; its clouds are a child too).
var light: HallowedLight
## Grace (the halos; no drawing of its own: each halo draws on its angel).
var grace: Grace
## The Last Trumpet (the Reckoning; no drawing of its own).
var trumpet: LastTrumpet
## Live Choir Angels (row group "choir" with a heal), in activation order:
## phase 2's Empyrean reads the count (the Choir widens the light).
var choir: Array[Enemy] = []
## Host kind -> game time (s) of its first activation this run (the
## autotest's "host kinds" line).
var first_seen: Dictionary = {}
## Sound event -> game time (s) it last played (rate limits).
var _sound_at: Dictionary = {}


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "HostRules"
	enabled = bool(p_game.stage_def.get("host", false))
	grace = Grace.new(p_game)
	judgment = Judgment.new(p_game, enabled)
	add_child(judgment)
	light = HallowedLight.new(p_game, enabled)
	add_child(light)
	add_child(light.clouds)
	trumpet = LastTrumpet.new(p_game, enabled)


## Per-tick update (Game, after the enemies, before the obstacle push-out):
## the Last Trumpet's clock, the scales, the Light, the halos.
func step(delta: float) -> void:
	trumpet.step(delta)
	judgment.step(delta)
	light.step(delta)
	grace.step(delta)


# =====================================================================================
# Hooks (CombatResolver, HordeDirector, kits)
# =====================================================================================

## A corpse was raised (HordeDirector.raise_corpse()): a sin on the scales
## (x absolution_mult()).
func on_raise() -> void:
	judgment.on_raise()


## A summon was replaced after it fell (HordeDirector's replacement timer): a
## sin on the scales.
func on_replace() -> void:
	judgment.on_replace()


## A Host kind's enemy `e` was activated (HostKit.reset()): its first time is
## recorded; a halo is counted, a regrower joins Grace's list, a Choir Angel
## the choir.
func note_spawn(e: Enemy) -> void:
	if not first_seen.has(e.kind):
		first_seen[e.kind] = game.elapsed
	var d := (e.kit as HostKit).d
	grace.note_spawn(e, d)
	if e.kind == HostEnemyData.CHOIR_ANGEL and not choir.has(e):
		choir.append(e)


## A Host kind's enemy `e` left the field (HostKit.on_deactivate()).
func note_gone(e: Enemy) -> void:
	grace.note_gone(e)
	choir.erase(e)


## Plays the sound of Host event `event` (HostRulesData.SOUNDS) at `pos`, at
## most once every `gap` game seconds.
func play_sound(event: String, pos: Vector2 = Vector2.INF, gap: float = 0.0) -> void:
	if gap > 0.0:
		if game.elapsed - float(_sound_at.get(event, -INF)) < gap:
			return
		_sound_at[event] = game.elapsed
	var id := String(HostRulesData.SOUNDS.get(event, ""))
	if id != "":
		Sfx.play(id, pos)


## The autotest autopilot's push away from every live Host telegraph at `p`:
## the Verdict's pillars and the shafts.
func danger_push(p: Vector2) -> Vector2:
	return judgment.danger_push(p) + light.danger_push(p)


# =====================================================================================
# Counter-passive hooks (Absolution, Smoked Glass: not built in phase 1)
# =====================================================================================

## ABSOLUTION (hook): x every sin's weight for the bound player (1 - the
## passive's fill_cut; proposal: "the scales fill 30% slower"). Exactly 1
## while the passive does not exist; Judgment.on_raise() / on_replace() read it.
func absolution_mult() -> float:
	return clampf(1.0 - game.abilities.passive_value(HostRulesData.ABSOLUTION, HostRulesData.ABSOLUTION_KEY), 0.0, 1.0)


## SMOKED GLASS (hook): x the Light's burn on the bound player's summons (1 -
## the passive's burn_cut; proposal: "Hallowed Light burns summons for
## half"). Exactly 1 while the passive does not exist; HallowedLight._burn() reads it.
func smoked_glass_mult() -> float:
	return clampf(1.0 - game.abilities.passive_value(HostRulesData.SMOKED_GLASS, HostRulesData.SMOKED_GLASS_KEY), 0.0, 1.0)
