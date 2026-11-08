## CodexData — designer data for the CODEX and ACHIEVEMENTS screen (GDD §10.1
## "Collection / Codex" and "Achievements" menu buttons; GDD §15.0 "Codex
## and achievements screen"). Data only, no logic beyond lookups.
##
## The codex is an illustrated compendium that fills in as the player MEETS
## things in runs (CodexLog records them, Meta saves them in [codex]):
##   * "spell"  — a spell learned (the starting spell or a card),
##   * "summon" — a summon class raised (the starting Warriors or a card),
##   * "enemy"  — a Covenant kind slain (soldiers, structures, the Reckoning
##                Inquisitor, the Cathedral Guardian miniboss),
##   * "boss"   — a stage boss faced (it arrived on the field).
## Evolutions are NOT recorded here: they follow the owner's recipe rule
## (hidden until obtained) and read the Meta [recipes] discoveries, so an
## unobtained evolution is a "?" tile with no name, shape or hint.
## Entry ids are the game's own ids (AbilityData, UnitData, the enemy data
## files, StageRegistry.BOSS_ARRIVALS), so new content only needs a line in
## the lists below; names, icons and stats are read from those files, the
## descriptions of the Covenant (whose data has none) live here.
class_name CodexData
extends RefCounted

## Codex category: spells learned.
const SPELL: String = "spell"
## Codex category: summon classes raised.
const SUMMON: String = "summon"
## Codex category: Covenant kinds slain.
const ENEMY: String = "enemy"
## Codex category: stage bosses faced.
const BOSS: String = "boss"
## Every recorded category, in save / summary order.
const CATEGORIES: Array[String] = [SPELL, SUMMON, ENEMY, BOSS]

## Screen tabs, left to right: [tab id, button text]. "feats" is the
## achievements list; the others are codex pages.
const TABS: Array = [["feats", "Achievements"], ["spells", "Spells"], ["summons", "Summons"], ["covenant", "Covenant"], ["eye", "Ancient Eye"],
		["empire", "Empire"],
		# --- Act IV: the Olympian Republic ---
		["pantheon", "Republic"],
		# --- Act V: the Shogunate of the Rising Sun ---
		["shogunate", "Shogunate"],
		# --- Act VI: the Inferno ---
		["inferno", "Inferno"],
		# --- Act VII: the Sanguine Court ---
		["court", "Court"],
		# --- Act VIII: the Last Line ---
		["city", "Last Line"],
		# --- Act IX: the Concord of Stars ---
		["concord", "Concord"],
		# --- Act X: the Black Tide ---
		["corsair", "Black Tide"],
		# --- Act XI (temporary): the Hall of the Slain ---
		["norse", "Hall"],
		# --- Act XII (temporary number): the Necropolis Dynasty ---
		["dynasty", "Dynasty"]]  # TUNING (not in GDD) Act II adds the Ancient Eye tab, Act III the Electronic Empire's, Act IV the Olympian Republic's, Act V the Shogunate's, Act VI the Inferno's, Act VII the Sanguine Court's, Act VIII the Last Line's, Act IX the Concord's, Act XII (temporary) the Dynasty's

## Summon classes shown on the Summons page (UnitData ids, card order). The
## Profane Bishop is a merge evolution, so it sits with the evolutions.
const SUMMON_ORDER: Array[String] = ["warrior", "archer", "mage", "mender", "warder", "abomination",
		"rogue", "gargoyle", "frost_wraith", "bone_hound", "banshee", "corpse_catapult",
		# --- Act II: Fallen Seraph --- (a locked silhouette naming its unlock until met)
		"fallen_seraph",
		# --- Act II: Ul-Thalos, the Risen Spire ---
		"spawn_of_the_deep",
		# --- Content wave 2: Bone Golem --- (a silhouette naming Bone Legion until met)
		"bone_golem",
		# --- Act III: the Assembly Halls --- (a silhouette naming the Motherboard until met)
		"grave_drone",
		# --- Act III: the Iron Citadel --- (a silhouette naming its unlock until met)
		"iron_revenant",
		# --- Act IV: the Asphodel Underworld --- (a silhouette naming its unlock until met)
		"myrmidon_shade",
		# --- Act V: the Road to the Sun --- (a silhouette naming its unlock until met)
		"bound_oni",
		# --- Act VI: the Palace of Silk and Ash --- (a silhouette naming its unlock until met)
		"bound_succubus",
		# --- Act VI: Pandemonium --- (a silhouette naming its unlock until met)
		"archfiend",
		# --- Act VII: Castle Sanguis --- (a silhouette naming its unlock until met)
		"blood_spawn",
		# --- Act VIII: Liberty Heights --- (a silhouette naming its unlock until met)
		"fallen_hero",
		# --- Act IX: the Ark --- (a silhouette naming its unlock until met)
		"ghost_saucer",
		# --- Act XI (temporary): Vigrid --- (a silhouette naming its unlock until met)
		"draugr_thane"]

## Covenant soldiers (enemy kinds), in the order the stages bring them.
const SOLDIERS: Array[String] = ["recruit", "footman", "archer", "chaplain", "purifier", "templar",
		"shieldbearer", "banner_bearer", "halberdier", "battle_sister",
		"sanctified_sentinel", "radiant_inquisitor", "high_confessor", "sun_paladin"]
## Covenant structures (enemy kinds that are buildings or carts).
const STRUCTURES: Array[String] = ["watchtower", "outpost", "ward_generator", "supply_cart", "holy_standard",
		"ward_crystal", "sacred_altar"]
## Champions: the Reckoning's executioner and the Sanctum's miniboss.
const CHAMPIONS: Array[String] = ["inquisitor", "cathedral_guardian"]
## Stage bosses (StageRegistry.BOSS_ARRIVALS ids), campaign order.
const BOSSES: Array[String] = ["alaric", "vael", "seraphine"]

## Act II, the Ancient Eye (GDD §15.0 "Act II: the Ancient Eye"; the Ancient
## Eye tab): its soldiers in the order the stages bring them (the Drowned
## Thrall last: the claimed dead), its minibosses, and its stage bosses
## (StageRegistry.BOSS_ARRIVALS ids). Each Act II stage adds its own as it is built.
const EYE_SOLDIERS: Array[String] = ["eye_initiate", "eye_chanter",
	# --- Act II: Gullhaven Harbour ---
	"deep_kin", "tide_caller", "netcaster", "deep_herald",
	# --- Act II: the Hollow Archive ---
	"scribe", "ink_wraith", "spore_pilgrim", "gibbering_mass",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"eye_siren", "eye_spawn", "eye_hierophant",
	"drowned_thrall"]
## Ancient Eye minibosses (enemy kinds) and the Act II Reckoning kinds.
const EYE_CHAMPIONS: Array[String] = [
	# --- Act II: Gullhaven Harbour ---
	"harbourmaster",
	# --- Act II: the Hollow Archive ---
	"librarian", "unwritten_one",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"eye_waking_horror",
]
## Ancient Eye stage bosses (StageRegistry.BOSS_ARRIVALS ids).
const EYE_BOSSES: Array[String] = [
	# --- Act II: Gullhaven Harbour ---
	"merrow",
	# --- Act II: the Hollow Archive ---
	"archivist",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"vhalneth",
]

## Act III, the Electronic Empire (GDD §15.0 "Act III foundation (phase 1)";
## the Empire tab): its soldiers in the order the stages bring them, its
## champions (minibosses and the Purge Protocol's kill-drone) and its stage
## bosses (StageRegistry.BOSS_ARRIVALS ids). Each Act III stage adds its own as
## it is built (phase 2).
const EMPIRE_SOLDIERS: Array[String] = ["scout_drone", "line_trooper", "spotter",
	# --- Act III: the Assembly Halls ---
	"arc_engineer", "juggernaut",
	# --- Act III: the Scrap Wastes ---
	"aegis_bot", "mortar_walker",
	# --- Act III: the Iron Citadel ---
	"valkyrie_duelist", "sentry_turret", "shield_generator"]
## Electronic Empire champions (minibosses) and the Act III Reckoning kinds.
const EMPIRE_CHAMPIONS: Array[String] = ["kill_drone",
	# --- Act III: the Assembly Halls ---
	"beta_build",
	# --- Act III: the Scrap Wastes ---
	"trojan_horse",
	# --- Act III: the Iron Citadel ---
	"valkyrie_prime"]
## Electronic Empire stage bosses (StageRegistry.BOSS_ARRIVALS ids).
const EMPIRE_BOSSES: Array[String] = ["kestrel", "motherboard", "deus_ex_machina"]

# --- Act IV: the Olympian Republic ---
## Act IV, the Olympian Republic (GDD §15.0 "Act IV foundation (phase 1)"; the
## Republic tab): its soldiers in the order the stages bring them, its
## champions (minibosses and the Twilight's Bronze Titan) and its stage bosses
## (StageRegistry.BOSS_ARRIVALS ids). Each Act IV stage adds its own as it is
## built (phase 2).
const PANTHEON_SOLDIERS: Array[String] = ["shade_of_dead", "hoplite", "hero",
	# --- Act IV: the Shores of Ilion ---
	"legionary", "wolf_of_rome", "cyclops", "siege_tower",
	# --- Act IV: Mount Olympus ---
	"centaur_archer", "amazon", "gorgon", "moon_hound", "sea_serpent",
	# --- Act IV: the Asphodel Underworld ---
	"shade_hoplite", "shade_archer"]
## Olympian Republic champions (minibosses) and the Act IV Reckoning kinds.
const PANTHEON_CHAMPIONS: Array[String] = ["bronze_titan",
	# --- Act IV: the Shores of Ilion ---
	"polyphemus",
	# --- Act IV: Mount Olympus --- (the Pantheon Trial's gods)
	"ares", "artemis", "poseidon",
	# --- Act IV: the Asphodel Underworld ---
	"cerberus", "tartarus_warden"]
## Olympian Republic stage bosses (StageRegistry.BOSS_ARRIVALS ids).
const PANTHEON_BOSSES: Array[String] = ["achilles", "zeus", "hades"]

# --- Act V: the Shogunate of the Rising Sun ---
## Act V, the Shogunate of the Rising Sun (GDD §15.0 "Act V foundation (phase
## 1)"; the Shogunate tab): its soldiers in the order the day brings them, its
## champions (the night heavy that is also the Endless Night's kind, and phase
## 2's minibosses) and its stage bosses (StageRegistry.BOSS_ARRIVALS ids). Each
## Act V stage adds its own as it is built (phase 2).
const SHOGUNATE_SOLDIERS: Array[String] = ["ashigaru", "samurai", "teppo_gunner", "ninja", "onryo",
	# --- Act V: the Burning Province ---
	"kunoichi", "kappa",
	# --- Act V: the Road to the Sun ---
	"sohei", "kitsune",
	# --- Act V: Castle Kurogane ---
	"hatamoto", "kiba_musha"]
## Shogunate champions (minibosses) and the Act V Reckoning kinds.
const SHOGUNATE_CHAMPIONS: Array[String] = ["oni",
	# --- Act V: the Burning Province ---
	"shuten_doji",
	# --- Act V: the Road to the Sun ---
	"kirin",
	# --- Act V: Castle Kurogane ---
	"general_left"]
## Shogunate stage bosses (StageRegistry.BOSS_ARRIVALS ids).
const SHOGUNATE_BOSSES: Array[String] = ["kage", "shogun", "amaterasu"]

# --- Act VI: the Inferno ---
## Act VI, the Inferno (GDD §15.0 "Act VI foundation (phase 1)"; the Inferno
## tab): its soldiers (the demon portal with them, as the Empire's pylons and
## the Republic's siege towers), its champions (the heavy that is also the Last
## Judgment's kind, and phase 2's minibosses) and its stage bosses
## (StageRegistry.BOSS_ARRIVALS ids). The charmed body (Temptation) is never
## listed. Each Act VI stage adds its own as it is built (phase 2).
const INFERNO_SOLDIERS: Array[String] = ["damned", "imp", "hell_knight", "succubus", "demon_portal",
	# --- Act VI: the Burning Gate ---
	"lava_hound", "pit_cultist",
	# --- Act VI: the Palace of Silk and Ash ---
	"lilim_witch",
	# --- Act VI: Pandemonium ---
	"fallen_angel"]
## Inferno champions (minibosses) and the Act VI Reckoning kinds.
const INFERNO_CHAMPIONS: Array[String] = ["demon_brute",
	# --- Act VI: the Burning Gate ---
	"gatekeeper",
	# --- Act VI: the Palace of Silk and Ash ---
	"twin_naamah", "twin_agrat",
	# --- Act VI: Pandemonium ---
	"seraph_general"]
## Inferno stage bosses (StageRegistry.BOSS_ARRIVALS ids).
const INFERNO_BOSSES: Array[String] = ["moloch", "lilith", "morning_star"]

# --- Act VII: the Sanguine Court ---
## Act VII, the Sanguine Court (GDD §15.0 "Act VII foundation (phase 1)"; the
## Court tab): its soldiers (the coffin with them, as the Inferno's portal),
## its champions (the werewolf, the heavy that is also the Endless Feast's
## kind, and phase 2's minibosses) and its stage bosses
## (StageRegistry.BOSS_ARRIVALS ids). Each Act VII stage adds its own as it is
## built (phase 2).
const COURT_SOLDIERS: Array[String] = ["blood_thrall", "vampire_bat", "blood_knight", "vampire_noble", "court_coffin",
	# --- Act VII: Ravensmoor ---
	"ghoul",
	# --- Act VII: the Witchwood ---
	"crimson_witch", "bloated_thrall", "hex_stone",
	# --- Act VII: Castle Sanguis ---
	"chiropteran", "blood_bearer"]
## Court champions (minibosses) and the Act VII Reckoning kinds.
const COURT_CHAMPIONS: Array[String] = ["werewolf",
	# --- Act VII: Ravensmoor ---
	"old_greymane",
	# --- Act VII: the Witchwood ---
	"bog_mother",
	# --- Act VII: Castle Sanguis ---
	"chiropteran_king"]
## Court stage bosses (StageRegistry.BOSS_ARRIVALS ids).
const COURT_BOSSES: Array[String] = ["vargr", "isolde", "carmilla"]

# --- Act VIII: the Last Line ---
## Act VIII, the Last Line (GDD §15.0 "Act VIII foundation (phase 1)"; the
## Last Line tab), GROUPED BY TIER (the escalation): the civilians, then each
## tier's kinds (gangs, police, SWAT and the Guard, the army, the heroes), then
## its stage bosses (StageRegistry.BOSS_ARRIVALS ids). Each Act VIII stage adds
## its own as it is built (phase 2). The burning wreck is not an entry (it is
## never slain).
const CITY_CIVILIANS: Array[String] = ["civilian"]
## The gangs' kinds (tier "gangs").
const CITY_GANGS: Array[String] = ["street_thug", "gang_gunner",
	# --- Act VIII: Skid Row --- (the gangs' enforcer: the miniboss in his limo and on foot)
	"armoured_limo", "big_sal"]
## The police's kinds (tier "police").
const CITY_POLICE: Array[String] = ["riot_cop", "squad_car"]
## SWAT and the Guard's kinds (tier "swat").
const CITY_SWAT: Array[String] = ["swat_breacher", "field_medic"]
## The army's kinds (tier "army").
const CITY_ARMY: Array[String] = ["rifleman", "tank",
	# --- Act VIII: Fort Kessler --- (Mammoth, the miniboss, with the army: the
	# Last Line tab has no champions section)
	"machine_gunner", "attack_helicopter", "mammoth",
	# --- Act VIII: Liberty Heights ---
	"conscript"]
## The heroes (tier "heroes": the Supers).
const CITY_HEROES: Array[String] = ["blitz",
	# --- Act VIII: Liberty Heights --- (the zones' Supers; each leads one as its miniboss there)
	"aurora", "atlas", "nightjar"]
## Last Line stage bosses (StageRegistry.BOSS_ARRIVALS ids).
const CITY_BOSSES: Array[String] = ["don_marrow", "harrow", "paragon"]

# --- Act IX: the Concord of Stars ---
## Act IX, the Concord of Stars (GDD §15.0 "Act IX foundation (phase 1)"; the
## Concord tab), GROUPED BY RACE (one coalition, owner): the Brood, the
## Harvesters, the Vrask, the Luminous, then its stage bosses
## (StageRegistry.BOSS_ARRIVALS ids). Each Act IX stage adds its own as it is
## built (phase 2). The landing pod sits with the Harvesters (it is slain).
const CONCORD_BROOD: Array[String] = ["broodling",
	# --- Act IX: the Crash Site --- (the Brood's soldiers and the stage's
	# miniboss with her race: the Concord tab has no champions section; the
	# Infestation egg has no entry: a cleared egg is never a kill, so the
	# Codex would never meet it)
	"burrower", "acid_spitter", "brood_matriarch"]
## The Harvesters' kinds (race "harvesters"), and the landing pod.
const CONCORD_HARVESTERS: Array[String] = ["grey_drone", "saucer", "concord_terraformer",
	# --- Act IX: the Ark --- (the Grey Overseer; the Ark's structures and the freed beast, the Harvesters' captive)
	"grey_overseer", "specimen_tank", "vault_beast", "reactor_vent", "reap_emitter"]
## The Vrask's kinds (race "vrask").
const CONCORD_VRASK: Array[String] = ["vrask_hunter",
	# --- Act IX: the Proving Moon --- (the Warbeast, the miniboss, with its race:
	# the Concord tab groups by race and has no champions section)
	"warbeast"]
## The Luminous's kinds (race "luminous").
const CONCORD_LUMINOUS: Array[String] = ["lumen_sentinel", "prism",
	# --- Act IX: the Ark --- (the miniboss with its race, as Act VIII placed Mammoth with the army)
	"luminous_archon"]
## Concord stage bosses (StageRegistry.BOSS_ARRIVALS ids).
const CONCORD_BOSSES: Array[String] = ["hive_mother", "vrask_tal", "harvester"]

# --- Act X: the Black Tide ---
## Act X, the Black Tide (GDD §15.0 "Act X foundation: the Black Tide (phase
## 1)"; the Black Tide tab): the Brotherhood's crews, the sea's beasts, the
## boats and their hooks, then its stage bosses (StageRegistry.BOSS_ARRIVALS
## ids). Each Act X stage adds its own kinds as it is built (phase 2).
const CORSAIR_CREW: Array[String] = ["deckhand", "musketeer", "powder_runner", "swashbuckler", "boarding_bruiser"]
## The sea's beasts (rows "water").
const CORSAIR_SEA: Array[String] = ["reef_shark", "kraken_arm"]
## The boats and their grapple hooks (structures BoardingParty brings).
const CORSAIR_BOATS: Array[String] = ["skiff", "longboat", "raider_ship", "boarding_hook"]
## Black Tide stage bosses (StageRegistry.BOSS_ARRIVALS ids).
const CORSAIR_BOSSES: Array[String] = ["crow", "marrec", "vandermere"]
# --- Act XI (temporary): the Hall of the Slain ---
## The Hall of the Slain (GDD §15.0 "The Hall of the Slain foundation (phase
## 1)"; the Hall tab), GROUPED as NorseRulesData.GROUPS: the warriors of the
## hall, the hall's valkyries and seers with its stones and braziers, the cold
## things of the north, then its stage bosses (StageRegistry.BOSS_ARRIVALS ids).
## Each of its stages adds its own as it is built (phase 2).
const NORSE_WARRIORS: Array[String] = ["raider", "shield_maiden", "berserker", "skald"]
## The hall's kinds (group "hall"): the valkyries, the seers and the
## Rune-Stone (recorded when first taken: a stone is never slain). The brazier
## has no entry (it is the necromancer's warmth, not a foe).
const NORSE_HALL: Array[String] = ["valkyrie", "seer", "rune_stone",
	# --- Act XI (temporary): Vigrid --- (Odin's ravens)
	"odin_raven"]
## The cold things of the north (group "wilds").
const NORSE_WILDS: Array[String] = ["draugr", "wolf_of_the_wastes", "frost_giant", "fire_giant",
	# --- Act XI (temporary): Vigrid --- (the miniboss with its kin, as Act VIII placed Mammoth with the army; Fenrir beside the giants)
	"muspel_giant", "fenrir"]
## The Hall of the Slain's stage bosses (StageRegistry.BOSS_ARRIVALS ids).
const NORSE_BOSSES: Array[String] = ["hrimgar", "sigrun", "odin"]
# --- Act XII (temporary number): the Necropolis Dynasty ---
## The Necropolis Dynasty (GDD §15.0 "The Necropolis Dynasty foundation (phase
## 1)"; the Dynasty tab), GROUPED BY GROUP (DynastyRulesData.GROUPS): the
## wrapped dead, the sacred beasts, the guard, the priesthood, stone and jars,
## then its stage bosses (StageRegistry.BOSS_ARRIVALS ids). Each Dynasty stage
## adds its own as it is built (phase 2). The cartouche is no roster kind (no
## entry).
const DYNASTY_DEAD: Array[String] = ["mummy", "mummy_female"]
## The sacred beasts (group "beasts").
const DYNASTY_BEASTS: Array[String] = ["scarab_swarm"]
## The guard (group "guard").
const DYNASTY_GUARD: Array[String] = ["khopesh_guard"]
## The priesthood (group "priests").
const DYNASTY_PRIESTS: Array[String] = ["heka_priest", "embalmer"]
## Stone and jars (group "stone": the structures and, in phase 2, the statues).
const DYNASTY_STONE: Array[String] = ["canopic_jar"]
## Dynasty stage bosses (StageRegistry.BOSS_ARRIVALS ids).
const DYNASTY_BOSSES: Array[String] = ["anubis", "sekhmet", "osiris"]

## Section headers of each page: page id -> [[section id, header text], ...].
const SECTIONS: Dictionary = {
	"spells": [["spells", "Spells"], ["spell_evolutions", "Evolutions"]],  # TUNING (not in GDD)
	"summons": [["summons", "Summons"], ["summon_evolutions", "Evolutions"]],  # TUNING (not in GDD)
	"covenant": [["soldiers", "Soldiers"], ["structures", "Structures"], ["champions", "Champions"], ["bosses", "Bosses"]],  # TUNING (not in GDD)
	"eye": [["eye_soldiers", "Soldiers"], ["eye_champions", "Champions"], ["eye_bosses", "Bosses"]],  # TUNING (not in GDD) Act II
	"empire": [["empire_soldiers", "Soldiers"], ["empire_champions", "Champions"], ["empire_bosses", "Bosses"]],  # TUNING (not in GDD) Act III
	# --- Act IV: the Olympian Republic ---
	"pantheon": [["pantheon_soldiers", "Soldiers"], ["pantheon_champions", "Champions"], ["pantheon_bosses", "Bosses"]],  # TUNING (not in GDD) Act IV
	# --- Act V: the Shogunate of the Rising Sun ---
	"shogunate": [["shogunate_soldiers", "Soldiers"], ["shogunate_champions", "Champions"], ["shogunate_bosses", "Bosses"]],  # TUNING (not in GDD) Act V
	# --- Act VI: the Inferno ---
	"inferno": [["inferno_soldiers", "Soldiers"], ["inferno_champions", "Champions"], ["inferno_bosses", "Bosses"]],  # TUNING (not in GDD) Act VI
	# --- Act VII: the Sanguine Court ---
	"court": [["court_soldiers", "Soldiers"], ["court_champions", "Champions"], ["court_bosses", "Bosses"]],  # TUNING (not in GDD) Act VII
	# --- Act VIII: the Last Line (grouped by tier) ---
	"city": [["city_civilians", "Civilians"], ["city_gangs", "Gangs"], ["city_police", "Police"], ["city_swat", "SWAT and the Guard"],
		["city_army", "The Army"], ["city_heroes", "The Heroes"], ["city_bosses", "Bosses"]],  # TUNING (not in GDD) Act VIII
	# --- Act IX: the Concord of Stars (grouped by race) ---
	"concord": [["concord_brood", "The Brood"], ["concord_harvesters", "The Harvesters"], ["concord_vrask", "The Vrask"],
		["concord_luminous", "The Luminous"], ["concord_bosses", "Bosses"]],  # TUNING (not in GDD) Act IX
	# --- Act X: the Black Tide ---
	"corsair": [["corsair_crew", "The Brotherhood"], ["corsair_sea", "The Sea"], ["corsair_boats", "Boats"],
		["corsair_bosses", "Bosses"]],  # TUNING (not in GDD) Act X
	# --- Act XI (temporary): the Hall of the Slain (grouped by group) ---
	"norse": [["norse_warriors", "The Warriors"], ["norse_hall", "The Hall"], ["norse_wilds", "The North"],
		["norse_bosses", "Bosses"]],  # TUNING (not in GDD) the Norse act
	# --- Act XII (temporary number): the Necropolis Dynasty (grouped by group) ---
	"dynasty": [["dynasty_dead", "The Wrapped Dead"], ["dynasty_beasts", "Sacred Beasts"], ["dynasty_guard", "The Guard"],
		["dynasty_priests", "The Priesthood"], ["dynasty_stone", "Stone and Jars"], ["dynasty_bosses", "Bosses"]],  # TUNING (not in GDD) Act XII
}

## One-sentence descriptions of the Covenant (the enemy data has none),
## from the GDD rows each kind cites (GDD §7.2, §7.4, §8, §10, §11).
const DESCRIPTIONS: Dictionary = {
	"recruit": "Weak basic infantry that come in massed waves.",  # GDD §10
	"footman": "Armoured melee soldiers that shrug off part of every blow.",  # GDD §10
	"archer": "Zealous archers that loose arrows from range.",  # GDD §10
	"chaplain": "Covenant priests that heal their wounded allies.",  # GDD §10
	"purifier": "Holy fire-bearers that deal bonus damage to the undead.",  # GDD §10
	"templar": "Heavy knights that charge through the army's lines.",  # GDD §10
	"shieldbearer": "Tower-shield infantry that block projectiles from the front.",  # GDD §7.2
	"banner_bearer": "Standard-bearers whose banner strengthens nearby soldiers.",  # GDD §7.2
	"halberdier": "Slow, armoured soldiers whose sweeps cleave packed summons.",  # GDD §8.2
	"battle_sister": "Battle-nuns whose scourges lash past the front line, zealous when a comrade falls.",  # GDD §15.0 "Sister of the Scourge" (owner request)
	"sanctified_sentinel": "Stone constructs with flat armour and a sweeping strike.",  # GDD §7.2
	"radiant_inquisitor": "Inquisitors who lay holy ground and suppress the undead.",  # GDD §7.2
	"high_confessor": "Confessors who heal, shield allies and raise the fallen.",  # GDD §7.2
	"sun_paladin": "Paladins whose sun aura hardens the soldiers around them.",  # GDD §7.2
	"watchtower": "A checkpoint tower that sends soldiers until it falls.",  # GDD §8.2
	"outpost": "A siege camp that spawns reinforcements until it is razed.",  # GDD §7.4
	"ward_generator": "A holy engine whose zone weakens the undead nearby.",  # GDD §7.4
	"supply_cart": "A Covenant cart that pays a reward if it is stopped.",  # GDD §7.4
	"holy_standard": "Marshal Vael's war banner, a zone that buffs the Covenant.",  # GDD §7.5
	"ward_crystal": "Crystals that keep a sanctified chamber's holy ground alive.",  # GDD §7.4
	"sacred_altar": "Altars whose fall weakens every soldier sent afterwards.",  # GDD §7.4
	"inquisitor": "The Reckoning's executioners, sent once the countdown ends.",  # GDD §15.0 run structure
	"cathedral_guardian": "A giant stone guardian that slams the ground and sweeps a beam.",  # GDD §7.4
	"alaric": "The Gravebreaker, master of the Desecrated Graveyard.",  # GDD §11
	"vael": "The Crimson Bulwark, who holds the March behind her shieldwall.",  # GDD §7.5
	"seraphine": "The Voice of the Dawn, judge of the Sanctum.",  # GDD §7.5
	"eye_initiate": "Robed, slow cultists of the Ancient Eye who come in great crowds.",  # GDD §15.0 Act II
	"eye_chanter": "Leads a squad of Initiates; a summon that falls near it is claimed.",  # GDD §15.0 Act II Claims
	"drowned_thrall": "One of your own dead, claimed by the Eye. Free its soul.",  # GDD §15.0 Act II Claims
	# --- Act II: Gullhaven Harbour ---
	"deep_kin": "Scaled fisherfolk of the deep who leap onto your front rank and swim at full speed.",  # owner-approved roster
	"tide_caller": "Fishwives of the Eye who raise a line of water that throws your dead back.",  # owner-approved roster
	"netcaster": "Net-menders who pin one of your dead in place until the net is cut.",  # owner-approved roster
	"deep_herald": "What the deep sends once the countdown ends.",  # GDD §15.0 run structure (the Harbour's Reckoning)
	"harbourmaster": "A hulking Deep Kin who drags your dead in on a chained anchor.",  # owner-approved proposal
	"merrow": "The Voice of the Deep, Gullhaven's priest, halfway through his Change.",  # owner-approved proposal
	# --- Act II: the Hollow Archive ---
	"scribe": "Inks a curse on the cultists around it: a cursed cultist claims your dead.",  # GDD §15.0 Act II: the Hollow Archive
	"ink_wraith": "Slips through shelves and walls and rises out of the ink.",  # GDD §15.0 Act II: the Hollow Archive
	"spore_pilgrim": "Leaves spore clouds in its wake that fill your mind with dread.",  # GDD §15.0 Act II: the Hollow Archive
	"gibbering_mass": "A heaving tank that splits into smaller masses when it dies, twice.",  # GDD §15.0 Act II: the Hollow Archive
	"librarian": "A floating eye in tendrils whose slow beam turns your dead around.",  # GDD §15.0 Act II: the Hollow Archive
	"archivist": "The Keeper of the Unwritten, whose face is an open book.",  # GDD §15.0 Act II: the Hollow Archive
	"unwritten_one": "Page-wrapped horrors the Archive sends once the countdown ends.",  # GDD §15.0 Act II: the Hollow Archive (its Reckoning)
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"eye_siren": "A singer of the deep whose song lures your dead out of their ranks.",  # GDD §15.0 Siren of the Eye
	"eye_spawn": "A tentacled, armoured spawn that seizes one of your dead and holds it fast.",  # GDD §15.0 Spawn of the Deep
	"eye_hierophant": "An elite of the Eye whose Ascension turns it into a Spawn of the Deep.",  # GDD §15.0 Hierophant
	"eye_waking_horror": "The god's last surge when the countdown ends: the Waking.",  # GDD §15.0 the Waking
	"vhalneth": "The Dreaming Mother, dead god of the Eye. Raise her.",  # GDD §15.0 final boss
	# --- Act III: the Electronic Empire ---
	"scout_drone": "Swarms of fast chrome drones that fly over everything and zap what is close.",  # GDD §15.0 Act III foundation
	"line_trooper": "Rebuilt riflemen who march at you firing bursts; your dead are their cover.",  # GDD §15.0 Act III foundation (Line of Fire)
	"spotter": "Marksmen who paint a red line on their target, then fire a rail shot down it.",  # GDD §15.0 Act III foundation (Lock-On)
	"kill_drone": "The Purge Protocol's drones, sent from every edge once the countdown ends.",  # GDD §15.0 Act III foundation (Purge Protocol)
	"kestrel": "The Empire's sniper commander: she leaps between perches, paints three red lines at once and, cornered, draws twin blades.",  # Owner-approved Act III proposal
	"motherboard": "The mind that runs every machine of the Assembly Halls at once.",  # Owner-approved Act III proposal
	"deus_ex_machina": "The god the Empire built, with Varn, the Root User, at its controls.",  # Owner-approved Act III proposal
	# --- Act III: the Assembly Halls ---
	"arc_engineer": "Cyborg engineers who repair the machines around them and jam your dead with static.",  # Owner-approved Act III proposal
	"juggernaut": "Armoured flamethrower walkers whose plating shrugs off light blows.",  # Owner-approved Act III proposal
	"beta_build": "An unfinished mech that patches itself from every fabricator still standing.",  # Owner-approved Act III proposal
	# --- Act III: the Scrap Wastes ---
	"aegis_bot": "Shield bots that walk in front of the riflemen; their shields stop your shots, so hit them from the side.",  # Owner-approved Act III proposal
	"mortar_walker": "Four-legged walkers that lob shells onto red circles over your army's heads: keep moving.",  # Owner-approved Act III proposal
	"trojan_horse": "A drone tank whose slow rockets your dead can intercept; broken open, it spills a swarm of drones.",  # Owner-approved Act III proposal
	# --- Act III: the Iron Citadel ---
	"valkyrie_duelist": "Jet-armoured duellists who lunge through your ring with an arm blade; a blocker stops them.",  # Owner-approved Act III proposal
	"sentry_turret": "Fixed gun emplacements behind the shield walls; siege them for a Soul Ash bounty.",  # Owner-approved Act III proposal
	"shield_generator": "Two hold up each Shield Gate; while they stand the wall bars your way.",  # Owner-approved Act III proposal
	"valkyrie_prime": "The Duelists' upgraded leader: a jet dash, a shield bash and a storm of blades.",  # Owner-approved Act III proposal (Valkyrie 2.0)
	# --- Act IV: the Olympian Republic ---
	"shade_of_dead": "Pale ghosts fleeing the Underworld: weak and fast, they come in swarms.",  # Owner-approved Act IV proposal
	"hoplite": "Spear and round shield. Three side by side lock shields: break the wall from the flanks.",  # Owner-approved Act IV proposal (Phalanx)
	"hero": "Named demigods who grow in Glory with every one of your dead they kill. Kill them early.",  # Owner-approved Act IV proposal (Glory)
	"bronze_titan": "Bronze colossi that step out of the ground when the gods' twilight falls.",  # Owner-approved Act IV proposal (Twilight of the Gods)
	"achilles": "The Unkillable: his front shrugs off nearly every blow. Strike his heel.",  # Owner-approved Act IV proposal
	"zeus": "King of the Gods: lightning storms, the thunderbolt beam, and at the last his true colossal form.",  # Owner-approved Act IV proposal
	"hades": "Lord of the Dead, who sent the gods to take the dead back. The first rival necromancer.",  # Owner-approved Act IV proposal
	# --- Act IV: the Shores of Ilion ---
	"legionary": "Scutum and gladius. Locked together they raise the testudo: arrows glance off, blades and stomps do not.",  # Owner-approved Act IV proposal
	"wolf_of_rome": "Bronze wolves come alive, hunting in packs of five with fast lunges. Hold them on your blockers.",  # Owner-approved Act IV proposal
	"cyclops": "One-eyed giants who hurl boulders onto red circles. Their stony hide shrugs off small blows.",  # Owner-approved Act IV proposal
	"siege_tower": "Towers rolling for the walls of Troy. Burn one for its bounty; let it arrive and its garrison marches out.",  # Owner-approved Act IV proposal
	"polyphemus": "Chieftain of the cyclopes: boulders rain on red circles and his stomp shakes the shore.",  # Owner-approved Act IV proposal
	# --- Act IV: Mount Olympus ---
	"centaur_archer": "Bronze-clad centaurs that shoot as they gallop straight at you. Kill them on approach.",  # Owner-approved Act IV proposal
	"amazon": "Warrior women with axe and crescent shield who leap over your front row; a heavy blocker catches them.",  # Owner-approved Act IV proposal
	"gorgon": "Snake-haired women whose gaze turns your dead to stone for a few seconds. Kill them first.",  # Owner-approved Act IV proposal
	"moon_hound": "Artemis's hunting pack: lean, silver and fast.",  # TUNING (not in GDD)
	"sea_serpent": "Poseidon's great sea snake: it lunges down a marked line.",  # Owner-approved Act IV proposal ("a sea serpent")
	"ares": "The god of war: his war-cry drives every soldier on, his spear charge breaks on a blocker.",  # Owner-approved Act IV proposal
	"artemis": "The Huntress: moonlit volleys, her hounds, and a step from grove to grove.",  # Owner-approved Act IV proposal
	"poseidon": "The Lord of the Sea: he floods half the field, throws his trident, and calls a sea serpent.",  # Owner-approved Act IV proposal
	# --- Act IV: the Asphodel Underworld ---
	"shade_hoplite": "The dead of a thousand wars, still in their ranks. They lock shields like the living.",  # TUNING (not in GDD)
	"shade_archer": "Troy's archers, still drawing their bows in the dark. They shoot over your army's ring: kill them on approach.",  # TUNING (not in GDD)
	"cerberus": "The three-headed hound of the gates. His body cannot be wounded: kill each head on its own.",  # Owner-approved Act IV proposal
	"tartarus_warden": "Hades' own ring of the dead. While it stands, its lord is all but untouchable.",  # Owner-approved Act IV proposal (Lord of the Dead)
	# --- Act V: the Shogunate of the Rising Sun ---
	"ashigaru": "Spear levies of the Shogunate, marching in wide ranks by day.",  # Owner-approved Act V proposal
	"samurai": "Katana duelists. Their elites stop, hand on the hilt, and draw: step out of the white line.",  # Owner-approved Act V proposal (the Draw)
	"teppo_gunner": "Arquebus lines that fire as one volley every few seconds. Rush them while they reload.",  # Owner-approved Act V proposal
	"ninja": "They never walk in from the edge: a puff of smoke in a shadow, and they are among your dead.",  # Owner-approved Act V proposal (From the Shadows)
	"onryo": "Vengeful ghosts of the night that drift through walls and through your ring.",  # Owner-approved Act V proposal
	"oni": "Ogres of the old stories who walk at night. The iron club stuns whatever it lands on.",  # Owner-approved Act V proposal
	"kage": "Mistress of the Hidden Hand, the ninja grandmaster: shadow clones, smoke and chained kunai.",  # Owner-approved Act V proposal
	"shogun": "Shogun Kurogane: his army is his strength. Break his regiments and he draws his own blade.",  # Owner-approved Act V proposal
	"amaterasu": "The sun goddess herself. Her place in the sky is the battle; when she falls, the sun goes out.",  # Owner-approved Act V proposal
	# --- Act V: the Burning Province ---
	"kunoichi": "Ninja elites out of the shadows. Their smoke bombs blind your dead; then they lunge at you.",  # Owner-approved Act V proposal
	"kappa": "River imps of the paddies that walk at night. The water never slows them, and they grab your dead.",  # Owner-approved Act V brief
	"shuten_doji": "The Oni King, drunk and enormous. His sake barrels burst into fire where they land.",  # Owner-approved Act V proposal
	# --- Act V: the Road to the Sun ---
	"sohei": "Warrior monks of the sun's shrines. The naginata sweeps a wide arc: step out of it.",  # TUNING (not in GDD)
	"kitsune": "Fox spirits of the night. Their fox-fire copies draw your dead's blows; light or area damage reveals them.",  # Owner-approved Act V proposal
	"kirin": "A holy beast of light that walks the road to the sun. Its gallop and its horn's rays burn the dead.",  # Owner-approved Act V proposal
	# --- Act V: Castle Kurogane ---
	"hatamoto": "Banner guards of the Shogun. While one stands, the soldiers near him fight harder. Kill the banner.",  # Owner-approved Act V proposal
	"kiba_musha": "Mounted samurai who rein in, then charge down a lane: step aside, or let the horse ride through your dead.",  # Owner-approved Act V proposal
	"general_left": "The General of the Left charges straight through your ring on his black war horse and calls his riders.",  # Owner-approved Act V proposal
	# --- Act VI: the Inferno ---
	"damned": "Chained, wailing souls dragged to the Pit. They burn in the pits like anything living: lead them through.",  # Owner-approved Act VI proposal
	"imp": "Small winged demons with pitchforks. They fly over the pits and never burn.",  # Owner-approved Act VI proposal
	"hell_knight": "Knights in ember armour with burning greatswords. Step out of the blade's sweep.",  # Owner-approved Act VI proposal
	"succubus": "Her kiss turns one of your dead to fight for hell for a few seconds. Kill her and her charms break.",  # Owner-approved Act VI proposal (Temptation)
	"demon_portal": "A gate of the Pit that pours out demons. Break it, or stand in its ring to seal it for Soul Ash.",  # Owner-approved Act VI proposal (Portals)
	"demon_brute": "A four-armed demon whose ground slam throws your dead aside. Its hide shrugs off small blows.",  # Owner-approved Act VI proposal
	"moloch": "The Furnace King, a colossal bull-headed demon. He swallows your dead and cracks the ground into pits.",  # Owner-approved Act VI proposal
	"lilith": "Queen of the Night, Mother of Demons. Her charm turns a whole arc of your ring.",  # Owner-approved Act VI proposal
	"morning_star": "The Adversary himself: first the Angel with six burnt wings, then the Beast.",  # Owner-approved Act VI proposal (two phases, owner Oct 26)
	# --- Act VI: the Burning Gate ---
	"lava_hound": "Hellhounds of lava and black crust. They run in packs and leave a trail of fire behind them.",  # Owner-approved Act VI proposal
	"pit_cultist": "Living men who serve the Pit. Their rite tears a demon portal open: kill them before it is done.",  # Owner-approved Act VI proposal
	"gatekeeper": "A chained giant of the gate. His chains drag your dead to his fists and the damned into his maw.",  # Owner-approved Act VI proposal
	# --- Act VI: the Palace of Silk and Ash ---
	"lilim_witch": "A demon sorceress of Lilith's court. She opens pits under your ring and heals the demons at a portal.",  # Owner-approved Act VI proposal
	"twin_naamah": "The elder of the Twin Succubi. The sisters charm in turns; kill one and the other rages.",  # Owner-approved Act VI proposal
	"twin_agrat": "The younger of the Twin Succubi, quicker than her sister, and as cruel.",  # TUNING (not in GDD)
	# --- Act VI: Pandemonium ---
	"fallen_angel": "She dives from above with a burning spear. Aloft, your blades barely reach her: gargoyles and ranged dead answer her.",  # Owner-approved Act VI proposal ("Gargoyles, ranged")
	"seraph_general": "A fallen archangel warlord with four burnt wings. His cleave cracks the ground; at half strength he calls the Fallen Host.",  # Owner-approved Act VI proposal (the miniboss)
	# --- Act VII: the Sanguine Court ---
	"blood_thrall": "Bitten servants of the Court, pale and slow. Every bite they land heals them a little.",  # Owner-approved Act VII proposal
	"vampire_bat": "Swarms of bats that fly over your ring and swoop down to bite. In the air only fliers, arrows and spells reach them.",  # Owner-approved Act VII proposal (Night Wings)
	"blood_knight": "Vampire knights in blood-red plate. Every blow feeds them: Rot and Wither halve it.",  # Owner-approved Act VII proposal (Bloodfeast)
	"werewolf": "A hunter with a silver crossbow, until the Blood Moon or his wounds turn him into a huge, lunging beast.",  # Owner-approved Act VII proposal
	"vampire_noble": "The Countess drains your dead from afar with a beam of blood. Wounded, she turns to mist and reforms closer.",  # Owner-approved Act VII proposal
	"court_coffin": "A sealed coffin of the Court. Under the endless moon it opens, and a noble climbs out.",  # Owner-approved Act VII proposal (the Endless Feast)
	"vargr": "Vargr, the Moon-Eater: the werewolf king, who calls his own Blood Moon and swallows it.",  # Owner-approved Act VII proposal
	"isolde": "Isolde Vane, the Witch of the Red Moon: hex circles, cauldron bombs and three sisters who must fall together.",  # Owner-approved Act VII proposal
	"carmilla": "Queen Carmilla, who dances through your ring in mist and feeds the Elder in his coffin.",  # Owner-approved Act VII proposal
	# --- Act VII: Ravensmoor ---
	"ghoul": "Grey corpse-eaters in packs of four. They stop to eat your fallen foes, healing as they eat, and leave nothing to raise.",  # Owner-approved Act VII proposal
	"old_greymane": "The pack's alpha. His howl turns every werewolf near him into the beast, moon or not.",  # Owner-approved Act VII proposal
	# --- Act VII: the Witchwood ---
	"crimson_witch": "Witches of the Court. In covens of three they draw a hex circle that heals the Court and drains your dead: kill one and it fails.",  # Owner-approved Act VII proposal
	"bloated_thrall": "A thrall swollen with blood. It bursts into a pool that heals the Court: kill it away from the knights.",  # Owner-approved Act VII proposal
	"hex_stone": "A standing stone carved with the witches' runes. It powers the covens' circles; broken, no coven casts near it.",  # Owner-approved Act VII proposal
	"bog_mother": "A vast drowned witch of the fen. Her weed-ropes drag your dead into her black water to drown.",  # Owner-approved Act VII proposal
	# --- Act VII: Castle Sanguis ---
	"chiropteran": "Bat-folk who glide over your ring. Their shriek stuns your dead in a cone: step out of it.",  # Owner-approved Act VII proposal
	"blood_bearer": "Thralls with chalices who carry blood to their kneeling Queen. Kill them before they reach her.",  # Owner-approved Act VII proposal ("the thralls that bring her blood")
	"chiropteran_king": "A giant bat-man who seizes your dead, flies them off over the ring and drops them outside it.",  # Owner-approved Act VII proposal (the miniboss)
	# --- Act VIII: the Last Line ---
	"civilian": "The living of the last city, running from your dead. They never fight back, and each one you catch is XP.",  # Owner answer Oct 31, 2026 (Civilians)
	"street_thug": "The gangs who own the blocks: bats and pipes, in crowds.",  # Owner-approved Act VIII proposal
	"gang_gunner": "Two pistols sprayed from the hip as he walks in: poor aim, a lot of bullets. Blockers soak it.",  # Owner-approved Act VIII proposal
	"riot_cop": "Riot shields in a line. From the front the shield takes most of a blow: flank them.",  # Owner-approved Act VIII proposal (Armour)
	"squad_car": "A police car that drives its lane through your ring. Its headlights show where it will be: get out of the way.",  # Owner-approved Act VIII proposal (Armour)
	"swat_breacher": "Flashbangs that stun your dead for a moment, and a shotgun up close. Kill them first.",  # Owner-approved Act VIII proposal
	"field_medic": "She patches up the soldiers around her. A priority target.",  # Owner-approved Act VIII proposal
	"rifleman": "Rifle squads of four, firing short bursts as they advance. Area damage breaks them.",  # Owner-approved Act VIII proposal
	"tank": "Armoured in front, shells with a landing circle, and it drives over your ring. Let it ram a wreck.",  # Owner-approved Act VIII proposal (Armour)
	"blitz": "A speedster who dashes through your ring. Fast, but he can't turn: a wall, a wreck or a blocker stops him cold.",  # Owner-approved Act VIII proposal (Supers)
	"don_marrow": "Don Marrow, the Kingpin: a bounty on your head, a call to the police, and a gold-plated minigun behind his limousine's armour.",  # Owner-approved Act VIII proposal
	"harrow": "General Vance Harrow, the Hammer: carpet bombing, a tank column, and Broken Arrow, a strike on his own position.",  # Owner-approved Act VIII proposal
	"paragon": "Paragon, the Last Hero: the strongest man alive, and every hero still standing flies to his side.",  # Owner-approved Act VIII proposal
	# --- Act VIII: Skid Row ---
	"armoured_limo": "Big Sal's armoured limousine rams your ring while his crew sprays pistols from both windows. Its front is armoured: hit it from the side.",  # Owner-approved Act VIII proposal (miniboss)
	"big_sal": "The gangs' enforcer, who climbs out of his burning limo with a sledgehammer. Step out of its swing.",  # Owner-approved Act VIII proposal (miniboss)
	# --- Act VIII: Fort Kessler ---
	"machine_gunner": "He sets up his gun and sweeps a fire lane across your ring. Step out of the lane, or put a Bone Wall in it.",  # Owner-approved Act VIII proposal
	"attack_helicopter": "Strafing runs down the street and rocket pods ahead of it. Swords can barely reach it: Gargoyles, Archers and spells bring it down.",  # Owner-approved Act VIII proposal
	"mammoth": "A super-heavy tank with two turrets. Its front shrugs off blows; hit it from the side, and it burns into the biggest wreck in the city.",  # Owner-approved Act VIII proposal
	# --- Act VIII: Liberty Heights ---
	"atlas": "A strongman who lifts wrecks and throws them at you. Strong, but slow to throw: stun him while he winds up.",  # Owner-approved Act VIII proposal (Supers)
	"aurora": "A flier who rains energy blasts on your ring. Any stun drops her out of the sky, and she is open until she rises.",  # Owner-approved Act VIII proposal (Supers)
	"nightjar": "A vigilante who grapples your dead out of the ring. He must land to strike: hold him there with a blocker.",  # Owner-approved Act VIII proposal (Supers)
	"conscript": "Young Guardsmen with bayonets, sent in crowds to hold the heart of the city.",  # TUNING (not in GDD) Liberty Heights's army fodder
	# --- Act IX: the Concord of Stars ---
	"broodling": "Small, fast insects of the Brood, in swarms of twelve. Anything kills them; there are just so many.",  # Owner-approved Act IX proposal
	"grey_drone": "Small greys in squads. A magenta line from a probe is a beam about to fire: step out of it.",  # Owner-approved Act IX proposal (Beams)
	"saucer": "It hovers over your ring and lifts your dead in a tractor beam. Shoot it down before they are gone.",  # Owner-approved Act IX proposal (Abduction)
	"concord_terraformer": "A landing pod that roots and grows alien ground. The Concord heals on it; your spells burn it back.",  # Owner answer Oct 31, 2026 (Terraforming)
	"vrask_hunter": "A hunter who shimmers as it moves, then locks three red dots on its prey. Your spells reveal it.",  # Owner-approved Act IX proposal
	"lumen_sentinel": "A being of light whose beams sweep your ring. Its shield soaks the first blows; reflect its beams back at it.",  # Owner-approved Act IX proposal
	"prism": "The Star-Seer. A beam that passes through her splits into three: kill her before the beams line up.",  # Owner-approved Act IX proposal
	"hive_mother": "The Hive Mother, the Brood's queen grown into the crater: egg waves, a burrow under your ring, and acid from the sky.",  # Owner-approved Act IX proposal
	"vrask_tal": "Vrask'Tal, the Hunt-Lord: he stalks your ring cloaked, duels you with his glaive, and arms the bomb on his wrist.",  # Owner-approved Act IX proposal
	"harvester": "The Harvester, the oldest of its kind: the one who planted the world, come to reap what is left.",  # Owner-approved Act IX proposal
	# --- Act X: the Black Tide ---
	"deckhand": "Cutlass mobs of the Brotherhood, pouring off the boats in streams. Meet them at the rail.",  # Owner-approved Act X proposal
	"musketeer": "A gunman of the Brotherhood. Ordinary shot, from the boats and then the deck: Archers answer him.",  # Owner-approved Act X proposal
	"powder_runner": "He sprints with a lit keg. Kill him at range, and the blast throws his own crew over the rail.",  # Owner-approved Act X proposal
	"swashbuckler": "A duellist whose rapier lunge jumps your first blocker. Rogues, Gargoyles and area damage end her.",  # Owner-approved Act X proposal
	"boarding_bruiser": "An axeman in a leather apron, flat armour 3. Wither him, or push him overboard.",  # Owner-approved Act X proposal
	"reef_shark": "It circles the hull and leaps into your ring. Hit it at the leap; on the deck, knock it back into the sea.",  # Owner-approved Act X proposal
	"kraken_arm": "A tentacle from below that drags one of your dead overboard. Kill it while it is above the water.",  # Owner-approved Act X proposal
	"skiff": "A small boat of six. Cut both grapple hooks and it drifts off; sink it and its crew drowns.",  # Owner-approved Act X proposal (Boarding)
	"longboat": "A boat of twelve. Ranged summons, spells and fliers sink it; your Warriors cut its hooks.",  # Owner-approved Act X proposal (Boarding)
	"raider_ship": "A raider of twenty-four with two planks. Sink it before its whole crew is aboard.",  # Owner-approved Act X proposal (Boarding)
	"boarding_hook": "A grapple biting the rail. Cut both hooks of a boat and it drifts away with its crew.",  # Owner-approved Act X proposal (Boarding)
	"crow": "Captain Ezekiel Crow, the Gull King: broadsides, a cutlass duel, and his own ship set ablaze.",  # Owner-approved Act X proposal
	"marrec": "Admiral Isabeau Marrec, the Sea Wolf: her fleet, the boarding plank and cursed gold.",  # Owner-approved Act X proposal
	"vandermere": "Captain Cornelius Vandermere, lashed to the wheel of the Hollow Queen behind an oath only the dead can break.",  # Owner-approved Act X proposal
	# --- Act XI (temporary): the Hall of the Slain ---
	"raider": "Raiders with axe and round shield, come south in crowds. Anything cuts them down.",  # Owner-approved proposal (LAST_SIX_ACTS.md)
	"shield_maiden": "A shield-maiden: her shield bash throws one of your dead out of the ring. Flank her.",  # Owner-approved proposal
	"berserker": "A berserker in a bear pelt, always in the fury: faster, harder, and no slow or stun holds him. Burst him down.",  # Owner-approved proposal (Berserkergang)
	"skald": "A skald whose war-song makes the warriors near him strike faster. Kill him first.",  # Owner-approved proposal
	"valkyrie": "A valkyrie who dives on your ring with her spear. Aloft, only arrows, fliers and spells reach her.",  # Owner-approved proposal (Night Wings)
	"seer": "A seer who douses your braziers, re-carves the rune-stones you take and curses one of your dead blind.",  # Owner decision Nov 7, 2026 (the Long Winter) and the proposal
	"rune_stone": "A carved stone that wards the warriors near it and calls them with its horn. Stand by it with your army to take it.",  # Owner-approved proposal (Rune-Stones)
	"draugr": "Barrow-dead in rusted mail. Their armour turns light blows, and their touch chills your dead.",  # Owner-approved proposal
	"wolf_of_the_wastes": "Wolves in packs of five that lunge at the ring. Blockers hold them.",  # Owner-approved proposal
	"frost_giant": "A frost giant: its boulders fall where a circle shows, it stamps your ring away and douses your braziers.",  # Owner-approved proposal and the Long Winter
	"fire_giant": "A fire-giant of the south, come to burn the last field.",  # Owner-approved proposal (Ragnarok)
	"hrimgar": "Hrimgar the Draugr-King, who rises from his barrow three times unless you break it.",  # Owner-approved proposal
	"sigrun": "Sigrun, the Shield-Queen, captain of the valkyries: she charges your ring and calls you to a duel.",  # Owner-approved proposal
	"odin": "Odin, the one-eyed god, and Fenrir the wolf, come for the army the world promised them.",  # Owner-approved proposal
	# --- Act XI (temporary): Vigrid ---
	"muspel_giant": "A fire-giant of the south, out of Muspell before his time: his footprints burn, and his stomp sets the ground alight.",  # Owner-approved proposal (miniboss)
	"fenrir": "Fenrir, the great wolf, his chain broken at last: he swallows one of your dead whole and spits it out four seconds later.",  # Owner-approved proposal
	"odin_raven": "One of Odin's ravens. If it reaches you, it marks you for the All-Father's spear. Shoot it down.",  # Owner-approved proposal
	# --- Act IX: the Crash Site ---
	"burrower": "It tunnels under your ring and bursts up among your dead. A mound of dirt shows a moment ahead: keep blockers inside the ring.",  # Owner-approved Act IX proposal
	"acid_spitter": "It lobs acid over your ring that leaves a burning puddle. Kill it on approach, and step out of the green.",  # Owner-approved Act IX proposal
	"brood_matriarch": "The Brood's winged queen-guard, who spits egg sacs over your ring. Clear her eggs before they hatch.",  # Owner-approved Act IX proposal (miniboss)
	# --- Act IX: the Proving Moon ---
	"warbeast": "The Vrask's armoured hound. It crouches, then pounces over your ring onto you, and the moon's low gravity throws your dead far. Its plates shrug off weak blows.",  # Owner-approved Act IX proposal
	# --- Act IX: the Ark ---
	"grey_overseer": "A tall grey whose psionic pulse stuns your dead and whose will shields the greys round it. Kill it first.",  # Owner-approved Act IX proposal
	"luminous_archon": "A being of pure light: every blow it strikes is a beam. Catch them on your Orb Shield and barriers and send them back.",  # Owner-approved Act IX proposal
	"specimen_tank": "A sealed tank in the Ark's vaults. Break it, and the beast inside attacks everyone near it.",  # Owner-approved Act IX proposal
	"vault_beast": "A beast the Concord harvested from some dead world. Freed, it bites whatever is nearest: your dead, you, or its keepers.",  # Owner-approved Act IX proposal
	"reactor_vent": "A vent of the Ark's reactor that breathes alien ground on a timer. Break it to stop it.",  # TUNING (not in GDD) brief
	"reap_emitter": "One of the Harvester's emitters: its tractor beam lifts your dead from the ring. Destroy them all to end the Reaping.",  # Owner-approved Act IX proposal
	# --- Act XII (temporary number): the Necropolis Dynasty ---
	"mummy": "The wrapped dead. A fallen mummy's Name waits over it: smash it or raise it, or it stands again. Fire burns them well.",  # Proposal (Rebirth)
	"mummy_female": "The wrapped dead, quicker on her feet. Her Name waits over her too: smash it or raise it before she returns.",  # Proposal (Rebirth)
	"scarab_swarm": "A swarm of sacred beetles that tears through your Warders' barriers. Beasts do not return.",  # Proposal
	"khopesh_guard": "A tomb guard with curved blades: when he plants his feet, he spins. He returns unless you take his Name.",  # Proposal (Rebirth)
	"heka_priest": "He writes a glyph on one of your dead, and it runs around your ring. A Mender's heal or a Warder's barrier clears it.",  # Proposal (Heka)
	"embalmer": "She heals the Dynasty's soldiers and hastens every Name near her. Kill her first.",  # Proposal (Rebirth)
	"canopic_jar": "A jar that holds the Names of the dead near it: no blow reaches them. Break it, and they return no more.",  # Proposal (Rebirth)
	"anubis": "Anubis, Opener of the Way: he leads the procession of the dead, embalms the fallen, then duels you as the jackal.",  # Proposal
	"sekhmet": "Sekhmet, the Lioness of Retribution: she leaps between the pillars, calls the Red Wind, and feasts in her fury.",  # Proposal
	"osiris": "Osiris, Lord of the Dead, judges you on the great scales; Ammit the Devourer waits at his feet.",  # Proposal
}

## Sprite key of an entry whose art is not "<category folder>/<id>":
## entry id -> SpriteBank key ("" = draw its icon instead).
const SPRITE_KEYS: Dictionary = {
	"profane_bishop": "summons/bishop",
	"inquisitor": "enemies/inquisitor",
	# --- Act II: Gullhaven Harbour (the Ancient Eye's art is in eye/) ---
	"deep_kin": "eye/deep_kin",
	"tide_caller": "eye/tide_caller",
	"netcaster": "eye/netcaster",
	"deep_herald": "eye/deep_herald",
	"harbourmaster": "eye/harbourmaster",
	# --- Act IV: the Asphodel Underworld --- (the Underworld's dead wear the Hoplite's art)
	"shade_hoplite": "pantheon/hoplite",
	"tartarus_warden": "pantheon/hoplite",
}

## Stat labels and record lines of the detail panel (format strings use
## %s / %d).
const TEXT: Dictionary = {
	"hp": "Base HP",  # TUNING (not in GDD)
	"damage": "Damage",  # TUNING (not in GDD)
	"speed": "Speed",  # TUNING (not in GDD)
	"armour": "Armour",  # TUNING (not in GDD)
	"recipe": "Recipe",  # TUNING (not in GDD)
	"stage": "Stage",  # TUNING (not in GDD)
	"arrives": "Arrives",  # TUNING (not in GDD)
	"arrives_at": "with %d:%02d left",  # TUNING (not in GDD) minutes, seconds of the countdown
	"slain": "Slain: %s",  # TUNING (not in GDD)
	"destroyed": "Destroyed: %s",  # TUNING (not in GDD)
	"best_level": "Best level reached: %d",  # TUNING (not in GDD)
	"skin_reward": "%s skin (%s)",  # TUNING (not in GDD) skin name, character name
}
## Lines on the detail panel of a locked entry, per page.
const LOCKED_HINT: Dictionary = {
	"spells": "Learn it in a run to record it.",  # TUNING (not in GDD)
	"summons": "Raise it in a run to record it.",  # TUNING (not in GDD)
	"soldiers": "Slay one to record it.",  # TUNING (not in GDD)
	"structures": "Destroy one to record it.",  # TUNING (not in GDD)
	"champions": "Slay one to record it.",  # TUNING (not in GDD)
	"bosses": "Face it to record it.",  # TUNING (not in GDD)
	"eye_soldiers": "Slay one to record it.",  # TUNING (not in GDD)
	"eye_champions": "Slay one to record it.",  # TUNING (not in GDD)
	"eye_bosses": "Face it to record it.",  # TUNING (not in GDD)
	"empire_soldiers": "Destroy one to record it.",  # TUNING (not in GDD)
	"empire_champions": "Destroy one to record it.",  # TUNING (not in GDD)
	"empire_bosses": "Face it to record it.",  # TUNING (not in GDD)
	"pantheon_soldiers": "Slay one to record it.",  # TUNING (not in GDD) Act IV
	"pantheon_champions": "Slay one to record it.",  # TUNING (not in GDD) Act IV
	"pantheon_bosses": "Face it to record it.",  # TUNING (not in GDD) Act IV
	"shogunate_soldiers": "Slay one to record it.",  # TUNING (not in GDD) Act V
	"shogunate_champions": "Slay one to record it.",  # TUNING (not in GDD) Act V
	"shogunate_bosses": "Face it to record it.",  # TUNING (not in GDD) Act V
	"inferno_soldiers": "Slay one to record it.",  # TUNING (not in GDD) Act VI
	"inferno_champions": "Slay one to record it.",  # TUNING (not in GDD) Act VI
	"inferno_bosses": "Face it to record it.",  # TUNING (not in GDD) Act VI
	# --- Act VII: the Sanguine Court ---
	"court_soldiers": "Slay one to record it.",  # TUNING (not in GDD) Act VII
	"court_champions": "Slay one to record it.",  # TUNING (not in GDD) Act VII champions
	"court_bosses": "Face it to record it.",  # TUNING (not in GDD) Act VII bosses
	# --- Act VIII: the Last Line ---
	"city_civilians": "Catch one to record it.",  # TUNING (not in GDD) Act VIII
	"city_gangs": "Slay one to record it.",  # TUNING (not in GDD) Act VIII gangs
	"city_police": "Slay one to record it.",  # TUNING (not in GDD) Act VIII police
	"city_swat": "Slay one to record it.",  # TUNING (not in GDD) Act VIII SWAT
	"city_army": "Slay one to record it.",  # TUNING (not in GDD) Act VIII army
	"city_heroes": "Slay one to record it.",  # TUNING (not in GDD) Act VIII heroes
	"city_bosses": "Face it to record it.",  # TUNING (not in GDD) Act VIII bosses
	# --- Act IX: the Concord of Stars ---
	"concord_brood": "Slay one to record it.",  # TUNING (not in GDD) Act IX
	"concord_harvesters": "Slay one to record it.",  # TUNING (not in GDD) Act IX Harvesters
	"concord_vrask": "Slay one to record it.",  # TUNING (not in GDD) Act IX Vrask
	"concord_luminous": "Slay one to record it.",  # TUNING (not in GDD) Act IX Luminous
	"concord_bosses": "Face it to record it.",  # TUNING (not in GDD) Act IX bosses
	# --- Act X: the Black Tide ---
	"corsair_crew": "Slay one to record it.",  # TUNING (not in GDD) Act X
	"corsair_sea": "Slay one to record it.",  # TUNING (not in GDD) Act X
	"corsair_boats": "Sink one to record it.",  # TUNING (not in GDD) Act X
	"corsair_bosses": "Face it to record it.",  # TUNING (not in GDD) Act X bosses
	# --- Act XI (temporary): the Hall of the Slain ---
	"norse_warriors": "Slay one to record it.",  # TUNING (not in GDD) the Norse act
	"norse_hall": "Slay or take one to record it.",  # TUNING (not in GDD) the Norse act (a stone is taken)
	"norse_wilds": "Slay one to record it.",  # TUNING (not in GDD) the Norse act
	"norse_bosses": "Face it to record it.",  # TUNING (not in GDD) the Norse act bosses
	# --- Act XII (temporary number): the Necropolis Dynasty ---
	"dynasty_dead": "Slay one to record it.",  # TUNING (not in GDD) Act XII
	"dynasty_beasts": "Slay one to record it.",  # TUNING (not in GDD) Act XII beasts
	"dynasty_guard": "Slay one to record it.",  # TUNING (not in GDD) Act XII guard
	"dynasty_priests": "Slay one to record it.",  # TUNING (not in GDD) Act XII priests
	"dynasty_stone": "Break one to record it.",  # TUNING (not in GDD) Act XII stone
	"dynasty_bosses": "Face it to record it.",  # TUNING (not in GDD) Act XII bosses
	"evolution": "Undiscovered.",  # TUNING (not in GDD) owner rule: no hint
}
## Name shown for a locked entry.
const LOCKED_NAME: String = "Unknown"  # TUNING (not in GDD)
## Name shown for an undiscovered evolution.
const LOCKED_EVOLUTION: String = "???"  # TUNING (not in GDD)
## Tag line (LABEL tier) of each section's entries on the detail panel.
const TAGS: Dictionary = {
	"spells": "Spell",  # TUNING (not in GDD)
	"spell_evolutions": "Spell evolution",  # TUNING (not in GDD)
	"summons": "Summon class",  # TUNING (not in GDD)
	"summon_evolutions": "Summon evolution",  # TUNING (not in GDD)
	"soldiers": "Covenant soldier",  # TUNING (not in GDD)
	"structures": "Covenant structure",  # TUNING (not in GDD)
	"champions": "Champion",  # TUNING (not in GDD)
	"bosses": "Stage boss",  # TUNING (not in GDD)
	"eye_soldiers": "Ancient Eye",  # TUNING (not in GDD)
	"eye_champions": "Champion of the Eye",  # TUNING (not in GDD)
	"eye_bosses": "Stage boss",  # TUNING (not in GDD)
	"empire_soldiers": "Electronic Empire",  # TUNING (not in GDD)
	"empire_champions": "Champion of the Empire",  # TUNING (not in GDD)
	"empire_bosses": "Stage boss",  # TUNING (not in GDD)
	"pantheon_soldiers": "Olympian Republic",  # TUNING (not in GDD) Act IV
	"pantheon_champions": "Champion of the Republic",  # TUNING (not in GDD) Act IV
	"pantheon_bosses": "Stage boss",  # TUNING (not in GDD) Act IV
	"shogunate_soldiers": "Shogunate of the Rising Sun",  # TUNING (not in GDD) Act V
	"shogunate_champions": "Champion of the Shogunate",  # TUNING (not in GDD) Act V
	"shogunate_bosses": "Stage boss",  # TUNING (not in GDD) Act V
	"inferno_soldiers": "The Inferno",  # TUNING (not in GDD) Act VI
	"inferno_champions": "Champion of the Pit",  # TUNING (not in GDD) Act VI
	"inferno_bosses": "Stage boss",  # TUNING (not in GDD) Act VI
	# --- Act VII: the Sanguine Court ---
	"court_soldiers": "The Sanguine Court",  # TUNING (not in GDD) Act VII
	"court_champions": "Champion of the Court",  # TUNING (not in GDD) Act VII champions
	"court_bosses": "Stage boss",  # TUNING (not in GDD) Act VII bosses
	# --- Act VIII: the Last Line ---
	"city_civilians": "The last city",  # TUNING (not in GDD) Act VIII
	"city_gangs": "The gangs",  # TUNING (not in GDD) Act VIII gangs
	"city_police": "The police",  # TUNING (not in GDD) Act VIII police
	"city_swat": "SWAT and the Guard",  # TUNING (not in GDD) Act VIII SWAT
	"city_army": "The army",  # TUNING (not in GDD) Act VIII army
	"city_heroes": "Super",  # TUNING (not in GDD) Act VIII heroes
	"city_bosses": "Stage boss",  # TUNING (not in GDD) Act VIII bosses
	# --- Act IX: the Concord of Stars ---
	"concord_brood": "The Brood",  # TUNING (not in GDD) Act IX
	"concord_harvesters": "The Harvesters",  # TUNING (not in GDD) Act IX
	"concord_vrask": "The Vrask",  # TUNING (not in GDD) Act IX
	"concord_luminous": "The Luminous",  # TUNING (not in GDD) Act IX
	"concord_bosses": "Stage boss",  # TUNING (not in GDD) Act IX bosses
	# --- Act X: the Black Tide ---
	"corsair_crew": "The Brotherhood",  # TUNING (not in GDD) Act X
	"corsair_sea": "The sea",  # TUNING (not in GDD) Act X
	"corsair_boats": "Boat",  # TUNING (not in GDD) Act X
	"corsair_bosses": "Stage boss",  # TUNING (not in GDD) Act X bosses
	# --- Act XI (temporary): the Hall of the Slain ---
	"norse_warriors": "Warrior",  # TUNING (not in GDD) the Norse act
	"norse_hall": "The Hall",  # TUNING (not in GDD) the Norse act
	"norse_wilds": "The North",  # TUNING (not in GDD) the Norse act
	"norse_bosses": "Stage boss",  # TUNING (not in GDD) the Norse act bosses
	# --- Act XII (temporary number): the Necropolis Dynasty ---
	"dynasty_dead": "The wrapped dead",  # TUNING (not in GDD) Act XII
	"dynasty_beasts": "Sacred beast",  # TUNING (not in GDD) Act XII
	"dynasty_guard": "The guard",  # TUNING (not in GDD) Act XII
	"dynasty_priests": "The priesthood",  # TUNING (not in GDD) Act XII
	"dynasty_stone": "Stone and jars",  # TUNING (not in GDD) Act XII
	"dynasty_bosses": "Stage boss",  # TUNING (not in GDD) Act XII bosses
}

# --- Layout (layout px at 1280x720; TUNING, not in GDD) -----------------------------

## Opacity (0..1) of the backdrop over the main menu (hides its hint strip).
const BACKDROP_ALPHA: float = 0.96  # TUNING (not in GDD)
## Outer size of the screen's ornate panel (px).
const PANEL_SIZE := Vector2(1196.0, 634.0)  # TUNING (not in GDD)
## Height (px) of the tab buttons and Back.
const TAB_HEIGHT: float = 42.0  # TUNING (not in GDD)
## Width (px) of the Back button.
const BACK_WIDTH: float = 100.0  # TUNING (not in GDD)
## Gap (px) between the last tab chip and Back.
const BACK_GAP: float = 10.0  # TUNING (not in GDD)
## Inset (px; x left / right, y top / bottom) of an achievement row's content.
const ROW_PAD := Vector2(16.0, 10.0)  # TUNING (not in GDD)
## Size of one codex tile button (px).
const TILE_SIZE := Vector2(80.0, 80.0)  # TUNING (not in GDD)
## Size of one boss tile button (px; two tiles and a gap wide).
const BOSS_TILE_SIZE := Vector2(168.0, 168.0)  # TUNING (not in GDD)
## Gap between tiles (px).
const TILE_GAP: int = 8  # TUNING (not in GDD)
## Tiles per grid row.
const COLUMNS: int = 8  # TUNING (not in GDD)
## Big boss tiles per grid row (each spans COLUMNS / BOSS_COLUMNS small tiles).
const BOSS_COLUMNS: int = 4  # TUNING (not in GDD)
## Width of the detail panel on the right of a codex page (px).
const DETAIL_WIDTH: float = 388.0  # TUNING (not in GDD)
## Size of the big portrait box on the detail panel (px).
const PORTRAIT_SIZE := Vector2(360.0, 244.0)  # TUNING (not in GDD)
## Largest integer scale of a portrait sprite (px per art px).
const PORTRAIT_MAX_SCALE: int = 5  # TUNING (not in GDD)
## Largest integer scale of an icon badge in a portrait (32 px badge -> 192 px).
const PORTRAIT_ICON_SCALE: int = 6  # TUNING (not in GDD)
## Items of a page that run the staggered entrance when its tab opens (the
## rest appear at once).
const STAGGER_COUNT: int = 24  # TUNING (not in GDD)
## Seconds between two items' entrances (quicker than UiMotionData's: tiles are many).
const STAGGER_INTERVAL: float = 0.018  # TUNING (not in GDD)
## Gap (px) kept between the achievement cards and the scroll bar.
const SCROLL_GUTTER: int = 16  # TUNING (not in GDD)
## Inset (px) of the stat lines from the detail card's sides.
const STATS_INSET: int = 14  # TUNING (not in GDD)
## Longest stat value (characters) kept on the label's line; a longer one
## (a recipe) is centred under its label.
const STAT_INLINE_CHARS: int = 24  # TUNING (not in GDD)
## Inset (px) of a tile's art from the tile's edge.
const TILE_INSET: float = 8.0  # TUNING (not in GDD)
## Flat fill of an entry's silhouette while it is not met yet (drawn with
## SILHOUETTE_SHADER: one solid colour).
const SILHOUETTE := Color(0.02, 0.01, 0.04, 1.0)  # TUNING (not in GDD)
## Flat colour of the 1 px rim around a silhouette.
const SILHOUETTE_RIM := Color(0.36, 0.22, 0.54, 0.9)  # TUNING (not in GDD)
## Multiply tint of an icon badge whose entry is not met yet (a dim ghost).
const GHOST_TINT := Color(0.38, 0.32, 0.46, 0.75)  # TUNING (not in GDD)
## Shader of the flat silhouettes.
const SILHOUETTE_SHADER: String = "res://scripts/fx/flat_silhouette.gdshader"
## Opacity (0..1) of a locked tile's frame and "?" glyph.
const LOCKED_ALPHA: float = 0.55  # TUNING (not in GDD)

# --- Achievements page ---------------------------------------------------------------

## Height (px) of one achievement row.
const ROW_HEIGHT: float = 96.0  # TUNING (not in GDD)
## Size (px) of the badge on an achievement row (a 32 px badge at x2).
const BADGE_SIZE := Vector2(64.0, 64.0)  # TUNING (not in GDD)
## Width (px) of an achievement row's progress bar.
const BAR_WIDTH: float = 400.0  # TUNING (not in GDD)
## Height (px) of an achievement row's progress bar.
const BAR_HEIGHT: float = 14.0  # TUNING (not in GDD)
## Width (px) of the reward column on an achievement row.
const REWARD_WIDTH: float = 330.0  # TUNING (not in GDD)
## Size (px) of the reward preview (a skin, a badge) on an achievement row.
const REWARD_PREVIEW := Vector2(64.0, 64.0)  # TUNING (not in GDD)
## Badge icon (assets/sprites/icons/<id>.png) of each achievement; one
## without art draws the achievement's fallback IconGlyph kind.
const ACHIEVEMENT_ICONS: Dictionary = {
	"bone_legion": "ach_bone_legion",  # TUNING (not in GDD)
	"heretics_bane": "ach_heretics_bane",  # TUNING (not in GDD)
	"dread_sovereign": "ach_dread_sovereign",  # TUNING (not in GDD)
	"dawn_extinguished": "ach_dawn_extinguished",  # TUNING (not in GDD)
	# --- Act II: Gullhaven Harbour ---
	"low_tide": "ach_low_tide",  # TUNING (not in GDD)
	# --- Act II: the Hollow Archive ---
	"nothing_unwritten": "ach_nothing_unwritten",  # TUNING (not in GDD)
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"the_dead_god_serves": "ach_the_dead_god_serves",  # TUNING (not in GDD)
	# --- Content wave 2: B. Achievement rewards (no badge PNGs yet: the fallbacks draw) ---
	"mass_grave": "ach_mass_grave",  # TUNING (not in GDD)
	"untouchable": "ach_untouchable",  # TUNING (not in GDD)
	"full_ossuary": "ach_full_ossuary",  # TUNING (not in GDD)
	"deathlords_due": "ach_deathlords_due",  # TUNING (not in GDD)
	"swift_judgment": "ach_swift_judgment",  # TUNING (not in GDD)
	# --- Act III: the Assembly Halls ---
	"cold_assembly": "ach_cold_assembly",  # TUNING (not in GDD)
	# --- Act III: the Scrap Wastes ---
	"static_in_the_wastes": "ach_static_in_the_wastes",  # TUNING (not in GDD)
	# --- Act III: the Iron Citadel ---
	"nothing_is_deathless": "ach_nothing_is_deathless",  # TUNING (not in GDD)
	# --- Act IV: the Shores of Ilion ---
	"heel_found": "ach_heel_found",  # TUNING (not in GDD)
	# --- Act IV: Mount Olympus ---
	"twilight_of_the_gods": "ach_twilight_of_the_gods",  # TUNING (not in GDD)
	# --- Act IV: the Asphodel Underworld ---
	"empty_throne": "ach_empty_throne",  # TUNING (not in GDD)
	# --- Act V: the Burning Province ---
	"no_shadow_unlit": "ach_no_shadow_unlit",  # TUNING (not in GDD)
	# --- Act V: the Road to the Sun ---
	"the_sun_goes_out": "ach_the_sun_goes_out",  # TUNING (not in GDD)
	# --- Act V: Castle Kurogane ---
	"regiments_broken": "ach_regiments_broken",  # TUNING (not in GDD)
	# --- Act VI: the Burning Gate ---
	"gate_crashed": "ach_gate_crashed",  # TUNING (not in GDD)
	# --- Act VI: the Palace of Silk and Ash ---
	"unmoved": "ach_unmoved",  # TUNING (not in GDD)
	# --- Act VI: Pandemonium ---
	"morning_star_falls": "ach_morning_star_falls",  # TUNING (not in GDD)
	# --- Act VII: Ravensmoor ---
	"coffin_nails": "ach_coffin_nails",  # TUNING (not in GDD)
	# --- Act VII: the Witchwood ---
	"the_coven_breaks": "ach_the_coven_breaks",  # TUNING (not in GDD)
	# --- Act VII: Castle Sanguis ---
	"last_supper": "ach_last_supper",  # TUNING (not in GDD)
	# --- Act VIII: Skid Row ---
	"no_witnesses": "ach_no_witnesses",  # TUNING (not in GDD)
	# --- Act VIII: Fort Kessler ---
	"broken_arrow": "ach_broken_arrow",  # TUNING (not in GDD)
	# --- Act VIII: Liberty Heights ---
	"no_more_heroes": "ach_no_more_heroes",  # TUNING (not in GDD)
	# --- Act IX: the Crash Site ---
	"nothing_hatched": "ach_nothing_hatched",  # TUNING (not in GDD)
	# --- Act IX: the Proving Moon ---
	"the_hunter_hunted": "ach_the_hunter_hunted",  # TUNING (not in GDD)
	# --- Act IX: the Ark ---
	"last_harvest": "ach_last_harvest",  # TUNING (not in GDD)
	# --- Act XI (temporary): Vigrid ---
	"twilight_of_the_wolf": "ach_twilight_of_the_wolf",  # TUNING (not in GDD) (no badge PNG yet: the fallback icon shows)
}
## IconGlyph kind drawn when an achievement badge PNG is missing.
const ACHIEVEMENT_FALLBACK_ICONS: Dictionary = {
	"bone_legion": "warrior",
	"heretics_bane": "dark_benediction",
	"dread_sovereign": "dark_command",
	"dawn_extinguished": "hyper_badge",
	# --- Act II: Gullhaven Harbour ---
	"low_tide": "brinewalker",
	# --- Act II: the Hollow Archive ---
	"nothing_unwritten": "forbidden_verse",
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"the_dead_god_serves": "call_of_the_drowned",
	# --- Content wave 2: B. Achievement rewards ---
	"mass_grave": "raise_dead",
	"untouchable": "warding_ritual",
	"full_ossuary": "forbidden_knowledge",
	"deathlords_due": "dread_rally",
	"swift_judgment": "death_mark",
	# --- Act III: the Assembly Halls ---
	"cold_assembly": "signal_ghost",
	# --- Act III: the Scrap Wastes ---
	"static_in_the_wastes": "lead_lined_bones",
	# --- Act III: the Iron Citadel ---
	"nothing_is_deathless": "scrap_swarm",
	# --- Act IV: the Shores of Ilion ---
	"heel_found": "bronze_breaker",
	# --- Act IV: Mount Olympus ---
	"twilight_of_the_gods": "grounded_bones",
	# --- Act IV: the Asphodel Underworld ---
	"empty_throne": "river_styx",
	# --- Act V: the Burning Province ---
	"no_shadow_unlit": "paper_lanterns",
	# --- Act V: the Road to the Sun ---
	"the_sun_goes_out": "black_sun",
	# --- Act V: Castle Kurogane ---
	"regiments_broken": "unbending",
	# --- Act VI: the Burning Gate ---
	"gate_crashed": "salt_circle",
	# --- Act VI: the Palace of Silk and Ash ---
	"unmoved": "faithless",
	# --- Act VI: Pandemonium ---
	"morning_star_falls": "fall_from_grace",
	# --- Act VII: Ravensmoor ---
	"coffin_nails": "silver_bones",
	# --- Act VII: the Witchwood ---
	"the_coven_breaks": "embalmed",
	# --- Act VII: Castle Sanguis ---
	"last_supper": "night_swarm",
	# --- Act VIII: Skid Row ---
	"no_witnesses": "kevlar_bones",
	# --- Act VIII: Fort Kessler ---
	"broken_arrow": "armour_piercing_bones",
	# --- Act VIII: Liberty Heights ---
	"no_more_heroes": "heros_fist",
	# --- Act IX: the Crash Site ---
	"nothing_hatched": "anchored",
	# --- Act IX: the Proving Moon ---
	"the_hunter_hunted": "mirror_bones",
	# --- Act IX: the Ark ---
	"last_harvest": "tractor_lift",
	# --- Act XI (temporary): Vigrid ---
	"twilight_of_the_wolf": "gungnir",
}
## Screen title (TITLE tier).
const TITLE: String = "Codex"  # TUNING (not in GDD)
## Label over an achievement row's reward.
const REWARD_LABEL: String = "Reward"  # TUNING (not in GDD)
## Header of the achievements section, and of the feats (the skin and Hyper
## unlocks that are not achievements) under it.
const ACHIEVEMENTS_HEADER: String = "Achievements"  # TUNING (not in GDD)
## Header of the feats section.
const FEATS_HEADER: String = "Feats"  # TUNING (not in GDD)
## Name, goal and reward text of the Hyper mode unlock feat.
const HYPER_FEAT := {"name": "Beyond the Dawn", "goal": "Slay Grand Inquisitor Seraphine", "reward": "Hyper mode"}  # TUNING (not in GDD) (HyperData unlock)
## Name, goal and reward text of the Hyper skins feat (one per character).
const HYPER_SKINS_FEAT := {"name": "Gilded Legion", "goal": "Clear the Sanctum on Hyper with each character", "reward": "A Hyper skin per character"}  # TUNING (not in GDD) (SkinData Hyper skins)
## Reward line of an achievement's Soul Ash bounty ("+%d Soul Ash").
const BOUNTY_TEXT: String = "+%d Soul Ash"  # TUNING (not in GDD)
## Stamp on an earned row.
const EARNED_TEXT: String = "Earned"  # TUNING (not in GDD)
## Count under the title: earned, total.
const EARNED_COUNT: String = "%d / %d earned"  # TUNING (not in GDD)
## Count under the title on a codex page: recorded, total.
const RECORDED_COUNT: String = "%d / %d recorded"  # TUNING (not in GDD)


## True when `id` is an entry of codex category `cat` (unknown ids are
## never recorded or saved).
static func is_known(cat: String, id: String) -> bool:
	match cat:
		SPELL:
			return AbilityData.SPELLS.has(id)
		SUMMON:
			return SUMMON_ORDER.has(id)
		ENEMY:
			return SOLDIERS.has(id) or STRUCTURES.has(id) or CHAMPIONS.has(id) \
					or EYE_SOLDIERS.has(id) or EYE_CHAMPIONS.has(id) \
					or EMPIRE_SOLDIERS.has(id) or EMPIRE_CHAMPIONS.has(id) \
					or PANTHEON_SOLDIERS.has(id) or PANTHEON_CHAMPIONS.has(id) \
					or SHOGUNATE_SOLDIERS.has(id) or SHOGUNATE_CHAMPIONS.has(id) \
					or INFERNO_SOLDIERS.has(id) or INFERNO_CHAMPIONS.has(id) \
					or COURT_SOLDIERS.has(id) or COURT_CHAMPIONS.has(id) \
					or CITY_CIVILIANS.has(id) or CITY_GANGS.has(id) or CITY_POLICE.has(id) \
					or CITY_SWAT.has(id) or CITY_ARMY.has(id) or CITY_HEROES.has(id) \
					or CONCORD_BROOD.has(id) or CONCORD_HARVESTERS.has(id) or CONCORD_VRASK.has(id) \
					or CONCORD_LUMINOUS.has(id) \
					or CORSAIR_CREW.has(id) or CORSAIR_SEA.has(id) or CORSAIR_BOATS.has(id) \
					or NORSE_WARRIORS.has(id) or NORSE_HALL.has(id) or NORSE_WILDS.has(id) \
					or DYNASTY_DEAD.has(id) or DYNASTY_BEASTS.has(id) or DYNASTY_GUARD.has(id) \
					or DYNASTY_PRIESTS.has(id) or DYNASTY_STONE.has(id)  # Act IV to Act XII (temporary numbers)
		BOSS:
			return BOSSES.has(id) or EYE_BOSSES.has(id) or EMPIRE_BOSSES.has(id) or PANTHEON_BOSSES.has(id) \
					or SHOGUNATE_BOSSES.has(id) or INFERNO_BOSSES.has(id) or COURT_BOSSES.has(id) \
					or CITY_BOSSES.has(id) or CONCORD_BOSSES.has(id) or CORSAIR_BOSSES.has(id) \
					or NORSE_BOSSES.has(id) or DYNASTY_BOSSES.has(id)  # (Act XII, temporary, last)
	return false


## Number of entries in category `cat` (the evolutions are not a category).
static func total(cat: String) -> int:
	match cat:
		SPELL:
			return AbilityData.SPELL_ORDER.size()
		SUMMON:
			return SUMMON_ORDER.size()
		ENEMY:
			return SOLDIERS.size() + STRUCTURES.size() + CHAMPIONS.size() + EYE_SOLDIERS.size() + EYE_CHAMPIONS.size() \
					+ EMPIRE_SOLDIERS.size() + EMPIRE_CHAMPIONS.size() \
					+ PANTHEON_SOLDIERS.size() + PANTHEON_CHAMPIONS.size() \
					+ SHOGUNATE_SOLDIERS.size() + SHOGUNATE_CHAMPIONS.size() \
					+ INFERNO_SOLDIERS.size() + INFERNO_CHAMPIONS.size() \
					+ COURT_SOLDIERS.size() + COURT_CHAMPIONS.size() \
					+ CITY_CIVILIANS.size() + CITY_GANGS.size() + CITY_POLICE.size() \
					+ CITY_SWAT.size() + CITY_ARMY.size() + CITY_HEROES.size() \
					+ CONCORD_BROOD.size() + CONCORD_HARVESTERS.size() + CONCORD_VRASK.size() \
					+ CONCORD_LUMINOUS.size() \
					+ CORSAIR_CREW.size() + CORSAIR_SEA.size() + CORSAIR_BOATS.size() \
					+ NORSE_WARRIORS.size() + NORSE_HALL.size() + NORSE_WILDS.size() \
					+ DYNASTY_DEAD.size() + DYNASTY_BEASTS.size() + DYNASTY_GUARD.size() \
					+ DYNASTY_PRIESTS.size() + DYNASTY_STONE.size()  # Act IV to Act XII (temporary numbers)
		BOSS:
			return BOSSES.size() + EYE_BOSSES.size() + EMPIRE_BOSSES.size() + PANTHEON_BOSSES.size() \
					+ SHOGUNATE_BOSSES.size() + INFERNO_BOSSES.size() + COURT_BOSSES.size() \
					+ CITY_BOSSES.size() + CONCORD_BOSSES.size() + CORSAIR_BOSSES.size() \
					+ NORSE_BOSSES.size() + DYNASTY_BOSSES.size()  # (Act XII, temporary, last)
	return 0


## The data row of Covenant kind or boss `id` (max_hp, damage, move_speed,
## display_name...; {} when unknown).
static func enemy_row(id: String) -> Dictionary:
	if id == "inquisitor":
		return EnemyData.RECKONING_ENEMY
	for table: Dictionary in [EnemyData.ENEMIES, MarchEnemyData.ENEMIES, BattleSisterData.ENEMIES, SanctumEnemyData.ENEMIES, SanctumObjectiveData.STRUCTURES]:
		if table.has(id):
			return table[id]
	var eye := EnemyDirector.eye_def(id)  # Act II kinds ({} when none).
	if not eye.is_empty():
		return eye
	var empire := EnemyDirector.empire_def(id)  # Act III kinds ({} when none).
	if not empire.is_empty():
		return empire
	var pantheon := EnemyDirector.pantheon_def(id)  # Act IV kinds ({} when none).
	if not pantheon.is_empty():
		return pantheon
	var shogunate := EnemyDirector.shogunate_def(id)  # Act V kinds ({} when none).
	if not shogunate.is_empty():
		return shogunate
	var inferno := EnemyDirector.inferno_def(id)  # Act VI kinds ({} when none).
	if not inferno.is_empty():
		return inferno
	var court := EnemyDirector.court_def(id)  # Act VII kinds ({} when none).
	if not court.is_empty():
		return court
	var city := EnemyDirector.city_def(id)  # Act VIII kinds ({} when none).
	if not city.is_empty():
		return city
	var concord := EnemyDirector.concord_def(id)  # Act IX kinds ({} when none).
	if not concord.is_empty():
		return concord
	var corsair := EnemyDirector.corsair_def(id)  # Act X kinds ({} when none).
	if not corsair.is_empty():
		return corsair
	var norse := EnemyDirector.norse_def(id)  # The Hall of the Slain's kinds ({} when none).
	if not norse.is_empty():
		return norse
	var dynasty := EnemyDirector.dynasty_def(id)  # Act XII (temporary) kinds ({} when none).
	if not dynasty.is_empty():
		return dynasty
	match id:
		"alaric":
			return EnemyData.BOSS
		"vael":
			return MarchEnemyData.VAEL
		"seraphine":
			return SeraphineData.BOSS
		"merrow":
			return MerrowData.BOSS  # Act II: Gullhaven Harbour.
		# --- Act II: the Hollow Archive ---
		"archivist":
			return ArchivistData.BOSS
		# --- Act II: Ul-Thalos, the Risen Spire ---
		"vhalneth":
			return VhalnethData.BOSS
		# --- Act III: the Assembly Halls ---
		"motherboard":
			return MotherboardData.BOSS
	return {}
