## save_safety_check.gd (preloaded by ossuary_check.gd: tools/ has a .gdignore, so
## no class_name): the save-safety part of tools/ossuary_check, written with the
## adversarial review's fixes (docs/review/FIX_PROPOSAL.md, Batches A and B). It checks:
## - a save from a newer build loads but is never written over (Fix 3);
## - save codes: a normal code round-trips; a code holding an Object( / Resource(
##   constructor, a version-only code and a newer build's code are all refused;
##   a restore keeps the old progress and Undo brings it back (Fixes 3, 10, 13);
## - crash recovery: a save.cfg.tmp left by a crash, and the save.cfg.bak beside a
##   lost save, are both loaded instead of a fresh profile; corrupt copies are
##   numbered (Fix 14);
## - refunds pay back what the save says was paid, not today's prices (Fix 18);
## - flags a Web page address may not set (WebLinkData, Fix 4) and the typed
##   settings readers (§20);
## - co-op input checks: a relay welcome with a script in its code or a bad seat
##   is refused, and a host start naming another offering for the guest's seat,
##   or with the wrong number of loadouts, is refused (Fixes 1 and 2).
## Called from ossuary_check.gd's _run(); every file lives in that check's temp
## directory, never the real save. tools/.gdignore keeps it out of exports.
extends RefCounted

## The ossuary_check node (its _check() counts failures; its _path() names temp files).
var host: Node


func _init(p_host: Node) -> void:
	host = p_host


## Runs every save-safety check, then leaves Meta reset with saving off again.
func run() -> void:
	DirAccess.make_dir_recursive_absolute(String(host.get("_dir")))
	_check_newer_save()
	_check_codes()
	_check_recovery()
	_check_paid_refund()
	_check_web_args_and_settings()
	_check_coop_inputs()
	GameState.autotest_meta_save = false
	Meta._reset()


## Records check `ok` (described by `what`) on the host.
func _check(ok: bool, what: String) -> void:
	host.call("_check", ok, "save safety: " + what)


## The temp file `name` in the check directory, with any leftovers of an
## earlier check (.tmp, .bak, .corrupt*, .pre_restore) removed.
func _fresh(name: String) -> String:
	var p: String = host.call("_path", name)
	for suffix: String in ["", ".tmp", Meta.BACKUP_SUFFIX, ".corrupt", ".corrupt.2", SaveBackupData.PRE_RESTORE_SUFFIX]:
		if FileAccess.file_exists(p + suffix):
			DirAccess.remove_absolute(p + suffix)
	return p


## Writes a minimal save at `path`: format version `version`, Soul Ash `ash`.
func _write_save(path: String, version: int, ash: int) -> void:
	var cfg := ConfigFile.new()  # The save being written.
	cfg.set_value("meta", "save_version", version)
	cfg.set_value("currency", "soul_ash", ash)
	cfg.set_value("lifetime", "runs", 3.0)
	cfg.save(path)


# --- Fix 3: a newer build's save ------------------------------------------------------

func _check_newer_save() -> void:
	var p := _fresh("newer.cfg")
	_write_save(p, MetaData.SAVE_VERSION + 5, 777)
	var before := FileAccess.get_file_as_string(p)  # The newer save's exact text.
	Meta.save_path = p
	GameState.autotest_meta_save = true  # Lets Meta read and write (the temp path only).
	Meta.load_save()
	_check(Meta.load_status == "newer" and Meta.soul_ash == 777, "a newer save loads (status %s)" % Meta.load_status)
	_check(not Meta.can_write() and Meta.mode_allows_write(), "a newer save is never written (can_write false)")
	Meta.soul_ash += 5
	Meta.save()
	_check(FileAccess.get_file_as_string(p) == before, "save() leaves the newer file unchanged")
	_write_save(p, MetaData.SAVE_VERSION, 10)
	Meta.load_save()
	_check(Meta.load_status == "ok" and Meta.can_write(), "a current save is writable again")


# --- Fixes 3, 10, 13: save codes --------------------------------------------------

func _check_codes() -> void:
	var p := _fresh("codes.cfg")
	Meta.save_path = p
	_write_save(p, MetaData.SAVE_VERSION, 100)
	Meta.load_save()
	var code := SaveBackup.export_code()  # A real code of a save with 100 Soul Ash.
	_check(code != "" and SaveBackup.decode(code) != "", "a normal code decodes")
	_check(SaveBackup.summary(SaveBackup.decode(code)) == SaveBackupData.SUMMARY % [100, 3], "the confirm summary reads the code")
	_check(SaveBackup.decode(_code_of("[meta]\nsave_version=%d\n[currency]\nsoul_ash=5\nx=Object(Node,\"name\":\"a\")\n" % MetaData.SAVE_VERSION)) == "",
			"a code holding Object( is refused")
	_check(SaveBackup.decode(_code_of("[meta]\nsave_version=%d\n[x]\ny=Resource(\"res://icon.svg\")\n" % MetaData.SAVE_VERSION)) == "",
			"a code holding Resource( is refused")
	_check(SaveBackup.decode(_code_of("[meta]\nsave_version=%d\n" % MetaData.SAVE_VERSION)) == "", "a version-only code is refused")
	_check(SaveBackup.decode("NECRO1:" + "A".repeat(SaveBackupData.MAX_CODE_CHARS + 4)) == "", "an over-long code is refused")
	var newer := _code_of("[meta]\nsave_version=%d\n[currency]\nsoul_ash=9\n" % (MetaData.SAVE_VERSION + 1))
	_check(SaveBackup.is_newer(SaveBackup.decode(newer)) and SaveBackup.import_code(newer) == ERR_INVALID_DATA and Meta.soul_ash == 100,
			"a newer build's code is refused and the progress kept")
	var other := _code_of("[meta]\nsave_version=%d\n[currency]\nsoul_ash=4242\n[lifetime]\nruns=1.0\n" % MetaData.SAVE_VERSION)
	_check(SaveBackup.import_code(other) == OK and Meta.soul_ash == 4242, "a restore loads the code")
	_check(FileAccess.file_exists(p + SaveBackupData.PRE_RESTORE_SUFFIX), "a restore keeps the replaced progress")
	_check(SaveBackup.undo_restore() == OK and Meta.soul_ash == 100, "Undo brings the replaced progress back")
	_check(SaveBackup.undo_restore() == OK and Meta.soul_ash == 4242, "a second Undo is a redo")
	DirAccess.remove_absolute(p + SaveBackupData.PRE_RESTORE_SUFFIX)
	_check(SaveBackup.undo_restore() == ERR_FILE_NOT_FOUND, "Undo without a restore does nothing")


## A save code (SaveBackupData.CODE_PREFIX + base64 of the gzipped text) of save text `text`.
static func _code_of(text: String) -> String:
	return SaveBackupData.CODE_PREFIX + Marshalls.raw_to_base64(text.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))


# --- Fix 14: crash recovery -------------------------------------------------------

func _check_recovery() -> void:
	var p := _fresh("recover.cfg")
	Meta.save_path = p
	_write_save(p + ".tmp", MetaData.SAVE_VERSION, 321)  # A crash after the temp file, before the rename.
	Meta.load_save()
	_check(Meta.soul_ash == 321 and FileAccess.file_exists(p) and not FileAccess.file_exists(p + ".tmp"),
			"a leftover .tmp becomes the save (status %s)" % Meta.load_status)
	Meta.soul_ash = 400
	Meta.save()
	Meta.soul_ash = 500
	Meta.save()
	var bak := ConfigFile.new()  # The previous save, kept by save().
	_check(bak.load(p + Meta.BACKUP_SUFFIX) == OK and int(bak.get_value("currency", "soul_ash", 0)) == 400, "save() keeps the previous save as .bak")
	# A lost save beside its .bak (an unreadable file takes the same path, but the
	# engine's parse error would break the CI log check, so the file is removed instead).
	DirAccess.remove_absolute(p)
	Meta.load_save()
	_check(Meta.soul_ash == 400 and FileAccess.file_exists(p), "a lost save falls back to .bak")
	var c1: String = Meta._free_corrupt_path()  # Where the first unreadable copy goes.
	FileAccess.open(c1, FileAccess.WRITE).close()
	var c2: String = Meta._free_corrupt_path()  # Where the second one goes.
	_check(c1 == p + ".corrupt" and c2 == p + ".corrupt.2", "corrupt copies are numbered, never overwritten")


# --- Fix 18: refunds pay back what was paid --------------------------------------

func _check_paid_refund() -> void:
	var p := _fresh("paid.cfg")
	Meta.save_path = p
	Meta._reset()
	Meta.soul_ash = 100000
	var price := Meta.next_cost("necrotic_marrow")  # Today's price of level 1.
	_check(Meta.purchase("necrotic_marrow") and Meta.paid_for("necrotic_marrow") == price, "a purchase records what it paid")
	var cfg := ConfigFile.new()  # The save, with the paid record changed as if prices had moved since.
	cfg.load(p)
	cfg.set_value("upgrades_paid", "necrotic_marrow", [1, price + 37])
	cfg.save(p)
	Meta.load_save()
	var ash := Meta.soul_ash  # Soul Ash before the refund.
	_check(Meta.refund_all() == price + 37 and Meta.soul_ash == ash + price + 37, "Refund all pays back the recorded amount")
	cfg.load(p)
	cfg.set_value("upgrades", "necrotic_marrow", 2)
	cfg.set_value("upgrades_paid", "necrotic_marrow", [1, 1])  # A record for another tier: ignored.
	cfg.save(p)
	Meta.load_save()
	_check(Meta.paid_for("necrotic_marrow") == MetaData.cost_up_to("necrotic_marrow", 2), "a record for another tier falls back to today's prices")


# --- Fix 4 and the settings readers -------------------------------------------------

func _check_web_args_and_settings() -> void:
	_check(GameState._web_arg_forbidden("--meta-save") and GameState._web_arg_forbidden("--feedback-url=https://x")
			and GameState._web_arg_forbidden("--relay=wss://x") and not GameState._web_arg_forbidden("--seed=3")
			and not GameState._web_arg_forbidden("--coop-bot"), "page-address flags: the save / data flags are refused, test flags pass")
	var cfg := ConfigFile.new()  # A hand-edited settings file with wrong types.
	cfg.set_value("feel", "screen_shake", "yes")
	cfg.set_value("audio", "master", "loud")
	cfg.set_value("video", "zoom", 3)
	_check(Settings._flag(cfg, "feel", "screen_shake", true) == true and is_equal_approx(Settings._num(cfg, "audio", "master", 0.5), 0.5)
			and Settings._text(cfg, "video", "zoom", "normal") == "normal", "wrong-typed settings keep their defaults")


# --- Fixes 1 and 2: what the relay and the host send -----------------------------

func _check_coop_inputs() -> void:
	CoopNet._reset_session()
	CoopNet.state = CoopNet.State.CONNECTING
	CoopNet._on_text(JSON.stringify({"t": "welcome", "code": "AB';alert(1)//", "slot": 0}))
	_check(CoopNet.state == CoopNet.State.CLOSED and CoopNet.code == "", "a welcome whose code holds a script is refused")
	CoopNet._reset_session()
	CoopNet.state = CoopNet.State.CONNECTING
	CoopNet._on_text(JSON.stringify({"t": "welcome", "code": "BCDFG".rpad(CoopNetData.CODE_LENGTH, "B").left(CoopNetData.CODE_LENGTH), "slot": 7}))
	_check(CoopNet.state == CoopNet.State.CLOSED and CoopNet.local_slot == -1, "a welcome with a seat beyond 0-1 is refused")
	CoopNet._reset_session()
	CoopNet.state = CoopNet.State.LOBBY
	CoopNet._on_text(JSON.stringify({"t": "welcome", "code": "BCDFG".rpad(CoopNetData.CODE_LENGTH, "B").left(CoopNetData.CODE_LENGTH), "slot": 0}))
	_check(CoopNet.state == CoopNet.State.CLOSED, "a second welcome in the lobby (a forged one) is refused")
	# The guest's own loadout: no offering. The host names one for the guest's seat.
	CoopNet._reset_session()
	CoopNet.local_slot = 1
	var mine := CoopNet._clean_loadout({"name": "P2"}, 1)  # The guest's loadout as it sent it.
	CoopNet.loadouts = [CoopNet._clean_loadout({"name": "P1"}, 0), mine]
	var offering: String = String(OfferingData.OFFERINGS.keys()[0])  # A real offering id.
	var forged := mine.duplicate(true)  # The guest's seat as a tampered host sends it.
	forged["offering"] = offering
	var info := {"seed": 7, "config": {}, "loadouts": [CoopNet.loadouts[0], forged]}  # The tampered start info.
	_check(CoopNet._start_problem(info) == "offering", "a start naming an offering the guest never chose is refused")
	_check(CoopNet._start_problem({"seed": 7, "config": {}, "loadouts": [CoopNet.loadouts[0]]}) == "loadouts", "a start with one loadout is refused")
	_check(CoopNet._start_problem({"seed": 7, "config": {}, "loadouts": [CoopNet.loadouts[0], 5]}) == "loadouts", "a start with a non-Dictionary loadout is refused")
	_check(CoopNet._start_problem({"seed": 7, "config": {}, "loadouts": [CoopNet.loadouts[0], mine]}) == "", "an honest start passes")
	CoopNet._reset_session()
	CoopNet.state = CoopNet.State.OFFLINE
	CoopNet.set_process(false)  # As at startup: nothing runs until host() / join().
