# Fix proposal for the adversarial review

This proposes a concrete code change for every finding in `docs/review/ADVERSARIAL_REVIEW.md`, numbered as there.
Nothing here has been applied yet. Each fix lists:
- the files it touches;
- the change, as code where the change is small enough to show;
- whether it keeps the same-seed autotest summaries identical (**gate-safe**), or changes gameplay on purpose (**gameplay change**);
- how to test it.

The proposed code follows the repo conventions: static typing, a comment on every new variable and constant, and new
tunable values in `scripts/data/*.gd` tagged `# TUNING (not in GDD)`. Each change that is a design decision also
gets a GDD §15.0 row.

**One correction to the review.** Finding 15 said the checksum leaves out the RNG. In fact the `rng` field
(`coop_lockstep.gd:988`) does hash the offer and chest RNGs. Only the engine's global stream (`seed(run_seed)`) is
missing, and Godot gives no way to read that stream's state. See §15.

## Batches

Order the work in four batches, each verified on its own:

| Batch | Findings | Why together | Gate |
|---|---|---|---|
| A: shared-link attacks | 1, 2, 4, 5, 6 | All reachable from one link today; all co-op or Web input checks | gate-safe |
| B: progress safety | 3, 10, 13, 14, 18, §20 settings items | All in the save code | gate-safe |
| C: CI and relay ops | 7, 8, 9, 16, 17 | Workflow and Worker only | n/a (no game code) |
| D: gameplay | 11, 12, 19 | Change gameplay; need a balance check | gameplay change |

Batch A is a few hours of work, the most urgent, and gate-safe. Batch D needs the multi-seed checks from CLAUDE.md.

---

## Batch A: shared-link attacks

### Fix 1: the share-link script injection
Files: `scripts/coop/coop_net.gd`, `scripts/ui/coop_lobby.gd`.

**(a) Quote the code in `_on_share`.** This is the root cause. Never paste data into script text unquoted:

```gdscript
# coop_lobby.gd, _on_share()
var js := "(function(k,c,t){var u=location.origin+location.pathname+'?'+k+'='+encodeURIComponent(c);navigator.share({title:'Necropathy',text:t,url:u}).catch(function(){});})(%s,%s,%s)" % [
	JSON.stringify(CoopNetData.JOIN_QUERY_KEY), JSON.stringify(c), JSON.stringify(CoopNetData.SHARE_TEXT % c)]
```

Also run `grep -rn "JavaScriptBridge.eval" scripts`. Every call that carries data must use `JSON.stringify` for each
value. `save_backup.gd:92` and `coop_net.gd:407` already do this correctly.

**(b) Validate the relay's `welcome`.** Accept it only while connecting, with a valid code and a real seat:

```gdscript
# coop_net.gd
## The relay seated us. Refused (the session fails with "protocol") unless we are
## still connecting and the code and seat are well formed.
func _on_welcome(m: Dictionary) -> void:
	var c := normalize_code(String(m.get("code", "")))  # The lobby code as the relay sent it.
	var s := int(m.get("slot", -1))  # Our seat, 0 (host) or 1 (guest).
	if state != State.CONNECTING or not is_valid_code(c) or s < 0 or s >= CoopData.SLOTS:
		_fail("protocol", "welcome")
		return
	code = c
	local_slot = s
	...  # unchanged from here
```

Add a `"protocol"` entry to `CoopNetData.ERROR_TEXT`, for example "The co-op server sent something unexpected.".

**(c) Honour `?relay=` only for test runs and dev builds.** `tools/coop_web_lockstep.js` still works, because it
always passes `?necro_autotest=` as well:

```gdscript
# coop_net.gd, relay_address()
var v := _cli_value("--relay=")
if v == "" and (GameState.autotest or build_id() == CoopNetData.DEV_BUILD_ID):
	v = page_query(CoopNetData.RELAY_QUERY_KEY)  # Tests only: a released page ignores ?relay=.
return v if v != "" else CoopNetData.RELAY_URL
```

Gate-safe. Test: a headless Chromium load of the release build with `?relay=wss://127.0.0.1:1&join=BCDFG` must still
connect to `CoopNetData.RELAY_URL`. Then run `tools/coop_web_lockstep.js`, which must still pass.

### Fix 2: the guest pays an offering it never chose
Files: `scripts/coop/coop_net.gd`, `scripts/core/game.gd`.

The run has to be the same on both machines, so the guest cannot quietly swap in its own offering. Instead it
**refuses a start whose offering for its seat is not the one it sent**:

```gdscript
# coop_net.gd, _on_text(), case "start"
"start":
	if local_slot == 1 and state == State.LOBBY:
		var info: Variant = m.get("info", {})  # The host's start info (untrusted).
		var why := _start_problem(info)  # "" when the start is well formed and matches our loadout.
		if why != "":
			_fail("bad_start", why)
			return
		_begin_run(info as Dictionary, 1)

## Why the host's start `info` must be refused ("" = it is fine): not a Dictionary,
## no config, not one loadout per seat, or our seat's offering / borrowed relic
## differing from the loadout we sent (the guest pays only for its own choice).
func _start_problem(info: Variant) -> String:
	if not (info is Dictionary) or not ((info as Dictionary).get("config") is Dictionary):
		return "shape"
	var los: Variant = (info as Dictionary).get("loadouts")  # Both seats' loadouts.
	if not (los is Array) or (los as Array).size() != CoopData.SLOTS:
		return "loadouts"
	for lo: Variant in los:
		if not (lo is Dictionary):
			return "loadouts"
	var theirs := _clean_loadout((los as Array)[local_slot] as Dictionary, local_slot)  # Our seat, as the host sent it.
	var mine: Dictionary = loadouts[local_slot]  # Our seat, as we sent it.
	if theirs["offering"] != mine["offering"] or theirs["borrowed"] != mine["borrowed"]:
		return "offering"
	if mine["offering"] != "" and Meta.soul_ash < OfferingData.price(mine["offering"]):
		return "offering_cost"  # Checked before the run, so both machines still build the same run.
	return ""
```

Also, in `_begin_run`, replace the `for lo: Dictionary in ...` loop with `_clean_loadout()` for each seat. The typed
loop variable aborts on a non-Dictionary. Then in `game.gd:_pay_offering()`, pay from the **local** copy:

```gdscript
var mine: Dictionary = CoopNet.loadouts[me] if me >= 0 and me < CoopNet.loadouts.size() else {}  # Our own loadout, as we sent it.
Meta.relics.pay_offering(String(mine.get("offering", "")))
```

Gate-safe: the autotest never pays. Test: a `--coop-bot` run, plus a unit-style check in `tools/coop_net_test.py`
that sends a doctored `start` and expects a `bad_start` close.

### Fix 4: `?necro_autotest=` can write the real save
File: `scripts/core/game_state.gd`.

Keep the URL flags for the Chromium perf tools, but **drop every flag that could touch the player's data or send it
anywhere**:

```gdscript
# game_state.gd
## Autotest flags a page URL may never set (they reach the player's save or send
## data out): read only from the real command line.
const WEB_FORBIDDEN_ARGS: Array[String] = ["--meta-save", "--feedback-url=", "--relay="]  # TUNING (not in GDD)

# _web_args(), replacing the append_array line:
for a: String in String(q).split(",", false):
	var banned := false  # True when `a` is a flag the URL may not set.
	for f: String in WEB_FORBIDDEN_ARGS:
		banned = banned or a == f or (f.ends_with("=") and a.begins_with(f))
	if banned:
		push_warning("?necro_autotest: %s ignored on the Web" % a)
	else:
		out.append(a)
```

`--relay=` stays reachable through `?relay=` for test runs, which Fix 1(c) allows. Gate-safe. Test: open
`?necro_autotest=--meta-save`, then check that IndexedDB is untouched.

### Fix 5: players faking the relay's own messages
Files: `server/relay/src/index.js`, `tools/coop_relay.py`. The client change is Fix 1(b).

**Forward only the player message types the protocol defines**, and drop the rest. That is safer than a block-list:

```js
// index.js: the text messages a player may send to the other seat (PROTOCOL.md "Player messages");
// anything else, above all the relay's own welcome / peer / left / error, is dropped.
const PLAYER_TYPES = new Set(["loadout", "settings", "pping", "ppong"]); // "start" has its own case above
...
      default:
        if (!PLAYER_TYPES.has(m.t)) return; // Not a player message: never forwarded.
        return this.relay(att.slot, message);
```

Do the same in `coop_relay.py` before `self.relay(...)`. The set matches every `_send_json` in `coop_net.gd` today (`hello`, `leave` and
`start` are handled by their own cases); keep it in step when a message type is added. Add a case to `tools/coop_relay_check.py` that sends `{"t":"left","slot":0}` and expects nothing to
arrive. Deploy the Worker **before** the game build, because old clients never send other types.

### Fix 6: unchecked partner frames
File: `scripts/coop/coop_lockstep.gd`, plus one constant in `scripts/data/coop_lockstep_data.gd`.

Parse into locals first, check every length, and apply the frame only once it parses fully. A malformed frame counts
as the partner leaving, which reuses the existing clean drop path:

```gdscript
# coop_lockstep_data.gd
## How far ahead of our tick a partner's input or checksum may be and still be
## kept (ticks): the largest input delay plus one full frame of slack.
const FRAME_AHEAD_MAX: int = DELAY_MAX + 255  # TUNING (not in GDD)

# coop_lockstep.gd, _on_frame(): the checks to add
if at + 5 > bytes.size(): return _bad_frame()
var first := bytes.decode_u32(at)
...
if at + 3 > bytes.size(): return _bad_frame()
...
var nc := mini(bytes[at], CoopLockstepData.MAX_COMMANDS_PER_TICK)  # Commands kept (the rest are skipped).
if at + 1 + bytes[at] * 2 > bytes.size(): return _bad_frame()
...
var t := first + i
if t > tick + CoopLockstepData.FRAME_AHEAD_MAX: return _bad_frame()  # A tick no honest partner can be at.
...
# checksums: the same bounds, and only on CHECKSUM_INTERVAL multiples
if t % CoopLockstepData.CHECKSUM_INTERVAL != 0 or t > tick + CoopLockstepData.FRAME_AHEAD_MAX: return _bad_frame()
if n != CoopLockstepData.CHECKSUM_FIELDS.size(): return _bad_frame()

## A partner frame that does not parse or points far ahead: the partner is
## treated as gone (the army bot takes his necromancer over), never a script error.
func _bad_frame() -> void:
	push_warning("CoopLockstep: malformed partner frame dropped")
	_on_partner_gone("stall")
```

To avoid applying half a frame, collect the decoded inputs and sums into two local arrays first, then copy them into
`_inputs` / `_their_sums` once the loop ends. Gate-safe, because honest frames never trip these checks. Test:
`tools/coop_lockstep_gate.py`, plus a fuzz step in `coop_net_test.gd` that sends truncated and far-future frames.

---

## Batch B: progress safety

### Fix 3: never write over a save from a newer build
Files: `scripts/core/meta_progress.gd`, `scripts/core/save_backup.gd`, title screen (`scripts/ui/main_menu.gd`).

```gdscript
# meta_progress.gd
func can_write() -> bool:
	if load_status == "newer":
		return false  # A newer build's save: this build would drop what it does not know.
	return (not GameState.autotest or GameState.autotest_meta_save) and not GameState.victory_preview
```

The title screen shows one crimson line while `Meta.load_status == "newer"`: "This save is from a newer version.
Progress is not saved until you update." Then in `SaveBackup.decode()`, after the parse:

```gdscript
if int(cfg.get_value("meta", "save_version", 0)) > MetaData.SAVE_VERSION:
	return ""  # A newer build's save: refused rather than cut down.
```

Gate-safe. Test: write a save with `save_version = 99`, start, play a run, then check that the file is unchanged.

### Fix 10: no undo after restoring a backup code
File: `scripts/core/save_backup.gd`, plus a Settings → Save line.

```gdscript
# save_backup_data.gd
## The copy of the progress kept by the last restore (Settings → Save → Undo).
const PRE_RESTORE_SUFFIX: String = ".pre_restore"  # TUNING (not in GDD)

# import_code(), before writing the tmp file:
if FileAccess.file_exists(Meta.save_path):
	DirAccess.copy_absolute(Meta.save_path, Meta.save_path + SaveBackupData.PRE_RESTORE_SUFFIX)
```

**Undo** is `import_code()` run on the `.pre_restore` text. It is reversible, so it acts at once, per the
`ConfirmDialog` rule. Make the existing confirm text show what the code holds: Soul Ash, runs, and the furthest
stage. Refuse a code with no `[meta] runs` key, so an all-empty code can no longer wipe a profile. Gate-safe.

### Fix 13: save codes parsed as Godot text values
File: `scripts/core/save_backup.gd`.

```gdscript
# save_backup_data.gd
## Text a save never contains: Godot value constructors that build objects or load
## resources. A code holding any of them is refused before it is parsed.
const FORBIDDEN_TOKENS: Array[String] = ["Object(", "Resource(", "SubResource(", "ExtResource("]  # TUNING (not in GDD)
## The longest code accepted (characters), checked before decoding.
const MAX_CODE_CHARS: int = 1_500_000  # TUNING (not in GDD) above any real save's gzipped base64

# decode(): right after the strip
if c.length() > SaveBackupData.MAX_CODE_CHARS:
	return ""
# decode(): before cfg.parse(text)
for bad: String in SaveBackupData.FORBIDDEN_TOKENS:
	if text.contains(bad):
		return ""
```

Gate-safe. Test: a code that holds `x = Object(Node, "name": "a")` must be refused.

### Fix 14: recover the temp file after a crash
File: `scripts/core/meta_progress.gd`. Do the same in `settings.gd`, which should also start writing through a temp
file.

```gdscript
# load_save(), before the ERR_FILE_NOT_FOUND branch
if last_load_error != OK and FileAccess.file_exists(save_path + ".tmp"):
	var probe := ConfigFile.new()  # The last save that was written but never renamed.
	if probe.load(save_path + ".tmp") == OK and probe.has_section_key("meta", "save_version"):
		if FileAccess.file_exists(save_path):
			DirAccess.copy_absolute(save_path, save_path + ".corrupt")
		DirAccess.rename_absolute(save_path + ".tmp", save_path)
		last_load_error = cfg.load(save_path)
		print("[meta] recovered the save from %s.tmp" % save_path)
```

In `save()`, copy the current `save.cfg` to `save.cfg.bak` before the rename, and name corrupt copies
`save.cfg.corrupt.<n>` (the lowest free `n`). Gate-safe, since the autotest never writes.

### Fix 18: refunds at today's prices
File: `scripts/core/meta_progress.gd`.

Add a `[upgrades_paid]` section: `id → Soul Ash paid`, increased by `purchase()`. `refund_all()` and
`_enforce_prerequisites()` refund `paid.get(id, MetaData.cost_up_to(id, tier))`; the fallback covers old saves.
When load clamps a tier down to a lowered `max_tier`, refund the difference. Bump `SAVE_VERSION` to 3. The migration
fills `[upgrades_paid]` from the current prices, which is what those saves get today anyway. Gate-safe.

### §20 settings items
- In `settings.gd`, read each value through a typed helper (`typeof(v) == TYPE_BOOL`, else the default), the way
  `Meta._read_int` does.
- When two actions share a key, keep the first binding and drop the second.
- Skip `load_settings()` under the autotest unless `--meta-save` is passed, so the CLAUDE.md rule holds as written.
- In `SaveMigration.run()`, migrate each file whose new copy is missing, instead of stopping as soon as either exists.

---

## Batch C: CI and relay operations

### Fix 7: lobby code brute force and quota exhaustion
Files: `server/relay/src/index.js`, `tools/coop_relay.py`, `scripts/data/coop_net_data.gd`, `server/relay/PROTOCOL.md`.

1. **Longer codes:** `CODE_LENGTH` goes from 5 to 6 in all three places, raising the space from 3.2M to 64M. The
   join pad gains one box. Old and new clients cannot pair anyway, because the build ids differ.
2. **Rate-limit joins.** Add a Cloudflare WAF rate-limiting rule on `/lobby/*/ws` (for example 20 a minute per IP) in
   the dashboard; documented in `docs/coop/RELAY_SETUP.md`. In code, count failed joins (`no_lobby`) per IP with the
   same mechanism as `mayCreate`.
3. **Evict instead of clear.** When `createLog.size > 10000`, delete the 1000 oldest entries (a `Map` iterates in
   insertion order) instead of calling `createLog.clear()`.

Gate-safe. Test: `tools/coop_relay_check.py` and `coop_net_test.py`.

### Fix 8: an older build replacing the live site
File: `.github/workflows/ci.yml` (`publish-pages-repo`).

```yaml
  publish-pages-repo:
    needs: [test, export]
    concurrency:
      # One publish at a time, in push order; a newer run waits for the running one.
      group: pages-repo
      cancel-in-progress: false
    ...
      - name: Push the build to the Pages repository
        if: env.PAGES_TOKEN != ''
        env:
          # GH_TOKEN: reads this repository's main tip (the job's own token, read-only).
          GH_TOKEN: ${{ github.token }}
        run: |
          # Publish only the commit main points at now: an older push, or a tag on an
          # older commit, never replaces a newer live build.
          TIP=$(git ls-remote "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" refs/heads/main | cut -f1)
          if [ "$TIP" != "$GITHUB_SHA" ]; then echo "::notice::$GITHUB_SHA is not main's tip ($TIP); not published."; exit 0; fi
          ...  # the existing steps
```

A `v*` tag on main's tip still publishes, as CLAUDE.md describes, and a tag on an old commit no longer does. For
one-click rollback, keep the previous build: before the force-push, fetch the target's `main` and push it to a
`previous` branch.

### Fix 9: relay deploy gates and the unpinned wrangler
Files: `.github/workflows/ci.yml` (`deploy-relay`), `server/relay/package-lock.json` (new).

- `needs: [coop-net, test, export]`.
- Commit `package-lock.json` (from `npm install` once, locally) and run `npm ci --no-audit --no-fund`.
- Move `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` from the job `env:` into the deploy step's own `env:`. The
  skip check can read them as `secrets.*` in its `if:` through a job-level boolean, for example
  `HAS_CF: ${{ secrets.CLOUDFLARE_API_TOKEN != '' }}`.

### Fix 16: permissions and action pinning
- At the top of `ci.yml`:

  ```yaml
  permissions:
    # Read-only by default; jobs that publish raise their own.
    contents: read
  ```

- Pin `softprops/action-gh-release` to a full commit SHA, with the tag in a comment. Optionally pin the `actions/*`
  steps too, and add Dependabot for `github-actions` so the SHAs stay current.

### Fix 17: publishing gates
- Add `coop-lockstep` to `publish-pages-repo`'s `needs`. That costs about 6 more minutes from push to live, which is
  an owner decision: record it in GDD §15.0 "Parallel CI and lean testing". If the owner keeps today's speed, make a
  red `coop-lockstep` on `main` open an issue instead.
- Add a **Web smoke** step to `export`, after the patch scripts: serve `build/web` and load it with Playwright
  Chromium. The step passes if the canvas starts, the page logs no `ERROR`, and the title screen's ready line prints
  within 60 s. It can reuse `tools/mobile_web_perf.js`'s server code.

---

## Batch D: gameplay (balance check needed)

### Fix 11: area attacks skipping summons
Files: the 7 loops found by
`grep -rn -B10 "combat.damage_unit(" scripts | grep "for u in h.units"`, which is the complete list:
- `seraphine_hazards.gd:339, 387`
- `eye/vhalneth_hazards.gd:146, 181`
- `eye/arm_kit.gd:138`
- `shogunate/amaterasu_hazards.gd:220`
- `empire/assembly_director.gd:232`

At each, iterate over a copy. The existing `u.active` checks then skip the ones that died:

```gdscript
for u in h.units.duplicate():  # A copy: a summon killed here swap-pops h.units (HordeDirector.on_unit_died()).
```

For a one-path guard, add `HordeDirector.units_snapshot() -> Array` (it returns `units.duplicate()`, documented as
"use this whenever the loop can kill") and use it at all seven sites. **Gameplay change:** these boss attacks get
stronger. Run 8 seeds × `--policy=army --mortal` on `sanctum`, `spire`, `assembly` and `sun_road` against the balance
table. Tune the hazard damage in the data files only if the army's min HP or Alaric-style boss kill rates drop below
target. Record a GDD §15.0 row.

### Fix 12: the Ferry of Souls bypassing "Steel has no soul"
File: `scripts/abilities/spells/river_styx.gd`.

Keep Acts I, II, IV and V exactly as they are: same class, same tags, same stats. Change only the cases the owner rule
covers:

```gdscript
func on_enemy_killed(e: Enemy) -> void:
	var cd := game.character.innate_value("ferry_cooldown")  # 0 for every other character.
	if cd <= 0.0 or game.elapsed < _ferry_ready or rivers.is_empty() or not e.leaves_corpse() \
			or e.is_boss or e.is_miniboss or e.is_reckoning:
		return  # No body to ferry: a structure, an Act III machine, a swallowed corpse, or a boss-class foe.
	if not in_river(e.position, e.radius):
		return
	_ferry_ready = game.elapsed + cd
	var life := game.character.innate_value("ferry_life")  # Seconds the ferried Risen lasts.
	var u: SummonedUnit = null  # The ferried Risen (null when the army is full).
	if e.rises_as_gunner():
		u = game.horde.raise_corpse(RiverStyxData.FERRY_CLASS, e.position, life, 1.0, 1.0, "ferry_risen", "risen", true)
	else:
		u = game.horde.spawn_temporary(RiverStyxData.FERRY_CLASS, e.position, life, 1.0, 1.0)
	if u != null:
		game.stat_add("ferry_risen", 1.0)
```

A related latent crash: `HordeDirector.raise_corpse()` dereferences `u` without a null check, while River Styx's
current code shows that `spawn_temporary()` can return null. Add `if u == null: return null` after the
`spawn_temporary` call in `raise_corpse()` (`horde_director.gd:745`). The Lich caller (`summon_evolutions.gd:292`) then
needs `if u == null: return`.

**Gameplay change**, but only with the Ferrywoman on Act III stages or against bosses. Stages 1–12 with the
Gravecaller stay identical. Test: `--character=ferrywoman --spells=river_styx --stage=wastes` must report
`ferry_risen` only from cyborg or organic kills.

### Fix 19: one Ferryman's Toll cap shared in co-op
File: `scripts/core/combat_resolver.gd`.

```gdscript
## Ferryman's Toll, per seat (index 0 in solo, CoopSession.bound in co-op): game
## time each seat's current one-second heal window started.
var _toll_window_t: PackedFloat64Array = PackedFloat64Array([-1.0, -1.0])
## Ferryman's Toll, per seat: HP healed in that seat's current window (capped at
## RiverStyxData.TOLL_HEAL_CAP_PER_S).
var _toll_window: PackedFloat64Array = PackedFloat64Array([0.0, 0.0])

# _ferrymans_toll(): use index `k`
var k := game.coop.bound if game.coop != null else 0  # The seat being healed.
```

Solo reads index 0 with the same arithmetic, so it is gate-safe for solo; co-op changes slightly. Run the
`coop-lockstep` gate afterwards, because both machines change the same way.

---

## Deliberately not proposed now

- **Hashing the global RNG (finding 15).** The engine has no way to read the stream's state. Hashing it would mean
  moving every gameplay `randf()` onto a game-owned `RandomNumberGenerator`: hundreds of call sites, and a change to
  every same-seed summary. It isn't worth it while the existing fields catch divergence within a few checksum
  intervals. Do take the cheap half: in `_compare`, a field-count difference counts as a desync (Fix 6 already
  refuses such frames).
- **Ownership checks on a partner's relics and unlocks (§20).** Stats are already clamped, and co-op is played with
  friends. Revisit if co-op ever gets public matchmaking.
- **Encrypting the `.pck` (§20).** It only matters if the source repo must stay secret. Godot's PCK encryption key is
  inside the shipped binary anyway.

## Definition of done

Per batch:
- `godot --headless --import` is clean.
- The default, `--mortal` and `--policy=army` autotests show zero `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines and
  `stuck_units=0`.
- Batches A–C: stages 1–12 same-seed summaries identical, plus `coop_lockstep_gate.py`.
- Batch D: the multi-seed balance screen (8 seeds, confirm with 16) and a GDD §15.0 row per gameplay change.
- README and GDD §15.0 updated for the new owner-visible behaviour: restore Undo, the newer-save notice, 6-letter
  codes, and the release build ignoring `?relay=` / some `?necro_autotest=` flags.
