# Online co-op: design (owner decisions, Oct 20, 2026)

The owner asked for online co-op with a lobby and code system, enemies doubled, and tested primarily with two
players (the worry: both armies' volleys at once hurting performance). This file is the shared plan for every agent
on the `coop` branch. CLAUDE.md overrides it where they conflict. Every decision below also becomes a GDD §15.0 row.

## Owner decisions

| Question | Answer |
| --- | --- |
| Connection | **Cloudflare relay.** A small Cloudflare Worker (Durable Object per lobby) hands out lobby codes and relays the inputs over WebSocket. Works in the browser (phones too) and on desktop, through home routers. The owner makes a free Cloudflare account once; CI deploys the Worker with a token secret. |
| XP and level-ups | **Shared XP, both pick.** One XP bar filled by either player's pickups. On a level-up the game pauses for both, each picks their own card, and it resumes when both have picked. |
| Death before 0:00 | **Downed, partner revives.** The fallen necromancer's army crumbles and they lie downed. The partner stands near them about 3 s to raise them at 50% HP. The run is lost only when both are down at once. |
| Scope | **Online only, 2 players**, browser and desktop, each player on their own screen. |
| Enemies | **Doubled** (owner: "obviously you would double the number of enemies"). |

## Lead decisions (TUNING, recorded as GDD §15.0 rows; the owner may change them)

- **Netcode: deterministic lockstep.** Runs are already deterministic per seed and the whole simulation is one
  fixed-rate `Game._physics_process()`. Each machine runs the full simulation of both players; only inputs travel
  (a few bytes per tick). A tick runs only when both players' inputs for it are known. Input delay starts at
  4 ticks (67 ms) and adapts to the measured round trip. Every 60 ticks each side sends a state checksum; a mismatch
  is a desync (logged, shown, the run ends cleanly for both with their Soul Ash kept).
- **Same build only.** The lobby refuses a partner on a different game version. Mixed platforms (web with desktop)
  are allowed only if the checksum test passes for them; otherwise the lobby refuses mixed platforms too (math
  libraries can differ by one bit between WASM and native).
- **Solo is untouched.** With no co-op session, nothing of co-op exists (`game.coop == null`), and every solo
  same-seed autotest summary stays bit-for-bit identical (stages 1-9).
- **Who picks what.** The host picks the stage, difficulty, run modifiers, Hyper and the Profane Pact. Each player
  picks their own character, skin, ultimate and title, from their own unlocks. Each player's own Ossuary upgrades
  (Soul Ash meta levels) and unlocks apply to their own necromancer, army and card offers; they are exchanged in
  the lobby so both simulations know them. The host's Profane Oath sets the run's Oath.
- **Each player has their own necromancer, army, spells, passives, synergies, Dread Rally / ultimate and
  character innate.** Armies ring their own necromancer. Menders and Warders look after their own necromancer
  (and any undead).
- **Enemies always advance on the nearest necromancer** (downed ones are not targets). Bosses too.
- **Doubling:** spawn counts and the alive cap ×2 (unless the performance check forces a lower cap), XP per kill
  ×0.5 so the shared bar keeps the solo pacing (first level-up ~0:20-0:30, builds complete ~16-18 min), stage
  boss HP ×1.7, minibosses ×1.5. Elite chests double naturally with the elites; each chest goes to whoever opens it
  (its evolution or rewards follow that player's build); the boss chest drops one per player.
- **Pickups:** XP crystals feed the shared bar from either player's magnet. Hearts and power-ups go to whoever
  touches them.
- **Pause:** either player can pause; it pauses both ("Paused by your partner"), either can resume. Hit-stop is off
  in co-op (it would only freeze one machine).
- **Partner drops (disconnect, closed tab):** after a short wait the remaining player's game hands the partner's
  necromancer to the autotest's army bot and the run goes on solo. No reconnect in v1.
- **Soul Ash, achievements, unlocks, the Codex:** each player earns and records their own, from their own slot,
  on their own device, as in a solo run.
- **Camera, HUD and input:** each machine follows its own necromancer. The HUD adds the partner's HP bar and an edge
  arrow toward the partner when off screen. Touch controls work unchanged.

## Interfaces (the seam between the agents)

- `CoopNet` (connectivity, lobby UI; agent "net"): an autoload that owns the WebSocket to the relay, the lobby state
  and the start message. It never touches gameplay. It exposes:
  - `send_frame(bytes: PackedByteArray)` and signal `frame_received(bytes: PackedByteArray)`: opaque, ordered,
    reliable messages to / from the partner (the lockstep driver's tick frames, checksums, commands);
  - `start_info`: a Dictionary set when the host starts the run, identical on both machines:
    `{"seed": int, "config": Dictionary (RunConfig fields the host picked), "loadouts": [slot0, slot1],
    "local_slot": int (differs per machine), "version": String}`; a loadout is
    `{"character_id", "skin_id", "ultimate_id", "title_id", "meta_levels": {upgrade_id: level},
    "unlocks": [ids], "name": String}`;
  - signals `partner_left`, `connection_lost`, `latency_measured(rtt_ms: float)`.
- The **lockstep driver and the whole co-op simulation** (agent "sim") live under `scripts/coop/` and consume
  `CoopNet` (or a loopback / bot input source in tests).

## Testing

- `--coop-bot` (autotest): a co-op run in one process, both slots driven by the bots (default army policy for both;
  `--policy2=` for slot 1), no network. Summary lines per slot plus a `coop` line.
- Two headless processes against the local Python relay (`tools/coop_relay.py`, same protocol as the Worker),
  comparing checksums every 60 ticks for a full run: the determinism gate.
- **Performance (the owner's question):** milliseconds per simulation tick and frame time, solo vs co-op, at the
  busiest moments (20:00 Reckoning, boss fights, Rally Barrages from both armies), headless and in the Web build in
  headless Chromium at a phone-sized viewport with Effects Reduced and Full. Report the numbers and fix what breaks
  the frame budget before shipping.
