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
| Turning Year (XV → XV) | 3 stages, the Last Claim | yes (`docs/year/playtest/pass1.md`) | approved (round 10) | Fae Court summon 2/3 (the Winter Prince's minute is the next lever) |

Owner answers: GDD §15.0 "Wave 2 owner answers" and "Wave 3 owner answers". Lead calls the owner may still overrule are
in each act's GDD rows (and were listed to the owner as they came).

## Waiting on the owner

- **Art: all approved** (owner, round 10, Nov 2026): every wave 2 image, the Turning Year's stage art and the 53
  epilogue panels. Review page <https://claude.ai/artifact/3xvAN2KYTE1JVuotg3HcZp>, collections `wave2_art_r1`..`r10`;
  generators `docs/last_acts/tools/make_wave2_review*.py`. Future redos: one Sonnet agent (bust boxes: the ART_BIBLE rule,
  `tools/bust_check.py --scale 8`; the review previews play at about 2x, so the owner's "N px" is about N/2 art px).
- Design questions: all answered (owner, Nov 2026; GDD §15.0 "Owner answers after the reorder tuning" and "Fairy rings
  slow attacks; Heartwood renamed Deep Roots"): the Thorn Tithe stays; fairy rings slow attacks too, both armies
  (built: attack timers and spell cooldowns at half speed inside a ring); Heartwood is renamed Deep Roots (built; the id
  `heartwood` stays); the Green Mother's half-damage ward during Last Claim slots stays.

## Next, in order

1. (Art: done, all approved.)
2. **The reorder pass** (PLAN.md "Waves" 4). **Part 1 (order and numbering) is done** (GDD §15.0 "The reorder pass,
   part 1 (order and numbering)"): `StageRegistry.ACT_ORDER` is the one ordered list (act numbers, Parts, chapters, the
   unlock chain and the Soul Ash bonus derive from it; act-scoped rows name acts by id), Part tabs on the stage select
   (`docs/last_acts/reorder_stage_select.png`, phone `reorder_stage_select_phone.png`; tool
   `tools/stage_select_shot.tscn`), save version 3 keeps every stage a save had opened (`tools/save_migration_check.tscn`,
   in CI), CI 46 jobs in the act order (an army job for every stage; Act III's were missing). **Part 2 (the story): done** (GDD §15.0 "The reorder pass, part 2 (the story)": fifteen epilogue parts in the act order, 14 closing cards, the panels still to paint are in `docs/last_acts/EPILOGUE_PANELS.md`). Parts open on the finale boss kill and the Hyper relic feat counts every finale (owner, GDD §15.0 row after part 2); all epilogue panels painted and approved (rounds 9 and 10). **Part 3 (slot tuning): done** (GDD §15.0 "The reorder pass, part 3 (slot tuning)", `docs/last_acts/playtest/reorder_pass1.md`; owner accepted the values; the city stuck units it exposed are fixed, GDD §15.0 "City stuck units after the slot tuning"). **Left:** (optional) renaming the act numbers in old code comments and README sections, which
   still say the number each act was built under.
3. **Before `main` moves:** the full "Done" set and same-seed gates (the city stages need a multi-seed look after the stuck-unit fix; the Fae Court rings now slow attacks too), plus `tools/coop_lockstep_gate.py` (the Fae Court's
   Bargain added a co-op lockstep command that only the in-process co-op bot has exercised).
4. Known tooling bug: `docs/act4/tools/playtest_report.py` reads min HP wrong for runs that died (use the log's
   `min_hp_before_0=` line).
