# Act VI playtest pass 3 (Pandemonium)

Date: Nov 2, 2026.

Change under test (owner: "Tone down the Morning Star", `scripts/data/morning_star_data.gd`): light / dark beam
damage -30% (`light_damage_player` 12 -> 8.4, `light_damage_summon` 11 -> 7.7, `dark_damage_player` 11 -> 7.7,
`dark_damage_summon` 13 -> 9.1), Beast slam damage -25% (`slam_damage_player` 16 -> 12, `slam_damage_summon`
18 -> 13.5), base HP -15% (`max_hp` 14000 -> 11900). Batch: `docs/act4/tools/playtest_batch.sh` commands on stage
`pandemonium`, five builds (army, evolve, summon, newclasses, newspells) × seeds 3, 7, 11, all `--mortal`
(15 runs). Logs are kept in the session scratchpad, not in the repo.

## Summary

| Stage / pass | Runs | Deaths before 0:00 | Boss slain | Mean min HP before 0:00 |
|---|---|---|---|---|
| Pandemonium pass 3 (this batch) | 15 | 4/15 | 10/15 | 79 |
| Pandemonium pass 2 (reference) | 15 | 9/15 | 5/15 | 77 |
| Burning Gate (reference) | 15 | 2/15 | 13/15 | 90 |
| Palace (reference) | 15 | 2/15 | 11/15 | 84 |

Errors: 0 `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines across all 15 logs (and 0 from `--import`). `stuck_units=0` in
every run. Exit codes: the 4 runs that died before 0:00 exit 1; the other 11 exit 0. By build: newclasses 0 deaths,
newspells 0, army 1, evolve 2, summon 1.

## Deaths (runs that did not reach 0:00)

| Build | Seed | Died at | Top 3 player_dmg_from | Top 3 summon_dmg_from |
|---|---|---|---|---|
| army | 7 | 17:47 | fallen_angel_dive=53, boss=36, seraph_feathers=28 | hell_knight=5838, demon_brute=4908, fallen_angel_dive=4428 |
| evolve | 3 | 13:47 | demon_brute=90, seraph_general=35, seraph_cleave=35 | hell_pit=2667, seraph_cleave=2405, fallen_angel_dive=1371 |
| evolve | 7 | 18:09 | fallen_angel_dive=119, boss=48, demon_brute=39 | hell_pit=7081, demon_brute=5355, fallen_angel_dive=2214 |
| summon | 7 | 19:30 | hell_knight=304, imp=167, morning_star_dark=162 | hell_knight=25049, hell_pit=13828, fallen_angel_dive=9314 |

None of the four deaths is mainly the Morning Star's beams or slam any more (only the summon seed 7 run has
`morning_star_dark` in its top 3, third); the rest come from Fallen Angel dives, Demon Brutes and Hell Knights.
The evolve seed 3 death (13:47) is identical to pass 2 and happens before the boss.

## Full report output

`python3 docs/act4/tools/playtest_report.py <outdir>/pandemonium`

| stage | build | seed | result | ended | min_hp | boss | kills | level | build_done | evos | first_evo | chests | ash | errors | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| pandemonium | army | 11 | WIN | 21:08 | 75 | 18:49 | 4087 | 62 | 18:59 | 2 | 13:43 | 5 | 1105 | 0 | 0 |
| pandemonium | army | 3 | WIN | 20:56 | 48 | - | 2888 | 43 | - | 0 | - | 1 | 565 | 0 | 0 |
| pandemonium | army | 7 | DIED | 17:47 | 96 | - | 3431 | 56 | - | 1 | 10:17 | 3 | 621 | 0 | 0 |
| pandemonium | evolve | 11 | WIN | 20:31 | 85 | 18:46 | 4010 | 62 | - | 4 | 08:03 | 7 | 663 | 0 | 0 |
| pandemonium | evolve | 3 | DIED | 13:47 | 120 | - | 2474 | 46 | - | 1 | 08:01 | 2 | 294 | 0 | 0 |
| pandemonium | evolve | 7 | DIED | 18:09 | 18 | - | 3446 | 56 | - | 3 | 08:46 | 5 | 387 | 0 | 0 |
| pandemonium | newclasses | 11 | WIN | 20:33 | 76 | 18:13 | 4060 | 63 | 16:48 | 2 | 12:39 | 5 | 943 | 0 | 0 |
| pandemonium | newclasses | 3 | WIN | 20:39 | 75 | 17:51 | 3994 | 62 | 16:53 | 4 | 09:19 | 7 | 750 | 0 | 0 |
| pandemonium | newclasses | 7 | WIN | 20:36 | 59 | 18:47 | 4019 | 62 | 16:59 | 3 | 10:33 | 6 | 771 | 0 | 0 |
| pandemonium | newspells | 11 | WIN | 20:55 | 79 | 18:50 | 3964 | 62 | 18:55 | 5 | 09:21 | 6 | 750 | 0 | 0 |
| pandemonium | newspells | 3 | WIN | 21:02 | 74 | 18:38 | 4252 | 63 | 18:34 | 5 | 08:38 | 8 | 792 | 0 | 0 |
| pandemonium | newspells | 7 | WIN | 20:48 | 117 | 18:17 | 4236 | 64 | 18:21 | 5 | 09:42 | 8 | 736 | 0 | 0 |
| pandemonium | summon | 11 | WIN | 21:26 | 116 | 18:55 | 4114 | 62 | - | 2 | 11:17 | 5 | 1206 | 0 | 0 |
| pandemonium | summon | 3 | WIN | 21:46 | 112 | 18:23 | 4167 | 63 | 19:32 | 4 | 08:12 | 7 | 1041 | 0 | 0 |
| pandemonium | summon | 7 | DIED | 19:30 | 29 | - | 3404 | 51 | - | 2 | 09:07 | 4 | 522 | 0 | 0 |

Summary per stage and build:

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| pandemonium | ALL | 15 | 4 | 10 | 79 | 3770 | 743 |
| pandemonium | army | 3 | 1 | 1 | 73 | 3469 | 764 |
| pandemonium | evolve | 3 | 2 | 1 | 74 | 3310 | 448 |
| pandemonium | newclasses | 3 | 0 | 3 | 70 | 4024 | 821 |
| pandemonium | newspells | 3 | 0 | 3 | 90 | 4151 | 759 |
| pandemonium | summon | 3 | 1 | 2 | 86 | 3895 | 923 |
