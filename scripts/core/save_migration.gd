## SaveMigration: carries a player's save over the game's rename from its working
## title Gravebound to Necropathy (owner decision, Oct 2026; GDD §15.0 "Title").
## Godot keeps user:// in a folder named after the project
## (".../app_userdata/<config/name>"), so renaming the project would start every
## playtester on a fresh profile. On the first Necropathy launch, when the new
## folder holds neither save file, the files are COPIED from the sibling
## Gravebound folder (the old folder stays as a backup). Runs once per launch
## from GameState._ready(), before Settings and Meta load; never in the
## autotest, which must not touch user://. Purely file handling: no gameplay.
## The reorder pass (part 1, save version 3) adds legacy_opened(): the stages a
## save had opened under the act order before the reorder, which Meta keeps
## open (Meta._migrate(), [stages] opened); checked by
## tools/save_migration_check.tscn.
class_name SaveMigration
extends RefCounted

## Folder name (under the same app_userdata parent) of the pre-rename saves.
const LEGACY_DIR_NAME: String = "Gravebound"
## Files carried over, relative to user:// (Meta's profile and the Settings file).
const FILES: Array[String] = ["save.cfg", "settings.cfg"]
## The campaign order before the reorder pass (save versions 0-2): each stage
## opened once the boss of the stage before it here was slain once. Only
## legacy_opened() reads it; nothing in a run does.
const LEGACY_ORDER: Array[String] = ["graveyard", "crimson_march", "sanctum", "harbour", "archive", "spire",
	"wastes", "assembly", "citadel", "ilion", "olympus", "underworld", "province", "kurogane", "sun_road",
	"burning_gate", "silk_palace", "pandemonium", "ravensmoor", "witchwood", "castle_sanguis",
	"skid_row", "fort_kessler", "liberty_heights", "crash_site", "proving_moon", "ark",
	"cutter", "galleon", "maelstrom", "barrow_fields", "valgard", "vigrid",
	"necropolis", "lioness_temple", "two_truths", "silver_stair", "wheel_of_thrones", "empyrean",
	"fern_basin", "great_plain", "last_day", "greenwood", "fae_court", "world_tree"]


## Stage ids an older save (`cfg`, its [stages] "<id>_boss_kills" records) had
## opened under LEGACY_ORDER: the first stage and every stage whose legacy
## predecessor's boss fell at least StageRegistry.UNLOCK_BOSS_KILLS times.
## A save from before [stages] existed opened the Crimson March through the
## lifetime boss kills (Meta rebuilds its Graveyard record from them).
static func legacy_opened(cfg: ConfigFile) -> PackedStringArray:
	var out := PackedStringArray([LEGACY_ORDER[0]])
	var need := float(StageRegistry.UNLOCK_BOSS_KILLS)  # Boss kills that opened the next stage.
	for i in range(1, LEGACY_ORDER.size()):
		var kills: Variant = cfg.get_value("stages", "%s_boss_kills" % LEGACY_ORDER[i - 1], 0.0)
		if i == 1 and not cfg.has_section("stages"):
			kills = cfg.get_value("lifetime", "boss_kills", 0.0)
		if (typeof(kills) == TYPE_FLOAT or typeof(kills) == TYPE_INT) and float(kills) >= need:
			out.append(LEGACY_ORDER[i])
	return out


## Copies FILES from the legacy folder when this install has none of them yet.
## Returns how many files were copied (0 when nothing needed or could be done).
static func run() -> int:
	for f: String in FILES:
		if FileAccess.file_exists("user://" + f):
			return 0  # This install already has its own data: never overwrite it.
	var new_dir := OS.get_user_data_dir()  # Absolute path of user:// for Necropathy.
	var old_dir := new_dir.get_base_dir().path_join(LEGACY_DIR_NAME)  # The Gravebound sibling folder.
	if old_dir == new_dir or not DirAccess.dir_exists_absolute(old_dir):
		return 0
	DirAccess.make_dir_recursive_absolute(new_dir)
	var copied := 0  # Files copied so far.
	for f: String in FILES:
		var src := old_dir.path_join(f)  # Legacy file.
		if FileAccess.file_exists(src) and DirAccess.copy_absolute(src, new_dir.path_join(f)) == OK:
			copied += 1
	if copied > 0:
		print("[save] carried %d file(s) over from %s (the Gravebound saves)" % [copied, old_dir])
	return copied
