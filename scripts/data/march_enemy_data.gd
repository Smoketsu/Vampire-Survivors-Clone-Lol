## MarchEnemyData — immutable design data for the Crimson March (GDD §8.2):
## the new Covenant soldiers (GDD §7.2 roster), the stage's destructible
## structures (GDD §7.4 outposts, Holy Ward Generators, supply carts) and
## Marshal Vael, the Crimson Bulwark (GDD §7.5). EnemyDirector.enemy_def()
## looks kinds up in EnemyData.ENEMIES first, then in ENEMIES here.
##
## Every row has all the keys of an EnemyData.ENEMIES row (same meaning).
## Optional keys read by Enemy.activate() (absent = off):
##   projectile_resist   — fraction (0..1) of damage ignored from projectile
##                         sources (PROJECTILE_SOURCES): a tower shield.
##   aura_radius         — px; this unit buffs every OTHER Covenant soldier
##                         (and the boss) inside it (Banner Bearer, Holy
##                         Standard). Buffs last AURA_LINGER s after leaving.
##   aura_damage_mult / aura_speed_mult / aura_taken_mult — the buff: damage
##                         dealt, move speed and damage taken multipliers.
##   cleave_radius / cleave_targets / cleave_mult — a melee hit on a summon
##                         also hits up to cleave_targets OTHER summons within
##                         cleave_radius px of it for cleave_mult of the damage.
##   is_structure        — true for buildings and carts: never recycled, no
##                         target picking, no separation steering; a Soul Nova
##                         treats them like elites (50% of current HP).
## The GDD gives no numbers: everything is TUNING (not in GDD); the behaviour
## each number expresses is cited.
class_name MarchEnemyData
extends RefCounted

## Display / iteration order of the new regular soldier kinds.
const ORDER := ["shieldbearer", "banner_bearer", "halberdier"]

## Damage sources (CombatResolver `source` tags) that count as projectiles
## for a tower shield: Shadow Bolt, Void Barrage bolts and shards, Bone Spear
## and Ossuary Lance, skeletal arrows, mage and Lich blasts, Frost Wraith
## frost bolts and the support classes' bolts (Mender, Warder, Bishop).
## Area spells (Shadow Blast, Corpse Explosion / Grave Eruption, Plague Cloud
## / Pestilence, Soul Siphon tethers and Soul Rapture bursts, Orb Shield) are
## not projectiles and go through a tower shield.
const PROJECTILE_SOURCES := ["bolt", "void", "void_shard", "spear", "lance",
	"archer", "mage", "lich", "frost_wraith", "mender", "warder", "bishop"]
## Damage sources that reach AROUND a shield (melee at close range); used by
## Marshal Vael's Shieldwall, which blocks everything else from the front:
## Skeleton Warrior strikes and bashes (temporary and Lich-risen skeletons
## included), the Death Knight's strike, bash and cleave, the Abomination's
## fists and stomp, the Rogue's stab, dash and bleed, the Gargoyle's claws
## and swoop (and the same strikes of their Shadow Reaper / Cathedral
## Horror evolutions), and the Profane Bishop's aura pulse (it surrounds the Bishop,
## so it reaches behind a shield like a blade at close range).
const MELEE_SOURCES := ["warrior", "bash", "lich_risen",
	"death_knight", "death_knight_bash", "death_knight_cleave",
	"abomination", "abom_stomp", "rogue", "rogue_dash", "rogue_bleed",
	"gargoyle", "gargoyle_swoop", "bishop_aura",
	"shadow_reaper", "cathedral_horror"]
## Seconds an aura buff (Banner Bearer, Holy Standard) lingers on a soldier
## after it leaves the aura (auras refresh at the 5 Hz think rate).
const AURA_LINGER: float = 0.6  # TUNING (not in GDD)

## The Crimson March's soldiers and structures (keys: see the header).
const ENEMIES := {
	# GDD §8.2 "Fortified checkpoint" / §7.3 "infantry protect archers and
	# priests in advancing formations": heavy infantry with a tower shield.
	# Counterplay: warriors and bashes, Shadow Blast, orbs (not projectiles).
	"shieldbearer": {
		"display_name": "Covenant Shieldbearer",
		"max_hp": 52.0,  # TUNING (not in GDD)
		"move_speed": 46.0,  # TUNING (not in GDD)
		"damage": 5.0,  # TUNING (not in GDD)
		"attack_interval": 1.2,  # TUNING (not in GDD)
		"attack_range": 5.0,  # TUNING (not in GDD)
		"radius": 12.0,  # TUNING (not in GDD)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.35,  # TUNING (not in GDD)
		"mass": 2.6,  # TUNING (not in GDD) leans on blocking warriors
		"projectile_resist": 0.6,  # TUNING (not in GDD) tower shield vs bolts and arrows
	},
	# GDD §7.2 "Banner Bearer: buffs nearby Covenant soldiers; elevated target
	# priority"; §7.3 "banners buff formations until destroyed". Advances
	# like a Chaplain (never kites), weak swing if cornered.
	"banner_bearer": {
		"display_name": "Banner Bearer",
		"max_hp": 40.0,  # TUNING (not in GDD)
		"move_speed": 50.0,  # TUNING (not in GDD)
		"damage": 2.0,  # TUNING (not in GDD)
		"attack_interval": 1.4,  # TUNING (not in GDD)
		"attack_range": 4.0,  # TUNING (not in GDD)
		"radius": 11.0,  # TUNING (not in GDD)
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "banner",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # GDD §7.2 "elevated target priority"
		"mass": 1.2,  # TUNING (not in GDD)
		"aura_radius": 110.0,  # TUNING (not in GDD)
		"aura_damage_mult": 1.15,  # TUNING (not in GDD)
		"aura_speed_mult": 1.15,  # TUNING (not in GDD)
		"aura_taken_mult": 0.9,  # TUNING (not in GDD)
	},
	# GDD §8.2 "12:00 Heavy infantry": slow, armoured halberdier whose sweeps
	# cleave packed summons. Counterplay: spread / heal the front line, kite
	# it (it is slow), focus it with spells.
	"halberdier": {
		"display_name": "Crimson Halberdier",
		"max_hp": 85.0,  # TUNING (not in GDD)
		"move_speed": 42.0,  # TUNING (not in GDD)
		"damage": 8.0,  # TUNING (not in GDD)
		"attack_interval": 1.5,  # TUNING (not in GDD)
		"attack_range": 12.0,  # TUNING (not in GDD) halberd reach
		"radius": 13.0,  # TUNING (not in GDD)
		"armor": 0.35,  # TUNING (not in GDD) heavy armour
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.45,  # TUNING (not in GDD)
		"mass": 3.2,  # TUNING (not in GDD) heavy: shoves warriors
		"cleave_radius": 34.0,  # TUNING (not in GDD)
		"cleave_targets": 2,  # TUNING (not in GDD)
		"cleave_mult": 0.4,  # TUNING (not in GDD)
	},
	# GDD §8.2 "04:00 Fortified checkpoint": a watchtower that sends recruits
	# and archers until it falls (MarchDirector "outposts" event).
	"watchtower": {
		"display_name": "Checkpoint Watchtower",
		"max_hp": 380.0,  # TUNING (not in GDD)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 20.0,  # TUNING (not in GDD)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is MarchDirector's XP burst.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) the army goes for it
		"mass": 60.0,  # Immovable.
		"is_structure": true,
	},
	# GDD §7.4 / §8.2 "outposts spawn reinforcements until destroyed".
	"outpost": {
		"display_name": "Siege Outpost",
		"max_hp": 700.0,  # TUNING (not in GDD)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 24.0,  # TUNING (not in GDD)
		"armor": 0.25,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is MarchDirector's XP burst.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD)
		"mass": 60.0,  # Immovable.
		"is_structure": true,
	},
	# GDD §7.4 / §8.2 "Holy Ward Generators damage/weaken summons in areas":
	# the centre of a holy zone that lasts until it is destroyed.
	"ward_generator": {
		"display_name": "Holy Ward Generator",
		"max_hp": 900.0,  # TUNING (not in GDD)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 18.0,  # TUNING (not in GDD)
		"armor": 0.3,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is MarchDirector's XP burst.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) top priority for the army
		"mass": 60.0,  # Immovable.
		"is_structure": true,
	},
	# GDD §7.4 / §8.2 "Destroy enemy supply carts for optional rewards": rolls
	# past along a straight line and escapes when its time is up.
	"supply_cart": {
		"display_name": "Supply Cart",
		"max_hp": 240.0,  # TUNING (not in GDD)
		"move_speed": 26.0,  # TUNING (not in GDD) slow enough to catch
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 16.0,  # TUNING (not in GDD)
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is MarchDirector's XP burst and power-up.
		"behavior": "cart",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD)
		"mass": 6.0,  # TUNING (not in GDD) warriors can hold it but not move it much
		"is_structure": true,
	},
	# Marshal Vael's Holy Standard (GDD §7.5 "Holy Standard: buff zone"): a
	# planted war banner whose aura buffs the Covenant until it falls or its
	# time runs out. Counterplay: destroy it, or pull Vael away from it.
	"holy_standard": {
		"display_name": "Holy Standard",
		"max_hp": 420.0,  # TUNING (not in GDD)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 12.0,  # TUNING (not in GDD)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) archers / mages focus it
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"aura_radius": 150.0,  # TUNING (not in GDD)
		"aura_damage_mult": 1.3,  # TUNING (not in GDD)
		"aura_speed_mult": 1.2,  # TUNING (not in GDD)
		"aura_taken_mult": 0.85,  # TUNING (not in GDD)
	},
}

## Marshal Vael, the Crimson Bulwark (GDD §7.5): "Shield and flaming holy
## sword" with five abilities, all telegraphed (GDD §10.5 "Clear AoE
## telegraphs"). Undead body-block his blows (GDD §15.0). Same base keys as
## EnemyData.BOSS (max_hp ... recover_time, reward_xp / reward_crystals,
## slow_resist, attack_gap, first_special); each special NAME in SPECIALS has
## NAME_weight and NAME_cooldown.
##   Last Stand (GDD §7.5 "attack speed boost below 30% HP"):
##     last_stand_hp_fraction — below this HP fraction it starts.
##     last_stand_attack_mult — multiplier on his melee attack interval.
##     last_stand_gap_mult    — multiplier on the gap between specials.
##     last_stand_telegraph_mult — multiplier on every special's windup.
##     last_stand_banner      — HUD banner (he also casts Crusader's Command
##                              as his next special).
##   Radiant Cleave (GDD §7.5 "sweeping melee"): a flaming arc in front of him.
##     cleave_radius / cleave_half_angle — sector radius (px) and half-angle
##                              (rad) toward the necromancer.
##     cleave_telegraph       — s the gold sector is shown before the sweep.
##     cleave_max_range       — px; only used on a necromancer this close.
##     cleave_damage_player / cleave_damage_summon — damage on the sweep.
##     cleave_soak_per_unit / cleave_soak_max — fraction of the necromancer's
##                              damage each summon in the sector absorbs
##                              (body-blocking), and its cap.
##   Crusader's Command (GDD §7.5 "infantry formation waves"):
##     command_telegraph      — s the rally banners stand before the line forms.
##     command_groups         — list of {kind, count} soldiers in the line.
##     command_distance       — px from the necromancer, on Vael's side.
##     command_spacing        — px between soldiers in the line.
##   Holy Standard (GDD §7.5 "buff zone"):
##     standard_kind          — MarchEnemyData kind planted (aura in its row).
##     standard_telegraph     — s the banner mark is shown before it stands.
##     standard_duration      — s it stands before it is struck (if not destroyed).
##     standard_offset        — px from Vael, toward the necromancer.
##   Shieldwall (GDD §7.5 "high frontal damage resistance"): a stance.
##     shieldwall_duration    — s the shield stays raised.
##     shieldwall_taken_mult  — damage multiplier from the front: every source
##                              except MELEE_SOURCES (spells and projectiles
##                              come from the necromancer's side; blades at
##                              close range reach around the shield).
##     shieldwall_speed_mult  — his move speed while the shield is raised.
##     shieldwall_min_range / shieldwall_max_range — px; raised only while the
##                              necromancer is this far (he is being shot at).
##   Forced march (no GDD ability; Alaric has Divine Charge to close in):
##     advance_range          — px; farther than this from the necromancer he
##                              strides faster (shield lowered or not).
##     advance_speed_mult     — his move-speed multiplier while striding.
const VAEL := {
	"display_name": "Marshal Vael, the Crimson Bulwark",  # GDD §7.5
	"max_hp": 32000.0,  # TUNING (not in GDD) x1.1 stage HP = 35,200; Shieldwall, the Holy Standard and Last Stand make him tougher than his HP says
	"move_speed": 50.0,  # TUNING (not in GDD)
	"damage": 14.0,  # TUNING (not in GDD) flaming sword swing
	"attack_interval": 1.1,  # TUNING (not in GDD)
	"attack_range": 9.0,  # TUNING (not in GDD)
	"radius": 23.0,  # TUNING (not in GDD)
	"armor": 0.2,  # TUNING (not in GDD)
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 12.0,  # TUNING (not in GDD) shoves warriors aside
	"reward_xp": 450,  # TUNING (not in GDD)
	"reward_crystals": 22,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD)
	"attack_gap": 2.4,  # TUNING (not in GDD)
	"first_special": 2.0,  # TUNING (not in GDD)
	"recover_time": 0.8,  # TUNING (not in GDD)
	# Last Stand.
	"last_stand_hp_fraction": 0.3,  # GDD §7.5 "below 30% HP"
	"last_stand_attack_mult": 0.6,  # TUNING (not in GDD) GDD "attack speed boost"
	"last_stand_gap_mult": 0.6,  # TUNING (not in GDD)
	"last_stand_telegraph_mult": 0.8,  # TUNING (not in GDD) still readable
	"last_stand_banner": "Marshal Vael makes his Last Stand!",  # TUNING (not in GDD)
	# Radiant Cleave.
	"cleave_weight": 1.0,  # TUNING (not in GDD)
	"cleave_cooldown": 5.0,  # TUNING (not in GDD)
	"cleave_radius": 120.0,  # TUNING (not in GDD)
	"cleave_half_angle": 1.0,  # TUNING (not in GDD) ~115 degree sweep
	"cleave_telegraph": 1.0,  # TUNING (not in GDD)
	"cleave_max_range": 150.0,  # TUNING (not in GDD)
	"cleave_damage_player": 30.0,  # TUNING (not in GDD)
	"cleave_damage_summon": 16.0,  # TUNING (not in GDD)
	"cleave_soak_per_unit": 0.15,  # TUNING (not in GDD) body-blocking
	"cleave_soak_max": 0.75,  # TUNING (not in GDD)
	# Crusader's Command.
	"command_weight": 1.0,  # TUNING (not in GDD)
	"command_cooldown": 24.0,  # TUNING (not in GDD)
	"command_telegraph": 1.5,  # TUNING (not in GDD)
	"command_groups": [{"kind": "footman", "count": 3}, {"kind": "shieldbearer", "count": 3}, {"kind": "archer", "count": 2}],  # TUNING (not in GDD)
	"command_distance": 230.0,  # TUNING (not in GDD)
	"command_spacing": 26.0,  # TUNING (not in GDD)
	# Holy Standard.
	"standard_weight": 1.0,  # TUNING (not in GDD)
	"standard_cooldown": 24.0,  # TUNING (not in GDD)
	"standard_kind": "holy_standard",
	"standard_telegraph": 1.0,  # TUNING (not in GDD)
	"standard_duration": 15.0,  # TUNING (not in GDD)
	"standard_offset": 40.0,  # TUNING (not in GDD)
	# Shieldwall.
	"shieldwall_weight": 1.0,  # TUNING (not in GDD)
	"shieldwall_cooldown": 16.0,  # TUNING (not in GDD)
	"shieldwall_duration": 4.0,  # TUNING (not in GDD)
	"shieldwall_taken_mult": 0.5,  # TUNING (not in GDD) "high frontal damage resistance"
	"shieldwall_speed_mult": 0.55,  # TUNING (not in GDD)
	"shieldwall_min_range": 60.0,  # TUNING (not in GDD)
	"shieldwall_max_range": 300.0,  # TUNING (not in GDD) only while he is within reach of the fight
	# Forced march (TUNING, not in GDD): Sir Alaric closes gaps with Divine
	# Charge; Vael has no dash, so he strides faster while far from the
	# necromancer (still slower than him: kiting stays possible).
	"advance_range": 220.0,  # TUNING (not in GDD) px
	"advance_speed_mult": 1.8,  # TUNING (not in GDD) 50 -> 90 px/s (the necromancer runs at 110)
}

## Marshal Vael's special ability ids (GDD §7.5), in HUD / report order
## (Last Stand is a phase, not a special).
const VAEL_SPECIALS := ["cleave", "command", "standard", "shieldwall"]
