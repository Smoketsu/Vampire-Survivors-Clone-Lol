# Ossuary expansion, step 1: the Soul Ash economy

Measured Oct 25, 2026 with `tools/ash_measure.py` (81 headless autotests, no `--meta-save`, so no real save was touched).
Raw data: `docs/ossuary/ash_runs.csv` (one row per run), `docs/ossuary/ash_table.md` (the generated table).
Owner decision: GDD §15.0 "Ossuary expansion: owner decisions" and "Soul Ash per act and difficulty".

## 1. How a run's Soul Ash is combined (`Meta.compute_ash()`)

One **subtotal** is built from the run itself: time (7.5 / min, max 20 min) + kills (0.03 each) + elites (4 each) + boss (75)
+ Reckoning seconds (2.5 each, capped at 180 s) + stage objectives (Sanctum chambers / altars, Wastes pylons, ...). Every
percentage then pays **its own floored line on that same subtotal, and the lines ADD**. Nothing multiplies another:

    total = subtotal
          + floor(subtotal x Ash Harvest)         (Ossuary, +5% / tier, max +15%; "mid" meta = +10%)
          + floor(subtotal x (stage mult - 1))    (stage_ash_mult from the stage definition, never below 0)
          + floor(subtotal x (difficulty mult - 1))   (Initiate is the only negative line, -20%)
          + floor(subtotal x run modifiers)       (sum of the active modifiers' rewards, up to +125%)
          + floor(subtotal x Hyper)               (+100%)
          + floor(subtotal x Pact) + floor(subtotal x Oath)
          (the one-time achievement bounty is paid separately, on top, and is not in these totals)

So the effective multiplier is `1 + Harvest + (stage - 1) + (difficulty - 1) + modifiers + Hyper + Pact + Oath`.
Examples: Deathlord on the Sanctum = 1 + 0.5 + 1.0 = x2.5; Deathlord + Hyper on the Sanctum with +10% Harvest =
1 + 0.1 + 0.5 + 1.0 + 1.0 = **x3.6** (not 2 x 2 x 1.5 = 6). The setup screen's "Soul Ash xN" total is
`difficulty mult + modifiers (+ Hyper)` and leaves the stage, Harvest, Pact and Oath lines out; that code reads the data, so
it follows the new numbers (Deathlord x2, all eight modifiers x3.25).

## 2. Multipliers, before and after (data only: gameplay is unchanged)

| Stage | Before | After |
|---|---|---|
| Graveyard (Act I, 1) | x1.0 | x1.0 |
| Crimson March (Act I, 2) | x1.25 | x1.25 |
| Sanctum of Judgment (Act I, 3) | x1.5 | x1.5 |
| Gullhaven Harbour (Act II, 1) | x1.75 | **x1.0** |
| Hollow Archive (Act II, 2) | x2.0 | **x1.25** |
| Ul-Thalos (Act II, 3) | x2.25 | **x1.5** |
| Scrap Wastes (Act III, 1) | x2.5 | **x1.0** |
| Assembly Halls (Act III, 2) | x2.75 | **x1.25** |
| Iron Citadel (Act III, 3) | x3.0 | **x1.5** |

| Difficulty | Before | After |
|---|---|---|
| Initiate | x0.8 | x0.8 |
| Necromancer | x1.0 | x1.0 |
| Lich | x1.25 | **x1.5** |
| Deathlord | x1.5 | **x2.0** |
| Hyper (extra line) | +100% | +100% |

## 3. What runs pay now

Army bot, `--meta=mid` (Ash Harvest +10%), `--mortal`, seeds 1 and 2; median of the two (before in brackets, computed from the
same runs with the old multipliers). Naive: `--policy=naive --meta=none`, seed 1, Necromancer, one run per stage.

| Stage | Necromancer | Lich | Deathlord | Deathlord + Hyper | Naive lower bound |
|---|---|---|---|---|---|
| Graveyard | 591 (592) | 870 (734) | 1,398 (1,066) | 1,359* (1,140) | 273 |
| Crimson March | 685 (686) | 921 (796) | 1,505 (1,184) | 2,166 (1,842) | 601 |
| Sanctum | 1,064 (1,064) | 1,371 (1,208) | 2,127 (1,718) | 2,742 (2,361) | 129 |
| Gullhaven Harbour | 532 (896) | 766 (1,006) | 1,344 (1,504) | 1,963 (2,121) | 268 |
| Hollow Archive | 822 (1,280) | 1,084 (1,378) | 1,766 (1,954) | 2,330* (2,504) | 373 |
| Ul-Thalos | 984 (1,446) | 1,256 (1,554) | 2,166 (2,374) | 2,389* (2,555) | 304 |
| Scrap Wastes | 758 (1,794) | 1,076 (1,918) | 1,762 (2,602) | 2,069 (2,736) | 149 |
| Assembly Halls | 972 (2,054) | 1,325 (2,222) | 1,963 (2,799) | 875* (1,136) | 176 |
| Iron Citadel | 1,482 (2,873) | 1,880 (3,000) | 2,857 (3,956) | 2,267* (2,898) | 559 |
| **Mean of the nine** | **877** (1,409) | **1,172** (1,535) | **1,877** (2,128) | **2,018** (2,144) | **315** (489) |

\* A median that includes bot deaths (see "odd" below). The army bot reached 0:00 in 18/18 Necromancer, 18/18 Lich and 18/18
Deathlord runs, but only 11/18 Deathlord + Hyper runs. The 11 Hyper runs that survived paid 2,276 on average (1,900-2,900 on
every stage that had a survivor; Assembly and Citadel had none). Hyper clears are limited by the bot, not by the economy, so read them as a floor.

## 4. Runs to max everything at today's cost (9,635 + Oath 375 = 10,010)

Using the stage-average payouts above (a strong run on a stage the player has open; achievement bounties, about 2,900 once in all,
would save one or two runs):

| Player | Per run | Runs to max 10,010 | Before this change |
|---|---|---|---|
| (a) Necromancer, plays up through the acts | ~880 | **~11** (about 32 if every run is a weak, naive-style 315) | ~7 |
| (b) Deathlord | ~1,880 | **~5** | ~5 |
| (c) Deathlord + Hyper | ~2,000 (2,280 when the run survives) | **~4-5** | ~4-5 |

A player who parks on the Iron Citadel at Necromancer (1,482) maxes in ~7 runs; on Deathlord (2,857) in ~4. The old cost is
spent in one evening at any difficulty, which is the owner's complaint. The new multipliers do not change that by themselves:
they cut Act II/III Necromancer pay by up to half and raise Deathlord pay ~2.1x over Necromancer (it was ~1.5x), so difficulty is
now the bigger lever, but the **cost** has to grow.

## 5. Recommended total cost of the new Ossuary

Target "about 60-100 good runs to max everything for a player who works up through the acts": at ~880 Soul Ash per Necromancer run
(~800 for a typical human run) that is 48,000-88,000. **Recommend a total of about 65,000 Soul Ash for everything (existing 10,010
+ roughly 55,000 of new content: tiers 6-10, the Dominion tree and options, Masteries, Relic slots, Offerings).**

| Player | Runs to 65,000 |
|---|---|
| Necromancer, up through the acts | ~74 (~80 at 800 a run) |
| Lich | ~55 |
| Deathlord | ~35 (47% of the Necromancer count: "roughly half") |
| Deathlord + Hyper | ~29 when the run survives |

Keep expensive items (Offerings) in this total. The three levers if it feels off after playtests: scale all new costs together
(one `COST_SCALE`-style factor in the new data), the Deathlord/Necromancer ratio (the difficulty multipliers), or the Reckoning
second rate. Re-run `python3 tools/ash_measure.py` (about 3 h for the full set at 2 processes; `--only NAIVE` is ~30 min) after
any balance pass that changes kills, elites or Reckoning length, because those drive the subtotal. `--meta=max` was not measured;
expect payouts roughly 5-10% higher than the mid profile once the new tiers are bought.

## 6. Odd findings

* **The raw subtotal differs a lot by stage**, so equal multipliers do not mean equal pay (Necromancer, army bot): Harbour 485,
  Crimson March 509, Graveyard 539, Archive 610, Spire 616, Sanctum 666, Wastes 690, Assembly 721, **Citadel 927**. Act III pays
  ~1.3-1.7x Act I per run before any multiplier, from more kills and elites and a longer Reckoning (40-55 s against 20-35 s). The
  Citadel is still the best farm (1,482 on Necromancer, 2.5x the Graveyard) even after the reset; Harbour pays *less* than the
  Graveyard at the same x1.0 and less than the March (532 against 591 and 685).
* **Hyper adds exactly one more subtotal** (+100%), not a doubling of everything, so Deathlord + Hyper is only ~1.5x Deathlord
  on a surviving run; the army bot's Hyper deaths (Assembly x2, Citadel x2, Graveyard, Archive, Ul-Thalos) make the Hyper medians
  look worse than Deathlord on Assembly and Citadel. Ash from a run that dies is smaller (no boss 75, no Reckoning).
* The Reckoning pays up to 180 s x 2.5 = 450 but runs ended 11-55 s past 0:00, so it is only ~30-140 per run.
* Boss ash (75) is missing in 7 of the 67 runs that reached 0:00 (five Deathlord + Hyper, Assembly Deathlord seed 2, the naive Harbour run): the boss was not killed in time.
* The naive bot pays 315 on average (Sanctum 129: it died at 6:57), 36% lower than before; weak players now progress slower, which
  matches "work up through the acts".
* No run had a SCRIPT ERROR / ERROR / WARNING line and every run had `stuck_units=0`.
