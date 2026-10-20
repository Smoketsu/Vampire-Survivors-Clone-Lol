## NecroSpellBook — owns and drives the newer necromancer spells (user
## request "more weapons", AbilityData header) behind ONE small dispatch in
## AbilityManager (setup / step / on_enemy_killed / passive card lines):
##   Bone Spear       -> BoneSpear        (evolves into Ossuary Lance)
##   Soul Siphon      -> SoulSiphon       (evolves into Soul Rapture)
##   Corpse Explosion -> CorpseExplosion  (evolves into Grave Eruption)
##   Plague Cloud     -> PlagueCloud      (evolves into Pestilence)
## and the five later spells (owner-approved, GDD §15.0 "Five more spells"),
## which use NecroSpell's optional hooks (on_enemy_killed, after_physics,
## summary_extra) instead of named calls here:
##   Death Mark       -> DeathMark        (evolves into Doom Brand)
##   Bone Wall        -> BoneWall         (evolves into Charnel Bastion)
##   Soul Chains      -> SoulChains       (evolves into Chains of the Damned)
##   Wither           -> Wither           (evolves into Necrotic Blight)
##   Raise Dead       -> RaiseDead        (evolves into Legion of Bones)
## Act II's abyssal spells (owner-approved, GDD §15.0; ACT2_IDS) join the
## same dispatch and the generic NecroSpell hooks, with their own autotest
## lines (HarbourReport) so the Act I summaries keep their text:
##   Undertow         -> Undertow         (evolves into Maelstrom)
## and Act II's unlockable spells (GDD §15.0 "Act II: the Ancient Eye"; locked
## until earned, UnlockData), same generic NecroSpell hooks, their own
## autotest line (act2_summary_line(), printed only when one was taken):
##   Forbidden Verse  -> ForbiddenVerse   (evolves into The Unwritten Word)
## and Act III's unlockable spells (owner-approved Act III proposal; locked until
## earned, UnlockData), same generic NecroSpell hooks, their own autotest line
## (WastesReport.print_items(), only when one was taken; ACT3_IDS, so the Act I
## and Act II lines keep their text):
##   Death Ray        -> DeathRay         (evolves into Event Horizon)
## earned, UnlockData), each stage's in its own list with the generic NecroSpell
## hooks and its own autotest line (CitadelReport):
##   Scrap Swarm      -> ScrapSwarm       (evolves into Deathless Swarm; the Iron Citadel)
## Game calls after_physics() once per tick after obstacles are resolved
## (Bone Wall holds enemies there).
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
const IDS := ["bone_spear", "soul_siphon", "corpse_explosion", "plague_cloud",
	"death_mark", "bone_wall", "soul_chains", "wither", "raise_dead",
	# --- Act II: the Hollow Archive ---
	"forbidden_verse",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"call_of_the_drowned"]
## The five later spells (their own autotest line, later_summary_line(), and
## the generic NecroSpell hooks).
const LATER_IDS := ["death_mark", "bone_wall", "soul_chains", "wither", "raise_dead"]
## Act II's abyssal spells (unlockable; the generic NecroSpell hooks, their
## own autotest lines: HarbourReport per spell, act2_summary_line() for all).
const ACT2_IDS := [
	# --- Act II: Gullhaven Harbour ---
	"undertow",
	# --- Act II: the Hollow Archive ---
	"forbidden_verse",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"call_of_the_drowned",
	# --- Act III: the Assembly Halls --- (an unlockable spell of the next act:
	# the same generic hooks and act2_summary_line(); its own EmpireReport line)
	"hollow_puppet",
]
## Act III's unlockable spells (the generic NecroSpell hooks; their own autotest
## line, WastesReport.print_items(); each Act III stage adds its own here).
const ACT3_IDS := [
	# --- Act III: the Scrap Wastes ---
	"death_ray",
]
# --- Act III: the Iron Citadel ---
## The Iron Citadel's unlockable spell (Deus Ex Machina's reward): stepped, kill
## hooked and after-physics hooked like ACT2_IDS, reported by CitadelReport.
const CITADEL_IDS := ["scrap_swarm"]
## Damage-source stat tags of each spell (CombatResolver "dmg_<tag>"), base
## spell first, then its evolution's. Used for the autotest summary.
const SOURCES := {
	"bone_spear": ["spear", "lance"],
	"soul_siphon": ["siphon", "rapture", "rapture_burst"],
	"corpse_explosion": ["corpse", "eruption", "eruption_spikes"],
	"plague_cloud": ["plague", "pestilence", "death_nova"],
	"death_mark": ["death_mark", "doom_brand", "doom_burst"],
	"bone_wall": ["bone_wall", "bastion", "bastion_shrapnel"],
	"soul_chains": ["soul_chains", "chains_damned"],
	"wither": ["wither", "blight"],
	"raise_dead": ["raised_dead", "legion_burst"],
	# --- Act II: Gullhaven Harbour ---
	"undertow": ["undertow", "maelstrom"],
	# --- Act II: the Hollow Archive ---
	"forbidden_verse": ["verse", "unwritten_word", "ink_burst"],
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"call_of_the_drowned": ["drowned_tendril", "tide_tendril"],
	# --- Act III: the Assembly Halls ---
	"hollow_puppet": ["hollow_puppet", "puppet_burst"],
	# --- Act III: the Scrap Wastes ---
	"death_ray": ["death_ray", "event_horizon", "ray_spark"],
	# --- Act III: the Iron Citadel ---
	"scrap_swarm": ["scrap_swarm", "deathless_swarm"],
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
			if nodes.has(id):
				(nodes[id] as NecroSpell).idle_step(delta)  # Content wave 2: a Titan's wall without the spell.
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))
	for id: String in ACT2_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))
	for id: String in ACT3_IDS + CITADEL_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))


## Content wave 2: the Bone Wall node, created when missing (the Ossuary
## Titan's collapse wall reuses its segment system, BoneWall.raise_wall(),
## also when the spell was never learned: the node then only ages its walls,
## NecroSpell.idle_step(), and after_physics() still pushes enemies out).
func bone_wall_node() -> BoneWall:
	var node: BoneWall = nodes.get("bone_wall")  # Existing node, or null.
	if node == null:
		node = _create("bone_wall") as BoneWall
	return node


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
		"death_mark":
			node = DeathMark.new()
		"bone_wall":
			node = BoneWall.new()
		"soul_chains":
			node = SoulChains.new()
		"wither":
			node = Wither.new()
		"raise_dead":
			node = RaiseDead.new()
		"undertow":
			node = Undertow.new()  # Act II: Gullhaven Harbour.
		# --- Act II: the Hollow Archive ---
		"forbidden_verse":
			node = ForbiddenVerse.new()
		"call_of_the_drowned":
			node = CallOfTheDrowned.new()  # Act II: Ul-Thalos, the Risen Spire.
		"hollow_puppet":
			node = HollowPuppet.new()  # Act III: the Assembly Halls.
		# --- Act III: the Scrap Wastes ---
		"death_ray":
			node = DeathRay.new()
		# --- Act III: the Iron Citadel ---
		"scrap_swarm":
			node = ScrapSwarm.new()
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
	for id: String in LATER_IDS:
		var node: NecroSpell = nodes.get(id)  # A later spell's node, if learned.
		if node != null:
			node.on_enemy_killed(e)
	for id: String in ACT2_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act II spell's node, if learned.
		if node != null:
			node.on_enemy_killed(e)
	for id: String in ACT3_IDS + CITADEL_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act III spell's node, if learned.
		if node != null:
			node.on_enemy_killed(e)


## Post-movement hook (Game._physics_process, after Arena.resolve_all()):
## lets the later spells act on final enemy positions (Bone Wall push-out).
func after_physics(delta: float) -> void:
	for id: String in LATER_IDS:
		var node: NecroSpell = nodes.get(id)  # A later spell's node, if learned.
		if node != null:
			node.after_physics(delta)
	for id: String in ACT2_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act II spell's node, if learned.
		if node != null:
			node.after_physics(delta)
	for id: String in ACT3_IDS + CITADEL_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act III spell's node, if learned.
		if node != null:
			node.after_physics(delta)


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
		"grim_ledger", "spirit_binding", "restless_dead":
			var line := GraveSpellLines.passive_line(game, id, nxt)  # The later spells' passives.
			if line != "":
				deltas.append(line)


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
		if id in LATER_IDS or id in ACT2_IDS:
			continue  # Reported by later_summary_line() / act2_summary_line().
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


## The autotest line of the five later spells: per spell its level (and
## EVOLVED), damage (and the evolved part), boss damage, kills and the
## spell's own counters (NecroSpell.summary_extra()).
func later_summary_line() -> String:
	var ab := game.abilities  # The owning AbilityManager.
	var st := game.stats  # Run counters.
	var parts := PackedStringArray()  # One "id: ..." chunk per spell.
	for id: String in LATER_IDS:
		var lvl := ab.spell_level(id)  # Final level (0 = never learned).
		if lvl <= 0:
			parts.append("%s: not taken" % id)
			continue
		var srcs: Array = SOURCES[id]  # Base source first.
		var evo_dmg := damage_of(id) - float(st.get("dmg_" + String(srcs[0]), 0.0))  # Evolution's share.
		var node: NecroSpell = nodes.get(id)  # Its node (null if never ticked).
		parts.append("%s: Lv%d%s dmg=%d (evolved %d) boss=%d kills=%d %s" % [id, lvl, " EVOLVED" if ab.evolved.has(id) else "",
			int(damage_of(id)), int(evo_dmg), int(_boss_damage_of(id)), int(kills_of(id)),
			node.summary_extra() if node != null else ""])
	return " | ".join(parts)


## The autotest line of one Act II spell `id` (HarbourReport): its level (and
## EVOLVED), damage (and the evolved part), boss damage, kills and the spell's
## own counters; "" when it was never learned.
func act2_summary(id: String) -> String:
	var ab := game.abilities  # The owning AbilityManager.
	var lvl := ab.spell_level(id)  # Final level (0 = never learned).
	if lvl <= 0:
		return ""
	var srcs: Array = SOURCES[id]  # Base source first.
	var evo_dmg := damage_of(id) - float(game.stats.get("dmg_" + String(srcs[0]), 0.0))  # Evolution's share.
	var node: NecroSpell = nodes.get(id)  # Its node (null if never ticked).
	return "%s: Lv%d%s dmg=%d (evolved %d) boss=%d kills=%d %s" % [id, lvl, " EVOLVED" if ab.evolved.has(id) else "",
		int(damage_of(id)), int(evo_dmg), int(_boss_damage_of(id)), int(kills_of(id)),
		node.summary_extra() if node != null else ""]
## The autotest line of Act II's unlockable spells (same layout as
## later_summary_line()); "" when none was ever learned this run, so the
## autotest prints it only then.
func act2_summary_line() -> String:
	var ab := game.abilities  # The owning AbilityManager.
	var st := game.stats  # Run counters.
	var parts := PackedStringArray()  # One "id: ..." chunk per spell.
	var any := false  # True once one of them was learned.
	for id: String in ACT2_IDS:
		var lvl := ab.spell_level(id)  # Final level (0 = never learned).
		if lvl <= 0:
			parts.append("%s: not taken" % id)
			continue
		any = true
		var srcs: Array = SOURCES[id]  # Base source first.
		var evo_dmg := damage_of(id) - float(st.get("dmg_" + String(srcs[0]), 0.0))  # Evolution's share (and the bursts).
		var node: NecroSpell = nodes.get(id)  # Its node (null if never ticked).
		parts.append("%s: Lv%d%s dmg=%d (beyond the base cut %d) boss=%d kills=%d %s" % [id, lvl, " EVOLVED" if ab.evolved.has(id) else "",
			int(damage_of(id)), int(evo_dmg), int(_boss_damage_of(id)), int(kills_of(id)),
			node.summary_extra() if node != null else ""])
	return " | ".join(parts) if any else ""


## Killing blows landed by spell `id` (kills_by_* stats of its sources).
func kills_of(id: String) -> float:
	var total := 0.0  # Sum of the spell's kills_by_* stats.
	for src: String in SOURCES[id]:
		total += float(game.stats.get("kills_by_" + src, 0.0))
	return total


## Damage spell `id` dealt to bosses (bossdmg_* stats).
func _boss_damage_of(id: String) -> float:
	var total := 0.0  # Sum of the spell's bossdmg_* stats.
	for src: String in SOURCES[id]:
		total += float(game.stats.get("bossdmg_" + src, 0.0))
	return total
