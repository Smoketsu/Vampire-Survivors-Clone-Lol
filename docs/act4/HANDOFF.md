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
   `act4_art_r1`, `act4_art_r2`; GDD rows "Act IV art review, round 1" / "round 2"). Round 1: 154 OK / 41 Redo (mixed
   lineup kept). Round 2: 25 OK / 16 Redo. **Round 3 was IN FLIGHT when this session hit its usage limit**: two agents
   on LOCAL branches (not pushed, lost if the container is gone) `act4-r3-underworld` and `act4-r3-olympus`, worktrees
   `/home/user/wt/act4-r3-*`, from `6cc2c91`. **Status:** both agents stopped at the usage limit (resets 5:20 pm UTC) with partial work, saved as
   one unreviewed WIP commit on each branch: Underworld had the Ferrywoman boxes, the Legion of Tartarus and two Hades
   sources changed (the Myrmidon Shade and the Hades sprites not yet); Olympus had the Amazon's sideways sway and a new
   Titan pose in progress (the Gorgon's face not yet). Resume them (SendMessage to the same agents) or finish by hand,
   then check every change against the owner's notes before merging. If those branches still exist with commits, check their contact sheets in
   the scratchpad (`.../scratchpad/act4/r3-*/`), merge them (the ledger CSV conflicts: keep both sides), `--import`.
   Otherwise redo the round 3 list (the GDD "round 2" row has it): **Hades** regenerated as a consistent set (still,
   bident pose with TWO prongs, kneeling; robe and cloak in clearly different colours); the **Myrmidon Shade** and
   **Legion of Tartarus** restarted from the round 1 originals (commit `16ea7aa`) with only a gentle speck cleanup
   (the owner rejected the flat simplification); the **Ferrywoman**'s bust box widened 2 px left, her Deathlord skin's
   3–4 px left; the **Amazon**'s hip box swaying SIDEWAYS instead of up and down (a new axis option in
   `tools/walk_cycle.py`, other rigs unchanged); a **Bronze Titan** walk that reads (likely a new walk-friendly source
   pose of the same titan with the legs apart, then the normal `legs` rig; the round 2 mirrored "stride" was rejected);
   the **Gorgon**'s face ("so silly"). Opus agents for these (judgment-heavy art). Then publish round 3 on the same
   page: `python3 docs/act4/tools/make_act4_review_r2.py <act4_art_r2 marks dir> <out.html> 6cc2c91 3` (read the r2
   marks with ArtifactData `list` + `out_dir` first), Artifact publish with `url` = the page above (keeps capabilities).
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
