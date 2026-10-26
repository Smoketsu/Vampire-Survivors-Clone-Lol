## CodexEntries — builds what the Codex and Achievements screen shows
## (CodexScreen) from the game's data and the Meta save; read-only, no UI.
##   * pages(): per codex page, its sections (CodexData.SECTIONS) and their
##     entries, each a Dictionary:
##       id, section, met (recorded / discovered), evolution (bool), name,
##       tag (LABEL line), desc (one sentence), sprite (SpriteBank key or ""),
##       icon (icon kind), stats (Array of [label, value] strings), record
##       (a lifetime line or ""), boss (bool: big tile).
##     Evolutions are met only when their recipe was discovered (Meta
##     [recipes]); until then they carry NO name, art or description (owner
##     rule: never hint unobtained evolutions).
##   * feats(): the achievement rows (MetaData achievements, then the feats:
##     the lifetime-counter skin unlocks, the Hyper unlock and the Hyper
##     skins), each a Dictionary:
##       name, goal, progress, target (floats), earned, badge (icon kind),
##       badge_fallback, reward (text), reward_skin (SkinData id or ""),
##       reward_icon (icon kind or "").
class_name CodexEntries
extends RefCounted


## Every codex page id -> Array of {id, title, entries} sections.
static func pages() -> Dictionary:
	var out := {}  # Page id -> sections.
	for page: String in CodexData.SECTIONS:
		var sections: Array = []
		for s: Array in CodexData.SECTIONS[page]:
			sections.append({"id": String(s[0]), "title": String(s[1]), "entries": section_entries(String(s[0]))})
		out[page] = sections
	return out


## The entries of section `section` (CodexData.SECTIONS ids), in order.
static func section_entries(section: String) -> Array:
	var out: Array = []
	match section:
		"spells":
			for id: String in AbilityData.SPELL_ORDER:
				out.append(_spell(id))
		"spell_evolutions":
			for id: String in EvolutionData.ORDER:
				out.append(_evolution(id, section))
		"summons":
			for id: String in CodexData.SUMMON_ORDER:
				out.append(_summon(id))
		"summon_evolutions":
			for id: String in SummonEvolutionData.ORDER:
				out.append(_evolution(id, section))
		"soldiers":
			for id: String in CodexData.SOLDIERS:
				out.append(_covenant(id, section))
		"structures":
			for id: String in CodexData.STRUCTURES:
				out.append(_covenant(id, section))
		"champions":
			for id: String in CodexData.CHAMPIONS:
				out.append(_covenant(id, section))
		"bosses":
			for id: String in CodexData.BOSSES:
				out.append(_boss(id))
		"eye_soldiers":
			for id: String in CodexData.EYE_SOLDIERS:
				out.append(_covenant(id, section))
		"eye_champions":
			for id: String in CodexData.EYE_CHAMPIONS:
				out.append(_covenant(id, section))
		"eye_bosses":
			for id: String in CodexData.EYE_BOSSES:
				var b := _boss(id)
				b["section"] = section
				out.append(b)
		# --- Act III: the Electronic Empire ---
		"empire_soldiers":
			for id: String in CodexData.EMPIRE_SOLDIERS:
				out.append(_covenant(id, section))
		"empire_champions":
			for id: String in CodexData.EMPIRE_CHAMPIONS:
				out.append(_covenant(id, section))
		"empire_bosses":
			for id: String in CodexData.EMPIRE_BOSSES:
				var b := _boss(id)
				b["section"] = section
				out.append(b)
		# --- Act IV: the Olympian Republic ---
		"pantheon_soldiers":
			for id: String in CodexData.PANTHEON_SOLDIERS:
				out.append(_covenant(id, section))
		"pantheon_champions":
			for id: String in CodexData.PANTHEON_CHAMPIONS:
				out.append(_covenant(id, section))
		"pantheon_bosses":
			for id: String in CodexData.PANTHEON_BOSSES:
				var b := _boss(id)
				b["section"] = section
				out.append(b)
		# --- Act V: the Shogunate of the Rising Sun ---
		"shogunate_soldiers":
			for id: String in CodexData.SHOGUNATE_SOLDIERS:
				out.append(_covenant(id, section))
		"shogunate_champions":
			for id: String in CodexData.SHOGUNATE_CHAMPIONS:
				out.append(_covenant(id, section))
		"shogunate_bosses":
			for id: String in CodexData.SHOGUNATE_BOSSES:
				var b := _boss(id)
				b["section"] = section
				out.append(b)
	return out


## Recorded / total entries of the sections of `sections` (pages() value).
static func counts(sections: Array) -> Vector2i:
	var met := 0
	var all := 0
	for s: Dictionary in sections:
		for e: Dictionary in s["entries"]:
			all += 1
			met += 1 if bool(e["met"]) else 0
	return Vector2i(met, all)


## A spell entry.
static func _spell(id: String) -> Dictionary:
	var d: Dictionary = AbilityData.SPELLS[id]
	var stats: Array = []  # Lv 1 -> Lv 5 of its first two card stats.
	var levels: Array = d["levels"]
	var labels: Dictionary = d["labels"]
	for key: String in labels.keys().slice(0, 2):
		stats.append([String(labels[key]), "%s  ->  %s" % [num(float(levels[0][key])), num(float(levels[levels.size() - 1][key]))]])
	var best := Meta.spell_max_level(id)  # Highest level it reached in any run.
	var e := _entry(id, "spells", Meta.is_codex_met(CodexData.SPELL, id), false, String(d["display_name"]),
		String(d["description"]), "", String(d["icon"]), stats, String(CodexData.TEXT["best_level"]) % best if best > 0 else "")
	_lock_hint(e, id)
	return e


## A summon class entry.
static func _summon(id: String) -> Dictionary:
	var d: Dictionary = UnitData.UNITS[id]
	var stats: Array = [[_t("hp"), num(float(d["max_hp"]))], [_t("damage"), num(float(d["damage"]))], [_t("speed"), num(float(d["move_speed"]))]]
	var e := _entry(id, "summons", Meta.is_codex_met(CodexData.SUMMON, id), false, String(d["display_name"]),
		String(d["description"]), "summons/" + id, id, stats, "")
	_lock_hint(e, id)
	return e


## A still-locked Act II item (Unlocks) shows its unlock condition instead of
## the page's hint while it is unrecorded (entry key "lock_hint").
static func _lock_hint(e: Dictionary, id: String) -> void:
	if not bool(e["met"]) and not Unlocks.is_open(id):
		e["lock_hint"] = Unlocks.lock_text(id)


## A spell or summon evolution entry (`section` names which).
static func _evolution(id: String, section: String) -> Dictionary:
	var met := Meta.is_recipe_discovered(id)  # Obtained in some run (the recipe book).
	if not met:
		return _entry(id, section, false, true, CodexData.LOCKED_EVOLUTION, "", "", "", [], "")
	var r := EvolutionRecipes.recipe(id)  # Normalised recipe (name, icon, ingredients).
	var parts := PackedStringArray()  # "Shadow Bolt Lv 5" per ingredient.
	for ing: Dictionary in r["ingredients"]:
		parts.append((RecipeBookData.INGREDIENT % [String(ing["name"]), int(ing["level"])]).replace(" ", "\u00a0"))  # One ingredient never wraps inside.
	var desc := String(EvolutionData.EVOLUTIONS[id]["description"]) if EvolutionData.EVOLUTIONS.has(id) \
			else String(SummonEvolutionData.EVOLUTIONS[id]["description"])
	var sprite := ""  # Spell evolutions have only their icon.
	if section == "summon_evolutions":
		sprite = String(CodexData.SPRITE_KEYS.get(id, "summons/" + String(r["icon"])))
	return _entry(id, section, true, true, String(r["name"]), desc, sprite, String(r["icon"]),
		[[_t("recipe"), (" %s " % RecipeBookData.PLUS).join(parts)]], "")


## A Covenant soldier, structure or champion entry.
static func _covenant(id: String, section: String) -> Dictionary:
	var d := CodexData.enemy_row(id)
	var stats: Array = [[_t("hp"), num(float(d.get("max_hp", 0.0)))]]
	if float(d.get("damage", 0.0)) > 0.0:
		stats.append([_t("damage"), num(float(d["damage"]))])
	if float(d.get("armor", 0.0)) > 0.0:
		stats.append([_t("armour"), "%d%%" % roundi(float(d["armor"]) * 100.0)])
	elif float(d.get("move_speed", 0.0)) > 0.0:
		stats.append([_t("speed"), num(float(d["move_speed"]))])
	var sprite := String(CodexData.SPRITE_KEYS.get(id, "enemies/" + id))  # Soldiers and champions (the Ancient Eye's in eye/)...
	if not SpriteBank.has(sprite) and SpriteBank.has("eye/" + id):
		sprite = "eye/" + id  # ...an Ancient Eye kind (Act II)...
	elif not SpriteBank.has(sprite) and SpriteBank.has("empire/" + id):
		sprite = "empire/" + id  # ...an Electronic Empire kind (Act III)...
	elif not SpriteBank.has(sprite) and SpriteBank.has("pantheon/" + id):
		sprite = "pantheon/" + id  # ...an Olympian Republic kind (Act IV)...
	elif not SpriteBank.has(sprite) and SpriteBank.has("shogunate/" + id):
		sprite = "shogunate/" + id  # ...a Shogunate kind (Act V)...
	elif not SpriteBank.has(sprite):
		sprite = "structures/" + id  # ...or a structure.
	var kills := Meta.codex_kill_count(id)  # Lifetime kills of this kind.
	return _entry(id, section, Meta.is_codex_met(CodexData.ENEMY, id), false, String(d.get("display_name", id)),
		String(CodexData.DESCRIPTIONS.get(id, "")), sprite, "", stats,
		_t("destroyed" if section == "structures" else "slain") % group(kills) if kills > 0 else "")


## A stage boss entry.
static func _boss(id: String) -> Dictionary:
	var d := CodexData.enemy_row(id)
	var arrival: Dictionary = StageRegistry.BOSS_ARRIVALS[id]
	var kills := 0  # Times slain: the boss kills of the stage whose slot holds it.
	var stage := ""  # That stage's name.
	for sid: String in StageRegistry.ORDER:
		if String((StageRegistry.STAGES[sid]["boss"] as Dictionary).get("id", "")) == id:
			kills = int(float(Meta.stage_record(sid)["boss_kills"]))
			stage = String(StageRegistry.STAGES[sid]["display_name"])
	var left := maxi(0, roundi(WaveData.RUN_DURATION - float(arrival["time"])))  # Countdown when it arrives (s).
	var stats: Array = [[_t("hp"), group(int(float(d.get("max_hp", 0.0))))], [_t("arrives"), _t("arrives_at") % [floori(float(left) / 60.0), left % 60]]]
	if stage != "":
		stats.push_front([_t("stage"), stage])
	var e := _entry(id, "bosses", Meta.is_codex_met(CodexData.BOSS, id), false, String(arrival["display_name"]),
		String(CodexData.DESCRIPTIONS.get(id, "")), "bosses/" + id, "", stats, _t("slain") % group(kills) if kills > 0 else "")
	e["boss"] = true
	return e


## One entry Dictionary (see the header).
static func _entry(id: String, section: String, met: bool, evolution: bool, name: String, desc: String,
		sprite: String, icon: String, stats: Array, record: String) -> Dictionary:
	return {"id": id, "section": section, "met": met, "evolution": evolution, "name": name, "desc": desc,
		"tag": String(CodexData.TAGS.get(section, "")), "sprite": sprite, "icon": icon, "stats": stats,
		"record": record, "boss": false}


# =====================================================================================
# Achievements and feats
# =====================================================================================

## The achievement rows (MetaData.ACHIEVEMENT_ORDER), then the feats.
static func feats() -> Array:
	var out: Array = []
	for id: String in MetaData.ACHIEVEMENT_ORDER:
		var a: Dictionary = MetaData.ACHIEVEMENTS[id]
		var skin := _skin_for_achievement(id)  # A skin this achievement unlocks ("" = none).
		var reward := CodexData.BOUNTY_TEXT % int(a["bounty"])
		if String(a.get("unlock", "")) != "":
			reward = "%s, %s" % [String(a["unlock"]), reward]  # Content wave 2: every achievement names its reward.
		elif skin != "":
			reward = "%s, %s" % [String(SkinData.skin(skin)["display_name"]), reward]
		out.append({"name": String(a["display_name"]), "goal": String(a["description"]),
			"progress": Meta.achievement_progress(id), "target": float(a["goal"]), "earned": Meta.achievements.has(id),
			"badge": String(CodexData.ACHIEVEMENT_ICONS.get(id, "")), "badge_fallback": String(CodexData.ACHIEVEMENT_FALLBACK_ICONS.get(id, "")),
			"reward": reward, "reward_skin": skin, "reward_icon": "" if skin != "" else "soul_ash", "feat": false})
	for id: String in SkinData.ACHIEVEMENT_SKINS:
		var s: Dictionary = SkinData.ACHIEVEMENT_SKINS[id]
		var u: Dictionary = s["unlock"]
		if String(u["type"]) != "lifetime":
			continue
		out.append({"name": String(s["display_name"]), "goal": String(s["unlock_text"]),
			"progress": float(Meta.lifetime.get(String(u["stat"]), 0.0)), "target": float(u["goal"]), "earned": Meta.is_skin_unlocked(id),
			"badge": "", "badge_fallback": "", "badge_skin": id, "reward": _t("skin_reward") % [String(s["display_name"]), SkinData.character_name(String(s["character"]))],
			"reward_skin": id, "reward_icon": "", "feat": true})
	out.append({"name": String(CodexData.HYPER_FEAT["name"]), "goal": String(CodexData.HYPER_FEAT["goal"]),
		"progress": 1.0 if Meta.hyper_unlocked else 0.0, "target": 1.0, "earned": Meta.hyper_unlocked,
		"badge": "hyper_badge", "badge_fallback": "hyper_badge", "reward": String(CodexData.HYPER_FEAT["reward"]),
		"reward_skin": "", "reward_icon": "powerup_hyper", "feat": true})
	var cleared := 0  # Characters with their Hyper skin.
	for ch: String in CharacterData.ORDER:
		if Meta.is_skin_unlocked(ch + "_hyper"):
			cleared += 1
	out.append({"name": String(CodexData.HYPER_SKINS_FEAT["name"]), "goal": String(CodexData.HYPER_SKINS_FEAT["goal"]),
		"progress": float(cleared), "target": float(CharacterData.ORDER.size()), "earned": cleared >= CharacterData.ORDER.size(),
		"badge": "", "badge_fallback": "", "badge_skin": CharacterData.DEFAULT_ID + "_hyper", "reward": String(CodexData.HYPER_SKINS_FEAT["reward"]),
		"reward_skin": CharacterData.DEFAULT_ID + "_hyper", "reward_icon": "", "feat": true})
	return out


## The achievement skin unlocked by achievement `id` ("" = none).
static func _skin_for_achievement(id: String) -> String:
	for sid: String in SkinData.ACHIEVEMENT_SKINS:
		var u: Dictionary = SkinData.ACHIEVEMENT_SKINS[sid]["unlock"]
		if String(u["type"]) == "achievement" and String(u["id"]) == id:
			return sid
	# Content wave 2: a universal skin family (UnlockData "skin" row), shown on the Gravecaller.
	for rid: String in Unlocks.rewards_of(id):
		if Unlocks.item_type(rid) == "skin" and SkinData.UNIVERSAL_SKINS.has(rid):
			return "%s_%s" % [CharacterData.DEFAULT_ID, rid]
	return ""


# =====================================================================================
# Texts and number formats
# =====================================================================================

## Detail / reward text `key` (CodexData.TEXT).
static func _t(key: String) -> String:
	return String(CodexData.TEXT.get(key, key))


## `v` as a short number: whole values without decimals ("15"), others
## with up to two ("0.25", "1.5").
static func num(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return "%d" % roundi(v)
	return String.num(v, 2)


## `n` with thousands separators ("12,345").
static func group(n: int) -> String:
	var s := str(absi(n))  # Digits.
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
