# Act VI phase 2: brief for the three stage agents

The lead wrote this brief when the foundation merged (Oct 31, 2026).

Three agents run at once, one per stage, each in its own worktree on its own branch, made from the lead's branch that
holds the merged foundation. The lead has the branches merged and runs one big test pass afterwards.

This is the Act V plan: `docs/act5/BRIEF_PHASE2.md`. Read it; its "Shared files" and "Testing and process" sections apply
here unchanged, with Act VI names. Read this brief in full, then your stage's section.

## Read first
1. **`CLAUDE.md`.** Every convention applies, in particular:
   - no shader may read the screen, and prefer textures over polygons redrawn every frame;
   - never call `AudioServer.add_bus()`;
   - **summons never get act-only rules**: charm, pull and swallow are enemy effects on units, through the existing one
     paths;
   - co-op reads the necromancer through the bound slot.
2. **`docs/act6/PROPOSAL.md`.** The owner's decisions are at the top; your stage's section and its rewards are the spec.
   - **No epilogue part and no closing card**, and no epilogue hook: the owner holds those until the act order is settled.
   - **The Morning Star has two phases** (the Angel, the Beast). The Throne phase is cut.
3. **`docs/GDD.md` §15.0:** the Act VI rows ("Act VI and the act order", "Building the rest of the planned content", "Act
   VI foundation (phase 1)", "Hell Pits", "Portals", "Temptation", "Act VI art: the shared kinds", "Hymn of the Pit and
   the Inferno sounds"), and the Act V phase 2 rows for how a stage was built last time.
4. **`README.md`**, your stub `scripts/data/stages/<id>_stage.gd`, the Inferno folder `scripts/enemies/inferno/`,
   `inferno_enemy_data.gd`, `inferno_rules_data.gd`, your stage's empty table, and the Act V stage closest to yours.
5. **Art.** Read the ART_BIBLE section "Act VI: the Inferno, the shared kinds" and the concept art
   `art_source/concepts/act6_*.png`.
   - **The approved target is `act6_units.png`** (owner: "perfect"). Its succubus, lilim witch and fallen angel set the
     level: the most exaggerated hourglass figures in the game, sultry poses, lingerie-styled corsets, bare backs,
     shoulders, midriffs and thighs, high slits, stockings, thigh-high boots. **Chest and hips are always covered; no
     nudity.**
   - Male units use the original models (`act6_lineup.png`).
   - The image API refuses wording past the line. The foundation's succubus prompt shows wording that passed: "sleek
     black leather corset-style bodysuit, high-cut hip, V neckline, bare midriff strip, bare shoulders and back,
     thigh-high stockings and boots, fully clothed". Name each figure's sex.
   - Female figures get a `bust` rig, the hip `swish`, and an idle strip. Fliers glide (robe mode) or hover.
   - Convert with `prepare_sprite.py` on the source and the `inferno/` ramps; `--no-levels` where demon skin washes out.

## Extension points of the foundation (use these; do not fork them)
- **The rule object.** `Game.inferno` (`InfernoRules`), created by the STAGE key `inferno`. It is null on Acts I–V.
- **Hell Pits:**
  - `game.inferno.pits.open_pit(at, radius, life, opts)` (opts `telegraph`, `tag`, `dps_mult`, `silent`);
  - `HellPits.burning_at(p, r)`, `avoid_point(p, r)` (the one avoid check the horde reads), `burns_enemy(e)`;
  - Salt Circle: `HellPits.salt_circle_mult(u)`, which reads PassiveData `salt_circle` / key `pit_reduction`;
  - the STAGE key `pits` overrides the defaults.
- **Portals:**
  - `game.inferno.portals.open(at, opts)` (opts `table`, `pour_every`, `pour_first`, `reckoning`, `silent`);
  - the timeline event `{"type": "portal", count, banner, distance_min, distance_max, table, pour_every}`;
  - the STAGE key `portals`, whose `table` holds squad rows `{kind, count, weight}`;
  - a `demon_portal` spawned any other way is adopted. Its sprite key is `structures/demon_portal`.
- **Temptation:**
  - `HordeDirector.charm(unit, by, duration, opts)` (opts `tint`, `name`, `source`, `ignore_cap`, `no_temporary`) and
    `HordeDirector.break_charms(by)`;
  - `InfernoKit.try_charm(e, u, duration, opts)`;
  - Faithless: `Temptation.faithless_mult(u)`, which reads PassiveData `faithless` / key `charm_reduction`;
  - breaking a charmed body frees the summon at 15% HP. **A boss that "swallows" or "turns" summons (Moloch, Lilith)
    uses this same charm path**, with its own opts.
- **Kits.** Extend `InfernoKit` (row flags `demon`, `flier`, `charmer`, `damned`). Bosses go in
  `scripts/enemies/inferno/boss_<id>.gd`; remove your stub's placeholder `script` key. Minibosses register through
  `EnemyDirector.set_miniboss()`.
- **The Reckoning:** the Last Judgment is shared. Tune it only through your stage's `RECKONING` `last_judgment` keys.
- **Sounds:** `InfernoRules.play_sound(event, pos)` with events in `InfernoRulesData.SOUNDS`. New sounds go in your own
  block at the END of `SoundData.INFERNO_SOUNDS`; pack seeds depend on order, so never insert in the middle.
- **Report:** a stage block in `InfernoReport.print_lines()`.
- **Codex:** the Inferno lists in `CodexData`.
- **Unlocks, spells, characters, classes, counter-passives, achievements:** as Act V (`UnlockData` / `Unlocks`, the one
  `NecroSpellBook` dispatch, `character_data.gd`, one `SummonBehavior` per class that works the same on every stage,
  PassiveData rows offered only in Act VI through the card row's `act`), plus each new class's Ossuary mastery
  (`mastery_data.gd` `CLASSES` and `FLAVOUR`, and the price total in `tools/ossuary_check.gd`). **Ids must not collide
  with enemy kinds:** use `bound_succubus` for the Succubus class (as Act V used `bound_oni`), and give the Temptation
  spell an id other than `temptation`.

## Shared files, testing and process
- **Shared files.** Use blocks headed `# --- Act VI: <your stage> ---` at the END of what they extend. End each dict
  entry or `match` arm with a line unique to it. Don't tune another stage's data or any earlier act's.
- **Testing:**
  - `--import` clean while building.
  - **Once at the end:** one `--stage=<id> --policy=army --seed=7` run that reaches 0:00 with zero errors and
    `stuck_units=0` and shows your systems in the summary. Use `--spawn=` / `--boss=` / `--spells=` / `--classes=` /
    `--character=` where needed.
  - Run `tools/art_check.py` and make a contact sheet.
  - **CPU: at most ONE Godot process at a time.**
  - Keep `"playable": false`.
- **Process.** Commit in steps and **do not push**. Commit messages end with exactly:

  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01TjA5CNwUWb95gMazj5Z3qp
  ```

  - Image generation: `GEN_LEDGER=<worktree>/docs/art/generation_ledger.csv python3 tools/gen_image.py ...`, absolute
    path. Budget about $0.70.
  - **Never read, print, echo, search for or set any API key.**
  - Scratch dir: `/tmp/claude-0/-home-user-Vampire-Survivors-Clone-Lol/b0031aa1-78e2-5d60-8763-4014a0c61c3c/scratchpad/act6/<id>/`.
  - Docs: GDD §15.0 rows for your stage and its rewards, README lines and ART_BIBLE rows.
- **Final message:** the commits, the files, the shared files touched, the decisions you made on your own, the test
  result, every PNG and its cost, and anything left for the lead.

---

## Agent A: the Burning Gate (`burning_gate`, Stage 16)
Branch `act6-burning-gate`, worktree `/home/user/wt/act6-burning-gate`.

- **Stage:** a plain of ash and obsidian before the gate of hell, with the river of fire Phlegethon along its edge.
  - Zones: the Ash Plain, the Cages, the River of Fire (a burning band through `HellPits`), the Gate.
  - Four zone floors as tiles, obstacles in both orientations.
- **Miniboss: the Gatekeeper.** A chained giant who drags the damned in: chains pull the damned and summons toward him,
  through one documented pull path (as Kage's kunai did). Slams.
- **Boss: Moloch, the Furnace King** (`boss_moloch.gd`). A colossal bull-headed demon with a furnace for a belly.
  - He **swallows summons**: they come back burning as his for 6 s, through the charm path.
  - He vents fire waves.
  - He cracks the arena into pits (`open_pit`).
  - Two or three phases.
- **Kinds:**
  - **Hellhound:** a pack of lava hounds that leave a short fire trail of small pits.
  - **Pit Cultist:** living humans, support. They open new portals (`portals.open`), so they are a priority target.
- **Spell:** **Brimstone**, unlocked by Moloch: burning stones fall on the densest group and leave a short pit. Your own
  pits never hurt your army: a spell's pit tags itself and burns enemies only. It evolves into **Rain of Fire**, with the
  paired passive **Furnace Heart**.
- **Character:** the **Furnace Priest** (male), with a Hyper skin and the Untouchable and Deathlord skins.
- **Achievement:** **Gate Crashed** (define it; e.g. beat Moloch having sealed N portals). It unlocks the counter-passive
  **Salt Circle**: build its PassiveData row on the existing hook, Act VI only.

## Agent B: the Palace of Silk and Ash (`silk_palace`, Stage 17)
Branch `act6-silk-palace`, worktree `/home/user/wt/act6-silk-palace`.

- **Stage:** the court of desire: velvet halls, mirrors, rose gardens of black thorns, a ballroom over a lava lake.
  - Zones: the Rose Garden, the Hall of Mirrors, the Ballroom, the Queen's Chamber.
  - In the Hall of Mirrors, reflections of the necromancer confuse summon targeting. Use the existing `misdirect()`
    summon hook, as an effect of the ground.
- **Miniboss: the Twin Succubi** (female, Act VI style). Two sisters who charm in turns; kill one and the other rages.
- **Boss: Lilith, Queen of the Night, Mother of Demons** (`boss_lilith.gd`; the style at its height, still within the
  line).
  - **Charm waves** turn a whole arc of the ring for a few seconds (the charm path with `ignore_cap`).
  - **A kiss marks the necromancer:** while marked, every heal on him is turned into damage for 5 s. Use one documented
    check in the one heal path in `CombatResolver`.
  - **Demon children** are born from her wings.
  - **A final phase in her true demon form.**
- **Kinds:** the **Lilim Witch** (support, female, Act VI style). She opens small pits under the ring and heals demons
  near a portal.
- **Spell:** **Temptation**, unlocked by Lilith (id other than `temptation`): charm the strongest nearby enemy to fight
  for you for 6 s. It works on enemies, and it is a spell, so it does not use the summon charm path. It evolves into
  **Unholy Desire**, with the paired passive **Velvet Chains**.
- **Character:** the **Succubus Queen** (female, the style at its height), with a Hyper skin and the Untouchable and
  Deathlord skins.
- **Summon class:** the **Succubus** (`bound_succubus`, unlocked by Lilith, like the Fallen Seraph by Seraphine). A
  flying charm support: it charms enemies briefly to fight beside the army. Its evolution is the **Lilim Matriarch**;
  name the paired passive and record it. Give it its Ossuary mastery.
- **Achievement:** **Unmoved** (beat Lilith without a single summon charmed). It unlocks the counter-passive
  **Faithless**: build its row on the existing hook, Act VI only.

## Agent C: Pandemonium (`pandemonium`, Stage 18, the finale of Part One)
Branch `act6-pandemonium`, worktree `/home/user/wt/act6-pandemonium`.

- **Stage:** the capital of hell: an obsidian cathedral city, chains, rivers of lava, the throne.
  - Zones: the Iron City, the Chain Bridges, the Cathedral of Ash, the Throne.
- **Miniboss: the Fallen Seraph General.**
- **Boss: the Morning Star** (`boss_morning_star.gd`), **two phases**:
  - **the Angel:** beautiful, six burnt wings, a burning sword, light and dark beams;
  - **the Beast:** the throne-skull form, huge and slamming, the whole arena turning to pits.

  **No Throne phase.** When he falls, his ending text has the necromancer take the throne (keep it short; no epilogue).
- **Kinds:** the **Fallen Angel** (elite, female, Act VI style). She dives from above with a burning spear. Gargoyles and
  ranged attacks answer her.
- **Spell:** **Fall from Grace**, unlocked by the Morning Star: a fallen star crashes on the strongest enemy. It evolves
  into **Lightbringer**, with the paired passive **Pride**.
- **Character:** the **Fallen Saint** (female, figure style), with a Hyper skin and the Untouchable and Deathlord skins.
- **Summon class:** the **Archfiend** (`archfiend`, the finale's reward): a winged heavy demon. It evolves into the
  **Prince of Hell**; name the paired passive and record it. Give it its Ossuary mastery.
- **Achievement:** **Morning Star Falls** (beat the Adversary). No epilogue: it only records the clear (title or Codex
  line as Act V did).
