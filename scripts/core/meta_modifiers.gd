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
##   relic(key)           a relic / Grave Offering special (RelicData.SPECIAL_RULES)
## Relics and Grave Offerings (Ossuary expansion, GDD §15.0 "Relics and Grave
## Offerings") ride on the same object: attach_rites() adds the RelicEffects'
## stats to the modifier stats once and keeps it as `rites` for relic(); so a
## co-op partner's relics follow his own slot like his upgrades.
## Each meta stat is its own stacking category (GDD §6.4): it multiplies the
## level / passive / synergy bonuses instead of adding to them. An empty
## instance (no upgrades) returns 0 everywhere, so a run without purchases
## plays exactly like before meta-progression existed.
class_name MetaModifiers
extends RefCounted

## Upgrade id -> purchased tier used for this run.
var tiers: Dictionary = {}
## Modifier stat (MetaData.STATS key) -> summed bonus.
var _values: Dictionary = {}
## The run's relics and Grave Offering (empty = none; attach_rites()).
var rites: RelicEffects = RelicEffects.new()


## Builds the modifiers for upgrade tiers `p_tiers` (id -> tier). Unknown ids
## are ignored and tiers are clamped to each upgrade's range (levels 6-10 of the
## deep upgrades included: the difficulty gates only limit buying, Meta.purchase_block(),
## so a co-op partner's loadout and the --meta=max profile apply in full).
## Each upgrade adds MetaData.value_at(id, tier).
static func from_tiers(p_tiers: Dictionary) -> MetaModifiers:
	var m := MetaModifiers.new()
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


## Attaches the run's relics and offering `r`: their stats are added to the
## modifier stats (once) and their specials answer relic(). An empty `r` changes
## nothing.
func attach_rites(r: RelicEffects) -> void:
	rites = r
	var st := r.stat_values()  # Stat -> value of every relic and the offering.
	for stat: String in st:
		_values[stat] = float(_values.get(stat, 0.0)) + float(st[stat])


## Combined relic / offering special `key` (RelicEffects.special(): 0, or 1 for
## a multiplier, when none has it).
func relic(key: String) -> float:
	return rites.special(key)


## relic() rounded to an int.
func relic_int(key: String) -> int:
	return rites.special_int(key)


## True when no upgrade is active.
func is_empty() -> bool:
	return tiers.is_empty()


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


## Sets the necromancer's run-start stats: max HP (+flat, then x the relics'
## max_hp_mult), move speed and pickup radius (+%), and the number of revivals.
func apply_to_player(p: Necromancer) -> void:
	p.max_hp = (PlayerData.MAX_HP + value("max_hp")) * relic("max_hp_mult")
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
	return ", ".join(parts)
