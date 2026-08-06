# DEMON (Pinky) — MONSTER ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Shape words are from that
spec's CLOSED set only; nothing here is coined.

## Denominator — what was actually read

| | |
|---|---|
| Source files, read whole | `zscript/monsters/demon/RS_Demon.zs` (2151 lines) · `zscript/monsters/demon/RS_DemonFX.zs` (910 lines) |
| Classes read | **54** — 23 in `RS_Demon.zs`, 31 in `RS_DemonFX.zs` |
| State labels read | **263** — 204 + 59 (comments stripped before counting) |
| Monsters carrying attacks | **15 of 23** (the other 8 = 1 `RandomSpawner` dial + 7 cvar-gate stubs that only `A_SpawnItemEx` a real body) |
| Attack rows written | **48** |
| CH cross-check | `E:\New folder\ART SOURCE\CH\decorate\Demons.txt`, 2654 lines. **Every attack state in this family was diffed line-for-line against CH. No disagreement was found** — see UNRESOLVED for the one path-level note. |

The 15 attack-carriers: `RS_PinkDemon`, `RS_BrownDemon2`, `RS_CyanDemon2`,
`RS_FireBluDemon2`, `RS_AbyssDemon2`, `RS_GreyDemon2`, `RS_CommonDemon`,
`RS_GreenDemon`, `RS_BlueDemon`, `RS_PurpleDemon`, `RS_YellowDemon`,
`RS_RedDemon`, `RS_BlackDemon3`, `RS_WHOLETTHEDOGSOUT`, `RS_WhiteDemon2`.

## Shape tally for this family

MELEE 13 · CHARGE 13 · RING 5 · SINGLE 4 · SCATTER 3 · MULTI 3 ·
UNCLASSIFIED 3 · FAN 2 · BURST 1 · SALVO 1 = 48. (HITSCAN 0, VILE 0, COMBO 0,
RAIN 0 — this family has none.)

MELEE + CHARGE is 26 of 48. This is the melee family; the projectiles are
the exception, not the rule.

## Engine semantics these rows depend on (verified in `E:\UZDXREMA`, not assumed)

Read once, applies to every row below. Line cites are the engine tree.

- **`A_CustomMeleeAttack(dmg, meleesnd, misssnd, type, bleed)`** —
  `src/playsim/p_actionfunctions.cpp:1076`. Damage is applied **flat, not
  multiplied**. `type` omitted or `""`/`none` ⇒ `Melee`. Reach is the actor's
  `MeleeRange`. CH passes the literal `"none"` as the **third** arg = the
  *miss* sound, which resolves to no sound — so every `"none"` in this family
  means "silent whiff", not "no damage type".
- **`A_MeleeAttack()`** — `wadsrc/static/zscript/actors/attacks.zs:844` →
  `DoAttack`, `:819`: damage = **`random(1,8) * MeleeDamage`**, sound =
  `MeleeSound`, type `Melee`.
- **`A_SargAttack()`** — `wadsrc/static/zscript/actors/doom/demon.zs:88`:
  damage = **`random(1,10) * 4`**, type `Melee`, **plays no sound itself**.
- **`A_SkullAttack(speed)`** — `wadsrc/.../doom/lostsoul.zs:96`: sets
  `bSkullFly`, plays the actor's **`AttackSound` on CHAN_VOICE**, faces target,
  `VelFromAngle(speed)`. Ram damage lands in `AActor::Slam`
  (`src/playsim/p_mobj.cpp:3358`) as **`GetMissileDamage(7,1)`** with type
  `Melee`. `GetMissileDamage` (`:3309`) means:
  - actor has `Damage N` ⇒ ram = **`random(1,8) * N`**
  - actor has `DamageFunction (roll)` ⇒ ram = **the roll, flat**
  - actor has **neither** ⇒ `DamageVal` is 0 ⇒ ram = **0**. Two demons are in
    this state; both are flagged at their rows and in UNRESOLVED.
- **`A_Chase` plays `AttackSound` on CHAN_WEAPON when it enters MeleeState**
  (`src/playsim/p_enemy.cpp:2637-2640`). So a MELEE row can have **two**
  sounds: the entry `AttackSound` and the `A_CustomMeleeAttack` melee sound.
  Both are recorded.
- **Default `MeleeRange` = `64 - MELEEDELTA` = 44** (`actor.zs:420`, `:90`).
  Recorded explicitly wherever a class does not set one.
- **`A_CustomMissile`'s angle is relative to the firer** unless
  `CMF_ABSOLUTEANGLE`. This makes `A_CustomMissile(X,0,-48,160-angle)` fire at
  **world angle 160**, not at a 160° offset — see `RS_WhiteDemon2.DASH`.
- **An action on a multi-frame state fires once PER FRAME.** `LMLO CD 2
  A_SkullAttack(20)` is **two** calls, not one. Every such count below is the
  frame count, verified programmatically.
- **`Radius_Quake(intensity, dur, damrad, tremrad, tid)`** — every use in this
  family passes `damrad 0`, i.e. **screen shake, zero damage**.

## Profile factory vocabulary used

Real calls from `zscript/systems/weapon/RS_AttackProfile.zs`:
`MakeVolley` (:470) · `MakeBurst` (:501) · `MakeMelee` (:439) ·
`MakeSummon` (:521) · `MakeRadial` (:542) · `MakeSelfBuff` (:564) ·
`MakeHeavy` (:413). Range bands are fields, not factory params, so a band is
written as a `.MinRange=` / `.MaxRange=` suffix. Class names are written as
strings, matching the spec's own worked example; the factories take
`Class<Actor>`.

`[GAP]` on a profile line means no factory expresses that shape today. All
`[GAP]`s are itemised in UNRESOLVED.

---

# RS_PinkDemon — tier 1 orphan, "Pinkier"

CH's orphan: defined at `Demons.txt:19`, spawned by nothing in CH. Imported
whole. `Damage 7`, no `AttackSound`, no `Melee` state — so `A_Chase` never
finds a melee, and the **only** attack path is `Missile` → `Melee2`.

```
ATTACK   RS_PinkDemon.Melee2
file     zscript/monsters/demon/RS_Demon.zs:101
shape    CHARGE
payload  --   (the monster is the projectile)
arc      --
timing   2,2 windup then 2,2 charge   (8 tics; Fast-flagged, halves on -fast)
damage   random(1,8) * 7  =  7..56    (Damage 7, RS_Demon.zs:57, via Slam GetMissileDamage(7,1))
type     Melee   (hardcoded by AActor::Slam, not by the actor)
sound    --   SILENT. A_SkullAttack plays AttackSound; RS_PinkDemon defines none.
impact   contact only -- no puff, no death FX, no explosion
trigger  Missile   (via A_JumpIfCloser(100,"Melee2") at RS_Demon.zs:93)
range    ..100
mirrored no
inherit  Actor   (nothing inherited; RS_PinkDemon sets all its own sounds)
profile  MakeMelee(range:100, dmgMult:1.0, profName:"PinkierRam")   [GAP: no CHARGE/lunge factory]
notes    A_SkullAttack fires TWICE -- frames C and D of `LMLO CD 2` are two
         states. The second call re-aims and re-launches mid-lunge.
         Missile itself is a jump-only state and is NOT a row; the fall-through
         (DashFaster, RS_Demon.zs:94) is a 1-tic-per-frame pursuit loop out to
         1000 units with no attack in it.
         CH identical: Demons.txt:74-77.
```

---

# RS_BrownDemon2 — tier 13, "Brownie"

Speed 17 dasher. **No `Melee` state** — `MeleeRange 64` is set and never used,
because `A_Chase` finds no MeleeState and always routes to `Missile`.
No `AttackSound`.

```
ATTACK   RS_BrownDemon2.Missile
file     zscript/monsters/demon/RS_Demon.zs:384
shape    SINGLE
payload  RS_BrownOrbDemon x1
arc      --
timing   8 windup, 1 sound tic, 6 on the shot, 3+9 recovery   (27 tics)
damage   DamageFunction (random(13,33))   (RS_DemonFX.zs:266)
type     Fire
sound    "SNPRFIRE"   (A_PlaySound, RS_Demon.zs:383, one tic BEFORE the shot)
impact   RIP1 D SetScale(1,1) -> SetTranslation("BBEASTEX5") -> RIP1 DEFGH 3 Bright
         A_Explode(random(2,8),64) on EACH of 5 frames + DeathSound "weapons/boom1".
         In flight: SeeSound "fire/fire3", Speed 28, ProjectileKickback 2000,
         +MTHRUSPECIES +THRUGHOST, Scale 0.5.   (RS_DemonFX.zs:256-287)
trigger  Missile
range    120..   (fires only when NOT closer than 120 -- A_JumpIfCloser(120,"ChainFlame"), RS_Demon.zs:380)
mirrored no
inherit  Actor
profile  MakeVolley(proj:"RS_BrownOrbDemon", count:1, fireSnd:"SNPRFIRE", profName:"BrownieSniper") .MinRange=120
notes    The sniper shot. ProjectileKickback 2000 is the punch -- it is the
         only kickback value in the family and would be lost if only damage
         were carried across.
         5-frame A_Explode is deliberate (a lingering burn), not a bug.
         CH identical: Demons.txt:222-231.
```

```
ATTACK   RS_BrownDemon2.ChainFlame2
file     zscript/monsters/demon/RS_Demon.zs:395
shape    SCATTER
payload  RS_RedDemonBloodBolt3 x1 per cycle, cycle repeats
arc      14   (random(-7,7) per shot)
timing   2 face, 1 fire, 1 refire-check, 0-tic loop back   (4 tics per shot)
damage   DamageFunction (random(1,5))   (RS_DemonFX.zs:523)
type     Fire
sound    --   SILENT. Neither the state nor RS_RedDemonBloodBolt3 has a SeeSound.
impact   NONE that damages. Death state is `BLUD C 0; Stop` -- a zero-tic
         no-op. The bolt is Gravity 0.2, Speed 15, SoulTrans, Scale 0.95.
trigger  Missile   (via A_JumpIfCloser(120,"ChainFlame") -> A_JumpIfCloser(120,"ChainFlame2"))
range    ..120
mirrored no
inherit  Actor
profile  MakeBurst(proj:"RS_RedDemonBloodBolt3", count:2, delayTics:4, arc:14, profName:"BrownieChainFlame") .MaxRange=120
notes    COUNT IS NOT FIXED. The loop exits on A_MonsterRefire(128,"See")
         (RS_Demon.zs:396) -- ~50% per cycle, so expected ~2 bolts, unbounded
         tail. count:2 in the profile is the expectation, not a transcription.
         The double 120-gate (ChainFlame re-checks) means stepping out of 120
         mid-chain cancels it.
         DELIBERATE DEPARTURE FROM CH, DO NOT REVERT: RS_RedDemonBloodBolt3
         draws BAL1 ABCDE 4 + E 7, where CH writes SPRY ABCDEF 4 + G 3. SPRY
         exists in neither CH nor CHP; owner ruling 2026-08-06, recorded at
         RS_DemonFX.zs:530-535. Same 27-tic span, 5+1 frames instead of 6+1.
         RS_RedDemonBloodBolt3 is defined in CH's spectres.txt:1031 but fired
         from Demons.txt:238 -- it lives in RS_DemonFX.zs per the
         demons-owns-shared rule.
```

```
ATTACK   RS_BrownDemon2.Death
file     zscript/monsters/demon/RS_Demon.zs:438
shape    UNCLASSIFIED   (radius blast -- the closed set has no word for A_Explode)
payload  --   (no actor spawned; A_Explode is a direct radius hit)
arc      --
timing   fires on the 4-tic IFIN J frame, 16 tics into the death animation
damage   A_Explode(random(5,32), 64, 0)
type     none   (A_Explode default; flags 0 = hurts the source too)
sound    --   the DeathSound "weapons/rocklx" is the corpse, not the blast
impact   radius 64, single frame -- one blast, not a lingering one
trigger  Death
range    --
mirrored no
inherit  Actor
profile  MakeRadial(radius:64, damage:18, profName:"BrownieDeathPop")   [GAP: MakeRadial takes an int, not a roll -- 18 is the midpoint of random(5,32) and IS a flattening; the roll is the authority]
notes    Same state also runs A_RadiusGive("RS_BrownImpCommand",320,
         RGF_MONSTERS|RGF_EXFILTER,1,...) at RS_Demon.zs:441 -- a 320-unit
         ALLY BUFF handed to the pack on death, excluding other Brownies and
         Species "Demon1". Not damage; recorded so it is not lost.
         CH identical: Demons.txt:280-288.
```

**Not attacks, recorded so the gap is visible:** `Dash` (RS_Demon.zs:342) is a
speed-40 blink-rush under `RS_HKEXProtect` (a `PowerProtection`,
DamageFactor 0.6) that sheds 10 `RS_BrownDemonGhost` afterimages. Zero damage,
zero payload — mobility, not an attack. `SpeedBuff` (:423) / `Calm` (:427) are
a speed toggle. `Pain.AbyssPE` (:398) is the family-wide abyss transformation
(spawns `RS_AbyssDemon2`, then `A_Die`), present on 11 classes; it deals no
damage and is not rowed anywhere in this file.

---

# RS_CyanDemon2 — tier 12, "Ice Worm"

`AttackSound "slimeworm/melee"`, `MeleeRange 64`, `Damage 3`.

```
ATTACK   RS_CyanDemon2.Melee
file     zscript/monsters/demon/RS_Demon.zs:546
shape    MELEE
payload  RS_SpikeCyanRev x10   (secondary; thrown from the same swing)
arc      18 / 8   (frandom(-9,9) on the first 5, frandom(-4,4) on the second 5)
timing   4,4 face; both needle groups on ONE tic; 4 on the hit   (12 tics)
damage   A_CustomMeleeAttack(random(25,75)) -- FLAT, not multiplied
type     Melee   ("none" is the MISS sound, not the damage type)
sound    "slimeworm/melee" on the hit + "slimeworm/melee" AGAIN from A_Chase
         on melee entry (AttackSound, RS_Demon.zs:481). Same lump, twice.
impact   melee: no puff, bleed on.
         needles: RIP1 ABCABC 8 Bright flight, then RIP1 CBA 6
         A_Explode(random(0,1),6) on each of 3 frames, DeathSound "" (silent).
         DamageFunction (random(1,3)), Ice, Gravity 1.5, Scale 0.25.  (RS_DemonFX.zs:153-181)
trigger  Melee   (also reached from Missile via A_JumpIfCloser(72,"Melee"), RS_Demon.zs:518)
range    ..72 via Missile; MeleeRange 64 via A_Chase
mirrored no
inherit  Actor
profile  MakeMelee(range:64, fireSnd:"slimeworm/melee", profName:"IceWormBite")
         + MakeVolley(proj:"RS_SpikeCyanRev", count:10, arc:18, pitchJitter:9, profName:"IceWormNeedles")
notes    TWO factory calls, ONE attack -- MakeMelee has no secondary-payload
         slot. Do not ship the melee without the needles; the needles are half
         of what this attack looks like.
         The needles are LOBBED, not fired: A_SpawnItemEx(...,16,0,24/29,
         xvel random(9,33), 0, zvel random(3,9)/random(4,12), ...) -- forward
         and upward velocity, then Gravity 1.5 drops them.
         CH identical: Demons.txt:469-475.
```

```
ATTACK   RS_CyanDemon2.HideMe
file     zscript/monsters/demon/RS_Demon.zs:525
shape    RING
payload  RS_SpikeCyanRev x12, TWICE (24 total)
arc      360   (four quadrant bands: random(0,90), random(89,180), random(181,270), random(271,359) -- 3 needles each)
timing   both rings are 0-tic (12 needles on one tic each); ~43 tics of burrow between them
damage   DamageFunction (random(1,3)) per needle
type     Ice
sound    --   SILENT. No A_PlaySound anywhere in HideMe; the needles' DeathSound is "".
impact   RIP1 CBA 6 A_Explode(random(0,1),6) x3 frames, silent
trigger  Missile (fall-through when target is beyond 700) AND Pain (A_Jump(232,"HideMe") -- 232/256, RS_Demon.zs:572)
range    700..   via Missile; unbanded via Pain
mirrored no
inherit  Actor
profile  MakeVolley(proj:"RS_SpikeCyanRev", count:12, arc:360, profName:"IceWormBurrowRing") .MinRange=700
notes    ONE ROW, TWO RINGS. The submerge ring (RS_Demon.zs:525-528) and the
         emerge ring (:536-539) are byte-identical; they bracket a
         Speed-77 A_Wander burrow with NOPAIN set and Y-scale crushed to 0.1.
         A player reads it as "it dives, it pops up" -- one attack.
         The 4x random(0,90)-style bands ARE the RING tell here; there is no
         literal random(0,359) on the spawn angle.
         Band 2 starts at 89, not 90 -- a 1-degree overlap, CH's own.
         Pain reaching this at 232/256 makes it the family's most-fired ring.
         CH identical: Demons.txt:447-467.
```

```
ATTACK   RS_CyanDemon2.Hiss
file     zscript/monsters/demon/RS_Demon.zs:550
shape    CHARGE
payload  --
arc      --
timing   4,4 face then 8 on the launch   (16 tics)
damage   random(1,8) * 3  =  3..24   (Damage 3, RS_Demon.zs:478)
type     Melee
sound    "slimeworm/melee"   (AttackSound, played on CHAN_VOICE by A_SkullAttack)
impact   contact only
trigger  Missile   (via A_JumpIfCloser(700,"Hiss"), RS_Demon.zs:519)
range    72..700   (the 72 gate to Melee is checked first)
mirrored no
inherit  Actor
profile  MakeMelee(range:64, fireSnd:"slimeworm/melee", profName:"IceWormLunge")   [GAP: no CHARGE factory; skullspeed 40 lost]
notes    Skull speed 40 -- the second fastest lunge in the family after the
         Juggernaut's 42. That number has nowhere to live in a profile today.
         CH identical: Demons.txt:477-479.
```

---

# RS_FireBluDemon2 — tier 7, "FireBluey"

`: Demon`. Sets its own `AttackSound "demon/melee"`. `Damage 1`,
`MeleeRange 64`, Speed 5, Mass 5000 — the slow tank.

```
ATTACK   RS_FireBluDemon2.Rush
file     zscript/monsters/demon/RS_Demon.zs:659
shape    CHARGE
payload  --
arc      --
timing   1 face, then 3/3 alternating fire+reface x5   (28 tics, 5 launches)
damage   random(1,8) * 1  =  1..8  PER SLAM   (Damage 1, RS_Demon.zs:608)
type     Melee
sound    "demon/melee" x5   (AttackSound, once per A_SkullAttack)
impact   contact only
trigger  Missile   (via A_JumpIfCloser(800,"Rush"), RS_Demon.zs:638)
range    ..800
mirrored no
inherit  Demon   (AttackSound is re-declared locally at RS_Demon.zs:615; the parent's is identical)
profile  MakeBurst(proj:null, count:5, delayTics:6, profName:"FireBlueyChainRam")   [GAP: no CHARGE factory -- this is 5 lunges, not 5 projectiles]
notes    FIVE consecutive A_SkullAttack(20), each re-aimed by an interleaved
         Fast A_FaceTarget. Damage 1 makes each slam trivially small; the
         attack is the repetition and the 20-speed shove, not the number.
         Total 5..40 if every slam connects.
         CH identical: Demons.txt:598-608.
```

```
ATTACK   RS_FireBluDemon2.Melee
file     zscript/monsters/demon/RS_Demon.zs:671
shape    MELEE
payload  --
arc      --
timing   7,7 face then 8 on the hit   (22 tics, Fast-flagged)
damage   A_CustomMeleeAttack(random(15,50)) -- FLAT
type     Melee
sound    "Demon/melee" on the hit + "demon/melee" from A_Chase on entry
impact   no puff, bleed on
trigger  Melee
range    MeleeRange 64
mirrored no
inherit  Demon
profile  MakeMelee(range:64, fireSnd:"Demon/melee", profName:"FireBlueyBite")
notes    CH identical: Demons.txt:610-613.
```

```
ATTACK   RS_FireBluDemon2.XDeath
file     zscript/monsters/demon/RS_Demon.zs:689
shape    RING
payload  RS_FireSGguy2 x19
arc      360   (random(-359,359))
timing   all 19 on ONE tic, 15 tics into the gib animation
damage   DamageFunction (random(5,15)) per flame   (RS_ZombiemanFX.zs:792)
type     Fire
sound    per-flame SeeSound "imp/attack" x19 on the same tic; DeathSound "imp/shotx"
impact   RS_FireSGguy2 is Speed 17, +RANDOMIZE +THRUACTORS, Add, Alpha 0.85
trigger  XDeath   (label shared with Death at RS_Demon.zs:681-682 -- BOTH deaths do this)
range    --
mirrored no
inherit  Demon; payload class lives in zscript/monsters/zombieman/RS_ZombiemanFX.zs:785 (CH Archviles.txt:2285)
profile  MakeVolley(proj:"RS_FireSGguy2", count:19, arc:360, profName:"FireBlueyDeathBurn") .FireTrigger=RS_FIRE_XDEATH
notes    `Death:` and `XDeath:` are the SAME label here (RS_Demon.zs:681-682),
         so this fires on EVERY death, not just gibs. 19 damaging flames at
         random(3,9) forward velocity is the single largest death payload in
         the family.
         Spawned with alpha arg 64 (SXF flags then 64) -- translucent.
         CH identical: Demons.txt:617-635.
```

---

# RS_AbyssDemon2 — tier 9, "Bad dog"

Alpha 0.10 Add — near-invisible. `AttackSound "monster/dogatk"`,
`MeleeSound "monster/dogbit"`, **no `MeleeRange` ⇒ 44**.

```
ATTACK   RS_AbyssDemon2.Melee
file     zscript/monsters/demon/RS_Demon.zs:803
shape    MELEE
payload  --
arc      --
timing   2 fade-in, 3 bookkeeping, 4 face, 6 on the hit, 1 chain-check   (16 tics)
damage   A_CustomMeleeAttack(random(17,58)) -- FLAT
type     Melee
sound    "blooddemon/melee" on the hit + "monster/dogatk" from A_Chase on entry.
         MeleeSound "monster/dogbit" (RS_Demon.zs:739) IS NEVER PLAYED -- only
         A_MeleeAttack/A_Melee read MeleeSound, and this class uses neither.
impact   no puff, bleed on
trigger  Melee
range    MeleeRange 44 (default -- class sets MeleeThreshold 150 but no MeleeRange)
mirrored no
inherit  Actor
profile  MakeMelee(range:44, fireSnd:"blooddemon/melee", profName:"AbyssDogBite")
notes    A_SetTranslucent(1.00) at the top -- the dog becomes SOLID to bite and
         is opaque for the whole swing. That reveal is the attack's tell and is
         not damage, so it survives nowhere but here.
         Chains into Missile at 86/256 (A_Jump, RS_Demon.zs:804).
         CH identical: Demons.txt:752-758.
```

```
ATTACK   RS_AbyssDemon2.Missile
file     zscript/monsters/demon/RS_Demon.zs:811
shape    FAN
payload  RS_AbyssDogFire x3
arc      34   (0, -17, +17; spawn xy-offset 0, -5, +5 to match)
timing   1,1,1 -- one flame per tic   (22 tics with the 13-tic windup and 6-tic recovery)
damage   DamageFunction (random(5,45)) per flame   (RS_DemonFX.zs:296)
type     Fire
sound    SeeSound "weapons/bigbrn" x3, one per flame
impact   FRFX HIJ 2 Bright A_Explode(random(1,9),32) x3 frames, then FRFX KLM 2
         A_Explode(random(1,7),64) x3 frames, then FRFX NO 2. SIX explode
         frames, radius stepping 32 -> 64. DeathSound "weapons/bigbrn".
         In flight: +SEEKERMISSILE with A_SeekerMissile(2,2) on 2 of 4 frames
         and A_Weave(3,1,5,0) on the other 2 -- it homes AND snakes. Speed 18,
         XScale 1.4 / YScale 0.35 (a flat streak), Alpha 1.95.
         Sheds RS_AbyssShotIdentifier markers (cvar rs_ch_abyssmark, default
         OFF -- inert unless the player turns it on).   (RS_DemonFX.zs:289-324)
trigger  Missile   (also reached from Melee at 86/256, RS_Demon.zs:804)
range    --   (no gate)
mirrored no   (the -17/+17 pair is a symmetric fan, not a mirrored variant state)
inherit  Actor
profile  MakeBurst(proj:"RS_AbyssDogFire", count:3, delayTics:1, arc:34, fireSnd:"weapons/bigbrn", profName:"AbyssDogFlames")
notes    The only true FAN this family fires from a Missile state.
         MakeBurst not MakeVolley: 1 tic apart is not "together", and the
         seeker means the three arrive on different paths anyway.
         Alpha 1.95 is over 1.0 -- CH's own over-bright value, kept.
         CH identical: Demons.txt:760-770.
```

---

# RS_GreyDemon2 — tier 8, "Coiling menace"

`AttackSound "slimeworm/melee"`, **no `MeleeRange` ⇒ 44**, **no `Damage` and no
`DamageFunction`**.

```
ATTACK   RS_GreyDemon2.Wrap
file     zscript/monsters/demon/RS_Demon.zs:912
shape    SINGLE
payload  RS_WormLewd x1 per cycle, cycle repeats
arc      --   (angle 0 -- fired point-blank while warped onto the target)
timing   1 warp, 0-tic fire, then 20 tics of 1-tic re-warps   (22 tics per cycle)
damage   DamageFunction (random(5,23))   (RS_DemonFX.zs:374)
type     Melee   (the projectile's own DamageType, RS_DemonFX.zs:375)
sound    "slimeworm/melee" (A_PlaySound on slot 4, RS_Demon.zs:910).
         The projectile's SeeSound is "" and its DeathSound is "x" -- and "x"
         RESOLVES TO NOTHING IN CH'S OWN SNDINFO. Silent there too; kept verbatim.
impact   BAL1 A 1 Bright, then BAL1 CDE 2 Bright A_Explode(random(1,7),32,0)
         on each of 3 frames. Speed 14 / FastSpeed 26, Add, Alpha 0.25,
         +DONTHARMCLASS +DONTHARMSPECIES.   (RS_DemonFX.zs:364-394)
trigger  Missile   (A_JumpIfCloser(72,"Wrap"), RS_Demon.zs:896) AND Melee
         (A_JumpIfCloser(72,"Wrap"), :906) AND AllyOp (A_JumpIfCloser(32,"Wrap"), :919)
range    ..72
mirrored no
inherit  Actor
profile  MakeVolley(proj:"RS_WormLewd", count:1, profName:"CoilDrain") .MaxRange=72
         + MakeSelfBuff(profName:"CoilHeal")   [GAP: MakeSelfBuff has no heal field -- HealThing(5,99) has nowhere to go]
notes    THIS IS A DRAIN, NOT A SHOT. Every cycle: A_Warp onto the target
         (random(-1,3) forward, z+12, random(-45,45) yaw), fire the pulse,
         then HealThing(5,99) -- 5 HP to itself, capped at 99% of max
         (RS_Demon.zs:913). The self-heal is the point of the attack and
         disappears entirely if only the projectile is carried across.
         Exits on A_JumpIfTargetInLOS("See",1) -- it holds until the target
         breaks line of sight.
         The `WORM HEHEHEHEHEHEHEHEHEHE 1` re-warp line is 20 states, so the
         warp fires 20 more times per cycle -- the coiling.
         CH identical: Demons.txt:947-954.
```

```
ATTACK   RS_GreyDemon2.AllyOp
file     zscript/monsters/demon/RS_Demon.zs:918
shape    CHARGE
payload  --
arc      --
timing   10 on the launch, 10 range-check, 10 stop   (30 tics)
damage   ZERO. RS_GreyDemon2 declares neither Damage nor DamageFunction, so
         DamageVal is 0 and Slam's GetMissileDamage(7,1) returns
         ((rand&7)+1) * 0 = 0.
type     Melee   (moot at 0 damage)
sound    "slimeworm/melee"   (AttackSound via A_SkullAttack)
impact   contact only -- and the contact does nothing
trigger  Missile   (via A_JumpIfCloser(900,"AllyOp"), RS_Demon.zs:897)
range    72..900
mirrored no
inherit  Actor
profile  MakeMelee(range:44, fireSnd:"slimeworm/melee", dmgMult:0.0, profName:"CoilLunge")   [GAP: no CHARGE factory; and dmgMult 0 is a guess at intent]
notes    ***THE DAMAGE IS ZERO AND CH IS THE SAME.*** Verified: CH's GreyDemon2
         (Demons.txt:881-993) declares no Damage line -- confirmed by grepping
         the whole actor body. This is CH's behaviour, not an import defect.
         Do not "fix" it by inventing a number.
         Functionally the lunge is a REPOSITION: skullspeed 45 closes the gap,
         then A_JumpIfCloser(32,"Wrap") hands off to the drain that does the
         real work. As a player-weapon profile this row is a movement tool.
```

**Not an attack:** `RS_GreyDemon2.Melee` (RS_Demon.zs:904) contains no attack
call at all — 6 tics of `A_FaceTarget` then `A_JumpIfCloser(72,"Wrap")`. It is
a router, not a row. The `Missile` fall-through (:898-902) is a Speed-50
NOPAIN wander, also not an attack.

---

# RS_CommonDemon — tier 1, "Pinky"

`: Demon`, vanilla-plus. **Sets no `AttackSound`** ⇒ inherits Demon's
`"demon/melee"`. `MeleeRange 54`, `GibHealth -70`.

```
ATTACK   RS_CommonDemon.Melee
file     zscript/monsters/demon/RS_Demon.zs:989
shape    MELEE
payload  --
arc      --
timing   8,8 face then 8 on the hit   (24 tics, Fast-flagged)
damage   random(1,10) * 4  =  4..40   (A_SargAttack, engine demon.zs:93)
type     Melee   (hardcoded in A_SargAttack)
sound    "demon/melee" -- from A_Chase on melee entry ONLY. A_SargAttack itself
         plays nothing (engine demon.zs:88-97 has no sound call).
impact   no puff; TraceBleed on
trigger  Melee
range    MeleeRange 54
mirrored no
inherit  Demon   -- BOTH the damage roll AND the sound come from the parent.
                    Reading RS_CommonDemon's body alone reports "no damage
                    number and no attack sound" for an attack that has both.
profile  MakeMelee(range:54, fireSnd:"demon/melee", profName:"PinkyBite")
notes    The only A_SargAttack in the family, and the only 1..10 (not 1..8)
         roll in the whole catalog -- every other melee here is a CH
         random(a,b) literal.
         CH identical: Demons.txt:1049-1051.
```

---

# RS_GreenDemon — tier 2, "Greeny"

`: Demon`. Sets its own `AttackSound "demon/melee"`. `MeleeRange 54`,
`GibHealth 45` (CH's own POSITIVE gibhealth, verbatim).

```
ATTACK   RS_GreenDemon.Melee
file     zscript/monsters/demon/RS_Demon.zs:1094
shape    MELEE
payload  --
arc      --
timing   7,7 face then 8 on the hit   (22 tics, Fast-flagged)
damage   A_CustomMeleeAttack(random(13,40)) -- FLAT
type     Melee
sound    "Demon/melee" on the hit + "demon/melee" from A_Chase on entry
impact   no puff, bleed on
trigger  Melee
range    MeleeRange 54
mirrored no
inherit  Demon
profile  MakeMelee(range:54, fireSnd:"Demon/melee", profName:"GreenyBite")
notes    CH identical: Demons.txt:1146-1148.
```

```
ATTACK   RS_GreenDemon.XDeath
file     zscript/monsters/demon/RS_Demon.zs:1135
shape    MULTI
payload  RS_GreenDEDSmoke x1  +  RS_Gas14 x4  +  RS_Splash11 x8
arc      --   (position-scattered, not angle-scattered: random(-120,120) down to random(-20,20) for the gas, random(-64,64) for the slime)
timing   the A_Explode lands on the 8-tic ZOMG P frame; every spawn is 0-tic
         across the following ZOMG Q and ZOMG R frames   (~24 tics total)
damage   A_Explode(random(12,64), 78) -- the core blast
         + RS_Gas14: A_Explode(random(4,8),42) on EACH of 8 loop frames and 7
           death frames, Poison, ~32+ tics of cloud   (RS_ShotgunnerFX.zs:260)
         + RS_GreenDEDSmoke: A_Explode(random(5,10),42), Fire   (RS_DemonFX.zs:396)
         + RS_Splash11: NO DAMAGE -- Projectile +THRUACTORS with no Damage
           and no DamageFunction   (RS_DemonFX.zs:183)
type     none (core blast) / Poison (gas) / Fire (smoke)
sound    A_XScream, then "weapons/rocklx" (slot 7), then "slimeball/splat"
         (slot 6). RS_GreenDEDSmoke plays "world/barrelx" twice on top.
impact   A_Quake(20,12,0,64,0) -- screen shake, damrad 0, no damage
trigger  XDeath, and Death at 44/256 (A_Jump(44,"XDeath"), RS_Demon.zs:1124),
         and ALWAYS on Death.Fire (shares the label, RS_Demon.zs:1133-1134)
range    --
mirrored no
inherit  Demon
profile  MakeRadial(radius:78, damage:38, profName:"GreenyPop")
         + MakeVolley(proj:"RS_Gas14", count:4, arc:360, profName:"GreenyGasWeb")
         + MakeVolley(proj:"RS_Splash11", count:8, arc:360, profName:"GreenySlime")
         [GAP: damage:38 flattens random(12,64); no factory carries a roll]
notes    THREE factory calls, ONE attack. The gas is the real threat: 4 clouds
         x 15 explode frames each = up to 60 poison ticks of radius 42.
         RS_Splash11 is PURE COSMETIC -- 8 of the 13 spawned actors do nothing.
         Recorded so nobody "balances" this by counting spawn lines.
         Death.Fire routes here UNCONDITIONALLY (any fire kill), while a plain
         death only reaches it 44/256. Two very different frequencies on one
         label.
         CH identical: Demons.txt:1180-1213.
```

---

# RS_BlueDemon — tier 3, "Bluey"

`: Demon`. Sets its own `AttackSound "demon/melee"`. `MeleeRange 64`.
**No `Damage`, no `DamageFunction`.**

```
ATTACK   RS_BlueDemon.Rush
file     zscript/monsters/demon/RS_Demon.zs:1236
shape    CHARGE
payload  --
arc      --
timing   1 face then 3 on the launch   (4 tics -- the shortest attack in the family)
damage   ZERO. No Damage and no DamageFunction on RS_BlueDemon, so DamageVal
         is 0 and Slam returns ((rand&7)+1) * 0 = 0.
type     Melee   (moot at 0 damage)
sound    "demon/melee"   (AttackSound via A_SkullAttack)
impact   contact only -- and the contact does nothing
trigger  Missile   (via A_JumpIfCloser(800,"Rush"), RS_Demon.zs:1216)
range    ..800
mirrored no
inherit  Demon   (the AttackSound the lunge plays is re-declared locally at :1194; identical to the parent's)
profile  MakeMelee(range:64, fireSnd:"demon/melee", dmgMult:0.0, profName:"BlueyRush")   [GAP: no CHARGE factory; and dmgMult 0 is a guess at intent]
notes    ***THE DAMAGE IS ZERO AND CH IS THE SAME.*** Verified: CH's BlueDemon
         (Demons.txt:1246-1357) declares no Damage line. This is a pure
         gap-closer -- skullspeed 25 body-slams you into range for the melee
         below. Second of two zero-damage charges in this family; the other is
         RS_GreyDemon2.AllyOp.
         CH identical: Demons.txt:1307-1310.
```

```
ATTACK   RS_BlueDemon.Melee
file     zscript/monsters/demon/RS_Demon.zs:1240
shape    MELEE
payload  --
arc      --
timing   7,7 face then 8 on the hit   (22 tics, Fast-flagged)
damage   A_CustomMeleeAttack(random(15,43)) -- FLAT
type     Melee
sound    "Demon/melee" on the hit + "demon/melee" from A_Chase on entry
impact   no puff, bleed on
trigger  Melee
range    MeleeRange 64
mirrored no
inherit  Demon
profile  MakeMelee(range:64, fireSnd:"Demon/melee", profName:"BlueyBite")
notes    CH identical: Demons.txt:1312-1314.
```

---

# RS_PurpleDemon — tier 4, "Purply"

`: Demon`. Sets its own `AttackSound "demon/melee"`. `MeleeRange 64`,
`Damage 3`.

```
ATTACK   RS_PurpleDemon.Rush2
file     zscript/monsters/demon/RS_Demon.zs:1341
shape    CHARGE
payload  --
arc      --
timing   2 face then 3 on the launch   (5 tics)
damage   random(1,8) * 3  =  3..24   (Damage 3, RS_Demon.zs:1302)
type     Melee
sound    "demon/melee"   (AttackSound via A_SkullAttack)
impact   contact only
trigger  Missile (A_JumpIfCloser(800,"Rush2"), RS_Demon.zs:1337) AND Pain
         (A_Jump(100,"Missile") -- 100/256, RS_Demon.zs:1367)
range    ..800
mirrored no
inherit  Demon
profile  MakeMelee(range:64, fireSnd:"demon/melee", profName:"PurplyRush")   [GAP: no CHARGE factory; skullspeed 24 lost]
notes    The retaliation path matters: 100/256 of pain reactions re-enter
         Missile, so a Purply that is being shot rushes far more often than
         one that is not. That is the attack's character.
         CH identical: Demons.txt:1407-1410.
```

```
ATTACK   RS_PurpleDemon.Melee
file     zscript/monsters/demon/RS_Demon.zs:1345
shape    MELEE
payload  --
arc      --
timing   7,7 face then 6 on the hit   (20 tics, Fast-flagged)
damage   A_CustomMeleeAttack(random(13,46)) -- FLAT
type     Melee
sound    "Demon/melee" on the hit + "demon/melee" from A_Chase on entry
impact   no puff, bleed on
trigger  Melee
range    MeleeRange 64
mirrored no
inherit  Demon
profile  MakeMelee(range:64, fireSnd:"Demon/melee", profName:"PurplyBite")
notes    6 tics on the hit frame, not 8 -- the fastest bite of the five
         SARG-family melees. Recorded because the tic IS the attack's feel.
         CH identical: Demons.txt:1412-1414.
```

---

# RS_YellowDemon — tier 5, "Yellowy"

`: Demon`. **Sets no `AttackSound`** ⇒ inherits Demon's `"demon/melee"`.
`MeleeRange 64`, `Damage 4`.

```
ATTACK   RS_YellowDemon.Melee
file     zscript/monsters/demon/RS_Demon.zs:1454
shape    MELEE
payload  --
arc      --
timing   7,7 face then 6 on the hit, 1 bookkeeping   (21 tics; NOT Fast-flagged)
damage   A_CustomMeleeAttack(random(13,52)) -- FLAT
type     Melee
sound    "blooddemon/melee" on the hit + "demon/melee" from A_Chase on entry.
         TWO DIFFERENT LUMPS -- the entry sound is the vanilla Demon's,
         inherited, and does not match the hit sound.
impact   no puff, bleed on
trigger  Melee
range    MeleeRange 64
mirrored no
inherit  Demon   -- the ENTRY SOUND comes from the parent and is written
                    nowhere in RS_YellowDemon. Reading this class alone
                    reports one sound for an attack that plays two.
profile  MakeMelee(range:64, fireSnd:"blooddemon/melee", profName:"YellowyBite")
notes    UNCONDITIONALLY falls through to NOYOUDONT (RS_Demon.zs:1456) -- the
         bite is never the whole attack. The two rows below always follow it.
         CH identical: Demons.txt:1513-1517.
```

```
ATTACK   RS_YellowDemon.NOYOUDONT (charge half)
file     zscript/monsters/demon/RS_Demon.zs:1459
shape    CHARGE
payload  --
arc      --
timing   8 on the launch
damage   random(1,8) * 4  =  4..32   (Damage 4, RS_Demon.zs:1421)
type     Melee
sound    "demon/melee"   (INHERITED AttackSound, via A_SkullAttack -- see inherit)
impact   contact only
trigger  Melee   (unconditional fall-through from Melee, RS_Demon.zs:1456)
range    --   (no gate; whatever range the bite happened at)
mirrored no
inherit  Demon   (AttackSound only)
profile  MakeMelee(range:64, fireSnd:"demon/melee", profName:"YellowyDisengage")   [GAP: no CHARGE factory; skullspeed 30 lost]
notes    The "no you don't" -- it bites, then IMMEDIATELY skull-rams to shove
         you back before laying down the lightning row below. Split from the
         zaps because they are different shapes and a profile holds one shape;
         they run back-to-back in one state chain.
```

```
ATTACK   RS_YellowDemon.NOYOUDONT (lightning half)
file     zscript/monsters/demon/RS_Demon.zs:1460
shape    SCATTER
payload  RS_ZapZapCB x5
arc      64   (random(-32,32) yaw)  +  64 pitch jitter (random(-32,32))
timing   2,2,2,2,2 -- one bolt every 2 tics   (10 tics), then a 4-tic A_Stop
damage   RS_ZapZapCB has NO Damage and NO DamageFunction -- contact damage 0.
         ALL its damage is A_Explode(random(1,8), 64) on EACH of 18 frames
         (LITN ABCDEFGOPABCDEFGOP 1 Bright, RS_DemonFX.zs:110): 18 radius-64
         bursts over 18 tics, per bolt, x5 bolts.
type     Plasma
sound    "Litn/litn3" -- ONCE, and AFTER all five bolts are out
         (A_PlaySound, RS_Demon.zs:1461). Not per-bolt.
impact   the bolt IS the impact: Speed 1, so it crawls where it lands and
         burns for 18 tics. +RANDOMIZE, Add, Alpha 0.65.
trigger  Melee   (fall-through)
range    --
mirrored no
inherit  Demon
profile  MakeBurst(proj:"RS_ZapZapCB", count:5, delayTics:2, arc:64, pitchJitter:64, fireSnd:"Litn/litn3", profName:"YellowyZapWalk")
notes    Speed 1 is not a typo. These are not projectiles that travel, they
         are 5 crawling lightning pools laid at your feet. 90 potential
         explode ticks total. This is the family's highest-uptime damage
         source and it looks like nothing.
         The 18-frame A_Explode is DELIBERATE (see the multi-frame-explode
         rule); do not convert it to a single call.
         CH identical: Demons.txt:1520-1525.
```

```
ATTACK   RS_YellowDemon.Calm
file     zscript/monsters/demon/RS_Demon.zs:1497
shape    SALVO
payload  RS_ZapZapCB x5
arc      64   (random(-32,32) yaw)  +  64 pitch jitter
timing   ALL FIVE ON ONE TIC (`SRG2 EEEEE 0`)
damage   as above -- 0 on contact, A_Explode(random(1,8),64) x18 frames per bolt
type     Plasma
sound    "Litn/litn3" -- played BEFORE the bolts here (RS_Demon.zs:1496), the
         reverse of NOYOUDONT's ordering
impact   as above
trigger  Walk   (A_JumpIf(user_Calm == 1,"Calm") out of See, RS_Demon.zs:1450)
range    --
mirrored no
inherit  Demon
profile  MakeVolley(proj:"RS_ZapZapCB", count:5, arc:64, pitchJitter:64, fireSnd:"Litn/litn3", profName:"YellowyZapDump") .FireTrigger=RS_FIRE_WALK
notes    SAME PAYLOAD, DIFFERENT SHAPE -- and that is the whole reason this is
         its own row. NOYOUDONT spaces the 5 bolts 2 tics apart (SCATTER);
         Calm dumps all 5 on one tic (SALVO). A catalog that collapsed these
         would lose the only SALVO in the family.
         Fired mid-CHASE, not from an attack state: user_Calm is set by
         SpeedBuff (RS_Demon.zs:1492), which Pain reaches at 174/256. So being
         shot is what makes a Yellowy start dropping lightning while walking.
         It also drops speed back to 16 on the same tic.
         CH identical: Demons.txt:1560-1563.
```

---

# RS_RedDemon — tier 6, "Red-y"

`: Demon`. **Sets no `AttackSound`** ⇒ inherits Demon's `"demon/melee"`.
`MeleeRange 64`, `Damage 4` (unused — RS_RedDemon never charges).

```
ATTACK   RS_RedDemon.Missile
file     zscript/monsters/demon/RS_Demon.zs:1573
shape    SINGLE
payload  RS_RedDemonBloodBolt1 x1
arc      --
timing   7,7 face then 3 on the shot, 4 recovery   (21 tics)
damage   DamageFunction (random(2,27))   (RS_DemonFX.zs:456)
type     Fire
sound    SeeSound "imp/attack" (on the projectile, RS_DemonFX.zs:459)
impact   BAL1 CD 1 A_SetTranslucent(0.35), then the 12-droplet burst below,
         then BAL1 E 1. DeathSound "misc/gibbed".
         IN FLIGHT it also sheds 3 droplets per 2-tic loop cycle
         (BAL1 BBB 0 A_CustomMissile("RS_RedDemonBloodBolt2",1,0,random(-180,180)),
         RS_DemonFX.zs:467) -- a continuous spray trail, not just an impact.
         Speed 19, Scale 0.95, Add, Alpha 0.95.
trigger  Missile
range    --   (no gate)
mirrored no
inherit  Demon
profile  MakeVolley(proj:"RS_RedDemonBloodBolt1", count:1, fireSnd:"imp/attack", profName:"RedySpit")
notes    The trail is 3 live droplets every 2 tics for the whole flight --
         at Speed 19 over 500 units that is ~40 droplets in the air. They are
         random(0,1) damage each, so the trail is texture, not threat, but it
         is the entire visual identity of the shot.
         SEE THE SEPARATE ROW BELOW for the impact burst -- it is a real
         second attack, not a puff.
         CH identical: Demons.txt:1667-1670.
```

```
ATTACK   RS_RedDemonBloodBolt1.Death   (secondary -- the payload is itself an attack)
file     zscript/monsters/demon/RS_DemonFX.zs:471
shape    RING
payload  RS_RedDemonBloodBolt2 x12
arc      360   (random(-180,180) yaw) + 360 pitch (CMF_AIMOFFSET with random(-180,180) pitch) -- a full SPHERE, not a flat ring
timing   all 12 on ONE tic (`BAL1 EEEEEEEEEEEE 0`), on the bolt's impact
damage   DamageFunction (random(0,1)) per droplet   (RS_DemonFX.zs:486)
type     Fire
sound    --   the parent bolt's DeathSound "misc/gibbed" covers it; the droplets are silent
impact   none -- Death is `BLUD C 0; Stop`, a zero-tic no-op. Speed 2,
         SoulTrans, Alpha 0.75, Scale 0.95.
trigger  Missile   (fires when RS_RedDemon's bolt lands)
range    --
mirrored no
inherit  Actor
profile  MakeVolley(proj:"RS_RedDemonBloodBolt2", count:12, arc:360, pitchJitter:360, profName:"RedySplatter")
notes    Rowed separately per the spec's "IMPACT CAN BE AN ATTACK" rule. At
         random(0,1) each this is 0..12 damage -- it is a splatter effect that
         happens to be made of live projectiles, and it reads as a wet burst.
         DELIBERATE DEPARTURE FROM CH, DO NOT REVERT: RS_RedDemonBloodBolt2
         draws BAL1 ABCDE 3 + E 5 where CH writes SPRY ABCDEF 3 + G 2.
         SPRY exists in NEITHER CH NOR CHP -- CHP retypes the same dead token
         (DECORATE\07\07_R.txt:1819) while shipping no SPRY lump, so there is
         no corrected upstream to read intent from. CH's three OTHER blood
         bolts all draw BAL1. Owner ruling 2026-08-06, recorded in full at
         RS_DemonFX.zs:493-501 and in that file's header. Same 20-tic span,
         5+1 frames instead of 6+1.
```

```
ATTACK   RS_RedDemon.Melee
file     zscript/monsters/demon/RS_Demon.zs:1578
shape    MELEE
payload  RS_RedThingsLS x2   (secondary, cosmetic)
arc      --
timing   7,7 face then 7 on the hit, 1+0 for the flecks   (22 tics; NOT Fast-flagged)
damage   A_CustomMeleeAttack(random(13,58)) -- FLAT.
         RS_RedThingsLS has NO Damage -- the flecks are pure decoration.
type     Melee
sound    "blooddemon/melee" on the hit + "demon/melee" from A_Chase on entry.
         TWO DIFFERENT LUMPS -- entry sound inherited from vanilla Demon.
impact   melee: no puff, bleed on.
         flecks: BAL1 AB 12 loop with A_Jump(32,"Death") then
         A_SetTranslucent(0.35). Speed 9, Gravity 2, Scale 0.15, +THRUACTORS,
         Add.   (RS_DemonFX.zs:115-142, CH lostsouls.txt:1218)
trigger  Melee
range    MeleeRange 64
mirrored no
inherit  Demon   (entry AttackSound only -- not written anywhere in RS_RedDemon)
profile  MakeMelee(range:64, fireSnd:"blooddemon/melee", profName:"RedyBite")
notes    Widest melee roll in the non-boss tiers: random(13,58).
         The 2 flecks spawn at (1,3,15) and (6,3,15) -- offset, not centred;
         they read as blood coming off the side of the bite.
         CH identical: Demons.txt:1675-1679.
```

```
ATTACK   RS_RedDemon.BuffUP
file     zscript/monsters/demon/RS_Demon.zs:1606
shape    SINGLE
payload  RS_EffectHK x2
arc      --
timing   1 speed-set, then 6,6 with one spawn per frame   (18 tics)
damage   NONE. RS_EffectHK is Speed 0, +NOINTERACTION, no Damage.   (RS_ImpFX.zs:365)
type     --
sound    --   SILENT
impact   CBAL A 1 -> A_Burst("RS_RedThingsHK") -- a one-frame shell that bursts
         into cosmetic red flecks.   (RS_ImpFX.zs:379-385)
trigger  Pain   (A_Jump(174,"BuffUP") -- 174/256, RS_Demon.zs:1602)
range    --
mirrored no
inherit  Demon; payload class lives in zscript/monsters/imp/RS_ImpFX.zs:365 (CH Hellknights.txt:2088)
profile  MakeSelfBuff(speedMult:1.667, noPain:true, profName:"RedyEnrage")
         + MakeVolley(proj:"RS_EffectHK", count:2, profName:"RedyEnrageFlash")   [GAP: MakeSelfBuff has no bMISSILEMORE field]
notes    NOT A DAMAGING ATTACK -- rowed because it fires a projectile class
         from a Pain beat, and leaving it out would make "absent" and "blank"
         look the same. The real content is the buff: A_SetSpeed(25) (from 15,
         so x1.667), bNOPAIN = true and bMISSILEMORE = true, all PERMANENT --
         there is no revert path anywhere in the class. Once a Red-y enrages
         it stays enraged.
         MakeSelfBuff has a duration; CH's has none. duration is omitted
         above rather than invented.
         CH identical: Demons.txt:1682-1686.
```

---

# RS_BlackDemon3 — tier 10 boss, "FRESH MEAT" (the Butcher)

Health 4500, `+BOSS`, Species "Butcher", `MeleeRange 77`,
`DamageFunction (random(10,40))`, **no `AttackSound`**,
`MeleeSound "Butcher/Melee"` (never read — this class uses no
`A_MeleeAttack`).

```
ATTACK   RS_BlackDemon3.HOPHOP
file     zscript/monsters/demon/RS_Demon.zs:1729
shape    CHARGE
payload  --
arc      --
timing   7,7 -- TWO launches per cycle, cycle loops   (14 tics per cycle)
damage   random(10,40) FLAT per slam. DamageFunction is set, so
         GetMissileDamage returns the roll DIRECTLY -- the usual random(1,8)
         multiplier does NOT apply.   (RS_Demon.zs:1659)
type     Melee
sound    --   SILENT. A_SkullAttack plays AttackSound; RS_BlackDemon3 has none.
impact   contact only
trigger  Missile   (A_Jump(256,"HOPHOP") -- the unconditional fall-through, RS_Demon.zs:1718)
range    60..   (loops until A_JumpIfCloser(60,"Melee"), RS_Demon.zs:1730)
mirrored no
inherit  Actor
profile  MakeBurst(proj:null, count:2, delayTics:7, profName:"ButcherHop")   [GAP: no CHARGE factory; this is 2 lunges, not 2 projectiles]
notes    `BCHR EF 7` is TWO frames, so A_SkullAttack fires TWICE per cycle,
         and the cycle LOOPS until it is inside 60 units. The Butcher hops at
         you repeatedly, not once.
         Preceded each cycle by ThrustThingZ(0,12,int(angle+360),0) at
         RS_Demon.zs:1728 -- the nonzero third arg means DOWNWARD thrust, and
         `angle+360` is CH's own quirk (any nonzero value reads as "down").
         Kept verbatim; do not "simplify" it to 0.
         CH identical: Demons.txt:1884-1888.
```

```
ATTACK   RS_BlackDemon3.BIGHOP
file     zscript/monsters/demon/RS_Demon.zs:1733
shape    CHARGE
payload  --
arc      --
timing   12,12 -- TWO launches   (24 tics), then 3 to reface
damage   random(10,40) FLAT per slam
type     Melee
sound    --   SILENT
impact   contact only
trigger  Missile   (via A_JumpIfCloser(500,"BIGHOP"), RS_Demon.zs:1717)
range    ..500
mirrored no
inherit  Actor
profile  MakeBurst(proj:null, count:2, delayTics:12, profName:"ButcherBigHop")   [GAP: no CHARGE factory]
notes    Skullspeed 37 vs HOPHOP's 20 -- this is the committed leap, fired
         when already inside 500. Falls through to Melee unless A_Jump(64)
         sends it back to HOPHOP.
         CH identical: Demons.txt:1890-1894.
```

```
ATTACK   RS_BlackDemon3.DOGS
file     zscript/monsters/demon/RS_Demon.zs:1739
shape    UNCLASSIFIED   (summon -- the closed set has no word for it)
payload  RS_WHOLETTHEDOGSOUT x4   (live monsters, not projectiles)
arc      --   (position-scattered: random(-65,65), random(-66,66), z random(3,24))
timing   20 windup, then 12,12,12,12 -- ONE hound per frame   (80 tics total)
damage   --   (the summon deals none; the hounds carry their own two rows below)
type     --
sound    --   SILENT
impact   spawned with SXF_SETMASTER, so RS_BlackDemon3.Death's A_KillChildren
         (RS_Demon.zs:1756) wipes the whole pack when the Butcher dies
trigger  Missile   (A_JumpIf(user_HOP >= 8,"DOGS"), RS_Demon.zs:1715)
range    --
mirrored no
inherit  Actor
profile  MakeSummon(summonCls:"RS_WHOLETTHEDOGSOUT", count:4, cap:4, tierOffset:-2, profName:"ButcherPack")
notes    THE GATE IS A PAIN COUNTER, NOT A TIMER. user_HOP increments on every
         Pain (RS_Demon.zs:1751) and this fires at >= 8, then subtracts 8
         (:1740). So the Butcher summons after taking eight pain reactions --
         hurt it faster and the dogs come faster. That coupling is the
         mechanic and it is invisible in the state names.
         80 tics is the longest single attack animation in the family.
         cap:4 in the profile is an inference: CH has no cap, the -8 counter
         is the only throttle. Flagged in UNRESOLVED.
         CH identical: Demons.txt:1896-1900.
```

```
ATTACK   RS_BlackDemon3.Melee
file     zscript/monsters/demon/RS_Demon.zs:1744
shape    MELEE
payload  --
arc      --
timing   5,5 face then 7 on the hit, 1 A_Stop   (18 tics)
damage   A_CustomMeleeAttack(random(30,125)) -- FLAT
type     "Extreme"   -- NOT Melee. The explicit fourth arg overrides the default.
sound    "Butcher/Melee" on the hit, "Butcher/miss" ON A WHIFF (the only real
         miss sound in the family -- everywhere else CH passes the literal
         "none"). No A_Chase entry sound: this class has no AttackSound.
impact   no puff, bleed on
trigger  Melee   (also from HOPHOP at <60 and from BIGHOP's fall-through)
range    MeleeRange 77
mirrored no
inherit  Actor
profile  MakeMelee(range:77, fireSnd:"Butcher/Melee", profName:"ButcherCleave")   [GAP: MakeMelee has no damagetype field -- "Extreme" is lost]
notes    "Extreme" damage type bypasses most DamageFactor mitigation. This is
         the hardest-hitting melee in the family (random(30,125)) AND the one
         that is hardest to resist. Both facts live only in this row.
         MakeMelee also has no miss-sound slot, so "Butcher/miss" is lost too.
         CH identical: Demons.txt:1902-1906 (CH writes the type unquoted:
         `Extreme`, ours quoted: `"Extreme"`. Same value.)
```

---

# RS_WHOLETTHEDOGSOUT — the Butcher's hounds, "DOGE" (minion, no tier token)

`AttackSound "monster/dogatk"`, `MeleeSound "monster/dogbit"`,
`MeleeDamage 7`, **no `MeleeRange` ⇒ 44**, `MaxTargetRange 256`.

```
ATTACK   RS_WHOLETTHEDOGSOUT.Melee
file     zscript/monsters/demon/RS_Demon.zs:1815
shape    MELEE
payload  --
arc      --
timing   6,6 face then 6 on the hit   (18 tics)
damage   random(1,8) * 7  =  7..56   (A_MeleeAttack reads MeleeDamage 7, RS_Demon.zs:1779; engine attacks.zs:819)
type     Melee   (hardcoded in DoAttack)
sound    "monster/dogbit" on the hit (MeleeSound -- THE ONLY PLACE IN THIS
         FAMILY WHERE MeleeSound IS ACTUALLY READ) + "monster/dogatk" from
         A_Chase on entry
impact   no puff, bleed on
trigger  Melee
range    MeleeRange 44 (default)
mirrored no
inherit  Actor
profile  MakeMelee(range:44, fireSnd:"monster/dogbit", profName:"DogeBite")
notes    A_MeleeAttack is DEPRECATED in the engine (attacks.zs:844) but works,
         and it is the only multiplied melee roll in the family other than
         A_SargAttack. Everything else here is a CH random(a,b) literal.
         CH identical: Demons.txt:1980-1983.
```

```
ATTACK   RS_WHOLETTHEDOGSOUT.Missile
file     zscript/monsters/demon/RS_Demon.zs:1819
shape    BURST
payload  RS_DogFire x12
arc      0   (every one of the twelve is angle 0 -- dead ahead)
timing   1,1,1,1,1,1,1,1,1,1,1,1 -- one flame per tic   (28 tics with the 10-tic windup and 6-tic recovery)
damage   Damage 1 on contact = random(1,8) * 1 = 1..8 per flame
         PLUS A_Explode on EACH of 12 spawn frames, radius stepping
         8 -> 16 -> 32 -> 64 (RS_DemonFX.zs:605-609). The explode damage is a
         flat 1 each; the RADIUS growth is the payload.
type     Fire
sound    SeeSound "weapons/bigbrn" x12 -- once per flame, twelve tics running
impact   FRFX HIJ 2 A_Explode(1,32) then KLM 2 A_Explode(1,64) then NO 2.
         DeathSound "weapons/bigbrn". `DontHurtShooter true` -- the hound
         cannot burn itself (engine PROPERTY, not a flag; actor.zs:310).
         Speed 16, Scale 0.67, Add, +THRUGHOST.   (RS_DemonFX.zs:583-618)
trigger  Missile
range    ..256   (MaxTargetRange 256 on the hound, RS_Demon.zs:1781 -- it cannot
         even acquire beyond that, so the flamer is strictly short range)
mirrored no
inherit  Actor
profile  MakeBurst(proj:"RS_DogFire", count:12, delayTics:1, arc:0, fireSnd:"weapons/bigbrn", profName:"DogeFlamer") .MaxRange=256
notes    THE ONLY TRUE BURST IN THE FAMILY: 12 rounds, identical angle,
         one tic apart. This is a flamethrower and it is the cleanest
         weapon-shaped thing the demons own.
         Twelve identical lines, verified as 12 in both trees.
         FRFX D 0 A_LowGravity mid-flight (RS_DemonFX.zs:606) makes the flame
         float upward after the fourth frame -- it rises as it travels.
         CH identical: Demons.txt:1985-1998.
```

---

# RS_WhiteDemon2 — tier 11 boss, "YOU KNOW WHO I AM" (the Juggernaut)

Health 8000, `+BOSS`, `MeleeRange 88`, `DamageFunction (random(20,60))`,
**no `AttackSound`**, `MeleeSound "Butcher/Melee"` (never read).
The largest attack surface in the family: nine rows.

```
ATTACK   RS_WhiteDemon2.Unblock
file     zscript/monsters/demon/RS_Demon.zs:1966
shape    CHARGE
payload  --
arc      --
timing   2 noclip-on, 3 face, 3 on the launch, 2 noclip-off   (10 tics)
damage   random(20,60) FLAT   (DamageFunction, RS_Demon.zs:1890 -- roll used directly)
type     Melee
sound    --   SILENT
impact   contact only
trigger  Walk   (A_CheckBlock("Unblock",CBF_DROPOFF) fired twice from See, RS_Demon.zs:1950-1951)
range    --
mirrored no
inherit  Actor
profile  MakeMelee(range:88, dmgMult:1.0, profName:"JuggUnblock")   [GAP: no CHARGE factory]
notes    NOT REACHED FROM MISSILE AT ALL. This fires when the Juggernaut's
         pathing is BLOCKED mid-chase -- it turns noclip on, rams through
         whatever is in the way, and turns it off. A name filter on
         Missile:/Melee: misses this entirely; it is exactly the case the
         spec's "FOLLOW THE JUMPS" rule exists for.
         CH identical: Demons.txt:2216-2221.
```

```
ATTACK   RS_WhiteDemon2.DASH (charge half)
file     zscript/monsters/demon/RS_Demon.zs:1982
shape    CHARGE
payload  --
arc      --
timing   4,4 face, 4 nopain-set, then 9 on the launch   (21 tics of windup+launch)
damage   random(20,60) FLAT
type     Melee
sound    --   SILENT
impact   contact only
trigger  Missile   (A_JumpIfCloser(700,"DASH",true), RS_Demon.zs:1974 -- the
         `true` makes it a NO-line-of-sight check) AND Melee (A_Jump(128,"DASH"),
         :2133) AND HOPHOP (A_JumpIfCloser(120,"DASH"), :2117)
range    ..700
mirrored no
inherit  Actor
profile  MakeMelee(range:88, profName:"JuggDash")   [GAP: no CHARGE factory; skullspeed 37 lost]
notes    Sets bNOPAIN for the whole dash (RS_Demon.zs:1981) -- it cannot be
         stunned out of it. Increments user_rock by 2 on entry (:1979), which
         is what eventually unlocks METEOR at >= 7.
         Split from the two rows below because they are different shapes;
         all three run in one uninterrupted state chain.
```

```
ATTACK   RS_WhiteDemon2.DASH (quake-ray half)
file     zscript/monsters/demon/RS_Demon.zs:1983
shape    FAN
payload  RS_MolochQuake x12
arc      30   (WORLD angles 160, 180, 190 -- four passes of three)
timing   1 tic per ray, interleaved with the melee below   (20 tics)
damage   DamageFunction (random(5,27)) on contact, +RIPPER so it passes
         through and hits again, PLUS A_Explode(random(7,28),128) on EACH of
         9 spawn frames at 10 tics apiece -- 90 tics of radius-128 blast per
         ray.   (RS_DemonFX.zs:65-93)
type     Melee
sound    SeeSound "moloch/thud" x12
impact   +FLOORHUGGER (crawls the floor), +FORCERADIUSDMG, +BLOODLESSIMPACT,
         Speed 8, Alpha 0.1 Translucent. Death adds one more
         A_Explode(random(7,28),128).
trigger  Missile
range    ..700
mirrored no
inherit  Actor; payload class from CH CYBIES.txt:4005, defined at RS_DemonFX.zs:65
profile  MakeVolley(proj:"RS_MolochQuake", count:12, arc:30, profName:"JuggDashRays") .MaxRange=700
notes    ***THESE FIRE AT FIXED WORLD ANGLES, NOT RELATIVE TO FACING.***
         `A_CustomMissile("RS_MolochQuake",0,-48,160-angle)` resolves to
         self.angle + (160 - self.angle) = world angle 160. Same for 180 and
         190. So the rays always crawl the same three compass directions no
         matter which way the Juggernaut is looking. Compare BAM below, which
         uses plain integers and therefore DOES rotate with facing. This is
         CH's own inconsistency, verified in Demons.txt:2235-2251, and it is
         the single most surprising fact in this family.
         The -48 z-offset puts them at ground level.
         The 9-frame A_Explode is DELIBERATE (lingering quake), not a bug.
```

```
ATTACK   RS_WhiteDemon2.DASH (melee half)
file     zscript/monsters/demon/RS_Demon.zs:1984
shape    MELEE
payload  --
arc      --
timing   4 hits, 2 tics each, interleaved between the ray triples
damage   A_CustomMeleeAttack(random(50,120)) x4 -- FLAT, each
type     Melee   (the `""` third and fourth args mean silent-miss and
         default-type; NAME_None falls back to Melee)
sound    --   SILENT. meleesound is `""`. No A_Chase entry sound either
         (this class has no AttackSound, and DASH is not entered via A_Chase).
impact   no puff, bleed on
trigger  Missile
range    MeleeRange 88
mirrored no
inherit  Actor
profile  MakeMelee(range:88, profName:"JuggTrample")   [GAP: no way to express "4 hits during a lunge"]
notes    FOUR silent 50..120 hits landing while it is already skull-flying
         through you. Up to 480 damage from this half alone, and the player
         hears nothing but the quake rays. The silence is CH's and is correct
         as a profile slot -- a gun's own sound fills it.
         MeleeSound "Butcher/Melee" (RS_Demon.zs:1889) is DEAD on this class:
         nothing here calls A_MeleeAttack or A_Melee.
```

```
ATTACK   RS_WhiteDemon2.BAM
file     zscript/monsters/demon/RS_Demon.zs:2005
shape    RING
payload  RS_MolochQuake x35
arc      360   (0,10,20 ... 160, then 180,190 ... 350 -- 10-degree step, RELATIVE to facing)
timing   ALL 35 ON ONE TIC (every one is a 0-tic state), after a 9-tic wind
damage   as the DASH rays: random(5,27) contact + 9 frames of
         A_Explode(random(7,28),128) each, +RIPPER
type     Melee
sound    "monster/hamflr" (A_PlaySound, RS_Demon.zs:2003) + 35x SeeSound
         "moloch/thud" on the same tic
impact   Radius_Quake(30,60,0,120,0) -- 60 tics of shake, damrad 0 so no damage.
         6 dirt spawns (RS_Drt1/2/3 x2 each) scattered random(-128,128).
trigger  Missile   (terminus of DASH, RS_Demon.zs:2001, and of METEOR, :2104)
range    --
mirrored no
inherit  Actor
profile  MakeVolley(proj:"RS_MolochQuake", count:35, arc:360, fireSnd:"monster/hamflr", profName:"JuggGroundSlam")
notes    ***35, NOT 36. THE 170-DEGREE RAY IS MISSING.*** The list runs
         0,10,...,160 then jumps to 180. Verified in both trees: ours at
         RS_Demon.zs:2005-2039 and CH at Demons.txt:2255-2289, both 35 rays,
         both skipping 170. This is CH's own off-by-one and it leaves a
         permanent gap in the ring. Do NOT "complete" it to 36 -- that would
         be a silent behaviour change with no source.
         UNLIKE the DASH rays, these angles are plain integers, so this ring
         rotates with the Juggernaut's facing. Same payload, opposite
         convention, ~20 lines apart.
         35 rays x 9 explode frames = up to 315 radius-128 blasts from one
         attack. This is the single largest damage event in the family.
```

```
ATTACK   RS_WhiteDemon2.ROCKS
file     zscript/monsters/demon/RS_Demon.zs:2061
shape    MULTI
payload  RS_WDRock1 x1  +  RS_WDRock2 x1
arc      2   (random(-1,1) on the WDRock2 only; WDRock1 is fired at flat 15 y-offset)
timing   8 face, 2 quake, 8 on the riser, 10 reface, 6 on the boulder, 12 recovery   (46 tics)
damage   RS_WDRock1: NONE -- +FLOAT +NOGRAVITY +NOCLIP, no Damage. A telegraph.
         RS_WDRock2: DamageFunction (random(35,125)), Melee   (RS_DemonFX.zs:852)
type     -- / Melee
sound    RS_WDRock1: "moloch/step" (slot 7, ATTN_NONE -- audible map-wide)
         RS_WDRock2: SeeSound "monster/hamflr", DeathSound "moloch/thud", plus
         "Ice/Fly" on every spawn loop cycle
impact   RS_WDRock1: rises on ThrustThingZ(0,8,0,0), then dies into 3 dirt
         spawns. Pure theatre.   (RS_DemonFX.zs:815-843)
         RS_WDRock2: SEE THE SEPARATE ROW BELOW -- its death is a shrapnel
         ring, plus Radius_Quake(40,60,0,40,0).
         Lobbed: Gravity 0.12, Speed 28, fired with CMF_OFFSETPITCH|
         CMF_ABSOLUTEPITCH at random(2,6) -- a shallow arc, not a flat shot.
trigger  Missile   (A_Jump(256,"ROCKS") fall-through, RS_Demon.zs:1976, and
         Choice's 50/50 at :2056)
range    1400..   via the fall-through; 700..1400 routes to Choice
mirrored no
inherit  Actor
profile  MakeVolley(proj:"RS_WDRock1", count:1, fireSnd:"moloch/step", profName:"JuggRockTell")
         + MakeVolley(proj:"RS_WDRock2", count:1, arc:2, pitchJitter:4, fireSnd:"monster/hamflr", profName:"JuggBoulder")
notes    TWO factory calls, ONE attack -- MULTI because two different payload
         classes leave on the same swing.
         The Radius_Quake at RS_Demon.zs:2060 has tremor radius 900 -- the
         whole arena shakes when the Juggernaut winds up. That is the tell,
         and it costs nothing in damage.
         RS_WDRock1 is a ZERO-DAMAGE payload. Half of this attack's spawn
         lines do no damage at all; do not read spawn count as threat.
         CH identical: Demons.txt:2310-2317.
```

```
ATTACK   RS_WDRock2.Death   (secondary -- the payload is itself an attack)
file     zscript/monsters/demon/RS_DemonFX.zs:871
shape    MULTI
payload  RS_WDRock4 x14  +  RS_WDRock3 x3
arc      360   (random(0,360) with CMF_ABSOLUTEANGLE) + 360 pitch (CMF_ABSOLUTEPITCH, random(0,360)) -- a full sphere of shrapnel
timing   all 17 on ONE tic (every spawn line is 0-tic), then 1 tic of quake
damage   RS_WDRock4: DamageFunction (random(5,20)), Melee   (RS_DemonFX.zs:886)
         RS_WDRock3: DamageFunction (random(15,65)), Melee   (RS_ZombiemanFX.zs:687)
type     Melee
sound    per-shard SeeSound "monster/hamflr" x17; WDRock4 DeathSound
         "Butcher/melee", WDRock3 DeathSound "Butcher/melee"
impact   WDRock4: Speed 42, Scale 0.4, dies into 2 dirt spawns
         WDRock3: Speed 36, Scale 0.7, dies into 8 dirt spawns
         plus Radius_Quake(40,60,0,40,0) on the last frame -- damrad 0
trigger  Missile   (fires when the Juggernaut's boulder lands)
range    --
mirrored no
inherit  Actor. RS_WDRock3 IS NOT IN THIS FILE -- it is owned by the zombieman
         family at zscript/monsters/zombieman/RS_ZombiemanFX.zs:680 (CH
         Demons.txt:2632). RS_DemonFX.zs:904-909 records the diff: both bodies
         are identical to CH. Reading RS_DemonFX.zs alone reports this payload
         as undefined.
profile  MakeVolley(proj:"RS_WDRock4", count:14, arc:360, pitchJitter:360, profName:"JuggShrapnelSmall")
         + MakeVolley(proj:"RS_WDRock3", count:3, arc:360, pitchJitter:360, profName:"JuggShrapnelBig")
notes    Rowed separately per the spec's "IMPACT CAN BE AN ATTACK" rule. 17
         live damaging projectiles on one tic -- the boulder's random(35,125)
         is the smaller half of what actually hits you.
         The 14 WDRock4 come from TWO seven-D lines (RS_DemonFX.zs:871 and
         :873) with the three WDRock3 sandwiched between them at :872.
         Verified frame-count: 7 + 3 + 7.
```

```
ATTACK   RS_WhiteDemon2.ROCKS2
file     zscript/monsters/demon/RS_Demon.zs:2072
shape    SCATTER
payload  RS_WDRock3 x2 per cycle, cycle repeats
arc      4 then 10   (random(-2,2) on the first, random(-5,5) on the second)
timing   6 face, 7 on shot one, 6 reface, 6 on shot two, 1 refire-check   (26 tics per cycle)
damage   DamageFunction (random(15,65)) each   (RS_ZombiemanFX.zs:687)
type     Melee
sound    SeeSound "monster/hamflr" per rock; DeathSound "Butcher/melee"
impact   Speed 36, Scale 0.7, JUBD ABCD 3 flight, dies into 8 dirt spawns
trigger  Missile   (fall-through from ROCKS when the target is beyond 1400,
         RS_Demon.zs:2065-2066)
range    1400..
mirrored no
inherit  Actor; payload owned by zscript/monsters/zombieman/RS_ZombiemanFX.zs:680
profile  MakeBurst(proj:"RS_WDRock3", count:2, delayTics:13, arc:10, profName:"JuggRockBarrage")
notes    COUNT IS NOT FIXED. Loops on A_MonsterRefire(128,"See")
         (RS_Demon.zs:2081) -- ~50% per cycle, so expected ~4 rocks, unbounded
         tail. count:2 is one cycle, not the expectation.
         Two A_CheckSight("See") calls (:2073, :2079) abort the barrage the
         instant it loses sight. This is the long-range siege mode.
         Increments user_rock by 1 per cycle (:2080) -- barraging is what
         charges the METEOR.
         The two shots have DIFFERENT spreads (4 then 10 degrees) -- a walking
         barrage, not a repeat. MakeBurst takes one arc, so 10 is recorded as
         the wider of the two; the 4 is here and nowhere else.
         CH identical: Demons.txt:2319-2333.
```

```
ATTACK   RS_WhiteDemon2.METEOR
file     zscript/monsters/demon/RS_Demon.zs:2095
shape    UNCLASSIFIED   (telegraphed self-warp ground slam -- the monster is
         the falling body, but it is not A_SkullAttack, so CHARGE does not apply)
payload  RS_MeteorStrikeCH x1   (a zero-damage marker; see the row below)
arc      --
timing   ~34 tics of setup (invuln/thruactors/nogravity on, thrust up, X-scale
         crushed to 0.1, two 3-tic wanders), A_VileTarget, 4-tic warp to
         target+128z, 40 TICS OF HANG TIME, 6 tics of flag reset, 6 tics of
         downward thrust, then the blast   (~85 tics before it lands)
damage   A_Explode(random(30,80), 128) on landing   (RS_Demon.zs:2102)
type     none   (A_Explode default)
sound    A_Scream from the marker + DeathSound "Juggernaut/Attack" on it
         (RS_DemonFX.zs:675). The Juggernaut itself is silent throughout.
impact   ThrustThingZ(0,90,1,0) -- nonzero third arg = DOWNWARD, a 90-unit
         slam. Then falls straight into BAM (RS_Demon.zs:2104), so the meteor
         is ALWAYS followed by the 35-ray ring.
trigger  Missile   (A_JumpIf(user_rock >= 7,"METEOR"), RS_Demon.zs:1972, and
         again at the top of DASH, :1978)
range    --
mirrored no
inherit  Actor
profile  MakeRadial(radius:128, damage:55, profName:"JuggMeteor")   [GAP: damage:55 flattens random(30,80); and nothing expresses the warp, the hang time, or the invulnerability window]
notes    THE ONLY A_VileTarget IN THE FAMILY, and it is NOT an A_VileAttack --
         no line-of-sight burn, no VILE shape. A_VileTarget
         (engine archvile.zs:113) just spawns the marker AT THE TARGET'S
         POSITION and wires pointers. All the damage is the Juggernaut's own
         A_Explode when it lands.
         INVULNERABLE + THRUACTORS + NOGRAVITY for the whole ~85 tics
         (RS_Demon.zs:2084-2086, cleared at :2098-2100). The player has ~40
         tics of warning and cannot hurt it during them.
         user_rock -= 6 afterwards (:2103), so the meteor is a spent resource
         rebuilt by dashing (+2) and barraging (+1).
         CH identical: Demons.txt:2335-2356.
```

```
ATTACK   RS_MeteorStrikeCH.Death   (secondary -- the meteor's ring telegraph)
file     zscript/monsters/demon/RS_DemonFX.zs:684
shape    RING
payload  RS_CircleDrawMeteorCH x1 + CH2 x1 + CH3 x1 + CH4 x1 + CH5 x3 + CH6 x3   (10 tracers)
arc      360   (each tracer WALKS a full circle; see notes for the resolved geometry)
timing   6 tracers on 0-tic states, then CH5/CH6 again on tics 1 and 3;
         the marker then holds ~88 tics (8x `CHTA A 10` + `TNT1 A 1`) before
         A_KillChildren("Extreme", KILS_FOILINVUL|KILS_KILLMISSILES)
damage   ZERO. RS_MeteorStrikeCH has no Damage and is not a Projectile.
         All six RS_CircleDrawMeteorCH* are +INVISIBLE +NOCLIP with no Damage.
type     --
sound    A_Scream (uses the marker's DeathSound "Juggernaut/Attack")
impact   none -- this is a pure telegraph
trigger  Missile   (spawned by RS_WhiteDemon2.METEOR)
range    --
mirrored no
inherit  RS_CircleDrawMeteorCH2..CH6 ALL inherit RS_CircleDrawMeteorCH
         (RS_DemonFX.zs:740, 755, 770, 785, 800). The base
         (RS_DemonFX.zs:715) supplies Radius 1, Height 1, Speed 255,
         Projectile, +INVISIBLE, +NOCLIP and the `int user_angle` field.
         EACH CHILD OVERRIDES ONLY `Spawn`/`Fly` -- nothing else. Reading a
         child alone reports an actor with no properties at all.
profile  MakeVolley(proj:"RS_CircleDrawMeteorCH", count:10, arc:360, profName:"JuggMeteorTell")   [GAP: nothing expresses an orbiting tracer; this is a telegraph primitive, not a volley]
notes    THE RESOLVED CIRCLE-DRAW CHAIN, since a "circle draw" is worth
         getting exact. Each tracer runs one 1-tic `A_Warp(AAPTR_MASTER,
         x, y, z, user_angle, WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|
         WARPF_INTERPOLATE)`, spawns 4 particles, then adds a fixed step to
         user_angle and loops. Because WARPF_ABSOLUTEANGLE re-frames the
         offset at user_angle, the offset ORBITS. Resolved per class:

           CH  (:733)  offset (+88,  0), z 1, step 7/tic, "orange", life random(90,120), size random(11,13), zvel 3
           CH2 (:748)  offset (-88,  0), z 1, step 7/tic, "orange", same particle
           CH3 (:763)  offset ( 0, +88), z 1, step 7/tic, "orange", same particle
           CH4 (:778)  offset ( 0, -88), z 1, step 7/tic, "orange", same particle
           CH5 (:793)  offset ( 0, +46), z 4, step 9/tic, "Red",    life random(90,120), size random(15,20), zvel 5, accelz 0.01
           CH6 (:808)  offset ( 0, -46), z 4, step 9/tic, "Red",    same particle

         So: an OUTER ring of radius 88 drawn by 4 tracers at 90-degree phase,
         advancing 7 deg/tic (a full lap in ~52 tics), and an INNER ring of
         radius 46 drawn by 6 tracers (CH5 and CH6 are each spawned three
         times) at 180-degree phase, advancing 9 deg/tic (a lap in 40 tics).
         Two concentric orange/red particle circles on the ground, under the
         player, for ~88 tics. THAT is the "circle draw".
         CH SPAWN-ARG QUIRK, transcribed faithfully and NOT to be tidied:
         the CH2/CH4/CH6 spawn lines are argument-shifted --
         `(-88,0,0,-3,0,0,0)` puts -88 in xofs, 0 in zofs and -3 in xvel,
         where CH/CH3/CH5 use `(88,0,-3,0,0,0,0)` with -3 in zofs. So CH2 and
         CH4 spawn at the SAME point and get a -3 x-velocity. It does not
         matter, because Fly warps to the master on tic one. Verified
         identical in CH Demons.txt:2420-2425.
         A_KillChildren with KILS_FOILINVUL is what ends the ring -- the
         tracers have no timeout of their own and would orbit forever.
```

```
ATTACK   RS_WhiteDemon2.HOPHOP
file     zscript/monsters/demon/RS_Demon.zs:2116
shape    CHARGE
payload  --
arc      --
timing   7,7 -- TWO launches per cycle, cycle loops   (14 tics per cycle)
damage   random(20,60) FLAT per slam
type     Melee
sound    --   SILENT
impact   contact only. Preceded by ThrustThingZ(0,16,0,0) (a real UPWARD hop)
         and Radius_Quake(10,40,0,80,0) -- shake only, damrad 0.
trigger  Missile   (via Choice's 50/50 A_Jump(256,"ROCKS","HOPHOP"), RS_Demon.zs:2056)
range    120..   (loops until A_JumpIfCloser(120,"DASH"), :2117)
mirrored no
inherit  Actor
profile  MakeBurst(proj:null, count:2, delayTics:7, profName:"JuggHop")   [GAP: no CHARGE factory]
notes    `JUGG CC 7` is two frames, so A_SkullAttack fires TWICE per cycle,
         and it loops. Unlike the Butcher's HOPHOP, this one hands off to
         DASH (not Melee) when it closes -- so the hop is the approach to the
         big combo, not to a bite.
         CH identical: Demons.txt:2364-2370.
```

```
ATTACK   RS_WhiteDemon2.BIGHOP
file     zscript/monsters/demon/RS_Demon.zs:2120
shape    CHARGE
payload  --
arc      --
timing   12,12 -- TWO launches   (24 tics), then 3 to reface
damage   random(20,60) FLAT per slam
type     Melee
sound    --   SILENT
impact   contact only
trigger  --   ***NOTHING REACHES THIS STATE.*** See notes.
range    --
mirrored no
inherit  Actor
profile  MakeBurst(proj:null, count:2, delayTics:12, profName:"JuggBigHop")   [GAP: no CHARGE factory]
notes    ***DEAD CODE, IN OUR TREE AND IN CH.*** Every jump target in
         RS_WhiteDemon2 was enumerated: Missile routes to METEOR / AlleUp /
         DASH / Choice / ROCKS; Choice routes to ROCKS or HOPHOP; Melee routes
         to DASH; HOPHOP routes to DASH; AlleUp routes to Maybenot, See or
         Missile; ROCKS routes to Missile or ROCKS2. **No state names BIGHOP.**
         Confirmed identical in CH (Demons.txt:2372-2376) -- CH's BlackDemon3
         reaches its BIGHOP via A_JumpIfCloser(500,"BIGHOP"), but WhiteDemon2
         has no equivalent line. Skullspeed 42 -- the fastest lunge in the
         family -- is content the player never sees.
         Rowed anyway: it is a fully-specified attack and a perfectly good
         profile. Recorded as unreachable rather than silently dropped.
```

```
ATTACK   RS_WhiteDemon2.Melee
file     zscript/monsters/demon/RS_Demon.zs:2128
shape    MELEE
payload  --
arc      --
timing   2,2,2 face, 6 on hit one, 4 reface, 6 on hit two   (22 tics, TWO hits)
damage   A_CustomMeleeAttack(random(40,120)) x2 -- FLAT, each
type     Melee   (the `""` fourth arg is NAME_None, which defaults to Melee)
sound    "Juggernaut/Hit" on each hit, plus "Juggernaut/Attack" on SoundSlot5
         and "Juggernaut/Pain" on SoundSlot6 fired BEFORE each swing
         (RS_Demon.zs:2126-2127, :2130-2131) -- three sounds per hit, on three
         separate channels. No A_Chase entry sound (no AttackSound on the class).
impact   no puff, bleed on (the explicit fifth arg `1`)
trigger  Melee
range    MeleeRange 88   -- the longest melee reach in the family
mirrored no
inherit  Actor
profile  MakeMelee(range:88, fireSnd:"Juggernaut/Hit", profName:"JuggSmash")   [GAP: MakeMelee holds one sound; the SoundSlot5/6 layer is lost]
notes    A TWO-HIT COMBO, not one swing -- 80..240 if both land. Ends on
         A_Jump(128,"DASH") (RS_Demon.zs:2133), so half of all melee combos
         roll straight into the dash.
         The three-channel sound stack (hit + attack + pain, deliberately
         played on the Juggernaut's OWN pain channel) is how CH makes this
         land heavy. One FireSound slot cannot carry it.
         MeleeSound "Butcher/Melee" (:1889) is DEAD -- nothing here reads it.
         CH identical: Demons.txt:2378-2387.
```

---

# UNRESOLVED

Honest gaps. Nothing below is a guess presented as a finding.

### U1. The CH path named in CLAUDE.md and in the spec does not exist on this machine

Both `CLAUDE.md` ("THE GROUND TRUTH IS `C:\Users\Command\Desktop\CH`") and
`rs_35_monster_attack_catalog_spec.txt` section 4 ("CH is at
`C:\Users\Command\Desktop\CH`") name a path that **is not present**.
`Test-Path` returns False; `C:\Users\Command\Desktop` contains `CHP` but no
`CH`.

CH **is** present at **`E:\New folder\ART SOURCE\CH\`** — the path CLAUDE.md
names in its "IMPORTING A MONSTER MEANS THE WHOLE MONSTER" section — with
`decorate/Demons.txt` at 2654 lines, matching the line count `RS_Demon.zs`'s
own header cites. Every CH citation in this file is against that copy.

I did not diff the two copies, because only one of them exists. If the owner
moved CH, the two docs need updating; if a second copy exists somewhere else,
this catalog was written against the ART SOURCE one and that should be known.
**Not resolved on my own authority.**

### U2. Two charges deal literally zero damage — and CH agrees

- `RS_BlueDemon.Rush` (`RS_Demon.zs:1236`, `A_SkullAttack(25)`)
- `RS_GreyDemon2.AllyOp` (`RS_Demon.zs:918`, `A_SkullAttack(45)`)

Neither class declares `Damage` or `DamageFunction`, so `DamageVal` is 0 and
`AActor::Slam`'s `GetMissileDamage(7,1)` returns `((rand&7)+1) * 0 = 0`.
Verified in CH: `BlueDemon` (Demons.txt:1246-1357) and `GreyDemon2`
(Demons.txt:881-993) have no `Damage` line either — confirmed by grepping
every `damage`/`damagefunction` line in the file.

So this is **CH's behaviour, faithfully imported**, not an import defect.
What I cannot tell is whether CH *intended* it. As parts-bin entries these two
rows are gap-closers with no payload, and I wrote `dmgMult:0.0` in their
profile lines — **that 0.0 is my reading of intent, not a measured value.**
Needs an owner call on whether a rebuilt profile keeps the zero.

### U3. `RS_WhiteDemon2.BIGHOP` is unreachable

No state in `RS_WhiteDemon2` jumps to `BIGHOP`. I enumerated every jump target
in the class (see that row's notes). CH is identical (Demons.txt:2372-2376).
Its sibling `RS_BlackDemon3.BIGHOP` **is** reachable, via
`A_JumpIfCloser(500,"BIGHOP")` — the Juggernaut has no equivalent line, so
this looks like an omission upstream rather than a deliberate cut. **I did not
change anything**; the row is catalogued and flagged.

### U4. The profile API has no CHARGE mode — 13 of 48 rows have no honest factory

`A_SkullAttack` is the second-most-common attack in this family and
`RS_AttackProfile` has nothing for it. `MakeMelee` is the closest real call,
and it loses:

- the **lunge itself** (`VelFromAngle(skullspeed)`) — the whole point
- the **skullspeed** value, which varies meaningfully: 20, 20, 20, 24, 25, 30,
  32, 37, 37, 40, 42, 45
- the fact that damage lands on **collision during flight**, not on a swing

Every affected row carries `[GAP: no CHARGE factory]`. A `MakeCharge(speed,
dmgMult, fireSnd)` would close all thirteen at once. **Not proposing it as a
change — flagging it as the single biggest hole between this catalog and a
usable parts bin.**

### U5. No factory carries a damage roll

`MakeMelee`, `MakeVolley`, `MakeBurst` and `MakeRadial` all take a
`dmgMult` (or an int), never a `random(a,b)`. Every melee row in this family
is a CH literal roll — `random(13,40)`, `random(30,125)`, `random(40,120)` —
and there is nowhere to put it.

I recorded every roll verbatim in the `damage` field and did **not** flatten
any of them. Where a factory forced an integer I said so on the line and gave
the roll beside it. **Three rows have a flattened number in the `profile` line
only** — `RS_BrownDemon2.Death` (18 for random(5,32)), `RS_GreenDemon.XDeath`
(38 for random(12,64)), `RS_WhiteDemon2.METEOR` (55 for random(30,80)) — each
marked `[GAP]` on the same line. The `damage` field above each is the
authority.

### U6. Fields with no home in `RS_AttackProfile`

Recorded in row notes, listed here so they are countable:

| Thing | Where | Nothing holds it |
|---|---|---|
| `"Extreme"` damage type | `RS_BlackDemon3.Melee` | `MakeMelee` has no damagetype |
| `"Butcher/miss"` whiff sound | same | `MakeMelee` has no miss sound |
| SoundSlot5/6 sound stack | `RS_WhiteDemon2.Melee` | one `FireSound` slot |
| `HealThing(5,99)` self-heal | `RS_GreyDemon2.Wrap` | `MakeSelfBuff` has no heal |
| `bMISSILEMORE` permanent set | `RS_RedDemon.BuffUP` | `MakeSelfBuff` has no such field |
| `ProjectileKickback 2000` | `RS_BrownOrbDemon` | no kickback field |
| orbiting tracer geometry | `RS_CircleDrawMeteorCH*` | no telegraph primitive |
| per-frame `A_Explode` lingering | MolochQuake, ZapZapCB, Gas14, DogFire | no lingering-blast field |
| "4 hits during one lunge" | `RS_WhiteDemon2.DASH` | melee and charge are separate profiles |

### U7. Two counts are expectations, not transcriptions

`RS_BrownDemon2.ChainFlame2` and `RS_WhiteDemon2.ROCKS2` both loop on
`A_MonsterRefire(128, "See")` — roughly a coin flip per cycle, so the shot
count is unbounded with an expected value near 2 and 4 respectively. The
`count:` in those two profile lines is my expectation. Every other count in
this file is a verified frame count.

`MakeSummon`'s `cap:4` on `RS_BlackDemon3.DOGS` is likewise an inference — CH
has no pack cap at all, only the `user_HOP -= 8` pain-counter throttle.

### U8. Things I deliberately did not row

Stated so "absent" and "blank" do not look the same:

- **`Pain.AbyssPE`** (11 classes, e.g. `RS_Demon.zs:398`, `:552`, `:641`) — the
  family-wide abyss transformation. Spawns 90 `RS_SplashAbyss` (45 + 45, zero
  damage, `RS_ZombiemanFX.zs:707`) and an `RS_AbyssDemon2`, then `A_Die`. No
  damage on any path. It is a death/replace, not an attack.
- **`RS_BrownDemon2.Dash`** (`:342`) — Speed-40 blink-rush with 10
  `RS_BrownDemonGhost` afterimages under `RS_HKEXProtect`. Zero damage.
  Mobility.
- **`RS_GreyDemon2.Melee`** (`:904`) and **`RS_CyanDemon2.Missile`** header
  (`:515`) — pure routers, no attack call in them.
- **`RS_BlackDemon3.Death`** (`:1753`) — `A_KillChildren` (kills its own
  hounds) + `RS_ButcherHammer`, a `BounceType "Doom"` prop with no damage.
- **`RS_YellowDemon.Death`** / **`RS_RedDemon.Death`** — drop
  `RS_BloodDemonArm` / `RS_BloodDemonArm2`. `+MISSILE` but no `Damage` and no
  `Projectile`; they are severed-arm gibs.
- **`RS_DogShot`** (`RS_DemonFX.zs:620`) — a complete `Damage 7` Fire
  projectile with `SeeSound "monster/dogsht"` and a `RS_DogTrail` puff.
  **Defined in CH and fired by nothing in `Demons.txt`.** Imported per the
  import-everything rule; it has no attack site, so it has no row. It is a
  ready-made payload for a profile if anyone wants one.
- **`RS_SplashAbyssBubbleDemon`** (`RS_DemonFX.zs:326`) — shed by
  `RS_AbyssDemon2.See2` while walking. `Projectile` but no `Damage`; spawns
  8 `RS_SplashAbyss2` droplets per flight loop and 108 more on death
  (54 + 54, `RS_DemonFX.zs:358-359`). Pond ambience.
  (Note `RS_SplashAbyss2` at `RS_ZombiemanFX.zs:735` **does** carry
  `DamageFunction (random(1,9))` Ice — but the bubble spawns them, and the
  bubble is a See-state effect, not an attack the monster aims. Flagged rather
  than rowed; if the owner reads walk-shed damage as an attack, that is a
  16th monster row.)

### U9. Sounds I could not confirm resolve to lumps

The spec asks for attacks, not an audio audit, so I did **not** trace these to
lumps end-to-end. Recording the ones that would be silent-and-inert if missing,
because an unresolved sound name produces no error:

`"SNPRFIRE"`, `"BrownDemon/Step"`, `"blooddemon/melee"`, `"slimeworm/melee"`,
`"Litn/litn3"`, `"moloch/thud"`, `"moloch/step"`, `"monster/hamflr"`,
`"Butcher/Melee"`, `"Butcher/miss"`, `"Juggernaut/Hit"`,
`"Juggernaut/Attack"`, `"weapons/bigbrn"`, `"Ice/Fly"`, `"abydogse"`.

One is **already known dead**: `RS_WormLewd`'s `DeathSound "x"`
(`RS_DemonFX.zs:382`) has no entry in CH's own `SNDINFO.txt` — silent in CH
too, kept verbatim. That is recorded in `RS_GreyDemon2.Wrap`'s row.

### U10. Not verified: sprite tokens

`CDW2 X` (the circle tracers), `IDGA C` (MolochQuake), `JUBD` (all four rock
classes and the meteor marker), `LITN` (ZapZapCB), `HHFX`, `A8Y5`, `AYPB`,
`CIRN`, `RIP1`, `BRHM`, `SG2A`. I did not check `sprites/` for any of them.
The catalog's job is attack shape; a missing sprite here would not change a
single field above. Flagged so nobody reads this file as sprite clearance.
`IFN2 C`/`IFN2 F` are already documented as absent-but-harmless
(`RS_Demon.zs:351`, `:379` — every use is a 0-tic state).
