# Act VII playtest pass 1

Nov 2, 2026. Meta none, `--mortal`, the five builds (army, evolve, summon, newclasses, newspells; see `docs/act4/tools/playtest_batch.sh`), seeds 3, 7, 11, run with `docs/act7/tools/playtest_round.sh`. Mechanical autotest numbers; the owner's own playtest notes outrank them.

Deaths /15: Ravensmoor 2, Witchwood 6, Castle Sanguis 5 (Act VI pass 1 for reference: 2, 2, 9). Every death is led by werewolves and Blood Knights (cumulative damage to the necromancer); five of the six newspells deaths fall at 8:00-9:16, under the second Blood Moon. Zero errors, `stuck_units=0` in all 45 runs.

| stage | build | seed | result | ended | min_hp | boss | kills | level | build_done | evos | first_evo | chests | ash | errors | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| castle_sanguis | army | 11 | WIN | 21:38 | 120 | 18:18 | 3961 | 63 | 18:18 | 1 | 12:16 | 5 | 912 | 0 | 0 |
| castle_sanguis | army | 3 | WIN | 21:22 | 53 | 18:00 | 3846 | 61 | - | 1 | 09:41 | 5 | 849 | 0 | 0 |
| castle_sanguis | army | 7 | WIN | 21:36 | 60 | 18:39 | 3828 | 61 | 20:00 | 2 | 13:31 | 5 | 897 | 0 | 0 |
| castle_sanguis | evolve | 11 | WIN | 21:06 | 106 | 18:27 | 3983 | 63 | - | 4 | 08:01 | 7 | 792 | 0 | 0 |
| castle_sanguis | evolve | 3 | WIN | 20:43 | 104 | 18:22 | 3978 | 63 | - | 4 | 09:24 | 7 | 706 | 0 | 0 |
| castle_sanguis | evolve | 7 | DIED | 17:07 | 7 | - | 3197 | 55 | - | 4 | 08:01 | 5 | 363 | 0 | 0 |
| castle_sanguis | newclasses | 11 | WIN | 20:31 | 72 | 18:24 | 3919 | 63 | 16:43 | 3 | 09:04 | 6 | 658 | 0 | 0 |
| castle_sanguis | newclasses | 3 | DIED | 16:43 | 28 | - | 3105 | 53 | - | 3 | 11:55 | 5 | 355 | 0 | 0 |
| castle_sanguis | newclasses | 7 | DIED | 14:55 | 76 | - | 2673 | 49 | - | 2 | 11:53 | 4 | 315 | 0 | 0 |
| castle_sanguis | newspells | 11 | DIED | 08:25 | 77 | - | 1290 | 30 | - | 0 | - | 1 | 151 | 0 | 0 |
| castle_sanguis | newspells | 3 | DIED | 08:24 | 56 | - | 1203 | 29 | - | 0 | - | 1 | 148 | 0 | 0 |
| castle_sanguis | newspells | 7 | WIN | 20:48 | 53 | 18:11 | 3958 | 63 | 18:12 | 5 | 10:24 | 8 | 723 | 0 | 0 |
| castle_sanguis | summon | 11 | WIN | 21:15 | 120 | - | 3804 | 57 | - | 1 | 09:28 | 4 | 708 | 0 | 0 |
| castle_sanguis | summon | 3 | WIN | 21:05 | 117 | 18:20 | 3935 | 62 | 18:20 | 2 | 13:38 | 6 | 787 | 0 | 0 |
| castle_sanguis | summon | 7 | WIN | 21:47 | 111 | 18:37 | 3982 | 63 | - | 3 | 09:47 | 6 | 946 | 0 | 0 |
| ravensmoor | army | 11 | WIN | 21:50 | 118 | 18:15 | 4015 | 58 | 20:03 | 3 | 08:51 | 7 | 654 | 0 | 0 |
| ravensmoor | army | 3 | WIN | 21:15 | 120 | 18:26 | 3872 | 58 | - | 1 | 13:48 | 4 | 564 | 0 | 0 |
| ravensmoor | army | 7 | WIN | 21:46 | 93 | 18:30 | 4021 | 59 | 20:16 | 3 | 15:40 | 6 | 650 | 0 | 0 |
| ravensmoor | evolve | 11 | WIN | 20:42 | 82 | 18:21 | 3968 | 58 | - | 4 | 08:00 | 7 | 501 | 0 | 0 |
| ravensmoor | evolve | 3 | WIN | 21:01 | 120 | 19:00 | 3995 | 58 | - | 4 | 08:01 | 7 | 531 | 0 | 0 |
| ravensmoor | evolve | 7 | WIN | 20:40 | 87 | 19:17 | 3918 | 58 | - | 3 | 08:59 | 6 | 482 | 0 | 0 |
| ravensmoor | newclasses | 11 | WIN | 20:31 | 11 | 18:09 | 3921 | 58 | 18:10 | 3 | 11:30 | 6 | 448 | 0 | 0 |
| ravensmoor | newclasses | 3 | WIN | 20:33 | 101 | 17:43 | 3942 | 58 | 17:44 | 3 | 11:09 | 6 | 467 | 0 | 0 |
| ravensmoor | newclasses | 7 | DIED | 15:55 | 11 | - | 2970 | 49 | - | 2 | 11:13 | 4 | 254 | 0 | 0 |
| ravensmoor | newspells | 11 | WIN | 20:42 | 90 | 17:34 | 3664 | 56 | - | 5 | 09:54 | 8 | 468 | 0 | 0 |
| ravensmoor | newspells | 3 | DIED | 08:31 | 116 | - | 1330 | 30 | - | 0 | - | 1 | 120 | 0 | 0 |
| ravensmoor | newspells | 7 | WIN | 20:40 | 44 | 18:42 | 3859 | 57 | 20:28 | 5 | 08:50 | 8 | 468 | 0 | 0 |
| ravensmoor | summon | 11 | WIN | 21:47 | 114 | 18:17 | 3991 | 58 | - | 2 | 12:03 | 5 | 653 | 0 | 0 |
| ravensmoor | summon | 3 | WIN | 21:57 | 120 | 18:27 | 3889 | 58 | - | 3 | 11:49 | 5 | 667 | 0 | 0 |
| ravensmoor | summon | 7 | WIN | 21:27 | 120 | 18:01 | 4050 | 59 | - | 3 | 10:24 | 6 | 604 | 0 | 0 |
| witchwood | army | 11 | WIN | 21:10 | 114 | 17:52 | 3908 | 64 | 17:41 | 2 | 08:59 | 5 | 647 | 0 | 0 |
| witchwood | army | 3 | WIN | 21:20 | 114 | 18:39 | 3873 | 63 | 19:33 | 2 | 15:32 | 5 | 676 | 0 | 0 |
| witchwood | army | 7 | WIN | 21:27 | 120 | 17:56 | 3918 | 64 | 17:58 | 2 | 12:38 | 4 | 700 | 0 | 0 |
| witchwood | evolve | 11 | DIED | 11:54 | 110 | - | 1995 | 40 | - | 1 | 08:00 | 2 | 185 | 0 | 0 |
| witchwood | evolve | 3 | WIN | 20:43 | 38 | 18:25 | 3889 | 65 | - | 4 | 08:00 | 7 | 560 | 0 | 0 |
| witchwood | evolve | 7 | WIN | 20:42 | 75 | 18:20 | 3876 | 63 | - | 4 | 08:01 | 7 | 557 | 0 | 0 |
| witchwood | newclasses | 11 | DIED | 11:43 | 49 | - | 1958 | 43 | - | 2 | 09:58 | 3 | 181 | 0 | 0 |
| witchwood | newclasses | 3 | WIN | 20:27 | 52 | 17:43 | 3835 | 63 | 16:35 | 4 | 10:58 | 7 | 510 | 0 | 0 |
| witchwood | newclasses | 7 | WIN | 20:37 | 85 | 17:49 | 3864 | 64 | 15:46 | 3 | 10:21 | 6 | 542 | 0 | 0 |
| witchwood | newspells | 11 | DIED | 08:29 | 76 | - | 1304 | 33 | - | 0 | - | 1 | 127 | 0 | 0 |
| witchwood | newspells | 3 | DIED | 09:16 | 39 | - | 1458 | 35 | - | 0 | - | 1 | 140 | 0 | 0 |
| witchwood | newspells | 7 | DIED | 08:00 | 1 | - | 1155 | 30 | - | 0 | - | 1 | 117 | 0 | 0 |
| witchwood | summon | 11 | DIED | 17:08 | 51 | - | 1604 | 37 | - | 0 | - | 2 | 220 | 0 | 0 |
| witchwood | summon | 3 | WIN | 21:17 | 80 | 18:12 | 3882 | 63 | 18:12 | 3 | 09:02 | 6 | 667 | 0 | 0 |
| witchwood | summon | 7 | WIN | 21:49 | 120 | 18:45 | 3921 | 63 | 19:27 | 2 | 10:14 | 6 | 768 | 0 | 0 |

Summary per stage and build (deaths before 0:00, boss kills, mean lowest HP, mean kills, mean Soul Ash):

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| castle_sanguis | ALL | 15 | 5 | 9 | 77 | 3377 | 621 |
| castle_sanguis | army | 3 | 0 | 3 | 78 | 3878 | 886 |
| castle_sanguis | evolve | 3 | 1 | 2 | 72 | 3719 | 620 |
| castle_sanguis | newclasses | 3 | 2 | 1 | 59 | 3232 | 443 |
| castle_sanguis | newspells | 3 | 2 | 1 | 62 | 2150 | 341 |
| castle_sanguis | summon | 3 | 0 | 2 | 116 | 3907 | 814 |
| ravensmoor | ALL | 15 | 2 | 13 | 90 | 3694 | 502 |
| ravensmoor | army | 3 | 0 | 3 | 110 | 3969 | 623 |
| ravensmoor | evolve | 3 | 0 | 3 | 96 | 3960 | 505 |
| ravensmoor | newclasses | 3 | 1 | 2 | 41 | 3611 | 390 |
| ravensmoor | newspells | 3 | 1 | 2 | 83 | 2951 | 352 |
| ravensmoor | summon | 3 | 0 | 3 | 118 | 3977 | 641 |
| witchwood | ALL | 15 | 6 | 9 | 75 | 2963 | 440 |
| witchwood | army | 3 | 0 | 3 | 116 | 3900 | 674 |
| witchwood | evolve | 3 | 1 | 2 | 74 | 3253 | 434 |
| witchwood | newclasses | 3 | 1 | 2 | 62 | 3219 | 411 |
| witchwood | newspells | 3 | 3 | 0 | 39 | 1306 | 128 |
| witchwood | summon | 3 | 1 | 2 | 84 | 3136 | 552 |
