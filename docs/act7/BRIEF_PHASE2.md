# Act VII phase 2: brief for the three stage agents

The lead wrote this brief when the foundation merged (Nov 2, 2026).

Three agents run at once, one per stage, each in its own worktree on its own branch, made from the lead's branch that
holds the merged foundation. The lead has the branches merged and runs one big test pass afterwards.

This is the Act VI plan: `docs/act6/BRIEF_PHASE2.md` (and through it `docs/act5/BRIEF_PHASE2.md`). Read it; its "Shared
files, testing and process" section applies here unchanged, with Act VII names, `# --- Act VII: <your stage> ---`
blocks and the scratch dir `.../scratchpad/act7/<id>/`. Read this brief in full, then your stage's section.

## Read first
1. **`CLAUDE.md`.** Every convention applies, in particular:
   - no shader may read the screen, and prefer textures over polygons redrawn every frame;
   - never call `AudioServer.add_bus()`;
   - **summons never get act-only rules**: carry-offs, drags, stuns and feeding are enemy effects on units, through the
     existing one paths (`CombatResolver.stun_unit()`, the held / misdirect hooks, Bloodfeast);
   - co-op reads the necromancer through the bound slot.
2. **`docs/act7/PROPOSAL.md`.** The owner's answers are at the top; your stage's section and its rewards are the spec.
   - **No epilogue part, no closing card and no epilogue hook.** Last Supper only records the clear.
   - Every prompt names the figure's sex. Female kinds and characters are in the figure-redesign style; Carmilla is the
     style at its limit, as in Act VI (chest and hips always covered, no nudity).
3. **`docs/GDD.md` §15.0:** the Act VII rows from "Act VII foundation (phase 1)" on (Bloodfeast, Night Wings, the Blood
   Moon, the Endless Feast, the shared kinds' art, "Waltz of the Red Moon"), and the Act VI phase 2 rows for how a stage
   was built last time.
4. **`README.md`**, your stub `scripts/data/stages/<id>_stage.gd`, the Court folder `scripts/enemies/court/`,
   `court_enemy_data.gd`, `court_rules_data.gd`, your stage's empty table, and the Act VI stage closest to yours.
5. **Art.** ART_BIBLE "Act VII: the Sanguine Court, the shared kinds" and the approved concept art
   `art_source/concepts/act7_lineup.png`, `act7_boss.png`, `act7_stage.png` (the owner approved all three; match them).
   - Known weak spots in the foundation's sprites (do not fix them here; the art review will): tan skin, a dark Blood
     Knight, purple werewolf fur. Don't copy them into your new sprites: vampires are pale, fur is grey-brown.
   - Female figures get a `bust` rig, the hip `swish` and an idle strip. Fliers glide or hover.
   - Convert with `prepare_sprite.py` on the source and the `court/` ramps (COURT_BLOOD / VELVET / MOON).

## Extension points of the foundation (use these; do not fork them)
- **The rule object.** `Game.court` (`CourtRules`), created by the STAGE key `court`. It is null on Acts I–VI.
  `game.court.feed_mult()` is the one feeding multiplier (moon, Reckoning).
- **Bloodfeast:** called once from `CombatResolver.damage_unit()` / `damage_player()` (the `by: Enemy` argument). A
  boss or kind sets its share with the row key `feeds` (read by `Bloodfeast.share_of(e)`); healing past full banks as
  `Enemy.blood_shield` (`absorb()`). **Every new Court heal goes through this path or the existing enemy-heal path in
  `CombatResolver`**: fountains, pools, hex circles and the Elder's feeding included.
- **Night Wings:** the row flag `flies` (`Enemy.flies`), read by the existing body-block code. Fliers must land to bite.
- **The Blood Moon:** `game.court.moon.is_up()`, `time_to_rise()`, `force(duration)` (a boss calls its own moon this
  way), `start_endless()` (the Reckoning only). Werewolves turn and covens cast while it is up.
- **Coffins:** `CourtCoffinKit.open_coffin(e)` (sprites `structures/court_coffin` and `_open`).
- **Counter-passive hooks, already built:** Embalmed (`Bloodfeast.embalmed_mult()`, PassiveData `embalmed` / key
  `feed_reduction`) and Silver Bones (`CourtRules.silver_bones_mult()` / `silver_mist_mult()`, PassiveData
  `silver_bones` / keys `silver_damage`, `mist_reduction`). Build the PassiveData rows on these hooks, Act VII only.
- **Kits.** Extend `CourtKit`. Bosses go in `scripts/enemies/court/boss_<id>.gd`; remove your stub's placeholder
  `script` key. Minibosses register through `EnemyDirector.set_miniboss()`.
- **The Reckoning:** the Endless Feast is shared. Tune it only through your stage's `RECKONING` keys.
- **Sounds:** `CourtRules.play_sound(event, pos)` with events in `CourtRulesData.SOUNDS`. New sounds go in your own
  block at the END of `SoundData.COURT_SOUNDS`; pack seeds depend on order, so never insert in the middle.
- **Report:** a stage block in `CourtReport.print_lines()`. **Codex:** the `CodexData.COURT_*` lists.
- **Unlocks, spells, characters, classes, counter-passives, achievements:** as Act VI (`UnlockData` / `Unlocks`, the one
  `NecroSpellBook` dispatch, `character_data.gd` with a Hyper skin and the Untouchable and Deathlord skins, one
  `SummonBehavior` per class that works the same on every stage, PassiveData rows offered only in Act VII through the
  card row's `act`, each new class's Ossuary mastery in `mastery_data.gd` and the price total in
  `tools/ossuary_check.gd`). **Ids must not collide with enemy kinds** (e.g. `blood_spawn` for the class is fine; check
  `court_enemy_data.gd`).

## The new kinds, split across the stages
The foundation built Thrall (`blood_thrall`), Vampire Bat, Blood Knight, Werewolf and Vampire Noble. The other four of
the proposal's roster are built by one stage each, as rows in `CourtEnemyData` (your own block at the end) with a
`CourtKit`, any stage may then use them:
- **Ghoul** → Ravensmoor. **Crimson Witch** (female, figure style) and **Bloated Thrall** → the Witchwood.
  **Chiropteran** → Castle Sanguis.

---

## Agent A: Ravensmoor (`ravensmoor`, Stage 19)
Branch `act7-ravensmoor`, worktree `/home/user/wt/act7-ravensmoor`.

- **Stage:** a cursed village on the moors below the castle. Zones: the Moor, the Village, the Old Church, the Wolfwood.
  Four zone floors as tiles, obstacles in both orientations.
  - **Sleeping coffins** in each zone: break one before the next Blood Moon for a Soul Ash bounty; one left whole opens
    when the moon rises and a Vampire Noble climbs out (`open_coffin`).
  - Foundation note: the stub dropped the army bot to 28 HP because the bats now dive at their target. Balance the
    stage so the army bot ends healthy (the lead's playtest passes tune it further).
- **Miniboss: Old Greymane**, the pack's alpha. His howl turns the werewolves near him into beasts early.
- **Boss: Vargr, the Moon-Eater** (`boss_vargr.gd`), three phases, each calling his own moon (`moon.force`):
  - **the Hunt:** circles the ring and lunges at the weakest summon;
  - **the Turning:** his pack transforms around him and he leaps over the ring at the necromancer;
  - **the Moon-Eater:** the arena goes dark except a red circle around him (a texture, no screen-reading shader), and
    every hit he lands feeds him.
- **Kind: the Ghoul.** Packs of 4 that stop to eat corpses (fewer raises: one documented check in the corpse path) and
  heal doing it (the enemy-heal path).
- **Spell: Moonfang**, unlocked by Vargr: spectral wolf jaws snap at the nearest group and leave bleeds. Evolves into
  **Wolf of the Red Moon** with the paired passive **Pack Blood**.
- **Character: the Moon-Cursed Huntress** (female, figure style), a werewolf hunter who turned.
- **Achievement: Coffin Nails** (break every coffin on Ravensmoor before it opens). It unlocks the counter-passive
  **Silver Bones**.

## Agent B: the Witchwood (`witchwood`, Stage 20)
Branch `act7-witchwood`, worktree `/home/user/wt/act7-witchwood`.

- **Stage:** a black fen and a wood of hanging charms. Zones: the Fen (water slows everyone, through `TerrainSlow`, the
  one ground-slow path), the Hanging Wood, the Standing Stones, the Cauldron.
  - **Hex stones:** standing stones that power the covens' circles; destroy one and its zone's covens cannot cast.
- **Miniboss: the Bog Mother** (female), a vast drowned witch who drags summons into the fen (one documented pull path,
  as the Gatekeeper's chains did).
- **Boss: Isolde Vane, the Witch of the Red Moon** (`boss_isolde.gd`, female, figure style):
  - phase 1: hex circles on the ring and cauldron bombs that leave healing pools for her thralls;
  - phase 2: she splits into three sisters; all three must fall within 10 s of each other or the fallen rise again;
  - phase 3: she calls the Blood Moon and keeps it up until she falls (`moon.force`).
- **Kinds:**
  - **Crimson Witch** (support, female, figure style): covens of three cast a hex circle while the moon is up (and
    when a stone powers them) that heals the Court inside and drains the army. Kill one and the circle fails.
  - **Bloated Thrall** (heavy): bursts into a pool that heals Court units walking through it.
- **Spell: Hex Circle**, unlocked by Isolde (id other than any enemy kind or circle id): a crimson circle under the
  necromancer drains every enemy inside. Evolves into **Witches' Sabbath** with the paired passive **Moonlit Rite**.
- **Character: the Hedge Witch** (female, figure style).
- **Achievement: The Coven Breaks** (kill Isolde's three sisters within 1 s). It unlocks the counter-passive
  **Embalmed**.

## Agent C: Castle Sanguis (`castle_sanguis`, Stage 21, the act's finale)
Branch `act7-castle-sanguis`, worktree `/home/user/wt/act7-castle-sanguis`.

- **Stage:** the Court's castle above the clouds. Zones: the Courtyard, the Banquet Hall, the Crypt Gallery, the Throne
  of Blood.
  - **The Banquet:** blood fountains heal any Court enemy standing in them; a Bone Wall segment or a Golem parked on a
    fountain denies it (one documented check).
- **Miniboss: the Chiropteran King**, a giant bat-man who carries summons off over the ring and drops them outside it
  (an enemy effect on units, through the held hook).
- **Boss: Queen Carmilla and the Elder** (`boss_carmilla.gd`; Carmilla female, the style at its limit):
  - **the Court:** she dances through the ring in mist form, her blood-drain beam sweeps the army, her nobles feed
    around her;
  - **the Waking:** she kneels at the Elder's coffin and feeds him; every heal she lands fills his health bar.
    Stuns, Soul Chains and killing the thralls that bring her blood interrupt her;
  - **the Elder:** the first vampire, a bat-winged horror with as much HP as she gave him; he commands every bat on the
    map and feeds on everything he touches.
  - Beaten, the Elder turns to ash and the Court's veil tears: a short ending text only, no epilogue.
- **Kind: the Chiropteran** (elite, flies): glides over the ring; a sonic shriek cone stuns summons for 1.5 s
  (`stun_unit()`).
- **Spell: Night Swarm**, unlocked by Carmilla: spectral bats circle the necromancer and dart at enemies. Evolves into
  **Nocturne** with the paired passive **Old Blood**.
- **Character: the Dhampir** (half-vampire; choose the sex and record it).
- **Summon class: Blood Spawn** (`blood_spawn`, the finale's reward): fast vampire brawlers that heal themselves on every
  hit (a class special, the same on every stage, through the existing unit-heal path). Its evolution is **Nosferatu**;
  name the paired passive and record it. Give it its Ossuary mastery.
- **Achievement: Last Supper** (beat the Elder). No epilogue: it only records the clear (a title, as Act VI did).
