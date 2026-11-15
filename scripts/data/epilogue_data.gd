## EpilogueData: the CAMPAIGN EPILOGUE, one illustrated part per act (GDD §15.0
## "Ul-Thalos, the Risen Spire", "Illustrated epilogue (content wave 2)" and
## "The reorder pass, part 2 (the story)"). Fifteen parts of three or four
## paragraphs, in the campaign's ACT ORDER (StageRegistry.ACT_ORDER: the one
## ordered list; PARTS is built from it, so no second order is kept), each
## opened by its act's finale achievement (MetaData.ACHIEVEMENTS). Every
## paragraph has its own pixel-art picture panel (`panels`,
## assets/sprites/epilogue/<key>.png, made by tools/epilogue_panel.py;
## docs/art/ART_BIBLE.md "Epilogue panels"; the panels still to paint are listed
## in docs/last_acts/EPILOGUE_PANELS.md, and a missing PNG is a flat EMPTY_COLOUR
## window that still pans and shows its text) with a slow pan. A closing card
## (CLOSINGS) follows every part but the last and hints at the NEXT act in the
## order; the Turning Year's part is the campaign's true ending and has none.
## The main menu shows its Epilogue button once any part is open
## (FrontDoorData.MENU_ITEMS); EpilogueScreen plays the slides, and plays the
## parts the player has not seen yet once on their own after a run (Meta
## [epilogue] seen_<id>; the ids act1..act5 are the first five parts' old ids and
## stay as save flags). Sizes are layout px on the 1280x720 layout, times are
## REAL seconds (UI motion never runs on game time). Data only.
class_name EpilogueData
extends RefCounted

## The parts in reading order (ACT_ORDER), built once from ROWS; each row gains
## "act", the label "Act XI: The Ancient Eye" derived from the act's number and name.
static var PARTS: Array = _ordered_parts()

## The part rows (PARTS orders them by their act). Keys: `id` (its Meta
## [epilogue] seen_<id> flag), `act_id` (the StageRegistry.ACT_ORDER id of its
## act), `achievement` (MetaData id that opens it), `heading`, `lines` (the
## paragraphs), and one picture panel per paragraph: [SpriteData key, pan start,
## pan end]; a pan point is the window's place over the picture as a fraction
## (0..1) of the picture's slack on each axis (0, 0 = top-left corner of the art
## in view).
const ROWS := [
	{
		"id": "act1",  # TUNING (not in GDD) the first part's old id, kept as the save flag
		"act_id": "covenant",  # TUNING (not in GDD)
		"achievement": "dawn_extinguished",
		"heading": "When the Dawn Went Out",
		"lines": [
			"The Sanctum burned for three nights. When the relic shattered, the light that had ruled the realm for a thousand years went out like a candle in a crypt.",
			"Across the land the other holy orders took up arms, but there was no Covenant left to lead them. The dead walked the pilgrim roads, and the living learned to bar their doors at dusk.",
			"The necromancer did not sit the empty throne. Out on the dark water a fleet of corsairs circled the cathedral gold the Covenant left behind, and the army began to drift toward the coast.",  # TUNING (not in GDD) reworded for the final order (the Black Tide follows; was: something far beneath the sea was calling the dead)
		],
		"panels": [
			["epilogue/act1_1", Vector2(0.5, 0.0), Vector2(0.5, 0.75)],  # TUNING (not in GDD) the burning Sanctum, tilting down to the shattered relic
			["epilogue/act1_2", Vector2(1.0, 0.1), Vector2(0.0, 0.9)],  # TUNING (not in GDD) the dying sun, down the pilgrim road
			["epilogue/act1_3", Vector2(0.0, 0.7), Vector2(1.0, 0.3)],  # TUNING (not in GDD) from the cliff out to the glow beneath the sea
		],
	},
	{
		"id": "corsair",  # TUNING (not in GDD) the part's id (Meta [epilogue] seen_corsair)
		"act_id": "corsair",  # TUNING (not in GDD) the StageRegistry.ACT_ORDER id of its act
		"achievement": "dead_men_tell_tales",
		"heading": "The Hollow Queen Sails",  # TUNING (not in GDD)
		"lines": [
			"The Covenant's tithe fleet drifted for a year with the gold of a hundred cathedrals in its holds, and every pirate on the sea came for it. They found the dead already aboard.",  # TUNING (not in GDD)
			"Crow burned in his own fog, and Admiral Marrec went down with her galleon and her cursed coins. The Brotherhood learned too late that the dead take no gold, only ships.",  # TUNING (not in GDD)
			"In the Maelstrom, Captain Vandermere stood lashed to the wheel of the Hollow Queen, bound by an Oath only his own ghost crew could break. They broke it, and the wheel turned for the dead.",  # TUNING (not in GDD)
			"The whirlpool closed over the Brotherhood's flag. Beneath the keels the black water is full of drowned crews who have waited a long time for a captain, and they all sail for the necromancer now.",  # TUNING (not in GDD)
		],
		"panels": [
			["epilogue/corsair_1", Vector2(0.0, 0.5), Vector2(1.0, 0.4)],  # TUNING (not in GDD) left to right along the deck, from the necromancer to the spilled gold
			["epilogue/corsair_2", Vector2(0.0, 0.2), Vector2(1.0, 0.8)],  # TUNING (not in GDD) from the burning sloop in the fog down across to the sinking galleon
			["epilogue/corsair_3", Vector2(0.5, 1.0), Vector2(0.5, 0.0)],  # TUNING (not in GDD) from the whirlpool up the tilted deck to Vandermere at the wheel
			["epilogue/corsair_4", Vector2(0.0, 0.0), Vector2(1.0, 0.7)],  # TUNING (not in GDD) from the sky and torn flag across the sea to the ghost fleet and the necromancer
		],
	},
	{
		"id": "court",  # TUNING (not in GDD) the part's id (Meta [epilogue] seen_court)
		"act_id": "court",  # TUNING (not in GDD) the StageRegistry.ACT_ORDER id of its act
		"achievement": "last_supper",
		"heading": "The Veil Tears",  # TUNING (not in GDD)
		"lines": [
			"For a thousand years the Court fed on the villages of Ravensmoor, and the villagers called its lords a rumour and its hunger the weather. The necromancer's army did not believe in rumours.",  # TUNING (not in GDD)
			"Vargr's wolves ran down to the dead and did not get up. Isolde Vane's coven burned in its own circle, and the Blood Moon rose over a Witchwood gone quiet.",  # TUNING (not in GDD)
			"In the deepest vault of Castle Sanguis, Queen Carmilla fell, and the Elder rose from his coffin to finish what she could not. The first vampire turned to ash in his own bed.",  # TUNING (not in GDD)
			"The veil the Court drew over the world for a thousand years tore like old silk. The feast is over, and the living learned too late what had been feeding on them.",  # TUNING (not in GDD)
		],
		"panels": [
			["epilogue/court_1", Vector2(0.0, 0.6), Vector2(1.0, 0.3)],  # TUNING (not in GDD) along the lane from the necromancer to the moon over the roofs
			["epilogue/court_2", Vector2(0.5, 0.9), Vector2(0.5, 0.0)],  # TUNING (not in GDD) from the burning circle up the black trunks to the Blood Moon
			["epilogue/court_3", Vector2(0.0, 0.7), Vector2(1.0, 0.2)],  # TUNING (not in GDD) from Carmilla on the floor across to the coffin and the Elder dissolving
			["epilogue/court_4", Vector2(0.1, 0.9), Vector2(0.9, 0.1)],  # TUNING (not in GDD) from the necromancer on the hill up and across the torn veil to the city lights
		],
	},
	{
		"id": "city",  # TUNING (not in GDD) the part's id (Meta [epilogue] seen_city)
		"act_id": "city",  # TUNING (not in GDD) the StageRegistry.ACT_ORDER id of its act
		"achievement": "no_more_heroes",
		"heading": "No One Left",  # TUNING (not in GDD)
		"lines": [
			"The living did not run. In the last cities they walled the streets and called out the police, then the soldiers, then the heroes, and every one of them stood between the dead and the world.",  # TUNING (not in GDD)
			"Don Marrow's gangs went first. General Harrow's armour followed, and the bones ground the Mammoth and its columns into the road as if the war had been decided long ago.",  # TUNING (not in GDD)
			"On Liberty Heights the Supers fell one by one, Blitz, Aurora, Atlas, Nightjar, until only Paragon stood in the plaza he had sworn to keep. He fell last, and the sirens stopped.",  # TUNING (not in GDD)
			"The towers burn on, and the world of the living has no one left to defend it. Somewhere, a last radio keeps asking if anyone is still out there.",  # TUNING (not in GDD)
		],
		"panels": [
			["epilogue/city_1", Vector2(0.0, 0.6), Vector2(1.0, 0.3)],  # TUNING (not in GDD) from the barricade along the street to the searchlit rooftops
			["epilogue/city_2", Vector2(1.0, 0.3), Vector2(0.0, 0.7)],  # TUNING (not in GDD) from the wrecked Mammoth across the ruts toward the necromancer's line
			["epilogue/city_3", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) from the flag and monument down to Paragon on his knee
			["epilogue/city_4", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) from the burning skyline down to the radio on the curb
		],
	},
	{
		"id": "act5",  # TUNING (not in GDD) the Shogunate's old id, kept as the save flag
		"act_id": "shogunate",  # TUNING (not in GDD)
		"achievement": "the_sun_goes_out",
		"heading": "The Sun Goes Out",  # Owner-approved proposal
		"lines": [
			"With the last city fallen there was only one day left for the dead to fear. Across the eastern sea a Shogun ruled in the sun goddess's name, and she had seen the night spreading west.",  # Owner-approved proposal story (reworded for the final order: was "With Olympus fallen")
			"His armies sailed to burn it out. The dead met them in the burning rice fields, and the ninja of the Hidden Hand could not hide from them in any shadow.",  # Owner-approved proposal story (TUNING the words)
			"Castle Kurogane fell regiment by regiment, until the Shogun came down from his platform and drew his own blade, and was cut down by the night.",  # Owner-approved proposal story (TUNING the words)
			"On the road above the clouds the sun goddess crossed the sky one last time. When she fell, the sun went out. There will be no dawn again: only the night, and the dead who walk in it.",  # Owner-approved proposal ending
		],
		"panels": [
			["epilogue/act5_1", Vector2(0.0, 0.6), Vector2(1.0, 0.2)],  # TUNING (not in GDD) from the necromancer and his skeletons up the winding road to the torii and the low sun
			["epilogue/act5_2", Vector2(0.0, 0.5), Vector2(1.0, 0.5)],  # TUNING (not in GDD) across the burning rice fields, from the dead line to the samurai and their banners
			["epilogue/act5_3", Vector2(0.0, 0.6), Vector2(1.0, 0.6)],  # TUNING (not in GDD) from the necromancer and his skeletons across the castle courtyard to the fallen Shogun
			["epilogue/act5_4", Vector2(1.0, 0.0), Vector2(0.0, 1.0)],  # TUNING (not in GDD) from the black sun in its last ring of gold, across the torii, down to the necromancer and the broken mirror and crown at his feet
		],
	},
	{
		"id": "norse",  # TUNING (not in GDD) the part's id (Meta [epilogue] seen_norse)
		"act_id": "norse",  # TUNING (not in GDD) the StageRegistry.ACT_ORDER id of its act
		"achievement": "twilight_of_the_wolf",
		"heading": "The Last Field",  # TUNING (not in GDD)
		"lines": [
			"The north does not own its dead; it chooses them. Valkyries carried the best to Odin's hall to feast until the last battle, and since the necromancer came, its benches stand empty.",  # TUNING (not in GDD)
			"The All-Father sent what he had: raiders and shield-maidens, berserkers and frost-giants, and the barrow dead who woke when the fires went out. The dead lit the braziers again, one by one.",  # TUNING (not in GDD)
			"Sigrun led the Einherjar down from the Hall and fell in her own doorway. On Vigrid, the Last Field, the great wolf broke its chain and met the dead, and it was not enough.",  # TUNING (not in GDD)
			"Odin lies on the field he chose for the end of the world, and no hall is left to take him. Ragnarok came and went, and the dead walked out of it, every one, behind the necromancer.",  # TUNING (not in GDD)
		],
		"panels": [
			["epilogue/norse_1", Vector2(0.0, 0.5), Vector2(1.0, 0.5)],  # TUNING (not in GDD) along the empty benches toward the dim high seat
			["epilogue/norse_2", Vector2(0.0, 0.7), Vector2(1.0, 0.3)],  # TUNING (not in GDD) from the necromancer lighting a brazier out across the mounds to the frost giant
			["epilogue/norse_3", Vector2(0.0, 0.2), Vector2(1.0, 0.8)],  # TUNING (not in GDD) from the hall door and Sigrun across to the wolf in the field
			["epilogue/norse_4", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) from the dying sun down to Odin and the marching dead
		],
	},
	{
		"id": "dynasty",  # TUNING (not in GDD) the part's id (Meta [epilogue] seen_dynasty)
		"act_id": "dynasty",  # TUNING (not in GDD) the StageRegistry.ACT_ORDER id of its act
		"achievement": "a_light_heart",
		"heading": "Weighed and Wanting",  # TUNING (not in GDD)
		"lines": [
			"In the south the dead were never lost: every body was named, weighed and wrapped, and every mummy belonged to a god. The Dynasty came to take its three thousand years back.",  # TUNING (not in GDD)
			"At the Necropolis of Sand, Anubis fell among the canopic jars, and the Names inside them rose for the necromancer instead. In the Temple of the Lioness, Sekhmet's burning eye went dark.",  # TUNING (not in GDD)
			"In the Hall of Two Truths the scales swung to his side. Osiris and Ammit, the Judge and the Devourer, weighed a heart lighter than a feather, and the heart was his.",  # TUNING (not in GDD)
			"No old master has a claim on the dead. The sarcophagi stand open from the Nile to the sea, and the sand gives back nothing it is asked to keep.",  # TUNING (not in GDD)
		],
		"panels": [
			["epilogue/dynasty_1", Vector2(0.0, 0.5), Vector2(1.0, 0.5)],  # TUNING (not in GDD) along the corridor of tombs from the entrance to the shut doors
			["epilogue/dynasty_2", Vector2(0.0, 0.4), Vector2(1.0, 0.6)],  # TUNING (not in GDD) from the glowing jars across to the dark lion eye
			["epilogue/dynasty_3", Vector2(0.5, 1.0), Vector2(0.5, 0.0)],  # TUNING (not in GDD) from the necromancer up past the scales to Osiris's throne
			["epilogue/dynasty_4", Vector2(1.0, 0.2), Vector2(0.0, 0.8)],  # TUNING (not in GDD) from the pyramids on the horizon down along the open sarcophagi
		],
	},
	{
		"id": "act4",  # TUNING (not in GDD) the Republic's old id, kept as the save flag
		"act_id": "pantheon",  # TUNING (not in GDD)
		"achievement": "empty_throne",
		"heading": "The Gods Are Silent",  # Owner-approved proposal
		"lines": [
			"The army of the dead had grown so vast that the Underworld stood empty. Hades complained to Olympus that his kingdom was a desert, and the gods came down to take the dead back.",  # Owner-approved proposal story
			"Their legions broke on the shore of Ilion, and one by one the gods of the mountain fell silent: Ares, Artemis, Poseidon, and at last Zeus himself.",  # Owner-approved proposal story
			"Below the world, in the grey fields of asphodel, the Lord of the Dead rose from his throne to fight for what was his. Beaten, he did not die. He knelt, and laid his crown at the necromancer's feet.",  # Owner-approved proposal ending
			"The Styx runs again, and every soul it carries answers to one master. The gods are silent. The throne below is empty.",  # TUNING (not in GDD)
		],
		"panels": [
			["epilogue/act4_1", Vector2(0.0, 0.6), Vector2(1.0, 0.3)],  # TUNING (not in GDD) across the asphodel fields and the dry Styx, from the necromancer along his army
			["epilogue/act4_2", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) the descending gods in gold, down to the undead line
			["epilogue/act4_3", Vector2(0.0, 0.5), Vector2(1.0, 0.5)],  # TUNING (not in GDD) from the necromancer across to Hades kneeling with his crown
			["epilogue/act4_4", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) the empty marble thrones of Olympus, down to the army and the necromancer
		],
	},
	{
		"id": "inferno",  # TUNING (not in GDD) the part's id (Meta [epilogue] seen_inferno)
		"act_id": "inferno",  # TUNING (not in GDD) the StageRegistry.ACT_ORDER id of its act
		"achievement": "morning_star_falls",
		"heading": "The Throne Below",  # TUNING (not in GDD)
		"lines": [
			"Hell keeps accounts. Every soul the necromancer raised was a soul owed to the Pit, and the Pit sent its collectors up through the Burning Gate to take them back.",  # TUNING (not in GDD)
			"Moloch broke on the Gate he kept. In the Palace of Silk and Ash, Lilith offered the army everything it could want, and the dead, who want nothing, would not be moved.",  # TUNING (not in GDD)
			"In Pandemonium the Morning Star rose from his burning throne to claim the debt himself, and the dead cast him down. The Archfiend fell with the Pit's ledger burning in his hand.",  # TUNING (not in GDD)
			"The necromancer climbed the burning steps and sat. The dead of earth and hell kneel to him now, and far below, the great fire has settled to embers in the empty Pit.",  # TUNING (not in GDD)
		],
		"panels": [
			["epilogue/inferno_1", Vector2(0.5, 0.0), Vector2(0.5, 0.9)],  # TUNING (not in GDD) from the top of the Gate down to the demons and the dead line
			["epilogue/inferno_2", Vector2(0.0, 0.5), Vector2(1.0, 0.5)],  # TUNING (not in GDD) from the necromancer's line across to Lilith's offering hand
			["epilogue/inferno_3", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) from the burning throne down the steps to the dead line
			["epilogue/inferno_4", Vector2(0.5, 1.0), Vector2(0.5, 0.0)],  # TUNING (not in GDD) from the kneeling army up the steps to the necromancer on the throne
		],
	},
	{
		"id": "host",  # TUNING (not in GDD) the part's id (Meta [epilogue] seen_host)
		"act_id": "host",  # TUNING (not in GDD) the StageRegistry.ACT_ORDER id of its act
		"achievement": "the_last_word",
		"heading": "The Voice Is Silent",  # TUNING (not in GDD)
		"lines": [
			"Heaven watched the dead rise for a long age and held its hand. When hell knelt to the necromancer, the silver stair came down, and the Host marched on the world in light.",  # TUNING (not in GDD)
			"Seraiel held the Gate with his flaming sword and fell before it. The Wheel of Thrones turned its thousand eyes on the army and was broken open by its own Core.",  # TUNING (not in GDD)
			"In the Empyrean the choirs sang until the sky shook, and the Herald of the Seventh Trumpet sounded all seven blasts. The dead walked on through every one, toward the Voice at the top of the world.",  # TUNING (not in GDD)
			"The Voice folded its six wings and said nothing more. Heaven, earth and hell answer to the necromancer, and the silence that follows has nothing left to forbid.",  # TUNING (not in GDD)
		],
		"panels": [
			["epilogue/host_1", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) from the clouds down the stair to the dark plain and the dead
			["epilogue/host_2", Vector2(0.0, 0.5), Vector2(1.0, 0.5)],  # TUNING (not in GDD) from the fallen sword at the Gate across to the broken Wheel
			["epilogue/host_3", Vector2(0.0, 0.8), Vector2(1.0, 0.1)],  # TUNING (not in GDD) from the dead line up and across to the Herald's trumpet and the rings
			["epilogue/host_4", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) from the folded wings down to the necromancer and the kneeling hosts
		],
	},
	{
		"id": "act2",  # TUNING (not in GDD) the Eye's old id, kept as the save flag
		"act_id": "eye",  # TUNING (not in GDD)
		"achievement": "the_dead_god_serves",
		"heading": "The Dead God Serves",
		"lines": [
			"The Eye's faithful had prayed for the Dreaming Mother to wake and claim every corpse as her vessel. They had not prayed for who would answer.",
			"Vhal'Neth was dead long before her city sank, and the dead belong to the necromancer. The Eye's own ritual, sung by a thousand drowned throats, bound her to a new master.",
			"Ul-Thalos sinks back beneath the waves. Somewhere far below, a god dreams of the necromancer's will, and the sea gives up its dead whenever it is asked.",
			"The Eye is blind. Its dead god serves. The army is endless, and the Eye's beacons still burn over the water for anything to see.",  # TUNING (not in GDD) reworded for the final order (the Empire follows; was: "The Covenant is ash. The Eye is blind. The army is endless, and it is only beginning.")
		],
		"panels": [
			["epilogue/act2_1", Vector2(0.0, 0.2), Vector2(1.0, 0.0)],  # TUNING (not in GDD) Gullhaven: the tide pulled back, up to the eye
			["epilogue/act2_2", Vector2(0.5, 0.0), Vector2(0.5, 0.9)],  # TUNING (not in GDD) the Archive's last page burning, down to the lectern
			["epilogue/act2_3", Vector2(1.0, 0.0), Vector2(0.4, 0.8)],  # TUNING (not in GDD) Ul-Thalos sinking, down to the watchers
			["epilogue/act2_4", Vector2(0.0, 0.8), Vector2(1.0, 0.3)],  # TUNING (not in GDD) from the necromancer across to Vhal'Neth kneeling
		],
	},
	{
		"id": "act3",  # TUNING (not in GDD) the Empire's old id, kept as the save flag
		"act_id": "empire",  # TUNING (not in GDD)
		"achievement": "nothing_is_deathless",
		"heading": "The Machines Go Dark",  # Owner-approved proposal
		"lines": [
			"The Empire had conquered death with steel. Its citizens were never buried; they were rebuilt, and rebuilt again, and called it forever.",  # TUNING (not in GDD)
			"In the Core of the Iron Citadel the god they built fell to its knees, and the necromancer reached into the broken engine for the one thing the Empire forgot to delete: Varn's soul.",  # Owner-approved proposal ending
			"Nothing is deathless. Everything is mine. Across the realm the machines went dark, rank after rank, and their founder rose to serve a new master.",  # Owner-approved proposal ending
			"Covenant, Eye and Empire are ash, blind and silent. The dead are the only empire left.",  # TUNING (not in GDD)
		],
		"panels": [
			["epilogue/act3_1", Vector2(0.0, 0.1), Vector2(1.0, 0.9)],  # TUNING (not in GDD) the chrome towers, down the avenue of steel citizens to the rebuilding cradle
			["epilogue/act3_2", Vector2(1.0, 0.2), Vector2(0.2, 0.6)],  # TUNING (not in GDD) from the kneeling mech across to the necromancer reaching for Varn's soul
			["epilogue/act3_3", Vector2(1.0, 0.3), Vector2(0.0, 0.8)],  # TUNING (not in GDD) along the dead ranks to Varn bowing to the necromancer
			["epilogue/act3_4", Vector2(0.5, 0.0), Vector2(0.5, 0.9)],  # TUNING (not in GDD) the three acts' ruins, down to the army of the dead
		],
	},
	{
		"id": "concord",  # TUNING (not in GDD) the part's id (Meta [epilogue] seen_concord)
		"act_id": "concord",  # TUNING (not in GDD) the StageRegistry.ACT_ORDER id of its act
		"achievement": "last_harvest",
		"heading": "The Stars Go Dark",  # TUNING (not in GDD)
		"lines": [
			"The stars came for a world they had planted. The Concord's Harvesters had reaped worlds before, and this one had no souls left to take: the necromancer had raised them all.",  # TUNING (not in GDD)
			"At the Crash Site the Hive Mother's brood hatched into a dead field. On the Proving Moon, Vrask'Tal hunted the necromancer, and was hunted down in turn.",  # TUNING (not in GDD)
			"On the Ark the Harvester fell among its own rings, the one who planted the world, and the Concord's stars went out one by one over the world below.",  # TUNING (not in GDD)
			"In the Ark's vault is a log of every world the Harvesters reaped. The oldest entry is this one, and it names the day before the sky fell. The necromancer reads it twice.",  # TUNING (not in GDD)
		],
		"panels": [
			["epilogue/concord_1", Vector2(0.5, 0.0), Vector2(0.5, 0.9)],  # TUNING (not in GDD) from the mothership down the beams to the dead line
			["epilogue/concord_2", Vector2(0.0, 0.5), Vector2(1.0, 0.5)],  # TUNING (not in GDD) from the crashed ship across the moon plain to the fallen Hunt-Lord
			["epilogue/concord_3", Vector2(0.5, 1.0), Vector2(0.5, 0.0)],  # TUNING (not in GDD) from the broken rings up to the cracked window and the dying stars
			["epilogue/concord_4", Vector2(0.0, 0.4), Vector2(1.0, 0.6)],  # TUNING (not in GDD) from the necromancer at the log-pillar along the vault to the rift
		],
	},
	{
		"id": "primeval",  # TUNING (not in GDD) the part's id (Meta [epilogue] seen_primeval)
		"act_id": "primeval",  # TUNING (not in GDD) the StageRegistry.ACT_ORDER id of its act
		"achievement": "the_day_the_sky_fell",
		"heading": "The Day the Sky Fell",  # TUNING (not in GDD)
		"lines": [
			"The rift opened on the day before the world ended. No gods, no armies, no walls: only fern and tar and animals the size of houses, and every one that fell left a skeleton to raise.",  # TUNING (not in GDD)
			"Scarmaw's pack hunted the necromancer through the Fern Basin and fell to his bones. On the Great Plain the herds stampeded, and Old Ironbrow charged into a rock he did not see.",  # TUNING (not in GDD)
			"On the Last Day Old Gravejaw ruled the world, the Tyrant King under a white sky, and he fell with the meteor already burning over his head.",  # TUNING (not in GDD)
			"The Extinction came as it was always going to. The sky fell, the beasts died, and the Fossil Host rose out of the dust, and for the first time the world was quiet.",  # TUNING (not in GDD)
		],
		"panels": [
			["epilogue/primeval_1", Vector2(0.0, 0.6), Vector2(1.0, 0.4)],  # TUNING (not in GDD) from the rift and the necromancer across the basin to the distant herd
			["epilogue/primeval_2", Vector2(0.0, 0.4), Vector2(1.0, 0.6)],  # TUNING (not in GDD) from the raptor pack across the plain to Ironbrow at the rock
			["epilogue/primeval_3", Vector2(0.5, 1.0), Vector2(0.5, 0.0)],  # TUNING (not in GDD) from the fallen Tyrant King up the meteor's trail to the white sky
			["epilogue/primeval_4", Vector2(1.0, 0.0), Vector2(0.0, 1.0)],  # TUNING (not in GDD) from the dying flash in the sky across down to the necromancer and the Fossil Host
		],
	},
	{
		"id": "wild",  # TUNING (not in GDD) the part's id (Meta [epilogue] seen_wild)
		"act_id": "wild",  # TUNING (not in GDD) the StageRegistry.ACT_ORDER id of its act
		"achievement": "the_first_spring",
		"heading": "The First Spring",  # TUNING (not in GDD)
		"lines": [
			"The meteor's ash settled and the world grew back. The Turning Year did not forgive the dead for walking in it: the Wild closed round the army in thorn and root and wind.",  # TUNING (not in GDD)
			"The Stag King's Hunt rode out of the Greenwood and was burned out of its own thickets. At the Fae Court the Summer Queen offered her bargains, and the Court of Masks fell with its last smile.",  # TUNING (not in GDD)
			"At the foot of the World-Tree the Green Mother remembered every power that had ever claimed the dead, and called each one back in turn. The necromancer outlasted them all.",  # TUNING (not in GDD)
			"Beaten, she did not die. She took the dead into the soil and gave him the one claim left: the dead are not buried now, they are planted. When the First Spring came, they rose.",  # TUNING (not in GDD)
		],
		"panels": [
			["epilogue/wild_1", Vector2(0.0, 0.6), Vector2(1.0, 0.4)],  # TUNING (not in GDD) from the dead line along the closing path to the treants
			["epilogue/wild_2", Vector2(0.0, 0.5), Vector2(1.0, 0.5)],  # TUNING (not in GDD) from the burning thicket across to the Summer Queen's dais
			["epilogue/wild_3", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) from the crown of the World-Tree down the trunk to the necromancer
			["epilogue/wild_4", Vector2(0.5, 1.0), Vector2(0.5, 0.0)],  # TUNING (not in GDD) from the planted rows up to the necromancer and the blooming tree
		],
	},
]
## The closing cards, one after every part but the last (the Turning Year's part is
## the true ending), each hinting at the NEXT act in the order (owner: "tie
## everything together nicely"; docs/act4/PROPOSAL.md "Closing cards"; GDD §15.0
## "Closing cards, one per act" and "The reorder pass, part 2 (the story)").
## Each follows the PARTS row its `after` key names: it is shown right after that
## part's slides, once that part is open (in the main menu's Epilogue button and the
## autoplay-once flow alike). Keys: after (PARTS id), act (the small label),
## heading, line (the closing text), tag (small dim line under it), panel
## ([SpriteData key, pan start, pan end] as PARTS panels). Four cards are the
## owner-approved originals retargeted to the act that now comes next ("The River
## Runs Dry" Dynasty to Republic, "The Pit Keeps Count" Republic to Inferno, "The
## Sun Still Rises" Last Line to Shogunate with a reworded line, "The Beacons
## Burn" Eye to Empire with a new line); their panels keep their art keys.
const CLOSINGS := [
	{
		"after": "act1",  # TUNING (not in GDD) id of the PARTS row the card follows
		"act": "Beyond the coast",  # TUNING (not in GDD)
		"heading": "Gold on the Tide",  # TUNING (not in GDD)
		"line": "The Sanctum is ash, and the Covenant's tithe fleet drifts untended, its holds full of cathedral gold. Every pirate on the sea has smelled it, and they will not leave the dead alone.",  # TUNING (not in GDD)
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_act1", Vector2(0.0, 0.2), Vector2(1.0, 0.9)],  # TUNING (not in GDD) from the drifting fleet across the water to the far pirate sail
	},
	{
		"after": "corsair",  # TUNING (not in GDD) id of the PARTS row the card follows
		"act": "Inland",  # TUNING (not in GDD)
		"heading": "A Table Is Laid",  # TUNING (not in GDD)
		"line": "The sailors who came ashore brought the grave with them to Ravensmoor. In a castle on the hill, a table is being laid, and its host has been hungry for a thousand years.",  # TUNING (not in GDD)
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_corsair", Vector2(0.5, 1.0), Vector2(0.5, 0.0)],  # TUNING (not in GDD) from the village roofs below up to the lit window and the moon
	},
	{
		"after": "court",  # TUNING (not in GDD) id of the PARTS row the card follows
		"act": "The last cities",  # TUNING (not in GDD)
		"heading": "The Sirens Sound",  # TUNING (not in GDD)
		"line": "The veil is torn, and the living have seen the dead. In the last cities the sirens are sounding, and men with guns and capes are marching to the walls.",  # TUNING (not in GDD)
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_court", Vector2(1.0, 0.0), Vector2(0.0, 0.8)],  # TUNING (not in GDD) from the searchlit sky down across the barricaded street
	},
	{
		"after": "city",  # TUNING (not in GDD) follows the Last Line part ("No One Left"): Last Line to Shogunate
		"act": "Across the eastern sea",  # TUNING (not in GDD)
		"heading": "The Sun Still Rises",  # Owner-approved proposal (docs/act4/PROPOSAL.md "Closing cards")
		"line": "The last city has fallen and its last hero with it. Only one light still burns against the dead: across the eastern sea, a goddess opens her eyes.",  # TUNING (not in GDD) reworded for the final order (was: "Olympus is silent and Hades kneels. Only one light still burns against the dead: across the eastern sea, a goddess opens her eyes.")
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_act4", Vector2(0.0, 0.8), Vector2(1.0, 0.1)],  # TUNING (not in GDD) from the ruined throne across the dark sea to the torii and the opening eyes
	},
	{
		"after": "act5",  # TUNING (not in GDD) id of the PARTS row the card follows
		"act": "The far north",  # TUNING (not in GDD)
		"heading": "The Benches Stand Empty",  # TUNING (not in GDD)
		"line": "The sun is out, and the night has no end. In the frozen north the benches of a golden hall stand empty, and the one-eyed god who keeps them has begun to count the days to the end of the world.",  # TUNING (not in GDD)
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_shogunate", Vector2(0.0, 0.7), Vector2(1.0, 0.2)],  # TUNING (not in GDD) from the snowy approach across to the open hall doors and raven
	},
	{
		"after": "norse",  # TUNING (not in GDD) id of the PARTS row the card follows
		"act": "Beyond the desert",  # TUNING (not in GDD)
		"heading": "The Names Are Counted",  # TUNING (not in GDD)
		"line": "The All-Father is silent, and his hall stands empty. Far to the south, under the sand, an older empire is counting its dead by name, and it has found some that are missing.",  # TUNING (not in GDD)
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_norse", Vector2(0.0, 0.6), Vector2(1.0, 0.3)],  # TUNING (not in GDD) from the cartouche at the paw across the dunes to the pyramid
	},
	{
		"after": "dynasty",  # TUNING (not in GDD) follows the Dynasty part: Dynasty to Republic
		"act": "Beneath the world",  # TUNING (not in GDD)
		"heading": "The River Runs Dry",  # Owner-approved proposal (docs/act4/PROPOSAL.md "Closing cards")
		"line": "Far below the world, the river of the dead has run dry, and its ferryman has no one left to carry. On a mountain of marble, the gods have noticed.",  # Owner-approved proposal
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_act3", Vector2(0.5, 0.0), Vector2(0.4, 1.0)],  # TUNING (not in GDD) the gods on the marble mountain, down to the empty ferry and the lantern
	},
	{
		"after": "act4",  # TUNING (not in GDD) follows the Republic part ("The Gods Are Silent"): Republic to Inferno
		"act": "Far below",  # TUNING (not in GDD)
		"heading": "The Pit Keeps Count",  # Owner-approved proposal (docs/act5/PROPOSAL.md)
		"line": "Olympus is silent and the throne below is empty. Far below, the souls owed to the Pit have stopped arriving, and something down there has started counting.",  # TUNING (not in GDD) reworded for the final order (was: "The sun is out, and the night has no end. Far below, the souls owed to the Pit have stopped arriving, and something down there has started counting.")
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_act5", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) from the rim of the Pit, with the ledger slabs, down to the two red embers in the dark
	},
	{
		"after": "inferno",  # TUNING (not in GDD) id of the PARTS row the card follows
		"act": "Above the clouds",  # TUNING (not in GDD)
		"heading": "The Stair Comes Down",  # TUNING (not in GDD)
		"line": "Hell kneels, and its throne is a seat for one. Above the clouds a silver stair is unrolling, and the choirs at the top of it have stopped singing for the living.",  # TUNING (not in GDD)
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_inferno", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) from the gap in the clouds down the stair to the dark world
	},
	{
		"after": "host",  # TUNING (not in GDD) id of the PARTS row the card follows
		"act": "Beneath the sea",  # TUNING (not in GDD)
		"heading": "The Deep Dreams",  # TUNING (not in GDD)
		"line": "Heaven is silent, and still, far beneath the sea, something older than any of them is calling the dead. It has been calling since before the first prayer.",  # TUNING (not in GDD)
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_host", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) from the moon and the lantern down into the eye under the water
	},
	{
		"after": "act2",  # TUNING (not in GDD) follows the Eye part: Eye to Empire
		"act": "Beyond the realm",  # TUNING (not in GDD)
		"heading": "The Beacons Burn",  # TUNING (not in GDD) kept from the first card
		"line": "The Eye is blind, but its beacons still burn on the water. Far across the dark, something with no eyes of flesh has seen them, and it is turning to look.",  # TUNING (not in GDD) new line for the final order (was the holy orders lighting beacons and marching on the dead; the knights picture needs a redo, docs/last_acts/EPILOGUE_PANELS.md)
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close", Vector2(0.0, 0.0), Vector2(1.0, 0.85)],  # TUNING (not in GDD) the beacons, down to the knights at the gate
	},
	{
		"after": "act3",  # TUNING (not in GDD) id of the PARTS row the card follows
		"act": "Above the sky",  # TUNING (not in GDD)
		"heading": "The Signal Climbs",  # TUNING (not in GDD)
		"line": "The Empire's last signal did not stop at the edge of the sky. Far above the dark world, a fleet of strangers has turned toward it, and they have come to harvest.",  # TUNING (not in GDD)
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_empire_to_concord", Vector2(0.5, 1.0), Vector2(0.5, 0.0)],  # TUNING (not in GDD) from the dead tower up the beam to the turning fleet
	},
	{
		"after": "concord",  # TUNING (not in GDD) id of the PARTS row the card follows
		"act": "Before everything",  # TUNING (not in GDD)
		"heading": "The First Entry",  # TUNING (not in GDD)
		"line": "Before the Harvesters, before the gods, before anyone gave the dead a name, a log in a broken ship is open to its first page. The necromancer has a rift, and a day to spend.",  # TUNING (not in GDD)
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_concord", Vector2(0.0, 0.5), Vector2(1.0, 0.5)],  # TUNING (not in GDD) from the log-pillar across to the rift and the fern dawn
	},
	{
		"after": "primeval",  # TUNING (not in GDD) id of the PARTS row the card follows
		"act": "After the ash",  # TUNING (not in GDD)
		"heading": "The Seed Cracks",  # TUNING (not in GDD)
		"line": "The sky has fallen and the fire is out. In the grey ash a seed has cracked, and something green has been waiting a very long time for the dead.",  # TUNING (not in GDD)
		"tag": "To be continued.",  # TUNING (not in GDD)
		"panel": ["epilogue/close_primeval", Vector2(0.5, 0.0), Vector2(0.5, 1.0)],  # TUNING (not in GDD) from the fading trail in the sky down to the shoot in the ash
	},
]
## Line shown in place of a part that is still sealed.
const SEALED: String = "Sealed. %s to read on."  # TUNING (not in GDD) %s = the achievement's goal
## Heading of a sealed part's slide.
const SEALED_HEADING: String = "Sealed"  # TUNING (not in GDD)
## Screen title (kept for the Codex / menu wording).
const TITLE: String = "Epilogue"  # TUNING (not in GDD)

# ------------------------------------------------------------------ layout

## Size of a picture panel PNG (art px = layout px, 16:9; tools/epilogue_panel.py PANEL_W / PANEL_H).
const PANEL_ART := Vector2(1024.0, 576.0)  # TUNING (not in GDD)
## The picture window (layout px): the part of the panel in view, panned over
## it. With the header, the frame and three text lines the column is about
## 590 px tall (fits the 600 px of a phone's mobile layout).
const WINDOW := Vector2(944.0, 424.0)  # TUNING (not in GDD)
## Inner padding (px) of the picture's frame around the window.
const FRAME_PAD: float = 6.0  # TUNING (not in GDD)
## Height (px) reserved for the paragraph under the picture (three NAME lines).
const TEXT_HEIGHT: float = 96.0  # TUNING (not in GDD)
## Gap (px) between the column's rows (header, picture, text).
const ROW_GAP: int = 8  # TUNING (not in GDD)
## Gap (px) between the header row's heading, act label and Skip button.
const HEADER_GAP: int = 14  # TUNING (not in GDD)
## Gap (px) between the paragraph and the closing card's tag line.
const TAG_GAP: int = 2  # TUNING (not in GDD)
## Width (px) of the Skip button (top right; touch players have no Esc key).
const SKIP_WIDTH: float = 96.0  # TUNING (not in GDD)
## Height (px) of the Skip button.
const SKIP_HEIGHT: float = 34.0  # TUNING (not in GDD)
## Opacity (0..1) of the black backdrop: the epilogue is a cutscene, the menu
## diorama does not show through.
const BACKDROP_ALPHA: float = 1.0  # TUNING (not in GDD)
## Colour of the picture window while its panel PNG is missing.
const EMPTY_COLOUR := Color("#160A21")  # TUNING (not in GDD) ink_violet
## Multiply colour of a sealed part's first panel: a dark violet silhouette
## (the Codex's way of showing what is not met yet), panning like the rest.
const SEALED_TINT := Color(0.08, 0.06, 0.12)  # TUNING (not in GDD)

# ------------------------------------------------------------------ timing (real seconds)

## A slide lasts this long plus SLIDE_PER_CHAR per character of its text
## before it moves on by itself (s); the pan spans the whole slide.
const SLIDE_BASE: float = 6.0  # TUNING (not in GDD)
## Extra slide time per character of the paragraph (s): reading time.
const SLIDE_PER_CHAR: float = 0.045  # TUNING (not in GDD) a 185-character paragraph shows ~14 s
## Crossfade (s) between two slides' pictures (instant with Reduce motion).
const PICTURE_FADE: float = 0.9  # TUNING (not in GDD)
## Delay (s) after a slide starts before its text fades in.
const TEXT_DELAY: float = 0.5  # TUNING (not in GDD)
## Fade-in time (s) of a slide's text.
const TEXT_FADE: float = 1.1  # TUNING (not in GDD)
## Fade (s) of the whole screen at open and close (UiMotion handles the open).
const CLOSE_FADE: float = 0.6  # TUNING (not in GDD)
## Presses within this long (s) of the previous advance are ignored (a tap
## arrives as a touch and an emulated click; a held key repeats).
const ADVANCE_GUARD: float = 0.3  # TUNING (not in GDD)


## True when part `part` (a PARTS row) is open in the save.
static func is_open(part: Dictionary) -> bool:
	return Meta.achievements.has(String(part["achievement"]))


## True when at least one part is open (the main menu shows its button).
static func any_open() -> bool:
	for part: Dictionary in PARTS:
		if is_open(part):
			return true
	return false


## Seconds slide text `text` stays before the next slide (SLIDE_BASE + reading time).
static func slide_time(text: String) -> float:
	return SLIDE_BASE + SLIDE_PER_CHAR * float(text.length())


## The closing card that follows part `part_id` (a PARTS id), or an empty
## Dictionary when that part has none.
static func closing_after(part_id: String) -> Dictionary:
	for c: Dictionary in CLOSINGS:
		if String(c["after"]) == part_id:
			return c
	return {}

## Builds PARTS: ROWS in ACT_ORDER order, each with its "act" label
## ("Act XI: The Ancient Eye") from the act's derived number and name. An act
## with no row is skipped (the autotest "epilogue" line reports the count).
static func _ordered_parts() -> Array:
	var out: Array = []  # The parts in act order.
	for act: Dictionary in StageRegistry.ACT_ORDER:
		for row: Dictionary in ROWS:
			if String(row["act_id"]) == String(act["id"]):
				var part: Dictionary = row.duplicate()  # A mutable copy of the const row.
				part["act"] = "%s: %s" % [StageRegistry.act_name(StageRegistry.act_number(String(act["id"]))), String(act["subtitle"])]
				out.append(part)
	return out
