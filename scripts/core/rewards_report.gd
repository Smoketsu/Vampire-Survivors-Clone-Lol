## RewardsReport — the autotest's achievement-rewards summary line (content
## wave 2, GDD §15.0 "Achievement rewards (content wave 2)"), called once by
## Autotest.finish() after every older line, so those keep their exact text:
##   rewards: achievements=<earned this run> (ids) titles=<titles open>
##            unlocks=<reward items unlocked this run> | run counters (RunRewards)
##            | the one-run achievements this run qualifies for, and whether
##            award_run() checked them (--rewards=on / --meta-save) | the
##            setup screen's title row, built once headless.
## Under the autotest Meta is in memory only (nothing is written to user://
## unless --meta-save), so "earned" means earned by this run on a fresh save.
## Read-only: it never changes the run.
class_name RewardsReport
extends RefCounted


## Prints the rewards line for the finished run `summary` (Game.build_summary()
## plus its "soul_ash" award); `host` parents the throwaway title row.
static func print_line(host: Node, game: Game, summary: Dictionary) -> void:
	var ash: Dictionary = summary.get("soul_ash", {})  # Meta.award_run() result.
	var earned: PackedStringArray = ash.get("achievements", PackedStringArray())  # Achievements earned this run.
	var items: PackedStringArray = ash.get("unlocked_items", PackedStringArray())  # UnlockData items unlocked this run.
	var rewards := PackedStringArray()  # The reward items among them ("type:id").
	for id: String in items:
		if Unlocks.is_reward(id):
			rewards.append("%s:%s" % [Unlocks.item_type(id), id])
	var st: Dictionary = summary.get("stats", {})
	var c := Meta.run_counters(summary)  # This run's one-run achievement counters.
	var qualifies := PackedStringArray()  # One-run achievements this run meets on its own.
	for id: String in MetaData.ACHIEVEMENT_ORDER:
		var def: Dictionary = MetaData.ACHIEVEMENTS[id]
		if bool(def.get("run", false)) and float(c.get(String(def["stat"]), 0.0)) >= float(def["goal"]):
			qualifies.append(id)
	var row := PreRunTitleRow.new()  # The setup screen's title row (UI code runs headless).
	host.add_child(row)
	var choices := row.choices().size()  # "None" + unlocked titles.
	row.queue_free()
	print("[autotest] rewards: achievements=%d (%s) titles=%d unlocks=%s | run: %s | one-run achievements met: %s (%s) | worn title: %s | title row choices %d" % [
		earned.size(), ", ".join(earned) if not earned.is_empty() else "none", Meta.unlocked_titles().size(),
		",".join(rewards) if not rewards.is_empty() else "none", game.rewards.summary_text(st),
		", ".join(qualifies) if not qualifies.is_empty() else "none",
		"checked" if Meta.run_achievements_checked() else "not checked: --rewards=on",
		TitleData.display_text(Meta.selected_title()) if Meta.selected_title() != "" else "none", choices])
