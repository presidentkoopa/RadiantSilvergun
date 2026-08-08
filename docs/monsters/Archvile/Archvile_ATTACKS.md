> ## DO NOT TRUST THIS DOCUMENT. ASK THE OWNER.
>
> Nothing in `docs/` is authoritative -- not the handoffs, not the specs, not
> the ones the owner asked for himself. This file describes what was true when
> somebody wrote it, and this project has repeatedly proven that "true when
> written" and "true now" are different things.
>
> Verify anything you are about to act on against the **disk**, the
> **compiler**, or the **running game**. Ask the owner about anything to do
> with scope, priority, or what to build next. Never inherit a task from a
> document.
>
> *Banner added 2026-08-07 at the owner's instruction.*

# ARCHVILE FAMILY -- MONSTER ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Field order fixed, shape
vocabulary closed. Written 2026-08-06.

## THE DENOMINATOR I ACTUALLY READ

| Thing | Count | How |
|---|---|---|
| Monster classes with a body | 15 | `zscript/monsters/archvile/RS_Archvile.zs`, 2,357 lines, read whole |
| Cvar/spawn-dial stubs (no attacks) | 9 | same file: `RS_Colourset11`, `RS_BrownArch`, `RS_CyanArch`, `RS_AbyssArch`, `RS_GrayArch`, `RS_FireBluArch`, `RS_RedArch`, `RS_BlackArch`, `RS_WhiteArch` |
| FX / payload / minion classes | 65 | `zscript/monsters/archvile/RS_ArchvileFX.zs`, 2,869 lines, read whole |
| Externally-owned payloads opened | 20 | baron / caco / demon / imp / lostsoul / painelemental / shotgunner / spectre / zombieman FX files, cited per row |
| CH cross-check | 5,287 lines | `E:\New folder\ART SOURCE\CH\decorate\Archviles.txt`, greped `-i` for every attack verb (see UNRESOLVED #1 on the CH path) |
| Attack / behaviour states catalogued | 52 monster-side + 14 payload-side | below |
| **Rows written** | **66** | 52 monster-side, 14 payload-side |

Shape histogram for the 66 rows -- every word is from the spec's closed set,
none coined:

    UNCLASSIFIED 28   VILE 10   SINGLE 6   FAN 6   SCATTER 4   RING 4
    MELEE 2   BURST 2   SALVO 1   RAIN 1   HITSCAN 1   CHARGE 1
    COMBO 0   MULTI 0

UNCLASSIFIED is 42% of this family and that is a real result, not a shortfall:
the archvile's defining actions are **raising, summoning and buffing**, and the
spec's vocabulary has no word for any of them. Every one of those 28 is a
resurrection, a summon, an ally buff, a decoy, a self-enrage or a two-stage
release -- each with full notes, as the brief requires. MULTI is 0 for the
reason given in UNRESOLVED #3c, not because the family lacks multi-payload
attacks.

Attack states were found by following every `A_Jump` / `A_JumpIf` /
`A_JumpIfCloser` / `A_JumpIfHealthLower` / `A_CheckSight` / `A_MonsterRefire`
target out of `Missile`, `See`, `Pain` and `Death`. A `Missile:`-label filter
would have found 15 of the 52 -- this family routes almost everything through
named states (`Fires`, `Floor`, `Meteorr`, `Balls`, `Bolts`, `AggroUP`,
`Classical`, `IceIt`, `GroundSpike`, `Tangle`, `Tendrils`, `GroundVhirl`,
`HereComesThatBoi`, `BoltVolley`, `EyeSees`, `Scream`, ...).

## HOW I CLASSIFIED -- READ THIS BEFORE MERGING WITH THE OTHER SIXTEEN FILES

No word outside the spec's closed set is used. Three judgement calls, stated so
they can be normalised at compose time (also listed in UNRESOLVED):

1. **Shape precedence when two words fit.** Applied in this order:
   `VILE > CHARGE > HITSCAN > MELEE > COMBO > RAIN > MULTI > RING > FAN >
   SALVO > BURST > SCATTER > SINGLE`. So an attack that both burns and fans is
   VILE, per the family brief ("A_VileAttack is its own shape").
2. **`A_VileTarget` counts as VILE delivery.** The engine
   (`E:\UZDXREMA\wadsrc\static\zscript\actors\doom\archvile.zs`) spawns the
   named class *at the target's position* after a `CheckSight` -- a
   line-of-sight placement with no travelling projectile, which is the same
   delivery VILE names. Every such row says which call it is (`A_VileTarget`
   only, or `A_VileTarget` + `A_VileAttack`). This family has 24 `A_VileTarget`
   sites and only 7 `A_VileAttack` sites, so the distinction matters.
3. **A cosmetic co-payload does NOT make a row MULTI.** MULTI is reserved for
   two or more *damage-bearing* classes. Zero-damage classes fired in the same
   state (`RS_BaronRing`, `RS_ArcRing1`, `RS_SparkPuff1`, `RS_DFlamePuffVile2`,
   `RS_IceStartVile4`, `RS_BlueGash2`) are listed in `payload` after a `+` and
   marked `(cosmetic)`.

## THE `profile` LINES ARE REAL CALLS, AND WHERE THEY ARE NOT, THEY SAY SO

Every `profile` line was written against the actual factory signatures in
`zscript/systems/weapon/RS_AttackProfile.zs` **as it stands on disk on
2026-08-06** (note: that file is currently modified in the working tree by
another lane -- see UNRESOLVED #12). The nine factories that exist:

    MakeBullet   MakeHitscan  MakeHeavy   MakeMelee                 (weapon-side)
    MakeVolley   MakeBurst    MakeSummon  MakeRadial  MakeSelfBuff  (monster-side)

Shape -> factory mapping used throughout:

| shape | factory |
|---|---|
| SINGLE | `MakeHeavy(proj, spawnHeight:)` |
| FAN / SALVO / RING | `MakeVolley(proj, count:, arc:)` -- `BurstDelayTics 0` is a one-tic release |
| BURST / time-spaced SCATTER | `MakeBurst(proj, count:, delayTics:, arc:)` |
| SCATTER (one tic) | `MakeVolley(proj, count:, arc:, pitchJitter:)` |
| MELEE | `MakeMelee(range:, fireSnd:)` |
| HITSCAN | `MakeHitscan(fireSnd:, spreadScale:)` |
| VILE | `MakeRadial(radius:, damage:)` -- the blast half only |
| summon / raise | `MakeSummon(cls, count:, cap:, tierOffset:)` |
| heal / aura | `MakeRadial(radius:, heal:, hitsAllies:true)` |
| self-buff | `MakeSelfBuff(duration:, noPain:)` |
| CHARGE, RAIN, resurrection | **no mode exists** -- flagged per row |

Range bands are written as `p.MinRange` / `p.MaxRange` post-sets, and non-Missile
triggers as `p.FireTrigger = RS_FIRE_WALK|PAIN|DEATH|SPAWN` (constants at
`RS_AttackProfile.zs:58-64`).

**45 rows carry a `+ gap:` line.** That is not padding -- it is the deliverable's
other half. Each names exactly what the current API cannot express for that
attack, so the weapon lane can see which fields are missing and which rows would
silently lose data if ported as written. The recurring ones are collected in
UNRESOLVED #11. A roll is never flattened to fit a field: where `RadialDamage`
(an `int`) cannot hold `random(a,b)`, the row writes `damage:<random(a,b)>` and
says so, rather than writing a midpoint (CLAUDE.md).

## ENGINE FACTS VERIFIED AGAINST SOURCE (not assumed)

Engine tree used: `E:\UZDXREMA` (see UNRESOLVED #2 -- CLAUDE.md names `E:\DXR2`,
which does not exist on this machine).

* `A_VileAttack(sound snd, int initialdmg, int blastdmg, int blastradius,
  double thrust, name damagetype, int flags)` --
  `wadsrc/static/zscript/actors/doom/archvile.zs`. **Three separate damage
  numbers, and every row below splits them:** `initialdmg` is dealt directly to
  the target with damagetype `'none'` unless `VAF_DMGTYPEAPPLYTODIRECT` is set
  (no CH archvile sets it, so **the direct hit ignores the named damage type**);
  `blastdmg`/`blastradius` are an `A_Explode` **at the tracer**, i.e. at
  whatever the last `A_VileTarget` spawned; `thrust` becomes
  `targ.Vel.z = thrust * 1000 / max(1, targ.Mass)` and is skipped entirely if
  the target is `+DONTTHRUST`. **With no preceding `A_VileTarget` there is no
  tracer and the blast never happens** -- only the direct damage and the thrust.
* `A_VileTarget(class<Actor> fire = "ArchvileFire")` -- spawns `fire` at
  `target.Pos`, sets `self.tracer = fog`, `fog.target = self`,
  `fog.tracer = self.target`, then calls `fog.A_Fire(0)`, which slides it to 24
  units in front of the player. `A_VileAttack` then re-seats it 24 units behind
  the target along the vile's angle before exploding it.
* `A_CustomMissile(class, spawnheight=32, spawnofs_xy=0, angle=0, flags=0,
  pitch=0, ptr)` -- `wadsrc/static/zscript/compatibility.zs:131` (deprecated
  alias of `A_SpawnProjectile`). **The third argument is a lateral offset, not
  an angle.** `A_CustomMissile("RS_WVileEye1",64,12)` is height 64, offset 12,
  angle **0**.
* `random(min, max)` with `min > max` **swaps the bounds** --
  `static int NativeRandom(FRandom*, int, int)`,
  `src/common/scripting/backend/codegen.cpp`. So CH's `random(180,-180)` is a
  full 360, not a degenerate call. Recorded verbatim on every row, with the
  swap noted.
* `CMF_AIMOFFSET = 1` -- `wadsrc/static/zscript/constants.zs:53`. This matters
  for `RS_RedArch3.AggroUP`; see that row's `notes`.
* `A_VileChase` -> `P_CheckForResurrection` (`src/playsim/p_enemy.cpp:2886`):
  on a successful raise the **vile** enters its own `Heal` state and the corpse
  plays `vile/raise` and enters its `Raise` state. That is why every `Heal` row
  below is a real behaviour and not dead animation.
* `RS_GrowRaisin` is an `Inventory { MaxAmount 1 }`. The archvile family
  `A_RadiusGive`s it to corpses; the **corpse's own `Raise` state** reads it
  (`A_JumpIfInventory("RS_GrowRaisin",1,"Grow")`, e.g.
  `zscript/monsters/demon/RS_Demon.zs:695`) and takes a `Grow` branch that
  spawns the **next tier up** of that monster and `A_Die`s the current body.
  So "give GrowRaisin" means **whatever raises this corpse later gets a
  stronger monster**. That is the family's signature support verb and it
  appears on eight monsters.

## FRAME-COUNT RULE APPLIED THROUGHOUT

An action on a multi-frame state line fires **once per frame**.
`DIAB GHGH 2 ... A_CustomMissile(...)` is **four** projectiles, not one.
`VILE JJJJJJJJJ 1 ...` is nine. Every count below is frame-expanded.

---

# TIER 1 -- RS_CommonArch  (`RS_Archvile.zs:1055`, CH Archviles.txt:2313)

```
ATTACK   RS_CommonArch.Missile
file     zscript/monsters/archvile/RS_Archvile.zs:1086
shape    VILE
payload  ArchvileFire x1   (engine default of bare A_VileTarget)
arc      --
timing   0,10,8,8,8,8,8,8,8,8,20   (86 tics; A_VileTarget at t=10, A_VileAttack at t=66)
damage   A_VileAttack defaults -- initialdmg 20, blastdmg 70, blastradius 70, thrust 1.0
type     Fire  (blast only -- the direct 20 is dealt as 'none', see engine facts)
sound    "vile/start" via A_VileStart (:1083), then "vile/stop" via A_VileAttack default
impact   ArchvileFire is the blast anchor; A_VileAttack A_Explodes it for 70/70 with BulletPuff
trigger  Missile
range    --
mirrored no
inherit  Archvile (engine)  -- RS_CommonArch extends Archvile; the Missile chain is CH's retype of the vanilla one
profile  MakeRadial(radius:70, damage:70, fireSnd:"vile/stop", profName:"vile_burn")
         + gap: no field carries A_VileAttack's direct 20 or its thrust 1.0, and the
                fire class ("ArchvileFire") has nowhere to go. See UNRESOLVED #11.
notes    The reference implementation for the other six A_VileAttack rows in this
         family. CH keeps vanilla's numbers exactly (CH:2341/2343 are a bare
         A_VileTarget and a bare A_VileAttack).
```

```
ATTACK   RS_CommonArch.Heal
file     zscript/monsters/archvile/RS_Archvile.zs:1091
shape    UNCLASSIFIED
payload  --
arc      --
timing   10,10,10   (30 tics)
damage   --
type     --
sound    "vile/raise" plays on the CORPSE, not the vile (engine default)
impact   the corpse is revived at full health and enters its own Raise state
trigger  Walk   (A_VileChase in See, :1077 / :1079)
range    -- (P_CheckForResurrection scans the vile's own step box, no numeric arg)
mirrored no
inherit  --
profile  -- NO MODE EXPRESSES RESURRECTION. See UNRESOLVED #11.
notes    The plain raise -- animation only, no GrowRaisin, no summon. Kept as a
         row because it IS the behaviour a profile might carry, and because the
         three richer Heal states below are diffed against it.
         The frame line is CH's `VILE "[\]"`; our tree renders the `\` frame as
         `TNT1 A 10` (see RS_Archvile.zs header). Timing preserved, one frame
         invisible. Same substitution on every Heal row in this file.
```

# TIER 2 -- RS_GreenArch  (`RS_Archvile.zs:1134`, CH Archviles.txt:2384)

```
ATTACK   RS_GreenArch.Missile
file     zscript/monsters/archvile/RS_Archvile.zs:1182
shape    VILE
payload  RS_Greenening x1 + RS_Greenening2 x1
arc      --
timing   0,16,5,5,5,5,5,0,9,3,7,16   (76 tics; targets at t=16 and t=46, burn at t=58)
damage   A_VileAttack("vile/stop", random(6,32), random(6,32), 64, 2, "plasma")
         -- direct random(6,32); blast random(6,32) in radius 64; thrust 2
         PLUS RS_Greenening2 Death: A_Explode(random(2,8),32) x3 then A_Burst("RS_Greenies2")
         PLUS each RS_Greenies2: DamageFunction (random(1,2)), Poison
type     plasma (blast); Poison (the Greenies2 shards); direct hit is 'none'
sound    "vile/start" (:1179), "vile/stop" (A_VileAttack :1187);
         payload plays "Vile/active" x3 at volume 1.5 and "Weapons/bfgx" (FX:1586-1595)
impact   RS_Greenening2 (FX:1565) grows 2.5->4.7 scale, then BFE2 BCD explode
         x3 at random(2,8)/32 and A_Burst-shatters into bouncing RS_Greenies2
         (FX:1602 -- Hexen bounce, BounceCount 6, +EXPLODEONWATER, Poison)
trigger  Missile
range    --
mirrored no
inherit  Archvile (engine) for the body; payload classes are stand-alone
profile  MakeRadial(radius:64, damage:<random(6,32)>, fireSnd:"vile/stop", profName:"green_burn")
         + gap: RadialDamage is `int` and cannot carry a roll -- DO NOT flatten it to 19.
                No field for the direct hit, the thrust 2, the type "plasma", or the
                RS_Greenening2 shatter. See UNRESOLVED #11.
notes    Tracer at the moment of A_VileAttack is RS_Greenening2, so the 64-radius
         blast lands on it, not on RS_Greenening. RS_Greenening (FX:1530) is a
         pure grow-and-fade puff -- ZERO damage; it is the first target only.
         The shatter is the real damage and it arrives LATE.
```

```
ATTACK   RS_GreenArch.Heal
file     zscript/monsters/archvile/RS_Archvile.zs:1191
shape    UNCLASSIFIED
payload  --
arc      --
timing   10,10,10
damage   --
type     --
sound    "vile/raise" on the corpse
impact   plain revive
trigger  Walk (A_VileChase, :1173 / :1175)
range    --
mirrored no
inherit  --
profile  -- no resurrection mode; see UNRESOLVED #11.
notes    Identical to RS_CommonArch.Heal. No GrowRaisin.
```

# TIER 3 -- RS_BlueArch  (`RS_Archvile.zs:1233`, CH Archviles.txt:2579)

```
ATTACK   RS_BlueArch.Classic1
file     zscript/monsters/archvile/RS_Archvile.zs:1289
shape    VILE
payload  RS_BlueGash3 x3  (1 at :1289, 2 more at :1291 -- `VILE MN 4` is TWO frames)
arc      --
timing   0,16,7,7,7,7,7,4,4,6,16   (81 tics)
damage   A_VileAttack("vile/stop", random(12,42), random(12,42), 64, 10, "plasma")
         -- direct random(12,42); blast random(12,42) radius 64; thrust 10 (a hard launch)
type     plasma (blast); direct hit is 'none'
sound    "vile/start" (:1287), "vile/stop" (A_VileAttack :1292)
impact   RS_BlueGash3 (FX:1645) Death fires 15x RS_BlueGash2 --
         `PLSE ABCDE 3` (5 frames) + `PLSE EEEEEEEEEE 0` (10 frames) --
         at random(-180,180) angle, CMF_AIMOFFSET, pitch random(45,180).
         RS_BlueGash2 (FX:1670) is COSMETIC, zero damage.
trigger  Missile (A_Jump(255,"Classic1","Boltings2") at :1285 -- even coin flip)
range    --
mirrored no
inherit  Archvile (engine)
profile  MakeRadial(radius:64, damage:<random(12,42)>, fireSnd:"vile/stop", profName:"blue_burn")
         + gap: RadialDamage is `int`; the roll, the direct hit and the thrust 10 (the
                whole character of this attack) are all unrepresentable. UNRESOLVED #11.
notes    thrust 10 is the highest in the family -- ten times vanilla. On a
         standard 100-mass player that is Vel.z = 100. All the visual noise
         (45 plasma flares) does no damage at all; every point comes from the
         A_VileAttack line.
```

```
ATTACK   RS_BlueArch.Boltings2
file     zscript/monsters/archvile/RS_Archvile.zs:1300
shape    SINGLE
payload  RS_BigBolt2 x1   (spawnheight 32, angle 0)
arc      --
timing   5,5,4,8,8,8,8,8,1,7,8   (70 tics; the bolt leaves at t=43)
damage   RS_BigBolt2 DamageFunction (random(25,95)), DamageType "Plasma"
type     Plasma
sound    "Vile/sight" (:1297); payload SeeSound none, DeathSound "weapons/bfgx"
impact   BFE1 AB then `BFE1 C 8 Bright A_Explode(random(25,75),128)` then BFE1 DEF
         -- a 128-radius secondary on top of the contact damage
         (zscript/monsters/lostsoul/RS_LostSoulFX.zs:1693)
trigger  Missile (A_Jump(255,"Classic1","Boltings2") at :1285)
range    --
mirrored no
inherit  -- (RS_BigBolt2 is a flat Actor, owned by the lostsoul lane)
profile  MakeHeavy("RS_BigBolt2", spawnHeight:32, profName:"blue_bolt")
notes    +SEEKERMISSILE with A_SeekerMissile(7,10) every other frame, speed 17,
         and it drips RS_BlueGash trail puffs. Contact random(25,95) PLUS blast
         random(25,75)/128 makes this the hardest single projectile any
         low-tier vile owns. The best clean SINGLE row in the family.
```

```
ATTACK   RS_BlueArch.Heal
file     zscript/monsters/archvile/RS_Archvile.zs:1305
shape    UNCLASSIFIED
payload  --
arc      --
timing   10,10,10
damage   --
type     --
sound    "vile/raise" on the corpse
impact   plain revive
trigger  Walk (A_VileChase, :1277 / :1279)
range    --
mirrored no
inherit  --
profile  -- no resurrection mode; see UNRESOLVED #11.
notes    No GrowRaisin.
```

# TIER 4 -- RS_PurpleArch  (`RS_Archvile.zs:1348`, CH Archviles.txt:2781)

```
ATTACK   RS_PurpleArch.Classic2
file     zscript/monsters/archvile/RS_Archvile.zs:1414
shape    VILE
payload  RS_PurpleWorry x1 + RS_PurpleWorry2 x1
arc      --
timing   0,13,8,11,11,11,11,11,0,9,8,16   (109 tics -- the slowest wind-up here)
damage   A_VileAttack, DEFAULTS: initialdmg 20, blastdmg 70, blastradius 70, thrust 1.0, Fire
         PLUS the RS_PurpleWorry2 storm below
type     Fire (blast); direct 20 is 'none'
sound    "vile/start" (:1412), "vile/stop" (A_VileAttack default)
impact   RS_PurpleWorry (FX:1698) -- zero damage, but its Death does
         A_RadiusGive("RS_GrowRaisin",100,RGF_MONSTERS|RGF_CORPSES,**6**), the
         largest GrowRaisin dose in the family.
         RS_PurpleWorry2 (FX:1724) -- see its own row below; it is the attack.
trigger  Missile (A_Jump(64,"Classic2") then A_Jump(255,"Classic2","Summon") at :1408-1409)
range    --
mirrored no
inherit  Archvile (engine)
profile  MakeRadial(radius:70, damage:70, fireSnd:"vile/stop", profName:"purple_burn")
         + MakeVolley("RS_TheBangers", count:24, arc:360)   // the RS_PurpleWorry2 storm
         + gap: needs TWO profiles because the fire class is itself an emitter. UNRESOLVED #11.
notes    Tracer at A_VileAttack time is RS_PurpleWorry2 -- the 70/70 blast lands
         on the seeker-storm emitter, which is still alive and firing. The
         GrowRaisin(6) on PurpleWorry means anything killed near this fight
         comes back a tier higher.
```

```
ATTACK   RS_PurpleArch.Summon
file     zscript/monsters/archvile/RS_Archvile.zs:1443
shape    UNCLASSIFIED
payload  RS_SpecialRev x1 per pass  (SXF_SETTARGET|SXF_SETMASTER, random(-8,8)/random(-12,12) offset)
arc      --
timing   1,8,8,7,11,11,11,11,3,9,2   (82 tics)
damage   -- (the summon fights on its own)
type     --
sound    "Vile/sight" (:1440)
impact   RS_SpecialRev (FX:1810) is a -COUNTKILL leashed revenant, Health 80,
         MeleeRange 88, +MISSILEMORE, warps back to master past 1000 units
trigger  Missile (A_Jump route :1409) and Walk (A_Jump(12,"Summon") in See at :1404)
range    --
mirrored no
inherit  RS_CommonRevenant (revenant lane) -- RS_SpecialRev overrides only Default + See
profile  MakeSummon("RS_SpecialRev", count:1, cap:8, tierOffset:0,
                    fireSnd:"Vile/sight", profName:"purple_escort")
notes    Hard-capped: `A_JumpIf(User_Summon == 8, "See")` at :1438. The counter
         is REBUILT to a toggle in Pain (:1456 -- `User_Summon = (User_Summon
         == 0) ? 1 : 0`, CH's `A_SetUserVar("User_Summon",User_Summon==0)`), so
         taking pain resets the cap and it can summon eight more. That is CH's
         behaviour, not a port bug -- both trees agree.
         Four RS_SpecialRev are also spawned free at Spawn (:1391-1394).
```

```
ATTACK   RS_PurpleArch.Heal
file     zscript/monsters/archvile/RS_Archvile.zs:1448
shape    UNCLASSIFIED
payload  RS_PurpleWorry x1 (on self, z+6)
arc      --
timing   1,1,10,10,10   (32 tics)
damage   --
type     --
sound    "vile/raise" on the corpse
impact   A_RadiusGive("RS_GrowRaisin",100,RGF_MONSTERS|RGF_CORPSES,3) at :1449,
         plus another 6 from the spawned RS_PurpleWorry's own Death
trigger  Walk (A_VileChase, :1400 / :1402)
range    100 (the GrowRaisin radius)
mirrored no
inherit  --
profile  MakeRadial(radius:100, damage:0, heal:0, hitsAllies:true, profName:"purple_growmark")
         + gap: MakeRadial has no "give this Inventory item" field, so the GrowRaisin
                tier-up mark -- the entire point of the action -- cannot be declared.
notes    The first Heal in the ladder that DOES something: every corpse within
         100 units is marked to come back a tier higher.
```

# TIER 5 -- RS_YellowArch  (`RS_Archvile.zs:1476`, CH Archviles.txt:3065)

```
ATTACK   RS_YellowArch.Fires
file     zscript/monsters/archvile/RS_Archvile.zs:1547
shape    VILE
payload  RS_ArcRing2 x3 (1 by A_VileTarget :1551, 2 by A_CustomMissile :1553/:1554 at random(-3,3))
         + RS_ArcRing1 x2 (cosmetic, :1547 / :1549)
arc      6   (the two A_CustomMissile rings, random(-3,3) each)
timing   0,13,6,7,7,7,7,7,0,7,1,4,2,12   (80 tics)
damage   A_VileAttack, DEFAULTS: 20 direct / 70 blast / 70 radius / 1.0 thrust / Fire
         PLUS each RS_ArcRing2: A_Explode(random(8,18),32) once per Fly-loop pass, unbounded
type     Fire (blast); ArcRing2's pulses are typeless (A_Explode default)
sound    "vile/start" (:1545); payload SeeSound "Fire/fire3"
impact   RS_ArcRing2 (zscript/monsters/lostsoul/RS_LostSoulFX.zs:1753) is a
         Hexen-bouncing, gravity-10, BounceCount 999 fire ring that wanders,
         fires 2x RS_FireHKBall1 per pass, drops RS_ArchRingHelp, and
         A_Explodes random(8,18)/32 EVERY pass until a 6/256 A_Jump kills it.
         RS_ArcRing1 (:1724) is +NOINTERACTION -- zero damage, pure floor art,
         but its Death gives GrowRaisin(3) at radius 100.
trigger  Missile (A_Jump(64,"Fires") then A_Jump(255,"Fires","Summon") at :1541-1542)
range    --
mirrored no  (the two A_CustomMissile rings use the same random(-3,3), not a mirrored pair)
inherit  Archvile (engine)
profile  MakeRadial(radius:70, damage:70, fireSnd:"vile/stop", profName:"yellow_burn")
         + MakeVolley("RS_ArcRing2", count:2, arc:6)   // the two A_CustomMissile rings
         + gap: RS_ArcRing2's own unbounded A_Explode loop is not a profile concept.
notes    Tracer at A_VileAttack is RS_ArcRing2 -- the 70/70 blast lands on a
         live, still-exploding ring. Total damage is genuinely unbounded: the
         ring's exit is a 6/256 roll per pass. This is the family's clearest
         "lingering area denial" and the reason `ArcRing2` is worth its own
         profile part.
```

```
ATTACK   RS_YellowArch.Summon
file     zscript/monsters/archvile/RS_Archvile.zs:1563
shape    UNCLASSIFIED
payload  RS_ArchSpawnerOrb x3  (random(-24,24) x/y, z+6, SXF_SETMASTER)
arc      --
timing   1,8,8,7,11,11,11,11,3,2,1,2   (76 tics)
damage   -- (the orbs summon; they do not hit)
type     --
sound    "Vile/sight" (:1560); orb ActiveSound "vile/active"
impact   RS_ArchSpawnerOrb (lostsoul/RS_LostSoulFX.zs:1854) wanders, and on
         `FireIt` spawns a vanilla `ArchvileFire` plus `RS_RandomizerArc`
         (:1925) -- a RandomSpawner over the ENTIRE CH monster table
         (imps/zombies/SGs/revenants/barons/CGuys/lost souls, weighted)
trigger  Missile (:1542) and Walk (A_Jump(11,"Summon") in See at :1537)
range    --
mirrored no
inherit  --
profile  MakeSummon("RS_ArchSpawnerOrb", count:3, cap:8, tierOffset:0,
                    fireSnd:"Vile/sight", profName:"yellow_orbs")
notes    Capped by `A_JumpIf(User_Summon2 >= 8, "See")` at :1558, and Pain
         SUBTRACTS 4 (`User_Summon2 = User_Summon2 - 4` at :1596), so pressure
         buys more summons. `Pain.Fire` (:1592) additionally rolls
         A_Jump(24,"Summon") -- setting this one on fire makes it summon.
         Three more orbs come free at Spawn (:1522-1527) and one at Heal (:1574).
```

```
ATTACK   RS_YellowArch.Heal
file     zscript/monsters/archvile/RS_Archvile.zs:1569
shape    UNCLASSIFIED
payload  RS_ArcRing1 x1 (self, cosmetic) + RS_ArchSpawnerOrb x1 (:1574)
arc      --
timing   1,1,10,10,10,1   (33 tics)
damage   --
type     --
sound    "vile/raise" on the corpse
impact   A_RadiusGive("RS_GrowRaisin",100,RGF_MONSTERS|RGF_CORPSES,3) at :1570
trigger  Walk (A_VileChase, :1533 / :1535)
range    100
mirrored no
inherit  --
profile  MakeRadial(radius:100, hitsAllies:true, profName:"yellow_raise")
         + MakeSummon("RS_ArchSpawnerOrb", count:1, cap:8, tierOffset:0)
notes    Raising a corpse also nets a free summon orb. The only Heal in the
         family that pays out twice.
```

# TIER 6 -- RS_RedArch2, ordinary phase  (`RS_Archvile.zs:1650`, CH Archviles.txt:3490)

```
ATTACK   RS_RedArch2.Breath
file     zscript/monsters/archvile/RS_Archvile.zs:1712
shape    SCATTER
payload  RS_ReABreath x3 per pass  (`DIAB ACE 2` -- THREE frames), angle random(-5,5) each
arc      10   (random(-5,5), re-rolled per frame)
timing   0,9,5,0,2,2,2,1,1 then loops to Breath+3   (~7 tics per repeat pass)
damage   RS_ReABreath DamageFunction (random(5,25)), DamageType "Fire"
type     Fire
sound    "Spell/SpellCast1" (:1708); payload SeeSound "CacoFlame/Attack",
         DeathSound "Fire/fire5"
impact   FLUM ABCDE flight, then `BBOM ABC 2 A_SetScale(0.6,0.6)` and
         `BBOM DEFG 2 A_Explode(random(1,5),64)` -- FOUR frames, so four
         explosions of random(1,5) at radius 64 (FX:1860, blast at :1882)
trigger  Missile, close band
range    ..420   (A_JumpIfCloser(420,"Breath",true) at :1704 -- noz = true)
mirrored no
inherit  --
profile  MakeBurst("RS_ReABreath", count:3, delayTics:2, arc:10,
                   fireSnd:"Spell/SpellCast1", profName:"red_breath")
         p.MaxRange = 420;
         + gap: no repeat field; this loops for as long as the target stays inside 420.
notes    A true sustained flamethrower: the loop exits only on
         `A_CheckRange(420,"See",true)` (:1713) or `A_MonsterRefire(128,"See")`
         (:1714), so it keeps breathing while you stay inside 420. Three per
         2-tic frame line = ~1.5 projectiles/tic sustained. The best
         "continuous close-range spray" part in this family.
```

```
ATTACK   RS_RedArch2.Meteorr
file     zscript/monsters/archvile/RS_Archvile.zs:1720
shape    SINGLE
payload  RS_ReAComet x1 (spawnheight 42, angle 0) + RS_BaronRing x1 (cosmetic, spawnheight 64)
arc      --
timing   3,3,6,7,7,7,0   (33 tics; the comet leaves on the last, 0-tic frame)
damage   RS_ReAComet DamageFunction (random(15,88)), DamageType "Fire"
type     Fire
sound    payload SeeSound "weapons/firmfi", BounceSound "Fire/fire4",
         DeathSound "weapons/firex4"; the STATE itself is silent
impact   RS_ReAComet (lostsoul/RS_LostSoulFX.zs:1983) is Scale 3, speed 28,
         Doom-bounce x2 off walls, trails RS_ReATrail every frame.
         RS_ReATrail (:2023) is itself damaging -- DamageFunction (random(5,10))
         Fire, and its Death does `BBOM CD 1 A_Explode(random(3,10),88)` (2
         frames) + `BBOM EFG 6 A_Explode(random(3,10),88)` (3 frames) = FIVE
         88-radius blasts per trail node.
         On its own Death the comet flips +ISMONSTER and A_Chases with
         CHF_RESURRECT -- a dead comet raises corpses (see UNRESOLVED #4).
trigger  Missile (A_Jump(256,"Classical","Meteorr") at :1705 -- even split)
range    420.. (only reached when NOT closer than 420)
mirrored no
inherit  --
profile  MakeHeavy("RS_ReAComet", spawnHeight:42, profName:"red_comet")
         p.MinRange = 420;   // only fired when NOT closer than 420
         (RS_BaronRing is cosmetic and needs no profile)
notes    The trail is the damage. One comet lays a corridor of ReATrail nodes,
         each worth five random(3,10)/88 blasts. Do not port the comet without
         the trail; the comet alone is a single random(15,88) hit.
         RS_BaronRing (imp/RS_ImpFX.zs:388) has NO Damage property -- cosmetic.
```

```
ATTACK   RS_RedArch2.Classical
file     zscript/monsters/archvile/RS_Archvile.zs:1725
shape    SINGLE
payload  RS_DFire x1  (spawnheight 32, offset 0, angle 0)
arc      --
timing   0,3,3,3(x15 frames = 45)   (51 tics; the fire leaves at t=6)
damage   RS_DFire has NO Damage/DamageFunction. Its Spawn chain is 29 interleaved
         `A_Explode(N,32)` pulses with N = 4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,5,
         4,4,3,3,3,2,2,2,1,1,1,1  (FX:1907-1964)
type     Fire  (DamageType "Fire" on the actor, FX:1896)
sound    A_StartFire / A_Fire / A_FireCrackle play the engine archvile fire sounds
impact   the pulses ARE the impact -- there is no separate Death FX
trigger  Missile (A_Jump(256,"Classical","Meteorr") at :1705)
range    420..
mirrored no
inherit  --
profile  MakeHeavy("RS_DFire", spawnHeight:32, profName:"red_firepillar")
         p.MinRange = 420;
notes    +SEEKERMISSILE, Speed 0, Radius 0 -- it does not travel; it is a
         standing 32-radius fire pillar that lives ~116 tics and pulses 29
         times for a total of 4+4+4+4+4+5*13+4+4+3+3+3+2+2+2+1+1+1+1 = 108
         damage if you stand in all of it. The ramp UP then DOWN is deliberate
         and is the whole character of the part -- do not average it.
         Reused verbatim by RS_RedArch3's Missile tail (:1851).
```

```
ATTACK   RS_RedArch2.Heal
file     zscript/monsters/archvile/RS_Archvile.zs:1750
shape    UNCLASSIFIED
payload  RS_ArcRing1 x1 (cosmetic) + RS_ArchSpawnerOrb x1 (SXF_SETMASTER)
arc      --
timing   0,10,2,5,5,4,6,6   (38 tics)
damage   --
type     --
sound    "vile/raise" on the corpse
impact   A_RadiusGive("RS_GrowRaisin",100,RGF_MONSTERS|RGF_CORPSES,3) at :1749
trigger  Walk -- NOTE: RS_RedArch2 does NOT use A_VileChase. Its See uses
         `A_Chase(null,"Missile",CHF_RESURRECT)` (:1697 / :1699)
range    100
mirrored no
inherit  --
profile  MakeRadial(radius:100, hitsAllies:true, profName:"red_raise")
         + MakeSummon("RS_ArchSpawnerOrb", count:1, cap:0, tierOffset:0)
notes    Same landing state as A_VileChase (the engine's Heal jump is on
         CHF_RESURRECT, not on A_VileChase specifically). CH writes
         `A_Chase("","Missile",CHF_RESURRECT)`; our tree's `null` for the empty
         string is the required ZScript form and is marked in the file header.
```

# TIER 6 -- RS_RedArch3, boss phase  (`RS_Archvile.zs:1774`, CH Archviles.txt:3699)

```
ATTACK   RS_RedArch3.Missile (tail)
file     zscript/monsters/archvile/RS_Archvile.zs:1851
shape    SINGLE
payload  RS_DFire x1
arc      --
timing   0,0,0,0,0,3,3,3,3(x15)   (51 tics)
damage   see RS_RedArch2.Classical -- the identical 29-pulse A_Explode ladder
type     Fire
sound    --   (this branch plays nothing of its own)
impact   as RS_RedArch2.Classical
trigger  Missile, fall-through when neither A_Jump lands (:1847 / :1848)
range    --
mirrored no
inherit  --
profile  MakeHeavy("RS_DFire", spawnHeight:32, profName:"redboss_firepillar")
notes    Reached ~25% of the time: A_Jump(60,"Fires") is 60/256, then
         A_Jump(132,...) is 132/256 across three states; the residue lands here.
         SILENT -- the only attack in the family with no sound at all, which
         makes it a clean profile slot (the gun's own sound fills it).
```

```
ATTACK   RS_RedArch3.Fires
file     zscript/monsters/archvile/RS_Archvile.zs:1855
shape    RING
payload  RS_DFlare x39 + RS_BaronRing x2 (cosmetic, :1855 / :1858)
arc      360 for 31 of them (angle random(180,-180), engine-swapped to random(-180,180));
         24 for the other 8 (angle random(-12,12) on :1860 and :1865)
timing   2,10,10,10,9,9,9,6,7,7, then the ten flare lines:
         2,2,2,2 | 1,1,1,1 | 2,2,2,2 | 1,1,1,1 | 2,2,2,2 | 2,2,2,2 |
         1,1,1,1 | 2,2,2,2 | 1,1,1,1 | 2,2,2
         (39 flares over 63 tics of release; ~89 tics of wind-up first)
damage   RS_DFlare DamageFunction (random(10,38)), DamageType "Fire"
type     Fire
sound    "Spell/SpellCast1" x3 (:1856 -- `DIA2 ABC 10` is THREE frames, so three
         casts); payload SeeSound "weapons/firmfi", DeathSound "weapons/firex4"
impact   RS_DFlare (cacodemon/RS_CacodemonFX.zs:86) trails RS_MFlareFX every
         frame (cosmetic) and dies to `CBAL CDEFG 3 Bright` -- NO explosion.
         Contact damage only.
trigger  Missile (A_Jump(60,"Fires") :1847, A_Jump(132,"Fires",...) :1848,
         and re-entered from AggroUP via Missile+1)
range    --
mirrored no
inherit  --
profile  MakeBurst("RS_DFlare", count:31, delayTics:2, arc:360,
                   fireSnd:"Spell/SpellCast1", profName:"red_flarestorm")
         + MakeBurst("RS_DFlare", count:8, delayTics:2, arc:24)   // the two random(-12,12) lines
         + gap: two profiles because CH interleaves a narrow-cone pair into the 360
                spray; one MakeBurst cannot do both arcs.
notes    The single biggest projectile count in the family. `random(180,-180)`
         is written backwards in CH (CH:3782-3790) AND in our tree; the engine
         swaps the bounds (codegen.cpp NativeRandom), so it is a genuine full
         360 spray, not a bug and not a no-op. Recorded as written.
         Tail-chains: A_Jump(48,"GroundVhirl") then A_Jump(24,"SummonSouls")
         at :1870-1871, so Fires often runs straight into a second attack.
         `DIAB GHGH` is FOUR frames -> four flares per line. Nine such lines
         plus `DIAB GHI` (three) = 39.
```

```
ATTACK   RS_RedArch3.SummonSouls
file     zscript/monsters/archvile/RS_Archvile.zs:1876
shape    UNCLASSIFIED
payload  RS_ArchSpawnerOrb x3  (2 on :1876 -- `DIA2 BB` is two frames -- and 1 on :1878... 
         `DIA2 CC` is also two frames, so 2 + 2 = 4 orbs total)
arc      --
timing   10,2,6,6,4,6,6   (40 tics)
damage   --
type     --
sound    "Forgotten/Pain" (:1875)
impact   as RS_YellowArch.Summon -- each orb eventually spawns ArchvileFire +
         RS_RandomizerArc (a random CH monster)
trigger  Missile (:1848) and tail of Fires (:1871)
range    --
mirrored no
inherit  --
profile  MakeSummon("RS_ArchSpawnerOrb", count:4, cap:0, tierOffset:0,
                    fireSnd:"Forgotten/Pain", profName:"redboss_orbs")
         + gap: cap is clamped to max(1,cap), so an UNCAPPED summon cannot be declared.
notes    Frame-expanded count is FOUR, not two: both `DIA2 BB 6` and
         `DIA2 CC 6` are two-frame lines and the action fires per frame. CH
         writes it the same way (CH:3799/3801). Uncapped -- unlike Purple and
         Yellow, RedArch3 has no user counter on this.
```

```
ATTACK   RS_RedArch3.GroundVhirl
file     zscript/monsters/archvile/RS_Archvile.zs:1882
shape    FAN
payload  RS_ArcRing2 x2 (angles random(-13,-3) and random(3,13)) + RS_BaronRing x1 (cosmetic)
arc      26   (-13..+13, with a dead band of +-3 in the middle -- the two rings
         never overlap)
timing   12,2,2,5,0,0   (21 tics; both rings leave on the same 0-tic pair)
damage   RS_ArcRing2: A_Explode(random(8,18),32) once per Fly-loop pass, unbounded
         until a 6/256 A_Jump ends it. Plus 2x RS_FireHKBall1 per pass.
type     -- (A_Explode default, typeless)
sound    payload SeeSound "Fire/fire3"
impact   see RS_YellowArch.Fires' impact -- same RS_ArcRing2 class
trigger  Missile (:1848) and tail of Fires (:1870)
range    --
mirrored yes  (the pair IS the mirror: random(-13,-3) / random(3,13))
inherit  --
profile  MakeVolley("RS_ArcRing2", count:2, arc:26, profName:"red_groundvhirl")
         + gap: the +-3 dead band in the middle (random(-13,-3) / random(3,13)) is not
                expressible -- MakeVolley spreads evenly across the arc.
notes    The cleanest mirrored pair in the family and the cheapest way to get
         RS_ArcRing2's lingering area denial into a profile: two bouncing fire
         rings that split left and right and then wander independently.
```

```
ATTACK   RS_RedArch3.AggroUP
file     zscript/monsters/archvile/RS_Archvile.zs:1892
shape    UNCLASSIFIED
payload  RS_SparkPuff1 x12  (cosmetic -- +NOINTERACTION, zero damage)
arc      --
timing   1,2,0,1,1,9,1,1,1,1,1,1,1,1,1,1,1,2   (28 tics)
damage   -- (no damage; this is a self-buff)
type     --
sound    "Monster/diasit" (:1894)
impact   sets `bNoPain = true` (:1891) and `bMissileEvenMore = true` (:1905),
         then increments User_Rage and returns to Missile+1
trigger  Missile, health gate
range    --   (health-gated, not range-gated: A_JumpIfHealthLower(1650,"AggroUP") at :1845)
mirrored no
inherit  --
profile  MakeSelfBuff(speedMult:1.0, damageMult:1.0, duration:0, noPain:true,
                      fireSnd:"Monster/diasit", profName:"redboss_rage")
         + gap: duration 0 means PERMANENT here, which MakeSelfBuff cannot say (it
                reverts). Also no field for bMissileEvenMore, the actual effect.
notes    ONE-SHOT -- `A_JumpIf(User_Rage >= 1, "Nah")` at :1890 sends every later
         entry to a 1-tic no-op. Fires at exactly half of 3200 health.
         **CH authoring quirk, preserved in both trees:** the call is
         `A_CustomMissile("RS_SparkPuff1",34,0,CMF_AIMOFFSET,random(0,360),random(0,360))`
         (CH:3813, ours :1892). The third slot is spawnofs_xy and the fourth is
         angle, so `CMF_AIMOFFSET` (= 1, constants.zs:53) lands in the ANGLE
         slot -- the puffs fire at 1 degree -- and `random(0,360)` lands in the
         FLAGS slot, meaning a random CMF_ bitmask every shot. Harmless because
         RS_SparkPuff1 is +NOINTERACTION, but do NOT copy this call shape into
         a damaging profile.
```

RS_RedArch3 has **no Heal state** -- its See uses plain `A_Chase` (:1839 / :1841)
with no CHF_RESURRECT. The boss phase does not resurrect. Confirmed against CH
(no `A_VileChase` and no `CHF_RESURRECT` between CH:3699 and CH:4328).

# TIER 7 -- RS_FireBluArch2  (`RS_Archvile.zs:917`, CH Archviles.txt:2115)

```
ATTACK   RS_FireBluArch2.Missile
file     zscript/monsters/archvile/RS_Archvile.zs:984
shape    VILE
payload  RS_FireBluVile x2  (:984 and :987)
arc      --
timing   0,16,3,3,3,2,2,2,2,1,1,1,1,1,1,6,5,5,5,5,5,0,9,3,7,16   (105 tics)
damage   A_VileAttack("vile/stop", random(6,64), random(6,64), 128, 2, "Fire")
         -- direct random(6,64); blast random(6,64) at radius **128** (double
         vanilla); thrust 2
         PLUS each RS_FireBluVile: DamageFunction (random(5,23)) contact, and a
         Death chain of A_Explode(random(3,10),64) x3 + 12x RS_FireSGguy2 +
         A_Explode(random(3,10),64) x3
type     Fire
sound    "vile/start" (:966), "vile/sight" (:982), "vile/stop" (A_VileAttack :989);
         payload SeeSound "imp/attack", DeathSound "imp/shotx"
impact   see the RS_FireBluVile.Death row below -- a 12-way ring, 30 degrees apart
trigger  Missile
range    --
mirrored no
inherit  Archvile (engine)
profile  MakeRadial(radius:128, damage:<random(6,64)>, fireSnd:"vile/stop", profName:"fireblu_burn")
         + gap: RadialDamage is `int`; also no field for the direct hit or thrust 2.
                Pair with the RS_FireBluVile.Death ring profile below. UNRESOLVED #11.
notes    Widest A_VileAttack blast radius in the family (128). The Missile chain
         is riddled with A_CheckSight("See") escapes at :971/:973/:977/:979/:981
         and :986 -- break line of sight during the ~1.5-second wind-up and it
         aborts. Worth carrying into a profile as a "channel" that can be
         interrupted.
         Tracer at A_VileAttack is the SECOND FireBluVile.
```

```
ATTACK   RS_FireBluArch2.Heal
file     zscript/monsters/archvile/RS_Archvile.zs:1009
shape    UNCLASSIFIED
payload  one of RS_FireBluSG / RS_FireBluCGuy / RS_FireBluRevenant / RS_FireBluHK /
         RS_FireBluLSoul / RS_FireBluCaco  (A_Jump(128, ...six labels...) at :1012)
arc      --
timing   10,10,10,0   (30 tics)
damage   --
type     --
sound    "vile/raise" on the corpse
impact   50% of raises ALSO spawn a fireblu minion at the vile's feet, SXF_SETMASTER
trigger  Walk (A_VileChase, :960 / :962)
range    --
mirrored no
inherit  --
profile  MakeSummon("RS_FireBluSG", count:1, cap:0, tierOffset:0, profName:"fireblu_minion")
         + gap: SummonClass is ONE class -- the six-entry table and the 128/256 gate
                cannot be expressed. Six profiles, or a RandomSpawner wrapper.
notes    A_Jump(128, a,b,c,d,e,f) = 50% chance to pick one of six uniformly.
         Pain (:1036) rolls the same jump across only the first three.
         No GrowRaisin on this one.
```

# TIER 8 -- RS_GrayArch2  (`RS_Archvile.zs:763`, CH Archviles.txt:1791)

```
ATTACK   RS_GrayArch2.Missile
file     zscript/monsters/archvile/RS_Archvile.zs:817
shape    RAIN
payload  RS_RockVileDrop x1 (:822) + RS_CHBSTarget x2 (cosmetic markers, :817 / :819)
arc      --
timing   2,0,12,1,6,5,5,5,5,5,0,9,3,7,16   (81 tics; the drop is called at t=56)
damage   RS_ROCKDROPVILE DamageFunction (random(75,155)) Melee on contact,
         then Death: A_Explode(random(60,115),64,0) + 19x RS_WDRock4 shrapnel,
         each DamageFunction (random(5,20)) Melee
type     Melee
sound    "vile/sight" (:815); RS_CHBSTarget plays "prox/beep" x2 as a telegraph;
         RS_ROCKDROPVILE SeeSound "monster/hamflr", DeathSound "moloch/thud"
impact   three-stage chain, all in RS_ArchvileFX.zs:
         RS_RockVileDrop (:1402, +NOCLIP, alpha 0.01) spawns
         RS_RockDropvile2 (:1421) at z+126, which is +CEILINGHUGGER and spawns
         RS_ROCKDROPVILE (:1441) at z-20 with gravity 1.25 and a single Hexen
         bounce -- an actual falling boulder that lands on the target's head.
trigger  Missile (A_Jump(128,"GroundSpike") at :813 -- 50% to the other attack)
range    --
mirrored no
inherit  --
profile  MakeVolley("RS_RockVileDrop", count:1, fireSnd:"vile/sight", profName:"gray_rockdrop")
         + gap: no RAIN mode and no spawn-above-target field. The three-actor chain
                (RockVileDrop -> RockDropvile2 at z+126 -> ROCKDROPVILE falling) is what
                makes it rain, so the profile MUST carry all three actors, and the
                RS_CHBSTarget telegraph has nowhere to be declared. UNRESOLVED #11.
notes    The only true RAIN in the family: spawned above the target and falling,
         not aimed. random(75,155) contact + random(60,115)/64 blast + 19
         pebbles is the hardest single hit any archvile lands.
         RS_CHBSTarget (shotgunner/RS_ShotgunnerFX.zs:807) is +NOINTERACTION,
         zero damage -- it is a 1.5-second audible telegraph and MUST be carried
         with the attack or the profile becomes an unfair instakill.
```

```
ATTACK   RS_GrayArch2.GroundSpike
file     zscript/monsters/archvile/RS_Archvile.zs:852
shape    FAN
payload  RS_VileGroundSpike x9  (3 at angle 0, 3 at -45, 3 at +45)
arc      90   (-45 / 0 / +45, 45-degree step, three deep per band)
timing   12,1,6,4,4,4,4,4,1, then 2,2,2,1,1,1,1,1,1, then 1,4,4,4   (release is 12 tics)
damage   RS_VileGroundSpike itself does none (Alpha 0.01, no Damage). It lays
         RS_VileGroundSpikes2 every 4 tics, and THAT is the damage:
         DamageFunction (random(1,10)) Melee contact plus
         A_Explode(random(60,100),32,0) x3 on eruption
type     Melee
sound    "vile/sight" (:845)
impact   RS_VileGroundSpikes2 (FX:1363) is a delayed mine: `SSPK C 30` idle
         with A_Jump(128,"WaitMore") (another 45+ tics, and a further 8/256
         re-roll), then it erupts for three A_Explode(random(60,100),32,0)
         pulses and finally A_SetSolid()s into a standing spike.
trigger  Missile (A_Jump(128,"GroundSpike") at :813)
range    --
mirrored yes  (the -45 and +45 bands are the same three lines with the sign flipped)
inherit  --
profile  MakeBurst("RS_VileGroundSpike", count:9, delayTics:1, arc:90,
                   fireSnd:"vile/sight", profName:"gray_groundspike")
         + gap: CH fires three-at-each-of-three-angles; MakeBurst spreads nine evenly
                across 90. Same count and arc, different clumping.
notes    Each of the 9 invisible runners lays 3 mines while it travels (Speed
         24, +FLOORHUGGER, looping Fly), so the ground fills with ~27 delayed
         random(60,100)/32 blasts on a 30-75 tic fuse. This is the family's
         area-denial-with-a-fuse part.
         CH writes the three lines as `VILE "[\]" 2/1/1` (CH:1874-1876) -- a
         THREE-frame state per line, 9 spikes. Our tree splits each into three
         lines because the escaped `\` frame is a parse error here; count,
         angles and tics are identical. Verified line by line.
```

```
ATTACK   RS_GrayArch2.Heal
file     zscript/monsters/archvile/RS_Archvile.zs:870
shape    UNCLASSIFIED
payload  one of RS_GrayDemon / RS_GrayCGuy / RS_GrayRevenant / RS_GrayHK /
         RS_GraySpectre / RS_GrayCaco  (A_Jump(128, ...six labels...))
arc      --
timing   10,10,10,0   (30 tics)
damage   --
type     --
sound    "vile/raise" on the corpse
impact   50% of raises also drop a gray minion at the vile's feet, SXF_SETMASTER
trigger  Walk (A_VileChase, :805 / :807)
range    --
mirrored no
inherit  --
profile  MakeSummon("RS_GrayDemon", count:1, cap:0, tierOffset:0, profName:"gray_minion")
notes    Structurally identical to RS_FireBluArch2.Heal, different table.
         `LSOUL` is a misnomer in CH: the label spawns RS_GraySpectre, not a
         lost soul. Kept verbatim (CH does the same).
```

```
ATTACK   RS_GrayArch2.Decoy
file     zscript/monsters/archvile/RS_Archvile.zs:897
shape    UNCLASSIFIED
payload  RS_VileGrayDecoy x1  (random(-32,32) x/y, SXF_SETMASTER)
arc      --
timing   0,2,2,2   (6 tics)
damage   --
type     --
sound    --
impact   RS_VileGrayDecoy (FX:1330) is a Speed 0, Health 99, -COUNTKILL statue
         that holds one random VILE A-D frame for 90 tics then fades out over 24
trigger  Pain (A_Jump(128,"Decoy") at :894 -- 50% of pain events)
range    --
mirrored no
inherit  --
profile  MakeSummon("RS_VileGrayDecoy", count:1, cap:0, tierOffset:0, profName:"gray_decoy")
         p.FireTrigger = RS_FIRE_PAIN;
         + gap: a decoy is not a minion -- it never acts. MakeSummon is the closest
                mode and it mis-describes the behaviour.
notes    A pain-reaction, not an attack: it drops a shootable body double and
         A_Wanders away. Recorded because it is a real behaviour a profile
         could carry and because a name filter would never have found it.
```

# TIER 9 -- RS_AbyssVile  (`RS_Archvile.zs:597`, CH Archviles.txt:1286)

```
ATTACK   RS_AbyssVile.Tangle
file     zscript/monsters/archvile/RS_Archvile.zs:678
shape    VILE
payload  RS_PsychicTangleAbyVile x1 per pass
arc      --
timing   1,5,1,5,2 per pass, looping   (14 tics per repeat)
damage   RS_PsychicTangleAbyVile DamageFunction (random(1,10)),
         DamageType "Getoutofmyheadcharles"  (CH's own type name, kept verbatim)
         plus A_Explode(1,32) and Radius_Quake(9,9,0,30,0) on arrival
type     Getoutofmyheadcharles
sound    "queen/sight" at ATTN_NONE, volume 2 (:673 -- map-wide);
         payload DeathSound "deepone/active"
impact   RS_PsychicTangleAbyVile (FX:1051) is +INVISIBLE and its Spawn IS its
         Death: A_Explode(1,32), a screen quake, then 15x
         RS_PsychicTangleAbyVile2 (FX:1081) scattered over random(-12,12) /
         random(-28,28) -- 5 close, 10 wide. Those are cosmetic (no damage) but
         each drops RS_ArchRingHelp x3.
trigger  Missile, far band
range    1500..   (A_JumpIfCloser(1500,"Choice") at :670 -- FAILING the check
         falls through to DarkTangle/Tangle, so this is the LONG-range attack)
mirrored no
inherit  --
profile  MakeRadial(radius:32, damage:1, profName:"abyss_tangle")
         + gap: the payload IS the screen quake (Radius_Quake(9,9,0,30,0)) and no mode
                or field expresses a quake at all. UNRESOLVED #11.
notes    Damage is nominal (1 blast + random(1,10) contact on an INVISIBLE
         actor). The payload is the SCREEN QUAKE -- Radius_Quake(9,9,0,30,0) --
         and the repeat: the state loops on itself until A_MonsterRefire(128,
         "See2") (:679) or A_CheckSight("See2") (:677) breaks it. As a profile
         part this is "harassment + camera shake", not damage.
```

```
ATTACK   RS_AbyssVile.Tendrils
file     zscript/monsters/archvile/RS_Archvile.zs:687
shape    VILE
payload  RS_ABVileTend x1 + RS_SplashAbyssVile2 x8 (:689, random(32,728) forward,
         random(-78,78) lateral)
arc      --
timing   5,10,5,5,0   (25 tics)
damage   RS_ABVileTend itself: none (no Damage, +NOCLIP).
         RS_SplashAbyssVile x?: DamageFunction (random(10,30)) -- see impact
type     -- (A_Explode/contact default, typeless)
sound    --   (this state is silent; the payload classes have no SeeSound)
impact   RS_ABVileTend (FX:1157) Death spawns FOUR RS_SplashAbyssVile2 in a
         cross at +-64 x and y. Each RS_SplashAbyssVile2 (FX:1189) flies BOGY
         ABC then spawns RS_ABVileTentacle (FX:1222) -- a full 30-HP melee
         MONSTER with 128 MeleeRange. Plus the 8 free RS_SplashAbyssVile2 at
         :689 spawn 8 more tentacles.
trigger  Missile, near band (A_Jump(255,"Tendrils","DarkTangle","Icicles") at :682)
range    ..1500
mirrored no
inherit  --
profile  MakeSummon("RS_ABVileTentacle", count:12, cap:12, tierOffset:0, profName:"abyss_tendrils")
         + gap: this is A_VileTarget delivery, not a spawn-at-self summon: the class
                arrives at the TARGET and unpacks through two intermediate actors
                (RS_ABVileTend -> RS_SplashAbyssVile2 -> RS_ABVileTentacle).
notes    This is a SUMMON dressed as a projectile: one A_VileTarget becomes up
         to 12 tentacle monsters around the player. Each has its own two attack
         rows below. The most expensive single archvile action to port.
```

```
ATTACK   RS_AbyssVile.IceIt
file     zscript/monsters/archvile/RS_Archvile.zs:695
shape    SCATTER
payload  RS_IceABVile x3 per pass  (`DGRD JJJ 2` -- THREE frames)
arc      18   (angle random(-9,9), re-rolled per frame; spawnheight random(24,42))
timing   2,2,2,2,1,1 then loops   (10 tics per repeat pass)
damage   RS_IceABVile DamageFunction (random(9,45)), DamageType "Ice",
         plus Death `ICEY FGHI 5 Bright A_Explode(random(5,12),64)` -- FOUR
         frames, so four 64-radius blasts of random(5,12)
type     Ice
sound    payload SeeSound "Ice/Hit2"; DeathSound "spike/spiked" -- **proven
         missing in CH's own SNDINFO** (see the FX file header, and UNRESOLVED #5)
impact   four A_Explode(random(5,12),64) pulses, plus RS_AbyssShotIdentifier
         markers dropped mid-flight
trigger  Missile, near band (A_Jump(255,"Tendrils","DarkTangle","Icicles") at :682)
range    ..1500
mirrored no
inherit  --
profile  MakeBurst("RS_IceABVile", count:3, delayTics:2, arc:18, profName:"abyss_icicles")
         p.MaxRange = 1500;
         + gap: no repeat field (A_MonsterRefire(128) exit), and none for the
                random(24,42) spawn height.
notes    Speed 46, XScale 1.5 / YScale 0.25 -- a flat horizontal shard. Loops
         until A_CheckSight("See2") (:696) or A_MonsterRefire(128,"See2")
         (:697). The best sustained mid-range SCATTER in the family.
         Note the non-uniform scale is a Default-block `XScale`/`YScale` pair,
         which IS legal (unlike a `Scale.X` property) -- see CLAUDE.md.
```

```
ATTACK   RS_AbyssVile.Melee
file     zscript/monsters/archvile/RS_Archvile.zs:702
shape    MELEE
payload  RS_SplashAbyss2 x16  (8 at :703, 8 at :705 -- `TNT1 AAAAAAAA 0` is EIGHT frames)
arc      50 then 30   (angle random(-25,25) then random(-15,15);
                       pitch random(-25,-5) with CMF_OFFSETPITCH, i.e. upward)
timing   6,0,6,0,6,0   (18 tics, two swings)
damage   A_CustomMeleeAttack(random(16,62),"imp/melee") x2
         plus RS_SplashAbyss2 DamageFunction (random(1,9)) DamageType "Ice"
type     -- (A_CustomMeleeAttack default damagetype) / Ice for the spray
sound    "imp/melee" on each swing (the A_CustomMeleeAttack argument);
         MeleeSound "vile/stop" declared on the actor at :625
impact   RS_SplashAbyss2 (zombieman/RS_ZombiemanFX.zs:735, extends
         RS_SplashAbyss) is a gravity droplet, speed 34, +DONTHARMCLASS
trigger  Melee
range    -- (engine default MeleeRange)
mirrored no
inherit  RS_SplashAbyss (zombieman lane) -- RS_SplashAbyss2 overrides only
         Height/Speed/DamageFunction/DamageType and three flags; its Spawn,
         Death and the BAL7 splash FX are INHERITED and are written nowhere
         near the attack
profile  MakeMelee(range:64, fireSnd:"imp/melee", profName:"abyss_claw")
         + MakeVolley("RS_SplashAbyss2", count:16, arc:50, pitchJitter:10)
         + gap: MakeMelee has no damage field at all (only dmgMult), so random(16,62)
                has nowhere to live, and no field expresses two swings.
notes    Two swings, each followed by an 8-droplet upward ice spray on the same
         tic. The spray is what makes this worth a profile slot -- a pure melee
         row would lose it. 32 damage rolls per Melee entry.
         Tails into A_Jump(32,"Jumpy") (:706) -- a 12% chance to leap backwards.
```

```
ATTACK   RS_AbyssVile.Heal
file     zscript/monsters/archvile/RS_Archvile.zs:709
shape    UNCLASSIFIED
payload  RS_AbyssBaronRing x1 (cosmetic) + RS_SplashAbyssVile x12 (:711,
         random(-258,258) x/y)
arc      --
timing   4,10,0,0,0   (14 tics)
damage   RS_SplashAbyssVile DamageFunction (random(10,30)) -- so the HEAL
         is itself an attack: twelve damaging floor-huggers over a 516x516 area
type     -- (typeless)
sound    "vile/raise" on the corpse
impact   RS_SplashAbyssVile (FX:1105) is +FLOORHUGGER, +BOUNCEONWALLS with
         BounceCount 999 and BounceFactor 1 -- it never stops until its ~140-tic
         animation runs out, cycling scale 1.5..1.8 and dropping RS_ArchRingHelp
trigger  Walk (A_VileChase, :645 / :648 and See2 :653-662)
range    258 (the spawn box); the huggers then bounce indefinitely
mirrored no
inherit  RS_AbyssBaronRing is baron/RS_BaronFX.zs:729 -- its Death gives
         GrowRaisin(3) at radius 100, which is where THIS monster's GrowRaisin
         comes from (it has no A_RadiusGive of its own)
profile  MakeVolley("RS_SplashAbyssVile", count:12, arc:360, profName:"abyss_healblades")
         p.FireTrigger = RS_FIRE_WALK;
         + gap: no field for the +-258 spawn BOX -- MakeVolley fires from the monster,
                CH scatters them across a 516x516 area around it.
notes    The only Heal in the family that DEALS DAMAGE. Raising a corpse floods
         the room with twelve immortal bouncing floor blades. Tails into
         A_Jump(76,"Portal") (:712) and A_Jump(32,"Jumpy") (:713).
```

```
ATTACK   RS_AbyssVile.Portal
file     zscript/monsters/archvile/RS_Archvile.zs:717
shape    UNCLASSIFIED
payload  RS_AbyssPortalVile x1  (z random(64,252) above the vile)
arc      --
timing   4,4,2   (10 tics)
damage   --
type     --
sound    payload SeeSound "holy2/holy4" -- **proven missing in CH's own SNDINFO**
         (see UNRESOLVED #5); DeathSound "wraith/wraith5"
impact   RS_AbyssPortalVile (FX:941) is a 250-HP floating summoner -- see its
         own row below
trigger  Walk, via Heal (A_Jump(76,"Portal") at :712 -- ~30% of raises)
range    --
mirrored no
inherit  --
profile  MakeSummon("RS_AbyssPortalVile", count:1, cap:1, tierOffset:0,
                    profName:"abyss_portal")
notes    Only reachable through Heal. A name filter would miss it twice over.
```

# TIER 10 -- RS_BlackVile  (`RS_Archvile.zs:1930`, CH Archviles.txt:4347)

```
ATTACK   RS_BlackVile.See (cloud)
file     zscript/monsters/archvile/RS_Archvile.zs:2009
shape    SINGLE
payload  RS_BVileCloud x1 per call, x3 per See loop (:2009, :2015, :2021)
arc      --
timing   0 (fired on 0-tic frames inside a 12-tic chase loop)
damage   RS_BVileCloud DamageFunction (random(1,2)), DamageType "Melee"
type     Melee
sound    --   (silent; the cloud has no SeeSound)
impact   RS_BVileCloud (FX:1973) is +NOCLIP, Stencil, speed 14 decaying to 8,
         fading out over 5 tics; Death spawns RS_ArchRingHelp
trigger  Walk   (fired from See, not Missile -- a passive aura while chasing)
range    --
mirrored no
inherit  --
profile  MakeBurst("RS_BVileCloud", count:1, delayTics:0, pitchJitter:45,
                   trigger:RS_FIRE_WALK, profName:"black_cloud")
         + gap: VolleyPitchJitter is symmetric around 0; CH's pitch is random(0,90),
                i.e. downward-only. 45 is the nearest symmetric stand-in, not equal.
notes    `A_CustomMissile("RS_BVileCloud",1,random(-5,5),0,CMF_AIMOFFSET,random(0,90))`
         -- spawnheight 1, lateral offset random(-5,5), angle **0**, flags
         CMF_AIMOFFSET (correctly placed here, unlike RedArch3's AggroUP),
         pitch random(0,90) (downward-ish). A ground-crawling smoke that chips
         1-2 per touch. A `Missile:` filter finds none of this.
```

```
ATTACK   RS_BlackVile.Balls
file     zscript/monsters/archvile/RS_Archvile.zs:2031
shape    SCATTER
payload  RS_BVileOrb1 x3  (angles random(-5,5), random(-12,12), random(-19,19))
arc      10 / 24 / 38   (a widening cone -- each shot looser than the last)
timing   6,5,3,3,3,3   (23 tics; orbs leave at t=6, t=14, t=20)
damage   RS_BVileOrb1 DamageFunction (random(12,45)), DamageType "Fire",
         plus Death `BAL2 DE 6 Bright A_Explode(random(12,64),64)` -- TWO
         frames, so two 64-radius blasts of random(12,64)
type     Fire
sound    --   (state silent); payload SeeSound "caco/attack", DeathSound "caco/shotx"
impact   two random(12,64)/64 blasts, plus the orb trails RS_BVileOrb2 (cosmetic)
         every other frame while flying (lostsoul/RS_LostSoulFX.zs:2055)
trigger  Missile (A_Jump(256,"GroundFlame","Balls","Summon") at :2028 -- even thirds)
         and the Summon overflow branch at :2040
range    --
mirrored no
inherit  --
profile  MakeBurst("RS_BVileOrb1", count:3, delayTics:4, arc:38, profName:"black_balls")
         + gap: both axes flattened: arc is one number so the WIDENING cone (10 then 24
                then 38) becomes a flat 38, and delayTics is one number so 6/8/6 becomes 4.
                The widening is the whole character of the attack.
notes    The widening cone is deliberate and is the part's whole character --
         a flat coneDeg loses it. Hexen bounce, BounceCount 6, BounceFactor 1.2
         (accelerating), so the orbs ricochet harder than they arrived.
```

```
ATTACK   RS_BlackVile.Summon
file     zscript/monsters/archvile/RS_Archvile.zs:2044
shape    UNCLASSIFIED
payload  RS_CommonRevenant x2 + RS_MrBones x4, + RS_DFlamePuffVile2 x23 (cosmetic:
         13 at :2044, 10 at :2053)
arc      360 (the puffs, angle random(-180,180), pitch random(-64,64))
timing   12,4x13,15,15,15,15,0,0,0,1   (~113 tics -- a very long channel)
damage   -- (RS_DFlamePuffVile2 is +NOINTERACTION, zero damage)
type     --
sound    "Bvile/Air2" (:2041) and "Bvile/Air1" (:2046), both ATTN_NONE volume 2
         -- map-wide announcements
impact   the summons arrive with SXF_TRANSFERRENDERSTYLE|SXF_SETMASTER, so they
         inherit the Black vile's Stencil/alpha-0.5 look and die with it
         (A_KillChildren at :2086)
trigger  Missile (A_Jump(256,"GroundFlame","Balls","Summon") at :2028)
range    --
mirrored no
inherit  --
profile  MakeSummon("RS_CommonRevenant", count:2, cap:2, tierOffset:0,
                    fireSnd:"Bvile/Air2", profName:"black_summon")
         + MakeSummon("RS_MrBones", count:4, cap:4, tierOffset:0)
         + gap: two classes, so two profiles; SummonClass is singular.
notes    Capped by `A_JumpIf(user_limit >= 1, "Balls")` at :2040 -- one summon
         per life, and every Pain->Phase decrements user_limit (:2078), so
         repeated pain re-arms it. `VILE GGGGGGGGGGGGG 4` is THIRTEEN frames,
         `VILE AAAA 0` is FOUR. Frame-expanded counts above.
```

```
ATTACK   RS_BlackVile.GroundFlame
file     zscript/monsters/archvile/RS_Archvile.zs:2064
shape    FAN
payload  RS_DarkFlameVile x2 (angles +12 / -12, lateral offsets +23 / -23)
         + RS_DFlamePuffVile2 x9 (cosmetic, :2059)
arc      24   (-12..+12); the +-23 lateral offset makes the pair separate wider than the angle
timing   8,1x9,10,10,10,0,0   (~48 tics; the flames leave last, on two 0-tic frames)
damage   RS_DarkFlameVile has no Damage property; it does A_Explode(random(4,20),32)
         FIVE times per Fly-loop pass (FX:2150, :2154, :2158, :2162, :2166) and
         the loop repeats until it hits something
type     Fire
sound    payload SeeSound "Bvile/Air1"
impact   Death: `FTRA GHIJ 2 A_SpawnItemEx("RS_DFlameBoomVile", random(-128,128),
         random(-128,128), random(1,32))` -- FOUR frames, so four boomlets
         scattered over a 256x256 box, each A_Explode(random(12,42),42) plus
         "weapons/rocklx" (FX:2252). It also lays RS_DarkFlameTrailVile x4 --
         see that row; the trail RESURRECTS.
trigger  Missile (A_Jump(256,"GroundFlame","Balls","Summon") at :2028)
range    --
mirrored yes  (the pair IS the mirror: (3,23,12) / (3,-23,-12), CMF_AIMDIRECTION)
inherit  --
profile  MakeVolley("RS_DarkFlameVile", count:2, arc:24, profName:"black_groundflame")
         + gap: no field for the +-23 lateral spawn offset, and none for CMF_AIMDIRECTION
                (fire along facing, do not aim) -- so a port auto-leads when CH does not.
notes    CMF_AIMDIRECTION means the angle is taken from the vile's facing rather
         than from an aim solution -- these do NOT auto-lead the player, they
         are two +SEEKERMISSILE floorhuggers launched sideways that then home
         in via A_SeekerMissile(0..1, 1..3). Slow (Speed 7) and inevitable.
         Damage is unbounded-ish: 5 blasts per loop pass, looping until impact.
```

RS_BlackVile has **no Heal state** -- See uses plain `A_Chase` (:2005 etc), no
CHF_RESURRECT. It does not resurrect directly; the `RS_DarkFlameTrailVile` it
leaves behind does (row below). Confirmed against CH:4347-4499.

# TIER 11 -- RS_Whitevile  (`RS_Archvile.zs:2095`, CH Archviles.txt:5033)

```
ATTACK   RS_Whitevile.Bolts
file     zscript/monsters/archvile/RS_Archvile.zs:2276
shape    BURST
payload  RS_WVileBolt1 x4  (angles random(-1,1), 0, random(-1,1), random(-3,3))
arc      6 at the widest, effectively 0 -- this is aimed fire with jitter
timing   12,12,5,5,5,5,12,12,2   (70 tics; bolts at t=24, 29, 34, 39)
damage   RS_WVileBolt1 DamageFunction (random(10,50)), DamageType "Plasma",
         plus Death A_Explode(random(10,25),32)
type     Plasma
sound    --   (state silent); payload SeeSound "baron/attack", DeathSound "baron/shotx"
impact   A_Explode(random(10,25),32) + 4 white particles + `FBXP ABC 6 Bright`,
         a sprite prefix **proven missing in CH itself** (FX:2481, and the FX
         header) -- CH draws nothing there either
trigger  Missile, far band (A_Jump(256,"SpawnEye","EyeSees","Bolts") at :2262)
range    1500..   (A_JumpIfCloser(1500,"Choices2",true) at :2258 -- FAILING it
         routes to Choices1, which is where Bolts lives)
mirrored no
inherit  --
profile  MakeBurst("RS_WVileBolt1", count:4, delayTics:5, arc:6, profName:"white_bolts")
         p.MinRange = 1500;
notes    The cleanest BURST in the family: same angle, evenly spaced 5 tics.
         Speed 21 / FastSpeed 25. Costs the vile 10 courage (:2281).
```

```
ATTACK   RS_Whitevile.BoltVolley
file     zscript/monsters/archvile/RS_Archvile.zs:2285
shape    FAN
payload  RS_WVileBolt1 x5  (angles 6, 0, -6, -12, 12)
arc      24   (-12..+12, even 6-degree step)
timing   0,0,0,0,0   (all five on ONE tic, after a 30-tic wind-up `LMWZ EFG 10`)
damage   as Bolts -- DamageFunction (random(10,50)) Plasma + A_Explode(random(10,25),32)
type     Plasma
sound    --   (silent)
impact   as Bolts
trigger  Missile, close band (A_Jump(256,"Scream","SpawnEye","EyeSees","BoltVolley") at :2265)
range    ..1500
mirrored no  (the fan is symmetric but is written as one sequence, not a mirrored pair)
inherit  --
profile  MakeVolley("RS_WVileBolt1", count:5, arc:24, profName:"white_boltvolley")
         p.MaxRange = 1500;
notes    Same payload as Bolts, opposite delivery: a one-tic 5-wide fan instead
         of a 4-shot burst. The two together are the best A/B pair in the
         family for testing FAN vs BURST on one projectile.
         RS_WvileSpot's Ded3 (FX:2830-2834) fires this exact five-bolt fan on
         death -- see its row.
```

```
ATTACK   RS_Whitevile.EyeSees
file     zscript/monsters/archvile/RS_Archvile.zs:2314
shape    SALVO
payload  RS_WVileEye1 x5  (spawnheights 78, 64, 64, 48, 48; lateral offsets
         0, +12, -12, +24, -24; **angle 0 on all five**)
arc      --   (they are offset in SPACE, not in angle -- see notes)
timing   0,0,0,0,0   (all five on one tic, after 1 + 30 tics of wind-up)
damage   RS_WVileEye1 DamageFunction (random(10,40))
type     -- (no DamageType declared -- typeless)
sound    "Forgotten/active" (:2312); payload DeathSound "Forgotten/Attack",
         and "fire/fire1" once per Fly loop after release
impact   `TNT1 A 0 A_SetScale(1,1)` then 6 red + 4 black particles then
         `SSUL ABCD 4 Bright` -- no explosion, contact damage only (FX:2446)
trigger  Missile, both bands (Choices1 :2262 and Choices2 :2265)
range    --
mirrored no
inherit  --
profile  MakeVolley("RS_WVileEye1", count:5, arc:0, fireSnd:"Forgotten/active",
                    profName:"white_eyes")
         + gap: no field for the per-shot spawn heights or lateral offsets, and none
                for the park-then-release two-stage shape. Pair with EyeSeekers.
notes    **The third A_CustomMissile argument is spawnofs_xy, not angle** --
         `A_CustomMissile("RS_WVileEye1",64,12)` is height 64, offset 12,
         angle 0. All five are fired straight ahead and immediately
         `A_Warp(AAPTR_TARGET, 2, random(-24,24), random(42,78), ...)` onto the
         PLAYER, where they park, +NOCLIP and +SCREENSEEKER, drawing
         RS_VBtrail4 -- until the separate `EyeSeekers` row releases them.
         This is a two-stage attack and both stages must be carried.
         `user_hoho` counts parked eyes (:2319).
```

```
ATTACK   RS_Whitevile.EyeSeekers
file     zscript/monsters/archvile/RS_Archvile.zs:2325
shape    UNCLASSIFIED
payload  -- (no spawn; it commands existing RS_WVileEye1 actors)
arc      --
timing   5,0,0,0   (5 tics)
damage   -- (the damage is RS_WVileEye1's, already recorded above)
type     --
sound    --
impact   A_RadiusGive("RS_WVEyeGo",320,RGF_MISSILES,10) gives the parked eyes a
         1-max Inventory token; each eye's Seek loop reads
         `A_JumpIfInventory("RS_WVEyeGo",1,"Charge")` (FX:2431) and switches to
         Charge -> Fly: NoClip off, A_SetSpeed(21), A_SeekerMissile(21,30,
         SMF_LOOK) + A_Weave(1,1,1,1)
trigger  Missile, priority branch (`A_JumpIf(user_hoho >= 1, "EyeSeekers")` at
         :2257 -- checked BEFORE the range gate, so releasing always wins)
range    320 (the RadiusGive radius)
mirrored no
inherit  --
profile  MakeRadial(radius:320, damage:0, heal:0, profName:"white_eyerelease")
         + gap: RadialHitsAllies is the only targeting switch; there is no
                RGF_MISSILES equivalent, and no item-grant field for RS_WVEyeGo.
                A two-stage plant-then-detonate attack has no representation at all.
notes    The trigger half of EyeSees. A weapon profile that wants this needs a
         two-button shape: plant, then detonate. Costs 10 courage and one hoho.
```

```
ATTACK   RS_Whitevile.Scream
file     zscript/monsters/archvile/RS_Archvile.zs:2299
shape    UNCLASSIFIED
payload  RS_WVilequake x1 (SXF_TRANSFERPOINTERS -- inherits the vile's target)
         + RS_WhiteVileResser x15 (9 at :2301 over +-728, 6 at :2307 over +-128)
         + RS_BrightUpVile2 x8 (4 at :2302 over +-128, 4 at :2305 over +-328)
arc      --
timing   24,0,0,24,0,14,14,0,0,12,0,0,10,10,0,5,5,5,5,5,0   (~158 tics -- the
         longest single action in the family)
damage   RS_BrightUpVile2 DamageFunction (random(5,30)) plus
         A_Explode(random(1,3),32) x16 over its life (FX:2578/2580/2583)
         RS_BrightUpVile (spawned by the quake) DamageFunction (random(2,20)),
         contact only
type     -- (typeless)
sound    "Wvile/scream" at ATTN_NONE volume 2 (:2300) -- map-wide
impact   RS_WVilequake (FX:2487) Death: Radius_Quake(180,90,0,900,0), then
         A_VileTarget("RS_BrightUpVile"), then Radius_Quake(280,90,0,1200,0),
         A_VileTarget again, then Radius_Quake(300,90,0,3000,0) and a third --
         three escalating quakes 20 tics apart, each seeding a homing spirit
         that A_Warps onto the target for ~120 tics and spawns 3 more
         RS_WhiteVileResser as it goes
trigger  Missile, close band (A_Jump(256,"Scream","SpawnEye","EyeSees","BoltVolley") at :2265)
range    ..1500
mirrored no
inherit  --
profile  MakeRadial(radius:300, damage:0, profName:"white_scream")   // the quake
         + MakeSummon("RS_WhiteVileResser", count:15, cap:0, tierOffset:0)
         + MakeVolley("RS_BrightUpVile2", count:8, arc:360)
         + gap: THREE profiles and still incomplete. Nothing in the API expresses
                a Radius_Quake or its escalation (180/280/300 intensity over
                900/1200/3000 tics), nothing expresses a +-728 spawn box, and
                MakeRadial's `damage` cannot carry RS_BrightUpVile2's
                random(5,30). Three new fields minimum. UNRESOLVED #11.
notes    Three things at once and none of the closed shape words covers it, so
         UNCLASSIFIED per the spec rather than a coined word. Aborts on
         A_CheckSight("See") at :2295 and :2298 -- break line of sight in the
         first 48 tics and the whole thing cancels.
         The 728-unit resser scatter is the family's largest area effect by a
         wide margin: it seeds a ~1456x1456 box with corpse-raisers.
```

```
ATTACK   RS_Whitevile.SpawnEye
file     zscript/monsters/archvile/RS_Archvile.zs:2269
shape    UNCLASSIFIED
payload  RS_WvileSpot x3 (`LMWZ GGG 5` is THREE frames; random(-128,128) x/y,
         SXF_TRANSFERPOINTERS|SXF_SETMASTER) + RS_WhiteVileResser x3 (:2272)
arc      --
timing   10,10,5,5,5,12,12,2   (61 tics)
damage   -- (RS_WvileSpot itself is -SHOOTABLE and +INVULNERABLE)
type     --
sound    payload SeeSound "Fire/fire3"
impact   RS_WvileSpot (FX:2712) is a black totem that A_Chases the player,
         accumulating eyes; see its own rows below. Its DEATH is the attack.
trigger  Missile, both bands (Choices1 :2262 and Choices2 :2265)
range    --
mirrored no
inherit  --
profile  MakeSummon("RS_WvileSpot", count:3, cap:3, tierOffset:0, profName:"white_spots")
notes    Three invulnerable pursuers per cast, each of which grows up to seven
         eyes and then detonates into a different payload depending on how many
         it grew (FX:2803-2866). Costs 15 courage.
```

```
ATTACK   RS_Whitevile.Clippy (resurrection field)
file     zscript/monsters/archvile/RS_Archvile.zs:2175
shape    UNCLASSIFIED
payload  RS_WhiteVileResser x1 per Clippy pass (also 1 per pass in Approach
         :2209, NoWander :2218, Agro :2232, Agro2 :2245)
arc      --
timing   0 (a 0-tic spawn at the head of every movement loop)
damage   --
type     --
sound    "vile/raise" on each corpse raised
impact   RS_WhiteVileResser (FX:2589) is an INVISIBLE, -SHOOTABLE, -COUNTKILL,
         +NOCLIP, alpha-0.01 monster that runs
         `A_RadiusGive("RS_GrowRaisin",60,RGF_MONSTERS|RGF_CORPSES,1)` then
         `FTRA CDEFGH 12 Bright A_Chase(null,null,CHF_RESURRECT)` -- SIX frames
         of resurrect-chase over 72 tics, then dies
trigger  Walk   (every movement state, continuously)
range    60 (the GrowRaisin radius); resurrection uses the resser's own step box
mirrored no
inherit  --
profile  MakeSummon("RS_WhiteVileResser", count:1, cap:0, tierOffset:0,
                    profName:"white_raisefield")
         p.FireTrigger = RS_FIRE_WALK;
         + gap: the carrier is the whole mechanic and MakeSummon can express spawning
                it, but nothing expresses "this is how the monster resurrects".
notes    **The White vile does not resurrect. Its proxies do.** The vile's own
         See/Clippy/Agro states use plain A_Chase and A_FastChase with no
         CHF_RESURRECT and there is no Heal label on RS_Whitevile at all --
         a check for "does this monster raise?" that only greps the monster
         returns NO, and is wrong. The behaviour is delegated to a disposable
         invisible actor spawned every few tics, everywhere it walks.
         This is the single most important finding in this family's raise
         behaviour and it is invisible to any per-class scan.
```

Also on RS_Whitevile, recorded but not rowed as attacks: `WhatThe` (:2336) is a
pain-triggered 52-tic invisible A_Wander escape (`bNoPain = true`, translucency
to 0.01), and the `user_courage` ladder (:2176-2178) escalates the whole
movement set from cowering to `bMissileEvenMore` as it takes damage. Neither
fires anything.

# TIER 12 -- RS_CyanVile  (`RS_Archvile.zs:434`, CH Archviles.txt:921)

```
ATTACK   RS_CyanVile.Floor
file     zscript/monsters/archvile/RS_Archvile.zs:523
shape    FAN
payload  RS_IceToMeetVile1 x5  (angles 0, +33, -33, +66, -66)
         + RS_IceStartVile4 x1 (cosmetic, :521, spawnheight 64)
arc      132   (-66..+66, even 33-degree step)
timing   3,3,6,7,7,7,0,0,0,0,0   (all five released on one tic after a 40-tic wind-up)
damage   RS_IceToMeetVile1 itself: NONE. Its spawn RS_IceToMeetVile2 carries
         DamageFunction (random(1,2)), DamageType "Ice", +RIPPER
type     Ice
sound    payload RS_IceToMeetVile2 SeeSound "" (explicitly empty in CH),
         DeathSound "Ice/Hit2"; the state itself is silent
impact   RS_IceToMeetVile1 (FX:741) is a Doom-bouncing, gravity-5,
         BounceCount 99, BounceFactor 1.0 slitherer (A_CStaffMissileSlither)
         that drops RS_IceToMeetVile2 (FX:784) every 4 tics.
         RS_IceToMeetVile2 is the +RIPPER ice sheet: `CHCY ABCDFG` x9 lines
         (SIX frames each = 54 spawns) of RS_SpikeCyanRev, each
         DamageFunction (random(1,3)) Ice with A_Explode(random(0,1),6)
         (demon/RS_DemonFX.zs:153).
trigger  Missile, close band (A_Jump(256,"Classical","Floor") at :517 -- even split)
range    ..900   (A_JumpIfCloser(900,"Choice") at :514; failing it goes to Classical)
mirrored no
inherit  --
profile  MakeVolley("RS_IceToMeetVile1", count:5, arc:132, profName:"cyan_icefan")
         p.MaxRange = 900;
notes    The widest FAN in the family (132 degrees). Damage is trivial per tick
         (1-2 per rip, 1-3 per needle) but the RIPPER sheets persist for ~200
         tics each and there are five of them; total output is high and slow.
         `Bounce.Floor` re-thrusts at speed 12 (FX:773), so the shards skip
         along the floor rather than stopping.
         RS_IceStartVile4 (FX:912) is a muzzle puff -- zero damage, A_IceGuyDie
         on expiry.
```

```
ATTACK   RS_CyanVile.Classical
file     zscript/monsters/archvile/RS_Archvile.zs:532
shape    VILE
payload  RS_IceStartVile1 x1 (:532, cosmetic) + RS_IceStartVile2 x1 (:538)
         + RS_IceStartVile3 x1 (:544)
arc      --
timing   0,3,3,3,3,3,0,3,3,3,3,3,0,3,3,3,0,3,0,3,3   (~54 tics)
damage   A_VileAttack("Ice/hit", random(10,60), random(10,60), 64, **-5**, "ice")
         -- direct random(10,60); blast random(10,60) radius 64; thrust **-5**
         PLUS RS_IceStartVile2: `C3BB EF 10 A_Explode(random(1,15),64,0)` -- TWO
         frames, two blasts
         PLUS RS_IceStartVile3: `C3BB IH 10 A_Explode(random(1,15),64,0)` -- TWO
         frames, two blasts
type     ice (blast); direct hit is 'none'
sound    "Ice/hit" -- **PROVEN MISSING IN CH ITSELF**: CH's SNDINFO defines only
         `Ice/Hit2 ICEI`, so this A_VileAttack is SILENT in CH too. Kept
         verbatim, nothing substituted (RS_Archvile.zs header, and UNRESOLVED #5).
         Payload plays "Ice/Fly" (FX:847, :877).
impact   four random(1,15)/64 blasts from the two damaging ice slabs, plus the
         A_VileAttack blast on the tracer (which is RS_IceStartVile2)
trigger  Missile, both bands (A_Jump(256,"Classical","Floor") :517, and the
         fall-through at :515 when the target is beyond 900)
range    -- (both bands; the ONLY attack this monster has past 900 units)
mirrored no
inherit  --
profile  MakeRadial(radius:64, damage:<random(10,60)>, fireSnd:"Ice/hit", profName:"cyan_burn")
         + gap: RadialDamage is `int`, AND there is no thrust field at all -- so the
                NEGATIVE thrust (-5, the downward slam that makes this attack distinct)
                is silently lost. The single sharpest API gap in this family.
notes    **thrust is NEGATIVE (-5).** The engine sets
         `targ.Vel.z = thrust * 1000 / max(1, targ.Mass)`, so this SLAMS the
         target DOWNWARD instead of launching it -- the only downward vile
         thrust in the family, and a genuinely different feel. Do not
         normalise the sign.
         Three A_CheckSight escapes at :534, :540, :542 abort the chain.
         RS_IceStartVile1 (FX:827) is cosmetic; 2 and 3 are the damage.
```

```
ATTACK   RS_CyanVile.Heal
file     zscript/monsters/archvile/RS_Archvile.zs:570
shape    UNCLASSIFIED
payload  RS_CyanLSoul2 x2  (`DIA2 BB 5` is TWO frames; random(-16,16) x/y,
         z random(12,64))
arc      --
timing   0,10,2,5,5,4,2,2   (30 tics)
damage   --
type     --
sound    "vile/raise" on the corpse
impact   A_RadiusGive("RS_GrowRaisin",100,RGF_MONSTERS|RGF_CORPSES,3) at :570;
         RS_CyanLSoul2 is lostsoul/RS_LostSoul.zs:326
trigger  Walk (A_VileChase, :491 / :493)
range    100
mirrored no
inherit  --
profile  MakeRadial(radius:100, hitsAllies:true, profName:"cyan_raise")
notes    Frame-expanded: TWO souls, not one.
```

Not rowed (movement, no payload): `DashBack` (:498) -- a `ThrustThingZ(0,72,0,0)`
+ `ThrustThing(angle-180,18,0,0)` backflip, cvar-gated on `rs_ch_cyanbounce`;
`Dodger` (:504) -- A_FastChase strafing. Both are reached from See and from Pain
(:567) and shape the range bands above.

# TIER 13 -- RS_BrownVile  (`RS_Archvile.zs:253`, CH Archviles.txt:40)

```
ATTACK   RS_BrownVile.Missile
file     zscript/monsters/archvile/RS_Archvile.zs:331
shape    VILE
payload  RS_VileGroundSpikeBrown x1
arc      --
timing   1,1,1,0,1,4,5,0,6,4   (23 tics; A_VileTarget at t=13)
damage   RS_VileGroundSpikeBrown DamageFunction (random(1,10)) Melee contact,
         then A_Explode(random(60,100),32,0) x3 on eruption, then 5x
         RS_VileGroundSpikeBrown2 each with the SAME random(1,10) + 3x
         random(60,100)/32   (baron/RS_BaronFX.zs:77 and :134)
type     Melee
sound    "CASTBROW" on channel 7 (:327); "ROCKHIT1" on eruption
         (RS_BaronFX.zs:120)
impact   the runner travels ~50 tics laying dirt, then plants five
         RS_VileGroundSpikeBrown2 at `randompick(-128,-94,-76,-64,-52,-46,-32,
         32,46,52,64,76,94,128)` x and y -- an irregular five-point minefield
         around the impact, each with its own three-pulse eruption
trigger  Missile (fall-through: A_Jump(64,"CheckThem") :324 fails, then
         A_Jump(128,"HereComesThatBoi") :325 fails -- so ~37% of the time)
range    --
mirrored no
inherit  -- (RS_VileGroundSpikeBrown/2 are baron-lane classes, referenced read-only)
profile  MakeVolley("RS_VileGroundSpikeBrown", count:1, fireSnd:"CASTBROW", profName:"brown_spike")
         + gap: MakeVolley fires FROM the monster; A_VileTarget plants AT the target,
                which is a different delivery with no mode. UNRESOLVED #11.
notes    `A_VileTarget` with NO following `A_VileAttack` -- so there is no
         direct damage, no blast and no thrust from the vile itself. All the
         damage is in the payload, and it arrives on a ~50-tic delay:
         6 eruptions x random(60,100) at radius 32 is 360-600 potential.
         The single hardest delayed-area part in the family.
```

```
ATTACK   RS_BrownVile.HereComesThatBoi
file     zscript/monsters/archvile/RS_Archvile.zs:339
shape    BURST
payload  RS_BrownBoiVile x5  (SXF_SETTRACER, spawned at x+32 and
         y = +76, +32, 0, -32, -76 / z = 32, 46, 64, 46, 32)
arc      --   (spatial offsets, not angles -- see notes)
timing   1,0,3,4,9,9,9,9,9,4   (57 tics; one head every 9 tics)
damage   RS_BrownBoiVile DamageFunction (random(10,55)), DamageType "Melee",
         plus Death `MISL BC 6 Bright A_Explode(random(8,37),64)` -- TWO
         frames, two 64-radius blasts
type     Melee
sound    "ATKBROWV" (:335); each head plays "VILEBOI1" before every charge;
         payload SeeSound "spit/spit", DeathSound "weapons/rocklx"
impact   see the RS_BrownBoiVile.Missile row below -- each head is a live
         charging monster, not a projectile
trigger  Missile (A_Jump(128,"HereComesThatBoi") at :325 -- ~37% overall)
range    --
mirrored yes  (the y offsets are a symmetric +-76 / +-32 / 0 set)
inherit  --
profile  MakeSummon("RS_BrownBoiVile", count:5, cap:5, tierOffset:0,
                    fireSnd:"ATKBROWV", profName:"brown_heads")
         + gap: MakeSummon, not MakeBurst: these are live monsters, not projectiles.
                No field for the +-76 y / 32..64 z spawn diamond or the 9-tic spacing.
notes    Same facing on all five (they are A_SpawnItemEx'd, not fired), so
         BURST rather than FAN -- the spread is a diamond in the Y/Z plane, not
         an angular arc. Each head is a bouncing, floating monster that
         SkullAttacks four times over ~4 seconds and explodes when it runs out
         or touches a floor. Five of them is the family's heaviest single
         commitment.
```

```
ATTACK   RS_BrownVile.FeelIt
file     zscript/monsters/archvile/RS_Archvile.zs:378
shape    UNCLASSIFIED
payload  RS_MediCacoBrown x9 (4 at :379 -- `WICK JJJJ 1` -- and 5 at :382 --
         `WICK KKKKK 1`), cosmetic
arc      --
timing   8,8,3,1,1,1,1,3,1,1,1,1,1,2,5   (38 tics)
damage   -- (this is a SUPPORT action; it damages nothing)
type     --
sound    --   (silent)
impact   A_RadiusGive("RS_ShieldUpVile",420,RGF_MONSTERS,1) at :378 and
         A_RadiusGive("Health",1200,RGF_MONSTERS,500) at :381.
         RS_ShieldUpVile (FX:235) is a CustomInventory that, on any non-+BOSS
         recipient, spawns RS_BrownVileBuffCtl (FX:264) -- a native rebuild of
         CH's `BrownVileCommand` ACS script (CHSett.acs:193) that sets the
         recipient's DamageFactor to **0.65** for 300 tics, shoves it in a
         random direction, and then restores the original factor.
trigger  Missile, via CheckThem (A_Jump(64,"CheckThem") at :324, then eleven
         A_CheckProximity(...,320,1,CPXF_ANCESTOR|CPXF_CHECKSIGHT) tests at
         :359-:370 -- ANY live vanilla-ancestor monster within 320 routes here)
range    320 (the proximity test) / 420 (the shield radius) / 1200 (the heal radius)
mirrored no
inherit  --
profile  MakeRadial(radius:1200, damage:0, heal:500, hitsAllies:true, profName:"brown_heal")
         + MakeRadial(radius:420, hitsAllies:true)   // the 0.65 damage-factor shield
         + gap: no field for a damage-factor aura or its 300-tic duration. MakeSelfBuff
                has damageMult+duration but only for SELF, not for allies in a radius.
notes    The family's only true ALLY BUFF, and the reason RS_BrownVile is a
         support monster rather than a damage one. 500 HP to everything within
         1200 units, plus a 35% damage reduction for 5 seconds to everything
         within 420.
         Gated by sight AND by an ancestor check across eleven vanilla classes,
         so it never fires in an empty room.
```

```
ATTACK   RS_BrownVile.HealNo
file     zscript/monsters/archvile/RS_Archvile.zs:388
shape    UNCLASSIFIED
payload  RS_Drt1/2/3 x11 (cosmetic) + RS_ArchRingHelp x23
         (4 at :403, 4 at :404, 6 at :405, 9 at :406 -- all frame-expanded)
arc      360   (the dirt ring is thrown at random(0,360) from +-164 offsets)
timing   0,0,4,1x11,1x23,5,8,5,1   (~64 tics)
damage   --
type     --
sound    --   (silent)
impact   A_RadiusGive("RS_GrowRaisin",100,RGF_MONSTERS|RGF_CORPSES,3) at :388,
         then a widening RS_ArchRingHelp bloom at +-64, +-128, +-252, +-352,
         then falls THROUGH into FeelIt (:412)
trigger  Missile, via CheckThem -- the CORPSE branch. Eleven
         A_CheckProximity(...,CPXF_DEADONLY) tests at :347-:357 fire first, so
         a nearby corpse always beats a nearby ally.
range    100 (GrowRaisin) / 352 (the ring bloom)
mirrored no
inherit  --
profile  MakeRadial(radius:100, hitsAllies:true, profName:"brown_growmark")
         then chain the two RS_BrownVile.FeelIt profiles (it falls through)
         + gap: as above -- no item-grant field, and no chaining field.
notes    RS_BrownVile does NOT use A_VileChase and has no Heal state -- it
         cannot raise anything itself. What it does is MARK corpses so that
         whichever vile raises them later gets a higher tier. A "does this
         monster resurrect?" check on this class returns NO and is misleading.
         The unconditional `Goto FeelIt` at :412 means the corpse branch always
         also runs the ally buff.
```

Not rowed: `RS_BrownVile.Scripted` (:295) and `See` (:304) spawn
RS_BrownVileRock / 2 / 3 orbiters -- all four rock classes (FX:307, :361, :415,
:555) are `Projectile` with **no Damage property**, i.e. zero damage. They are
cosmetic orbiting debris, driven by `A_Warp(AAPTR_MASTER, ...)` around an
incrementing `user_angle`. Recorded here so a later pass does not mistake them
for a fourth attack.

---

# PAYLOAD-SIDE ATTACKS

These are attacks carried by classes in `RS_ArchvileFX.zs` rather than by a
monster body. Per the spec's "IMPACT CAN BE AN ATTACK" rule they get their own
rows because each is substantial; the smaller payload blasts stay in the
`impact` field of their parent row above.

```
ATTACK   RS_BrownBoiVile.Missile
file     zscript/monsters/archvile/RS_ArchvileFX.zs:186
shape    CHARGE
payload  self  (A_SkullAttack(45) x4)
arc      --
timing   6,0,6,0,0,0,0,30,6,6,6, then 6,0,6,0,0,30, then 6,0,6,0,0,0,30,
         0,0,60,0,0,0,30,0,0,60   (four charges, 30 tics of flight each,
         with 60-tic hovers between the last three)
damage   DamageFunction (random(10,55)), DamageType "Melee"  (FX:132)
type     Melee
sound    "VILEBOI1" before every charge (:183, :194, :201, :205, :210, :214)
impact   XDeath = Death (FX:224): A_SetScale(0.5,0.5), ThrustThingZ(0,12,0,0),
         A_Scream, then `MISL BC 6 Bright A_Explode(random(8,37),64)` -- TWO
         frames, two 64-radius blasts -- then A_Die
trigger  Missile (as a monster in its own right); spawned by
         RS_BrownVile.HereComesThatBoi
range    --
mirrored no
inherit  --
profile  -- no CHARGE mode exists. Nearest: MakeSummon("RS_BrownBoiVile", ...) from
         the parent, and carry the actor whole -- its A_SkullAttack(45), its four
         charges and its random(8,37)/64 death blast are all actor-side.
         + gap: RS_ATK_ has no self-as-projectile mode. UNRESOLVED #11.
notes    A_SkullAttack(45) -- the actor IS the projectile, at speed 45.
         It flips `bIsMonster = false` and `bMissile = true` before each charge
         (:184-:185) so it behaves as a missile mid-flight and as a monster
         between charges. BounceCount 1 with BounceFactor 0.05 means one dead
         thud, then Bounce.* all route to Death (:218-:223).
         Three separate `A_CheckFloor("Death")` guards and a
         `A_JumpIf(scale.x == 0.5, "Death")` self-check (:170) stop it looping.
         The only CHARGE in the archvile family.
```

```
ATTACK   RS_ABVileTentacle.Melee
file     zscript/monsters/archvile/RS_ArchvileFX.zs:1265
shape    MELEE
payload  RS_SplashAbyss2 x4  (`T6TE UVWZ 2` is FOUR frames, :1268)
arc      50   (angle random(-25,25); pitch random(-45,-5) with CMF_OFFSETPITCH)
timing   2,2,2,2,2,2,2,2,2,2,2,2,2   (26 tics)
damage   A_CustomMeleeAttack(random(1,7),"") x2 -- **six frames on the first
         line** (`T6TE JLMNOP`) and **three on the second** (`T6TE RTS`), so
         NINE melee rolls of random(1,7), not two
type     -- (default) / Ice for the spray
sound    ""  -- the A_CustomMeleeAttack sound argument is explicitly EMPTY in
         CH and in our tree. MeleeSound is not set on this actor either. Silent.
impact   RS_SplashAbyss2 -- DamageFunction (random(1,9)) Ice, gravity droplet
trigger  Melee
range    128 (MeleeRange, FX:1235)
mirrored no
inherit  RS_SplashAbyss (zombieman lane) for the spray's Spawn/Death/FX
profile  MakeMelee(range:128, fireSnd:"", profName:"tentacle_claw")
         + MakeVolley("RS_SplashAbyss2", count:4, arc:50)
         + gap: no damage field, and none for the NINE separate random(1,7) rolls --
                a port reads as one hit instead of nine.
notes    Nine weak rolls, not two strong ones -- the frame expansion changes the
         character completely (max 63 rather than max 14).
         **MeleeRange 128** is four times normal, so it reaches from well
         outside punching distance. Mass 0x7FFFFFFF -- unpushable.
```

```
ATTACK   RS_ABVileTentacle.Missile
file     zscript/monsters/archvile/RS_ArchvileFX.zs:1272
shape    SCATTER
payload  RS_SplashAbyss2 x16  (8 at :1272, 8 at :1274 -- `TNT1 AAAAAAAA 0`)
arc      50 then 30   (angle random(-25,25) then random(-15,15);
                       pitch random(-45,-5), upward)
timing   3,3,3,0,3,3,0,3   (18 tics; both volleys on 0-tic frames)
damage   RS_SplashAbyss2 DamageFunction (random(1,9)), DamageType "Ice"
type     Ice
sound    --   (silent)
impact   contact only; the BAL7 splash is inherited from RS_SplashAbyss
trigger  Missile
range    --
mirrored no
inherit  RS_SplashAbyss (zombieman/RS_ZombiemanFX.zs:707) -- RS_SplashAbyss2
         (:735) overrides only Height, Speed, DamageFunction, DamageType and
         three flags. **Its entire Spawn and Death, including the splash
         sprite, is inherited and lives in another family's file.** Reading
         RS_SplashAbyss2's body alone reports "no impact FX".
profile  MakeVolley("RS_SplashAbyss2", count:16, arc:50, pitchJitter:20,
                    profName:"tentacle_spray")
         + gap: VolleyPitchJitter is symmetric; CH's random(-45,-5) is upward-only.
                20 is a stand-in, not an equivalent.
notes    Sixteen droplets on two tics is the densest SALVO-like burst in the
         family; classified SCATTER because the angles are random rather than
         stepped. Up to twelve of these tentacles exist at once after one
         RS_AbyssVile.Tendrils cast.
```

```
ATTACK   RS_AbyssPortalVile.Missile
file     zscript/monsters/archvile/RS_ArchvileFX.zs:988
shape    UNCLASSIFIED
payload  a charge-gated ladder, one per firing:
         charge  <5 -> RS_AbyssBaronSoul     (:988)
         charge >=5 -> RS_CommonRevenant     (:991)
         charge>=10 -> RS_AbyssImp2          (:995)
         charge>=15 -> RS_AbyssDemon2        (:999)
         charge>=20 -> RS_AbyssCaco2         (:1003)
         charge>=25 -> RS_AbyssRevenant2     (:1007)
arc      --
timing   1,1,4,4,4,4,4,4,4,4,1   (35 tics per cast)
damage   -- (the summons fight; the portal itself never hits)
type     --
sound    "SYNTPORT" at ATTN_NONE volume 2 (:981) -- map-wide
impact   A_PainAttack(class,1,PAF_NOSKULLATTACK) -- the pain-elemental spawn
         verb with the charge-and-fling suppressed, so the summon simply
         appears in front and starts fighting
trigger  Missile, self-driven (`A_JumpIf(user_charge == 7/14/21, "Missile")` at
         :973-:975, from its own See loop -- it fires on a clock, not on a target)
range    --
mirrored no
inherit  --
profile  MakeSummon("RS_AbyssBaronSoul", count:1, cap:0, tierOffset:0,
                    fireSnd:"SYNTPORT", profName:"portal_summon")
         + gap: the six-step escalating ladder needs six profiles and a charge gate
                that no field provides. This one call is the first rung only.
notes    Escalating summoner: the longer it lives, the worse what comes out.
         Only reachable through RS_AbyssVile.Heal -> Portal, i.e. two jumps
         deep from a resurrection.
         Health 250, Speed 2, +NOPAIN, Scale 0.5. Death (:1010) throws 16
         RS_SplashAbyss and drops RS_HealthBundle + RS_CH_Cell.
         `PAF_NOSKULLATTACK` matters: without it the summon would be flung.
```

```
ATTACK   RS_FireBluVile.Death
file     zscript/monsters/archvile/RS_ArchvileFX.zs:1509
shape    RING
payload  RS_FireSGguy2 x12  (angles 15, 45, 75, 105, 135, 165, 195, 225, 255,
         285, 315, 345 -- an exact 30-degree ring, offset 15 degrees)
arc      360
timing   4,4,4, then 0x12, then 6,6,6   (30 tics; the ring leaves on one tic)
damage   A_Explode(random(3,10),64) x3 before the ring (`FIRE CDE 4`) and x3
         after (`FIRE FGH 6`), plus each RS_FireSGguy2:
         DamageFunction (random(5,15)) Fire on contact, and its own Death is
         `FIRE CDEEDCDE 5 A_Explode(random(3,9),64)` -- EIGHT frames -- plus
         `FIRE FGH 4 A_Explode(random(5,15),64)` -- THREE frames.
         So each of the twelve is worth ELEVEN more 64-radius blasts.
type     Fire
sound    SeeSound "imp/attack", DeathSound "imp/shotx" (both on the parent and
         on each of the twelve)
impact   see damage -- the whole class is impact
trigger  Death   (RS_FireBluVile's Spawn is two frames long and falls straight
         into Death; it is a fuse, not a projectile)
range    --
mirrored no
inherit  -- (RS_FireSGguy2 is zombieman/RS_ZombiemanFX.zs:785, referenced read-only)
profile  MakeVolley("RS_FireSGguy2", count:12, arc:360, fireSnd:"imp/attack",
                    profName:"fireblu_ring")
         p.FireTrigger = RS_FIRE_DEATH;
         + gap: no field for the 15-degree ring offset. Cosmetic here (a full ring),
                but it is data and it is being dropped.
notes    The textbook "impact is an attack" case for this family: the parent's
         own row (RS_FireBluArch2.Missile) would read as a plain A_VileAttack
         and miss a 12-way ring of secondary fireballs each carrying eleven
         more area blasts. Two RS_FireBluVile are planted per cast, so 24
         fireballs and ~270 blast events per Missile.
         Speed 1 / FastSpeed 1 -- the parent does not travel; it detonates
         where A_VileTarget put it.
```

```
ATTACK   RS_ROCKDROPVILE.Death
file     zscript/monsters/archvile/RS_ArchvileFX.zs:1473
shape    RING
payload  RS_WDRock4 x19  (angle random(-359,359) each -- `TNT1 AAAAAAAAAAAAAAAAAAA 0`
         is NINETEEN frames)
arc      360
timing   0,0,0,1,0   (the whole death is 1 tic)
damage   A_Explode(random(60,115),64,0) at :1473, plus each RS_WDRock4:
         DamageFunction (random(5,20)), DamageType "Melee"
         (demon/RS_DemonFX.zs:879)
type     Melee
sound    DeathSound "moloch/thud"; each pebble SeeSound "monster/hamflr",
         DeathSound "Butcher/melee"
impact   pebbles die to `JUBD DD 1 A_SpawnItemEx("RS_Drt3",...)` -- dirt only,
         no secondary blast
trigger  Death   (it is +TOUCHY with a single Hexen bounce, so it dies on the
         first thing it touches)
range    --
mirrored no
inherit  --
profile  MakeBurst("RS_WDRock4", count:19, delayTics:0, arc:360,
                   trigger:RS_FIRE_DEATH, fireSnd:"moloch/thud", profName:"gray_shrapnel")
notes    The falling boulder of RS_GrayArch2.Missile. random(-359,359) is a full
         circle with a 1-degree dead spot; recorded as written rather than
         normalised to random(0,359).
         Speed 42 on the pebbles -- they travel, they are not decoration.
```

```
ATTACK   RS_PurpleWorry2.Spawn
file     zscript/monsters/archvile/RS_ArchvileFX.zs:1742
shape    RING
payload  RS_TheBangers x8 by A_CustomMissile (four `SBFX HI`/`SBFX JK` lines,
         TWO frames each) + x16 by A_SpawnItemEx (four `TNT1 AAAA 0` lines),
         **per loop pass**
arc      360   (A_CustomMissile angle random(-180,180); A_SpawnItemEx angles
         random(0,90) / random(90,180) / random(180,270) / random(270,359) --
         one quadrant per line, so the sixteen tile the circle)
timing   5,5,0,5,5,0,5,5,0,5,5,0,2   (42 tics per pass, then A_Jump(65,"Death")
         -- ~25% exit, so it averages ~4 passes = ~96 bangers)
damage   RS_TheBangers DamageFunction (random(1,8)), DamageType "Plasma"
type     Plasma
sound    SeeSound "Spell/SpellCast1" on the emitter; each banger SeeSound
         "caco/attack", DeathSound "caco/shotx"
impact   RS_TheBangers (FX:1759) is +SEEKERMISSILE with A_SeekerMissile(4,5),
         Hexen bounce x4 at BounceFactor 1 / WallBounceFactor 1.1.
         On Death it does NOT explode -- it flips `bIsMonster = true`,
         `bNoTarget = true`, A_SetSpeed(1) and jumps to a `See` state running
         `A_Chase(null,null,CHF_RESURRECT)` (FX:1802). **A dead banger
         resurrects corpses**, and its `Heal` state is
         `BAL2 DE 4 Bright A_Explode(random(2,8),88)` -- TWO frames, two
         88-radius blasts, fired when it succeeds.
         Death of the emitter (:1752) additionally A_Bursts into more bangers.
trigger  Spawn   (the whole class is one long attack; it is planted by
         RS_PurpleArch.Classic2's second A_VileTarget)
range    --
mirrored no
inherit  --
profile  MakeBurst("RS_TheBangers", count:24, delayTics:5, arc:360,
                   trigger:RS_FIRE_SPAWN, fireSnd:"Spell/SpellCast1",
                   profName:"purple_bangers")
         + gap: no repeat/loop field -- CH runs this until a 65/256 roll ends it, so
                one MakeBurst is ~one quarter of the real output.
notes    The most projectiles per second in the family. Damage per banger is
         trivial (1-8) but there are ~96 of them, they seek, they bounce four
         times, and each one that dies becomes a corpse-raiser that explodes
         twice when it raises something.
         The A_Explode(random(2,8),88) is in the **Heal** state, so it only
         fires on a successful resurrection -- easy to miss.
```

```
ATTACK   RS_DarkFlameVile.Fly
file     zscript/monsters/archvile/RS_ArchvileFX.zs:2150
shape    SINGLE
payload  self (a seeker) + RS_DarkFlameTrailVile x1 and RS_DFlamePuffVile x1
         per Fly sub-beat (five of each per loop pass)
arc      --
timing   1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,0  then Loop   (10 tics per pass)
damage   A_Explode(random(4,20),32) FIVE times per loop pass (:2150, :2154,
         :2158, :2162, :2166) -- unbounded until it hits something
type     Fire
sound    SeeSound "Bvile/Air1"
impact   Death (:2170): `FTRA GHIJ 2 A_SpawnItemEx("RS_DFlameBoomVile",
         random(-128,128), random(-128,128), random(1,32))` -- FOUR frames, so
         four boomlets over a 256x256 box, each
         `MISL B 8 Bright A_Explode(random(12,42),42)` + "weapons/rocklx"
         (FX:2252). Plus four more RS_DarkFlameTrailVile at :2172.
trigger  Missile (fired by RS_BlackVile.GroundFlame at :2064 / :2065)
range    --
mirrored no
inherit  --
profile  MakeHeavy("RS_DarkFlameVile", spawnHeight:3, profName:"black_darkflame")
         + gap: the seeking and the five-per-pass A_Explode loop live on the actor, not
                on the profile -- which is correct, but means the profile alone tells you
                nothing about its damage. Carry the actor.
notes    +FLOORHUGGER, -NOGRAVITY, +SEEKERMISSILE, Speed 7, Scale 1.5. It
         crawls along the floor toward you pulsing five times every 10 tics.
         Total damage is a function of how long you let it live, which is the
         point of the part.
```

```
ATTACK   RS_DarkFlameTrailVile.See  (resurrection)
file     zscript/monsters/archvile/RS_ArchvileFX.zs:2211
shape    UNCLASSIFIED
payload  RS_DFlamePuffVile x1 per pass (cosmetic)
arc      --
timing   0,0,8,8,8,8,8,8,3,3   (~54 tics of life)
damage   `Damage 2` (a bare constant, FX:2194), DamageType "Fire"
type     Fire
sound    --   (silent)
impact   A_RadiusGive("RS_GrowRaisin",60,RGF_MONSTERS|RGF_CORPSES,1) at :2210,
         then `FTRA CDEFGH 8 Bright A_VileChase` -- SIX frames of
         resurrect-chase; its Heal state (:2217) is two frames and then A_Die
trigger  Walk (it spawns already in See and never stops)
range    60 (GrowRaisin); resurrection uses its own step box
mirrored no
inherit  --
profile  MakeSummon("RS_DarkFlameTrailVile", count:1, cap:0, tierOffset:0,
                    profName:"black_raisefield")
         p.FireTrigger = RS_FIRE_WALK;
         + gap: as above; the Damage 2 contact and the 60-unit GrowRaisin graft are
                actor-side and invisible to the profile.
notes    **The Black vile's flame trail resurrects.** RS_BlackVile has no Heal
         state and no CHF_RESURRECT anywhere in its own body, so a
         monster-only scan says it does not raise. It does -- through the
         litter its GroundFlame attack leaves behind, five nodes per
         RS_DarkFlameVile loop pass. Exactly the same delegation pattern as
         RS_Whitevile's RS_WhiteVileResser.
         Health 9999, -SHOOTABLE, +NOCLIP, Mass 90000 -- unkillable and
         unpushable for its 54 tics.
```

```
ATTACK   RS_WvileSpot.Missile / V1..V7
file     zscript/monsters/archvile/RS_ArchvileFX.zs:2770
shape    UNCLASSIFIED
payload  a seven-step alternating ladder:
         V1 -> RS_WVileEye2 at ( 2,  16, 18)    (:2770)
         V2 -> RS_WVileEye3 at ( 2,  -6, 32)    (:2775)
         V3 -> RS_WVileEye2 at ( 2,  48, 46)    (:2780)
         V4 -> RS_WVileEye3 at (-2, -24, 64)    (:2785)
         V5 -> RS_WVileEye2 at ( 2,  32, 78)    (:2790)
         V6 -> RS_WVileEye3 at ( 2, -32, 78)    (:2795)
         V7 -> RS_WVileEye2 at ( 2,   0, 90)    (:2800)
arc      --
timing   5,3,1 per step, then back to Charge (21 tics per Charge pass)
damage   -- (the eyes are +INVULNERABLE, Speed 0, and never attack)
type     --
sound    SeeSound "Fire/fire3"; the eyes SeeSound "vile/active"
impact   nothing until it dies -- the eyes are a COUNTER, drawn as a growing
         totem of floating eyeballs
trigger  Missile (self-driven; it is a monster with its own AI)
range    --
mirrored no
inherit  --
profile  MakeSummon("RS_WVileEye2", count:1, cap:7, tierOffset:0, profName:"wvilespot_eyes")
         + gap: the eyes alternate between two classes and are a visible AMMO GAUGE,
                not minions. cap:7 is the only part that transfers.
notes    This is a visible ammo gauge for the death payload below. It also
         drops RS_WhiteVileResser every Charge pass (:2761) and dies on its own
         after 20 of them (`A_JumpIf(user_ded >= 20, "Death")` at :2763).
         `user_count` is toggled 0/1 at Set (:2751, CH's
         `A_SetUserVar("user_count",user_count==0)`), which is why the ladder
         can start at V2.
```

```
ATTACK   RS_WvileSpot.Death (payload table)
file     zscript/monsters/archvile/RS_ArchvileFX.zs:2803
shape    UNCLASSIFIED  (the table); its two damaging branches are rowed below
payload  by eye count at death (:2805-:2811):
         >=1 Ded1 -> RS_MrBones           (:2818)
         >=2 Ded2 -> RS_PurpleLSoul       (:2824)
         >=3 Ded3 -> 5x RS_WVileBolt1     (:2830-:2834)   <- FAN, see below
         >=4 Ded4 -> RS_CommonRevenant    (:2840)
         >=5 Ded5 -> RS_PurpleRevenant    (:2846)
         >=6 Ded6 -> RS_RedRevenant       (:2852)
         >=7 Ded7 -> 8x A_CustomRailgun   (:2858-:2865)   <- HITSCAN, see below
         0        -> nothing but A_KillChildren
arc      --
timing   4,4,4,4 then the branch   (16 tics before the payload)
damage   branch-dependent
type     branch-dependent
sound    --
impact   every branch ends with
         A_KillChildren("extreme",KILS_FOILINVUL|KILS_KILLMISSILES), which
         removes its own eyes
trigger  Death
range    --
mirrored no
inherit  --
profile  -- no dispatch/table mode exists. Seven separate profiles, selected by
         eye count at death; the two damaging ones are rowed below.
         + gap: nothing expresses "pick a branch by a counter". UNRESOLVED #11.
notes    Kill it early and it drops a skull; let it grow and it opens fire.
         The gate is `>=`, checked from 7 downward, so exactly one branch runs.
```

```
ATTACK   RS_WvileSpot.Ded3
file     zscript/monsters/archvile/RS_ArchvileFX.zs:2830
shape    FAN
payload  RS_WVileBolt1 x5  (angles 6, 0, -6, -12, 12)
arc      24   (-12..+12, even 6-degree step)
timing   0,0,0,0,0   (one tic)
damage   RS_WVileBolt1 DamageFunction (random(10,50)), DamageType "Plasma",
         plus A_Explode(random(10,25),32) on impact
type     Plasma
sound    payload SeeSound "baron/attack", DeathSound "baron/shotx"
impact   as RS_Whitevile.Bolts
trigger  Death
range    --
mirrored no
inherit  --
profile  MakeBurst("RS_WVileBolt1", count:5, delayTics:0, arc:24,
                   trigger:RS_FIRE_DEATH, profName:"wvilespot_ded3")
notes    Byte-identical to RS_Whitevile.BoltVolley (:2285-:2289 vs :2830-:2834),
         including the `6, 0, -6, -12, 12` ordering, but fired on Death by a
         minion. CH duplicates it the same way (CH:4992-4996 vs CH:5216-5220).
         Same profile, different trigger.
```

```
ATTACK   RS_WvileSpot.Ded7
file     zscript/monsters/archvile/RS_ArchvileFX.zs:2858
shape    HITSCAN
payload  A_CustomRailgun x8
arc      0   (spread arg is 0)
timing   12,12,12,12,12,12,12,12   (96 tics of sustained railfire)
damage   A_CustomRailgun(random(2,10), 0, "none", "red", RGF_FULLBRIGHT, 1, 12,
         "none", 0, 0, 0, 34, 1, 15, "none", 0)
         -- damage random(2,10) per beam, spawnofs_xy 0, no puff class,
         red trail, fullbright, maxdiff 1, particle duration 12, no spawnclass,
         offset_z 0, offset_xy 0, no pitch, sparsity 34, driftspeed 1,
         spawnofs_z 15, no limit
type     -- (no damage type given)
sound    --   (A_CustomRailgun plays nothing by itself here)
impact   instant hitscan, red fullbright trail
trigger  Death
range    -- (hitscan, unlimited)
mirrored no
inherit  --
profile  MakeHitscan(fireSnd:"", spreadScale:0.0, ammoCost:0, profName:"wvilespot_rail")
         p.FireTrigger = RS_FIRE_DEATH;
         + gap: no damage field (random(2,10)), no shot count (8), no delay (12 tics),
                and no rail trail colour. MakeHitscan is a weapon-side factory and this
                is the only monster-side hitscan in the family.
notes    **The family's only hitscan.** Eight beams over 96 tics from a dying,
         invulnerable-while-alive totem that has been walking at you. Damage is
         low per beam but it cannot be dodged.
         Reached only when the spot grew all seven eyes -- so it is a
         punishment for ignoring it, and the eye count is the telegraph.
         Argument order verified against CH:5020-5027; identical.
```

```
ATTACK   RS_WhiteVileResser.See  (resurrection)
file     zscript/monsters/archvile/RS_ArchvileFX.zs:2621
shape    UNCLASSIFIED
payload  --
arc      --
timing   0,12,12,12,12,12,12,3,3   (~78 tics of life)
damage   `Damage 0` (FX:2607) -- explicitly harmless
type     --
sound    "vile/raise" on each corpse raised
impact   A_RadiusGive("RS_GrowRaisin",60,RGF_MONSTERS|RGF_CORPSES,1) at :2621,
         then `FTRA CDEFGH 12 Bright A_Chase(null,null,CHF_RESURRECT)` -- SIX
         frames over 72 tics. Its Heal state (:2625) is particles and a die.
trigger  Walk / Spawn -- spawned by RS_Whitevile.Clippy (:2175), Approach
         (:2209), NoWander (:2218), Agro (:2232), Agro2 (:2245), SpawnEye
         (:2272), Scream (:2301, :2307), by RS_WvileSpot.Charge (:2761), and by
         RS_BrightUpVile (FX:2541, :2543, :2549)
range    60 (GrowRaisin)
mirrored no
inherit  --
profile  -- this IS the carrier; it is spawned BY the profiles above, and has no
         profile of its own. Its behaviour (A_Chase CHF_RESURRECT + GrowRaisin)
         is entirely actor-side.
notes    +INVISIBLE, -SHOOTABLE, +NOCLIP, Health 9999, alpha 0.01 -- there is no
         way to stop it. Nine separate call sites across the White vile's
         movement AND its attacks, so the field is continuous everywhere it has
         been. This, not any state on RS_Whitevile, is tier 11's resurrection.
```

---

# UNRESOLVED

An honest gap is worth more than a confident guess.

**1. `C:\Users\Command\Desktop\CH` DOES NOT EXIST ON THIS MACHINE.**
Both the spec (section 4) and CLAUDE.md name it as the ground truth, and both
source files' headers cite it line by line. `ls` of `C:\Users\Command\Desktop\`
returns `CHP`, `CrashReport`, `GlowInTheDark_2.6`, `GlowInTheDark_3.1`,
`TextureLights_Reignited`, `elites` and loose files -- no `CH`.
I used **`E:\New folder\ART SOURCE\CH\decorate\Archviles.txt`** (5,287 lines --
the exact length both file headers claim for the Desktop path, so it is the same
file), which CLAUDE.md separately names as the source of truth for CH's sounds,
sprites, SNDINFO, TRNSLATE and DECORATE. Every CH line number I cite is from
that copy and matched our tree's own `// CH Archviles.txt:NNNN` comments on
every class I checked. **I did not scan any drive to find CH** (per the standing
no-recursive-search rule) -- I only listed the two paths CLAUDE.md already names.
If the Desktop copy exists somewhere else and differs, nothing here is verified
against it. **Owner should confirm which path is canonical.**

**2. `E:\DXR2` does not exist either.** CLAUDE.md names it as the engine source
of truth for flags and properties. I used **`E:\UZDXREMA`**, a GZDoom-family
source tree at the top level of the same drive, whose
`wadsrc/static/zscript/actors/doom/archvile.zs`,
`src/playsim/p_enemy.cpp`, `src/common/scripting/backend/codegen.cpp` and
`wadsrc/static/zscript/constants.zs` gave the A_VileAttack / A_VileTarget /
`random()` / CMF_ facts above. **I have not verified that this is the same
engine build RS_Main runs against.** If it is not, the six "engine facts" at the
top of this file need re-checking -- particularly the `random(min>max)` swap,
which changes how `RS_RedArch3.Fires` reads.

**3. Shape vocabulary judgement calls that could make seventeen files
not compose.** Stated in full at the top; repeated here so a merge pass sees
them:
   a. I treat **`A_VileTarget` as VILE delivery**, not just `A_VileAttack`.
      24 rows in this family hinge on it. If another agent used UNCLASSIFIED
      or MULTI for the same construct, these rows must be renamed, not
      re-derived -- the payloads and line numbers are correct either way.
   b. I use a **shape precedence order** (VILE > CHARGE > HITSCAN > MELEE >
      COMBO > RAIN > MULTI > RING > FAN > SALVO > BURST > SCATTER > SINGLE)
      when two words fit. The spec does not define one.
   c. **Zero-damage co-payloads do not trigger MULTI.** Under a literal reading
      of "two or more DIFFERENT payload classes", nine of my rows would be
      MULTI instead (RedArch2.Meteorr, RedArch3.Fires, RedArch3.GroundVhirl,
      YellowArch.Fires, CyanVile.Floor, BlackVile.GroundFlame,
      GrayArch2.Missile, FireBluArch2.Missile, BrownVile.Missile). **There are
      zero MULTI rows in this file as a result** -- that is a classification
      choice, not a finding that the family has no multi-payload attacks.

**4. `CHF_RESURRECT` on projectile corpses -- behaviour not confirmed in game.**
`RS_TheBangers` (FX:1802) and `RS_ReAComet` (lostsoul/RS_LostSoulFX.zs:2010)
both flip `bIsMonster = true` on Death and then run
`A_Chase(null,null,CHF_RESURRECT)`, with a `Heal` state that explodes. CH does
the same (CH:2997, CH:3661). I have recorded it as written and reasoned about
it from `P_CheckForResurrection`, but **I have not seen a dead purple banger
raise a corpse in game**, and whether a 1-tic `BAL2 CC 2` chase window actually
finds one is a timing question source cannot answer. Rows flagged.

**5. Three sounds that resolve nowhere, in CH as well as here.** Recorded as
findings, not as our defects -- the FX file header proves each by CH's own
SNDINFO:
   * `"Ice/hit"` -- `RS_CyanVile.Classical`'s A_VileAttack (:543, CH:1029).
     CH's SNDINFO defines only `Ice/Hit2 ICEI`. That A_VileAttack is silent in
     CH too.
   * `"spike/spiked"` -- `RS_IceABVile` DeathSound (FX:1034, CH:1532). No
     `spike/` entry anywhere in CH's SNDINFO.
   * `"holy2/holy4"` -- `RS_AbyssPortalVile` SeeSound (FX:960, CH:1459). CH
     defines `Holy2/holy2` and `Holy3/holy3`, never this.
   I did **not** re-verify these against the repo's SNDINFO myself; I am
   reporting the FX file's own header claim, which cites CH. An unresolved
   sound name is completely inert (CLAUDE.md), so nothing here can fail a check.

**6. Sprite prefix `FBXP` renders nothing.** `RS_VBtrail` Spawn/Death (FX:2331,
:2334) and `RS_WVileBolt1` Death (FX:2482) name it; the FX header records that a
search of the whole CH tree returns zero FBXP lumps and that it is not an IWAD
prefix. So **RS_WVileBolt1 -- the White vile's entire Bolts / BoltVolley
payload, and RS_WvileSpot's Ded3 -- has an invisible impact effect**, in CH as
well as here. The `A_Explode(random(10,25),32)` still fires. Flagged because any
port of this attack ships with no visible hit.

**7. Damage totals I did not compute, on purpose.** Five attacks have unbounded
or loop-dependent output and I recorded the per-pulse roll and the exit
condition rather than a number: `RS_ArcRing2` (6/256 exit per pass),
`RS_DarkFlameVile` (loops until impact), `RS_RedArch2.Breath` (loops while you
stay inside 420), `RS_AbyssVile.IceIt` and `.Tangle` (A_MonsterRefire(128)
exit), `RS_PurpleWorry2` (A_Jump(65) exit). A profile builder needs the roll and
the exit, not an average.

**8. Jumps I followed but did not row, and why.** `RS_CyanVile.DashBack` /
`.Dodger`, `RS_AbyssVile.Jumpy` / `.Warp`, `RS_BlackVile.Phase`,
`RS_Whitevile.WhatThe` / `.Approach` / `.NoWander` / `.Agro` / `.Agro2` /
`.Clippy`(movement half), `RS_RedArch3.Nah`, `RS_BrownVile.CheckThem` /
`.CheckThem2`, `RS_CyanVile.Tickles`, `RS_GrayArch2.Tickles` and the other
`Tickles` states (a `RS_CHBoner` death-variant router). All are reachable from
Missile or Pain and none fires a payload. `Pain.AbyssPE` (seven monsters) is a
morph-into-RS_AbyssVile death sequence, not an attack. Listed so a later pass
can see they were opened rather than missed.

**9. `RS_SpecialVile` (`RS_Archvile.zs:1616`) has no rows of its own.** It
extends `RS_CommonArch` and overrides only `Default` and `See`, so its Missile
and Heal are **inherited verbatim** -- use the two RS_CommonArch rows, with
`MeleeRange 88`, `-COUNTKILL`, `+THRUSPECIES` and `RenderStyle "Add"` applied.
It is spawned two at a time by `RS_RedArch3.Spawn` (:1827-:1828) and leashes to
its master at 1000 units. Counted in the 15 bodies, contributes 0 new rows.

**10. Classes I read but that produced no row.** For completeness of the
denominator: `RS_ShieldUpVile`, `RS_BrownVileBuffCtl`, `RS_BrownVileRock1-4`,
`RS_WickedTorso`, `RS_IceStartVile1`, `RS_IceStartVile4`, `RS_SplashAbyssVile2`,
`RS_VileGrayDecoy` (rowed under GrayArch2.Decoy), `RS_RockVileDrop`,
`RS_RockDropvile2`, `RS_Greenening`, `RS_Greenies2`, `RS_BlueGash2`,
`RS_BlueGash3`, `RS_PurpleWorry`, `RS_SpecialRev`, `RS_BVileCloud2`,
`RS_EyeIseeViles`, `RS_BVileEye`, `RS_BVileEye2`, `RS_BvileDummy`,
`RS_DFlamePuffVile`, `RS_DFlamePuffVile2`, `RS_DFlameBoomVile`, `RS_VBtrail`,
`RS_VBtrail2`, `RS_VBtrail3`, `RS_VBtrail4`, `RS_WVEyeGo`, `RS_WVilequake`,
`RS_BrightUpVile`, `RS_BrightUpVile2`, `RS_WVileEye2`, `RS_WVileEye3`,
`RS_PsychicTangleAbyVile2`, `RS_ABVileTend`, `RS_SplashAbyssVile`,
`RS_VileGroundSpike`, `RS_VileGroundSpikes2`, `RS_IceToMeetVile1/2`,
`RS_IceStartVile2/3`, `RS_IceABVile`, `RS_PsychicTangleAbyVile`,
`RS_FireBluVile`(rowed by its Death), `RS_TheBangers`, `RS_ReABreath`,
`RS_DFire`, `RS_DarkFlameTrailVile`(rowed), `RS_WhiteVileResser`(rowed),
`RS_WVileEye1`, `RS_WVileBolt1`, `RS_ROCKDROPVILE`(rowed by its Death),
`RS_BrownBoiVile`(rowed), `RS_AbyssPortalVile`(rowed), `RS_ABVileTentacle`
(rowed), `RS_WvileSpot`(rowed), `RS_Greenening2`. Every one was opened; the
non-rowed ones are trails, markers, buff carriers or the cosmetic half of an
attack already rowed above, and their damage (where any) is recorded in the
`impact` field of the row that fires them.

**11. WHAT `RS_AttackProfile` CANNOT SAY -- 45 of 66 rows hit a wall.**
Collected from the per-row `+ gap:` lines, most-frequent first. This is the
useful output of the exercise, not a complaint: it is the shopping list.

   a. **No mode for A_VileAttack.** Its three damage numbers are one action --
      direct hit, blast, thrust -- and `MakeRadial` carries only the blast.
      All ten VILE rows lose the direct damage and the thrust. **`RS_CyanVile`'s
      thrust is -5**, a downward slam; there is no thrust field of any sign, so
      that attack cannot be distinguished from a normal one. Wanted:
      `RS_ATK_VILE` with `direct`, `blast`, `blastRadius`, `thrust`, `fireClass`.
   b. **`RadialDamage` and `RadialHeal` are `int` -- they cannot hold a roll.**
      Five rows want `random(6,32)`, `random(12,42)`, `random(6,64)`,
      `random(10,60)`, `random(5,30)`. None was flattened; each is written
      `damage:<random(a,b)>` and flagged. Wanted: a `DamageFunction`-style field,
      or min/max pair.
   c. **No item-grant field on `MakeRadial`.** Eight rows are
      `A_RadiusGive("RS_GrowRaisin", ...)` -- the tier-up mark that is this
      family's signature verb -- plus `RS_ShieldUpVile` and `RS_WVEyeGo`. The
      *entire point* of those actions is ungrantable. Wanted: `grantItem`,
      `grantAmount`, and a target filter (RGF_CORPSES / RGF_MISSILES).
   d. **No resurrection mode at all.** Eleven rows. Worse, this family
      delegates raising to disposable carrier actors
      (`RS_WhiteVileResser`, `RS_DarkFlameTrailVile`), which `MakeSummon` can
      spawn but cannot describe. Wanted: `RS_ATK_RAISE`.
   e. **`SummonClass` is one class.** Five rows need a table
      (`RS_FireBluArch2.Heal`'s six minions, `RS_GrayArch2.Heal`'s six,
      `RS_AbyssPortalVile`'s six-rung ladder, `RS_BlackVile.Summon`'s two,
      `RS_WvileSpot`'s seven-branch death table). Wanted: a weighted table, or a
      documented RandomSpawner wrapper.
   f. **`SummonCap` is `max(1, cap)` -- an uncapped summon cannot be declared.**
      Four rows are genuinely uncapped in CH.
   g. **No CHARGE mode** (`A_SkullAttack`, `RS_BrownBoiVile`) and **no RAIN
      mode** (`RS_GrayArch2.Missile`'s three-actor spawn-above-and-fall chain).
   h. **`VolleyArc` is one number.** `RS_BlackVile.Balls` widens 10 -> 24 -> 38
      across three shots and `RS_RedArch3.Fires` interleaves a 24-degree pair
      into a 360 spray; both collapse. `BurstDelayTics` is likewise one number,
      so Balls' 6/8/6 spacing collapses too.
   i. **`VolleyPitchJitter` is symmetric around 0.** Three rows use one-sided
      pitch (`random(0,90)` down, `random(-45,-5)` up). The stand-ins are marked.
   j. **No spawn-offset fields** -- lateral (`spawnofs_xy`), per-shot height, or
      a spawn BOX. Six rows need one; `RS_Whitevile.EyeSees` is *entirely* made
      of them (five eyes differing only in height and lateral offset).
   k. **No repeat/loop field.** Five rows loop until a probability roll or an
      `A_MonsterRefire`; a single call is a fraction of the real output
      (`RS_PurpleWorry2` is ~4x).
   l. **`MakeMelee` has no damage field**, only `dmgMult`. Both MELEE rows lose
      their roll, and neither can say "nine hits" or "two swings".
   m. **`MakeHitscan` is weapon-shaped** -- no damage, shot count, delay or rail
      colour. `RS_WvileSpot.Ded7` is the family's only hitscan and almost none
      of it transfers.
   n. **No quake, and no two-stage plant-then-release.** `RS_Whitevile.Scream`
      needs the first; `EyeSees`/`EyeSeekers` is the second and is one attack
      split across two rows because nothing joins them.

**12. `RS_AttackProfile.zs`, `RS_Weapon.zs` and `RS_UI.zs` are MODIFIED in the
working tree by another session right now** (`git status` at the time of
writing). I read `RS_AttackProfile.zs` read-only and wrote every `profile` line
against that working-tree state, **not** against `HEAD`. If that lane's changes
alter or rename a factory, the `profile` lines need re-checking -- the `shape`,
`payload`, `damage`, `timing` and `file:line` fields do not, since those come
from the monster files and CH. I edited nothing and staged nothing.
