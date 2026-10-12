## NecroSpell — base class of the newer necromancer spells driven by
## NecroSpellBook (BoneSpear, SoulSiphon, CorpseExplosion, PlagueCloud, and
## the five later ones: DeathMark, BoneWall, SoulChains, Wither, RaiseDead).
## A spell node lives in world space (child of the spell book, which sits at
## the origin), simulates its own pooled pieces (spears, tethers, corpses,
## clouds) in step() and draws them itself in _draw(), so no shared pool or
## projectile code is touched. All damage goes through CombatResolver.
class_name NecroSpell
extends Node2D

## Owning run.
var game: Game
## Reusable spatial-hash query buffer.
var _tmp: Array = []


## Advances the spell by `delta` s with its effective `stats` row
## (AbilityManager.spell_stats(): level or evolution row, all modifiers on).
## Overridden by every spell.
func step(_delta: float, _stats: Dictionary) -> void:
	pass


## Kill hook (NecroSpellBook.on_enemy_killed, from CombatResolver's kill
## path while `e` is still active and in place). Optional override: the
## five later spells use it (Death Mark Risen); the four older spells are
## called directly by the book.
func on_enemy_killed(_e: Enemy) -> void:
	pass


## Called once per physics tick AFTER enemies moved and obstacles were
## resolved (Game._physics_process -> NecroSpellBook.after_physics). Optional
## override: Bone Wall pushes enemies out of its segments here.
func after_physics(_delta: float) -> void:
	pass


## Spell-specific counters for the autotest summary (e.g. "brands=12").
## Optional override: the five later spells report theirs here.
func summary_extra() -> String:
	return ""


## True if `e` is a live enemy whose HP is not already spoken for by damage
## in flight (overkill reservation, Enemy.incoming_damage, GDD §27/§32).
static func is_open_target(e: Enemy) -> bool:
	return e.active and e.hp - e.incoming_damage > 0.0


## Number of live enemies within `r` px of `pos` (their body radius counts),
## ignoring enemies already expected to die.
func count_enemies(pos: Vector2, r: float) -> int:
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, _tmp)
	var n := 0  # Enemies inside.
	for e: Enemy in _tmp:
		if is_open_target(e) and e.position.distance_to(pos) <= r + e.radius:
			n += 1
	return n


## Damages every live enemy within `r` px of `pos` (body radius counts) by
## `dmg`, tagged `source`. Returns how many were hit. Uses its own buffer so
## kills that trigger other spell hooks cannot clobber the loop.
func damage_area(pos: Vector2, r: float, dmg: float, source: String) -> int:
	var hits: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, hits)
	var n := 0  # Enemies hit.
	for e: Enemy in hits:
		if e.active and e.position.distance_to(pos) <= r + e.radius:
			game.combat.damage_enemy(e, dmg, source)
			n += 1
	return n
