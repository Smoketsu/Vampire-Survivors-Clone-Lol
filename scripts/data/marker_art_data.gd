## MarkerArtData: sprite keys and placement of the placeholder art batch
## (docs/art/ART_BIBLE.md "Placeholder art batch", GDD §15.0 "Placeholder art
## batch"): the small world markers, overlays and spell props that were still
## drawn in code. Each drawing site asks SpriteBank for its key first and keeps
## its code drawing as the fallback when the PNG is missing; rings, telegraphs,
## zones, glows and progress arcs stay in code. Sizes of the flat sprites are in
## SpriteData.FLAT_SIZES, of the world sprites in SpriteData.HEIGHTS. Purely
## visual: nothing here touches gameplay state or RNG. Data only, no logic.
class_name MarkerArtData
extends RefCounted

# --- Covenant marks ----------------------------------------------------------------

## Pennant of a boss's Call to Arms rally point (StageDirector._draw_mark()).
const RALLY_PENNANT: String = "markers/rally_pennant"  # TUNING (not in GDD)
## Centre of the pennant sprite relative to the mark (px): its pole (2 px left
## of the sprite's centre) stands where the code pole stood, its foot 6 px
## below the mark.
const RALLY_PENNANT_OFFSET := Vector2(2.0, -9.0)  # TUNING (not in GDD)
## Gold chevron over a Covenant soldier buffed by an aura (MarchGlyphs.draw_buffed()).
const BUFF_CHEVRON: String = "markers/buff_chevron"  # TUNING (not in GDD)
## Gold shield badge of a Sun Paladin's ward (SanctumGlyphs.draw_ward()).
const SUN_WARD: String = "markers/sun_ward"  # TUNING (not in GDD)
## Ivory cross in the middle of each of Seraphine's nova safe circles (SeraphineHazards).
const SANCTUARY_CROSS: String = "markers/sanctuary_cross"  # TUNING (not in GDD)
## Opacity (0-1) of the sanctuary cross (the code sigil was drawn at 0.8).
const SANCTUARY_CROSS_ALPHA: float = 0.9  # TUNING (not in GDD)

# --- Undead and player marks ---------------------------------------------------------

## Volley of the Fallen mark over an enemy (Enemy._draw_over(); the code
## diamond, ProgressionGlyphs.draw_mage_mark(), is its fallback).
const MAGE_MARK: String = "markers/mage_mark"  # TUNING (not in GDD)
## Skull over an enemy branded by Death Mark (GraveSpellGlyphs.draw_brand()).
const DEATH_BRAND: String = "markers/death_brand"  # TUNING (not in GDD)
## Skull over an enemy branded by the evolved Doom Brand.
const DEATH_BRAND_DOOM: String = "markers/death_brand_doom"  # TUNING (not in GDD)
## Gap (px) between the top of the body circle and the brand skull's centre
## (the code skull sat 9 px above it).
const DEATH_BRAND_RISE: float = 10.0  # TUNING (not in GDD)
## Stun stars over a stunned enemy (ReaperHorrorGlyphs.draw_stun()); a still
## (the overlay layer redraws only when the unit's look changes, so a loop
## would need per-frame redraws).
const STUN_STARS: String = "markers/stun_stars"  # TUNING (not in GDD)

# --- Overlays --------------------------------------------------------------------------

## Ice shell over an enemy or boss frozen by Stasis or Deep Freeze (PowerupGlyphs.draw_frozen()).
const FROZEN_SHELL: String = "overlays/frozen_shell"  # TUNING (not in GDD)
## Height of the drawn shell (px) per px of body radius, rounded to a whole
## scale of the 40 px sprite (x1 up to a body radius of about 18 px, x2 for the
## bosses), so its pixels stay even squares and bosses get a shell their size.
const FROZEN_SHELL_PER_RADIUS: float = 3.2  # TUNING (not in GDD)
## Lift (fraction of the body radius) of the shell's centre above the body
## origin, toward the sprite's centre (sprites sit above their feet).
const FROZEN_SHELL_LIFT: float = 0.4  # TUNING (not in GDD)
## Opacity (0-1) of the ice shell sprite (the body shows through the ring's
## open centre; the code's translucent cold disc stays under it).
const FROZEN_SHELL_ALPHA: float = 0.9  # TUNING (not in GDD)
## Radius of the translucent cold disc under the shell, as a fraction of the
## drawn shell's height (it fills the ring's open centre).
const FROZEN_DISC_FRACTION: float = 0.36  # TUNING (not in GDD)
## Suffix of a summon's stone-form still: "summons/<kind>" + this, drawn while
## SummonedUnit.stone_form (the Cathedral Horror after landing).
const STONE_SUFFIX: String = "_stone"  # TUNING (not in GDD)

# --- Spell props ----------------------------------------------------------------------

## Corpse Explosion corpses lying on the ground, one per pool slot k (variant
## CORPSES[k % size], fixed by the slot: no RNG).
const CORPSES: Array[String] = ["decals/corpse", "decals/corpse_2", "decals/corpse_3"]  # TUNING (not in GDD)
## Opacity of a corpse sprite at its freshest and at its oldest (it fades as it
## ages, like the code corpse).
const CORPSE_ALPHA_FRESH: float = 1.0  # TUNING (not in GDD)
const CORPSE_ALPHA_OLD: float = 0.35  # TUNING (not in GDD) opacity just before a corpse expires
## One Bone Wall segment (GraveSpellGlyphs.draw_wall_segment()); odd segments
## are mirrored so a wall does not repeat one shape.
const BONE_WALL_SEGMENT: String = "structures/bone_wall_segment"  # TUNING (not in GDD)
## One Charnel Bastion (evolved Bone Wall) ring segment.
const BONE_WALL_BASTION: String = "structures/bone_wall_bastion"  # TUNING (not in GDD)
## Corpse Catapult boulder in flight (WarbandGlyphs.draw_boulder()).
const BOULDER: String = "projectiles/corpse_boulder"  # TUNING (not in GDD)
## Ossuary Engine burning boulder in flight.
const BOULDER_BURNING: String = "projectiles/corpse_boulder_burning"  # TUNING (not in GDD)
## Offset (px) of the burning boulder's sprite centre: its flames rise above
## the skull, so the skull sits on the boulder's position.
const BOULDER_BURNING_OFFSET := Vector2(0.0, -4.0)  # TUNING (not in GDD)
## Boulder radius (px) at which the sprite is drawn 1:1; a boulder high in its
## arc is drawn larger (radius / this), its art scaled up through the
## sharp-pixel shader (never below 1:1).
const BOULDER_BASE_RADIUS: float = 7.0  # TUNING (not in GDD)
## Bone Oracle "Ossuary Ward" orbiting bone shard (CharacterInnates), turned
## along its orbit.
const ORACLE_SHARD: String = "projectiles/oracle_shard"  # TUNING (not in GDD)
## Eclipse Ward (evolved Orb Shield) orb, its soul-green crescent turned outward.
const ECLIPSE_ORB: String = "projectiles/eclipse_orb"  # TUNING (not in GDD)
## Opacity of an Eclipse Ward orb while it recharges.
const ECLIPSE_ORB_DIM_ALPHA: float = 0.45  # TUNING (not in GDD) same as the Orb Shield's dim orb

# --- UI ---------------------------------------------------------------------------------

## The phone of the "turn your device" overlay (RotateOverlay), drawn at
## TouchData.ROTATE_PHONE_SIZE (35 x 60 art px at x2 = 70 x 120 layout px).
const ROTATE_PHONE: String = "ui/rotate_phone"  # TUNING (not in GDD)
