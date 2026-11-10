# The last six acts: handoff (paused Nov 2026, owner: "hold off on everything else until usage resets")

Branch: `claude/determined-pasteur-hdy1g6` (pushed; nothing is on `main` yet). Plan: `docs/last_acts/PLAN.md`.
Process that worked: one agent at a time on this branch (no parallel worktrees, no merges), Opus for stages / tuning,
Sonnet for art / audio / review pages, Haiku for test batches; every agent commits WIP at milestones (the container
restarted once mid-stage). The lead pushes after each agent.

## State

| Act (temp number → final slot) | Built | Tuned | Art | Notes |
| --- | --- | --- | --- | --- |
| Black Tide (X → II) | 3 stages | yes (`docs/tide/playtest/pass1.md`) | approved (old session) | Cutter newspells 2/3 deaths left |
| Hall of the Slain (XI → VI) | 3 stages | yes (`docs/norse/playtest/pass1.md`) | approved (old session) | Vigrid newclasses 3/3 left |
| Necropolis Dynasty (XII → VII) | 3 stages | yes (`docs/dynasty/playtest/pass1.md`) | approved (old session) | Ammit lives 5-10 s (Weighing at 30%; owner: playtest) |
| Celestial Host (XIII → X) | 3 stages | yes (`docs/host/playtest/pass1.md`) | approved | Silver Stair newclasses 2/3 left |
| Age of Titans (XIV → XIV) | 3 stages | yes (`docs/titans/playtest/pass1.md`) | approved | |
| Turning Year (XV → XV) | 3 stages, the Last Claim | yes (`docs/year/playtest/pass1.md`) | **awaiting marks** | Fae Court summon 2/3 (the Winter Prince's minute is the next lever) |

Owner answers: GDD §15.0 "Wave 2 owner answers" and "Wave 3 owner answers". Lead calls the owner may still overrule are
in each act's GDD rows (and were listed to the owner as they came).

## Waiting on the owner

- **Art marks:** review page <https://claude.ai/artifact/3xvAN2KYTE1JVuotg3HcZp>, db collection `wave2_art_r8`:
  60 images (the 4 Blind Saint / Fern Huntress bust-box nudges of round 7, read as 3 and 5 art pixels from the owner's
  "5 px" / "9 px", then the Turning Year's stage art). Earlier rounds are in collections `wave2_art_r1`..`r7`.
  Generators: `docs/last_acts/tools/make_wave2_review*.py` (r6 / r7 show was / now for redone images; r8 merged
  with r7 by hand). Redo any Redo marks with one Sonnet agent (bust boxes: the ART_BIBLE rule, check with
  `tools/bust_check.py --scale 8` and look at the image).
- Open design questions: the Thorn Tithe (the Fae Court's second bargain, an agent's design), fairy rings slowing
  attacks too (lead: no), Heartwood (the Ossuary Oak's passive name), the half-damage ward on the Green Mother during
  Last Claim slots (lead: keep).

## Next, in order

1. Any art Redo from the marks.
2. **The reorder pass** (PLAN.md "Waves" 4): one ordered act list, renumbered stages and acts, the unlock chain,
   Part-grouped act tabs (three Parts of five), the save migration, the epilogue parts and closing cards for every act,
   a bot pass per moved act, CI jobs for every new stage (43 matrix jobs now).
3. **Before `main` moves:** the full "Done" set and same-seed gates, plus `tools/coop_lockstep_gate.py` (the Fae Court's
   Bargain added a co-op lockstep command that only the in-process co-op bot has exercised).
4. Known tooling bug: `docs/act4/tools/playtest_report.py` reads min HP wrong for runs that died (use the log's
   `min_hp_before_0=` line).
