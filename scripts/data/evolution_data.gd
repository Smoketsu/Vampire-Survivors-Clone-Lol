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
	# --- Act III: the Scrap Wastes ---
	"event_horizon"]

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
			"damage": 80.0, "targets": 3, "radius": 50.0, "cooldown": 4.5, "range": 340.0, "life": 14.0, "thrall_hp": 0.9, "thrall_damage": 1.0,  # TUNING (not in GDD)
			"host": 1,  # The evolution flag: the drowned rise as Spawns of the Deep.
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
			"damage": 64.0, "cooldown": 2.6, "sweep_time": 1.3, "beam_length": 440.0, "beam_width": 16.0, "spark": 0.6, "spark_range": 150.0,  # TUNING (not in GDD)
			"beams": 2,  # Owner-approved proposal: "two beams sweeping opposite each other"
			"chain": 4,  # Owner-approved proposal: "chain lightning through up to 4 enemies"
			"chain_falloff": 0.15,  # TUNING (not in GDD) damage lost per jump
		},
	},
}


## Returns the evolution id whose base spell is `spell_id` ("" if none).
static func for_spell(spell_id: String) -> String:
	for id: String in ORDER:
		if String(EVOLUTIONS[id]["base"]) == spell_id:
			return id
	return ""
