## WheelOfThronesReport — the autotest summary lines of THE WHEEL OF THRONES and
## its rewards (temporary Act XIII, the Celestial Host; GDD §15.0 "The Wheel of
## Thrones (Act XIII phase 2)" and the rows after it). Read-only: it never
## changes the run. Two entry points:
##   stage_lines(game, st) — from HostReport.print_lines() (only when the Host
##       ran), each line only when its system ran:
##     wheel of thrones: WheelOfThronesDirector (the zones, the turning
##                       spheres, the Dominion of the Spheres, The Wheel
##                       Breaks, the events)
##     ophans:           the Ophans' rolls and the Dominion of the Spheres
##                       (when either spawned)
##     throne:           the Throne's fight (when it was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Wheel of Thrones' items was taken (so other runs print as before):
##     act XIII spell:    Wheel of Eyes / Ophanim
##     act XIII passives: All-Seeing, Smoked Glass
class_name WheelOfThronesReport
extends RefCounted


## The stage's lines (see the header).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.wheel_of_thrones != null:
		print("[autotest] wheel of thrones: %s" % en.wheel_of_thrones.summary_line())
	var ophans := int(st.get("spawned_" + HostEnemyData.OPHAN, 0.0))
	var dom := int(st.get("spawned_" + WheelOfThronesEnemyData.DOMINION_OF_THE_SPHERES, 0.0))
	if ophans > 0 or dom > 0:
		print("[autotest] ophans: ophan %d/%d, rolls %d (summon hits %d, player hits %d; dmg to you %d, to summons %d) | dominion of the spheres %d/%d (killed in %.0f s; halos regrown all run %d)" % [
			ophans, int(st.get("kill_" + HostEnemyData.OPHAN, 0.0)), int(st.get("ophan_rolls", 0.0)),
			int(st.get("ophan_summon_hits", 0.0)), int(st.get("ophan_player_hits", 0.0)),
			int(st.get("player_dmg_from_" + OphanKit.SOURCE, 0.0)), int(st.get("summon_dmg_from_" + OphanKit.SOURCE, 0.0)),
			dom, int(st.get("spheres_dominion_kills", 0.0)), float(st.get("spheres_dominion_ttk", 0.0)),
			game.host.grace.regrown if game.host != null else 0])
	if String(en.boss_info.get("id", "")) == String(WheelOfThronesStage.BOSS["id"]) and en.boss is BossThrone:
		print("[autotest] throne: %s" % BossThrone.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(WheelOfEyesData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(WheelOfEyesData.ID)  # The spell node (null if never ticked).
		print("[autotest] act XIII spell: wheel_of_eyes: Lv%d%s dmg=%d (ophanim %d) boss=%d kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(WheelOfEyesData.ID) else "", int(ab.spells.damage_of(WheelOfEyesData.ID)),
			int(st.get("dmg_" + WheelOfEyesData.EVOLVED_SOURCE, 0.0)),
			int(st.get("bossdmg_" + WheelOfEyesData.SOURCE, 0.0)) + int(st.get("bossdmg_" + WheelOfEyesData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(WheelOfEyesData.ID)), node.summary_extra() if node != null else ""])
	var sight := ab.passive_level(WheelOfEyesData.ALL_SEEING)  # All-Seeing level.
	var glass := ab.passive_level(HostRulesData.SMOKED_GLASS)  # Smoked Glass level.
	if sight > 0 or glass > 0:
		print("[autotest] act XIII passives: all_seeing Lv%d (wheels +%d%% damage, +%d%% roll time) | smoked_glass Lv%d (the Light's burn on summons -%d%%)" % [
			sight, roundi(100.0 * ab.passive_value(WheelOfEyesData.ALL_SEEING, WheelOfEyesData.DAMAGE_KEY)),
			roundi(100.0 * ab.passive_value(WheelOfEyesData.ALL_SEEING, WheelOfEyesData.LIFE_KEY)),
			glass, roundi(100.0 * ab.passive_value(HostRulesData.SMOKED_GLASS, HostRulesData.SMOKED_GLASS_KEY))])
