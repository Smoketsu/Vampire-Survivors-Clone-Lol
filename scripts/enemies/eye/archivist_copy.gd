## ArchivistCopy — one of the Archivist's FOOTNOTES (Act II, the Hollow Archive;
## ArchiveEnemyData "archivist_copy", ArchivistData): while she is split, two
## copies stand at the spots she did not take and walk at the necromancer with
## her. A copy is an ordinary enemy to the army (it is targeted, blocked and
## hit like her: the blows are wasted), but it CASTS NO SHADOW and takes no
## damage (damage_taken_mult() is 0; the blows are counted in
## archivist_copy_hits and CombatResolver's dmg_resisted_archivist_copy). It
## never attacks.
## The boss owns her two copies and reuses them: appear() activates one and
## adds it to EnemyDirector.active, vanish() deactivates it, after which the
## director's compaction drops it. A copy is never killed, recycled
## (is_objective) or pooled, so the generic enemy pool never holds one.
class_name ArchivistCopy
extends Enemy

## The Archivist this copy belongs to.
var boss: BossArchivist = null


## Activates the copy at `pos` (think slot `slot`) beside boss `b`.
func appear(g: Game, b: BossArchivist, pos: Vector2, slot: int) -> void:
	boss = b
	if active:
		vanish()
	activate(g, ArchiveEnemyData.COPY, g.enemies.enemy_def(ArchiveEnemyData.COPY), g.arena.free_point(pos, b.radius), 1.0, false, slot)
	is_objective = true  # Never recycled.
	radius = b.radius
	g.enemies.active.append(self)
	g.effects.ring(position, radius * 2.0, ArchivistData.COPY_TINT, 0.4)


## Fades the copy away (EnemyDirector's compaction drops it from `active`).
func vanish() -> void:
	if active:
		deactivate()


## A copy takes no damage: every blow on it is wasted.
func damage_taken_mult(_source: String) -> float:
	game.stat_add("archivist_copy_hits", 1.0)
	return 0.0


## A copy only ever walks at the necromancer (no target choice).
func think() -> void:
	target = game.player
	target_gen = 0
	targeting_player = position.distance_to(game.player.position) < EnemyData.ATTACKING_PLAYER_RADIUS
	targeting_summon = false


## Walks at the necromancer, stopping on contact; it never attacks.
func physics_step(delta: float) -> void:
	_tick_timers(delta)
	var to_p := game.player.position - position
	var d := to_p.length()
	var move := to_p / d if d - radius - game.player.radius > EnemyData.ADVANCE_STOP_GAP and d > 0.001 else Vector2.ZERO
	var spd := move_speed * (1.0 - slow_factor if slow_timer > 0.0 else 1.0)
	if engaged_timer > 0.0:
		spd *= engaged_mult
	velocity = move * spd + sep * spd * EnemyData.SEPARATION_STRENGTH
	position += (velocity + knockback) * delta
	_update_facing()


## Sprite key of its art: the Archivist's (engine-motion pivot).
func motion_sprite_key() -> String:
	return "bosses/archivist"


## Ground layer: nothing (no shadow, no aura).
func _draw_under() -> void:
	pass


## Body layer: her sprite, pale, faintly see-through and with NO shadow.
func _draw_body(ci: CanvasItem) -> void:
	if not ArchiveGlyphs.draw_sprite_unshadowed(ci, "bosses/archivist", Vector2.ZERO, flash > 0.0, ArchivistData.COPY_TINT):
		ArchiveGlyphs.draw_archivist(ci, Vector2.ZERO, radius, flash > 0.0, 0, false)


## Overlay layer: the Stasis / freeze look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)
