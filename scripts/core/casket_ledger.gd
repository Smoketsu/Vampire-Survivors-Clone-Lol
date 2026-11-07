## CasketLedger — the logic and save side of the Recolour Caskets (owner request,
## Oct 2026, GDD §15.0 "Recolour Caskets (owner request, Oct 2026)"; numbers in
## CasketData): the prize pool, the weighted roll with its pity counter, opening a
## casket (Soul Ash off, the prize owned, saved) and wearing a prize. The Meta
## autoload owns one instance as `Meta.caskets` and calls reset() / read() /
## write() from its own _reset() / load_save() / save(), so the save stays one
## file with one load path:
##   [caskets]       seed = the save's casket seed (0 = not drawn yet),
##                   opened = caskets opened, since_epic = caskets in a row below
##                   CasketData.PITY_TIER (the pity counter), spent = Soul Ash paid,
##   [casket_skins]  <SkinData.CASKET_SKINS id> = true for every one won.
## The sections are additive: an older save has none and reads as nothing opened
## (no SAVE_VERSION step needed); the recolours it bought stay owned
## (Meta.owned_recolours, [recolours]). Every prize lands in the same places the
## old purchases did: a recolour in Meta.owned_recolours, a casket skin in
## `won_skins` (read by Meta.is_skin_unlocked()).
## A PRIZE is a Dictionary {"skin": SkinData id, "recolour": RecolourData id
## ("" = the skin itself, a casket-only skin), "tier": CasketData tier id}.
## Randomness never touches gameplay RNG: each opening seeds its own
## RandomNumberGenerator from (seed, opened) (rng_for()), the seed itself drawn
## once per save with a fresh randomize() (CasketData.AUTOTEST_SEED under the
## autotest), so a save's results are reproducible. Menu-side and cosmetic only:
## nothing here reaches a run. Every write goes through Meta.save() (never under
## the autotest, Meta.can_write()).
class_name CasketLedger
extends RefCounted

## The save's casket seed (any non-zero int; 0 = not drawn yet, ensure_seed()).
var casket_seed: int = 0
## Caskets opened so far (0..; also the second half of each opening's seed).
var opened: int = 0
## Caskets in a row whose prize was below CasketData.PITY_TIER (0..PITY_AFTER;
## the pity counter: at PITY_AFTER the next one is PITY_TIER or better).
var since_epic: int = 0
## Soul Ash paid for caskets so far (never refunded).
var spent: int = 0
## SkinData.CASKET_SKINS id -> true for every casket-only skin won.
var won_skins: Dictionary = {}


## A fresh profile: nothing opened, no seed yet.
func reset() -> void:
	casket_seed = 0
	opened = 0
	since_epic = 0
	spent = 0
	won_skins = {}


# =====================================================================================
# Save / load (called by Meta)
# =====================================================================================

## Reads [caskets] and [casket_skins] from `cfg` (missing = the fresh profile;
## bad values are clamped, unknown skins dropped).
func read(cfg: ConfigFile) -> void:
	reset()
	casket_seed = _int(cfg.get_value("caskets", "seed", 0), 0)
	opened = maxi(0, _int(cfg.get_value("caskets", "opened", 0), 0))
	since_epic = clampi(_int(cfg.get_value("caskets", "since_epic", 0), 0), 0, CasketData.PITY_AFTER)
	spent = maxi(0, _int(cfg.get_value("caskets", "spent", 0), 0))
	for id: String in SkinData.CASKET_SKINS:
		var v: Variant = cfg.get_value("casket_skins", id, false)
		if typeof(v) == TYPE_BOOL and bool(v):
			won_skins[id] = true


## Writes the ledger into `cfg` (Meta.save()).
func write(cfg: ConfigFile) -> void:
	cfg.set_value("caskets", "seed", casket_seed)
	cfg.set_value("caskets", "opened", opened)
	cfg.set_value("caskets", "since_epic", since_epic)
	cfg.set_value("caskets", "spent", spent)
	for id: String in SkinData.CASKET_SKINS:
		if won_skins.has(id):
			cfg.set_value("casket_skins", id, true)


## `v` as an int (`fallback` when it is not a number).
static func _int(v: Variant, fallback: int) -> int:
	return int(v) if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT else fallback


# =====================================================================================
# The prize pool
# =====================================================================================

## True when casket-only skin `id` was won.
func has_won(id: String) -> bool:
	return won_skins.has(id)


## Every prize the player can still win, in SkinData × RecolourData order.
func prize_pool() -> Array[Dictionary]:
	return pool_from(skin_rows())


## Every skin row (SkinData.skin() with its "id" added), in SkinData.all_ids() order.
static func skin_rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []  # Rows.
	for id: String in SkinData.all_ids():
		var row := SkinData.skin(id).duplicate()  # A copy, so "id" can be added.
		row["id"] = id
		out.append(row)
	return out


## The prizes of skin rows `rows` (each a SkinData.skin() row with its "id";
## tools/ossuary_check passes rows of its own): a casket-only skin not won yet
## (the Legendary tier), then every recolour an unlocked skin offers and does not
## own (its CasketData.RECOLOUR_TIERS tier). No duplicates: a won prize is owned.
func pool_from(rows: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []  # Prizes.
	for v: Variant in rows:
		var row: Dictionary = v
		var id := String(row.get("id", ""))  # Skin id.
		if id == "":
			continue
		var kind := String(row.get("kind", ""))  # SkinData kind.
		if kind == "casket" and not won_skins.has(id):
			out.append({"skin": id, "recolour": "", "tier": CasketData.CASKET_SKIN_TIER})
			continue
		if not Meta.skin_row_unlocked(id, row):
			continue
		var have: PackedStringArray = Meta.owned_recolours.get(id, PackedStringArray())  # Owned for this skin.
		for rc: String in RecolourData.ids_for_kind(kind):
			if not have.has(rc):
				out.append({"skin": id, "recolour": rc, "tier": recolour_tier(rc)})
	return out


## The casket tier of recolour `rc` (CasketData.RECOLOUR_TIERS; "common" when unlisted).
static func recolour_tier(rc: String) -> String:
	return String(CasketData.RECOLOUR_TIERS.get(rc, CasketData.TIER_ORDER[0]))


## `pool` grouped by tier: tier id -> Array of its prizes (every CasketData tier
## present, empty ones too; pool order kept inside a tier).
static func by_tier(pool: Array) -> Dictionary:
	var out := {}  # Tier -> prizes.
	for t: String in CasketData.TIER_ORDER:
		out[t] = []
	for p: Variant in pool:
		var tier := String((p as Dictionary).get("tier", ""))  # The prize's tier.
		if out.has(tier):
			(out[tier] as Array).append(p)
	return out


## The chance (0..1) of each tier for the next casket from `pool`, weights
## renormalised over the tiers that hold a prize (an empty tier is absent). The
## pity casket is not shown here (pity_due()).
static func odds(pool: Array) -> Dictionary:
	var groups := by_tier(pool)  # Tier -> prizes.
	var total := 0.0  # Sum of the weights in play.
	for t: String in CasketData.TIER_ORDER:
		if not (groups[t] as Array).is_empty():
			total += float(CasketData.TIERS[t]["weight"])
	var out := {}  # Tier -> chance.
	if total <= 0.0:
		return out
	for t: String in CasketData.TIER_ORDER:
		if not (groups[t] as Array).is_empty():
			out[t] = float(CasketData.TIERS[t]["weight"]) / total
	return out


## True when `pool` holds a prize at CasketData.PITY_TIER or better.
static func has_pity_prize(pool: Array) -> bool:
	return _best_pity_tier(by_tier(pool)) != ""


## The best non-empty tier at CasketData.PITY_TIER or above in `groups`
## (by_tier()); "" when there is none.
static func _best_pity_tier(groups: Dictionary) -> String:
	var floor_i := CasketData.TIER_ORDER.find(CasketData.PITY_TIER)  # Index of the pity floor.
	for i in range(CasketData.TIER_ORDER.size() - 1, floor_i - 1, -1):
		var t := CasketData.TIER_ORDER[i]  # Tier, best first.
		if not (groups[t] as Array).is_empty():
			return t
	return ""


## True when the next casket from `pool` is a pity casket (since_epic reached
## PITY_AFTER and a PITY_TIER-or-better prize exists).
func pity_due(pool: Array) -> bool:
	return since_epic >= CasketData.PITY_AFTER and has_pity_prize(pool)


## Caskets until the pity casket, counting the pity one itself (1..PITY_AFTER + 1).
func pity_left() -> int:
	return CasketData.PITY_AFTER + 1 - mini(since_epic, CasketData.PITY_AFTER)


## One prize from `pool` with `rng`, after `since` caskets in a row below the
## pity tier: the pity casket takes the best non-empty tier at PITY_TIER or above
## (when one exists); otherwise a tier by weight among the non-empty tiers, then
## a uniform prize in it. {} for an empty pool. Pure: the same pool, rng state and
## `since` give the same prize.
static func roll(pool: Array, rng: RandomNumberGenerator, since: int) -> Dictionary:
	if pool.is_empty():
		return {}
	var groups := by_tier(pool)  # Tier -> prizes.
	var tier := ""  # The tier rolled.
	if since >= CasketData.PITY_AFTER:
		tier = _best_pity_tier(groups)
	if tier == "":
		var chances := odds(pool)  # Tier -> chance (non-empty tiers only).
		var r := rng.randf()  # 0..1.
		var acc := 0.0  # Running sum of the chances.
		for t: String in CasketData.TIER_ORDER:
			if not chances.has(t):
				continue
			tier = t  # The last non-empty tier also catches float rounding.
			acc += float(chances[t])
			if r < acc:
				break
	var list: Array = groups[tier]  # Prizes of that tier.
	return list[rng.randi_range(0, list.size() - 1)]


# =====================================================================================
# Opening
# =====================================================================================

## Why a casket cannot be opened now: "" (it can), "empty" (no prize left: the
## pool is checked first) or "cost" (not enough Soul Ash).
func open_block() -> String:
	if prize_pool().is_empty():
		return "empty"
	if Meta.soul_ash < CasketData.PRICE:
		return "cost"
	return ""


## Draws the save's casket seed the first time (a fresh randomize(); the fixed
## CasketData.AUTOTEST_SEED under the autotest). Never 0.
func ensure_seed() -> void:
	if casket_seed != 0:
		return
	if GameState.autotest:
		casket_seed = CasketData.AUTOTEST_SEED
		return
	var r := RandomNumberGenerator.new()  # Menu-side only: never gameplay RNG.
	r.randomize()
	casket_seed = maxi(1, int(r.randi()))


## The generator of opening number `count` (0-based): seeded from the save's
## casket seed and `count`, so each opening is reproducible per save.
func rng_for(count: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [casket_seed, count])
	return rng


## Opens one casket: rolls a prize from the pool, takes CasketData.PRICE Soul
## Ash, makes the prize owned, moves the pity counter, saves and emits
## Meta.changed. Returns the prize, or {} (nothing charged) when blocked
## (open_block()).
func open() -> Dictionary:
	var pool := prize_pool()  # What can be won.
	if pool.is_empty() or Meta.soul_ash < CasketData.PRICE:
		return {}
	ensure_seed()
	var prize := roll(pool, rng_for(opened), since_epic)  # The prize.
	Meta.soul_ash -= CasketData.PRICE
	spent += CasketData.PRICE
	opened += 1
	var good := CasketData.TIER_ORDER.find(String(prize["tier"])) >= CasketData.TIER_ORDER.find(CasketData.PITY_TIER)  # Pity tier or better.
	since_epic = 0 if good else mini(since_epic + 1, CasketData.PITY_AFTER)
	_grant(prize)
	Meta.save()
	Meta.changed.emit()
	return prize


## Makes `prize` owned: a recolour joins its skin's owned set, a casket skin is won.
func _grant(prize: Dictionary) -> void:
	var skin := String(prize["skin"])  # Skin id.
	var rc := String(prize["recolour"])  # Recolour ("" = the skin itself).
	if rc == "":
		won_skins[skin] = true
		return
	var have: PackedStringArray = Meta.owned_recolours.get(skin, PackedStringArray())  # Owned for the skin.
	if not have.has(rc):
		have.append(rc)
	Meta.owned_recolours[skin] = have


## Wears `prize` (the reveal's Wear button): a recolour becomes its skin's worn
## recolour (Meta.set_chosen_recolour), a casket skin its character's worn skin.
## Free and reversible (the pre-run skin row changes it back). Saves.
func wear(prize: Dictionary) -> void:
	var skin := String(prize.get("skin", ""))  # Skin id.
	var rc := String(prize.get("recolour", ""))  # Recolour ("" = the skin itself).
	if skin == "" or not Meta.is_skin_unlocked(skin):
		return
	if rc != "":
		Meta.set_chosen_recolour(skin, rc)
		return
	Meta.chosen_skins[String(SkinData.skin(skin)["character"])] = skin
	Meta.save()


## True when `prize` is what the player wears now (its recolour on its skin, or
## the casket skin on its character).
func is_worn(prize: Dictionary) -> bool:
	var skin := String(prize.get("skin", ""))  # Skin id.
	var rc := String(prize.get("recolour", ""))  # Recolour ("" = the skin itself).
	if skin == "":
		return false
	if rc != "":
		return Meta.chosen_recolour(skin) == rc
	return Meta.chosen_skin(String(SkinData.skin(skin).get("character", ""))) == skin


## The collection count: {"recolours": owned, "recolours_total": owned + still
## winnable, "skins": casket skins won, "skins_total": SkinData.CASKET_SKINS size}.
func collection() -> Dictionary:
	var owned := 0  # Recolours owned, all skins.
	for id: String in SkinData.all_ids():
		owned += Meta.owned_recolour_ids(id).size()
	var left := 0  # Recolour prizes still in the pool.
	for p: Dictionary in prize_pool():
		if String(p["recolour"]) != "":
			left += 1
	return {"recolours": owned, "recolours_total": owned + left, "skins": won_skins.size(), "skins_total": SkinData.CASKET_SKINS.size()}


## UI name of `prize`: "<Skin> · <Recolour>" (a casket skin: its name alone).
static func prize_name(prize: Dictionary) -> String:
	var row := SkinData.skin(String(prize.get("skin", "")))  # The skin ({} = unknown).
	var skin_name := String(row.get("display_name", "?"))  # Its name (a default skin: the character's).
	var rc := String(prize.get("recolour", ""))  # Recolour ("" = the skin itself).
	return skin_name if rc == "" else "%s · %s" % [skin_name, RecolourData.display_name(rc)]
