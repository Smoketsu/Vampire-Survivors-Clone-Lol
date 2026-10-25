# Act IV handoff (lead session, updated Oct 25, 2026)

Read this first, then `CLAUDE.md` (the project rules; they win any conflict), `docs/act4/PROPOSAL.md` (the
owner-answered design) and `docs/act4/BRIEF_PHASE2.md` (how the three stages were briefed). GDD §15.0 rows from
"Act IV proposal (owner answers)" to the end of the table record every Act IV decision; "Act IV integration (phase
2)" has the final test numbers.

## Where things stand

- **Branch `claude/charming-lamport-upfhlz`** (pushed) holds all of Act IV on top of `main` (`3cbe21f`). Nothing of Act
  IV is on `main` or live: the three stages are still `"playable": false` ("Coming soon").
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

1. **The owner's art review** (one page, https://claude.ai/artifact/7BnCJnbvumT9an6eeB47Km; marks in db collections
   `act4_art_r1`, `act4_art_r2`, `act4_art_r3`; GDD rows "Act IV art review, round 1" / "round 2"). Round 1: 154 OK /
   41 Redo (mixed lineup kept). Round 2: 25 OK / 16 Redo. **Round 3 is published** (16 redone + 3 changed with them:
   the Hades set regenerated, the Myrmidon Shade and Legion of Tartarus from the round 1 originals with a speck
   cleanup, the Ferrywoman boxes widened left, the Amazon's sideways sway (`walk_cycle.py` rig key `bust_axis="x"`), the
   Bronze Titan in a new legs-apart pose with a `legs` walk, the Gorgon's face repainted). Open question on the page:
   Hades' cloak uses the player's violet. Round 3: 9 OK / 9 Redo (GDD row "round 3"). **Round 4 is published** (`act4_art_r4`): Hades back to his
   round 1 sprites recoloured (bone robe under a midnight-Aegean cloak, `art_source/underworld/r4/hades_recolour.py`;
   the alternative scheme E, charcoal robe, is a "choice" card: if the owner marks it OK, switch the script's scheme
   letter and rerun it), the Myrmidon Shade and Legion of Tartarus regenerated from their original prompts, the
   Amazon's skirt (her front flap read as genitalia: now a full pleated war skirt; still, walk and idle rebuilt). Round 4 (GDD row "round 4"): the Legion of Tartarus
   and scheme E approved. **Round 5 is published** (`act4_art_r5`): Hades regenerated as colour edits of his round 1
   images (scheme E, the round 1 head pasted back; `art_source/underworld/r5/`), the Amazon regenerated (70 px, muscular,
   short closed skirt), the Myrmidon Shade's face. Round 5: Hades and the Myrmidon Shade approved. **Round 6 is
   published** (`act4_art_r6`), the last asset: the Amazon's skirt (high side flaps showing the thighs, a front panel with
   one flat hem over the crotch, a `swish` box in `walk_cycle.py`). Next: read `act4_art_r6`; if OK, the art review is
   done (record it in GDD §15.0); a round 7 is `make_act4_review_r2.py <act4_art_r6 marks dir> <out.html> <HEAD> 7`.
2. **The owner's playtest**, then the balance pass (open items in the GDD integration row: the naive Olympus opening,
   the Underworld is the easiest, siege towers rarely destroyed, strong Gigantomachy / Lethe's Flood / Myrmidons, the
   placeholder Soul Ash multipliers ×3.25 / ×3.5 / ×3.75).
3. Turn the stages `"playable": true`, add an Act IV army job to CI, fast-forward `main` (tell any co-op session first).
4. The Web performance check at phone size on the busiest stage (Olympus late game), as Act III had.

## Notes for the next lead

- **Merging parallel branches:** most conflicts are both sides appending, but git keeps identical trailing lines ONCE,
  so a dict entry or `match` arm can lose its last lines (`"starts_unlocked": false`, a `return`). After resolving, run
  the block check (every block a branch added must appear intact in the merged file: see the GDD integration row) and
  `--import`, then one run per stage.
- Image generation works here (`api.openai.com` is injected by the proxy). Never read or print a key.
- Regenerate gate bases with `docs/act4/tools/gate.sh <tree> <outdir>` from a clean `git worktree add` of the base.
