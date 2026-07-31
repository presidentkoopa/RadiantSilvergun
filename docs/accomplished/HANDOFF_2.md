# RS_Main Handoff — Part 2

Continues from [`docs/HANDOFF.md`](HANDOFF.md) (Part 1). That document
still holds — architecture, hard rules, asset layout, the import
checklist — none of it is repeated here. This covers everything built
since Part 1 was last written (right after the universal reload system
landed): weapon gating, a full model/MODELDEF sanity pass that found
three real bugs, and a new Debug/Testing menu.

## Weapon gating

**Vanilla+ now behaves like real vanilla Doom, not a StartItem-only
sandbox.** Three problems fixed together:

- All 8 map-slot `RS_VP_*` weapons (Pistol, Shotgun, SuperShotgun,
  Chaingun, RocketLauncher, PlasmaRifle, BFG9000, Chainsaw) now carry
  `replaces <Vanilla>`. Before this, none of them could ever appear on a
  map — `StartItem` was the only source, forever. Fist is excluded (never
  a map pickup in vanilla Doom); the Assault Rifle is excluded (no
  classic slot — see below).
- `RS_VP_Weapon` gained a shared offhand-morph pickup pattern:
  `virtual Class<Weapon> GetOffhandClass()` (base returns null) plus
  `override bool TryPickup(in out Actor toucher)`. If the toucher already
  holds the mainhand but not the offhand, the pickup morphs into the
  offhand weapon instead of vanilla's "already own it, ammo only"
  behavior. Once both hands are full, `Super.TryPickup` runs unchanged.
  Same virtual-override shape `GetHeavyProjectile()` already established
  for heavy projectiles — each of the 8 mainhand files just names its own
  `"X2"` sibling.
- `VR_VanillaPlus`'s start trimmed to a real vanilla-style loadout:
  mainhand-only pistol (`RS_VP_Pistol2`/`RS_VP_PistolLoaded2` start grants
  removed). Both fists are still granted — VR needs the off-hand
  fallback regardless, and Fist was never a map pickup either way.

**The Assault Rifle has no classic-Doom slot**, so it can't `replaces`
anything. Instead, `RS_VP_Chaingun.PostBeginPlay` rolls a chance to
silently substitute itself with `RS_VP_ARifle` before the player ever
sees it, gated by two cvars:

```
server bool rs_vanillaplus_arifle_enable = false;
server float rs_vanillaplus_arifle_chance = 0.15;
```

Default off (new, unbalanced content). A parallel "zombieman drop chance"
idea is deliberately **not** built — it depends on a Rifle Zombieman
monster that doesn't exist yet.

**Dual_ classes got a real base class instead of 7 duplicated blocks.**
`VR_DualClassBase : DoomPlayer abstract` now holds one shared
`PostBeginPlay`; each of the 7 `VR_Dual_*` classes just overrides
`GetMainhandClass()` to name its own weapon. That one shared method:

- Force-equips the granted mainhand weapon (`player.PendingWeapon = w`)
  instead of trusting engine default weapon-selection at spawn, which was
  observed leaving the player holding fists instead of their class weapon.
- Grants heavy ordnance (Rocket/Plasma/BFG, one of each, mainhand only)
  **plus their reserve ammo** (`RocketAmmo`/`Cell` — the earlier version of
  this toggle granted the guns with zero ammo) when
  `rs_dualclass_allowbigguns` is on. Default off, matching the
  post-complaint removal from earlier in the project's history — this is
  the opt-back-in, not a reversal of that decision.

New menu branch: `Dual Class Behavior` under `Radiant Silvergun Options`,
holding the Big Guns toggle. Two new entries added to the existing
`Vanilla+ Weapon Behavior` branch for the ARifle cvars.

## Model / MODELDEF sanity pass

A full audit was run across every main-arsenal weapon (Pistol, Revolver,
SMG, Rifle, Shotgun, SuperShotgun, Chaingun), cross-checked against
original source material the user provided directly (not guessed at) —
old reference MODELDEF/DECORATE files for the Revolver, Pistol, Rifle,
Shotgun, SMG, and Chaingun. **Do not re-audit these from scratch** —
they're confirmed correct or confirmed fixed:

- **Confirmed clean, no changes needed:** Pistol, Rifle, Shotgun,
  Chaingun, SuperShotgun. Every FrameIndex binding matches the reference
  or is internally consistent; no gaps, no case mismatches.
- **SMG — real bug, fixed.** The `Shoot:` state played invented frames
  (`SMGS B`/`C`) that were never part of the real design — a wrong guess
  made earlier when fixing an unrelated missing-sprite crash. The true
  design (confirmed against the original source): the gun body holds one
  static frame (`SMGG A`) the entire time it fires; the recoil illusion is
  sold entirely by a 3-frame muzzle flash cycle (`SMGF A/B/C`), which the
  project was previously only playing 1 of 3 frames of. Both fixed;
  the wrong MODELDEF bindings removed from all 6 identities.
- **Revolver — the most severe bug found.** `Reload:` was playing
  `REVO QRSTUVWXYZ`, but the real source plays `REVL` there — `REVO` never
  had frame data past letter `F`. Wrong sprite prefix, not a missing-content
  problem; fixed with a one-line ZScript change. On top of that, a batch of
  MODELDEF bindings across all 6 identities were case-mismatched (state
  plays uppercase `REVO G-L`/`REVF E-H`, MODELDEF only had lowercase
  `g-l`/`e-h` bound) — relabeled to match, using frame data that already
  existed. Net effect before the fix: most of the reload animation and half
  the muzzle flash were silently falling back to a flat 2D sprite instead
  of rendering the 3D model.
- **Fist — real bug, fixed.** Every other weapon in the project uses
  `Scale -1.0 1.0 1.0` (the established mirroring convention). `Fist` and
  `VR_Fist2` had no `Scale` line at all, and both used the *identical*
  transform — both hands rendering the same handedness instead of being
  mirror images. This is almost certainly the previously-reported
  "backwards fist" bug. Fixed by adding `Scale -1.0 1.0 1.0` to both.

**One asset still missing, not yet resolved:** `RedFlash.png` — the
Revolver's muzzle-flash skin, referenced identically across all 6
Revolver identities' `revf.md3` block. Doesn't exist anywhere in the
project under any casing. The user has a candidate flame/flash texture
image ready to drop in, but it hasn't been applied yet (needs a file path
handed over — the image was pasted into chat, not saved to a known
location).

## Debug / Testing menu (new)

`zscript/systems/RS_DebugMenu.zs` — `RS_DebugHandler : EventHandler`.
MENUDEF `Command` items can only run console commands, so anything
stateful or that needs to reach into `RS_Weapon`/`RS_HiFiFX` is dispatched
through `override void NetworkProcess(ConsoleEvent e)`, triggered by
MENUDEF entries of the form `Command "Label", "netevent <name>"`. Six
sections, each mapped to a real system rather than being a generic cheat
dump:

- **General** — native console commands only (god, noclip, kill monsters,
  full heal), zero ZScript.
- **Weapon Acquisition** — give-all/give-next per weapon set (cycles via
  `user` cvars `rs_debug_vpindex`/`rs_debug_dualindex`, one per player),
  force heavy ordnance, refill reserve ammo.
- **Stat / Roll Testing** — reroll held weapons to a menu-picked tier,
  dump both hands' current rolled stats to console.
- **Reload Testing** — empty held magazine(s) or reserve ammo on demand,
  to force the `Reload:`/`OutOfAmmo:` paths without burning real shots.
- **Vanilla+ Behavior Testing** — `ForceVPPickupMorph` actually calls
  `TryPickup()` on a freshly spawned instance (not `GiveInventory`, which
  bypasses pickup logic entirely) to exercise the real offhand-morph code
  path on demand; `TestARifleSubstitution` spawns 10 Chainguns under
  whatever the current cvar settings actually are and counts the result —
  an honest empirical test, not a faked one.
- **Hi-Fi FX Testing** — spawns casings/mag-drops/muzzle lights directly,
  bypassing `RS_HiFiFX`'s own tier gates on purpose (the point is to see
  the effect on demand regardless of the current Weapon Fidelity Options
  setting). The stress test spawns muzzle lights until the real cap is
  hit, confirming it holds under load.
- **Model Testing** — one entry so far: toggle mirroring on both held
  weapons' models (`Scale.X *= -1`), for A/B-testing an orientation fix
  live without editing MODELDEF and reloading between attempts.

**Two ZScript gotchas hit while building this, worth remembering:**
1. A function cannot return a dynamic array (`Array<string>`) by value in
   ZScript — use an `out Array<string>` parameter instead.
2. `Spawn(...)` has no implicit `self` when called from a `static`
   function on a non-Actor class (like an `EventHandler`). Use
   `Actor.Spawn(...)` — the properly-scoped static form — instead of bare
   `Spawn(...)`.

## Muzzle light cap is now a cvar, not a constant

`RS_HiFiFX.MAX_CONCURRENT_MUZZLE_LIGHTS` (a compile-time `const = 12`) is
gone. It's now `rs_fx_maxmuzzlelights` (server cvar, default 12, slider
0–256 in Weapon Fidelity Options), read via the new
`RS_HiFiFX.MaxMuzzleLights()` static method. If anything still references
the old constant name, that's a leftover to fix, not intentional.

## Updated open issues

Carried forward from Part 1, still open:
- Infinite ammo on the 3 main-arsenal heavy weapons (Rocket/Plasma/BFG
  never actually consume `AmmoType1` despite `Weapon.AmmoUse 1`).
- `RS_BallisticTracer` naming/architecture debt — whizz sound and
  ricochet still coupled to one visual variant instead of being universal,
  separately-toggleable bullet behaviors.
- The "locked stat" system (`LockedDamage`/etc. + `UnlockStat()`) does
  nothing — no `RollStats()` anywhere checks these before overwriting.
- Condition/backfire fully disabled (`RS_Roll.GetConditionEffects()`
  wrapped in `if (false)`) — explicitly out of scope for reload, confirmed
  by the user; this is a fire-time-only concern whenever it gets revisited.
- `zscript/monsters/RS_TEX_*.zs` (9 files) still unwired into `zscript.txt`
  — depends on external `HF_*` base classes not in this project. User has
  said not to worry about this yet.

Resolved this round, removed from the list: off-hand seating was already
confirmed working generally; the SMG/Revolver/Fist model bugs above; the
Dual_ "start with fists instead of guns" bug (force-equip fix).

New this round:
- `RedFlash.png` missing (see above).

## Next session: GunBonsai integration + keyword system

This is the explicitly agreed next priority, deferred to a new
conversation on purpose. What's known so far, so that conversation doesn't
start from zero:

- **`GunBonaiSockets`** (`RS_Weapon.zs`) is the only existing integration
  point today — a per-tier socket count (`RS_Roll.SocketsForTier`), set on
  every weapon in both sets, connected to no actual affix/upgrade logic.
  It's a placeholder field, not a working integration.
- **A GunBonsai fork existed in this project before this session** —
  `GunBonsai_RS_Fork.pk3` shows up in the git history as a deletion in the
  big reorg commit (`33d252a`). It is **not currently present** anywhere
  in the live project. Where the current, real version of this fork lives
  now is unknown — the next conversation needs the user to point at it
  directly rather than guessing or searching blindly (established
  practice this session: ask, don't go on undirected filesystem searches).
- **A "keyword system" was already flagged as wanted** in Part 1's open
  issues, before this session even started: *"a robust keyword system...
  to simplify distribution among our increasingly large range of sounds
  and effects in preparation for GunBonsai."* This is that work, now
  promoted from "someday" to "next," and the user wants it developed for
  **both weapon sets** (main arsenal and Vanilla+) together — presumably
  so GunBonsai's affix system can reason about weapons it doesn't
  natively know about via tags/keywords rather than hardcoded class
  checks, which is the standard shape of how GunBonsai's real compatibility
  patches for other weapon mods work.
- No design decisions have been made yet on what the keyword taxonomy
  actually looks like (per-weapon-type tags? per-projectile tags? damage
  type / delivery type / archetype tags feeding into the same "attack as
  data" framework discussed earlier this session?). That conversation
  should start with the user's intent for keyword scope, not with an
  assumed design.
