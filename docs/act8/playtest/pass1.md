# Act VIII playtest pass 1

Nov 3, 2026. Meta none, `--mortal`, five builds x seeds 3, 7, 11 (`docs/act7/tools/playtest_round.sh`). Deaths /15: Skid Row 2, Fort Kessler 8, Liberty Heights 13. Riflemen lead every Liberty Heights death (the stage starts at the army tier at 0:00); Fort Kessler deaths are led by gang gunners, riflemen and riot cops. Zero errors, `stuck_units=0`.

| stage | build | seed | result | ended | min_hp | boss | kills | level | build_done | evos | first_evo | chests | ash | errors | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| fort_kessler | army | 11 | WIN | 21:02 | 103 | 18:51 | 3412 | 66 | 17:50 | 2 | 08:27 | 5 | 607 | 0 | 0 |
| fort_kessler | army | 3 | DIED | 17:16 | 33 | - | 2446 | 52 | - | 0 | - | 2 | 252 | 0 | 0 |
| fort_kessler | army | 7 | WIN | 21:05 | 115 | 19:23 | 3352 | 66 | 18:15 | 2 | 13:33 | 6 | 615 | 0 | 0 |
| fort_kessler | evolve | 11 | DIED | 10:34 | 46 | - | 1613 | 40 | - | 1 | 08:10 | 2 | 158 | 0 | 0 |
| fort_kessler | evolve | 3 | DIED | 18:13 | 57 | - | 3051 | 60 | - | 3 | 08:00 | 5 | 288 | 0 | 0 |
| fort_kessler | evolve | 7 | DIED | 08:19 | 38 | - | 1104 | 32 | - | 0 | - | 1 | 118 | 0 | 0 |
| fort_kessler | newclasses | 11 | DIED | 12:51 | 22 | - | 1933 | 47 | - | 1 | 10:56 | 3 | 196 | 0 | 0 |
| fort_kessler | newclasses | 3 | DIED | 10:36 | 31 | - | 1592 | 40 | - | 1 | 09:22 | 2 | 157 | 0 | 0 |
| fort_kessler | newclasses | 7 | DIED | 11:19 | 37 | - | 1695 | 43 | - | 0 | - | 1 | 167 | 0 | 0 |
| fort_kessler | newspells | 11 | WIN | 20:46 | 60 | 19:52 | 3472 | 64 | 17:38 | 5 | 08:01 | 8 | 561 | 0 | 0 |
| fort_kessler | newspells | 3 | DIED | 08:48 | 28 | - | 911 | 26 | - | 0 | - | 0 | 116 | 0 | 0 |
| fort_kessler | newspells | 7 | WIN | 20:07 | 52 | - | 3207 | 62 | 18:04 | 4 | 09:13 | 7 | 335 | 0 | 0 |
| fort_kessler | summon | 11 | WIN | 20:38 | 105 | 18:56 | 3404 | 65 | 18:57 | 3 | 08:09 | 5 | 532 | 0 | 0 |
| fort_kessler | summon | 3 | WIN | 20:58 | 118 | 18:35 | 3106 | 64 | - | 3 | 12:41 | 7 | 591 | 0 | 0 |
| fort_kessler | summon | 7 | WIN | 20:21 | 115 | 18:52 | 3159 | 64 | - | 3 | 11:53 | 5 | 471 | 0 | 0 |
| liberty_heights | army | 11 | WIN | 20:30 | 106 | 18:05 | 3665 | 60 | 18:08 | 1 | 09:25 | 6 | 651 | 0 | 0 |
| liberty_heights | army | 3 | DIED | 09:15 | 29 | - | 1012 | 27 | - | 0 | - | 1 | 154 | 0 | 0 |
| liberty_heights | army | 7 | WIN | 21:00 | 44 | 18:01 | 3523 | 60 | 19:19 | 2 | 08:51 | 6 | 763 | 0 | 0 |
| liberty_heights | evolve | 11 | DIED | 19:38 | 50 | 18:10 | 3396 | 59 | - | 4 | 08:01 | 8 | 514 | 0 | 0 |
| liberty_heights | evolve | 3 | DIED | 12:54 | 14 | - | 1943 | 38 | - | 1 | 08:00 | 3 | 243 | 0 | 0 |
| liberty_heights | evolve | 7 | DIED | 07:52 | 96 | - | 1006 | 27 | - | 0 | - | 1 | 139 | 0 | 0 |
| liberty_heights | newclasses | 11 | DIED | 08:46 | 59 | - | 1276 | 32 | - | 0 | - | 2 | 166 | 0 | 0 |
| liberty_heights | newclasses | 3 | DIED | 12:51 | 49 | - | 2074 | 42 | - | 1 | 12:03 | 4 | 255 | 0 | 0 |
| liberty_heights | newclasses | 7 | DIED | 11:30 | 12 | - | 1810 | 40 | - | 1 | 09:38 | 3 | 222 | 0 | 0 |
| liberty_heights | newspells | 11 | DIED | 03:34 | 42 | - | 176 | 7 | - | 0 | - | 0 | 46 | 0 | 0 |
| liberty_heights | newspells | 3 | DIED | 07:44 | 108 | - | 1071 | 28 | - | 0 | - | 1 | 141 | 0 | 0 |
| liberty_heights | newspells | 7 | DIED | 07:49 | 78 | - | 1079 | 29 | - | 0 | - | 1 | 141 | 0 | 0 |
| liberty_heights | summon | 11 | DIED | 07:49 | 25 | - | 805 | 23 | - | 0 | - | 1 | 129 | 0 | 0 |
| liberty_heights | summon | 3 | DIED | 10:06 | 29 | - | 1133 | 28 | - | 0 | - | 1 | 168 | 0 | 0 |
| liberty_heights | summon | 7 | DIED | 09:23 | 50 | - | 1063 | 28 | - | 0 | - | 1 | 157 | 0 | 0 |
| skid_row | army | 11 | WIN | 20:54 | 97 | 18:42 | 3587 | 59 | 18:57 | 2 | 10:42 | 6 | 472 | 0 | 0 |
| skid_row | army | 3 | WIN | 21:07 | 59 | 18:41 | 3412 | 58 | - | 1 | 13:45 | 4 | 503 | 0 | 0 |
| skid_row | army | 7 | WIN | 20:54 | 110 | 18:32 | 3485 | 59 | 20:45 | 2 | 16:46 | 5 | 473 | 0 | 0 |
| skid_row | evolve | 11 | WIN | 20:21 | 49 | 19:00 | 3397 | 56 | - | 3 | 10:58 | 7 | 384 | 0 | 0 |
| skid_row | evolve | 3 | WIN | 20:56 | 111 | 19:46 | 3527 | 58 | - | 4 | 10:26 | 7 | 475 | 0 | 0 |
| skid_row | evolve | 7 | DIED | 08:07 | 65 | - | 1063 | 28 | - | 1 | 08:05 | 2 | 91 | 0 | 0 |
| skid_row | newclasses | 11 | WIN | 20:22 | 36 | 18:08 | 3430 | 58 | 18:09 | 3 | 09:52 | 5 | 386 | 0 | 0 |
| skid_row | newclasses | 3 | WIN | 20:27 | 49 | 17:51 | 3440 | 58 | 17:31 | 3 | 12:55 | 7 | 401 | 0 | 0 |
| skid_row | newclasses | 7 | WIN | 20:13 | 92 | 17:57 | 3354 | 57 | 17:57 | 3 | 09:03 | 6 | 363 | 0 | 0 |
| skid_row | newspells | 11 | DIED | 07:36 | 26 | - | 988 | 27 | - | 0 | - | 1 | 86 | 0 | 0 |
| skid_row | newspells | 3 | WIN | 20:57 | 72 | - | 3599 | 54 | - | 5 | 11:05 | 7 | 408 | 0 | 0 |
| skid_row | newspells | 7 | WIN | 20:22 | 118 | - | 3516 | 54 | - | 5 | 11:36 | 6 | 314 | 0 | 0 |
| skid_row | summon | 11 | WIN | 21:01 | 91 | 18:27 | 3518 | 59 | - | 3 | 08:05 | 6 | 492 | 0 | 0 |
| skid_row | summon | 3 | WIN | 20:14 | 119 | 18:31 | 3436 | 58 | - | 3 | 13:00 | 6 | 367 | 0 | 0 |
| skid_row | summon | 7 | WIN | 20:47 | 44 | - | 3284 | 54 | - | 3 | 08:07 | 5 | 370 | 0 | 0 |

Summary per stage and build (deaths before 0:00, boss kills, mean lowest HP, mean kills, mean Soul Ash):

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| fort_kessler | ALL | 15 | 8 | 6 | 64 | 2497 | 344 |
| fort_kessler | army | 3 | 1 | 2 | 84 | 3070 | 491 |
| fort_kessler | evolve | 3 | 3 | 0 | 47 | 1923 | 188 |
| fort_kessler | newclasses | 3 | 3 | 0 | 30 | 1740 | 173 |
| fort_kessler | newspells | 3 | 1 | 1 | 47 | 2530 | 337 |
| fort_kessler | summon | 3 | 0 | 3 | 113 | 3223 | 531 |
| liberty_heights | ALL | 15 | 13 | 3 | 53 | 1669 | 259 |
| liberty_heights | army | 3 | 1 | 2 | 60 | 2733 | 523 |
| liberty_heights | evolve | 3 | 3 | 1 | 53 | 2115 | 299 |
| liberty_heights | newclasses | 3 | 3 | 0 | 40 | 1720 | 214 |
| liberty_heights | newspells | 3 | 3 | 0 | 76 | 775 | 109 |
| liberty_heights | summon | 3 | 3 | 0 | 35 | 1000 | 151 |
| skid_row | ALL | 15 | 2 | 10 | 76 | 3136 | 372 |
| skid_row | army | 3 | 0 | 3 | 89 | 3495 | 483 |
| skid_row | evolve | 3 | 1 | 2 | 75 | 2662 | 317 |
| skid_row | newclasses | 3 | 0 | 3 | 59 | 3408 | 383 |
| skid_row | newspells | 3 | 1 | 0 | 72 | 2701 | 269 |
| skid_row | summon | 3 | 0 | 2 | 85 | 3413 | 410 |
