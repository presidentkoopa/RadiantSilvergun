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

# CACODEMON FAMILY -- ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Field order and shape
vocabulary are that spec's, unaltered. Paths are repo-relative to
`E:\RS_Main\`.

## DENOMINATOR -- WHAT WAS ACTUALLY READ

| | |
|---|---|
| Source files | `zscript/monsters/cacodemon/RS_Cacodemon.zs` (2312 lines, read whole) `zscript/monsters/cacodemon/RS_CacodemonFX.zs` (2153 lines, read whole) |
| Classes in the monster file | **23** -- 8 cvar-gate spawn stubs (no attacks) + **15 monster bodies** |
| Classes in the FX file | **65** |
| State labels, comments stripped | **353** (218 monster file + 135 FX file) |
| Direct attack call sites, comments stripped | **223** -- `A_CustomMissile` 199, `A_VileTarget` 6, `A_CustomMeleeAttack` 5, `A_CustomComboAttack` 4, `A_MeleeAttack` 2, `A_SkullAttack` 3, `A_CustomBulletAttack` 2, `A_CustomRailgun` 1, `A_PainAttack` 1 |
| Indirect damage sites | `A_Explode` 49, `A_RadiusGive` 9 (all in the FX file except the 8 ally-heal/buff pulses in the monster file) |
| Distinct classes named by an attack call | **40** |
| Monsters catalogued | **15 / 15** |
| Attacking non-monster actors also catalogued | **8** (minions, summons and payloads that themselves attack) |
| **Attack rows written** | **69** |

Ground truth cross-check: every attack state of all 15 monsters was diffed
against CH's own `decorate/Cacodemons.txt` (3876 lines). **They agree
everywhere.** See UNRESOLVED item 1 for where CH actually lives on this
machine, which is not the path the spec names.

### A note on the two shape calls this family forced

1. **`RAIN` is target-centred and I used it only for target-centred spawns.**
   `A_VileTarget` puts the spawner at the *target's* feet -- that is RAIN.
   The many CH attacks that scatter hazards around the **caster** (Yellow's
   void fields, both black bosses' death storms, the White boss's rising
   eyes) are *not* RAIN by the spec's wording, so they are `UNCLASSIFIED`
   with a full description.

   **14 rows are UNCLASSIFIED, and they are FIVE distinct kinds, not one.**
   Counted so the composer can decide what deserves a word and what does
   not -- I coined none of them:

   | kind | rows | which |
   |---|---|---|
   | self-centred area spawn | 5 | Yellow.VoidField, BlackCaco2.Death, BlackCacoEX.Death, WhiteCacoREAL.Bloody, WhiteCacoREAL.Portal |
   | radial ally heal / buff | 3 | BrownCaco2.HealAndBuff, AbyssCaco2.Missile (prologue), AbyssCaco2.Pain |
   | summon | 3 | BlackCaco2.Phase2Jumps, BlackCacoEX.Phase2Jumps, SummonPortalCybie.Missile |
   | permanent self-buff | 1 | RedCaco.ThatsIt |
   | persistent hazard entity | 2 | VoidField.Spawn, HadesBolt.Spawn |

   The middle three kinds all HAVE a factory (`MakeSummon`, `MakeRadial`,
   `MakeSelfBuff`) but no *shape word* -- that is a gap in the vocabulary,
   not in the code.
2. Angle discipline: fixed stepped angles = `FAN`; per-shot `random(...)` /
   `randompick(...)` angles = `SCATTER`; identical angle spaced in time =
   `BURST`.

---

## THREE FINDINGS THAT CHANGE HOW ROWS READ

**(a) Eight FX classes derive from vanilla `CacodemonBall`.** They are
`RS_HadesBall`, `RS_HadesBall2`, `RS_HadesBall3`, `RS_HadesBolt`,
`RS_HadesBolt2`, `RS_HadesBallEX2`, `RS_HadesBallEX3`, `RS_HadesBallEX4`
(`RS_CacodemonFX.zs:1120, 1159, 1302, 1553, 1588, 1692, 1717, 1765`).
Each one **overrides both `Spawn` and `Death`**, so their flight visuals
and their impact are written in our file, NOT inherited. What IS from the
engine actor and appears nowhere in our source: `Radius 6`, `Height 8`,
`+RANDOMIZE`, `RenderStyle "Add"`, `FastSpeed 20`, and -- where the child
does not override it -- `Damage 5`. `RS_HadesBall`, `RS_HadesBall2`,
`RS_HadesBallEX2` set no Radius/Height at all and run on the engine's 6x8.
Every one of these rows carries `inherit CacodemonBall`.

The vanilla body is legible in our own tree without leaving it:
`RS_CacodemonBall2` (`RS_CacodemonFX.zs:754`) is a verbatim copy of it,
carrying `replaces CacodemonBall`. **`replaces` does not affect subclasses** --
the eight above still inherit the engine's original.

**(b) CH passes `CMF_AIMOFFSET` (value 1) in `A_CustomMissile`'s ANGLE slot,
not its flags slot.** Eleven sites:
`A_CustomMissile("RS_HKRedDeath",100,-30,CMF_AIMOFFSET,2,-10)` resolves to
*spawnheight 100, lateral offset -30, **angle 1 degree**, flags 2
(`CMF_AIMDIRECTION`), pitch -10*. The spread on those attacks comes entirely
from the lateral offset and the pitch -- the angle is a constant 1. CH's own
text; preserved verbatim; **flagged, not corrected.** Two further sites
(`RS_SbombCaco`, `RS_CacodemonFX.zs:1012` and `:1019`) go further and pass
`random(0,360)` into the **flags** slot, scrambling the flag bits per shot.

**(c) Two `+SEEKERMISSILE` payloads never call `A_SeekerMissile` and
therefore do not home.** `RS_CacobaldBall2` (`:2117`, commented "the wonky
seeker") weaves via `A_BishopMissileWeave` / `A_CStaffMissileSlither` /
`A_SetSpeed(30)` instead; `RS_HadeExpl` (`:1617`) drops straight from Spawn
to Death. The flag is inert on both. The four that *do* home are
`RS_Cacofire3` (4,4), `RS_Cacofire4` (6,6), `RS_AbyssCacoHidi` (2,2) and
`RS_EyeRocketCaco` (11,11).

---

# TIER 13 -- RS_BrownCaco2 ("Gruelsome")

```
ATTACK   RS_BrownCaco2.Missile
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:277
shape    SINGLE
payload  RS_GrellBallBrown x1
arc      --
timing   one shot, 8 tics of wind-up (4+4) before it
damage   Damage 4   (bare constant -- the engine rolls it 4..32)
type     Melee
sound    "grell/attack"   (RS_Cacodemon.zs:273)
impact   Death: RCHB C-E flash + 3x RS_Gas14 poison cloud, each cloud
         A_Explode(random(4,8),42) on 15 frames. XDeath ADDITIONALLY runs
         A_RadiusGive("RS_GrellSlowdown",48,RGF_PLAYERS|RGF_CUBE,1) then
         falls through into Death -- a PERMANENT 0.8x PowerSpeed
         (Powerup.Duration -1) on the player. DeathSound "grell/projhit".
trigger  Missile
range    --   (but see notes: A_CheckProximity diverts at the top)
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_GrellBallBrown", fireSnd:"grell/attack", spawnHeight:32)
notes    The slow is the whole point of this projectile and it is on
         XDeath, not Death. Which of the two a projectile takes on this
         engine build is UNRESOLVED item 4.
         Missile opens with A_CheckProximity("Scatter","Cacodemon",600,1,
         CPXF_ANCESTOR|CPXF_CHECKSIGHT) (:272): with any Cacodemon-descendant
         ally in sight within 600, it diverts to Scatter, which is a 64/256
         coin flip between HealAndBuff and `Goto Missile+3`. Missile+3 is
         this same shot MINUS the "grell/attack" line -- the same attack,
         silent. Not a second row.
```

```
ATTACK   RS_BrownCaco2.HealAndBuff
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:282
shape    UNCLASSIFIED   (self-centred support burst -- see the shape note)
payload  RS_MediCacoBrown x15  +  RS_SpeedBuffPE x1  +  RS_BrownImpCommand x1
arc      full 360 on the motes (angle random(0,359))
timing   2,2,2 / 1,1,1 / 2,2,2 / 3 / 3,3,3 / 3 / 3,3,3   (~48 tics)
damage   --   THE MOTES DO NO DAMAGE AND DO NO HEALING
type     --
sound    "Caco/sight" x2 (:283, :292)
impact   RS_MediCacoBrown (RS_SpectreFX.zs:123) has NO Damage and no heal --
         it is a 4-part cosmetic sparkle that fades in ~14 tics.
trigger  Missile   (via A_CheckProximity -> Scatter -> A_Jump(64))
range    ..600 on the ally proximity check; the effects reach 1200
mirrored no
inherit  --
profile  MakeRadial(radius:1200, heal:200, hitsAllies:true, fireSnd:"Caco/sight")
         + MakeSelfBuff-style ally pulses, see notes -- ONE call cannot carry
         this row; it is three radial pulses plus a cosmetic emitter.
notes    THE REAL EFFECT IS FIVE A_RadiusGive PULSES, NOT THE MOTES:
           :286  RS_SpeedBuffPE   r1200 MONSTERS species "Caco"  -> +10 Speed
                 and +ALWAYSFAST for 300 tics (RS_SpectreFX.zs:78, non-boss)
           :287  RS_BrownImpCommand r200 MONSTERS|EXFILTER, excluding
                 RS_BrownCaco2 itself -> DamageFactor 0.5 for 300 tics plus a
                 random scatter shove (RS_ImpFX.zs:95)
           :288, :291, :294, :297  Health 200, r1200, species "Caco" -- FOUR
                 separate 200-HP pack heals in one animation
         A player-side profile wants the radial pulses; the 15 motes are the
         tell that the pulse happened.
```

---

# TIER 12 -- RS_CyanCaco2 ("FrostBaller")

```
ATTACK   RS_CyanCaco2.Missile
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:408
shape    SCATTER
payload  RS_BigIceCaco x2
arc      20   (shot 1 dead centre; shot 2 randompick(-10,10,-7,7,-5,5))
timing   3,3   (after 10 tics of wind-up; 16 tics of recovery)
damage   DamageFunction (random(8,40))
type     Ice
sound    "imp/attack"   (SeeSound on the ball, RS_CacodemonFX.zs:441)
impact   DeathSound "Ice/Hit2"; A_Scream, 15 cyan particles, 16 extra
         RS_IceCacoTrail shards flung at random(12,40) speed, then
         PUFI A-H frost puff. IN FLIGHT it sheds an RS_IceCacoTrail every
         frame (6 per loop) -- each trail shard is itself a live projectile,
         DamageFunction (random(2,16)), Ice. The trail is a damage source.
trigger  Missile (and Melee -- the labels are stacked at :403/:404)
range    --
mirrored no
inherit  --   (RS_IceCacoTrail inherits from RS_SmallIceCaco: :493)
profile  MakeBurst(proj:"RS_BigIceCaco", count:2, delayTics:3, arc:20, fireSnd:"imp/attack")
notes    `Melee:` and `Missile:` are the SAME state -- this monster has no
         melee at all, it fires ice at contact range too. A_Jump(128,"WaveIt")
         at :407 sends half of all attacks to the row below.
```

```
ATTACK   RS_CyanCaco2.WaveIt
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:413
shape    FAN
payload  RS_SmallIceCaco x7
arc      30   angles in order: randompick(-15,10), randompick(-10,5), -5, 0,
         +5, randompick(-5,10), randompick(15,-10)
timing   2,2,2,2,2,2,2   (14 tics; 16 tics of recovery)
damage   DamageFunction (random(8,21))
type     Ice
sound    "Ice/Hit2"   (SeeSound on the needle)
impact   ICEY F-G, 7 cyan particles, ICEY H-I. DeathSound "spike/spiked" is
         **PROVEN MISSING IN CH ITSELF** -- no SNDINFO entry anywhere, not
         vanilla. The impact is silent in CH too; that is not our defect.
trigger  Missile   (A_Jump(128,"WaveIt") from Missile, :407)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_SmallIceCaco", count:7, delayTics:2, arc:30, fireSnd:"Ice/Hit2")
notes    Three of the seven are fixed (-5,0,+5); four are randompick, and two
         of those picks straddle zero (randompick(-15,10) can go either way).
         The sweep reads as a wave, not a clean fan. Uniform 2-tic spacing
         means MakeBurst reproduces the timing exactly -- no rounding loss.
```

---

# TIER 9 -- RS_AbyssCaco2 ("Abyssmal Tomatoe quality")

```
ATTACK   RS_AbyssCaco2.Melee
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:513
shape    MELEE
payload  --   (plus 4x RS_Zap88, cosmetic)
arc      --
timing   5,5,5 then 1,1,1,2
damage   MeleeDamage 12   (the actor property, RS_Cacodemon.zs:464 -- flat,
         not a roll)
type     --
sound    MeleeSound "Caco/Melee"
impact   4x RS_Zap88 lightning flick at the mouth (LITN A-G,O,P, +NOINTERACTION,
         no damage), SXF_TRANSFERTRANSLATION so they take the black remap.
trigger  Melee
range    --
mirrored no
inherit  --
profile  MakeMelee(range:64, fireSnd:"Caco/Melee", dmgMult:1.0)
notes    Ends on A_Jump(88,"Missile") (:518) -- a 34% chance to chain
         straight from the bite into the ranged routine.
```

```
ATTACK   RS_AbyssCaco2.Missile   (the buff prologue)
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:522
shape    UNCLASSIFIED   (radial ally buff, no projectile)
payload  RS_SpeedBuffPE x1
arc      --
timing   1 tic
damage   --
type     --
sound    --   SILENT. A pure buff pulse with no cue at all.
impact   A_RadiusGive("RS_SpeedBuffPE",800,RGF_MONSTERS,1,null,"Caco") --
         every Caco-species monster within 800 gets +10 Speed and
         +ALWAYSFAST for 300 tics.
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeRadial(radius:800, heal:0, hitsAllies:true)
notes    This runs on the FIRST tic of EVERY ranged attack, before the
         range check picks Spam or Hidious. It is not optional and it is
         not gated -- the abyss caco speeds up its whole pack every time it
         decides to shoot.
```

```
ATTACK   RS_AbyssCaco2.Spam
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:532
shape    FAN
payload  RS_AbyssCacoBalls x32
arc      26 core (-13..+13), plus a lateral-offset tail
timing   phase 1: 0,0,5 | phase 2: 1x9 | phase 3: 1x9 | phase 4: 0x10 then 5
         (three A_CheckSight("See") breaks of 5 tics between phases)
damage   DamageFunction (random(5,55))
type     Ice
sound    "Crack/see"   (SeeSound on the ball; 32 of them, one per shot)
impact   DeathSound "Crack/death". Death spawns **9x RS_AbyssCacoZap2**
         scattered +/-32,+/-16 -- each is a 9-frame
         A_Explode(random(1,4),64) crawler, so one ball landing is up to 36
         radius pulses. Then A_KillChildren("extreme",KILS_FOILINVUL|
         KILS_KILLMISSILES). IN FLIGHT each ball carries an
         **RS_AbyssCacoZap** orbiting it (spawned at :555 with
         SXF_SETMASTER|SXF_ORIGINATOR, A_Warp'd to the master every 2 tics)
         which is +RIPPER, DamageFunction (random(1,5)), Plasma. The escort
         is a damage source with no travel of its own.
trigger  Missile
range    ..1000   (A_JumpIfCloser(1000,"Choice") at :523; Choice is a 50/50
         A_Jump(255,"Spam","Hidious") at :526. Beyond 1000 it is ALWAYS
         Hidious.)
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_AbyssCacoBalls", count:32, arc:26, fireSnd:"Crack/see")
         -- then p.MaxRange = 1000
notes    FOUR PHASES, one row, because a player reads it as one attack:
           :532-534  3 balls, angles 0 / -13 / +13
           :539-547  9 balls, -13,-10,-7,-4,-1,+2,+5,+8,+11  (1 tic apart)
           :552-560  9 balls, +13,+10,+7,+4,+1,-2,-5,-8,-11  (the sweep back)
           :565      5 balls, angle 0, LATERAL OFFSET random(-23,1)
           :566      5 balls, offset 0, angle random(-1,23)
           :567      1 ball, dead centre
         Every call passes flags=1 (CMF_AIMOFFSET) -- here that is the
         correct slot, unlike finding (b).
         The three A_CheckSight("See") breaks abort the barrage if the
         target breaks line of sight; a weapon profile has no analogue and
         should just fire all 32.
```

```
ATTACK   RS_AbyssCaco2.Hidious
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:574
shape    SINGLE
payload  RS_AbyssCacoHidi x1
arc      --
timing   1 shot after 29 tics of charge (1+12+16), 10 tics recovery
damage   DamageFunction (random(30,95))
type     Plasma
sound    "caco/sight" at ATTN_NONE, channel 7, volume 2 (:570) -- a
         MAP-WIDE roar, plus the flame's own SeeSound "weapons/bigbrn"
impact   DeathSound "weapons/bigbrn". Death: 9 RS_AbyssCacoZap2, A_SetScale
         1.5, then FRFX H-J A_Explode(random(4,10),88) per frame, FRFX K-M
         A_Explode(random(4,12),128) per frame, 18 more zaps. Roughly
         6 radius pulses up to r128 plus 27 crawling zaps.
trigger  Missile
range    1000..   (the default branch; also 50/50 inside 1000)
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_AbyssCacoHidi", fireSnd:"caco/sight", spawnHeight:24)
notes    HOMES. A_SeekerMissile(2,2) on two of four flight frames, with
         A_Weave(3,1,5,0) on the other two -- it snakes toward you at
         Speed 55. Sheds 3x RS_AbyssCacoZap2 per frame in flight, so the
         trail is itself damaging.
         Charge tell: 4x RS_Zap88 at the eye over 16 tics (:572).
```

```
ATTACK   RS_AbyssCaco2.Pain
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:582
shape    UNCLASSIFIED   (radial ally heal, no projectile)
payload  --
arc      --
timing   3 tics
damage   --
type     --
sound    --   SILENT.
impact   A_RadiusGive("Health",800,RGF_MONSTERS,200,null,"Caco") -- 200 HP
         to every Caco-species monster within 800, on every pain state.
trigger  Pain
range    --
mirrored no
inherit  --
profile  MakeRadial(radius:800, heal:200, hitsAllies:true)  -- trigger RS_FIRE_PAIN
notes    Followed by 8 tics of A_Wander. Shooting an abyss caco inside a
         caco pack heals the pack; that is the intended pressure.
         Its Death (:588) spawns 26x RS_SplashAbyss + 4x
         RS_SplashAbyssBubbleDemon -- **RS_SplashAbyss has NO Damage
         property** (RS_ZombiemanFX.zs:706); only its sibling
         RS_SplashAbyss2 does. The abyss death spray is pure cosmetics.
         No death row.
```

---

# TIER 8 -- RS_GrayCaco2 ("Stone Cold Cacodemon")

```
ATTACK   RS_GrayCaco2.Rusher1
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:666
shape    CHARGE
payload  --   (the monster IS the projectile)
arc      --
timing   2 tics of commit
damage   Damage 5   (the ACTOR's Damage, :627 -- A_SkullAttack's contact
         damage is `Damage * random(1,8)`, so 5..40)
type     --
sound    --   A_SkullAttack(50) is given no sound argument, and this class
         has no AttackSound. SILENT LUNGE.
impact   Contact only. No puff, no explosion.
trigger  Missile   (A_JumpIfCloser(900,"Rusher1") at :659)
range    ..900   AND user_nodash3 < 13
mirrored no
inherit  Cacodemon   (this class extends the engine actor, :609)
profile  MakeHeavy(proj:null, ...) has no charge mode -- NO FACTORY COVERS
         THIS. Closest usable stand-in: MakeMelee(range:900, dmgMult:1.0)
         with a forward lunge. Flagged in UNRESOLVED item 6.
notes    A_SkullAttack(50) = lunge at speed 50 (Gray's walk Speed is 9, so
         this is a 5.5x dash). Falls through to Melee on arrival.
         DASH BUDGET: user_nodash3 starts 0; Rusher1 adds +5 on entry
         (:665), Woosh subtracts -2 (:675), Missile subtracts -5 on the
         far branch (:660). At >=13 (three dashes without a cooldown) it
         is forced to Woosh instead. The budget is a soft cooldown, not
         a timer.
```

```
ATTACK   RS_GrayCaco2.Woosh
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:670
shape    SCATTER
payload  RS_CacoRockBreath x5
arc      widening: random(-1,1), random(-3,3), random(-5,5), random(-8,8),
         random(-11,11) -- 2 -> 22 degrees
timing   5,4,3,2,1   (15 tics, ACCELERATING)
damage   DamageFunction (random(15,50))
type     Melee   (INHERITED from RS_WDRock3)
sound    "monster/hamflr"  (SeeSound, INHERITED from RS_WDRock3)
impact   INHERITED WHOLE from RS_WDRock3 (RS_ZombiemanFX.zs:680):
         DeathSound "Butcher/melee", JUBD A-D flight, Death spawns 4x
         RS_Drt2 + 4x RS_Drt3 dirt puffs. RS_CacoRockBreath's own body
         (RS_CacodemonFX.zs:676) is FOUR LINES -- it overrides
         DamageFunction and nothing else. Read the child alone and you
         report "no impact FX" for an attack that has one.
trigger  Missile   (A_Jump(255,"Woosh") at :661, or forced from Rusher1
         when the dash budget is spent)
range    900..     (the far branch) -- also reachable at any range when
         user_nodash3 >= 13
mirrored no
inherit  RS_WDRock3   (parent's damage was random(15,65); the child cuts it
         to random(15,50))
profile  MakeBurst(proj:"RS_CacoRockBreath", count:5, delayTics:3, arc:22, fireSnd:"monster/hamflr")
notes    The accelerating cadence 5,4,3,2,1 has no exact form --
         BurstDelayTics is uniform. 3 tics = 15 total, which happens to
         match CH's 15 exactly, but the RAMP is lost. Recorded, not
         silently smoothed.
```

```
ATTACK   RS_GrayCaco2.Melee
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:680
shape    MELEE
payload  --
arc      --
timing   7 tics (after 16 of wind-up), then A_Stop
damage   random(5,50)   (the A_CustomMeleeAttack argument)
type     --   (defaults to Normal)
sound    "bite/bite4"
impact   --
trigger  Melee   (also fallen into from Rusher1, :667)
range    --
mirrored no
inherit  Cacodemon
profile  MakeMelee(range:64, fireSnd:"bite/bite4")
notes    A_Stop then A_CheckSight("See") then `Goto Rusher1` -- if it can
         still see you it immediately tries to dash again, which is what
         makes this monster feel like it never stops moving.
```

```
ATTACK   RS_GrayCaco2.Death
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:707
shape    RING
payload  RS_WDRock4 x20
arc      360   (angle random(-359,359) -- the tell)
timing   one tic, all 20 together
damage   DamageFunction (random(5,20))
type     Melee
sound    "monster/hamflr" x20 (SeeSound per pebble) then A_XScream
impact   DeathSound "Butcher/melee"; Death spawns 2x RS_Drt3 dirt.
trigger  Death
range    --
mirrored no
inherit  --   (RS_WDRock4 is RS_DemonFX.zs:879, a standalone class)
profile  MakeVolley(proj:"RS_WDRock4", count:20, arc:360, fireSnd:"monster/hamflr")
         -- trigger RS_FIRE_DEATH
notes    Fired on the FIRST line of Death, before A_XScream. The stone caco
         shatters into 20 pebbles at Speed 42 in every direction. This is
         the only genuine 360 death burst in the family and the cleanest
         RING in it.
```

---

# TIER 7 -- RS_FireBluCaco2 ("One Ugly Tomatoe")

```
ATTACK   RS_FireBluCaco2.Missile
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:776
shape    SINGLE
payload  RS_FireBluCacoBall x1
arc      --   (single shot, jittered random(-5,5))
timing   one shot after 10 tics of wind-up, 5-tic hold
damage   DamageFunction (random(5,40))
type     Plasma
sound    "imp/attack"   (SeeSound on the ball)
impact   DeathSound "imp/shotx"; Death is BAL1 C-E with
         A_Explode(random(5,15),128) ON EVERY FRAME -- three r128 blasts,
         not one.
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_FireBluCacoBall", fireSnd:"imp/attack", spawnHeight:32,
                   explosionVisual:null)
notes    THE FLIGHT IS THE ATTACK. RS_FireBluCacoBall (RS_CacodemonFX.zs:684)
         is +BOUNCEONWALLS, BounceType "Hexen", BounceCount 4,
         WallBounceFactor 0.9, BounceSound "Bomb/bounce" -- it ricochets
         four times before it dies. Every 8-tic flight cycle it rolls
         A_Jump(32,"WOM") (12.5%): WOM stops it dead, turns it
         random(-60,60) degrees and re-thrusts it at 8. It wanders.
         It also sheds an **RS_FireBluCacoBall2** every frame in flight --
         a lingering fire pool, DamageFunction (random(5,23)), Fire, whose
         Death is ELEVEN frames of A_Explode(random(3,10),64). One ball's
         flight lays a burning trail; that trail is most of its damage.
```

---

# TIER 1 -- RS_CommonCaco ("Cacodemon")

```
ATTACK   RS_CommonCaco.Missile
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:867
shape    COMBO
payload  MELEE HALF: no class, damage 10 * random(1,6)  ==  10/20/30/40/50/60
         MISSILE HALF: "CacodemonBall" x1
arc      --
timing   one call, 5-tic frame, after 10 tics of wind-up
damage   melee 10 * random(1,6)  |  missile Damage 5 (bare -- engine rolls
         5..40) on the ball
type     melee Normal  |  missile Plasma
sound    melee "Bite/bite4" (the A_CustomComboAttack argument)  |  missile
         "caco/attack" (the ball's SeeSound)
impact   missile: DeathSound "caco/shotx", BAL2 C-E pop, no explosion, no
         spawns. melee: nothing.
trigger  Missile
range    ..MeleeRange for the melee half; beyond it, the missile half.
         MeleeThreshold 80 (:845) additionally BLOCKS the whole Missile
         state inside 80 units -- see notes.
mirrored no
inherit  Cacodemon (the monster) / CacodemonBall (the payload)
profile  RECORD AS TWO SLOTS -- no single factory is a combo:
           MakeMelee(range:64, fireSnd:"Bite/bite4")        // dmg 10*random(1,6)
           MakeHeavy(proj:"RS_CacodemonBall2", fireSnd:"caco/attack",
                     spawnHeight:32)
notes    BOTH HALVES ARE DIFFERENT THINGS AND BOTH MATTER. The melee roll
         10 * random(1,6) is a 10-step ladder, not a flat spread -- do NOT
         write it as random(10,60).
         THE PAYLOAD SWAPS AT SPAWN. The call names the vanilla
         "CacodemonBall", but RS_CacodemonBall2 carries
         `replaces CacodemonBall` (RS_CacodemonFX.zs:754), so what actually
         flies is RS_CacodemonBall2. Its body is a verbatim copy of the
         vanilla actor, so nothing changes numerically -- but a profile
         should name RS_CacodemonBall2, not "CacodemonBall".
         MeleeThreshold 80: the engine refuses a missile attack when the
         target is nearer than 80. This class defines NO Melee state, so
         inside 80 units it has no attack at all and simply chases.
         This is CH's own text (Cacodemons.txt:1127), not an import slip.
```

---

# TIER 2 -- RS_GreenCaco ("Green Cacodemon")

```
ATTACK   RS_GreenCaco.Missile
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:980
shape    SINGLE
payload  RS_Cacospit1 x1
arc      --   (jitter random(-1,1))
timing   one shot after 10 tics of wind-up
damage   DamageFunction (random(10,45))
type     Plasma
sound    "baron/attack"   (SeeSound on the spit)
impact   DeathSound "baron/shotx", BAL7 C-E, Decal "BaronScorch". No
         explosion. In flight it sheds RS_Trail12 each frame (cosmetic,
         no Damage -- RS_ChaingunnerFX.zs:111).
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_Cacospit1", fireSnd:"baron/attack", spawnHeight:32)
notes    Speed 17 / FastSpeed 20, +RANDOMIZE. It is a baron shot wearing a
         caco's animation -- the sounds and the decal are baron's.
```

```
ATTACK   RS_GreenCaco.Melee
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:985
shape    MELEE
payload  --
arc      --
timing   7 tics after 16 of wind-up
damage   random(5,50)
type     --
sound    "bite/bite4"
impact   --
trigger  Melee
range    --
mirrored no
inherit  Cacodemon
profile  MakeMelee(range:64, fireSnd:"bite/bite4")
notes    The identical bite -- random(5,50) / "bite/bite4" -- appears on
         Green (:985), Blue (:1083), Purple (:1226) and Gray (:680). One
         profile serves all four.
```

---

# TIER 3 -- RS_BlueCaco ("Blue Cacodemon")

```
ATTACK   RS_BlueCaco.Missile
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1075
shape    SCATTER
payload  RS_CacoFire2 x4
arc      10   angles random(-1,1), random(-3,3), random(-5,5), random(-4,4)
timing   7,5,4,2   (18 tics, accelerating then easing)
damage   DamageFunction (random(6,35))
type     Plasma
sound    "holy3/holy3"   (SeeSound, one per shot)
impact   DeathSound "holy2/holy2"; Death is a four-beat pulse that rescales
         0.5 / 0.7 / 0.5 / 1.0 over 24 tics -- a throbbing holy flash, not
         a pop. No explosion, no spawns.
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_CacoFire2", count:4, delayTics:5, arc:10, fireSnd:"holy3/holy3")
notes    Arc WIDENS then narrows again on the fourth shot (5 -> 4). Not a
         clean cone. delayTics 5 gives 20 tics against CH's 18; recorded,
         not rounded away.
         The Blue caco is the family's only genuinely "holy" sounding
         monster -- both sounds come from the Heretic/Hexen holy set.
```

```
ATTACK   RS_BlueCaco.Melee
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1083
shape    MELEE
payload  --
arc      --
timing   7 tics after 16 of wind-up
damage   random(5,50)
type     --
sound    "bite/bite4"
impact   --
trigger  Melee
range    --
mirrored no
inherit  Cacodemon
profile  MakeMelee(range:64, fireSnd:"bite/bite4")
notes    Identical to Green/Purple/Gray. See RS_GreenCaco.Melee.
```

---

# TIER 4 -- RS_PurpleCaco ("Purple Cacodemon")

```
ATTACK   RS_PurpleCaco.Rusher1
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1214
shape    CHARGE
payload  --
arc      --
timing   2 tics of commit
damage   Damage 3   (the ACTOR's Damage, :1160 -- A_SkullAttack contact is
         Damage * random(1,8), so 3..24)
type     --
sound    --   SILENT LUNGE (no argument, no AttackSound).
impact   Contact only.
trigger  Missile   (A_JumpIfCloser(300,"Rusher1") at :1191)
range    ..300   AND user_nodash3 < 11
mirrored no
inherit  Cacodemon
profile  no charge factory -- see RS_GrayCaco2.Rusher1 and UNRESOLVED item 6
notes    A_SkullAttack(25) against a walk Speed of 11 -- a 2.3x dash, much
         tamer than Gray's 5.5x, and it only triggers inside 300 (Gray's
         gate is 900). Budget: +5 on entry (:1213), -2 in Woosh (:1221),
         -3 on the far branch of Missile (:1192), ceiling 11.
         Falls through to Melee on arrival.
```

```
ATTACK   RS_PurpleCaco.Woosh
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1218
shape    MULTI
payload  RS_Cacofire3 x1  +  RS_Cacofire4 x2
arc      big shot random(-1,1); the two escorts at fixed +8 and -8
timing   5,0,0 -- the escorts leave on the SAME tic as each other,
         5 tics after the big one
damage   RS_Cacofire3 DamageFunction (random(10,50))
         RS_Cacofire4 DamageFunction (random(5,25))
type     Fire (both)
sound    "caco/attack" (SeeSound on both classes -- fires three times)
impact   RS_Cacofire3: DeathSound "caco/shotx". Death rolls
         A_Jump(32,"Oh") (12.5%): the normal path is a plain BAL2 C-E pop,
         but "Oh" is a GROWING TRIPLE BLAST --
         A_Explode(random(8,32),64) x2 at scale 1.3, then
         A_Explode(random(12,44),82) x2 at 1.6, then
         A_Explode(random(16,64),112) x2 at 2.0. One shot in eight detonates
         for up to 128 damage in a r112 sphere.
         RS_Cacofire4: DeathSound "caco/shotx", plain BAL2 C-E pop.
trigger  Missile   (A_Jump(255,"Woosh") at :1193)
range    300..     (or any range once the dash budget is spent)
mirrored no
inherit  --
profile  TWO SLOTS in one attack:
           MakeHeavy(proj:"RS_Cacofire3", fireSnd:"caco/attack", spawnHeight:32)
           MakeVolley(proj:"RS_Cacofire4", count:2, arc:16, fireSnd:"caco/attack")
notes    ALL THREE HOME. RS_Cacofire3 runs A_SeekerMissile(4,4) and
         RS_Cacofire4 A_SeekerMissile(6,6) -- the small escorts turn HARDER
         than the big one. Speeds 15/28 and 16/29 (Speed/FastSpeed).
         The 1-in-8 "Oh" detonation is the sharpest hidden number in this
         family: nothing at the call site suggests the shot might blow up.
```

```
ATTACK   RS_PurpleCaco.Melee
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1226
shape    MELEE
payload  --
arc      --
timing   7 tics after 16 of wind-up
damage   random(5,50)
type     --
sound    "bite/bite4"
impact   --
trigger  Melee
range    --
mirrored no
inherit  Cacodemon
profile  MakeMelee(range:64, fireSnd:"bite/bite4")
notes    Identical to Green/Blue/Gray.
```

---

# TIER 5 -- RS_YellowCaco ("Yellow Cacolich")

```
ATTACK   RS_YellowCaco.VoidField
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1370
shape    UNCLASSIFIED   (self-centred hazard placement -- see the shape note)
payload  RS_VoidField x5
arc      --   (offsets, not angles: +/-180, +/-280 x2, +/-380 x2 in X and Y;
         z random(1,32) / random(-16,32) x2 / random(-32,32) x2)
timing   6 tics for the first, then 4 more on the SAME tic (0,0,0,0)
damage   Damage 0 on the field itself; ALL its damage is
         A_Explode(5,64) once per 5-tic Spawn cycle
type     DIMp
sound    "spell/spellcast1"   (SeeSound on each field, x5)
impact   DeathSound "spell/Impact1". The field is Health 6666, +INVULNERABLE,
         +REFLECTIVE, -SOLID, Speed 0, Radius 46, Height 46, Scale 1.5. Its
         Spawn loop pulses scale 1.5/1.3/1.0 and rolls A_Jump(2,"Death")
         each cycle -- 2/256 per 5 tics, so it lives ~11 seconds on average.
trigger  Missile   (A_JumpIf(user_VoidField == 0,"VoidField") at :1337 --
         the FIRST ranged action after every Pain)
range    --   (the fields land 180-380 units from the LICH, not from you)
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_VoidField", count:5, cap:5, tierOffset:0,
                    fireSnd:"spell/spellcast1")
         -- the fields are stationary hazards, so Summon models them better
            than any volley call
notes    DIMp IS AN ANTI-PLAYER DAMAGE TYPE. Every monster in this family
         carries `DamageFactor "DIMp", 0` and `PainChance "DIMp", 0` -- the
         void fields cannot hurt any of them. They exist only to deny the
         player ground.
         Counter quirk preserved from CH: `CALI FE 6 { user_VoidField++ }`
         at :1375 is TWO frames, so the action fires TWICE -- the counter
         goes 0 -> 2, not 0 -> 1. Only `== 0` is ever tested, so it is
         harmless, and it is CH's own. Then `Goto Missile` re-rolls the
         branch immediately, so the field drop is always followed by a real
         attack in the same breath.
         Pain (:1381) flips the counter back with
         `user_VoidField = (user_VoidField == 0) ? 1 : 0`, so a lich that
         is being hurt alternates fields and flame.
```

```
ATTACK   RS_YellowCaco.SpitFlame
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1343
shape    SINGLE
payload  RS_SpitFireCaco x1
arc      --   (jitter random(-3,3))
timing   one shot after 24 tics of wind-up; 18 tics of recovery, then a
         refire roll
damage   DamageFunction (random(10,65))
type     Fire
sound    "CacoFlame/Attack"   (SeeSound on the flame)
impact   DeathSound "Fire/fire5". Death: BBOM A-C at scale 0.6, then BBOM
         D-G with A_Explode(random(5,15),64) ON EVERY FRAME -- four r64
         blasts.
trigger  Missile   (A_JumpIfCloser(1000,"SpitFlame") at :1338)
range    ..1000
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_SpitFireCaco", fireSnd:"CacoFlame/Attack", spawnHeight:35)
         -- then p.MaxRange = 1000
notes    BOUNCES. +BOUNCEONWALLS, BounceType "Doom", BounceCount 8,
         WallBounceFactor 0.8. Eight wall bounces at Speed 20 in a corridor
         is a long-lived hazard. Also +VISIBILITYPULSE.
         REFIRE LOOP: A_JumpIfTargetInLOS("RefireYes") (:1345) then
         A_Jump(176,"SpitFlame") (:1348) -- 69% chance to fire again while
         you stay in sight. Expected burst is ~3 shots. That is the row's
         real cadence and no factory field carries it.
```

```
ATTACK   RS_YellowCaco.Melee
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1365
shape    MELEE
payload  --
arc      --
timing   6 tics after 14 of wind-up, 6 of recovery
damage   random(5,64)
type     --
sound    "bite/bite4"
impact   --
trigger  Melee
range    --
mirrored no
inherit  Cacodemon
profile  MakeMelee(range:64, fireSnd:"bite/bite4", dmgMult:1.0)
notes    random(5,64), NOT the random(5,50) the other four use. The lich
         bites harder. Do not fold this row into the shared bite profile.
         NOT AN ATTACK, recorded so nobody hunts for one: `SeekAndKill`
         (:1350) is the >1000 branch and fires NOTHING -- it drops alpha to
         0.3 then 0.1, sets Speed 42, and A_Wanders for ~70 tics before
         re-checking range. It is a stealth reposition.
         `Dodge1`/`Dodge2` (:1328/:1331) are ThrustThing sidesteps off Pain,
         also not attacks.
```

---

# TIER 6 -- RS_RedCaco ("Red Cacodemon")

```
ATTACK   RS_RedCaco.Melee
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1463
shape    MELEE
payload  --   (plus 4x RS_RedThingsLS, cosmetic)
arc      --
timing   5 tics after 10 of wind-up, then 1,1,1,3
damage   MeleeDamage 10   (the actor property, :1422)
type     --
sound    MeleeSound "Caco/Melee"
impact   4x RS_RedThingsLS blood flecks at the mouth -- NO Damage
         (RS_DemonFX.zs:115), Gravity 2, they fall and fade.
trigger  Melee
range    --
mirrored no
inherit  --
profile  MakeMelee(range:64, fireSnd:"Caco/Melee")
notes    Structurally the same bite as RS_AbyssCaco2.Melee (A_MeleeAttack +
         four cosmetic sprites) but 10 damage instead of 12, red flecks
         instead of lightning, and NO chain-into-Missile jump at the end.
```

```
ATTACK   RS_RedCaco.Spam
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1477
shape    FAN
payload  RS_CrackodemonBall x3
arc      16   fixed 0 / -8 / +8
timing   0,0,5   (all three effectively together, after 15 tics of wind-up)
damage   DamageFunction (random(5,55))
type     Plasma
sound    "Crack/see"   (SeeSound, one per ball)
impact   DeathSound "Crack/death", BLL9 C-E pop. No explosion, no spawns.
         In flight it sheds RS_CrackoBallTrail each frame (8 per loop,
         cosmetic -- RS_ImpFX.zs:417).
trigger  Missile   (A_Jump(255,"Spam","Sludgebomb") at :1471 -- effectively
         a 50/50, since A_Jump(255,...) picks one of the two labels)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_CrackodemonBall", count:3, arc:16, fireSnd:"Crack/see")
notes    Ends on A_Jump(128,"MoreSpam") (:1480) -- 50% chance to escalate
         straight into the nine-shot row below without returning to See.
```

```
ATTACK   RS_RedCaco.MoreSpam
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1510
shape    FAN
payload  RS_CrackodemonBall x9
arc      32   fixed +16, +12, +8, +4, 0, -4, -8, -12, -16 (a clean sweep
         from left to right, 4 degrees per step)
timing   2,2,2,2,2,2,2,2,2   (18 tics), with A_FaceTarget re-aiming between
         every pair -- the fan TRACKS you as it sweeps
damage   DamageFunction (random(5,55))
type     Plasma
sound    "Crack/see" x9
impact   as RS_RedCaco.Spam
trigger  Missile   (A_Jump(128,"MoreSpam") from Spam)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_CrackodemonBall", count:9, delayTics:2, arc:32, fireSnd:"Crack/see")
notes    The five interleaved A_FaceTarget calls (:1512, 1515, 1519, 1522)
         are the interesting part: the sweep is re-anchored to your current
         position four times mid-fan, so strafing does not simply walk you
         out of it. No profile field carries mid-volley re-aim.
         Ends A_MonsterRefire(24,"See") then `Goto Spam` -- roughly a 90%
         chance to loop back into the 3-shot fan and start the whole cycle
         again. Sustained fire, not a burst.
```

```
ATTACK   RS_RedCaco.SludgeBomb
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1488
shape    SINGLE
payload  RS_SbombCaco x1
arc      --
timing   one shot after 16 tics (12 of aim + 4 of flecks); 10-tic recovery
damage   DamageFunction (random(5,80))
type     Plasma
sound    "Spell/spellCast1"   (SeeSound on the bomb)
impact   SEE THE DEDICATED ROW BELOW -- this payload's Death is itself a
         12-projectile attack. Summary: DeathSound "Crack/death",
         A_Explode(random(5,20),88), 12x RS_CrackodemonBall, then
         A_Explode(random(5,20),99).
trigger  Missile   (A_Jump(255,"Spam","Sludgebomb") at :1471)
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_SbombCaco", fireSnd:"Spell/spellCast1", spawnHeight:24)
notes    Radius 20, Height 20, Mass 600, Scale 2 -- the biggest single
         projectile in the family and the slowest (Speed 11).
         Preceded by 4x RS_RedThingsLS at z=32 (:1484-1487) -- the same
         cosmetic flecks the bite uses, here as a charge tell.
```

```
ATTACK   RS_RedCaco.ThatsIt
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1536
shape    UNCLASSIFIED   (self-buff, no payload that damages)
payload  RS_EffectHK x1   (cosmetic shell only)
arc      --
timing   4,4,4,4,12   (28 tics, during which it is unhittable-by-pain)
damage   --
type     --
sound    "Cracko/See" (:1534)
impact   RS_EffectHK (RS_ImpFX.zs:365) has NO Damage: one CBAL frame then
         A_Burst("RS_RedThingsHK") -- a red spark shell, pure tell.
trigger  Pain
range    --
mirrored no
inherit  --
profile  MakeSelfBuff(speedMult:2.43, damageMult:1.0, duration:-1, noPain:true,
                      fireSnd:"Cracko/See")
         -- speed 14 -> 34 is 2.43x; duration is PERMANENT, see notes
notes    THE RAGE GATE. Pain increments user_Tick2 (:1531); at >=5 it
         jumps here instead (:1528) and the changes are one-way and
         permanent for the rest of the monster's life:
           +NOPAIN            -- cannot be stunlocked again, ever
           A_SetSpeed(34)     -- from 14
           +MISSILEEVENMORE   -- attacks far more often
         MakeSelfBuff's `duration` has no "forever" value documented at the
         factory; -1 here is my notation for CH's permanence, not a verified
         API value. Flagged in UNRESOLVED item 7.
         OUR TREE vs CH, deliberate and documented at the site: CH writes
         sprite `VBAL` in RS_EffectHK; our tree uses `CBAL`, fixed 2026-08-06
         on the owner's "nothing invisible" rule. VBAL does not exist; CBAL
         has the frame. Behaviour identical, visibility differs.
```

---

# TIER 10 -- RS_BlackCaco2 ("SHOCKMASTER")

Branching: `Missile` (:1662) checks `A_JumpIfHealthLower(3000,"Phase2Jumps")`,
else `A_Jump(256,"Electro1","Electro5","Electro3")`. Below 3000 HP it runs
Phase2Jumps ONCE (user_DO2 guard), thereafter `Nah` ->
`A_Jump(256,"Electro2","Electro3","Electro4","Electro5")`. So **Electro2 and
Electro4 are phase-2 only**; Electro1 and Electro5 are phase-1 only; Electro3
appears in both.

```
ATTACK   RS_BlackCaco2.Electro1
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1696
shape    FAN
payload  RS_HadesBall x5
arc      28   fixed -14, -7, 0, +7, +14
timing   one tic -- all five together (0,0,0,0,5)
damage   DamageFunction (random(5,30))
type     Plasma
sound    "Monster/hadtel"   (SeeSound, x5)
impact   DeathSound "Monster/hadsit", Decal "CacoScorch". Death is HEFX
         C,D,E,E,F,G,H -- **seven frames, each spawning an RS_HadeExpl**
         at random(+/-128, +/-128, +/-12). Each RS_HadeExpl is
         DamageFunction (random(5,10)) Fire and drops straight to a Death
         of A_Explode(random(2,10),108) / (random(2,12),124) /
         (random(2,10),138) x2 / (random(5,25),128). ONE ball landing is
         seven secondary explosions covering a 128-unit area.
trigger  Missile   (phase 1) -- also the fallthrough target of Electro4
range    --
mirrored no
inherit  CacodemonBall   (Radius 6, Height 8, +RANDOMIZE, RenderStyle "Add"
         all come from the engine actor -- see finding (a))
profile  MakeVolley(proj:"RS_HadesBall", count:5, arc:28, fireSnd:"Monster/hadtel")
notes    Speed 17, +THRUGHOST, +FORCEXYBILLBOARD, Alpha 0.80.
         The impact spread (128 units) is nearly five times the muzzle arc.
```

```
ATTACK   RS_BlackCaco2.Electro2
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1705
shape    FAN
payload  RS_HadesBolt x3   (preceded by RS_HadeLoad1 x1, non-damaging)
arc      32   fixed -16, 0, +16
timing   one tic -- all three together (0,0,5), after 12 tics of charge
damage   Damage 1   (bare constant -- the engine rolls 1..8)
type     Plasma
sound    SILENT AT THE MUZZLE. RS_HadesBolt's SeeSound is "weapons/none",
         which is **PROVEN MISSING IN CH ITSELF** -- CH's deliberate
         no-sound idiom. The only cue is RS_HadeLoad1's "Weapons/BFGF"
         charge whine 12 tics earlier.
impact   DeathSound "weapons/gntidl" -- SNDINFO maps it to lump DSGNTIDL,
         **which does not exist in CH either**. Silent both ends.
         Death: HADE F-K, six frames of A_Explode(random(5,35),64).
trigger  Missile (phase 2, via Nah) -- and Melee (:1721, see notes)
range    --
mirrored no
inherit  CacodemonBall
profile  MakeVolley(proj:"RS_HadesBolt", count:3, arc:32)
         -- fireSnd deliberately EMPTY; the gun's own sound fills it
notes    THE PAYLOAD IS THE ATTACK, AND IT IS ENORMOUS. RS_HadesBolt
         (RS_CacodemonFX.zs:1717) is +FLOORHUGGER +RIPPER +FLOORCLIP,
         BounceType "Hexen", -NOGRAVITY, Speed 5, ReactionTime 35, YScale
         4.0 / XScale 0.7 -- a tall thin ripping wall that crawls the floor.
         Its Spawn state is a 10-tic loop that A_CountDowns 35 times
         (~350 tics / 10 seconds), and EACH loop lays down:
           5x A_Explode(random(5,15),64,0)
           5x A_CustomMissile("RS_HadesBolt2",0,0,0,6,90)  -- Speed 184,
              RenderStyle "None", +RIPPER, whose Spawn is a 1-tic
              A_Explode(random(5,15),64,0) LOOP
           5x A_SpawnItemEx("RS_HadeExpl", +/-128, +/-128, rising z bands
              1-12, 12-24, 16-32, 24-42, 32-64)
           1x ThrustThing(random(0,255),1,0,0) -- it drifts randomly
         Three bolts = three of these running at once for ten seconds.
         MELEE IS NOT A MELEE: RS_BlackCaco2's Melee state (:1719) is three
         frames of A_FaceTarget then A_Jump(256,"Electro2") -- an
         unconditional redirect. This boss has no bite. Not a separate row.
```

```
ATTACK   RS_BlackCaco2.Electro3
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1715
shape    MULTI
payload  RS_EyeBeamCaco x1  +  1 hitscan bullet with puff RS_HadeAra
         (preceded by RS_HadeLoad1 x2, non-damaging charge)
arc      --   both dead centre; A_CustomBulletAttack(0,0,...) = zero spread
timing   lance and bullet on the SAME tic, after 32 tics of charge
damage   LANCE: Damage 1 bare + **+STRIFEDAMAGE** (engine multiplies by
         random(1,4)) -- so 1..4 on contact, trivial
         BULLET: random(1,5) -- also trivial
type     LANCE Plasma  |  BULLET Melee (from RS_HadeAra)
sound    "Crack/see" (lance SeeSound) + "Vile/Active" (puff SeeSound);
         the charge is "Weapons/BFGF" x2 from RS_HadeLoad1
impact   BOTH LISTED DAMAGES ARE DECOYS -- the real damage is in the puffs:
         LANCE (RS_CacodemonFX.zs:1429): Speed 178 (near-hitscan). Death is
           BLL9 C-E with A_Explode(random(2,30),34) ON EVERY FRAME. In
           flight it sheds RS_RedRevLoad3 spirals (cosmetic).
         PUFF RS_HadeAra (RS_CacodemonFX.zs:1502): +PUFFONACTORS, Scale 2.
           Its Spawn is SEVEN frames of A_Explode(random(2,26),64) and then
           **falls through to Melee** (no Stop) which is EIGHT more frames
           each spawning an RS_HadeExpl at +/-128. One "1-5 damage bullet"
           is up to 182 radius damage plus eight secondary explosions.
trigger  Missile   (both phases -- the only Electro that appears in each)
range    --
mirrored no
inherit  CacodemonBall (the lance is NOT a CacodemonBall child -- it is a
         standalone Actor; RS_HadesBall* are the eight children)
profile  TWO SLOTS:
           MakeHeavy(proj:"RS_EyeBeamCaco", fireSnd:"Crack/see", spawnHeight:32)
           MakeHitscan(fireSnd:"Vile/Active", spreadScale:0.0,
                       impactPuff:"RS_HadeAra")
notes    A row that transcribed only `damage random(1,5)` would report this
         as the boss's weakest attack. It is its strongest. This is the
         family's clearest case of the spec's "open the parent / open the
         payload" rule.
```

```
ATTACK   RS_BlackCaco2.Electro4
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1684
shape    SINGLE
payload  RS_HadesBall2 x1
arc      --
timing   one shot after 16 tics of aim, 16-tic recovery
damage   DamageFunction (random(5,50))
type     Plasma
sound    "Monster/hadtel"
impact   **IT SPAWNS A LIVE MONSTER.** DeathSound "Monster/hadsit". Death is
         HEFX C-E each spawning an RS_HadeLoad1, HEFX E-H each spawning an
         RS_HadeExpl, HADE H-A, and then at RS_CacodemonFX.zs:1612:
         `A_SpawnItemEx("RS_RedCaco",0,-64,12,0,0,0,0,SXF_SETMASTER|
         SXF_NOCHECKPOSITION)` -- every sawblade that lands hatches a
         Tier-6 Red Cacodemon (Health 830) as the boss's minion.
         In flight it sheds RS_SpiralSaw5 each frame -- itself damaging,
         A_Explode(random(2,10),88) on 5 frames (RS_ChaingunnerFX.zs:175).
trigger  Missile   (phase 2 only, via Nah)
range    --
mirrored no
inherit  CacodemonBall
profile  MakeHeavy(proj:"RS_HadesBall2", fireSnd:"Monster/hadtel", spawnHeight:24)
         -- a player-side version MUST drop the RS_RedCaco spawn or gate it,
            see notes
notes    Ends `Goto Electro1` (:1686) -- Electro4 ALWAYS chains into the
         five-ball fan. It is a two-part attack in practice.
         The monster spawn is the single most dangerous thing to port
         verbatim into a player weapon; recorded here so the decision is
         made deliberately rather than by omission.
```

```
ATTACK   RS_BlackCaco2.Electro5
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1691
shape    SINGLE
payload  RS_HadesBall3 x1   (preceded by RS_HadeLoad1 x1)
arc      --
timing   one shot after 15 tics of charge, 10-tic recovery
damage   DamageFunction (random(5,50))
type     Plasma
sound    "Monster/hadtel", after "Weapons/BFGF" charge
impact   DeathSound "Monster/hadsit". Death: HEFX C,D,E,E,F,G,H -- seven
         frames each spawning an RS_HadeExpl at +/-228 (a WIDER spread than
         RS_HadesBall's +/-128).
trigger  Missile   (phase 1, and phase 2 via Nah)
range    --
mirrored no
inherit  CacodemonBall
profile  MakeHeavy(proj:"RS_HadesBall3", fireSnd:"Monster/hadtel", spawnHeight:18)
notes    SPEED 4 -- the slowest projectile the black boss has, and that is
         the design. Its Spawn state sheds an **RS_ZapperCaco** every frame
         at a lateral offset stepping through
         -333..-256, -256..-168, -168..-88, -88..0, 0..88, 88..168,
         168..256, 256..333 -- a 666-unit-wide crackling curtain that
         crawls toward you at walking pace. Each RS_ZapperCaco is Damage 3
         plus 4 frames of A_Explode(random(2,20),32). This is an area
         denial wall, not a bolt.
```

```
ATTACK   RS_BlackCaco2.Phase2Jumps
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1675
shape    UNCLASSIFIED   (one-shot summon + self-buff)
payload  RS_RedCaco x2
arc      --   (placed at random(-128,128) in X and Y around the BOSS)
timing   12,12
damage   --
type     --
sound    "monster/helsit" (:1674)
impact   Two live Tier-6 Red Cacodemons, SXF_SETMASTER (they are its pack).
trigger  Missile   (A_JumpIfHealthLower(3000) at :1664, guarded to fire
         exactly once by user_DO2)
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_RedCaco", count:2, cap:2, tierOffset:0,
                    fireSnd:"monster/helsit")
notes    Also flips +NOPAIN on for the duration, sets +MISSILEEVENMORE
         permanently (:1677) and A_SetSpeed(20) from 16. The summon is the
         visible half; the permanent aggression buff is the real change.
```

```
ATTACK   RS_BlackCaco2.Death
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1731
shape    UNCLASSIFIED   (self-centred area detonation -- see the shape note)
payload  RS_HadeExpl x13
arc      --   (offsets random(-128,128) X/Y, random(-88,88) Z)
timing   8,8,8 | 0,0,0,0 | 8,8,8 | 8,8,8,8,8   spread over ~100 tics
damage   DamageFunction (random(5,10)) contact, plus each one's own Death:
         A_Explode(random(2,10),108), (random(2,12),124),
         (random(2,10),138) x2, (random(5,25),128)
type     Fire
sound    A_Scream ("monster/heldth"), then "caco/attack" x13 (each
         RS_HadeExpl's SeeSound)
impact   RS_HadeExpl's Spawn goes straight to Death, so it detonates where
         it lands. Five radius pulses each, up to r138.
trigger  Death
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_HadeExpl", count:13, arc:360)
         -- trigger RS_FIRE_DEATH; the arc is a placeholder, the real
            geometry is a 256x256x176 box of point detonations
notes    13 explosions x 5 pulses = 65 radius damage events over ~3
         seconds. Standing on the corpse is fatal. RS_BlackCacoEX's Death
         (:1961) is byte-identical -- one row covers both.
```

---

# TIER 10 EX -- RS_BlackCacoEX ("SHOCKMASTER RETURNS")

Same branch structure, thresholds 6500 (phase 2) and 5000 (BonusDucks).
Health 10000, Speed 21. **No Melee state at all.** Every Electro state also
sheds RS_BlackCacoEXShade afterimages (cosmetic, +NOINTERACTION, Stencil
red) -- not recorded per-row.

```
ATTACK   RS_BlackCacoEX.Electro1
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1901
shape    FAN
payload  RS_HadesBall x15
arc      28 horizontal x 8 vertical -- a 5x3 GRID
timing   one tic, all fifteen together (fourteen 0-tic frames + one 5)
damage   DamageFunction (random(5,30))
type     Plasma
sound    "Monster/hadtel" x15
impact   as RS_BlackCaco2.Electro1 -- seven RS_HadeExpl per ball. Fifteen
         balls landing is 105 secondary explosions.
trigger  Missile   (phase 1)
range    --
mirrored no
inherit  CacodemonBall
profile  MakeVolley(proj:"RS_HadesBall", count:15, arc:28, pitchJitter:4.0,
                    fireSnd:"Monster/hadtel")
notes    THE GRID IS EXACT, NOT RANDOM. Yaw {-14,-7,0,+7,+14} crossed with
         pitch {-4, 0, +4}:
           :1901-1904  yaw -14,-7,0,+7   flags 0 (pitch 0)
           :1905-1909  yaw -14,-7,0,+7,+14  CMF_OFFSETPITCH|CMF_AIMDIRECTION, pitch -4
           :1910-1914  the same five        CMF_OFFSETPITCH|CMF_AIMDIRECTION, pitch +4
           :1915       yaw +14, flags 0     -- completes the middle row
         MakeVolley's `pitchJitter` is a random jitter, not a fixed
         three-row grid, so the profile above APPROXIMATES this. The exact
         form is a wall, not a spray. Recorded, not smoothed.
         Ends A_JumpIfHealthLower(5000,"BonusDucks") (:1917).
```

```
ATTACK   RS_BlackCacoEX.Electro2
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1931
shape    MULTI
payload  RS_HadesBolt x3  +  RS_RedSpikeCacoEX x6   (plus RS_HadeLoad1 x1)
arc      bolts 32 (fixed -16, 0, +16); spikes are placed, not aimed
timing   bolts on one tic; the six spikes over 72 tics BEFORE them
         (two lines of `HELE DDD 12`, three frames each)
damage   BOLTS Damage 1 bare (1..8) | SPIKES Damage 5 bare on a Health-100
         monster
type     Plasma (bolts)
sound    bolts SILENT (see RS_BlackCaco2.Electro2); charge "Weapons/BFGF"
impact   BOLTS: the 10-second floor-crawler described under
         RS_BlackCaco2.Electro2 -- the single biggest sustained hazard in
         this family.
         SPIKES: RS_RedSpikeCacoEX (RS_CacodemonFX.zs:1218) -- see its own
         rows below. They orbit the boss at radius 176 for 90 tics, then
         hunt.
trigger  Missile   (phase 2 only, via Nah)
range    --
mirrored no
inherit  CacodemonBall (the bolts)
profile  TWO SLOTS:
           MakeSummon(summonCls:"RS_RedSpikeCacoEX", count:6, cap:6, tierOffset:0)
           MakeVolley(proj:"RS_HadesBolt", count:3, arc:32)
notes    The summon half takes 72 tics and happens FIRST -- this is a long,
         readable tell. The EX boss is the only one that pairs a summon and
         a projectile volley in a single attack state.
```

```
ATTACK   RS_BlackCacoEX.Electro3
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1946
shape    MULTI
payload  RS_EyeBeamCaco x1  +  a railgun trace  +  1 hitscan bullet with
         puff RS_HadeAra   (plus RS_HadeLoad1 x2)
arc      --   all three dead centre
timing   lance, rail and bullet on consecutive 0-tic frames after 48 tics
         of charge
damage   LANCE Damage 1 + +STRIFEDAMAGE (1..4)
         RAIL random(20,80) -- the ONLY honest damage number in the state
         BULLET random(1,5)
type     LANCE Plasma | RAIL none declared | BULLET Melee
sound    "Crack/see" (lance) + "Vile/Active" (puff). **THE RAIL IS SILENT
         BY FLAG** -- RGF_SILENT (:1947).
impact   RAIL (RS_Cacodemon.zs:1947, full call preserved):
           A_CustomRailgun(random(20,80), -20, "white","white",
             RGF_NOPIERCING|RGF_SILENT, 0, 0, "RS_BlackCacoBeam1",
             0, 0, 0, 0, 0.4, 1.0, "RS_BlackCacoBeam2", 1)
           spawnofs_xy -20; puff RS_BlackCacoBeam1 (DeathSound "NETHERDE",
           five frames of A_Explode(random(2,20),128)); spawnclass
           RS_BlackCacoBeam2 laid down the beam at 1-unit spacing --
           DamageFunction (random(10,20)) Fire, +NOCLIP, and its Fly state
           runs FOUR A_Explode(random(5,30),64,0) while pulsing scale
           1.75 -> 0.15. **A rail beam that leaves a line of expanding
           bombs behind it.**
         LANCE and PUFF as RS_BlackCaco2.Electro3.
trigger  Missile   (both phases)
range    --
mirrored no
inherit  CacodemonBall (neither the lance nor the beam classes are children
         of it -- listed here only to say so explicitly)
profile  THREE SLOTS:
           MakeHeavy(proj:"RS_EyeBeamCaco", fireSnd:"Crack/see", spawnHeight:32)
           MakeHitscan(spreadScale:0.0, impactPuff:"RS_BlackCacoBeam1")   // the rail
           MakeHitscan(fireSnd:"Vile/Active", spreadScale:0.0, impactPuff:"RS_HadeAra")
notes    The single richest attack in the family. The railgun is the only
         A_CustomRailgun in either file.
         `A_CustomRailgun`'s `spawnofs_xy` of -20 means the beam originates
         20 units to the boss's LEFT, so it does not line up with the eye.
         CH's own text.
```

```
ATTACK   RS_BlackCacoEX.Electro4
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1882
shape    FAN
payload  RS_HadesBallEX4 x3
arc      25   -- but see notes, only two of three are angles
timing   3,3,3   (after 16 tics of aim), 16-tic recovery
damage   DamageFunction (random(15,60))
type     Plasma
sound    "Monster/hadtel" x3
impact   DeathSound "Monster/hadsit". Death fires **41x RS_ZapperCacoEX** at
         velocity random(5,28) and angle random(0,359) -- a full-circle
         fountain -- then HEFX C-H each spawning an RS_HadeExpl at +/-228.
         Each RS_ZapperCacoEX is Damage 3 with SIXTEEN frames of
         A_Explode(random(2,20),32).
trigger  Missile   (phase 2 only, via Nah)
range    --
mirrored no
inherit  CacodemonBall
profile  MakeVolley(proj:"RS_HadesBallEX4", count:3, arc:25, fireSnd:"Monster/hadtel")
notes    THE THIRD SHOT IS NOT ANGLED. The three calls are
           (24, 0,   0,   0,0)   -- centre
           (24, 0,  -25,  0,0)   -- 25 degrees left
           (24, 25,  0,   0,0)   -- spawnofs_xy 25, angle 0: fired PARALLEL,
                                    25 units to the side
         So the pattern is two convergent shots plus one offset straight
         one, not a symmetric fan. CH's own text (Cacodemons.txt:2478).
         In flight each ball sheds RS_ZapperCacoEX at random(+/-66) angles
         with real velocity -- the trail spits sideways.
         Ends `Goto Electro1` -- always chains into the 15-ball grid.
```

```
ATTACK   RS_BlackCacoEX.Electro5
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1893
shape    FAN
payload  RS_HadesBallEX3 x3   (plus RS_HadeLoad1 x1)
arc      50   fixed 0, +25, -25
timing   3,3,3 after 15 tics of charge, 5-tic recovery
damage   DamageFunction (random(15,60))
type     Plasma
sound    "Monster/hadtel" x3, after "Weapons/BFGF"
impact   DeathSound "Monster/hadsit"; HEFX C-H each spawning an RS_HadeExpl
         at +/-228.
trigger  Missile   (phase 1, and phase 2 via Nah)
range    --
mirrored no
inherit  CacodemonBall
profile  MakeVolley(proj:"RS_HadesBallEX3", count:3, arc:50, fireSnd:"Monster/hadtel")
notes    THE WIDEST CURTAIN IN THE FAMILY. RS_HadesBallEX3's Spawn sheds
         RS_ZapperCaco at lateral offsets stepping through
         -1026..-528, -528..-356, -528..-128, -356..-296, -296..-188,
         -188..-88, -88..0, 0..88, 88..188, 188..296, 128..528, 526..1026
         -- a **2052-unit-wide** crackling wall per ball, three balls at
         once, moving at Speed 10. This is the EX version of Electro5's
         area denial and it is four times as wide as the non-EX
         RS_HadesBall3 (666 units).
         Ends A_JumpIfHealthLower(5000,"BonusDucks").
```

```
ATTACK   RS_BlackCacoEX.BonusDucks
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1921
shape    SINGLE
payload  RS_HadesBallEX2 x1
arc      --
timing   one shot after 6 tics of aim
damage   DamageFunction (random(25,75))   -- the highest single-projectile
         roll in the family
type     Plasma
sound    "Monster/hadtel"
impact   THE LARGEST DEATH EFFECT IN EITHER FILE. DeathSound
         "Monster/hadsit". Death (RS_CacodemonFX.zs:1322-1366): HEFX C-E
         each spawning RS_HadeLoad1, HEFX E-H each spawning RS_HadeExpl at
         +/-228, HADE H-A, then **40 consecutive 1-tic frames each
         spawning an RS_HadeExpl** at random(+/-128) with velocity
         random(8,33) at angles cycling 0/90/180/270. Forty explosions,
         each with five radius pulses, thrown outward in four directions.
trigger  Missile   (appended to Electro1/2/3/5 when HP < 5000 -- the
         boss's final-phase punctuation, fired after almost every attack)
range    --
mirrored no
inherit  CacodemonBall
profile  MakeHeavy(proj:"RS_HadesBallEX2", fireSnd:"Monster/hadtel", spawnHeight:18)
notes    Speed 18, Scale 1.5, sheds RS_SpiralSaw5 (itself damaging) in
         flight. Below 5000 HP this is appended to FOUR of the five Electro
         states, so it is not a rare finisher -- it is most of the boss's
         late output.
```

```
ATTACK   RS_BlackCacoEX.Phase2Jumps
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1869
shape    UNCLASSIFIED   (one-shot summon + self-buff)
payload  RS_RedSpikeCacoEX x7
arc      --   (all placed at the same relative offset 12,128,32)
timing   12 x 7   (84 tics -- `HELE DDD 12` then `HELE DDDD 12`)
damage   --
type     --
sound    "monster/helsit" (:1867)
impact   Seven Health-100 orbiting spike monsters, SXF_SETMASTER.
trigger  Missile   (A_JumpIfHealthLower(6500) at :1856, once via user_DO2)
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_RedSpikeCacoEX", count:7, cap:7,
                    tierOffset:0, fireSnd:"monster/helsit")
notes    Also sets +MISSILEEVENMORE permanently and A_SetSpeed(42) from 21
         -- a DOUBLING of the boss's move speed. Unlike the non-EX boss it
         does NOT clear +NOPAIN afterwards at :1875 (the non-EX does, at
         :1679) -- CH's own asymmetry, verified against
         Cacodemons.txt:2472 vs :2222. So the EX boss is stun-immune for
         the rest of the fight.
```

```
ATTACK   RS_BlackCacoEX.Death
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:1963
shape    UNCLASSIFIED   (self-centred area detonation)
payload  RS_HadeExpl x13
arc      --   (offsets random(-128,128) X/Y, random(-88,88) Z)
timing   8,8,8 | 0,0,0,0 | 8,8,8 | 8,8,8,8,8   spread over ~100 tics
damage   DamageFunction (random(5,10)) contact, plus each one's own Death:
         A_Explode(random(2,10),108), (random(2,12),124),
         (random(2,10),138) x2, (random(5,25),128)
type     Fire
sound    A_Scream ("monster/heldth"), then "caco/attack" x13
impact   RS_HadeExpl's Spawn goes straight to Death -- it detonates where
         it lands. Five radius pulses each, up to r138.
trigger  Death
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_HadeExpl", count:13, arc:360)
         -- trigger RS_FIRE_DEATH
notes    **BYTE-IDENTICAL TO RS_BlackCaco2.Death** -- same 13 spawns, same
         offsets, same frame timing, same sounds. Written out in full
         rather than cross-referenced so the row composes standalone, but
         one profile serves both bosses.
```

---

# TIER 11 PHASE 1 -- RS_WhiteCaco2 ("PLEASE NO")

`Missile` (:2038) is `A_Jump(255,"Basic","Wonky","arms")` -- an even
three-way. Each branch has a `A_JumpIfHealthLower(2500)` escalation.

```
ATTACK   RS_WhiteCaco2.Basic
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2043
shape    COMBO
payload  RS_CacobaldBall x4   (2 via combo, 2 direct)
arc      the two direct shots at random(-12,-2) and random(2,12) -- a
         SPLIT pattern that never fires down the centre
timing   combo at t=8, combo at t=14 (the two direct shots are 0-tic and
         leave with the second combo)
damage   MELEE HALF of each combo: 2   (flat, and yes, two)
         MISSILE HALF: Damage 5 bare on RS_CacobaldBall (engine 5..40)
type     Melee (the ball's own DamageType is "Melee")
sound    melee "imp/melee" (the combo argument) | missile "imp/attack"
         (SeeSound on the ball)
impact   DeathSound "imp/shotx", CEYX A-C, Decal "DoomImpScorch". No
         explosion, no spawns.
trigger  Missile
range    ..MeleeRange for the melee halves; beyond, the missile halves
mirrored no
inherit  --
profile  TWO SLOTS:
           MakeMelee(range:64, fireSnd:"imp/melee", dmgMult:0.02)  // dmg 2
           MakeVolley(proj:"RS_CacobaldBall", count:4, arc:24, fireSnd:"imp/attack")
notes    THE MELEE HALF IS 2 DAMAGE. That is not a transcription error --
         CH writes `A_CustomComboAttack("CacobaldBall",32,2,"imp/melee")` at
         Cacodemons.txt:3269, :3274 and :3279. A 5000-HP boss whose bite
         does 2. The combo exists to switch to the missile, not to bite.
         A_JumpIfHealthLower(2500,"BasicBITCH") at :2045 splits this row
         from the next.
```

```
ATTACK   RS_WhiteCaco2.BasicBitch
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2051
shape    COMBO
payload  RS_CacobaldBall x7   (6 direct + 1 via combo)
arc      3 shots from lateral offset -6 at random(-15,-2)
         3 shots from lateral offset +8 at random(2,15)
         plus the combo's centre shot -- 30 degrees of split spray
timing   all six direct shots on 0-tic frames; combo 2 tics later
damage   as Basic -- melee 2, missile Damage 5 bare
type     Melee
sound    "imp/melee" / "imp/attack"
impact   as Basic
trigger  Missile   (A_JumpIfHealthLower(2500) from Basic)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_CacobaldBall", count:7, arc:30, fireSnd:"imp/attack")
         + the combo slot from Basic
notes    Note the ASYMMETRIC lateral offsets: -6 on the left cluster, +8 on
         the right. CH's own (Cacodemons.txt:3277-3278). The right barrel
         is further out than the left.
         Ends A_Jump(64,"what") -- 25% chance to break into the decoy
         escape (see notes at the foot of this monster).
```

```
ATTACK   RS_WhiteCaco2.Wonky
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2058
shape    SCATTER
payload  RS_CacobaldBall2 x24   (10 before the health check, 14 after)
arc      30   angle bands random(-3,3), random(-9,9), random(-15,-5),
         random(5,15) -- overlapping, not stepped
timing   1,1,1 | 2,2 | 1,1,1 | 2,2 || 1,1,1,1 | 2,2 | 0,0,0,0 | 0,0,0 | 2
damage   Damage 5   (bare constant -- engine rolls 5..40)
type     Melee
sound    "imp/attack" x24
impact   DeathSound "imp/shotx", CEYX A-C, Decal "DoomImpScorch".
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_CacobaldBall2", count:24, delayTics:1, arc:30,
                   fireSnd:"imp/attack")
notes    IT DOES NOT SEEK, despite `+SEEKERMISSILE` and the source comment
         calling it "the wonky seeker" (RS_CacodemonFX.zs:2117). There is no
         A_SeekerMissile anywhere in the class. Instead its Fly state rolls
         A_Jump(255,"A1","A2","A3") once and commits to one of:
           A1  A_BishopMissileWeave        -- wide sine weave
           A2  A_CStaffMissileSlither      -- tight slither
           A3  A_SetSpeed(30)              -- straight, but 1.7x faster
         Twenty-four balls each independently picking one of three flight
         behaviours is what "wonky" actually means here. NO PROFILE FIELD
         CARRIES THIS. Flagged in UNRESOLVED item 5.
         Ten of the twenty-four are also spawned at a random HEIGHT
         random(12,48) and a random lateral offset random(-16,16), so the
         muzzle wanders too.
         A_JumpIfHealthLower(2500,"Wonkier") at :2063 cuts this to 10 shots
         and diverts.
```

```
ATTACK   RS_WhiteCaco2.Wonkier
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2071
shape    SCATTER
payload  RS_CacobaldBall2 x31
arc      50   bands random(-3,3) x12, random(-9,9) x5, random(-25,-3) x7,
         random(3,25) x7
timing   0,0,0,0 | 1,1 | 0,0,0,0 | 1,1 | 0,0,0,0 | 2 | 0x7 | 0x6 | 2
         -- 24 of the 31 leave on ZERO-tic frames
damage   Damage 5   (bare -- engine 5..40)
type     Melee
sound    "imp/attack" x31
impact   as Wonky
trigger  Missile   (A_JumpIfHealthLower(2500) from Wonky)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_CacobaldBall2", count:31, arc:50, fireSnd:"imp/attack")
notes    THE LARGEST SINGLE VOLLEY IN THE FAMILY -- 31 projectiles in
         ~10 tics, most of them on the same tic. The pattern is a dense
         centre core (12 shots inside +/-3) wrapped in two wide flanks
         (14 shots between 3 and 25 degrees). Every one weaves
         independently. Ends A_Jump(64,"what").
```

```
ATTACK   RS_WhiteCaco2.arms
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2087
shape    RAIN
payload  RS_ArmSpawnerCACO x1  ->  RS_CacoARMSU x9
arc      --   (arms land at random(+/-64), random(+/-128), random(+/-256)
         around the TARGET -- three widening rings)
timing   spawner at t=27; arms at +6, +10, +18 tics after it lands
damage   ARMS HAVE NO Damage PROPERTY. All damage is
         A_Explode(random(10,50),64) on ELEVEN frames
         (RS_CacodemonFX.zs:2075-2082) -- up to 550 damage per arm if you
         stand in it the whole time.
type     Melee
sound    "caco/sight" at ATTN_NONE, channel 7, volume 2 (:2086) -- a
         map-wide roar. Each arm plays SeeSound "Forgotten/Pain".
impact   RS_ArmSpawnerCACO (RS_CacodemonFX.zs:1945) is a white Stencil
         orb that scales 4.7 -> 2.0 over 18 tics and then spawns
         2 + 3 + 4 = 9 RS_CacoARMSU. Each arm is +FLOORHUGGER +THRUACTORS,
         Speed 0 -- it rises out of the floor, grabs, and shrinks away.
trigger  Missile   (one of three even branches)
range    --   (A_VileTarget places it at the target regardless of distance,
         and needs no line of sight check of its own)
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_ArmSpawnerCACO", count:1, cap:1,
                    tierOffset:0, fireSnd:"caco/sight")
         -- the 9 arms are the spawner's own payload, not the caster's
notes    THIS IS THE ONLY TARGET-CENTRED ATTACK IN THE FAMILY and the only
         reason `RAIN` appears in this file. A_VileTarget is the archvile's
         "put a thing at their feet" primitive; the arms then erupt around
         that point rather than falling from above, but the geometry is
         RAIN's.
         Preceded by 23 white A_SpawnParticle puffs (:2085) as the tell.
         A_JumpIfHealthLower(2500,"MoreArms") at :2088.
```

```
ATTACK   RS_WhiteCaco2.MoreArms
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2093
shape    RAIN
payload  RS_ArmSpawnerCACO x3  ->  RS_CacoARMSU x27
arc      --   (as arms, three times over)
timing   9, 8, 7 tics between waves -- ACCELERATING
damage   as arms -- A_Explode(random(10,50),64) x11 frames per arm
type     Melee
sound    "caco/sight" ATTN_NONE x3 -- three map-wide roars
impact   as arms, x3
trigger  Missile   (A_JumpIfHealthLower(2500) from arms)
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_ArmSpawnerCACO", count:3, cap:3,
                    tierOffset:0, fireSnd:"caco/sight")
notes    Twenty-seven arms, each capable of 550 damage, all re-targeted to
         wherever you are at the moment of each A_VileTarget. Below 2500 HP
         this is the phase-1 boss's killer.
         Ends A_Jump(64,"what").
         NOT AN ATTACK: `what` (:2108) spawns 3x RS_WhiteCacoFake decoys at
         random(+/-64,+/-64,+/-32), sets +NOPAIN, A_Wanders for ~24 tics,
         then rescales 0.1 -> 1.0. RS_WhiteCacoFake (RS_CacodemonFX.zs:1922)
         has no Damage; it A_Warps itself around and fades. An escape, not
         an attack.
         NOT AN ATTACK: Death (:2121) is a 90+ tic set piece of screams,
         Radius_Quake(15,30,0,40,0) x3 and white particles that ends by
         spawning RS_WhiteCacoREAL (:2142). Radius_Quake does no damage.
         Phase 1 dies without hurting anyone.
```

---

# TIER 11 PHASE 2 -- RS_WhiteCacoREAL ("Thy flesh consumer")

Spawns +INVULNERABLE +NOPAIN. `Eyes` (:2218) puts **four RS_WhiteCacoOrb1**
in orbit; each orb's Death gives the boss one `RS_CacoSafety`
(RS_CacodemonFX.zs:1906). At 4 tokens, `See` diverts to `Vuln` (:2237),
which clears +INVULNERABLE and +NOPAIN, sets +MISSILEEVENMORE, raises Speed
to 24, and sets `user_mad = 1` -- which unlocks the second attack table.
So: **kill the four orbs, or nothing you do matters.**

```
ATTACK   RS_WhiteCacoREAL.Handy
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2257
shape    RAIN
payload  RS_ArmSpawnerCACO2 x1  ->  RS_CacoARMSU2 x16
arc      --   (arms at random(+/-64) x3, random(+/-128) x5,
         random(+/-256) x8 around the TARGET)
timing   spawner at t=15; arms at +4, +8, +14 tics
damage   NO Damage property. A_Explode(random(10,50),64) on FOURTEEN frames
         per arm (RS_CacodemonFX.zs:2035-2048)
type     **DIMp**
sound    each arm's SeeSound "Forgotten/Active"; the spawner itself is
         SILENT -- unlike phase 1's `arms`, there is no roar
impact   RS_ArmSpawnerCACO2 (RS_CacodemonFX.zs:1979) is the BLACK Stencil
         twin of phase 1's white one: faster (2-tic frames vs 3) and it
         spawns 3 + 5 + 8 = 16 arms instead of 9.
trigger  Missile   (phase A: A_Jump(255,"Handy","Bloody") at :2249)
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_ArmSpawnerCACO2", count:1, cap:1, tierOffset:0)
notes    DIMp AGAIN CANNOT HURT CACOS -- every monster in this family has
         `DamageFactor "DIMp", 0`. Sixteen arms x fourteen r64 pulses is a
         player-only grinder.
         Silent, black, and 78% more arms than phase 1's version. It is
         phase 1's attack made worse in every axis.
```

```
ATTACK   RS_WhiteCacoREAL.Bloody
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2262
shape    UNCLASSIFIED   (self-centred delayed launcher)
payload  RS_BloodRainerCaco x3  ->  RS_EyeRocketCaco x3
arc      --   (rainers at random(+/-12) around the CASTER, z 24)
timing   5,5,5 for the rainers; each fires its rocket after 19 more tics
damage   RS_BloodRainerCaco itself: none (Health 9999, +NOCLIP, Speed 1)
         RS_EyeRocketCaco: DamageFunction (random(50,150))
type     Melee (the rocket)
sound    rocket SeeSound "skull/melee"
impact   RS_EyeRocketCaco (RS_CacodemonFX.zs:1817) **HOMES HARD** --
         A_SeekerMissile(11,11) every 2 tics at Speed 24, +THRUSPECIES
         +MTHRUSPECIES. Death: A_Scream, then
         **A_Explode(random(50,120),64)** -- up to 120 damage in a r64
         sphere, on top of the random(50,150) contact hit. Then a 30-tic
         shrinking eye animation with "misc/gibbed".
         DeathSound "vile/laugh" is **PROVEN MISSING IN CH ITSELF** -- no
         SNDINFO entry, not vanilla. The detonation is silent apart from
         A_Scream and misc/gibbed.
trigger  Missile   (phase A)
range    --
mirrored no
inherit  --
profile  TWO SLOTS (the delay is the point):
           MakeSummon(summonCls:"RS_BloodRainerCaco", count:3, cap:3, tierOffset:0)
           MakeHeavy(proj:"RS_EyeRocketCaco", fireSnd:"skull/melee", spawnHeight:12)
notes    The rainer rises on ThrustThingz(0,10,0,0) for 3 tics, sits for 16,
         then dies and fires ONE rocket at random(-3,3) before A_Die
         (RS_CacodemonFX.zs:1807-1812). It is a 19-tic fuse on a
         200-damage homing seeker. Three of them.
```

```
ATTACK   RS_WhiteCacoREAL.Handy2
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2283
shape    RAIN
payload  RS_ArmSpawnerCACO2 x1 -> RS_CacoARMSU2 x16, PLUS 4 more
         RS_CacoARMSU2 placed directly
arc      --   the 4 direct arms at random(+/-528) around the CASTER
timing   spawner at t=15; the 4 direct arms on the same 0-tic frame
damage   as Handy -- A_Explode(random(10,50),64) x14 frames per arm
type     DIMp
sound    SILENT
impact   as Handy, plus four arms at up to 528 units in any direction --
         these are CASTER-centred, so they cover the room rather than you.
trigger  Missile   (phase B: A_Jump(255,"Handy2","Bloody2","Portal","spikes")
         at :2253 -- only after Vuln)
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_ArmSpawnerCACO2", count:1, cap:1, tierOffset:0)
         + MakeSummon(summonCls:"RS_CacoARMSU2", count:4, cap:4, tierOffset:0)
notes    Twenty arms. The four extra ones use a DIFFERENT origin (the
         caster, radius 528) from the sixteen (the target, radius 256), so
         the attack covers both where you are and where you might run.
```

```
ATTACK   RS_WhiteCacoREAL.Bloody2
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2277
shape    MULTI
payload  RS_BloodRainerCaco x3  +  RS_EyeRocketCaco x3 DIRECT
arc      the direct rockets at random(-20,20) -- a 40-degree spread
timing   rainers 3,3,3 then rockets 3,3,3
damage   RS_EyeRocketCaco DamageFunction (random(50,150)), from both
         sources
type     Melee
sound    "skull/melee" x6
impact   as Bloody -- A_Explode(random(50,120),64) on every rocket
trigger  Missile   (phase B)
range    --
mirrored no
inherit  --
profile  TWO SLOTS:
           MakeSummon(summonCls:"RS_BloodRainerCaco", count:3, cap:3, tierOffset:0)
           MakeVolley(proj:"RS_EyeRocketCaco", count:3, arc:40, fireSnd:"skull/melee")
notes    SIX homing rockets, not three -- three fired immediately in a
         spread and three more on a 19-tic fuse from the rainers. Six x
         (150 contact + 120 blast) is 1620 potential damage from one
         attack state. This is the family's ceiling.
```

```
ATTACK   RS_WhiteCacoREAL.spikes
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2267
shape    MULTI
payload  RS_MolochNail x8  +  RS_MinesRev x4
arc      nails random(-9,9) from lateral offset random(-10,10);
         mines random(-25,25) from offset 0
timing   4 nails (3,3,3,3) | sight check | 4 mines (3,3,3,3) | sight check |
         4 nails (3,3,3,3) | 12 tics recovery
damage   RS_MolochNail DamageFunction (random(10,30))
         RS_MinesRev   DamageFunction (random(10,40))
type     Fire (both)
sound    nails AttackSound "moloch/nailhitbleed" (+SPAWNSOUNDSOURCE);
         mines SeeSound "monster/dknmsl"
impact   NAILS (RS_CacodemonFX.zs:169): Speed 30, +EXTREMEDEATH
         +BLOODSPLATTER +ROCKETTRAIL, Decal "BulletChip". Death plays
         "moloch/nailhit", then SIX frames of A_Explode(random(2,10),64)
         and THREE of A_Explode(random(5,20),64) -- nine radius pulses per
         nail -- plus an RS_PuffCybieRed. DeathSound "weapons/firex4".
         MINES: SEE THE DEDICATED ROW BELOW -- their Death is a 35-nail
         ring, and they bounce almost forever first.
trigger  Missile   (phase B)
range    --
mirrored no
inherit  --
profile  TWO SLOTS:
           MakeBurst(proj:"RS_MolochNail", count:8, delayTics:3, arc:18,
                     fireSnd:"moloch/nailhitbleed")
           MakeBurst(proj:"RS_MinesRev", count:4, delayTics:3, arc:50,
                     fireSnd:"monster/dknmsl")
notes    Ends A_MonsterRefire(150,"See") (:2273) -- ~41% chance to loop the
         whole 60-tic sequence again. Two A_CheckSight("See") breaks abort
         it if you break line of sight.
```

```
ATTACK   RS_WhiteCacoREAL.Portal
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2289
shape    UNCLASSIFIED   (self-centred summon)
payload  RS_SummonPortalCybie x1
arc      --   (at random(+/-128) around the CASTER, z 12)
timing   one spawn after 15 tics
damage   --
type     --
sound    the portal's SeeSound is "holy2/holy4", which is **PROVEN MISSING
         IN CH ITSELF** -- CH's SNDINFO defines Holy2/holy2 and Holy3/holy3
         only. Inert there too. THE PORTAL ARRIVES SILENTLY.
impact   RS_SummonPortalCybie (RS_CacodemonFX.zs:337) is a Health-50
         Monster, +NOPAIN +NOTARGET +LOOKALLAROUND, Scale 2, Speed 1.
         Its own Missile (see the minion row below) is
         A_PainAttack("RS_PortalSummons",0,PAF_NOSKULLATTACK) -- it births
         a random monster every ~8% of See cycles until you kill it.
         DeathSound "wraith/wraith5", DropItem RS_HealthBundle.
trigger  Missile   (phase B)
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_SummonPortalCybie", count:1, cap:1,
                    tierOffset:0)
notes    A summoner that summons a summoner. RS_PortalSummons
         (RS_CacodemonFX.zs:316) is a RandomSpawner weighted
         MolochWraith 800 / Revenant 300 / RedImp 300 / RedLSoul 200 /
         RedRevenant 120 / PurpleRevenant 100 / RedZombie 80 /
         RedCGuy 70 / RedDemon 150 / RedSG 50 / RedCaco 50.
         **Four of those eleven classes do not exist in this tree yet**
         (three revenants and RS_MolochWraith), documented at the site as
         self-healing when those lanes land. Until then those weights are
         inert and the effective table is skewed toward RedImp/RedDemon.
```

```
ATTACK   RS_WhiteCacoREAL.Death
file     zscript/monsters/cacodemon/RS_Cacodemon.zs:2301
shape    SCATTER
payload  RS_HKRedDeath x24
arc      NOT AN ANGLE SPREAD -- see notes. Lateral offsets -30, +50, +30,
         +5, then random(-50,50) x20; pitch -10, +10, +10, -10, then
         random(-10,10) x20
timing   4,4,4,4 | 4x5 | 3x5 | 2x5 | 1x5   -- ACCELERATING to a machine-gun
damage   RS_HKRedDeath has NO Damage property. Its whole output is
         A_Explode(random(5,10),42) once on the second frame of Death
         (RS_ZombiemanFX.zs:860) plus A_Burst("RS_RedThingsHK") gibs.
type     Fire
sound    A_Scream ("cacobalddeath"), then "world/barrelx" TWICE per
         projectile -- 48 barrel pops
impact   RS_HKRedDeath's Spawn goes straight to Death: it is a barrel
         explosion in projectile form, MISL B-D over 17 tics.
trigger  Death
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_HKRedDeath", count:24, delayTics:3, arc:2,
                   pitchJitter:10.0)
         -- trigger RS_FIRE_DEATH
notes    **THIS IS FINDING (b) IN ITS PUREST FORM.** All 24 calls pass
         `CMF_AIMOFFSET` in the ANGLE slot and `2` in the FLAGS slot:
           A_CustomMissile("RS_HKRedDeath", random(15,90), random(-50,50),
                           CMF_AIMOFFSET, 2, random(-10,10))
         resolves to spawnheight random(15,90), lateral offset
         random(-50,50), **angle = 1 degree (constant)**, flags = 2
         (CMF_AIMDIRECTION), pitch random(-10,10). There is no horizontal
         angular spread at all -- the spray comes from the 100-unit lateral
         band and the 75-unit height band. CH's own text
         (Cacodemons.txt:3524-3531). Preserved, flagged, NOT corrected.
         The same eleven-argument pattern appears at
         RS_CacodemonFX.zs:1288-1292 (RS_RedSpikeCacoEX.Death) and
         :1910-1914 (RS_WhiteCacoOrb1.Death).
```

---

# MINIONS, SUMMONS AND PAYLOADS THAT THEMSELVES ATTACK

Eight non-monster actors in `RS_CacodemonFX.zs` carry real attack states.
They are not in the 15-monster count but they are attack sources and a
parts bin wants them.

```
ATTACK   RS_RedSpikeCacoEX.Missile
file     zscript/monsters/cacodemon/RS_CacodemonFX.zs:1276
shape    CHARGE
payload  --   (the minion IS the projectile)
arc      --
timing   6 tics of aim, 1 tic of commit, then a 39-tic decelerating tail
damage   Damage 5   (bare -- A_SkullAttack contact is Damage * random(1,8),
         so 5..40)
type     --
sound    --   AttackSound is explicitly `""` (:1245). SILENT.
impact   Contact only.
trigger  Missile
range    --
mirrored no
inherit  --
profile  no charge factory -- see UNRESOLVED item 6
notes    A_SkullAttack(50) IMMEDIATELY FOLLOWED BY
         `ThrustThing(int(angle),33,0,0)` (:1277). ThrustThing takes a BYTE
         angle (0-255); CH passes degrees (0-359), so the extra shove goes
         in a direction that is wrong by design. CH's own quirk, preserved
         with a comment at the site.
         ORBIT PHASE FIRST: `Fly` (:1262) A_Warps the spike to
         master + 176 units at a rotating user_angle (+8 per 2 tics) until
         user_angle >= 720 -- i.e. it circles the black boss twice, about
         90 tics, before `Strike` releases it to A_Chase.
```

```
ATTACK   RS_RedSpikeCacoEX.Death
file     zscript/monsters/cacodemon/RS_CacodemonFX.zs:1288
shape    MULTI
payload  RS_HKRedDeath x5  +  RS_CacoNail x32
arc      nails in four quadrants -- random(0,90), random(90,180),
         random(180,270), random(270,359), 8 each = a full 360
timing   1,1,1,1,1 for the barrels; all 32 nails on 0-tic frames
damage   RS_HKRedDeath none directly (A_Explode(random(5,10),42) on its own
         Death); RS_CacoNail DamageFunction (random(5,15))
type     Fire / Melee
sound    "world/barrelx" x10; nails AttackSound "moloch/nailhitbleed"
impact   RS_CacoNail (RS_CacodemonFX.zs:1370): Speed 55, Decal
         "BulletChip", +EXTREMEDEATH +BLOODSPLATTER. Death plays
         "moloch/nailhit" then SIX frames of A_Explode(random(2,5),64) and
         THREE of A_Explode(random(2,8),64), plus RS_PuffCybieRed.
trigger  Death
range    --
mirrored no
inherit  --
profile  TWO SLOTS:
           MakeVolley(proj:"RS_HKRedDeath", count:5, arc:2, pitchJitter:10.0)
           MakeVolley(proj:"RS_CacoNail", count:32, arc:360)
         -- trigger RS_FIRE_DEATH
notes    The nails go out with velocity random(33,66) and z-velocity
         random(-1,25), so it is a 360 spray that also rises.
         The five RS_HKRedDeath calls carry finding (b)'s
         angle/flags swap.
```

```
ATTACK   RS_WhiteCacoOrb1.Pain
file     zscript/monsters/cacodemon/RS_CacodemonFX.zs:1899
shape    RING
payload  RS_PlasmaBallSP5 x45
arc      360   angle random(0,360) AND pitch random(0,360) -- the tell,
         twice over: it is a SPHERE, not a ring
timing   one tic -- all 45 together
damage   DamageFunction (random(3,7))   (INHERITED from RS_PlasmaBallSP4)
type     Plasma   (INHERITED)
sound    --   the orb's AttackSound is `""` (:1879). The only sound is
         PainSound "prox/beep".
impact   INHERITED WHOLE from RS_PlasmaBallSP4 (RS_CacodemonFX.zs:132):
         DeathSound "weapons/plasmax", PLSE A-E flash, Speed 9, Scale 0.25,
         Alpha 0.75, and a 2/256-per-cycle self-destruct roll in flight.
         RS_PlasmaBallSP5's own body is FIVE LINES -- it adds
         Species "Cybie" and +DONTHARMCLASS and nothing else. Read the
         child alone and this attack has no damage, no sound and no impact.
trigger  Pain
range    --
mirrored no
inherit  RS_PlasmaBallSP4
profile  MakeVolley(proj:"RS_PlasmaBallSP5", count:45, arc:360,
                    pitchJitter:360.0)
         -- trigger RS_FIRE_PAIN
notes    FORTY-FIVE PROJECTILES ON ONE TIC, FIRED BY BEING SHOT. The orbs
         are the phase-2 white boss's invulnerability lock, so the player
         has to shoot them, and every hit that causes pain triggers this.
         PainChance 232 -- it happens on ~91% of hits.
         A_Jump(128,"Laser") at :1898 sends half of them to the row below
         instead.
         The orbs orbit the boss at radius 64 (A_Warp, +8 degrees per tic,
         :1893).
```

```
ATTACK   RS_WhiteCacoOrb1.Laser
file     zscript/monsters/cacodemon/RS_CacodemonFX.zs:1902
shape    SALVO
payload  RS_DFlare x3
arc      --   (all three at random(-3,3) -- effectively aimed)
timing   one tic, all three together
damage   DamageFunction (random(10,38))
type     Fire
sound    "weapons/firmfi"   (SeeSound on the dart, x3)
impact   DeathSound "weapons/firex4", then CBAL C-G flare. In flight it
         sheds an RS_MFlareFX trail flame every 3 tics (cosmetic).
trigger  Pain   (A_Jump(128,"Laser") from Pain)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_DFlare", count:3, arc:6, fireSnd:"weapons/firmfi")
         -- trigger RS_FIRE_PAIN
notes    Speed 25, +THRUGHOST, Alpha 0.85. The aimed half of the orb's
         retaliation -- three darts down your throat instead of a 45-ball
         sphere.
         Sprite note carried from the file header: CBAL ships via
         `sprites/rs_lostsoul` because lostsouls.txt uses it too.
```

```
ATTACK   RS_WhiteCacoOrb1.Death
file     zscript/monsters/cacodemon/RS_CacodemonFX.zs:1910
shape    SCATTER
payload  RS_HKRedDeath x5
arc      NOT AN ANGLE SPREAD -- finding (b) again. Lateral offsets -30,
         +50, +30, +5, +50; pitch -10, +10, +10, -10, +10; angle constant 1
timing   4,4,4,4,4
damage   none directly -- A_Explode(random(5,10),42) per barrel
type     Fire
sound    A_Scream x2 ("prox/beep"), then "world/barrelx" x10
impact   as RS_WhiteCacoREAL.Death
trigger  Death
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_HKRedDeath", count:5, arc:2, pitchJitter:10.0)
         -- trigger RS_FIRE_DEATH
notes    Also gives the boss one RS_CacoSafety token (:1906) -- this is the
         line that counts toward the four-orb unlock. Killing an orb costs
         you five barrel explosions.
```

```
ATTACK   RS_SummonPortalCybie.Missile
file     zscript/monsters/cacodemon/RS_CacodemonFX.zs:371
shape    UNCLASSIFIED   (summon, via a pain-elemental primitive)
payload  RS_PortalSummons x1   (a RandomSpawner -- see the Portal row above
         for the roster)
arc      --
timing   1 + 2 tics
damage   --
type     --
sound    --   SILENT. SeeSound "holy2/holy4" is PROVEN MISSING IN CH.
impact   Whatever the RandomSpawner rolls arrives alive.
trigger  Missile   (A_Jump(12,"Missile") from See at :367 -- ~4.7% per
         32-tic See cycle, so roughly one monster every 11 seconds while
         it lives)
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_PortalSummons", count:1, cap:0,
                    tierOffset:0)
         -- cap 0 means UNCAPPED; MakeSummon's cap is `max(1,cap)`, so the
            uncapped behaviour cannot be expressed. Flagged in UNRESOLVED
            item 8.
notes    `A_PainAttack("RS_PortalSummons",0,PAF_NOSKULLATTACK)` --
         PAF_NOSKULLATTACK stops the spawned thing from being launched like
         a lost soul; it just appears. The portal has Health 50 and
         +NOPAIN, so it is easy to kill but does not flinch while you do.
```

```
ATTACK   RS_BloodRainerCaco.Death
file     zscript/monsters/cacodemon/RS_CacodemonFX.zs:1811
shape    SINGLE
payload  RS_EyeRocketCaco x1
arc      --   (jitter random(-3,3))
timing   fires 16 tics after the rainer stops rising, then A_Die
damage   DamageFunction (random(50,150))
type     Melee
sound    "skull/melee"   (SeeSound on the rocket)
impact   A_SeekerMissile(11,11) at Speed 24 -- hard homing. Death:
         A_Scream then **A_Explode(random(50,120),64)**, "misc/gibbed",
         and a shrinking eye. DeathSound "vile/laugh" is PROVEN MISSING
         IN CH.
trigger  Death   (of the rainer -- but the rainer's Death is its normal
         lifecycle, not a reaction to damage: Fly falls through to Death
         after 3 tics)
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_EyeRocketCaco", fireSnd:"skull/melee", spawnHeight:12)
notes    Health 9999, +NOCLIP, -COUNTKILL, Speed 1 -- it cannot be killed
         early and it cannot be blocked. The 19-tic delay is the whole
         mechanic: you are given time to move and the seeker takes it back.
```

```
ATTACK   RS_VoidField.Spawn
file     zscript/monsters/cacodemon/RS_CacodemonFX.zs:978
shape    UNCLASSIFIED   (stationary damage aura)
payload  --   (the field damages directly)
arc      --
timing   A_Explode(5,64) once per 5-tic pulse cycle, indefinitely
damage   5   (FLAT -- the one A_Explode in this family with no roll)
type     DIMp
sound    "spell/spellcast1" on arrival; DeathSound "spell/Impact1"
impact   --   (it is the impact)
trigger  Spawn
range    --   (radius 64 on the explode; Radius 46 / Height 46 on the body)
mirrored no
inherit  --
profile  MakeRadial(radius:64, damage:5, hitsAllies:false,
                    fireSnd:"spell/spellcast1")
notes    +INVULNERABLE, Health 6666, +REFLECTIVE, -SOLID, -COUNTKILL,
         +DONTTHRUST. YOU CANNOT DESTROY IT -- it dies only on its own
         2/256-per-cycle roll (:980), averaging ~640 tics but with a very
         long tail. Five of these at once (Yellow's VoidField row) is a
         no-go zone that outlasts the fight.
         DIMp means it cannot hurt any monster in this family.
```

---

# PAYLOAD SECONDARIES SUBSTANTIAL ENOUGH TO BE THEIR OWN ROWS

```
ATTACK   RS_MinesRev.Death
file     zscript/monsters/cacodemon/RS_CacodemonFX.zs:244
shape    RING
payload  RS_RevNail x35
arc      360   fixed 10-degree steps: 0,10,20 ... 160, then 180,190 ... 350
timing   one tic, all 35 together, after 25 tics of A_Explode frames
damage   DamageFunction (random(5,15)) per nail; the mine's own death
         adds FIVE frames of A_Explode(random(5,15),88)
type     Melee (nails) / Fire (the mine)
sound    DeathSound "weapons/boom1"; each nail AttackSound
         "moloch/nailhitbleed"
impact   RS_RevNail (RS_CacodemonFX.zs:283): Speed 55, +MTHRUSPECIES
         +EXTREMEDEATH +BLOODSPLATTER, Decal "BulletChip". Death plays
         "moloch/nailhit" then six frames of A_Explode(random(2,5),64) and
         three of A_Explode(random(2,8),64), plus RS_PuffCybieRed.
trigger  Death   (of the mine)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_RevNail", count:35, arc:360,
                    fireSnd:"moloch/nailhitbleed")
notes    **CH SKIPS 170 DEGREES.** The steps run 0..160 then jump to 180 --
         34 evenly spaced nails plus one gap. Preserved with a comment at
         the site (:261). Do not "complete" the ring.
         BEFORE IT DIES IT BOUNCES: -NOGRAVITY, Gravity 0.9, BounceType
         "Doom", **BounceCount 999**, BounceFactor 0.85, WallBounceFactor
         **1.3** (it gains speed off walls), BounceSound "fire/fire3".
         Per 12-tic flight cycle it rolls A_Jump(12,"Death") (4.7%
         self-detonate) and A_Jump(32,"Bounce") (12.5% random re-thrust at
         a scrambled angle, :239). It is a live grenade that wanders for
         seconds.
         IT ALSO DROPS AMMO: RS_CH_RocketAmmo 64, RS_CH_Shell 128,
         RS_implyingclip 174, RS_CH_Cell 32 (:226-229). A projectile with
         a drop table.
```

```
ATTACK   RS_SbombCaco.Death
file     zscript/monsters/cacodemon/RS_CacodemonFX.zs:1019
shape    SCATTER
payload  RS_CrackodemonBall x12
arc      SEE NOTES -- the angle is a constant 1 and the FLAGS are random
timing   1 tic each, twelve consecutive frames (12 tics), bracketed by
         A_Explode(random(5,20),88) before and A_Explode(random(5,20),99)
         after
damage   DamageFunction (random(5,55)) per ball
type     Plasma
sound    DeathSound "Crack/death"; each ball's SeeSound "Crack/see" x12
impact   BLL9 C-E pop per ball, no explosion. Trail RS_CrackoBallTrail.
trigger  Death   (of the bomb)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_CrackodemonBall", count:12, delayTics:1,
                   arc:2, pitchJitter:360.0, fireSnd:"Crack/see")
notes    **THE WORST CASE OF FINDING (b) IN THE FILE.** The call is
           A_CustomMissile("RS_CrackodemonBall", 5, 0, CMF_AIMOFFSET,
                           random(0,360), random(0,360))
         which resolves to spawnheight 5, offset 0, **angle 1**,
         **flags = random(0,360)** and pitch random(0,360). The FLAGS
         argument is a random integer, so on every shot a different
         combination of CMF_AIMOFFSET/AIMDIRECTION/TRACKOWNER/
         CHECKTARGETDEAD/ABSOLUTEPITCH/OFFSETPITCH/SAVEPITCH/ABSOLUTEANGLE
         is active. The behaviour is genuinely non-deterministic in a way
         no profile can reproduce, and it is CH's own text
         (Cacodemons.txt:2024). Recorded verbatim; NOT corrected.
         The identical pattern is at :1012 on the bomb's Spawn state,
         throwing an RS_RedThingsHK (cosmetic) every tic of flight.
```

```
ATTACK   RS_HadesBolt.Spawn   (the floor crawler's laydown)
file     zscript/monsters/cacodemon/RS_CacodemonFX.zs:1741
shape    UNCLASSIFIED   (a self-propelled hazard that lays hazards)
payload  RS_HadesBolt2 x5 per loop  +  RS_HadeExpl x5 per loop
arc      --   the crawler drifts by ThrustThing(random(0,255),1,0,0) each
         loop; the RS_HadeExpl land at random(+/-128) in rising z bands
timing   a 10-tic loop, run 35 times (ReactionTime 35, A_CountDown at
         :1757) -- **~350 tics, about 10 seconds**
damage   A_Explode(random(5,15),64,0) FIVE times per loop from the crawler
         itself, plus every RS_HadesBolt2's own 1-tic
         A_Explode(random(5,15),64,0) LOOP, plus every RS_HadeExpl's five
         pulses
type     Plasma
sound    SILENT AT BOTH ENDS -- both its sounds are PROVEN MISSING in CH
         (see the Electro2 rows). RS_HadesBolt2 plays "Monster/hadtel".
impact   Death (:1759): six frames of A_Explode(random(5,35),64,0).
trigger  --   (this is a payload's own behaviour, reached from
         RS_BlackCaco2.Electro2 and RS_BlackCacoEX.Electro2)
range    --
mirrored no
inherit  CacodemonBall
profile  NO FACTORY COVERS THIS. It is a persistent moving area-denial
         entity, not a volley. Closest honest expression:
           MakeHeavy(proj:"RS_HadesBolt", spawnHeight:32)
         and accept that everything interesting happens inside the payload.
notes    +FLOORHUGGER +RIPPER +FLOORCLIP, BounceType "Hexen", -NOGRAVITY,
         Speed 5, YScale 4.0 / XScale 0.7 -- a tall thin ripping sheet that
         crawls the floor and cannot be blocked by bodies.
         Per loop: 5 A_Explodes, 5 RS_HadesBolt2 (Speed 184, RenderStyle
         "None", +RIPPER, invisible, 1-tic explode loop), 5 RS_HadeExpl at
         z bands 1-12, 12-24, 16-32, 24-42, 32-64 (a rising wall), and one
         random thrust.
         Over 35 loops that is 175 A_Explodes from the crawler, 175
         invisible ripping risers, and 175 five-pulse explosions. Three of
         these are fired at once by Electro2. **It is the single largest
         damage source in the family and its two sounds are both broken in
         CH, so it arrives in total silence.**
```

---

# UNRESOLVED

An honest gap is worth more than a confident guess.

**1. THE SPEC'S CH PATH DOES NOT EXIST ON THIS MACHINE.**
`C:\Users\Command\Desktop\CH` is absent -- `C:\Users\Command\Desktop\`
contains `CHP`, but no `CH`. I did the CH cross-check against
`E:\New folder\ART SOURCE\CH\decorate\Cacodemons.txt` (3876 lines), which is
the path `CLAUDE.md`'s "IMPORTING A MONSTER MEANS THE WHOLE MONSTER" section
names as source of truth, and which matches the line count and line numbers
cited in both source files' headers. **I consulted no other pack.** The
owner should decide which path is canonical; the two documents disagree and
one of them points at nothing.

**2. `E:\DXR2` is not reachable from this session.** CLAUDE.md names it as
the authority on engine flags and properties. `ls E:/DXR2` returns nothing.
Two consequences:
  * The vanilla `CacodemonBall` body used in the `inherit` lines is taken
    from `RS_CacodemonBall2` (`RS_CacodemonFX.zs:754`), which is a verbatim
    copy of it carrying `replaces CacodemonBall`. That is our own tree, not
    the engine source, so it is evidence rather than proof.
  * `A_MeleeAttack`'s exact use of `MeleeDamage` (flat vs rolled) is
    recorded as "the actor property, flat" without engine confirmation.
    Affects RS_AbyssCaco2.Melee (12) and RS_RedCaco.Melee (10).

**3. `+STRIFEDAMAGE` on RS_EyeBeamCaco.** I recorded the effect as
"damage x random(1,4)" from memory of the engine's damage path, not from
`E:\DXR2`. The declared `Damage 1` is certain; the multiplier is not.

**4. Whether a projectile takes `Death` or `XDeath` on this build.**
`RS_GrellBallBrown` (`RS_CacodemonFX.zs:407`) puts its permanent 0.8x
player slow on `XDeath`, which then falls through into `Death`. If XDeath is
never entered for a projectile on this engine, the Brown caco's signature
mechanic never fires and nothing anywhere would report it -- an unresolved
sound-class silent failure. **This is the highest-value thing in this list
to check in-game.** CH is identical, so it is not an import defect either
way.

**5. `RS_CacobaldBall2`'s three-way flight behaviour has no profile
expression.** Each ball independently rolls `A_BishopMissileWeave` /
`A_CStaffMissileSlither` / `A_SetSpeed(30)` and commits. `RS_AttackProfile`
has no per-projectile flight-behaviour field. The White boss's Wonky and
Wonkier rows (55 projectiles between them) lose this if ported as written.

**6. THERE IS NO CHARGE FACTORY.** `A_SkullAttack` appears three times
(RS_GrayCaco2, RS_PurpleCaco, RS_RedSpikeCacoEX) and `RS_AttackProfile`
has `RS_ATK_BULLET / HEAVY / MELEE / HITSCAN / SUMMON / RADIAL / SELFBUFF`
-- no lunge mode. All three CHARGE rows carry a stand-in profile line and
say so. Whoever composes the seventeen files should decide whether CHARGE
gets a mode or is dropped.

**7. `MakeSelfBuff(duration:)` has no documented "permanent" value.**
RS_RedCaco's `ThatsIt` sets +NOPAIN, Speed 34 and +MISSILEEVENMORE
irreversibly. I wrote `duration:-1` by analogy with
`Powerup.Duration -1`, which is a DIFFERENT API. Unverified.

**8. `MakeSummon(cap:)` cannot express "uncapped".** The factory does
`max(1, cap)` (`RS_AttackProfile.zs:534`), so 0 becomes 1.
`RS_SummonPortalCybie` has no cap in CH -- it summons until killed.

**9. Four classes in `RS_PortalSummons`' roster do not exist in this tree.**
`RS_CommonRevenant`, `RS_PurpleRevenant`, `RS_RedRevenant` and
`RS_MolochWraith` (`RS_CacodemonFX.zs:323-333`). Documented at the site as
self-healing when those lanes land. Until then the effective spawn table for
`RS_WhiteCacoREAL.Portal` is skewed -- notably `RS_MolochWraith` carries
weight 800 of 2220, so **36% of the portal's rolls currently produce
nothing.** I did not verify what a RandomSpawner does with a missing class
name on this build (silently nothing, or a console warning).

**10. `RS_RedLSoul` is a cross-lane dependency.** Same table, weight 200,
expected from the lost-soul import lane (`lostsouls.txt:1085`). Not present
at the time of this read.

**11. Five sounds are PROVEN MISSING IN CH ITSELF and are therefore
correctly silent here.** Transcribed from the FX file's own header, not
re-verified by me against CH's SNDINFO:
`weapons/none`, `weapons/gntidl` (both RS_HadesBolt), `spike/spiked`
(RS_SmallIceCaco), `vile/laugh` (RS_EyeRocketCaco), `holy2/holy4`
(RS_SummonPortalCybie). Per the spec, silence is a finding: as monster
behaviour these are defects inherited from CH; as **profile slots they are
CORRECT**, because the gun's own sound fills the empty rung.

**12. Attacks that are deliberately NOT rows, listed so nobody hunts for
them.** Each was read and found to fire nothing:
  * `RS_YellowCaco.SeekAndKill` (:1350) -- stealth reposition
  * `RS_YellowCaco.Dodge1` / `Dodge2` (:1328/:1331) -- ThrustThing sidesteps
  * `RS_CyanCaco2.Dodge` (:428) -- wander/chase mix off Pain
  * `RS_BlackCaco2.Melee` (:1719) -- an unconditional redirect to Electro2
  * `RS_BlackCaco2.Phase` / `RS_BlackCacoEX.Phase` -- the fade-and-wander
    teleport
  * `RS_WhiteCaco2.what` (:2108) -- decoy escape; RS_WhiteCacoFake has no
    Damage
  * `RS_WhiteCaco2.Death` (:2121) -- 90+ tics of screams, three
    `Radius_Quake`s (no damage) and the hatch of RS_WhiteCacoREAL
  * `RS_WhiteCacoREAL.Vuln` (:2237) -- the invulnerability drop
  * `RS_AbyssCaco2.Death` (:588) -- 30 spawns, but **RS_SplashAbyss has no
    Damage property** (`RS_ZombiemanFX.zs:706`); only its sibling
    RS_SplashAbyss2 does. Pure cosmetics.
  * `Pain.AbyssPE` on all seven monsters that carry it -- a 60-tic
    transformation into RS_AbyssCaco2. It spawns 94 RS_SplashAbyss, which
    do not damage, then A_Die. A morph, not an attack.
  * The eight cvar-gate stubs (`RS_BrownCaco`, `RS_CyanCaco`, `RS_AbyssCaco`,
    `RS_FireBluCaco`, `RS_GrayCaco`, `RS_BlackCaco`, `RS_WhiteCaco`,
    `RS_Colourset7`) -- pure spawn dials, no states past `Stop`.

**13. What I could NOT check.** The spec permits our tree and CH only, and
I stayed inside that. So: no sprite-lump existence check, no SNDINFO
end-to-end resolution, no in-game observation. Every damage number, sound
name and impact chain above is read from source. A sound name that resolves
to a missing lump would look identical to a working one in this document.
```
