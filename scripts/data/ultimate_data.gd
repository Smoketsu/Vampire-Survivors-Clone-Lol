## UltimateData — designer data for the necromancer's ULTIMATES (content wave 2,
## owner-approved Proposal 4 "More ultimates"; GDD §15.0 "Ultimates (content
## wave 2)"). Every ultimate uses the ONE soul meter (DreadRally: 240 points,
## PlayerAbilityData.KILLS_TO_FILL), the ONE action `ultimate` (Space / pad LB /
## the touch button) and the ONE HUD slot; the run's choice is
## RunConfig.ultimate_id (picked on the pre-run setup screen under the
## character and skin, remembered in the Meta save [prerun] ultimate, kept by
## Restart; any character). Dread Rally stays the default, always open, and its
## numbers stay in PlayerAbilityData (unchanged). The three new ones run in
## UltimateSystem (scripts/player/ultimate_system.gd); locks are asked through
## Unlocks.is_open(id) (UnlockData rows belong to the achievement rewards; an id
## without a row is open).
## Owner guardrails: same meter cost for all four; none may beat Dread Rally's
## measured value (autotest --ultimate=, an A/B batch on deaths, min HP and boss
## kill time); no freeze or stun on bosses; Grave Tide never raises a boss,
## miniboss, Reckoning enemy or structure; every effect through the existing
## single paths. Data only, no logic.
class_name UltimateData
extends RefCounted

## Ultimate ids in picker order (Dread Rally first: the default).
const ORDER := ["dread_rally", "sovereigns_decree", "eclipse", "grave_tide"]  # owner-approved Proposal 4
## The default ultimate (RunConfig, fresh saves, the autotest): Dread Rally.
const DEFAULT_ID: String = "dread_rally"  # owner-approved Proposal 4

## Ultimate id -> picker / HUD row:
##   display_name — UI name.
##   short        — one word for the hint chips ("Rally").
##   tagline      — the picker's one line (few words).
##   description  — the full effect (tooltip, detail line).
##   pick         — when it is the right pick (picker detail line).
##   icon         — icon key (assets/sprites/icons/<icon>.png, else the
##                  UltimateGlyphs / AbilityGlyphs code drawing).
##   anim         — burst effect strip id (AnimData; drawn rings without it).
##   sound        — cast sound id (SoundData.SOUNDS, synthesized).
##   color        — accent colour of the burst rings, overlay and icon fallback
##                  (player violet, or soul teal for the rising undead; never
##                  Covenant gold or crimson, ART_BIBLE colour language).
const ULTIMATES := {
	"dread_rally": {"display_name": "Dread Rally", "short": "Rally", "tagline": "Raise and rally the army",
		"description": "Raises every fallen summon, heals the army 30%, +40% damage and attack speed for 8 s, knocks foes back.",
		"pick": "All-rounder: rescues a broken army.",
		"icon": "dread_rally", "anim": "dread_rally", "sound": "death_nova", "color": Color(0.48, 0.26, 0.68)},  # owner-approved Proposal 4 (today's ultimate)
	"sovereigns_decree": {"display_name": "Sovereign's Decree", "short": "Decree", "tagline": "Your dead take the blows",
		"description": "For 8 s every summon taunts foes near it and takes 50% less damage; you cannot be targeted.",
		"pick": "Bosses and swarms that dive you.",
		"icon": "sovereigns_decree", "anim": "sovereigns_decree", "sound": "ult_decree", "color": Color(0.64, 0.36, 0.98)},  # owner-approved Proposal 4
	"eclipse": {"display_name": "Eclipse", "short": "Eclipse", "tagline": "Darkness stops the world",
		"description": "Darkness for 4 s: every foe on screen freezes (bosses are slowed 60%), then takes +30% damage for 6 s.",
		"pick": "Emergency brake when surrounded.",
		"icon": "eclipse", "anim": "eclipse", "sound": "ult_eclipse", "color": Color(0.87, 0.74, 1.0)},  # owner-approved Proposal 4
	"grave_tide": {"display_name": "Grave Tide", "short": "Tide", "tagline": "The slain rise for you",
		"description": "For 10 s every foe that dies rises as a Risen fighting for you for 12 s.",
		"pick": "Snowballing big waves into an army.",
		"icon": "grave_tide", "anim": "grave_tide", "sound": "ult_tide", "color": Color(0.24, 0.80, 0.58)},  # owner-approved Proposal 4
}

# --- Sovereign's Decree --------------------------------------------------------------

## Seconds the Decree runs (taunt, damage cut, untargetable necromancer).
const DECREE_DURATION: float = 8.0  # owner-approved Proposal 4 "for 8 s"
## Taunt reach (px) of every living summon while the Decree runs: an enemy whose
## centre is within it targets the nearest such summon (Enemy._pick_target()
## through UltimateSystem.taunt_target(); bosses, Reckoning enemies and
## structures ignore it, like the Bone Colossus taunt).
const DECREE_TAUNT_RADIUS: float = 150.0  # TUNING (not in GDD)
## Fraction (0..1) of every hit on a summon removed while the Decree runs
## (CombatResolver.damage_unit(), its own category; stat decree_dmg_prevented).
const DECREE_DAMAGE_REDUCTION: float = 0.5  # owner-approved Proposal 4 "takes 50% less damage"
## True: while the Decree runs the necromancer cannot be targeted: enemies
## retarget summons (the taunt) and every hit that still reaches him (a
## projectile already in flight, a boss attack, a stage hazard) is ignored in
## CombatResolver.damage_player() before any other rule (stat
## decree_player_hits_ignored / decree_player_dmg_prevented).
const DECREE_UNTARGETABLE: bool = true  # owner-approved Proposal 4
## Radius (px) of the Decree's burst rings around the necromancer.
const DECREE_RING_RADIUS: float = 150.0  # TUNING (not in GDD) cosmetic
## Seconds of the drawn burst rings without the strip (with art, AnimData's duration).
const DECREE_RING_TIME: float = 0.6  # TUNING (not in GDD) cosmetic
## Screen shake request (px) of the Decree burst.
const DECREE_SHAKE: float = 6.0  # TUNING (not in GDD) cosmetic
## Opacity (0..1) the necromancer is drawn at while untargetable (visual only).
const DECREE_PLAYER_ALPHA: float = 0.55  # TUNING (not in GDD) cosmetic

# --- Eclipse -------------------------------------------------------------------------

## Seconds of darkness: every enemy on screen is held (frozen) that long.
const ECLIPSE_DARK_DURATION: float = 4.0  # owner-approved Proposal 4 "darkness for 4 s"
## Half extent (px) of "on screen": the 1280 x 720 layout at Normal zoom around
## the necromancer, plus a small margin. Fixed (not the live camera), so a zoom
## setting never changes gameplay.
const ECLIPSE_HALF_VIEW: Vector2 = Vector2(680.0, 400.0)  # TUNING (not in GDD)
## Freeze share of an elite (1 = the full darkness).
const ECLIPSE_ELITE_MULT: float = 1.0  # TUNING (not in GDD)
## Bosses and minibosses are never frozen or stunned (owner guardrail): they are
## slowed by this fraction for the darkness instead (CombatResolver.slow_enemy()).
const ECLIPSE_BOSS_SLOW: float = 0.6  # owner-approved Proposal 4 "slowed 60% instead"
## After the darkness, every enemy it caught that is still alive takes this
## fraction more damage from every source (CombatResolver.expose_enemy(), the
## one Eclipse debuff; stat eclipse_bonus_dmg).
const ECLIPSE_EXPOSE_AMP: float = 0.3  # owner-approved Proposal 4 "+30% damage"
## Seconds the exposure lasts (before Mournsong, which lengthens it like every
## weakening effect).
const ECLIPSE_EXPOSE_DURATION: float = 6.0  # owner-approved Proposal 4 "for 6 s"
## Share (0..1) of the exposure on bosses and minibosses. 1 = the full +30%, as
## the owner's proposal words it (A/B batch: at 0.5 the Eclipse failed 3 of 4
## Archivist fights while Dread Rally won all 4; bosses are only slowed by the
## darkness, never held, so the exposure is the Eclipse's one boss tool).
const ECLIPSE_EXPOSE_BOSS_MULT: float = 1.0  # TUNING (not in GDD)
## Seconds (0..ECLIPSE_DARK_DURATION) before the darkness ends that the
## exposure already starts. 0 = the proposal's wording (exposed only after the
## darkness); ECLIPSE_DARK_DURATION = frozen foes are exposed from the cast, so
## the army cashes in on the sitting ducks (A/B batch: without it the Eclipse
## starved for kills in the Archive and lost 2 of 4 runs Dread Rally won).
const ECLIPSE_EXPOSE_LEAD: float = 4.0  # TUNING (not in GDD)
## Peak opacity (0..1) of the darkness overlay (visual only).
const ECLIPSE_OVERLAY_ALPHA: float = 0.45  # TUNING (not in GDD) cosmetic
## Radius (px) of the Eclipse burst rings.
const ECLIPSE_RING_RADIUS: float = 220.0  # TUNING (not in GDD) cosmetic
## Seconds of the drawn burst rings without the strip.
const ECLIPSE_RING_TIME: float = 0.7  # TUNING (not in GDD) cosmetic
## Screen shake request (px) of the Eclipse burst.
const ECLIPSE_SHAKE: float = 7.0  # TUNING (not in GDD) cosmetic

# --- Grave Tide ----------------------------------------------------------------------

## Seconds the Tide runs: every enemy that dies meanwhile rises for the necromancer.
const TIDE_DURATION: float = 10.0  # owner-approved Proposal 4 "for 10 s"
## Base life (s) of a Tide Risen (HordeDirector.spawn_temporary(): Restless Dead
## and the Grave Herald's Restless innate lengthen it there).
const TIDE_RISEN_LIFE: float = 12.0  # owner-approved Proposal 4 "lasts 12 s"
## Summon class of a Tide Risen (the shared AI; drawn as a Risen glyph).
const TIDE_RISEN_CLASS: String = "warrior"  # TUNING (not in GDD) like Death Mark's Risen
## Max HP multiplier of a Tide Risen (on the class's current stats).
const TIDE_RISEN_HP: float = 0.5  # TUNING (not in GDD)
## Damage multiplier of a Tide Risen (on the class's current stats).
const TIDE_RISEN_DAMAGE: float = 0.6  # TUNING (not in GDD)
## Most Tide Risen alive at once (more deaths are counted as capped), so the
## pools never explode in a big wave.
const TIDE_MAX_ALIVE: int = 24  # TUNING (not in GDD)
## Most Tide Risen raised in one physics tick (the rest wait in the queue).
const TIDE_RAISES_PER_TICK: int = 4  # TUNING (not in GDD)
## Most deaths waiting to rise (older ones beyond it are dropped as capped).
const TIDE_QUEUE_MAX: int = 32  # TUNING (not in GDD)
## Radius (px) of the Tide burst rings.
const TIDE_RING_RADIUS: float = 170.0  # TUNING (not in GDD) cosmetic
## Seconds of the drawn burst rings without the strip.
const TIDE_RING_TIME: float = 0.65  # TUNING (not in GDD) cosmetic
## Screen shake request (px) of the Tide burst.
const TIDE_SHAKE: float = 6.0  # TUNING (not in GDD) cosmetic
## Peak opacity (0..1) of the Tide's green edge mist (visual only).
const TIDE_OVERLAY_ALPHA: float = 0.28  # TUNING (not in GDD) cosmetic

# --- Pre-run picker (PreRunUltimates) -------------------------------------------------

## One ultimate tile of the pre-run picker (px; four fill the hero panel's text width).
const PICKER_TILE: Vector2 = Vector2(86.0, 42.0)  # TUNING (not in GDD)
## Icon box (px) inside a picker tile (the 32 px badge art, 1:1).
const PICKER_ICON: float = 32.0  # TUNING (not in GDD)
## Gap (px) between two picker tiles.
const PICKER_GAP: int = 6  # TUNING (not in GDD)
## Lines of the picker's detail text kept free (a lock condition wraps to two).
const PICKER_DETAIL_LINES: int = 2  # TUNING (not in GDD)
## Lock line of an ultimate whose UnlockData row gives no text.
const PICKER_LOCKED_TEXT: String = "Earned by an achievement."  # TUNING (not in GDD)
