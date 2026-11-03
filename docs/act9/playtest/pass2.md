# Act IX playtest pass 2 (the Ark)

Change ("Harden the Ark", owner, after pass 1): `ark_stage.gd` enemy HP x2.15 -> x3.0, damage x1.5 -> x2.5, every segment's spawn rate and alive cap x1.2 (events and guest squads unchanged).
Deaths before 0:00, the Ark: pass 1 0/15 -> pass 2 4/15 (army 0/3, summon 0/3, newspells 0/3, evolve 2/3, newclasses 2/3); the Harvester slain 14 -> 10 of 15; mean lowest HP 113 -> 99. The Crash Site (3/15) and the Proving Moon (1/15) were not rerun: the Ark is now the hardest Act IX stage.
Meta none, `--mortal`, five builds x seeds 3, 7, 11 (`docs/act7/tools/playtest_round.sh <dir> ark`, `docs/act4/tools/playtest_report.py`). Zero errors, `stuck_units=0` in every run (the stuck check now ignores stunned summons: Grey Overseer pulses on army seed 3).

| stage | build | seed | result | ended | min_hp | boss | kills | level | build_done | evos | first_evo | chests | ash | errors | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ark | army | 11 | WIN | 20:56 | 120 | 19:02 | 4362 | 72 | 15:04 | 2 | 09:26 | 5 | 742 | 0 | 0 |
| ark | army | 3 | WIN | 20:32 | 90 | - | 2455 | 51 | - | 0 | - | 3 | 457 | 0 | 0 |
| ark | army | 7 | WIN | 20:47 | 120 | 19:59 | 4265 | 71 | 14:46 | 1 | 09:22 | 4 | 706 | 0 | 0 |
| ark | evolve | 11 | DIED | 18:53 | 115 | - | 3626 | 62 | - | 4 | 08:13 | 6 | 373 | 0 | 0 |
| ark | evolve | 3 | WIN | 20:48 | 109 | 18:56 | 4384 | 71 | - | 4 | 08:07 | 7 | 715 | 0 | 0 |
| ark | evolve | 7 | DIED | 18:43 | 44 | - | 3863 | 65 | - | 3 | 08:01 | 5 | 382 | 0 | 0 |
| ark | newclasses | 11 | WIN | 20:32 | 102 | 18:56 | 4355 | 72 | 13:52 | 3 | 08:17 | 6 | 652 | 0 | 0 |
| ark | newclasses | 3 | DIED | 19:13 | 42 | - | 3937 | 65 | 14:05 | 3 | 09:07 | 5 | 393 | 0 | 0 |
| ark | newclasses | 7 | DIED | 19:20 | 49 | - | 4048 | 66 | 14:23 | 3 | 08:02 | 5 | 399 | 0 | 0 |
| ark | newspells | 11 | WIN | 20:40 | 115 | 18:58 | 4399 | 72 | 16:20 | 5 | 09:02 | 8 | 684 | 0 | 0 |
| ark | newspells | 3 | WIN | 20:48 | 112 | 19:35 | 4447 | 72 | 15:46 | 5 | 08:01 | 8 | 717 | 0 | 0 |
| ark | newspells | 7 | WIN | 21:03 | 116 | 19:49 | 4524 | 72 | 15:33 | 5 | 08:01 | 8 | 778 | 0 | 0 |
| ark | summon | 11 | WIN | 21:06 | 120 | 18:48 | 4436 | 72 | 17:48 | 3 | 08:03 | 6 | 784 | 0 | 0 |
| ark | summon | 3 | WIN | 21:06 | 112 | 18:40 | 4304 | 71 | 18:41 | 4 | 10:59 | 6 | 781 | 0 | 0 |
| ark | summon | 7 | WIN | 21:04 | 116 | 18:42 | 4402 | 71 | 18:33 | 3 | 09:17 | 6 | 775 | 0 | 0 |

Summary per stage and build (deaths before 0:00, boss kills, mean lowest HP, mean kills, mean Soul Ash):

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| ark | ALL | 15 | 4 | 10 | 99 | 4120 | 623 |
| ark | army | 3 | 0 | 2 | 110 | 3694 | 635 |
| ark | evolve | 3 | 2 | 1 | 89 | 3958 | 490 |
| ark | newclasses | 3 | 2 | 1 | 64 | 4113 | 481 |
| ark | newspells | 3 | 0 | 3 | 114 | 4457 | 726 |
| ark | summon | 3 | 0 | 3 | 116 | 4381 | 780 |

## Deaths (4 of 15), time and top "dmg to you" kinds (from each log's `concord kinds` line; the Harvester from its `harvester` line)

| stage | build | seed | died at | top damage to you | the Harvester |
|---|---|---|---|---|---|
| ark | evolve | 11 | 18:53 | broodling 113, lumen_sentinel 108, grey_drone 55, luminous_archon 36 | 175 (touch 163, beams 12) |
| ark | evolve | 7 | 18:43 | lumen_sentinel 302, vrask_hunter 144, luminous_archon 112, broodling 72 | 55 (touch) |
| ark | newclasses | 3 | 19:13 | lumen_sentinel 215, broodling 160, luminous_archon 63, grey_drone 59 | 52 (beams) |
| ark | newclasses | 7 | 19:20 | lumen_sentinel 317, grey_drone 72, luminous_archon 68, broodling 68 | 96 (beams) |

Every death fell in the Harvester's fight (18:43-19:20), after the Reaping's emitters lifted 22-52 summons and the ring thinned (summons 5-19 at 18:00). Lumen Sentinel beams were the top source in three of the four.
