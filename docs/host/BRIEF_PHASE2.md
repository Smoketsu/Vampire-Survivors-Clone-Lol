# The Celestial Host, phase 2: brief for the three stage agents

Written by the foundation agent for the lead (branch `claude/determined-pasteur-hdy1g6`, base `45b231ba`). The lead adds the
merge commit, the owner's phase 2 answers (if any) and the session line before handing it out.

Three agents run at the same time, one per stage, each in its own worktree on its own branch made from the lead's branch
that holds the merged foundation (code, art and audio). The lead merges the branches and runs one big test pass after.

This is the plan that built Acts IV to IX and the Dynasty: `docs/dynasty/BRIEF_PHASE2.md` is the closest model (and through
it `docs/act9/BRIEF_PHASE2.md`). Its "Process" section applies unchanged with the Host's names, blocks headed
`# --- Act XIII (temporary number): <your stage> ---`, and your own scratch dir.

## Read first
1. **`CLAUDE.md`** (it wins). In particular: no shader may read the screen (the Verdict's whiteness and Be Not Afraid's
   "the screen whitens" are flat additive rects, never a screen read), textures over polygons redrawn every frame, never
   `AudioServer.add_bus()`, **summons never get act-only rules** (the Light's burn, the pillars, the Voice's stop are
   enemy effects through the one paths: `damage_unit()`, `CombatResolver.stun_unit()`, `HallowedLight.add_shaft()`), co-op
   reads the necromancer through the bound slot.
2. **`docs/last_acts/PLAN.md`:** temporary act number 13, **tune for the final slot X** (at or just above the Inferno),
   no epilogue part and no closing card yet (the Voice's ending is a short text only; the Part One epilogue waits for the
   reorder pass), **original names** (Seraiel, the Throne, the Voice; never scriptural names), female figures in the
   figure-redesign style (clothed), **no crimson and no warm gold** on any Host figure.
3. **The design:** `docs/proposals/LAST_SIX_ACTS.md` section "X. The Celestial Host" (your stage's section and the
   Rewards table are the spec; the owner took every recommendation of its open questions, so Grace stays "the first hit of
   each kind"). Concept art: `art_source/concepts/act15/host_lineup.png`, `host_bosses.png`, `host_stage.png`.
4. **`docs/GDD.md` §15.0:** "The Celestial Host foundation (phase 1)", "Judgment", "Hallowed Light", "Grace", "The Last
   Trumpet", the Host art and audio rows when they land, and the Dynasty phase 2 rows for how a stage was built last time.
5. **The code:** `README.md` (*Act XIII: the Celestial Host*), your stub `scripts/data/stages/<id>_stage.gd`, the folder
   `scripts/enemies/host/` (`host_rules.gd`, `judgment.gd`, `judgment_bar.gd`, `hallowed_light.gd`, `cloud_shade.gd`,
   `grace.gd`, `last_trumpet.gd`, `host_kit.gd` and the kits), `host_enemy_data.gd`, `host_rules_data.gd`,
   `scripts/core/host_report.gd` / `host_ground.gd` / `host_glyphs.gd`, your stage's empty table, `docs/host/ART_MANIFEST.md`.

## Extension points of the foundation (use these; do not fork them)
- **The rule object.** `Game.host` (`HostRules`) is created by the STAGE key `host`, null everywhere else. Parts:
  `judgment`, `light` (with `light.clouds`), `grace`, `trumpet`, plus the `choir` list.
  - `HostRules.enabled` is true only on a Host stage (a Host kind forced elsewhere makes the rules with the scales and the
    Light off). Stage-only things check the stage, not just `game.host != null`.
  - `HostRules.danger_push(p)` is what the army bot reads (the Verdict's pillars, the shafts). Add your hazards there,
    additively; a kit's own telegraph goes in its `danger_push(e, p)` (the Power's lunge is the model).
  - `HostRules.play_sound(event, pos, gap)`; events in `HostRulesData.SOUNDS` (your own block at its end).
  - Each stage director goes in `scripts/enemies/host/<id>_director.gd`, switched on by its own STAGE key and created and
    stepped from `EnemyDirector` like `TwoTruthsDirector`.
- **Judgment** (`game.host.judgment`). The sins are built (`HordeDirector.raise_corpse()` and the replacement timer call
  `HostRules.on_raise()` / `on_replace()`); never add a second write.
  - `add(amount)` is THE one write (Seraiel's Trial: "he fills the scales by a third with each phase he survives" is
    `add(capacity / 3)`), `fill()` the full scales (the Last Trumpet), `share()`, `thirds_passed`, `verdict_running()`.
  - The Voice's **Last Word** ("every raise of the run returns as a Judge, in waves") reads `judgment.raised` and calls
    `send_judges()` (or one wave method of yours on `Judgment`) per wave.
  - STAGE `judgment` overrides any `JUDGMENT` key (`capacity`, `thirds`, `judge_lighten`, the Verdict's numbers).
  - **Without Sin** (Silver Stair achievement): "the scales never passed the first third" is `judgment.thirds_passed == 0`
    for the whole run (record the max in your stage's director; the counter resets with the Verdict).
- **Hallowed Light** (`game.host.light`).
  - `add_shaft(origin, normal, width, travel)` is the one call for a new shaft (the Throne's Gaze as beams from the rim:
    shafts that start on the rim and sweep toward the necromancer; the Voice's Holy: more, wider shafts); `width_mult`
    (the Empyrean's Choir: "every Choir Angel alive adds to the light's width" reads `game.host.choir.size()`; the Last
    Trumpet multiplies it too), `every_mult`, `max_live`, `shaded(p, r)`.
  - `light.clouds.add_shade(at, radius, life)` lays a shadow (the Silver Stair's low cloud banks per step; a summon "behind
    a barrier or in shadow" for Be Not Afraid reads `shaded()` and `barrier_hp`). STAGE `clouds` (`"chance": 0.0` = no
    fixed banks) and `light` override any key.
  - Obstacles already cast a pillar's shadow (`pillar_pad`); a moving wall (the Wheel's crystal rings) shades only if it is
    an arena obstacle or you add `add_shade()` for it.
- **Grace** (`game.host.grace`). `absorbs(e, source)` is THE one read, from `CombatResolver.damage_enemy()`; never add a
  second. Row key `halo: true` gives a kind its halo, `regrows: true` makes it a regrower (the Dominion of the Spheres:
  "keeps halos returning across the whole zone" = a regrower with a zone-wide aura radius, or one method of yours on
  `Grace`, e.g. `set_zone_regrow()`). `HostKit.seen` / `last_absorb` are Grace's: never write them elsewhere.
  - **The Wheel Breaks** ("beat the Throne by its core alone"): count the boss's damage by window (core open or not) in
    your boss script; Grace does not apply to a boss without a `HostKit`.
- **The Last Trumpet** is the shared Reckoning; tune it only through your RECKONING's `last_trumpet` keys and its
  `companions`.
- **Counter-passive hooks are built and read** (exactly 1 today). Build only the PassiveData rows, offered in this act only
  through the card row's `act` (use `13`; the reorder renumbers):
  - **Absolution** (`HostRulesData.ABSOLUTION`, key `fill_cut`, proposal 0.3): `HostRules.absolution_mult()`, read by
    `Judgment.on_raise()` / `on_replace()`.
  - **Smoked Glass** (`SMOKED_GLASS`, key `burn_cut`, proposal 0.5): `HostRules.smoked_glass_mult()`, read by
    `HallowedLight._burn()` (summons only).
- **Kits and rows.** Extend `HostKit` (the halo, the registration, the halo drawing); call `super.reset()` /
  `super.on_deactivate()` / `super.draw_over()`. Row keys: `group` (lights, soldiers, choir, orders; add `guardians` for the
  Cherub and the Ophan to `HostRulesData.GROUPS`, `CodexData` and `CodexData.SECTIONS["host"]`), `halo`, `regrows`, `judge`,
  `lunge`, `blast`. Kit ids must be unique across all kit folders. Bosses in `scripts/enemies/host/boss_<id>.gd`
  (`EnemyDirector.HOST_BOSS_DIR`); remove your stub's `"script": "vael"`. Minibosses through `EnemyDirector.set_miniboss()`.
  New shared kinds: rows in your own block at the end of `HostEnemyData`; stage-only things in your stage's table.
- **Art keys.** Sprites load from `assets/sprites/host/<kind_id>.png` (`docs/host/ART_MANIFEST.md`); `tiles/host_cloud_shadow`
  replaces the code cloud shadows; the halo is code-drawn (`markers/host_halo` may replace it).
- **Report.** A per-stage file beside `host_report.gd` (`silver_stair_report.gd` ...), called from the marker in
  `HostReport.print_lines()`, one line in your own block. **Codex:** your kinds in the `CodexData.HOST_*` group lists.
- **Unlocks, spells, characters, classes, achievements** as in the Dynasty (`UnlockData` / `Unlocks`, the one
  `NecroSpellBook` dispatch, `character_data.gd` with Hyper / Untouchable / Deathlord skins, one `SummonBehavior` per class,
  its Ossuary mastery). Ids must not collide with kinds, structures, source tags, sound or rule names (check
  `host_enemy_data.gd`, `HostRulesData`, the sound packs; `judgment`, `grace`, `hallowed_light`, `host_verdict`, `power_lunge`,
  `virtue`, `power`, `herald`, `dominion`, `judge` are taken).

## The new kinds, split across the stages
The foundation built `lesser_light`, `virtue`, `power`, `choir_angel`, `herald`, `dominion` and `judge`. The rest, one
stage each:
- **The Silver Stair:** the **Cherub** (group `guardians`; four faces, eyes on its wings, a flaming sword that sweeps all
  around it; "Siegecraft; stay out of reach") as a shared row in `HostEnemyData`; the miniboss **Cherub of the Gate** (its
  sword turns a full circle every 6 s) in `SilverStairEnemyData`.
- **The Wheel of Thrones:** the **Ophan** (group `guardians`; a burning wheel that rolls straight through the ring, then
  turns; "Bone Wall; Grave Step") as a shared row; the miniboss **Dominion of the Spheres** in `WheelOfThronesEnemyData`.
- **The Empyrean:** the miniboss **Herald of the Seventh Trumpet** (its trumpets call the squads of all the earlier zones)
  in `EmpyreanEnemyData`; the Voice's waves of Judges reuse `judge`.

## Balance (the foundation's flags; seed 7)
- **The stubs are easy for the army bot** (the Silver Stair: VICTORY, lowest HP before 0:00 91/120, the placeholder boss
  slain) and hard for the naive bot (the Empyrean `--mortal`: died at 18:51 in the placeholder boss fight, lowest HP 16).
  The stage content is where the difficulty comes from; tune for slot X with your stage's data first.
- **Hallowed Light is the stubs' largest source of summon damage** (the Silver Stair army run: 968 burns, 23,657 damage;
  4,345 burns blocked by barriers, the army bot's Warders cover most of the ring). Watch it with builds without Warders.
- **Grace is heavy**: ~13,500 hits shrugged off in the Silver Stair army run (10 kinds; about five a halo). That is the
  rule as written; if the angels feel too tanky, lower the stage HP multipliers (the stubs sit at 1.7 / 1.75 / 1.8, a
  little under the Inferno's 1.75 because of it) rather than changing the rule.
- **Judgment** reached one Verdict from sins in the army run (at 19:11; 133 summons replaced, 2 Judges sent and slain). The
  army bot never raises corpses; a Lich / Death Mark / Linen Bind build fills it much faster (each raise 0.5).
- **Dominions regrow a lot of halos against DoTs** (the naive Empyrean run: 3,810 regrown, 4,363 plague ticks shrugged off).
- One Godot process at a time (`pgrep -c Godot` first). Each agent balances its own stage so the army bot ends healthy on
  seed 7 (`--policy=army --mortal`); the Silver Stair agent also checks seeds 1 and 2.

## Process
- Do not push; commit in steps; keep `"playable": false`. Commit messages end with the lead's co-author lines.
- Touching a shared path outside the Host folder (`combat_resolver.gd`, `summoned_unit.gd`, `horde_director.gd`,
  `enemy.gd`): also run the Graveyard default and the Hall of Two Truths army runs of `docs/host/tools/gate.sh` against your
  base, one at a time; their `[autotest]` / `[metric]` lines must be identical.

---

## Agent A: the Silver Stair (`silver_stair`, final stage 28)
- **Stage:** a stair of light rising from hell's ashes into the clouds. Zones: the Ashen Foot, the Stair, the Cloud Shelf,
  the Gate of Pearl. Four zone floors over the `stair` style, obstacles in both orientations.
- **Stage mechanic: the Stair:** each zone is a wider step; low cloud banks are the shadows that hide from the light
  (`clouds.add_shade()` per step, or STAGE `clouds` per zone).
- **Miniboss: the Cherub of the Gate** (its flaming sword turns in a full circle every 6 s).
- **Boss: Seraiel, Warden of the Gate** (`boss_seraiel.gd`, male, a four-winged archangel):
  - **the Gate:** walls of light split the arena into lanes that close one by one;
  - **the Sword:** sweeps of a flaming sword across the ring;
  - **the Trial:** he fills the scales by a third with each phase he survives (`judgment.add()`).
- **Spell: Flaming Sword** (a spectral sword sweeps a wide arc in front of the necromancer) → **Sword at the Gate** +
  **Fallen Light**. **Character: the Fallen Herald** (male).
- **Achievement: Without Sin** (clear the Silver Stair without the scales passing the first third); it unlocks a
  counter-passive (the lead says which: Absolution or Smoked Glass).

## Agent B: the Wheel of Thrones (`wheel_of_thrones`, final stage 29)
- **Stage:** the turning spheres of heaven: rings of crystal that orbit through the arena. Zones: the Sphere of the Moon,
  the Sphere of the Sun, the Sphere of the Stars, the Wheel. Floors over the `wheel` style.
- **Stage mechanic: turning spheres:** crystal rings sweep slowly across the map as moving walls; the ring must flow
  through their gaps (moving walls go through the arena's push-out like every obstacle; record how).
- **Miniboss: the Dominion of the Spheres** (keeps halos returning across the whole zone until he falls).
- **Boss: the Throne** (`boss_throne.gd`, a colossal wheel within a wheel, rims covered in eyes):
  - **the Rolling:** it crosses the arena in straight lines and rebounds;
  - **the Gaze:** every eye opens: beams from the rim toward the necromancer that only shadows stop (`add_shaft()` /
    `shaded()`);
  - **the Core:** the wheels open and a burning eye at the centre can be hurt for 10 s at a time.
- **Spell: Wheel of Eyes** (a burning wheel rolls out in a line and rebounds off walls) → **Ophanim** + **All-Seeing**.
  **Character: the Blind Saint** (female, figure style).
- **Achievement: The Wheel Breaks** (beat the Throne by its core alone).

## Agent C: the Empyrean (`empyrean`, final stage 30, the end of Part One)
- **Stage:** the highest heaven: a white rose of light, endless and silent. Zones: the Rose's Edge, the Petals, the Choir,
  the Heart of the Rose. Floors over the `rose` style.
- **Stage mechanic: the Choir:** the hymn of the whole Host can be heard; every Choir Angel alive adds to the light's width
  (`light.width_mult` from `game.host.choir.size()`, one read).
- **Miniboss: the Herald of the Seventh Trumpet** (its trumpets call the squads of all the earlier zones).
- **Boss: the Voice** (`boss_voice.gd`, a six-winged seraph of light; it never moves):
  - **the Holy:** the light at its strongest;
  - **Be Not Afraid:** it lowers the wings from its face: the screen whitens (a flat additive rect) and every summon in
    the open stops for 2 s (`CombatResolver.stun_unit()`); summons behind a barrier or in shadow are spared;
  - **the Last Word:** the scales read the run's sins back: every raise of the run returns as a Judge, in waves, until the
    Voice falls (cap the waves; `judgment.raised`).
  When the Voice falls, a short ending text only ("heaven, earth and hell answer to the necromancer"); no epilogue part.
- **Spell: Revelation** (a flash that stuns every enemy on screen for 1 s and weakens them through
  `CombatResolver.weaken_enemy()`) → **Be Not Afraid** + **Seventh Seal**. **Character: the Unveiled** (female, figure
  style). **Summon class: the Bound Ophan** (finale reward: a wheel of bone and eyes that orbits the Bone Ring and rolls
  through packs; evolution Throne of Bones; a class special that works everywhere; its Ossuary mastery).
- **Achievement: The Last Word** (beat the Voice). It only records the clear until the reorder pass writes the Part One
  epilogue part.

## Owner answers (Nov 9, 2026; GDD §15.0 "Wave 2 owner answers")
- Grace stays as built; angel HP is tuned to compensate.
- Lesser lights have no halo.
- **Without Sin unlocks Absolution**; the Host's other achievement unlocks Smoked Glass.
