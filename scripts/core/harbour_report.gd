## HarbourReport — the autotest summary lines of Gullhaven Harbour's systems
## (Act II, GDD §15.0 "Gullhaven Harbour (Act II phase 2)"), called once by
## Autotest.finish(). Each line prints only when its system ran this run, so
## the Act I summaries keep their exact text:
##   tide:            the TideDirector (the Harbour only)
##   harbour:         the HarbourDirector's buoys, caches, the Harbourmaster
##   harbour events:  the HarbourDirector's event log
##   harbour kinds:   spawns / kills and the tricks of the Harbour's kinds
##                    (any stage where one spawned, e.g. --spawn=deep_kin@60)
##   merrow:          Abbot Merrow's fight (when he was the stage boss)
##   undertow:        the Undertow spell (when learned)
##   act II passives: Salt of the Deep and Brinewalker (when owned)
## Read-only: it never changes the run.
class_name HarbourReport
extends RefCounted

## The Harbour's kinds, in report order.
const KINDS := ["deep_kin", "tide_caller", "netcaster", "harbourmaster", "deep_herald"]


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies
	if en.tide != null:
		print("[autotest] tide: %s" % en.tide.summary_line())
	if en.harbour != null:
		print("[autotest] harbour: %s" % en.harbour.summary_line())
		print("[autotest] harbour events (%d): %s" % [en.harbour.fired.size(), ", ".join(en.harbour.fired)])
	var any := false  # A Harbour kind spawned this run.
	var parts := PackedStringArray()
	for k: String in KINDS:
		var spawned := int(st.get("spawned_" + k, 0.0))
		var killed := int(st.get("kill_" + k, 0.0))
		if spawned > 0 or killed > 0:
			any = true
		parts.append("%s %d/%d" % [k, spawned, killed])
	if any:
		print("[autotest] harbour kinds (spawned/killed): %s" % " ".join(parts))
		print("[autotest] harbour tricks: deep kin leaps %d (summon hits %d, player hits %d) | tide caller lines %d (summons thrown %d, player hits %d) | nets thrown %d, landed %d, missed %d, cut %d, pinned %.0f unit-s | harbourmaster sweeps %d, hurls %d, summons dragged %d, reeled in %d, you dragged %d, kills %d (avg time to kill %.1f s) | dmg to player: leap %d, line %d, net %d, sweep %d, hurl %d" % [
			int(st.get("deep_kin_leaps", 0.0)), int(st.get("deep_kin_leap_summon_hits", 0.0)), int(st.get("deep_kin_leap_player_hits", 0.0)),
			int(st.get("tide_caller_walls", 0.0)), int(st.get("tide_caller_wall_summon_hits", 0.0)), int(st.get("tide_caller_wall_player_hits", 0.0)),
			int(st.get("netcaster_nets", 0.0)), int(st.get("netcaster_pins", 0.0)), int(st.get("netcaster_misses", 0.0)), int(st.get("netcaster_nets_cut", 0.0)),
			float(st.get("netcaster_pin_seconds", 0.0)),
			int(st.get("harbourmaster_sweeps", 0.0)), int(st.get("harbourmaster_hurls", 0.0)), int(st.get("harbourmaster_drags", 0.0)),
			int(st.get("harbourmaster_reels", 0.0)), int(st.get("harbourmaster_player_drags", 0.0)), int(st.get("harbourmaster_kills", 0.0)),
			float(st.get("harbourmaster_ttk", 0.0)) / maxf(1.0, float(st.get("harbourmaster_kills", 0.0))),
			int(st.get("player_dmg_from_deep_kin_leap", 0.0)), int(st.get("player_dmg_from_tide_wall", 0.0)), int(st.get("player_dmg_from_netcaster_net", 0.0)),
			int(st.get("player_dmg_from_harbourmaster_sweep", 0.0)), int(st.get("player_dmg_from_harbourmaster_hurl", 0.0))])
	if String(en.boss_info.get("id", "")) == "merrow" and en.boss != null:
		print("[autotest] merrow: %s" % BossMerrow.summary_line(st))
	var ab := game.abilities
	for id: String in NecroSpellBook.ACT2_IDS:
		var line := ab.spells.act2_summary(id)
		if line != "":
			print("[autotest] act II spell: %s" % line)
	var salt := ab.passive_level("salt_of_the_deep")
	var brine := ab.passive_level("brinewalker")
	if salt > 0 or brine > 0:
		print("[autotest] act II passives: salt_of_the_deep Lv%d bonus_dmg=%d | brinewalker Lv%d (water slow on you resisted %.0f s, summons helped from Lv %d) | riptide extra shallows %d" % [
			salt, int(st.get("salt_bonus_dmg", 0.0)), brine, float(st.get("tide_player_wet_resisted_s", 0.0)),
			PassiveData.BRINEWALKER_SUMMON_LEVEL, int(st.get("riptide_extra_shallows", 0.0))])
