## HostKit — base class of the Celestial Host's kits (temporary Act XIII; GDD
## §15.0 "The Celestial Host foundation (phase 1)"), a CovenantKit plugged
## into the shared Enemy AI like every kit. Kits load by name from
## scripts/enemies/host/<id>_kit.gd (CovenantKits, after the Dynasty's folder;
## an id must not repeat any other folder's). What every Host kind shares:
##   * creating the shared rules on first use (Game.host_rules()), so a Host
##     kind forced onto any stage with --spawn= keeps its halo there (the
##     scales and the Light stay off off the act);
##   * THE HALO (Grace): `halo` (its row's "halo") and `seen`, the kinds of
##     damage it already shrugged off; Grace.absorbs() is the one reader and
##     writer, from CombatResolver.damage_enemy();
##   * drawing the halo: a thin ring of cerulean rects over the head that dims
##     with every kind it shrugged off (visual only; textures and rects).
## Phase 2 kinds extend this class: override physics() for a special and call
## super.reset() / super.on_deactivate() / super.draw_over() when they
## override those. Determinism: no RNG, no instance ids.
class_name HostKit
extends CovenantKit

## Number of rects the code-drawn halo is made of (visual only).
const HALO_SEGMENTS: int = 10

## True when this kind wears a halo (its row's "halo").
var halo: bool = false
## Damage kinds (Grace.damage_kind()) this halo already shrugged off: kind -> true.
var seen: Dictionary = {}
## Game time (s) of the last hit this halo shrugged off (-INF = none yet).
var last_absorb: float = -INF


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	halo = bool(d.get("halo", false))
	seen.clear()
	last_absorb = -INF
	e.game.host_rules().note_spawn(e)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	seen.clear()
	if e.game.host != null:
		e.game.host.note_gone(e)


## The shared rules (created on first use).
static func rules(e: Enemy) -> HostRules:
	return e.game.host_rules()


## The kind's group (row "group"; HostRulesData.GROUPS).
func group() -> String:
	return String(d.get("group", ""))


## The halo over the head: a ring of small cerulean rects, dimmer with every
## kind of damage it already shrugged off (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if not halo:
		return
	var k := float(seen.size())  # Kinds shrugged off.
	var a := clampf(0.95 - 0.16 * k, 0.25, 0.95)  # The halo's light.
	var c := Vector2(0.0, -e.radius * 2.1)  # Over the head.
	var rx := e.radius * 0.8
	var ry := e.radius * 0.28
	for i in HALO_SEGMENTS:
		if k > 0.0 and i % 4 == 1:
			continue  # A cracked halo shows gaps.
		var p := c + Vector2(cos(TAU * float(i) / float(HALO_SEGMENTS)) * rx, sin(TAU * float(i) / float(HALO_SEGMENTS)) * ry)
		ci.draw_rect(Rect2(p - Vector2(1.5, 0.5), Vector2(3.0, 1.0)), Color(Palette.HOST_CERULEAN, a))
