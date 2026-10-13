## SaveMigration: carries a player's save over the game's rename from its working
## title Gravebound to Necropathy (owner decision, Oct 2026; GDD §15.0 "Title").
## Godot keeps user:// in a folder named after the project
## (".../app_userdata/<config/name>"), so renaming the project would start every
## playtester on a fresh profile. On the first Necropathy launch, when the new
## folder holds neither save file, the files are COPIED from the sibling
## Gravebound folder (the old folder stays as a backup). Runs once per launch
## from GameState._ready(), before Settings and Meta load; never in the
## autotest, which must not touch user://. Purely file handling: no gameplay.
class_name SaveMigration
extends RefCounted

## Folder name (under the same app_userdata parent) of the pre-rename saves.
const LEGACY_DIR_NAME: String = "Gravebound"
## Files carried over, relative to user:// (Meta's profile and the Settings file).
const FILES: Array[String] = ["save.cfg", "settings.cfg"]


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
