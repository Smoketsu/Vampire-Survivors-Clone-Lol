# Act III handoff (from the previous lead session, Oct 20, 2026)

The owner asked for a fresh session to build Act III. This file is everything the new lead needs. Read it first,
then `CLAUDE.md` (the project rules; they override everything here if they conflict), then `docs/act3/PROPOSAL.md`
(the owner-approved design), then `docs/act3/BRIEF_FOUNDATION.md` (the phase 1 brief).

## Where things stand

- **`main`** is at the `integration` tip `c0189e9`: all of content wave 2, its art redos, the chest beacon, the
  Feedback button (live, the owner's Google Form) and the Reckoning-death crash fix. It is live on GitHub Pages
  (https://smoketsu.github.io/NecropathyPlay/). CI takes about 4 minutes; `main` pushes publish automatically.
- **`act3-foundation`** (this branch) is phase 1, **most of it built but not yet merged**:
  - `a125078`, the foundation:
    - three stub stages behind "Coming soon": `wastes`, `assembly`, `citadel`, an Act III tab, the unlock chain from
      Vhal'Neth, placeholder bosses and timelines, `EmpireGround` floors;
    - **Line of Fire** (`EmpireShots`: pooled packed-array shots stopped by the first summon, Bone Wall segment or
      Orb Shield; barriers absorb; arcing shots fly over);
    - **Lock-On** (`LockOn`: 1.5 s paint, max 3 lines, a boss override, a Signal Ghost hook);
    - **Steel has no soul** (`Enemy.leaves_corpse()` gates every corpse and raise path; cyborgs rise as Grave Gunners
      through `HordeDirector.raise_corpse()` / `spawn_temporary()`);
    - the Purge Protocol Reckoning hook (kill-drones, orbital strikes);
    - `EmpireEnemyData` (Scout Drone, Line Trooper, Spotter, Kill-Drone) with per-stage tables; kits and bosses load
      by name from `scripts/enemies/empire/`;
    - the Codex Empire tab, palette ramps chrome / signal, the "Iron Requiem" loop and an Empire sound pack;
    - art for the three shared kinds plus the Grave Gunner;
    - autotest `--stage=wastes|assembly|citadel` and the lines `line of fire`, `lock-on`, `steel`, `purge protocol`,
      `empire kinds`, `empire stage`.
  - `06e4792`: edits that were uncommitted at a container restart (README, ART_BIBLE, `empire_enemy_data.gd`,
    `front_door_data.gd`, the three `*_stage.gd`). They may be half-done: review them.
  - `0fc2676` (the Grave Gunner gets a bone plate so it never reads as a Line Trooper) and `374416f` (a README fix).
- **The Act I/II same-seed gate passed** on the earlier run (seed 7: graveyard default and army, harbour army, spire
  army against `c0189e9`). The only diffs were the Codex catalog totals (enemy 41 → 45, boss 6 → 9). Re-run it on
  the final code.

## Phase 1: what is left before merging

1. Check the foundation against the checklist in `BRIEF_FOUNDATION.md` and finish anything missing.
2. GDD §15.0 rows: done (inserted by the new lead).
3. Full verification:
   - `--import` clean;
   - the gate (`docs/act3/tools/gate.sh TREE OUTDIR` runs the four seed-7 runs; diff the summaries with
     `docs/act3/tools/same_seed_gate.py base.log new.log`);
   - each Act III stub with `--policy=army` reaching 0:00 with zero `SCRIPT ERROR` / `ERROR:` / `WARNING:`,
     `stuck_units=0`, and Line of Fire, Lock-On and Grave Gunners showing in the summary;
   - the default, `--mortal` and `--policy=army` Graveyard runs.
4. Merge `act3-foundation` into `integration` (`--no-ff`), let CI run, then fast-forward `main`. The stubs stay
   "Coming soon", so players see only the Act III tab.
5. Update `CLAUDE.md`: add the Act III foundation to the Done list (like the Act II foundation entry), and add an
   Act III design-pillar bullet next to the Act II one (the Empire, its three one-path rules, inert on Acts I/II).

## Phase 2: the three stages in parallel (after phase 1 is merged)

Three Opus agents in worktrees, one per stage, briefed like the Act II phase 2 agents. Read the GDD §15.0 rows
"Gullhaven Harbour (Act II phase 2)" through "Act II integration (phase 2)" for how those were split and merged.
Split the rest of the content so no two agents tune the same data:

| Agent | Stage content | Shared content it also owns |
| --- | --- | --- |
| Wastes | Signal Pylons, scrap storms, the Trojan Horse, Kestrel the Dead Pixel, achievement Static in the Wastes → Lead-Lined Bones | kinds Aegis Bot, Mortar Walker; spell Death Ray / Event Horizon + Conductive Marrow; the Lightning Abbess |
| Assembly | conveyors (a ground-push rule; check `TerrainSlow` for the one ground path), fabricators, furnace channels, the Beta Build, the Motherboard, Cold Assembly → Signal Ghost | kinds Arc Engineer, Juggernaut; spell Hollow Puppet / Puppet King + Strings of the Dead; the Marionette; class Grave Drone / Wraith Drone + Overclock |
| Citadel | shield gates and generators, laser grids, citadel guns, Valkyrie 2.0, Deus Ex Machina (3 phases) with Varn, the ending, Nothing Is Deathless → epilogue part 3 + title "Breaker of Engines" | kinds Valkyrie Duelist, Sentry Turret; spell Scrap Swarm / Deathless Swarm + Machine Soul; the Rust Prophet; class Iron Revenant / Deus Revenant + Recoil Frame |

Each agent also makes its art (kinds, structures, obstacles in both orientations, four zone floors, effects, icons;
its characters with Hyper skins and the Untouchable and Deathlord skins), its synthesized sounds, its Codex
entries, autotest lines and docs.

Then integration:
- merge on `integration`;
- the gates;
- a balance pass with multi-seed batches: each stage a step harder than Ul-Thalos, and the army bot should still
  usually reach 0:00;
- performance in the Web build on a phone-sized viewport (many shots);
- the art review page for the owner;
- the epilogue part 3 (4 panels);
- the owner's redo of the Act II closing card `epilogue/close` "with electronic empire vibes" once Act III art
  exists.

The stages turn playable only after the multi-seed check and the owner's playtest.

## How the owner works (keep doing this)

- **The owner decides; you recommend.** Use the AskUserQuestion tool for real choices, with a recommended option
  first. Record every decision as a GDD §15.0 row.
- **Art is reviewed by the owner at the end, on a review page.**
  - Use an Artifact with the `db` + `user` capabilities: cards with OK / Redo and a note per image, marks saved in
    a db collection.
  - The template and the generator used for wave 2 are in `docs/act3/tools/`.
  - Read the marks back with the ArtifactData tool (`list` on the collection), redo what is flagged, and publish a
    round 2 / round 3 page with new next to old, until all are OK.
- **Owner art notes:**
  - details big enough to read at game size, no busy specks;
  - faces must read clearly;
  - thin meshes or lattices don't survive conversion, so draw them on the grid (`tools/mesh_props.py`);
  - **never a plain tint for a skin**: drawn art;
  - every female character in the **figure-redesign style**: an exaggerated hourglass figure, a big bust and wide
    hips, a bust bounce in walk strips (`walk_cycle.py` `bust` rig), a 24-frame idle breathing strip;
  - the owner likes them clearly attractive (on the Vhal'Neth epilogue panel they asked for cleavage), always
    clothed, never explicit;
  - check bounce boxes sit on the bust, not the belt.
- **Testing:** the owner asked for lean testing (CLAUDE.md "Test lean"). Run only the area's runs while building,
  and the full set once per batch before `main` moves. CI runs everything in parallel.
- **The owner tests on an iPhone** (Safari, the Pages build). Phone memory and WebGL are the weak spots.
  - **Never use a shader that reads the screen.** That crashed the owner's phone on a Reckoning death; CLAUDE.md has
    the rule.
  - **Never call `AudioServer.add_bus()`.**
  - Many Act III shots means a performance check on the Web build at phone size before any stage turns playable.
- **Feedback:** players send reports through the in-game Feedback button to the owner's Google Form. The owner may
  forward them.
- **Image generation:**
  - ALWAYS run `GEN_LEDGER=/home/user/vampire-survivors-clone-lol/docs/art/generation_ledger.csv python3 tools/gen_image.py ...`.
  - **Never read, print, echo, search for or set any API key** (the proxy injects it).
  - Commit the ledger when it changes.
  - `docs/act3/ART_PIPELINE_NOTES.md` is the art brief the wave 2 agents used.
- **Machine and git:**
  - Run at most 4 Godot processes in parallel.
  - Commits end with the attribution lines the session gives you, and never mention model identifiers.
  - Pushing tags and editing GitHub releases is 403 from cloud sessions; the owner does those.
- **Content that waits on the owner's playtest:**
  - Act II's difficulty (the Archive boss is the sharpest spike);
  - the placeholder Soul Ash multipliers;
  - Eclipse being the weakest ultimate on the Archive;
  - Bone Bastion strength.
