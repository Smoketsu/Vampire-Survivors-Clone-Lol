## Autotest — headless self-test of a full run, enabled with `-- --autotest`
## (see GameState for options). It:
##   * seeds the RNG and fast-forwards time (Engine.time_scale with physics
##     ticks scaled to match, so each physics step is still 1/60 s of game
##     time and collision behaviour is unchanged),
##   * drives the necromancer with a simple kiting autopilot (it also dodges
##     boss telegraphs and holy zones, steers off obstacles, and walks to
##     empowered graves, crypts and graves being consecrated),
##   * auto-picks level-up cards with a policy (--policy=naive: unowned summon
##     classes and spells first so every system gets exercised; --policy=army:
##     a summoner build that levels summons and army passives first, both
##     priest orders included; --policy=evolve: a spell build that chases all
##     three spell evolutions; --policy=summon: a summoner build that chases
##     the three summon evolutions, Death Knight, Lich and Profane Bishop).
##     Every policy would take an evolution card first (evolutions now come
##     only from treasure chests, so level-up hands no longer hold them); army,
##     evolve and summon also banish unwanted items and reroll weak hands
##     (naive never does, it plays like a careless player), and never take a
##     new item that is not on their build list (_build_list(); they reroll or
##     skip instead, so the newer spells and the later summon classes do not
##     change these baseline builds),
##   * exercises both Shadow Bolt aim modes: Nearest until the boss spawns,
##     then Strongest, and reports bolt damage per mode and to the boss,
##   * keeps the necromancer invulnerable (unless --mortal) until the countdown
##     has ended and the Reckoning has run for RECKONING_GRACE seconds, then
##     makes him mortal so the Reckoning kills him -> "Run Complete" screen,
##   * prints progress every 60 game seconds, plus "[metric]" lines (horde
##     size, damage taken by attacker, enemies alive by kind, XP collected)
##     that the multi-seed tuning scripts parse, and a final summary
##     (including Sir Alaric's attacks per type, stage events fired, obstacle
##     collisions resolved, stuck units, the level pacing and when the build
##     was complete), then quits with exit code 0 when the run completed, 1
##     otherwise,
##   * applies the --meta profile (none / mid / max simulated Soul Ash
##     purchases, in memory only) and reports the run's Soul Ash award and
##     its breakdown in the summary,
##   * detects stuck units: a summon or enemy that wants to move toward its
##     goal (target out of reach, anchor far away, returning...) but has not
##     moved more than STUCK_DISTANCE px in STUCK_TIME s,
##   * Profane Pact: every other policy ranks the Pact card below every card,
##     fallbacks included (PACT_SCORE), so balance runs never take it; --policy=pact is the
##     naive build that takes it at once (PACT_EAGER_SCORE). --oath=N sets the
##     Profane Oath tier. The summary reports whether and when the Pact was
##     taken, the Oath tier, and the extra XP / Soul Ash they gave,
##   * power-ups: the autopilot walks to a drop within DROP_SEEK_RADIUS when no
##     enemy presses it (keeps it simple), and the summary reports drops
##     spawned / collected / expired per type and the uptime of each buff,
##   * treasure chests open automatically (ChestPanel closes at once); the
##     autopilot walks to a chest within ChestData.AUTOTEST_SEEK_RADIUS unless
##     enemies press it hard, and the summary lists chests spawned / opened,
##     their sizes, every item granted and the evolution times (evolutions
##     come only from chests); a "chest beacon" line counts what the chest
##     beacon showed (ChestBeacon, from the logical view, never drawn
##     headless): chests marked and seen on screen, the most off-screen
##     arrows at once and the ticks with an arrow,
##   * the recipe book: a "recipe book" line lists the evolutions discovered
##     so far (Meta [recipes]; in memory only unless --meta-save) and the
##     pause menu's Recipes rows are built once, headless,
##   * the codex: a "codex" line counts the entries this run met per
##     category (spells learned, summon classes raised, Covenant kinds slain,
##     bosses faced; CodexLog), how many were new to the save, and the save's
##     codex totals (Meta [codex]; in memory only unless --meta-save),
##   * the Feedback buttons: a last "feedback" line says whether a form link is
##     set (FeedbackData.FORM_URL or --feedback-url=) and the length of three
##     sample reports (main menu, pause, results) built headless; nothing is
##     ever opened under the autotest (FeedbackReport.can_open()),
##   * the epilogue: an "epilogue" line counts its parts, how many the save has
##     opened and seen, the panels and whether one would autoplay on the
##     return to the menu (read only; the screen never opens headless),
##   * summon evolutions and the priest split: the summary lists every
##     evolution by type (spell / summon) with its time, the damage, heals
##     and shields of every summon source and class (dmg_<tag>, heal_by_<tag>,
##     shield_by_<tag>), and the Lich raises, merge, ally barriers and aura,
##   * later summon classes: --classes=a,b raises those classes to Lv 1 at
##     the start and makes every policy upgrade them first; the summary has
##     one line per class with a special (damage by source, stomps / dashes /
##     swoops / Deep Freezes, frozen-enemy-seconds, chills; Bone Hound bites,
##     pack bites and pack bonus damage, Hellhound burns and trail; Banshee
##     Dirges, enemies weakened, debuff uptime, Keening waves and silences;
##     Catapult volleys, boulders, hits, structure damage, Ossuary shard
##     fields), a "class passives" line (Blood Scent, Mournsong, Siegecraft
##     and summon damage to structures), a "fallen seraph" line in runs that
##     had her (Act II class: dives, chained dives, feather rings and cuts,
##     damage by source, Fallen Grace; an unlockable class never raised is
##     left out of the class lists, so other runs print as before), and the stuck
##     check also counts a special that runs past SPECIAL_STUCK_TIME
##     (airborne / dashing units) or ends inside an obstacle,
##   * --spells=a,b: every policy first takes those spells and their
##     evolution passives (FORCED_SPELL_SCORE; never banished), so each of
##     the newer spells can be exercised and evolved; the summary's
##     "necro spells" line reports each newer spell's level, damage (and its
##     evolved part), boss damage and spell counters, and the "evolutions"
##     line their times; the five later spells (death_mark, bone_wall,
##     soul_chains, wither, raise_dead) get their own "later spells" line
##     (damage, killing blows, brands / Risen, walls / push-outs, arcs /
##     jumps, aura uptime / heal, skeletons / bursts) and a "later spell
##     passives" line; --passives=a,b forces passives the same way (to
##     exercise one, e.g. a later horde passive),
##   * the later horde passives: a "horde passives" line reports each one's
##     level and effect (Bone Plating / Unholy Resilience damage prevented,
##     Unholy Precision crits and their extra damage, Bound Souls soft and
##     hard recalls); army and summon list them below their core passives.
##     Every evolution needs its paired passive at Lv 5, which the evolve,
##     summon and --spells bots level like any other build item,
##   * stages: --stage=graveyard|crimson_march|sanctum picks the stage (locks
##     are ignored; Main builds the RunConfig). On the Crimson March the
##     autopilot also walks toward outposts, ward generators and supply
##     carts when calm, and the summary adds a "crimson march" line (zones,
##     structures placed / destroyed / escaped, outpost reinforcements, aura
##     buffs, tower-shield and Shieldwall damage resisted, halberd cleaves)
##     and Marshal Vael's attack counters. The boss line works for any stage
##     boss (Boss.special_ids()). --boss=ID puts another boss in the stage's
##     slot (e.g. --boss=seraphine on any stage); with Grand Inquisitor
##     Seraphine the summary adds a "seraphine" line (phase times, attendants
##     and their healing, teleports, circles, beams, barrages, summons,
##     suppressions, novas, the collapsing arena and her damage;
##     BossSeraphine.summary_line()). In the Sanctum of Judgment the army,
##     summon and evolve bots also walk toward live ward crystals and sacred
##     altars when calm (naive / pact keep their baseline), and the summary
##     adds a "sanctum" line (chambers cleansed and when, altars destroyed
##     and when, corruption, the soldier HP cut applied, the Guardian's
##     death time, chamber burns, objective Soul Ash, structures caught in
##     obstacles: must stay 0) and the Sanctum event log.
##   * difficulty: --difficulty=ID and --modifiers=a,b set the GDD §8.4
##     level and §8.5 run modifiers (Main builds the RunConfig); the summary
##     adds a "difficulty" line (level, modifiers, every effective multiplier,
##     the Soul Ash parts, trickle elites promoted, Holy Retribution bursts
##     and radiant-bolt damage).
##   * manual abilities (GDD §5.5): every policy uses Grave Step (the dash)
##     when enemies crowd the necromancer, when he was just hit while in
##     danger, or to leave a boss / stage telegraph, toward the safest of
##     PlayerAbilityData.BOT_DASH_DIRECTIONS directions (clear length,
##     enemies and danger at the landing point, the flee direction), and
##     casts Dread Rally once the soul meter is full and he is in danger, the
##     stage boss is alive or the army is badly hurt (_drive_abilities()).
##     The summary's "grave step" / "dread rally" lines report dashes (and
##     why), hits ignored during dash i-frames, rallies, the meter fill
##     times, knockbacks, summons called back, rally healing and the minion
##     damage dealt under the buff.
##   * ultimates (content wave 2, --ultimate=ID, UltimateData): the bots cast
##     the chosen ultimate with the same rule as Dread Rally (_rally_wanted());
##     with another ultimate than Dread Rally an "ultimate" line follows the
##     "dread rally" line (UltimateSystem.summary_line(): casts and effect
##     stats: taunted, damage prevented, frozen, exposed, risen...), and the
##     header names it. The Dread Rally run prints neither (unchanged).
##   * army synergies: the "synergies active at end" line lists every active
##     synergy and when each awoke; the "synergy bonus" line reports, for the
##     newer classes' synergies, the hits each mark bonus raised and the
##     damage it added, the Baying frenzies, the staggered / swooped marks,
##     the Death from Above dash resets and the seconds Requiem stretched
##     (SynergyManager.summary_line()). --synergies=off keeps every synergy
##     off for A/B runs (the line is then marked "synergies off").
##   * the army formation (the Bone Ring, the only one): the summary has an
##     "army formation" line (time, kills, army damage taken, hard recalls
##     and the unit spread).
##   * forced spawns: --spawn=kind@T[xN],... spawns N enemies of any kind
##     (Graveyard, Crimson March or Sanctum data) in an arc on the spawn ring
##     at T game seconds, on any stage (a test hook for new kinds). The
##     autopilot also dodges the Sanctum kits' telegraphs
##     (EnemyDirector.rites.danger_push()), and when any Sanctum kind spawned
##     the summary adds "sanctum enemies" lines (spawns and kills per kind,
##     Sentinel sweeps and flat armour absorbed, Inquisitor zones and
##     suppressions with the horde's suppression counters, Confessor heals /
##     shields / revives / cancelled revives, Paladin ward damage prevented,
##     Cathedral Guardian slams / beams / kills / time to kill / chests);
##     when a Sister of the Scourge spawned (BattleSisterData; March, Sanctum
##     or --spawn=battle_sister@T) a "battle sister" line adds her spawns,
##     kills, lashes, lash hits on summons and the player, zeal surges and
##     her damage.
##   * playable characters: --character=ID plays that character (locks
##     bypassed; Main builds the RunConfig). For any character but the
##     Gravecaller the army / evolve / summon build lists swap the
##     character's starting spell (and its evolution passive) into Shadow
##     Bolt's (and Soul Conduit's) priority, and never banish them, so each
##     character plays the same build shape around its own spell
##     (_character_list()). The summary adds a "character" line (starting
##     spell level, stats, the innate's counters, characters unlocked this
##     run; CharacterInnates.summary_line()).
##   * Act IV, the Olympian Republic (GDD §15.0 "Act IV foundation (phase
##     1)"): --stage=ilion|olympus|underworld, --spawn= with its kinds
##     (shade_of_dead, hoplite, hero, bronze_titan), --boss=achilles|zeus|
##     hades. The bot steps off telegraphed bolt circles and fissures
##     (PantheonRules.danger_push(); the waves cannot be dodged). When the
##     Pantheon ran, the summary adds the "divine wrath", "phalanx", "glory",
##     "pantheon kinds" and (on an Act IV stage) "pantheon stage" lines
##     (PantheonReport).
##   * Act IV, Mount Olympus: --spawn= with its kinds (centaur_archer, amazon,
##     gorgon, moon_hound, sea_serpent) and its gods (ares, artemis, poseidon;
##     any stage), --boss=zeus, --character=oathbreaker; the "olympus",
##     "pantheon trial", "olympus kinds", "wrath called" and "zeus" lines
##     (OlympusReport, through PantheonReport), and on every stage the
##     "stolen thunder" / "grounded bones" lines when used.
##   * Act V, the Shogunate of the Rising Sun (GDD §15.0 "Act V foundation
##     (phase 1)"): --stage=province|kurogane|sun_road, --spawn= with its kinds
##     (ashigaru, samurai, teppo_gunner, ninja, onryo, oni), --boss=kage|
##     shogun|amaterasu. The bot steps out of flashing Draw lines
##     (ShogunateRules.danger_push()) and the oni's raised club (its kit's
##     danger_push()). When the Shogunate ran, the summary adds the "sun's
##     course", "the draw", "from the shadows", "shogunate kinds" and (on an
##     Act V stage) "shogunate stage" lines (ShogunateReport).
class_name Autotest
extends Node

## Game seconds between progress lines (a 20-minute run prints 20 of them).
const REPORT_INTERVAL: float = 60.0
## Levels whose arrival time the summary's level-pacing line lists.
const LEVEL_MARKS := [2, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
## Elapsed game times (s) at which the summary lists the level reached.
const TIME_MARKS := [60.0, 180.0, 300.0, 600.0, 900.0, 1020.0, 1200.0]
## Radius (px) in which the autopilot flees enemies.
const FLEE_RADIUS: float = 110.0
## Radius (px) in which the autopilot walks toward XP crystals.
const XP_SEEK_RADIUS: float = 320.0
## Game seconds of Reckoning before the invulnerable autopilot turns mortal.
const RECKONING_GRACE: float = 20.0
## Radius (px) in which the autopilot walks to stage objectives.
const OBJECTIVE_SEEK_RADIUS: float = 420.0
## Policies whose autopilot walks to the Sanctum's ward crystals and altars.
const SANCTUM_SEEK_POLICIES := ["army", "summon", "evolve"]
# --- Act III: the Iron Citadel ---
## Summons the bot needs before it walks to the Citadel's gate generators and
## turrets (a starting army of four walked into a gate's guns and died).
const CITADEL_SEEK_ARMY: int = 12
## Distance (px) at which the autopilot starts steering off obstacles.
const OBSTACLE_LOOK: float = 22.0
## Game seconds between stuck-unit samples.
const STUCK_SAMPLE: float = 1.0
## A unit that moved less than this (px) ...
const STUCK_DISTANCE: float = 10.0
## ... over this many game seconds while wanting to move counts as stuck.
const STUCK_TIME: float = 10.0
## A following summon "wants to move" only when its anchor is farther than
## this (px); closer than that it is simply standing in formation.
const STUCK_ANCHOR_SLACK: float = 40.0
## Card priorities for --policy=army (higher = picked first). The four later
## horde passives (Bone Plating, Unholy Resilience, Unholy Precision, Bound
## Souls) sit below every passive of its baseline build (Soul Conduit
## included: at 32-34 Bone Plating took its slot and the bot lost Void
## Barrage in 3 of 4 seeds), so they mostly fill a slot the baseline passives
## were not offered for in time.
const ARMY_PRIORITY := {"warrior": 100.0, "archer": 95.0, "mage": 98.0, "mender": 90.0, "warder": 89.0, "grave_dominion": 105.0,
	"dark_command": 70.0, "necrotic_vigor": 65.0, "soul_recycling": 50.0,
	"shadow_bolt": 60.0, "shadow_blast": 55.0, "orb_shield": 40.0,
	"warding_ritual": 35.0, "soul_conduit": 30.0, "abyssal_focus": 28.0,
	"bone_plating": 27.0, "unholy_resilience": 26.0, "unholy_precision": 25.0, "bound_souls": 20.0}
## Card priorities for --policy=evolve (higher = picked first): the three
## base spells and their paired passives, then the army.
const EVOLVE_PRIORITY := {"shadow_bolt": 100.0, "soul_conduit": 96.0, "shadow_blast": 94.0, "abyssal_focus": 92.0,
	"orb_shield": 90.0, "warding_ritual": 88.0, "warrior": 70.0, "mender": 66.0, "warder": 63.0, "grave_dominion": 64.0,
	"mage": 62.0, "archer": 60.0, "dark_command": 50.0, "necrotic_vigor": 48.0, "soul_recycling": 40.0}
## --policy=summon: the base classes of the three summon evolutions. The bot
## keeps active slots free for the ones it does not own yet (see
## _forced_slots_short()), because with seven spells a treasure chest could
## hand it a new spell and a too-early Shadow Blast then left no slot for the
## Warder (no Profane Bishop). Chests no longer grant new items
## (ChestData.GRANTS_NEW_ITEMS), but the reservation is kept. A merged-away
## Mender / Warder counts as owned.
const SUMMON_CORE := ["warrior", "mage", "mender", "warder"]
## --policy=army: its summoner core, the four GDD roles with both priest
## orders. Six active slots hold Shadow Bolt and these five, so the bot keeps
## slots for the ones it lacks the same way (_forced_slots_short()): a Shadow
## Blast taken early once left no slot for Mages, and that army fell apart on
## the Crimson March.
const ARMY_CORE := ["warrior", "archer", "mage", "mender", "warder"]
## Card priorities for --policy=summon (higher = picked first): the base
## classes of the three summon evolutions and their passives (all three
## must reach Lv 5, the owner's rule for every evolution), then Archers,
## Shadow Bolt and the rest. Once the Mender + Warder merge frees a slot,
## Shadow Blast fills it. The later horde passives come last, like in
## ARMY_PRIORITY.
const SUMMON_PRIORITY := {"grave_dominion": 105.0, "warrior": 100.0, "mage": 98.0, "mender": 93.0, "warder": 92.0,
	"dark_command": 84.0, "forbidden_knowledge": 82.0, "dark_benediction": 80.0, "archer": 78.0,
	"necrotic_vigor": 62.0, "shadow_bolt": 60.0, "shadow_blast": 55.0, "soul_recycling": 45.0,
	"warding_ritual": 35.0, "soul_conduit": 30.0,
	"bone_plating": 27.0, "unholy_resilience": 26.0, "unholy_precision": 25.0, "bound_souls": 20.0}
## army / summon take a later horde passive (PassiveData "shared_card_pool")
## NEW only once they own this passive, their top one: an early Unholy
## Precision once filled the last passive slot before Grave Dominion was
## offered, and that army starved (lowest HP 27, no evolutions, no boss kill).
const LATE_PASSIVE_GATE: String = "grave_dominion"
## Warding Ritual priority for --policy=army --pact: the Pact takes a
## passive slot, and a sensible Pact build gives up Warding Ritual (below
## Soul Conduit, 30) rather than its Void Barrage evolution passive.
const ARMY_PACT_WARDING_PRIORITY: float = 25.0
## Items each policy banishes when offered (while banish charges last).
const BANISH_IDS := {"army": ["orb_shield", "abyssal_focus"], "evolve": ["soul_recycling", "necrotic_vigor"],
	"summon": ["orb_shield", "abyssal_focus"]}
## army / evolve reroll the hand when its best card scores below this.
const REROLL_BELOW: float = 25.0
## Score of an evolution card (always taken first).
const EVOLUTION_SCORE: float = 1000.0
## Score of a fallback card (taken only when nothing else is offered).
const FALLBACK_SCORE: float = -100.0
## Score of a Profane Pact card for every policy but "pact": below every
## card including the fallbacks, so the balance policies never take it (a
## hand of only the Pact cannot happen: fallbacks fill every hand).
const PACT_SCORE: float = -150.0
## Score of a Profane Pact card for --policy=pact (always taken first,
## except evolutions).
const PACT_EAGER_SCORE: float = 500.0
## Radius (px) in which the autopilot walks to a power-up drop.
const DROP_SEEK_RADIUS: float = 300.0
## Flee pressure (length of the flee vector) above which drops are ignored.
const DROP_SAFE_PRESSURE: float = 0.35
## Flee pressure above which even chests are ignored.
const CHEST_SAFE_PRESSURE: float = 0.8
## Score of a card for a class forced by --classes (above everything but
## evolutions and an eager Pact).
const FORCED_CLASS_SCORE: float = 400.0
## A class special (dash, swoop, stomp, freeze) still running after this many
## game seconds counts as a stuck unit (the longest one, a swoop, is ~2 s).
const SPECIAL_STUCK_TIME: float = 4.0
## Summary of the later classes: class -> [damage stat sources, count stats].
const CLASS_REPORT := {
	"abomination": [["abomination", "abom_stomp"], ["abom_stomps", "abom_stomp_hits"]],
	"rogue": [["rogue", "rogue_dash", "rogue_bleed"], ["rogue_dashes", "rogue_dash_hits"]],
	"gargoyle": [["gargoyle", "gargoyle_swoop"], ["gargoyle_swoops", "gargoyle_swoop_hits"]],
	"frost_wraith": [["frost_wraith"], ["frost_deep_freezes", "frost_freezes", "frost_boss_freezes", "frost_frozen_seconds", "frost_chills"]],
	"bone_hound": [["bone_hound", "hellhound", "hellhound_burn", "hellhound_trail"],
		["hound_bites", "hound_pack_bites", "hound_pack_bonus_dmg", "hellhound_burns", "hellhound_trail_patches"]],
	"banshee": [["banshee", "keening_lady"],
		["banshee_dirges", "banshee_dirge_hits", "dirge_debuff_seconds", "keening_waves", "keening_silenced", "keening_heals_silenced"]],
	"corpse_catapult": [["corpse_catapult", "ossuary_engine", "ossuary_shards"],
		["catapult_volleys", "catapult_boulders", "catapult_boulder_hits", "catapult_structure_dmg", "ossuary_shard_fields", "hazards_dropped"]],
}
## Score of a --spells card (a forced spell or its evolution passive): above
## every policy priority and the Pact, below evolutions.
const FORCED_SPELL_SCORE: float = 300.0
## Score of a card for a NEW non-forced item while a --spells item of the
## same slot kind (active / passive) is not owned yet, and of a NEW item
## that is not on the army / evolve build list: below every real card and
## the fallbacks, above the unwanted Profane Pact (PACT_SCORE); a hand whose
## best card scores this or less is rerolled or skipped, so a blocked hand
## never falls through to the Pact.
const FORCED_BLOCK_SCORE: float = -120.0
## --spells: free slots kept beyond the forced items still missing. It was
## headroom for a treasure chest granting some other new item; chests now
## only upgrade owned items (ChestData.GRANTS_NEW_ITEMS), and it is kept at
## 1 so the summon / army bots' slot order (and their baselines) stay as
## they were.
const FORCED_SPARE_SLOTS: int = 1
## --spells: card-weight multiplier of the forced spells and passives in
## level-up hands and chests (AbilityManager._candidates asks through
## card_weight_mult()), so they are offered reliably; scoring alone left a
## forced spell unoffered for most of a run in some seeds.
const FORCED_WEIGHT_MULT: float = 8.0

## Owning run.
var game: Game
## Game time of the next progress line.
var _next_report: float = REPORT_INTERVAL
## Game time the boss spawned (-1 until then).
var _boss_spawn_time: float = -1.0
## Game time the boss died (-1 if alive / never spawned).
var _boss_death_time: float = -1.0
## Game time the Reckoning began (-1 until then).
var _reckoning_time: float = -1.0
## Peak simultaneous entity counts.
var _peak: Dictionary = {"enemies": 0, "summons": 0, "projectiles": 0, "effects": 0, "crystals": 0}
## Real-time start (ms) for the wall-clock duration line.
var _real_start_msec: int = 0
## Necromancer max HP at the first step (after Soul Ash upgrades and the
## Frail Master run modifier); -1 before the first step.
var _start_max_hp: float = -1.0
## Game seconds during which 2 or more ward casters (Warders / Profane
## Bishops) were alive.
var _two_priest_time: float = 0.0
## Wards cast while 2 or more ward casters were alive.
var _two_priest_wards: int = 0
## priest_wards stat seen on the previous step (to attribute new wards).
var _last_wards: int = 0
## Sum of living-summon counts over the current report window.
var _horde_sum: float = 0.0
## Number of steps in the current report window.
var _horde_n: int = 0
## Total summon deaths at the start of the current report window.
var _death_mark: int = 0
## Boss HP when the countdown reached 0:00 (-1 = not reached / no boss).
var _boss_hp_at_0: float = -1.0
## summon_dmg_from_* stats at the previous report (to print per-window deltas).
var _last_src: Dictionary = {}
## Lowest necromancer HP seen before 0:00 (the "nigh-unkillable" check).
var _min_hp: float = 9999.0
## dmg_bolt stat when the aim switched to Strongest (-1 = never switched).
var _bolt_dmg_at_switch: float = -1.0
## Guards against printing the summary twice.
var _finished: bool = false
## Instance id -> [generation, position, game time] of the stuck tracker.
var _stuck_track: Dictionary = {}
## Game time of the next stuck-unit sample.
var _next_stuck_sample: float = STUCK_SAMPLE
## Stuck episodes detected (must stay ~0).
var _stuck_units: int = 0
## Stuck episodes by unit label ("summon_warrior", "enemy_footman"...).
var _stuck_by: Dictionary = {}
## Stuck episodes where the unit was touching an obstacle.
var _stuck_at_obstacle: int = 0
## Reusable query buffer.
var _tmp: Array = []
## Game time (s) at which each level was reached, indexed by level (level 1 = 0).
var _level_time: PackedFloat32Array = PackedFloat32Array([0.0, 0.0])
## Level the necromancer had at each TIME_MARKS entry (-1 until reached).
var _level_at_mark: PackedInt32Array = PackedInt32Array()
## Game time (s) of the first level-up hand made only of fallback cards, i.e.
## every slot full and maxed, every evolution taken (-1 = never).
var _build_complete_time: float = -1.0
## Level of that hand (0 = never).
var _build_complete_level: int = 0
## Level-up hands seen by choose_action() (rerolled hands count again).
var _hands_seen: int = 0
## NEW-item cards offered in those hands (an item not owned yet: spell, summon
## class or passive, from level 0).
var _new_offers: int = 0
## Of those, cards of a later item ("shared_card_pool", LevelUpData.WEIGHT_NEW_LATER).
var _new_later_offers: int = 0
## Hands that held at least one later-item NEW card.
var _hands_with_later: int = 0
## Distinct later items offered at least once (id -> true).
var _later_seen: Dictionary = {}
## Highest Profane Pact level seen so far.
var _pact_seen: int = 0
## "Ln@mm:ss" for every Profane Pact level taken.
var _pact_log: PackedStringArray = PackedStringArray()
## True once the --classes forced classes were raised.
var _forced_done: bool = false
## summon_special_end_blocked stat already counted as stuck units.
var _end_blocked_seen: int = 0
## Instance id -> generation of units already counted for an overlong special.
var _overtime_seen: Dictionary = {}
## Item id -> true for the --spells spells and their evolution passives.
var _forced: Dictionary = {}
## --spawn entries sorted by time ({"kind", "time", "count"}).
var _spawns: Array[Dictionary] = []
## Index of the next --spawn entry to run.
var _next_spawn: int = 0
## Policy -> its build list with the --character swap applied (cache of
## _character_list(); the Gravecaller uses the constant lists unchanged).
var _char_lists: Dictionary = {}
## Item ids the --character build never banishes (its starting spell and its
## evolution passive; empty for the Gravecaller).
var _char_keep: Dictionary = {}
# --- Co-op (--coop-bot; CoopSession) ----------------------------------------------------
## Co-op slot this bot drives (0 = the run's own Autotest node; 1 = a bot
## node built by CoopSession.build_slot(), which skips _ready()'s run setup).
var slot: int = 0
## Card policy of a slot-1 bot (--policy2=; "" = GameState.autotest_policy).
var _policy_override: String = ""
## Character of a slot-1 bot (--character2=; "" = GameState.autotest_character).
var _char_override: String = ""
## Forced summon classes of a slot-1 bot (--classes2=).
var _classes_override: PackedStringArray = PackedStringArray()
## True once a slot-1 bot switched its Shadow Bolt aim at the boss's arrival.
var _aim_switched: bool = false
## True for a bot that only steers and picks for one slot (a --coop-bot slot-1
## bot, or the bot that takes a dropped partner's necromancer over): its
## _ready() skips the run setup (seeding, the clock), whatever its slot.
var helper: bool = false
## Online co-op (--coop-net=host|join, CoopLockstep): true for the run's own
## bot, which drives this machine's slot through the lockstep (its dash,
## ultimate and aim go out as inputs, never as direct requests).
var net: bool = false


## Co-op: sets up this object as the bot of slot `i` > 0 (--coop-bot): its
## policy (--policy2=, army by default), character (--character2=), forced
## classes (--classes2=) and spells (--spells2=). The run-level work (seeding,
## the clock, the report) stays with slot 0's Autotest node.
func init_bot(i: int) -> void:
	slot = i
	helper = true
	_policy_override = GameState.autotest_policy2 if GameState.autotest_policy2 != "" else "army"
	_char_override = GameState.autotest_character2
	_classes_override = GameState.autotest_classes2
	for id: String in GameState.autotest_spells2:
		_forced[id] = true
		var evo := EvolutionData.for_spell(id)  # Its evolution ("" if none).
		if evo != "":
			_forced[String(EvolutionData.EVOLUTIONS[evo]["passive"])] = true


## Online co-op: sets up this object as the bot that takes a dropped partner's
## slot `i` over (CoopLockstep): card policy `pol`, the partner's character
## `char_id` (its build list swap), no forced classes or spells.
func init_takeover(i: int, pol: String, char_id: String) -> void:
	slot = i
	helper = true
	_policy_override = pol
	_char_override = char_id
	_forced_done = true  # Nothing forced: the partner's build stays his.


## This bot's card policy ("naive", "army", ...).
func policy() -> String:
	return _policy_override if _policy_override != "" else GameState.autotest_policy


## This bot's character (CharacterData id).
func _char_id() -> String:
	return _char_override if _char_override != "" else GameState.autotest_character


## This bot's forced summon classes (--classes= / --classes2=).
func _classes() -> PackedStringArray:
	return _classes_override if slot > 0 else GameState.autotest_classes


## Co-op: one tick of a slot-1 bot (its slot bound; CoopSession.step_bots()):
## the forced classes once, the Strongest aim when the boss comes, the dash and
## the ultimate. The run-level checks stay in slot 0's step().
func step_slot(_delta: float) -> void:
	if not _forced_done:
		_apply_forced_classes()
	if not _aim_switched and game.enemies.boss != null:
		_aim_switched = true
		if not game.abilities.bolt_aim_strongest:
			_toggle_aim()
	_drive_abilities()


func _ready() -> void:
	if slot > 0 or helper:
		return  # Co-op: a slot bot only picks and steers (init_bot() / init_takeover()); the run's own Autotest does the rest.
	process_mode = Node.PROCESS_MODE_ALWAYS
	seed(GameState.autotest_seed)
	for id: String in GameState.autotest_spells:
		_forced[id] = true
		var evo := EvolutionData.for_spell(id)  # Its evolution ("" if none).
		if evo != "":
			_forced[String(EvolutionData.EVOLUTIONS[evo]["passive"])] = true
	for id: String in GameState.autotest_passives:
		_forced[id] = true  # --passives: taken and levelled like a --spells item.
	var speed := GameState.autotest_speed
	Engine.time_scale = speed
	Engine.physics_ticks_per_second = int(roundf(60.0 * speed))
	Engine.max_physics_steps_per_frame = maxi(8, int(ceilf(8.0 * speed)))
	_real_start_msec = Time.get_ticks_msec()
	for _i in TIME_MARKS.size():
		_level_at_mark.append(-1)
	print("[autotest] start: seed=%d speed=%sx mortal=%s timeout=%ss policy=%s meta=%s oath=%d pact=%s classes=%s spells=%s" % [
		GameState.autotest_seed, str(speed), str(GameState.autotest_mortal), str(GameState.autotest_timeout), GameState.autotest_policy, GameState.autotest_meta,
		GameState.autotest_oath, str(GameState.autotest_pact), ",".join(GameState.autotest_classes) if not GameState.autotest_classes.is_empty() else "-",
		",".join(GameState.autotest_spells) if not GameState.autotest_spells.is_empty() else "-"])
	if not GameState.autotest_passives.is_empty():
		print("[autotest] forced passives: %s" % ",".join(GameState.autotest_passives))
	print("[autotest] stage: %s" % GameState.autotest_stage)
	_spawns = GameState.autotest_spawns.duplicate()
	_spawns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["time"]) < float(b["time"]))
	if not _spawns.is_empty():
		var parts := PackedStringArray()  # "kind@T xN" per forced spawn.
		for sp in _spawns:
			parts.append("%s@%s x%d" % [sp["kind"], _clock(float(sp["time"])), int(sp["count"])])
		print("[autotest] forced spawns: %s" % ", ".join(parts))
	if GameState.autotest_boss != "":
		print("[autotest] boss override: %s" % GameState.autotest_boss)
	print("[autotest] difficulty: %s | modifiers: %s" % [GameState.autotest_difficulty,
		",".join(GameState.autotest_modifiers) if not GameState.autotest_modifiers.is_empty() else "none"])
	print("[autotest] character: %s (starting spell %s)" % [GameState.autotest_character,
		String(CharacterData.CHARACTERS[GameState.autotest_character]["spell"])])
	if GameState.autotest_hyper or GameState.autotest_skin != "":
		print("[autotest] hyper: %s | skin: %s" % [str(GameState.autotest_hyper), GameState.autotest_skin if GameState.autotest_skin != "" else "default"])
	if GameState.autotest_ultimate != UltimateData.DEFAULT_ID:
		print("[autotest] ultimate: %s" % GameState.autotest_ultimate)  # Content wave 2 (UltimateData).


## --classes: raises every forced class to Lv 1 while an active slot is free.
func _apply_forced_classes() -> void:
	_forced_done = true
	for cls: String in _classes():
		if int(game.horde.class_levels[cls]) > 0:
			continue
		if game.abilities.active_count() >= game.abilities.active_slots():
			print("[autotest] forced class %s skipped: no active slot left" % cls)
			continue
		game.horde.set_class_level(cls, 1)
		game.abilities.pick_history.append("%s 1 (forced)" % cls)
		print("[autotest] forced class %s raised to Lv 1" % cls)


## Called by Game after each simulation step.
func step(delta: float) -> void:
	if not _forced_done:
		_apply_forced_classes()
	while _next_spawn < _spawns.size() and game.elapsed >= float(_spawns[_next_spawn]["time"]):
		_forced_spawn(_spawns[_next_spawn])
		_next_spawn += 1
	if _start_max_hp < 0.0:
		_start_max_hp = game.player.max_hp
	var wards := int(game.stats.get("priest_wards", 0.0))
	if game.horde.count_of("warder") + game.horde.count_of("bishop") >= 2:
		_two_priest_time += delta
		_two_priest_wards += wards - _last_wards
	_last_wards = wards
	_peak["enemies"] = maxi(int(_peak["enemies"]), game.enemies.active.size())
	_peak["summons"] = maxi(int(_peak["summons"]), game.horde.units.size())
	_peak["projectiles"] = maxi(int(_peak["projectiles"]), game.projectiles.active.size())
	_peak["effects"] = maxi(int(_peak["effects"]), game.effects.active.size())
	_peak["crystals"] = maxi(int(_peak["crystals"]), game.pickups.active.size())
	if _boss_spawn_time < 0.0 and game.enemies.boss != null:
		_boss_spawn_time = game.elapsed
		print("[autotest] boss spawned at %.1f s" % game.elapsed)
		if not game.abilities.bolt_aim_strongest:
			_toggle_aim()
			_bolt_dmg_at_switch = _bolt_damage(game.stats, "dmg_")
			print("[autotest] Shadow Bolt aim switched to %s" % game.abilities.bolt_aim_name())
	if _boss_death_time < 0.0 and game.boss_defeated:
		_boss_death_time = game.elapsed
		print("[autotest] boss defeated at %.1f s" % game.elapsed)
	if _reckoning_time < 0.0 and game.enemies.reckoning_wave > 0:
		_reckoning_time = game.elapsed
		print("[autotest] countdown reached 0:00 at %.1f s - THE RECKONING begins" % game.elapsed)
	if _reckoning_time >= 0.0 and game.player.invulnerable and game.elapsed >= _reckoning_time + RECKONING_GRACE:
		for pl in game.all_players:
			pl.invulnerable = false  # Co-op: every necromancer (one in solo).
		print("[autotest] %.1f s: Reckoning wave %d reached, player made mortal" % [game.elapsed, game.enemies.reckoning_wave])
	if game.elapsed < WaveData.RUN_DURATION:
		_min_hp = minf(_min_hp, game.player.hp)
	_horde_sum += game.horde.units.size()
	_horde_n += 1
	while _level_time.size() <= game.level:
		_level_time.append(game.elapsed)
	var pact := game.difficulty.pact_level()  # Profane Pact level now.
	if pact > _pact_seen:
		_pact_seen = pact
		_pact_log.append("L%d@%s" % [pact, _clock(game.elapsed)])
	for i in TIME_MARKS.size():
		if _level_at_mark[i] < 0 and game.elapsed >= float(TIME_MARKS[i]):
			_level_at_mark[i] = game.level
	if _boss_hp_at_0 < 0.0 and game.elapsed >= WaveData.RUN_DURATION and game.enemies.boss != null:
		_boss_hp_at_0 = game.enemies.boss.hp if game.enemies.boss.active else 0.0
	_drive_abilities()
	if game.elapsed >= _next_stuck_sample:
		_next_stuck_sample += STUCK_SAMPLE
		_sample_stuck()
	if game.elapsed >= _next_report:
		_next_report += REPORT_INTERVAL
		_print_metrics()
		print("[autotest] t=%s lvl=%d kills=%d enemies=%d summons=%d/%d projectiles=%d hp=%d step_avg=%.2fms" % [
			_clock(game.elapsed), game.level, game.kills, game.enemies.active.size(),
			game.horde.units.size(), game.horde.total_capacity(), game.projectiles.active.size(),
			int(game.player.hp), game.avg_step_ms()])
		print("[autotest]    unit FSM: %s" % str(game.horde.state_counts()))
	if game.elapsed >= GameState.autotest_timeout:
		game.end_run(false, "timeout")


## --spawn: spawns one forced entry in an arc on the spawn ring (the normal
## formation path, HARD_CAP respected).
func _forced_spawn(sp: Dictionary) -> void:
	var before := game.enemies.total_spawned  # To count what really spawned.
	game.enemies.spawn_formation("arc", [{"kind": String(sp["kind"]), "count": int(sp["count"]), "elite": false}])
	print("[autotest] %s forced spawn: %d x %s" % [_clock(game.elapsed), game.enemies.total_spawned - before, sp["kind"]])


## Samples every summon and enemy for the stuck-unit check. Class specials
## (airborne / dashing units) are checked separately: one that runs longer
## than SPECIAL_STUCK_TIME, or ends inside an obstacle, is a stuck unit.
func _sample_stuck() -> void:
	for u in _all_units():
		if u.active:
			_track(u, u.generation, u.radius, _summon_wants_move(u), "summon_" + u.unit_class)
			if u.behavior != null and u.behavior.is_busy() and u.behavior.special_time > SPECIAL_STUCK_TIME \
					and int(_overtime_seen.get(u.get_instance_id(), -1)) != u.generation:
				_overtime_seen[u.get_instance_id()] = u.generation
				_count_stuck("summon_%s_special" % u.unit_class, "special overtime: %s phase %d for %.1f s (airborne: %s)" % [
					u.unit_class, u.behavior.phase, u.behavior.special_time, str(u.airborne)])
	var blocked := int(game.stats.get("summon_special_end_blocked", 0.0))  # Specials that ended in an obstacle.
	if blocked > _end_blocked_seen:
		_count_stuck("summon_special_end_blocked", "%d special(s) ended inside an obstacle" % (blocked - _end_blocked_seen))
		_end_blocked_seen = blocked
	for e in game.enemies.active:
		if e.active:
			_track(e, e.generation, e.radius, _enemy_wants_move(e), "enemy_" + e.kind)


## Stuck bookkeeping for one unit: restart its window whenever it moved
## enough, was recycled, or has no reason to move; count an episode when
## the window reaches STUCK_TIME.
func _track(n: Node2D, gen: int, r: float, wants: bool, label: String) -> void:
	var id := n.get_instance_id()
	var rec: Variant = _stuck_track.get(id)
	if rec == null or int(rec[0]) != gen or not wants or n.position.distance_to(rec[1]) > STUCK_DISTANCE:
		_stuck_track[id] = [gen, n.position, game.elapsed]
		return
	if game.elapsed - float(rec[2]) < STUCK_TIME:
		return
	_stuck_units += 1
	_stuck_by[label] = int(_stuck_by.get(label, 0)) + 1
	var at_obstacle := game.arena.is_blocked(n.position, r + 3.0)
	if at_obstacle:
		_stuck_at_obstacle += 1
	print("[autotest] stuck unit: %s at %s (%.0f px from player, touching obstacle: %s)" % [
		label, str(n.position.round()), n.position.distance_to(game.player.position), str(at_obstacle)])
	_stuck_track[id] = [gen, n.position, game.elapsed]


## Every summon of the run (co-op: both armies; solo: the one).
func _all_units() -> Array[SummonedUnit]:
	if game.coop == null:
		return game.horde.units
	var out: Array[SummonedUnit] = []
	for h in game.all_hordes:
		out.append_array(h.units)
	return out


## Where summon `u`'s necromancer stands (co-op: its own army's).
func _owner_pos(u: SummonedUnit) -> Vector2:
	if game.coop == null or u.director == null:
		return game.player.position
	return game.coop.slots[u.director.slot].player.position


## Records one stuck episode labelled `label` and prints `detail`.
func _count_stuck(label: String, detail: String) -> void:
	_stuck_units += 1
	_stuck_by[label] = int(_stuck_by.get(label, 0)) + 1
	print("[autotest] stuck unit: %s" % detail)


## True when a summon is trying to get somewhere (not idling in formation,
## casting or fighting in reach).
func _summon_wants_move(u: SummonedUnit) -> bool:
	match u.state:
		SummonedUnit.State.RETURNING, SummonedUnit.State.RETREATING, SummonedUnit.State.REPOSITIONING:
			return true
		SummonedUnit.State.FOLLOWING, SummonedUnit.State.ACQUIRING:
			return u.position.distance_to(_owner_pos(u) + u.anchor_offset) > STUCK_ANCHOR_SLACK
		SummonedUnit.State.ENGAGING:
			var t := u.target
			if u.attack_profile == "melee" and t != null and t.active and t.generation == u.target_gen:
				return u.position.distance_to(t.position) - u.radius - t.radius > u.attack_range + UnitData.MELEE_TOLERANCE
	return false


## True when an enemy is trying to close in (not fighting a blocker, not in
## reach, not winding up a special).
func _enemy_wants_move(e: Enemy) -> bool:
	if e.engaged_timer > 0.0 or (e.kit != null and e.kit.is_busy()):
		return false  # Fighting a blocker, or standing in a Sanctum windup / cast.
	var pl := game.nearest_player(e.position)  # (Co-op: the one it advances on.)
	if e.is_boss:
		var b := e as Boss
		return b.is_walking() and e.position.distance_to(pl.position) - e.radius - pl.radius > e.attack_range + 4.0
	if e.is_structure:
		return false  # Outposts, generators, standards stand; carts roll on a fixed path.
	match e.behavior:
		"consecrator":
			return e.position.distance_to(e.post_pos) > 12.0
		"ranged", "healer", "banner":
			return e.position.distance_to(pl.position) - e.radius - pl.radius > EnemyData.ADVANCE_STOP_GAP + 6.0
		"templar":
			if e.rush_state != 0:
				return false
	var t := e.target
	if t == null:
		return false
	var tr := (t as Necromancer).radius if t is Necromancer else (t as SummonedUnit).radius
	return e.position.distance_to(t.position) - e.radius - tr > e.attack_range + 4.0


## True for an unlockable summon class (UnlockData, Act II) that was never
## raised this run: left out of the class lists, so a run without it prints
## exactly what it printed before the class existed.
func _unused_locked_class(cls: String) -> bool:
	return UnlockData.UNLOCKS.has(cls) and int(game.horde.class_levels[cls]) <= 0 and game.horde.count_of(cls) <= 0 			and game.horde.capacity(cls) <= 0


## Prints the per-window "[metric]" lines parsed by the tuning scripts.
func _print_metrics() -> void:
	var cc := PackedStringArray()
	for cls: String in UnitData.CLASS_ORDER:
		if _unused_locked_class(cls):
			continue  # Act II: an unlockable class never raised this run (lines as before).
		cc.append("%s%d/%d" % [cls.substr(0, 1), game.horde.count_of(cls), game.horde.capacity(cls)])
	print("[metric] t=%d avg_horde=%.1f now=%d cap=%d %s deaths_win=%d lvl=%d kills=%d enemies=%d hp=%d boss_hp=%d crystals=%d xp=%d" % [
		int(game.elapsed), _horde_sum / maxf(1.0, _horde_n), game.horde.units.size(), game.horde.total_capacity(), " ".join(cc),
		game.horde.total_deaths - _death_mark, game.level, game.kills, game.enemies.active.size(), int(game.player.hp),
		int(game.enemies.boss.hp) if game.enemies.boss != null else -1, game.pickups.active.size(),
		int(game.stats.get("xp_collected", 0.0))])
	var parts := PackedStringArray()
	for k: String in game.stats.keys():
		if k.begins_with("summon_dmg_from_"):
			var v := float(game.stats[k]) - float(_last_src.get(k, 0.0))
			_last_src[k] = float(game.stats[k])
			if v >= 1.0:
				parts.append("%s=%d" % [k.substr(16), int(v)])
	print("[metric]    summon dmg taken this window: " + " ".join(parts))
	var kinds := {}
	var near := 0
	for e in game.enemies.active:
		if e.active:
			kinds[e.kind] = int(kinds.get(e.kind, 0)) + 1
			if e.position.distance_to(game.player.position) < 260.0:
				near += 1
	print("[metric]    alive by kind: %s within260=%d" % [str(kinds), near])
	_horde_sum = 0.0
	_horde_n = 0
	_death_mark = game.horde.total_deaths


## Counts a level-up hand for the summary's "level-up offers" line: NEW-item
## cards, and how many of them are later items (LevelUpData.WEIGHT_NEW_LATER).
func _count_offers(offers: Array[Dictionary]) -> void:
	_hands_seen += 1
	var later_in_hand := false  # This hand holds a later item's NEW card.
	for o in offers:
		var kind := String(o["kind"])
		if not kind in ["spell", "summon", "passive"] or int(o.get("from", 1)) != 0:
			continue
		_new_offers += 1
		var id := String(o["id"])
		var later := false  # The item is flagged "shared_card_pool" in its data.
		match kind:
			"spell": later = bool(AbilityData.SPELLS[id].get("shared_card_pool", false))
			"summon": later = bool(UnitData.UNITS[id].get("shared_card_pool", false))
			"passive": later = bool(PassiveData.PASSIVES[id].get("shared_card_pool", false))
		if later:
			_new_later_offers += 1
			_later_seen[id] = true
			later_in_hand = true
	if later_in_hand:
		_hands_with_later += 1


## Decides what to do with a level-up hand: {"action": "pick" | "reroll" |
## "banish" | "skip", "index": card}. Evolutions are always picked. army /
## evolve banish BANISH_IDS items, reroll hands scoring below REROLL_BELOW,
## and skip when the only useful card would heal an unhurt necromancer.
## Deterministic for a given offer list and charge state.
func choose_action(offers: Array[Dictionary]) -> Dictionary:
	_count_offers(offers)
	if _build_complete_time < 0.0:
		var only_fallbacks := true  # Hand holds nothing but fallback cards (or the optional Pact).
		for o in offers:
			only_fallbacks = only_fallbacks and (String(o["kind"]) == "fallback" or String(o["id"]) == PactData.ID)
		if only_fallbacks:
			_build_complete_time = game.elapsed
			_build_complete_level = game.level - game.pending_level_ups + 1
			print("[autotest] build complete (only fallback cards left) at %s, level %d" % [_clock(game.elapsed), _build_complete_level])
	var best := 0
	var best_score := -INF
	for i in offers.size():
		var s := _card_score(offers[i])
		if s > best_score:
			best_score = s
			best = i
	var pol := policy()  # This bot's card policy.
	var ab := game.abilities
	if best_score <= FORCED_BLOCK_SCORE:
		# --spells: only slot-stealing actives on offer; keep the slots.
		return {"action": "reroll", "index": -1} if ab.rerolls_left > 0 else {"action": "skip", "index": -1}
	if pol in ["army", "evolve", "summon"] and best_score < EVOLUTION_SCORE:
		var banish_ids: Array = BANISH_IDS.get(pol, [])
		for i in offers.size():
			if ab.can_banish(offers[i]) and String(offers[i]["id"]) in banish_ids and not _forced.has(String(offers[i]["id"])) \
					and not _char_keep.has(String(offers[i]["id"])):
				return {"action": "banish", "index": i}
		if best_score < REROLL_BELOW and ab.rerolls_left > 0:
			return {"action": "reroll", "index": -1}
		if String(offers[best]["id"]) == "dark_restoration" and game.player.hp >= game.player.max_hp:
			return {"action": "skip", "index": -1}
	return {"action": "pick", "index": best}


## Policy score of one card (higher = better).
##   naive : new summon classes > new spells > new passives > lowest level.
##   army  : ARMY_PRIORITY minus a level penalty.
##   evolve: EVOLVE_PRIORITY minus a small level penalty (maxes spells).
##   summon: SUMMON_PRIORITY minus a level penalty.
##   army / evolve / summon never take a NEW item off their build list
##   (FORCED_BLOCK_SCORE); --classes and --spells items come first. army /
##   summon take a later horde passive NEW only once LATE_PASSIVE_GATE is
##   owned.
##   pact  : naive, but the Profane Pact first (PACT_EAGER_SCORE); every
##           other policy ranks the Pact at PACT_SCORE unless --pact is given
##           (then it too takes the Pact first).
func _card_score(o: Dictionary) -> float:
	match String(o["kind"]):
		"evolution":
			return EVOLUTION_SCORE
		"fallback":
			return FALLBACK_SCORE
	var id := String(o["id"])
	if id == PactData.ID:
		var eager := policy() == "pact" or GameState.autotest_pact  # --policy=pact or --pact.
		return (PACT_EAGER_SCORE if eager else PACT_SCORE) - float(o["to"])
	if String(o["kind"]) == "summon" and _classes().has(id):
		return FORCED_CLASS_SCORE - float(o["to"])  # --classes: upgrade it first.
	if _forced.has(id):
		return FORCED_SPELL_SCORE - float(o["to"]) * 3.0  # --spells: take and level these first.
	if int(o["from"]) == 0 and not _reserved_ids().has(id) and _forced_slots_short(String(o["kind"])):
		return FORCED_BLOCK_SCORE  # Would take a slot a --spells item (or a summon-bot core class) still needs.
	var listed: Dictionary = _build_list(policy())  # Build list ({} = naive / pact).
	if not listed.is_empty() and int(o["from"]) == 0 and not listed.has(id):
		# Off-build item (the newer spells and passives, the later summon
		# classes, the other policies' items): a focused build never spends a
		# slot on it; reroll or skip instead (FORCED_BLOCK_SCORE).
		return FORCED_BLOCK_SCORE
	if policy() in ["army", "summon"] and int(o["from"]) == 0 and String(o["kind"]) == "passive" \
			and bool(PassiveData.PASSIVES[id].get("shared_card_pool", false)) and game.abilities.passive_level(LATE_PASSIVE_GATE) <= 0:
		return FORCED_BLOCK_SCORE  # A later horde passive before the bot's top passive (LATE_PASSIVE_GATE).
	match policy():
		"army":
			var pri := float(_build_list("army").get(id, 0.0))  # Card priority.
			if GameState.autotest_pact and id == "warding_ritual":
				pri = ARMY_PACT_WARDING_PRIORITY  # The Pact's slot comes out of Warding Ritual.
			return pri - float(o["to"]) * 8.0
		"evolve":
			return float(_build_list("evolve").get(id, 0.0)) - float(o["to"]) * 3.0
		"summon":
			return float(_build_list("summon").get(id, 0.0)) - float(o["to"]) * 6.0
	var s := -float(o["to"]) * 5.0
	var is_new := int(o["from"]) == 0
	match String(o["kind"]):
		"summon":
			s += 100.0 if is_new else 3.0
		"spell":
			s += 80.0 if is_new else 0.0
		"passive":
			s += 60.0 if is_new else 0.0
	return s


## Card-weight multiplier of item `id` for AbilityManager's weighted draw:
## FORCED_WEIGHT_MULT for --spells items, 1 otherwise (so every run without
## --spells draws exactly as before).
func card_weight_mult(id: String) -> float:
	return FORCED_WEIGHT_MULT if _forced.has(id) else 1.0


## Build list (item id -> priority) of a focused policy: ARMY_PRIORITY,
## EVOLVE_PRIORITY or SUMMON_PRIORITY (with the --character swap,
## _character_list()); empty for naive / pact, which take anything. Items
## not on the list are never taken NEW (see _card_score()), so these bots
## stay comparable baselines as spells and classes are added.
func _build_list(policy: String) -> Dictionary:
	var base: Dictionary = {}  # The policy's constant list.
	match policy:
		"army":
			base = ARMY_PRIORITY
		"evolve":
			base = EVOLVE_PRIORITY
		"summon":
			base = SUMMON_PRIORITY
	if base.is_empty() or _char_id() == CharacterData.DEFAULT_ID:
		return base
	if not _char_lists.has(policy):
		_char_lists[policy] = _character_list(base)
	return _char_lists[policy]


## `base` with the --character swap: the character's starting spell takes
## Shadow Bolt's priority (Shadow Bolt takes the starting spell's, or leaves
## the list), and the starting spell's evolution passive takes Soul
## Conduit's the same way. Both are recorded in _char_keep (never banished).
func _character_list(base: Dictionary) -> Dictionary:
	var out := base.duplicate()  # Swapped copy.
	var start := String(CharacterData.CHARACTERS[_char_id()]["spell"])  # Starting spell.
	_swap(out, AbilityData.STARTING_SPELL, start)
	_char_keep[start] = true
	var evo := EvolutionData.for_spell(start)  # Its evolution ("" if none).
	var bolt_evo := EvolutionData.for_spell(AbilityData.STARTING_SPELL)  # Void Barrage.
	if evo != "" and bolt_evo != "":
		var p := String(EvolutionData.EVOLUTIONS[evo]["passive"])  # Starting spell's evolution passive.
		_swap(out, String(EvolutionData.EVOLUTIONS[bolt_evo]["passive"]), p)
		_char_keep[p] = true
	return out


## Gives `to` the priority of `from` in `list` and `from` the old priority of
## `to` (or removes `from` when `to` was not listed). No-op when equal.
static func _swap(list: Dictionary, from: String, to: String) -> void:
	if from == to or not list.has(from):
		return
	var had := list.has(to)  # `to` was on the list.
	var old_to: Variant = list.get(to)  # Its old priority.
	list[to] = list[from]
	if had:
		list[from] = old_to
	else:
		list.erase(from)


## Items whose slots are reserved (id -> true): the --spells spells and
## their evolution passives, plus SUMMON_CORE under --policy=summon and
## ARMY_CORE under --policy=army.
func _reserved_ids() -> Dictionary:
	var core: Array = []  # The policy's core classes.
	match policy():
		"summon":
			core = SUMMON_CORE
		"army":
			core = ARMY_CORE
	if core.is_empty():
		return _forced
	var out := _forced.duplicate()  # Forced items plus the bot's core classes.
	for cls: String in core:
		out[cls] = true
	return out


## True when taking another NEW non-reserved item of card kind `kind` could
## lock a reserved item (_reserved_ids()) out of its slot kind: spells and
## summon classes use active slots ("spell" / "summon" cards), evolution
## passives passive slots. It blocks once the free slots of that kind are
## down to the reserved items still missing plus FORCED_SPARE_SLOTS
## (a margin from when treasure chests could fill a slot too).
func _forced_slots_short(kind: String) -> bool:
	var ab := game.abilities
	var passive := kind == "passive"  # Slot kind of this card.
	if not passive and kind not in ["spell", "summon"]:
		return false
	var missing := 0  # Reserved items of this slot kind not owned yet.
	for id: String in _reserved_ids().keys():
		if UnitData.UNITS.has(id):
			# Summon class: owned, or merged away into the Profane Bishop.
			if not passive and int(game.horde.class_levels[id]) <= 0 and not game.horde.evolutions.merged.has(id):
				missing += 1
			continue
		var is_spell := AbilityData.SPELLS.has(id)  # Spell (active) or passive.
		if passive and not is_spell and ab.passive_level(id) <= 0:
			missing += 1
		elif not passive and is_spell and ab.spell_level(id) <= 0:
			missing += 1
	if missing == 0:
		return false
	var free := (PlayerData.PASSIVE_SLOTS - ab.passive_count()) if passive else (ab.active_slots() - ab.active_count())  # Free slots (relics may add an active one).
	return free <= missing + FORCED_SPARE_SLOTS


## Bot use of the manual abilities (every policy, deterministic): a Grave
## Step toward the safest direction when _dash_reason() finds a reason, and
## Dread Rally when the meter is full and _rally_wanted().
func _drive_abilities() -> void:
	if game.player.dead:
		return
	var gs := game.grave_step
	if gs.charges > 0 and not gs.is_dashing():
		var why := _dash_reason()  # "" = no reason to dash.
		if why != "":
			var dir := _safest_dash_dir()  # Zero when every direction is blocked.
			if dir != Vector2.ZERO:
				if _routed():
					game.coop.lockstep.press(CoopLockstep.BTN_DASH, dir)  # Online co-op: an input for the lockstep.
				else:
					gs.request(dir)
				game.stat_add("bot_dash_" + why, 1.0)
	if game.dread_rally.is_full() and _rally_wanted():
		if _routed():
			game.coop.lockstep.press(CoopLockstep.BTN_ULT)
		else:
			game.dread_rally.request()


## True when this bot's presses travel as lockstep inputs (online co-op: the
## run's own bot, for this machine's slot), never as direct requests.
func _routed() -> bool:
	return net and game.coop != null and game.coop.lockstep != null and game.coop.lockstep.networked(slot)


## Switches the bound slot's Shadow Bolt aim (through the lockstep when routed).
func _toggle_aim() -> void:
	if _routed():
		game.coop.lockstep.press(CoopLockstep.BTN_AIM)
	else:
		game.abilities.toggle_bolt_aim()


## Why the bot should dash now: "telegraph" (a boss / stage danger zone
## pushes the necromancer), "crowd" (BOT_DASH_CROWD enemies touch the
## BOT_DASH_RADIUS circle), "hit" (hit within BOT_DASH_HIT_WINDOW s while in
## danger), or "" for no reason.
func _dash_reason() -> String:
	var p := game.player
	if _danger_at(p.position).length() > PlayerAbilityData.BOT_DASH_DANGER_PUSH:
		return "telegraph"
	game.enemy_grid.query(p.position, PlayerAbilityData.BOT_DASH_RADIUS + 30.0, _tmp)
	var close := 0  # Enemies touching the crowd circle.
	for e: Enemy in _tmp:
		if e.active and not e.is_structure and e.position.distance_to(p.position) <= PlayerAbilityData.BOT_DASH_RADIUS + e.radius:
			close += 1
	if close >= PlayerAbilityData.BOT_DASH_CROWD:
		return "crowd"
	if p.time_since_hit < PlayerAbilityData.BOT_DASH_HIT_WINDOW and game.horde.player_in_danger:
		return "hit"
	# --- Act III: the Iron Citadel --- (Grave Step through an overload pulse's front)
	if game.enemies.boss is BossDeusExMachina and game.enemies.boss.active and (game.enemies.boss as BossDeusExMachina).pulse_near(p.position):
		return "pulse"
	return ""


## Stage, Sanctum kit and boss danger push at `pos` (the autopilot's
## telegraph dodge).
func _danger_at(pos: Vector2) -> Vector2:
	var danger := game.enemies.stage.danger_push(pos) + game.enemies.rites.danger_push(pos)
	if game.enemies.boss != null and game.enemies.boss.active:
		danger += game.enemies.boss.danger_push(pos)
	if game.enemies.archive_haz != null:
		danger += game.enemies.archive_haz.danger_push(pos)  # Act II: pages, spore clouds, ink (null elsewhere).
	if game.empire != null:
		danger += game.empire.danger_push(pos)  # Act III: Lock-On lines, orbital strikes (null elsewhere).
	if game.pantheon != null:
		danger += game.pantheon.danger_push(pos)  # Act IV: bolt circles, fissures (null elsewhere).
	if game.shogunate != null:
		danger += game.shogunate.danger_push(pos)  # Act V: flashing Draw lines (null elsewhere).
	if game.enemies.assembly != null:
		danger += game.enemies.assembly.danger_push(pos)  # Act III, the Assembly Halls: glowing / burning furnace channels.
	if game.enemies.citadel != null:
		danger += game.enemies.citadel.danger_push(pos)  # Act III, the Iron Citadel: laser grids (null elsewhere).
	if game.enemies.underworld != null:
		danger += game.enemies.underworld.danger_push(pos)  # Act IV, the Asphodel Underworld: out of the Styx (null elsewhere).
	return danger


## The safest step direction: of BOT_DASH_DIRECTIONS directions (starting
## from the flee + danger direction), the one with the best score of clear
## length, few enemies and no danger around the landing point, and closeness
## to the flee direction. Vector2.ZERO when every direction is blocked.
func _safest_dash_dir() -> Vector2:
	var p := game.player.position
	var flee := Vector2.ZERO  # Away from nearby enemies, like the autopilot.
	game.enemy_grid.query(p, FLEE_RADIUS, _tmp)
	for e: Enemy in _tmp:
		if e.active:
			var diff := p - e.position
			var d := maxf(diff.length(), 1.0)
			flee += diff / d * (1.0 - d / FLEE_RADIUS)
	flee += _danger_at(p) * 3.0
	var base := flee.angle() if flee.length() > 0.01 else game.grave_step.facing_dir.angle()  # First candidate angle.
	var pref := Vector2.from_angle(base)  # Preferred direction.
	var best := Vector2.ZERO
	var best_score := -INF
	var n := PlayerAbilityData.BOT_DASH_DIRECTIONS
	for i in n:
		var dir := Vector2.from_angle(base + TAU * float(i) / float(n))
		var length := game.arena.clear_length(p, dir, PlayerAbilityData.DASH_DISTANCE, game.player.radius)
		if length < PlayerAbilityData.DASH_MIN_LENGTH:
			continue
		var end := p + dir * length  # Landing point.
		var crowd := 0.0  # Enemies near the landing point, weighted by closeness.
		game.enemy_grid.query(end, PlayerAbilityData.BOT_DASH_LANDING_RADIUS, _tmp)
		for e: Enemy in _tmp:
			if e.active:
				crowd += maxf(0.0, 1.0 - e.position.distance_to(end) / PlayerAbilityData.BOT_DASH_LANDING_RADIUS)
		var score := length / PlayerAbilityData.DASH_DISTANCE - crowd * 0.6 - _danger_at(end).length() * 3.0 + dir.dot(pref) * 0.5
		if score > best_score:
			best_score = score
			best = dir
	return best


## True when the bot should spend a full Dread Rally meter: the player is in
## danger, the stage boss is alive, or the army is badly hurt (average HP
## below BOT_RALLY_ARMY_HP, or fewer than BOT_RALLY_ARMY_ALIVE of its
## capacity alive; temporary summons do not count).
func _rally_wanted() -> bool:
	var h := game.horde
	if h.player_in_danger or (game.enemies.boss != null and game.enemies.boss.active):
		return true
	var alive := 0  # Living permanent summons.
	var hp_frac := 0.0  # Sum of their HP fractions.
	for u in h.units:
		if u.active and not u.is_temporary:
			alive += 1
			hp_frac += u.hp / maxf(u.max_hp, 1.0)
	var cap := h.total_capacity()
	if cap > 0 and float(alive) < float(cap) * PlayerAbilityData.BOT_RALLY_ARMY_ALIVE:
		return true
	return alive > 0 and hp_frac / float(alive) < PlayerAbilityData.BOT_RALLY_ARMY_HP


## Autopilot: flee nearby enemies, drift toward XP, dodge boss telegraphs,
## plus a slow circular wander so the run covers ground.
func get_move_vector() -> Vector2:
	var p := game.player.position
	var away := Vector2.ZERO
	game.enemy_grid.query(p, FLEE_RADIUS, _tmp)
	for e: Enemy in _tmp:
		if not e.active:
			continue
		var diff := p - e.position
		var d := maxf(diff.length(), 1.0)
		away += diff / d * (1.0 - d / FLEE_RADIUS)
	var toward := Vector2.ZERO
	var best_d := XP_SEEK_RADIUS
	for c in game.pickups.active:
		var d := p.distance_to(c.position)
		if d < best_d:
			best_d = d
			toward = (c.position - p) / maxf(d, 1.0)
	var danger := game.enemies.stage.danger_push(p) + game.enemies.rites.danger_push(p)
	if game.enemies.tide != null:
		danger += game.enemies.tide.danger_push(p)  # Act II: out of a telegraphed tide surge.
	if game.enemies.boss != null and game.enemies.boss.active:
		danger += game.enemies.boss.danger_push(p)
	if game.enemies.archive_haz != null:
		danger += game.enemies.archive_haz.danger_push(p)  # Act II: pages, spore clouds, ink (null elsewhere).
	if game.empire != null:
		danger += game.empire.danger_push(p)  # Act III: Lock-On lines, orbital strikes (null elsewhere).
	if game.pantheon != null:
		danger += game.pantheon.danger_push(p)  # Act IV: bolt circles, fissures (null elsewhere).
	if game.shogunate != null:
		danger += game.shogunate.danger_push(p)  # Act V: flashing Draw lines (null elsewhere).
	if game.enemies.assembly != null:
		danger += game.enemies.assembly.danger_push(p)  # Act III, the Assembly Halls: glowing / burning furnace channels.
	if game.enemies.citadel != null:
		danger += game.enemies.citadel.danger_push(p)  # Act III, the Iron Citadel: laser grids (null elsewhere).
	if game.enemies.underworld != null:
		danger += game.enemies.underworld.danger_push(p)  # Act IV, the Asphodel Underworld: out of the Styx (null elsewhere).
	var objective := Vector2.ZERO
	# Walk to shrines any time, to graves under consecration only when calm.
	var goal := game.enemies.stage.seek_point(p, OBJECTIVE_SEEK_RADIUS, away.length() < 0.2)
	if goal == Vector2.INF and game.enemies.march != null and away.length() < 0.2:
		# Crimson March: close in on outposts, generators and carts when calm.
		goal = game.enemies.march.seek_point(p, OBJECTIVE_SEEK_RADIUS)
	if goal == Vector2.INF and game.enemies.sanctum != null and away.length() < 0.2 and policy() in SANCTUM_SEEK_POLICIES:
		# Sanctum: close in on ward crystals and sacred altars when calm.
		goal = game.enemies.sanctum.seek_point(p, OBJECTIVE_SEEK_RADIUS)
	if goal == Vector2.INF and game.enemies.harbour != null and away.length() < 0.2 and policy() in SANCTUM_SEEK_POLICIES:
		# Gullhaven Harbour: close in on bell buoys and smugglers' caches when calm.
		goal = game.enemies.harbour.seek_point(p, OBJECTIVE_SEEK_RADIUS)
	if goal == Vector2.INF and game.enemies.archive != null and away.length() < 0.5:
		# The Hollow Archive: walk onto forbidden tomes when calm (burns them).
		goal = game.enemies.archive.seek_point(p, OBJECTIVE_SEEK_RADIUS)
	# --- Act II: Ul-Thalos, the Risen Spire ---
	if goal == Vector2.INF and game.enemies.spire != null and away.length() < 0.2 and policy() in SANCTUM_SEEK_POLICIES:
		goal = game.enemies.spire.seek_point(p, OBJECTIVE_SEEK_RADIUS)  # Ul-Thalos: topple the dream pillars when calm.
	# --- Act III: the Assembly Halls ---
	if goal == Vector2.INF and game.enemies.assembly != null and away.length() < 0.3 and policy() in SANCTUM_SEEK_POLICIES:
		goal = game.enemies.assembly.seek_point(p, OBJECTIVE_SEEK_RADIUS)  # Smash the fabricators when calm.
	# --- Act III: the Scrap Wastes ---
	if goal == Vector2.INF and game.enemies.wastes != null and away.length() < 0.2 and policy() in SANCTUM_SEEK_POLICIES:
		goal = game.enemies.wastes.seek_point(p, OBJECTIVE_SEEK_RADIUS)  # The Scrap Wastes: tear down the Signal Pylons when calm.
	# --- Act III: the Iron Citadel ---
	if goal == Vector2.INF and game.enemies.citadel != null and away.length() < 0.3 and GameState.autotest_policy in SANCTUM_SEEK_POLICIES \
			and game.horde.units.size() >= CITADEL_SEEK_ARMY:
		goal = game.enemies.citadel.seek_point(p, OBJECTIVE_SEEK_RADIUS)  # The Iron Citadel: gate generators, then turrets, when calm and the army can take them.
	# --- Act IV: the Shores of Ilion ---
	if goal == Vector2.INF and game.enemies.ilion != null and away.length() < 0.2 and policy() in SANCTUM_SEEK_POLICIES:
		goal = game.enemies.ilion.seek_point(p, OBJECTIVE_SEEK_RADIUS)  # The Shores of Ilion: burn the siege towers when calm.
	if game.enemies.boss is BossVhalneth and game.enemies.boss.active:
		# Vhal'Neth never walks: go and fight her arms, then her face (every policy).
		var at := (game.enemies.boss as BossVhalneth).approach_point(p)
		if at != Vector2.INF and p.distance_to(at) > 150.0 and away.length() < 0.6:
			goal = at
	# --- Act III: the Iron Citadel ---
	if game.enemies.boss is BossDeusExMachina and game.enemies.boss.active:
		# The Siege Core is planted: go and bring the army to its shield drones (every policy).
		var at := (game.enemies.boss as BossDeusExMachina).approach_point(p)
		if at != Vector2.INF and p.distance_to(at) > 200.0 and away.length() < 0.6:
			goal = at
	if game.enemies.sinking != null:
		danger += game.enemies.sinking.danger_push(p) * 0.5  # Ul-Thalos: keep off the shore the sea is about to take.
	if goal != Vector2.INF:
		objective = (goal - p).normalized()
	var avoid := game.arena.avoid_vector(p, game.player.radius, OBSTACLE_LOOK)
	var wander := Vector2.from_angle(game.elapsed * 0.3) * 0.35
	var loot := _loot_vector(p, away.length())  # Toward a nearby chest / drop when safe.
	if game.coop != null:
		return _coop_move(away, toward, objective, danger, avoid, wander, loot)
	return (away * 1.5 + toward * 1.2 + objective * 1.0 + danger * 3.0 + avoid * 1.5 + wander + loot * 1.4).limit_length(1.0)


## Co-op autopilot mix (--coop-bot): the solo mix, plus a walk to a downed
## partner (held in revive reach, ignoring the crowd) and a drift back toward
## a partner who is far away (CoopSession.revive_vector() / cohesion_vector()).
## Slot 1 wanders the other way round, so the two do not walk in step.
func _coop_move(away: Vector2, toward: Vector2, objective: Vector2, danger: Vector2, avoid: Vector2, wander: Vector2, loot: Vector2) -> Vector2:
	var p := game.player
	var co := game.coop
	if co.holding_revive(p):
		return (danger * 3.0 + avoid * 1.5).limit_length(0.3)  # Stay on the partner: only dodge telegraphs and obstacles.
	var revive := co.revive_vector(p) * CoopData.BOT_REVIVE_WEIGHT
	var cohesion := co.cohesion_vector(p) * CoopData.BOT_COHESION_WEIGHT
	var w := wander if slot == 0 else -wander
	return (away * 1.5 + toward * 1.2 + objective * 1.0 + danger * 3.0 + avoid * 1.5 + w + loot * 1.4 + revive + cohesion).limit_length(1.0)


## Unit vector toward the nearest chest (within ChestData.AUTOTEST_SEEK_RADIUS,
## unless `pressure` > CHEST_SAFE_PRESSURE), else the nearest power-up drop
## within DROP_SEEK_RADIUS (unless `pressure` > DROP_SAFE_PRESSURE), else zero.
func _loot_vector(p: Vector2, pressure: float) -> Vector2:
	if pressure <= CHEST_SAFE_PRESSURE:
		var c := game.chests.nearest_chest(p, ChestData.AUTOTEST_SEEK_RADIUS)  # Closest chest in reach.
		if c != null:
			return (c.position - p).normalized()
	if pressure > DROP_SAFE_PRESSURE:
		return Vector2.ZERO
	var d := game.powerups.nearest_drop(p, DROP_SEEK_RADIUS)  # Closest drop in reach.
	if d == null:
		return Vector2.ZERO
	return (d.position - p).normalized()


## Prints the final summary and quits the engine.
func finish(summary: Dictionary) -> void:
	if _finished:
		return
	_finished = true
	var real_s := float(Time.get_ticks_msec() - _real_start_msec) / 1000.0
	var counts: Dictionary = summary["horde_counts"]
	var caps: Dictionary = summary["horde_caps"]
	var classes := PackedStringArray()
	for cls: String in UnitData.CLASS_ORDER:
		if _unused_locked_class(cls):
			continue  # Act II: an unlockable class never raised this run (lines as before).
		classes.append("%s %d/%d" % [cls, int(counts[cls]), int(caps[cls])])
	var stat_parts := PackedStringArray()
	var st: Dictionary = summary["stats"]
	var keys := st.keys()
	keys.sort()
	for k: String in keys:
		stat_parts.append("%s=%d" % [k, int(st[k])])
	print("[autotest] ===== NECROPATHY AUTOTEST SUMMARY =====")
	print("[autotest] result: %s (%s)" % ["VICTORY / RUN COMPLETE" if summary["victory"] else "NOT COMPLETED", summary["reason"]])
	print("[autotest] time reached: %s elapsed (%.1f s game time, %.1f s real time); past 0:00: %.1f s; Reckoning waves: %d" % [
		_clock(summary["time"]), float(summary["time"]), real_s, float(summary["time_past_zero"]), int(summary["reckoning_waves"])])
	print("[autotest] kills: %d | level: %d" % [int(summary["kills"]), int(summary["level"])])
	var at_mark := PackedStringArray()  # "mm:ss=Ln" per TIME_MARKS entry reached.
	for i in TIME_MARKS.size():
		if _level_at_mark[i] >= 0:
			at_mark.append("%s=L%d" % [_clock(float(TIME_MARKS[i])), _level_at_mark[i]])
	var reached := PackedStringArray()  # "Ln@mm:ss" per LEVEL_MARKS entry reached.
	for lvl: int in LEVEL_MARKS:
		if lvl < _level_time.size():
			reached.append("L%d@%s" % [lvl, _clock(_level_time[lvl])])
	print("[autotest] level pacing: %s | reached: %s" % [" ".join(at_mark), " ".join(reached)])
	print("[autotest] build complete: %s" % ("at %s, level %d" % [_clock(_build_complete_time), _build_complete_level] if _build_complete_time >= 0.0 else "no"))
	print("[autotest] horde: %d alive / capacity %d (%s)" % [int(summary["horde_total"]), int(summary["horde_capacity"]), ", ".join(classes)])
	print("[autotest] summons spawned: %d, died: %d, hard recalls: %d (stall recalls: %d)" % [game.horde.total_spawned, game.horde.total_deaths, game.horde.hard_recalls, game.horde.stall_recalls])
	var boss_line := "boss spawned: %s" % ("yes at %.1f s" % _boss_spawn_time if summary["boss_spawned"] else "no")
	boss_line += " | boss defeated: %s" % ("yes at %.1f s" % _boss_death_time if summary["boss_defeated"] else "no")
	if summary["boss_spawned"]:
		boss_line += " | boss HP left: %d / %d" % [int(summary["boss_hp"]), int(summary["boss_max_hp"])]
	print("[autotest] " + boss_line)
	print("[autotest] player HP: %d / %d (invulnerable: %s)" % [int(summary["player_hp"]), int(summary["player_max_hp"]), str(game.player.invulnerable)])
	print("[autotest] picks (%d): %s" % [(summary["picks"] as PackedStringArray).size(), ", ".join(summary["picks"])])
	var st_all: Dictionary = summary["stats"]
	var ward_rate := float(_two_priest_wards) / (_two_priest_time / 60.0) if _two_priest_time > 1.0 else 0.0
	print("[autotest] wards on you: %d total, absorbed %d dmg | %d wards in %.0f s with 2+ Warders/Bishops alive (%.1f / min) | heal casts: %d | ally barriers: %d, barrier dmg absorbed: %d" % [
		int(st_all.get("priest_wards", 0.0)), int(st_all.get("ward_absorbed", 0.0)), _two_priest_wards, _two_priest_time, ward_rate, int(st_all.get("priest_heals", 0.0)),
		int(st_all.get("ally_barriers", 0.0)), int(st_all.get("barrier_absorbed", 0.0))])
	var ab := game.abilities
	print("[autotest] evolutions: %s" % (", ".join(ab.evolution_history) if not ab.evolution_history.is_empty() else "none"))
	_print_summon_evolutions(st_all)
	_print_recipe_book()
	print("[autotest] codex: %s" % game.codex.summary_line())  # Codex records (CodexLog).
	print("[autotest] epilogue: %s" % _epilogue_line())  # Illustrated epilogue (EpilogueData; read only).
	print("[autotest] volleys: %s" % game.volleys.summary_line())  # Bullet heaven pass (VolleyDirector).
	# Adaptive quality: depends on real frame times, so it is not an [autotest] line (the same-seed gates
	# compare those); drawing only.
	print("[visual] adaptive quality: %s" % AdaptiveQuality.summary_line())
	if bool(summary["victory"]) and not game.end_screen.victory_info.is_empty():
		print("[autotest] victory screen: %s" % VictoryResults.summary_line(game.end_screen.victory_info))  # Content wave 2 (victories only).
	if game.dread != null:
		print("[autotest] dread: %s" % game.dread.summary_line())  # Act II Dread (DreadMeter; Act II stages only).
	if game.claims != null:
		print("[autotest] claims: %s" % game.claims.summary_line())  # Act II Claims (EyeClaims; Act II stages only).
	EmpireReport.print_lines(game, st_all)  # Act III: line of fire, lock-on, steel, purge protocol, kinds, the stage (only when the Empire ran).
	PantheonReport.print_lines(game, st_all)  # Act IV: divine wrath, phalanx, glory, kinds, the stage (only when the Pantheon ran).
	ShogunateReport.print_lines(game, st_all)  # Act V: the sun's course, the draw, from the shadows, kinds, the stage (only when the Shogunate ran).
	WastesReport.print_items(game, st_all)  # Act III, the Scrap Wastes: Death Ray and its passives (only when taken).
	IlionReport.print_items(game, st_all)  # Act IV, the Shores of Ilion: Paris's Arrow and its passives (only when taken).
	# --- Act V: the Burning Province ---
	ProvinceReport.print_items(game, st_all)  # Hundred Shadows and its passives (only when taken).
	print("[autotest] gravebow / bone colossus: %s | %s" % [GravebowKit.summary_line(st_all), ColossusKit.summary_line(st_all)])
	print("[autotest] necro spells: %s" % ab.spells.summary_line())
	print("[autotest] later spells: %s" % ab.spells.later_summary_line())
	print("[autotest] later spell passives: grim_ledger Lv%d bonus_dmg=%d | spirit_binding Lv%d | restless_dead Lv%d | temporary summons spawned=%d" % [
		ab.passive_level("grim_ledger"), int(st_all.get("grim_ledger_bonus_dmg", 0.0)), ab.passive_level("spirit_binding"),
		ab.passive_level("restless_dead"), game.horde.temp_spawned])
	print("[autotest] horde passives: %s" % MinionPassives.summary_line(game))
	print("[autotest] class passives: %s" % ClassPassives.summary_line(game))
	if SeraphTexts.used(game):
		print("[autotest] fallen seraph: %s" % SeraphTexts.summary_line(game))  # Act II: only in runs that had her.
	if GolemTexts.used(game):
		print("[autotest] bone golem: %s" % GolemTexts.summary_line(game))  # Content wave 2: only in runs with the Golem or Grave Masonry.
	var syn := game.horde.synergies
	print("[autotest] synergies active at end: %s | activations: %s" % [
		", ".join(syn.active_ids()) if not syn.active_ids().is_empty() else "none",
		", ".join(syn.activation_log) if not syn.activation_log.is_empty() else "none"])
	print("[autotest] synergy bonus%s: %s" % [" (synergies off)" if GameState.autotest_synergies_off else "", SynergyManager.summary_line(st_all)])
	print("[autotest] level-up offers: hands %d, new-item cards %d, later items %d (%.0f%%) in %d hands (%.0f%%), distinct later items offered %d" % [
		_hands_seen, _new_offers, _new_later_offers, 100.0 * _new_later_offers / maxf(1.0, float(_new_offers)),
		_hands_with_later, 100.0 * _hands_with_later / maxf(1.0, float(_hands_seen)), _later_seen.size()])
	print("[autotest] level-up actions: rerolls used %d/%d, banishes used %d/%d (banished: %s), skips %d" % [
		ab.rerolls_max - ab.rerolls_left, ab.rerolls_max, ab.banishes_max - ab.banishes_left, ab.banishes_max,
		", ".join(PackedStringArray(ab.banished.keys())) if not ab.banished.is_empty() else "none", ab.skips_used])
	# Shadow Bolt damage includes its Void Barrage evolution (bolts + shards).
	var bolt_total := _bolt_damage(st, "dmg_")
	var bolt_nearest := bolt_total if _bolt_dmg_at_switch < 0.0 else _bolt_dmg_at_switch
	print("[autotest] shadow bolt: %d dmg in Nearest mode, %d dmg in Strongest mode; to boss: %d of %d total boss dmg" % [
		int(bolt_nearest), int(bolt_total - bolt_nearest), int(_bolt_damage(st, "bossdmg_")), int(_sum_prefix(st, "bossdmg_"))])
	print("[autotest] stats: " + " ".join(stat_parts))
	var atk := PackedStringArray()
	for id: String in _boss_special_ids():
		atk.append("%s=%d" % [id, int(st.get("boss_atk_" + id, 0.0))])
	print("[autotest] boss attacks: %s | wrath: %s | hammer soaked by undead: %d | charges stopped by undead: %d (shielding the player: %d) | judgment hits: %d | call soldiers: %d | holy zones boss/grave: %d/%d" % [
		" ".join(atk), "yes" if st.has("boss_phase2") or st.has("boss_last_stand") else "no", int(st.get("boss_hammer_soaked", 0.0)), int(st.get("boss_charge_stopped", 0.0)), int(st.get("boss_charge_blocked", 0.0)),
		int(st.get("boss_judgment_hits", 0.0)), int(st.get("boss_call_soldiers", 0.0)), int(st.get("holy_zones_boss", 0.0)), int(st.get("holy_zones_grave", 0.0))])
	if game.enemies.march != null:
		_print_march(st)
	if game.enemies.sanctum != null:
		var sd := game.enemies.sanctum  # Sanctum objectives.
		print("[autotest] sanctum: %s | minion dmg prevented by chambers %d" % [sd.summary_line(), int(st.get("sanctum_chamber_dmg_prevented", 0.0))])
		print("[autotest] sanctum events (%d): %s" % [sd.fired.size(), ", ".join(sd.fired)])
	_print_sanctum(st)
	# --- Act II: Gullhaven Harbour ---
	HarbourReport.print_lines(game, st)
	_print_battle_sister(st)
	_print_archive(st)  # Act II: the Hollow Archive (only when its stage or kinds ran).
	SpireReport.print_all(game, st)  # Act II, Ul-Thalos: the sinking, pillars, kinds, Vhal'Neth, the Waking, its items (only when they ran).
	AssemblyReport.print_items(game, st)  # Act III, the Assembly Halls: Hollow Puppet, the Grave Drone, their passives, Signal Ghost (only when owned).
	CitadelReport.item_lines(game, st)  # Act III, the Iron Citadel: Scrap Swarm, the Iron Revenant (only when used; the stage's own lines are EmpireReport's).
	OlympusReport.item_lines(game, st)  # Act IV, Mount Olympus: Stolen Thunder, Grounded Bones (only when used; the stage's own lines are PantheonReport's).
	UnderworldReport.item_lines(game, st)  # Act IV, the Asphodel Underworld: River Styx, the Myrmidon Shades (only when used; the stage's own lines are PantheonReport's).
	SunRoadReport.item_lines(game, st)  # Act V, the Road to the Sun: Black Sun, the Bound Oni (only when used; the stage's own lines are ShogunateReport's).
	KuroganeReport.item_lines(game, st)  # Act V, Castle Kurogane: Banner of the Dead, Warlord's Seal, Unbending (only when taken; the stage's own lines are ShogunateReport's).
	if game.enemies.boss is BossSeraphine:
		print("[autotest] seraphine: %s" % BossSeraphine.summary_line(st))
	var fired := game.enemies.stage.fired
	print("[autotest] stage events fired (%d): %s" % [fired.size(), ", ".join(fired)])
	print("[autotest] templar charges: %d (body-blocked by warriors: %d) | temporary summons spawned: %d" % [
		int(st.get("templar_charges", 0.0)), int(st.get("templar_charges_blocked", 0.0)), game.horde.temp_spawned])
	print("[autotest] obstacle collisions resolved: player=%d summons=%d enemies=%d" % [
		game.arena.resolved_player, game.arena.resolved_summons, game.arena.resolved_enemies])
	_print_class_specials(st)
	print("[autotest] special evolutions: %s" % SpecialEvolutions.summary_line(game))
	_print_abilities(st)
	print("[autotest] army formation: %s" % game.stance.summary_line())
	print("[autotest] character: %s" % game.innates.summary_line())
	print("[autotest] stuck_units=%d (touching an obstacle: %d) %s" % [_stuck_units, _stuck_at_obstacle, str(_stuck_by)])
	print("[metric] boss_hp_at_0=%d min_hp_before_0=%d" % [int(_boss_hp_at_0), int(_min_hp)])
	print("[autotest] peaks: enemies=%d summons=%d projectiles=%d effects=%d crystals=%d" % [
		int(_peak["enemies"]), int(_peak["summons"]), int(_peak["projectiles"]), int(_peak["effects"]), int(_peak["crystals"])])
	print("[autotest] nodes created (pools): enemies=%d summons=%d projectiles=%d effects=%d crystals=%d" % [
		game.enemies.created_nodes, game.horde.created_nodes, game.projectiles.created, game.effects.created, game.pickups.created])
	print("[autotest] simulation step: avg %.2f ms, worst %.2f ms" % [game.avg_step_ms(), float(game.worst_step_usec) / 1000.0])
	_print_powerups(summary)
	_print_soul_ash(summary)
	_print_hyper_skins(summary)
	RewardsReport.print_line(self, summary)  # Content wave 2: achievement rewards.
	print("[autotest] feedback: %s" % FeedbackReport.summary_line(game, summary))  # Feedback buttons: three sample reports built, nothing opened.
	if game.coop != null:
		game.coop.print_report()  # --coop-bot: a line per slot and the coop line (CoopSession).
		if game.hud != null and game.hud.coop_ui != null:
			print("[autotest] %s" % game.hud.coop_ui.summary_line())  # The co-op visuals (CoopUi; read only).
	if game.perf != null:
		game.perf.print_table()  # --perf: the per-tick timing table (PerfProbe).
	if game.monitor != null:
		game.monitor.print_peaks()  # --monitor=N: the last sample and the peaks (MonitorProbe).
	if ArtMissLog.on:
		ArtMissLog.print_report()  # --art-misses: the sprite keys drawn without art ("[art-miss]" lines).
	if game.coop != null and game.coop.lockstep != null:
		print("[autotest] coop %s" % game.coop.lockstep.report_line())  # Online co-op: ticks, frames, checksums.
		await get_tree().create_timer(CoopLockstepData.LINGER_S, true, false, true).timeout  # The last frames reach the partner.
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	get_tree().quit(0 if summary["victory"] else 1)


## Act II, the Hollow Archive: its stage mechanics (tomes, wells, the
## orrery, the Librarian, rifts), its kinds, the Archivist, Forbidden Verse and
## the Archive's passives. Each line prints only when it has something to
## say, so the other stages' summaries are unchanged.
func _print_archive(st: Dictionary) -> void:
	var ad := game.enemies.archive  # The Archive's director (null elsewhere).
	if ad != null:
		print("[autotest] archive: %s | objective ash %d" % [ad.summary_line(), int(st.get("objective_ash", 0.0))])
		print("[autotest] archive rifts: %s" % ad.rifts.summary_line())
		print("[autotest] archive events (%d): %s" % [ad.fired.size(), ", ".join(ad.fired)])
	var spawned := PackedStringArray()  # "kind spawned/killed" per Archive kind met.
	var any := false
	for kind: String in ArchiveEnemyData.ORDER + ArchiveEnemyData.MASS_KINDS.slice(1) + [ArchiveEnemyData.RIFT]:
		var n := int(st.get("spawned_" + kind, 0.0))  # Counted for kinds with a kit (Enemy.activate()).
		var k := int(st.get("kill_" + kind, 0.0))
		if n > 0 or k > 0:
			any = true
		spawned.append("%s %d/%d" % [kind, n, k])
	if any:
		print("[autotest] archive enemies (spawned/killed): %s" % " ".join(spawned))
		print("[autotest] archive kits: scribe curses %d (cultists cursed %d) | ink wraith rises %d, dives %d | spore clouds %d (+%d death clouds), summon dmg from spores %d | masses split %d (capped %d) | librarian beams %d (player hits %d), summons turned %d, lashes %d (summon hits %d), killed %d (avg %.1f s), dmg taken %d" % [
			int(st.get("scribe_curses", 0.0)), int(st.get("scribe_cursed", 0.0)), int(st.get("ink_wraith_rises", 0.0)), int(st.get("ink_wraith_dives", 0.0)),
			int(st.get("spore_clouds_left", 0.0)), int(st.get("spore_death_clouds", 0.0)), int(st.get("summon_dmg_from_spores", 0.0)),
			int(st.get("gibbering_splits", 0.0)), int(st.get("gibbering_splits_capped", 0.0)),
			int(st.get("librarian_beams", 0.0)), int(st.get("librarian_beam_player_hits", 0.0)), int(st.get("librarian_turned", 0.0)),
			int(st.get("librarian_lashes", 0.0)), int(st.get("librarian_lash_summon_hits", 0.0)), int(st.get("librarian_kills", 0.0)),
			float(st.get("librarian_ttk", 0.0)) / maxf(1.0, float(st.get("librarian_kills", 0.0))), int(_sum_prefix(st, "minibossdmg_"))])
		print("[autotest] archive hazards: ink pools %d, spore clouds %d | necromancer in ink %.0f s, in spores %.0f s | player dmg from pages %d, librarian %d, archive kinds %d" % [
			int(st.get("archive_ink_pools", 0.0)), int(st.get("archive_spore_clouds", 0.0)),
			float(st.get("archive_ink_seconds", 0.0)), float(st.get("archive_spore_seconds", 0.0)),
			int(st.get("player_dmg_from_archivist_page", 0.0)), int(float(st.get("player_dmg_from_librarian_beam", 0.0)) + float(st.get("player_dmg_from_librarian_lash", 0.0))),
			int(_archive_kind_player_dmg(st))])
	if game.enemies.boss is BossArchivist:
		print("[autotest] archivist: %s" % BossArchivist.summary_line(st))
	var verse := game.abilities.spells.act2_summary_line()  # "" unless an Act II spell was taken.
	if verse != "":
		print("[autotest] act ii spells: %s" % verse)
	var ab := game.abilities
	if ab.passive_level("marginalia") > 0 or ab.passive_level("iron_mind") > 0:
		print("[autotest] act ii passives: marginalia Lv%d bonus_dmg=%d | iron_mind Lv%d" % [
			ab.passive_level("marginalia"), int(st.get("marginalia_bonus_dmg", 0.0)), ab.passive_level("iron_mind")])


## Damage the necromancer took from the Archive's soldier kinds.
static func _archive_kind_player_dmg(st: Dictionary) -> float:
	var total := 0.0
	for kind: String in ArchiveEnemyData.ORDER + ArchiveEnemyData.MASS_KINDS.slice(1):
		total += float(st.get("player_dmg_from_" + kind, 0.0))
	return total


## Prints the Meta recipe book (evolutions discovered in any run; in memory
## only unless --meta-save) and builds the pause menu's Recipes rows once,
## headless, so that UI code runs in every autotest.
func _print_recipe_book() -> void:
	var known := PackedStringArray()  # Discovered evolution ids, recipe order.
	for id: String in EvolutionRecipes.ids():
		if Meta.is_recipe_discovered(id):
			known.append(id)
	var buttons: Array[Button] = []  # Focus buttons of the built rows.
	var list := RecipesPanel.build_list(Meta.discovered_recipes, buttons)
	var rows := list.get_child_count()
	list.free()
	print("[autotest] recipe book: %d / %d discovered (%s) | Recipes view rows built: %d (saved: %s)" % [
		Meta.discovered_count(), EvolutionRecipes.ids().size(), ", ".join(known) if not known.is_empty() else "none",
		rows, str(Meta.can_write())])


## Prints the evolutions split by type (spell / summon, with times), the
## summon-evolution counters, and every summon source's damage, heals and
## shields, plus the same summed per base class.
func _print_summon_evolutions(st: Dictionary) -> void:
	var spell := PackedStringArray()  # "id@mm:ss" spell evolutions.
	var summon := PackedStringArray()  # "id@mm:ss" summon evolutions.
	for entry: String in game.abilities.evolution_history:
		if SummonEvolutionData.EVOLUTIONS.has(entry.get_slice("@", 0)):
			summon.append(entry)
		else:
			spell.append(entry)
	print("[autotest] evolutions by type: spell: %s | summon: %s" % [
		", ".join(spell) if not spell.is_empty() else "none", ", ".join(summon) if not summon.is_empty() else "none"])
	var ev := game.horde.evolutions
	print("[autotest] summon evolutions: lich raised %d (capped %d) | merge converted %d, dissolved %d | aura pulses %d | merged classes: %s" % [
		int(st.get("lich_raised", 0.0)), int(st.get("lich_raise_capped", 0.0)), int(st.get("merge_converted", 0.0)),
		int(st.get("merge_dissolved", 0.0)), int(st.get("aura_pulses", 0.0)),
		", ".join(PackedStringArray(ev.merged.keys())) if not ev.merged.is_empty() else "none"])
	print("[autotest] winter revenant: %s" % WinterRevenant.summary_line(st))
	# Summon statistic tags -> base class they belong to.
	var tags := {}
	for cls: String in UnitData.CLASS_ORDER:
		tags[cls] = cls
	tags["bash"] = "warrior"
	for evo: String in SummonEvolutionData.ORDER:
		var base: String = SummonEvolutionData.EVOLUTIONS[evo]["bases"][0]
		tags[evo] = base
		tags[evo + "_bash"] = base
		tags[evo + "_cleave"] = base
	tags["lich_risen"] = "lich_risen"
	tags[WinterRevenant.SRC_SHATTER] = "frost_wraith"
	tags[WinterRevenant.SRC_NOVA] = "frost_wraith"
	tags["bishop_aura"] = "bishop"
	for tag: String in ClassPassives.EXTRA_TAGS:
		tags[tag] = ClassPassives.EXTRA_TAGS[tag]  # Hellhound burn / trail, Ossuary Engine shards.
	tags[SeraphBehavior.SRC_DIVE] = SeraphTexts.CLASS_ID  # Act II: the Fallen Seraph's dive ...
	tags[SeraphBehavior.SRC_FEATHERS] = SeraphTexts.CLASS_ID  # ... and feather rings.
	tags[GolemBehavior.SLAM_SOURCE] = GolemKit.CLASS_ID  # Content wave 2: the Golem's slam splash ...
	tags[GolemKit.WALL_SOURCE] = GolemKit.CLASS_ID  # ... and the Titan's collapse wall.
	var by_src := PackedStringArray()  # "tag=dmg/heal/shield" per source.
	var by_cls := {}  # Base class -> [dmg, heal, shield].
	for tag: String in tags:
		var v := [float(st.get("dmg_" + tag, 0.0)), float(st.get("heal_by_" + tag, 0.0)), float(st.get("shield_by_" + tag, 0.0))]
		if v[0] + v[1] + v[2] <= 0.0:
			continue
		by_src.append("%s=%d/%d/%d" % [tag, int(v[0]), int(v[1]), int(v[2])])
		var cls: String = tags[tag]
		var sum: Array = by_cls.get(cls, [0.0, 0.0, 0.0])
		for i in 3:
			sum[i] = float(sum[i]) + float(v[i])
		by_cls[cls] = sum
	var cls_parts := PackedStringArray()  # "class=dmg/heal/shield" per base class.
	for cls: String in by_cls:
		var sum: Array = by_cls[cls]
		cls_parts.append("%s=%d/%d/%d" % [cls, int(sum[0]), int(sum[1]), int(sum[2])])
	print("[autotest] summon output by source (dmg/heal/shield): %s" % " ".join(by_src))
	print("[autotest] summon output by class (dmg/heal/shield): %s" % " ".join(cls_parts))


## Prints one line per later summon class (CLASS_REPORT): level, live count,
## deaths, damage by source and its special counters, plus the special
## cancellations / obstacle endings.
func _print_class_specials(st: Dictionary) -> void:
	for cls: String in CLASS_REPORT:
		var rep: Array = CLASS_REPORT[cls]  # [damage sources, count stats].
		var dmg_parts := PackedStringArray()  # "source=N" damage dealt.
		var total := 0.0  # Damage dealt by the class.
		for src: String in rep[0]:
			total += float(st.get("dmg_" + src, 0.0))
			dmg_parts.append("%s=%d" % [src, int(st.get("dmg_" + src, 0.0))])
		var counts := PackedStringArray()  # "stat=N" special counters.
		for key: String in rep[1]:
			counts.append("%s=%d" % [key, int(st.get(key, 0.0))])
		print("[autotest] class %s: Lv %d, alive %d/%d, deaths %d | dmg %d (%s) | %s" % [
			cls, int(game.horde.class_levels[cls]), game.horde.count_of(cls), game.horde.capacity(cls),
			int(_sum_prefix(st, "death_%s_by_" % cls)), int(total), " ".join(dmg_parts), " ".join(counts)])
	print("[autotest] class specials: cancelled by recall %d | ended inside an obstacle %d" % [
		int(st.get("summon_specials_cancelled", 0.0)), int(st.get("summon_special_end_blocked", 0.0))])


## Prints the Grave Step and Dread Rally lines (GDD §5.5 manual abilities).
## "est. +dmg part" is the share of the minion damage under the buff that
## its +RALLY_DAMAGE_BONUS damage multiplier added (attack speed not counted).
func _print_abilities(st: Dictionary) -> void:
	var gs := game.grave_step
	var dashes := float(st.get("dashes", 0.0))  # Steps taken.
	print("[autotest] grave step: dashes %d (bot: crowd %d, hit %d, telegraph %d) | hits avoided in dash i-frames %d | blocked %d, shortened by obstacles %d, ended inside an obstacle %d, avg length %.0f px | charges %d, cooldown %.2f s" % [
		int(dashes), int(st.get("bot_dash_crowd", 0.0)), int(st.get("bot_dash_hit", 0.0)), int(st.get("bot_dash_telegraph", 0.0)),
		int(st.get("dash_hits_avoided", 0.0)), int(st.get("dash_blocked", 0.0)), int(st.get("dash_shortened", 0.0)), int(st.get("dash_end_blocked", 0.0)),
		float(st.get("dash_distance", 0.0)) / maxf(dashes, 1.0), gs.max_charges, gs.cooldown])
	var dr := game.dread_rally
	var fills := PackedStringArray()  # Seconds each fill took.
	var total := 0.0  # Sum of the fill times.
	for t: float in dr.fill_times:
		fills.append("%.0f" % t)
		total += t
	var under := float(st.get("rally_minion_dmg", 0.0))  # Minion damage dealt under the buff.
	var bonus := PlayerAbilityData.RALLY_DAMAGE_BONUS  # Damage bonus share of that damage.
	print("[autotest] dread rally: rallies %d | meter fills %d, fill times s [%s] (avg %.0f s), meter now %d%% | knockbacks %d | summons called back %d | heal %d | minion dmg under buff %d (est. +dmg part %d) | buff time %.0f s" % [
		dr.rallies, dr.fill_times.size(), " ".join(fills), total / maxf(1.0, float(dr.fill_times.size())), int(dr.fraction() * 100.0),
		int(st.get("rally_knockbacks", 0.0)), int(st.get("rally_recalled", 0.0)), int(st.get("rally_heal", 0.0)),
		int(under), int(under * bonus / (1.0 + bonus)), float(st.get("rally_buff_time", 0.0))])
	if not game.ultimates.is_default():
		print("[autotest] ultimate: " + game.ultimates.summary_line(st))  # Content wave 2 (UltimateSystem).


## Special ids of the stage boss (from the boss once he arrived, else from
## the stage data) for the "boss attacks" line.
func _boss_special_ids() -> Array:
	if game.enemies.boss != null:
		return game.enemies.boss.special_ids()
	match String(game.stage_def["boss"]["id"]):
		"vael":
			return MarchEnemyData.VAEL_SPECIALS
		"seraphine":
			return SeraphineData.SPECIALS
	return EnemyData.SPECIALS


## Crimson March summary: zones, structures, new-enemy mechanics, Marshal
## Vael's body-blocking and stance counters, and the march event log.
func _print_march(st: Dictionary) -> void:
	var m := game.enemies.march
	var roles := PackedStringArray()  # "role placed/destroyed/escaped".
	for role: String in ["outpost", "generator", "cart", "standard"]:
		roles.append("%ss %d/%d/%d" % [role, int(st.get("march_%ss_placed" % role, 0.0)) if role != "standard" else int(st.get("boss_atk_standard", 0.0)),
			int(st.get("march_%ss_destroyed" % role, 0.0)), int(st.get("march_%ss_escaped" % role, 0.0))])
	print("[autotest] crimson march: zones entered %d (final: %s) | placed/destroyed/escaped: %s | outpost reinforcements %d | ward zones %d" % [
		int(st.get("march_zones_entered", 0.0)), m.zone_label(), " ".join(roles), int(st.get("march_outpost_reinforcements", 0.0)), int(st.get("holy_zones_ward", 0.0))])
	print("[autotest] march enemies: aura buff pulses %d | halberd cleave hits %d | dmg resisted: shieldbearer %d, boss %d | kills: shieldbearer=%d banner_bearer=%d halberdier=%d" % [
		int(st.get("march_aura_buff_pulses", 0.0)), int(st.get("march_cleave_hits", 0.0)), int(st.get("dmg_resisted_shieldbearer", 0.0)), int(st.get("dmg_resisted_boss", 0.0)),
		int(st.get("kill_shieldbearer", 0.0)), int(st.get("kill_banner_bearer", 0.0)), int(st.get("kill_halberdier", 0.0))])
	print("[autotest] marshal vael: last stand %s | cleave summon hits %d, soaked for the player %d | command soldiers %d" % [
		"yes" if st.has("boss_last_stand") else "no", int(st.get("boss_cleave_summon_hits", 0.0)), int(st.get("boss_cleave_soaked", 0.0)), int(st.get("boss_command_soldiers", 0.0))])
	print("[autotest] march events (%d): %s" % [m.fired.size(), ", ".join(m.fired)])


## Sanctum of Judgment kinds (SanctumEnemyData): printed only when one of
## them spawned this run (so every other run's summary is unchanged).
func _print_sanctum(st: Dictionary) -> void:
	var spawned := PackedStringArray()  # "kind=spawned/killed".
	var any := false  # A Sanctum kind spawned.
	for kind: String in SanctumEnemyData.ORDER:
		var n := int(st.get("spawned_" + kind, 0.0))
		any = any or n > 0
		spawned.append("%s=%d/%d" % [kind, n, int(st.get("kill_" + kind, 0.0))])
	if not any:
		return
	var i := func(key: String) -> int: return int(st.get(key, 0.0))
	print("[autotest] sanctum enemies (spawned/killed): %s | confessor revived soldiers killed: %d" % [" ".join(spawned), i.call("revived_killed")])
	print("[autotest] sanctum sentinel: sweeps %d (summon hits %d, player hits %d) | flat armour absorbed %d | player dmg from sweeps %d, summon dmg %d" % [
		i.call("sentinel_sweeps"), i.call("sentinel_sweep_summon_hits"), i.call("sentinel_sweep_player_hits"), i.call("flat_armor_absorbed_sanctified_sentinel"),
		i.call("player_dmg_from_sentinel_sweep"), i.call("summon_dmg_from_sentinel_sweep")])
	print("[autotest] sanctum inquisitor: holy zones %d, suppressions %d | suppression: replacements delayed %d, released %d, paused class-seconds %d, spawn spots blocked %d, minion dmg prevented %d | radiant bolt dmg to player %d, summons %d" % [
		i.call("inquisitor_zones"), i.call("inquisitor_suppressions"), i.call("suppression_replacements_delayed"), i.call("suppression_released"),
		i.call("suppression_paused_seconds"), i.call("suppression_spawns_blocked"), i.call("suppression_dmg_prevented"),
		i.call("player_dmg_from_radiant_inquisitor"), i.call("summon_dmg_from_radiant_inquisitor")])
	print("[autotest] sanctum confessor: heals %d (%d HP healed by all priests) | shields %d, absorbed %d, broken %d | revives started %d, done %d, cancelled %d, capped %d" % [
		i.call("high_confessor_heals"), i.call("enemy_healing"), i.call("confessor_shields"), i.call("holy_shield_absorbed"), i.call("holy_shields_broken"),
		i.call("confessor_revives_started"), i.call("confessor_revives"), i.call("confessor_revives_cancelled"), i.call("confessor_revives_capped")])
	print("[autotest] sanctum paladin: ward pulses %d, ward dmg prevented %d | charges (shared with templars) %d" % [
		i.call("paladin_ward_pulses"), i.call("paladin_ward_dmg_prevented"), i.call("templar_charges")])
	var ttk := float(st.get("guardian_ttk", 0.0)) / maxf(1.0, float(st.get("guardian_kills", 0.0)))  # Average time to kill (s).
	var mb := game.enemies.miniboss_alive()  # A Guardian still standing (null = none).
	print("[autotest] sanctum guardian: dmg taken %d (alive now: %s) | spawned %d, killed %d (avg time to kill %.1f s), chests %d | slams %d (summon hits %d, player hits %d, soaked %d) | beams %d (summon hits %d, player hits %d) | dmg to player %d, summons %d" % [
		int(_sum_prefix(st, "minibossdmg_")), "%d / %d HP" % [int(mb.hp), int(mb.max_hp)] if mb != null else "no",
		i.call("guardian_spawned"), i.call("guardian_kills"), ttk, i.call("miniboss_chests"), i.call("guardian_slams"), i.call("guardian_slam_summon_hits"),
		i.call("guardian_slam_player_hits"), i.call("guardian_slam_soaked"), i.call("guardian_beams"), i.call("guardian_beam_summon_hits"), i.call("guardian_beam_player_hits"),
		i.call("player_dmg_from_guardian_slam") + i.call("player_dmg_from_guardian_beam") + i.call("player_dmg_from_cathedral_guardian"),
		i.call("summon_dmg_from_guardian_slam") + i.call("summon_dmg_from_guardian_beam") + i.call("summon_dmg_from_cathedral_guardian")])


## Sister of the Scourge (BattleSisterData, BattleSisterKit): printed only
## when one spawned this run (so every other run's summary is unchanged).
func _print_battle_sister(st: Dictionary) -> void:
	var spawned := int(st.get("spawned_" + BattleSisterData.ID, 0.0))  # Sisters spawned.
	if spawned <= 0:
		return
	var i := func(key: String) -> int: return int(st.get(key, 0.0))
	var lashes := maxi(1, i.call("sister_lashes"))  # Lashes started (avoid / 0).
	print("[autotest] battle sister: spawned %d, killed %d | lashes %d (summon hits %d, player hits %d, %.2f bodies a lash) | zeal surges %d | lash dmg to player %d, summons %d (summons slain by it %d) | contact dmg to player %d, summons %d" % [
		spawned, i.call("kill_" + BattleSisterData.ID), i.call("sister_lashes"), i.call("sister_lash_summon_hits"), i.call("sister_lash_player_hits"),
		float(i.call("sister_lash_summon_hits") + i.call("sister_lash_player_hits")) / float(lashes), i.call("sister_zeal"),
		i.call("player_dmg_from_sister_lash"), i.call("summon_dmg_from_sister_lash"), int(_sum_suffix(st, "_by_sister_lash")),
		i.call("player_dmg_from_" + BattleSisterData.ID), i.call("summon_dmg_from_" + BattleSisterData.ID)])


## Prints the power-up drop / buff counters and the Profane Pact / Oath lines.
func _print_powerups(summary: Dictionary) -> void:
	var st: Dictionary = summary["stats"]  # Run counters.
	var spawned := PackedStringArray()  # "kind=n" drops spawned.
	var taken := PackedStringArray()  # "kind=n" drops collected.
	var expired := PackedStringArray()  # "kind=n" drops that despawned.
	var n_sp := 0  # Total drops spawned.
	var n_tk := 0  # Total drops collected.
	for kind: String in PowerupData.ORDER:
		n_sp += int(st.get("pu_spawned_" + kind, 0.0))
		n_tk += int(st.get("pu_collected_" + kind, 0.0))
		spawned.append("%s=%d" % [kind, int(st.get("pu_spawned_" + kind, 0.0))])
		taken.append("%s=%d" % [kind, int(st.get("pu_collected_" + kind, 0.0))])
		expired.append("%s=%d" % [kind, int(st.get("pu_expired_" + kind, 0.0))])
	print("[autotest] power-ups: spawned %d (%s) | collected %d (%s) | expired (%s) | lost at cap %d | pity drops %d | crystals pulled by Soul Magnet %d" % [
		n_sp, " ".join(spawned), n_tk, " ".join(taken), " ".join(expired), int(st.get("pu_lost_at_cap", 0.0)), int(st.get("pu_pity_drops", 0.0)),
		int(st.get("pu_magnet_crystals", 0.0))])
	var up := PackedStringArray()  # "buff=Ns (p% of the run)".
	var run_t := maxf(1.0, float(summary["time"]))  # Run length for the uptime %.
	for kind: String in PowerupData.TIMED:
		var t := float(st.get("pu_uptime_" + kind, 0.0))  # Seconds this buff ran.
		up.append("%s=%.0fs (%.1f%%, refreshed %d)" % [kind, t, t / run_t * 100.0, int(st.get("pu_refreshed_" + kind, 0.0))])
	print("[autotest] buff uptime: %s | soul nova kills: %d" % [" ".join(up), int(st.get("nova_kills", 0.0))])
	print("[autotest] chests: spawned %d, opened %d (x1=%d x3=%d x5=%d), items granted %d (evolutions %d), pity %d, lost at cap %d, left on ground %d" % [
		int(st.get("chests_spawned", 0.0)), int(st.get("chests_opened", 0.0)), int(st.get("chest_count_1", 0.0)), int(st.get("chest_count_3", 0.0)),
		int(st.get("chest_count_5", 0.0)), int(st.get("chest_items", 0.0)), int(st.get("chest_evolutions", 0.0)), int(st.get("chests_pity", 0.0)),
		int(st.get("chests_lost_at_cap", 0.0)), game.chests.active.size()])
	for line: String in game.chests.open_log:
		print("[autotest]    chest %s" % line)
	print("[autotest] chest beacon: %s" % game.chest_beacon.summary_line())  # Chest beacon (ChestBeacon; counted headless, never drawn).
	var ash: Dictionary = summary.get("soul_ash", {})  # Meta.award_run() breakdown.
	print("[autotest] profane pact: taken %s (final Lv %d; %s) | oath tier %d | extra XP from pact %d, from oath %d | extra soul ash from pact %d, from oath %d" % [
		"yes" if _pact_seen > 0 else "no", _pact_seen, " ".join(_pact_log) if not _pact_log.is_empty() else "never offered or never picked",
		int(summary.get("oath_tier", 0)), int(st.get("pact_bonus_xp", 0.0)), int(st.get("oath_bonus_xp", 0.0)),
		int(ash.get("pact_bonus", 0)), int(ash.get("oath_bonus", 0))])


## Ossuary deep levels: the run's upgrade levels against the whole Ossuary (the
## Profane Oath left out, like the profiles): levels owned, of them the gated
## ones (above MetaData.UNGATED_MAX_TIER), and their Soul Ash price.
func _print_ossuary_totals() -> void:
	var owned := 0  # Levels owned.
	var deep := 0  # Of them above level 5 (the difficulty-gated levels).
	var deep_total := 0  # Gated levels in the whole Ossuary.
	var cost := 0  # Soul Ash price of the owned levels.
	for id: String in MetaData.UPGRADE_ORDER:
		if id == PactData.OATH_ID:
			continue
		var t := int(game.meta.tiers.get(id, 0))  # This upgrade's level.
		owned += t
		deep += maxi(0, t - MetaData.UNGATED_MAX_TIER)
		deep_total += maxi(0, MetaData.max_tier(id) - MetaData.UNGATED_MAX_TIER)
		cost += MetaData.cost_up_to(id, t)
	var all_cost := MetaData.max_total_cost() - MetaData.cost_up_to(PactData.OATH_ID, MetaData.max_tier(PactData.OATH_ID))  # Whole Ossuary, Oath excluded.
	print("[autotest] ossuary: levels %d / %d owned (levels 6-10: %d / %d) | soul ash %d / %d" % [
		owned, MetaData.total_tiers(), deep, deep_total, cost, all_cost])


## Ossuary new options (expansion step 3): what each one did this run (only with
## upgrades, like the line above).
func _print_ossuary_options() -> void:
	var st := game.stats
	print("[autotest] ossuary options: bone reserve %d barrier HP | presence +%d%% (%d classes) | echoes from Lv %d | dark tithe +%.0f meter | last rites %d | grave ward %d blocked | gilded %d draws, %d swaps | elite bounty +%d ash | head start %d | vanguard %d | patient grave %d rerolls" % [
		int(st.get("bone_reserve_barrier", 0.0)), int(roundf(game.meta.value("presence_damage") * float(game.horde.distinct_classes()) * 100.0)),
		game.horde.distinct_classes(), maxi(1, VolleyData.LEVEL_ON - game.meta.int_value("echo_levels")),
		float(st.get("dark_tithe_points", 0.0)), int(st.get("last_rites_fired", 0.0)), int(st.get("grave_ward_blocks", 0.0)),
		int(st.get("gilded_draws", 0.0)), int(st.get("gilded_swaps", 0.0)),
		floori(float(st.get("elite_kills", 0.0)) * game.meta.value("elite_ash")), int(st.get("head_start_levels", 0.0)),
		int(st.get("vanguard_raises", 0.0)), int(st.get("patient_grave_rerolls", 0.0))])
## Ossuary Masteries (expansion step 4): the run's Mastery levels against all of them.
func _print_mastery_line() -> void:
	var levels := 0  # Mastery levels owned.
	var cost := 0  # Soul Ash price of the owned levels.
	for cls: String in MasteryData.CLASSES:
		var lv := int(game.meta.masteries.get(cls, 0))  # This class's level.
		levels += lv
		cost += MasteryData.cost_up_to(lv)
	print("[autotest] masteries: %d / %d levels owned | soul ash %d / %d | %s" % [
		levels, MasteryData.CLASSES.size() * MasteryData.MAX_LEVEL, cost, MasteryData.total_cost(), game.meta.describe_masteries()])


## Relics and Grave Offerings (GDD §15.0 "Relics and Grave Offerings"): what the
## run equipped and what the relic hooks did (rerolls from the Bone Abacus, Grave
## Feasts from Mourner's Bell, Gilded Coffer chests, extra active slots, the
## chest bonus, the meter's start and the max HP multiplier).
func _print_rites() -> void:
	var m := game.meta  # The bound (solo) player's modifiers.
	print("[autotest] rites: %s | active slots %d | chest +%d | meter start %d%%, charge x%.2f | max HP x%.2f | relic rerolls %d | relic feasts %d | offering chests %d" % [
		m.rites.describe(), game.abilities.active_slots(), m.relic_int("chest_bonus"),
		roundi(clampf(m.relic("ult_start"), 0.0, 1.0) * 100.0), game.dread_rally.charge_mult, m.relic("max_hp_mult"),
		int(game.stats.get("relic_rerolls", 0.0)), int(game.stats.get("relic_feasts", 0.0)), int(game.stats.get("offering_chests", 0.0))])


## Prints the meta profile and the run's Soul Ash award (Meta.award_run()).
func _print_soul_ash(summary: Dictionary) -> void:
	print("[autotest] meta upgrades (--meta=%s): %s | revivals used: %d" % [
		GameState.autotest_meta, game.meta.describe(), int(game.stats.get("revivals", 0.0))])
	if not game.meta.is_empty():
		_print_ossuary_totals()  # Only with upgrades: the default (--meta=none) summary keeps its lines.
		_print_ossuary_options()
	if not game.meta.masteries.is_empty():
		_print_mastery_line()  # Only with Masteries (--meta=max): the other summaries keep their lines.
	if not game.meta.rites.is_empty():
		_print_rites()  # Relics / offering only (the default summary keeps its lines).
	var ash: Dictionary = summary.get("soul_ash", {})
	if ash.is_empty():
		return
	var parts: Dictionary = ash["parts"]
	print("[autotest] soul ash: +%d (time %d [%s] + kills %d [%d] + elites %d [%d] + boss %d + reckoning %d [%.1f s]%s = %d, bonus +%d%% = +%d, pact +%d, oath +%d) | bounty %d | new total %d | saved: %s" % [
		int(ash["total"]), int(parts["time"]), _clock(float(ash["time_survived"])), int(parts["kills"]), int(ash["kill_count"]),
		int(parts["elites"]), int(ash["elite_count"]), int(parts["boss"]), int(parts["reckoning"]), float(ash["reckoning_seconds"]),
		" + objectives %d" % int(parts["objectives"]) if int(parts.get("objectives", 0)) > 0 else "",
		int(ash["subtotal"]), int(roundf(float(ash["bonus_pct"]) * 100.0)), int(ash["bonus"]), int(ash.get("pact_bonus", 0)), int(ash.get("oath_bonus", 0)),
		int(ash["bounty"]), int(ash["new_total"]), str(Meta.can_write())])
	var dif := game.difficulty
	print("[autotest] %s" % dif.summary_line())
	print("[autotest] difficulty results: soul ash difficulty %+d, modifiers +%d | trickle elites promoted: %d | holy retribution bursts: %d (dmg to you %d, to summons %d) | player max HP at start: %d" % [
		int(ash.get("difficulty_bonus", 0)), int(ash.get("modifiers_bonus", 0)), int(game.stats.get("elites_promoted", 0.0)),
		int(game.stats.get("holy_retribution_bursts", 0.0)), int(game.stats.get("player_dmg_from_holy_retribution", 0.0)),
		int(game.stats.get("summon_dmg_from_holy_retribution", 0.0)), int(_start_max_hp)])
	print("[autotest] stage: %s | soul ash stage bonus +%d (x%.2f) | stages unlocked by this run: %s" % [
		String(summary.get("stage_name", "")), int(ash.get("stage_bonus", 0)), 1.0 + float(ash.get("stage_pct", 0.0)),
		", ".join(ash.get("unlocked_stages", PackedStringArray())) if not (ash.get("unlocked_stages", PackedStringArray()) as PackedStringArray).is_empty() else "none"])


## Prints Hyper mode (HyperData) and the skin system (SkinData): the run's
## Hyper numbers and the 20:00 enemy multipliers vs the standard game, what
## the run unlocked (in memory only unless --meta-save), the worn skin and
## the skin counters, and builds the setup screen's Hyper / skin row once,
## headless, so that UI code runs in every autotest.
func _print_hyper_skins(summary: Dictionary) -> void:
	var dif := game.difficulty
	var pv := DifficultyModifiers.preview(dif.difficulty_id(), dif.modifier_ids(), dif.is_hyper())  # 20:00 multipliers vs standard.
	var ash: Dictionary = summary.get("soul_ash", {})
	print("[autotest] hyper: %s (%s) | foes: HP growth x%.2f, dmg growth x%.2f, boss HP x%.3f | at 0:00 vs the standard game: HP x%.2f, dmg x%.2f | soul ash hyper +%d (+%d%%) | Reckoning lasted %.1f s past 0:00 | unlocked: %s (by this run: %s) | hyper clear recorded: %s" % [
		"on" if dif.is_hyper() else "off", dif.difficulty_label(), dif.hp_scaling(), dif.damage_scaling(), dif.boss_hp_mult(),
		float(pv["enemy_hp_end"]), float(pv["enemy_damage_end"]), int(ash.get("hyper_bonus", 0)), roundi(float(ash.get("hyper_pct", 0.0)) * 100.0),
		float(summary["time_past_zero"]), str(Meta.hyper_unlocked), str(bool(ash.get("hyper_unlocked", false))),
		String(ash.get("hyper_clear", "")) if String(ash.get("hyper_clear", "")) != "" else "no"])
	var st: Dictionary = summary["stats"]
	var skin := String(summary.get("skin_id", ""))  # Worn skin ("" = default).
	var key := String(SkinData.skin(skin).get("sprite", "")) if skin != "" else ""  # Its sprite key.
	var row_cfg := RunConfig.for_stage(String(summary["stage_id"]))  # Throwaway config for the UI check.
	var row := PreRunHyperSkins.new()  # The setup screen's Hyper / skin row.
	row.config = row_cfg
	add_child(row)
	var cards := row.cards().size()  # Cards built (Hyper + skins).
	row.queue_free()
	var new_skins: PackedStringArray = ash.get("unlocked_skins", PackedStringArray())
	print("[autotest] skins: character %s, worn %s%s | this run: rot kills %d, high confessors slain %d, seraphine slain with all 4 roles %d | lifetime: rot %d/5000, confessors %d/50, seraphine full army %d/1 | unlocked %d/%d (new: %s) | setup row cards %d" % [
		String(summary.get("character_id", CharacterData.DEFAULT_ID)), skin if skin != "" else "default",
		(" (art %s: %s)" % [key, "yes" if SpriteBank.has(key) else "no, palette fallback"]) if skin != "" else "",
		int(st.get("rot_kills", 0.0)), int(st.get("kill_high_confessor", 0.0)), 1 if float(st.get("boss_kill_full_army", 0.0)) > 0.0 and String(summary.get("boss_id", "")) == HyperData.UNLOCK_BOSS_ID and bool(summary["boss_defeated"]) else 0,
		int(float(Meta.lifetime.get("rot_kills", 0.0))), int(float(Meta.lifetime.get("high_confessor_kills", 0.0))), int(float(Meta.lifetime.get("seraphine_kills_full_army", 0.0))),
		Meta.unlocked_skin_ids().size(), SkinData.all_ids().size(), ", ".join(new_skins) if not new_skins.is_empty() else "none", cards])
	var rc := String(summary.get("recolour_id", ""))  # Worn skin recolour ("" = none; the line only prints when one is forced, so default runs print nothing new).
	if rc != "":
		var rkey := String(SkinData.skin(skin).get("sprite", "")) if skin != "" else SkinData.base_sprite(String(summary.get("character_id", CharacterData.DEFAULT_ID)))  # Sprite remapped.
		var rtex := SpriteBank.texture(rkey)  # The original art (null without it).
		var rre := Recolour.texture(rtex, rkey, rc) if rtex != null else null  # The recoloured art.
		print("[autotest] recolours: %s (%d Soul Ash) worn on %s | art %s: %s | %d recolours x %d skins, %d Soul Ash a skin" % [
			RecolourData.display_name(rc), RecolourData.price(rc), skin if skin != "" else "the default look", rkey,
			"remapped" if rre != null and rre != rtex else "no art, drawn unchanged", RecolourData.ORDER.size(), SkinData.all_ids().size(), RecolourData.price_per_skin()])


## Shadow Bolt damage stat with `prefix` ("dmg_" / "bossdmg_"), including the
## Void Barrage bolts and shards.
static func _bolt_damage(st: Dictionary, prefix: String) -> float:
	var total := 0.0
	for src: String in ["bolt", "void", "void_shard"]:
		total += float(st.get(prefix + src, 0.0))
	return total


## Sum of every stat whose key starts with `prefix`.
static func _sum_prefix(st: Dictionary, prefix: String) -> float:
	var total := 0.0
	for k: String in st.keys():
		if k.begins_with(prefix):
			total += float(st[k])
	return total


## Sum of every stat whose key ends with `suffix` (e.g. "death_*_by_<source>").
static func _sum_suffix(st: Dictionary, suffix: String) -> float:
	var total := 0.0
	for k: String in st.keys():
		if k.ends_with(suffix):
			total += float(st[k])
	return total


## Formats seconds as mm:ss.
static func _clock(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [floori(float(s) / 60.0), s % 60]


## The "epilogue" summary line (content wave 2: E. Illustrated epilogue):
## parts, how many are open and seen in the save, panels and whether an open,
## unseen part would autoplay. Reads EpilogueData and Meta only.
func _epilogue_line() -> String:
	var opened := 0  # Parts the save has opened (their achievement earned).
	var seen := 0  # Parts already shown once.
	var pending := 0  # Open parts not yet seen (they autoplay on the return to the menu).
	var panels := 0  # Picture panels across all parts.
	for part: Dictionary in EpilogueData.PARTS:
		panels += (part["panels"] as Array).size()
		var id := String(part["id"])  # The part's [epilogue] seen_<id> key.
		if EpilogueData.is_open(part):
			opened += 1
			if Meta.is_epilogue_seen(id):
				seen += 1
			else:
				pending += 1
	return "parts=%d open=%d seen=%d panels=%d autoplay_pending=%s" % [EpilogueData.PARTS.size(), opened, seen, panels, pending > 0]
