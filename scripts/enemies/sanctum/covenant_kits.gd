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
## "trooper" -> TrooperKit), loaded the same way.
## Enemy only ever talks to this file and the CovenantKit base class.
class_name CovenantKits
extends RefCounted

## Folder of the Ancient Eye's kit scripts ("<id>_kit.gd", each a CovenantKit).
const EYE_KIT_DIR: String = "res://scripts/enemies/eye/"
## Folder of the Electronic Empire's kit scripts ("<id>_kit.gd", each a CovenantKit; Act III).
const EMPIRE_KIT_DIR: String = "res://scripts/enemies/empire/"

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
## of Electronic Empire kit `id` (EMPIRE_KIT_DIR + "<id>_kit.gd", Act III), or
## null when no such script exists.
static func _eye_kit(id: String) -> CovenantKit:
	if not _eye_scripts.has(id):
		var path := EYE_KIT_DIR + id + "_kit.gd"  # Expected script location.
		if not ResourceLoader.exists(path):
			path = EMPIRE_KIT_DIR + id + "_kit.gd"  # Act III: an Empire kit.
		_eye_scripts[id] = load(path) if ResourceLoader.exists(path) else null
	var scr: Script = _eye_scripts[id]
	if scr == null:
		return null
	return scr.new() as CovenantKit
