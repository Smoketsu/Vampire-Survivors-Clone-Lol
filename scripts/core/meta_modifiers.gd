## MetaModifiers — the ONE path through which purchased meta upgrades (Soul
## Ash, GDD §9.2) reach gameplay. Game builds one instance at run start from
## the purchased tiers (Meta.run_modifiers(): the save file in normal play, an
## in-memory --meta profile in the autotest) and keeps it for the whole run as
## `game.meta`. The existing stat code reads it in a handful of places (the
## list is in MetaData.STATS):
##   value(stat)          summed bonus of every upgrade raising `stat`
##   capacity_bonus(cls)  extra summon capacity of class `cls`
##   apply_to_player(p)   one-time player stats at run start
##   unlocks(stat)        an "unlock" upgrade is owned (none on sale at present)
##   mastery_value(cls, stat)  a summon class's Mastery bonus (MasteryData; Ossuary
##                        expansion step 4), read by HordeDirector.compute_stats()
## Each meta stat is its own stacking category (GDD §6.4): it multiplies the
## level / passive / synergy bonuses instead of adding to them. An empty
## instance (no upgrades) returns 0 everywhere, so a run without purchases
## plays exactly like before meta-progression existed.
class_name MetaModifiers
extends RefCounted

## Upgrade id -> purchased tier used for this run.
var tiers: Dictionary = {}
## Summon class id -> Mastery level used for this run (MasteryData, 0..MAX_LEVEL).
var masteries: Dictionary = {}
## Modifier stat (MetaData.STATS key) -> summed bonus.
var _values: Dictionary = {}


## Builds the modifiers for upgrade tiers `p_tiers` (id -> tier). Unknown ids
## are ignored and tiers are clamped to each upgrade's range (levels 6-10 of the
## deep upgrades included: the difficulty gates only limit buying, Meta.purchase_block(),
## so a co-op partner's loadout and the --meta=max profile apply in full).
## Each upgrade adds MetaData.value_at(id, tier). `p_masteries` (class id ->
## level, default none) are the summon Masteries, clamped to MasteryData's range;
## classes without a mastery are ignored.
static func from_tiers(p_tiers: Dictionary, p_masteries: Dictionary = {}) -> MetaModifiers:
	var m := MetaModifiers.new()
	for cls: String in MasteryData.CLASSES:
		var lv := clampi(int(p_masteries.get(cls, 0)), 0, MasteryData.MAX_LEVEL)
		if lv > 0:
			m.masteries[cls] = lv
	for id: String in MetaData.UPGRADE_ORDER:
		var t := clampi(int(p_tiers.get(id, 0)), 0, MetaData.max_tier(id))
		if t <= 0:
			continue
		m.tiers[id] = t
		var stat: String = MetaData.UPGRADES[id]["stat"]
		m._values[stat] = float(m._values.get(stat, 0.0)) + MetaData.value_at(id, t)  # Listed levels + deep levels (6-10).
	return m


## Summed bonus of modifier `stat` (0 when nothing raises it).
func value(stat: String) -> float:
	return float(_values.get(stat, 0.0))


## value() rounded to an int (capacity, rerolls, banishes, revivals).
func int_value(stat: String) -> int:
	return int(roundf(value(stat)))


## True when no upgrade and no mastery is active.
func is_empty() -> bool:
	return tiers.is_empty() and masteries.is_empty()


## Mastery level that applies to summon class `cls` (0 = none). An evolved form
## is its base class (HordeDirector calls with the base id); the Profane Bishop
## takes the better of its bases (MasteryData.BASES_OF).
func mastery_level(cls: String) -> int:
	if masteries.is_empty():
		return 0
	if MasteryData.BASES_OF.has(cls):
		var best := 0
		for base: String in MasteryData.BASES_OF[cls]:
			best = maxi(best, int(masteries.get(base, 0)))
		return best
	return int(masteries.get(cls, 0))


## Mastery bonus fraction for summon class `cls` on `stat` ("hp" or "damage"; 0
## when the class has no mastery level). One multiplier category, applied once
## in HordeDirector.compute_stats().
func mastery_value(cls: String, stat: String) -> float:
	var lv := mastery_level(cls)
	if lv <= 0:
		return 0.0
	return MasteryData.hp_bonus(lv) if stat == "hp" else MasteryData.damage_bonus(lv)


## True when an "unlock" stat (MetaData.STATS format "unlock") is owned.
func unlocks(stat: String) -> bool:
	return value(stat) >= 1.0


## Extra summon capacity for class `cls`: Legion of Bone for every class plus
## Risen Vanguard for Skeleton Warriors (GDD open question 13: a meta
## capacity bonus goes to every class, or to the class the upgrade names).
func capacity_bonus(cls: String) -> int:
	var bonus := int_value("capacity_per_class")
	if cls == "warrior":
		bonus += int_value("warrior_capacity")
	return bonus


## Sets the necromancer's run-start stats: max HP (+flat), move speed and
## pickup radius (+%), and the number of revivals.
func apply_to_player(p: Necromancer) -> void:
	p.max_hp = PlayerData.MAX_HP + value("max_hp")
	p.hp = p.max_hp
	p.move_speed = PlayerData.MOVE_SPEED * (1.0 + value("move_speed"))
	p.pickup_radius = PlayerData.PICKUP_RADIUS * (1.0 + value("pickup_radius"))
	p.revives_left = int_value("revives")


## "id:tier" list of the active upgrades (autotest summary).
func describe() -> String:
	if tiers.is_empty():
		return "none"
	var parts := PackedStringArray()
	for id: String in MetaData.UPGRADE_ORDER:
		if tiers.has(id):
			parts.append("%s:%d" % [id, int(tiers[id])])
	return ", ".join(parts)  # Masteries have their own autotest line (describe_masteries()).


## "class:level" list of the active Masteries (autotest summary), "none" when empty.
func describe_masteries() -> String:
	if masteries.is_empty():
		return "none"
	var parts := PackedStringArray()
	for cls: String in MasteryData.CLASSES:
		if masteries.has(cls):
			parts.append("%s:%d" % [cls, int(masteries[cls])])
	return ", ".join(parts)
