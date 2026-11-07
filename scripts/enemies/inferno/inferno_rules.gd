## InfernoRules — the Inferno's shared rules (Act VI; GDD §15.0 "Act VI
## foundation (phase 1)", "Hell Pits", "Portals" and "Temptation"), run as
## `Game.inferno`. Null on Acts I to V (created in Game._ready() only for a
## stage whose STAGE has "inferno": true), except that an Inferno kind forced
## onto any other stage with --spawn= creates it on its first activation through
## Game.inferno_rules() (InfernoKit.reset()), so a kind works anywhere (as the
## Act III to V kinds do); there the pits and the Last Judgment stay off
## (HellPits / LastJudgment read the STAGE "inferno" key) and only what the
## kind itself uses (Temptation, a portal) runs.
## Owns ONE path per rule:
##   pits       — HellPits: THE HELL PITS. Fixed pits per zone and telegraphed
##                pits that burn anyone standing in them, demons excepted;
##                HellPits.open_pit() for phase 2; the ring's avoid check
##                (avoid_point()); the Salt Circle hook.
##   portals    — DemonPortals: THE PORTALS. demon_portal structures that pour
##                squads, destroyed by damage or sealed for a Soul Ash bounty;
##                DemonPortals.open() and the timeline event "portal".
##   temptation — Temptation: TEMPTATION, reached only through
##                HordeDirector.charm() / break_charms(); the Faithless hook.
##   judgment   — LastJudgment: the shared Act VI Reckoning (RECKONING
##                "last_judgment"): every portal opens at once, the pits open
##                faster, the Adversary's hand.
## Stepped by Game after the enemies (and the Shogunate's rules) and before the
## obstacle push-out, so a squad a portal pours this tick is pushed out of any
## obstacle before it is drawn.
## Determinism: only the seeded gameplay RNG, and only while it exists (Act VI,
## or a forced Inferno kind).
class_name InfernoRules
extends Node2D

## Owning run.
var game: Game
## True on an Act VI stage (STAGE "inferno"): the pits burn and the Last
## Judgment may run; false when a forced Inferno kind made the rules elsewhere.
var enabled: bool = false
## The Hell Pits (child node: the pits on the ground).
var pits: HellPits
## The demon portals (child node: the sealing rings).
var portals: DemonPortals
## Temptation (the charm records).
var temptation: Temptation
## The Last Judgment (child node: the Adversary's hand).
var judgment: LastJudgment
## Inferno kind -> game time (s) of its first activation this run (the
## autotest's "inferno kinds" line).
var first_seen: Dictionary = {}
## Game time (s) of the last pit_burn sound (rate-limited).
var _burn_sound_at: float = -INF


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "InfernoRules"
	enabled = bool(p_game.stage_def.get("inferno", false))
	pits = HellPits.new(p_game)
	add_child(pits)
	portals = DemonPortals.new(p_game)
	add_child(portals)
	temptation = Temptation.new(p_game)
	judgment = LastJudgment.new(p_game)
	add_child(judgment)


## Per-tick update (Game, after the enemies, before the obstacle push-out): the
## Last Judgment's clock, the pits (only on an Act VI stage), the portals, then
## the charms.
func step(delta: float) -> void:
	judgment.step(delta)
	if enabled:
		pits.step(delta)
	portals.step(delta)
	temptation.step(delta)


# =====================================================================================
# Hooks (EnemyDirector, kits)
# =====================================================================================

## An Inferno kind's enemy `e` was activated (InfernoKit.reset()): its first
## time is recorded.
func note_spawn(e: Enemy) -> void:
	if not first_seen.has(e.kind):
		first_seen[e.kind] = game.elapsed


## Plays the sound of Inferno event `event` (InfernoRulesData.SOUNDS) at `pos`;
## pit_burn at most once per BURN_SOUND_GAP s.
func play_sound(event: String, pos: Vector2 = Vector2.INF) -> void:
	if event == "pit_burn":
		if game.elapsed - _burn_sound_at < InfernoRulesData.BURN_SOUND_GAP:
			return
		_burn_sound_at = game.elapsed
	var id := String(InfernoRulesData.SOUNDS.get(event, ""))
	if id != "":
		Sfx.play(id, pos)


# =====================================================================================
# Autotest
# =====================================================================================

## Autopilot hint (the autotest bot): out of the pits and their glowing rims,
## and out of the Adversary's pending grabs (the kits' own telegraphs, such as
## the brute's slam, come through CovenantRites.danger_push()).
func danger_push(p: Vector2) -> Vector2:
	var push := judgment.danger_push(p)
	if enabled:
		push += pits.danger_push(p)
	return push


## The autotest bot's one sealing behaviour: the portal to walk into (its
## centre) within `reach` px of `p`, or Vector2.INF (DemonPortals.seek_point()).
func seal_point(p: Vector2, reach: float) -> Vector2:
	return portals.seek_point(p, reach)
