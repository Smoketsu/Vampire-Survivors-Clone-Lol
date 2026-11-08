## CursedCoinKit — the kit of Admiral Marrec's cursed coin (GalleonEnemyData
## "cursed_coin"; Act X, the Black Tide, the Treasure Galleon; GDD §15.0
## "Admiral Isabeau Marrec, the Sea Wolf (Act X)"; owner-approved proposal:
## "Gold Fever: cursed coins that become short barriers round her marines;
## area damage clears them"). A 1 HP STRUCTURE (any hit clears it, so an area
## spell clears a whole scatter): every "pulse" s, while it stands, every
## crewman (a non-boss, non-structure enemy) within "aura" px keeps a barrier
## of "shield" x the enemies' HP scaling through Enemy.holy_shield (the one
## shield path; CombatResolver drains it before HP), renewed for 2 pulses.
## The Admiral's own cut (each standing coin near her) is BossMarrec's
## (damage_taken_mult(), reads near()). It fades after "life" s.
## Determinism: no RNG. Stats: coins_dropped (BossMarrec), coins_cleared,
## coins_faded, coin_shields.
class_name CursedCoinKit
extends CorsairKit

## Seconds until its next barrier pulse.
var _pulse_cd: float = 0.0
## Game time (s) it fades.
var _fade_at: float = 0.0
## Scratch query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_pulse_cd = 0.0
	_fade_at = e.game.elapsed + float(d.get("life", 14.0))
	e.is_objective = true  # It lies where it fell until cleared or faded (never recycled).


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	e.game.stat_add("coins_cleared", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	hold(e)
	if g.elapsed >= _fade_at:
		g.stat_add("coins_faded", 1.0)
		g.enemies.despawn(e)
		return true
	_pulse_cd -= delta
	if _pulse_cd > 0.0:
		return true
	var pulse := float(d.get("pulse", 1.0))
	_pulse_cd = pulse
	var shield := float(d.get("shield", 18.0)) * g.enemies.hp_mult
	var r := float(d.get("aura", 80.0))
	g.enemy_grid.query(e.position, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	for o: Enemy in _buf:
		if not o.active or o == e or o.is_boss or o.is_structure or o.position.distance_to(e.position) > r + o.radius:
			continue
		o.holy_shield = maxf(o.holy_shield, shield)
		o.holy_shield_time = maxf(o.holy_shield_time, pulse * 2.0)
		g.stat_add("coin_shields", 1.0)
	return true


## True while coin `e` stands within its aura of `p` (BossMarrec's cut).
func near(e: Enemy, p: Vector2) -> bool:
	return e.position.distance_to(p) <= float(d.get("aura", 80.0))


## The coin itself: a cursed gold piece with a sickly lantern glow (code drawn:
## no coin sprite; textures only).
func draws_body(_e: Enemy) -> bool:
	return true


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var t := e.game.elapsed
	var glow := 0.5 + 0.5 * absf(sin(t * 4.0 + float(e.think_slot)))
	SpriteBank.draw_disc(ci, Vector2.ZERO, e.radius * 2.2, Color(Palette.CORSAIR_LANTERN, 0.18 + 0.15 * glow))
	SpriteBank.draw_disc(ci, Vector2.ZERO, e.radius + 1.0, Palette.CORSAIR_INK)
	SpriteBank.draw_disc(ci, Vector2.ZERO, e.radius, Palette.CORSAIR_BRASS_DARK if e.flash <= 0.0 else Color.WHITE)
	SpriteBank.draw_disc(ci, Vector2(-1.0, -1.0), e.radius * 0.65, Palette.CORSAIR_BRASS)
	ci.draw_rect(Rect2(Vector2(-0.5, -e.radius * 0.5), Vector2(1.0, e.radius)), Palette.CORSAIR_BRASS_LIGHT)


## Its aura on the deck: a faint ring the crew inside it keep their barriers in.
func draw_under(e: Enemy) -> void:
	var r := float(d.get("aura", 80.0))
	e.draw_texture_rect(CityGlyphs.ring_texture(), Rect2(Vector2(-r, -r), Vector2(r, r) * 2.0), false, Color(Palette.CORSAIR_BRASS, 0.25))
