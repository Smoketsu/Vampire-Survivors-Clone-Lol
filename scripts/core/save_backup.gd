## SaveBackup: the save code behind Settings -> Save (GDD §15.0 "Save backup codes and the
## GitHub Pages build"). A save code is the player's whole progress file (Meta's
## user://save.cfg: Soul Ash, upgrades, unlocks, records, Codex) gzipped and written as
## base64 behind SaveBackupData.CODE_PREFIX, so it can be copied out of one browser or
## computer and pasted into another. It exists for iPhone Safari, which keeps an embedded
## page's storage (the itch.io game frame) only until Safari closes; it also moves a profile
## between the desktop build and a browser. Settings (volumes, keys) are not part of a code:
## they belong to the device.
## Moving the code in and out of the game:
##   * Web build: Backup tries the browser clipboard and falls back to a native prompt box
##     that shows the code, selected for copying; Restore reads it from a native prompt box
##     (window.prompt needs no user gesture, unlike the clipboard API, and runs inside the
##     game's frame on itch.io too).
##   * Desktop: the system clipboard (Backup copies, Restore reads what was copied).
## Restoring validates the code (prefix, base64, gzip, a ConfigFile with a save version)
## before anything is written, writes the file like Meta.save() does (temp file + rename),
## then reloads it through Meta.load_save(), the one load path. Never under the autotest
## (Meta.can_write() is false there). Static helpers only; no state, no gameplay.
class_name SaveBackup
extends RefCounted


## The current progress as a save code ("" when there is nothing to back up yet).
## Writes Meta first, so the code holds exactly what is in memory.
static func export_code() -> String:
	if Meta.can_write():
		Meta.save()
	if not FileAccess.file_exists(Meta.save_path):
		return ""
	var raw := FileAccess.get_file_as_bytes(Meta.save_path)  # The save file's bytes (ConfigFile text).
	if raw.is_empty():
		return ""
	var packed := raw.compress(FileAccess.COMPRESSION_GZIP)  # Gzipped save file.
	return SaveBackupData.CODE_PREFIX + Marshalls.raw_to_base64(packed)


## Decodes `code` into the save file's text, or "" when it is not a valid save code
## (wrong prefix, bad base64 or gzip, not a ConfigFile, no save version).
static func decode(code: String) -> String:
	if code.length() > SaveBackupData.MAX_CODE_CHARS:
		return ""  # Far longer than any save: refused before it is copied or decoded.
	var c := code.strip_edges().replace(" ", "").replace("\n", "").replace("\r", "")  # Pasted code, whitespace removed.
	if not c.begins_with(SaveBackupData.CODE_PREFIX):
		return ""
	var b64 := c.substr(SaveBackupData.CODE_PREFIX.length())  # The base64 part.
	# Checked first: the engine's decoder logs an error for text that is not base64.
	var re := RegEx.create_from_string("^[A-Za-z0-9+/]+={0,2}$")  # Base64 alphabet with padding.
	if b64.length() % 4 != 0 or re.search(b64) == null:
		return ""
	var packed := Marshalls.base64_to_raw(b64)  # Gzipped bytes.
	if packed.is_empty():
		return ""
	var raw := packed.decompress_dynamic(SaveBackupData.MAX_SAVE_BYTES, FileAccess.COMPRESSION_GZIP)  # ConfigFile bytes.
	if raw.is_empty():
		return ""
	var text := raw.get_string_from_utf8()  # The save file's text.
	for bad: String in SaveBackupData.FORBIDDEN_TOKENS:
		if text.contains(bad):
			return ""  # An object or resource constructor: never in a real save.
	var cfg := ConfigFile.new()
	if cfg.parse(text) != OK or not cfg.has_section_key("meta", "save_version"):
		return ""
	if cfg.get_sections().size() < 2:
		return ""  # Only a version: a code like that would wipe the profile.
	return text


## True when save text `text` (from decode()) was written by a newer version of the
## game than this one (MetaData.SAVE_VERSION): such a code is refused, never cut
## down to what this version knows (adversarial review, Fix 3).
static func is_newer(text: String) -> bool:
	var cfg := ConfigFile.new()
	if cfg.parse(text) != OK:
		return false
	var v: Variant = cfg.get_value("meta", "save_version", 0)  # The code's save format version.
	return (v is int or v is float) and int(v) > MetaData.SAVE_VERSION


## SaveBackupData.SUMMARY for save text `text` (from decode()): its Soul Ash and runs.
static func summary(text: String) -> String:
	var cfg := ConfigFile.new()
	if cfg.parse(text) != OK:
		return ""
	var ash: Variant = cfg.get_value("currency", "soul_ash", 0)  # Soul Ash the code holds.
	var runs: Variant = cfg.get_value("lifetime", "runs", 0)  # Runs finished in the code.
	return SaveBackupData.SUMMARY % [int(ash) if (ash is int or ash is float) else 0, int(runs) if (runs is int or runs is float) else 0]


## Replaces the progress with the save in `code` and reloads it. Returns OK, or
## ERR_INVALID_DATA for a code that is not a save, ERR_UNAVAILABLE when saving is off
## (the autotest), or the file error.
static func import_code(code: String) -> Error:
	if not Meta.mode_allows_write():
		return ERR_UNAVAILABLE
	var text := decode(code)  # The validated save file text.
	if text == "" or is_newer(text):
		return ERR_INVALID_DATA
	return _replace_save(text, true)


## Undo of the last restore: puts back the progress it replaced (the
## PRE_RESTORE_SUFFIX copy), keeping the restored one as the new copy, so Undo
## twice is a redo. ERR_FILE_NOT_FOUND when no restore was made on this device.
static func undo_restore() -> Error:
	if not Meta.mode_allows_write():
		return ERR_UNAVAILABLE
	var keep := Meta.save_path + SaveBackupData.PRE_RESTORE_SUFFIX  # The progress the last restore replaced.
	if not FileAccess.file_exists(keep):
		return ERR_FILE_NOT_FOUND
	var text := FileAccess.get_file_as_string(keep)  # Its save text.
	if text == "":
		return ERR_FILE_NOT_FOUND
	return _replace_save(text, true)


## Writes save text `text` over the progress and reloads it; with `keep_old`, the
## current save file is first copied to the PRE_RESTORE_SUFFIX file (Undo).
static func _replace_save(text: String, keep_old: bool) -> Error:
	if keep_old and FileAccess.file_exists(Meta.save_path):
		var old := FileAccess.get_file_as_string(Meta.save_path)  # The progress being replaced.
		var k := FileAccess.open(Meta.save_path + SaveBackupData.PRE_RESTORE_SUFFIX, FileAccess.WRITE)
		if k == null:
			return FileAccess.get_open_error()  # No undo copy: nothing is replaced.
		k.store_string(old)
		k.close()
	var tmp := Meta.save_path + ".tmp"  # Written first, then renamed over the save.
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(text)
	f.close()
	if DirAccess.rename_absolute(tmp, Meta.save_path) != OK:
		DirAccess.remove_absolute(tmp)
		var g := FileAccess.open(Meta.save_path, FileAccess.WRITE)
		if g == null:
			return FileAccess.get_open_error()
		g.store_string(text)
		g.close()
	Meta.load_save()
	return OK


## Hands `code` to the player: the clipboard, or (Web build, clipboard refused) a native
## prompt box showing the code for copying. Web build: the clipboard's answer comes later,
## so copied_on_web() reports it a moment after.
static func give_to_player(code: String) -> void:
	if OS.has_feature("web"):
		var js := "(function (c, m) { window.__necroCopied = 0; try { if (navigator.clipboard && navigator.clipboard.writeText) { navigator.clipboard.writeText(c).then(function () { window.__necroCopied = 1; }, function () { window.prompt(m, c); window.__necroCopied = 2; }); return; } } catch (e) {} window.prompt(m, c); window.__necroCopied = 2; })(%s, %s)" % [JSON.stringify(code), JSON.stringify(SaveBackupData.PROMPT_COPY)]
		JavaScriptBridge.eval(js, true)
	else:
		DisplayServer.clipboard_set(code)


## Web build: 1 when give_to_player()'s clipboard write succeeded, 2 when the prompt box
## showed the code instead, 0 while the browser has not answered. Desktop: always 1.
static func copied_on_web() -> int:
	if not OS.has_feature("web"):
		return 1
	var v: Variant = JavaScriptBridge.eval("window.__necroCopied || 0", true)
	return int(v) if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT else 0


## Asks the player for a save code: a native prompt box on the Web build, the system
## clipboard on desktop. "" when nothing was given.
static func ask_player() -> String:
	if OS.has_feature("web"):
		var v: Variant = JavaScriptBridge.eval("window.prompt(%s, '') || ''" % JSON.stringify(SaveBackupData.PROMPT_PASTE), true)
		return String(v) if typeof(v) == TYPE_STRING else ""
	return DisplayServer.clipboard_get()
