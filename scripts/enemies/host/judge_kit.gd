## JudgeKit — the kit of the JUDGE (male, Judgment's elite; HostEnemyData
## "judge"; temporary Act XIII, the Celestial Host; GDD §15.0 "Judgment";
## proposal: "Comes for the necromancer with a sword and a set of scales | Kill
## it to lighten the scales"). Sent by Judgment at each third of the scales
## (Judgment.send_judges()). He HUNTS THE NECROMANCER: every tick, unless a
## blocker holds him (Enemy.engaged_timer: Warriors still body-block him, the
## owner rule), his target is the nearest standing necromancer, never the
## ring. His death lightens the scales (on_killed() ->
## Judgment.on_judge_died(); only a kill counts, so a Judge pooled away at the
## run's end lightens nothing). Determinism: no RNG.
class_name JudgeKit
extends HostKit


func physics(e: Enemy, delta: float) -> bool:
	if e.engaged_timer <= 0.0:
		var best: Necromancer = null  # Nearest standing necromancer.
		var best_d := INF
		for pl in e.game.all_players:
			if pl.dead:
				continue
			var dd := pl.position.distance_to(e.position)
			if dd < best_d:
				best_d = dd
				best = pl
		if best != null:
			e.target = best
			e.target_gen = 0
	return super.physics(e, delta)


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if e.game.host != null:
		e.game.host.judgment.on_judge_died(e)


## The Judge's scales over his halo: two small dawn-rose pans (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	super.draw_over(e, ci)
	var top := Vector2(0.0, -e.radius * 2.6)
	ci.draw_rect(Rect2(top + Vector2(-e.radius * 0.7, 0.0), Vector2(e.radius * 1.4, 1.0)), Palette.HOST_SILVER)
	for s: float in [-1.0, 1.0]:
		ci.draw_rect(Rect2(top + Vector2(s * e.radius * 0.7 - 2.0, 2.0), Vector2(4.0, 1.5)), Palette.HOST_ROSE)
