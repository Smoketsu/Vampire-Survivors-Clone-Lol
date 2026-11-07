## UnderworldReport — the autotest summary lines of THE ASPHODEL UNDERWORLD and
## its rewards (Act IV, Stage 12; GDD §15.0 "The Asphodel Underworld (Act IV
## phase 2)" and the rows after it). Read-only: it never changes the run.
##   stage_lines(): called from PantheonReport (only when the Pantheon ran):
##     underworld        UnderworldDirector (the Styx, guests, objective Soul Ash)
##     underworld events the director's event log
##     underworld kinds  Cerberus (heads, attacks, time to kill), the Shade
##                       Hoplites, the Tartarus Wardens, the Shade Archers and
##                       the damage their arrows did (when any spawned)
##     hades             BossHades.summary_line() (when he fought) and his shades
##                       through the Claims path
##   item_lines(): called from Autotest.finish() on EVERY stage, each line only
##     when its item was used, so every other summary keeps its exact text:
##     river styx        River Styx / Lethe's Flood, Ferryman's Toll, the
##                       Ferrywoman's Ferry of Souls
##     myrmidon shades   the Myrmidon Shades / Legion of Tartarus and Myrmidon Oath
class_name UnderworldReport
extends RefCounted


## The stage's lines (PantheonReport; the Pantheon ran this run).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var ud := game.enemies.underworld  # The stage director (null off the Underworld).
	if ud != null:
		print("[autotest] underworld: %s" % ud.summary_line())
		print("[autotest] underworld events (%d): %s" % [ud.fired.size(), ", ".join(ud.fired)])
	if int(st.get("cerberus_spawned", 0.0)) > 0 or int(st.get("spawned_" + UnderworldEnemyData.SHADE_HOPLITE, 0.0)) > 0 \
			or int(st.get("spawned_" + UnderworldEnemyData.WARDEN, 0.0)) > 0 \
			or int(st.get("spawned_" + UnderworldEnemyData.SHADE_ARCHER, 0.0)) > 0:
		print("[autotest] underworld kinds: shade hoplites %d/%d | cerberus %d, killed %d (ttk %ds): heads killed %d, breaths %d, pounces %d, howls %d (shades %d), you hit %d, summon hits %d | tartarus wardens %d/%d | shade archers %d/%d, arrows hit you %d, summons %d" % [
			int(st.get("spawned_" + UnderworldEnemyData.SHADE_HOPLITE, 0.0)), int(st.get("kill_" + UnderworldEnemyData.SHADE_HOPLITE, 0.0)),
			int(st.get("cerberus_spawned", 0.0)), int(st.get("cerberus_kills", 0.0)), int(st.get("cerberus_ttk", 0.0)),
			int(st.get("cerberus_heads_killed", 0.0)), int(st.get("cerberus_breaths", 0.0)), int(st.get("cerberus_pounces", 0.0)),
			int(st.get("cerberus_howls", 0.0)), int(st.get("cerberus_shades", 0.0)), int(st.get("cerberus_player_hits", 0.0)),
			int(st.get("cerberus_summon_hits", 0.0)),
			int(st.get("spawned_" + UnderworldEnemyData.WARDEN, 0.0)), int(st.get("kill_" + UnderworldEnemyData.WARDEN, 0.0)),
			int(st.get("spawned_" + UnderworldEnemyData.SHADE_ARCHER, 0.0)), int(st.get("kill_" + UnderworldEnemyData.SHADE_ARCHER, 0.0)),
			int(st.get("player_dmg_from_" + UnderworldEnemyData.SHADE_ARCHER, 0.0)), int(st.get("summon_dmg_from_" + UnderworldEnemyData.SHADE_ARCHER, 0.0))])
	if game.enemies.boss is BossHades:
		print("[autotest] hades: %s" % BossHades.summary_line(st))
		if game.claims != null:
			print("[autotest] hades claims: %s | hades' shades %d" % [game.claims.summary_line(), game.claims.marked_claims])


## The rewards' lines (every stage; each only when its item was used).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var lvl := ab.spell_level(RiverStyxData.ID)
	if lvl > 0 or ab.passive_level(RiverStyxData.TOLL) > 0:
		var node: NecroSpell = ab.spells.nodes.get(RiverStyxData.ID)  # The spell node (null if never ticked).
		print("[autotest] river styx: Lv%d%s dmg=%d (evolved %d) boss=%d kills=%d %s | ferrymans_toll Lv%d slowed kills %d healed %d" % [
			lvl, " EVOLVED" if ab.evolved.has(RiverStyxData.ID) else "", int(ab.spells.damage_of(RiverStyxData.ID)),
			int(st.get("dmg_" + RiverStyxData.EVOLVED_SOURCE, 0.0)), int(st.get("bossdmg_" + RiverStyxData.SOURCE, 0.0)) + int(st.get("bossdmg_" + RiverStyxData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(RiverStyxData.ID)), node.summary_extra() if node != null else "",
			ab.passive_level(RiverStyxData.TOLL), int(st.get("toll_kills", 0.0)), int(st.get("toll_healed", 0.0))])
	var cls := "myrmidon_shade"
	if int(game.horde.class_levels.get(cls, 0)) > 0 or ab.passive_level("myrmidon_oath") > 0:
		print("[autotest] myrmidon shades: Lv %d%s, alive %d | dmg %d (myrmidon_shade=%d legion_of_tartarus=%d pierce=%d) | wall-locked thinks %d, dmg prevented %d | pierces %d, grips %d | myrmidon_oath Lv%d" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_myrmidon_shade", 0.0)) + int(st.get("dmg_legion_of_tartarus", 0.0)) + int(st.get("dmg_" + MyrmidonBehavior.PIERCE_SOURCE, 0.0)),
			int(st.get("dmg_myrmidon_shade", 0.0)), int(st.get("dmg_legion_of_tartarus", 0.0)), int(st.get("dmg_" + MyrmidonBehavior.PIERCE_SOURCE, 0.0)),
			int(st.get("myrmidon_walls_locked", 0.0)), int(st.get("behavior_dmg_prevented_" + cls, 0.0)),
			int(st.get("myrmidon_pierces", 0.0)), int(st.get("myrmidon_grips", 0.0)), ab.passive_level("myrmidon_oath")])
