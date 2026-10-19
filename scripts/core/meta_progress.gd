## Meta — persistent meta-progression autoload (GDD §9.2 Soul Ash, §9.4
## achievements, §15.7 q50 "what persists"). Owns everything that outlives a
## run and saves it to user://save.cfg (ConfigFile), separate from
## user://settings.cfg:
##   * Soul Ash balance and the purchased tier of every upgrade (MetaData),
##   * lifetime statistics (runs, best time, total kills, boss kills...),
##   * achievement unlocks (MetaData.ACHIEVEMENTS),
##   * the discovered evolution recipes ([recipes], see below).
## Run flow: Game asks run_modifiers() at run start (the ONE place meta
## upgrades enter a run, see MetaModifiers) and calls award_run() when the
## run ends, won or lost (Soul Ash is kept on death).
##
## Saving: on every run end, purchase and refund. Never in --autotest unless
## the --meta-save test flag asks for it; the autotest does not even read the
## file and uses an in-memory --meta profile instead.
## Loading is migration-safe: a missing file starts fresh, an unreadable
## (corrupt) file is copied to "<path>.corrupt" and the game starts fresh,
## every value is type-checked and clamped, unknown keys are ignored, and
## tiers whose prerequisite is no longer met are refunded.
## Profane Oath (user request): its purchased tier is a normal upgrade tier,
## but the tier that applies to runs is `oath_active`, which the player may
## lower or switch off in the Ossuary for free (set_oath_active(); owned
## tiers stay owned and can be raised again for free). Buying a tier makes it
## active. Saved as [oath] active.
## Stages (GDD §9.3 campaign unlocks): per-stage records (runs, victories,
## best time, boss kills) in `stage_records`, saved as [stages]
## "<id>_<key>". A stage opens once the boss its StageRegistry `unlock` names
## was slain often enough (is_stage_unlocked(); the Crimson March: Sir
## Alaric once). A save without [stages] (older build) is migrated additively:
## every earlier run was a Graveyard run, so the Graveyard record is rebuilt
## from the lifetime stats (an old Alaric kill unlocks the Crimson March).
## A run on a stage with an `ash_mult` above 1 earns a stage bonus line.
## Pre-run choices (GDD §10.2): the difficulty level and run modifiers last
## confirmed on the pre-run setup screen are remembered in `prerun_difficulty`
## / `prerun_modifiers` (saved as [prerun] difficulty / modifiers, a
## comma-separated id list). Older saves have no [prerun] section and get
## the defaults (Necromancer, no modifiers); unknown ids are dropped. The
## difficulty level and run modifiers each pay their own Soul Ash line.
## Recipe book (owner decision "Evolution recipe book", GDD §15.0): every
## evolution the player has obtained in any run is "discovered"
## (`discovered_recipes`, saved as [recipes] <evolution id> = true; ids from
## EvolutionRecipes, so new recipes need no save change). AbilityManager
## calls discover_recipe() when it grants an evolution; a new discovery is
## saved at once (so it survives quitting mid-run). Older saves have no
## [recipes] section and start with nothing discovered; unknown ids are
## ignored. The pause menu's Recipes view (RecipesPanel) reads it.
## Playable characters (CharacterData, owner rule): the highest level each
## spell reached in any run (`spell_max_levels`, saved as [characters]
## <spell id> = level; AbilityManager reports every spell level-up through
## CharacterModifiers.on_spell_level() -> record_spell_level(), which saves
## at once when a level is new, like a recipe discovery). A character unlocks
## once its starting spell reached CharacterData.UNLOCK_LEVEL
## (is_character_unlocked(); the Gravecaller is open from the start). The
## character last confirmed on the pre-run setup screen is remembered in
## `prerun_character` ([prerun] character). Older saves have neither and get
## nothing reached and the Gravecaller; unknown ids are ignored.
## Hyper mode and skins (owner-approved; HyperData, SkinData):
##   * `hyper_unlocked` turns true the first time HyperData.UNLOCK_BOSS_ID
##     (Grand Inquisitor Seraphine) is slain ([hyper] unlocked; an older save
##     with a kill in that boss's stage record is migrated as unlocked),
##   * `hyper_clears` records every Hyper clear (a victory with Hyper on) per
##     stage and character ([hyper_clears] "<stage>-<character>" = true; the
##     stage-select gold badges and the Hyper skins read it),
##   * `prerun_hyper` is the Hyper toggle last confirmed ([prerun] hyper),
##   * `chosen_skins` is the skin last chosen per character ([skins]
##     <character> = <skin id>); skin UNLOCKS are not stored but derived
##     (is_skin_unlocked()) from the Hyper clears, achievements and three
##     lifetime counters (rot_kills, high_confessor_kills,
##     seraphine_kills_full_army), so they can never disagree with them.
## award_run() reports what a run unlocked ("hyper_unlocked", "hyper_clear",
## "unlocked_skins") for the end screen. Older saves without these sections
## get the defaults; unknown ids are ignored.
## Codex (GDD §10.1 "Collection / Codex", CodexData): what the player has met
## in any run, per CodexData category (spells learned, summon classes raised,
## Covenant kinds slain, stage bosses faced), in `codex_seen`, saved as
## [codex] <category> = "<id>,<id>,..." (a comma-separated id list, like
## [prerun] modifiers). The run's CodexLog calls codex_record() on a first
## sight; a new entry is saved once at the end of that frame (a deferred
## save, so a burst of first sights writes once), never under the autotest
## (can_write()). Lifetime kills per Covenant kind (`codex_kills`, from the
## run's "kill_<kind>" stats in award_run()) are saved as [codex_kills]
## <kind> = count. Evolutions are not in [codex]: the Codex reads the
## [recipes] discoveries (owner rule: hidden until obtained). Older saves
## have neither section and start with nothing met; unknown ids are ignored.
## Act II (GDD §15.0 "Act II: the Ancient Eye"): the unlockable spells,
## passives and summon classes (UnlockData) a run unlocked by slaying a boss
## or earning an achievement are kept in `unlocked_items`, saved as
## [unlocks] <id> = true (award_run() fills award "unlocked_items" for the end
## screen's plates); older saves have no section and start with none, except
## that an item unlocked by a boss already slain on the stage records is
## opened on load (_load_unlocks(): the Fallen Seraph for an old Seraphine kill).
## Epilogue (content wave 2): the parts of the illustrated epilogue already
## shown are kept in `epilogue_seen`, saved as [epilogue] seen_<part id> = true
## (older saves: none seen, so an earned part plays once after the next run).
## Like Settings this script has no class_name; it is reached as `Meta`.
extends Node

## Emitted after the balance, tiers, lifetime stats or achievements changed.
signal changed

## Default save file location.
const DEFAULT_PATH: String = "user://save.cfg"
## Upper clamp for any stored counter (guards against absurd edited values).
const MAX_STORED: int = 1000000000

## File used by load_save() / save() (tests point this somewhere else).
var save_path: String = DEFAULT_PATH
## Current Soul Ash balance.
var soul_ash: int = 0
## Upgrade id -> purchased tier (every MetaData upgrade id is present).
var tiers: Dictionary = {}
## Lifetime statistics (key -> number). See _default_lifetime().
var lifetime: Dictionary = {}
## Achievement id -> true once unlocked.
var achievements: Dictionary = {}
## Result of the last ConfigFile.load() (OK, ERR_FILE_NOT_FOUND, ERR_PARSE_ERROR...).
var last_load_error: Error = OK
## What the last load did: "fresh" (not loaded), "missing", "corrupt", "ok",
## "migrated" (older save_version) or "newer" (save from a newer build).
var load_status: String = "fresh"
## Soul Ash refunded by the last load for retired upgrades (MetaData.RETIRED_REFUNDS; 0 = none).
var retired_refund: int = 0
## Breakdown Dictionary of the most recent award_run() (see compute_ash()).
var last_award: Dictionary = {}
## Profane Oath tier that applies to runs (0..owned tier; 0 = switched off).
var oath_active: int = 0
## Stage id -> {runs, victories, best_time, boss_kills} (STAGE_RECORD_KEYS),
## one entry per StageRegistry stage.
var stage_records: Dictionary = {}

## Difficulty level (DifficultyData id) last confirmed on the setup screen.
var prerun_difficulty: String = DifficultyData.DEFAULT_ID
## Run modifiers (RunModifierData ids, ORDER order) last confirmed there.
var prerun_modifiers: PackedStringArray = PackedStringArray()
## Evolution id (EvolutionRecipes.ids()) -> true once obtained in any run.
var discovered_recipes: Dictionary = {}
## Playable character (CharacterData id) last confirmed on the setup screen.
var prerun_character: String = CharacterData.DEFAULT_ID
## Spell id (AbilityData) -> highest level it reached in any run (1..5;
## absent = never learned). Drives the character unlock rule.
var spell_max_levels: Dictionary = {}
## True once Hyper mode is unlocked (HyperData.UNLOCK_BOSS_ID slain once).
var hyper_unlocked: bool = false
## "<stage id>-<character id>" -> true for every stage cleared on Hyper with
## that character (stage-select badges, Hyper skin unlocks).
var hyper_clears: Dictionary = {}
## Hyper toggle last confirmed on the setup screen.
var prerun_hyper: bool = false
## Character id -> SkinData id last chosen for that character.
var chosen_skins: Dictionary = {}
## Codex: CodexData category -> {entry id -> true} for every entry met in
## any run (one Dictionary per CodexData.CATEGORIES entry, always present).
var codex_seen: Dictionary = {}
## Codex: Covenant kind (CodexData ENEMY id) -> enemies of that kind slain
## over all runs (finished runs only, like the lifetime stats).
var codex_kills: Dictionary = {}
## Act II unlockable items (UnlockData ids) unlocked in some run: id -> true
## (the [unlocks] save section; read through Unlocks.is_open()).
var unlocked_items: Dictionary = {}
## True while a deferred codex save is queued for the end of this frame.
var _codex_save_queued: bool = false
# --- Content wave 2: E. Illustrated epilogue ---
## Epilogue part id (EpilogueData.PARTS "id") -> true once that part was shown
## (the [epilogue] seen_<id> save keys): the epilogue plays an open, unseen
## part once on its own after a run (EpilogueScreen.play_unseen()).
var epilogue_seen: Dictionary = {}

## Keys of every stage record (all floats, like the lifetime stats).
const STAGE_RECORD_KEYS := ["runs", "victories", "best_time", "boss_kills"]


func _ready() -> void:
	_reset()
	if not GameState.autotest or GameState.autotest_meta_save:
		load_save()


# =====================================================================================
# Run hooks
# =====================================================================================

## Modifiers for a new run: the purchased tiers, or the --meta profile
## (MetaData.AUTOTEST_PROFILES) in the autotest. Nothing is written.
## The Profane Oath enters at its ACTIVE tier (the autotest: --oath=N).
func run_modifiers() -> MetaModifiers:
	if GameState.autotest:
		var test_tiers: Dictionary = MetaData.autotest_tiers(GameState.autotest_meta)  # Profile tiers (never the Oath).
		if GameState.autotest_oath > 0:
			test_tiers[PactData.OATH_ID] = GameState.autotest_oath
		return MetaModifiers.from_tiers(test_tiers)
	var run_tiers := tiers.duplicate()  # Owned tiers with the Oath at its active tier.
	run_tiers[PactData.OATH_ID] = oath_active_tier()
	return MetaModifiers.from_tiers(run_tiers)


## Profane Oath tier applied to runs (never above the owned tier).
func oath_active_tier() -> int:
	return clampi(oath_active, 0, tier(PactData.OATH_ID))


## Sets the active Profane Oath tier (0 = off, up to the owned tier) without
## any refund or cost, then saves. Returns false if nothing changed.
func set_oath_active(t: int) -> bool:
	var nt := clampi(t, 0, tier(PactData.OATH_ID))  # Clamped new active tier.
	if nt == oath_active_tier():
		return false
	oath_active = nt
	save()
	changed.emit()
	return true


## Soul Ash earned by a finished run (MetaData header formula). Each part is
## floored to whole ash so the breakdown on the end screen adds up exactly.
## `summary` is Game.build_summary(); `ash_gain` is the Ash Harvest bonus.
## The Profane Pact and Profane Oath rewards (summary "pact_ash_gain" /
## "oath_ash_gain", from DifficultyModifiers) are two more bonus lines on the
## same subtotal, each floored ("pact_bonus" / "oath_bonus"), and so are
## the difficulty level ("difficulty_ash_pct" = ash_mult - 1: negative on
## Initiate, so its line subtracts; "difficulty_bonus") and the run
## modifiers ("modifiers_ash_gain" = their summed ash_gain;
## "modifiers_bonus") and Hyper mode ("hyper_ash_gain" = HyperData.ASH_BONUS
## when on; "hyper_bonus"). A summary without these keys pays nothing extra.
## Stage objectives (the Sanctum's cleansed chambers and destroyed altars,
## the run stat "objective_ash") are one more part, "objectives", of the
## subtotal (0 on stages without them).
static func compute_ash(summary: Dictionary, ash_gain: float) -> Dictionary:
	var st: Dictionary = summary.get("stats", {})
	var countdown := float(summary.get("countdown", WaveData.RUN_DURATION))
	var survived := minf(float(summary.get("time", 0.0)), countdown)
	var past_zero := minf(float(summary.get("time_past_zero", 0.0)), MetaData.ASH_RECKONING_CAP_SECONDS)
	var kills := int(summary.get("kills", 0))
	var elites := int(st.get("elite_kills", 0.0))
	var boss := bool(summary.get("boss_defeated", false))
	var parts := {
		"time": floori(survived / 60.0 * MetaData.ASH_PER_MINUTE),
		"kills": floori(float(kills) * MetaData.ASH_PER_KILL),
		"elites": floori(float(elites) * MetaData.ASH_PER_ELITE),
		"boss": floori(MetaData.ASH_BOSS_KILL) if boss else 0,
		"reckoning": floori(past_zero * MetaData.ASH_PER_RECKONING_SECOND),
		"objectives": floori(float(st.get("objective_ash", 0.0))),
	}
	var subtotal := 0
	for k: String in parts:
		subtotal += int(parts[k])
	var bonus := floori(float(subtotal) * maxf(0.0, ash_gain))
	var pact_pct := maxf(0.0, float(summary.get("pact_ash_gain", 0.0)))  # Profane Pact Soul Ash reward.
	var oath_pct := maxf(0.0, float(summary.get("oath_ash_gain", 0.0)))  # Profane Oath Soul Ash reward.
	var pact_bonus := floori(float(subtotal) * pact_pct)  # Ash from the Pact reward.
	var oath_bonus := floori(float(subtotal) * oath_pct)  # Ash from the Oath reward.
	var stage_pct := maxf(0.0, float(summary.get("stage_ash_mult", 1.0)) - 1.0)  # Stage Soul Ash bonus (Crimson March).
	var stage_bonus := floori(float(subtotal) * stage_pct)  # Ash from the stage bonus.
	var diff_pct := float(summary.get("difficulty_ash_pct", 0.0))  # Difficulty level Soul Ash change (signed).
	var diff_bonus := floori(float(subtotal) * diff_pct) if diff_pct >= 0.0 else -floori(float(subtotal) * -diff_pct)  # Signed, floored toward 0.
	var mods_pct := maxf(0.0, float(summary.get("modifiers_ash_gain", 0.0)))  # Run modifiers Soul Ash reward.
	var mods_bonus := floori(float(subtotal) * mods_pct)  # Ash from the run modifiers.
	var hyper_pct := maxf(0.0, float(summary.get("hyper_ash_gain", 0.0)))  # Hyper mode Soul Ash reward.
	var hyper_bonus := floori(float(subtotal) * hyper_pct)  # Ash from Hyper mode.
	return {
		"parts": parts,
		"time_survived": survived,
		"kill_count": kills,
		"elite_count": elites,
		"reckoning_seconds": past_zero,
		"subtotal": subtotal,
		"bonus_pct": ash_gain,
		"bonus": bonus,
		"pact_level": int(summary.get("pact_level", 0)),
		"pact_pct": pact_pct,
		"pact_bonus": pact_bonus,
		"oath_tier": int(summary.get("oath_tier", 0)),
		"oath_pct": oath_pct,
		"oath_bonus": oath_bonus,
		"stage_name": String(summary.get("stage_name", "")),
		"stage_pct": stage_pct,
		"stage_bonus": stage_bonus,
		"difficulty_name": String(summary.get("difficulty_name", "")),
		"difficulty_pct": diff_pct,
		"difficulty_bonus": diff_bonus,
		"modifier_count": (summary.get("modifiers", PackedStringArray()) as PackedStringArray).size(),
		"modifiers_pct": mods_pct,
		"modifiers_bonus": mods_bonus,
		"hyper_pct": hyper_pct,
		"hyper_bonus": hyper_bonus,
		"total": maxi(0, subtotal + bonus + pact_bonus + oath_bonus + stage_bonus + diff_bonus + mods_bonus + hyper_bonus),
	}


## Ends a run for meta-progression: adds its Soul Ash (kept on death),
## updates lifetime stats, the stage record and achievements (one-time
## bounties), saves, and returns the compute_ash() breakdown plus
## "achievements" (newly unlocked ids), "unlocked_stages" (stage ids opened
## by this run), "bounty" and "new_total" for the end screen / autotest.
func award_run(summary: Dictionary, mods: MetaModifiers) -> Dictionary:
	var award := compute_ash(summary, mods.value("ash_gain") if mods != null else 0.0)
	var st: Dictionary = summary.get("stats", {})
	var skins_before := unlocked_skin_ids()  # Skins owned before this run.
	var was_locked := PackedStringArray()  # Stages still locked before this run.
	for sid: String in StageRegistry.ORDER:
		if not is_stage_unlocked(sid):
			was_locked.append(sid)
	_record_stage_run(summary)
	var opened := PackedStringArray()  # Stages this run unlocked.
	for sid: String in was_locked:
		if is_stage_unlocked(sid):
			opened.append(sid)
	award["unlocked_stages"] = opened
	_add_lifetime("runs", 1.0)
	_add_lifetime("victories", 1.0 if bool(summary.get("victory", false)) else 0.0)
	_add_lifetime("total_kills", float(summary.get("kills", 0)))
	_add_lifetime("boss_kills", 1.0 if bool(summary.get("boss_defeated", false)) else 0.0)
	_add_lifetime("warrior_kills", float(st.get("warrior_kills", 0.0)))
	_add_lifetime("chaplain_kills", float(st.get("kill_chaplain", 0.0)))
	_add_lifetime("boss_kills_full_army", float(st.get("boss_kill_full_army", 0.0)))
	_add_lifetime("rot_kills", float(st.get("rot_kills", 0.0)))
	_add_lifetime("high_confessor_kills", float(st.get("kill_high_confessor", 0.0)))
	_add_lifetime("archive_all_tomes_runs", 1.0 if float(st.get("archive_all_tomes", 0.0)) > 0.0 else 0.0)  # Nothing Unwritten (Act II)
	var slew_unlock_boss := bool(summary.get("boss_defeated", false)) and String(summary.get("boss_id", "")) == HyperData.UNLOCK_BOSS_ID  # Seraphine slain.
	if slew_unlock_boss:
		# The Dread Sovereign skin reuses the achievement's role check
		# (Game._on_boss_defeated: the four GDD roles when the boss fell).
		_add_lifetime("seraphine_kills_full_army", 1.0 if float(st.get("boss_kill_full_army", 0.0)) > 0.0 else 0.0)
	_add_codex_kills(st)
	award["hyper_unlocked"] = slew_unlock_boss and not hyper_unlocked
	if slew_unlock_boss:
		hyper_unlocked = true
	award["hyper_clear"] = _record_hyper_clear(summary)
	_add_lifetime("ash_earned", float(award["total"]))
	lifetime["best_time"] = maxf(float(lifetime["best_time"]), float(summary.get("time", 0.0)))
	lifetime["best_reckoning"] = maxf(float(lifetime["best_reckoning"]), float(summary.get("time_past_zero", 0.0)))
	var unlocked := PackedStringArray()
	var bounty := 0
	for id: String in MetaData.ACHIEVEMENT_ORDER:
		var def: Dictionary = MetaData.ACHIEVEMENTS[id]
		if not achievements.has(id) and achievement_progress(id) >= float(def["goal"]):
			achievements[id] = true
			unlocked.append(id)
			bounty += int(def["bounty"])
	_add_lifetime("ash_earned", float(bounty))
	soul_ash = mini(soul_ash + int(award["total"]) + bounty, MAX_STORED)
	award["achievements"] = unlocked
	# Act II unlockable items (UnlockData): by the boss slain this run or by an achievement now held.
	var slain_boss := String(summary.get("boss_id", "")) if bool(summary.get("boss_defeated", false)) else ""  # Boss slain this run ("" = none).
	var items := Unlocks.newly_unlocked(slain_boss, achievements, unlocked_items)
	for id: String in items:
		unlocked_items[id] = true
	award["unlocked_items"] = items
	var new_skins := PackedStringArray()  # Skins this run unlocked.
	for id: String in unlocked_skin_ids():
		if not skins_before.has(id):
			new_skins.append(id)
	award["unlocked_skins"] = new_skins
	award["bounty"] = bounty
	award["new_total"] = soul_ash
	last_award = award
	save()
	changed.emit()
	return award


## Progress of achievement `id` toward its goal: its `stat` in the record of
## its `stage` when it names one (e.g. Dawn Extinguished: the Sanctum's boss
## kills), else the lifetime counter `stat`.
func achievement_progress(id: String) -> float:
	var def: Dictionary = MetaData.ACHIEVEMENTS[id]
	if def.has("stage"):
		return float(stage_record(String(def["stage"])).get(String(def["stat"]), 0.0))
	return float(lifetime.get(String(def["stat"]), 0.0))


# =====================================================================================
# Pre-run choices (GDD §10.2)
# =====================================================================================

## A RunConfig for stage `stage_id` with the remembered difficulty level,
## run modifiers, character (a remembered character that is locked or
## missing from this build falls back to the default), Hyper toggle (only
## while unlocked) and the skin chosen for that character (the setup screen
## opens on it).
func prerun_config(stage_id: String) -> RunConfig:
	var c := RunConfig.for_stage(stage_id)
	c.set_difficulty(prerun_difficulty)
	c.set_modifiers(prerun_modifiers)
	c.set_character(prerun_character if is_character_unlocked(prerun_character) else CharacterData.DEFAULT_ID)
	c.hyper = prerun_hyper and hyper_unlocked
	c.skin_id = chosen_skin(c.character_key())
	return c


## Remembers the difficulty level, run modifiers, character, Hyper toggle
## and skin of `config` for the next setup screen (and the next session) and
## saves when they changed.
func remember_prerun(config: RunConfig) -> void:
	var skin_changed := _remember_skin(config)  # The character's skin choice changed.
	if config.difficulty_id == prerun_difficulty and config.modifiers == prerun_modifiers \
			and config.character_id == prerun_character and config.hyper == prerun_hyper and not skin_changed:
		return
	prerun_difficulty = config.difficulty_id
	prerun_modifiers = config.modifiers.duplicate()
	prerun_character = config.character_id
	prerun_hyper = config.hyper
	save()
	changed.emit()


## Stores the skin of `config` as its character's choice (unlocked skins of
## that character only). Returns true if the stored choice changed.
func _remember_skin(config: RunConfig) -> bool:
	var ch := config.character_key()  # The run's character.
	var id := config.skin_id if config.skin_id != "" else SkinData.default_skin(ch)  # Chosen skin.
	if not SkinData.skins_for(ch).has(id) or not is_skin_unlocked(id):
		return false
	if String(chosen_skins.get(ch, SkinData.default_skin(ch))) == id:
		return false
	chosen_skins[ch] = id
	return true


# =====================================================================================
# Hyper mode and skins (owner-approved; HyperData, SkinData)
# =====================================================================================

## Records a Hyper clear of `summary` (victory with Hyper on) for its stage
## and character. Returns the stage id when it is that pair's first clear,
## else "".
func _record_hyper_clear(summary: Dictionary) -> String:
	if not bool(summary.get("hyper", false)) or not bool(summary.get("victory", false)):
		return ""
	var sid := String(summary.get("stage_id", StageRegistry.DEFAULT_ID))  # Cleared stage.
	var key := _hyper_key(sid, SkinData.character_or_default(String(summary.get("character_id", ""))))  # Save key.
	if hyper_clears.has(key) or not StageRegistry.STAGES.has(sid):
		return ""
	hyper_clears[key] = true
	return sid


## [hyper_clears] key of stage `stage_id` and character `character`.
static func _hyper_key(stage_id: String, character: String) -> String:
	return "%s-%s" % [stage_id, character]


## True when stage `stage_id` was cleared on Hyper with `character`.
func is_hyper_cleared(stage_id: String, character: String) -> bool:
	return hyper_clears.has(_hyper_key(stage_id, character))


## Number of characters that cleared stage `stage_id` on Hyper (stage-select badge).
func hyper_clear_count(stage_id: String) -> int:
	var n := 0  # Characters with a clear.
	for ch: String in CharacterData.ORDER:
		if is_hyper_cleared(stage_id, ch):
			n += 1
	return n


## True when skin `id` may be worn (SkinData unlock rules; default skins
## always). Unknown ids are locked.
func is_skin_unlocked(id: String) -> bool:
	var row := SkinData.skin(id)  # The skin's data ({} if unknown).
	if row.is_empty():
		return false
	var u: Dictionary = row["unlock"]
	match String(u["type"]):
		"default":
			return true
		"hyper_clear":
			return is_hyper_cleared(String(u["stage"]), String(row["character"]))
		"achievement":
			return achievements.has(String(u["id"]))
		"lifetime":
			return float(lifetime.get(String(u["stat"]), 0.0)) >= float(u["goal"])
	return false


## Progress text of a locked skin's condition ("1,234 / 5,000"; "" when the
## condition has no counter).
func skin_progress(id: String) -> String:
	var row := SkinData.skin(id)  # The skin's data.
	if row.is_empty():
		return ""
	var u: Dictionary = row["unlock"]
	match String(u["type"]):
		"lifetime":
			return "%d / %d" % [mini(int(float(lifetime.get(String(u["stat"]), 0.0))), int(u["goal"])), int(u["goal"])]
		"achievement":
			var aid := String(u["id"])  # The achievement.
			if MetaData.ACHIEVEMENTS.has(aid):
				var goal := int(MetaData.ACHIEVEMENTS[aid]["goal"])  # Its goal.
				return "%d / %d" % [mini(int(achievement_progress(aid)), goal), goal]
	return ""


## Every unlocked skin id (all characters, SkinData order).
func unlocked_skin_ids() -> PackedStringArray:
	var out := PackedStringArray()  # Ids.
	for id: String in SkinData.all_ids():
		if is_skin_unlocked(id):
			out.append(id)
	return out


## Skin worn by `character` next run: its remembered choice while still
## unlocked, else its default skin.
func chosen_skin(character: String) -> String:
	var ch := SkinData.character_or_default(character)  # Known character.
	var id := String(chosen_skins.get(ch, ""))  # Remembered choice.
	if id != "" and SkinData.skins_for(ch).has(id) and is_skin_unlocked(id):
		return id
	return SkinData.default_skin(ch)


# =====================================================================================
# Playable characters (unlock rule: Lv UNLOCK_LEVEL with the character's spell)
# =====================================================================================

## Records that spell `spell` reached level `lvl` in a run. When that is a
## new best it is saved at once and the characters it unlocked (first time
## their spell reached CharacterData.UNLOCK_LEVEL) are returned.
func record_spell_level(spell: String, lvl: int) -> PackedStringArray:
	var opened := PackedStringArray()  # Characters unlocked by this level.
	var old := spell_max_level(spell)  # Best level before.
	if lvl <= old or not AbilityData.SPELLS.has(spell):
		return opened
	spell_max_levels[spell] = lvl
	if old < CharacterData.UNLOCK_LEVEL and lvl >= CharacterData.UNLOCK_LEVEL:
		opened = CharacterModifiers.unlocked_by_spell(spell)
	save()
	changed.emit()
	return opened


## Highest level spell `spell` reached in any run (0 = never learned).
func spell_max_level(spell: String) -> int:
	return int(spell_max_levels.get(spell, 0))


## True when character `id` may be chosen: open from the start, or its
## starting spell reached CharacterData.UNLOCK_LEVEL in some run. (Whether
## the character exists in this build is CharacterModifiers.is_available().)
func is_character_unlocked(id: String) -> bool:
	if not CharacterModifiers.is_known(id):
		return false
	var d: Dictionary = CharacterData.CHARACTERS[id]
	return bool(d["starts_unlocked"]) or spell_max_level(String(d["spell"])) >= CharacterData.UNLOCK_LEVEL


# =====================================================================================
# Recipe book (discovered evolutions)
# =====================================================================================

## Records evolution `id` as discovered (it was just obtained) and saves when
## it is new. Returns true if it was new. Unknown ids are ignored.
func discover_recipe(id: String) -> bool:
	if discovered_recipes.has(id) or not EvolutionRecipes.has(id):
		return false
	discovered_recipes[id] = true
	save()
	changed.emit()
	return true


## True once evolution `id` has been obtained in some run.
func is_recipe_discovered(id: String) -> bool:
	return discovered_recipes.has(id)


## Number of known evolutions discovered so far.
func discovered_count() -> int:
	var n := 0  # Discovered ids still in the recipe data.
	for id: String in EvolutionRecipes.ids():
		if discovered_recipes.has(id):
			n += 1
	return n


# =====================================================================================
# Codex (GDD §10.1 "Collection / Codex"; CodexData)
# =====================================================================================

## Records codex entry `id` of category `cat` (CodexData) as met. Returns
## true when it is new (then a save is queued for the end of the frame);
## unknown categories / ids and known entries are ignored. In memory only
## under the autotest (can_write()). Never touches gameplay state.
func codex_record(cat: String, id: String) -> bool:
	var seen: Dictionary = codex_seen.get(cat, {})  # This category's met ids.
	if seen.has(id) or not CodexData.is_known(cat, id):
		return false
	seen[id] = true
	codex_seen[cat] = seen
	if can_write() and not _codex_save_queued:
		_codex_save_queued = true
		_flush_codex.call_deferred()
	return true


## The deferred half of codex_record(): one save for every first sight of
## this frame.
func _flush_codex() -> void:
	_codex_save_queued = false
	save()


## True once codex entry `id` of category `cat` was met in some run.
func is_codex_met(cat: String, id: String) -> bool:
	return (codex_seen.get(cat, {}) as Dictionary).has(id)


## Number of known entries of category `cat` met so far.
func codex_count(cat: String) -> int:
	var n := 0  # Met ids still in the codex data.
	for id: String in (codex_seen.get(cat, {}) as Dictionary):
		if CodexData.is_known(cat, id):
			n += 1
	return n


## Enemies of Covenant kind `kind` slain over all finished runs.
func codex_kill_count(kind: String) -> int:
	return int(float(codex_kills.get(kind, 0.0)))


## Adds a finished run's "kill_<kind>" stats (`st`) to the lifetime kills
## per Covenant kind (and records each kind as met, in case it was not).
func _add_codex_kills(st: Dictionary) -> void:
	for key: Variant in st:
		var k := String(key)  # Stat name.
		if not k.begins_with("kill_"):
			continue
		var kind := k.substr(5)  # Covenant kind.
		if not CodexData.is_known(CodexData.ENEMY, kind):
			continue
		codex_kills[kind] = minf(float(codex_kills.get(kind, 0.0)) + float(st[key]), float(MAX_STORED))
		(codex_seen[CodexData.ENEMY] as Dictionary)[kind] = true


## Empty met-sets, one per codex category.
static func _empty_codex() -> Dictionary:
	var out := {}  # Category -> {}.
	for cat: String in CodexData.CATEGORIES:
		out[cat] = {}
	return out


## Reads [codex] (comma-separated id lists per category) and [codex_kills]
## (count per Covenant kind). Missing sections or keys = nothing met; wrong
## types and unknown ids are ignored.
func _load_codex(cfg: ConfigFile) -> void:
	for cat: String in CodexData.CATEGORIES:
		var v: Variant = cfg.get_value("codex", cat, "")
		if typeof(v) != TYPE_STRING:
			continue
		for id: String in String(v).split(",", false):
			if CodexData.is_known(cat, id):
				(codex_seen[cat] as Dictionary)[id] = true
	if cfg.has_section("codex_kills"):
		for kind: String in cfg.get_section_keys("codex_kills"):
			if CodexData.is_known(CodexData.ENEMY, kind):
				codex_kills[kind] = _read_float(cfg, "codex_kills", kind, 0.0)


# =====================================================================================
# Stages (GDD §9.3 campaign unlocks)
# =====================================================================================

## True when stage `id` may be played: no `unlock` requirement, or the
## required stage's boss was slain at least `boss_kills` times.
func is_stage_unlocked(id: String) -> bool:
	if not StageRegistry.STAGES.has(id):
		return false
	var req: Dictionary = StageRegistry.STAGES[id]["unlock"]
	if req.is_empty():
		return true
	return float(stage_record(String(req["stage"])).get("boss_kills", 0.0)) >= float(req["boss_kills"])


## Record of stage `id` (STAGE_RECORD_KEYS; zeros for an unknown id).
func stage_record(id: String) -> Dictionary:
	if stage_records.has(id):
		return stage_records[id]
	return _empty_stage_record()


## Adds a finished run to its stage's record (summary "stage_id").
func _record_stage_run(summary: Dictionary) -> void:
	var id := String(summary.get("stage_id", StageRegistry.DEFAULT_ID))  # Stage the run was on.
	if not stage_records.has(id):
		return
	var rec: Dictionary = stage_records[id]
	rec["runs"] = minf(float(rec["runs"]) + 1.0, float(MAX_STORED))
	if bool(summary.get("victory", false)):
		rec["victories"] = minf(float(rec["victories"]) + 1.0, float(MAX_STORED))
	if bool(summary.get("boss_defeated", false)):
		rec["boss_kills"] = minf(float(rec["boss_kills"]) + 1.0, float(MAX_STORED))
	rec["best_time"] = maxf(float(rec["best_time"]), float(summary.get("time", 0.0)))


## A zeroed stage record.
static func _empty_stage_record() -> Dictionary:
	var rec := {}
	for key: String in STAGE_RECORD_KEYS:
		rec[key] = 0.0
	return rec


## A zeroed record for every StageRegistry stage.
static func _default_stage_records() -> Dictionary:
	var out := {}
	for id: String in StageRegistry.ORDER:
		out[id] = _empty_stage_record()
	return out


# =====================================================================================
# Shop (Ossuary)
# =====================================================================================

## Purchased tier of upgrade `id`.
func tier(id: String) -> int:
	return int(tiers.get(id, 0))


## True when upgrade `id` has every tier.
func is_maxed(id: String) -> bool:
	return tier(id) >= MetaData.max_tier(id)


## True when the prerequisite of upgrade `id` is met (or it has none).
func prerequisite_met(id: String) -> bool:
	var req: Dictionary = MetaData.UPGRADES[id]["requires"]
	return req.is_empty() or tier(String(req["id"])) >= int(req["tier"])


## Price of the next tier of `id` (-1 when maxed).
func next_cost(id: String) -> int:
	return -1 if is_maxed(id) else MetaData.tier_cost(id, tier(id) + 1)


## Why `id` cannot be bought right now: "" (it can), "maxed", "locked"
## (prerequisite missing) or "cost" (not enough Soul Ash).
func purchase_block(id: String) -> String:
	if is_maxed(id):
		return "maxed"
	if not prerequisite_met(id):
		return "locked"
	if soul_ash < next_cost(id):
		return "cost"
	return ""


## Buys the next tier of `id` and saves. Returns false if it was blocked.
func purchase(id: String) -> bool:
	if not MetaData.UPGRADES.has(id) or purchase_block(id) != "":
		return false
	soul_ash -= next_cost(id)
	tiers[id] = tier(id) + 1
	if id == PactData.OATH_ID:
		oath_active = tier(id)  # A newly sworn tier is active at once.
	save()
	changed.emit()
	return true


## Soul Ash currently invested in upgrades.
func spent_total() -> int:
	var total := 0
	for id: String in MetaData.UPGRADE_ORDER:
		total += MetaData.cost_up_to(id, tier(id))
	return total


## Respec: refunds every purchased tier in full, saves and returns the refund.
func refund_all() -> int:
	var refund := spent_total()
	for id: String in MetaData.UPGRADE_ORDER:
		tiers[id] = 0
	oath_active = 0
	soul_ash = mini(soul_ash + refund, MAX_STORED)
	save()
	changed.emit()
	return refund


# =====================================================================================
# Save / load
# =====================================================================================

## False in the autotest (unless --meta-save), so tests never touch user://.
func can_write() -> bool:
	return not GameState.autotest or GameState.autotest_meta_save


## Writes everything to save_path (temp file + rename, so a crash mid-write
## cannot corrupt the old save). Skipped (returns OK) when can_write() is false.
func save() -> Error:
	if not can_write():
		return OK
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "save_version", MetaData.SAVE_VERSION)
	cfg.set_value("currency", "soul_ash", soul_ash)
	for id: String in MetaData.UPGRADE_ORDER:
		cfg.set_value("upgrades", id, tier(id))
	for key: String in lifetime:
		cfg.set_value("lifetime", key, lifetime[key])
	for id: String in MetaData.ACHIEVEMENT_ORDER:
		cfg.set_value("achievements", id, achievements.has(id))
	cfg.set_value("oath", "active", oath_active_tier())
	cfg.set_value("prerun", "difficulty", prerun_difficulty)
	cfg.set_value("prerun", "modifiers", ",".join(prerun_modifiers))
	cfg.set_value("prerun", "character", prerun_character)
	for id: String in AbilityData.SPELL_ORDER:
		if spell_max_level(id) > 0:
			cfg.set_value("characters", id, spell_max_level(id))
	for id: String in StageRegistry.ORDER:
		var rec := stage_record(id)  # This stage's record.
		for key: String in STAGE_RECORD_KEYS:
			cfg.set_value("stages", "%s_%s" % [id, key], float(rec[key]))
	for id: String in EvolutionRecipes.ids():
		cfg.set_value("recipes", id, discovered_recipes.has(id))
	cfg.set_value("prerun", "hyper", prerun_hyper)
	cfg.set_value("hyper", "unlocked", hyper_unlocked)
	for key: String in hyper_clears:
		cfg.set_value("hyper_clears", key, true)
	for ch: String in chosen_skins:
		cfg.set_value("skins", ch, String(chosen_skins[ch]))
	for cat: String in CodexData.CATEGORIES:
		cfg.set_value("codex", cat, ",".join(PackedStringArray((codex_seen[cat] as Dictionary).keys())))
	for kind: String in codex_kills:
		cfg.set_value("codex_kills", kind, float(codex_kills[kind]))
	for id: String in UnlockData.UNLOCKS:
		if unlocked_items.has(id):
			cfg.set_value("unlocks", id, true)
	for id: String in epilogue_seen:  # Content wave 2: E. Illustrated epilogue.
		cfg.set_value("epilogue", "seen_" + id, true)
	var tmp := save_path + ".tmp"
	var err := cfg.save(tmp)
	if err != OK:
		return cfg.save(save_path)
	if DirAccess.rename_absolute(tmp, save_path) != OK:
		DirAccess.remove_absolute(tmp)
		return cfg.save(save_path)
	return OK


## Loads save_path into memory (see the header for the recovery rules).
func load_save() -> void:
	_reset()
	var cfg := ConfigFile.new()
	last_load_error = cfg.load(save_path)
	if last_load_error == ERR_FILE_NOT_FOUND:
		load_status = "missing"
		changed.emit()
		return
	if last_load_error != OK:
		load_status = "corrupt"
		print("[meta] %s is unreadable (error %d); starting a fresh profile" % [save_path, last_load_error])
		if can_write() and DirAccess.copy_absolute(save_path, save_path + ".corrupt") == OK:
			print("[meta] the unreadable file was kept as %s.corrupt" % save_path)
		changed.emit()
		return
	var version := _read_int(cfg, "meta", "save_version", 0)
	_migrate(cfg, version)
	soul_ash = _read_int(cfg, "currency", "soul_ash", 0)
	# Retired upgrades (MetaData.RETIRED_REFUNDS): an owned one pays its Soul Ash back;
	# save() never writes the key again, so the refund happens once.
	for old_id: String in MetaData.RETIRED_REFUNDS:
		if _read_int(cfg, "upgrades", old_id, 0) > 0:
			soul_ash = mini(soul_ash + int(MetaData.RETIRED_REFUNDS[old_id]), MAX_STORED)
			retired_refund += int(MetaData.RETIRED_REFUNDS[old_id])
	for id: String in MetaData.UPGRADE_ORDER:
		tiers[id] = mini(_read_int(cfg, "upgrades", id, 0), MetaData.max_tier(id))
	for key: String in lifetime:
		lifetime[key] = _read_float(cfg, "lifetime", key, float(lifetime[key]))
	for id: String in MetaData.ACHIEVEMENT_ORDER:
		var v: Variant = cfg.get_value("achievements", id, false)
		if typeof(v) == TYPE_BOOL and bool(v):
			achievements[id] = true
	_enforce_prerequisites()
	# Missing key (older save) = the owned Oath tier is active.
	oath_active = clampi(_read_int(cfg, "oath", "active", tier(PactData.OATH_ID)), 0, tier(PactData.OATH_ID))
	_load_stage_records(cfg)
	_load_prerun(cfg)
	_load_recipes(cfg)
	_load_characters(cfg)
	_load_hyper_skins(cfg)
	_load_codex(cfg)
	_load_unlocks(cfg)
	_load_epilogue(cfg)
	if version > MetaData.SAVE_VERSION:
		load_status = "newer"
	elif version < MetaData.SAVE_VERSION:
		load_status = "migrated"
	else:
		load_status = "ok"
	changed.emit()


## Reads the [stages] records. A save from before stages existed has no such
## section: every earlier run was a Graveyard run, so the Graveyard record
## is rebuilt from the lifetime stats (runs, victories, best time, boss
## kills), which keeps an earlier Alaric kill's Crimson March unlock.
## Missing keys of a known stage read as 0; unknown keys are ignored.
func _load_stage_records(cfg: ConfigFile) -> void:
	if not cfg.has_section("stages"):
		var gy: Dictionary = stage_records[StageRegistry.DEFAULT_ID]  # The Graveyard record.
		for key: String in STAGE_RECORD_KEYS:
			gy[key] = float(lifetime.get(key, 0.0))
		return
	for id: String in StageRegistry.ORDER:
		var rec: Dictionary = stage_records[id]
		for key: String in STAGE_RECORD_KEYS:
			rec[key] = _read_float(cfg, "stages", "%s_%s" % [id, key], 0.0)


## Reads the [prerun] choices (missing section or keys = the defaults; wrong
## types and unknown ids are ignored).
func _load_prerun(cfg: ConfigFile) -> void:
	var c := RunConfig.new()  # Validates the ids.
	var d: Variant = cfg.get_value("prerun", "difficulty", DifficultyData.DEFAULT_ID)
	if typeof(d) == TYPE_STRING:
		c.set_difficulty(String(d))
	var m: Variant = cfg.get_value("prerun", "modifiers", "")
	if typeof(m) == TYPE_STRING:
		c.set_modifiers(String(m).split(",", false))
	prerun_difficulty = c.difficulty_id
	prerun_modifiers = c.modifiers


## Reads the [characters] spell levels (missing section or keys = never
## reached; only known spell ids, clamped to 0..5) and the remembered
## [prerun] character (unknown ids = the default).
func _load_characters(cfg: ConfigFile) -> void:
	for id: String in AbilityData.SPELL_ORDER:
		var lvl := mini(_read_int(cfg, "characters", id, 0), (AbilityData.SPELLS[id]["levels"] as Array).size())  # Saved best level.
		if lvl > 0:
			spell_max_levels[id] = lvl
	var c: Variant = cfg.get_value("prerun", "character", CharacterData.DEFAULT_ID)
	prerun_character = String(c) if typeof(c) == TYPE_STRING and CharacterModifiers.is_known(String(c)) else CharacterData.DEFAULT_ID


## Reads the [unlocks] section (missing = locked; only `true` booleans of
## known UnlockData ids count). Retroactive boss unlocks (GDD §15.0 "Fallen
## Seraph"): an item whose row names a `boss` is also open when the stage
## record of that boss's stage already shows a kill, so a save that slew the
## boss before the item existed (Seraphine before the Fallen Seraph) has it
## (the same rule as Hyper's migration, _load_hyper_skins()). Stage records
## are read first (load()).
func _load_unlocks(cfg: ConfigFile) -> void:
	for id: String in UnlockData.UNLOCKS:
		var v: Variant = cfg.get_value("unlocks", id, false)
		if typeof(v) == TYPE_BOOL and bool(v):
			unlocked_items[id] = true
		var row: Dictionary = UnlockData.UNLOCKS[id]
		if row.has("boss") and _boss_slain_on_record(String(row["boss"])):
			unlocked_items[id] = true


## True when some stage whose boss slot is boss `boss_id` records a boss kill.
func _boss_slain_on_record(boss_id: String) -> bool:
	for sid: String in StageRegistry.ORDER:
		var boss: Dictionary = StageRegistry.STAGES[sid]["boss"]  # The stage's boss slot.
		if String(boss.get("id", "")) == boss_id and float(stage_record(sid)["boss_kills"]) > 0.0:
			return true
	return false


# --- Content wave 2: E. Illustrated epilogue ---

## Reads the [epilogue] seen flags (missing = unseen; only `true` booleans of
## known EpilogueData part ids count).
func _load_epilogue(cfg: ConfigFile) -> void:
	for part: Dictionary in EpilogueData.PARTS:
		var id := String(part["id"])  # The part's id.
		var v: Variant = cfg.get_value("epilogue", "seen_" + id, false)
		if typeof(v) == TYPE_BOOL and bool(v):
			epilogue_seen[id] = true


## True once epilogue part `id` (EpilogueData.PARTS "id") was shown.
func is_epilogue_seen(id: String) -> bool:
	return epilogue_seen.has(id)


## Marks epilogue parts `ids` as shown and saves once when one was new (never
## under the autotest: save() checks can_write()). Returns true when any was new.
func mark_epilogue_seen(ids: PackedStringArray) -> bool:
	var any_new := false  # True when at least one id was not seen yet.
	for id: String in ids:
		if not epilogue_seen.has(id):
			epilogue_seen[id] = true
			any_new = true
	if any_new:
		save()
	return any_new


## True when Act II item `id` (UnlockData) was unlocked in some run. Callers
## use Unlocks.is_open(), which also opens every non-lockable item.
func is_item_unlocked(id: String) -> bool:
	return unlocked_items.has(id)


## Reads the [recipes] discoveries (missing section or keys = undiscovered;
## only `true` booleans of known evolution ids count).
func _load_recipes(cfg: ConfigFile) -> void:
	for id: String in EvolutionRecipes.ids():
		var v: Variant = cfg.get_value("recipes", id, false)
		if typeof(v) == TYPE_BOOL and bool(v):
			discovered_recipes[id] = true


## Reads the Hyper / skin sections (missing = locked, no clears, Hyper off,
## default skins; only `true` booleans and known ids count). A save from
## before Hyper existed whose stage records show HyperData.UNLOCK_BOSS_ID
## slain is treated as unlocked.
func _load_hyper_skins(cfg: ConfigFile) -> void:
	var u: Variant = cfg.get_value("hyper", "unlocked", false)
	hyper_unlocked = typeof(u) == TYPE_BOOL and bool(u)
	for sid: String in StageRegistry.ORDER:
		var boss: Dictionary = StageRegistry.STAGES[sid]["boss"]  # The stage's boss slot.
		if String(boss.get("id", "")) == HyperData.UNLOCK_BOSS_ID and float(stage_record(sid)["boss_kills"]) > 0.0:
			hyper_unlocked = true
	for sid: String in StageRegistry.ORDER:
		for ch: String in CharacterData.ORDER:
			var v: Variant = cfg.get_value("hyper_clears", _hyper_key(sid, ch), false)
			if typeof(v) == TYPE_BOOL and bool(v):
				hyper_clears[_hyper_key(sid, ch)] = true
	var h: Variant = cfg.get_value("prerun", "hyper", false)
	prerun_hyper = typeof(h) == TYPE_BOOL and bool(h)
	for ch: String in CharacterData.ORDER:
		var sk: Variant = cfg.get_value("skins", ch, "")
		if typeof(sk) == TYPE_STRING and SkinData.skins_for(ch).has(String(sk)):
			chosen_skins[ch] = String(sk)


## Upgrades an older save layout in `cfg` (in memory) to SAVE_VERSION.
## Version 0 is a file without a save_version key; it has the version-1
## layout, so nothing moves. Future layout changes add one step per version
## here (rename / convert keys), so old saves keep loading.
func _migrate(cfg: ConfigFile, from_version: int) -> void:
	if from_version < 1:
		cfg.set_value("meta", "save_version", 1)


## Refunds tiers whose prerequisite is not met (a hand-edited save or a
## data change), repeating until every remaining tier is valid.
func _enforce_prerequisites() -> void:
	var changed_any := true
	while changed_any:
		changed_any = false
		for id: String in MetaData.UPGRADE_ORDER:
			if tier(id) > 0 and not prerequisite_met(id):
				soul_ash = mini(soul_ash + MetaData.cost_up_to(id, tier(id)), MAX_STORED)
				tiers[id] = 0
				changed_any = true


## Clears every persistent value to a fresh profile (in memory only).
func _reset() -> void:
	soul_ash = 0
	retired_refund = 0
	tiers = {}
	for id: String in MetaData.UPGRADE_ORDER:
		tiers[id] = 0
	lifetime = _default_lifetime()
	achievements = {}
	last_award = {}
	oath_active = 0
	stage_records = _default_stage_records()
	prerun_difficulty = DifficultyData.DEFAULT_ID
	prerun_modifiers = PackedStringArray()
	discovered_recipes = {}
	prerun_character = CharacterData.DEFAULT_ID
	spell_max_levels = {}
	hyper_unlocked = false
	hyper_clears = {}
	prerun_hyper = false
	chosen_skins = {}
	codex_seen = _empty_codex()
	codex_kills = {}
	unlocked_items = {}
	epilogue_seen = {}
	load_status = "fresh"


## Lifetime statistic keys and their starting values.
static func _default_lifetime() -> Dictionary:
	return {
		"runs": 0.0,  # runs finished (won or lost)
		"victories": 0.0,  # runs that survived the countdown
		"best_time": 0.0,  # longest run, seconds
		"best_reckoning": 0.0,  # most seconds survived past 0:00
		"total_kills": 0.0,  # enemies slain over all runs
		"boss_kills": 0.0,  # stage boss kills (Sir Alaric, Marshal Vael), all stages
		"warrior_kills": 0.0,  # killing blows by Skeleton Warriors (achievement)
		"chaplain_kills": 0.0,  # Covenant Chaplains slain (achievement)
		"boss_kills_full_army": 0.0,  # boss kills with all 4 classes (achievement)
		"ash_earned": 0.0,  # Soul Ash earned in total (runs + bounties)
		"rot_kills": 0.0,  # enemies slain while Rotting (Plague Doctor skin)
		"high_confessor_kills": 0.0,  # High Confessors slain (Heretic Saint skin)
		"seraphine_kills_full_army": 0.0,  # Seraphine slain with the 4 GDD roles (Dread Sovereign skin)
		# --- Act II: the Hollow Archive ---
		"archive_all_tomes_runs": 0.0,  # Hollow Archive runs that burned every tome (Nothing Unwritten)
	}


## Adds `amount` to lifetime counter `key`.
func _add_lifetime(key: String, amount: float) -> void:
	lifetime[key] = minf(float(lifetime.get(key, 0.0)) + amount, float(MAX_STORED))


## Reads a non-negative int; wrong types fall back to `default`.
static func _read_int(cfg: ConfigFile, section: String, key: String, default: int) -> int:
	var v: Variant = cfg.get_value(section, key, default)
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return default
	var f := float(v)
	if is_nan(f) or is_inf(f):
		return default
	return clampi(int(f), 0, MAX_STORED)


## Reads a non-negative float; wrong types fall back to `default`.
static func _read_float(cfg: ConfigFile, section: String, key: String, default: float) -> float:
	var v: Variant = cfg.get_value(section, key, default)
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return default
	var f := float(v)
	if is_nan(f) or is_inf(f):
		return default
	return clampf(f, 0.0, float(MAX_STORED))
