# Act V phase 2: brief for the three stage agents

The lead wrote this brief when the foundation merged (Oct 26, 2026).

Three agents run at once, one per stage. Each works in its own git worktree, on its own branch made from the lead's
branch that holds the merged phase 1 foundation. Afterwards the lead merges the three branches and runs one big test
pass.

This is the plan that built Act IV: `docs/act4/BRIEF_PHASE2.md`. Read it too. Its "Shared files" and "Testing"
sections apply here unchanged, apart from the names below. Read this brief in full, then the section for YOUR stage.

## Read first
1. `CLAUDE.md`. Every convention applies, including:
   - **no shader may read the screen**;
   - **never call `AudioServer.add_bus()`**;
   - **summons never get act-only rules**;
   - in co-op, read the necromancer through the bound slot;
   - prefer textures over polygons redrawn every frame (the Web GL rule).
2. `docs/act5/PROPOSAL.md`, the owner-approved design. Your stage's section and its rewards are the spec.
3. `docs/GDD.md` §15.0:
   - the Act V rows: "Act V foundation (phase 1)", "The Sun's Course (Act V)", "The Draw (Act V)", "From the Shadows
     (Act V)", "Act V art: the shared kinds" and "The Setting Sun and the Shogunate sounds";
   - for how a stage was built last time, the Act IV phase 2 rows, from "The Shores of Ilion (Act IV phase 2)" to
     "Act IV integration (phase 2)".
4. `docs/act4/HANDOFF.md`.
5. `README.md`.
6. The code you build on:
   - your stub, `scripts/data/stages/<id>_stage.gd`;
   - the Shogunate folder, `scripts/enemies/shogunate/`;
   - `shogunate_enemy_data.gd`, `shogunate_rules_data.gd` and your stage's empty table;
   - the Act IV stage closest to yours.
7. Art: `docs/art/ART_BIBLE.md` section "Act V: the Shogunate of the Rising Sun, the shared kinds", and the concept
   art `art_source/concepts/act5_*.png`.
   - The pipeline that worked: `prepare_sprite.py` straight on the source, `--ramps lacquer,indigo,sakura,grey,gold,skin,brown --ink-l 0.22`.
   - The mixed lineup: male soldiers, and the female kinds in the figure-redesign style. Those get exaggerated
     hourglass figures, fully clothed, a `bust` rig and a 24-frame idle strip.
   - Name each figure's sex in every prompt.
   - Owner art notes from the Act IV review:
     - details must be big enough to read at game size;
     - don't over-focus on one costume part;
     - a female figure "a bit scandalous" is fine, but never nudity, and no notch or gap that reads as anatomy.

## Extension points of the foundation (use these; do not fork them)
- **The rule object:** `Game.shogunate` (`ShogunateRules`), created by the STAGE key `shogunate`. It is null on Acts
  I–IV.
- **The Sun's Course** (`SunCourse`):
  - clock: `phase()` / `phase_at(t)`, `is_night()`, `is_dusk_or_later()`;
  - light: `light_at(pos)`, `in_lit_pool(pos)`, `darkness_alpha()`, `ambient()`;
  - timeline helpers `timeline_weights(seg)` / `filter_groups(groups)`;
  - the Paper Lanterns hook `lantern_mult(pl)`;
  - per-stage overrides through the STAGE key `sun` (`dusk_banner` / `night_banner` too).

  A boss that changes the sky (Amaterasu) adds ONE public override entry on `SunCourse` (e.g.
  `set_override(phase_or_sky, opts)` / `clear_override()`) that `phase()`, `light_at()` and the darkness read. The
  Road to the Sun owns that change. Never write a second lighting path.
- **The Draw** (`DrawCuts`):
  - `draw(source, from, dir, opts)`, with opts `flash`, `length`, `width`, `dmg_player`, `dmg_summon`, `dash`, `tag`
    and `boss_override` (up to 9 lines, several per drawer);
  - `has_line(e)`;
  - the Unbending hook `unbending_mult(u)`.

  The Shogun's iai duel and any boss's draw-cut use this path.
- **From the Shadows** (`ShadowAmbush`): `start_event(ev)`. Timeline event type `ambush`; segment key
  `ambush: {every, kind, count, elite}`.
- **Kinds:**
  - Add rows to YOUR table (`ProvinceEnemyData` / `KuroganeEnemyData` / `SunRoadEnemyData`, looked up by
    `EnemyDirector.shogunate_def()`).
  - Row keys: `night`, `draws`, `draws_always`, `ambusher`, `ethereal`, `fodder`, `floating`.
  - Kits go in `scripts/enemies/shogunate/<id>_kit.gd`, extending `ShogunateKit` (`can_draw(e)`,
    `start_draw(e, at, opts)`, `light(e)`, `is_night_kind()`, `is_ambusher()`, `is_ethereal()`, `rules(e)`).
  - Kit ids must be unique across the Eye, Empire, Pantheon and Shogunate folders.
  - The one summon stun path is `CombatResolver.stun_unit()`.
  - Enemy buffs and debuffs go through the existing one paths (look at how Ares's war-cry and the Banner Bearer do it).
- **Sounds:** `ShogunateRules.play_sound(event, pos)`, with events in `ShogunateRulesData.SOUNDS`. New sounds go in your
  own block of `SoundData.SHOGUNATE_SOUNDS`; they load lazily with the `sun` music.
- **Bosses:**
  - `scripts/enemies/shogunate/boss_<id>.gd` (extends `Boss`). Remove your stub's placeholder `script` key
    (`EnemyDirector.SHOGUNATE_BOSS_DIR`).
  - Minibosses register through `EnemyDirector.set_miniboss()`; `ChestManager` drops the chest.
- **Reckoning:** the Endless Night is shared. Tune it only through your stage's `RECKONING` keys (`endless_night`,
  `companions`).
- **Report:** add your stage's line to `ShogunateReport` (your own block). Keep the foundation lines unchanged.
- **Codex:** `CodexData.SHOGUNATE_SOLDIERS` / `_CHAMPIONS` / `_BOSSES`.
- **Unlocks, spells, characters, classes, counter-passives, achievements, epilogue:** do these exactly as Act IV did:
  - `UnlockData` / `Unlocks`;
  - the one `NecroSpellBook` dispatch;
  - `character_data.gd` and `game.character.innate_value()`;
  - one `SummonBehavior` per class that works the same on every stage;
  - PassiveData rows offered only in Act V through the card row's `act`;
  - `EpilogueData` hooks like `ACT4_PART`.

## Shared files
- Keep edits small, additive and in a block headed `# --- Act V: <your stage> ---` at the END of the table or list it
  extends.
- Never reorder or reformat existing lines.
- Do not tune data another stage owns, and do not touch Act I–IV stages' data.
- Lesson from the Act IV merge: git keeps identical trailing lines once. So end each dict entry or `match` arm you add
  with a line unique to it, such as a comment naming the kind.

## Testing and process
**Testing** is as Act IV:
- `--import` clean while building.
- **Once, at the end:** one `--stage=<id> --policy=army --seed=7` run. It must reach 0:00 with zero errors and
  `stuck_units=0`, and show your new systems in the summary. Use `--spawn=` / `--boss=` in the same run where needed.
- Art: run `tools/art_check.py` and make a contact sheet in your scratch dir.
- **CPU: at most ONE Godot process at a time.**
- Keep your stage `"playable": false`.

**Process:**
- Your branch and worktree are named in your section. Commit in steps.
- **Do not push.**
- Commit messages end with exactly:

  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01TjA5CNwUWb95gMazj5Z3qp
  ```

  Never mention model identifiers.
- Image generation: ALWAYS `GEN_LEDGER=<your worktree>/docs/art/generation_ledger.csv python3 tools/gen_image.py ...`
  with an absolute path, and commit the ledger rows. Budget about $0.70.
- **Never read, print, echo, search for or set any API key**; the proxy injects it.
- Scratch dir: `/tmp/claude-0/-home-user-Vampire-Survivors-Clone-Lol/b0031aa1-78e2-5d60-8763-4014a0c61c3c/scratchpad/act5/<id>/`.
- Docs:
  - GDD §15.0 rows for your stage and every reward, at the end of the table;
  - README lines;
  - ART_BIBLE rows;
  - leave CLAUDE.md to the lead.
- Your final message covers:
  - the branch and commits;
  - the files you added;
  - the shared files you touched;
  - the decisions you made on your own;
  - the test result;
  - every PNG and its cost;
  - anything left for the lead.

---

## Agent A: the Burning Province (`province`, Stage 13)
Branch `act5-province`, worktree `/home/user/wt/act5-province`.

- **Stage:** rice terraces, bamboo groves, a village in flames.
  - Zones: the Paddies (water slows everyone, through `TerrainSlow`, the one ground-slow path), the Bamboo Grove (dense
    obstacles, ninja heaven: ambushes more frequent), the Burning Village (burning houses as obstacles; fire patches
    as textures), the Mountain Shrine.
  - Four zone floors as tiles, obstacles in both orientations.
- **Miniboss: Shuten-dōji, the Oni King**, at night only. Drunk and enormous, he throws sake barrels that burst into
  fire, with landing circles.
- **Boss: Kage, Mistress of the Hidden Hand** (`boss_kage.gd`; figure-redesign style, female). The ninja grandmaster:
  - she splits into shadow clones, of which only one is real, **revealed by light** (`SunCourse.light_at()`: a clone
    in light shows as false);
  - she plants smoke fields;
  - she throws chained kunai that pull a summon out of the ring. This is an enemy effect on a unit, through one
    documented pull path, not a summon rule.
- **Kinds:**
  - **Kunoichi**: elite, female, figure-redesign style. Smoke bombs blind summons for 2 s through one documented
    debuff path; a lunge at the necromancer.
  - **Kappa**: night yokai fodder of the paddies. Water-strong (no slow in water), it grapples a summon briefly.
- **Spell:** **Hundred Shadows**, unlocked by Kage: shadow clones of the necromancer echo the next spell cast. It
  evolves into **Thousand Shadows**, paired passive **Hidden Hand**.
- **Character:** the **Grave Kunoichi** (figure-redesign style, female), with a Hyper skin and the Untouchable and
  Deathlord skins.
- **Achievement:** **No Shadow Unlit**. Define it (e.g. clear the Province having lit every stone lantern, or killed
  every ambush squad in light) and record it. It unlocks the counter-passive **Paper Lanterns**: build the PassiveData
  row on `SunCourse.lantern_mult()` (a wider light radius, ambushes show earlier), offered only in Act V.

## Agent B: Castle Kurogane (`kurogane`, Stage 14)
Branch `act5-kurogane`, worktree `/home/user/wt/act5-kurogane`.

- **Stage:** the Shogun's fortress. Zones: the Outer Bailey, the Gatehouse, the Courtyards, the Keep. Stone walls,
  gates, courtyards; four zone floors as tiles, obstacles in both orientations.
- **Miniboss: the General of the Left.** A mounted samurai who charges through the ring on a telegraphed line.
- **Boss: Shogun Kurogane** (`boss_shogun.gd`). His army is his health bar (owner idea; owner: "give him Iai style
  slashes"):
  - **Command platform.** He stands on a command platform at first, untargetable, signalling with a war fan.
  - **The bar.** His HUD bar (the one boss bar) is the soldiers he has left, about 600 in six regiments, each with its
    own banner colour. Every Shogunate kill takes a point off it.
  - **Regiment orders.** Each regiment arrives with a different order: an arquebus line, a spear wall, a cavalry
    charge, a ninja ambush (through `ShadowAmbush`), a samurai duel squad (the Draw).
  - **Hatamoto.** Killing a regiment's **Hatamoto** breaks it: the rest flee and count as lost.
  - **The duel.** Under 10% he draws his own blade and comes down with his honour guard for a short final duel. It is
    fought with iai slashes through `DrawCuts.draw()` with `boss_override`: white lines flashed across the arena,
    faster as his guard falls, and his last move is a **triple cut** of three lines at once.
  - **Timing.** The fight must fit the 3:00 boss window. Size the regiments so a decent army breaks most of them in
    time.
- **Kinds:**
  - **Hatamoto**: elite banner guard. Nearby soldiers fight harder while he stands, through the one enemy-buff path;
    kill the banner.
  - **Kiba-musha**: mounted samurai cavalry, a charging soldier; the regiments' cavalry.
- **Spell:** **Banner of the Dead**, unlocked by the Shogun: a war banner planted where you stand, summons near it
  attack faster. This is a spell effect through the summon stat path, the same on every stage. It evolves into
  **Hundred Banners**, paired passive **Warlord's Seal**.
- **Character:** the **Ronin Revenant** (male), with a Hyper skin and the Untouchable and Deathlord skins.
- **Achievement:** **Regiments Broken** (beat the Shogun after breaking all six banners). It unlocks the
  counter-passive **Unbending**: build the PassiveData row on `DrawCuts.unbending_mult()` (Draw cuts hit summons for
  less), offered only in Act V.

## Agent C: the Road to the Sun (`sun_road`, Stage 15, the finale)
Branch `act5-sun-road`, worktree `/home/user/wt/act5-sun-road`.

- **Stage:** a pilgrim road of torii gates climbing to the sun goddess's shrine above the clouds. Zones: the Torii
  Road, the Sacred Forest, the Shrine Steps, the High Plain of Heaven. Four zone floors as tiles, obstacles in both
  orientations.
- **Miniboss: the Kirin**, a holy beast of light.
- **Boss: Amaterasu** (`boss_amaterasu.gd`; figure-redesign style, female). Her place in the sky is the phase, through
  the ONE `SunCourse` override you add:
  - **East (dawn).** She rises on the arena's east edge: slow sweeping beams from her mirror, sun-disc mines.
  - **North (noon).** Directly overhead: the whole arena is bright and hot, beams fall straight down on marked
    circles, and the shadows of obstacles are the only safe ground.
  - **West (sunset).** She sinks to the west edge: a wide setting-sun beam that crosses the arena, the light turns
    red, night closes in.
  - **Her fall.** When she falls, the sun goes out and the Reckoning is the Endless Night. Write her ending text like
    Hades' and Vhal'Neth's.
  - **Web.** Beams and heat drawn as textures; no screen-reading shader.
- **Kinds:**
  - **Kitsune**: night support, female, figure-redesign style. Fox-fire illusions: decoy enemies the summons waste
    attacks on, revealed in light or by area damage.
  - **Sōhei**: a warrior monk with a naginata; soldier, a sweeping cut.
- **Spell:** **Black Sun**, unlocked by Amaterasu: a dark sun orbits the necromancer and fires a short beam at the
  nearest group. It evolves into **Eclipse of Heaven**, paired passive **Stolen Dawn**.
- **Character:** the **Shrine Maiden of Night** (figure-redesign style, female), with a Hyper skin and the Untouchable
  and Deathlord skins.
- **Summon class:** the **Oni**, the finale's reward. Bound oni brutes with kanabō: a heavy blocker with a stun smash.
  - One `SummonBehavior`, the same on every stage.
  - Its own sprite, made from the shared `oni`'s style but bound, bone-chained, soul-teal eyes.
  - It evolves into **Oni Lord** with a paired passive: name it and record it.
- **Achievement:** **The Sun Goes Out** (beat Amaterasu). It opens the Act V epilogue part **"The Sun Goes Out"**:
  leave a documented hook in `epilogue_data.gd` like `ACT4_PART`; the panels are made at integration. It also opens the
  next closing card, **"The Pit Keeps Count"**: a row in `EpilogueData.CLOSINGS` whose `after` is the Act V part. Its
  text is in the proposal; its panel is made at integration.
