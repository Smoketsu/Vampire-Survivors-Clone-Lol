## BannerData — the fixed rules of the Banner of the Dead spell, its evolution
## Hundred Banners and its paired passive Warlord's Seal (Act V, Castle
## Kurogane; owner-approved Act V proposal "Rewards": "Banner of the Dead: a war
## banner planted where you stand; summons near it attack faster -> Hundred
## Banners (+ Warlord's Seal)"; GDD §15.0 "Banner of the Dead, Warlord's Seal and
## the Ronin Revenant"). The levelled numbers live in AbilityData.SPELLS
## "banner_of_the_dead", EvolutionData.EVOLUTIONS "hundred_banners" and
## PassiveData.PASSIVES "warlords_seal"; these are the rules that do not level.
## The attack speed reaches the summons through ONE read,
## HordeDirector.attack_haste() (SummonedUnit's attack timer), the same on every
## stage (no act-only rule). Logic: BannerOfTheDead. Data only (CLAUDE.md rule 2).
class_name BannerData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData, the spell book).
const SPELL: String = "banner_of_the_dead"
## Evolution id (EvolutionData.EVOLUTIONS).
const EVOLUTION: String = "hundred_banners"
## Damage source tag of the planting blast (CombatResolver "dmg_<tag>").
const SOURCE: String = "banner_of_the_dead"
## Damage source tag of Hundred Banners' blasts and war-drum pulses.
const EVOLVED_SOURCE: String = "hundred_banners"
## Paired passive id (PassiveData.PASSIVES).
const SEAL: String = "warlords_seal"
## Warlord's Seal's level-row key: the attack-speed share summons near the
## necromancer gain (fraction).
const SEAL_KEY: String = "seal_haste"
## px around the necromancer Warlord's Seal reaches (about the Bone Ring and
## its blockers' reach).
const SEAL_RADIUS: float = 170.0  # TUNING (not in GDD)
## The Ronin Revenant's innate key (CharacterData): an extra share of his
## banners' haste (x (1 + value)).
const INNATE_KEY: String = "banner_haste_bonus"
## Seconds before the first planting once the spell is learned.
const FIRST_PLANT: float = 0.5  # TUNING (not in GDD)
## px from the necromancer Hundred Banners' banners are planted on a ring
## (evenly round it, the first toward his facing).
const RING: float = 80.0  # TUNING (not in GDD)
## Most banners standing at once (a planting past it uproots the oldest).
const MAX_STANDING: int = 8  # TUNING (not in GDD)
## Seconds a planting's blast ring shows (drawing only).
const BLAST_TIME: float = 0.35  # TUNING (not in GDD)
## The banner's cloth (lacquer black; drawing only).
const CLOTH := Color(0.10, 0.04, 0.05)  # TUNING (not in GDD) Palette.SHOGUN_LACQUER_INK
## The banner's skull-circle emblem and aura (the player's violet; drawing only).
const EMBLEM := Color(0.64, 0.36, 0.98)  # TUNING (not in GDD) Palette.VIOLET
## The banner's bone pole (drawing only).
const POLE := Color(0.85, 0.80, 0.67)  # TUNING (not in GDD) bone
## Alpha of the aura disc on the ground (drawing only).
const AURA_ALPHA: float = 0.10  # TUNING (not in GDD)
## Sound pitch of a planting (Sfx "bone_wall" / startup bank; audio only).
const PLANT_PITCH: float = 0.8  # TUNING (not in GDD)
