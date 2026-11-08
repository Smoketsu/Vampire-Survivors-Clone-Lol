## NorseRules — THE HALL OF THE SLAIN's shared rules (the Norse act,
## temporarily Act XI, final slot VI; GDD §15.0 "The Hall of the Slain
## foundation (phase 1)", "The Long Winter", "Berserkergang", "Rune-Stones" and
## "Ragnarök"), run as
## `Game.norse`. Null on every other act (created in Game._ready() only for a
## stage whose STAGE has "norse": true), except that a Norse kind forced onto
## any other stage with --spawn= creates it on its first activation through
## Game.norse_rules() (NorseKit.reset()), so a kind works anywhere (as the Act
## III to IX kinds do); there the cold, the braziers, the timeline's
## Rune-Stones and Ragnarök stay off (`enabled` false) and only what the kinds
## themselves use (the fury, a seer's carving of a stone a --spawn=rune_stone
## raised) runs.
## Owns ONE path per rule:
##   winter    — LongWinter: THE LONG WINTER (owner decision Nov 7, 2026,
##               replacing the proposal's Choosing): the cold level, the
##               braziers (place()), the slow and frostbite out of warmth
##               (TerrainSlow, CombatResolver.damage_unit()), the douse and the
##               relight, the frost vignette. Norse kinds are immune.
##   (fury)    — BERSERKERGANG: on_enemy_hit() (called ONCE at the end of
##               CombatResolver.damage_enemy()) puts a wounded Norse warrior
##               into the fury through enter_fury(), the one writer of
##               Enemy.berserk (the one enemy stat; Enemy.hit_mult() and
##               Enemy.physics_step() read it, Enemy.apply_slow() and
##               CombatResolver.stun_enemy() / freeze_enemy() refuse it).
##   stones    — RuneStones: THE STONES (raise_stone(), the timeline event
##               "rune_stone"), their ward (ward_mult(), read by
##               NorseKit.taken_mult()), their horn, the capture, the seers'
##               re-carving.
##   ragnarok  — Ragnarok: the shared Reckoning (RECKONING "ragnarok").
## Also: the draugr's cold touch on a summon it strikes (on_unit_struck(),
## called once from CombatResolver.damage_unit() with the attacker, through
## CombatResolver.chill_unit(), the one enemy slow path on summons).
## Summons never get act-only rules: every rule here acts on enemies, the
## stones and the necromancer's standing; a stone never buffs the army.
## A further rule slots in the same way: its own child node created in
## _init() and stepped in step(), its numbers in NorseRulesData, its report
## line in NorseReport.
## Stepped by Game after the enemies (and the Concord's rules) and before the
## obstacle push-out.
## Determinism: game time and the seeded gameplay RNG only (where the braziers
## and the stones stand, a horn's squad), and only while it exists.
class_name NorseRules
extends Node2D

## Owning run.
var game: Game
## True on a Norse stage (STAGE "norse"): the timeline's stones and Ragnarök
## may run; false when a forced Norse kind made the rules elsewhere.
var enabled: bool = false
## The Long Winter (child node: the braziers, their rings, the frost).
var winter: LongWinter
## The Rune-Stones (child node: the stones, their rings).
var stones: RuneStones
## Ragnarök (child node: the dark red sky).
var ragnarok: Ragnarok
## Norse kind -> game time (s) of its first activation this run (the
## autotest's "norse kinds" line).
var first_seen: Dictionary = {}
## Warriors that went berserk this run (wounded into it; berserkers born in it
## are not counted).
var furies: int = 0
## Sound event -> game time (s) it last played (rate limits).
var _sound_at: Dictionary = {}


## Builds the rules for `p_game` (call before add_child; Game does both).
func _init(p_game: Game) -> void:
	game = p_game
	name = "NorseRules"
	enabled = bool(p_game.stage_def.get("norse", false))
	winter = LongWinter.new(p_game, enabled)
	add_child(winter)
	stones = RuneStones.new(p_game)
	add_child(stones)
	ragnarok = Ragnarok.new(p_game, enabled)
	add_child(ragnarok)


## Per-tick update (Game, after the enemies, before the obstacle push-out):
## Ragnarök's clock, the Long Winter, the stones.
func step(delta: float) -> void:
	ragnarok.step(delta)
	winter.step(delta)
	stones.step(delta)


# =====================================================================================
# The one tests
# =====================================================================================

## True for a Norse enemy whose row is a WARRIOR of the hall ("warrior":
## Berserkergang drives him).
static func is_warrior(e: Enemy) -> bool:
	return e != null and e.kit is NorseKit and (e.kit as NorseKit).is_warrior()


# =====================================================================================
# Hooks (CombatResolver, kits)
# =====================================================================================

## Called ONCE at the end of CombatResolver.damage_enemy() (only while
## Game.norse exists) for a hit on `e` that dealt damage: BERSERKERGANG, a
## living Norse warrior below the threshold share of its max HP goes berserk
## (for good).
func on_enemy_hit(e: Enemy, _source: String) -> void:
	if e.berserk or not e.active or e.hp <= 0.0 or not is_warrior(e):
		return
	if e.hp < e.max_hp * float(NorseRulesData.BERSERK["threshold"]):
		enter_fury(e, true)


## THE ONE WRITER of Enemy.berserk: `e` goes berserk (+speed and damage, slows
## and stuns no longer hold: the running ones end now). `wounded` false for a
## berserker born in it (not counted as a fury).
func enter_fury(e: Enemy, wounded: bool) -> void:
	if e.berserk:
		return
	e.berserk = true
	e.slow_timer = 0.0
	e.slow_factor = 0.0
	e.stun_timer = 0.0
	e.freeze_timer = 0.0
	e.queue_redraw()
	if wounded:
		furies += 1
		game.stat_add("norse_furies", 1.0)
		game.stat_add("norse_fury_" + e.kind, 1.0)
		play_sound("berserk", e.position, 1.5)


## Called ONCE from CombatResolver.damage_unit() (only while Game.norse
## exists) after enemy `by` struck summon `u` with a hit tagged `source` that
## dealt `dealt` HP: a draugr's own blow (its kind's tag) chills the summon
## (CombatResolver.chill_unit(), the one enemy slow path on summons).
func on_unit_struck(u: SummonedUnit, by: Enemy, source: String, _dealt: float) -> void:
	if not by.active or source != by.kind or not (by.kit is NorseKit):
		return
	var k := by.kit as NorseKit
	var f := float(k.d.get("chill_slow", 0.0))
	if f > 0.0 and u.active:
		if game.combat.chill_unit(u, f, float(k.d.get("chill_time", 1.5)), by.kind) > 0.0:
			game.stat_add("draugr_chills", 1.0)


## A Norse kind's enemy `e` was activated (NorseKit.reset()): its first time is
## recorded.
func note_spawn(e: Enemy) -> void:
	if not first_seen.has(e.kind):
		first_seen[e.kind] = game.elapsed


## Plays the sound of Norse event `event` (NorseRulesData.SOUNDS) at `pos`, at
## most once every `gap` game seconds.
func play_sound(event: String, pos: Vector2 = Vector2.INF, gap: float = 0.0) -> void:
	if gap > 0.0:
		if game.elapsed - float(_sound_at.get(event, -INF)) < gap:
			return
		_sound_at[event] = game.elapsed
	var id := String(NorseRulesData.SOUNDS.get(event, ""))
	if id != "":
		Sfx.play(id, pos)


## The autotest autopilot's push away from the act's own telegraphs at `p`
## (the dives and boulders use the shared telegraph circles and the kits'
## danger_push(), which the bot already reads); each stage adds its own.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	# --- Act XI (temporary): Vigrid --- out of the burning ground (the
	# Fire-Giant of the south's tracks, Ragnarok's rings of fire).
	if game.enemies.vigrid != null:
		push += game.enemies.vigrid.danger_push(p)
	return push


## Autotest bot (the one cold behaviour): a brazier to warm up at or relight
## within `reach` px of `p`, or Vector2.INF (LongWinter.bot_point()).
func warm_point(p: Vector2, reach: float) -> Vector2:
	return winter.bot_point(p, reach)


## Autotest bot (the one stone-taking behaviour): the nearest stone the hall
## holds within `reach` px of `p`, or Vector2.INF (RuneStones.seek_point()).
func stone_point(p: Vector2, reach: float) -> Vector2:
	return stones.seek_point(p, reach)
