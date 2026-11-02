## BountyBoardKit — the kit of DON MARROW'S BOUNTY BOARD (SkidRowEnemyData
## "bounty_board"; Act VIII, Skid Row; GDD §15.0 "Don Marrow, the Kingpin (Act
## VIII)"; owner-approved proposal: "he puts a price on the necromancer's head:
## gang spawns double while his bounty board is up; break the board to end
## it"). A structure (a billboard of wanted posters on legs; no letters on the
## art), raised by BossDonMarrow and tracked by SkidRowDirector, which doubles
## the gangs while it stands (bounty_active()). It never moves or attacks; it
## is a priority target (row target_priority 1) and never recycled
## (is_objective, set by the boss). Here: a slow gold pulse under it (a texture
## at <= 1 Hz, visual only) and its fall's banner and stat. No RNG. Stats:
## bounty_board_raised (the boss), bounty_board_broken.
class_name BountyBoardKit
extends CityKit

## Pulse rate (Hz) of the gold glow under the board (owner rule: at most 1 Hz,
## a soft fade).
const PULSE_HZ: float = 0.5  # TUNING (not in GDD)


func physics(e: Enemy, _delta: float) -> bool:
	hold(e)
	return true  # A board stands still: nothing else moves it.


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	g.stat_add("bounty_board_broken", 1.0)
	g.effects.impact(e.position, e.radius * 2.5, Palette.GOLD)
	g.enemies.show_banner(String(DonMarrowData.BOSS["board_down_banner"]))


## A soft gold glow under the board, pulsing slowly (visual only).
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	var k := 0.5 + 0.5 * sin(TAU * PULSE_HZ * e.game.elapsed)  # 0..1, a soft fade.
	SpriteBank.draw_disc(e, Vector2(0.0, e.radius * 0.4), e.radius * 1.8, Color(Palette.GOLD, 0.12 + 0.12 * k))
