# Reorder pass, part 4: the final test pass (Nov 16, 2026)

Branch head e15a913d (main's promo-tool commits merged in). Kept lean: CI does the broad pass, the local runs cover only what CI does not.

## CI (workflow_dispatch on the branch, run 114): success
<https://github.com/Smoketsu/Vampire-Survivors-Clone-Lol/actions/runs/43932982293>: import, the 46 stage jobs (every stage's
army autotest, the Graveyard naive / army, the Crimson March, the Ossuary / demo / act-order / save-migration checks),
the Windows / Linux / Web exports and their smoke test, coop-net and coop-lockstep. The publish and deploy jobs are
gated on main / tags and did not run.

## Local (what CI does not cover)
- Import: 0 errors. Graveyard `--mortal`: victory, `stuck_units=0`, 0 errors.
- **Same-seed gate** (army, seed 7, the code before part 3 (4d4c9c0c) against now, timing lines ignored): cutter,
  vigrid, two_truths, olympus, pandemonium, empyrean, last_day, greenwood: **0 differing lines** each.
- **Multi-seed city and Fae Court** (army and summon, seeds 3 and 11, `--mortal`): 16 runs, all `stuck_units=0`,
  0 errors. Three deaths before 0:00: Liberty Heights army s11 (7:41) and summon s11 (7:04), Fae Court summon s3
  (12:32). **All three die on the pre-part-3 code as well** (8:16, 8:07, 13:14): seed-specific, not caused by the tuning,
  the city stuck-unit fix or the ring attack slow. Liberty Heights seed 11 is the known early-collapse soft spot (both
  builds at level 7-9 by 7:00, riot cops grinding the army down).
- **Co-op lockstep gate on the Fae Court** (`tools/coop_lockstep_gate.py --stage=fae_court`, two processes, the
  Bargain command): **PASS** (wipe at 20:56, checksums matched).
