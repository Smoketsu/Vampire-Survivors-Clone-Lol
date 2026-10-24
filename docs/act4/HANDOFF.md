# Act IV handoff (lead session, Oct 24, 2026)

Read this first, then `CLAUDE.md` (the project rules; they win any conflict), `docs/act4/PROPOSAL.md` (the
owner-answered design) and `docs/act4/BRIEF_PHASE2.md` (the brief for the three stage agents). GDD §15.0 rows from
"Act IV proposal (owner answers)" to the end of the table record every Act IV decision.

## Where things stand

- **Branch `claude/charming-lamport-upfhlz`** (pushed) holds the whole Act IV foundation on top of `main` (`3cbe21f`):
  - the Acts IV–VI concept art (merged from `act3-epilogue`, the only unmerged work there);
  - the proposal copy and the foundation briefs (`docs/act4/`);
  - three merged agent branches (local only, lost with the container; everything is in the merges):
    - `act4-art`: the `bronze` / `marble` / `aegean` ramps (`tools/palette.json`), `assets/sprites/pantheon/`
      (`shade_of_dead`, `hoplite`, `hero`, `bronze_titan`, stills and walk / hover strips, about $0.12), the rigs in
      `walk_cycle.py` and the `"pantheon"` faction ramps in `prepare_sprite.py`;
    - `act4-audio`: "Hymn of Bronze" (`SoundData.BRONZE_SCORE`), the lazy Pantheon pack (`SoundData.PANTHEON_SOUNDS`,
      `Sfx.PACK_SEED_OFFSETS`), closing cards per act (`EpilogueData.CLOSINGS`, "The River Runs Dry" after Act III,
      panel `epilogue/close_act3`, about $0.04);
    - `act4-foundation`: the stubs, `PantheonRules` (`DivineWrath`, `Phalanx`, `Glory`), the kinds and kits, the
      Twilight of the Gods, the Act IV and Codex tabs, hit origins on `CombatResolver.damage_enemy()`, `PantheonReport`,
      `docs/act4/tools/gate.sh`;
  - the lead's merge wiring (the `bronze` music on the stubs, the Pantheon sound ids) and the review fixes (GDD row
    "Act IV foundation review fixes").
- **Verified on the merged branch** (seed 7):
  - `--import` clean;
  - the gate (Graveyard default and army, Gullhaven, Ul-Thalos, the Iron Citadel army) against `7ab1c74`: every
    gameplay line identical; only the Codex totals (enemy 55 → 59, boss 9 → 12) and the Citadel's "stages unlocked by
    this run: ilion" differ;
  - `--stage=ilion|olympus|underworld --policy=army`: VICTORY, 0 errors, `stuck_units=0`, every wrath kind striking,
    walls locking and breaking, Glory paid out; Graveyard `--mortal` clean; `--coop-bot --stage=ilion` clean.
- **Not on `main`.** Nothing of Act IV is on `main` or live. The stubs are "Coming soon" behind `"playable": false`,
  so the foundation could go to `main` the way the Act III foundation did, once the owner agrees. Tell the co-op work
  (if a session is running it) before any fast-forward of `main`.

## What is left for Act IV, in order

1. **The owner's open question:** the soldiers' sex (they asked to see the all-female `_v1` lineups again:
   `art_source/concepts/act4_lineup_v1.png` vs `act4_lineup.png`). Show both before the stage agents make their art.
2. **Phase 2:** three stage agents in parallel from `docs/act4/BRIEF_PHASE2.md` (Ilion, Olympus, the Underworld), each
   in a worktree from this branch, one Godot process each. Then merge (most conflicts are both sides appending to the
   same list: keep both; watch a list's closing `]`, a dict entry cut mid-way and a `match` arm that loses its
   `return`), `--import` and one run per stage after every merge, the gate, the balance pass (a step harder than the
   Iron Citadel; the army bot reaches 0:00 and kills the boss), the art review page (round after round until all OK),
   the Act IV epilogue part "The Gods Are Silent" and the closing card "The Sun Still Rises" (image key needed), then
   the owner's playtest and `"playable": true`.
3. **CI:** add an Act IV army job when the stages turn playable (CI runs no Act III job yet either).

## Notes for the next lead

- The foundation's own decisions are in its GDD rows: Olympus zone names, wrath damage to summons softened (5 per
  wave, 3 per fissure tick), front melee on a locked wall deals full damage (only shots are cut, to 10%), any flank
  hit breaks the whole wall for 1.6 s, Glory bounty 2 Soul Ash per stack, no Glory chest after 0:00, the Codex tab
  "Republic", compact act tabs beyond three acts, the closing card's label "Beneath the world".
- The art agent's pipeline notes (the bronze muddies through `pixelate_source.py`) are in the ART_BIBLE's Act IV
  section; the Hoplite's crest is Aegean blue, not the concept's crimson (crimson is the Covenant's).
- Image generation works in this environment (`api.openai.com` is injected by the proxy; a free
  `curl -sS -o /dev/null -w "%{http_code}" https://api.openai.com/v1/models` prints 200). Never read or print a key.
- Regenerate gate bases with `docs/act4/tools/gate.sh <tree> <outdir>` from a clean `git worktree add` of the base;
  scratchpad logs die with the container.
