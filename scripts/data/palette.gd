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
