## CorsairReport — the autotest summary lines of the Black Tide's shared rules
## and stages (Act X; GDD §15.0 "Act X foundation: the Black Tide (phase 1)"),
## called once by Autotest.finish(). Every line prints only when the Black Tide
## ran this run (Game.corsair exists: an Act X stage, or a Black Tide kind forced
## onto another stage with --spawn=), so the Act I to IX summaries keep their
## exact text:
##   boarding:      BoardingParty (boats launched by size, hooked, repelled,
##                  sunk, emptied; crew aboard, cancelled, drowned with their
##                  boat; the queue's peak and refusals; peak boats; hooks cut)
##   deck:          DeckBounds (enemies overboard by kind, clamps of the
##                  necromancer / summons / enemies, fliers pulled back, drops
##                  moved, the ring posts' slide, powder blasts)
##   sea strikes:   SeaStrikes (swimmers, refused at the cap, peak alive,
##                  strikes by type, leaps landed, grabs, rescues, dragged
##                  overboard, hits on summons / you and the damage, enemy damage)
##   black tide:    BlackTide (only once the Reckoning ran: rail strikes,
##                  waves, enemies shoved, drowned by the waves)
##   corsair kinds: spawns / kills of every Black Tide kind that spawned, its
##                  first appearance, its damage to the necromancer and to summons
##   corsair stage: the Act X stage itself (stub status, deck, boss, Soul Ash,
##                  the Reckoning)
## Phase 2 adds one line per stage system here (each stage in its own block):
## the Smuggler's Cutter's are CutterReport's (cutter, cutter crew, bosun
## gorran, captain crow).
## Read-only: it never changes the run.
class_name CorsairReport
extends RefCounted


## Prints every line that applies to this run.
static func print_lines(game: Game, st: Dictionary) -> void:
	var c := game.corsair  # The Black Tide's rules (null when they never ran).
	if c == null:
		return
	if c.enabled:
		print("[autotest] boarding: %s" % boarding_line(game, st))
		print("[autotest] deck: %s" % deck_line(game, st))
		print("[autotest] sea strikes: %s" % sea_line(game, st))
		if c.tide.running():
			print("[autotest] black tide: began %s | rail strikes %d | waves %d (enemies shoved %d, drowned by the waves %d)" % [
				EmpireReport._clock(c.tide.started_at), c.tide.strikes, c.tide.waves, int(st.get("black_tide_wave_pushes", 0.0)),
				int(st.get("black_tide_drowned", 0.0))])
	var kinds := kinds_line_of(game, st)
	if kinds != "":
		print("[autotest] corsair kinds (spawned/killed): %s" % kinds)
	var sd := game.stage_def  # The run's stage.
	if StageRegistry.act_of(String(sd["id"])) == 10:
		var boss: Dictionary = sd["boss"]
		var dk: Dictionary = sd.get("deck", {})
		print("[autotest] corsair stage: %s (%s) | playable %s | deck %d x %d | boss %s (script %s) | enemy x%.2f HP / x%.2f dmg from %s | soul ash x%.2f | reckoning kind %s, black tide %s" % [
			String(sd["id"]), String(sd["display_name"]), str(StageRegistry.is_playable(String(sd["id"]))),
			int(dk.get("length", 0.0)), int(dk.get("beam", 0.0)),
			String(boss["id"]), String(boss.get("script", boss["id"])), float(sd["enemy_hp_mult"]), float(sd["enemy_damage_mult"]),
			EmpireReport._clock(float(sd.get("enemy_mult_from", 0.0))), float(sd["ash_mult"]),
			String((sd["reckoning"] as Dictionary).get("kind", "inquisitor")), str(c.tide.enabled)])
	# Phase 2: each Act X stage's own lines go here (its stage, kinds and boss).
	# --- Act X: the Smuggler's Cutter ---
	CutterReport.print_lines(game, st)  # The barrels, fog, Gorran's ram, the Fire Ship; the Grappler and Boatswain; Gorran; Crow.
	# --- Act X: the Treasure Galleon --- (zones, broadsides, deck cannons, gunboats, Old Hollow-Eye, Marrec; GalleonReport)
	GalleonReport.print_lines(game, st)


## The "boarding" line (BoardingParty).
static func boarding_line(game: Game, st: Dictionary) -> String:
	var b := game.corsair.boarding
	var by := PackedStringArray()
	for s: String in CorsairRulesData.BOAT_ORDER:
		if st.has("boats_" + s):
			by.append("%s %d" % [s, int(st["boats_" + s])])
	return "boats %d (%s) | hooked %d | repelled %d | sunk %d | emptied %d | crew aboard %d, cancelled %d, drowned with their boat %d | queue peak %d, refused %d, waiting at the end %d | peak boats %d | hooks cut %d" % [
		b.launched, ", ".join(by) if not by.is_empty() else "-", int(st.get("boats_hooked", 0.0)), int(st.get("boats_repelled", 0.0)),
		int(st.get("boats_sunk", 0.0)), int(st.get("boats_emptied", 0.0)), b.aboard, int(st.get("crew_cancelled", 0.0)),
		int(st.get("crew_drowned", 0.0)), b.peak_queue, int(st.get("boarding_refused", 0.0)), b.waiting(), b.peak_boats,
		int(st.get("hooks_cut", 0.0))]


## The "deck" line (DeckBounds).
static func deck_line(game: Game, st: Dictionary) -> String:
	var parts := PackedStringArray()
	for k: String in st:
		if k.begins_with("overboard_") and k != "overboard_total" and k != "overboard_survived":
			parts.append("%s %d" % [k.substr(10), int(st[k])])
	parts.sort()
	var d := game.deck
	return "overboard %d (%s) | ring posts %d, slid inboard %d (%.0f%%) | clamps: you %d, summons %d, enemies %d | fliers pulled back %d | drops moved %d | powder blasts %d (fuses %d, enemy dmg %d) | swashbuckler lunges %d" % [
		int(st.get("overboard_total", 0.0)), ", ".join(parts) if not parts.is_empty() else "-", d.posts, d.posts_slid,
		100.0 * float(d.posts_slid) / maxf(1.0, float(d.posts)), int(st.get("deck_clamps_player", 0.0)),
		int(st.get("deck_clamps_summons", 0.0)), int(st.get("deck_clamps_enemies", 0.0)), int(st.get("deck_flier_pulls", 0.0)),
		int(st.get("deck_drops_moved", 0.0)), int(st.get("powder_blasts", 0.0)), int(st.get("powder_fuses", 0.0)),
		int(st.get("powder_enemy_dmg", 0.0)), int(st.get("swashbuckler_lunges", 0.0))]


## The "sea strikes" line (SeaStrikes).
static func sea_line(game: Game, st: Dictionary) -> String:
	var s := game.corsair.sea
	return "swimmers %d (refused at the cap %d, peak alive %d) | strikes: leap %d, tentacle %d, sea %d | leaps landed %d | grabs %d, rescued %d, dragged overboard %d | hits on summons %d (dmg %d), on you %d (dmg %d) | enemy dmg %d" % [
		int(st.get("sea_swimmers", 0.0)), int(st.get("sea_refused_cap", 0.0)), s.peak, int(st.get("sea_strikes_leap", 0.0)),
		int(st.get("sea_strikes_tentacle", 0.0)), int(st.get("sea_strikes_sea", 0.0)), int(st.get("sea_leaps_landed", 0.0)),
		int(st.get("sea_grabs", 0.0)), int(st.get("sea_grab_rescues", 0.0)), int(st.get("sea_dragged", 0.0)),
		int(st.get("sea_strike_hits_summons", 0.0)), int(st.get("summon_dmg_from_" + CorsairRulesData.STRIKE_SOURCE, 0.0)),
		int(st.get("sea_strike_hits_you", 0.0)), int(st.get("player_dmg_from_" + CorsairRulesData.STRIKE_SOURCE, 0.0)),
		int(st.get("sea_strike_enemy_dmg", 0.0))]


## The "corsair kinds" line: every Black Tide kind that spawned ("" when none did).
static func kinds_line_of(game: Game, st: Dictionary) -> String:
	var c := game.corsair
	var parts := PackedStringArray()
	for table: Dictionary in [CorsairEnemyData.ENEMIES, CutterEnemyData.ENEMIES, GalleonEnemyData.ENEMIES, MaelstromEnemyData.ENEMIES]:
		for k: String in table:
			var spawned := int(st.get("spawned_" + k, 0.0))
			var killed := int(st.get("kill_" + k, 0.0))
			if spawned > 0 or killed > 0:
				var first := EmpireReport._clock(float(c.first_seen[k])) if c.first_seen.has(k) else "-"
				parts.append("%s %d/%d first %s (dmg to you %d, to summons %d)" % [k, spawned, killed, first,
					int(st.get("player_dmg_from_" + k, 0.0)), int(st.get("summon_dmg_from_" + k, 0.0))])
	return " | ".join(parts)
