# RS Effect Catalog

Everything you can pick from when building an affix. Say
*"use explosion 1, plasma 6, and the near-explosion sound"* and this is the
list that means.

Sprites live in `sprites/combatfx/<category>/`, sounds in
`sounds/combatfx/<category>/`. Same category name on both sides.

---

## Explosions — `RSE0`–`RSE9`

| Pick | Frames | What it is |
|---|---|---|
| `RSE0` | 26 | Big rocket fireball. The longest, fullest blast in the set. |
| `RSE1` | 25 | Second large blast, different look to RSE0. |
| `RSE2` | 1 | Single-frame rocket burst. Cheap, use for small hits. |
| `RSE3` | 6 | BFG detonation. |
| `RSE4` | 4 | BFG secondary flare. |
| `RSE5` | 1 | Single generic pop. |
| `RSE6` | 3 | Short blast (was the explosive-death affix). |
| `RSE7` | 3 | Short blast, alternate (was the explosive affix). |
| `RSE8` | 5 | Fragmentation burst. |
| `RSE9` | 8 | GunstarHeroes BFG green explosion (source: BFGB). Pairs with `RSF7` (shockwave) and `RSR5` (the ball itself). |

## Fire — `RSI0`–`RSI6`

| Pick | Frames | What it is |
|---|---|---|
| `RSI0` | 19 | Long fire plume. |
| `RSI1` | 13 | Medium fire. |
| `RSI2` | 10 | Short fire. |
| `RSI3` | 8 | Burning flame (was the fire affix). |
| `RSI4` | 8 | GunstarHeroes Unmaker fire burst (source: EXPL). |
| `RSI5` + `RSI6` | 26 + 5 | GunstarHeroes flung flame particle (source: FRFX), shared by the Unmaker and the Flamethrower. One continuous 16-frame sequence (each source frame held ~2 tics) split across two sprite names because a single sprite can't hold more than 26 letters — `RSI5` is frames 1–26, `RSI6` continues at 27–31. |

## Smoke — `RSK0`–`RSK2`

| Pick | Frames | What it is |
|---|---|---|
| `RSK0` | 17 | Standard smoke puff. |
| `RSK1` | 18 | Second smoke variant. |
| `RSK2` | 11 | Shorter, thinner smoke. |

## Plasma — `RSP0`–`RSP7`

| Pick | Frames | What it is |
|---|---|---|
| `RSP0` | 2 | Plasma bolt in flight. |
| `RSP1` | 5 | Plasma bolt impact. |
| `RSP2` | 2 | Second bolt in flight. |
| `RSP3` | 5 | Second bolt impact. |
| `RSP4` | 1 | Single plasma flare. |
| `RSP5` | 6 | Plasma ball, larger. |
| `RSP6` | 13 | Big plasma detonation. |
| `RSP7` | 5 | GunstarHeroes plasma ball (source: PBAL). Distinct rounder look from RSP0/RSP2. |

## Lightning — `RSL0`–`RSL2`

| Pick | Frames | What it is |
|---|---|---|
| `RSL0` | 11 | Lightning flash. |
| `RSL1` | 25 | Long arc / travelling bolt. |
| `RSL2` | 13 | Thunder strike. |

## Acid / Poison

| Pick | Frames | What it is |
|---|---|---|
| `RSA0` | 5 | Acid splash. |
| `RSN0` | 5 | Poison cloud. |

## Projectiles — `RSR0`–`RSR6`

| Pick | Frames | What it is |
|---|---|---|
| `RSR0` | 1 | Rocket in flight. |
| `RSR1` | 2 | BFG ball in flight. |
| `RSR2` | 4 | Bomblet / submunition. |
| `RSR4` | 1 | (pre-existing, unidentified — not part of the GunstarHeroes import) |
| `RSR5` | 2 | GunstarHeroes BFG ball in flight (source: BFS1). Distinct from RSR1 — this is the round the GH BFG9000/BFG10k actually fire. |
| `RSR6` | 1 (5 rotation angles) | GunstarHeroes railgun beam core segment (source: TRAC). Single frame with 8-angle billboard rotation art, not an animation. |
| `RSB0` | 5 | Bullet round in flight. The only real bullet visual -- every bullet weapon in both sets shares this one. |

## Puffs (wall/flesh hit marks) — `RSU0`–`RSU4`

| Pick | Frames | What it is |
|---|---|---|
| `RSU0` | 4 | Standard bullet puff. |
| `RSU1` | 4 | Second puff variant. |
| `RSU2` | 4 | Third puff variant. |
| `RSU3` | 8 | Longer particle burst. |
| `RSU4` | 4 | Frag puff. |

## Sparks & Flares

| Pick | Frames | What it is |
|---|---|---|
| `RSS0` | 5 | Spark shower. |
| `RSS1` | 1 | Single spark. |
| `RSS2` | 2 | GunstarHeroes impact spark flash (source: SPKS). Used by the railgun/rail-adjacent impacts. |
| `RSF0`–`RSF6` | 1 each | Coloured glow dots — blue, green, red, and four more. Use for light bloom on a projectile. |
| `RSF7` | 18 | GunstarHeroes BFG green shockwave ring (source: SHOK). Pairs with `RSE9` (explosion) and `RSR5` (the ball). |
| `RSF8` | 1 | GunstarHeroes thin laser sliver (source: LEYS, frame R only — the only frame the source code actually uses). Used for the railgun's coil trail and the Unmaker's bolt trail/laser. |

## Casings & Magazines

| Pick | Frames | What it is |
|---|---|---|
| `RSC0` | 5 | Small casing (pistol). |
| `RSC1` | 5 | Rifle casing. |
| `RSC2` | 5 | Shotgun hull. |
| `RSM0` | 8 | Rifle magazine. |
| `RSM1` | 1 | Small pistol clip. |
| `RSM2` | 5 | Energy cell pack. |
| `RSM3` | 8 | Rocket pack. |

---

# Sounds

Each one is a group — the game picks a random take each time, so it doesn't
sound repetitive.

| Pick | Takes | What it is |
|---|---|---|
| `rs_fx_explode_near` | 3 | Close explosion. |
| `rs_fx_explode_dist` | 5 | Distant explosion rumble. |
| `rs_fx_plasma_explode` | 3 | Plasma detonation. |
| `rs_fx_bfg_explode` | 4 | BFG detonation. |
| `rs_fx_impact_bullet` | 10 | Bullet hitting something. |
| `rs_fx_ricochet` | 7 | Bullet ricochet. |
| `rs_fx_casing_pistol` | 3 | Small casing hitting floor. |
| `rs_fx_casing_rifle` | 3 | Rifle casing hitting floor. |
| `rs_fx_casing_chaingun` | 3 | Chaingun casing. |
| `rs_fx_casing_shell` | 3 | Shotgun hull hitting floor. |
| `rs_fx_magdrop_small` | 3 | Small mag hitting floor. |
| `rs_fx_magdrop_large` | 3 | Large mag hitting floor. |
| `rs_fx_magdrop_bfg` | 3 | Cell pack hitting floor. |
| `rs_fx_saw_wall` | 3 | Chainsaw grinding on wall. |
| `rs_fx_foley` | 5 | Generic weapon handling. |
| `rs_fx_holster` | 3 | Putting a weapon away. |

Single sounds (not groups): `rs_fx_weapon_empty` (dry click),
`rs_fx_rocket_explode`, `rs_fx_weapdraw`, `rs_fx_weaponup`.

---

## Reading a name

`RSE3` = **RS** project, **E**xplosion category, set **3**.
The letter after it in code (`RSE3 A`, `RSE3 B`…) is the animation frame.

| Letter | Category |
|---|---|
| A | Acid |
| B | Bullet round |
| C | Casing |
| E | Explosion |
| F | Flare / glow |
| I | Fire |
| K | Smoke |
| L | Lightning |
| M | Magazine drop |
| N | Poison |
| P | Plasma |
| R | Projectile |
| S | Spark |
| U | Puff |
