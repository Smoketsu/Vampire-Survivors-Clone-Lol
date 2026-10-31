## AbilityData — immutable design data for the three shadow spells (GDD §8):
## Shadow Bolt (starting spell), Shadow Orb Shield and Shadow Blast. Each spell
## has five levels (GDD §6). Each level row holds the ABSOLUTE stats at that
## level, so designers read a level without summing increments, and level-up
## cards can show exact "old -> new" values by diffing two rows.
##
## The GDD lists which stats each spell upgrades but no values, so all numbers
## are TUNING (not in GDD).
##
## Four more necromancer spells (user request "more weapons", GDD §5.3
## candidate spells where they fit; logic in scripts/abilities/spells/):
##   Bone Spear       — straight piercing bone spears thrown the way you are
##                      walking (aim-assisted toward the nearest foe ahead).
##   Soul Siphon      — GDD §5.3: tethers drain the strongest nearby foes and
##                      heal you, with a capped lifesteal.
##   Corpse Explosion — detonates fresh corpses (any killer: horde, spells)
##                      into bursts of bone.
##   Plague Cloud     — lingering plague zones that deal damage over time and
##                      inflict Rot (the enemy takes more damage from every
##                      source; GDD open question 30 "curse" status).
## Five more spells (owner-approved, GDD §15.0 "Five more spells"; logic in
## scripts/abilities/spells/, same NecroSpellBook dispatch):
##   Death Mark  — brands the strongest foes in range with a damage-over-time
##                 brand; a branded foe that dies rises as a temporary Risen
##                 skeleton (no damage-taken amplification: owner decision).
##   Bone Wall   — raises a short wall of bone spikes ahead of you that holds
##                 enemies back (they press against it) and hurts them.
##   Soul Chains — a soul-lightning bolt that arcs from foe to foe with
##                 falloff per jump, briefly slowing each one (owner change:
##                 lightning instead of tethers).
##   Wither      — a decay aura around you (garlic-like): damage every pulse
##                 and lowered armour while inside.
##   Raise Dead  — temporary skeletons claw up beside nearby enemies and fight
##                 for a few seconds, outside the army cap.
## Act II's abyssal spells (owner-approved "Unlockable spells and passives",
## GDD §15.0; each unlocked once by slaying one of the act's bosses,
## UnlockData, then offered on every stage at the later items' weight):
##   Undertow    — a wave rolls out in the aim direction over a 120° cone and
##                 shoves enemies back; every third wave leaves slowing
##                 shallow water (Gullhaven Harbour, Abbot Merrow).
## Act III's unlockable spells (owner-approved Act III proposal "Rewards"; each
## unlocked by slaying one of the act's bosses, UnlockData, then offered on
## every stage at the later items' weight):
##   Death Ray   — a soul laser sweeps a full circle around the necromancer
##                 every few seconds, cutting everything along it out to about
##                 420 px; a beam kill sparks lightning to a nearby enemy (the
##                 Scrap Wastes, Kestrel; logic DeathRay, rules DeathRayData).
## Act IV's unlockable spells (owner-approved Act IV proposal "Rewards"; the
## same rule):
##   Stolen Thunder — a charged bolt strikes the strongest enemy and chains to
##                 armoured foes (Mount Olympus, Zeus; logic StolenThunder,
##                 rules StolenThunderData).
class_name AbilityData
extends RefCounted

## Spell the default character, the Gravecaller, starts with (GDD §3 "Begin
## run with a single starting skill"). Each playable character names its own
## starting spell (CharacterData "spell"; AbilityManager.setup() reads it
## through CharacterModifiers.starting_spell()).
const STARTING_SPELL: String = "shadow_bolt"

## Display / card order of spells.
const SPELL_ORDER := ["shadow_bolt", "orb_shield", "shadow_blast",
	"bone_spear", "soul_siphon", "corpse_explosion", "plague_cloud",
	"death_mark", "bone_wall", "soul_chains", "wither", "raise_dead",
	# --- Act II: Gullhaven Harbour ---
	"undertow",
	# --- Act II: the Hollow Archive ---
	"forbidden_verse",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"call_of_the_drowned",
	# --- Act III: the Assembly Halls ---
	"hollow_puppet",
	# --- Act III: the Scrap Wastes ---
	"death_ray",
	# --- Act III: the Iron Citadel ---
	"scrap_swarm",
	# --- Act IV: the Shores of Ilion ---
	"paris_arrow",
	# --- Act IV: Mount Olympus ---
	"stolen_thunder",
	# --- Act IV: the Asphodel Underworld ---
	"river_styx",
	# --- Act V: the Burning Province ---
	"hundred_shadows",
	# --- Act V: the Road to the Sun ---
	"black_sun",
	# --- Act V: Castle Kurogane ---
	"banner_of_the_dead",
	# --- Act VI: the Burning Gate ---
	"brimstone",
	# --- Act VI: the Palace of Silk and Ash ---
	"tempt",
	# --- Act VI: Pandemonium ---
	"fall_from_grace"]

## Spell definitions.
##   display_name — UI name.
##   icon         — IconGlyph kind.
##   description  — card text (GDD §8 wording): one short sentence, no
##                  numbers (GDD §15.0 "Card text: one sentence").
##   labels       — stat key -> UI label, in display order. Only these keys
##                  are listed on cards.
##   levels       — 5 rows of absolute stats.
##   shared_card_pool — true (every spell after the GDD's three): a later
##                  item, its NEW card weighs LevelUpData.WEIGHT_NEW_LATER;
##                  absent: the full LevelUpData.WEIGHT_NEW (the GDD spells).
##
## Shadow Bolt stat keys:
##   damage (per bolt), cooldown (s), count (bolts per cast), pierce (extra
##   enemies passed through), speed (px/s), range (px search radius).
## Orb Shield stat keys:
##   orbs (count), damage (per touch), orbit_radius (px), orbit_speed (rad/s),
##   hit_cooldown (s between touches on the same enemy), recharge (s before a
##   spent orb can intercept another projectile; GDD §8 "charge-limited").
## Shadow Blast stat keys:
##   damage, radius (px), cooldown (s), slow (fraction of speed removed),
##   slow_duration (s).
## Bone Spear stat keys:
##   damage (per spear per enemy), cooldown (s), count (spears per volley,
##   fanned by SPEAR_SPREAD), pierce (extra enemies passed through), speed
##   (px/s), range (px a spear flies before it crumbles).
## Soul Siphon stat keys:
##   damage (drained from each tethered enemy per pulse), cooldown (s between
##   drain pulses), targets (tethers at once), range (px tether reach),
##   lifesteal (fraction of drained damage healed), heal_cap (HP/s: the most
##   the siphon can heal per second; GDD §5.3 "capped lifesteal").
## Corpse Explosion stat keys:
##   damage (per enemy per burst), radius (px burst radius), cooldown (s),
##   count (corpses detonated per cast), range (px around the necromancer in
##   which corpses are used).
## Plague Cloud stat keys:
##   damage (per enemy per PLAGUE_TICK), radius (px cloud radius), duration
##   (s a cloud lingers), cooldown (s between clouds), rot (fraction: extra
##   damage a rotting enemy takes from every source), range (px from the
##   necromancer in which a cloud is placed).
## Death Mark stat keys:
##   damage (per brand per DEATH_MARK_TICK), duration (s a brand lasts),
##   cooldown (s between casts), count (enemies branded per cast), range (px
##   search radius), risen_cap (most Death Mark Risen alive at once).
## Bone Wall stat keys:
##   damage (per BONE_WALL_TICK to each enemy pressing on the wall), cooldown
##   (s), duration (s the wall stands), segments (bone-spike segments, each
##   BONE_WALL_SEGMENT_RADIUS px, BONE_WALL_SPACING px apart), distance (px
##   from the necromancer to the wall's centre).
## Soul Chains stat keys:
##   damage (first strike), cooldown (s), jumps (arcs after the first
##   strike), falloff (fraction of damage lost per jump, compounding),
##   jump_range (px from one struck enemy to the next), range (px search
##   radius of the first strike), slow (fraction of speed removed),
##   slow_duration (s).
## Wither stat keys:
##   damage (per pulse to each enemy inside), radius (px aura radius),
##   cooldown (s between pulses), shred (fraction of armour and flat armour
##   removed while inside; bosses get WITHER_BOSS_MULT of it).
## Raise Dead stat keys:
##   count (skeletons per cast), cooldown (s), life (s a skeleton lasts),
##   skeleton_hp / skeleton_damage (fractions of a Skeleton Warrior's current
##   HP / damage), range (px around the necromancer in which enemies are
##   looked for).
## Undertow stat keys (fixed rules in UndertowData):
##   damage (per enemy in the cone), cooldown (s), range (px reach of the
##   cone), push (px/s shove impulse, divided by enemy mass), slow (fraction
##   of speed removed by the shallow water), slow_duration (s; owner-approved 3).
## Forbidden Verse stat keys (Act II, the Hollow Archive; unlocked by slaying
## the Archivist, UnlockData; rules in VerseData):
##   pages (orbiting pages), damage (per cut), orbit_radius (px), orbit_speed
##   (rad/s), hit_cooldown (s between two cuts on the same enemy), inscribe (s
##   an enemy stays inscribed), burst (ink burst damage as a fraction of
##   `damage`), radius (px burst radius), cooldown (s between page sweeps).
const SPELLS := {
	"shadow_bolt": {
		"display_name": "Shadow Bolt",
		"icon": "shadow_bolt",
		"description": "Fires homing shadow bolts at nearby foes.",
		"labels": {"damage": "Damage", "count": "Bolts", "cooldown": "Cooldown (s)", "pierce": "Pierce", "speed": "Speed"},
		"levels": [
			{"damage": 15.0, "cooldown": 1.0, "count": 1, "pierce": 0, "speed": 380.0, "range": 380.0},  # TUNING (not in GDD)
			{"damage": 20.0, "cooldown": 1.0, "count": 1, "pierce": 0, "speed": 380.0, "range": 380.0},  # TUNING (not in GDD)
			{"damage": 20.0, "cooldown": 1.0, "count": 2, "pierce": 0, "speed": 380.0, "range": 380.0},  # TUNING (not in GDD)
			{"damage": 20.0, "cooldown": 0.9, "count": 2, "pierce": 1, "speed": 440.0, "range": 400.0},  # TUNING (not in GDD)
			{"damage": 26.0, "cooldown": 0.8, "count": 3, "pierce": 1, "speed": 440.0, "range": 420.0},  # TUNING (not in GDD)
		],
	},
	"orb_shield": {
		"display_name": "Shadow Orb Shield",
		"icon": "orb_shield",
		"description": "Shadow orbs circle you, striking foes and catching projectiles.",
		"labels": {"orbs": "Orbs", "damage": "Damage", "orbit_radius": "Orbit radius", "orbit_speed": "Orbit speed", "recharge": "Intercept recharge (s)"},
		"levels": [
			{"orbs": 2, "damage": 8.0, "orbit_radius": 52.0, "orbit_speed": 2.6, "hit_cooldown": 0.5, "recharge": 5.0},  # TUNING (not in GDD)
			{"orbs": 3, "damage": 8.0, "orbit_radius": 52.0, "orbit_speed": 2.6, "hit_cooldown": 0.5, "recharge": 5.0},  # TUNING (not in GDD)
			{"orbs": 3, "damage": 12.0, "orbit_radius": 60.0, "orbit_speed": 2.6, "hit_cooldown": 0.5, "recharge": 5.0},  # TUNING (not in GDD)
			{"orbs": 4, "damage": 12.0, "orbit_radius": 60.0, "orbit_speed": 2.6, "hit_cooldown": 0.5, "recharge": 3.5},  # TUNING (not in GDD)
			{"orbs": 5, "damage": 16.0, "orbit_radius": 64.0, "orbit_speed": 3.4, "hit_cooldown": 0.5, "recharge": 3.5},  # TUNING (not in GDD)
		],
	},
	"shadow_blast": {
		"display_name": "Shadow Blast",
		"icon": "shadow_blast",
		"description": "Shadow erupts around you, wounding and slowing nearby foes.",
		"labels": {"damage": "Damage", "radius": "Radius", "cooldown": "Cooldown (s)", "slow": "Slow", "slow_duration": "Slow duration (s)"},
		"levels": [
			{"damage": 22.0, "radius": 80.0, "cooldown": 4.0, "slow": 0.3, "slow_duration": 1.0},  # TUNING (not in GDD)
			{"damage": 30.0, "radius": 80.0, "cooldown": 4.0, "slow": 0.3, "slow_duration": 1.0},  # TUNING (not in GDD)
			{"damage": 30.0, "radius": 105.0, "cooldown": 4.0, "slow": 0.3, "slow_duration": 1.0},  # TUNING (not in GDD)
			{"damage": 30.0, "radius": 105.0, "cooldown": 3.0, "slow": 0.45, "slow_duration": 1.0},  # TUNING (not in GDD)
			{"damage": 42.0, "radius": 125.0, "cooldown": 3.0, "slow": 0.45, "slow_duration": 1.5},  # TUNING (not in GDD)
		],
	},
	"bone_spear": {
		"display_name": "Bone Spear",
		"icon": "bone_spear",
		"description": "Hurls piercing bone spears ahead of you as you walk.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Damage", "count": "Spears", "cooldown": "Cooldown (s)", "pierce": "Pierce", "range": "Range"},
		"levels": [
			{"damage": 18.0, "cooldown": 1.3, "count": 1, "pierce": 2, "speed": 520.0, "range": 360.0},  # TUNING (not in GDD)
			{"damage": 22.0, "cooldown": 1.3, "count": 2, "pierce": 2, "speed": 520.0, "range": 360.0},  # TUNING (not in GDD)
			{"damage": 22.0, "cooldown": 1.1, "count": 2, "pierce": 3, "speed": 560.0, "range": 400.0},  # TUNING (not in GDD)
			{"damage": 27.0, "cooldown": 1.1, "count": 3, "pierce": 3, "speed": 560.0, "range": 400.0},  # TUNING (not in GDD)
			{"damage": 31.0, "cooldown": 0.9, "count": 3, "pierce": 4, "speed": 600.0, "range": 440.0},  # TUNING (not in GDD)
		],
	},
	"soul_siphon": {
		"display_name": "Soul Siphon",
		"icon": "soul_siphon",
		"description": "Soul tethers drain the strongest nearby foes to heal you.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Drain", "targets": "Tethers", "cooldown": "Drain every (s)", "range": "Range", "lifesteal": "Lifesteal", "heal_cap": "Heal cap (HP/s)"},
		"levels": [
			{"damage": 7.0, "cooldown": 0.5, "targets": 1, "range": 170.0, "lifesteal": 0.25, "heal_cap": 1.0},  # TUNING (not in GDD)
			{"damage": 9.0, "cooldown": 0.5, "targets": 1, "range": 170.0, "lifesteal": 0.25, "heal_cap": 1.0},  # TUNING (not in GDD)
			{"damage": 9.0, "cooldown": 0.5, "targets": 2, "range": 190.0, "lifesteal": 0.25, "heal_cap": 1.5},  # TUNING (not in GDD)
			{"damage": 12.0, "cooldown": 0.5, "targets": 2, "range": 190.0, "lifesteal": 0.3, "heal_cap": 1.5},  # TUNING (not in GDD)
			{"damage": 14.0, "cooldown": 0.45, "targets": 3, "range": 210.0, "lifesteal": 0.35, "heal_cap": 2.0},  # TUNING (not in GDD)
		],
	},
	"corpse_explosion": {
		"display_name": "Corpse Explosion",
		"icon": "corpse_explosion",
		"description": "Detonates fresh corpses near you in bursts of bone.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Damage", "radius": "Radius", "count": "Corpses per cast", "cooldown": "Cooldown (s)", "range": "Range"},
		"levels": [
			# Combined balance pass: damage 24/30/30/36/40 -> 22/26/26/30/34 and cooldown
			# 2.2/2.2/1.9/1.9/1.6 -> 2.4/2.4/2.2/2.2/2.0 (Lv 5 output about -32%). Unevolved
			# it dealt about 165k in naive runs (mage about 90k, Shadow Bolt about 47k): every
			# kill feeds it and it always bursts on the densest pack.
			{"damage": 22.0, "radius": 50.0, "cooldown": 2.4, "count": 1, "range": 240.0},  # TUNING (not in GDD)
			{"damage": 26.0, "radius": 50.0, "cooldown": 2.4, "count": 2, "range": 240.0},  # TUNING (not in GDD)
			{"damage": 26.0, "radius": 60.0, "cooldown": 2.2, "count": 2, "range": 260.0},  # TUNING (not in GDD)
			{"damage": 30.0, "radius": 60.0, "cooldown": 2.2, "count": 3, "range": 260.0},  # TUNING (not in GDD)
			{"damage": 34.0, "radius": 70.0, "cooldown": 2.0, "count": 3, "range": 280.0},  # TUNING (not in GDD)
		],
	},
	"plague_cloud": {
		"display_name": "Plague Cloud",
		"icon": "plague_cloud",
		"description": "Plague clouds settle on packed foes and rot them to take more damage.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Damage per tick", "radius": "Radius", "duration": "Duration (s)", "cooldown": "Cooldown (s)", "rot": "Rot (damage taken)"},
		"levels": [
			# Two cuts: the first pass (4-8 dmg/tick, 4-6 s, every 3.0-2.2 s) and a second
			# (3-6 dmg/tick) still dealt 2-3x Shadow Blast's damage in naive runs (up to 37%
			# of all damage): a cloud always sits on the densest pack, so coverage was cut.
			# Combined balance pass, a third cut: damage 3/3/3/4/4 -> 2/2/2/3/3, duration
			# 3.5/4/4/4.5/5 -> 3/3.5/3.5/4/4.5, cooldown 3.4/3.4/3.2/3.2/3.0 -> 3.8/3.8/3.6/3.6/3.4
			# (about -40% damage; Rot unchanged, it is the spell's real job). Unevolved at
			# Lv 4 it still dealt 150-230k in naive Crimson March runs, up to 80% of all damage.
			{"damage": 2.0, "radius": 55.0, "duration": 3.0, "cooldown": 3.8, "rot": 0.08, "range": 260.0},  # TUNING (not in GDD)
			{"damage": 2.0, "radius": 55.0, "duration": 3.5, "cooldown": 3.8, "rot": 0.10, "range": 260.0},  # TUNING (not in GDD)
			{"damage": 2.0, "radius": 62.0, "duration": 3.5, "cooldown": 3.6, "rot": 0.12, "range": 260.0},  # TUNING (not in GDD)
			{"damage": 3.0, "radius": 62.0, "duration": 4.0, "cooldown": 3.6, "rot": 0.15, "range": 260.0},  # TUNING (not in GDD)
			{"damage": 3.0, "radius": 70.0, "duration": 4.5, "cooldown": 3.4, "rot": 0.18, "range": 280.0},  # TUNING (not in GDD)
		],
	},
	"death_mark": {
		"display_name": "Death Mark",
		"icon": "death_mark",
		"description": "Brands the strongest foes, and the branded dead rise to fight for you.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Brand damage per tick", "duration": "Brand duration (s)", "count": "Brands per cast", "cooldown": "Cooldown (s)", "risen_cap": "Risen at once"},
		"levels": [
			# Owner: no damage-taken amplification; the brand alone must kill early
			# foes (a Lv 1 brand deals 40 over 5 s: a recruit has 14 HP, a footman 36).
			{"damage": 4.0, "duration": 5.0, "cooldown": 2.4, "count": 1, "range": 340.0, "risen_cap": 2},  # TUNING (not in GDD)
			{"damage": 5.0, "duration": 5.0, "cooldown": 2.4, "count": 1, "range": 340.0, "risen_cap": 2},  # TUNING (not in GDD)
			{"damage": 5.0, "duration": 6.0, "cooldown": 2.2, "count": 2, "range": 360.0, "risen_cap": 3},  # TUNING (not in GDD)
			{"damage": 6.0, "duration": 6.0, "cooldown": 2.0, "count": 2, "range": 360.0, "risen_cap": 3},  # TUNING (not in GDD)
			{"damage": 7.0, "duration": 6.0, "cooldown": 1.8, "count": 2, "range": 380.0, "risen_cap": 4},  # TUNING (not in GDD)
		],
	},
	"bone_wall": {
		"display_name": "Bone Wall",
		"icon": "bone_wall",
		"description": "Raises a wall of bone spikes that holds foes back and tears them.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Spike damage per tick", "segments": "Wall segments", "duration": "Wall duration (s)", "cooldown": "Cooldown (s)"},
		"levels": [
			{"damage": 4.0, "cooldown": 7.0, "duration": 3.5, "segments": 5, "distance": 70.0},  # TUNING (not in GDD)
			{"damage": 5.0, "cooldown": 7.0, "duration": 3.5, "segments": 6, "distance": 70.0},  # TUNING (not in GDD)
			{"damage": 5.0, "cooldown": 6.5, "duration": 4.0, "segments": 7, "distance": 75.0},  # TUNING (not in GDD)
			{"damage": 7.0, "cooldown": 6.5, "duration": 4.0, "segments": 8, "distance": 75.0},  # TUNING (not in GDD)
			{"damage": 8.0, "cooldown": 6.0, "duration": 4.5, "segments": 9, "distance": 80.0},  # TUNING (not in GDD)
		],
	},
	"soul_chains": {
		"display_name": "Soul Chains",
		"icon": "soul_chains",
		"description": "Soul lightning arcs from foe to foe, slowing each one it strikes.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Damage", "jumps": "Jumps", "falloff": "Falloff per jump", "cooldown": "Cooldown (s)", "slow": "Slow", "slow_duration": "Slow duration (s)"},
		"levels": [
			{"damage": 18.0, "cooldown": 1.6, "jumps": 2, "falloff": 0.2, "jump_range": 110.0, "range": 320.0, "slow": 0.25, "slow_duration": 0.6},  # TUNING (not in GDD)
			{"damage": 22.0, "cooldown": 1.6, "jumps": 2, "falloff": 0.2, "jump_range": 110.0, "range": 320.0, "slow": 0.25, "slow_duration": 0.6},  # TUNING (not in GDD)
			{"damage": 22.0, "cooldown": 1.5, "jumps": 3, "falloff": 0.2, "jump_range": 120.0, "range": 340.0, "slow": 0.3, "slow_duration": 0.6},  # TUNING (not in GDD)
			{"damage": 27.0, "cooldown": 1.4, "jumps": 3, "falloff": 0.18, "jump_range": 120.0, "range": 340.0, "slow": 0.3, "slow_duration": 0.8},  # TUNING (not in GDD)
			{"damage": 31.0, "cooldown": 1.3, "jumps": 4, "falloff": 0.18, "jump_range": 130.0, "range": 360.0, "slow": 0.35, "slow_duration": 0.8},  # TUNING (not in GDD)
		],
	},
	"wither": {
		"display_name": "Wither",
		"icon": "wither",
		"description": "A decay aura withers nearby foes and rots their armour away.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Damage per pulse", "radius": "Radius", "cooldown": "Pulse every (s)", "shred": "Armour removed"},
		"levels": [
			# First pass (radius 60-85, damage 4-10) dealt 2.4k in 10 minutes of a forced
			# run: a kiting necromancer rarely lets foes that close.
			{"damage": 5.0, "radius": 80.0, "cooldown": 1.0, "shred": 0.25},  # TUNING (not in GDD)
			{"damage": 7.0, "radius": 80.0, "cooldown": 1.0, "shred": 0.25},  # TUNING (not in GDD)
			{"damage": 7.0, "radius": 90.0, "cooldown": 0.9, "shred": 0.35},  # TUNING (not in GDD)
			{"damage": 9.0, "radius": 95.0, "cooldown": 0.9, "shred": 0.35},  # TUNING (not in GDD)
			{"damage": 11.0, "radius": 105.0, "cooldown": 0.8, "shred": 0.5},  # TUNING (not in GDD)
		],
	},
	"raise_dead": {
		"display_name": "Raise Dead",
		"icon": "raise_dead",
		"description": "Skeletons briefly claw up beside nearby foes, beyond your army's limit.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"count": "Skeletons", "cooldown": "Cooldown (s)", "life": "Skeleton life (s)", "skeleton_hp": "Skeleton HP", "skeleton_damage": "Skeleton damage"},
		"levels": [
			{"count": 2, "cooldown": 9.0, "life": 7.0, "skeleton_hp": 0.5, "skeleton_damage": 0.6, "range": 260.0},  # TUNING (not in GDD)
			{"count": 3, "cooldown": 9.0, "life": 7.0, "skeleton_hp": 0.5, "skeleton_damage": 0.7, "range": 260.0},  # TUNING (not in GDD)
			{"count": 3, "cooldown": 8.0, "life": 8.0, "skeleton_hp": 0.6, "skeleton_damage": 0.8, "range": 280.0},  # TUNING (not in GDD)
			{"count": 4, "cooldown": 8.0, "life": 8.0, "skeleton_hp": 0.6, "skeleton_damage": 0.9, "range": 280.0},  # TUNING (not in GDD)
			{"count": 4, "cooldown": 7.0, "life": 9.0, "skeleton_hp": 0.7, "skeleton_damage": 1.0, "range": 300.0},  # TUNING (not in GDD)
		],
	},
	# --- Act II: Gullhaven Harbour ---
	"undertow": {
		"display_name": "Undertow",
		"icon": "undertow",
		"description": "A wave rolls out before you, shoving foes back and leaving slowing shallows.",
		"shared_card_pool": true,  # owner-approved: unlocked Act II spells weigh the later items' 0.5
		"labels": {"damage": "Damage", "range": "Reach", "cooldown": "Cooldown (s)", "push": "Shove", "slow": "Shallows slow"},
		"levels": [
			{"damage": 16.0, "cooldown": 2.6, "range": 150.0, "push": 220.0, "slow": 0.30, "slow_duration": 3.0},  # TUNING (not in GDD); slow_duration owner-approved 3 s
			{"damage": 20.0, "cooldown": 2.6, "range": 150.0, "push": 240.0, "slow": 0.30, "slow_duration": 3.0},  # TUNING (not in GDD)
			{"damage": 20.0, "cooldown": 2.3, "range": 170.0, "push": 260.0, "slow": 0.35, "slow_duration": 3.0},  # TUNING (not in GDD)
			{"damage": 25.0, "cooldown": 2.3, "range": 170.0, "push": 280.0, "slow": 0.35, "slow_duration": 3.0},  # TUNING (not in GDD)
			{"damage": 30.0, "cooldown": 2.0, "range": 190.0, "push": 300.0, "slow": 0.40, "slow_duration": 3.0},  # TUNING (not in GDD)
		],
	},
	# --- Act II: the Hollow Archive ---
	"forbidden_verse": {
		"display_name": "Forbidden Verse",
		"icon": "forbidden_verse",
		"description": "Pages of scripture circle you, cutting foes and inscribing them to burst into ink.",
		"shared_card_pool": true,  # TUNING (not in GDD) an unlocked Act II spell: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER (owner-approved 0.5)
		"labels": {"damage": "Cut damage", "pages": "Pages", "inscribe": "Inscription (s)", "burst": "Ink burst", "radius": "Burst radius", "cooldown": "Sweep every (s)"},
		"levels": [
			{"pages": 3, "damage": 9.0, "orbit_radius": 64.0, "orbit_speed": 2.4, "hit_cooldown": 0.5, "inscribe": 4.0, "burst": 1.0, "radius": 40.0, "cooldown": 5.0},  # TUNING (not in GDD) owner-approved "three pages"
			{"pages": 3, "damage": 12.0, "orbit_radius": 64.0, "orbit_speed": 2.4, "hit_cooldown": 0.5, "inscribe": 4.0, "burst": 1.0, "radius": 40.0, "cooldown": 5.0},  # TUNING (not in GDD)
			{"pages": 3, "damage": 12.0, "orbit_radius": 72.0, "orbit_speed": 2.6, "hit_cooldown": 0.5, "inscribe": 5.0, "burst": 1.2, "radius": 44.0, "cooldown": 4.5},  # TUNING (not in GDD)
			{"pages": 3, "damage": 15.0, "orbit_radius": 72.0, "orbit_speed": 2.6, "hit_cooldown": 0.45, "inscribe": 5.0, "burst": 1.2, "radius": 44.0, "cooldown": 4.5},  # TUNING (not in GDD)
			{"pages": 3, "damage": 18.0, "orbit_radius": 80.0, "orbit_speed": 2.9, "hit_cooldown": 0.45, "inscribe": 6.0, "burst": 1.4, "radius": 50.0, "cooldown": 4.0},  # TUNING (not in GDD) first pass (burst 1.6-2.0, radius 46-60) dealt ~80% of its damage in bursts, 260k in an army run
		],
	},
	# --- Act II: Ul-Thalos, the Risen Spire ---
	# Call of the Drowned (GDD §15.0 "Ul-Thalos, the Risen Spire"; unlocked by
	# slaying Vhal'Neth, UnlockData): the Eye's Claim turned against it.
	# Tendrils rise under the strongest foes in range every `cooldown` s
	# (`targets` of them, after a short telegraph): `damage` to every foe
	# within `radius` px of each, slowing them; a foe they kill rises as YOUR
	# Drowned Thrall for `life` s (HordeDirector.spawn_temporary(), so Restless
	# Dead and the Grave Herald's innate apply), with `thrall_hp` /
	# `thrall_damage` of a Skeleton Warrior's current stats. Logic:
	# CallOfTheDrowned; fixed rules: CallDrownedData.
	"call_of_the_drowned": {
		"display_name": "Call of the Drowned",
		"icon": "call_of_the_drowned",
		"description": "Tendrils drag the strongest foes under; those they drown rise to fight for you.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Tendril damage", "targets": "Tendrils", "cooldown": "Cooldown (s)", "life": "Thrall life (s)", "thrall_damage": "Thrall damage"},
		"levels": [
			{"damage": 26.0, "targets": 1, "radius": 34.0, "cooldown": 3.0, "range": 280.0, "life": 12.0, "thrall_hp": 0.5, "thrall_damage": 0.6},  # TUNING (not in GDD) proposal "every 6 s" was effectively 3 s live (a double step, fixed Oct 2026, GDD §15.0 "Double-stepped Act II spells"): halved to keep it as played; "for 12 s"
			{"damage": 32.0, "targets": 1, "radius": 36.0, "cooldown": 3.0, "range": 290.0, "life": 12.0, "thrall_hp": 0.55, "thrall_damage": 0.7},  # TUNING (not in GDD) halved with the double-step fix
			{"damage": 40.0, "targets": 2, "radius": 38.0, "cooldown": 3.0, "range": 300.0, "life": 12.0, "thrall_hp": 0.6, "thrall_damage": 0.8},  # TUNING (not in GDD) halved with the double-step fix
			{"damage": 48.0, "targets": 2, "radius": 40.0, "cooldown": 2.75, "range": 310.0, "life": 12.0, "thrall_hp": 0.65, "thrall_damage": 0.9},  # TUNING (not in GDD) halved with the double-step fix
			{"damage": 58.0, "targets": 3, "radius": 44.0, "cooldown": 2.5, "range": 320.0, "life": 12.0, "thrall_hp": 0.7, "thrall_damage": 1.0},  # TUNING (not in GDD) halved with the double-step fix
		],
	},
	# --- Act III: the Assembly Halls ---
	# Hollow Puppet (GDD §15.0 "The Assembly Halls (Act III phase 2)"; owner-
	# approved proposal: "curses the strongest nearby non-boss enemy: for 8 s it
	# fights for you, then dies"; unlocked by slaying the Motherboard,
	# UnlockData). Every `cooldown` s the strongest foe (the most HP) within
	# `range` px of the necromancer that is not a boss, miniboss, structure or
	# Reckoning foe is cut loose from its side: it leaves the field and rises
	# as YOUR puppet, a temporary summon (HordeDirector.spawn_temporary(), so
	# Restless Dead, the Grave Herald and Strings of the Dead apply) with
	# `puppet_hp` of the foe's HP, hitting for `damage`, for `puppet_life` s;
	# then it dies (its XP drops). Logic: HollowPuppet; fixed rules: PuppetData.
	"hollow_puppet": {
		"display_name": "Hollow Puppet",
		"icon": "hollow_puppet",
		"description": "Strings of soul seize the strongest foe nearby: it fights for you, then dies.",
		"shared_card_pool": true,  # TUNING (not in GDD) an unlocked Act III spell: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER (as Act II's)
		"labels": {"damage": "Puppet damage", "puppets": "Puppets", "puppet_life": "Puppet life (s)", "puppet_hp": "Puppet HP (of the foe's)", "cooldown": "Cooldown (s)"},
		"levels": [
			{"damage": 16.0, "puppets": 1, "puppet_life": 8.0, "puppet_hp": 0.8, "cooldown": 11.0, "range": 260.0},  # Owner-approved proposal "for 8 s"; the rest TUNING (not in GDD)
			{"damage": 20.0, "puppets": 1, "puppet_life": 8.0, "puppet_hp": 0.8, "cooldown": 10.5, "range": 275.0},  # TUNING (not in GDD)
			{"damage": 25.0, "puppets": 1, "puppet_life": 8.0, "puppet_hp": 0.9, "cooldown": 10.0, "range": 290.0},  # TUNING (not in GDD)
			{"damage": 30.0, "puppets": 1, "puppet_life": 8.0, "puppet_hp": 0.9, "cooldown": 9.0, "range": 305.0},  # TUNING (not in GDD)
			{"damage": 36.0, "puppets": 1, "puppet_life": 8.0, "puppet_hp": 1.0, "cooldown": 8.0, "range": 320.0},  # TUNING (not in GDD)
		],
	},
	# --- Act III: the Scrap Wastes ---
	# Death Ray (owner-approved Act III proposal; unlocked by slaying Kestrel,
	# UnlockData): "A soul laser fires from the necromancer and sweeps a full
	# circle around you every few seconds, cutting everything in its line out
	# to about 420 px ... It moves with you: nothing to stand in. Each kill on
	# the beam sparks lightning to one nearby enemy." Every `cooldown` s (start
	# to start) a beam `beam_length` px long and `beam_width` px wide turns one
	# full circle around the necromancer in `sweep_time` s, dealing `damage` to
	# every enemy it crosses (once per sweep); a foe it kills sparks lightning
	# to the nearest other foe within `spark_range` px for `spark` x the beam's
	# damage. Stat keys: damage, cooldown (s), sweep_time (s), beam_length (px),
	# beam_width (px), spark (fraction of the beam damage), spark_range (px),
	# beams (beams 360/beams degrees apart). Logic: DeathRay; fixed rules:
	# DeathRayData; Conductive Marrow lengthens and widens the beam
	# (AbilityManager.apply_spell_mods(): beam_length, beam_width).
	"death_ray": {
		"display_name": "Death Ray",
		"icon": "death_ray",
		"description": "A soul laser sweeps a full circle around you; its kills spark lightning.",
		"shared_card_pool": true,  # TUNING (not in GDD) an unlocked Act III spell: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Beam damage", "beam_length": "Beam length", "cooldown": "Sweep every (s)", "spark": "Spark damage", "beam_width": "Beam width"},
		"levels": [
			{"damage": 16.0, "cooldown": 7.5, "sweep_time": 1.5, "beam_length": 230.0, "beam_width": 10.0, "spark": 0.4, "spark_range": 120.0, "beams": 1},  # TUNING (not in GDD) Act III balance: every cooldown about x1.9 (4.0 / 4.0 / 3.8 / 3.6 / 3.4 -> 7.5 / 7.5 / 7.2 / 6.9 / 6.6 s) and the beam 300-420 -> 230-310 px (the owner-approved "about 420 px" reach is an open question): halving the sweeps alone still left 251-271k, 51-56%, because a slower sweep meets more foes; it dealt 334-351k, 69-71% of a Graveyard evolve run, against an evolved Bone Spear's 144-148k, 30%)
			{"damage": 19.0, "cooldown": 7.5, "sweep_time": 1.5, "beam_length": 250.0, "beam_width": 10.0, "spark": 0.4, "spark_range": 120.0, "beams": 1},  # TUNING (not in GDD)
			{"damage": 23.0, "cooldown": 7.2, "sweep_time": 1.4, "beam_length": 270.0, "beam_width": 12.0, "spark": 0.4, "spark_range": 130.0, "beams": 1},  # TUNING (not in GDD)
			{"damage": 27.0, "cooldown": 6.9, "sweep_time": 1.4, "beam_length": 290.0, "beam_width": 12.0, "spark": 0.4, "spark_range": 130.0, "beams": 1},  # TUNING (not in GDD)
			{"damage": 32.0, "cooldown": 6.6, "sweep_time": 1.3, "beam_length": 310.0, "beam_width": 14.0, "spark": 0.4, "spark_range": 140.0, "beams": 1},  # Owner-approved proposal "out to about 420 px"; TUNING (not in GDD) the rest (first pass 52 dmg / 3.0 s / spark 0.6 + Event Horizon dealt 456k, 5,500 kills in a Graveyard evolve run: cut; pass 2: 40 dmg / spark 0.45 still dealt 435k, 91% of the run, against 125k for Bone Spear on the same seed: damage -20% on every level)
		],
	},
	# --- Act III: the Iron Citadel ---
	# Scrap Swarm (GDD §15.0 "Scrap Swarm, Machine Soul and the Rust Prophet";
	# unlocked by defeating Deus Ex Machina, UnlockData): `drones` bone-and-scrap
	# drones orbit OUTSIDE the Bone Ring (owner-approved: about 40 px past its
	# outer edge, so the orbit widens with the army) at `orbit_speed` rad/s;
	# each fires a bolt every `cooldown` s at the nearest foe within `range` px
	# that has not reached the army yet, for `damage`. Logic: ScrapSwarm; fixed
	# rules: ScrapSwarmData.
	"scrap_swarm": {
		"display_name": "Scrap Swarm",
		"icon": "scrap_swarm",
		"description": "Drones of bone and scrap orbit beyond your ring and shoot foes before they reach your army.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Bolt damage", "drones": "Drones", "cooldown": "Fire interval (s)", "range": "Range"},
		"levels": [
			{"drones": 3, "damage": 9.0, "cooldown": 1.2, "range": 200.0, "orbit_speed": 1.0},  # TUNING (not in GDD)
			{"drones": 3, "damage": 11.0, "cooldown": 1.1, "range": 210.0, "orbit_speed": 1.05},  # TUNING (not in GDD)
			{"drones": 4, "damage": 11.0, "cooldown": 1.05, "range": 220.0, "orbit_speed": 1.1},  # TUNING (not in GDD)
			{"drones": 4, "damage": 13.0, "cooldown": 0.95, "range": 230.0, "orbit_speed": 1.15},  # TUNING (not in GDD)
			{"drones": 5, "damage": 15.0, "cooldown": 0.85, "range": 240.0, "orbit_speed": 1.2},  # TUNING (not in GDD) first pass 19 (with the evolution 296k damage in a forced army run)
		],
	},
	# --- Act IV: the Shores of Ilion ---
	# Paris's Arrow (owner-approved Act IV proposal "Rewards": "a spectral arrow
	# that always strikes its target from behind (full damage through phalanx
	# fronts)"; unlocked by slaying Achilles, UnlockData). Every `cooldown` s
	# (start to start) it looses `arrows` violet ghost arrows at the strongest
	# foes (most max HP first: it hunts champions) within `range` px; each
	# swings around its target in `flight` s and strikes it FROM BEHIND (its
	# origin behind the target's facing: CombatResolver.damage_enemy() with
	# that origin, a shot), dealing `damage`: full damage through a locked
	# shield front or a testudo, it breaks the wall it strikes and finds
	# Achilles' back. Stat keys: damage, cooldown (s), arrows, range (px),
	# flight (s). Logic: ParisArrow; fixed rules: ParisArrowData; Mortal Heel
	# (its paired passive) raises every hit from behind, these included.
	"paris_arrow": {
		"display_name": "Paris's Arrow",
		"icon": "paris_arrow",
		"description": "Ghost arrows swing around the strongest foes and strike them from behind.",
		"shared_card_pool": true,  # TUNING (not in GDD) an unlocked Act IV spell: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Arrow damage", "arrows": "Arrows", "cooldown": "Cooldown (s)", "range": "Range"},
		"levels": [
			{"damage": 30.0, "arrows": 1, "cooldown": 2.6, "range": 360.0, "flight": 0.55},  # TUNING (not in GDD) a single-target hunter (the act's champions and fronts)
			{"damage": 36.0, "arrows": 2, "cooldown": 2.6, "range": 370.0, "flight": 0.55},  # TUNING (not in GDD)
			{"damage": 42.0, "arrows": 2, "cooldown": 2.4, "range": 380.0, "flight": 0.5},  # TUNING (not in GDD)
			{"damage": 50.0, "arrows": 3, "cooldown": 2.3, "range": 390.0, "flight": 0.5},  # TUNING (not in GDD)
			{"damage": 58.0, "arrows": 3, "cooldown": 2.1, "range": 400.0, "flight": 0.45},  # TUNING (not in GDD)
		],
	},
	# --- Act IV: Mount Olympus ---
	# Stolen Thunder (owner-approved Act IV proposal "Rewards": "a charged bolt
	# on the strongest enemy that chains to armoured foes"; unlocked by slaying
	# Zeus, UnlockData). Every `cooldown` s the bolt charges `thunder_charge` s
	# over the necromancer, then strikes the foe with the most HP left within
	# `range` px for `damage`, and chains up to `thunder_chains` hops to the
	# nearest ARMOURED foe within `chain_range` px (each hop `chain_falloff`
	# weaker); armoured foes take `armour_bonus` more. Logic: StolenThunder;
	# fixed rules: StolenThunderData; Titan's Blood adds hops and cuts the
	# charge (AbilityManager.apply_spell_mods(): thunder_chains, thunder_charge).
	"stolen_thunder": {
		"display_name": "Stolen Thunder",
		"icon": "stolen_thunder",
		"description": "A charged bolt strikes the strongest foe and leaps on to armoured ones.",
		"shared_card_pool": true,  # TUNING (not in GDD) an unlocked Act IV spell: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Bolt damage", "thunder_chains": "Chain hops", "cooldown": "Bolt every (s)", "armour_bonus": "Bonus vs armour", "range": "Range"},
		"levels": [
			{"damage": 60.0, "cooldown": 3.6, "thunder_charge": 0.8, "range": 420.0, "thunder_chains": 2, "chain_range": 150.0, "chain_falloff": 0.15, "armour_bonus": 0.25},  # TUNING (not in GDD)
			{"damage": 76.0, "cooldown": 3.4, "thunder_charge": 0.8, "range": 430.0, "thunder_chains": 3, "chain_range": 155.0, "chain_falloff": 0.15, "armour_bonus": 0.25},  # TUNING (not in GDD)
			{"damage": 92.0, "cooldown": 3.2, "thunder_charge": 0.75, "range": 440.0, "thunder_chains": 3, "chain_range": 160.0, "chain_falloff": 0.12, "armour_bonus": 0.3},  # TUNING (not in GDD)
			{"damage": 112.0, "cooldown": 3.0, "thunder_charge": 0.7, "range": 450.0, "thunder_chains": 4, "chain_range": 170.0, "chain_falloff": 0.12, "armour_bonus": 0.3},  # TUNING (not in GDD)
			{"damage": 136.0, "cooldown": 2.8, "thunder_charge": 0.65, "range": 460.0, "thunder_chains": 5, "chain_range": 180.0, "chain_falloff": 0.1, "armour_bonus": 0.35},  # TUNING (not in GDD)
		],
	},
	# --- Act IV: the Asphodel Underworld ---
	# River Styx (GDD §15.0 "River Styx, Lethe's Flood, Ferryman's Toll and the
	# Ferrywoman"; owner-approved proposal: "a black river line that drains and
	# slows whatever crosses it"; unlocked by defeating Hades, UnlockData): every
	# `cooldown` s, `rivers` river line(s) `length` px long and 2 x `radius` px
	# wide across the nearest foe's way, flowing `duration` s; every `tick` s each
	# foe in the water takes `damage` and is slowed by `river_slow` for
	# `slow_duration` s; the necromancer heals `drain_share` of it (at most
	# `drain_cap` HP a second). Logic: RiverStyx; fixed rules: RiverStyxData.
	"river_styx": {
		"display_name": "River Styx",
		"icon": "river_styx",
		"description": "A black river opens across your foes' path: it drains and slows whatever crosses it.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Drain per tick", "river_slow": "Slow", "length": "River length", "duration": "Duration (s)", "cooldown": "Cooldown (s)"},
		"levels": [
			{"rivers": 1, "damage": 6.0, "tick": 0.5, "river_slow": 0.30, "slow_duration": 0.8, "length": 170.0, "radius": 16.0, "duration": 4.0, "cooldown": 5.0, "drain_share": 0.04, "drain_cap": 3.0},  # TUNING (not in GDD)
			{"rivers": 1, "damage": 8.0, "tick": 0.5, "river_slow": 0.32, "slow_duration": 0.8, "length": 190.0, "radius": 17.0, "duration": 4.5, "cooldown": 4.8, "drain_share": 0.04, "drain_cap": 3.0},  # TUNING (not in GDD)
			{"rivers": 1, "damage": 9.0, "tick": 0.5, "river_slow": 0.35, "slow_duration": 0.8, "length": 210.0, "radius": 18.0, "duration": 5.0, "cooldown": 4.5, "drain_share": 0.05, "drain_cap": 4.0},  # TUNING (not in GDD)
			{"rivers": 1, "damage": 11.0, "tick": 0.5, "river_slow": 0.38, "slow_duration": 0.8, "length": 230.0, "radius": 19.0, "duration": 5.5, "cooldown": 4.2, "drain_share": 0.05, "drain_cap": 4.0},  # TUNING (not in GDD)
			{"rivers": 1, "damage": 13.0, "tick": 0.5, "river_slow": 0.40, "slow_duration": 0.8, "length": 250.0, "radius": 20.0, "duration": 6.0, "cooldown": 4.0, "drain_share": 0.06, "drain_cap": 5.0},  # TUNING (not in GDD)
		],
	},
	# --- Act V: the Burning Province ---
	# Hundred Shadows (GDD §15.0 "Hundred Shadows, Hidden Hand and the Grave
	# Kunoichi (Act V)"; owner-approved proposal: "shadow clones of the
	# necromancer that echo your next spell cast"; unlocked by slaying Kage,
	# UnlockData): every `cooldown` s, `clones` shadow clones step out around the
	# necromancer for `life` s, each throwing a shadow kunai (`damage`) at the
	# nearest foe within `range` px; each then ECHOES the necromancer's next
	# spell hit with another kunai at that foe (`damage` + `echo_share` x the
	# hit). Stat keys: damage, clones, cooldown (s), life (s), echo_share, range
	# (px). Logic: HundredShadows; fixed rules: HundredShadowsData; Hidden Hand
	# (its paired passive) raises every spell hit on a foe busy with a summon.
	"hundred_shadows": {
		"display_name": "Hundred Shadows",
		"icon": "hundred_shadows",
		"description": "Shadow clones step out of you, throw kunai, then echo your next spell.",
		"shared_card_pool": true,  # TUNING (not in GDD) an unlocked Act V spell: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Kunai damage", "clones": "Clones", "echo_share": "Echo of the spell", "life": "Clone life (s)", "cooldown": "Cooldown (s)"},
		"levels": [
			{"damage": 14.0, "clones": 1, "cooldown": 5.5, "life": 4.0, "echo_share": 0.5, "range": 300.0},  # TUNING (not in GDD)
			{"damage": 17.0, "clones": 2, "cooldown": 5.5, "life": 4.0, "echo_share": 0.5, "range": 310.0},  # TUNING (not in GDD)
			{"damage": 21.0, "clones": 2, "cooldown": 5.0, "life": 4.5, "echo_share": 0.6, "range": 320.0},  # TUNING (not in GDD)
			{"damage": 25.0, "clones": 3, "cooldown": 4.8, "life": 4.5, "echo_share": 0.6, "range": 330.0},  # TUNING (not in GDD)
			{"damage": 30.0, "clones": 3, "cooldown": 4.5, "life": 5.0, "echo_share": 0.7, "range": 340.0},  # TUNING (not in GDD)
		],
	},
	# --- Act V: the Road to the Sun ---
	# Black Sun (GDD §15.0 "Black Sun, Eclipse of Heaven, Stolen Dawn and the
	# Shrine Maiden of Night"; owner-approved proposal: "a dark sun orbits the
	# necromancer and fires a short beam at the nearest group"; unlocked by
	# defeating Amaterasu, UnlockData): `suns` dark sun(s) orbit him
	# (BlackSunData.ORBIT_RADIUS px); every `cooldown` s each fires a beam
	# `sun_reach` px long and `sun_width` px wide at the nearest group of foes
	# (the nearest foe within BlackSunData.AIM_RANGE and the foes within
	# `group_radius` px of it), hitting every foe on it for `damage`. Logic:
	# BlackSun; fixed rules: BlackSunData. (Its own keys, not the Death Ray's
	# beam_length / beam_width: Conductive Marrow stays the Death Ray's.)
	"black_sun": {
		"display_name": "Black Sun",
		"icon": "black_sun",
		"description": "A dark sun orbits you and burns a short beam through the nearest group of foes.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Beam damage", "sun_reach": "Beam reach", "cooldown": "Cooldown (s)"},
		"levels": [
			{"suns": 1, "damage": 12.0, "cooldown": 1.8, "sun_reach": 160.0, "sun_width": 14.0, "group_radius": 60.0},  # TUNING (not in GDD)
			{"suns": 1, "damage": 15.0, "cooldown": 1.7, "sun_reach": 170.0, "sun_width": 15.0, "group_radius": 60.0},  # TUNING (not in GDD)
			{"suns": 1, "damage": 17.0, "cooldown": 1.55, "sun_reach": 180.0, "sun_width": 16.0, "group_radius": 64.0},  # TUNING (not in GDD)
			{"suns": 1, "damage": 20.0, "cooldown": 1.45, "sun_reach": 190.0, "sun_width": 17.0, "group_radius": 64.0},  # TUNING (not in GDD)
			{"suns": 1, "damage": 23.0, "cooldown": 1.3, "sun_reach": 200.0, "sun_width": 18.0, "group_radius": 68.0},  # TUNING (not in GDD)
		],
	},
	# --- Act V: Castle Kurogane ---
	# Banner of the Dead (owner-approved Act V proposal "Rewards": "a war banner
	# planted where you stand; summons near it attack faster"; unlocked by
	# slaying Shogun Kurogane, UnlockData). Every `cooldown` s it plants a war
	# banner where the necromancer stands: the planting strikes every foe within
	# `pulse_radius` px for `damage`; the banner stands `duration` s (at most
	# `banners` at once) and every summon of his within `radius` px of it
	# attacks `haste` faster (HordeDirector.attack_haste(), the one read; the
	# same on every stage). Logic: BannerOfTheDead; fixed rules: BannerData.
	"banner_of_the_dead": {
		"display_name": "Banner of the Dead",
		"icon": "banner_of_the_dead",
		"description": "Plant a war banner where you stand: your dead near it attack faster.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"haste": "Attack speed near it", "radius": "Banner reach", "banners": "Banners", "duration": "Duration (s)", "cooldown": "Cooldown (s)"},
		"levels": [
			{"damage": 20.0, "pulse_radius": 70.0, "haste": 0.20, "radius": 110.0, "banners": 1, "duration": 7.0, "cooldown": 9.0},  # TUNING (not in GDD) a support spell: the haste is its worth
			{"damage": 26.0, "pulse_radius": 74.0, "haste": 0.25, "radius": 120.0, "banners": 1, "duration": 7.5, "cooldown": 8.5},  # TUNING (not in GDD)
			{"damage": 32.0, "pulse_radius": 78.0, "haste": 0.30, "radius": 130.0, "banners": 2, "duration": 8.0, "cooldown": 8.0},  # TUNING (not in GDD)
			{"damage": 40.0, "pulse_radius": 82.0, "haste": 0.35, "radius": 140.0, "banners": 2, "duration": 8.5, "cooldown": 7.5},  # TUNING (not in GDD)
			{"damage": 48.0, "pulse_radius": 86.0, "haste": 0.40, "radius": 150.0, "banners": 2, "duration": 9.0, "cooldown": 7.0},  # TUNING (not in GDD)
		],
	},
	# --- Act VI: the Burning Gate ---
	# Brimstone (GDD §15.0 "Brimstone, Rain of Fire, Furnace Heart and the
	# Furnace Priest (Act VI)"; owner-approved proposal: "burning stones fall on
	# the densest group and leave a short pit"; unlocked by slaying Moloch,
	# UnlockData): every `cooldown` s, `stones` stones fall on the densest groups
	# within `range` px, `damage` to every foe within `radius` px, then a pit of
	# `pit_radius` px burns foes only for `pit_life` s at `pit_share` x the
	# damage per s. Stat keys: damage, stones, radius (px), pit_radius (px),
	# pit_life (s), pit_share, cooldown (s), range (px). Logic: Brimstone; fixed
	# rules: BrimstoneData; Furnace Heart (its paired passive) raises every spell
	# hit on a foe standing in fire.
	"brimstone": {
		"display_name": "Brimstone",  # Owner-approved proposal
		"icon": "brimstone",
		"description": "Burning stones fall on the thickest crowd and leave fire where they land.",
		"shared_card_pool": true,  # TUNING (not in GDD) an unlocked Act VI spell: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Stone damage", "stones": "Stones", "radius": "Blast radius", "pit_share": "Fire per second", "pit_life": "Fire lasts (s)", "cooldown": "Cooldown (s)"},
		"levels": [
			{"damage": 20.0, "stones": 1, "radius": 34.0, "pit_radius": 26.0, "pit_life": 1.6, "pit_share": 0.25, "cooldown": 3.0, "range": 340.0},  # TUNING (not in GDD)
			{"damage": 24.0, "stones": 2, "radius": 34.0, "pit_radius": 26.0, "pit_life": 1.8, "pit_share": 0.25, "cooldown": 3.0, "range": 340.0},  # TUNING (not in GDD)
			{"damage": 28.0, "stones": 2, "radius": 38.0, "pit_radius": 30.0, "pit_life": 2.2, "pit_share": 0.3, "cooldown": 2.8, "range": 350.0},  # TUNING (not in GDD)
			{"damage": 33.0, "stones": 3, "radius": 38.0, "pit_radius": 30.0, "pit_life": 2.4, "pit_share": 0.3, "cooldown": 2.7, "range": 350.0},  # TUNING (not in GDD)
			{"damage": 40.0, "stones": 3, "radius": 42.0, "pit_radius": 34.0, "pit_life": 2.8, "pit_share": 0.35, "cooldown": 2.5, "range": 360.0},  # TUNING (not in GDD)
		],
	},
	# --- Act VI: the Palace of Silk and Ash ---
	# Temptation (id "tempt": the Inferno's rule is Temptation and no spell id may
	# meet a kind; GDD §15.0 "Temptation, Unholy Desire, Velvet Chains and the
	# Succubus Queen"; owner-approved proposal: "charm the strongest nearby enemy
	# to fight for you for 6 s"; unlocked by slaying Lilith, UnlockData): every
	# `cooldown` s the `charms` strongest foes (most HP) within `range` px are
	# charmed for `charm_time` s through the Enthrall path (never a boss,
	# miniboss or structure), each fighting for you hitting for `damage`, then
	# going back to its side. Logic: TemptSpell, Enthrall; fixed rules: TemptData.
	"tempt": {
		"display_name": "Temptation",  # Owner-approved proposal
		"icon": "tempt",
		"description": "Charm the strongest foe near you: it fights for you for a while.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"charms": "Foes charmed", "charm_time": "Charm (s)", "damage": "Thrall hit", "range": "Reach", "cooldown": "Cooldown (s)"},
		"levels": [
			{"charms": 1, "charm_time": 6.0, "damage": 14.0, "range": 220.0, "cooldown": 7.0},  # Owner-approved proposal: the 6 s; the rest TUNING (not in GDD)
			{"charms": 1, "charm_time": 6.0, "damage": 17.0, "range": 230.0, "cooldown": 6.5},  # TUNING (not in GDD)
			{"charms": 1, "charm_time": 6.5, "damage": 20.0, "range": 240.0, "cooldown": 6.0},  # TUNING (not in GDD)
			{"charms": 2, "charm_time": 6.5, "damage": 22.0, "range": 250.0, "cooldown": 6.0},  # TUNING (not in GDD)
			{"charms": 2, "charm_time": 7.0, "damage": 25.0, "range": 260.0, "cooldown": 5.5},  # TUNING (not in GDD)
		],
	},
	# --- Act VI: Pandemonium ---
	# Fall from Grace (GDD §15.0 "Fall from Grace, Lightbringer, Pride and the
	# Fallen Saint"; owner-approved proposal: "a fallen star crashes on the
	# strongest enemy"; unlocked by defeating the Morning Star, UnlockData):
	# every `cooldown` s `stars` star(s) (1 before the evolution) fall for
	# `fall_time` s on the strongest foes within FallFromGraceData.AIM_RANGE px
	# (the most HP left) and crash: `damage` to the target, `splash` x that to
	# every other foe within `radius` px (Necrotic Expanse widens it, like every
	# spell radius). Logic: FallFromGrace; fixed rules: FallFromGraceData.
	# A single-target spell: the tall foe it finds is what spell-only builds
	# lacked (CLAUDE.md "Next" 7).
	"fall_from_grace": {
		"display_name": "Fall from Grace",
		"icon": "fall_from_grace",
		"description": "A fallen star crashes down on the strongest foe near you.",
		"shared_card_pool": true,  # TUNING (not in GDD) a later item: its NEW card weighs LevelUpData.WEIGHT_NEW_LATER
		"labels": {"damage": "Star damage", "radius": "Crash radius", "splash": "Splash", "cooldown": "Cooldown (s)"},
		"levels": [
			{"damage": 36.0, "radius": 40.0, "splash": 0.4, "fall_time": 0.6, "cooldown": 3.2},  # TUNING (not in GDD) a heavy single blow (first pass 46-106 at Lv 1-5: Lightbringer led every source by 4x in the agent run)
			{"damage": 44.0, "radius": 42.0, "splash": 0.4, "fall_time": 0.6, "cooldown": 3.0},  # TUNING (not in GDD)
			{"damage": 54.0, "radius": 44.0, "splash": 0.45, "fall_time": 0.55, "cooldown": 2.8},  # TUNING (not in GDD)
			{"damage": 66.0, "radius": 46.0, "splash": 0.45, "fall_time": 0.55, "cooldown": 2.6},  # TUNING (not in GDD)
			{"damage": 80.0, "radius": 48.0, "splash": 0.5, "fall_time": 0.5, "cooldown": 2.4},  # TUNING (not in GDD)
		],
	},
}

## Stat keys shown as a percentage on cards (fractions: 0.25 -> 25%).
const PERCENT_KEYS := ["lifesteal", "rot", "burst", "zone_damage", "zone_slow", "nova", "nova_rot_bonus",
	"falloff", "shred", "skeleton_hp", "skeleton_damage",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"thrall_hp", "thrall_damage",
	# --- Act III: the Assembly Halls ---
	"puppet_hp",
	# --- Act III: the Scrap Wastes ---
	"spark",
	# --- Act IV: Mount Olympus ---
	"armour_bonus", "chain_falloff", "clap_share",
	# --- Act IV: the Asphodel Underworld ---
	"river_slow", "drain_share",
	# --- Act V: the Burning Province ---
	"echo_share", "burst_share",
	# --- Act V: Castle Kurogane ---
	"haste",
	# --- Act VI: the Burning Gate ---
	"pit_share",
	# --- Act VI: Pandemonium ---
	"splash", "flare"]
## Stat keys that are spell durations (s): the Lingering Malediction passive
## lengthens them (AbilityManager.apply_spell_mods()).
const DURATION_KEYS := ["duration", "zone_duration", "slow_duration"]
## Multiplier on every spell's and spell evolution's `damage` / `pulse_damage`
## (and so on the hits defined as fractions of them: split arrows, second
## hits, spike fields), applied in AbilityManager.apply_spell_mods() with Soul
## Conduit and the Ossuary, so the level-up cards show the real numbers.
## Owner balance pass (Oct 2026 playtest): raise the necromancer's own
## damage "in general" instead of a hidden multiplier on every damage source.
const SPELL_DAMAGE_MULT: float = 1.2  # TUNING (not in GDD) owner balance pass

## Shadow Bolt: score bonus (px-equivalent) for enemies currently attacking a
## summon, so bolts "preferentially hit enemies threatening warriors" (GDD §33).
const BOLT_PROTECT_BONUS: float = 80.0  # TUNING (not in GDD)
## Shadow Bolt homing turn rate (radians/s) toward its target.
const BOLT_HOMING: float = 5.0  # TUNING (not in GDD)
## Radius (px) of a single orb's body / hit circle.
const ORB_RADIUS: float = 7.0  # TUNING (not in GDD)

# --- Bone Spear / Ossuary Lance (BoneSpear) ----------------------------------------

## Angle (radians) between neighbouring spears of one volley.
const SPEAR_SPREAD: float = 0.14  # TUNING (not in GDD)
## Hit radius (px) of a Bone Spear (Ossuary Lance uses its "width" stat).
const SPEAR_RADIUS: float = 5.0  # TUNING (not in GDD)
## Most spears / lances in flight at once (new ones are skipped beyond it).
const SPEAR_MAX: int = 60  # TUNING (not in GDD)
## A volley is only thrown while an enemy is within this many px (else the
## spell retries every SPELL_RETRY s instead of wasting its cooldown).
const SPEAR_TRIGGER_RANGE: float = 420.0  # TUNING (not in GDD)
## Aim assist half-angle (radians) around the walking direction: the volley
## flies at the nearest enemy inside this cone, else at the nearest enemy
## (pure movement aim dealt almost nothing while kiting).
const SPEAR_AIM_CONE: float = 0.6  # TUNING (not in GDD)

# --- Soul Siphon / Soul Rapture (SoulSiphon) ---------------------------------------

## A tether breaks once its enemy is this many px beyond the spell range.
const SIPHON_LEASH: float = 40.0  # TUNING (not in GDD)
## Seconds of heal_cap the lifesteal budget can bank (the cap is per second,
## so a full budget allows at most heal_cap * this HP in one pulse).
const SIPHON_BUDGET_SECONDS: float = 1.0  # TUNING (not in GDD)

# --- Corpse Explosion / Grave Eruption (CorpseExplosion) ---------------------------

## Seconds a corpse stays usable after its enemy died.
const CORPSE_LIFE: float = 8.0  # TUNING (not in GDD)
## Corpses remembered at once (ring buffer; the oldest is overwritten).
const CORPSE_MAX: int = 64  # TUNING (not in GDD)
## Seconds between Grave Eruption spike-field damage ticks.
const ZONE_TICK: float = 0.5  # TUNING (not in GDD)
## Most Grave Eruption spike fields at once (the oldest is replaced).
const ZONE_MAX: int = 10  # TUNING (not in GDD)

# --- Plague Cloud / Pestilence (PlagueCloud) ---------------------------------------

## Seconds between plague damage ticks of one cloud.
const PLAGUE_TICK: float = 0.5  # TUNING (not in GDD)
## Seconds Rot lingers on an enemy after its last plague tick.
const ROT_LINGER: float = 1.5  # TUNING (not in GDD)
## Fraction of the Rot bonus that applies to bosses (Sir Alaric).
const ROT_BOSS_MULT: float = 0.5  # TUNING (not in GDD)
## Most clouds at once (the oldest is replaced).
const CLOUD_MAX: int = 12  # TUNING (not in GDD)
## Pestilence Death Nova radius as a multiple of the cloud radius.
const NOVA_RADIUS_MULT: float = 1.5  # TUNING (not in GDD)

# --- Shared by the four spells above -----------------------------------------------

## Seconds before a spell that found nothing to do tries again (its cooldown
## is not spent on an empty cast).
const SPELL_RETRY: float = 0.25  # TUNING (not in GDD)
