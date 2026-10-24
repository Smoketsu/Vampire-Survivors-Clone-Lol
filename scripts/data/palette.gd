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
