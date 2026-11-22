# The Necropolis Dynasty: balance pass 1

Bot playtest at meta none, `--mortal`, seeds 3 / 7 / 11, six builds per stage (flags as
`docs/act7/tools/playtest_round.sh`, naive = no `--policy`). Target: the final slot VII (Shogunate /
Olympus level). Pass 1 logs `pass1_logs/`, table `pass1_report.md`; pass 2 logs `pass2_logs/`, table
`pass2_report.md`.

## Pass 1 (died / boss slain / mean min HP before 0:00)

| stage | army | evolve | summon | newclasses | newspells | naive |
|---|---|---|---|---|---|---|
| necropolis | 0/3/115 | 0/3/104 | 0/3/120 | 0/3/99 | 0/3/98 | 2/0/42 |
| lioness_temple | 0/3/95 | 0/3/118 | 1/2/96 | 0/3/99 | 0/3/115 | 2/0/94 |
| two_truths | 0/2/100 | 0/1/78 | 1/2/116 | 2/1/102 | 0/2/108 | 2/0/80 |

The Necropolis and the Lioness Temple are on target and were left alone. The Hall of Two Truths has
its problem in the boss fight (Osiris, then Ammit).

## The three boss deaths

- **summon s7** (died 18:56): full 120 HP at 18:00; the necromancer took 176 from the boss, Ammit's
  charge 151 of it (4 charges, ~38 a charge at that time scaling) and the Judgment 25.
- **newclasses s3** (died 17:32): the Judgment 95 (5 Judgments, ~32-40 a hit), before the Weighing.
- **newclasses s7** (died 17:56): the Judgment 122 (8 Judgments); the Weighing was not reached.

A single Judgment or charge strikes the necromancer only once (the Judgment is a one-shot circle;
the charge keeps a struck set per run), so the bursts were the per-hit numbers: three Judgments or
three to four charges took a full-HP necromancer down. The fight was also long: Osiris was slain
before 0:00 in only 8 of 18 runs (army 2/3, evolve 1/3); after the 60 s Weighing (about 17:30-18:30)
Ammit has about 90 s left for the last 41% of the pool.

## Changes (`scripts/data/osiris_data.gd`, BOSS)

| key | old | new |
|---|---|---|
| `judgment_damage` (to the necromancer) | 14 | 8 |
| `charge_damage` (to the necromancer) | 22 | 12 |
| `max_hp` | 13,000 | 11,500 |

The summon-side damage (`judgment_summon_damage` 12, `charge_summon_damage` 40) is unchanged.

## Pass 2 (Hall of Two Truths only)

| build | died | boss slain | mean min HP |
|---|---|---|---|
| army | 0 | 1 | 113 |
| evolve | 0 | 0 | 98 |
| summon | 0 | 0 | 118 |
| newclasses | 0 | 1 | 82 |
| newspells | 0 | 3 | 111 |
| naive | 2 | 1 | 80 |

No boss deaths left (the two naive deaths are at 13:44 / 14:50, before the boss, identical to pass 1).
Every run: 0 `SCRIPT ERROR` / `ERROR:` / `WARNING:`, `stuck_units=0`. The bursts are fixed (largest
boss total on the necromancer 155, newspells s3, survived; newclasses s3 Judgment 129 over the fight,
min HP 44). The boss is still often alive at 0:00 (6 of 18 slain, pass 1 8 of 18): the HP trim
brought several close (150, 216, 1,493 HP left) but the Devourer phase is where the time goes. Open
for the owner: a larger HP cut (~9,500), a lower `weighing_hp` so more of the pool falls to the Judge
before the Weighing, or a shorter Weighing (60 s is from the owner-approved proposal).

## Pass 3: the Weighing earlier (owner's choice)

The owner picked option 2: begin the Weighing at a lower HP share; `weighing_time` stays 60 s and
`max_hp` 11,500. Pass 2 phase rates: the Judge lost his 34% (about 6,060 of 17,824 scaled HP) in
28-37 s, about 180 HP/s; Ammit lost 30-80 HP/s. So the pool moves to the Judge.

| key | old | new |
|---|---|---|
| `weighing_hp` | 0.66 | 0.30 |

Ammit's share is now 5% of the pool after a won Weighing (the shield break takes 25%), 30% after a lost one.
Logs `pass3_logs/`, table `pass3_report.md`.

| build | died | boss slain | mean min HP |
|---|---|---|---|
| army | 0 | 3 | 116 |
| evolve | 0 | 3 | 98 |
| summon | 0 | 3 | 120 |
| newclasses | 0 | 3 | 65 |
| newspells | 0 | 3 | 117 |
| naive | 2 | 1 | 80 |

16 of 18 slain before 0:00; the two left are the naive deaths at 13:44 / 14:50 (before the boss,
unchanged), so every run that met Osiris killed him. Every run: 0 `SCRIPT ERROR` / `ERROR:` /
`WARNING:`, `stuck_units=0`. Every Weighing begins before 0:00 (17:23-18:08; newspells s3 18:54) and
was won; the boss falls 85-132 s after arriving (newspells s3: 195 s, at 20:15, after 0:00). The
Judge sped up as more of the pool became his (70% in 40-55 s), so **Ammit now lives only about
5-10 s**: no charge reached the necromancer in pass 3. The longer Judge phase means more Judgments:
newclasses took 100-138 from them (lowest HP 29 on s3). If the owner wants a real Devourer phase, a
value between (0.35-0.40) keeps her about 15-30 s.
