## GhostBosunKit — the kit of THE GHOST BOSUN, the Maelstrom's miniboss
## (MaelstromEnemyData "ghost_bosun"; Act X; GDD §15.0 "The Maelstrom (Act X
## phase 2)"; owner-approved proposal: "Miniboss: The Ghost Bosun (male), whose
## whistle summons a spectral longboat"). A drowned bosun who comes over the
## rail from the sea (MaelstromDirector.start_event(): EnemyDirector.spawn_at(),
## not a boat) and walks at the necromancer with the shared melee AI. He
## registers as the miniboss (EnemyDirector.set_miniboss(): the HUD bar; his
## chest drops where he falls, ChestManager). His special, THE WHISTLE: every
## whistle "every" s (the first after "first") he stands "windup" s with the
## whistle at his lips, then a SPECTRAL LONGBOAT comes alongside the rail
## nearest the necromancer's side with "crew" drowned crewmen ("gunners" of them
## Ghost Gunners): BoardingParty.launch_boat(), the one boarding path (through
## MaelstromDirector.bosun_whistle()). A miniboss never drowns (DeckBounds).
## Determinism: no RNG (the first whistle staggered by the think slot).
## Stats: ghost_bosun_whistles, ghost_bosun_boats (MaelstromDirector).
class_name GhostBosunKit
extends CorsairKit

## Phase: the whistle at his lips (he stands).
const WHISTLE: int = 1

## Seconds until his next whistle.
var _cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	var w: Dictionary = d.get("whistle", {})
	_cd = first_cd(e, float(w.get("first", 3.0)))
	e.game.enemies.set_miniboss(e)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


## The whistle's clock; while it sounds he stands (true owns the tick).
func physics(e: Enemy, delta: float) -> bool:
	if in_water:
		return super.physics(e, delta)
	var w: Dictionary = d.get("whistle", {})
	if phase == WHISTLE:
		phase_time += delta
		hold(e)
		if phase_time >= float(w.get("windup", 1.0)):
			var md := e.game.enemies.maelstrom
			if md != null:
				md.bosun_whistle(e, w)
			e.game.stat_add("ghost_bosun_whistles", 1.0)
			_cd = float(w.get("every", 13.0))
			set_phase(e, IDLE)
		return true
	_cd -= delta
	if _cd <= 0.0:
		set_phase(e, WHISTLE)
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		if e.game.corsair != null:
			e.game.corsair.play_sound("ghost_whistle", e.position, 0.5)
		return true
	return false


## While he whistles: a pale ring of sound round him (visual only).
func draw_under(e: Enemy) -> void:
	SpriteBank.draw_disc(e, Vector2.ZERO, e.radius * 1.4, Color(Palette.CORSAIR_SPECTRE, 0.18))
	if phase == WHISTLE:
		var w: Dictionary = d.get("whistle", {})
		var k := clampf(phase_time / maxf(float(w.get("windup", 1.0)), 0.01), 0.0, 1.0)
		var ring := CityGlyphs.ring_texture()
		var r := e.radius * (1.5 + 2.0 * k)
		e.draw_texture_rect(ring, Rect2(Vector2(-r, -r), Vector2(r, r) * 2.0), false, Color(Palette.CORSAIR_SPECTRE_LIGHT, 0.7 * (1.0 - k) + 0.2))
