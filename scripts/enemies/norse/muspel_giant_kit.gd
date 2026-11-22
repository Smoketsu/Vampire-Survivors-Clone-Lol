## MuspelGiantKit — the kit of the FIRE-GIANT OF THE SOUTH, Vigrid's miniboss
## (VigridEnemyData "muspel_giant"; the Hall of the Slain, temporarily Act XI;
## GDD §15.0 "Vigrid, the Last Field (phase 2)"; owner-approved proposal:
## "Miniboss, a Fire-Giant of the south, who leaves burning tracks"). The
## shared fire-giant's kit (FireGiantKit: its STOMP, a telegraphed burning
## stamp that throws the ring back) with two more things:
##   * BURNING TRACKS: every track_every s while he walks (and has moved at
##     least track_min_step px since the last one) he leaves a burning
##     footprint behind him: a fire patch of track_radius px for track_life s
##     through EnemyDirector.province_hazards().add_fire() (THE pooled enemy
##     fire path: it burns the necromancer and the summons every track_tick s,
##     never an enemy; drawn as the shared fire-patch textures);
##   * THE STOMP SETS THE GROUND BURNING: when a stomp lands, a patch of
##     stomp_fire_radius px burns round him for stomp_fire_life s (the same path).
## He registers on the HUD's miniboss bar (EnemyDirector.set_miniboss()); his
## chest is ChestManager's (the miniboss flag). He wears the art pass's
## fire-giant of the south (VigridEnemyData.MUSPEL_SPRITE) with an ember glow
## under him. The burns are fixed when a patch is laid (the time scaling and his
## hit multiplier). No RNG. Stats: muspel_spawned, muspel_tracks,
## muspel_stomp_fires, muspel_kill_time (dmg as player_dmg_from_muspel_tracks /
## summon_dmg_from_muspel_tracks).
class_name MuspelGiantKit
extends FireGiantKit

## Seconds until the next footprint may burn.
var _track_cd: float = 0.0
## Where the last footprint was laid (world px).
var _last_track: Vector2 = Vector2.ZERO
## Game time (s) he came onto the field (the kill time).
var _spawned_at: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_track_cd = float(def.get("track_every", 0.7))
	_last_track = e.position
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("muspel_spawned", 1.0)


func on_deactivate(e: Enemy) -> void:
	if e.hp <= 0.0 and e.game != null:
		e.game.stats["muspel_kill_time"] = e.game.elapsed - _spawned_at
	e.game.enemies.clear_miniboss(e)
	super.on_deactivate(e)


func physics(e: Enemy, delta: float) -> bool:
	e.knockback = Vector2.ZERO  # A miniboss: blows do not shove him.
	var was_stomping := phase == STOMP
	var owned := super.physics(e, delta)
	if was_stomping and phase != STOMP:
		_burn_ground(e, e.position, float(d.get("stomp_fire_radius", 54.0)), float(d.get("stomp_fire_life", 4.0)))
		e.game.stat_add("muspel_stomp_fires", 1.0)
	_track_cd -= delta
	if phase == IDLE and _track_cd <= 0.0 and e.position.distance_to(_last_track) >= float(d.get("track_min_step", 18.0)):
		_track_cd = float(d.get("track_every", 0.7))
		_last_track = e.position
		_burn_ground(e, e.position, float(d.get("track_radius", 24.0)), float(d.get("track_life", 6.0)))
		e.game.stat_add("muspel_tracks", 1.0)
	return owned


## A burning patch at `at` (`r` px, `life` s) through THE pooled enemy fire
## path; its burns are fixed now (the time scaling x his hit multiplier).
func _burn_ground(e: Enemy, at: Vector2, r: float, life: float) -> void:
	var k := hit_scale(e)
	e.game.enemies.province_hazards().add_fire(at, r, life, float(d.get("track_tick", 0.5)),
			float(d.get("track_dmg_player", 1.6)) * k, float(d.get("track_dmg_summon", 2.4)) * k * e.undead_damage_mult,
			0.0, VigridEnemyData.TRACK_SOURCE)


## He wears the fire-giant of the south's art (his kind has no sprite of its own).
func draws_body(_e: Enemy) -> bool:
	return true


## His sprite (walk strip through SpriteBank), else the shared glyph.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	if not SpriteBank.draw(ci, VigridEnemyData.MUSPEL_SPRITE, Vector2.ZERO, e.flash > 0.0, Color(1.08, 0.96, 0.9)):
		Glyphs.draw_enemy(ci, NorseEnemyData.FIRE_GIANT, Vector2.ZERO, e.radius, e.flash > 0.0, true)


## Under the body: an ember glow (and the shared looks).
func draw_under(e: Enemy) -> void:
	var r := e.radius * 2.0  # Glow radius (px).
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r * 0.6), Vector2(r * 2.0, r * 1.2)), false, Color(Palette.NORSE_FIRE, 0.22))
	super.draw_under(e)
