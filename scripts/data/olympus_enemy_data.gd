## OlympusEnemyData — immutable design data for the Olympian Republic kinds that
## join on Mount Olympus (Stage 11) (Act IV; GDD §15.0 "Act IV foundation
## (phase 1)" and "Mount Olympus (Act IV phase 2)"): the Pantheon Trial's gods
## and their kinds.
##   centaur_archer — Centaur Archer (ranged, male): a bronze-armoured centaur
##                    that fires while galloping straight at you (never kites;
##                    CentaurKit). BRONZE (Zeus's lightning chains to it).
##   amazon         — Amazon (elite, female, figure-redesign style): axe and
##                    crescent shield; LEAPS over the ring's first row onto the
##                    necromancer (a telegraphed landing circle); a heavy
##                    blocker under her landing catches and stuns her
##                    (AmazonKit). BRONZE.
##   gorgon         — Gorgon (elite, female, figure-redesign style): a snake-
##                    haired woman with a serpent tail; a telegraphed petrifying
##                    GAZE cone: summons in it turn to stone for 3 s through the
##                    one stun path for summons, the necromancer is hurt
##                    (GorgonKit).
##   moon_hound     — Hound of Artemis (fodder, the goddess's pack): a lean
##                    silver hunting hound, fast. FODDER (MoonHoundKit).
##   sea_serpent    — Sea Serpent (heavy, Poseidon's): a great Aegean sea snake
##                    that lunges along a telegraphed line (SeaSerpentKit).
##   ares / artemis / poseidon — the first three gods of the PANTHEON TRIAL
##                    (minibosses, one at a time on the HUD's miniboss bar, each
##                    about a third of Zeus's HP with the boss's HP scaling and
##                    a chest when slain): AresKit, ArtemisKit, PoseidonKit.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.pantheon_def() looks these rows up after
## PantheonEnemyData. Rows have every key of a PantheonEnemyData.ENEMIES row
## (same meaning; "kit" ids load scripts/enemies/pantheon/<kit>_kit.gd, unique
## across the Eye, Empire and Pantheon folders; "bronze", "phalanx", "hero",
## "fodder" switch the shared rules on for the kind) plus their kit's numbers
## (documented on each row). Gods also carry:
##   god_hp_share    — share of ZeusData.MAX_HP their max HP is set to on
##                     arrival, x the boss HP multipliers (difficulty, Hyper,
##                     the stage), never the time scaling (GodKit).
##   reward_xp / reward_crystals — the XP burst on death (like the Trojan Horse).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked
## as the owner-approved proposal.
class_name OlympusEnemyData
extends RefCounted

## Kind id of the Centaur Archer.
const CENTAUR: String = "centaur_archer"
## Kind id of the Amazon.
const AMAZON: String = "amazon"
## Kind id of the Gorgon.
const GORGON: String = "gorgon"
## Kind id of Artemis's hunting hounds.
const HOUND: String = "moon_hound"
## Kind id of Poseidon's sea serpent.
const SERPENT: String = "sea_serpent"
## Kind ids of the trial's gods, in their order of arrival.
const GODS: Array[String] = ["ares", "artemis", "poseidon"]

## Kind id -> design row.
const ENEMIES := {
	# Ranged (male): a centaur with a bronze cuirass and helmet, a short bow, a
	# brown horse body. Fires while galloping toward you; never kites.
	"centaur_archer": {
		"display_name": "Centaur Archer",
		"max_hp": 46.0,  # TUNING (not in GDD) a big body (Hoplite 34)
		"move_speed": 74.0,  # TUNING (not in GDD) px/s; a gallop (Hoplite 42)
		"damage": 4.5,  # TUNING (not in GDD) per arrow, before the time scaling
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 250.0,  # TUNING (not in GDD) px
		"radius": 13.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 3,  # TUNING (not in GDD)
		"behavior": "ranged",  # The shared ranged AI: always advances on the necromancer.
		"projectile_speed": 300.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.6,  # TUNING (not in GDD) 0..1; kill it on approach
		"mass": 2.4,  # TUNING (not in GDD) a horse's weight
		"faction": PantheonEnemyData.FACTION,
		"kit": "centaur",
		"bronze": true,  # Bronze cuirass: Zeus's lightning chains to it.
		"gallop_fire": true,  # CentaurKit: no slow-down while it shoots (owner-approved "fires while galloping toward you").
	},
	# Elite (female, figure-redesign style): bronze breastplate and war skirt,
	# a crested helmet over long hair, a double axe and a crescent (pelta)
	# shield. Leaps over the ring's first row.
	"amazon": {
		"display_name": "Amazon",
		"max_hp": 150.0,  # TUNING (not in GDD) an elite (Hero 280, Valkyrie Duelist 130)
		"move_speed": 62.0,  # TUNING (not in GDD) px/s
		"damage": 10.0,  # TUNING (not in GDD) an axe blow, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 12.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 14,  # TUNING (not in GDD) an elite's XP
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD)
		"mass": 2.0,  # TUNING (not in GDD)
		"faction": PantheonEnemyData.FACTION,
		"kit": "amazon",
		"always_elite": true,  # Owner-approved proposal: tier Elite
		"bronze": true,  # Bronze breastplate.
		# The leap (AmazonKit; owner-approved "leaps over the first row of the
		# ring"): when the necromancer is leap_min..leap_max px away she crouches
		# (leap_windup s) over a landing circle land_gap px in front of him, flies
		# leap_time s over everything, and lands: land_damage_* to what is inside
		# land_radius. A summon of block_mass >= catch_mass within catch_reach px
		# of the landing CATCHES her (owner-approved "Warriors, the Golem"): she is
		# stunned catch_stun s and the landing hurts nothing.
		"leap_cooldown": 7.0,  # TUNING (not in GDD) s
		"first_leap": 2.0,  # TUNING (not in GDD) s after spawning
		"leap_min": 80.0,  # TUNING (not in GDD) px
		"leap_max": 260.0,  # TUNING (not in GDD) px
		"leap_windup": 0.6,  # TUNING (not in GDD) s
		"leap_time": 0.6,  # TUNING (not in GDD) s in the air
		"leap_height": 42.0,  # TUNING (not in GDD) px the drawn arc rises (visual only)
		"land_gap": 34.0,  # TUNING (not in GDD) px in front of the necromancer (inside the ring's first row)
		"land_radius": 36.0,  # TUNING (not in GDD) px
		"land_damage_player": 11.0,  # TUNING (not in GDD) before the time scaling
		"land_damage_summon": 14.0,  # TUNING (not in GDD) before the time scaling
		"catch_mass": 3.0,  # TUNING (not in GDD) block mass that catches her (the Templar's rule: Warriors, Abominations, the Golem)
		"catch_reach": 30.0,  # TUNING (not in GDD) px from the landing point
		"catch_stun": 1.4,  # TUNING (not in GDD) s
	},
	# Elite (female, figure-redesign style): a Gorgon with living snakes for
	# hair, pale green skin, golden eyes, a white chiton over a serpent tail.
	"gorgon": {
		"display_name": "Gorgon",
		"max_hp": 170.0,  # TUNING (not in GDD) an elite
		"move_speed": 40.0,  # TUNING (not in GDD) px/s; she slithers
		"damage": 7.0,  # TUNING (not in GDD) a claw, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 12.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 16,  # TUNING (not in GDD) an elite's XP
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) kill her first (owner-approved)
		"mass": 1.6,  # TUNING (not in GDD)
		"faction": PantheonEnemyData.FACTION,
		"kit": "gorgon",
		"always_elite": true,  # Owner-approved proposal: tier Elite
		# The petrifying gaze (GorgonKit; owner-approved "a petrifying gaze cone:
		# summons in it turn to stone for 3 s (one stun path)"): when the
		# necromancer is within gaze_trigger px she stops, her eyes glow and a
		# cone of gaze_range px and gaze_half_angle rad toward him shows for
		# gaze_telegraph s; then every summon in it is stunned petrify_time s
		# (CombatResolver.stun_unit()) and the necromancer in it takes
		# gaze_damage_player (Grave Step out of the cone).
		"first_gaze": 3.0,  # TUNING (not in GDD) s after spawning
		"gaze_cooldown": 7.5,  # TUNING (not in GDD) s
		"gaze_trigger": 240.0,  # TUNING (not in GDD) px
		"gaze_range": 210.0,  # TUNING (not in GDD) px
		"gaze_half_angle": 0.42,  # TUNING (not in GDD) rad each side (~48 degrees in all)
		"gaze_telegraph": 1.1,  # TUNING (not in GDD) s
		"petrify_time": 3.0,  # Owner-approved proposal: "turn to stone for 3 s"
		"gaze_damage_player": 8.0,  # TUNING (not in GDD) before the time scaling
	},
	# Fodder (Artemis's pack): a lean silver-grey hunting hound with a moon-
	# white collar, fast.
	"moon_hound": {
		"display_name": "Hound of Artemis",
		"max_hp": 16.0,  # TUNING (not in GDD) fodder
		"move_speed": 104.0,  # TUNING (not in GDD) px/s; very fast (Shade 86)
		"damage": 3.0,  # TUNING (not in GDD) a bite, before the time scaling
		"attack_interval": 0.8,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px
		"radius": 8.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.3,  # TUNING (not in GDD)
		"mass": 0.7,  # TUNING (not in GDD)
		"faction": PantheonEnemyData.FACTION,
		"kit": "moon_hound",
		"fodder": true,  # A wave drowns it.
	},
	# Heavy (Poseidon's): a great sea serpent, Aegean scales and a pale belly,
	# a finned head; it lunges.
	"sea_serpent": {
		"display_name": "Sea Serpent",
		"max_hp": 360.0,  # TUNING (not in GDD) a heavy (Bronze Titan 520)
		"move_speed": 58.0,  # TUNING (not in GDD) px/s
		"damage": 12.0,  # TUNING (not in GDD) a bite, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 16.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.8,  # TUNING (not in GDD)
		"mass": 4.0,  # TUNING (not in GDD)
		"faction": PantheonEnemyData.FACTION,
		"kit": "sea_serpent",
		"always_elite": true,  # A champion of the sea.
		# The lunge (SeaSerpentKit): every lunge_cooldown s, at a necromancer or
		# summon within lunge_range px, a lane lunge_length px long and
		# lunge_width wide shows for lunge_telegraph s; then it shoots down the
		# lane at lunge_speed, biting everything in it once (lunge_damage_*).
		"first_lunge": 2.0,  # TUNING (not in GDD) s
		"lunge_cooldown": 4.5,  # TUNING (not in GDD) s
		"lunge_range": 200.0,  # TUNING (not in GDD) px
		"lunge_length": 170.0,  # TUNING (not in GDD) px
		"lunge_width": 30.0,  # TUNING (not in GDD) px
		"lunge_telegraph": 0.7,  # TUNING (not in GDD) s
		"lunge_speed": 520.0,  # TUNING (not in GDD) px/s
		"lunge_damage_player": 12.0,  # TUNING (not in GDD) before the time scaling
		"lunge_damage_summon": 16.0,  # TUNING (not in GDD) before the time scaling
	},
	# --- The Pantheon Trial's gods (minibosses; owner-approved proposal) ---
	# ARES, god of war (male): black and bronze armour, a red cloak, a crested
	# Corinthian helmet, a long spear. War-cry, spear charge, dies to blockers.
	"ares": {
		"display_name": "Ares, God of War",
		"max_hp": ZeusData.MAX_HP * ZeusData.GOD_HP_SHARE,  # Owner-approved proposal: about a third of a stage boss (GodKit: the boss's HP scaling)
		"move_speed": 56.0,  # TUNING (not in GDD) px/s
		"damage": 16.0,  # TUNING (not in GDD) a spear thrust in reach
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px; the spear outreaches a sword
		"radius": 18.0,  # TUNING (not in GDD) px
		"armor": 0.25,  # TUNING (not in GDD)
		"xp": 0,  # Its reward is the XP burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) archers prioritise him like a boss
		"mass": 10.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"faction": PantheonEnemyData.FACTION,
		"kit": "ares",
		"always_elite": true,
		"miniboss": true,
		"bronze": true,  # His bronze draws Zeus's lightning: lure him under the storm.
		"god_hp_share": ZeusData.GOD_HP_SHARE,
		"reward_xp": 200,  # TUNING (not in GDD) XP burst (the Trojan Horse 170)
		"reward_crystals": 14,  # TUNING (not in GDD)
		"advance_range": 520.0,  # TUNING (not in GDD) px beyond which he strides faster
		"advance_speed_mult": 1.7,  # TUNING (not in GDD)
		"first_special": 2.5,  # TUNING (not in GDD) s
		"attack_gap": 2.0,  # TUNING (not in GDD) s between two specials
		"recover_time": 0.6,  # TUNING (not in GDD) s
		# The war-cry (owner-approved "war-cry buffs every enemy on screen"):
		# warcry_cast s with his spear raised, then every enemy within
		# warcry_radius px (about the screen; bosses, minibosses and structures
		# excepted) is buffed warcry_time s through the one enemy-buff path
		# (Enemy.apply_buff()): damage x warcry_damage, speed x warcry_speed.
		"warcry_cooldown": 13.0,  # TUNING (not in GDD) s
		"warcry_cast": 0.9,  # TUNING (not in GDD) s
		"warcry_radius": 640.0,  # TUNING (not in GDD) px ("on screen")
		"warcry_damage": 1.3,  # TUNING (not in GDD) x damage dealt
		"warcry_speed": 1.2,  # TUNING (not in GDD) x move speed
		"warcry_taken": 1.0,  # TUNING (not in GDD) x damage taken (unchanged)
		"warcry_time": 8.0,  # TUNING (not in GDD) s
		# The spear charge (owner-approved "charges with a spear; dies to
		# blockers"): a lane toward the necromancer (charge_telegraph s), then he
		# runs it at charge_speed: the necromancer in it is hit, summons thrown
		# aside; a blocker of block_mass >= charge_block_mass IMPALES him: the
		# charge stops, he takes block_self_damage of his max HP and is stunned
		# block_stun s.
		"charge_cooldown": 6.0,  # TUNING (not in GDD) s
		"charge_min": 90.0,  # TUNING (not in GDD) px
		"charge_max": 440.0,  # TUNING (not in GDD) px
		"charge_length": 420.0,  # TUNING (not in GDD) px (obstacles cut it short)
		"charge_width": 40.0,  # TUNING (not in GDD) px
		"charge_telegraph": 0.9,  # TUNING (not in GDD) s
		"charge_speed": 700.0,  # TUNING (not in GDD) px/s
		"charge_damage_player": 18.0,  # TUNING (not in GDD) before the time scaling
		"charge_damage_summon": 22.0,  # TUNING (not in GDD) before the time scaling
		"charge_push": 40.0,  # TUNING (not in GDD) px summons in the lane are thrown aside
		"charge_block_mass": 3.0,  # TUNING (not in GDD) the Templar's rule: Warriors, Abominations, the Golem
		"block_self_damage": 0.05,  # TUNING (not in GDD) share of his max HP lost when a blocker impales him
		"block_stun": 2.0,  # TUNING (not in GDD) s
	},
	# ARTEMIS, goddess of the hunt (female, figure-redesign style): a short
	# silver-white chiton, a crescent-moon circlet over long dark hair, a
	# silver longbow, a quiver. Moonlit volleys, hounds, teleports between groves.
	"artemis": {
		"display_name": "Artemis, the Huntress",
		"max_hp": ZeusData.MAX_HP * ZeusData.GOD_HP_SHARE,  # Owner-approved proposal: about a third of a stage boss (GodKit)
		"move_speed": 58.0,  # TUNING (not in GDD) px/s
		"damage": 6.0,  # TUNING (not in GDD) per plain arrow, before the time scaling
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 320.0,  # TUNING (not in GDD) px
		"radius": 15.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 0,
		"behavior": "ranged",  # The shared ranged AI: she always advances on the necromancer.
		"projectile_speed": 340.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD)
		"mass": 8.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD)
		"faction": PantheonEnemyData.FACTION,
		"kit": "artemis",
		"always_elite": true,
		"miniboss": true,
		"god_hp_share": ZeusData.GOD_HP_SHARE,
		"reward_xp": 200,  # TUNING (not in GDD)
		"reward_crystals": 14,  # TUNING (not in GDD)
		# Moonlit volleys (owner-approved "volleys of moonlit arrows"): she
		# stands volley_telegraph s drawing (a fan of pale lines), then looses
		# volley_arrows arrows fanned over volley_spread rad at the necromancer.
		"first_volley": 2.0,  # TUNING (not in GDD) s
		"volley_cooldown": 5.5,  # TUNING (not in GDD) s
		"volley_telegraph": 0.7,  # TUNING (not in GDD) s
		"volley_arrows": 7,  # TUNING (not in GDD)
		"volley_spread": 0.9,  # TUNING (not in GDD) rad
		"volley_damage": 7.0,  # TUNING (not in GDD) per arrow, before the time scaling
		"volley_speed": 380.0,  # TUNING (not in GDD) px/s
		# Hunting hounds (owner-approved "her hunting hounds").
		"first_hounds": 4.0,  # TUNING (not in GDD) s
		"hounds_cooldown": 16.0,  # TUNING (not in GDD) s
		"hounds_count": 4,  # TUNING (not in GDD)
		"hounds_cast": 0.6,  # TUNING (not in GDD) s she stands calling them (a horn)
		# Teleports between groves (owner-approved): every teleport_cooldown s, or
		# sooner (after teleport_min s) when crowd_summons summons stand within
		# crowd_reach px of her, she fades out (blink_time s) and appears at
		# another moonlit grove (OlympusDirector.grove_point()).
		"teleport_cooldown": 9.0,  # TUNING (not in GDD) s
		"teleport_min": 3.0,  # TUNING (not in GDD) s
		"crowd_summons": 4,  # TUNING (not in GDD)
		"crowd_reach": 60.0,  # TUNING (not in GDD) px
		"blink_time": 0.5,  # TUNING (not in GDD) s
	},
	# POSEIDON, lord of the sea (male): a big bearded god, sea-green hair and
	# beard, a gold crown, a sea-green robe over one shoulder, a gold trident.
	"poseidon": {
		"display_name": "Poseidon, Lord of the Sea",
		"max_hp": ZeusData.MAX_HP * ZeusData.GOD_HP_SHARE,  # Owner-approved proposal: about a third of a stage boss (GodKit)
		"move_speed": 46.0,  # TUNING (not in GDD) px/s
		"damage": 15.0,  # TUNING (not in GDD) a trident blow in reach
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 19.0,  # TUNING (not in GDD) px
		"armor": 0.25,  # TUNING (not in GDD)
		"xp": 0,
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD)
		"mass": 12.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD)
		"faction": PantheonEnemyData.FACTION,
		"kit": "poseidon",
		"always_elite": true,
		"miniboss": true,
		"god_hp_share": ZeusData.GOD_HP_SHARE,
		"reward_xp": 200,  # TUNING (not in GDD)
		"reward_crystals": 14,  # TUNING (not in GDD)
		"advance_range": 520.0,  # TUNING (not in GDD) px
		"advance_speed_mult": 1.7,  # TUNING (not in GDD)
		"attack_gap": 1.8,  # TUNING (not in GDD) s between two specials
		"recover_time": 0.6,  # TUNING (not in GDD) s
		# The flood (owner-approved "floods half the arena"): flood_cast s with
		# the trident raised, then a wall of water through the Wrath of the Gods'
		# strike entry (DivineWrath.strike("waves")): from his side across the
		# necromancer, flood_half_len px each side of his line (half the arena),
		# starting flood_start px behind the necromancer, shown flood_telegraph s.
		"first_flood": 4.0,  # TUNING (not in GDD) s
		"flood_cooldown": 15.0,  # TUNING (not in GDD) s
		"flood_cast": 1.0,  # TUNING (not in GDD) s
		"flood_half_len": 420.0,  # TUNING (not in GDD) px (the wrath's 900: half the arena)
		"flood_start": 380.0,  # TUNING (not in GDD) px
		"flood_telegraph": 2.0,  # TUNING (not in GDD) s
		# Trident throws (owner-approved): a lane toward the necromancer shows
		# trident_telegraph s, then the trident flies down it (trident_speed),
		# piercing everything in its width once.
		"first_trident": 2.0,  # TUNING (not in GDD) s
		"trident_cooldown": 5.0,  # TUNING (not in GDD) s
		"trident_range": 460.0,  # TUNING (not in GDD) px; throws at a necromancer this close
		"trident_telegraph": 0.8,  # TUNING (not in GDD) s
		"trident_length": 480.0,  # TUNING (not in GDD) px
		"trident_width": 26.0,  # TUNING (not in GDD) px
		"trident_speed": 950.0,  # TUNING (not in GDD) px/s
		"trident_damage_player": 14.0,  # TUNING (not in GDD) before the time scaling
		"trident_damage_summon": 20.0,  # TUNING (not in GDD) before the time scaling
		# The sea serpent (owner-approved "a sea serpent"): at each HP share in
		# serpent_at he stands serpent_cast s and a Sea Serpent rises beside him.
		"serpent_at": [0.66, 0.33],  # TUNING (not in GDD) HP shares
		"serpent_cast": 1.0,  # TUNING (not in GDD) s
	},
}
