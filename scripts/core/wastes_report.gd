## WastesReport — the autotest summary lines of the Scrap Wastes (Act III,
## Stage 7; GDD §15.0 "The Scrap Wastes (Act III phase 2)" and "Death Ray,
## Conductive Marrow and the Lightning Abbess"). Read-only: it never changes the
## run. Two entry points:
##   print_lines(game, st) — from EmpireReport.print_lines() (only when the
##       Empire ran), each line only when its system ran:
##     wastes:        WastesDirector (pylons, the reach shares, storms, the
##                    Trojan Horse, objective Soul Ash)
##     wastes kinds:  the Aegis Bot shields, Mortar shells, Swarm Rockets,
##                    Kestrel's decoys (when any of them spawned)
##     trojan horse:  the miniboss's fight (when it spawned)
##     kestrel:       Kestrel's fight (when she was the stage boss)
##   print_items(game, st) — from Autotest.finish() on every stage, only when
##       one of the Scrap Wastes' items was taken (so other runs print as before):
##     act III spell:     Death Ray / Event Horizon (level, damage, kills, sweeps)
##     act III passives:  Conductive Marrow, Lead-Lined Bones (levels, effects)
class_name WastesReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.wastes != null:
		print("[autotest] wastes: %s" % en.wastes.summary_line())
	var kinds := false  # A Scrap Wastes kind spawned.
	for k: String in WastesEnemyData.ENEMIES:
		kinds = kinds or float(st.get("spawned_" + k, 0.0)) > 0.0
	if kinds:
		print("[autotest] wastes kinds: aegis shields blocked %d shots (%d dmg), broke %d times | mortar shells %d | rockets launched %d: intercepted by summons %d, hit you %d, shot down %d, burst %d | decoys %d (fizzled %d)" % [
			int(st.get("aegis_shots_blocked", 0.0)), int(st.get("aegis_dmg_blocked", 0.0)), int(st.get("aegis_shield_breaks", 0.0)),
			int(st.get("wastes_mortar_shells", 0.0)), int(st.get("wastes_rockets_launched", 0.0)), int(st.get("wastes_rockets_intercepted", 0.0)),
			int(st.get("wastes_rockets_hit_player", 0.0)), int(st.get("wastes_rockets_shot_down", 0.0)), int(st.get("wastes_rockets_burst", 0.0)),
			int(st.get("spawned_" + WastesEnemyData.DECOY, 0.0)), int(st.get("wastes_decoys_fizzled", 0.0))])
	if float(st.get("trojan_spawned", 0.0)) > 0.0:
		var split := float(st.get("trojan_split_at", -1.0))
		print("[autotest] trojan horse: volleys %d | stomps %d (summon hits %d) | hull split %s (drones %d) | killed %d (ttk %.0f s) | dmg to you %d, to summons %d" % [
			int(st.get("trojan_volleys", 0.0)), int(st.get("trojan_stomps", 0.0)), int(st.get("trojan_stomp_hits", 0.0)),
			("at %d:%02d" % [floori(split / 60.0), int(split) % 60]) if split >= 0.0 else "no", int(st.get("trojan_split_drones", 0.0)),
			int(st.get("trojan_kills", 0.0)), float(st.get("trojan_ttk", 0.0)),
			int(st.get("player_dmg_from_trojan_stomp", 0.0) + st.get("player_dmg_from_trojan_horse", 0.0) + st.get("player_dmg_from_trojan_rocket", 0.0)),
			int(st.get("summon_dmg_from_trojan_stomp", 0.0) + st.get("summon_dmg_from_trojan_horse", 0.0) + st.get("summon_dmg_from_trojan_rocket", 0.0))])
	if String(en.boss_info.get("id", "")) == "kestrel" and en.boss != null:
		print("[autotest] kestrel: %s" % BossKestrel.summary_line(st))


## The items' lines (see the header).
static func print_items(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level("death_ray")  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get("death_ray")  # The spell node (null if never ticked).
		print("[autotest] act III spell: death_ray: Lv%d%s dmg=%d (event horizon %d, sparks %d) boss=%d kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has("death_ray") else "", int(ab.spells.damage_of("death_ray")), int(st.get("dmg_event_horizon", 0.0)),
			int(st.get("dmg_ray_spark", 0.0)), int(st.get("bossdmg_death_ray", 0.0) + st.get("bossdmg_event_horizon", 0.0) + st.get("bossdmg_ray_spark", 0.0)),
			int(ab.spells.kills_of("death_ray")), node.summary_extra() if node != null else ""])
	var marrow := ab.passive_level("conductive_marrow")  # Conductive Marrow level.
	var lead := ab.passive_level("lead_lined_bones")  # Lead-Lined Bones level.
	if marrow > 0 or lead > 0:
		print("[autotest] act III passives: conductive_marrow Lv%d | lead_lined_bones Lv%d (ranged dmg prevented %d)" % [
			marrow, lead, int(st.get("lead_lined_dmg_prevented", 0.0))])
