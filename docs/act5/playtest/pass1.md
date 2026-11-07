# Act V playtest pass 1 (Oct 26, 2026)

All three Act V stages after the integration balance and the art review. Meta none (the control), `--mortal`, builds
army / evolve / summon / newclasses / newspells × seeds 3, 7, 11 (`docs/act4/tools/playtest_batch.sh`,
`playtest_report.py`). For reference, the Act IV finale (the Underworld, pass 3): 4/15 deaths, mean min HP 88.

| stage | deaths | boss slain | mean min HP |
|---|---|---|---|
| Burning Province (13) | 0/15 | 15/15 | 92 |
| Castle Kurogane (14) | 8/15 | 7/15 | 75 |
| Road to the Sun (15) | 1/15 | 11/15 | 95 |

Castle Kurogane deaths (all between 7:13 and 12:48 elapsed; the General of the Left arrives at 11:00):

| run | died at | top damage to the necromancer |
|---|---|---|
| army s3 | 11:56 | Teppo Gunner 166, Samurai 95, Kiba-musha 61 |
| evolve s7 | 12:48 | Teppo Gunner 199, Samurai 86, Kiba-musha 41 |
| newclasses s3 / s7 / s11 | 12:12 / 11:47 / 11:00 | Teppo Gunner 128–182, Kiba-musha 15–63 |
| newspells s11 | 7:13 | Teppo Gunner 235, Samurai 89 |
| summon s7 / s11 | 8:09 / 11:46 | Teppo Gunner 148–154, Samurai 107–186, Kiba-musha 35–112 |

What breaks the army on Kurogane: the cavalry charges. Top damage to summons on army s3 was Kiba-musha charges 8,450,
Samurai 5,437 and the General's charge 2,671; on army s7 the Oni 12,028, Kiba-musha charges 10,721 and the General's
charge 6,946. With the ring broken, the Teppo Gunners finish the necromancer.

The one Road to the Sun death (summon s11, 15:30): Teppo Gunner 566.

| stage | build | seed | result | ended | min_hp | boss | kills | level | build_done | evos | first_evo | chests | ash | errors | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| province | army | 11 | WIN | 21:20 | 116 | 18:03 | 4006 | 62 | 18:56 | 2 | 08:02 | 6 | 2484 | 0 | 0 |
| province | army | 3 | WIN | 21:33 | 100 | 18:00 | 4048 | 62 | 16:50 | 2 | 09:40 | 7 | 2620 | 0 | 0 |
| province | army | 7 | WIN | 21:27 | 115 | 18:03 | 4058 | 62 | 18:04 | 1 | 08:01 | 6 | 2564 | 0 | 0 |
| province | evolve | 11 | WIN | 20:54 | 109 | 17:53 | 4051 | 62 | - | 3 | 08:01 | 7 | 2228 | 0 | 0 |
| province | evolve | 3 | WIN | 20:49 | 70 | 17:53 | 4033 | 62 | - | 4 | 08:01 | 9 | 2180 | 0 | 0 |
| province | evolve | 7 | WIN | 21:06 | 99 | 18:26 | 4067 | 62 | - | 4 | 08:04 | 9 | 2352 | 0 | 0 |
| province | newclasses | 11 | WIN | 20:52 | 40 | 18:17 | 4036 | 62 | 15:57 | 4 | 12:48 | 9 | 2212 | 0 | 0 |
| province | newclasses | 3 | WIN | 21:03 | 18 | 18:22 | 4055 | 62 | 15:38 | 3 | 12:42 | 8 | 2320 | 0 | 0 |
| province | newclasses | 7 | WIN | 20:49 | 89 | 17:49 | 4022 | 62 | 16:31 | 3 | 08:00 | 7 | 2172 | 0 | 0 |
| province | newspells | 11 | WIN | 20:53 | 110 | 18:49 | 4037 | 62 | 16:17 | 4 | 08:02 | 9 | 2224 | 0 | 0 |
| province | newspells | 3 | WIN | 20:53 | 102 | 18:15 | 4049 | 61 | 16:51 | 5 | 08:37 | 11 | 2220 | 0 | 0 |
| province | newspells | 7 | WIN | 20:58 | 116 | 18:12 | 4055 | 62 | 18:02 | 5 | 08:45 | 11 | 2276 | 0 | 0 |
| province | summon | 11 | WIN | 21:28 | 91 | 18:08 | 4072 | 63 | - | 3 | 08:14 | 7 | 2572 | 0 | 0 |
| province | summon | 3 | WIN | 21:17 | 104 | 17:53 | 4079 | 62 | 16:41 | 3 | 10:42 | 8 | 2468 | 0 | 0 |
| province | summon | 7 | WIN | 21:25 | 97 | 18:01 | 4072 | 62 | - | 3 | 10:11 | 8 | 2544 | 0 | 0 |
| kurogane | army | 11 | WIN | 21:58 | 113 | 19:02 | 4368 | 68 | 14:21 | 2 | 12:28 | 11 | 3735 | 0 | 0 |
| kurogane | army | 3 | DIED | 11:56 | 102 | - | 2193 | 47 | - | 1 | 08:02 | 5 | 1079 | 0 | 0 |
| kurogane | army | 7 | WIN | 21:58 | 79 | 18:53 | 4367 | 68 | 14:48 | 2 | 08:01 | 9 | 4029 | 0 | 0 |
| kurogane | evolve | 11 | WIN | 20:50 | 52 | 19:26 | 4365 | 68 | - | 4 | 08:05 | 11 | 3332 | 0 | 0 |
| kurogane | evolve | 3 | WIN | 21:04 | 99 | 19:01 | 4411 | 68 | - | 3 | 08:17 | 13 | 3344 | 0 | 0 |
| kurogane | evolve | 7 | DIED | 12:48 | 89 | - | 2433 | 50 | - | 1 | 08:01 | 4 | 1258 | 0 | 0 |
| kurogane | newclasses | 11 | DIED | 11:00 | 25 | - | 1972 | 44 | - | 1 | 10:35 | 3 | 990 | 0 | 0 |
| kurogane | newclasses | 3 | DIED | 12:12 | 21 | - | 2282 | 49 | - | 2 | 09:28 | 7 | 1134 | 0 | 0 |
| kurogane | newclasses | 7 | DIED | 11:47 | 95 | - | 2172 | 47 | - | 2 | 09:16 | 5 | 1092 | 0 | 0 |
| kurogane | newspells | 11 | DIED | 07:13 | 46 | - | 589 | 22 | - | 0 | - | 1 | 369 | 0 | 0 |
| kurogane | newspells | 3 | WIN | 21:58 | 47 | 19:09 | 4382 | 68 | 13:57 | 4 | 08:00 | 14 | 3876 | 0 | 0 |
| kurogane | newspells | 7 | WIN | 21:24 | 86 | 19:13 | 4279 | 67 | 15:23 | 6 | 08:07 | 13 | 3536 | 0 | 0 |
| kurogane | summon | 11 | DIED | 11:46 | 116 | - | 2152 | 47 | - | 2 | 08:02 | 4 | 1020 | 0 | 0 |
| kurogane | summon | 3 | WIN | 22:15 | 120 | 19:15 | 4392 | 68 | 16:00 | 4 | 08:32 | 12 | 3973 | 0 | 0 |
| kurogane | summon | 7 | DIED | 08:09 | 33 | - | 1198 | 33 | - | 0 | - | 1 | 578 | 0 | 0 |
| sun_road | army | 11 | WIN | 21:17 | 102 | 18:28 | 3985 | 65 | 16:51 | 2 | 12:00 | 8 | 3033 | 0 | 0 |
| sun_road | army | 3 | WIN | 20:42 | 72 | - | 3903 | 61 | 16:30 | 1 | 09:49 | 7 | 2214 | 0 | 0 |
| sun_road | army | 7 | WIN | 21:01 | 113 | 18:52 | 3995 | 65 | 16:44 | 2 | 12:47 | 7 | 2700 | 0 | 0 |
| sun_road | evolve | 11 | WIN | 21:03 | 105 | 18:29 | 4036 | 65 | - | 3 | 08:00 | 8 | 2875 | 0 | 0 |
| sun_road | evolve | 3 | WIN | 20:55 | 95 | 19:06 | 3988 | 65 | - | 4 | 08:01 | 12 | 2830 | 0 | 0 |
| sun_road | evolve | 7 | WIN | 21:11 | 111 | 18:58 | 3962 | 64 | - | 3 | 08:01 | 9 | 2925 | 0 | 0 |
| sun_road | newclasses | 11 | WIN | 20:48 | 92 | 17:48 | 3974 | 64 | 16:10 | 3 | 09:19 | 6 | 2520 | 0 | 0 |
| sun_road | newclasses | 3 | WIN | 20:51 | 90 | 17:54 | 3994 | 64 | 14:59 | 3 | 10:49 | 9 | 2785 | 0 | 0 |
| sun_road | newclasses | 7 | WIN | 20:48 | 45 | 18:27 | 3975 | 64 | 15:04 | 5 | 10:11 | 11 | 2628 | 0 | 0 |
| sun_road | newspells | 11 | WIN | 20:58 | 115 | 19:03 | 3965 | 64 | 18:27 | 5 | 08:03 | 9 | 2673 | 0 | 0 |
| sun_road | newspells | 3 | WIN | 20:55 | 99 | 18:05 | 3992 | 63 | 17:11 | 5 | 10:06 | 10 | 2776 | 0 | 0 |
| sun_road | newspells | 7 | WIN | 20:48 | 115 | 18:17 | 3970 | 64 | 17:10 | 6 | 08:00 | 11 | 2835 | 0 | 0 |
| sun_road | summon | 11 | DIED | 15:30 | 48 | - | 704 | 22 | - | 0 | - | 0 | 688 | 0 | 0 |
| sun_road | summon | 3 | WIN | 21:25 | 105 | - | 3976 | 61 | 19:38 | 3 | 11:34 | 8 | 2722 | 0 | 0 |
| sun_road | summon | 7 | WIN | 21:24 | 113 | - | 3882 | 62 | 19:58 | 2 | 11:55 | 7 | 2601 | 0 | 0 |

Summary per stage and build (deaths before 0:00, boss kills, mean lowest HP, mean kills, mean Soul Ash):

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| kurogane | ALL | 15 | 8 | 7 | 75 | 3037 | 2223 |
| kurogane | army | 3 | 1 | 2 | 98 | 3643 | 2948 |
| kurogane | evolve | 3 | 1 | 2 | 80 | 3736 | 2645 |
| kurogane | newclasses | 3 | 3 | 0 | 47 | 2142 | 1072 |
| kurogane | newspells | 3 | 1 | 2 | 60 | 3083 | 2594 |
| kurogane | summon | 3 | 2 | 1 | 90 | 2581 | 1857 |
| province | ALL | 15 | 0 | 15 | 92 | 4049 | 2362 |
| province | army | 3 | 0 | 3 | 110 | 4037 | 2556 |
| province | evolve | 3 | 0 | 3 | 93 | 4050 | 2253 |
| province | newclasses | 3 | 0 | 3 | 49 | 4038 | 2235 |
| province | newspells | 3 | 0 | 3 | 109 | 4047 | 2240 |
| province | summon | 3 | 0 | 3 | 97 | 4074 | 2528 |
| sun_road | ALL | 15 | 1 | 11 | 95 | 3753 | 2587 |
| sun_road | army | 3 | 0 | 2 | 96 | 3961 | 2649 |
| sun_road | evolve | 3 | 0 | 3 | 104 | 3995 | 2877 |
| sun_road | newclasses | 3 | 0 | 3 | 76 | 3981 | 2644 |
| sun_road | newspells | 3 | 0 | 3 | 110 | 3976 | 2761 |
| sun_road | summon | 3 | 1 | 0 | 89 | 2854 | 2004 |
