# Synergies for the later classes: balance pass (Nov 2026)

Owner decisions and design: GDD §15.0 "Synergies for the later classes (owner decisions, Nov 2026)". Numbers live in
`scripts/data/synergy_data.gd`.

## Method

- Screens: `--policy=summon --mortal --unlocks=all --stage=crimson_march --classes=<pair>`; on versus `--synergies=off`.
- **Direct lift** = the synergy's bonus damage over the finisher's damage without it (the method of the newer classes'
  pair screens, GDD §15.0 "Synergies for the newer classes"). The A/B finisher-damage difference ("A/B") is reported
  too, but at these seed counts it is noise-dominated (the off runs also lose Deathless / Shieldwall, and the summon bot
  drafts other classes freely; medians from −6% to +88%).
- Round 1 (proposal numbers): 16 seeds for Pinned Down, Carrion Swarm, Winter's Edge (Cold Blood) and both capstones,
  8 for the rest. Round 2 (after the mechanical changes below): 8 seeds per changed pair. Round 3 (final bonuses,
  extrapolated linearly from round 2's mark coverage): 4 seeds per changed pair, as a check. Off runs: 4 seeds per pair.
  The compute budget (two usage cut-offs) kept the off and check rounds short.
- Target: about 8–12% direct per pair (the newer pairs measured 4–13%).

## Results

| Synergy | Final numbers | Direct lift: round 1 → 2 → final check | Notes |
|---|---|---|---|
| Pinned Down | pin 6 s (was 4), arrows +75% (was 40%) | 4.0% → 4.4% → **9.0%** | in target |
| Anchor and Stone | boulders +75% (was 50%) on held, aim +1.0 | 1.3% → 2.0% → **1.6%** | below target: stuns are rare and short |
| Broken Guard | warriors +75% (was 40%) on held | 0.6% → 1.1% → **1.6%** | below target: same reason |
| Searchlight | beams +75% (was 40%) on swooped, saucer aim +1.0 | 1.5% → 2.7% → **5.1%** | low end |
| Carrion Swarm | darts +75% (was 35%) on staggered, drone aim +1.0 | 2.3% → 4.6% → **5.0%** | low end |
| Fallen Choir | seraph +60% (was 40%) on weakened, seraph aim +1.0 | 5.0% → 6.6% → **8.9%** | in target |
| Black Ice | kegs +75% / +40% (was 60 / 30%) on frozen / chilled, aim +1.0 | 3.8% → 5.3% → **4.6%** | low end (few kegs a run) |
| Blood in the Water | blood spawn +75% (was 40%) on bleeding, aim +1.0 | 2.2% → 3.9% → **4.2%** | low end |
| Aegis of Tartarus | barriers 25% max HP / 5 s, wall + barrier capped at 70% | n/a (no hit bonus) | ~350 barriers a run, barrier absorption +26% vs off |
| Winter's Edge (Cold Blood) | unchanged (the Frost Wraith numbers) | **3.0%** (16 seeds) | the Draugr's chill uptime is low: no cap needed |
| Winter's Edge (Shatterfall) | unchanged | **2.0%** (8 seeds) | same |
| The Unhallowed Legion | +10% damage, specials 15% sooner | **9.4%** (16 seeds) | in target, unchanged |
| The Rain of Ruin | +10% damage, +10% attack speed | **8.7%** (16 seeds) | in target, unchanged |

Survival: no death before 0:00 in any screen run (summon bot, `--mortal`); Marshal Vael killed in about half the
summon-bot runs either way (the summon bot is weak on the March); no script error, `stuck_units=0` everywhere.

## Changes made in the pass (all `TUNING`)

1. **MARK_LINGER 3 s**: "held" lasts the stun plus 3 s (`Enemy.held_until`, written in `CombatResolver.stun_enemy()`,
   the one stun path, only while a held pair is active; every stun still counts) and "bleeding" the bleed plus 3 s.
2. **Finisher aim**: the drones, saucers, seraphs, powder wraiths and blood spawn of these pairs prefer marked foes
   (`aim_bonus` 1.0, `SynergyManager.aim_bonus()`, like Killing Field's catapult aim).
3. **Pinned 4 → 6 s** and the bonuses above, capped at Shatterfall's +75% (no new per-hit maximum).

## Open (for the owner's playtest)

- Anchor and Stone and Broken Guard stay well under target: "held" depends on how often foes are stunned (an Oni stuns
  one foe per 5.5 s, a Spawn grasps one per 7 s). Raising the bonus past +75% would make one hit absurd; a wider fix
  (the Oni stunning several foes, or held marking the smash's whole splash) is a class change, left to the owner.
- Searchlight, Carrion Swarm, Black Ice and Blood in the Water sit at 4–5%, the low end of the newer pairs' 4–13%.
