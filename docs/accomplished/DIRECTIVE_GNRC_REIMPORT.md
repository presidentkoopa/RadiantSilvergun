# DIRECTIVE: Asset Layout & GNRC Weapon Re-Import

Status: **executed.** Both sections below landed: the folder reorg (§1) and
the full Vanilla+ weapon rebuild (§2) — real alt-fires, real multi-stage
reloads, source-accurate primary fire, all sounds moved/registered, across
Pistol/Shotgun/SuperShotgun/Chaingun/RocketLauncher/PlasmaRifle/BFG9000/
ARifle. Verified via `git diff` against each `RS_VP_*.zs` file, not assumed.
Not independently re-verified: §1's "no dangling lump names" guarantee
(every relocated asset's references fixed in the same pass) — the bulk of
it looked consistent where checked, but this wasn't audited file-by-file.
This document stays as the record of what was planned and built, not a
to-do list anymore.

## 1. Asset folder layout (project-wide, not just Vanilla+)

**Per-weapon folders hold only that weapon's own hand sprites/sounds.**
- `sprites\weapons\rs_vp_weapon\vp_<weapon>\` — hand sprites only (already
  correct today, do not change what's already there).
- `sounds\rs_vp_weapon\vp_<weapon>\` — that weapon's own fire/reload/
  handling sounds only.

**Shared effects go in a shared bucket, sorted by category, never inside a
per-weapon folder.** Covers projectile flight sprites (plasma ball, rocket),
puffs, muzzle flash, casings, smoke, explosions, and their sounds.
- `sprites\weapons\fx\<category>\` — already exists for `smoke`, `casings`,
  `bullets`; extend with whatever categories the re-import needs (puffs,
  explosions, projectile trails).
- `sounds\weapons\fx\<category>\` — **does not exist yet.** Every sound in
  the project today is filed per-weapon, including sounds that are actually
  shared effects. This directive creates the bucket and requires shared
  sounds to move into it.

**Required first step:** scan `sprites\` and `sounds\` under this project,
identify anything that is a shared effect currently misfiled inside a
per-weapon folder, relocate it into the buckets above, and update every
`SNDINFO` / `zscript` reference that pointed at the old path. Nothing gets
moved without its references being fixed in the same pass — no dangling
lump names.

**Why this matters going forward:** Radiant Silvergun is replacing every
stock GunBonsai affix with dozens of new custom ones. New affixes will need
to assemble their own visuals/sounds from these shared effect pools rather
than each carrying a private, undiscoverable copy. This layout is what makes
that possible later — it's infrastructure for the affix system, not just
tidiness.

## 2. GNRC weapon re-import scope

Re-import the full GNRCWPN weapon set into `RS_VP_*`, one weapon at a time.

**In scope, per weapon:**
- Primary fire, rebuilt to match the source's real behavior.
- Alt-fire, where the source has a genuine second attack mode:
  - Pistol: 3-round burst.
  - Plasma Rifle: rail beam.
  - (Rocket Launcher's grenade alt-fire stays cut — see exclusions.)
- Reload — real multi-stage behavior (mag-out sound, empty beat, mag-in
  sound, ready cue), not the current flattened 3-frame version, still using
  the shared `RS_ReloadAtomic`/`RS_ReloadIncremental` plumbing where the
  shape fits.
- All sounds — every fire/reload/handling cue the source has, sourced
  correctly per §1.
- Sprites and animations — full hand-sprite state machines, effect spawns
  routed through the shared `fx` buckets instead of one-off imports.
- World-pickup voxels — **already done**, no action needed (`VOXELDEF.txt`
  covers all 9 VP weapon pickups + ammo).

**Explicitly out of scope (do not port):**
- Aim-down-sights / zoom (Rifle, Shotgun both had this in source — VR
  aiming is physical, not a screen-zoom toggle).
- The punch-interrupt / melee-fallback system (`base.txt`'s
  `ActualPunch`/`BerserkPunch`, `Punching` inventory flag).
- Weapon bob tuning from `base.txt`'s `ModWeapon` default (`BobStyle`,
  `BobSpeed`, `BobRangeX/Y`).
- Rocket Launcher's grenade alt-fire.

## 3. Stat architecture: opt-in rolling, not forced

These are **not** getting a new class hierarchy. They stay on
`RS_VP_Weapon`, because it already has the exact mechanism this needs:
`Purist()`, gated by the `rs_vanillaplus_rollstats` cvar (menu label:
"Roll Weapon Stats," default **off**).

- Default (`Purist() == true`): every weapon uses fixed, real numbers taken
  directly from the source — no `RS_Roll` randomization. This is the "just
  get the guns in here, they don't roll stats" baseline.
- Opt-in (`rs_vanillaplus_rollstats` on): `RollStats()`'s existing rolled
  branch takes over, same tier-scaled ranges as today.

No new toggle, no new base class. The re-import's job is to make sure the
fixed (`Purist`) branch of each weapon's `RollStats()` actually holds the
real source numbers, not placeholder tuning.
