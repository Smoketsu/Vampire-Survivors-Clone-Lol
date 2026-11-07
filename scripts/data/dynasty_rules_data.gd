## DynastyRulesData — the numbers of THE NECROPOLIS DYNASTY's shared rules
## (temporary Act XII, final slot VII; GDD §15.0 "The Necropolis Dynasty
## foundation (phase 1)", "Rebirth", "The Black Land", "Heka" and "The
## Devourer's Hour"; proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 3 and
## the Dynasty section of docs/proposals/LAST_SIX_ACTS.md, which wins where
## they differ). Read by DynastyRules (Game.dynasty) and its parts:
##   REBIRTH    — Rebirth: the cartouche over a fallen mummy or guardian, the
##                return, the raise that steals the Name, the smash, the
##                Canopic Jars that hold the Names, the Embalmers' haste.
##   JARS       — the stubs' own Canopic Jars (phase 2 stages place theirs
##                with Rebirth.place_jar()).
##   QUICKSAND  — the Black Land's ground: quicksand patches (TerrainSlow).
##   SANDSTORM  — the Black Land's clock: the Sandstorm (one clock path).
##   HEKA       — words of power: the glyph on a summon
##                (CombatResolver.curse_unit(), the one curse path).
##   DEVOURER   — the Reckoning, the Devourer's Hour.
## A stage's STAGE "rebirth" / "jars" / "quicksand" / "sandstorm" / "heka"
## dictionaries override any key here; its RECKONING "devourers_hour"
## overrides DEVOURER. Data only, no logic. Every value is TUNING (not in GDD)
## unless it is marked as the owner-approved proposal.
class_name DynastyRulesData
extends RefCounted

## Faction id of the Dynasty's kinds (row "faction").
const FACTION: String = "dynasty"
## The roster's groups in order (row "group"; the Codex and the report group
## by them): the wrapped dead, the sacred beasts, the guard, the priesthood,
## stone and jars.
const GROUPS: Array[String] = ["dead", "beasts", "guard", "priests", "stone"]

# --- Rebirth (Rebirth; one path) ---------------------------------------------------------
## Rebirth's numbers (a stage's STAGE "rebirth" overrides any key).
const REBIRTH := {
	"duration": 6.0,  # Owner-approved proposal: "a gold cartouche floats over the corpse for 6 s"
	"return_hp": 0.7,  # Owner-approved proposal: "returns at 70% HP"
	"damage_mult": 1.2,  # Owner-approved proposal: "+20% damage stamp" (x per return, so x1.44 after the second)
	"max_returns": 2,  # Owner-approved proposal: "at most twice per body"
	"steal_radius": 30.0,  # TUNING (not in GDD) px: a raise (HordeDirector.raise_corpse()) this close to a cartouche steals its Name
	"jar_radius": 300.0,  # Owner-approved proposal: "Canopic Jars hold the Names of every body within 300 px"
	"embalm_radius": 150.0,  # TUNING (not in GDD) px: a live Embalmer this close to a cartouche hastens it
	"embalm_speed": 2.0,  # Owner-approved proposal: "the cartouche timer -3 s nearby" (6 s run at x2 = 3 s)
	"max_cartouches": 40,  # TUNING (not in GDD) most cartouches at once (a body past it simply stays dead; counted)
	"jars_required": false,  # TUNING (not in GDD) true: only a body a live jar holds gets a cartouche (phase 2: Anubis's Procession may set it)
	"icon_shrink_from": 10,  # TUNING (not in GDD) drawing only: from this many cartouches the icon shrinks (proposal risks: "shrink the icon with the count")
	"icon_min_scale": 0.6,  # TUNING (not in GDD) drawing only: the smallest icon scale
}
## Kind id of the cartouche (a 1-hit structure row, DynastyEnemyData).
const CARTOUCHE: String = "cartouche"
## Max HP a cartouche is set to at activation, whatever the HP scalings (so
## every hit that reaches it smashes it: proposal, "one hit from any source").
const CARTOUCHE_HP: float = 0.01  # TUNING (not in GDD) one hit from any source

# --- The stubs' Canopic Jars ---------------------------------------------------------------
## The stubs' Canopic Jars (Rebirth): from `first` s, every `every` s a jar
## rises out of the sand `min`..`max` px from a standing necromancer (the
## seeded gameplay RNG), at most `max_alive` standing; a telegraph circle for
## `warn` s first. "every" 0 = off (a phase 2 stage that places its jars
## beside its tombs with Rebirth.place_jar()).
const JARS := {
	"first": 100.0,  # TUNING (not in GDD) s
	"every": 110.0,  # TUNING (not in GDD) s
	"max_alive": 2,  # TUNING (not in GDD)
	"min": 220.0,  # TUNING (not in GDD) px
	"max": 360.0,  # TUNING (not in GDD) px
	"warn": 1.2,  # TUNING (not in GDD) s
}

# --- The Black Land: quicksand (Quicksand; TerrainSlow) -----------------------------------
## Quicksand patches: fixed patches from a pure hash of the world cells (cell
## px; chance per cell; radius radius_min..radius_max px), the same in every
## run of a stage (salted by the arena layout seed); only those within
## active_radius of a standing necromancer are live (rebuilt every `refresh`
## s); none within clear_radius of the arena centre (the start). Every `tick`
## s a body standing in one is slowed for `linger` s: the necromancer and the
## summons by `slow` through TerrainSlow (Brinewalker as on every ground
## slow, then the Dune Walkers hook), the enemies by enemy_slow (their own
## slow path; fliers and floating kinds pass over). Quicksand.add_patch() is
## the public call for phase 2 (the Crocodile Warden rises from it).
const QUICKSAND := {
	"cell": 420.0,  # TUNING (not in GDD) px
	"chance": 0.24,  # TUNING (not in GDD) 0..1 per cell
	"radius_min": 40.0,  # TUNING (not in GDD) px
	"radius_max": 66.0,  # TUNING (not in GDD) px
	"active_radius": 900.0,  # TUNING (not in GDD) px
	"refresh": 0.5,  # TUNING (not in GDD) s
	"clear_radius": 280.0,  # TUNING (not in GDD) px round the start
	"tick": 0.25,  # TUNING (not in GDD) s
	"linger": 0.4,  # TUNING (not in GDD) s
	"slow": 0.4,  # TUNING (not in GDD) 0..1 of move speed lost (the necromancer, the summons)
	"enemy_slow": 0.3,  # TUNING (not in GDD) 0..1 (the enemies: "Quicksand patches slow everyone")
	"max_added": 12,  # TUNING (not in GDD) most add_patch() patches at once
	"seed": 0,  # 0 = the stage's arena layout_seed salts the hash
}

# --- The Black Land: the Sandstorm (Sandstorm; one clock path) ----------------------------
## The Sandstorm: from `first` s, every `every` s it blows for `duration` s,
## shown `warn` s ahead on the HUD (owner-approved proposal: "every 5:00, a
## Sandstorm blows for 40 s (shown 10 s ahead on the HUD). During it ranged
## weapons have half range for both armies ... and enemies are partially
## hidden beyond 300 px"). reach_mult is x every ranged reach while it blows
## (the ranged summons' attack range in HordeDirector.compute_stats(), the
## spells' "range" in AbilityManager, the volleys' flight, the enemies'
## ranged attack range through DynastyKit); hide_radius is where the veil
## starts (drawing only), `fade` s its fade in and out.
const SANDSTORM := {
	"first": 300.0,  # Owner-approved proposal: every 5:00
	"every": 300.0,  # Owner-approved proposal: every 5:00
	"duration": 40.0,  # Owner-approved proposal: 40 s
	"warn": 10.0,  # Owner-approved proposal: shown 10 s ahead on the HUD
	"reach_mult": 0.5,  # Owner-approved proposal: half range for both armies
	"hide_radius": 300.0,  # Owner-approved proposal: hidden beyond 300 px
	"hide_soft": 120.0,  # TUNING (not in GDD) drawing only: px over which the veil thickens past hide_radius
	"veil_alpha": 0.9,  # TUNING (not in GDD) drawing only: the veil's opacity far out
	"tint_alpha": 0.22,  # TUNING (not in GDD) drawing only: the sand wash over the whole view
	"fade": 1.5,  # TUNING (not in GDD) s, drawing only
	"warn_banner": "A SANDSTORM RISES ON THE HORIZON",  # TUNING (not in GDD)
	"rise_banner": "SANDSTORM: every bow and spell reaches half as far",  # TUNING (not in GDD)
}

# --- Heka (Heka; CombatResolver.curse_unit()) ---------------------------------------------
## Heka, words of power: a priest writes a glyph on a summon (owner-approved
## proposal: "the summon deals less damage and moves slower (-20% each).
## Every 2 s the glyph jumps to an adjacent summon ... A curse lasts at most
## 10 s"). `mult` is x the cursed summon's damage and move speed; it jumps
## every jump_every s to the nearest other summon within jump_range px (none
## there: it stays); it fades after max_time s from its writing; at most
## max_glyphs glyphs at once (a priest's cast over it is refused and
## counted). Cleansed by a Mender's heal or a Profane Bishop's aura, a
## Warder's ward (its barrier), or the priest's death.
const HEKA := {
	"mult": 0.8,  # Owner-approved proposal: -20% damage and speed
	"jump_every": 2.0,  # Owner-approved proposal: every 2 s
	"max_time": 10.0,  # Owner-approved proposal: at most 10 s
	"jump_range": 110.0,  # TUNING (not in GDD) px: "an adjacent summon" (the Bone Ring's neighbours)
	"max_glyphs": 8,  # TUNING (not in GDD)
	"heal_priority": 0.12,  # TUNING (not in GDD) heal score a cursed summon adds for a Mender (priests seek the glyphs out, but not before the badly hurt; first pass 0.45 cleansed in under a second, so the glyph never ran)
	"sigil_rise": 12.0,  # TUNING (not in GDD) drawing only: px above the head
	"sigil_size": 9.0,  # TUNING (not in GDD) drawing only: px half-size of the sigil
}

# --- The Reckoning: the Devourer's Hour (DevourersHour) -----------------------------------
## The Devourer's Hour (owner-approved proposal: "at 0:00 every sarcophagus in
## the necropolis opens: Rebirth has no limit, the Sandstorm becomes
## permanent, and a huge shadow, the Devourer, sweeps telegraphed lanes across
## the map, eating every corpse and unit in them"). From 0:00, every
## lane_every s (shorter by lane_step each minute, down to lane_every_min) a
## lane lane_width px wide and lane_length px long crosses the view through a
## point up to lane_offset px from a standing necromancer (the seeded gameplay
## RNG); it shows for lane_warn s, then the Devourer's shadow runs along it in
## lane_sweep s: every summon in it takes summon_damage and the necromancer
## lane_damage (both x the time scaling), once per lane, and every cartouche
## in it is eaten (its body never returns). At most max_lanes at once.
const DEVOURER := {
	"lane_first": 4.0,  # TUNING (not in GDD) s after 0:00
	"lane_every": 7.0,  # TUNING (not in GDD) s
	"lane_step": 1.0,  # TUNING (not in GDD) s shorter each minute
	"lane_every_min": 2.5,  # TUNING (not in GDD) s
	"lane_width": 96.0,  # TUNING (not in GDD) px
	"lane_length": 1800.0,  # TUNING (not in GDD) px (crosses the view)
	"lane_offset": 120.0,  # TUNING (not in GDD) px
	"lane_warn": 1.6,  # TUNING (not in GDD) s
	"lane_sweep": 1.4,  # TUNING (not in GDD) s (first pass 0.9: the shadow crossed the screen too fast to read)
	"lane_damage": 30.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"summon_damage": 70.0,  # TUNING (not in GDD) to each summon, before the time scaling
	"max_lanes": 3,  # TUNING (not in GDD)
}
## Damage tag of the Devourer's lanes (stats, the death line).
const DEVOURER_SOURCE: String = "devourer"

# --- Fire (the mummies' weakness) ----------------------------------------------------------
## The FIRE damage sources (owner-approved proposal: "Mummy ... fire (Rot
## burn, Mages) does x1.5"): a row's "fire_taken" multiplies hits tagged with
## one of these (DynastyKit.taken_mult()). The mages' blasts, the Lich's, the
## Hellhounds' burns and trails, Brimstone, the plague's rotting fog.
const FIRE_SOURCES: Array[String] = ["mage", "lich", "hellhound_burn", "hellhound_trail", "brimstone", "plague_cloud",
	"pestilence"]  # TUNING (not in GDD)

# --- Counter-passive hooks (not built in phase 1) ------------------------------------------
## Passive id of EMBALMED BONES (proposal: "summons shed a curse glyph faster
## and take less damage while cursed"; DynastyRules.embalmed_*()).
const EMBALMED_BONES: String = "embalmed_bones"
## Its value key: share (0..1) of a glyph's time a summon sheds.
const EMBALMED_SHED_KEY: String = "glyph_shed"
## Its value key: share (0..1) less damage a cursed summon takes.
const EMBALMED_TAKEN_KEY: String = "cursed_damage_cut"
## Passive id of DUNE WALKERS (proposal: "quicksand slows summons by half as
## much and Sandstorm range loss is smaller for the army"; DynastyRules.dune_*()).
const DUNE_WALKERS: String = "dune_walkers"
## Its value key: share (0..1) of the quicksand slow a summon shrugs off.
const DUNE_SLOW_KEY: String = "sand_slow_cut"
## Its value key: share (0..1) of the Sandstorm's reach loss the army keeps.
const DUNE_REACH_KEY: String = "storm_reach_kept"

# --- HUD ---------------------------------------------------------------------------------
## Colour of the HUD's Sandstorm line (the dull bronze-gold: a warning, not a reward).
const STORM_HUD_COLOR := Color(0.824, 0.733, 0.384)  # TUNING (not in GDD) DYN_BRONZE_LIGHT
## Layout px between the HUD's top-centre block and the Sandstorm line.
const STORM_HUD_GAP: float = 4.0  # TUNING (not in GDD)

# --- Sounds --------------------------------------------------------------------------------
## Dynasty event -> sound id: the Dynasty pack (SoundData.DYNASTY_SOUNDS,
## rendered lazily with the "weighing" music; wired at the wave 1 integration)
## where it has one, else a startup-bank sound (the comment names the intended
## pack id still to come).
const SOUNDS := {
	"cartouche": "cartouche_chime",  # Dynasty pack: a soft dry chime as the Name appears.
	"rebirth": "rebirth_groan",  # Dynasty pack: a dry rasp of linen as the body stands again.
	"name_stolen": "summon_rise",  # Intended "name_stolen" (a teal whoosh: the Name is yours).
	"smash": "enemy_hit",  # Intended "cartouche_smash" (a clay crack).
	"jar_rise": "boss_telegraph",  # Intended "jar_rise" (sand pouring off stone).
	"jar_break": "jar_shatter",  # Dynasty pack: a heavy pot shatters, a sigh of breath.
	"heka_write": "heka_glyph",  # Dynasty pack: a whispered syllable and a chime.
	"heka_cleanse": "orb_block",  # Intended "heka_cleanse" (a bright unravelling).
	"storm_warn": "boss_telegraph",  # Intended "storm_warn" (a far rising wind).
	"storm_rise": "sandstorm",  # Dynasty pack: a roaring, hissing wind.
	"devourer_lane": "boss_telegraph",  # Intended "devourer_growl" (a low growl from below).
	"devourer_eat": "boss_impact",  # Intended "devourer_bite" (a huge snap of jaws).
	"khopesh_spin": "warrior_bash",  # Intended "khopesh_spin" (a whirling double blade).
}
