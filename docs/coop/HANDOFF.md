# Co-op handoff (lead session, Oct 20, 2026)

The owner asked for online co-op. Usage limits are close, so this file is everything the next lead needs. Read it,
then `CLAUDE.md` (project rules, they win on conflicts), then `docs/coop/DESIGN.md` (the owner's decisions and the
agent interface), then `server/relay/PROTOCOL.md`.

## The owner's request

"Add co-op to the game, a lobby and code system. Double the number of enemies. Test with two primarily; I'm wondering
if the volleys going off from both will cause performance issues." Owner answers (all the recommended options):
Cloudflare relay; shared XP, both pick on a level-up (the game pauses for both); a downed necromancer is revived by
the partner (run lost only when both are down); online only, 2 players. Lead decisions (TUNING, owner may change):
lockstep, XP per kill ×0.5, boss HP ×1.7, minibosses ×1.5, pause pauses both, a bot takes over a dropped partner,
~70 ms input delay, same version only. All in DESIGN.md.

**The owner's open question is performance with both armies' volleys.** Answer it first, with numbers (headless ms per
tick and Web frame times at a phone viewport, solo vs co-op, at the busiest moments), in plain words.

## Where things stand

| Branch | State |
| --- | --- |
| `main` | `8525012`: live on Pages. Only my hotfixes; **no Act III, no co-op**. The last hotfix is the slow-browser hint (GDD §15.0 "Slow browser hint"; the owner's friend's GrapheneOS phone was in fact just slow to load: false alarm, the hint stays). |
| `integration` | `30ba528`: Act III phase 2 fully merged (by the Act III session) + main merged in. |
| `coop` | `457aea0`: DESIGN.md + **`coop-net` merged** (done, see below). Based on integration 18f72a5. |
| `coop-net` | Done. Relay Worker `server/relay/` (Durable Object per lobby, hibernation API), `tools/coop_relay.py` (same protocol, local tests), `CoopNet` autoload (`scripts/coop/coop_net.gd`, data `scripts/data/coop_net_data.gd`, default relay `wss://necropathy-relay.smoketsu.workers.dev`, overrides `?relay=` / `--relay=`), the lobby screens (title-screen Co-op item, Host / Join, a letter pad, two player cards, host's stage / setup synced read-only), `--coop-net-test`, CI jobs `coop-net` and `deploy-relay`. Screens in `docs/coop/shots/`. **Start still runs a solo game on each machine**: `Main.start_coop_run(info)` is the marked stub hook for the sim. |
| `coop-sim` | **In progress** (an agent was running when this session stopped). Pushed: `6b96cbe` two player slots in one simulation, `--coop-bot`, `--perf`; `d30bddc` `--effects=reduced` for the Web measurement; `693a53a` integration 18f72a5 merged; `3a02f69` Citadel audit, tick sections in `--perf`, `--coop-down` revive test. Check `git log origin/coop-sim` for anything newer and `docs/coop/PERF.md` (asked for; may not exist yet). Its milestone 1 brief: the slots refactor, co-op rules, `--coop-bot`, solo same-seed gate unchanged, the perf measurement, then STOP and report. |

## Next steps, in order

1. **Finish milestone 1 of `coop-sim`.** Read its commits and PERF.md; if the agent is gone, run the measurements
   yourself or brief a new Opus agent in a worktree on `coop-sim` with the milestone 1 brief (below). Verify: `--import`
   clean; `--coop-bot` full runs (Graveyard, one Act II, one Act III stage) with zero `SCRIPT ERROR` / `ERROR:` /
   `WARNING:` and `stuck_units=0`; the solo same-seed gate (`docs/act3/tools/gate.sh`, `same_seed_gate.py`, seed 7,
   base logs from integration 18f72a5 or newer) unchanged apart from catalog totals. Volley `SHOT_CAP` (320,
   `volley_data.gd`) is one global cap: decide with the numbers whether co-op raises it.
2. **Tell the owner the perf answer** (short, plain words, numbers), with any fix you recommend.
3. **Milestone 2 (the sim, after `coop` is merged into `coop-sim`):**
   - implement `Main.start_coop_run(info)` from `CoopNet.start_info` (seed, host config, both loadouts with meta levels
     and unlocks, local slot);
   - the lockstep driver in `scripts/coop/`: inputs per tick per slot (move quantized, buttons, commands: level-up
     card, chest, pause / resume), input delay with adaptive RTT, **send one bundled frame every ~3 ticks** (the
     Cloudflare free plan bills incoming WebSocket messages: one frame per tick allows only ~12 runs a day);
   - level-up / chest / pause as commands inside the lockstep (no `get_tree().paused` for gameplay in co-op), the
     "waiting for partner" states;
   - a checksum every 60 ticks with a desync end (both keep their Soul Ash);
   - the partner drop → bot takeover;
   - the partner HUD (HP bar, off-screen arrow);
   - per-slot Soul Ash, achievements and Codex on each device;
   - the determinism gate: two headless processes against `tools/coop_relay.py`, full run, checksums equal;
   - decide web-with-desktop mixing from that test.
4. **Integration:** merge `coop-sim` into `coop`, merge the newest `integration` into `coop` (the Act III session may
   still land a data-only balance pass), run the full "Done" set (CLAUDE.md) plus the co-op tests, a Web build check
   in headless Chromium (phone + desktop, two pages against the local relay, a real co-op run), then merge `coop` into
   `integration` and fast-forward `main`. **The first `main` push with `server/relay/` deploys the Worker** (the
   owner already added `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`; their workers.dev subdomain is
   `smoketsu.workers.dev`). Then check `https://necropathy-relay.smoketsu.workers.dev/health` says
   `{"ok":true,"protocol":1}` (the sandbox proxy may block it: ask the owner to open it).
5. **Docs:** GDD §15.0 rows for every co-op decision (the agents add theirs), README co-op section, CLAUDE.md: a
   co-op design-pillar bullet and a Done entry, `--coop-bot` / `--coop-net-test` in the autotest options.
6. **The owner tests** on their iPhone with a friend (the Pages build). Tell them the free-plan limit (~40-50 runs a
   day with bundled frames; the $5/month Workers plan removes it).

## Coordination with the Act III session

Another cloud session (`session_01Etc2wb7CR1tZxL38Nta6Qe`, reach it with the claude-code-remote `send_message`)
owns Act III. Agreement: **each side messages the other before fast-forwarding `main`.** It may still land an Act III
data-only balance pass on `integration`. It knows co-op is coming and that new enemy targeting gets audited at the
co-op merge (enemies must target the nearest non-downed necromancer through the sim's one accessor).

## Rules that bit before (keep)

- Never call `AudioServer.add_bus()`; no shader may read the screen (it crashed the owner's phone).
- Web export: `mkdir -p build/web && touch build/.gdignore`, export "Web", then **always**
  `python3 tools/patch_web_audio.py build/web/index.js`.
- At most 4 Godot processes; lean testing; commits end with the session's attribution lines and never name a model.
- The sandbox proxy blocks `*.github.io` and the Pages repo API: confirm a publish from the CI job result.
- Disk was nearly full from old worktrees: remove finished worktrees (`git worktree remove --force`) when done.
- Never read, print or set API keys; image generation only with the `GEN_LEDGER=...` prefix (CLAUDE.md).

## The coop-sim milestone 1 brief (to re-brief an agent)

Two player slots (necromancer, army, spells, passives, synergies, Dread Rally / ultimate, character, meta modifiers,
unlocks, own RNG streams for offers), with the bound-slot pattern: `game.player` / `game.horde` / `game.abilities`
are the bound slot's, each slot bound in turn for its own systems, shared systems step once, owner-specific effects
resolve the owner's slot through one path; enemies target the nearest non-downed necromancer through one accessor;
the DESIGN.md co-op rules (numbers in `scripts/data/coop_data.gd`); `--coop-bot` (both slots bots, camera on slot 0,
per-slot summary lines + a `coop` line); solo bit-for-bit identical (`game.coop == null`); `--perf` tables; Web
frame times at 844×390 (dpr 3, touch) and 1280×720, Effects Reduced / Full; `docs/coop/PERF.md`.
