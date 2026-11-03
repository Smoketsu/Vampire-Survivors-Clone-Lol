## ProvingMoonReport — the autotest summary lines of the Proving Moon (Act IX,
## Stage 26; GDD §15.0 "The Proving Moon (Act IX phase 2)" and the rows after
## it). Read-only: it never changes the run. Two entry points:
##   print_lines(game, st) — from ConcordReport.print_lines() (only when the
##       Concord ran), each line only when its system ran:
##     proving moon:          ProvingMoonDirector (low gravity, the Warbeast,
##                            the events) and the knockback the moon threw
##     warbeast:              the miniboss's fight (when it spawned)
##     proving moon threats:  the top summon-damage sources and summon deaths
##                            of the run, and the reflected beams' share of the
##                            run's damage (the balance pass's view)
##     vrask'tal:             his fight (when he was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Proving Moon's items was taken (so other runs print as before):
##     act IX spell:          Soul Caster / Apex Predator (level, damage, kills,
##                            locks, trophies)
##     act IX passives:       Trophy Rack, Mirror Bones (levels, effects)
class_name ProvingMoonReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.proving_moon != null:
		print("[autotest] proving moon: %s" % en.proving_moon.summary_line())
	if float(st.get("warbeast_spawned", 0.0)) > 0.0:
		print("[autotest] warbeast: pounces %d (hits %d, farthest from %d px, reach %d px) | killed %d (ttk %.0f s) | dmg to you %d, to summons %d" % [
			int(st.get("warbeast_pounces", 0.0)), int(st.get("warbeast_pounce_hits", 0.0)), int(st.get("warbeast_pounce_reach_max", 0.0)),
			roundi(float(ProvingMoonEnemyData.ENEMIES[ProvingMoonEnemyData.WARBEAST]["pounce_reach"]) * game.concord.gravity()),
			int(st.get("warbeast_kills", 0.0)), float(st.get("warbeast_ttk", 0.0)),
			int(st.get("player_dmg_from_" + ProvingMoonEnemyData.WARBEAST, 0.0) + st.get("player_dmg_from_" + ProvingMoonEnemyData.POUNCE_SOURCE, 0.0)),
			int(st.get("summon_dmg_from_" + ProvingMoonEnemyData.WARBEAST, 0.0) + st.get("summon_dmg_from_" + ProvingMoonEnemyData.POUNCE_SOURCE, 0.0))])
	if String(game.stage_def.get("id", "")) == ProvingMoonStage.ID:
		var total := float(st.get("damage_dealt", 0.0))  # The run's damage to enemies.
		var refl := float(st.get("beam_reflect_dmg", 0.0))
		print("[autotest] proving moon threats (summon dmg by source): %s | summon deaths by source: %s | reflected beams %d dmg (%.1f%% of the run's %d)" % [
			FortKesslerReport._threats(st), FortKesslerReport._deaths(st), int(refl), 100.0 * refl / maxf(1.0, total), int(total)])
	if String(en.boss_info.get("id", "")) == VraskTalData.ARRIVAL["id"] and en.boss is BossVraskTal:
		print("[autotest] vrask'tal: %s" % BossVraskTal.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(SoulCasterData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(SoulCasterData.ID)  # The spell node (null if never ticked).
		print("[autotest] act IX spell: soul_caster: Lv%d%s dmg=%d (apex predator %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(SoulCasterData.ID) else "", int(ab.spells.damage_of(SoulCasterData.ID)),
			int(st.get("dmg_" + SoulCasterData.EVOLVED_SOURCE, 0.0)), int(ab.spells.kills_of(SoulCasterData.ID)),
			node.summary_extra() if node != null else ""])
	var rack := ab.passive_level(SoulCasterData.TROPHY_RACK)  # Trophy Rack level.
	var mirror := ab.passive_level(ConcordRulesData.MIRROR_BONES)  # Mirror Bones level.
	if rack > 0 or mirror > 0:
		print("[autotest] act IX passives: trophy_rack Lv%d (+%.1f%% a trophy, up to %d; trophies hung %d) | mirror_bones Lv%d (beam damage to summons -%d%%, reflected +%d%%)" % [
			rack, 100.0 * ab.passive_value(SoulCasterData.TROPHY_RACK, SoulCasterData.TROPHY_DMG_KEY),
			int(ab.passive_value(SoulCasterData.TROPHY_RACK, SoulCasterData.TROPHY_CAP_KEY)), int(st.get("soul_caster_trophies", 0.0)),
			mirror, roundi(100.0 * ab.passive_value(ConcordRulesData.MIRROR_BONES, ConcordRulesData.MIRROR_TAKEN_KEY)),
			roundi(100.0 * ab.passive_value(ConcordRulesData.MIRROR_BONES, ConcordRulesData.MIRROR_REFLECT_KEY))])
