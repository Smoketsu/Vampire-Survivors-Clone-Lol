## SleepingCoffinKit — the kit of Ravensmoor's SLEEPING COFFINS
## (RavensmoorEnemyData "sleeping_coffin"; Act VII, GDD §15.0 "Ravensmoor (Act
## VII phase 2)"; owner-approved proposal: "Sleeping coffins: sealed coffins
## in each zone. Break one before the next Blood Moon for a Soul Ash bounty;
## leave it and a Vampire Noble climbs out when the moon turns"). The Court's
## coffin (CourtCoffinKit: it stands closed until open_coffin(), then releases
## its row's release_kind; the sleeping coffin's row lets out ONE noble,
## release_max 1), placed and opened by RavensmoorDirector (its "coffins"
## waves; it opens every closed one when the Blood Moon rises, any moon: the
## clock's, Vargr's or the Endless Feast's). Broken while still closed, it
## tells the director (the bounty, Coffin Nails). Drawn with the shared
## coffin's art (structures/court_coffin and _open, else CourtGlyphs' coffin).
## No RNG. Stats: the director's (ravensmoor_coffins_*).
class_name SleepingCoffinKit
extends CourtCoffinKit


## Broken: the director pays the bounty when it was still closed.
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var rm := e.game.enemies.ravensmoor  # Ravensmoor's director (null elsewhere, --spawn=).
	if rm != null:
		rm.on_coffin_broken(e, opened)


## The sleeping coffin always draws itself: the shared coffin's art.
func draws_body(_e: Enemy) -> bool:
	return true


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	if opened:
		super.draw_body(e, ci)
	elif not SpriteBank.draw(ci, "structures/" + CourtEnemyData.COFFIN, Vector2.ZERO, e.flash > 0.0):
		CourtGlyphs.draw_coffin(ci, Vector2.ZERO, e.radius, e.flash > 0.0, false)
