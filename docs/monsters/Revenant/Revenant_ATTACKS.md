# REVENANT FAMILY -- ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Closed shape vocabulary,
fixed field order, `--` for genuinely-absent, never a blank.

| | |
|---|---|
| Family | Revenant (Colourful Hell `Colourset1`) |
| Monsters carrying attacks | **18** |
| Attack rows written | **74** (68 monster attacks + 6 payload-impact secondaries) |
| Classes read | **96** in the two family files (26 in `RS_Revenant.zs`, 70 in `RS_RevenantFX.zs`) + **21** externally-owned payload classes opened in 9 other family files |
| State labels read | **431** (269 monster-file, 162 FX-file) |
| Attack call sites reconciled | 216 `A_CustomMissile`, 6 `A_CustomMeleeAttack`, 5 `A_SkullAttack`, 9 `A_SkelFist`, 3 `A_VileTarget`, 2 `A_CustomRailgun`, 1 `A_CustomBulletAttack` |
| Our tree | `E:\RS_Main\zscript\monsters\revenant\RS_Revenant.zs`, `...\RS_RevenantFX.zs` |
| CH | `E:\New folder\ART SOURCE\CH\decorate\Revenants.txt` (5,154 lines) -- **see UNRESOLVED #1: this is NOT the path the spec names** |

Paths in `file` lines are repo-relative to `E:\RS_Main`.

---

## CH CROSS-CHECK -- WHAT WAS ACTUALLY COMPARED

Every attack call in both files was extracted with comments stripped,
normalised (case, whitespace, `RS_` prefix), sorted and diffed against the
same extraction from CH's `Revenants.txt`. **Result: zero substantive
divergence.** The only diffs were:

* **35 `A_CustomMissile("RevNail",...)` lines present in CH's file, absent
  from ours.** They belong to `MinesRev`, which our tree owns in the
  *cacodemon* lane (`zscript/monsters/cacodemon/RS_CacodemonFX.zs:202`).
  Opened it: all 35 present, same angles, same skipped 170. Not a gap.
* **`A_CustomRailgun(... ,"none",20)` -> `(... ,null,20)`** x2. Documented
  conversion (`RS_RevenantFX.zs` header): `"none"` spawnclass -> `null`.
* **`A_JumpIf(CallACS("CH_*")...)` -> `A_JumpIf(RS_Zom.CV('rs_ch_*', N)...)`**
  x18. Documented conversion, CH's value semantics preserved.
* CH-only `A_Explode` (16), `A_SeekerMissile` (5), `A_SpawnItemEx` (22) all
  reconcile exactly against the ceded classes listed above -- I decomposed
  each count and every one lands.

So the rows below describe CH as well as they describe us, and where they
do not I say so in the row.

---

## TWO CONVENTIONS I HAD TO FIX, STATED SO THE SEVENTEEN FILES COMPOSE

The spec's shape set is closed but gives no numeric split between FAN /
BURST / SALVO / SCATTER. Rather than decide silently per row:

**(A) Geometry decides the shape; timing decides FAN-vs-BURST.**
* angles **fixed or stepped**, shots <=2 tics apart -> **FAN**
* angles **fixed or stepped**, shots >=3 tics apart -> **BURST**
* all angles **identical**, one tic -> **SALVO**
* every shot draws from the **same wide random band** -> **SCATTER**
* full 360 coverage -> **RING**

**(B) `MULTI` is reserved for attacks no single geometric shape covers**
(melee + projectile; rain + cone; a bomb swarm plus a seeker), not for any
attack that happens to name two payload classes. A two-class mirrored pair
is still a FAN, with both classes written into `payload`. Reason: the
spec's own sample counts MULTI at 12/215, which a literal "two classes"
reading could not produce.

Every row records the exact tic list and the exact angle expression, so a
different convention can be re-derived from the row without reopening the
file.

---

## FAMILY-WIDE FACTS THAT WOULD OTHERWISE BE RE-DISCOVERED 18 TIMES

* **`A_SkelFist` is native and the damage is not written anywhere in this
  repo.** Engine: `random(1,10) * 6` (6..60), `DamageType 'Melee'`, plays
  `skeleton/melee` on the hit only if it lands. `A_SkelWhoosh` plays
  `skeleton/swing` and does nothing else. Verified in the running engine's
  own `zscript/actors/doom/revenant.zs`, lines 149-169 (see UNRESOLVED #2
  for where that file was read from).
* **`A_CustomMeleeAttack(dmg)` with no sound arguments is SILENT.** The
  monster's `MeleeSound` property is *not* auto-played by it. Gray, both
  Black Knights and the Knight's shadow all hit silently; only the separate
  `A_SkelWhoosh` / `A_PlaySound("monster/dknswg")` is audible.
* **Nothing in this family plays `AttackSound` from a projectile attack.**
  `A_CustomMissile` plays no sound. Every "attack sound" you hear is the
  *payload's* `SeeSound` firing on spawn. `sound --` in these rows is
  therefore correct and load-bearing, exactly as rs_35 section 4 says.
* **`RS_ColorTierIconCH*`, `RS_Zap99`, `RS_Bounc34`, `RS_SparkPuff1`,
  `RS_Splash11`, `RS_SplashAbyss` (no `2`), `RS_ArchvileFire2`,
  `RS_FrostWingBaron/2`, `RS_FireHand1`, `RS_RedRevLoad`,
  `RS_CyanCybieGunFlare`, `RS_CH_BoneGib`, `RS_DKSword`, `RS_DKShield`,
  `RS_BlackRevShade/2`, `RS_BRevEye/2` all carry NO `Damage`** and are
  omitted from `payload`. They are named in `notes` where they are the
  visible part of an attack.
* **`RS_SplashAbyss2` DOES damage** -- `random(1,9)` Ice
  (`RS_ZombiemanFX.zs:735`). Its parent `RS_SplashAbyss` does not. The Abyss
  Revenant uses the harmful one; every family's `Pain.AbyssPE` morph uses
  the harmless one. Getting these two the wrong way round would invent or
  erase four attacks.
* **Seeking is `A_SeekerMissile` everywhere EXCEPT the Common Revenant**,
  whose tracer inherits vanilla `A_Tracer` from the engine's
  `RevenantTracer` -- a *harder* turn (16.875 deg) applied only on tics
  where `level.maptime & 3 == 0`, i.e. every 4th tic. Different mechanism,
  recorded as such.
* **No subclass in this family strips `+SEEKERMISSILE` from a seeking
  parent.** The nearest thing to that trap is
  `RS_SoulSeekerRev` -> `RS_SoulSeekerRevex`, which are *siblings*, not
  parent/child, and whose seek arguments differ by a factor of 2.4 -- see
  the note on `RS_BlackRevEx2.Seekers`.

---

# ROWS

## RS_BrownRevenant2 -- tier 13, "Mummy mummy" (`RS_Revenant.zs:219`)

```
ATTACK   RS_BrownRevenant2.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:290
shape    MELEE
payload  --   (native A_SkelFist, no actor)
arc      --
timing   0,5,5,5   (15 tics; A_SkelWhoosh at :292, A_SkelFist at :294)
damage   random(1,10)*6   (engine A_SkelFist; NOT written in this repo)
type     Melee
sound    "skeleton/swing" on the whoosh, "skeleton/melee" on a landed hit
impact   -- (instant hit, TraceBleed only)
trigger  Melee
range    ..88   (MeleeRange 88 at :243 -- it OVERRIDES the 102 set at :228)
mirrored no
inherit  --
profile  MakeMelee(range:88, fireSnd:"skeleton/swing", dmgMult:1.0)
notes    MeleeThreshold 106 -- it will not choose Melee beyond that.
         The Default block sets MeleeRange twice (102 then 88); the second
         wins. CH does the same, Revenants.txt:71 / :83.
```

```
ATTACK   RS_BrownRevenant2.Missile
file     zscript/monsters/revenant/RS_Revenant.zs:301
shape    FAN
payload  RS_BrownRevBall x2   (RS_RevenantFX.zs:119)
arc      24   (+12 / -12, from shoulder offsets +12 / -12)
timing   5,0,5,10,[0,0],10   (30 tics; both shots resolve on the same tic)
damage   DamageFunction (random(5,40))
type     Plasma
sound    --   (attack fires silent; each ball plays its own SeeSound
               "imp/attack" on spawn)
impact   A_SetScale(1.6); A_RadiusGive("RS_GrellSlowdown",64,RGF_PLAYERS|RGF_CUBE,1)
         -- a SLOW applied to the player on detonation; 7x RS_ZapFFAT sparks;
         RCHB C,D,E 4 tics each with A_Explode(random(6,9),64) -- THREE
         explosions, one per frame; DeathSound "Crack/death"
trigger  Missile
range    --
mirrored no
inherit  --   (RS_BrownRevBall is a plain Actor; nothing inherited)
profile  MakeVolley(proj:"RS_BrownRevBall", count:2, arc:24, fireSnd:"imp/attack")
notes    SEEKING: +SEEKERMISSILE with A_SeekerMissile(45,45,SMF_PRECISE) --
         a 45-degree threshold and 45-degree max turn, the most aggressive
         homing in the family. Fired at RS_RevenantFX.zs:148 (end of Fly)
         and :159 (state Turn).
         CH QUIRK KEPT: RS_RevenantFX.zs:157 is `A_Jump(64,"Turn")` and the
         VERY NEXT state IS `Turn:`. The jump is a no-op -- the ball always
         reaches Turn and always re-seeks. Verbatim from CH
         (Revenants.txt:202-205).
         ProjectileKickBack 500 -- heavy shove on hit.
```

```
ATTACK   RS_BrownRevenant2.XDeath
file     zscript/monsters/revenant/RS_Revenant.zs:323
shape    UNCLASSIFIED
payload  --   (no projectile; A_RadiusGive x3)
arc      --
timing   0,10,5,5,5,[0],[0,0],[0],25,-1
damage   --   (heals, does not hurt)
type     --
sound    "BASSFFAT" (:319), plus A_Scream at :318
impact   A_RadiusGive("Health",1200,RGF_MONSTERS,500) fired TWICE (:323 is
         `TNT1 AA`, two frames), then
         A_RadiusGive("RS_RevSpeedBuff",1200,RGF_MONSTERS,1) (:324).
         20x RS_BrownVileGas (harmless smoke) at :322.
trigger  XDeath
range    --
mirrored no
inherit  --
profile  MakeRadial(radius:1200, heal:500, hitsAllies:true, fireSnd:"BASSFFAT")
notes    Not an attack -- rowed anyway because it is the single most
         fight-changing thing this monster does: gibbing it heals every
         monster within 1200 units for 500, twice.
         **RS_RevSpeedBuff IS CURRENTLY INERT.** RS_RevenantFX.zs:98-117 --
         its Pickup/Use states are two empty `TNT1 A 0;` lines because CH's
         `ACS_NamedExecuteAlways("BrownRevSPEED")` was stripped per the
         standing order. The same dead token is handed out on every See
         beat at :279 and :287. It costs nothing and does nothing.
```

## RS_CyanRevenant2 -- tier 12, "Cyan Revenant chains" (`RS_Revenant.zs:337`)

```
ATTACK   RS_CyanRevenant2.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:421
shape    MULTI
payload  RS_ChainWhipRev x1   (RS_RevenantFX.zs:251)   [+ native melee hit]
arc      --   (whip fired straight, lateral offset 10)
timing   1,3,3,0,3   (10 tics)
damage   melee random(15,55); whip DamageFunction (random(11,33))
type     Melee (both)
sound    "skeleton/swing" (whoosh :419); "skeleton/melee" on the melee hit
         (passed explicitly at :421); miss sound "none"
impact   whip Death (RS_RevenantFX.zs:279-281): ELEVEN frames of
         A_Explode(random(1,4),8), 2/2/3 tics; DeathSound "weapons/boom1"
trigger  Melee
range    ..88   (MeleeRange 88 at :365, overriding 102 at :350)
mirrored no
inherit  --
profile  MakeMelee(range:88, fireSnd:"skeleton/melee")
         + MakeVolley(proj:"RS_ChainWhipRev", count:1)
notes    MULTI because a native melee hit and a launched projectile land
         together -- no single geometric shape covers it.
         THE WHIP TRAILS A SECOND LIVE PROJECTILE: RS_ChainWhipRev2
         (RS_RevenantFX.zs:286), DamageFunction (random(1,9)), Melee,
         spawned on EVERY flight frame (:274 x4, :276 x3), and each one
         A_Explode(random(1,4),8) on death. The whip is a stream, not a shot.
         The whip starts +NOGRAVITY and turns gravity ON mid-flight
         (:275, `bNOGRAVITY = false`), Gravity 1.25 -- it droops.
         Exits to A_Jump(232,"SeeMe","See2") -- 90% chance of the hop game.
```

```
ATTACK   RS_CyanRevenant2.Missile
file     zscript/monsters/revenant/RS_Revenant.zs:431
shape    BURST
payload  RS_IceORBCyanRev x6   (RS_RevenantFX.zs:217)
arc      volley 1: 0 / 0
         volley 2: randompick(-1,1,-5,5) each, pitch random(-1,1)
         volley 3: randompick(-10,10,-5,5) each, pitch random(-1,1)
timing   1,0,1,1,8,[0],4,8,[0],4,8,[0],4,12   (52 tics; 12 tics per volley)
damage   DamageFunction (random(5,21))
type     Ice
sound    --   (attack silent; each orb plays SeeSound "ice/Cast")
impact   RS_RevenantFX.zs:239-247 -- the orb STALLS on impact (A_Stop),
         holds 11 frames, A_SetScale(4,4), then
         ICEY F 3 Bright A_Explode(random(10,80),128).
         DeathSound "Ice/Hit2". A delayed 128-radius ice bloom.
trigger  Missile   (reached when the A_Jump(128,"IceBomb") at :429 fails)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_IceORBCyanRev", count:6, delayTics:6, arc:20)
notes    Three shoulder-pairs, each pair 4 tics apart internally and 12
         tics between pairs, with the spread WIDENING per pair (0 -> +-5
         -> +-10). MakeBurst is uniform-delay, so 6 x 6 tics = 36 vs CH's
         52. Recorded, not silently rounded.
         The orbs ACCELERATE: A_ScaleVelocity(1.25) every 3 tics
         (RS_RevenantFX.zs:236). Speed 20 nominal, far higher on arrival.
         NOT seeking.
         Exits via A_Jump(64,"Bon") -- a 25% backflip retreat (:455).
```

```
ATTACK   RS_CyanRevenant2.IceBomb
file     zscript/monsters/revenant/RS_Revenant.zs:445
shape    BURST
payload  RS_BigBallCrev x2   (RS_RevenantFX.zs:173)
arc      10   (+5 / -5, shoulder offsets +12 / -12)
timing   1,9,6,6,12   (34 tics; the two shots 6 tics apart)
damage   DamageFunction (random(3,30))
type     Ice
sound    --   (attack silent; each ball plays SeeSound "imp/attack")
impact   see the dedicated row RS_BigBallCrev.Death below -- 24 live ice
         needles. DeathSound "Ice/Hit2".
trigger  Missile   (via A_Jump(128,"IceBomb") from Missile, :429 -- 50%)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_BigBallCrev", count:2, delayTics:6, arc:10)
notes    SEEKING: +SEEKERMISSILE, A_SeekerMissile(18,18,SMF_PRECISE) TWICE
         per flight loop (RS_RevenantFX.zs:200 and :202).
         Speed 38 -- the fastest seeker in the family bar the Red's beam.
         NON-UNIFORM SCALE: Scale = (1.25, 0.75) set in PostBeginPlay
         (:193) because CH's `xscale 1.25 / yscale 0.75` cannot live in a
         Default block on this engine. A squashed disc, not a ball.
         Trails RS_BigBallCrev2 (cacodemon lane,
         zscript/monsters/cacodemon/RS_CacodemonFX.zs:512).
```

```
ATTACK   RS_BigBallCrev.Death   [SECONDARY -- payload impact of IceBomb]
file     zscript/monsters/revenant/RS_RevenantFX.zs:207
shape    RING
payload  RS_SpikeCyanRev x24   (zscript/monsters/demon/RS_DemonFX.zs:153)
arc      360   (four quadrant groups of 6: random(0,90), random(89,180),
                random(181,270), random(271,359))
timing   one tic   (all 24 on 0-tic frames)
damage   DamageFunction (random(1,3))
type     Ice
sound    A_Scream on detonation; needles have DeathSound "" (deliberate)
impact   RS_DemonFX.zs:180 -- RIP1 CBA 6 Bright A_Explode(random(0,1),6),
         three frames
trigger  Missile   (fires when the parent RS_BigBallCrev dies)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_SpikeCyanRev", count:24, arc:360)
notes    Velocities randomised per needle: forward random(12,40),
         upward random(5,25). -NOGRAVITY with Gravity 1.5 -- they arc and
         fall hard. Plus 15 cyan particles and a PUFI puff.
```

## RS_AbyssRevenant2 -- tier 9, "Abyss Revenant" (`RS_Revenant.zs:475`)

```
ATTACK   RS_AbyssRevenant2.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:548
shape    MULTI
payload  RS_SplashAbyss2 x8   (zscript/monsters/zombieman/RS_ZombiemanFX.zs:735)
                              [+ native A_SkelFist hit]
arc      random(-15,15) per splash, pitch offset random(-25,-5) (upward)
timing   2,3,2,4,[0 x8]   (11 tics; the 8 splashes all on one tic)
damage   melee random(1,10)*6; splash DamageFunction (random(1,9))
type     Melee (fist) / Ice (splash)
sound    "skeleton/swing" (whoosh :546); "skeleton/melee" on a landed fist
impact   splash Death (RS_ZombiemanFX.zs:729-732) -- BAL7 C/D/E fade, no
         explode, no DeathSound
trigger  Melee
range    ..88   (MeleeRange 88 at :512)
mirrored no
inherit  RS_SplashAbyss (RS_ZombiemanFX.zs:707) -- the CHILD adds
         DamageFunction, DamageType Ice, Speed 34, -THRUACTORS,
         +MTHRUSPECIES, +DONTHARMCLASS. The PARENT does none of that and
         is harmless. Reading the parent alone reports "no damage".
profile  MakeMelee(range:88, fireSnd:"skeleton/melee")
         + MakeVolley(proj:"RS_SplashAbyss2", count:8, arc:30, pitchJitter:20)
notes    CMF_OFFSETPITCH on the splashes -- pitch is relative to the aim,
         random(-25,-5) throws them UP into the target's face.
         Chains: A_Jump(86,"Missile") at :550 -- ~34% to immediately open
         with the ranged attack after punching.
```

```
ATTACK   RS_AbyssRevenant2.MissileIt
file     zscript/monsters/revenant/RS_Revenant.zs:559
shape    FAN
payload  RS_CrackedAbyssRev x2   (RS_RevenantFX.zs:317)
arc      ~20   (right shot random(-10,1), left shot random(-1,10) --
                distinct per-shoulder bands, offsets +8 / -8)
timing   2,0,12,1,5,8   (28 tics; the two shots 1 tic apart)
damage   DamageFunction (random(6,66))
type     Plasma
sound    --   (attack silent; each ball plays SeeSound "Crack/see")
impact   RS_RevenantFX.zs:350-354 -- 4x RS_ZAP88, then a SINGLE
         A_Explode(random(6,66),66,0) on a 0-tic frame, then BLL9 CDE 6
         Bright. DeathSound "Crack/death".
trigger  Missile   (fallthrough when A_JumpIfCloser(900,"StepDance") at :555
                    fails, i.e. target is FARTHER than 900)
range    900..
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_CrackedAbyssRev", count:2, arc:20)
         ; p.MinRange = 900
notes    SEEKING with SWAPPED ARGUMENTS, verbatim from CH: the first call
         is A_SeekerMissile(6,9,SMF_PRECISE) (RS_RevenantFX.zs:341) and the
         second is A_SeekerMissile(9,6,SMF_PRECISE) (:347) -- threshold and
         turnmax exchanged between the two halves of one flight loop.
         CH Revenants.txt:748 / :754. Not a transcription error here.
         Alpha 1.95 (over-bright Add), Translation "Ice".
         Trails RS_CrackoBallTrail, RS_ZAP88 and RS_AbyssShotIdentifier
         (the last is a cvar-gated debug marker, inert at default).
```

```
ATTACK   RS_AbyssRevenant2.StepDance
file     zscript/monsters/revenant/RS_Revenant.zs:567
shape    MULTI
payload  RS_SplashAbyss2 x47 (rain) + RS_IceOrbAbyssRev x6 (cone)
         (RS_ZombiemanFX.zs:735 / RS_RevenantFX.zs:358)
arc      splashes: placed at random(-328,328) x random(-328,328), not aimed
         orbs: random(-50,50) each, pitch offset random(-35,15)
timing   1,1,1,[0 x47],1,2,2,2,2,2,2,8   (~22 tics)
damage   splash random(1,9); orb DamageFunction (random(6,55))
type     Ice (both)
sound    --   (orbs play SeeSound "ice/Cast" on spawn)
impact   splash: fade, no explode. orb: see RS_IceOrbAbyssRev.Death below.
trigger  Missile   (via A_JumpIfCloser(900,"StepDance") from Missile, :555)
range    ..900
mirrored no
inherit  RS_SplashAbyss for the rain half (see the Melee row)
profile  MakeVolley(proj:"RS_SplashAbyss2", count:47, arc:360)
         + MakeBurst(proj:"RS_IceOrbAbyssRev", count:6, delayTics:2,
                     arc:100, pitchJitter:50)
notes    MULTI: a 656x656 hazard carpet dropped around the monster PLUS a
         6-shot scattered cone, in one beat. No single shape covers it.
         A_Jump(162,"MissileIt") at :565 -- ~63% bails straight back to the
         long-range pair BEFORE any of this fires. StepDance is the
         minority branch of the minority branch.
         The hop (ThrustThingZ(0,64,0,0), :566) is what "StepDance" names.
         The 6 orbs come from `SKEL JJJJKK 2` -- 6 frames, one call each.
```

```
ATTACK   RS_IceOrbAbyssRev.Death   [SECONDARY -- payload impact of StepDance]
file     zscript/monsters/revenant/RS_RevenantFX.zs:396
shape    RAIN
payload  RS_SplashAbyss2 x108   (54 at random(-24,24) x random(-528,528),
                                 54 at random(-528,528) x random(-24,24))
arc      --   (a 1056-unit cross centred on the impact, not aimed)
timing   1,1,1,6,6,6,6,6,6,6,6,[0],3,2,2,2,[0 x108]
damage   blast DamageFunction: A_Explode(random(40,130),128) at :397;
         each splash random(1,9)
type     Ice
sound    DeathSound "Ice/Hit2"
impact   A_SetScale(4,4) then the 128-radius blast, then the cross
trigger  Missile   (fires when the parent orb dies)
range    --
mirrored no
inherit  RS_SplashAbyss
profile  MakeVolley(proj:"RS_SplashAbyss2", count:108, arc:360)
         + MakeRadial(radius:128, damage:85)
notes    The orb itself: Speed 15 but A_ScaleVelocity(1.5) EVERY loop
         (:388) -- it accelerates without bound. VSpeed 1.1, -NOGRAVITY,
         BounceType "Doom", BounceCount 2, BounceFactor 1.5,
         WallBounceFactor 1.5, Scale 2. A_Weave(0,3,0,4) makes it snake.
         SEEKING: A_SeekerMissile(6,6) at :386 -- no SMF_PRECISE, so it
         seeks loosely, unlike this family's other seekers.
         It STALLS on impact (A_Stop, :393) and holds 30 tics before the
         blast -- a long, readable fuse.
```

```
ATTACK   RS_AbyssRevenant2.Phase
file     zscript/monsters/revenant/RS_Revenant.zs:576
shape    RAIN
payload  RS_SplashAbyss2 x94   (two lines of 47, :576 and :578)
arc      --   (random(-128,128) x random(-128,128) around the monster)
timing   1,1,1,[0 x47],18,[0 x47],1,1   (23 tics)
damage   DamageFunction (random(1,9)) each
type     Ice
sound    --   (silent)
impact   fade, no explode, no DeathSound
trigger  Pain   (via A_Jump(76,"Phase") from Pain, :585 -- ~30%)
range    --
mirrored no
inherit  RS_SplashAbyss
profile  MakeBurst(proj:"RS_SplashAbyss2", count:94, delayTics:0, arc:360,
                   trigger:RS_FIRE_PAIN)
notes    Also a self-buff: bNOPAIN = true (:574), A_SetSpeed(99) (:575),
         18 tics of A_Wander at that speed, then A_SetSpeed(11) and
         bNOPAIN = false. It teleport-blinks out of a beating while
         carpeting where it stood.
         Pain.Ice (:587) is a pure resist beat -- plays "RESISTCH" and
         nothing else. Not an attack.
```

```
ATTACK   RS_AbyssRevenant2.Death
file     zscript/monsters/revenant/RS_Revenant.zs:601
shape    RAIN
payload  RS_SplashAbyss2 x47
arc      --   (random(-128,128) x random(-128,128))
timing   0,7,7,7,7,7,[0 x47],-1
damage   DamageFunction (random(1,9)) each
type     Ice
sound    A_Scream (:598); DeathSound "skeleton/death"
impact   fade, no explode
trigger  Death
range    --
mirrored no
inherit  RS_SplashAbyss
profile  MakeBurst(proj:"RS_SplashAbyss2", count:47, delayTics:0, arc:360,
                   trigger:RS_FIRE_DEATH)
notes    Death is gated at :596 by A_JumpIfInventory("RS_CHBoner",1,
         "Tickles") -- the marked-corpse egg path, which jumps to Death+1
         and therefore STILL fires this carpet.
```

## RS_FireBluRevenant2 -- tier 7, "Skeleton on fire!" (`RS_Revenant.zs:614`)

```
ATTACK   RS_FireBluRevenant2.Missile
file     zscript/monsters/revenant/RS_Revenant.zs:670
shape    BURST
payload  RS_FBSkelCH03 x4 + RS_FBSkelCH04 x4
         (RS_RevenantFX.zs:484 / :520)
arc      volley 1: +1 / -1
         volley 2: random(1,5) / random(-5,-1)
         volley 3: random(2,8) / random(-8,-2)
         volley 4: random(3,11) / random(-11,-3)   -- widening
timing   0,9,7,[0,0],14,[0,0],14,[0,0],14,[0,0],20   (78 tics)
damage   Damage 3 (bare) on both -- the engine rolls it, 3..24
type     Fire
sound    --   (attack silent; each round plays SeeSound "fire/fire3")
impact   both: MISL B,C,D 6 tics each with A_Explode(random(5,15),64,0) --
         THREE explosions per round. DeathSound "weapons/plasmax".
trigger  Missile   (fallthrough when A_JumpIfCloser(500,"Spread") at :665
                    fails, i.e. target FARTHER than 500)
range    500..
mirrored yes   (CH04 is CH03 mirrored: A_Weave(6,0,+1.5,0) vs (6,0,-1.5,0),
                and every angle band is the negation of its twin's)
inherit  --
profile  MakeBurst(proj:"RS_FBSkelCH03", count:4, delayTics:14, arc:22)
         + MakeBurst(proj:"RS_FBSkelCH04", count:4, delayTics:14, arc:22)
notes    NOT MULTI by convention (B): two mirrored twin classes, one
         geometry. Both are listed in payload.
         SPIRALLING ROUNDS: WeaveIndexXY 10, WeaveIndexZ 1, and
         A_Weave(6,0,-+1.5,0.0) on every flight frame -- the two streams
         corkscrew in opposite directions and cross.
         **CH'S TRAILS ARE CROSSED AND WE KEPT IT.** CH03 is RED-translated
         and spawns RS_FBSkelTrailer2, which is BLUE (RS_RevenantFX.zs:510,
         :512, :579). CH04 is BLUE-translated and spawns RS_FBSkelTrailer,
         which is RED (:546, :548, :556). Verified against CH
         Revenants.txt:1055/:1057 and :1089/:1091 -- identical there.
         Left as CH has it.
```

```
ATTACK   RS_FireBluRevenant2.Spread
file     zscript/monsters/revenant/RS_Revenant.zs:686
shape    RING
payload  RS_FBSkelCH02 x7 + RS_FBSkelCH01 x7
         (RS_RevenantFX.zs:446 / :408)
arc      360   (fixed angles 5,15,45,75,105,135,165,195,225,255,285,315,
                345,355 -- alternating CH02/CH01)
timing   10,10,[0 x14],20   (40 tics; all 14 on one tic)
damage   Damage 3 (bare) on both -- engine-rolled, 3..24
type     Fire
sound    --   (silent; each round plays SeeSound "fire/fire3")
impact   both: MISL B,C,D 6 tics each with A_Explode(random(7,18),64,0) --
         three explosions per round. DeathSound "weapons/plasmax".
         CH01/CH02 Death ALSO sets +FLATSPRITE (:440 / :478) so the
         explosion lies flat on the floor. XDeath is the same minus that.
trigger  Missile (via A_JumpIfCloser(500,"Spread") from Missile, :665)
         ALSO Pain -> `Goto Spread` (:727) -- being hurt fires the full ring
range    ..500
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_FBSkelCH01", count:7, arc:360)
         + MakeVolley(proj:"RS_FBSkelCH02", count:7, arc:360)
         ; p.MaxRange = 500
notes    ANGLE GAPS ARE NOT EVEN. 5,15 are 10 apart, then 30 apart to 345,
         then 355 is 10 from 345 and 10 from 5. CH's own uneven ring
         (Revenants.txt:894-907). A uniform 14-way ring is 25.7 apart --
         recorded, not smoothed.
         Both classes start +NOGRAVITY and turn gravity ON one frame into
         flight (:433 / :471) -- the ring sags into the floor.
         The Pain trigger makes this monster genuinely dangerous to shoot:
         PainChance 12, but every pain that does land fires all 14.
```

```
ATTACK   RS_FireBluRevenant2.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:708
shape    SINGLE
payload  RS_BoomSkel1 x1   (RS_RevenantFX.zs:584)
arc      --
timing   6,1,1,0,1,0   (9 tics)
damage   Damage 4 (bare, engine-rolled 4..32) on contact;
         A_Explode(random(20,50),64,0) on detonation
type     Fire
sound    "skeleton/swing" (whoosh :704); "weapons/rocklx" (:706)
impact   RS_RevenantFX.zs:604-607 -- Spawn goes STRAIGHT to Death, so it
         detonates essentially at the muzzle: MISL B 2 Bright
         A_Explode(random(20,50),64,0), then MISL CD 2. No DeathSound.
trigger  Melee
range    ..42   (MeleeRange 42 at :648 -- the shortest in the family)
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_BoomSkel1", fireSnd:"weapons/rocklx",
                   bigMuzzle:true)
notes    THERE IS NO A_SkelFist HERE. The "melee" is a point-blank bomb,
         nothing else -- the whoosh is pure animation. A row that assumed
         the family's shared fist would be wrong by 6..60 damage.
         MeleeThreshold 255 -- it will melee from any range it can reach.
```

## RS_GrayRevenant2 -- tier 8, "Punchout master" (`RS_Revenant.zs:760`)

```
ATTACK   RS_GrayRevenant2.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:811
shape    MELEE
payload  --   (A_CustomMeleeAttack x2)
arc      --
timing   1,1,1,1,1,1,1,1   (8 tics -- two full punches)
damage   random(2,8) per punch, twice
type     none   (A_CustomMeleeAttack's damagetype defaults to "none")
sound    "skeleton/swing" x2 (A_SkelWhoosh :809 and :813).
         **THE HITS ARE SILENT** -- A_CustomMeleeAttack(random(2,8)) passes
         no meleesound, and the actor's MeleeSound "skeleton/melee" is NOT
         played automatically.
impact   -- (instant)
trigger  Melee
range    ..72   (MeleeRange 72 at :790)
mirrored yes   (A_SetScale(-1.0,1.0) at :812 flips the sprite for the
                second punch; See resets it with A_SetScale(1.0,1.0) at :801)
inherit  --
profile  MakeBurst(proj:null, count:2, delayTics:4, trigger:RS_FIRE_MELEE)
         -- or MakeMelee(range:72, fireSnd:"skeleton/swing") called twice
notes    Tiny damage (2..8 x2) but Speed 18 and MeleeThreshold 255 and
         +NOPAIN -- the whole design is relentless closing, not per-hit
         weight. That is the profile worth lifting, not the numbers.
```

```
ATTACK   RS_GrayRevenant2.BoneIt
file     zscript/monsters/revenant/RS_Revenant.zs:821
shape    BURST
payload  RS_BoneToPickGrey x3   (RS_RevenantFX.zs:614)
arc      shot 1: 0; shot 2: random(-1,1); shot 3: random(-3,3)
timing   8,2,2,6,2,2,4,2,2   (30 tics; gaps SHRINK 8 -> 6 -> 4)
damage   DamageFunction (random(10,40))
type     Melee
sound    --   (attack silent; each bone plays SeeSound "skelatt")
impact   RS_RevenantFX.zs:637-641 -- 5 white particles,
         A_SetScale(0.3,0.3), MISL BCD 3. DeathSound "swordhit".
         XDeath (:642-646) instead plays "COCONUTT" and spawns
         RS_BoneToPickGray2, a bouncing bone with NO Damage.
trigger  Missile   (fallthrough when A_JumpIfCloser(1000,"Closer") at :818
                    fails, i.e. target FARTHER than 1000)
range    1000..
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_BoneToPickGrey", count:3, delayTics:6, arc:6)
         ; p.MinRange = 1000
notes    THE CADENCE ACCELERATES. 8 -> 6 -> 4 tics between shots. MakeBurst
         is uniform, so delayTics:6 averages it (18 vs CH's 18 -- exact by
         luck, the shape is still lost). Recorded.
         +FORCEPAIN -- every bone that connects guarantees a pain state on
         the victim regardless of PainChance. That, not the damage roll,
         is what this attack is for.
         +BLOODLESSIMPACT, +SKYEXPLODE, Speed 36.
```

```
ATTACK   RS_GrayRevenant2.Closer
file     zscript/monsters/revenant/RS_Revenant.zs:832
shape    CHARGE
payload  --   (the monster IS the projectile)
arc      --
timing   0,2   (then Goto Melee)
damage   --   **See UNRESOLVED #3.** The monster declares no `Damage`
         property, so the A_SkullAttack contact hit has nothing to roll.
         The damage that lands is the Melee state it falls into.
type     --
sound    AttackSound   -- this actor declares NONE, so A_SkullAttack's
         A_StartSound(AttackSound, CHAN_VOICE) plays nothing
impact   -- (a ram; ends in Melee)
trigger  Missile   (via A_JumpIfCloser(1000,"Closer") from Missile, :818)
range    ..1000
mirrored no
inherit  --
profile  MakeSelfBuff(speedMult:2.5, duration:35)  -- the closest existing
         factory; there is no charge/ram mode in RS_AttackProfile
notes    A_SkullAttack(45) -- ram speed 45 against a walk Speed of 18.
         A_Jump(32,"BoneIt") at :831 gives a ~12.5% chance to throw bones
         instead even inside 1000.
         Falls into Melee, which is where the damage actually is.
```

## RS_CommonRevenant -- tier 1, "Revenant" (`RS_Revenant.zs:880`, `: Revenant`)

```
ATTACK   RS_CommonRevenant.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:924
shape    MELEE
payload  --
arc      --
timing   1,6,6,6   (19 tics)
damage   random(1,10)*6   (engine A_SkelFist)
type     Melee
sound    "skeleton/swing" (:926); "skeleton/melee" on a landed hit
impact   --
trigger  Melee
range    ..88   (MeleeRange 88 at :909)
mirrored no
inherit  Revenant (engine) for everything not overridden
profile  MakeMelee(range:88, fireSnd:"skeleton/swing")
notes    MeleeThreshold 196.
```

```
ATTACK   RS_CommonRevenant.Missile
file     zscript/monsters/revenant/RS_Revenant.zs:935
shape    FAN
payload  RS_RevenantTracer2 x2   (RS_RevenantFX.zs:678)
arc      2   (+1 / -1, shoulder offsets +7 / -7)
timing   0,10,9,[0,0],10   (29 tics; both on the same tic)
damage   DamageFunction (random(5,50))   -- OVERRIDES the engine's Damage 10
type     fire   -- OVERRIDES the engine's default (none)
sound    --   (attack silent; each tracer plays INHERITED SeeSound
               "skeleton/attack")
impact   **ALL INHERITED** -- FBXP A 8 / B 6 / C 4 Bright and DeathSound
         "skeleton/tracex" come from the engine's RevenantTracer, not from
         RS_RevenantTracer2, which overrides ONLY DamageType and
         DamageFunction. Reading RS_RevenantFX.zs:678-685 alone reports
         "no impact FX" for an attack that has one.
trigger  Missile
range    --
mirrored no
inherit  RevenantTracer (engine) -- Radius 11, Height 8, Speed 10,
         +SEEKERMISSILE, +RANDOMIZE, RenderStyle Add, SeeSound
         "skeleton/attack", DeathSound "skeleton/tracex", the FATB flight
         sprite, the FBXP death sprite, and A_Tracer
profile  MakeVolley(proj:"RS_RevenantTracer2", count:2, arc:2,
                    fireSnd:"skeleton/attack")
notes    SEEKING IS `A_Tracer`, NOT `A_SeekerMissile` -- the only such case
         in this family. Turn is a fixed 16.875 degrees and is applied only
         on tics where `level.maptime & 3 == 0`, i.e. once every four tics.
         Chunky, vanilla-feeling homing rather than the smooth
         A_SeekerMissile arc every other payload here uses. A_Tracer also
         spawns a BulletPuff and a RevenantTracerSmoke behind the round.
         **DOOM 1 HAZARD:** this payload draws `FATB` (flight) and `FBXP`
         (explosion), the two Doom-2-only prefixes CLAUDE.md records as
         still unresolved on `doom.wad` and explicitly OUTSIDE the granted
         extraction. On Ultimate Doom the tier-1 revenant's signature
         homing missile renders NOTHING. Flagged, not touched.
```

## RS_GreenRevenant -- tier 2, "Green Revenant" (`RS_Revenant.zs:1007`)

```
ATTACK   RS_GreenRevenant.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:1061
shape    MELEE
payload  --
arc      --
timing   3,0,6,6,6   (21 tics)
damage   random(1,10)*6   (engine A_SkelFist)
type     Melee
sound    "skeleton/swing" (:1059); "skeleton/melee" on a landed hit
impact   --
trigger  Melee
range    ..88
mirrored no
inherit  --
profile  MakeMelee(range:88, fireSnd:"skeleton/swing")
notes    2x RS_Splash11 acid droplets at :1058 -- Damage 0, cosmetic
         (zscript/monsters/demon/RS_DemonFX.zs:183).
         MeleeThreshold 255.
```

```
ATTACK   RS_GreenRevenant.Missile
file     zscript/monsters/revenant/RS_Revenant.zs:1069
shape    FAN
payload  RS_AcidBlast1 x2   (zscript/monsters/lostsoul/RS_LostSoulFX.zs:1120)
arc      2   (+1 / -1, shoulder offsets +7 / -7)
timing   0,9,0,7,[0,0],8   (24 tics; both on the same tic)
damage   DamageFunction (random(5,55))
type     Plasma
sound    --   (attack silent; each ball plays SeeSound "baron/attack")
impact   RS_LostSoulFX.zs:1145 -- BAL7 CDE 6 Bright, NO A_Explode.
         DeathSound "baron/shotx". Decal "BaronScorch".
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_AcidBlast1", count:2, arc:2,
                    fireSnd:"baron/attack")
notes    SEEKING: +SEEKERMISSILE, A_SeekerMissile(11,11,SMF_PRECISE) on
         every other flight frame (RS_LostSoulFX.zs:1139).
         Speed 14, FastSpeed 25. Trails RS_Trail11
         (zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:84).
         Direct contact only -- no splash, unlike almost everything else in
         this family. The highest single-hit roll of the low tiers (55).
```

## RS_BlueRevenant -- tier 3, "Blue Revenant" (`RS_Revenant.zs:1144`)

```
ATTACK   RS_BlueRevenant.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:1209
shape    MELEE
payload  --
arc      --
timing   3,5,5,4   (17 tics)
damage   random(1,10)*6   (engine A_SkelFist)
type     Melee
sound    "skeleton/swing" (:1207); "skeleton/melee" on a landed hit
impact   --
trigger  Melee
range    ..88
mirrored no
inherit  --
profile  MakeMelee(range:88, fireSnd:"skeleton/swing")
notes    MeleeThreshold 300.
```

```
ATTACK   RS_BlueRevenant.Falcon
file     zscript/monsters/revenant/RS_Revenant.zs:1220
shape    CHARGE
payload  --   (the monster IS the projectile)
arc      --
timing   4,0,0,0,2   (then Goto Melee)
damage   --   **See UNRESOLVED #3** -- no `Damage` property on the monster.
         The Melee it falls into is the damage.
type     --
sound    AttackSound -- not declared on this actor, so silent
impact   --
trigger  Missile   (via A_JumpIfCloser(300,"Falcon") from Missile, :1214)
range    ..300
mirrored no
inherit  --
profile  MakeSelfBuff(speedMult:2.5, duration:35)
notes    A_SkullAttack(30) against a walk Speed of 12.
         **DASH BUDGET, a real mechanic worth lifting.** `user_nodash1`
         (declared :1146): each Falcon costs +5 (:1219), each Blastings
         refunds -2 (:1236), and at >=11 Falcon is refused and routes to
         Blastings (:1218). Net effect: ~3 dashes, then it is forced to
         stand and shoot for ~3 volleys before it can dash again.
         RS_AttackProfile has no cooldown/budget field -- flagged in
         UNRESOLVED #5.
```

```
ATTACK   RS_BlueRevenant.Blastings
file     zscript/monsters/revenant/RS_Revenant.zs:1226
shape    MULTI
payload  RS_Zap7 x2 (opener) + RS_Zap8 x7 (salvo)
         (RS_LostSoulFX.zs:1152 / RS_RevenantFX.zs:690)
arc      Zap7:  random(0,2) at offset +7, random(-2,0) at offset -7
         Zap8:  random(4,7)@-7, random(-7,-4)@+7, 0@+7, 0@-7,
                random(4,7)@-7, random(-7,-4)@+7, random(-7,7)@-7
timing   0,12,5,[0,0],12,[0 x7],0,8   (37 tics)
damage   Zap7 DamageFunction (random(20,50));
         Zap8 DamageFunction (random(11,33))
type     Plasma (both)
sound    --   (both play SeeSound "weapons/plasmaf")
impact   both: PLSE CDE 6 Bright, DeathSound "weapons/plasmax", NO explode
trigger  Missile   (via A_Jump(255,"Blastings") from Missile, :1215 --
                    guaranteed when outside 300; also the Falcon overflow)
range    300..     (inside 300 the Falcon dash wins, budget permitting)
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_Zap7", count:2, arc:4, fireSnd:"weapons/plasmaf")
         + MakeVolley(proj:"RS_Zap8", count:7, arc:14)
notes    MULTI: two classes doing genuinely different jobs -- a 2-shot
         heavy opener (20..50 each) followed 12 tics later by a 7-shot
         light wall (11..33 each) all on ONE tic. No single shape covers it.
         NEITHER IS SEEKING. Both A_ScaleVelocity(1.15) every frame
         (RS_LostSoulFX.zs:1172 / RS_RevenantFX.zs:711) -- they accelerate
         from Speed 15 continuously. FastSpeed 32 / 38.
         Blue is the family's only "pure ballistic" tier: everything it
         throws flies straight and fast.
```

## RS_PurpleRevenant -- tier 4, "Purple Revenant" (`RS_Revenant.zs:1307`)

```
ATTACK   RS_PurpleRevenant.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:1384
shape    MELEE
payload  --
arc      --
timing   3,4,0,4,4   (15 tics)
damage   random(1,10)*6   (engine A_SkelFist)
type     Melee
sound    "skeleton/swing" (:1381); "skeleton/melee" on a landed hit
impact   --
trigger  Melee
range    ..88
mirrored no
inherit  --
profile  MakeMelee(range:88, fireSnd:"skeleton/swing")
notes    RS_Zap99 spark at :1382 -- Damage 0, cosmetic. This monster fires
         RS_Zap99 at 11 sites across See/Jumper2/Melee/Missile/Fireing1/
         Fireing2/Pain; NONE of them damage. RS_Zap99 (RS_RevenantFX.zs:722)
         is Speed 1, Projectile, no Damage, and spawns 3x RS_Bounc34
         (:743, +NOINTERACTION, no Damage). Pure ambience.
         MeleeThreshold 200.
```

```
ATTACK   RS_PurpleRevenant.Falcon2
file     zscript/monsters/revenant/RS_Revenant.zs:1397
shape    CHARGE
payload  --
arc      --
timing   4,0,0,0,0,2   (then Goto Melee)
damage   --   **See UNRESOLVED #3** -- no `Damage` property on the monster.
type     --
sound    AttackSound -- not declared, silent
impact   --
trigger  Missile   (via A_JumpIfCloser(300,"Falcon2") from Missile, :1390)
range    ..300
mirrored no
inherit  --
profile  MakeSelfBuff(speedMult:3.0, duration:35)
notes    A_SkullAttack(40) against a walk Speed of 13.
         Same dash budget as Blue but on `user_nodash2` (:1309): +5 per
         dash (:1396), -2 per Fireing2 (:1407), refused at >=11 (:1395,
         routing to Fireing2).
```

```
ATTACK   RS_PurpleRevenant.Fireing2
file     zscript/monsters/revenant/RS_Revenant.zs:1403
shape    FAN
payload  RS_Purp1 x2   (RS_LostSoulFX.zs:1180)
arc      4   (random(0,2)@+7, random(-2,0)@-7)
timing   4,0,0,0,0,9,5,[0,0],8,0,0,8   (34 tics)
damage   DamageFunction (random(10,30))
type     Plasma
sound    --   (attack silent; each ball plays SeeSound "baron/attack")
impact   RS_LostSoulFX.zs:1207 -- BAL1 CDE 6 Bright A_Explode(random(35,45),64)
         on EACH of three frames. DeathSound "weapons/plasmax".
trigger  Missile   (via A_JumpIfCloser(1800,"Fireing2") from Missile, :1391)
range    300..1800
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_Purp1", count:2, arc:4, fireSnd:"baron/attack")
notes    **THIS PAYLOAD BURNS WHAT IT PASSES.** RS_LostSoulFX.zs:1202 is
         `BAL1 AA 1 Bright A_Explode(random(8,18),45)` -- TWO frames, so
         A_Explode fires TWICE per flight loop, radius 45, forever, in
         flight. It is a moving 45-unit damage aura, not a projectile that
         hurts on arrival. The repo comment there marks it deliberate
         ("CH's graze aura"). CH: Revenants.txt:2142.
         SEEKING: +SEEKERMISSILE, A_SeekerMissile(4,5) -- the WEAKEST seek
         in the family (4-degree threshold, 5-degree turn). It barely
         corrects; the graze aura is how it lands.
         Speed 13, FastSpeed 14 -- also the slowest. Trails RS_Trail22.
```

```
ATTACK   RS_PurpleRevenant.Fireing1
file     zscript/monsters/revenant/RS_Revenant.zs:1416
shape    HITSCAN
payload  --   (instant trace; puff RS_FatsoPuff3, RS_RevenantFX.zs:2036)
arc      0   (spread_xy 0, spread_z 0; the two beams differ only by the
              +7 / -7 lateral spawn offset)
timing   4,0,0,0,0,0,15,15,5,0,[0,0],10,0,8   (57 tics -- a long telegraph)
damage   random(2,20) per beam, x2 beams
type     none   (A_CustomRailgun has no damagetype parameter; the puff
                 carries no DamageType either)
sound    --   (A_CustomRailgun plays nothing; no A_PlaySound in the state)
impact   RS_FatsoPuff3 -- Speed 16, +NOINTERACTION, no Damage. A pure
         visual. The beam itself is purple->white, RGF_FULLBRIGHT.
trigger  Missile   (via A_Jump(255,"Fireing1") from Missile, :1392 -- the
                    guaranteed fallthrough when both range gates fail)
range    1800..
mirrored no
inherit  --
profile  MakeHitscan(fireSnd:"", spreadScale:0.0, impactPuff:"RS_FatsoPuff3")
         ; p.MinRange = 1800
         -- MakeHitscan is the nearest factory; RS_AttackProfile has no
            railgun mode. See UNRESOLVED #5.
notes    Full call, both beams identical but for the offset sign:
         A_CustomRailgun(random(2,20), +-7, "purple", "white",
                         RGF_FULLBRIGHT, 1, 0, "RS_FatsoPuff3", 0, 0,
                         10000, 0, 1, 1, null, 20)
         -- aim 1, maxdiff 0, RANGE 10000, duration 0, sparsity 1,
            driftspeed 1, spawnclass null, spawnofs_z 20.
         Range 10000 is effectively map-wide: this is the family's only
         true sniper. Damage is small (2..20) but instant and unavoidable.
         A_CheckSight("See") at :1415 aborts the shot if LOS is lost
         DURING the 34-tic windup -- a real tell the player can break.
         A_MonsterRefire(120,"See") at :1420 then `Goto Missile` loops it.
         The `null` spawnclass is our conversion of CH's `"none"`
         (Revenants.txt:1994-1995); documented, not a change of behaviour.
```

## RS_SpecialSoul -- the escort soul, no tier token (`RS_Revenant.zs:1489`)

```
ATTACK   RS_SpecialSoul.Missile
file     zscript/monsters/revenant/RS_Revenant.zs:1545
shape    HITSCAN
payload  --   (puff RS_PsychPuff, RS_LostSoulFX.zs:1095)
arc      +-8 horizontal, +-8 vertical (spread_xy 8, spread_z 8)
timing   10,4,4,4   (22 tics)
damage   1 per bullet, x random(1,3) by the engine's own roll = 1..3 each,
         across random(1,6) bullets
type     Hitscan   (A_CustomBulletAttack's fixed damage type)
sound    AttackSound "skull/melee" -- A_CustomBulletAttack DOES play
         AttackSound on CHAN_WEAPON. The only attack in this family that
         makes a noise of its own.
impact   RS_PsychPuff -- +NOBLOCKMAP, +NOGRAVITY, Alpha 0.5, Scale 0.3,
         no Damage. Visual only.
trigger  Missile
range    ..2048   (MISSILERANGE default; no range argument given)
mirrored no
inherit  --
profile  MakeHitscan(fireSnd:"skull/melee", spreadScale:0.13,
                     impactPuff:"RS_PsychPuff")
notes    Total per burst: 1..18. Trivial damage -- this thing exists to
         chip and to soak, not to kill.
         It is a TETHERED escort: See (:1540) does
         A_JumpIfMasterCloser(720,"See") and otherwise
         A_Warp(AAPTR_MASTER,5,1,6,0,...) -- it snaps back to its master
         the moment it drifts past 720 units.
         Spawned four at a time by RS_YellowRevenant.Script3 (:1634-1637,
         SXF_SETMASTER) and singly by nothing else.
         +NOCLIP, +NOTARGET, +NOINFIGHTING, Health 75, Speed 7.
```

## RS_YellowRevenant -- tier 5, "Terrifying Orange (NoClip?) Revenant" (`RS_Revenant.zs:1571`)

```
ATTACK   RS_YellowRevenant.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:1665
shape    MELEE
payload  --
arc      --
timing   6,0,4,4,0,4   (18 tics)
damage   random(1,10)*6   (engine A_SkelFist)
type     Melee
sound    "skeleton/swing" (:1662); "skeleton/melee" on a landed hit
impact   --
trigger  Melee
range    ..94   (MeleeRange 94 at :1618)
mirrored no
inherit  --
profile  MakeMelee(range:94, fireSnd:"skeleton/swing")
notes    RS_SparkPuff1 at :1661 and :1664 -- cosmetic, no Damage
         (zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:209).
         MeleeThreshold 200. In its default spawn (Script3) this monster is
         +NOCLIP and walks through walls to reach you.
```

```
ATTACK   RS_YellowRevenant.SpitIt
file     zscript/monsters/revenant/RS_Revenant.zs:1681
shape    BURST
payload  RS_FirespeNewYel x4   (RS_RevenantFX.zs:793)
arc      12   (random(-6,6) per shot), pitch offset random(-5,-1) (upward)
timing   4,0,0,8,8,3,3,3,3,5   (37 tics; 3 tics between shots)
damage   DamageFunction (random(8,24))
type     Fire
sound    --   (attack silent; each blob plays SeeSound "Fire/fire1")
impact   RS_RevenantFX.zs:815-819 -- MISL B 5, MISL C 5 A_Explode(7,64),
         MISL D 5 A_SpawnItemEx("RS_FireSpe2",...) -- ONE lingering ground
         flame. No DeathSound.
         RS_Firespe2 (zscript/monsters/imp/RS_ImpFX.zs:327) then burns:
         A_Explode(random(1,2),41) on every frame of a looping 6-frame
         chain that can re-thrust itself and persists for a long time.
trigger  Missile   (Missile -> A_JumpIfCloser(600,"NewMove") :1670 ->
                    A_JumpIf(speed >= 20,"SpitIt") :1676)
range    ..600   AND speed >= 20
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_FirespeNewYel", count:4, delayTics:3, arc:12,
                   pitchJitter:4)
         ; p.MaxRange = 600
notes    **THIS ATTACK IS UNREACHABLE AT THE SHIPPED DEFAULT.** The speed
         gate only passes after Script1 runs A_SetSpeed(24) (:1640), and
         Script1 needs `rs_ch_yellowrev` == 1 or a coin-flip from == 2.
         That cvar is NOT in this repo's CVARINFO.txt, so RS_Zom.CV returns
         the CH default 0 and Spawn always falls to Script3 (:1632), which
         leaves Speed 7. Documented in the class header (:1564-1569) and
         faithful to CH. Flagged in UNRESOLVED #6.
         CMF_AIMOFFSET|CMF_OFFSETPITCH -- the blobs are lobbed upward.
         Each blob also ThrustThingZ(0,random(6,18),0,0) mid-flight (:812)
         and then self-detonates after ~30 tics whether it hit or not.
         A_CheckSight("See") at :1682 aborts the tail of the burst.
```

```
ATTACK   RS_YellowRevenant.Proje
file     zscript/monsters/revenant/RS_Revenant.zs:1693
shape    FAN
payload  RS_Homer1 x2   (zscript/monsters/lostsoul/RS_LostSoulFX.zs:1239)
arc      10   (random(0,5)@+9, random(-5,0)@-9)
timing   4,0,0,0,0,9,5,[0,0],8,0,8   (34 tics)
damage   DamageFunction (random(8,52))
type     Fire
sound    --   (attack silent; each homer plays "Fire/fire3" on its first
               0-tic frame AND SeeSound "fire/fire1" on spawn)
impact   RS_LostSoulFX.zs:1262 -- MISL B,C,D 6 tics each with
         A_Explode(random(5,35),64): THREE explosions. DeathSound
         "fire/fire5". Repo marks the per-frame explode deliberate
         ("CH's blast bloom").
trigger  Missile   (Missile -> A_JumpIfCloser(1500,"Projeor") :1672 ->
                    A_Jump(78,"Proje") :1685 (~30%), else
                    A_Jump(255,"Proje","HellFlame") :1686 (50/50))
range    600..1500   (and the close-range fallthrough via Missile+4)
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_Homer1", count:2, arc:10, fireSnd:"fire/fire1")
         ; p.MinRange = 600 ; p.MaxRange = 1500
notes    SEEKING: +SEEKERMISSILE, A_SeekerMissile(18,18,SMF_PRECISE)
         (RS_LostSoulFX.zs:1257). Speed 11, FastSpeed 22 -- slow, hard
         homing. It follows you around corners at walking pace.
         Trails RS_SparkPuff1.
         Sprite note carried from the FX header: RS_Homer1's Spawn opens on
         `SBS1 A 0` where CH wrote `SBSI` -- a CH typo on a 0-tic
         sound-only frame, corrected 2026-08-06 (owner: nothing invisible).
```

```
ATTACK   RS_YellowRevenant.HellFlame
file     zscript/monsters/revenant/RS_Revenant.zs:1703
shape    VILE
payload  RS_BigBadFire1 x1   (zscript/monsters/baron/RS_BaronFX.zs:254)
arc      --   (A_VileTarget spawns AT the target's position; no travel)
timing   0,14,10,8,9   (41 tics)
damage   A_Explode(5,25) on EVERY frame of a looping 5-frame spawn chain
         (RS_BaronFX.zs:271-273), then A_Explode(random(4,10),64) on death
type     Fire
sound    --   (RS_BigBadFire1 has no SeeSound; DeathSound "Fire/fire5")
impact   RS_BaronFX.zs:275-281 -- MISL B 5, MISL C 5 A_Explode(random(4,10),64),
         MISL D 5 + four more 0-tic frames each spawning RS_FireSpe1 =
         **5 bouncing embers**, scattered random(-32,32) x random(-32,32).
         Each RS_Firespe1 (zscript/monsters/imp/RS_ImpFX.zs:293) is +TOUCHY,
         Gravity 0.4, BounceType "Heretic", and on ITS death does
         A_Explode(7,64) plus **6x RS_Firespe2** lingering flames, each of
         which A_Explode(random(1,2),41) per frame for a long loop.
trigger  Missile   (Missile -> A_Jump(255,"HellFlame") :1673 when beyond
                    1500, or the 50% branch of Projeor at :1686)
range    1500..   (plus the Projeor branch inside 1500)
mirrored no
inherit  --
profile  MakeRadial(radius:25, damage:5, fireSnd:"fire/fire4")
         -- no VILE mode exists; MakeRadial is the nearest. UNRESOLVED #5.
notes    THE CASCADE IS THE ATTACK: 1 fire -> 5 embers -> 30 lingering
         flames, all damaging, all on the ground where you were standing.
         A_VileTarget does NOT check line of sight (only A_VileAttack
         does) -- it spawns on the target wherever the target is. Verified
         in the engine's own zscript/actors/doom/archvile.zs:113-128.
         RS_FireHand1 at :1701 (RS_BaronFX.zs:230) is the visible hand
         flame -- Speed 0, +NOINTERACTION, NO DAMAGE. It is the tell, not
         the attack. A row that credited it would double-count.
         RS_FireHand1 and RS_BigBadFire1 are CH Revenants.txt:2556/:2578
         but are owned by the baron lane under the file-order rule
         (RS_RevenantFX.zs header, :30-31). Referenced read-only.
```

```
ATTACK   RS_YellowRevenant.FlameSplit
file     zscript/monsters/revenant/RS_Revenant.zs:1710
shape    RING
payload  RS_Firespe1 x8   (zscript/monsters/imp/RS_ImpFX.zs:293)
arc      360   (random(-360,360) per ember, independently)
timing   0,5,5,[0 x8]   (10 tics; all 8 on one tic)
damage   contact: none declared. A_Explode(7,64) on death, then 6x
         RS_Firespe2 each doing A_Explode(random(1,2),41) per frame
type     Fire
sound    --   (each ember plays SeeSound "Fire/fire1")
impact   RS_ImpFX.zs:313-321 -- MISL B 5, MISL C 5 A_Explode(7,64),
         MISL D 4 + five 0-tic frames spawning RS_Firespe2 (6 total),
         scattered random(-32,32) x random(-32,32)
trigger  Pain   (via A_Jump(76,"FlameSplit") from Pain, :1740 -- ~30%)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_Firespe1", count:8, arc:360)
         ; p.FireTrigger = RS_FIRE_PAIN
notes    Retaliation, not a chosen attack. 8 embers in random full-circle
         directions -> up to 48 lingering ground flames. Speed 20,
         +TOUCHY (detonates on contact with anything), Gravity 0.4,
         BounceType "Heretic".
         PainChance 30 overall but PainChance "fire" 8 -- burning it rarely
         triggers this; bullets do.
```

```
ATTACK   RS_YellowRevenant.XDeath
file     zscript/monsters/revenant/RS_Revenant.zs:1762
shape    UNCLASSIFIED
payload  RS_ArcRing1 x1 (RS_LostSoulFX.zs:1724)
         + RS_ArchvileFire2 x9 (RS_RevenantFX.zs:772) -- ZERO DAMAGE
arc      the 9 fires at fixed 0,45,90,135,180,225,270,305,340
timing   5,1,1,[0 x9],24, then a 60-tic fade
damage   --   (nothing here hurts)
type     --
sound    A_Scream (:1763); RS_ArcRing1 SeeSound "Fire/fire3"
impact   RS_ArcRing1 Death (RS_LostSoulFX.zs:1748) --
         A_RadiusGive("RS_GrowRaisin",100,RGF_MONSTERS|RGF_CORPSES,3):
         it hands the TIER-UP token to every monster AND EVERY CORPSE
         within 100 units. Corpses that later Raise take the Grow branch
         and come back one tier higher.
trigger  XDeath
range    --
mirrored no
inherit  RS_ArchvileFire2 : ArchvileFire (engine) -- and the override sets
         Damage 0, +NOCLIP, +THRUACTORS. The parent has no damage either;
         in vanilla the harm comes from A_VileAttack, which is never
         called here. So the ring is pure spectacle.
profile  MakeRadial(radius:100, heal:0, hitsAllies:true)
         -- there is no "promote allies" mode; see UNRESOLVED #5
notes    Rowed because it changes the room, not because it hurts. Gibbing
         an orange revenant tiers up the corpses around it.
         Note the angle list skips the even step twice: 305 and 340 where
         315 and 360 would be even. CH's own (Revenants.txt:2477-2478).
```

## RS_RedRevenant -- tier 6, "a Bloody Red Revenant" (`RS_Revenant.zs:1791`)

```
ATTACK   RS_RedRevenant.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:1857
shape    MELEE
payload  --   (A_SkelFist TWICE)
arc      --
timing   1,6,5,3,3   (18 tics)
damage   random(1,10)*6 per fist, TWICE (:1857 and :1858)
type     Melee
sound    "skeleton/swing" (:1855); "skeleton/melee" per landed hit
impact   --
trigger  Melee
range    ..94   (MeleeRange 94 at :1834)
mirrored no
inherit  --
profile  MakeBurst(proj:null, count:2, delayTics:3, trigger:RS_FIRE_MELEE)
         -- or MakeMelee(range:94, fireSnd:"skeleton/swing") twice
notes    12..120 in 6 tics at Speed 14. The heaviest melee below the
         Black Knight. MeleeThreshold 200.
```

```
ATTACK   RS_RedRevenant.Missile
file     zscript/monsters/revenant/RS_Revenant.zs:1865
shape    SINGLE
payload  RS_RedDeathRev x1   (zscript/monsters/lostsoul/RS_LostSoulFX.zs:1270)
arc      random(-4,4)   (shoulder offset +9)
timing   1,0,1,9,10,0,10,2   (33 tics)
damage   DamageFunction (random(25,85))
type     Fire
sound    --   (attack silent; the ball plays SeeSound "Forgotten/Attack")
impact   RS_LostSoulFX.zs:1289-1293 -- MISL B 3 A_SetScale(1.4),
         MISL C 3 A_SetTranslucent(0.65), MISL D 3 A_Explode(random(5,20),128),
         MISL D 5 A_Explode(random(5,35),128). TWO blasts at radius 128.
         DeathSound "spell/Impact1".
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_RedDeathRev", fireSnd:"Forgotten/Attack",
                   bigMuzzle:true)
notes    SEEKING: +SEEKERMISSILE, A_SeekerMissile(7,12) TWICE per flight
         loop (RS_LostSoulFX.zs:1284 and :1286). No SMF_PRECISE.
         Speed 24, FastSpeed 38, Scale 0.65. Trails RS_CrackoBallTrail.
         **CHARGE COUNTER:** `user_ttt` (:1793) +1 per shot (:1866); at
         >=4 the Missile state routes to MegaShot instead (:1863). So
         every FIFTH ranged attack is the big one. MegaShot then -4.
         SPRITE FIX RECORDED IN-REPO: this payload's death held `MISL E`
         in CH, a frame vanilla MISL does not have (it is 8 lumps, A-D).
         It rendered nothing in CH too; our copy holds D for E's 5 tics.
         Tic count and A_Explode unchanged. See RS_LostSoulFX.zs:1292.
```

```
ATTACK   RS_RedRevenant.MegaShot
file     zscript/monsters/revenant/RS_Revenant.zs:1875
shape    SINGLE
payload  RS_MegaRedRev x1   (zscript/monsters/hellknight/RS_HellKnightFX.zs:784)
arc      random(-4,4)   (shoulder offset +9)
timing   5,5,5,5,10,15,7,5,1,1   (59 tics -- a 45-tic telegraph)
damage   DamageFunction (random(35,95))
type     Plasma
sound    "Skeleton/Sight" played deliberately at :1871 as the tell.
         The beam itself plays SeeSound "Crack/see" on spawn.
impact   RS_HellKnightFX.zs:806 -- BLL9 CDE 6 tics each with
         A_Explode(random(15,55),64): THREE blasts. DeathSound "Litn/litn3".
trigger  Missile   (via A_JumpIf(user_ttt >= 4,"MegaShot") from Missile, :1863)
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_MegaRedRev", fireSnd:"Skeleton/Sight",
                   bigMuzzle:true, spawnHeight:60)
notes    **SPEED 90.** Nothing else in the family is close. It is NOT
         seeking -- it does not need to be. 45 tics of windup, then an
         effectively instant round for 35..95 plus 45..165 of splash.
         The player's counterplay is the 45-tic tell and nothing else.
         RS_RedRevLoad at :1873 (RS_ChaingunnerFX.zs:230) is the charge
         flare -- +NOCLIP, +NOINTERACTION, no Damage.
         The beam trails RS_RedRevLoad2 (RS_HellKnightFX.zs:812) which
         itself spawns more RS_RedRevLoad. All cosmetic.
```

```
ATTACK   RS_RedRevenant.XDeath
file     zscript/monsters/revenant/RS_Revenant.zs:1923
shape    BURST
payload  RS_HKRedDeath x9   (zscript/monsters/zombieman/RS_ZombiemanFX.zs:844)
arc      random(-16,16) per blast, spawn height random(12,64)
timing   1,0,1,7,[1 x9],24   (~43 tics; 1 tic between blasts)
damage   A_Explode(random(5,10),42) each, plus A_Burst("RS_RedThingsHK")
type     Fire
sound    "world/barrelx" twice per blast (RS_ZombiemanFX.zs:859 and :863)
impact   RS_ZombiemanFX.zs:861-865 -- Spawn goes STRAIGHT to Death, so each
         one detonates where it is spawned: MISL B 8 Bright
         A_Explode(random(5,10),42); MISL C 6 A_PlaySound("world/barrelx");
         MISL D 3 A_Burst("RS_RedThingsHK"). DeathSound "world/barrelx".
trigger  XDeath
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_HKRedDeath", count:9, delayTics:1, arc:32,
                   fireSnd:"world/barrelx", trigger:RS_FIRE_XDEATH)
notes    A string of nine barrel blasts over nine tics. Modest per-blast
         (5..10, r42) but they overlap.
         RS_RedRevLoad at :1920 is cosmetic.
         PAIN IS A ONE-WAY SELF-BUFF: Pain (:1897) permanently sets
         bNOPAIN = true (:1902) and bMISSILEEVENMORE = true (:1903). The
         first time you stagger it is the last. Not an attack, but it is
         what makes the fight change shape.
```

## RS_BlackRevenant3 -- tier 10, "The Black Knight" phase 1 (`RS_Revenant.zs:1949`)

```
ATTACK   RS_BlackRevenant3.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:2037
shape    MELEE
payload  --
arc      --
timing   6,1,6,6   (19 tics)
damage   random(20,120)
type     none   (A_CustomMeleeAttack default)
sound    "monster/dknswg" (the swing, :2035). **THE HIT IS SILENT** --
         no meleesound argument; MeleeSound "monster/dknhit" is never
         auto-played.
impact   --
trigger  Melee
range    ..92   (MeleeRange 92 at :1960)
mirrored no
inherit  --
profile  MakeMelee(range:92, fireSnd:"monster/dknswg")
notes    No MeleeThreshold declared -- it melees whenever it can reach.
```

```
ATTACK   RS_BlackRevenant3.DartCleave
file     zscript/monsters/revenant/RS_Revenant.zs:2048
shape    FAN
payload  RS_DKDart x5   (RS_RevenantFX.zs:919)
arc      24   (random(-6,-2), random(-12,-7), 0, random(7,12), random(2,6))
timing   9,8,[0 x5],5   (22 tics; all five on one tic)
damage   Damage 5 (bare) -- engine-rolled, 5..40
type     Fire
sound    "monster/kntswg" (:2047); each dart plays SeeSound "monster/dkndrt"
impact   see the dedicated row RS_DKDart.Death below -- an 8-way fire ring
         per dart. DeathSound "weapons/firex2".
trigger  Missile   (via A_Jump(255,"DartCleave","Mines","Dash") from
                    Missile, :2043 -- one third)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_DKDart", count:5, arc:24, fireSnd:"monster/kntswg")
notes    The angle bands overlap deliberately: -12..-7, -6..-2, 0, +2..+6,
         +7..+12. It is a cleave, not an even fan.
         Speed 28, +THRUGHOST, +MTHRUSPECIES, RenderStyle Add.
         Direct damage is modest; the ground fire it leaves is the attack.
```

```
ATTACK   RS_DKDart.Death   [SECONDARY -- payload impact of DartCleave]
file     zscript/monsters/revenant/RS_RevenantFX.zs:944
shape    RING
payload  RS_DKFire x8   (RS_RevenantFX.zs:959)
arc      360   (fixed 45,90,135,180,225,270,315,0; flags 2 =
                CMF_AIMDIRECTION, so they radiate from the impact)
timing   0,3,3,[0 x7],3,3,3,3,3,3   (~24 tics)
damage   impact blast A_Explode(random(5,55),64) at :944;
         each RS_DKFire then ExplosionDamage 4 / ExplosionRadius 8 fired by
         a bare A_Explode() on EVERY frame of a 21-frame spawn chain
         (:979) plus 3 more on death (:982)
type     Fire (the dart); RS_DKFire declares no DamageType
sound    DeathSound "weapons/firex2" (dart); "weapons/scorch" (each fire)
impact   RS_DKFire has Damage 0 on contact -- ALL of its harm is the
         repeated A_Explode. It is a ground-denial flame, not a projectile.
trigger  Missile   (fires when a dart dies)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_DKFire", count:8, arc:360)
         + MakeRadial(radius:64, damage:30)
notes    Per DartCleave: 5 darts x 8 fires = **40 crawling flames**, each
         ticking 4 damage in an 8-unit radius 24 times over ~72 tics.
         Speed 6 -- they crawl outward slowly and the floor stays lethal.
         This is the single largest multiplier in the family and it is
         entirely invisible from the monster's own state code.
```

```
ATTACK   RS_BlackRevenant3.Mines
file     zscript/monsters/revenant/RS_Revenant.zs:2058
shape    BURST
payload  RS_MinesRev x2   (zscript/monsters/cacodemon/RS_CacodemonFX.zs:202)
arc      24   (-12 / +12, lateral offset -4 on both)
timing   8,2,[0],6,0,0   (16 tics; the two mines 6 tics apart)
damage   DamageFunction (random(10,40)) on contact
type     Fire
sound    --   (each mine plays SeeSound "monster/dknmsl", BounceSound
               "fire/fire3" on every bounce)
impact   see the dedicated row RS_MinesRev.Death below.
         DeathSound "weapons/boom1".
trigger  Missile   (via A_Jump(255,"DartCleave","Mines","Dash") :2043)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_MinesRev", count:2, delayTics:6, arc:24)
notes    A_Jump(64,"Mines") at :2061 -- 25% chance to immediately fire the
         pair again, and again, compounding.
         A_UnSetReflectiveInvulnerable at :2060 -- it drops its reflective
         guard to throw. That is the window.
         The mines BOUNCE FOREVER: BounceType "Doom", BounceCount 999,
         BounceFactor 0.85, WallBounceFactor 1.3, Gravity 0.9. In flight
         they roll A_Jump(12,"Death") (~4.7% self-detonate per loop) and
         A_Jump(32,"Bounce") (~12.5% random re-thrust).
         THEY DROP AMMO ON DEATH: RocketAmmo 64/256, Shell 128/256,
         ImplyingClip 174/256, Cell 32/256 (RS_CacodemonFX.zs:225-228).
```

```
ATTACK   RS_MinesRev.Death   [SECONDARY -- payload impact of Mines]
file     zscript/monsters/cacodemon/RS_CacodemonFX.zs:243
shape    RING
payload  RS_RevNail x35   (zscript/monsters/cacodemon/RS_CacodemonFX.zs:283)
arc      360   (0,10,20 ... 160, then 180,190 ... 350 -- **170 IS SKIPPED**,
                which is CH's own and is kept)
timing   0,[5 x5],[0 x35]   (25 tics)
damage   mine blast A_Explode(random(5,15),88) on EACH of five frames;
         each nail DamageFunction (random(5,15))
type     Fire (blast) / Melee (nails)
sound    DeathSound "weapons/boom1"; each nail
         AttackSound "moloch/nailhitbleed", DeathSound "weapons/firex4"
impact   RS_CacodemonFX.zs:307-311 -- "moloch/nailhit", then 6PUF ABCDEF 1
         with A_Explode(random(2,5),64) per frame, then FBL1 EFG 1 with
         A_Explode(random(2,8),64) per frame, then RS_PuffCybieRed.
         Nine explosions per nail.
trigger  Missile   (fires when a mine dies)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_RevNail", count:35, arc:360)
         + MakeRadial(radius:88, damage:50)
notes    Speed 55 nails, +EXTREMEDEATH, +BLOODSPLATTER, +SPAWNSOUNDSOURCE,
         Decal "BulletChip".
         Per Mines volley: 2 mines x 35 nails = 70, each with a 9-frame
         explosion chain. This is why the mines look harmless and are not.
```

```
ATTACK   RS_BlackRevenant3.Dash
file     zscript/monsters/revenant/RS_Revenant.zs:2065
shape    CHARGE
payload  --   (the monster IS the projectile)
arc      --
timing   8,[8 x5],4   (52 tics)
damage   --   **See UNRESOLVED #3** -- no `Damage` property on the monster.
type     --
sound    AttackSound -- not declared, silent
impact   A_Stop at :2066, then Goto Melee
trigger  Missile   (via A_Jump(255,"DartCleave","Mines","Dash") :2043)
range    --
mirrored no
inherit  --
profile  MakeSelfBuff(speedMult:3.8, duration:44)
notes    **A_SkullAttack(38) IS CALLED FIVE TIMES**, once per frame of
         `DKNT FFFFF 8` (:2065), 8 tics apart. Each call re-faces the
         target and re-launches -- so this is a TRACKING charge that
         corrects four times mid-flight, not a straight ram. That is the
         thing worth lifting and it is invisible unless you notice the
         five-frame sprite string.
         A_UnSetReflectiveInvulnerable at :2064 -- guard down for the whole
         dash. Ends in Melee for random(20,120).
```

```
ATTACK   RS_BlackRevenant3.Shield
file     zscript/monsters/revenant/RS_Revenant.zs:2073
shape    SINGLE
payload  RS_ShieldBlastRev x1   (RS_RevenantFX.zs:826)
arc      0
timing   0,0,60,10,10   (80 tics)
damage   DamageFunction (random(10,65))
type     Fire
sound    --   (the blast plays SeeSound "fire/fire3")
impact   RS_RevenantFX.zs:870-873 -- BBOM A 2 A_SetScale(1.5),
         BBOM B 2 A_SetTranslucent(0.65),
         BBOM C,D 3 tics each A_Explode(random(5,25),148),
         BBOM E,F,G 6 tics each A_Explode(random(5,20),148).
         **FIVE blasts at radius 148** -- the largest blast radius in the
         family bar the Lich's channel. DeathSound "spell/Impact1".
trigger  Pain   (via A_Jump(178,"Shield") from Pain, :2080 -- ~70%)
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_ShieldBlastRev", fireSnd:"fire/fire3",
                   bigMuzzle:true)
         ; p.FireTrigger = RS_FIRE_PAIN
notes    THE SHIELD IS THE OTHER HALF. :2069 sets bNOPAIN = true, :2070
         spawns RS_RevShieldWalk (RS_RevenantFX.zs:878) as a SXF_SETMASTER
         child: Health 999, +INVULNERABLE +REFLECTIVE +DEFLECT
         +SHIELDREFLECT, Radius 64, warping to master+24 forward, z+42
         every 3 tics. It REFLECTS your shots back at you for 60 tics.
         Then A_KillChildren("extreme") at :2072 destroys it and the blast
         fires. bNOPAIN back to false at :2074.
         **THE PAYLOAD ACCELERATES WHILE SEEKING.** Speed 12 at spawn, then
         A_SetSpeed 16 / 20 / 24 / 30 through Fly..Fly7, with
         A_SeekerMissile(12,18) at :850, :854, :858, :862, :866 and :867.
         It starts slow enough to dodge and ends faster than you run.
         Scale = (1.0, 1.45) set in PostBeginPlay (:846) -- CH's
         non-uniform yScale, which cannot live in a Default block here.
         ShieldSee (:2029) spawns the same shield without the blast, from
         Pain.Melee / Pain.Ice (:2087) and Pain.Fire (:2093). Defensive
         only, not rowed.
```

## RS_BlackRev2 -- tier 10, "Just a flesh wound", phase 2 (`RS_Revenant.zs:2113`)

```
ATTACK   RS_BlackRev2.Shots
file     zscript/monsters/revenant/RS_Revenant.zs:2185
shape    SCATTER
payload  RS_RevSol x3   (RS_RevenantFX.zs:1079)
arc      18   (random(-9,9), random(-1,1), random(-9,9) -- overlapping
                bands from the same centre)
timing   5,5,5,[0 x3]   (15 tics; all three on one tic)
damage   DamageFunction (random(10,50))
type     Fire
sound    --   (each plays SeeSound "monster/dkndrt")
impact   RS_RevenantFX.zs:1102-1106 -- A_SetTranslucent(0.85),
         DKAT D 3 A_SetScale(1.5), DKAT E 3 A_Explode(random(5,30),128),
         then DKAT FGH and IJKLM. DeathSound "weapons/firex2".
trigger  Missile   (via A_Jump(255,"Seekers","AoE","Shots") from Missile,
                    :2181 -- one third)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_RevSol", count:3, arc:18)
notes    SCATTER by convention (A): all three draw from bands sharing one
         centre, two of them identical.
         Speed 32, +THRUGHOST, NOT seeking. A straight fast shotgun.
```

```
ATTACK   RS_BlackRev2.AoE
file     zscript/monsters/revenant/RS_Revenant.zs:2192
shape    RING
payload  RS_DKFire2 x8   (RS_RevenantFX.zs:1111)
arc      360   (fixed 45,90,135,180,225,270,315,0; flags 2 =
                CMF_AIMDIRECTION -- relative to facing, so a true ring)
timing   5,5,5,5,[0 x8],5,5   (30 tics)
damage   contact Damage 0. Harm is A_Explode(random(5,15),12) on EVERY
         frame of a 21-frame spawn chain (:1130) -- 21 pulses each.
type     none declared on RS_DKFire2
sound    "Spell/SpellCast1" (:2191); each fire DeathSound "weapons/scorch"
impact   see the dedicated row RS_DKFire2.Death below
trigger  Missile   (via A_Jump(255,...) :2181)
         ALSO Pain -> A_Jump(128,"AoE") at :2221 (50%)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_DKFire2", count:8, arc:360)
notes    Speed 8 -- eight slow flames crawling outward in a ring, each
         pulsing 5..15 damage in a 12-unit radius 21 times.
         A_Jump(12,"Death") at :1131 gives ~4.7% per loop to burst early.
         The 50% Pain trigger makes shooting it into a room-filling fire.
```

```
ATTACK   RS_DKFire2.Death   [SECONDARY -- payload impact of AoE]
file     zscript/monsters/revenant/RS_RevenantFX.zs:1134
shape    RING
payload  RS_DKFire x8   (RS_RevenantFX.zs:959)
arc      360   (fixed 45,90,135,180,225,270,315,0; CMF_AIMDIRECTION)
timing   3,3,3,[0 x7],3
damage   A_Explode(random(5,20),20) on each of three frames (:1134),
         then each RS_DKFire pulses ExplosionDamage 4 / radius 8, 24 times
type     none declared
sound    DeathSound "weapons/scorch" on both tiers
impact   RS_DKFire is Damage 0 on contact; all harm is the repeated bare
         A_Explode()
trigger  Missile   (fires when an RS_DKFire2 dies)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_DKFire", count:8, arc:360)
         + MakeRadial(radius:20, damage:12)
notes    Per AoE cast: 8 x 8 = **64 crawling flames**. Same escalation as
         RS_DKDart.Death and it stacks with it whenever phase 1 has
         already carpeted the room.
```

```
ATTACK   RS_BlackRev2.Seekers
file     zscript/monsters/revenant/RS_Revenant.zs:2205
shape    BURST
payload  RS_SoulSeekerRev x6   (RS_RevenantFX.zs:1044)
arc      38   (each pair random(-19,-9) and random(9,19))
timing   6,6,[0,0],6,6,[0,0],6,6,[0,0],2   (38 tics; 12 tics per pair)
damage   DamageFunction (random(5,20))
type     Melee
sound    --   (each plays SeeSound "skull/melee")
impact   RS_RevenantFX.zs:1070-1074 -- A_SetTranslucent(0.85),
         DKAT D 3 A_SetScale(1), DKAT E 3 A_Explode(random(5,20),64),
         then DKAT FGH and IJKLM. DeathSound "weapons/firex2".
trigger  Missile   (via A_Jump(255,"Seekers","AoE","Shots") :2181)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_SoulSeekerRev", count:6, delayTics:12, arc:38)
notes    **THE STATE LOOPS ON ITSELF.** :2215 is
         A_MonsterRefire(64,"See") followed by `Goto Seekers` (:2216) --
         it keeps pouring seekers until the refire check sends it back to
         See. Six per pass is a floor, not a ceiling.
         SEEKING: +SEEKERMISSILE, A_SeekerMissile(12,24,SMF_PRECISE) on
         every 4-tic frame (:1067) -- 12-degree threshold, 24-degree turn,
         precise. Strong homing at Speed 22.
         +THRUGHOST, +MTHRUSPECIES, Scale 0.45.
         Fired wide (9..19 off centre) precisely because they turn back in.
```

## RS_BlackRevenantEX -- tier 10, "The Black Knight unleashed" (`RS_Revenant.zs:2238`)

```
ATTACK   RS_BlackRevenantEX.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:2342
shape    MELEE
payload  --
arc      --
timing   3,1,4,4,0,4,0   (16 tics)
damage   random(50,140)
type     none   (A_CustomMeleeAttack default)
sound    "monster/dknswg" (:2340); "BKFuKINV" after the hit (:2343).
         The hit itself is silent.
impact   --
trigger  Melee
range    ..92   (MeleeRange 92 at :2249)
mirrored no
inherit  --
profile  MakeMelee(range:92, fireSnd:"monster/dknswg")
notes    Chains: A_Jump(128,"Grap2") at :2345 -- 50% to immediately follow
         the punch with a hook throw.
         Scale 1.2 -- physically larger than phase 1.
```

```
ATTACK   RS_BlackRevenantEX.ShieldBlast
file     zscript/monsters/revenant/RS_Revenant.zs:2361
shape    MULTI
payload  RS_ShieldBombRev x32 (RS_RevenantFX.zs:1254)
         + RS_ShieldBlastRev x1 (RS_RevenantFX.zs:826)
arc      bombs random(-7,7) each, spawn height random(32,56) each;
         the blast dead centre
timing   10,10,2,[0 x8],[1 x8],[0 x8],[1 x8],8   (~48 tics)
damage   bomb DamageFunction (random(2,25));
         blast DamageFunction (random(10,65))
type     Fire (both)
sound    --   (bombs play SeeSound "imp/attack"; the blast "fire/fire3")
impact   bomb: BAL1 CDE 1 A_SetTranslucent(0.35) -- NO explode.
         DeathSound "weapons/firex4". Direct hits only.
         blast: five A_Explode at radius 148 (see the phase-1 Shield row).
trigger  Missile   (via A_Jump(255,"DartCleave","ShieldBlast","Dash") from
                    Missile, :2352 -- one third, OUTSIDE 1000)
range    1000..
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_ShieldBombRev", count:32, delayTics:0, arc:14)
         + MakeHeavy(proj:"RS_ShieldBlastRev", fireSnd:"fire/fire3")
         ; p.MinRange = 1000
notes    MULTI: a 32-round suppression stream and a single seeking heavy
         in one beat -- no one shape covers it.
         The 32 come as four groups of 8: two groups fire all 8 on ONE tic
         (:2361, :2363, both `TNT1 AAAAAAAA 0`) and two groups spread 8
         over 8 tics (:2362, :2364, both `DKNT UUUUUUUU 1`). Bursts and
         walls alternating.
         Speed 34, Mass 5, Scale 0.55 -- small, fast, many.
```

```
ATTACK   RS_BlackRevenantEX.Grap
file     zscript/monsters/revenant/RS_Revenant.zs:2369
shape    SINGLE
payload  RS_BlackRevHook x1   (RS_RevenantFX.zs:1182)
arc      0 (Grap) / random(-13,13) (Grap2, :2375)
timing   3,3,3,3,3,2   (17 tics)
damage   DamageFunction (random(5,30))
type     Melee
sound    --   (plays SeeSound "monster/dknmsl")
impact   RS_RevenantFX.zs:1202-1206 -- BLAD A 10, BLAD A 10,
         BLAD AAA 10 A_FadeOut(0.33). **NO explode, no damage on arrival.**
         DeathSound "weapons/firex4".
trigger  Missile   (Grap: via A_Jump(255,"DartCleave","Mines","Dash","Grap")
                    from Choice2, :2355, INSIDE 1000)
                   (Grap2: from Melee :2345 at 50%, Mines :2403 at ~41%,
                    Dash :2409 at 25%)
range    ..1000   for Grap; Grap2 has no range gate
mirrored no
inherit  **NOMINALLY `Loreshot` -- WHICH DOES NOT EXIST ANYWHERE IN CH.**
         CH writes `ACTOR BlackRevHook : Loreshot` (Revenants.txt:3907) and
         the name `Loreshot` appears nowhere else in the CH tree, so CH's
         own BlackRevHook fails to load. Rebuilt here on plain `Actor`
         carrying CH's whole body; nothing invented to stand in.
         Recorded in the FX header (:55-60). See UNRESOLVED #4.
profile  MakeVolley(proj:"RS_BlackRevHook", count:1, fireSnd:"monster/dknmsl")
notes    **THE HOOK LAYS A LIVE MINEFIELD BEHIND ITSELF.** Its Spawn state
         (:1200) is a one-tic loop doing
         A_SpawnItemEx("RS_FatsoSpikes2",0,0,1,...) -- EVERY TIC, at
         Speed 42. RS_FatsoSpikes2 (zscript/monsters/imp/RS_ImpFX.zs:216)
         is DamageFunction (random(10,40)), DamageType Melee, Gravity 0.1,
         and on death does A_Explode(random(1,4),8) across ELEVEN frames.
         The hook's own 5..30 is the least of it; the corridor it draws is
         the attack.
         Grap and Grap2 are one attack (identical bodies, one angle
         argument apart) reached from different states -- merged per the
         spec's "not a second row" rule.
         NAMED "Hook" BUT NOTHING PULLS. No A_Warp, no thrust, no tether
         anywhere in the class. The grapple behaviour presumably lived in
         the missing `Loreshot` parent. Flagged, not invented.
```

```
ATTACK   RS_BlackRevenantEX.DartCleave
file     zscript/monsters/revenant/RS_Revenant.zs:2382
shape    FAN
payload  RS_DKDart x9   (RS_RevenantFX.zs:919)
arc      36   (random(-6,-2), random(-3,-1), random(-12,-7),
                random(-18,9), 0, random(9,18), random(7,12),
                random(1,3), random(2,6))
timing   9,8,[0 x9],5,0   (22 tics; all nine on one tic)
damage   Damage 5 (bare) -- engine-rolled, 5..40
type     Fire
sound    "monster/kntswg" (:2381), "BKFuKINV" on exit (:2392); each dart
         plays SeeSound "monster/dkndrt"
impact   as RS_DKDart.Death above -- 8 crawling fires per dart, so
         **72 flames per cleave**
trigger  Missile   (A_Jump(255,"DartCleave","ShieldBlast","Dash") :2352
                    outside 1000; A_Jump(255,"DartCleave","Mines","Dash",
                    "Grap") :2355 inside 1000)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_DKDart", count:9, arc:36, fireSnd:"monster/kntswg")
notes    **THE 4TH BAND IS ASYMMETRIC AND THAT IS CH's, NOT A TYPO HERE.**
         `random(-18,9)` (:2385) spans 27 degrees across the centre line
         while every sibling band is 4-6 degrees wide on one side.
         Verified byte-for-byte against CH Revenants.txt. Kept.
```

```
ATTACK   RS_BlackRevenantEX.Mines
file     zscript/monsters/revenant/RS_Revenant.zs:2397
shape    FAN
payload  RS_MinesRev x4   (zscript/monsters/cacodemon/RS_CacodemonFX.zs:202)
arc      48   (-12, -24, +24, +12; lateral offset -4 on all)
timing   8,2,[0,0,0],6,0,0,0   (16 tics; three on one tic, the fourth 6
                                tics later)
damage   DamageFunction (random(10,40)) on contact
type     Fire
sound    --   (SeeSound "monster/dknmsl", BounceSound "fire/fire3")
impact   as RS_MinesRev.Death above -- 35 nails each, so **140 nails**
trigger  Missile   (via A_Jump(255,"DartCleave","Mines","Dash","Grap")
                    from Choice2, :2355 -- INSIDE 1000 only)
range    ..1000
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_MinesRev", count:4, arc:48)
notes    Chains twice: A_Jump(64,"Mines") at :2402 (25% repeat) and
         A_Jump(106,"Grap2") at :2403 (~41% into a hook throw).
         A_UnSetReflectiveInvulnerable at :2401 -- guard down.
```

```
ATTACK   RS_BlackRevenantEX.Dash
file     zscript/monsters/revenant/RS_Revenant.zs:2407
shape    CHARGE
payload  --
arc      --
timing   8,[8 x5],4,0,0   (52 tics)
damage   --   **See UNRESOLVED #3** -- no `Damage` property on the monster.
type     --
sound    "BKFuKINV" on exit (:2410). AttackSound not declared, so the
         A_SkullAttack itself is silent.
impact   A_Stop at :2408, then A_Jump(64,"Grap","Grap2") at :2409, then
         Goto Melee
trigger  Missile   (both routers, :2352 and :2355)
range    --
mirrored no
inherit  --
profile  MakeSelfBuff(speedMult:3.0, duration:44)
notes    A_SkullAttack(42) called FIVE times, 8 tics apart -- same tracking
         charge as phase 1 but faster (42 vs 38) from a higher walk Speed
         (14 vs 10).
         A_UnSetReflectiveInvulnerable at :2406.
```

```
ATTACK   RS_BlackRevenantEX.Shield
file     zscript/monsters/revenant/RS_Revenant.zs:2417
shape    SINGLE
payload  RS_ShieldBlastRev x1   (RS_RevenantFX.zs:826)
arc      0
timing   0,0,50,10,10,9,9,9,0,0   (~97 tics)
damage   DamageFunction (random(10,65))
type     Fire
sound    "BKFuKINV" on exit (:2420); the blast plays SeeSound "fire/fire3"
impact   five A_Explode at radius 148 -- see the phase-1 Shield row
trigger  Pain   (via A_Jump(178,"Shield") from Pain, :2426 -- ~70%)
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_ShieldBlastRev", fireSnd:"fire/fire3")
         ; p.FireTrigger = RS_FIRE_PAIN
notes    Shorter guard than phase 1 (50 tics vs 60) but it leaves
         **THREE ORBITING SHIELDS BEHIND**: :2418 is
         `DKNT UUU 9 Bright A_SpawnItemEx("RS_RevShieldWalk2",...)`,
         three frames, SXF_SETTARGET.
         RS_RevShieldWalk2 (RS_RevenantFX.zs:1210) orbits its TARGET at
         64 units, `user_angle += 8` per tic (:1241-1242,
         WARPF_ABSOLUTEANGLE), +INVULNERABLE +REFLECTIVE +DEFLECT
         +SHIELDREFLECT, and dies only on A_Jump(2,"Death") (:1243) --
         roughly 0.8% per tic, so ~128 tics of expected life each.
         Three reflective bodies circling the boss is a real mechanic and
         it is spawned from an attack state, which is why it is here.
         ShieldSee (:2333) spawns BOTH shield types from Pain.Ice (:2432)
         and Pain.Fire (:2438). Defensive only, not rowed.
```

## RS_BlackRevEx3 -- tier 10, "The Black Knight's shadow" (`RS_Revenant.zs:2460`)

```
ATTACK   RS_BlackRevEx3.Melee
file     zscript/monsters/revenant/RS_Revenant.zs:2515
shape    MELEE
payload  --
arc      --
timing   6,1,6,6   (19 tics)
damage   random(20,120)
type     none   (A_CustomMeleeAttack default)
sound    "monster/dknswg" (:2513). The hit is silent.
impact   --
trigger  Melee
range    ..92   (MeleeRange 92 at :2471)
mirrored no
inherit  --
profile  MakeMelee(range:92, fireSnd:"monster/dknswg")
notes    **THE SHADOW'S ONLY ATTACK.** No Missile state exists.
         Health 20000, Speed 5, +NOCLIP, +NOBLOOD, +NOINFIGHTING,
         RenderStyle "Stencil" / StencilColor "black", +THRUSPECIES.
         It cannot be outrun into geometry and it cannot practically be
         killed -- it is killed by killing RS_BlackRevEx2:
         See (:2504-2505, :2508-2509) checks
         A_JumpIfInventory("RS_PowerRevEx",1,"Death") and
         A_CheckProximity("Death","RS_BlackRevEx2",9999,0,CPXF_NOZ|
         CPXF_EXACT) twice per walk cycle. RS_BlackRevEx2's Death hands
         out RS_PowerRevEx at radius 9999 (:2665).
         DamageFactor "DIMp" 0 and PainChance "DIMp" 0 are its only
         resistances of note.
```

## RS_BlackRevEx2 -- tier 10, "Just a shade wound", EX phase 2 (`RS_Revenant.zs:2540`)

```
ATTACK   RS_BlackRevEx2.Shots
file     zscript/monsters/revenant/RS_Revenant.zs:2623
shape    FAN
payload  RS_RevSolex x4   (RS_RevenantFX.zs:1433)
arc      18   (random(-9,1)@+5, random(-1,2)@0, random(-1,9)@-5,
                random(-2,1)@0)
timing   5,5,[0 x4]   (10 tics; all four on one tic)
damage   DamageFunction (random(10,50))
type     Fire
sound    --   (each plays SeeSound "monster/dkndrt")
impact   RS_RevenantFX.zs:1460-1464 -- A_SetTranslucent(0.85),
         DKAT D 3 A_SetScale(1.5), DKAT E 3 A_Explode(random(5,30),128),
         then DKAT FGH and IJKLM. DeathSound "weapons/firex2".
trigger  Missile   (via A_Jump(255,"Seekers","AoE","Shots") from Missile,
                    :2619 -- one third)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_RevSolex", count:4, arc:18)
notes    **THE DIFFERENCE FROM RS_RevSol IS THAT THIS ONE BOUNCES.**
         +BOUNCEONWALLS, BounceType "Hexen", BounceCount 2,
         BounceFactor 1.5, Speed 34 (vs 32). Same damage, same blast --
         but corners stop being cover. A row that reused the RS_RevSol
         entry would miss the entire point of the EX variant.
         Distinct per-shot bands and a 4-shot structure -> FAN, not
         SCATTER, unlike phase 2's 3-shot version.
```

```
ATTACK   RS_BlackRevEx2.AoE
file     zscript/monsters/revenant/RS_Revenant.zs:2631
shape    RAIN
payload  RS_RainFireRevEX x10   (RS_RevenantFX.zs:1469)
arc      --   (placed at random(-528,528) x random(-528,528),
                z random(-64,64), velocity random(-5,5)/0/random(-5,5),
                angle random(-359,359) -- not aimed at anything)
timing   5,5,5,5,[1 x10],5,5   (~40 tics)
damage   DamageFunction (random(5,12)) on contact
type     none declared on RS_RainFireRevEX
sound    "Spell/SpellCast1" (:2630); DeathSound "weapons/scorch"
impact   RS_RevenantFX.zs:1491 -- DKAT UVW 3 Bright A_Explode(random(2,8),32,0)
         on each of three frames.
         **THE TRAIL IS THE REAL DAMAGE.** :1488 spawns
         RS_RainFireRevEXTrail on EVERY frame of a 21-frame chain -- 21
         sub-drops per drop, each with random(-10,10) velocity spread.
         RS_RainFireRevEXTrail (:1496) is DamageFunction (random(1,3)),
         Gravity 0.05, and does A_Explode(random(1,3),16,0) on every frame
         of its own 21-frame chain plus 3 on death.
trigger  Missile   (via A_Jump(255,"Seekers","AoE","Shots") :2619)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_RainFireRevEX", count:10, arc:360)
notes    A 1056 x 1056 box of falling fire centred on the boss. Ten drops,
         210 sub-drops, each pulsing ~24 times. Individually trivial;
         collectively the arena floor becomes damage.
         Replaces phase-2's 8-way RS_DKFire2 ring with an area denial that
         does not care where you are.
         +DONTHARMCLASS and +MTHRUSPECIES on both tiers -- it cannot hurt
         the boss or its own kind.
```

```
ATTACK   RS_BlackRevEx2.Seekers
file     zscript/monsters/revenant/RS_Revenant.zs:2637
shape    FAN
payload  RS_SoulSeekerRevex x4   (RS_RevenantFX.zs:1369)
arc      90   (random(-19,-9)@0, random(9,19)@0,
                random(-45,-30)@+32, random(30,45)@-32)
timing   6,6,[0 x4],2   (14 tics; all four on one tic, then loop)
damage   DamageFunction (random(10,30))
type     Melee
sound    --   (each plays SeeSound "skull/melee")
impact   RS_RevenantFX.zs:1398-1402 -- A_SetTranslucent(0.85),
         DKAT D 3 A_SetScale(2.4,0.75), DKAT E 3
         A_Explode(random(10,30),128), then DKAT FGH and IJKLM.
         DeathSound "weapons/firex2".
trigger  Missile   (via A_Jump(255,"Seekers","AoE","Shots") :2619)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_SoulSeekerRevex", count:4, arc:90)
notes    **LOOPS ON ITSELF** -- :2641 A_MonsterRefire(64,"See") then
         `Goto Seekers` (:2642). Four per pass is a floor.
         **THE EX SEEKER IS A DIFFERENT ATTACK FROM THE PHASE-2 SEEKER,
         AND NOT IN THE DIRECTION THE NAME SUGGESTS.**
           RS_SoulSeekerRev   : Speed 22, dmg random(5,20),  blast r64,
                                A_SeekerMissile(12,24,SMF_PRECISE)
           RS_SoulSeekerRevex : Speed 19, dmg random(10,30), blast r128,
                                A_SeekerMissile(5,10) -- NO SMF_PRECISE
         The EX version is SLOWER and homes FAR more weakly (5/10 vs
         12/24, and without precise mode) while hitting twice as hard over
         twice the radius. They are siblings, not parent and child --
         neither strips +SEEKERMISSILE from the other -- but treating them
         as the same profile would be wrong on four axes.
         Fired 30-45 degrees wide from +-32 shoulder offsets, which the
         weak seek can no longer fully correct: they sweep past you.
         Trails RS_SoulSeekerRevTrail (:1407, cyan stencil, no damage).
```

## RS_WhiteRevenant2 -- tier 11, "Lichest Lich" (`RS_Revenant.zs:2682`)

Routing, because nothing else in the family is this deep:

```
Missile (:2760) --A_JumpIfHealthLower(4500)--> Enrage (:2871)
                                                 |-- already enraged --> Nah --> Missile2
                --A_JumpIfCloser(1500)--------> CloseChoice (:2842)
                                                 = GroundPain | FrostMines | IceBreath
                                                   | DeathCoil | IceBolt   (equal fifths)
                --else------------------------> IceBolt | DeathCoil (50/50)

Missile2 (:2791) --A_JumpIfCloser(1500)-------> CloseChoice2 (:2839)
                                                 = GroundPainex | SummonHelp
                                                   | DeathCoil | IceBolt   (equal quarters)
                 --else-----------------------> IceBolt | DeathCoil (50/50)
```

So **FrostMines and IceBreath are pre-enrage only** (health >= 4500) and
**SummonHelp and GroundPainex are post-enrage only**.

```
ATTACK   RS_WhiteRevenant2.See
file     zscript/monsters/revenant/RS_Revenant.zs:2755
shape    SINGLE
payload  RS_EvilShadeWhiteRev2 x1 per beat   (RS_RevenantFX.zs:1993)
arc      --   (placed random(-1,2) x random(-6,6) at z 3, velocity
                random(3,11) forward, random(0,2) up, angle
                randompick(45,90,225,270,180,0))
timing   3,3,[0],3,3,[0]   (one shade every 6 tics, forever, while walking)
damage   DamageFunction (random(2,7))
type     Melee
sound    --   (no SeeSound, no DeathSound on the class)
impact   RS_RevenantFX.zs:1985-1989 -- Death spawns RS_ArchRingHelp
         (zscript/monsters/lostsoul/RS_LostSoulFX.zs:1810), an invisible
         +NOCLIP Monster that A_VileChase-RESURRECTS corpses and
         A_RadiusGive("RS_GrowRaisin",60,RGF_MONSTERS|RGF_CORPSES,1) as it
         walks. Every shade the Lich sheds becomes a roaming raise-and-
         promote aura.
trigger  Walk
range    --
mirrored no
inherit  RS_EvilShadeWhiteRev (RS_RevenantFX.zs:1967). The `2` subclass
         changes ONLY the scale -- Scale = (1.0, 0.15) in PostBeginPlay
         (:1996), CH's non-uniform yscale. Damage, type, flags and the
         whole Death chain come from the parent.
profile  MakeBurst(proj:"RS_EvilShadeWhiteRev2", count:1, delayTics:6,
                   trigger:RS_FIRE_WALK)
notes    Trivial contact damage; rowed because it is a WALK-trigger attack
         that no name filter finds and because the resurrection chain
         behind it is what makes the Lich fight not end.
         The unsquashed RS_EvilShadeWhiteRev is spawned once per Missile
         and Missile2 cast (:2764, :2793) and three more times inside
         SummonHelp (:2823, :2828, :2833).
         CH OFF-BY-ONE KEPT (:1986-1988): the Death spawn passes only 8
         arguments, so SXF_NOCHECKPOSITION lands in A_SpawnItemEx's ANGLE
         slot. CH's own bug, verbatim.
```

```
ATTACK   RS_WhiteRevenant2.DeathCoil
file     zscript/monsters/revenant/RS_Revenant.zs:2775
shape    MULTI
payload  RS_WhiteRevCoil x1 + RS_WhiteRevCoil2 x1 + RS_WhiteRevCoil3 x1
         (+ RS_WhiteRevCoil4 x1 below 4500 HP, via MoreCoil :2782)
         (RS_RevenantFX.zs:1573, :1612, :1613, :1614)
arc      random(-11,1) / random(-1,1) / random(-1,11), each from a
         random(-7,7) lateral offset, pitch random(-2,2) on coils 1 and 3
timing   6,6,6,6,4,4,4,[4],3,3   (~46 tics; 4 tics between coils)
damage   DamageFunction (random(40,90)) -- all four, inherited
type     Melee
sound    "Lich/Cast" (from Missile, :2765); each coil plays SeeSound
         "baron/attack"
impact   RS_RevenantFX.zs:1606 -- BAL1 CDE 2 Bright A_Explode(random(5,25),128)
         on each of three frames, plus 8 blue particles.
         DeathSound "weapons/rocklx".
trigger  Missile   (CloseChoice :2843 one fifth; CloseChoice2 :2840 one
                    quarter; and the far-range 50/50 at :2768 / :2797)
range    --
mirrored no
inherit  Coil2/3/4 inherit EVERYTHING from RS_WhiteRevCoil and override
         ONLY `Speed` -- 12, 18, 30 against the parent's 24. Damage, the
         +THRUACTORS flag, the in-flight explode chain, the seek calls and
         the impact are all the parent's and are written nowhere near the
         subclasses (they are one-line classes).
profile  MakeBurst(proj:"RS_WhiteRevCoil", count:3, delayTics:4, arc:22,
                   pitchJitter:4, fireSnd:"baron/attack")
notes    **MULTI because the four classes exist ONLY to arrive at
         different times.** Speeds 24 / 12 / 18 (+30) fired 4 tics apart
         means they spread out into a rolling wall rather than a volley.
         MakeBurst with one class cannot reproduce that -- flagged.
         **THE COIL PASSES THROUGH YOU AND KEEPS BURNING.** +THRUACTORS
         (:1583) means it never impacts an actor at all; it flies until it
         hits a wall. And its flight state does
         `AYPE Y 2 Bright A_Explode(random(18,28),64)` (:1594 and :1600) --
         18..28 damage in a 64-unit radius EVERY 2 TICS, for the whole
         flight. Standing anywhere near its path is the damage; there is
         no "dodge the projectile".
         SEEKING: A_SeekerMissile(4,5) in Fly (:1596), A_SeekerMissile(1,1)
         in Fly2 (:1602), and it flips between the two on A_Jump(32) /
         A_Jump(64). Barely steers -- it does not need to.
         Trails RS_TrailAbyPE1.
         MoreCoil (:2781) is a health-band extension, not a second attack:
         below 4500 HP a fourth coil at Speed 30 and angle random(-1,1)
         joins. Folded into this row per the spec's band rule.
```

```
ATTACK   RS_WhiteRevenant2.IceBolt
file     zscript/monsters/revenant/RS_Revenant.zs:2788
shape    SINGLE
payload  RS_WhiteRevFrostBolt x1   (RS_RevenantFX.zs:1616)
arc      0
timing   4,4,4,4,6,3,3   (28 tics)
damage   DamageFunction (random(30,90))
type     Ice
sound    "Lich/Cast" (from Missile, :2765); the bolt plays SeeSound
         "weapons/rocklf"
impact   see the dedicated row RS_WhiteRevFrostBolt.Death below.
         DeathSound "Bomb/boom".
trigger  Missile   (CloseChoice, CloseChoice2, and both far-range 50/50s;
                    also FrostMinesStop -> A_Jump(32,"IceBolt") at :2869)
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_WhiteRevFrostBolt", fireSnd:"weapons/rocklf",
                   bigMuzzle:true)
notes    Speed 35, +BRIGHT, NOT seeking -- a straight fast bolt, the
         Lich's only clean single-target shot.
         **IT LAYS A CORRIDOR OF EXPLODING MIST.** Its flight loop
         (:1639-1650) spawns 4x RS_FrostMistWhiteRev per frame across 6
         frames = **24 mist clouds per loop**, plus an RS_FrostWingBaron
         each frame. RS_FrostMistWhiteRev (:1766) is
         DamageFunction (random(5,12)), Ice, +THRUACTORS, and does
         A_Explode(random(3,13),20) on 4 spawn frames AND 4 death frames --
         eight explosions each.
         RS_CyanCybieGunFlare at :2787 (RS_RevenantFX.zs:2064) is the
         muzzle flare -- +NOINTERACTION, +THRUACTORS, no Damage.
         RS_FrostWingBaron is expected from the barons lane and HAS landed
         (zscript/monsters/baron/RS_BaronFX.zs:667); no Damage, cosmetic.
```

```
ATTACK   RS_WhiteRevFrostBolt.Death   [SECONDARY -- payload impact of IceBolt]
file     zscript/monsters/revenant/RS_RevenantFX.zs:1656
shape    RING
payload  RS_FrostMistWhiteRev x26   (RS_RevenantFX.zs:1766)
arc      360   (13 at random(0,180), 13 at random(180,359); velocity
                random(10,20) forward, random(-15,15) up)
timing   0,0,3,3,3,3,[0 x26],[0],2,2,2,2   (~24 tics)
damage   blast A_Explode(random(20,120),128,0) at :1658;
         each mist DamageFunction (random(5,12)) plus eight
         A_Explode(random(3,13),20)
type     Ice
sound    A_Scream on detonation; each mist SeeSound "ice/Breath",
         DeathSound "Ice/Splode"
impact   A_SetScale(1.33,1.0), PUFI ABCD 3, the 26 clouds, the 128-radius
         blast, PUFI EFGH 2
trigger  Missile   (fires when the bolt dies)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_FrostMistWhiteRev", count:26, arc:360)
         + MakeRadial(radius:128, damage:70)
notes    20..120 in a 128 radius is the largest single blast any payload in
         this family delivers, and it is followed by 26 clouds each capable
         of another 24..104 over eight pulses. The bolt's own 30..90 is
         the smallest part of it.
```

```
ATTACK   RS_WhiteRevenant2.IceBreath
file     zscript/monsters/revenant/RS_Revenant.zs:2802
shape    SINGLE
payload  RS_IceToMeetWhiteRev x1   (RS_RevenantFX.zs:1694)
arc      0
timing   4,4,4,4,[0],6,[0],3,3   (28 tics)
damage   **the carrier has NO Damage** (Projectile, no Damage property).
         All damage is the trail: RS_IceToMeetWhiteRev2
         DamageFunction (random(1,2)) plus A_Explode(random(1,8),32,0)
type     Ice   (on the trail; the carrier declares none)
sound    "Lich/Cast" (from Missile). **The carrier has no SeeSound**
         (declared as `""`, RS_RevenantFX.zs:1750 is the trail's).
impact   RS_RevenantFX.zs:1727-1732 -- Bounce.Wall does A_Stop and goes to
         Death, which is an empty `TNT1 A 0; Stop;`. Nothing on arrival.
trigger  Missile   (via CloseChoice, :2843 -- one fifth, PRE-ENRAGE ONLY)
range    ..1500
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_IceToMeetWhiteRev", fireSnd:"Lich/Cast",
                   bigMuzzle:false)
         ; p.MaxRange = 1500
notes    **THE ATTACK IS INVISIBLE AND SILENT.** The carrier's every state
         is the `TNT1` null sprite (:1719-1723) and it declares no
         SeeSound. What you see is the line of ice patches it drops.
         MECHANIC: Gravity 5.0, -NOGRAVITY, +USEBOUNCESTATE, BounceType
         "Doom", BounceCount 99, BounceFactor 1.0, WallBounceFactor 1.0.
         Bounce.Floor (:1724) does ThrustThing(angle,12,0,0) -- it SKIPS
         along the ground like a stone, up to 99 times, dropping
         RS_IceToMeetWhiteRev2 every 3 tics (:1722).
         RS_IceToMeetWhiteRev2 (:1736) is the patch: +FLOORHUGGER, +RIPPER,
         +DONTHARMCLASS, +DONTHARMSPECIES, and its Fly state is
         `1C3F EFGHIJKLLLLLLLLLLLLIHGFE 5 Bright A_Explode(random(1,8),32,0)`
         -- **24 frames at 5 tics each = 120 tics of a 32-radius pulse,
         once per frame.** DeathSound "Ice/Hit2".
         The Lich walls off a corridor with this.
```

```
ATTACK   RS_WhiteRevenant2.BiggerBreath
file     zscript/monsters/revenant/RS_Revenant.zs:2807
shape    FAN
payload  RS_IceToMeetWhiteRev x3   (RS_RevenantFX.zs:1694)
arc      10   (+5, -5, 0)
timing   [0,0],6,3,3   (12 tics; all three effectively on one tic)
damage   as IceBreath -- carrier none, trail random(1,2) + the pulse
type     Ice (trail)
sound    "Lich/Cast" from the caller; carriers silent
impact   nothing on arrival; the ice patches are the attack
trigger  Missile   (via A_JumpIfHealthLower(6200,"BiggerBreath") from
                    IceBreath, checked TWICE -- :2801 before the single
                    bolt and :2803 after it)
range    ..1500   and health < 6200
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_IceToMeetWhiteRev", count:3, arc:10)
         ; p.MaxRange = 1500
notes    Rowed separately from IceBreath because the SHAPE changes, not
         just a number: one skipping carrier becomes a three-lane fan.
         **THE HEALTH CHECK IS DUPLICATED AND THAT MATTERS.** :2801 fires
         before the single carrier and :2803 after it, so below 6200 HP
         the Lich can emit 1 + 3 = FOUR carriers from one IceBreath cast.
         CH does the same (Revenants.txt:4870-4872). Kept.
```

```
ATTACK   RS_WhiteRevenant2.FrostMines
file     zscript/monsters/revenant/RS_Revenant.zs:2859
shape    RAIN
payload  RS_IceGroundWhiteRev x4 per loop   (RS_RevenantFX.zs:1664)
arc      --   (placed at random(24,1028) x random(-128,128) and
                random(128,1028) x random(-528,528), z 12 -- laid ahead
                of the Lich, not aimed)
timing   intro 5,[0 x20],3,3,[0 x20],5,5,5
         loop  5,2,2,2,2,2,0,0,0   (repeats while target within 1500)
damage   DamageFunction (random(33,66)) on contact
type     Ice
sound    --   (no SeeSound; DeathSound "Ice/Splode")
impact   RS_RevenantFX.zs:1684-1690 -- PUFI ABCD 3 Bright, then
         **18x RS_SpikeCyanRev** in three groups of six, each at
         random(-6,6) x random(-6,6) x random(12,64) with velocity
         random(1,13) forward and random(1,13) up, then PUFI EFGH 2.
trigger  Missile   (via CloseChoice, :2843 -- one fifth, PRE-ENRAGE ONLY)
range    ..1500   (A_JumpIfCloser(1500,"FrostMines2") at :2864 sustains it)
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_IceGroundWhiteRev", count:4, delayTics:2,
                   arc:360)
         ; p.MaxRange = 1500
notes    RAIN is the closest closed-vocabulary fit and it is not exact:
         these are LAID ON THE FLOOR, not dropped from above. Recorded
         rather than coining a word.
         The mines arm over 30 tics (`1C3F DCB 10 Bright`, :1679) then sit
         in a Fly loop rolling A_Jump(12,"Death") (~4.7% per 30 tics) --
         so they self-trigger eventually even if you never touch them.
         +FLOORHUGGER, Radius 9.
         THE INTRO IS COSMETIC: 20 RS_FrostWingBaron2 at :2850-2851 and
         :2854-2855 (zscript/monsters/baron/RS_BaronFX.zs:697) -- Speed 1,
         +NOCLIP, no Damage. The mines are FrostMines2 (:2857).
         **THE LOOP IS OPEN-ENDED.** :2862-2864 -- it keeps laying 4 mines
         every 15 tics until it loses sight (A_CheckSight), rolls the
         ~9% A_Jump(24,"FrostMinesStop"), or you break 1500. There is no
         count cap. MakeBurst count:4 covers one pass only; flagged.
         It sets bNOPAIN = false on entry (:2852) -- it is interruptible
         while laying, which is the counterplay.
```

```
ATTACK   RS_WhiteRevenant2.GroundPain
file     zscript/monsters/revenant/RS_Revenant.zs:2920
shape    VILE
payload  RS_DarkChannelWhiteRev x1   (RS_RevenantFX.zs:1809)
arc      --   (A_VileTarget spawns it AT the target's position)
timing   5,3,3,[8 x3],[5 x3], then GroundPain2 loops [5 x3] indefinitely
damage   A_Explode(random(10,80),256,0) x7 per Fly pass;
         escalating to A_Explode(random(10,80),512,0) x6 per Fly3 pass
type     Plasma
sound    "Forgotten/Attack" on the mark (:1831); "Litn/litn3" on every
         Fly/Fly3 pass (:1854, :1870); DeathSound "Litn/litn3"
impact   The channel is stationary (Speed 0, +FLOORHUGGER, +FLATSPRITE,
         +THRUACTORS, +DONTHARMCLASS). It also sheds RS_CybieZappy
         (RS_RevenantFX.zs:2089) ten times per Fly pass -- Gravity 0.4
         bouncing sparks whose Death does A_Explode(random(5,20),32) x3
         plus 5x RS_ZapZapCB, and whose trail RS_TrailCB (:2121) does
         A_Explode(random(5,20),64) on two frames.
trigger  Missile   (via CloseChoice, :2843 -- one fifth, PRE-ENRAGE ONLY)
range    ..1500   (A_JumpIfCloser(1500,"GroundPain2") at :2927 sustains it)
mirrored no
inherit  --
profile  MakeRadial(radius:256, damage:45, fireSnd:"Forgotten/Attack")
         ; p.MaxRange = 1500
         -- no VILE/channel mode exists; see UNRESOLVED #5
notes    **THE BIGGEST SUSTAINED AoE IN THE FAMILY, BY AN ORDER.**
         Radius 256 rising to 512, seven to eleven pulses of 10..80 per
         pass, repeating for as long as the Lich channels.
         40-TIC TELEGRAPH: the Mark state (:1830-1850) plays
         "Forgotten/Attack", spawns four orbiting
         RS_CastTargetingWhiteRev1-4 markers three times over 20 tics
         (:1832-1845), then grows D4RC A->E scale 0.1 -> 1.0 across 40
         tics before a single point of damage lands. That telegraph IS the
         counterplay and must survive any port of this profile.
         ESCALATION: A_Jump(102,"Fly2") at :1860 (~40%) doubles the scale
         to 2.0 and switches Fly3 to radius 512 (:1871, :1873) permanently.
         KILL SWITCH: GroundStop (:2929) does
         A_RadiusGive("RS_ByeWhiteRevCast",9999,RGF_MISSILES|RGF_NOSIGHT,1)
         and the channel checks A_JumpIfInventory("RS_ByeWhiteRevCast",1,
         "Death") at :1853 and :1869. The Lich's own Warp (:2949) and
         Death (:2963) fire the same switch. Nothing the PLAYER does stops
         it -- only the Lich moving on.
         bNOPAIN = false on entry (:2919), true on exit (:2931) -- it is
         interruptible only while channelling.
```

```
ATTACK   RS_WhiteRevenant2.GroundPainex
file     zscript/monsters/revenant/RS_Revenant.zs:2895
shape    MULTI
payload  RS_DarkChannelWhiteRev x1 + RS_IceGroundWhiteRev x4 per loop
         (RS_RevenantFX.zs:1809 / :1664)
arc      channel at the target; mines at random(24,1028) x random(-128,128)
         and random(128,1028) x random(-528,528)
timing   5,3,3,[7 x3],[3 x3], then GroundPainex2 loops 5,2,2,2,2,2
damage   channel as GroundPain (10..80 at r256, escalating to r512);
         mines DamageFunction (random(33,66)) each
type     Plasma (channel) / Ice (mines)
sound    "Forgotten/Attack", "Litn/litn3"; mines DeathSound "Ice/Splode"
impact   channel as GroundPain; mines burst into 18x RS_SpikeCyanRev each
trigger  Missile   (via CloseChoice2, :2840 -- one quarter,
                    POST-ENRAGE ONLY, health < 4500)
range    ..1500
mirrored no
inherit  --
profile  MakeRadial(radius:256, damage:45, fireSnd:"Forgotten/Attack")
         + MakeBurst(proj:"RS_IceGroundWhiteRev", count:4, delayTics:2,
                     arc:360)
         ; p.MaxRange = 1500
notes    **THE ENRAGED FUSION OF GroundPain AND FrostMines**, and this is
         the only place the two combine. GroundPainex2 (:2898) is
         byte-for-byte GroundPain2's structure with FrostMines2's two mine
         spawns (:2900, :2902) inserted into it. Rowed separately because
         the payload set genuinely differs, not just a number.
         Same 40-tic channel telegraph, same escalation, same
         RS_ByeWhiteRevCast kill switch via GroundStopex (:2907).
```

```
ATTACK   RS_WhiteRevenant2.SummonHelp
file     zscript/monsters/revenant/RS_Revenant.zs:2826
shape    UNCLASSIFIED
payload  RS_MrBones x3 (zscript/monsters/zombieman/RS_Zombieman.zs:2256)
         + RS_PortalSummons x3 (zscript/monsters/cacodemon/RS_CacodemonFX.zs:316)
arc      --   (placed at randompick(-64,64,32,-32) x
                randompick(-128,64,-64,128), z 32, SXF_SETMASTER)
timing   1,[0,0],5,3,3,[8 x3],5,3,[8 x9],[8 x9],3,[2 x4],[2 x3],12
         (~150 tics -- the longest single beat in the family)
damage   --   (the summons do the damage)
type     --
sound    "Lich/Cast" from Missile2 (:2794)
impact   RS_PortalSummons is a RandomSpawner -- a hell portal whose roster
         is CH's own; each rolls a monster.
trigger  Missile   (via CloseChoice2, :2840 -- one quarter,
                    POST-ENRAGE ONLY, health < 4500)
range    ..1500
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_MrBones", count:3, cap:6, tierOffset:-2,
                    fireSnd:"Lich/Cast")
         + MakeSummon(summonCls:"RS_PortalSummons", count:3, cap:6,
                      tierOffset:-2)
notes    THREE SEPARATE +5 DEFENSIVE STACKS ARE APPLIED DURING THE CAST:
         A_GiveInventory("RS_WhiteRevProtect",1) at :2822, :2827 and :2832,
         each paired with an RS_EvilShadeWhiteRev.
         **RS_WhiteRevProtect IS A PERMANENT, STACKING DAMAGE REDUCTION.**
         RS_RevenantFX.zs:1800 -- `: PowerProtection`, DamageFactor 0.33,
         `Powerup.Duration -1`. It is also handed out once per Missile
         (:2763) and once per Missile2 (:2792). Nothing ever removes it.
         The Lich gets harder to kill every time it attacks. That is either
         CH's intent or CH's bug; it is CH's either way
         (Revenants.txt:4971-4975) and is kept verbatim.
         RS_RedRevLoad at :2814-2815 is the cosmetic charge flare.
         bNOPAIN goes false at :2817 and true at :2834 -- the middle of the
         summon is the interruptible window.
```

```
ATTACK   RS_WhiteRevenant2.Death
file     zscript/monsters/revenant/RS_Revenant.zs:2964
shape    BURST
payload  RS_HKRedDeath x16   (zscript/monsters/zombieman/RS_ZombiemanFX.zs:844)
arc      random(-30,30), spawn height random(20,100), CMF_AIMOFFSET,
         flags-pitch 2 / -10
timing   [2 x6],3,[1 x10],3,3,[3 x4]   (~40 tics)
damage   A_Explode(random(5,10),42) each, plus A_Burst("RS_RedThingsHK")
type     Fire
sound    A_Scream (:2965); DeathSound "LICHDEAD"; each blast plays
         "world/barrelx" twice
impact   Spawn goes straight to Death -- each detonates where it lands
trigger  Death   (the state is `XDeath:` falling through to `Death:`,
                  :2961-2962, so gibbing produces the identical burst)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_HKRedDeath", count:16, delayTics:1, arc:60,
                   fireSnd:"world/barrelx", trigger:RS_FIRE_DEATH)
notes    Six blasts 2 tics apart, then ten 1 tic apart -- accelerating.
         MakeBurst is uniform; delayTics:1 keeps the total near CH's.
         A_RadiusGive("RS_ByeWhiteRevCast",9999,...) at :2963 fires FIRST,
         shutting down any live GroundPain channel. Killing the Lich does
         stop the floor.
```

---

# UNRESOLVED

An honest gap is worth more than a confident guess.

### 1. CH IS NOT AT THE PATH THE SPEC AND CLAUDE.md NAME

`C:\Users\Command\Desktop\CH` **does not exist on this machine.** Checked
directly. `C:\Users\Command\Desktop` exists and does not contain a `CH`
folder.

I used **`E:\New folder\ART SOURCE\CH\`** instead, which does exist, and
whose `decorate\Revenants.txt` is 5,154 lines -- matching exactly the
line count and the per-actor line citations that `RS_Revenant.zs`'s own
header records for the pack it was built from. CLAUDE.md's "IMPORTING A
MONSTER" section names this same path as the source of truth for CH's
sounds, sprites, SNDINFO, TRNSLATE and DECORATE.

I am confident it is the same pack. I did not verify that it is the same
*revision*. **The owner should say which path is canonical**, because two
sections of CLAUDE.md now name different ones and the "ground truth"
section names the one that is gone.

### 2. THE ENGINE SOURCE IS NOT AT `E:\DXR2`

CLAUDE.md says "the engine source is the authority ... and it is on this
machine. `E:\DXR2`". **That path does not exist.** Checked directly.

Four rows need engine behaviour that is written nowhere in this repo:
`A_SkelFist`'s damage roll, `A_CustomBulletAttack`'s damage multiplier,
`A_VileTarget`'s sight behaviour, and the whole of `RevenantTracer`.

I read those from the engine **the game actually runs**:
`D:\SteamLibrary\steamapps\Common\DooM VR\___Sourceport\qzdoom-16-RC1-Windows-64bit\qzdoom.pk3`,
entries `zscript/actors/doom/revenant.zs`, `zscript/actors/doom/archvile.zs`,
`zscript/actors/attacks.zs`, `zscript/actors/actor.zs`. That is "the running
game", which CLAUDE.md does allow. It is not the C++ source.

**Flagging it rather than quietly substituting a source.** If the owner
wants engine claims cited against `E:\DXR2`, that tree needs restoring.

### 3. THE FIVE `A_SkullAttack` CHARGES HAVE NO RECORDABLE DAMAGE

`RS_GrayRevenant2.Closer`, `RS_BlueRevenant.Falcon`,
`RS_PurpleRevenant.Falcon2`, `RS_BlackRevenant3.Dash`,
`RS_BlackRevenantEX.Dash`.

`A_SkullAttack` sets `bSkullfly` and launches the monster; the contact
hit is resolved by the engine's `PIT_CheckThing`, which is **C++
(`src/p_map.cpp`), not ZScript** -- it is not in `qzdoom.pk3` and the
source tree is missing (see #2).

What I can state: **none of these five monsters declares a `Damage`
property.** Verified in every Default block. Every other CH family's
charger I could reach declares one or does not; I did not survey them.

So `damage --` on those rows means "nothing is written and I could not
verify what the engine does with nothing", not "zero". All five fall
into a `Melee` state immediately afterwards, and that melee IS written,
so the rows are usable either way. **Do not turn `--` into `0` without
checking `p_map.cpp`.**

### 4. `RS_BlackRevHook` HAS NO GRAPPLE AND ITS PARENT DOES NOT EXIST

CH declares `ACTOR BlackRevHook : Loreshot` (Revenants.txt:3907). The
token `Loreshot` occurs **exactly once in the whole CH tree** -- on that
inheritance line. CH never defines it, so CH's own BlackRevHook fails to
load.
Our copy (`RS_RevenantFX.zs:1182`) rebuilds the body on plain `Actor` with
nothing substituted, and the FX header records it.

Consequence for this catalog: **the class named "Hook" contains no hook.**
No `A_Warp`, no thrust, no tether, nothing that pulls. Whatever grapple
behaviour the name implies lived in the absent parent and is unrecoverable
from CH.

I rowed it as what it demonstrably is -- a fast melee-type projectile that
lays a trail of live `RS_FatsoSpikes2`. **If a player-weapon profile is
built from this row it will not grapple, and that is correct, not a
transcription loss.**

### 5. FIVE SHAPES HAVE NO FACTORY IN `RS_AttackProfile`

Read `zscript/systems/weapon/RS_AttackProfile.zs` in full. Available:
`MakeBullet`, `MakeHitscan`, `MakeHeavy`, `MakeMelee`, `MakeVolley`,
`MakeBurst`, `MakeSummon`, `MakeRadial`, `MakeSelfBuff`. Modes:
`RS_ATK_BULLET/HEAVY/MELEE/HITSCAN/SUMMON/RADIAL/SELFBUFF`.

The `profile` lines below are **approximations and are marked as such in
their rows**:

* **CHARGE** -- no ram mode. Five rows use `MakeSelfBuff` as a stand-in.
* **VILE** -- no "spawn a burning thing at the target" mode. Three rows
  (`HellFlame`, `GroundPain`, `GroundPainex`) use `MakeRadial`.
* **RAILGUN** -- `A_CustomRailgun` has no mode; `RS_PurpleRevenant.Fireing1`
  uses `MakeHitscan`, which loses the 10000-unit range and the beam.
* **A NON-UNIFORM BURST** -- `MakeBurst.BurstDelayTics` is one integer.
  Seven rows have accelerating or decelerating cadences
  (`RS_GrayRevenant2.BoneIt` 8/6/4, `RS_WhiteRevenant2.Death` 2/2/2/2/2/2
  then 1x10, `RS_CyanRevenant2.Missile` 0/4/12, and others). Each row
  records the true tic list and the substitution.
* **A SHOT-COUNT BUDGET / COOLDOWN** -- `RS_BlueRevenant`,
  `RS_PurpleRevenant` and `RS_RedRevenant` all gate an attack on a
  per-monster counter (`user_nodash1`, `user_nodash2`, `user_ttt`) that
  spends and refunds across attacks. There is no field for it. This is the
  single most transferable mechanic in the family and it currently cannot
  be expressed.

Also missing: an **open-ended loop** field. `RS_BlackRev2.Seekers`,
`RS_BlackRevEx2.Seekers`, `RS_WhiteRevenant2.FrostMines` and
`GroundPain` all repeat until a condition breaks, with no count. Every
such row states the per-pass count and says it is a floor.

### 6. `RS_YellowRevenant.SpitIt` IS UNREACHABLE AS SHIPPED

Rowed anyway, because it is real code that CH reaches and a cvar could
reach here. The gate: `A_JumpIf(speed >= 20,"SpitIt")` (:1676) can only
pass after `Script1` runs `A_SetSpeed(24)` (:1640), and `Script1` needs
`RS_Zom.CV('rs_ch_yellowrev', 0)` to return 1, or 2 for a coin flip.

**`rs_ch_yellowrev` is not in this repo's `CVARINFO.txt`.** I did not add
it -- this is a documentation pass. `CV()` therefore returns CH's own
default of 0 and `Spawn` always lands on `Script3`, which leaves Speed 7.

Same condition means the `Translation "YellowRev01"` at :1642 never
applies either -- which is fortunate, since the FX header records that
translation as absent from this repo's `TRNSLATE.txt` (it is CH
`TRNSLATE.txt:10`).

**Owner decision, not mine.** Flagged.

### 7. FIVE `Pain.AbyssPE` STATES ARE MORPHS, NOT ATTACKS -- NOT ROWED

`RS_CommonRevenant` (:939), `RS_GreenRevenant` (:1073),
`RS_BlueRevenant` (:1239), `RS_PurpleRevenant` (:1422),
`RS_YellowRevenant` (:1719), `RS_RedRevenant` (:1880),
`RS_FireBluRevenant2` (:710), `RS_GrayRevenant2` (:834).

Each spawns 94x **`RS_SplashAbyss`** -- the *harmless* parent, not
`RS_SplashAbyss2` -- then `RS_AbyssRevenant2` and `A_Die`. It is a
transformation into the tier-9 monster, triggered by an external damage
type, and it deals nothing. Recorded here so a later pass does not
"discover" eight missing attacks.

### 8. RECORDED BUT DELIBERATELY NOT ROWED

Real mechanics with no damage and no summon, listed so they are not lost:

* **`RS_CyanRevenant2.Jumpy`** (:409) -- a bounding evade off
  `A_JumpIfInTargetLOS(...,750)` via `SeeMe` (:406), gated by
  `rs_ch_cyanbounce`. Pure mobility.
* **`RS_CyanRevenant2.Bon`** (:455) -- a 25% backflip after Missile and a
  50% one after Pain.
* **`RS_BlueRevenant.Jumper`** (:1201) / **`RS_PurpleRevenant.Jumper2`**
  (:1370) -- post-Pain fast-chase loops.
* **`RS_WhiteRevenant2.Enrage`** (:2871) -- the phase change. Sets FLOAT,
  NOGRAVITY, `user_enrage = 1`, speed 99 wander, back to 23; plays
  "deepone/death" at `ATTN_NONE` (map-wide). Would be
  `MakeSelfBuff(speedMult:4.3, duration:24, noPain:false)`.
* **`RS_WhiteRevenant2.Warp`** (:2943) and **`RS_BlackRevEx2.Warp`**
  (:2650) -- post-Pain blink-outs at speed 99.
* **`RS_AbyssRevenant2.Pain.Ice`** (:587), the two Black Knights'
  `Pain.Ice`/`Pain.Melee`/`Pain.Fire` -- resist beats playing "ResistCH".
* **`RS_RedRevenant.Pain`** (:1897) -- permanently sets `bNOPAIN` and
  `bMISSILEEVENMORE`. One-way, no reset anywhere.
* **`RS_BlackRevenant3/EX.ShieldSee`** (:2029 / :2333) -- defensive shield
  spawns with no attack attached.
* **`RS_WhiteRevenant2.PainDup`** (:2934) -- **dead code in CH too.** CH
  declares `Pain:` twice in one States block (Revenants.txt:4703 and
  :4725) with byte-identical bodies; the first binds. ZScript rejects a
  duplicate label, so ours is renamed and is equally unreachable.
* **`RS_RevSpeedBuff`** (`RS_RevenantFX.zs:98`) -- **completely inert.**
  Its Pickup/Use are two empty `TNT1 A 0;` lines because CH's
  `ACS_NamedExecuteAlways("BrownRevSPEED")` was stripped. Handed out by
  `RS_BrownRevenant2` on every See beat (:279, :287) and on XDeath (:324).
  Whatever speed boost CH intended, this repo does not have it.
* **`RS_PowerRevEx`** / **`RS_PowerRevEx2`** (`RS_RevenantFX.zs:1530`,
  :1550) -- also ACS-stripped, but `RS_PowerRevEx` still does real work
  because `RS_BlackRevEx3` tests for it by inventory (:2504, :2508).
  `RS_PowerRevEx2` (given at :2646) is tested by **nothing** in this tree.
  Its CH job was `ACS_NamedExecuteAlways("RevBuffEx")`. Whatever that
  buffed, the shadow does not get it here.

### 9. ONE PAYLOAD I COULD NOT FULLY RESOLVE

**`RS_PortalSummons`** (`zscript/monsters/cacodemon/RS_CacodemonFX.zs:316`,
CH CYBIES.txt:3535) is a `RandomSpawner`. The `SummonHelp` row records that
the Lich spawns three of them, but **I did not open its roster**, so the row
cannot say what actually comes out. It is cacodemon-lane content and CH
defines it in a different file. If a summon profile is built from that row,
the roster needs reading first.

### 10. WHAT THIS CATALOG DOES NOT COVER

Deliberately out of scope, stated so nobody reads a silence as a clear:

* **Sounds were recorded as written, NOT resolved to lumps.** CLAUDE.md is
  explicit that an unresolved sound name is completely inert -- no error,
  no warning, just silence -- and that 87% of CH's sound library was once
  missing. Every `sound` and `impact` field here says what the code asks
  for. **None of it was traced through SNDINFO to a real lump.** The names
  most worth checking, because they are the ones this family leans on:
  `monster/incatk`, `monster/incdth`, `monster/incsit`, `monster/inchit`,
  `BASSFFAT`, `BK/Pass`, `BK/invi`, `BK/Phase2`, `BK/Die`, `BKFuKINV`,
  `monster/dknswg`, `monster/dkndrt`, `monster/dknmsl`, `monster/kntswg`,
  `LICHVOID`, `LICHDEAD`, `LICHLMAO`, `Lich/Cast`, `Forgotten/Attack`,
  `Litn/litn3`, `Spell/SpellCast1`, `spell/Impact1`, `Crack/see`,
  `Crack/death`, `Ice/Hit2`, `Ice/Splode`, `ice/Cast`, `ice/Breath`,
  `AbyssForm`, `ResistCH`, `COCONUTT`, `skelatt`, `swordhit`,
  `moloch/nailhit`, `moloch/nailhitbleed`, `deepone/death`.
  `monster/dkdie` is already recorded in the FX header as **proven missing
  in CH itself** -- both Black Knights die silent there too.
* **Sprites were not verified to exist.** Two are already recorded as
  proven-missing in CH (`DNKT` frame A, `SBSI` frame A) and two were fixed
  in-repo on 2026-08-06 (`DKNT`, `SBS1`/`MISL E`). `FATB` and `FBXP` are
  flagged in the `RS_CommonRevenant.Missile` row as Doom-1 hazards on
  CLAUDE.md's own authority. Nothing else was checked.
* **`A_MonsterRefire`'s exact probability semantics.** Three rows use it
  (`Fireing1` :1420, both `Seekers` :2215 / :2641). I recorded the call as
  written and said the state loops. I did not assert what `120` and `64`
  resolve to, because that is C++ (`p_enemy.cpp`) and see #2.
* **`+MISSILEMORE` / `+MISSILEEVENMORE` firing-rate effects.** Fifteen of
  the eighteen monsters carry one or both. CLAUDE.md records these as
  unfixable deprecated flags that set native fields with no `Property`
  binding, and that their behaviour is already correct. They change how
  OFTEN every row above fires and are not quantified here.
```
