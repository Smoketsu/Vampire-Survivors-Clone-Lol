## CoopSlot — one player of a co-op run (docs/coop/DESIGN.md): the objects that
## belong to that player alone. Game keeps its per-player fields (`game.player`,
## `game.horde`, `game.abilities`, ...) pointing at the BOUND slot's objects;
## CoopSession.bind() swaps them, so every existing system that reads
## `game.player` acts for the slot being stepped (see CoopSession's header).
## Holds no logic beyond its own bookkeeping; the session drives it.
class_name CoopSlot
extends RefCounted

## Slot index (0 = the host, 1 = the guest; the fixed stepping order).
var index: int = 0
## The lobby loadout of this player (CoopNet start_info "loadouts" entry, or the
## autotest's): character_id, skin_id, ultimate_id, title_id, meta_levels, mastery_levels,
## unlocks, name. Read once at run start.
var loadout: Dictionary = {}
## Display name (loadout "name"; "P1" / "P2" when none).
var display_name: String = ""

# --- The player's own systems (what Game binds) ---------------------------------------

## This player's necromancer.
var player: Necromancer = null
## This player's undead army.
var horde: HordeDirector = null
## This player's spells, passives and level-up offers.
var abilities: AbilityManager = null
## This player's Grave Step dash.
var grave_step: GraveStep = null
## This player's soul meter and Dread Rally.
var dread_rally: DreadRally = null
## This player's chosen ultimate.
var ultimates: UltimateSystem = null
## This player's army formation numbers (the Bone Ring).
var stance: ArmyStance = null
## This player's playable character (the one character path).
var character: CharacterModifiers = null
## This player's character innate.
var innates: CharacterInnates = null
## This player's Ossuary (Soul Ash) upgrades.
var meta: MetaModifiers = null
## This player's bullet heaven volleys (their own shot cap).
var volleys: VolleyDirector = null
## This player's Act II Dread (null outside Act II).
var dread: DreadMeter = null
## This player's one-run achievement counters.
var rewards: RunRewards = null
## The autotest bot driving this slot (null when a human or the network does).
var bot: Autotest = null
## Power-up timed buffs of this player (PowerupManager.timers while bound).
var powerup_timers: Dictionary = {}
## Stasis length of this player's current Stasis buff (PowerupManager.stasis_total).
var stasis_total: float = 0.0

# --- Co-op state ------------------------------------------------------------------------------

## True while this necromancer lies downed (0 HP before 0:00, waiting for a revive).
var downed: bool = false
## Seconds of revive progress (0..CoopData.REVIVE_TIME) the partner has built up.
var revive_progress: float = 0.0
## Movement input of this tick (unit vector or less), written by the lockstep
## driver for a networked slot (Necromancer.step() reads it through
## CoopSession.move_input()); zero for a bot slot (the bot steers itself).
var move: Vector2 = Vector2.ZERO

# --- Counters (autotest per-slot lines; never read by gameplay) ---------------------

## Enemies this player's systems killed (the killing blow was dealt while bound).
var kills: int = 0
## Times this necromancer was downed.
var downs: int = 0
## Times this player raised the partner.
var revives_given: int = 0
## Lowest HP seen before 0:00 (the autotest's "nigh-unkillable" check).
var min_hp: float = 9999.0
## Game seconds spent downed.
var downed_time: float = 0.0
## Most summons this player had alive at once.
var peak_army: int = 0
## XP this player's pickups fed into the shared bar.
var xp_collected: int = 0
## Treasure chests this player opened.
var chests_opened: int = 0


## True when the necromancer stands (not downed, not dead).
func alive() -> bool:
	return player != null and not downed and not player.dead
