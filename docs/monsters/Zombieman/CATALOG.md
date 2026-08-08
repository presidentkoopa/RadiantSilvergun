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

# Zombieman (family 01) — ATTACK CATALOG

Written to the format in `docs/rs_21_port_law.txt` section 4. PHASE 1 —
documentation only; no `.zs` was written or edited producing this.

**Ground truth**, and the only thing checked:

* `E:\New folder\ART SOURCE\CHP\DECORATE\01\01_*.txt` (14 tier files + one empty)
* `E:\New folder\ART SOURCE\CHP\source\*.acs`
* `E:\New folder\ART SOURCE\CH\decorate\Zombies.txt` (fallback for inherited state)
* `E:\New folder\ART SOURCE\CH\decorate\Imps.txt`, `Archviles.txt` (shared effect actors)

Every `chp source` line is a real file and a real line range, checked with the
file open. Paths are written relative to `E:\New folder\ART SOURCE\`.

---

## READ THIS BEFORE USING THE `axes` LINES

`axes` values are restricted to the vocabulary that **already exists in this
project**, read off `GetBaseKeywords()` across `zscript/weapons/` and
`zscript/monsters/`:

```
archetype: bfg chaingun energy flamethrower launcher melee pistol railgun
           revolver rifle shotgun smg supershotgun
delivery : bullet heavy melee radial
element  : explosive kinetic melt thermal plasma void
payload  : multi single
trigger  : burst fullauto semi semiauto
role     : artillery boss bruiser fodder skirmisher summoner
mobility : ground flying floating
species  : (one per monster family)
trait    : ex homing resurrector secondstage stealth summoned
behavior : homing          (affix-granted, RS_FX_BallisticFired.zs:26)
feed / reserve / set / promotion : weapon-side only
```

**Three axis values that Zombieman needs do not exist and were NOT invented.**
Each is called out in the affected entry's `notes`:

| missing value | wanted by | entries |
|---|---|---|
| `element:ice` | ice/cold damage | Ice Shard, Twin Abyss Bolts, Abyss Splash Burst |
| `element:poison` | `DamageType Poison` | Poison Gas Cloud |
| `element:bone` (or similar) | the Undertaker's untyped bone rounds | Bone Shotgun, Rapid Bone Stream, Bone Tornado |

`rs_21`'s own worked example at `docs/rs_21_port_law.txt:143-144` uses
`element:ice` and `archetype:hitscan`. **Neither exists in the live vocabulary.**
The example is illustrative, not a licence — extending the vocabulary is an
rs_17 job, per rs_21:165-166.

Note also that no `archetype:` value is appropriate for a monster attack: every
live `archetype:` value names a *player weapon class*. Monster entries below
leave that axis off rather than borrow it.

---

## 1. Aimed Rifle Shot
`zscript/monsters/Zombieman/attacks/RS_Zombieman_RifleShot.zs`

```
kind         : single aimed rifle shot
axes         : delivery:bullet payload:single element:kinetic trigger:semi
               role:fodder mobility:ground species:zombieman
tier(s)      : T00 Common (CommonCommonZombie), T01 Green (CommonGreenZombie)
chp source   : CHP/DECORATE/01/01_C.txt:23-27   (T00 Missile)
               CHP/DECORATE/01/01_G.txt:27-35   (T01 Missile — same call, twice)
acs          : none
fires        : hitscan. A_CustomBulletAttack(22.5, 0, 1, random(1,5)*3,
               "BulletPuff_C", 0, CBAF_NORANDOM)
               one bullet, 22.5 deg horizontal cone, no vertical spread.
damage       : random(1,5) * 3   -> 3/6/9/12/15, five flat steps.
               CBAF_NORANDOM is SET, so the engine's usual damage*random(1,3)
               multiplier does NOT apply. The roll is exactly as written.
sprites      : POSS E (aim) / POSS F (fire) / POSS E (recover)   [T00]
               ZOMG E / ZOMG F / ZOMG E                          [T01]
               puff: BulletPuff_C (CHP/DECORATE/01/01_C.txt:1173-1175 — an
               empty subclass of vanilla BulletPuff; no override at all)
sounds       : AttackSound "grunt/attack" (T00 01_C.txt:7, T01 01_G.txt:7)
behaviour    : The baseline. Ten tics of standing still with the rifle up,
               eight tics of muzzle flash, eight tics of recovery, then back
               to the chase. Wide cone, low damage, no lead — it is a coin
               flip at range and reliable in a corridor. Being hit by it is
               a chip, never a threat; being hit by nine of them is a threat.
               T01 runs the identical call TWICE per Missile pass with a gas
               puff between each (see entry 2), and exits into See2 rather
               than See, so a green zombie that has fired once never stops
               trailing gas.
profile      : RS_AttackProfile.MakeHitscan("grunt/attack", 22.5/45.0, 0, null,
                   "", false, "aimed rifle shot", "BulletPuff")
               // spreadScale is the cone half-angle normalised; damage roll
               // stays at the call site — MakeHitscan carries no damage field.
notes        : CH's parent GreenZombie uses plain A_PosAttack for this
               (CH/decorate/Zombies.txt:921); CHP replaces it with the explicit
               A_CustomBulletAttack above. CHP wins.
```

## 2. Poison Gas Cloud
`zscript/monsters/Zombieman/attacks/RS_Zombieman_GasCloud.zs`

```
kind         : lingering poison gas cloud
axes         : delivery:heavy payload:single role:fodder mobility:ground
               species:zombieman
tier(s)      : T01 Green (CommonGreenZombie)
chp source   : CHP/DECORATE/01/01_G.txt:25      (See2 — one puff per lap)
               CHP/DECORATE/01/01_G.txt:28,31,34 (Missile — three per pass)
               CHP/DECORATE/01/01_G.txt:37      (Pain — one on being hurt)
               CHP/DECORATE/01/01_G.txt:49      (Death — one at frame K)
               CHP/DECORATE/01/01_G.txt:62-64   (XDeath — three, fanned +-7 deg)
               projectile: CHP/DECORATE/01/01_G.txt:1410-1421 (Gas11_C)
               parent    : CH/decorate/Zombies.txt:989-1011   (Gas11)
acs          : none
fires        : A_Custommissile("Gas11_C", 32, 0)   — Speed 0. It does not
               travel. It is dropped where the zombie stands.
damage       : A_Explode(random(1,8), 32) — and the Death state is
               `PSBG FGHI 6 Bright A_Explode(random(1,8),32)`, FOUR frames, so
               A_Explode fires FOUR TIMES per cloud, 6 tics apart.
               Total per cloud: 4 x random(1,8) = 4..32 over 24 tics.
               DamageType Poison.
sprites      : PSBG CDE (3 tics each, Bright) -> PSBG FGHI (6 tics each, Bright)
sounds       : none — Gas11 declares no SeeSound or DeathSound.
behaviour    : A green zombie leaks poison. Not an aimed attack at all: it
               drops a stationary cloud at its own feet on every walk lap, on
               every shot, when it flinches, and twice more as it dies. The
               cloud does nothing for 9 tics, then ticks damage four times over
               24. Chasing a green zombie down a corridor means walking through
               everything it has already dropped. It is an area-denial trail,
               not a projectile — the correct read for PACK is "this monster
               poisons the ground it has walked on."
profile      : RS_AttackProfile.MakeVolley("RS_Gas11", 1, 0.0, "", 1.0, 0.0,
                   "poison gas cloud")
notes        : NO `element:poison` VALUE EXISTS in the live keyword vocabulary.
               DamageType is literally "Poison" (CH/decorate/Zombies.txt:996).
               Left off rather than mapped to element:melt, which means acid.
               The multi-frame A_Explode is DELIBERATE here — this is exactly
               the "gas/lightning/lingering fire" class the memory note
               `project_rs_multiframe_explode` says must NOT be collapsed to a
               single firing.
```

## 3. Three-Round Burst
`zscript/monsters/Zombieman/attacks/RS_Zombieman_Burst.zs`

```
kind         : three-round rifle burst
axes         : delivery:bullet payload:multi element:kinetic trigger:burst
               role:fodder mobility:ground species:zombieman
tier(s)      : T02 Blue (CommonBlueZombie)
chp source   : CHP/DECORATE/01/01_B.txt:24-28
acs          : none
fires        : A_Custombulletattack(7, 7, 3, random(1,3), "BulletPuff_C")
               three bullets on one tic, 7 deg horizontal AND 7 deg vertical.
damage       : random(1,3) per bullet, and CBAF_NORANDOM is NOT set, so the
               engine multiplies by random(1,3):  random(1,3) * random(1,3)
               = 1..9 per bullet, 3..27 for the burst.
sprites      : ZOMB E 10 (aim) / ZOMB F 7 (fire) / ZOMB E 8 (recover)
sounds       : AttackSound "grunt/attack" (01_B.txt:7)
behaviour    : Three rounds in a tight 7x7 cone at once — the first tier that
               can actually hurt at range. Faster than T00 (7 tics of fire
               instead of 8) and the cone is a third the width, so it will
               land two of three at mid distance. The blue zombie also
               alternates A_Chase with A_FastChase every walk lap
               (01_B.txt:20-23), so it closes while it does this.
profile      : RS_AttackProfile.MakeHitscan("grunt/attack", 7.0/45.0, 0, null,
                   "", false, "three-round rifle burst", "BulletPuff")
               // then p.VolleyCount = 3;
notes        : Damage LOOKS tiny (random(1,3)) and is not — the missing
               CBAF_NORANDOM is doing real work. Any port that copies the
               number without the flag halves the tier.
```

## 4. Ice Shard
`zscript/monsters/Zombieman/attacks/RS_Zombieman_IceShard.zs`

```
kind         : flat ice shard, fired like a dart
axes         : delivery:heavy payload:single role:skirmisher mobility:ground
               species:zombieman
tier(s)      : T03 Cyan (CommonCyanZombie)
chp source   : CHP/DECORATE/01/01_CY.txt:30-34   (Missile)
               projectile: CHP/DECORATE/01/01_CY.txt:934-957 (IceZombieShot_C)
acs          : none
fires        : A_Custommissile("IceZombieShot_C", 42, 1, random(-2,2))
               one shard, spawn height 42, x-offset 1, +-2 degrees of yaw.
damage       : Damage (random(6,16))   [01_CY.txt:939]   DamageType Ice
sprites      : CYNT E 6 (aim) / CYNT F 4 (fire) / CYNT E 4 (recover)
               shard: ICEY ABC 3 Bright (loop) -> ICEY FGHI 5 Bright (death)
sounds       : SeeSound "Ice/Hit2"  DeathSound "spike/spiked"  [01_CY.txt:946-947]
behaviour    : The fastest attack in the low tiers — six tics up, four to
               fire, four down, half the wind-up of everything below it, and
               the shard travels at Speed 33 as a FastProjectile. It is drawn
               almost flat (xScale 1.15, yScale 0.15) so it reads as a
               horizontal sliver, hard to see edge-on. The cyan zombie is
               Alpha 0.75 translucent with PainChance 40, so it barely
               flinches and keeps this rhythm under fire.
profile      : RS_AttackProfile.MakeVolley("RS_IceZombieShot", 1, 4.0,
                   "Ice/Hit2", 1.0, 0.0, "ice shard")
               // arc 4.0 covers CHP's random(-2,2)
notes        : NO `element:ice` VALUE EXISTS. DamageType is "Ice"
               (01_CY.txt:940). Not mapped onto element:kinetic — that would
               be a lie about what resists it.
               The cyan zombie's DEATH (01_CY.txt:39-57) wobbles the corpse
               through twelve A_SetScale frames and then A_Burst("IceChunk_C").
               A_Burst spawns debris only; IceChunk deals no damage. It is
               NOT an attack and has no entry here. Recorded so the next
               reader does not have to re-derive that.
```

## 5. Twin Hitscan Double-Tap
`zscript/monsters/Zombieman/attacks/RS_Zombieman_DoubleTap.zs`

```
kind         : close-range hitscan double-tap
axes         : delivery:bullet payload:multi element:kinetic trigger:burst
               role:skirmisher mobility:ground species:zombieman
tier(s)      : T04 Purple (CommonPurpleZombie)
chp source   : CHP/DECORATE/01/01_P.txt:27-32   (Hitscanne)
               gate  : CHP/DECORATE/01/01_P.txt:25 (A_JumpIfCloser 800)
acs          : none
fires        : beat 1  A_Custombulletattack(9, 9, 3, random(1,2), "BulletPuff_C")
               beat 2  A_Custombulletattack(7, 7, 2, random(1,2), "BulletPuff_C")
               five bullets total across two tics.
damage       : random(1,2) per bullet, CBAF_NORANDOM NOT set -> x random(1,3)
               = 1..6 per bullet. Beat 1: 3..18. Beat 2: 2..12.
sprites      : BPOS E 10 (aim) / BPOS F 7 (beat 1) / BPOS F 4 (beat 2) /
               BPOS E 8 (refire check)
sounds       : AttackSound "grunt/attack" (01_P.txt:8)
behaviour    : Only used inside 800 units. Two shrinking cones back to back —
               wide-and-three, then tight-and-two — so it walks its fire onto
               you. Ends on A_Monsterrefire(128, "See"), a 50% chance to keep
               the barrel on target and loop straight back into Missile, which
               makes it a sustained burst rather than a one-and-done.
profile      : RS_AttackProfile.MakeHitscan("grunt/attack", 9.0/45.0, 0, null,
                   "", false, "hitscan double-tap", "BulletPuff")
               // p.VolleyCount = 3; p.MaxRange = 800;
notes        : CHP's Missile block (01_P.txt:24-26) has NO terminator before
               `Hitscanne:` — if A_Jump(255) fails (1 in 256) it falls straight
               through into Hitscanne. That is CHP's behaviour, not a bug to
               fix, and it means the orb volley is 255/256 and the double-tap
               1/256 beyond 800 units.
```

## 6. Homing Orb Volley
`zscript/monsters/Zombieman/attacks/RS_Zombieman_OrbVolley.zs`

```
kind         : three-orb homing plasma volley
axes         : delivery:heavy payload:multi element:plasma behavior:homing
               role:skirmisher mobility:ground species:zombieman
tier(s)      : T04 Purple (CommonPurpleZombie)
chp source   : CHP/DECORATE/01/01_P.txt:33-39   (Orbb)
               projectile: CHP/DECORATE/01/01_P.txt:1332-1360 (Orbb11_C)
acs          : none
fires        : A_Custommissile("Orbb11_C", 46, 1)  x3, five tics apart.
               No angle spread — all three go dead ahead and then steer.
damage       : Damage (random(2,18))   [01_P.txt:1339]   DamageType Plasma
sprites      : BPOS E 5 (aim) / BPOS F 5 Bright x3 (three shots) / BPOS E 5
               orb: BAL1 A 2 Bright A_Seekermissile(2,3)
                    BAL1 B 2 Bright A_weave(5,4,2,1)   (loop)
                    BAL1 CDE 6 Bright                  (death)
sounds       : SeeSound "Weapons/Plasmaf"  DeathSound "weapons/plasmax"
               [01_P.txt:1347-1348]
behaviour    : Beyond 800 units the purple zombie stops shooting bullets and
               throws three small violet orbs, one every five tics. They SEEK
               (A_Seekermissile 2,3 — 2 degrees of turn, threshold 3) and they
               WEAVE (A_weave 5,4,2,1) so they corkscrew as they come. Scale
               0.3 makes each one tiny. Strafing does not shake them; breaking
               line of sight does. Three staggered seekers is the whole reason
               the purple zombie is dangerous in the open and harmless in a
               doorway.
profile      : RS_AttackProfile.MakeVolley("RS_Orbb11", 3, 0.0,
                   "Weapons/Plasmaf", 1.0, 0.0, "homing orb volley")
               // p.MinRange = 800;  and CHP staggers them 5 tics apart, which
               // MakeVolley fires on one tic — see notes.
notes        : MakeVolley puts all `count` rounds out on the SAME tic
               (rs_17:154-156). CHP spaces these FIVE TICS apart. That is
               BurstCount, not VolleyCount, and BurstCount does not exist yet
               (rs_17:137-138, PROPOSED). Until it does, this attack cannot be
               expressed as one profile without losing the stagger. Recording
               it rather than pretending MakeVolley(3) is equivalent.
```

## 7. Chaingun Three-Tap
`zscript/monsters/Zombieman/attacks/RS_Zombieman_ChaingunTap.zs`

```
kind         : walking three-shot chaingun burst
axes         : delivery:bullet payload:single element:kinetic trigger:burst
               role:skirmisher mobility:ground species:zombieman
tier(s)      : T05 Yellow / "Orange Zombiewoman" (CommonYellowZombie)
chp source   : CHP/DECORATE/01/01_Y.txt:30-38   (Bullets)
               gate  : CHP/DECORATE/01/01_Y.txt:24 (A_JumpIfCloser 550)
acs          : none
fires        : three separate single-bullet shots, each preceded by a re-aim:
                 A_Custombulletattack(4, 4, 1, random(1,3), "BulletPuff_C")
                 A_Custombulletattack(7, 7, 1, random(1,3), "BulletPuff_C")
                 A_Custombulletattack(9, 9, 1, random(1,3), "BulletPuff_C")
               3 tics of fire, 2 tics of A_FaceTarget between each.
damage       : random(1,3) per shot, CBAF_NORANDOM NOT set -> x random(1,3)
               = 1..9 per shot, 3..27 across the burst.
sprites      : CZOW F 3 Bright (each shot) / CZOW E 2 (each re-aim)
sounds       : A_Playsound("chainguy/attack") once, at the head of the burst
               (01_Y.txt:31)
behaviour    : The cone WIDENS as the burst goes — 4, then 7, then 9 degrees —
               which is backwards from a normal recoil pattern and means the
               first shot is the accurate one. She re-faces between every
               round, so sidestepping does not break the burst. Ends on
               A_Monsterrefire(128,"See") and loops back into Missile, so this
               sustains as long as she has line of sight. Used inside 550
               units, and it is also the fallback half of the coin flip
               beyond that (01_Y.txt:28).
profile      : RS_AttackProfile.MakeHitscan("chainguy/attack", 4.0/45.0, 0,
                   null, "", false, "chaingun three-tap", "BulletPuff")
               // p.MaxRange = 550; three beats, widening — see notes.
notes        : The widening cone is three DIFFERENT spreads in one burst.
               RS_AttackProfile carries one SpreadScale. Expressing this
               faithfully needs three profiles in a slot rotation, or the
               BurstCount fields from rs_17:137-138. Not solvable today.
```

## 8. Mini-Rocket (jamming)
`zscript/monsters/Zombieman/attacks/RS_Zombieman_MiniRocket.zs`

```
kind         : small rocket, three then the launcher jams
axes         : delivery:heavy payload:single element:explosive
               role:artillery mobility:ground species:zombieman
tier(s)      : T05 Yellow (CommonYellowZombie)
chp source   : CHP/DECORATE/01/01_Y.txt:39-44   (Rockets)
               jam   : CHP/DECORATE/01/01_Y.txt:45-55  (Jammed)
               projectile: CHP/DECORATE/01/01_Y.txt:1481-1507 (MiniRKTZombie_C)
acs          : none
fires        : A_Custommissile("MiniRKTZombie_C", 32, 2, random(-2,2))
               one rocket per pass, +-2 degrees.
damage       : direct  Damage (random(5,40))     [01_Y.txt:1487]  DamageType Fire
               splash  A_Explode(random(5,15), 58) on MISL B  [01_Y.txt:1502]
                       — ONE frame, so it fires once. Deliberate.
sprites      : CZOW F 3 Bright (fire) / CZOW E 2 (count) / CZOW E 2 (refire)
               rocket: MISL A 1 Bright (loop) ->
                       MISL B 8 Bright (explode) / MISL C 6 / MISL D 4
sounds       : SeeSound "weapons/rocklf"  DeathSound "weapons/rocklx"
               jam    : A_Playsound("Jam/Jamd", 0, 1.9) x4
               clear  : A_Playsound("Lady/Active")
behaviour    : THE TIER'S WHOLE IDENTITY. She carries exactly three rockets.
               A RocketCounter token increments after each; at three the next
               attempt goes to Jammed, where she sets +NOPAIN, stands in the
               open for 80 tics hammering a stuck launcher (four "Jam/Jamd"
               plays), clears the counter, grunts, drops NOPAIN, and returns to
               See. The jam is a free 80-tic window on a 90 HP monster — and
               because she is NOPAIN through it, you cannot stunlock her out
               of it, you just get to shoot her. Kiting her to three rockets
               and then closing is the intended play.
profile      : RS_AttackProfile.MakeVolley("RS_MiniRKTZombie", 1, 4.0,
                   "weapons/rocklf", 1.0, 0.0, "jamming mini-rocket")
notes        : The ammo counter and the jam window are NOT profile-expressible.
               RS_AttackProfile has AmmoClass/AmmoCost (rs_21:88) but no
               "out of ammo -> go to this state" hook. This attack needs the
               tier's own state machine either way; the profile only carries
               the round.
```

## 9. Twin Abyss Bolts
`zscript/monsters/Zombieman/attacks/RS_Zombieman_AbyssBolts.zs`

```
kind         : twin abyss bolts, fanned outward
axes         : delivery:heavy payload:multi element:void role:bruiser
               mobility:ground species:zombieman
tier(s)      : T06 Abyss (CommonAbyssZombie)
chp source   : CHP/DECORATE/01/01_A.txt:31-36   (Missile)
               projectile: CHP/DECORATE/01/01_A.txt:1208-1228 (AbyssZShotCH_C)
               parent    : CH/decorate/Zombies.txt:643-676    (AbyssZShotCH)
acs          : none
fires        : A_Custommissile("AbyssZshotCH_C", 36, 3, random(-7,1))
               A_Custommissile("AbyssZshotCH_C", 36, 3, random(-1,7))
               two bolts, five tics apart. The angle rolls are DELIBERATELY
               asymmetric — the first drifts left, the second right, and they
               overlap only in the -1..1 sliver.
damage       : direct  Damage (random(5,30))    [01_A.txt:1211]; DamageType Ice is
                       INHERITED, CH/decorate/Zombies.txt:652
               splash  A_Explode(random(1,8), 42) on `BAL7 CDE 4`
                       — THREE frames, so it fires THREE TIMES, 4 tics apart.
                       3 x random(1,8) = 3..24 of splash per bolt.
sprites      : ABTR E 10 (aim) / ABTR F 5 x2 (fire) / ABTR E 10 (recover)
               bolt: BAL1 A 2 Bright / BAL1 B 2 Bright a_weave(2,1,2,0.1)
                     death: BAL7 CDE 4 Bright
sounds       : SeeSound "imp/attack"  DeathSound "imp/shotx"  [01_A.txt:1212-1213]
behaviour    : Two dark bolts thrown a fifth of a second apart on diverging
               arcs, each weaving slightly as it flies. You cannot dodge both
               with one sidestep — the fan is the point. Each one detonates
               three times where it lands. A 200 HP monster at Speed 14 with
               PainChance 18 firing these is the first tier that pressures you
               rather than annoying you.
profile      : RS_AttackProfile.MakeVolley("RS_AbyssZshotCH", 2, 8.0,
                   "imp/attack", 1.0, 0.0, "twin abyss bolts")
notes        : NO `element:ice` VALUE EXISTS; DamageType is "Ice"
               (inherited, CH/decorate/Zombies.txt:652 — the CHP _C variant
               does not restate it) even though everything about the actor reads as
               void/shadow. Tagged element:void here because that value DOES
               exist and matches the fiction — but the RESISTANCE it should
               check is Ice. Flagging the mismatch rather than hiding it.
               The three-frame A_Explode is deliberate (lingering field), not
               the bug class from `project_rs_multiframe_explode`.
               CH's AbyssZShotCH additionally spawns AbyssShotIdentifier every
               flight frame (CH/decorate/Zombies.txt:669); CHP's _C variant
               DROPS that line (01_A.txt:1217-1220). CHP wins.
```

## 10. Abyss Splash Burst
`zscript/monsters/Zombieman/attacks/RS_Zombieman_AbyssBurst.zs`

```
kind         : pain-reflex splash field
axes         : delivery:radial payload:multi element:void role:bruiser
               mobility:ground species:zombieman
tier(s)      : T06 Abyss (CommonAbyssZombie)
chp source   : CHP/DECORATE/01/01_A.txt:37-41   (Pain)
               CHP/DECORATE/01/01_A.txt:61      (XDeath, 4 frames)
               projectile: CHP/DECORATE/03/03_A.txt:2088-2097 (SplashAbyss2_C)
               parent    : CH/decorate/Imps.txt:663-671       (SplashAbyss2)
acs          : none
fires        : on PAIN — FORTY-FIVE spawns on one tic:
               TNT1 AAAA...(45) 0 A_Spawnitemex("SplashAbyss2_C",
                   random(-178,178), random(-178,178), random(6,16),
                   0, 0, 2, 0, SXF_NOCHECKPOSITION)
               a 356 x 356 unit box around itself, each with upward velocity 2.
damage       : Damage (random(1,9)) per droplet [03_A.txt:2092], DamageType Ice
               -THRUACTORS +MTHRUSPECIES +DONTHARMCLASS — it passes through
               its own kind and cannot hurt the player's allies, but it CAN
               hurt the player.
sprites      : ABTR G 1 / ABTR G 1 (A_Pain) then the 45-spawn tic
               droplet: BAL1 AB 12 / BAL1 A 2 A_Jump(32,"Death") ->
                        BAL7 C 1 Bright A_SetScale(0.6) / BAL7 CDE 4 Bright
sounds       : PainSound "Form2/hurt" (01_A.txt:8)
behaviour    : HURTING IT IS THE TRIGGER. Two tics of flinch and then the
               floor for 178 units in every direction fills with rising
               black droplets, each of which hits for 1..9. It is a punish on
               fighting it up close, and the flinch is only 2 tics long
               (PainChance 18) so it does not cost the monster anything. The
               XDeath repeats a smaller version four times as the corpse
               falls (01_A.txt:61, random(-24,24) box).
profile      : RS_AttackProfile.MakeRadial(178.0, 5, 0, false, "Form2/hurt",
                   "abyss splash burst")
               // MakeRadial's `damage` is a flat int and cannot carry
               // random(1,9) x 45 spawns — see notes.
notes        : MakeRadial applies ONE damage number over a radius. CHP throws
               45 independent physical droplets that fall, rise, and can miss.
               Those are not the same thing: MakeRadial cannot miss, and CHP's
               field can be walked out of. Recorded honestly — the profile is
               an approximation, and the droplet spawn is the real mechanic.
               Do NOT flatten random(1,9) to 5 in the actor. The actor already
               HAS been flattened (see the GAPS section of the README).
               The plain SplashAbyss_C sown on the walk loop (01_A.txt:25,28)
               has NO Damage property — it is decoration, verified at
               CHP/DECORATE/03/03_A.txt:1979-1984. Not an attack.
```

## 11. Suicide Detonation
`zscript/monsters/Zombieman/attacks/RS_Zombieman_Kamikaze.zs`

```
kind         : contact suicide bomb
axes         : delivery:melee payload:single element:explosive role:fodder
               mobility:ground species:zombieman
tier(s)      : T07 Fireblu (CommonFirebluZombie)
chp source   : CHP/DECORATE/01/01_F.txt:34-37   (Melee)
               blast : CHP/DECORATE/01/01_F.txt:62-72  (XDeath)
acs          : none
fires        : Melee is TEN TICS of animation and then `DamageThing(9999)` on
               ITSELF, followed by `Goto XDeath`. It does not damage you
               directly at all — it kills itself into its own gib state.
damage       : A_Explode(random(12,44), 84)  [01_F.txt:65] — ONE frame, fires
               once. Radius 84.
               plus A_Quake(20, 12, 0, 64, 0) on the next frame [01_F.txt:66]
               plus 5 x FireSGguy2_C thrown outward, and 2 more fanned +-7
               (01_F.txt:68-70) — see entry 12 for what those do.
sprites      : ZOMF E 5 Bright / ZOMF F 5 Bright (the lunge) ->
               MISL X 6 Bright (blast) / MISL Y 6 Bright (quake) /
               MISL Z 6 (settle)
sounds       : A_PlaySound("weapons/rocklx", 7, 1) at the head of XDeath
behaviour    : ITS ONLY ATTACK. CHP gives the fireblu zombie a Missile state
               that is a single blank tic straight back into the walk
               (01_F.txt:31-33) — it has NO ranged attack of any kind. What it
               does is run at you at Speed 12 with PainChance 255 (it flinches
               constantly, which makes it look harmless), get in contact
               range, wind up for ten tics, and delete itself in an 84-unit
               explosion that also throws seven fire clouds. GibHealth -5, so
               almost anything overkills it into the same XDeath from range —
               killing it at distance is the counter, and killing it in your
               face is the failure.
profile      : RS_AttackProfile.MakeRadial(84.0, 28, 0, false, "weapons/rocklx",
                   "suicide detonation")
               // MakeRadial's flat 28 stands in for random(12,44); the roll
               // belongs at the A_Explode call site, not in the profile.
notes        : `DamageThing(9999)` is an ACTION SPECIAL used as an action
               function — it damages the calling actor. CH's parent
               FirebluZombie2 Melee is only `POSS EF 5 bright A_FaceTarget /
               Goto XDeath` (CH/decorate/Zombies.txt:411-413) with NO
               DamageThing.
               CHP ADDS the self-kill. CHP wins.
               No MeleeRange or MeleeDamage is set on either actor, so contact
               range is the engine default.
```

## 12. Fire Trail
`zscript/monsters/Zombieman/attacks/RS_Zombieman_FireTrail.zs`

```
kind         : trailing fire cloud
axes         : delivery:heavy payload:single element:thermal role:fodder
               mobility:ground species:zombieman
tier(s)      : T07 Fireblu (CommonFirebluZombie)
chp source   : CHP/DECORATE/01/01_F.txt:27,29   (See2 — one per half-lap)
               CHP/DECORATE/01/01_F.txt:39      (Pain — thrown forward at vel 9)
               CHP/DECORATE/01/01_F.txt:68-70   (XDeath — 5 + 2 fanned)
               projectile: CHP/DECORATE/14/14_F.txt:1987-2006 (FireSGguy2_C)
               parent    : CH/decorate/Archviles.txt:2285-2312 (FireSGguy2)
acs          : none
fires        : A_SpawnItemEx("FireSGguy2_C", -6, 0, 3, -2, 0, 1, -180)
               spawned BEHIND itself (x -6, angle -180) with backward velocity
               — it lays fire in its own footprints as it walks.
damage       : direct  Damage (random(5,15))  [14_F.txt:1992]  DamageType Fire
               splash  A_Explode(random(3,9), 32) on `FIRE CDEEDCDE 5 Bright`
                       — EIGHT frames, so EIGHT firings, 5 tics apart.
                       8 x random(3,9) = 24..72 over 40 tics, radius 32.
sprites      : FIRE AB 6 Bright -> FIRE CDEEDCDE 5 Bright / FIRE FGH 4 Bright
sounds       : SeeSound "imp/attack"  DeathSound "imp/shotx"  [14_F.txt:1993-1994]
behaviour    : The other half of the kamikaze. Every walk lap it drops a fire
               cloud behind itself, and every flinch throws one FORWARD at
               velocity 9 — so shooting it at close range lights the ground
               between you and it. The cloud burns for 40 tics and ticks eight
               times. A pack of fireblu zombies does not need to reach you;
               the room fills in behind them.
profile      : RS_AttackProfile.MakeVolley("RS_FireSGguy2", 1, 0.0, "imp/attack",
                   1.0, 0.0, "trailing fire cloud")
notes        : The eight-frame A_Explode is DELIBERATE — this is the
               "lingering fire" case from `project_rs_multiframe_explode` and
               must not be collapsed.
               CHP's _C variant HALVES the parent's blast radius (CH: 64,
               CHP: 32 — CH/decorate/Archviles.txt:2307 vs 14_F.txt:2002) and
               DROPS the parent's second A_Explode on FIRE FGH entirely
               (CH: `FIRE FGH 4 Bright A_Explode(random(5,15),64)`
               at CH/decorate/Archviles.txt:2308;
               CHP: `FIRE FGH 4 Bright` with no action). CHP wins — the CHP
               cloud is materially weaker than the CH one.
```

## 13. Sniper Bullet
`zscript/monsters/Zombieman/attacks/RS_Zombieman_Sniper.zs`

```
kind         : slow single sniper bullet
axes         : delivery:bullet payload:single element:kinetic trigger:semi
               role:skirmisher mobility:ground species:zombieman
tier(s)      : T08 Brown / "GET DOWN MR PRESIDENT" (CommonBrownZombie)
chp source   : CHP/DECORATE/01/01_BR.txt:37-41
acs          : none
fires        : A_CustomBulletAttack(5, 0, 1, 10, "BulletPuff_C", 0, CBAF_NORANDOM)
               one bullet, 5 degree cone, no vertical spread.
damage       : flat 10. CBAF_NORANDOM is SET, so no multiplier.
               CHP WROTE IT FLAT — this is not a flattened roll, there was
               never a roll here. Verified at 01_BR.txt:39.
sprites      : SGAR F 10 (aim) / SGAR G 10 BRIGHT (fire) / SGAR F 10 (recover)
sounds       : AttackSound "SNPRFIRE"  [01_BR.txt:10]
behaviour    : Thirty tics of standing still for one accurate bullet. The
               narrowest cone of any bullet attack in the family (5 degrees)
               and the slowest cycle. At Speed 4 the bodyguard cannot chase
               you, so this is what it does instead: plants itself and picks.
profile      : RS_AttackProfile.MakeHitscan("SNPRFIRE", 5.0/45.0, 0, null,
                   "", false, "sniper bullet", "BulletPuff")
notes        : none.
```

## 14. Bodyguard Dive
`zscript/monsters/Zombieman/attacks/RS_Zombieman_BodyguardDive.zs`

```
kind         : ally-shielding dive, heals the pack
axes         : delivery:radial role:skirmisher mobility:ground
               species:zombieman
tier(s)      : T08 Brown (CommonBrownZombie)
chp source   : CHP/DECORATE/01/01_BR.txt:30-36  (Checks — the target scan)
               CHP/DECORATE/01/01_BR.txt:42-44  (GETDOWN — the LOF gate)
               CHP/DECORATE/01/01_BR.txt:45-69  (GETDOWN2 — the dive)
               heal  : CHP/DECORATE/01/01_BR.txt:58
acs          : none
fires        : A_radiusgive("health", 100, RGF_MONSTERS, 50)
               +50 health to every MONSTER within 100 units, at the apex of
               the roll.
damage       : none. This is a SUPPORT action. Nothing about it hurts anyone.
sprites      : SGAR F, held for the whole 26-tic roll. The animation is
               A_SetRoll stepped 20 degrees at a time from 20 to 340 and back
               to 0 — a literal barrel roll, which is why CH gives the parent
               +ROLLSPRITE (CH/decorate/Zombies.txt:57).
sounds       : none declared for this state.
behaviour    : THE TIER'S IDENTITY, and it is not an attack on you at all.
               On roughly half its walk laps it scans 1000 units for an
               Archvile, Baron, HellKnight, Cyberdemon or Chaingunner
               (CPXF_ANCESTOR|CPXF_CHECKSIGHT|CPXF_SETMASTER|CPXF_CLOSEST) and
               if it finds one with line of fire to it, it faces its MASTER,
               launches itself upward and forward (thrustthingz 30,
               thrustthing 40), and rolls through the air between that demon
               and the incoming shot — healing every monster within 100 units
               by 50 on the way past. It is a pack-support unit disguised as a
               zombie. Killing the bodyguards first is a real tactical
               decision, and PACK should treat this as a HEAL, never as damage.
profile      : RS_AttackProfile.MakeRadial(100.0, 0, 50, true, "",
                   "bodyguard dive heal")
               // hitsAllies TRUE — the whole point.
notes        : CHP scans for the VANILLA class names. RS's monsters replace
               those classes but do not inherit from them, so the scan will
               find nothing unless the RS class names are substituted. The
               existing RS file already does this substitution
               (RS_Zombieman.zs:675-679) and it is correct.
               `FrontJump` (01_BR.txt:70-76) is the same launch aimed at the
               PLAYER instead, with no heal and no roll. It is pure movement,
               deals no damage, and gets no catalog entry.
```

## 15. Rock Volley
`zscript/monsters/Zombieman/attacks/RS_Zombieman_RockVolley.zs`

```
kind         : three thrown rocks
axes         : delivery:heavy payload:multi element:kinetic role:artillery
               mobility:ground species:zombieman
tier(s)      : T09 Gray (CommonGrayZombie)
chp source   : CHP/DECORATE/01/01_GY.txt:26-32  (Missile)
               projectile: CHP/DECORATE/01/01_GY.txt:1300-1322 (ZombieRock_C)
acs          : none
fires        : A_Custommissile("ZombieRock_C", 46, 1, random(-2,2))  x3,
               two tics apart, alternating Bright / not-Bright.
damage       : Damage (Random(1,12))  [01_GY.txt:1306]  DamageType "Melee"
                                                        [01_GY.txt:1307]
sprites      : SHDT E 10 (aim) / SHDT F 2 x3 (throws) / SHDT FEEEE 2 (recover)
               rock: JUBD ABCD 3 Bright (loop) ->
                     JUBD DDDD 0/1 Bright, spawning Drt2_C and Drt3_C debris
sounds       : SeeSound "monster/hamflr"  DeathSound "Butcher/melee"
               [01_GY.txt:1310-1311]
behaviour    : Three rocks in six tics, then a ten-tic tail. Speed 36 and
               Scale 0.25 — small, fast, and they burst into dirt when they
               land. DamageType "Melee" is doing something specific: it means
               armour types and resistances that key on melee apply, and the
               gray zombie's own Mass 400 / Speed 4 makes it a stationary
               artillery piece that you cannot outrun into cover quickly.
profile      : RS_AttackProfile.MakeVolley("RS_ZombieRock", 3, 4.0,
                   "monster/hamflr", 1.0, 0.0, "three-rock volley")
notes        : Same 2-tic stagger problem as entry 6 — MakeVolley fires all
               three on one tic; CHP spaces them. Recorded, not papered over.
```

## 16. Rock Ring (gib)
`zscript/monsters/Zombieman/attacks/RS_Zombieman_RockRing.zs`

```
kind         : dying rock burst in all directions
axes         : delivery:radial payload:multi element:kinetic role:artillery
               mobility:ground species:zombieman
tier(s)      : T09 Gray (CommonGrayZombie)
chp source   : CHP/DECORATE/01/01_GY.txt:50-68  (XDeath)
               the burst itself: CHP/DECORATE/01/01_GY.txt:67
acs          : none
fires        : TNT1 AAAAAAAAAAAAA 0 A_Custommissile("ZombieRock_C", 32, 0,
                   random(-359,359))
               THIRTEEN rocks on one tic, each at an independent random yaw.
damage       : Random(1,12) each, DamageType "Melee". 13..156 if every one
               connects, which they will not.
sprites      : SHDT G held through twelve A_SetScale wobble frames
               (1.2/0.8 alternating, tics 12,4,6,6,6,4,4,3,3,2,2,1,1) then
               MISL X 0 (sound) / MISL XYZ 2 (the pop)
sounds       : A_Playsound("weapons/rocklx")  [01_GY.txt:65]
behaviour    : Gibbing a gray zombie is punished. The corpse swells and
               squashes for about 50 tics — an unmistakable, readable tell —
               and then bursts, throwing thirteen rocks in thirteen random
               directions. Standing next to a gray zombie you just overkilled
               is a mistake. The wobble gives you time to move, which is the
               design: it is a telegraphed trap, not a gotcha.
profile      : RS_AttackProfile.MakeVolley("RS_ZombieRock", 13, 360.0,
                   "weapons/rocklx", 1.0, 0.0, "dying rock ring")
notes        : This is the one place in the family where MakeVolley IS exact —
               CHP genuinely fires all thirteen on one tic.
               Note the gray tier's DEATH (01_GY.txt:40-49) is an ordinary
               corpse; only XDeath does this.
```

## 17. Heavy Slug
`zscript/monsters/Zombieman/attacks/RS_Zombieman_Slug.zs`

```
kind         : single heavy slug
axes         : delivery:bullet payload:single element:kinetic trigger:semi
               role:bruiser mobility:ground species:zombieman
tier(s)      : T10 Red / "Red ZombieUnman" (CommonRedZombie)
chp source   : CHP/DECORATE/01/01_R.txt:19-24   (Missile)
               puff  : CHP/DECORATE/01/01_R.txt:1602-1604 (BloodyPuff_C)
               parent: CH/decorate/Zombies.txt:1553-1565  (BloodyPuff)
acs          : none
fires        : A_CustomBulletAttack(10, 2, 1, random(5,15), "BloodyPuff_C")
               one bullet, 10 deg horizontal, 2 deg vertical.
damage       : random(5,15) and CBAF_NORANDOM NOT set -> x random(1,3)
               = 5..45 from a single round.
sprites      : ZUNM E 15 (aim) / ZUNM F 10 (fire) / ZUNM E 10 (recover)
               puff: DBLD A 4 BRIGHT / DBLD BCD 4   (+EXTREMEDEATH — this puff
               gibs what it kills)
sounds       : AttackSound "zombie/unmaker" (inherited, CH/decorate/Zombies.txt:1451)
behaviour    : Thirty-five tics for one round that can hit for 45. The puff
               carries +EXTREMEDEATH, so a kill from this always gibs. It is
               the 3-in-4 branch; the other quarter is the rail barrage below.
profile      : RS_AttackProfile.MakeHitscan("zombie/unmaker", 10.0/45.0, 0,
                   null, "", false, "heavy slug", "RS_BloodyPuff")
notes        : CH's parent is `A_CustomBulletAttack(2,2,1,random(5,25),
               "BloodyPuff")` (CH/decorate/Zombies.txt:1490) — a TIGHTER cone
               and a BIGGER roll. CHP widens the cone to 10 and cuts the roll
               to random(5,15). CHP wins. Recorded because the two numbers are
               easy to mix up.
```

## 18. Unmaker Rail Barrage
`zscript/monsters/Zombieman/attacks/RS_Zombieman_Unmaker.zs`

```
kind         : five-beam fading railgun barrage
axes         : delivery:bullet payload:multi element:kinetic trigger:fullauto
               role:bruiser mobility:ground species:zombieman
tier(s)      : T10 Red (CommonRedZombie)
chp source   : CHP/DECORATE/01/01_R.txt:25-38   (Missile2)
               gate  : CHP/DECORATE/01/01_R.txt:20 (A_Jump(64) — 25%)
acs          : none
fires        : five A_CustomRailgun(random(5,10), 4, "<colour>", 0, 0) calls,
               one per tic, colours stepping FF/CC/99/55/33 00 00 — a red beam
               that visibly DARKENS across the burst.
damage       : random(5,10) per beam, 5 beams = 25..50 per barrage.
               Railgun: instant, pierces, no projectile to dodge.
sprites      : ZUNM E 16 (wind-up) then ZUNM F 1 BRIGHT x5 with ZUNM E 0
               sound frames interleaved, then ZUNM E 10 (refire check)
sounds       : A_PlaySound("zombie/unpower") once BEFORE each of the five
               beams — five plays per barrage.
behaviour    : Sixteen tics of wind-up with a distinctive rising "unpower"
               sound, then five instant rail beams in five tics that fade from
               bright red to nearly black. There is nothing to dodge once it
               starts — the wind-up is the entire window. Ends on
               A_SentinelRefire and loops back to the FIRST beam (Missile2+1,
               01_R.txt:38), skipping the wind-up, so a red zombie that keeps
               line of sight sustains the barrage indefinitely with only ten
               tics between volleys.
profile      : RS_AttackProfile.MakeHitscan("zombie/unpower", 0.0, 0, null,
                   "", true, "unmaker rail barrage", null)
               // Mode is HITSCAN; A_CustomRailgun's pierce/beam is not
               // representable in the profile as it stands — see notes.
notes        : RS_AttackProfile HAS NO RAILGUN MODE. The seven modes are
               BULLET / HEAVY / MELEE / HITSCAN / SUMMON / RADIAL / SELFBUFF
               (rs_21:83-84). A rail beam is not a hitscan: it pierces every
               actor in the line and draws a trail. Modelling it as HITSCAN
               loses the pierce. There IS a live `behavior:piercing` string
               (RS_FX_BallisticFired.zs:140) but no keyword grants it and
               rs_18:275 lists adding it as open work. Flagged, not faked.
               The Missile2 loop target is `Missile2+1`, NOT `Missile2` — the
               16-tic wind-up plays once and never again.
```

## 19. Fist
`zscript/monsters/Zombieman/attacks/RS_Zombieman_Fist.zs`

```
kind         : bare-fisted punch
axes         : delivery:melee payload:single element:kinetic role:boss
               mobility:ground species:zombieman
tier(s)      : T11 Black / "Player 9"   (CommonBlackZombie1)
               TEX Black-EX / "Player X" (CommonBlackZombieEX2)
chp source   : CHP/DECORATE/01/01_K.txt:30-33    (T11 Melee)
               CHP/DECORATE/01/01_KX.txt:36-40   (TEX Melee)
acs          : none
fires        : T11  a_custommeleeattack(random(20,80), "*fist", "none")
               TEX  a_custommeleeattack(random(60,120), "*fist", "none")
damage       : T11 random(20,80)   TEX random(60,120)
sprites      : ZOMK E 4 (face) / ZOMK E 4 (punch)    [T11]
               ZMKX E 4 / ZMKX E 4                   [TEX]
sounds       : "*fist" — the PLAYER's own punch sound. Deliberate: these two
               tiers are dead marines, not zombies, and everything about them
               uses the player sound set.
behaviour    : If you close on Player 9 or Player X they hit you, hard, with
               nothing but a fist — and then IMMEDIATELY go to the super
               shotgun state (`Goto Shotttgun`, 01_K.txt:33 / 01_KX.txt:40).
               The punch is not a melee option, it is the opening of a
               point-blank SSG combo. random(60,120) followed by an 8-pellet
               SSG blast at contact range is most of a player's health.
               TEX additionally checks whether its target is a CORPSE right
               after punching (01_KX.txt:39) and will break off to taunt.
profile      : RS_AttackProfile.MakeMelee(64.0, "*fist", null, true, 1.0,
                   "marine fist")
notes        : Third argument "none" is DECORATE for "no miss sound"; the
               ZScript equivalent is an empty string, not the literal "none".
```

## 20. Super Shotgun Blast
`zscript/monsters/Zombieman/attacks/RS_Zombieman_SSG.zs`

```
kind         : super shotgun blast, one shell then a reload
axes         : delivery:bullet payload:multi element:kinetic trigger:semi
               role:boss mobility:ground species:zombieman
tier(s)      : T11 Black (CommonBlackZombie1), TEX Black-EX (CommonBlackZombieEX2)
chp source   : CHP/DECORATE/01/01_K.txt:39-45    (T11 Shotttgun)
               CHP/DECORATE/01/01_K.txt:46-52    (T11 Jammed — the reload)
               CHP/DECORATE/01/01_KX.txt:67-79   (TEX Shotttgun + Shootmydude)
               CHP/DECORATE/01/01_KX.txt:80-87   (TEX Jammed — the reload)
acs          : none
fires        : A_CustomBulletAttack(22.5, 5, 8, 6, "BulletPuff_C", 0)
               EIGHT pellets, 22.5 deg horizontal, 5 deg vertical. Identical
               call in both tiers.
damage       : 6 per pellet, CBAF_NORANDOM NOT set -> x random(1,3)
               = 6..18 per pellet, 48..144 for a full-face hit.
sprites      : ZOMK E 3 (face) / ZOMK F 13 Bright (blast)      [T11]
               ZMKX E 3 / ZMKX E 1 / ZMKX E 1 / ZMKX E 10 / ZMKX F 13 Bright [TEX]
               reload: ZOMK E 8 Bright / ZOMK A 2 / ZOMK A 8 / ZOMK E 2
sounds       : fire   A_PlaySound("weapons/sshotf")
               reload A_Playsound("weapons/sshotl")
               plus a real Shell actor ejected at angle+5 (01_K.txt:50)
behaviour    : ONE SHELL. It fires, sets a ShotgunWhere token, and the NEXT
               time it wants the shotgun it must reload instead: 20 tics of
               standing still racking the gun and throwing a shell. That
               window is the fight. TEX makes it worse for you in two ways —
               it HOPS the last of the gap before firing if you are outside
               300 (thrustthingz 64, thrustthing 12; 01_KX.txt:70-71), and
               after the reload it does NOT return to neutral: it rolls
               84/256 into the rocket barrage and then 64/256 into the BFG
               (01_KX.txt:85-86). Reloading commits it to an attack.
profile      : RS_AttackProfile.MakeHitscan("weapons/sshotf", 22.5/45.0, 1,
                   null, "Shell", true, "super shotgun blast", "BulletPuff")
               // p.VolleyCount = 8; p.MaxRange = 300;
notes        : `ShotgunWhere` is an Inventory token; it is not defined in
               any 01_*.txt or in CH/decorate/Zombies.txt. I could not find
               its definition anywhere in CH or CHP DECORATE. Reported as
               uncertainty: the MECHANIC is unambiguous from the call sites,
               the token's MaxAmount is not.
```

## 21. Plasma Spam
`zscript/monsters/Zombieman/attacks/RS_Zombieman_PlasmaSpam.zs`

```
kind         : widening four-bolt plasma burst
axes         : delivery:heavy payload:multi element:plasma trigger:fullauto
               role:boss mobility:ground species:zombieman
tier(s)      : T11 Black (CommonBlackZombie1), TEX Black-EX (CommonBlackZombieEX2)
chp source   : CHP/DECORATE/01/01_K.txt:53-64    (T11 PlasmaSpammer)
               CHP/DECORATE/01/01_KX.txt:122-136 (TEX PlasmaSpammer)
               projectile: CHP/DECORATE/12/12_B.txt:1232-1257 (PlasmaBallSP3_C)
acs          : none
fires        : four A_custommissile("PlasmaBallSP3_C", 32, 0, <spread>) with
               the spread WIDENING every shot:
                 random(-5,5) -> random(-15,15) -> random(-25,25) -> random(-35,35)
               3 tics of fire, 1 tic of A_FaceTarget between each.
damage       : Damage 5 flat  [12_B.txt:1239], DamageType Plasma.
               CHP WROTE IT FLAT — no roll was lost here. Verified.
sprites      : ZOMK/ZMKX F 3 Bright per bolt, E 1 between
               bolt: PLSS AB 6 Bright -> PLSE ABCDE 4 Bright
sounds       : SeeSound "weapons/plasmaf"  DeathSound "weapons/plasmax"
behaviour    : Used from 300 to 840 units. The burst gets WIDER as it goes,
               which means the safe lane you are standing in closes while you
               are standing in it — sidestepping into the gap after bolt one
               walks you into bolt four. Ends on A_MonsterRefire(128) into a
               CellEject animation (two spent Cell casings thrown, 01_K.txt:67)
               or straight back into Missile.
               TEX adds two escape hatches you do not get a say in: an 84/256
               roll into the rocket barrage BEFORE the burst starts
               (01_KX.txt:123) and a 34/256 roll into the BFG after the third
               bolt (01_KX.txt:132).
profile      : RS_AttackProfile.MakeVolley("RS_PlasmaBallSP3", 4, 10.0,
                   "weapons/plasmaf", 1.0, 0.0, "plasma spam")
               // p.MinRange = 300; p.MaxRange = 840;
notes        : The WIDENING is the attack. One VolleyArc cannot express four
               different arcs. Same structural gap as entry 7 — this needs
               either four profiles in a rotation or rs_17's BurstCount.
```

## 22. Chaingun Tap
`zscript/monsters/Zombieman/attacks/RS_Zombieman_MarineChaingun.zs`

```
kind         : single chaingun tap on a refire loop
axes         : delivery:bullet payload:single element:kinetic trigger:fullauto
               role:boss mobility:ground species:zombieman
tier(s)      : T11 Black (CommonBlackZombie1), TEX Black-EX (CommonBlackZombieEX2)
chp source   : CHP/DECORATE/01/01_K.txt:70-77    (T11 Rawkets)
               CHP/DECORATE/01/01_KX.txt:142-151 (TEX Rawkets)
acs          : none
fires        : A_custombulletattack(5.6, 0, 1, 5, "BulletPuff_C")
               one bullet, 5.6 deg cone, no vertical spread.
damage       : 5 per bullet, CBAF_NORANDOM NOT set -> x random(1,3) = 5..15.
sprites      : ZOMK/ZMKX E 2 (face) / F 2 Bright (fire) / E 2 (roll)
sounds       : none declared on this state — it uses the actor's AttackSound.
behaviour    : What they do beyond 840 units. Six tics per tap, held together
               by A_CPosRefire, so it reads as a chaingun rather than a rifle.
               Every tap has a 32/256 chance of becoming a rocket instead
               (entry 23), so the long-range pattern is bullets with rockets
               salted through it. TEX adds an 8/256 roll into the BFG on top
               (01_KX.txt:147) and re-faces before each tap (01_KX.txt:143)
               where T11 does not (01_K.txt:71) — TEX's long-range fire tracks
               you and T11's does not.
profile      : RS_AttackProfile.MakeHitscan("", 5.6/45.0, 0, null, "", false,
                   "marine chaingun tap", "BulletPuff")
               // p.MinRange = 840;
notes        : CHP's Rawkets block has two lines of UNREACHABLE code after
               `Goto Missile` (01_K.txt:76-77, 01_KX.txt:150-151):
                   ZOMK A 0
                   Goto See
               Dead in CHP, dead in any faithful port. Quoted so nobody
               "restores" it.
```

## 23. Rocket
`zscript/monsters/Zombieman/attacks/RS_Zombieman_MarineRocket.zs`

```
kind         : single rocket
axes         : delivery:heavy payload:single element:explosive role:boss
               mobility:ground species:zombieman
tier(s)      : T11 Black (CommonBlackZombie1), TEX Black-EX (CommonBlackZombieEX2)
chp source   : CHP/DECORATE/01/01_K.txt:78-82    (T11 ActualRawk)
               CHP/DECORATE/01/01_KX.txt:152-157 (TEX ActualRawk)
               projectile: CHP/DECORATE/17/17_C.txt:965-989 (Rocket_C)
acs          : none
fires        : A_Custommissile("Rocket_C", 32, 0, random(-1,1))
               one rocket, +-1 degree. Effectively dead straight.
damage       : Damage 20 flat  [17_C.txt:970]
               splash A_Explode() with no arguments -> engine default
               (128 damage, 128 radius)  [17_C.txt:984], ONE frame.
               CHP WROTE IT FLAT. No roll lost.
sprites      : ZOMK/ZMKX E 2 / F 2 Bright / E 2
               rocket: MISL A 1 Bright -> MISL B 8 / MISL C 6 / MISL D 4
sounds       : SeeSound "weapons/rocklf"  DeathSound "weapons/rocklx"
behaviour    : Fired at 32/256 out of the chaingun loop. A bare-argument
               A_Explode is the full 128/128 rocket blast — this is not a
               small rocket, it is the player's rocket launcher pointed at
               you by something with 2000-5000 HP. TEX rolls 34/256 into the
               BFG immediately after firing one (01_KX.txt:156).
profile      : RS_AttackProfile.MakeVolley("RS_Rocket", 1, 2.0,
                   "weapons/rocklf", 1.0, 0.0, "marine rocket")
notes        : Rocket_C is a FastProjectile, not the stock Rocket
               (17_C.txt:965). It is meaningfully faster than a player rocket.
```

## 24. Rocket Barrage (strafing)
`zscript/monsters/Zombieman/attacks/RS_Zombieman_RocketBarrage.zs`

```
kind         : strafing three-rocket barrage
axes         : delivery:heavy payload:multi element:explosive role:boss
               mobility:ground species:zombieman trait:ex
tier(s)      : TEX Black-EX (CommonBlackZombieEX2)
chp source   : CHP/DECORATE/01/01_KX.txt:88-101  (RBarrage — strafes RIGHT)
               CHP/DECORATE/01/01_KX.txt:102-111 (AltBar — strafes LEFT)
               entries: 01_KX.txt:85 (after reload, 84/256)
                        01_KX.txt:123 (before plasma, 84/256)
                        01_KX.txt:161 (on PAIN, 84/256)
acs          : none
fires        : three A_Custommissile("Rocket_C", 32, 0, random(-1,1)), four
               tics apart, WHILE MOVING sideways.
damage       : 20 direct + default A_Explode (128/128) per rocket. Three of
               them. See entry 23.
sprites      : ZMKX E 1 (hop up) / E 1 (hop back) / E 6 (face) then
               ZMKX E 1 / E 3 (strafe) / F 4 Bright x3 (fire)
sounds       : "weapons/rocklf" per rocket.
behaviour    : IT BACKPEDALS, THEN STRAFES, THEN FIRES. First it hops
               backward (thrustthing angle-180), then coin-flips left or
               right (angle+90 vs angle-90, 01_KX.txt:92) and hops that way,
               and only then puts three rockets downrange. So the rockets come
               from a position you were not looking at, and which side is a
               50/50 you cannot read. It answers PAIN with this 84/256 of the
               time, which means hurting Player X makes it MORE dangerous.
               Every rocket is followed by a corpse check that can break the
               barrage off into a taunt.
profile      : RS_AttackProfile.MakeVolley("RS_Rocket", 3, 2.0,
                   "weapons/rocklf", 1.0, 0.0, "strafing rocket barrage")
notes        : The strafe is inseparable from the attack — a profile that
               fires three rockets from a standing monster is a DIFFERENT
               attack. RS_AttackProfile has no movement field of any kind
               (rs_21:83-91). This one needs its state block regardless.
```

## 25. BFG Shot
`zscript/monsters/Zombieman/attacks/RS_Zombieman_BFG.zs`

```
kind         : BFG ball with a shrapnel bloom
axes         : delivery:heavy payload:multi element:plasma role:boss
               mobility:ground species:zombieman trait:ex
tier(s)      : TEX Black-EX (CommonBlackZombieEX2)
chp source   : CHP/DECORATE/01/01_KX.txt:112-121 (BFGBoi)
               projectile: CHP/DECORATE/01/01_KX.txt:3007-3035 (PlayerEXBFG_C)
               shrapnel  : CHP/DECORATE/01/01_KX.txt:3367-3385 (PlayerEXBFG2_C)
               parent    : CH/decorate/Zombies.txt:1857-1884   (PlayerEXBFG2)
               entries   : 01_KX.txt:86 (after reload), :132 (mid-plasma),
                           :147 (mid-chaingun), :156 (after a rocket)
acs          : none
fires        : A_Custommissile("PlayerEXBFG_C", 32, 0, 0) — dead straight,
               no spread at all.
damage       : ball      Damage (random(100,200))  [01_KX.txt:3013]
               quake     Radius_Quake(15, 15, 0, 40, 0)  [01_KX.txt:3029]
               blast     A_Explode(random(45,125), 156)  [01_KX.txt:3030]
                         ONE frame — fires once. Radius 156.
               shrapnel  29 x PlayerEXBFG2_C, each Damage (random(20,80))
                         [01_KX.txt:3031, 3370]
               A single clean hit is 100..200 + 45..125 + whatever shrapnel
               connects. It one-shots most builds.
sprites      : ZMKX E 1 / E 1 / E 10 Bright / E 8 Bright / E 6 Bright
               (24 tics of wind-up) then ZMKX F 4 Bright (fire) / E 12
               ball: BFS1 AB 2 Bright, trailing TrailSPCguy_C
               blast: BFE1 AB 8 / BFE1 C 8 / BFE1 DEF 8
sounds       : a_playsound("weapons/bfgf", 0) at the head of the wind-up.
behaviour    : THE THING THAT KILLS YOU. Twenty-four tics of standing
               absolutely still, glowing, with the BFG charge sound playing —
               the most readable telegraph in the family, and deliberately so.
               Then one un-spread ball. It detonates for 156 units, shakes the
               screen, and blooms twenty-nine independent shrapnel bolts in
               random directions, each of which does 20..80 and each of which
               self-destructs on a 2/256 roll per frame so the cloud thins
               instead of persisting. FOUR different branches can escalate
               into it, so there is no range or behaviour that makes you safe
               from it — only the wind-up.
profile      : RS_AttackProfile.MakeVolley("RS_PlayerEXBFG", 1, 0.0,
                   "weapons/bfgf", 1.0, 0.0, "BFG shot")
notes        : The 24-tic wind-up is not expressible today. rs_17:134
               PROPOSES `int WindupTics` for exactly this shape and it is not
               built. Until it is, the wind-up lives in the state block.
```

## 26. Shovel Blade Fan
`zscript/monsters/Zombieman/attacks/RS_Zombieman_Shovel.zs`

```
kind         : close-range shovel blade fan
axes         : delivery:melee payload:multi element:kinetic role:boss
               mobility:ground species:zombieman
tier(s)      : T12 White / "THE UNDERTAKER" (CommonWhiteZombie1)
chp source   : CHP/DECORATE/01/01_W.txt:104-112  (Shovel)
               projectile: CHP/DECORATE/01/01_W.txt:7091-7129 (ShoveZM_C)
acs          : none
fires        : three A_custommissile("ShoveZM_C", 38, <ofs>, <angle>) on ONE
               tic:  (38, 0, 0) / (38, 3, 5) / (38, -3, -5)
               a three-wide fan, and each ShoveZM_C then sprays its OWN
               side-blades as it travels (01_W.txt:7108-7120) — ShoveZM2_C
               and ShoveZM3_C, forward AND backward at -180, twenty-plus
               spawns per blade.
damage       : blade   damage (random(10,45))  [01_W.txt:7095]  DamageType Melee
               blast   A_Explode(random(5,20), 64) on `FBL1 EFG 1 bright`
                       [01_W.txt:7125] — THREE frames, THREE firings.
               +EXTREMEDEATH +BLOODSPLATTER — kills from this always gib.
sprites      : MAGE E 7 (raise) / MAGE F 7 Bright (swing, spawns all three)
               blade: BLAD A, held, spraying ShoveZM2/3 the whole flight
               impact: BLAD A 1 / 6PUF ABCDEF 1 / FBL1 EFG 1 Bright
sounds       : A_Playsound("Spell/SpellCast1") on the swing  [01_W.txt:106]
               blade attacksound "skelsit4", deathsound "moloch/nailhitbleed"
behaviour    : Inside 550 units the Undertaker swings, and what comes out is
               not three projectiles — it is three projectiles that are each
               continuously shedding more blades in every direction, forward
               and behind, for their whole flight. At contact range it is a
               wall. Each core blade rolls 10..45 and detonates three times
               for 5..20 in a 64-unit radius. It exits into ShotBone2 if the
               ladder is at grade 2 (01_W.txt:110), otherwise coin-flips back
               into Missile or ShotBone (01_W.txt:111) — it does not give the
               range back.
profile      : RS_AttackProfile.MakeVolley("RS_ShoveZM", 3, 10.0,
                   "Spell/SpellCast1", 1.0, 0.0, "shovel blade fan")
               // p.MaxRange = 550;
notes        : The blade's Death also spawns a MrBones skeleton at failchance
               128, i.e. a 50% chance (01_W.txt:7126). That is the summon in
               entry 30 and it is HALF of what makes the Undertaker fight
               escalate. Do not treat ShoveZM as a pure damage projectile.
```

## 27. Bone Shotgun
`zscript/monsters/Zombieman/attacks/RS_Zombieman_BoneShotgun.zs`

```
kind         : shotgun blast of bones
axes         : delivery:heavy payload:multi element:kinetic trigger:semi
               role:boss mobility:ground species:zombieman
tier(s)      : T12 White (CommonWhiteZombie1)
chp source   : CHP/DECORATE/01/01_W.txt:79-84    (ShotBone,  grade 1)
               CHP/DECORATE/01/01_W.txt:85-88    (ShotBone2, grade 2)
               CHP/DECORATE/01/01_W.txt:70-75    (ShotBone3, grade 3)
               projectiles: 01_W.txt:6580-6610 (BoneProjZM_C)
                            01_W.txt:6871-6875 (BoneProjZM2_C)
                            01_W.txt:6981-6985 (BoneProjZM3_C)
acs          : none
fires        : grade 1   9 x BoneProjZM_C  on one tic (MAGE FFFFFFFFF 0)
               grade 2  12 x BoneProjZM2_C on one tic (MAGE FFFFFFFFFFFF 0)
               grade 3  11 x BoneProjZM3_C on one tic (MAGE FFFFFFFFFFF 0)
               all with A_custommissile(<cls>, random(32,42), random(-5,5),
                   random(-12,12), 32, random(-3,3))
               — the SPAWN HEIGHT is itself randomised per bone.
damage       : grade 1  Damage (random(4,16))  Speed 32  [01_W.txt:6585-6586]
               grade 2  Damage (random(8,20))  Speed 36  [01_W.txt:6873-6874]
               grade 3  Damage (random(12,26)) Speed 40  [01_W.txt:6983-6984]
               +FORCEPAIN — every bone that connects staggers you.
sprites      : MAGE E 8 (raise) / MAGE F 5-6 Bright (the blast) / MAGE E 5
               bone: BBBN ABCD 4 (loop) -> MISL BCD 3 (shatter)
sounds       : SeeSound "skelatt"  Deathsound "swordhit"  [01_W.txt:6593-6594]
behaviour    : Nine to twelve bones in a 24-degree cone, all on one tic, all
               spawned at slightly different heights so the wall of bone has
               depth as well as width. +FORCEPAIN means a single connecting
               bone interrupts you and the rest of the blast lands while you
               are staggered. Used from 550 to 1250 units. The GRADE is the
               Undertaker's ladder: grade 2 unlocks at BoneUp 9, grade 3 in
               FinalForm. Grade 3 nearly doubles grade 1's floor damage.
profile      : RS_AttackProfile.MakeVolley("RS_BoneProjZM", 9, 24.0, "skelatt",
                   1.0, 6.0, "bone shotgun")
               // grade 2: MakeVolley("RS_BoneProjZM2", 12, 24.0, ...)
               // grade 3: MakeVolley("RS_BoneProjZM3", 11, 24.0, ...)
               // three profiles in one slot; the ladder picks the index.
notes        : NO ELEMENT VALUE FITS. BoneProjZM_C declares NO DamageType at
               all (01_W.txt:6580-6599) — it is untyped/normal damage.
               element:kinetic is the closest live value and is what is used
               above, but "bone" is a distinct identity in this mod and the
               vocabulary has no word for it.
               EVERY bone that dies spawns a MrBones at failchance 250 — a
               6/256 (~2.3%) chance each (01_W.txt:6608). Nine to twelve bones
               per blast means roughly one skeleton every 4 blasts. See
               entry 30.
```

## 28. Rapid Bone Stream
`zscript/monsters/Zombieman/attacks/RS_Zombieman_RapidBone.zs`

```
kind         : sustained rapid-fire bone stream
axes         : delivery:heavy payload:single element:kinetic trigger:fullauto
               role:boss mobility:ground species:zombieman
tier(s)      : T12 White (CommonWhiteZombie1)
chp source   : CHP/DECORATE/01/01_W.txt:89-96    (RapidBone,  grade 1)
               CHP/DECORATE/01/01_W.txt:97-103   (RapidBone2, grade 2)
               CHP/DECORATE/01/01_W.txt:64-69    (RapidBone3, grade 3)
acs          : none
fires        : grade 1  2 bones/tic-pair, A_custommissile(BoneProjZM_C,
                   random(34,40), random(-2,2), random(-5,5), 32, random(-1,1))
               grade 2  2 bones, tighter: random(-1,1) / random(-3,3)
               grade 3  THREE bones, tightest, and a 1-tic loop instead of 2
damage       : same three grades as entry 27 — random(4,16) / random(8,20) /
               random(12,26). +FORCEPAIN on all of them.
sprites      : MAGE E 7 (raise) then MAGE F 1 Bright per bone, looping
sounds       : "skelatt" per bone.
behaviour    : The long-range answer, used beyond 1250 units. Narrow, fast,
               and it LOOPS — A_Monsterrefire(150) at grade 1, tightening to
               120 at grades 2 and 3 — so it keeps streaming as long as it can
               see you. As the ladder climbs, the stream gets tighter, faster
               AND heavier: grade 1 is a 10-degree scatter every 2 tics, grade
               3 is a 4-degree stream of three bones every tic. Grade 1 also
               has a 12/256 chance per loop of breaking into the bone shotgun
               instead (01_W.txt:94).
profile      : RS_AttackProfile.MakeVolley("RS_BoneProjZM", 2, 10.0, "skelatt",
                   1.0, 2.0, "rapid bone stream")
               // grade 2: MakeVolley("RS_BoneProjZM2", 2, 6.0, ...)
               // grade 3: MakeVolley("RS_BoneProjZM3", 3, 4.0, ...)
notes        : Same untyped-damage / no-element-value problem as entry 27.
               The loop-and-refire structure is state machinery, not profile
               data; the profile carries one burst of the stream.
```

## 29. Bone Tornado
`zscript/monsters/Zombieman/attacks/RS_Zombieman_BoneTornado.zs`

```
kind         : roaming bone tornado
axes         : delivery:radial payload:multi element:kinetic role:boss
               mobility:ground species:zombieman
tier(s)      : T12 White (CommonWhiteZombie1) — FINAL FORM ONLY
chp source   : CHP/DECORATE/01/01_W.txt:52-63    (BoneTornado)
               gate  : CHP/DECORATE/01/01_W.txt:36 (user_skel1 == 4)
                       CHP/DECORATE/01/01_W.txt:50 (MedRange2, 1-in-3)
               tornado   : CHP/DECORATE/01/01_W.txt:4268-4318 (BoneTorn2_C)
               ring bones: CHP/DECORATE/01/01_W.txt:5080-5108 (BoneStormer1_C)
                           01_W.txt:5410-5421 (BoneStormer2_C, Speed 105)
                           01_W.txt:5605-5616 (BoneStormer3_C, Speed 115)
                           and BoneStormer4_C..7_C, same pattern
acs          : none
fires        : A_Custommissile("BoneTorn2_C", 4, 0, random(-64,64))
               ONE tornado, launched at a random yaw within a 128-degree arc.
               The tornado then, for its whole life, per tic:
                 A_Wander  (it roams — it does not track you)
                 A_SpawnItemEx("BoneStormerN_C", 0,0,4, ...,
                     SXF_SETMASTER|SXF_ORIGINATOR)   x seven variants
                 A_CustomMissile("BoneProjZM3_C", 4, random(-20,20),
                     CMF_AIMOFFSET, random(0,360), random(0,360))
                     — bones fired at COMPLETELY random yaw and pitch
damage       : ring bones  Damage (random(1,3))  Speed 105-120  +Ripper
                           +FORCEPAIN  [01_W.txt:5085-5090]
               loose bones random(12,26) (BoneProjZM3_C)
               The ring bones are cheap individually and there are dozens
               alive at once; +Ripper means they do not stop on you.
sprites      : MAGE E 9/7/7/5/5/3/3 (a 39-tic wind-up) / MAGE F 5 Bright
               (launch) / MAGE F 3 / MAGE E 3
               tornado: RNGG AB (wander) / RNGG C, D (the body)
               ring bone: BBBN A/B 1 Bright, A_Warp'd to the master every tic
sounds       : A_Playsound("Under/Goodie", 7, 2, false, ATTN_NONE) at the head
               of the wind-up — full volume, no attenuation, heard map-wide.
behaviour    : THE FINAL-FORM ATTACK, and it does not aim at you. The
               Undertaker spends 39 tics winding up with a map-wide sound and
               then throws a wandering vortex into the room. The vortex
               A_Wanders on its own path and continuously A_Warps seven
               streams of ripping bone around itself at radii 10-32 and speeds
               105-120, incrementing each one's angle by 8 degrees per tic so
               they orbit — plus loose grade-3 bones at fully random yaw and
               pitch. It is a moving no-go zone with a shredding skirt, and it
               only ends when a 8/256 per-loop roll kills it. You cannot
               dodge it by reading it; you have to leave the area it is in.
profile      : RS_AttackProfile.MakeVolley("RS_BoneTorn2", 1, 128.0,
                   "Under/Goodie", 1.0, 0.0, "bone tornado")
               // the tornado's own emissions are the actor's job, not the
               // profile's — the profile only launches it.
notes        : SEVEN BoneStormer variants exist (1..7), differing in Speed
               (105/115/120...), warp radius (10-32) and self-destruct roll
               (A_Jump 4 vs 8). The RS tree has ONE (`RS_BoneStormer`,
               zscript/monsters/monsterfx/RS_human_projectiles.zs:276).
               Same untyped-damage / no-element-value problem as entry 27.
```

## 30. Skeleton Hatch
`zscript/monsters/Zombieman/attacks/RS_Zombieman_SkeletonHatch.zs`

```
kind         : skeleton summon from bones and corpses
axes         : delivery:heavy role:summoner mobility:ground trait:summoned
               species:zombieman
tier(s)      : T12 White (CommonWhiteZombie1) — but its EFFECT lands on
               EVERY tier of EVERY family on the map (see behaviour)
chp source   : CHP/DECORATE/01/01_W.txt:18      (Scripted — the map-wide mark)
               CHP/DECORATE/01/01_W.txt:6608    (BoneProjZM_C Death, fail 250)
               CHP/DECORATE/01/01_W.txt:7126    (ShoveZM_C Death, fail 128)
               CHP/DECORATE/01/01_W.txt:8930-8961 (WhiteZombiePlan_C — the
                   corpse hatch, ACS-gated)
               CHP/DECORATE/01/01_W.txt:9430-9433 (CHWhitePlan — the token)
               skeleton : CHP/DECORATE/01/01_W.txt:2980-3060 (MrBones_C)
               the feed : CHP/DECORATE/01/01_W.txt:3027-3029 (MrBones_C Death)
               every tier's hook: 01_C.txt:34, 01_G.txt:46, 01_B.txt:39,
                   01_P.txt:50, 01_Y.txt:66, 01_A.txt:48, 01_F.txt:45,
                   01_BR.txt:86, 01_GY.txt:43, 01_R.txt:49
acs          : CHSett2.acs:74-77 "CH_WZPlan" — a CVar read that gates the
               corpse hatch. NOT cosmetic. See the README's ACS section.
fires        : three independent spawn paths for MrBones_C:
                 1. a bone projectile dies      -> failchance 250 (~2.3%)
                 2. a shovel blade dies         -> failchance 128 (50%)
                 3. ANY marked monster dies     -> WhiteZombiePlan_C, gated
                    by CVar CH_WZPlan: 1 = always, 2 = 85/256, 3 = never
damage       : MrBones_C melee A_CustomMeleeAttack(random(1,6)*4, "swordhit",
               none)  = 4/8/12/16/20/24  [01_W.txt:3014]
               Health 50, Speed 12, PainChance 180, GibHealth -60
sprites      : SKLT R (idle) / SKLT ABCDEF (walk) / SKLT GHIJK (attack) /
               SKLT L (pain) / SKLT MNOPQ (death, then a 450-tic CanRaise)
sounds       : A_playsound("skelatt") on the swing
behaviour    : THE UNDERTAKER'S REAL MECHANIC, AND IT IS A FEEDBACK LOOP.
               On spawn it does A_Radiusgive("CHWhitePlan", 16383,
               RGF_NOSIGHT|RGF_MONSTERS) — it marks EVERY MONSTER ON THE MAP,
               through walls, out to 16383 units. From that moment every
               marked monster's Death state diverts through Tickles, which
               spawns a WhiteZombiePlan_C on the corpse, which asks the CVar
               and then hatches a skeleton out of the body.
               Its own bones and shovel blades also leave skeletons where
               they land.
               And then the loop closes: when a MrBones DIES it does
                   A_Radiusgive("Health",   528, RGF_MONSTERS, random(12,128),
                       "CommonWhiteZombie1")
                   A_Radiusgive("BoneUp2_C",528, RGF_MONSTERS, 1, "...")
                   A_Radiusgive("BoneUp",   528, RGF_MONSTERS, 1, "...")
               — KILLING ITS SKELETONS HEALS IT AND LEVELS IT UP. BoneUp 5, 9
               and 12 are the Buff1/Buff2/Buff3 thresholds (01_W.txt:24-26)
               that raise its speed, scale, missile rate, bone grade, and
               finally unlock FinalForm and the tornado. Skeletons that are
               left alone stay alive for 450 tics and can raise themselves
               twice, and on the third they turn into a REVENANT
               (01_W.txt:3030 CanRaise, :3047-3050 Raise, :3052-3060
               Revenante).
               So: you must kill the skeletons or be swarmed, and killing them
               is what makes the boss stronger. That tension is the fight.
profile      : RS_AttackProfile.MakeSummon("RS_MrBones", 1, 8, 0, "",
                   "skeleton hatch")
               // count 1 per trigger; cap is a judgement call — CHP has NO
               // cap at all, which is why the fight escalates.
notes        : THIS IS THE MOST IMPORTANT ENTRY IN THE DOCUMENT and it is
               entirely absent from the current RS tree. Detail in the
               README's GAPS section.
               CHP's per-tier hook is inconsistent: T00/T01/T02/T07/T08/T09
               test `A_JumpIfInventory("CHWhitePlan", 0, ...)` and
               T04/T05/T06/T10 test amount `1`. With Inventory.MaxAmount 1
               (01_W.txt:9430-9433) amount-0 means "has the maximum", so both
               forms behave the same here. Quoting it because a reader will
               otherwise assume one of the two is a typo and "fix" it.
               T03 Cyan and T11/T12/TEX have NO hook — cyan shatters
               (01_CY.txt:39-57) and the three boss tiers do not divert.
```

---

## COUNTS

| | |
|---|---|
| tiers documented | 14 (T00-T12 + TEX-K). TEX-W does not exist — see README. |
| distinct attacks | 30 |
| ACS scripts opened and read | 6 |
| projectile / effect actors opened | 21 |
