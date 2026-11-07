# Act VI playtest pass 1

Oct 31, 2026. Meta none, `--mortal`, the five builds (army, evolve, summon, newclasses, newspells), seeds 3, 7, 11. Stages: Burning Gate, Silk Palace, Pandemonium (15 runs each, 45 in all). Mechanical autotest numbers; the owner's own playtest notes outrank them.

Build ids (from `docs/act4/tools/playtest_batch.sh`): army = `--policy=army`; evolve = `--policy=evolve`; summon = `--policy=summon`; newclasses = `--policy=army --classes=abomination,rogue,gargoyle,frost_wraith`; newspells = `--policy=evolve --spells=bone_spear,soul_siphon,corpse_explosion,plague_cloud`.

## Per stage

| Stage | Deaths /15 | Boss slain /15 | Mean min HP |
|---|---|---|---|
| Burning Gate | 2 | 13 | 90 |
| Silk Palace | 2 | 11 | 84 |
| Pandemonium | 9 | 4 | 69 |
| Reference: Road to the Sun (Act V finale, pass 3) | 1 | 12 | 85 |

Per build (deaths /3 per stage): Burning Gate army 1, evolve 1, newclasses 0, newspells 0, summon 0; Silk Palace army 0, evolve 1, newclasses 1, newspells 0, summon 0; Pandemonium army 2, evolve 2, newclasses 3, newspells 0, summon 2.

Pandemonium is the hard stage: no newspells run died there, and newclasses died in all three seeds (two of them before 14:00).

## Death table

"Died at" is the game clock at death. The damage columns are the top three `player_dmg_from_` and `summon_dmg_from_` values from each run's stats line.

| Stage | Build | Seed | Died at | Top player damage | Top summon damage |
|---|---|---|---|---|---|
| Burning Gate | army | 3 | 19:53 | lava_hound=234, hell_knight=125, imp=123 | hell_knight=22202, hell_pit=12315, demon_brute=5365 |
| Burning Gate | evolve | 11 | 18:09 | demon_brute=89, imp=68, boss=64 | hell_pit=8554, demon_brute=4914, hell_knight=2753 |
| Silk Palace | evolve | 11 | 18:08 | lilith_wings=42, boss=37, succubus=36 | hell_pit=9296, demon_brute=2608, damned=600 |
| Silk Palace | newclasses | 7 | 12:29 | twin_heartbreak=80, hell_knight=47, imp=43 | hell_pit=18017, hell_knight=6874, demon_brute=1668 |
| Pandemonium | army | 3 | 18:26 | morning_star_dark=100, imp=87, hell_knight=71 | hell_knight=19571, hell_pit=17385, fallen_angel_dive=7016 |
| Pandemonium | army | 11 | 18:41 | hell_knight=247, imp=204, morning_star_dark=178 | hell_knight=15892, hell_pit=10228, fallen_angel_dive=8028 |
| Pandemonium | evolve | 7 | 19:15 | imp=164, morning_star_dark=137, hell_knight=130 | hell_knight=10416, hell_pit=4864, fallen_angel_dive=4091 |
| Pandemonium | evolve | 11 | 18:21 | fallen_angel_dive=59, demon_brute=57, boss=49 | hell_pit=13458, fallen_angel_dive=4367, demon_brute=4026 |
| Pandemonium | newclasses | 3 | 13:14 | fallen_angel_dive=47, hell_knight=45, imp=42 | hell_knight=11780, hell_pit=11681, seraph_cleave=4150 |
| Pandemonium | newclasses | 7 | 18:37 | hell_knight=169, demon_brute=71, fallen_angel_dive=59 | hell_pit=41448, hell_knight=20883, demon_brute=12288 |
| Pandemonium | newclasses | 11 | 12:39 | hell_knight=96, fallen_angel_dive=41, damned=36 | hell_pit=12070, hell_knight=11740, fallen_angel_dive=2588 |
| Pandemonium | summon | 3 | 13:53 | hell_knight=72, fallen_angel_dive=40, imp=37 | hell_pit=5033, hell_knight=4092, seraph_cleave=2046 |
| Pandemonium | summon | 11 | 17:39 | imp=82, hell_knight=71, morning_star_light=62 | hell_pit=17431, hell_knight=13511, demon_brute=8008 |

No run in the batch was NOT COMPLETED: all 45 either reached 0:00 or died before it (a death after 0:00 is a win).

## Error counts

Every log (45 of 45) was checked for `SCRIPT ERROR`, `ERROR:` and `WARNING:` lines: **0** in each. `stuck` is 0 in every run. Exit codes: 0 for the 32 runs that reached 0:00 or later, 1 for the 13 deaths before 0:00.

## Full report output

`python3 docs/act4/tools/playtest_report.py burning_gate silk_palace pandemonium`, unchanged:

| stage | build | seed | result | ended | min_hp | boss | kills | level | build_done | evos | first_evo | chests | ash | errors | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| burning_gate | army | 11 | WIN | 20:49 | 96 | 18:16 | 4370 | 61 | 18:07 | 1 | 15:28 | 6 | 884 | 0 | 0 |
| burning_gate | army | 3 | DIED | 19:53 | 62 | - | 3859 | 52 | - | 1 | 13:57 | 4 | 308 | 0 | 0 |
| burning_gate | army | 7 | WIN | 20:35 | 112 | 18:56 | 4339 | 61 | 19:03 | 2 | 10:49 | 5 | 748 | 0 | 0 |
| burning_gate | evolve | 11 | DIED | 18:09 | 111 | - | 3555 | 53 | - | 3 | 08:28 | 4 | 266 | 0 | 0 |
| burning_gate | evolve | 3 | WIN | 20:49 | 100 | 18:47 | 4285 | 61 | - | 4 | 08:01 | 7 | 581 | 0 | 0 |
| burning_gate | evolve | 7 | WIN | 20:45 | 120 | 18:32 | 4278 | 61 | - | 4 | 08:40 | 6 | 490 | 0 | 0 |
| burning_gate | newclasses | 11 | WIN | 20:58 | 46 | 17:49 | 4296 | 61 | 17:50 | 4 | 11:44 | 8 | 662 | 0 | 0 |
| burning_gate | newclasses | 3 | WIN | 20:38 | 59 | 18:01 | 4141 | 59 | 17:40 | 3 | 08:59 | 6 | 648 | 0 | 0 |
| burning_gate | newclasses | 7 | WIN | 20:38 | 48 | 17:52 | 4285 | 61 | 17:53 | 3 | 09:31 | 5 | 613 | 0 | 0 |
| burning_gate | newspells | 11 | WIN | 20:45 | 120 | 18:06 | 4503 | 61 | 18:08 | 4 | 08:00 | 8 | 476 | 0 | 0 |
| burning_gate | newspells | 3 | WIN | 20:51 | 85 | 17:56 | 4467 | 61 | 17:09 | 5 | 08:21 | 9 | 490 | 0 | 0 |
| burning_gate | newspells | 7 | WIN | 20:50 | 49 | 18:09 | 4547 | 61 | 18:16 | 5 | 08:47 | 9 | 491 | 0 | 0 |
| burning_gate | summon | 11 | WIN | 21:26 | 107 | 17:55 | 4235 | 60 | 18:44 | 3 | 15:51 | 4 | 912 | 0 | 0 |
| burning_gate | summon | 3 | WIN | 21:06 | 120 | 17:50 | 4257 | 59 | - | 3 | 11:23 | 7 | 801 | 0 | 0 |
| burning_gate | summon | 7 | WIN | 21:25 | 118 | 19:14 | 3857 | 55 | - | 3 | 17:15 | 6 | 877 | 0 | 0 |
| silk_palace | army | 11 | WIN | 21:07 | 107 | 18:24 | 4109 | 60 | 18:24 | 2 | 13:14 | 6 | 848 | 0 | 0 |
| silk_palace | army | 3 | WIN | 21:10 | 102 | - | 3745 | 54 | - | 0 | - | 2 | 678 | 0 | 0 |
| silk_palace | army | 7 | WIN | 20:46 | 85 | 19:14 | 4165 | 60 | 19:17 | 1 | 08:06 | 5 | 886 | 0 | 0 |
| silk_palace | evolve | 11 | DIED | 18:08 | 30 | - | 3637 | 54 | - | 3 | 08:00 | 5 | 336 | 0 | 0 |
| silk_palace | evolve | 3 | WIN | 20:43 | 105 | 18:38 | 4121 | 60 | - | 4 | 08:02 | 7 | 626 | 0 | 0 |
| silk_palace | evolve | 7 | WIN | 20:46 | 109 | 18:25 | 4059 | 60 | - | 3 | 08:03 | 7 | 756 | 0 | 0 |
| silk_palace | newclasses | 11 | WIN | 20:28 | 69 | 17:52 | 3946 | 59 | 17:53 | 2 | 10:19 | 5 | 722 | 0 | 0 |
| silk_palace | newclasses | 3 | WIN | 20:39 | 44 | 17:59 | 4054 | 60 | 17:07 | 3 | 11:18 | 6 | 636 | 0 | 0 |
| silk_palace | newclasses | 7 | DIED | 12:29 | 99 | - | 2173 | 41 | - | 1 | 09:46 | 2 | 252 | 0 | 0 |
| silk_palace | newspells | 11 | WIN | 21:09 | 94 | 18:21 | 3864 | 58 | 19:31 | 5 | 09:48 | 8 | 672 | 0 | 0 |
| silk_palace | newspells | 3 | WIN | 20:56 | 119 | 18:33 | 4295 | 62 | 18:34 | 4 | 08:11 | 7 | 646 | 0 | 0 |
| silk_palace | newspells | 7 | WIN | 20:47 | 88 | 18:00 | 4239 | 60 | 18:31 | 5 | 08:54 | 8 | 618 | 0 | 0 |
| silk_palace | summon | 11 | WIN | 21:07 | 93 | 18:11 | 4148 | 61 | - | 3 | 12:42 | 6 | 852 | 0 | 0 |
| silk_palace | summon | 3 | WIN | 21:25 | 68 | - | 3361 | 48 | - | 0 | - | 2 | 610 | 0 | 0 |
| silk_palace | summon | 7 | WIN | 21:08 | 50 | 19:32 | 3618 | 54 | - | 2 | 17:39 | 5 | 711 | 0 | 0 |
| pandemonium | army | 11 | DIED | 18:41 | 84 | - | 2719 | 42 | - | 0 | - | 1 | 361 | 0 | 0 |
| pandemonium | army | 3 | DIED | 18:26 | 63 | - | 3071 | 49 | - | 0 | - | 1 | 435 | 0 | 0 |
| pandemonium | army | 7 | WIN | 21:16 | 45 | - | 3176 | 47 | - | 0 | - | 1 | 744 | 0 | 0 |
| pandemonium | evolve | 11 | DIED | 18:21 | 48 | - | 3519 | 54 | - | 3 | 08:10 | 5 | 421 | 0 | 0 |
| pandemonium | evolve | 3 | WIN | 20:25 | 44 | 19:40 | 3936 | 62 | - | 4 | 08:34 | 7 | 637 | 0 | 0 |
| pandemonium | evolve | 7 | DIED | 19:15 | 57 | - | 3290 | 50 | - | 1 | 18:43 | 3 | 363 | 0 | 0 |
| pandemonium | newclasses | 11 | DIED | 12:39 | 48 | - | 2350 | 45 | - | 0 | - | 2 | 276 | 0 | 0 |
| pandemonium | newclasses | 3 | DIED | 13:14 | 40 | - | 2322 | 44 | - | 0 | - | 2 | 282 | 0 | 0 |
| pandemonium | newclasses | 7 | DIED | 18:37 | 39 | - | 3570 | 57 | 17:26 | 3 | 08:14 | 5 | 427 | 0 | 0 |
| pandemonium | newspells | 11 | WIN | 21:16 | 72 | 18:25 | 4225 | 63 | 18:26 | 5 | 08:30 | 8 | 841 | 0 | 0 |
| pandemonium | newspells | 3 | WIN | 20:50 | 99 | 19:18 | 4271 | 59 | 19:51 | 5 | 08:17 | 7 | 747 | 0 | 0 |
| pandemonium | newspells | 7 | WIN | 21:05 | 116 | 19:32 | 4259 | 64 | 18:14 | 4 | 08:29 | 7 | 802 | 0 | 0 |
| pandemonium | summon | 11 | DIED | 17:39 | 111 | - | 3409 | 55 | - | 1 | 08:16 | 3 | 559 | 0 | 0 |
| pandemonium | summon | 3 | DIED | 13:53 | 84 | - | 2500 | 45 | - | 2 | 08:00 | 3 | 388 | 0 | 0 |
| pandemonium | summon | 7 | WIN | 21:28 | 81 | - | 3936 | 57 | - | 2 | 10:39 | 4 | 820 | 0 | 0 |

Summary per stage and build (deaths before 0:00, boss kills, mean lowest HP, mean kills, mean Soul Ash):

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| burning_gate | ALL | 15 | 2 | 13 | 90 | 4218 | 616 |
| burning_gate | army | 3 | 1 | 2 | 90 | 4189 | 647 |
| burning_gate | evolve | 3 | 1 | 2 | 110 | 4039 | 446 |
| burning_gate | newclasses | 3 | 0 | 3 | 51 | 4241 | 641 |
| burning_gate | newspells | 3 | 0 | 3 | 85 | 4506 | 486 |
| burning_gate | summon | 3 | 0 | 3 | 115 | 4116 | 863 |
| pandemonium | ALL | 15 | 9 | 4 | 69 | 3370 | 540 |
| pandemonium | army | 3 | 2 | 0 | 64 | 2989 | 513 |
| pandemonium | evolve | 3 | 2 | 1 | 50 | 3582 | 474 |
| pandemonium | newclasses | 3 | 3 | 0 | 42 | 2747 | 328 |
| pandemonium | newspells | 3 | 0 | 3 | 96 | 4252 | 797 |
| pandemonium | summon | 3 | 2 | 0 | 92 | 3282 | 589 |
| silk_palace | ALL | 15 | 2 | 11 | 84 | 3836 | 657 |
| silk_palace | army | 3 | 0 | 2 | 98 | 4006 | 804 |
| silk_palace | evolve | 3 | 1 | 2 | 81 | 3939 | 573 |
| silk_palace | newclasses | 3 | 1 | 2 | 71 | 3391 | 537 |
| silk_palace | newspells | 3 | 0 | 3 | 100 | 4133 | 645 |
| silk_palace | summon | 3 | 0 | 2 | 70 | 3709 | 724 |
