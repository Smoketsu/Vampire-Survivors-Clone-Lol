## SeasonWheel — the HUD's WHEEL OF THE YEAR on Turning Year stages (temporary
## Act XV; GDD §15.0 "The Turning Year (seasons)"; owner-approved proposal: "the
## 20:00 clock is one year ... shown as a wheel on the HUD"). Four quarters
## (spring green, summer gold, autumn leaf, winter frost) round a small disc
## left of the countdown, the season now lit and a bone-white hand on the
## share of it passed; after 0:00 the whole wheel turns green (Spring Returns).
## Reads SeasonCycle only; changes nothing. Redrawn only when the season or the
## hand's step changes (a few times a minute: a handful of arcs, never every
## frame). Created by WildRules when the run has a HUD (never headless).
class_name SeasonWheel
extends Control

## Radius (layout px) of the wheel.
const RADIUS: float = 12.0  # TUNING (not in GDD) drawing only
## Layout px from the HUD's centre line (left of the countdown; the Last Day's
## meteor dial sits on the right).
const OFFSET := Vector2(-96.0, 38.0)  # TUNING (not in GDD) drawing only
## Steps of the hand round one quarter (a redraw at each).
const HAND_STEPS: int = 12  # TUNING (not in GDD) drawing only
## Colour of each season's quarter (WildRulesData season order; [4] = Spring Returns).
const COLORS: Array[Color] = [Palette.WILD_MOSS, Palette.WILD_GOLD_LEAF, Palette.WILD_FIRE, Palette.WILD_FROST, Palette.WILD_BLOSSOM]

## Owning run.
var game: Game
## Season drawn last (-2 = never drawn).
var _drawn_season: int = -2
## Hand step drawn last.
var _drawn_step: int = -1


## Lays the wheel out beside the countdown and redraws when it moved (WildRules, every tick).
func refresh() -> void:
	position = Vector2(game.hud.size.x * 0.5, 0.0) + OFFSET
	var s := game.wild.seasons.season()
	var st := int(game.wild.seasons.season_fraction() * float(HAND_STEPS))
	if s != _drawn_season or st != _drawn_step:
		_drawn_season = s
		_drawn_step = st
		queue_redraw()


func _draw() -> void:
	draw_texture_rect(SpriteBank.disc(), Rect2(Vector2.ONE * -(RADIUS + 2.0), Vector2.ONE * (RADIUS + 2.0) * 2.0), false, Palette.WILD_INK)
	if _drawn_season == WildRulesData.RETURNS:
		draw_texture_rect(SpriteBank.disc(), Rect2(Vector2.ONE * -RADIUS, Vector2.ONE * RADIUS * 2.0), false, COLORS[4])
		return
	for q in 4:
		var a0 := -PI * 0.5 + float(q) * PI * 0.5  # Spring at the top, clockwise.
		var lit := q == _drawn_season
		draw_arc(Vector2.ZERO, RADIUS * 0.55, a0 + 0.06, a0 + PI * 0.5 - 0.06, 6, Color(COLORS[q], 1.0 if lit else 0.35), RADIUS * 0.8)
	if _drawn_season >= 0 and _drawn_season < 4:
		var a := -PI * 0.5 + (float(_drawn_season) + float(_drawn_step) / float(HAND_STEPS)) * PI * 0.5
		var tip := Vector2.from_angle(a) * RADIUS
		draw_line(Vector2.ZERO, tip, Palette.WILD_BONE, 2.0)
