## ConfessorKit — the High Confessor's rites (GDD §7.2 "healing, shielding
## and limited revival"). The Confessor walks at the necromancer like a
## Chaplain (shared "healer" AI, never kites) and keeps its rites going on
## the move:
##   Healing     — the shared Chaplain heal (Enemy._try_heal) on the most
##                 wounded ally within heal_radius (bosses included);
##                 heal_amount grows with the enemy HP scaling at spawn
##                 (set here). An external owner can point any healer at a
##                 target with Enemy.set_heal_override() (Seraphine).
##                 Constructs are never healed.
##   Holy shields — every shield_interval s: an absorb barrier
##                 (Enemy.holy_shield, CombatResolver.damage_enemy()) of
##                 shield_amount x the current enemy HP scaling on up to
##                 shield_targets unshielded allies within shield_radius
##                 (bosses and minibosses first, then elites, then the
##                 nearest); it fades after shield_duration s. Never on
##                 itself or another Confessor, constructs, structures or
##                 the Reckoning.
##   Revival     — owner-approved (GDD §15.0 / open question 35): every
##                 revive_interval s it raises one ordinary soldier that fell
##                 within revive_radius px of it in the last revive_max_age s,
##                 where it fell, after a revive_telegraph s gold pillar
##                 (CovenantRites). Killing the Confessor during the pillar
##                 cancels it. At most revive_max revives per Confessor;
##                 never elites, structures, constructs, bosses, minibosses,
##                 objectives, the Reckoning or a soldier already raised once.
## Stats: high_confessor_heals (Enemy heal_stat), confessor_shields,
## holy_shield_absorbed / holy_shields_broken (CombatResolver),
## confessor_revives_started, confessor_revives, confessor_revives_cancelled.
class_name ConfessorKit
extends CovenantKit

## Seconds until the next round of holy shields.
var shield_cd: float = 0.0
## Seconds until the next revival attempt.
var revive_cd: float = 0.0
## Revivals started by this Confessor (capped at revive_max).
var revives_used: int = 0
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	# Heals grow with the enemy HP scaling it spawned under (max_hp / row HP).
	e.heal_amount = float(d["heal_amount"]) * e.max_hp / maxf(1.0, float(d["max_hp"]))
	shield_cd = first_cd(e, float(d["shield_first"]))
	revive_cd = first_cd(e, float(d["revive_first"]))
	revives_used = 0


## Shields and revival when their timers are ready.
func think(e: Enemy) -> void:
	if shield_cd <= 0.0:
		shield_cd = float(d["shield_interval"])
		_cast_shields(e)
	if revive_cd <= 0.0 and revives_used < int(d["revive_max"]):
		var rites := e.game.enemies.rites
		if rites.has_pending(e):
			return
		if rites.start_revive(e, float(d["revive_radius"]), float(d["revive_max_age"]), float(d["revive_telegraph"]), float(d["revive_hp_fraction"])):
			revives_used += 1
			revive_cd = float(d["revive_interval"])
		else:
			revive_cd = 1.0  # Nobody to raise yet: look again in a second.


func physics(_e: Enemy, delta: float) -> bool:
	shield_cd -= delta
	revive_cd -= delta
	return false


## Holy shields on up to shield_targets allies (see the header).
func _cast_shields(e: Enemy) -> void:
	var g := e.game
	var r := float(d["shield_radius"])  # Search radius (px).
	g.enemy_grid.query(e.position, r, _tmp)
	var picked: Array[Enemy] = []  # Chosen allies, best first.
	var scores: Array[float] = []  # Their scores (same order).
	for o: Enemy in _tmp:
		if o == e or o.kind == e.kind or not o.active or o.is_structure or o.is_reckoning or o.is_construct or o.holy_shield > 0.0:
			continue
		var dist := o.position.distance_to(e.position)
		if dist > r:
			continue
		var s := 1.0 - dist / r  # Nearer is better ...
		if o.is_boss or o.is_miniboss:
			s += 3.0  # ... but the boss and minibosses come first ...
		elif o.is_elite:
			s += 1.5  # ... then elites.
		var at := 0  # Insertion index (descending scores, stable).
		while at < scores.size() and scores[at] >= s:
			at += 1
		picked.insert(at, o)
		scores.insert(at, s)
	var amount := float(d["shield_amount"]) * g.enemies.hp_mult  # Absorb per shield.
	var n := mini(picked.size(), int(d["shield_targets"]))
	for i in n:
		var o := picked[i]
		o.holy_shield = amount
		o.holy_shield_time = float(d["shield_duration"])
		o.queue_redraw()
		g.effects.beam(e.position, o.position, Palette.IVORY)
	if n > 0:
		g.stat_add("confessor_shields", float(n))
		g.effects.ring(e.position, r, Palette.GOLD, 0.3)
		Sfx.play("priest_ward", e.position, 1.3)


## A gold mitre glow while its own revival pillar rises.
func draw_over(e: Enemy) -> void:
	if e.game != null and e.game.enemies.rites.has_pending(e):
		SanctumGlyphs.draw_casting(e, Vector2(0, -e.radius * 2.2), e.radius * 0.8)
