# Adversarial code review and fix proposal (Oct 31, 2026)

This is a read-only review of `main` as of commit `7b0f60a`, plus the published build in `Smoketsu/NecropathyPlay`.
It covers four areas: online co-op (the relay and the lockstep), saves and progression, the gameplay simulation, and
CI / the Web build / tooling. Every finding below was traced in the code. Where the evidence depends on engine
behaviour that was not tested here, it is marked **plausible**; the rest are **confirmed**. No code was changed.

**Severity** means how bad the worst real outcome is, taking into account how likely it is:
- **High:** a player can lose progress, or a stranger can attack a player through a link.
- **Medium:** the game breaks, can be griefed, or a stated design rule is broken.
- **Low:** hardening, or small fairness problems.

## Summary

| # | Area | Finding | Severity | Impact in one line |
|---|---|---|---|---|
| 1 | Web / co-op | A crafted join link (`?relay=`) and a fake relay can run script on the game's site | High | Read, change or wipe the victim's save; attack other pages on `smoketsu.github.io` |
| 2 | Co-op | The guest pays whatever offering the host's start message names | High | A tampered host or relay spends the guest's Soul Ash for good |
| 3 | Saves | A save from a newer build is cut down by an older build | High | Unlocks, records and deep Ossuary tiers lost for good after a downgrade |
| 4 | Web | `?necro_autotest=--meta-save` on the public build writes bot results into the real save | Medium-High | A crafted link changes or ruins a player's progress |
| 5 | Co-op | The relay forwards its own control messages (`welcome`, `left`, ...) from players | Medium | A partner can fake a drop, change seats or end the session |
| 6 | Co-op | Partner frames are not bounds-checked | Medium | Unbounded memory growth: the phone tab crashes; script errors mid-run |
| 7 | Relay | Lobby codes can be brute-forced; the create limit resets itself | Medium | Strangers take seats in lobbies; the free-plan quota is used up, so co-op is down |
| 8 | CI | Publishing to Pages has no concurrency group and force-pushes; a `v*` tag on any commit publishes | Medium | An older build can replace the live site |
| 9 | CI | The relay deploys without the game tests, with an unpinned `wrangler` that holds the Cloudflare token | Medium | A relay out of step with the game goes live; supply-chain exposure of the token |
| 10 | Saves | Restoring a backup code keeps no undo copy | Medium | A wrong or empty code replaces real progress for good |
| 11 | Simulation | Area attacks skip a summon each time one dies inside the loop | Medium | Boss novas and slams hit fewer summons than intended |
| 12 | Simulation | The Ferrywoman's Ferry of Souls bypasses "Steel has no soul" and the one raise path | Medium | Act III machines and bosses rise as Risen, against an owner rule |
| 13 | Saves | Save codes go through Godot's text-value parser, which accepts `Object(...)` | Low-Medium (plausible) | A pasted code can create engine objects or load resources |
| 14 | Saves | The temp file and rename are not crash-safe on Windows; a leftover `.tmp` is never recovered | Low-Medium (plausible) | A power cut during a save resets the profile |
| 15 | Co-op | Checksum gaps: comparison stops at the shorter list; RNG state and cooldowns are not hashed | Low-Medium | Desyncs are caught late, or not at all against a tampered client |
| 16 | CI | No top-level `permissions:`; third-party actions pinned by tag | Low-Medium | A wider token blast radius if an action is compromised |
| 17 | CI | Pages publishing does not wait for `coop-lockstep`; the Web build is never smoke-tested | Low-Medium | A co-op determinism bug or a Web-only break ships live |
| 18 | Saves | Refund all pays today's prices, not what was paid | Low | A cost change in a patch becomes a Soul Ash exploit or a loss |
| 19 | Simulation | Co-op players share one Ferryman's Toll healing cap | Low | Each player heals less than in solo |
| 20 | Misc | Smaller items (listed in §20) | Low | |

Suggested order of fixes: **1, 2, 4, 5** first, since all four are reachable from a single shared link today. Then
**3, 10, 8**, which are about losing progress or losing the live build. The rest can follow in one batch.

---

## 1. Script injection through a crafted join link (High, confirmed chain)

**Where**
- `scripts/coop/coop_net.gd:396-401` (`relay_address()`) accepts any relay URL from the page's `?relay=` on the live
  build. The comment says it is for tests, but nothing restricts it to tests.
- `scripts/coop/coop_net.gd:618` (`_on_welcome`) stores the code the relay sends with
  `code = String(m.get("code", ""))`, without calling `is_valid_code()`. The `?join=` path does call it (line 414).
- `scripts/ui/coop_lobby.gd:337-339` (`_on_share`) pastes that code unquoted into a script string and runs it with
  `JavaScriptBridge.eval(js, true)`:
  `"...'?%s=%s';navigator.share(...)" % [JOIN_QUERY_KEY, c, ...]`.

**Impact.** An attacker sends `https://smoketsu.github.io/NecropathyPlay/?relay=wss://evil.example&join=ABCDE`. Their
relay seats the victim and answers with a `code` such as `x';fetch(...)//`. When the victim taps **Share**, which
shows on most phones, that script runs on `smoketsu.github.io`. From there it can read, rewrite or delete the
IndexedDB save, and it also has access to every other GitHub Pages site under that account (same origin). The same
fake relay is also the way in for findings 2, 5 and 6.

**Fix**
1. Honour `?relay=` only on dev builds (`build_id() == DEV_BUILD_ID`) or for a short allow-list in `CoopNetData`.
2. In `_on_welcome`, normalise the code and drop the connection (`_fail("protocol")`) if `is_valid_code()` fails.
   Accept `welcome` only while the state is CONNECTING, and `slot` only if it is in `{0, 1}`.
3. In `_on_share`, build the URL with `JSON.stringify(c)` (or `encodeURIComponent` on the JS side) instead of raw
   `%s`. Treat every `JavaScriptBridge.eval` call that carries data as an injection point and quote it the same way.

## 2. A tampered host or relay can spend the guest's Soul Ash (High, confirmed)

**Where.** `coop_net.gd:666-679` (`_begin_run`) copies `start.info.loadouts` exactly as received; it only casts
`meta_levels` to int, and `_clean_loadout()` is never run on them. Then `game.gd:1033-1035` does:
```gdscript
if me >= 0 and me < los.size():
    Meta.relics.pay_offering(String((los[me] as Dictionary).get("offering", "")))
```
In other words, the guest pays for the offering that the **host's** message puts in the **guest's** seat, out of the
guest's own save (`relic_ledger.gd:236-243` deducts and saves).

**Impact.** On every run, the guest can be charged for a Grave Offering they never chose. The Soul Ash is gone for
good. Some related failures:
- A `start` message with fewer than 2 loadouts silently turns the guest's run into a solo run (`game.gd:553`).
- A loadout that is not a Dictionary aborts `_begin_run`, and the guest is stuck in the lobby.

**Fix.** The guest keeps the loadout it last sent (`_pending_loadout`) and pays only from that. It refuses a `start`
in any of these cases:
- `loadouts.size() != CoopData.SLOTS`;
- `loadouts[local_slot]` differs from what it sent;
- `config` or a loadout is not a Dictionary.

Run `_clean_loadout()` on both seats on the receiving side too. In `game.gd`, if `pay_offering()` fails, drop the
offering instead of applying it anyway, as the solo branch already does.

## 3. A save from a newer build is silently cut down (High, confirmed)

**Where.** `meta_progress.gd:1346-1347` sets `load_status = "newer"`, but nothing ever reads that value.
`can_write()` (line 1223) checks only the autotest flags. `save()` writes only the ids this build knows, and load
clamps tiers to this build's `max_tier` (line 1323). `SaveBackup.decode()` accepts any `save_version`.

**Impact.** Any downgrade loses data for good. Ways it happens:
- a stale cached Web build (Pages caches for about 10 min after a deploy);
- an older desktop zip;
- a backup code taken on a newer build and restored on an older one.

Unlocks, records, achievements, casket prizes and Ossuary tiers 6-10 that the older build does not know are dropped.
The first codex save comes on the first frame anything is met, so the loss is near-immediate.

**Fix.** When `load_status == "newer"`, make `can_write()` return `false` and show a one-line notice: "This save is
from a newer version; progress will not be saved." In `SaveBackup.import_code()`, refuse codes whose `save_version`
is above `MetaData.SAVE_VERSION`. Optionally, keep unknown sections and keys and write them back unchanged
(round-trip), so even a partial downgrade loses nothing.

## 4. `?necro_autotest=` on the public build can write into the real save (Medium-High, confirmed reachable)

**Where.** `scripts/core/game_state.gd:350-362` (`_web_args`) turns the URL parameter into `--autotest` plus the given
flags on every Web build. `--meta-save` (line 449) sets `autotest_meta_save`. That makes `Meta.load_save()` run and
`can_write()` return true (`meta_progress.gd:1224`).

**Impact.** A link like `?necro_autotest=--meta-save,--meta=max,--rewards=on` makes the victim's tab play a bot run
and write its results into their real save. That means unearned Soul Ash, records and unlocks, or a save they did not
want changed. Without `--meta-save` the parameter is harmless, because nothing is loaded or written.

**Fix.** Never accept `--meta-save` (or `--feedback-url`) from the URL. Better, honour `necro_autotest` only on dev
builds or when a build-time flag is set. CI can export a separate test build for the Chromium perf tools
(`tools/mobile_web_perf.js`, `coop_web_perf.js`) if they need it on a release build.

## 5. Players can fake the relay's control messages (Medium, confirmed)

**Where.** `server/relay/src/index.js:383-384` forwards any message type it does not handle itself:
`default: return this.relay(att.slot, message)`. `tools/coop_relay.py:272` does the same. The client's `_on_text`
(`coop_net.gd:579-591`) handles `welcome`, `peer`, `left` and `error` the same way, whoever sent them.

**Impact.** A modified client can:
- force a partner drop (`left`);
- move the partner to another seat or an out-of-range seat (`welcome` with `slot:7`; the state also falls from
  STARTED back to LOBBY);
- end the session (`peer` with another platform → `_fail("platform")`);
- hide later real errors (`error` sets `_got_error`).

This is griefing and broken runs, not a crash or data loss.

**Fix.** In both relays, refuse or drop player messages whose `t` is one of the relay's own types. Better, forward
only an explicit allow-list of player types. On the client, also apply the state checks from §1.2.

## 6. Partner frames are not bounds-checked (Medium, confirmed)

**Where.** `scripts/coop/coop_lockstep.gd:780-826` (`_on_frame`):
- the first tick (`first`) can be any u32, and `_inputs[remote][t] = inp` stores inputs for any future tick;
- `_their_sums[t]` grows without limit, and a sum for a tick that never runs is never erased;
- reads like `bytes[at + 4]` happen before any length check;
- the command count `nc` can be up to 255 per input (the intended maximum is 4);
- `_remote_high` can jump to about 2^32, which leaves catch-up mode on for good.

**Impact.** The relay allows about 64 KB/s, which is about 20,000 stored Dictionaries a second. A tampered peer or
relay can push a phone tab out of memory within minutes. A truncated frame raises a script error after part of it has
already been applied.

**Fix.**
- Check `at + needed <= bytes.size()` before every read, and drop the whole frame if it fails.
- Accept input ticks only within `[tick, tick + DELAY_MAX + 255]`.
- Accept checksum ticks only on `CHECKSUM_INTERVAL` multiples within that same window.
- Clamp `nc` to `MAX_COMMANDS_PER_TICK`.
- Treat a malformed frame as a partner drop, which already has a clean path.

## 7. Lobby codes can be brute-forced and the quota used up (Medium, path confirmed, impact plausible)

**Where.** `server/relay/src/index.js:115-126` and `174-182`. Codes are 5 letters from a 20-letter alphabet, which
gives 3.2M combinations. There is no join rate limit. The create limit is kept per isolate, and its map is cleared
completely (`createLog.clear()`) once it reaches 10,000 IPs, which an attacker with many IPv6 addresses can trigger.

**Impact**
- With about 50 lobbies open, one hit takes about 64,000 tries, which is minutes of scripted joins. The attacker then
  holds the guest seat and can use findings 2, 5 and 6 against a stranger.
- Every try reaches a Durable Object, so a flood can use up the free plan's daily quota and take co-op down for
  everyone.

**Fix**
- Add a Cloudflare rate-limiting rule (or a per-IP counter Durable Object) on `join`.
- Move to 6-7 letter codes (64M-1.28B combinations).
- Evict the oldest `createLog` entries instead of clearing the map.
- Optionally, the host approves a joining guest before the lobby shows them as seated.

## 8. An older build can replace the live site (Medium, confirmed)

**Where.** In `.github/workflows/ci.yml:490-525`, `publish-pages-repo` has no `concurrency:` group and runs
`git push -q -f ... HEAD:main`. Lines 450 and 493 publish on `startsWith(github.ref, 'refs/tags/v')` without checking
that the tagged commit is on `main`.

**Impact**
- Two quick pushes, or a `main` push plus a tag push, race: whichever finishes last wins, so an older build can end up
  live.
- Tagging an old or hotfix commit force-pushes that older build over the site.
- NecropathyPlay keeps exactly one commit, so the only rollback is re-running CI while the artifact still exists
  (7 days).

**Fix**
- Add `concurrency: { group: pages-repo, cancel-in-progress: false }` so publishes queue up in order.
- Publish Pages only from `refs/heads/main`. Let tags create Releases only, or check
  `git merge-base --is-ancestor $GITHUB_SHA origin/main`.
- Before pushing, compare the source SHA recorded in the target's last commit message, and skip the push if the
  target is newer.
- Optionally, keep the last few builds (no force-push, or a `previous` branch) so a rollback is one click.

## 9. The relay deploys without the game tests, with an unpinned wrangler (Medium, confirmed)

**Where.** `ci.yml:267` has `deploy-relay` with `needs: [coop-net]` only. Line 292 runs `npm install` against
`"wrangler": "^4.0.0"`, and `server/relay/` has no lockfile. `CLOUDFLARE_API_TOKEN` is set at job level (line 273),
so every step can see it.

**Impact**
- A commit that fails the playthroughs still deploys the relay, so a relay that does not match the live game can go
  live.
- A compromised or broken wrangler release runs while holding the account token.

**Fix**
- Commit `package-lock.json` and use `npm ci`.
- Add `test` and `export` to the job's `needs`.
- Move the token into the deploy step's own `env:`.

## 10. Restoring a backup code keeps no undo copy (Medium, confirmed)

**Where.** `scripts/core/save_backup.gd` (`import_code()`) renames the decoded text over `save.cfg`. The confirm dialog
exists (`settings_menu.gd:289`), but no copy of the old save is kept. A code that holds only `[meta] save_version`
passes `decode()` and resets the whole profile.

**Impact.** A mistyped code, a friend's code or a "maxed save" from the internet replaces real progress for good.

**Fix**
- Copy `save.cfg` to `save.cfg.pre_restore` before the rename, and add an **Undo** line in Settings → Save.
- Show the code's Soul Ash, run count and version in the confirm text.
- Refuse codes with no `[meta] runs` or `[stages]` data.

## 11. Area attacks skip a summon each time one dies in the loop (Medium, confirmed)

**Where.** Several hazards loop `for u in h.units:` and call `game.combat.damage_unit(u, ...)` inside the loop, for
example `seraphine_hazards.gd:339-346`. When the hit kills the summon, `HordeDirector.on_unit_died()`
(`horde_director.gd:794-797`) swap-pops the same array: `units[idx] = units[units.size() - 1]; units.pop_back()`.
The loop then moves on, and the summon that was swapped into that slot is never checked. Affected sites:
- `seraphine_hazards.gd:339` (nova) and `:387` (collapse);
- `eye/vhalneth_hazards.gd:146` (gaze) and `:181` (roar, which also skips the knockback);
- `eye/arm_kit.gd:138`;
- `shogunate/amaterasu_hazards.gd:220`;
- `empire/assembly_director.gd:232`, whose enemy loop just below already copies its list for exactly this reason.

**Impact.** Every kill lets one other summon in range dodge the hit. Against lethal hits, roughly half the army in
range survives. The boss fights are softer than designed, and the fix will make them harder. The behaviour is
deterministic, so there is no co-op desync.

**Fix.** Loop over a copy (`for u in h.units.duplicate():`, keeping the `u.active` check), or walk the array
backwards. Re-check the Sanctum, Ul-Thalos, Assembly and Road to the Sun summaries and boss balance afterwards. This
is a balance-affecting change: run a multi-seed check.

## 12. The Ferry of Souls bypasses "Steel has no soul" (Medium, confirmed)

**Where.** `scripts/abilities/spells/river_styx.gd:153-163` calls `game.horde.spawn_temporary(...)` directly. Its
guard checks only `e.is_structure`. Every other raise goes through `Enemy.leaves_corpse()` and
`HordeDirector.raise_corpse()`, which `horde_director.gd:727` describes as "THE one path". River Styx has no `act`
key, so the Ferrywoman can take it into Act III.

**Impact**
- Machines rise as Risen, against the CLAUDE.md Act III rule.
- Cyborgs never become Grave Gunners.
- Bosses, minibosses and Reckoning enemies can leave a Risen.
- A corpse swallowed by a Hades fissure still rises.

**Fix.** Extend the guard with `not e.leaves_corpse()` and the boss / miniboss / Reckoning exclusions. Route the spawn
through `raise_corpse(...)` with `e.rises_as_gunner()`.

## 13. Save codes are parsed as Godot text values (Low-Medium, plausible)

**Where.** `SaveBackup.decode()` calls `ConfigFile.parse(text)`. Godot's variant parser accepts `Object(Class, ...)`
and possibly `Resource("res://...")`. That is engine behaviour and was not tested in this repo.

**Impact.** A pasted code could create engine objects (running a script's `_init`), load large resources, or leak
memory. The typed readers then ignore the values, so this is a robustness problem rather than code execution.

**Fix.** Before parsing, refuse text that contains `Object(`, `Resource(`, `SubResource(` or `ExtResource(`.
`save()` never writes any of them. Also cap the base64 length before decoding (the 1 MB cap applies only after
decompression).

## 14. The save is not crash-safe on Windows (Low-Medium, plausible)

**Where.** `meta_progress.gd:1286-1292` writes `save.cfg.tmp` and then renames it over the old save. On Windows,
Godot's rename probably removes the target first (engine behaviour, not tested). `load_save()` never looks at
`save.cfg.tmp`. Also, `save.cfg.corrupt` is overwritten on each corruption (line 1308).

**Impact.** A crash or power cut between the remove and the rename leaves only the `.tmp`. The next launch starts a
fresh profile, and the next save overwrites the `.tmp`, which was the only good copy.

**Fix.**
- If `save.cfg` is missing or unreadable and `save.cfg.tmp` parses, load the `.tmp` and promote it.
- Keep a `save.cfg.bak` of the previous save.
- Number the corrupt copies (`save.cfg.corrupt.<n>`).
- Write `settings.cfg` the same temp-then-rename way (today it is written straight over).

## 15. Gaps in the desync check (Low-Medium, confirmed)

**Where.** `coop_lockstep.gd:893-904` compares only `mini(a.size(), b.size())` fields, so a peer that sends empty
checksums is never flagged. The hash (`924-985`) leaves out the global RNG state, status timers, cooldowns and slot
XP.

**Impact.** A divergence in those values shows up only later, through positions or HP. Against a tampered client it
may never show up.

**Fix**
- Treat a different field count as a desync.
- Fold in an RNG fingerprint. Draw it from a game-owned `RandomNumberGenerator`, or read the state before and after a
  probe so the stream is unchanged.
- Fold in summed cooldowns and status timers.

## 16-17. CI hardening (Low-Medium, confirmed)

- **Permissions.** There is no top-level `permissions:`; only `release` and `publish-pages` set their own.
  `softprops/action-gh-release@v2` runs with `contents: write`, pinned only by tag. **Fix:** add `permissions:
  contents: read` at the top, and pin third-party actions to a commit SHA.
- **Publishing gates.** `publish-pages-repo` needs only `[test, export]`, so a determinism bug that the
  `coop-lockstep` job would catch can go live. The Web build is never loaded in CI; only Linux is smoke-tested.
  **Fix:** add `coop-lockstep` to the publish job's `needs`, or turn a red lockstep job into an automatic revert or
  alert. Add a headless Chromium load of `build/web` (the title screen reached, no console errors) before publishing.

## 18. Refund all pays today's prices (Low, confirmed)

**Where.** `refund_all()` (`meta_progress.gd:1123`) and `_enforce_prerequisites()` (`1543`) refund
`MetaData.cost_up_to(id, tier)` from current data. When a `max_tier` is lowered, load clamps the tiers away with no
refund.

**Impact.** A patch that raises a cost lets players buy cheap and refund at the new price for a profit. A patch that
lowers a cost makes them lose Soul Ash.

**Fix.** Store what was paid per upgrade (`[upgrades_paid]`) and refund that. Refund tiers that a lowered maximum
clamps away.

## 19. Co-op players share one Ferryman's Toll cap (Low, confirmed)

**Where.** `combat_resolver.gd:192-196` and `941-958`: `_toll_window_t` / `_toll_window` live on the one
`CombatResolver`, and `CoopSession.bind()` does not swap them per slot.

**Impact.** When both players own the passive, each heals less than in solo. It stays deterministic.

**Fix.** Keep the window per slot: a two-entry array indexed by `game.coop.bound`, or the field moved onto `CoopSlot`.

## 20. Smaller items (Low)

- **Settings reads under the autotest.** The autotest reads `user://settings.cfg` and applies the player's key
  bindings (`settings.gd:92-96`). That breaks the letter of the CLAUDE.md rule, although nothing gameplay-relevant is
  read. Skip it under the autotest, or amend the rule.
- **Settings value types.** `settings.gd:101-108` calls `bool(cfg.get_value(...))` on raw values; a hand-edited
  String can abort the load before `apply_all()` (plausible). Use typed readers, and de-duplicate key bindings.
- **Partial migration.** `SaveMigration.run()` stops as soon as either file exists, so a half-finished copy (settings
  copied, save not) is never retried.
- **Co-op loadout claims.** A co-op partner's loadout is checked against the data tables, not against what they own
  (relics, unlocks, meta levels). Stats are still clamped by `MetaModifiers`. Acceptable for co-op between friends.
  Optionally, drop an offering the partner failed to pay for.
- **Co-op skin.** `_resolve_skin()` (`game.gd:514`) checks this machine's save for the partner's skin, so two
  machines can draw different skins for the same player. Visual only.
- **Summon grid bucket.** A summon that dies and is reused in the same tick stays in its old `ally_grid` bucket until
  the next rebuild. References are protected by `generation`; at worst this is one tick of odd queries.
- **Public build.** The build (`index.pck`, unencrypted) can be decompiled into readable scripts, including the
  autotest code. This is only a concern if the source repository is meant to stay private.

## What was checked and found sound

- **Determinism.** Every global `randf` / `randi` in the simulation draws from the seeded stream. UI, fx and audio use
  their own generators. `get_instance_id()` is used only as an equality key or for visuals. Wall-clock time is used
  only for timing, networking and profiling. The Effects, adaptive tier, culling and zoom settings change drawing
  only. Gameplay uses the fixed `gameplay_view_size()`.
- **Pools.** Every stored reference that was sampled checks `generation`. Pool caps drop or merge and never grow
  without limit. Bosses are not pooled.
- **Crash guards.** Every `randi() % size()` is guarded. Placement and push-out loops are bounded.
- **Single paths.** Damage multipliers, synergies (`hit_mult()`) and Dread (`damage_player()`) each apply once.
- **Economy.** `award_run()` pays once per run. Every shop path re-checks before it charges. Caskets cannot be
  save-scummed (seeded per save and per opening).
- **Partner commands.** A partner's commands affect only their own slot. PICK / BANISH / REROLL are clamped.
- **Relay limits.** The relay enforces message size, rate buckets, a hello timeout, idle / age expiry and no joins
  after the start.
- **CI.** No `pull_request_target`. No `${{ github.event.* }}` in `run:` steps. Fork PRs get no secrets.
- **Web patches.** Both patch tools fail loudly if their pattern is missing or appears twice, and both patches are
  present in the live `index.js`.
- **Secrets.** Neither repo, nor its 327-commit history, contains a secret. `tools/gen_image.py` reads its key from
  the environment only.

## Testing the fixes

Following the CLAUDE.md "Done" rules:
- §11 changes balance: multi-seed screens on the four affected stages.
- §2, §5, §6 and §15 touch co-op: `tools/coop_net_test.py`, `--coop-bot`, and the `coop-lockstep` gate.
- §1 and §4 need a headless Chromium check that `?relay=` / `?necro_autotest=` are ignored on a release build.
- §3, §10, §13 and §14: an `ossuary_check`-style headless scene that loads crafted saves and codes.

Solo same-seed summaries must stay identical for every fix except §11 and §12. Both of those change gameplay on
purpose.
