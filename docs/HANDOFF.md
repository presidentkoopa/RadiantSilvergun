# RS_Main Handoff / Project Reference

GZDoom VR Doom mod. No `gzdoom.exe` or IWAD exists on this machine — nothing
in this project has ever been compile-tested here. Everything below was
verified statically (brace balance, duplicate-class greps, sound/sprite
string resolution checked file-by-file against what's actually on disk).
Treat any in-game report from the user as the first real ground truth for
whatever it touches.

## The two weapon sets

**Main arsenal** (`zscript/weapons/rs_weapon/RS_*.zs`) — 10 weapons
(Revolver, Pistol, SMG, Rifle, Shotgun, SuperShotgun, Chaingun,
RocketLauncher, PlasmaRifle, BFG9000), each with 6 identities per type:
- Identities 1-3: mainhand-eligible, no `+WEAPON.OFFHANDWEAPON` flag.
  Identity 1 carries the full `RollStats`/fire logic; 2-3 are thin
  `Default`-only subclasses of it.
- Identities 4-6: same, but `+WEAPON.OFFHANDWEAPON` flagged, for the
  off-hand controller.
- Full elite-drop tier/roll system: `RollStats(EVR_Tier t)`, `Condition`,
  `XP`/`Level`, `GunBonaiSockets` (GunBonsai integration).

`zscript/weapons/rs_weapon/RS_Fist.zs` is this set's off-hand fist
(`VR_Fist2 : Fist`) — main-arsenal-only, not shared with Vanilla+. Melee is
per-weapon-set by decision, not an oversight; a future cross-set
`RS_Dual_Fist` ("Slappers Only!") set is a deferred idea, not started.

**Vanilla+ set** (`zscript/weapons/rs_vp_weapon/RS_VP_*.zs`) — 10 weapons
ported from the external `li-gnrcwpn` pack (Beretta→Pistol,
Riotgun→Shotgun, DoubleSG→SuperShotgun, Minigun→Chaingun,
Rlauncher→RocketLauncher, PlasRifle→PlasmaRifle, BFG9K→BFG9000,
Knuckle→Fist, ModChainsaw→Chainsaw, plus a bonus ARifle with no
main-arsenal equivalent). Only **2 identities** each (mainhand +
`2`-suffixed offhand) — deliberately not 6, since this set doesn't
participate in the tier loop. Granted only via the `VR_VanillaPlus`
player class's `StartItem`s, not found in the wild as loot.

Both sets are real `RS_Weapon`-based classes (full roll/condition/XP
capability) so Vanilla+ weapons could join the main loot pool later
without rebuilding — currently gated off from that by simply never being
spawned as drops, not by any code restriction.

The shared abstract base for the set, `RS_VP_Weapon : RS_Weapon abstract`,
lives at `zscript/weapons/RS_VP_Weapon.zs` — one level up from the
`rs_vp_weapon/` folder that holds the 10 concrete weapon files. Don't be
surprised it isn't inside that folder; `zscript.txt` documents this
explicitly.

## Shared infrastructure (both sets call into this, neither owns it)

- **`zscript/weapons/RS_Weapon.zs`** — base class for both sets (`RS_Weapon`
  itself, and `RS_VP_Weapon : RS_Weapon` on top of it). Holds:
  - `ProjectileClass` — swappable bullet visual, read fresh at fire time.
  - `HeavyProjectileClass` + `GetHeavyProjectile()` — the equivalent for
    rockets/plasma/BFG. A weapon overrides `GetHeavyProjectile()` to name
    its `RS_Enhanced*` class; `PostBeginPlay` seeds the field from it once.
    Added specifically because before this existed, all six heavy weapons
    (3 per set) fired a hardcoded `A_FireProjectile("Rocket")`-style string
    carrying vanilla's own fixed damage — so tier, Condition, XP, and
    purist mode had zero effect on rocket/plasma/BFG damage. Fixed now:
    `A_RS_FireHeavyProjectile()` calls `SetupStats()` on the spawned
    projectile with the weapon's real rolled damage.
  - `A_RS_FireBallisticVolley(...)` — shared bullet-firing action.
  - `A_RS_ReloadAtomic()` / `A_RS_ReloadIncremental()` — universal reload
    plumbing (see below).
  - `A_RS_MuzzleFlash()` (calls into `RS_HiFiFX`).
  - `override AttachToOwner` — seats off-hand weapons
    (`newOwner.player.OffhandWeapon = self`, confirmed working in-game for
    the Pistol; other weapon types share the identical path but haven't
    been individually confirmed) **and** tops up `AmmoType2` to `Capacity`
    on pickup, so a newly found gun arrives loaded instead of forcing a
    reload mid-fight. Skips weapons with no magazine (fists, chainsaw,
    heavy ordnance).
  - `LockedDamage`/`LockedAccuracy`/`LockedVelocity`/`LockedCritChance`/
    `LockedCapacity` fields + `UnlockStat()` exist but **do nothing yet** —
    no weapon's `RollStats()` checks them before overwriting. Known gap,
    not yet actioned; matters if a future upgrade-card system is meant to
    let a player lock a stat before a reroll.
- **Universal reload** (`A_RS_ReloadAtomic()` / `A_RS_ReloadIncremental()`
  on `RS_Weapon`). Every reloadable weapon in both sets reduces to one of
  two bookkeeping shapes:
  - **Atomic** — fills `AmmoType2` to `Capacity` in one call. Covers
    magazine swaps, speed-loaders, and break-action reloads alike — all
    three "look" different in their `States` block (different animation,
    different sound sequence) but do identical math the moment the rounds
    actually go in. Used by Pistol, SMG, Rifle, Revolver, SuperShotgun,
    and all 10 Vanilla+ weapons that reload.
  - **Incremental** — loads one round per call, for weapons whose
    `Reload:` state is a loop. Used only by the Shotgun.
  Both read `invoker.AmmoType1` generically. Before this consolidation, six
  main-arsenal weapons each carried their own byte-identical copy of the
  atomic version with a different literal reserve-ammo string
  (`"Clip"`/`"VR_Shell"`) hardcoded in — the exact bug Vanilla+'s own
  `A_RS_VP_MagLoad` had already fixed once (by reading `AmmoType1`
  directly), just not carried back to the main arsenal. Now there is
  exactly one implementation of each shape, shared by both sets.
  Scope note: reload has **no relationship to Condition/backfire** —
  that's a deliberate boundary, not an oversight. Backfire-on-bad-condition
  stays a fire-time-only concern (currently disabled, see below);
  reloading never jams or fumbles based on Condition.
  Chaingun, RocketLauncher, PlasmaRifle, and BFG9000 (main arsenal) have no
  reload state at all — see the infinite-ammo bug below.
- **`zscript/systems/RS_Roll.zs`** (class `RS_Roll`) — tier ladder
  (`EVR_Tier`), `SocketsForTier()`, generic dice helpers, and Condition
  mechanics (`RepairCondition()`, `DegradeCondition()`,
  `GetConditionEffects()`). **`GetConditionEffects()` is currently disabled**
  wrapped in `if (false)`, with a comment explaining it fired far too often
  at too low a Condition threshold and needs rebalancing before re-enabling.
  Condition itself still tracks live — `DegradeCondition()` runs on every
  hit the player takes, `RepairCondition()` still responds to Grey Bits —
  but nothing currently consumes the number: backfire chance is
  permanently 0.0 and damage/pellet penalties never apply, in both sets.
- **`zscript/weapons/weaponfx/RS_HiFiFX.zs`** — plain **static utility
  class**, no inheritance from anything weapon-related. This is
  deliberate: it's the reason the FX system works for both weapon sets
  without modification, and will work for whatever gets imported next.
  `Tier()`/`TracersOn()`/`RicochetOn()` read cvars. `MuzzleEffects()`,
  `CasingEject()`, `MagDrop()`, `SpawnMuzzleLight()` (capped at
  `MAX_CONCURRENT_MUZZLE_LIGHTS = 12` via `ThinkerIterator` before
  spawning another, to protect performance in a firefight).
- **`zscript/weapons/weaponfx/RS_EnhancedFX.zs`** — ~50 classes, a full
  renamed ZScript rebuild of an external DECORATE effects library
  (explosions, debris, smoke, sparks, ricochet, casings, mag drops, muzzle
  lights). The three heavy-projectile `replaces` classes that used to live
  here moved to their own file (below) since they're projectiles, not
  effects.
- **`zscript/weapons/weaponfx/RS_HeavyProjectiles.zs`** — `RS_EnhancedRocket
  : Rocket replaces Rocket`, `RS_EnhancedPlasmaBall : PlasmaBall replaces
  PlasmaBall`, `RS_EnhancedBFGBall : BFGBall replaces BFGBall`, each with a
  `SetupStats(int finalDamage, double critChance)` mirroring
  `RS_BallisticFired.SetupStats`'s role. `replaces` is kept deliberately —
  weapons point `HeavyProjectileClass` directly at these class names, but
  plenty of non-weapon things spawn the vanilla classes too (the Cyberdemon
  fires a stock `Rocket`), and dropping `replaces` would strip the trail
  effects from all of those. Rocket's splash damage scales proportionally
  against vanilla's 128 baseline rather than using the raw roll, to avoid
  an absurd crater on a high roll.
- **`zscript/weapons/weaponfx/RS_BallisticFired.zs`** — `RS_BallisticFired
  : FastProjectile`, the real-projectile replacement for hitscan bullets.
  `RS_BallisticType1` (default visual), `RS_BallisticTracer` (used when
  `rs_fx_tracers` is on — despite the name, this is purely a visual/sound
  variant now, see the tracer note below).

### Note on "tracer" naming

`RS_BallisticTracer` predates a correction: it was originally built with
proximity-whizz-sound and ricochet-on-impact behavior welded to one visual
variant, which the user never asked for and found confusing (didn't know
what a "tracer" was supposed to mean). The intended shape — confirmed by
the user — is that the whizz sound and ricochet are **universal bullet
behaviors** that should apply regardless of which visual is active, not
bundled into one specific sprite choice. **This rework has not been done
yet.** As of now, `RS_BallisticTracer` still couples all three (BAL1
sprite + whizz + ricochet) — the class name and behavior are correct and
functional, but the architecture doesn't yet reflect the corrected design.
When touched next: split the sprite choice out as pure data (the same way
`RS_BallisticType1` already is), and move whizz/ricochet onto
`RS_BallisticFired` itself, each behind its own cvar, so any visual variant
gets them. Do not name anything "redshoes" — that was scaffolding used
mid-conversation to unstick a naming confusion, not an intended permanent
name; use plain descriptive names (e.g. `rs_fx_bulletwhizz`) instead.

## Menu structure

```
ZDoom Options
  └─ Radiant Silvergun Options        (RS_MainOptions)
       ├─ Weapon Fidelity Options     (RS_FXSettings)
       │    Hi-Fi Weapon Effects        rs_fx_hifitier    [Off/Standard/Hi-Fi]
       │    Bullet tracers              rs_fx_tracers     [On/Off]
       │    Ricochet effects            rs_fx_ricochet    [On/Off]
       │    HQ vanilla sound pack       rs_fx_hqvanillasounds [On/Off]
       └─ Vanilla+ Weapon Behavior    (RS_VanillaPlusSettings)
            Purist mode                rs_vanillaplus_purist [On/Off]
```

Set-agnostic FX toggles and set-specific behavior are deliberately split
into separate branches rather than one flat list — a new Vanilla+-only
setting (e.g. a future reload-feel toggle) belongs under `Vanilla+ Weapon
Behavior`, not bolted onto `Weapon Fidelity Options` just because both
happened to exist at the same time. **Don't duplicate these cvars** — this
is the one settings surface for weapon-related toggles; a new feature that
wants a toggle goes into one of these two branches.

## Hard rules — break these and things fail silently or crash at load

1. **Every class ported from an external standalone mod gets this
   project's prefix, no exceptions** — `RS_`/`RS_VP_`. GZDoom hard-errors
   on duplicate class names across loaded content; a throwaway-looking
   helper class from a source pack is just as much a collision risk as a
   named weapon class.
2. **`MODELDEF` must be a single root-level file literally named
   `MODELDEF`, no extension.** Individual `.modeldef` files silently never
   load.
3. **VOXELDEF binds to sprite name + frame letter, not to actor/class
   name.** Look at the weapon's actual `Spawn:` state to know what to
   bind, not the weapon's class name or the source mod's voxel filename.
4. **A MODELDEF `FrameIndex` bound to a sprite no `States` block actually
   plays is a hard "Unknown sprite" crash at load time**, not a harmless
   no-op. Every binding needs a real, played sprite+frame behind it. (Two
   real instances of this were found and fixed this session — see below.)
5. **No hitscan.** This is a VR game — bullets are real traveling
   projectiles (`RS_BallisticFired`/`RS_BallisticType1`/`RS_BallisticTracer`),
   never `A_FireBullets`. Heavy ordnance fires real vanilla-derived
   projectile actors (`RS_EnhancedRocket` etc.), also never hitscan.
6. **Ammo include order matters** — ammo files must be `#include`d before
   the weapon files that reference their `AmmoType2` strings by name
   (`zscript.txt` documents this inline for both sets).
7. **Don't duplicate the FX/behavior cvars.** See Menu structure above —
   exactly two settings branches, no parallel cvar sets.
8. **No compiler available on this machine.** Verification method is:
   brace-balance check, duplicate-class-name grep, sound-reference
   resolution against `SNDINFO`, and sprite-frame-by-frame resolution
   against actual files on disk (every `SPRITE LETTER` combo in every
   `States` block cross-referenced against what's really in `sprites/`).
   Run this after any substantial write; don't assume a binding resolves
   just because it looks plausible.

## Voxel pickups (`VOXELDEF.txt`, `voxels/`)

Two external voxel packs are in play for Vanilla+ world-pickup models:
`li-gnrcwpn-vox` (the source pack's own) and
`Environmental_Voxels_PickupAndDecoration` (a much larger, separately
curated pack). **Precedence rule: where both packs have the same voxel,
Environmental_Voxels wins.** Only `PISTA`/`PLASA`/`BFUGA`/`MNIGA` and the
ammo voxels (`CLIPA`/`SHELA`/`CELLA`/`CELPA`/`ROCKA`) currently come from
it; the rest are GNRCWPN-only. The Minigun is a special case: GNRCWPN's own
file (`MNIGA.dat`) isn't a valid voxel format, so `Environmental_Voxels`'s
`MGUNA.kvx` (vanilla chaingun's real pickup voxel) was copied in and
renamed to `MNIGA.kvx` to bind against `RS_VP_Chaingun`'s actual sprite.
Only the Brass Knuckle has no voxel anywhere and falls back to its flat
sprite.

## Asset layout

Both asset trees mirror the zscript layout, so a path answers "which
weapon set owns this" on its own.

```
sprites/weapons/
  rs_weapon/vr_<weapon>/       main arsenal, one folder per weapon
  rs_vp_weapon/vp_<weapon>/    Vanilla+ set, one folder per weapon
  fx/
    bullets/                   the bb01 projectile sprites
    casings/                   casing + mag-drop sprites
    smoke/, sparks/, puffs/,
    flares/, plasma/           the FX sprite sets imported this session
                               (see "FX sprites" below)
sounds/
  rs_weapon/vr_<weapon>/       main arsenal, one folder per weapon
  rs_weapon/shared/            AKEMPT (main arsenal only)
  rs_vp_weapon/vp_<weapon>/    Vanilla+'s own per-weapon sounds
  rs_vp_weapon/vp_shared/      mag-drop bounce sounds (set-agnostic use,
                                folder kept here since these are the only
                                sound assets sourced from the VP import)
  bullets/                     casings / ricochet / tracer whizz
  impact/                      ballistic projectile impacts
  hq_vanilla/                  the HQ vanilla alternate pack
  UNUSED/                      pre-reorg legacy files, referenced by
                                nothing -- kept, not deleted
```

Two things worth knowing:

- **`bullets/`, `impact/`, and `hq_vanilla/` are top-level on purpose**,
  not nested under `rs_weapon/`. Both weapon sets consume all three.
  Vanilla+ **used to** have zero sound files of its own and rode these plus
  `9mmclip1`/`hq_*` substitutes entirely — that's since been fixed (see
  "Vanilla+ sounds" below), but the shared folders stay top-level because
  they're still genuinely cross-set.
- **Folder depth inside `sprites/` is purely cosmetic.** GZDoom flattens
  the sprite namespace by name, so sprite files can be reorganized freely
  with zero code changes. Sound paths are the opposite — real paths
  written into `SNDINFO`, so moving a sound file means editing `SNDINFO`
  to match. The logical sound *names* in `SNDINFO`'s left column are what
  ZScript references and must never change during a move.

### FX sprites (imported this session, from a different source than expected)

`RS_EnhancedFX.zs`/`RS_BallisticFired.zs` reference sprite sets — `SMOK`,
`SPRK`, `SPKO`, `BPRT`, `BPUF`, `CPUF`, `LENR`/`LENG`/`LENB`, `PLBS`,
`PEXP`, `PLSE` — that were never actually copied into the project despite
being referenced since the FX system was first built. All were located and
copied in from `1.0b_Weapons_VanillaVRPlus_v1.2` (a separate DooM VR pack,
not `li-gnrcwpn`) and organized into the `fx/` subfolders listed above.
Two real bugs were found and fixed during this import, independent of the
missing files:
- `SPKO`/`SPRK` frame `"S"`/`"B"` didn't exist in the actual sanctioned
  source (only frame `A` does — `B`/`S` exist only in unrelated mods like
  BrutalDoom). Three states in `RS_EnhancedFX.zs` were rebound to frame `A`.
  These are single-frame fade-out particles, so the visual effect is
  unchanged.
- `RS_SMG.zs`'s `Shoot:` state played `SMGG BC`, and MODELDEF bound
  `FrameIndex SMGG B`/`C` in all six SMG blocks — but only `SMGGA0.png`
  exists anywhere. Fixed by rebinding to `SMGS B`/`C` (which exist and were
  otherwise unused), preserving the original model fire animation rather
  than flattening it to one frame.
- A third real MODELDEF bug found in the same audit pass: six
  `FrameIndex REVF k 0 10 ...` bindings (Revolver) pointed at an 11th frame
  that doesn't exist and no state plays. Removed.

### Vanilla+ sounds (imported this session)

Vanilla+ weapons originally had zero dedicated sound files and rode
`hq_dspistol`/`hq_dsshotgn`/etc. and a borrowed `9mmclip1` reload across all
10 weapons. Real sounds now exist for all of them
(`sounds/rs_vp_weapon/vp_<weapon>/`), sourced from `li-gnrcwpn`'s own
`sounds/weapons/` folder and mapped using that pack's own `SNDINFO.txt` as
the authority, not guessed by filename. Every weapon now has its own fire
take(s) (several with `$random` variety) and its own reload sound instead
of the borrowed substitute. `RS_MagDrop` also gained real sounds in the
same pass (`rs_fx_magdrop_small/large/bfg`) — it had none before.

## Reusable import checklist (for the next external weapon/content pack)

1. Survey first, in full — directory structure, code format (ZScript vs
   DECORATE), asset counts, existing shared base classes.
2. Total rename, no exceptions (see Hard Rule 1).
3. Don't port 1:1 — collapse near-duplicate classes differing only by
   numeric tuning into one parameterized class with a `SetupX()` method
   (pattern: `RS_BallisticFired.SetupStats`, `RS_SmokeWisp.SetupVisual`,
   `RS_EnhancedRocket.SetupStats`).
4. Extract frame/sprite-letter *structure* from old reference material if
   available, but resolve every path/skin/scale value against what's
   actually sitting in this project's own folders — never trust a
   reference file's paths.
5. Ground-truth every binding (sound, sprite, effect) against what the
   actual `States` block plays before wiring it — don't port unused
   bindings just because the source had them. This has caught real bugs
   every time it's been run (see the FX sprite and MODELDEF fixes above).
6. New content calls into `RS_HiFiFX`/`RS_EnhancedFX`/`RS_BallisticFired`/
   `RS_HeavyProjectiles`/the universal reload actions rather than growing a
   parallel copy of shared logic.
7. Static verification pass after every substantial write (Hard Rule 8).
8. Discuss tone/feel decisions before writing code, not just architecture.
9. **When in doubt about where source material lives, ask the user rather
   than searching broadly.** Established explicitly this session — don't
   go on undirected filesystem searches for "maybe this is the source"
   when the user can just say where it is.

## Known open issues (not yet resolved, not yet reported fixed)

- **Infinite ammo on 3 main-arsenal heavy weapons.** Rocket Launcher,
  Plasma Rifle, and BFG9000 (main arsenal only — Vanilla+'s versions are
  fine) have `Weapon.AmmoUse 1` set but never actually consume ammo: no
  `TakeInventory`/`DepleteAmmo` anywhere in their fire path, and
  `A_FireProjectile` is called with `useammo` effectively false. Found
  during the heavy-projectile refactor, deliberately preserved rather than
  silently changing game balance. Still open.
- **The modular attack-composition framework.** Discussed at length but
  not built: the goal is treating an "attack" as data — visual, tint,
  trail, fire sound, impact sound, impact effect, damage type, pellet
  count — so a weapon just points at one instead of hardcoding a
  class/behavior. Motivating example from the user: "a rocket launcher
  that fires 20 cryo pellets that make a lightning crack sound with red
  sparks and black smoke," entirely via data, no new classes. The heavy
  projectile field (`HeavyProjectileClass`/`GetHeavyProjectile()`) and the
  bullet field (`ProjectileClass`) are steps toward this, not the finished
  thing. Explicitly **no beam/instant-hit delivery type** — projectile
  delivery only, for now; beams would need a genuinely different code path
  (line traces) and were deliberately scoped out.
- **`RS_BallisticTracer` naming/architecture** — see the tracer note
  above. Whizz sound and ricochet need to move off the tracer visual and
  onto the base class as universal, separately-toggleable bullet behaviors.
- **The "locked stat" system does nothing.** `RS_Weapon` has
  `LockedDamage`/etc. fields and `UnlockStat()`, but no `RollStats()`
  override anywhere checks them before rerolling. Latent bug, not yet hit
  by anything in practice since nothing currently tries to lock a stat.
- **Condition/backfire is fully disabled.** `RS_Roll.GetConditionEffects()`
  is wrapped in `if (false)` pending a rebalance (previous version fired
  far too often at too low a Condition threshold). `DegradeCondition()`
  and `RepairCondition()` still run and the number is real and visible,
  but nothing consumes it — Condition currently cannot cause backfire or a
  damage/pellet penalty in either weapon set. Explicitly out of scope for
  reload (confirmed by the user) — this is a fire-time-only concern.
- **Off-hand seating**: confirmed working for the Pistol in-game. Not yet
  individually confirmed for the other 9 main-arsenal weapon types or the
  10 Vanilla+ weapons, though they all share the identical
  `AttachToOwner` path.
- **Fist orientation**: user reported the fists may be visually
  180°'d/mirrored between hands. Dropped mid-investigation, unresolved,
  not reproduced or root-caused.
- **Keywording pass**: wanted ("a robust keyword system...to simplify
  distribution among our increasingly large range of sounds and effects in
  preparation for GunBonsai") but not scoped or started.
- **`zscript/monsters/RS_TEX_*.zs`** — 9 new monster reskin/enhancement
  files, not wired into `zscript.txt` at all, and every class in them
  subclasses base classes (`HF_Imp`, `HF_Cyberdemon`, `HF_Caco`, etc.) that
  don't exist anywhere in this project — they look like enhanced-reskin
  addons meant to layer on top of a separate external monster mod. User has
  said not to worry about this yet.

## Where old/replaced material lives

`UNUSED_MODELDEF/UNUSEDweaponzs/` — the original monolithic `RS_Arsenal.zs`
plus the 8 old `*MasterTemplate.zs` files it was split out of.
`UNUSED_MODELDEF/unusedmodeldef/` — superseded MODELDEF material the same
way. Neither is referenced by `zscript.txt` or `MODELDEF`. Don't pull
paths, skins, or scale values from either — current geometry data was
independently rebuilt and verified against current sprites/models; these
folders exist for history, not as a source of truth.
