# The Celestial Host: balance pass 1

Bot playtest of the three Host stages (temporary Act XIII; tuned for the final slot X, at or just above the Inferno).
Meta none, `--mortal`, seeds 3 / 7 / 11; build flags as in `docs/act7/tools/playtest_round.sh` (naive = no `--policy`).
Logs: pass 1 `pass1_logs/` (report `pass1_report.md`), pass 2 `pass2_logs/` (report `pass2_report.md`), the first
tuning iteration `pass2_iter/` (newclasses only; the second iteration's newclasses runs are the ones in `pass2_logs/`).

## Pass 1 (before the changes)

Cells are: died before 0:00 (of 3) / boss slain / mean lowest HP (the report's metric samples).

| build | silver_stair | wheel_of_thrones | empyrean |
|---|---|---|---|
| army | 0 / 3 / 111 | 0 / 3 / 99 | 0 / 2 / 91 |
| evolve | 2 / 1 / 77 | 0 / 3 / 90 | 0 / 2 / 94 |
| summon | 0 / 2 / 91 | 0 / 2 / 88 | 0 / 3 / 99 |
| newclasses | 3 / 0 / 32 | 3 / 0 / 52 | 3 / 0 / 77 |
| newspells | 1 / 2 / 81 | 1 / 1 / 55 | 1 / 2 / 81 |
| naive | 1 / 0 / 82 | 1 / 0 / 69 | 1 / 0 / 51 |

## Why it killed

The `host kinds` line lists only enemy kinds, so the Virtue looked like the top killer everywhere. The full
`player_dmg_from_*` stats tell two stories:

- **newclasses (9 of 9 deaths): Hallowed Light, not the Virtue.** The Light is the top damage to the necromancer in
  all nine (139-513, the Virtue 20-238), and it melts the ring first: 23k-100k Light damage to summons a run
  (army 10k-23k), 450-620 summons lost (army 150-360), the Light the top killer of Rogues and Frost Wraiths. The reason
  is the barriers: the army and summon builds field Warders, and a barrier blocks a burn (`light_blocked` about 5,000 a
  run); `--classes=abomination,rogue,gargoyle,frost_wraith` has no priest, so every shaft sweeping through the Bone Ring
  (it starts 540 px out and crosses the necromancer) burns every summon about twice. The ring empties, then the Light
  and the Virtues reach the necromancer. Grace is not the cause: one free hit per class per halo is a small tax, and
  the halos are as many in the winning army runs (about 12,000 shrugged off) as in the losing newclasses ones.
- **newspells / evolve / naive: the Virtue.** With no ring to speak of, the Virtue is the top source (up to 503).
  It is the bulk soldier (1,000-1,300 a run) and hit harder than its Inferno counterpart: 6 damage / 1.2 s = 5.0 dps
  against the Inferno soldier's 5.5 / 1.3 s = 4.2 dps (that one was cut from 6.5 in its own pass 1). Its reach
  (10 px, plain melee) and kit (nothing beyond the halo) are not the problem.

## Changes (old -> new)

| file | value | pass 1 | iteration 1 | final |
|---|---|---|---|---|
| `scripts/data/host_enemy_data.gd` | Virtue `damage` | 6.0 | 5.0 | **5.0** (4.2 dps, the Inferno soldier's) |
| `scripts/data/host_rules_data.gd` | `LIGHT.summon_burn` | 7.0 | 5.0 | **3.5** (half) |
| `scripts/data/host_rules_data.gd` | `LIGHT.player_burn` | 4.0 | 3.0 | **2.5** |

Iteration 1 left newclasses at 7 of 9 deaths (the Light still about 45k on summons a run); iteration 2 brought it to 4
of 9. No stage damage multiplier, Grace or kit was touched.

## Pass 2 (after the changes)

| build | silver_stair | wheel_of_thrones | empyrean |
|---|---|---|---|
| army | 0 / 3 / 113 | 0 / 2 / 107 | 0 / 2 / 88 |
| evolve | 2 / 1 / 84 | 1 / 2 / 42 | 1 / 1 / 79 |
| newclasses | 2 / 1 / 82 | 1 / 2 / 70 | 1 / 2 / 33 |
| newspells | 1 / 2 / 100 | 2 / 1 / 66 | 0 / 3 / 90 |
| naive | 0 / 0 / 78 | 2 / 0 / 71 | 1 / 0 / 67 |

All 45 runs (and the 9 iteration runs): zero `SCRIPT ERROR` / `ERROR:` / `WARNING:`, `stuck_units=0`.

Non-naive deaths (army, evolve, newclasses, newspells): silver_stair 5, wheel_of_thrones 4, empyrean 2 (pass 1: 6 / 4 /
4); newclasses 9 -> 4. Army stays at 0 deaths. Naive is 3 of 9 overall, as before (0 / 2 / 1 across the stages).

## Still open

- **The goal is not fully met:** silver_stair evolve and newclasses are 2 of 3, wheel_of_thrones newspells 2 of 3.
  Almost every remaining death before 0:00 falls at 17:20-18:30 (the boss fight), and in the evolve / newspells ones
  the Virtue is again the top source (199-452). A third iteration (beyond this pass's two) would be the Virtue's
  `max_hp` 40 -> 36 or `attack_interval` 1.2 -> 1.3, or the bosses' arrival pressure.
- Army mean lowest HP is 88 on the Empyrean (target 90+, pass 1 91); the Empyrean army seed 7 and the Wheel army seed 3
  did not slay the boss.
- Three seeds per cell is a small sample: the same build moves by a death between seeds after any change.
