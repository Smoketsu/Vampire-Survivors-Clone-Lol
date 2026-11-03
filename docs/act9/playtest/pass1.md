# Act IX playtest pass 1

Nov 4, 2026. Meta none, `--mortal`, five builds x seeds 3, 7, 11 (`docs/act7/tools/playtest_round.sh`). Deaths /15: Crash Site 3, Proving Moon 1, the Ark 0 (the finale is the easiest stage: mean min HP 113, boss slain 14/15). Zero errors, `stuck_units=0`.

| stage | build | seed | result | ended | min_hp | boss | kills | level | build_done | evos | first_evo | chests | ash | errors | stuck |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ark | army | 11 | WIN | 21:27 | 119 | 18:24 | 3722 | 67 | 17:13 | 3 | 13:40 | 7 | 829 | 0 | 0 |
| ark | army | 3 | WIN | 21:19 | 115 | 18:03 | 3621 | 66 | 17:44 | 2 | 09:05 | 5 | 795 | 0 | 0 |
| ark | army | 7 | WIN | 21:11 | 120 | 18:42 | 3744 | 67 | 18:42 | 2 | 08:08 | 5 | 772 | 0 | 0 |
| ark | evolve | 11 | WIN | 21:13 | 120 | 19:05 | 3779 | 67 | - | 3 | 08:46 | 7 | 781 | 0 | 0 |
| ark | evolve | 3 | WIN | 21:01 | 113 | 18:41 | 3680 | 66 | - | 3 | 08:01 | 6 | 732 | 0 | 0 |
| ark | evolve | 7 | WIN | 21:09 | 117 | 18:43 | 3786 | 68 | - | 3 | 08:06 | 6 | 765 | 0 | 0 |
| ark | newclasses | 11 | WIN | 20:56 | 105 | 18:10 | 3743 | 66 | 15:38 | 4 | 11:20 | 8 | 717 | 0 | 0 |
| ark | newclasses | 3 | WIN | 20:47 | 115 | 19:12 | 3730 | 66 | 14:59 | 3 | 08:02 | 6 | 681 | 0 | 0 |
| ark | newclasses | 7 | WIN | 20:42 | 113 | 18:56 | 3693 | 66 | 15:13 | 3 | 08:01 | 6 | 660 | 0 | 0 |
| ark | newspells | 11 | WIN | 21:04 | 116 | 19:14 | 3799 | 68 | 17:38 | 5 | 08:00 | 8 | 747 | 0 | 0 |
| ark | newspells | 3 | WIN | 20:55 | 120 | 19:15 | 3745 | 66 | 17:50 | 5 | 08:04 | 8 | 714 | 0 | 0 |
| ark | newspells | 7 | WIN | 21:04 | 116 | 19:35 | 3787 | 67 | 17:02 | 4 | 08:30 | 7 | 747 | 0 | 0 |
| ark | summon | 11 | WIN | 21:03 | 73 | - | 2092 | 45 | - | 2 | 14:25 | 4 | 555 | 0 | 0 |
| ark | summon | 3 | WIN | 21:26 | 118 | 18:40 | 3751 | 67 | 18:41 | 3 | 08:00 | 6 | 828 | 0 | 0 |
| ark | summon | 7 | WIN | 21:18 | 120 | 18:43 | 3785 | 68 | 18:44 | 3 | 08:02 | 6 | 801 | 0 | 0 |
| crash_site | army | 11 | DIED | 16:40 | 59 | - | 2297 | 43 | - | 0 | - | 1 | 197 | 0 | 0 |
| crash_site | army | 3 | WIN | 20:57 | 68 | - | 3873 | 61 | 18:23 | 2 | 09:13 | 5 | 412 | 0 | 0 |
| crash_site | army | 7 | WIN | 21:18 | 120 | 18:30 | 4057 | 66 | 17:42 | 2 | 09:22 | 5 | 546 | 0 | 0 |
| crash_site | evolve | 11 | WIN | 21:06 | 115 | 18:41 | 4117 | 66 | - | 4 | 08:00 | 7 | 519 | 0 | 0 |
| crash_site | evolve | 3 | WIN | 21:07 | 111 | 18:38 | 4125 | 65 | - | 4 | 08:04 | 7 | 520 | 0 | 0 |
| crash_site | evolve | 7 | WIN | 20:57 | 92 | 18:43 | 4007 | 66 | - | 4 | 08:10 | 7 | 493 | 0 | 0 |
| crash_site | newclasses | 11 | DIED | 10:47 | 61 | - | 1836 | 42 | - | 1 | 09:03 | 2 | 135 | 0 | 0 |
| crash_site | newclasses | 3 | DIED | 11:05 | 10 | - | 1911 | 42 | - | 0 | - | 1 | 140 | 0 | 0 |
| crash_site | newclasses | 7 | WIN | 20:42 | 51 | 18:22 | 4011 | 66 | 15:00 | 3 | 10:38 | 6 | 455 | 0 | 0 |
| crash_site | newspells | 11 | WIN | 20:57 | 116 | 19:07 | 4076 | 64 | 17:52 | 5 | 09:08 | 8 | 495 | 0 | 0 |
| crash_site | newspells | 3 | WIN | 20:56 | 105 | 18:58 | 4083 | 65 | 17:45 | 6 | 08:28 | 9 | 493 | 0 | 0 |
| crash_site | newspells | 7 | WIN | 21:18 | 113 | 19:30 | 4224 | 67 | 16:29 | 4 | 08:33 | 8 | 551 | 0 | 0 |
| crash_site | summon | 11 | WIN | 21:17 | 116 | 18:32 | 3996 | 65 | - | 3 | 13:01 | 5 | 541 | 0 | 0 |
| crash_site | summon | 3 | WIN | 21:26 | 104 | 20:06 | 3965 | 65 | 19:45 | 2 | 11:35 | 5 | 563 | 0 | 0 |
| crash_site | summon | 7 | WIN | 21:18 | 116 | 18:24 | 4114 | 66 | 18:30 | 3 | 12:16 | 6 | 549 | 0 | 0 |
| proving_moon | army | 11 | WIN | 21:17 | 99 | 18:48 | 3808 | 63 | 19:28 | 1 | 08:54 | 4 | 671 | 0 | 0 |
| proving_moon | army | 3 | WIN | 21:10 | 113 | 18:41 | 3838 | 64 | 19:09 | 2 | 11:23 | 5 | 650 | 0 | 0 |
| proving_moon | army | 7 | WIN | 21:29 | 118 | 18:20 | 3844 | 64 | 18:04 | 2 | 13:43 | 6 | 710 | 0 | 0 |
| proving_moon | evolve | 11 | WIN | 21:11 | 112 | 18:41 | 3831 | 63 | - | 2 | 08:03 | 5 | 651 | 0 | 0 |
| proving_moon | evolve | 3 | WIN | 21:18 | 114 | 18:39 | 3860 | 64 | - | 3 | 09:50 | 5 | 673 | 0 | 0 |
| proving_moon | evolve | 7 | WIN | 21:07 | 118 | 18:53 | 3883 | 64 | - | 4 | 08:03 | 8 | 640 | 0 | 0 |
| proving_moon | newclasses | 11 | DIED | 13:10 | 13 | - | 2195 | 47 | - | 2 | 09:50 | 4 | 208 | 0 | 0 |
| proving_moon | newclasses | 3 | WIN | 20:56 | 78 | 18:27 | 3825 | 64 | 15:43 | 3 | 11:22 | 6 | 605 | 0 | 0 |
| proving_moon | newclasses | 7 | WIN | 20:41 | 30 | 18:07 | 3771 | 63 | 15:54 | 3 | 10:21 | 6 | 557 | 0 | 0 |
| proving_moon | newspells | 11 | WIN | 21:01 | 69 | 19:33 | 3850 | 64 | 17:18 | 5 | 08:38 | 8 | 621 | 0 | 0 |
| proving_moon | newspells | 3 | WIN | 20:57 | 56 | 19:29 | 3834 | 64 | 18:11 | 4 | 08:00 | 8 | 610 | 0 | 0 |
| proving_moon | newspells | 7 | WIN | 21:03 | 107 | 19:08 | 3900 | 66 | 17:42 | 5 | 08:22 | 8 | 630 | 0 | 0 |
| proving_moon | summon | 11 | WIN | 21:11 | 120 | 18:10 | 3836 | 64 | 20:47 | 3 | 10:16 | 6 | 652 | 0 | 0 |
| proving_moon | summon | 3 | WIN | 21:17 | 110 | 18:39 | 3822 | 63 | - | 2 | 08:06 | 5 | 670 | 0 | 0 |
| proving_moon | summon | 7 | WIN | 21:18 | 120 | 18:10 | 3834 | 65 | 21:07 | 3 | 12:09 | 5 | 673 | 0 | 0 |

Summary per stage and build (deaths before 0:00, boss kills, mean lowest HP, mean kills, mean Soul Ash):

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| ark | ALL | 15 | 0 | 14 | 113 | 3630 | 742 |
| ark | army | 3 | 0 | 3 | 118 | 3696 | 799 |
| ark | evolve | 3 | 0 | 3 | 117 | 3748 | 759 |
| ark | newclasses | 3 | 0 | 3 | 111 | 3722 | 686 |
| ark | newspells | 3 | 0 | 3 | 117 | 3777 | 736 |
| ark | summon | 3 | 0 | 2 | 104 | 3209 | 728 |
| crash_site | ALL | 15 | 3 | 11 | 90 | 3646 | 441 |
| crash_site | army | 3 | 1 | 1 | 82 | 3409 | 385 |
| crash_site | evolve | 3 | 0 | 3 | 106 | 4083 | 511 |
| crash_site | newclasses | 3 | 2 | 1 | 41 | 2586 | 243 |
| crash_site | newspells | 3 | 0 | 3 | 111 | 4128 | 513 |
| crash_site | summon | 3 | 0 | 3 | 112 | 4025 | 551 |
| proving_moon | ALL | 15 | 1 | 14 | 92 | 3729 | 615 |
| proving_moon | army | 3 | 0 | 3 | 110 | 3830 | 677 |
| proving_moon | evolve | 3 | 0 | 3 | 115 | 3858 | 655 |
| proving_moon | newclasses | 3 | 1 | 2 | 40 | 3264 | 457 |
| proving_moon | newspells | 3 | 0 | 3 | 77 | 3861 | 620 |
| proving_moon | summon | 3 | 0 | 3 | 117 | 3831 | 665 |
