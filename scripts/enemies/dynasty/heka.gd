## Heka — HEKA, words of power, the third Necropolis Dynasty rule (temporary Act
## XII; GDD §15.0 "Heka"; owner-approved proposal: "A priest writes a glyph on
## a summon (a gold sigil above it): the summon deals less damage and moves
## slower (-20% each). Every 2 s the glyph jumps to an adjacent summon, so on
## the Bone Ring it runs around the circle. Cleanses: a Mender's heal, a
## Warder's ward, or the priest's death (all glyphs from that priest vanish).
## A curse lasts at most 10 s. One path: CombatResolver.curse_unit() (the only
## way a summon is cursed), read by compute_stats() like the other debuffs"),
## owned by Game.dynasty. An enemy effect on a summon: summons get no act rule
## of their own.
## THE GLYPHS (at most HEKA max_glyphs at once):
##   * write(priest, u): THE one call (the Heka Priests; phase 2's Osiris and
##     Sekhmet's Red Wind): the summon is cursed through
##     CombatResolver.curse_unit() (x HEKA mult on its damage and move speed:
##     SummonedUnit.curse(), re-applied by apply_stats() whenever
##     HordeDirector.compute_stats()' numbers land on it);
##   * THE JUMP: every jump_every s (x jump_speed(), 1; Sekhmet's Red Wind may
##     set 2) the glyph leaves its bearer (CombatResolver.lift_curse()) for the
##     nearest other summon within jump_range px that can take one (none
##     there: it stays);
##   * THE END: max_time s after its writing (x Embalmed Bones' hook on the
##     bearer), its bearer's death, its priest's death or leaving the field
##     (on_priest_gone()), or a CLEANSE (cleanse(): a Mender's heal and a
##     Profane Bishop's aura, SummonedUnit / SummonAbilities; a Warder's
##     barrier, SummonAbilities.try_ally_barrier()).
## Drawn: a small sigil over every cursed head (art `dynasty/heka_glyph`, else
## two textures and a few rects in the dull bronze-gold), z 4 over the units;
## nothing drawn headless. Determinism: game time, and the nearest summon (ties
## by the ally grid's order); no RNG. Stats: heka_* (the report's "heka" line).
class_name Heka
extends Node2D

## Sprite key of the sigil (assets/sprites/dynasty/heka_glyph.png).
const SPRITE: String = "dynasty/heka_glyph"

## Owning run.
var game: Game
## The rule's numbers (HEKA with the STAGE's "heka").
var cfg: Dictionary = {}
## Live glyphs: [bearer (SummonedUnit), bearer generation, priest (Enemy, may be
## null), priest generation, game time written, game time of the next jump].
var glyphs: Array = []
## x the jump rate (1; a boss's Red Wind may raise it: set_jump_speed()).
var jump_speed: float = 1.0
## Glyphs written.
var written: int = 0
## Jumps made.
var jumps: int = 0
## Glyphs refused at the cap.
var refused: int = 0
## Glyphs ended, by why: "mender", "warder", "bishop", ... (the cleanser's
## source), "priest" (its death), "expired", "bearer" (the bearer fell).
var ended: Dictionary = {}
## Most glyphs at once.
var peak: int = 0
## Summon-seconds spent cursed.
var cursed_seconds: float = 0.0
## True when this build draws (never headless).
var _draws: bool = false
## Ally query buffer.
var _tmp: Array = []


## Builds Heka for `p_game` (DynastyRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "Heka"
	z_index = 4  # Over the units.
	z_as_relative = false
	cfg = DynastyRulesData.HEKA.duplicate()
	var over: Dictionary = p_game.stage_def.get("heka", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# Public API
# =====================================================================================

## True when summon `u` can take a glyph now: active, on the ground (not
## airborne, flying, spawning, dead or charmed) and not already cursed.
static func can_take(g: Game, u: SummonedUnit) -> bool:
	return u != null and u.active and not u.airborne and not u.flies and not u.charmed \
			and u.state != SummonedUnit.State.SPAWNING and u.state != SummonedUnit.State.DEAD \
			and u.heka_until <= g.elapsed


## THE one call: `priest` (null = a boss's own Heka) writes a glyph on summon
## `u`. False when it was refused (the cap, or `u` cannot take one).
func write(priest: Enemy, u: SummonedUnit) -> bool:
	if glyphs.size() >= int(cfg["max_glyphs"]):
		refused += 1
		game.stat_add("heka_refused", 1.0)
		return false
	if not can_take(game, u):
		return false
	var until := game.elapsed + float(cfg["max_time"]) * game.dynasty.embalmed_shed_mult(u)  # When it fades.
	if not game.combat.curse_unit(u, float(cfg["mult"]), until, "heka"):
		return false
	glyphs.append([u, u.generation, priest, priest.generation if priest != null else 0, game.elapsed,
			game.elapsed + float(cfg["jump_every"]) / jump_speed])
	written += 1
	peak = maxi(peak, glyphs.size())
	game.stat_add("heka_written", 1.0)
	game.effects.pop(u.position + Vector2(0.0, -u.radius - 8.0), Palette.DYN_BRONZE_LIGHT, 8.0)
	game.dynasty.play_sound("heka_write", u.position, 0.3)
	return true


## True while `priest` has a glyph of his own on the field.
func has_glyph_of(priest: Enemy) -> bool:
	for gl in glyphs:
		if gl[2] == priest and int(gl[3]) == priest.generation:
			return true
	return false


## A CLEANSE (a Mender's heal, a Profane Bishop's aura, a Warder's barrier):
## the glyph on summon `u` ends; `by` (the cleanser's source) tags the stats.
## True when one ended.
func cleanse(u: SummonedUnit, by: String) -> bool:
	for i in glyphs.size():
		var gl: Array = glyphs[i]
		if gl[0] == u and int(gl[1]) == u.generation:
			_end(i, by)
			game.effects.pop(u.position + Vector2(0.0, -u.radius - 8.0), Palette.NECRO_GREEN, 10.0)
			game.dynasty.play_sound("heka_cleanse", u.position, 0.3)
			return true
	return false


## The priest `e` left the field (killed, despawned, pooled): every glyph he
## wrote ends at once.
func on_priest_gone(e: Enemy) -> void:
	var i := glyphs.size() - 1
	while i >= 0:
		var gl: Array = glyphs[i]
		if gl[2] == e and int(gl[3]) == e.generation:
			_end(i, "priest")
		i -= 1


## x the jump rate from now on (phase 2: Sekhmet's Red Wind, "the Heka glyph
## spreads at double speed"); 1 = the rule's.
func set_jump_speed(m: float) -> void:
	jump_speed = maxf(m, 0.1)


# =====================================================================================
# Per tick
# =====================================================================================

## Per-tick update (DynastyRules.step()): every glyph's end and jump.
func step(delta: float) -> void:
	var now := game.elapsed
	cursed_seconds += delta * float(glyphs.size())
	var i := glyphs.size() - 1
	while i >= 0:
		var gl: Array = glyphs[i]
		var u: SummonedUnit = gl[0]
		if not u.active or u.generation != int(gl[1]) or u.state == SummonedUnit.State.DEAD:
			_end(i, "bearer")
		elif u.heka_until <= now:
			_end(i, "expired")
		elif now >= float(gl[5]):
			gl[5] = now + float(cfg["jump_every"]) / jump_speed
			_jump(gl)
		i -= 1
	if _draws and (not glyphs.is_empty() or _drawn):
		queue_redraw()


## Moves glyph `gl` to the nearest other summon within jump_range that can
## take one (it stays when there is none); the fade time is kept.
func _jump(gl: Array) -> void:
	var u: SummonedUnit = gl[0]
	var reach := float(cfg["jump_range"])
	game.ally_grid.query(u.position, reach, _tmp)
	var best: SummonedUnit = null
	var best_d := reach
	for o: SummonedUnit in _tmp:
		if o == u or not can_take(game, o):
			continue
		var dd := o.position.distance_to(u.position)
		if dd <= best_d:
			best_d = dd
			best = o
	if best == null:
		game.stat_add("heka_jumps_stuck", 1.0)
		return
	var until := u.heka_until
	game.combat.lift_curse(u)
	if not game.combat.curse_unit(best, float(cfg["mult"]), until, "heka_jump"):
		return
	gl[0] = best
	gl[1] = best.generation
	jumps += 1
	game.stat_add("heka_jumps", 1.0)


## Ends glyph `i` (its bearer's curse is lifted when it still lives); `why`
## tags the stats.
func _end(i: int, why: String) -> void:
	var gl: Array = glyphs[i]
	var u: SummonedUnit = gl[0]
	if u.active and u.generation == int(gl[1]):
		game.combat.lift_curse(u)
	glyphs.remove_at(i)
	ended[why] = int(ended.get(why, 0)) + 1
	game.stat_add("heka_ended_" + why, 1.0)


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## True if the last redraw drew a sigil.
var _drawn: bool = false


## A small sigil over every cursed head.
func _draw() -> void:
	_drawn = false
	var s := float(cfg["sigil_size"])
	for gl in glyphs:
		var u: SummonedUnit = gl[0]
		if not u.active or not u.visible:
			continue
		_drawn = true
		var c := u.position + Vector2(0.0, -u.radius - float(cfg["sigil_rise"]) - s)
		if SpriteBank.draw(self, SPRITE, c, false):
			continue
		draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(s, s), Vector2(s, s) * 2.0), false, Color(Palette.DYN_BRONZE, 0.35))
		draw_texture_rect(SpriteBank.disc(), Rect2(c - Vector2(s, s) * 0.45, Vector2(s, s) * 0.9), false, Palette.DYN_BRONZE_LIGHT)
		draw_rect(Rect2(c + Vector2(-1.0, -s * 0.9), Vector2(2.0, s * 1.8)), Palette.DYN_INK)  # The ankh's stem...
		draw_rect(Rect2(c + Vector2(-s * 0.55, -1.0), Vector2(s * 1.1, 2.0)), Palette.DYN_INK)  # ... and its arms.
