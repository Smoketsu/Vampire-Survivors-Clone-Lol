## HrimgarBarrowKit — the kit of HRIMGAR'S BARROW (BarrowFieldsEnemyData
## "hrimgar_barrow"; the Barrow Fields; GDD §15.0 "Hrimgar the Draugr-King";
## owner-approved proposal: "each time he falls he sinks into his barrow and
## returns stronger 20 s later, unless the necromancer breaks the barrow while
## he is down"). The great mound BossHrimgar raises where he fell (his one
## barrow path, BossHrimgar._fall()). An open barrow from the start (no crack:
## he is already in it), so draugr climb out of it on the open barrow's rules
## (OpenBarrowKit, the row's release_every / release_max). Broken (its HP to
## 0), it tells the king (BossHrimgar.barrow_broken(): he never rises again);
## when he rises out of it first, he takes it off the field without a kill
## (EnemyDirector.despawn()). Drawn from norse/boss_barrow (64 x 56), a crack
## of rune light across it. Determinism: no RNG.
class_name HrimgarBarrowKit
extends OpenBarrowKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	set_phase(e, OPEN)  # He is already in it: no crack.
	release_cd = 1.0


## Broken while he lies in it: he never rises again.
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var b := e.game.enemies.boss
	if b is BossHrimgar and b.active:
		(b as BossHrimgar).barrow_broken(e)


## The king's barrow: its sprite, else the open barrow's mound, larger; a
## pulse of rune light while he lies in it. Visual only.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	unmirror(e, ci)
	if not SpriteBank.draw(ci, HrimgarData.BARROW_SPRITE, Vector2.ZERO, e.flash > 0.0):
		draw_mound(ci, "obstacles/barrow_open", Vector2.ZERO, e.radius, e.flash > 0.0)
	var a := 0.2 + 0.15 * sin(e.game.elapsed * 4.0)
	SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 0.3), e.radius * 0.5, Color(Palette.NORSE_RUNE, a))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
