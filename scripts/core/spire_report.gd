## SpireReport — the autotest summary lines of Ul-Thalos, the Risen Spire (Act
## II, Stage 6) and its items (Autotest.finish() calls print_all()). Every
## line is printed only when its system ran this run (the stage's directors
## exist, one of its kinds spawned, an item was owned or forced), so the
## summaries of every other stage and build are unchanged.
##   spire sinking   — floods, the shoreline, bodies and drops the sea moved,
##                     shore spawns, the sinking's event log (SinkingDirector).
##   spire           — dream pillars, guest squads (SpireDirector).
##   spire kinds     — Sirens (songs, lured), Spawns of the Deep (grabs,
##                     squeezes), Hierophants (Ascensions started / finished /
##                     interrupted / broken), spawned / killed per kind.
##   vhalneth        — her phases, arms, gaze and roar (BossVhalneth).
##   the waking      — the Reckoning's Dreamspawn and the last flood.
##   call of the drowned / spawn of the deep — the spell, the class, their
##                     evolutions and passives (Abyssal Pact, Crushing Depths).
## Read-only: it never changes the run.
class_name SpireReport
extends RefCounted

## The Ul-Thalos kinds reported on the "spire kinds" line.
const KINDS := ["eye_siren", "eye_spawn", "eye_hierophant"]


## Prints every relevant line of run `game` (run statistics `st`).
static func print_all(game: Game, st: Dictionary) -> void:
	var i := func(key: String) -> int: return int(st.get(key, 0.0))
	var sink := game.enemies.sinking
	if sink != null:
		print("[autotest] spire sinking: %s" % sink.summary_line())
	if game.enemies.spire != null:
		print("[autotest] spire: %s" % game.enemies.spire.summary_line())
	var spawned := PackedStringArray()  # "kind=spawned/killed".
	var any := false  # An Ul-Thalos kind spawned.
	for kind: String in KINDS:
		var n: int = i.call("spawned_" + kind)
		any = any or n > 0
		spawned.append("%s=%d/%d" % [kind, n, i.call("kill_" + kind)])
	if any:
		print("[autotest] spire kinds (spawned/killed): %s | siren: songs %d (cancelled %d), lured %d | spawn: grabs %d, squeezes %d, broken by its death %d, squeeze dmg %d | ascensions: started %d, finished %d, interrupted %d, broken %d" % [
			" ".join(spawned), i.call("siren_songs"), i.call("siren_songs_cancelled"), i.call("siren_lured"),
			i.call("spawn_grabs"), i.call("spawn_grab_squeezes"), i.call("spawn_grabs_broken"), i.call("summon_dmg_from_spawn_grab"),
			i.call("ascensions_started"), i.call("ascensions_finished"), i.call("ascensions_interrupted"), i.call("ascensions_broken")])
	if st.has("vhalneth_spawn_time"):
		print("[autotest] vhalneth: %s" % BossVhalneth.summary_line(st))
	var waking: int = i.call("spawned_eye_waking_horror")  # Dreamspawn of the Waking.
	if waking > 0:
		print("[autotest] the waking: dreamspawn %d (slain %d) | dmg to player %d, summons %d" % [
			waking, i.call("kill_eye_waking_horror"), i.call("player_dmg_from_eye_waking_horror"), i.call("summon_dmg_from_eye_waking_horror")])
	_print_items(game, st)


## The Act II items of Ul-Thalos: printed when owned (or the class raised).
static func _print_items(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var i := func(key: String) -> int: return int(st.get(key, 0.0))
	var spell_lvl := ab.spell_level("call_of_the_drowned")
	if spell_lvl > 0 or ab.passive_level("abyssal_pact") > 0:
		var node: NecroSpell = ab.spells.nodes.get("call_of_the_drowned")  # The spell node (null if never ticked).
		print("[autotest] call of the drowned: Lv%d%s dmg=%d (evolved %d) boss=%d %s | %s" % [
			spell_lvl, " EVOLVED" if ab.evolved.has("call_of_the_drowned") else "", int(ab.spells.damage_of("call_of_the_drowned")),
			i.call("dmg_tide_tendril"), i.call("bossdmg_drowned_tendril") + i.call("bossdmg_tide_tendril"),
			node.summary_extra() if node != null else "", AbyssalPact.summary_line(game)])
	var cls := "spawn_of_the_deep"
	if int(game.horde.class_levels[cls]) > 0 or i.call("drowned_host_risen") > 0 or ab.passive_level("crushing_depths") > 0:
		print("[autotest] class %s: Lv %d, alive %d/%d, deaths %d | dmg %d (spawn_of_the_deep=%d leviathan=%d deep_grasp=%d leviathan_sweep=%d tide_host_spawn=%d) | grasps=%d holds=%d squeezes=%d held_s=%d sweeps=%d sweep_hits=%d | crushing_depths Lv%d bonus_dmg=%d" % [
			cls, int(game.horde.class_levels[cls]), game.horde.count_of(cls), game.horde.capacity(cls),
			int(Autotest._sum_prefix(st, "death_%s_by_" % cls)),
			i.call("dmg_spawn_of_the_deep") + i.call("dmg_leviathan") + i.call("dmg_deep_grasp") + i.call("dmg_leviathan_sweep"),
			i.call("dmg_spawn_of_the_deep"), i.call("dmg_leviathan"), i.call("dmg_deep_grasp"), i.call("dmg_leviathan_sweep"), i.call("dmg_tide_host_spawn"),
			i.call("deep_grasps"), i.call("deep_grasp_holds"), i.call("deep_grasp_squeezes"), i.call("deep_grasp_held_seconds"),
			i.call("leviathan_sweeps"), i.call("leviathan_sweep_hits"), ab.passive_level("crushing_depths"), i.call("crushing_depths_bonus_dmg")])
