# CHShared — ATTACK CATALOG

Written 2026-08-06 against `docs/rs_35_monster_attack_catalog_spec.txt`.
Completes coverage to **18 of 18** code folders under `zscript/monsters/`;
the other seventeen are the CH families, one file each.

## DENOMINATOR ACTUALLY READ

| | count |
|---|---|
| files | 2 — `RS_CHEvents.zs`, `RS_CHShared.zs` |
| classes | 55 — 49 in CHEvents, 6 in CHShared |
| classes that attack | **1** |
| attack rows | **1** |

**This folder is machinery, not monsters, and that is the finding.**
`RS_CHEvents.zs`'s 49 classes are spawners and directors — `RandomSpawner`
subclasses (`RS_CH_PackofMedium`, `RS_CH_PackofHitScan`, …) and CH's dormant
bonus/ambush machinery (`RS_CH_BonusEnemyBaseSpawner`/`2`), kept inert exactly
as CH has it. **Zero attack actions across all 49**, verified comment-stripped.
`RS_CHShared.zs`'s other five classes are the drop-gating bases
(`RS_DropBaseWeapon` / `Powerup` / `Armor`) and two items (`RS_CH_BlurSphere`,
`RS_CH_BadItch`) — pickups, not attackers.

A grep for attack verbs returns 2 hits in `RS_CHShared.zs`. **One is prose
inside a comment block** (`RS_CHShared.zs:304`, describing VoidField's pulsing
A_Explode). Stripping comments before counting is what separates them — the
trap CLAUDE.md names.

---

## THE ONE ROW

  ATTACK   RS_CH_VoidOrb.Spawn
  file     zscript/monsters/chshared/RS_CHShared.zs:359
  shape    AURA
  payload  --   (no projectile; the actor IS the field)
  arc      --
  timing   one A_Explode per 12-tic cycle. Spawn is 5 states x 3 tics, but
           the loop is `Goto Spawn+1`, so after the first pass it cycles
           indices 1-4 only — 12 tics, one pulse each.
  damage   8        (bare constant, deliberately bare — VoidField has it the
                     same way. NOT a flattened roll; no roll exists here.)
  type     DIMp     (VoidField's own type, so existing resistances apply)
  sound    SeeSound "spell/spellcast1" · DeathSound "spell/Impact1"
           NOT traced to lumps — out of scope, and an unresolved sound name
           is inert with no error. Do not assume these play.
  impact   radius 96, no puff, no spawn. A_Explode's second arg is the
           distance, so the pulse is 8 damage inside 96 units.
  trigger  Spawn   (RS_FIRE_SPAWN — fires on arrival and keeps firing; this
                    is not a Missile beat and a `Missile:` filter finds nothing)
  range    --      (self-centred; the 96 radius is the whole extent)
  mirrored no
  inherit  Actor directly. Nothing inherited — Default and States are whole.
  profile  MakeRadial(radius: 96, damage: 8, heal: 0, hitsAllies: false)
  notes    SELF-TERMINATING: `A_Jump(6,"Death")` once per cycle, ~6/256, so it
           outlives a fight without outliving the map. MakeRadial has no field
           for that and no field for the pulse period — both are lost in the
           profile line and recorded here instead.
           +INVULNERABLE / -COUNTKILL / -SOLID: cannot be killed, cannot block
           a 100% clear, cannot be walked into.
           +DONTHARMSPECIES and +DONTHARMCLASS: it does not hurt its own kind.

---

## THE THING THAT MATTERS MOST ABOUT THIS ROW

**`RS_CH_VoidOrb` IS AN RS INVENTION. DO NOT DIFF IT AGAINST CH.**

It is the third deliberate departure in the project, after GrayPE2's healed
`RS_GreyDemon2` and the hell knight's kept lead-shot. CH names `VoidOrb` in two
`DropItem` lines (`MASTERMINDS.txt:3883` and `:4979`) and **defines it
absolutely nowhere** — a case-insensitive sweep of all of CH returns only those
two references. In CH the drop silently does nothing.

The owner ruled that the name belongs to CH's *attack* vocabulary rather than
its pickup vocabulary, and it was built on `VoidField`'s shape
(`RS_CacodemonFX.zs:942`) as the hazard the two hardest masterminds leave on
their corpse — same sprite, same DamageType, same invulnerable/no-kill posture,
but slower-pulsing, wider, and self-terminating.

So: **no CH line may be cited for its body**, and a future differ-against-CH
pass must skip it rather than report it as a divergence. The full derivation is
at `RS_CHShared.zs:296-321` and is worth reading before touching it.

---

## UNRESOLVED

1. **Sounds not traced to lumps.** `spell/spellcast1` and `spell/Impact1` are
   recorded as written. An unresolved sound name in GZDoom is completely inert
   — no error, no warning, no log line — so neither should be trusted to play
   until an SNDINFO pass with a denominator says so.
2. **`MakeRadial` cannot hold two of this attack's three real parameters.** It
   carries radius and damage; it has no pulse period and no self-termination
   chance. The profile line above is therefore an approximation of a *single
   pulse*, not of the attack. Same class of gap the other sixteen files
   report — `MakeRadial`'s `RadialDamage` is also an `int`, so it could not
   carry a roll if this one had ever had one.
3. **Not observed in game.** Nothing here was booted; the pulse period and the
   ~6/256 termination are read off the state chain, not measured.
4. **The 49 spawners were counted, not individually opened.** They contain no
   attack verbs, which is the question this catalog asks. What they *spawn* is
   a different catalog and is not attempted here.
