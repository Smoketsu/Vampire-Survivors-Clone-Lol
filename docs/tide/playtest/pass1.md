# The Black Tide: balance pass 1 (the Smuggler's Cutter)

Bot playtest, meta none, `--mortal`, seeds 3 / 7 / 11, builds as `docs/act7/tools/playtest_round.sh` (naive = no
`--policy`). Report tool `python3 docs/act4/tools/playtest_report.py <dir>`. GDD §15.0 "The Black Tide balance pass 1
(the Cutter)".

## Pass 1 (before): all three stages

Full table `pass1_report.md`, logs `pass1_logs/`.

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| cutter | army | 3 | 0 | 3 | 114 | 3621 | 514 |
| cutter | evolve | 3 | 2 | 1 | 78 | 2869 | 321 |
| cutter | naive | 3 | 3 | 0 | 70 | 2066 | 150 |
| cutter | newclasses | 3 | 0 | 3 | 114 | 3618 | 509 |
| cutter | newspells | 3 | 3 | 0 | 116 | 2179 | 168 |
| cutter | summon | 3 | 0 | 3 | 116 | 3829 | 527 |
| galleon | army | 3 | 0 | 3 | 103 | 5780 | 742 |
| galleon | evolve | 3 | 0 | 3 | 94 | 5246 | 665 |
| galleon | naive | 3 | 2 | 1 | 67 | 3146 | 319 |
| galleon | newclasses | 3 | 0 | 3 | 94 | 5537 | 692 |
| galleon | newspells | 3 | 0 | 3 | 114 | 5326 | 722 |
| galleon | summon | 3 | 0 | 3 | 114 | 5771 | 795 |
| maelstrom | army | 3 | 0 | 3 | 108 | 5728 | 895 |
| maelstrom | evolve | 3 | 0 | 3 | 115 | 5533 | 847 |
| maelstrom | naive | 3 | 2 | 1 | 35 | 3294 | 418 |
| maelstrom | newclasses | 3 | 0 | 3 | 87 | 5436 | 820 |
| maelstrom | newspells | 3 | 0 | 3 | 100 | 5509 | 871 |
| maelstrom | summon | 3 | 0 | 3 | 114 | 5649 | 887 |

**The problem: the act's FIRST stage was its hardest** (8 deaths of 18 against 2 on each later stage). Every Cutter
death came at one of the stage's two set pieces, never from the trickle:

- **11:00-12:10, Bosun Gorran** (the ram longboat at 11:00): newspells s3 / s7 died at 11:35 with ~120 damage from
  Gorran alone (`bosun gorran: ... dmg to you 121-123`, 4 chain sweeps, the necromancer in reach with 2 Warriors);
  the three naive runs died 11:34-12:07 after his ram and escort cut their army (naive s11 15 -> 2 summons in the
  11:00 window; s7 `bosun_gorran=720` summon damage in one window).
- **17:30-18:40, Captain Crow's Duel**: evolve s11 / s3 and newspells s11 died with 95-144 `boss` (cutlass) damage.
- **The root under both: the spell builds were starved of XP.** On the 960 x 360 deck their area spells cut the
  boats' grapple hooks inside the 3 s empty window (`first_pour`), and a repelled boat's crew is cancelled (no XP):
  cutter evolve s3 collected 3,620 XP (2,020 crew cancelled, 1,712 aboard) against the Galleon's 9,437; level 35 at
  17:00 against 57 on the Galleon. The stage's lower spawn rate (2.9-3.7 a second from 5:00, the Galleon 3.9-4.8)
  kept enemies alive at 6-23.
- Gorran's and the Cutter's numbers are Cutter-only (`cutter_enemy_data.gd`, `crow_data.gd`, `cutter_stage.gd`);
  no shared corsair kind was touched.

## Changes (all `# TUNING (not in GDD)`)

| file | value | old -> new | why |
|---|---|---|---|
| `scripts/data/cutter_enemy_data.gd` | Bosun Gorran `damage` (chain-hook) | 9 -> 6 | his ~120 to the necromancer |
| `scripts/data/cutter_enemy_data.gd` | Bosun Gorran `sweep_damage_player` | 8 -> 4 | the same; his summon damage unchanged |
| `scripts/data/stages/cutter_stage.gd` | `ENEMY_DAMAGE_MULT` | 1.15 -> 1.0 | the act's first stage (the Galleon 1.2, the Maelstrom 1.25); also the boss |
| `scripts/data/stages/cutter_stage.gd` | BOARDING `first_pour` | 3.0 -> 1.5 s | fewer crews cancelled in the empty window (XP); Not One Aboard still earnable |
| `scripts/data/crow_data.gd` | Crow `damage` (cutlass) | 9 -> 7 | his Duel killed the spell builds |
| `scripts/data/crow_data.gd` | Crow `attack_interval` | 0.9 -> 1.2 s | cutlass 10 -> 5.8 dps base, below Marrec's 9.1 (the act's first boss) |
| `scripts/data/stages/cutter_stage.gd` | SEGMENTS `rate` from 5:00 / 10:00 / 15:00 | 2.9 / 3.4 / 3.7 -> 3.3 / 3.9 / 4.3 | more XP for spell builds; `max_alive` unchanged |

Iteration 1 was the first four rows (logs `pass2_iter1/`); iteration 2 added the last three.

### Iteration 1 (Gorran, damage ×1.0, first pour 1.5 s)

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| cutter | evolve | 3 | 0 | 3 | 52 | 3383 | 470 |
| cutter | naive | 3 | 1 | 2 | 68 | 4170 | 385 |
| cutter | newspells | 3 | 3 | 0 | 105 | 2787 | 220 |

Gorran stopped killing anyone (2-48 damage to the necromancer). Newspells now died at 17:42-17:55 instead, all in
Crow's Duel (`boss` 111-137): still XP-short (level 44 at 17:50).

## Pass 2 (after both iterations): the Cutter

Full table `pass2_report.md`, logs `pass2_logs/`. 0 `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines and `stuck_units=0`
in all 15 runs (exit 1 = a death under `--mortal`).

| stage | build | runs | died | boss slain | mean min HP | mean kills | mean ash |
|---|---|---|---|---|---|---|---|
| cutter | army | 3 | 0 | 3 | 118 | 4086 | 563 |
| cutter | evolve | 3 | 1 | 2 | 98 | 3253 | 405 |
| cutter | naive | 3 | 1 | 2 | 51 | 3887 | 404 |
| cutter | newspells | 3 | 2 | 1 | 63 | 3100 | 312 |
| cutter | summon | 3 | 0 | 3 | 116 | 4143 | 561 |

- **Deaths 8/15 -> 4/15** on the builds compared (evolve 2 -> 1, newspells 3 -> 2, naive 3 -> 1); army and summon
  still 0 deaths, min HP 118 / 116. Gorran now deals 0-83 to the necromancer.
- **Left over: newspells 2/3** (target 0-1), both in Crow's Duel (17:34, 18:27; `boss` 110-127 and his pistol 42-221
  on s7), at level 47-49 (the Galleon's newspells: 54 at 17:00). The forced four-spell build has two Warriors to
  body-block on the smallest deck. Two iterations were the budget; the next levers, if the owner wants one: Crow's
  `pistol_damage` 7 (the s7 death) or letting a repelled boat's crew drop some XP (code, `BoardingParty`).
- Naive mean min HP 51 (one death at 13:08 to the deck pressure after Gorran); Soul Ash for winners 440-563; Gorran is now slain in all 15 runs.
