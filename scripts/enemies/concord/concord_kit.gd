## ConcordKit — base class of the Concord of Stars' kits (Act IX; GDD §15.0 "Act
## IX foundation (phase 1)"), a CovenantKit plugged into the shared Enemy AI
## like every kit. Kits load by name from scripts/enemies/concord/<id>_kit.gd
## (CovenantKits, after the Eye's, the Empire's, the Pantheon's, the
## Shogunate's, the Inferno's, the Court's and the City's folders; an id must
## not repeat theirs). What every Concord kind shares:
##   * creating the shared rules on first use (Game.concord_rules()), so a
##     Concord kind forced onto any stage with --spawn= still fires its beams,
##     abducts and heals on turf there (the pods and the Final Harvest stay off
##     off Act IX);
##   * the row flags as helpers: race(), heals_on_turf() (Terraforming),
##     beam_style() (row "beam": BEAMS), abducts() (Abduction), is_flier(),
##     cloak() (row "cloak": the Vrask cloak, VraskHunterKit);
##   * THE BEAM (a row with "beam"): its ranged attack goes through
##     fire_ranged() into ConcordBeams.fire() (THE beam path, never
##     ProjectileManager), aimed at the attack's target; a refusal (the cap)
##     retries after BEAMS retry s. While its beam aims and holds, physics()
##     holds the firer still (the beam leaves its muzzle);
##   * THE SAUCER IN THE AIR (a row with "flies"): taken_mult() applies the
##     Night Wings test (FallenAngelKit.grounded_melee()): a grounded melee
##     summon's blow deals the row's flight_melee_taken (0); everything else
##     lands in full (counted: concord_air_whiffs, concord_air_hits); a hit on
##     an abducting saucer tells Abduction (the Anchored hook);
##   * the Lumen Sentinel's shield (row "lumen_shield"): an Enemy.holy_shield
##     of that share of its max HP at activation (the existing path; never
##     renewed);
##   * the prism list (row "prism") and the hold release on deactivation
##     (ConcordRules.note_spawn() / note_gone()).
## Phase 2 kinds extend this class: override physics() for a special and call
## super.physics() first (a live beam owns the tick); call super.reset() /
## super.on_deactivate() / super.taken_mult() / super.draw_under() /
## super.draw_over() when they override those.
## Determinism: no RNG, no instance ids.
class_name ConcordKit
extends CovenantKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	var r := e.game.concord_rules()  # The shared rules exist wherever a Concord kind walks.
	r.note_spawn(e)
	var share := float(d.get("lumen_shield", 0.0))  # The Lumen Sentinel's shield (share of max HP).
	if share > 0.0:
		e.holy_shield = e.max_hp * share
		e.holy_shield_time = INF  # Never fades: it soaks the first hits, then it is gone.


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	if e.game.concord != null:
		e.game.concord.note_gone(e)


## The shared rules (created on first use).
static func rules(e: Enemy) -> ConcordRules:
	return e.game.concord_rules()


## The kind's race (row "race"; ConcordRulesData.RACES).
func race() -> String:
	return String(d.get("race", ""))


## True when the kind heals on live alien ground (row "heals_on_turf";
## absent = true for every Concord kind but a structure).
func heals_on_turf() -> bool:
	return bool(d.get("heals_on_turf", not bool(d.get("is_structure", false))))


## The kind's beam style id (row "beam" "style"; "" = it fires none).
func beam_style() -> String:
	var b: Dictionary = d.get("beam", {})
	return String(b.get("style", ""))


## True for an abducting kind (row "abducts"): Abduction.
func abducts() -> bool:
	return bool(d.get("abducts", false))


## True for a flier (row "flies"): the Night Wings test in taken_mult().
func is_flier() -> bool:
	return bool(d.get("flies", false))


## The Vrask cloak's numbers (row "cloak"; {} = none).
func cloak() -> Dictionary:
	return d.get("cloak", {})


## Per-tick hook: while the kind's beam aims or holds, it stands still facing
## along it (true); otherwise the shared AI moves it (false). Subclasses add
## their specials after calling this.
func physics(e: Enemy, _delta: float) -> bool:
	var g := e.game
	if g.concord != null and g.concord.beams.has_beam(e):
		hold(e)
		return true
	return false


## The ranged attack of a beam kind: a beam at `t` through ConcordBeams.fire()
## (the row's "beam" style and overrides); a refusal (the cap) retries after
## BEAMS retry s. A kind without a beam fires nothing (the Star-Seer). Always
## true: no Concord kind fires a ProjectileManager shot.
func fire_ranged(e: Enemy, t: Node2D, dir: Vector2, _dmg: float) -> bool:
	var style := beam_style()
	if style == "":
		return true
	var over: Dictionary = (d.get("beam", {}) as Dictionary).duplicate()  # The row's overrides of its style.
	over.erase("style")
	over["target"] = t
	if not rules(e).beams.fire(e, dir, style, over):
		e.attack_cd = float(ConcordRulesData.BEAMS["retry"])
	else:
		on_beam_fired(e)
	return true


## Called when this kind's beam was accepted (subclasses: the Vrask hunter
## drops its cloak).
func on_beam_fired(_e: Enemy) -> void:
	pass


## Share of a friendly hit tagged `source` this kind takes: a flier's Night
## Wings test (a grounded melee summon's blow deals flight_melee_taken; every
## other hit in full). Exactly 1 for a grounded kind.
func taken_mult(e: Enemy, source: String) -> float:
	if not is_flier():
		return 1.0
	var g := e.game
	if g.concord != null and abducts():
		g.concord.abduction.on_saucer_hit(e)  # Anchored's hook (no-op while the passive does not exist).
	if FallenAngelKit.grounded_melee(source):
		g.stat_add("concord_air_whiffs", 1.0)
		return float(d.get("flight_melee_taken", 0.0))
	g.stat_add("concord_air_hits", 1.0)
	return 1.0


func is_busy() -> bool:
	return phase != IDLE


## A flier's ground shadow (it hovers above the ground).
func draw_under(e: Enemy) -> void:
	if not is_flier():
		return
	var w := e.radius * 1.1  # Shadow half-width (px).
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-w, e.radius * 0.9 - w * 0.35), Vector2(w * 2.0, w * 0.7)), false, Color(0.0, 0.0, 0.0, 0.28))
