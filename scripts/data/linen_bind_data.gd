## LinenBindData — immutable rule constants of the Linen Bind spell, its
## evolution Eternal Shroud, its paired passive Natron Salts and the
## Embalmer's innate (temporary Act XII, the Necropolis of Sand; GDD §15.0
## "Linen Bind, Eternal Shroud, Natron Salts and the Embalmer (Act XII)";
## owner-approved proposal: "Linen Bind: spectral bandages wrap up to 5
## enemies and hold them 1.2 s; wrapped enemies that die rise as temporary
## Mummies -> Eternal Shroud (+ Natron Salts)"; unlocked by slaying Anubis).
## Its per-level stat rows live in AbilityData.SPELLS and its evolution row in
## EvolutionData, like every spell; this file holds only the fixed rules the
## spell node (LinenBind) reads and the passive's and the innate's keys. Data
## only.
class_name LinenBindData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData). Never an enemy kind, a structure,
## a source tag or a Dynasty sound / rule name.
const ID: String = "linen_bind"
## Damage-source tag of the base spell's binding.
const SOURCE: String = "linen_bind"
## Damage-source tag of the evolved binding (Eternal Shroud).
const EVOLVED_SOURCE: String = "eternal_shroud"
## Evolution id (EvolutionData).
const EVOLUTION: String = "eternal_shroud"

# --- The risen Mummies (HordeDirector.raise_corpse(), the one raise path) ---
## Summon class a wrapped foe rises as (its stats; drawn as RISEN_GLYPH).
const RISEN_CLASS: String = "warrior"  # TUNING (not in GDD) a melee body, as Death Mark's Risen
## Damage / stats tag of a risen Mummy's blows (PassiveData.MINION_EXTRA_TAGS:
## Unholy Precision crits them like every raised summon).
const RISEN_TAG: String = "linen_mummy"
## Summon glyph / sprite of a risen Mummy (assets/sprites/summons/linen_mummy:
## the Dynasty mummy in the necromancer's bone and soul-teal).
const RISEN_GLYPH: String = "linen_mummy"
## x the risen class's max HP.
const RISEN_HP: float = 0.6  # TUNING (not in GDD) (Death Mark's Risen 0.5)
## x the risen class's damage.
const RISEN_DAMAGE: float = 0.7  # TUNING (not in GDD) (Death Mark's Risen 0.6)

# --- Drawing (visual only) ---
## The bandages' colour (the necromancer's bone, soul-teal edged: the
## player's own linen, never the Dynasty's bronze).
const LINEN_COLOR := Color(0.92, 0.89, 0.80)  # TUNING (not in GDD)
## The soul-teal of the wrap's glow.
const GLOW_COLOR := Color(0.36, 0.94, 0.86)  # TUNING (not in GDD) the necromancer's soul-teal
## Seconds a cast's bandage lines stay drawn.
const LINE_FADE: float = 0.3  # TUNING (not in GDD)
## Seconds a cast waits before trying again when no foe stands in range.
const WAIT_RETRY: float = 0.3  # TUNING (not in GDD)
## Most wrapped foes remembered at once (older marks drop first).
const MAX_MARKS: int = 48  # TUNING (not in GDD)

# --- The hold (CombatResolver.stun_enemy(), the one enemy stun path) ---
## x the hold on bosses and minibosses (they shrug the linen off).
const BOSS_HOLD_MULT: float = 0.25  # TUNING (not in GDD)
## x the hold on elites.
const ELITE_HOLD_MULT: float = 0.6  # TUNING (not in GDD)

# --- Natron Salts (the paired passive) ---
## Passive id of Natron Salts (PassiveData, UnlockData).
const NATRON_SALTS: String = "natron_salts"
## Its level-row key: share (0..1) more binding damage.
const NATRON_DMG_KEY: String = "bind_bonus"
## Its level-row key: seconds more hold.
const NATRON_HOLD_KEY: String = "hold_bonus"

# --- The Embalmer's innate: Linen Ward (Linen Bind) ---
## Innate value key: risen Mummies last this many seconds more (CharacterData
## "the_embalmer"; game.character.innate_value()).
const EXTRA_LIFE_KEY: String = "linen_mummy_life"
