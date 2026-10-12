## GameState — the only autoload. It is justified because it holds state that
## must survive the Game node being freed and rebuilt (restart / main menu):
##   * launch options parsed from the command line (autotest mode),
##   * per-session preferences (debug overlay visibility),
##   * a summary of the last finished run (for the end screen / autotest).
## Gameplay systems do NOT talk through this node; they hold direct typed
## references owned by Game and use their own signals.
##
## Command-line options (pass after `--`, e.g. `godot -- --autotest`):
##   --autotest            Skip the menu, start a run, auto-pick cards,
##                         fast-forward and print a summary, then quit.
##   --mortal              Autotest player can die (default: invulnerable so
##                         the whole 20-minute timeline + boss are exercised).
##   --speed=N             Autotest time scale (default 8; the results are
##                         identical at any speed up to 8, only the frame
##                         count changes).
##   --seed=N              RNG seed for the autotest run (default 1337).
##   --timeout=N           Autotest gives up after N game seconds (default
##                         1500: the 20:00 countdown plus the Reckoning).
##   --policy=NAME         Autotest card policy: "naive" (default; new summon
##                         classes, then new spells, then new passives) or
##                         "army" (summoner build: summon levels and army
##                         passives first, then Shadow Bolt / Blast) or
##                         "evolve" (spell build that chases the three
##                         spell evolutions) or "summon" (summoner build that
##                         chases the Death Knight, Lich and Profane Bishop
##                         summon evolutions) or "pact" (the naive build that
##                         also takes every Profane Pact card at once, to
##                         measure the Pact; the other policies rank the
##                         Pact below every card, fallbacks included).
##   --meta=PROFILE        Autotest Soul Ash upgrades, applied in memory only:
##                         "none" (default, no upgrades), "mid" or "max"
##                         (MetaData.AUTOTEST_PROFILES).
##   --meta-save           Test flag: lets the autotest read and write
##                         user://save.cfg (by default it never touches it).
##   --oath=N              Autotest active Profane Oath tier 0-5 (default 0;
##                         no --meta profile includes the Oath).
##   --pact                Any policy also takes every Profane Pact card at
##                         once (e.g. --policy=army --pact: a strong build
##                         with the Pact); --policy=pact is naive + --pact.
##   --classes=a,b         Forces summon classes (UnitData ids, e.g.
##                         abomination,rogue,gargoyle,frost_wraith or
##                         bone_hound,banshee,corpse_catapult): each is
##                         raised to Lv 1 at the start (while active slots
##                         allow) and every policy upgrades it first, so its
##                         special gets exercised. Unknown ids and the
##                         evolution-only "bishop" are ignored.
##   --spells=a,b,...      Any policy first takes these spells (AbilityData
##                         ids, e.g. bone_spear,plague_cloud) and their
##                         evolution passives, so each spell can be exercised
##                         and its evolution reached.
##   --passives=a,b,...    Any policy first takes these passives (PassiveData
##                         ids, e.g. unholy_precision,unholy_resilience) the
##                         same way as the --spells items, so a passive's
##                         effect can be exercised.
##   --stage=ID           Autotest stage: "graveyard" (default),
##                         "crimson_march" or "sanctum" (StageRegistry ids;
##                         stage locks are ignored).
##   --boss=ID             Autotest boss test: puts boss ID ("alaric", "vael"
##                         or "seraphine"; StageRegistry.BOSS_ARRIVALS) in
##                         the stage's boss slot at the stage's boss time,
##                         e.g. --boss=seraphine on the Graveyard.
##   --difficulty=ID      Autotest difficulty level (GDD §8.4, DifficultyData
##                         ids or names, any case): initiate, necromancer
##                         (default, today's game), lich or deathlord.
##   --modifiers=a,b       Autotest run modifiers (GDD §8.5, RunModifierData
##                         ids): endless_crusade, hardened_faith, divine_fury,
##                         purge_the_unholy, scarcity, frail_master,
##                         vengeful_dead, holy_retribution; "all" = every one.
##   --hyper               Autotest Hyper mode (HyperData: enemy HP / damage
##                         growth x2, stage boss HP x1.5, Soul Ash +100%);
##                         bypasses the Seraphine unlock.
##   --skin=ID             Autotest skin (SkinData id, e.g. dread_sovereign
##                         or gravecaller_hyper), forced for screenshots:
##                         ignores the unlock and the character. Cosmetic.
##   --stance=ID           Autotest army stance for the whole run (StanceData
##                         ids: escort, onslaught, spearhead, bone_ring);
##                         forcing ignores the Spearhead unlock. Without it,
##                         army / summon / evolve switch stances (StanceBot)
##                         and naive / pact keep Escort.
##   --spawn=k@T[xN],...   Autotest test hook: force-spawns N (default 1)
##                         enemies of kind k (any stage's data: EnemyData,
##                         MarchEnemyData or SanctumEnemyData ids) at T game
##                         seconds, in an arc on the spawn ring, on any
##                         stage, e.g. --spawn=sanctified_sentinel@120x3,
##                         high_confessor@180x2,cathedral_guardian@300.
##   --character=ID        Autotest playable character (CharacterData ids:
##                         gravecaller (default, today's game),
##                         umbral_warden, voidcaller, bone_oracle,
##                         fallen_confessor, carrion_lord, plague_scholar,
##                         doomsayer, barrow_warden, soulbinder,
##                         wither_witch, grave_herald); locks are bypassed.
##                         An unknown id (or one whose starting spell is not
##                         in the build) is refused with an error and the
##                         default is played.
## The environment variable GRAVEBOUND_AUTOTEST=1 is equivalent to --autotest.
extends Node

## True when the game runs the headless self-test instead of the menu.
var autotest: bool = false
## Autotest: if true the necromancer can die (balance check run).
var autotest_mortal: bool = false
## Autotest: Engine.time_scale multiplier (1 = real time).
var autotest_speed: float = 8.0
## Autotest: seed for the global RNG so runs are reproducible.
var autotest_seed: int = 1337
## Autotest: game-time limit in seconds before the test aborts.
var autotest_timeout: float = 1500.0
## Autotest: level-up card policy, "naive", "army", "evolve", "summon" or "pact" (see header).
var autotest_policy: String = "naive"
## Autotest: simulated meta-upgrade profile, "none", "mid" or "max" (see header).
var autotest_meta: String = "none"
## Autotest: true when --meta-save allows the run to use user://save.cfg.
var autotest_meta_save: bool = false
## Autotest: active Profane Oath tier (--oath=N, 0 = off).
var autotest_oath: int = 0
## Autotest: true when --pact makes the policy take every Profane Pact card.
var autotest_pact: bool = false
## Autotest: summon class ids forced by --classes=a,b (empty = none).
var autotest_classes: PackedStringArray = PackedStringArray()
## Autotest: spell ids from --spells=a,b the policy takes first (with their
## evolution passives); empty = none forced.
var autotest_spells: PackedStringArray = PackedStringArray()
## Autotest: passive ids from --passives=a,b the policy takes first; empty =
## none forced.
var autotest_passives: PackedStringArray = PackedStringArray()
## Autotest: StageRegistry id of the stage to play (--stage=, locks ignored).
var autotest_stage: String = StageRegistry.DEFAULT_ID
## Autotest: StageRegistry.BOSS_ARRIVALS id replacing the stage's boss
## (--boss=; "" = the stage's own boss).
var autotest_boss: String = ""
## Autotest: DifficultyData id of the difficulty level (--difficulty=).
var autotest_difficulty: String = DifficultyData.DEFAULT_ID
## Autotest: RunModifierData ids of the run modifiers (--modifiers=a,b).
var autotest_modifiers: PackedStringArray = PackedStringArray()
## Autotest: true when --hyper turns Hyper mode on (lock bypassed).
var autotest_hyper: bool = false
## Autotest: SkinData id forced by --skin= ("" = the default look).
var autotest_skin: String = ""
## Autotest: StanceData id forced for the whole run by --stance= ("" = the
## stance bot's rule, StanceBot).
var autotest_stance: String = ""
## Autotest: forced spawns from --spawn= ({"kind", "time" s, "count"}, in
## the order given; empty = none).
var autotest_spawns: Array[Dictionary] = []
## Autotest: CharacterData id of the playable character (--character=;
## locks bypassed, only characters whose starting spell exists).
var autotest_character: String = CharacterData.DEFAULT_ID
## Stage chosen last in the stage select this session (focused next time).
var last_stage_id: String = StageRegistry.DEFAULT_ID
## Whether the F3 debug overlay is shown; persists across restarts.
var debug_overlay_visible: bool = false
## Summary dictionary of the most recent finished run (see Game.build_summary).
var last_run_summary: Dictionary = {}


func _ready() -> void:
	_parse_args(OS.get_cmdline_user_args())
	if OS.get_environment("GRAVEBOUND_AUTOTEST") == "1":
		autotest = true


## Parses user command-line arguments (the ones after `--`).
func _parse_args(args: PackedStringArray) -> void:
	for arg: String in args:
		if arg == "--autotest":
			autotest = true
		elif arg == "--mortal":
			autotest_mortal = true
		elif arg.begins_with("--speed="):
			autotest_speed = clampf(arg.get_slice("=", 1).to_float(), 0.25, 32.0)
		elif arg.begins_with("--seed="):
			autotest_seed = arg.get_slice("=", 1).to_int()
		elif arg.begins_with("--timeout="):
			autotest_timeout = maxf(30.0, arg.get_slice("=", 1).to_float())
		elif arg.begins_with("--policy="):
			autotest_policy = arg.get_slice("=", 1)
		elif arg.begins_with("--meta="):
			var profile := arg.get_slice("=", 1)
			autotest_meta = profile if profile in MetaData.AUTOTEST_PROFILES else "none"
		elif arg == "--meta-save":
			autotest_meta_save = true
		elif arg == "--pact":
			autotest_pact = true
		elif arg.begins_with("--spells="):
			for id: String in arg.get_slice("=", 1).split(",", false):
				if id in AbilityData.SPELL_ORDER:
					autotest_spells.append(id)
				else:
					push_warning("--spells: unknown spell id '%s' ignored" % id)
		elif arg.begins_with("--passives="):
			for id: String in arg.get_slice("=", 1).split(",", false):
				if PassiveData.PASSIVES.has(id) and id != PactData.ID:
					autotest_passives.append(id)
				else:
					push_warning("--passives: unknown passive id '%s' ignored" % id)
		elif arg.begins_with("--stage="):
			var id := arg.get_slice("=", 1)  # Requested stage id.
			if StageRegistry.STAGES.has(id):
				autotest_stage = id
			else:
				push_error("Unknown --stage=%s (expected one of %s)" % [id, ", ".join(PackedStringArray(StageRegistry.ORDER))])
		elif arg.begins_with("--boss="):
			var bid := arg.get_slice("=", 1).to_lower()  # Requested boss id.
			if StageRegistry.BOSS_ARRIVALS.has(bid):
				autotest_boss = bid
			else:
				push_error("Unknown --boss=%s (expected one of %s)" % [bid, ", ".join(PackedStringArray(StageRegistry.BOSS_ARRIVALS.keys()))])
		elif arg.begins_with("--difficulty="):
			var want := arg.get_slice("=", 1).to_lower()  # Requested level (id or name).
			var found := ""  # Matching DifficultyData id.
			for id: String in DifficultyData.ORDER:
				if id == want or String(DifficultyData.LEVELS[id]["display_name"]).to_lower() == want:
					found = id
			if found != "":
				autotest_difficulty = found
			else:
				push_error("Unknown --difficulty=%s (expected one of %s)" % [want, ", ".join(PackedStringArray(DifficultyData.ORDER))])
		elif arg.begins_with("--modifiers="):
			for id: String in arg.get_slice("=", 1).to_lower().split(",", false):
				if id == "all":
					autotest_modifiers = PackedStringArray(RunModifierData.ORDER)
				elif RunModifierData.MODIFIERS.has(id):
					if not autotest_modifiers.has(id):
						autotest_modifiers.append(id)
				else:
					push_error("Unknown --modifiers id '%s' (expected %s or all)" % [id, ", ".join(PackedStringArray(RunModifierData.ORDER))])
		elif arg.begins_with("--oath="):
			autotest_oath = clampi(arg.get_slice("=", 1).to_int(), 0, MetaData.max_tier(PactData.OATH_ID))
		elif arg == "--hyper":
			autotest_hyper = true
		elif arg.begins_with("--skin="):
			var skid := arg.get_slice("=", 1).to_lower()  # Requested skin id.
			if SkinData.has(skid):
				autotest_skin = skid
			else:
				push_error("Unknown --skin=%s (expected one of %s)" % [skid, ", ".join(SkinData.all_ids())])
		elif arg.begins_with("--stance="):
			var sid := arg.get_slice("=", 1).to_lower()  # Requested stance id.
			if StanceData.STANCES.has(sid):
				autotest_stance = sid
			else:
				push_error("Unknown --stance=%s (expected one of %s)" % [sid, ", ".join(PackedStringArray(StanceData.ORDER))])
		elif arg.begins_with("--spawn="):
			for entry: String in arg.get_slice("=", 1).split(",", false):
				var kind := entry.get_slice("@", 0)  # Enemy kind id.
				var rest := entry.get_slice("@", 1) if entry.contains("@") else "0"  # "T" or "TxN".
				var count := int(rest.get_slice("x", 1)) if rest.contains("x") else 1  # How many.
				if EnemyDirector.is_known_kind(kind) and count > 0:
					autotest_spawns.append({"kind": kind, "time": rest.get_slice("x", 0).to_float(), "count": count})
				else:
					push_error("--spawn: bad entry '%s' (expected kind@seconds[xcount] with a known enemy kind)" % entry)
		elif arg.begins_with("--character="):
			var cid := arg.get_slice("=", 1).to_lower()  # Requested character id.
			if not CharacterModifiers.is_known(cid):
				push_error("Unknown --character=%s (expected one of %s)" % [cid, ", ".join(CharacterModifiers.available_ids())])
			elif not CharacterModifiers.is_available(cid):
				push_error("--character=%s is not playable in this build: its starting spell '%s' does not exist yet (playable: %s); playing %s" % [
					cid, String(CharacterData.CHARACTERS[cid]["spell"]), ", ".join(CharacterModifiers.available_ids()), CharacterData.DEFAULT_ID])
			else:
				autotest_character = cid
		elif arg.begins_with("--classes="):
			for cls: String in arg.get_slice("=", 1).split(",", false):
				# Evolution-only classes (the Profane Bishop) cannot be forced.
				if UnitData.UNITS.has(cls) and not autotest_classes.has(cls) \
						and not bool(UnitData.UNITS[cls].get("evolved_only", false)):
					autotest_classes.append(cls)
