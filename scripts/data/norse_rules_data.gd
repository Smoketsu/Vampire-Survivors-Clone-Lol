## NorseRulesData — immutable numbers of THE HALL OF THE SLAIN's shared rules
## (the Norse act, temporarily Act XI, final slot VI; GDD §15.0 "The Hall of
## the Slain foundation (phase 1)", "The Long Winter", "Berserkergang",
## "Rune-Stones" and "Ragnarök"; the act's section "VI. The Hall of the Slain"
## of docs/proposals/LAST_SIX_ACTS.md, owner go-ahead Nov 7, 2026), read by
## NorseRules (Game.norse) and its parts:
##   LONG_WINTER  — LongWinter (the first rule; owner decision Nov 7, 2026,
##                  replacing the Choosing): the cold rises with the clock;
##                  outside a lit brazier's warmth the necromancer's side is
##                  slowed and bitten; frost giants and seers douse braziers,
##                  the necromancer relights them.
##   EINHERJAR    — the gold-lit heroes of the hall (NorseKit.make_einherjar()).
##   BERSERK      — Berserkergang: below a share of its HP a Norse warrior
##                  goes berserk (Enemy.berserk, the one enemy stat).
##   RUNE_STONES  — RuneStones: the capturable stones, their ward, their horn,
##                  the capture, the seers' re-carving, their squads.
##   RAGNAROK     — Ragnarok: the act's Reckoning (RECKONING "ragnarok").
##   SOUNDS       — event -> sound id map (one place to switch the Norse pack
##                  in once the audio pass has made it).
## A stage's STAGE "long_winter" / "rune_stones" dictionaries and its RECKONING
## "ragnarok" override any key here ({} = these defaults).
## Data only (CLAUDE.md rule 2). The proposal's own numbers are marked as such;
## every other number is TUNING (not in GDD), tuned for the act's FINAL slot VI
## (the Shogunate / Olympus level, docs/last_acts/PLAN.md).
class_name NorseRulesData
extends RefCounted

# --- Groups (row key "group"; the Codex and the report group by it) ------------------------

## Group ids in Codex / report order: the warriors of the hall
## (Berserkergang reads the row key "warrior"), the hall's valkyries and seers
## (and its stones and braziers), and the cold things of the north (draugr,
## wolves, giants).
const GROUPS: Array[String] = ["warriors", "hall", "wilds"]

# --- The Long Winter (LongWinter; the act's first rule) -----------------------------------

## The Long Winter's numbers (owner decision Nov 7, 2026: the first rule,
## replacing the Choosing; a stage's STAGE "long_winter" overrides any key):
##   step_every     — s of the 20:00 clock per cold level (level 0 at the start).
##   max_level      — the coldest level.
##   slow_by_level  — slow share of the necromancer and every summon OUT OF
##                    WARMTH at levels 0..max_level (through TerrainSlow, the
##                    one ground-slow path).
##   bite_by_level  — frostbite: share of a summon's max HP lost per s out of
##                    warmth at levels 0..max_level (CombatResolver.damage_unit(),
##                    FROSTBITE_SOURCE).
##   tick           — s between two cold checks (the slow lingers a tick).
##   warm_radius    — px around a lit brazier that is warm.
##   brazier_radius — px: a brazier's body (drawing and placement).
##   douse_radius   — px: a frost giant or seer passing this close douses it.
##   douse_seek     — px: a douser this close to a lit brazier turns aside to
##                    it (NorseKit.douse_step(): it passes by on purpose).
##   douse_time     — s of the douse's telegraph (the fire gutters; the douser
##                    must stay within douse_radius*1.5 or it holds).
##   relight_radius — px: the necromancer standing this close relights it.
##   relight_time   — s of standing there to relight it.
##   relight_decay  — s of progress lost per s while nobody stands there.
##   ash_per_relight — Soul Ash a relight pays (the objective bounty path).
##   ash_relights_max — relights that pay (later relights pay nothing).
##   count          — braziers placed at the start (a ring around the start).
##   ring_min / ring_max — px from the start the braziers stand.
##   placement_tries — positions tried per brazier (seeded).
##   frost_px       — px of the frost vignette's band at the coldest level
##                    (drawing only).
const LONG_WINTER := {
	"step_every": 300.0,  # Owner decision Nov 7, 2026: "about +1 step every 5:00"
	"max_level": 3,  # Owner decision: "3 steps max"
	"slow_by_level": [0.0, 0.1, 0.2, 0.3],  # Owner decision: "about 10% / 20% / 30%"
	"bite_by_level": [0.0, 0.0, 0.005, 0.01],  # Owner decision: "at level 2+ ... about 0.5% / 1% max HP per s"
	"tick": 0.5,  # TUNING (not in GDD) s
	"warm_radius": 220.0,  # Owner decision: "within ~220 px of a lit brazier"
	"brazier_radius": 12.0,  # TUNING (not in GDD) px (~32 px sprite)
	"douse_radius": 40.0,  # TUNING (not in GDD) px
	"douse_seek": 170.0,  # TUNING (not in GDD) px
	"douse_time": 1.2,  # TUNING (not in GDD) s ("a brief telegraph")
	"relight_radius": 60.0,  # Owner decision: "within ~60 px"
	"relight_time": 2.0,  # Owner decision: "for 2 s"
	"relight_decay": 1.0,  # TUNING (not in GDD) s/s
	"ash_per_relight": 5.0,  # TUNING (not in GDD) owner: "small"
	"ash_relights_max": 6,  # TUNING (not in GDD)
	"count": 6,  # Owner decision: "about 6 brazier structures"
	"ring_min": 260.0,  # TUNING (not in GDD) px
	"ring_max": 900.0,  # TUNING (not in GDD) px
	"placement_tries": 6,  # TUNING (not in GDD)
	"frost_px": 150.0,  # TUNING (not in GDD) px, visual only
}
## Fur-Lined Bones, the act's counter-passive (owner decision Nov 7, 2026:
## "the cold slows summons half as much"; NOT built in phase 1: its PassiveData
## id and value key, read by LongWinter.fur_mult(), exactly 1 while no row
## exists).
const FUR_LINED_BONES: String = "fur_lined_bones"
## Fur-Lined Bones' value key: share (0..1) of the cold's slow on summons cut.
const FUR_KEY: String = "cold_slow_cut"
## Keep the Fires, the act's achievement (owner decision Nov 7, 2026: "finish
## the Barrow Fields with no brazier ever out for more than 30 s"; phase 2
## builds it on LongWinter.longest_out()): the longest outage allowed (s).
const KEEP_THE_FIRES_MAX_OUT: float = 30.0  # Owner decision Nov 7, 2026
## Damage tag of the frostbite tick on a summon out of warmth.
const FROSTBITE_SOURCE: String = "frostbite"
## Kind id of a brazier (a structure row in NorseEnemyData for the Codex and
## --spawn=; LongWinter draws and runs every brazier itself).
const BRAZIER_KIND: String = "brazier"
## Sprite key of a lit brazier (the art pass's brazier_lit; wired at the wave 1 integration).
const BRAZIER_SPRITE: String = "norse/brazier_lit"
## Sprite key of a doused (cold) brazier (the art pass's brazier_doused).
const BRAZIER_OUT_SPRITE: String = "norse/brazier_doused"
# --- Act XI (temporary): the Barrow Fields --- (the art round 2's brazier loops)
## Suffix of a brazier sprite's animated strip (norse/brazier_lit_anim,
## norse/brazier_doused_anim: BRAZIER_ANIM_FRAMES frames of 32 x 32 side by
## side, frame 0 = the still; LongWinter draws them, the stills the fallback).
const BRAZIER_ANIM_SUFFIX: String = "_anim"
## Frames in a brazier's animated strip.
const BRAZIER_ANIM_FRAMES: int = 8  # Art round 2 (docs/norse/ART_MANIFEST.md)
## Frames a second of a brazier's loop (on game time).
const BRAZIER_ANIM_FPS: float = 8.0  # Art round 2 (docs/norse/ART_MANIFEST.md)
## Frost vignette colour (drawing only; a flat tinted band, no screen read).
const FROST_TINT: Color = Color(0.82, 0.92, 1.0, 0.55)  # TUNING (not in GDD) visual only
## Sprite key of the frost edge laid over the vignette's bands (a 128 x 48 strip,
## tileable along x, its frost edge on the top row; rotated per screen edge).
## A missing PNG leaves the plain gradient bands (wired at the wave 1 integration).
const FROST_SPRITE: String = "norse/frost_creep"
## Opacity of the frost edge strip over the bands, 0-1 (drawing only).
const FROST_SPRITE_ALPHA: float = 0.85  # TUNING (not in GDD) visual only

# --- The Einherjar (NorseKit.make_einherjar()) ----------------------------------------------

## An Einherjar's numbers: x max HP, damage and move speed on top of the elite's
## (Ragnarök's march; phase 2's Feast and Sigrun's Doors of the Hall).
const EINHERJAR := {
	"hp": 1.35,  # TUNING (not in GDD)
	"damage": 1.25,  # TUNING (not in GDD)
	"speed": 1.1,  # TUNING (not in GDD)
}

# --- Berserkergang (Enemy.berserk) ----------------------------------------------------------

## Berserkergang's numbers:
##   threshold — share of its max HP below which a Norse warrior goes berserk
##               (for good: the fury does not end).
##   speed     — + share of move speed while berserk.
##   damage    — + share of damage while berserk.
const BERSERK := {
	"threshold": 0.4,  # Owner-approved proposal: "below 40% health"
	"speed": 0.3,  # Owner-approved proposal: "+30% speed and damage"
	"damage": 0.3,  # Owner-approved proposal
}

# --- Rune-Stones (RuneStones) ---------------------------------------------------------------

## The Rune-Stones' numbers:
##   body_radius   — px: the stone's size (drawing and placement).
##   ward_radius   — px: Norse warriors within it of a stone the hall holds
##                   take ward_taken of every hit.
##   ward_taken    — share of a hit a warded Norse enemy takes.
##   horn_first    — s after a stone rises before its first horn.
##   horn_every    — s between two horns of a held stone.
##   horn_reach    — px: a stone blows its horn only while a necromancer is
##                   this close (no off-screen flood).
##   capture_radius — px: the ring the necromancer must stand in.
##   capture_time  — s with more bodies than the hall inside to take it.
##   capture_decay — s of progress lost per s while the condition fails.
##   ash_per_take  — Soul Ash a stone pays the FIRST time it is taken (the
##                   objective bounty path; a re-take pays nothing).
##   carve_radius  — px: a seer this close to a taken stone re-carves it.
##   carve_time    — s of seers carving to give a stone back to the hall.
##   carve_seek    — px: a seer walks to a taken stone this close to her
##                   (else she advances like every enemy).
##   max_stones    — stones standing at once (a new one past it is refused).
##   dist_min / dist_max — px from the necromancer a timeline stone rises.
##   spacing       — px kept between two stones.
##   placement_tries — positions tried per stone (seeded).
##   cap_margin    — a horn skips its squad while fewer than this many enemies
##                   are left under the hard cap.
##   squad_spread  — px from the stone's centre a squad appears.
##   table         — the horn's squads: rows {kind, count, weight[, elite]}
##                   (a seeded weighted pick).
const RUNE_STONES := {
	"body_radius": 16.0,  # TUNING (not in GDD) px (~40 px sprite)
	"ward_radius": 300.0,  # Owner-approved proposal: "wards Norse warriors within 300 px"
	"ward_taken": 0.75,  # Owner-approved proposal: "(-25% damage taken)"
	"horn_first": 12.0,  # TUNING (not in GDD) s
	"horn_every": 60.0,  # Owner-approved proposal: "calls a squad every 60 s"
	"horn_reach": 900.0,  # TUNING (not in GDD) px (as the Inferno's portals)
	"capture_radius": 120.0,  # Owner-approved proposal: "standing within 120 px"
	"capture_time": 3.0,  # Owner-approved proposal: "for 3 s"
	"capture_decay": 1.0,  # TUNING (not in GDD) s/s
	"ash_per_take": 20.0,  # TUNING (not in GDD) (a sealed portal 20, a siege tower 25)
	"carve_radius": 44.0,  # TUNING (not in GDD) px
	"carve_time": 5.0,  # TUNING (not in GDD) s
	"carve_seek": 720.0,  # TUNING (not in GDD) px
	"max_stones": 4,  # Owner-approved proposal: "Three or four carved stones per stage"
	"dist_min": 260.0,  # TUNING (not in GDD) px
	"dist_max": 420.0,  # TUNING (not in GDD) px
	"spacing": 340.0,  # TUNING (not in GDD) px
	"placement_tries": 6,  # TUNING (not in GDD)
	"cap_margin": 8,  # TUNING (not in GDD)
	"squad_spread": 40.0,  # TUNING (not in GDD) px
	"table": [
		{"kind": "raider", "count": 5, "weight": 0.5},  # TUNING (not in GDD) a raiding party
		{"kind": "shield_maiden", "count": 3, "weight": 0.3},  # TUNING (not in GDD) a shield line
		{"kind": "berserker", "count": 1, "weight": 0.2},  # TUNING (not in GDD) one berserker
	],
}
## Dots of a stone's capture ring (drawn with disc textures).
const CAPTURE_DOTS: int = 24  # TUNING (not in GDD) visual only
## Kind id of a Rune-Stone (a structure row in NorseEnemyData for the Codex and
## --spawn=; RuneStones draws and runs every stone itself).
const STONE_KIND: String = "rune_stone"
## Sprite key of a stone the hall holds, and of a taken one (dark runes).
const STONE_SPRITE: String = "norse/rune_stone"
## Sprite key of a taken (dead) stone.
const STONE_TAKEN_SPRITE: String = "norse/rune_stone_taken"

# --- Ragnarök (Ragnarok; the act's Reckoning) -----------------------------------------------

## Ragnarök's numbers (RECKONING "ragnarok" overrides any of them):
##   tint          — the dark red wash over the view (multiplied: white = none).
##   fade          — s the wash takes to come in.
##   einherjar     — Einherjar of the hall that march out at 0:00 (heroes of
##                   einherjar_kinds in turn, elites made gold by
##                   NorseKit.make_einherjar()).
##   einherjar_kinds — the warrior kinds they are, in turn.
##   giant_kind    — the fire-giants' kind.
##   giants        — fire-giants per march out of the south edge.
##   giant_every   — s between two marches (the first at 0:00).
##   giant_spread  — px between two giants of a march.
##   dive_every_mult — x every valkyrie's dive cooldown while Ragnarök runs
##                   (every valkyrie dives at the ring).
const RAGNAROK := {
	"tint": Color(0.86, 0.46, 0.42),  # TUNING (not in GDD) dark red
	"fade": 3.0,  # TUNING (not in GDD) s
	"einherjar": 8,  # TUNING (not in GDD) "the Einherjar of the hall march"
	"einherjar_kinds": ["raider", "shield_maiden", "raider", "berserker"],  # TUNING (not in GDD)
	"giant_kind": "fire_giant",  # Owner-approved proposal: "fire-giants step out of the south edge"
	"giants": 2,  # TUNING (not in GDD)
	"giant_every": 30.0,  # TUNING (not in GDD) s
	"giant_spread": 90.0,  # TUNING (not in GDD) px
	"dive_every_mult": 0.35,  # TUNING (not in GDD) "every valkyrie dives at the ring"
}

# --- Damage sources -------------------------------------------------------------------------

## Damage tag of a valkyrie's spear dive (summons and the necromancer).
const DIVE_SOURCE: String = "valkyrie_dive"
## Damage tag of a frost giant's boulder.
const BOULDER_SOURCE: String = "giant_boulder"
## Damage tag of a giant's stomp.
const STOMP_SOURCE: String = "giant_stomp"
## Damage tag of a shield-maiden's shield bash.
const BASH_SOURCE: String = "maiden_bash"
## Damage tag of a wolf's lunge.
const LUNGE_SOURCE: String = "wolf_lunge"
## Ranged damage tags of the Norse (a future counter-passive may read them).
const RANGED_SOURCES: Array[String] = [BOULDER_SOURCE]

# --- Sounds ---------------------------------------------------------------------------------

## Norse event -> sound id: the Norse pack (SoundData.NORSE_SOUNDS, rendered
## lazily with the "valhall" music; wired at the wave 1 integration) where it
## has one, else a startup-bank sound (other acts' packs are not rendered on a
## Norse stage). An id that is not rendered is skipped silently by Sfx.play().
const SOUNDS := {
	"valkyrie_dive": "valkyrie_dive",  # Norse pack: a war cry and a rush of wings.
	"einherjar_march": "einherjar_rise",  # Norse pack: the Einherjar of the hall march out.
	"brazier_douse": "deep_freeze",  # Startup bank (a cold crack); intended a fire hissing out under snow (not in the Norse pack yet).
	"brazier_relight": "pu_feast",  # Startup bank (a warm swell); intended a fire catching (not in the Norse pack yet).
	"cold_rises": "deep_freeze",  # Startup bank; intended a rising icy wind (not in the Norse pack yet).
	"berserk": "berserk_roar",  # Norse pack: a bear-like roar.
	"horn": "horn_call",  # Norse pack: a long low war horn.
	"stone_taken": "rune_capture",  # Norse pack: the runes go dark.
	"stone_carved": "priest_ward",  # Startup bank (a chime); intended chisel taps and a rising hum.
	"ragnarok": "reckoning",  # Startup bank; intended the wolf's howl, the sun going out.
	"wolf_lunge": "rogue_dash",  # Startup bank (a lunge); intended a wolf's snarl.
	"boulder_throw": "catapult_launch",  # Startup bank (a heave).
	"boulder_land": "frost_giant_stomp",  # Norse pack: a giant's heavy impact.
	"maiden_bash": "warrior_bash",  # Startup bank (a shield clang).
	"skald_song": "banshee_wail",  # Startup bank (a chant); intended a drum and a chant.
}


# --- Act XI (temporary): Valgard ---
## Calm Blood, the act's counter-passive (owner-approved proposal: "berserk
## enemies deal 20% less damage to summons"; Valgard's achievement Holmgang
## unlocks it): its PassiveData id, read by NorseRules.calm_blood_mult().
const CALM_BLOOD: String = "calm_blood"
## Calm Blood's value key: share (0..1) cut from a berserk enemy's blow on a summon.
const CALM_BLOOD_KEY: String = "fury_cut"
