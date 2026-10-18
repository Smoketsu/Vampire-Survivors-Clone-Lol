## EyeClaims — CLAIMS, the fight over the dead (GDD §15.0 "Act II: the Ancient
## Eye"; numbers in EyeEnemyData.CLAIM). The Covenant destroyed the
## necromancer's dead; the Ancient Eye steals them. A summon that dies within
## reach of a claimer (an Eye enemy with a claim_radius, such as the Chanter
## leading an Initiate squad, or a cultist a Scribe has marked,
## Enemy.claimer_until) rises at once as a hostile DROWNED THRALL wearing that
## summon's sprite, tinted, for CLAIM.thrall_life s. Killing it returns its soul
## as Dread Rally charge; if it lasts its time out, it slips back to the sea
## (no XP, no charge). The army's replenish timers are untouched: the summon
## died normally and comes back as usual, so nothing is lost for good.
## ONE path: HordeDirector.claim_fallen() calls claim_fallen() for every real
## summon death. Game owns one as `game.claims` only on a stage whose STAGE
## has "claims": true (null elsewhere, so Act I never runs any of this).
## Determinism: no RNG of its own; the claimer search is the enemy spatial hash
## in a fixed order (the nearest claimer wins).
class_name EyeClaims
extends RefCounted

## Owning run.
var game: Game

## Thralls risen right now.
var thralls_alive: int = 0
## Summons claimed this run.
var claims: int = 0
## Thralls killed (their souls returned as Dread Rally charge).
var freed: int = 0
## Thralls that lasted their time out and slipped back.
var expired: int = 0
## Claims refused because CLAIM.max_thralls were already risen.
var refused_cap: int = 0
## Claimed summons by class (class id -> count).
var by_class: Dictionary = {}
## Reusable enemy query buffer.
var _tmp: Array = []


func _init(p_game: Game) -> void:
	game = p_game


## A summon died (HordeDirector.claim_fallen). Raises it as a Thrall when a
## claimer stands close enough. Returns true when it was claimed.
func claim_fallen(u: SummonedUnit) -> bool:
	var c: Dictionary = EyeEnemyData.CLAIM
	if u.is_temporary and not bool(c["temporary_claimable"]):
		return false
	if _claimer_near(u.position) == null:
		return false
	if thralls_alive >= int(c["max_thralls"]):
		refused_cap += 1
		return false
	var e := game.enemies.spawn_at(EyeEnemyData.THRALL, u.position, false)
	if e == null:
		return false
	var row: Dictionary = game.enemies.enemy_def(EyeEnemyData.THRALL)  # Floors of the Thrall's stats.
	e.max_hp = maxf(float(row["max_hp"]), u.max_hp * float(c["thrall_hp_mult"]))
	e.hp = e.max_hp
	e.move_speed = maxf(float(row["move_speed"]), u.move_speed * float(c["thrall_speed_mult"]))
	e.radius = u.radius
	var look := u.glyph_kind if u.glyph_kind != "" else u.unit_class  # The summon's art key (an evolved form has its own).
	e.wears = "summons/" + look
	e.wears_class = look
	e.wear_tint = c["tint"]
	if e.kit is EyeThrallKit:
		(e.kit as EyeThrallKit).start(float(c["thrall_life"]), u.unit_class)
	e.queue_redraw()
	thralls_alive += 1
	claims += 1
	by_class[u.unit_class] = int(by_class.get(u.unit_class, 0)) + 1
	game.stat_add("claims", 1.0)
	game.effects.spawn_ring(u.position, c["rise_color"], "summon_rise")  # Visual only.
	return true


## The nearest enemy within its claim reach of `p`, or null.
func _claimer_near(p: Vector2) -> Enemy:
	var c: Dictionary = EyeEnemyData.CLAIM
	game.enemy_grid.query(p, float(c["query_radius"]), _tmp)
	var best: Enemy = null
	var best_d := INF
	for e: Enemy in _tmp:
		if not e.active:
			continue
		var reach := e.claim_radius  # This enemy's claim reach (px).
		if e.claimer_until > game.elapsed:
			reach = maxf(reach, float(c["curse_radius"]))
		if reach <= 0.0:
			continue
		var d := e.position.distance_to(p)
		if d <= reach and d < best_d:
			best = e
			best_d = d
	return best


## A Thrall was killed: its soul returns as Dread Rally charge.
func on_thrall_killed(_e: Enemy, _cls: String) -> void:
	freed += 1
	game.stat_add("thralls_freed", 1.0)
	game.dread_rally.add_points(float(EyeEnemyData.CLAIM["thrall_rally_points"]))


## A Thrall lasted its time out (it is despawned right after).
func on_thrall_expired(_e: Enemy) -> void:
	expired += 1
	game.stat_add("thralls_expired", 1.0)


## A Thrall left the field (killed, expired or pooled at run end).
func on_thrall_gone() -> void:
	thralls_alive = maxi(0, thralls_alive - 1)


## One-line summary for the autotest.
func summary_line() -> String:
	var parts := PackedStringArray()
	var keys := by_class.keys()
	keys.sort()
	for k: String in keys:
		parts.append("%s %d" % [k, int(by_class[k])])
	return "claims %d | freed %d | expired %d | still risen at the end %d | cap refusals %d | by class: %s" % [
		claims, freed, expired, thralls_alive, refused_cap, ", ".join(parts) if not parts.is_empty() else "none"]
