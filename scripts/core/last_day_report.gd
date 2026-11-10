## LastDayReport — the autotest summary lines of THE LAST DAY and its rewards
## (temporary Act XIV, the Age of Titans' finale; GDD §15.0 "The Last Day (Act
## XIV phase 2)" and the rows after it). Read-only: it never changes the run.
## Two entry points:
##   stage_lines(game, st) — from PrimevalReport.print_lines() (only when the
##       Titans' rules ran), each line only when its system ran:
##     last day:   LastDayDirector (Fire from the Sky; Thunderwing; the
##                 Stormwings' gusts; the Tyrants' swallows and roars; events)
##     extinction: the Extinction (only once it began: the fall, the impact's
##                 kills, the boss left, the Fossil Host raised and its
##                 damage, the end in victory, The Day the Sky Fell)
##     gravejaw:   Old Gravejaw's fight (when he was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Last Day's items was taken (so other runs print as before):
##     act XIV spell:   Meteor Call / Extinction Event
##     act XIV passive: Cosmic Dust, Petrified Horns, Thick Marrow
##     bonehorn:        the Bonehorn / Fossil Tyrant
class_name LastDayReport
extends RefCounted


## The stage's lines (see the header).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.last_day != null:
		print("[autotest] last day: %s" % en.last_day.summary_line())
	var ex := game.primeval.extinction
	if ex.running():
		var lost := 0  # The necromancers' own summons lost this run.
		for hd in game.all_hordes:
			lost += hd.total_deaths
		print("[autotest] extinction: fell %s | impact %s (the white-out %.0f s, under the ward) | enemies killed %d (taken off %d) | boss left %s | fossil host risen %d (capped %d, too far %d), life %.0f s, dmg %d | ended %s | the day the sky fell %s (summons lost %d)" % [
			EmpireReport._clock(ex.started_at), EmpireReport._clock(ex.landed_at) if ex.landed else "no", float(ex.cfg["warn"]),
			ex.killed, int(st.get("extinction_despawned", 0.0)),
			("%d%%" % roundi(100.0 * ex.boss_left)) if ex.boss_left >= 0.0 else "none alive",
			ex.raised, int(st.get("extinction_host_capped", 0.0)), int(st.get("extinction_host_far", 0.0)), float(ex.cfg["host_life"]),
			int(st.get("dmg_" + String(ex.cfg["tag"]), 0.0)),
			("in VICTORY at " + EmpireReport._clock(game.elapsed)) if float(st.get("extinction_ended", 0.0)) > 0.0 else "no (the run ended before)",
			"EARNED" if float(st.get(Extinction.DAY_THE_SKY_FELL_STAT, 0.0)) > 0.0 else "no", lost])
	if String(en.boss_info.get("id", "")) == String(LastDayStage.BOSS["id"]) and en.boss is BossGravejaw:
		print("[autotest] gravejaw: %s" % BossGravejaw.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(MeteorCallData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(MeteorCallData.ID)  # The spell node (null if never ticked).
		print("[autotest] act XIV spell: meteor_call: Lv%d%s dmg=%d (extinction event %d) boss=%d kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(MeteorCallData.ID) else "", int(ab.spells.damage_of(MeteorCallData.ID)),
			int(st.get("dmg_" + MeteorCallData.EVOLVED_SOURCE, 0.0)),
			int(st.get("bossdmg_" + MeteorCallData.SOURCE, 0.0)) + int(st.get("bossdmg_" + MeteorCallData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(MeteorCallData.ID)), node.summary_extra() if node != null else ""])
	var dust := ab.passive_level(MeteorCallData.COSMIC_DUST)  # Cosmic Dust level.
	if dust > 0:
		print("[autotest] act XIV passive: cosmic_dust Lv%d (meteors +%d%%, +%d px)" % [
			dust, roundi(100.0 * ab.passive_value(MeteorCallData.COSMIC_DUST, MeteorCallData.DAMAGE_KEY)),
			roundi(ab.passive_value(MeteorCallData.COSMIC_DUST, MeteorCallData.RADIUS_KEY))])
	var horns := ab.passive_level(BonehornBehavior.HORNS)  # Petrified Horns level.
	if horns > 0:
		print("[autotest] act XIV passive: petrified_horns Lv%d (charges +%d%% damage, +%d%% recharge)" % [
			horns, roundi(100.0 * ab.passive_value(BonehornBehavior.HORNS, BonehornBehavior.HORNS_DAMAGE_KEY)),
			roundi(100.0 * ab.passive_value(BonehornBehavior.HORNS, BonehornBehavior.HORNS_HASTE_KEY))])
	var marrow := ab.passive_level(PrimevalRulesData.THICK_MARROW)  # Thick Marrow level.
	if marrow > 0:
		print("[autotest] act XIV passive: thick_marrow Lv%d (tramples, charges, stomps -%d%%)" % [
			marrow, roundi(100.0 * ab.passive_value(PrimevalRulesData.THICK_MARROW, PrimevalRulesData.THICK_MARROW_KEY))])
	var cls := BonehornBehavior.CLASS_ID
	if int(game.horde.class_levels.get(cls, 0)) > 0:
		print("[autotest] bonehorn: Lv %d%s, alive %d | dmg %d (bonehorn=%d charge=%d fossil_tyrant=%d charge=%d) | charges %d (hits %d, roars %d, stunned %d)" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_bonehorn", 0.0)) + int(st.get("dmg_" + BonehornBehavior.SOURCE, 0.0)) + int(st.get("dmg_fossil_tyrant", 0.0)) + int(st.get("dmg_" + BonehornBehavior.EVOLVED_SOURCE, 0.0)),
			int(st.get("dmg_bonehorn", 0.0)), int(st.get("dmg_" + BonehornBehavior.SOURCE, 0.0)),
			int(st.get("dmg_fossil_tyrant", 0.0)), int(st.get("dmg_" + BonehornBehavior.EVOLVED_SOURCE, 0.0)),
			int(st.get("bonehorn_charges", 0.0)), int(st.get("bonehorn_hits", 0.0)), int(st.get("fossil_tyrant_roars", 0.0)), int(st.get("fossil_tyrant_stuns", 0.0))])
