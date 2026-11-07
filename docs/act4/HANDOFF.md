# Act IV handoff (lead session, updated Oct 25, 2026)

Read this first, then `CLAUDE.md` (the project rules; they win any conflict), `docs/act4/PROPOSAL.md` (the
owner-answered design) and `docs/act4/BRIEF_PHASE2.md` (how the three stages were briefed). GDD §15.0 rows from
"Act IV proposal (owner answers)" to the end of the table record every Act IV decision; "Act IV integration (phase
2)" has the final test numbers.

## Where things stand

- **Act IV is live** (owner: "Ship it!", Oct 25, 2026; GDD §15.0 "Act IV goes live"): the three stages are playable,
  CI runs one army job per stage, and `main` carries it (branch `claude/charming-lamport-upfhlz` merged with `main` and
  fast-forwarded). Balance after three bot playtest passes in `docs/act4/playtest/`.
  - **Phase 1, the foundation:** the stubs, `PantheonRules` (`DivineWrath`, `Phalanx`, `Glory`), the shared kinds, the
    Twilight of the Gods, the Act IV and Codex tabs, the `bronze` music and Pantheon sound pack, the closing cards per
    act ("The River Runs Dry" after Act III).
  - **Phase 2, the three stages** (three parallel agents, merged): **the Shores of Ilion** (siege towers, Polyphemus,
    Achilles with his heel and three phases; Legionary / testudo, Wolf of Rome, Cyclops; Paris's Arrow / Arrow of Fate
    + Mortal Heel; the Doomed Prophetess; Heel Found → Bronze Breaker), **Mount Olympus** (the Pantheon Trial: Ares,
    Artemis, Poseidon, then Zeus in three phases; Centaur Archer, Amazon, Gorgon, Hound of Artemis, Sea Serpent; Stolen
    Thunder / Gigantomachy + Titan's Blood; the Oathbreaker; Twilight of the Gods → Grounded Bones; the public
    `DivineWrath.strike()`, the one summon stun path `CombatResolver.stun_unit()`), **the Asphodel Underworld** (the
    Styx, Cerberus with three heads, Hades in three phases on the Claims path, kneeling at the end; Shade Hoplite,
    Tartarus Warden; River Styx / Lethe's Flood + Ferryman's Toll; the Ferrywoman; the Myrmidon Shades / Legion of
    Tartarus + Myrmidon Oath; Empty Throne); the Act IV epilogue part "The Gods Are Silent" (4 panels) and the card
    "The Sun Still Rises".
  - Art: about 75 API images in all (≈$1.8), every sprite with walk / idle strips as the rules ask. **None reviewed
    by the owner yet.**
- **Verified** (the big pass, see the GDD row): import clean, zero errors and `stuck_units=0` everywhere, the stages 1–9
  same-seed gate passes, co-op bot runs clean, the army bot wins every Act IV seed it ran after the Olympus tuning.

## What is left for Act IV, in order

1. ~~The owner's art review~~ **Done** (eight rounds on https://claude.ai/artifact/7BnCJnbvumT9an6eeB47Km, collections
   `act4_art_r1`–`r8`; every round in its GDD §15.0 row). After it, every bounce animation in the game was slowed
   (GDD row "Slower bounce animations": IdleData.FPS 6, one smooth swell a step), approved by the owner.
2. ~~Bot playtest passes~~ **Done** (three passes, `docs/act4/playtest/`). Next: **the owner's own playtest**, then a balance pass (open items in the GDD integration row: the naive Olympus opening,
   the Underworld is the easiest, siege towers rarely destroyed, strong Gigantomachy / Lethe's Flood / Myrmidons, the
   placeholder Soul Ash multipliers ×3.25 / ×3.5 / ×3.75).
3. ~~Turn the stages `"playable": true`, add an Act IV army job to CI, fast-forward `main`~~ **Done.**
4. The Web performance check at phone size on the busiest stage (Olympus late game), as Act III had.

## Notes for the next lead

- **Merging parallel branches:** most conflicts are both sides appending, but git keeps identical trailing lines ONCE,
  so a dict entry or `match` arm can lose its last lines (`"starts_unlocked": false`, a `return`). After resolving, run
  the block check (every block a branch added must appear intact in the merged file: see the GDD integration row) and
  `--import`, then one run per stage.
- Image generation works here (`api.openai.com` is injected by the proxy). Never read or print a key.
- Regenerate gate bases with `docs/act4/tools/gate.sh <tree> <outdir>` from a clean `git worktree add` of the base.
