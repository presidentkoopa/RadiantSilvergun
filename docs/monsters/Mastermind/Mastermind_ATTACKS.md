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

# MASTERMIND -- MONSTER ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Field order and shape
vocabulary are that spec's, unchanged. This is a parts bin, not documentation.

| | |
|---|---|
| Family | Mastermind (CH `MASTERMINDS.txt`, Spider Mastermind line) |
| Monsters that carry attacks | 15 |
| Attack rows | 74 |
| Source files | `E:\RS_Main\zscript\monsters\mastermind\RS_Mastermind.zs` (3007 lines), `E:\RS_Main\zscript\monsters\mastermind\RS_MastermindFX.zs` (2851 lines) |

## The denominator actually read

* `RS_Mastermind.zs` -- **25 classes**, **245 state labels** (comment-stripped
  count). 9 of the 25 are the spawn dial + the 7 cvar stubs + CH's own
  `// UNUSED` `RS_CH_OrbOfChaos`; none of those has an attack. The remaining
  **15 attacking classes hold 193 state labels, and all 193 were opened**, not
  filtered by name. `RS_SpecialSpider1` declares only `See:` -- its attack is
  inherited and was chased into `RS_Spider.zs`.
* `RS_MastermindFX.zs` -- **81 classes**, **198 state labels**. Every payload
  named by a row was opened for its `Default` block *and* its `Death`/`Bounce`
  states; every payload that is a subclass had its parent opened too.
* Attack call sites in the monster file, comment-stripped: `A_CustomMissile`
  **289**, `A_CustomBulletAttack` **8**, `A_VileTarget` **8**, `A_CustomRailgun`
  **5**, `A_DualPainAttack` **4**, `A_Explode` **3**, `A_SkullAttack` **1**,
  `A_SPosAttackUseAtkSound` **1** = **319 sites**, all attributed to a row below.
  (The brief said 311; this is my own comment-stripped count, reported as
  measured rather than adopted.)
* 13 payload classes live outside this family's two files. All 13 were opened at
  their defining file:line: `RS_ZombieRock`+`RS_WDRock3`, `RS_SpiderCyanBomb`,
  `RS_AracnorbBall`, `RS_GrayCGuff`+`RS_CGthing3`+`RS_CGNail`, `RS_FireBCGguy`,
  `RS_MolochNail`, `RS_FrostLong`, `RS_PlasmaBallSP3`, `RS_RedMessImp`,
  `RS_HKRedDeath`, `RS_DFlarePE2`, `RS_DeathBreathDI`, `RS_WvileSpot`,
  `RS_BlueSP1`, `RS_CH_BoneGib`, `RS_RedThingsLS`.

## CH cross-check

CH was **not** at the path the brief named (`C:\Users\Command\Desktop\CH` does
not exist on this machine). It **is** at `E:\New folder\ART SOURCE\CH`, the path
`CLAUDE.md` names for the import, and `decorate/MASTERMINDS.txt` there is 5273
newline-terminated lines and its line numbers land exactly on the citations our
tree carries (`:70` = `ACTOR BrownMind2`, `:4925` = `ACTOR WhiteMind2`, and 13
more spot-checks, all hits). That is the CH used here. Flagged in UNRESOLVED.

Every attack line in all 15 monsters was diffed against CH line-for-line.
**Every projectile class, count, angle, offset, tic count, jump chance and
roll is identical in every row.** Not one roll is flattened: CH's 60
`Damage(random(a,b))` declarations in `MASTERMINDS.txt` all survive here as
`DamageFunction (random(a,b))`.
Two cosmetic divergences exist and are recorded under UNRESOLVED; neither
touches an attack parameter.

## Factory vocabulary used on the `profile` line

The spec ships exactly one worked `profile` example
(`MakeBurst(proj:, count:, delayTics:, arc:)`). Everything else below is derived
from that naming style. It is declared here so a composer can remap it
mechanically:

`MakeSingle(proj:)` · `MakeBurst(proj:, count:, delayTics:, arc:)` ·
`MakeFan(proj:, count:, arc:, delayTics:)` · `MakeSalvo(proj:, count:, arc:)` ·
`MakeScatter(proj:, count:, coneDeg:, delayTics:)` ·
`MakeHitscan(pellets:, damage:, spreadXY:, spreadZ:, puff:)` ·
`MakeRailgun(damage:, puff:, spawnClass:, duration:)` ·
`MakeCharge(speed:, damage:)` · `MakeRain(proj:, count:, delayTics:, atTarget:)` ·
`MakeMulti(...)` · `MakeSummon(proj:, count:, delayTics:)`.

`muzzleOfs:` = A_CustomMissile's 3rd arg (`spawnofs_xy`, a lateral muzzle
offset), which is **not** an angle. This family uses it constantly and it is the
single easiest field to misread as arc.

---

# BROWN -- RS_BrownMind2 (tier 13, "Death N Decay Master")

Missile branches: `A_Jump(128,"Checkers")` else falls into `BackBack`, which
does `A_JumpIfInTargetLOS("Spiral",0,JLOSF_DEADNOJUMP,850,100)` else falls into
`Missile2`. `Missile2` itself rolls `A_Jump(96,"GroundBreak")` and twice
`A_Jump(64/128,"Boners")`.

```
ATTACK   RS_BrownMind2.Missile2
file     zscript/monsters/mastermind/RS_Mastermind.zs:547
shape    BURST
payload  RS_BrownOrbMind x3 per volley, up to 3 volleys (9 max)
arc      4   (angle random(-2,2); pitch random(-1,1))
timing   5,5,5 within a volley; 10-tic A_FaceTarget re-aim between volleys
damage   DamageFunction (random(3,33))
type     Fire
sound    --   (the attack state is silent; RS_BrownOrbMind's own SeeSound "fire/fire3" plays at spawn)
impact   A_Explode(random(2,8),64) on 5 death frames, PLUS 24x RS_BrownOrbMind2 shrapnel (6 groups of 4, angles random(0,120)/(120,240)/(240,360) x pitch +/-, each random(1,2) Fire and A_Explode(random(1,2),16) x5); DeathSound "weapons/boom1"
trigger  Missile   (Missile -> BackBack -> Missile2)
range    ..   (no gate; BackBack's LOS test at 850..100 diverts to Spiral instead)
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_BrownOrbMind", count:3, delayTics:5, arc:4)   x3 volleys, 10-tic gap
notes    ProjectileKickback 333. Muzzle height 42. The shrapnel is what makes
         this an area weapon -- one orb becomes 25 explosions.
```

```
ATTACK   RS_BrownMind2.Boners
file     zscript/monsters/mastermind/RS_Mastermind.zs:558
shape    BURST
payload  RS_BrownMindBone2 x3
arc      4   (fixed -2 / 0 / +2 -- a token walk, not a fan)
timing   10,10,10   (30 tics; 10-tic A_FaceTarget before and after)
damage   DamageFunction (random(20,40))
type     Melee
sound    --   (SeeSound is explicitly "" -- CH silences the spawn on purpose)
impact   DeathSound "MEATIMPB"; spawns 9x RS_CH_BoneGib, which is Damage 0 -- cosmetic bone gibs, no secondary damage
trigger  Missile   (A_Jump(64) at :548 or A_Jump(128) at :553, out of Missile2)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_BrownMindBone2", count:3, delayTics:10, arc:4)
notes    +SEEKERMISSILE, A_SeekerMissile(4,4) EVERY flight tic -- a slow (Speed
         20) but relentless homer. ProjectileKickback 500, Scale 2.25. The
         Spawn state coin-flips between two frame orders (A1 spins the bone one
         way, A2 the other); no gameplay difference.
```

```
ATTACK   RS_BrownMind2.GroundBreak
file     zscript/monsters/mastermind/RS_Mastermind.zs:566
shape    RAIN
payload  RS_MindGroundSpikeBrown x3
arc      --   (A_VileTarget; placed at the target, not aimed)
timing   8,8,8   (after a 24-tic B05P TUV wind-up)
damage   DamageFunction (random(10,25))  -- contact; the real damage is the detonation, below
type     Melee
sound    "ECHOIMPB" at :564
impact   see the row below -- the spike is itself an attack
trigger  Missile   (A_Jump(96,"GroundBreak") at :544, out of Missile2)
range    --
mirrored no
inherit  --
profile  MakeRain(proj:"RS_MindGroundSpikeBrown", count:3, delayTics:8, atTarget:true)
notes    A_VileTarget spawns AT the target's feet. It is not A_VileAttack, so
         the spec's VILE word does not apply; RAIN is the closest closed-set
         word and the divergence is flagged in UNRESOLVED.
```

```
ATTACK   RS_MindGroundSpikeBrown.Fly   (secondary -- the spike's own detonation)
file     zscript/monsters/mastermind/RS_MastermindFX.zs:643
shape    RING
payload  RS_BrownMindStoneThrow x8   + 9x RS_CH_BoneGib (Damage 0, cosmetic)
arc      360   (fixed 45-degree steps: 0,90,180,270,45,135,225,315)
timing   one tic for the ring; A_Explode(random(60,100),32) fires 3 times, 3 tics apart, around it
damage   DamageFunction (random(1,2)) per stone; A_Explode(random(60,100),32) x3 is the bulk
type     Fire (stones) / none-typed radius damage (A_Explode)
sound    "ROCKHIT1" at :642
impact   stones are +HITTARGET; on XDeath they run A_VileAttack("HEAVIMPB",random(20,60),random(20,60),64,4,"Melee")
trigger  Missile   (as the payload of GroundBreak, above)
range    --
mirrored no
inherit  --
profile  MakeMulti( MakeSalvo(proj:"RS_BrownMindStoneThrow", count:8, arc:360), Explode(dmg:"random(60,100)", radius:32, times:3) )
notes    The spike sits +FLOORHUGGER +THRUACTORS for ~24 tics kicking 22 dirt
         puffs (RS_Drt1/2/3) and quaking, THEN clears THRUACTORS and blows.
         The wind-up IS the attack's read. This is the family's only true RING.
```

```
ATTACK   RS_BrownMind2.Spiral
file     zscript/monsters/mastermind/RS_Mastermind.zs:573
shape    MULTI
payload  RS_ZombieRock x7  +  RS_WindBlastMasterMind x1  +  RS_WindBlastMasterMind2 x1  +  RS_WindBlastMasterMind3 x1
arc      8   (rocks: angle random(-4,4), muzzleOfs random(-5,5), CMF_OFFSETPITCH random(-3,5), height random(28,35))
timing   rocks all on ONE tic (7x 0-tic frames); then the three blasts at 1,1,1
damage   rocks DamageFunction (random(1,12)); blasts have NO Damage -- they are pure A_Explode
type     Melee (rocks) / -- (blasts)
sound    RS_ZombieRock SeeSound "monster/hamflr"; RS_WindBlastMasterMind SeeSound "PUSHBMIN"; blasts 2 and 3 SeeSound ""
impact   rock: DeathSound "Butcher/melee" + 8 dirt spawns. Blast 1: flies, grows Scale 1.5 -> 7.0, A_Stop()s mid-air, then A_Explode(random(10,32),64) then (,82) then (,102) then A_Explode(random(20,80),128) -- four staged blasts from a stationary growing sphere. Blasts 2 and 3 are BBOM pulse VFX with no damage at all.
trigger  Missile   (A_JumpIfInTargetLOS("Spiral",0,JLOSF_DEADNOJUMP,850,100) at :540)
range    100..850   (the LOS gate is a distance band, not a plain range)
mirrored no
inherit  RS_ZombieRock : RS_WDRock3 -- the roll random(1,12) and Scale 0.25 are the child's; Speed 36, DamageType Melee, SeeSound and DeathSound come from RS_WDRock3 (zscript/monsters/zombieman/RS_ZombiemanFX.zs:680)
profile  MakeMulti( MakeSalvo(proj:"RS_ZombieRock", count:7, arc:8), MakeBurst(proj:"RS_WindBlastMasterMind", count:1, delayTics:1, arc:0), MakeBurst(proj:"RS_WindBlastMasterMind2", count:1, delayTics:1, arc:0), MakeBurst(proj:"RS_WindBlastMasterMind3", count:1, delayTics:1, arc:0) )
notes    Reading only the class names, "three wind blasts" looks like triple
         damage. It is not: 2 and 3 are decoration. All the damage is blast 1's
         four-stage A_Explode ladder. It also sheds 3x RS_ReflectorBBaron.
         The state opens with A_Jump(176,"Missile2") -- 69% of Spiral entries
         bail straight back to the orb volley.
```

```
ATTACK   RS_BrownMind2.FeelIt
file     zscript/monsters/mastermind/RS_Mastermind.zs:632
shape    UNCLASSIFIED
payload  RS_ShieldUpMind (given to every monster within 732 units) -> RS_BrownMindShieldBuff + 4x RS_BrownMindBone1
arc      --
timing   A_RadiusGive on one tic; the pickup then spawns a bone every 15 tics, 4 times
damage   RS_BrownMindBone1: A_Explode(random(1,8),8,0) once per flight tic, for ~600 tics
type     Dimp (the bones)
sound    "BONEBR3K" twice, at :629 and :631
impact   the buff halves the recipient's DamageFactor to 0.50, sets +ALWAYSFAST, and thrusts it; reverts after 304 tics (RS_MastermindFX.zs:411)
trigger  Missile   (Missile -> A_Jump(128,"Checkers") -> A_CheckProximity of 13 vanilla monster classes at 320 units -> FeelIt / FeelIt2)
range    ..320 for the proximity test; the buff radius is 732
mirrored no
inherit  --
profile  MakeSummon(proj:"RS_BrownMindBone1", count:4, delayTics:15)  + AllyBuff(radius:732, damageFactor:0.50, alwaysFast:true, tics:304)
notes    An ALLY buff, not a shot -- but it is reachable from Missile and it
         fires something, so it is a row. As a player part it reads as
         "four orbiting bone drones that chip everything near you."
         The bones A_Warp to their master at 128 units, rotating -32 deg per
         4-tic cycle, for 150 cycles.
         Three lines sit AFTER this state's `Goto See` (:637-639: two
         A_CustomMissile("RS_SpidieShotGray") and a FaceTarget). They are
         unreachable here and unreachable in CH (MASTERMINDS.txt:260-262).
```

```
ATTACK   RS_BrownMind2.Yum3
file     zscript/monsters/mastermind/RS_Mastermind.zs:611
shape    UNCLASSIFIED
payload  A_KillTarget("Extreme",KILS_FOILINVUL) + RS_BrownWarriorsStrifeFor (to the target) + 6x RS_RedMessMindB + 22x RS_MediCacoBrown
arc      --
timing   10 (face) / 0 (VileTarget) / 2 / 1 / 1 / 10 (kill) / 10 (heal) / 10 / 10
damage   INSTANT KILL -- A_KillTarget with KILS_FOILINVUL. No roll.
type     "Extreme"
sound    "CUCHUM01" x3 (:614, :622, :624)
impact   monster gains Health 500; target is yanked in by A_RadiusThrust(-800,302) then (-500,302), lifted by RS_BrownDinnerLift (FLOAT on, +30/4 Z thrust, 33 tics), then killed
trigger  Missile   (ORPHAN -- nothing in our tree or in CH jumps to YumYum, and no state falls through into it)
range    ..256   (Yum2's A_JumpIfCloser(256,"Yum3",true))
mirrored no
inherit  --
profile  MakeExecute(range:256, requires:"RS_EatableMind", pullForce:800, heal:500)
notes    DEAD CODE, and dead in CH too -- see UNRESOLVED. Kept as a row because
         it is a complete, distinctive mechanic (mark -> pull -> devour -> heal)
         and a parts bin should have it. RS_EatableMind is handed out by
         YumYum's A_RadiusGive at 526 units, which is also unreachable.
         RS_RedMessMindB is a +SEEKERMISSILE bishop-weaving mote with no
         Damage -- pure gore VFX.
```

**Brown, not rows.** `Death` (:655) spawns 12x `RS_CH_BoneGib` -- `Damage 0`,
cosmetic. `Idle`/`See`/`See2` spawn only `RS_ColorTierIconCH13`.

---

# CYAN -- RS_CyanMind2 (tier 12, "Cyanide Master(Mind)")

`Missile` -> `A_JumpIfCloser(1500,"FrostMode")`, else `A_Jump(255,"RapidFire")`.
`FrostMode` re-rolls: `A_Jump(64,"RapidFire")`, then `A_Jump(72,"Frost2")`.

```
ATTACK   RS_CyanMind2.RapidFire
file     zscript/monsters/mastermind/RS_Mastermind.zs:793
shape    BURST
payload  RS_SpiderCyanBomb x3 per cycle, loops on A_MonsterRefire(128)
arc      6   (0, then random(-3,3), then random(-1,1))
timing   5,5   (2+2+1 between shots; 4-tic A_FaceTarget opener)
damage   DamageFunction (random(11,44))
type     Ice
sound    --   (state is silent; the bomb's SeeSound "Spell/SpellCast1" plays at spawn)
impact   DeathSound "Fire/Fire4"; A_Explode(random(2,12),32) fires every 3rd flight tic as well -- it damages along its path, not only at the end
trigger  Missile   (>1500 units, or 25% of FrostMode entries)
range    1500..   (from Missile); also reachable inside 1500 via FrostMode's A_Jump(64)
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_SpiderCyanBomb", count:3, delayTics:5, arc:6)
notes    +SEEKERMISSILE with A_SeekerMissile(1,1) -- a very lazy homer, Speed 45.
         Sheds RS_FrostWingBaron trail. Two A_CheckSight("See") aborts sit
         between the shots, so the burst breaks if LOS is lost mid-volley.
         Defined at zscript/monsters/spider/RS_SpiderFX.zs:152.
```

```
ATTACK   RS_CyanMind2.FrostMode
file     zscript/monsters/mastermind/RS_Mastermind.zs:808
shape    BURST
payload  RS_IceOrbCyanMind x24
arc      2   (angle random(-1,1))
timing   1 x24   (24 tics), after a 10-tic face + 15-tic SUPS OPQ wind-up
damage   DamageFunction (random(5,55))
type     Ice
sound    A_PlayWeaponSound("fiend/bomb") at :806; the orb's own SeeSound "ice/Cast" x24
impact   DeathSound "Ice/Hit2"; ICEY FGHI 5 with A_Explode(random(5,40),64) on all four frames
trigger  Missile   (A_JumpIfCloser(1500,"FrostMode") at :788)
range    ..1500
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_IceOrbCyanMind", count:24, delayTics:1, arc:2)
notes    THE ORB DOES NOT FLY STRAIGHT. On spawn it A_Jumps into one of six
         orbit patterns (A1..A6) that A_Warp it around the PLAYER at 64 / 88 /
         128 units, stepping +/-7, +/-12 or +/-19 degrees per tic, with a
         12/256 chance per 3-tic cycle to break orbit and fly straight
         (RS_MastermindFX.zs:737-779). 24 of these builds a swarm that
         encircles you and then peels off one at a time. Scale 1.5.
```

```
ATTACK   RS_CyanMind2.Frost2
file     zscript/monsters/mastermind/RS_Mastermind.zs:814
shape    FAN
payload  RS_IceOrbCyanMind2 x27
arc      150   (-75..+75)
timing   3 x15, then 5 x8, then 7 x4   (45 + 40 + 28 = 113 tics)
damage   DamageFunction (random(5,55))   [inherited]
type     Ice   [inherited]
sound    A_PlayWeaponSound("fiend/bomb") at :812
impact   A_Explode(random(5,40),64) x4 frames, DeathSound "Ice/Hit2"   [both inherited]
trigger  Missile   (A_Jump(72,"Frost2") at :805, inside FrostMode)
range    ..1500
mirrored no
inherit  RS_IceOrbCyanMind -- the child overrides Spawn/Jumps ONLY, to skip the orbit patterns and go straight to Fly. Damage, type, sounds, scale, translation and the Death explosion all come from the parent (RS_MastermindFX.zs:786).
profile  MakeMulti( MakeFan(proj:"RS_IceOrbCyanMind2", count:15, arc:150, delayTics:3), MakeScatter(proj:"RS_IceOrbCyanMind2", count:8, coneDeg:10, delayTics:5), MakeBurst(proj:"RS_IceOrbCyanMind2", count:4, delayTics:7, arc:0) )
notes    Three phases, ONE attack. Phase 1 is a stepped sweep whose angle list
         is NOT monotone -- CH writes 0,15,-15,-30,30,-45,45,-60,-60,-75,75,
         -45,45,15,-15, with -60 twice and no +30-side mirror past +75. Kept
         verbatim; do not "tidy" it into an even sweep. Phase 2 is 8 shots at
         random(-5,5); phase 3 is 4 dead-ahead. A_CheckSight("See") aborts sit
         before phases 2 and 3.
```

**Cyan, not rows.** `See`/`Dodge`/`Jumps` shed `RS_CyanSpidTrail` and
`RS_BaronCyanBombTrail` -- both Damage 0. `Pain` is an `A_Teleport`. `Death`
spawns `RS_CH_Cirno` (an easter egg).

---

# ABYSS -- RS_AbyssMind2 (tier 9)

`Missile` -> `A_JumpIfCloser(1000,"Choice1")` else `Choice2`.
`Choice1` = MindSpike | MindWave | BigZap. `Choice2` = MindSpike | MindWave.

```
ATTACK   RS_AbyssMind2.MindSpike
file     zscript/monsters/mastermind/RS_Mastermind.zs:1002
shape    MULTI
payload  RS_AbyssMindSpike x3  +  RS_AbyssMindSpike2 x1
arc      --   (A_VileTarget; placed at the target)
timing   12,12,12 then 9
damage   both DamageFunction (random(1,10)) on contact -- the detonation is A_Explode(random(60,100),32) x3
type     "Getoutofmyheadcharles"
sound    A_PlaySound("queen/sight",7,2,false,ATTN_NONE) at :1000 -- map-wide, no attenuation
impact   Spike1: 10-tic tell, 3 staged A_Explode(random(60,100),32) as it scales 0.3->0.6->1.0 vertically, then Death spawns 3x RS_CrackedAbyssMindFall from 200 units up at random(-264,264) and random(-764,764) offsets. Spike2: identical but a 20-tic tell and NO Fall spawns.
trigger  Missile   (Choice1 or Choice2)
range    --   (both choosers reach it; Choice1 is gated at ..1000)
mirrored no
inherit  --
profile  MakeMulti( MakeRain(proj:"RS_AbyssMindSpike", count:3, delayTics:12, atTarget:true), MakeRain(proj:"RS_AbyssMindSpike2", count:1, delayTics:9, atTarget:true) )
notes    The two spikes differ ONLY in tell length (10 vs 20 tics) and whether
         they call down the ceiling drops. Both are +FLOORHUGGER +THRUACTORS
         until the moment they detonate, then A_SetSolid.
         RS_CrackedAbyssMindFall is random(10,60) Plasma and its own Death
         fires 64 RS_CrackedAbyssMind sparks in four 16-shot quadrant groups
         -- one spike can end up filling a room.
```

```
ATTACK   RS_AbyssMind2.BigZap
file     zscript/monsters/mastermind/RS_Mastermind.zs:1014
shape    MULTI
payload  RS_AbyssMindBigZap x1  +  RS_CrackedAbyssMindFloor x50  +  RS_CrackedAbyssMindFall x12
arc      360   (floor shards: mostly random(-359,359); three tight groups at random(-15,15) and two singles at random(-1,1))
timing   12 (the pillar), then two 50-tic ANIM sweeps of 10 frames x 5 tics, each bracketed by 0-tic shard dumps
damage   BigZap NONE; Floor DamageFunction (random(10,30)); Fall DamageFunction (random(10,60))
type     -- (BigZap) / Plasma (Floor, Fall)
sound    -- from the state; RS_CrackedAbyssMindFloor SeeSound "Crack/see" x50
impact   Floor: DeathSound "Crack/death"; each shard sheds RS_CrackedAbyssMind (random(1,6) Plasma + A_Explode(random(2,9),64)) as it slithers. Fall: drops from random(32,128) up, Death spawns 64 more RS_CrackedAbyssMind.
trigger  Missile   (Choice1 only)
range    ..1000
mirrored no
inherit  --
profile  MakeMulti( MakeSingle(proj:"RS_AbyssMindBigZap"), MakeScatter(proj:"RS_CrackedAbyssMindFloor", count:50, coneDeg:360, delayTics:0), MakeRain(proj:"RS_CrackedAbyssMindFall", count:12, delayTics:0, atTarget:false) )
notes    RS_AbyssMindBigZap has NO Damage and +DONTHARMCLASS +NOCLIP -- it is a
         150-tic ZPWV light pillar, the telegraph. All 62 damaging pieces come
         after it. The monster sets +NOPAIN for the whole sequence (:1015 on,
         :1029 off) and A_Wanders 28 steps before and 10 after.
         RS_CrackedAbyssMindFloor picks one of three travel patterns
         (A_CStaffMissileSlither / A_Weave(random(1,8),0,random(1,12),0) /
         straight) per shard, so 50 shards crawl the floor 50 different ways.
         Falls are placed at random(-1028,1028) then random(-1528,1528) --
         the second wave is deliberately wider than the first.
```

```
ATTACK   RS_AbyssMind2.MindWave
file     zscript/monsters/mastermind/RS_Mastermind.zs:1034
shape    SCATTER
payload  RS_AbyssMindWave x13
arc      100 at the widest   (random(-6,6), then (-20,20), then (-2,2), then (-20,20), then (-50,50))
timing   9,9 / one tic x3 / 9,9 / one tic x3 / one tic x3   (the cone widens as it goes)
damage   DamageFunction (random(30,80))
type     Melee
sound    --   (state is silent; the wave's SeeSound "queen/fire" plays x13)
impact   DeathSound "holy2/holy2"; ZPWV ABC/BA over 45 tics each spawning RS_CrackedAbyssMind, plus 12 white A_SpawnParticle bursts
trigger  Missile   (Choice1 or Choice2)
range    --
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_AbyssMindWave", count:13, coneDeg:100, delayTics:0)
notes    ProjectileKickback 9000 -- by a wide margin the hardest shove in the
         family; this is the wave's real function. In flight it loops shedding
         RS_AbyssMindWave2 (Alpha 0.05 expanding ring, no damage) and
         RS_AbyssShotIdentifier while pulsing its own scale 0.85 -> 0.60 ->
         0.85. An A_FaceTarget sits between the two 9-tic pairs, so the second
         half re-aims.
```

```
ATTACK   RS_AbyssMind2.Pain
file     zscript/monsters/mastermind/RS_Mastermind.zs:1049
shape    UNCLASSIFIED
payload  RS_WvileSpot x1
arc      --   (A_SpawnItemEx at random(-128,128) x random(-128,128), Z 1)
timing   one tic, once per Pain
damage   -- (the turret itself has none; it builds RS_WVileEye2/3 emplacements and RS_WhiteVileResser)
type     --
sound    --
impact   RS_WvileSpot is +INVULNERABLE, -SHOOTABLE, Speed 0, Health 9999, and cycles V1..V6 planting eye turrets on itself; it self-destructs after 20 Charge cycles
trigger  Pain
range    --
mirrored no
inherit  --
profile  MakeSummon(proj:"RS_WvileSpot", count:1, delayTics:0)
notes    Spawned with SXF_TRANSFERPOINTERS|SXF_SETMASTER and alpha 212, so it
         inherits the abyss mind's target. Defined in another family:
         zscript/monsters/archvile/RS_ArchvileFX.zs:2712 (CH Archviles.txt:4877).
         A Pain beat that plants a turret is exactly the "Pain beat that fires
         something" the spec asks for.
```

**Abyss, not rows.** `See`/`See2`/`See3` and every attack state shed
`RS_AbyssMindWalk` (a RandomSpawner over four Damage-0 decoration classes).
`Warp` is A_Wander repositioning plus two harmless `RS_CrackedAbyssMindFall`
-- those two ARE damaging (`random(10,60)`), so `Warp` is a marginal case; it is
recorded here rather than as a row because it is a reposition, not an attack,
and the Falls are placed on the monster's own old position.

---

# COMMON -- RS_CommonMind (tier 1)

```
ATTACK   RS_CommonMind.Missile
file     zscript/monsters/mastermind/RS_Mastermind.zs:1119
shape    HITSCAN
payload  A_SPosAttackUseAtkSound -- 3 hitscans per call, x2 calls = 6 per cycle
arc      ~22.5   (engine: angle + Random2 * (22.5/255), i.e. about +/-11.25)
timing   4,4 then 1 (A_SpidRefire), looping to Missile+1; 20-tic A_FaceTarget on entry only
damage   engine-internal: ((random % 5) + 1) * 3  =  3 / 6 / 9 / 12 / 15
type     Hitscan
sound    AttackSound "spider/attack" -- fired by the function itself, once per call
impact   default "BulletPuff"
trigger  Missile
range    --   (MISSILERANGE)
mirrored no
inherit  SpiderMastermind -- RS_CommonMind overrides only Spawn/See/Missile/Pain and the tier token; AttackSound, Health 3000, Radius 128, Height 100 and the Death/Raise chains are all the vanilla parent's
profile  MakeHitscan(pellets:3, damage:"((random%5)+1)*3", spreadXY:11.25, spreadZ:0, puff:"BulletPuff")   x2 per cycle
notes    The only unmodified vanilla attack in the family -- this is the stock
         Spider Mastermind chaingun. Written out in full anyway because the
         damage formula and the 22.5/255 spread are engine-internal and a
         player-weapon profile needs the numbers, not the function name.
         ENGINE SOURCE NOT VERIFIABLE THIS SESSION -- see UNRESOLVED.
```

---

# GRAY -- RS_GrayMind2 (tier 8, "Rocky Road Spider")

`Missile` -> `A_JumpIfCloser(1500,"BLECK")` -> `A_JumpIfHealthLower(4004,"BLECK2")`
-> falls into `Missile2`. `BLECK2` re-rolls `A_Jump(128,"Missile2","SpikeYou")`
then falls to `BLECK`.

```
ATTACK   RS_GrayMind2.Missile2
file     zscript/monsters/mastermind/RS_Mastermind.zs:1222
shape    HITSCAN
payload  A_CustomBulletAttack x4 calls: 2 bullets tight, then 5 bullets spread -- 14 bullets per cycle
arc      0 on the first 4 bullets (spread 0,0); 3 x 3 on the next 10
timing   1,1,1,1 then 1 (A_MonsterRefire(188,"See")), looping to Missile2; 2-tic face on entry
damage   random(1,8) per bullet -- and the engine multiplies by random(1,3) (no CBAF_NORANDOM), so 1..24
type     -- (no DamageType arg; the puff carries Fire)
sound    --   (the state plays nothing; RS_GrayCGuff has SeeSound "weapons/firex4" and +PUFFONACTORS so it is heard on every hit)
impact   puff RS_GrayCGuff -- see the row below; this puff is an attack
trigger  Missile   (>1500 units and health >4004)
range    1500..
mirrored no
inherit  SpiderMastermind (Missile2 is wholly RS_GrayMind2's own)
profile  MakeMulti( MakeHitscan(pellets:2, damage:"random(1,8)", spreadXY:0, spreadZ:0, puff:"RS_GrayCGuff"), MakeHitscan(pellets:5, damage:"random(1,8)", spreadXY:3, spreadZ:3, puff:"RS_GrayCGuff") )
notes    Two frames each, so 2x2 + 2x5 = 14 bullets per 7-tic loop. The engine's
         hidden random(1,3) damage multiplier on A_CustomBulletAttack is the
         difference between "8 max" and "24 max" and MUST carry into a profile.
```

```
ATTACK   RS_GrayCGuff.Melee   (secondary -- the hitscan puff's own payload)
file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:386
shape    RING
payload  RS_CGNail x12  (via RS_CGthing3)
arc      360   (fixed 30-degree steps: 15,45,75,105,...,345)
timing   all 12 on one tic, 5 tics after the puff lands
damage   A_Explode(random(1,12),64) from the puff itself; each nail DamageFunction (random(1,5))
type     Fire (puff) / Melee (nails)
sound    puff SeeSound "weapons/firex4"; nail AttackSound "moloch/nailhitbleed" (+SPAWNSOUNDSOURCE), DeathSound "weapons/firex4"
impact   nail Death: "moloch/nailhit" + A_Explode(random(1,3),16) on 9 frames + RS_PuffCybieRed
trigger  Missile   (as the puff of RS_GrayMind2.Missile2, above)
range    --
mirrored no
inherit  --
profile  MakeMulti( Explode(dmg:"random(1,12)", radius:64), MakeSalvo(proj:"RS_CGNail", count:12, arc:360) )
notes    EVERY ONE of Missile2's 14 bullets per cycle detonates like this. That
         is up to 168 nails a second at point-blank. This is why the gray mind
         reads as a shotgun and not a chaingun, and it is invisible if you read
         only the A_CustomBulletAttack line.
```

```
ATTACK   RS_GrayMind2.BLECK
file     zscript/monsters/mastermind/RS_Mastermind.zs:1229
shape    SCATTER
payload  RS_SpidieShotGray x9
arc      30 at the widest   (random(-3,3), (-5,5), (-13,13) x2, (-15,15) x2, (-10,10) x3; six of the nine also carry CMF_OFFSETPITCH|CMF_SAVEPITCH random(-10,10))
timing   1,1,1,1,1,1,0,0,3   (9 tics for all nine)
damage   DamageFunction (random(1,11))
type     Melee
sound    --   (the state is silent; the shot's SeeSound "moloch/nailhitbleed" plays x9)
impact   DeathSound "spike/spiked"; PUFI ABCD 2 + A_Explode(random(1,10),128) + 6 white particles -- and the IDENTICAL chain runs on Bounce, so a shot that bounces explodes and keeps going
trigger  Missile   (A_JumpIfCloser(1500,"BLECK") at :1217)
range    ..1500
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_SpidieShotGray", count:9, coneDeg:30, delayTics:1)
notes    BounceType "Hexen", BounceCount 3, BounceFactor 1, WallBounceFactor 1
         -- these do not slow down when they bounce, and each bounce is a free
         128-radius explosion. Speed 46. In a corridor nine shots become up to
         36 blasts. The state opens with A_Jump(128,"Needler") and closes with
         A_Jump(32,"SpikeYou"), so it is also the gateway to the other two.
```

```
ATTACK   RS_GrayMind2.Needler
file     zscript/monsters/mastermind/RS_Mastermind.zs:1242
shape    SALVO
payload  RS_GrayMindNeedle x4 per salvo, x3 salvos = 12
arc      --   (ALL FOUR FIRE DEAD AHEAD; the 12/-12/24/-24 are spawnofs_xy, not angles)
timing   4 needles on one tic; salvos 14 tics apart (8 face + 3 + 3)
damage   DamageFunction (random(10,50))
type     Melee
sound    AttackSound "moloch/nailhitbleed" with +SPAWNSOUNDSOURCE -- plays at the muzzle, x12
impact   DeathSound "spike/spiked"; Death plays "moloch/nailhit" then 6PUF ABCDEF
trigger  Missile   (A_Jump(128,"Needler") at :1228, inside BLECK)
range    ..1500
mirrored no
inherit  --
profile  MakeSalvo(proj:"RS_GrayMindNeedle", count:4, arc:0)   x3, delayTics:14, muzzleOfs:[+12,-12,+24,-24], muzzleZ:[64,64,132,132]
notes    THE TRAP IN THIS ROW: A_CustomMissile's args are
         (type, spawnheight, spawnofs_xy, angle, flags, pitch). CH passes only
         two numbers, so 64/12 is height 64 and lateral +12 -- the arc is zero
         and all twelve needles converge on the same aim point from four
         muzzles (two at chest height, two at 132 units up).
         The needle's flight is the point: it hangs 5 tics at Speed 5, then
         A_ScaleVelocity(3), then seeks with A_ScaleVelocity(5), (8), (10) on
         successive beats -- it drifts, then snaps. Scale (1.1,0.45) is set in
         BeginPlay because a non-uniform scale cannot live in a Default block.
```

```
ATTACK   RS_GrayMind2.SpikeYou
file     zscript/monsters/mastermind/RS_Mastermind.zs:1265
shape    SCATTER
payload  RS_MolochNail x46
arc      16   (angle random(-8,8), muzzleOfs random(-15,15), CMF_OFFSETPITCH|CMF_SAVEPITCH random(-5,5))
timing   1 x46   (46 tics), bracketed by 15-tic A_FaceTarget before and after
damage   DamageFunction (random(10,30))
type     Fire
sound    AttackSound "moloch/nailhitbleed" with +SPAWNSOUNDSOURCE, x46
impact   "moloch/nailhit" then A_Explode(random(2,10),64) on SIX frames then A_Explode(random(5,20),64) on THREE more, then RS_PuffCybieRed. DeathSound "weapons/firex4". +EXTREMEDEATH +BLOODSPLATTER +ROCKETTRAIL
trigger  Missile   (A_Jump(32,"SpikeYou") at :1236 inside BLECK, or A_Jump(128,"Missile2","SpikeYou") at :1270 inside BLECK2)
range    ..1500 via BLECK; BLECK2 is the health<4004 path
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_MolochNail", count:46, coneDeg:16, delayTics:1)
notes    46 is the exact length of CH's "GHGHGH...GH" frame string, counted, not
         estimated. Each nail's nine-frame A_Explode ladder is deliberate
         multi-frame explode (the "burn" pattern CLAUDE.md flags as
         intentional), so one nail is up to nine detonations.
         Defined in another family: zscript/monsters/cacodemon/RS_CacodemonFX.zs:169.
```

---

# FIREBLU -- RS_FireBluMind2 (tier 7, "It's horrifying!")

`Missile` -> `A_JumpIfCloser(1500,"Choices")`, else falls into the long-range
flame lay. `Choices` = Spam | GroundFlame.

```
ATTACK   RS_FireBluMind2.Missile
file     zscript/monsters/mastermind/RS_Mastermind.zs:1381
shape    RAIN
payload  RS_FireBluMindFlame1 x3
arc      --   (A_VileTarget; placed at the target)
timing   10,10   (5-tic A_CheckSight between each; 25-tic face + 10-tic roar on entry)
damage   DamageFunction (random(5,23))
type     Fire
sound    A_PlaySound("spider/sight") at :1379; the flame's own SeeSound "imp/attack" x3
impact   DeathSound "imp/shotx". The flame's Death is the attack: three batches of 7x RS_FireBluMindFlame2 scattered +/-128 units, interleaved with 22 frames of A_Explode(random(3,10),64). Each Flame2 then runs its own 11 frames of A_Explode(random(3,6),32) at random(5,15) Fire.
trigger  Missile   (the >1500 fall-through)
range    1500..
mirrored no
inherit  --
profile  MakeRain(proj:"RS_FireBluMindFlame1", count:3, delayTics:10, atTarget:true)
notes    3 seeds -> 21 secondary flames -> ~330 explode frames. This is a
         denial field, not a shot. Speed 1 and +THRUACTORS, so the seed does not
         travel; A_CheckSight("See") between each placement aborts the chain if
         you break LOS.
```

```
ATTACK   RS_FireBluMind2.GroundFlame
file     zscript/monsters/mastermind/RS_Mastermind.zs:1393
shape    SCATTER
payload  RS_FireBluMindFlame3 x3
arc      300 total, DELIBERATELY LOPSIDED   (random(-3,3) aimed, random(30,150) hard right, random(-150,30) hard left)
timing   2,0,2   (14-tic face + 2-tic face on entry)
damage   DamageFunction (random(5,15))
type     Fire
sound    --   (state silent; SeeSound "imp/attack" x3)
impact   DeathSound "imp/shotx"; Death drops 21 more RS_FireBluMindFlame2 in three batches of 7 plus 11 frames of A_Explode(random(3,9),64)
trigger  Missile   (Choices -> GroundFlame)
range    ..1500
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_FireBluMindFlame3", count:3, coneDeg:300, delayTics:2)
notes    Not a fan -- one shot at you and two flanking sweeps that can go almost
         behind the monster. +FLOORHUGGER +SEEKERMISSILE: they hug the ground
         and A_SeekerMissile(6,3) back onto you, so the wide two curve in.
         In flight each drops 3 Flame2 per 2-tic cycle AND runs
         A_Explode(random(3,12),64) -- the flame trail damages while it travels.
         Scale (1.5,0.7), set in BeginPlay.
```

```
ATTACK   RS_FireBluMind2.Spam
file     zscript/monsters/mastermind/RS_Mastermind.zs:1401
shape    SCATTER
payload  RS_FireBCGguy x3
arc      70 at the widest   (random(-3,3), random(-15,15), random(-35,35))
timing   2,0,2 then 1 (A_MonsterRefire(188,"See")); loops to Missile+1, which re-runs the range test
damage   DamageFunction (random(5,20))
type     Fire
sound    --   (state silent; SeeSound "imp/attack" x3)
impact   DeathSound "imp/shotx"; Death = FIRE FGH 6 with A_Explode(random(5,15),64) on all three. In FLIGHT it loops FIRE CDEEDCDE 3 with A_Explode(random(4,15),64) on all eight frames -- a burning trail, not a clean projectile.
trigger  Missile   (Choices -> Spam)
range    ..1500
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_FireBCGguy", count:3, coneDeg:70, delayTics:2)
notes    Speed 45 but FastSpeed 26 -- it gets SLOWER on fast-monsters skills,
         which is CH's own inversion and is kept. Widening cone: aimed, then
         loose, then wild. Defined at
         zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:455.
```

---

# GREEN -- RS_GreenMind (tier 2)

```
ATTACK   RS_GreenMind.Missile
file     zscript/monsters/mastermind/RS_Mastermind.zs:1487
shape    BURST
payload  RS_SpidieShot1 x2 per cycle
arc      10   (random(-3,3) then random(-5,5))
timing   2,2 then 1 (A_MonsterRefire(188,"See")); loops to Missile+1. 20-tic face on first entry only.
damage   DamageFunction (random(3,8))
type     Poison
sound    --   (state silent; SeeSound "spider/attack" per shot)
impact   DeathSound "imp/shotx"; BAL1 CD 4 then a 128/256 coin flip -- half the time it drops RS_Gas14, a lingering poison cloud, at random(-5,5)/(-8,8)/(-1,7)
trigger  Missile
range    --
mirrored no
inherit  SpiderMastermind
profile  MakeBurst(proj:"RS_SpidieShot1", count:2, delayTics:2, arc:10)
notes    Speed 65 / FastSpeed 80 and Scale 0.15 -- a fast, tiny tracer. The
         50% gas cloud is the whole character of the shot and is written
         nowhere near the attack (RS_MastermindFX.zs:1476).
```

```
ATTACK   RS_GreenMind.Sweep
file     zscript/monsters/mastermind/RS_Mastermind.zs:1494
shape    FAN
payload  RS_SpidieShot1 x33
arc      16   (+8 down to -8 in 1-degree steps, then back up to +8 -- a full there-and-back windscreen wipe)
timing   2 x33   (66 tics)
damage   DamageFunction (random(3,8))
type     Poison
sound    --
impact   as above: DeathSound "imp/shotx", 50% RS_Gas14
trigger  Missile   (A_Jump(32,"Sweep") at :1489)
range    --
mirrored no   (the sweep already contains its own mirror -- +8..-8..+8)
inherit  SpiderMastermind
profile  MakeFan(proj:"RS_SpidieShot1", count:33, arc:16, delayTics:2)
notes    17 shots down, 16 back. Exactly 33 A_CustomMissile lines, counted
         against CH's 33 (MASTERMINDS.txt:2403-2435). The 1-degree step and the
         2-tic cadence make this the tightest, longest sustained fan in the
         family -- a wall, not a spray. Ends on A_MonsterRefire(188,"See").
```

---

# BLUE -- RS_BlueMind (tier 3, "Frosty Blue Spider MasterMind")

`Missile` -> `A_JumpIfCloser(420,"FrostBreath")` -> `A_JumpIfHealthLower(2650,"OrMaybe")`
-> `A_JumpIfCloser(1200,"FrostOrbs")` -> `A_Jump(255,"LongFrost")`.
`OrMaybe` = LongFrost2 | FrostOrbs. Both FrostBreath and FrostOrbs first run
`A_JumpIfHigherOrLower("HighShot",null,28,0,true)`.

```
ATTACK   RS_BlueMind.FrostBreath
file     zscript/monsters/mastermind/RS_Mastermind.zs:1624
shape    BURST
payload  RS_FrostMind x2
arc      14   (random(-3,3) then random(-7,7))
timing   1,2 then 1 (A_MonsterRefire(80,"See")); loops to Missile+1
damage   DamageFunction (random(5,12))
type     Ice
sound    A_PlaySound("Ice/Inhale",0,1.5) at :1621 -- volume 1.5, an audible inhale tell
impact   SeeSound "ice/Breath", DeathSound "Ice/Splode". Spawn AND Death both run A_Explode(random(3,13),20) over 4 frames each -- it damages from the muzzle onward, 8 explode frames per puff.
trigger  Missile   (A_JumpIfCloser(420,"FrostBreath"))
range    ..420
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_FrostMind", count:2, delayTics:2, arc:14)
notes    Speed 19, +THRUACTORS, Scale 1.1 -- a slow cone of cold that passes
         through bodies. The refire chance is 80 (vs 188 elsewhere), so the
         point-blank breath re-triggers far more readily.
```

```
ATTACK   RS_BlueMind.HighShot
file     zscript/monsters/mastermind/RS_Mastermind.zs:1630
shape    SALVO
payload  RS_IceOrb x3
arc      14   (0, -7, +7)
timing   all three on one tic, after a 6-tic cast
damage   DamageFunction (random(10,55))
type     Ice
sound    A_PlaySound("Spell/SpellCast1",1,3) at :1629 -- volume 3
impact   SeeSound "ice/Cast", DeathSound "Ice/Hit2", BounceSound "Ice/Splode". Death: A_SetScale(3.5) then ICEY FGHI 5 with A_Explode(random(6,12),64) on all four, plus 11 blue particles.
trigger  Missile   (A_JumpIfHigherOrLower("HighShot",null,28,0,true) from FrostBreath :1623 or FrostOrbs :1636)
range    --   (the gate is a HEIGHT difference of 28+, not a distance)
mirrored no
inherit  --
profile  MakeSalvo(proj:"RS_IceOrb", count:3, arc:14)   lobbed: velX random(6,12), velZ random(6,14)
notes    The ONLY lobbed attack in the family. A_SpawnItemEx, not
         A_CustomMissile -- CH hands it explicit X and Z velocities so the orbs
         arc up and over, which is why this is the answer to a target 28+ units
         above or below. BounceType "Doom", BounceCount 7, BounceFactor 1.5
         (they bounce HIGHER each time), WallBounceFactor 0.2, +SEEKERMISSILE
         with A_SeekerMissile(6,6) and A_ScaleVelocity(1.5) per cycle.
         Scale 2, so they read as beach balls.
```

```
ATTACK   RS_BlueMind.FrostOrbs
file     zscript/monsters/mastermind/RS_Mastermind.zs:1638
shape    SALVO
payload  RS_IceOrb x3
arc      10   (random(-5,5), random(-5,5), random(-1,1))
timing   all three on one tic, after a 6-tic face and a 6-tic cast
damage   DamageFunction (random(10,55))
type     Ice
sound    A_PlaySound("Spell/SpellCast1",1,3) at :1637
impact   as HighShot
trigger  Missile   (A_JumpIfCloser(1200,"FrostOrbs") at :1614, or OrMaybe)
range    420..1200
mirrored no
inherit  --
profile  MakeSalvo(proj:"RS_IceOrb", count:3, arc:10)   muzzleOfs:[-32,+32,0], muzzleZ:[52,52,36]
notes    Same payload as HighShot, fired FLAT from three muzzles (two shoulder
         mounts at 52 units and +/-32 lateral, one low centre at 36) instead of
         lobbed. Ends on A_Jump(128,"Missile") -- half the time it immediately
         re-rolls the whole range ladder.
```

```
ATTACK   RS_BlueMind.LongFrost
file     zscript/monsters/mastermind/RS_Mastermind.zs:1645
shape    BURST
payload  RS_FrostLong x2
arc      12   (random(-1,1) then random(-6,6))
timing   2,2 then 1 (A_MonsterRefire(80,"See")); loops to Missile+1
damage   DamageFunction (random(5,12))
type     Ice
sound    --   (RS_FrostLong has NO SeeSound; it plays "Ice/Fly" from its own Spawn loop instead)
impact   DeathSound "Ice/Hit2"; PUFI ABCD/EFGH 1 -- 8 frames, no explosion
trigger  Missile   (A_Jump(255,"LongFrost") at :1615 -- the >1200 default)
range    1200..
mirrored no
inherit  --   (RS_FrostLong itself is the parent class; it is defined in another family, zscript/monsters/imp/RS_ImpFX.zs:246, CH MASTERMINDS.txt:2610)
profile  MakeBurst(proj:"RS_FrostLong", count:2, delayTics:2, arc:12)
notes    Speed 76 -- the fastest projectile in the family by a wide margin,
         and +SEEKERMISSILE with A_SeekerMissile(8,8) on top. Scale 0.3.
         The 4-frame Spawn loop (seek / play "Ice/Fly" / A_Weave(1,1,2,1) /
         idle) gives it a shimmer as it goes.
```

```
ATTACK   RS_BlueMind.LongFrost2
file     zscript/monsters/mastermind/RS_Mastermind.zs:1651
shape    BURST
payload  RS_FrostLong x2
arc      30   (random(-1,1) then random(-15,15))
timing   2,2 then 1 (A_MonsterRefire(70,"See")); LOOPS TO ITSELF, not to Missile
damage   DamageFunction (random(5,12))
type     Ice
sound    --
impact   DeathSound "Ice/Hit2"
trigger  Missile   (OrMaybe, at :1618 -- the health<2650 path)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_FrostLong", count:2, delayTics:2, arc:30)
notes    The wounded version of LongFrost: wider second shot (15 vs 6), a
         hungrier refire (70 vs 80), and `Goto LongFrost2` instead of
         `Goto Missile+1` so it never re-checks range. Below half health the
         blue mind locks into this and does not stop.
```

---

# PURPLE'S BABY -- RS_SpecialSpider1

```
ATTACK   RS_SpecialSpider1.Missile   (inherited)
file     zscript/monsters/spider/RS_Spider.zs:478
shape    SINGLE
payload  RS_PlasmaBallSP3 x1 per cycle
arc      2   (random(-1,1))
timing   4 then 3 (A_MonsterRefire(128,"See")); loops to Missile+1; 20-tic face on first entry
damage   Damage 5 -- bare, so the engine rolls it x random(1,8) = 5..40
type     Plasma
sound    --   (state silent; SeeSound "weapons/plasmaf")
impact   DeathSound "weapons/plasmax"; PLSE ABCDE 4, no explosion
trigger  Missile
range    --
mirrored no
inherit  RS_BlueSP1 (zscript/monsters/spider/RS_Spider.zs:425) -- RS_SpecialSpider1 overrides Spawn/See ONLY. Missile, Pain, Death, Raise, the arachnotron sounds and the plasma ball all come from the blue arachnotron.
profile  MakeSingle(proj:"RS_PlasmaBallSP3")
notes    THE ONLY ROW IN THIS FAMILY WHOSE ATTACK STATE IS NOT IN
         RS_Mastermind.zs. RS_SpecialSpider1 declares one state label (`See:`)
         and nothing else; reading the class body alone reports "no attack".
         Its own See does A_JumpIfMasterCloser(1000,"See") then
         A_Warp(AAPTR_MASTER,...) -- it teleports back to the purple mind if it
         strays past 1000 units, so it is a leashed escort, not a free minion.
         Health 350, RenderStyle "Add", Alpha 0.95, -COUNTKILL.
```

---

# PURPLE -- RS_PurpleMind (tier 4)

`Missile` -> `A_JumpIf(user_ragemind>=10,"RageSummon")` ->
`A_JumpIfCloser(1000,"PewPew")` -> `A_Jump(255,"HitScanHell","Borb")`.
`PewPew` = PewPew2 | Borb, then PewPew2 | HitScanHell.

```
ATTACK   RS_PurpleMind.PewPew2
file     zscript/monsters/mastermind/RS_Mastermind.zs:1805
shape    SINGLE
payload  RS_DemoMissile x1
arc      --
timing   one shot, after 12-tic face + 8-tic roar; 10-tic recovery + 10 idle
damage   Damage 20 -- bare, so the engine rolls it x random(1,8) = 20..160
type     Fire
sound    A_PlaySound("Spider/Sight") at :1804; the rocket's SeeSound "weapons/rocklf"
impact   DeathSound "weapons/rocklx". Death is a cluster bomb: 8x RS_BaronStar4 shrapnel at random(0,360) angle AND random(0,360) pitch, interleaved with A_Explode(random(5,30),165) / (15,30) / (10,30) -- radius 165, one of the largest in the family. Each BaronStar4 is random(5,30) Fire with its own A_Explode(random(10,30),165) x2 and (10,45) x3.
trigger  Missile   (PewPew branch, <1000 units)
range    ..1000
mirrored no
inherit  SpiderMastermind
profile  MakeSingle(proj:"RS_DemoMissile")
notes    +DEHEXPLOSION, so the base blast uses the Dehacked values, and the
         A_Explode calls stack on top. +ROCKETTRAIL and it fires
         RS_SparkPuff1 every flight tic at random 360/360. Species "MMind3"
         and +THRUSPECIES: it passes through the purple mind's own babies.
         Ends on A_Jump(88,"Missile") -- a 34% chance to immediately re-roll.
```

```
ATTACK   RS_PurpleMind.HitScanHell
file     zscript/monsters/mastermind/RS_Mastermind.zs:1812
shape    HITSCAN
payload  A_CustomBulletAttack x4 calls per cycle
arc      8x8, then 5x5, then 12x12, then 2x2   (spread_xy = spread_z on all four -- a square, not a line)
timing   0,4,0,4 then 1 (A_SpidRefire); loops to HitScanHell; 5-tic face on entry
damage   random(1,2) per bullet, x the engine's random(1,3) = 1..6 per bullet; random(1,7) bullets per call
type     -- (no DamageType; default puff)
sound    A_PlaySound("spider/attack") FIVE times, once before each call and once more at :1819
impact   default "BulletPuff"
trigger  Missile   (A_Jump(255,"HitScanHell","Borb") at :1796, or PewPew)
range    --
mirrored no
inherit  SpiderMastermind
profile  MakeMulti( MakeHitscan(pellets:"random(1,7)", damage:"random(1,2)", spreadXY:8, spreadZ:8, puff:"BulletPuff"), MakeHitscan(pellets:"random(1,7)", damage:"random(1,2)", spreadXY:5, spreadZ:5, puff:"BulletPuff"), MakeHitscan(pellets:"random(1,7)", damage:"random(1,2)", spreadXY:12, spreadZ:12, puff:"BulletPuff"), MakeHitscan(pellets:"random(1,7)", damage:"random(1,2)", spreadXY:2, spreadZ:2, puff:"BulletPuff") )
notes    4..28 bullets per 9-tic loop, each 1..6 damage. Low per-pellet, high
         volume, and the spread REROLLS every call (8 -> 5 -> 12 -> 2), so the
         group tightens and loosens inside a single burst. This is the one
         hitscan in the family with no custom puff.
```

```
ATTACK   RS_PurpleMind.Borb
file     zscript/monsters/mastermind/RS_Mastermind.zs:1824
shape    BURST
payload  RS_OrbPurpleMind x24
arc      2   (angle random(-1,1); the +/-12 is spawnofs_xy -- twin muzzles, NOT a fan)
timing   2,3 alternating x24 (about 60 tics), with 3-tic A_FaceTarget re-aims after shot 6 and shot 18
damage   DamageFunction (random(10,30))
type     Plasma
sound    --   (state silent; SeeSound "Weapons/Plasmaf" x24)
impact   DeathSound "weapons/plasmax"; A_SetScale(0.4) then BAL1 CDE 6 -- no explosion
trigger  Missile   (A_Jump(255,"HitScanHell","Borb") at :1796, or PewPew's A_Jump(64,"PewPew2","Borb"))
range    --
mirrored no
inherit  SpiderMastermind
profile  MakeBurst(proj:"RS_OrbPurpleMind", count:24, delayTics:2.5, arc:2)   muzzleOfs alternating [-12,+12]
notes    Counted line by line: 24, not 22. The muzzle alternation is NOT a
         clean left-right -- CH's sequence is -12,+12,-12,+12,-12,-12 |
         -12,+12,+12,-12,+12,-12,-12,+12,-12,+12,-12,-12 | -12,+12,+12,-12,
         +12,-12. Kept verbatim; it makes the stream visibly stutter.
         Every orb runs A_BishopMissileWeave EVERY tic and is +FLOATBOB, so a
         24-orb stream corkscrews. Scale 0.25, trails RS_OrbPurpMindTrail.
```

```
ATTACK   RS_PurpleMind.RageSummon
file     zscript/monsters/mastermind/RS_Mastermind.zs:1855
shape    UNCLASSIFIED
payload  RS_SpecialSpider1 x4
arc      --   (spawn offsets (0,-5), (0,+5), (+5,-5), (-5,+5), Z 6)
timing   4,4,4,4   (after 12-tic roar + 8 + 12-tic second roar)
damage   -- (the babies carry it; see RS_SpecialSpider1.Missile)
type     --
sound    A_PlaySound("Spider/Sight") at :1852 and :1854
impact   SXF_SETMASTER -- the babies leash to the purple mind and warp back if they stray past 1000 units
trigger  Missile   (A_JumpIf(user_ragemind >= 10) at :1794)
range    --
mirrored no
inherit  --
profile  MakeSummon(proj:"RS_SpecialSpider1", count:4, delayTics:4)
notes    THE GATE IS A PAIN COUNTER, NOT A TIMER OR A HEALTH THRESHOLD.
         `user_ragemind` increments by 1 in Pain (:1863) and is decremented by
         8 here (:1859), so the purple mind summons after being hurt 10 times
         and can do it again after 8 more. Four more spawn free at Spawn
         (:1772-1775). It is +NOPAIN for the whole summon.
```

---

# YELLOW -- RS_YellowMind (tier 5)

`Missile` -> `A_JumpIfHealthLower(3500,"Halp")` -> `A_JumpIfCloser(500,"BFGd")`
-> `A_JumpIfCloser(2000,"OrMaybe")` -> `A_Jump(255,"Homers")`.
`OrMaybe` = Homers | PlasmaSpam | RapidPlasma. `RapidPlasma` = HitIt | HitIt2.

```
ATTACK   RS_YellowMind.Halp
file     zscript/monsters/mastermind/RS_Mastermind.zs:1966
shape    UNCLASSIFIED
payload  RS_YellowSP1 x4
arc      --   (offsets (0,-55,+56), (0,+55,-56), (0,-25,+26), (0,+25,-26))
timing   4,4,4,4   (after a 12-tic cry and a 24-tic charge)
damage   -- (the yellow arachnotrons carry their own)
type     --
sound    A_PlaySound("fiend/see") at :1964
impact   SXF_SETMASTER
trigger  Missile   (A_JumpIfHealthLower(3500,"Halp"))
range    --
mirrored no
inherit  --
profile  MakeSummon(proj:"RS_YellowSP1", count:4, delayTics:4)
notes    ONE-SHOT. `user_halpme` gates it (:1963) and is incremented at :1972,
         so this fires exactly once per yellow mind, ever; every later attempt
         falls through `Nah` to `Missile+4`. It also permanently sets
         +MISSILEEVENMORE (:1965) -- the panic summon is also a permanent rate
         buff. +THRUACTORS is set for the summon window (:1970) and cleared at
         :1973 so the drones can be pushed out through its own body.
         RS_YellowSP1 is defined at zscript/monsters/spider/RS_Spider.zs:652.
```

```
ATTACK   RS_YellowMind.PlasmaSpam
file     zscript/monsters/mastermind/RS_Mastermind.zs:1983
shape    BURST
payload  RS_FiendPlasmaBall x3
arc      16   (0, random(-3,3), random(-8,8))
timing   5,5   (2+2+1 between shots; two 6-tic faces on entry)
damage   DamageFunction (random(10,35))
type     Plasma
sound    A_PlaySound("fiend/hover") at :1979 and :1981; SeeSound "Weapons/Plasmaf" x3
impact   DeathSound "Weapons/Plasmax"; APBX ABCDE 4, no explosion of its own
trigger  Missile   (OrMaybe)
range    500..2000
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_FiendPlasmaBall", count:3, delayTics:5, arc:16)
notes    The ball trails RS_TrailSP EVERY flight tic, and RS_TrailSP is not
         decoration -- its Death runs A_Explode(10,32) on FIVE frames, so the
         flight path is lined with 50 points of splash. Two A_SpidRefire calls
         sit between the shots, so the burst can cut short. Decal
         "ArachnotronScorch". Ends `Goto Missile` -- a full re-roll.
```

```
ATTACK   RS_YellowMind.BFGd
file     zscript/monsters/mastermind/RS_Mastermind.zs:2000
shape    SALVO
payload  RS_FiendPlasmaBall x5
arc      24   (0, -6, +6, -12, +12)
timing   all five on ONE tic, after a long tell: 8-face, 8-face, 8-charge, 10, 10
damage   DamageFunction (random(10,35))
type     Plasma
sound    A_PlayWeaponSound("fiend/bfg") at :1997 -- the tell
impact   DeathSound "Weapons/Plasmax"; plus the RS_TrailSP splash line, x5
trigger  Missile   (A_JumpIfCloser(500,"BFGd") at :1955)
range    ..500
mirrored no
inherit  --
profile  MakeSalvo(proj:"RS_FiendPlasmaBall", count:5, arc:24)
notes    44 tics of wind-up for one instantaneous 5-shot spread -- the longest
         tell-to-payload ratio in the family, and the reason it is the
         point-blank answer. Ends A_Jump(128,"PlasmaSpam","RapidPlasma"), so it
         chains straight into another attack half the time.
```

```
ATTACK   RS_YellowMind.HitIt
file     zscript/monsters/mastermind/RS_Mastermind.zs:2014
shape    BURST
payload  RS_PlasmaBallSP3 x6
arc      22 at the widest   (pair 1 random(-11,1) / random(-1,11); pair 2 random(1,5) / random(-5,-1); pair 3 +1 / -1)
timing   pairs on one tic each, 3 tics apart (1+1+1); loops on itself
damage   Damage 5 -- bare, engine rolls x random(1,8) = 5..40
type     Plasma
sound    A_PlayWeaponSound("fiend/bomb") at :2009; SeeSound "weapons/plasmaf" x6
impact   DeathSound "weapons/plasmax"; PLSE ABCDE 4
trigger  Missile   (RapidPlasma, reached from OrMaybe)
range    500..2000
mirrored yes   (each pair is a mirrored L/R shot from muzzles at +20 and -20 lateral; HitIt2 below is the same state with a different payload)
inherit  --
profile  MakeBurst(proj:"RS_PlasmaBallSP3", count:6, delayTics:3, arc:22)   muzzleOfs:[+20,-20] per pair
notes    Three converging pairs: wide, then narrow, then dead-on. The +/-20 is
         spawnofs_xy. The state ends A_CheckSight("StopIt"),
         A_Jump(64,"HitIt2") -- so it can swap payload mid-stream -- then
         A_CheckFlag("SOLID","HitIt",AAPTR_TARGET), which loops it back only
         while the target is solid.
```

```
ATTACK   RS_YellowMind.HitIt2
file     zscript/monsters/mastermind/RS_Mastermind.zs:2031
shape    BURST
payload  RS_AracnorbBall x6
arc      22   (identical angle table to HitIt)
timing   pairs on one tic each, 3 tics apart; loops on itself
damage   DamageFunction (random(10,50))
type     -- (no DamageType; +STRIFEDAMAGE)
sound    SeeSound "baby/attack" x6
impact   DeathSound "baby/shotx"; ACNF CDEFG 5, no explosion
trigger  Missile   (RapidPlasma's A_Jump(128,"HitIt2") at :2011, or HitIt's A_Jump(64,"HitIt2") at :2026)
range    500..2000
mirrored yes
inherit  --
profile  MakeBurst(proj:"RS_AracnorbBall", count:6, delayTics:3, arc:22)   muzzleOfs:[+20,-20] per pair
notes    Structurally identical to HitIt, DIFFERENT PAYLOAD -- so it is its own
         row, not a `mirrored: yes` variant of HitIt. Speed 11 (vs 25) and
         +SEEKERMISSILE with A_BishopMissileWeave every tic: slow, weaving,
         homing, and much harder-hitting. The two states cross-jump into each
         other at 64/256 per cycle, so a sustained volley mixes both.
         Defined at zscript/monsters/spider/RS_SpiderFX.zs:911.
```

```
ATTACK   RS_YellowMind.Homers
file     zscript/monsters/mastermind/RS_Mastermind.zs:2053
shape    BURST
payload  RS_RemoteBombV2 x6
arc      90 down to 30   (pairs at +/-45, then +/-33, then +/-15)
timing   pairs on one tic, 16 tics apart; 10-tic face + 21-tic OPQ tell on entry
damage   DamageFunction (random(5,45))
type     Fire
sound    A_PlayWeaponSound("fiend/bomb") at :2051, :2056 and :2060 -- once per pair
impact   Death: A_PlaySound("prox/beep") + A_Explode(random(10,50),128) + DeathSound "weapons/rocklx"
trigger  Missile   (A_Jump(255,"Homers") at :1957 -- the >2000 default -- or OrMaybe)
range    2000..   (also reachable at 500..2000 via OrMaybe)
mirrored yes   (every pair is a symmetric L/R launch from muzzles at +20 / -20)
inherit  --
profile  MakeBurst(proj:"RS_RemoteBombV2", count:6, delayTics:16, arc:90)   muzzleOfs:[+20,-20] per pair
notes    THE ANGLES CLOSE IN, THE PAIRS DO NOT CONVERGE ON YOU -- they are
         launched sideways at 45 degrees and then hunt: A_SeekerMissile(9,18)
         fires four times per 12-tic Spawn loop, the hardest homing in the
         family. SeeSound "prox/fire" and AttackSound "prox/beep" make the
         approach audible. +FLOATBOB, trails RS_BuffTrailSP.
```

---

# RED -- RS_RedMind (tier 6)

`Missile` -> `A_JumpIf(user_phase2>=1,"Phase2Jumps")` ->
`A_JumpIfHealthLower(5000,"Phase2")` ->
`A_Jump(255,"Chaingunlasers","Blobs","FireWave")`.
`Phase2Jumps` -> `A_JumpIfCloser(1500,"Phase2Jumps2")` else Chaingunlasers.
`Phase2Jumps2` = Chaingunlasers2 | Blobs | FireWave | GroundHogs.

```
ATTACK   RS_RedMind.Chaingunlasers
file     zscript/monsters/mastermind/RS_Mastermind.zs:2235
shape    HITSCAN
payload  A_CustomRailgun(random(2,10),0,"none","red",RGF_FULLBRIGHT,1,12,"none",0,0,0,34,1,15,"none",0) x2 per cycle
arc      0   (spread_xy 0, spread_z 0; aim=1 and maxdiff=12 -- it snaps onto the target within 12 units)
timing   5,5 then 2 (A_MonsterRefire(128,"See")); loops to Chaingunlasers+1; 5-tic BABAB face on entry
damage   random(2,10) per rail
type     -- (no DamageType; puff is "none")
sound    A_PlaySound("arachnophyte/engine") at :2234
impact   NO PUFF AND NO SPAWNCLASS -- CH passes "none" for both. Only the red RGF_FULLBRIGHT beam, duration 34, sparsity 1, driftspeed 15.
trigger  Missile
range    --   (range arg 0 = unlimited)
mirrored no
inherit  --
profile  MakeRailgun(damage:"random(2,10)", puff:"none", spawnClass:"none", duration:34)   x2, delayTics:5
notes    Low damage, INSTANT, unlimited range, auto-aiming (aim=1, maxdiff=12),
         and it loops. This is the red mind's chip weapon and the reason it is
         dangerous across an open map. It ends A_Jump(24,"Blobs") -- a 9%
         chance to drop mines instead of refiring.
         `Chaingunlasers2` (:2202) is the SAME railgun with the SAME arguments,
         reachable only in phase 2, and differs only in that its bail-to-Blobs
         chance is A_Jump(64) instead of A_Jump(24). Not a second row.
```

```
ATTACK   RS_RedMind.Phase2
file     zscript/monsters/mastermind/RS_Mastermind.zs:2211
shape    UNCLASSIFIED
payload  RS_RedMessImp x12
arc      360   (CMF_AIMOFFSET with angle random(0,360) and pitch random(0,360))
timing   4 x12   (48 tics), inside a ~100-tic transformation
damage   NONE -- RS_RedMessImp has no Damage property
type     --
sound    A_PlaySound("arachnophyte/sight") at :2207
impact   -- (Scale 0.3 Add-blend gore mote, fades and stops)
trigger  Missile   (A_JumpIfHealthLower(5000,"Phase2") at :2188)
range    --
mirrored no
inherit  --
profile  PhaseChange(vfx:"RS_RedMessImp", count:12, missileEvenMore:true, then:"GroundHogs")
notes    A ROW THAT DOES NO DAMAGE, KEPT BECAUSE IT IS THE FIGHT'S TURNING
         POINT. It sets +MISSILEEVENMORE permanently (:2208), increments
         `user_phase2` (:2213) so it can never repeat, and falls straight into
         GroundHogs. From then on Missile routes through Phase2Jumps, which
         unlocks Chaingunlasers2 and GroundHogs. Reading only the payload
         ("12 missiles!") reports an attack that is entirely cosmetic.
```

```
ATTACK   RS_RedMind.GroundHogs
file     zscript/monsters/mastermind/RS_Mastermind.zs:2218
shape    SCATTER
payload  RS_RedMindRingNew x5
arc      128   (angle random(-64,64); muzzleOfs random(-32,32); spawnheight 0 -- launched off the floor)
timing   6 x5   (after 10-tic face + 6-tic face)
damage   DamageFunction (random(30,90))
type     Melee
sound    --   (state silent; SeeSound "Fire/fire3" x5)
impact   Bounce.Wall -> Death: A_Stop then 4x RS_SpiralSawMind3, each A_Explode(random(5,20),88) on NINE frames
trigger  Missile   (Phase2Jumps2, or the fall-through from Phase2)
range    ..1500   (Phase2Jumps2 gate)
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_RedMindRingNew", count:5, coneDeg:128, delayTics:6)
notes    THE MOST COMPLEX PROJECTILE IN THE FAMILY. Speed 1 and Gravity 10 at
         launch, +SEEKERMISSILE with A_SeekerMissile(99,99) -- effectively
         instant turn -- for three frames, THEN A_ScaleVelocity(random(8,12))
         snaps it to speed. In flight it toggles +FLOORHUGGER on and off every
         cycle to hop over lips, runs A_Explode(random(20,60),32) every other
         tic, sheds RS_GroundRedCyb, and accelerates by frandom(1.5,2) per
         cycle. BounceType "Hexen", BounceCount 999, BounceFactor 0.5 on
         floors; a WALL bounce kills it into the saw burst.
         Mass 999999 + +DONTBLAST + +DONTTHRUST: nothing can push it.
```

```
ATTACK   RS_RedMind.FireWave
file     zscript/monsters/mastermind/RS_Mastermind.zs:2223
shape    SCATTER
payload  RS_SpiralSawMind1 x7
arc      64   (angle random(-32,32); muzzleOfs random(-32,32); height 18)
timing   6 x7   (after 10-tic face + 6-tic face)
damage   DamageFunction (random(10,60))
type     Fire
sound    --   (state silent; SeeSound "Weapons/BFGF" x7)
impact   DeathSound "Fire/Fire4"; Death scatters 5x RS_SpiralSawMind2 at random(-128,128) offsets, each A_Explode(random(10,20),88) on NINE frames
trigger  Missile   (A_Jump(255,"Chaingunlasers","Blobs","FireWave") at :2189, or Phase2Jumps2)
range    --
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_SpiralSawMind1", count:7, coneDeg:64, delayTics:6)
notes    Each saw seeks with A_SeekerMissile(1,1), fires 5x RS_SparkPuff1 at
         random 360/360 per cycle, and A_Weave(5,1,7,1) -- it spirals visibly.
         7 saws -> 35 secondary spiral bursts -> 315 explode frames.
```

```
ATTACK   RS_RedMind.Blobs
file     zscript/monsters/mastermind/RS_Mastermind.zs:2229
shape    UNCLASSIFIED
payload  RS_RedMindBomb x5
arc      --   (A_SpawnItemEx at random(-60,60) x random(-60,60), Z random(-15,40) -- placed around the RED MIND, not the target)
timing   6 x5   (after 10-tic face + 8 + 8)
damage   -- (the mines carry it; see the two RS_RedMindBomb rows below)
type     --
sound    --   (the mine's SeeSound "prox/fire" fires when it wakes)
impact   the mines are live monsters with Health 20 that hunt on their own
trigger  Missile   (A_Jump(255,...) at :2189, Phase2Jumps2, or the bail-out from either Chaingunlasers state)
range    --
mirrored no
inherit  --
profile  MakeSummon(proj:"RS_RedMindBomb", count:5, delayTics:6)
notes    Reachable from four different places, including mid-railgun. The mines
         float, +LOOKALLAROUND, +THRUACTORS, and are shot down at 20 health --
         but killing one still detonates it (Death runs A_Explode(50,128)).
```

```
ATTACK   RS_RedMind.Death
file     zscript/monsters/mastermind/RS_Mastermind.zs:2249
shape    UNCLASSIFIED
payload  A_Explode(random(5,45),128) -- no projectile
arc      --
timing   once, on the APYT G 6 frame, 16 tics into the death chain
damage   random(5,45)
type     -- (the actor's own ExplosionDamage 128 / ExplosionRadius 255 are OVERRIDDEN by the explicit args)
sound    A_PlaySound("spider/death") at :2245 plus A_Scream at :2246
impact   --
trigger  Death
range    --   (radius 128)
mirrored no
inherit  --
profile  Explode(dmg:"random(5,45)", radius:128)
notes    A corpse bomb -- standing next to the red mind when it dies costs you.
         The Default block's ExplosionDamage 128 / ExplosionRadius 255 are
         dead weight here because A_Explode is called with explicit arguments;
         they would only apply to a bare A_Explode().
```

---

# RED'S MINE -- RS_RedMindBomb

```
ATTACK   RS_RedMindBomb.Boom
file     zscript/monsters/mastermind/RS_Mastermind.zs:2304
shape    UNCLASSIFIED
payload  A_Explode(random(20,70),128) -- no projectile
arc      --
timing   one tic (A_SetScale(1.1) then the blast on the same 0-tic frame), then 15 tics of MISL B/C/D before A_Die
damage   random(20,70)
type     Fire   (the actor's DamageType)
sound    A_PlaySound("weapons/rocklx") at :2305; DeathSound "weapons/rocklx"; AttackSound "vile/active"
impact   --
trigger  Melee   (Melee: at :2299 falls straight into Boom)
range    --   (contact; radius 128)
mirrored no
inherit  --
profile  Explode(dmg:"random(20,70)", radius:128)
notes    The suicide-charge detonation. This is a MELEE trigger with no
         A_MeleeAttack in it -- the whole "melee" is the blast, so the spec's
         MELEE word (A_CustomMeleeAttack / A_MeleeAttack) does not apply.
         Pain.Fire (:2314) calls A_SetSpeed(30) -- setting one on fire makes it
         FASTER, from Speed 19 to 30. That is the mine's whole tell.
         Scale 1.85, RenderStyle Add, +FLOATBOB, -COUNTKILL, Health 20.
```

```
ATTACK   RS_RedMindBomb.Death
file     zscript/monsters/mastermind/RS_Mastermind.zs:2320
shape    UNCLASSIFIED
payload  A_Explode(50,128) -- no projectile
arc      --
timing   one tic, then 10 tics before A_Die; then drops a Clip or a Shell
damage   50   (a FLAT 50 -- this is CH's own constant at MASTERMINDS.txt:3773, not a flattened roll; the Melee blast above IS a roll and is preserved as one)
type     Fire
sound    A_PlaySound("weapons/rocklx") at :2321
impact   A_Jump(255,"Clip2","Shell2") -- a 50/50 ammo drop at alpha 128
trigger  Death
range    --   (radius 128)
mirrored no
inherit  --
profile  Explode(dmg:50, radius:128)
notes    Shooting a mine does NOT defuse it -- it detonates for a flat 50 and
         still pays out ammo. The Melee blast (20..70) and the Death blast (50)
         are deliberately different numbers in CH; both verified against
         MASTERMINDS.txt:3757 and :3773.
```

---

# BLACK -- RS_BlackMind2 (tier 10, "Pseudo Old God")

The heaviest state graph in the family. `Missile` ->
`A_JumpIfHealthLower(7777,"SCREEE")` -> `A_JumpIfCloser(512,"CloseRange")` ->
`A_JumpIfCloser(2028,"Choose")` -> `A_Jump(256,"Psyche2")`. Once `user_sce >= 1`
the SCREEE test lands on `Miss2` instead, which re-tests range into
`CloseRange2` / `Choose2` and otherwise falls to `Goto Missile+7` -- a numeric
offset that walks PAST its own Goto into `Choose:` and then `Miss2:`.

```
ATTACK   RS_BlackMind2.SCREEE
file     zscript/monsters/mastermind/RS_Mastermind.zs:2452
shape    UNCLASSIFIED
payload  A_SpawnParticle("Black",SPF_FULLBRIGHT,...) x6 frames -- no projectile
arc      --
timing   10,10,10, then 2 x6, then 10, then 8   (about 70 tics)
damage   NONE
type     --
sound    A_PlaySound("DeepOne/active",7,2,false,ATTN_NONE) at :2456 -- map-wide
impact   --
trigger  Missile   (A_JumpIfHealthLower(7777,"SCREEE") at :2439)
range    --
mirrored no
inherit  --
profile  PhaseChange(missileEvenMore:true, speed:24, noPainDuring:true)
notes    One-shot enrage at 70% health. Sets +MISSILEEVENMORE permanently
         (:2455), A_SetSpeed(24) (:2459, up from 26 base -- CH lowers it, which
         is counter-intuitive and is kept verbatim), and holds +NOPAIN for the
         whole ~70-tic animation. `user_sce` (:2457) makes it once-only, and
         from then on the health test routes to Miss2, unlocking CloseRange2 /
         Choose2 and therefore Waves2 and Summons.
```

```
ATTACK   RS_BlackMind2.BIGBAM
file     zscript/monsters/mastermind/RS_Mastermind.zs:2477
shape    SINGLE
payload  RS_QueenMindWave x1
arc      --
timing   one shot after an 18-tic BCD face; 10-tic recovery
damage   DamageFunction (random(30,80))
type     Plasma
sound    A_PlaySound("queen/fire") at :2475; the wave's own SeeSound "queen/fire"
impact   DeathSound "queen/hit"; Death is a four-stage escalating blast with a scale ramp: Radius_Quake(15,15,0,40), A_Explode(random(11,50),110) at scale 1.2, then (9,40) at 130, then (7,30) at 150, then (5,20) at 170. Four blasts, four radii, one impact.
trigger  Missile   (Choose, or Choose2)
range    512..2028
mirrored no
inherit  --
profile  MakeSingle(proj:"RS_QueenMindWave")
notes    +SEEKERMISSILE with A_SeekerMissile ramping 3,6 -> 4,8 -> 3,9 -> 6,12
         across its 20-tic flight loop -- it gets better at tracking the longer
         it chases. It sheds an RS_ZWAVE ripper ring EVERY tic: RS_ZWAVE is
         +RIPPER +NOCLIP, random(1,3) Plasma, with A_Explode(random(2,7),64) on
         five frames. The trail alone is a damage corridor. Decal
         "SwordLightning". Muzzle height 64.
```

```
ATTACK   RS_BlackMind2.Waves
file     zscript/monsters/mastermind/RS_Mastermind.zs:2482
shape    SALVO
payload  RS_ZWAVE3 x5
arc      30 at the widest   (0, random(-5,5), random(-8,8), random(-12,12), random(-15,15))
timing   four on ONE tic, the fifth on the 6-tic frame; 12-tic BCD face on entry
damage   DamageFunction (random(10,30))
type     Melee
sound    A_PlaySound("queen/fire") at :2480; SeeSound "queen/fire" x5
impact   see the RS_ZWAVE3 note below
trigger  Missile   (CloseRange, or LongRange)
range    ..512 via CloseRange; 512..2028 via LongRange
mirrored no
inherit  --
profile  MakeSalvo(proj:"RS_ZWAVE3", count:5, arc:30)   muzzleZ:[30,54,72,64,44], muzzleOfs:[-10,-2,+10,-10,+18]
notes    The five muzzle heights (30/54/72/64/44) and lateral offsets are what
         make this read as a wall rather than a line -- the shots leave from
         five different points on the body.
         RS_ZWAVE3 IS ALSO A BLACKOUT WEAPON: every flight cycle it runs
         A_RadiusGive("RS_DarknessCallwithnewphone",24,RGF_PLAYERS,1), and its
         Death does the same at 42 units. That powerup is
         Powerup.Color "00 00 00", 0.85 for 120 tics, +ADDITIVETIME -- it
         stacks, and a sustained wave volley blinds the player. In flight it
         also fires A_Explode(random(2,7),64) five times per loop and randomly
         rescales its own velocity by 1.15 / 1.33 / 0.80 / 1.5 / 0.65, so the
         five shots desynchronise into an uneven wall.
```

```
ATTACK   RS_BlackMind2.Waves2
file     zscript/monsters/mastermind/RS_Mastermind.zs:2492
shape    SALVO
payload  RS_ZWAVE3 x7
arc      24 at the widest   (random(-12,12) x4, random(-1,1), random(-4,4), random(-12,12))
timing   six on ONE tic, the seventh on the 6-tic frame; 12-tic BCD face on entry
damage   DamageFunction (random(10,30))
type     Melee
sound    A_PlaySound("queen/fire") at :2490
impact   as Waves -- including the stacking blackout
trigger  Missile   (CloseRange2 or Choose2 -- BOTH ARE POST-SCREEE ONLY)
range    ..512 via CloseRange2; 512..2028 via Choose2
mirrored no
inherit  --
profile  MakeSalvo(proj:"RS_ZWAVE3", count:7, arc:24)   muzzleZ:[64,54,44,74,64,54,64], muzzleOfs:[-10,+10,-0,+20,-30,+30,-20]
notes    The enraged Waves: two more shots and a much wider muzzle spread
         (-30..+30 lateral vs -10..+18) for a slightly TIGHTER angular cone.
         Note CH writes `-0` for the third shot's offset, kept verbatim.
         Ends A_Jump(84,"BIGBAM","ClusterEf") then falls into Waves, so it
         chains rather than returning to See.
```

```
ATTACK   RS_BlackMind2.ClusterEf
file     zscript/monsters/mastermind/RS_Mastermind.zs:2503
shape    MULTI
payload  RS_QueenPlasmaBlast x9  +  RS_ZWAVE3 x6
arc      22   (all fifteen at random(-11,11))
timing   1 x15, in five 3-shot groups with a 0-tic A_FaceTarget re-aim between every group; 12-tic BCD face on entry
damage   QueenPlasmaBlast DamageFunction (random(8,45)); ZWAVE3 DamageFunction (random(10,30))
type     Plasma / Melee
sound    --   (state silent; SeeSound "electricplasma/shoot" x9 and "queen/fire" x6)
impact   QueenPlasmaBlast: DeathSound "electricplasma/hit", EBLT IJK 3, and it BOUNCES (Doom, BounceCount 3, BounceFactor 1.25 -- it speeds up on each floor bounce). ZWAVE3: the blackout + explode ladder above.
trigger  Missile   (Waves2's A_Jump(84,...), RapidFire's A_Jump(72,...), or SpreadFire's A_Jump(64,...))
range    --   (never entered directly from Missile)
mirrored no
inherit  --
profile  MakeMulti( MakeBurst(proj:"RS_QueenPlasmaBlast", count:9, delayTics:1, arc:22), MakeBurst(proj:"RS_ZWAVE3", count:6, delayTics:1, arc:22) )
notes    Alternating triplets: plasma, wave, plasma, wave, plasma. The
         re-aim between groups means the two payload types converge on you from
         slightly different lines. Muzzle height 62 throughout.
         RS_QueenPlasmaBlast picks one of THREE flight patterns per shot
         (BishopMissileWeave + 5% accel per cycle / CStaffMissileSlither + 10%
         accel / random ThrustThing + ThrustThingZ chaos), so no two of the
         nine fly the same path. WeaveIndexXY 61, WeaveIndexZ 23.
```

```
ATTACK   RS_BlackMind2.Summons
file     zscript/monsters/mastermind/RS_Mastermind.zs:2522
shape    UNCLASSIFIED
payload  RS_PortalSummons2 x5   (a RandomSpawner over 10 classes)
arc      --   (placed at random(-178,178) x random(-178,178), Z random(5,64))
timing   3 x5   (after 10 + 10 + 16 tics of tell)
damage   -- (whatever comes out of the portal carries it)
type     --
sound    A_PlaySound("DeepOne/active",7,2,false,ATTN_NONE) at :2519 -- map-wide
impact   SXF_SETMASTER, so everything summoned dies with the black mind (its Death runs A_KillMaster... and the summons' own A_KillChildren chain)
trigger  Missile   (CloseRange2 or Choose2 -- POST-SCREEE ONLY)
range    ..2028
mirrored no
inherit  --
profile  MakeSummon(proj:"RS_PortalSummons2", count:5, delayTics:3)
notes    RS_PortalSummons2 (RS_MastermindFX.zs:2037) rolls over
         RS_CommonRevenant 100 / RS_PurpleRevenant 100 / RS_RedRevenant 120 /
         RS_RedLSoul 100 / RS_DeepTentacle 350 / RS_RoseTentacle 800 /
         RS_YellowSP1 180 / RS_RedSpectre 120 / RS_RedDemon 150 /
         RS_RedCaco 120 -- weight 800 means the rose tentacle is the most
         likely single outcome by a wide margin. All ten live in other
         families; none is defined here.
```

```
ATTACK   RS_BlackMind2.RapidFire
file     zscript/monsters/mastermind/RS_Mastermind.zs:2527
shape    BURST
payload  RS_QueenPlasmaBlast x52
arc      22 at the widest   (the cone breathes: +/-4, +/-7, +/-11, +/-11, +/-7, +/-7, +/-4, then -4..+7, +/-11, -7..+4, +/-3)
timing   2 x21 (seven groups of three), then 1 x31 (groups of 5, 7, 7, 12); a 0-tic A_FaceTarget re-aim between EVERY group
damage   DamageFunction (random(8,45))
type     Plasma
sound    --   (state silent; SeeSound "electricplasma/shoot" x52)
impact   DeathSound "electricplasma/hit"; bounces off floors 3 times at BounceFactor 1.25
trigger  Missile   (CloseRange, CloseRange2, or LongRange's fall-through)
range    ..512 via CloseRange / CloseRange2; the LongRange default at 512..2028
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_QueenPlasmaBlast", count:52, delayTics:1.4, arc:22)
notes    52 shots, counted from CH's frame strings (EEE x7 = 21, then
         EEEEE = 5, EEEEEEE = 7, EEEEEEE = 7, EEEEEEEEEEEE = 12). The cadence
         ACCELERATES -- 2 tics for the first 21, 1 tic for the last 31 -- and
         the cone narrows to +/-3 for the final twelve. It is a spin-up.
         Ends A_CheckSight("PainTele"), A_Jump(72,"BIGBAM","ClusterEf"),
         A_Jump(94,"Missile"): it will teleport if it loses sight of you
         mid-burst rather than stop firing.
```

```
ATTACK   RS_BlackMind2.Psyche2
file     zscript/monsters/mastermind/RS_Mastermind.zs:2561
shape    RAIN
payload  RS_PsychicAra2 x1 per cycle, looping on A_MonsterRefire(128,"See") back to Psyche2+3
arc      --   (A_VileTarget; placed on the target)
timing   4 tics per cast, 12-tic cycle (9 + 3 + 0 + 4 + 2); a 14-tic tell on first entry
damage   DamageFunction (random(2,12))
type     "Getoutofmyheadcharles"
sound    A_PlaySound("queen/sight",7,2,false,ATTN_NONE) at :2557 -- map-wide
impact   Spawn IS Death: 4 frames, Radius_Quake(9,9,0,30), and A_RadiusGive("RS_DarknessCallwithnewphone",72,RGF_PLAYERS,1). DeathSound "deepone/active".
trigger  Missile   (the >2028 default at :2442, or CloseRange2 / Choose2 / LongRange)
range    2028.. from Missile; also reachable at every band
mirrored no
inherit  --
profile  MakeRain(proj:"RS_PsychicAra2", count:1, delayTics:12, atTarget:true)
notes    THE DAMAGE IS NOT THE POINT -- random(2,12) is trivial. This is a
         screen-blackout weapon: the 72-unit A_RadiusGive hands the player
         RS_DarknessCallwithnewphone, which is Powerup.Color "00 00 00" at 0.85
         alpha for 120 tics with +ADDITIVETIME and +NOSCREENBLINK. Because it
         loops on A_MonsterRefire and the powerup stacks, a sustained Psyche2
         can black the screen out indefinitely. RenderStyle "Stencil",
         Scale 1.8. A_CheckSight("See") aborts before each cast.
```

```
ATTACK   RS_BlackMind2.SpreadFire
file     zscript/monsters/mastermind/RS_Mastermind.zs:2566
shape    SCATTER
payload  RS_QueenPlasmaBlast x24
arc      34 at the widest   (first half: random(-7,1), (-1,7), (-15,-7), (7,15), (-7,7); second half: (-7,1), (-1,7), (-15,15) x4, (-7,17), (-17,7))
timing   two halves of 11 and 13; within a half, ten or twelve on ONE tic then one on a 5-tic frame; 18-tic BCD face before each half
damage   DamageFunction (random(8,45))
type     Plasma
sound    --   (state silent; SeeSound "electricplasma/shoot" x24)
impact   DeathSound "electricplasma/hit"; floor-bouncing, BounceFactor 1.25
trigger  Missile   (LongRange, or CloseRange's fall-through)
range    ..512 via CloseRange's fall-through; 512..2028 via LongRange
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_QueenPlasmaBlast", count:24, coneDeg:34, delayTics:0)   two waves, 18 tics apart
notes    Every shot but the two closers carries CMF_AIMOFFSET|CMF_OFFSETPITCH
         with pitch random(-3,3) -- unlike RapidFire, this one spreads
         VERTICALLY as well. The second half is asymmetric on purpose:
         random(-7,17) and random(-17,7) are pulled off-centre in opposite
         directions. Muzzle height 64. Ends A_Jump(64,"Missile","ClusterEf").
```

```
ATTACK   RS_BlackMind2.See
file     zscript/monsters/mastermind/RS_Mastermind.zs:2431
shape    SCATTER
payload  RS_BlackSpidShade x2 per See loop
arc      360   (CMF_AIMOFFSET, angle random(0,360), pitch random(0,360); spawnheight random(-5,55), muzzleOfs random(-15,15))
timing   one every 2 tics of walking, indefinitely
damage   DamageFunction (random(10,58))
type     Melee
sound    --
impact   RS_BlackSpidShade sits 24 tics, runs A_RadiusGive("RS_DarknessCallwithnewphone",22,RGF_PLAYERS,1), then loops a pulse-and-fade (three variants) back to Spawn+1 -- it lingers and re-gives the blackout on every loop
trigger  Walk   (the See chain, :2426-2436)
range    --
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_BlackSpidShade", count:2, coneDeg:360, delayTics:2)
notes    A DAMAGING TRAIL, NOT DECORATION. Every other tic of walking the black
         mind sheds a Speed 8, +FLOATBOB, Alpha 0.5, Scale 1.5 shadow that does
         random(10,58) Melee on contact and blinds you at 22 units. Chasing it
         through its own wake is the fight. It derives from SpecialSpot but
         carries `Projectile`, which is what makes it hurt.
```

```
ATTACK   RS_BlackMind2.PainTele
file     zscript/monsters/mastermind/RS_Mastermind.zs:2592
shape    UNCLASSIFIED
payload  A_Teleport("See","RS_BlackSpidShade","RS_ZWAVE2",TF_KEEPVELOCITY)
arc      --
timing   2 tics
damage   RS_BlackSpidShade DamageFunction (random(10,58)) at the DEPARTURE point; RS_ZWAVE2 has none
type     Melee (departure fog only)
sound    --
impact   the departure fog is the damaging shade described above; the arrival fog RS_ZWAVE2 is +NOINTERACTION, Scale 1.5, Alpha 0.75 and is harmless
trigger  Pain   (A_Jump(142,"PainTele") at :2586 -- 55% of pain beats), and also from See's A_Jump(12) and RapidFire's A_CheckSight
range    --
mirrored no
inherit  RS_ZWAVE2 : RS_ZWAVE (RS_MastermindFX.zs:2384) -- the child adds +NOINTERACTION, Scale 1.5, Alpha 0.75 and overrides Spawn to a pure fade, which is what STRIPS the parent's random(1,3) +RIPPER damage. Read the parent and you would wrongly report the arrival fog as a damaging ripper.
profile  Blink(departFog:"RS_BlackSpidShade", arriveFog:"RS_ZWAVE2", keepVelocity:true)
notes    A_Teleport's 2nd arg is the SOURCE fog and the 3rd is the DEST fog.
         CH puts the damaging class on the source: hitting it hard leaves a
         random(10,58) shadow where it was standing, and it reappears
         harmlessly elsewhere. That asymmetry is deliberate and is the whole
         mechanic. The inherit line above is why this row exists at all --
         the naive read ("both fogs are ZWAVE-family, both rip") is wrong.
```

---

# WHITE -- RS_WhiteMind2 (tier 11, "Heavily Armed Spidey")

`Missile` -> `A_JumpIfCloser(100,"Dash",true)` ->
`A_JumpIfCloser(1500,"LowRange",true)` ->
`A_Jump(255,"EyeBeam","RapidFire","HitScan")`. `LowRange` ->
`A_JumpIfHealthLower(5000,"Third")` -> `A_JumpIfHealthLower(10000,"Second")`
-> `A_Jump(255,"RapidFire","EyeBeam","OrbShot","FloorCrack")`.
`Second` = HitScan | OrbShot2 | FloorCrack2 | SpawnSentinel.
`Third` = HitScan | OrbShot3 | FloorCrack3 | SpawnSentinel.

```
ATTACK   RS_WhiteMind2.HitScan
file     zscript/monsters/mastermind/RS_Mastermind.zs:2765
shape    HITSCAN
payload  A_CustomBulletAttack(random(2,15),0,random(1,2),random(1,2),"RS_WhiteMindFlare") x2 calls
arc      4..30, REROLLED PER CALL   (spread_xy random(2,15), spread_z 0 -- horizontal only)
timing   2,0 then 1 (A_MonsterRefire(64,"See")); loops to HitScan+2; 10-tic FE face on entry
damage   random(1,2) per bullet x the engine's random(1,3) = 1..6; random(1,2) bullets per call
type     -- (no DamageType)
sound    A_PlaySound("moloch/nailhitbleed",0) at :2764
impact   puff RS_WhiteMindFlare -- an 8-frame Add-blend SSBL flare with NO damage, +NOCLIP +DONTTHRUST +DONTBLAST, SeeSound "holy3/holy3", DeathSound "holy2/holy2". Unlike the gray mind's puff this one is purely visual.
trigger  Missile   (the >1500 A_Jump, or Second, or Third)
range    1500.. from Missile; also at ..1500 via Second/Third
mirrored no
inherit  --
profile  MakeHitscan(pellets:"random(1,2)", damage:"random(1,2)", spreadXY:"random(2,15)", spreadZ:0, puff:"RS_WhiteMindFlare")   x2
notes    Tiny numbers -- 2..12 damage per cycle -- but the refire chance is 64
         (the loosest in the family, so it re-fires constantly) and the spread
         is rerolled every call, so it wanders. Two muzzle flares are also
         spawned as decoration at +/-16 lateral, 32 up (:2762-2763).
         THE PUFF IS NAMED IN THE CALL AND IS HARMLESS; reading "custom puff"
         and assuming a secondary payload, as the gray mind's puff has, would
         be wrong here.
```

```
ATTACK   RS_WhiteMind2.RapidFire
file     zscript/monsters/mastermind/RS_Mastermind.zs:2888
shape    BURST
payload  RS_WhiteMindshot1 x12
arc      2   (pair 1 -1/+1, pairs 2-3 dead ahead; pair 4 +1/-1, pairs 5-6 dead ahead; the +/-16 is spawnofs_xy, twin muzzles)
timing   pairs on one tic, 2 tics apart, three pairs; 12-tic A_FaceTarget re-aim; then three more pairs
damage   DamageFunction (random(10,50))
type     Plasma
sound    A_PlaySound("DEEPSHO1",0) SIX times, once per pair; SeeSound "weapons/plasmaf" x12
impact   DeathSound "weapons/plasmax"; A_SetScale(0.85) then RCHB CD 3, then A_SetScale(1.35,1.05) and RCHB E 3 with A_Explode(random(10,40),64)
trigger  Missile   (the >1500 A_Jump, or LowRange's first tier)
range    --
mirrored yes   (every shot is a mirrored pair from muzzles at +16 and -16)
inherit  --
profile  MakeBurst(proj:"RS_WhiteMindshot1", count:12, delayTics:2, arc:2)   muzzleOfs:[+16,-16] per pair
notes    Speed 45 and BounceType "Doom" with BounceCount 2 and BounceSound ""
         -- they ricochet SILENTLY twice before dying, and each death is a
         64-radius blast. In a corridor 12 shots become up to 36 explosions
         with no audio warning of the bounce. Scale (1.1,0.75) set in
         BeginPlay. Trails RS_SpideMindTrail every tic.
         Two muzzle flares are spawned per half at +/-16, 32 up.
```

```
ATTACK   RS_WhiteMind2.EyeBeam
file     zscript/monsters/mastermind/RS_Mastermind.zs:2912
shape    HITSCAN
payload  2x telegraph railgun (damage 0) then 1x A_CustomRailgun(random(10,40),0,"blue","blue",RGF_FULLBRIGHT|RGF_NORANDOMPUFFZ,0,0,"RS_WhiteMindRB3",0,0,0,66,0.7,0.9,"RS_WhiteMindRB4",7,10)
arc      0   (spread_xy 0, spread_z 0, aim 0, maxdiff 0 -- dead straight, no auto-aim)
timing   6,6 (the two telegraphs) then 4 (the real one); 5-tic face on entry, 20-tic recovery
damage   0, 0, then random(10,40) from the rail itself
type     -- from the rail; Plasma from the puff and the spawnclass
sound    A_PlaySound("ECHOIMPB",0) at :2911; RS_WhiteMindRB4 SeeSound "Spell/spellCast1" along the whole beam
impact   PUFF RS_WhiteMindRB3: DamageFunction (random(30,95)) Plasma, +ALWAYSPUFF, DeathSound "NETHERDE", and its Death runs A_Scream + BFE1 AB 5 + A_Explode(random(30,95),128) + Radius_Quake(9,9,0,30). SPAWNCLASS RS_WhiteMindRB4: a LIVE projectile, DamageFunction (random(15,30)) Plasma Speed 11, spawned in a spiral along the beam (spiraloffset 10, spawnofs_z 7), DeathSound "Crack/death", Death A_Explode(random(10,20),88) x2.
trigger  Missile   (the >1500 A_Jump, or LowRange's first tier)
range    --   (range arg 0 = unlimited)
mirrored no
inherit  --
profile  MakeRailgun(damage:"random(10,40)", puff:"RS_WhiteMindRB3", spawnClass:"RS_WhiteMindRB4", duration:66)   preceded by 2x MakeRailgun(damage:0, duration:0) telegraph
notes    THE RAIL'S OWN DAMAGE IS THE SMALLEST PART OF IT. random(10,40) from
         the beam, then random(30,95) from the puff, then another
         random(30,95) from the puff's explosion -- 70..230 on one hit, plus a
         spiral of live orbs left hanging in the air along the beam that each
         do random(15,30) and explode twice more.
         THE TWO ZERO-DAMAGE RAILS ARE A TELEGRAPH: 12 tics of blue
         RGF_NOPIERCING beam drawn on your position before the real shot. Any
         profile that drops them loses the attack's entire fairness budget.
         sparsity 0.7 and driftspeed 0.9 make the beam dense and slow-drifting.
```

```
ATTACK   RS_WhiteMind2.OrbShot
file     zscript/monsters/mastermind/RS_Mastermind.zs:2880
shape    SINGLE
payload  RS_WhiteMindCrackleOrb x1
arc      --
timing   one shot after a 10-tic FE face; 20-tic recovery
damage   DamageFunction (random(50,120))
type     Plasma
sound    A_PlaySound("ELECFATT",0) at :2878; SeeSound "Spell/SpellCast1"
impact   DeathSound "Fire/Fire4"; A_SetScale(4.0) then SPIR ABCDEDCBA 5 with A_Explode(random(5,50),256) on ALL NINE FRAMES -- a 256-radius blast repeated nine times. DropItem "RS_CH_RocketAmmo".
trigger  Missile   (LowRange's first tier)
range    ..1500
mirrored no
inherit  --
profile  MakeSingle(proj:"RS_WhiteMindCrackleOrb")
notes    Speed 9 and Scale 2.35 -- a slow, enormous, dodgeable ball, which is
         what pays for random(50,120) plus nine 256-radius explosions. In
         flight it runs A_Explode(random(4,10),128) every other tic and sheds
         2x RS_CrackedWhiteMind per cycle (random(1,6) Plasma each, with their
         own A_Explode(random(2,9),64)), and seeks with A_SeekerMissile(2,2).
         Radius 256 is the largest single blast radius in the family.
```

```
ATTACK   RS_WhiteMind2.OrbShot2
file     zscript/monsters/mastermind/RS_Mastermind.zs:2874
shape    SINGLE
payload  RS_WhiteMindCrackleOrb2 x1
arc      --
timing   one shot after a 10-tic FE face; 20-tic recovery
damage   DamageFunction (random(50,120))
type     Plasma
sound    A_PlaySound("ELECFATT",0) at :2872; SeeSound "Spell/SpellCast1"
impact   DeathSound "Fire/Fire4"; A_SetScale(4.0), A_Explode(random(40,100),128), 10x RS_CrackedWhiteMind, then SPIR ABCDEDCBA 5 with A_Explode(random(5,50),256) on all nine
trigger  Missile   (Second -- health 5000..10000 only)
range    ..1500
mirrored no
inherit  --
profile  MakeSingle(proj:"RS_WhiteMindCrackleOrb2")
notes    SAME DAMAGE, COMPLETELY DIFFERENT DELIVERY. Speed 0 at spawn: it hangs
         in the air growing Scale 1.0 -> 2.2 over 10 tics, THEN A_SetSpeed(24)
         and seeks with A_SeekerMissile(9,9) -- an aggressive homer, where
         OrbShot's is a lazy drifting one at (2,2). Its impact also adds a
         random(40,100) opening blast the original does not have.
```

```
ATTACK   RS_WhiteMind2.OrbShot3
file     zscript/monsters/mastermind/RS_Mastermind.zs:2782
shape    MULTI
payload  RS_WhiteMindCrackleOrb x1  +  RS_WhiteMindCrackleOrb2 x3
arc      --   (all four dead ahead, muzzle height 64)
timing   5, then 5,5,5; preceded by a 5-tic tell and an 8-tic ThrustThingZ(0,50,0,0) hop
damage   both DamageFunction (random(50,120))
type     Plasma
sound    --   (no A_PlaySound in this state -- unlike OrbShot and OrbShot2, which both play "ELECFATT". SILENT, and that is a finding: at low health the white mind stops announcing its heaviest attack.)
impact   as OrbShot / OrbShot2 above
trigger  Missile   (Third -- health <5000 only)
range    ..1500
mirrored no
inherit  --
profile  MakeMulti( MakeSingle(proj:"RS_WhiteMindCrackleOrb"), MakeBurst(proj:"RS_WhiteMindCrackleOrb2", count:3, delayTics:5, arc:0) )
notes    Four orbs at random(50,120) each and up to 36 x 256-radius
         explosions -- by total damage the heaviest single state in the family.
         It leaps 50 units up first (ThrustThingZ), so the orbs come down at
         you. The absence of a sound cue is CH's own (MASTERMINDS.txt:5044-5049
         has no A_PlaySound); recorded, not "fixed".
```

```
ATTACK   RS_WhiteMind2.FloorCrack
file     zscript/monsters/mastermind/RS_Mastermind.zs:2839
shape    SALVO
payload  RS_WhiteSpidWinder x6
arc      184   (-92, +92, -32, +32, -62, +62 -- three mirrored pairs, near-perpendicular first)
timing   five on ONE tic, the sixth on a 5-tic frame; preceded by a 5-tic tell, an 8-tic ThrustThingZ(0,50,0,0) hop, 15 tics, and 5 more
damage   DamageFunction (random(10,70))
type     Plasma
sound    A_PlaySound("DSHADEXP",0) at :2838; SeeSound "ELECTRO8" x6
impact   DeathSound "Crack/death". In FLIGHT each winder spawns RS_WhiteSpidWave every other tic -- a +FLOORHUGGER +FORCERADIUSDMG lingering floor wave, random(5,27) Plasma, running A_Explode(random(7,28),32) on TEN frames of 10 tics. The trail is the weapon.
trigger  Missile   (LowRange's first tier)
range    ..1500
mirrored yes   (three mirrored pairs; the muzzleOfs alternates +16 / -16 with the sign of the angle)
inherit  --
profile  MakeSalvo(proj:"RS_WhiteSpidWinder", count:6, arc:184)   muzzleOfs:[+16,-16] per pair
notes    THE ANGLES ARE NEARLY SIDEWAYS ON PURPOSE. +SEEKERMISSILE with
         A_SeekerMissile(4,9) means they launch perpendicular and then curve
         back in, so they sweep the floor around you rather than flying at you.
         +FLOORHUGGER keeps them on the deck. A 6/256 chance per cycle expires
         each one, so the field decays. +DONTHARMCLASS +THRUSPECIES.
```

```
ATTACK   RS_WhiteMind2.FloorCrack2
file     zscript/monsters/mastermind/RS_Mastermind.zs:2851
shape    SALVO
payload  RS_STracerWhiteSP x19
arc      180   (0, then +/-10, +/-20, +/-30, +/-40, +/-50, +/-60, +/-70, +/-80, +/-90 -- exact 10-degree steps)
timing   ALL NINETEEN ON ONE TIC; preceded by a 5-tic tell, a 10-tic A_FaceTarget and 5 more
damage   DamageFunction (random(11,33))
type     Fire
sound    A_PlaySound("DSHADEXP",0) at :2850; SeeSound "ELECTRO8" x19
impact   DeathSound "Crack/death"; FTRA K 4, then FTRA L 4 with A_Explode(random(5,15),64), then MNO 3
trigger  Missile   (Second -- health 5000..10000 only)
range    ..1500
mirrored yes   (the +/- pairs are exact mirrors around a single centre shot)
inherit  --
profile  MakeSalvo(proj:"RS_STracerWhiteSP", count:19, arc:180)
notes    A FULL 180-DEGREE FLOOR BURST, INSTANT. +FLOORHUGGER, -NOGRAVITY,
         +DONTSPLASH, Speed 20, and A_CStaffMissileSlither every tic so each
         tracer snakes rather than running straight. It also drops
         RS_STracerPuffSP every tic -- ExplosionDamage 2 / ExplosionRadius 8,
         so the ground behind each tracer stays hot.
         The only attack in the family that covers the whole forward hemisphere
         in a single tic. There is nowhere in front of it to stand.
```

```
ATTACK   RS_WhiteMind2.FloorCrack3
file     zscript/monsters/mastermind/RS_Mastermind.zs:2791
shape    MULTI
payload  RS_STracerWhiteSP x19  +  RS_WhiteSpidWinder x6
arc      184   (the 19 tracers at 10-degree steps across 180; the 6 winders at -92/+92/-32/+32/-62/+62)
timing   twenty-four on ONE tic, the twenty-fifth on a 5-tic frame; 25-tic tell (5 + 15 face + 5)
damage   tracers DamageFunction (random(11,33)); winders DamageFunction (random(10,70))
type     Fire / Plasma
sound    A_PlaySound("DSHADEXP",0) at :2790
impact   as the two rows above -- including the winders' lingering RS_WhiteSpidWave floor field
trigger  Missile   (Third -- health <5000 only)
range    ..1500
mirrored yes
inherit  --
profile  MakeMulti( MakeSalvo(proj:"RS_STracerWhiteSP", count:19, arc:180), MakeSalvo(proj:"RS_WhiteSpidWinder", count:6, arc:184) )
notes    FloorCrack2 and FloorCrack fired together and simultaneously -- the
         low-health escalation. 25 payloads on a single tic, the densest
         instantaneous volley in the family. Unlike FloorCrack it does NOT
         leap first (no ThrustThingZ), because it is already committing
         everything.
```

```
ATTACK   RS_WhiteMind2.Dash
file     zscript/monsters/mastermind/RS_Mastermind.zs:2818
shape    CHARGE
payload  the monster itself (A_SkullAttack())
arc      --
timing   5 tics to launch; 16 tics of RS_WhiteSpidShade afterimages; A_Stop at :2820
damage   Damage 8 (the actor's own) -- the engine's skullfly collision rolls it x random(1,8), so 8..64
type     --
sound    --   (A_SkullAttack plays AttackSound, and RS_WhiteMind2 declares none)
impact   the afterimages RS_WhiteSpidShade are Damage 0, +NOCLIP +DONTTHRUST +DONTBLAST -- decoration
trigger  Missile   (A_JumpIfCloser(100,"Dash",true) at :2757 -- the `true` means it checks Z too)
range    ..100
mirrored no
inherit  --
profile  MakeCharge(speed:20, damage:"8 x random(1,8)")
notes    A_SkullAttack's default speed is SKULLSPEED (20). This is the family's
         ONLY CHARGE, and it is the answer to being inside 100 units --
         combined with +AVOIDMELEE, the white mind refuses to be cornered.
         It ends A_Jump(128,"Dodge1","Dodge2"), so the dash always becomes a
         sidestep. Dodge1/Dodge2 are ThrustThing(angle*256/360 +64 or +192, 36)
         strafes that shed more Damage-0 shades -- movement, not attacks.
         ENGINE SOURCE NOT VERIFIABLE THIS SESSION -- see UNRESOLVED.
```

```
ATTACK   RS_WhiteMind2.SpawnSentinel
file     zscript/monsters/mastermind/RS_Mastermind.zs:2826
shape    UNCLASSIFIED
payload  RS_MiniSentinelSpider x8   (A_DualPainAttack x4 -- two drones per call, at +/-45)
arc      90   (the engine's dual spit: one at angle+45, one at angle-45)
timing   15,10,5,5   (after a 5-tic tell and an 8-tic charge)
damage   -- (the drones carry it; see the two RS_MiniSentinelSpider rows below)
type     --
sound    --   (silent; nothing in the state plays a sound)
impact   the drones are free-roaming, NOT leashed -- no SXF_SETMASTER, unlike the purple mind's babies
trigger  Missile   (Second or Third -- health <10000 only)
range    ..1500
mirrored yes   (A_DualPainAttack is inherently a mirrored pair)
inherit  --
profile  MakeSummon(proj:"RS_MiniSentinelSpider", count:8, delayTics:8)   as 4 mirrored pairs at +/-45
notes    A_DualPainAttack is the Pain Elemental's two-sided spit used as a
         summon -- 4 calls, 8 drones, and the cadence ACCELERATES (15, 10, 5,
         5). Ends A_Jump(64,"RapidFire","OrbShot","FloorCrack"), so a quarter
         of the time it chains straight into another attack while the drones
         are still spawning.
```

```
ATTACK   RS_WhiteMind2.Death
file     zscript/monsters/mastermind/RS_Mastermind.zs:2924
shape    SCATTER
payload  RS_HKRedDeath x26
arc      60   (CMF_AIMOFFSET, angle 2, pitch -10, muzzleOfs random(-30,30), spawnheight random(20,100))
timing   10 x5, 8 x5, 3 x5, 1 x11   (50 + 40 + 15 + 11 = 116 tics, ACCELERATING)
damage   A_Explode(random(5,10),42) per barrel -- RS_HKRedDeath has no Damage property of its own
type     Fire
sound    RS_HKRedDeath plays "world/barrelx" at spawn AND again on its Death frame -- 52 plays; the monster's own A_Scream fires at :2928
impact   A_Burst("RS_RedThingsHK") per barrel
trigger  Death
range    --   (radius 42 each)
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_HKRedDeath", count:26, coneDeg:60, delayTics:2)
notes    116 tics of accelerating explosions as the corpse comes apart -- 26
         barrel bursts totalling 130..260 damage in a spreading cloud. Counted
         from CH's frame strings: FABDF(5) + AFDCF(5) + BFDCD(5) +
         FFFFFFFFFFF(11) = 26. The monster only calls A_BossDeath and
         A_KillMaster AFTER the whole cascade (:2929-2930), so the fireworks
         are guaranteed to finish. Defined at
         zscript/monsters/zombieman/RS_ZombiemanFX.zs:844.
```

---

# WHITE'S DRONE -- RS_MiniSentinelSpider

```
ATTACK   RS_MiniSentinelSpider.Missile
file     zscript/monsters/mastermind/RS_Mastermind.zs:2984
shape    SCATTER
payload  RS_DFlarePE2 x3
arc      18 at the widest   (0, random(-3,3), random(-9,9) -- a widening cone)
timing   1,1,1   (4-tic face on entry, 4-tic recovery)
damage   DamageFunction (random(10,20))
type     Fire
sound    --   (state silent; SeeSound "weapons/firmfi" x3)
impact   DeathSound "weapons/firex4"; CBAL CDEFG 3, no explosion
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeScatter(proj:"RS_DFlarePE2", count:3, coneDeg:18, delayTics:1)
notes    Speed 25, RenderStyle "Stencil" with StencilColor "red", Species "PE",
         +THRUGHOST +MTHRUSPECIES +THRUSPECIES -- eight drones can stack their
         fire without clipping each other. Trails RS_MFlareFX. Health 70 and
         PainChance 255, so the drones flinch constantly and are trivially
         killed; the threat is volume. +NOGRAVITY +LOOKALLAROUND
         +NEVERRESPAWN. Defined at
         zscript/monsters/painelemental/RS_PainElementalFX.zs:1717.
```

```
ATTACK   RS_MiniSentinelSpider.Death
file     zscript/monsters/mastermind/RS_Mastermind.zs:3000
shape    UNCLASSIFIED
payload  RS_DeathBreathDI x3   (or, on A_Jump(32,"SpawnThing"), ArchvileFire + RS_RandomizerArc)
arc      --   (placed at random(-178,178) x random(-178,178), Z random(-12,42), alpha 128)
timing   all three on one tic, at the end of a 32-tic death animation
damage   Damage 1 -- bare, engine rolls x random(1,8) = 1..8 on contact; the real damage is A_Explode(random(0,2),42) / (1,2) / (0,1) across ~28 frames
type     DImp
sound    DeathSound "Crack/death"; PainSound "prox/beep"
impact   the gas also runs A_RadiusGive("Health",64,RGF_MONSTERS|RGF_EXFILTER,3/5,"RS_BlackImp1") four times -- it HEALS nearby monsters while it poisons you
trigger  Death
range    --   (radius 42, at up to 178 units from the corpse)
mirrored no
inherit  --
profile  MakeSummon(proj:"RS_DeathBreathDI", count:3, delayTics:0)   with a 12.5% branch to ArchvileFire + RS_RandomizerArc
notes    Killing a drone leaves three lingering poison clouds up to 178 units
         away -- clearing them is worse than leaving them. The 32/256 branch
         (:2999) drops a live ArchvileFire and an RS_RandomizerArc instead.
         RS_DeathBreathDI is defined at
         zscript/monsters/imp/RS_ImpFX.zs:1147.
```

---

# UNRESOLVED

Honest gaps. Nothing below was guessed at.

**1. CH was not at the path the brief named.**
`C:\Users\Command\Desktop\CH` **does not exist on this machine** (checked
directly; `C:\Users\Command\Desktop` exists, the `CH` folder under it does not).
CH **is** at `E:\New folder\ART SOURCE\CH`, which is the path `CLAUDE.md`'s
"IMPORTING A MONSTER MEANS THE WHOLE MONSTER" section names for CH's own
`sounds/ sprites/ SNDINFO.txt TRNSLATE.txt DECORATE.txt`. Its
`decorate/MASTERMINDS.txt` is 5273 newline-terminated lines and its line numbers
land exactly on the citations our tree already carries (15 spot-checks, 15
hits), so it is the same file the import was made from. **All CH claims in this
document come from that copy.** If the owner considers only the Desktop path
authoritative, every CH assertion here needs re-running against it.

**2. The engine source is not on this machine.**
`CLAUDE.md` says the authority on flags and properties is `E:\DXR2`. **`E:\DXR2`
does not exist** (checked). Four rows lean on engine-internal behaviour I could
not re-read from source this session, and each is flagged in its own `notes`:
* `A_SPosAttackUseAtkSound` -- 3 bullets, damage `((random%5)+1)*3`, spread
  `Random2 * (22.5/255)`, puff `BulletPuff` (RS_CommonMind.Missile).
* `A_CustomBulletAttack`'s hidden `damage x random(1,3)` when `CBAF_NORANDOM`
  is absent (RS_GrayMind2.Missile2, RS_PurpleMind.HitScanHell,
  RS_WhiteMind2.HitScan). If this multiplier is wrong, three rows' damage
  ceilings are 3x too high.
* `A_SkullAttack`'s default `SKULLSPEED` = 20 and the skullfly collision's
  `Damage x random(1,8)` (RS_WhiteMind2.Dash).
* bare `Damage N` on a projectile rolling `x random(1,8)` (RS_PlasmaBallSP3,
  RS_DemoMissile, RS_DeathBreathDI). This one is corroborated in-tree by a
  comment at `zscript/monsters/zombieman/RS_ZombiemanFX.zs:842`, but that is our
  own tree agreeing with itself, which CLAUDE.md warns is worth nothing.

**3. `A_VileTarget` has no word in the closed shape vocabulary.**
The spec defines `VILE` as `A_VileAttack` specifically -- "line-of-sight burn,
no travel". `A_VileTarget` is a different function: it spawns an actor AT the
target's position and sets it as tracer. **Four rows use it.** Three are written
`RAIN` ("spawned above/around the target ... not aimed"), the closest closed-set
word, rather than coining one: `RS_BrownMind2.GroundBreak`,
`RS_FireBluMind2.Missile`, `RS_BlackMind2.Psyche2`. The fourth,
`RS_AbyssMind2.MindSpike`, is written `MULTI` because it places two DIFFERENT
projectile classes and `MULTI` takes precedence in the spec's own
definition -- but its delivery is the same A_VileTarget placement. None of the four is
falling, so `RAIN` is imprecise in all of them. **If the composer wants a
different word, these four remap together in one pass.** (A fifth and sixth `A_VileTarget` exist inside FX
payloads -- `RS_MindGroundSpikeBrown.XDeath` and `RS_BrownMindStoneThrow.XDeath`
both call `A_VileTarget("RS_Drt3")` then a real `A_VileAttack` -- and a seventh
in the orphaned `RS_BrownMind2.Yum3`.)

**4. Summons have no word either.** Six rows spawn live monsters
(`RS_PurpleMind.RageSummon`, `RS_YellowMind.Halp`, `RS_BlackMind2.Summons`,
`RS_WhiteMind2.SpawnSentinel`, `RS_RedMind.Blobs`, `RS_AbyssMind2.Pain`). All
are written `UNCLASSIFIED` with the mechanic described, per the spec's
instruction not to coin words. Three more non-damaging state chains are also
`UNCLASSIFIED` for the same reason: `RS_BrownMind2.FeelIt` (ally buff),
`RS_RedMind.Phase2` and `RS_BlackMind2.SCREEE` (phase changes),
`RS_BrownMind2.Yum3` (execute), plus the four bare-`A_Explode` rows
(`RS_RedMind.Death`, both `RS_RedMindBomb` rows,
`RS_BlackMind2.PainTele`).

**5. `RS_BrownMind2.YumYum` / `Yum2` / `Yum3` is unreachable dead code -- in our
tree AND in CH.** Nothing jumps to `YumYum` and no state falls through into it
(`FeelIt2` ends `Goto FeelIt`, `Checkers` ends `Goto See`). Verified in CH by
grep: `YumYum` appears once, as its own label (MASTERMINDS.txt:224). It is
catalogued as a row anyway because it is a complete mechanic worth having in a
parts bin, but **it never fires in game**. The devour's marker item
`RS_EatableMind` is handed out by `YumYum`'s own `A_RadiusGive`, so the whole
sub-system is orphaned together.

**6. Three orphan attack lines in `RS_BrownMind2.FeelIt`.** Lines 637-639
(`A_CustomMissile("RS_SpidieShotGray")` x2 plus a face) sit after that state's
`Goto See`. They are unreachable, they are unreachable in CH too
(MASTERMINDS.txt:260-262), and our file's own comment says so. Not given a row.

**7. Two CH-vs-tree divergences, both cosmetic, both already documented
in-tree.** Neither changes an attack parameter, so no row is affected:
* `RS_AbyssMind2` `See`/`See2`/`See3` (`RS_Mastermind.zs:954, 968, 982`): our
  tree writes `ANIM KLMLK`, CH writes `AMIN KLMLK` (MASTERMINDS.txt:1228, 1242,
  1256). CH ships `AMIN` frames A-I only, so CH's own line renders nothing;
  `ANIM` has K/L/M and CH itself writes `ANIM KLMMLK` for the identical
  flash-pulse two states later. Recorded as a divergence, not re-litigated.
* `RS_BlackMind2.RapidFire` (`RS_Mastermind.zs:2535`): our tree writes
  `ARNQ D 0 A_FaceTarget`, CH writes `ARNQ P` (MASTERMINDS.txt:4018). `ARNQ`
  ships A-M. It is a 0-tic state, so it never rendered either way.

**8. `RS_AbyssMind2.Warp` is a judgement call I made against myself.** It is
reachable from Missile (all three attack states end `A_Jump(64,"Warp")`), it
A_Wanders 36 steps, and it drops two `RS_CrackedAbyssMindFall` -- which ARE
damaging, `random(10,60)` Plasma. I did **not** give it a row, because the Falls
are placed on the monster's own position as a departure effect rather than
aimed at anything. If the composer wants every state that "fires something", this
is the one row I left out on judgement rather than on fact.

**9. Two payloads named by CH exist but are never fired by any state in this
family.** `RS_QueenPainPlasmaBlast` (`RS_MastermindFX.zs:2228`, CH
MASTERMINDS.txt:4267 -- a Speed 15 subclass of the black mind's plasma) and
`RS_WhiteMindshoTrail1` (`RS_MastermindFX.zs:2566`, CH:4658 -- `random(2,6)`
Plasma) are defined, complete, and referenced by nothing. Case-insensitive grep
across `zscript/` finds only their own declarations. They are free parts with no
attack attached; recorded here rather than silently dropped.

**10. Sound resolution was NOT checked end-to-end.** Every `sound` and `impact`
field above records the sound NAME as our tree writes it. Per CLAUDE.md, an
unresolved sound name is completely inert -- no error, no warning. I did not
walk `SNDINFO.txt` `$random`/`$alias` chains down to the actual lumps for any of
the ~40 distinct sound names in this catalogue. **If a name here does not
resolve, the row will still look correct and the attack will be silent.** That
check is out of scope for an attack catalogue but is a real hole in it.
