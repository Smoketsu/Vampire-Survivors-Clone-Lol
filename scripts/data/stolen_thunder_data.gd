## StolenThunderData — immutable rule constants of the Stolen Thunder spell, its
## evolution Gigantomachy and its paired passive Titan's Blood (Act IV, Mount
## Olympus; GDD §15.0 "Stolen Thunder, Titan's Blood and the Oathbreaker";
## owner-approved proposal: "Stolen Thunder: a charged bolt on the strongest
## enemy that chains to armoured foes", unlocked by slaying Zeus). Its
## per-level stat rows live in AbilityData.SPELLS and its evolution row in
## EvolutionData, like every spell; this file holds only the fixed rules the
## spell node (StolenThunder) reads, the passive's and the Oathbreaker's ids
## and keys. Data only.
class_name StolenThunderData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "stolen_thunder"
## Damage-source tag of the bolt and its chain (base spell).
const SOURCE: String = "stolen_thunder"
## Damage-source tag of the evolved bolts and their chains (Gigantomachy).
const EVOLVED_SOURCE: String = "gigantomachy"
## Damage-source tag of Gigantomachy's thunderclaps (the area at each hop).
const CLAP_SOURCE: String = "thunderclap"
## Seconds before the first charge starts after the spell is learned.
const FIRST_CHARGE: float = 0.8  # TUNING (not in GDD)
## Px above the necromancer's feet the charging orb hangs (drawing only).
const ORB_LIFT: float = 34.0  # TUNING (not in GDD)
## Seconds a drawn bolt or chain arc stays visible.
const ARC_TIME: float = 0.22  # TUNING (not in GDD)
## Pitch of the charge's crackle (Sfx "bolt_cast" from the startup bank: the
## spell is offered on every stage, where the Pantheon pack may not be loaded).
const CHARGE_PITCH: float = 0.6  # TUNING (not in GDD)
## Pitch of the strike's crack (Sfx "mage_burst", the startup bank).
const STRIKE_PITCH: float = 0.7  # TUNING (not in GDD)
## Most arcs drawn at once (the oldest is dropped beyond it).
const MAX_ARCS: int = 40  # TUNING (not in GDD)
## A foe is ARMOURED (the chain's prey) when its percentage armour is at least
## this, or it has flat armour, or it is bronze-clad (PantheonKit.is_bronze()).
const ARMOUR_MIN: float = 0.05  # TUNING (not in GDD) (a Footman 0.0, a Hoplite 0.2)

# --- Titan's Blood (the paired passive) ---
## Passive id of Titan's Blood (PassiveData, UnlockData).
const TITANS_BLOOD: String = "titans_blood"
## Its level-row key: extra chain hops (added to the spell's thunder_chains in
## AbilityManager.apply_spell_mods(), the one spell modifier path).
const CHAINS_KEY: String = "chain_bonus"
## Its level-row key: the share (0..1) cut from the charge time
## (thunder_charge, AbilityManager.apply_spell_mods()).
const CHARGE_KEY: String = "charge_cut"

# --- The Oathbreaker's innate: Kinslayer (StolenThunder) ---
## Character innate key: extra share of Stolen Thunder damage against bosses,
## minibosses (the gods) and Heroes (CharacterData INNATE_KEYS).
const DIVINE_KEY: String = "thunder_divine_bonus"
