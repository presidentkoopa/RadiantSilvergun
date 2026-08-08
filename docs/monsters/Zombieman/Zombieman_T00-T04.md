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

# Zombieman (family 01) — DEEP READ, T00–T04

Deliverable for the rs_21 port. **Documentation only. No .zs/.zsc was written or
edited; nothing was staged or committed.**

Scope: tiers T00 (C), T01 (G), T02 (B), T03 (CY), T04 (P) of family 01, read as
the `Common<Colour>Zombie` actor per rs_21 §1 ("OUR TIER MAPS TO CHP'S
`Common<Colour><Family>` ACTOR", `docs/rs_21_port_law.txt:51`).

Every claim below carries FILE:LINE. Paths are relative to
`E:\New folder\ART SOURCE\` unless they start with `E:\RS_Main`.

---

## 0. METHOD, AND THE ONE THING WORTH KNOWING FIRST

CHP does **not** redefine `CommonZombie`, `GreenZombie`, `BlueZombie`,
`CyanZombie2` or `PurpleZombie` anywhere — verified by
`grep -rinE "^\s*(ACTOR|Actor|actor)\s+(CommonZombie|GreenZombie|BlueZombie|CyanZombie2|PurpleZombie)\b" CHP/`
returning **nothing**. So for these five tiers the parent bodies are CH's, in
`CH/decorate/Zombies.txt`, and CHP is a pure subclass patch on top. Everything a
CHP actor does not redeclare comes from those CH parents (and, for four of the
five, from GZDoom's built-in `Zombieman` beneath that — `Actor Zombieman` is
defined in **neither** CH nor CHP; the same grep over `Zombieman` returns
nothing).

CHP naming decoded, from evidence rather than the name:
`<SubVariant><Tier>Zombie`. `CommonCommonZombie` Grows into `CommonGreenZombie`
(`CHP/DECORATE/01/01_C.txt:60`), which lives in `01_G.txt`; `GreenCommonZombie`
Grows into `GreenGreenZombie` (`01_C.txt:137`). First word = spawn-colour
sub-variant, second word = tier. So `Common<Tier>Zombie` is the "no extra tint"
sub-variant of each tier — exactly what rs_21 asks for.

Corroboration from our own tree: `E:\RS_Main\zscript\monsters\RS_Zombieman.zs:143`
already maps `T00..T04 = POSS ZOMG ZOMB CYNT BPOS`, which is frame-for-frame the
sprite token each of the five CHP actors below actually uses. That mapping is
correct.

| our tier | CHP file | CHP actor | parent | line |
|---|---|---|---|---|
| T00 | `CHP/DECORATE/01/01_C.txt`  | `CommonCommonZombie` | `CommonZombie` (`CH/decorate/Zombies.txt:788`) | 1–74 |
| T01 | `CHP/DECORATE/01/01_G.txt`  | `CommonGreenZombie`  | `GreenZombie` (`CH/decorate/Zombies.txt:870`) | 1–87 |
| T02 | `CHP/DECORATE/01/01_B.txt`  | `CommonBlueZombie`   | `BlueZombie` (`CH/decorate/Zombies.txt:1013`) | 1–78 |
| T03 | `CHP/DECORATE/01/01_CY.txt` | `CommonCyanZombie`   | `CyanZombie2` (`CH/decorate/Zombies.txt:245`) | 1–59 |
| T04 | `CHP/DECORATE/01/01_P.txt`  | `CommonPurpleZombie` | `PurpleZombie` (`CH/decorate/Zombies.txt:1125`) | 1–82 |

### DISAGREEMENT WITH rs_21 ON TIER ORDER — stated, not softened

rs_21 orders `C=T00 G=T01 B=T02 CY=T03 P=T04`
(`E:\RS_Main\docs\rs_21_port_law.txt:42`). CHP's own data disagrees twice:

1. **CHP's spawner index** is `Common 0, Green 1, Blue 2, Purple 3, Yellow 4,
   Red 5, Black 6, White 7, BlackEX 8, WhiteEX 9, Abyss 10, Brown 11, **Cyan
   12**, Fireblu 13, Gray 14` —
   `CHP/zscript/customspawners.zsc:572-586`. Cyan is index 12, not 3.
2. **CHP's Grow ladder skips Cyan entirely.** `CommonBlueZombie` Grows into
   `CommonPurpleZombie` (`01_B.txt:64`), not into a Cyan. Nothing anywhere in
   `CHP/DECORATE/01/*.txt` Grows *into* a Cyan zombie —
   `grep -n 'Spawnitemex("[A-Za-z]*CyanZombie"' CHP/DECORATE/01/*.txt` returns
   **zero hits** — and `CommonCyanZombie` has no `Grow` state of its own and no
   `Raise` state to reach one.

Cyan is a **side branch**, gated on its own CVar (`CH_Cyan`,
`CH/CVARINFO.txt:12`), not a rung on the ladder. Placing it at T03 between Blue
and Purple is a deliberate RS choice, which is fine — but it must be a *known*
choice, because it means T03 is the only tier in this range that cannot be
resurrected, cannot Grow, and cannot be gibbed (see §4). I am not asking for the
order to change; I am recording that "T02 → T03 → T04" is our invention, and no
CHP behaviour connects them.

---

# 1. T00 — `CommonCommonZombie` (`CHP/DECORATE/01/01_C.txt:1-74`)

## 1.1 Properties

**Declared by CHP** (`01_C.txt`):

| property | value | line |
|---|---|---|
| Health | `20` | 3 |
| Speed | `7` | 4 |
| PainChance | `200` | 5 |
| SeeSound | `"grunt/sight"` | 6 |
| AttackSound | `"grunt/attack"` | 7 |
| PainSound | `"grunt/pain"` | 8 |
| DeathSound | `"grunt/death"` | 9 |
| ActiveSound | `"grunt/active"` | 10 |
| Obituary | `"%o was somehow killed by \c[ColorC]Common Zombie\c-"` | 11 |
| Tag | `"\c[ColorC]Zombieman\c-"` | 12 |

**Inherited from `CommonZombie`** (`CH/decorate/Zombies.txt:788-868`):
`Game Doom` (790), `Speed 7` (791, re-stated by CHP), `Species "Zombie"` (792),
`DamageFactor "Exorcist",3.0` (793), `DamageFactor "DIMp",0` (794),
`PainChance "DIMp",0` (795), `Monster` (796), `+AVOIDMELEE` (797),
`DropItem "implyingclip"` (799).
Its `Obituary` (798) and `tag` (800) are overridden by CHP.

**Not set anywhere in the chain** (verified by grep over both the CHP actor and
the CH parent block): `Radius`, `Height`, `Mass`, `Scale`, `MeleeRange`,
`MeleeDamage`, `Translation`, `BloodColor`, `HitObituary`, `GibHealth`,
`RenderStyle`, `Alpha`. Those fall through to GZDoom's built-in `Zombieman`
(Radius 20 / Height 56 / PainChance 200 / +FLOORCLIP) and to `Actor` defaults
(Mass 100, Scale 1.0, MeleeRange 44, BloodColor red). **I cannot give a FILE:LINE
for those — they are engine defaults and no file under `ART SOURCE` states
them.** Recorded as unknown-by-citation rather than asserted.

There is **no `HitObituary`** on any of the five tiers, and **no `Melee` state**
on any of the five — this family has no melee attack at all.

## 1.2 Full state transcription

```
15  Spawn:
16      POSS A 0 Nodelay A_SpawnitemEx("NewIconCHP_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
                                     ; falls through into Idle, no Goto
17  Idle:
18      POSS AB 10 A_Look
19      Loop
20  See:
21      POSS AABBCCDD 4 A_Chase
22      Loop
23  Missile:
24      POSS E 10 A_FaceTarget
25      POSS F 8 A_CustomBulletAttack (22.5,0,1,random(1,5) * 3,"BulletPuff_C",0,CBAF_NORANDOM)
26      POSS E 8
27      Goto See
28  Tick:
29      TNT1 A 0 A_Spawnitemex("WhiteZombiePlan_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION)
30      Goto Death+2
31  Death.Ice:
32  Death:
33      TNT1 A 0 A_GivetoChildren("GoAway",1)
34      POSS H 5 A_JumpIfInventory("CHWhitePlan",0,"Tick")
35      POSS I 5 A_Scream
36      POSS J 5 A_NoBlocking
37      POSS K 5
38      TNT1 A 0 A_JumpIfInventory("CHAbyssMark",1,"AbyssGrow")
39      POSS L -1
40      Stop
41  xdeath:
42      TNT1 A 0 A_GivetoChildren("GoAway",1)
43      TNT1 A 0 A_Playsound("misc/gibbed/c")
44      TNT1 AAA 0 A_SpawnItemEx ("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
45      POSS M 3
46      POSS N 3 a_xscream
47      TNT1 AAA 0 A_SpawnItemEx ("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
48      POSS O 3 a_noblocking
49      POSS PQRST 3
50      TNT1 AAA 0 A_Spawnparticle("Red",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(1,13),frandom(0,360),0,0,24,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
51      POSS U -1
52      stop
53  Raise:
54      POSS K 5 A_JumpIfInventory("GrowRaisin",1,"Grow")
55      POSS JIH 5
56      POSS H 0 A_SpawnitemEx("NewIconCHP_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
57      Goto See
58  Grow:
59      POSS JIH 5
60      POSS A 0 A_Spawnitemex("CommonGreenZombie",0,0,6,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETTARGET)
61      TNT1 A 0 A_die("Nocorpse")
62      Stop
63  AbyssGrow:
64      TNT1 A×15 0 A_Spawnparticle("Black",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(9,15),frandom(0,360),0,0,32,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
65      TNT1 A×45 0 A_Spawnitemex("SplashAbyss_C",random(-32,32),random(-32,32),random(2,16),0,0,2,random(-359,359),SXF_NOCHECKPOSITION)
66      TNT1 A 8
67      POSS A 0 A_Spawnitemex("CommonAbyssZombieClone",0,0,6,0,0,1,0,SXF_NOCHECKPOSITION|SXF_SETTARGET)
68      TNT1 A 0 A_die
69      Stop
70  Death.Nocorpse:
71      TNT1 A 0 A_Changeflag(COUNTKILL,0)
72      Stop
```

The `A×15` and `A×45` runs are literal in the file and were counted
programmatically, not eyeballed: 15 A's on line 64, 45 A's on line 65 (identical
counts in `01_G.txt:77/78`, `01_B.txt:68/69`, `01_P.txt:70/71`).

`Goto Death+2` (line 30) lands on `POSS I 5 A_Scream` (line 35) — index 0 is the
0-tic `A_GivetoChildren`, index 1 is `POSS H 5`, index 2 is `POSS I 5`. CHP
inserted the `A_GivetoChildren` line that CH does not have and correctly bumped
`Death+1` (CH `CommonZombie`, `CH/decorate/Zombies.txt:850`) to `Death+2`.

## 1.3 States NOT declared by CHP that this actor still has

* **`Pain`** — `CommonZombie` (`CH/decorate/Zombies.txt:788-868`) declares
  `Pain.AbyssPE` but **no plain `Pain:`**. T00 therefore uses GZDoom's built-in
  `Zombieman` Pain (`POSS G 3` / `POSS G 3 A_Pain` / `Goto See`), and its
  `Goto See` resolves to **CHP's** See at `01_C.txt:20`. No file under
  `ART SOURCE` contains those three lines — engine default.
  T01, T02, T03 and T04 all declare their own `Pain`; T00 is the only one of the
  five that does not.
* **`Pain.AbyssPE`** — `CH/decorate/Zombies.txt:813-828`. 27 tics of `AYPB`
  frames, `a_playsound("AbyssForm",0)`, two 45-shot `SplashAbyss` bursts, then
  `A_SpawnitemEx("AbyssZombie2",...)` and `A_die`. This is the Abyss Pain
  Elemental's conversion path. Untouched by CHP for this tier.

---

# 2. T01 — `CommonGreenZombie` (`CHP/DECORATE/01/01_G.txt:1-87`)

## 2.1 Properties

**Declared by CHP** (`01_G.txt`):

| property | value | line |
|---|---|---|
| Health | `30` | 3 |
| Speed | `9` | 4 |
| PainChance | `180` | 5 |
| SeeSound | `"grunt/sight"` | 6 |
| AttackSound | `"grunt/attack"` | 7 |
| PainSound | `"grunt/pain"` | 8 |
| DeathSound | `"grunt/death"` | 9 |
| ActiveSound | `"grunt/active"` | 10 |
| Obituary | `"%o was killed by a smelly \c[ColorG]Green Zombieman\c-."` | 11 |
| Tag | `"\c[ColorG]Green Zombieman\c"` | 12 |

Note the `Tag` at line 12 ends `\c` with no trailing `-`; every other tier in
this range closes with `\c-`. Listed under §9 as a cosmetic defect.

**Inherited from `GreenZombie`** (`CH/decorate/Zombies.txt:870-987`):
`Game Doom` (872), **`Health 40`** (873 — overridden to 30 by CHP),
`Species "Zombie"` (874), **`BloodColor "Green"` (875)**,
`DamageFactor "Exorcist",3.0` (876), `DamageFactor "DIMp",0` (877),
`PainChance "DIMp",0` (878), `Radius 20` (879), `Height 56` (880),
`Speed 9` (881), `PainChance 180` (882), **`MeleeThreshold 300` (883)**,
`Monster` (884), `+FLOORCLIP` (885), **`+DONTHARMSPECIES` (886)**,
`+Missilemore` (887), `DropItem "implyingclip"` ×2 (894, 895),
**`Translation` (896)** — the long index-range remap, see §9.2.

`MeleeThreshold 300` is the only such property in the five tiers and it is worth
carrying: with no `Melee` state, `MeleeThreshold` still suppresses the missile
attack inside 300 units, so a Green Common zombie stops shooting when you close
and just chases (leaking gas). That is a real behavioural difference from T00.

## 2.2 Full state transcription

```
15  Spawn:
16      ZOMG A 0 Nodelay A_SpawnitemEx("NewIconCHP2_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
17  Idle:
18      ZOMG AB 10 A_Look
19      Loop
20  See:
21      ZOMG AABBCCDD 4 A_Chase
22      Loop
23  See2:
24      ZOMG AABBCCDD 4 A_Chase
25      ZOMG A 0 A_Custommissile("Gas11_C",32,0)
26      Loop
27  Missile:
28      ZOMG E 0 A_Custommissile("Gas11_C",32,0)
29      ZOMG E 10 A_FaceTarget
30      ZOMG F 8 A_CustomBulletAttack (22.5,0,1,random(1,5) * 3,"BulletPuff_C",0,CBAF_NORANDOM)
31      ZOMG E 8 A_Custommissile("Gas11_C",32,0)
32      ZOMG E 10 A_FaceTarget
33      ZOMG F 8 A_CustomBulletAttack (22.5,0,1,random(1,5) * 3,"BulletPuff_C",0,CBAF_NORANDOM)
34      ZOMG E 8 A_Custommissile("Gas11_C",32,0)
35      Goto See2
36  Pain:
37      ZOMG G 3 A_Custommissile("Gas11_C",32,0)
38      ZOMG G 3 A_Pain
39      Goto See2
40  Tickles:
41      TNT1 A 0 A_Spawnitemex("WhiteZombiePlan_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION)
42      Goto Death+2
43  Death.Ice:
44  Death:
45      TNT1 A 0 A_GivetoChildren("GoAway",1)
46      ZOMG H 5 A_JumpIfInventory("CHWhitePlan",0,"Tickles")
47      ZOMG I 5 A_Scream
48      ZOMG J 5 A_NoBlocking
49      ZOMG K 5 A_Custommissile("Gas11_C",32,0)
50      TNT1 A 0 A_JumpIfInventory("CHAbyssMark",1,"AbyssGrow")
51      ZOMG L -1
52      Stop
53  XDeath:
54      TNT1 A 0 A_GivetoChildren("GoAway",1)
55      TNT1 A 0 A_Playsound("misc/gibbed/c")
56      ZOMG M 5 A_SetTranslucent(0.8)
57      ZOMG N 5 A_XScream
58      TNT1 AAA 0 A_SpawnItemEx("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
59      ZOMG O 5 A_NoBlocking
60      ZOMG PQR 5 A_SetTranslucent(0.5)
61      ZOMG RST 5 A_SetTranslucent(0.3)
62      ZOMG U 5 A_Custommissile("Gas11_C",49,0)
63      ZOMG U 0 A_Custommissile("Gas11_C",32,7)
64      ZOMG U 0 A_Custommissile("Gas11_C",32,-7)
65      Stop
66  Raise:
67      ZOMG K 5 A_JumpIfInventory("GrowRaisin",1,"Grow")
68      ZOMG JIH 5
69      ZOMG H 0 A_SpawnitemEx("NewIconCHP2_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
70      Goto See2
71  Grow:
72      ZOMG JIH 5
73      ZOMG A 0 A_Spawnitemex("CommonBlueZombie",0,0,6,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETTARGET)
74      TNT1 A 0 A_die("Nocorpse")
75      Stop
76  AbyssGrow:
77      TNT1 A×15 0 A_Spawnparticle("Black",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(9,15),frandom(0,360),0,0,32,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
78      TNT1 A×45 0 A_Spawnitemex("SplashAbyss_C",random(-32,32),random(-32,32),random(2,16),0,0,2,random(-359,359),SXF_NOCHECKPOSITION)
79      TNT1 A 8
80      POSS A 0 A_Spawnitemex("CommonAbyssZombieClone",0,0,6,0,0,1,0,SXF_NOCHECKPOSITION|SXF_SETTARGET)
81      TNT1 A 0 A_die
82      Stop
83  Death.Nocorpse:
84      TNT1 A 0 A_Changeflag(COUNTKILL,0)
85      Stop
```

Frame `R` appears at the end of line 60 and again at the start of line 61 — it
plays twice, 5 tics each. Identical in CH (`CH/decorate/Zombies.txt:971-972`).
Sprite token on line 80 is `POSS`, not `ZOMG`, in an otherwise-ZOMG actor —
0 tics, so invisible, but it is a copy-paste tell; same on `01_B.txt:71` and
`01_P.txt:73`.

## 2.3 The See/See2 split — a behaviour that is easy to lose

The gas is **not** always on. `See:` (20–22) is a plain `A_Chase` loop with no
`A_Custommissile` and it `Loop`s forever. Only `Missile` (35), `Pain` (39) and
`Raise` (70) exit to `See2:`, which is the version that leaks gas once per
32-tic chase cycle (25). A Green Common zombie that has never fired and never
been hit leaves **no gas trail at all**. Same structure in CH
(`CH/decorate/Zombies.txt:904-916`).

## 2.4 States NOT declared by CHP

* **`Pain.AbyssPE`** — `CH/decorate/Zombies.txt:927-942`, identical shape to
  T00's.

---

# 3. T02 — `CommonBlueZombie` (`CHP/DECORATE/01/01_B.txt:1-78`)

## 3.1 Properties

**Declared by CHP** (`01_B.txt`):

| property | value | line |
|---|---|---|
| Health | `40` | 3 |
| Speed | `9` | 4 |
| PainChance | `140` | 5 |
| SeeSound | `"Zom2/see"` | 6 |
| AttackSound | `"grunt/attack"` | 7 |
| PainSound | `"Form2/hurt"` | 8 |
| DeathSound | `"zom2/die"` | 9 |
| ActiveSound | `"Form2/active"` | 10 |
| Obituary | `"%o got the blues from getting killed by \c[ColorB]Blue Zombie\c-."` | 11 |
| Tag | `"\c[ColorB]Blue Zombieman\c-"` | 12 |

**Inherited from `BlueZombie`** (`CH/decorate/Zombies.txt:1013-1122`):
`Game Doom` (1015), **`Health 60`** (1016 — overridden to 40 by CHP),
`Radius 20` (1017), `Height 56` (1018), `Speed 9` (1019), `PainChance 140`
(1020), `DamageFactor "Exorcist",3.0` (1021), `DamageFactor "DIMp",0` (1022),
`PainChance "DIMp",0` (1023), `Monster` (1024), `+FLOORCLIP` (1025),
`+Missilemore` (1026), `+Avoidmelee` (1027),
`DropItem "implyingclip"` ×2 (1034, 1035),
`DropItem "HealthBonus",64` (1036), `DropItem "HealthBonus",128` (1037),
**`Translation`** (1040).

`BlueZombie` declares **no `Species`** — unlike `CommonZombie` (792),
`GreenZombie` (874) and `PurpleZombie` (1129), which all set `Species "Zombie"`.
No `BloodColor` either, so T02 bleeds red despite being blue.

## 3.2 Full state transcription

```
15  Spawn:
16      ZOMB A 0 Nodelay A_SpawnitemEx("NewIconCHP3_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
17  Idle:
18      ZOMB AB 10 A_Look
19      Loop
20  See:
21      ZOMB AABBCCDD 4 A_Chase
22      ZOMB AABBCCDD 4 A_Fastchase
23      Loop
24  Missile:
25      ZOMB E 10 A_FaceTarget
26      ZOMB F 7 A_Custombulletattack(7,7,3,random(1,3),"BulletPuff_C")
27      ZOMB E 8
28      Goto See
29  Pain:
30      ZOMB G 3
31      ZOMB G 3 A_Pain
32      Goto See
33  Tickles:
34      TNT1 A 0 A_Spawnitemex("WhiteZombiePlan_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION)
35      Goto Death+2
36  Death.Ice:
37  Death:
38      TNT1 A 0 A_GivetoChildren("GoAway",1)
39      ZOMB H 5 A_JumpIfInventory("CHWhitePlan",0,"Tickles")
40      ZOMB I 5 A_Scream
41      ZOMB J 5 A_NoBlocking
42      ZOMB K 5
43      TNT1 A 0 A_JumpIfInventory("CHAbyssMark",1,"AbyssGrow")
44      ZOMB L -1
45      Stop
46  XDeath:
47      ZOMB M 0 A_GivetoChildren("GoAway",1)
48      TNT1 A 0 A_Playsound("misc/gibbed/c")
49      TNT1 AAA 0 A_SpawnItemEx("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
50      ZOMB N 5 A_XScream
51      ZOMB O 5 A_NoBlocking
52      TNT1 AAA 0 A_SpawnItemEx("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
53      ZOMB PQRST 5
54      TNT1 AAAA 0  a_Spawnparticle("Blue",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(1,13),frandom(0,360),0,0,24,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
55      ZOMB U -1
56      Stop
57  Raise:
58      ZOMB K 5 A_JumpIfInventory("GrowRaisin",1,"Grow")
59      ZOMB JIH 5
60      ZOMB H 0 A_SpawnitemEx("NewIconCHP3_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
61      Goto See
62  Grow:
63      ZOMB JIH 5
64      ZOMB A 0 A_Spawnitemex("CommonPurpleZombie",0,0,6,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETTARGET)
65      TNT1 A 0 A_die("Nocorpse")
66      Stop
67  AbyssGrow:
68      TNT1 A×15 0 A_Spawnparticle("Black",...)          [same body as T00 line 64]
69      TNT1 A×45 0 A_Spawnitemex("SplashAbyss_C",random(-32,32),random(-32,32),random(2,16),0,0,2,random(-359,359),SXF_NOCHECKPOSITION)
70      TNT1 A 8
71      POSS A 0 A_Spawnitemex("CommonAbyssZombieClone",0,0,6,0,0,1,0,SXF_NOCHECKPOSITION|SXF_SETTARGET)
72      TNT1 A 0 A_die
73      Stop
74  Death.Nocorpse:
75      TNT1 A 0 A_Changeflag(COUNTKILL,0)
76      Stop
```

Line 47 uses sprite frame `ZOMB M 0` where every other tier uses `TNT1 A 0` for
the `A_GivetoChildren` line, then never shows frame `M` again (the XDeath goes
`M(0) → N → O → PQRST → U`). Zero tics, so no visual difference; noted only
because a mechanical port that reads "frame M, 0 tics" as meaningful will add a
frame that CHP never displays.

## 3.3 States NOT declared by CHP

* **`Pain.AbyssPE`** — `CH/decorate/Zombies.txt:1064-1079`.

---

# 4. T03 — `CommonCyanZombie` (`CHP/DECORATE/01/01_CY.txt:1-59`)

**This is the odd one and the one most likely to be ported wrong.** It has the
fewest states of the five and it is *not* a `Zombieman` descendant.

## 4.1 Properties

**Declared by CHP** (`01_CY.txt`):

| property | value | line |
|---|---|---|
| Health | `30` | 3 |
| Speed | `9` | 4 |
| PainChance | `40` | 5 |
| RenderStyle | `Translucent` | 6 |
| Alpha | `0.75` | 7 |
| SeeSound | `"Zom2/see"` | 8 |
| AttackSound | `"grunt/attack"` | 9 |
| PainSound | `"Form2/hurt"` | 10 |
| DeathSound | `"zom2/die"` | 11 |
| ActiveSound | `"Form2/active"` | 12 |
| Obituary | `"%o got cooled off by \c[ColorCY]Cyan Zombie\c-"` | 13 |
| Tag | `"\c[ColorCY]Cyan Zombieman\c-"` | 14 |
| Translation | **`None`** | 15 |

`RenderStyle Translucent` + `Alpha 0.75` are **new in CHP** — `CyanZombie2` sets
neither.

**Inherited from `CyanZombie2`** (`CH/decorate/Zombies.txt:245-338`) — note the
declaration is `ACTOR CyanZombie2` with **no parent**, so this actor is *not* a
`Zombieman` and has no vanilla zombie states beneath it:
`Game Doom` (247), **`Health 30`** (248), `Radius 20` (249), `Height 56` (250),
`Speed 9` (251), `PainChance 40` (252), **`Bloodcolor "Blue"` (253)**,
`DamageFactor "Exorcist",3.0` (254), **`DamaGeFactor Fire,2.0` (255)**,
**`DamageFactor "Fire",2.0` (256)** — the same factor declared twice, once
unquoted with a typo'd capital G in the property name, once quoted —
**`DamageFactor Melee,2.0` (257)**, `DamageFactor "DIMp",0` (258),
`PainChance "DIMp",0` (259), `Monster` (260), `+FLOORCLIP` (261),
**`+thruspecies` (262)**, `+Missilemore` (263), `+Avoidmelee` (264),
**`+noicedeath` (265)**, `DropItem "implyingclip"` ×2 (272, 273),
`DropItem "HealthBonus",64` (274), `DropItem "HealthBonus",128` (275),
`Translation "0:255=%[0.06,0.31,0.35]:[1.01,2.00,2.00]"` (278) — cleared by
CHP's `Translation None`.

`CyanZombie2` sets `+THRUSPECIES` (262) but declares **no `Species`** — see §9.5.

**Double damage from fire and from melee** is unique to this tier in this range
and is the single most gameplay-relevant inherited property here.

## 4.2 Full state transcription — this is ALL of it

```
18  Spawn:
19      CYNT A 0 Nodelay A_SpawnitemEx("NewIconCHP22_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
20  Idle:
21      CYNT AB 10 A_Look
22      Loop
23  See:
24      CYNT AABBCCDD 2 A_Chase
25      CYNT A 0 A_jump(128,"See2")
26      Loop
27  See2:
28      CYNT AABBCCDD 1 A_FastChase
29      Goto see
30  Missile:
31      CYNT E 6 A_FaceTarget
32      CYNT F 4 A_Custommissile("IceZombieShot_C",42,1,random(-2,2))
33      CYNT E 4
34      Goto See
35  Pain:
36      CYNT G 3
37      CYNT G 3 A_Pain
38      Goto See
39  Death.Ice:
40  Death:
41      TNT1 A 0 A_GivetoChildren("GoAway",1)
42      CYNT G 12 a_scream
43      CYNT G 4 A_NoBlocking
44      CYNT G 6 a_setscale(1.2,0.8)
45      CYNT G 6 a_setscale(1.0,1.0)
46      CYNT G 6 a_setscale(0.8,1.2)
47      CYNT G 4 a_setscale(1.2,0.8)
48      CYNT G 4 a_setscale(0.8,1.2)
49      CYNT G 3 a_setscale(1.2,0.8)
50      CYNT G 3 a_setscale(0.8,1.2)
51      CYNT G 2 a_setscale(1.2,0.8)
52      CYNT G 2 a_setscale(0.8,1.2)
53      CYNT G 1 a_setscale(1.2,0.8)
54      CYNT G 1 a_setscale(0.8,1.2)
55      MISL A 0 A_Playsound("misc/icebreak")
56      MISL A 0 A_Burst("IceChunk_C")
57      Stop
```

Death runs 48 tics of a single frame (`CYNT G`) with an accelerating
squash-and-stretch — 6,6,6,4,4,3,3,2,2,1,1 after a 12-tic scream and a 4-tic
`A_NoBlocking` — then shatters. It is a *vibrating*, not a falling, death.

CHP replaced CH's terminator: `CyanZombie2` ends
`MISL A 0 A_iceguydie` (`CH/decorate/Zombies.txt:335`); CHP ends with an
explicit `A_Playsound("misc/icebreak")` + `A_Burst("IceChunk_C")` pair
(`01_CY.txt:55-56`). Functionally similar, but it is the *shatter* that is now
authored rather than delegated, and `IceChunk_C` is the chunk class.

## 4.3 States this tier DOES NOT HAVE — verified absent, not merely unread

`CommonCyanZombie` declares 7 state labels (Spawn, Idle, See, See2, Missile,
Pain, Death.Ice, Death). `CyanZombie2` (`CH/decorate/Zombies.txt:280-337`)
declares Spawn, See, See2, Missile, Pain.AbyssPE, Pain, Death. Between the two,
**there is no**:

* `XDeath` — a Cyan zombie cannot be gibbed; extreme damage runs the normal
  Death, so the 48-tic shatter always plays.
* `Raise` — **it cannot be resurrected by an Archvile.** No Raise anywhere in
  the chain, and the chain does not reach `Zombieman`.
* `Grow` / `GrowRaisin` check — it cannot tier up.
* `AbyssGrow` / `CHAbyssMark` check — the Abyss mark does nothing to it.
* `Tickles` / `Tick` / `CHWhitePlan` check — the White Zombie Plan does not fire
  on it.
* `Death.Nocorpse`.
* `Melee`.

Only `Pain.AbyssPE` (`CH/decorate/Zombies.txt:300-315`) is inherited and not
redeclared.

`Death.Ice:` (39) falling into `Death:` is **redundant here** because
`CyanZombie2` carries `+noicedeath` (`CH/decorate/Zombies.txt:265`), which
already suppresses the engine freeze-shatter. On T00/T01/T02/T04 the same
`Death.Ice:` label is *not* redundant — those actors have no `+NOICEDEATH`, so
the label is what stops them freeze-shattering and routes ice kills into the
normal death.

---

# 5. T04 — `CommonPurpleZombie` (`CHP/DECORATE/01/01_P.txt:1-82`)

## 5.1 Properties

**Declared by CHP** (`01_P.txt`):

| property | value | line |
|---|---|---|
| Health | `65` | 3 |
| Speed | `10` | 4 |
| PainChance | `120` | 5 |
| SeeSound | `"Zom2/see"` | 6 |
| AttackSound | `"grunt/attack"` | 7 |
| PainSound | `"Form2/hurt"` | 8 |
| DeathSound | `"zom2/die"` | 9 |
| ActiveSound | `"Form2/active"` | 10 |
| Obituary | `"%o got \c[ColorP]outfabolous'd\c-"` | 11 |
| Tag | `"\c[ColorP]Purple Zombieman\c-"` | 12 |

**Inherited from `PurpleZombie`** (`CH/decorate/Zombies.txt:1125-1243`):
`Game Doom` (1127), **`Health 95`** (1128 — overridden to 65 by CHP),
`Species "Zombie"` (1129), `DamageFactor "Exorcist",3.0` (1130),
`DamageFactor "DIMp",0` (1131), `PainChance "DIMp",0` (1132), `Radius 20`
(1133), `Height 56` (1134), `Speed 10` (1135), `PainChance 120` (1136),
`Monster` (1137), `+FLOORCLIP` (1138), `+Missilemore` (1139), `+Avoidmelee`
(1140), `DropItem "implyingclip"` ×2 (1147, 1148),
`DropItem "HealthBonus"` (1149), `DropItem "HealthBonus",88` (1150),
`DropItem "HealthBonus",128` (1151), `DropItem "ArmorBonus",64` (1152),
**`Renderstyle SoulTrans` (1153)**, **`Alpha 1` (1154)**,
**`Translation`** (1155).

`Renderstyle SoulTrans` with `Alpha 1` on the next line: in GZDoom `SoulTrans`
takes its alpha from the `transsouls` CVar rather than from the actor's `Alpha`,
so the `Alpha 1` is inert and the Purple zombie is substantially transparent by
default. I am flagging rather than asserting — this is engine behaviour I cannot
cite to a file under `ART SOURCE`, and it should be looked at on screen before
the port copies `Alpha 1` and expects an opaque monster.

## 5.2 Full state transcription

```
15  Spawn:
16      BPOS A 0 Nodelay A_SpawnitemEx("NewIconCHP4_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
17  Idle:
18      BPOS AB 10 A_Look
19      Loop
20  See:
21      BPOS AABBCCDD 4 A_Chase
22      BPOS AABBCCDD 4 A_Fastchase
23      Loop
24  Missile:
25      BPOS E 2 A_JumpIfCloser(800,"Hitscanne")
26      BPOS E 0 A_Jump(255,"Orbb")
27  Hitscanne:
28      BPOS E 10 A_FaceTarget
29      BPOS F 7 A_Custombulletattack(9,9,3,random(1,2),"BulletPuff_C")
30      BPOS F 4 A_Custombulletattack(7,7,2,random(1,2),"BulletPuff_C")
31      BPOS E 8 A_Monsterrefire(128,"See")
32      Goto Missile
33  Orbb:
34      BPOS E 5 A_FaceTarget
35      BPOS F 5 Bright A_Custommissile("Orbb11_C",46,1)
36      BPOS F 5 Bright A_Custommissile("Orbb11_C",46,1)
37      BPOS F 5 Bright A_Custommissile("Orbb11_C",46,1)
38      BPOS E 5
39      Goto See
40  Pain:
41      BPOS G 3
42      BPOS G 3 A_Pain
43      Goto See
44  Tickles:
45      TNT1 A 0 A_Spawnitemex("WhiteZombiePlan_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION)
46      Goto Death+2
47  Death.Ice:
48  Death:
49      TNT1 A 0 A_GivetoChildren("GoAway",1)
50      BPOS H 5 A_JumpIfInventory("CHWhitePlan",1,"Tickles")
51      BPOS I 5 A_Scream
52      BPOS J 5 A_NoBlocking
53      BPOS K 5
54      TNT1 A 0 A_JumpIfInventory("CHAbyssMark",1,"AbyssGrow")
55      BPOS L -1
56      Stop
57  XDeath:
58      TNT1 A 0 A_GivetoChildren("GoAway",1)
59      TNT1 A 0 A_Playsound("misc/gibbed/c")
60      TNT1 AAA 0 A_SpawnItemEx("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
61      BPOS M 5
62      BPOS N 5 A_XScream
63      BPOS O 5 A_NoBlocking
64      TNT1 AAA 0 A_SpawnItemEx("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
65      BPOS PQRST 5
66      TNT1 AAAA 0 A_Spawnparticle("Purple",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(1,13),frandom(0,360),0,0,24,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
67      BPOS U -1
68      Stop
69  AbyssGrow:
70      TNT1 A×15 0 A_Spawnparticle("Black",...)          [same body as T00 line 64]
71      TNT1 A×45 0 A_Spawnitemex("SplashAbyss_C",random(-32,32),random(-32,32),random(2,16),0,0,2,random(-359,359),SXF_NOCHECKPOSITION)
72      TNT1 A 8
73      POSS A 0 A_Spawnitemex("CommonAbyssZombieClone",0,0,6,0,0,1,0,SXF_NOCHECKPOSITION|SXF_SETTARGET)
74      TNT1 A 0 A_die
75      Stop
76  Raise:
77      BPOS K 5
78      BPOS JIH 5
79      BPOS H 0 A_SpawnitemEx("NewIconCHP4_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
80      Goto See
81  }
```

## 5.3 Two things about T04 a port will get wrong

1. **No `Grow` state and no `GrowRaisin` check in `Raise`** (line 77 is a bare
   `BPOS K 5`, where T00/T01/T02 all have
   `A_JumpIfInventory("GrowRaisin",1,"Grow")`). `PurpleZombie` has none either
   (`CH/decorate/Zombies.txt:1239-1241` is a bare `POSS KJIH 5` / `Goto See`).
   **Purple is the top of the Grow ladder in this range.** There is also no
   `Death.Nocorpse` — nothing calls `A_die("Nocorpse")` on it, so that is
   consistent, not a dangling reference.
2. **`A_JumpIfInventory("CHWhitePlan",1,...)` on line 50 uses count 1**, where
   T00 (`01_C.txt:34`), T01 (`01_G.txt:46`) and T02 (`01_B.txt:39`) all use
   count **0**. Per GZDoom, count 0 means "has the item at its maximum amount",
   and `CHWhitePlan` is `Inventory.MaxAmount 1`
   (`CHP/DECORATE/01/01_W.txt:9430-9433`), so **0 and 1 are equivalent here** and
   this is *not* a live bug — but it is an inconsistency that will make a
   line-by-line differ scream, and it is worth pinning in a comment at the port
   site so nobody "fixes" it twice.

## 5.4 States NOT declared by CHP

* **`Pain.AbyssPE`** — `CH/decorate/Zombies.txt:1190-1205`.

---

# 6. THE CATALOG — one entry per distinct attack

`axes` uses **only** values already live in this project. I grepped the whole
tree (`grep -rhoE "\b[a-z]+:[a-z0-9_-]+" zscript/weapons/ zscript/monsters/`) and
the live monster-side vocabulary is:
`species:*`, `role:{fodder,skirmisher,artillery,bruiser,summoner,boss}`,
`delivery:{bullet,heavy,melee,radial}`,
`element:{kinetic,thermal,plasma,void}`,
`payload:{single,multi}`,
`behavior:{homing,piercing}`,
`mobility:{ground,flying,floating}`,
`trait:{ex,secondstage,summoned,resurrector,homing,stealth}`.

**There is no `element:ice` and no `element:poison` in this project, and there is
no `archetype:hitscan` or `delivery:hitscan`.** I have not invented them. Where
an axis has no fitting value I have left it out and said so in `notes`.
See §10.1 — rs_21's own worked example uses two values that do not exist.

`delivery:bullet` is used below for the hitscan attacks because that is the
precedent already in the tree for this exact monster:
`E:\RS_Main\zscript\monsters\RS_Zombieman.zs:155` reads
`"species:zombieman role:fodder delivery:bullet element:kinetic mobility:ground"`.

---

## ZM_RifleShot
`zscript/monsters/Zombieman/attacks/RS_Zombieman_RifleShot.zs`

```
kind         : single rifle crack -- one aimed hitscan round, wide cone, no burst
axes         : species:zombieman role:fodder delivery:bullet payload:single
               element:kinetic mobility:ground
tier(s)      : T00 Common (Zombieman)
chp source   : CHP/DECORATE/01/01_C.txt:23-27  (Missile)
acs          : none. The actor calls no ACS. The only CallACS in T00's reach is
               inside the icon actor it spawns (CHP/DECORATE/MISC/icons.txt:1,
               which is a no-op) and inside WhiteZombiePlan_C
               (CHP/DECORATE/01/01_W.txt:8939-8941). Neither is an attack.
fires        : hitscan trace x1, spread 22.5 deg horizontal / 0 vertical,
               range 0 (= engine MISSILERANGE), puff BulletPuff_C
damage       : random(1,5) * 3          -- 3..15, flat, because CBAF_NORANDOM
                                           is set (01_C.txt:25). Do NOT drop the
                                           flag: without it the engine multiplies
                                           by a further random(1,3).
sprites      : POSS E (10t windup) / POSS F (8t fire) / POSS E (8t recover)
sounds       : AttackSound "grunt/attack" (01_C.txt:7). Not played by the state
               -- A_CustomBulletAttack does not play AttackSound; nothing in
               T00's Missile plays a sound at all. See notes.
behaviour    : Faces you for 10 tics, then puts one bullet into a 22.5-degree
               cone and stands in the recovery frame for 8. Wider cone than the
               vanilla zombieman's own A_PosAttack in practice because the
               damage roll is fixed rather than tripled, so it is more of a
               steady chip than a spike: never more than 15, never less than 3,
               once every 26 tics.
profile      : RS_AttackProfile.MakeHitscan(
                   fireSnd: "grunt/attack",
                   spreadScale: 22.5,     // see notes -- units differ
                   ammoCost: 0,
                   profName: "Rifle Shot",
                   impactPuff: <BulletPuff_C port>)
notes        : (a) MakeHitscan's SpreadScale is a MULTIPLIER on
                   (100 - Accuracy), not degrees (RS_AttackProfile.zs:71-76).
                   22.5 degrees cannot be expressed through it directly; the
                   monster path needs either SpreadBonus (flat degrees,
                   RS_AttackProfile.zs:80) or a new call. Recorded as a real
                   gap, not papered over.
               (b) No `element:` beyond kinetic and no trigger axis: there is no
                   live `trigger:` value for a monster (all four live trigger
                   values are weapon-side: semiauto/fullauto/semi/burst).
               (c) CHP declares AttackSound but no state plays it. Vanilla
                   A_PosAttack plays AttackSound internally;
                   A_CustomBulletAttack does not. Every one of these five tiers
                   inherits that silence. Flagged in section 9.
```

## ZM_GasRifleDoubleTap
`zscript/monsters/Zombieman/attacks/RS_Zombieman_GasRifle.zs`

```
kind         : two-shot rifle burst that vents poison gas between the shots
axes         : species:zombieman role:fodder delivery:bullet payload:multi
               element:kinetic mobility:ground
tier(s)      : T01 Green (Zombieman)
chp source   : CHP/DECORATE/01/01_G.txt:27-35  (Missile)
acs          : none.
fires        : hitscan trace x1 at 01_G.txt:30 and again at 01_G.txt:33 --
               spread 22.5/0, range 0, puff BulletPuff_C, CBAF_NORANDOM;
               PLUS Gas11_C x4 in the same state chain, at spawnheight 32,
               offset 0 -- lines 28, 31, 34 and the entry line 28.
damage       : bullets: random(1,5) * 3 each, twice        -- 3..15 per shot
               gas:     random(1,8) per A_Explode, FOUR times per cloud
                        (Gas11_C Death is a 4-FRAME state, 01_G.txt:1418)
sprites      : ZOMG E (0t gas) / E (10t aim) / F (8t fire) / E (8t gas)
               / E (10t aim) / F (8t fire) / E (8t gas)   -- 42 tics total
sounds       : AttackSound "grunt/attack" declared (01_G.txt:7), never played.
behaviour    : Enters the attack already exhaling, fires, exhales, re-aims,
               fires again, exhales, and leaves into See2 which keeps exhaling
               forever. Standing where a Green Common zombie has been standing
               hurts; the bullets are the same as T00's, so the tier's real
               escalation is the gas field, not the gun. Total 3 clouds per
               attack pass plus one per chase cycle thereafter.
profile      : two entries in one slot --
               RS_AttackProfile.MakeHitscan(
                   fireSnd: "grunt/attack", ammoCost: 0,
                   profName: "Gas Rifle", impactPuff: <BulletPuff_C port>)
               RS_AttackProfile.MakeVolley(
                   <Gas11_C port>, 1, 0.0, "", 1.0, 0.0, "Gas Vent")
notes        : the double-tap is a STATE SHAPE, not a profile field. rs_17 s4
               (docs/rs_17_attack_grammar.txt:151-159) already names this exact
               hole: VolleyCount fires on one tic, BurstCount (2 shots, 18 tics
               apart here) does not exist yet. Porting this faithfully today
               means the state chain, not the profile. Recording it rather than
               pretending MakeVolley covers it.
```

## ZM_PoisonGasCloud
`zscript/monsters/Zombieman/attacks/RS_Zombieman_GasCloud.zs`

```
kind         : lingering poison gas cloud -- a stationary area-denial puff
axes         : delivery:radial payload:multi mobility:ground
tier(s)      : T01 Green (Zombieman)
chp source   : projectile CHP/DECORATE/01/01_G.txt:1410-1421 (Gas11_C)
               base     CH/decorate/Zombies.txt:989-1011      (Gas11)
               emitted from  01_G.txt:25 (See2, once per chase cycle)
                             01_G.txt:28,31,34 (Missile)
                             01_G.txt:37 (Pain)
                             01_G.txt:49 (Death, frame K)
                             01_G.txt:62,63,64 (XDeath -- 3 at once, one at
                             height 49 and two at height 32, offset +7 and -7)
acs          : none.
fires        : A_Custommissile("Gas11_C",32,0) -- Speed 0, so it does not
               travel; it is dropped where the zombie stands. Radius 6,
               Height 16, Scale 0.8, Alpha 0.6, RenderStyle Add, +RANDOMIZE
               (CH/decorate/Zombies.txt:992-1001).
damage       : random(1,8) per detonation, radius 32, DamageType Poison
               (CH/decorate/Zombies.txt:996) -- and it detonates FOUR TIMES,
               once per frame of `PSBG FGHI 6 Bright A_Explode(random(1,8),32)`
               (01_G.txt:1418), 6 tics apart. Total exposure 3..32 over 24 tics.
sprites      : PSBG CDE (3t each, Bright) rise / PSBG FGHI (6t each, Bright)
               detonating
sounds       : none. Gas11/Gas11_C declare no sounds at all.
behaviour    : A knee-high puff of green haze that sits still, brightens, and
               then ticks damage four times over about half a second inside a
               32-unit ball. One is trivial. A Green Common zombie that has
               been aggroed leaves a new one every chase cycle, so a corridor
               it has walked becomes a slow-damage field, and the three it
               drops on being gibbed make its corpse a small trap.
profile      : RS_AttackProfile.MakeVolley(
                   <Gas11_C port>, 1, 0.0, "", 1.0, 0.0, "Gas Cloud")
               -- or MakeRadial(32.0, <roll>, 0, false, "", "Gas Cloud") if the
               cloud is modelled as an effect rather than a spawned actor. The
               four-detonation shape is a property of the PROJECTILE's state,
               not of the profile, so MakeVolley of the ported actor is the
               faithful one.
notes        : (a) THE FOUR-FRAME A_Explode IS DELIBERATE. This is exactly the
                   "gas/lightning/lingering fire" class the project already
                   knows about. It must NOT be collapsed to a single
                   detonation.
               (b) A_Explode's `flags` argument is left at default, which is
                   XF_HURTSOURCE -- the cloud's source is the zombie that
                   emitted it. GreenZombie carries +DONTHARMSPECIES and
                   Species "Zombie" (CH/decorate/Zombies.txt:874, 886), which
                   may or may not spare it. Unresolved; needs the engine.
               (c) `Gas11_C` (01_G.txt:1410-1421) overrides Spawn and Death with
                   bodies BYTE-IDENTICAL to `Gas11`'s (CH:1004-1009). It is a
                   pure no-op subclass. Its sibling `Gas11_G` (01_G.txt:1423)
                   does change something (random(1,10)), so the _C override is
                   template residue. Port one class, not two.
               (d) There is no live `element:` value for poison. Left off
                   rather than invented.
```

## ZM_TripleBurst
`zscript/monsters/Zombieman/attacks/RS_Zombieman_TripleBurst.zs`

```
kind         : three-round tight burst -- a rattle of hitscan on one trigger pull
axes         : species:zombieman role:skirmisher delivery:bullet payload:multi
               element:kinetic mobility:ground
tier(s)      : T02 Blue (Zombieman)
chp source   : CHP/DECORATE/01/01_B.txt:24-28  (Missile)
acs          : none.
fires        : 3 hitscan traces on ONE tic, spread 7 deg horizontal /
               7 deg vertical, range 0, puff BulletPuff_C. NO CBAF_NORANDOM.
damage       : random(1,3) per bullet, THEN multiplied per-bullet by the
               engine's random(1,3) because the flag is absent
               (01_B.txt:26) -- effective 1..9 per bullet, 3..27 for the burst.
               The outer roll is evaluated ONCE for the call; the inner x1..3
               is rolled separately for each of the three bullets.
sprites      : ZOMB E (10t aim) / ZOMB F (7t fire) / ZOMB E (8t recover)
sounds       : AttackSound "grunt/attack" declared (01_B.txt:7), never played.
behaviour    : A much tighter cone than T00/T01 -- 7 degrees against 22.5 -- but
               three rounds at once and vertical scatter as well as horizontal,
               so at range it is a shotgun-ish smear and up close it is a
               reliable 3-hit. Faster too: 25 tics against T00's 26 for triple
               the rounds, on a monster that alternates A_Chase and A_FastChase
               (01_B.txt:21-22) so it closes while doing it.
profile      : RS_AttackProfile.MakeHitscan(
                   fireSnd: "grunt/attack", ammoCost: 0,
                   profName: "Triple Burst",
                   impactPuff: <BulletPuff_C port>)
               with PelletOverride 3 (RS_AttackProfile.zs:77) -- three traces on
               one tic is exactly what PelletOverride means; this is the one
               attack in the five that maps cleanly onto an existing field.
notes        : the missing CBAF_NORANDOM is the single most likely thing to be
               lost in a port, because the visible text says random(1,3) and the
               real answer is random(1,3) x random(1,3). Keep it as a roll on a
               roll; do not multiply out to random(1,9), which is a different
               distribution.
```

## ZM_IceBolt
`zscript/monsters/Zombieman/attacks/RS_Zombieman_IceBolt.zs`

```
kind         : flat ice sliver -- a fast, thin, freezing dart
axes         : species:zombieman role:skirmisher delivery:heavy payload:single
               mobility:ground
tier(s)      : T03 Cyan (Zombieman)
chp source   : CHP/DECORATE/01/01_CY.txt:30-34  (Missile)
               projectile CHP/DECORATE/01/01_CY.txt:934-957 (IceZombieShot_C)
               base       CH/decorate/Zombies.txt:211-234   (IceZombieShot)
acs          : none on the attack. The tier's SPAWN is ACS-gated
               (CommonCyanZombieCheck, CHP/DECORATE/MISC/op_m_checks.txt:590-604,
               reads CallACS("CH_Cyan")), but the attack is not.
fires        : A_Custommissile("IceZombieShot_C", 42, 1, random(-2,2))
               -- spawnheight 42, lateral offset 1, aim jitter +-2 degrees
damage       : Damage (random(6,16))   -- 01_CY.txt:939. PARENTHESISED, so this
               is the exact damage; the engine's x random(1,8) projectile
               multiplier is NOT applied. DamageType Ice (01_CY.txt:940).
sprites      : ICEY ABC 3 Bright (flight, looping) / ICEY FGHI 5 Bright (death)
sounds       : SeeSound "Ice/Hit2"     -> ICEI (CH/SNDINFO.txt:1132)
               DeathSound "spike/spiked" -> NOT DEFINED, see notes
               monster: AttackSound "grunt/attack" declared, never played
behaviour    : A near-flat sliver -- xScale 1.15, yScale 0.15 (01_CY.txt:944-945)
               -- fired at speed 33 as a FastProjectile, so it crosses the room
               in a couple of tics and is close to undodgeable at range; the
               only slack is the +-2 degree jitter. The Cyan zombie's whole
               attack cycle is 14 tics (6 aim, 4 fire, 4 recover), the shortest
               of the five by a wide margin, and it fast-chases at 1 tic per
               frame half the time (01_CY.txt:25,28). It is a harasser: small
               bites, delivered constantly, from a monster that is always
               closing.
profile      : RS_AttackProfile.MakeVolley(
                   <IceZombieShot_C port>, 1, 4.0,
                   "", 1.0, 0.0, "Ice Sliver")
               -- VolleyArc 4.0 reproduces random(-2,2). Alternatively arc 0
               and VolleyPitchJitter 0 with the jitter left in the state; the
               arc form is closer to the source's intent.
notes        : (a) NO ELEMENT AXIS. There is no `element:ice` in this project
                   (grep over all of zscript/ returns zero). rs_21's own example
                   entry uses `element:ice` -- see section 10.1. I have left the
                   axis OFF rather than invent it. If the vocabulary is
                   extended, this is the first customer.
               (b) CHP CHANGED THE PROJECTILE'S CLASS. CH's IceZombieShot is a
                   plain `ACTOR IceZombieShot` with `Projectile`
                   (CH/decorate/Zombies.txt:211,218). CHP's IceZombieShot_C is
                   `: FastProjectile` AND also declares `Projectile`
                   (01_CY.txt:934,941). FastProjectile moves in sub-steps per
                   tic; at speed 33 that is a materially different flight from
                   CH's. Port the FastProjectile form -- CHP wins.
               (c) DeathSound "spike/spiked" (01_CY.txt:947) is defined in
                   NEITHER CH/SNDINFO.txt NOR CHP/SNDINFO.txt --
                   grep "spiked" over both returns nothing. The shatter is
                   silent unless the engine provides it. See section 9.4.
```

## ZM_PurpleBurst
`zscript/monsters/Zombieman/attacks/RS_Zombieman_PurpleBurst.zs`

```
kind         : close-range 3+2 rattle with a refire loop -- a suppressing burst
axes         : species:zombieman role:skirmisher delivery:bullet payload:multi
               element:kinetic mobility:ground
tier(s)      : T04 Purple (Zombieman)
chp source   : CHP/DECORATE/01/01_P.txt:24-32  (Missile / Hitscanne)
acs          : none.
fires        : A_Custombulletattack(9,9,3,random(1,2),"BulletPuff_C")  -- 3
                 traces, 9/9 spread              (01_P.txt:29)
               A_Custombulletattack(7,7,2,random(1,2),"BulletPuff_C")  -- 2
                 traces, 7/7 spread, 7 tics later (01_P.txt:30)
               then A_Monsterrefire(128,"See")   (01_P.txt:31) -- 50% chance to
               break off, otherwise Goto Missile and go round again.
damage       : random(1,2) per bullet x the engine's per-bullet random(1,3)
               (no CBAF_NORANDOM on either call) -- 1..6 per bullet.
               5 bullets per pass, 5..30 per pass, unbounded passes at 50% each.
sprites      : BPOS E (2t range check) / E (10t aim) / F (7t fire)
               / F (4t fire) / E (8t refire check)
sounds       : AttackSound "grunt/attack" declared (01_P.txt:7), never played.
behaviour    : Only used inside 800 units (01_P.txt:25). Two bursts a third of a
               second apart, the second tighter than the first, then a coin
               flip: walk away, or do it all again without re-acquiring. A
               Purple Common zombie that wins the coin flip three times has put
               twenty rounds into you in under two seconds. It is the closest
               thing in this range to sustained fire, and it does it while
               alternating A_Chase and A_FastChase (01_P.txt:21-22).
profile      : two entries, fired in sequence from one slot --
               RS_AttackProfile.MakeHitscan(
                   fireSnd: "grunt/attack", ammoCost: 0,
                   profName: "Purple Burst A", impactPuff: <BulletPuff_C port>)
                 with PelletOverride 3
               RS_AttackProfile.MakeHitscan(
                   fireSnd: "grunt/attack", ammoCost: 0,
                   profName: "Purple Burst B", impactPuff: <BulletPuff_C port>)
                 with PelletOverride 2
notes        : (a) The refire loop is A_Monsterrefire(128,"See"), i.e. 128/256.
                   There is no profile field for "50% chance to repeat this
                   whole attack" -- another instance of the rs_17 s4 time gap.
                   Keep it in the state.
               (b) `A_Jump(255,"Orbb")` at 01_P.txt:26 is 255/256, so ~0.4% of
                   the time it falls through -- into `Hitscanne:`, the very next
                   label, which is where A_JumpIfCloser would have sent it
                   anyway. Behaviourally identical to A_Jump(256). Worth a
                   comment at the port site so the odd number is not "corrected"
                   into a real change.
```

## ZM_SeekerOrbs
`zscript/monsters/Zombieman/attacks/RS_Zombieman_SeekerOrbs.zs`

```
kind         : slow homing plasma orbs -- three weaving trackers, fired at range
axes         : species:zombieman role:artillery delivery:heavy payload:multi
               element:plasma behavior:homing mobility:ground
tier(s)      : T04 Purple (Zombieman)
chp source   : CHP/DECORATE/01/01_P.txt:33-39  (Orbb)
               projectile CHP/DECORATE/01/01_P.txt:1332-1360 (Orbb11_C)
               base       CH/decorate/Zombies.txt:1245-1273  (Orbb11)
acs          : none.
fires        : A_Custommissile("Orbb11_C",46,1) three times, 5 tics apart
               (01_P.txt:35,36,37) -- spawnheight 46, lateral offset 1
damage       : Damage (random(2,18))  -- 01_P.txt:1339. PARENTHESISED, so exact;
               no x random(1,8). DamageType Plasma (01_P.txt:1340).
               3 orbs, 6..54 if all three land.
sprites      : BAL1 A 2 Bright (seek) / BAL1 B 2 Bright (weave), looping
               / BAL1 CDE 6 Bright (death)
sounds       : SeeSound "Weapons/Plasmaf" (dsplasma, engine)
               DeathSound "weapons/plasmax" (dsfirxpl, engine)
               Neither is defined in CH or CHP SNDINFO; both are vanilla Doom
               logical names, so both resolve.
behaviour    : Fired only beyond 800 units (01_P.txt:25 sends anything closer to
               the hitscan branch). Three small bright orbs at Scale 0.3, speed
               21 (32 in fast mode), each correcting toward you by up to 3
               degrees whenever it is more than 2 degrees off
               (A_Seekermissile(2,3), 01_P.txt:1353) and weaving side to side
               between corrections (A_weave(5,4,2,1), 01_P.txt:1354). They are
               slow enough to outrun in a straight line and persistent enough
               that you cannot ignore them; the weave makes strafing past one
               unreliable. All three leave on the SAME facing -- there is a
               single A_FaceTarget at 01_P.txt:34 and none between the shots.
profile      : RS_AttackProfile.MakeVolley(
                   <Orbb11_C port>, 3, 0.0,
                   "Weapons/Plasmaf", 1.0, 0.0, "Seeker Orbs")
notes        : (a) MakeVolley puts all `count` rounds out on ONE tic
                   (RS_AttackProfile.zs:404,417 and the rs_17 s4 note at
                   docs/rs_17_attack_grammar.txt:154-157). CHP fires them 5 tics
                   apart. MakeVolley(3) is therefore NOT faithful on its own --
                   it is a 3-round volley where CHP has a 3-round burst. Either
                   keep the 5-tic spacing in the state, or wait for BurstCount.
                   Recording the gap rather than declaring the profile correct.
               (b) CHP changed the class: CH's Orbb11 is `ACTOR Orbb11` with
                   `Projectile` (CH/decorate/Zombies.txt:1245,1255); CHP's
                   Orbb11_C is `: FastProjectile` (01_P.txt:1332). Same change
                   CHP made to the ice bolt. The Translation strings are
                   otherwise byte-identical between the two.
               (c) FastProjectile + A_Weave is a known-awkward combination
                   (FastProjectile advances in sub-steps inside one Tick; A_Weave
                   applies a positional offset). Worth watching on screen.
```

---

# 7. EVERY REFERENCED ACTOR, BY NAME, WITH ITS DEFINITION SITE

## 7.1 Attack-carrying actors

| actor | defined at | what it is |
|---|---|---|
| `BulletPuff_C` | `CHP/DECORATE/01/01_C.txt:1173-1175` | `Actor BulletPuff_C : BulletPuff { }` — an **empty** subclass of the engine's BulletPuff. Its siblings `_G`/`_B`/`_P` (1177, 1182, 1187) each add one `Translation`; `_C` adds nothing. All five tiers use `_C`. |
| `Gas11_C` | `CHP/DECORATE/01/01_G.txt:1410-1421` | poison cloud, T01. Parent `Gas11` at `CH/decorate/Zombies.txt:989-1011`. |
| `IceZombieShot_C` | `CHP/DECORATE/01/01_CY.txt:934-957` | ice sliver, T03. Base `IceZombieShot` at `CH/decorate/Zombies.txt:211-234`. |
| `IceChunk_C` | `CHP/DECORATE.txt:279` — `Actor IceChunk_C : IceChunk { }` | shatter chunk, T03 death. `IceChunk` is defined in **neither CH nor CHP** — grep returns nothing — so it is the GZDoom built-in. |
| `Orbb11_C` | `CHP/DECORATE/01/01_P.txt:1332-1360` | seeker orb, T04. Base `Orbb11` at `CH/decorate/Zombies.txt:1245-1273`. |

## 7.2 Non-attack actors and tokens each tier references

| actor / item | defined at | role |
|---|---|---|
| `NewIconCHP_T1_C` (T00) | `CHP/DECORATE/MISC/icons.txt:1` | `Actor NewIconCHP_T1_C : Nothin {}` — **a no-op.** All 112 `NewIconCHP_*` (no numeral) entries are `: Nothin {}` (`grep -c ": Nothin {}"` = 112, lines 1–112), i.e. the Common *tier* deliberately shows no colourblind glyph. `Nothin` is at `CHP/DECORATE.txt:11`. |
| `NewIconCHP2_T1_C` (T01) | `CHP/DECORATE/MISC/icons.txt:251-272` | real icon: sprite `TI3R B 1 Bright`, `A_Warp(AAPTR_MASTER,0,0,64,...)`, gated on `CallACS("CH_ColorBlind") == 1`, exits when it receives `GoAway`. |
| `NewIconCHP3_T1_C` (T02) | `CHP/DECORATE/MISC/icons.txt:388-408` | as above, sprite `TI3R C`. |
| `NewIconCHP22_T1_C` (T03) | `CHP/DECORATE/MISC/icons.txt:1484-1505` | as above, sprite **`OTIR C`** (different sprite family from the TI3R tiers). |
| `NewIconCHP4_T1_C` (T04) | `CHP/DECORATE/MISC/icons.txt:525-545` | as above, sprite `TI3R D`. |
| `GoAway` | `CHP/DECORATE.txt:1-4` — `Inventory.MaxAmount 1` | the icon kill-switch. `A_GivetoChildren("GoAway",1)` on death reaches the icon because Spawn set it with `SXF_SETMASTER`. |
| `CHWhitePlan` | `CHP/DECORATE/01/01_W.txt:9430-9433` — `Inventory.MaxAmount 1` | flag that routes Death into `Tick`/`Tickles`. |
| `WhiteZombiePlan_C` | `CHP/DECORATE/01/01_W.txt:8930-8961` | parent `ThePlanBoner` (`CH/decorate/Zombies.txt:2046-2078`). Reads `CallACS("CH_WZPlan")`; on 1 always, on 2 with an 85/256 `A_Jump`, on 3 never; hatches `BBBN BCD` and spawns `MrBones_C` (`CHP/DECORATE/01/01_W.txt:2980`). |
| `CHAbyssMark` | `CH/DECORATE.txt:895-898` — `Inventory.MaxAmount 1` | flag that routes Death into `AbyssGrow`. |
| `GrowRaisin` | `CH/DECORATE.txt:885-888` — `Inventory.MaxAmount 1` | flag that routes Raise into `Grow`. |
| `SplashAbyss_C` | `CHP/DECORATE/03/03_A.txt:1979-1984` | `: SplashAbyss` (`CH/decorate/Imps.txt:637`), `Speed 16 / FastSpeed 23` + Translation. 45 of them per AbyssGrow. |
| `CommonAbyssZombieClone` | `CHP/DECORATE/01/01_A.txt:1111-1115` | `: CommonAbyssZombie`, `Health 140 / Speed 10`. The AbyssGrow product for all four of T00/T01/T02/T04. |
| `CHRandom_GibGenerator` | `CH/Gibs.txt:3-40` | 8-way `A_Jump(255,1,2,...,8)` picking `CHGore_Gib1..8`. Six invocations per XDeath (two lines of `TNT1 AAA 0`). |
| `implyingclip` | `CH/DECORATE.txt:871-882` | `: ScootDropChecker`; drops `RLClip` or `CH_Clip` depending on the weapon set. Inherited DropItem on all five tiers. |
| `AbyssZombie2` / `AbyssZombie3` | `CH/decorate/Zombies.txt:782-786` (`AbyssZombie3`) | referenced only from the inherited `Pain.AbyssPE` / CH-side `AbyssGrow`. |

## 7.3 Grow / AbyssGrow targets (out of my five tiers, named for completeness)

* T00 → `CommonGreenZombie` (`01_C.txt:60`) = T01, this document.
* T01 → `CommonBlueZombie` (`01_G.txt:73`) = T02, this document.
* T02 → `CommonPurpleZombie` (`01_B.txt:64`) = **T04**, this document. Cyan is skipped.
* T03 → nothing. No Grow, no Raise.
* T04 → nothing. No Grow state.
* All four Grow-capable tiers AbyssGrow into `CommonAbyssZombieClone`
  (`01_C.txt:67`, `01_G.txt:80`, `01_B.txt:71`, `01_P.txt:73`).

---

# 8. ACS — every script in reach, opened and quoted

None of the five `Common*Zombie` actors calls ACS. The three scripts reachable
from actors they spawn are all one-line CVar readers:

```
CHP/source/CHSett2.acs:177-180
    Script "CH_ColorBlind" (void)
    {
        SetResultValue(GetCVar("CH_ColorBlind"));
    }

CHP/source/CHSett2.acs:74-77
    Script "CH_WZPlan" (void)
    {
        SetResultValue(GetCVar("CH_WZPlan"));
    }

CHP/source/CHSett2.acs:207-210
    Script "CH_Cyan" (void)
    {
        SetResultValue(GetCVar("CH_Cyan"));
    }
```

CVar defaults: `CH_WZPlan = 1` (`CHP/CVARINFO.txt:4`),
`CH_CyanSubtier = 1` (`CHP/CVARINFO.txt:16`), `CH_Cyan = 1`
(`CH/CVARINFO.txt:12`), `CH_ColorBlind = 0` (`CH/CVARINFO.txt:17`).

`CH_Cyan` is consumed by the **spawner**, not by the monster:
`CommonCyanZombieCheck` (`CHP/DECORATE/MISC/op_m_checks.txt:590-605`) reads it
and either re-rolls through `CHPZombieSpawnerCustom` or spawns
`CommonCyanZombie`. `CH_ColorBlind` is read once per icon spawn. `CH_WZPlan`
is read once per `WhiteZombiePlan_C`.

**Per rs_21 §2 line 93-94 these are cosmetic-and-configuration, and the bodies
are quoted above as the required evidence.** There is no hidden behaviour in
the ACS for this family in this tier range — no pack buffs, no resistance auras,
no lead-fire. (Which is worth stating explicitly, because rs_21:68-73 records
that exactly this assumption was made wrongly before. Here it was checked by
opening the files, and the file bodies are three lines each.)

---

# 9. THINGS IN THESE FIVE TIERS THAT LOOK LIKE CHP BUGS

## 9.1 CONFIRMED BUG — `misc/gibbed/c` does not exist. Four of five tiers gib silently.

All four tiers with an XDeath call it:

```
CHP/DECORATE/01/01_C.txt:43   TNT1 A 0 A_Playsound("misc/gibbed/c")
CHP/DECORATE/01/01_G.txt:55   TNT1 A 0 A_Playsound("misc/gibbed/c")
CHP/DECORATE/01/01_B.txt:48   TNT1 A 0 A_Playsound("misc/gibbed/c")
CHP/DECORATE/01/01_P.txt:59   TNT1 A 0 A_Playsound("misc/gibbed/c")
```

The only definition of anything resembling it, in either SNDINFO, is:

```
CHP/SNDINFO.txt:1528   misc/Gibbed/G			dsslop
```

`grep -rin "gibbed" CH/SNDINFO.txt CHP/SNDINFO.txt` returns **that one line and
nothing else**. There is no `misc/gibbed/c` and no unsuffixed `misc/gibbed`.

The root cause is visible one grep further out. CHP's SNDINFO was produced by a
blind letter substitution that replaced the colour letter *inside the word*:

```
CHP/SNDINFO.txt:1528    misc/Gibbed/G   dsslop
CHP/SNDINFO.txt:3015    misc/Bibbed/B   dsslop
CHP/SNDINFO.txt:4502    misc/Pibbed/P   dsslop
CHP/SNDINFO.txt:5989    misc/Yibbed/Y   dsslop
CHP/SNDINFO.txt:7476    misc/Ribbed/R   dsslop
CHP/SNDINFO.txt:8963    misc/Kibbed/K   dsslop
CHP/SNDINFO.txt:10450   misc/Wibbed/W   dsslop
CHP/SNDINFO.txt:14911   misc/Aibbed/A   dsslop
CHP/SNDINFO.txt:19372   misc/Fibbed/F   dsslop
```

`Gibbed` → `Bibbed`, `Pibbed`, `Yibbed`… Only the `/G` block survives, by luck,
because G is the letter that happened to already be there. So *every*
`A_Playsound("misc/gibbed/<x>")` in CHP is dead except `/g`. For our five tiers
the effect is: **T00, T01, T02 and T04 make no gib sound.** The port should
either drop the call or wire it to `dsslop` deliberately — but it must not
copy the string and assume it works.

The same defect hits the ice shatter: `misc/icebreak` is defined (`CHP/SNDINFO.txt:37`,
lump `ICEBREAK`) but `misc/icebreak/G` (`01_CY.txt:116`), `/B` (`01_CY.txt:177`)
and the rest are not — grep for "icebreak" over both SNDINFO files returns that
single line 37. **Our T03 uses the unsuffixed form and is fine**; its sibling
sub-variants are not.

## 9.2 CHECKED AND NOT A BUG — the inherited Translations are effectively inert

T03 clears its parent's tint with `Translation None` (`01_CY.txt:15`). T01, T02
and T04 do **not**, so they inherit CH's index-range remaps
(`CH/decorate/Zombies.txt:896`, `1040`, `1155`) — remaps that were authored for
the vanilla `POSS` sprite while CHP draws these tiers with bespoke `ZOMG`,
`ZOMB` and `BPOS` art. That reads like a double-tint bug, and I nearly filed it
as one. I decoded the actual lumps instead.

Decoding every `ZOMG*.lmp`, `ZOMB*.lmp` and `BPOS*.lmp` in
`CHP/sprites/zombies/` against `CHP/PLAYPAL.pal` and measuring what fraction of
solid pixels falls inside each translation's *source* ranges:

```
GreenZombie  translation vs ZOMG   41 lumps  37882 px   0.00% affected
BlueZombie   translation vs ZOMB   41 lumps  37882 px   1.51% affected
                                   (indices 160-167 only)
PurpleZombie translation vs BPOS   49 lumps  47102 px   0.01% affected
                                   (index 21 only)
```

The CHP artists drew these on palette ramps the CH translations do not read
from — ZOMG sits on 121–127 (green), ZOMB on 198–207 and 242 (blue), BPOS on
250–254 (purple), and none of those are source ranges in the inherited strings.
So the inherited tint is a near-total no-op and the sprites show as drawn.

**This confirms the claim already in our tree** at
`E:\RS_Main\zscript\monsters\RS_Zombieman.zs:147-151` — *"CHP gives each colour
its own ARTWORK, so no palette remap is needed or wanted"* — with the one
caveat that T02 does leave 1.51% of ZOMB's pixels being remapped (the 160–167
tan ramp → 198:205 blue), which is almost certainly the intent anyway. The
existing all-`-` TintTable is right.

## 9.3 CONFIRMED — `AttackSound` is declared on all five tiers and played by none

Every one of the five declares `AttackSound "grunt/attack"`
(`01_C.txt:7`, `01_G.txt:7`, `01_B.txt:7`, `01_CY.txt:9`, `01_P.txt:7`), and
none of the Missile chains contains an `A_PlaySound`. `A_PosAttack` — which CH's
own `GreenZombie` still uses at `CH/decorate/Zombies.txt:921` — plays
`AttackSound` internally; `A_CustomBulletAttack` and `A_CustomMissile` do not.
CHP replaced `A_PosAttack` with `A_CustomBulletAttack` throughout and did not
re-add the sound. **The Zombieman family fires silently in CHP.** This is the
single most audible difference from CH and it should be a deliberate decision in
the port, not an accident inherited a second time.

## 9.4 CONFIRMED — `spike/spiked` is undefined

`IceZombieShot_C` sets `DeathSound "spike/spiked"` (`01_CY.txt:947`), inherited
straight from CH (`CH/decorate/Zombies.txt:224`).
`grep -rin "spike/spiked" CH/SNDINFO.txt CHP/SNDINFO.txt` returns nothing. I am
not asserting the engine has no such sound — I am recording that neither mod
defines it, so if it plays at all it is from outside `ART SOURCE`.

## 9.5 SUSPICIOUS — `+THRUSPECIES` with no `Species`, and a doubled DamageFactor

```
CH/decorate/Zombies.txt:255   DamaGeFactor Fire,2.0
CH/decorate/Zombies.txt:256   DamageFactor "Fire",2.0
...
CH/decorate/Zombies.txt:262   +thruspecies
```

`CyanZombie2` declares `+thruspecies` but never declares `Species` — unlike
`CommonZombie` (792), `GreenZombie` (874) and `PurpleZombie` (1129), which all
set `Species "Zombie"`. What THRUSPECIES does on an actor with no species is
engine behaviour I will not guess at; flagged for the compiler and the game to
answer. The doubled Fire damage factor on 255/256 is harmless (same value) but
line 255 also has a typo in the property name's capitalisation (`DamaGeFactor`),
which DECORATE tolerates and ZScript may not.

## 9.6 COSMETIC — small copy-paste tells worth carrying a comment, not a fix

* `01_G.txt:12` — `Tag "\c[ColorG]Green Zombieman\c"` closes with `\c` instead
  of `\c-`. Every other tier here closes correctly.
* `01_G.txt:60-61` — frame `R` plays twice (`ZOMG PQR` then `ZOMG RST`).
  Identical in CH (`CH/decorate/Zombies.txt:971-972`).
* `01_B.txt:47` — `ZOMB M 0 A_GivetoChildren(...)` where every sibling uses
  `TNT1 A 0`. Zero tics, invisible.
* `01_G.txt:80`, `01_B.txt:71`, `01_P.txt:73` — `POSS A 0` inside otherwise
  ZOMG/ZOMB/BPOS actors, in AbyssGrow. Zero tics, invisible.
* `01_C.txt:28` uses the label `Tick:`; T01/T02/T04 renamed the identical state
  to `Tickles:`. Both are inherited spellings from CH (`Tick` at
  `CH/decorate/Zombies.txt:847`, `Tickles` at `956`). Not a conflict, but a port
  that unifies them should say so.
* `01_P.txt:50` uses count 1 on the `CHWhitePlan` check where T00/T01/T02 use
  count 0 — equivalent because MaxAmount is 1 (§5.3.2), but it will show up in
  any diff.
* T01's XDeath **ends in `Stop`** (`01_G.txt:65`), so the gibbed Green Common
  zombie's remains are removed from the world; T00, T02 and T04 all end
  `<frame> U -1` and leave a permanent gib pile. Inherited from CH
  (`CH/decorate/Zombies.txt:976`), but it is a visible inconsistency between
  adjacent tiers.

---

# 10. DISAGREEMENTS AND OPEN ITEMS

## 10.1 rs_21's own catalog example uses two axis values that do not exist

`docs/rs_21_port_law.txt:144-145`:

```
axes         : delivery:bullet payload:single element:ice
               trigger:semi archetype:hitscan
```

against `docs/rs_21_port_law.txt:162-166`, which says axes
*"must use ONLY values that already exist in the keyword system"* and that
inventing one *"breaks the query."*

Measured against the tree: `element:ice` — **zero occurrences** anywhere in
`E:\RS_Main\zscript\`. `archetype:hitscan` — **zero**. `delivery:hitscan` —
**zero**; the live `delivery:` values are `bullet`, `heavy`, `melee`, `radial`.
`trigger:semi` exists exactly **once** against 19 for `trigger:semiauto`, and no
`trigger:` value appears on any monster at all.

So rs_21's illustrative entry is, by rs_21's own rule, invalid. I have followed
the rule rather than the example: **the T03 ice bolt has no `element:` axis in
this document**, and I have not invented one. If `element:ice` is wanted (and
this family plus every Cyan tier of every other family will want it), the place
to add it is rs_17 §5, deliberately — not here.

Same for poison: T01's gas has no element axis either.

## 10.2 Two attacks in this range cannot be expressed as an RS_AttackProfile today

Recorded plainly rather than papered over, because rs_21 §2 line 100-105 asks
for the honest gap rather than the tidy reason:

* **T01's double-tap** (two identical shots 18 tics apart) and **T04's Orbb
  triple** (three projectiles 5 tics apart) are *bursts*, not *volleys*.
  `MakeVolley` puts every round out on one tic
  (`E:\RS_Main\zscript\systems\RS_AttackProfile.zs:404-424`). rs_17 §4 already
  names this exact hole and proposes `BurstCount`/`BurstDelayTics`
  (`docs/rs_17_attack_grammar.txt:137-138, 151-159`). Until that lands, faithful
  ports of these two must keep the spacing in the state chain, and the catalog
  entry above says so instead of claiming the profile is equivalent.
* **T04's `A_Monsterrefire(128,"See")` loop** — a 50% chance to repeat the whole
  attack — has no profile representation at all.
* **T00/T01's 22.5-degree spread** cannot be set through `MakeHitscan`, whose
  `spreadScale` is a multiplier on `(100 - Accuracy)`
  (`RS_AttackProfile.zs:71-84`), not degrees. `SpreadBonus` (flat degrees,
  `RS_AttackProfile.zs:80`) is the field that fits, but no factory takes it.

## 10.3 Left unresolved, deliberately

* Whether `Gas11_C`'s `A_Explode` default `XF_HURTSOURCE` lets the cloud hurt
  the zombie that dropped it, given `GreenZombie`'s `+DONTHARMSPECIES` /
  `Species "Zombie"`. Engine question.
* Whether `Renderstyle SoulTrans` + `Alpha 1` on T04 renders near-opaque or
  near-transparent. Engine question; matters visually.
* Whether `+THRUSPECIES` with no `Species` (T03) does anything. Engine question.
* The five tiers reference `Pain.AbyssPE` states in their CH parents that are
  reachable only from the Abyss Pain Elemental (family 10). They are transcribed
  by citation above but not by line here, because the actor that triggers them is
  outside this family. `CH/decorate/Zombies.txt:813-828` (T00), `927-942` (T01),
  `1064-1079` (T02), `300-315` (T03), `1190-1205` (T04).

---

## APPENDIX — tier stat comparison, CHP vs the CH parent it overrides

| | T00 C | T01 G | T02 B | T03 CY | T04 P |
|---|---|---|---|---|---|
| CHP Health | 20 | 30 | 40 | 30 | 65 |
| CH parent Health | (Zombieman 20) | 40 | 60 | 30 | 95 |
| CHP Speed | 7 | 9 | 9 | 9 | 10 |
| CHP PainChance | 200 | 180 | 140 | 40 | 120 |
| Radius / Height | 20/56 (engine) | 20/56 | 20/56 | 20/56 | 20/56 |
| BloodColor | red (default) | Green | red (default) | Blue | red (default) |
| Melee | none | none | none | none | none |
| Grow → | CommonGreen | CommonBlue | CommonPurple | — | — |
| Raise | yes | yes | yes | **no** | yes (no Grow) |
| XDeath | yes | yes (corpse removed) | yes | **no** | yes |
| attack cycle | 26 tics | 42 tics | 25 tics | 14 tics | 31 tics + refire |

Every `Common*` tier's CHP Health is **below** the CH parent it inherits from
(20 vs 20, 30 vs 40, 40 vs 60, 30 vs 30, 65 vs 95). The `Common` sub-variant is
CHP's *floor* for each tier; the coloured sub-variants scale up from there
(e.g. `GreenGreenZombie` Health 38, `01_G.txt:91`). Our per-tier stats should be
built from these Common numbers, not from CH's.
