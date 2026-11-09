## EvolutionData — immutable design data for spell evolutions (GDD §6.1
## "Evolution Recipes", §5.1 evolution behaviour):
##   Shadow Bolt       + Soul Conduit   = Void Barrage
##   Shadow Orb Shield + Warding Ritual = Eclipse Ward
##   Shadow Blast      + Abyssal Focus  = Abyssal Detonation
## plus the four newer necromancer spells (user request "more weapons"; the
## recipes are the prototype's own, recorded in GDD §15.0):
##   Bone Spear        + Shade Stride          = Ossuary Lance
##   Soul Siphon       + Vampiric Rite         = Soul Rapture
##   Corpse Explosion  + Necrotic Expanse      = Grave Eruption (GDD §5.3)
##   Plague Cloud      + Lingering Malediction = Pestilence (with the GDD
##                                               §5.3 Death Nova burst)
## plus the five later spells (owner-approved, GDD §15.0 "Five more
## spells"; no passive pairs with two evolutions):
##   Death Mark        + Grim Ledger           = Doom Brand
##   Bone Wall         + Grave Dominion        = Charnel Bastion
##   Soul Chains       + Spirit Binding        = Chains of the Damned
##   Wither            + Necrotic Vigor        = Necrotic Blight
##   Raise Dead        + Restless Dead         = Legion of Bones
## plus Act II's abyssal spells (owner-approved, GDD §15.0; each with a NEW
## paired passive, unlocked with its spell):
##   Undertow          + Salt of the Deep      = Maelstrom
## plus Act III's unlockable spells (owner-approved Act III proposal; each with a
## NEW paired passive, unlocked with its spell):
##   Death Ray         + Conductive Marrow     = Event Horizon
## plus Act IV's unlockable spells (owner-approved Act IV proposal "Rewards";
## each with a NEW paired passive, unlocked with its spell):
##   Paris's Arrow     + Mortal Heel           = Arrow of Fate
##   Stolen Thunder    + Titan's Blood         = Gigantomachy
##   River Styx        + Ferryman's Toll       = Lethe's Flood
##
## Evolution condition (GDD open question 27; decisions recorded in GDD
## §15.0): the base spell is at its max level (5), the paired passive is at
## its max level too (5; owner rule "every evolution requires its paired
## passive at Lv 5", which the summon evolutions share), and at least
## MIN_ELAPSED seconds of the run have passed (8:00, the Purifier beat; this
## stands in for the GDD's "special elite reward", which is not implemented
## yet, and keeps a spell rush from evolving at 2:00-5:00). While the
## condition holds, the next treasure chest grants the evolution
## (AbilityManager.chest_rewards()); it replaces the base spell in its active
## slot (no extra slot is used) and the passive is kept.
##
## Each evolution has ONE stats row (it does not level further). Keys reuse the
## base spell's keys so the casting code, the card deltas and the passive
## modifiers (Soul Conduit damage, Abyssal Focus cooldowns) work unchanged; new
## keys add the evolved behaviour. All numbers are TUNING (not in GDD).
class_name EvolutionData
extends RefCounted

## Base spell level required before its evolution can be offered.
const BASE_LEVEL_REQUIRED: int = 5  # TUNING (not in GDD) decision for open question 27
## Paired passive level required before the evolution can be offered (5 =
## max level; it was 1, "owned", before the owner's Lv 5 rule).
const PASSIVE_LEVEL_REQUIRED: int = 5  # TUNING (not in GDD) owner rule: every evolution needs its passive at Lv 5
## Elapsed game seconds before any evolution can be offered (8:00 elapsed =
## 12:00 left on the countdown, the GDD §11 Purifier beat). Balance pass: a
## spell rush evolved Shadow Bolt at 1:48-5:35 before this gate existed.
const MIN_ELAPSED: float = 480.0  # TUNING (not in GDD) decision for open question 27

## Display / card order of evolutions.
const ORDER := ["void_barrage", "eclipse_ward", "abyssal_detonation",
	"ossuary_lance", "soul_rapture", "grave_eruption", "pestilence",
	"doom_brand", "charnel_bastion", "chains_of_the_damned", "necrotic_blight", "legion_of_bones",
	# --- Act II: Gullhaven Harbour ---
	"maelstrom",
	# --- Act II: the Hollow Archive ---
	"unwritten_word",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"tidecallers_host",
	# --- Act III: the Assembly Halls ---
	"puppet_king",
	# --- Act III: the Scrap Wastes ---
	"event_horizon",
	# --- Act III: the Iron Citadel ---
	"deathless_swarm",
	# --- Act IV: the Shores of Ilion ---
	"arrow_of_fate",
	# --- Act IV: Mount Olympus ---
	"gigantomachy",
	# --- Act IV: the Asphodel Underworld ---
	"lethes_flood",
	# --- Act V: the Burning Province ---
	"thousand_shadows",
	# --- Act V: the Road to the Sun ---
	"eclipse_of_heaven",
	# --- Act V: Castle Kurogane ---
	"hundred_banners",
	# --- Act VI: the Burning Gate ---
	"rain_of_fire",
	# --- Act VI: the Palace of Silk and Ash ---
	"unholy_desire",
	# --- Act VI: Pandemonium ---
	"lightbringer",
	# --- Act VII: Ravensmoor ---
	"wolf_of_the_red_moon",
	# --- Act VII: the Witchwood ---
	"witches_sabbath",
	# --- Act VII: Castle Sanguis ---
	"nocturne",
	# --- Act VIII: Skid Row ---
	"funeral_procession",
	# --- Act VIII: Fort Kessler ---
	"killing_ground",
	# --- Act VIII: Liberty Heights ---
	"doomsday",
	# --- Act IX: the Crash Site ---
	"hive_of_bone",
	# --- Act IX: the Proving Moon ---
	"apex_predator",
	# --- Act IX: the Ark ---
	"star_abduction",
	# --- Act X: the Smuggler's Cutter ---
	"keelhauler",
	# --- Act X: the Treasure Galleon ---
	"dead_mens_broadside",
	# --- Act X: the Maelstrom ---
	"abyssal_mooring",
	# --- Act XI (temporary): the Barrow Fields ---
	"barrow_lords_embrace",
	# --- Act XI (temporary): Valgard ---
	"chooser_of_the_slain",
	# --- Act XI (temporary): Vigrid ---
	"spear_of_the_hanged",
	# --- Act XII (temporary number): the Necropolis of Sand ---
	"eternal_shroud",
	# --- Act XII (temporary number): the Temple of the Lioness ---
	"eye_of_retribution",
	# --- Act XII (temporary number): the Hall of Two Truths ---
	"heart_devoured",
	# --- Act XIII (temporary number): the Silver Stair ---
	"sword_at_the_gate"]

## Evolution definitions.
##   base         — spell id that evolves (AbilityData.SPELLS key).
##   passive      — paired passive id (PassiveData.PASSIVES key).
##   display_name — UI name.
##   icon         — IconGlyph kind (drawn by ProgressionGlyphs).
##   description  — card text (GDD §5.1 wording).
##   labels       — stat key -> UI label, in card order. Keys missing from the
##                  base spell are shown as new stats.
##   stats        — absolute stats of the evolved spell.
##
## Void Barrage extra keys:
##   split (shards released on the first enemy a bolt hits), split_damage
##   (fraction of bolt damage per shard), split_speed (px/s), split_life (s).
## Eclipse Ward extra keys:
##   pulse_damage, pulse_radius (px), pulse_interval (s), pulse_knockback
##   (px/s outward impulse, divided by enemy mass).
## Abyssal Detonation extra keys:
##   second_delay (s between the two hits), second_damage (fraction of damage
##   dealt by the second hit), pull (px/s inward impulse toward the blast
##   centre, divided by enemy mass), pull_inner (fraction of the radius inside
##   which enemies are no longer pulled).
## Ossuary Lance extra keys:
##   back_count (lances also thrown behind you), width (px hit radius of a
##   lance), knockback (px/s impulse along the lance, divided by enemy mass).
## Soul Rapture extra keys:
##   burst (death burst damage as a multiple of the drain damage, released
##   when a tethered enemy dies), radius (px burst radius), overflow
##   (fraction of the lifesteal that heals the most wounded nearby summon
##   when you are already at full HP).
## Grave Eruption extra keys:
##   zone_duration (s a bone-spike field lingers), zone_damage (fraction of
##   damage dealt per AbilityData.ZONE_TICK inside a field), zone_slow
##   (fraction of speed removed inside a field), chain (most extra bursts
##   per cast from enemies an eruption kills: they detonate at once).
## Pestilence extra keys:
##   creep (px/s a cloud drifts toward the nearest enemy), nova (Death Nova
##   damage as a multiple of the tick damage, released when a cloud
##   expires, radius x AbilityData.NOVA_RADIUS_MULT), nova_rot_bonus (extra
##   fraction of nova damage against rotting enemies, GDD §5.3 "bonus
##   damage to cursed enemies").
## Doom Brand extra keys:
##   detonation (burst damage as a multiple of the brand tick damage when a
##   branded enemy dies), radius (px burst radius).
## Charnel Bastion keys (no "segments" / "distance": the wall is a ring):
##   radius (px ring radius around the necromancer; segments are placed at
##   most GraveSpellData.BASTION_SPACING apart), pulse_damage (shrapnel
##   damage to each enemy within GraveSpellData.BASTION_SHRAPNEL_RADIUS of a
##   segment when the ring expires).
## Chains of the Damned extra keys:
##   pull (px/s impulse toward the first struck enemy given to every later
##   one, divided by enemy mass).
## Necrotic Blight extra keys:
##   heal (HP healed per enemy inside per pulse), heal_cap (HP/s: the most
##   the aura heals per second).
## The Unwritten Word extra keys (Act II, the Hollow Archive):
##   chain (how many more ink bursts each burst can set off: the first
##   inscribed enemies it kills burst too; VerseData.CHAIN_MAX_DEPTH links).
## Legion of Bones extra keys:
##   damage (bone burst damage to each enemy within `radius` px when a
##   skeleton expires or falls), radius (px).
const EVOLUTIONS := {
	"void_barrage": {
		"base": "shadow_bolt",
		"passive": "soul_conduit",
		"display_name": "Void Barrage",
		"icon": "void_barrage",
		"description": "Rapid piercing void bolts that split into shards on impact.",
		"labels": {"damage": "Damage", "count": "Bolts", "cooldown": "Cooldown (s)", "pierce": "Pierce", "split": "Split shards"},
		"stats": {
			# Balance pass: damage 30 -> 24, cooldown 0.5 -> 0.6, pierce 3 -> 2 and
			# split_damage 0.5 -> 0.4 (about -33% single-target and -55% crowd
			# output); it dealt 70-85% of all damage in a spell build.
			"damage": 24.0, "cooldown": 0.6, "count": 4, "pierce": 2, "speed": 540.0, "range": 460.0,  # TUNING (not in GDD)
			"split": 3, "split_damage": 0.4, "split_speed": 380.0, "split_life": 0.45,  # TUNING (not in GDD)
		},
	},
	"eclipse_ward": {
		"base": "orb_shield",
		"passive": "warding_ritual",
		"display_name": "Eclipse Ward",
		"icon": "eclipse_ward",
		"description": "Six eclipse orbs guard you and pulse with dark damage.",
		"labels": {"orbs": "Orbs", "damage": "Damage", "recharge": "Intercept recharge (s)", "pulse_damage": "Pulse damage", "pulse_interval": "Pulse every (s)"},
		"stats": {
			"orbs": 6, "damage": 24.0, "orbit_radius": 74.0, "orbit_speed": 4.2, "hit_cooldown": 0.4, "recharge": 2.0,  # TUNING (not in GDD)
			"pulse_damage": 34.0, "pulse_radius": 120.0, "pulse_interval": 2.4, "pulse_knockback": 170.0,  # TUNING (not in GDD)
		},
	},
	"abyssal_detonation": {
		"base": "shadow_blast",
		"passive": "abyssal_focus",
		"display_name": "Abyssal Detonation",
		"icon": "abyssal_detonation",
		"description": "A blast drags foes inward, then the abyss detonates again.",
		"labels": {"damage": "Damage", "radius": "Radius", "cooldown": "Cooldown (s)", "slow": "Slow", "second_damage": "Second hit"},
		"stats": {
			"damage": 60.0, "radius": 150.0, "cooldown": 2.6, "slow": 0.6, "slow_duration": 2.0,  # TUNING (not in GDD)
			"second_delay": 0.4, "second_damage": 0.8, "pull": 240.0, "pull_inner": 0.35,  # TUNING (not in GDD)
		},
	},
	"ossuary_lance": {
		"base": "bone_spear",
		"passive": "shade_stride",
		"display_name": "Ossuary Lance",
		"icon": "ossuary_lance",
		"description": "Great bone lances skewer every foe ahead and behind and drive them back.",
		"labels": {"damage": "Damage", "count": "Lances ahead", "back_count": "Lances behind", "cooldown": "Cooldown (s)", "pierce": "Pierce", "knockback": "Knockback"},
		"stats": {
			"damage": 34.0, "cooldown": 0.8, "count": 3, "pierce": 8, "speed": 640.0, "range": 520.0,  # TUNING (not in GDD)
			"back_count": 2, "width": 9.0, "knockback": 150.0,  # TUNING (not in GDD)
		},
	},
	"soul_rapture": {
		"base": "soul_siphon",
		"passive": "vampiric_rite",
		"display_name": "Soul Rapture",
		"icon": "soul_rapture",
		"description": "More tethers feed you; tethered foes burst and spare life mends your undead.",
		"labels": {"damage": "Drain", "targets": "Tethers", "cooldown": "Drain every (s)", "lifesteal": "Lifesteal", "heal_cap": "Heal cap (HP/s)", "burst": "Death burst (x drain)", "radius": "Burst radius"},
		"stats": {
			# First pass (18 dmg, burst x3) dealt about 350 dmg/s; trimmed.
			"damage": 16.0, "cooldown": 0.4, "targets": 5, "range": 250.0, "lifesteal": 0.4, "heal_cap": 3.0,  # TUNING (not in GDD)
			"burst": 2.0, "radius": 70.0, "overflow": 1.0,  # TUNING (not in GDD)
		},
	},
	"grave_eruption": {
		"base": "corpse_explosion",
		"passive": "necrotic_expanse",
		"display_name": "Grave Eruption",
		"icon": "grave_eruption",
		"description": "Corpses erupt into bone-spike fields, and their victims erupt in turn.",
		"labels": {"damage": "Damage", "radius": "Radius", "count": "Corpses per cast", "cooldown": "Cooldown (s)", "zone_duration": "Spike field (s)", "zone_damage": "Spikes per tick", "chain": "Chain bursts"},
		"stats": {
			# First pass (damage 52, 4 corpses, spikes 25%, chain 6) and a second (46, spikes
			# 20%, chain 4) dealt about 480 dmg/s (Void Barrage: about 300); trimmed.
			# Combined balance pass: damage 36 -> 26, cooldown 1.3 -> 1.6, corpses 3 -> 2,
			# chain 3 -> 2. With all four newer spells forced it dealt 145-306k (35-42% of all
			# damage with its spikes), 2-3x Ossuary Lance, Soul Rapture or Pestilence in the same
			# runs; after a first cut (30 damage, 3 corpses) naive runs still got 430-760 dmg/s
			# from it in the packed late game (Void Barrage: about 300).
			"damage": 26.0, "radius": 90.0, "cooldown": 1.6, "count": 2, "range": 320.0,  # TUNING (not in GDD)
			"zone_duration": 3.0, "zone_damage": 0.15, "zone_slow": 0.35, "chain": 2,  # TUNING (not in GDD)
		},
	},
	"pestilence": {
		"base": "plague_cloud",
		"passive": "lingering_malediction",
		"display_name": "Pestilence",
		"icon": "pestilence",
		"description": "Creeping plague clouds deepen the Rot and end in a Death Nova.",
		"labels": {"damage": "Damage per tick", "radius": "Radius", "duration": "Duration (s)", "cooldown": "Cooldown (s)", "rot": "Rot (damage taken)", "creep": "Creep speed", "nova": "Death Nova (x tick)"},
		"stats": {
			# First pass (12 dmg, 8 s every 1.8 s, Rot 30%, nova x4) dealt 118k in its first
			# 4 minutes of a naive run (Void Barrage: about 300 dmg/s); cut to about a third.
			"damage": 6.0, "radius": 95.0, "duration": 7.0, "cooldown": 2.6, "rot": 0.25, "range": 300.0,  # TUNING (not in GDD)
			"creep": 35.0, "nova": 3.0, "nova_rot_bonus": 1.0,  # TUNING (not in GDD)
		},
	},
	"doom_brand": {
		"base": "death_mark",
		"passive": "grim_ledger",
		"display_name": "Doom Brand",
		"icon": "doom_brand",
		"description": "Branded foes explode in doom when they die, then rise as Risen.",
		"labels": {"damage": "Brand damage per tick", "count": "Brands per cast", "cooldown": "Cooldown (s)", "risen_cap": "Risen at once", "detonation": "Detonation (x tick)", "radius": "Detonation radius"},
		"stats": {
			"damage": 9.0, "duration": 6.0, "cooldown": 1.6, "count": 3, "range": 400.0, "risen_cap": 5,  # TUNING (not in GDD)
			"detonation": 4.0, "radius": 60.0,  # TUNING (not in GDD)
		},
	},
	"charnel_bastion": {
		"base": "bone_wall",
		"passive": "grave_dominion",
		"display_name": "Charnel Bastion",
		"icon": "charnel_bastion",
		"description": "A ring of bone walls encloses you, then bursts into shrapnel.",
		"labels": {"damage": "Spike damage per tick", "duration": "Wall duration (s)", "cooldown": "Cooldown (s)", "radius": "Ring radius", "pulse_damage": "Shrapnel damage"},
		"stats": {
			"damage": 10.0, "cooldown": 6.0, "duration": 4.5,  # TUNING (not in GDD)
			"radius": 95.0, "pulse_damage": 30.0,  # TUNING (not in GDD)
		},
	},
	"chains_of_the_damned": {
		"base": "soul_chains",
		"passive": "spirit_binding",
		"display_name": "Chains of the Damned",
		"icon": "chains_of_the_damned",
		"description": "Soul lightning leaps farther and drags every foe it strikes toward the first.",
		"labels": {"damage": "Damage", "jumps": "Jumps", "falloff": "Falloff per jump", "cooldown": "Cooldown (s)", "slow": "Slow", "pull": "Pull"},
		"stats": {
			"damage": 38.0, "cooldown": 1.1, "jumps": 8, "falloff": 0.12, "jump_range": 140.0, "range": 380.0, "slow": 0.45, "slow_duration": 1.0,  # TUNING (not in GDD)
			"pull": 150.0,  # TUNING (not in GDD)
		},
	},
	"necrotic_blight": {
		"base": "wither",
		"passive": "necrotic_vigor",
		"display_name": "Necrotic Blight",
		"icon": "necrotic_blight",
		"description": "A wide blight withers the foes around you and feeds you their life.",
		"labels": {"damage": "Damage per pulse", "radius": "Radius", "cooldown": "Pulse every (s)", "shred": "Armour removed", "heal": "Heal per foe", "heal_cap": "Heal cap (HP/s)"},
		"stats": {
			"damage": 13.0, "radius": 130.0, "cooldown": 0.7, "shred": 0.6,  # TUNING (not in GDD)
			"heal": 0.6, "heal_cap": 3.0,  # TUNING (not in GDD)
		},
	},
	"legion_of_bones": {
		"base": "raise_dead",
		"passive": "restless_dead",
		"display_name": "Legion of Bones",
		"icon": "legion_of_bones",
		"description": "A legion of skeletons rises, each bursting into bone shards when it falls.",
		"labels": {"count": "Skeletons", "cooldown": "Cooldown (s)", "life": "Skeleton life (s)", "skeleton_damage": "Skeleton damage", "damage": "Bone burst", "radius": "Burst radius"},
		"stats": {
			"count": 6, "cooldown": 7.0, "life": 10.0, "skeleton_hp": 0.8, "skeleton_damage": 1.1, "range": 320.0,  # TUNING (not in GDD)
			"damage": 32.0, "radius": 60.0,  # TUNING (not in GDD)
		},
	},
	# --- Act II: Gullhaven Harbour ---
	# Maelstrom extra keys (Undertow): whirl_damage (per grind tick to each enemy
	# at the whirlpool's heart), whirl_tick (s), whirl_life (s a whirlpool
	# lasts), whirl_radius (px grind radius; it drags from
	# UndertowData.WHIRL_DRAG_RADIUS_MULT x this), whirl_pull (px/s drag speed).
	"maelstrom": {
		"base": "undertow",
		"passive": "salt_of_the_deep",
		"display_name": "Maelstrom",
		"icon": "maelstrom",
		"description": "Every wave ends in a whirlpool that drags foes into one knot and grinds them.",
		"labels": {"damage": "Damage", "range": "Reach", "cooldown": "Cooldown (s)", "whirl_damage": "Whirlpool damage per tick", "whirl_life": "Whirlpool duration (s)", "whirl_pull": "Whirlpool drag"},
		"stats": {
			"damage": 36.0, "cooldown": 1.9, "range": 200.0, "push": 300.0, "slow": 0.45, "slow_duration": 3.0,  # TUNING (not in GDD)
			"whirl_damage": 7.0, "whirl_tick": 0.25, "whirl_life": 2.5, "whirl_radius": 60.0, "whirl_pull": 240.0,  # TUNING (not in GDD)
		},
	},
	# --- Act II: the Hollow Archive ---
	"unwritten_word": {
		"base": "forbidden_verse",
		"passive": "marginalia",
		"display_name": "The Unwritten Word",
		"icon": "unwritten_word",
		"description": "Six pages circle you, and every ink burst can set off another.",
		"labels": {"damage": "Cut damage", "pages": "Pages", "inscribe": "Inscription (s)", "burst": "Ink burst", "radius": "Burst radius", "chain": "Bursts each burst sets off"},
		"stats": {
			"pages": 6, "damage": 20.0, "orbit_radius": 84.0, "orbit_speed": 3.0, "hit_cooldown": 0.4, "inscribe": 7.0,  # TUNING (not in GDD) owner-approved "six pages"
			"burst": 1.5, "radius": 56.0, "cooldown": 3.5, "chain": 1,  # TUNING (not in GDD) owner-approved "each ink burst can set off one more"
		},
	},
	# --- Act II: Ul-Thalos, the Risen Spire ---
	# Tidecaller's Host (GDD §15.0 "Ul-Thalos, the Risen Spire"): Call of the
	# Drowned + Abyssal Pact (a NEW passive, owner rule: at Lv 5). The
	# drowned rise as Spawns of the Deep (the Spawn of the Deep summon class's
	# kit, CallDrownedData.HOST_CLASS: bigger, and they grab and hold an
	# enemy). Detected by the "host" key.
	"tidecallers_host": {
		"base": "call_of_the_drowned",
		"passive": "abyssal_pact",
		"display_name": "Tidecaller's Host",
		"icon": "tidecallers_host",
		"description": "The drowned rise as Spawns of the Deep that seize your foes and hold them fast.",
		"labels": {"damage": "Tendril damage", "targets": "Tendrils", "cooldown": "Cooldown (s)", "life": "Spawn life (s)", "thrall_damage": "Spawn damage"},
		"stats": {
			"damage": 80.0, "targets": 3, "radius": 50.0, "cooldown": 2.25, "range": 340.0, "life": 14.0, "thrall_hp": 0.9, "thrall_damage": 1.0,  # TUNING (not in GDD)
			"host": 1,  # The evolution flag: the drowned rise as Spawns of the Deep.
		},
	},
	# --- Act III: the Assembly Halls ---
	# Puppet King (GDD §15.0 "The Assembly Halls (Act III phase 2)"; owner-
	# approved proposal: "two puppets, and a puppet that dies explodes"): Hollow
	# Puppet + Strings of the Dead (a NEW passive, owner rule: at Lv 5). A
	# puppet that dies (its life ran out or it was killed) bursts: `burst` x its
	# damage to every foe within `burst_radius` px (source "puppet_burst", an
	# on-death effect for Marginalia). Detected by the "king" key.
	"puppet_king": {
		"base": "hollow_puppet",
		"passive": "strings_of_the_dead",
		"display_name": "Puppet King",
		"icon": "puppet_king",
		"description": "Two puppets dance on your strings, and each one bursts when it dies.",
		"labels": {"damage": "Puppet damage", "puppets": "Puppets", "puppet_life": "Puppet life (s)", "burst": "Death burst (x damage)", "cooldown": "Cooldown (s)"},
		"stats": {
			"damage": 42.0, "puppets": 2, "puppet_life": 8.0, "puppet_hp": 1.0, "cooldown": 7.0, "range": 340.0,  # Owner-approved proposal "two puppets"; numbers TUNING (not in GDD)
			"burst": 2.5, "burst_radius": 72.0,  # TUNING (not in GDD) owner-approved "a puppet that dies explodes"
			"king": 1,  # The evolution flag: puppets burst when they die.
		},
	},
	# --- Act III: the Scrap Wastes ---
	# Event Horizon (owner-approved Act III proposal): Death Ray + Conductive
	# Marrow (a NEW passive, owner rule: at Lv 5). "Two beams sweeping opposite
	# each other; each kill sets off wild chain lightning through up to 4
	# enemies." Detected by the "chain" key: a beam kill's lightning arcs from
	# foe to foe through up to `chain` enemies (each within spark_range px of
	# the last), losing `chain_falloff` of its damage per jump.
	"event_horizon": {
		"base": "death_ray",
		"passive": "conductive_marrow",
		"display_name": "Event Horizon",
		"icon": "event_horizon",
		"description": "Two soul lasers sweep opposite each other; every kill sets off wild chain lightning.",
		"labels": {"damage": "Beam damage", "beams": "Beams", "beam_length": "Beam length", "cooldown": "Sweep every (s)", "chain": "Chain lightning jumps", "spark": "Lightning damage"},
		"stats": {
			"damage": 30.0, "cooldown": 5.8, "sweep_time": 1.3, "beam_length": 330.0, "beam_width": 16.0, "spark": 0.3, "spark_range": 150.0,  # TUNING (not in GDD) Act III balance: cooldown 3.0 -> 5.8 s and beam 440 -> 330 px (the base spell's slower, shorter sweep); first pass 64 dmg / 2.6 s / spark 0.6 / falloff 0.15: cut with the base spell; pass 2: 48 dmg / spark 0.4 -> 30 / 0.3 (each enemy meets both beams every sweep)
			"beams": 2,  # Owner-approved proposal: "two beams sweeping opposite each other"
			"chain": 4,  # Owner-approved proposal: "chain lightning through up to 4 enemies"
			"chain_falloff": 0.25,  # TUNING (not in GDD) damage lost per jump
		},
	},
	# --- Act III: the Iron Citadel ---
	# Deathless Swarm (GDD §15.0 "Scrap Swarm, Machine Soul and the Rust
	# Prophet"): Scrap Swarm + Machine Soul (a NEW passive, owner rule: at Lv 5).
	# More drones, and every foe their bolts kill launches one more drone for
	# 10 s (owner-approved: "more drones; each kill adds one for 10 s"), at most
	# `kill_drones` extra. Detected by the "kill_drones" key.
	"deathless_swarm": {
		"base": "scrap_swarm",
		"passive": "machine_soul",
		"display_name": "Deathless Swarm",
		"icon": "deathless_swarm",
		"description": "A greater swarm, and every foe it kills sends another drone into the orbit.",
		"labels": {"damage": "Bolt damage", "drones": "Drones", "cooldown": "Fire interval (s)", "range": "Range", "kill_drones": "Kill drones (10 s)"},
		"stats": {
			"drones": 6, "damage": 18.0, "cooldown": 0.8, "range": 260.0, "orbit_speed": 1.3,  # TUNING (not in GDD) first pass 7 x 24 every 0.75 s dealt 256k in a forced army run
			"kill_drones": 4,  # TUNING (not in GDD) the evolution flag: extra drones from kills, at most this many (first pass 6)
		},
	},
	# --- Act IV: the Shores of Ilion ---
	# Arrow of Fate (owner-approved Act IV proposal: "Paris's Arrow ... -> Arrow
	# of Fate (+ Mortal Heel)"): Paris's Arrow + Mortal Heel (a NEW passive,
	# owner rule: at Lv 5). Own decision on its kit: more arrows, and fate cannot
	# be escaped: an arrow that kills its target flies on from the body to the
	# next strongest foe within `fate_range` px it has not struck, up to
	# `fate_jumps` times, each time from behind. Detected by the "fate_jumps" key.
	"arrow_of_fate": {
		"base": "paris_arrow",
		"passive": "mortal_heel",
		"display_name": "Arrow of Fate",
		"icon": "arrow_of_fate",
		"description": "More ghost arrows, and one that kills flies on to the next foe's back.",
		"labels": {"damage": "Arrow damage", "arrows": "Arrows", "fate_jumps": "Fated jumps", "cooldown": "Cooldown (s)", "range": "Range"},
		"stats": {
			"damage": 64.0, "arrows": 4, "cooldown": 1.9, "range": 420.0, "flight": 0.45,  # TUNING (not in GDD)
			"fate_jumps": 3,  # TUNING (not in GDD) the evolution flag: a killing arrow flies on, at most this many times
			"fate_range": 220.0,  # TUNING (not in GDD) px from the body to its next target
		},
	},
	# --- Act IV: Mount Olympus ---
	# Gigantomachy (owner-approved Act IV proposal: Stolen Thunder + Titan's
	# Blood, a NEW passive, owner rule: at Lv 5): the war of the giants. Each
	# strike also hurls `giants` more bolts at the next strongest foes (each
	# chaining the same way), and every hop cracks a thunderclap of `clap_share`
	# of the hop's damage within `clap_radius` px. Detected by the "giants" key.
	"gigantomachy": {
		"base": "stolen_thunder",
		"passive": "titans_blood",
		"display_name": "Gigantomachy",
		"icon": "gigantomachy",
		"description": "Three stolen bolts fall at once, and every leap of the lightning cracks a thunderclap.",
		"labels": {"damage": "Bolt damage", "giants": "Extra bolts", "thunder_chains": "Chain hops", "cooldown": "Bolts every (s)", "clap_share": "Thunderclap damage"},
		"stats": {
			"damage": 150.0, "cooldown": 2.6, "thunder_charge": 0.6, "range": 480.0, "thunder_chains": 5, "chain_range": 190.0, "chain_falloff": 0.1, "armour_bonus": 0.4,  # TUNING (not in GDD)
			"giants": 2,  # TUNING (not in GDD) the evolution flag: extra bolts per strike
			"clap_share": 0.4,  # TUNING (not in GDD) share of the hop's damage
			"clap_radius": 46.0,  # TUNING (not in GDD) px
		},
	},
	# --- Act IV: the Asphodel Underworld ---
	# Lethe's Flood (GDD §15.0 "River Styx, Lethe's Flood, Ferryman's Toll and the
	# Ferrywoman"; owner-approved proposal "River Styx -> Lethe's Flood (+
	# Ferryman's Toll)"): River Styx + Ferryman's Toll (a NEW passive, owner rule:
	# at Lv 5). Two crossing rivers, wider, longer and harder, and the water of
	# forgetting: a foe entering a river is stunned `forget` s (bosses and
	# minibosses a quarter, elites half: RiverStyxData). Detected by the "forget" key.
	"lethes_flood": {
		"base": "river_styx",
		"passive": "ferrymans_toll",
		"display_name": "Lethe's Flood",
		"icon": "lethes_flood",
		"description": "Two crossing rivers of forgetting: foes that wade in forget themselves and stand still.",
		"labels": {"damage": "Drain per tick", "rivers": "Rivers", "length": "River length", "forget": "Forget (s)", "cooldown": "Cooldown (s)"},
		"stats": {
			"rivers": 2, "damage": 16.0, "tick": 0.5, "river_slow": 0.45, "slow_duration": 0.8, "length": 280.0, "radius": 24.0,  # TUNING (not in GDD)
			"duration": 6.5, "cooldown": 4.0, "drain_share": 0.06, "drain_cap": 6.0,  # TUNING (not in GDD)
			"forget": 1.2,  # TUNING (not in GDD) the evolution flag: s a foe entering a river stands stunned (once per river)
		},
	},
	# --- Act V: the Burning Province ---
	# Thousand Shadows (owner-approved Act V proposal: "Hundred Shadows ... ->
	# Thousand Shadows (+ Hidden Hand)"): Hundred Shadows + Hidden Hand (a NEW
	# passive, owner rule: at Lv 5). Own decision on its kit: five clones, each
	# echoing the next `echoes` spell hits, and every clone bursts into a ring of
	# shadow blades when its life ends (`burst_share` x damage to every foe
	# within `burst_radius` px). Detected by the "burst_radius" key.
	"thousand_shadows": {
		"base": "hundred_shadows",
		"passive": "hidden_hand",
		"display_name": "Thousand Shadows",
		"icon": "thousand_shadows",
		"description": "Five shadows echo every spell, then burst into blades when they fade.",
		"labels": {"damage": "Kunai damage", "clones": "Clones", "echoes": "Echoes each", "burst_radius": "Burst radius", "cooldown": "Cooldown (s)"},
		"stats": {
			"damage": 36.0, "clones": 5, "cooldown": 4.2, "life": 5.0, "echo_share": 0.8, "range": 360.0,  # TUNING (not in GDD)
			"echoes": 3,  # TUNING (not in GDD) spell hits each clone echoes
			"burst_radius": 50.0,  # TUNING (not in GDD) the evolution flag: px of a fading clone's burst
			"burst_share": 1.0,  # TUNING (not in GDD) x damage of the burst
		},
	},
	# --- Act V: the Road to the Sun ---
	# Eclipse of Heaven (GDD §15.0 "Black Sun, Eclipse of Heaven, Stolen Dawn and
	# the Shrine Maiden of Night"; owner-approved proposal "Black Sun -> Eclipse
	# of Heaven (+ Stolen Dawn)"): Black Sun + Stolen Dawn (a NEW passive, owner
	# rule: at Lv 5). Two dark suns orbit him, their beams longer and harder, and
	# each beam ends in a CORONA burst (`corona` x the beam's damage to every foe
	# within BlackSunData.CORONA_RADIUS px of its end). Detected by the "corona" key.
	"eclipse_of_heaven": {
		"base": "black_sun",
		"passive": "stolen_dawn",
		"display_name": "Eclipse of Heaven",
		"icon": "eclipse_of_heaven",
		"description": "Two dark suns eclipse the sky: longer beams that end in a burst of black corona.",
		"labels": {"damage": "Beam damage", "suns": "Dark suns", "sun_reach": "Beam reach", "corona": "Corona", "cooldown": "Cooldown (s)"},
		"stats": {
			"suns": 2, "damage": 26.0, "cooldown": 1.2, "sun_reach": 240.0, "sun_width": 22.0, "group_radius": 72.0,  # TUNING (not in GDD)
			"corona": 0.5,  # TUNING (not in GDD) the evolution flag: share of the beam's damage its corona deals
		},
	},
	# --- Act V: Castle Kurogane ---
	# Hundred Banners (owner-approved Act V proposal: "Banner of the Dead ->
	# Hundred Banners (+ Warlord's Seal)"): Banner of the Dead + Warlord's Seal
	# (a NEW passive, owner rule: at Lv 5). Own decision on its kit: each
	# planting raises `banners` banners at once on a ring round the necromancer
	# (BannerData.RING), and every banner beats a war drum every
	# `pulse_interval` s: `pulse_damage` to every foe within `pulse_radius` px.
	# Detected by the "pulse_interval" key.
	"hundred_banners": {
		"base": "banner_of_the_dead",
		"passive": "warlords_seal",
		"display_name": "Hundred Banners",
		"icon": "hundred_banners",
		"description": "A ring of war banners rises round you, and their war drums beat on your foes.",
		"labels": {"haste": "Attack speed near them", "banners": "Banners", "pulse_damage": "War drum", "duration": "Duration (s)", "cooldown": "Cooldown (s)"},
		"stats": {
			"damage": 56.0, "pulse_radius": 84.0, "haste": 0.45, "radius": 130.0, "banners": 4, "duration": 10.0, "cooldown": 7.0,  # TUNING (not in GDD)
			"pulse_damage": 16.0,  # TUNING (not in GDD) each war drum's beat
			"pulse_interval": 2.0,  # TUNING (not in GDD) the evolution flag: s between two beats of each banner's drum
		},
	},
	# --- Act VI: the Burning Gate ---
	# Rain of Fire (owner-approved Act VI proposal: "Brimstone ... -> Rain of
	# Fire (+ Furnace Heart)"): Brimstone + Furnace Heart (a NEW passive, owner
	# rule: at Lv 5). Own decision on its kit: a true rain: `stones` stones fall
	# one after another `rain_gap` s apart over the densest groups (the stones
	# beyond the groups scatter `rain_spread` px around the densest), harder and
	# wider, and their pits burn longer. Detected by the "rain_gap" key.
	"rain_of_fire": {
		"base": "brimstone",
		"passive": "furnace_heart",
		"display_name": "Rain of Fire",  # Owner-approved proposal
		"icon": "rain_of_fire",
		"description": "Brimstone pours from the sky in a burning rain that leaves the ground on fire.",
		"labels": {"damage": "Stone damage", "stones": "Stones", "radius": "Blast radius", "pit_share": "Fire per second", "pit_life": "Fire lasts (s)", "cooldown": "Cooldown (s)"},
		"stats": {
			"damage": 36.0, "stones": 5, "radius": 44.0, "pit_radius": 38.0, "pit_life": 3.0, "pit_share": 0.3, "cooldown": 2.6, "range": 380.0,  # TUNING (not in GDD) first pass 46 dmg, 6 stones, 3.5 s, 0.4 (the forced smoke run: 260k damage, ahead of the Death Knights' 140k)
			"rain_gap": 0.12,  # TUNING (not in GDD) the evolution flag: s between two stones of a rain
			"rain_spread": 60.0,  # TUNING (not in GDD) px the stones beyond the groups scatter
		},
	},
	# --- Act VI: the Palace of Silk and Ash ---
	# Unholy Desire (owner-approved Act VI proposal "Rewards": "Temptation ->
	# Unholy Desire (+ Velvet Chains)"): Temptation + Velvet Chains (a NEW
	# passive, owner rule: at Lv 5). Own decision on its kit: three charms a
	# cast, longer, harder-hitting thralls, and every charm that ends (or thrall
	# that falls) BURSTS: `desire` x the thrall's hit to every foe within
	# TemptData.BURST_RADIUS px (TemptData.BURST_SOURCE). Detected by the
	# "desire" key.
	"unholy_desire": {
		"base": "tempt",
		"passive": "velvet_chains",
		"display_name": "Unholy Desire",  # Owner-approved proposal
		"icon": "unholy_desire",
		"description": "Three foes at once burn with desire for you, and burst when the spell lets them go.",
		"labels": {"charms": "Foes charmed", "charm_time": "Charm (s)", "damage": "Thrall hit", "desire": "Burst", "cooldown": "Cooldown (s)"},
		"stats": {
			"charms": 3, "charm_time": 8.0, "damage": 30.0, "range": 280.0, "cooldown": 5.0,  # TUNING (not in GDD)
			"desire": 1.0,  # TUNING (not in GDD) the evolution flag: share of the thrall's hit its burst deals; first pass 1.5 (151k burst damage in the forced run)
		},
	},
	# --- Act VI: Pandemonium ---
	# Lightbringer (GDD §15.0 "Fall from Grace, Lightbringer, Pride and the
	# Fallen Saint"; owner-approved proposal "Fall from Grace -> Lightbringer (+
	# Pride)"): Fall from Grace + Pride (a NEW passive, owner rule: at Lv 5).
	# Three stars a cast on the three strongest foes, harder and wider, and each
	# crash sends a FLARE ring out to FallFromGraceData.FLARE_RADIUS_MULT x the
	# crash radius (`flare` x the damage to every foe in the ring beyond the
	# crash). Detected by the "flare" key.
	"lightbringer": {
		"base": "fall_from_grace",
		"passive": "pride",
		"display_name": "Lightbringer",
		"icon": "lightbringer",
		"description": "Three morning stars fall on the mightiest foes, and every crash flares out in a ring of light.",
		"labels": {"damage": "Star damage", "stars": "Stars", "radius": "Crash radius", "flare": "Flare", "cooldown": "Cooldown (s)"},
		"stats": {
			"stars": 3, "damage": 90.0, "radius": 52.0, "splash": 0.5, "fall_time": 0.45, "cooldown": 2.5,  # TUNING (not in GDD) first pass 120 / r56 / 2.2 s led every source by 4x
			"flare": 0.25,  # TUNING (not in GDD) first pass 0.35; the evolution flag: share of the star's damage its flare ring deals
		},
	},
	# --- Act VII: Ravensmoor ---
	# Wolf of the Red Moon (owner-approved Act VII proposal: "Moonfang -> Wolf
	# of the Red Moon (+ Pack Blood)"): Moonfang + Pack Blood (a NEW passive,
	# owner rule: at Lv 5). Own decision on its kit: the jaws are a red wolf's
	# that leaps from group to group: bigger, harder jaws, longer bleeds, and
	# every jaw that bit something leaps on to the nearest unbitten foe within
	# `chain_reach` px and snaps again, `chain` more times, `chain_gap` s apart.
	# Detected by the "chain" key.
	"wolf_of_the_red_moon": {
		"base": "moonfang",
		"passive": "pack_blood",
		"display_name": "Wolf of the Red Moon",  # Owner-approved proposal
		"icon": "wolf_of_the_red_moon",
		"description": "A red spectral wolf leaps from pack to pack, and every bite leaves them bleeding.",
		"labels": {"damage": "Bite damage", "jaws": "Jaws", "chain": "Leaps", "radius": "Bite radius", "bleed_share": "Bleed per second", "cooldown": "Cooldown (s)"},
		"stats": {
			"damage": 26.0, "jaws": 4, "radius": 34.0, "bleed_share": 0.25, "bleed_time": 4.0, "cooldown": 2.1, "range": 360.0,  # TUNING (not in GDD) first pass 40 / r36 / 0.35 / 4.5 s with 2 leaps (272k from the evolved jaws alone in the forced run)
			"chain": 1,  # TUNING (not in GDD) the evolution flag: more snaps each jaw leaps on to (first pass 2)
			"chain_gap": 0.18,  # TUNING (not in GDD) s between two snaps of a leaping jaw
			"chain_reach": 130.0,  # TUNING (not in GDD) px a jaw leaps to its next group
		},
	},
	# --- Act VII: the Witchwood ---
	# Witches' Sabbath (owner-approved Act VII proposal: "Hex Circle -> Witches'
	# Sabbath (+ Moonlit Rite)"): Hex Circle + Moonlit Rite (a NEW passive, owner
	# rule: at Lv 5). Own decision on its kit: the coven of the necromancer's
	# own: the circle grows and `sabbath_circles` smaller circles of
	# `sabbath_radius` px orbit it `sabbath_orbit` px out at `sabbath_speed`
	# rad/s, each draining like the first. Detected by the "sabbath_circles" key.
	"witches_sabbath": {
		"base": "witch_circle",
		"passive": "moonlit_rite",
		"display_name": "Witches' Sabbath",  # Owner-approved proposal
		"icon": "witches_sabbath",
		"description": "Your circle grows, and three lesser circles dance around it, draining all they cross.",
		"labels": {"damage": "Drain per pulse", "radius": "Radius", "sabbath_circles": "Dancing circles", "cooldown": "Pulse every (s)", "drain": "Drunk back"},
		"stats": {
			"damage": 14.0, "radius": 104.0, "cooldown": 0.8, "drain": 0.2, "heal_cap": 5.0,  # TUNING (not in GDD) first pass 17 (358k in the forced run, ahead of Rain of Fire's 157k)
			"sabbath_circles": 3,  # TUNING (not in GDD) the evolution flag: orbiting circles
			"sabbath_radius": 40.0,  # TUNING (not in GDD) px; first pass 46
			"sabbath_orbit": 160.0,  # TUNING (not in GDD) px from the necromancer
			"sabbath_speed": 1.2,  # TUNING (not in GDD) rad/s
		},
	},
	# --- Act VII: Castle Sanguis ---
	# Nocturne (GDD §15.0 "Night Swarm, Nocturne, Old Blood and the Dhampir";
	# owner-approved proposal "Night Swarm -> Nocturne (+ Old Blood)"): Night
	# Swarm + Old Blood (a NEW passive, owner rule: at Lv 5). A greater swarm,
	# and after each bite a bat LEAPS on to up to `chain` more foes within
	# NightSwarmData.CHAIN_RANGE px (`chain_share` x the damage each). Detected
	# by the "chain" key.
	"nocturne": {
		"base": "night_swarm",
		"passive": "old_blood",
		"display_name": "Nocturne",
		"icon": "nocturne",
		"description": "A night of bats wheels around you, and every bite leaps on to the next throat.",
		"labels": {"bats": "Bats", "damage": "Bite damage", "chain": "Leaps", "chain_share": "Leap damage", "cooldown": "Dart every (s)"},
		"stats": {
			"bats": 8, "damage": 13.0, "orbit": 58.0, "cooldown": 1.5,  # TUNING (not in GDD) first pass 15 (Nocturne led every source by ~2x in the forced run)
			"chain": 1, "chain_share": 0.5,  # TUNING (not in GDD) the evolution flag: leaps after each bite and their share of the bite
		},
	},
	# --- Act VIII: Skid Row ---
	# Funeral Procession (GDD §15.0 "Hearse Run, Funeral Procession, Black Car
	# and the Undertaker (Act VIII)"; owner-approved proposal "Hearse Run ->
	# Funeral Procession (+ Black Car)"): Hearse Run + Black Car (a NEW passive,
	# owner rule: at Lv 5). Own decision on its kit: every hearse is a
	# procession of `procession` cars `procession_gap` px apart, each striking
	# on its own, and every foe a car kills rises as a PALLBEARER (a temporary
	# Warrior, at most `pallbearers` a cast). Detected by the "procession" key.
	"funeral_procession": {
		"base": "hearse_run",
		"passive": "black_car",
		"display_name": "Funeral Procession",  # Owner-approved proposal
		"icon": "funeral_procession",
		"description": "A procession of spectral hearses drives through your foes, and the dead it makes walk behind it.",
		"labels": {"damage": "Hit damage", "hearses": "Hearses", "procession": "Cars each", "pallbearers": "Pallbearers a cast", "cooldown": "Cooldown (s)"},
		"stats": {
			"damage": 26.0, "hearses": 3, "width": 28.0, "length": 640.0, "speed": 560.0, "cooldown": 2.7, "range": 380.0,  # TUNING (not in GDD) first pass 34 (244k from the processions alone in the forced seed-7 run)
			"procession": 3,  # TUNING (not in GDD) the evolution flag: cars in each procession
			"procession_gap": 46.0,  # TUNING (not in GDD) px between two cars
			"pallbearers": 2,  # TUNING (not in GDD) most pallbearers a cast raises (first pass 3: 599 in the forced run)
		},
	},
	# --- Act VIII: Fort Kessler ---
	# Killing Ground (owner-approved Act VIII proposal: "Bone Mines -> Killing
	# Ground (+ Tripwire)"): Bone Mines + Tripwire (a NEW passive, owner rule:
	# at Lv 5). Own decision on its kit: bigger, harder mines laid faster, and
	# each blast throws `shards` bone shards on a ring `shard_reach` px out,
	# each hitting every enemy within `shard_radius` px for shard_share x the
	# damage (source killing_ground_shards). Detected by the "shards" key.
	"killing_ground": {
		"base": "bone_mines",
		"passive": "tripwire",
		"display_name": "Killing Ground",  # Owner-approved proposal
		"icon": "killing_ground",
		"description": "The ground you walk becomes a minefield, and every blast throws bone shrapnel.",
		"labels": {"damage": "Blast damage", "radius": "Blast radius", "max_mines": "Mines laid at once", "shards": "Shards", "shard_share": "Shard damage", "cooldown": "Drop every (s)"},
		"stats": {
			"damage": 50.0, "radius": 56.0, "trigger": 16.0, "max_mines": 14, "spacing": 32.0, "life": 16.0, "cooldown": 0.8,  # TUNING (not in GDD)
			"shards": 6,  # TUNING (not in GDD) the evolution flag: bone shards a blast throws
			"shard_share": 0.4,  # TUNING (not in GDD) of the blast's damage
			"shard_reach": 64.0,  # TUNING (not in GDD) px out from the blast
			"shard_radius": 26.0,  # TUNING (not in GDD) px each shard hits
		},
	},
	# --- Act VIII: Liberty Heights ---
	# Doomsday (GDD §15.0 "Hero's Fist, Doomsday, Secret Identity and the
	# Revenant Heroine"; owner-approved proposal "Hero's Fist -> Doomsday (+
	# Secret Identity)"): Hero's Fist + Secret Identity (a NEW passive, owner
	# rule: at Lv 5). Two fists, harder and farther, and where a flung foe
	# lands (or around an unmoved one) a CRATER of `crater` px strikes
	# crater_share x the damage. Detected by the "crater" key.
	"doomsday": {
		"base": "heros_fist",
		"passive": "secret_identity",
		"display_name": "Doomsday",
		"icon": "doomsday",
		"description": "Two fists fall like the end of the world, and every foe they fling lands in a crater.",
		"labels": {"damage": "Slam damage", "cooldown": "Cooldown (s)", "fists": "Fists", "fling": "Flung (px)", "fling_share": "Flung foe's hit", "crater": "Crater (px)", "crater_share": "Crater damage"},
		"stats": {
			"damage": 95.0, "cooldown": 2.3, "fists": 2, "fling": 240.0, "fling_share": 0.5,  # TUNING (not in GDD) first pass 110 / 2.2 s / 0.65: ~500k damage in the forced seed-7 run, far ahead of every source
			"crater": 64.0, "crater_share": 0.4,  # TUNING (not in GDD) the evolution flag: the crater where a flung foe lands (first pass 0.6)
		},
	},
	# --- Act IX: the Crash Site ---
	# Hive of Bone (GDD §15.0 "Bone Beetles, Hive of Bone, Chitin and the
	# Broodbound (Act IX)"; owner-approved proposal "Bone Beetles -> Hive of
	# Bone (+ Chitin)"): Bone Beetles + Chitin (a NEW passive, owner rule: at
	# Lv 5). Own decision on its kit: each beetle bites `bites` foes in turn,
	# and a foe a beetle kills bursts too (the hive feeds itself, still under
	# the cap). Detected by the "bites" key.
	"hive_of_bone": {
		"base": "bone_beetles",
		"passive": "chitin",
		"display_name": "Hive of Bone",  # Owner-approved proposal
		"icon": "hive_of_bone",
		"description": "A hive of bone beetles: each bites foe after foe, and every foe they kill bursts into more.",
		"labels": {"damage": "Bite damage", "beetles": "Beetles a foe", "bites": "Bites each", "range": "Range", "cap": "Most beetles"},
		"stats": {
			"damage": 11.0, "beetles": 3, "range": 340.0, "speed": 280.0, "seek": 220.0, "life": 3.5, "cap": 32,  # TUNING (not in GDD) first pass 17 / cap 40 (377k from the hive alone in the forced seed-7 run)
			"bites": 2,  # TUNING (not in GDD) the evolution flag: foes each beetle bites in turn (first pass 3)
		},
	},
	# --- Act IX: the Proving Moon ---
	# Apex Predator (GDD §15.0 "Soul Caster, Apex Predator, Trophy Rack and the
	# Blooded (Act IX)"; owner-approved proposal "Soul Caster -> Apex Predator
	# (+ Trophy Rack)"): Soul Caster + Trophy Rack (a NEW passive, owner rule:
	# at Lv 5). Own decision on its kit: five targets, harder shots, x
	# elite_mult on elites, minibosses and bosses, and every kill gives back
	# `refund` s of the cooldown (the predator never stops). Detected by the
	# "refund" key.
	"apex_predator": {
		"base": "soul_caster",
		"passive": "trophy_rack",
		"display_name": "Apex Predator",  # Owner-approved proposal
		"icon": "apex_predator",
		"description": "Five locks, harder shots that hunt the strongest, and every kill reloads the cannon.",
		"labels": {"damage": "Shot damage", "targets": "Targets locked", "elite_mult": "Vs elites and bosses", "refund": "Reload per kill (s)", "cooldown": "Cooldown (s)"},
		"stats": {
			"damage": 58.0, "targets": 5, "lock": 0.4, "range": 360.0, "cooldown": 1.9,  # TUNING (not in GDD)
			"elite_mult": 1.5,  # TUNING (not in GDD) x on elites, minibosses and bosses
			"refund": 0.25,  # TUNING (not in GDD) the evolution flag: s of the cooldown given back per kill
		},
	},
	# --- Act IX: the Ark ---
	# Abduction (id "star_abduction": "abduction" is the Concord rule's source
	# tag and class name; its display name stays "Abduction"; GDD §15.0
	# "Tractor Beam, Abduction, Starseed and the Starborn"; owner-approved
	# proposal "Tractor Beam -> Abduction (+ Starseed)"): Tractor Beam +
	# Starseed (a NEW passive, owner rule: at Lv 5). Three foes lifted a cast,
	# held longer, and every slam first DRAGS the foes within `pull` px in
	# toward it (pull_force / mass) and shakes them for quake_share x the
	# damage. Detected by the "pull" key.
	"star_abduction": {
		"base": "tractor_lift",
		"passive": "starseed",
		"display_name": "Abduction",  # Owner-approved proposal
		"icon": "star_abduction",
		"description": "Three foes rise into the light, and each falls like a star, dragging the rest in after it.",
		"labels": {"damage": "Slam damage", "cooldown": "Cooldown (s)", "lifts": "Lifts", "lift_time": "Lift (s)", "slam_radius": "Slam (px)", "slam_share": "Slam splash", "pull": "Pull (px)", "quake_share": "Quake damage"},
		"stats": {
			"damage": 88.0, "cooldown": 2.4, "lifts": 3, "lift_time": 1.2, "slam_radius": 70.0, "slam_share": 0.5,  # TUNING (not in GDD) first pass 96 / 0.55
			"pull": 120.0, "pull_force": 260.0, "quake_share": 0.18,  # TUNING (not in GDD) the evolution flag: the pull round each slam (first pass 0.3: 244k damage, 95k of it quake, in the forced seed-7 Graveyard run)
		},
	},
	# --- Act X: the Smuggler's Cutter ---
	# Keelhauler (GDD §15.0 "Chain Shot, Keelhauler, Bosun's Whistle and the
	# Marooned Quartermaster (Act X)"; owner-approved proposal "Chain Shot ->
	# Keelhauler (+ Bosun's Whistle)"): Chain Shot + Bosun's Whistle (a NEW
	# passive, owner rule: at Lv 5). Own decision on its kit: heavier, wider
	# shots that KNOCK every foe they strike `knock` px off the line (never a
	# boss, miniboss or structure; on the Black Tide's decks, over the rail).
	# No pull (owner: the act's spells knock back, chain and bombard). Detected
	# by the "knock" key.
	"keelhauler": {
		"base": "chain_shot",
		"passive": "bosuns_whistle",
		"display_name": "Keelhauler",  # Owner-approved proposal
		"icon": "keelhauler",
		"description": "Barnacled chain-shots tear through the line and back, throwing every foe they strike aside.",
		"labels": {"damage": "Hit damage", "shots": "Chain-shots", "knock": "Knockback (px)", "cooldown": "Cooldown (s)"},
		"stats": {
			"damage": 12.0, "shots": 3, "range": 320.0, "speed": 440.0, "width": 22.0, "cooldown": 2.4,  # TUNING (not in GDD) integration balance 16 -> 12 (159k with the base in the forced seed-7 Cutter run, 2.5x the top summon class); first pass 27 / 2.2 s (185k in the forced seed-7 run, 3.4x the Death Knights), then 19 (177k, 1.7x the Mages: its knocks drown more)
			"knock": 80.0,  # TUNING (not in GDD) the evolution flag: px each struck foe is knocked off the line
		},
	},
	# --- Act X: the Treasure Galleon ---
	# Dead Men's Broadside (GDD §15.0 "Cannonade, Dead Men's Broadside, Black
	# Powder and the Corsair Queen (Act X)"; owner-approved proposal "Cannonade
	# -> Dead Men's Broadside (+ Black Powder)"): Cannonade + Black Powder (a NEW
	# passive, owner rule: at Lv 5). Own decision on its kit: five marks,
	# wider blasts, and every mark takes a second ball `salvo` s later dealing
	# `salvo_share` of the damage (a double broadside). Detected by the "salvo" key.
	"dead_mens_broadside": {
		"base": "cannonade",
		"passive": "black_powder",
		"display_name": "Dead Men's Broadside",  # Owner-approved proposal
		"icon": "dead_mens_broadside",
		"description": "Five groups marked at once, and a second ghostly ball follows every first.",
		"labels": {"damage": "Ball damage", "marks": "Groups marked", "salvo": "Second ball after (s)", "cooldown": "Cooldown (s)"},
		"stats": {
			"damage": 26.0, "marks": 5, "radius": 42.0, "range": 380.0, "cooldown": 2.8,  # TUNING (not in GDD) integration balance 30 -> 26 (232k with the base, above the Death Knights); first pass 40 / 2.6 s (the forced seed-7 run: 261k from the evolution alone)
			"salvo": 0.45,  # TUNING (not in GDD) the evolution flag: s between the two balls of a mark
			"salvo_share": 0.5,  # TUNING (not in GDD) x the damage of the second ball
		},
	},
	# --- Act X: the Maelstrom ---
	# Abyssal Mooring (GDD §15.0 "Anchor Drop, Abyssal Mooring, Dead Reckoning
	# and the Ghost Helmsman"; owner-approved proposal "Anchor Drop -> Abyssal
	# Mooring (+ Dead Reckoning)"): Anchor Drop + Dead Reckoning (a NEW passive,
	# owner rule: at Lv 5). Two anchors a cast, harder, a wider shock and a
	# longer stun, and each anchor stays MOORED `moor` s where it fell, shocking
	# the foes within moor_radius px every moor_every s for moor_share x the
	# damage (no pull). Detected by the "moor" key.
	"abyssal_mooring": {
		"base": "anchor_drop",
		"passive": "dead_reckoning",
		"display_name": "Abyssal Mooring",  # Owner-approved proposal
		"icon": "abyssal_mooring",
		"description": "Two anchors fall from the abyss; each stays moored where it lands, shocking all around it.",
		"labels": {"damage": "Slam damage", "cooldown": "Cooldown (s)", "anchors": "Anchors", "anchor_stun": "Stun (s)", "ring_radius": "Shock (px)", "ring_share": "Shock damage", "moor": "Moored (s)", "moor_share": "Mooring pulse"},
		"stats": {
			"damage": 80.0, "cooldown": 2.5, "anchors": 2, "anchor_stun": 1.5, "ring_radius": 70.0, "ring_share": 0.18,  # TUNING (not in GDD) integration balance 90 / 0.3 -> 80 / 0.18 (345k in the forced seed-7 Maelstrom run, 1.5x the top summon class); first passes 74 px / 0.55, then 0.42 (404k in the forced seed-7 Maelstrom run)
			"moor": 2.0, "moor_every": 0.6, "moor_share": 0.06, "moor_radius": 64.0,  # TUNING (not in GDD) integration balance 0.08 -> 0.06; the evolution flag: the moored anchor's pulses (first pass 2.4 s / 0.18 / 70 px: 437k damage in the forced seed-7 Maelstrom run)
		},
	},
	# --- Act XI (temporary): the Barrow Fields ---
	# Barrow-Lord's Embrace (GDD §15.0 "Barrow Grasp, Barrow-Lord's Embrace,
	# Grave Frost and the Rune-Seer"; owner-approved proposal "Barrow Grasp ->
	# Barrow-Lord's Embrace (+ Grave Frost)"): Barrow Grasp + Grave Frost (a NEW
	# passive, owner rule: at Lv 5). Own decision on its kit: two rings of hands
	# (the inner at ring_step of the outer), and every hand LINGERS `linger` s,
	# grabbing again every BarrowGraspData.LINGER_TICK s. Detected by "linger".
	"barrow_lords_embrace": {
		"base": "barrow_grasp",
		"passive": "grave_frost",
		"display_name": "Barrow-Lord's Embrace",  # Owner-approved proposal
		"icon": "barrow_lords_embrace",
		"description": "Two rings of barrow hands rise around you and linger, seizing every foe that walks into them.",
		"labels": {"damage": "Damage", "hands": "Hands", "rings": "Rings", "hold": "Hold", "linger": "Linger (s)", "cooldown": "Cooldown"},
		"stats": {
			"damage": 32.0, "hands": 11, "ring": 170.0, "radius": 33.0, "hold": 1.7, "cooldown": 3.4,  # TUNING (not in GDD)
			"rings": 2, "ring_step": 0.55, "linger": 2.2,  # TUNING (not in GDD) the evolution flag: two rings, lingering hands
		},
	},
	# --- Act XI (temporary): Valgard ---
	# Chooser of the Slain (GDD §15.0 "Valkyrie Spear, Chooser of the Slain,
	# Einherjar's Oath and the Shield-Maiden (Valgard)"; owner-approved
	# proposal "Valkyrie Spear -> Chooser of the Slain (+ Einherjar's Oath)"):
	# Valkyrie Spear + Einherjar's Oath (a NEW passive, owner rule: at Lv 5).
	# Own decision on its kit: more leaps and damage, x elite_mult on elites,
	# minibosses and bosses, and the spear CHOOSES THE SLAIN: every
	# chosen_every-th foe it kills (that leaves a corpse) rises for risen_time s
	# as a temporary Warrior of the army (HordeDirector.spawn_temporary(), the
	# one temporary-summon path: Restless Dead applies), at most risen_cap at
	# once. Detected by the "risen_time" key.
	"chooser_of_the_slain": {
		"base": "valkyrie_spear",
		"passive": "einherjars_oath",
		"display_name": "Chooser of the Slain",  # Owner-approved proposal
		"icon": "chooser_of_the_slain",
		"description": "More leaps and harder strikes, and the foes it slays rise to fight for you.",
		"labels": {"damage": "Spear damage", "jumps": "Leaps", "elite_mult": "Vs elites and bosses", "risen_time": "Chosen rise (s)", "cooldown": "Cooldown (s)"},
		"stats": {
			"damage": 62.0, "jumps": 5, "falloff": 0.84, "chain": 210.0, "range": 390.0, "cooldown": 2.0,  # TUNING (not in GDD)
			"elite_mult": 1.35,  # TUNING (not in GDD) x on elites, minibosses and bosses
			"chosen_every": 4,  # TUNING (not in GDD) every 4th kill of the spear rises
			"risen_time": 12.0,  # TUNING (not in GDD) the evolution flag: s a chosen warrior fights
			"risen_cap": 4,  # TUNING (not in GDD) chosen warriors at once
			"risen_hp": 0.8,  # TUNING (not in GDD) x the Warrior's HP
			"risen_damage": 0.8,  # TUNING (not in GDD) x the Warrior's damage
		},
	},
	# --- Act XI (temporary): Vigrid ---
	# Spear of the Hanged (GDD §15.0 "Gungnir, Spear of the Hanged, Runecraft
	# and the Berserker"; owner-approved proposal "Gungnir -> Spear of the
	# Hanged (+ Runecraft)"): Gungnir + Runecraft (a NEW passive, owner rule: at
	# Lv 5). The god hung nine nights on his own spear for the runes: two spears
	# a cast, wider and longer, and each RETURNS along its line return_delay s
	# later for return_share x the damage. Detected by the "return_share" key.
	"spear_of_the_hanged": {
		"base": "gungnir",
		"passive": "runecraft",
		"display_name": "Spear of the Hanged",  # Owner-approved proposal
		"icon": "spear_of_the_hanged",
		"description": "Two spears fly at the strongest foes and come back to your hand through everything in their line.",
		"labels": {"damage": "Damage", "cooldown": "Cooldown (s)", "spears": "Spears", "spear_width": "Width (px)", "length": "Reach (px)", "return_share": "Return damage"},
		"stats": {
			"damage": 74.0, "cooldown": 2.3, "spears": 2, "spear_width": 14.0, "length": 740.0,  # TUNING (not in GDD) first pass 84 / 2.2 / 15
			"return_share": 0.4, "return_delay": 0.35,  # TUNING (not in GDD) the evolution flag: the spear comes back (first pass 0.5: 331k evolved damage in the forced seed-7 run)
		},
	},
	# --- Act XII (temporary number): the Necropolis of Sand ---
	# Eternal Shroud (GDD §15.0 "Linen Bind, Eternal Shroud, Natron Salts and
	# the Embalmer (Act XII)"; owner-approved proposal "Linen Bind -> Eternal
	# Shroud (+ Natron Salts)"): Linen Bind + Natron Salts (a NEW passive,
	# owner rule: at Lv 5). Own decision on its kit: more foes, longer holds
	# and Mummies, and every risen Mummy that falls bursts into bandages that
	# wrap burst_wraps foes within burst_reach px (half the bind damage; held
	# and wrapped the same, so the shroud feeds itself). Detected by the
	# "burst_wraps" key.
	"eternal_shroud": {
		"base": "linen_bind",
		"passive": "natron_salts",
		"display_name": "Eternal Shroud",  # Owner-approved proposal
		"icon": "eternal_shroud",
		"description": "The shroud never ends: more foes wrapped, and every Mummy that falls bursts into bandages that bind the next.",
		"labels": {"damage": "Bind damage", "targets": "Foes wrapped", "hold": "Hold (s)", "burst_wraps": "Wraps when a Mummy falls", "cap": "Mummies at most"},
		"stats": {
			"damage": 44.0, "targets": 7, "hold": 1.5, "mark": 4.0, "range": 330.0, "cooldown": 2.2, "life": 12.0, "cap": 10,  # TUNING (not in GDD)
			"burst_wraps": 2, "burst_reach": 90.0,  # TUNING (not in GDD) the evolution flag: foes a falling Mummy's bandages wrap, within px
		},
	},
	# --- Act XII (temporary number): the Temple of the Lioness ---
	# Eye of Retribution (GDD §15.0 "Burning Eye, Eye of Retribution, Desert
	# Fury and the Lion-Priestess (Dynasty phase 2)"; owner-approved proposal
	# "Burning Eye -> Eye of Retribution (+ Desert Fury)"): Burning Eye + Desert
	# Fury (a NEW passive, owner rule: at Lv 5). Own decision on its kit: the
	# beam sweeps a wider arc THERE AND BACK (each pass strikes), and whenever
	# the necromancer is hurt the eye opens again at once, at most every
	# `retribution` s (the goddess of retribution). Detected by the
	# "retribution" key.
	"eye_of_retribution": {
		"base": "burning_eye",
		"passive": "desert_fury",
		"display_name": "Eye of Retribution",  # Owner-approved proposal
		"icon": "eye_of_retribution",
		"description": "The eye sweeps there and back, and every blow you take opens it again.",
		"labels": {"damage": "Beam damage", "arc": "Arc (deg)", "range": "Range (px)", "cooldown": "Cooldown (s)", "retribution": "Answers a blow every (s)"},
		"stats": {
			"damage": 60.0, "arc": 140.0, "range": 320.0, "width": 18.0, "sweep_time": 0.6, "cooldown": 2.6,  # TUNING (not in GDD) two passes a sweep
			"retribution": 1.6,  # TUNING (not in GDD) the evolution flag: least s between two sweeps called by a blow
		},
	},
	# --- Act XII (temporary number): the Hall of Two Truths ---
	# Heart Devoured (GDD §15.0 "Feather's Verdict, Heart Devoured, Heavy Heart
	# and the Pharaoh's Shade"; owner-approved proposal "Feather's Verdict ->
	# Heart Devoured (+ Heavy Heart)"): Feather's Verdict + Heavy Heart (a NEW
	# passive, owner rule: at Lv 5). Two feathers a cast on the strongest foes
	# in turn, a higher line and a wider ring, and every execution heals the
	# necromancer devour_heal HP (at most devour_cap a cast). Detected by the
	# "feathers" key.
	"heart_devoured": {
		"base": "feathers_verdict",
		"passive": "heavy_heart",
		"display_name": "Heart Devoured",  # Owner-approved proposal
		"icon": "heart_devoured",
		"description": "Two feathers fall, and every heart they find too light is devoured: each one heals you.",
		"labels": {"damage": "Feather damage", "cooldown": "Cooldown (s)", "feathers": "Feathers", "execute": "Executes under", "ring": "Ring (px)", "devour_heal": "Heal per heart"},
		"stats": {
			"damage": 92.0, "cooldown": 2.6, "range": 320.0, "feathers": 2, "execute": 0.3, "ring": 88.0,  # TUNING (not in GDD)
			"devour_heal": 0.5, "devour_cap": 6.0,  # TUNING (not in GDD) the evolution's heal (HP an execution, HP a cast at most)
		},
	},
	# --- Act XIII (temporary number): the Silver Stair ---
	# Sword at the Gate (GDD §15.0 "Flaming Sword, Sword at the Gate, Fallen
	# Light and the Fallen Herald"; owner-approved proposal "Flaming Sword ->
	# Sword at the Gate (+ Fallen Light)"): Flaming Sword + Fallen Light (a NEW
	# passive, owner rule: at Lv 5). Own decision on its kit: the sword turns a
	# full circle round the necromancer (Seraiel's guard at the Gate), and
	# echo_delay s later it sweeps back once more for echo_share of the damage.
	# Detected by the "echo_share" key.
	"sword_at_the_gate": {
		"base": "flaming_sword",
		"passive": "fallen_light",
		"display_name": "Sword at the Gate",  # Owner-approved proposal
		"icon": "sword_at_the_gate",
		"description": "The sword turns a full circle round you, then sweeps back once more.",
		"labels": {"damage": "Sword damage", "radius": "Reach (px)", "cooldown": "Cooldown (s)", "echo_share": "Echo damage"},
		"stats": {
			"damage": 72.0, "arc": 360.0, "radius": 165.0, "cooldown": 1.7,  # TUNING (not in GDD) a full circle
			"echo_share": 0.5, "echo_delay": 0.3,  # TUNING (not in GDD) the evolution flag: share of the damage the way back strikes, s after the first sweep
		},
	},
}


## Returns the evolution id whose base spell is `spell_id` ("" if none).
static func for_spell(spell_id: String) -> String:
	for id: String in ORDER:
		if String(EVOLUTIONS[id]["base"]) == spell_id:
			return id
	return ""
