# LostSoul family -- ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Shape words are from that
spec's CLOSED set only; nothing is coined here.

| | |
|---|---|
| Family | LostSoul (Colourful Hell tiers 1-13 + minions) |
| Monsters carrying attacks | **16** bodies in `RS_LostSoul.zs` + **5** minion monsters defined in `RS_LostSoulFX.zs` = **21** attackers |
| Attack rows written | **55** |
| Denominator read | **101 classes** (25 in `RS_LostSoul.zs`, 76 in `RS_LostSoulFX.zs`), **374 state labels** (196 + 178), read whole. Plus **21 payload classes opened in other families' files** (see "Payloads that live elsewhere"). |
| Source files | `E:\RS_Main\zscript\monsters\lostsoul\RS_LostSoul.zs`<br>`E:\RS_Main\zscript\monsters\lostsoul\RS_LostSoulFX.zs` |
| CH diffed against | `E:\New folder\ART SOURCE\CH\decorate\lostsouls.txt` (3042 lines) + `Revenants.txt`, `Barons.txt`, `Archviles.txt`, `Hellknights.txt`, `Fatsos.txt`. **All 16 monster bodies and all 55 FX payloads diffed line-by-line; see "CH diff result" below.** |

---

## CH diff result -- read this before trusting any row

`C:\Users\Command\Desktop\CH` **does not exist on this machine.** The CH copy
that CLAUDE.md also names as source of truth -- `E:\New folder\ART SOURCE\CH\` --
does, and it is the same pack: every one of the 25 CH line offsets our file
headers cite (`lostsouls.txt:1, :18, :40, :131, :203, :285, :308, :533, :552,
:629, :648, :722, :758, :848, :928, :1003, :1085, :1244, :1263, :1273, :1413,
:1771, :1870, :1906, :2225`) lands exactly on the actor it claims. That is the
copy used here.

Every monster body and every payload was normalised (comments stripped, case
folded, `RS_` prefix removed) and diffed against CH. **The only differences are
the already-documented ZScript translations.** No attack semantics disagree:

* `A_ChangeFlag(x,bool)` -> `{ bX = ...; }`, `A_SetUserVar` -> field write,
  `ThrustThing(angle,...)` -> `ThrustThing(int(angle),...)` -- ZScript form.
* `A_JumpIfTargetInLOS(4,75)` -> `A_JumpIfTargetInLOS("KeepUp",75)` -- numeric
  state offset replaced by an added label; state counts unchanged
  (`RS_YellowLSoul`, `RS_RedLSoul`).
* `Game "Doom";` deleted (DECORATE-only), duplicate `Scale` deleted
  (`RS_HomingRocketTrailFatso`).
* ACS strips: `AnnounceBlackSoul` / `AnnounceWhiteSoul` announcers, and
  **`ACS_NamedExecuteWithResult("BaronMissile",1)` at 3 sites** -- a
  lead-predicted vanilla BaronBall shot that our tree does not fire at all.
  Those three states are now inert 5-tic frames. Flagged below.
* Four sprite-frame corrections, all previously recorded in the file headers
  and all confirmed against CH here: `SBSI`->`SBS1` (`RS_Homer1`),
  `MISL E`->`MISL D` (`RS_RedDeathRev`), `RMGG`->`RNGG` x4
  (`RS_ArchRingHelp`), `XXBF T`->`XXBF S` (`RS_BigHK2`, `RS_BigHK3`).
* Foreign-family spawns wrapped in the runtime `String.Format` guard idiom
  (`RS_HKEgg`, `RS_RevEgg`, `RS_SkullWSoulEX1`) -- same call, deferred lookup.

Nothing else. **Damage rolls, angles, tic counts, projectile classes, sounds
and A_Explode radii are byte-for-byte CH.**

---

## Family-wide idioms you must know to read a row

**1. THIS IS THE CHARGE FAMILY.** 13 of the tree's ~13 CHARGE attacks are here.
`A_SkullAttack(speed)` sets `MF_SKULLFLY` on the MONSTER, plays its
`AttackSound`, and launches the whole body at the target. There is no payload
class. The `payload` field on those rows names the monster itself. Contact
damage is the monster's own `Damage` property, and the engine multiplies it by
`random(1,8)` on the skull-fly hit -- so `Damage 3` is 3..24, not 3. Default
speed with no argument is `SKULLSPEED` = 20.

**2. AN ACTION FIRES ONCE PER FRAME LETTER, NOT ONCE PER LINE.**
`BOSF ABCD 1 Bright A_SkullAttack;` is FOUR A_SkullAttack calls on four
consecutive tics, not one. Every count in this file was taken by counting
frame letters, per `project_rs_multiframe_explode`. Same for the many
`A_Explode` lines.

**3. CH'S MALFORMED `A_CustomMissile` ARGUMENT ORDER.** The idiom
`A_CustomMissile("X",16,0,CMF_AIMOFFSET,random(0,360),random(0,360))` appears
**118 times** in this family. `A_CustomMissile`'s signature is
`(type, spawnheight, spawnofs_xy, angle, flags, pitch)`, so this puts
`CMF_AIMOFFSET` (== 1) in the **angle** slot -- a 1-degree offset -- and a
random 0..360 integer into the **flags bitfield**, randomly setting
`CMF_AIMDIRECTION`/`CMF_TRACKOWNER`/`CMF_ABSOLUTEPITCH`/`CMF_ABSOLUTEANGLE`
etc. shot by shot. This is CH's own text, transcribed faithfully. It is mostly
harmless (`RS_WSSmore` and `RS_SparkPuff1` are cosmetic) but it is **not**
harmless on `RS_BigHK3` (`random(15,45)` Fire) and `RS_REDTHINGSHK`. Recorded,
not corrected. See UNRESOLVED.

**4. `A_PainAttack` / `A_DualPainAttack` / `A_PainDie` fire LIVE MONSTERS as
missiles.** Vanilla geometry: `A_PainAttack` = 1 at the facing angle,
`A_DualPainAttack` = 2 at +45 and -45, `A_PainDie` = 3 at +90/+180/+270. Rows
using them are FAN with the payload flagged as a live monster.

**5. `RS_ColorTierIconCH*` spawns are the tier token, not an attack.** Stripped
from every row, as are the `LFX1`/`SKUL`/`BOSF`/`WASP`/`ETHS`/`FRGO`/`BST7-9`/
`ABSP` sprite letters. Only tics and angles survive.

**6. There is not one `A_VileAttack` in this family.** `A_VileTarget` appears
5 times -- it only PLACES an actor at the target's feet, it does no burn
damage. So the shape `VILE` is used zero times here.

---

## Payloads that live elsewhere (opened, not guessed)

| Class | Defined at | Damage / note |
|---|---|---|
| `RS_Cacospit1` | `zscript/monsters/cacodemon/RS_CacodemonFX.zs:782` | `random(10,45)` Plasma, spd 17 |
| `RS_CacoFire2` | `RS_CacodemonFX.zs:811` | `random(6,35)` Plasma, spd 18 |
| `RS_Cacofire3` | `RS_CacodemonFX.zs:841` | `random(10,50)` Fire, seeker; Death = 3 growing explodes to `random(16,64)`/r112 |
| `RS_Cacofire4` | `RS_CacodemonFX.zs:879` | `random(5,25)` Fire, seeker |
| `RS_SpitFireCaco` | `RS_CacodemonFX.zs:909` | `random(10,65)` Fire, Doom-bounce x8 |
| `RS_SbombCaco` | `RS_CacodemonFX.zs:991` | `random(5,80)` Plasma, Scale 2 |
| `RS_CrackodemonBall` | `RS_CacodemonFX.zs:1025` | `random(5,55)` Plasma |
| `RS_Zap88` | `RS_CacodemonFX.zs:66` | cosmetic lightning flick, no damage |
| `RS_PlasmaBallSP4` | `RS_CacodemonFX.zs:132` | `random(3,7)` Plasma, spd 9 |
| `RS_Trail11` / `RS_Trail12` | `RS_ChaingunnerFX.zs:84` / `:111` | inert trail puffs |
| `RS_RedRevLoad` | `RS_ChaingunnerFX.zs:230` | charge-up flare, no damage |
| `RS_SparkPuff1` | `RS_ShotgunnerFX.zs:209` | cosmetic spark, no damage |
| `RS_WormLewd` | `RS_DemonFX.zs:364` | `random(5,23)` Melee; Death `A_Explode(random(1,7),32)` |
| `RS_RedThingsLS` | `RS_DemonFX.zs:115` | inert blood flecks |
| `RS_HKRedDeath` | `RS_ZombiemanFX.zs:844` | Fire; Death `A_Explode(random(5,10),42)` + `A_Burst` |
| `RS_RedThingsHK` | `RS_ZombiemanFX.zs:816` | inert |
| `RS_CrackoBallTrail` | `RS_ImpFX.zs:417` | inert |
| `RS_Bounc22` | `RS_ImpFX.zs:727` | bouncing sub-fleck |
| `RS_Firespe2` | `RS_ImpFX.zs:327` | lingering flame |
| `RS_GrowRaisin` / `RS_CHBoner` | `RS_ZombiemanFX.zs:72` / `:73` | Inventory tokens (buffs) |
| vanilla | engine | `RevenantTracer` (spd 10, Damage 10, seeker), `CacodemonBall` (spd 10, Damage 5), `BaronBall` via `A_BruisAttack` (spd 15, Damage 8), `FatShot` via `A_FatAttack1/2/3` (spd 20, Damage 8), `ArchvileFire`, `Health`, `HealthBonus`, `BackPack` |

---

# ROWS

## RS_BrownLSoul2 -- "THE CUBE", tier 13 (`RS_LostSoul.zs:228`)

```
ATTACK   RS_BrownLSoul2.Missile
file     zscript/monsters/lostsoul/RS_LostSoul.zs:279
shape    CHARGE
payload  RS_BrownLSoul2 (the monster itself)  x8 relaunches
arc      --
timing   36-tic windup (4,4,4 x4 frames each, A_FaceTarget), then 1,1,1,1 fire
         / 16 glide / 1,1,1,1 fire / 48 glide, A_Stop
damage   Damage 3   (contact; engine rolls Damage x random(1,8) = 3..24)
type     --   (no DamageType set)
sound    AttackSound "skelatt"   (played by A_SkullAttack itself)
impact   contact only -- no payload, no puff. Engine clears MF_SKULLFLY on the
         hit and returns the cube to See.
trigger  Missile
range    --
mirrored no
inherit  Actor
profile  --   NO CHARGE MODE EXISTS. RS_AttackProfile.zs has BULLET/HEAVY/
         MELEE/HITSCAN/SUMMON/RADIAL/SELFBUFF and nothing that launches the
         firer. Nearest honest stand-in: MakeMelee(range: 20*35, dmgMult: 3.0)
         -- which is not the same attack. See UNRESOLVED.
notes    A_SkullAttack fires 4x on line :279 (4 frame letters, 1 tic each) and
         4x again on :281 -- eight relaunches, each re-aiming. Speed 15 body,
         launch speed 20 (SKULLSPEED default). +MISSILEMORE +MISSILEEVENMORE
         make it pick Missile far more often than vanilla.
```

```
ATTACK   RS_BrownLSoul2.Melee
file     zscript/monsters/lostsoul/RS_LostSoul.zs:288
shape    MELEE
payload  --
arc      --
timing   4 tics windup (A_FaceTarget x4), then 1,1,1,1
damage   A_CustomMeleeAttack(random(1,3))  x4 calls = random(1,3) x4
type     --
sound    "imp/melee"   (passed to A_CustomMeleeAttack)
impact   --
trigger  Melee
range    ..128   (A_CheckRange(128,"See",false) at :289 aborts to See if the
         target is further; otherwise the cube commits to DeathHeal)
mirrored no
inherit  Actor
profile  MakeMelee(range: 128, fireSnd: "imp/melee", profName: "CubeClaw")
notes    4 frame letters = 4 melee calls, so 4..12 total over 4 tics. On
         success it does NOT return to See: it plays "vile/active" for 20 tics
         and falls into DeathHeal -> Death. THE CUBE KILLS ITSELF TO MELEE YOU.
         MeleeThreshold 150 is set on the Default block, recorded as written.
```

```
ATTACK   RS_BrownLSoul2.DeathHeal
file     zscript/monsters/lostsoul/RS_LostSoul.zs:308
shape    UNCLASSIFIED
payload  RS_ArchRingHelp x4  + A_RadiusGive "Health" x1  + A_RadiusGive
         "RS_CHBoner" x1
arc      --
timing   one tic (all four spawns are 0-tic frame letters on :308)
damage   --   (no damage; this beat is pure support)
type     --
sound    "vile/active" (played on the preceding frame, RS_LostSoul.zs:291)
impact   RS_ArchRingHelp is an invisible 9999hp mover that A_VileChase-
         RESURRECTS corpses and A_RadiusGive's RS_GrowRaisin (r60) for ~12
         tics before expiring (RS_LostSoulFX.zs:1810)
trigger  Melee   (also entered from the Heal state, RS_LostSoul.zs:306)
range    --   (spawn offsets random(-128,128) in x and y)
mirrored no
inherit  Actor
profile  MakeRadial(radius: 320, damage: 0, heal: 200, hitsAllies: true,
         fireSnd: "vile/active", profName: "CubeLastRites")
         -- plus MakeSummon("RS_ArchRingHelp", count: 4, cap: 4)
notes    A_RadiusGive("Health",1200,RGF_MONSTERS,200) hands the vanilla Health
         item, amount 200, to every monster within 1200. A_RadiusGive
         ("RS_CHBoner",320,RGF_MONSTERS) hands the CH buff token within 320.
         The cube's See state runs A_VileChase (RS_LostSoul.zs:271), so it is
         resurrecting the pack the whole time it is alive -- that is context
         for this row, not a row of its own (no payload, no damage).
```

```
ATTACK   RS_BrownLSoul2.Death
file     zscript/monsters/lostsoul/RS_LostSoul.zs:316
shape    UNCLASSIFIED
payload  --   (A_Explode; no projectile)
arc      --
timing   3,3,3   (MISL B, C, D -- three frame letters, three explosions)
damage   A_Explode(random(10,50),128)  x3
type     --   (A_Explode default damage type)
sound    A_Scream (DeathSound "skull/death") on the frame before
impact    self-centred blast, radius 128, three times over 9 tics
trigger  Death
range    --
mirrored no
inherit  Actor
profile  MakeRadial(radius: 128, damage: 30, hitsAllies: false,
         fireSnd: "skull/death", profName: "CubeDetonate") x3 pulses
         -- MakeRadial takes a flat int, so the random(10,50) roll has no home
notes    Per-frame explode is DELIBERATE and marked so at the site. Reached
         both from DeathHeal (the melee suicide) and from being killed
         normally. A_Die on the last frame guarantees removal.
```

## RS_CyanLSoul2 -- "Cyan LostSoul", tier 12 (`RS_LostSoul.zs:326`)

```
ATTACK   RS_CyanLSoul2.Missile
file     zscript/monsters/lostsoul/RS_LostSoul.zs:383
shape    CHARGE
payload  RS_CyanLSoul2 (the monster itself)  x5 relaunches
         + RS_BaronCyanBombTrail x10 (inert wake)
arc      --
timing   1,1 face / 1,1,1,1 fire @18 / 9 fire @40 / thrust 30 /
         1x5, 2x5, 3x5, 4x5, 5x5 glide (75 tics) / A_Stop
damage   Damage 2   (contact; engine rolls x random(1,8) = 2..16)
type     --
sound    A_PlaySound("ice/splode",0) on :382.
         AttackSound is EXPLICITLY "" -- A_SkullAttack plays nothing.
impact   contact only. Death is A_IceGuyDie (shatter) + A_KillChildren
         ("Extreme", KILS_FOILINVUL|KILS_KILLMISSILES) which destroys its own
         two eye actors.
trigger  Missile
range    --
mirrored no
inherit  Actor
profile  --   no CHARGE mode. See UNRESOLVED.
notes    TWO-STAGE LAUNCH: A_SkullAttack(18) fires four times (4 frame letters
         on :383) then A_SkullAttack(40) once on :384, then ThrustThing
         (int(angle),30,0,0) on :385 adds another 30 units of forward push.
         The comet accelerates 18 -> 40 -> +30. Body Speed 8, FloatSpeed 11.
         The cyan bomb trail (10 spawns, :387-:388) is NOCLIP, Speed 1, no
         damage -- pure additive wake (RS_LostSoulFX.zs:1311).
         Spawn attaches RS_CyanSoulEye / RS_CyanSoulEye2 (warp-locked eye
         glints, RS_LostSoulFX.zs:103/:131) -- cosmetic, not attacks.
```

## RS_AbyssLSoul2 -- "beetlejuice", tier 9 (`RS_LostSoul.zs:415`)

```
ATTACK   RS_AbyssLSoul2.Missile
file     zscript/monsters/lostsoul/RS_LostSoul.zs:554
shape    SCATTER
payload  RS_BeetleSpitAbyss x4
arc      20   (random(-10,10) per shot, independent rolls)
timing   one tic (four 0-tic frame letters on TNT1 AAAA), after a
         10 / 1 / 2 / 2 / 2,2 windup
damage   DamageFunction (random(1,8))  + PoisonDamage 1
type     Poison
sound    A_PlaySound("BETLEAT2",4) on :552.
         No AttackSound on the monster.
impact   BLVB CDEF 4 Bright, DeathSound "imp/shotx". Bounces first: Hexen
         bounce, BounceFactor 1.25, BounceCount 4, Gravity 0.02, and each
         bounce adds ThrustThingZ(0,9,0,0) -- it skips along the floor.
         Sheds green particles + RS_AbyssShotIdentifier each Fly frame.
trigger  Missile
range    600..   (A_JumpIfCloser(600,"Rush") on :550 skips the spit entirely
         when the target is closer)
mirrored no
inherit  Actor   (payload RS_BeetleSpitAbyss : Actor, RS_LostSoulFX.zs:162)
profile  MakeVolley("RS_BeetleSpitAbyss", count: 4, arc: 20,
         fireSnd: "BETLEAT2", profName: "BeetleSpit")
         -- then p.MinRange = 600;
notes    Spawn height 18. The four shots leave on the same tic, hence SALVO's
         timing with SCATTER's angles -- SCATTER chosen because the per-shot
         random(-10,10) is the defining feature, matching the spec's own
         51-instance idiom.
```

```
ATTACK   RS_AbyssLSoul2.Rush
file     zscript/monsters/lostsoul/RS_LostSoul.zs:557
shape    CHARGE
payload  RS_AbyssLSoul2 (the monster itself)  x1 per pass
arc      --
timing   8 fire / 7,7 recover (A_FaceTarget), then re-enters at Missile+3
damage   Damage 1   (contact; engine rolls x random(1,8) = 1..8)
type     --
sound    --   NO AttackSound on the Default block, so A_SkullAttack is SILENT.
         "BETLEAT1"/"BETLEAT2" belong to the melee and spit, not this.
impact   contact only
trigger  Missile
range    ..600   (entered by A_JumpIfCloser(600) from Missile, or by falling
         through the spit)
mirrored no
inherit  Actor
profile  --   no CHARGE mode. See UNRESOLVED.
notes    Loops: Rush -> A_JumpIfCloser(90,"Melee") -> else Goto Missile+3,
         which re-runs the spit windup and rushes again. Body Speed 8; launch
         speed 20 (default). Mass 5000 -- almost unpushable.
```

```
ATTACK   RS_AbyssLSoul2.Melee
file     zscript/monsters/lostsoul/RS_LostSoul.zs:562
shape    MELEE
payload  --
arc      --
timing   1,1   (two frame letters = two calls)
damage   A_CustomMeleeAttack(random(5,15))  x2 = random(5,15) x2
type     --
sound    "Skull/melee" (to A_CustomMeleeAttack); then A_PlaySound("BETLEAT1",4)
impact   --
trigger  Melee
range    ..90   (A_JumpIfCloser(90,"Melee") from Rush, :559)
mirrored no
inherit  Actor
profile  MakeMelee(range: 90, fireSnd: "Skull/melee", dmgMult: 1.0,
         profName: "BeetleBite")
notes    Followed by A_JumpIfCloser(72,"Wrap") on 3 frame letters (:564) -- if
         still inside 72 the beetle escalates to the grapple below.
```

```
ATTACK   RS_AbyssLSoul2.Wrap
file     zscript/monsters/lostsoul/RS_LostSoul.zs:570
shape    SINGLE
payload  RS_WormLewd x1  (per Wrap pass; the state Loops)
arc      --
timing   1 warp / 1 warp / 0 fire / 0 heal / 24 tics of warp-clinging
         (BST8 BEBEBEBEBEBEBEBEBEBEBEBE 1, 24 frame letters), then Loop
damage   DamageFunction (random(5,23))
type     Melee
sound    A_PlaySound("BETLEAT1",4) on :568. The payload's own SeeSound is ""
         and its DeathSound is "x", which resolves to nothing in CH's SNDINFO
         -- silent in CH too, kept verbatim.
impact   BAL1 CDE 2 Bright A_Explode(random(1,7),32,0) -- 3 frames, 3 blasts
         (RS_DemonFX.zs:364)
trigger  Melee
range    ..72
mirrored no
inherit  Actor   (RS_WormLewd : Actor, RS_DemonFX.zs:364)
profile  MakeVolley("RS_WormLewd", count: 1, fireSnd: "BETLEAT1",
         profName: "BeetleDrain")
         -- the warp and the self-heal have no profile expression at all
notes    THE GRAPPLE. A_Warp(AAPTR_TARGET, random(-1,3), 0, 12,
         random(-45,45), WARPF_ABSOLUTEANGLE|WARPF_NOCHECKPOSITION|
         WARPF_INTERPOLATE) teleports the beetle onto the player's head, fires
         the drain point-blank, then HealThing(5,300) heals itself 5 (cap 300)
         and A_JumpIfTargetInLOS("See",1) checks for escape. Then 24 more tics
         of warping and it loops -- it rides you until the LOS check fires.
         The stealth states (Hide/HideGround/HideRoof/Stalk/Stalk2/PopYet/
         DropYet/Now/Now2, :484-:546) carry NO attack: the beetle shrinks to
         0.5x0.05 scale at 20% alpha, A_Wanders, and pops back at 128 units
         or after 100 ticks of user_pop. Recorded so nobody re-reads it.
```

## RS_GrayLSoul2 -- "A hive", tier 8 (`RS_LostSoul.zs:607`)

```
ATTACK   RS_GrayLSoul2.Missile
file     zscript/monsters/lostsoul/RS_LostSoul.zs:666
shape    FAN
payload  RS_BlackLSoul2 x2   (LIVE MONSTERS -- bees, RS_LostSoul.zs:1583)
arc      90   (A_DualPainAttack fires at facing+45 and facing-45)
timing   one tic, after a 5,5,5,5 swelling windup (A_SetScale 1.1/1.4 ->
         1.2/1.3 -> 1.3/1.2 -> 1.2/1.3); 5,5 to deflate afterwards
damage   --   (the payload is a monster; its own attacks are its rows)
type     --
sound    --   AttackSound is EXPLICITLY "". The hive fires SILENT.
         (Correct for a profile slot -- the gun's own sound fills it.)
impact   the bees fly, charge and bite on their own -- see RS_BlackLSoul2
trigger  Missile
range    --
mirrored no
inherit  Actor
profile  MakeSummon("RS_BlackLSoul2", count: 2, cap: 8, tierOffset: -2,
         profName: "HiveRelease")
notes    Body is Speed 2, FloatSpeed 2, +SPAWNCEILING, +NOPAIN, YScale 1.5 --
         a ceiling sac, not a flier. Health 50, DamageFactor "fire" 1.7.
         The See state emits gray particles (:657) -- cosmetic.
```

```
ATTACK   RS_GrayLSoul2.Crash
file     zscript/monsters/lostsoul/RS_LostSoul.zs:680
shape    FAN
payload  RS_BlackLSoul2 x3   (LIVE MONSTERS)
arc      270   (A_PainDie's vanilla geometry: facing+90, +180, +270)
timing   one tic, after Death's 5 + 30 tic fall (A_Fall then A_SetScale(1.5,1.0))
damage   --
type     --
sound    A_Scream (DeathSound "Hornet/Death") AFTER the release, on :681
impact   three live bees
trigger  Death
range    --
mirrored no
inherit  Actor
profile  MakeSummon("RS_BlackLSoul2", count: 3, cap: 8,
         fireSnd: "Hornet/Death", profName: "HiveBurst")
notes    Crash is entered by falling off the end of Death. Twelve gray
         particle spawns precede it (:679) -- cosmetic. THE HIVE IS A BOMB:
         killing it releases MORE bees than shooting it does.
```

## RS_FireBluLSoul2 -- "Charred skull", tier 7 (`RS_LostSoul.zs:690`)

```
ATTACK   RS_FireBluLSoul2.Missile
file     zscript/monsters/lostsoul/RS_LostSoul.zs:739
shape    CHARGE
payload  RS_FireBluLSoul2 (the monster itself)  x1
arc      --
timing   10 windup (A_FaceTarget) / 4 fire / 4,4 glide, then Goto Missile+3
         -> 4,4 more glide, then FALLS THROUGH INTO Melee
damage   Damage 3   (contact; engine rolls x random(1,8) = 3..24)
type     --
sound    AttackSound "skull/melee"   (played by A_SkullAttack)
impact   contact only
trigger  Missile
range    --
mirrored no
inherit  Actor
profile  --   no CHARGE mode. See UNRESOLVED.
notes    THE FALL-THROUGH IS THE POINT and it is CH's, verbatim. `Goto
         Missile+3` lands on the second glide state; the Missile block then
         ENDS, and execution continues into the next label, which is Melee --
         the suicide burst. So a charge that does not connect within ~22 tics
         detonates the skull anyway. Body Speed 15. Only ONE A_SkullAttack
         here (one frame letter, :739) -- unlike the cube.
```

```
ATTACK   RS_FireBluLSoul2.Melee
file     zscript/monsters/lostsoul/RS_LostSoul.zs:743
shape    MELEE
payload  --
arc      --
timing   1,1 melee / then 2,2,2 detonation frames
damage   A_CustomMeleeAttack(random(3,8)) x2, THEN
         A_Explode(random(10,50),128) x3
type     --
sound    "Skull/melee"
impact   self-centred blast r128 three times over 6 tics, then A_Die
trigger  Melee
range    --   (MeleeThreshold 150 on the Default block, as written)
mirrored no
inherit  Actor
profile  MakeMelee(range: 64, fireSnd: "Skull/melee", profName: "CharredTouch")
         -- followed by MakeRadial(radius: 128, damage: 30) x3.
         The two-stage "hit then detonate" has no single factory.
notes    SUICIDE. `A_Die` on :746 ends the actor -- the Death state below is
         NOT run from here, so the melee blast is 3 explosions, not 6.
```

```
ATTACK   RS_FireBluLSoul2.Death
file     zscript/monsters/lostsoul/RS_LostSoul.zs:759
shape    UNCLASSIFIED
payload  --   (A_Explode; no projectile)
arc      --
timing   3,3,3   (three frame letters after a 3,3,3,3,3 death animation)
damage   A_Explode(random(10,50),128)  x3
type     --
sound    A_Scream (DeathSound "skull/death") on :755
impact   self-centred blast r128 x3, then ThrustThingZ(0,2,1,0) and A_Die
trigger  Death
range    --
mirrored no
inherit  Actor
profile  MakeRadial(radius: 128, damage: 30, fireSnd: "skull/death",
         profName: "CharredDeath") x3
notes    Same detonation as the melee, on a slower animation. Killing this
         thing at point-blank is as bad as letting it touch you.
```

## RS_CommonLSoul -- tier 1 (`RS_LostSoul.zs:770`)

```
ATTACK   RS_CommonLSoul.Missile
file     zscript/monsters/lostsoul/RS_LostSoul.zs:797
shape    CHARGE
payload  RS_CommonLSoul (the monster itself)  x1
arc      --
timing   10 windup / 4 fire / 0 (icon) / 4,4 glide, then Goto Missile+2 ->
         0/4/4 again, then falls into Pain (A_Pain, Goto See)
damage   Damage 3   (INHERITED from vanilla LostSoul; contact roll x random(1,8))
type     --
sound    AttackSound "skull/melee"   (INHERITED from vanilla LostSoul)
impact   contact only
trigger  Missile
range    --
mirrored no
inherit  LostSoul (vanilla)  -- Health 100, Radius 16, Height 56, Mass 50,
         Speed 8, Damage 3, DeathSound "skull/death", ActiveSound
         "skull/active" all come from the parent. Our subclass adds only
         Species "LSoul", the DamageFactors, +DONTHARMSPECIES,
         +MISSILEMORE, +MISSILEEVENMORE and the Tag.
profile  --   no CHARGE mode. See UNRESOLVED.
notes    The baseline the other twelve tiers are variations on. Launch speed
         20 (default). The `Goto Missile+2` loop runs once and then exits via
         the Pain block, so this is a single charge, not a chain.
```

## RS_GreenLSoul -- "Green LostSoul", tier 2 (`RS_LostSoul.zs:813`)

```
ATTACK   RS_GreenLSoul.Missile
file     zscript/monsters/lostsoul/RS_LostSoul.zs:860
shape    CHARGE
payload  RS_GreenLSoul (the monster itself)  x1
arc      --
timing   10 windup / 4 fire / 0 / 4,4 glide, Goto Missile+2 -> 0/4/4, then
         FALLS THROUGH INTO Melee
damage   Damage 3   (contact; x random(1,8) = 3..24)
type     --
sound    AttackSound "skull/melee"
impact   contact only
trigger  Missile
range    --
mirrored no
inherit  LostSoul (vanilla)
profile  --   no CHARGE mode. See UNRESOLVED.
notes    Same fall-through as the fireblu: Missile ends and flow continues
         into Melee, which throws the poison splash. Body Speed 8.
```

```
ATTACK   RS_GreenLSoul.Melee
file     zscript/monsters/lostsoul/RS_LostSoul.zs:865
shape    MELEE
payload  RS_SplasherSoul x1  (secondary, thrown on the follow-up frame)
arc      --
timing   9,9 melee (two frame letters) / 0 throw
damage   A_CustomMeleeAttack(random(3,8)) x2;
         payload DamageFunction (random(5,15))
type     --  melee / Poison for the splash
sound    "Skull/melee"; the splash has no SeeSound
impact   RS_SplasherSoul Spawn is `BAL7 CDE 5 Bright A_Explode(random(5,15),48)`
         -- THREE explosions over 15 tics, radius 48, at Speed 5 (it creeps
         forward while burning). DeathSound "baron/shotx", Scale 1.6,
         RenderStyle Add. (RS_LostSoulFX.zs:206)
trigger  Melee
range    --   (MeleeThreshold 150)
mirrored no
inherit  Actor   (RS_SplasherSoul : Actor)
profile  MakeMelee(range: 64, fireSnd: "Skull/melee", profName: "GreenClaw")
         + MakeVolley("RS_SplasherSoul", count: 1, profName: "PoisonSplash")
notes    Spawn height 30. The splash has NO Death state -- its Spawn block
         ends in Stop, so the three A_Explodes ARE the whole payload.
```

```
ATTACK   RS_GreenLSoul.Death
file     zscript/monsters/lostsoul/RS_LostSoul.zs:876
shape    SINGLE
payload  RS_SplasherSoul x1
arc      --
timing   one 0-offset throw on the third death frame (6-tic frames throughout)
damage   DamageFunction (random(5,15)) + A_Explode(random(5,15),48) x3
type     Poison
sound    A_Scream (DeathSound "skull/death") on the frame before
impact   as above -- 3 blasts, r48, over 15 tics
trigger  Death
range    --
mirrored no
inherit  Actor
profile  MakeVolley("RS_SplasherSoul", count: 1, fireSnd: "skull/death",
         profName: "GreenDeathSplash")
notes    Spawn height 30, angle 0 -- aimed at whatever it was facing when it
         died, not at the killer.
```

## RS_BlueLSoul -- "Blue LostSoul", tier 3 (`RS_LostSoul.zs:887`)

```
ATTACK   RS_BlueLSoul.RushIt
file     zscript/monsters/lostsoul/RS_LostSoul.zs:943
shape    CHARGE
payload  RS_BlueLSoul (the monster itself)  x1 every 12 tics, INDEFINITELY
arc      --
timing   8 windup / 4 fire / 4,4 glide / Goto RushIt+1 -> re-fires
damage   Damage 3   (contact; x random(1,8) = 3..24)
type     --
sound    AttackSound "skull/melee"
impact   contact only
trigger  Missile   (via A_JumpIfCloser(650,"RushIt") at :935, or the 50/50 at
         :939)
range    ..650 always; 650.. at 50% odds
mirrored no
inherit  LostSoul (vanilla)
profile  --   no CHARGE mode. See UNRESOLVED.
notes    THE ONLY UNBOUNDED CHARGE LOOP IN THE FAMILY. `Goto RushIt+1` lands
         back on the A_SkullAttack state, so it relaunches every 12 tics until
         it connects (the engine drops MF_SKULLFLY and sends it to See) or it
         dies. Body Speed 9.
         Branch logic verbatim: A_JumpIfCloser(650,"RushIt") -> A_Jump(255,
         "Decision") -> A_Jump(255,"RushIt","Psychic"). So inside 650 it
         ALWAYS charges; outside 650 it is a coin flip.
```

```
ATTACK   RS_BlueLSoul.Psychic
file     zscript/monsters/lostsoul/RS_LostSoul.zs:949
shape    HITSCAN
payload  RS_PsychPuff (puff class only -- A_CustomBulletAttack traces, nothing
         travels)
arc      12 horizontal / 12 vertical   (spread ±6, ±6)
timing   7 windup / 0 sound / 4 fire (one tic, all bullets) / 4,4 recover
damage   A_CustomBulletAttack(6, 6, random(1,15), random(1,2), "RS_PsychPuff")
         -- random(1,15) BULLETS, each random(1,2) damage, engine default
         multiplies each by random(1,3) (no CBAF_NORANDOM flag set)
type     --
sound    A_PlaySound("fire/fire4") on :948
impact   RS_PsychPuff: PLSE A 4 Bright, PLSE B 4, then Melee: PLSE CDE 4.
         Translucent, Alpha 0.5, Scale 0.3, VSpeed 1, +ALLOWPARTICLES.
         NO damage of its own -- pure visual. (RS_LostSoulFX.zs:1095, CH
         Revenants.txt:2279)
trigger  Missile
range    650..   at 50% odds (see RushIt)
mirrored no
inherit  Actor
profile  MakeHitscan(fireSnd: "fire/fire4", spreadScale: 0.05,
         impactPuff: "RS_PsychPuff", profName: "PsychicVolley")
         -- note MakeHitscan has NO pellet-count parameter; the random(1,15)
         bullet count has to ride the weapon's own rolled PelletCount, or
         PelletOverride post-construction.
notes    THE ONLY HITSCAN IN THE FAMILY. The 1..15 bullet count is a very wide
         roll -- a burst can be a tickle or a shotgun blast. Goto Missile
         after, so it re-decides.
```

```
ATTACK   RS_BlueLSoul.Melee
file     zscript/monsters/lostsoul/RS_LostSoul.zs:953
shape    MELEE
payload  --
arc      --
timing   9,9   (two frame letters = two calls)
damage   A_CustomMeleeAttack(random(4,9)) x2
type     --
sound    "Skull/melee"
impact   --
trigger  Melee
range    --   (MeleeThreshold 150)
mirrored no
inherit  LostSoul (vanilla)
profile  MakeMelee(range: 64, fireSnd: "Skull/melee", profName: "BlueClaw")
notes    Highest per-hit melee roll of the vanilla-shaped tiers.
```

## RS_PurpleLSoul -- "Purple LostSoul", tier 4 (`RS_LostSoul.zs:974`)

```
ATTACK   RS_PurpleLSoul.Missile
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1027
shape    CHARGE
payload  RS_PurpleLSoul (the monster itself)  x1 per approach cycle
arc      --
timing   0 (set +THRUACTORS) / 0 (icon) / 8 windup / 4 fire @35 / 4,4 check
         loop; Reset clears +THRUACTORS and Goto Missile+3 re-fires
damage   Damage 3   (contact; x random(1,8) = 3..24)
type     --
sound    AttackSound "skull/melee"
impact   contact only
trigger  Missile
range    ..100 re-triggers   (A_JumpIfCloser(100,"Reset") on 2 frame letters,
         :1028)
mirrored no
inherit  LostSoul (vanilla)
profile  --   no CHARGE mode. See UNRESOLVED.
notes    THE PHASE CHARGE. `bTHRUACTORS = true` is set BEFORE the launch and
         cleared only in Reset, so the whole flight passes through other
         actors -- you cannot body-block it, and it cannot be stopped by its
         own pack. Launch speed 35, the second-fastest charge in the family
         (only the bee's 30 and the cyan's 40 second stage compare).
         The loop is: fire -> glide checking A_JumpIfCloser(100) -> when
         inside 100, Reset (solid again) -> Missile+3 -> fire again.
         Pain also routes through Reset2 to clear the flag (:1037-:1040).
         +NOTARGET is set: it does not retaliate at what hurt it.
```

## RS_YellowLSoul -- "Yellow LostSoul" / the Forgotten One, tier 5 (`RS_LostSoul.zs:1055`)

```
ATTACK   RS_YellowLSoul.Missile
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1111
shape    CHARGE
payload  RS_YellowLSoul (the monster itself)  -- relaunches while it can see you
arc      --
timing   2,2,2,2,2 windup (5 frame letters, A_FaceTarget) / 0 sound / 2 fire /
         2 glide / 0 LOS check / 0 abort roll / 2,2 glide / Goto Missile+11
damage   Damage 5   (contact; x random(1,8) = 5..40)
type     --
sound    A_PlaySound("Forgotten/Attack") on :1110.
         NO AttackSound on the Default block -- A_SkullAttack itself is silent.
impact   contact only
trigger  Missile
range    --   (gated by FOV, not distance: A_JumpIfTargetInLOS("KeepUp",75))
mirrored no
inherit  Actor
profile  --   no CHARGE mode. See UNRESOLVED.
notes    THE CHAIN-CHARGER. A_JumpIfTargetInLOS("KeepUp",75) on :1113 -- if the
         target is inside a 75-degree cone, jump to KeepUp, which is
         `Goto Missile+8` = straight back onto the A_SkullAttack state. It
         re-rams as long as you stay in front of it. Otherwise A_Jump(24,
         "StopCharge") gives a 24/256 chance per pass to A_Stop and return to
         See; failing that it loops Missile+11 -> +13 -> +11.
         CH wrote the LOS jump as a numeric offset `A_JumpIfTargetInLOS(4,75)`;
         our tree adds the label KeepUp with no change to state count.
         +FLOATBOB is toggled OFF for the whole attack and back ON in Pain.
```

```
ATTACK   RS_YellowLSoul.Death
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1134
shape    FAN
payload  RS_CommonLSoul x3   (LIVE MONSTERS, via A_PainDie)
         + A_Explode(random(5,15),64) x1
arc      270   (A_PainDie: facing+90, +180, +270)
timing   4,4 / 6 scream / 6 explode / 6 unblock / 6 SPLIT
damage   A_Explode(random(5,15),64)  x1 (one frame letter on :1134)
type     --
sound    A_Scream (DeathSound "Forgotten/Death") on :1133
impact   three live tier-1 lost souls, each with its own charge
trigger  Death
range    --
mirrored no
inherit  Actor
profile  MakeRadial(radius: 64, damage: 10, profName: "ForgottenBurst")
         + MakeSummon("RS_CommonLSoul", count: 3, cap: 6,
                      fireSnd: "Forgotten/Death", profName: "ForgottenSplit")
notes    IT SPLITS. Kill one Forgotten One and you get three common souls.
         The explode and the split are 18 tics apart, not simultaneous.
```

## RS_RedLSoul -- "Bloody Red LostSoul", tier 6 (`RS_LostSoul.zs:1145`)

```
ATTACK   RS_RedLSoul.Spit
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1209
shape    BURST
payload  RS_SpitBoltLS x3
arc      16 jitter   (random(-8,8), rolled independently per shot -- this is
         aim scatter, not a fixed spread pattern)
timing   8 face / 5 SHOT / 6 face / 0 / 3 SHOT / 4 face / 1 SHOT
         -- an accelerating 3-round burst, re-aimed between each
damage   DamageFunction (random(5,42))
type     Plasma
sound    SeeSound "Spell/spellCast1" on the payload; the monster plays nothing
impact   BAL1 C 4 A_SetTranslucent(0.35) / BAL1 DE 5, DeathSound "fire/Fire4".
         NO explosion. Speed 21, Mass 25, Scale 0.60, RenderStyle Add.
         Sheds RS_REDTHINGSHK every Spawn frame (:257) using the malformed
         CMF_AIMOFFSET argument order -- see idiom 3.
         (RS_LostSoulFX.zs:236)
trigger  Missile
range    --
mirrored no
inherit  Actor
profile  MakeBurst("RS_SpitBoltLS", count: 3, delayTics: 5, arc: 16,
         fireSnd: "Spell/spellCast1", profName: "RedSpit")
         -- MakeBurst's delayTics is UNIFORM. CH's gaps are 11, 9, then the
         last shot; 5 tics x3 = 15 vs CH's ~27 total. RECORDED, not rounded
         away. If the cadence matters, it needs three chained profiles.
notes    Spawn height 12. Reached only via A_Jump(256,"Charge","Spit") after
         A_Jump(126,"Charge") already took ~49% -- so Spit fires on roughly
         one attack in four.
```

```
ATTACK   RS_RedLSoul.Charge
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1220
shape    CHARGE
payload  RS_RedLSoul (the monster itself)  -- relaunches while in FOV
         + RS_RedThingsLS x3 per pass (inert flecks)
arc      --
timing   2,2,2,2,2 windup / 0 sound / 0 fleck / 2 FIRE @23 / 0 fleck /
         2 glide / 0 fleck / 0 LOS check / 0 abort roll / 2,2 / Goto Charge+8
damage   Damage 5   (contact; x random(1,8) = 5..40)
type     --
sound    A_PlaySound("Forgotten/Attack") on :1218.
         NO AttackSound on the Default block.
impact   contact only
trigger  Missile
range    --   (FOV-gated, A_JumpIfTargetInLOS("KeepUp",75))
mirrored no
inherit  Actor
profile  --   no CHARGE mode. See UNRESOLVED.
notes    Same chain-charge machine as the Yellow, at launch speed 23 instead
         of the default 20, and shedding RS_RedThingsLS blood flecks on three
         frames of every pass (:1219, :1221, :1223 -- inert, Speed 9,
         Scale 0.15, RS_DemonFX.zs:115). KeepUp -> `Goto Charge+5` replays
         the sound AND the launch. Body Speed 11, Scale 1.15, Health 240.
```

```
ATTACK   RS_RedLSoul.Death
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1246
shape    UNCLASSIFIED
payload  RS_HKREDDEATH x1  (a delayed second blast)
arc      --
timing   4,4 EXPLODE (two frame letters) / 6 scream / 6 EXPLODE / 6 unblock /
         6 spawn the barrel blast
damage   A_Explode(random(5,15),64) x3 total (2 on :1246 + 1 on :1248),
         then RS_HKRedDeath's own A_Explode(random(5,10),42)
type     --  / Fire for the barrel blast
sound    A_Scream (DeathSound "Forgotten/Death"); RS_HKRedDeath plays
         "world/barrelx" twice
impact   RS_HKRedDeath: Spawn plays world/barrelx and immediately Goto Death;
         MISL B 8 Bright A_Explode(random(5,10),42), MISL C 6 sound,
         MISL D 3 A_Burst("RS_RedThingsHK"). (RS_ZombiemanFX.zs:844)
trigger  Death
range    --
mirrored no
inherit  Actor
profile  MakeRadial(radius: 64, damage: 10, fireSnd: "Forgotten/Death",
         profName: "RedDeathBlast") x3
         + MakeVolley("RS_HKREDDEATH", count: 1, profName: "RedDeathBarrel")
notes    Four separate blasts across ~26 tics -- three from the corpse and one
         delayed from the spawned barrel actor. Pain (:1234-:1242) also sheds
         three RS_RedThingsLS flecks; those are inert and are NOT an attack.
```

## RS_BlackLSoulOld3 -- "Queen Bee", CH's orphan, tier 10 (`RS_LostSoul.zs:1260`)

CH's orphan: defined at `lostsouls.txt:1273`, spawned by nothing anywhere in CH.
Imported whole. Reachable only by console summon.

```
ATTACK   RS_BlackLSoulOld3.Spawn
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1308
shape    UNCLASSIFIED
payload  RS_BlackLSoul2 x46   (LIVE MONSTERS, SXF_SETMASTER)
arc      --   (positional, not angular: random(-16,16) x, random(-16,16) y,
         random(-6,10) z)
timing   one tic -- two lines of 23 zero-tic frame letters each
damage   --
type     --
sound    --
impact   46 live bees, mastered to the queen
trigger  Spawn
range    --
mirrored no
inherit  Actor
profile  MakeSummon("RS_BlackLSoul2", count: 46, cap: 46, tierOffset: -2,
         profName: "QueenEscortOld")
notes    UNCLASSIFIED because the closed set has no word for a positional
         (non-angular) mass spawn. 46 bees at once -- more than double the
         live queen's 6. This is why the orphan was cut.
```

```
ATTACK   RS_BlackLSoulOld3.Missile
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1345
shape    CHARGE
payload  RS_BlackLSoulOld3 (the monster itself)  x1
arc      --
timing   0 sound / 0 spark / 2 face / 0 spark / 2 branch roll / 0 spark /
         2 FIRE
damage   Damage 5   (contact; x random(1,8) = 5..40)
type     hornet   (DamageType "hornet"; DamageFactor "hornet" 0 makes the
         queen and her bees immune to each other)
sound    --   NO AttackSound on the Default block. The charge is SILENT;
         "Hornet/Fly" is a looping SoundSlot7 ambience, not the attack.
impact   contact only
trigger  Missile
range    --
mirrored no
inherit  Actor
profile  --   no CHARGE mode. See UNRESOLVED.
notes    Only 70/256 (~27%) of Missile entries reach the charge: A_Jump(186,
         "MINIONS") on :1343 takes the rest. Launch speed 20 (default).
         MaxTargetRange 256, +BOSS, +NORADIUSDMG, Health 666.
         The A_CustomMissile("RS_SparkPuff1",...) lines throughout See, Dodge
         and Missile are cosmetic body sparks (Speed 1, VSpeed 4, no damage)
         AND use the malformed argument order -- see idiom 3.
```

```
ATTACK   RS_BlackLSoulOld3.MINIONS
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1349
shape    FAN
payload  RS_BlackLSoul2 x12 per pass   (LIVE MONSTERS)
arc      90   (0 for A_PainAttack, ±45 for A_DualPainAttack)
timing   3,3 / 3,3 / 3,3 / 3,3   (four two-frame lines, 24 tics total)
damage   --
type     --
sound    --
impact   12 live bees per pass; A_Jump(102,"MINIONS") on :1356 gives a
         102/256 (~40%) chance to run the whole thing again
trigger  Missile
range    --
mirrored no
inherit  Actor
profile  MakeSummon("RS_BlackLSoul2", count: 12, cap: 24, tierOffset: -2,
         profName: "QueenBroodOld")
notes    Release pattern per pass, in order: A_PainAttack x2 (2 bees at
         facing), A_DualPainAttack x2 (4 bees at ±45), A_PainAttack x2
         (2 bees), A_DualPainAttack x2 (4 bees) = 12. Each LINE has two frame
         letters, so each line is two calls.
```

## RS_BlackLSoul3 -- "Queen Bee", the live one, tier 10 (`RS_LostSoul.zs:1382`)

```
ATTACK   RS_BlackLSoul3.Spawn
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1430
shape    UNCLASSIFIED
payload  RS_BlackLSoul2 x6   (LIVE MONSTERS)
         + RS_BLSoulAss x1 (cosmetic abdomen glow, SXF_SETMASTER)
arc      --   (positional: random(-16,16) x/y, random(-6,10) z)
timing   one tic (two lines of 3 zero-tic frame letters)
damage   --
type     --
sound    --
impact   6 live bees escorting; the glow warps to the queen's abdomen forever
trigger  Spawn
range    --
mirrored no
inherit  Actor
profile  MakeSummon("RS_BlackLSoul2", count: 6, cap: 6, tierOffset: -2,
         profName: "QueenEscort")
notes    RS_BLSoulAss (RS_LostSoulFX.zs:269) is +NOINTERACTION +NOCLIP, Speed
         1, and A_Warps to AAPTR_MASTER (-2,0,-12) pulsing scale 0.33<->0.38.
         Not an attack.
         NOTE: RS_BlackLSoul3 HAS NO CHARGE. Its Missile state (:1459) is a
         pure selector -- A_Jump(255,"MINIONS","Stinger","HurtSoul") -- and
         the 1/256 fall-through fires only a cosmetic RS_SparkPuff1. The
         orphan charges; the live queen does not. Diffed against CH: correct.
```

```
ATTACK   RS_BlackLSoul3.HurtSoul
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1470
shape    SINGLE
payload  RS_BSoulHellNo x1
arc      --
timing   12 face / 8 FIRE / 0 chain roll
damage   DamageFunction (random(1,2))
type     Melee
sound    payload SeeSound "baron/attack"; the queen plays nothing
impact   THE SEEKER IS THE ATTACK. Spawn loop: A_SeekerMissile(10,10,
         SMF_PRECISE) + six RS_BSoulHellNo2 cosmetic shards + three black
         particles + a looping "Hornet/Fly" SoundSlot7, every 4 tics.
         Death (normal): six more shards, "Hornet/Splat", stop.
         XDeath (OVERKILL ONLY): six shards, `TNT1 A 3 A_Explode(random(10,30),
         32,0)`, then NINE RS_BSoulHellNo3.
         RS_BSoulHellNo3: Speed 20, random(1,2), +SEEKERMISSILE +THRUACTORS,
         A_SeekerMissile(32,255,SMF_PRECISE|SMF_LOOK,255) -- it acquires its
         OWN targets -- and `A_Explode(1,22)` every loop as a graze DoT, with
         a 12/256 chance per loop to expire.
         (RS_LostSoulFX.zs:324 / :367 / :301)
trigger  Missile
range    --
mirrored no
inherit  Actor
profile  MakeVolley("RS_BSoulHellNo", count: 1, fireSnd: "baron/attack",
         profName: "QueenSwarmSeed")
notes    A_Jump(128,"Stinger") on :1471 gives a 50% chance to chain straight
         into the stinger strafe. Spawn height 0 -- fired from the floor
         plane of the actor.
         THE XDEATH BRANCH IS THE PAYOFF: overkill the seeker and it splits
         into a nine-strong self-targeting sub-swarm. A normal kill does not.
```

```
ATTACK   RS_BlackLSoul3.Stinger
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1474
shape    BURST
payload  RS_BSoulStinger1 x4 + RS_BSoulStinger2 x3  = 7 per full pass
arc      --   (every call is A_CustomMissile(cls,0,0,0) -- dead centre)
timing   HEALTHY (>=800hp), Stinger/ThatWay:
           2 FIRE / 0 mirror roll / 0 health check /
           5 THRUST(20) / 5 FIRE / 5 / 5 FIRE / 5 / 5 FIRE / 5 A_Stop /
           0 mirror roll /
           5 THRUST(20) / 5 FIRE / 5 / 5 FIRE / 5 / 5 FIRE / 5 A_Stop
         ENRAGED (<800hp), FasterBee/FasterBee2:
           3 THRUST(25) / 2 FIRE / 2 / 2 FIRE / 2 / 2 FIRE / 1 A_Stop /
           0 roll / 3 THRUST(25) / 2 FIRE / 2 / 2 FIRE / 2 / 2 FIRE / 5 A_Stop
damage   DamageFunction (random(5,25)) + PoisonDamage 6 (PoisonDamageType
         "Poison")  -- identical on both stinger classes
type     Melee   (+ Poison over time)
sound    payload SeeSound "Jam/Jamd" (+SPAWNSOUNDSOURCE, so it plays from the
         projectile), AttackSound "moloch/nailhitbleed"
impact   `6PUF A 0 A_PlaySound("moloch/nailhit")` then
         `6PUF ABCDEF 1 Bright A_Explode(random(2,5),64)` -- SIX blasts --
         then `FBL1 EFG 1 Bright A_Explode(random(2,8),64)` -- THREE more --
         then a RS_Trail12 puff. DeathSound "gas/gas1". Nine explosions per
         stinger. Decal "BulletChip", +BLOODSPLATTER, +THRUSPECIES,
         Species "Hornet".  (RS_LostSoulFX.zs:399 / :437)
trigger  Missile
range    --
mirrored yes   (ThatWay is Stinger with the two strafe legs swapped:
         +192 then +64 instead of +64 then +192. FasterBee/FasterBee2 are the
         same swap on the enraged timing. Reached by A_Jump(128,"ThatWay") at
         :1475 and A_Jump(32,...) mid-pass.)
inherit  Actor
profile  MakeBurst("RS_BSoulStinger1", count: 7, delayTics: 10,
         fireSnd: "Jam/Jamd", profName: "QueenStinger")
         -- but the alternation Stinger1/Stinger2 needs an RS_AttackSlot with
         [Stinger1, Stinger2, Stinger1, ...], which is exactly what
         AttackSlot's cursor is for. The strafe has no profile expression.
notes    THE TWO STINGERS ARE NOT THE SAME PROJECTILE.
         RS_BSoulStinger1: Speed 35 -- a dart, straight to you.
         RS_BSoulStinger2: Speed 1 -- IT HANGS IN THE AIR. Spawn is
           `BLAD A random(12,32) Bright A_Jump(128,"Delay")`, and Delay is
           `BLAD A 12 Bright A_Jump(64,"Delay")` -- so it floats 12..32 tics,
           possibly much longer, THEN `A_ScaleVelocity(random(12,83))` rockets
           it off. It is a mine. Everything else about it is identical.
         The strafe: `ThrustThing(int(angle*256/360+64),20,0,0)` -- CH's
         256-unit angle arithmetic; +64 is 90 degrees (left), +192 is 270
         (right). Thrust magnitude 20 healthy, 25 enraged.
         Health gate: A_JumpIfHealthLower(800,"FasterBee") on :1476 and
         A_JumpIfHealthLower(800,"FasterBee2") on :1528. Health 1500, so the
         enrage is the bottom half of the fight -- same 7 stingers in roughly
         half the time.
```

```
ATTACK   RS_BlackLSoul3.MINIONS
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1552
shape    FAN
payload  RS_BlackLSoul2 x12   (LIVE MONSTERS)
         + RS_RedRevLoad x2 (cosmetic charge-up flares)
arc      90   (0 for A_PainAttack, ±45 for A_DualPainAttack)
timing   8,8 A_Stop / 6 FLARE / 4x8 / 6 FLARE / 4x8 / then 3,3 / 3,3 / 3,3 /
         3,3 releases  -- 92 tics of stationary wind-up before a single bee
damage   --
type     --
sound    RS_RedRevLoad SeeSound "Weapons/BFGF"
impact   12 live bees
trigger  Missile
range    256..   (A_JumpIfCloser(256,"Dodge") on :1546 ABORTS the whole thing
         if you are close -- she will not stand still next to you)
mirrored no
inherit  Actor
profile  MakeSummon("RS_BlackLSoul2", count: 12, cap: 24, tierOffset: -2,
         fireSnd: "Weapons/BFGF", profName: "QueenBrood")
notes    Same 12-bee pattern as the orphan, but with a 92-tic telegraph
         (A_Stop, two RS_RedRevLoad flares, 64 tics of idle wing frames) and
         NO repeat roll -- one pass only, then Goto See. The orphan's version
         has no telegraph and a 40% repeat. This is the balanced cut.
```

## RS_BlackLSoul2 -- "Bee", minion (`RS_LostSoul.zs:1583`)

Spawned by the two queens and the gray hive. `-COUNTKILL`, no tier token.

```
ATTACK   RS_BlackLSoul2.Missile
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1642
shape    CHARGE
payload  RS_BlackLSoul2 (the monster itself)  x1
arc      --
timing   0 sound / 2 face / 2 FIRE @30 / then 10,10 x12 of alternating
         A_JumpIfCloser(16,"Melee") and A_CheckFloor("Death")
damage   **0** -- THE DEFAULT BLOCK HAS NO `Damage` PROPERTY.
         Actor's default Damage is 0, so the skull-fly contact resolves to
         0 x random(1,8) = 0. Verified absent in OUR tree AND in CH
         (lostsouls.txt:1771-1869, diffed: identical). See UNRESOLVED.
type     --
sound    --   NO AttackSound. The ram is silent.
impact   contact does nothing; the ram exists to close distance
trigger  Missile
range    --
mirrored no
inherit  Actor
profile  --   no CHARGE mode. See UNRESOLVED.
notes    Launch speed 30 -- fast. A_CheckFloor("Death") x6 means a bee that
         rams into the floor DIES; that is how the swarm thins itself.
         A_JumpIfCloser(16,"Melee") x6 is the real payoff: the ram is a
         delivery vehicle for the bite. Body Speed 18, Health 18, Scale 0.5,
         MaxTargetRange 256, DamageFactor "fire" 0.2 / "plasma" 0.4.
```

```
ATTACK   RS_BlackLSoul2.Melee
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1658
shape    MELEE
payload  --
arc      --
timing   5 face / 3 bite   (one frame letter = ONE call)
damage   A_CustomMeleeAttack(random(1,2))
type     --
sound    "GENTLES1"
impact   --
trigger  Melee
range    ..16   (A_JumpIfCloser(16,"Melee") from the ram)
mirrored no
inherit  Actor
profile  MakeMelee(range: 16, fireSnd: "GENTLES1", profName: "BeeSting")
notes    1..2 damage. The bee is a nuisance individually and a wall in
         numbers -- 46 of them (orphan queen) is 46..92 per volley of bites.
```

## RS_WhiteLSoul2 -- "The shifter", tier 11 (`RS_LostSoul.zs:1689`)

`Missile` (:1763) is a pure selector: a transform animation shedding cosmetic
`RS_WSSmore` wisps, ending in `A_Jump(256,"revform","archform","baronform")`.
No row -- it picks between the three below at 1/3 each.

```
ATTACK   RS_WhiteLSoul2.revform
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1784
shape    MULTI
payload  RevenantTracer x2, RS_AcidBlast1 x2, RS_zap7 x2, RS_Purp1 x2,
         RS_Homer1 x2, RS_RevEgg x1   = 11
arc      per pair, mirrored shoulder shots at spawnofs_xy +7 / -7, height 50:
           RevenantTracer  ±5   (arc 10)
           RS_AcidBlast1   ±12  (arc 24)
           RS_zap7         ±1   (arc 2)
           RS_Purp1        ±9   (arc 18)
           RS_Homer1       ±15  (arc 30)
timing   5 sight / 4 / 2,2,2,2 face / 6 face /
         0,0 TRACERS / 4 face / 7,0 ACID / 4 face / 7,0 ZAP / 4 face /
         7,0 PURP / 4 face / 7,4 HOMER / 4 EGG
damage   RevenantTracer  Damage 10 (vanilla; x random(1,8))
         RS_AcidBlast1   random(5,55)  Plasma
         RS_zap7         random(20,50) Plasma
         RS_Purp1        random(10,30) Plasma
         RS_Homer1       random(8,52)  Fire
         RS_RevEgg       -- (a monster)
type     Plasma / Plasma / Plasma / Fire  (mixed -- see per-payload above)
sound    A_PlaySound("skeleton/sight") on :1780. Each payload carries its own
         SeeSound: baron/attack, weapons/plasmaf, baron/attack, fire/fire1.
impact   RevenantTracer  vanilla puff, DeathSound "skeleton/tracex"
         RS_AcidBlast1   BAL7 CDE 6 Bright, NO explode, DeathSound
                         "baron/shotx", Decal BaronScorch; A_SeekerMissile
                         (11,11,SMF_PRECISE) + RS_Trail11 wake
         RS_zap7         PLSE CDE 6 Bright, DeathSound "weapons/plasmax";
                         A_ScaleVelocity(1.15) EVERY FRAME -- it accelerates
         RS_Purp1        Spawn does `BAL1 AA 1 Bright A_Explode(random(8,18),
                         45)` -- TWO graze blasts per 4-tic loop, in flight.
                         Death: `BAL1 CDE 6 Bright A_Explode(random(35,45),
                         64)` -- THREE blasts. Seeker (4,5), RS_Trail22 wake.
         RS_Homer1       `MISL BCD 6 Bright A_Explode(random(5,35),64)` --
                         THREE blasts. Seeker (18,18,SMF_PRECISE),
                         RS_SparkPuff1 wake, DeathSound "fire/fire5"
         RS_RevEgg       pulses 8 times over ~104 tics then A_PainAttack
                         ("RS_CommonRevenant",0,PAF_NOSKULLATTACK) and dies
trigger  Missile
range    --
mirrored yes   (each pair is literally +offs/+angle then -offs/-angle)
inherit  Actor.  RS_AcidBlast1/zap7/Purp1/Homer1 are CH Revenants.txt
         externals living at RS_LostSoulFX.zs:1120/:1152/:1180/:1239.
         RS_RevEgg at RS_LostSoulFX.zs:537.
profile  RS_AttackSlot with five MakeVolley entries plus a MakeSummon:
           MakeVolley("RevenantTracer", 2, arc: 10)
           MakeVolley("RS_AcidBlast1",  2, arc: 24, fireSnd: "baron/attack")
           MakeVolley("RS_zap7",        2, arc: 2,  fireSnd: "weapons/plasmaf")
           MakeVolley("RS_Purp1",       2, arc: 18, fireSnd: "baron/attack")
           MakeVolley("RS_Homer1",      2, arc: 30, fireSnd: "fire/fire1")
           MakeSummon("RS_RevEgg", count: 1, cap: 2)
         -- the AttackSlot cursor walks them in order, which is exactly the
         behaviour CH's state chain has.
notes    RS_RevEgg's hatch is runtime-guarded (`String.Format` idiom) because
         the revenant family's body classes may not be compiled; the guard
         self-activates. This is a documented translation, not a difference.
         The whole sequence is ~64 tics and is not interruptible by Pain
         (bNOPAIN is set true on entering Missile, :1764).
```

```
ATTACK   RS_WhiteLSoul2.baronform
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1811
shape    MULTI
payload  BaronBall x1 (via A_BruisAttack), RS_Spspit2 x2, RS_SmashBalls2 x2,
         RS_BaronWave x7, RS_Spear11 x1, RS_HKEgg x1   = 14
arc      RS_Spspit2      random(-1,1) then random(-8,8)
         RS_SmashBalls2  random(-8,8) then random(-1,1)
         RS_BaronWave    18  -- FIXED FAN at +1,+3,-3,+6,-6,+9,-9
         RS_Spear11      random(-1,1)
         all at spawnheight 32, spawnofs_xy 5
timing   8 sight / 8,8,8 face / 7 BRUIS / 5,5 face / 5 (ACS strip) /
         5,5 face / 5 SPSPIT / 5,5 face / 3 SPSPIT / 3,3 face / 3 SMASH /
         6,6 face / 6 SMASH / 5,5 face /
         0,0,0,0,0,0,5 BARONWAVE x7 (six 0-tic, one 5-tic -- all on one tic) /
         5,5 face / 5 SPEAR / 5 / 8 EGG
damage   BaronBall       Damage 8 (vanilla; x random(1,8))
         RS_Spspit2      random(10,72) Plasma
         RS_SmashBalls2  random(5,35)  Plasma
         RS_BaronWave    random(5,17)  Fire
         RS_Spear11      random(10,85) Plasma
         RS_HKEgg        -- (a monster)
type     mixed -- Plasma / Fire, see above
sound    A_PlaySound("baron/sight") on :1809. Payload SeeSounds:
         baron/attack, caco/attack, caco/attack, baron/attack.
impact   RS_Spspit2      BAL7 CDE 3 Bright, no explode, DeathSound
                         "imp/shotx"; seeker (2,2), RS_Trail12 wake
         RS_SmashBalls2  Gravity 0.1, Hexen bounce x7 factor 2. EVERY FLOOR
                         BOUNCE fires FIFTEEN RS_STracerBlue in a full ring
                         (random(1,120)/(121,240)/(241,359), 5 each), then
                         64/256 to become a seeker and 12/256 to detonate.
                         Death `BAL2 DE 6 Bright A_Explode(random(5,20),128)`
                         -- two blasts. RS_STracerBlue: Speed 2, random(5,17)
                         Fire, +FLOORHUGGER, A_CStaffMissileSlither, sheds
                         RS_STracerPuffBlue, 24/256 per tic to die, Death
                         `FTRA L 4 Bright A_Explode(random(5,15),32)`
         RS_BaronWave    Hexen bounce x2, `BAL2 E 6 Bright A_Explode
                         (random(3,15),88)`
         RS_Spear11      Speed 42 (FastSpeed 68) -- the fastest thing the
                         shifter throws. `PLSE CDE 3 Bright A_SpawnItemEx
                         ("RS_Zap88",...)` x3, DeathSound "Litn/litn3".
                         RS_TrailB wake, which itself does
                         `PLSE CDE 2 Bright A_Explode(7,18)` x3
         RS_HKEgg        pulses 8 times then A_PainAttack("RS_CommonHK",0,
                         PAF_NOSKULLATTACK) and dies
trigger  Missile
range    --
mirrored no
inherit  Actor.  Barons.txt externals at RS_LostSoulFX.zs:1358 (Spspit2),
         :1387 (SmashBalls2), :1504 (BaronWave), :1542 (Spear11).
         RS_HKEgg at RS_LostSoulFX.zs:488.
profile  RS_AttackSlot:
           MakeVolley("BaronBall",      1, fireSnd: "baron/attack")
           MakeBurst ("RS_Spspit2",     2, delayTics: 10, arc: 16)
           MakeBurst ("RS_SmashBalls2", 2, delayTics: 12, arc: 16)
           MakeVolley("RS_BaronWave",   7, arc: 18, fireSnd: "caco/attack")
           MakeVolley("RS_Spear11",     1, arc: 2,  fireSnd: "baron/attack")
           MakeSummon("RS_HKEgg", count: 1, cap: 2)
notes    THE 7-SHOT BARONWAVE FAN (:1823-:1829) IS THE LIFTABLE PIECE. Six
         zero-tic calls plus one 5-tic call = all seven leave on the same tic
         at hand-written angles +1,+3,-3,+6,-6,+9,-9. That is a genuine FAN,
         arc 18, asymmetric by one degree (the +1 centre shot).
         `BOSS R 5;` at :1813 is CH's `ACS_NamedExecuteWithResult
         ("BaronMissile",1)` -- a lead-predicted vanilla BaronBall shot from
         CHACS.acs:54. THE ACS ENGINE IS NOT PORTED, so our shifter fires
         ONE FEWER PROJECTILE than CH's here. Flagged in UNRESOLVED.
         A_BruisAttack is vanilla: melee (10 x random(1,8)) if in melee range,
         otherwise a BaronBall.
```

```
ATTACK   RS_WhiteLSoul2.archform
file     zscript/monsters/lostsoul/RS_LostSoul.zs:1848
shape    MULTI
payload  RS_BigBolt2 x1, RS_ArcRing1 x2 (A_VileTarget), RS_ArcRing2 x1
         (A_VileTarget) + x2 (aimed), RS_ArchSpawnerOrb x3   = 9
         + RS_BlueGash x1 (cosmetic)
arc      RS_BigBolt2   0        (spawnheight 32)
         RS_ArcRing1   n/a      (A_VileTarget places it AT THE TARGET'S FEET)
         RS_ArcRing2   n/a for the VileTarget copy; random(-3,3) for the two
                       aimed copies (spawnheight 12)
timing   8 sight / 5 face / 4 gash / 7,7,7,7,7 face / 1 BIGBOLT / 0 VileStart /
         7 face / 6 ARCRING1 / 5,5,5,5,5 face / 4 ARCRING1 / 0 sight check /
         7 ARCRING2 / 4 ARCRING2 / 2 ARCRING2 / 12 / 3,2,1 ORBS
damage   RS_BigBolt2   random(25,95) Plasma  -- the family's biggest single
                       direct roll
         RS_ArcRing1   NO DAMAGE AT ALL. +NOINTERACTION.
         RS_ArcRing2   no Damage property (contact 0); the damage is its
                       per-loop `A_Explode(random(8,18),32)`
         orbs          -- (monsters)
type     Plasma / -- / --
sound    A_PlaySound("vile/sight") :1844, A_VileStart :1849 (plays
         "vile/start"). RS_ArcRing1/2 SeeSound "Fire/fire3".
         RS_BigBolt2 has NO SeeSound -- silent launch.
impact   RS_BigBolt2   Seeker (7,10), sheds RS_BlueGash. Death: BFE1 AB 8,
                       `BFE1 C 8 Bright A_Explode(random(25,75),128)`,
                       BFE1 DEF 8. DeathSound "weapons/bfgx".
         RS_ArcRing1   72 tics of rolling ring (RNGG ABCD x6), then Death
                       `A_RadiusGive("RS_GrowRaisin",100,RGF_MONSTERS|
                       RGF_CORPSES,3)` -- THIS IS A BUFF RING FOR THE PACK,
                       not a weapon. It reaches corpses too.
         RS_ArcRing2   Mass 999999, Gravity 10, bounces floors AND walls 999
                       times. Every Fly loop: `A_Explode(random(8,18),32)`,
                       TWO RS_FireHKBall1 at random(0,360) angle and
                       random(-20,20) pitch (a genuine RING), and one
                       RS_ArchRingHelp. 6/256 per loop to stop.
                       RS_FireHKBall1: random(10,40) Fire, Death
                       `BRB2 CDEFGHI 3 Bright A_Explode(random(2,6),32)` --
                       SEVEN blasts.
         RS_ArchSpawnerOrb  a live 13hp flier; see its own row
trigger  Missile
range    --
mirrored no
inherit  Actor.  Archviles.txt externals at RS_LostSoulFX.zs:1693 (BigBolt2),
         :1724 (ArcRing1), :1753 (ArcRing2), :1810 (ArchRingHelp),
         :1854 (ArchSpawnerOrb). RS_FireHKBall1 at :2183 (Hellknights.txt).
profile  RS_AttackSlot:
           MakeVolley("RS_BigBolt2", 1, profName: "ShifterBolt")
           MakeVolley("RS_ArcRing2", 2, arc: 6, fireSnd: "Fire/fire3")
           MakeSummon("RS_ArchSpawnerOrb", count: 3, cap: 3,
                      fireSnd: "vile/active")
         -- A_VileTarget (place an actor AT THE TARGET) has NO factory. Three
            of the nine payloads here are placed that way. See UNRESOLVED.
notes    A_VileTarget is NOT A_VileAttack: it only spawns the named actor at
         the target's feet. There is no line-of-sight burn anywhere in this
         family, so the shape word VILE is never used in this file.
         `VILE O 0 A_CheckSight("See")` at :1854 bails out of the sequence if
         the target broke LOS. The EX soul's equivalent state fires
         RS_ReAComet there instead -- confirmed against CH, they genuinely
         differ.
         The three RS_ArchSpawnerOrb spawns (:1859-:1861) pass CH's flag word
         in the xvel argument slot; kept verbatim, as CH wrote it.
```

`Death` (:1871-:1895) throws 14 cosmetic `RS_WSSmore` wisps across the three
form-death animations and does **no damage**. Not a row.

## RS_WhiteLSoulEX -- "The vengeful soul", tier 11 EX (`RS_LostSoul.zs:1903`)

12500hp. `Missile` (:2006) -> `A_Jump(128,"A1","A2","A3")` -> `Miss2` (:2013)
-> `A_Jump(255,"SoulShot","Beam","Transformers")`. `Transformers` (:2016) and
`RollOut` (:2134) are pure selectors gated on `A_JumpIfHealthLower(6000)`:
above 6000hp you get HK / REV / CACO, below it you get Baron / Vile / Mancu.
Neither selector is a row.

```
ATTACK   RS_WhiteLSoulEX.A1
file     zscript/monsters/lostsoul/RS_LostSoul.zs:2296
shape    UNCLASSIFIED
payload  --   (Inventory token: RS_WhiteSoulAdsOff2)
arc      --
timing   one tic (two 0-tic frame letters)
damage   --
type     --
sound    --
impact   A_RadiusGive("RS_WhiteSoulAdsOff2",700,RGF_MONSTERS) hands the token
         to every monster within 700. Its ONLY reader is the two orbiting
         skulls: RS_SkullWSoulEX1/2's Fly loop polls A_JumpIfInventory for
         AdsOff/2/3/4 and DETACHES into A2/A3/A4 (see the skull's own rows).
trigger  Missile
range    ..700
mirrored no   (A2 at :2298 and A3 at :2301 are the identical state with
         tokens 3 and 4 -- same attack, different summon table)
inherit  Actor
profile  MakeRadial(radius: 700, damage: 0, heal: 0, hitsAllies: true,
         profName: "ShifterCommand")
         -- MakeRadial cannot hand an Inventory token; RadialHeal is an int.
notes    THE COMMAND ATTACK. It does nothing on its own and is the trigger for
         everything the escort skulls do. Reached 128/256 of the time from
         Missile; the rest of the time Miss2 runs unchanged.
         Token -> summon table: AdsOff2 -> revenants (A2), AdsOff3 -> hell
         knights (A3), AdsOff4 -> cacodemons (A4). AdsOff (no number, thrown
         from Reset) sends the skulls back to normal See behaviour instead.
```

```
ATTACK   RS_WhiteLSoulEX.CACO
file     zscript/monsters/lostsoul/RS_LostSoul.zs:2032
shape    MULTI
payload  CacodemonBall x5, RS_Cacospit1 x3, RS_CacoFire2 x4, RS_CacoFire4 x4,
         RS_CacoFire3 x1, RS_SpitFireCaco x4, RS_CrackodemonBall x12,
         RS_SBombCaco x1   = 34
arc      CacodemonBall      8    (-4,-2,0,+2,+4 -- a FIXED 5-shot fan,
                                  spawnheight 50, offs 7)
         RS_Cacospit1       14   (random(-7,7), spawnheight 32)
         RS_CacoFire2       widening: random(-1,1), (-3,3), (-5,5), (-4,4)
         RS_CacoFire4       42   (+8,-8,+21,-21 -- fixed, all on one tic)
         RS_CacoFire3       2    (random(-1,1))
         RS_SpitFireCaco    180  (random(-90,90), spawnheight 35)
         RS_CrackodemonBall 32   (0,-8,+8,+16,+12,+8,+4,0,-4,-8,-12,-16;
                                  spawnheight 24, flags CMF_AIMOFFSET)
         RS_SBombCaco       0    (spawnheight 24, CMF_AIMOFFSET)
timing   5 sight / 2,2,2,2 face / 5 face / 3 /
         1,1,1,1,1 CACOBALL x5 / 3,3,3 face / 2,2,2 SPIT x3 / 3,3,3 face /
         4,4,4,4 FIRE2 x4 / 3,3,3 face / 1 / 0,0,0,0 FIRE4 x4 / 5 FIRE3 /
         3,3,3 face / 2,2,2,2 SPITFIRE x4 / 3,3,3 face /
         0,0,5 CRACKO x3 / 2,2 face / 2,2 CRACKO / 0 face / 2,2 CRACKO /
         0 face / 2,2 CRACKO / 0 face / 2,2 CRACKO / 0 face / 6 CRACKO /
         5 SBOMB / 4
damage   CacodemonBall      Damage 5 (vanilla; x random(1,8))
         RS_Cacospit1       random(10,45) Plasma
         RS_CacoFire2       random(6,35)  Plasma
         RS_CacoFire4       random(5,25)  Fire, seeker
         RS_CacoFire3       random(10,50) Fire, seeker
         RS_SpitFireCaco    random(10,65) Fire, Doom-bounce x8
         RS_CrackodemonBall random(5,55)  Plasma
         RS_SBombCaco       random(5,80)  Plasma, Scale 2
type     mixed -- Plasma / Fire
sound    A_PlaySound("caco/sight") :2028. Payload SeeSounds: baron/attack,
         holy3/holy3, caco/attack, caco/attack, CacoFlame/Attack, Crack/see,
         Spell/spellCast1.
impact   RS_CacoFire3 is the standout: Death runs THREE growing explosions --
         `A_Explode(random(8,32),64)`, `(random(12,44),82)`,
         `(random(16,64),112)` -- each on 2 frame letters, so six blasts.
         RS_SpitFireCaco: `BBOM DEFG 3 Bright A_Explode(random(5,15),64)` x4.
         RS_SBombCaco: `A_Explode(random(5,20),88)` + `(random(5,20),99)`.
         All seven RS_* classes live in RS_CacodemonFX.zs (see the table at
         the top); this file references them READ-ONLY.
trigger  Missile
range    --   (health-gated: only reachable ABOVE 6000hp)
mirrored no
inherit  Actor -- all seven payloads defined in
         zscript/monsters/cacodemon/RS_CacodemonFX.zs:782..1025
profile  RS_AttackSlot, eight entries:
           MakeVolley("CacodemonBall",      5, arc: 8)
           MakeBurst ("RS_Cacospit1",       3, delayTics: 2, arc: 14)
           MakeBurst ("RS_CacoFire2",       4, delayTics: 4, arc: 10)
           MakeVolley("RS_CacoFire4",       4, arc: 42)
           MakeVolley("RS_CacoFire3",       1, arc: 2)
           MakeBurst ("RS_SpitFireCaco",    4, delayTics: 2, arc: 180)
           MakeBurst ("RS_CrackodemonBall", 12, delayTics: 2, arc: 32)
           MakeVolley("RS_SBombCaco",       1)
notes    34 projectiles in ~140 tics. THIS FILE HARD-DEPENDS ON
         RS_CacodemonFX.zs BEING WIRED INTO zscript.txt -- if it is not, the
         classes silently do not exist and this whole attack fires nothing
         (CLAUDE.md's include-list trap).
         The 12-shot RS_CrackodemonBall run is the liftable piece: a walking
         sweep -8..+16 and back, 2 tics apart, with A_FaceTarget re-aims mixed
         in, so it tracks you while it sweeps.
```

```
ATTACK   RS_WhiteLSoulEX.REV
file     zscript/monsters/lostsoul/RS_LostSoul.zs:2084
shape    MULTI
payload  RevenantTracer x2, RS_AcidBlast1 x2, RS_zap7 x2, RS_Purp1 x2,
         RS_Homer1 x2, RS_RedDeathRev x1   = 11
arc      identical shoulder pairs to RS_WhiteLSoul2.revform:
         ±5, ±12, ±1, ±9, ±15 (offs +7/-7, height 50); RS_RedDeathRev at
         0 offs, 0 angle, height 50
timing   as revform, but the Homer pair is 7,0 (not 7,4), and the closer is
         7 REDDEATH / 4,4
damage   as revform for the five pairs, plus
         RS_RedDeathRev  random(25,85) Fire
type     mixed
sound    A_PlaySound("skeleton/sight") :2080. RS_RedDeathRev SeeSound
         "Forgotten/Attack".
impact   RS_RedDeathRev: Speed 24 (FastSpeed 38), +SEEKERMISSILE
         A_SeekerMissile(7,12), RS_CrackoBallTrail wake. Death:
         `MISL B 3 A_SetScale(1.4)`, `MISL C 3 A_SetTranslucent(0.65)`,
         `MISL D 3 Bright A_Explode(random(5,20),128)`,
         `MISL D 5 Bright A_Explode(random(5,35),128)`.
         DeathSound "spell/Impact1". (RS_LostSoulFX.zs:1270)
trigger  Missile
range    --   (only ABOVE 6000hp)
mirrored yes   (five mirrored shoulder pairs)
inherit  Actor
profile  as revform's slot, with the closer swapped:
           MakeVolley("RS_RedDeathRev", 1, fireSnd: "Forgotten/Attack")
         instead of MakeSummon("RS_RevEgg", ...)
notes    THIS IS revform WITH THE EGG SWAPPED FOR A BOMB. The shifter lays a
         revenant egg; the EX soul throws a seeking two-stage detonation
         instead. Diffed against CH -- the difference is CH's, not ours.
         The `MISL D 5` on the last line is our corrected frame; CH wrote
         `MISL E`, which does not exist in any IWAD or in CH's own sprites
         and rendered nothing. Documented at the site.
```

```
ATTACK   RS_WhiteLSoulEX.HK
file     zscript/monsters/lostsoul/RS_LostSoul.zs:2113
shape    MULTI
payload  BaronBall x1 (A_BruisAttack), RS_BaronsBlueBalls x8, RS_HKBolt2 x2,
         RS_BigHK x1, RS_THEBEEHK x1   = 13
arc      RS_BaronsBlueBalls  random(-1,1) x5, then random(-8,8) x3
         RS_HKBolt2          random(-8,8), then random(-1,1)
         RS_BigHK            +1  (fixed)
         RS_THEBEEHK         random(-1,1)
         all at spawnheight 32, spawnofs_xy 5
timing   8 sight / 8,8,8 face / 7 BRUIS / 5,5 face / 5 (ACS strip) /
         5,5 face / 1,1,1,1,1 BLUEBALLS x5 / 5,5 face / 1,1,1 BLUEBALLS x3 /
         3,3 face / 3 HKBOLT / 6,6 face / 6 HKBOLT / 5,5 face / 5 BIGHK /
         5,5 face / 5 THEBEE / 8
damage   BaronBall           Damage 8 (vanilla)
         RS_BaronsBlueBalls  random(10,45) Plasma
         RS_HKBolt2          random(10,50) Plasma
         RS_BigHK            random(10,77) Fire
         RS_THEBEEHK         random(1,3)   -- tiny direct, huge DoT
type     Plasma / Fire
sound    A_PlaySound("knight/sight") :2111. Payload SeeSounds: baron/attack,
         caco/attack, imp/attack, weapons/firmfi.
impact   RS_BaronsBlueBalls  PLSE CDE 3 Bright, NO explode, DeathSound
                             "weapons/plasmax"
         RS_HKBolt2          seeker (2,2) + A_Weave(3,1,5,0) -- it snakes.
                             `BAL2 E 6 Bright A_Explode(random(5,30),88)`
         RS_BigHK            Scale 2. Sheds SIX RS_BigHK2 per Spawn loop
                             (`BRB2 ABABAB 2`), each a stationary
                             `A_Explode(random(5,21),100,0)` mine doing
                             random(15,45) Fire. Death: THREE RS_BigHK3
                             (mobile, Speed 12, same damage,
                             `A_Explode(random(5,21),88,0)`) then
                             `BRB2 FGHI 3 Bright A_Explode(random(2,6),32)`
                             x4. DeathSound "weapons/rocklx".
                             THE THREE RS_BigHK3 CALLS USE THE MALFORMED
                             ARGUMENT ORDER (idiom 3) -- angle 1 degree,
                             random flags, random pitch.
         RS_THEBEEHK         Speed 36, seeker (32,255,SMF_PRECISE),
                             `A_Explode(random(1,2),42)` EVERY loop as a graze
                             DoT. Death spawns TEN RS_THEBEEHK2 sub-bees
                             (`CBAL CCDDEEFFGG 1`), each Speed 23,
                             random(1,2), self-targeting seeker
                             (SMF_LOOK,255), `A_Explode(1,22)` every loop.
trigger  Missile
range    --   (only ABOVE 6000hp)
mirrored no
inherit  Actor.  Hellknights.txt externals at RS_LostSoulFX.zs:2120
         (BaronsBlueBalls), :2149 (HKBolt2), :2211 (BigHK), :2243/:2269
         (BigHK2/3), :2295/:2324 (THEBEEHK/2).
profile  RS_AttackSlot:
           MakeVolley("BaronBall", 1, fireSnd: "baron/attack")
           MakeBurst ("RS_BaronsBlueBalls", 5, delayTics: 1, arc: 2)
           MakeBurst ("RS_BaronsBlueBalls", 3, delayTics: 1, arc: 16)
           MakeBurst ("RS_HKBolt2", 2, delayTics: 12, arc: 16)
           MakeVolley("RS_BigHK", 1, fireSnd: "imp/attack")
           MakeVolley("RS_THEBEEHK", 1, arc: 2, fireSnd: "weapons/firmfi")
notes    The 5-then-3 RS_BaronsBlueBalls run (`BOS2 GGGGG 1` then
         `BOS2 RRR 1`) is a genuine 1-tic-apart burst -- 5 frame letters and 3
         frame letters, so 8 shots, not 2. Easy to miscount from the line.
         Same `BOS2 R 5;` ACS strip as baronform -- one fewer projectile than
         CH here too.
```

```
ATTACK   RS_WhiteLSoulEX.Baron
file     zscript/monsters/lostsoul/RS_LostSoul.zs:2145
shape    MULTI
payload  BaronBall x1, RS_Spspit2 x2, RS_SmashBalls2 x2, RS_BaronWave x7,
         RS_Spear11 x1, RS_BaronStar x1   = 14
arc      as RS_WhiteLSoul2.baronform for the first five; RS_BaronStar at +1,
         spawnheight 32, offs 5
timing   as baronform up to the Spear, then 5,5 face / 8 BARONSTAR
damage   as baronform, plus RS_BaronStar random(5,25) Fire
type     mixed
sound    A_PlaySound("baron/sight") :2143. RS_BaronStar SeeSound "caco/attack".
impact   RS_BaronStar: Speed 28 (FastSpeed 38), Species "BaronOfHell",
         +SEEKERMISSILE A_SeekerMissile(3,3) + A_Weave(4,1,6,0), Scale 1.3.
         Death: `BBOM A 2 A_SetScale(1)`, `BBOM B 2 A_SetTranslucent(0.65)`,
         `BBOM CD 3 Bright A_Explode(random(5,25),108)` (2 blasts),
         `BBOM EFG 6 Bright A_Explode(random(5,30),108)` (3 blasts).
         DeathSound "spell/Impact1". (RS_LostSoulFX.zs:1629)
trigger  Missile
range    --   (only BELOW 6000hp -- reached via RollOut)
mirrored no
inherit  Actor
profile  as baronform's slot, with the closer swapped:
           MakeVolley("RS_BaronStar", 1, fireSnd: "caco/attack")
         instead of MakeSummon("RS_HKEgg", ...)
notes    Same swap logic as REV vs revform: the shifter lays an egg, the EX
         soul throws a weaving 5-blast star. Confirmed against CH.
         Same `BOSS R 5;` ACS strip.
```

```
ATTACK   RS_WhiteLSoulEX.Vile
file     zscript/monsters/lostsoul/RS_LostSoul.zs:2182
shape    MULTI
payload  RS_BigBolt2 x1, RS_ArcRing1 x2 (A_VileTarget), RS_ArcRing2 x1
         (A_VileTarget) + x2 (aimed), RS_ReAComet x1, RS_BVileOrb1 x10   = 17
         + RS_BlueGash x1 (cosmetic)
arc      RS_BigBolt2   0
         RS_ArcRing2   random(-3,3) on the two aimed copies (height 12)
         RS_ReAComet   0  (height 32)
         RS_BVileOrb1  38  (random(-19,19), height 32)
timing   8 sight / 5 face / 4 gash / 7x5 face / 1 BIGBOLT / 0 VileStart /
         7 face / 6 ARCRING1 / 5x5 face / 4 ARCRING1 / 0 REACOMET /
         7 ARCRING2 / 4 ARCRING2 / 2 ARCRING2 / 12 /
         3,3 ORB / 2,2,2 ORB / 1,1,1,1,1 ORB   -- 10 orbs, accelerating
damage   RS_BigBolt2   random(25,95) Plasma
         RS_ReAComet   random(15,88) Fire
         RS_BVileOrb1  random(12,45) Fire
         RS_ArcRing1   none;  RS_ArcRing2   per-loop A_Explode(random(8,18),32)
type     Plasma / Fire
sound    A_PlaySound("vile/sight") :2178, A_VileStart :2183.
         RS_ReAComet SeeSound "weapons/firmfi", BounceSound "Fire/fire4".
         RS_BVileOrb1 SeeSound "caco/attack".
impact   RS_ReAComet   Scale 3, Doom-bounce x2 (factor 1.05, wall 1.1), sheds
                       RS_ReATrail (random(5,10) Fire, five A_Explode
                       (random(3,10),88) on death).
                       ITS DEATH IS THE POINT: `CBAL C 0 { bISMONSTER = true; }`
                       then `CBAL CDEFG 3 Bright A_Chase(null,null,
                       CHF_RESURRECT)` -- THE DEAD COMET BECOMES A
                       RESURRECTOR and raises corpses for 15 tics.
                       (RS_LostSoulFX.zs:1983)
         RS_BVileOrb1  Hexen bounce x6, factor 1.2. Sheds RS_BVileOrb2
                       (cosmetic). Death `BAL2 C 6 A_SetScale(2,2)` then
                       `BAL2 DE 6 Bright A_Explode(random(12,64),64)` -- two
                       blasts. DeathSound "caco/shotx".
                       (RS_LostSoulFX.zs:2055)
         RS_BigBolt2 / RS_ArcRing1 / RS_ArcRing2  as archform above
trigger  Missile
range    --   (only BELOW 6000hp)
mirrored no
inherit  Actor
profile  RS_AttackSlot:
           MakeVolley("RS_BigBolt2",  1)
           MakeVolley("RS_ReAComet",  1, fireSnd: "weapons/firmfi")
           MakeVolley("RS_ArcRing2",  2, arc: 6, fireSnd: "Fire/fire3")
           MakeBurst ("RS_BVileOrb1", 10, delayTics: 2, arc: 38,
                      fireSnd: "caco/attack")
         -- A_VileTarget still has no factory (3 of 17 payloads).
notes    TWO DIFFERENCES FROM RS_WhiteLSoul2.archform, both CH's:
           1. `VILE O 0` fires RS_ReAComet here (:2188); the shifter runs
              A_CheckSight("See") there instead.
           2. The closer is 10 bouncing RS_BVileOrb1 on an accelerating
              2/3/5 cadence, not 3 RS_ArchSpawnerOrb summons.
         The 10-orb run is the liftable piece: `VILE QQ 3` (2 shots),
         `VILE QQQ 2` (3 shots), `VILE QQQQQ 1` (5 shots) -- count the frame
         letters, not the lines.
```

```
ATTACK   RS_WhiteLSoulEX.Mancu
file     zscript/monsters/lostsoul/RS_LostSoul.zs:2207
shape    MULTI
payload  FatShot x6 (A_FatAttack1/2/3), RS_GreenBomb1 x6, RS_Bluewave1 x6,
         RS_BlueFT x1, RS_BlueFT2 x4, RS_PurpleBomb1 x6,
         RS_RocketShotFatso x8, RS_FatsoShotYE x6, RS_Shot2Fatso x2   = 45
arc      RS_GreenBomb1       offs +13 / -13, angle random(-5,5), height 20
         RS_Bluewave1        offs +13 angle random(-5,5) / offs -13 angle
                             random(-8,8), height 20
         RS_BlueFT           0, height 12
         RS_BlueFT2          widening: 0, random(-4,4), random(-9,9),
                             random(-16,16); height 20
         RS_PurpleBomb1      offs +13 random(-5,5) / -13 random(-8,8), h 20
         RS_RocketShotFatso  offs +42 random(-3,3) height 35 / offs -39
                             random(-6,6) height 34
         RS_FatsoShotYE      offs -12 / +12, angle random(-3,3), height 36
         RS_Shot2Fatso       offs +20 / -20, angle random(-1,1), height 32
timing   8 sight / 20 A_FatRaise / 7 FAT1 / 4,4 / 7 FAT2 / 4,4 / 7 FAT3 /
         4,4 / 10,0 GREEN x2 / 5,5 / 10,0 GREEN / 5,5 / 10,0 GREEN / 5,5 /
         8,0 BLUEWAVE x2 / 5,5 / 8,0 BLUEWAVE / 5,5 / 8,0 BLUEWAVE / 5,5 /
         0 BLUEFT / 10 / 7 / 8 BLUEFT2 / 5 BLUEFT2 / 4 BLUEFT2 / 3 BLUEFT2 /
         5,5 / 11,0 PURPLE x2 / 7,7 / 11,0 PURPLE / 7,7 / 11,0 PURPLE / 5,5 /
         8,2 ROCKET x2 / 4 / 8,2 ROCKET / 4 / 8,2 ROCKET / 4 / 8,2 ROCKET /
         5,5 / 0,5 YE x2 / 5 / 0,5 YE / 5 / 0,5 YE / 5,5 / 1 /
         0,0 SHOT2 x2 / 5 / 4,4,4,4,4,4
damage   FatShot             Damage 8 (vanilla; x random(1,8))
         RS_GreenBomb1       random(20,75) Plasma
         RS_Bluewave1        random(10,69) Plasma
         RS_BlueFT           Damage 0 -- a flash, not a weapon
         RS_BlueFT2          random(10,70) Plasma
         RS_PurpleBomb1      random(10,65) Fire
         RS_RocketShotFatso  random(10,40) Fire
         RS_FatsoShotYE      random(10,40) Plasma
         RS_Shot2Fatso       Damage 8 bare (engine rolls 8 x random(1,8) = 8..64)
type     Plasma / Fire
sound    A_PlaySound("fatso/sight") :2205, A_FatRaise (plays "fatso/raiseguns").
         Payload SeeSounds: spit/spit, fatso/attack, Spell/Lightn,
         fatso/attack, caco/attack, weapons/hominglaunch, spell/spellcast1,
         fatso/attack.
impact   RS_GreenBomb1      Scale 1.6, RS_Trail12 wake, `BAL2 CDE 6 Bright
                            A_Explode(random(8,37),64)` x3
         RS_Bluewave1       A GROWING GROUND WAVE. Fly grows 0.33/0.1 ->
                            0.75/0.3 then A_ScaleVelocity(1.5); Fly2 loops
                            `DIS1 CFEDB 2 Bright A_Explode(random(7,17),72,0)`
                            -- FIVE blasts per loop, forever, plus a
                            RS_Bluewave2 wake each pass. Death: three more
                            blasts, then EIGHTEEN RS_PlasmaBallSP4 in a full
                            360 ring (3 lines x 6 frame letters,
                            random(0,120)/(120,240)/(240,359)).
         RS_BlueFT2         Speed 50, sheds RS_BlueFT3. Death is a BFE1
                            shrinking bloom, DeathSound "weapons/bfgx"
         RS_PurpleBomb1     Gravity 0.3, Hexen bounce x8.
                            Bounce.Wall fires TWELVE RS_MiniFatsoPurpleBomb in
                            a full 360 ring then detonates. Death
                            `SBS4 FGH 6 Bright A_Explode(random(5,28),88)` x3.
                            RS_MiniFatsoPurpleBomb: random(5,20) Fire,
                            bounces, sheds RS_Bounc22, Death
                            `BAL1 CD 3 A_Explode(random(2,10),42)` x2 + nine
                            more RS_Bounc22 + one more blast
         RS_RocketShotFatso RS_HomingRocketTrailFatso wake. Death
                            `MISL B 4 Bright A_Explode(random(5,35),88)`.
                            NOTE: named "homing" but it has NO +SEEKERMISSILE
                            -- it flies straight. CH's name, CH's behaviour.
         RS_FatsoShotYE     seeker (8,12,SMF_PRECISE). Death runs
                            A_Explode(random(3,15),115) on FIVE frames
         RS_Shot2Fatso      Death `MISL BC 4 Bright A_Explode(random(10,40),
                            128)` x2, then A_SetScale(2), then a long tail of
                            RS_SparkPuff1 bursts and SEVEN-plus RS_Firespe2
                            lingering flames thrown at random(1,359)
trigger  Missile
range    --   (only BELOW 6000hp)
mirrored yes   (nearly every payload is a mirrored +offs / -offs pair)
inherit  Actor.  Fatsos.txt externals at RS_LostSoulFX.zs:2360 (GreenBomb1),
         :2390/:2421/:2449 (BlueFT/3/2), :2484/:2529 (Bluewave1/2),
         :2553/:2602 (PurpleBomb1/Mini), :2639 (FatsoShotYE),
         :2677/:2705 (RocketShotFatso/Trail), :2729 (Shot2Fatso).
profile  RS_AttackSlot, nine entries -- this is the largest single attack in
         the family:
           MakeVolley("FatShot",            2, arc: 11)    x3 (Fat1/2/3)
           MakeBurst ("RS_GreenBomb1",      6, delayTics: 10, arc: 10)
           MakeBurst ("RS_Bluewave1",       6, delayTics: 8,  arc: 16)
           MakeVolley("RS_BlueFT",          1)
           MakeBurst ("RS_BlueFT2",         4, delayTics: 5,  arc: 32)
           MakeBurst ("RS_PurpleBomb1",     6, delayTics: 11, arc: 16)
           MakeBurst ("RS_RocketShotFatso", 8, delayTics: 8,  arc: 12)
           MakeBurst ("RS_FatsoShotYE",     6, delayTics: 5,  arc: 6)
           MakeVolley("RS_Shot2Fatso",      2, arc: 2)
notes    45 projectiles across roughly 400 tics -- the longest attack chain in
         the family by a wide margin, and it only exists below 6000hp.
         A_FatAttack1/2/3 are vanilla and fire FatShot pairs at FATSPREAD
         (11.25 degrees) offsets. The exact per-call angles are engine
         internals; see UNRESOLVED.
         `HBST E 0` on :2270-:2271 is a sprite the Mancubus does not own --
         CH's own frame choice for the two RS_Shot2Fatso shots, kept verbatim.
         RS_Bluewave1's Fly2 loop is the single most damaging thing in this
         file: five A_Explode(random(7,17),72,0) per loop, looping while it
         travels.
```

```
ATTACK   RS_WhiteLSoulEX.Beam
file     zscript/monsters/lostsoul/RS_LostSoul.zs:2283
shape    SINGLE
payload  RS_SoulexBeam x1   (which is a three-stage cascade -- see impact)
arc      --
timing   4 / 8,8 face / 1 x27 (27 cosmetic wisps = a 27-tic telegraph) /
         10 FIRE / 10,10
damage   DamageFunction (random(10,30))  on all three beam stages
type     Ice
sound    SeeSound "ILLSHEAR", DeathSound "NETHERDE".
         NOTE: CH's SNDINFO defines `$random ILLSHEAR { ILLSHEA1 ILLSHEA2 }`
         but ships only ILLSHEA1.ogg -- half the roll is silent IN CH ITSELF.
         Our SNDINFO mirrors it exactly. Not a defect introduced here.
impact   THE PAYLOAD IS A CHAIN. RS_SoulexBeam (Speed 69, Scale 0.77,
         +DONTHARMCLASS +THRUSPECIES +FULLVOLDEATH, Species "whitelsoul"):
           Fly loop spawns RS_SoulexBeam2 EVERY TIC at forward velocity
           cos(pitch)*12 / *16 / *8 / *20, with SXF_TRANSFERPITCH.
           Death: `PUFI EFGH 1 A_Explode(random(10,20),64,0)` -- four blasts.
         RS_SoulexBeam2 (RS_LostSoulFX.zs:649) spawns SIXTEEN RS_SoulexBeam3
           over 16 tics at velocities 16/24/12/32/24/12/16/28/16/24/12/32/
           24/12/16/28, then Death `BAL2 ABABABABA 1 A_Explode(random(2,12),
           32,0)` -- NINE blasts.
         RS_SoulexBeam3 (RS_LostSoulFX.zs:695) Fly is 2 tics, then Death
           `BAL2 ABABABABABABABABABABABABABA 1 A_Explode(random(2,12),32,0)`
           -- TWENTY-SEVEN blasts.
         One Beam cast therefore lays down a travelling column of hundreds of
         small radius-32 detonations.
trigger  Missile
range    --
mirrored no
inherit  Actor
profile  MakeVolley("RS_SoulexBeam", count: 1, fireSnd: "ILLSHEAR",
         profName: "SoulIceLance")
notes    Spawn height 32, angle 0. Species "whitelsoul" + +DONTHARMCLASS on
         all three stages means the beam cannot hurt the caster or the escort
         skulls -- important if this is worn by a player weapon, because that
         guard will not transfer.
```

```
ATTACK   RS_WhiteLSoulEX.SoulShot
file     zscript/monsters/lostsoul/RS_LostSoul.zs:2291
shape    SINGLE
payload  RS_SOULEXSoulCharge x1
arc      --
timing   4 / 8,8 face / 1 grow(1.15) / 1 grow(1.3) / 10 FIRE / 1 / 1 shrink
damage   DamageFunction (random(20,90))
type     Melee
sound    SeeSound "Spell/SpellCast1", DeathSound "Fire/Fire4"
impact   RS_SOULEXSoulCharge (RS_LostSoulFX.zs:730): Speed 21, +SEEKERMISSILE
         A_SeekerMissile(3,3), Scale 0.5, +THRUSPECIES, Species "whitelsoul".
         IN FLIGHT, every 3-tic loop it:
           * sheds TWO RS_SpiralSawAby (saw wake; Spawn is
             `SPIR EDCBA 3 Bright A_Explode(random(2,10),88)` -- FIVE blasts
             each, radius 88, DamageType Plasma)
           * fires ONE RS_GroundRedLSoul (crawling floor fire: +FLOORHUGGER
             +BOUNCEONWALLS, BounceCount 999, WallBounceFactor 1.5, Spawn is
             `RED8 ABC 3` + `RED8 FGH 3` each with A_Explode(random(2,10),128)
             -- SIX blasts, radius 128, DamageType Fire)
         Death: `SPIR A 1 Bright A_SetScale(2)` then
         `SPIR ABCDEDCBAE 5 Bright A_Explode(random(2,20),128)` -- TEN blasts
         over 50 tics at radius 128.
trigger  Missile
range    --
mirrored no
inherit  Actor
profile  MakeHeavy(proj: "RS_SOULEXSoulCharge", fireSnd: "Spell/SpellCast1",
         spawnHeight: 32, bigMuzzle: true, profName: "SoulCharge")
notes    THE FAMILY'S SINGLE BIGGEST DIRECT ROLL, random(20,90), and it seeks.
         The scale pulse (1.0 -> 1.15 -> 1.3 -> 1.15 -> 1.0) around the shot
         is the telegraph; ~24 tics total.
```

```
ATTACK   RS_WhiteLSoulEX.Reset
file     zscript/monsters/lostsoul/RS_LostSoul.zs:2313
shape    UNCLASSIFIED
payload  RS_SkullWSoulEX1 x1 + RS_SkullWSoulEX2 x1  (re-attached escorts)
         + Inventory token RS_WhiteSoulAdsOff
arc      --   (fixed offsets: +32,+32,+12 and -32,-32,+12, SXF_SETMASTER)
timing   0,0,0,0 wisps / 1,1 wisps / 0 RADIUSGIVE / 74 x A_Wander at 0 tics /
         0,0 respawn skulls / 1,1
damage   --
type     --
sound    --
impact   A_RadiusGive("RS_WhiteSoulAdsOff",700,RGF_MONSTERS) recalls any
         detached escort skull to its normal See behaviour (their Fly loop
         reads it first). Then two fresh skulls are attached.
trigger  Pain
range    ..700
mirrored no
inherit  Actor
profile  MakeSummon("RS_SkullWSoulEX1", count: 1, cap: 2,
         profName: "ShifterRecall")
         -- and MakeSummon("RS_SkullWSoulEX2", count: 1, cap: 2).
         The 74-tic-of-zero A_Wander teleport scramble has no expression.
notes    THE ESCAPE. Reached 64/256 (25%) of the time from Pain (:2308).
         `ETHS G...G 0 A_Wander` with SEVENTY-FOUR frame letters at 0 tics
         runs 74 A_Wander calls in one tic -- the boss teleport-scrambles
         across the room instantly. Not a bug: CH's text, diffed identical.
         The See state also polls `A_CheckProximity("AddOns",
         "RS_SkullWSoulEX1",512,0,CPXF_EXACT)` x4 per loop (:1982-:1997) and
         routes to AddOns (:1999) to re-attach a missing skull -- a second,
         passive path to the same summon. AddOns is not a separate row: it is
         this attack reached from See instead of Pain.
```

`Transformers` (:2016) throws 12 aimed + 33 positional `RS_WSSmore` wisps
(:2020-:2021). All cosmetic (Speed 12, no Damage property). Not a row.
`Death` (:2319-:2342) throws 14 more. Not a row.

---

# MINION MONSTERS DEFINED IN `RS_LostSoulFX.zs`

## RS_SkullWSoulEX1 / RS_SkullWSoulEX2 -- the EX soul's orbiting skulls (`RS_LostSoulFX.zs:813` / `:989`)

`RS_SkullWSoulEX2 : RS_SkullWSoulEX1` overrides **only** `Spawn` and `Fly`
(a mirrored orbit path). Every attack below is inherited unchanged.

```
ATTACK   RS_SkullWSoulEX1.Missile
file     zscript/monsters/lostsoul/RS_LostSoulFX.zs:973
shape    SINGLE
payload  RS_SoulShotWEX x1
arc      --
timing   0 (clear NOCLIP) / 10 face / 4 FIRE / 4,4
damage   DamageFunction (random(5,33))
type     Melee
sound    SeeSound "skull/melee", DeathSound "skull/melee"
impact   `SKUL ABAB 1 A_FadeOut(0.33)` -- no explosion, no puff. Speed 24,
         Scale 0.75, RenderStyle Subtract (it renders as a black hole).
         (RS_LostSoulFX.zs:1024)
trigger  Missile
range    --
mirrored no
inherit  Actor.  RS_SkullWSoulEX2 inherits this state verbatim.
profile  MakeVolley("RS_SoulShotWEX", count: 1, fireSnd: "skull/melee",
         profName: "EscortShot")
notes    Spawn height 5 -- fired from near the floor of the actor.
         CH'S MISSILE FALLS THROUGH INTO PAIN. `SKUL CD 4 Bright;` ends the
         Missile block and the next label is `Pain:`, so after firing it runs
         the pain animation and `Goto See`. That is CH's text and our file
         marks it at the site (:975). Recorded, not corrected.
         Only reachable once the skull has left orbit -- while orbiting it is
         +INVULNERABLE +NOCLIP +NOTARGET and never enters See.
```

```
ATTACK   RS_SkullWSoulEX1.A2
file     zscript/monsters/lostsoul/RS_LostSoulFX.zs:877
shape    UNCLASSIFIED
payload  a live monster from the token's family:
           A2 (:872) -> RS_CommonRevenant / RS_GreenRevenant /
                        RS_PurpleRevenant / RS_RedRevenant
           A3 (:903) -> RS_CommonHK / RS_BlueHK / RS_GreenHK / RS_YellowHK
           A4 (:934) -> RS_CommonCaco (x2 entries) / RS_BlueCaco /
                        RS_YellowCaco
         x1, at (-2,0,3), plus 34 cosmetic RS_WSSmore
arc      --
timing   0,0 (drop INVULNERABLE, set NOPAIN) / 6,6,6 A_Wander / 1 face /
         4 RAM (ThrustThing(int(angle),13,0,0)) / 32 hang / 0 drop NOCLIP /
         6 A_Stop / 10 grow(1.0) / 1 x17 wisps / 10 grow(1.25) / 1 x17 wisps /
         10 grow(1.5) / 10,10,10,10 / 0 SUMMON / 5,5,5 -- then Stop
damage   --   the ram is ThrustThing, NOT a missile: it has no damage at all
type     --
sound    --   (this whole chain is silent)
impact   one live monster of the chosen family; the skull is CONSUMED (Stop)
trigger  Missile   (indirectly: the parent's A1/A2/A3 A_RadiusGive is what
         puts the token in the skull's inventory, and the Fly loop polls for
         it four times per orbit -- :850-:853 and :861-:864)
range    --
mirrored no   (A3 and A4 are the identical state with a different summon
         table; the four-way A_Jump(64,...) inside each picks the tier)
inherit  Actor.  RS_SkullWSoulEX2 inherits A2/A3/A4 verbatim -- both skulls
         run this, so the EX soul summons TWO monsters per command.
profile  MakeSummon(<family common>, count: 1, cap: 2, tierOffset: -2,
         profName: "EscortHatch")
         -- the token-driven table switch and the ram have no expression.
notes    THE SKULL IS A DELIVERY VEHICLE THAT DIES. It drops invulnerability,
         wanders, faces you, rams forward at thrust 13, hangs 32 tics, grows
         from 1.0 to 1.5 scale over ~62 tics while shedding 34 wisps, then
         opens and is destroyed.
         Every summon target is a FOREIGN FAMILY body wrapped in the runtime
         `String.Format("RS_%s", ...)` guard, so it silently does nothing
         until that family compiles in. Revenants, HKs and cacos are all
         imported as of 2026-08-06, so all three tables are live.
         A4's first two branches BOTH name RS_CommonCaco -- that is CH's own
         table, not a transcription slip (diffed).
```

## RS_HKEgg -- the shifter's hell-knight egg (`RS_LostSoulFX.zs:488`)

```
ATTACK   RS_HKEgg.See
file     zscript/monsters/lostsoul/RS_LostSoulFX.zs:528
shape    UNCLASSIFIED
payload  RS_CommonHK x1   (LIVE MONSTER, via A_PainAttack with
         PAF_NOSKULLATTACK so it does not launch)
arc      0
timing   16 (sight) / 12 x8 alternating A_SetScale(1.5,2) and (2,1.5) --
         a 96-tic visible pulse -- / 2 HATCH, then Goto Death
damage   --
type     --
sound    A_PlaySound("Knight/sight") on :519 -- the egg announces itself
impact   one live Hell Knight; the egg then plays `BAL1 DE 3 Bright` and
         A_Die
trigger  Missile   (the egg is thrown by RS_WhiteLSoul2.baronform; it enters
         See on acquiring a target)
range    --
mirrored no
inherit  Actor
profile  MakeSummon("RS_CommonHK", count: 1, cap: 2, tierOffset: -2,
         fireSnd: "Knight/sight", profName: "HKEgg")
notes    Health 50, -COUNTKILL, +NOPAIN +NOTARGET +FLOAT +FLOATBOB
         +LOOKALLAROUND, Speed 3, Scale 2. IT IS KILLABLE DURING THE 96-TIC
         PULSE -- that is the entire counterplay, and the pulse is the tell.
         Drops RS_HealthBundle, RS_implyingclip(128,3), RS_CH_Shell(72,2),
         RS_CH_Cell(32,2) if killed.
         The hatch is runtime-guarded (`String.Format`); the HK family is
         imported, so it is live.
```

## RS_RevEgg -- the shifter's revenant egg (`RS_LostSoulFX.zs:537`)

```
ATTACK   RS_RevEgg.See
file     zscript/monsters/lostsoul/RS_LostSoulFX.zs:577
shape    UNCLASSIFIED
payload  RS_CommonRevenant x1   (LIVE MONSTER, PAF_NOSKULLATTACK)
arc      0
timing   16 (sight) / 12 x8 scale pulse / 2 HATCH, then Goto Death
damage   --
type     --
sound    A_PlaySound("skeleton/sight") on :568
impact   one live Revenant; egg plays `BAL1 DE 3 Bright` and A_Die
trigger  Missile   (thrown by RS_WhiteLSoul2.revform)
range    --
mirrored no
inherit  Actor
profile  MakeSummon("RS_CommonRevenant", count: 1, cap: 2, tierOffset: -2,
         fireSnd: "skeleton/sight", profName: "RevEgg")
notes    Identical to RS_HKEgg but for the sound, the hatch class, and a
         slightly leaner drop table (RS_implyingclip 128,2 and RS_CH_Cell 32
         instead of 32,2). Both differences are CH's.
```

## RS_ArchSpawnerOrb -- the shifter's summon orb (`RS_LostSoulFX.zs:1854`)

```
ATTACK   RS_ArchSpawnerOrb.FireIt
file     zscript/monsters/lostsoul/RS_LostSoulFX.zs:1915
shape    UNCLASSIFIED
payload  ArchvileFire x1 (vanilla)  +  RS_RandomizerArc x1
arc      --
timing   Missile loops 1/2/2/2/2/2 with A_CheckSight("FireIt") on the fourth
         frame; FireIt is 1,1 then A_Die
damage   ArchvileFire's own vanilla behaviour
type     Fire
sound    ActiveSound "vile/active"; no attack sound of its own
impact   RS_RandomizerArc (RS_LostSoulFX.zs:1925) is a RandomSpawner with a
         FIFTY-ONE ENTRY DROP TABLE spanning every imported CH family --
         imps, zombies, shotgunners, revenants, barons, chaingunners, lost
         souls, cacos, HKs, demons and the archvile, weighted 439/270/120/
         83/47 by tier (common down to yellow). One random CH monster
         appears where the orb died.
trigger  Missile
range    --
mirrored no
inherit  Actor
profile  MakeSummon("RS_RandomizerArc", count: 1, cap: 3, tierOffset: -2,
         fireSnd: "vile/active", profName: "ArcOrbSummon")
notes    Health 13, -COUNTKILL, +THRUACTORS, +LOOKALLAROUND, Speed 33,
         FloatSpeed 33, Mass 2, RenderStyle Add. Three of these are thrown by
         RS_WhiteLSoul2.archform.
         `A_SetScale(0.75,0,75)` at :1886/:1889/:1892/:1898/:1901/:1904 is
         CH's own three-argument call -- the `0,75` is a typo for `0.75`, and
         scaley 0 makes the engine fall back to scalex. Kept verbatim; it is
         cosmetic and CH ships it that way.
         The orb is the ONLY thing in this family that can put a monster from
         any other family on the map at random.
```

## RS_ArchRingHelp -- the cube's heal ring (`RS_LostSoulFX.zs:1810`)

```
ATTACK   RS_ArchRingHelp.See
file     zscript/monsters/lostsoul/RS_LostSoulFX.zs:1835
shape    UNCLASSIFIED
payload  --   (Inventory token RS_GrowRaisin)
arc      --
timing   0 GIVE / 3 A_VileChase / 0 sight check -- x4, then Goto Death
damage   --   NO DAMAGE. This is support, and mistaking it for a weapon is
         the exact error this row exists to prevent.
type     --
sound    --
impact   A_RadiusGive("RS_GrowRaisin",60,RGF_MONSTERS|RGF_CORPSES,1) four
         times over 12 tics, at radius 60, moving. A_VileChase RESURRECTS
         corpses in its path.
trigger  Spawn   (it is spawned already-hostile; Spawn falls straight to See)
range    ..60
mirrored no
inherit  Actor
profile  MakeRadial(radius: 60, damage: 0, heal: 1, hitsAllies: true,
         profName: "GrowRing")
         -- MakeRadial cannot hand an Inventory token, and has no
         resurrection axis at all.
notes    Health 9999, +INVISIBLE +NOCLIP +THRUACTORS +NOTARGET +NEVERTARGET,
         -SHOOTABLE, -COUNTKILL, Speed 4, Mass 5000. YOU CANNOT SHOOT IT.
         Four spawned by RS_BrownLSoul2.DeathHeal, one spawned per Fly loop
         by RS_ArcRing2.
         The four `A_CheckSight("Death")` lines used sprite `RMGG` in CH,
         which does not exist; corrected to `RNGG` at each site with CH's
         original preserved in a comment. Zero-tic frames, so no visual
         change either way.
```

---

# UNRESOLVED

Honest gaps. Nothing below is a guess dressed as a finding.

### 1. `C:\Users\Command\Desktop\CH` DOES NOT EXIST ON THIS MACHINE
CLAUDE.md and the task brief both name it as THE ground truth. It is absent;
`C:\Users\Command\Desktop\` holds `CHP` (a different pack) and no `CH`.
The diff in this file was run against **`E:\New folder\ART SOURCE\CH\`**, which
CLAUDE.md separately names as CH's source of truth for the whole-monster
import, and which is verifiably the same pack (all 25 cited line offsets land
exactly). **This should be confirmed with the owner** -- either the Desktop copy
moved and CLAUDE.md's path is stale, or a second copy is expected to exist.

### 2. THE ENGINE SOURCE AT `E:\DXR2` IS ALSO ABSENT
CLAUDE.md says "the engine source is the authority on flags and properties, and
it is on this machine: `E:\DXR2`". It is not there. Four claims in this file are
therefore standard-GZDoom-semantics, **not verified against the engine build
this project runs**:

* `A_SkullAttack` default speed = `SKULLSPEED` = 20, and skull-fly contact
  damage = `Damage x random(1,8)`.
* `A_CheckRange(distance, label, two_dimension)` jumps when the target is
  **further** than `distance` (the row for `RS_BrownLSoul2.Melee` depends on
  this reading; if it is inverted, the cube suicides at range instead of close).
* `A_CustomBulletAttack`'s per-bullet damage is multiplied by `random(1,3)`
  unless `CBAF_NORANDOM` (affects `RS_BlueLSoul.Psychic` only).
* `A_PainAttack` = 1 at facing, `A_DualPainAttack` = 2 at ±45,
  `A_PainDie` = 3 at +90/+180/+270 (affects five FAN rows' `arc` values).
* `A_FatAttack1/2/3` exact FatShot angles (FATSPREAD = 11.25 degrees). The
  `Mancu` row's FatShot arc is given as 11 and is the least certain number in
  this file.

### 3. THERE IS NO `CHARGE` MODE IN `RS_AttackProfile`
`zscript/systems/weapon/RS_AttackProfile.zs` ships `RS_ATK_BULLET`,
`_HEAVY`, `_MELEE`, `_HITSCAN`, `_SUMMON`, `_RADIAL`, `_SELFBUFF` and the
factories `MakeBullet / MakeHitscan / MakeHeavy / MakeMelee / MakeVolley /
MakeBurst / MakeSummon / MakeRadial / MakeSelfBuff`.

**Nothing launches the firer.** Thirteen rows in this file are `shape CHARGE`
and every one of them has `profile --`. This is the single largest gap the
lost-soul family exposes, and it is a design question for the owner, not
something to invent: a player-weapon "charge" could mean a dash, a thrown
proxy that carries the player's damage, or nothing at all.

Affected rows: `RS_BrownLSoul2.Missile`, `RS_CyanLSoul2.Missile`,
`RS_AbyssLSoul2.Rush`, `RS_FireBluLSoul2.Missile`, `RS_CommonLSoul.Missile`,
`RS_GreenLSoul.Missile`, `RS_BlueLSoul.RushIt`, `RS_PurpleLSoul.Missile`,
`RS_YellowLSoul.Missile`, `RS_RedLSoul.Charge`,
`RS_BlackLSoulOld3.Missile`, `RS_BlackLSoul2.Missile`. (12 here; the 13th
tree-wide CHARGE is outside this family.)

### 4. TWO MORE FACTORY GAPS, SMALLER BUT REAL
* **`A_VileTarget` has no expression.** It places an actor at the TARGET's
  feet, not in front of the firer. Five payload placements use it
  (`RS_WhiteLSoul2.archform` x3, `RS_WhiteLSoulEX.Vile` x3 -- one shared).
  `MakeVolley` fires forward; there is no "place at target".
* **`MakeRadial` takes flat ints and cannot hand an Inventory token.**
  `RadialDamage` / `RadialHeal` are `int`, so `A_Explode(random(10,50),128)`
  has to be flattened to fit -- and every `profile` line in this file that
  does so says so on the line. Four rows hand Inventory tokens
  (`RS_GrowRaisin`, `RS_CHBoner`, `RS_WhiteSoulAdsOff*`) which `MakeRadial`
  cannot carry at all.

### 5. THE ACS `BaronMissile` SHOT IS MISSING FROM THREE ATTACKS
`ACS_NamedExecuteWithResult("BaronMissile",1)` (CH `CHACS.acs:54`) is a
lead-predicted vanilla BaronBall shot. The ACS engine is not ported, so
`RS_WhiteLSoul2.baronform` (:1813), `RS_WhiteLSoulEX.HK` (:2115) and
`RS_WhiteLSoulEX.Baron` (:2147) each fire **one fewer projectile than CH**.
The states are inert 5-tic frames. Already flagged in the file header for the
owner; repeated here because it is an attack-count difference, and the payload
counts in those three rows are ours, not CH's.

### 6. `RS_BlackLSoul2` HAS NO `Damage` PROPERTY -- ITS CHARGE MAY DO NOTHING
The bee's `Missile` fires `A_SkullAttack(30)` but the Default block sets no
`Damage`. Actor's default is 0, so the contact resolves to 0. **Confirmed
absent in CH as well** (`lostsouls.txt:1771-1869`, diffed identical), so this
is CH's own state, not an import error. Whether the engine short-circuits a
zero-damage skull-fly hit differently (e.g. still applying thrust) could not be
checked -- see gap 2. Recorded rather than "fixed": the bee's real attack is
its `random(1,2)` melee.

### 7. CH'S MALFORMED `A_CustomMissile` ARGUMENT ORDER, 118 SITES
`A_CustomMissile("X", h, 0, CMF_AIMOFFSET, random(0,360), random(0,360))`
puts a flag constant in the **angle** slot and a random integer in the **flags
bitfield**. Faithful to CH. Mostly cosmetic actors, but it is also how
`RS_BigHK3` (random(15,45) Fire) and `RS_REDTHINGSHK` are launched, so a
fraction of those shots get `CMF_ABSOLUTEANGLE` / `CMF_ABSOLUTEPITCH` /
`CMF_AIMDIRECTION` set at random. **What this actually does in flight was not
tested in-game.** It is not a defect to fix without the owner's word -- CH
shipped it and the behaviour is what players of CH saw.

### 8. SHAPES I COULD NOT CLASSIFY WITHOUT COINING A WORD (11 rows)
The closed set has no entry for:
* **a self-detonation** (`A_Explode` on the monster, no projectile) --
  `RS_BrownLSoul2.Death`, `RS_FireBluLSoul2.Death`.
* **a support / buff beat** (`A_RadiusGive`, `A_VileChase`) --
  `RS_BrownLSoul2.DeathHeal`, `RS_ArchRingHelp.See`,
  `RS_WhiteLSoulEX.A1`, `RS_WhiteLSoulEX.Reset`.
* **a positional (non-angular) mass spawn** --
  `RS_BlackLSoulOld3.Spawn`, `RS_BlackLSoul3.Spawn`.
* **a hatch / delayed summon** -- `RS_HKEgg.See`, `RS_RevEgg.See`,
  `RS_ArchSpawnerOrb.FireIt`, `RS_SkullWSoulEX1.A2`.

All are written `shape UNCLASSIFIED` with the mechanism spelled out in `notes`,
per the spec. **If the other sixteen passes hit the same three categories, the
spec probably wants three more words** (something like BLAST / AURA / HATCH) --
that is a decision for whoever composes the seventeen files, not for me to make
unilaterally.

### 9. JUDGEMENT CALLS ON ROW COLLAPSE, STATED SO THEY CAN BE OVERRULED
* **`RS_BlackLSoul3.Stinger` is ONE row, not four.** `ThatWay`, `FasterBee`
  and `FasterBee2` are the same 7-stinger strafe mirrored and/or accelerated
  by the sub-800hp health gate. Collapsed per the spec's `OtherB` rule, with
  both cadences written into `timing`.
* **The shifter's three forms are three rows, not thirty.** `revform`,
  `baronform`, `archform` (and the EX's six) are each one uninterruptible
  scripted volley. Each is `shape MULTI` with the complete payload / angle /
  timing sequence written out, so any single pair inside one can still be
  lifted without reopening the file.
* **Pure selector states got no row**, per the spec: `RS_BlueLSoul.Decision`,
  `RS_BlackLSoul3.Missile`, `RS_WhiteLSoul2.Missile`,
  `RS_WhiteLSoulEX.Missile`, `.Miss2`, `.Transformers`, `.RollOut`.
* **Cosmetic-only beats got no row**: every `RS_WSSmore`, `RS_SparkPuff1`,
  `RS_RedThingsLS`, `RS_BaronCyanBombTrail`, `RS_LSoulEXShade`,
  `RS_CyanSoulEye`, `RS_BLSoulAss` and `A_SpawnParticle` line, and the
  `RS_ColorTierIconCH*` tier tokens throughout.

### 10. SOUNDS WERE RECORDED AS WRITTEN, NOT RESOLVED TO LUMPS
The `sound` field reports the string the attack plays. **No sound name in this
file was chased through SNDINFO to a real lump** -- that is the whole-monster
import check (CLAUDE.md), not the attack-catalog check, and doing it badly is
worse than not doing it. The one exception is `ILLSHEAR`, which the file header
already documents as half-silent in CH itself.
