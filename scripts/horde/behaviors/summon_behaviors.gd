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
##   "grasp"  Spawn of the Deep   DeepSpawnBehavior (Act II, Ul-Thalos)
##   "bulwark" Bone Golem         GolemBehavior (content wave 2)
##   "hover"  Grave Drone         GraveDroneBehavior (Act III, the Assembly Halls)
##   "suppress" Iron Revenant     RevenantBehavior (Act III, the Iron Citadel)
##   "shieldwall" Myrmidon Shade  MyrmidonBehavior (Act IV, the Asphodel Underworld)
##   "kanabo" Bound Oni           OniBehavior (Act V, the Road to the Sun)
##   "allure" Succubus            BoundSuccubusBehavior (Act VI, the Palace of Silk and Ash)
##   "hellfire" Archfiend         ArchfiendBehavior (Act VI, Pandemonium)
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
		"grasp":
			b = DeepSpawnBehavior.new()  # Act II: the Spawn of the Deep.
		# --- Content wave 2: Bone Golem ---
		"bulwark":
			b = GolemBehavior.new()
		# --- Act III: the Assembly Halls ---
		"hover":
			b = GraveDroneBehavior.new()
		# --- Act III: the Iron Citadel ---
		"suppress":
			b = RevenantBehavior.new()  # The Iron Revenant.
		# --- Act IV: the Asphodel Underworld ---
		"shieldwall":
			b = MyrmidonBehavior.new()  # The Myrmidon Shades.
		# --- Act V: the Road to the Sun ---
		"kanabo":
			b = OniBehavior.new()  # The Bound Oni.
		# --- Act VI: the Palace of Silk and Ash ---
		"allure":
			b = BoundSuccubusBehavior.new()  # The Succubus.
		# --- Act VI: Pandemonium ---
		"hellfire":
			b = ArchfiendBehavior.new()  # The Archfiend.
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
		# --- Act II: Ul-Thalos, the Risen Spire ---
		"grasp":
			if a.is_empty():
				out.append("Blocks enemies with its heavy body")
				out.append("Grasp: holds a foe %ss, %s dmg a squeeze, every %ss" % [_f(b["grasp_duration"]), _f(b["grasp_damage"]), _f(b["grasp_cooldown"])])
			else:
				_delta(out, "Squeeze damage", a, b, "grasp_damage")
				_delta(out, "Hold time (s)", a, b, "grasp_duration")
				_delta(out, "Grasp cooldown (s)", a, b, "grasp_cooldown")
		# --- Content wave 2: Bone Golem ---
		"bulwark":
			GolemTexts.class_lines(out, a, b, nxt)
		# --- Act III: the Assembly Halls ---
		"hover":
			if a.is_empty():
				out.append("Hovers over the army: flies over obstacles and belts")
				out.append("Bone darts: %s dmg each, %s px reach" % [_f(nxt["damage"]), _f(nxt["attack_range"])])
			elif int(b.get("dart_count", 1)) != int(a.get("dart_count", 1)):
				out.append("Darts per attack %d -> %d" % [int(a.get("dart_count", 1)), int(b.get("dart_count", 1))])
		# --- Act III: the Iron Citadel ---
		"suppress":
			if a.is_empty():
				out.append("Holds a post inside the Bone Ring, a heavy gunner")
				out.append("Suppressive fire: %d shells a burst, each slows %d%% for %ss" % [int(b["shells"]), int(roundf(float(b["slow"]) * 100.0)), _f(b["slow_duration"])])
			else:
				_delta(out, "Shells per burst", a, b, "shells")
				_delta(out, "Slow time (s)", a, b, "slow_duration")
		# --- Act IV: the Asphodel Underworld ---
		"shieldwall":
			if a.is_empty():
				out.append("Holds the ring's front; three side by side lock shields")
				out.append("Shield wall: %d%% less damage; the spear runs through a foe behind" % int(roundf(float(b["wall_cut"]) * 100.0)))
		# --- Act V: the Road to the Sun ---
		"kanabo":
			if a.is_empty():
				out.append("Holds the ring's front like a wall of muscle")
				out.append("Kanabo smash: stuns every foe it lands on for %.1f s" % float(b["smash_stun_duration"]))
			else:
				_delta(out, "Smash damage", a, b, "smash_damage")
				_delta(out, "Stun (s)", a, b, "smash_stun_duration")
		# --- Act VI: the Palace of Silk and Ash ---
		"allure":
			if a.is_empty():
				out.append("Floats behind the ring and throws kiss bolts")
				out.append("Charm: the foe it fights fights for you for %.1f s" % float(b["charm_duration"]))
			else:
				_delta(out, "Charm (s)", a, b, "charm_duration")
				_delta(out, "Thrall hit", a, b, "thrall_damage")
		# --- Act VI: Pandemonium ---
		"hellfire":
			if a.is_empty():
				out.append("Holds the ring's front on spread wings")
				out.append("Hellfire Cleave: sweeps a wide arc and throws the foes in it back")
			else:
				_delta(out, "Cleave damage", a, b, "cleave_damage")
				_delta(out, "Cleave cooldown (s)", a, b, "cleave_cooldown")
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
