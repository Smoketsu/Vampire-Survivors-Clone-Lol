## SynergyData — immutable design data for the army synergies (GDD §6.3):
##   Shieldwall of the Damned (Warriors + Warders)  warder barriers on the frontline
##   Volley of the Fallen     (Archers + Mages)     mage marks -> archer bonus damage
##   March of the Deathless   (3 different summons) move speed + regeneration
##   The Unholy Host          (all 4 main summons)  attack speed / resilience aura
## and the synergies of the seven newer classes (owner-approved proposal
## "Synergies for the Newer Summons", GDD §15.0), a SETTER / FINISHER pattern:
## a control class marks foes, a damage class cashes the mark in (like Volley):
##   Flesh Rampart         (Abomination + Warriors)         stomps stagger; warriors hit staggered foes harder
##   Killing Field         (Abomination + Corpse Catapult)  boulders hit staggered foes harder, aimed at them
##   Death from Above      (Gargoyle + Rogues)              rogues hit swooped foes harder; dash reset
##   The Wild Hunt         (Gargoyle + Bone Hounds)         a swooped foe becomes the pack's prey, bitten harder
##   Cold Blood            (Frost Wraith + Rogues)          rogues hit chilled / frozen foes harder, dash at them
##   Shatterfall           (Frost Wraith + Corpse Catapult) boulders hit frozen (or chilled) foes harder
##   Requiem               (Banshee + Mages)                mage explosions hit weakened foes harder, stretch the Dirge
##   Baying of the Damned  (Banshee + Bone Hounds)          every Dirge sends the pack into a short frenzy
##   The Charnel Menagerie (any 4 of the 7 newer classes)   the newer classes deal more damage, replenish faster
## and content wave 2's pair (owner-approved proposal 5; the Bone Golem also
## joins NEWER_CLASSES, so it counts toward the Menagerie):
##   Bone Bastion          (Bone Golem + Warrior or Abom.)  an aura: summons near a Golem take less damage (no mark)
## and the synergies of the seventeen later classes (owner-approved proposal
## "Synergies for the Later Classes", GDD §15.0 "Synergies for the later
## classes (owner decisions, Nov 2026)"), the same setter / finisher pattern:
##   Pinned Down           (Iron Revenant + Archers)          shells pin foes; arrows hit pinned foes harder
##   Anchor and Stone      (Spawn of the Deep + Catapult)     boulders aim at held (stunned) foes and hit them harder
##   Broken Guard          (Bound Oni + Warriors)             warriors hit held (stunned) foes harder
##   Searchlight           (Gargoyle + Ghost Saucer)          saucer beams hit swooped foes harder
##   Carrion Swarm         (Abomination + Grave Drone)        drone darts hit staggered foes harder
##   Fallen Choir          (Banshee + Fallen Seraph)          seraph blades, dives and feathers hit weakened foes harder
##   Black Ice             (Frost Wraith + Powder Wraith)     keg bursts hit frozen (or chilled) foes harder
##   Blood in the Water    (Rogue + Blood Spawn)              rogue bleeds mark foes; blood spawn hit bleeding foes harder
##   Aegis of Tartarus     (Warder + Myrmidon Shade)          warder barriers on shield-locked Myrmidons (no mark)
##   Winter's Edge         the Draugr Thane is a second setter of Cold Blood
##                         and Shatterfall (its chill is the Frost Wraith's)
## and two capstones that split the seventeen (owner: "maybe more than one";
## the later classes never join the Charnel Menagerie):
##   The Unhallowed Legion (any 4 of the 12 LEGION_CLASSES, the front line)  more damage, shorter special cooldowns
##   The Rain of Ruin      (any 3 of the 5 RUIN_CLASSES, the ranged ones)    more damage, faster attacks
## "Held" is every stun (Enemy.stun_timer > 0) from any source; evolved-only
## setters count (the Black Paragon slam, the Fossil Tyrant roar stun, the
## Prince of Hell's weakening).
## Evolved forms keep their class id, so they count (and finish) as their
## class (Bone Colossus, Cathedral Horror, Winter Revenant, Keening Lady,
## Shadow Reaper, Hellhound, Ossuary Engine; Death Knight, Lich).
##
## Priest split (user request, GDD §15.0): the GDD's Priest is now two
## classes. Shieldwall needs the Crypt Warder (the barrier caster). The Unholy
## Host's "4 main summons" are Warriors, Archers, Mages and EITHER priest
## order (a nested array in `requires` means "any one of these"). A class
## whose UnitData row lists `counts_as` (the Profane Bishop) satisfies those
## classes, so merging Menders + Warders keeps both synergies.
##
## Activation rule (GDD open question 29 is unresolved; prototype decision,
## recorded in GDD §15.0): a synergy is active automatically while every
## required summon class is owned at skill level MIN_CLASS_LEVEL or higher
## ("distinct" synergies count classes at that level, only among
## `distinct_of` when it is given: the Charnel Menagerie counts
## NEWER_CLASSES). Units do not need to be alive. Synergies are re-evaluated
## whenever a summon level changes; SynergyManager applies them and the HUD
## lists the active ones.
## Mark-bonus rules (owner decisions): ONE mark bonus per hit, the highest
## applicable one wins (Cold Blood and Death from Above never stack on a
## Rogue hit, Killing Field and Shatterfall never on a boulder); the stage
## boss takes BOSS_MARK_MULT of it (minibosses and elites the full bonus).
## The Charnel Menagerie's damage bonus is not a mark bonus: it multiplies as
## its own category. Marks (staggered, swooped) are never put on structures
## or Reckoning enemies.
## All magnitudes are TUNING (not in GDD).
class_name SynergyData
extends RefCounted

## Summon skill level a class needs to count toward a synergy.
const MIN_CLASS_LEVEL: int = 2  # TUNING (not in GDD) decision for open question 29
## Seconds the activation banner stays on screen.
const BANNER_TIME: float = 3.5  # TUNING (not in GDD)

## Display / HUD order: the four original synergies, the eight pairs of the
## newer classes, then the capstone; Bone Bastion; the later classes' pairs
## and their two capstones.
const ORDER := ["shieldwall", "volley", "deathless", "unholy_host",
		"flesh_rampart", "killing_field", "death_from_above", "wild_hunt",
		"cold_blood", "shatterfall", "requiem", "baying", "charnel_menagerie",
		# --- Content wave 2: Bone Golem ---
		"bone_bastion",
		# --- Synergies for the later classes (Nov 2026) ---
		"pinned_down", "anchor_and_stone", "broken_guard", "searchlight",
		"carrion_swarm", "fallen_choir", "black_ice", "blood_in_the_water",
		"aegis_of_tartarus", "unhallowed_legion", "rain_of_ruin"]

## The seven newer summon classes (UnitData ids): the classes the Charnel
## Menagerie counts and whose damage and replenishment it raises.
const NEWER_CLASSES := ["abomination", "rogue", "gargoyle", "frost_wraith",
		"bone_hound", "banshee", "corpse_catapult",
		# --- Content wave 2: Bone Golem --- (owner-approved: it counts toward the Menagerie)
		"bone_golem"]
## The seventeen later summon classes (UnitData ids; owner list, Nov 2026):
## every one is in a pair or a capstone. They never count toward the
## Charnel Menagerie (owner decision).
const LATER_CLASSES := ["fallen_seraph", "spawn_of_the_deep", "grave_drone", "iron_revenant",
		"myrmidon_shade", "bound_oni", "bound_succubus", "archfiend", "blood_spawn",
		"fallen_hero", "ghost_saucer", "powder_wraith", "draugr_thane", "ushabti_sentinel",
		"bound_ophan", "bonehorn", "ossuary_oak"]
## The twelve later classes that fight on the Bone Ring's front (formation
## "front"): the classes The Unhallowed Legion counts and raises.
const LEGION_CLASSES := ["spawn_of_the_deep", "myrmidon_shade", "bound_oni", "archfiend",
		"blood_spawn", "fallen_hero", "powder_wraith", "draugr_thane", "ushabti_sentinel",
		"bound_ophan", "bonehorn", "ossuary_oak"]
## The five later classes that strike from range (formation "mid" / "back",
## attack range 140 px or more): the classes The Rain of Ruin counts and raises.
const RUIN_CLASSES := ["fallen_seraph", "grave_drone", "iron_revenant", "bound_succubus", "ghost_saucer"]
## Seconds an Iron Revenant (or Deus Revenant) shell leaves a foe "pinned"
## (Pinned Down; Enemy.pinned_until).
const PINNED_DURATION: float = 6.0  # TUNING (not in GDD) proposal 4.0; balance pass (docs/synergies/LATE_PAIRS.md): too few pinned arrows
## Seconds a status mark outlasts its status: a foe stays "held" this long
## after its stun ends (Enemy.held_until) and "bleeding" this long after the
## rogue bleed would end (Enemy.bleeding_until), so a finisher arriving just
## after the setter still cashes it in (like the 4 s stagger).
const MARK_LINGER: float = 3.0  # TUNING (not in GDD) balance pass: 1 s stuns and 3 s bleeds covered too few finisher hits
## Seconds an Abomination (or Bone Colossus) stomp leaves a foe "staggered"
## (Flesh Rampart, Killing Field; Enemy.staggered_until).
const STAGGER_DURATION: float = 4.0  # TUNING (not in GDD) proposal 2.5; pair screens: 2/3 of the 6 s stomp cooldown
## Seconds a Gargoyle (or Cathedral Horror) dive leaves a foe "swooped"
## (Death from Above, The Wild Hunt; Enemy.swooped_until).
const SWOOPED_DURATION: float = 5.0  # TUNING (not in GDD) proposal 3.0; pair screens: 2/3 of the 7 s swoop cooldown
## Share (0..1) of a mark bonus the stage boss takes (owner decision: half;
## minibosses and elites take the full bonus).
const BOSS_MARK_MULT: float = 0.5  # TUNING (not in GDD) owner decision
## Damage-source tag (CombatResolver.damage_enemy `source`) -> the summon
## class it belongs to, for the mark bonuses and the Charnel Menagerie. Only
## the classes these synergies name are listed: a class's basic attack (its
## class id, or its evolution id: evolved forms keep their class), the
## evolved bash / cleave, and the class specials (PassiveData
## MINION_SPECIAL_SOURCES / MINION_DOT_SOURCES, the Winter Revenant shatter
## and nova). Spell and evolution raises with their own tags (lich_risen,
## death_mark_risen, raised_dead) are not class damage and are left out.
const SOURCE_CLASS := {
	"warrior": "warrior", "bash": "warrior", "death_knight": "warrior",
	"death_knight_bash": "warrior", "death_knight_cleave": "warrior",
	"mage": "mage", "lich": "mage",
	"abomination": "abomination", "bone_colossus": "abomination",
	"abom_stomp": "abomination", "colossus_shrapnel": "abomination",
	"rogue": "rogue", "shadow_reaper": "rogue", "rogue_dash": "rogue", "rogue_bleed": "rogue",
	"gargoyle": "gargoyle", "cathedral_horror": "gargoyle", "gargoyle_swoop": "gargoyle",
	"frost_wraith": "frost_wraith", "winter_revenant_shatter": "frost_wraith",
	"winter_revenant_nova": "frost_wraith",
	"bone_hound": "bone_hound", "hellhound": "bone_hound",
	"hellhound_burn": "bone_hound", "hellhound_trail": "bone_hound",
	"banshee": "banshee", "keening_lady": "banshee",
	"corpse_catapult": "corpse_catapult", "ossuary_engine": "corpse_catapult",
	"ossuary_shards": "corpse_catapult",
	# --- Content wave 2: Bone Golem ---
	"bone_golem": "bone_golem", "ossuary_titan": "bone_golem", "golem_slam": "bone_golem", "titan_wall": "bone_golem",
	# --- Synergies for the later classes (Nov 2026): every source of the
	# seventeen later classes (basic attack, evolution id, specials), for
	# their pairs and their capstones ---
	"fallen_seraph": "fallen_seraph", "ruin_seraph": "fallen_seraph",
	"seraph_dive": "fallen_seraph", "seraph_feathers": "fallen_seraph",
	"spawn_of_the_deep": "spawn_of_the_deep", "leviathan": "spawn_of_the_deep",
	"deep_grasp": "spawn_of_the_deep", "leviathan_sweep": "spawn_of_the_deep",
	"grave_drone": "grave_drone", "wraith_drone": "grave_drone",
	"iron_revenant": "iron_revenant", "deus_revenant": "iron_revenant",
	"deus_revenant_missile": "iron_revenant",
	"myrmidon_shade": "myrmidon_shade", "legion_of_tartarus": "myrmidon_shade",
	"myrmidon_pierce": "myrmidon_shade",
	"bound_oni": "bound_oni", "oni_lord": "bound_oni", "oni_kanabo": "bound_oni", "oni_quake": "bound_oni",
	"bound_succubus": "bound_succubus", "lilim_matriarch": "bound_succubus",
	"archfiend": "archfiend", "prince_of_hell": "archfiend", "archfiend_cleave": "archfiend",
	"blood_spawn": "blood_spawn", "nosferatu": "blood_spawn",
	"fallen_hero": "fallen_hero", "black_paragon": "fallen_hero",
	"fallen_hero_slam": "fallen_hero", "black_paragon_slam": "fallen_hero",
	"ghost_saucer": "ghost_saucer", "black_mothership": "ghost_saucer",
	"ghost_saucer_lift": "ghost_saucer", "black_mothership_lift": "ghost_saucer",
	"powder_wraith": "powder_wraith", "magazine_lord": "powder_wraith",
	"powder_wraith_keg": "powder_wraith", "magazine_lord_keg": "powder_wraith",
	"draugr_thane": "draugr_thane", "barrow_king": "draugr_thane",
	"thane_cleave": "draugr_thane", "barrow_king_cleave": "draugr_thane",
	"ushabti_sentinel": "ushabti_sentinel", "eternal_guard": "ushabti_sentinel",
	"ushabti_reform": "ushabti_sentinel", "eternal_guard_reform": "ushabti_sentinel",
	"bound_ophan": "bound_ophan", "throne_of_bones": "bound_ophan",
	"bound_ophan_roll": "bound_ophan", "throne_of_bones_roll": "bound_ophan",
	"bonehorn": "bonehorn", "fossil_tyrant": "bonehorn",
	"bonehorn_charge": "bonehorn", "fossil_tyrant_charge": "bonehorn",
	"ossuary_oak": "ossuary_oak", "world_root_warden": "ossuary_oak",
	"ossuary_oak_lash": "ossuary_oak", "world_root_lash": "ossuary_oak",
}
## Finisher sources read ONLY by the synergy hit path (SynergyManager.hit_mult()),
## kept out of SOURCE_CLASS on purpose: other systems read SOURCE_CLASS (the
## Celestial Host's Grace damage kinds, the Crash Site's egg report), and the
## Archers are a core class the bots draft, so listing them there would change
## the same-seed summaries of every run with Archers. Pinned Down's finisher.
const HIT_ONLY_SOURCES := {"archer": "archer", "gravebow": "archer"}
## The arrow sources (Archers, Gravebow): Pinned Down raises these.
const ARROW_SOURCES := ["archer", "gravebow"]
## The Grave Drone's bone darts (base and Wraith Drone): Carrion Swarm raises these.
const DART_SOURCES := ["grave_drone", "wraith_drone"]
## The Ghost Saucer's beams (base and Black Mothership; not the lift's slam):
## Searchlight raises these.
const BEAM_SOURCES := ["ghost_saucer", "black_mothership"]
## The Powder Wraith's keg bursts (base and Magazine Lord): Black Ice raises these.
const KEG_SOURCES := ["powder_wraith_keg", "magazine_lord_keg"]
## The boulder sources (a Corpse Catapult's and an Ossuary Engine's splash):
## Killing Field and Shatterfall raise these only, not the shard fields.
const BOULDER_SOURCES := ["corpse_catapult", "ossuary_engine"]
## The mage explosion sources (Undead Mage, Lich): Requiem raises these.
const MAGE_SOURCES := ["mage", "lich"]

## Synergy definitions.
##   display_name — UI name (banner).
##   short_name   — compact HUD name.
##   icon         — IconGlyph kind (icons/<kind>.png art, else drawn by
##                  ProgressionGlyphs).
##   description  — one-line effect text (banner subtitle).
##   requires     — summon classes that must each be at MIN_CLASS_LEVEL+; an
##                  entry may be an Array of class ids (any one of them).
##   distinct     — alternatively: number of different classes at
##                  MIN_CLASS_LEVEL+ (0 = use `requires`).
##   distinct_of  — optional: the classes `distinct` counts (absent = every
##                  class; the Charnel Menagerie: NEWER_CLASSES).
##   mark         — optional (the newer pairs): the foe state the finisher
##                  cashes in: "staggered" (Enemy.staggered_until),
##                  "swooped" (Enemy.swooped_until), "chilled" (chilled or
##                  Deep-Frozen), "frozen" (Deep-Frozen takes `bonus`, only
##                  chilled takes `bonus_chilled`), "weakened" (the Dirge,
##                  Enemy.weaken_until), "dirge" (no hit bonus: Baying),
##                  "pinned" (Enemy.pinned_until), "held" (any stun,
##                  Enemy.stun_timer > 0, and MARK_LINGER s after it:
##                  Enemy.held_until) or "bleeding" (Enemy.bleeding_until).
##   aim_bonus    — optional: target-score bonus the finisher's behaviour (or
##                  the catapult aim) gives a marked foe (SynergyManager.aim_bonus()).
##   finisher     — optional: the class (a SOURCE_CLASS value) whose hits
##                  take the mark bonus.
##   sources      — optional: only these damage sources of the finisher take
##                  it (absent = every source of the class).
##   bonus        — optional: the mark bonus (+fraction of the hit, 0..1).
##   (other effect keys, see each entry)
const SYNERGIES := {
	"shieldwall": {
		"display_name": "Shieldwall of the Damned",
		"short_name": "Shieldwall",
		"icon": "syn_shieldwall",
		"description": "Warders raise bone barriers on your frontline warriors.",
		"requires": ["warrior", "warder"],
		"distinct": 0,
		## Barrier HP as a fraction of the warrior's max HP (refreshed, not stacked).
		"barrier_fraction": 0.25,  # TUNING (not in GDD)
		## Seconds between barrier refreshes (needs at least one living Warder or Bishop).
		"barrier_interval": 5.0,  # TUNING (not in GDD)
	},
	"volley": {
		"display_name": "Volley of the Fallen",
		"short_name": "Volley",
		"icon": "syn_volley",
		"description": "Mage explosions mark foes; archers deal bonus damage to marked foes.",
		"requires": ["archer", "mage"],
		"distinct": 0,
		## Seconds a mage mark lasts on an enemy.
		"mark_duration": 4.0,  # TUNING (not in GDD)
		## Extra archer arrow damage against marked enemies (+35%).
		"archer_bonus": 0.35,  # TUNING (not in GDD)
	},
	"deathless": {
		"display_name": "March of the Deathless",
		"short_name": "Deathless",
		"icon": "syn_deathless",
		"description": "Your summons move faster and slowly regenerate.",
		"requires": [],
		"distinct": 3,
		## Summon move-speed bonus (+15%), its own stacking category.
		"move_speed": 0.15,  # TUNING (not in GDD)
		## Fraction of max HP each summon regenerates per second.
		"regen_per_s": 0.015,  # TUNING (not in GDD)
	},
	"unholy_host": {
		"display_name": "The Unholy Host",
		"short_name": "Unholy Host",
		"icon": "syn_unholy_host",
		"description": "An unholy aura: all summons attack faster and take less damage.",
		"requires": ["warrior", "archer", "mage", ["mender", "warder"]],
		"distinct": 0,
		## Summon attack-speed bonus (+15%), its own stacking category.
		"attack_speed": 0.15,  # TUNING (not in GDD)
		## Fraction of damage summons ignore (-15% damage taken).
		"damage_reduction": 0.15,  # TUNING (not in GDD)
	},
	"flesh_rampart": {
		"display_name": "Flesh Rampart",
		"short_name": "Flesh Rampart",
		"icon": "syn_flesh_rampart",
		"description": "Abomination stomps stagger foes; warriors hit staggered foes harder.",
		"requires": ["abomination", "warrior"],
		"distinct": 0,
		"mark": "staggered",
		"finisher": "warrior",
		## Extra warrior / Death Knight damage (strikes, bashes, cleaves) on a staggered foe (+40%).
		"bonus": 0.40,  # TUNING (not in GDD) proposal 0.30; pair screens (low lift)
	},
	"killing_field": {
		"display_name": "Killing Field",
		"short_name": "Killing Field",
		"icon": "syn_killing_field",
		"description": "Catapults aim at the foes an Abomination staggers and hit them harder.",
		"requires": ["abomination", "corpse_catapult"],
		"distinct": 0,
		"mark": "staggered",
		"finisher": "corpse_catapult",
		"sources": BOULDER_SOURCES,
		## Extra boulder damage on a staggered foe (+50%).
		"bonus": 0.50,  # TUNING (not in GDD) proposal 0.35; pair screens (low lift)
		## Catapult target-score bonus for a staggered foe (the shared score is ~1-3; CatapultBehavior).
		"aim_bonus": 1.0,  # TUNING (not in GDD) 0.6 in the first pair screens (too few staggered hits)
	},
	"death_from_above": {
		"display_name": "Death from Above",
		"short_name": "Death Above",
		"icon": "syn_death_from_above",
		"description": "Rogues hit swooped foes harder; the first hit on one resets the dash.",
		"requires": ["gargoyle", "rogue"],
		"distinct": 0,
		"mark": "swooped",
		"finisher": "rogue",
		## Extra rogue damage (strikes, dashes, bleeds) on a swooped foe (+40%).
		"bonus": 0.40,  # TUNING (not in GDD) proposal 0.30; pair screens (low lift)
		## Rogue target-score bonus for a swooped foe (RogueBehavior; like Cold Blood's).
		"prefer_bonus": 0.5,  # TUNING (not in GDD) pair screens: rogues rarely met the swooped foes
		## Dash cooldown left (s) after the first rogue hit on a swooped foe
		## (once per swoop mark; never 0, so resets cannot loop).
		"dash_reset_floor": 0.6,  # TUNING (not in GDD)
	},
	"wild_hunt": {
		"display_name": "The Wild Hunt",
		"short_name": "Wild Hunt",
		"icon": "syn_wild_hunt",
		"description": "A foe a Gargoyle swoops on becomes the pack's prey; bites on it hit harder.",
		"requires": ["gargoyle", "bone_hound"],
		"distinct": 0,
		"mark": "swooped",
		"finisher": "bone_hound",
		## Extra hound damage (bites, Hellhound burns and fire) on a swooped foe (+35%).
		"bonus": 0.35,  # TUNING (not in GDD) proposal 0.25; pair screens (low lift)
		## Hound target-score bonus for a swooped foe within prey_reach (BoneHoundBehavior).
		"prey_bonus": 1.0,  # TUNING (not in GDD)
		## px from the hound within which a swooped foe becomes its prey.
		"prey_reach": 220.0,  # TUNING (not in GDD) owner-approved proposal
	},
	"cold_blood": {
		"display_name": "Cold Blood",
		"short_name": "Cold Blood",
		"icon": "syn_cold_blood",
		"description": "Rogues dash at chilled and frozen foes and hit them harder.",
		# Winter's Edge (owner decision, Nov 2026): the Draugr Thane is a second setter.
		"requires": [["frost_wraith", "draugr_thane"], "rogue"],
		"distinct": 0,
		"mark": "chilled",
		"finisher": "rogue",
		## Extra rogue damage on a chilled or Deep-Frozen foe (+40%).
		"bonus": 0.40,  # TUNING (not in GDD) owner-approved proposal
		## Rogue target-score bonus for a chilled or frozen foe (RogueBehavior).
		"prefer_bonus": 0.5,  # TUNING (not in GDD)
	},
	"shatterfall": {
		"display_name": "Shatterfall",
		"short_name": "Shatterfall",
		"icon": "syn_shatterfall",
		"description": "Catapults aim at frozen foes; boulders hit frozen foes much harder.",
		# Winter's Edge (owner decision, Nov 2026): the Draugr Thane is a second setter.
		"requires": [["frost_wraith", "draugr_thane"], "corpse_catapult"],
		"distinct": 0,
		"mark": "frozen",
		"finisher": "corpse_catapult",
		"sources": BOULDER_SOURCES,
		## Extra boulder damage on a Deep-Frozen foe (+75%).
		"bonus": 0.75,  # TUNING (not in GDD) proposal 0.50; pair screens (low lift)
		## Extra boulder damage on a foe that is only chilled (+40%).
		"bonus_chilled": 0.40,  # TUNING (not in GDD) proposal 0.25; pair screens (low lift)
		## Catapult target-score bonus for a Deep-Frozen foe (CatapultBehavior).
		"aim_bonus": 0.6,  # TUNING (not in GDD)
	},
	"requiem": {
		"display_name": "Requiem",
		"short_name": "Requiem",
		"icon": "syn_requiem",
		"description": "Mage explosions hit weakened foes harder and stretch the Dirge.",
		"requires": ["banshee", "mage"],
		"distinct": 0,
		"mark": "weakened",
		"finisher": "mage",
		"sources": MAGE_SOURCES,
		## Extra mage / Lich explosion damage on a weakened foe (+40%).
		"bonus": 0.40,  # TUNING (not in GDD) proposal 0.30; pair screens (low lift)
		## Seconds each such hit adds to the weakening, never beyond the
		## Dirge's own duration from now (CombatResolver.extend_weaken()).
		"extend_seconds": 1.0,  # TUNING (not in GDD) owner-approved proposal
	},
	"baying": {
		"display_name": "Baying of the Damned",
		"short_name": "Baying",
		"icon": "syn_baying",
		"description": "Every Dirge sends the bone hounds into a frenzy.",
		"requires": ["banshee", "bone_hound"],
		"distinct": 0,
		"mark": "dirge",
		## Class the frenzy speeds up (HordeDirector.compute_stats()).
		"frenzy_class": "bone_hound",
		## Hound attack-speed bonus during the frenzy (+15%), its own category.
		"attack_speed": 0.15,  # TUNING (not in GDD) proposal 0.25; pair screens: several banshees keep the frenzy up (+38% lift)
		## Hound move-speed bonus during the frenzy (+10%), its own category.
		"move_speed": 0.10,  # TUNING (not in GDD) proposal 0.15; trimmed with attack_speed
		## Seconds the frenzy lasts after a Dirge (a new Dirge refreshes it).
		"frenzy_duration": 4.0,  # TUNING (not in GDD) owner-approved proposal
	},
	"charnel_menagerie": {
		"display_name": "The Charnel Menagerie",
		"short_name": "Menagerie",
		"icon": "syn_charnel_menagerie",
		"description": "Four of the newer horrors: they deal more damage and return faster.",
		"requires": [],
		"distinct": 4,
		"distinct_of": NEWER_CLASSES,
		## Damage bonus of every NEWER_CLASSES source (+10%), its own category.
		"damage": 0.10,  # TUNING (not in GDD) owner-approved proposal
		## Replenishment speed bonus of the newer classes (+20%: interval / 1.2), its own category.
		"replenish_speed": 0.20,  # TUNING (not in GDD) owner-approved proposal
	},
	# --- Content wave 2: Bone Golem ---
	"bone_bastion": {
		# Owner decision (Oct 2026, GDD §15.0 "Bone Bastion"): it replaced Charnel House
		# (a slam mark the Abomination stomps cashed in), which almost never fired because
		# Golems and Abominations hold different Bone Ring posts. No mark: an aura.
		"display_name": "Bone Bastion",  # Owner decision
		"short_name": "Bone Bastion",
		"icon": "syn_bone_bastion",
		"description": "Summons near a Bone Golem take less damage, far less while it is planted.",
		## The Golem and any blocker class (a Warrior or an Abomination, evolved forms too).
		"requires": ["bone_golem", ["warrior", "abomination"]],  # Owner decision
		"distinct": 0,
		## Reach of a Golem's bastion, centre to centre (px): Bulwark's taunt reach.
		"radius": 120.0,  # TUNING (not in GDD) owner-approved proposal
		## Damage-taken cut (0..1) for the other summons inside a Golem's reach.
		"reduction": 0.15,  # TUNING (not in GDD) owner-approved proposal
		## The cut while that Golem is planted (Bulwark).
		"planted_reduction": 0.30,  # TUNING (not in GDD) owner-approved proposal
		## Most (0..1) Grave Masonry and the bastion may cut one hit together.
		"max_combined": 0.60,  # TUNING (not in GDD) owner-approved proposal
	},
	# --- Synergies for the later classes (owner decisions, Nov 2026) ---
	"pinned_down": {
		"display_name": "Pinned Down",
		"short_name": "Pinned Down",
		"icon": "syn_pinned_down",
		"description": "Iron Revenant shells pin foes; arrows hit pinned foes harder.",
		"requires": ["iron_revenant", "archer"],
		"distinct": 0,
		"mark": "pinned",
		"finisher": "archer",
		"sources": ARROW_SOURCES,
		## Extra arrow damage (Archers, Gravebow, their volleys) on a pinned foe (+40%).
		"bonus": 0.40,  # TUNING (not in GDD) owner-approved proposal
	},
	"anchor_and_stone": {
		"display_name": "Anchor and Stone",
		"short_name": "Anchor & Stone",
		"icon": "syn_anchor_and_stone",
		"description": "Catapults aim at held foes and hit them harder.",
		"requires": ["spawn_of_the_deep", "corpse_catapult"],
		"distinct": 0,
		"mark": "held",
		"finisher": "corpse_catapult",
		"sources": BOULDER_SOURCES,
		## Extra boulder damage on a held (stunned) foe (+50%).
		"bonus": 0.50,  # TUNING (not in GDD) owner-approved proposal
		## Catapult target-score bonus for a held foe (like Killing Field's).
		"aim_bonus": 1.0,  # TUNING (not in GDD) owner-approved proposal
	},
	"broken_guard": {
		"display_name": "Broken Guard",
		"short_name": "Broken Guard",
		"icon": "syn_broken_guard",
		"description": "Warriors hit held foes harder.",
		"requires": ["bound_oni", "warrior"],
		"distinct": 0,
		"mark": "held",
		"finisher": "warrior",
		## Extra warrior / Death Knight damage on a held (stunned) foe (+40%).
		"bonus": 0.40,  # TUNING (not in GDD) owner-approved proposal
	},
	"searchlight": {
		"display_name": "Searchlight",
		"short_name": "Searchlight",
		"icon": "syn_searchlight",
		"description": "Ghost Saucer beams hit swooped foes harder.",
		"requires": ["gargoyle", "ghost_saucer"],
		"distinct": 0,
		"mark": "swooped",
		"finisher": "ghost_saucer",
		"sources": BEAM_SOURCES,
		## Extra beam damage on a swooped foe (+40%).
		"bonus": 0.40,  # TUNING (not in GDD) owner-approved proposal
		## Target-score bonus the saucers give a marked foe (SynergyManager.aim_bonus()).
		"aim_bonus": 1.0,  # TUNING (not in GDD) balance pass: like Killing Field's aim (finishers rarely met the marked foes)
	},
	"carrion_swarm": {
		"display_name": "Carrion Swarm",
		"short_name": "Carrion Swarm",
		"icon": "syn_carrion_swarm",
		"description": "Grave Drone darts hit staggered foes harder.",
		"requires": ["abomination", "grave_drone"],
		"distinct": 0,
		"mark": "staggered",
		"finisher": "grave_drone",
		"sources": DART_SOURCES,
		## Extra dart damage on a staggered foe (+35%).
		"bonus": 0.35,  # TUNING (not in GDD) owner-approved proposal
		## Target-score bonus the drones give a marked foe (SynergyManager.aim_bonus()).
		"aim_bonus": 1.0,  # TUNING (not in GDD) balance pass: like Killing Field's aim (finishers rarely met the marked foes)
	},
	"fallen_choir": {
		"display_name": "Fallen Choir",
		"short_name": "Fallen Choir",
		"icon": "syn_fallen_choir",
		"description": "Fallen Seraphs hit weakened foes harder.",
		"requires": ["banshee", "fallen_seraph"],
		"distinct": 0,
		"mark": "weakened",
		"finisher": "fallen_seraph",
		## Extra seraph damage (blades, dives, feather rings) on a weakened foe (+40%).
		"bonus": 0.40,  # TUNING (not in GDD) owner-approved proposal
		## Target-score bonus the seraphs give a marked foe (SynergyManager.aim_bonus()).
		"aim_bonus": 1.0,  # TUNING (not in GDD) balance pass: like Killing Field's aim (finishers rarely met the marked foes)
	},
	"black_ice": {
		"display_name": "Black Ice",
		"short_name": "Black Ice",
		"icon": "syn_black_ice",
		"description": "Powder kegs burst much harder on frozen and chilled foes.",
		"requires": ["frost_wraith", "powder_wraith"],
		"distinct": 0,
		"mark": "frozen",
		"finisher": "powder_wraith",
		"sources": KEG_SOURCES,
		## Extra keg damage on a Deep-Frozen foe (+60%).
		"bonus": 0.60,  # TUNING (not in GDD) owner-approved proposal
		## Extra keg damage on a foe that is only chilled (+30%).
		"bonus_chilled": 0.30,  # TUNING (not in GDD) owner-approved proposal
		## Target-score bonus the powder wraiths give a marked foe (SynergyManager.aim_bonus()).
		"aim_bonus": 1.0,  # TUNING (not in GDD) balance pass: like Killing Field's aim (finishers rarely met the marked foes)
	},
	"blood_in_the_water": {
		"display_name": "Blood in the Water",
		"short_name": "Blood in Water",
		"icon": "syn_blood_in_the_water",
		"description": "Rogue bleeds draw the Blood Spawn; they hit bleeding foes harder.",
		"requires": ["rogue", "blood_spawn"],
		"distinct": 0,
		"mark": "bleeding",
		"finisher": "blood_spawn",
		## Extra blood spawn / Nosferatu damage on a bleeding foe (+40%).
		"bonus": 0.40,  # TUNING (not in GDD) owner-approved proposal
		## Target-score bonus the blood spawn give a marked foe (SynergyManager.aim_bonus()).
		"aim_bonus": 1.0,  # TUNING (not in GDD) balance pass: like Killing Field's aim (finishers rarely met the marked foes)
	},
	"aegis_of_tartarus": {
		"display_name": "Aegis of Tartarus",
		"short_name": "Aegis",
		"icon": "syn_aegis_of_tartarus",
		"description": "Warders raise bone barriers on shield-locked Myrmidons.",
		"requires": ["warder", "myrmidon_shade"],
		"distinct": 0,
		## Barrier HP as a fraction of the Myrmidon's max HP (refreshed, not stacked; Shieldwall's).
		"barrier_fraction": 0.25,  # TUNING (not in GDD) owner-approved proposal
		## Seconds between barrier refreshes (needs a living Warder or Bishop; Shieldwall's).
		"barrier_interval": 5.0,  # TUNING (not in GDD) owner-approved proposal
		## Most (0..1) of one hit the locked wall's cut and a barrier may stop
		## together on a Myrmidon (CombatResolver.damage_unit(); like Bone Bastion's cap).
		"max_combined": 0.70,  # TUNING (not in GDD)
	},
	"unhallowed_legion": {
		"display_name": "The Unhallowed Legion",
		"short_name": "Legion",
		"icon": "syn_unhallowed_legion",
		"description": "Four of the later front-line horrors: they hit harder and their specials return sooner.",
		"requires": [],
		"distinct": 4,
		"distinct_of": LEGION_CLASSES,
		## Damage bonus of every LEGION_CLASSES source (+10%), its own category.
		"damage": 0.10,  # TUNING (not in GDD) owner-approved proposal
		## Share (0..1) cut from the LEGION_CLASSES' special cooldowns (HordeDirector._special_stats()).
		"special_cooldown_cut": 0.15,  # TUNING (not in GDD) owner-approved proposal
	},
	"rain_of_ruin": {
		"display_name": "The Rain of Ruin",
		"short_name": "Rain of Ruin",
		"icon": "syn_rain_of_ruin",
		"description": "Three of the later ranged horrors: they hit harder and attack faster.",
		"requires": [],
		"distinct": 3,
		"distinct_of": RUIN_CLASSES,
		## Damage bonus of every RUIN_CLASSES source (+10%), its own category.
		"damage": 0.10,  # TUNING (not in GDD) capstone 2, mirrors the Legion
		## Attack-speed bonus of the RUIN_CLASSES (+10%), its own category (HordeDirector.compute_stats()).
		"attack_speed": 0.10,  # TUNING (not in GDD) capstone 2
	},
}
