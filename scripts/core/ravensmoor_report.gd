## RavensmoorReport — the autotest summary lines of Ravensmoor (Act VII, Stage
## 19; GDD §15.0 "Ravensmoor (Act VII phase 2)" and the rows after it).
## Read-only: it never changes the run. Two entry points:
##   print_lines(game, st) — from CourtReport.print_lines() (only when the
##       Court ran), each line only when its system ran:
##     ravensmoor:       RavensmoorDirector (the sleeping coffins, Coffin Nails,
##                       the ghoul packs, Old Greymane, the events)
##     ravensmoor kinds: the Ghouls' meals (when a ghoul spawned)
##     old greymane:     the miniboss's fight (when he spawned)
##     vargr:            Vargr's fight (when he was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of Ravensmoor's items was taken (so other runs print as before):
##     act VII spell:    Moonfang / Wolf of the Red Moon (level, damage, kills,
##                       jaws, bleeds)
##     act VII passives: Pack Blood, Silver Bones (levels, effects)
class_name RavensmoorReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.ravensmoor != null:
		print("[autotest] ravensmoor: %s" % en.ravensmoor.summary_line())
	if float(st.get("spawned_" + CourtEnemyData.GHOUL, 0.0)) > 0.0:
		print("[autotest] ravensmoor kinds: ghoul corpse claims %d (each corpse lost to every raise) | meals eaten %d, broken by a kill %d, abandoned %d | healed %d" % [
			int(st.get("ghoul_claims", 0.0)), int(st.get("ghoul_meals", 0.0)), int(st.get("ghoul_meals_broken", 0.0)),
			int(st.get("ghoul_meals_abandoned", 0.0)), int(st.get("ghoul_meal_heal", 0.0))])
	if float(st.get("greymane_spawned", 0.0)) > 0.0:
		print("[autotest] old greymane: howls %d (werewolves turned %d, spurred %d) | lunges %d (bites %d) | killed %d (ttk %.0f s) | fed %d | dmg to you %d, to summons %d" % [
			int(st.get("greymane_howls", 0.0)), int(st.get("greymane_howl_turned", 0.0)), int(st.get("greymane_howl_spurred", 0.0)),
			int(st.get("greymane_lunges", 0.0)), int(st.get("greymane_lunge_hits", 0.0)),
			int(st.get("greymane_kills", 0.0)), float(st.get("greymane_ttk", 0.0)),
			int(st.get("feast_heal_" + RavensmoorEnemyData.GREYMANE, 0.0)),
			int(st.get("player_dmg_from_" + RavensmoorEnemyData.GREYMANE, 0.0) + st.get("player_dmg_from_" + RavensmoorEnemyData.GREYMANE_LUNGE_SOURCE, 0.0)),
			int(st.get("summon_dmg_from_" + RavensmoorEnemyData.GREYMANE, 0.0) + st.get("summon_dmg_from_" + RavensmoorEnemyData.GREYMANE_LUNGE_SOURCE, 0.0))])
	if String(en.boss_info.get("id", "")) == VargrData.ARRIVAL["id"] and en.boss is BossVargr:
		print("[autotest] vargr: %s" % BossVargr.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(MoonfangData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(MoonfangData.ID)  # The spell node (null if never ticked).
		print("[autotest] act VII spell: moonfang: Lv%d%s dmg=%d (wolf of the red moon %d, bleeds %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(MoonfangData.ID) else "", int(ab.spells.damage_of(MoonfangData.ID)),
			int(st.get("dmg_" + MoonfangData.EVOLVED_SOURCE, 0.0)), int(st.get("dmg_" + MoonfangData.BLEED_SOURCE, 0.0)),
			int(ab.spells.kills_of(MoonfangData.ID)), node.summary_extra() if node != null else ""])
	var pack := ab.passive_level(MoonfangData.PACK_BLOOD)  # Pack Blood level.
	var silver := ab.passive_level(MoonfangData.SILVER_BONES)  # Silver Bones level.
	if pack > 0 or silver > 0:
		print("[autotest] act VII passives: pack_blood Lv%d (dmg to bleeding foes +%d%%, bonus %d) | silver_bones Lv%d (summon dmg to werewolves / nobles +%d%%, %d hits; mist x%.2f)" % [
			pack, roundi(100.0 * ab.passive_value(MoonfangData.PACK_BLOOD, MoonfangData.PACK_KEY)), int(st.get("pack_blood_bonus_dmg", 0.0)),
			silver, roundi(100.0 * ab.passive_value(MoonfangData.SILVER_BONES, CourtRulesData.SILVER_DAMAGE_KEY)), int(st.get("silver_bones_bonus_hits", 0.0)),
			1.0 - ab.passive_value(MoonfangData.SILVER_BONES, CourtRulesData.SILVER_MIST_KEY)])
