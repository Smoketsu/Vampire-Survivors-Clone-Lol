## PantheonReport — the autotest summary lines of the Olympian Republic's shared
## rules and stages (Act IV; GDD §15.0 "Act IV foundation (phase 1)"), called
## once by Autotest.finish(). Every line prints only when the Pantheon ran this
## run (Game.pantheon exists: an Act IV stage, or a Pantheon kind forced onto
## another stage with --spawn=), so the Act I to III summaries keep their exact
## text:
##   divine wrath:    DivineWrath (salvos and strikes by kind, damage to
##                    enemies vs summons vs the necromancer, fodder drowned,
##                    corpses swallowed, lightning chains, shades spat, the
##                    Twilight)
##   phalanx:         Phalanx (walls formed, bodies locked, front hits cut,
##                    flank breaks, the most locked at once)
##   glory:           Glory (stacks gained, the peak, heroes killed and with
##                    which stacks, chests and Soul Ash bounty paid)
##   pantheon kinds:  spawns / kills of every Pantheon kind that spawned
##   pantheon stage:  the Act IV stage itself (stub status, wrath, boss, Soul Ash)
## Phase 2 adds one line per stage system here (each stage in its own block):
##   Act IV, the Shores of Ilion: IlionReport.print_lines() (ilion, ilion
##   kinds, polyphemus, achilles).
## Read-only: it never changes the run.
class_name PantheonReport
extends RefCounted


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var pan := game.pantheon  # The Pantheon's rules (null when they never ran).
	if pan == null:
		return
	print("[autotest] divine wrath: %s" % wrath_line(game, st))
	print("[autotest] phalanx: %s" % phalanx_line(game, st))
	print("[autotest] glory: %s" % glory_line(game, st))
	var parts := PackedStringArray()  # "kind spawned/killed" per Pantheon kind seen.
	var kinds: Array = []  # Every Pantheon kind id, the shared table first.
	for table: Dictionary in [PantheonEnemyData.ENEMIES, IlionEnemyData.ENEMIES, OlympusEnemyData.ENEMIES, UnderworldEnemyData.ENEMIES]:
		kinds.append_array(table.keys())
	for k: String in kinds:
		var spawned := int(st.get("spawned_" + k, 0.0))
		var killed := int(st.get("kill_" + k, 0.0))
		if spawned > 0 or killed > 0:
			parts.append("%s %d/%d (dmg to you %d, to summons %d)" % [k, spawned, killed,
				int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0))])
	if not parts.is_empty():
		print("[autotest] pantheon kinds (spawned/killed): %s" % " | ".join(parts))
	var sd := game.stage_def  # The run's stage.
	if StageRegistry.act_of(String(sd["id"])) == 4:
		var boss: Dictionary = sd["boss"]
		print("[autotest] pantheon stage: %s (%s) | playable %s | wrath %s | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | reckoning kind %s, twilight %s" % [
			String(sd["id"]), String(sd["display_name"]), str(StageRegistry.is_playable(String(sd["id"]))), pan.wrath.stage_kind,
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			EmpireReport._clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]),
			String((sd["reckoning"] as Dictionary).get("kind", "inquisitor")), str(not pan.wrath.twilight.is_empty())])
	# --- Act IV: the Shores of Ilion ---
	IlionReport.print_lines(game, st)  # Siege towers, the stage's kinds, Polyphemus, Achilles (each when it ran).


## The "divine wrath" line (DivineWrath counters; the damage to summons and to
## the necromancer from CombatResolver's per-source stats).
static func wrath_line(game: Game, st: Dictionary) -> String:
	var summon := 0.0  # Damage the wrath dealt to summons.
	var player := 0.0  # Damage the wrath dealt to the necromancer.
	for src: String in [DivineWrath.SRC_WAVE, DivineWrath.SRC_BOLT, DivineWrath.SRC_CHAIN, DivineWrath.SRC_FISSURE]:
		summon += float(st.get("summon_dmg_from_" + src, 0.0))
		player += float(st.get("player_dmg_from_" + src, 0.0))
	var enemy := 0.0  # Damage the wrath dealt to enemies.
	for k: String in PantheonRulesData.WRATH_KINDS:
		enemy += float(st.get("wrath_enemy_dmg_" + k, 0.0))
	var kills := 0  # Enemies the wrath killed.
	for src: String in [DivineWrath.SRC_WAVE, DivineWrath.SRC_BOLT, DivineWrath.SRC_CHAIN, DivineWrath.SRC_FISSURE]:
		kills += int(st.get("kills_by_" + src, 0.0))
	var w := game.pantheon.wrath
	return "stage kind %s | salvos waves %d, lightning %d, fissures %d | strikes: waves %d, bolts %d, fissures %d | dmg to enemies %d (kills %d), to summons %d, to you %d | fodder drowned %d | lightning chains %d | corpses swallowed %d | shades spat %d | capped %d | twilight %s" % [
		w.stage_kind if w.stage_kind != "" else "none",
		int(st.get("wrath_salvos_waves", 0.0)), int(st.get("wrath_salvos_lightning", 0.0)), int(st.get("wrath_salvos_fissures", 0.0)),
		int(st.get("wrath_waves", 0.0)), int(st.get("wrath_bolts", 0.0)), int(st.get("wrath_fissures", 0.0)),
		int(enemy), kills, int(summon), int(player), int(st.get("wrath_drowned", 0.0)), int(st.get("wrath_chains", 0.0)),
		int(st.get("wrath_corpses_swallowed", 0.0)), int(st.get("wrath_shades_spat", 0.0)), int(st.get("wrath_capped", 0.0)),
		"on" if w.twilight_on else ("off" if w.twilight.is_empty() else "not reached")]


## The "phalanx" line (Phalanx counters).
static func phalanx_line(game: Game, st: Dictionary) -> String:
	return "walls formed %d, bodies locked %d | front hits: shots %d, melee %d, dmg prevented %d | flank breaks %d | most locked at once %d" % [
		int(st.get("phalanx_walls_formed", 0.0)), int(st.get("phalanx_members_locked", 0.0)),
		int(st.get("phalanx_front_shots", 0.0)), int(st.get("phalanx_front_melee", 0.0)), int(st.get("phalanx_front_dmg_prevented", 0.0)),
		int(st.get("phalanx_flank_breaks", 0.0)), game.pantheon.phalanx.peak_locked]


## The "glory" line (Glory counters).
static func glory_line(game: Game, st: Dictionary) -> String:
	var by := PackedStringArray()  # "N stacks xM" for each stack count heroes died with.
	for n in range(1, int(PantheonRulesData.GLORY["max_stacks"]) + 1):
		var c := int(st.get("glory_kills_s%d" % n, 0.0))
		if c > 0:
			by.append("%d:%d" % [n, c])
	return "stacks gained %d, peak %d | heroes killed %d (with stacks %d; by stacks %s) | chests %d | bounty %d soul ash" % [
		int(st.get("glory_stacks_gained", 0.0)), game.pantheon.glory.peak, int(st.get("glory_heroes_killed", 0.0)),
		int(st.get("glory_kills_stacked", 0.0)), " ".join(by) if not by.is_empty() else "none", int(st.get("glory_chests", 0.0)),
		int(st.get("glory_bounty_ash", 0.0))]
