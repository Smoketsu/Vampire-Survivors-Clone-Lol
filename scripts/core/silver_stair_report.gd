## SilverStairReport — the autotest summary lines of THE SILVER STAIR and its
## rewards (temporary Act XIII, the Celestial Host; GDD §15.0 "The Silver Stair
## (Act XIII phase 2)" and the rows after it). Read-only: it never changes the
## run. Two entry points:
##   stage_lines(game, st) — from HostReport.print_lines() (only when the Host
##       ran), each line only when its system ran:
##     silver stair:  SilverStairDirector (the steps, the low cloud banks,
##                    Without Sin, the Cherub of the Gate, the events)
##     cherubs:       the Cherubs' and the Cherub of the Gate's swords (when
##                    either spawned)
##     seraiel:       Seraiel's fight (when he was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Silver Stair's items was taken (so other runs print as before):
##     act XIII spell:    Flaming Sword / Sword at the Gate
##     act XIII passives: Fallen Light, Absolution
class_name SilverStairReport
extends RefCounted


## The stage's lines (see the header).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.silver_stair != null:
		print("[autotest] silver stair: %s" % en.silver_stair.summary_line())
	var cherubs := int(st.get("spawned_" + HostEnemyData.CHERUB, 0.0))
	var gate := int(st.get("spawned_" + SilverStairEnemyData.CHERUB_OF_THE_GATE, 0.0))
	if cherubs > 0 or gate > 0:
		print("[autotest] cherubs: cherub %d/%d, sweeps %d | cherub of the gate %d/%d (killed in %.0f s) | bodies cut %d (sword dmg to you %d, to summons %d)" % [
			cherubs, int(st.get("kill_" + HostEnemyData.CHERUB, 0.0)), int(st.get("cherub_sweeps", 0.0)),
			gate, int(st.get("cherub_gate_kills", 0.0)), float(st.get("cherub_gate_ttk", 0.0)), int(st.get("cherub_cuts", 0.0)),
			int(st.get("player_dmg_from_" + CherubKit.SOURCE, 0.0)), int(st.get("summon_dmg_from_" + CherubKit.SOURCE, 0.0))])
	if String(en.boss_info.get("id", "")) == String(SilverStairStage.BOSS["id"]) and en.boss is BossSeraiel:
		print("[autotest] seraiel: %s" % BossSeraiel.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(FlamingSwordData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(FlamingSwordData.ID)  # The spell node (null if never ticked).
		print("[autotest] act XIII spell: flaming_sword: Lv%d%s dmg=%d (sword at the gate %d) boss=%d kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(FlamingSwordData.ID) else "", int(ab.spells.damage_of(FlamingSwordData.ID)),
			int(st.get("dmg_" + FlamingSwordData.EVOLVED_SOURCE, 0.0)),
			int(st.get("bossdmg_" + FlamingSwordData.SOURCE, 0.0)) + int(st.get("bossdmg_" + FlamingSwordData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(FlamingSwordData.ID)), node.summary_extra() if node != null else ""])
	var light := ab.passive_level(FlamingSwordData.FALLEN_LIGHT)  # Fallen Light level.
	var absol := ab.passive_level(HostRulesData.ABSOLUTION)  # Absolution level.
	if light > 0 or absol > 0:
		print("[autotest] act XIII passives: fallen_light Lv%d (sweeps +%d%%, arc +%d deg) | absolution Lv%d (each sin -%d%%)" % [
			light, roundi(100.0 * ab.passive_value(FlamingSwordData.FALLEN_LIGHT, FlamingSwordData.EDGE_KEY)),
			roundi(ab.passive_value(FlamingSwordData.FALLEN_LIGHT, FlamingSwordData.ARC_KEY)),
			absol, roundi(100.0 * ab.passive_value(HostRulesData.ABSOLUTION, HostRulesData.ABSOLUTION_KEY))])
