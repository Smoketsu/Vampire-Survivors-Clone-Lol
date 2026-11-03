# Act VIII playtest pass 4 (Fort Kessler and Liberty Heights)

Nov 3, 2026. After the owner's call "Stage damage x1.3": `ENEMY_DAMAGE_MULT` 1.5 -> 1.3 in `fort_kessler_stage.gd` and `liberty_heights_stage.gd`, nothing else. Deaths /15: Fort Kessler 9 (pass 2) -> 7 (pass 4); Liberty Heights 14 (pass 2) -> 11 (pass 3) -> 6 (pass 4); boss kills Fort Kessler 7, Liberty Heights 9.
Zero errors, `stuck_units=0`. Remaining pattern: Liberty Heights early collapses at 7:14-8:16 (5 of 6 deaths, 117-662 kills; riot cops and Blitz plus riflemen) and Fort Kessler newclasses / newspells builds (5 of 7 deaths, gang gunners and riflemen).

| stage | build | seed | result | ended | min_hp | boss | kills | level | build_done | evos | first_evo | chests | ash | errors | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| fort_kessler | army | 11 | WIN | 20:22 | 91 | 18:09 | 3330 | 66 | 17:08 | 3 | 08:00 | 6 | 478 | 0 | 0 |
| fort_kessler | army | 3 | WIN | 20:43 | 96 | - | 2904 | 57 | - | 0 | - | 2 | 436 | 0 | 0 |
| fort_kessler | army | 7 | WIN | 21:26 | 110 | 19:31 | 3431 | 67 | 19:05 | 2 | 10:32 | 6 | 688 | 0 | 0 |
| fort_kessler | evolve | 11 | WIN | 20:30 | 61 | 18:56 | 3346 | 65 | - | 3 | 08:00 | 5 | 505 | 0 | 0 |
| fort_kessler | evolve | 3 | WIN | 20:45 | 104 | 18:38 | 3435 | 66 | - | 3 | 08:01 | 6 | 557 | 0 | 0 |
| fort_kessler | evolve | 7 | DIED | 18:39 | 37 | - | 3046 | 61 | - | 3 | 09:52 | 5 | 292 | 0 | 0 |
| fort_kessler | newclasses | 11 | DIED | 14:29 | 14 | - | 2249 | 52 | - | 2 | 09:34 | 4 | 223 | 0 | 0 |
| fort_kessler | newclasses | 3 | DIED | 10:52 | 45 | - | 1646 | 41 | - | 1 | 10:47 | 2 | 162 | 0 | 0 |
| fort_kessler | newclasses | 7 | DIED | 13:09 | 36 | - | 2051 | 47 | - | 1 | 09:41 | 2 | 198 | 0 | 0 |
| fort_kessler | newspells | 11 | DIED | 19:32 | 95 | - | 3207 | 60 | 18:12 | 5 | 08:02 | 7 | 307 | 0 | 0 |
| fort_kessler | newspells | 3 | DIED | 09:08 | 11 | - | 937 | 26 | - | 0 | - | 0 | 120 | 0 | 0 |
| fort_kessler | newspells | 7 | WIN | 20:22 | 98 | 20:05 | 3338 | 63 | 17:01 | 6 | 08:57 | 8 | 480 | 0 | 0 |
| fort_kessler | summon | 11 | WIN | 20:06 | 101 | 18:23 | 3378 | 65 | 18:25 | 3 | 08:00 | 6 | 432 | 0 | 0 |
| fort_kessler | summon | 3 | DIED | 15:34 | 91 | - | 1609 | 40 | - | 0 | - | 2 | 205 | 0 | 0 |
| fort_kessler | summon | 7 | WIN | 20:30 | 115 | 18:47 | 2632 | 57 | - | 3 | 13:36 | 7 | 482 | 0 | 0 |
| liberty_heights | army | 11 | DIED | 08:16 | 30 | - | 117 | 10 | - | 0 | - | 0 | 103 | 0 | 0 |
| liberty_heights | army | 3 | WIN | 21:02 | 88 | 18:32 | 3469 | 62 | 18:32 | 2 | 15:54 | 7 | 763 | 0 | 0 |
| liberty_heights | army | 7 | WIN | 20:22 | 78 | 18:38 | 3295 | 59 | 18:58 | 2 | 17:55 | 6 | 603 | 0 | 0 |
| liberty_heights | evolve | 11 | DIED | 07:14 | 62 | - | 215 | 15 | - | 0 | - | 1 | 96 | 0 | 0 |
| liberty_heights | evolve | 3 | WIN | 21:01 | 54 | 18:06 | 3431 | 61 | - | 4 | 08:01 | 9 | 756 | 0 | 0 |
| liberty_heights | evolve | 7 | WIN | 20:48 | 72 | 18:19 | 3218 | 60 | - | 4 | 08:16 | 9 | 697 | 0 | 0 |
| liberty_heights | newclasses | 11 | DIED | 17:58 | 34 | - | 3055 | 54 | 16:58 | 3 | 08:06 | 6 | 367 | 0 | 0 |
| liberty_heights | newclasses | 3 | WIN | 20:00 | 83 | 17:58 | 3476 | 62 | 16:36 | 3 | 11:14 | 7 | 532 | 0 | 0 |
| liberty_heights | newclasses | 7 | WIN | 20:34 | 88 | 17:51 | 3513 | 62 | 16:26 | 3 | 10:27 | 8 | 661 | 0 | 0 |
| liberty_heights | newspells | 11 | WIN | 20:43 | 42 | 18:00 | 3419 | 61 | 18:01 | 5 | 08:13 | 10 | 688 | 0 | 0 |
| liberty_heights | newspells | 3 | DIED | 07:58 | 58 | - | 491 | 21 | - | 0 | - | 2 | 115 | 0 | 0 |
| liberty_heights | newspells | 7 | DIED | 07:37 | 95 | - | 662 | 27 | - | 0 | - | 1 | 120 | 0 | 0 |
| liberty_heights | summon | 11 | DIED | 08:07 | 28 | - | 137 | 11 | - | 0 | - | 1 | 102 | 0 | 0 |
| liberty_heights | summon | 3 | WIN | 20:13 | 64 | 18:01 | 3456 | 62 | 18:03 | 3 | 10:46 | 8 | 579 | 0 | 0 |
| liberty_heights | summon | 7 | WIN | 20:30 | 93 | 18:38 | 3376 | 60 | 18:38 | 1 | 09:07 | 6 | 633 | 0 | 0 |

Summary per stage and build (deaths before 0:00, boss kills, mean lowest HP, mean kills, mean Soul Ash):

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| fort_kessler | ALL | 15 | 7 | 7 | 74 | 2703 | 371 |
| fort_kessler | army | 3 | 0 | 2 | 99 | 3222 | 534 |
| fort_kessler | evolve | 3 | 1 | 2 | 67 | 3276 | 451 |
| fort_kessler | newclasses | 3 | 3 | 0 | 32 | 1982 | 194 |
| fort_kessler | newspells | 3 | 2 | 1 | 68 | 2494 | 302 |
| fort_kessler | summon | 3 | 1 | 2 | 102 | 2540 | 373 |
| liberty_heights | ALL | 15 | 6 | 9 | 65 | 2355 | 454 |
| liberty_heights | army | 3 | 1 | 2 | 65 | 2294 | 490 |
| liberty_heights | evolve | 3 | 1 | 2 | 63 | 2288 | 516 |
| liberty_heights | newclasses | 3 | 1 | 2 | 68 | 3348 | 520 |
| liberty_heights | newspells | 3 | 2 | 1 | 65 | 1524 | 308 |
| liberty_heights | summon | 3 | 1 | 2 | 62 | 2323 | 438 |

## Deaths (13 of 30), time and top "dmg to you" kinds (from each log's `city kinds` line)

| stage | build | seed | died at | top damage to you |
|---|---|---|---|---|
| fort_kessler | evolve | 7 | 18:39 | rifleman 481, gang_gunner 205, riot_cop 167 |
| fort_kessler | newclasses | 11 | 14:29 | rifleman 139, gang_gunner 91, swat_breacher 21 |
| fort_kessler | newclasses | 3 | 10:52 | gang_gunner 81, rifleman 63, riot_cop 35 |
| fort_kessler | newclasses | 7 | 13:09 | rifleman 105, gang_gunner 99, riot_cop 33 |
| fort_kessler | newspells | 11 | 19:32 | rifleman 620, gang_gunner 236, swat_breacher 226 |
| fort_kessler | newspells | 3 | 09:08 | gang_gunner 216, riot_cop 129, swat_breacher 73 |
| fort_kessler | summon | 3 | 15:34 | rifleman 187, mammoth 34, swat_breacher 28 |
| liberty_heights | army | 11 | 08:16 | riot_cop 53, rifleman 49, swat_breacher 30 |
| liberty_heights | evolve | 11 | 07:14 | rifleman 96, blitz 49, riot_cop 36 |
| liberty_heights | newclasses | 11 | 17:58 | rifleman 361, conscript 34, swat_breacher 9 |
| liberty_heights | newspells | 3 | 07:58 | rifleman 210, riot_cop 63, conscript 39 |
| liberty_heights | newspells | 7 | 07:37 | rifleman 122, riot_cop 71, blitz 34 |
| liberty_heights | summon | 11 | 08:07 | riot_cop 67, blitz 45, rifleman 27 |
