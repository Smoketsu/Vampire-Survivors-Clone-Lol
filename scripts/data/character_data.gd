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
	"brine_widow",
	# --- Act II: the Hollow Archive ---
	"heretic_scribe",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"tide_widow",
	# --- Act III: the Assembly Halls ---
	"marionette",
	# --- Act III: the Scrap Wastes ---
	"lightning_abbess",
	# --- Act III: the Iron Citadel ---
	"rust_prophet",
	# --- Act IV: the Shores of Ilion ---
	"doomed_prophetess",
	# --- Act IV: Mount Olympus ---
	"oathbreaker",
	# --- Act IV: the Asphodel Underworld ---
	"ferrywoman"]
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
##   verse_burst_radius      ForbiddenVerse._release_bursts (extra ink burst radius fraction)
##   thrall_hp_bonus         CallOfTheDrowned._raise (extra Thrall HP fraction)
##   thrall_cap_bonus        CallOfTheDrowned._raise (extra Thralls at once)
##   puppet_duration         HollowPuppet._raise (extra puppet life fraction)
##   puppet_damage           HollowPuppet._raise (extra puppet damage fraction)
##   ray_extra_sparks        DeathRay._spark_from (extra sparks per beam kill)
##   risen_bolt_interval     CharacterInnates.on_temporary_spawned / step (s
##                           between a temporary Risen's scrap bolts; Act III)
##   risen_bolt_damage       CharacterInnates (damage of each scrap bolt, before
##                           the Risen's own summon bonuses)
##   thunder_divine_bonus    StolenThunder._hit (extra damage fraction on bosses,
##                           minibosses and Heroes; Act IV)
##   ferry_cooldown          RiverStyx.on_enemy_killed (s between two Risen a foe
##                           slain in her river raises; Act IV)
##   ferry_life              RiverStyx.on_enemy_killed (s that Risen stands)
const INNATE_KEYS := ["orb_projectile_destroy", "blast_echo_delay", "blast_echo_damage", "spear_shard_max",
	"spear_shard_cooldown", "summon_corpses", "grace_share", "grace_targets", "grace_range", "contagion_range",
	"contagion_duration", "death_mark_slow", "bone_wall_duration", "soul_chains_extra_jumps", "wither_rot",
	"wither_rot_linger", "temp_summon_duration",
	# --- Act II: Gullhaven Harbour ---
	"undertow_shallows_every",
	# --- Act II: the Hollow Archive ---
	"verse_burst_radius",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"thrall_hp_bonus", "thrall_cap_bonus",
	# --- Act III: the Assembly Halls ---
	"puppet_duration", "puppet_damage",
	# --- Act III: the Scrap Wastes ---
	"ray_extra_sparks",
	# --- Act III: the Iron Citadel ---
	"risen_bolt_interval", "risen_bolt_damage",
	# --- Act IV: the Shores of Ilion ---
	"arrow_elite_bonus",
	# --- Act IV: Mount Olympus ---
	"thunder_divine_bonus",
	# --- Act IV: the Asphodel Underworld ---
	"ferry_cooldown", "ferry_life"]

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
	# --- Act II: the Hollow Archive ---
	# Forbidden Verse's character (owner rule: each new spell comes with its
	# playable character; his spell must be unlocked first, by the Archivist).
	"heretic_scribe": {
		"display_name": "The Heretic Scribe",
		"title": "He reads the Eye's scripture aloud, and the words cut.",
		"spell": "forbidden_verse",
		"innate": {
			"id": "illuminated_margins", "name": "Illuminated Margins",
			"description": "Your ink bursts reach 30% farther.",
			"values": {"verse_burst_radius": 0.3},  # TUNING (not in GDD)
		},
		"stats": {"max_hp": -10.0, "move_speed": 0.05},  # TUNING (not in GDD) a frail, quick reader
		"sprite": "player/heretic_scribe",
		"tint": Color(0.48, 0.30, 0.86),  # TUNING (not in GDD) scripture violet ink
		"starts_unlocked": false,
	},
	# --- Act II: Ul-Thalos, the Risen Spire ---
	# The Tide Widow (the Call of the Drowned's character; female, in the
	# figure-redesign style: fully clothed, the bust rig and idle breathing).
	# A drowned priestess of the Eye who walked back out of the sea as a
	# necromancer: the Thralls she calls rise sturdier, and more of them.
	"tide_widow": {
		"display_name": "The Tide Widow",
		"title": "She sang the drowned home; now they answer her.",
		"spell": "call_of_the_drowned",
		"innate": {
			"id": "drowned_chorus", "name": "Drowned Chorus",
			"description": "The Thralls you call rise 40% sturdier, and two more may stand at once.",
			"values": {"thrall_hp_bonus": 0.4, "thrall_cap_bonus": 2.0},  # TUNING (not in GDD) HP fraction, Thralls
		},
		"stats": {"max_hp": 10.0, "move_speed": -0.05},  # TUNING (not in GDD) sturdier, slower: the sea's weight
		"sprite": "player/tide_widow",
		"tint": Color(0.36, 0.78, 0.72),  # TUNING (not in GDD) drowned teal
		"starts_unlocked": false,
	},
	# --- Act III: the Assembly Halls ---
	# The Marionette (Hollow Puppet's character; owner-approved Act III proposal,
	# female, in the figure-redesign style: an hourglass figure, fully clothed in
	# a violet harlequin gown and corset, a porcelain doll's mask face, soul
	# strings running from her fingers; the bust rig and idle breathing). Hollow
	# Puppet must be unlocked (the Motherboard) before she can be earned, by the
	# usual Lv 5 rule.
	"marionette": {
		"display_name": "The Marionette",  # Owner-approved proposal
		"title": "Every soul is a string; she has learned to pull them.",
		"spell": "hollow_puppet",
		"innate": {
			"id": "puppeteer", "name": "Puppeteer",
			"description": "Your puppets last 25% longer and hit 25% harder.",
			"values": {"puppet_duration": 0.25, "puppet_damage": 0.25},  # Owner-approved proposal "puppets last 25% longer and hit harder"; the damage share TUNING (not in GDD)
		},
		"stats": {"max_hp": -5.0, "move_speed": 0.05},  # TUNING (not in GDD) a light dancer's body
		"sprite": "player/marionette",
		"tint": Color(0.74, 0.46, 0.96),  # TUNING (not in GDD) soul-string violet
		"starts_unlocked": false,
	},
	# --- Act III: the Scrap Wastes ---
	# The Lightning Abbess (Death Ray's character; owner-approved Act III
	# proposal; female, in the figure-redesign style: fully clothed, the bust
	# rig and idle breathing). The abbess of a storm-chapel the Empire razed; she
	# drew the lightning into her own bones. Her spell must be unlocked first
	# (by Kestrel), then she unlocks the usual way (Death Ray to Lv 5).
	"lightning_abbess": {
		"display_name": "The Lightning Abbess",
		"title": "She prayed for a storm; now she is one.",
		"spell": "death_ray",
		"innate": {
			"id": "storm_litany", "name": "Storm Litany",
			"description": "Every kill of your beam sparks lightning to one more foe.",
			"values": {"ray_extra_sparks": 1.0},  # Owner-approved Act III proposal: "Beam kills spark lightning to one more enemy"
		},
		"stats": {"max_hp": -5.0, "move_speed": 0.05},  # TUNING (not in GDD) a light, quick abbess
		"sprite": "player/lightning_abbess",
		"tint": Color(0.70, 0.55, 1.0),  # TUNING (not in GDD) storm violet
		"starts_unlocked": false,
	},
	# --- Act III: the Iron Citadel ---
	# The Rust Prophet (Scrap Swarm's character; owner-approved Act III proposal:
	# "an Empire engineer who defected to death"; his spell must be unlocked
	# first, by Deus Ex Machina). He taught the Empire's scrap to obey the dead:
	# every temporary Risen he raises carries a scrap launcher and fires a bolt
	# every few seconds (HordeDirector.spawn_temporary() hands it to
	# CharacterInnates, the one temporary-summon path).
	"rust_prophet": {
		"display_name": "The Rust Prophet",
		"title": "He built the Empire's machines. Now he builds them for the dead.",
		"spell": "scrap_swarm",
		"innate": {
			"id": "scrap_prophecy", "name": "Scrap Prophecy",
			"description": "Every temporary Risen you raise fires a scrap bolt every few seconds.",
			"values": {"risen_bolt_interval": 2.5, "risen_bolt_damage": 10.0},  # TUNING (not in GDD) s, damage per bolt
		},
		"stats": {"max_hp": 5.0, "spell_area": 0.05},  # TUNING (not in GDD) an engineer's plating and a wider reach
		"sprite": "player/rust_prophet",
		"tint": Color(0.86, 0.58, 0.34),  # TUNING (not in GDD) rust orange over the violet
		"starts_unlocked": false,
	},
	# --- Act IV: the Shores of Ilion ---
	# The Doomed Prophetess (Paris's Arrow's character; owner-approved Act IV
	# proposal: "a dead seer of Troy (figure style)"; female, in the
	# figure-redesign style: fully clothed, the bust rig and idle breathing). She
	# foresaw the fall of Troy and the death of Achilles at the heel, and no one
	# believed her; dead, she still sees where every champion will fall. Her
	# spell must be unlocked first (by Achilles), then she unlocks the usual way
	# (Paris's Arrow to Lv 5). Own decision on her innate (the proposal names
	# none): her arrows strike champions harder (ParisArrow reads it).
	"doomed_prophetess": {
		"display_name": "The Doomed Prophetess",
		"title": "She saw the heel. No one believed her.",
		"spell": "paris_arrow",
		"innate": {
			"id": "foretold_fall", "name": "Foretold Fall",
			"description": "Your ghost arrows strike elites, champions and bosses harder.",
			"values": {"arrow_elite_bonus": 0.3},  # TUNING (not in GDD) +30% Paris's Arrow damage to elites, minibosses and bosses
		},
		"stats": {"max_hp": -5.0, "spell_area": 0.05},  # TUNING (not in GDD) a frail seer with a wide sight
		"sprite": "player/doomed_prophetess",
		"tint": Color(0.62, 0.48, 0.92),  # TUNING (not in GDD) twilight violet
	},
	# --- Act IV: Mount Olympus ---
	# The Oathbreaker (Stolen Thunder's character; owner-approved Act IV
	# proposal: "a fallen demigod", male; his spell must be unlocked first, by
	# Zeus). A son of Zeus who swore to guard the dead and broke the oath to
	# raise them: he stole a bolt from his father's hand on the way down, and
	# it strikes hardest at his own kin (StolenThunder reads the innate).
	"oathbreaker": {
		"display_name": "The Oathbreaker",
		"title": "He swore to guard the dead. Now he leads them against his father.",
		"spell": "stolen_thunder",
		"innate": {
			"id": "kinslayer", "name": "Kinslayer",
			"description": "Your Stolen Thunder strikes bosses, gods and Heroes harder.",
			"values": {"thunder_divine_bonus": 0.35},  # TUNING (not in GDD) +35% Stolen Thunder damage on bosses, minibosses and Heroes
		},
		"stats": {"max_hp": 10.0, "move_speed": -0.03},  # TUNING (not in GDD) a demigod's body, heavy bronze
		"sprite": "player/oathbreaker",
		"tint": Color(0.85, 0.72, 0.45),  # TUNING (not in GDD) tarnished bronze over the violet
	},
	# --- Act IV: the Asphodel Underworld ---
	# The Ferrywoman (River Styx's character; owner-approved Act IV proposal:
	# "the Ferrywoman, Charon's daughter (figure style)": female, in the
	# figure-redesign style, an hourglass figure fully clothed in a hooded grey
	# ferryman's robe and a dark corset, a lantern and a long oar, an obol on a
	# cord; the bust rig and idle breathing). River Styx must be unlocked (Hades)
	# before she can be earned, by the usual Lv 5 rule. She ferries the dead the
	# other way: a foe slain in her river rises as a temporary Risen
	# (RiverStyx.on_enemy_killed(), through HordeDirector.spawn_temporary()).
	"ferrywoman": {
		"display_name": "The Ferrywoman",  # Owner-approved proposal
		"title": "Charon's daughter. The river ran dry, so she rows for you.",
		"spell": "river_styx",
		"innate": {
			"id": "ferry_of_souls", "name": "Ferry of Souls",
			"description": "A foe slain in your river rises as a Risen for a few seconds.",
			"values": {"ferry_cooldown": 2.0, "ferry_life": 8.0},  # TUNING (not in GDD) s between two Risen, s each stands
		},
		"stats": {"max_hp": 5.0, "move_speed": 0.05},  # TUNING (not in GDD) a rower's strength, a ferry's glide
		"sprite": "player/ferrywoman",
		"tint": Color(0.58, 0.66, 0.80),  # TUNING (not in GDD) a cold river grey-blue over the violet
		"starts_unlocked": false,
	},
}
