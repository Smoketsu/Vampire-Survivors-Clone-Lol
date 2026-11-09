## HostRulesData — the numbers of THE CELESTIAL HOST's shared rules (temporary
## Act XIII, final slot X; GDD §15.0 "The Celestial Host foundation (phase 1)",
## "Judgment", "Hallowed Light", "Grace" and "The Last Trumpet"; design
## docs/proposals/LAST_SIX_ACTS.md section X, plan docs/last_acts/PLAN.md).
## Read by HostRules (Game.host) and its parts:
##   JUDGMENT  — the scales of Judgment: the necromancer's sins (raises and
##               replaced summons) fill them; a Judge descends at each third;
##               full, the Verdict's pillars fall; killing Judges lightens them.
##   LIGHT     — Hallowed Light: telegraphed shafts that sweep the arena, burn
##               the undead (summons and the necromancer) and heal angels;
##               cloud shadows and pillars are safe ground.
##   CLOUDS    — the cloud banks whose shadows are the Light's safe ground.
##   GRACE     — the halo of every angel: the first hit of each kind of damage
##               is shrugged off; a Dominion's halos come back.
##   TRUMPET   — the Reckoning, the Last Trumpet.
## A stage's STAGE "judgment" / "light" / "clouds" / "grace" dictionaries
## override any key here; its RECKONING "last_trumpet" overrides TRUMPET. Data
## only, no logic. Every value is TUNING (not in GDD) unless it is marked as
## the owner-approved proposal. Tuned for the act's FINAL slot X (at or just
## above the Inferno), not its temporary number.
class_name HostRulesData
extends RefCounted

## Faction id of the Host's kinds (row "faction").
const FACTION: String = "host"
## The roster's groups in order (row "group"; the Codex and the report group
## by them): the lesser lights, the soldiers of light, the choir (the
## supports), the high orders (the elites), the guardians (the Cherub, the
## Ophan and the Silver Stair's miniboss; the Silver Stair added the group with
## its Codex section).
const GROUPS: Array[String] = ["lights", "soldiers", "choir", "orders",
	# --- Act XIII (temporary number): the Silver Stair ---
	"guardians"]

# --- Judgment (Judgment; one path) ----------------------------------------------------------
## The scales of Judgment (a stage's STAGE "judgment" overrides any key).
const JUDGMENT := {
	"capacity": 45.0,  # TUNING (not in GDD) weight that fills the scales (the Verdict; ~1 Verdict in an army bot run)
	"raise_weight": 0.5,  # Owner-approved proposal: "every corpse he raises ... adds weight"; TUNING (not in GDD) value
	"replace_weight": 0.5,  # Owner-approved proposal: "every summon he replaces adds weight"; TUNING (not in GDD) value
	"thirds": [0.3334, 0.6667],  # Owner-approved proposal: "at each third, a Judge descends" (share of capacity; each third sends once a cycle)
	"judge_kind": "judge",  # The Judge's kind id (HostEnemyData)
	"judges_per_third": 1,  # TUNING (not in GDD) Judges sent at each third (per standing necromancer)
	"judge_distance": 360.0,  # TUNING (not in GDD) px from the necromancer the Judge lands
	"judge_lighten": 6.0,  # Owner-approved proposal: "killing Judges lightens them"; TUNING (not in GDD) weight
	"verdict_every": 5.0,  # Owner-approved proposal: "a pillar of light falls on the necromancer every 5 s"
	"verdict_duration": 20.0,  # Owner-approved proposal: "for 20 s, then the scales reset"
	"pillar_warn": 1.3,  # TUNING (not in GDD) s the pillar's ring shows before it falls
	"pillar_radius": 64.0,  # TUNING (not in GDD) px
	"pillar_player_damage": 16.0,  # TUNING (not in GDD) before the time scaling (Grave Step's i-frames dodge it)
	"pillar_summon_damage": 36.0,  # TUNING (not in GDD) per summon in the pillar, before the time scaling
	"pillar_show": 0.35,  # TUNING (not in GDD) drawing only: s the fallen pillar stays drawn
	"start": 20.0,  # TUNING (not in GDD) s of game time before any sin is weighed
}
## Damage source tag of the Verdict's pillar (summons, the necromancer).
const VERDICT_SOURCE: String = "host_verdict"

# --- Hallowed Light (HallowedLight; one ground-hazard path) ---------------------------------
## The shafts of Hallowed Light (a stage's STAGE "light" overrides any key).
const LIGHT := {
	"first": 45.0,  # TUNING (not in GDD) s of game time of the first shaft
	"every": 16.0,  # TUNING (not in GDD) s between two shafts at first
	"every_step": 0.5,  # TUNING (not in GDD) s shorter each minute
	"every_min": 8.0,  # TUNING (not in GDD) s, the shortest gap
	"max_live": 2,  # TUNING (not in GDD) shafts at once
	"lead": 1.5,  # Owner-approved proposal: "a thin line 1.5 s ahead"
	"width": 52.0,  # TUNING (not in GDD) px, the shaft's width
	"speed": 72.0,  # TUNING (not in GDD) px/s the shaft sweeps
	"length": 1500.0,  # TUNING (not in GDD) px, the shaft's length (wider than the view)
	"start_offset": 540.0,  # TUNING (not in GDD) px from the necromancer the shaft starts (off his side)
	"travel": 1080.0,  # TUNING (not in GDD) px the shaft sweeps before it fades
	"tick": 0.5,  # TUNING (not in GDD) s between two burns
	"summon_burn": 7.0,  # TUNING (not in GDD) per tick to a summon in the light, before the time scaling
	"player_burn": 4.0,  # TUNING (not in GDD) per tick to the necromancer in the light, before the time scaling
	"angel_heal": 0.04,  # Owner-approved proposal: "angels in the light are healed"; TUNING (not in GDD) share of max HP per tick
	"orb_reach": 70.0,  # TUNING (not in GDD) px around the necromancer: a charged Orb Shield orb this close takes a burn for him (spent)
	"pillar_pad": 18.0,  # TUNING (not in GDD) px: a body this close to an obstacle (a pillar's shadow) is shaded
}
## Damage source tag of the Light's burn (summons, the necromancer).
const LIGHT_SOURCE: String = "hallowed_light"

## The cloud banks whose shadows are the Light's safe ground (fixed, one per
## arena cell at most, pure hashes of the stage's layout seed; a stage's STAGE
## "clouds" overrides any key).
const CLOUDS := {
	"cell": 420.0,  # TUNING (not in GDD) px, the cloud grid
	"chance": 0.5,  # TUNING (not in GDD) share of cells with a cloud bank
	"radius_min": 58.0,  # TUNING (not in GDD) px
	"radius_max": 104.0,  # TUNING (not in GDD) px
	"clear_radius": 160.0,  # TUNING (not in GDD) px around the start kept in the light
	"active_radius": 900.0,  # TUNING (not in GDD) px around a necromancer whose clouds are live
	"refresh": 0.5,  # TUNING (not in GDD) s between two rebuilds of the live set
	"seed": 0,  # 0 = the arena's layout_seed
}

# --- Grace (Grace; one stat in CombatResolver.damage_enemy()) -------------------------------
## The angels' halos (a stage's STAGE "grace" overrides any key).
const GRACE := {
	"regrow": 10.0,  # Owner-approved proposal: "their halos come back after 10 s" (near a Dominion)
	"regrow_check": 0.5,  # TUNING (not in GDD) s between two regrowth checks
}

# --- The Last Trumpet (the Reckoning) -------------------------------------------------------
## The Last Trumpet (a stage's RECKONING "last_trumpet" overrides any key):
## from 0:00 seven trumpets sound one after another; each fills the scales,
## widens the light and doubles the Host; after the seventh the sky opens.
const TRUMPET := {
	"count": 7,  # Owner-approved proposal: "seven trumpets sound one after another"
	"first": 4.0,  # TUNING (not in GDD) s after 0:00
	"every": 14.0,  # TUNING (not in GDD) s between two trumpets
	"width_mult": 1.2,  # Owner-approved proposal: "widens the light"; TUNING (not in GDD) x per trumpet
	"every_mult": 0.8,  # TUNING (not in GDD) x the Light's gap per trumpet
	"host_kind": "virtue",  # Owner-approved proposal: "doubles the Host": the squad's kind
	"host_base": 3,  # TUNING (not in GDD) the first trumpet's squad (doubles each trumpet)
	"host_cap": 48,  # TUNING (not in GDD) most a squad holds
	"host_ring": 420.0,  # TUNING (not in GDD) px from the necromancer the squad lands (a ring)
	"open_every": 3.0,  # Owner-approved proposal: "and the sky opens": TUNING (not in GDD) s between two shafts after the seventh
	"open_max_live": 6,  # TUNING (not in GDD) shafts at once once the sky is open
}

## Sound of each Host event: its id in the Host's lazy pack (SoundData.HOST_SOUNDS,
## pack "host", rendered with the "hosanna" music; wired at the art and audio merge).
const SOUNDS := {
	"scales_tip": "scales_tip",  # Host pack: a small bright bell as weight is added at a third.
	"judge_descend": "judge_descend",  # Host pack: a falling chord, wings.
	"judge_slain": "judge_slain",  # Host pack: a glass ring breaking.
	"verdict": "verdict",  # Host pack: a deep struck bell.
	"pillar_fall": "pillar_fall",  # Host pack: a white roar of light.
	"light_warn": "light_warn",  # Host pack: a thin rising tone.
	"light_burn": "light_burn",  # Host pack: a hiss of searing light.
	"halo_absorb": "halo_absorb",  # Host pack: a soft glass chime.
	"halo_regrow": "halo_regrow",  # Host pack: a rising shimmer.
	"trumpet": "trumpet",  # Host pack: a long silver trumpet blast.
	"herald_blast": "herald_blast",  # Host pack: a short trumpet call and a gust.
	"power_lunge": "power_lunge",  # Host pack: a white-flame sword cut.
	# --- Act XIII (temporary number): the Silver Stair ---
	"cherub_sword": "power_lunge",  # Host pack (reused): the Cherub's sword cut as it sweeps round.
	"seraiel_sword": "power_lunge",  # Host pack (reused): Seraiel's sword sweep.
	"gate_raise": "verdict",  # Host pack (reused): the Gate's walls of light rise (a deep struck bell).
	"trial": "scales_tip",  # Host pack (reused): Seraiel's Trial tips the scales.
	# --- Act XIII (temporary number): the Wheel of Thrones ---
	"ophan_roll": "power_lunge",  # Host pack (reused): an Ophan sets off rolling.
	"sphere_turn": "halo_regrow",  # Host pack (reused): a crystal sphere comes turning in (a rising shimmer).
	"throne_roll": "pillar_fall",  # Host pack (reused): the Throne rolls (a white roar).
	"throne_core": "judge_slain",  # Host pack (reused): the wheels open on the burning eye (glass ringing).
	# --- Act XIII (temporary number): the Empyrean ---
	"seventh_trumpet": "trumpet",  # Host pack (reused): the Herald of the Seventh Trumpet's great blast (a long silver trumpet).
	"voice_holy": "light_warn",  # Host pack (reused): the Holy's shafts rise round the Voice (a thin rising tone).
	"voice_unveil": "verdict",  # Host pack (reused): the Voice lowers its wings (a deep struck bell).
	"last_word": "judge_descend",  # Host pack (reused): the scales read the run's sins back (a falling chord, wings).
}

# --- The counter-passives (phase 2 builds them; HostRules' hooks read them) ----------------
## Passive id of Absolution (proposal: "the scales fill 30% slower"; this act only).
const ABSOLUTION: String = "absolution"
## Absolution's value key: the share of every sin's weight it takes off (0..1).
const ABSOLUTION_KEY: String = "fill_cut"
## Passive id of Smoked Glass (proposal: "Hallowed Light burns summons for half"; this act only).
const SMOKED_GLASS: String = "smoked_glass"
## Smoked Glass's value key: the share of the Light's burn on summons it takes off (0..1).
const SMOKED_GLASS_KEY: String = "burn_cut"
