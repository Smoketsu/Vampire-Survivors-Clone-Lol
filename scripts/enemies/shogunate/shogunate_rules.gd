## ShogunateRules — the Shogunate of the Rising Sun's shared rules (Act V; GDD
## §15.0 "Act V foundation (phase 1)", "The Sun's Course", "The Draw" and "From
## the Shadows"), run as `Game.shogunate`. Null on Acts I to IV (created in
## Game._ready() only for a stage whose STAGE has "shogunate": true), except
## that a Shogunate kind forced onto any other stage with --spawn= creates it on
## its first activation through Game.shogunate_rules() (ShogunateKit.reset()),
## so a kind works anywhere (as the Act III and IV kinds do); there the Sun's
## Course stays day (SunCourse.enabled is false: no darkness, no ambushes).
## Owns ONE path per rule:
##   sun     — SunCourse: THE SUN'S COURSE. One path reading the run clock:
##             phase() (day, dusk, night, the Endless Night), light_at(pos),
##             the night's darkness and lit stone lanterns, the dusk tint, the
##             timeline helper (night kinds only at night), the Paper Lanterns
##             hook (lantern_mult()).
##   draws   — DrawCuts: THE DRAW. Every iaijutsu line (DrawCuts.draw(source,
##             from, dir, opts): a white line for 0.8 s, then one cut hitting
##             every body on it through CombatResolver); the Unbending hook.
##   ambush  — ShadowAmbush: FROM THE SHADOWS. Ambusher squads appear out of
##             obstacle shadows near the necromancer after a smoke puff.
## The Endless Night (the shared Act V Reckoning, RECKONING "endless_night") is
## the Sun's Course's last phase; on_reckoning_spawn() quickens each Reckoning
## enemy minute by minute.
## Stepped by Game after the enemies (and the Pantheon's rules) and before the
## obstacle push-out, so an ambusher that appears this tick is pushed out of
## any obstacle before it is drawn.
## Determinism: only the seeded gameplay RNG, and only while it exists (Act V,
## or a forced Shogunate kind).
class_name ShogunateRules
extends Node2D

## Owning run.
var game: Game
## The Sun's Course (child node: the night's darkness and the dusk tint over the
## units).
var sun: SunCourse
## The Draw (child node: the flashing lines and the cuts above the darkness).
var draws: DrawCuts
## From the Shadows (child node: the smoke puffs above the darkness).
var ambush: ShadowAmbush
## Game time (s) of the last teppo volley sound (one per beat, however many fire).
var _volley_sound_at: float = -INF
## Shogunate kind -> game time (s) of its first activation this run (the
## autotest's "shogunate kinds" line: the night kinds first appear at night).
var first_seen: Dictionary = {}


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "ShogunateRules"
	sun = SunCourse.new(p_game)
	add_child(sun)
	draws = DrawCuts.new(p_game)
	add_child(draws)
	ambush = ShadowAmbush.new(p_game)
	add_child(ambush)


## Per-tick update (Game, after the enemies, before the obstacle push-out): the
## clock and the lanterns, the pending ambushes, then the Draw lines.
func step(delta: float) -> void:
	sun.step(delta)
	ambush.step(delta)
	draws.step(delta)


# =====================================================================================
# Hooks (EnemyDirector, kits)
# =====================================================================================

## A Reckoning enemy `e` just spawned (EnemyDirector): during the Endless Night
## it moves faster for every minute past 0:00 (SunCourse.endless_speed_mult();
## exactly 1 without an Endless Night).
func on_reckoning_spawn(e: Enemy) -> void:
	var m := sun.endless_speed_mult()  # x its move speed.
	if m != 1.0:
		e.move_speed *= m
		game.stat_add("endless_quickened", 1.0)


## A Shogunate kind's enemy `e` was activated (ShogunateKit.reset()): its first
## time is recorded, and a night kind activated by day or at dusk on an Act V
## stage is counted (it should stay 0: the timeline helper keeps them to the
## night; only --spawn= or a phase 2 script could break it).
func note_spawn(e: Enemy, night_kind: bool) -> void:
	if not first_seen.has(e.kind):
		first_seen[e.kind] = game.elapsed
	if night_kind and sun.enabled and not sun.is_night():
		game.stat_add("sun_night_kind_by_day", 1.0)


## The teppo volley's sound: once per shared beat (TeppoKit.fire_ranged()).
func volley_sound(pos: Vector2) -> void:
	if game.elapsed - _volley_sound_at >= ShogunateRulesData.VOLLEY_BEAT * 0.5:
		_volley_sound_at = game.elapsed
		play_sound("teppo_volley", pos)


## Plays the sound of Shogunate event `event` (ShogunateRulesData.SOUNDS) at `pos`.
func play_sound(event: String, pos: Vector2 = Vector2.INF) -> void:
	var id := String(ShogunateRulesData.SOUNDS.get(event, ""))
	if id != "":
		Sfx.play(id, pos)


# =====================================================================================
# Autotest
# =====================================================================================

## Autopilot hint (the autotest bot): a push sideways off every flashing Draw
## line at `p` (the kits' own telegraphs, such as the oni's smash, come through
## CovenantRites.danger_push()).
func danger_push(p: Vector2) -> Vector2:
	return draws.danger_push(p)
