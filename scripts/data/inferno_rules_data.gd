## InfernoRulesData — the numbers of the Inferno's three shared rules (Act VI;
## GDD §15.0 "Act VI foundation (phase 1)", "Hell Pits", "Portals" and
## "Temptation"), each with ONE code path, inert on Acts I to V (Game.inferno
## stays null there):
##   PITS — HellPits: burning pools on the ground that damage anyone standing
##       in them, demons excepted (the necromancer, summons, the damned, the
##       living). Fixed pits per zone (a seeded hash of the world cells, so they
##       are the same in every run of a stage) and telegraphed pits that open
##       near the necromancer and close again. A stage's STAGE "pits"
##       dictionary overrides any key ({} = these defaults).
##   PORTALS — DemonPortals: demon_portal structures that pour out a squad
##       every few seconds; destroyed by damage, or SEALED by a necromancer
##       standing in the ring for seal_time s (a Soul Ash bounty). A stage's
##       STAGE "portals" dictionary overrides any key ({} = these defaults).
##   TEMPTATION — Temptation (HordeDirector.charm()): a charmer kind charms a
##       summon, which fights for hell for a few seconds, then comes back.
##   LAST_JUDGMENT — the shared Act VI Reckoning hook (a stage's RECKONING
##       "last_judgment" dictionary overrides these keys; absent = no Last
##       Judgment): every portal opens at once, the pits open faster each
##       minute, and the Adversary's hand reaches up through the floor.
##   SOUNDS — event -> sound id map (one place to switch the Inferno pack in).
## Counter-passive hooks (NOT built in phase 1; AbilityManager.passive_value()
## returns 0 while no PassiveData row exists, so each hook is exactly 1):
##   SALT_CIRCLE — summons take less pit damage (HellPits.salt_circle_mult(),
##       the one read).
##   FAITHLESS — charms on summons last shorter (Temptation.faithless_mult(),
##       the one read).
## Data only (CLAUDE.md rule 2). Every number is TUNING (not in GDD) unless
## marked as the owner-approved proposal.
class_name InfernoRulesData
extends RefCounted

# --- Hell Pits (HellPits) ----------------------------------------------------------------

## The Hell Pits' defaults (a stage's STAGE "pits" overrides any key).
##   tick            — s between two burns of everything standing in a pit.
##   dps_player      — damage per second to the necromancer (x the enemies'
##                     damage scaling, EnemyDirector.damage_mult).
##   dps_summon      — damage per second to a summon (x the damage scaling, x
##                     Salt Circle).
##   dps_enemy       — damage per second to a non-demon enemy (x the enemies'
##                     HP scaling, EnemyDirector.hp_mult, so the pits stay a
##                     threat to them all run).
##   damned_mult     — x dps_enemy for a `damned` kind (the damned burn fast:
##                     luring them through the pits is the counterplay).
##   telegraph       — s of the glowing rim before a pit burns (owner-approved
##                     proposal: "a glowing rim for 1.5 s").
##   close_time      — s a closing pit takes to cool (drawn only; no burn).
##   start_at        — game time (s) of the first telegraphed pit.
##   open_every      — s between two telegraphed pits near a necromancer (at
##                     the start of the run).
##   open_every_min  — the shortest interval (s) they reach.
##   open_every_step — s the interval shortens every minute of game time.
##   life_min / life_max — s a telegraphed pit burns before it closes.
##   radius_min / radius_max — px of a telegraphed pit.
##   dist_min / dist_max — px from the necromancer a telegraphed pit opens
##                     (some under the Bone Ring, some in front of it).
##   max_temp        — most telegraphed pits open at once (the oldest close).
##   fixed_cell      — px of one world cell of the fixed-pit hash.
##   fixed_chance    — per zone (index of the STAGE "zones"), the chance
##                     (0..1) a world cell holds a fixed pit in that zone.
##   fixed_radius_min / fixed_radius_max — px of a fixed pit.
##   fixed_margin    — px a fixed pit keeps from its cell's edges.
##   fixed_clear     — px around the world origin with no fixed pit (the
##                     necromancer's start).
##   active_radius   — px around each necromancer in which fixed pits are live
##                     (drawn and burning).
##   refresh         — s between two rebuilds of the live fixed-pit list.
##   avoid_margin    — px a ring post keeps from a pit's edge (avoid_point()).
##   danger_reach    — px beyond a pit's edge the autotest bot keeps away.
##   max_pits        — hard cap of telegraphed + opened pits (open_pit()).
const PITS := {
	"tick": 0.25,  # TUNING (not in GDD) s
	"dps_player": 6.0,  # TUNING (not in GDD)
	"dps_summon": 9.0,  # TUNING (not in GDD)
	"dps_enemy": 10.0,  # TUNING (not in GDD)
	"damned_mult": 3.0,  # TUNING (not in GDD)
	"telegraph": 1.5,  # Owner-approved proposal: "a glowing rim for 1.5 s"
	"close_time": 0.8,  # TUNING (not in GDD) s
	"start_at": 40.0,  # TUNING (not in GDD) s
	"open_every": 11.0,  # TUNING (not in GDD) s
	"open_every_min": 5.0,  # TUNING (not in GDD) s
	"open_every_step": 0.35,  # TUNING (not in GDD) s per minute
	"life_min": 8.0,  # TUNING (not in GDD) s
	"life_max": 14.0,  # TUNING (not in GDD) s
	"radius_min": 30.0,  # TUNING (not in GDD) px
	"radius_max": 52.0,  # TUNING (not in GDD) px
	"dist_min": 50.0,  # TUNING (not in GDD) px
	"dist_max": 240.0,  # TUNING (not in GDD) px
	"max_temp": 8,  # TUNING (not in GDD)
	"fixed_cell": 560.0,  # TUNING (not in GDD) px
	"fixed_chance": [0.3, 0.38, 0.45, 0.5],  # TUNING (not in GDD) one per zone; the last repeats
	"fixed_radius_min": 38.0,  # TUNING (not in GDD) px
	"fixed_radius_max": 72.0,  # TUNING (not in GDD) px
	"fixed_margin": 90.0,  # TUNING (not in GDD) px
	"fixed_clear": 300.0,  # TUNING (not in GDD) px
	"active_radius": 1000.0,  # TUNING (not in GDD) px, beyond the view's half diagonal
	"refresh": 0.5,  # TUNING (not in GDD) s
	"avoid_margin": 10.0,  # TUNING (not in GDD) px
	"danger_reach": 26.0,  # TUNING (not in GDD) px
	"max_pits": 24,  # TUNING (not in GDD)
}

## Damage tag of a pit's burn (stats "player_dmg_from_hell_pit",
## "summon_dmg_from_hell_pit", "dmg_hell_pit").
const PIT_SOURCE: String = "hell_pit"
## Alpha (0..1) of a burning pit's lava fill (drawn only).
const PIT_ALPHA: float = 0.9  # TUNING (not in GDD)
## Alpha (0..1) of the additive glow over a burning pit (drawn only).
const PIT_GLOW_ALPHA: float = 0.35  # TUNING (not in GDD)

## The future Act VI counter-passive Salt Circle (owner-approved proposal; NOT
## built in phase 1): PassiveData row SALT_CIRCLE's level value SALT_CIRCLE_KEY
## is the share of a pit's burn summons no longer take
## (HellPits.salt_circle_mult(): 1 - value; exactly 1 while no such passive exists).
const SALT_CIRCLE: String = "salt_circle"
## Level-row key of Salt Circle's pit damage cut (fraction 0..1).
const SALT_CIRCLE_KEY: String = "pit_reduction"

# --- Portals (DemonPortals) -----------------------------------------------------------------

## The demon portals' defaults (a stage's STAGE "portals" overrides any key).
##   kind          — the portal's structure kind (InfernoEnemyData).
##   pour_first    — s after a portal opens before its first squad.
##   pour_every    — s between two squads of one portal.
##   pour_spread   — px around the portal's edge its squad steps out in.
##   pour_reach    — px: a portal pours only while a necromancer is this close.
##   table         — the squads a portal pours: rows {kind, count, weight}
##                   (a seeded weighted pick each time).
##   seal_radius   — px of the sealing ring around the portal's centre (the
##                   necromancer's centre inside it seals).
##   seal_time     — s a necromancer must stand in the ring (owner-approved
##                   proposal: "for 3 s").
##   seal_decay    — progress (s) lost per s while no necromancer stands in it.
##   ash_per_seal  — Soul Ash bounty of one sealed portal (the objective_ash
##                   path every stage objective pays through).
##   max_open      — most portals standing at once (an event beyond it opens fewer).
##   dist_min / dist_max — px from the necromancer a timeline portal opens.
##   spacing       — px between two portals placed together.
##   placement_tries — positions tried per portal (seeded).
##   cap_margin    — a portal skips its squad while fewer than this many
##                   regular slots are free under the hard cap.
const PORTALS := {
	"kind": "demon_portal",  # InfernoEnemyData.PORTAL
	"pour_first": 2.5,  # TUNING (not in GDD) s
	"pour_every": 9.0,  # TUNING (not in GDD) s ("a squad every few seconds"); first pass 7 (eight portals poured 750 demons into one stub run)
	"pour_reach": 900.0,  # TUNING (not in GDD) px: a portal pours only while a necromancer is this close (no off-screen flood)
	"pour_spread": 26.0,  # TUNING (not in GDD) px
	"table": [
		{"kind": "imp", "count": 3, "weight": 1.0},  # TUNING (not in GDD)
		{"kind": "damned", "count": 4, "weight": 1.0},  # TUNING (not in GDD)
		{"kind": "hell_knight", "count": 1, "weight": 0.35},  # TUNING (not in GDD)
	],
	"seal_radius": 52.0,  # TUNING (not in GDD) px
	"seal_time": 3.0,  # Owner-approved proposal: "standing inside a portal's ring for 3 s"
	"seal_decay": 1.0,  # TUNING (not in GDD) s per s
	"ash_per_seal": 20.0,  # TUNING (not in GDD) (a siege tower 25, a pylon 20)
	"max_open": 4,  # TUNING (not in GDD) first pass 6
	"dist_min": 300.0,  # TUNING (not in GDD) px
	"dist_max": 440.0,  # TUNING (not in GDD) px
	"spacing": 200.0,  # TUNING (not in GDD) px
	"placement_tries": 6,  # TUNING (not in GDD)
	"cap_margin": 4,  # TUNING (not in GDD)
}

## Colour of the sealing ring's progress (drawn only).
const SEAL_COLOR := Color(1.0, 0.722, 0.867)  # Palette.INFERNO_CHARM_LIGHT: sealing is the necromancer's own magic answering the swirl
## Dots of the sealing ring (drawn only: disc textures, no polygons).
const SEAL_DOTS: int = 28  # TUNING (not in GDD)

# --- Temptation (Temptation; HordeDirector.charm()) ---------------------------------------

## Temptation.
##   duration      — s a charmed summon fights for hell (owner-approved
##                   proposal: "fights for hell for 6 s"; x Faithless).
##   max_charmed   — most summons charmed at once, every army together
##                   (owner-approved proposal: "capped at 3 charmed at once").
##   kind          — the hostile body's enemy kind (InfernoEnemyData.CHARMED).
##   speed_mult    — the body's move speed = this x the summon's.
##   return_min    — least share (0..1) of its max HP a summon comes back with
##                   (also the HP of one FREED by breaking its body).
##   heart_every   — s between two hearts rising over a charmed body (drawn only).
##   tint          — colour multiplied over the summon's sprite while charmed.
const TEMPTATION := {
	"duration": 6.0,  # Owner-approved proposal
	"max_charmed": 3,  # Owner-approved proposal
	"kind": "charmed",  # InfernoEnemyData.CHARMED
	"speed_mult": 1.0,  # TUNING (not in GDD)
	"return_min": 0.15,  # TUNING (not in GDD)
	"heart_every": 0.45,  # TUNING (not in GDD) s
	"tint": Color(1.0, 0.62, 0.82),  # TUNING (not in GDD) charm pink over the bone
}

## The future Act VI counter-passive Faithless (owner-approved proposal: "charms
## on summons last half as long"; NOT built in phase 1): PassiveData row
## FAITHLESS's level value FAITHLESS_KEY is the share of a charm's duration cut
## (Temptation.faithless_mult(): 1 - value; exactly 1 while no such passive exists).
const FAITHLESS: String = "faithless"
## Level-row key of Faithless's charm duration cut (fraction 0..1).
const FAITHLESS_KEY: String = "charm_reduction"

# --- The Last Judgment (the shared Act VI Reckoning hook) ---------------------------------

## After 0:00, on a stage whose RECKONING has a "last_judgment" dictionary (its
## keys override these): every portal opens at once, the pits open faster each
## minute, and the Adversary's hand reaches up through the floor.
##   portals         — new portals opened around each necromancer at 0:00
##                     ("every portal opens at once").
##   portal_dist     — px from the necromancer they open.
##   pour_mult       — x every portal's pour interval in the Reckoning.
##   pit_every       — s between telegraphed pits at 0:00 ...
##   pit_speedup     — ... x this for every minute past 0:00 ...
##   pit_every_min   — ... down to this (s).
##   hand_every      — s between two grabs of the Adversary's hand at 0:00 ...
##   hand_speedup    — ... x this for every minute past 0:00 ...
##   hand_every_min  — ... down to this (s).
##   hand_windup     — s of the grab's telegraph (the floor glows red).
##   hand_radius     — px of the grab.
##   hand_dmg_player — damage to the necromancer (x the damage scaling).
##   hand_dmg_summon — damage to each summon in it (x the damage scaling).
##   hand_dmg_enemy  — damage to each non-demon enemy in it (x the HP scaling).
##   hand_on_player  — share (0..1) of grabs aimed at the necromancer; the
##                     rest at the densest part of his army.
const LAST_JUDGMENT := {
	"portals": 3,  # TUNING (not in GDD)
	"portal_dist": 360.0,  # TUNING (not in GDD) px
	"pour_mult": 0.6,  # TUNING (not in GDD)
	"pit_every": 3.0,  # TUNING (not in GDD) s
	"pit_speedup": 0.8,  # TUNING (not in GDD)
	"pit_every_min": 0.9,  # TUNING (not in GDD) s
	"hand_every": 6.0,  # TUNING (not in GDD) s
	"hand_speedup": 0.85,  # TUNING (not in GDD)
	"hand_every_min": 2.0,  # TUNING (not in GDD) s
	"hand_windup": 1.2,  # TUNING (not in GDD) s
	"hand_radius": 48.0,  # TUNING (not in GDD) px
	"hand_dmg_player": 16.0,  # TUNING (not in GDD)
	"hand_dmg_summon": 40.0,  # TUNING (not in GDD)
	"hand_dmg_enemy": 60.0,  # TUNING (not in GDD)
	"hand_on_player": 0.5,  # TUNING (not in GDD)
}
## Damage tag of the Adversary's hand.
const HAND_SOURCE: String = "adversary_hand"

# --- Sounds ------------------------------------------------------------------------------------

## Inferno event -> sound id played for it (Sfx.play(); an id that is not
## rendered is a silent no-op). The ids are the Inferno pack's
## (SoundData.INFERNO_SOUNDS), loaded lazily with the "brimstone" music; wired by
## the lead at the foundation merge. "hand_grab" has no own sound and stays on
## its stand-in (the Adversary's hand; it may later point at "brute_slam").
const SOUNDS := {
	"pit_open": "pit_open",  # A pit's rim cracking open and flaring (Inferno pack).
	"pit_burn": "pit_burn",  # The sizzle of a burn tick (Inferno pack).
	"portal_open": "portal_open",  # A demon portal tearing open (Inferno pack).
	"portal_seal": "portal_seal",  # A portal sealed or destroyed (Inferno pack).
	"charm_kiss": "charm_kiss",  # A succubus's charm landing (Inferno pack).
	"charm_break": "charm_break",  # A charm breaking (Inferno pack).
	"imp_cackle": "imp_cackle",  # An imp's cackle (Inferno pack).
	"brute_slam": "brute_slam",  # The Demon Brute's slam (Inferno pack).
	"hand_grab": "boss_impact",  # No own id: the Adversary's hand (stand-in; the startup bank's boss_impact)
	# --- Act VI: the Burning Gate ---
	"moloch_roar": "moloch_roar",  # SoundData.INFERNO_SOUNDS: Moloch's furnace roars open (his swallow, his phases; BossMoloch)
	"chain_haul": "chain_haul",  # SoundData.INFERNO_SOUNDS: the Gatekeeper's chains fly (GatekeeperKit)
	"cultist_chant": "cultist_chant",  # SoundData.INFERNO_SOUNDS: a Pit Cultist's rite begins (PitCultistKit)
}
## Least s between two pit_burn sounds (a burn tick hits many bodies at once).
const BURN_SOUND_GAP: float = 0.6  # TUNING (not in GDD)
