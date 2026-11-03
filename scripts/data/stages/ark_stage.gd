## ArkStage — STAGE 27, THE ARK OF THE CONCORD, the finale of Act IX (the
## Concord of Stars; GDD §15.0 "Act IX foundation (phase 1)" and "The Ark of
## the Concord (Act IX phase 2)"; owner-approved proposal docs/act9/PROPOSAL.md
## "Stage 27: The Ark of the Concord (the finale)", with the owner's answers of
## Oct 31 and Nov 3, 2026: one coalition, the Harvesters lead here and the
## Luminous are mixed in; a plain finale; no epilogue). The mothership in
## orbit over the dead world: the Concord's capital and its harvest vault.
## Every number and event that belongs to this stage. StageRegistry exposes it
## to the run as `Game.stage_def` (the STAGE dictionary at the bottom; its keys
## are documented in StageRegistry).
##
## The stage runs the Concord's three shared rules ("concord": true: Beams,
## Abduction and Terraforming), four clock-driven zones (ZONES, run by
## MarchDirector: a zone banner, the zone's floor and obstacles) and its own
## mechanics in ArkDirector (STAGE key "ark", ARK):
##   I   THE HANGAR (0:00): hull-white deck plates and landing marks; the
##       Harvesters' greys come with their Overseers;
##   II  THE SPECIMEN VAULTS (5:00): specimen tanks stand round the
##       necromancer; break them and the beasts inside attack everyone;
##   III THE REACTOR (10:00): reactor vents breathe live alien ground on a
##       timer; break them; the LUMINOUS ARCHON (the miniboss) comes at 12:30;
##   IV  THE BRIDGE OF STARS (15:00): starfield glass, the whole coalition.
## The Harvester (HarvesterData, boss_harvester.gd: the Council, the Reaping,
## the Gardener) arrives with 3:00 left; the Reckoning, the Final Harvest, at
## 0:00. Still "playable": false until the lead's integration and the owner's
## review. Every rate, cap and weight is TUNING (not in GDD).
class_name ArkStage
extends RefCounted

## Registry id of this stage (StageRegistry.ORDER, save keys, --stage=).
const ID: String = "ark"

## Game time (s) at which the stage boss appears (3:00 left; the run structure
## of every stage).
const BOSS_TIME: float = 1020.0  # TUNING (not in GDD) 17:00, as on every stage

## Enemy max-HP multiplier of this stage on top of the shared time scaling
## (Act IX starts a step above Liberty Heights's 2.0; the step goes in HP, not
## damage: the Act IV lesson).
const ENEMY_HP_MULT: float = 2.15  # TUNING (not in GDD) the foundation's step above Liberty Heights
## Enemy damage multiplier of this stage on top of the shared time scaling
## (Liberty Heights's 1.5, kept: the step up is in HP).
const ENEMY_DAMAGE_MULT: float = 1.5  # TUNING (not in GDD) the foundation's
## Elapsed game seconds from which the two multipliers apply to regular
## enemies (the boss always gets them).
const ENEMY_MULT_FROM: float = 420.0  # TUNING (not in GDD) (Acts III to VIII: 7:00)
## Soul Ash multiplier of a run on this stage (its own end-screen line).
const ASH_MULT: float = 1.5  # TUNING (not in GDD) owner decision Oct 2026, GDD §15.0 "Ossuary expansion: owner decisions": every act restarts, stage 3 of Act IX

# =====================================================================================
# Zones and their look
# =====================================================================================

## The four zones (the clock is authoritative). Keys as CrimsonMarchStage.ZONES.
## `ground` is an ArkGround look: style "hangar" (deck plates and landing
## marks), "vaults" (gunmetal deck between rows of sunken specimen tanks),
## "reactor" (a glowing plasma grating) or "bridge" (starfield glass under
## gunmetal ribs); base / line / accent colours of the code floor (the
## tiles/ark_<style> PNG replaces them when it exists). Obstacle kinds are
## drawn from their obstacles/<kind> PNGs (tools/ark_tiles.py), else
## ArkGlyphs: cargo crates, consoles and hull pillars.
const ZONES := [
	{"id": "hangar", "start": 0.0, "numeral": "I", "name": "The Hangar",  # Owner-approved proposal zone I
		"blurb": "The mothership's open hangar, where the saucers dock and the greys muster",
		"ground": {"style": "hangar", "base": Color(0.17, 0.20, 0.23), "line": Color(0.12, 0.14, 0.17),
			"accent": Palette.CONCORD_PLASMA},
		"arena": {"density": 0.18, "clear_radius": 220.0, "layout_seed": 2701,  # TUNING (not in GDD)
			"kinds": {
				"ark_crate": {"weight": 0.6, "shape": "rect", "sizes": [40.0, 56.0], "short": 18.0},  # TUNING (not in GDD) cargo crates
				"ark_pillar": {"weight": 0.4, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD) hull pillars
			}},
	},
	{"id": "specimen_vaults", "start": 300.0, "numeral": "II", "name": "The Specimen Vaults",  # Owner-approved proposal zone II
		"blurb": "Row on row of sealed tanks: every beast the Concord ever harvested, still breathing",
		"ground": {"style": "vaults", "base": Color(0.13, 0.15, 0.18), "line": Color(0.08, 0.09, 0.11),
			"accent": Palette.CONCORD_PLASMA},
		"arena": {"density": 0.17, "clear_radius": 220.0, "layout_seed": 2702,  # TUNING (not in GDD) open: the tanks are the feature here
			"kinds": {
				"ark_console": {"weight": 0.5, "shape": "rect", "sizes": [40.0, 56.0], "short": 16.0},  # TUNING (not in GDD) specimen consoles
				"ark_pillar": {"weight": 0.5, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD)
			}},
	},
	{"id": "reactor", "start": 600.0, "numeral": "III", "name": "The Reactor",  # Owner-approved proposal zone III
		"blurb": "The Ark's heart burns green beneath the grating, and the vents breathe alien ground",
		"ground": {"style": "reactor", "base": Color(0.07, 0.12, 0.09), "line": Color(0.03, 0.05, 0.04),
			"accent": Palette.CONCORD_PLASMA},
		"arena": {"density": 0.2, "clear_radius": 220.0, "layout_seed": 2703,  # TUNING (not in GDD)
			"kinds": {
				"ark_pillar": {"weight": 0.55, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD)
				"ark_crate": {"weight": 0.45, "shape": "rect", "sizes": [40.0, 56.0], "short": 18.0},  # TUNING (not in GDD)
			}},
	},
	{"id": "bridge_of_stars", "start": 900.0, "numeral": "IV", "name": "The Bridge of Stars",  # Owner-approved proposal zone IV
		"blurb": "A floor of glass over the stars, and the throne of rings at its far end",
		"ground": {"style": "bridge", "base": Color(0.03, 0.03, 0.06), "line": Color(0.16, 0.18, 0.22),
			"accent": Palette.CONCORD_LUMEN},
		"arena": {"density": 0.15, "clear_radius": 240.0, "layout_seed": 2704,  # TUNING (not in GDD) open for the finale
			"kinds": {
				"ark_console": {"weight": 0.55, "shape": "rect", "sizes": [40.0, 56.0], "short": 16.0},  # TUNING (not in GDD) the bridge's consoles
				"ark_pillar": {"weight": 0.45, "shape": "circle", "sizes": [12.0, 16.0]},  # TUNING (not in GDD)
			}},
	},
]

## Zone mechanics for MarchDirector (keys as SanctumStage.MARCH: no road,
## outposts or carts), with the stage's own zone change look.
const MARCH := {
	"transition_time": 1.6,  # TUNING (not in GDD)
	"transition_clear": 260.0,  # TUNING (not in GDD)
	"zone_title": "DEEPER INTO THE ARK  -  ZONE %s",
	"zone_color": Palette.CONCORD_PLASMA,  # The Harvesters' plasma green.
	"fog_color": Color(0.03, 0.04, 0.06),  # The void between decks.
	"fog_bank_color": Color(0.22, 0.26, 0.30),  # Hull haze.
	"zones": ZONES,
}

## Terraforming on this stage: {} = the defaults of
## ConcordRulesData.TERRAFORMING (the Reactor's vents and the Gardener seed
## more ground through Terraforming.seed()).
const TERRAFORMING := {}

## The Final Harvest's companions on the Ark: the shared ones
## (ConcordEnemyData.RECKONING_COMPANIONS, copied: a constant cannot join two
## arrays) and a Grey Overseer (the Harvesters' home).
const RECKONING_COMPANIONS: Array = [
	{"kind": ConcordEnemyData.BROODLING, "count": 12, "growth": 2.0},  # As ConcordEnemyData.RECKONING_COMPANIONS
	{"kind": ConcordEnemyData.GREY_DRONE, "count": 4, "growth": 1.0},  # As ConcordEnemyData.RECKONING_COMPANIONS
	{"kind": ConcordEnemyData.VRASK_HUNTER, "count": 1, "growth": 0.34},  # As ConcordEnemyData.RECKONING_COMPANIONS
	{"kind": ConcordEnemyData.LUMEN_SENTINEL, "count": 1, "growth": 0.34},  # As ConcordEnemyData.RECKONING_COMPANIONS
	{"kind": ConcordEnemyData.GREY_OVERSEER, "count": 1, "growth": 0.34},  # TUNING (not in GDD) the Harvesters' home
]

## The Reckoning of this stage (keys as GraveyardStage.RECKONING): the FINAL
## HARVEST, shared by every Act IX stage: the mothership's eye opens over the
## arena and sweeps it with its beam, saucers fill the sky ("kind": the
## saucer, with the shared kinds as companions), and the abduction cap is gone
## ("final_harvest": ConcordRulesData.FINAL_HARVEST keys; {} = those
## defaults). The pods keep falling. On the Ark the Grey Overseers march with
## it (the Harvesters' home).
const RECKONING := {
	"banner": "THE FINAL HARVEST: THE MOTHERSHIP OPENS ITS EYE",
	"kind": ConcordEnemyData.RECKONING_KIND,  # The shared Final Harvest heavy (the saucer).
	"final_harvest": {},  # ConcordRulesData.FINAL_HARVEST defaults.
	"companions": RECKONING_COMPANIONS,  # The shared companions and a Grey Overseer.
	"interval": 10.0,  # TUNING (not in GDD) as every stage
	"base_count": 2,  # TUNING (not in GDD) saucers
	"count_growth": 1,  # TUNING (not in GDD)
	"hp_growth": 1.6,  # TUNING (not in GDD)
	"damage_growth": 1.25,  # TUNING (not in GDD)
}
## Objective text shown once the countdown has reached 0:00.
const RECKONING_OBJECTIVE: String = "THE FINAL HARVEST: the eye sweeps the world, and the saucers take your dead. Endure."

## Continuous spawning segments (keys as GraveyardStage.SEGMENTS): the
## Harvesters lead (grey drones, Overseers, saucers), the Luminous are mixed in
## (Sentinels, Star-Seers), the Brood and the Vrask come as guests. Saucers,
## hunters and Overseers stay rare.
const SEGMENTS := [
	{"start": 0.0, "rate": 1.4, "max_alive": 30,  # TUNING (not in GDD)
		"weights": {"grey_drone": 0.65, "broodling": 0.35},
		"objective": "The Hangar: the Harvesters' greys come for you, their probes raised"},
	{"start": 60.0, "rate": 1.7, "max_alive": 40,  # TUNING (not in GDD)
		"weights": {"grey_drone": 0.6, "broodling": 0.3, "grey_overseer": 0.06, "saucer": 0.04},
		"objective": "Kill the Grey Overseers first: their pulse stuns your dead and shields their greys"},
	{"start": 180.0, "rate": 2.0, "max_alive": 50,  # TUNING (not in GDD)
		"weights": {"grey_drone": 0.56, "broodling": 0.27, "grey_overseer": 0.06, "lumen_sentinel": 0.05, "prism": 0.02, "saucer": 0.04},
		"objective": "Your Orb Shield and your Warders' barriers send a beam back at its firer"},
	{"start": 300.0, "rate": 2.3, "max_alive": 60,  # TUNING (not in GDD)
		"weights": {"grey_drone": 0.55, "broodling": 0.27, "grey_overseer": 0.06, "lumen_sentinel": 0.05, "prism": 0.02, "vrask_hunter": 0.02, "saucer": 0.03},
		"objective": "The Specimen Vaults: break the tanks, and the beasts inside fall on the Concord too"},
	{"start": 600.0, "rate": 2.6, "max_alive": 70,  # TUNING (not in GDD)
		"weights": {"grey_drone": 0.54, "broodling": 0.27, "grey_overseer": 0.06, "lumen_sentinel": 0.06, "prism": 0.02, "vrask_hunter": 0.02, "saucer": 0.03},
		"objective": "The Reactor: break the vents before their ground heals the Concord. Your spells burn it back"},
	{"start": 900.0, "rate": 2.9, "max_alive": 80,  # TUNING (not in GDD)
		"weights": {"grey_drone": 0.52, "broodling": 0.27, "grey_overseer": 0.06, "lumen_sentinel": 0.07, "prism": 0.02, "vrask_hunter": 0.03, "saucer": 0.03},
		"objective": "The Bridge of Stars: the whole coalition stands before the throne of rings"},
	{"start": BOSS_TIME, "rate": 2.2, "max_alive": 60,  # TUNING (not in GDD) thinner during the boss fight
		"weights": {"grey_drone": 0.58, "broodling": 0.27, "grey_overseer": 0.05, "lumen_sentinel": 0.05, "prism": 0.02, "saucer": 0.03},
		"objective": "The Harvester has come for you"},
]

## One-shot scripted events (keys as GraveyardStage.EVENTS). Broodlings come in
## swarms of 12 (owner-approved proposal), grey drones in squads. The
## "luminous_archon" event is ArkDirector's (the miniboss and its escort).
const EVENTS := [
	{"time": 20.0, "type": "wave", "banner": "The hangar doors open: a squad of greys!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "grey_drone", "count": 6, "elite": false}]},
	{"time": 90.0, "type": "wave", "banner": "A Grey Overseer leads its squad! Kill it first", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "grey_overseer", "count": 1, "elite": false}, {"kind": "grey_drone", "count": 5, "elite": false}]},
	{"time": 160.0, "type": "wave", "banner": "A saucer leaves its dock! Shoot it down before it takes your dead!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "saucer", "count": 1, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 240.0, "type": "wave", "banner": "The Luminous! A Star-Seer splits their beams!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "lumen_sentinel", "count": 1, "elite": false}, {"kind": "prism", "count": 1, "elite": false}, {"kind": "grey_drone", "count": 4, "elite": false}]},
	{"time": 330.0, "type": "wave", "banner": "The vault keepers come: Overseers and their greys!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "grey_overseer", "count": 2, "elite": false}, {"kind": "grey_drone", "count": 6, "elite": false}]},
	{"time": 450.0, "type": "wave", "banner": "A Brood swarm loosed from the vaults!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}]},
	{"time": 540.0, "type": "wave", "banner": "Saucers over the vaults!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "saucer", "count": 2, "elite": false}, {"kind": "grey_drone", "count": 5, "elite": false}]},
	{"time": 680.0, "type": "wave", "banner": "The Luminous line their beams up over the reactor!", "formation": "line",  # TUNING (not in GDD)
		"groups": [{"kind": "lumen_sentinel", "count": 2, "elite": false}, {"kind": "prism", "count": 1, "elite": false}, {"kind": "grey_overseer", "count": 1, "elite": false}]},
	{"time": 750.0, "type": "luminous_archon", "kind": "luminous_archon",  # TUNING (not in GDD) the miniboss, in the Reactor
		"banner": "The LUMINOUS ARCHON descends! Every blow it strikes is a beam: catch them on your Orb Shield and barriers!",
		"escort": [{"kind": "lumen_sentinel", "count": 2, "elite": false}, {"kind": "prism", "count": 1, "elite": false}]},
	{"time": 860.0, "type": "wave", "banner": "A Vrask hunting party stalks the reactor!", "formation": "arc",  # TUNING (not in GDD)
		"groups": [{"kind": "vrask_hunter", "count": 2, "elite": false}, {"kind": "grey_drone", "count": 5, "elite": false}]},
	{"time": 940.0, "type": "wave", "banner": "The whole coalition comes!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "broodling", "count": 12, "elite": false}, {"kind": "saucer", "count": 1, "elite": false}, {"kind": "lumen_sentinel", "count": 1, "elite": false}, {"kind": "grey_overseer", "count": 1, "elite": false}]},
	{"time": 995.0, "type": "wave", "banner": "The Concord gathers before the throne of rings!", "formation": "ring",  # TUNING (not in GDD)
		"groups": [{"kind": "grey_drone", "count": 8, "elite": false}, {"kind": "broodling", "count": 12, "elite": false}, {"kind": "prism", "count": 1, "elite": false}]},
]

## ArkDirector's config (STAGE key "ark"; the director's header documents the
## rules):
##   tanks / vents — a structure window: from / until (game s), count (standing
##                   at once), ring_min / ring_max (px from the necromancer),
##                   spacing (px between two), keep (px: farther, it is taken
##                   off and rises again nearer), respawn (s after one rises
##                   before the next), max_total (in the window), banner (the
##                   first one's banner).
##   wrecks_max    — broken tanks and vents drawn on the floor at most.
const ARK := {
	"tanks": {
		"from": 300.0, "until": 600.0,  # Owner-approved proposal: the Specimen Vaults
		"count": 3,  # TUNING (not in GDD)
		"ring_min": 170.0, "ring_max": 330.0,  # TUNING (not in GDD) px
		"spacing": 120.0,  # TUNING (not in GDD) px
		"keep": 760.0,  # TUNING (not in GDD) px
		"respawn": 7.0,  # TUNING (not in GDD) s
		"max_total": 16,  # TUNING (not in GDD)
		"banner": "The Specimen Vaults: sealed tanks of captured beasts! Break them and the beasts attack everyone",
	},
	"vents": {
		"from": 600.0, "until": 900.0,  # Brief: the Reactor
		"count": 2,  # TUNING (not in GDD)
		"ring_min": 200.0, "ring_max": 360.0,  # TUNING (not in GDD) px
		"spacing": 220.0,  # TUNING (not in GDD) px
		"keep": 820.0,  # TUNING (not in GDD) px
		"respawn": 14.0,  # TUNING (not in GDD) s
		"max_total": 10,  # TUNING (not in GDD)
		"banner": "The Reactor's vents breathe alien ground that heals the Concord! Break the vents, burn the ground",
	},
	"wrecks_max": 12,  # TUNING (not in GDD)
}

## Obstacle layout of the first zone (keys as GraveyardStage.ARENA; every zone
## has its own in ZONES).
const ARENA: Dictionary = ZONES[0]["arena"]

## The Harvester's arrival (keys as GraveyardStage.BOSS): HarvesterData.ARRIVAL
## (boss id "harvester", the ending line as the defeat banner), whose `time`
## equals BOSS_TIME (17:00). Its script is scripts/enemies/concord/
## boss_harvester.gd (found by the boss id).
const BOSS: Dictionary = HarvesterData.ARRIVAL

## Floor look of the placeholder "concord" ground (ConcordGround; the stage now
## uses ArkGround and its ZONES, this stays for any caller of "floor").
const FLOOR := {
	"style": "hull",  # The mothership's deck: hull-white plates, gunmetal seams, plasma lights.
	"base": Color(0.17, 0.19, 0.22),  # TUNING (not in GDD) deck plating in the dark
	"line": Palette.CONCORD_GUNMETAL_DARK,  # TUNING (not in GDD) plate seams
	"accent": Palette.CONCORD_GUNMETAL,  # TUNING (not in GDD) hatch plates
	"trim": Palette.CONCORD_PLASMA,  # TUNING (not in GDD) deck lights
}

## The whole stage as one dictionary (StageRegistry documents every key).
const STAGE := {
	"id": ID,
	"display_name": "The Ark of the Concord",
	"short_name": "The Ark",
	"chapter": "Chapter XXVII",
	"act": 9,  # Act IX, the Concord of Stars.
	"playable": false,  # Phase 2 built; hidden from the stage select until the lead's integration and the owner's go.
	"description": "The mothership in orbit over the dead world: the Concord's capital and its harvest vault, where the one who planted the world waits.",
	"unlock": {"stage": "proving_moon", "boss_kills": 1},  # Brief: each Act IX stage opens the next
	"unlock_text": "Defeat Vrask'Tal on the Proving Moon to unlock.",
	"boss": BOSS,
	"segments": SEGMENTS,
	"events": EVENTS,
	"reckoning": RECKONING,
	"reckoning_objective": RECKONING_OBJECTIVE,
	"empowered_graves": {},  # None on Act IX stages.
	"consecration": {},  # A Covenant event: none in Act IX.
	"crypt_defender": {},  # None in Act IX.
	"arena": ARENA,
	"ground": "ark",  # ArkGround (the four zone floors).
	"floor": FLOOR,
	"enemy_hp_mult": ENEMY_HP_MULT,
	"enemy_damage_mult": ENEMY_DAMAGE_MULT,
	"enemy_mult_from": ENEMY_MULT_FROM,
	"ash_mult": ASH_MULT,
	"march": MARCH,  # The four clock-driven zones (MarchDirector).
	"ark": ARK,  # ArkDirector (the Specimen Vaults' tanks, the Reactor's vents, the Luminous Archon).
	"concord": true,  # Act IX: Beams, Abduction, Terraforming (ConcordRules).
	"terraforming": TERRAFORMING,  # Act IX: this stage's Terraforming overrides ({} = the defaults).
	"zones": ZONES,  # The four zones (MarchDirector reads them through "march").
	# Music: "The Reaping Stars" (SoundData.STARSONG_SCORE).
	"music": "starsong",
}
