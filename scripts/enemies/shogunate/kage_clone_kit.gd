## KageCloneKit — the kit of Kage's SHADOW CLONES (ProvinceEnemyData
## "kage_clone"; Act V, the Burning Province, GDD §15.0 "Kage, Mistress of the
## Hidden Hand (Act V)"; owner-approved proposal: "splits into shadow clones
## (only one is real, revealed by light)"). BossKage spawns them at a split
## (begin()), each one wearing her look; the army cannot tell them from her and
## spends its blows on them. A clone walks and cuts with the shared melee AI.
## LIGHT REVEALS IT: once it stands in light (SunCourse.light_at() at least
## the boss's reveal_light) for reveal_time s it shows as false: it turns
## pale, flickers, can no longer be targeted or struck (Enemy.untargetable)
## and dissolves over clone_fade s, taken off the field without a kill (no XP,
## no drop). An unrevealed clone fades the same way after clone_life s. The
## Sun's Course's light is the one light: the necromancer's own pool, a lit
## stone lantern, and the day (forced onto a day stage every clone is revealed
## at once). Drawn as Kage's sprite in smoke-dark indigo (pale when revealed).
## Determinism: no RNG. Stats: kage_clones_revealed, kage_clones_faded,
## kage_clones_killed.
class_name KageCloneKit
extends ShogunateKit

## Phase: revealed as false, dissolving.
const REVEALED: int = 1
## Tint of an unrevealed clone (Kage in smoke-dark indigo).
const SHADOW_TINT := Color(0.42, 0.42, 0.62, 0.92)
## Tint of a revealed clone (pale, see-through).
const FALSE_TINT := Color(0.85, 0.88, 1.0, 0.55)

## Seconds this clone has left before it fades unrevealed.
var life: float = 12.0
## Light (0..1) that reveals it.
var reveal_light: float = 0.55
## Seconds in light before it shows as false.
var reveal_time: float = 0.4
## Seconds a revealed clone takes to dissolve.
var fade_time: float = 0.6
## Seconds it has stood in light so far (resets in the dark).
var _lit: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	life = 12.0
	_lit = 0.0


## Sets the clone up for its split (BossKage): its life and the light rule.
func begin(p_life: float, p_light: float, p_reveal: float, p_fade: float) -> void:
	life = p_life
	reveal_light = p_light
	reveal_time = p_reveal
	fade_time = p_fade
	_lit = 0.0


## The light test and the fade (see the header). Holds the body while it dissolves.
func physics(e: Enemy, delta: float) -> bool:
	if phase == REVEALED:
		phase_time += delta
		hold(e)
		e.queue_redraw()
		if phase_time >= fade_time:
			e.game.enemies.despawn(e)
		return true
	life -= delta
	if light(e) >= reveal_light:
		_lit += delta
		if _lit >= reveal_time:
			_reveal(e, true)
			return true
	else:
		_lit = 0.0
	if life <= 0.0:
		_reveal(e, false)
		return true
	return false


## The clone shows as false (`by_light`) or simply fades: it can no longer be
## struck and dissolves.
func _reveal(e: Enemy, by_light: bool) -> void:
	e.untargetable = true
	e.game.stat_add("kage_clones_revealed" if by_light else "kage_clones_faded", 1.0)
	if by_light:
		e.game.effects.ring(e.position, e.radius * 2.2, Palette.GOLD, 0.35)
	rules(e).play_sound("smoke_puff", e.position)
	set_phase(e, REVEALED)
	hold(e)


func on_killed(e: Enemy) -> void:
	e.game.stat_add("kage_clones_killed", 1.0)


func is_busy() -> bool:
	return phase == REVEALED


## The clone draws Kage's own sprite (tinted), not a kind of its own.
func draws_body(_e: Enemy) -> bool:
	return true


## Kage's sprite in shadow (pale and fading once revealed); her glyph without art.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var tint := SHADOW_TINT
	if phase == REVEALED:
		var k := clampf(phase_time / maxf(0.01, fade_time), 0.0, 1.0)
		var flick := 0.75 + 0.25 * sin(e.game.elapsed * 40.0)  # Flicker (visual only).
		tint = Color(FALSE_TINT.r, FALSE_TINT.g, FALSE_TINT.b, FALSE_TINT.a * (1.0 - k) * flick)
	if not SpriteBank.draw(ci, KageData.SPRITE, Vector2.ZERO, e.flash > 0.0, tint):
		ProvinceGlyphs.draw_kage(ci, Vector2.ZERO, e.radius, e.flash > 0.0, tint)
