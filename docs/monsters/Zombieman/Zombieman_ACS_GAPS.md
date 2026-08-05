# Zombieman (family 01) — ACS inventory + gap list vs `RS_Zombieman.zs`

Written 2026-08-04 under `docs/rs_21_port_law.txt`. Documentation only; no
`.zs`/`.zsc` touched, nothing staged.

## Path abbreviations used below

| Alias | Absolute path |
|---|---|
| `CHP01/` | `E:\New folder\ART SOURCE\CHP\DECORATE\01\` |
| `CHPDEC` | `E:\New folder\ART SOURCE\CHP\DECORATE.txt` |
| `CHPSRC/` | `E:\New folder\ART SOURCE\CHP\source\` |
| `CHZOM` | `E:\New folder\ART SOURCE\CH\decorate\Zombies.txt` |
| `CHDEC` | `E:\New folder\ART SOURCE\CH\DECORATE.txt` |
| `RSZM` | `E:\RS_Main\zscript\monsters\RS_Zombieman.zs` |
| `RSHP` | `E:\RS_Main\zscript\monsters\monsterfx\RS_human_projectiles.zs` |

Tier ↔ CHP actor mapping used throughout (rs_21 §1: port the `Common*` actors):

| Tier | CHP file | Common actor | line |
|---|---|---|---|
| T00 | `CHP01/01_C.txt` | `CommonCommonZombie` | 1 |
| T01 | `CHP01/01_G.txt` | `CommonGreenZombie` | 1 |
| T02 | `CHP01/01_B.txt` | `CommonBlueZombie` | 1 |
| T03 | `CHP01/01_CY.txt` | `CommonCyanZombie` | 1 |
| T04 | `CHP01/01_P.txt` | `CommonPurpleZombie` | 1 |
| T05 | `CHP01/01_Y.txt` | `CommonYellowZombie` | 1 |
| T06 | `CHP01/01_A.txt` | `CommonAbyssZombie` | 1 |
| T07 | `CHP01/01_F.txt` | `CommonFirebluZombie` | 1 |
| T08 | `CHP01/01_BR.txt` | `CommonBrownZombie` | 1 |
| T09 | `CHP01/01_GY.txt` | `CommonGrayZombie` | 1 |
| T10 | `CHP01/01_R.txt` | `CommonRedZombie` | 1 |
| T11 | `CHP01/01_K.txt` | `CommonBlackZombie1` | 1 |
| T12 | `CHP01/01_W.txt` | `CommonWhiteZombie1` | 1 |
| TEX | `CHP01/01_KX.txt` | `CommonBlackZombieEX2` | 1 |
| TEX-W | `CHP01/01_WX.txt` | **does not exist** — file is 2 bytes, contents `//` | — |

---

# JOB 1 — THE ACS

## 1.1 Every ACS invocation in `CHP01/*.txt`

A case-insensitive sweep for `ACS_NamedExecute`, `ACS_NamedExecuteAlways`,
`ACS_NamedExecuteWithResult` and `CallACS` across all fifteen `CHP01/*.txt`
files returns exactly **four distinct script names** (146 call sites, almost
all of them the per-spawn-colour duplicates rs_19 describes):

| Script | Called from | Sites in family 01 | Source | Verdict |
|---|---|---|---|---|
| `AnnounceBlackZombie_<colour>` | `CHP01/01_K.txt:17,137,257,377,497,617,737,857,978,1099,1219,1361,1499,1623,1788` and `CHP01/01_KX.txt:22,216,410,604,798,992,1186,1380,1575,1770,1964,2176,2384,2582,2835` | 30 | `CHPSRC/Bosses.acs:635` | COSMETIC |
| `AnnounceWhiteZombie_<colour>` | `CHP01/01_W.txt:17,210,403,596,789,982,1175,1382,1576,1770,1963,2176,2389,2582,2808` | 15 | `CHPSRC/Bosses.acs:2420` | COSMETIC |
| `EXBOSS` | `CHP01/01_KX.txt:23,217,411,605,799,993,1187,1381,1576,1771,1965,2177,2385,2583,2836` | 15 | `CHPSRC/Bosses.acs:4331` | **MOSTLY COSMETIC — one real part (screen shake)** |
| `CH_WZPlan` (via `CallACS`) | `CHP01/01_W.txt:8939-8941, 8972-8974, 9005-9007, 9038-9040, 9071-9073, 9104-9106, 9137-9139, 9170-9172, 9205-9207, 9239-9241, 9273-9275, 9306-9308, 9340-9342, 9373-9375, 9406-9408` | 45 | `CHPSRC/CHSett2.acs:74` | CVAR READER — but **it gates a real mechanic**, see 1.3 |

### `AnnounceBlackZombie_C` — `CHPSRC/Bosses.acs:635-640`

```
script "AnnounceBlackZombie_C" (void) {
    SetFont("smallfont");
    SetHudSize(640,480,0);
    Hudmessagebold(s:"\c[ColorC]Player 9 joined the server (black zombie spawned)\c-\c-";
    HUDMSG_FADEINOUT | HUDMSG_LOG | HUDMSG_COLORSTRING, 613, "ColorC", 320.4, 160.0, 3.5, 1.0);
}
```

DOES: prints one HUD line when a Player-9 spawns. No actor property, no
inventory, no damage, no thrust.
**VERDICT: COSMETIC.** The fourteen colour siblings (`_G` at :642, `_B` at :649,
`_P` at :656, …) are byte-identical apart from the colour token and the message
id. Correctly dropped by our port (`RSZM:63`).

### `AnnounceWhiteZombie_C` — `CHPSRC/Bosses.acs:2420-2425`

```
script "AnnounceWhiteZombie_C" (void) {
    SetFont("smallfont");
    SetHudSize(640,480,0);
    Hudmessagebold(s:"\c[ColorC]Are you ready to roll some bones?\c-";
    HUDMSG_FADEINOUT | HUDMSG_LOG | HUDMSG_COLORSTRING, 2313, "ColorC", 320.4, 152.0, 3.5, 1.0);
}
```

DOES: one HUD line on Undertaker spawn.
**VERDICT: COSMETIC.**

CAUTION, and this is the trap rs_19 warns about: the Undertaker's `Scripted:`
state does **two** things, and only the first is this announcer —

```
CHP01/01_W.txt:16   Scripted:
CHP01/01_W.txt:17       MAGE A 0 ACS_NamedExecuteAlways("AnnounceWhiteZombie_C")
CHP01/01_W.txt:18       MAGE A 0 A_Radiusgive("CHWhitePlan",16383,RGF_NOSIGHT|RGF_MONSTERS)
```

Line 18 is not ACS and is not cosmetic. See §1.3.

### `EXBOSS` — `CHPSRC/Bosses.acs:4331-4337`

```
script "EXBOSS" (void) {
    SetFont("smallfont");
    SetHudSize(480,360,0);
    Hudmessagebold(s:"A chill runs down your spine...";
    HUDMSG_TYPEON, 13, CR_GRAY, 240.4, 35.0, 3.5);
	Radius_quake(1,35,0,1200,0);
}
```

DOES: a typed-on message, **plus `Radius_Quake(intensity 1, duration 35 tics,
damrad 0, tremrad 1200, tid 0)`** — a real 1-second screen shake felt out to
1200 map units by every player, fired the instant Player X spawns.
**VERDICT: COSMETIC-PLUS.** The message is cosmetic; the quake is a real
engine effect. Our port has neither (`RSZM:1089-1091` `Spawn.TEX` is just the
look loop). This matches rs_19's "9 HUD-MESSAGE ONLY … the quake is the only
real part" bucket. Cheap to restore: one `A_Quake(1, 35, 0, 1200)` in
`Spawn.TEX`.

### `CH_WZPlan` — `CHPSRC/CHSett2.acs:74-77`

```
Script "CH_WZPlan" (void)
{
    SetResultValue(GetCVar("CH_WZPlan"));
}
```

DOES: returns the CVar. Default is `server int CH_WZPlan = 1;`
(`E:\New folder\ART SOURCE\CHP\CVARINFO.txt:4`), exposed in CH's own options
menu at `E:\New folder\ART SOURCE\CHP\MENUDEF.txt:158`
(`Option "White Zombie Skeletons","CH_WZPlan","WZPlan_A"`).
**VERDICT: CVAR READER — droppable as a script, NOT droppable as a branch.**
The reader itself is CH menu infrastructure and this project has its own
MENUDEF/CVARINFO, so rs_19's "36 CH OPTIONS READERS … CORRECTLY DROPPED"
applies to the *script*. But the value selects between three real behaviours
at `CHP01/01_W.txt:8939-8944`:

```
	Spawn:
		TNT1 A 0 Nodelay A_JumpIf(CallACS("CH_WZPlan") == 1,"DoIt")
		TNT1 A 0 A_JumpIf(CallACS("CH_WZPlan") == 2,"Maybe")
		TNT1 A 0 A_JumpIf(CallACS("CH_WZPlan") == 3,"Death2")
	Maybe:
		TNT1 A 0 A_Jump(85,"DoIt")
		Goto Death2
```

1 = always hatch a skeleton, 2 = 85/256 chance, 3 = never. **Default is 1.**
Dropping the reader is fine; dropping the `DoIt` branch is not, and that is
what happened (§1.3).

## 1.2 Every inventory token the family touches, and its own definition

A sweep of `CHP01/*.txt` for `A_GiveInventory` / `A_RadiusGive` /
`A_JumpIfInventory` / `A_TakeInventory` yields nine distinct tokens plus the
vanilla `Health`. Each one's DECORATE body was opened. **None of them is an ACS
wrapper** — that is the honest result here, and it is the opposite of the
Cacodemon `SpeedBuffPE` case in rs_19.

| Token | Definition | Body | Verdict |
|---|---|---|---|
| `CHWhitePlan` | `CHP01/01_W.txt:9430-9433` | `Actor CHWhitePlan : Inventory { Inventory.MaxAmount 1 }` | plain marker — but see §1.3, it gates a large mechanic |
| `CHAbyssMark` | `CHDEC:895-898` | `Actor CHAbyssMark : Inventory { Inventory.MaxAmount 1 }` | plain marker, gates `AbyssGrow` |
| `GrowRaisin` | `CHDEC:885-888` | `Actor GrowRaisin : Inventory { Inventory.MaxAmount 1 }` | plain marker, gates `Grow` (tier promotion — RS owns tiering) |
| `ShotgunWhere` | `CHZOM:2025` | `Actor ShotgunWhere : Inventory { Inventory.MaxAmount 1 }` | plain counter — **ported** as `rsShellUsed` (`RSZM:87`) |
| `RocketCounter` | `CHZOM:1439` | `Actor RocketCounter : Inventory { Inventory.MaxAmount 3 }` | plain counter — **ported** as `rsRockets` (`RSZM:86`) |
| `BoneUp` | `CHZOM:2219` | `Actor BoneUp : Inventory { Inventory.MaxAmount 30 }` | plain counter — see §1.3 for where it comes from |
| `BoneUp2_<colour>` | `CHP01/01_W.txt:8399-8411` (`_C`), siblings 8413-8608 | `CustomInventory`, `Pickup:` spawns `SpirZom_C` + particles + `ice/Cast` | cosmetic aura on the Undertaker |
| `IcyShoeToken` | `CHPDEC:65-68` | `Actor IcyShoeToken : Inventory { Inventory.MaxAmount 200 }` | **ACS-consumed** — see §1.4 |
| `AbyssEffectToken` | `CHPDEC:79-82` | `Actor AbyssEffectToken : Inventory { Inventory.MaxAmount 200 }` | **ACS-consumed** — see §1.4 |
| `Health` (vanilla) | IWAD | — | used as a heal payload, `CHP01/01_BR.txt:58`, `CHP01/01_W.txt:3027` |

## 1.3 THE FINDING — the Undertaker's skeleton economy

This is not an ACS mechanic; it is a token+DECORATE mechanic gated by one ACS
CVar read. It is the largest thing this family has and our port removed all of
it. Documented here because Job 1's remit is "find the token, then find the
token's own definition" and this is where that chain leads.

The loop, every link quoted:

1. **The Undertaker marks the whole map on spawn.**
   `CHP01/01_W.txt:18`
   ```
   MAGE A 0 A_Radiusgive("CHWhitePlan",16383,RGF_NOSIGHT|RGF_MONSTERS)
   ```
   Radius 16383 = every monster on the level, through walls.

2. **Ten of the other tiers' Death states check that mark.** All ten
   verified open:
   `CHP01/01_C.txt:34` `POSS H 5 A_JumpIfInventory("CHWhitePlan",0,"Tick")`
   `CHP01/01_G.txt:46` `ZOMG H 5 A_JumpIfInventory("CHWhitePlan",0,"Tickles")`
   `CHP01/01_B.txt:39`, `CHP01/01_P.txt:50`, `CHP01/01_Y.txt:66`,
   `CHP01/01_A.txt:48`, `CHP01/01_F.txt:45`, `CHP01/01_BR.txt:86`,
   `CHP01/01_GY.txt:43`, `CHP01/01_R.txt:49`.
   T03, T11, T12 and TEX carry no such branch.
   The `Tickles` state is the same everywhere, e.g. `CHP01/01_C.txt:28-30`:
   ```
   Tick:
       TNT1 A 0 A_Spawnitemex("WhiteZombiePlan_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION)
       Goto Death+2
   ```

3. **`WhiteZombiePlan_C` hatches a skeleton** — `CHP01/01_W.txt:8930-8960`,
   gated by `CH_WZPlan` (default 1 = always):
   ```
   Hatch:
       BBBN BCD 5
       TNT1 AAAAAAAAAAAAAAA 0 a_Spawnparticle("White",...)
       TNT1 A 3 Bright A_Spawnitemex("MrBones_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION)
       Goto Death2
   ```

4. **The Undertaker's own projectiles also raise skeletons where they land.**
   `CHP01/01_W.txt:6608` (bone bolt, 250/256 chance):
   ```
   MISL D 0 A_Spawnitemex("MrBones_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION,250)
   ```
   `CHP01/01_W.txt:7126` (shovel blade, 128/256 chance):
   ```
   TNT1 A 0 A_Spawnitemex("MrBones_C",0,0,6,0,0,0,0,SXF_NOPOINTERS|SXF_NOCHECKPOSITION,128)
   ```

5. **The skeleton's death feeds the Undertaker.** `MrBones_C` is
   `CHP01/01_W.txt:2980` (parent `MrBones` at `CHZOM:2114`); its Death state
   `CHP01/01_W.txt:3027-3029`:
   ```
   SKLT P 0  A_Radiusgive("Health",528,RGF_MONSTERS,random(12,128),"CommonWhiteZombie1")
   SKLT P 0  A_Radiusgive("BoneUp2_C",528,RGF_MONSTERS,1,"CommonWhiteZombie1")
   SKLT P 12 A_Radiusgive("BoneUp",528,RGF_MONSTERS,1,"CommonWhiteZombie1")
   ```
   A rolled **12-128 heal** and one `BoneUp` charge, filtered to the Undertaker
   class only, at 528 units.

6. **`BoneUp` is the buff ladder, and it is read in `See`, not in `Pain`.**
   `CHP01/01_W.txt:24-26`:
   ```
   MAGE E 0 A_JumpIfInventory("BoneUp",12,"Buff3")
   MAGE E 0 A_JumpIfInventory("BoneUp",9,"Buff2")
   MAGE E 0 A_JumpIfInventory("BoneUp",5,"Buff1")
   ```

**BEHAVIOUR IN PLAIN WORDS:** the Undertaker turns the whole level into its
supply line. Every monster that dies anywhere on the map while it lives leaves
a skeleton behind; so does most of its own gunfire. Those skeletons fight for
it, and when they die within 528 units they heal it for 12-128 and push it one
step up its own power ladder. Kill things near it and you make it stronger; do
nothing and its own bolts still farm it. That is the fight.

**WHAT OUR PORT HAS:** `RSZM:170-204` `RS_ClimbLadder()` raises the charge one
step **every time the Undertaker takes a hit** (`RSZM:275-279`, the Pain
dispatcher). There is no `MrBones`, no `WhiteZombiePlan`, no map-wide mark, no
heal, and the ladder input is a different quantity entirely. `RSZM:54-57`
describes the CH staircase correctly but attaches it to the wrong trigger.

## 1.4 `IcyShoeToken` / `AbyssEffectToken` — real ACS, but NOT reachable from the Common ladder

These two tokens ARE consumed by ACS. `CHPSRC/NICEICE.acs` is 106 lines and
four of its six scripts touch them.

`CHPSRC/NICEICE.acs:21-47`:
```
script "CH_IcyScript2" Enter
{
	if (CheckInventory("IcyShoeToken") > 200) {
		TakeInventory("IcyShoeToken",99999999);
		GiveInventory("IcyShoeToken",200);
		restart;
	}
	int icyshoe = (CheckInventory("IcyShoeToken") - 2) / 10;
	if (CheckInventory("IcyShoeToken") >= 1) {
		GiveInventory("IcyShoes",1);
		SetHudSize(320,240,0);
		Hudmessagebold(i:icyshoe + 1;
		HUDMSG_PLAIN|HUDMSG_COLORSTRING,0,"ColorCY",160.0,110.0,1.0 / 5 + 1);
		Delay(7);
		restart;
	} else {
		TakeInventory("IcyShoes",99999999);
		Delay(1);
		restart;
	}
}
```
plus the decay pump `CH_IcyScript` at `CHPSRC/NICEICE.acs:4-19` (drains 2
tokens every 7 tics), and the `AbyssEffectToken` mirror pair
`CH_AbyssyEffectScript` / `CH_AbyssyEffectScript2` at
`CHPSRC/NICEICE.acs:65-106`.

The payloads are `PowerSpeed` subclasses, `CHPDEC:70-77` and `CHPDEC:84-91`:
```
Actor IcyShoes : PowerSpeed
{ Speed 0.4  Powerup.Color "Cyan", 0.1333  PowerSpeed.NoTrail 1
  Powerup.Duration 99999999  +INVENTORY.NOSCREENBLINK }

Actor AbyssEffect : PowerSpeed
{ Speed -1  Powerup.Color "48 60 78", 0.2667  PowerSpeed.NoTrail 1
  Powerup.Duration 99999999  +INVENTORY.NOSCREENBLINK }
```

DOES: a stacking player debuff. Each token is ~7 tics of effect; hits stack up
to a 200-token cap; while any remain the player is dropped to 0.4× movement
speed (ice) or has movement inverted (abyss, `Speed -1`), tinted, with a
counter drawn on the HUD; the token pool bleeds off at 2 per 7 tics so it wears
off on its own.
**VERDICT: REAL BEHAVIOUR.**

**BUT — it is not reachable from the tier ladder we are porting.** Every grant
site in family 01 sits inside a **spawn-colour** `_CY` or `_A` sub-variant of a
projectile or puff, never the `_C` (Common) one that the `Common*` actors fire.
Verified by opening the owning actor at each site:

* `CHP01/01_CY.txt:1042` `Actor IceZombieShot_A : IceZombieShot_C` → grant at :1053
* `CHP01/01_CY.txt:1068` `Actor IceZombieShot_CY : IceZombieShot_C` → grant at :1079
* `CHP01/01_C.txt:1231` `Actor BulletPuff_A_1 : BulletPuff_A` → grant at :1237
* `CHP01/01_C.txt:1423` `Actor BulletPuff_CY_1 : BulletPuff_CY` → grant at :1429

and the Common versions carry no grant at all —
`CHP01/01_CY.txt:934-957` `IceZombieShot_C` has `Death: ICEY FGHI 5 Bright /
Stop`, nothing else; `CHP01/01_C.txt:1173-1175` is `Actor BulletPuff_C :
BulletPuff { }`, an empty subclass.

**Conclusion for the port:** NICEICE is real behaviour and belongs on the
rebuild list, but it is owed to the **spawn-colour axis** rs_21 §1 defers, not
to T00-TEX. Nothing is missing from our Common ladder on account of it. Record
it so the colour axis does not land later without it.

## 1.5 ACS totals for family 01

* **4** distinct ACS scripts invoked directly (146 call sites).
* **1** of the 4 carries real behaviour, and only partially: `EXBOSS`'s
  `Radius_quake(1,35,0,1200,0)` (`CHPSRC/Bosses.acs:4336`).
* **2** are pure announcers (COSMETIC, correctly dropped).
* **1** is a CVar reader whose *branch* gates the skeleton economy (§1.3).
* **2** further real-behaviour scripts (`CH_IcyScript2`,
  `CH_AbyssyEffectScript2`, `CHPSRC/NICEICE.acs`) reach this family only
  through the deferred spawn-colour axis (§1.4).
* **0** tokens in this family are "empty DECORATE wrapper around an ACS call".
  The rs_19 failure pattern does not occur here; the equivalent trap in this
  family is §1.3, where the wrapper is an empty *Inventory marker* and the
  behaviour is in the thirteen DECORATE states that read it.

---

# JOB 2 — THE GAP LIST

## 2.0 What is already RIGHT — read this first

These were checked line-by-line against the CHP file and match. This is most of
the state machine.

* **Every tier's Health / Speed / PainChance is exactly CHP's.** `RSZM:116-130`
  against `CHP01/01_C.txt:3-5`, `01_G.txt:3-5`, `01_B.txt:3-5`, `01_CY.txt:3-5`,
  `01_P.txt:3-5`, `01_Y.txt:3-5`, `01_A.txt:3,5,6`, `01_F.txt:3,5,6`,
  `01_BR.txt:5,7,6`, `01_GY.txt:3-5`, `01_R.txt:3,5,6`, `01_K.txt:3,5,6`,
  `01_W.txt:3,5,6`, `01_KX.txt:3,5,6`. Fourteen for fourteen.
* **Every hitscan damage roll survives as a roll.** `A_CustomBulletAttack`
  arguments match CHP exactly at `RSZM:293` (`random(1,5)*3` ↔
  `CHP01/01_C.txt:25`), `RSZM:335,338` (↔ `01_G.txt:30,33`), `RSZM:379`
  (`7,7,3,random(1,3)` ↔ `01_B.txt:26`), `RSZM:459-460` (↔ `01_P.txt:29-30`),
  `RSZM:517,519,521` (↔ `01_Y.txt:32,34,36`), `RSZM:683` (↔ `01_BR.txt:39`),
  `RSZM:806` (`10,2,1,random(5,15)` ↔ `01_R.txt:22`), `RSZM:874`
  (`22.5,5,8,6` ↔ `01_K.txt:43`), `RSZM:903` (`5.6,0,1,5` ↔ `01_K.txt:72`),
  `RSZM:1142,1220` (↔ `01_KX.txt:76,144`).
* **Sprite tokens, frame letters and tic counts** match frame-for-frame on
  every state I diffed except the four listed in §2.2. Spot checks:
  T09 `XDeath` thirteen-rock ring `RSZM:788` is thirteen `A`s, exactly
  `CHP01/01_GY.txt:67`; T12 `ShotBone` 9 / `ShotBone2` 12 / `ShotBone3` 11
  `F`s at `RSZM:1004,1008,995` ↔ `CHP01/01_W.txt:82,86,73`.
* **`Goto <state>+N` offsets were resolved correctly.** `CHP01/01_BR.txt:36,44`
  `Goto See+3` → `RSZM:680,688` `Goto See.T08.Half`; `CHP01/01_R.txt:38`
  `goto Missile2+1` → `RSZM:811` `Missile.T10.RailLoop`;
  `CHP01/01_W.txt:69,96,103` `Goto RapidBone3+1 / RapidBone+2 / RapidBone2+1`
  → `RSZM:987,1014,1022`. These are the easiest thing in the file to get
  wrong and they are right.
* **The `thrustthingz` / `thrustthing` quarter-unit conversion is right.**
  `CHP01/01_BR.txt:47` `thrustthingz(0,30,…)` → `RSZM:691` `vel.z += 7.5`;
  `CHP01/01_W.txt:173` `thrustthingz(0,45,…)` → `RSZM:1055` `vel.z += 11.25`;
  `CHP01/01_KX.txt:70` `thrustthingz(0,64,…)` → `RSZM:1136` `RS_HopZ(16)`.
* **T03 and T12 correctly have no `XDeath` / no `Raise`**, matching
  `CHP01/01_CY.txt:16-58` and `CHP01/01_W.txt:11-186`; T11 correctly has no
  `Raise` (`CHP01/01_K.txt:11-115`). `RSZM:70` records this honestly.
* **The `ZOMG U` omission at `RSZM:353-355` is CORRECT and I verified it.**
  `CHP01/01_G.txt:62-64` uses `ZOMG U`; CH ships `ZOMGN0…ZOMGT0` only
  (`E:\New folder\ART SOURCE\CH\sprites\zombies\`), and the repo has
  `E:\RS_Main\sprites\monsters\Zombieman\T01\ZOMGT0.lmp` with no `ZOMGU0`
  anywhere. The substitution is justified and documented.
* **`BulletPuff` is not a collapsed variant.** `CHP01/01_C.txt:1173-1175` is
  `Actor BulletPuff_C : BulletPuff { }` — an empty subclass. Using stock
  `BulletPuff` at `RSZM:293` etc. is faithful, not a shortcut. Same for
  `BloodyPuff_C` (`CHP01/01_R.txt:1602-1604`, empty subclass of `CHZOM:1553`),
  and `RSHP:605-616` reproduces `CHZOM:1553-1567` exactly.
* **`RS_PlasmaBallSP3`** (`RSHP` via
  `E:\RS_Main\zscript\monsters\monsterfx\RS_spidermind_projectiles.zs:224-229`)
  matches `E:\New folder\ART SOURCE\CHP\DECORATE\12\12_B.txt:1232-1257`
  property for property, including `Damage 5` which is a genuine constant in
  CHP. **`RS_Rocket`** (`RSHP:620-635`) likewise matches
  `E:\New folder\ART SOURCE\CHP\DECORATE\17\17_C.txt:965-989`, `Damage 20`
  constant. **`RS_PlayerEXBFG`** (`RSHP:1133-1157`) is the best-ported actor in
  the family — it keeps `DamageFunction (random(100,200))` against
  `CHP01/01_KX.txt:3013`, keeps `A_Explode(random(45,125),156)` against
  `CHP01/01_KX.txt:3030`, and the 29-shard `TNT1 A×29` count is exact.
* **`RS_SplashAbyss`** (`E:\RS_Main\zscript\monsters\monsterfx\RS_imp_projectiles.zs:203-223`)
  has `Speed 16; FastSpeed 23`, exactly `SplashAbyss_C`
  (`E:\New folder\ART SOURCE\CHP\DECORATE\03\03_A.txt:1979-1984`).
* **T08's Radius/Height/Scale are right and it is worth saying so**, because
  the CH parent `BrownZombie2` sets `Radius 24` (`CHZOM:45`), `Height 64`
  (`CHZOM:46`), `scale 0.9` (`CHZOM:48`) and it is easy to "fix" our file to
  those. CHP overrides them
  back to `Radius 20 / Height 56 / Scale 1` at `CHP01/01_BR.txt:3,4,8`, so our
  default (`RSZM:92-93`) is correct. Do not change it.

## 2.1 CROSS-CUTTING gaps (apply to the whole family)

### G-1. Damage rolls flattened to constants in the projectiles — 16 instances

`RSHP:25` states the policy outright: `Damage->constants.` and `RSHP:210`
repeats it: `Damage -> constants, house style.` and `RSHP:663-665` again. This
is the exact data loss CLAUDE.md forbids, applied deliberately and at scale.
Every one of these is a `DamageFunction (random(a,b))` in ZScript.

| CHP source | CHP roll | Our value |
|---|---|---|
| `CHP01/01_CY.txt:939` `IceZombieShot_C` | `Damage (random(6,16))` | `RSHP:37` `Damage 11` |
| `CHP01/01_P.txt:1339` `Orbb11_C` | `Damage (random(2,18))` | `RSHP:43` `Damage 10` |
| `CHP01/01_Y.txt:1487` `MiniRKTZombie_C` | `Damage (random(5,40))` | `RSHP:49` `Damage 22` |
| `CHP01/01_Y.txt:1502` `MiniRKTZombie_C` death | `A_Explode(random(5,15),58)` | `RSHP:50` `A_Explode(120, 80, …)` |
| `CHP01/01_A.txt:1211` `AbyssZShotCH_C` | `Damage (random(5,30))` | `RSHP:54` `Damage 17` |
| `CHP01/01_A.txt:1225` `AbyssZShotCH_C` death | `A_Explode(random(1,8),42)` | `RSHP:55` `A_Explode(51, 48, …)` |
| `CHP01/01_G.txt:1418` `Gas11_C` death | `A_Explode(random(1,8),32)` | `RSHP:33` `A_Explode(24, 48, …)` |
| `CHP01/01_GY.txt:1306` `ZombieRock_C` | `Damage (Random(1,12))` | `E:\RS_Main\zscript\monsters\monsterfx\RS_baron_projectiles.zs:491` `Damage 6` |
| `CHP01/01_W.txt:6585` `BoneProjZM_C` | `Damage (random(4,16))` | `RSHP:218` `Damage 10` |
| `CHP01/01_W.txt:6873` `BoneProjZM2_C` | `Damage (random(8,20))` | `RSHP:231` `Damage 14` |
| `CHP01/01_W.txt:6983` `BoneProjZM3_C` | `Damage (random(12,26))` | `RSHP:232` `Damage 19` |
| `CHP01/01_W.txt:7095` `ShoveZM_C` | `damage (random(10,45))` | `RSHP:253` `Damage 20` |
| `CHP01/01_W.txt:7125` `ShoveZM_C` death | `A_Explode(random(5,20),64)` | `RSHP:269` `A_Explode(12, 64)` |
| `CHZOM:2554` `BoneStormer1` | `Damage (random(1,3))` | `RSHP:288` `Damage 2` |
| `E:\New folder\ART SOURCE\CHP\DECORATE\14\14_F.txt:1992` `FireSGguy2_C` | `Damage (random(5,15))` | `E:\RS_Main\zscript\monsters\monsterfx\RS_archvile_projectiles.zs:113` `Damage 10` |
| `E:\New folder\ART SOURCE\CHP\DECORATE\03\03_A.txt:2092` `SplashAbyss2_C` | `Damage (random(1,9))` | `E:\RS_Main\zscript\monsters\monsterfx\RS_imp_projectiles.zs:229` `Damage 4` |

Note also that several of the "constants" are not even the mean: `Gas11_C`'s
`random(1,8)` blast (mean 4.5, radius 32) became 24 damage at radius 48 —
5× the damage over 2.2× the area; `MiniRKTZombie_C`'s `random(5,15)` at
radius 58 became 120 at radius 80.

### G-2. No `RS_AttackProfile` sockets at all — rs_21 §5 not started for this family

`RS_MonsterMaster` provides `virtual RS_AttackSlot BuildTierAttacks(int t)`
(`E:\RS_Main\zscript\monsters\RS_MonsterMaster.zs:690`). `RSZM` does not
override it — grep for `BuildTierAttacks` in `RSZM` returns nothing. Every one
of the family's ~20 attacks is an inline `A_SpawnProjectile` /
`A_CustomBulletAttack` in state code, so none is reassignable. This is 0 of
~20 against rs_21 §5's requirement.

### G-3. Layout does not follow rs_21 §3

Required: `zscript/monsters/Zombieman/RS_Zombieman.zs`, `…/attacks/*.zs`,
`…/README.txt`, `docs/monsters/Zombieman.md`. Present: a single flat
`E:\RS_Main\zscript\monsters\RS_Zombieman.zs`, projectiles scattered across
five files in `monsterfx/` (`RS_human_projectiles.zs`,
`RS_baron_projectiles.zs`, `RS_imp_projectiles.zs`,
`RS_archvile_projectiles.zs`, `RS_spidermind_projectiles.zs`), no
`zscript/monsters/Zombieman/` directory, no catalog file. Note that
`RS_ZombieRock` living in `RS_baron_projectiles.zs` is exactly the
"named for the first family that happened to use it" problem rs_21 §3 names.

### G-4. `Death.Ice` alias dropped on 13 of 14 tiers

CHP aliases `Death.Ice:` onto the normal `Death:` at `CHP01/01_C.txt:31`,
`01_G.txt:43`, `01_B.txt:36`, `01_CY.txt:39`, `01_P.txt:47`, `01_Y.txt:63`,
`01_A.txt:45`, `01_F.txt:42`, `01_GY.txt:40`, `01_R.txt:46`, `01_K.txt:87`,
`01_W.txt:154`, `01_KX.txt:163`. `RSZM` defines no `Death.Ice` for any tier,
so an ice-damage kill drops the engine's generic frozen-shatter corpse instead
of CHP's normal death animation. **T08 is the exception and is accidentally
correct** — `CHP01/01_BR.txt:81-94` genuinely has no `Death.Ice`, so the
Bodyguard is meant to freeze and shatter.

### G-5. Missing per-tier actor properties CHP/CH set

None of these are carried by `RS_MonsterTierRow`, and `OnTierApplied`
(`RSZM:209-266`) does not set them.

* `Species "Zombie"` on T00-T10 (`CHZOM:792`), `Species "UnderTaker"` on T12
  (`CHZOM:2291`). Without it CHP's `+DONTHARMSPECIES` /
  `RGF_EXFILTER` filtering and the Undertaker's `+dontharmspecies`
  (`CHZOM:2305`) cannot work.
* `DamageFactor "Exorcist",3.0` / `DamageFactor "DIMp",0` /
  `PainChance "DIMp",0` on the light tiers (`CHZOM:793-795`); `DamageFactor
  "Heroic",3.0` on T11/T12/TEX (`CHZOM:1897`, `CHZOM:2292`); per-damagetype
  PainChance on T11 (`CHZOM:1900-1903`: `PLWater 8`, `ice 10`, `Fire 8`,
  `Melee 42`) and TEX.
* Flags: `+AVOIDMELEE` (`CHZOM:797`), and on T11/T12/TEX `+BOSS`,
  `+QUICKTORETALIATE`, `+LOOKALLAROUND`, `+MISSILEMORE`, `+NOFEAR`,
  `-NORADIUSDMG`, `+DONTMORPH` (`CHZOM:1905-1912`, `CHZOM:2296-2305`);
  T12 also `+Notarget` (`CHZOM:2301`); TEX also `+LAXTELEFRAGDMG`
  (`CHZOM:1627`).
* Radius: T11 / T12 / TEX are `Radius 16` (`CHZOM:1892`, `CHZOM:2286`,
  `CHZOM:1611`), T05 is `mass 90` (`CHZOM:1278`) / `Radius 19`
  (`CHZOM:1286`) / `Height 52` (`CHZOM:1287`). `RSZM:92-93` uses 20/56/100
  for all.
* `GibHealth`: T06 -100 (`CHP01/01_A.txt:4`), T07 -5 (`CHP01/01_F.txt:4`),
  T10 -100 (`CHP01/01_R.txt:4`), T11 -500 (`CHP01/01_K.txt:4`), T12 -500
  (`CHP01/01_W.txt:4`), TEX -500 (`CHP01/01_KX.txt:4`). `RSZM:71-72` records
  this as a known omission; it is real and it changes when each tier gibs.
* `BloodColor`: T05 "Yellow" (`CHZOM:1280`), T09 "Black"
  (`CHP01/01_GY.txt:12`), T06 "Black" on the colour variants. Recorded at
  `RSZM:71`.
* `HitObituary`: T11 (`CHP01/01_K.txt:8`), T12 (`CHP01/01_W.txt:9`),
  TEX (`CHP01/01_KX.txt:12`). Not ported. `RSZM:102-103` sets only a single
  family-wide `Obituary`/`Tag`; CHP gives every tier its own coloured pair.
* `DropItem` lists — every CH parent has one and none is ported. The
  Undertaker's own bone bolt drops player ammo (`CHP01/01_W.txt:6595-6598`:
  `implyingclip,48` / `CH_Shell,32` / `CH_Cell,16` / `CH_RocketAmmo,8`), which
  is a resource loop the fight depends on and `RSHP:216-230` has none of.

### G-6. `r.dmgMul` ladder is inert — not a bug, but do not count it as escalation

`RSZM:116-130` sets `dmgMul` 1.0 → 3.5 across the ladder.
`E:\RS_Main\zscript\monsters\RS_MonsterMaster.zs:57-60` states plainly that
this field is data only and is not applied anywhere. So it is **not**
double-counting CHP's escalation — good — but it also means the only per-tier
damage escalation this family has is whatever lives in the projectile classes,
which is where G-1 flattened it.

## 2.2 PER-TIER gaps

### T00 (`CHP01/01_C.txt:1-74`) — essentially complete

* Missing `Death` → `Tick` branch, `CHP01/01_C.txt:34` (§1.3).
* Missing `Death` → `AbyssGrow` branch, `CHP01/01_C.txt:38`, and the
  `Raise` → `Grow` branch, `CHP01/01_C.txt:54`. Both are CHP's tier-promotion
  chain; `RSZM:61-62` records dropping them deliberately because RS owns
  tiering. **That reason is sound — keep it, but keep it written down.**
* `Death.Ice` (G-4), properties (G-5).
* Everything else matches: `Idle`, `See`, `Missile`, `Death`, `XDeath`,
  `Raise` are frame-exact. CHP has **no** `Pain` state here, so the vanilla
  `POSS G 3 / POSS G 3 A_Pain` our `RSZM:296-299` uses is the correct
  inherited behaviour.

### T01 (`CHP01/01_G.txt:1-87`) — complete but for the gas payload

* `Gas11_C` blast flattened, `CHP01/01_G.txt:1418` (G-1). This is the whole
  point of the green zombie and it is the single worst numeric error in the
  family: `random(1,8)` at radius 32 became 24 at radius 48.
* `ZOMG U` substitution is verified correct (§2.0).
* `Death.Ice`, `Tickles`/`AbyssGrow`/`Grow` branches, properties.

### T02 (`CHP01/01_B.txt:1-78`) — complete

* Our `XDeath.T02` correctly omits a visible `M` frame: CHP's `ZOMB M 0`
  (`CHP01/01_B.txt:47`) is a zero-tic carrier, not a displayed frame.
* Only the family-wide gaps apply.

### T03 (`CHP01/01_CY.txt:1-59`) — one wrong frame token

* `RSZM:440-441` uses `MISL X 0` for the shatter sound and `A_Burst`;
  CHP uses `MISL A 0` (`CHP01/01_CY.txt:55-56`). Zero-tic so invisible, but
  it is a wrong token and should read `MISL A`.
* `IceChunk` vs CHP's `IceChunk_C` — `CHPDEC:279` is
  `Actor IceChunk_C : IceChunk { }`, empty subclass, so `RSZM:441` is
  behaviourally correct.
* `Translation None` (`CHP01/01_CY.txt:15`) is handled by `RSZM:150`.
* `Renderstyle Translucent / Alpha 0.75` (`CHP01/01_CY.txt:6-7`) →
  `RSZM:261-262` ✔.

### T04 (`CHP01/01_P.txt:1-82`) — complete

* Orb damage flattened (G-1). CHP's `random(2,18)` is a wide spread; 10 is a
  different weapon.
* `RSZM:454-456` reproduces the deliberate fall-through into `Hitscanne`
  (`CHP01/01_P.txt:25-27`) correctly, including the `A_Jump(255,…)` that misses
  1 time in 256.
* Note the CHP inconsistency, quoted so nobody "fixes" it: T00/T01/T07/T09 test
  `A_JumpIfInventory("CHWhitePlan",0,…)` while T04/T05/T06/T10 test with `1`
  (`CHP01/01_P.txt:50` vs `CHP01/01_C.txt:34`). With `MaxAmount 1` both forms
  fire, so it makes no difference — but the two spellings are in the source.

### T05 (`CHP01/01_Y.txt:1-88`) — complete

* Rocket damage and blast flattened (G-1).
* `A_TakeInventory("RocketCounter",3)` (`CHP01/01_Y.txt:52`) → `rsRockets = 0`
  (`RSZM:537`) is equivalent given `MaxAmount 3` (`CHZOM:1439`). ✔
* CHP declares no sounds on `CommonYellowZombie`; the `lady/*` set at
  `RSZM:227-229` is correctly taken from the CH parent `CHZOM:1290-1293`. ✔
* Missing `mass 90` (`CHZOM:1278`), `Bloodcolor "Yellow"` (`CHZOM:1280`),
  `DamageFactor Melee,2` (`CHZOM:1281`), `Radius 19` (`CHZOM:1286`),
  `Height 52` (`CHZOM:1287`).

### T06 (`CHP01/01_A.txt:1-69`) — **one whole state missing**

* **`Fling:` is not ported.** `CHP01/01_A.txt:18-19`:
  ```
  Fling:
      ABTR A 0 A_Radiusgive("CHAbyssMark",528,RGF_MONSTERS|RGF_NOSIGHT|RGF_EXFILTER,1,"CommonAbyssZombie","Zombie")
  ```
  It sits between `Spawn` and `Idle` and therefore runs unconditionally on
  spawn. It marks every Zombie-species monster within 528 units (through
  walls, excluding other Abyss Zombies) so that when they die they run
  `AbyssGrow` and become Abyss Zombie clones. This is an **infection aura**,
  not a colour-promotion detail — it is the Abyss tier's identity, and
  `RSZM:62` sweeps it away with the rest of the "colour-promotion chain".
  RS owning tiering is a legitimate reason to not spawn a CHP actor; it is
  not a reason to have no aura at all.
* AbyssZshot damage and blast flattened (G-1).
* `GibHealth -100` (`CHP01/01_A.txt:4`).
* CH's parent also defines `Pain.AbyssPE:` (`CHZOM:813-828`), a 60-tic
  transformation into an `AbyssZombie2` triggered by Abyss Pain Elemental
  damage. Inherited by every tier through `CommonZombie`; not ported anywhere.
* `See`, `Missile`, `Pain` (including the 47-splash burst), `Death`, `XDeath`,
  `Raise` are otherwise frame-exact — `RSZM:586` is 47 `A`s matching
  `CHP01/01_A.txt:40`.

### T07 (`CHP01/01_F.txt:1-80`) — the fire trail is inert

* `FireSGguy2_C`
  (`E:\New folder\ART SOURCE\CHP\DECORATE\14\14_F.txt:1987-2004`) differs from
  our `RS_FireSGguy2`
  (`E:\RS_Main\zscript\monsters\monsterfx\RS_archvile_projectiles.zs:112-117`)
  in three ways:
  1. `Damage (random(5,15))` → `Damage 10` (G-1).
  2. CHP `Death:` is `FIRE CDEEDCDE 5 Bright A_Explode(random(3,9),32)`
     (`14_F.txt:2002`) then `FIRE FGH 4 Bright` (`:2003`) — **eight ticks of
     radius-32 blast**. Ours is `FIRE CDE 3 Bright` with **no `A_Explode`
     at all**. The kamikaze's trail does nothing on contact in our build.
  3. CHP `Spawn:` is `FIRE AB 6 Bright / Goto Death` (`14_F.txt:1999-2000`) —
     it burns out after 12 tics. Ours is `FIRE AB 3 Bright; Loop;` — it
     persists indefinitely.
* Everything in the monster itself is right, including `Melee` →
  `A_DamageSelf(9999)` (CHP `DamageThing(9999)`, `CHP01/01_F.txt:36`), the
  `XDeath` order, and `Missile:` being a single blank tic
  (`CHP01/01_F.txt:31-33` ↔ `RSZM:623-625`).
* `GibHealth -5` (`CHP01/01_F.txt:4`).

### T08 (`CHP01/01_BR.txt:1-119`) — complete, with one honest divergence to record

* CHP's leap uses `thrustthing(angle,40,0,0)` (`CHP01/01_BR.txt:48`) and
  `thrustthing(angle,14,0,0)` (`:73`). `ThrustThing`'s first parameter is a
  **byte angle (0-255)**, and CHP is feeding it the actor's angle in degrees
  — so CHP's own bodyguard dive goes off at `angle × 360/256`, not along its
  facing. Our `A_Recoil(-40)` / `A_Recoil(-14)` (`RSZM:692,717`) launches it
  along the facing, which is what CHP obviously *meant*. That is a deliberate
  bug-fix, but it is currently undocumented at the site — write it down.
* `A_Radiusgive("health",100,RGF_MONSTERS,50)` (`CHP01/01_BR.txt:58`) ported
  verbatim at `RSZM:702` ✔.
* The class names in `Checks:` were remapped to RS classes
  (`CHP01/01_BR.txt:31-35` ↔ `RSZM:675-679`) with the reason written at
  `RSZM:672-674` ✔. `Cyberdemon` still points at the IWAD class.
* No `Death.Ice` in CHP for this tier — ours is right by accident (G-4).
* `Mass 1000` (`CHZOM:47`) and `+RollSprite` (`CHZOM:57`) applied at
  `RSZM:239-240` ✔; `+noinfighting` (`CHZOM:56`) and `+notargetswitch`
  (`CHZOM:58`) are not.

### T09 (`CHP01/01_GY.txt:1-83`) — complete

* `ZombieRock_C` flattened (G-1) and additionally missing
  `DamageType "Melee"`, `SeeSound "monster/hamflr"`,
  `DeathSound "Butcher/melee"`, `Radius 9 / Height 9`
  (`CHP01/01_GY.txt:1300-1311`); our `RS_ZombieRock`
  (`E:\RS_Main\zscript\monsters\monsterfx\RS_baron_projectiles.zs:489-492`)
  only overrides `Damage` and `Scale` on a Baron rock base.
* CH parent adds `DamaGeFactor Fire,2.0` (`CHZOM:502`) and
  `DamageFactor Melee,2.0` (`CHZOM:504`) — the gray zombie is supposed to be
  soft to fire.
* `Mass 400` (`CHP01/01_GY.txt:6`) ✔ `RSZM:264-265`.

### T10 (`CHP01/01_R.txt:1-70`) — complete

* Only family-wide gaps. Rail colours, tic counts, `A_SentinelRefire` loop
  target and the `HKRedDeath_C` XDeath spray all match
  (`CHP01/01_R.txt:26-38,62` ↔ `RSZM:809-823,839`).
* CHP declares no sounds on `CommonRedZombie`; `RSZM:243-245` correctly takes
  `attacksound "zombie/unmaker"` (`CHZOM:1451`) and the `Zom2`/`Form2` set
  starting `SeeSound "Zom2/see"` (`CHZOM:1456`). ✔

### T11 (`CHP01/01_K.txt:1-116`) — complete, two sound errors

* `SeeSound` and `ActiveSound`: `CommonBlackZombie1` declares none
  (`CHP01/01_K.txt:1-10`) and the CH parent `BlackZombie1` declares none
  either (`CHZOM:1888-1930` — only `DeathSound "*death"` at `CHZOM:1914` and
  `PainSound "*pain50"` at `CHZOM:1915`). Player 9 is **silent** on sight and
  idle.
  `RSZM:211-212` leaves `grunt/sight` / `grunt/active` in place for T11, so
  ours grunts like a zombieman. Wrong sound where CHP has none.
* `Translation "0:0=0:0"` (`CHP01/01_K.txt:10`) — a no-op; `RSZM:150` is
  correct to leave it blank.
* `HitObituary "Player9: Git Gud"` (`CHP01/01_K.txt:8`) not ported.
* `EXBOSS`-style `+BOSS` flag set not ported (G-5).
* Everything in the state machine matches, including the dead code CHP leaves
  after `Goto Missile` in `Rawkets:` (`CHP01/01_K.txt:76-77`) which ours
  correctly does not reproduce.

### T12 (`CHP01/01_W.txt:1-187`) — **the buff ladder numbers are wrong, and its economy is missing**

Beyond §1.3 (the whole `MrBones` / `CHWhitePlan` loop), the ladder we *do*
have does not match CHP.

CHP, quoted:
```
CHP01/01_W.txt:116  Buff1:
CHP01/01_W.txt:122      MAGE E 1 A_ChangeFlag(MISSILEEVENMORE,TRUE)
CHP01/01_W.txt:123      MAGE E 1 A_Setuservar("user_skel1",user_skel1+2)
CHP01/01_W.txt:124      MAGE E 5 A_Setspeed(16)
CHP01/01_W.txt:125      MAGE E 0 A_SetScale(1.1,1.1)
CHP01/01_W.txt:127  Buff2:
CHP01/01_W.txt:133      MAGE E 1 A_Setuservar("user_skel1",user_skel1+1)
CHP01/01_W.txt:134      MAGE E 1 A_Setspeed(21)
CHP01/01_W.txt:135      MAGE E 6 A_SetScale(1.25,1.25)
CHP01/01_W.txt:137  Buff3:
CHP01/01_W.txt:143      MAGE E 0 A_ChangeFlag(NOPAIN,TRUE)
CHP01/01_W.txt:144      MAGE E 1 A_Setuservar("user_skel1",user_skel1+1)
CHP01/01_W.txt:145      MAGE E 1 A_Setspeed(28)
CHP01/01_W.txt:147      MAGE E 0 A_SetScale(1.45,1.45)
```

* **Speed.** CHP sets ABSOLUTE speeds 16 / 21 / 28 from a base of 10
  (`CHP01/01_W.txt:5`) — ×1.6, ×2.1, ×2.8. `RSZM:181,190,200` multiplies
  cumulatively by 1.3 / 1.25 / 1.2, giving 13 / 16.25 / 19.5 — **×1.3, ×1.63,
  ×1.95**. At the top of its ladder the Undertaker should be moving 44%
  faster than ours does.
* **Scale.** CHP sets ABSOLUTE 1.1 / 1.25 / 1.45. `RSZM:183,191,201`
  multiplies cumulatively by 1.08 / 1.10 / 1.12 → 1.08 / 1.19 / 1.33.
* **Trigger.** CHP checks `BoneUp` count in `See` (`CHP01/01_W.txt:24-26`),
  every chase cycle, fed by skeleton deaths. Ours calls `RS_ClimbLadder()`
  once per pain event (`RSZM:275-279`) and adds one charge per hit taken
  (`RSZM:175`).
* **`>=` vs `==`.** CHP gates the bone-grade upgrades on `user_skel1==3`
  (`CHP01/01_W.txt:81,90,110`) — strict equality. At final form
  (`user_skel1==4`) those checks **fail**, so `Shovel` at `CHP01/01_W.txt:110`
  does *not* chain into `ShotBone2`. `RSZM:1034` uses `rsStep >= 2` and does
  chain. Whether CHP's equality is a bug is arguable; the divergence is real
  and undocumented.
* `Buff1` also sets `+MISSILEEVENMORE` (`CHP01/01_W.txt:122`) ↔ `RSZM:182`
  `MissileChanceMult *= 0.125` ✔ — the mapping is right.
* **`ShoveZM` blade count.** CHP fires 27 blades across 12 spawn lines
  (`CHP01/01_W.txt:7109-7120`); `RSHP:259-265` fires 12 across 7 lines. The
  four backward fans at `CHP01/01_W.txt:7117-7120`
  (`random(-190,-175)` with `±6` / `±3` pitch) are absent entirely, and the
  `BLAD AAA 0 A_CustomMissile("ShoveZM2_C",0,0)` line at `:7112` is missing.
  `RSHP:234-235` admits "kept, at reduced count" — honest, and still a gap.
* **`ShoveZM` death.** CHP `CHP01/01_W.txt:7122-7126` is
  `A_PlaySound("moloch/nailhit")` → `BLAD A 1` → `6PUF ABCDEF 1` →
  `FBL1 EFG 1 bright A_Explode(random(5,20),64)` → `MrBones_C`. Ours
  (`RSHP:266-271`) has no sound, no `FBL1` frames, a flat `A_Explode(12,64)`,
  and no skeleton.
* **`BoneTorn2`.** CH's `BoneTorn2` is `+INVISIBLE` (`CHZOM:2488`) with
  `SeeSound "Fire/fire3"` (`CHZOM:2494`); ours (`RSHP:310-331`) is visible and
  uses `skeleton/attack`. CHP's `BoneTorn2_C` (`CHP01/01_W.txt:4268`) spawns
  seven distinct `BoneStormer1_C…7_C` on a long hand-written schedule; ours
  collapses them to one randomised `RS_BoneStormer` (`RSHP:274-306`), which is
  a defensible simplification — but it is a simplification and belongs in a
  note at the site.
* `Mass 400` (`CHP01/01_W.txt:7`) ✔ `RSZM:254`.
* `ActiveSound`: CHP declares none and `WhiteZombie1` declares none — it has
  only `DeathSound "Under/Die"` (`CHZOM:2308`), `SeeSound "Under/See"`
  (`CHZOM:2309`) and `painsound "skelpai"` (`CHZOM:2310`). `RSZM:253` sets
  `grunt/active`. Wrong sound where CHP has silence.
* For the record, CH's own `WhiteZombie1` does the map-wide mark too, with the
  pre-CHP token name: `CHZOM:2331`
  `MAGE A 1 A_Radiusgive("CHBoner",16383,RGF_NOSIGHT|RGF_MONSTERS)`. CHP
  replaces `CHBoner` with `CHWhitePlan`; both were dropped (`RSZM:62`).
* `HitObituary "Shovel to the face?"` (`CHP01/01_W.txt:9`) not ported.

### TEX (`CHP01/01_KX.txt:1-192`) — the taunt is silent, and so is Player X

* **`SeeSound "HEHEEENH"` and `ActiveSound "HEHEEENH"`** are declared
  explicitly on the Common actor (`CHP01/01_KX.txt:7-8`). `RSZM:247-250`
  handles case 13 with only `PainSound`/`DeathSound`; `SeeSound` and
  `ActiveSound` fall through to `grunt/sight` / `grunt/active` at
  `RSZM:211-212`. Player X should laugh when it sees you.
* **The taunt has no sound.** CHP plays `A_Playsound("HEHEEENH",0)` on
  **eleven** of the taunt's frames — `CHP01/01_KX.txt:48,50,52,54,56,58,60,
  62,63,64,65`. `RSZM:1111-1131` reproduces the frames and tic counts exactly
  and plays nothing. The taunt is the one moment the fight stops; in our build
  it stops in silence.
* `A_PlaySound("*xdeath",0,255,0,0)` (`CHP01/01_KX.txt:180`) uses channel 0 =
  `CHAN_AUTO`; `RSZM:1255` uses `CHAN_VOICE`. (T11's equivalent at `RSZM:931`
  is correct.)
* `EXBOSS` quake missing (§1.1).
* `HitObituary` (`CHP01/01_KX.txt:12`) not ported.
* `Death.Ice` (`CHP01/01_KX.txt:163`) missing.
* Everything else is frame-exact, including the reload→barrage/BFG commit
  (`CHP01/01_KX.txt:85-86` ↔ `RSZM:1153-1154`), both barrage strafe branches,
  the widening plasma burst, and the `A_CheckFlag("CORPSE",…)` taunt hooks.
* **TEX-W does not exist in CHP** — `CHP01/01_WX.txt` is two bytes. Our file
  correctly stops at TEX (`RSZM:130`). Nothing missing.

---

## COUNTS

* **ACS scripts invoked by family 01: 4.** REAL BEHAVIOUR: **1**, and only in
  part (`EXBOSS`'s `Radius_quake`). 2 announcers COSMETIC. 1 CVar reader whose
  branch gates a real mechanic.
* **ACS scripts reachable only via the deferred spawn-colour axis: 4**
  (`CH_IcyScript`, `CH_IcyScript2`, `CH_AbyssyEffectScript`,
  `CH_AbyssyEffectScript2` — all REAL BEHAVIOUR, none owed to T00-TEX).
* **Inventory tokens audited: 10. ACS wrappers among them: 0.**
* **Gaps: 53**, counted as discrete fixable items rather than as headings —
  26 cross-cutting (G-1's 16 flattened rolls; G-2; G-3; G-4; G-5's 7 property
  groups; plus §1.3, the skeleton economy) and 27 tier-specific
  (T00 2, T01 1, T03 1, T06 2, T07 2, T08 1, T09 1, T11 2, T12 10, TEX 5).
  G-6 is not counted — it is a clarification, not a defect.

## THE THREE MOST SERIOUS

1. **The Undertaker's skeleton economy is entirely absent** (§1.3) —
   `CHP01/01_W.txt:18`, `:6608`, `:7126`, `:8951`, `:3027-3029`, `:24-26`. Every
   monster death on the map, plus most of T12's own gunfire, should be raising
   skeletons that heal it 12-128 and climb its power ladder. Our substitute
   (`RSZM:170-204`, driven by damage taken) is a different mechanic wearing the
   same variable names.
2. **Sixteen damage rolls flattened to constants** (G-1), by stated policy at
   `RSHP:25`, `RSHP:210`, `RSHP:663-665` — the exact defect CLAUDE.md names,
   institutionalised as house style. Worst single case: `Gas11_C`'s
   `A_Explode(random(1,8),32)` (`CHP01/01_G.txt:1418`) became
   `A_Explode(24, 48, …)` (`RSHP:33`).
3. **T12's buff ladder escalates to the wrong numbers** (§2.2 T12) — CHP's
   absolute `Setspeed(16/21/28)` and `SetScale(1.1/1.25/1.45)`
   (`CHP01/01_W.txt:124,134,145,125,135,147`) became cumulative ×1.3/×1.25/×1.2
   and ×1.08/×1.10/×1.12 (`RSZM:181,190,200,183,191,201`), leaving the final
   form ~44% slower than CHP's. Honourable mention, and nearly as bad:
   **T07's fire trail carries no `A_Explode` at all** —
   `E:\New folder\ART SOURCE\CHP\DECORATE\14\14_F.txt:2002` vs
   `E:\RS_Main\zscript\monsters\monsterfx\RS_archvile_projectiles.zs:116`.
