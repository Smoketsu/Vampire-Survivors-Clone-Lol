## Glory — the GLORY rule of the Olympian Republic (Act IV; GDD §15.0 "Glory"),
## owned by PantheonRules (`Game.pantheon.glory`). Numbers in
## PantheonRulesData.GLORY.
##   * GAIN: a "hero" kind (PantheonKit with row "hero") that kills a summon
##     gains a stack (on_summon_killed(), from the kill hook in
##     CombatResolver.damage_unit(), which names the killer when an enemy's own
##     blow struck it), up to max_stacks: Enemy.glory. Each stack adds
##     damage_per_stack to its hits (Enemy.hit_mult(), the one enemy damage
##     multiplier) and size_per_stack to its body radius and drawn size
##     (UnitMotion.set_size()); HeroKit draws the growing gold aura and pips.
##   * PAYOUT: a hero slain with stacks (on_enemy_killed(), from
##     CombatResolver._kill_enemy()) pays ash_per_stack Soul Ash per stack
##     through the run's "objective_ash" (the existing Soul Ash path) and, at
##     chest_stacks or more, drops a chest (ChestManager.spawn_chest(), never
##     after 0:00, like every chest).
## Stats: glory_stacks_gained, glory_peak, glory_heroes_killed,
## glory_kills_stacked (killed with any stacks), glory_kills_s<N> (killed at N
## stacks), glory_chests, glory_bounty_ash.
class_name Glory
extends RefCounted

## Owning run.
var game: Game
## Most stacks any hero held this run.
var peak: int = 0


## Builds the rule for `p_game`.
func _init(p_game: Game) -> void:
	game = p_game


## Hero `by` killed a summon: one more stack (no-op for a non-hero, a dead
## killer or a hero at the cap).
func on_summon_killed(by: Enemy) -> void:
	if by == null or not by.active or not (by.kit is PantheonKit) or not (by.kit as PantheonKit).is_hero():
		return
	var cfg := PantheonRulesData.GLORY
	if by.glory >= int(cfg["max_stacks"]):
		return
	by.glory += 1
	var grow := 1.0 + float(cfg["size_per_stack"]) * float(by.glory)  # Size factor.
	by.radius = by.glory_base_radius * grow
	if by.motion != null:
		by.motion.set_size(grow)
	by.queue_redraw()
	peak = maxi(peak, by.glory)
	game.stat_add("glory_stacks_gained", 1.0)
	game.pantheon.play_sound("glory", by.position)
	game.effects.ring(by.position, by.radius * 1.8, Palette.GOLD, 0.3)
	if by.glory == int(cfg["banner_stacks"]):
		game.enemies.show_banner("%s grows in Glory: kill it for its bounty!" % by.display_name)


## Enemy `e` was killed: a hero pays out its Glory (see the header).
func on_enemy_killed(e: Enemy) -> void:
	if not (e.kit is PantheonKit) or not (e.kit as PantheonKit).is_hero():
		return
	game.stat_add("glory_heroes_killed", 1.0)
	if e.glory <= 0:
		return
	var cfg := PantheonRulesData.GLORY
	game.stat_add("glory_kills_stacked", 1.0)
	game.stat_add("glory_kills_s%d" % e.glory, 1.0)
	var ash := float(int(cfg["ash_per_stack"]) * e.glory)  # Soul Ash bounty.
	game.stat_add("objective_ash", ash)
	game.stat_add("glory_bounty_ash", ash)
	if e.glory >= int(cfg["chest_stacks"]) and not game.countdown_finished():
		if game.chests.spawn_chest(e.position, true):
			game.stat_add("glory_chests", 1.0)
	game.effects.impact(e.position, e.radius * 2.0, Palette.GOLD)
