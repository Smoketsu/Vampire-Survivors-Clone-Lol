## CovenantKits — registry of the Covenant kinds' special actions
## (CovenantKit subclasses), keyed by the SanctumEnemyData "kit" id:
##   "sentinel"   Sanctified Sentinel  SentinelKit   (frontal sweep)
##   "inquisitor" Radiant Inquisitor   InquisitorKit (holy zones, suppression)
##   "confessor"  High Confessor       ConfessorKit  (shields, revival)
##   "paladin"    Sun Paladin          PaladinKit    (sun ward aura)
##   "guardian"   Cathedral Guardian   GuardianKit   (slams, sweeping beam)
##   "sister"     Sister of the Scourge BattleSisterKit (lash, zeal;
##                BattleSisterData, Crimson March and Sanctum)
## Any other id is an ANCIENT EYE kit (Act II): its script is
## EYE_KIT_DIR + "<id>_kit.gd" (e.g. "thrall" -> EyeThrallKit), loaded by
## name so each Act II stage adds its kits as new files without touching
## this registry. Loading is cached per id. An id with no Eye kit is an
## ELECTRONIC EMPIRE kit (Act III): EMPIRE_KIT_DIR + "<id>_kit.gd" (e.g.
## "trooper" -> TrooperKit), loaded the same way, and an id with neither is
## an OLYMPIAN REPUBLIC kit (Act IV): PANTHEON_KIT_DIR + "<id>_kit.gd" (e.g.
## "hoplite" -> HopliteKit), and an id with none of those is a SHOGUNATE kit
## (Act V): SHOGUNATE_KIT_DIR + "<id>_kit.gd" (e.g. "samurai" -> SamuraiKit),
## and an id with none of those is an INFERNO kit (Act VI): INFERNO_KIT_DIR +
## "<id>_kit.gd" (e.g. "succubus" -> SuccubusKit), and an id with none of
## those is a SANGUINE COURT kit (Act VII): COURT_KIT_DIR + "<id>_kit.gd"
## (e.g. "vampire_noble" -> VampireNobleKit), and an id with none of those is
## a LAST LINE kit (Act VIII): CITY_KIT_DIR + "<id>_kit.gd" (e.g. "blitz" ->
## BlitzKit), and an id with none of those is a CONCORD OF STARS kit (Act IX):
## CONCORD_KIT_DIR + "<id>_kit.gd" (e.g. "saucer" -> SaucerKit).
## An id with none of those is a BLACK TIDE kit (Act X): CORSAIR_KIT_DIR +
## "<id>_kit.gd" (e.g. "reef_shark" -> ReefSharkKit), else a HALL OF THE SLAIN
## kit (the Norse act): NORSE_KIT_DIR + "<id>_kit.gd" (e.g. "raider" -> RaiderKit).
## Kit ids must be unique across the nine folders.
## Enemy only ever talks to this file and the CovenantKit base class.
class_name CovenantKits
extends RefCounted

## Folder of the Ancient Eye's kit scripts ("<id>_kit.gd", each a CovenantKit).
const EYE_KIT_DIR: String = "res://scripts/enemies/eye/"
## Folder of the Electronic Empire's kit scripts ("<id>_kit.gd", each a CovenantKit; Act III).
const EMPIRE_KIT_DIR: String = "res://scripts/enemies/empire/"
# --- Act IV: the Olympian Republic ---
## Folder of the Olympian Republic's kit scripts ("<id>_kit.gd", each a PantheonKit; Act IV).
const PANTHEON_KIT_DIR: String = "res://scripts/enemies/pantheon/"
# --- Act V: the Shogunate of the Rising Sun ---
## Folder of the Shogunate's kit scripts ("<id>_kit.gd", each a ShogunateKit; Act V).
const SHOGUNATE_KIT_DIR: String = "res://scripts/enemies/shogunate/"
# --- Act VI: the Inferno ---
## Folder of the Inferno's kit scripts ("<id>_kit.gd", each an InfernoKit; Act VI).
const INFERNO_KIT_DIR: String = "res://scripts/enemies/inferno/"
# --- Act VII: the Sanguine Court ---
## Folder of the Sanguine Court's kit scripts ("<id>_kit.gd", each a CourtKit; Act VII).
const COURT_KIT_DIR: String = "res://scripts/enemies/court/"
# --- Act VIII: the Last Line ---
## Folder of the Last Line's kit scripts ("<id>_kit.gd", each a CityKit; Act VIII).
const CITY_KIT_DIR: String = "res://scripts/enemies/city/"
# --- Act IX: the Concord of Stars ---
## Folder of the Concord of Stars' kit scripts ("<id>_kit.gd", each a ConcordKit; Act IX).
const CONCORD_KIT_DIR: String = "res://scripts/enemies/concord/"
# --- Act X: the Black Tide ---
## Folder of the Black Tide's kit scripts ("<id>_kit.gd", each a CorsairKit; Act X).
const CORSAIR_KIT_DIR: String = "res://scripts/enemies/corsair/"
# --- Act XI (temporary): the Hall of the Slain ---
## Folder of the Hall of the Slain's kit scripts ("<id>_kit.gd", each a NorseKit).
const NORSE_KIT_DIR: String = "res://scripts/enemies/norse/"

## Eye / Empire kit id -> its loaded Script (null when no file exists), filled on first use.
static var _eye_scripts: Dictionary = {}


## The kit an enemy should use for kit id `id`: `current` when it already
## implements it (pooled enemies keep theirs), a new instance otherwise, or
## null for "" (no kit: every Graveyard and Crimson March kind).
static func for_enemy(current: CovenantKit, id: String) -> CovenantKit:
	if id == "":
		return null
	if current != null and current.kind == id:
		return current
	var k: CovenantKit = null  # New kit instance.
	match id:
		"sentinel":
			k = SentinelKit.new()
		"inquisitor":
			k = InquisitorKit.new()
		"confessor":
			k = ConfessorKit.new()
		"paladin":
			k = PaladinKit.new()
		"guardian":
			k = GuardianKit.new()
		"sister":
			k = BattleSisterKit.new()
		_:
			k = _eye_kit(id)
			if k == null:
				push_error("CovenantKits: unknown kit id '%s'" % id)
	if k != null:
		k.kind = id
	return k


## A new instance of Ancient Eye kit `id` (EYE_KIT_DIR + "<id>_kit.gd"), else
## of Electronic Empire kit `id` (EMPIRE_KIT_DIR + "<id>_kit.gd", Act III), else
## of Olympian Republic kit `id` (PANTHEON_KIT_DIR + "<id>_kit.gd", Act IV), else
## of Shogunate kit `id` (SHOGUNATE_KIT_DIR + "<id>_kit.gd", Act V), else of
## Inferno kit `id` (INFERNO_KIT_DIR + "<id>_kit.gd", Act VI), else of Sanguine
## Court kit `id` (COURT_KIT_DIR + "<id>_kit.gd", Act VII), else of Last Line
## kit `id` (CITY_KIT_DIR + "<id>_kit.gd", Act VIII), else of Concord of
## Stars kit `id` (CONCORD_KIT_DIR + "<id>_kit.gd", Act IX), or null when no
## such script exists.
static func _eye_kit(id: String) -> CovenantKit:
	if not _eye_scripts.has(id):
		var path := EYE_KIT_DIR + id + "_kit.gd"  # Expected script location.
		if not ResourceLoader.exists(path):
			path = EMPIRE_KIT_DIR + id + "_kit.gd"  # Act III: an Empire kit.
		if not ResourceLoader.exists(path):
			path = PANTHEON_KIT_DIR + id + "_kit.gd"  # Act IV: a Pantheon kit.
		if not ResourceLoader.exists(path):
			path = SHOGUNATE_KIT_DIR + id + "_kit.gd"  # Act V: a Shogunate kit.
		if not ResourceLoader.exists(path):
			path = INFERNO_KIT_DIR + id + "_kit.gd"  # Act VI: an Inferno kit.
		if not ResourceLoader.exists(path):
			path = COURT_KIT_DIR + id + "_kit.gd"  # Act VII: a Sanguine Court kit.
		if not ResourceLoader.exists(path):
			path = CITY_KIT_DIR + id + "_kit.gd"  # Act VIII: a Last Line kit.
		if not ResourceLoader.exists(path):
			path = CONCORD_KIT_DIR + id + "_kit.gd"  # Act IX: a Concord of Stars kit.
		if not ResourceLoader.exists(path):
			path = CORSAIR_KIT_DIR + id + "_kit.gd"  # Act X: a Black Tide kit.
		if not ResourceLoader.exists(path):
			path = NORSE_KIT_DIR + id + "_kit.gd"  # The Hall of the Slain: a Norse kit.
		_eye_scripts[id] = load(path) if ResourceLoader.exists(path) else null
	var scr: Script = _eye_scripts[id]
	if scr == null:
		return null
	return scr.new() as CovenantKit
