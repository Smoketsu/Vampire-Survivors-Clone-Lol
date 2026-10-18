## SummonBehaviors — registry of the class special actions (SummonBehavior
## subclasses), keyed by the UnitData "behavior" id:
##   "stomp"  Corpse Abomination  AbominationBehavior
##   "dash"   Grave Rogue         RogueBehavior
##   "swoop"  Crypt Gargoyle      GargoyleBehavior
##   "frost"  Frost Wraith        FrostWraithBehavior
##   "pack"   Bone Hounds         BoneHoundBehavior
##   "dirge"  Banshee             BansheeBehavior
##   "barrage" Corpse Catapult    CatapultBehavior
##   "dive"   Fallen Seraph       SeraphBehavior (Act II)
## It creates / reuses the per-unit instance and builds the class-specific
## level-up card lines (AbilityManager._summon_offer()), so the shared code
## only ever talks to this file and the SummonBehavior base class.
class_name SummonBehaviors
extends RefCounted


## The behaviour a unit should use for behaviour id `kind`: `current` when it
## already implements it (pooled units keep theirs), a new instance
## otherwise, or null for "" (no special).
static func for_unit(current: SummonBehavior, kind: String) -> SummonBehavior:
	if kind == "":
		return null
	if current != null and current.kind == kind:
		return current
	var b: SummonBehavior = null  # New behaviour instance.
	match kind:
		"stomp":
			b = AbominationBehavior.new()
		"dash":
			b = RogueBehavior.new()
		"swoop":
			b = GargoyleBehavior.new()
		"frost":
			b = FrostWraithBehavior.new()
		"pack":
			b = BoneHoundBehavior.new()
		"dirge":
			b = BansheeBehavior.new()
		"barrage":
			b = CatapultBehavior.new()
		# --- Act II: Fallen Seraph ---
		"dive":
			b = SeraphBehavior.new()
	if b != null:
		b.kind = kind
	return b


## Level-up card lines for summon class `cls`: what its special does at the
## next level (`cur` empty: a new class), or how it changes from `cur` to
## `nxt` (effective stats from HordeDirector.compute_stats()).
static func card_lines(cls: String, cur: Dictionary, nxt: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()  # Card lines.
	var b: Dictionary = nxt.get("special", {})  # Next-level special numbers.
	var a: Dictionary = cur.get("special", {})  # Current special numbers (may be empty).
	match String(UnitData.UNITS[cls].get("behavior", "")):
		"stomp":
			if a.is_empty():
				out.append("Blocks enemies with its huge body")
				out.append("Stomp: %s dmg in %s px every %ss, knocks back" % [_f(b["stomp_damage"]), _f(b["stomp_radius"]), _f(b["stomp_cooldown"])])
			else:
				_delta(out, "Stomp damage", a, b, "stomp_damage")
				_delta(out, "Stomp radius", a, b, "stomp_radius")
		"dash":
			if a.is_empty():
				out.append("Dash strike: %s dmg to every foe in a %s px lane" % [_f(b["dash_damage"]), _f(b["dash_length"])])
				out.append("Bleed %s dmg over %ss; hunts healers and archers" % [_f(float(b["bleed_damage"]) * float(RogueBehavior.bleed_ticks(b))), _f(b["bleed_duration"])])
			else:
				_delta(out, "Dash damage", a, b, "dash_damage")
				_delta(out, "Bleed time (s)", a, b, "bleed_duration")
				_delta(out, "Dash cooldown (s)", a, b, "dash_cooldown")
		"swoop":
			if a.is_empty():
				out.append("Swoop: flies over everything onto a cluster")
				out.append("Dive %s dmg in %s px every %ss" % [_f(b["swoop_damage"]), _f(b["swoop_radius"]), _f(b["swoop_cooldown"])])
			else:
				_delta(out, "Swoop damage", a, b, "swoop_damage")
				_delta(out, "Swoop radius", a, b, "swoop_radius")
				_delta(out, "Swoop cooldown (s)", a, b, "swoop_cooldown")
		"frost":
			if a.is_empty():
				out.append("Frost bolts slow foes by %d%%" % int(roundf(float(b["chill_slow"]) * 100.0)))
				out.append("Deep Freeze: freezes foes in %s px for %ss" % [_f(b["freeze_radius"]), _f(b["freeze_duration"])])
			else:
				_delta(out, "Freeze radius", a, b, "freeze_radius")
				_delta(out, "Freeze time (s)", a, b, "freeze_duration")
				_delta(out, "Freeze cooldown (s)", a, b, "freeze_cooldown")
		"pack":
			if a.is_empty():
				out.append("Pack Hunt: hounds share prey, hunting archers and priests")
				out.append("+%d%% bite per packmate on the foe (max +%d%%)" % [
					int(roundf(float(b["pack_bonus"]) * 100.0)), int(roundf(float(b["pack_bonus"]) * float(b["pack_cap"]) * 100.0))])
		"dirge":
			if a.is_empty():
				out.append("Dirge every %ss: foes in %s px slowed %d%%" % [_f(b["dirge_cooldown"]), _f(b["dirge_radius"]),
					int(roundf(float(b["dirge_slow"]) * 100.0))])
				out.append("and deal %d%% less damage for %ss" % [int(roundf(float(b["dirge_cut"]) * 100.0)), _f(b["dirge_duration"])])
			else:
				_delta(out, "Dirge radius", a, b, "dirge_radius")
				_delta(out, "Dirge time (s)", a, b, "dirge_duration")
				_delta(out, "Dirge cooldown (s)", a, b, "dirge_cooldown")
		"barrage":
			if a.is_empty():
				out.append("Bone Barrage: boulders splash %s px, from behind the army" % _f(nxt["splash_radius"]))
				out.append("Targets structures, elites and dense packs first")
		# --- Act II: Fallen Seraph ---
		"dive":
			if a.is_empty():
				out.append("Dive: %s dmg in %s px on the densest pack every %ss" % [_f(b["dive_damage"]), _f(b["dive_radius"]), _f(b["dive_cooldown"])])
				out.append("Feather ring: %s dmg to every foe within %s px" % [_f(b["feather_damage"]), _f(b["ring_radius"])])
			else:
				_delta(out, "Dive damage", a, b, "dive_damage")
				_delta(out, "Feather damage", a, b, "feather_damage")
				_delta(out, "Feather ring radius", a, b, "ring_radius")
				_delta(out, "Dive cooldown (s)", a, b, "dive_cooldown")
	return out


## Appends "label a -> b" when special key `key` changes between `a` and `b`.
static func _delta(out: PackedStringArray, label: String, a: Dictionary, b: Dictionary, key: String) -> void:
	var va := float(a.get(key, 0.0))  # Current value.
	var vb := float(b.get(key, 0.0))  # Next value.
	if not is_equal_approx(va, vb):
		out.append("%s %s -> %s" % [label, _f(va), _f(vb)])


## Compact number format (AbilityManager._fmt).
static func _f(v: Variant) -> String:
	return AbilityManager._fmt(float(v))
