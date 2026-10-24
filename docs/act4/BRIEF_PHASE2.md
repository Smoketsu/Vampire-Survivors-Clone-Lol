# Act IV phase 2: brief for the three stage agents

Lead's brief, written when the foundation merged (Oct 24, 2026). Read it in full, then the section for YOUR stage.
Three agents run at once, one per stage, each in its own git worktree on its own branch made from the lead's branch
that holds the merged phase 1 foundation. The lead merges the three branches afterwards, runs the gates and the
balance pass. This mirrors `docs/act3/BRIEF_PHASE2.md` (read it too: its "Art rules", "Testing" and "Process"
sections apply here unchanged, except the paths named below).

## Read first
1. `CLAUDE.md`: every convention (document every variable and constant with units; tunables only in
   `scripts/data/*.gd`; static typing; determinism; one path per modifier; pooling with `generation` checks; no
   physics; autotest friendly; the UI rules; **no shader may read the screen**; **never `AudioServer.add_bus()`**;
   **summons never get act-only rules**; co-op: read the necromancer through the bound slot).
2. `docs/act4/PROPOSAL.md`: the owner-answered design. Your stage's section and your rewards are the spec.
3. `docs/GDD.md` §15.0: the rows "Act IV proposal (owner answers)", "Act IV foundation (phase 1)", "Wrath of the
   Gods (Act IV)", "Phalanx (Act IV)", "Glory (Act IV)", "Act IV art: the shared kinds", "Hymn of Bronze and the
   Pantheon sounds", "Closing cards, one per act", "Act IV foundation review fixes"; and the Act III phase 2 rows
   ("The Scrap Wastes (Act III phase 2)" through "Act III goes live") for how a stage was built last time.
4. `README.md`, your stub `scripts/data/stages/<id>_stage.gd`, the Pantheon folder `scripts/enemies/pantheon/`
   (`pantheon_rules.gd`, `divine_wrath.gd`, `phalanx.gd`, `glory.gd`, `pantheon_kit.gd` and the four kits),
   `pantheon_enemy_data.gd`, `pantheon_rules_data.gd`, your stage's empty table, and the Act III stage closest to yours.
5. Art: `docs/art/ART_BIBLE.md` section "Act IV: the Olympian Republic, the shared kinds" (the style and the pipeline
   that worked: `pixelate_source.py` muddied the bronze, so `prepare_sprite.py` straight on the source with
   `--ink-l 0.15` and explicit `--ramps`, `--no-levels` for gold-heavy figures), the concept art
   `art_source/concepts/act4_*.png`. Owner's open question: the soldiers' sex. Until the owner picks, follow the mixed
   second lineup (male hoplites, legionaries and heroes; the Amazon, the Gorgon, Atalanta and Artemis in the
   figure-redesign style). Name each figure's sex in every prompt.

## Extension points of the foundation (use these, do not fork them)
- **The rule object:** `Game.pantheon` (`PantheonRules`; created by the STAGE key `pantheon`, or on demand by
  `Game.pantheon_rules()` when a Pantheon kind is forced elsewhere). Null on Acts I–III.
- **Kinds:** add rows to YOUR stage's table (`IlionEnemyData` / `OlympusEnemyData` / `UnderworldEnemyData`, looked
  up by `EnemyDirector.pantheon_def()`); row keys `bronze`, `phalanx`, `hero`, `fodder`, `names`, `rises`, `kit`.
  Kits: `scripts/enemies/pantheon/<id>_kit.gd` extending `PantheonKit` (fields `facing`, `locked`, `wall`,
  `broken_until`, `free_speed`; helpers `turn_to()`, `front_point()`, `rules()`, `is_bronze()`, `is_phalanx()`,
  `is_hero()`, `is_fodder()`). Kit ids unique across the Eye, Empire and Pantheon folders.
- **Direction:** `PantheonRules.hit_from_front(e, origin, half_angle=-1)` and `PantheonRules.facing_of(e)` are the
  only facing test. Hits carry their origin: `CombatResolver.damage_enemy(e, amount, source, as_slot=-1,
  origin=CombatResolver.NO_ORIGIN, shot=false)`; a new damage source that should respect fronts passes them. A boss
  with a directional rule (Achilles' heel, a testudo) exposes `pantheon_facing` and
  `directed_hit_mult(origin, shot, source)`; `PantheonRules.directed_hit_mult()` dispatches to it (one path in
  `damage_enemy()`).
- **Wrath of the Gods:** `DivineWrath` (fields `cfg`, `next_at`, `stage_kind`, `twilight`, `twilight_on`;
  `interval()`, `swallows()`, `grounded_mult()`; sources `SRC_WAVE`, `SRC_BOLT`, `SRC_CHAIN`, `SRC_FISSURE`). Tune a
  stage's wrath only through its STAGE `wrath` keys (`{}` = `PantheonRulesData.WRATH` defaults). A boss that floods or
  calls bolts / fissures (Poseidon, Zeus, Hades) adds a public "strike now" entry on `DivineWrath` (e.g.
  `strike(kind, at, overrides)`) rather than copying the hazard code; Olympus owns that change, the others use it after
  the merge (until then, call the private `_strike` through one wrapper in your boss, marked for the lead).
- **Phalanx:** `Phalanx.directed_hit_mult()`, `breaker_mult()`, `locked_count()`. The Legionary's testudo (Ilion)
  extends the front to "from above" (arcing / volley hits) through the same helper.
- **Glory:** `Glory.on_summon_killed(u, by)`, `on_enemy_killed(e)`; hero names through
  `PantheonRules.next_hero_name()`. Any enemy blow that should feed Glory passes `by = self` to
  `CombatResolver.damage_unit()`.
- **Corpses:** `Enemy.leaves_corpse()` (fissures swallow through `PantheonRules.swallows_corpse()`) and
  `HordeDirector.raise_corpse()` stay the only gates.
- **Sounds:** `PantheonRules.play_sound(event, pos)` with events in `PantheonRulesData.SOUNDS`; new sounds go in your
  own block of `SoundData.PANTHEON_SOUNDS` (they load lazily with the `bronze` music; Sfx renders a pack asked for
  while another renders).
- **Counter-passive hooks (exist, read 0 now):** Grounded Bones = PassiveData row `grounded_bones`, key
  `wrath_reduction`, read only by `DivineWrath.grounded_mult()`; Bronze Breaker = row `bronze_breaker`, key
  `front_damage`, read only by `Phalanx.breaker_mult()`. Both offered only in Act IV through the card row's `act`.
  **Known gap (Olympus fixes it):** `grounded_mult()` reads the bound (primary) slot's passives and applies to both
  players and armies; make it per target slot when the passive is built.
- **Bosses:** `scripts/enemies/pantheon/boss_<id>.gd` (extends `Boss`); remove your stub's placeholder `script` key
  (`EnemyDirector.PANTHEON_BOSS_DIR`). Minibosses register through `EnemyDirector.set_miniboss()`; `ChestManager`
  drops the chest.
- **Reckoning:** the Twilight of the Gods is shared (`bronze_titan` + `TWILIGHT`); tune it only through your stage's
  `RECKONING` keys.
- **Report:** add your stage's line to `PantheonReport` (your own block); keep its five foundation lines unchanged.
- **Unlocks, spells, characters, classes:** as Act III (`UnlockData` / `Unlocks`, `NecroSpellBook`'s one dispatch,
  `character_data.gd`, `game.character.innate_value()`, one `SummonBehavior` per class that works the same on every
  stage).

## Shared files
Keep edits small, additive and in a block headed `# --- Act IV: <your stage> ---` at the END of the table or list
it extends. Never reorder or reformat existing lines. Do not tune data another stage owns, and do not touch Act I–III
stages' data.

## Testing and gate
As `docs/act3/BRIEF_PHASE2.md` "Testing", but the gate script is `docs/act4/tools/gate.sh <worktree> <outdir>`
(seed 7: Graveyard default and army, Gullhaven, Ul-Thalos and the Iron Citadel army), compared with
`docs/act3/tools/same_seed_gate.py` against the lead's base summaries. Allowed diffs: catalog counts only. **CPU: at
most ONE Godot process at a time.** Keep your stage `"playable": false`. Difficulty target for your own sanity runs:
a step harder than the Iron Citadel; `--policy=army` usually reaches 0:00 and kills your boss.

---

## Agent A: the Shores of Ilion (`ilion`, Stage 10)
- **Stage:** zones the Beachhead, the Siege Camp, the Scaean Gate, the Walls (four zone floors as tiles, obstacles in
  both orientations: beached warships, siege camp tents and palisades, the walls of Troy). Wrath: Poseidon's waves.
  **Siege towers** (structures rolling toward the walls; destroying one spills its soldiers and pays a Soul Ash
  bounty). Miniboss **Polyphemus the Cyclops** (boulders with landing circles, flat armour).
- **Boss: Achilles, the Unkillable** (`boss_achilles.gd`): hits to his front deal 10%, hits from behind or to the
  gold heel mark under him deal full damage and stagger him (through `directed_hit_mult`); phases the duel, the
  Myrmidon charge (his guard), the rage after Patroclus (fast, wild).
- **Kinds:** Legionary (soldier: scutum and gladius, the testudo against arrows and volleys from above), Wolf of Rome
  (fodder pack of 5, bronze, fast lunges), Cyclops (heavy; the miniboss's lesser kin).
- **Spell:** Paris's Arrow (unlocked by Achilles; a spectral arrow that always strikes its target from behind: full
  damage through phalanx fronts) → **Arrow of Fate** + paired passive **Mortal Heel**.
- **Character:** the **Doomed Prophetess** (a dead seer of Troy, figure-redesign style), Hyper skin, Untouchable and
  Deathlord skins.
- **Achievement** Heel Found (kill Achilles from behind only) → counter-passive **Bronze Breaker** (build the
  PassiveData row on the existing hook; Act IV only).

## Agent B: Mount Olympus, the Pantheon Trial (`olympus`, Stage 11)
- **Stage:** zones the Field of Ares, the Groves of Artemis, the Terraces of Poseidon, the Summit (the foundation's
  names; keep or rename and record it). Wrath: Zeus's lightning (bronze draws it). Build the public
  `DivineWrath.strike()` entry (above) for the gods.
- **The trial:** Ares at 14:00 left (war-cry buffing every enemy on screen through the one enemy-buff path, a spear
  charge, dies to blockers), **Artemis** at 9:30 (figure-redesign style; moonlit arrow volleys, hunting hounds,
  teleports between groves), Poseidon at 6:00 (floods half the arena with the wave hazard, trident throws, a sea
  serpent). Each about a third of a stage boss's HP, each leaves a chest; the HUD's one miniboss bar shows the god in
  play. **Zeus** (`boss_zeus.gd`) on the usual schedule: lightning storms, the thunderbolt beam, phase 3 his colossal
  form.
- **Kinds:** Centaur Archer (ranged; fires while galloping toward you, never kites), Amazon (elite, female,
  figure-redesign style; leaps over the ring's first row), Gorgon (elite, female, figure-redesign style; a petrifying
  gaze cone: summons in it turn to stone 3 s through the one stun path for summons).
- **Spell:** Stolen Thunder (unlocked by Zeus; a charged bolt on the strongest enemy chaining to armoured foes) →
  **Gigantomachy** + **Titan's Blood**.
- **Character:** the **Oathbreaker** (a fallen demigod, male), Hyper skin, Untouchable and Deathlord skins.
- **Achievement** Twilight of the Gods (clear the Pantheon Trial) → counter-passive **Grounded Bones** (build the row
  on the existing hook, made per target slot; Act IV only).

## Agent C: the Asphodel Underworld (`underworld`, Stage 12, the finale)
- **Stage:** zones the Asphodel Fields, the Styx Crossing, the Judges' Hall, the Throne of Hades. Wrath: Hades'
  fissures. **The Styx**: a river band through `TerrainSlow` that slows the living and suppresses a summon wading it
  for 2 s through `HordeDirector.add_suppression()` (an effect of the ground on everyone in it, not a summon rule).
  Miniboss **Cerberus** (three heads, three attacks, each head killed on its own).
- **Boss: Hades, Lord of the Dead** (`boss_hades.gd`), the first rival necromancer: the Helm of Darkness (invisible
  but for footprints; fissures under the ring), the Reclaiming (marks summons and turns them into his shades for
  10 s: **reuse the Claims path** `HordeDirector.claim_fallen()` / `EyeClaims`; `game.claims` is null outside Act II,
  so create it for this boss through one documented switch rather than a copy, and keep Act II unchanged; he also
  raises the Olympus gods as shades for one attack each), Lord of the Dead (his own ring of the dead, army against
  army, until it breaks). Beaten, he kneels and gives up his crown (ending text like Vhal'Neth's and Deus Ex
  Machina's).
- **Spell:** River Styx (unlocked by Hades; a black river line that drains and slows whatever crosses it) →
  **Lethe's Flood** + **Ferryman's Toll**.
- **Character:** the **Ferrywoman** (Charon's daughter, figure-redesign style), Hyper skin, Untouchable and
  Deathlord skins.
- **Summon class:** the **Myrmidon Shades** (the finale's reward: undead hoplites fighting as a three-shield wall on
  the ring; one `SummonBehavior`, the same on every stage) → evolution **Legion of Tartarus** + its paired passive
  (name it; record it).
- **Achievement** Empty Throne (beat Hades) → opens the Act IV epilogue part **"The Gods Are Silent"** (leave a
  documented hook in `epilogue_data.gd` like `ACT3_PART`, panels made at integration) and the next closing card
  **"The Sun Still Rises"** (a row in `EpilogueData.CLOSINGS` with `after` = the Act IV part; its text is in the
  proposal; its panel at integration).
