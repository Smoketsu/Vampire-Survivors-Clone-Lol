# Wiring plan for the missing-art round effects

**Status: wired (Nov 2026, GDD §15.0 "Missing art round wired").** Sections 1, 4 and 5 and the Cursed Coin are all drawn
(`PantheonFx` / `PantheonFxData`, the spells' and kits' own draw code), each with its code drawing kept as the fallback.
Small departures from the plan: the arcs and the fissure telegraph repeat their tile at 1:1 along the line (the telegraph
grows uniformly, so its pixels stay square), the chevron art points -x (turned half round past the heading), the bolt
column comes down from its top, and the Cursed Coin draws a white
disc over its art for the hit flash.

All art is drawn by `art_source/missing_art/make_missing_art.py` (deterministic; `manifest.json` beside it lists every
PNG with its size and frame count). Everything is true pixel art on the art grid: draw 1 art px = 1 layout px, through
the sharp-pixel path (`SpriteBank.apply_sharp()`), never stretched. Keep each code drawing as the fallback when the PNG is
missing. Obstacles, markers (`scribe_curse`, `inscription`), the passive icon and achievement badges and the 23 decals
need NO wiring: they sit at keys that `EnvironmentArt` / `SpriteBank` / the icon path already ask for.

Follow the `EmpireFx` pattern (`scripts/fx/empire_fx.gd`, `scripts/data/empire_fx_data.gd`): a new `PantheonFx` helper
(`scripts/fx/pantheon_fx.gd`) and `PantheonFxData` (keys and numbers). Alphas are baked into the PNGs (stepped), so draw
with `Color.WHITE` unless a fade is noted.

## 1. Divine Wrath (`scripts/enemies/pantheon/divine_wrath.gd`, `_draw()`) — **done**

| Key | Size (art px) | Use |
|---|---|---|
| `pantheon_fx/edge`, `edge_tick` | 10 x 6, row 0 outside, hit edge on row 3 | Warning band: tile at 1:1 along any telegraph line or circle edge (every 2nd piece the `_tick`), like `EmpireFx` `EDGE` / `EDGE_TICK`. |
| `pantheon_fx/chevron` | 13 x 13, points +x | Wave telegraph: replaces the two marble chevron lines; place at `line_c + perp * s + dir * (14 + 30k)`, rotate by `dir.angle()`. |
| `pantheon_fx/fill` | 16 x 16 seamless | Danger fill inside the bolt circle, laid as clipped 2 px rows (as `EmpireFx` hex); full colour at `FILL_ALPHA` 0.5, 0.22 over the whole area. |
| `pantheon_fx/target` | 15 x 15 | Bolt circle centre (replaces the 4 cross lines), only if radius >= 26. |
| `pantheon_fx/wave_front` | 24 x 16, tiles along x, advancing edge = bottom row (foam edge ~ row 13) | The wave front. Rotate so art-down points along `dir`; tile along `perp` from `-half` to `+half`; put row 13 on `o + dir * f`. Replaces the 5 px line and the 2 px marble line. |
| `pantheon_fx/wave_body` | 32 x 32 seamless | Water behind the front, from `back` to `f - 16`, clipped to the wall's rectangle in the wave's rotated frame, scrolled along `dir` by `t * speed` (like `EmpireFx.belt()`). Replaces the two translucent polygons. |
| `pantheon_fx/bolt_column` | 16 x 96, base on the bottom row, stepped alpha | In the last 28% of a bolt's telegraph (`k > 0.72`) stand it on `at`, rising up 96 px (clip from the top by `(k - 0.72) / 0.28`), as `EmpireFx` `UPLINK`. |
| `effects/wrath_strike` | 8 frames of 96 x 96 (strip 768 x 96), additive off; the shock ring ends at 0.84 of the half = 40 px | On a bolt's landing (`_land_bolt`): `EffectManager.impact(at, "wrath_strike")`-style, scale = `radius / 40` (44 px radius -> x1.1, "fill 1.1" like `empire_blast`), 0.4 s at the AnimData rate; add the `anim_data.gd` row `wrath_strike: frames 8`. |
| `pantheon_fx/arc_thin` (20 x 9), `arc_thick` (20 x 13) | seamless along x, bolt line on the middle row | Chain flashes (`flashes`: `arc_thin` -> `arc_thick`): scale along x to `a.distance_to(b)` (no more than x3 stretch per tile: tile it repeating otherwise), rotate by `(b - a).angle()`, fade with `modulate.a`. Replaces the 6-segment zigzag lines. |
| `pantheon_fx/fissure_warn` | 12 x 6, tiles along x | Fissure telegraph: tile along a -> b (rotated), height scales 1 -> 3x by `k` as the current crimson line grows; blink alpha as now. |
| `pantheon_fx/fissure_body`, `fissure_cap` | 16 x 22 tile, 10 x 22 left cap (flip for the right) | Open fissure (opening 18 px = `width`, centre row 11): cap at `a`, tiles between, flipped cap at `b`, all rotated by `(b - a).angle()`. Replaces the 3 lines. |

## 4. Act-spell effects — **done**

- **Stolen Thunder** (`scripts/abilities/spells/stolen_thunder.gd` `_draw()`): arcs use `pantheon_fx/arc_thin` (ground arc) and
  `arc_thick` (`arc.sky`), same drawing as the chain flash above, fade by `fade`. Charge orb: `pantheon_fx/thunder_orb`, 4 frames of
  16 x 16 (strip 64 x 16), frame = `min(3, int(k * 4))`, centred on `caster_pos() + (0, -ORB_LIFT)`, drawn at 1:1.
- **Paris's Arrow** (`paris_arrow.gd` `_draw()`): `projectiles/paris_arrow` 20 x 7, art points +x, **pivot = the arrow's `pos`
  at art x 17** (head tip at x 19: draw the rect at `pos - 17 * dir` rotated by `dir.angle()`), 1:1, no shadow, via
  `SpriteBank.draw_flat()` with the key (add `FLAT_SIZES`). Trail: `aoe/paris_trail` 24 x 5, drawn from the oldest `trail` point
  to `pos`, stretched along its length (one rect per `trail` segment, bright end at the arrow). The code `GLOW` / `CORE` colours
  (violet) match the art.
- **River Styx** (`river_styx.gd` `_draw()`): `pantheon_fx/styx_water` (base) or `lethe_water` (`evolved`), 32 x 32 seamless, laid as
  clipped rows over the oriented rectangle `a2 -> b2`, width `2r`, scrolled along the river by `now * 30` px (replaces the black line,
  the current line and the drift ticks); drawn at modulate alpha `fade`. Banks: `styx_bank` / `lethe_bank`, 16 x 4 (row 0 outside),
  tile along each long edge, flipped vertically on the far side. Fill: reveal from the middle as now (`fill`).
- **Linen Bind** (`linen_bind.gd` `_draw()`): per marked enemy `spell_fx/linen_wrap_s` (16), `_m` (24) or `_l` (36), the one nearest
  `2 * e.radius`, centred on the enemy, `Color(1, 1, 1, alpha)`; replaces the 3 rects. Tether lines (`_lines`, a -> b):
  `spell_fx/linen_strand` 16 x 4, tiled along the line, rotated, alpha `k`.
- Death Ray fallback: not made (`EmpireFx.death_ray` already has art, the fallback never shows).

## 5. Holmgang ring (`scripts/enemies/norse/holmgang.gd` `_draw()`) — **done**

- Posts: `norse/holmgang_post` 8 x 16, **pivot = bottom centre** (feet at the rod position `p`, art x 4, y 15), replaces the 3 x 11 rect and
  leaf rect; draw sorted by y.
- Rope: `norse/holmgang_rope` 16 x 3 (tile along x) for the top / bottom sides, `holmgang_rope_v` 3 x 16 for the left / right sides,
  laid where the code puts the 1 px rope lines (7 px above the ground line), at 1:1.
- Ground: `norse/holmgang_ground` 32 x 32 seamless, tiled over the square under `GROUND_TINT` (draw at modulate alpha 0.8 so
  it replaces the flat gold rect; keep the code tint at lower alpha if the square must still read).

## Also (not a wired effect, optional) — **done**

- Cursed Coin: `corsair/cursed_coin` (14 x 14 still) and `corsair/cursed_coin_spin` (4 frames of 14 x 14: face, 3/4, edge, 3/4
  mirrored). `CursedCoinKit.draw_body()` has no texture lookup: add one with `SpriteBank.draw_flat_frame(ci, key, 4, frame, Vector2.ZERO, 0.0)`
  (frame from `e.game.elapsed * 6`), keep the lantern glow disc in code, and keep the code disc as the fallback.
