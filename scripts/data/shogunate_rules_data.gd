## ShogunateRulesData — the numbers of the Shogunate of the Rising Sun's three
## shared rules (Act V; GDD §15.0 "Act V foundation (phase 1)", "The Sun's
## Course", "The Draw" and "From the Shadows"), each with ONE code path, inert on
## Acts I to IV (Game.shogunate stays null there):
##   SUN — SunCourse: one path reading the run clock. Day (20:00-13:00 left),
##       dusk (13:00-7:00), night (7:00-0:00), the Endless Night (the
##       Reckoning). Ambient light, the night's darkness beyond the light
##       pools (the necromancer, lit stone lanterns), the dusk tint. A stage's
##       STAGE "sun" dictionary overrides any key ({} = these defaults).
##   ENDLESS_NIGHT — the shared Act V Reckoning hook: the sun never rises; a
##       stage's RECKONING "endless_night" dictionary overrides these keys
##       (absent = no Endless Night: the Reckoning keeps the last night).
##   DRAW — DrawCuts (the Draw, iaijutsu): a white line flashes from a drawing
##       samurai for `flash` s, then one cut hits every body on the line.
##   AMBUSH — ShadowAmbush (From the Shadows): ambusher squads appear out of
##       obstacle shadows near the necromancer after a smoke puff.
##   SOUNDS — event -> sound id map (one place to switch the Shogunate pack in).
## Counter-passive hooks (NOT built in phase 1; AbilityManager.passive_value()
## returns 0 while no PassiveData row exists, so each hook is exactly 1):
##   PAPER_LANTERNS — a wider light radius and earlier ambush puffs
##       (SunCourse.lantern_mult(), the one read).
##   UNBENDING — Draw cuts hit summons for less (DrawCuts.unbending_mult(), the
##       one read).
## Data only (CLAUDE.md rule 2). Every number is TUNING (not in GDD) unless
## marked as the owner-approved proposal.
class_name ShogunateRulesData
extends RefCounted

# --- The Sun's Course (SunCourse) ------------------------------------------------------

## Phase ids of the Sun's Course, in order (SunCourse.phase()).
enum Phase { DAY, DUSK, NIGHT, ENDLESS_NIGHT }
## Display names of the phases (autotest lines, banners), indexed by Phase.
const PHASE_NAMES: Array[String] = ["day", "dusk", "night", "endless night"]

## The Sun's Course defaults (a stage's STAGE "sun" overrides any key).
##   dusk_at        — game time (s) dusk begins (owner-approved proposal: 13:00 left).
##   night_at       — game time (s) night begins (owner-approved proposal: 7:00 left).
##   blend          — s each phase change blends over (game time).
##   ambient_day    — ambient light (0..1) by day: everything is lit.
##   ambient_dusk   — ambient light (0..1) at dusk (light_at() everywhere outside a pool).
##   ambient_night  — ambient light (0..1) at night: the dark beyond the pools.
##   darkness       — alpha (0..1) of the night's darkness at ambient 0 (drawn
##                    only; units in the dark stay readable: dimmed, never hidden).
##   night_color    — colour of the darkness (an indigo black).
##   dusk_tint      — colour of the dusk wash (orange).
##   dusk_tint_alpha — alpha (0..1) of the dusk wash at full dusk.
##   light_radius   — px of the necromancer's light pool (x Paper Lanterns).
##   lantern_radius — px of a lit stone lantern's light pool.
##   soft           — fraction (0..1) of a pool's radius that fades at its rim.
##   pool_light     — light (0..1) at which a point counts as "inside a lit
##                    lantern pool" (ShadowAmbush never places a puff there).
##   lantern_scan   — px around each necromancer in which stone lanterns light
##                    up at night (each stays lit for the whole night).
##   scan_every     — s between two lantern scans (simulation only).
##   max_lanterns   — most lit lanterns remembered at once (the farthest drop out).
##   shadow_len     — px of the long obstacle shadows at full dusk (drawn only).
##   sun_dir        — unit direction the dusk shadows fall (away from the sinking sun).
##   cell           — px of one darkness texel (the darkness texture's resolution;
##                    drawn only: bilinear between texels keeps the pools smooth).
const SUN := {
	"dusk_at": 420.0,  # Owner-approved proposal: dusk at 13:00 left (7:00 elapsed)
	"night_at": 780.0,  # Owner-approved proposal: night at 7:00 left (13:00 elapsed)
	"blend": 4.0,  # TUNING (not in GDD) s ("phases blend over a few seconds")
	"ambient_day": 1.0,  # TUNING (not in GDD)
	"ambient_dusk": 0.55,  # TUNING (not in GDD)
	"ambient_night": 0.0,  # TUNING (not in GDD)
	"darkness": 0.55,  # TUNING (not in GDD) brief: "about 0.55", readable on a phone
	"night_color": Color(0.02, 0.025, 0.07),  # TUNING (not in GDD) indigo black (indigo_dark, darker)
	"dusk_tint": Color(0.95, 0.45, 0.15),  # TUNING (not in GDD) the setting sun's orange
	"dusk_tint_alpha": 0.16,  # TUNING (not in GDD)
	"light_radius": 150.0,  # TUNING (not in GDD) px: wider than the Bone Ring's 60-150 px
	"lantern_radius": 120.0,  # TUNING (not in GDD) px
	"soft": 0.4,  # TUNING (not in GDD)
	"pool_light": 0.5,  # TUNING (not in GDD)
	"lantern_scan": 720.0,  # TUNING (not in GDD) px, about the view's half width plus a margin
	"scan_every": 0.5,  # TUNING (not in GDD) s
	"max_lanterns": 32,  # TUNING (not in GDD)
	"shadow_len": 26.0,  # TUNING (not in GDD) px
	"sun_dir": Vector2(0.94, 0.34),  # TUNING (not in GDD) the sun sinks in the west: shadows fall east
	"cell": 24.0,  # TUNING (not in GDD) px
}

## Banners of the phase changes (a stage may set its own as SUN keys
## "dusk_banner" / "night_banner").
const SUN_BANNERS := {
	"dusk": "Dusk: the shadows lengthen. Beware ambushes!",  # TUNING (not in GDD)
	"night": "Night falls: the oni and the dead walk. Keep to the light!",  # TUNING (not in GDD)
}

## Alpha (0..1) of a lit stone lantern's warm light-pool sprite at full night
## (drawn additively; visual only).
const LANTERN_GLOW_ALPHA: float = 0.28  # TUNING (not in GDD)
## Colour and alpha (0..1) of the faint light-pool sprite on each necromancer's
## pool at full night (drawn additively; visual only: without it the pool did
## not read on the Province's dark paddy floor).
const NECRO_GLOW_COLOR := Color(0.85, 0.80, 0.70)  # TUNING (not in GDD) pale lamplight
## Alpha of that sprite at full night.
const NECRO_GLOW_ALPHA: float = 0.12  # TUNING (not in GDD)

## The future Act V counter-passive Paper Lanterns (owner-approved proposal; NOT
## built in phase 1): PassiveData row PAPER_LANTERNS's level value
## PAPER_LANTERNS_KEY (a fraction) widens the necromancer's light radius and
## lengthens the lit part of an ambush puff's warning by (1 + value)
## (SunCourse.lantern_mult(), the one read; exactly 1 while no such passive exists).
const PAPER_LANTERNS: String = "paper_lanterns"
## Level-row key of Paper Lanterns's bonus (fraction).
const PAPER_LANTERNS_KEY: String = "light_radius"

# --- The Endless Night (the shared Act V Reckoning hook) --------------------------------

## After 0:00, on a stage whose RECKONING has an "endless_night" dictionary (its
## keys override these): the sun never rises, the dark deepens and the light
## pools shrink each minute, and the Reckoning's night kinds move faster each
## minute.
##   darkness        — darkness alpha at ambient 0 during the Endless Night.
##   light_shrink    — x the light radii for every minute past 0:00.
##   min_light_mult  — the smallest the light radii shrink to (x their base).
##   speed_per_min   — extra move speed share per minute past 0:00 of each
##                     Reckoning enemy spawned then ("faster each minute").
##   max_speed_mult  — the fastest they get (x their base speed).
const ENDLESS_NIGHT := {
	"darkness": 0.62,  # TUNING (not in GDD)
	"light_shrink": 0.9,  # TUNING (not in GDD)
	"min_light_mult": 0.6,  # TUNING (not in GDD)
	"speed_per_min": 0.08,  # TUNING (not in GDD)
	"max_speed_mult": 1.6,  # TUNING (not in GDD)
}

# --- The Draw (DrawCuts) ------------------------------------------------------------------

## The Draw (iaijutsu), Act III's Lock-On's melee cousin.
##   flash          — s the thin white line shows before the cut (owner-approved
##                    proposal: "flashes from them for 0.8 s").
##   length         — px of the line (from the drawer along its aim).
##   width          — px of the cut (a body is on the line within width / 2 of
##                    it, plus its own radius).
##   max_lines      — most lines flashing at once (owner-approved: "at most 3").
##   boss_max_lines — the boss override's hard cap (the Shogun's triple cut, phase 2).
##   dmg_player     — damage to the necromancer (x the enemies' damage scaling).
##   dmg_summon     — damage to each summon on the line (x the damage scaling,
##                    x Unbending).
##   dash           — share (0..1) of the line the drawer dashes along with the cut.
##   origin         — px from the drawer's centre where the line starts.
##   danger_reach   — px beyond the cut's half-width the autotest bot steps out of.
const DRAW := {
	"flash": 0.8,  # Owner-approved proposal
	"length": 250.0,  # TUNING (not in GDD) px
	"width": 16.0,  # TUNING (not in GDD) px
	"max_lines": 3,  # Owner-approved proposal: "At most 3 lines at once"
	"boss_max_lines": 9,  # TUNING (not in GDD)
	"dmg_player": 13.0,  # TUNING (not in GDD) a heavy blow, like a Lock-On rail
	"dmg_summon": 24.0,  # TUNING (not in GDD) it cuts through a whole file of summons
	"dash": 0.7,  # TUNING (not in GDD)
	"origin": 6.0,  # TUNING (not in GDD) px
	"danger_reach": 22.0,  # TUNING (not in GDD) px
}

## The future Act V counter-passive Unbending (owner-approved proposal; NOT built
## in phase 1): PassiveData row UNBENDING's level value UNBENDING_KEY is the
## share of a Draw cut's damage summons no longer take (DrawCuts.unbending_mult():
## 1 - value; exactly 1 while no such passive exists).
const UNBENDING: String = "unbending"
## Level-row key of Unbending's damage cut (fraction 0..1).
const UNBENDING_KEY: String = "draw_reduction"

# --- From the Shadows (ShadowAmbush) ---------------------------------------------------------

## Ambushes.
##   search       — px around the necromancer searched for obstacle shadows.
##   min_dist     — px: never closer to the necromancer than this (outside the ring).
##   shadow_gap   — px between the obstacle's edge and the puff (on its dark side).
##   probes       — random open points tried (seeded RNG) when no obstacle shadow
##                  is in reach, for one outside a lit lantern's pool.
##   puff         — s of the smoke-puff warning in the dark (owner-approved: "1 s").
##   lit_bonus    — extra s of warning at full light (x light_at() of the spot, x
##                  Paper Lanterns): "the puff shows earlier in light".
##   ring_chance  — chance (0..1) a squad member appears inside the Bone Ring.
##   ring_min     — px: the least distance from the necromancer of a ring ambush.
##   spread       — px between the members of one squad.
##   max_pending  — most puffs waiting at once (a squad beyond it waits).
##   puff_radius  — px of the drawn smoke puff (visual).
const AMBUSH := {
	"search": 400.0,  # TUNING (not in GDD) px; first pass 280 found an obstacle for few squads
	"min_dist": 90.0,  # TUNING (not in GDD) px
	"shadow_gap": 6.0,  # TUNING (not in GDD) px
	"probes": 10,  # TUNING (not in GDD)
	"puff": 1.0,  # Owner-approved proposal: "after a 1 s smoke puff"
	"lit_bonus": 0.8,  # TUNING (not in GDD) s
	"ring_chance": 0.25,  # TUNING (not in GDD) ("sometimes inside the Bone Ring")
	"ring_min": 34.0,  # TUNING (not in GDD) px
	"spread": 20.0,  # TUNING (not in GDD) px
	"max_pending": 12,  # TUNING (not in GDD)
	"puff_radius": 22.0,  # TUNING (not in GDD) px; first pass 16 read too small in a screenshot
}

# --- The Teppo volley (TeppoKit) -----------------------------------------------------------

## Every gunner fires on this shared beat (s), so the gunners in range fire as
## one volley ("a volley in a line every 6 s"); the beat is game time, no RNG.
const VOLLEY_BEAT: float = 6.0  # Owner-approved proposal: "every 6 s"

# --- Sounds ------------------------------------------------------------------------------------

## Shogunate event -> sound id played for it (Sfx.play(); an id that is not
## rendered is a silent no-op). The ids are the Shogunate pack's
## (SoundData.SHOGUNATE_SOUNDS), loaded lazily with the "sun" music; wired by the
## lead at the foundation merge.
const SOUNDS := {
	"draw_flash": "draw_flash",  # A thin steel ring as the blade leaves the saya (Shogunate pack).
	"draw_cut": "draw_cut",  # The cut's slicing whoosh.
	"smoke_puff": "smoke_puff",  # An ambush's smoke burst.
	"teppo_volley": "teppo_volley",  # A ragged crackle of matchlocks.
	"taiko_hit": "taiko_hit",  # One deep drum (reserved for phase 2's regiments and banners).
	"lantern_lit": "lantern_lit",  # A stone lantern catching light at nightfall.
	"nightfall": "nightfall",  # The low swell and temple bell of the night transition.
	"oni_smash": "oni_smash",  # The oni's iron kanabo.
	# --- Act V: Castle Kurogane ---
	"cavalry_charge": "cavalry_charge",  # SoundData.SHOGUNATE_SOUNDS: a Kiba-musha's / the General's charge (KibaKit)
	"regiment_break": "regiment_break",  # SoundData.SHOGUNATE_SOUNDS: a regiment breaks as its Hatamoto falls (ShogunRegiments)
}

