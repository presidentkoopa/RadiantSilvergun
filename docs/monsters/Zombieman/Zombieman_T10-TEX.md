# Zombieman (family 01) — APEX TIERS DEEP READ: T10, T11, T12, TEX

Deep transcription of CHP's `Common*` Zombieman actors for tiers R / K / W / KX (+WX),
written per `docs/rs_21_port_law.txt`. **Transcription, not summary.** Nothing here is
inferred from a class name; every actor listed was opened and read.

**Ground-truth root** — all `CHP/...` and `CH/...` paths below are relative to
`E:\New folder\ART SOURCE\`.

| our tier | CHP colour | CHP file | CHP `Common*` actor | CH parent | in-game name |
|---|---|---|---|---|---|
| T10 | R  (Red)      | `CHP/DECORATE/01/01_R.txt:1`  | `CommonRedZombie`       | `RedZombie` — `CH/decorate/Zombies.txt:1441`  | "Red ZombieUnman" |
| T11 | K  (Black)    | `CHP/DECORATE/01/01_K.txt:1`  | `CommonBlackZombie1`    | `BlackZombie1` — `CH/decorate/Zombies.txt:1888` | "Player 9" |
| T12 | W  (White)    | `CHP/DECORATE/01/01_W.txt:1`  | `CommonWhiteZombie1`    | `WhiteZombie1` — `CH/decorate/Zombies.txt:2282` | "UNDERTAKER" |
| TEX | KX (Black EX) | `CHP/DECORATE/01/01_KX.txt:1` | `CommonBlackZombieEX2`  | `BlackZombieEX` — `CH/decorate/Zombies.txt:1607` | "Player X" |
| TEX | WX (White EX) | `CHP/DECORATE/01/01_WX.txt`   | **DOES NOT EXIST** — see §E | — | — |

Actor counts in these files: `01_R.txt` 45 actors / 1697 lines, `01_K.txt` 15 / 1887,
`01_W.txt` 316 / 9432, `01_KX.txt` 45 / 3499, `01_WX.txt` **0 actors / 2 bytes**.
Of the 316 in `01_W.txt`, 15 are the monster (one per spawn colour) and 301 are the
bone kit replicated 15 ways — see §G.

---

## §A — T10 RED · `CommonRedZombie` · the Unmaker zombie

### A.1 Properties

CHP declares only these (`CHP/DECORATE/01/01_R.txt:3-8`):

```
Health 115
GibHealth -100
Speed 8
PainChance 100
obituary "%o was unmade by the \c[ColorR]Red Zombie\c-."
tag "\c[ColorR]Red ZombieUnman\c-"
```

Everything else is inherited from CH `RedZombie` (`CH/decorate/Zombies.txt:1441-1473`):

```
health 186   radius 20   height 56   mass 100   speed 8
Species "Zombie"           painchance 100
attacksound "zombie/unmaker"
DamageFactor "Exorcist",3.0     DamageFactor "DIMp",0     DamageFactor Melee,3
PainChance "DIMp",0
SeeSound "Zom2/see"   PainSound "Form2/hurt"
DeathSound "zom2/die" ActiveSound "Form2/active"
DropItem "CH_Cell" / "implyingclip" / "HealthBundle",128 / "ArmorBundle",64
Dropitem "CH_Berserk",128 / DropItem "CH_cell",128 / Dropitem "RLUnmakerPickup",4
Decal BloodSplat
MONSTER  +FLOORCLIP  +EXTREMEDEATH  +DONTHARMSPECIES  +Avoidmelee
tag "Red ZombieUnman"
```

CHP declares **no `Translation`** on the Common variant — it is the uncoloured base
of the 15-colour ladder. (`GreenRedZombie` at `01_R.txt:85` is the first with one.)
CHP's Common Health 115 is *below* CH's 186; this is the CHP colour-ladder floor
(Green 144 `:74`, Blue 173 `:152`, Purple 201 `:230`), not an error.

### A.2 Full state transcription — `CHP/DECORATE/01/01_R.txt:11-68`

```
Spawn:                                                                    (:11)
    ZUNM A 0 Nodelay A_SpawnitemEx("NewIconCHP6_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
Idle:                                                                     (:13)
    ZUNM AB 10 A_Look
    Loop
See:                                                                      (:16)
    ZUNM AABBCCDD 2 A_Chase
    loop
Missile:                                                                  (:19)
    ZUNM E 0  A_Jump(64,"Missile2")
    ZUNM E 15 A_FaceTarget
    ZUNM F 10 A_CustomBulletAttack(10,2,1,random(5,15),"BloodyPuff_C")
    ZUNM E 10
    goto See
Missile2:                                                                 (:25)
    ZUNM E 16 A_FaceTarget
    ZUNM E 0  A_PlaySound("zombie/unpower")
    ZUNM F 1 BRIGHT A_CustomRailgun (random(5,10),4,"FF 00 00",0,0)
    ZUNM E 0  A_PlaySound("zombie/unpower")
    ZUNM F 1 BRIGHT A_CustomRailgun (random(5,10),4,"CC 00 00",0,0)
    ZUNM E 0  A_PlaySound("zombie/unpower")
    ZUNM F 1 BRIGHT A_CustomRailgun (random(5,10),4,"99 00 00",0,0)
    ZUNM E 0  A_PlaySound("zombie/unpower")
    ZUNM F 1 BRIGHT A_CustomRailgun (random(5,10),4,"55 00 00",0,0)
    ZUNM E 0  A_PlaySound("zombie/unpower")
    ZUNM F 1 BRIGHT A_CustomRailgun (random(5,10),4,"33 00 00",0,0)
    ZUNM E 10 A_SentinelRefire
    goto Missile2+1
Pain:                                                                     (:39)
    ZUNM G 3
    ZUNM G 3 A_Pain
    goto See
Tickles:                                                                  (:43)
    TNT1 A 0 A_Spawnitemex("WhiteZombiePlan_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION)
    Goto Death+2
Death.Ice:                                                                (:46)
Death:                                                                    (:47)
    TNT1 A 0 A_GivetoChildren("GoAway",1)
    ZUNM H 5 A_JumpIfInventory("CHWhitePlan",1,"Tickles")
    ZUNM I 5 A_Scream
    ZUNM J 5 A_NoBlocking
    ZUNM KLM 5
    ZUNM N 0 A_SpawnItemEx("RandomLetterSpawner_C",0,0,0,frandom(-7500,7500)/1000,frandom(-7500,7500)/1000,0,0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,255)
    ZUNM N -1
    stop
XDeath:                                                                   (:56)
    ZUNM O 5 A_GivetoChildren("GoAway",1)
    TNT1 A 0 A_Playsound("misc/gibbed/c")
    TNT1 AAAAA 0 A_Spawnparticle("Red",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(1,13),frandom(0,360),0,0,24,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
    ZUNM P 5 A_XScream
    ZUNM Q 5 A_NoBlocking
    ZUNM RSTUV 5 A_Spawnitemex("HKRedDeath_C",random(-24,24),random(-24,24),random(8,64),0,0,0,0,SXF_NOCHECKPOSITION)
    ZUNM W 0 A_SpawnItemEx("RandomLetterSpawner_C",...,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,255)
    ZUNM W -1
Raise:                                                                    (:65)
    ZUNM KJIH 5
    ZUNM H 0 A_SpawnitemEx("NewIconCHP6_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
    goto See
```

Notes on the branch structure:

* `Missile` is a 64/256 (25 %) coin-flip into `Missile2`. 75 % of engagements are one
  weak bullet; 25 % are the beam burst.
* `goto Missile2+1` (`:38`) re-enters at the *first* `A_PlaySound`, skipping the 16-tic
  aim. So `A_SentinelRefire` (`:37`) loops the 5-shot burst until GZDoom's refire check
  breaks it back to `See` (target dead / not visible / random break).
* `Tickles` (`:43`) is not this monster's own mechanic — it is T12's. See §C.5.
* CHP adds `Death.Ice` and a full `XDeath`; CH `RedZombie` has neither
  (`CH/decorate/Zombies.txt:1531-1546` has `Death`/`XDeath` but no `Death.Ice`, no
  `A_GivetoChildren`, no letter drop, and `XDeath` opens `ZUNM O 5` with no action).

### A.3 CHP-vs-CH deltas worth knowing

| | CH `RedZombie` | CHP `CommonRedZombie` |
|---|---|---|
| bullet | `A_CustomBulletAttack(2,2,1,random(5,25),"BloodyPuff")` `:1490` | `(10,2,1,random(5,15),"BloodyPuff_C")` `:22` |
| beam | `A_CustomRailgun(random(5,20),4,…)` `:1496` | `A_CustomRailgun(random(5,10),4,…)` `:28` |
| icon | `ColorTierIconCH6` spawned in Spawn/See/Missile/Pain | `NewIconCHP6_T1_C` spawned once in `Spawn` and `Raise` |
| plan token | `CHBoner` `:1532` | `CHWhitePlan` `:49` |

CHP widened horizontal spread 2° → 10° and halved the ceilings on both rolls.

### A.4 `CommonRedZombie2` — `CHP/DECORATE/01/01_R.txt:1197-1222`

A sibling that inherits `CommonRedZombie` and overrides only `Tickles` / `Death.Ice` /
`Death` / `XDeath`, **dropping the `RandomLetterSpawner_C` lines**. Otherwise identical.
Its only consumer in the whole tree is the Red Cyberdemon's portal summon table:
`CHP/DECORATE/17/17_R.txt:3665` — `DropItem "CommonRedZombie2", 255, 80`.
Meaning: summoned Red Zombies don't drop collectible letters. Cosmetic, but the *reason*
is structural, so it is recorded rather than merged away.

---

## §B — T11 BLACK · `CommonBlackZombie1` · "Player 9"

### B.1 Properties

CHP (`CHP/DECORATE/01/01_K.txt:3-10`):

```
Health 2000        GibHealth -500      Speed 26      PainChance 16
Obituary    "%o met the \c[ColorK]missing player\c-"
HitObituary "\c[ColorK]Player9\c-: Git Gud"
Tag         "\c[ColorK]Player 9\c-"
Translation "0:0=0:0"
```

`Translation "0:0=0:0"` is a *no-op* remap of index 0 onto itself — i.e. CHP
deliberately **cancels** CH's black-silhouette translation
(`CH/decorate/Zombies.txt:1913`: `"80:95=96:111","96:111=5:8","112:127=96:111"`) because
the CHP sprite set `ZOMK` is already drawn black. CH used `PLAY` + translation.

Inherited from CH `BlackZombie1` (`CH/decorate/Zombies.txt:1890-1927`):

```
Game Doom   Health 2500   Radius 16   Height 56   Mass 100   Speed 26   PainChance 16
DamageFactor "Heroic",3.0    DamageFactor "DIMp",0     PainChance "DIMp",0
PainChance "PLWater",8   PainChance "ice",10   PainChance "Fire",8   PainChance "Melee",42
Monster  +BOSS  +QUICKTORETALIATE  +FLOORCLIP  +LOOKALLAROUND
+Missilemore  +dontmorph  -NORADIUSDMG  +NOFEAR
DeathSound "*death"   PainSound "*pain50"      (NO SeeSound, NO ActiveSound)
DropItem "CH_SoulSphere" / "CH_PlasmaRifle" / "CH_Chaingun" / "CH_SuperShotgun"
Dropitem "RareArmorPool",64 / "RLFragShotgunPickup",72
DropItem "BackPack" / "BackPackBundle" / Dropitem "RLUniqueWeaponSpawner",12
tag "Player 9"
```

Note `PainChance "Melee",42` — Player 9 flinches badly to melee (TEX drops this to 12).

### B.2 Full state transcription — `CHP/DECORATE/01/01_K.txt:13-115`

```
Spawn:                                                                    (:13)
    ZOMK A 0 Nodelay A_SpawnitemEx("NewIconCHP10_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
    Goto Scripted
Scripted:                                                                 (:16)
    ZOMK A 0 ACS_NamedExecuteAlways("AnnounceBlackZombie_C")
    Goto Idle
Idle:                                                                     (:19)
    ZOMK A 4 A_Look
    Loop
See:                                                                      (:22)
    ZOMK ABCD 4 A_Chase
    ZOMK A 0 A_Jump(128,"See2")
    Loop
See2:                                                                     (:26)
    ZOMK ABCD 4 A_FastChase
    ZOMK A 0 A_Jump(128,"See")
    Loop
Melee:                                                                    (:30)
    ZOMK E 4 A_FaceTarget
    ZOMK E 4 a_custommeleeattack(random(20,80),"*fist","none")
    Goto Shotttgun
Missile:                                                                  (:34)
    ZOMK E 0 a_Jumpifcloser(300,"shotttgun")
    ZOMK E 0 a_JumpIfCloser(840,"PlasmaSpammer")
    ZOMK E 0 A_Jump(256,"Rawkets")
    GoTo See                                       <-- unreachable, A_Jump(256) always taken
Shotttgun:                                                                (:39)
    ZOMK E 3 A_FaceTarget
    ZOMK F 0 A_JumpIfInventory("ShotgunWhere",1,"Jammed")
    ZOMK F 0 A_PlaySound("weapons/sshotf")
    ZOMK F 13 Bright A_CustomBulletAttack(22.5,5,8,6,"BulletPuff_C",0)
    ZOMK F 0 A_GiveInventory("ShotgunWhere",1)
    Goto See
Jammed:                                                                   (:46)
    ZOMK E 8 Bright
    ZOMK A 2 A_Playsound("weapons/sshotl")
    ZOMK A 8 A_TakeInventory("ShotgunWhere",1)
    ZOMK E 2 A_SpawnItemEx("Shell",8,4,32,3,3,1,angle+5)
    ZOMK E 0
    Goto Missile
PlasmaSpammer:                                                            (:53)
    ZOMK E 2 A_FaceTarget
    ZOMK E 0 A_FaceTarget
    ZOMK F 3 Bright A_custommissile("PlasmaBallSP3_C",32,0,random(-5,5))
    ZOMK E 1 A_FaceTarget
    ZOMK F 3 Bright A_custommissile("PlasmaBallSP3_C",32,0,random(-15,15))
    ZOMK E 1 A_FaceTarget
    ZOMK F 3 Bright A_custommissile("PlasmaBallSP3_C",32,0,random(-25,25))
    ZOMK E 1
    ZOMK F 3 Bright A_custommissile("PlasmaBallSP3_C",32,0,random(-35,35))
    ZOMK A 0 A_MonsterRefire(128,"CellEject")
    Goto Missile
CellEject:                                                                (:65)
    ZOMK A 8
    ZOMK GG 3 A_SpawnItemEx("Cell",8,4,32,3,3,1,angle+5)
    ZOMK A 3
    Goto See
Rawkets:                                                                  (:70)
    ZOMK E 2
    ZOMK F 2 Bright A_custombulletattack(5.6,0,1,5,"BulletPuff_C")
    ZOMK E 2 A_Jump(32,"ActualRawk")
    ZOMK A 0 A_CPosRefire
    Goto Missile
    ZOMK A 0                                       <-- DEAD, no label reaches it
    Goto See
ActualRawk:                                                               (:78)
    ZOMK E 2
    ZOMK F 2 Bright A_Custommissile("Rocket_C",32,0,random(-1,1))
    ZOMK E 2
    Goto Missile
Pain:                                                                     (:83)
    ZOMK G 4
    ZOMK G 4 A_Pain
    Goto See
Death.Ice:                                                                (:87)
Death:                                                                    (:88)
    ZOMK H 10 A_GivetoChildren("GoAway",1)
    ZOMK I 10 A_Scream
    ZOMK J 10 A_NoBlocking
    ZOMK I 10 A_PlaySound("*death")
    ZOMK J 10
    ZOMK I 10 A_PlaySound("*death")
    ZOMK J 10
    ZOMK I 10 A_PlaySound("*death")
    ZOMK J 10
    ZOMK KLM 10
    ZOMK M 0 A_SpawnItemEx("RandomLetterSpawner_C",0,0,0,frandom(-7500,7500)/1000,frandom(-7500,7500)/1000,0,0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,244)
    ZOMK M -1
    stop
XDeath:                                                                   (:102)
    ZOMK H 5  A_GivetoChildren("GoAway",1)
    ZOMK H 20 A_PlaySound("*xdeath",0,255,0,0)
    TNT1 AAA 0 A_SpawnItemEx("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
    ZOMK O 5 A_PlaySound("misc/gibbed/c")
    ZOMK P 5 A_XScream
    TNT1 AAA 0 A_SpawnItemEx("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
    ZOMK Q 5 A_NoBlocking
    ZOMK RSTUV 5
    TNT1 AAA 0 A_Spawnparticle("Red",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(1,13),frandom(0,360),0,0,24,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
    ZOMK M 0 A_SpawnItemEx("RandomLetterSpawner_C",...,244)
    ZOMK W -1
    Stop
```

### B.3 What Player 9 does NOT have (and TEX does)

Player 9 is the *stripped* marine. Comparing `01_K.txt` with `01_KX.txt`:

* **no `Taunt` state, and no single `A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)`.** The
  gloat is TEX-only.
* **no `RBarrage` / `AltBar` / `BFGBoi`.** `Jammed` (`:46-52`) just reloads and returns
  to `Missile`; TEX's `Jammed` (`01_KX.txt:85-86`) rolls into a rocket barrage or a BFG.
* **no approach hop.** `Shotttgun` fires from wherever it stands
  (`01_K.txt:39-45`); TEX first checks range and hops in (`01_KX.txt:67-72`).
* `PlasmaSpammer` has no escape hatches; TEX's has two (`01_KX.txt:123`, `:132`).

CH `BlackZombie1` matches on all four — CHP did not remove anything here, it is
faithfully the lesser version. Only real CHP change: melee sound `player/fist`
(`CH/decorate/Zombies.txt:1954`) → `*fist` (`01_K.txt:32`), and `Jammed` gains an inert
`ZOMK E 0` filler at `:51`.

---

## §C — T12 WHITE · `CommonWhiteZombie1` · "UNDERTAKER" · the bone mage

The most elaborate tier in the family. A caster that summons skeletons, is *fed by
their deaths*, and escalates through four grades into a walking bone tornado.

### C.1 Properties

CHP (`CHP/DECORATE/01/01_W.txt:3-10`):

```
Health 3500        GibHealth -500      Speed 10      PainChance 16      Mass 400
Obituary    "Hey %o , the demons called the \c[ColorW]undertaker\c-~"
HitObituary "\c[ColorW]Shovel to the face?\c-"
Tag         "\c[ColorW]UNDERTAKER\c-"
```

Inherited from CH `WhiteZombie1` (`CH/decorate/Zombies.txt:2284-2323`):

```
Game Doom   Health 2800   Radius 16   Height 56   Mass 100   Speed 10   PainChance 16
Species "UnderTaker"
DamageFactor "Heroic",3.0    DamageFactor "DIMp",0     PainChance "DIMp",0
Monster  +BOSS  +QUICKTORETALIATE  +FLOORCLIP  +LOOKALLAROUND  +Missilemore
+Notarget  -NORADIUSDMG  +NOFEAR  +dontmorph  +dontharmspecies  +dontharmclass
Translation "205:205=192:192","206:206=88:88","207:207=93:93","241:241=99:99",
            "242:242=103:103","6:6=102:102","5:5=109:109","243:243=110:110",
            "250:254=152:158","164:167=107:111","0:0=0:0","125:125=112:112"
DeathSound "Under/Die"   SeeSound "Under/See"   painsound "skelpai"
DropItem "CH_SoulSphere" ×2 / Dropitem "CH_MegaSphere",72
DropItem "BackPack" / "BackPackBundle" / Dropitem "RareArmorPool",128
Dropitem "RLDemonicWeaponSpawner",12 / "RLLegendaryWeaponSpawner",4 / "RLUniqueWeaponSpawner",16
var int user_skel1;
tag "UNDERTAKER"
```

Three of these flags are load-bearing and easy to drop by accident:

* `Species "UnderTaker"` + `+dontharmspecies` — shared with `MrBones`
  (`CH/decorate/Zombies.txt:2128`), so its own skeletons cannot hurt it and it cannot
  hurt them. Without this the bone shotgun kills its own summons.
* `+Notarget` — other monsters will not retaliate against it. No infighting.
* `+dontharmclass` — the bone projectiles pass over other Undertakers.

`user_skel1` is the escalation counter and lives on the **CH parent**, not on CHP.

### C.2 Full state transcription — `CHP/DECORATE/01/01_W.txt:13-185`

```
Spawn:                                                                    (:13)
    MAGE A 0 Nodelay A_SpawnitemEx("NewIconCHP11_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
    Goto Scripted
Scripted:                                                                 (:16)
    MAGE A 0 ACS_NamedExecuteAlways("AnnounceWhiteZombie_C")
    MAGE A 0 A_Radiusgive("CHWhitePlan",16383,RGF_NOSIGHT|RGF_MONSTERS)
    Goto Idle
Idle:                                                                     (:20)
    MAGE A 4 A_Look
    Loop
See:                                                                      (:23)
    MAGE E 0 A_JumpIfInventory("BoneUp",12,"Buff3")          <- See+0
    MAGE E 0 A_JumpIfInventory("BoneUp",9,"Buff2")           <- See+1
    MAGE E 0 A_JumpIfInventory("BoneUp",5,"Buff1")           <- See+2
    MAGE ABCD 4 A_Chase                                      <- See+3..+6
    MAGE A 0 A_Jump(128,"See2")                              <- See+7
    Loop
See2:                                                                     (:30)
    MAGE ABCD 4 A_FastChase
    MAGE A 0 A_Jump(128,"See")
    Loop
Melee:                                                                    (:34)   <- falls through
Missile:                                                                  (:35)
    MAGE E 0 A_JumpIf(user_skel1==4,"FinalForm")
    MAGE E 0 A_JumpIfCloser(550,"Shovel",true)               <- true = 2D check, ignore height
    MAGE E 0 A_JumpIfCloser(1250,"MedRange")
    MAGE E 0 A_Jump(256,"RapidBone")
    GoTo See                                                 <- unreachable
FinalForm:                                                                (:41)
    MAGE E 0 A_JumpIfCloser(550,"Close2",true)
    MAGE E 0 A_JumpIfCloser(1250,"MedRange2")
    MAGE E 0 A_Jump(256,"RapidBone3")
    Goto See                                                 <- unreachable
Close2:                                                                   (:46)
    MAGE E 0 A_Jump(256,"ShotBone3","Shovel")
    Goto See                                                 <- unreachable
MedRange2:                                                                (:49)
    MAGE E 0 A_Jump(256,"ShotBone3","BoneTornado","RapidBone3")
    Goto See                                                 <- unreachable
BoneTornado:                                                              (:52)
    MAGE E 9 A_FaceTarget
    MAGE E 7 Bright A_Playsound("Under/Goodie",7,2,false,ATTN_NONE)
    MAGE E 7
    MAGE E 5 Bright
    MAGE E 5
    MAGE E 3 Bright
    MAGE E 3
    MAGE F 5 Bright A_Custommissile("BoneTorn2_C",4,0,random(-64,64))
    MAGE F 3 Bright
    MAGE E 3
    Goto See
RapidBone3:                                                               (:64)
    MAGE E 7 A_FaceTarget
    MAGE F 1 Bright                                          <- RapidBone3+1, the loop head
    MAGE FFF 1 Bright A_custommissile("BoneProjZM3_C",random(34,40),random(-1,1),random(-2,2),32,random(-1,1))
    MAGE F 1 A_Monsterrefire(120,"See")
    Goto RapidBone3+1
ShotBone3:                                                                (:70)
    MAGE E 8 A_FaceTarget
    MAGE F 5 Bright
    MAGE FFFFFFFFFFF 0 A_custommissile("BoneProjZM3_C",random(32,42),random(-5,5),random(-12,12),32,random(-3,3))
    MAGE E 5
    Goto See
MedRange:                                                                 (:76)
    MAGE E 0 A_Jump(256,"ShotBone","RapidBone")
    Goto See                                                 <- unreachable
ShotBone:                                                                 (:79)
    MAGE E 8 A_FaceTarget
    MAGE F 6 Bright A_JumpIf(user_skel1==3,"ShotBone2")
    MAGE FFFFFFFFF 0 A_custommissile("BoneProjZM_C",random(32,42),random(-5,5),random(-12,12),32,random(-3,3))
    MAGE E 5
    Goto See
ShotBone2:                                                                (:85)
    MAGE FFFFFFFFFFFF 0 A_custommissile("BoneProjZM2_C",random(32,42),random(-5,5),random(-12,12),32,random(-3,3))
    MAGE E 5
    Goto See
RapidBone:                                                                (:89)
    MAGE E 0 A_JumpIf(user_skel1==3,"RapidBone2")
    MAGE E 7 A_FaceTarget
    MAGE F 1 Bright                                          <- RapidBone+2, the loop head
    MAGE FF 1 Bright A_custommissile("BoneProjZM_C",random(34,40),random(-2,2),random(-5,5),32,random(-1,1))
    MAGE F 0 A_jump(12,"ShotBone")
    MAGE F 2 A_Monsterrefire(150,"See")
    Goto RapidBone+2
RapidBone2:                                                               (:97)
    MAGE E 7 A_FaceTarget
    MAGE F 1 Bright                                          <- RapidBone2+1, the loop head
    MAGE FF 1 Bright A_custommissile("BoneProjZM2_C",random(34,40),random(-1,1),random(-3,3),32,random(-1,1))
    MAGE F 0 A_jump(12,"ShotBone2")
    MAGE F 1 A_Monsterrefire(120,"See")
    Goto RapidBone2+1
Shovel:                                                                   (:104)
    MAGE E 7 A_FaceTarget
    MAGE F 7 Bright A_Playsound("Spell/SpellCast1")
    MAGE F 0 A_custommissile("ShoveZM_C",38,0,0)
    MAGE F 0 A_custommissile("ShoveZM_C",38,3,5)
    MAGE F 0 A_custommissile("ShoveZM_C",38,-3,-5)
    MAGE E 0 A_JumpIf(user_skel1==3,"ShotBone2")
    MAGE E 6 A_Jump(128,"missile","ShotBone")
    Goto See
Reset:                                                                    (:113)
    MAGE A 0
    Goto See+3
Buff1:                                                                    (:116)
    MAGE A 0 A_GivetoChildren("GoAway",1)
    MAGE A 0 A_SpawnitemEx("NewIconCHP11_T2_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
    MAGE A 0 A_JumpIf(user_skel1>=2,"Reset")
    MAGE A 0 A_Playsound("Under/Goodie",7,2,false,ATTN_NONE)
    MAGE AAAAAAAAAAAAAAA 0 a_Spawnparticle("Green",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(1,13),frandom(0,360),0,0,12,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
    MAGE E 1 A_ChangeFlag(MISSILEEVENMORE,TRUE)
    MAGE E 1 A_Setuservar("user_skel1",user_skel1+2)
    MAGE E 5 A_Setspeed(16)
    MAGE E 0 A_SetScale(1.1,1.1)
    Goto See+3
Buff2:                                                                    (:127)
    MAGE A 0 A_GivetoChildren("GoAway",1)
    MAGE A 0 A_SpawnitemEx("NewIconCHP11_T3_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
    MAGE A 0 A_JumpIf(user_skel1>=3,"Reset")
    MAGE A 0 A_Playsound("Under/Goodie",7,2,false,ATTN_NONE)
    MAGE AAAAAAAAAAAAAAA 0 a_Spawnparticle("Yellow",...)
    MAGE E 1 A_Setuservar("user_skel1",user_skel1+1)
    MAGE E 1 A_Setspeed(21)
    MAGE E 6 A_SetScale(1.25,1.25)
    Goto See+3
Buff3:                                                                    (:137)
    MAGE A 0 A_GivetoChildren("GoAway",1)
    MAGE A 0 A_SpawnitemEx("NewIconCHP11_T4_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
    MAGE A 0 A_JumpIf(user_skel1>=4,"Reset")
    MAGE A 0 A_Playsound("Under/Goodie",7,2,false,ATTN_NONE)
    MAGE AAAAAAAAAAAAAAA 0 a_Spawnparticle("Red",...)
    MAGE E 0 A_ChangeFlag(NOPAIN,TRUE)
    MAGE E 1 A_Setuservar("user_skel1",user_skel1+1)
    MAGE E 1 A_Setspeed(28)
    MAGE E 7
    MAGE E 0 A_SetScale(1.45,1.45)
    MAGE E 12
    Goto See+3
Pain:                                                                     (:150)
    MAGE G 4
    MAGE G 4 A_Pain
    Goto See
Death.Ice:                                                                (:154)
Death:                                                                    (:155)
    TNT1 A 0 A_GivetoChildren("GoAway",1)
    MAGE H 13
    MAGE I 13 A_Scream
    MAGE J 13 A_NoBlocking
    MAGE KLM 13
    MAGE N 0 A_SpawnItemEx("RandomLetterSpawner_C",0,0,0,frandom(-7500,7500)/1000,frandom(-7500,7500)/1000,0,0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,220)
    MAGE N -1
    stop
xdeath:                                                                   (:164)
    TNT1 A 0 A_GivetoChildren("GoAway",1)
    TNT1 AAAAAAAAAAAAAAAAAAAAAAAAAAA 0 a_Spawnparticle("White",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(1,13),frandom(0,360),0,0,32,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
    TNT1 A 0 A_Playsound("UNDERGIB",0,255,0,0)
    TNT1 AAAA 0 A_Custommissile("CH_BoneGib_C",0,12,random(-180,180),0,random(0,90))
    TNT1 AAAAA 1 A_SpawnItemEx("HomingRocketTrailFatso_C",random(-12,12),random(-12,12),random(20,52),0,0,0,0,0)
    TNT1 AAAAAAAA 0 A_SpawnItemEx("HomingRocketTrailFatso_C",random(-32,32),random(-32,32),random(10,64),0,0,0,0,0)
    TNT1 AAA 1 A_SpawnItemEx("HomingRocketTrailFatso_C",random(-2,2),random(-2,2),random(26,34),0,0,0,0,0)
    TNT1 A 0 A_SetTranslucent(0.1)
    REVB A 1 thrustthingz(0,45,0,0)
    MAGE X 12
    TNT1 A 0 A_SetTranslucent(0.35)
    TNT1 AAA 0 A_Custommissile("CH_BoneGib_C",0,12,random(-180,180),0,random(0,90))
    MAGE X 12
    TNT1 A 0 A_SetTranslucent(0.7)
    TNT1 AA 0 A_Custommissile("CH_BoneGib_C",0,12,random(-180,180),0,random(0,90))
    MAGE X 12
    TNT1 A 0 A_SetTranslucent(1)
    TNT1 A 0 A_Custommissile("CH_BoneGib_C",0,12,random(-180,180),0,random(0,90))
    MAGE X 0 A_SpawnItemEx("RandomLetterSpawner_C",...,220)
    MAGE X -1
    stop
```

`xdeath` is **CHP-only** — CH `WhiteZombie1` defines no XDeath at all
(`CH/decorate/Zombies.txt:2465-2471` ends at `Death`). It is a ten-second fade-out in
which the corpse becomes solid again over three 12-tic beats while shedding ten
`CH_BoneGib_C` bones. This is the single largest thing a summarising port loses.

### C.3 The four-grade escalation ladder — the heart of T12

**Driver:** the inventory item `BoneUp` (`CH/decorate/Zombies.txt:2219`,
`Actor BoneUp : Inventory { Inventory.MaxAmount 30 }`) plus the actor user variable
`user_skel1` (declared `CH/decorate/Zombies.txt:2322`). **No ACS is involved.**

**Feed:** the Undertaker does not earn `BoneUp` by fighting. `MrBones_C` earns it *by
dying* (`CHP/DECORATE/01/01_W.txt:3027-3029`):

```
SKLT P 0  A_Radiusgive("Health",528,RGF_MONSTERS,random(12,128),"CommonWhiteZombie1")
SKLT P 0  A_Radiusgive("BoneUp2_C",528,RGF_MONSTERS,1,"CommonWhiteZombie1")
SKLT P 12 A_Radiusgive("BoneUp",528,RGF_MONSTERS,1,"CommonWhiteZombie1")
```

So every skeleton the player kills inside 528 units heals the Undertaker
`random(12,128)`, plays the ghost-wisp effect (`BoneUp2_C`, §G), and adds one rung.
**Killing the summons is how you power up the boss.** That is the design.

| rung | trigger | state | user_skel1 | effect |
|---|---|---|---|---|
| 0 | — | — | 0 | Speed 10, Scale 1.0, `+MISSILEMORE` from CH |
| 1 | `BoneUp` ≥ 5 | `Buff1` `:116` | `+2` → 2 | `+MISSILEEVENMORE`, `A_Setspeed(16)`, `A_SetScale(1.1,1.1)`, green particles |
| 2 | `BoneUp` ≥ 9 | `Buff2` `:127` | `+1` → 3 | `A_Setspeed(21)`, `A_SetScale(1.25,1.25)`, yellow particles. **Unlocks grade-2 bones** (`ShotBone2` / `RapidBone2`) |
| 3 | `BoneUp` ≥ 12 | `Buff3` `:137` | `+1` → 4 | `+NOPAIN`, `A_Setspeed(28)`, `A_SetScale(1.45,1.45)`, red particles. **Unlocks `FinalForm`** — grade-3 bones and the **BONE TORNADO** |

All of `A_Setspeed` / `A_SetScale` are **absolute**, not multiplicative: 10→16→21→28
and 1.0→1.1→1.25→1.45. It nearly triples its speed and gets half again as big.

The gates are re-checked at the top of `See` every loop, so the ladder is one-shot per
rung only because of the `A_JumpIf(user_skel1>=N,"Reset")` guards. `Reset` (`:113`)
jumps to `See+3`, the first `A_Chase` frame, which is why the buff checks are the first
three zero-tic states.

Grade gates use exact equality (`user_skel1==3` at `:81`, `:90`, `:110`;
`user_skel1==4` at `:36`). See §J.3 for why that is fragile.

### C.4 What changes per grade (the whole T12 attack table)

| range band | grade 0–1 (`Missile` `:35`) | grade 3 (`FinalForm` `:41`) |
|---|---|---|
| < 550 (2D) | `Shovel` | `Close2` → 50/50 `ShotBone3` \| `Shovel` |
| < 1250 | `MedRange` → 50/50 `ShotBone` \| `RapidBone` | `MedRange2` → 1/3 each `ShotBone3` \| **`BoneTornado`** \| `RapidBone3` |
| ≥ 1250 | `RapidBone` | `RapidBone3` |

Grade 2 (`user_skel1==3`) does not change the *dispatch*; it upgrades the projectile
in place — `ShotBone`→`ShotBone2` (`:81`), `RapidBone`→`RapidBone2` (`:90`), and
`Shovel` chains into `ShotBone2` instead of `ShotBone` (`:110`).

### C.5 "The Plan" — the map-wide skeleton seeding

`Scripted` (`01_W.txt:18`) fires
`A_Radiusgive("CHWhitePlan",16383,RGF_NOSIGHT|RGF_MONSTERS)` — 16383 map units, no
sight check, monsters only. That is *every monster on the map*.

`CHWhitePlan` is `Actor CHWhitePlan : Inventory { Inventory.MaxAmount 1 }`
(`CHP/DECORATE/01/01_W.txt:9430`), and **128 CHP decorate files** contain a
`A_JumpIfInventory("CHWhitePlan",1,"Tickles")` in their `Death` state — including the
T10 Red Zombie at `01_R.txt:49`. `Tickles` spawns `WhiteZombiePlan_<colour>`, which
hatches into a skeleton.

`WhiteZombiePlan_C` (`CHP/DECORATE/01/01_W.txt:8930-8962`):

```
Spawn:
    TNT1 A 0 Nodelay A_JumpIf(CallACS("CH_WZPlan") == 1,"DoIt")
    TNT1 A 0 A_JumpIf(CallACS("CH_WZPlan") == 2,"Maybe")
    TNT1 A 0 A_JumpIf(CallACS("CH_WZPlan") == 3,"Death2")
Maybe:
    TNT1 A 0 A_Jump(85,"DoIt")            <- 85/256 ~= 33 %
    Goto Death2
DoIt:
    BBBN A 3
    Goto Hatch
Hatch:
    BBBN BCD 5
    TNT1 AAAAAAAAAAAAAAA 0 a_Spawnparticle("White",...)
    TNT1 A 3 Bright A_Spawnitemex("MrBones_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION)
    Goto Death2
Death: MISL B 0 A_SetScale(0.4,0.4) / MISL BCD 3 / Stop
Death2: TNT1 A 0 / stop
```

So while one Undertaker is alive, **anything that dies anywhere on the map may leave a
skeleton behind**, and each of those skeletons, when killed, feeds the Undertaker's
ladder. The whole map becomes its resource pool. `CH_WZPlan` is a CVar (§I).

Note the CHP variant is *not* CH's `ThePlanBoner` (`CH/decorate/Zombies.txt:2046`) —
CHP adds the CVar gate, `Health 10`, `+NOCLIP`, a white translation, and drops one
`BBBN A` frame from `Hatch`.

---

## §D — TEX · `CommonBlackZombieEX2` · "Player X"

Not a zombie. A player marine with the full arsenal, a real super-shotgun reload, a
range ladder, dodge hops in four directions — **and it stops shooting to laugh at
corpses**.

### D.1 Properties

CHP (`CHP/DECORATE/01/01_KX.txt:3-14`):

```
Health 5000        GibHealth -500      Speed 28      PainChance 16
SeeSound "HEHEEENH"     ActiveSound "HEHEEENH"
DeathSound "*death"     PainSound "*pain50"
Obituary    "%o met the \c[ColorKX]player X\c- "
HitObituary "\c[ColorKX]Player X\c-: lmao owned rekt gg ez"
tag         "\c[ColorKX]Player X\c-"
Translation None
```

`Translation None` explicitly clears CH's 11-range silhouette translation
(`CH/decorate/Zombies.txt:1636`) — CHP ships a pre-blackened `ZMKX` sprite set.

Inherited from CH `BlackZombieEX` (`CH/decorate/Zombies.txt:1609-1653`):

```
Game Doom   Health 5000   Radius 16   Height 56   Mass 100   Speed 28   PainChance 16
DamageFactor "Heroic",3.0    DamageFactor "PlayerVoid",0.5   DamageFactor "DIMp",0
PainChance "DIMp",0          DamageFactor "Falling",0.0  (declared twice, :1620 and :1621)
PainChance "PLWater",12   PainChance "ice",12   PainChance "Fire",4   PainChance "Melee",12
Monster  +LAXTELEFRAGDMG  +BOSS  +QUICKTORETALIATE  +FLOORCLIP  +LOOKALLAROUND
+Missilemore  +dontmorph  -NORADIUSDMG  +NOFEAR
DropItem "CH_SoulSphere" / "CH_MegaSphere" / "CH_PlasmaRifle" / "CH_Chaingun" / "CH_SuperShotgun"
Dropitem "RareArmorPool",128 / "RLFragShotgunPickup",84
DropItem "BackPack" / "BackPackBundle" / Dropitem "RLUniqueWeaponSpawner",24
tag "Player X"
```

`+LAXTELEFRAGDMG` and `DamageFactor "PlayerVoid",0.5` are TEX-only (Player 9 has
neither). `PainChance "Melee",12` vs Player 9's 42 — you cannot punch it out of its
rhythm.

### D.2 Full state transcription — `CHP/DECORATE/01/01_KX.txt:17-190`

```
Spawn:                                                                    (:17)
    ZMKX A 0 Nodelay A_SpawnitemEx("NewIconCHP10_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
    ZMKX A 0 A_SpawnitemEx("NewIconCHP30_T1_C",0,0,72,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
    Goto Scripted
Scripted:                                                                 (:21)
    ZMKX A 0 ACS_NamedExecuteAlways("AnnounceBlackZombie_C")
    ZMKX A 0 ACS_NamedExecuteAlways("EXBOSS")
    Goto Idle
Idle:                                                                     (:25)
    ZMKX A 4 A_Look
    Loop
See:                                                                      (:28)
    ZMKX ABCD 4 A_Chase
    ZMKX A 0 A_Jump(128,"See2")
    Loop
See2:                                                                     (:32)
    ZMKX ABCD 4 A_FastChase
    ZMKX A 0 A_Jump(128,"See")
    Loop
Melee:                                                                    (:36)
    ZMKX E 4 A_FaceTarget
    ZMKX E 4 a_custommeleeattack(random(60,120), "*fist", "none")
    ZMKX E 0 A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)      <-- GLOAT CHECK 1
    Goto Shotttgun
Missile:                                                                  (:41)
    ZMKX E 0 a_Jumpifcloser (300, "shotttgun")
    ZMKX E 0 a_JumpIfCloser (840, "PlasmaSpammer")
    ZMKX E 0 A_Jump (256, "Rawkets")
    GoTo See                                                 <- unreachable
Taunt:                                                                    (:46)
    ZMKX A 4
    ZMKX G 4 A_Playsound("HEHEEENH",0)
    ZMKX A 4
    ZMKX G 4 A_Playsound("HEHEEENH",0)
    ZMKX A 4
    ZMKX G 4 A_Playsound("HEHEEENH",0)
    ZMKX A 4
    ZMKX G 4 A_Playsound("HEHEEENH",0)
    ZMKX A 4
    ZMKX G 4 A_Playsound("HEHEEENH",0)
    ZMKX A 3
    ZMKX G 3 A_Playsound("HEHEEENH",0)
    ZMKX A 3
    ZMKX G 3 A_Playsound("HEHEEENH",0)
    ZMKX A 3
    ZMKX G 3 A_Playsound("HEHEEENH",0)
    ZMKX GAG 4 A_Playsound("HEHEEENH",0)     <- action fires on EACH of the 3 frames
    ZMKX AGA 3 A_Playsound("HEHEEENH",0)     <- and each of these 3
    ZMKX GAG 2 A_Playsound("HEHEEENH",0)     <- and each of these 3
    goto see
Shotttgun:                                                                (:67)
    ZMKX E 3 A_FaceTarget
    ZMKX E 1 A_jumpifcloser(300,"SHOOTMYDUDE")
    ZMKX E 1 thrustthingz(0,64,0,0)                          <- hop UP  (64 quarter-units = 16)
    ZMKX E 1 thrustthing(angle,12,0,0)                       <- lunge FORWARD
    ZMKX E 10 A_FaceTarget
Shootmydude:                                                              (:73)
    ZMKX F 0 A_JumpIfInventory("ShotgunWhere", 1, "Jammed")
    ZMKX F 0 A_PlaySound("weapons/sshotf")
    ZMKX F 13 Bright A_CustomBulletAttack(22.5, 5, 8, 6, "BulletPuff_C", 0)
    ZMKX E 0 A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)      <-- GLOAT CHECK 2
    ZMKX F 0 A_GiveInventory("ShotgunWhere",1)
    Goto See
Jammed:                                                                   (:80)   <- THE RELOAD
    ZMKX E 8 Bright
    ZMKX A 2 A_Playsound("weapons/sshotl")
    ZMKX A 8 A_TakeInventory("ShotgunWhere",1)
    ZMKX E 2 A_SpawnItemEx("Shell",8,4,32,3,3,1,angle+5)
    ZMKX E 0 A_jump(84,"RBarrage")                           <- 84/256 = 33 % barrage
    ZMKX E 0 A_jump(64,"BFGBoi")                             <- 64/256 = 25 % of the rest -> BFG
    Goto Missile
RBarrage:                                                                 (:88)
    ZMKX E 1 thrustthingz(0,64,0,0)
    ZMKX E 1 thrustthing(angle-180,12,0,0)                   <- back-hop
    ZMKX E 6 A_FaceTarget
    TNT1 A 0 A_jump(128,"AltBar")                            <- 50 % mirror the strafe
    ZMKX E 1 thrustthingz(0,64,0,0)
    ZMKX E 3 thrustthing(angle+90,12,0,0)                    <- strafe RIGHT
    ZMKX F 4 Bright A_Custommissile("Rocket_C",32,0,random(-1,1))
    ZMKX E 0 A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)      <-- GLOAT CHECK 3
    ZMKX F 4 Bright A_Custommissile("Rocket_C",32,0,random(-1,1))
    ZMKX E 0 A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)      <-- GLOAT CHECK 4
    ZMKX F 4 Bright A_Custommissile("Rocket_C",32,0,random(-1,1))
    ZMKX E 0 A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)      <-- GLOAT CHECK 5
    Goto see
AltBar:                                                                   (:102)
    ZMKX E 1 thrustthingz(0,64,0,0)
    ZMKX E 3 thrustthing(angle-90,12,0,0)                    <- strafe LEFT
    ZMKX F 4 Bright A_Custommissile("Rocket_C",32,0,random(-1,1))
    ZMKX E 0 A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)      <-- GLOAT CHECK 6
    ZMKX F 4 Bright A_Custommissile("Rocket_C",32,0,random(-1,1))
    ZMKX E 0 A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)      <-- GLOAT CHECK 7
    ZMKX F 4 Bright A_Custommissile("Rocket_C",32,0,random(-1,1))
    ZMKX E 0 A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)      <-- GLOAT CHECK 8
    Goto see
BFGBoi:                                                                   (:112)
    ZMKX E 1
    ZMKX E 1 a_playsound("weapons/bfgf",0)
    ZMKX E 10 bright
    ZMKX E 8 bright A_FaceTarget
    ZMKX E 6 bright A_FaceTarget                             <- 26 tics of charge, telegraphed
    ZMKX F 4 Bright A_Custommissile("PlayerEXBFG_C",32,0,0)
    ZMKX E 12
    ZMKX E 0 A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)      <-- GLOAT CHECK 9
    Goto see
PlasmaSpammer:                                                            (:122)
    ZMKX E 0 A_jump(84,"RBarrage")                           <- 33 % bail into barrage
    ZMKX E 2 A_FaceTarget
    ZMKX E 0 A_FaceTarget
    ZMKX F 3 Bright A_custommissile("PlasmaBallSP3_C", 32, 0, random(-5,5))
    ZMKX E 1 A_FaceTarget
    ZMKX F 3 Bright A_custommissile("PlasmaBallSP3_C", 32, 0, random(-15,15))
    ZMKX E 1 A_FaceTarget
    ZMKX F 3 Bright A_custommissile("PlasmaBallSP3_C", 32, 0, random(-25,25))
    ZMKX E 1 A_FaceTarget
    ZMKX E 0 A_jump(34,"BFGBoi")                             <- 34/256 = 13 % mid-burst BFG
    ZMKX F 3 Bright A_custommissile("PlasmaBallSP3_C", 32, 0, random(-35,35))
    ZMKX E 0 A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)      <-- GLOAT CHECK 10
    ZMKX A 0 A_MonsterRefire(128,"CellEject")
    Goto Missile
CellEject:                                                                (:137)
    ZMKX A 8
    ZMKX GG 3 A_SpawnItemEx("Cell",8,4,32,3,3,1,angle+5)
    ZMKX A 3
    Goto See
Rawkets:                                                                  (:142)
    ZMKX E 2 A_FaceTarget
    ZMKX F 2 Bright A_custombulletattack(5.6, 0, 1, 5, "BulletPuff_C")
    ZMKX E 2 A_Jump(32,"ActualRawk")                         <- 32/256 = 12.5 % rocket
    ZMKX E 0 A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)      <-- GLOAT CHECK 11
    ZMKX E 0 A_jump(8,"BFGBoi")                              <- 8/256 = 3 % BFG
    ZMKX A 0 A_CPosRefire
    Goto Missile
    ZMKX A 0                                                 <- DEAD, unreachable
    Goto See
ActualRawk:                                                               (:152)
    ZMKX E 2 A_FaceTarget
    ZMKX F 2 Bright A_Custommissile("Rocket_C",32,0,random(-1,1))
    ZMKX E 0 A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET)      <-- GLOAT CHECK 12
    ZMKX E 2 A_jump(34,"BFGBoi")                             <- 13 % BFG
    Goto Missile
Pain:                                                                     (:158)
    ZMKX G 4
    ZMKX G 4 A_Pain
    ZMKX E 0 A_jump(84,"RBarrage")                           <- 33 % ANSWERS PAIN WITH ROCKETS
    Goto See
Death.Ice:                                                                (:163)
Death:                                                                    (:164)
    ZMKX H 10 A_GivetoChildren("GoAway",1)
    ZMKX I 10 A_Scream
    ZMKX J 10 A_NoBlocking
    ZMKX I 10 A_PlaySound("*death")
    ZMKX J 10
    ZMKX I 10 A_PlaySound("*death")
    ZMKX J 10
    ZMKX I 10 A_PlaySound("*death")
    ZMKX J 10
    ZMKX KLM 10
    ZMKX M 0 A_SpawnItemEx ("RandomLetterSpawner_C",0,0,0,frandom(-7500,7500)/1000,frandom(-7500,7500)/1000,0,0,SXF_ABSOLUTEMOMENTUM|SXF_NOCHECKPOSITION,220)
    ZMKX M -1
    stop
XDeath:                                                                   (:178)
    ZMKX H 5  A_GivetoChildren("GoAway",1)
    ZMKX H 20 A_PlaySound("*xdeath",0,255,0,0)
    TNT1 AAA 0 A_SpawnItemEx ("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
    ZMKX O 5 A_PlaySound("misc/gibbed/c")
    ZMKX P 5 A_XScream
    TNT1 AAA 0 A_SpawnItemEx ("CHRandom_GibGenerator",...)
    ZMKX Q 5 A_NoBlocking
    ZMKX RSTUV 5
    TNT1 AAA 0 a_Spawnparticle("Red",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(1,13),frandom(0,360),0,0,24,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
    ZMKX M 0 A_SpawnItemEx ("RandomLetterSpawner_C",...,220)
    ZMKX W -1
    Stop
```

### D.3 The gloat, precisely

`A_CheckFlag("CORPSE", "TAUNT", AAPTR_TARGET)` — checks the `CORPSE` flag on **its
current target** and jumps to `Taunt` if set. There are **twelve** such checks
(`:39, :77, :96, :98, :100, :106, :108, :110, :120, :134, :146, :155`), one after
practically every attack beat.

In play: if the thing it was shooting at is now a corpse — which in a Colourful Hell
map is constantly true, since it will happily target and kill other monsters — it
breaks off and spends **85 tics (~2.4 s) of pure showboating**, laughing **seventeen times**. Eleven
state lines carry `A_Playsound("HEHEEENH",0)`, but an action fires once per FRAME, so
the last three (`ZMKX GAG 4`, `ZMKX AGA 3`, `ZMKX GAG 2`) are 3 calls each: 8 + 9 = 17.

That taunt window is the fight's only free breathing room and the whole reason Player X
reads as a person rather than a turret. It is content, not cruft.

CH's `BlackZombieEX` (`CH/decorate/Zombies.txt:1689-1709`) has the identical Taunt with
`PLAY` sprites; CHP only reskinned it to `ZMKX`.

### D.4 CHP-vs-CH deltas for TEX

| | CH `BlackZombieEX` | CHP `CommonBlackZombieEX2` |
|---|---|---|
| spawn text | `PLAY A 1 A_log("A chill runs down your spine")` `:1662` | `ACS_NamedExecuteAlways("EXBOSS")` `:23` — HUD typeon + `Radius_quake(1,35,0,1200,0)` |
| Shotttgun approach | `PLAY E 10` (idle) `:1715` | `ZMKX E 10 A_FaceTarget` `:72` |
| RBarrage strafe | `PLAY E 1 thrustthing(angle+90,…)` + `PLAY E 2` `:1737-1738` | merged `ZMKX E 3 thrustthing(angle+90,…)` `:94` (same 3 tics) |
| PlasmaSpammer beat 4 | `PLAY E 1` `:1776` | `ZMKX E 1 A_FaceTarget` `:131` |
| Rawkets open | `PLAY E 2` `:1788` | `ZMKX E 2 A_FaceTarget` `:143` |
| ActualRawk open | `PLAY E 2` `:1798` | `ZMKX E 2 A_FaceTarget` `:153` |
| melee sound | `"player/fist"` `:1680` | `"*fist"` `:38` |
| Death.Ice / GivetoChildren / letters | absent | added `:163, :165, :175` |
| XDeath | **absent entirely** | full 13-line XDeath `:178-190` |

CHP made Player X aim *more* (four extra `A_FaceTarget`) and gave it a gib death.

---

## §E — TEX "WX" (White EX) : **THIS TIER DOES NOT EXIST**

This is the clearest result of the read and it needs to be recorded so nobody hunts
for it again.

1. `CHP/DECORATE/01/01_WX.txt` is **2 bytes**: the literal text `//`. Zero actors.
   It *is* included — `CHP/DECORATE.txt:661` — so it is a deliberate empty file, not
   a missing one.
2. There is **no `WhiteZombieEX` actor anywhere** in CH. `CH/decorate/Zombies.txt`
   defines `RedZombie` (`:1441`), `BlackZombieEX` (`:1607`), `BlackZombie1` (`:1888`),
   `WhiteZombie1` (`:2282`) — and nothing else EX-shaped for family 01.
3. CH's spawn chain has no WX rung: `Actor WhiteZombie`
   (`CH/decorate/Zombies.txt:2027-2044`) branches only `First` → `WhiteZombie1` or
   `Third` → `BlackZombie`. `Actor BlackZombie` (`:1569`) is where `CH_ExBoss` is read
   and `BlackZombieEX` is rolled.
4. CHP **explicitly stubs it to nothing**: `CHP/DECORATE.txt:369-383` —

   ```
   Actor CommonWhiteZombieEX : Nothin {}
   Actor GreenWhiteZombieEX  : Nothin {}
   ... (15 spawn colours, all : Nothin)
   ```

   with `Actor Nothin { +NOCLIP +NOBLOCKMAP +NOGRAVITY States { Spawn: TNT1 A 0 Stop } }`
   at `CHP/DECORATE.txt:11-22`.
5. `CHP/DECORATE/MISC/op_s_checks.txt:1054-1170` still contains fifteen
   `<Colour>WhiteZombieEXCheck` actors that spawn those stubs. They resolve — because
   of the `: Nothin` line — but they spawn nothing. So the sub-tier plumbing is wired
   to a hole on purpose.

**Conclusion:** family 01 has exactly ONE EX tier, KX / Player X. Do not port a WX
Zombieman. Compare families that DO have one: `CHP/DECORATE/12WX.txt`,
`14WX.txt`, `17WX.txt` exist as real top-level files.

---

## §F — THE CATALOG (rs_21 §4 format)

`axes` values are restricted to what is live in this repo today. Verified by
`grep "return \"species:" zscript/monsters/*.zs` and
`grep -o '<axis>:[a-z-]*' zscript/weapons/` — union:

* `delivery:` bullet · melee · heavy · radial
* `payload:` single · multi · cluster · explosive
* `element:` kinetic · thermal · plasma · void · explosive · melt
* `archetype:` pistol · rifle · smg · chaingun · shotgun · supershotgun · revolver ·
  railgun · launcher · energy · bfg · flamethrower · melee
* `trigger:` semi · semiauto · burst · fullauto
* `species:`/`role:`/`mobility:`/`trait:` per `zscript/systems/RS_MonsterKeywordIndex.zs`

There is **no live value for "summon", "bone", "ice", or "taunt"**. Where nothing fits
the `notes:` line says so; nothing is invented here.

---

### Unmaker Snapshot            zscript/monsters/Zombieman/attacks/RS_Zombieman_UnmakerSnap.zs
```
kind         : lazy single potshot from a dying energy rifle
axes         : delivery:bullet payload:single element:kinetic
               archetype:rifle trigger:semi
tier(s)      : T10 Red  (Zombieman)
chp source   : CHP/DECORATE/01/01_R.txt:19-24  (CH/decorate/Zombies.txt:1486-1492)
acs          : none
fires        : 1 hitscan bullet, 10 deg horizontal / 2 deg vertical spread,
               puff BloodyPuff_C (CHP/DECORATE/01/01_R.txt:1602)
damage       : random(5,15) x random(1,3)   <- A_CustomBulletAttack multiplies by
               random(1,3) unless CBAF_NORANDOM is passed; CHP passes no flags.
               Effective band 5..45.  CH's was random(5,25) x random(1,3).
sprites      : ZUNM E (aim, 15t) / ZUNM F (fire, 10t) / ZUNM E (recover, 10t)
sounds       : attacksound "zombie/unmaker" (CH/decorate/Zombies.txt:1451)
behaviour    : The default 75 % branch. It stands still for a quarter second, points
               the Unmaker at you and coughs out one wide, weak round -- more of a
               warning shot than an attack. Being hit by it is a scratch; the point of
               it is the 25 % of the time it does the other thing instead.
profile      : RS_AttackProfile.MakeHitscan("zombie/unmaker", 0.18, 0, null, "", false,
                   "Unmaker Snapshot", "RS_BloodyPuff")
notes        : CHP widened CH's 2 deg spread to 10 deg while cutting the damage ceiling
               from 25 to 15 -- deliberately made worse so the beam branch is the star.
```

### Unmaker Beam Burst          zscript/monsters/Zombieman/attacks/RS_Zombieman_UnmakerBeam.zs
```
kind         : five-shot fading-red railgun burst that reloops until it loses you
axes         : delivery:bullet payload:single element:kinetic
               archetype:railgun trigger:burst
tier(s)      : T10 Red  (Zombieman)
chp source   : CHP/DECORATE/01/01_R.txt:25-38  (CH/decorate/Zombies.txt:1493-1506)
acs          : none
fires        : 5 x A_CustomRailgun(random(5,10), 4, <colour>, 0, 0), one per tic,
               colours stepping FF0000 -> CC0000 -> 990000 -> 550000 -> 330000
damage       : random(5,10) per beam, 5 beams -> random(25,50) per burst.
               CH's was random(5,20) per beam.
sprites      : ZUNM E (aim, 16t) / ZUNM F 1 BRIGHT x5 (the beams) / ZUNM E 10 (refire)
sounds       : A_PlaySound("zombie/unpower") once before EACH beam -- 5 per burst
behaviour    : Entered on a 64/256 roll off Missile. It plants, and then rails you five
               times in five tics, the beam visibly draining from bright red to almost
               black as the Unmaker's charge dies. Then A_SentinelRefire re-aims and,
               unless you have broken line of sight or died, it does it again, and
               again -- `goto Missile2+1` skips the aim frame so every repeat is
               faster than the first. It is a hitscan chain-drain, not a burst.
profile      : RS_AttackProfile.MakeHitscan("zombie/unpower", 0.0, 0, null, "", false,
                   "Unmaker Beam Burst")
               -- needs 5 beats; today this is one profile fired 5x from the state,
               or a BurstCount:5 / BurstDelayTics:1 profile once rs_17 s4 lands.
notes        : The colour ramp is per-tier data in CHP: Green uses 18A818 -> 082808
               (01_R.txt:106-114), Blue 184DA8 -> 061028 (:184-192). Five hex strings
               per colour, 15 colours. That is a TintTable job, not 15 ports.
               A_SentinelRefire is a GZDoom stock function -- re-faces the target and
               breaks to See on a random check or when the target is dead/unseen.
```

### Player 9 Fist               zscript/monsters/Zombieman/attacks/RS_Zombieman_MarineFist.zs
```
kind         : a punch from a man who used to be a marine
axes         : delivery:melee payload:single element:kinetic archetype:melee
tier(s)      : T11 Black  (Zombieman) -- TEX uses the same attack at double damage
chp source   : CHP/DECORATE/01/01_K.txt:30-33
acs          : none
fires        : A_CustomMeleeAttack(random(20,80), "*fist", "none")
damage       : random(20,80)   (TEX: random(60,120), CHP/DECORATE/01/01_KX.txt:38)
sprites      : ZOMK E 4 (face) / ZOMK E 4 (swing)      [TEX: ZMKX]
sounds       : "*fist" -- CHP changed CH's "player/fist" (CH/decorate/Zombies.txt:1954)
               to the player-sound alias
behaviour    : Eight tics, no wind-up, and it does not stop there: Melee falls straight
               through into Shotttgun, so a punch is always followed by a shell in the
               chest at contact range. That pairing is the attack, not the punch.
profile      : RS_AttackProfile.MakeMelee(64.0, "*fist", null, false, 1.0, "Player 9 Fist")
notes        : TEX inserts a gloat check between the punch and the shotgun
               (01_KX.txt:39). T11 does not.
```

### Player 9 Super Shotgun      zscript/monsters/Zombieman/attacks/RS_Zombieman_MarineSSG.zs
```
kind         : one barrel of double-barrel, then a real reload
axes         : delivery:bullet payload:multi element:kinetic
               archetype:supershotgun trigger:semi
tier(s)      : T11 Black, TEX  (Zombieman)
chp source   : CHP/DECORATE/01/01_K.txt:39-52   TEX: CHP/DECORATE/01/01_KX.txt:67-87
acs          : none
fires        : A_CustomBulletAttack(22.5, 5, 8, 6, "BulletPuff_C", 0)
               -- 8 pellets, 22.5 deg horizontal / 5 deg vertical
damage       : 6 x random(1,3) per pellet, 8 pellets -> 48..144 per shell.
               The roll is the engine's: A_CustomBulletAttack multiplies
               damageperbullet by random(1,3) unless CBAF_NORANDOM. Do NOT port this
               as flat 48.
sprites      : ZOMK E 3 (aim) / ZOMK F 13 BRIGHT (fire) ;
               reload ZOMK E 8 BRIGHT / ZOMK A 2 / ZOMK A 8 / ZOMK E 2
sounds       : "weapons/sshotf" on fire, "weapons/sshotl" on rack
behaviour    : It carries exactly one loaded shell, tracked by the inventory token
               ShotgunWhere (CH/decorate/Zombies.txt:2025, MaxAmount 1). Fire and the
               token is set; the next time it wants the shotgun it is JAMMED and must
               spend 20 tics standing still racking the gun and flicking a live Shell
               actor out of the breech. That reload is the fight's rhythm: the shot is
               enormous and the window afterwards is real.
               TEX's version differs twice: it hops toward you first if you are further
               than 300 (thrustthingz 64 + thrustthing forward 12, 01_KX.txt:69-72), and
               its reload COMMITS -- 84/256 into the rocket barrage, then 64/256 of the
               remainder into the BFG (01_KX.txt:85-86). Punishing the reload on TEX
               is how you eat three rockets.
profile      : RS_AttackProfile.MakeBullet("weapons/sshotf", 0.39, false, 1, "Shell",
                   true, false, 1.0, null, "Player 9 Super Shotgun", "RS_BulletPuff")
               with PelletOverride 8
notes        : the reload is a STATE, not a profile beat. Until rs_17 s4's WindupTics /
               FireOnRelease land there is no profile field that can express "this beat
               costs the next 20 tics".
```

### Player 9 Plasma Spam        zscript/monsters/Zombieman/attacks/RS_Zombieman_MarinePlasma.zs
```
kind         : four plasma bolts on a widening cone, walked across your face
axes         : delivery:heavy payload:single element:plasma
               archetype:energy trigger:fullauto
tier(s)      : T11 Black, TEX  (Zombieman)
chp source   : CHP/DECORATE/01/01_K.txt:53-64   TEX: CHP/DECORATE/01/01_KX.txt:122-136
acs          : none
fires        : 4 x A_CustomMissile("PlasmaBallSP3_C", 32, 0, random(-N,N)) with
               N = 5, 15, 25, 35 -- the cone OPENS as the burst goes on
damage       : PlasmaBallSP3_C Damage 5, DamageType "Plasma"
               (CHP/DECORATE/12/12_B.txt:1232-1240). See notes.
sprites      : ZOMK E/F alternating, F 3 BRIGHT on each bolt ; ZOMK GG 3 on cell eject
sounds       : SeeSound "weapons/plasmaf", DeathSound "weapons/plasmax" on the ball
behaviour    : Its medium-range answer, used inside 840 units. Four bolts over ~16
               tics, re-facing you between the first three, and each successive bolt is
               allowed to stray further -- so the first is aimed and the fourth is a
               spray. It ends on A_MonsterRefire(128,"CellEject"): while you are alive
               and visible it just goes round again, and only when it loses you does it
               stop to dump the spent cell on the floor (a real, pickup-able Cell).
               TEX bolts out of this burst twice -- 84/256 straight into the rocket
               barrage before firing at all, and 34/256 into the BFG between bolts 3
               and 4.
profile      : RS_AttackProfile.MakeVolley("RS_PlasmaBallSP3", 1, 0.0, "weapons/plasmaf",
                   1.0, 0.0, "Player 9 Plasma Spam")
               fired 4x from the state with arc 5/15/25/35
notes        : CHP BUG CANDIDATE -- PlasmaBallSP3_C is flat `Damage 5`
               (12/12_B.txt:1239) while its own sibling PlasmaBallSP3_B is
               `Damage (random(1,8)*random(7,8))` (12/12_B.txt:1270). Every other
               colour in that block is a flat constant too. Either the _B line is the
               outlier or the _C is; recorded, not resolved.
```

### Player 9 Chaingun Tap       zscript/monsters/Zombieman/attacks/RS_Zombieman_MarineChaingun.zs
```
kind         : tight chaingun taps at long range, with a rocket hidden in them
axes         : delivery:bullet payload:single element:kinetic
               archetype:chaingun trigger:fullauto
tier(s)      : T11 Black, TEX  (Zombieman)
chp source   : CHP/DECORATE/01/01_K.txt:70-77   TEX: CHP/DECORATE/01/01_KX.txt:142-151
acs          : none
fires        : A_CustomBulletAttack(5.6, 0, 1, 5, "BulletPuff_C")
               -- 1 bullet, 5.6 deg horizontal, ZERO vertical spread
damage       : 5 x random(1,3) -> 5..15 per tap (engine roll, see SSG entry)
sprites      : ZOMK E 2 / ZOMK F 2 BRIGHT / ZOMK E 2
behaviour    : What it does beyond 840 units. Six tics per tap, pinpoint vertically,
               and A_CPosRefire keeps it tapping as long as it can see you -- so at
               range this is a steady, accurate drizzle rather than a burst. Every tap
               carries a 32/256 chance of being a ROCKET instead (ActualRawk), so the
               drizzle is never safe to just walk through.
profile      : RS_AttackProfile.MakeHitscan("chaingun/fire", 0.10, 0, null, "Clip",
                   false, "Player 9 Chaingun Tap", "RS_BulletPuff")
notes        : CHP BUG -- two dead states after `Goto Missile`:
                 01_K.txt:76-77   `ZOMK A 0` / `Goto See`
                 01_KX.txt:150-151 `ZMKX A 0` / `Goto See`
               No label reaches them. Present in CH too
               (CH/decorate/Zombies.txt:1998-1999 and :1795-1796).
```

### Player 9 Rocket             zscript/monsters/Zombieman/attacks/RS_Zombieman_MarineRocket.zs
```
kind         : a single aimed rocket that arrives with the chaingun fire
axes         : delivery:heavy payload:explosive element:explosive
               archetype:launcher trigger:semi
tier(s)      : T11 Black, TEX  (Zombieman)
chp source   : CHP/DECORATE/01/01_K.txt:78-82   TEX: CHP/DECORATE/01/01_KX.txt:152-157
acs          : none
fires        : A_CustomMissile("Rocket_C", 32, 0, random(-1,1))
damage       : Rocket_C Damage 20 impact, Speed 20, then bare `A_Explode`
               (CHP/DECORATE/17/17_C.txt:965-989) -- GZDoom default 128 damage /
               128 units radius.
sprites      : MISL A 1 BRIGHT (flight) / MISL BCD (blast)
sounds       : SeeSound "weapons/rocklf", DeathSound "weapons/rocklx"
behaviour    : Fired one at a time out of the chaingun rhythm, with +-1 degree of
               scatter, i.e. effectively dead on. It is a FastProjectile in CHP, so it
               crosses the room noticeably faster than a vanilla rocket. On TEX it
               carries a 34/256 tail into the BFG.
profile      : RS_AttackProfile.MakeHeavy("RS_Rocket", "weapons/rocklf", 0, null, true,
                   32.0, 1.0, "Player 9 Rocket")
notes        : CHP's per-colour Rocket_* variants give explicit A_Explode(N,128) values
               (Green 160, Blue 192 -- 17/17_C.txt:1001, :1018) but _C leaves it bare,
               so the Common tier's rocket is the strongest-by-default. Probably not
               intended; recorded.
```

### Player X Rocket Barrage     zscript/monsters/Zombieman/attacks/RS_Zombieman_RocketBarrage.zs
```
kind         : strafing three-rocket barrage -- it dodges sideways then unloads
axes         : delivery:heavy payload:explosive element:explosive
               archetype:launcher trigger:burst
tier(s)      : TEX  (Zombieman)
chp source   : CHP/DECORATE/01/01_KX.txt:88-111  (RBarrage + AltBar)
               CH/decorate/Zombies.txt:1731-1756
acs          : none
fires        : back-hop, then 50/50 strafe right (RBarrage) or left (AltBar), then
               3 x A_CustomMissile("Rocket_C", 32, 0, random(-1,1)) at 4-tic spacing
damage       : 3 x (Rocket_C impact 20 + A_Explode default 128/128)
sprites      : ZMKX E (hops) / ZMKX F 4 BRIGHT x3 (launches)
sounds       : Rocket_C's own "weapons/rocklf" x3
behaviour    : The signature Player X move and the reason the duel feels like a duel.
               It hops UP and BACKWARD out of your line, then jukes hard left or right,
               and fires three rockets in twelve tics from wherever it landed. It is not
               a scripted set-piece -- it is reachable from FOUR places: after the
               shotgun reload (33 %), instead of a plasma burst (33 %), and, most
               importantly, OUT OF PAIN (01_KX.txt:161, 33 %). Hurt it and one time in
               three it answers by leaping aside and rocketing you.
profile      : RS_AttackProfile.MakeVolley("RS_Rocket", 3, 0.0, "weapons/rocklf", 1.0,
                   0.0, "Player X Rocket Barrage")
               -- the hops are movement, not payload; they stay in state code until
               rs_17 s4's WindupProfile exists.
notes        : thrustthingz takes Z thrust in quarter-units, so `thrustthingz(0,64,0,0)`
               is +16 units/tic of upward velocity. thrustthing(angle+-90,12,0,0) is
               12 units/tic laterally. CHP merged CH's two-state strafe into one
               3-tic state (01_KX.txt:94 vs CH:1737-1738) with identical timing.
```

### Player X BFG                zscript/monsters/Zombieman/attacks/RS_Zombieman_PlayerBFG.zs
```
kind         : a telegraphed BFG shot that bursts into a 29-shard cloud
axes         : delivery:heavy payload:cluster element:plasma
               archetype:bfg trigger:semi
tier(s)      : TEX  (Zombieman)
chp source   : CHP/DECORATE/01/01_KX.txt:112-121
               projectile CHP/DECORATE/01/01_KX.txt:3007-3035
               shards     CHP/DECORATE/01/01_KX.txt:3367-3384
acs          : none
fires        : 1 x PlayerEXBFG_C, spawn height 32, dead ahead
damage       : ball impact random(100,200) DamageType "Plasma"  (01_KX.txt:3013)
               blast     A_Explode(random(45,125), 156)         (01_KX.txt:3030)
               29 shards x random(20,80) each                   (01_KX.txt:3370)
sprites      : ZMKX E 1/1/10/8/6 (26-tic charge) / ZMKX F 4 BRIGHT (launch) / ZMKX E 12
               ball BFS1 AB (2t each, Add, Alpha 1.25)
               blast BFE1 AB 8 / BFE1 C 8 / BFE1 DEF 8, all BRIGHT
               shards BFS1 AB 2 BRIGHT, pulsing scale 0.55/0.75
sounds       : "weapons/bfgf" on the charge, DeathSound "weapons/bfgx" on the blast
behaviour    : Twenty-six tics of it standing still, glowing, tracking you -- the
               longest telegraph anything in this family has, and it is a mercy, because
               what lands is a BFG. On contact the ball quakes the room
               (Radius_Quake(15,15,0,40,0)), detonates for a rolled blast in a 156-unit
               radius, and sprays 29 independent plasma shards in every direction, each
               of which is itself a real projectile that fades out on a 2/256 per-tic
               timer. It is reachable from the shotgun reload, the plasma burst, the
               chaingun and the single rocket -- never as an opener.
profile      : RS_AttackProfile.MakeHeavy("RS_PlayerEXBFG", "weapons/bfgf", 0, null,
                   true, 32.0, 1.0, "Player X BFG", "RS_PlayerEXBFGBurst")
notes        : the ball trails TrailSPCguy_C (CHP/DECORATE/04/04_K.txt:2021) every
               2 tics -- itself a live FastProjectile with A_Explode(10,32) on death.
               The trail hurts. Do not port it as a decoration.
```

### Player X Gloat              zscript/monsters/Zombieman/attacks/RS_Zombieman_Gloat.zs
```
kind         : a taunt -- it stops fighting to laugh at a body
axes         : (none apply; this beat has no delivery and no payload -- see notes)
tier(s)      : TEX  (Zombieman)
chp source   : CHP/DECORATE/01/01_KX.txt:46-66, entered from 12 A_CheckFlag sites
               (:39, :77, :96, :98, :100, :106, :108, :110, :120, :134, :146, :155)
acs          : none
fires        : nothing
damage       : none
sprites      : ZMKX A / ZMKX G alternating, 4t x10, 3t x6, then GAG 4 / AGA 3 / GAG 2
sounds       : A_Playsound("HEHEEENH", 0) on 11 state lines -- 17 actual invocations,
               because the last three lines are 3-frame states and an action fires
               once per FRAME
behaviour    : Whenever its current target is a CORPSE, Player X drops out of whatever
               it was doing and spends 85 tics -- about two and a half seconds -- bobbing and
               laughing at the body. It fights other monsters, so this triggers
               constantly in a busy map, and it is the only time the fight pauses. If
               you are hiding, this is your window. It is also the single most
               characterful thing in the family: nothing else in Colourful Hell stops
               to celebrate.
profile      : no existing factory fits. Closest honest expression is
               RS_AttackProfile.MakeSelfBuff(1.0, 1.0, 85, false, "HEHEEENH",
                   "Player X Gloat") -- an 85-tic no-op self-buff -- which is a lie
               dressed as data. Recommend it stay a state until a "pose"/"idle beat"
               profile mode exists.
notes        : AXIS GAP, recorded not invented. There is no live `delivery:` value for
               a non-attack beat and no live `trait:` value for taunting. Per rs_21 s4
               the vocabulary gets extended in rs_17, not here.
               CH has the identical state on PLAY sprites
               (CH/decorate/Zombies.txt:1689-1709); CHP only reskinned it.
```

### Bone Shotgun                zscript/monsters/Zombieman/attacks/RS_Zombieman_BoneShotgun.zs
```
kind         : a shotgun blast of thrown bones, three grades of it
axes         : delivery:heavy payload:multi element:kinetic
               archetype:shotgun trigger:semi
tier(s)      : T12 White  (Zombieman)
chp source   : ShotBone  CHP/DECORATE/01/01_W.txt:79-84   (9 bolts, BoneProjZM_C)
               ShotBone2 CHP/DECORATE/01/01_W.txt:85-88   (12 bolts, BoneProjZM2_C)
               ShotBone3 CHP/DECORATE/01/01_W.txt:70-75   (11 bolts, BoneProjZM3_C)
acs          : none
fires        : N x A_CustomMissile(<grade>, random(32,42), random(-5,5), random(-12,12),
                   32, random(-3,3))
               -- spawn height, lateral offset, +-12 deg yaw, CMF_OFFSETPITCH, +-3 deg pitch
damage       : grade 1  BoneProjZM_C  random(4,16)  Speed 32
               grade 2  BoneProjZM2_C random(8,20)  Speed 36
               grade 3  BoneProjZM3_C random(12,26) Speed 40
               (CHP/DECORATE/01/01_W.txt:6585, :6873, :6983)
sprites      : MAGE E 8 (cast) / MAGE F 5-6 BRIGHT / MAGE E 5 (recover)
               bolts BBBN ABCD 4 ; impact MISL BCD 3 at scale 0.3
sounds       : bolt SeeSound "skelatt", DeathSound "swordhit"
behaviour    : Its mid-range answer. All N bones leave the staff in the SAME TIC -- the
               state is `MAGE FFFFFFFFF 0`, nine zero-tic frames -- so it is a true
               shotgun blast, a wall of femurs arriving together, not a stream. Each
               bone that dies has a 5/256 chance to stand a skeleton up where it landed
               (see Skeleton Seeding), so a missed volley across a corridor turns into
               a picket line of skeletons in front of you.
profile      : RS_AttackProfile.MakeVolley("RS_BoneProjZM", 9, 24.0, "skeleton/attack",
                   1.0, 6.0, "Bone Shotgun")
               grade 2: ("RS_BoneProjZM2", 12, 24.0, ...)   grade 3: ("RS_BoneProjZM3", 11, ...)
notes        : each bolt also carries DropItem "implyingclip",48 / "CH_Shell",32 /
               "CH_Cell",16 / "CH_RocketAmmo",8 (01_W.txt:6595-6598) -- the boss FEEDS
               YOU AMMO through its own missiles. That is a deliberate CH sustain valve
               and it is easy to drop as "cruft".
```

### Bone Stream                 zscript/monsters/Zombieman/attacks/RS_Zombieman_BoneStream.zs
```
kind         : a sustained bone drill -- two or three bones per tic, held on you
axes         : delivery:heavy payload:single element:kinetic
               archetype:chaingun trigger:fullauto
tier(s)      : T12 White  (Zombieman)
chp source   : RapidBone  CHP/DECORATE/01/01_W.txt:89-96   (2/tic, BoneProjZM_C)
               RapidBone2 CHP/DECORATE/01/01_W.txt:97-103  (2/tic, BoneProjZM2_C)
               RapidBone3 CHP/DECORATE/01/01_W.txt:64-69   (3/tic, BoneProjZM3_C)
acs          : none
fires        : `MAGE FF 1 Bright A_custommissile(...)` -- the action fires once per
               FRAME, so a 2-frame 1-tic state is 2 bones per tic. Grade 3 is FFF = 3.
               offsets random(34,40) height, +-2 lateral, +-5 deg yaw (grade 3: +-1/+-2)
damage       : same three grades as Bone Shotgun -- random(4,16) / random(8,20) / random(12,26)
sprites      : MAGE E 7 (cast) then MAGE F 1 BRIGHT looping
sounds       : "skelatt" per bolt
behaviour    : What it uses beyond 1250 units, and what FinalForm falls back to. It
               locks on and drills -- a continuous rope of bone, tighter than the
               shotgun and much longer-lasting, held by A_MonsterRefire(150 / 120) until
               it loses sight of you. Grades 1 and 2 carry a 12/256 per-cycle chance to
               break into the shotgun blast instead (01_W.txt:94, :101); grade 3 does not
               -- at final form the drill just keeps going.
profile      : RS_AttackProfile.MakeVolley("RS_BoneProjZM", 2, 10.0, "skeleton/attack",
                   1.0, 2.0, "Bone Stream")
               grade 3: ("RS_BoneProjZM3", 3, 4.0, ..., 1.0, 2.0, "Bone Drill")
notes        : the loop targets are `Goto RapidBone+2` / `RapidBone2+1` / `RapidBone3+1`
               -- each re-enters AFTER the A_FaceTarget, so the stream does not re-aim
               once it has started. Strafing out of it works. That is the counterplay
               and it exists only because of the +N offset.
```

### Shovel Fan                  zscript/monsters/Zombieman/attacks/RS_Zombieman_ShovelFan.zs
```
kind         : a three-blade spirit shovel swing that keeps shedding blades in flight
axes         : delivery:heavy payload:multi element:kinetic archetype:melee
tier(s)      : T12 White  (Zombieman)
chp source   : CHP/DECORATE/01/01_W.txt:104-112
               projectile CHP/DECORATE/01/01_W.txt:7091-7129
acs          : none
fires        : 3 x A_CustomMissile("ShoveZM_C", 38, 0/3/-3, 0/5/-5) -- centre, right, left
damage       : ShoveZM_C   random(10,45)  DamageType "Melee"  Speed 25  Scale 2   (01_W.txt:7095)
               ShoveZM2_C  random(1,5)    DamageType "Melee"  Speed 25  Scale 1.8 (01_W.txt:7599)
               ShoveZM3_C  random(3,12)   DamageType "Melee"  Speed 27  Scale 1.55(01_W.txt:7780)
               death blast A_Explode(random(5,20), 64) on 3 consecutive frames
               (CHP/DECORATE/01/01_W.txt:7125 -- `FBL1 EFG 1 bright A_Explode(...)`)
sprites      : MAGE E 7 / MAGE F 7 BRIGHT ; blades BLAD A ; impact 6PUF ABCDEF + FBL1 EFG
sounds       : A_Playsound("Spell/SpellCast1") on the swing;
               blade attacksound "skelsit4", DeathSound "moloch/nailhitbleed",
               impact "moloch/nailhit"
behaviour    : Its close-range attack, and the only thing it does inside 550 units --
               and note that Melee: and Missile: are THE SAME LABEL on this monster
               (01_W.txt:34-35), so the shovel IS its melee. Three huge spectral blades
               go out in a shallow fan, and each of those, as it travels, sheds a
               further twenty-seven smaller blades across twelve separate bursts -- some thrown
               FORWARD, some thrown BACKWARD at -180 and off-axis by +-6 pitch. Standing
               anywhere near the flight path hurts. Where the main blade lands it
               explodes three times in a 64-unit radius and, half the time, leaves a
               skeleton standing in the crater (failchance 128).
               After the swing it chains: at grade 2+ straight into the bone shotgun,
               otherwise a 128/256 roll back into Missile or into ShotBone.
profile      : RS_AttackProfile.MakeVolley("RS_ShoveZM", 3, 10.0, "Spell/SpellCast1",
                   1.0, 6.0, "Shovel Fan")
notes        : A_Explode on `FBL1 EFG 1` is THREE explosions, one per frame -- the known
               multi-frame A_Explode pattern (see MEMORY project_rs_multiframe_explode).
               Here it is almost certainly deliberate (a 3-tic lingering crater), so it
               belongs in the ~55 "do not convert" set.
```

### Bone Tornado                zscript/monsters/Zombieman/attacks/RS_Zombieman_BoneTornado.zs
```
kind         : a bone tornado -- a wandering floor-hugging vortex wearing a column of
               orbiting femurs
axes         : delivery:heavy payload:multi element:kinetic
               archetype:launcher trigger:semi
tier(s)      : T12 White  (Zombieman), FINAL FORM ONLY (user_skel1 == 4)
chp source   : CHP/DECORATE/01/01_W.txt:52-63   (the cast)
               CHP/DECORATE/01/01_W.txt:4268-4317 (BoneTorn2_C, the vortex)
               CHP/DECORATE/01/01_W.txt:5080-5107 + :5410, :5605, :5800, :5995, :6190,
                   :6385 (BoneStormer1_C .. 7_C, the orbiters)
acs          : none
fires        : 1 x A_CustomMissile("BoneTorn2_C", 4, 0, random(-64,64))
               -- spawn height 4 (ground level), +-64 degrees of aim. It is NOT aimed
               at you; it is thrown roughly your way and then wanders.
damage       : each orbiting BoneStormer random(1,3), +RIPPER +FORCEPAIN, Speed 105-155
               each spat BoneProjZM3_C random(12,26)
               the vortex itself does no contact damage (+THRUACTORS, +invisible)
sprites      : cast MAGE E x6 alternating BRIGHT (35 tics of wind-up) / MAGE F 5 BRIGHT
               vortex RNGG A B (wander) / RNGG C D (the spawn frames)
               orbiters BBBN A/B/C/D 1 BRIGHT
sounds       : A_Playsound("Under/Goodie", 7, 2, false, ATTN_NONE) at the start of the
               cast -- channel 7, volume 2, NO ATTENUATION, i.e. audible map-wide;
               vortex SeeSound "Fire/fire3"; orbiter DeathSound "Ice/Fly"
behaviour    : The Undertaker's final-form set piece and the single most complicated
               thing in family 01. Thirty-five tics of visible charging, then it lobs an
               INVISIBLE floor-hugging bouncer that wanders the room on its own
               (A_Wander), bounces off walls at 1.1x, and cannot be shot or blocked
               (+THRUACTORS, +DONTBLAST, +DONTTHRUST, BounceCount 999). What you see is
               its dressing: it spawns seven distinct orbiting bone types, over and over,
               on 32 separate spawn lines per loop -- radii 12/28/32/44/56/68/80 at
               heights 10/28/32/64/88/102/128, speeds 105 to 155 -- and each of them
               A_Warps to the vortex every tic while advancing its own angle by 8
               degrees. The result is a rotating COLUMN of ripping bones, wide at the
               bottom, tall and fast at the top, dragging itself around the arena. Four
               times per loop it also spits a full-damage grade-3 bone bolt outward.
               The whole thing self-terminates on an 8/256 roll at the end of each loop.
profile      : RS_AttackProfile.MakeHeavy("RS_BoneTorn2", "Under/Goodie", 0, null, true,
                   4.0, 1.0, "Bone Tornado")
               -- the orbiters are the projectile's own business, not the profile's.
notes        : CHP BUG (inherited from CH). Every bone-spit line reads
                 A_CustomMissile("BoneProjZM3_C", 4, random(-20,20), CMF_AIMOFFSET,
                                 random(0,360), random(0,360))
               (01_W.txt:4281, :4291, :4305, :4314 ; CH/decorate/Zombies.txt:2507, :2517,
               :2531, :2540). A_CustomMissile's signature is
               (type, spawnheight, spawnofs_xy, ANGLE, FLAGS, PITCH), so this passes
               CMF_AIMOFFSET (= 1) as the ANGLE -- one degree -- and a random(0,360) as
               the FLAGS bitfield, which lights up an arbitrary mix of CMF_AIMOFFSET /
               AIMDIRECTION / TRACKOWNER / CHECKTARGETDEAD / ABSOLUTEPITCH / OFFSETPITCH /
               SAVEPITCH / ABSOLUTEANGLE every single call. The arguments are transposed;
               the author almost certainly meant angle=random(0,360), flags=CMF_AIMOFFSET.
               It "works" chaotically, which is presumably why it survived. A faithful
               port should reproduce the INTENT (random outward angle) and record this.
```

### Skeleton Seeding            zscript/monsters/Zombieman/attacks/RS_Zombieman_SkeletonSeed.zs
```
kind         : it plants skeletons -- from its own missed shots, and from every corpse
               on the map
axes         : delivery:heavy payload:single element:kinetic
               (there is no live `delivery:summon`; role:summoner is the monster-level
               statement -- see notes)
tier(s)      : T12 White  (Zombieman)
chp source   : from bone bolts  CHP/DECORATE/01/01_W.txt:6608
                   `MISL D 0 A_Spawnitemex("MrBones_C",0,0,6,...,250)`
               from the shovel  CHP/DECORATE/01/01_W.txt:7126  (failchance 128)
               from any corpse  CHP/DECORATE/01/01_W.txt:18 + :8930-8962
               the skeleton     CHP/DECORATE/01/01_W.txt:2980-3060
acs          : "CH_WZPlan" -- CHP/source/CHSett2.acs:74-77. Body is
                   `SetResultValue(GetCVar("CH_WZPlan"));`
               1 = always seed, 2 = 85/256 (~33 %) per corpse, 3 = never.
               Pure CVar read; rebuild as an RS option, not as a script.
fires        : MrBones_C -- Health 50, Speed 12, Radius 16, PainChance 180,
               Species "UnderTaker", +NOCLIP (toggled), -COUNTKILL, +DONTDRAIN
damage       : MrBones melee A_CustomMeleeAttack(random(1,6)*4, "swordhit", none)
               -- 4..24. KEEP THE ROLL: random(1,6)*4, never 14.
sprites      : SKLT A-R (full monster set), death SKLT M N O P Q, gibs BBBN via
               BoneGibWhite_C
sounds       : seesound "skelsit", painsound "skelpai", deathsound "skeldth",
               attack "skelatt", hit "swordhit"
behaviour    : Every bone bolt that dies has a 5/256 chance and every shovel blade a
               50 % chance of leaving a skeleton standing where it hit -- and while an
               Undertaker is alive, so does ANY monster that dies anywhere on the map
               (see s C.5). They are slow, weak, and do not count toward the kill
               percentage, and they will unstick themselves (a_checkblock -> noclip ->
               A_Wander -> give up after 12 strikes). They can also self-resurrect
               twice, and on the third raise a skeleton becomes a full REVENANT
               (01_W.txt:3057, `A_Spawnitemex("CommonCommonRevenant",...)`).
               The trap is that killing them is how the Undertaker levels up: each
               death A_Radiusgives it random(12,128) health and one BoneUp.
profile      : RS_AttackProfile.MakeSummon("RS_MrBones", 1, 8, -2, "ice/Cast",
                   "Skeleton Seeding")
               -- but the real mechanism is a spawn-on-projectile-death with a
               failchance, not a summon beat. Both should exist.
notes        : AXIS GAP, recorded not invented -- `delivery:summon` is RESERVED, not
               live (zscript/systems/RS_MonsterKeywordIndex.zs:71-75), and the index
               explicitly argues against adding it. The monster-level `role:summoner`
               is the correct place to say this.
               A_SpawnItemEx's last-but-one argument is a FAILCHANCE out of 255, so 250
               means ~2 % spawn, 128 means ~50 %, and 255 (used on the letter drops)
               means ~0.4 %. Getting this backwards would carpet the map in skeletons.
```

---

## §G — REFERENCED ACTOR INDEX (file:line for every one)

### Used by T10
| actor | defined at | what it is |
|---|---|---|
| `BloodyPuff_C` | `CHP/DECORATE/01/01_R.txt:1602` (empty override of `BloodyPuff`, `CH/decorate/Zombies.txt:1553`) | bullet puff, `DBLD ABCD 4` |
| `HKRedDeath_C` | `CHP/DECORATE/11/11_R.txt:3641` | XDeath fireball: `A_Explode(random(5,10),42)` + `A_Burst("REDTHINGSHK_C")` |
| `WhiteZombiePlan_C` | `CHP/DECORATE/01/01_W.txt:8930` | the corpse-seed (see §C.5) |
| `CHWhitePlan` | `CHP/DECORATE/01/01_W.txt:9430` | `Inventory`, MaxAmount 1 |
| `RandomLetterSpawner_C` | `CHP/DECORATE/MISC/letters.txt:1` | `Randomspawner` over `LetterA_C`..`LetterZ_C` |
| `NewIconCHP6_T1_C` | CHP tier-icon set (cosmetic HUD marker) | not needed for RS |
| `GoAway` | `CHP/DECORATE.txt:1` | `Inventory` MaxAmount 1, the "despawn your children" token |

### Used by T11 and TEX
| actor | defined at | what it is |
|---|---|---|
| `BulletPuff_C` | `CHP/DECORATE/01/01_C.txt:1173` (empty override of vanilla `BulletPuff`) | |
| `PlasmaBallSP3_C` | `CHP/DECORATE/12/12_B.txt:1232` | FastProjectile, Speed 25, `Damage 5`, DamageType Plasma, `PLSS AB 6` / `PLSE ABCDE 4` |
| `Rocket_C` | `CHP/DECORATE/17/17_C.txt:965` | FastProjectile, Speed 20, Damage 20, bare `A_Explode` |
| `ShotgunWhere` | `CH/decorate/Zombies.txt:2025` | `Inventory` MaxAmount 1 — the one-shell token |
| `Shell` / `Cell` | vanilla ammo | ejected as real pickups |
| `CHRandom_GibGenerator` | `CH/Gibs.txt:3` | XDeath gib spray |
| `PlayerEXBFG_C` | `CHP/DECORATE/01/01_KX.txt:3007` | TEX only |
| `PlayerEXBFG2_C` | `CHP/DECORATE/01/01_KX.txt:3367-3384` | the 29 shards |
| `TrailSPCguy_C` | `CHP/DECORATE/04/04_K.txt:2021` | BFG trail — a live projectile, `A_explode(10,32)` on death |
| `NewIconCHP10_T1_C`, `NewIconCHP30_T1_C` | CHP tier-icon set | cosmetic |

### Used by T12 — the bone kit
| actor | CHP `_C` variant | CH parent | notes |
|---|---|---|---|
| `MrBones_C` | `01_W.txt:2980-3060` | `MrBones` `CH/decorate/Zombies.txt:2114` | the skeleton; feeds the ladder on death |
| `BoneTorn2_C` | `01_W.txt:4268-4317` | `BoneTorn2` `CH/decorate/Zombies.txt:2475` | the vortex |
| `BoneStormer1_C` | `01_W.txt:5080-5107` | `BoneStormer1` `:2549` | orbit r32 h32, Speed 120, `A_Jump(8,"Death")` |
| `BoneStormer2_C` | `01_W.txt:5410` | `:2579` | r28 h28, Speed 105, `A_Jump(4)` |
| `BoneStormer3_C` | `01_W.txt:5605` | `:2592` | r12 h10, Speed 115 |
| `BoneStormer4_C` | `01_W.txt:5800` | `:2605` | r44 h64, Speed 130 |
| `BoneStormer5_C` | `01_W.txt:5995` | `:2618` | r56 h88, Speed 125 |
| `BoneStormer6_C` | `01_W.txt:6190` | `:2631` | r68 h102, Speed 130 |
| `BoneStormer7_C` | `01_W.txt:6385` | `:2644` | r80 h128, Speed 155 |
| `BoneProjZM_C` | `01_W.txt:6580-6611` | `:2657` | `Damage (random(4,16))` Speed 32, drops ammo, seeds skeletons |
| `BoneProjZM2_C` | `01_W.txt:6871-6876` | `:2690` | `Damage (random(8,20))` Speed 36 |
| `BoneProjZM3_C` | `01_W.txt:6981-6986` | `:2696` | `Damage (random(12,26))` Speed 40 |
| `ShoveZM_C` | `01_W.txt:7091-7129` | `:2702` | `damage (random(10,45))`, sheds 18 sub-blades |
| `ShoveZM2_C` | `01_W.txt:7595-7624` | `:2742` | `damage (random(1,5))` |
| `ShoveZM3_C` | `01_W.txt:7777-7795` | `:2770` | `damage (random(3,12))` Speed 27 |
| `BoneGibWhite_C` | `01_W.txt:8064-8084` | `BoneGibWhite` `:2082` | bouncing gib |
| `BoneUp` | — | `CH/decorate/Zombies.txt:2219` | `Inventory` MaxAmount 30 — the ladder counter |
| `BoneUp2_C` | `01_W.txt:8399-8412` | `BoneUp2` `:2221` | CustomInventory, autoactivate; spawns `SpirZom_C` |
| `SpirZom_C` | `01_W.txt:8609-8623` | `SpirZom` `:2236` | soul wisp that A_Warps to its master |
| `SpirZom2_C` | `01_W.txt:8852-8855` (empty override) | `SpirZom2` `:2260` | wisp particles, `HUWZ A` |
| `WhiteZombiePlan_C` | `01_W.txt:8930-8962` | `ThePlanBoner` `:2046` | CHP adds the `CH_WZPlan` CVar gate |
| `CH_BoneGib_C` | `CHP/DECORATE/08/08_C.txt:1732` | `CH_BoneGib` `CH/Gibs.txt:162` | T12 xdeath bone shower |
| `HomingRocketTrailFatso_C` | `CHP/DECORATE/13/13_Y.txt:2031` | | T12 xdeath smoke |
| `CommonCommonRevenant` | family 08 | | what a skeleton becomes on its 3rd raise |

**CHP's 15-way replication.** Of `01_W.txt`'s 316 actors, 15 are the monster and the
other 301 are these 20 support classes duplicated once per spawn colour. Every colour
copy differs only in `Speed`, `Damage`, `Translation` and per-colour sound suffixes.
This is exactly the data axis rs_21 §1 says to defer.

---

## §H — PHASE / ESCALATION SUMMARY

| tier | phase system | driver | one-shot? |
|---|---|---|---|
| T10 | none | — | — |
| T11 | none. `ShotgunWhere` is a one-shell ammo token, not a phase | inventory token, `CH/decorate/Zombies.txt:2025` | resets every reload |
| T12 | **4-rung ladder**, §C.3 | `BoneUp` inventory count (5/9/12) + `user_skel1` actor user-var. **No ACS.** | yes per rung, guarded by `A_JumpIf(user_skel1>=N,"Reset")` |
| T12 | **map-wide skeleton seeding** ("The Plan"), §C.5 | `CHWhitePlan` inventory token given by `A_Radiusgive` at spawn; gated by the **`CH_WZPlan` CVar** via ACS | permanent while the Undertaker lives |
| TEX | none — but the `Jammed` reload and `Pain` both roll into the barrage/BFG, which reads as escalation without being state | `A_jump` only | not persistent |
| TEX | **gloat interrupt**, §D.3 | `A_CheckFlag("CORPSE", …, AAPTR_TARGET)` — target state, not a token | re-arms every time the target is a corpse |

Nothing in these four tiers uses an ACS script to *drive* behaviour. The three ACS calls
are announcements and a CVar read (§I).

---

## §I — ACS REGISTER (every script these tiers call, opened and read)

| called from | script | file:line | body | verdict |
|---|---|---|---|---|
| T11 `01_K.txt:17`, TEX `01_KX.txt:22` | `AnnounceBlackZombie_C` | `CHP/source/Bosses.acs:635-640` | `SetFont("smallfont"); SetHudSize(640,480,0); Hudmessagebold(s:"\c[ColorC]Player 9 joined the server (black zombie spawned)\c-\c-"; HUDMSG_FADEINOUT|HUDMSG_LOG|HUDMSG_COLORSTRING, 613, "ColorC", 320.4, 160.0, 3.5, 1.0);` | cosmetic — HUD text only |
| TEX `01_KX.txt:23` | `EXBOSS` | `CHP/source/Bosses.acs:4331-4337` | `SetFont("smallfont"); SetHudSize(480,360,0); Hudmessagebold(s:"A chill runs down your spine..."; HUDMSG_TYPEON, 13, CR_GRAY, 240.4, 35.0, 3.5); Radius_quake(1,35,0,1200,0);` | **not purely cosmetic** — the `Radius_quake(1,35,0,1200,0)` is a real 35-tic screen shake over 1200 units. Rebuild it. |
| T12 `01_W.txt:17` | `AnnounceWhiteZombie_C` | `CHP/source/Bosses.acs:2420-2425` | `Hudmessagebold(s:"\c[ColorC]Are you ready to roll some bones?\c-"; …, 2313, "ColorC", 320.4, 152.0, 3.5, 1.0);` | cosmetic |
| `WhiteZombiePlan_C` `01_W.txt:8939-8941` | `CH_WZPlan` | `CHP/source/CHSett2.acs:74-77` | `Script "CH_WZPlan" (void) { SetResultValue(GetCVar("CH_WZPlan")); }` | a CVar read. Rebuild as an RS option/CVar, not as a script. |
| (spawn-chain, above these tiers) | `CH_BlackBossy` | `CHP/source/CHSett2.acs:187-190` | `SetResultValue(GetCVar("CH_BlackBoss"));` | CVar read |
| (spawn-chain) | `CH_WhiteBossy` | `CHP/source/CHSett2.acs:217-220` | `SetResultValue(GetCVar("CH_WhiteBoss"));` | CVar read |
| (spawn-chain) | `CH_ExBoss` | `CHP/source/CHSett2.acs:222-225` | `SetResultValue(GetCVar("CH_EXBoss"));` | CVar read — this is what decides whether a Black Zombie is Player 9 or Player X (`CH/decorate/Zombies.txt:1580-1598`: `==1` → 232/256 chance to stay Player 9; `==2` → 128/256; `==3` → always Player X) |

CH fallbacks, for the record: `CH/source/Announcers.acs:277` (`AnnounceBlackZombie`),
`CH/source/Announcers.acs:85` (`AnnounceWhiteZombie`), `CH/source/CHSett.acs:34`
(`CH_BlackBossy`). CHP's `_C` variants supersede them.

---

## §J — THINGS THAT LOOK LIKE CHP BUGS (quoted, not fixed)

### J.1 The bone-tornado's transposed `A_CustomMissile` arguments
`CHP/DECORATE/01/01_W.txt:4281` (and `:4291`, `:4305`, `:4314`; also CH at
`CH/decorate/Zombies.txt:2507`, `:2517`, `:2531`, `:2540`):

```
RNGG CCDD 1 Bright A_CustomMissile("BoneProjZM3_C",4,random(-20,20),CMF_AIMOFFSET,random(0,360),random(0,360))
```

`A_CustomMissile(type, spawnheight, spawnofs_xy, angle, flags, pitch)`. As written the
**angle is `CMF_AIMOFFSET`, i.e. 1 degree**, and the **flags are `random(0,360)`** — a
different arbitrary bitmask every call. Almost certainly meant to be
`…, random(0,360), CMF_AIMOFFSET, random(0,360))`.

### J.2 T12's buff icon respawns forever
`CHP/DECORATE/01/01_W.txt:116-119`:

```
Buff1:
    MAGE A 0 A_GivetoChildren("GoAway",1)
    MAGE A 0 A_SpawnitemEx("NewIconCHP11_T2_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
    MAGE A 0 A_JumpIf(user_skel1>=2,"Reset")
```

CH puts the guard FIRST (`CH/decorate/Zombies.txt:2434`). CHP put two side effects
*before* it, and `See` re-enters `Buff1` every chase loop once `BoneUp >= 5`. So from
rung 1 onward the Undertaker spawns a fresh HUD icon and re-issues `GoAway` to its
children **every time it takes a step**. Same pattern at `:127-130` and `:137-140`.
This is CHP-introduced; CH does not have it.

### J.3 The ladder's `==` gates can be skipped
`user_skel1` is compared with exact equality at `01_W.txt:36` (`==4`), `:81`, `:90`,
`:110` (`==3`), while `Buff1` adds **2** (`:123`) and Buff2/Buff3 add 1 each. The
sequence only reaches 2→3→4 if every rung fires in order. `See` tests the
*highest* threshold first (`:24` BoneUp≥12 → Buff3), so a monster that gained several
`BoneUp` in one frame — two skeletons dying in the same tic inside 528 units is not
exotic — lands in `Buff3` with `user_skel1 == 0`, sets it to **1**, and then never
matches `==3` or `==4` again. It would be permanently stuck below grade 2 while holding
`+NOPAIN` and Speed 28. Present in CH too (`CH/decorate/Zombies.txt:2338-2340`,
`:2434`, `:2443`, `:2451`).

### J.4 Dead states after `Goto`
`01_K.txt:76-77` and `01_KX.txt:150-151`:

```
    Goto Missile
    ZMKX A 0                <- no label reaches this
    Goto See
```
Also in CH (`CH/decorate/Zombies.txt:1795-1796`, `:1998-1999`).

### J.5 `A_Jump(256, …)` makes every following `GoTo See` dead
`01_K.txt:37-38`, `01_KX.txt:44-45`, `01_W.txt:39-40`, `:44-45`, `:47-48`, `:50-51`,
`:77-78`. CHP raised CH's `A_Jump(255,…)` to 256, which turns a 255/256 chance into a
certainty and orphans the fallthrough. Harmless, but it means those `GoTo See` lines
are not a real "no valid attack" path — there isn't one.

### J.6 `DamageFactor "Falling"` declared twice
`CH/decorate/Zombies.txt:1620-1621` — `DamageFactor "Falling",0.0` then
`DamageFactor Falling,0.0`. Redundant, harmless.

### J.7 `PlasmaBallSP3_C` is flat while a sibling is a roll
`CHP/DECORATE/12/12_B.txt:1239` — `Damage 5`, vs `PlasmaBallSP3_B` at `:1270` —
`Damage (random(1,8)*random(7,8))`. Every other colour in that block is flat. One of
the two is wrong; can't tell which from the source alone.

### J.8 `Rocket_C` leaves `A_Explode` bare while its colour siblings don't
`CHP/DECORATE/17/17_C.txt:984` — `MISL B 8 Bright A_Explode` (engine default 128/128).
`Rocket_G` at `:1001` uses `A_Explode(160,128)`, `Rocket_B` at `:1018`
`A_Explode(192,128)`. So the *Common* rocket has 128 blast damage and the *Green* one
160 — the ladder holds, but only by accident of the default.

---

## §K — WHERE I DISAGREE WITH THE CURRENT `E:\RS_Main` TREE

Documentation only — nothing was edited. These are the concrete gaps I found while
holding CHP open next to `zscript/monsters/RS_Zombieman.zs` and
`zscript/monsters/monsterfx/RS_human_projectiles.zs`.

**K.1 — Every bone/shovel damage roll has been flattened, and the file says so out loud.**
`zscript/monsters/monsterfx/RS_human_projectiles.zs:210` —
`// "no RS_ port -> add it here" rule. Damage -> constants, house style.`
That "house style" is the exact thing `CLAUDE.md` forbids, and no `// CH:` note records
what was lost:

| RS | line | CHP source |
|---|---|---|
| `RS_BoneProjZM  Damage 10` | `RS_human_projectiles.zs:218` | `random(4,16)` — `01_W.txt:6585` |
| `RS_BoneProjZM2 Damage 14` | `:231` | `random(8,20)` — `01_W.txt:6873` |
| `RS_BoneProjZM3 Damage 19` | `:232` | `random(12,26)` — `01_W.txt:6983` |
| `RS_ShoveZM     Damage 20` | `:253` | `random(10,45)` — `01_W.txt:7095` |
| `RS_ShoveZM2    Damage 3`  | `:238` | `random(1,5)`  — `01_W.txt:7599` |
| `RS_ShoveZM3    Damage 7`  | `:250` | `random(3,12)` — `01_W.txt:7780` |
| `RS_BoneStormer Damage 2`  | `:288` | `random(1,3)`  — `01_W.txt:5085` |

All seven should be `DamageFunction (random(a,b))`.

**K.2 — The Undertaker's ladder has no feed.**
CHP: `BoneUp` comes from `MrBones_C` dying (`01_W.txt:3029`).
RS: `RS_ClimbLadder()` is called from exactly one place —
`zscript/monsters/RS_Zombieman.zs:277`, inside `Pain:`. So in RS the Undertaker levels
up by *being shot*, which is a different monster. `RS_MrBones` exists
(`zscript/monsters/monsterfx/RS_rev_projectiles.zs:733`) and is spawned by the Archvile,
the Revenant and `RS_MonsterStages` — but **never by the Zombieman**. `RS_BoneProjZM`'s
Death state (`RS_human_projectiles.zs:225-228`) has no skeleton spawn; CHP's has one at
5/256 (`01_W.txt:6608`). `RS_ShoveZM`'s Death (`:266-270`) has none; CHP's is 50 %
(`01_W.txt:7126`). The whole "kill the skeletons and you empower the boss" loop is
absent.

**K.3 — The buff magnitudes are multiplicative where CHP's are absolute.**
`RS_Zombieman.zs:170-203` (`RS_ClimbLadder`) does `Speed *= 1.3` / `*= 1.25` / `*= 1.2` from base 10, i.e.
13 → 16.25 → 19.5, and `A_SetScale(Scale.X * 1.08 / 1.10 / 1.12)`.
CHP does `A_Setspeed(16)` / `(21)` / `(28)` and `A_SetScale(1.1,1.1)` / `(1.25,1.25)` /
`(1.45,1.45)` — absolute (`01_W.txt:124-125, 134-135, 145-147`). Final-form CHP is
**Speed 28 at scale 1.45**; RS's is Speed 19.5 at ~1.32. Roughly a third slower.

**K.4 — Player X's taunt is silent.**
`RS_Zombieman.zs:1111-1131` reproduces all 19 state lines of the gloat with the correct
sprites and tics but **drops every `A_Playsound("HEHEEENH",0)`** (CHP `01_KX.txt:48-65`,
11 state lines / 17 invocations). The gloat is a *sound* gag; without the laugh it is the
monster standing still for three seconds for no visible reason.

**K.5 — The bone tornado is a tenth of its CHP self.**
`RS_BoneTorn2` (`RS_human_projectiles.zs:310-331`) has **3** stormer spawn lines and
2 bone spits per loop; CHP's `BoneTorn2_C` (`01_W.txt:4274-4315`) has **32** stormer
spawns and 4 spits. `RS_BoneStormer` (`:276-306`) collapses CHP's seven distinct
orbiters into one class with `frandom(12,80)` radius / `frandom(10,128)` height /
Speed 120 fixed — so the shaped column (narrow-and-slow at the bottom, wide-and-fast at
the top, seven discrete rings) becomes an even random cloud. CHP's speeds are
120/105/115/130/125/130/155.

**K.6 — a fix I'd keep.** `RS_Zombieman.zs:957, 1003, 1012, 1034` use `rsStep >= N`
where CHP uses `user_skel1 == N`. That is strictly better (see §J.3) — but it is a
deviation, and rs_21 §2 says deviations get recorded at the site with the source
quoted. Right now the header comment at `RS_Zombieman.zs:54-57` documents the mapping
but not that `==` became `>=` or why.

**K.7 — `RS_ShoveZM`'s explosion.** `RS_human_projectiles.zs:269` is a single
`A_Explode(12, 64)`; CHP is `FBL1 EFG 1 bright A_Explode(random(5,20),64)` —
**three** explosions with a roll (`01_W.txt:7125`). This is a member of the
"deliberate multi-frame A_Explode" set, not the accidental one.

**K.8 — the keyword index disagrees with the code it documents.**
`zscript/systems/RS_MonsterKeywordIndex.zs:91` lists `element:void` as RESERVED, but
`RS_Archvile.zs`, `RS_Baron.zs` and `RS_Cyberdemon.zs` all return it from
`GetBaseKeywords()` today. Not this family's problem, but it means the index's
REAL/RESERVED split cannot be trusted as-is when picking `axes` values.

---

## §L — COMPLETION AGAINST rs_21 §2 FOR THESE FOUR TIERS

| test | T10 | T11 | T12 | TEX |
|---|---|---|---|---|
| every state transcribed | yes (9 states) | yes (13) | yes (24) | yes (20) |
| sprite tokens frame-for-frame | yes | yes | yes | yes |
| tic counts | yes | yes | yes | yes |
| actions + all arguments | yes | yes | yes | yes |
| every property incl. inherited | yes | yes | yes | yes |
| every ACS script opened + quoted | n/a (none) | yes (1) | yes (2) | yes (2) |
| every projectile/summon/effect located | yes (7) | yes (10) | yes (23) | yes (13) |
| catalog entry per attack | 2 | 5 | 5 | 8 (5 shared with T11, 3 own) |
| RS_AttackProfile call written | yes | yes | yes | yes, except the Gloat (§F, axis gap) |

Not covered by this document, deliberately: the 14 non-`Common` spawn colours per tier
(rs_21 §1 defers them to a TintTable), and the `_G`/`_B`/`_P`/… copies of the 20 bone
support classes.
