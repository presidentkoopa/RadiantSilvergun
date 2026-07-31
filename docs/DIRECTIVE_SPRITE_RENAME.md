# DIRECTIVE: Project-Wide Sprite Naming Pass

Status: **plan only, not started.** Nothing below has been executed.

{edit - this has been started, maybe even finished, as effect_catalog.md and catalog_notes)

## 1. Why this is worth doing

**GZDoom's sprite namespace is flat.** The engine identifies a sprite by its
4-character lump name alone; the folder it sits in is organisational only and
carries no meaning at load time. Two files named `SHT2B0` in two different
folders are the *same sprite* to the engine, and one silently overwrites the
other according to load order.

This is not theoretical. As of this audit the project ships **five frames of
colliding, genuinely different art**:

| Sprite | Contested by | Consequence |
|---|---|---|
| `RIFL A` | `vp_arifle` (VP Assault Rifle pickup) vs `vr_rifle` | one silently wins |
| `SAWG A` | `vp_chainsaw` vs `vr_saw` | one silently wins |
| `SHT2 B` | `vp_supershotgun` vs `vr_ssg` | one silently wins |
| `SHT2 D` | `vp_supershotgun` vs `vr_ssg` | one silently wins |
| `SHT3 A` | `vp_supershotgun` vs `vr_ssg` | one silently wins |

Beyond collisions *within* the project, many current names are stock Doom
sprite names (`PISG`, `SHTG`, `SHT2`, `CHGG`, `MISG`, `PLSG`, `SAWG`, `PUNP`,
`RIFL`, `PLAS`, `LAWN`, `BFUG`, `CSAW`, `RIOB`, `DBBL`), so the project also
silently overrides vanilla art game-wide wherever it ships one.

The `sprites/combatfx/` tree was already fixed this way (`RSP0`, `RSE1`,
`RSC2`…) and is the proven model. This directive extends the same discipline
to the per-weapon sprites, which were left alone in that pass.

**Secondary benefit, and the reason to do it now:** a systematic name makes a
sprite set *addressable in code* — `GetSpriteIndex("VPSR")` — which is what
the planned RS affix system needs in order to swap or layer weapon visuals
without a hand-written actor per combination.

## 2. Scope

- **670 sprite files** across **83 distinct 4-character prefixes**, in 21
  weapon folders (10 Vanilla+, 11 main arsenal).
- Every affected weapon's `States` block must be rewritten in lockstep, or the
  sprite silently disappears in game. That is ~21 `.zs` files.
- `sprites/combatfx/` is **out of scope** — already correct.
- `sprites/pickups/` and `textures/` are **out of scope** — GunBonsai owns
  those names and they are an upstream drop-in (see
  `DIRECTIVE_GNRC_REIMPORT.md` §1).

## 3. Naming scheme

Four characters, fixed layout: **`<set><weapon><anim>`**

```
  V  PS  R
  │  │   └─ animation set (1 char)
  │  └───── weapon code (2 chars, unique within its set)
  └──────── which arsenal (1 char)
```

**Char 1 — arsenal**
| Code | Meaning |
|---|---|
| `V` | Vanilla+ set (`rs_vp_weapon`) |
| `A` | main RS arsenal (`rs_weapon`) |

**Chars 2-3 — weapon code**

| Vanilla+ | | Main arsenal | |
|---|---|---|---|
| `PS` Pistol/Beretta | `MG` Minigun | `PS` Pistol | `CG` Chaingun |
| `AR` Assault Rifle | `RL` Rocket Launcher | `RV` Revolver | `RL` Rocket Launcher |
| `SG` Riot Shotgun | `PL` Plasma Rifle | `RF` Rifle | `PL` Plasma Rifle |
| `DB` Double-Barrel | `BF` BFG | `SM` SMG | `BF` BFG |
| `CS` Chainsaw | `FS` Fist | `SG` Shotgun | `CS` Chainsaw |
| | | `SS` Super Shotgun | `FS` Fist |

**Char 4 — animation set**
| Code | Meaning |
|---|---|
| `I` | Idle / ready (and fire frames where the source shares them) |
| `F` | Fire, where it has its own sprite set |
| `R` | Reload — primary branch |
| `S` | Reload — secondary branch (chambered-vs-empty, loaded-vs-dry) |
| `L` | Muzzle flash (Light) |
| `P` | World pickup |
| `A` | Alt-fire / special state |

**Sequence** is the existing 5th character (frame letter) and needs no change.
GZDoom supports frames past `Z` via `[ \ ] ^ _` and lowercase, giving ~60 per
set; the largest current set is 26, so there is ample headroom.

### Worked example — Vanilla+ Pistol
| Now | Becomes | Contents |
|---|---|---|
| `BRTT` | `VPSI` | idle + fire, 5 frames |
| `BRLD` | `VPSR` | reload, empty branch, 19 frames |
| `CHLD` | `VPSS` | reload, chambered branch, 13 frames |
| `BRTF` | `VPSL` | muzzle flash, 2 frames |
| `PIST` | `VPSP` | world pickup — see §5 |

Reading `VPSS` tells you: Vanilla+, Pistol, secondary reload. The four sets
sharing `VPS` are visibly one weapon's family.

## 4. Execution order

Do **one weapon at a time**, never a bulk rename, so a mistake is contained
and attributable.

Per weapon:
1. Rename the sprite files (preserve chars 5-6 — frame and rotation — exactly).
2. Rewrite that weapon's `States` block to match.
3. Run the existing verifier (`scratchpad/verify.py`) — it resolves every
   referenced frame against disk and fails on any miss.
4. Only then move to the next weapon.

Before starting, and again at the end:
- Build the full IWAD stock-sprite list and assert **zero** generated name
  collides with it.
- Assert every generated name is unique project-wide.
- Assert the total file count is unchanged (670 in, 670 out).

**Case sensitivity is the known trap.** The `combatfx` pass broke `BB01`
because the rename script matched lowercase while the ZScript reference was
uppercase, and `sed` is case-sensitive; the bullet tracer pointed at a
nonexistent sprite until it was caught by audit. All matching in this pass
must be explicitly case-insensitive, and the verifier must run per weapon
rather than once at the end.

## 5. Open question — world pickup sprites

Several weapons' `Spawn:` states use stock names (`PIST`, `PLAS`, `LAWN`,
`BFUG`, `CSAW`, `MNIG`, `RIOB`, `DBBL`, `RIFL`) **on purpose**: the Vanilla+
weapons carry `replaces <VanillaClass>`, and `VOXELDEF.txt` binds voxel models
to those exact sprite names. Renaming them means updating VOXELDEF in the same
commit, and means the weapon no longer inherits the vanilla pickup appearance
as a fallback.

**DECISION: option (a) — rename them too**, updating `VOXELDEF.txt` in the
same pass so the voxel bindings follow. This fully removes vanilla name
collision, and resolves the live `RIFL A` clash as a side effect. Accepted
cost: a weapon whose voxel is missing no longer falls back to the vanilla
pickup sprite.

Applies only to pickup sprites the project actually **ships**. Ten do:

| Weapon | Pickup sprite | New name |
|---|---|---|
| VP Assault Rifle | `RIFL` | `VARP` |
| VP BFG | `BFUG` | `VBFP` |
| VP Minigun | `MNIG` | `VMGP` |
| VP Minigun (empty) | `EMNG` | `VMGQ` |
| VP Chainsaw | `CSAW` | `VCSP` |
| VP Fist | `PUNP` | `VFSP` |
| VP Plasma Rifle | `PLAS` | `VPLP` |
| VP Rocket Launcher | `LAWN` | `VRLP` |
| VP Riot Shotgun | `RIOB` | `VSGP` |
| VP Double-Barrel | `DBBL` | `VDBP` |

The **Vanilla+ Pistol ships no pickup sprite** — its `Spawn:` state resolves
`PIST` from the IWAD, with `VOXELDEF` supplying the voxel. Nothing to rename
there; it stays as-is by necessity, not by choice.

(`VMGQ` uses `Q` rather than `P` because the Minigun has two pickup states,
loaded and empty — see the `S` secondary-set convention in §3.)

## 6. Definition of done

- 670 files renamed, count verified unchanged.
- Zero name collisions project-wide; zero collisions against stock Doom.
- All 21 weapon `.zs` files updated; verifier clean on every one.
- The five known art collisions in §1 resolved.
- This document updated to record which §5 option was taken.
