## KuroganeReport — the autotest summary lines of Castle Kurogane (Act V, Stage
## 14; GDD §15.0 "Castle Kurogane (Act V phase 2)" and the rows after it).
## Read-only: it never changes the run. Two entry points:
##   print_lines(game, st) — from ShogunateReport.print_lines() (only when the
##       Shogunate ran), each line only when its system ran:
##     kurogane:            KuroganeDirector (the General's arrival and fall)
##     kurogane kinds:      the Hatamoto (banners, aura pulses), the Kiba-musha's
##                          charges (when any of the stage's kinds spawned)
##     general of the left: the miniboss's fight (when he spawned)
##     shogun:              Shogun Kurogane's fight (when he was the stage boss):
##                          the bar, the regiments, the banners, the duel
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of Castle Kurogane's items was taken (so other runs print as before):
##     act V spell:     Banner of the Dead / Hundred Banners (level, banners,
##                      hastened attacks, plant damage, kills)
##     act V passives:  Warlord's Seal, Unbending (levels, effects)
class_name KuroganeReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.kurogane != null:
		print("[autotest] kurogane: %s" % en.kurogane.summary_line())
	var kinds := false  # A Castle Kurogane kind spawned.
	for k: String in KuroganeEnemyData.ENEMIES:
		kinds = kinds or float(st.get("spawned_" + k, 0.0)) > 0.0
	if kinds:
		print("[autotest] kurogane kinds: hatamoto %d (killed %d; aura pulses %d) | kiba-musha charges %d (hits: summons %d, you %d)" % [
			int(st.get("hatamoto_spawned", 0.0)), int(st.get("kill_hatamoto", 0.0)), int(st.get("march_aura_buff_pulses", 0.0)),
			int(st.get("kiba_charges", 0.0)), int(st.get("kiba_charge_hits_summon", 0.0)), int(st.get("kiba_charge_hits_player", 0.0))])
	if float(st.get("general_spawned", 0.0)) > 0.0:
		var rage := float(st.get("general_rage_at", -1.0))
		print("[autotest] general of the left: charges %d (hits: summons %d, you %d) | riders called %d | rage %s | killed %d (ttk %.0f s) | dmg to you %d, to summons %d" % [
			int(st.get("general_charges", 0.0)), int(st.get("general_charge_hits_summon", 0.0)), int(st.get("general_charge_hits_player", 0.0)),
			int(st.get("general_riders_called", 0.0)), EmpireReport._clock(rage) if rage >= 0.0 else "no",
			int(st.get("general_kills", 0.0)), float(st.get("general_ttk", 0.0)),
			int(st.get("player_dmg_from_" + KuroganeEnemyData.GENERAL_CHARGE_SOURCE, 0.0) + st.get("player_dmg_from_general_left", 0.0)),
			int(st.get("summon_dmg_from_" + KuroganeEnemyData.GENERAL_CHARGE_SOURCE, 0.0) + st.get("summon_dmg_from_general_left", 0.0))])
	if String(en.boss_info.get("id", "")) == "shogun" and en.boss is BossShogun:
		print("[autotest] shogun: %s" % BossShogun.summary_line(game, st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(BannerData.SPELL)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(BannerData.SPELL)  # The spell node (null if never ticked).
		print("[autotest] act V spell: banner_of_the_dead: Lv%d%s dmg=%d (hundred banners %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(BannerData.SPELL) else "", int(ab.spells.damage_of(BannerData.SPELL)),
			int(st.get("dmg_" + BannerData.EVOLVED_SOURCE, 0.0)), int(ab.spells.kills_of(BannerData.SPELL)),
			node.summary_extra() if node != null else ""])
	var seal := ab.passive_level(BannerData.SEAL)  # Warlord's Seal level.
	var unb := ab.passive_level(ShogunateRulesData.UNBENDING)  # Unbending level.
	if seal > 0 or unb > 0:
		print("[autotest] act V passives: warlords_seal Lv%d (attack speed near you +%d%%) | unbending Lv%d (draw cut dmg to summons %d, x%.2f)" % [
			seal, roundi(100.0 * ab.passive_value(BannerData.SEAL, BannerData.SEAL_KEY)), unb, int(st.get("draw_dmg_summons", 0.0)),
			1.0 - ab.passive_value(ShogunateRulesData.UNBENDING, ShogunateRulesData.UNBENDING_KEY)])
