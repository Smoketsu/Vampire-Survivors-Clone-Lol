## HeroKit — the kit of the Hero (PantheonEnemyData "hero"; Act IV, GDD §15.0
## "Act IV foundation (phase 1)" and "Glory"): a strong melee demigod. Each Hero
## takes the next named variant of its row's "names" (Ajax, Hector, Atalanta,
## in turn: PantheonRules.next_hero_name(), no RNG) as its display name. HERO:
## every summon it kills is a Glory stack (Glory, through the kill hook in
## CombatResolver.damage_unit()): more damage (Enemy.hit_mult()), a bigger body
## and a growing gold aura drawn here. BRONZE: Zeus's lightning chains to it.
class_name HeroKit
extends PantheonKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	var names: Array = def.get("names", [])  # Named variants.
	if not names.is_empty():
		e.display_name = rules(e).next_hero_name(names)


## The Glory aura on the ground: a gold ring that widens and brightens with
## every stack (none at 0). Visual only.
func draw_under(e: Enemy) -> void:
	if e.glory <= 0:
		return
	var k := float(e.glory) / float(PantheonRulesData.GLORY["max_stacks"])  # 0..1 of the cap.
	var r := e.radius * (1.35 + 0.5 * k)  # Aura radius (px).
	unmirror(e)
	e.draw_circle(Vector2.ZERO, r, Color(Palette.GOLD, 0.08 + 0.14 * k))
	e.draw_arc(Vector2.ZERO, r, 0.0, TAU, 28, Color(Palette.GOLD, 0.45 + 0.4 * k), 1.0 + 2.0 * k)
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The Glory pips over the head (one gold pip per stack, two rows past 5).
## Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if e.glory <= 0:
		return
	unmirror(e, ci)
	var y := e.marker_y(-e.radius * 2.2) - 2.0  # Pip row height (px).
	for i in e.glory:
		var row := floori(float(i) / 5.0)  # 0 or 1.
		var col := i % 5
		var p := Vector2((float(col) - 2.0) * 7.0, y - float(row) * 7.0)
		ci.draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), PantheonGlyphs.INK)
		ci.draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Palette.GOLD)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
