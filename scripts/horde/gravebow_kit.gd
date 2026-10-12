## GravebowKit — the Gravebow's arrows (summon evolution of the Skeletal
## Archer + Unholy Precision, SummonEvolutionData "gravebow"; GDD §4.2 / §6.1
## "Gravebow Company": splitting / piercing arrows and curses). The Gravebow
## is still an ordinary "arrow" summon that holds its ground (owner
## decision); only what its volley releases changes:
##   * every arrow pierces `pierce` enemies (the evolution's "set" overlay)
##     and curses every enemy it hits (CombatResolver.curse_enemy(), the one
##     place the curse is applied and amplifies damage),
##   * every split_every-th volley of a unit fans into split_count arrows
##     (split_fan radians in total): the middle one homes on the target like
##     a normal arrow, the others fly straight and reserve no damage.
## Numbers come from the unit's effective special (SummonEvolutions
## modify_stats() "special_set"), never from constants here. The volley
## counter is per unit (SummonedUnit.evo_volleys), so it is deterministic.
## Stats: gravebow_volleys, gravebow_splits, gravebow_split_arrows,
## gravebow_pierce_hits (ProjectileManager), curses_applied / curse_refreshes
## / curse_bonus_dmg (CombatResolver).
class_name GravebowKit
extends RefCounted


## True if unit `u` fires Gravebow volleys (its special has the split keys).
static func is_gravebow(u: SummonedUnit) -> bool:
	return u.special.has("split_every")


## Releases one Gravebow volley at `u.target` (the caller checked it is
## valid): the aimed arrow, plus the split fan on every split_every-th volley.
static func release_volley(u: SummonedUnit) -> void:
	var game := u.game
	var sp := u.special  # Effective Gravebow numbers.
	u.evo_volleys += 1
	game.stat_add("gravebow_volleys", 1.0)
	var aimed := game.projectiles.fire_friendly(Projectile.Kind.ARROW, u.position, u.target, u.damage, u.projectile_speed, u.pierce, u.dmg_source)
	_curse_arrow(aimed, sp)
	var every := maxi(1, int(sp["split_every"]))  # Volleys per split.
	var n := int(sp["split_count"])  # Arrows in a split volley.
	if u.evo_volleys % every != 0 or n <= 1:
		return
	var heading := (u.target.position - u.position).angle()  # Fan centre (rad).
	var fan := float(sp["split_fan"])  # Total spread (rad).
	var extra := 0  # Side arrows actually fired (the projectile cap may drop some).
	for i in n:
		var t := float(i) / float(n - 1) - 0.5  # -0.5 .. 0.5 across the fan.
		if absf(t) < 0.001:
			continue  # The middle arrow is the aimed one.
		var dir := Vector2.from_angle(heading + t * fan)  # This arrow's heading.
		var p := game.projectiles.fire_friendly_dir(Projectile.Kind.ARROW, u.position, dir, u.damage, u.projectile_speed, u.pierce, u.dmg_source)
		if p != null:
			_curse_arrow(p, sp)
			extra += 1
	game.effects.ring(u.position, u.radius * 1.8, Palette.VIOLET, 0.25)
	game.stat_add("gravebow_splits", 1.0)
	game.stat_add("gravebow_split_arrows", float(extra))


## Loads the curse onto projectile `p` (null when the projectile cap was hit).
static func _curse_arrow(p: Projectile, sp: Dictionary) -> void:
	if p == null:
		return
	p.curse_amp = float(sp["curse_amp"])
	p.curse_time = float(sp["curse_duration"])
	p.queue_redraw()


## Evolution card lines for the Gravebow (`cur` / `nxt`: effective stats
## before / after; empty unless `nxt` carries the Gravebow keys).
static func offer_lines(cur: Dictionary, nxt: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()  # Card lines.
	var sp: Dictionary = nxt.get("special", {})  # Evolved special numbers.
	if not sp.has("split_every"):
		return out
	if int(nxt["pierce"]) != int(cur["pierce"]):
		out.append("Arrows pierce %d -> %d foes" % [int(cur["pierce"]), int(nxt["pierce"])])
	out.append("NEW  Every %s volley splits into %d arrows" % [_ordinal(int(sp["split_every"])), int(sp["split_count"])])
	out.append("NEW  Curse: foes hit take +%d%% damage from your undead for %ss" % [
			int(roundf(float(sp["curse_amp"]) * 100.0)), AbilityManager._fmt(sp["curse_duration"])])
	return out


## "4th"-style ordinal for card text.
static func _ordinal(n: int) -> String:
	var suffix := "th"  # English ordinal suffix.
	if n % 100 < 11 or n % 100 > 13:
		match n % 10:
			1:
				suffix = "st"
			2:
				suffix = "nd"
			3:
				suffix = "rd"
	return "%d%s" % [n, suffix]


## Autotest summary of the Gravebow and its curse.
static func summary_line(st: Dictionary) -> String:
	return "gravebow volleys %d, splits %d (+%d arrows), pierce hits %d, dmg %d | curses applied %d (refreshed %d), curse bonus dmg %d" % [
		int(st.get("gravebow_volleys", 0.0)), int(st.get("gravebow_splits", 0.0)), int(st.get("gravebow_split_arrows", 0.0)),
		int(st.get("gravebow_pierce_hits", 0.0)), int(st.get("dmg_gravebow", 0.0)),
		int(st.get("curses_applied", 0.0)), int(st.get("curse_refreshes", 0.0)), int(st.get("curse_bonus_dmg", 0.0))]
