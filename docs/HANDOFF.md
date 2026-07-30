# RS_Main Handoff / Project Reference

GZDoom VR Doom mod. No `gzdoom.exe` or IWAD exists on this machine — nothing
in this project has ever been compile-tested here. Everything below was
verified statically (brace balance, duplicate-class greps, sound/sprite
string resolution checked file-by-file against what's actually on disk).
Treat any in-game report from the user as the first real ground truth for
whatever it touches.

## The two weapon sets

**Main arsenal** (`zscript/weapons/RS_*.zs`) — 10 weapons (Revolver, Pistol,
SMG, Rifle, Shotgun, SuperShotgun, Chaingun, RocketLauncher, PlasmaRifle,
BFG9000), each with 6 identities per type:
- Identities 1-3: mainhand-eligible, no `+WEAPON.OFFHANDWEAPON` flag.
  Identity 1 carries the full `RollStats`/fire logic; 2-3 are thin
  `Default`-only subclasses of it.
- Identities 4-6: same, but `+WEAPON.OFFHANDWEAPON` flagged, for the
  off-hand controller.
- All carry `+WEAPON.NOHANDSWITCH` (well, only identity 1 sets it in
  `Default`; subclasses inherit).
- Full elite-drop tier/roll system: `RollStats(EVR_Tier t)`, `Condition`,
  `XP`/`Level`, `GunBonaiSockets` (GunBonsai integration).

**Vanilla+ set** (`zscript/weapons/gnrcwpn/RS_VP_*.zs`) — 10 weapons ported
from the external `li-gnrcwpn` pack (Beretta→Pistol, Riotgun→Shotgun,
DoubleSG→SuperShotgun, Minigun→Chaingun, Rlauncher→RocketLauncher,
PlasRifle→PlasmaRifle, BFG9K→BFG9000, Knuckle→Fist, ModChainsaw→Chainsaw,
plus a bonus ARifle with no main-arsenal equivalent). Only **2 identities**
each (mainhand + `2`-suffixed offhand) — deliberately not 6, to avoid
project bloat, since this set doesn't participate in the tier loop.
Granted only via the `VR_VanillaPlus` player class's `StartItem`s, not
found in the wild as loot.

Both sets are real `RS_Weapon`-based classes (full roll/condition/XP
capability) so Vanilla+ weapons could join the main loot pool later
without rebuilding — currently gated off from that by simply never being
spawned as drops, not by any code restriction.

## Shared infrastructure (both sets call into this, neither owns it)

- **`zscript/weapons/RS_Weapon.zs`** — base class for the main arsenal.
  `ProjectileClass` field (swappable at runtime, read fresh at fire time —
  future hook for GunBonsai-style beam/rail attack-type swaps, not built
  yet). `A_RS_FireBallisticVolley(...)` (shared bullet-firing action).
  `A_RS_MuzzleFlash()` (calls into `RS_HiFiFX`). `override AttachToOwner`
  seats off-hand weapons: `if (bOffhandWeapon && newOwner.player)
  newOwner.player.OffhandWeapon = self;` — this is the actual dual-wield
  mechanism, confirmed working in-game for the Pistol; other weapon types
  use the identical code path but haven't been individually confirmed yet.
- **`zscript/weapons/gnrcwpn/RS_VP_Weapon.zs`** — Vanilla+'s own base,
  `RS_VP_Weapon : RS_Weapon abstract`. `Purist()` checks
  `rs_vanillaplus_purist` cvar. `A_RS_VP_Fire(...)` is Vanilla+'s shared
  fire path (equivalent role to the main arsenal's per-weapon fire logic,
  but consolidated since all 10 share more in common with each other than
  the main arsenal's 10 do). Reads `invoker.AmmoType1` directly for reserve
  ammo rather than hardcoding a class name per weapon.
- **`zscript/weapons/weaponfx/RS_HiFiFX.zs`** — plain **static utility
  class**, no inheritance from anything weapon-related. This is
  deliberate: it's the reason the FX system works for both weapon sets
  without modification, and will work for whatever gets imported next.
  `Tier()`/`TracersOn()`/`RicochetOn()` read cvars. `MuzzleEffects()`,
  `CasingEject()`, `MagDrop()`, `SpawnMuzzleLight()` (capped at
  `MAX_CONCURRENT_MUZZLE_LIGHTS = 12` via `ThinkerIterator` before
  spawning another, to protect performance in a firefight).
- **`zscript/weapons/weaponfx/RS_EnhancedFX.zs`** — ~57 classes, a full
  renamed ZScript rebuild of an external DECORATE effects library
  (explosions, debris, smoke, sparks, ricochet, casings, mag drops,
  muzzle lights, weapon-specific trail effects for rockets/plasma/BFG).
  Includes `RS_EnhancedRocket : Rocket replaces Rocket` (and the Plasma/
  BFG equivalents) — these transparently intercept every vanilla
  projectile spawn project-wide via the `replaces` keyword, so anything
  that fires a stock `Rocket`/`PlasmaBall`/`BFGBall` (including Vanilla+
  weapons) gets the enhanced trail for free with zero per-weapon wiring.
- **`zscript/weapons/weaponfx/RS_BallisticFired.zs`** — `RS_BallisticFired
  : FastProjectile`, the real-projectile replacement for hitscan bullets.
  `RS_BallisticType1` (default visual), `RS_BallisticTracer` (tier-gated
  tracer/ricochet variant, used when `rs_fx_tracers` is on).

## Hard rules — break these and things fail silently or crash at load

1. **Every class ported from an external standalone mod gets this
   project's prefix, no exceptions** — `RS_`/`RS_VP_`. GZDoom hard-errors
   on duplicate class names across loaded content; a throwaway-looking
   helper class from a source pack is just as much a collision risk as a
   named weapon class.
2. **`MODELDEF` must be a single root-level file literally named
   `MODELDEF`, no extension.** Individual `.modeldef` files silently never
   load. This was re-derived the hard way this session — don't split it
   back out.
3. **VOXELDEF binds to sprite name + frame letter, not to actor/class
   name.** Look at the weapon's actual `Spawn:` state to know what to
   bind, not the weapon's class name or the source mod's voxel filename.
4. **A MODELDEF `FrameIndex` bound to a sprite no `States` block actually
   plays is a hard "Unknown sprite" crash at load time**, not a harmless
   no-op. Every binding needs a real, played sprite+frame behind it.
5. **No hitscan.** This is a VR game — bullets are real traveling
   projectiles (`RS_BallisticFired`/`RS_BallisticType1`/`RS_BallisticTracer`),
   never `A_FireBullets`.
6. **Ammo include order matters** — ammo files must be `#include`d before
   the weapon files that reference their `AmmoType2` strings by name
   (`zscript.txt` documents this inline for both sets).
7. **Don't duplicate the FX-tier cvars.** There is exactly one settings
   surface for this: the "Hi-Fi Weapon Settings" menu
   (`CVARINFO.txt`/`MENUDEF.txt`) — one tiered dropdown
   (`rs_fx_hifitier`: Off/Standard/Hi-Fi) plus a small number of
   independent boolean toggles (`rs_fx_tracers`, `rs_fx_ricochet`,
   `rs_fx_hqvanillasounds`, `rs_vanillaplus_purist`). A new feature that
   wants a toggle goes here, not into a new parallel CVar set.
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
Environmental_Voxels wins** — it's the one intended to be baked in
project-wide later. Only `PISTA`/`PLASA`/`BFUGA` and the ammo voxels
(`CLIPA`/`SHELA`/`CELLA`/`CELPA`/`ROCKA`) currently come from it; the rest
are GNRCWPN-only. The Minigun is a special case: its own pack's only file
(`MNIGA.dat`) isn't a valid voxel format, so `Environmental_Voxels`'s
`MGUNA.kvx` (vanilla chaingun's real pickup voxel — functionally the same
model) was copied in and renamed to `MNIGA.kvx` to bind against our
`RS_VP_Chaingun`'s actual `MNIG` sprite. Only the Brass Knuckle has no
voxel anywhere and falls back to its flat sprite.

## Asset layout

Both asset trees mirror the zscript layout, so a path answers "which
weapon set owns this" on its own.

```
sprites/
  weapons/rs_weapon/vr_<weapon>/      main arsenal, one folder per weapon
  weapons/rs_vp_weapon/vp_<weapon>/   Vanilla+ set, one folder per weapon
  weapons/fx/                         casings + mag drop (set-agnostic)
  ballistic_bullets/                  the bb01 projectile sprites
sounds/
  rs_weapon/vr_<weapon>/              main arsenal, one folder per weapon
  rs_weapon/shared/                   AKEMPT (main arsenal only)
  bullets/                            casings / ricochet / tracer whizz
  impact/                             ballistic projectile impacts
  hq_vanilla/                         the HQ vanilla alternate pack
  UNUSED/                             pre-reorg originals, referenced by
                                      nothing -- kept, not deleted
```

Two things worth knowing before "fixing" this layout:

- **`bullets/`, `impact/`, and `hq_vanilla/` are top-level on purpose**,
  not nested under `rs_weapon/`. Both weapon sets consume all three. The
  Vanilla+ set in particular has **zero sound files of its own** — every
  `A_PlaySound` call across all 11 of its files resolves to `9mmclip1`,
  `AKEMPT`, or an `hq_*` entry. That's a real characteristic of the
  import, not an oversight, and is why there is no `sounds/rs_vp_weapon/`.
- **Folder depth inside `sprites/` is purely cosmetic.** GZDoom flattens
  the sprite namespace by name, so sprite files can be reorganized freely
  with zero code changes. Sound paths are the opposite — they are real
  paths written into `SNDINFO`, so moving a sound file means editing
  `SNDINFO` to match. The logical sound *names* in `SNDINFO`'s left column
  are what ZScript references, so those must never change during a move.

## Reusable import checklist (for the next external weapon/content pack)

This is the actual point of having done Vanilla+ as a full pass rather
than a quick port — the process is meant to be reused, not re-derived:

1. Survey first, in full — directory structure, code format (ZScript vs
   DECORATE), asset counts, existing shared base classes.
2. Total rename, no exceptions (see Hard Rule 1).
3. Don't port 1:1 — collapse near-duplicate classes differing only by
   numeric tuning into one parameterized class with a `SetupX()` method
   (pattern: `RS_BallisticFired.SetupStats`, `RS_SmokeWisp.SetupVisual`).
4. Extract frame/sprite-letter *structure* from old reference material if
   available, but resolve every path/skin/scale value against what's
   actually sitting in this project's own folders — never trust a
   reference file's paths.
5. Ground-truth every binding (sound, sprite, effect) against what the
   actual `States` block plays before wiring it — don't port unused
   bindings just because the source had them.
6. New content calls into `RS_HiFiFX`/`RS_EnhancedFX`/`RS_BallisticFired`
   rather than growing a parallel copy of smoke/tracer/casing logic.
7. Static verification pass after every substantial write (Hard Rule 8).
8. Discuss tone/feel decisions before writing code, not just architecture.

## Known open issues (not yet resolved, not yet reported fixed)

- **Off-hand seating**: confirmed working for the Pistol in-game
  (`AttachToOwner` correctly seats it). Not yet individually confirmed for
  the other 9 main-arsenal weapon types or the 10 Vanilla+ weapons, though
  they all share the identical code path.
- **Fist orientation**: user reported the fists may be visually
  180°'d/mirrored between hands ("left fist right arm, right fist left
  arm" pattern). Dropped mid-investigation, unresolved, not reproduced or
  root-caused.
- **`sounds/HQ_Vanilla` relocation**: user wants the `hq_*` sound files
  moved to a simpler path (`RS_Main/Sounds/HQ_Vanilla`). Explicitly
  deferred ("fix it later"), not done.
- **Attack-type/beam-swap system**: `ProjectileClass` on `RS_Weapon` was
  built specifically to support a future GunBonsai-style runtime
  visual/behavior swap (e.g. a "beam revolver" or "railgun shotgun" mod
  that changes what a weapon fires without editing its file). The field
  exists and is read at fire time; the actual swap-granting system that
  would set it doesn't exist yet. Agreed to be a separate future plan.
- **Keywording pass**: mentioned as wanted ("a robust keyword system...to
  simplify distribution among our increasingly large range of sounds and
  effects in preparation for GunBonsai") but not scoped or started.
- **Missing FX sprites** (user is sourcing these): `RS_EnhancedFX.zs` and
  `RS_BallisticFired.zs` reference sprite sets that have never been copied
  into this project — `SMOK`, `SPRK`, `SPKO`, `BPRT`, `BPUF`, `CPUF`,
  `LENR`/`LENG`/`LENB`, `PLBS`, `PEXP`, `PLSE`. `SMOK` and `SPRK` do exist
  in the `li-gnrcwpn` source (`sprites/weapons/smoke/` and `.../sparks/`)
  and just need copying; the rest have no located source yet. Until they
  land, every effect that plays them is a load-time crash risk.
- **`SPRK "S"` / `SPKO "S"` bad frame letter**: `RS_ExplosionParticle2`,
  `RS_ExplosionParticleHeavy`, and `RS_SparkX` play frame `S` of `SPRK`/
  `SPKO`. The real `SPRK` set only has frames `A`-`D` (cycled), so frame
  `S` doesn't exist even in the source material — this is wrong
  independently of the missing-file problem above and needs the states
  rewritten to real frame letters, not just the sprites copied in.
- **`SMGG B`/`C` don't exist**: `RS_SMG.zs:199` plays `SMGG BC` and
  `MODELDEF` binds `FrameIndex SMGG B`/`C` in all six SMG identity blocks,
  but only `SMGGA0.png` exists on disk (`sprites/weapons/rs_weapon/
  vr_smg/`). `SMGG` is a custom sprite, so unlike `PIST`/`BFUG`/`BFGG`
  these cannot come from the vanilla IWAD. Either the two sprite files are
  missing, or the state and its MODELDEF bindings should only use frame
  `A`. Pre-existing, unrelated to any folder reorganization.

## Where old/replaced material lives

`zscript/weapons/UNUSED/` — the original monolithic `RS_Arsenal.zs` plus
the 8 old `*MasterTemplate.zs` files it was split out of. Kept for
reference, not included in the build (`zscript.txt` doesn't reference this
folder). `UNUSED_MODELDEF/` at the project root holds superseded MODELDEF
material the same way. Don't pull paths, skins, or scale values from
either — main arsenal MODELDEF geometry data was independently rebuilt and
verified against current sprites/models this session; these folders exist
for history, not as a source of truth.
