## CovenantKits — registry of the Covenant kinds' special actions
## (CovenantKit subclasses), keyed by the SanctumEnemyData "kit" id:
##   "sentinel"   Sanctified Sentinel  SentinelKit   (frontal sweep)
##   "inquisitor" Radiant Inquisitor   InquisitorKit (holy zones, suppression)
##   "confessor"  High Confessor       ConfessorKit  (shields, revival)
##   "paladin"    Sun Paladin          PaladinKit    (sun ward aura)
##   "guardian"   Cathedral Guardian   GuardianKit   (slams, sweeping beam)
##   "sister"     Sister of the Scourge BattleSisterKit (lash, zeal;
##                BattleSisterData, Crimson March and Sanctum)
## Enemy only ever talks to this file and the CovenantKit base class.
class_name CovenantKits
extends RefCounted


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
			push_error("CovenantKits: unknown kit id '%s'" % id)
	if k != null:
		k.kind = id
	return k
