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
		["inferno", "Inferno"]]  # TUNING (not in GDD) Act II adds the Ancient Eye tab, Act III the Electronic Empire's, Act IV the Olympian Republic's, Act V the Shogunate's, Act VI the Inferno's

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
		"archfiend"]

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
					or INFERNO_SOLDIERS.has(id) or INFERNO_CHAMPIONS.has(id)  # Act IV, Act V, Act VI
		BOSS:
			return BOSSES.has(id) or EYE_BOSSES.has(id) or EMPIRE_BOSSES.has(id) or PANTHEON_BOSSES.has(id) \
					or SHOGUNATE_BOSSES.has(id) or INFERNO_BOSSES.has(id)  # (Act VI last)
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
					+ INFERNO_SOLDIERS.size() + INFERNO_CHAMPIONS.size()  # Act IV, Act V, Act VI
		BOSS:
			return BOSSES.size() + EYE_BOSSES.size() + EMPIRE_BOSSES.size() + PANTHEON_BOSSES.size() \
					+ SHOGUNATE_BOSSES.size() + INFERNO_BOSSES.size()  # (Act VI last)
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
