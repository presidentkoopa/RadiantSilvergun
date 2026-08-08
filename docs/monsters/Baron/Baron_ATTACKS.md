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

# BARON — MONSTER ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Field order is that spec's,
unchanged. Shape words are that spec's CLOSED set; none coined.

| | |
|---|---|
| Family | baron |
| Monsters that carry attacks | **17** |
| Attack rows | **64** |
| Denominator actually read | **26 classes** in `RS_Baron.zs` (3,019 lines, read whole) + **48 classes** in `RS_BaronFX.zs` (2,003 lines, read whole) + **19 payload classes opened in other families' FX files** (see "Payloads that live elsewhere") |
| Attack state labels walked | **77** reachable attack/branch labels across the 17 monsters — every `A_Jump`, `A_JumpIfCloser`, `A_JumpIfHealthLower`, `A_JumpIfInTargetLOS`, `A_JumpIfHigherOrLower`, `A_MonsterRefire` and fall-through followed to its landing state |
| Distinct payload classes | **51** (+6 pure-cosmetic spawns, listed but not counted as payloads — see convention C1) |
| Attack call sites | **301** in the two baron files |
| CH cross-check | **clean** — see "CH agreement" |

Source files:
- `E:\RS_Main\zscript\monsters\baron\RS_Baron.zs`
- `E:\RS_Main\zscript\monsters\baron\RS_BaronFX.zs`

---

## READ THIS BEFORE ANY ROW — `A_CustomMissile` ARG 3 IS NOT AN ANGLE

Verified against the running engine, not from memory. `zscript/actors/actor.zs`
inside `D:\SteamLibrary\steamapps\Common\DooM VR\___Sourceport\qzdoom-16-RC1-Windows-64bit\qzdoom.pk3`,
line 1211 — `A_CustomMissile` is the deprecated alias of:

```
A_SpawnProjectile(class<Actor> missiletype, double spawnheight = 32,
                  double spawnofs_xy = 0, double angle = 0,
                  int flags = 0, double pitch = 0, int ptr = AAPTR_TARGET)
```

So in `A_CustomMissile("RS_WhiteBaronSlice",48,24)` the `24` is a **lateral spawn
offset in map units**, and the angle is **0**. This family is full of attacks whose
spread is *spatial*, not angular — every `RS_WhiteBaronSlice` in `Slice1` and
`Slice2`, all ten `RS_WhiteBaronSliceHoming`, all ten `RS_TentacleBall2`, and all
six `RS_WhiteBaronStar` fly **parallel**, not fanned. A reading that treats arg 3
as an angle reports a fan where there is a wall. That distinction drives the
FAN/SALVO split below.

Also verified in the same pk3:
- `constants.zs:53-60` — `CMF_AIMOFFSET = 1`, `CMF_AIMDIRECTION = 2`, `CMF_OFFSETPITCH = 32`.
- `attacks.zs:844` — `A_MeleeAttack()` → `DoAttack(true,false,MeleeDamage,MeleeSound,NULL,0)`;
  `attacks.zs:819` — damage is **`random(1,8) * MeleeDamage`**, DamageType `Melee`.
  So `MeleeDamage 10` is a roll of 10..80 in steps of 10. **Not a constant.**
- `bruiser.zs:153` — `A_BruisAttack()`: in melee range, `random(1,8)*10` with
  `"baron/melee"` / DamageType `Melee`; otherwise `SpawnMissile(target,"BaronBall")`.
- `actor.zs:1212` — `A_CustomRailgun(damage, spawnofs_xy, color1, color2, flags,
  aim, maxdiff, pufftype, spread_xy, spread_z, range, duration, sparsity,
  driftspeed, spawnclass, spawnofs_z, spiraloffset, limit, veleffect)`.

## CONVENTIONS USED HERE (stated so the seventeen files compose)

- **C1 — cosmetic spawns are not payloads.** A spawned actor with no `Damage`,
  no `DamageFunction` and no `A_Explode` anywhere in its states is recorded in
  `impact`/`notes`, never in `payload`, and never affects `shape`. Six in this
  family: `RS_BrownBaronFlame`, `RS_FrostWingBaron`, `RS_FrostWingBaron2`,
  `RS_AbyssBaronHandFire`, `RS_Zap88`, `RS_SparkPuff1` — plus three *telegraph*
  risers that are damageless but structurally load-bearing and so are named in
  `payload` with `(telegraph, 0 dmg)`: `RS_WDRock1`, `RS_BaronOfDirtCH`,
  `RS_DeepCharge1`.
- **C2 — FAN vs SALVO.** Distinct **angles** → FAN, whether or not they share a
  tic. Same angle, one tic → SALVO. Same angle, spaced in time → BURST. This
  makes the three disjoint and is the only reading under which the spec's own
  `RS_DeepTentacle` example lands where the spec says it should.
- **C3 — `A_VileTarget` is filed under VILE**, alongside `A_VileAttack`: spawned
  on the target, line-of-sight gated, no travel. Flagged in UNRESOLVED as a
  vocabulary question, because the spec names only `A_VileAttack` for VILE.
- **C4 — factory names track the shape words 1:1**: `MakeSingle`, `MakeFan`,
  `MakeBurst`, `MakeSalvo`, `MakeRing`, `MakeScatter`, `MakeMelee`,
  `MakeHitscan`, `MakeCharge`, `MakeVile`, `MakeCombo`, `MakeRain`, `MakeMulti`,
  plus `MakeSelfBuff` (named by the task) and `MakeSummon` for the two
  `A_SpawnItemEx`-of-a-monster rows, which are `shape UNCLASSIFIED`.
- **Timings are recomputed from state entry, not copied off the firing line.**
  A shot on a 9-tic frame preceded by an 8-tic frame repeats every **17** tics,
  not 9. Every `timing` below is the real inter-shot interval.

---

# CH AGREEMENT

Mechanically diffed, comments stripped, case-folded, `RS_` prefix normalised:
**all 17 monsters' attack-call sequences are identical to CH**, and **all 32
`Damage(random(a,b))` rolls plus all 5 bare `Damage N` constants match CH
exactly**. Nothing is flattened.

Two differences exist and both are the documented, intentional import decisions
already recorded in the file headers:

1. `A_SpawnItemEx("CHRandom_GibGenerator",...)` is absent from the `XDeath` of
   `RS_CommonBaron`, `RS_GreenBaron`, `RS_BlueBaron`, `RS_PurpleBaron` — the
   gore-chain strip. Replaced with `A_SpawnParticle`. Not a damage attack; no row
   is affected.
2. `RS_CommonBaron.Missile` has `RS_HKLead.FireLead(self,"BaronBall",32)` where
   CH has `ACS_NamedExecuteWithResult("BaronMissile",1)` (CHACS.acs:54) — the
   native rebuild. Same projectile, same z-offset, same speed (15, or 20 under
   `sv_fastmonsters`). Row 21 records both.

**CH path used: `E:\New folder\ART SOURCE\CH\decorate\Barons.txt`, 5,021 lines.**
The path named in the task (`C:\Users\Command\Desktop\CH`) **does not exist on
this machine**; only `C:\Users\Command\Desktop\CHP` does, and CHP is a different
pack and was not consulted. See UNRESOLVED U1.

---

# ROWS

## RS_BrownBaron2 — tier 13, "Brown Baron Boi" (the satyr)

```
ATTACK   RS_BrownBaron2.Melee
file     zscript/monsters/baron/RS_Baron.zs:301
shape    MELEE
payload  --
arc      --
timing   one tic  (swing lands 14 tics into the state; 6-tic recovery)
damage   A_CustomMeleeAttack(random(30,80))
type     Melee   (A_CustomMeleeAttack default)
sound    "skeleton/melee" on hit; miss sound explicitly "none"
impact   --   (direct hit only, no puff, no splash)
trigger  Melee
range    ..64   (MeleeRange 64; MeleeThreshold 128 keeps it out of melee above 128)
mirrored no
inherit  --
profile  MakeMelee(damage:"random(30,80)", hitSound:"skeleton/melee", missSound:"")
notes    Falls into Slam via A_JumpIfCloser(128,"Slam") after the swing, so the
         swing and the slam are consecutive beats, not alternatives.
```

```
ATTACK   RS_BrownBaron2.Slam
file     zscript/monsters/baron/RS_Baron.zs:305
shape    VILE
payload  RS_BBaronCmonAndSlam x1  (cosmetic shockwave ring, 0 dmg — floor-hugger)
arc      --
timing   one tic  (ring t=0, burn t=0, thrust t=1)
damage   A_VileAttack("bomb/boom", initial 5, blast 5, radius 128, thrust 1.75)
type     --   (A_VileAttack default, no damagetype argument given)
sound    "bomb/boom"
impact   A_RadiusThrust(3040, 400, RTF_NOTMISSILE) one tic later — a 400-unit
         no-damage shove at force 3040. This is the "slam", not the damage.
trigger  Melee   (via A_JumpIfCloser(128,"Slam") at RS_Baron.zs:302)
range    ..128
mirrored no
inherit  --
profile  MakeVile(mode:"attack", sound:"bomb/boom", initial:5, blast:5, radius:128, thrust:1.75)
notes    Damage is trivial (5+5); the attack IS the 3040-force knockback. That is
         the whole design and a profile that drops the thrust drops the attack.
         RS_BBaronCmonAndSlam (RS_BaronFX.zs:478) is a 12-tic expanding ring
         sprite with no Damage — pure tell.
```

```
ATTACK   RS_BrownBaron2.Missile
file     zscript/monsters/baron/RS_Baron.zs:318
shape    BURST
payload  RS_BaronBrownRock x2   (+ RS_BrownBaronFlame x2, cosmetic, C1)
arc      --   (angle 0 both; spawnheight 46, offset 0)
timing   12   (rocks at t=21 and t=33; flames at t=1 and t=9; 38 tics total)
damage   DamageFunction (random(10,40))
type     Melee
sound    SeeSound "monster/hamflr" on each rock
impact   A_Explode(random(10,40),64,0) + 18x RS_BrownBaronFlame2 in three 120-deg
         wedges + 8x RS_Drt2/RS_Drt3 dust. DeathSound "Butcher/melee".
         RS_BrownBaronFlame2 is itself live: random(5,20), A_Explode(random(2,10),64,0)
         on its own death. So one rock lands ~18 secondary fire pops.
trigger  Missile
range    850..   (A_JumpIfInTargetLOS(...,850,...) at :311 diverts to Spiral inside 850)
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_BaronBrownRock", count:2, delayTics:12)
notes    +SEEKERMISSILE with A_SeekerMissile(9,6) on every second flight frame —
         a hard homing rock, Speed 28, Scale 0.5.
         The two RS_BrownBaronFlame (RS_BaronFX.zs:328) are +NOINTERACTION with no
         Damage: muzzle fire at spawnofs_xy 34, not a payload.
```

```
ATTACK   RS_BrownBaron2.Spiral
file     zscript/monsters/baron/RS_Baron.zs:327
shape    SINGLE
payload  RS_BrownBaronSpiral x1
arc      --
timing   one tic  (fires at t=6, 12 tics of recovery)
damage   --   (no Damage property; all damage is the A_Explode ladder in flight)
type     --   (none set)
sound    --   (the projectile has no SeeSound; the state plays nothing)
impact   Three escalating in-flight blasts: A_Explode(random(10,20),64,0),
         then (random(10,20),94,0), then (random(10,20),128,0) — it detonates
         while travelling, not on contact. Death spawns RS_ReflectorBBaron.
trigger  Missile   (via A_JumpIfInTargetLOS("Spiral",0,JLOSF_DEADNOJUMP,850,100) at :311)
range    ..850     (and only 80/256 of the time — Spiral opens with A_Jump(176,"NoSpiral"))
mirrored no
inherit  --
profile  MakeSingle(proj:"RS_BrownBaronSpiral")
notes    THE PAYLOAD LEAVES A REFLECTOR BEHIND. Its Death spawns
         RS_ReflectorBBaron (RS_BaronFX.zs:419) at -16 x-offset: Radius 32,
         Height 56, +REFLECTIVE +DEFLECT +SHIELDREFLECT +INVULNERABLE, alive for
         20 tics. For 20 tics the player's own shots come back. That is the point
         of the attack and it is written 90 lines away from the firing site.
         Also A_RadiusGive("RS_BBaronSlowDown",64/84/64,RGF_MISSILES) three times
         — provably INERT: CH's BBaronSlow ACS (CHSett.acs:249) guards on a local
         `int Nope` that is always 0 and compared against 3. Kept as a no-op.
```

## RS_CyanBaron2 — tier 12, "Cyanide bitten BaronOfHell"

```
ATTACK   RS_CyanBaron2.Melee
file     zscript/monsters/baron/RS_Baron.zs:476
shape    MELEE
payload  --
arc      --
timing   one tic  (lands t=16, 8-tic frame)
damage   A_CustomMeleeAttack(random(10,90))
type     Melee
sound    "Baron/melee"
impact   --
trigger  Melee
range    ..64   (MeleeRange unset -> engine default 64)
mirrored no
inherit  --
profile  MakeMelee(damage:"random(10,90)", hitSound:"Baron/melee")
notes    Falls through into Missile (no Goto) after a 76/256 dodge-out to DashBack.
         Eight RS_FrostWingBaron cosmetic wing shards spawn during the windup (C1).
```

```
ATTACK   RS_CyanBaron2.Stars
file     zscript/monsters/baron/RS_Baron.zs:495
shape    SINGLE
payload  RS_BaronStarCyan x1 per pass
arc      --   (spawnheight 42, offset 0, angle 0)
timing   21 per loop  (fires t=16 of a 21-tic pass; Stars <-> Stars2 alternate)
damage   DamageFunction (random(5,25))
type     Ice
sound    SeeSound "caco/attack"
impact   DeathSound "spell/Impact1". No A_Explode — instead the death sprays
         **64** RS_SpikeCyanRev needles: 8x4 at random(12,40) speed / random(5,25)
         vspeed across four 90-deg quadrants, then 8x4 more at random(21,60) /
         random(1,15). Each needle is random(1,3) Ice with gravity 1.5.
trigger  Missile
range    ..1200 (via CheckAgain) or 1200.. (fall-through when both far-range jumps miss)
mirrored yes   (Stars2 at :510 is the identical shot on the other arm's frames)
inherit  --
profile  MakeSingle(proj:"RS_BaronStarCyan")
notes    Flight is randomised three ways by A_Jump(168,"A1","A3") inside the
         projectile: A_Weave(4,1,6,0) drift, or ThrustThing(random(0,255),random(1,12))
         scatter-kick, or dead straight. Same class, three trajectories.
         Loops itself: A_CheckSight("See") bails, A_Jump(64,"Missile") re-rolls.
```

```
ATTACK   RS_CyanBaron2.BigBlast
file     zscript/monsters/baron/RS_Baron.zs:537
shape    SINGLE
payload  RS_BaronCyanBomb x1
arc      --   (spawnheight 42, offset 0, angle 0)
timing   one tic  (fires t=28; 12 tics recovery, then FALLS THROUGH to WingBlast)
damage   DamageFunction (random(33,99))
type     Ice
sound    SeeSound "Spell/SpellCast1"
impact   A_Explode(random(2,12),32,0) **every third flight frame while travelling**,
         then Death = 9x A_Explode(random(6,12),128,0) over 45 tics at Scale 2.0.
         DeathSound "Fire/Fire4".
trigger  Missile
range    1200.. (128/256 branch) or ..1200 (via CheckAgain)
mirrored no
inherit  --
profile  MakeSingle(proj:"RS_BaronCyanBomb")
notes    **BigBlast has no Goto — it falls straight into WingBlast** (verified in
         CH at Barons.txt:766ff, same fall-through). The bomb and the twelve ice
         seekers are ONE continuous beat when this branch is taken. Kept as two
         rows because WingBlast is also reachable on its own (212/256 at :482).
         Seeker: A_SeekerMissile(6,4).
```

```
ATTACK   RS_CyanBaron2.WingBlast
file     zscript/monsters/baron/RS_Baron.zs:551
shape    FAN
payload  RS_IceSeekerBaron x12   (+ RS_FrostWingBaron2 x8, cosmetic, C1)
arc      28   (-14..+14, NON-monotone: -9,+9,-6,+6,+5,-5,-7,+7,+9,-9,-14,+14)
timing   1,1,1,1,1,1,1,1,1,1,1   (shots t=28..39; 48 tics for the whole state)
damage   DamageFunction (random(5,25))
type     Ice
sound    SeeSound "ice/Cast" per seeker (12 casts in 12 tics)
impact   A_Explode(random(10,50),64) on death, DeathSound "Ice/Hit2".
trigger  Missile
range    1200.. (212/256) or ..1200 (via CheckAgain third branch)
mirrored no   (self-mirroring: the angle list already pairs +/- )
inherit  --
profile  MakeFan(proj:"RS_IceSeekerBaron", count:12, arc:28, delayTics:1)
notes    Spawn heights AND lateral offsets vary per shot as well as angle:
         (74,15),(74,-15),(82,-25),(82,25),(76,-19),(76,19),(92,12),(92,12),
         (74,-29),(74,29),(64,-32),(64,32). A flat 12-shot fan loses the
         wing-shaped spawn envelope but keeps the angular spread.
         A_SeekerMissile(frandom(3,12),frandom(3,12),SMF_PRECISE) — the hardest
         homing in the family.
```

## RS_AbyssBaron2 — tier 9, Abyss Baron

```
ATTACK   RS_AbyssBaron2.Missile
file     zscript/monsters/baron/RS_Baron.zs:725
shape    SINGLE
payload  RS_AbyssBaronLightning x1   (+ RS_AbyssBaronHandFire, RS_Zap88 — cosmetic, C1)
arc      --   (spawnheight 38, offset 5, angle 0)
timing   one tic  (fires t=25 after a 25-tic tell; 47 tics total)
damage   DamageFunction (random(20,125))
type     Plasma
sound    A_PlaySound("brnaby3",0) at state entry; projectile SeeSound "baron/attack"
impact   A_Explode(random(20,120),128) + 12x RS_AbyssCacoZap2 static arcs thrown
         to random(-128,128) x/y. DeathSound "Litn/litn3".
trigger  Missile
range    1500..   (A_JumpIfCloser(1500,"Choice") at :715 takes everything nearer)
mirrored no
inherit  --
profile  MakeSingle(proj:"RS_AbyssBaronLightning")
notes    Speed 76 — the fastest projectile in the family. The 25-tic windup is
         the whole counterplay. The two cosmetics are the tell: a hand flame at
         t=1 and a lightning flick (RS_Zap88, cacodemon FX file) at t=8.
         64/256 chance this state is pre-empted by SoulSummon at :716.
```

```
ATTACK   RS_AbyssBaron2.Defile
file     zscript/monsters/baron/RS_Baron.zs:740
shape    VILE
payload  RS_AbyssBaronDefile x1   (+ RS_AbyssBaronHandFire, cosmetic, C1)
arc      --
timing   one tic  (A_VileTarget at t=25; 33 tics total)
damage   --   (the actor has no Damage; damage is the A_Explode ladder below)
type     --   (none set on the actor)
sound    A_PlaySound("brnaby3",0); the pool's SeeSound "Fire/fire3"
impact   A SPREADING GROUND POOL, six stages, each stage = 12 frames x 3 tics with
         A_Explode fired PER FRAME (72 detonations total, ~252 tics ≈ 7.2 s):
           random(2,30)@64 -> random(3,30)@96 -> random(4,30)@128
           -> random(5,30)@176 -> random(7,30)@232 -> random(9,30)@272
         Scale stretches 1.25 -> 2.7 on X, 0.75 fixed on Y. +FLOORHUGGER
         +THRUACTORS +FLATSPRITE. Also spits RS_SplashAbyssBubbleDemon and
         RS_AbyssShotIdentifier markers each stage.
trigger  Missile   (via Choice, A_Jump(255,"MLeftHand","Defile","SoulCharge") at :731)
range    ..1500
mirrored no
inherit  --
profile  MakeVile(mode:"target", proj:"RS_AbyssBaronDefile")
notes    This is the single largest sustained AoE in the family — a 272-radius
         area denial that lasts seven seconds and grows the whole time.
         See convention C3: A_VileTarget filed under VILE.
```

```
ATTACK   RS_AbyssBaron2.SoulCharge
file     zscript/monsters/baron/RS_Baron.zs:755
shape    SINGLE
payload  RS_AbyssBaronSoulCharge x1   (+ RS_AbyssBaronHandFire x9, cosmetic, C1)
arc      --   (spawnheight 42, offset 0, angle 0)
timing   one tic  (fires t=49 after a 49-tic windup; 64 tics total)
damage   DamageFunction (random(20,90))
type     Melee
sound    A_PlaySound("brnaby3",0) at t=49; projectile SeeSound "Spell/SpellCast1"
impact   Death = 10x A_Explode(random(2,20),128) over 50 tics at Scale 2.
         DeathSound "Fire/Fire4". In FLIGHT it lays a trail of live
         RS_GroundRedBar (RS_BaronFX.zs:848) every cycle — a Doom-bouncing
         floor-hugger, BounceCount 999, WallBounceFactor 1.5, DamageType Fire,
         6x A_Explode(random(2,10),128) each. The trail is the real threat.
trigger  Missile   (via Choice at :731)
range    ..1500
mirrored no
inherit  --
profile  MakeSingle(proj:"RS_AbyssBaronSoulCharge")
notes    Nine cosmetic hand flames at 1-tic spacing (t=16..24) at offsets
         -30/+30/0 across heights 32/64/0 — the longest tell in the family.
         Seeker A_SeekerMissile(3,3), Speed 17. Baron hops (ThrustThingZ 14)
         after firing.
```

```
ATTACK   RS_AbyssBaron2.SoulSummon
file     zscript/monsters/baron/RS_Baron.zs:761
shape    BURST
payload  RS_AbyssBaronHandFire3 x3
arc      --   (angle 0 all three; offsets -30, 0, +30; heights 64, 76, 64)
timing   11,11   (fires t=10, t=21, t=32; 59 tics total)
damage   --   (the carrier has no Damage — it is a summoner, see impact)
type     --
sound    A_PlaySound("brnaby3",0) at state entry
impact   EACH CARRIER HATCHES A LIVE MONSTER. RS_AbyssBaronHandFire3
         (RS_BaronFX.zs:914) is Speed 1 +NOCLIP, dies after 32 tics, and its
         Death spawns RS_AbyssBaronSoul at z+32. RS_AbyssBaronSoul
         (RS_PainElementalFX.zs:745) is a Monster: Health 30, Speed 30,
         +FLOAT +FLOATBOB +LOOKALLAROUND +THRUACTORS, -COUNTKILL, DamageType Ice.
         It chases, and on Melee OR Death runs Boom: A_Explode(random(20,80),128)
         + "weapons/rocklx" + A_Die. A homing suicide bomb x3.
trigger  Missile   (64/256 at :716 from far range, 18/256 at :730 from near)
range    --   (reachable from both range bands)
mirrored no
inherit  RS_AbyssBaronSoul's kill is written in the pain-elemental FX file, not here
profile  MakeBurst(proj:"RS_AbyssBaronHandFire3", count:3, delayTics:11)
notes    A profile that stops at "3 damageless puffs" reports a lie. The payload
         is a delayed 3-way summon of seeking bombs.
```

```
ATTACK   RS_AbyssBaron2.MLeftHand
file     zscript/monsters/baron/RS_Baron.zs:775
shape    BURST
payload  RS_AbyssBaronFlare x2   (+ RS_AbyssBaronHandFire x2, cosmetic, C1)
arc      --   (angle 0 both; spawnheight 38, offsets -5 then +5)
timing   20   (flares at t=12 and t=32; 39 tics total)
damage   DamageFunction (random(13,75))
type     Plasma
sound    A_PlaySound("brnaby3",0) before each half; projectile SeeSound "weapons/firmfi"
impact   A_Explode(random(20,80),128) then a **cross of twelve
         RS_AbyssBaronHandFire2** at +-64/+-128/+-232 on both axes, each of which
         runs 8x A_Explode(random(1,7),32,0) — a 232-unit plus-sign of small
         Ice pops. DeathSound "weapons/firex4". +THRUGHOST.
trigger  Missile   (via Choice at :731)
range    ..1500
mirrored yes  (the second flare IS the mirror: MRightHand at :778 is a fall-through)
inherit  --
profile  MakeBurst(proj:"RS_AbyssBaronFlare", count:2, delayTics:20)
notes    **MLeftHand falls through into MRightHand — there is no Goto.** MRightHand
         is not independently reachable from Choice, so the two labels are one
         two-beat attack. `A_CheckSight("See")` between them aborts the second
         flare if the player breaks line of sight.
         RS_Baron.zs:776 carries CH's own typo, sprite AZAA (no such lump anywhere
         in CH) on a 1-tic state — invisible in CH too, kept verbatim.
```

```
ATTACK   RS_AbyssBaron2.Melee
file     zscript/monsters/baron/RS_Baron.zs:789
shape    MULTI
payload  RS_SplashAbyss2 x12 then x13  (+ two A_CustomMeleeAttack swings)
arc      50   (random(-25,+25) per splash, plus CMF_OFFSETPITCH random(-25,-5) upward)
timing   swings at t=8 and t=24; each spray is one tic, immediately after its swing
damage   A_CustomMeleeAttack(random(42,99)) x2  +  DamageFunction (random(1,9)) per splash
type     Melee (swing) / Ice (splash)
sound    A_PlaySound("brnaby3",0) before each swing; hit "monster/kntswg",
         miss "skeleton/swing"; the splashes are SILENT
impact   RS_SplashAbyss2 (RS_ZombiemanFX.zs:735) has NO death FX of its own — its
         states are INHERITED WHOLE from RS_SplashAbyss (:707): BAL1 AB 12 loop
         with a 32/256 self-expire per 26-tic cycle, then a BAL7 CDE fade.
         Gravity-affected (-NOGRAVITY), Scale 0.3, Speed 34. No explosion.
trigger  Melee
range    ..64   (MeleeRange unset -> default 64)
mirrored yes   (spray 1 at spawnofs +3, spray 2 at -3)
inherit  RS_SplashAbyss  — the child overrides ONLY Default; every state is the parent's
profile  MakeMulti(parts:[ MakeMelee(damage:"random(42,99)", hitSound:"monster/kntswg",
                                     missSound:"skeleton/swing"),
                           MakeScatter(proj:"RS_SplashAbyss2", count:12, arc:50,
                                       pitch:"random(-25,-5)") ])
notes    Counted from source, not eyeballed: 12 splashes on the first swing
         (RS_Baron.zs:790), 13 on the second (:794). CH is identical.
         SHAPE IS A STRETCH — the spec defines MULTI as "two or more DIFFERENT
         payload classes" and here it is melee + one projectile class. MULTI is
         used because it is the only word that warns the reader the row carries
         more than one damage source. Flagged in UNRESOLVED U2.
         Falls through to Missile after the second spray.
```

```
ATTACK   RS_AbyssBaron2.Heal
file     zscript/monsters/baron/RS_Baron.zs:690
shape    UNCLASSIFIED
payload  RS_AbyssBaronRing x1 + RS_ArchRingHelp x4
arc      --
timing   ring at t=0; four helpers at t=14,15,16,17 (18 tics total)
damage   --   (no damage anywhere in this chain)
type     --
sound    SeeSound "Fire/fire3" on the ring
impact   RS_AbyssBaronRing (RS_BaronFX.zs:729) burns for 72 tics then, on Death,
         A_RadiusGive("RS_GrowRaisin",100,RGF_MONSTERS|RGF_CORPSES,3).
         RS_ArchRingHelp (RS_LostSoulFX.zs:1810) is an invisible crawler that
         A_RadiusGive("RS_GrowRaisin",60,...) and A_VileChase four times over
         ~12 tics, scattered to random(-128,128) x/y.
trigger  See   (A_VileChase at RS_Baron.zs:682/685 enters Heal when it resurrects)
range    --
mirrored no
inherit  --
profile  MakeSelfBuff(target:"allies", grants:"RS_GrowRaisin", radius:100,
                      extra:"resurrect via A_VileChase")
notes    NOT AN ATTACK — a resurrect-and-upgrade aura, included because it is
         reachable from See and fires actors. RS_GrowRaisin is the escalator:
         RS_CommonBaron.Raise (:1177) checks for it and, if present, replaces the
         raised baron with RS_GreenBaron; GreenBaron.Raise -> RS_BlueBaron;
         BlueBaron.Raise -> RS_PurpleBaron. The Abyss Baron raises the DEAD ONE
         TIER HIGHER. Nothing in this row is damage and nothing in the closed
         shape set describes it. Flagged in UNRESOLVED U3.
```

## RS_GrayBaron2 — tier 8, "Statue?"

```
ATTACK   RS_GrayBaron2.A1
file     zscript/monsters/baron/RS_Baron.zs:888
shape    BURST
payload  RS_BaronOfDirtCH3 x2   (+ RS_WDRock1 x2, telegraph, 0 dmg, C1)
arc      --   (boulder: spawnheight 28, offset 0, angle 0)
timing   42   (boulders at t=32 and t=74; risers at t=8 and t=50; 83 tics)
damage   DamageFunction (random(75,155))
type     Melee
sound    SeeSound "monster/hamflr" per boulder; the riser plays "moloch/step"
impact   DeathSound "moloch/thud" + 12 dirt puffs. No A_Explode — direct hit only.
trigger  Missile   (A_Jump(255,"A1","A2") at :881)
range    --
mirrored yes   (riser 1 at spawnofs +26, riser 2 at -26)
inherit  --
profile  MakeBurst(proj:"RS_BaronOfDirtCH3", count:2, delayTics:42)
notes    RS_WDRock1 (RS_DemonFX.zs:815) IS NOT A PROJECTILE — no `Projectile`,
         no Damage, +FLOAT +NOGRAVITY +NOCLIP. It rises, plays "moloch/step" and
         dies into dust. It is the 24-tic-early telegraph for each boulder and
         a profile that treats it as a payload doubles the shot count.
         The boulder: Hexen bounce x10 at factor 0.95, Gravity 0.8, Speed 20.
         A_MonsterRefire(128,"See") gates each half at 128/256.
```

```
ATTACK   RS_GrayBaron2.A2
file     zscript/monsters/baron/RS_Baron.zs:904
shape    SINGLE
payload  RS_BaronOfDirtCH2 x1   (+ RS_BaronOfDirtCH x1, telegraph, 0 dmg, C1)
arc      --   (spawnheight 32, offset 0, angle 0)
timing   one tic  (boulder at t=41; riser at t=7; 49 tics total)
damage   DamageFunction (random(70,170))
type     Melee
sound    A_PlaySound("monster/ar2sit") at t=0 and t=13; SeeSound "monster/hamflr"
impact   DeathSound "moloch/thud" + 15 dirt puffs + **38 RS_ZombieRock shrapnel**
         thrown at random(7,14) speed and random(-8,9) vspeed across a full circle.
trigger  Missile   (A_Jump(255,"A1","A2") at :881)
range    --
mirrored no
inherit  --
profile  MakeSingle(proj:"RS_BaronOfDirtCH2")
notes    Highest single-hit roll in the family, random(70,170).
         Bounce behaviour is unusual: Hexen bounce x6 factor 1.15, Gravity 0.10,
         and Bounce.Floor does ThrustThingZ(0,18,0,1) — it HOPS higher each floor
         hit — while Bounce.Wall goes straight to Death. Seeker A_SeekerMissile(3,6)/(6,3).
         `Radius_Quake(7,45,0,40,0)` at :900 shakes the screen for 45 tics.
         Sets +NOPAIN for the duration (cleared at :905).
```

## RS_FireBluBaron2 — tier 7, "How awkward!"

```
ATTACK   RS_FireBluBaron2.A1
file     zscript/monsters/baron/RS_Baron.zs:1025
shape    FAN
payload  RS_RedBBall x2 + RS_BluBBall x1  (volley 1) / RS_BluBBall x1 + RS_RedBBall x2 (volley 2)
arc      8   (angles 0, -4, +4; spawnheight 28, offset 0)
timing   22   (volley 1 at t=16, volley 2 at t=38; each volley is one tic)
damage   DamageFunction (random(10,50))   [both classes]
type     Plasma
sound    SeeSound "weapons/firbfi" per ball (3 per volley)
impact   A_Explode(random(5,20),128,0) + a 4-frame ARCB burn.
         DeathSound "weapons/hellex". DontHurtShooter true.
trigger  Missile   (A_Jump(255,"A1","A2","A3") at :1021)
range    --
mirrored yes   (volley 2 swaps which of the three is blue)
inherit  RS_BluBBall : RS_RedBBall — RS_ImpFX.zs:476 overrides ONLY the Translation.
         Identical damage, speed, sounds, death. The colour is the only difference.
profile  MakeFan(proj:"RS_RedBBall", count:3, arc:8, secondary:"RS_BluBBall")
notes    RS_RedBBall lives at RS_ImpFX.zs:438 and RS_BluBBall at :476 — the
         payloads are in the imp family's FX file, not this one.
         A_MonsterRefire(128,"See") after each volley.
```

```
ATTACK   RS_FireBluBaron2.A2
file     zscript/monsters/baron/RS_Baron.zs:1046
shape    MULTI
payload  RS_RedPower x2 + RS_RedPowerBomb x1
arc      --   (all angle 0; RedPower at spawnheight 10, bomb at 32)
timing   RedPower at t=7 and t=21; bomb at t=45 (49 tics total)
damage   RedPower: -- (see impact) / RedPowerBomb: DamageFunction (random(10,80))
type     Melee   (the bomb)
sound    A_PlaySound("monster/ar2sit") at t=0 and t=13; bomb SeeSound "Spell/SpellCast1"
impact   BOMB: Death is SPIR ABCDEDCBA with **no A_Explode** — direct hit only,
         DeathSound "Fire/Fire4", seeker A_SeekerMissile(2,2), Speed 21,
         +DONTHARMCLASS +DONTHARMSPECIES Species "BaronOfHell".
         REDPOWER IS THE AREA ATTACK: RS_RedPower (RS_BaronFX.zs:1466) is
         +NOINTERACTION with no Damage, but its Spawn runs 8 frames x
         A_SpawnItemEx("RS_ArchonSoul", random(-128,128), random(-128,218),
         random(5,45)) over 64 tics. Each RS_ArchonSoul (:1527) is a live
         Projectile that runs BFX1 ABCD 6 x A_Explode(random(5,12),32) — FOUR
         detonations each. 2 RedPower = 16 souls = **64 area detonations**
         scattered around the baron over ~4 seconds.
trigger  Missile   (A_Jump(255,"A1","A2","A3") at :1021)
range    --
mirrored no
inherit  --
profile  MakeMulti(parts:[ MakeBurst(proj:"RS_RedPower", count:2, delayTics:14),
                           MakeSingle(proj:"RS_RedPowerBomb") ])
notes    RS_RedPower reads as cosmetic at the call site and is not — it is the
         family's signature area-denial and appears in five rows (this, RedBaron1
         Bomb and Rage, RedBaron3 Bomb and BUFF). Sets +NOPAIN for the duration
         (cleared at :1051).
```

```
ATTACK   RS_FireBluBaron2.A3
file     zscript/monsters/baron/RS_Baron.zs:1039
shape    SINGLE
payload  RS_BluPowerBomb x1
arc      --   (spawnheight 40, offset 0, angle 0)
timing   one tic  (fires t=28; 34 tics total)
damage   DamageFunction (random(10,70))
type     Plasma
sound    A_PlaySound("monster/ar2sit") at t=0; SeeSound "Litn/litn3"
impact   A_Explode(random(40,80),158) inside a 6-frame BFE1 (BFG) burst at
         Scale (1.25, 0.8). DeathSound "weapons/bfgx". +EXTREMEDEATH.
trigger  Missile   (A_Jump(255,"A1","A2","A3") at :1021)
range    --
mirrored no
inherit  --
profile  MakeSingle(proj:"RS_BluPowerBomb")
notes    The nastiest travel behaviour in the family: Speed 10 (slow),
         A_SeekerMissile(12,18) (very hard homing), Hexen bounce x4 at
         BounceFactor 1.25 and WallBounceFactor 1.25 — it ACCELERATES off walls.
         Sets +NOPAIN for the duration (cleared at :1041).
```

## RS_CommonBaron — tier 1, "BaronOfHell"

```
ATTACK   RS_CommonBaron.Missile (beat 1)
file     zscript/monsters/baron/RS_Baron.zs:1138
shape    COMBO
payload  RS_BaronBall2 x1 (far)  /  none (near — direct melee)
arc      --
timing   one tic  (fires t=16)
damage   melee random(1,8)*10 = 10..80  /  missile Damage 8 (engine rolls 1d8 -> 8..64)
type     Melee (near) / Plasma (the ball's own DamageType)
sound    "baron/melee" on the melee branch; SeeSound "baron/attack" on the ball
impact   DeathSound "baron/shotx", BAL7 CDE fade, Decal "BaronScorch". No A_Explode.
trigger  Missile   (the state is labelled Melee: Missile: — one entry for both)
range    ..64 melee / 64.. missile   (A_BruisAttack's own CheckMeleeRange split)
mirrored no
inherit  RS_BaronBall2 `replaces BaronBall` (RS_BaronFX.zs:1187), so A_BruisAttack's
         hardcoded SpawnMissile(target,"BaronBall") resolves to RS_BaronBall2.
profile  MakeCombo(meleeDamage:"random(1,8)*10", meleeSound:"baron/melee",
                   proj:"RS_BaronBall2")
notes    Vanilla A_BruisAttack, verified in qzdoom.pk3 `zscript/actors/doom/bruiser.zs:153`.
         Damage is a ROLL (`random(1,8)*10`), not 40.
```

```
ATTACK   RS_CommonBaron.Missile (beat 2 — the lead shot)
file     zscript/monsters/baron/RS_Baron.zs:1141
shape    SINGLE
payload  RS_BaronBall2 x1   (named as "BaronBall"; the replacement resolves)
arc      --   (aimed by intercept solution, not by an angle argument)
timing   one tic  (fires t=40, 24 tics after beat 1; 48 tics total)
damage   Damage 8   (engine rolls 1d8 -> 8..64)
type     Plasma
sound    SeeSound "baron/attack"
impact   DeathSound "baron/shotx", Decal "BaronScorch". No A_Explode.
trigger  Missile
range    --
mirrored no
inherit  RS_BaronBall2 replaces BaronBall
profile  MakeSingle(proj:"RS_BaronBall2", aim:"lead", projSpeed:15)
notes    **PREDICTIVE AIM, NOT AIMED AT THE TARGET.** RS_HKLead.FireLead
         (RS_HellKnightFX.zs:99) solves the intercept quadratic against the
         target's velocity and fires at where it will be. Speed 15, or 20 when
         sv_fastmonsters is set. z-offset 32. No intercept solution -> straight shot.
         CH does this with ACS_NamedExecuteWithResult("BaronMissile",1)
         (CHACS.acs:54); this is the documented native rebuild — the one
         non-verbatim attack line in the family.
         Opt-out: `rs_ch_intercept == 1` diverts to Miss2 (:1144), which is just
         a second A_BruisAttack — same as beat 1, so no separate row.
         A_Jump(75,"Missile") re-enters the whole chain 75/256 of the time.
```

## RS_GreenBaron — tier 2, "Green BaronOfHell"

```
ATTACK   RS_GreenBaron.Melee
file     zscript/monsters/baron/RS_Baron.zs:1249
shape    MELEE
payload  --
arc      --
timing   one tic  (lands t=16)
damage   A_CustomMeleeAttack(random(10,65))
type     Melee
sound    "Baron/melee"
impact   --
trigger  Melee
range    ..64
mirrored no
inherit  --
profile  MakeMelee(damage:"random(10,65)", hitSound:"Baron/melee")
notes    --
```

```
ATTACK   RS_GreenBaron.Missile
file     zscript/monsters/baron/RS_Baron.zs:1255
shape    BURST
payload  RS_Spspit2 x2
arc      2   (random(-1,1) jitter per shot; spawnheight 32, offset 5)
timing   20   (shots at t=16 and t=36; 42 tics total)
damage   DamageFunction (random(10,72))
type     Plasma
sound    SeeSound "baron/attack"
impact   DeathSound "imp/shotx", BAL7 CDE fade. **No A_Explode** — direct hit only.
         Trails RS_Trail12 each cycle.
trigger  Missile
range    500..   (A_JumpIfCloser(500,"Spit",true) at :1253 takes everything nearer)
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_Spspit2", count:2, delayTics:20, jitter:1)
notes    Seeker A_SeekerMissile(2,2), Speed 25. Lives at RS_LostSoulFX.zs:1358.
         The `true` third argument to A_JumpIfCloser is noz — the range gate
         ignores height difference.
```

```
ATTACK   RS_GreenBaron.Spit
file     zscript/monsters/baron/RS_Baron.zs:1262
shape    BURST
payload  RS_Spspit3 x2
arc      2   (random(-1,1) jitter; spawnheight 32, offset 0)
timing   20   (shots at t=15 and t=35; 41 tics total)
damage   DamageFunction (random(15,60))
type     Plasma
sound    SeeSound "baron/attack"
impact   A_Explode(random(1,7),32) over 3 death frames, DeathSound "imp/shotx".
trigger  Missile   (via A_JumpIfCloser(500,"Spit",true) at :1253)
range    ..500
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_Spspit3", count:2, delayTics:20, jitter:1)
notes    **IT DRIPS POISON THE WHOLE WAY.** Every 4 tics in flight it spawns a
         live RS_GreeniesBR behind itself at random(180,210) / random(150,180)
         degrees — a trail of bouncing poison globs along its path. Each glob is
         random(1,2) Poison, Hexen bounce x3, +EXPLODEONWATER, and turns gravity
         ON after its first flight frame. Speed 12, no seeker.
```

```
ATTACK   RS_GreenBaron.Puke
file     zscript/monsters/baron/RS_Baron.zs:1268
shape    SCATTER
payload  RS_GreeniesBR x6
arc      28   (random(-6,6) x4, random(-13,13) x1, random(-14,14) x1; spawnheight 56)
timing   2,0,2,0,2   (shots at t=5, 7, 7, 9, 9, 11 — 6 shots in 7 tics)
damage   DamageFunction (random(1,2))
type     Poison
sound    SeeSound "fire/fire1" per glob
impact   DeathSound "caco/shotx", BAL2 CDE fade at 0.4 translucency. No A_Explode.
trigger  Missile   (via Spit, A_JumpIfHigherOrLower(null,"PUKE",0,-32) at :1260)
range    ..500 AND target at least 32 units BELOW the baron
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_GreeniesBR", count:6, arc:28, delayTics:1)
notes    A downhill vomit — only reachable when the target is lower. Damage per
         glob is trivial (1..2) but they bounce three times each with
         BounceFactor 1.1 / WallBounceFactor 1.1 and turn on gravity, so the
         pool persists. +EXPLODEONWATER.
         Ends with A_CheckSight("See") and A_CheckFlag("SOLID","Missile",AAPTR_TARGET).
```

## RS_BlueBaron — tier 3, "Blue Blood Baron"

```
ATTACK   RS_BlueBaron.Balls
file     zscript/monsters/baron/RS_Baron.zs:1391
shape    SCATTER
payload  RS_SmashBalls2 x2
arc      42   (shot 1 random(-5,5); shot 2 randompick of four bands spanning -21..+21)
timing   one tic   (both on 0-tic states; fires t=26 of the Missile chain)
damage   DamageFunction (random(5,35))
type     Plasma
sound    SeeSound "caco/attack"; BounceSound "Bomb/bounce"
impact   A_Explode(random(5,20),128), DeathSound "caco/shotx". **AND ON EVERY
         FLOOR BOUNCE it throws 15 RS_STracerBlue** — 5 each into random(1,120),
         random(121,240), random(241,359) degrees. Then 64/256 it turns seeker,
         12/256 it self-destructs, else it keeps bouncing. Hexen bounce x7 at
         BounceFactor 2 (it bounces HIGHER each time), WallBounceFactor 0.1.
trigger  Missile
range    ..1000   (A_JumpIfCloser(1000,"Balls",true) at :1387)
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_SmashBalls2", count:2, arc:42)
notes    Gravity 0.1, Speed 11 — a lobbed bomblet, not a bolt. Lives at
         RS_LostSoulFX.zs:1387.
         CH itself comments out two further SmashBalls2 lines here; our tree
         keeps them absent and records the fact at :1393.
```

```
ATTACK   RS_BlueBaron.Cometto
file     zscript/monsters/baron/RS_Baron.zs:1396
shape    SINGLE
payload  RS_SmashBall4 x1
arc      2   (random(-1,1); spawnheight 32, offset 5)
timing   one tic  (6-tic frame)
damage   DamageFunction (random(5,65))
type     Plasma
sound    SeeSound "caco/attack"
impact   A_Explode(random(3,20),128), DeathSound "caco/shotx". Trails RS_Blutrail1.
trigger  Missile
range    --   (taken when the target is >28 units HIGHER, via
               A_JumpIfHigherOrLower("Cometto",null,28,0,true) at :1386;
               also the 256/256 fallback at :1388 beyond 1000 units)
mirrored no
inherit  --
profile  MakeSingle(proj:"RS_SmashBall4")
notes    Anti-air and long-range in one class: seeker A_SeekerMissile(3,3),
         Speed 24, Scale 1.8, +EXPLODEONWATER.
```

## RS_PurpleBaron — tier 4, "Royal BaronOfHell"

```
ATTACK   RS_PurpleBaron.Wave1
file     zscript/monsters/baron/RS_Baron.zs:1517
shape    FAN
payload  RS_BaronWave x7
arc      18   (+1, +3, -3, +6, -6, +9, -9 — spawnheight 32, offset 5)
timing   one tic   (all seven on 0-tic states, t=11; 11-tic windup)
damage   DamageFunction (random(5,17))
type     Fire
sound    SeeSound "caco/attack" x7; BounceSound "Bomb/bounce"
impact   A_Explode(random(3,15),88) + a scale-up flash, DeathSound "caco/shotx".
         Hexen bounce x2 at WallBounceFactor 0.7. +DONTHARMCLASS.
trigger  Missile
range    ..800   (A_JumpIfCloser(800,"Wave1") at :1508; also 50/50 from Both below 900 hp)
mirrored yes   (Wave2 at :1529 is the identical 7-shot fan on the other arm,
                chained 100/256 of the time by A_Jump(100,"Wave2") at :1524)
inherit  --
profile  MakeFan(proj:"RS_BaronWave", count:7, arc:18)
notes    The angle list is NOT an even step: +1 sits where a symmetric fan would
         put 0, so the whole spread is biased one degree right. Recorded as
         written. Speed 21 / FastSpeed 50 — it more than doubles on fast monsters.
         Lives at RS_LostSoulFX.zs:1504.
```

```
ATTACK   RS_PurpleBaron.Spearthingy
file     zscript/monsters/baron/RS_Baron.zs:1540
shape    BURST
payload  RS_Spear11 x2   (+ RS_Zap88 x1, cosmetic, C1)
arc      --   (angle 0 both; spawnheight 38, offsets +5 then -5)
timing   22   (spears at t=12 and t=34; zap tell at t=0; 39 tics total)
damage   DamageFunction (random(10,85))
type     Plasma
sound    A_PlaySound("Litn/litn2") at t=0; SeeSound "baron/attack" per spear
impact   DeathSound "Litn/litn3" + **3x A_SpawnItemEx("RS_Zap88")** on the death
         frames — a lightning splash, but no A_Explode, so it is direct-hit only.
         Trails RS_TrailB.
trigger  Missile
range    800..   (fallback at :1509 when not closer than 800; or 50/50 via Both below 900 hp)
mirrored yes   (spear 1 at offset +5, spear 2 at -5)
inherit  --
profile  MakeBurst(proj:"RS_Spear11", count:2, delayTics:22)
notes    Speed 42 / FastSpeed 68 — near-hitscan. RS_Zap88 (RS_CacodemonFX.zs:66)
         is +NOINTERACTION with no Damage: the muzzle arc, not a payload.
         A_Jump(115,"Missile") re-rolls the whole Missile chain 115/256.
         Lives at RS_LostSoulFX.zs:1542.
```

## RS_YellowBaron — tier 5, "Grand Orange BaronOfHell"

```
ATTACK   RS_YellowBaron.Melee
file     zscript/monsters/baron/RS_Baron.zs:1666
shape    MELEE
payload  --
arc      --
timing   one tic  (lands t=16)
damage   A_CustomMeleeAttack(random(10,90))
type     Melee
sound    "Baron/melee"
impact   --
trigger  Melee
range    ..64
mirrored no
inherit  --
profile  MakeMelee(damage:"random(10,90)", hitSound:"Baron/melee")
notes    Falls straight through into Missile (no Goto) — the swing always
         chains into a ranged branch.
```

```
ATTACK   RS_YellowBaron.StarShot
file     zscript/monsters/baron/RS_Baron.zs:1685
shape    SINGLE
payload  RS_BaronStar x1  (StarShot) / RS_BaronStar2 x1  (StarShot2)
arc      --   (angle 1, spawnheight 32, offset 3)
timing   20 per loop  (fires t=12 of a 20-tic pass; StarShot <-> StarShot2 alternate)
damage   DamageFunction (random(5,25))   [both classes]
type     Fire
sound    SeeSound "caco/attack"
impact   RS_BaronStar: 2x A_Explode(random(5,25),108) then 3x A_Explode(random(5,30),108).
         RS_BaronStar2: 2x + 3x A_Explode(random(5,30),108).
         Both DeathSound "spell/Impact1". Both +DONTHARMCLASS, Species "BaronOfHell".
trigger  Missile   (via RumbleIT, A_Jump(255,"StarShot","FireBlast") at :1681)
range    ..1000
mirrored yes   **and the mirror is a different class** — RS_BaronStar weaves
               A_Weave(4,1,6,0), RS_BaronStar2 weaves A_Weave(-4,-1,-6,0).
               Same damage, same speed, opposite drift.
inherit  --
profile  MakeSingle(proj:"RS_BaronStar", mirrorProj:"RS_BaronStar2")
notes    One row, not two: the spec's OtherB rule. The alternation is enforced by
         Goto, so a sustained volley genuinely alternates left-weave and
         right-weave stars and the pair braids in the air.
         RS_BaronStar lives at RS_LostSoulFX.zs:1629; RS_BaronStar2 at
         RS_BaronFX.zs:1390 (seeker 5,5 vs the first's 3,3).
         A_MonsterRefire(80,"See") gates each pass at 80/256.
```

```
ATTACK   RS_YellowBaron.FireBlast
file     zscript/monsters/baron/RS_Baron.zs:1697
shape    SINGLE
payload  RS_BaronFbomb x1   (+ RS_BaronRing x1, cosmetic, C1)
arc      --   (spawnheight 32, offset 3, angle 0)
timing   one tic  (bomb at t=33; ring tell at t=0; 45 tics total)
damage   DamageFunction (random(10,70))
type     Fire
sound    SeeSound "spell/spellcast1"
impact   **EIGHT SEEKING STARS PLUS THREE BLASTS.** Death fires 8x
         RS_BaronStar3 at random(0,360) angle AND random(0,360) pitch
         (CMF_AIMOFFSET), interleaved with 3x A_Explode(random(5,30),155).
         DeathSound "spell/Impact1". Each RS_BaronStar3 (RS_HellKnightFX.zs:833)
         is random(5,30) Fire, seeker A_SeekerMissile(3,3), and its own death is
         2x A_Explode(random(5,20),148) + 3x A_Explode(random(5,30),148).
trigger  Missile   (via RumbleIT at :1681)
range    ..1000
mirrored no
inherit  --
profile  MakeSingle(proj:"RS_BaronFbomb")
notes    This is a cluster bomb with a homing submunition — the largest
         damage-per-shot chain in the family once the eight stars are counted.
         Seeker itself, Speed 19 / FastSpeed 38, Species "BaronOfHell"
         +DONTHARMCLASS. Sparks RS_SparkPuff1 in flight (cosmetic, C1).
         RS_BaronRing (RS_ImpFX.zs:388) has no Damage — it is a gravity-affected
         ring sprite that falls to the floor. Telegraph only.
```

```
ATTACK   RS_YellowBaron.FireSummon
file     zscript/monsters/baron/RS_Baron.zs:1703
shape    VILE
payload  RS_BigBadFire1 x1   (+ RS_FireHand1 x1, cosmetic, C1)
arc      --
timing   one tic  (A_VileTarget at t=26; 39 tics total)
damage   --   (no Damage property; damage is the A_Explode loop below)
type     Fire
sound    RS_FireHand1 SeeSound "fire/fire4" at t=0 (the tell)
impact   A pillar of fire ON THE TARGET. Spawn loops FLUM AB + FLUM CD, each
         frame running **A_Explode(5,25)** — 4 flat-5 blasts at radius 25 per
         12-tic cycle — with a 104/256 chance to end each cycle. Death:
         A_Explode(random(4,10),64) + 5x RS_FireSpe1. DeathSound "Fire/fire5",
         Scale 1.5.
trigger  Missile   (255/256 at :1674)
range    1500..
mirrored no
inherit  --
profile  MakeVile(mode:"target", proj:"RS_BigBadFire1")
notes    A_Explode(5,25) is a FLAT CONSTANT in CH, not a roll — recorded as CH
         wrote it. The roll is only on the death blast.
         RS_BigBadFire1 is defined in this family's FX file (RS_BaronFX.zs:254)
         but its CH home is Revenants.txt:2578; RS_FireHand1 (:230) is
         Revenants.txt:2556. Both are third-file externals this lane owns.
         See convention C3 for A_VileTarget under VILE.
```

## RS_RedBaron1 — tier 6 phase 1, "Red Rage Baron"

```
ATTACK   RS_RedBaron1.Trio
file     zscript/monsters/baron/RS_Baron.zs:1812
shape    FAN
payload  RS_RedBBall x3
arc      8   (0, -4, +4; spawnheight 28, offset 0)
timing   22   (Trio volley t=16, Trio2 volley t=38 — each volley is one tic)
damage   DamageFunction (random(10,50))
type     Plasma
sound    SeeSound "weapons/firbfi" x3 per volley
impact   A_Explode(random(5,20),128,0), DeathSound "weapons/hellex".
         +THRUGHOST, DontHurtShooter true, Species "BaronOfHell".
trigger  Missile   (A_Jump(128,"Trio") at :1806, then A_Jump(255,"Trio","Bomb") at :1808)
range    --
mirrored yes   (Trio2 at :1819 is the identical volley on the other arm)
inherit  --
profile  MakeFan(proj:"RS_RedBBall", count:3, arc:8)
notes    Trio -> Trio2 -> Missile is a hard chain, so a sustained engagement is a
         continuous 3-round volley every 22 tics. A_MonsterRefire(128,"See")
         breaks it at 128/256 after each volley.
         RS_RedBBall lives at RS_ImpFX.zs:438.
```

```
ATTACK   RS_RedBaron1.Bomb
file     zscript/monsters/baron/RS_Baron.zs:1827
shape    MULTI
payload  RS_RedPower x2 + RS_RedPowerBomb x1
arc      --   (all angle 0; RedPower spawnheight 10, bomb spawnheight 10)
timing   RedPower at t=7 and t=21; bomb at t=45 (49 tics total)
damage   RedPower: -- (see impact) / RedPowerBomb: DamageFunction (random(10,80))
type     Melee   (the bomb)
sound    A_PlaySound("monster/ar2sit") at t=0 and t=13; bomb SeeSound "Spell/SpellCast1"
impact   Bomb: seeker A_SeekerMissile(2,2), Speed 21, Death is SPIR ABCDEDCBA with
         **no A_Explode** — direct hit only. DeathSound "Fire/Fire4".
         RedPower: 8 RS_ArchonSoul each, each running 4x A_Explode(random(5,12),32)
         at a random point within (+-128, -128..218, 5..45) of the baron.
         2 RedPower = 64 scattered detonations over ~4 seconds.
trigger  Missile   (A_Jump(255,"Trio","Bomb") at :1808)
range    --
mirrored no
inherit  --
profile  MakeMulti(parts:[ MakeBurst(proj:"RS_RedPower", count:2, delayTics:14),
                           MakeSingle(proj:"RS_RedPowerBomb") ])
notes    Structurally identical to RS_FireBluBaron2.A2 except the bomb spawns at
         height 10 instead of 32. Sets +NOPAIN for the duration (cleared at :1832).
```

```
ATTACK   RS_RedBaron1.Melee
file     zscript/monsters/baron/RS_Baron.zs:1837
shape    MELEE
payload  --
arc      --
timing   swing 1 t=16, swing 2 t=38, swings 3+4 t=54 (same tic)
damage   A_MeleeAttack() -> **random(1,8) * MeleeDamage 10 = 10..80** per swing
type     Melee
sound    MeleeSound "baron/melee"
impact   --
trigger  Melee
range    ..64
mirrored yes   (swing 2 uses the mirrored IJ/K frames)
inherit  --
profile  MakeMelee(damage:"random(1,8)*10", hitSound:"baron/melee", chain:[128,64])
notes    **1 TO 4 SWINGS, PROBABILISTICALLY CHAINED.** A_Jump(128,1) at :1839 and
         A_Jump(64,1) at :1844 skip the intervening `Goto See` — so swing 2
         happens 128/256 of the time and swings 3+4 happen 64/256 after that.
         Swings 3 and 4 land on the SAME TIC (a 0-tic A_MeleeAttack at :1847
         followed immediately by a 3-tic one at :1848) — a double hit worth
         20..160. That 0-tic line is easy to read as a duplicate; it is not.
         Damage is a roll. `MeleeDamage 10` is NOT 10 damage; it is the multiplier.
```

```
ATTACK   RS_RedBaron1.Rage
file     zscript/monsters/baron/RS_Baron.zs:1877
shape    UNCLASSIFIED   (self-buff)
payload  RS_RedPower x2
arc      --   (angle 0; spawnheight 10)
timing   RedPower at t=5 and t=22 (32 tics total)
damage   --   (see impact — RedPower's souls)
type     Plasma  (via RS_ArchonSoul)
sound    A_PlaySound("monster/ar2sit") at t=0
impact   16 RS_ArchonSoul = 64 detonations of random(5,12) at radius 32,
         scattered around the baron over ~4 seconds.
trigger  Pain   (A_Jump(32,"Rage") at :1871 — 32/256 per pain state)
range    --
mirrored no
inherit  --
profile  MakeSelfBuff(target:"self",
                      sets:["+NOPAIN","+MISSILEEVENMORE"],
                      speed:{from:10,to:28},
                      accompany:MakeBurst(proj:"RS_RedPower", count:2, delayTics:17),
                      oncePerLife:true)
notes    WHAT IT ACTUALLY CHANGES, all three PERMANENT — none is ever undone:
           * `bNOPAIN = true`  (:1876) — cannot be staggered again, ever.
           * `bMISSILEEVENMORE = true` (:1878) — attack rate goes up sharply.
           * `A_SetSpeed(28)` (:1881) — Speed 10 -> 28, a 2.8x movement increase.
         Gated once per life by `user_rageup2` (:1874/:1882); the NAH exit at
         :1884 falls back into Missile+1.
         The two RS_RedPower are not decoration — they are 64 area detonations
         fired at the moment the baron becomes unstaggerable.
```

## RS_RedBaron3 — tier 6 boss phase 1, "Power Baron of Red"

```
ATTACK   RS_RedBaron3.Trio
file     zscript/monsters/baron/RS_Baron.zs:1982
shape    FAN
payload  RS_RedBBall x3
arc      8   (0, -4, +4; spawnheight 28, offset 0)
timing   22   (Trio volley t=16, Trio2 volley t=38)
damage   DamageFunction (random(10,50))
type     Plasma
sound    SeeSound "weapons/firbfi" x3 per volley
impact   A_Explode(random(5,20),128,0), DeathSound "weapons/hellex".
trigger  Missile   (A_Jump(255,"Trio") at :1978)
range    --
mirrored yes   (Trio2 at :1990)
inherit  --
profile  MakeFan(proj:"RS_RedBBall", count:3, arc:8)
notes    **THIS VOLLEY IS THE BOSS'S CHARGE METER.** Each half increments
         `user_buildup` (:1985 and :1993); Pain also increments it (:2043). At
         `user_buildup >= 6` the Missile entry (:1977) diverts to Bomb — the
         Archon Comet. So the comet is EARNED by six volleys or by taking pain,
         not rolled. Bomb then subtracts 5 (:2002).
```

```
ATTACK   RS_RedBaron3.Bomb
file     zscript/monsters/baron/RS_Baron.zs:2001
shape    MULTI
payload  RS_ArchonComet x1 + RS_RedPower x1
arc      --   (both angle 0; RedPower spawnheight 10, comet spawnheight 28)
timing   RedPower at t=5; comet at t=25 (36 tics total)
damage   comet: Damage 20 (engine rolls 1d8 -> 20..160) / RedPower: see impact
type     Fire (comet) / Plasma (the souls)
sound    A_PlaySound("monster/ar2sit") at t=0; comet SeeSound "weapons/firbfi";
         BounceSound "Fire/fire4"
impact   COMET: A_Explode(random(10,80),128,0), DeathSound "weapons/hellex",
         Doom bounce x4 at BounceFactor 1 and **WallBounceFactor 1.2** — it speeds
         up off walls. DontHurtShooter true, +THRUGHOST. Trails
         RS_ArchonCometTrail, which itself sprays RS_CrackoBallTrail.
         REDPOWER: 8 RS_ArchonSoul = 32 detonations of random(5,12) at radius 32.
trigger  Missile   (only when user_buildup >= 6, :1977)
range    --
mirrored no
inherit  --
profile  MakeMulti(parts:[ MakeSingle(proj:"RS_RedPower"),
                           MakeSingle(proj:"RS_ArchonComet") ])
notes    Highest single-projectile ceiling in the family: Damage 20 with the
         engine's 1d8 missile multiplier tops out at 160 before the 128-radius
         splash. Sets +NOPAIN for the duration (cleared at :2003).
```

```
ATTACK   RS_RedBaron3.BUFF
file     zscript/monsters/baron/RS_Baron.zs:2009
shape    UNCLASSIFIED   (self-buff)
payload  RS_RedPower x3
arc      --   (all angle 0; spawnheight 10)
timing   RedPower at t=5, t=19, t=38 (54 tics total)
damage   --   (see impact)
type     Plasma  (via RS_ArchonSoul)
sound    A_PlaySound("monster/ar2sit") at t=0 and t=13
impact   24 RS_ArchonSoul = **96 detonations** of random(5,12) at radius 32,
         scattered within (+-128, -128..218, 5..45) over ~6 seconds. Plus
         A_Quake(10,30,0,256,"") at :2011 — intensity 10, 30 tics, 256-unit radius.
trigger  Missile   (A_JumpIfHealthLower(1250,"BUFF") at :1975 — Health 2100, so
                    the boss buffs below ~60%)
range    --
mirrored no
inherit  --
profile  MakeSelfBuff(target:"self",
                      sets:["+NOPAIN","+MISSILEEVENMORE"],
                      speed:{from:8,to:28},
                      accompany:MakeBurst(proj:"RS_RedPower", count:3, delayTics:16),
                      quake:{intensity:10, tics:30, radius:256},
                      oncePerLife:true)
notes    WHAT IT ACTUALLY CHANGES, all PERMANENT for the rest of the fight:
           * `bNOPAIN = true` (:2008) — never staggered again. Set and never cleared.
           * `bMISSILEEVENMORE = true` (:2013) — attack rate goes up sharply.
           * `A_SetSpeed(28)` (:2016) — Speed 8 -> 28, a **3.5x** movement increase,
             the biggest speed jump in the family.
         Gated once per life by `user_rageup` (:2006/:2017); NAH at :2019 falls
         back into Missile+1.
         The three RS_RedPower make this the single densest area event in the
         family at 96 detonations.
         **This is the row the task called out.** The buff is real, it is
         permanent, and it comes with an attack attached.
```

```
ATTACK   RS_RedBaron3.Melee
file     zscript/monsters/baron/RS_Baron.zs:2025
shape    MELEE
payload  --
arc      --
timing   swing 1 t=16, swing 2 t=38, swings 3+4 t=54 (same tic)
damage   A_MeleeAttack() -> random(1,8) * MeleeDamage 10 = 10..80 per swing
type     Melee
sound    MeleeSound "baron/melee"
impact   --
trigger  Melee
range    ..64
mirrored yes
inherit  --
profile  MakeMelee(damage:"random(1,8)*10", hitSound:"baron/melee", chain:[128,64])
notes    Byte-identical to RS_RedBaron1.Melee including the same-tic double hit at
         :2035/:2036. Kept as its own row because the two monsters are separately
         spawnable and a profile referencing "the Red Baron's melee" must say which.
```

## RS_RedBaron2 — tier 6 boss phase 2, "Flying Red Baron"

```
ATTACK   RS_RedBaron2.Missile
file     zscript/monsters/baron/RS_Baron.zs:2157   (variant B at :2173)
shape    BURST
payload  RS_RedBBall2 x5
arc      --   (angle 0 all five; spawnheight 40, offset 0)
timing   VARIANT A (128/256): 5,5,5,5   — shots at t=4,9,14,19,24 (29 tics)
         VARIANT B (128/256): 7,10,7,8  — shots at t=4,11,21,28,36 (43 tics),
                                          with A_FastChase between every shot
damage   DamageFunction (random(10,55))
type     Plasma
sound    SeeSound "weapons/firbfi" per ball
impact   **FIFTEEN SUBMUNITIONS.** Death runs ARCB J x15 at 1 tic each, each frame
         firing A_CustomMissile("RS_FallenShot",4,0,CMF_AIMOFFSET,random(0,360),
         random(0,360)) — 15 fire bolts in every direction — then
         A_Explode(random(8,20),128,0). DeathSound "weapons/hellex".
         RS_FallenShot (RS_BaronFX.zs:1631) is Damage 2 (1d8 -> 2..16), Fire,
         Speed 16, +THRUGHOST, no splash.
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_RedBBall2", count:5, delayTics:5)
notes    ONE ROW, TWO TIMINGS. `FALN C 0 A_Jump(128,13)` at :2155 jumps thirteen
         states forward, landing on :2168 — the start of the strafing variant.
         Same payload, same count, same angle; only the cadence and the
         A_FastChase interleave differ. Recorded as one attack with both timings
         rather than invented as two, per the spec's mirrored/OtherB rule.
         **The state entries here must not be reordered or merged** — the jump is
         by numeric offset, so any edit moves the landing spot (noted at :2060).
         DontHurtShooter true. +THRUGHOST.
```

```
ATTACK   RS_RedBaron2.Death
file     zscript/monsters/baron/RS_Baron.zs:2217
shape    SCATTER
payload  RS_HKRedDeath x9
arc      --   (see notes — angle is a fixed 1 degree, CH argument slip)
timing   2,2,2,2,2,2,2,2   (9 frames of 2 tics, one spawn per frame, 18 tics)
damage   --   (RS_HKRedDeath has no Damage; all damage is A_Explode)
type     Fire
sound    A_PlaySound("world/barrelx") on spawn AND again mid-death
impact   Barrel-style airburst: A_Explode(random(5,10),42) then
         A_Burst("RS_RedThingsHK") shrapnel. DeathSound "world/barrelx".
         +NOGRAVITY +DONTGIB, Scale 0.7.
trigger  Death
range    --
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_HKRedDeath", count:9, delayTics:2,
                     spawnHeight:"random(5,70)", spawnOffset:"random(5,35)")
notes    THE SCATTER IS SPATIAL, NOT ANGULAR. `A_CustomMissile("RS_HKRedDeath",
         random(5,70), random(5,35), CMF_AIMOFFSET, 2, -10)` — arg 3 is
         spawnofs_xy (random 5..35 units sideways), arg 4 is the ANGLE and is
         literally `CMF_AIMOFFSET` = **1 degree** (constants.zs:53), arg 5 is
         flags = 2 = CMF_AIMDIRECTION, arg 6 is pitch = -10. CH has the same
         argument slip verbatim; not a defect introduced here. The visible effect
         is nine explosive barrels lobbed in a rough cone up and forward as the
         flier dies. Classified SCATTER on the randomised spawn envelope.
```

## RS_BlackBaron2 — tier 10, "Baron from Abyss"

```
ATTACK   RS_BlackBaron2.Melee
file     zscript/monsters/baron/RS_Baron.zs:2331
shape    MELEE
payload  --
arc      --
timing   one tic  (lands t=8)
damage   A_CustomMeleeAttack(random(42,99))
type     Melee
sound    A_PlaySound("deepone/meleegrowl") at t=0; hit "monster/kntswg",
         miss "skeleton/swing"; MeleeSound "deepone/melee"
impact   --
trigger  Melee
range    ..88   (MeleeRange 88 — reach, not the engine default)
mirrored no
inherit  --
profile  MakeMelee(damage:"random(42,99)", hitSound:"monster/kntswg",
                   missSound:"skeleton/swing", range:88)
notes    A_Jump(128,"Missile") at :2333 chains into a ranged branch half the time.
         Missile can bounce straight back here via A_JumpIfCloser(32,"Melee") (:2336).
```

```
ATTACK   RS_BlackBaron2.Basic
file     zscript/monsters/baron/RS_Baron.zs:2363
shape    SCATTER
payload  RS_DeepOneBall x3
arc      26   (0, random(-13,-5), random(5,13); spawnheight 42, offsets 20/5/35)
timing   one tic  (all three on 0-tic states, t=8; 16 tics per pass)
damage   DamageFunction (random(25,75))
type     Plasma
sound    SeeSound "deepone/fire" x3
impact   A_Scream + OLDP CDEF fade, DeathSound "deepone/firehit". **No A_Explode**
         — direct hit only, but see the flight behaviour.
trigger  Missile   (A_Jump(255,"Basic","BeamThing","TentacleBashers") at :2339)
range    32..   (A_JumpIfCloser(32,"Melee") at :2336 diverts anything nearer)
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_DeepOneBall", count:3, arc:26)
notes    THE FLIGHT IS THE ATTACK: +ROCKETTRAIL +SEEKERMISSILE with BOTH
         A_Tracer AND A_BishopMissileWeave every frame. It homes AND corkscrews
         — very hard to sidestep. Speed 25.
         Loops itself 168/256 via A_Jump(168,"Basic") at :2368.
```

```
ATTACK   RS_BlackBaron2.Basic2
file     zscript/monsters/baron/RS_Baron.zs:2372
shape    SCATTER
payload  RS_DeepOneBall x5
arc      40   (0, random(-13,-5), random(5,13), random(-20,-13), random(13,20);
               spawnheight 42, offsets 20/5/35/-5/45)
timing   one tic  (all five on 0-tic states, t=8; 16 tics per pass)
damage   DamageFunction (random(25,75))
type     Plasma
sound    SeeSound "deepone/fire" x5
impact   as Basic — A_Scream, "deepone/firehit", no splash
trigger  Missile   (via Nah at :2393, reachable only after AggroUp has fired once)
range    32..
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_DeepOneBall", count:5, arc:40)
notes    The enraged version of Basic: two extra balls and a 40-degree cone
         instead of 26. **Basic2 is unreachable until `user_uhoh >= 1`** — it
         only appears in the Nah jump list (:2393), which AggroUp gates.
         Loops itself 168/256 (:2379).
```

```
ATTACK   RS_BlackBaron2.Beamthing
file     zscript/monsters/baron/RS_Baron.zs:2357
shape    HITSCAN
payload  RS_DeepBeam1  (both the puff AND the beam spawn class)
           (+ RS_DeepCharge1 x1, telegraph, 0 dmg, C1)
arc      --   (spread_xy 0, spread_z 0 — a perfectly straight beam)
timing   one tic  (railgun at t=23 after an 18-tic charge; 31 tics total)
damage   A_CustomRailgun(random(25,75), ...)
type     Plasma   (from RS_DeepBeam1's own DamageType on the puff)
sound    RS_DeepCharge1 SeeSound "deepone/fire" at t=4 (the charge tell)
impact   pufftype AND spawnclass are both RS_DeepBeam1 (RS_BaronFX.zs:1793):
         random(10,25) Plasma, Scale 1.5, A_Scream on impact,
         DeathSound "deepone/firehit". duration 35, sparsity 0.1, driftspeed 0.1,
         range 0 (= infinite), RGF_FULLBRIGHT, aim 1, maxdiff 0.
trigger  Missile   (A_Jump(255,"Basic","BeamThing","TentacleBashers") at :2339;
                    also in the Nah list at :2393)
range    32..
mirrored no
inherit  --
profile  MakeHitscan(mode:"railgun", damage:"random(25,75)", spawnOfs:25,
                     color:"white", puff:"RS_DeepBeam1", spawn:"RS_DeepBeam1",
                     duration:35, sparsity:0.1, driftSpeed:0.1)
notes    The only railgun in the family and the only true hitscan. Signature
         verified against qzdoom.pk3 `actor.zs:1212`. sparsity 0.1 means a dense
         beam of RS_DeepBeam1 actors, each carrying its own random(10,25) — so
         the effective damage is the railgun roll PLUS whatever the beam actors
         land. Loops itself 88/256 (:2359); A_CheckSight("See") aborts.
         RS_DeepCharge1 (RS_BaronFX.zs:1768) is Speed 1 with no Damage: a
         shrinking sphere at spawnofs_xy 25 — the 18-tic wind-up tell.
```

```
ATTACK   RS_BlackBaron2.TentacleBashers
file     zscript/monsters/baron/RS_Baron.zs:2343
shape    UNCLASSIFIED   (summon)
payload  RS_RoseTentacle x4
arc      --
timing   2,2,2   (four spawns at t=8,10,12,14 — one per frame of CUTH IIII 2)
damage   --   (see the minion's own row)
type     --
sound    A_PlaySound("deepone/active") at t=0
impact   Four live RS_RoseTentacle (RS_Baron.zs:2516) at random(-65,66) y and
         random(-65,66) z of the summoner, SXF_SETMASTER. They spawn unshootable
         and non-solid, walk to the target, then become solid and swing.
trigger  Missile   (A_Jump(255,"Basic","BeamThing","TentacleBashers") at :2339;
                    also 88/256 from TentacleRangers at :2351, and in Nah at :2393)
range    32..
mirrored no
inherit  --
profile  MakeSummon(actor:"RS_RoseTentacle", count:4, delayTics:2, setMaster:true)
notes    No word in the closed shape set describes a direct A_SpawnItemEx summon
         (no projectile, no travel, no aim). UNCLASSIFIED per the spec rather than
         coining one. Flagged in UNRESOLVED U3.
```

```
ATTACK   RS_BlackBaron2.TentacleRangers
file     zscript/monsters/baron/RS_Baron.zs:2349
shape    UNCLASSIFIED   (summon)
payload  RS_DeepTentacle x2
arc      --
timing   2   (two spawns at t=12 and t=14 — one per frame of CUTH II 2)
damage   --   (see the minion's own two rows)
type     --
sound    A_PlaySound("deepone/active") at t=0
impact   Two live RS_DeepTentacle (RS_Baron.zs:2423) at random(-65,66) y/z,
         SXF_SETMASTER. Health 500, +LOOKALLAROUND +NOTARGET +MISSILEEVENMORE,
         Mass 0x7FFFFFFF ("infinite" — cannot be pushed).
trigger  Missile   (reachable only via Nah at :2393, i.e. after AggroUp)
range    32..
mirrored no
inherit  --
profile  MakeSummon(actor:"RS_DeepTentacle", count:2, delayTics:2, setMaster:true)
notes    Longer wind-up than TentacleBashers (12 tics vs 8) and summons the
         RANGED minion instead of the melee one. Chains 88/256 into
         TentacleBashers at :2351, so one cast can produce both kinds.
         **Not reachable until `user_uhoh >= 1`** — the base Missile jump list
         at :2339 does not include it.
```

```
ATTACK   RS_BlackBaron2.AggroUp
file     zscript/monsters/baron/RS_Baron.zs:2383
shape    UNCLASSIFIED   (self-buff + summon)
payload  RS_DeepCharge1 x5 (telegraph, 0 dmg) + RS_DeepTentacle x2
arc      176   (random(-88,88) spawn offset per charge — spatial, angle 0)
timing   1,1,1,1   (five charges t=0..4; tentacles at t=13 and t=13)
damage   --
type     --
sound    A_PlaySound("deepone/pain") at t=8
impact   Two live RS_DeepTentacle at (0, +88, -88) and (0, -88, +88), SXF_SETMASTER.
trigger  Missile   (A_JumpIfHealthLower(4500,"AggroUP") at :2337 — Health 8907,
                    so it fires just past the 50% mark)
range    32..
mirrored yes   (the two tentacles are placed on opposite diagonals)
inherit  --
profile  MakeSelfBuff(target:"self",
                      sets:["+NOPAIN","+MISSILEEVENMORE"],
                      speed:{from:13,to:17},
                      accompany:MakeSummon(actor:"RS_DeepTentacle", count:2, setMaster:true),
                      unlocks:["Basic2","TentacleRangers"],
                      oncePerLife:true)
notes    WHAT IT ACTUALLY CHANGES:
           * `bNOPAIN = true` (:2384) — PERMANENT, never cleared.
           * `bMISSILEEVENMORE = true` (:2385) — PERMANENT.
           * `A_SetSpeed(17)` (:2386) — Speed 13 -> 17.
           * **IT UNLOCKS TWO ATTACKS.** Setting `user_uhoh` (:2388) reroutes the
             AggroUp entry to Nah (:2382), and Nah's jump list (:2393) is
             "Basic2","BeamThing","TentacleBashers","TentacleRangers" — where the
             pre-buff list (:2339) was only "Basic","BeamThing","TentacleBashers".
             Basic2 (5 balls, 40-degree cone) and TentacleRangers do not exist
             before this row fires. That is the real payload.
         Gated once per life by `user_uhoh` (:2382/:2388).
```

## RS_DeepTentacle — Black Baron's ranged minion (no tier token)

```
ATTACK   RS_DeepTentacle.Missile1
file     zscript/monsters/baron/RS_Baron.zs:2477
shape    BURST
payload  RS_TentacleBall1 x3
arc      --   (angle 0 all three; spawnheight 100, offset 0)
timing   17,17   (shots at t=8, t=25, t=42; 59 tics total)
damage   DamageFunction (random(10,60))
type     Plasma
sound    SeeSound "monster/tenatk" per ball
impact   OLDP CDEF fade, DeathSound "weapons/plasmax". No A_Explode.
trigger  Missile   (the 160/256 fall-through when A_Jump(96,"Missile2") at :2474 misses)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_TentacleBall1", count:3, delayTics:17)
notes    **THE INTERVAL IS 17 TICS, NOT 9.** The firing frame is `TEN1 J 9` but
         each shot is preceded by `TEN1 I 8 A_FaceTarget` — the shot re-fires
         9 + 8 tics later. Reading the tic off the firing line alone reports 9
         and builds a burst nearly twice as fast as the monster's.
         Aimed: A_FaceTarget between every round, so the burst tracks a strafing
         player. Speed 25. This is the BURST half of the spec's own worked
         example; Missile2 below is the SALVO half.
```

```
ATTACK   RS_DeepTentacle.Missile2
file     zscript/monsters/baron/RS_Baron.zs:2486
shape    SALVO
payload  RS_TentacleBall2 x10
arc      --   (ANGLE 0 FOR ALL TEN — the spread is vertical, see notes)
timing   one tic   (nine 0-tic states plus the tenth on a 9-tic frame; all ten
                    execute in the same tic, t=8)
damage   Damage 5   (engine rolls 1d8 -> 5..40)
type     Plasma   (INHERITED from RS_TentacleBall1)
sound    SeeSound "imp/attack" x10 in one tic
impact   OLDP BA fade, DeathSound "imp/shotx". No A_Explode.
trigger  Missile   (96/256 via A_Jump(96,"Missile2") at :2474)
range    --
mirrored no
inherit  RS_TentacleBall1 (RS_BaronFX.zs:1721) — RS_TentacleBall2 (:1748)
         overrides ONLY Speed, Damage, SeeSound, DeathSound and the two state
         sequences. DamageType "Plasma", Radius 4, Height 4, RenderStyle Add,
         Alpha 0.75, +RANDOMIZE and the Projectile block are ALL the parent's.
         `Damage 5` replaces the parent's `DamageFunction (random(10,60))`.
profile  MakeSalvo(proj:"RS_TentacleBall2", count:10)
notes    **THE TEN ARE STACKED VERTICALLY, NOT FANNED.** The arguments are
         spawnheight 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 with spawnofs_xy 0
         and angle 0 (see the signature note at the top of this file). It is a
         100-unit-tall curtain of ten parallel bolts, released as one — a wall,
         not a spread. Every one is aimed at the target.
         Speed 10, half the parent's 25 — the curtain travels slowly and fills
         the corridor.
         Verified identical in CH (Barons.txt:4084-4096).
```

## RS_RoseTentacle — Black Baron's melee minion (no tier token)

```
ATTACK   RS_RoseTentacle.Melee
file     zscript/monsters/baron/RS_Baron.zs:2604
shape    MELEE
payload  --
arc      --
timing   swing 1 t=8; swing 2 t=44; swing 3/4 t=57+ (see notes)
damage   A_MeleeAttack() -> **random(1,8) * MeleeDamage 3 = 3..24** per swing
type     Melee
sound    --   (no MeleeSound property is set on this actor — SILENT ON HIT)
impact   --
trigger  Melee   (See ends with `Goto Melee` at :2593 — it always walks into melee)
range    ..52   (MeleeRange 52)
mirrored no
inherit  --
profile  MakeMelee(damage:"random(1,8)*3", hitSound:"", range:52)
notes    SILENCE IS THE FINDING, NOT A GAP — no MeleeSound anywhere on the actor,
         so the swing lands with no sound in CH either. As a weapon profile slot
         that is correct: the gun's own sound fills it.
         An A_CPosRefire loop (:2612 and :2616) with `Goto Melee+17` keeps it
         swinging while the target is alive and visible, so the swing count is
         unbounded, not 4. A_Jump(64,6) at :2608 picks between two swing paths.
         **The state entries must not be reordered** — `Goto Melee+17` and
         `Goto See+30` (:2622) are numeric offsets (noted at :2514).
         It arrives unshootable and non-solid (A_UnsetShootable / A_UnsetSolid at
         :2552/:2553) and only becomes hittable when Melee starts (:2595/:2596) —
         and drops back to intangible on Pain (:2620/:2621). It is a ghost until
         it swings.
```

## RS_WhiteBaron2 — tier 11, "Hell's Slice and Dicer"

```
ATTACK   RS_WhiteBaron2.Melee
file     zscript/monsters/baron/RS_Baron.zs:2778
shape    MELEE
payload  --
arc      --
timing   one tic  (lands t=18 after a 12-tic wind and a 3x A_Recoil(-12) lunge)
damage   A_CustomMeleeAttack(random(10,15)*7)   -> 70..105
type     Melee
sound    A_PlaySound("Obsidian/Swipe") at t=1 (the tell); hit "Obsidian/Melee"
impact   --
trigger  Melee
range    ..64   (MeleeRange unset -> default 64)
mirrored no
inherit  --
profile  MakeMelee(damage:"random(10,15)*7", hitSound:"Obsidian/Melee",
                   telegraph:"Obsidian/Swipe")
notes    Damage is a SCALED ROLL — `random(10,15)*7`, i.e. 70/77/84/91/98/105.
         Not 87. Recorded as written.
         `A_Recoil(-12)` x3 at :2777 lunges it forward into the swing.
         A_Jump(128,"Slice1","Slice2","Slice3") at :2779 chains half the time.
```

```
ATTACK   RS_WhiteBaron2.Dash
file     zscript/monsters/baron/RS_Baron.zs:2834
shape    CHARGE
payload  --   (the monster IS the projectile)
arc      --
timing   one tic  (A_SkullAttack at t=15, then five 5-tic proximity checks)
damage   Damage 5   (the +SKULLFLY ram roll: engine 1d8 -> 5..40 on contact)
type     --   (no DamageType on the actor)
sound    A_PlaySound("Ice/Fly") at t=10
impact   A_Recoil(-20) immediately after, then five A_JumpIfCloser checks at
         200/250/300/250/200 units — any hit diverts to SpinSlice. Then A_Stop
         and A_Jump(128,"Slice1","Slice2","Slice3").
trigger  Missile   (A_JumpIfCloser(800,"Dash") at :2785)
range    ..800     (and only 128/256 — Dash opens with A_Jump(128,"Missile2"))
mirrored no
inherit  --
profile  MakeCharge(speed:35, ramDamage:"1d8 x Damage 5")
notes    `Damage 5;` in the Default block (:2662) is not dead — it is exactly the
         +SKULLFLY collision damage A_SkullAttack(35) uses. A profile that drops
         it makes the charge harmless.
         The five graduated A_JumpIfCloser checks are a closing-window detector:
         200 -> 250 -> 300 -> 250 -> 200, so it converts the charge into a
         SpinSlice the moment it gets inside range at any point of the dash.
```

```
ATTACK   RS_WhiteBaron2.Slice1
file     zscript/monsters/baron/RS_Baron.zs:2850
shape    SALVO
payload  RS_WhiteBaronSlice x14   (2 volleys of 7)
arc      --   **ANGLE 0 ON ALL FOURTEEN** — the spread is spatial, see notes
timing   volley 1 at t=10 (one tic), volley 2 at t=20 (one tic); 42 tics total
damage   DamageFunction (random(11,44))
type     Fire
sound    SeeSound "Spell/SpellCast1" x7 per volley
impact   **IT DAMAGES WHILE FLYING.** A_Explode(random(2,12),16,0) on every
         second flight frame — a 16-unit proximity bite the whole way down the
         lane. Death: SPIR scale-up + BRB2 CDEFGHI, DeathSound "Fire/Fire4",
         no death explode. Trails RS_WhiteBaronSliceTrail. Speed 38, +NOGRAVITY.
trigger  Missile   (A_Jump(252,"Slice1","Slice2","Slice3","SpinSlice","SliceHoming",
                    "Stars","Spikes","FloorCrack") at :2790; also chained from
                    Melee :2779 and Dash :2844)
range    --
mirrored yes   (volley 1 offsets +24..-24, volley 2 offsets -24..+24)
inherit  --
profile  MakeSalvo(proj:"RS_WhiteBaronSlice", count:7, volleys:2, volleyGapTics:10)
notes    THE SEVEN ARE PARALLEL. Arguments are (48,24),(40,16),(32,8),(26,0),
         (18,-8),(10,-16),(2,-24) — spawnheight and spawnofs_xy, angle 0
         throughout. It is a diagonal BLADE of seven bolts sweeping from
         high-left to low-right, all travelling on the same heading. Reading
         arg 3 as an angle would report a 48-degree fan; there is no fan.
         Verified identical in CH (Barons.txt Slice1).
```

```
ATTACK   RS_WhiteBaron2.Slice2
file     zscript/monsters/baron/RS_Baron.zs:2873
shape    SALVO
payload  RS_WhiteBaronSlice x14   (2 volleys of 7)
arc      --   (angle 0 on all fourteen)
timing   volley 1 at t=10 (one tic), volley 2 at t=20 (one tic); 42 tics total
damage   DamageFunction (random(11,44))
type     Fire
sound    SeeSound "Spell/SpellCast1" x7 per volley
impact   as Slice1 — A_Explode(random(2,12),16,0) in flight, "Fire/Fire4" on death
trigger  Missile   (same jump list as Slice1)
range    --
mirrored yes   (volley 1 offsets +44..-22, volley 2 offsets -44..+22)
inherit  --
profile  MakeSalvo(proj:"RS_WhiteBaronSlice", count:7, volleys:2, volleyGapTics:10)
notes    Arguments (44,44),(42,33),(40,22),(38,11),(36,0),(34,-11),(32,-22) — a
         NARROWER height band (44 down to 32) but a WIDER lateral sweep (+44 to
         -22) than Slice1. A flatter, wider blade at chest height. Angle 0 throughout.
```

```
ATTACK   RS_WhiteBaron2.Slice3
file     zscript/monsters/baron/RS_Baron.zs:2896
shape    FAN
payload  RS_WhiteBaronSlice x14   (2 volleys of 7)
arc      12   (volley 1: -4,-2,0,+2,+4,+6,+8; volley 2 mirrors: +4,+2,0,-2,-4,-6,-8)
timing   volley 1 at t=10 (one tic), volley 2 at t=24 (one tic); 46 tics total
damage   DamageFunction (random(11,44))
type     Fire
sound    SeeSound "Spell/SpellCast1" x7 per volley
impact   as Slice1 — A_Explode(random(2,12),16,0) in flight, "Fire/Fire4" on death
trigger  Missile   (same jump list as Slice1)
range    --
mirrored yes
inherit  --
profile  MakeFan(proj:"RS_WhiteBaronSlice", count:7, arc:12, volleys:2, volleyGapTics:14)
notes    THE ONLY SLICE VARIANT WITH REAL ANGULAR SPREAD. Arguments are
         (32,44,-4),(32,33,-2),(32,22),(32,11,2),(32,0,4),(32,-11,6),(32,-22,8) —
         fixed spawnheight 32, sweeping lateral offset 44 -> -22, AND a 12-degree
         angular sweep. Note the middle shot `(32,22)` omits the angle entirely,
         so it is 0 — which sits correctly in the -4..+8 progression.
         The extra `VSTL N 4` at :2905 is why volley 2 lands 14 tics after
         volley 1 here, not 10 as in Slice1/Slice2.
```

```
ATTACK   RS_WhiteBaron2.SpinSlice
file     zscript/monsters/baron/RS_Baron.zs:2920
shape    FAN
payload  RS_WhiteBaronSlice x66   (6 volleys of 11)
arc      60   (-30 to +30 in steps of 6 — but see the -6 anomaly in notes)
timing   volleys at t=10, 18, 26, 34, 42, 50 (each volley one tic); ~72 tics total
damage   DamageFunction (random(11,44))
type     Fire
sound    SeeSound "Spell/SpellCast1" x11 per volley — 66 casts in 72 tics
impact   as Slice1 — A_Explode(random(2,12),16,0) in flight, "Fire/Fire4" on death
trigger  Missile   (same jump list as Slice1; also from Dash's proximity checks at
                    :2836-2840)
range    --
mirrored no   (each volley is the full symmetric -30..+30 sweep already)
inherit  --
profile  MakeFan(proj:"RS_WhiteBaronSlice", count:11, arc:60, volleys:6, volleyGapTics:8)
notes    **THE LARGEST ATTACK IN THE FAMILY: 66 projectiles.** Six identical
         11-shot fans, 8 tics apart, at spawnheight 32 / spawnofs_xy 1.
         **CH ANOMALY, PRESERVED VERBATIM.** One slot in each volley is written
         `A_CustomMissile("RS_WhiteBaronSlice",32,-6)` — two positional arguments,
         so spawnofs_xy = -6 and ANGLE = 0. Every other slot is
         `(32,1,<angle>)`. Where the -6-degree shot should be, there is instead a
         straight-ahead shot offset 6 units left. The step-6 sweep therefore has
         a hole at -6 and a doubled shot at 0. **CH has the identical line**
         (verified: 66 calls, same anomalous slot), so this is CH's own slip, not
         an import defect. Do not "fix" it.
         Total volley damage ceiling: 66 x 44 = 2,904 on a full connect, before
         the in-flight A_Explode chain.
```

```
ATTACK   RS_WhiteBaron2.SliceHoming
file     zscript/monsters/baron/RS_Baron.zs:2818
shape    SALVO
payload  RS_WhiteBaronSliceHoming x10
arc      --   (angle 0 on all ten — see notes)
timing   one tic  (nine 0-tic states plus one 4-tic frame, all at t=10; 29 tics total)
damage   DamageFunction (random(5,25))
type     Fire
sound    SeeSound "Spell/SpellCast1" x10 in one tic
impact   A_Explode(random(2,12),16,0) in flight, as the other slices. Death:
         BRB2 CDEFGHI, DeathSound "Fire/Fire4". Trails RS_WhiteBaronSliceTrail.
trigger  Missile   (A_Jump(64,"SliceHoming","Stars","Spikes","FloorCrack") at :2789,
                    then the 8-way list at :2790; also chained from Stars at :2811)
range    --
mirrored yes   (offsets run +28..-28 then -28..+28 in the same tic)
inherit  --
profile  MakeSalvo(proj:"RS_WhiteBaronSliceHoming", count:10)
notes    Arguments (48,28),(32,14),(26,-2),(18,-14),(2,-28),(48,-28),(32,-14),
         (26,2),(18,14),(2,28) — heights and lateral offsets only, angle 0
         throughout. Ten parallel launch points forming an X, all ten released
         together.
         **They home**: +SEEKERMISSILE with A_SeekerMissile(12,12) every other
         frame, at Speed 15 — slow and relentless, versus Slice's Speed 38 and no
         homing. Half the damage per bolt, twice the hit rate.
```

```
ATTACK   RS_WhiteBaron2.Stars
file     zscript/monsters/baron/RS_Baron.zs:2804
shape    SALVO
payload  RS_WhiteBaronStar x6   (2 volleys of 3)
arc      --   (angle 0 on all six; spawnheight 42, offsets 0/+16/-16)
timing   volley 1 at t=8 (one tic), volley 2 at t=24 (one tic); 32 tics total
damage   DamageFunction (random(5,25))
type     Fire
sound    SeeSound "caco/attack" x3 per volley
impact   2x A_Explode(random(5,25),64) then 3x A_Explode(random(5,30),64) —
         five detonations per star. DeathSound "spell/Impact1".
trigger  Missile   (A_Jump(64,"SliceHoming","Stars","Spikes","FloorCrack") at :2789
                    and the 8-way list at :2790)
range    --
mirrored no
inherit  --
profile  MakeSalvo(proj:"RS_WhiteBaronStar", count:3, volleys:2, volleyGapTics:16)
notes    Three PARALLEL stars per volley at lateral offsets 0/+16/-16, angle 0.
         Each is +SEEKERMISSILE A_SeekerMissile(3,3) and picks one of two weave
         directions at spawn (A_Jump(128,"Two") at :1942), so the three braid
         apart on their own rather than being fanned by the firing state.
         Speed 33, Species "BaronOfHell" +DONTHARMCLASS.
         Loops itself 64/256 into SliceHoming or Stars (:2811).
```

```
ATTACK   RS_WhiteBaron2.Spikes
file     zscript/monsters/baron/RS_Baron.zs:2799
shape    VILE
payload  RS_VileGroundSpikeBrown x1   (which lays 5x RS_VileGroundSpikeBrown2)
arc      --
timing   one tic  (A_VileTarget at t=5; 13 tics total)
damage   DamageFunction (random(1,10))   [contact, on each spike]
type     Melee
sound    A_PlaySound("ROCKHIT1",0) when each spike erupts
impact   **A DELAYED MINEFIELD.** RS_VileGroundSpikeBrown (RS_BaronFX.zs:77)
         spends ~55 tics throwing dirt, and at ~t=32 spawns FIVE
         RS_VileGroundSpikeBrown2 at randompick(+-32,46,52,64,76,94,128) on both
         axes. Every spike — primary and satellites — then erupts with
         **3x A_Explode(random(60,100),32,0)** at growing scale, plays "ROCKHIT1",
         drops +THRUACTORS and becomes solid for a further 40 tics.
         Six eruptions x 3 blasts x random(60,100) at radius 32.
trigger  Missile   (A_Jump(64,"SliceHoming","Stars","Spikes","FloorCrack") at :2789
                    and the 8-way list at :2790)
range    --
mirrored no
inherit  --
profile  MakeVile(mode:"target", proj:"RS_VileGroundSpikeBrown")
notes    Highest area-damage roll in the family: random(60,100) x3 per spike, x6
         spikes. The ~55-tic fuse is the entire counterplay — the ground effect
         is a dirt-kicking tell for nearly two seconds before anything hurts.
         Both spike classes are third-file externals this lane defines; CH's home
         is Archviles.txt:214 and :269. Verified there: same random(1,10) Melee,
         same random(60,100) A_Explode ladder.
         See convention C3 for A_VileTarget under VILE.
```

```
ATTACK   RS_WhiteBaron2.FloorCrack
file     zscript/monsters/baron/RS_Baron.zs:2794
shape    SCATTER
payload  RS_WhiteBaronGround x3
arc      32   (randompick(16,8,0,-8,-16) per shot — spawnheight 32, offset 0)
timing   3,3   (one per frame of `VSTL PPP 3`; shots at t=8, 11, 14; 17 tics total)
damage   --   **THE CARRIER DOES NO DAMAGE** — see impact
type     Melee   (via the spikes it lays)
sound    --   (RS_WhiteBaronGround has no SeeSound; the state plays nothing)
impact   IT IS A PLOUGH, NOT A SHOT. RS_WhiteBaronGround (RS_BaronFX.zs:1960) has
         no Damage at all: Speed 25, Gravity 5.0, Doom bounce x99,
         +SEEKERMISSILE, and A_CStaffMissileSlither so it snakes along the floor.
         **Every Fly cycle it drops a live RS_VileGroundSpikeBrown2 at its current
         position** — a trail of mines down the whole path, each erupting for
         3x A_Explode(random(60,100),32,0) after its ~44-tic fuse.
         Bounce.Floor kicks it to angle +- randompick(-5..5) at speed 12 and keeps
         going; Bounce.Wall stops it dead.
trigger  Missile   (A_Jump(64,"SliceHoming","Stars","Spikes","FloorCrack") at :2789
                    and the 8-way list at :2790)
range    --
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_WhiteBaronGround", count:3, arc:32, delayTics:3)
notes    A row that records only "3 ground missiles, no damage" is a lie: the
         damage is entirely in the mine trail, and it is the same random(60,100)
         ladder as Spikes. Confirmed against CH — CH's WhiteBaronGround has no
         Damage property either (Barons.txt:4604ff).
         `VSTL PPP 3` fires the action ONCE PER FRAME (three times), not once.
```

---

# UNRESOLVED

**U1 — The CH path named in the task does not exist on this machine.**
`C:\Users\Command\Desktop\CH` is absent; the desktop holds `CHP`, which is a
different pack and was **not** consulted. All CH citations above are against
`E:\New folder\ART SOURCE\CH\decorate\Barons.txt` — 5,021 lines, the exact
length both baron file headers cite, and the path CLAUDE.md names as CH's home
("Source of truth for all of it: `E:\New folder\ART SOURCE\CH\`"). I believe
this is the same pack under a different path, but I did not verify that the two
are byte-identical because one of them is not here. **If the owner moved CH,
the 32 damage-roll matches and the 17 attack-sequence matches above should be
re-run against the real location before they are trusted.**

**U2 — `MULTI` is stretched in one of its four rows.** The spec defines MULTI as
"one attack that fires two or more DIFFERENT payload classes."
`RS_FireBluBaron2.A2`, `RS_RedBaron1.Bomb` and `RS_RedBaron3.Bomb` are each two
projectile classes, so they fit cleanly. `RS_AbyssBaron2.Melee` does not — it is
melee plus one projectile class. I used MULTI anyway because it is the only word in the
closed set that warns a reader the row carries more than one damage source, and
splitting the row would break the spec's "one thing the player recognises" rule.
**The spec owner should decide whether melee-plus-spray gets its own word or
stays under MULTI**; I did not coin one.

**U3 — Three things in this family have no shape word, and I did not invent
one.** All are `shape UNCLASSIFIED` with full descriptions:
  * `RS_AbyssBaron2.Heal` — a resurrect-and-upgrade aura (allies, not enemies).
  * `RS_BlackBaron2.TentacleBashers` / `.TentacleRangers` — direct
    `A_SpawnItemEx` summons of live monsters: no projectile, no travel, no aim.
  * The three self-buffs (`RedBaron1.Rage`, `RedBaron3.BUFF`,
    `BlackBaron2.AggroUp`) — the task named `MakeSelfBuff` as the factory but the
    spec's shape vocabulary has no matching word.
**If other families hit the same three cases, the spec needs SUMMON and BUFF (and
possibly AURA) added, or all seventeen files will carry UNCLASSIFIED rows that
mean different things.** Do not let seventeen agents each pick a different word.

**U4 — `A_VileTarget` is filed under `VILE` by my own convention (C3), not by
the spec.** The spec says "VILE — A_VileAttack — line-of-sight burn, no travel."
Four rows here use `A_VileTarget` instead (`AbyssBaron2.Defile`,
`YellowBaron.FireSummon`, `WhiteBaron2.Spikes`) and one uses `A_VileAttack`
(`BrownBaron2.Slam`). They are different engine functions with different
mechanics — `A_VileAttack` is an instant LOS burn on the target, `A_VileTarget`
spawns an actor at the target's feet. **The spec should say explicitly which
bucket `A_VileTarget` belongs to.** I distinguished them in the `profile` line
with `mode:"attack"` vs `mode:"target"` so the rows survive either ruling.

**U5 — the engine source path in CLAUDE.md is gone.** `E:\DXR2` does not exist.
I verified `A_CustomMissile`/`A_SpawnProjectile`, `A_MeleeAttack`,
`A_BruisAttack`, `A_CustomRailgun` and the `CMF_*` constants against
`qzdoom.pk3` in the running sourceport instead
(`D:\SteamLibrary\steamapps\Common\DooM VR\___Sourceport\qzdoom-16-RC1-Windows-64bit\`).
That is the engine actually running the mod, so I consider it at least as
authoritative — but CLAUDE.md's stated location is stale and should be updated
or the source restored.

**U6 — three sound names in this family are never defined by CH.** Already
itemised in `RS_BaronFX.zs:50-57` and unchanged by this pass, but they touch
attack rows so they are repeated here: `"satyr/sight"`, `"satyr/death"` and
`"knight/pain"` on `RS_BrownBaron2` are absent from CH's SNDINFO and are
overridden eighteen lines later anyway. **I did not audit whether every
attack-time sound above resolves to a real lump** — that is the sound-import
check CLAUDE.md describes, it is a different job from this catalog, and an
unresolved sound name is completely inert, so nothing in this document would
have revealed it. Sounds above are transcribed as written, not verified end to end.

**U7 — `RS_RedBaron2.Missile` variant B is recorded as one row with two
timings, and that is a judgement call.** Same payload, same count (5), same
angle; only the cadence (5,5,5,5 vs 7,10,7,8) and the `A_FastChase` interleave
differ. I applied the spec's mirrored/OtherB rule. **If the catalog's consumer
needs cadence-level granularity, this is the one row that should split into
two.** Nothing else in the family is close to that line.

**U8 — I did not chase the secondary rows the spec permits.** The spec says that
an impact which is itself substantial "IMPACT CAN BE AN ATTACK ... give the
secondary its own row if it is substantial." Several here qualify:
`RS_ArchonSoul` (fired 8-at-a-time by every `RS_RedPower`, 4 detonations each),
`RS_BaronStar3` (8 seekers from every `RS_BaronFbomb`), `RS_FallenShot` (15 from
every `RS_RedBBall2`), `RS_VileGroundSpikeBrown2` (the mine that does all of
FloorCrack's and most of Spikes' damage), `RS_GreeniesBR` (dripped continuously
by `RS_Spspit3`), `RS_STracerBlue` (15 per `RS_SmashBalls2` floor bounce),
`RS_SpikeCyanRev` (64 per `RS_BaronStarCyan`) and `RS_AbyssBaronSoul` (a live
summoned bomb). **Each is fully described in its parent's `impact` field with
its own damage roll and file:line, so nothing is lost — but they are not
addressable as profile rows.** If the parts bin wants them as standalone parts,
that is a second pass and it should be a deliberate decision, not eight rows I
added on my own authority.
