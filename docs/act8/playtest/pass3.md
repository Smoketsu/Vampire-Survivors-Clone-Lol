# Act VIII playtest pass 3 (Liberty Heights only)

Nov 3, 2026. After the owner's pass 2 call "Later army on Liberty Heights" (police 0:00, SWAT 2:30, army 5:00 instead of 0:00; heroes still 15:00; the timeline spawns only the reached tiers' kinds). Deaths /15: Liberty Heights 14 (pass 2) -> 11 (pass 3), boss kills 1 -> 4, mean min HP 58 -> 48, mean kills 1600 -> 1960, mean Soul Ash 230 -> 345.
Zero errors, `stuck_units=0`. Better, but six of 11 deaths still fall at 7:12-9:04 (early collapses with 94-658 kills: the horde stays at 1-3 units against riot cops and the first Super, Blitz), and rifleman fire is again the top damage source in the later deaths (newclasses, evolve, army seed 3).

| stage | build | seed | result | ended | min_hp | boss | kills | level | build_done | evos | first_evo | chests | ash | errors | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| liberty_heights | army | 11 | DIED | 07:38 | 82 | - | 94 | 9 | - | 0 | - | 0 | 88 | 0 | 0 |
| liberty_heights | army | 3 | DIED | 18:30 | 50 | - | 2320 | 47 | - | 0 | - | 2 | 322 | 0 | 0 |
| liberty_heights | army | 7 | WIN | 20:51 | 78 | 18:13 | 3431 | 60 | 19:06 | 2 | 15:14 | 7 | 718 | 0 | 0 |
| liberty_heights | evolve | 11 | DIED | 07:12 | 62 | - | 213 | 15 | - | 0 | - | 1 | 96 | 0 | 0 |
| liberty_heights | evolve | 3 | WIN | 20:38 | 44 | 18:04 | 3443 | 62 | - | 4 | 08:04 | 9 | 672 | 0 | 0 |
| liberty_heights | evolve | 7 | DIED | 17:51 | 47 | - | 2653 | 49 | - | 3 | 08:15 | 7 | 342 | 0 | 0 |
| liberty_heights | newclasses | 11 | DIED | 15:13 | 7 | - | 2489 | 50 | - | 2 | 08:01 | 5 | 300 | 0 | 0 |
| liberty_heights | newclasses | 3 | DIED | 18:02 | 10 | - | 3126 | 56 | 16:12 | 3 | 09:16 | 7 | 372 | 0 | 0 |
| liberty_heights | newclasses | 7 | DIED | 14:46 | 39 | - | 2364 | 50 | - | 2 | 09:48 | 5 | 288 | 0 | 0 |
| liberty_heights | newspells | 11 | WIN | 20:30 | 56 | 18:08 | 3425 | 59 | 18:13 | 5 | 08:01 | 10 | 639 | 0 | 0 |
| liberty_heights | newspells | 3 | DIED | 07:15 | 58 | - | 433 | 20 | - | 0 | - | 2 | 105 | 0 | 0 |
| liberty_heights | newspells | 7 | DIED | 07:38 | 95 | - | 658 | 27 | - | 0 | - | 1 | 120 | 0 | 0 |
| liberty_heights | summon | 11 | DIED | 08:04 | 12 | - | 136 | 11 | - | 0 | - | 1 | 102 | 0 | 0 |
| liberty_heights | summon | 3 | WIN | 21:23 | 64 | 17:55 | 3543 | 62 | - | 3 | 08:18 | 8 | 846 | 0 | 0 |
| liberty_heights | summon | 7 | DIED | 09:04 | 10 | - | 1074 | 35 | - | 1 | 08:47 | 3 | 162 | 0 | 0 |

Summary per stage and build (deaths before 0:00, boss kills, mean lowest HP, mean kills, mean Soul Ash):

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| liberty_heights | ALL | 15 | 11 | 4 | 48 | 1960 | 345 |
| liberty_heights | army | 3 | 2 | 1 | 70 | 1948 | 376 |
| liberty_heights | evolve | 3 | 2 | 1 | 51 | 2103 | 370 |
| liberty_heights | newclasses | 3 | 3 | 0 | 19 | 2660 | 320 |
| liberty_heights | newspells | 3 | 2 | 1 | 70 | 1505 | 288 |
| liberty_heights | summon | 3 | 2 | 1 | 29 | 1584 | 370 |

## Deaths (11 of 15), time and top "dmg to you" kinds (from each log's `city kinds` line)

| build | seed | died at | top damage to you |
|---|---|---|---|
| army | 11 | 7:38 | blitz 66, riot_cop 53, swat_breacher 30 |
| army | 3 | 18:30 | rifleman 239, riot_cop 99, conscript 84 |
| evolve | 11 | 7:12 | rifleman 97, blitz 49, riot_cop 36 |
| evolve | 7 | 17:51 | rifleman 200, riot_cop 86, blitz 56 |
| newclasses | 11 | 15:13 | rifleman 208, conscript 33, swat_breacher 9 |
| newclasses | 3 | 18:02 | rifleman 402, riot_cop 47, conscript 32 |
| newclasses | 7 | 14:46 | rifleman 262, riot_cop 46, tank 27 |
| newspells | 3 | 7:15 | rifleman 145, riot_cop 63, blitz 34 |
| newspells | 7 | 7:38 | rifleman 117, riot_cop 71, blitz 34 |
| summon | 11 | 8:04 | riot_cop 67, blitz 45, rifleman 43 |
| summon | 7 | 9:04 | riot_cop 133, rifleman 72, tank 18 |

Wins: army 7, evolve 3, newspells 11, summon 3.
