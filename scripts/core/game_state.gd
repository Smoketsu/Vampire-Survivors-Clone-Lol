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
##                         abomination,rogue,gargoyle,frost_wraith): each is
##                         raised to Lv 1 at the start (while active slots
##                         allow) and every policy upgrades it first, so its
##                         special gets exercised. Unknown ids and the
##                         evolution-only "bishop" are ignored.
##   --spells=a,b,...      Any policy first takes these spells (AbilityData
##                         ids, e.g. bone_spear,plague_cloud) and their
##                         evolution passives, so each spell can be exercised
##                         and its evolution reached.
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
		elif arg.begins_with("--oath="):
			autotest_oath = clampi(arg.get_slice("=", 1).to_int(), 0, MetaData.max_tier(PactData.OATH_ID))
		elif arg.begins_with("--classes="):
			for cls: String in arg.get_slice("=", 1).split(",", false):
				# Evolution-only classes (the Profane Bishop) cannot be forced.
				if UnitData.UNITS.has(cls) and not autotest_classes.has(cls) \
						and not bool(UnitData.UNITS[cls].get("evolved_only", false)):
					autotest_classes.append(cls)
