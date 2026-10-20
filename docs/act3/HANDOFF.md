# Act III handoff (second lead session, Oct 20, 2026, 15:45 UTC)

Read this first, then `CLAUDE.md` (the project rules; they win any conflict), `docs/act3/PROPOSAL.md` (the
owner-approved design) and `docs/act3/BRIEF_PHASE2.md` (how the three stages were briefed). GDD §15.0 rows from
"Act III foundation (phase 1)" to the end of the table record every Act III decision.

## Where things stand

- **`main`** (`8525012`, live on GitHub Pages): the Act III foundation only (stubs behind "Coming soon", the Act III
  tab) plus two web hotfixes from the co-op lead session. No Act III stage content is on `main` yet.
- **`integration`** (`30ba528` and this file): everything below.
  - **Phase 1** (the foundation) and **phase 2**: the Scrap Wastes, the Assembly Halls and the Iron Citadel. Each
    stage has its kinds, miniboss, boss, spell + evolution + paired passive, character + 3 skins, achievement, art,
    sounds, Codex entries, report lines and GDD rows. The Grave Drone and Iron Revenant classes are in. All three
    stages stay `"playable": false`.
  - **Merge fixes:**
    - the Assembly and Wastes event branches each keep their `return` in `EnemyDirector._run_event()`;
    - the Citadel's `cargo_crate` obstacle is renamed `citadel_crate` (it clashed with the Assembly's);
    - the art ledger's duplicated rows are removed (`25f86ff`).
  - **The double-step bug fix** (`e829bb7`; the owner chose "fix and rebalance"): Forbidden Verse and Call of the
    Drowned were stepped twice a tick. Call of the Drowned's cooldowns are halved to keep it as played. GDD row
    "Double-stepped Act II spells".
  - **Art review round 1 redos**: both batches merged (`98392c1`, `501ffda`).
  - The co-op session's `main` hotfix, merged in (`30ba528`).
- **Verified on integration:**
  - Before the art merges:
    - `--import` clean;
    - all three stages `--policy=army --mortal` seed 7: victory, boss killed, 0 errors, `stuck_units=0`;
    - the stages 1–6 same-seed gate (seed 7: Graveyard default and army, Gullhaven and Ul-Thalos army): identical
      except catalog totals;
    - Graveyard `--mortal` clean.
  - After the art merges (art and tool changes only, plus drawing heights): `--import` clean. The machines agent also
    ran one Assembly army autotest on its branch: clean.
  - Regenerate the gate base with `docs/act3/tools/gate.sh <tree> <outdir>`; the scratchpad logs die with the
    container.

## In flight when this session ended

1. **The Act III balance pass**: an agent on branch **`act3-balance`** (worktree `/home/user/wt/act3-balance`, from
   `e829bb7`). Its brief:
   - one shared fix for the act's opening (the naive bot dies at 3:30–4:30 on all three stages);
   - each stage a step harder than Ul-Thalos (the army bot reaches 0:00 and kills the boss);
   - ranged share about 60%;
   - pacing (the Assembly had 29 chests on one seed);
   - Death Ray, far too strong (412k of 475k damage in a Graveyard run): reduce its reach or sweep rate;
   - checks of Hollow Puppet, Scrap Swarm, the Grave Drone and the Iron Revenant;
   - a Soul Ash proposal for the placeholder multipliers (×2.5 / ×2.75 / ×3.0); the owner decides;
   - the same-seed gate;
   - one GDD row "Act III integration (phase 2)".

   **Check the branch** (`git log origin/act3-balance`). If it has commits beyond `e829bb7`: read its GDD row,
   re-run the gate and the three army runs, then merge it into `integration` (expect only data-file and GDD
   conflicts). If it has none, re-run the pass from that brief (it is data-only).
2. **Art review: round 2 is done** (owner, db collection `act3_art_r2`): 45 OK, 9 redo, all hand-fixable. An
   agent is redoing them by hand on branch **`act3-art-redo-r2`** (worktree `/home/user/wt/act3-art-redo-r2`):
   - the 4 Deus Ex Machina images: more colour (they read monochrome), like the approved Arc Engineer / Juggernaut fix;
   - `bosses/kestrel_aim` and `kestrel_blades`: remove the extra line where the rear meets the leg; thicker thighs;
   - `empire/valkyrie_prime_walk`: the feet split in the animation (a walk-rig fix);
   - `player/lightning_abbess_deathlord_idle` / `_walk`: the bounce box 1 px further right.

   Check the branch; merge it into `integration` (`--import`), then publish **round 3** (only those 9 keys, new next
   to round 2) by adapting `docs/act3/tools/make_act3_review_r2.py` (set `BEFORE_REV` to the integration commit before
   the merge, a new collection `act3_art_r3`, and read the marks dir of `act3_art_r2`). Everything else is approved.
   **Update:** merged (`2c75989`); round 3 is published on the same page (collection `act3_art_r3`, 9 images; the
   generator now takes `<marks dir> <out> <before rev> <round>`). Read its marks when the owner says done.
3. **The OpenAI image key**: the owner replaced it (Oct 20, ~16:00 UTC), but this session still got 401
   `invalid_api_key` (environment changes reach new sessions only). **First thing in a new session:** check with a free
   `curl -sS -o /dev/null -w "%{http_code}" https://api.openai.com/v1/models` (200 = good). The owner approved the
   hand-fixed Untouchable Marionette in round 2, so it needs no regeneration.

## The image-API art job (needs a session started by the owner with the OpenAI connector on)

The OpenAI key is a claude.ai **connector** ("Chat GPT API", https://claude.ai/customize/connectors), read when a session
starts; a session created by another session gets no connector ("Missing bearer authentication"). The owner starts that
session. Its job, on branch `act3-epilogue` from `integration`:
1. Check the key: `curl -sS -o /dev/null -w "%{http_code}" https://api.openai.com/v1/models` must print 200.
2. **The Act III epilogue part "The Machines Go Dark": 4 panels**, one per line of `EpilogueData.ACT3_PART["lines"]`,
   made like the Act I / II panels (ART_BIBLE "Epilogue panels": `art_source/epilogue/act3_<n>.png` 1536x1024 from
   `tools/gen_image.py`, prompt saved beside it, `python3 tools/epilogue_panel.py <source> act3_<n>`). Ideas: (1) the
   Empire's chrome city, citizens rebuilt not buried, amber lights; (2) the Citadel's Core, Deus Ex Machina on its knees,
   the necromancer (violet) reaching into the engine for Varn's soul (soul teal); (3) the machines going dark rank after
   rank, Varn rising to serve; (4) the ashes of Covenant, Eye and Empire under the risen dead. Fill `ACT3_PART["panels"]`
   and append `ACT3_PART` to `PARTS` (the hook's comment says how; Meta `[epilogue] seen_act3`).
3. **The owner's redo of the Act II closing card `epilogue/close`** "with electronic empire vibes": the beacons burning
   on the hilltops, the Electronic Empire watching from beyond the mountains (chrome towers, a rising wall, amber
   lights, drones). Update `CLOSING`'s text to match (the Empire saw the beacons and came; nobody called it), two short
   lines plus "To be continued.".
4. Ledger rows committed (budget about $0.40); ART_BIBLE rows; GDD §15.0 row "Act III epilogue and the new closing card";
   `--import` clean and one default autotest clean. Then the lead merges it and adds the 5 images to the art review.

## Coordination with the co-op lead session

The previous lead session (`session_01FLPv2RqRe5qVsRWxUhur7z`) is building **online co-op** on branch `coop`, with two
agents. Agreements:
- **Tell it before every fast-forward of `main`**, and it tells you. Use send_message of the claude-code-remote MCP
  server, with the session_id above.
- It merges co-op into `integration` after Act III phase 2; data-only balance changes are fine to land meanwhile.
- New enemy code that targets the necromancer is audited at its merge (enemies will target the nearest necromancer
  through one accessor). Nothing to change on the Act III side now.

## What is left for Act III, in order

1. Merge the balance pass (above). Confirm it with multiple seeds: 8 seeds per stage, army `--mortal` and naive
   `--meta=mid --mortal`.
2. Finish the art review rounds until all images are OK.
3. **Performance in the Web build at phone size**, with many Empire shots on screen (Effects: Reduced draws 140 of
   360), before any stage turns playable:
   - export the Web build (CLAUDE.md "Local web export", always run `patch_web_audio.py`);
   - test in headless Chromium at a phone viewport on the Citadel at 15:00 or later.
4. **The Act III epilogue part 3**: 4 panels, "The Machines Go Dark", through the hook `EpilogueData.ACT3_PART`,
   opened by Nothing Is Deathless. Also the owner's redo of the Act II closing card `epilogue/close` "with electronic
   empire vibes". Both need the image key.
5. The owner's playtest. Then flip the three stages to `"playable": true`, update CLAUDE.md (Done list: Act III phase
   2), tell the co-op session, and fast-forward `main`.
6. CI does not run any Act III stage yet; add an Act III army job when the stages turn playable.

## How the owner works (keep doing this)

- **The owner decides; you recommend.** Use AskUserQuestion for real choices, recommended option first. Record every
  decision as a GDD §15.0 row. Write short, plain messages.
- **Art is reviewed on a review page** (db + user capabilities; OK / Redo and a note per image), round after round,
  new next to old, until all are OK. Owner art notes:
  - details big enough to read at game size, no busy specks; faces read clearly;
  - thin meshes are drawn on the grid (`tools/mesh_props.py`);
  - never a plain tint for a skin;
  - every female character in the figure-redesign style: hourglass figure, big bust and wide hips, fully clothed,
    clearly attractive, never explicit, with a bust bounce in walk strips and a 24-frame idle breathing strip;
  - **check the bounce box sits on the chest, not the belt**: most round 1 figure notes were about that;
  - machines are chrome but need clear coloured parts, or they read as a silver blob;
  - flyers hover (a bob, flapping wings, spinning propellers); they don't walk.
- **Testing is lean** (CLAUDE.md "Test lean"). Run at most 4 Godot processes on the 4-core machine, and split that
  budget when several agents run.
- **The owner tests on an iPhone** (Safari, the Pages build): no screen-reading shaders, never `AudioServer.add_bus()`.
- **Image generation:**
  - run `GEN_LEDGER=<repo or worktree root>/docs/art/generation_ledger.csv python3 tools/gen_image.py ...` with an
    absolute path; the clone's folder name differs between containers (here `/home/user/Vampire-Survivors-Clone-Lol`);
  - never read, print, echo, search for or set any API key;
  - commit the ledger rows;
  - when merging branches, union the ledger and drop exact duplicate rows (a "keep both" merge doubled it once).
- **Merging parallel branches:** most conflicts are both sides appending to the same list or dict, so keep both. Watch
  for:
  - a list's closing `]` (join the two sides with a comma);
  - a dict entry cut off mid-way;
  - a `match` arm or function body whose last lines git took as shared (the lost `return` bug happened twice).

  Run `--import` and one run per touched stage after every merge.
- Commits end with the session's attribution lines and never mention model identifiers. Tags and releases are the
  owner's to push (403 from cloud sessions).
- This session's worktrees (`/home/user/wt/act3-*`) are lost with the container; every branch is pushed.
