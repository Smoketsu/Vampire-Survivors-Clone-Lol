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
## and Act IV's (owner-approved Act IV proposal; locked until earned), the
## same way (ACT4_IDS; each stage's own report line):
##   Paris's Arrow    -> ParisArrow       (evolves into Arrow of Fate)
## earned, UnlockData), each stage's in its own list with the generic NecroSpell
## hooks and its own autotest line (CitadelReport):
##   Scrap Swarm      -> ScrapSwarm       (evolves into Deathless Swarm; the Iron Citadel)
## and Act IV's (Mount Olympus, OLYMPUS_IDS: the same generic hooks; its own
## autotest line, OlympusReport):
##   Stolen Thunder   -> StolenThunder    (evolves into Gigantomachy)
## and Act IV's (each Act IV stage in its own list with the same hooks):
##   River Styx       -> RiverStyx        (evolves into Lethe's Flood; the Asphodel Underworld)
## and Act V's (each Act V stage in its own list with the same hooks; its own
## autotest line, ProvinceReport):
##   Hundred Shadows  -> HundredShadows   (evolves into Thousand Shadows; the Burning Province)
## Hundred Shadows also hears every spell hit (on_spell_hit(), called once per
## hit by CombatResolver.damage_enemy(): its clones echo the next spell cast).
## and Act V's (each Act V stage in its own list with the same hooks):
##   Black Sun        -> BlackSun         (evolves into Eclipse of Heaven; the Road to the Sun)
## and Act V's (Castle Kurogane, KUROGANE_IDS: the same generic hooks; its own
## autotest line, KuroganeReport.item_lines()):
##   Banner of the Dead -> BannerOfTheDead (evolves into Hundred Banners)
## and Act VI's (the Burning Gate, BURNING_GATE_IDS: stepped only; its own
## autotest line, BurningGateReport.item_lines()):
##   Brimstone        -> Brimstone        (evolves into Rain of Fire)
## and Act VI's (the Palace of Silk and Ash, SILK_PALACE_IDS: stepped only; its
## own autotest line, SilkPalaceReport.item_lines()):
##   Temptation ("tempt") -> TemptSpell (evolves into Unholy Desire)
## and Act VI's (Pandemonium, PANDEMONIUM_IDS: the same generic hooks; its own
## autotest line, PandemoniumReport.item_lines()):
##   Fall from Grace  -> FallFromGrace    (evolves into Lightbringer)
## and Act VII's (Ravensmoor, RAVENSMOOR_IDS: stepped only; its own autotest
## line, RavensmoorReport.item_lines()):
##   Moonfang         -> Moonfang         (evolves into Wolf of the Red Moon)
## and Act VII's (the Witchwood, WITCHWOOD_IDS: stepped only; its own autotest
## line, WitchwoodReport.item_lines()):
##   Hex Circle ("witch_circle") -> WitchCircle (evolves into Witches' Sabbath)
## and Act VII's (Castle Sanguis, CASTLE_SANGUIS_IDS: stepped only; its own
## autotest line, CastleSanguisReport.item_lines()):
##   Night Swarm      -> NightSwarm       (evolves into Nocturne)
## and Act VIII's (Skid Row, SKID_ROW_IDS: stepped only; its own autotest line,
## SkidRowReport.item_lines()):
##   Hearse Run       -> HearseRun        (evolves into Funeral Procession)
## and Act IX's (the Crash Site, CRASH_SITE_IDS: stepped, with a kill hook; its
## own autotest line, CrashSiteReport.item_lines()):
##   Bone Beetles     -> BoneBeetles      (evolves into Hive of Bone)
## and the Hall of the Slain's (the Barrow Fields, BARROW_FIELDS_IDS: stepped
## only; its own autotest line, BarrowFieldsReport.item_lines()):
##   Barrow Grasp     -> BarrowGrasp      (evolves into Barrow-Lord's Embrace)
## and Act VIII's (Fort Kessler, FORT_KESSLER_IDS: stepped only; its own
## autotest line, FortKesslerReport.item_lines()):
##   Bone Mines       -> BoneMines        (evolves into Killing Ground)
## and Act VIII's (Liberty Heights, LIBERTY_HEIGHTS_IDS: stepped only; its own
## autotest line, LibertyHeightsReport.item_lines()):
##   Hero's Fist      -> HerosFist        (evolves into Doomsday)
## and Act IX's (the Proving Moon, PROVING_MOON_IDS: stepped only; its own
## autotest line, ProvingMoonReport.item_lines()):
##   Soul Caster      -> SoulCaster       (evolves into Apex Predator)
## and Act IX's (the Ark, ARK_IDS: stepped only; its own autotest line,
## ArkReport.item_lines()):
##   Tractor Beam     -> TractorLift      (evolves into Abduction)
## and Act X's (the Smuggler's Cutter, CUTTER_IDS: stepped only; its own
## autotest line, CutterReport.item_lines()):
##   Chain Shot       -> ChainShot        (evolves into Keelhauler)
## and Act X's (the Treasure Galleon, GALLEON_IDS: stepped only; its own
## autotest line, GalleonReport.item_lines()):
##   Cannonade        -> Cannonade        (evolves into Dead Men's Broadside)
## and Act X's (the Maelstrom, MAELSTROM_IDS: stepped only; its own autotest
## line, MaelstromReport.item_lines()):
##   Anchor Drop      -> AnchorDrop       (evolves into Abyssal Mooring)
## and the Hall of the Slain's (temporarily Act XI; Valgard, VALGARD_IDS:
## stepped only; its own autotest line, ValgardReport.item_lines()):
##   Valkyrie Spear   -> ValkyrieSpear    (evolves into Chooser of the Slain)
## and Vigrid's (the Hall of the Slain's finale, VIGRID_IDS: stepped only; its
## own autotest line, VigridReport.item_lines()):
##   Gungnir          -> Gungnir          (evolves into Spear of the Hanged)
## and Act XII's (temporary: the Necropolis of Sand, NECROPOLIS_IDS: stepped,
## with a kill hook; its own autotest line, NecropolisReport.item_lines()):
##   Linen Bind       -> LinenBind        (evolves into Eternal Shroud)
## and the Hall of Two Truths' (temporary Act XII, TWO_TRUTHS_IDS: stepped only;
## its own autotest line, TwoTruthsReport.item_lines()):
##   Feather's Verdict -> FeathersVerdict (evolves into Heart Devoured)
## and the Silver Stair's (temporary Act XIII, SILVER_STAIR_IDS: stepped only;
## its own autotest line, SilverStairReport.item_lines()):
##   Flaming Sword    -> FlamingSword     (evolves into Sword at the Gate)
## and the Wheel of Thrones' (temporary Act XIII, WHEEL_OF_THRONES_IDS: stepped
## only; its own autotest line, WheelOfThronesReport.item_lines()):
##   Wheel of Eyes    -> WheelOfEyes      (evolves into Ophanim)
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
# --- Act IV: the Shores of Ilion ---
## Act IV's unlockable spells (the generic NecroSpell hooks: stepped, kill
## hooked and after-physics hooked like ACT3_IDS; each Act IV stage adds its
## own here; reported by the stage's own report, IlionReport.print_items()).
const ACT4_IDS := ["paris_arrow"]
# --- Act IV: Mount Olympus ---
## Mount Olympus's unlockable spell (Zeus's reward): stepped, kill hooked and
## after-physics hooked like CITADEL_IDS, reported by OlympusReport.
const OLYMPUS_IDS := ["stolen_thunder"]
# --- Act IV: the Asphodel Underworld ---
## The Asphodel Underworld's unlockable spell (Hades' reward): stepped, kill
## hooked and after-physics hooked like CITADEL_IDS, reported by UnderworldReport.
const UNDERWORLD_IDS := ["river_styx"]
# --- Act V: the Burning Province ---
## The Burning Province's unlockable spell (Kage's reward): stepped, kill
## hooked and after-physics hooked like UNDERWORLD_IDS, reported by ProvinceReport.
const PROVINCE_IDS := ["hundred_shadows"]
# --- Act V: the Road to the Sun ---
## The Road to the Sun's unlockable spell (Amaterasu's reward): stepped, kill
## hooked and after-physics hooked like UNDERWORLD_IDS, reported by SunRoadReport.
const SUN_ROAD_IDS := ["black_sun"]
# --- Act V: Castle Kurogane ---
## Castle Kurogane's unlockable spell (Shogun Kurogane's reward): stepped, kill
## hooked and after-physics hooked like UNDERWORLD_IDS, reported by KuroganeReport.
const KUROGANE_IDS := ["banner_of_the_dead"]
# --- Act VI: the Burning Gate ---
## The Burning Gate's unlockable spell (Moloch's reward): stepped like
## UNDERWORLD_IDS (no kill or after-physics hook), reported by BurningGateReport.
const BURNING_GATE_IDS := ["brimstone"]
# --- Act VI: the Palace of Silk and Ash ---
## The Palace of Silk and Ash's unlockable spell (Lilith's reward): stepped like
## KUROGANE_IDS (it needs no kill or after-physics hook), reported by
## SilkPalaceReport. Its id is "tempt" (never a kind or rule id).
const SILK_PALACE_IDS := ["tempt"]
# --- Act VI: Pandemonium ---
## Pandemonium's unlockable spell (the Morning Star's reward): stepped, kill
## hooked and after-physics hooked like KUROGANE_IDS, reported by PandemoniumReport.
const PANDEMONIUM_IDS := ["fall_from_grace"]
# --- Act VII: Ravensmoor ---
## Ravensmoor's unlockable spell (Vargr's reward): stepped like BURNING_GATE_IDS
## (no kill or after-physics hook), reported by RavensmoorReport.
const RAVENSMOOR_IDS := ["moonfang"]
# --- Act VII: the Witchwood ---
## The Witchwood's unlockable spell (Isolde's reward): stepped like
## BURNING_GATE_IDS (no kill or after-physics hook), reported by WitchwoodReport.
## Its id is "witch_circle" (never a kind or the witches' own circle tag).
const WITCHWOOD_IDS := ["witch_circle"]
# --- Act VII: Castle Sanguis ---
## Castle Sanguis's unlockable spell (Queen Carmilla and the Elder's reward):
## stepped only (no kill or after-physics hook), reported by CastleSanguisReport.
const CASTLE_SANGUIS_IDS := ["night_swarm"]
# --- Act VIII: Skid Row ---
## Skid Row's unlockable spell (Don Marrow's reward): stepped only (no kill or
## after-physics hook), reported by SkidRowReport.
const SKID_ROW_IDS := ["hearse_run"]
# --- Act VIII: Fort Kessler ---
## Fort Kessler's unlockable spell (General Harrow's reward): stepped only (no
## kill or after-physics hook), reported by FortKesslerReport. Its id is
## "bone_mines" (never the minefield's "kessler_mine").
const FORT_KESSLER_IDS := ["bone_mines"]
# --- Act VIII: Liberty Heights ---
## Liberty Heights's unlockable spell (Paragon's reward): stepped only (no kill
## or after-physics hook), reported by LibertyHeightsReport.
const LIBERTY_HEIGHTS_IDS := ["heros_fist"]
# --- Act IX: the Crash Site ---
## The Crash Site's unlockable spell (the Hive Mother's reward): stepped, with
## a kill hook (its beetles burst from slain foes; no after-physics hook),
## reported by CrashSiteReport.
const CRASH_SITE_IDS := ["bone_beetles"]
# --- Act IX: the Proving Moon ---
## The Proving Moon's unlockable spell (Vrask'Tal's reward): stepped only (no
## kill or after-physics hook), reported by ProvingMoonReport.
const PROVING_MOON_IDS := ["soul_caster"]
# --- Act IX: the Ark ---
## The Ark of the Concord's unlockable spell (the Harvester's reward): stepped
## only (no kill or after-physics hook), reported by ArkReport. Its id is
## "tractor_lift" (never the Concord's "tractor_beam" sound / event).
const ARK_IDS := ["tractor_lift"]
# --- Act X: the Smuggler's Cutter ---
## The Smuggler's Cutter's unlockable spell (Captain Crow's reward): stepped
## only (no kill or after-physics hook), reported by CutterReport.
const CUTTER_IDS := ["chain_shot"]
# --- Act X: the Treasure Galleon ---
## The Treasure Galleon's unlockable spell (Admiral Marrec's reward): stepped
## only (no kill or after-physics hook), reported by GalleonReport.
const GALLEON_IDS := ["cannonade"]
# --- Act X: the Maelstrom ---
## The Maelstrom's unlockable spell (Vandermere's reward): stepped only (no kill
## or after-physics hook), reported by MaelstromReport.
const MAELSTROM_IDS := ["anchor_drop"]
# --- Act XI (temporary): the Barrow Fields ---
## The Barrow Fields' unlockable spell (Hrimgar's reward): stepped only (no
## kill or after-physics hook), reported by BarrowFieldsReport.
const BARROW_FIELDS_IDS := ["barrow_grasp"]
# --- Act XI (temporary): Valgard ---
## Valgard's unlockable spell (Sigrun's reward): stepped only (no kill or
## after-physics hook; it sees its own kills), reported by ValgardReport.
const VALGARD_IDS := ["valkyrie_spear"]
# --- Act XI (temporary): Vigrid ---
## Vigrid's unlockable spell (Odin's reward): stepped only (no kill or
## after-physics hook), reported by VigridReport. Its id is "gungnir" (never
## Odin's own "odin_gungnir" damage tag).
const VIGRID_IDS := ["gungnir"]
# --- Act XII (temporary number): the Necropolis of Sand ---
## The Necropolis of Sand's unlockable spell (Anubis's reward): stepped, with a
## kill hook (a wrapped foe that dies rises as a Mummy), reported by
## NecropolisReport.
const NECROPOLIS_IDS := ["linen_bind"]
# --- Act XII (temporary number): the Temple of the Lioness ---
## The Temple of the Lioness's unlockable spell (Sekhmet's reward): stepped
## only (no kill or after-physics hook), reported by LionessTempleReport.
const LIONESS_TEMPLE_IDS := ["burning_eye"]
# --- Act XII (temporary number): the Hall of Two Truths ---
## The Hall of Two Truths' unlockable spell (Osiris and Ammit's reward):
## stepped only (no kill or after-physics hook), reported by TwoTruthsReport.
const TWO_TRUTHS_IDS := ["feathers_verdict"]
# --- Act XIII (temporary number): the Silver Stair ---
## The Silver Stair's unlockable spell (Seraiel's reward): stepped only (no
## kill or after-physics hook), reported by SilverStairReport.
const SILVER_STAIR_IDS := ["flaming_sword"]
# --- Act XIII (temporary number): the Wheel of Thrones ---
## The Wheel of Thrones' unlockable spell (the Throne's reward): stepped only
## (no kill or after-physics hook), reported by WheelOfThronesReport.
const WHEEL_OF_THRONES_IDS := ["wheel_of_eyes"]
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
	# --- Act IV: the Shores of Ilion ---
	"paris_arrow": ["paris_arrow", "arrow_of_fate"],
	# --- Act IV: Mount Olympus ---
	"stolen_thunder": ["stolen_thunder", "gigantomachy", "thunderclap"],
	# --- Act IV: the Asphodel Underworld ---
	"river_styx": ["river_styx", "lethes_flood"],
	# --- Act V: the Burning Province ---
	"hundred_shadows": ["hundred_shadows", "thousand_shadows"],
	# --- Act V: the Road to the Sun ---
	"black_sun": ["black_sun", "eclipse_of_heaven", "eclipse_corona"],
	# --- Act V: Castle Kurogane ---
	"banner_of_the_dead": ["banner_of_the_dead", "hundred_banners"],
	# --- Act VI: the Burning Gate ---
	"brimstone": ["brimstone", "rain_of_fire", "brimstone_pit"],
	# --- Act VI: the Palace of Silk and Ash --- (the thralls' blows, Unholy Desire's burst, the Succubus Queen's Heartbreaker)
	"tempt": ["tempt", "unholy_desire", "desire_burst", "tempt_heartbreak"],
	# --- Act VI: Pandemonium ---
	"fall_from_grace": ["fall_from_grace", "lightbringer", "lightbringer_flare"],
	# --- Act VII: Ravensmoor ---
	"moonfang": ["moonfang", "wolf_of_the_red_moon", "moonfang_bleed"],
	# --- Act VII: the Witchwood ---
	"witch_circle": ["witch_circle", "witches_sabbath"],
	# --- Act VII: Castle Sanguis ---
	"night_swarm": ["night_swarm", "nocturne", "nocturne_leap"],
	# --- Act VIII: Skid Row ---
	"hearse_run": ["hearse_run", "funeral_procession"],
	# --- Act VIII: Fort Kessler ---
	"bone_mines": ["bone_mines", "killing_ground", "killing_ground_shards"],
	# --- Act VIII: Liberty Heights ---
	"heros_fist": ["heros_fist", "heros_fist_fling", "doomsday", "doomsday_crater"],
	# --- Act IX: the Crash Site ---
	"bone_beetles": ["bone_beetles", "hive_of_bone"],
	# --- Act IX: the Proving Moon ---
	"soul_caster": ["soul_caster", "apex_predator"],
	# --- Act IX: the Ark ---
	"tractor_lift": ["tractor_lift", "star_abduction", "star_abduction_quake"],
	# --- Act X: the Smuggler's Cutter ---
	"chain_shot": ["chain_shot", "keelhauler"],
	# --- Act X: the Treasure Galleon ---
	"cannonade": ["cannonade", "dead_mens_broadside"],
	# --- Act X: the Maelstrom ---
	"anchor_drop": ["anchor_drop", "anchor_drop_shock", "abyssal_mooring", "abyssal_mooring_shock"],
	# --- Act XI (temporary): the Barrow Fields ---
	"barrow_grasp": ["barrow_grasp", "barrow_lords_embrace"],
	# --- Act XI (temporary): Valgard ---
	"valkyrie_spear": ["valkyrie_spear", "chooser_of_the_slain"],
	# --- Act XI (temporary): Vigrid ---
	"gungnir": ["gungnir", "spear_of_the_hanged"],
	# --- Act XII (temporary number): the Necropolis of Sand ---
	"linen_bind": ["linen_bind", "eternal_shroud"],
	# --- Act XII (temporary number): the Temple of the Lioness ---
	"burning_eye": ["burning_eye", "eye_of_retribution"],
	# --- Act XII (temporary number): the Hall of Two Truths ---
	"feathers_verdict": ["feathers_verdict", "feathers_verdict_execute", "heart_devoured", "heart_devoured_execute"],
	# --- Act XIII (temporary number): the Silver Stair ---
	"flaming_sword": ["flaming_sword", "sword_at_the_gate"],
	# --- Act XIII (temporary number): the Wheel of Thrones ---
	"wheel_of_eyes": ["wheel_of_eyes", "ophanim"],
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
		if id in IDS or ab.spell_level(id) <= 0:
			continue  # Forbidden Verse and Call of the Drowned are also in IDS: stepped once, above.
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))
	for id: String in ACT3_IDS + CITADEL_IDS + ACT4_IDS + OLYMPUS_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))
	# --- Act IV: the Asphodel Underworld ---
	for id: String in UNDERWORLD_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))
	# --- Act V: the Burning Province ---
	for id: String in PROVINCE_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()); Hundred Shadows' clones.
		node.step(delta, ab.spell_stats(id))
	# --- Act V: the Road to the Sun ---
	for id: String in SUN_ROAD_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))
	# --- Act V: Castle Kurogane ---
	for id: String in KUROGANE_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # Castle Kurogane's spell.
	# --- Act VI: the Burning Gate ---
	for id: String in BURNING_GATE_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Burning Gate's spell.
	# --- Act VI: the Palace of Silk and Ash ---
	for id: String in SILK_PALACE_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Palace of Silk and Ash's spell.
	# --- Act VI: Pandemonium ---
	for id: String in PANDEMONIUM_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # Pandemonium's spell.
	# --- Act VII: Ravensmoor ---
	for id: String in RAVENSMOOR_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # Ravensmoor's spell.
	# --- Act VII: the Witchwood ---
	for id: String in WITCHWOOD_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Witchwood's spell.
	# --- Act VII: Castle Sanguis ---
	for id: String in CASTLE_SANGUIS_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # Castle Sanguis's spell.
	# --- Act VIII: Skid Row ---
	for id: String in SKID_ROW_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # Skid Row's spell.
	# --- Act VIII: Fort Kessler ---
	for id: String in FORT_KESSLER_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # Fort Kessler's spell.
	# --- Act VIII: Liberty Heights ---
	for id: String in LIBERTY_HEIGHTS_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # Liberty Heights's spell.
	# --- Act IX: the Crash Site ---
	for id: String in CRASH_SITE_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Crash Site's spell.
	# --- Act IX: the Proving Moon ---
	for id: String in PROVING_MOON_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Proving Moon's spell.
	# --- Act IX: the Ark ---
	for id: String in ARK_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Ark's spell.
	# --- Act X: the Smuggler's Cutter ---
	for id: String in CUTTER_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Cutter's spell.
	# --- Act X: the Treasure Galleon ---
	for id: String in GALLEON_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Treasure Galleon's spell.
	# --- Act X: the Maelstrom ---
	for id: String in MAELSTROM_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Maelstrom's spell.
	# --- Act XI (temporary): the Barrow Fields ---
	for id: String in BARROW_FIELDS_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Barrow Fields' spell.
	# --- Act XI (temporary): Valgard ---
	for id: String in VALGARD_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # Valgard's spell.
	# --- Act XI (temporary): Vigrid ---
	for id: String in VIGRID_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # Vigrid's spell.
	# --- Act XII (temporary number): the Necropolis of Sand ---
	for id: String in NECROPOLIS_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Necropolis's spell.
	# --- Act XII (temporary number): the Temple of the Lioness ---
	for id: String in LIONESS_TEMPLE_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Temple of the Lioness's spell.
	# --- Act XII (temporary number): the Hall of Two Truths ---
	for id: String in TWO_TRUTHS_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Hall of Two Truths' spell.
	# --- Act XIII (temporary number): the Silver Stair ---
	for id: String in SILVER_STAIR_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Silver Stair's spell.
	# --- Act XIII (temporary number): the Wheel of Thrones ---
	for id: String in WHEEL_OF_THRONES_IDS:
		if ab.spell_level(id) <= 0:
			continue
		var node: NecroSpell = nodes.get(id)  # The spell's node (created lazily).
		if node == null:
			node = _create(id)
		node.origin = game.player.position  # Co-op drawing (NecroSpell.caster_pos()).
		node.step(delta, ab.spell_stats(id))  # The Wheel of Thrones' spell.


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
		# --- Act IV: the Shores of Ilion ---
		"paris_arrow":
			node = ParisArrow.new()
		# --- Act IV: Mount Olympus ---
		"stolen_thunder":
			node = StolenThunder.new()
		# --- Act IV: the Asphodel Underworld ---
		"river_styx":
			node = RiverStyx.new()
		# --- Act V: the Burning Province ---
		"hundred_shadows":
			node = HundredShadows.new()
		# --- Act V: the Road to the Sun ---
		"black_sun":
			node = BlackSun.new()
		# --- Act V: Castle Kurogane ---
		"banner_of_the_dead":
			node = BannerOfTheDead.new()
		# --- Act VI: the Burning Gate ---
		"brimstone":
			node = Brimstone.new()  # The Burning Gate's spell.
		# --- Act VI: the Palace of Silk and Ash ---
		"tempt":
			node = TemptSpell.new()  # Temptation (its id "tempt").
		# --- Act VI: Pandemonium ---
		"fall_from_grace":
			node = FallFromGrace.new()  # Pandemonium's spell.
		# --- Act VII: Ravensmoor ---
		"moonfang":
			node = Moonfang.new()  # Ravensmoor's spell.
		# --- Act VII: the Witchwood ---
		"witch_circle":
			node = WitchCircle.new()  # Hex Circle (its id "witch_circle").
		# --- Act VII: Castle Sanguis ---
		"night_swarm":
			node = NightSwarm.new()  # Castle Sanguis's spell.
		# --- Act VIII: Skid Row ---
		"hearse_run":
			node = HearseRun.new()  # Skid Row's spell.
		# --- Act VIII: Fort Kessler ---
		"bone_mines":
			node = BoneMines.new()  # Fort Kessler's spell.
		# --- Act VIII: Liberty Heights ---
		"heros_fist":
			node = HerosFist.new()  # Liberty Heights's spell.
		# --- Act IX: the Crash Site ---
		"bone_beetles":
			node = BoneBeetles.new()  # The Crash Site's spell.
		# --- Act IX: the Proving Moon ---
		"soul_caster":
			node = SoulCaster.new()  # The Proving Moon's spell.
		# --- Act IX: the Ark ---
		"tractor_lift":
			node = TractorLift.new()  # The Ark's spell.
		# --- Act X: the Smuggler's Cutter ---
		"chain_shot":
			node = ChainShot.new()  # The Cutter's spell.
		# --- Act X: the Treasure Galleon ---
		"cannonade":
			node = Cannonade.new()  # The Treasure Galleon's spell.
		# --- Act X: the Maelstrom ---
		"anchor_drop":
			node = AnchorDrop.new()  # The Maelstrom's spell.
		# --- Act XI (temporary): the Barrow Fields ---
		"barrow_grasp":
			node = BarrowGrasp.new()  # The Barrow Fields' spell.
		# --- Act XI (temporary): Valgard ---
		"valkyrie_spear":
			node = ValkyrieSpear.new()  # Valgard's spell.
		# --- Act XI (temporary): Vigrid ---
		"gungnir":
			node = Gungnir.new()  # Vigrid's spell.
		# --- Act XII (temporary number): the Necropolis of Sand ---
		"linen_bind":
			node = LinenBind.new()  # The Necropolis's spell.
		# --- Act XII (temporary number): the Temple of the Lioness ---
		"burning_eye":
			node = BurningEye.new()  # The Temple of the Lioness's spell.
		# --- Act XII (temporary number): the Hall of Two Truths ---
		"feathers_verdict":
			node = FeathersVerdict.new()  # The Hall of Two Truths' spell.
		# --- Act XIII (temporary number): the Silver Stair ---
		"flaming_sword":
			node = FlamingSword.new()  # The Silver Stair's spell.
		# --- Act XIII (temporary number): the Wheel of Thrones ---
		"wheel_of_eyes":
			node = WheelOfEyes.new()  # The Wheel of Thrones' spell.
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
	for id: String in ACT3_IDS + CITADEL_IDS + ACT4_IDS + OLYMPUS_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act III spell's node, if learned.
		if node != null:
			node.on_enemy_killed(e)
	for id: String in UNDERWORLD_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act IV spell's node, if learned (the Underworld).
		if node != null:
			node.on_enemy_killed(e)
	# --- Act V: the Burning Province ---
	for id: String in PROVINCE_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act V spell's node, if learned (the Province).
		if node != null:
			node.on_enemy_killed(e)
	# --- Act V: the Road to the Sun ---
	for id: String in SUN_ROAD_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act V spell's node, if learned (the Road to the Sun).
		if node != null:
			node.on_enemy_killed(e)
	# --- Act V: Castle Kurogane ---
	for id: String in KUROGANE_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act V spell's node, if learned (Castle Kurogane).
		if node != null:
			node.on_enemy_killed(e)  # Castle Kurogane's spell.
	# --- Act VI: Pandemonium ---
	for id: String in PANDEMONIUM_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act VI spell's node, if learned (Pandemonium).
		if node != null:
			node.on_enemy_killed(e)  # Pandemonium's spell.
	# --- Act IX: the Crash Site ---
	for id: String in CRASH_SITE_IDS:
		var node: NecroSpell = nodes.get(id)  # The Crash Site's spell node, if learned.
		if node != null:
			node.on_enemy_killed(e)  # Bone Beetles: a slain foe bursts into beetles.
	# --- Act XII (temporary number): the Necropolis of Sand ---
	for id: String in NECROPOLIS_IDS:
		var node: NecroSpell = nodes.get(id)  # The Necropolis's spell node, if learned.
		if node != null:
			node.on_enemy_killed(e)  # Linen Bind: a wrapped foe rises as a Mummy.


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
	for id: String in ACT3_IDS + CITADEL_IDS + ACT4_IDS + OLYMPUS_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act III spell's node, if learned.
		if node != null:
			node.after_physics(delta)
	for id: String in UNDERWORLD_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act IV spell's node, if learned (the Underworld).
		if node != null:
			node.after_physics(delta)
	# --- Act V: the Road to the Sun --- (this loop and Castle Kurogane's run before the Province's, whose block runs on into on_spell_hit())
	for id: String in SUN_ROAD_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act V spell's node, if learned (the Road to the Sun).
		if node != null:
			node.after_physics(delta)
	# --- Act V: Castle Kurogane ---
	for id: String in KUROGANE_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act V spell's node, if learned (Castle Kurogane).
		if node != null:
			node.after_physics(delta)  # Castle Kurogane's spell.
	# --- Act V: the Burning Province ---
	for id: String in PROVINCE_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act V spell's node, if learned (the Province).
		if node != null:
			node.after_physics(delta)
	# --- Act VI: Pandemonium ---
	for id: String in PANDEMONIUM_IDS:
		var node: NecroSpell = nodes.get(id)  # An Act VI spell's node, if learned (Pandemonium).
		if node != null:
			node.after_physics(delta)  # Pandemonium's spell.


# --- Act V: the Burning Province ---
## A spell hit landed (CombatResolver.damage_enemy(), once per hit, only while
## Hundred Shadows is learned): `amount` damage on `e` tagged `source`. Hundred
## Shadows' clones echo the necromancer's next spell (HundredShadows.on_spell_hit());
## a hit that is no spell (HundredShadowsData.is_spell_source()) is ignored.
func on_spell_hit(e: Enemy, amount: float, source: String) -> void:
	if not HundredShadowsData.is_spell_source(source):
		return
	var node: HundredShadows = nodes.get(HundredShadowsData.ID)  # The spell's node, if it ever stepped.
	if node != null:
		node.on_spell_hit(e, amount)


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
