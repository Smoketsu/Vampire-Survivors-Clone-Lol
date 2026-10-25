# Ossuary expansion: handoff (lead session, Oct 25, 2026)

The owner's request (Oct 25): "I think ossuary may need to be expanded, or we need to find something else to spend
soul ash on. As it is there's no reason for the player to try harder difficulties when you are able to max out so
quickly. I think we need more levels in each option, and more options. Write proposal and handoff file."

**The proposal** is a Claude Doc the owner reads and comments on: <https://claude.ai/artifact/3sZKSYQJc4L8kGAu33CUvc>
("Ossuary Expansion Proposal"). **The owner answered all 7 decisions (Oct 25): see GDD §15.0 "Ossuary expansion: owner
decisions"** (all five parts; difficulty-gated levels 6-10; Masteries for summon classes only; Relic slots 1 -> 3;
Offerings expensive; stage multipliers restart each act ×1 / ×1.25 / ×1.5, Lich ×1.5, Deathlord ×2; prestige later).
Then read `CLAUDE.md` (rules; it overrides this file).

## Where things stand (Oct 25)

- `main` = `integration` = `ae5c6aa` (if the last publish went through; check `gh run list --branch main`):
  everything shipped, including the placeholder-art sweep (Harbour, Act I enemy / player AoEs, Act I walk strips,
  Act III effects and sprites, all owner-approved on review pages) and "bosses don't flash" (`EnemyData.BIG_HIT_FLASH`).
- Nothing in flight. No open agents. The owner said (Oct 25) there is no need to notify the Act III session
  (`session_01Etc2wb7CR1tZxL38Nta6Qe`) any more before moving `main`; just fetch / rebase before pushing.

## The economy today (facts gathered for the proposal)

- `scripts/data/meta_data.gd`, `UPGRADES`: 20 upgrades in 4 trees + the Profane Oath; 60 tiers; every upgrade maxed costs
  9,635 Soul Ash (Oath 375 more). Costs per tree: Necromancy 2,595, Shadowcraft 2,520, Survival 2,435, Fortune 2,085.
- Earn formula: `Meta.compute_ash()` (minutes × 7.5, kills × 0.03, elites × 4, boss 75, Reckoning seconds × 2.5 capped at
  180 s; then the bonus lines). A strong Graveyard run on Necromancer is about 450.
- Multipliers: stage `ash_mult` (Graveyard 1.0, March 1.25, Sanctum 1.5, Harbour 1.75, Archive 2.0, Spire 2.25, Wastes 2.5,
  Assembly 2.75, Citadel 3.0; the Act II / III ones are marked placeholders), difficulty `ash_mult` (Initiate 0.8,
  Necromancer 1.0, Lich 1.25, Deathlord 1.5; `difficulty_data.gd`), Hyper +100% (`hyper_data.gd`), Pact / Oath ash lines
  (`pact_data.gd`). Check in `Meta.compute_ash()` exactly how these combine (separate end-screen lines vs multiplied);
  the proposal's "several thousand per strong Act III Deathlord + Hyper run" is an estimate to confirm.
- One modifier path: `scripts/core/meta_modifiers.gd` sums the stats; the game's stat code reads them. Keep it the one
  path (CLAUDE.md convention 4). Unlock-type upgrades exist (`"unlock"` format, `MetaModifiers.unlocks()`), and retired
  upgrades are refunded through `MetaData.RETIRED_REFUNDS`.
- UI: the Ossuary screen (`ossuary_tile.gd`, `ossuary_ui_data.gd`, pixel badges per upgrade, the Refund-all dialog);
  the Codex reads achievement counters only.

## Plan once the owner answers (the proposal's build plan)

1. **Measure the economy** (safe to start now): a small script that runs the autotest with `--meta-save` on a scratch
   save (never the owner's) for each stage × difficulty (× Hyper) with the army bot, and records Soul Ash per run.
   Report a table, then retune the stage and difficulty multipliers to the owner's answer to decision 6. Sonnet is
   enough for this (mechanical).
2. **Deeper tiers** (levels 6-10, smaller steps, ~1.35× cost growth) with the difficulty gates (decision 2), and the
   save migration (`MetaData.SAVE_VERSION`, `Meta._migrate()`; existing levels kept, nothing refunded). One Opus
   agent; it owns `meta_data.gd` / `meta_modifiers.gd` / `meta_progress.gd` for this step.
3-6. **New options + the Dominion tree, Masteries, Relics, Grave Offerings + recolours**: separate agents in worktrees
   once 1 and 2 are merged. Assign one owner per shared file (`meta_data.gd` gets small additive rows only; new systems in
   new files: e.g. `mastery_data.gd`, `relic_data.gd`, `offering_data.gd`). The Ossuary screen needs tabs (Trees,
   Masteries, Relics, Offerings): one UI agent, the menu rules in CLAUDE.md, phones (`TouchSupport.fit_to_screen()`).
- **Every step:** the power curve must hold (CLAUDE.md "Balance targets": `--meta=max` clearly easier but the Reckoning
  still ends every run 30-90 s past 0:00; builds complete ~16-18 min). `--meta=max` must be redefined to mean "everything
  bought" including the new content, and a multi-seed check run on it. Solo same-seed summaries at `--meta=none` must
  stay identical (new content defaults to nothing bought). Co-op: each player's own Ossuary applies to their own slot
  (the loadout's `meta_levels`); new meta content must travel in the loadout the same way (`CoopNet` loadout, the sim's
  `meta_for()`), or both machines desync.
- **Docs:** a GDD §15.0 row per decision; README (Ossuary section); CLAUDE.md Done entry when shipped.

## How the owner works (unchanged)

- The owner decides; recommend with a reason. Proposals go in a Claude Doc they can comment on.
- Art for new icons / badges: review page (Artifact with `db` + `user`, template `docs/act3/tools/art_review_template.html`);
  read marks with ArtifactData. Image generation only with
  `GEN_LEDGER=/home/user/vampire-survivors-clone-lol/docs/art/generation_ledger.csv python3 tools/gen_image.py`; never
  touch API keys; commit the ledger when it changes.
- Usage: the owner asked to respect usage: Sonnet for mechanical work (audits, measuring, tool-driven art), Opus for
  design-heavy implementation; don't poll agents (they notify when done).
- Gameplay checks for art-only work are skipped at the owner's request; gameplay changes (this project) get the full
  "Done" set before `main` moves.
- Rules that bit before: never `AudioServer.add_bus()`; no screen-reading shaders; Web export always through
  `tools/patch_web_audio.py` (which also runs `patch_web_gl.py`); prefer textures over per-frame polygons; at most 4 Godot
  processes; commits end with the session's attribution lines and never name a model.

## Progress (Oct 25, later)

- Merged on `integration`: step 1 (`ossuary/economy`: per-act stage multipliers ×1 / ×1.25 / ×1.5, Lich ×1.5, Deathlord ×2;
  `tools/ash_measure.py`, `docs/ossuary/ECONOMY.md`: ~877 / 1,170 / 1,880 Soul Ash a good run) and step 2
  (`ossuary/deep-tiers`: levels 6-10, `[clears]`, `Meta.max_open_tier()`, SAVE_VERSION 2, `tools/ossuary_check.tscn`),
  then the deep-level prices retuned to ×1.10 a level (24,950). Budget for the rest: options + Dominion ~9,000, summon
  Masteries ~13,000, Relics ~8,000 (Offerings are consumables). Not yet on `main`.
- Running in parallel (shared brief `docs/ossuary/AGENT_RULES.md`): A `ossuary/options` (Opus: ~10 new upgrades, the
  Dominion tree, the Ossuary tab bar), B `ossuary/masteries` (Sonnet: summon-class Masteries), C `ossuary/relics` (Opus:
  Relics with 1 -> 3 slots + expensive Grave Offerings, the pre-run "Rites" strip), D `ossuary/recolours` (Sonnet:
  cosmetic recolours of owned skins).
- After they merge: ONE multi-seed power-curve batch by a Sonnet agent (`--meta=max` = everything bought / equipped;
  8 seeds, army and naive, a stage per act; targets in CLAUDE.md), then the full "Done" set, CI on integration, ship.


## Status for the next session (Oct 25, lead about to hit usage)

| Branch | State |
| --- | --- |
| `integration` | Steps 1-2 merged (economy, deep levels at ×1.10 = 24,950), the owner's decisions, this file. Not on `main` yet. |
| `ossuary/masteries` | **Done** (Sonnet), c9ece0e: 17 summon classes × 3 levels (+4% HP and damage per level, 190 / 250 / 320, 12,920 total), unlock on class Lv 5 (`[class_lv5]`, `[masteries]`), `MetaModifiers.mastery_value()` → `HordeDirector.compute_stats()`, co-op `mastery_levels`, panel `ossuary_masteries_panel.gd` (not yet seen inside A's tab bar). Gates passed; `--meta=max` victory 36 s past 0:00. |
| `ossuary/recolours` | **Done** (Sonnet), b1b49c7: Bone 300 / Blood 400 / Abyss 500 / Gilded 600 (Hyper skins: Verdant), CPU palette remap cached (`Recolour`), `SpriteBank.draw()` `recolour` param, pre-run hero Recolour button, `[recolours]` / `[recolour_pick]`, co-op `recolour_id`. Gates passed. |
| `ossuary/options` | Agent A (Opus) was finishing: 3e5d9e5 "ten upgrades, the Dominion tree, the tab bar" pushed; check for a final report / later commits. |
| `ossuary/relics` | Agent C (Opus): Relics (1 → 3 slots) + Grave Offerings + the pre-run "Rites" strip. **Not pushed when this was written**; it was told to push WIP. If the branch is missing, re-brief an Opus agent from `docs/ossuary/AGENT_RULES.md` + the agent C brief below. |

**Next steps:**
1. Wait for / check A and C. Then merge on `integration` in this order: options (it owns the tab bar), masteries, relics,
   recolours. Expect conflicts in `meta_progress.gd`, `meta_modifiers.gd`, `coop_net.gd` / `coop_session.gd` (loadout
   keys), `autotest.gd`, `tools/ossuary_check.gd`, `pre_run_setup.gd` (C's right-column strip vs D's left-column button),
   `README.md`, `docs/GDD.md` (keep both sides). `--import`, `tools/ossuary_check.tscn` PASS, check the Masteries / Relics /
   Offerings panels load inside A's tab bar, and that the pre-run screen still fits 1280×720 and 844×390.
2. **One balance batch (Sonnet agent, at most 4 Godot processes):** `--meta=max` (everything bought / equipped) and
   `--meta=none`, `--policy=army` and `naive`, `--mortal`, 8 seeds, on one stage per act (graveyard, harbour, citadel) and
   Deathlord on the Citadel. Targets (CLAUDE.md): meta max clearly easier but the Reckoning still ends every run 30-90 s
   past 0:00; builds complete ~16-18 min; meta none unchanged. Retune with a few data changes if needed.
3. Full "Done" set, CI on `integration` (`gh workflow run ci.yml --ref integration`), then fast-forward `main`
   (no need to notify the Act III session any more: owner, Oct 25). Then tell the owner with screenshots of the new tabs
   and the pre-run strip. Remaining from the proposal: prestige noted for later (owner).

**Agent C's brief (to re-brief if needed):** Relics, ~8,000 Soul Ash incl. slots: ~15 run-shaping perks bought once,
equipped before a run, 1 slot from the start + 2 buyable (max 3); examples Grave Lantern (chests reveal two choices),
Black Banner (ultimate meter starts half charged), Bone Abacus (free reroll every five levels), Hollow Crown (+1 active
slot, −10% max HP), Mourner's Bell (elites drop a heart); some sold only after feats (`[clears]`, Hyper / boss records);
`relic_data.gd`, one effects path, Meta section, `[prerun]`. Grave Offerings (expensive, 40-70% of an 877 run): ~5-6
single-run boons, one per run, paid at run start; `offering_data.gd`. Panels `ossuary_relics_panel.gd` /
`ossuary_offerings_panel.gd` (tab contract in AGENT_RULES.md); a compact pre-run "Rites" strip in the right column;
co-op loadout; `--relics=` / `--offering=` flags; `--meta=max` equips a fixed set.

**Update (Oct 25, 17:50 UTC):** `ossuary/options` (9,060: ten upgrades, Dominion, the tab bar), `ossuary/masteries` and
`ossuary/recolours` are MERGED on `integration` (08ee6f8; conflicts in autotest / horde_director / coop_net loadout /
ossuary_check resolved by keeping both sides). `--import` clean, `ossuary_check` PASS, seed 7 default clean (513 ash),
`--meta=max --policy=army --mortal` victory 35 s past 0:00, build complete 13:26 (earlier than 16-18: the balance batch
should judge it). Left: merge `ossuary/relics` when its agent reports (it was resumed after the usage limit), then the
balance batch, CI, ship.

**Update (Oct 25, ~18:30 UTC):** ALL FOUR branches merged on `integration` (7ce7e4d). Checks after the merge: `--import`
clean, `ossuary_check` PASS (168 tiers), seed 7 default identical to before the merge, `--meta=max --policy=army
--mortal` victory 44 s past 0:00 (build 13:22), `--coop-bot --meta=max` clean. Running: the balance batch (Sonnet,
branch `ossuary/balance`: meta none / max × army / naive × graveyard / harbour / citadel, 8 seeds, + citadel Deathlord;
`docs/ossuary/BALANCE.md`). Then: merge its data changes, CI on integration, fast-forward main, tell the owner with
screenshots (`docs/ossuary/shots/*`).
