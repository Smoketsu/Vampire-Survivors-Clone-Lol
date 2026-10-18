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
	"forbidden_verse"]

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
}

## Stat keys shown as a percentage on cards (fractions: 0.25 -> 25%).
const PERCENT_KEYS := ["lifesteal", "rot", "burst", "zone_damage", "zone_slow", "nova", "nova_rot_bonus",
	"falloff", "shred", "skeleton_hp", "skeleton_damage"]
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
