## CharacterData — designer data for the PLAYABLE CHARACTERS (owner-approved
## "one character per spell"): twelve necromancers, each starting the run
## with a different spell, with one INNATE passive (owner decision: innates
## only, no exclusive passive cards) and a few stat modifiers. No logic here:
## CharacterModifiers (the ONE character path) reads it, CharacterInnates
## runs the innates, and the pre-run setup screen's CharacterPicker shows it.
##
## The Gravecaller is today's necromancer and the default (RunConfig,
## fresh saves): Shadow Bolt, NO innate and baseline stats, so a Gravecaller
## run plays bit-for-bit like the game before characters existed.
##
## Unlock rule (owner): a character unlocks the first time the player reaches
## Lv UNLOCK_LEVEL with that character's starting spell in any run (tracked
## per spell in the Meta save, [characters] section); the Gravecaller
## (`starts_unlocked`) is open from the start.
##
## A character whose starting spell is not in AbilityData.SPELLS would be
## hidden from the picker and refused by --character= (a safety rule; all
## twelve spells exist). The five later spells' innates are hooks (`values`
## below) the spell's code reads with game.character.innate_value(key),
## which is 0 for every other character.
##
## Keys of a character row:
##   display_name    UI name.
##   title           one-line flavour title under the name.
##   spell           AbilityData id of the starting spell (Lv 1 at run start).
##   innate          {} = no innate (the Gravecaller), else:
##                     id           innate id (summary / stats).
##                     name         UI name of the innate.
##                     description  card / picker text.
##                     values       innate key -> number. Keys are unique
##                                  across characters (see INNATE_KEYS), so a
##                                  hook asks for its key and gets 0 unless
##                                  that character is played.
##   stats           stat modifiers (STAT_LABELS keys; {} = baseline):
##                     max_hp       flat max HP (+/-, HP)
##                     move_speed   move speed fraction (+0.05 = +5%)
##                     spell_area   spell radius fraction (+0.10 = +10%)
##   sprite          SpriteBank key of the character's art (assets/sprites/
##                   player/<id>.png, 56 px tall, ART_BIBLE). Until it
##                   exists the necromancer's art / glyph is drawn tinted.
##   tint            the spell school's colour: picker accents, the glyph /
##                   tinted-sprite fallback and the in-run aura.
##   starts_unlocked true = open from the start (else the unlock rule).
class_name CharacterData
extends RefCounted

## Character ids in picker order (the spells' AbilityData order, then the
## five later spells).
const ORDER := ["gravecaller", "umbral_warden", "voidcaller", "bone_oracle", "fallen_confessor",
	"carrion_lord", "plague_scholar", "doomsayer", "barrow_warden", "soulbinder", "wither_witch", "grave_herald",
	# --- Act II: Gullhaven Harbour (Undertow's character) ---
	"brine_widow"]
## The default character (RunConfig, fresh saves, the autotest): today's game.
const DEFAULT_ID: String = "gravecaller"
## Spell level that unlocks a character (owner rule: reach Lv 5 with its spell
## in any run).
const UNLOCK_LEVEL: int = 5  # Owner decision (GDD §15.0)

## Stat modifier key -> [UI label, format] ("int" = flat, "pct" = fraction),
## in display order.
const STAT_LABELS := {
	"max_hp": ["Max HP", "int"],
	"move_speed": ["Move speed", "pct"],
	"spell_area": ["Spell area", "pct"],
}

## Every innate value key (CharacterData.CHARACTERS[*].innate.values) and
## what reads it:
##   orb_projectile_destroy  CharacterInnates.eclipsed_guard (ProjectileManager)
##   blast_echo_delay        CharacterInnates.on_blast (s before the echo)
##   blast_echo_damage       CharacterInnates.on_blast (fraction of the blast)
##   spear_shard_max         CharacterInnates.on_enemy_killed (shards held)
##   spear_shard_cooldown    CharacterInnates.on_enemy_killed (s between grows)
##   summon_corpses          CharacterInnates.on_summon_died (1 = on)
##   grace_share             CharacterInnates.on_player_healed (fraction)
##   grace_targets           CharacterInnates.on_player_healed (summons)
##   grace_range             CharacterInnates.on_player_healed (px)
##   contagion_range         CharacterInnates.on_enemy_killed (px)
##   contagion_duration      CharacterInnates.on_enemy_killed (s of Rot)
##   death_mark_slow         DeathMark._brand (slow fraction for the brand's s)
##   bone_wall_duration      BoneWall._cast (extra wall lifetime fraction)
##   soul_chains_extra_jumps SoulChains._cast (extra arcs per bolt)
##   wither_rot              Wither._pulse (Rot fraction per pulse)
##   wither_rot_linger       Wither._pulse (s the Rot outlasts the pulse)
##   temp_summon_duration    HordeDirector.spawn_temporary (every source)
##   undertow_shallows_every Undertow._cast (a wave in every N leaves shallows;
##                           the spell's own rule is every 3rd)
const INNATE_KEYS := ["orb_projectile_destroy", "blast_echo_delay", "blast_echo_damage", "spear_shard_max",
	"spear_shard_cooldown", "summon_corpses", "grace_share", "grace_targets", "grace_range", "contagion_range",
	"contagion_duration", "death_mark_slow", "bone_wall_duration", "soul_chains_extra_jumps", "wither_rot",
	"wither_rot_linger", "temp_summon_duration",
	# --- Act II: Gullhaven Harbour ---
	"undertow_shallows_every"]

## Orbit radius (px) of the Bone Oracle's Ossuary Ward shards around him.
const SHARD_ORBIT_RADIUS: float = 27.0  # TUNING (not in GDD)
## Orbit speed (rad/s) of the Ossuary Ward shards (purely visual).
const SHARD_ORBIT_SPEED: float = 2.2  # TUNING (not in GDD)
## Vertical offset (px) of the shard orbit's centre from the necromancer's
## feet (his chest height), purely visual.
const SHARD_ORBIT_LIFT: float = -10.0  # TUNING (not in GDD)
## Radius (px) of the in-run school aura drawn under a non-default character
## whose own art does not exist yet (purely visual).
const AURA_RADIUS: float = 15.0  # TUNING (not in GDD)

## Every character (see the header for the keys).
const CHARACTERS := {
	"gravecaller": {
		"display_name": "The Gravecaller",
		"title": "First of the risen circle. The dead answer his shadow.",
		"spell": "shadow_bolt",  # AbilityData.STARTING_SPELL (GDD §3)
		"innate": {},  # Owner decision: the default has no innate.
		"stats": {},  # Owner decision: baseline stats.
		"sprite": "player/necromancer",
		"tint": Color(0.64, 0.36, 0.98),  # Shadow violet (Palette.VIOLET).
		"starts_unlocked": true,  # Owner decision: open from the start.
	},
	"umbral_warden": {
		"display_name": "The Umbral Warden",
		"title": "Keeper of the eclipse, who walks behind a wall of night.",
		"spell": "orb_shield",
		"innate": {
			"id": "eclipsed_guard", "name": "Eclipsed Guard",
			"description": "Your orbs destroy every enemy arrow and bolt they touch, even while recharging.",
			"values": {"orb_projectile_destroy": 1.0},  # Owner spec (on / off)
		},
		"stats": {"max_hp": 15.0, "move_speed": -0.05},  # Owner spec
		"sprite": "player/umbral_warden",
		"tint": Color(0.45, 0.55, 1.0),  # TUNING (not in GDD) eclipse blue-violet
		"starts_unlocked": false,
	},
	"voidcaller": {
		"display_name": "The Voidcaller",
		"title": "She speaks the void aloud, and the void answers twice.",
		"spell": "shadow_blast",
		"innate": {
			"id": "echoing_dark", "name": "Echoing Dark",
			"description": "Each Shadow Blast leaves a ring that bursts again 1 s later for 40% of its damage.",
			"values": {"blast_echo_delay": 1.0, "blast_echo_damage": 0.4},  # Owner spec
		},
		"stats": {"max_hp": -10.0},  # Owner spec
		"sprite": "player/voidcaller",
		"tint": Color(0.55, 0.22, 0.85),  # TUNING (not in GDD) abyssal purple
		"starts_unlocked": false,
	},
	"bone_oracle": {
		"display_name": "The Bone Oracle",
		"title": "He reads the future in thrown bones.",
		"spell": "bone_spear",
		"innate": {
			"id": "ossuary_ward", "name": "Ossuary Ward",
			"description": "Bone Spear kills grow bone shards that orbit you; each blocks one hit (max 3, one grows every 3 s).",
			"values": {"spear_shard_max": 3.0, "spear_shard_cooldown": 3.0},  # Owner spec (max 3); TUNING (not in GDD) cooldown
		},
		"stats": {"max_hp": 10.0},  # Owner spec
		"sprite": "player/bone_oracle",
		"tint": Color(0.92, 0.88, 0.74),  # TUNING (not in GDD) bone white
		"starts_unlocked": false,
	},
	"fallen_confessor": {
		"display_name": "The Fallen Confessor",
		"title": "A defrocked priest who learned to take what he once gave.",
		"spell": "soul_siphon",
		"innate": {
			"id": "stolen_grace", "name": "Stolen Grace",
			"description": "Healing you receive also heals your nearest wounded summons for half as much.",
			"values": {"grace_share": 0.5, "grace_targets": 3.0, "grace_range": 240.0},  # Owner spec (half); TUNING (not in GDD) targets, range
		},
		"stats": {"move_speed": 0.05},  # Owner spec
		"sprite": "player/fallen_confessor",
		"tint": Color(0.36, 0.86, 0.74),  # TUNING (not in GDD) soul teal
		"starts_unlocked": false,
	},
	"carrion_lord": {
		"display_name": "The Carrion Lord",
		"title": "Every corpse is a weapon, even his own servants'.",
		"spell": "corpse_explosion",
		"innate": {
			"id": "grave_harvest", "name": "Grave Harvest",
			"description": "Your own fallen summons leave corpses that Corpse Explosion detonates like the enemy's.",
			"values": {"summon_corpses": 1.0},  # Owner spec (on / off)
		},
		"stats": {},  # Owner spec: baseline
		"sprite": "player/carrion_lord",
		"tint": Color(0.78, 0.42, 0.36),  # TUNING (not in GDD) raw bone and gore
		"starts_unlocked": false,
	},
	"plague_scholar": {
		"display_name": "The Plague Scholar",
		"title": "She catalogues every rot, and spreads the best of them.",
		"spell": "plague_cloud",
		"innate": {
			"id": "contagion", "name": "Contagion",
			"description": "An enemy that dies while Rotting spreads its Rot to the nearest enemy.",
			"values": {"contagion_range": 160.0, "contagion_duration": 3.0},  # TUNING (not in GDD)
		},
		"stats": {"max_hp": -10.0, "spell_area": 0.10},  # Owner spec
		"sprite": "player/plague_scholar",
		"tint": Color(0.70, 0.86, 0.30),  # TUNING (not in GDD) plague yellow-green
		"starts_unlocked": false,
	},
	"doomsayer": {
		"display_name": "The Doomsayer",
		"title": "He brands the doomed, and the doomed believe him.",
		"spell": "death_mark",
		"innate": {
			"id": "ill_omen", "name": "Ill Omen",
			"description": "Branded enemies are also slowed by 15%.",
			"values": {"death_mark_slow": 0.15},  # Owner spec
		},
		"stats": {},  # Owner spec: baseline
		"sprite": "player/doomsayer",
		"tint": Color(0.86, 0.20, 0.26),  # TUNING (not in GDD) doom crimson
		"starts_unlocked": false,
	},
	"barrow_warden": {
		"display_name": "The Barrow Warden",
		"title": "He raises barrow walls out of old bones.",
		"spell": "bone_wall",
		"innate": {
			"id": "stonebone", "name": "Stonebone",
			"description": "Your bone walls last 50% longer.",
			"values": {"bone_wall_duration": 0.5},  # Owner spec
		},
		"stats": {"max_hp": 10.0},  # Owner spec
		"sprite": "player/barrow_warden",
		"tint": Color(0.66, 0.63, 0.55),  # TUNING (not in GDD) barrow stone
		"starts_unlocked": false,
	},
	"soulbinder": {
		"display_name": "The Soulbinder",
		"title": "She chains souls together and lets the lightning run.",
		"spell": "soul_chains",
		"innate": {
			"id": "conductor", "name": "Conductor",
			"description": "Your lightning arcs jump to one extra enemy.",
			"values": {"soul_chains_extra_jumps": 1.0},  # Owner spec
		},
		"stats": {},  # Owner spec: baseline
		"sprite": "player/soulbinder",
		"tint": Color(0.40, 0.86, 1.0),  # TUNING (not in GDD) soul-lightning cyan
		"starts_unlocked": false,
	},
	"wither_witch": {
		"display_name": "The Wither Witch",
		"title": "Where she walks, the living wither.",
		"spell": "wither",
		"innate": {
			"id": "creeping_rot", "name": "Creeping Rot",
			"description": "Your withering aura also inflicts Rot.",
			"values": {"wither_rot": 0.10, "wither_rot_linger": 1.0},  # TUNING (not in GDD) Rot fraction, s
		},
		"stats": {"max_hp": -5.0},  # Owner spec
		"sprite": "player/wither_witch",
		"tint": Color(0.80, 0.60, 0.30),  # TUNING (not in GDD) withered amber
		"starts_unlocked": false,
	},
	"grave_herald": {
		"display_name": "The Grave Herald",
		"title": "He heralds the restless dead back to war.",
		"spell": "raise_dead",
		"innate": {
			"id": "restless", "name": "Restless",
			"description": "Temporary summons from any source last 25% longer.",
			"values": {"temp_summon_duration": 0.25},  # Owner spec
		},
		"stats": {},  # Owner spec: baseline
		"sprite": "player/grave_herald",
		"tint": Color(0.42, 0.95, 0.55),  # TUNING (not in GDD) necrotic green
		"starts_unlocked": false,
	},
	# --- Act II: Gullhaven Harbour ---
	# Undertow's character (owner rule: each new spell comes with its playable
	# character; figure-redesign style: an hourglass figure, fully clothed in a
	# violet mourning gown with a drowned-teal kelp shawl and veil). Undertow
	# must be unlocked (Abbot Merrow) before she can be earned, by the usual
	# Lv 5 rule.
	"brine_widow": {
		"display_name": "The Brine Widow",
		"title": "The sea took her husband; she took the sea.",
		"spell": "undertow",
		"innate": {
			"id": "riptide", "name": "Riptide",
			"description": "Every second Undertow wave leaves shallow water, not every third.",
			"values": {"undertow_shallows_every": 2},  # TUNING (not in GDD) waves per patch
		},
		"stats": {"spell_area": 0.06, "max_hp": -5.0},  # TUNING (not in GDD) a wider reach, a frailer body
		"sprite": "player/brine_widow",
		"tint": Color(0.45, 0.78, 0.86),  # TUNING (not in GDD) stolen tide blue
		"starts_unlocked": false,
	},
}
