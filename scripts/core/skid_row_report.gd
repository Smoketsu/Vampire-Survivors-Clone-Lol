## SkidRowReport — the autotest summary lines of Skid Row (Act VIII, Stage 22;
## GDD §15.0 "Skid Row (Act VIII phase 2)" and the rows after it). Read-only:
## it never changes the run. Two entry points:
##   print_lines(game, st) — from CityReport.print_lines() (only when the Last
##       Line ran), each line only when its system ran:
##     skid row:      SkidRowDirector (Big Sal and the limo, the Bounty's
##                    gangs, No Witnesses, the events)
##     tear gas:      the riot cops' tear gas (when a riot cop spawned)
##     big sal:       the miniboss's fight (when the limo came)
##     don marrow:    Don Marrow's fight (when he was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of Skid Row's items was taken (so other runs print as before):
##     act VIII spell:    Hearse Run / Funeral Procession (level, damage,
##                        kills, hearses, hits)
##     act VIII passives: Black Car, Kevlar Bones (levels, effects)
class_name SkidRowReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.skid_row != null:
		print("[autotest] skid row: %s" % en.skid_row.summary_line())
	if float(st.get("spawned_" + CityEnemyData.RIOT_COP, 0.0)) > 0.0:
		print("[autotest] tear gas: canisters %d | summon slows %d (refreshes of %.2f s)" % [
			int(st.get("riot_gas_thrown", 0.0)), int(st.get("riot_gas_slows", 0.0)),
			float(CityEnemyData.ENEMIES[CityEnemyData.RIOT_COP].get("gas_linger", 0.0))])
	if float(st.get("limo_spawned", 0.0)) > 0.0:
		print("[autotest] big sal: limo spawned %d, crew sprays %d (dmg to you %d, to summons %d), run-over dmg to summons %d | big sal out %d, swings %d (hits %d), killed %d (ttk %.0f s), dmg to you %d, to summons %d" % [
			int(st.get("limo_spawned", 0.0)), int(st.get("limo_crew_sprays", 0.0)),
			int(st.get("player_dmg_from_" + SkidRowEnemyData.LIMO_SPRAY_SOURCE, 0.0)), int(st.get("summon_dmg_from_" + SkidRowEnemyData.LIMO_SPRAY_SOURCE, 0.0)),
			int(st.get("summon_dmg_from_" + SkidRowEnemyData.LIMO, 0.0)),
			int(st.get("big_sal_spawned", 0.0)), int(st.get("big_sal_swings", 0.0)), int(st.get("big_sal_swing_hits", 0.0)),
			int(st.get("big_sal_kills", 0.0)), float(st.get("big_sal_ttk", 0.0)),
			int(st.get("player_dmg_from_" + SkidRowEnemyData.BIG_SAL, 0.0) + st.get("player_dmg_from_" + SkidRowEnemyData.SAL_SWING_SOURCE, 0.0)),
			int(st.get("summon_dmg_from_" + SkidRowEnemyData.BIG_SAL, 0.0) + st.get("summon_dmg_from_" + SkidRowEnemyData.SAL_SWING_SOURCE, 0.0))])
	if String(en.boss_info.get("id", "")) == DonMarrowData.ARRIVAL["id"] and en.boss is BossDonMarrow:
		print("[autotest] don marrow: %s" % BossDonMarrow.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(HearseRunData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(HearseRunData.ID)  # The spell node (null if never ticked).
		print("[autotest] act VIII spell: hearse_run: Lv%d%s dmg=%d (funeral procession %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(HearseRunData.ID) else "", int(ab.spells.damage_of(HearseRunData.ID)),
			int(st.get("dmg_" + HearseRunData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(HearseRunData.ID)), node.summary_extra() if node != null else ""])
	var car := ab.passive_level(HearseRunData.BLACK_CAR)  # Black Car level.
	var kevlar := ab.passive_level(HearseRunData.KEVLAR_BONES)  # Kevlar Bones level.
	if car > 0 or kevlar > 0:
		print("[autotest] act VIII passives: black_car Lv%d (struck foes slowed %d%%, %d slows) | kevlar_bones Lv%d (ranged City damage to summons -%d%%, withheld %d)" % [
			car, roundi(100.0 * ab.passive_value(HearseRunData.BLACK_CAR, HearseRunData.BLACK_CAR_KEY)), int(st.get("hearse_black_car_slows", 0.0)),
			kevlar, roundi(100.0 * ab.passive_value(HearseRunData.KEVLAR_BONES, CityRulesData.KEVLAR_KEY)), int(st.get("kevlar_dmg_prevented", 0.0))])
