## EmpyreanReport — the autotest summary lines of THE EMPYREAN and its rewards
## (temporary Act XIII, the Celestial Host's finale; GDD §15.0 "The Empyrean
## (Act XIII phase 2)" and the rows after it). Read-only: it never changes the
## run. Two entry points:
##   stage_lines(game, st) — from HostReport.print_lines() (only when the Host
##       ran), each line only when its system ran:
##     empyrean:   EmpyreanDirector (the zones, the Choir, the Herald of the
##                 Seventh Trumpet, The Last Word, the events)
##     seventh herald: the miniboss's calls and fall (when he spawned)
##     voice:      the Voice's fight (when it was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Empyrean's items was taken (so other runs print as before):
##     act XIII spell:    Revelation / Be Not Afraid
##     act XIII passives: Seventh Seal, Turning Bones
##     bound ophan:       the Bound Ophan / Throne of Bones
class_name EmpyreanReport
extends RefCounted


## The stage's lines (see the header).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.empyrean != null:
		print("[autotest] empyrean: %s" % en.empyrean.summary_line())
	var her := int(st.get("spawned_" + EmpyreanEnemyData.HERALD_OF_THE_SEVENTH_TRUMPET, 0.0))
	if her > 0:
		print("[autotest] seventh herald: %d/%d, calls %d (bodies called %d, summons pushed %d), killed in %.0f s" % [
			her, int(st.get("seventh_herald_kills", 0.0)), int(st.get("seventh_herald_calls", 0.0)),
			int(st.get("herald_called", 0.0)), int(st.get("herald_pushed", 0.0)), float(st.get("seventh_herald_ttk", 0.0))])
	if String(en.boss_info.get("id", "")) == String(EmpyreanStage.BOSS["id"]) and en.boss is BossVoice:
		print("[autotest] voice: %s" % BossVoice.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(RevelationData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(RevelationData.ID)  # The spell node (null if never ticked).
		print("[autotest] act XIII spell: revelation: Lv%d%s dmg=%d (be_not_afraid %d) boss=%d kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(RevelationData.ID) else "", int(ab.spells.damage_of(RevelationData.ID)),
			int(st.get("dmg_" + RevelationData.EVOLVED_SOURCE, 0.0)),
			int(st.get("bossdmg_" + RevelationData.SOURCE, 0.0)) + int(st.get("bossdmg_" + RevelationData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(RevelationData.ID)), node.summary_extra() if node != null else ""])
	var seal := ab.passive_level(RevelationData.SEVENTH_SEAL)  # Seventh Seal level.
	var turn := ab.passive_level(BoundOphanBehavior.TURNING)  # Turning Bones level.
	if seal > 0 or turn > 0:
		print("[autotest] act XIII passives: seventh_seal Lv%d (flash +%d%% damage, +%.1f s stun) | turning_bones Lv%d (rolls +%d%% damage, +%d%% recharge)" % [
			seal, roundi(100.0 * ab.passive_value(RevelationData.SEVENTH_SEAL, RevelationData.DAMAGE_KEY)),
			ab.passive_value(RevelationData.SEVENTH_SEAL, RevelationData.STUN_KEY),
			turn, roundi(100.0 * ab.passive_value(BoundOphanBehavior.TURNING, BoundOphanBehavior.TURNING_DAMAGE_KEY)),
			roundi(100.0 * ab.passive_value(BoundOphanBehavior.TURNING, BoundOphanBehavior.TURNING_HASTE_KEY))])
	var cls := BoundOphanBehavior.CLASS_ID
	if int(game.horde.class_levels.get(cls, 0)) > 0:
		print("[autotest] bound ophan: Lv %d%s, alive %d | dmg %d (bound_ophan=%d roll=%d throne_of_bones=%d roll=%d) | rolls %d (orbit hits %d, roll hits %d, backs %d)" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_bound_ophan", 0.0)) + int(st.get("dmg_" + BoundOphanBehavior.SOURCE, 0.0)) + int(st.get("dmg_throne_of_bones", 0.0)) + int(st.get("dmg_" + BoundOphanBehavior.EVOLVED_SOURCE, 0.0)),
			int(st.get("dmg_bound_ophan", 0.0)), int(st.get("dmg_" + BoundOphanBehavior.SOURCE, 0.0)),
			int(st.get("dmg_throne_of_bones", 0.0)), int(st.get("dmg_" + BoundOphanBehavior.EVOLVED_SOURCE, 0.0)),
			int(st.get("bound_ophan_rolls", 0.0)), int(st.get("bound_ophan_orbit_hits", 0.0)), int(st.get("bound_ophan_roll_hits", 0.0)),
			int(st.get("throne_of_bones_backs", 0.0))])
