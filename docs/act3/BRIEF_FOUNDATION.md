# Act III foundation (phase 1): brief

Lead's brief for the Act III foundation agent. Read it in full before starting.

You build **phase 1 of Act III** of **Necropathy**, a Godot 4.3 GDScript game in the Vampire Survivors genre. Act III pits the necromancer against **the Electronic Empire**, a machine power ("the Empire" for short). The owner approved the full proposal (the Claude Docs proposal "Necropathy: Act III Proposal (The Electronic Empire)"); its decisions are summarized below.

Phase 1 is the **shared foundation**, in the same shape as the Act II foundation. Read GDD §15.0, the row "Act II foundation (phase 1)", and copy its structure. After phase 1, three parallel agents will build the three stages on top of your work. Make the shared paths solid, documented and easy to extend; the stage agents will add only stage-specific content.

## Read first
1. `CLAUDE.md` (all conventions).
   - Document EVERY variable and constant with units.
   - Tunables go in `scripts/data/*.gd`, tagged `# TUNING (not in GDD)`.
   - Static typing; determinism per seed.
   - One path per modifier.
   - Pooling with generation checks.
   - No physics engine.
   - Autotest-friendly.
   - The UI rules.
   - **No shader may read the screen.**
   - **Never call `AudioServer.add_bus()`.**
   - Web and phone support.
2. `docs/GDD.md` §15.0. In particular, the rows from "Act II foundation (phase 1)" through "Act II integration (phase 2)": how Act II wired its faction (`EyeEnemyData`, Eye kits loaded by name from `scripts/enemies/eye/`), its shared rules (Claims, Dread: one path each, null on other acts), the unlocks (`UnlockData` / `Unlocks`), the stage stubs, the act tabs, the Codex tab, the palette ramps and the score-driven music.
   - Also read the rows "More ultimates (content wave 2)", "Bone Bastion", "Chest beacon", and the rule "no act-specific summon mechanics" (Content wave 2 row): **summons never get act-only rules**. The act's rules act on enemies and shots, never by changing how a summon class works in one act.
3. `README.md` (architecture tree, autotest options), `scripts/data/stage_registry.gd`, `scripts/data/stages/*_stage.gd` (look closely at `harbour_stage.gd`), `scripts/enemies/enemy_director.gd`, `scripts/enemies/enemy.gd`, `scripts/abilities/projectile_manager.gd`, the Eye folder `scripts/enemies/eye/`, `scripts/core/combat_resolver.gd`, `scripts/horde/horde_director.gd` (`spawn_temporary`, raises), `scripts/ui/stage_select.gd`, and `scripts/ui/codex_*.gd`.

## What Act III is (owner-approved decisions)
- **Faction:** the Electronic Empire, which conquered death with steel. Its citizens are rebuilt, not reborn, and it sees an undead army as a rival it must delete. It *saw* the Act II beacons burning and came; nobody called it.
- **Three stages** (ids are your choice, but use these names): Stage 7 **The Scrap Wastes** (boss Kestrel, the Dead Pixel), Stage 8 **The Assembly Halls** (boss the Motherboard), Stage 9 **The Iron Citadel** (boss Deus Ex Machina, with Varn, the Root User).
  - Suggested ids: `wastes`, `assembly`, `citadel`.
  - Each stage keeps the standard run: 20:00 clock, four zones changing with the clock, the boss at 3:00 left, the Reckoning at 0:00.
  - Act III opens when Vhal'Neth falls; each stage opens the next.
- **The gimmick:** about 60% of enemies attack from range (Act I is under 20%). Each shot is weaker (rifle shots 4-6 damage), but there are many more, fired from 380-520 px (from just off screen). The rules every act keeps still hold: enemies always advance (riflemen fire while marching; nobody kites), the undead never dodge.
  - The owner noted the volley system should keep this from becoming too hard.
- **Reckoning, "Purge Protocol":** at 0:00 orbital strikes rain down on telegraphed circles, faster each minute, while kill-drones pour in from every edge. The stage agents build the stage details; you build the shared Reckoning kind/hook if one is needed, following how Act II stages set their Reckoning.
- **Palette:** two new ramps, **chrome** (cold steel greys with a blue cast) for machines and **signal** (hard amber to warning red) for lights, lasers and screens. Soul-teal stays the undead's colour and violet the player's.
- **Music:** a synthesized run loop, **"Iron Requiem"**: a pulsing low synth, metallic hits and a cold arpeggio. Make it score-driven like "Below the Tide" (`SoundData.TIDE_SCORE`, `RunLoopSynth`), with no sound files. Also add new synthesized sound effects for rifle bursts, rail shots, servo steps and orbital strikes; any you don't need yet can wait for phase 2.

## The three shared rules (one code path each; inert on Acts I and II)
1. **Line of Fire: your dead are cover.** Every Empire shot travels as a real projectile and stops on the first summon in its path. The necromancer is hit only by shots that find a gap.
   - Bone Wall segments stop these shots; Warder barriers absorb them (as they absorb any hit).
   - Arcing shots (mortars, marked `arc`) ignore Line of Fire.
   - Use pooled, packed-array data with a hard cap, and check only the summons near each shot through the existing spatial hash. Act III has many shots, so performance matters: phones on Effects: Reduced draw fewer.
   - Check how the game already handles hostile projectiles (enemy arrows and bolts, Orb Shield interception, `ProjectileManager`) and extend that one path, or add a dedicated `EmpireShots` system if the existing one cannot scale. Either way, every hit goes through `CombatResolver.damage_unit()` / `damage_player()`.
   - Record stats for shots fired, blocked by summons, blocked by walls, absorbed by barriers, and reaching the player.
2. **Lock-On: the big shots are telegraphed.** Spotter elites paint a target (the necromancer or a summon) with a thin red laser for 1.5 s, then a heavy shot fires down that line.
   - Counters: Grave Step out of the line, put a summon in it (Line of Fire), or kill the spotter first.
   - Spotters glow red and rank high on every summon's target list. Do that through the existing targeting priority, not a new summon rule.
   - At most 3 painted lines at once; they must be drawn clearly.
   - Leave a documented hook for the future Act III counter-passive **Signal Ghost** (Lock-On lines take longer to paint on the necromancer), but don't build the passive itself.
   - Bosses will reuse this (e.g. a "missile salvo: four Lock-On lines at once" for the final boss may exceed the cap through a documented boss override).
3. **Steel has no soul: machines leave no corpse.** Each Empire kind is `machine` or `cyborg`.
   - Machines (drones, turrets, mechs) leave nothing to raise: no Corpse Explosion corpse, no Raise Dead / Death Mark Risen / Grave Tide / Lich raise, and the Carrion Lord's Grave Harvest isn't affected.
   - Find every raise / corpse path and gate it in ONE place (e.g. `Enemy.leaves_corpse()` or a flag read by those paths).
   - **The twist:** a cyborg raised as a temporary Risen **keeps its weapon** and fires it for you, as a "Grave Gunner": a temporary summon variant with a ranged attack. Add it through `HordeDirector.spawn_temporary()` so Restless Dead and the Grave Herald still apply.
   - Dread Rally's soul meter still charges from every kill.

## The shared enemy kinds (build these three in phase 1; they exercise the rules)
| Kind | Tier | Body | Range | What it does |
|---|---|---|---|---|
| **Scout Drone** | Fodder | Machine | Short | Fast flying swarms with small zaps; fly over obstacles |
| **Line Trooper** | Soldier | Cyborg | Long (400 px) | Three-round bursts while marching forward ("marching fire"); rises as a Grave Gunner |
| **Spotter** | Elite | Cyborg | Very long | Paints a Lock-On line, then fires the heavy rail shot down it |

The remaining six kinds (Aegis Bot, Mortar Walker, Arc Engineer, Valkyrie Duelist, Sentry Turret, Juggernaut) are phase 2, built by the stage agents. Your data table and kit loader must make adding them easy.

## Foundation scope (mirror the Act II foundation)
- **Stages:** three registered stages (`*_stage.gd`) as **stubs** behind `"playable": false` ("Coming soon" on the stage select), act 3. Each stub has:
  - its unlock chain: wastes opened by Vhal'Neth, then each stage opening the next;
  - its own boss id with a placeholder script;
  - a placeholder timeline using the three shared kinds, so `--stage=<id>` runs a full autotest (stage locks are ignored there);
  - a simple placeholder floor (code-drawn or one flat tile is fine; the stage agents make the real floors and obstacles);
  - the Iron Requiem music;
  - a Soul Ash multiplier placeholder.
- **Stage select:** an **Act III tab**, the same way Act II got its tab.
- **Faction data and code:** `EmpireEnemyData` (shared kinds; per-stage tables later), looked up by `EnemyDirector.enemy_def()` like `EyeEnemyData`. Empire kits load by name from `scripts/enemies/empire/`. Add the `machine` / `cyborg` body flag.
- **Codex:** an **Electronic Empire tab** (kinds and bosses fill in as met, dark silhouettes until then, like the Ancient Eye tab).
- **Palette and sprites:** the chrome and signal ramps in the palette. A sprite folder `empire/` with code-glyph fallbacks (`EmpireGlyphs`, like `EyeGlyphs`) for every kind.
- **Art for the three shared kinds:** a still and a walk or glide strip each, made with the art pipeline.
  - Read `docs/art/ART_BIBLE.md` and the art section of `/tmp/claude-0/-home-user-vampire-survivors-clone-lol/d5c098ec-bb2d-5b61-bfc3-6ed79c1e8fd5/scratchpad/wave2/BRIEF_COMMON.md`.
  - ALWAYS run `GEN_LEDGER=/home/user/vampire-survivors-clone-lol/docs/art/generation_ledger.csv python3 tools/gen_image.py ...`. Never read, print, echo, search for or set any API key or OPENAI_API_KEY.
  - Owner art notes: details big enough to read at game size, no busy specks, faces read clearly, thin lattices don't survive conversion.
  - These three set the Empire's visual style for the stage agents, so make them strong and consistent: chrome bodies, signal-amber lights, hard clean silhouettes against the undead's bone and teal.
- **Autotest:**
  - `--stage=wastes|assembly|citadel` (or your ids).
  - `--spawn=` works with the new kinds.
  - Summary lines `line of fire`, `lock-on` and `steel` (machine vs cyborg kills, Grave Gunners raised, their damage).
  - Per-stage report line like Act II's.
- **Gate:** stages 1–6 keep their same-seed autotest summaries.
  - Run `--seed=7` on `graveyard` (default and `--policy=army`), plus `harbour` and `spire` (army), on your branch and on the base (`origin/integration`, commit c0189e9 or newer), and diff the `[autotest]` / `[metric]` lines.
  - The only allowed diffs are catalog counts the new content naturally adds (e.g. Codex totals, recipe/stage counts). List them.
- **Act III playability check:** `--stage=<each id> --policy=army` must reach 0:00 with zero errors and `stuck_units=0`, and show Line of Fire blocking shots, Lock-On firing and Grave Gunners rising in the summary.
  - Don't balance yet; just make sure it isn't broken (e.g. the army bot shouldn't die by 3:00 to rifle fire).
- **Docs:**
  - GDD §15.0 rows at the end of the table (just before `### 15.1 Core Rules and Run Structure`): one "Act III foundation (phase 1)" row and one per shared rule if it helps.
  - README: architecture tree, autotest options, the Act III section.
  - ART_BIBLE rows for the new art.
  - Leave CLAUDE.md to the lead.

## Process rules
- Work on branch `act3-foundation` in your worktree; commit in sensible steps and push the branch as a backup (`git push -u origin act3-foundation`).
- Never push to `main` or `integration`.
- Commit messages via `git commit -F <file>`, ending with exactly:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
  `Claude-Session: https://claude.ai/code/session_01FLPv2RqRe5qVsRWxUhur7z`
- Never mention model identifiers.
- CPU: you may run up to 3 Godot processes in parallel (nobody else is running).
  - Binary: `/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64`.
  - `--headless --import` must be clean.
  - Autotest: `--headless --fixed-fps 60 --quit-after 15000 -- --autotest [options]`.
- Logs and screenshots go under `/tmp/claude-0/-home-user-vampire-survivors-clone-lol/d5c098ec-bb2d-5b61-bfc3-6ed79c1e8fd5/scratchpad/act3/foundation/`.
- Screenshot a running Act III stub at 1280×720 (xvfb; helpers to copy are in `.../scratchpad/wave2/C/ui/`), showing the three kinds, a Lock-On line, shots being blocked by the Bone Ring and a Grave Gunner. Look at the screenshots yourself.

## Final report
Your last message:
- branch and commits;
- what you built (files);
- shared files touched and why;
- the extension points the stage agents must use (exact names);
- GDD rows;
- test results (numbers, the gate diff);
- every new PNG and its cost;
- anything left open or decided on your own.
