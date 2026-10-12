## StageRegistry — the campaign's stages (GDD §8 "Stages and Wave Timelines",
## §9.3 "Graveyard -> Crimson March -> Sanctum"). One entry per stage, each
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
##                        the Crimson March types in CrimsonMarchStage.EVENTS).
##   reckoning          — Reckoning escalation and its banner.
##   reckoning_objective — HUD objective after 0:00.
##   empowered_graves   — StageDirector empowered graves ({} = none).
##   consecration       — StageDirector desecration events ({} = none).
##   crypt_defender     — StageDirector Crypt Defender ({} = none).
##   arena              — obstacle layout at run start (Arena).
##   ground             — "graveyard" (Ground) or "march" (MarchGround).
##   enemy_hp_mult / enemy_damage_mult — stage multipliers on the shared
##                        enemy time scaling (1.0 = Graveyard baseline).
##   enemy_mult_from    — elapsed game seconds from which those two
##                        multipliers apply to regular enemies (0 = from the
##                        start; the stage boss always gets them).
##   ash_mult           — Soul Ash multiplier of a run here (an end-screen
##                        bonus line; 1.0 = none).
##   march              — MarchDirector config ({} = no march mechanics).
class_name StageRegistry
extends RefCounted

## Stages in campaign order (stage select order, unlock chain).
const ORDER := ["graveyard", "crimson_march"]
## Stage used when none (or an unknown id) is given.
const DEFAULT_ID: String = "graveyard"
## Stage id -> STAGE dictionary.
const STAGES := {
	"graveyard": GraveyardStage.STAGE,
	"crimson_march": CrimsonMarchStage.STAGE,
}

## Boss script id -> that boss's arrival dictionary (the STAGE "boss" keys).
## The autotest option --boss=ID puts one of them in the run's stage slot
## (keeping the stage's own arrival time), so a boss can be tested on any
## stage (Game._ready()).
const BOSS_ARRIVALS := {
	"alaric": GraveyardStage.BOSS,
	"vael": CrimsonMarchStage.BOSS,
	"seraphine": SeraphineData.ARRIVAL,
}
