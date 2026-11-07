# Act VI playtest pass 2 (Pandemonium)

Date: Oct 31, 2026.

Change under test: Pandemonium's Hell Pits deal 40% less damage to summons (`dps_summon` 9 → 5.4,
`scripts/data/stages/pandemonium_stage.gd`). Batch: `docs/act4/tools/playtest_batch.sh` on stage
`pandemonium`, five builds (army, evolve, summon, newclasses, newspells) × seeds 3, 7, 11, all `--mortal`
(15 runs). Logs are kept in the session scratchpad, not in the repo.

## Summary

| Stage / pass | Runs | Deaths before 0:00 | Boss slain | Mean min HP before 0:00 |
|---|---|---|---|---|
| Pandemonium pass 2 (this batch) | 15 | 9/15 | 5/15 | 77 |
| Pandemonium pass 1 (reference) | 15 | 9/15 | 4/15 | 69 |
| Burning Gate (reference) | 15 | 2/15 | 13/15 | 90 |
| Palace (reference) | 15 | 2/15 | 11/15 | 84 |

Errors: 0 `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines across all 15 logs. `stuck_units=0` in every run.
Exit codes: the 9 runs that died before 0:00 exit 1; the 6 runs that reached 0:00 exit 0.

## Deaths (runs that did not reach 0:00)

Top 3 sources from each run's stats line (`player_dmg_from_<x>` = damage to the necromancer,
`summon_dmg_from_<x>` = damage dealt to the army by each source).

| Build | Seed | Died at | Top 3 player_dmg_from | Top 3 summon_dmg_from | summon_dmg_from_hell_pit |
|---|---|---|---|---|---|
| army | 11 | 18:59 | imp=119, hell_knight=91, seraph_general=68 | hell_knight=19173, hell_pit=12475, fallen_angel_dive=7184 | 12475 |
| army | 7 | 17:56 | demon_brute=91, imp=49, morning_star_dark=47 | hell_knight=5969, fallen_angel_dive=4762, demon_brute=4715 | 2103 |
| evolve | 11 | 18:05 | morning_star_light=126, seraph_general=43, morning_star_dark=37 | hell_pit=8086, demon_brute=4676, fallen_angel_dive=2580 | 8086 |
| evolve | 3 | 13:47 | demon_brute=90, seraph_general=35, seraph_cleave=35 | hell_pit=2667, seraph_cleave=2405, fallen_angel_dive=1371 | 2667 |
| evolve | 7 | 18:10 | morning_star_light=126, fallen_angel_dive=88, boss=48 | hell_pit=6999, demon_brute=5332, fallen_angel_dive=2141 | 6999 |
| newclasses | 11 | 17:40 | morning_star_light=82, hell_knight=81, damned=76 | hell_pit=21148, hell_knight=20949, demon_brute=9463 | 21148 |
| newclasses | 3 | 17:28 | hell_knight=63, morning_star_light=54, morning_star_dark=50 | hell_knight=15633, hell_pit=11019, demon_brute=5920 | 11019 |
| newclasses | 7 | 18:18 | hell_knight=114, demon_brute=87, morning_star_dark=76 | hell_pit=32676, hell_knight=20663, demon_brute=7834 | 32676 |
| summon | 7 | 18:23 | hell_knight=245, morning_star_dark=132, imp=129 | hell_knight=23234, hell_pit=11923, fallen_angel_dive=8320 | 11923 |

## Hell Pit summon damage, every run

| Build | Seed | Result | summon_dmg_from_hell_pit |
|---|---|---|---|
| army | 3 | reached 0:00 | 5974 |
| army | 7 | died 17:56 | 2103 |
| army | 11 | died 18:59 | 12475 |
| evolve | 3 | died 13:47 | 2667 |
| evolve | 7 | died 18:10 | 6999 |
| evolve | 11 | died 18:05 | 8086 |
| newclasses | 3 | died 17:28 | 11019 |
| newclasses | 7 | died 18:18 | 32676 |
| newclasses | 11 | died 17:40 | 21148 |
| newspells | 3 | reached 0:00 | 1813 |
| newspells | 7 | reached 0:00 | 1372 |
| newspells | 11 | reached 0:00 | 2555 |
| summon | 3 | reached 0:00 | 21145 |
| summon | 7 | died 18:23 | 11923 |
| summon | 11 | reached 0:00 | 22450 |

## Full report output

`python3 docs/act4/tools/playtest_report.py <outdir>/pandemonium`

| stage | build | seed | result | ended | min_hp | boss | kills | level | build_done | evos | first_evo | chests | ash | errors | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| pandemonium | army | 11 | DIED | 18:59 | 75 | - | 3647 | 55 | - | 1 | 13:43 | 4 | 585 | 0 | 0 |
| pandemonium | army | 3 | WIN | 20:21 | 48 | - | 2877 | 42 | - | 0 | - | 0 | 435 | 0 | 0 |
| pandemonium | army | 7 | DIED | 17:56 | 96 | - | 3449 | 56 | - | 1 | 10:17 | 3 | 624 | 0 | 0 |
| pandemonium | evolve | 11 | DIED | 18:05 | 57 | - | 3486 | 56 | - | 4 | 08:03 | 6 | 387 | 0 | 0 |
| pandemonium | evolve | 3 | DIED | 13:47 | 120 | - | 2474 | 46 | - | 1 | 08:01 | 2 | 294 | 0 | 0 |
| pandemonium | evolve | 7 | DIED | 18:10 | 47 | - | 3458 | 56 | - | 4 | 08:46 | 6 | 387 | 0 | 0 |
| pandemonium | newclasses | 11 | DIED | 17:40 | 76 | - | 3452 | 55 | 16:48 | 2 | 12:39 | 4 | 561 | 0 | 0 |
| pandemonium | newclasses | 3 | DIED | 17:28 | 75 | - | 3328 | 55 | 16:53 | 4 | 09:19 | 6 | 403 | 0 | 0 |
| pandemonium | newclasses | 7 | DIED | 18:18 | 33 | - | 3529 | 56 | 16:59 | 3 | 10:33 | 5 | 421 | 0 | 0 |
| pandemonium | newspells | 11 | WIN | 20:49 | 59 | 18:47 | 3992 | 62 | 18:58 | 5 | 09:21 | 6 | 729 | 0 | 0 |
| pandemonium | newspells | 3 | WIN | 21:05 | 72 | 19:38 | 4251 | 62 | 19:40 | 5 | 08:38 | 8 | 801 | 0 | 0 |
| pandemonium | newspells | 7 | WIN | 20:49 | 120 | 19:32 | 4276 | 64 | 18:48 | 5 | 09:42 | 8 | 744 | 0 | 0 |
| pandemonium | summon | 11 | WIN | 21:48 | 116 | 19:02 | 4136 | 62 | - | 2 | 11:17 | 5 | 1380 | 0 | 0 |
| pandemonium | summon | 3 | WIN | 21:36 | 112 | 18:48 | 4138 | 63 | 19:38 | 3 | 08:12 | 6 | 1003 | 0 | 0 |
| pandemonium | summon | 7 | DIED | 18:23 | 46 | - | 3208 | 50 | - | 2 | 09:07 | 4 | 499 | 0 | 0 |

Summary per stage and build (deaths before 0:00, boss kills, mean lowest HP, mean kills, mean Soul Ash):

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| pandemonium | ALL | 15 | 9 | 5 | 77 | 3580 | 617 |
| pandemonium | army | 3 | 2 | 0 | 73 | 3324 | 548 |
| pandemonium | evolve | 3 | 3 | 0 | 75 | 3139 | 356 |
| pandemonium | newclasses | 3 | 3 | 0 | 61 | 3436 | 462 |
| pandemonium | newspells | 3 | 0 | 3 | 84 | 4173 | 758 |
| pandemonium | summon | 3 | 1 | 2 | 91 | 3827 | 961 |
