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
## this registry. Loading is cached per id.
## Enemy only ever talks to this file and the CovenantKit base class.
class_name CovenantKits
extends RefCounted

## Folder of the Ancient Eye's kit scripts ("<id>_kit.gd", each a CovenantKit).
const EYE_KIT_DIR: String = "res://scripts/enemies/eye/"

## Eye kit id -> its loaded Script (null when the file is missing), filled on first use.
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


## A new instance of Ancient Eye kit `id` (EYE_KIT_DIR + "<id>_kit.gd"), or
## null when no such script exists.
static func _eye_kit(id: String) -> CovenantKit:
	if not _eye_scripts.has(id):
		var path := EYE_KIT_DIR + id + "_kit.gd"  # Expected script location.
		_eye_scripts[id] = load(path) if ResourceLoader.exists(path) else null
	var scr: Script = _eye_scripts[id]
	if scr == null:
		return null
	return scr.new() as CovenantKit
