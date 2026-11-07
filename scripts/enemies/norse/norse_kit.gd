## NorseKit — base class of the Hall of the Slain's kits (the Norse act,
## temporarily Act XI; GDD §15.0 "The Hall of the Slain foundation (phase 1)"),
## a CovenantKit plugged into the shared Enemy AI like every kit. Kits load by
## name from scripts/enemies/norse/<id>_kit.gd (CovenantKits, after the Eye's,
## the Empire's, the Pantheon's, the Shogunate's, the Inferno's, the Court's,
## the City's and the Concord's folders; an id must not repeat theirs). What
## every Norse kind shares:
##   * creating the shared rules on first use (Game.norse_rules()), so a Norse
##     kind forced onto any stage with --spawn= still goes berserk and fears no
##     cold there (the timeline's stones, braziers and Ragnarök stay off);
##   * the row flags as helpers: group(), is_warrior() (Berserkergang),
##     is_flier();
##   * BERSERKERS are born in the fury (row "berserk_always":
##     NorseRules.enter_fury());
##   * THE WARD of a Rune-Stone the hall holds: taken_mult() asks
##     RuneStones.ward_mult() (the one ward read), times a flier's Night Wings
##     test (FallenAngelKit.grounded_melee(): a grounded melee summon's blow
##     deals the row's flight_melee_taken while she is aloft; landed() true
##     lets every blow land);
##   * THE SKALD'S SONG on this warrior: while `song_until` lies ahead his
##     attack cooldown runs `song_bonus` faster (physics(); written only by
##     SkaldKit.sing());
##   * THE EINHERJAR: make_einherjar() (Ragnarok; phase 2's Feast and Sigrun's
##     Doors of the Hall) makes a warrior of the hall a gold-lit hero,
##     stronger by NorseRulesData.EINHERJAR (on top of the elite's);
##   * the looks every Norse kind shares: a flier's ground shadow, the
##     Einherjar's gold light, the fury's red eyes, the song's notes, the ward's
##     rune shimmer.
## Phase 2 kinds extend this class: override physics() for a special and call
## super.physics() first; call super.reset() / super.on_deactivate() /
## super.taken_mult() / super.draw_under() / super.draw_over() when they
## override those.
## Determinism: no RNG, no instance ids.
class_name NorseKit
extends CovenantKit

## True for an Einherjar, a hero of the hall (gold-lit; make_einherjar()).
var einherjar: bool = false
## Game time (s) until which a skald's song quickens this warrior (0 = none).
var song_until: float = 0.0
## + share of attack speed the song gives while it lasts (0..1).
var song_bonus: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	einherjar = false
	song_until = 0.0
	song_bonus = 0.0
	var r := e.game.norse_rules()  # The shared rules exist wherever a Norse kind walks.
	r.note_spawn(e)
	if bool(d.get("berserk_always", false)):
		r.enter_fury(e, false)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	einherjar = false


## The shared rules (created on first use).
static func rules(e: Enemy) -> NorseRules:
	return e.game.norse_rules()


## The kind's group (row "group"; NorseRulesData.GROUPS).
func group() -> String:
	return String(d.get("group", ""))


## True for a warrior of the hall (row "warrior"): Berserkergang.
func is_warrior() -> bool:
	return bool(d.get("warrior", false))


## True for a flier (row "flies"): the Night Wings test in taken_mult().
func is_flier() -> bool:
	return bool(d.get("flies", false))


## True while a flier stands on the ground (every blow lands); false aloft.
## Subclasses with a landing override it (the valkyrie after her dive).
func landed() -> bool:
	return false


## Makes `e` (this kit's enemy, just spawned) an EINHERJAR: gold-lit, and
## NorseRulesData.EINHERJAR hp / damage / speed stronger (on top of the
## elite's). Call it right after spawning `e` as an elite.
func make_einherjar(e: Enemy) -> void:
	var cfg := NorseRulesData.EINHERJAR  # The Einherjar's numbers.
	einherjar = true
	e.max_hp *= float(cfg["hp"])
	e.hp = e.max_hp
	e.damage *= float(cfg["damage"])
	e.move_speed *= float(cfg["speed"])
	e.queue_redraw()


## Per-tick hook: the skald's song runs this warrior's attack cooldown faster.
## Never owns the tick (false); subclasses add their specials after calling it.
func physics(e: Enemy, delta: float) -> bool:
	if song_until > e.game.elapsed:
		e.attack_cd -= delta * song_bonus
	return false


## Share of a friendly hit tagged `source` this kind takes: the ward of a
## Rune-Stone the hall holds (RuneStones.ward_mult(), 1 outside every ward),
## times a flier's Night Wings test aloft. Exactly 1 for a grounded kind far
## from every held stone.
func taken_mult(e: Enemy, source: String) -> float:
	var m := 1.0
	var g := e.game
	if g.norse != null and not e.is_structure:
		m = g.norse.stones.ward_mult(e)
	if is_flier() and not landed():
		if FallenAngelKit.grounded_melee(source):
			g.stat_add("norse_air_whiffs", 1.0)
			m *= float(d.get("flight_melee_taken", 0.0))
		else:
			g.stat_add("norse_air_hits", 1.0)
	return m


func is_busy() -> bool:
	return phase != IDLE


## Under the body: a flier's ground shadow; an Einherjar's gold light.
func draw_under(e: Enemy) -> void:
	if is_flier():
		var w := e.radius * 1.1  # Shadow half-width (px).
		e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-w, e.radius * 0.9 - w * 0.35), Vector2(w * 2.0, w * 0.7)), false, Color(0.0, 0.0, 0.0, 0.28))
	if einherjar:
		var r := e.radius * 1.8  # Glow radius (px).
		e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r * 1.1), Vector2(r * 2.0, r * 2.0)), false, Color(Palette.NORSE_VALKYRIE_GOLD, 0.32))


## Over the body: the fury's red eyes and the song's notes.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var top := e.marker_y(-e.radius * 1.4)  # Just above the sprite (px, local).
	if e.berserk:
		unmirror(e, ci)
		SpriteBank.draw_disc(ci, Vector2(-2.5, top + 4.0), 1.6, Palette.NORSE_BERSERK)
		SpriteBank.draw_disc(ci, Vector2(2.5, top + 4.0), 1.6, Palette.NORSE_BERSERK)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if song_until > e.game.elapsed:
		unmirror(e, ci)
		SpriteBank.draw_disc(ci, Vector2(e.radius * 0.6, top - 2.0), 1.5, Palette.NORSE_HEARTH)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
