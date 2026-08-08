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

# Zombieman (family 01) — DEEP READ, tiers T05–T09

Ground-truth transcription per `docs/rs_21_port_law.txt`. Nothing here is
inferred from a name; every claim carries FILE:LINE and every line was opened.

**Scope:** T05 (01_Y), T06 (01_A), T07 (01_F), T08 (01_BR), T09 (01_GY) —
the `Common<Colour>Zombie` actor of each file, per rs_21 §1 line 51.

**Path shorthand used throughout** (all under `E:\New folder\ART SOURCE\`):

| short | real path |
|---|---|
| `CHP/01/01_X.txt`   | `CHP\DECORATE\01\01_X.txt` |
| `CHP/NN/NN_X.txt`   | `CHP\DECORATE\NN\NN_X.txt` |
| `CHP/icons.txt`     | `CHP\DECORATE\MISC\icons.txt` |
| `CHP/DECORATE.txt`  | `CHP\DECORATE.txt` |
| `CH/Zombies.txt`    | `CH\decorate\Zombies.txt` |
| `CH/Imps.txt`       | `CH\decorate\Imps.txt` |
| `CH/Demons.txt`     | `CH\decorate\Demons.txt` |
| `CH/Barons.txt`     | `CH\decorate\Barons.txt` |
| `CH/Archviles.txt`  | `CH\decorate\Archviles.txt` |
| `CH/Gibs.txt`       | `CH\Gibs.txt` |
| `CH/DECORATE.txt`   | `CH\DECORATE.txt` |

---

## 0. FINDINGS UP FRONT

Read these before the transcriptions; several change what a correct port looks
like.

### 0.1 These five tiers call NO ACS. At all.

```
grep -niE "CallACS|ACS_Execute|ACS_NamedExecute" \
    CHP/DECORATE/01/{01_Y,01_A,01_F,01_BR,01_GY}.txt
  -> zero matches
```

Nor do their five CH parent actors (`CH/Zombies.txt:40-185`, `:359-471`,
`:492-612`, `:695-780`, `:1275-1409`) contain a single `CallACS`. The ACS in
CH's zombie chain lives *only* in the outer RandomSpawner shells
(`Actor BrownZombie` `CH/Zombies.txt:26-27` → `CallACS("CH_Brown")`;
`Actor GrayZombie` `:481` → `CallACS("CH_Grayscale")`;
`Actor AbyssZombie` `:628-629` → `CallACS("CH_Abyssmal")`), which are tier-roll
gates that RS's own tier system replaces. `YellowZombie` has no shell at all —
`Colourset2` drops it directly (`CH/Zombies.txt:12`).

Two ACS scripts *are* reachable, both indirectly and both cosmetic-with-evidence:

* `Script "CH_ColorBlind"` — `CHP/source/CHSett2.acs:177-180`, body verbatim:
  ```
  Script "CH_ColorBlind" (void)
  {
      SetResultValue(GetCVar("CH_ColorBlind"));
  }
  ```
  Read by every `NewIconCHP*_T1_C` tier marker (§6.6). It is a cvar read, nothing more.
* `Script "CH_WZPlan"` — `CHP/source/CHSett2.acs:74-77`, body verbatim:
  ```
  Script "CH_WZPlan" (void)
  {
      SetResultValue(GetCVar("CH_WZPlan"));
  }
  ```
  Read by `WhiteZombiePlan_C` (`CHP/01/01_W.txt:8939-8941`), the actor the
  `Tickles:` branch spawns. Also a cvar read.

**So for these five tiers rs_21's "read every ACS script" checkbox closes
clean.** Recording it explicitly because rs_21 §1 line 68 warns that the last
port dropped ACS tokens as empty wrappers without opening them — here they were
opened and are genuinely two cvar getters.

### 0.2 CHP BUG — `misc/gibbed/c` is defined nowhere. 88 call sites.

T05 (`CHP/01/01_Y.txt:74`), T06 (`CHP/01/01_A.txt:56`) and T08
(`CHP/01/01_BR.txt:99`) all play:

```
TNT1 A 0 A_Playsound("misc/gibbed/c")
```

The only `misc/Gibbed` entry in either SNDINFO is
`CHP/SNDINFO.txt:1528` → `misc/Gibbed/G            dsslop`.
There is no `/c` (Common) variant, and `CH/SNDINFO.txt` has no `misc/gibbed`
line at all. `grep -rn 'misc/gibbed/c"' CHP --include=*.txt | wc -l` → **88**.
Every Common-colour gib in CHP is silent. Not a transcription error on my part —
it is CHP's own hole, and a port that "fixes" it by pointing at `dsslop` is
adding a sound CHP does not play.

### 0.3 CHP BUG (probable) — T08's `AttackSound "SNPRFIRE"` can never fire.

`CHP/01/01_BR.txt:10` declares `AttackSound "SNPRFIRE"` (defined at
`CH/SNDINFO.txt:201` → `SNPRFIRE  SNPRFIRE`, so the sound is real). The Missile
state that would use it is:

```
CHP/01/01_BR.txt:37-41
Missile:
    SGAR F 10 A_FaceTarget
    SGAR G 10 BRIGHT A_CustomBulletAttack(5,0,1,10,"BulletPuff_C",0,CBAF_NORANDOM)
    SGAR F 10
    Goto See
```

`A_CustomBulletAttack` has no sound parameter and does not play `AttackSound`
(only `A_PosAttack`/`A_SPosAttack`-family and `A_CustomMeleeAttack` do). CH's
parent used `A_PosAttack` (`CH/Zombies.txt:92`), which *does* play AttackSound —
so CHP swapped the attack function, kept the sound property, and lost the crack
of the shot. Every colour in `01_BR.txt` has the same shape (e.g.
`GreenBrownZombie` at `:131` + `:162`), so it is systemic, not a one-off.
**Flagged, not "fixed": a port that adds `A_StartSound("SNPRFIRE")` is louder
than CHP.** Record it and let the owner decide.

### 0.4 CH BUG that CHP FIXED — swapped velocity/angle in the Abyss XDeath splash.

```
CH/Zombies.txt:774
  ABTR RSTU 5 A_Spawnitemex("SplashAbyss2",random(-24,24),random(-24,24),
                            random(8,64),0,0,random(-359,359),2,SXF_NOCHECKPOSITION)
```
`A_SpawnItemEx(class, xofs, yofs, zofs, xvel, yvel, zvel, angle, flags, ...)` —
so CH passes **zvel = random(-359,359)** and **angle = 2**. That is a ±359
units/tic vertical launch.

```
CHP/01/01_A.txt:61
  ABTR RSTU 5 A_Spawnitemex("SplashAbyss2_C",random(-24,24),random(-24,24),
                            random(8,64),0,0,2,random(-359,359),SXF_NOCHECKPOSITION)
```
CHP has zvel = 2, angle = random(-359,359). **Port CHP's order.** If a future
reader diffs against CH and "restores" the CH line, they are re-introducing the bug.

### 0.5 CH BUG, inherited live by T07 — `Pain.AbyssPE` removes the monster without `A_die`.

Every other member of this family ends `Pain.AbyssPE` with `TNT1 A 0 A_die`
before `Stop` — `CH/Zombies.txt:150` (BrownZombie2), `:314` (CyanZombie2),
`:560` (GrayZombie2), `:827` (CommonZombie), `:1377` (YellowZombie).
`FireBluZombie2`'s does not:

```
CH/Zombies.txt:427-428
    AYPB H 5 bright a_setscale(1,0.05)
    Stop
```

`Stop` outside a Death state destroys the actor outright, so the FireBlu zombie
converted by an Abyss Pain Elemental vanishes with **no kill credit, no drops,
no death sound**. CHP's `CommonFirebluZombie` does not override `Pain.AbyssPE`
(`CHP/01/01_F.txt:1-80` has no such label), so T07 inherits the bug verbatim.

### 0.6 Suspected engine-level bug in T08's leaps (present in CH too, so not a CHP regression).

```
CHP/01/01_BR.txt:48   SGAR F 1 thrustthing(angle,40,0,0)
CHP/01/01_BR.txt:73   SGAR F 17 thrustthing(angle,14,0,0)
CH/Zombies.txt:102    SGAR F 1 thrustthing(angle,24,0,0)
CH/Zombies.txt:126    SGAR F 1 thrustthing(angle,14,0,0)
```
`ThrustThing(angle, force, nolimit, tid)` takes its angle in **byte-angle**
(256 = full circle). The actor property `angle` is in **degrees** (0–360).
Passing degrees where byte-angle is expected multiplies the intended heading by
360/256 = 1.40625, so a bodyguard facing 90° lunges toward ≈126.6°. That is
consistent with the "GET DOWN MR PRESIDENT" dive visibly missing.
**NOT VERIFIED IN ENGINE — flagged as suspicion with the arithmetic shown.**
`ThrustThingZ(0,30,0,0)` on the preceding line is fine: its units are 1/4 map
unit, so 30 → 7.5 u/tic up.

### 0.7 T08's POSS gib frames are a HARD requirement, not a slip.

The prompt flagged this; here is the evidence, which is stronger than "deliberate":

```
find CH/sprites/brownnoise/getdownmrpresident -iname "SGAR*"  ->  frames A..M only
```

`SGAR` **has no frames N through U.** The Death state uses `SGAR I J K L M`
(`CHP/01/01_BR.txt:88-93`) — the last frame the sprite set owns — and XDeath is
therefore *forced* onto vanilla `POSS M N O P Q R S T U`
(`CHP/01/01_BR.txt:98-105`), which are the IWAD zombieman's gib frames. CH did
exactly the same (`CH/Zombies.txt:163-169`).
**Do not "fix" this. There is no SGAR gib art to fix it with.**

Related hazard for the port, not for CHP: `SGAR` is also the lump prefix of
`ARTSOURCE2\SPRITES\WEAPONS\Slot 3\SSG\DualSSG\RightReload\SGARA0.png` …
`SGARR0.png` (18 files, frames A–R). If both ever land in the same sprite
namespace, the bodyguard body and an SSG reload animation collide, and the
weapon set covers *more* frames (A–R) so it wins on N–R. `SPRITES/humans`
carries a third 45-file `SGAR*` set. Worth a decision before either is copied in.

### 0.8 `element:ice` does not exist in this project's live keyword vocabulary.

rs_21's own worked example (`docs/rs_21_port_law.txt:143`) writes
`axes : delivery:bullet payload:single element:ice`. A sweep of every keyword
string literal in `zscript/` returns 72 values across 13 axes and **`element:ice`
is not one of them** (the only other hit anywhere is prose in
`docs/rs_09_affix_slate.txt:96`). This matters here because CHP's Abyss bolt is
literally `DamageType "Ice"` (`CH/Zombies.txt:652`) and the obvious axis is
unavailable. Per rs_21 §4 ("If nothing fits, the axis vocabulary gets extended
deliberately, in rs_17, not quietly here") I have used **`element:void`**, which
IS live and is what RS already uses for abyss-flavoured content
(`zscript/monsters/RS_MonsterStages.zs:559`, `:806`;
`zscript/monsters/RS_ExBosses.zs:216`), and flagged the mismatch in each entry's
`notes`.

Live vocabulary actually used below (all verified present in a declared keyword
string, not a comment):
`species:zombieman · role:fodder|skirmisher|artillery|bruiser · delivery:bullet|heavy|melee|radial ·
element:kinetic|thermal|explosive|void · payload:single|multi · mobility:ground · trait:summoned`

Deliberately **not** used, because they appear only inside comments and are not
live: `payload:explosive` (`zscript/weapons/weaponfx/RS_FX_BallisticFired.zs:71`),
`payload:cluster` (`zscript/weapons/RS_Weapon.zs:763`),
`payload:slug` (`zscript/systems/RS_AffixIngredients.zs:16`).

### 0.9 One attack in this set cannot be expressed by RS_AttackProfile at all.

T06's Abyss-mark aura (§2.4 A2) grants an **inventory token to nearby allies**.
`RS_AttackProfile` (`zscript/systems/RS_AttackProfile.zs`) has `MakeRadial`
(damage / heal / hitsAllies, lines 450-468) and `MakeSelfBuff` (lines 472-490),
but no "grant item / apply status to others" mode. Recorded as a gap, not
papered over.

Two more, smaller: `MakeHitscan` (`:319-345`) has **no bullet-count parameter**
(the weapon side gets pellets from the weapon's own rolled `PelletCount`), so a
monster hitscan of *n* bullets has nowhere to put *n*; and neither
`MakeVolley` nor `MakeHeavy` carries a spawn **X/Y offset**, which CHP uses on
every `A_CustomMissile` here (`spawnofs_xy` 2 / 3 / 1).

---

## 1. TIER T05 — `CommonYellowZombie` (01_Y, "Yellow Zombiewoman")

* CHP actor: `CHP/01/01_Y.txt:1-88` — `ACTOR CommonYellowZombie : YellowZombie`
* CH parent: `CH/Zombies.txt:1275-1409` — `ACTOR YellowZombie : Zombieman`
* Body sprite: `CZOW` (`CH/sprites/zombies/CZOW*`, frames **A–W**, all used frames exist)

### 1.1 Properties (CHP wins; CH fills)

| property | value | source |
|---|---|---|
| Health | 90 | CHP `01_Y.txt:3` (overrides CH 140 @ `Zombies.txt:1277`) |
| Speed | 13 | CHP `01_Y.txt:4` (CH also 13 @ `:1285`) |
| PainChance | 100 | CHP `01_Y.txt:5` (CH also 100 @ `:1288`) |
| Radius | 19 | CH `Zombies.txt:1286` — CHP does not restate |
| Height | 52 | CH `Zombies.txt:1287` |
| Mass | 90 | CH `Zombies.txt:1278` |
| Scale | not set anywhere in the chain → engine default 1.0 | — |
| GibHealth | not set → engine default | — |
| Species | `"Zombie"` | CH `Zombies.txt:1279` |
| BloodColor | `"Yellow"` | CH `Zombies.txt:1280` |
| DamageFactor Melee | 2 | CH `Zombies.txt:1281` |
| DamageFactor "Exorcist" | 3.0 | CH `Zombies.txt:1282` |
| DamageFactor "DIMp" | 0 | CH `Zombies.txt:1283` |
| PainChance "DIMp" | 0 | CH `Zombies.txt:1284` |
| Translation | **inherited, NOT cleared** — `"168:191=160:167","152:159=164:167","40:47=232:235","32:39=213:223","26:31=248:248"` | CH `Zombies.txt:1307` |
| Flags | `MONSTER`, `+FLOORCLIP`, `+Missilemore`, `+Avoidmelee`, `+Dontharmspecies` | CH `Zombies.txt:1302-1306` |
| SeeSound | `"lady/aggro"` | CH `Zombies.txt:1290` (`CH/SNDINFO.txt:1100`) |
| PainSound | `"lady/hurt"` | CH `Zombies.txt:1291` (`CH/SNDINFO.txt:1102`) |
| DeathSound | `"lady/die"` | CH `Zombies.txt:1292` (`CH/SNDINFO.txt:1101`) |
| ActiveSound | `"lady/active"` | CH `Zombies.txt:1293` (`CH/SNDINFO.txt:1103`) |
| AttackSound | none declared in CHP or in `YellowZombie`; inherits GZDoom `Zombieman`'s `"grunt/attack"` | — |
| Obituary | `"%o was shown that the \c[ColorY]Yellow zombie\c- was a tough lady"` | CHP `01_Y.txt:6` |
| HitObituary | **not defined anywhere in the chain** | — |
| Tag | `"\c[ColorY]Yellow Zombiewoman\c-"` | CHP `01_Y.txt:7` |
| MeleeRange / MeleeDamage / MeleeSound | **not declared by CHP, by `YellowZombie`, or used at all** — no Melee state exists | — |
| DropItem | inherited from CH `Zombies.txt:1294-1301`: `implyingclip`, `implyingclip`,128, `implyingclip`,128, `CH_RocketAmmo`, `CH_RocketBox`,12, `CH_Medikit`,160, `CH_RocketLauncher`,24, `RLDuelistArmorPickup`,32 | — |

**T05 is the only one of my five that does NOT clear its palette remap.** T06,
T07 and T09 all declare `Translation None` (`01_A.txt:13`, `01_F.txt:14`,
`01_GY.txt:15`); T08 has none to clear (`BrownZombie2` declares no Translation).
T05 declares nothing, so `YellowZombie`'s five-range index remap
(`CH/Zombies.txt:1307`) is applied on top of the bespoke `CZOW` art. Whether
that is intentional in CHP or an oversight I cannot tell from the file — but it
is a real, visible difference and it must be ported *as CHP has it*.

### 1.2 Full state transcription — `CHP/01/01_Y.txt:8-87`

```
 10  Spawn:
 11      CZOW A 0 Nodelay A_SpawnitemEx("NewIconCHP5_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
                                         (falls through into Idle)
 12  Idle:
 13      CZOW AB 10 A_Look
 14      Loop
 15  See:
 16      CZOW AABBCCDD 4 A_Chase
 17      Loop
 18  Dodger:
 19      CZOW AABBCCDD 4 A_Fastchase
 20      CZOW A 0 A_Jump(88,"see")
 21      Loop
 22  Missile:
 23      CZOW E 5 A_FaceTarget
 24      CZOW E 0 A_JumpIfCloser(550,"Bullets")
 25      CZOW E 0 A_Jump(256,"RocketsOr")
 26      Goto See
 27  RocketsOr:
 28      CZOW E 0 A_Jump(255,"Rockets","Bullets")
 29      Goto See
 30  Bullets:
 31      CZOW F 0 A_Playsound("chainguy/attack")
 32      CZOW F 3 Bright A_Custombulletattack(4,4,1,random(1,3),"BulletPuff_C")
 33      CZOW E 2 A_FaceTarget
 34      CZOW F 3 Bright A_Custombulletattack(7,7,1,random(1,3),"BulletPuff_C")
 35      CZOW E 2 A_FaceTarget
 36      CZOW F 3 Bright A_Custombulletattack(9,9,1,random(1,3),"BulletPuff_C")
 37      CZOW E 2 A_Monsterrefire(128,"See")
 38      Goto Missile
 39  Rockets:
 40      CZOW F 0 A_JumpIfInventory("RocketCounter",3,"Jammed")
 41      CZOW F 3 Bright A_Custommissile("MiniRKTZombie_C",32,2,random(-2,2))
 42      CZOW E 2 A_giveInventory("RocketCounter",1)
 43      CZOW E 2 A_Monsterrefire(128,"See")
 44      Goto Missile
 45  Jammed:
 46      CZOW E 0 A_ChangeFlag("NOPAIN",TRUE)
 47      CZOW E 10 A_Playsound("Jam/Jamd",0,1.9)
 48      CZOW A 18 A_FaceTarget
 49      CZOW E 10 A_Playsound("Jam/Jamd",0,1.9)
 50      CZOW E 10 A_Playsound("Jam/Jamd",0,1.9)
 51      CZOW E 10 A_Playsound("Jam/Jamd",0,1.9)
 52      CZOW G 16 A_TakeInventory("RocketCounter",3)
 53      CZOW A 16 A_Playsound("Lady/Active")
 54      CZOW A 0 A_ChangeFlag("NOPAIN",False)
 55      Goto See
 56  Pain:
 57      CZOW G 3
 58      CZOW G 3 A_Pain
 59      Goto Dodger
 60  Tickles:
 61      TNT1 A 0 A_Spawnitemex("WhiteZombiePlan_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION)
 62      Goto Death+2
 63  Death.Ice:
 64  Death:
 65      TNT1 A 0 A_GivetoChildren("GoAway",1)
 66      CZOW H 5 A_JumpIfInventory("CHWhitePlan",1,"Tickles")
 67      CZOW I 5 A_Scream
 68      CZOW J 5 A_Fall
 69      CZOW KLM 5
 70      CZOW N -1
 71      Stop
 72  XDeath:
 73      TNT1 A 0 A_GivetoChildren("GoAway",1)
 74      TNT1 A 0 A_Playsound("misc/gibbed/c")
 75      TNT1 AAA 0 A_SpawnItemEx("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
 76      CZOW O 5
 77      CZOW P 5 A_XScream
 78      CZOW Q 5 A_Fall
 79      CZOW RSTUV 5
 80      TNT1 AAAAA 0 A_Spawnparticle("Yellow",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(1,13),frandom(0,360),0,0,24,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
 81      CZOW W -1
 82      Stop
 83  Raise:
 84      CZOW MLKJIH 5
 85      CZOW H 0 A_SpawnitemEx("NewIconCHP5_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
 86      Goto See
```

Repeat-run counts verified by character count, not by eye: line 75 `TNT1 AAA` = 3;
line 80 `TNT1 AAAAA` = 5.

**Inherited, not redefined by CHP:** `Pain.AbyssPE` (`CH/Zombies.txt:1363-1378`,
16 lines, ends with `A_die` at `:1377`). `YellowZombie` defines no `Melee`,
`Grow` or `AbyssGrow` — so T05 cannot be Abyss-converted or Raise-grown, unlike
T07/T08/T09. That is CH's own asymmetry, faithfully carried.

**CHP vs CH deltas worth knowing:**
* CH's XDeath spawns `CH_Pantsu` (`CH/Zombies.txt:1402`). CHP dropped it.
* CH's `Death` has `CZOW K 5` and `CZOW LM 5` as two lines (`:1391-1392`); CHP
  merged to `CZOW KLM 5` (`:69`). Identical timing.
* CHP added the `BulletPuff_C` argument (CH's `A_Custombulletattack(4,4,1,random(1,3))`
  at `:1339` used the default `BulletPuff`).
* CHP's `Dodger` is one 8-frame line; CH's is two 4-frame lines with icon spawns
  interleaved (`:1322-1326`). Same tics.
* CHP's `Tickles` targets `Death+2`, CH's targets `Death+1` (`:1386`) — correct
  in both, because CHP prepends the `A_GivetoChildren` frame.

### 1.3 Branch logic, stated plainly

`Missile` faces for 5 tics, then: **target closer than 550 → `Bullets`, always.**
Otherwise `A_Jump(256,…)` (256/256 = certain) to `RocketsOr`, which is
`A_Jump(255,"Rockets","Bullets")` — a 255/256 chance to pick one of the two
labels at random, i.e. ~49.8% rockets / ~49.8% bullets / 0.4% fall through to
`Goto See`. **Rockets are a long-range-only option.**

`Rockets` is gated by `RocketCounter` (`Actor RocketCounter : Inventory
{ Inventory.MaxAmount 3 }` — `CH/Zombies.txt:1439`). Rockets 1, 2, 3 fire and
increment; the 4th attempt jams. `Jammed` costs **90 tics** (10+18+10+10+10+16+16)
during which `NOPAIN` is on (so it does not flinch out of the jam), then
`A_TakeInventory("RocketCounter",3)` resets it. This is a real
ammo-and-cooldown mechanic, not dressing.

`Pain` routes to `Dodger`, not `See` — after being hurt she strafes with
`A_FastChase` until an `A_Jump(88,"see")` (88/256 ≈ 34% per 32-tic cycle) drops
her back to normal chase.

---

### 1.4 CATALOG — T05

```
## YellowZombiewomanBurst      zscript/monsters/Zombieman/attacks/RS_Zombieman_YellowBurst.zs
kind         : three-round rifle burst that walks wider with each shot
axes         : delivery:bullet payload:single element:kinetic
               species:zombieman role:skirmisher mobility:ground trigger:burst
tier(s)      : T05 Yellow (Zombieman) — CommonYellowZombie
chp source   : CHP/DECORATE/01/01_Y.txt:30-38   (Bullets:)
acs          : none — see §0.1
fires        : hitscan, 1 bullet per pull, 3 pulls per Missile entry.
               cone 4x4 deg, then 7x7, then 9x9 (CHP:32,34,36)
               puff RS_BulletPuff_C (CHP/DECORATE/01/01_C.txt:1173)
damage       : per bullet = random(1,3) * random(1,3)      <- KEEP AS A ROLL
               CHP writes damageperbullet = random(1,3) and does NOT pass
               CBAF_NORANDOM, so GZDoom multiplies by its own random(1,3).
               Range 1..9, mode 4. NOT "5", NOT "2".
sprites      : CZOW F (muzzle, Bright) / CZOW E (recover)
sounds       : fire = "chainguy/attack" played once at CHP:31, before the
               volley, NOT per shot. see=lady/aggro pain=lady/hurt
               death=lady/die active=lady/active
behaviour    : Her close-range answer. Under 550 units she always takes this
               and never the rockets. Three shots at 3-tic intervals with a
               2-tic re-face between them, and the cone opens 4->7->9 degrees
               as the burst walks off target, so the first round is the one
               that hurts and standing still through all three is what kills
               you. Ends on A_MonsterRefire(128,"See") — a coin flip to run
               the whole Missile decision again rather than disengage.
profile      : RS_AttackProfile.MakeHitscan(
                   fireSnd: "chainguy/attack", spreadScale: <4|7|9 deg>,
                   ammoCost: 0, profName: "Walking Burst",
                   impactPuff: "RS_BulletPuff_C")
               x3 beats in the slot, one per widening cone.
notes        : MakeHitscan has no bullet-count field (RS_AttackProfile.zs:319-345);
               fine here because numbullets is 1, but the gap is real for any
               monster that fires n>1 per call.
               The single pre-volley sound is a shape MakeHitscan cannot express
               either (FireSound is per-beat). Three beats = three cracks.
```

```
## YellowZombiewomanRocket     zscript/monsters/Zombieman/attacks/RS_Zombieman_YellowRocket.zs
kind         : pocket rocket launcher that jams after three
axes         : delivery:heavy payload:single element:thermal
               species:zombieman role:artillery mobility:ground
tier(s)      : T05 Yellow (Zombieman) — CommonYellowZombie
chp source   : CHP/DECORATE/01/01_Y.txt:39-44   (Rockets:)
               CHP/DECORATE/01/01_Y.txt:45-55   (Jammed:)  -- the cooldown
acs          : none
fires        : RS_MiniRKTZombie_C x1, spawn height 32, lateral offset 2,
               angle random(-2,2)      (CHP/DECORATE/01/01_Y.txt:41)
damage       : impact  random(5,40)     (CHP/DECORATE/01/01_Y.txt:1487)
               splash  random(5,15) over radius 58, DEHEXPLOSION
                                       (CHP/DECORATE/01/01_Y.txt:1502)
               DamageType Fire
sprites      : CZOW F (fire, Bright) / CZOW E (recover) / CZOW G + A (jam)
               projectile MISL A (flight) / MISL B C D (burst)
sounds       : see=weapons/rocklf  death=weapons/rocklx  jam="Jam/Jamd" x4
               at volume 1.9 (CH/SNDINFO.txt:1104 -> CORK), clear="Lady/Active"
behaviour    : Only offered beyond 550 units, and then only on a coin flip
               against the burst. Three rockets, roughly one every 7 tics,
               and then the launcher jams: 90 tics of her standing in the
               open thumping the breech four times, unable to flinch
               (NOPAIN is forced on for the whole window), before she clears
               it and resumes. The jam is the fight -- it is a guaranteed,
               self-inflicted punish window every three rockets.
profile      : RS_AttackProfile.MakeVolley(
                   proj: "RS_MiniRKTZombie_C", count: 1, arc: 4.0,
                   fireSnd: "weapons/rocklf", profName: "Jamming Rocket")
notes        : CHP CHANGED THE PARENT CLASS. CH's MiniRKTZombie is a plain
               Actor with Projectile (CH/Zombies.txt:1411-1437); CHP's
               MiniRKTZombie_C is ": FastProjectile" (CHP/.../01_Y.txt:1481)
               with every other property identical. At Speed 22 that means
               sub-stepped movement and different wall/actor contact
               behaviour. Do not port it as a plain projectile.
               The jam is a 3-shot magazine + 90-tic reload. RS_AttackProfile
               has no magazine or cooldown field on the monster side, so the
               jam must live in the monster's state machine, exactly as CHP
               does it. Recording that as a shape gap, not as "cosmetic".
               MakeVolley has no spawn-offset field for CHP's spawnofs_xy=2.
```

Non-attack mechanic, recorded so it is not lost: **`Dodger`**
(`CHP/01/01_Y.txt:18-21`) — a post-Pain evasion mode using `A_FastChase`,
entered from `Pain` (`:59`) and left on a 34% jump. It is a movement state, not
an attack, so it gets no catalog entry, but a port that routes `Pain → See` has
changed how she plays.

### 1.5 Referenced actors — T05

| actor | defined at | what it is |
|---|---|---|
| `MiniRKTZombie_C` | **CHP/DECORATE/01/01_Y.txt:1481-1507** | `: FastProjectile`; Radius 6, Height 4, Speed 22, `Damage (random(5,40))`, DamageType Fire, `Projectile`, `+RANDOMIZE +DEHEXPLOSION +ROCKETTRAIL`, Scale 0.4, See `weapons/rocklf`, Death `weapons/rocklx`. Spawn `MISL A 1 Bright` Loop; Death `MISL B 8 Bright A_Explode(random(5,15),58)` / `MISL C 6 Bright` / `MISL D 4 Bright` / Stop. |
| `MiniRKTZombie` (CH original, superseded) | CH/Zombies.txt:1411-1437 | identical numbers, **plain Actor** not FastProjectile |
| `BulletPuff_C` | **CHP/DECORATE/01/01_C.txt:1173-1175** | `Actor BulletPuff_C : BulletPuff {}` — empty body, pure alias. The `_G`/`_B`/… siblings at `:1177-1209` add Translations; `_C` adds nothing. |
| `RocketCounter` | CH/Zombies.txt:1439 | `Actor RocketCounter : Inventory { Inventory.MaxAmount 3 }` |
| `NewIconCHP5_T1_C` | CHP/DECORATE/MISC/icons.txt:662-683 | tier marker, sprite `TI3R E`; `+NOCLIP +NOBLOCKMAP +NOGRAVITY +NOTIMEFREEZE`, Scale 0.9; `A_JumpIf(CallACS("CH_ColorBlind")==1,"Show")`, else Stop; Show warps to master every tic and quits when it receives `GoAway` |
| `GoAway` | CHP/DECORATE.txt:1-4 | `Actor GoAway : Inventory { Inventory.MaxAmount 1 }` — the icon kill-switch |
| `WhiteZombiePlan_C` | CHP/DECORATE/01/01_W.txt:8930-8961 | `: ThePlanBoner`; Health 10, Speed 1, `+NOCLIP`; reads cvar `CH_WZPlan`, and on success hatches `MrBones_C` |
| `ThePlanBoner` | CH/Zombies.txt:2046-2080 | the CH base: Health 45, Radius 8, Height 16, Mass 1, `+float +Floatbob +Noradiusdmg`, sprite `BBBN` |
| `CHWhitePlan` | CHP/DECORATE/01/01_W.txt:9430-9433 | `Inventory`, MaxAmount 1 — the "you were killed by the White zombie's plan" mark |
| `CHRandom_GibGenerator` | CH/Gibs.txt:3-41 | 8-way `A_Jump` spawner for `CHGore_Gib1..8`, all `SXF_USEBLOODCOLOR` |

---

## 2. TIER T06 — `CommonAbyssZombie` (01_A, "Abyss Infected Zombie")

* CHP actor: `CHP/01/01_A.txt:1-69` — `Actor CommonAbyssZombie : AbyssZombie2`
* CH parent: `CH/Zombies.txt:695-780` — `actor AbyssZombie2` (a bare Actor, **not** `: Zombieman`)
* Body sprite: `ABTR` (`CH/sprites/AbyssTrooper/ABTR*`, frames **A–U**; all used frames exist)

### 2.1 Properties

| property | value | source |
|---|---|---|
| Health | 200 | CHP `01_A.txt:3` (CH also 200 @ `Zombies.txt:698`) |
| GibHealth | **-100** | CHP `01_A.txt:4` — CH sets none |
| Speed | 14 | CHP `01_A.txt:5` (CH also 14 @ `:702`) |
| PainChance | 18 | CHP `01_A.txt:6` (CH also 18 @ `:705`) |
| Radius | 20 | CH `Zombies.txt:699` |
| Height | 56 | CH `Zombies.txt:700` |
| Mass | 100 | CH `Zombies.txt:701` |
| Scale | not set → 1.0 | — |
| BloodColor | `"Black"` | CH `Zombies.txt:703` |
| Species | `"Zombie"` | CH `Zombies.txt:704` |
| DamageFactor "Exorcist" | 3.0 | CH `Zombies.txt:706` |
| DamageFactor "DIMp" | 0 | CH `Zombies.txt:707` |
| PainChance "DIMp" | 0 | CH `Zombies.txt:708` |
| Translation | **`None`** — explicitly cleared | CHP `01_A.txt:13` (overrides CH `"0:255=%[0.02,0.02,0.03]:[0.29,0.49,0.65]"` @ `:725`) |
| Flags | `MONSTER`, `+FLOORCLIP`, `+DONTHARMSPECIES`, `+Avoidmelee` | CH `Zombies.txt:720-723` |
| SeeSound | `"Zom2/see"` | CHP `01_A.txt:7` (`CH/SNDINFO.txt:1114`) |
| PainSound | `"Form2/hurt"` | CHP `01_A.txt:8` (`CH/SNDINFO.txt:1118`) |
| DeathSound | `"imp2/die"` | CHP `01_A.txt:9` (`CH/SNDINFO.txt:1095`) |
| ActiveSound | `"Form2/active"` | CHP `01_A.txt:10` (`CH/SNDINFO.txt:1119`) |
| AttackSound | **none anywhere in the chain** (parent is a bare Actor, so there is no `Zombieman` fallback either) | — |
| Obituary | `"%o was dragged down deep by \c[ColorA]Abyss Zombie\c-."` | CHP `01_A.txt:11` |
| HitObituary | not defined | — |
| Tag | `"\c[ColorA]Abyss Infected Zombie\c-"` | CHP `01_A.txt:12` |
| Melee* | no Melee state, no MeleeRange/MeleeDamage anywhere | — |
| DropItem | inherited CH `Zombies.txt:713-719`: `CH_Cell`, `implyingclip` x2, `HealthBundle`, `ArmorBundle`, `CH_Berserk`,64, `CH_cell`,128 | — |

### 2.2 Full state transcription — `CHP/01/01_A.txt:14-68`

```
 16  Spawn:
 17      ABTR A 0 Nodelay A_SpawnitemEx("NewIconCHP20_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
 18  Fling:
 19      ABTR A 0 A_Radiusgive("CHAbyssMark",528,RGF_MONSTERS|RGF_NOSIGHT|RGF_EXFILTER,1,"CommonAbyssZombie","Zombie")
 20  Idle:
 21      ABTR AB 10 A_Look
 22      loop
 23  See:
 24      ABTR AAB 2 A_chase
 25      TNT1 AAA 0 A_Spawnitemex("SplashAbyss_C",random(-8,8),random(-8,8),random(5,32))
 26      ABTR B 2 a_fastchase
 27      ABTR CCD 2 A_Chase
 28      TNT1 AAA 0 A_Spawnitemex("SplashAbyss_C",random(-8,8),random(-8,8),random(5,32))
 29      ABTR D 2 a_fastchase
 30      loop
 31  Missile:
 32      ABTR E 10 A_FaceTarget
 33      ABTR F 5 A_Custommissile("AbyssZshotCH_C",36,3,random(-7,1))
 34      ABTR F 5 A_Custommissile("AbyssZshotCH_C",36,3,random(-1,7))
 35      ABTR E 10
 36      goto See
 37  Pain:
 38      ABTR G 1
 39      ABTR G 1 A_Pain
 40      TNT1 [A x45] 0 A_Spawnitemex("SplashAbyss2_C",random(-178,178),random(-178,178),random(6,16),0,0,2,0,SXF_NOCHECKPOSITION)
 41      goto See
 42  Tickles:
 43      TNT1 A 0 A_Spawnitemex("WhiteZombiePlan_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION)
 44      Goto Death+2
 45  Death.Ice:
 46  Death:
 47      TNT1 A 0 A_GivetoChildren("GoAway",1)
 48      ABTR H 5 A_JumpIfInventory("CHWhitePlan",1,"Tickles")
 49      ABTR I 5 A_Scream
 50      ABTR J 5 A_NoBlocking
 51      ABTR KL 5
 52      ABTR L -1
 53      stop
 54  XDeath:
 55      ABTR M 5 A_GivetoChildren("GoAway",1)
 56      TNT1 A 0 A_Playsound("misc/gibbed/c")            <- silent, see 0.2
 57      ABTR N 5 A_XScream
 58      ABTR O 5 A_NoBlocking
 59      TNT1 AAAAA 0 A_Spawnparticle("Black",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(1,13),frandom(0,360),0,0,24,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
 60      ABTR PQ 5
 61      ABTR RSTU 5 A_Spawnitemex("SplashAbyss2_C",random(-24,24),random(-24,24),random(8,64),0,0,2,random(-359,359),SXF_NOCHECKPOSITION)
 62      ABTR U -1
 63      Stop
 64  Raise:
 65      ABTR KJIH 5
 66      ABTR H 0 A_SpawnitemEx("NewIconCHP20_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
 67      goto See
```

Repeat-run counts verified by character count: line 40 = **45** `A`s;
lines 25 / 28 = 3 each; line 59 = 5.

**Line 40 is the single biggest thing in this tier and it is easy to read past.**
45 separate `SplashAbyss2_C` on one 0-tic frame, scattered ±178 units in X and
Y. `SplashAbyss2_C` carries `Damage (random(1,9))` and `DamageType Ice`
(`CHP/DECORATE/03/03_A.txt:2088-2096`). That is a damaging nova **every time it
takes pain**, and at PainChance 18 it is rare enough to be a surprise.

**Inherited, not redefined:** nothing of consequence — `AbyssZombie2` defines no
`Pain.AbyssPE` (it *is* the abyss form), no `Melee`, no `Grow`, no `AbyssGrow`.

**CHP vs CH deltas:**
* `Fling`'s radiusgive changed materially — see the catalog entry below.
* `See`: CHP's fastchase frames are **2 tics**; CH's are 1 (`CH/Zombies.txt:740`, `:744`).
* `XDeath` reordered and the arg-swap bug fixed (§0.4). CH's version also lacks
  a terminating `Stop` (`CH/Zombies.txt:775` → falls into `Raise:`); CHP added it (`:63`).
* CHP added `Death.Ice:` (`:45`) so an ice death plays the normal death rather
  than the engine shatter. CH has no such label.

### 2.3 Branch logic

There is no branching. `Missile` always fires exactly two bolts and returns to
`See`. The variety is in the aim: `random(-7,1)` then `random(-1,7)`
(`:33`, `:34`) — the two bolts fan to opposite sides of the target, with a
1-degree overlap at centre. `A_CustomMissile(cls, spawnheight, spawnofs_xy, angle)`,
so both leave at height 36, offset 3 to the right.

### 2.4 CATALOG — T06

```
## AbyssBoltPair                zscript/monsters/Zombieman/attacks/RS_Zombieman_AbyssBolt.zs
kind         : twin void bolts, fanned left and right
axes         : delivery:heavy payload:multi element:void
               species:zombieman role:artillery mobility:ground
tier(s)      : T06 Abyss (Zombieman) — CommonAbyssZombie
chp source   : CHP/DECORATE/01/01_A.txt:31-36   (Missile:)
acs          : none
fires        : RS_AbyssZShotCH_C x2, sequential 5 tics apart,
               spawn height 36, lateral offset 3,
               angles random(-7,1) then random(-1,7)
damage       : impact  random(5,30)     (CHP/DECORATE/01/01_A.txt:1211)
               splash  random(1,8) over radius 42
                                       (CHP/DECORATE/01/01_A.txt:1225)
               DamageType "Ice"        (CH/decorate/Zombies.txt:652, inherited)
sprites      : ABTR E (wind-up) / ABTR F (release, x2) / ABTR E (recover)
               projectile BAL1 A B (weaving flight) / BAL7 C D E (burst)
sounds       : see="imp/attack"  death="imp/shotx"   (on the projectile)
               monster has NO AttackSound anywhere in the chain
behaviour    : Two slow black bolts, five tics apart, thrown wide of each
               other so they arrive as a pincer rather than a stream --
               dodging the first walks you into the second. Each one weaves
               as it flies (a_weave(2,1,2,0.1)) so it does not track a
               straight line, and each detonates for a small splash on
               contact. Total commitment is 30 tics with a 10-tic tell.
profile      : RS_AttackProfile.MakeVolley(
                   proj: "RS_AbyssZShotCH_C", count: 2, arc: 14.0,
                   fireSnd: "", profName: "Pincer Bolts")
notes        : arc 14 approximates CHP's two independent random(-7,1) /
               random(-1,7) draws; MakeVolley fires a symmetric fan on ONE
               tic, CHP fires two shots 5 tics apart. That 5-tic stagger is
               the attack's character and MakeVolley cannot express it --
               two single-count beats in the slot is the honest port.
               DamageType is literally "Ice" but element:ice is NOT a live
               axis value in this project (see 0.8); element:void chosen.
               MakeVolley has no spawn-offset field for spawnofs_xy=3.
```

```
## AbyssMarkAura                zscript/monsters/Zombieman/attacks/RS_Zombieman_AbyssMark.zs
kind         : infection aura — marks nearby zombies to rise again as abyss zombies
axes         : delivery:radial element:void
               species:zombieman role:summoner mobility:ground
tier(s)      : T06 Abyss (Zombieman) — CommonAbyssZombie
chp source   : CHP/DECORATE/01/01_A.txt:18-19   (Fling:)
acs          : none
fires        : nothing. A_RadiusGive("CHAbyssMark", 528,
               RGF_MONSTERS|RGF_NOSIGHT|RGF_EXFILTER, 1,
               filter "CommonAbyssZombie", species "Zombie")
damage       : none
sprites      : none (0-tic ABTR A)
sounds       : none
behaviour    : Fires ONCE, at spawn, and never again -- the state is a 0-tic
               frame between Spawn and Idle. Every monster of species
               "Zombie" within 528 units, through walls, that is not itself
               a CommonAbyssZombie, gets one CHAbyssMark. A marked zombie
               that later dies does not stay dead: its Death state jumps to
               AbyssGrow and it comes back as an abyss zombie
               (T07 CHP/DECORATE/01/01_F.txt:49 + :55-61;
                T08 CHP/DECORATE/01/01_BR.txt:92 + :107-113;
                T09 CHP/DECORATE/01/01_GY.txt:47 + :69-75).
               So one abyss zombie walking into a room of zombiemen quietly
               converts that room's corpses into more of itself. It is the
               family's only recruiting mechanic and it is invisible until
               something dies.
profile      : *** CANNOT BE EXPRESSED. *** RS_AttackProfile has MakeRadial
               (damage/heal/hitsAllies, RS_AttackProfile.zs:450-468) and
               MakeSelfBuff (:472-490) but no mode that grants an item or a
               status to OTHER actors. MakeRadial(radius:528, damage:0,
               heal:0, hitsAllies:true) is a no-op, not an approximation.
notes        : GAP, recorded per rs_21 line 100 rather than dropped.
               What is missing is one radial variant: "grant Class<Inventory>
               to actors matching species, count n". That is a payload axis
               addition, not a shape axis -- cheap.
               CHP vs CH: CH's call is A_Radiusgive("CHAbyssMark",528,
               RGF_MONSTERS,55,0,"Zombie") (CH/decorate/Zombies.txt:731) --
               amount 55 (meaningless, CHAbyssMark MaxAmount is 1, see
               CH/DECORATE.txt:895-898), no NOSIGHT, and no self-exclusion.
               CHP's is the corrected one. Port CHP's.
```

```
## AbyssFlinchNova              zscript/monsters/Zombieman/attacks/RS_Zombieman_AbyssNova.zs
kind         : flinch nova — a room-wide sheet of void shards when it is hurt
axes         : delivery:radial payload:multi element:void
               species:zombieman role:artillery mobility:ground
tier(s)      : T06 Abyss (Zombieman) — CommonAbyssZombie
chp source   : CHP/DECORATE/01/01_A.txt:37-41   (Pain:)
acs          : none
fires        : RS_SplashAbyss2_C x45 on one tic, positions
               random(-178,178) X, random(-178,178) Y, random(6,16) Z,
               zvel 2, angle 0
damage       : random(1,9) each, DamageType Ice
               (CHP/DECORATE/03/03_A.txt:2088-2096)
sprites      : ABTR G x2 (2 tics of flinch) then the shard field
               shards: BAL1 A B (12 tics each) / BAL7 C D E (burst)
sounds       : PainSound "Form2/hurt"
behaviour    : Hurt it and the floor answers. Forty-five falling shards
               appear across a 356x356 unit square centred on the zombie --
               larger than most rooms -- each doing a small ice hit if it
               lands on you. It flinches for two tics, not two frames of
               animation, so the nova is nearly instantaneous and the
               punishment for closing to melee is that shooting it at all
               fills the room. PainChance is only 18, which is what keeps
               this from being constant: roughly one hit in fourteen.
profile      : RS_AttackProfile.MakeRadial(
                   radius: 178.0, damage: <random 1..9 per shard>,
                   heal: 0, hitsAllies: false, profName: "Shard Fall")
notes        : MakeRadial applies ONE damage number over a radius; CHP
               spawns 45 independent projectiles, so coverage is patchy and
               a target can be hit 0..n times. The radial is an
               approximation and should be labelled as one, not as a port.
               Faithful alternative: MakeVolley(count:45, arc:360) -- but
               that fires from the actor outward, and CHP's shards rain
               DOWN at scattered XY. Neither factory has "scatter over an
               area"; recorded as a second, smaller gap.
               Note also this is a PAIN reaction, not a Missile branch --
               nothing in the PACK slot system currently triggers off pain.
```

```
## AbyssDeathSpill              zscript/monsters/Zombieman/attacks/RS_Zombieman_AbyssNova.zs
kind         : void shard spill from the corpse as it comes apart
axes         : delivery:radial payload:multi element:void
               species:zombieman role:artillery mobility:ground
tier(s)      : T06 Abyss (Zombieman) — CommonAbyssZombie
chp source   : CHP/DECORATE/01/01_A.txt:61   (XDeath:)
acs          : none
fires        : RS_SplashAbyss2_C x4 -- ONE PER FRAME of "ABTR RSTU 5",
               positions random(-24,24) XY, random(8,64) Z, zvel 2,
               angle random(-359,359)
damage       : random(1,9) each, DamageType Ice
sprites      : ABTR R S T U, 5 tics each
sounds       : "misc/gibbed/c" at :56 -- SILENT, see 0.2
behaviour    : Gibbing it is not free. Over the 20 tics its body takes to
               come apart it coughs four more shards straight up out of
               itself, so standing on top of the kill costs you a little.
               Small, but it is the reason you do not finish an abyss
               zombie point-blank with a shotgun.
profile      : RS_AttackProfile.MakeVolley(
                   proj: "RS_SplashAbyss2_C", count: 4, arc: 360.0,
                   pitchJitter: 60.0, profName: "Death Spill")
notes        : Four spawns from four FRAMES, not one call with count 4 --
               the multi-frame idiom CLAUDE.md records for A_Explode. Here
               it is deliberate (it staggers the spill across the gib
               animation) and converting it to a single burst changes the
               look. Same class of thing as the ~55 protected looping-
               explode sites.
               The CH original passed zvel and angle SWAPPED (see 0.4).
```

### 2.5 Referenced actors — T06

| actor | defined at | what it is |
|---|---|---|
| `AbyssZShotCH_C` | **CHP/DECORATE/01/01_A.txt:1208-1228** | `: AbyssZShotCH`. Speed 32, `Damage (random(5,30))`, See `imp/attack`, Death `imp/shotx`, Translation `"0:255=%[0.04,0.04,0.06]:[0.58,0.98,1.30]"`. States: `Spawn: TNT1 A 0` / `Fly: BAL1 A 2 Bright` , `BAL1 B 2 Bright a_weave(2,1,2,0.1)` Loop / `Death: TNT1 A 0 A_setscale(0.85,0.85)` , `BAL7 CDE 4 Bright A_Explode(random(1,8),42)` Stop. |
| `AbyssZShotCH` (CH base) | CH/Zombies.txt:643-675 | supplies what `_C` does not restate: Radius 3, Height 3, xscale 0.5, yscale 0.2, `DamageType "Ice"`, RenderStyle Add, Alpha 0.95, `Projectile`, `+RANDOMIZE`, `+dontharmclass`, Translation. **CHP's `_C` Fly state DROPS CH's `A_SpawnItemEx("AbyssShotIdentifier",…)` trail** (CH `:667`). |
| `AbyssZShotCH2_C` | CHP/DECORATE/01/01_A.txt:1456-1463 | Radius 2, Height 2, Speed 45 — **defined in the file but NOT used by `CommonAbyssZombie`**; the higher sub-variants use it. Recorded so nobody ports it as T06 content. |
| `AbyssZShotCH3_C` | CHP/DECORATE/01/01_A.txt:1591-1598 | Speed 60 — same, unused by Common. |
| `SplashAbyss_C` | **CHP/DECORATE/03/03_A.txt:1979-1984** | `: SplashAbyss`; Speed 16, FastSpeed 23, Translation `"0:255=%[0.04,0.04,0.06]:[0.58,0.98,1.30]"`. Base at `CH/Imps.txt:637-661`: Radius 6, Height 16, Speed 16, FastSpeed 23, `Projectile +RANDOMIZE +THRUACTORS -Nogravity`, Scale 0.3, `Spawn: BAL1 AB 12`, `BAL1 A 2 A_Jump(32,"Death")` Loop, `Death: BAL7 C 1 Bright A_SetScale(0.6)`, `BAL7 CDE 4 Bright`. **No Damage — purely visual.** |
| `SplashAbyss2_C` | **CHP/DECORATE/03/03_A.txt:2088-2097** | `: SplashAbyss_C`; Height 6 (`:2090`), Speed 34 (`:2091`), `Damage (random(1,9))` (`:2092`), `DamageType Ice` (`:2093`), `-thruactors +mthruspecies +dontharmclass`. **This one hurts.** CH base `SplashAbyss2` at `CH/Imps.txt:663-672`, identical numbers. |
| `CHAbyssMark` | CH/DECORATE.txt:895-898 | `Inventory`, MaxAmount 1 |
| `CommonAbyssZombieClone` | **CHP/DECORATE/01/01_A.txt:1111-1115** | `: CommonAbyssZombie { Health 140  Speed 10 }` — the weaker copy that T07/T08/T09's `AbyssGrow` spawns |
| `NewIconCHP20_T1_C` | CHP/DECORATE/MISC/icons.txt:1210-1231 | tier marker, sprite `OTIR A` |
| `WhiteZombiePlan_C`, `CHWhitePlan`, `GoAway` | as T05 §1.5 | — |

---

## 3. TIER T07 — `CommonFirebluZombie` (01_F, "Fireblu Zombieman")

* CHP actor: `CHP/01/01_F.txt:1-80` — `ACTOR CommonFirebluZombie : FirebluZombie2`
* CH parent: `CH/Zombies.txt:359-471` — `ACTOR FireBluZombie2` (bare Actor)
* Body sprite: `ZOMF` (`CHP/sprites/zombies/ZOMF*`, frames **A–U, X, Y, Z**; V and W do not exist and are not used)

### 3.1 Properties

| property | value | source |
|---|---|---|
| Health | 50 | CHP `01_F.txt:3` (overrides CH 70 @ `Zombies.txt:362`) |
| GibHealth | -5 | CHP `01_F.txt:4` (CH also -5 @ `:364`) |
| Speed | 12 | CHP `01_F.txt:5` (CH also 12 @ `:371`) |
| PainChance | 255 | CHP `01_F.txt:6` (CH also 255 @ `:372`) |
| Radius | 20 | CH `Zombies.txt:369` |
| Height | 56 | CH `Zombies.txt:370` |
| Mass | not set anywhere → engine default 100 | — |
| Scale | not set → 1.0 | — |
| Species | `"Zombie"` | CH `Zombies.txt:363` |
| BloodColor | not set anywhere | — |
| DamageFactor "Exorcist" | 3.0 | CH `Zombies.txt:365` |
| DamageFactor fire | **0.25** | CH `Zombies.txt:366` |
| DamageFactor "DIMp" | 0 | CH `Zombies.txt:367` |
| PainChance "DIMp" | 0 | CH `Zombies.txt:368` |
| Translation | **`None`** | CHP `01_F.txt:14` (overrides CH's long two-tone red/blue remap @ `Zombies.txt:386`) |
| Flags | `Monster`, `+FLOORCLIP`, `+DONTHARMSPECIES`, `+Missilemore` | CH `Zombies.txt:373-376` |
| SeeSound | `"grunt/sight"` | CHP `01_F.txt:7` |
| AttackSound | `"grunt/attack"` | CHP `01_F.txt:8` — **declared and never played**; no state in the actor calls a function that uses AttackSound |
| PainSound | `"grunt/pain"` | CHP `01_F.txt:9` |
| DeathSound | `"grunt/death"` | CHP `01_F.txt:10` |
| ActiveSound | `"grunt/active"` | CHP `01_F.txt:11` |
| Obituary | `"%o was killed by a... uhhh... \c[ColorF]flaming zombieman\c-?"` | CHP `01_F.txt:12` |
| HitObituary | **not defined — and this is the tier that kills you in melee.** See §3.4 | — |
| Tag | `"\c[ColorF]Fireblu Zombieman\c-"` | CHP `01_F.txt:13` |
| MeleeRange / MeleeDamage | **not declared anywhere**, though a `Melee` state exists — engine `Actor` defaults apply | — |
| DropItem | inherited CH `Zombies.txt:383-385`: `implyingclip` x2, `CH_RocketAmmo` | — |

### 3.2 Full state transcription — `CHP/01/01_F.txt:15-79`

```
 17  Spawn:
 18      ZOMF A 0 Nodelay A_SpawnitemEx("NewIconCHP23_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
 19  Idle:
 20      ZOMF AB 10 A_Look
 21      Loop
 22  See:
 23      ZOMF AABBCCDD 3 a_chase
 24      Loop
 25  See2:
 26      ZOMF AABB 2 A_Chase
 27      ZOMF A 0 A_SpawnItemEx("FireSGguy2_C",-6,0,3,-2,0,1,-180)
 28      ZOMF CCDD 2 A_Chase
 29      ZOMF A 0 A_SpawnItemEx("FireSGguy2_C",-6,0,3,-2,0,1,-180)
 30      Loop
 31  Missile:
 32      TNT1 A 0
 33      Goto see2
 34  Melee:
 35      ZOMF EF 5 bright A_FaceTarget
 36      ZOMF E 0 DamageThing(9999)
 37      Goto XDeath
 38  Pain:
 39      ZOMF G 3 A_SpawnItemEx("FireSGguy2_C",6,0,3,9,0,1,random(0,359))
 40      ZOMF G 3 A_Pain
 41      Goto See2
 42  Death.Ice:
 43  Death:
 44      TNT1 A 0 A_GivetoChildren("GoAway",1)
 45      ZOMF H 5 A_JumpIfInventory("CHWhitePlan", 0, "Tickles")
 46      ZOMF I 5 A_Scream
 47      ZOMF J 5 A_NoBlocking
 48      ZOMF K 5
 49      TNT1 A 0 A_JumpIfInventory("CHAbyssMark",1,"AbyssGrow")
 50      ZOMF L -1
 51      Stop
 52  Tickles:
 53      TNT1 A 0 A_Spawnitemex("WhiteZombiePlan_C",0,0,6,0,0,0,0, SXF_NOPOINTERS| SXF_NOCHECKPOSITION)
 54      Goto Death+2
 55  AbyssGrow:
 56      TNT1 [A x15] 0 a_Spawnparticle("Black",SPF_FULLBRIGHT | SPF_RELATIVE, random(27,74), random(9,15), frandom(0,360), 0,0,32, frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9), 0,0,-0.1, 0.98, -1)
 57      TNT1 [A x45] 0 A_Spawnitemex("SplashAbyss_C",random(-32,32),random(-32,32),random(2,16),0,0,2,random(-359,359),SXF_NOCHECKPOSITION)
 58      TNT1 A 8
 59      ZOMF A 0 A_Spawnitemex("CommonAbyssZombieClone",0,0,6,0,0,1,0,SXF_NOCHECKPOSITION|SXF_SETTARGET)
 60      TNT1 A 0 A_die
 61      Stop
 62  XDeath:
 63      TNT1 A 0 A_GivetoChildren("GoAway",1)
 64      ZOMF P 0 Bright A_PlaySound("weapons/rocklx",7,1)
 65      MISL X 6 Bright A_Explode(random(12,44),84)
 66      MISL Y 6 Bright A_Quake(20,12,0,64,0)
 67      TNT1 AAA 0 A_SpawnItemEx ("CHRandom_GibGenerator", 0,0,8, VelX,VelY,VelZ, 0, SXF_ABSOLUTEMOMENTUM | SXF_USEBLOODCOLOR | SXF_NOCHECKPOSITION)
 68      ZOMF AAAAA 0 A_SpawnItemEx("FireSGguy2_C",0,0,3,random(3,9),0,1,random(-359,359))
 69      ZOMF U 0 A_Custommissile("FireSGguy2_C",32,7)
 70      ZOMF U 0 A_Custommissile("FireSGguy2_C",32,-7)
 71      MISL Z 6 A_NoBlocking
 72      Stop
 73  Raise:
 74      ZOMF KJIH 5
 75      ZOMF H 0 A_SpawnitemEx("NewIconCHP23_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
 76      Goto See2
 77  Grow:
 78      Stop
```

Repeat-run counts verified: line 56 = 15 `A`s; line 57 = 45; line 67 = 3;
line 68 = 5. `MISL X`, `MISL Y`, `MISL Z` are **real** — `CHP/sprites/MISLX0.lmp`,
`MISLY0.lmp`, `MISLZ0.lmp` exist (they are CHP additions to the vanilla MISL set,
which is A–D only). `ZOMF U` also exists.

**`Missile` is a redirect, not an attack** (`:31-33`): it jumps straight to
`See2`. **T07 has no ranged attack at all.** Its "ranged" damage is the fire it
sheds while walking.

**`Grow: Stop`** (`:77-78`) — CHP deliberately disables CH's `Grow` state
(`CH/Zombies.txt:465-469`, which turned a raised FireBlu into a `PurpleZombie`).
`Stop` here destroys the actor, so anything that jumps to `Grow` vanishes.
Nothing in `CommonFirebluZombie` jumps to it (CH's `Raise` did, via
`A_JumpIfInventory("GrowRaisin",1,"Grow")` at `CH/Zombies.txt:462`; CHP's `Raise`
at `:73-76` dropped that check). So it is dead code CHP kept as a stub. Record
it, do not "restore" CH's version.

### 3.3 CHP vs CH deltas

* **Body sprite changed.** CH's `FireBluZombie2` uses vanilla `POSS` throughout
  (`CH/Zombies.txt:391`, `:395`, `:412`, `:434`…). CHP uses bespoke `ZOMF`.
* **`DamageThing(9999)` is NEW in CHP** (`01_F.txt:36`). CH's Melee is only
  `POSS EF 5 bright A_FaceTarget` / `Goto XDeath` (`CH/Zombies.txt:411-413`).
* `A_Explode(random(12,44),84)` — same numbers as CH (`:453`), but CHP moved the
  quake onto its own frame and dropped CH's `MISL C 6 Bright` framing.
* CH's `AbyssGrow` spawns `AbyssZombie2` (`:448`); CHP spawns
  `CommonAbyssZombieClone` (`:59`) — Health 140 / Speed 10 rather than 200/14.
* `A_JumpIfInventory("CHWhitePlan", 0, …)` at `:45` uses count **0**, whereas
  T05 (`01_Y.txt:66`) and T06 (`01_A.txt:48`) use count **1**. With count 0
  GZDoom jumps only when the actor holds the item's *maximum* amount; since
  `CHWhitePlan` is `Inventory.MaxAmount 1` (`CHP/01/01_W.txt:9430-9433`) the two
  forms are equivalent here. Inconsistent, not broken. T08 (`01_BR.txt:86`) and
  T09 (`01_GY.txt:43`) also use 0.

### 3.4 `DamageThing(9999)` — what I am confident of and what I am not

`DamageThing` is an action special, and in a DECORATE state the calling actor is
the activator, so the standard reading is **the zombie damages itself for 9999
and dies**. Supporting evidence from the file itself: the very next line is
`Goto XDeath` (`:37`), and 9999 against Health 50 / GibHealth -5 would send it to
XDeath anyway — the explicit goto is belt-and-braces for a suicide, not a
mechanism for killing a target. Against that reading: nothing in CHP declares a
`HitObituary`, which a melee that *killed the player* would want.

**Observable outcome is the same either way** — it detonates
(`A_Explode(random(12,44),84)` + quake + 7 fireballs). What is uncertain is
whether the player *also* eats 9999 on contact. **Not verified in engine.
Flagged for the owner's walkthrough.** I have written the catalog entry for the
self-damage reading and said so.

### 3.5 CATALOG — T07

```
## FirebluSuicideHug            zscript/monsters/Zombieman/attacks/RS_Zombieman_FirebluBlast.zs
kind         : suicide bomber — it walks into you and detonates itself
axes         : delivery:melee payload:multi element:explosive
               species:zombieman role:skirmisher mobility:ground
tier(s)      : T07 Fireblu (Zombieman) — CommonFirebluZombie
chp source   : CHP/DECORATE/01/01_F.txt:34-37   (Melee:)
               CHP/DECORATE/01/01_F.txt:62-72   (XDeath:, the payload)
acs          : none
fires        : self-kill, then the XDeath chain:
                 A_Explode(random(12,44), 84)          radius damage
                 A_Quake(20,12,0,64,0)                 20 intensity, 12 tics,
                                                       radius 64
                 RS_FireSGguy2_C x5  via A_SpawnItemEx, xvel random(3,9),
                                     zvel 1, angle random(-359,359)
                 RS_FireSGguy2_C x2  via A_CustomMissile, height 32,
                                     angles +7 and -7
damage       : blast    random(12,44) over radius 84   (01_F.txt:65)
               each fireball  random(5,15)             (CH/decorate/Archviles.txt:2291)
               fireball splash random(3,9) over 32, then no further explode
                                                       (CHP/DECORATE/14/14_F.txt:2002)
sprites      : ZOMF E F (lunge, Bright) / MISL X Y Z (the blast)
sounds       : "weapons/rocklx" on channel 7 at volume 1 (01_F.txt:64)
behaviour    : It does not punch. It runs at you on fire, and when it is close
               enough for a melee it kills itself: an 84-unit blast, a screen
               quake, and seven fireballs thrown outward that keep burning
               where they land. Health 50 and PainChance 255 mean it flinches
               constantly and dies to almost anything -- the fight is entirely
               about whether you kill it before it arrives, because arriving
               IS the attack. DamageFactor fire 0.25 means burning it is the
               slow way.
profile      : RS_AttackProfile.MakeRadial(
                   radius: 84.0, damage: <random 12..44>, heal: 0,
                   hitsAllies: false, fireSnd: "weapons/rocklx",
                   profName: "Detonate")
               + RS_AttackProfile.MakeVolley(
                   proj: "RS_FireSGguy2_C", count: 7, arc: 360.0,
                   pitchJitter: 20.0, profName: "Burst Embers")
notes        : Needs BOTH profiles on one beat -- RS_AttackProfile is
               one-mode-per-profile, so a self-detonation that is
               simultaneously a radial and a 7-way volley needs two slots
               fired together, or a state that fires both. Recorded as a
               shape observation, not a request for a field.
               DamageThing(9999) reading: see 3.4. UNVERIFIED.
               CH's Melee had NO DamageThing (CH/decorate/Zombies.txt:411-413);
               this self-kill is CHP's addition.
```

```
## FirebluBurningWake           zscript/monsters/Zombieman/attacks/RS_Zombieman_FirebluWake.zs
kind         : burning wake — it drops fire behind itself as it walks
axes         : delivery:heavy payload:single element:thermal
               species:zombieman role:skirmisher mobility:ground
tier(s)      : T07 Fireblu (Zombieman) — CommonFirebluZombie
chp source   : CHP/DECORATE/01/01_F.txt:25-30   (See2:)
               CHP/DECORATE/01/01_F.txt:31-33   (Missile: -> Goto see2)
acs          : none
fires        : RS_FireSGguy2_C x1 every 8 tics while in See2,
               offset x=-6 (BEHIND it), z=3, xvel=-2, zvel=1, angle=-180
damage       : random(5,15) on contact                (CH/decorate/Archviles.txt:2291)
               splash random(3,9) over radius 32      (CHP/DECORATE/14/14_F.txt:2002)
               DamageType "Fire"
sprites      : ZOMF A A B B / C C D D at 2 tics (a FASTER walk than See's 3)
               fire: FIRE A B (6 tics) -> FIRE C D E E D C D E (5) ->
                     FIRE F G H (4)
sounds       : see="imp/attack" death="imp/shotx" on each ember
behaviour    : This is its ranged attack, and it does not aim. Once it has a
               target it switches to a faster 2-tic walk and sheds a burning
               ember out of its back every eight tics, angled backwards at
               velocity -2 so the trail lags behind it. Follow one down a
               corridor and the corridor is on fire. The embers are the same
               actor the Archvile uses, so they linger, spread a small blast
               where they land, and are not something you can shoot down.
               Its Missile state is literally a redirect into this walk --
               it has no aimed attack of any kind.
profile      : RS_AttackProfile.MakeVolley(
                   proj: "RS_FireSGguy2_C", count: 1, arc: 0.0,
                   profName: "Burning Wake")
               fired on a timer from the See/chase loop, NOT from a
               Missile slot.
notes        : PACK has no "fires while walking" hook. Every monster attack
               slot in this repo is entered from Missile. This one is not,
               and porting it into Missile would change the monster into an
               ordinary shooter. Recorded as a shape gap: a profile that
               ticks on a movement cadence rather than a trigger.
               MakeVolley has no spawn-offset field and this attack is
               DEFINED by its offset (x=-6, behind).
```

```
## FirebluFlinchFlare           zscript/monsters/Zombieman/attacks/RS_Zombieman_FirebluWake.zs
kind         : flinch flare — one ember thrown forward whenever it is hit
axes         : delivery:heavy payload:single element:thermal
               species:zombieman role:skirmisher mobility:ground
tier(s)      : T07 Fireblu (Zombieman) — CommonFirebluZombie
chp source   : CHP/DECORATE/01/01_F.txt:38-41   (Pain:)
acs          : none
fires        : RS_FireSGguy2_C x1, offset x=+6 (IN FRONT), z=3,
               xvel=9, zvel=1, angle random(0,359)
damage       : random(5,15) + splash random(3,9) over 32
sprites      : ZOMF G x2, 3 tics each
sounds       : PainSound "grunt/pain"
behaviour    : Shoot it and it spits. One ember leaves the front of it at
               nine times the speed of its walking trail, in a completely
               random direction. At PainChance 255 this fires on essentially
               every hit it takes, so a sustained burst turns it into a
               sprinkler. That is the actual reason a room of these is
               dangerous: the damage comes from hurting them.
profile      : RS_AttackProfile.MakeVolley(
                   proj: "RS_FireSGguy2_C", count: 1, arc: 360.0,
                   profName: "Flinch Flare")
notes        : Pain-triggered; PACK has no pain hook (same gap as T06's
               AbyssFlinchNova). PainChance 255 makes this the tier's
               highest-volume damage source in practice, which is exactly
               the sort of thing a catalog that only lists Missile branches
               would miss entirely.
```

### 3.6 Referenced actors — T07

| actor | defined at | what it is |
|---|---|---|
| `FireSGguy2_C` | **CHP/DECORATE/14/14_F.txt:1987-2006** | `: FireSGguy2`; `Species "vile1"`, `+DONTHARMSPECIES`, Speed 17, `Damage (random(5,15))`, See `imp/attack`, Death `imp/shotx`, the 8-entry Translation. States: `Spawn: FIRE AB 6 Bright` → `Goto Death`; `Death: FIRE CDEEDCDE 5 Bright A_Explode(random(3,9),32)` , `FIRE FGH 4 Bright` , Stop. |
| `FireSGguy2` (CH base) | CH/Archviles.txt:2285-2311 | supplies Radius 12, Height 16, `DamageType "Fire"`, `Projectile +RANDOMIZE +thruactors`, RenderStyle Add, Alpha 0.85. **CH's Death is `FIRE CDEEDCDE 5 A_Explode(random(3,9),64)` then `FIRE FGH 4 Bright A_Explode(random(5,15),64)`** — CHP's `_C` halves the radius to 32 and REMOVES the second explode entirely. Real damage reduction, port CHP's. |
| `A_Explode` on `FIRE CDEEDCDE` | — | **eight frames, so eight explosions.** This is one of the deliberate multi-frame explode sites CLAUDE.md protects; it is what makes a fireball a lingering hazard rather than a hit. Do not "fix" it to one. |
| `CommonAbyssZombieClone` | CHP/DECORATE/01/01_A.txt:1111-1115 | see §2.5 |
| `SplashAbyss_C` | CHP/DECORATE/03/03_A.txt:1979-1984 | see §2.5 — cosmetic only, no Damage |
| `NewIconCHP23_T1_C` | CHP/DECORATE/MISC/icons.txt:1621-1642 | tier marker, sprite `OTIR F` |
| `CHRandom_GibGenerator`, `WhiteZombiePlan_C`, `CHWhitePlan`, `CHAbyssMark`, `GoAway` | as above | — |

---

## 4. TIER T08 — `CommonBrownZombie` (01_BR, "GET DOWN MR PRESIDENT")

* CHP actor: `CHP/01/01_BR.txt:1-119` — `ACTOR CommonBrownZombie : BrownZombie2`
* CH parent: `CH/Zombies.txt:40-185` — `ACTOR BrownZombie2` (bare Actor)
* Body sprite: `SGAR` (`CH/sprites/brownnoise/getdownmrpresident/SGAR*`, frames **A–M only**)
* Gib sprite: `POSS M–U` — vanilla IWAD. **Deliberate and unavoidable, see §0.7.**

### 4.1 Properties

| property | value | source |
|---|---|---|
| Radius | 20 | CHP `01_BR.txt:3` (overrides CH 24 @ `Zombies.txt:45`) |
| Height | 56 | CHP `01_BR.txt:4` (overrides CH 64 @ `Zombies.txt:46`) |
| Health | 100 | CHP `01_BR.txt:5` (CH also 100 @ `:42`) |
| PainChance | 128 | CHP `01_BR.txt:6` (CH also 128 @ `:43`) |
| Speed | 4 | CHP `01_BR.txt:7` (**overrides CH 8** @ `:44` — halved) |
| Scale | **1** | CHP `01_BR.txt:8` (overrides CH 0.9 @ `:48`) |
| Mass | 1000 | CH `Zombies.txt:47` |
| GibHealth | not set | — |
| Species | **not set anywhere** — so no species protection and no `+DONTHARMSPECIES` benefit | — |
| BloodColor | not set (the Green sibling sets one @ `01_BR.txt:138`; Common does not) | — |
| DamageFactor "Exorcist" | 3.0 | CH `Zombies.txt:50` |
| DamageFactor "DIMp" | 0 | CH `Zombies.txt:51` |
| PainChance "DIMp" | 0 | CH `Zombies.txt:52` |
| Translation | **none anywhere in the chain** — no remap, bespoke art shown raw | — |
| Flags | `Monster` (declared **twice**, CH `:49` and `:53`), `+FLOORCLIP`, `+Avoidmelee`, `+noinfighting`, `+RollSprite`, `+notargetswitch` | CH `Zombies.txt:49-58` |
| SeeSound | `"Zom2/see"` | CHP `01_BR.txt:9` |
| AttackSound | `"SNPRFIRE"` | CHP `01_BR.txt:10` — **never played, see §0.3** |
| PainSound | `"Form2/hurt"` | CHP `01_BR.txt:11` |
| DeathSound | `"zom2/die"` | CHP `01_BR.txt:12` |
| ActiveSound | `"Form2/active"` | CHP `01_BR.txt:13` |
| Obituary | `"%o got \c[ColorBR]bodyguard slammed\c-"` | CHP `01_BR.txt:14` |
| HitObituary | not defined | — |
| Tag | `"\c[ColorBR]GET DOWN MR PRESIDENT\c-"` | CHP `01_BR.txt:15` |
| Melee* | no Melee state, no MeleeRange/MeleeDamage | — |
| DropItem | inherited CH `Zombies.txt:65-68`: `implyingclip` x2, `HealthBonus`,64, `HealthBonus`,128 | — |

`+RollSprite` is load-bearing here — the whole GETDOWN2 routine is
`A_SetRoll` — and `+noinfighting` + `+notargetswitch` are what keep the
bodyguard aimed at the player instead of at whatever hit it.

### 4.2 Full state transcription — `CHP/01/01_BR.txt:16-118`

```
 18  Spawn:
 19      SGAR A 0 Nodelay A_SpawnitemEx("NewIconCHP21_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
 20  Idle:
 21      SGAR A 5 A_Look
 22      Loop
 23  See:
 24      SGAR BC 5 A_Chase
 25      TNT1 A 0 A_Jump(128,"Checks")
 26      SGAR DE 5 A_Chase
 27      TNT1 A 0 A_jump(200,"see")
 28      TNT1 A 0 A_CheckLOF("FrontJump",CLOFF_NOAIM_VERT|CLOFF_JUMPENEMY|CLOFF_SKIPOBSTACLES,800)
 29      Loop
 30  Checks:
 31      TNT1 A 0 A_checkproximity("GETDOWN","Archvile",1000,1,CPXF_ANCESTOR|CPXF_CHECKSIGHT|CPXF_SETMASTER|CPXF_CLOSEST)
 32      TNT1 A 0 A_checkproximity("GETDOWN","BaronOfHell",1000,1,CPXF_ANCESTOR|CPXF_CHECKSIGHT|CPXF_SETMASTER|CPXF_CLOSEST)
 33      TNT1 A 0 A_checkproximity("GETDOWN","HellKnight",1000,1,CPXF_ANCESTOR|CPXF_CHECKSIGHT|CPXF_SETMASTER|CPXF_CLOSEST)
 34      TNT1 A 0 A_checkproximity("GETDOWN","CyberDemon",1000,1,CPXF_ANCESTOR|CPXF_CHECKSIGHT|CPXF_SETMASTER|CPXF_CLOSEST)
 35      TNT1 A 0 A_checkproximity("GETDOWN","ChainGunGuy",1000,1,CPXF_ANCESTOR|CPXF_CHECKSIGHT|CPXF_SETMASTER|CPXF_CLOSEST)
 36      Goto See+3
 37  Missile:
 38      SGAR F 10 A_FaceTarget
 39      SGAR G 10 BRIGHT A_CustomBulletAttack(5,0,1,10,"BulletPuff_C",0,CBAF_NORANDOM)
 40      SGAR F 10
 41      Goto See
 42  GETDOWN:
 43      TNT1 A 0 A_CheckLOF("GETDOWN2",CLOFF_NOAIM_VERT|CLOFF_JUMPENEMY|CLOFF_SKIPOBSTACLES,800)
 44      Goto see+3
 45  GETDOWN2:
 46      SGAR F 5 A_FaceMaster
 47      SGAR F 1 thrustthingz(0,30,0,0)
 48      SGAR F 1 thrustthing(angle,40,0,0)
 49      SGAR F 1 A_setroll(20)
 50      SGAR F 1 A_setroll(40)
 51      SGAR F 1 A_setroll(60)
 52      SGAR F 1 A_setroll(80)
 53      SGAR F 1 A_setroll(100)
 54      SGAR F 1 A_setroll(120)
 55      SGAR F 1 A_setroll(140)
 56      SGAR F 1 A_setroll(160)
 57      SGAR F 1 A_setroll(180)
 58      TNT1 A 0 A_radiusgive("health",100,RGF_MONSTERS,50)
 59      SGAR F 1 A_setroll(200)
 60      SGAR F 1 A_setroll(220)
 61      SGAR F 1 A_setroll(240)
 62      SGAR F 1 A_setroll(260)
 63      SGAR F 1 A_setroll(280)
 64      SGAR F 1 A_setroll(300)
 65      SGAR F 1 A_setroll(320)
 66      SGAR F 1 A_setroll(340)
 67      SGAR F 1 A_setroll(0)
 68      SGAR F 6 a_stop
 69      Goto see
 70  FrontJump:
 71      SGAR F 5 A_FaceTarget
 72      SGAR F 1 thrustthingz(0,28,0,0)
 73      SGAR F 17 thrustthing(angle,14,0,0)
 74      SGAR F 6 a_stop
 75      SGAR BC 6 A_FastChase
 76      Goto see
 77  Pain:
 78      TNT1 A 0 A_setroll(0)
 79      SGAR H 8 A_Pain
 80      Goto See
 81  Tickles:
 82      TNT1 A 0 A_Spawnitemex("WhiteZombiePlan_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION)
 83      Goto Death+2
 84  Death:
 85      TNT1 A 0 A_GivetoChildren("GoAway",1)
 86      TNT1 A 0 A_JumpIfInventory("CHWhitePlan",0,"Tickles")
 87      TNT1 A 0 A_setroll(0)
 88      SGAR I 5
 89      SGAR J 5 A_Scream
 90      SGAR K 5
 91      SGAR L 5 A_NoBlocking
 92      TNT1 A 0 A_JumpIfInventory("CHAbyssMark",1,"AbyssGrow")
 93      SGAR M -1
 94      Stop
 95  XDeath:
 96      TNT1 A 0 A_GivetoChildren("GoAway",1)
 97      TNT1 AAA 0 A_SpawnItemEx ("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
 98      POSS M 5
 99      TNT1 A 0 A_Playsound("misc/gibbed/c")           <- silent, see 0.2
100      POSS N 5 a_xscream
101      TNT1 AAA 0 A_SpawnItemEx ("CHRandom_GibGenerator",0,0,8,VelX,VelY,VelZ,0,SXF_ABSOLUTEMOMENTUM|SXF_USEBLOODCOLOR|SXF_NOCHECKPOSITION)
102      POSS O 5 a_noblocking
103      POSS PQRST 5
104      TNT1 AAA 0 A_Spawnparticle("Red",SPF_FULLBRIGHT|SPF_RELATIVE,random(27,74),random(1,13),frandom(0,360),0,0,24,frandom(0.1,11.0),frandom(-0.15,0.25),frandom(-6.9,6.9),0,0,-0.1,0.98,-1)
105      POSS U -1
106      Stop
107  AbyssGrow:
108      TNT1 [A x15] 0 A_Spawnparticle("Black",...)      (as T07:56)
109      TNT1 [A x45] 0 A_Spawnitemex("SplashAbyss_C",random(-32,32),random(-32,32),random(2,16),0,0,2,random(-359,359),SXF_NOCHECKPOSITION)
110      TNT1 A 8
111      POSS A 0 A_Spawnitemex("CommonAbyssZombieClone",0,0,6,0,0,1,0,SXF_NOCHECKPOSITION|SXF_SETTARGET)
112      TNT1 A 0 A_die
113      Stop
114  Raise:
115      SGAR LKJI 5
116      SGAR I 0 A_SpawnitemEx("NewIconCHP21_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
117      Goto See
```

Repeat-run counts verified: lines 97/101/104 = 3 each; 108 = 15; 109 = 45.

**T08 has NO `Death.Ice` label** — unlike T05/T06/T07/T09. `BrownZombie2` has no
`+NOICEDEATH` either (`CH/Zombies.txt:54-58`), so freezing this tier gives the
engine's default ice shatter. That asymmetry is real and should be ported as-is.

**`Goto See+3` resolves to `SGAR D`.** `See` indexes as
0=`SGAR B`, 1=`SGAR C`, 2=`TNT1 A_Jump`, 3=`SGAR D`. CH's equivalent was
`Goto see+8` (`CH/Zombies.txt:97`) into a longer See — same landing frame.

### 4.3 CHP vs CH — the bodyguard mechanic CHANGED

This is the single most important delta in my five tiers.

**CH's `GetDown2` (`CH/Zombies.txt:98-122`) TELEPORTS the bodyguard onto the VIP:**
```
CH/Zombies.txt:112
    SGAR F 1 A_warp(AAPTR_MASTER,randompick(32,48,64),0,randompick(-32,-16,0,16,32),0,WARPF_COPYVELOCITY|WARPF_COPYPITCH)
```
with a translucency fade in and out around it (`:105`, `:108`, `:111`, `:113`,
`:116`, `:118`).

**CHP's `GETDOWN2` (`CHP/01/01_BR.txt:45-69`) has NO warp and NO fade.** It
replaced them with:
```
CHP/DECORATE/01/01_BR.txt:58
    TNT1 A 0 A_radiusgive("health",100,RGF_MONSTERS,50)
```

So the mechanic went from *"blink to the VIP's side and body-block"* to
*"combat-roll in place and heal every monster within 100 units for 50"*. The
lunge also got stronger: `thrustthing(angle,40,…)` vs CH's 24. It is now a
**support/heal ability**, not a repositioning one. A port that reads CH will
build the wrong monster.

### 4.4 CATALOG — T08

```
## BodyguardSniperShot          zscript/monsters/Zombieman/attacks/RS_Zombieman_BodyguardShot.zs
kind         : single-shot sniper crack — one tight, flat-damage bullet
axes         : delivery:bullet payload:single element:kinetic
               species:zombieman role:skirmisher mobility:ground trigger:semi
tier(s)      : T08 Brown (Zombieman) — CommonBrownZombie
chp source   : CHP/DECORATE/01/01_BR.txt:37-41   (Missile:)
acs          : none
fires        : hitscan, 1 bullet, horizontal spread 5 deg, vertical spread 0,
               puff RS_BulletPuff_C, range default, CBAF_NORANDOM
damage       : EXACTLY 10. Flat. Not a roll.
               CHP passes damageperbullet=10 AND CBAF_NORANDOM
               (CHP/DECORATE/01/01_BR.txt:39), which suppresses GZDoom's
               own random(1,3) multiplier. This is CHP's own constant, not
               a flattened roll -- do not "restore" a spread that was never
               there. (Contrast the Green sibling at 01_BR.txt:162, which
               uses random(12,13) with the same NORANDOM flag.)
sprites      : SGAR F (aim, 10t) / SGAR G (fire, 10t, BRIGHT) / SGAR F (10t)
sounds       : NONE. AttackSound "SNPRFIRE" is declared at 01_BR.txt:10 but
               A_CustomBulletAttack does not play it -- see 0.3.
behaviour    : One shot every 30 tics, dead flat: a 5-degree cone with no
               vertical scatter and a fixed 10 damage, so it neither misses
               wildly nor spikes. Slow (Speed 4) and heavy (Mass 1000), it
               is a stationary problem rather than a chasing one, and the
               damage is small enough that the shot is not what kills you --
               the shot is what keeps you honest while it does its actual
               job, which is bodyguarding.
profile      : RS_AttackProfile.MakeHitscan(
                   fireSnd: "", spreadScale: 5.0, ammoCost: 0,
                   profName: "Sniper Crack",
                   impactPuff: "RS_BulletPuff_C")
notes        : Deliberately NOT giving this a fire sound in the profile, to
               match CHP exactly. If the owner wants the crack audible that
               is a change, not a port, and should be recorded as one.
```

```
## BodyguardRollGuard           zscript/monsters/Zombieman/attacks/RS_Zombieman_BodyguardRoll.zs
kind         : combat-roll heal pulse — it dives for a VIP and patches up everything near it
axes         : delivery:radial element:kinetic
               species:zombieman role:bruiser mobility:ground
tier(s)      : T08 Brown (Zombieman) — CommonBrownZombie
chp source   : CHP/DECORATE/01/01_BR.txt:42-69   (GETDOWN: / GETDOWN2:)
               trigger at CHP/DECORATE/01/01_BR.txt:30-36   (Checks:)
acs          : none
fires        : A_RadiusGive("health", 100, RGF_MONSTERS, 50) once, at the
               midpoint of the roll (01_BR.txt:58)
damage       : none -- this HEALS. 50 health to every monster within 100
               units.
sprites      : SGAR F throughout; the animation is A_SetRoll 20..340 then 0,
               one step per tic, i.e. the sprite physically somersaults
               (+RollSprite, CH/decorate/Zombies.txt:57)
sounds       : none
behaviour    : Every second See cycle it looks for an Archvile, Baron,
               Hell Knight, Cyberdemon or Chaingunner within 1000 units and
               in line of sight. Find one, and it takes that monster as its
               master, checks it has a clear line, then launches: a hop
               straight up, a hard lunge forward, and a full 360-degree
               somersault over about 27 tics. Halfway through the roll every
               monster within 100 units is healed for 50. Then it stops dead
               and goes back to chasing. The whole thing is a commitment --
               it is not steering during the roll and it is not shooting.
profile      : RS_AttackProfile.MakeRadial(
                   radius: 100.0, damage: 0, heal: 50,
                   hitsAllies: true, profName: "Roll Guard")
notes        : PORT WARNING -- CH's version of this state WARPS to the VIP
               (CH/decorate/Zombies.txt:112) and does NOT heal. CHP replaced
               the warp with the heal. See 4.3. Build CHP's.
               The 27-tic roll, the leap and the master-acquisition are
               movement/AI, not profile content, and must stay in the
               monster's state machine.
               A_CheckProximity uses CPXF_ANCESTOR against the VANILLA class
               names (Archvile, BaronOfHell, HellKnight, CyberDemon,
               ChainGunGuy). RS's monsters `replaces` those classes rather
               than descending from them, so this trigger finds nothing in
               an RS load unless the check is rewritten against RS_* classes.
               That is a live porting hazard, not a CHP bug.
               thrustthing(angle,...) heading may be wrong -- see 0.6.
```

Non-attack mechanic: **`FrontJump`** (`CHP/01/01_BR.txt:70-76`) — a
line-of-fire-triggered pounce toward the target (up 7 u/tic, forward force 14,
17 tics of flight, then `A_FastChase`). Entered from `See` (`:28`) on a clear
LOF within 800 units. Mobility only, no damage. CHP merged CH's separate
1-tic-thrust + 16-tic-wait (`CH/Zombies.txt:126-127`) into one 17-tic frame;
timing is identical.

### 4.5 Referenced actors — T08

| actor | defined at | what it is |
|---|---|---|
| `BulletPuff_C` | CHP/DECORATE/01/01_C.txt:1173-1175 | empty alias of `BulletPuff` |
| `NewIconCHP21_T1_C` | CHP/DECORATE/MISC/icons.txt:1347-1368 | tier marker, sprite `OTIR B` |
| `CommonAbyssZombieClone` | CHP/DECORATE/01/01_A.txt:1111-1115 | see §2.5 |
| `SplashAbyss_C` | CHP/DECORATE/03/03_A.txt:1979-1984 | see §2.5 |
| `CHRandom_GibGenerator` | CH/Gibs.txt:3-41 | 6 spawns across two 3-frame runs (`:97`, `:101`) |
| `WhiteZombiePlan_C`, `CHWhitePlan`, `CHAbyssMark`, `GoAway` | as above | — |
| `health` (A_RadiusGive item) | GZDoom base `Health` inventory class | not a CH/CHP actor; the engine class |

---

## 5. TIER T09 — `CommonGrayZombie` (01_GY, "Gray Zombieman")

* CHP actor: `CHP/01/01_GY.txt:1-83` — `ACTOR CommonGrayZombie : GrayZombie2`
* CH parent: `CH/Zombies.txt:492-612` — `ACTOR GrayZombie2 : Zombieman`
* Body sprite: `SHDT` (`CH/sprites/GrayTrooper/SHDT*`, frames **A–U**; used A–L)

### 5.1 Properties

| property | value | source |
|---|---|---|
| Health | 80 | CHP `01_GY.txt:3` (overrides CH 110 @ `Zombies.txt:495`) |
| Speed | 4 | CHP `01_GY.txt:4` (CH also 4 @ `:498`) |
| PainChance | 40 | CHP `01_GY.txt:5` (CH also 40 @ `:500`) |
| Mass | **400** | CHP `01_GY.txt:6` — CH sets none, so CH inherits `Zombieman`'s 100 |
| Radius | 20 | CH `Zombies.txt:496` |
| Height | 56 | CH `Zombies.txt:497` |
| Scale | not set → 1.0 | — |
| GibHealth | not set | — |
| Damage | 1 | CH `Zombies.txt:499` — a projectile property on a monster; inert |
| BloodColor | **`"Black"`** | CHP `01_GY.txt:12` — CH sets none |
| Species | **not set** anywhere (`GrayZombie2 : Zombieman`, and `Zombieman` has none) | — |
| DamageFactor "Exorcist" | 3.0 | CH `Zombies.txt:501` |
| DamageFactor Fire | 2.0 — declared **twice**, `DamaGeFactor Fire,2.0` and `DamageFactor "Fire",2.0` | CH `Zombies.txt:502-503` |
| DamageFactor Melee | **2.0** | CH `Zombies.txt:504` |
| DamageFactor "DIMp" | 0 | CH `Zombies.txt:505` |
| PainChance "DIMp" | 0 | CH `Zombies.txt:506` |
| Translation | **`None`** | CHP `01_GY.txt:15` (overrides CH's greyscale `"0:255=%[0.00,0.00,0.00]:[1.13,1.25,1.35]"` @ `:523`) |
| Flags | `Monster`, `+FLOORCLIP`, `+Missilemore`, `+Avoidmelee` | CH `Zombies.txt:507-510` |
| SeeSound | `"Zom2/see"` | CHP `01_GY.txt:7` |
| AttackSound | `"grunt/attack"` | CHP `01_GY.txt:8` — **declared and never played**; the Missile state uses `A_CustomMissile`, which does not play AttackSound |
| PainSound | `"Form2/hurt"` | CHP `01_GY.txt:9` |
| DeathSound | `"zom2/die"` | CHP `01_GY.txt:10` |
| ActiveSound | `"Form2/active"` | CHP `01_GY.txt:11` |
| Obituary | `"%o was brick'd by \c[ColorGY]gray zombie\c-."` | CHP `01_GY.txt:13` |
| HitObituary | not defined | — |
| Tag | `"\c[ColorGY]Gray Zombieman\c-"` | CHP `01_GY.txt:14` |
| Melee* | no Melee state, no MeleeRange/MeleeDamage | — |
| DropItem | inherited CH `Zombies.txt:517-520`: `implyingclip` x2, `HealthBonus`,64, `HealthBonus`,128 | — |

**`DamageFactor Melee 2.0` + `ZombieRock_C` `DamageType "Melee"` is a live
interaction.** Gray zombies take double damage from their own rocks, and with no
`Species` and no `+DONTHARMSPECIES` there is nothing stopping them hitting each
other — including from the 13-rock death burst. A pack of these will meaningfully
shred itself. That is CHP's design as written; recording it so it is not read as
a port bug later.

### 5.2 Full state transcription — `CHP/01/01_GY.txt:16-82`

```
 18  Spawn:
 19      SHDT A 0 Nodelay A_SpawnitemEx("NewIconCHP24_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
 20  Idle:
 21      SHDT AB 10 A_Look
 22      Loop
 23  See:
 24      SHDT AABBCCDD 5 A_Chase
 25      Loop
 26  Missile:
 27      SHDT E 10 A_FaceTarget
 28      SHDT F 2 bright A_Custommissile("ZombieRock_C",46,1,random(-2,2))
 29      SHDT F 2 A_Custommissile("ZombieRock_C",46,1,random(-2,2))
 30      SHDT F 2 bright A_Custommissile("ZombieRock_C",46,1,random(-2,2))
 31      SHDT FEEEE 2
 32      Goto See
 33  Pain:
 34      SHDT G 3
 35      SHDT G 3 A_Pain
 36      Goto See
 37  Tickles:
 38      TNT1 A 0 A_Spawnitemex("WhiteZombiePlan_C",0,0,6,0,0,0,0,SXF_NOPOINTERS| SXF_NOCHECKPOSITION)
 39      Goto Death+2
 40  Death.Ice:
 41  Death:
 42      TNT1 A 0 A_GivetoChildren("GoAway",1)
 43      SHDT H 5 A_JumpIfInventory("CHWhitePlan",0,"Tickles")
 44      SHDT I 5 A_Scream
 45      SHDT J 5 A_NoBlocking
 46      SHDT K 5
 47      TNT1 A 0 A_JumpIfInventory("CHAbyssMark",1,"AbyssGrow")
 48      SHDT L -1
 49      Stop
 50  XDeath:
 51      TNT1 A 0 A_GivetoChildren("GoAway",1)
 52      SHDT G 12 a_scream
 53      SHDT G 4 A_NoBlocking
 54      SHDT G 6 a_setscale(1.2,0.8)
 55      SHDT G 6 a_setscale(1.0,1.0)
 56      SHDT G 6 a_setscale(0.8,1.2)
 57      SHDT G 4 a_setscale(1.2,0.8)
 58      SHDT G 4 a_setscale(0.8,1.2)
 59      SHDT G 3 a_setscale(1.2,0.8)
 60      SHDT G 3 a_setscale(0.8,1.2)
 61      SHDT G 2 a_setscale(1.2,0.8)
 62      SHDT G 2 a_setscale(0.8,1.2)
 63      SHDT G 1 a_setscale(1.2,0.8)
 64      SHDT G 1 a_setscale(0.8,1.2)
 65      MISL X 0 A_Playsound("weapons/rocklx")
 66      MISL XYZ 2
 67      TNT1 [A x13] 0 A_Custommissile("ZombieRock_C",32,0,random(-359,359))
 68      Stop
 69  AbyssGrow:
 70      TNT1 [A x15] 0 A_Spawnparticle("Black",...)      (as T07:56)
 71      TNT1 [A x45] 0 A_Spawnitemex("SplashAbyss_C",random(-32,32),random(-32,32),random(2,16),0,0,2,random(-359,359),SXF_NOCHECKPOSITION)
 72      TNT1 A 8
 73      POSS A 0 A_Spawnitemex("CommonAbyssZombieClone",0,0,6,0,0,1,0,SXF_NOCHECKPOSITION|SXF_SETTARGET)
 74      TNT1 A 0 A_die
 75      Stop
 76  Raise:
 77      SHDT KJIH 5
 78      SHDT H 0 A_SpawnitemEx("NewIconCHP24_T1_C",0,0,64,0,0,0,0,SXF_NOCHECKPOSITION|SXF_SETMASTER)
 79      Goto See
 80  Grow:
 81      Stop
```

Repeat-run counts verified: line 67 = **13** `A`s (CH's is also 13,
`CH/Zombies.txt:600`); line 70 = 15; line 71 = 45.

Line 73 uses `POSS A` as a 0-tic carrier frame inside a `SHDT`-bodied actor —
harmless (0 tics, never drawn), inherited from CH's pattern, but worth noting so
nobody "corrects" it to `SHDT A` and calls that a fix.

The XDeath is a 50-tic squash-and-stretch pulse (12+4+6+6+6+4+4+3+3+2+2+1+1)
followed by a 6-tic `MISL X Y Z` flash and then the rock burst.

`Grow: Stop` (`:80-81`) — same deliberate stub as T07; CHP disabled CH's
`Grow → PurpleZombie` promotion (`CH/Zombies.txt:606-610`) and CHP's `Raise`
(`:76-79`) dropped CH's `GrowRaisin` check (`CH/Zombies.txt:603`).

### 5.3 CHP vs CH deltas

* `See` is one 8-frame line at 5 tics (`:24`); CH's is two 4-frame lines with
  icon spawns interleaved (`CH/Zombies.txt:532-535`). Same 40-tic cycle.
* `Missile` tail: CHP `SHDT FEEEE 2` = 10 tics (`:31`); CH `SHDT F 2` +
  `SHDT E 8` = 10 tics (`CH/Zombies.txt:543-544`). Same duration, different frames.
* CHP added `Death.Ice` (`:40`), the `weapons/rocklx` cue (`:65`), and moved the
  gib flash from `MISL BCD` (CH `:599`) to `MISL XYZ` — CHP's own added lumps.
* CH's `AbyssGrow` spawns `AbyssZombie2` (`:579`); CHP spawns
  `CommonAbyssZombieClone` (`:73`).

### 5.4 CATALOG — T09

```
## GrayRockVolley               zscript/monsters/Zombieman/attacks/RS_Zombieman_GrayRock.zs
kind         : three-rock stone volley — a slow lobber that throws masonry
axes         : delivery:heavy payload:multi element:kinetic
               species:zombieman role:artillery mobility:ground
tier(s)      : T09 Gray (Zombieman) — CommonGrayZombie
chp source   : CHP/DECORATE/01/01_GY.txt:26-32   (Missile:)
acs          : none
fires        : RS_ZombieRock_C x3, one every 2 tics, spawn height 46,
               lateral offset 1, angle random(-2,2) each
damage       : random(1,12) per rock, DamageType "Melee"
               (CHP/DECORATE/01/01_GY.txt:1306-1307)
               no splash -- the rock's Death state only spawns dirt
sprites      : SHDT E (10t wind-up) / SHDT F x3 (throw, 1st and 3rd BRIGHT)
               / SHDT F E E E E (10t recover)
               rock: JUBD A B C D at 3 tics, Bright, looping
sounds       : see="monster/hamflr"  death="Butcher/melee"  (on the rock)
               AttackSound "grunt/attack" is declared but never played
behaviour    : Three fast rocks in six tics after a long ten-tic wind-up,
               essentially straight (±2 degrees) at speed 36. It is slow
               (Speed 4), so it plants and throws rather than chases, and
               the whole cycle is 30 tics with 20 of them being tells.
               Each rock bursts into eight lumps of dirt on impact -- four
               heavy, four light -- which is cosmetic but reads as a real
               impact. DamageType "Melee" is unusual for a projectile and
               matters: anything with a melee resistance shrugs it off, and
               gray zombies themselves take DOUBLE from it.
profile      : RS_AttackProfile.MakeVolley(
                   proj: "RS_ZombieRock_C", count: 3, arc: 4.0,
                   fireSnd: "", profName: "Stone Volley")
notes        : MakeVolley fires its count on ONE tic; CHP staggers three
               shots 2 tics apart. The stagger is small enough that a single
               burst is a defensible approximation here -- unlike T06's
               5-tic pincer -- but say so rather than pretending it matches.
               MakeVolley has no spawn-offset field (spawnofs_xy = 1).
               CHP CHANGED THE PARENT CLASS: CH's ZombieRock is
               ": WDRock3" (CH/decorate/Zombies.txt:614); CHP's
               ZombieRock_C is ": FastProjectile"
               (CHP/DECORATE/01/01_GY.txt:1300). Same numbers, different
               movement stepping. Port CHP's.
```

```
## GrayDeathBurst               zscript/monsters/Zombieman/attacks/RS_Zombieman_GrayRock.zs
kind         : shrapnel burst — the corpse bursts and throws rocks in every direction
axes         : delivery:radial payload:multi element:kinetic
               species:zombieman role:artillery mobility:ground
tier(s)      : T09 Gray (Zombieman) — CommonGrayZombie
chp source   : CHP/DECORATE/01/01_GY.txt:50-68   (XDeath:)
acs          : none
fires        : RS_ZombieRock_C x13 on ONE tic, spawn height 32,
               lateral offset 0, angle random(-359,359) each
damage       : random(1,12) per rock, DamageType "Melee"
sprites      : SHDT G pulsing (13 frames of a_setscale squash/stretch,
               50 tics total) then MISL X Y Z at 2 tics
sounds       : "weapons/rocklx" at 01_GY.txt:65
behaviour    : Gib it and it does not just die -- it inflates, wobbles
               faster and faster for fifty tics like something about to
               pop, and then throws thirteen rocks out at completely random
               angles. Standing next to the kill is the mistake. Note the
               fifty-tic wind-up: you get an unmistakable warning, and the
               correct answer is to walk away from a corpse, which is not a
               reflex most players have.
profile      : RS_AttackProfile.MakeVolley(
                   proj: "RS_ZombieRock_C", count: 13, arc: 360.0,
                   fireSnd: "weapons/rocklx", profName: "Shrapnel Burst")
notes        : Thirteen verified by character count on 01_GY.txt:67, not
               estimated. CH's is also thirteen (CH/decorate/Zombies.txt:600).
               No species protection and DamageFactor Melee 2.0 mean this
               burst hits other gray zombies for DOUBLE. See 5.1.
               This is an XDeath payload, and PACK has no death-trigger
               slot -- same class of gap as the pain triggers in T06/T07.
```

### 5.5 Referenced actors — T09

| actor | defined at | what it is |
|---|---|---|
| `ZombieRock_C` | **CHP/DECORATE/01/01_GY.txt:1300-1322** | `: FastProjectile`; Radius 9, Height 9, Speed 36, `Damage (Random(1,12))`, `DamageType "Melee"`, `Projectile`, scale 0.25, See `monster/hamflr`, Death `Butcher/melee`. `Spawn: JUBD ABCD 3 Bright` Loop. `Death: JUBD DDDD 0 Bright A_SpawnItemEx("Drt2_C",random(-2,2),random(-2,2),random(-2,2),1,0,1,Random(0,360),128)` then `JUBD DDDD 1 Bright A_SpawnItemEx("Drt3_C",…)` then Stop. |
| — multi-frame note | — | Four `D` frames × two lines = **8 dirt spawns per impact**, one per frame. Same deliberate multi-frame idiom as T07's fireball. Not a bug. |
| `ZombieRock` (CH original, superseded) | CH/Zombies.txt:614-618 | `: WDRock3 { Damage (Random(1,12))  scale 0.25 }` — a plain projectile |
| `WDRock3` (CH grandparent) | CH/Demons.txt:2632-2654 | Radius 9, Height 9, Speed 36, `Damage (Random(15,65))`, `DamageType "Melee"`, scale 0.7. Note the base rolls **15–65**; both `ZombieRock` and `ZombieRock_C` cut it to 1–12. |
| `Drt2_C` | **CHP/DECORATE/15/15_K.txt:5200-5204** | `: Drt2 { Speed 5  +NOTELEPORT }` |
| `Drt3_C` | **CHP/DECORATE/15/15_K.txt:5293-5297** | `: Drt3 { Speed 5  +NOTELEPORT }` |
| `Drt2` / `Drt3` (CH base) | CH/Barons.txt:4407-4430 / 4432-4455 | `PROJECTILE -NOGRAVITY -NOBLOCKMAP -NOTELEPORT +RANDOMIZE`, Radius 2, **Damage 0**, Speed 5; `Spawn: DIRT A 0 A_SetGravity(0.5)` , `DIRT A 0 ThrustThingZ(0,15,0,1)` → `See: DIRT DEF 5` (Drt2) / `DIRT GHI 5` (Drt3) loop; `Death: DIRT JKL 3`. Purely visual. |
| `NewIconCHP24_T1_C` | CHP/DECORATE/MISC/icons.txt:1758-1779 | tier marker, sprite `OTIR G` |
| `CommonAbyssZombieClone`, `SplashAbyss_C`, `WhiteZombiePlan_C`, `CHWhitePlan`, `CHAbyssMark`, `GoAway` | as above | — |

---

## 6. CROSS-TIER NOTES

### 6.1 The tier-icon chain is a real mechanism, not dressing

Every one of my five tiers opens with a 0-tic `Nodelay A_SpawnItemEx("NewIconCHP*_T1_C", 0,0,64, …, SXF_SETMASTER)`
and repeats it at the end of `Raise` (T05 `:11`/`:85`, T06 `:17`/`:66`,
T07 `:18`/`:75`, T08 `:19`/`:116`, T09 `:19`/`:78`). Every `Death`/`XDeath`
opens with `A_GivetoChildren("GoAway",1)`.

Those two halves are one mechanism: `SXF_SETMASTER` makes the zombie the icon's
master, so `A_GiveToChildren` reaches it, and the icon's own loop
(`CHP/icons.txt:676-677` for T05) is
```
TI3R E 1 Bright A_Warp(AAPTR_MASTER,0,0,64,0,WARPF_NOCHECKPOSITION)
TI3R E 0 A_JumpIfInventory("GoAway",1,"Nope")
```
— warp to master every tic, quit when told. The icon only appears at all if
`CallACS("CH_ColorBlind") == 1` (`CHP/icons.txt:672`).

So it is a **colourblind-accessibility tier marker with a working cleanup
protocol**, gated on a cvar. `RS_Zombieman.zs:59-63` currently lists
"NewIconCHP*/ColorTierIcon spawns" and "A_GivetoChildren" under *"CHP cruft
stripped per spec"*. rs_21 §1 line 68 says NOTHING IS CRUFT UNTIL ITS SOURCE HAS
BEEN READ. I have read it: it is an accessibility feature, and `A_GivetoChildren`
is not decoration — it is the half that prevents orphaned icons. **I disagree
with the "cruft" label and record the disagreement here rather than softening
it.** Dropping it may still be the right call (RS has its own tier UI), but the
reason must be "RS owns tier display", not "it does nothing".

### 6.2 Where each tier can and cannot be promoted

| tier | `AbyssGrow` on death? | `Grow` on raise? | `Death.Ice`? | `Pain.AbyssPE`? |
|---|---|---|---|---|
| T05 Y | **no** — Death has no CHAbyssMark check | no state | yes (`:63`) | inherited `CH/Zombies.txt:1363-1378` |
| T06 A | no (it *is* the abyss form) | no state | yes (`:45`) | none in chain |
| T07 F | yes (`:49` → `:55-61`) | stubbed `Grow: Stop` (`:77`) | yes (`:42`) | inherited **and broken** — §0.5 |
| T08 BR | yes (`:92` → `:107-113`) | no state | **no** | inherited `CH/Zombies.txt:136-151` |
| T09 GY | yes (`:47` → `:69-75`) | stubbed `Grow: Stop` (`:80`) | yes (`:40`) | inherited `CH/Zombies.txt:546-561` |

Every `AbyssGrow` spawns `CommonAbyssZombieClone` (Health 140 / Speed 10), never
`AbyssZombie2` — CHP changed this from CH in all three cases.

### 6.3 Sub-variants NOT ported (rs_21 §1 lines 53-63 requires they be recorded)

Each of my five files carries 14 further colours beyond `Common`, all deriving
from the same CH parent. Their `Translation` strings, verbatim from the Green of
each file, so the axis can be table-filled later without re-reading:

| file | Common | Green sibling | Green's Translation |
|---|---|---|---|
| 01_Y | `CommonYellowZombie` `:1` | `GreenYellowZombie` `:90` | (see `01_Y.txt:90-185`) |
| 01_A | `CommonAbyssZombie` `:1` | `GreenAbyssZombie` `:71` | (see `01_A.txt:71-141`) |
| 01_F | `CommonFirebluZombie` `:1` | `GreenFirebluZombie` `:82` | (see `01_F.txt:82-163`) |
| 01_BR | `CommonBrownZombie` `:1` | `GreenBrownZombie` `:122` | `"0:255=%[0.00,0.00,0.00]:[0.18,1.32,0.18]"` (`01_BR.txt:137`), BloodColor `"18 A8 18"` (`:138`) |
| 01_GY | `CommonGrayZombie` `:1` | `GreenGrayZombie` `:85` | (see `01_GY.txt:85-168`) |

Full sub-variant actor lists (line numbers are the `ACTOR` line):

* **01_Y**: Common 1, Green 90, Blue 186, Purple 282, Yellow 378, Red 474,
  Black 570, White 666, BlackEX 762, WhiteEX 859, Abyss 956, Brown 1070,
  Cyan 1184, Fireblu 1280, Gray 1384. Projectiles `MiniRKTZombie_*` 1481-1730.
* **01_A**: Common 1, Green 71, Blue 142, Purple 213, Yellow 284, Red 355,
  Black 426, White 497, BlackEX 568, WhiteEX 640, Abyss 710, Brown 795,
  Cyan 880, Fireblu 951, Gray 1039. Clones 1111-1206. Projectiles
  `AbyssZShotCH_*` 1208-1454, `AbyssZShotCH2_*` 1456-1589, `AbyssZShotCH3_*` 1591-1725.
* **01_F**: Common 1, Green 82, Blue 164, Purple 246, Yellow 328, Red 410,
  Black 492, White 574, BlackEX 656, WhiteEX 739, Abyss 822, Brown 916,
  Cyan 1009, Fireblu 1092, Gray 1183. **No projectile classes in this file** —
  it uses `FireSGguy2_*` from `CHP/DECORATE/14/14_F.txt`.
* **01_BR**: Common 1, Green 122, Blue 244, Purple 366, Yellow 488, Red 610,
  Black 732, White 854, BlackEX 976, WhiteEX 1099, Abyss 1222, Brown 1345,
  Cyan 1468, Fireblu 1590, Gray 1714. **No projectile classes** — hitscan only.
* **01_GY**: Common 1, Green 85, Blue 169, Purple 253, Yellow 337, Red 421,
  Black 505, White 589, BlackEX 673, WhiteEX 758, Abyss 843, Brown 942,
  Cyan 1041, Fireblu 1125, Gray 1215. Projectiles `ZombieRock_*` 1300-1553.

### 6.4 Damage roll register — every roll in these five tiers, unflattened

Per CLAUDE.md's standing rule. Anything here that appears in the port as a
constant is data loss.

| where | roll | file:line |
|---|---|---|
| T05 bullets, per bullet | `random(1,3) * random(1,3)` (damageperbullet × engine multiplier; no CBAF_NORANDOM) | CHP `01_Y.txt:32,34,36` |
| T05 rocket impact | `random(5,40)` | CHP `01_Y.txt:1487` |
| T05 rocket splash | `random(5,15)` r58 | CHP `01_Y.txt:1502` |
| T05 rocket aim jitter | `random(-2,2)` | CHP `01_Y.txt:41` |
| T06 bolt impact | `random(5,30)` | CHP `01_A.txt:1211` |
| T06 bolt splash | `random(1,8)` r42 | CHP `01_A.txt:1225` |
| T06 bolt aim | `random(-7,1)` / `random(-1,7)` | CHP `01_A.txt:33,34` |
| T06 splash shard | `random(1,9)` | CHP `03_A.txt:2091` |
| T07 detonation | `random(12,44)` r84 | CHP `01_F.txt:65` |
| T07 fireball impact | `random(5,15)` | CH `Archviles.txt:2291` |
| T07 fireball splash | `random(3,9)` r32, **×8 frames** | CHP `14_F.txt:2002` |
| T08 sniper shot | **NO ROLL — flat 10 with CBAF_NORANDOM.** CHP's own constant. | CHP `01_BR.txt:39` |
| T09 rock | `Random(1,12)` | CHP `01_GY.txt:1306` |
| T09 rock aim | `random(-2,2)` (volley) / `random(-359,359)` (death burst) | CHP `01_GY.txt:28-30,67` |

### 6.5 Sound register

| sound | first use | SNDINFO |
|---|---|---|
| `lady/aggro` `lady/hurt` `lady/die` `lady/active` | T05 (inherited) | `CH/SNDINFO.txt:1100,1102,1101,1103` |
| `Jam/Jamd` | T05 `:47,49,50,51` | `CH/SNDINFO.txt:1104` → `CORK` |
| `chainguy/attack` | T05 `:31` | IWAD/GZDoom |
| `weapons/rocklf` `weapons/rocklx` | T05 projectile, T07 `:64`, T09 `:65` | IWAD/GZDoom |
| `Zom2/see` | T06 `:7`, T08 `:9`, T09 `:7` | `CH/SNDINFO.txt:1114` |
| `Form2/hurt` `Form2/active` | T06/T08/T09 | `CH/SNDINFO.txt:1118,1119` |
| `imp2/die` | T06 `:9` | `CH/SNDINFO.txt:1095` |
| `imp/attack` `imp/shotx` | T06 & T07 projectiles | IWAD/GZDoom |
| `grunt/sight` `grunt/attack` `grunt/pain` `grunt/death` `grunt/active` | T07 `:7-11`, T09 `:8` | IWAD/GZDoom |
| `SNPRFIRE` | T08 `:10` — **declared, never played (§0.3)** | `CH/SNDINFO.txt:201` |
| `zom2/die` | T08 `:12`, T09 `:10` | CH SNDINFO |
| `monster/hamflr` `Butcher/melee` | T09 projectile | `CH/SNDINFO.txt:718,868` |
| `misc/gibbed/c` | T05 `:74`, T06 `:56`, T08 `:99` | **UNDEFINED (§0.2)** |

### 6.6 What I could NOT determine

Stated plainly rather than guessed:

1. **Whether `DamageThing(9999)` in T07's Melee also damages the player.** §3.4.
   Needs an in-engine check on the owner's walkthrough.
2. **Whether `thrustthing(angle,…)`'s heading is actually wrong.** §0.6. The
   byte-angle/degree mismatch is documented behaviour, but I have not seen the
   leap on screen.
3. **Whether T05's un-cleared `Translation` is intentional.** §1.1. It is
   objectively different from the other four tiers; the file gives no reason.
4. **Whether `A_RadiusGive("health", …, 50)` heals exactly 50** or is capped by
   the recipient's MaxHealth. `Health` is a GZDoom base class, not a CH/CHP
   actor, so there is nothing in ART SOURCE to read. Behaviour, not text.
5. **`A_Playsound("Jam/Jamd",0,1.9)`** — volume 1.9 exceeds 1.0 (T05 `:47`,
   `:49`, `:50`, `:51`). Whether GZDoom clamps or amplifies I did not verify.
```
