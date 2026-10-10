## NecroSpellBook — owns and drives the four newer necromancer spells (user
## request "more weapons", AbilityData header) behind ONE small dispatch in
## AbilityManager (setup / step / on_enemy_killed / passive card lines):
##   Bone Spear       -> BoneSpear        (evolves into Ossuary Lance)
##   Soul Siphon      -> SoulSiphon       (evolves into Soul Rapture)
##   Corpse Explosion -> CorpseExplosion  (evolves into Grave Eruption)
##   Plague Cloud     -> PlagueCloud      (evolves into Pestilence)
## Each spell node is created the first time its spell is learned and reads
## its EFFECTIVE stats every tick from AbilityManager.spell_stats() — the one
## modifier path, so Soul Conduit, Abyssal Focus, the new spell passives,
## meta Shadowcraft and the Hyper power-up all apply unchanged. Evolved rows
## come from EvolutionData via the same call.
## Enemies frozen by Stasis are still valid targets: nothing here checks
## Enemy.frozen (power-up rule "spells keep working on frozen enemies").
class_name NecroSpellBook
extends Node2D

## Spell ids this book drives, in AbilityData.SPELL_ORDER order.
const IDS := ["bone_spear", "soul_siphon", "corpse_explosion", "plague_cloud"]
## Damage-source stat tags of each spell (CombatResolver "dmg_<tag>"), base
## spell first, then its evolution's. Used for the autotest summary.
const SOURCES := {
	"bone_spear": ["spear", "lance"],
	"soul_siphon": ["siphon", "rapture", "rapture_burst"],
	"corpse_explosion": ["corpse", "eruption", "eruption_spikes"],
	"plague_cloud": ["plague", "pestilence", "death_nova"],
}

## Owning run.
var game: Game
## Spell id -> its spell node (BoneSpear / SoulSiphon / CorpseExplosion /
## PlagueCloud), present once the spell has been learned.
var nodes: Dictionary = {}


## Ticks every learned spell with its current effective stats. Spells that
## have not been learned cost nothing.
func step(delta: float) -> void:
	var ab := game.abilities  # The owning AbilityManager.
	for id: String in IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.step(delta, ab.spell_stats(id))


## Builds the node of spell `id` and adds it as a child (world space).
func _create(id: String) -> NecroSpell:
	var node: NecroSpell = null  # The new spell node.
	match id:
		"bone_spear":
			node = BoneSpear.new()
		"soul_siphon":
			node = SoulSiphon.new()
		"corpse_explosion":
			node = CorpseExplosion.new()
		_:
			node = PlagueCloud.new()
	node.game = game
	add_child(node)
	nodes[id] = node
	return node


## Kill hook (CombatResolver._kill_enemy, via AbilityManager): Corpse
## Explosion remembers the corpse, Soul Rapture bursts tethered victims,
## Grave Eruption chains. Called while `e` is still active and in place.
func on_enemy_killed(e: Enemy) -> void:
	var ce: CorpseExplosion = nodes.get("corpse_explosion")  # Corpse spell node, if learned.
	if ce != null:
		ce.on_enemy_killed(e)
	var ss: SoulSiphon = nodes.get("soul_siphon")  # Siphon spell node, if learned.
	if ss != null:
		ss.on_enemy_killed(e)


## Total damage dealt so far by spell `id` (base and evolved sources).
func damage_of(id: String) -> float:
	var total := 0.0  # Sum of the spell's dmg_* stats.
	for src: String in SOURCES[id]:
		total += float(game.stats.get("dmg_" + src, 0.0))
	return total


## Adds the one concrete, player-visible consequence line of a level-up
## card for the four newer passives (AbilityManager._passive_offer).
## Values "now" come from the current passive level, `nxt` is the next
## level's row.
func passive_example(id: String, nxt: Dictionary, deltas: PackedStringArray) -> void:
	var ab := game.abilities  # The owning AbilityManager.
	match id:
		"shade_stride":
			var base := game.player.move_speed  # px/s before the passive (meta included).
			var cur := base * (1.0 + ab.passive_value(id, "move_speed"))  # px/s now.
			var nx := base * (1.0 + float(nxt["move_speed"]))  # px/s after the card.
			deltas.append("Move speed %s -> %s px/s" % [AbilityManager._fmt(cur), AbilityManager._fmt(nx)])
		"vampiric_rite":
			var cur := PlayerData.HP_REGEN + ab.passive_value(id, "hp_regen")  # HP/s now.
			var nx := PlayerData.HP_REGEN + float(nxt["hp_regen"])  # HP/s after the card.
			deltas.append("Regeneration %s -> %s HP/s" % [AbilityManager._fmt(cur), AbilityManager._fmt(nx)])
		"necrotic_expanse":
			var spell := _first_owned(["shadow_blast", "corpse_explosion", "plague_cloud"])  # Spell shown.
			if spell != "":
				var r := float(ab.spell_stats(spell)["radius"])  # Effective radius now (Hyper excluded: no radius key).
				var k := (1.0 + float(nxt["spell_area"])) / (1.0 + ab.passive_value(id, "spell_area"))  # Ratio after / before.
				deltas.append("%s radius %s -> %s" % [ab.spell_name(spell), AbilityManager._fmt(r), AbilityManager._fmt(r * k)])
		"lingering_malediction":
			var spell := _first_owned(["plague_cloud", "corpse_explosion", "shadow_blast"])  # Spell shown.
			var key := ""  # Duration key shown for that spell.
			match spell:
				"plague_cloud":
					key = "duration"
				"corpse_explosion":
					key = "zone_duration" if ab.evolved.has(spell) else ""
				"shadow_blast":
					key = "slow_duration"
			if key != "":
				var d := float(ab.spell_stats(spell)[key])  # Effective duration now.
				var k := (1.0 + float(nxt["spell_duration"])) / (1.0 + ab.passive_value(id, "spell_duration"))  # Ratio after / before.
				deltas.append("%s duration %ss -> %ss" % [ab.spell_name(spell), AbilityManager._fmt(d), AbilityManager._fmt(d * k)])


## First spell of `ids` the necromancer owns ("" if none).
func _first_owned(ids: Array) -> String:
	for id: String in ids:
		if game.abilities.spell_level(id) > 0:
			return id
	return ""


## One autotest summary line: per spell, damage dealt (and the evolved part),
## when it was learned / maxed, and spell-specific counters.
func summary_line() -> String:
	var ab := game.abilities  # The owning AbilityManager.
	var st := game.stats  # Run counters.
	var parts := PackedStringArray()  # One "id: ..." chunk per spell.
	for id: String in IDS:
		var lvl := ab.spell_level(id)  # Final level (0 = never learned).
		if lvl <= 0:
			parts.append("%s: not taken" % id)
			continue
		var srcs: Array = SOURCES[id]  # Base source first.
		var evo_dmg := damage_of(id) - float(st.get("dmg_" + String(srcs[0]), 0.0))  # Evolution's share.
		var extra := ""  # Spell-specific counters.
		match id:
			"bone_spear":
				extra = "volleys=%d" % int(st.get("spear_volleys", 0.0))
			"soul_siphon":
				extra = "healed=%d summon_heal=%d bursts=%d" % [int(st.get("siphon_healed", 0.0)), int(st.get("siphon_summon_heal", 0.0)), int(st.get("rapture_bursts", 0.0))]
			"corpse_explosion":
				extra = "bursts=%d chain=%d" % [int(st.get("corpse_bursts", 0.0)), int(st.get("eruption_chains", 0.0))]
			"plague_cloud":
				extra = "clouds=%d novas=%d rot_bonus_dmg=%d" % [int(st.get("plague_clouds", 0.0)), int(st.get("death_novas", 0.0)), int(st.get("rot_bonus_dmg", 0.0))]
		parts.append("%s: Lv%d%s dmg=%d (evolved %d) boss=%d %s" % [id, lvl, " EVOLVED" if ab.evolved.has(id) else "",
			int(damage_of(id)), int(evo_dmg), int(_boss_damage_of(id)), extra])
	return " | ".join(parts)


## Damage spell `id` dealt to bosses (bossdmg_* stats).
func _boss_damage_of(id: String) -> float:
	var total := 0.0  # Sum of the spell's bossdmg_* stats.
	for src: String in SOURCES[id]:
		total += float(game.stats.get("bossdmg_" + src, 0.0))
	return total
