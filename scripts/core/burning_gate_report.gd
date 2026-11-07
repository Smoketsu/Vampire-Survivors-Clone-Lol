## BurningGateReport — the autotest summary lines of the Burning Gate (Act VI,
## Stage 16; GDD §15.0 "The Burning Gate (Act VI phase 2)" and the rows after
## it). Read-only: it never changes the run. Two entry points:
##   print_lines(game, st) — from InfernoReport.print_lines() (only when the
##       Inferno ran), each line only when its system ran:
##     burning gate:       BurningGateDirector (the Gatekeeper, the River of
##                         Fire, Gate Crashed, the events)
##     burning gate kinds: the Hellhounds' trails, the Pit Cultists' rites
##                         (when any of the stage's kinds spawned)
##     gatekeeper:         the miniboss's fight (when he spawned)
##     moloch:             Moloch's fight (when he was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Burning Gate's items was taken (so other runs print as before):
##     act VI spell:     Brimstone / Rain of Fire (level, damage, kills, stones,
##                       pits)
##     act VI passives:  Furnace Heart, Salt Circle (levels, effects)
class_name BurningGateReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.burning_gate != null:
		print("[autotest] burning gate: %s" % en.burning_gate.summary_line())
	var kinds := false  # A Burning Gate kind spawned.
	for k: String in BurningGateEnemyData.ENEMIES:
		kinds = kinds or float(st.get("spawned_" + k, 0.0)) > 0.0
	if kinds:
		print("[autotest] burning gate kinds: hellhound trail pits %d (skipped at the cap %d; every pit burned summons for %d) | pit cultist rites %d (portals opened %d, broken by a kill %d, refused %d)" % [
			int(st.get("hound_trail_pits", 0.0)), int(st.get("hound_trail_skipped", 0.0)), int(st.get("summon_dmg_from_" + InfernoRulesData.PIT_SOURCE, 0.0)),
			int(st.get("cultist_rites", 0.0)), int(st.get("cultist_portals", 0.0)), int(st.get("cultist_rites_broken", 0.0)),
			int(st.get("cultist_rites_refused", 0.0))])
	if float(st.get("gatekeeper_spawned", 0.0)) > 0.0:
		print("[autotest] gatekeeper: chains %d (summons hooked %d, crushed %d; damned hooked %d, devoured %d, healed %d; hit you %d) | slams %d (summon hits %d) | coffles %d (damned %d) | killed %d (ttk %.0f s) | dmg to you %d, to summons %d" % [
			int(st.get("gatekeeper_chains", 0.0)), int(st.get("gatekeeper_hooked_summons", 0.0)), int(st.get("gatekeeper_crushed", 0.0)),
			int(st.get("gatekeeper_hooked_damned", 0.0)), int(st.get("gatekeeper_devoured", 0.0)), int(st.get("gatekeeper_devour_heal", 0.0)),
			int(st.get("gatekeeper_chain_hits_player", 0.0)), int(st.get("gatekeeper_slams", 0.0)), int(st.get("gatekeeper_slam_hits", 0.0)),
			int(st.get("gatekeeper_coffles", 0.0)), int(st.get("gatekeeper_coffle_damned", 0.0)),
			int(st.get("gatekeeper_kills", 0.0)), float(st.get("gatekeeper_ttk", 0.0)),
			int(st.get("player_dmg_from_" + BurningGateEnemyData.CHAIN_SOURCE, 0.0) + st.get("player_dmg_from_" + BurningGateEnemyData.SLAM_SOURCE, 0.0) + st.get("player_dmg_from_gatekeeper", 0.0)),
			int(st.get("summon_dmg_from_" + BurningGateEnemyData.CHAIN_SOURCE, 0.0) + st.get("summon_dmg_from_" + BurningGateEnemyData.SLAM_SOURCE, 0.0) + st.get("summon_dmg_from_gatekeeper", 0.0))])
	if String(en.boss_info.get("id", "")) == MolochData.ARRIVAL["id"] and en.boss is BossMoloch:
		print("[autotest] moloch: %s" % BossMoloch.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(BrimstoneData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(BrimstoneData.ID)  # The spell node (null if never ticked).
		print("[autotest] act VI spell: brimstone: Lv%d%s dmg=%d (rain of fire %d, pits %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(BrimstoneData.ID) else "", int(ab.spells.damage_of(BrimstoneData.ID)),
			int(st.get("dmg_" + BrimstoneData.EVOLVED_SOURCE, 0.0)), int(st.get("dmg_" + BrimstoneData.PIT_SOURCE, 0.0)),
			int(ab.spells.kills_of(BrimstoneData.ID)), node.summary_extra() if node != null else ""])
	var heart := ab.passive_level(BrimstoneData.FURNACE_HEART)  # Furnace Heart level.
	var salt := ab.passive_level(BrimstoneData.SALT_CIRCLE)  # Salt Circle level.
	if heart > 0 or salt > 0:
		print("[autotest] act VI passives: furnace_heart Lv%d (spell dmg in fire +%d%%, bonus %d) | salt_circle Lv%d (pit dmg to summons %d, x%.2f)" % [
			heart, roundi(100.0 * ab.passive_value(BrimstoneData.FURNACE_HEART, BrimstoneData.HEART_KEY)), int(st.get("furnace_heart_bonus_dmg", 0.0)),
			salt, int(st.get("pit_dmg_summons", 0.0)), 1.0 - ab.passive_value(BrimstoneData.SALT_CIRCLE, InfernoRulesData.SALT_CIRCLE_KEY)])
