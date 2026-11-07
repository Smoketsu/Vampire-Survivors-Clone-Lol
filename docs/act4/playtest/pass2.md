# Act IV playtest pass 2 (Oct 25, 2026)

The Underworld only, after the owner's pass 1 decision: `ENEMY_DAMAGE_MULT` 1.25 → 1.5. Meta none (the control), `--mortal`,
the same five builds × seeds 3, 7, 11 as pass 1 (`docs/act4/tools/playtest_batch.sh`, `playtest_report.py`).

| run set | deaths | mean min HP | mean player damage taken | mean summon damage taken | mean ash |
|---|---|---|---|---|---|
| Underworld pass 1 (×1.25) | 0/15 | 104 | 345 | 31553 | 3220 |
| Underworld pass 2 (×1.5) | 0/15 | 101 | 317 | 36547 | 3062 |
| Citadel (pass 1) | 4/15 | 78 | 1042 | 18592 | 2333 |
| Ilion (pass 1) | 1/15 | 102 | 320 | 40411 | 2888 |
| Olympus (pass 1) | 4/15 | 88 | 639 | 38757 | 3589 |

Reading: the damage step reached the army (+16% summon damage taken) but not the necromancer. Almost nothing reaches
the player in the Underworld: no ranged kinds, and the army body-blocks the melee shades. The Citadel (Line of Fire
shots) and Olympus (Centaur Archers) hurt the player through range. The closest run (evolve s3, min HP 19) dropped in the
Hades fight; its player damage came from Heroes 92, wrath fissures 64, Hades 46, god shades 43, wrath lightning 36.

| stage | build | seed | result | ended | min_hp | boss | kills | level | build_done | evos | first_evo | chests | ash | errors | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| underworld | army | 11 | WIN | 20:43 | 111 | 18:40 | 4879 | 63 | 15:29 | 2 | 16:50 | 13 | 3318 | 0 | 0 |
| underworld | army | 3 | WIN | 20:40 | 120 | 17:58 | 4842 | 63 | 15:44 | 2 | 10:33 | 14 | 3116 | 0 | 0 |
| underworld | army | 7 | WIN | 20:39 | 117 | 18:28 | 4907 | 63 | 17:05 | 3 | 08:32 | 10 | 2951 | 0 | 0 |
| underworld | evolve | 11 | WIN | 20:37 | 112 | 19:09 | 4919 | 63 | - | 4 | 08:02 | 12 | 2745 | 0 | 0 |
| underworld | evolve | 3 | WIN | 20:05 | 19 | 19:08 | 4855 | 63 | - | 4 | 08:00 | 13 | 3060 | 0 | 0 |
| underworld | evolve | 7 | WIN | 20:42 | 112 | 18:39 | 4966 | 64 | - | 3 | 11:05 | 11 | 3266 | 0 | 0 |
| underworld | newclasses | 11 | WIN | 20:38 | 80 | 18:05 | 4866 | 63 | 14:15 | 3 | 10:35 | 11 | 2910 | 0 | 0 |
| underworld | newclasses | 3 | WIN | 20:29 | 117 | 17:49 | 4884 | 63 | 14:23 | 3 | 10:54 | 13 | 2790 | 0 | 0 |
| underworld | newclasses | 7 | WIN | 20:43 | 79 | 18:02 | 4876 | 63 | 15:40 | 3 | 11:58 | 8 | 3195 | 0 | 0 |
| underworld | newspells | 11 | WIN | 20:43 | 118 | 18:22 | 4931 | 62 | 16:31 | 4 | 08:02 | 12 | 3217 | 0 | 0 |
| underworld | newspells | 3 | WIN | 20:24 | 78 | 18:46 | 4889 | 63 | 15:43 | 5 | 09:29 | 13 | 2958 | 0 | 0 |
| underworld | newspells | 7 | WIN | 20:45 | 103 | 18:52 | 4993 | 63 | 16:39 | 5 | 08:32 | 9 | 3303 | 0 | 0 |
| underworld | summon | 11 | WIN | 20:58 | 112 | 17:56 | 4977 | 63 | 17:57 | 3 | 13:39 | 10 | 3097 | 0 | 0 |
| underworld | summon | 3 | WIN | 20:48 | 120 | 18:07 | 4945 | 63 | 17:56 | 4 | 08:01 | 14 | 2906 | 0 | 0 |
| underworld | summon | 7 | WIN | 21:01 | 120 | 18:12 | 5000 | 63 | 18:07 | 3 | 12:31 | 11 | 3097 | 0 | 0 |

Summary per stage and build (deaths before 0:00, boss kills, mean lowest HP, mean kills, mean Soul Ash):

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| underworld | ALL | 15 | 0 | 15 | 101 | 4915 | 3062 |
| underworld | army | 3 | 0 | 3 | 116 | 4876 | 3128 |
| underworld | evolve | 3 | 0 | 3 | 81 | 4913 | 3024 |
| underworld | newclasses | 3 | 0 | 3 | 92 | 4875 | 2965 |
| underworld | newspells | 3 | 0 | 3 | 100 | 4938 | 3159 |
| underworld | summon | 3 | 0 | 3 | 117 | 4974 | 3033 |
