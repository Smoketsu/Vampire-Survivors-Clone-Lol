## StageRegistry — the campaign's stages (GDD §8 "Stages and Wave Timelines",
## §9.3 "Graveyard -> Crimson March -> Sanctum"; Act II, GDD §15.0 "Act II: the
## Ancient Eye": Gullhaven Harbour -> the Hollow Archive -> Ul-Thalos, opened
## by slaying Seraphine; Act III, GDD §15.0 "Act III foundation (phase 1)": the
## Scrap Wastes -> the Assembly Halls -> the Iron Citadel, opened by slaying
## Vhal'Neth; Act IV, GDD §15.0 "Act IV foundation (phase 1)": the Shores of
## Ilion -> Mount Olympus -> the Asphodel Underworld, opened by slaying Deus Ex
## Machina). One entry per stage, each
## the STAGE dictionary of its file under scripts/data/stages/. A run reads
## its stage through RunConfig.stage_def() as `Game.stage_def`; nothing else
## in the game hard-codes a stage.
##
## Keys of every STAGE dictionary:
##   id                 — registry id (save keys, --stage=, RunConfig).
##   display_name       — full name (stage select, end screen).
##   short_name         — short name (HUD, Soul Ash line).
##   chapter            — "Chapter I", ... (stage select).
##   description        — one-paragraph pitch (stage select; GDD theme/story).
##   unlock             — {} (always open) or {"stage": id, "boss_kills": n}:
##                        open once the boss of `stage` was slain n times in
##                        any run (GDD §9.3; Meta.is_stage_unlocked()).
##   unlock_text        — how to unlock it (stage select, while locked).
##   boss               — {id, time, display_name, short_name, arrive_banner,
##                        defeat_banner, dead_objective}: which boss script
##                        ("alaric" / "vael" / "seraphine") arrives at `time` s.
##   segments           — trickle segments (GraveyardStage.SEGMENTS keys).
##   events             — timeline events (GraveyardStage.EVENTS keys, plus
##                        the Crimson March types in CrimsonMarchStage.EVENTS
##                        and the Sanctum types in SanctumStage.EVENTS).
##   reckoning          — Reckoning escalation and its banner (optional key
##                        "kind": the main wave's enemy kind, an Act II
##                        stage's own; absent = the Reckoning Inquisitor).
##   reckoning_objective — HUD objective after 0:00.
##   empowered_graves   — StageDirector empowered graves ({} = none).
##   consecration       — StageDirector desecration events ({} = none).
##   crypt_defender     — StageDirector Crypt Defender ({} = none).
##   arena              — obstacle layout at run start (Arena).
##   ground             — "graveyard" (Ground), "march" (MarchGround),
##                        "sanctum" (SanctumGround), the Act II floors
##                        ("harbour", "archive", "spire") or "empire"
##                        (EmpireGround, the Act III placeholder floor drawn
##                        from the STAGE's "floor" dictionary) or "pantheon"
##                        (PantheonGround, the Act IV placeholder floor, from
##                        the same "floor" dictionary).
##   enemy_hp_mult / enemy_damage_mult — stage multipliers on the shared
##                        enemy time scaling (1.0 = Graveyard baseline).
##   enemy_mult_from    — elapsed game seconds from which those two
##                        multipliers apply to regular enemies (0 = from the
##                        start; the stage boss always gets them).
##   ash_mult           — Soul Ash multiplier of a run here (an end-screen
##                        bonus line; 1.0 = none).
##   march              — MarchDirector config ({} = no march mechanics; the
##                        Sanctum uses it for its battle zones only).
## Optional keys (absent = off):
##   act                — campaign act (1 = the Crimson Covenant, 2 = the
##                        Ancient Eye, 3 = the Electronic Empire, 4 = the
##                        Olympian Republic; absent = 1). The stage select shows one
##                        act at a time; Act II-only cards (PassiveData "act")
##                        are offered only on stages of that act.
##   playable           — false hides a registered stage from the stage select
##                        (shown as "Coming soon"); the autotest still runs it
##                        (absent = true). The Act II foundation stubs use it.
##   dread              — true: Dread on the necromancer (DreadMeter, Act II).
##   claims             — true: the Ancient Eye claims fallen summons as
##                        Drowned Thralls (EyeClaims, Act II).
##   music              — run loop id ("" / absent = the Act I loop; "tide" =
##                        "Below the Tide", "iron" = "Iron Requiem" (Act III);
##                        SoundData.SCORES, RunLoopSynth).
##   empire             — true: the Electronic Empire's shared rules (Act III,
##                        EmpireRules as Game.empire: Line of Fire, Lock-On,
##                        Steel has no soul, the Purge Protocol's orbital
##                        strikes when the RECKONING has an "orbital" key).
##   floor              — EmpireGround look of the "empire" ground (style,
##                        base, line, accent, trim; Act III placeholder).
##   sanctum            — SanctumDirector config (SanctumStage.SANCTUM:
##                        chambers, altars, corruption).
##   kind_aliases       — {alias: real kind}: short kind names the stage's
##                        timeline uses (EnemyDirector.resolve_kind()).
##   tide               — TideDirector config (HarbourStage.TIDE: the rising
##                        water, tide surges, High Water; Act II).
##   harbour            — HarbourDirector config (HarbourStage.HARBOUR: bell
##                        buoys, smugglers' caches, the Harbourmaster; Act II).
##   archive            — ArchiveDirector config (ArchiveStage.ARCHIVE: the
##                        Ink Wells, the Orrery, the forbidden tomes, rifts).
##   sinking            — SinkingDirector config (SpireStage.SINKING, Act II
##                        Ul-Thalos): the island shrinks with the zones (each
##                        zone's `shore` radius); the sea is the world's edge.
##   spire              — SpireDirector config (SpireStage.SPIRE: dream
##                        pillars, guest squads of the earlier Act II kinds).
##   assembly           — AssemblyDirector config (AssemblyStage.ASSEMBLY, Act
##                        III the Assembly Halls: fabricators, the furnace
##                        rhythm, guest aliases; its zones' "belts" /
##                        "channels"); with ground "assembly" (AssemblyGround).
##   citadel            — CitadelDirector config (CitadelStage.CITADEL, Act
##                        III, the Iron Citadel: Shield Gates, laser grids, the
##                        Citadel's guns, Sentry Turrets, Valkyrie 2.0, guest
##                        squads of the earlier Act III kinds); ground
##                        "citadel" is its CitadelGround (four zone floors).
## --- Act IV: the Olympian Republic ---
##   pantheon           — true: the Olympian Republic's shared rules (Act IV,
##                        PantheonRules as Game.pantheon: Wrath of the Gods,
##                        Phalanx, Glory, and the Twilight of the Gods when the
##                        RECKONING has a "twilight" key).
##   wrath              — the stage's Wrath of the Gods (DivineWrath): {"kind":
##                        "waves" | "lightning" | "fissures", plus any key of
##                        PantheonRulesData.WRATH[kind] to override it}.
##   zones              — Act IV stubs: the planned zones ([{id, name, start}],
##                        names only until phase 2 builds them).
## --- Act IV: Mount Olympus ---
##   olympus            — OlympusDirector config (OlympusStage.OLYMPUS: the
##                        Pantheon Trial's gods, Artemis's groves); ground
##                        "olympus" is its OlympusGround (four zone floors).
class_name StageRegistry
extends RefCounted

## Stages in campaign order (stage select order, unlock chain).
const ORDER := ["graveyard", "crimson_march", "sanctum", "harbour", "archive", "spire",
	# --- Act III: the Electronic Empire ---
	"wastes", "assembly", "citadel",
	# --- Act IV: the Olympian Republic ---
	"ilion", "olympus", "underworld"]
## Stage used when none (or an unknown id) is given.
const DEFAULT_ID: String = "graveyard"
## Stage id -> STAGE dictionary.
const STAGES := {
	"graveyard": GraveyardStage.STAGE,
	"crimson_march": CrimsonMarchStage.STAGE,
	"sanctum": SanctumStage.STAGE,
	"harbour": HarbourStage.STAGE,
	"archive": ArchiveStage.STAGE,
	"spire": SpireStage.STAGE,
	# --- Act III: the Electronic Empire ---
	"wastes": WastesStage.STAGE,
	"assembly": AssemblyStage.STAGE,
	"citadel": CitadelStage.STAGE,
	# --- Act IV: the Olympian Republic ---
	"ilion": IlionStage.STAGE,
	"olympus": OlympusStage.STAGE,
	"underworld": UnderworldStage.STAGE,
}

## Acts in order: act number -> {name, subtitle} (stage select tabs).
const ACTS := {
	1: {"name": "Act I", "subtitle": "The Crimson Covenant"},
	2: {"name": "Act II", "subtitle": "The Ancient Eye"},
	3: {"name": "Act III", "subtitle": "The Electronic Empire"},
	# --- Act IV: the Olympian Republic ---
	4: {"name": "Act IV", "subtitle": "The Olympian Republic"},
}


## Act of stage `id` (STAGE "act", 1 when absent or unknown).
static func act_of(id: String) -> int:
	if not STAGES.has(id):
		return 1
	return int((STAGES[id] as Dictionary).get("act", 1))


## Stage ids of act `act`, in campaign order.
static func stages_of_act(act: int) -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in ORDER:
		if act_of(id) == act:
			out.append(id)
	return out


## False for a registered stage hidden from the stage select (STAGE "playable").
static func is_playable(id: String) -> bool:
	return STAGES.has(id) and bool((STAGES[id] as Dictionary).get("playable", true))

## Boss script id -> that boss's arrival dictionary (the STAGE "boss" keys).
## The autotest option --boss=ID puts one of them in the run's stage slot
## (keeping the stage's own arrival time), so a boss can be tested on any
## stage (Game._ready()).
const BOSS_ARRIVALS := {
	"alaric": GraveyardStage.BOSS,
	"vael": CrimsonMarchStage.BOSS,
	"seraphine": SeraphineData.ARRIVAL,
	# --- Act II: Gullhaven Harbour ---
	"merrow": MerrowData.ARRIVAL,
	# --- Act II: the Hollow Archive ---
	"archivist": ArchivistData.ARRIVAL,
	# --- Act II: Ul-Thalos, the Risen Spire ---
	"vhalneth": VhalnethData.ARRIVAL,
	# --- Act III: the Electronic Empire (stubs: each stage's BOSS until phase 2
	# gives the boss its own data file) ---
	"kestrel": WastesStage.BOSS,
	"motherboard": MotherboardData.ARRIVAL,  # Act III: the Assembly Halls (its own data file)
	# --- Act III: the Iron Citadel --- (its own data file, Act III phase 2)
	"deus_ex_machina": DeusData.ARRIVAL,
	# --- Act IV: the Olympian Republic (stubs: each stage's BOSS until phase 2
	# gives the boss its own data file) ---
	"achilles": IlionStage.BOSS,
	"zeus": OlympusStage.BOSS,
	"hades": UnderworldStage.BOSS,
}
