## Palette — the game's colour language, per GDD §16 ("Combat visual language")
## and §17 ("Art"):
##   * Friendly undead / necromancy: blue, violet, green, bone.
##   * Crimson Covenant / holy effects: crimson, ivory, silver, gold.
## Every placeholder shape and effect pulls its colours from here so the
## language stays consistent and can be re-tuned in one place.
class_name Palette
extends RefCounted

# --- Friendly (necromancer + undead) ------------------------------------------

## Bone white for skulls and skeletal limbs.
const BONE := Color(0.87, 0.85, 0.76)
## Dull grey steel for skeletal armour (warrior body).
const UNDEAD_STEEL := Color(0.42, 0.48, 0.58)
## Cold blue used for warrior shields and friendly physical projectiles.
const COLD_BLUE := Color(0.38, 0.62, 0.98)
## Necrotic green (archers, priest halos, XP crystals, heals).
const NECRO_GREEN := Color(0.42, 0.95, 0.55)
## Violet shadow magic (mages, Shadow Bolt, Shadow Blast).
const VIOLET := Color(0.64, 0.36, 0.98)
## Deep purple of the necromancer's robe.
const ROBE := Color(0.24, 0.12, 0.34)
## Dark teal robe of the undead priest (now the Grave Mender).
const PRIEST_ROBE := Color(0.16, 0.36, 0.36)
## Deep cold-blue robe of the Crypt Warder (ward caster).
const WARDER_ROBE := Color(0.14, 0.23, 0.42)
## Deep violet vestment of the Profane Bishop (merged priest evolution).
const BISHOP_ROBE := Color(0.27, 0.12, 0.38)
## Blackened steel of the Death Knight (evolved Skeleton Warrior).
const DEATH_STEEL := Color(0.19, 0.21, 0.29)
## Dark violet robe of the Lich (evolved Undead Mage), outlined in VIOLET.
const LICH_ROBE := Color(0.21, 0.10, 0.33)
## Sickly grey-green stitched flesh of the Corpse Abomination (and its stomp).
const CORPSE_FLESH := Color(0.47, 0.56, 0.42)
## Near-black violet cloak of the Grave Rogue.
const ROGUE_CLOAK := Color(0.16, 0.10, 0.24)
## Blue-grey weathered stone of the Crypt Gargoyle.
const GARGOYLE_STONE := Color(0.46, 0.50, 0.58)
## Pale frost blue of the Frost Wraith's spectral body (chill tint too).
const FROST := Color(0.62, 0.84, 1.0)

# --- Hostile (Crimson Covenant) -----------------------------------------------

## Covenant crimson (tabards, cloaks).
const CRIMSON := Color(0.78, 0.10, 0.16)
## Darker crimson for shading / purifier bodies.
const DARK_CRIMSON := Color(0.45, 0.05, 0.09)
## Ivory cloth and robes.
const IVORY := Color(0.96, 0.93, 0.83)
## Polished silver armour.
const SILVER := Color(0.80, 0.82, 0.87)
## Radiant gold for holy magic, halos, telegraphs and elites.
const GOLD := Color(1.0, 0.82, 0.30)
## Orange-gold purifying flame.
const FLAME := Color(1.0, 0.55, 0.15)

# --- Hostile (the Ancient Eye, Act II) ------------------------------------------------

## Drowned teal of the Ancient Eye's robes (tools/palette.json "drowned"; darker and
## bluer than the UI's soul-teal, which means "affordable / focused / new").
const EYE_DROWNED := Color(0.227, 0.486, 0.502)
## Drowned teal in shadow ("drowned_dark").
const EYE_DROWNED_DARK := Color(0.106, 0.275, 0.314)
## Bioluminescent glow of the Eye's eyes and sigils ("biolume"; magenta-leaning, never
## the player's violet).
const EYE_BIOLUME := Color(0.690, 0.298, 0.753)
## Bioluminescent glow core ("biolume_glow").
const EYE_BIOLUME_GLOW := Color(0.941, 0.612, 0.949)

# --- Hostile (the Electronic Empire, Act III) -------------------------------------------

## Empire chrome in shadow (tools/palette.json "chrome_dark"): joints, gun metal.
const EMPIRE_CHROME_DARK := Color(0.173, 0.227, 0.314)
## Empire chrome ("chrome"): machine bodies, helmets, plates; bluer than the undead grey.
const EMPIRE_CHROME := Color(0.357, 0.451, 0.592)
## Lit chrome ("chrome_light"): top faces and visors.
const EMPIRE_CHROME_LIGHT := Color(0.616, 0.714, 0.839)
## Signal light housings in shadow ("signal_dark").
const EMPIRE_SIGNAL_DARK := Color(0.588, 0.141, 0.063)
## Warning red ("signal_red"): Lock-On lasers, sensor eyes, alarms (more orange than
## the Covenant crimson).
const EMPIRE_SIGNAL_RED := Color(0.878, 0.224, 0.118)
## Hard amber ("signal_amber"): running lights, screens, tracer rounds.
const EMPIRE_SIGNAL_AMBER := Color(1.0, 0.682, 0.102)
## White-hot core of the Empire's lights and lasers ("signal_glow").
const EMPIRE_SIGNAL_GLOW := Color(1.0, 0.922, 0.659)

# --- World / UI ---------------------------------------------------------------

## Graveyard soil base colour.
const GROUND := Color(0.085, 0.10, 0.11)
## Faint moonlit grid / path lines on the ground.
const GROUND_LINE := Color(0.13, 0.16, 0.17)
## Tombstone stone colour.
const STONE := Color(0.27, 0.29, 0.31)
## Spectral blue-green fog patches (GDD §11 art direction).
const FOG := Color(0.35, 0.75, 0.70, 0.06)
## Health bar fill for friendly units / player.
const HP_FRIENDLY := Color(0.35, 0.85, 0.45)
## Health bar fill for enemies.
const HP_ENEMY := Color(0.90, 0.22, 0.22)
## Health bar background.
const HP_BACK := Color(0.0, 0.0, 0.0, 0.6)
## Hit-flash colour drawn instead of body colours for a few frames.
const FLASH := Color(1.0, 1.0, 1.0)
## Experience bar fill.
const XP := Color(0.45, 0.85, 1.0)

# --- Hostile (the Olympian Republic, Act IV) ----------------------------------------
# GDD §15.0 "Act IV foundation (phase 1)": the fixed values of docs/act4/BRIEF_FOUNDATION.md
# (tools/palette.json ramps bronze, marble, aegean, owned by the art pass). Gold stays
# Palette.GOLD (evolution / chest / victory, and Glory).

## Bronze outline ink (tools/palette.json "bronze" ramp, darkest): every Pantheon sprite's outline.
const PANTHEON_BRONZE_INK := Color(0.118, 0.078, 0.031)  # #1E1408
## Bronze in shadow ("bronze_dark"): shield rims, greaves, the underside of helmets.
const PANTHEON_BRONZE_DARK := Color(0.420, 0.267, 0.137)  # #6B4423
## Bronze ("bronze"): hoplite shields and helmets, the Titans' plates; the Phalanx's locked shield line.
const PANTHEON_BRONZE := Color(0.659, 0.439, 0.180)  # #A8702E
## Lit bronze ("bronze_light"): highlights, crests, the locked wall's top edge.
const PANTHEON_BRONZE_LIGHT := Color(0.878, 0.663, 0.333)  # #E0A955
## Marble in shadow ("marble_dark"): column flutes, the Titans' joints, shades' cores.
const PANTHEON_MARBLE_DARK := Color(0.557, 0.541, 0.525)  # #8E8A86
## Marble ("marble"): columns, statues, the pale Shades of the Dead.
const PANTHEON_MARBLE := Color(0.812, 0.796, 0.769)  # #CFCBC4
## Lit marble ("marble_light"): highlights; the lightning's white core.
const PANTHEON_MARBLE_LIGHT := Color(0.957, 0.945, 0.918)  # #F4F1EA
## Aegean blue in shadow ("aegean_dark"): deep water, the wave's body, cloaks in shadow.
const PANTHEON_AEGEAN_DARK := Color(0.071, 0.243, 0.400)  # #123E66
## Aegean blue ("aegean"): heroes' cloaks, Poseidon's waves, Zeus's lightning glow.
const PANTHEON_AEGEAN := Color(0.173, 0.467, 0.722)  # #2C77B8
## Lit Aegean ("aegean_light"): foam lines, lightning halos, wave crests.
const PANTHEON_AEGEAN_LIGHT := Color(0.435, 0.714, 0.910)  # #6FB6E8

# --- Act V: the Shogunate of the Rising Sun ---
# GDD §15.0 "Act V foundation (phase 1)": the fixed values of docs/act5/BRIEF_FOUNDATION.md
# (tools/palette.json ramps lacquer, indigo, sakura, owned by the art pass). Steel uses the
# existing grey / chrome ramps; gold stays Palette.GOLD (evolution / chest / victory, and the sun).

## Lacquer outline ink (tools/palette.json "lacquer" ramp, darkest): every Shogunate sprite's outline.
const SHOGUN_LACQUER_INK := Color(0.102, 0.043, 0.047)  # #1A0B0C
## Lacquer in shadow ("lacquer_dark"): armour plates in shadow, the oni's skin in shadow.
const SHOGUN_LACQUER_DARK := Color(0.416, 0.078, 0.094)  # #6A1418
## Lacquer red ("lacquer"): samurai and ashigaru armour, banners, the oni's skin.
const SHOGUN_LACQUER := Color(0.702, 0.149, 0.169)  # #B3262B
## Lit lacquer ("lacquer_light"): highlights, the match cord's glow, torii gates.
const SHOGUN_LACQUER_LIGHT := Color(0.886, 0.349, 0.290)  # #E2594A
## Indigo in shadow ("indigo_dark"): ninja garb, the night's tint.
const SHOGUN_INDIGO_DARK := Color(0.086, 0.114, 0.220)  # #161D38
## Indigo ("indigo"): gunners' coats, ninja garb, the smoke of an ambush.
const SHOGUN_INDIGO := Color(0.180, 0.247, 0.455)  # #2E3F74
## Lit indigo ("indigo_light"): the rim that keeps a ninja readable on dark ground.
const SHOGUN_INDIGO_LIGHT := Color(0.416, 0.510, 0.753)  # #6A82C0
## Sakura in shadow ("sakura_dark"): blossom petals in shadow.
const SHOGUN_SAKURA_DARK := Color(0.659, 0.329, 0.431)  # #A8546E
## Sakura pink ("sakura"): blossoms, kimono accents.
const SHOGUN_SAKURA := Color(0.894, 0.580, 0.675)  # #E494AC
## Lit sakura ("sakura_light"): highlights, petals in the light.
const SHOGUN_SAKURA_LIGHT := Color(0.976, 0.827, 0.867)  # #F9D3DD

# --- Act VI: the Inferno ---
# GDD §15.0 "Act VI foundation (phase 1)": the fixed values of docs/act6/BRIEF_FOUNDATION.md
# (tools/palette.json ramps obsidian, lava, demon, charm, owned by the art pass). Gold keeps
# its meaning (evolution / chest / victory); charm pink is the act's signature colour
# (Temptation).

## Obsidian outline ink (tools/palette.json "obsidian" ramp, darkest): every Inferno sprite's outline.
const INFERNO_OBSIDIAN_INK := Color(0.043, 0.039, 0.063)  # #0B0A10
## Dark obsidian ("obsidian_dark"): armour shadows, the pits' crust, portal stone.
const INFERNO_OBSIDIAN_DARK := Color(0.118, 0.102, 0.149)  # #1E1A26
## Obsidian ("obsidian"): hell knight plate, the ash plain's rocks, portal rings.
const INFERNO_OBSIDIAN := Color(0.208, 0.180, 0.251)  # #352E40
## Lit obsidian ("obsidian_light"): glassy highlights on armour and rock.
const INFERNO_OBSIDIAN_LIGHT := Color(0.353, 0.314, 0.408)  # #5A5068
## Dark lava ("lava_dark"): cooling crust, ember cracks, a pit's rim.
const INFERNO_LAVA_DARK := Color(0.541, 0.165, 0.031)  # #8A2A08
## Lava ("lava"): the Hell Pits' fire, burning blades, ember armour.
const INFERNO_LAVA := Color(0.878, 0.376, 0.102)  # #E0601A
## Lit lava ("lava_light"): the pits' white-hot core, telegraph rims, sparks.
const INFERNO_LAVA_LIGHT := Color(1.000, 0.702, 0.278)  # #FFB347
## Dark demon skin ("demon_dark"): shadowed crimson-violet skin, wings.
const INFERNO_DEMON_DARK := Color(0.361, 0.102, 0.227)  # #5C1A3A
## Demon skin ("demon"): imps, brutes, the succubus's wings and tail.
const INFERNO_DEMON := Color(0.608, 0.176, 0.369)  # #9B2D5E
## Lit demon skin ("demon_light"): skin highlights.
const INFERNO_DEMON_LIGHT := Color(0.831, 0.361, 0.541)  # #D45C8A
## Charm pink ("charm"): Temptation (hearts over a charmed summon, the kiss, portal swirls).
const INFERNO_CHARM := Color(1.000, 0.435, 0.710)  # #FF6FB5
## Lit charm pink ("charm_light"): heart highlights, the sealing ring's glow.
const INFERNO_CHARM_LIGHT := Color(1.000, 0.722, 0.867)  # #FFB8DD

# --- Act VII: the Sanguine Court ---
# GDD §15.0 "Act VII foundation (phase 1)": the fixed values of docs/act7/BRIEF_FOUNDATION.md
# (tools/palette.json ramps blood, velvet, moonlight, owned by the art pass). Candle gold is the
# existing gold and keeps its meaning (evolution / chest / victory); fresh blood is the act's
# signature colour (Bloodfeast).

## Blood outline ink (tools/palette.json "blood" ramp, darkest): every Court sprite's outline.
const COURT_BLOOD_INK := Color(0.071, 0.024, 0.039)  # #12060A
## Dark blood ("blood_dark"): dried blood, the shadows of the knights' plate, a blood shield's edge.
const COURT_BLOOD_DARK := Color(0.353, 0.039, 0.078)  # #5A0A14
## Blood ("blood"): Bloodfeast's red thread, the knights' plate, the Blood Moon's tint.
const COURT_BLOOD := Color(0.639, 0.078, 0.165)  # #A3142A
## Fresh blood ("blood_light"): the act's signature colour: a feeding thread's bright core, a shield's glint.
const COURT_BLOOD_LIGHT := Color(0.878, 0.220, 0.306)  # #E0384E
## Dark velvet ("velvet_dark"): gowns and capes in shadow, coffin wood.
const COURT_VELVET_DARK := Color(0.086, 0.059, 0.110)  # #160F1C
## Velvet ("velvet"): the nobles' gowns, the bats' wings, the castle's banners.
const COURT_VELVET := Color(0.169, 0.118, 0.212)  # #2B1E36
## Lit velvet ("velvet_light"): highlights on velvet and wings.
const COURT_VELVET_LIGHT := Color(0.302, 0.227, 0.369)  # #4D3A5E
## Dark moonlight ("moon_dark"): silver in shadow, the werewolf hunter's crossbow, moor stone.
const COURT_MOON_DARK := Color(0.431, 0.478, 0.549)  # #6E7A8C
## Moonlight ("moon"): silver, pale thralls' skin, the moon on a clear night.
const COURT_MOON := Color(0.706, 0.753, 0.816)  # #B4C0D0
## Lit moonlight ("moon_light"): silver glints, mist.
const COURT_MOON_LIGHT := Color(0.902, 0.933, 0.969)  # #E6EEF7

# --- Act VIII: the Last Line ---
# GDD §15.0 "Act VIII foundation (phase 1)": the fixed values of docs/act8/BRIEF_FOUNDATION.md
# (tools/palette.json ramps asphalt, concrete, neon, olive, siren, owned by the art pass). Gold keeps
# its meaning (evolution / chest / victory) and crimson stays danger; the heroes' bright colours pop
# off the asphalt.

## City outline ink (tools/palette.json "asphalt" ramp, darkest): every City sprite's outline.
const CITY_INK := Color(0.063, 0.067, 0.078)  # #101114
## Dark asphalt ("asphalt_dark"): alleys, the road in shadow, tyres.
const CITY_ASPHALT_DARK := Color(0.118, 0.125, 0.141)  # #1E2024
## Asphalt ("asphalt"): the streets' roadway.
const CITY_ASPHALT := Color(0.227, 0.239, 0.267)  # #3A3D44
## Concrete ("concrete"): sidewalks, curbs, rooftops, the base's walls.
const CITY_CONCRETE := Color(0.333, 0.349, 0.373)  # #55595F
## Lit concrete ("concrete_light"): curb edges, parapets, plaza paving.
const CITY_CONCRETE_LIGHT := Color(0.478, 0.498, 0.529)  # #7A7F87
## Sodium orange ("sodium"): streetlights, the lane lines, headlight glow.
const CITY_SODIUM := Color(0.910, 0.643, 0.227)  # #E8A43A
## Neon pink ("neon_pink"): signs of the Night Market, the gangs' colours.
const CITY_NEON_PINK := Color(1.000, 0.310, 0.659)  # #FF4FA8
## Neon cyan ("neon_cyan"): signs, the speedster's trail, a super's plate edge.
const CITY_NEON_CYAN := Color(0.247, 0.878, 0.910)  # #3FE0E8
## Dark olive ("olive_dark"): the army's drab in shadow, tank hulls.
const CITY_OLIVE_DARK := Color(0.294, 0.325, 0.188)  # #4B5330
## Olive ("olive"): the army's drab, tanks, sandbags.
const CITY_OLIVE := Color(0.420, 0.459, 0.271)  # #6B7545
## Hazard yellow ("hazard"): hazard stripes, the escalation badge, a shell's landing ring.
const CITY_HAZARD := Color(0.949, 0.769, 0.094)  # #F2C418
## Police blue ("police_blue"): the police's uniforms and the light bar's blue half.
const CITY_POLICE_BLUE := Color(0.180, 0.373, 0.816)  # #2E5FD0
## Siren red ("siren_red"): the light bar's red half (pulsed slowly, never a flash).
const CITY_SIREN_RED := Color(0.847, 0.165, 0.165)  # #D82A2A
## Hero orange ("hero_orange"): the speedster's suit, a super's plate accent.
const CITY_HERO_ORANGE := Color(0.941, 0.478, 0.118)  # #F07A1E
