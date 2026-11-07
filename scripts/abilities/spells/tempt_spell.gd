## TemptSpell — the TEMPTATION spell (AbilityData "tempt"; Act VI, the Palace of
## Silk and Ash; GDD §15.0 "Temptation, Unholy Desire, Velvet Chains and the
## Succubus Queen"; owner-approved proposal: "Temptation: charm the strongest
## nearby enemy to fight for you for 6 s"; unlocked by slaying Lilith, offered on
## every stage at the later-item card weight). Every `cooldown` s the `charms`
## strongest foes (the most HP) within `range` px of the necromancer are charmed
## for `charm_time` s through THE one Enthrall path (HordeDirector.enthrall_foe():
## never a boss, miniboss, structure, objective or Reckoning foe): each fights
## for him as a thrall hitting for `damage`, then goes back to its side (a thrall
## slain while charmed takes its foe with it: XP and a kill). A spell's effect
## on enemies: it never uses the summon charm path (the Inferno's Temptation).
## Evolved into Unholy Desire (EvolutionData "unholy_desire", detected by the
## "desire" key): more and longer charms, and every charm that ends (or thrall
## that falls) bursts: `desire` x its damage to every foe within
## TemptData.BURST_RADIUS px (source TemptData.BURST_SOURCE).
## Velvet Chains (its paired passive) lengthens the charms and hardens the
## thralls' blows through AbilityManager.apply_spell_mods() (the rows' keys).
## The Succubus Queen's innate Heartbreaker (CharacterData "tempt_heartbreak";
## 0 for every other character): a foe whose charm ends loses that share of its
## max HP (Enthrall). Determinism: no RNG; targets ordered by HP, ties in the
## spatial hash's order. Stats: tempt_casts, tempt_charmed (Enthrall's
## enthrall_* counters).
class_name TemptSpell
extends NecroSpell

## Seconds until the next cast.
var _timer: float = 1.5
## Candidate [hp, enemy] pairs of a cast.
var _cands: Array = []
## Kisses being drawn from the necromancer to a fresh thrall: [world position, game time].
var _fx: Array = []


## Casts on cooldown.
func step(delta: float, stats: Dictionary) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	if not _fx.is_empty():
		queue_redraw()


## Charms the strongest foes in range. Returns false when nobody was taken.
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position
	var reach := float(stats["range"])
	game.enemy_grid.query(p, reach, _tmp)
	_cands.clear()
	for e: Enemy in _tmp:
		if not Enthrall.can_turn(e) or p.distance_to(e.position) > reach:
			continue
		_cands.append([e.hp, e])
	if _cands.is_empty():
		return false
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var evolved := stats.has("desire")
	var opts := {
		"source": TemptData.EVOLVED_SOURCE if evolved else TemptData.SOURCE,
		"damage": float(stats["damage"]),
		"heartbreak": game.character.innate_value(TemptData.HEARTBREAK_KEY),  # The Succubus Queen's Heartbreaker (0 for the others).
		"burst_damage": float(stats["damage"]) * float(stats.get("desire", 0.0)),
	}
	var taken := 0
	for k in mini(int(stats["charms"]), _cands.size()):
		var e: Enemy = _cands[k][1]
		if not e.active:
			continue
		var at := e.position
		if game.horde.enthrall_foe(e, float(stats["charm_time"]), opts) != null:
			_fx.append([at, game.elapsed])
			taken += 1
	if taken > 0:
		game.stat_add("tempt_casts", 1.0)
		game.stat_add("tempt_charmed", float(taken))
		game.player.cast_motion(p)  # Engine motion: the necromancer blows the kiss (visual only).
		Sfx.play("summon_rise", p, 1.2)  # The startup bank (the spell is offered on every stage).
	return taken > 0


## Autotest counters (SilkPalaceReport).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d charmed=%d slain=%d returned=%d heartbreaks=%d bursts=%d burst_hits=%d refused=%d thrall_dmg=%d burst_dmg=%d" % [
		int(st.get("tempt_casts", 0.0)), int(st.get("tempt_charmed", 0.0)), int(st.get("enthrall_slain", 0.0)),
		int(st.get("enthrall_returned", 0.0)), int(st.get("enthrall_heartbreaks", 0.0)), int(st.get("enthrall_bursts", 0.0)),
		int(st.get("enthrall_burst_hits", 0.0)), int(st.get("enthrall_refused", 0.0)),
		int(st.get("dmg_" + TemptData.SOURCE, 0.0) + st.get("dmg_" + TemptData.EVOLVED_SOURCE, 0.0)),
		int(st.get("dmg_" + TemptData.BURST_SOURCE, 0.0))]


## The kiss flying out to a freshly charmed foe (drawing only).
func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	var from := caster_pos() + Vector2(0, -18)
	var i := _fx.size() - 1
	while i >= 0:
		var f: Array = _fx[i]
		var age := now - float(f[1])
		if age > TemptData.CAST_FX_TIME:
			_fx.remove_at(i)
		else:
			var k := age / TemptData.CAST_FX_TIME
			var to: Vector2 = f[0]
			InfernoGlyphs.draw_heart(self, from.lerp(to, k), 4.0, Color(TemptData.HEART_COLOR, 1.0 - 0.5 * k))
		i -= 1
