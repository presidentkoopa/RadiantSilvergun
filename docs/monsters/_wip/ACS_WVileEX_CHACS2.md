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

# ACS DECODE — `WVileEX.acs` + `CHACS2.acs` + the function libraries

> **RS_MonsterAim.zs NO LONGER EXISTS.** It was deleted from the project on
> 2026-08-05 (commit 5df0c013, the sweep that removed the import-era monster
> files). Every reference below to `RS_MonsterAim.GetLeadAngle`,
> `PredictInterceptPoint`, or `zscript/systems/RS_MonsterAim.zs:<line>` points
> at a file that is not on disk. It is recoverable from git history if the
> predictive-lead maths is ever wanted again -- but do NOT build against it as
> though it were live. Noted 2026-08-07.



Source read 2026-08-04 from `E:\New folder\ART SOURCE\CHP\source\`.
Documentation only. Nothing in `zscript/` was written or edited.

Every claim below carries `FILE:LINE`. Line numbers are 1-based and refer to
the files as they sit on disk today.

**Reading rule this document obeys:** an empty DECORATE wrapper is not
evidence of an empty mechanic. Every script named here was opened. Where a
script does nothing, that is stated as a finding with the body quoted, not
inferred from the name.

---

## 0. HEADLINE

| | |
|---|---|
| Gameplay scripts documented | **79** (49 in WVileEX.acs, 30 in CHACS2.acs) |
| DEAD — no caller anywhere in `ART SOURCE` | **3** (`WVileEXArmorSteal_E`, `WVileEXTimer_E`, `WVileEXTimer2_E`) |
| Library functions documented | **ProjInt_Brute** + 7 in mathFuncs2 + ~90 in commonFuncs2 |
| Library functions that need **no port at all** | **all of commonFuncs2 except `abs`, and all of mathFuncs2** — see §5.4 |
| Library functions already replaced in this project | `ProjInt_Brute` → `RS_MonsterAim.GetLeadAngle` / `PredictInterceptPoint` (`zscript/systems/RS_MonsterAim.zs:34,87`) |

**The single biggest correction in this document:** the `_C / _G / _B / _P …`
suffix on the WVileEX scripts is **NOT the tier axis**. It is CHP's
**spawn-colour sub-variant axis**, and all 16 copies belong to **one tier** —
family 14 (Archvile), code `WX`, file `CHP/DECORATE/14/14_WX.txt`. Per rs_21
§1 this project ports the `Common*` actor, so the copy that matters to RS is
the **`_C` copy** and only that one. The other 14 live copies are the
recolour axis and are pure data (§2.5). This is the opposite of the
assumption the inventory in rs_19 made when it wrote "~120 lines x 15 tier
copies."

---

## 1. THE WVileEX PHASE ENGINE — the three-sentence answer

> **The White Archvile EX ("Master of Time") arms a one-shot doomsday clock
> the first time it is hurt past 60.1% of its health and a 6.25% roll lands;
> the clock's length is exactly `Health x 3 / 208` seconds (300 s for the
> `Common` variant at 20 800 HP), and while it runs the only thing that
> happens is escalating screen-shake, a looping unattenuated tick and a HUD
> countdown — nothing is buffed, nothing is nerfed, no property changes.**
>
> **The clock's five "phases" are cosmetic dread only: quake intensity climbs
> 1 → 1 → 2 → 3 → 5 → 9 across five fixed proportional segments (10, 10, 5, 3
> and 1 intervals, then a hard 10 x 35-tic final countdown), each interval
> scaled so the whole thing always divides into the tier's total.**
>
> **What is load-bearing is the expiry: at t = 0 the boss is set
> `APROP_INVULNERABLE = TRUE` — permanently, nothing in CHP ever clears it —
> and handed the `TIMESUPMOT` token, which drops it into a `TIMESUP` state
> that freezes world time for 60 s, pins the player's speed to 0, warps onto
> the player and machine-guns `TimeShockMOT_C` at 2-tic intervals until the
> player is a corpse; so the engine is a hard DPS check worth exactly
> **41.67 damage per second**, identical across all 15 live variants, and
> failing it is unwinnable rather than merely painful.**

Phases are **one-shot per boss**: `ShouldI` (`14_WX.txt:357-360`) guards on
`user_endoftime` so the countdown is meant to arm only once — though the
latch itself is broken, see §2.6-B.

---

## 2. `WVileEX.acs` — 49 scripts

`WVileEX.acs:1-2` is the whole preamble:

```c
#library "WVileEX"
#include "zcommon.acs"
```

**No `#import`.** WVileEX.acs calls **nothing** from commonFuncs2 /
miscFuncs2 / mathFuncs2. The libraries are irrelevant to this file.

Registered for loading at `CHP/LOADACS.txt` (5 lines: `Bosses`, `CHACS2`,
`CHSett2`, `NICEICE`, `WVileEX`).

### 2.1 WHO CALLS IT — the complete caller map

Grepped across all of `E:\New folder\ART SOURCE`. **Every** call site for
every WVileEX script lives in one file: `CHP/DECORATE/14/14_WX.txt`, which is
included at `CHP/DECORATE.txt:860` (`#include "decorate/14/14_WX"`).

> `CHP/DECORATE/14WX.txt` (top level) contains a partial stale copy — 6 hits,
> `_C` only — and is **not** in the include list at `CHP/DECORATE.txt`. Ignore
> it; cite `DECORATE/14/14_WX.txt`.

Each of the 15 live spawn-colour actors makes exactly **5** calls:

| suffix | calling actor | Health | Speed | ArmorSteal | Timer | Timer2 | TimeStop | Terminate |
|---|---|---|---|---|---|---|---|---|
| `_C` | `CommonWhiteArchEX2` | 20 800 | 60 | :343 | :377 | :378 | :454 | :455 |
| `_G` | `GreenWhiteArchEX2` | 26 000 | 75 | :789 | :823 | :824 | :900 | :901 |
| `_B` | `BlueWhiteArchEX2` | 31 200 | 90 | :1235 | :1269 | :1270 | :1346 | :1347 |
| `_P` | `PurpleWhiteArchEX2` | 36 400 | 105 | :1681 | :1715 | :1716 | :1792 | :1793 |
| `_Y` | `YellowWhiteArchEX2` | 41 600 | 120 | :2127 | :2161 | :2162 | :2238 | :2239 |
| `_R` | `RedWhiteArchEX2` | 52 000 | 150 | :2573 | :2607 | :2608 | :2684 | :2685 |
| `_K` | `BlackWhiteArchEX2` | 62 400 | 180 | :3015 | :3049 | :3050 | :3121 | :3122 |
| `_W` | `WhiteWhiteArchEX2` | 83 200 | 240 | :3456 | :3490 | :3491 | :3567 | :3568 |
| `_KX` | `BlackEXWhiteArchEX2` | 156 000 | 180 | :3900 | :3934 | :3935 | :4006 | :4007 |
| `_WX` | `WhiteEXWhiteArchEX2` | 208 000 | 240 | :4343 | :4377 | :4378 | :4454 | :4455 |
| `_A` | `AbyssWhiteArchEX2` | 31 200 | 120 | :4810 | :4844 | :4845 | :4921 | :4922 |
| `_BR` | `BrownWhiteArchEX2` | 20 800 | 45 | :5277 | :5311 | :5312 | :5388 | :5389 |
| `_CY` | `CyanWhiteArchEX2` | 10 400 | 120 | :5723 | :5757 | :5758 | :5834 | :5835 |
| `_F` | `FirebluWhiteArchEX2` | 20 800 | 60 | :6252 | :6325 | :6326 | :6413 | :6414 |
| `_GY` | `GrayWhiteArchEX2` | 52 000 | 30 | :6764 | :6798 | :6799 | :6875 | :6876 |
| **`_E`** | **NOTHING** | — | — | **DEAD** | **DEAD** | **DEAD** | — | — |

Health/Speed read from the actor blocks at `14_WX.txt:1,513,959,1405,1851,
2297,2743,3180,3626,4065,4513,4980,5447,5893,6486`.

> ### DEAD — SAY IT LOUDLY
> **`WVileEXArmorSteal_E` (`WVileEX.acs:187-197`), `WVileEXTimer_E`
> (`WVileEX.acs:2009-2128`), `WVileEXTimer2_E` (`WVileEX.acs:2235-2240`) have
> ZERO callers anywhere in `E:\New folder\ART SOURCE`** — not in CHP
> DECORATE, not in CHP ZSCRIPT, not in CH. Three independent confirmations
> that this is a prepared-but-abandoned 16th spawn colour:
> 1. there is no `…WhiteArchEX2` actor with an `E` suffix (the 15 that exist
>    are listed in the table above);
> 2. the sounds it asks for **do not exist** — `CHP/SNDINFO.txt` defines
>    `WVEXTAKE/<X>` and `TIME03/<X>` for all 15 live suffixes and **no `/E`
>    pair** (`:106,109,270,273,1757,1760,…,19601,19604`), so even if something
>    called `WVileEXArmorSteal_E` it would be silent;
> 3. only the text colour got as far as being defined —
>    `CHP/TEXTCOLO.txt:194` has `ColorE`.
>
> **~130 lines. Do not port. Do not cost.**
>
> Side note from the same SNDINFO sweep, useful for the port: all 15 live
> `WVEXTAKE/<X>` aliases point at the **same lump** `WVEXTAKE`, and all 15
> `TIME03/<X>` at the same lump `TIME03`. The per-colour sound axis is
> aliasing only — there is one steal sound and one clock tick in the pack.

The `…WhiteArchEX3` subclasses (`14_WX.txt:6934-7814`) are the 500 HP **clones**
produced by `CloneofTime`, and they are **not callers**: `14_WX.txt:6973-6978`
explicitly blanks the whole engine —

```
	CloneofTime:
	ShouldI:
	ENDOFTIME:
	TIMESUP:
	TIMESUP2:
		Goto Clippy
```

— and `Choices1` (`14_WX.txt:6967-6969`) drops `StealofTime` from the pick
list, so a clone can neither arm the clock nor steal armour.

---

### 2.2 `WVileEXArmorSteal_<X>` — 16 scripts, `WVileEX.acs:5-197`

**What it does.** The victim (the vile's `target`, i.e. the player) is
flash-blinded pure white, has **all** armour taken, is given a 10-second
75%-speed-reduction powerup, and takes flat damage. It is the payload half of
the `StealofTime` attack.

**Full body — `_C`, `WVileEX.acs:5-15` (the one RS needs):**

```c
Script "WVileEXArmorSteal_C" (void)
{
	SetActivator(0,AAPTR_TARGET);
    FadeTo(255,255,255,1.0,0.0);
	AmbientSound("WVEXTAKE",255);
	GiveInventory("WVileEXSpeedNerf",1); //was going to take a percentage of ammo,but there's nothing to work with
	TakeInventory("Armor",99999999); //plus it doesn't support weapon mods.
	DamageThing(20);
	Delay(1);
    FadeTo(255,255,255,0.0,1.0);
}
```

Every other copy is byte-identical except for the fade colour, the sound
suffix, the damage number, and (twice) an extra `GiveInventory`. The two
outliers are quoted in full:

**`_A`, `WVileEX.acs:125-136`:**

```c
Script "WVileEXArmorSteal_A" (void)
{
	SetActivator(0,AAPTR_TARGET);
    FadeTo(72,96,120,1.0,0.0);
	AmbientSound("WVEXTAKE/A",255);
	GiveInventory("WVileEXSpeedNerf",1);
	GiveInventory("AbyssEffectToken",20);
	TakeInventory("Armor",99999999);
	DamageThing(20);
	Delay(1);
    FadeTo(72,96,120,0.0,1.0);
}
```

**`_CY`, `WVileEX.acs:150-161`:**

```c
Script "WVileEXArmorSteal_CY" (void)
{
	SetActivator(0,AAPTR_TARGET);
    FadeTo(144,240,240,1.0,0.0);
	AmbientSound("WVEXTAKE/CY",255);
	GiveInventory("WVileEXSpeedNerf",1);
	GiveInventory("IcyShoeToken",20);
	TakeInventory("Armor",99999999);
	DamageThing(20);
	Delay(1);
    FadeTo(144,240,240,0.0,1.0);
}
```

**Per-copy table (reconstructs every body exactly):**

| script | line | FadeTo RGB | sound | DamageThing | extra give |
|---|---|---|---|---|---|
| `_C` | 5 | 255,255,255 | `WVEXTAKE` | 20 | — |
| `_G` | 17 | 0,255,0 | `WVEXTAKE/G` | 25 | — |
| `_B` | 29 | 0,192,255 | `WVEXTAKE/B` | 30 | — |
| `_P` | 41 | 128,0,255 | `WVEXTAKE/P` | 35 | — |
| `_Y` | 53 | 255,255,0 | `WVEXTAKE/Y` | 40 | — |
| `_R` | 65 | 255,0,0 | `WVEXTAKE/R` | 50 | — |
| `_K` | 77 | 64,64,64 | `WVEXTAKE/K` | 60 | — |
| `_W` | 89 | 255,255,255 | `WVEXTAKE/W` | 80 | — |
| `_KX` | 101 | 1,1,1 | `WVEXTAKE/KX` | 150 | — |
| `_WX` | 113 | 255,255,255 | `WVEXTAKE/WX` | 200 | — |
| `_A` | 125 | 72,96,120 | `WVEXTAKE/A` | 20 | `AbyssEffectToken` x20 |
| `_BR` | 138 | 144,96,48 | `WVEXTAKE/BR` | 20 | — |
| `_CY` | 150 | 144,240,240 | `WVEXTAKE/CY` | 20 | `IcyShoeToken` x20 |
| `_F` | 163 | 255,0,0 | `WVEXTAKE/F` | 60 | — |
| `_GY` | 175 | 128,128,128 | `WVEXTAKE/GY` | 50 | — |
| `_E` | 187 | 255,128,0 | `WVEXTAKE/E` | 20 | **DEAD** |

**Exact properties changed on the player:**

| change | value | duration | source |
|---|---|---|---|
| screen fade | opaque white/RGB, alpha 1.0, **0.0 s ramp = instant blind** | held 1 tic then a 1.0 s fade-out | `:8`, `:13`, `:14` |
| `Armor` inventory | **all of it**, `TakeInventory("Armor", 99999999)` | permanent | `:11` |
| `WVileEXSpeedNerf` | `PowerSpeed`, `Speed 0.25` — 25% move speed | `Powerup.Duration -10` = **10 s** | `:10`; actor at `14_WX.txt:7856-7860` |
| direct damage | 20 (Common) … 200 (`_WX`) | instant | `:12` |
| `AbyssEffectToken` (`_A` only) | +20, capped 200 | consumed by `NICEICE.acs:67-91` → `AbyssEffect` `PowerSpeed Speed -1` | `:131`; tokens at `CHP/DECORATE.txt:79-91` |
| `IcyShoeToken` (`_CY` only) | +20, capped 200 | consumed by `NICEICE.acs:6-32` → `IcyShoes` `PowerSpeed Speed 0.4` | `:156`; tokens at `CHP/DECORATE.txt:65-77` |

**Call context** — `StealofTime`, `14_WX.txt:337-346`:

```
	StealofTime:
		LMWX A 0 A_JumpIfHealthLower(12500,1)
		Goto Choices
		LMWX A 0 A_playsound("TIME02",0,255,0,0)
		LMWX QQQQRSTU 10 bright A_VileTarget("TIMESTEALMOT_C")
		LMWX U 0 A_CheckSight("Clippy")
		LMWX U 40 bright ACS_NamedExecute("WVileEXArmorSteal_C",0,0,0,0)
		LMWX E 0 A_Jump(128,"Choices")
		LMWX E 2 A_setuservar("User_courage",user_courage-15)
		Goto Clippy
```

Gated twice: only below 60.1% health (`:338`) and only with line of sight at
the moment of firing (`:342`).

**PROPOSED ZSCRIPT SHAPE.** An **inline helper on the attack state**, not a
Powerup. The armour strip, the damage and the flash are one-shot verbs that
belong where they are fired; only the slow needs an object, and that is
already `RS_WVileEXSpeedNerf`. `zscript/monsters/RS_Archvile.zs:1995-2002`
already does 4 of the 5 effects correctly — the only missing piece for the
`_C` copy is the full-screen white flash, which wants a one-line
`A_SetBlend`/`Console`-side flash on the player rather than a new class.

---

### 2.3 `WVileEXTimer_<X>` — 16 scripts, `WVileEX.acs:199-2128`

**What it does.** Nothing mechanical at all. It is the **clock face**: a
looping unattenuated tick sound, a HUD countdown, and a ramping `Radius_quake`.
Its `damrad` argument is `0` in all 479 quake calls, so the shaking never
damages anyone. It changes **no** actor property and **no** inventory.

Its one real consequence is that it holds `CHAN_7` on the player with a
looping sound — which is why `WVileEXTimeStop` exists (§2.5).

**Full body — `_C`, `WVileEX.acs:199-318`** (this is the one RS needs; the
repeated blocks are elided with an explicit count, everything else is verbatim):

```c
Script "WVileEXTimer_C" (void)
{
	SetActivator(0,AAPTR_TARGET);
	Playsound(0,"TIME03",CHAN_7,1.0,1,0);
    SetFont("smallfont");
    SetHudSize(320,240,0);
    Hudmessagebold(s:"300 seconds left...";
    HUDMSG_FADEINOUT,0,CR_YELLOW,160.0,32.0,3.5);
	Radius_quake(1,35,0,1200,0);
	Delay(350);
	                       // :207-226 -- the {quake(1,35,0,1200,0); Delay(350);}
	                       // pair repeated for TEN intervals total
    SetHudSize(320,240,0);
	Hudmessagebold(s:"200 seconds left...";
    HUDMSG_FADEINOUT,0,CR_YELLOW,160.0,32.0,3.5);
	                       // :230-249 -- TEN more of quake(1,35,0,1200,0)+Delay(350)
    SetHudSize(320,240,0);
	Hudmessagebold(s:"100 seconds left...";
    HUDMSG_FADEINOUT,0,CR_YELLOW,160.0,32.0,3.5);
	                       // :253-262 -- FIVE of quake(2,60,0,1200,0)+Delay(350)
    SetHudSize(320,240,0);
	Hudmessagebold(s:"50 seconds left...";
    HUDMSG_FADEINOUT,0,CR_YELLOW,160.0,32.0,3.5);
	                       // :266-271 -- THREE of quake(3,100,0,1200,0)+Delay(350)
    SetHudSize(320,240,0);
	Hudmessagebold(s:"20 seconds left...";
    HUDMSG_FADEINOUT,0,CR_YELLOW,160.0,32.0,3.5);
	Radius_quake(5,200,0,1200,0);
	Delay(350);
    SetHudSize(320,240,0);
	Hudmessagebold(s:"10...";
    HUDMSG_FADEINOUT,0,CR_YELLOW,160.0,32.0,0.8,0.1,0.1);
	Radius_quake(9,350,0,1200,0);
	Delay(35);
	                       // :282-317 -- "9..." down to "1...", each
	                       // SetHudSize + Hudmessagebold + Delay(35), NO quake
}
```

**Verified sums (`awk` over the delay literals, all 16 scripts):**

| script | line | unit delay U | final long delay F | quakes | total tics | seconds |
|---|---|---|---|---|---|---|
| `_C` | 199 | 350 | 350 | 30 | 10 500 | **300** |
| `_G` | 320 | 438/437 alt. | 525 | 30 | 13 125 | 375 |
| `_B` | 441 | 525 | 700 | 30 | 15 750 | 450 |
| `_P` | 562 | 612/613 alt. | 875 | 30 | 18 375 | 525 |
| `_Y` | 683 | 700 | 1050 | 30 | 21 000 | 600 |
| `_R` | 804 | 875 | 1400 | 30 | 26 250 | 750 |
| `_K` | 925 | 1050 | 1750 | 30 | 31 500 | 900 |
| `_W` | 1046 | 1400 | 2450 | 30 | 42 000 | 1200 |
| `_KX` | 1167 | 2625 | 4900 | 30 | 78 750 | 2250 |
| `_WX` | 1288 | 3500 | 6650 | 30 | 105 000 | 3000 |
| `_A` | 1409 | 525 | 700 | 30 | 15 750 | 450 |
| `_BR` | 1530 | 350 | 350 | 30 | 10 500 | 300 |
| `_CY` | 1651 | 175 | *(phase absent)* | **29** | 5 250 | 150 |
| `_F` | 1767 | 350 | 350 | 30 | 10 500 | 300 |
| `_GY` | 1888 | 875 | 1400 | 30 | 26 250 | 750 |
| `_E` | 2009 | 350 | 350 | 30 | 10 500 | 300 — **DEAD** |

**Body reconstruction rule** (holds for all 16, verified against `_C`
`:199-318`, `_W` `:1046-1165` and `_CY` `:1651-1765` read in full):

```
SetActivator(0,AAPTR_TARGET)
Playsound(0,"TIME03[/X]",CHAN_7, 1.0, looping=1, attenuation=0)   // GLOBAL, LOOPS
SetFont("smallfont")
phase 1: msg M1   then 10 x { Radius_quake(1,35,0,1200,0); Delay(U); }
phase 2: msg M2   then 10 x { Radius_quake(1,35,0,1200,0); Delay(U); }
phase 3: msg M3   then  5 x { Radius_quake(2,60,0,1200,0);  Delay(U); }
phase 4: msg M4   then  3 x { Radius_quake(3,100,0,1200,0); Delay(U); }
phase 5: msg M5   then  1 x { Radius_quake(5,200,0,1200,0); Delay(F); }   // _CY OMITS THIS PHASE
final:   msg "10..." + Radius_quake(9,350,0,1200,0) + Delay(35),
         then "9..." … "1...", each SetHudSize + Hudmessagebold + Delay(35)
```

Only `_C` uses `HUDMSG_FADEINOUT,0,CR_YELLOW` (15 occurrences, `WVileEX.acs`
grep); every other copy uses `HUDMSG_FADEINOUT|HUDMSG_COLORSTRING,0,"Color<X>"`.
All messages are at `160.0,32.0` with holdtime `3.5` for M1-M5 and
`0.8,0.1,0.1` for the final ten — except `_CY`'s `"10..."` which is `3.5`
(`WVileEX.acs:1726`), a copy-paste slip.

Quake argument census across the whole file (all `damrad = 0`, all
`tremrad = 1200`, all `tid = 0`):
`Radius_quake(1,35,…)` x320, `(2,60,…)` x80, `(3,100,…)` x48, `(5,200,…)` x15,
`(9,350,…)` x16 = 479 = 16 x 30 − 1 (the `_CY` omission).

**Phase headline texts:**

| script | M1 | M2 | M3 | M4 | M5 |
|---|---|---|---|---|---|
| `_C` | 300 | 200 | 100 | 50 | 20 |
| `_G` | 375 | 250 | 125 | 62.5 | 25 |
| `_B` | 450 | 300 | 150 | 75 | 30 |
| `_P` | 525 | 350 | 175 | 87.5 | 35 |
| `_Y` | 600 | 400 | 200 | 100 | 40 |
| `_R` | 750 | 500 | 250 | 125 | 50 |
| `_K` | 900 | 600 | 300 | 150 | 60 |
| `_W` | 1200 | 800 | 400 | 200 | 80 |
| `_KX` | 2250 | 1500 | 750 | 375 | 150 |
| `_WX` | 3000 | 2000 | 1000 | 500 | 200 |
| `_A` | 450 | 300 | 150 | 75 | 30 |
| `_BR` | 300 | 200 | 100 | 50 | 20 |
| `_CY` | 150 | 100 | 50 | 25 | *(none)* |
| `_F` | 300 | 200 | 100 | 50 | 20 |
| `_GY` | 750 | 500 | 250 | 125 | 50 |
| `_E` | 300 | 200 | 100 | 50 | 20 |

Note `Radius_quake(…, tid=0)` fires on the **activator**, and the activator
was switched to the player at `:201`. **The shake is centred on the player,
not on the boss** — it does not fall off with distance from the vile, which is
the point: the world is ending, not the room.

**PROPOSED ZSCRIPT SHAPE.** A **Thinker** owned by the boss (or a countdown
field ticked in the boss's own `Tick()`), driving a HUD element and
`A_QuakeEx`. It must NOT be a state-machine branch — the boss keeps fighting
through the entire countdown, so the clock cannot occupy the state pointer.
`RS_Archvile.zs:2047` already models this correctly as
`rsTimesUpTic = level.time + 10500`; the missing half is the presentation
(tick sound, HUD, quake ramp), which is a Thinker or an
`OverlayDrawer`-style HUD hook.

---

### 2.4 `WVileEXTimer2_<X>` — 16 scripts, `WVileEX.acs:2130-2240`

**THE ONLY SCRIPT IN THIS FILE THAT CHANGES AN ACTOR PROPERTY.**

**Full body — `_C`, `WVileEX.acs:2130-2135`:**

```c
script "WVileEXTimer2_C" (void)
{
	Delay(10500);
	SetActorProperty(0,APROP_INVULNERABLE,TRUE);
	GiveInventory("TIMESUPMOT",1);
}
```

Every one of the 16 is exactly this with a different `Delay`. Note there is
**no `SetActivator`**: the activator stays the vile that called it, so the
invulnerability and the token land on the boss.

| script | line | `Delay` | seconds | matches Timer_ total |
|---|---|---|---|---|
| `_C` | 2130 | 10500 | 300 | yes |
| `_G` | 2137 | 13125 | 375 | yes |
| `_B` | 2144 | 15750 | 450 | yes |
| `_P` | 2151 | 18375 | 525 | yes |
| `_Y` | 2158 | 21000 | 600 | yes |
| `_R` | 2165 | 26250 | 750 | yes |
| `_K` | 2172 | 31500 | 900 | yes |
| `_W` | 2179 | 42000 | 1200 | yes |
| `_KX` | 2186 | 78750 | 2250 | yes |
| `_WX` | 2193 | 105000 | 3000 | yes |
| `_A` | 2200 | 15750 | 450 | yes |
| `_BR` | 2207 | 10500 | 300 | yes |
| `_CY` | 2214 | 5250 | 150 | yes |
| `_F` | 2221 | 10500 | 300 | yes |
| `_GY` | 2228 | 26250 | 750 | yes |
| `_E` | 2235 | 10500 | 300 | **DEAD** |

**Properties changed:**

| target | change | value | duration |
|---|---|---|---|
| the vile itself | `APROP_INVULNERABLE` | `TRUE` | **permanent — nothing in CH or CHP ever sets it FALSE.** Grepped: `APROP_INVULNERABLE` appears 16 times in `WVileEX.acs` (all `TRUE`) and once read-only at `commonFuncs2.acs:916`. There is no `invulnerable` token in `14_WX.txt` at all. |
| the vile itself | `TIMESUPMOT` | +1 (`Inventory.MaxAmount 1`, `14_WX.txt:7820-7823`) | until `Idle` takes it back at `14_WX.txt:95` |

**THE ARITHMETIC THAT MAKES THIS A DESIGNED MECHANIC AND NOT A NUMBER SOUP.**
Cross-referencing the timer against the health at which it arms
(`A_JumpIfHealthLower`, one per variant):

| variant | Health | arm threshold | ratio | timer (s) | **required DPS** |
|---|---|---|---|---|---|
| `Common` | 20 800 | 12 500 (`14_WX.txt:198`) | 60.10% | 300 | **41.67** |
| `Green` | 26 000 | 15 625 (`:644`) | 60.10% | 375 | **41.67** |
| `Blue` | 31 200 | 18 750 (`:1090`) | 60.10% | 450 | **41.67** |
| `Purple` | 36 400 | 21 875 (`:1536`) | 60.10% | 525 | **41.67** |
| `Yellow` | 41 600 | 25 000 (`:1982`) | 60.10% | 600 | **41.67** |
| `Red` | 52 000 | 31 250 (`:2428`) | 60.10% | 750 | **41.67** |
| `Black` | 62 400 | 37 500 (`:2873`) | 60.10% | 900 | **41.67** |
| `White` | 83 200 | 50 000 (`:3311`) | 60.10% | 1200 | **41.67** |
| `BlackEX` | 156 000 | 93 750 (`:3758`) | 60.10% | 2250 | **41.67** |
| `WhiteEX` | 208 000 | 125 000 (`:4198`) | 60.10% | 3000 | **41.67** |
| `Abyss` | 31 200 | 18 750 (`:4665`) | 60.10% | 450 | **41.67** |
| `Brown` | 20 800 | 12 500 (`:5132`) | 60.10% | 300 | **41.67** |
| `Cyan` | 10 400 | 6 250 (`:5578`) | 60.10% | 150 | **41.67** |
| `Fireblu` | 20 800 | 12 500 (`:6035`) | 60.10% | 300 | **41.67** |
| `Gray` | 52 000 | 31 250 (`:6619`) | 60.10% | 750 | **41.67** |

Timer seconds = `Health x 3 / 208` exactly. Arm threshold = `Health x 0.60096`
exactly. Required sustained damage = `41.666…` in **every** variant. **This is
the mechanic.** Any port that scales the timer by tier rather than deriving it
from health will break the one invariant CHP was careful about.

**PROPOSED ZSCRIPT SHAPE.** A **deadline field plus a state-machine branch** —
`rsTimesUpTic` stamped at arm time, tested each `Tick()`, and on expiry set
`bINVULNERABLE` and jump to `TIMESUP`. Already the shape at
`RS_Archvile.zs:2047` and `:2185`. The only correction needed there is that
the deadline should be computed from `SpawnHealth() * 105 / 208` rather than
hard-coded 10500, so the recolour axis stays free (rs_21 §1).

---

### 2.5 `WVileEXTimeStop` — 1 script, `WVileEX.acs:2242-2246`

**Full body — the entire script:**

```c
Script "WVileEXTimeStop" (void)
{
	SetActivator(0,AAPTR_TARGET);
	StopSound(0,CHAN_7);
}
```

**What it does.** Silences the looping tick on the player. **That is all.** It
changes no property, gives and takes no inventory, and does not stop any
script.

**Who calls it:** all 15 live variants, from `Death` — `14_WX.txt:454, 900,
1346, 1792, 2238, 2684, 3121, 3567, 4006, 4454, 4921, 5388, 5834, 6413, 6875`.
There is exactly ONE script name in the whole engine, unsuffixed, so all 15
variants share it. Context, `14_WX.txt:454-455`:

```
		TNT1 A 0 ACS_NamedExecute("WVileEXTimeStop",0,0,0,0)
		TNT1 A 0 ACS_NamedTerminate("WVileEXTimer_C",0)
```

**PROPOSED ZSCRIPT SHAPE.** **Delete it.** In ZScript the tick sound is a
channel on the boss or on the countdown Thinker, and it dies with the owner.
There is nothing to port; record it as read-and-dismissed with the body above
as evidence.

---

### 2.6 BUGS AND TRAPS IN THE ENGINE — quoted, so the port does not inherit them

**A. `Timer2` is never terminated.** `Death` terminates only the countdown:

```
	TNT1 A 0 ACS_NamedTerminate("WVileEXTimer_C",0)      // 14_WX.txt:455
```

`WVileEXTimer2_C` keeps sleeping through its `Delay` and, when it wakes, still
runs `SetActorProperty(0,APROP_INVULNERABLE,TRUE)` and
`GiveInventory("TIMESUPMOT",1)` on a corpse (`WVileEX.acs:2133-2134`).
Harmless on a dead actor, but it means the *name* stays occupied — see B.

**B. `ACS_NamedExecute`, not `…Always`.** All five call sites use
`ACS_NamedExecute` (`14_WX.txt:343,377,378,454`), which permits only one
instance of a named script at a time. Consequences, all real:
1. Two `CommonWhiteArchEX2` alive at once → the second one's countdown is a
   silent no-op, and it becomes invulnerable on the *first* one's schedule
   (or never).
2. Because of (A), a fresh boss cannot arm the clock at all until the previous
   boss's orphaned `Timer2` has finished sleeping — which for `_WX` is 3000
   seconds.
3. Killing boss #1 terminates boss #2's countdown HUD.

**C. The one-shot latch is broken.** `14_WX.txt:379`:

```
		LMWX A 0 a_setuservar("user_hoho",user_endoftime=1)
```

The intent is plainly `user_endoftime = 1` — the latch `ShouldI` reads at
`14_WX.txt:358` (`A_JumpIf(user_endoftime>0,"Missile2")`). What is written
assigns into **`user_hoho`**, which is the *EyeofTime2* latch
(`14_WX.txt:207,325,334`). Either reading is wrong: if DECORATE parses the
inner `=` as an assignment the boss also gets a free `EyeofTime2` charge; if
it parses as a comparison the latch is never set and the countdown can be
re-armed on every subsequent `ShouldI` roll. **Do not reproduce this line.**
`RS_Archvile.zs:2020-2023` already models `ShouldI` with a working latch.

**D. Nothing clears `APROP_INVULNERABLE`.** §2.4. If a port ever wants the
boss killable after a failed check, that is a deliberate design change, not a
port fidelity question — CHP's answer is "you lost."

**E. `Idle` clears the latch but not the invulnerability.** `14_WX.txt:92-97`:

```
	Idle:
		LMWX A 0 A_changeflag(NOPAIN,FALSE)
		LMWX A 0 A_TakeInventory("TimeSlowMOT2",1)
		LMWX A 0 A_TakeInventory("TIMESUPMOT",1)
		LMWX E 10 A_Look
		loop
```

`TIMESUP2` returns here when the player is a corpse (`:415`), so after a kill
the boss stops the execution loop, releases the time freeze — and remains
permanently unkillable.

---

### 2.7 SUPPORT ACTORS THE ENGINE DEPENDS ON — exact values

All from `CHP/DECORATE/14/14_WX.txt:7815-7860`. Negative `Powerup.Duration`
is **seconds** in ZDoom.

```
Actor MOTFreezeToken : Inventory      { Inventory.MaxAmount 99999 }        // :7815
Actor TIMESUPMOT : Inventory          { Inventory.MaxAmount 1 }            // :7820
Actor TimeSlowMOT : PowerupGiver      { Powerup.Type "TimeFreezer"         // :7825
                                        Powerup.Duration -2                //  = 2 s
                                        +INVENTORY.ADDITIVETIME +AUTOACTIVATE }
Actor TimeSlowMOT2 : TimeSlowMOT      { Powerup.Duration -60 }             // :7839  = 60 s
Actor TimeSlowMOT3 : PowerSpeed       { Speed 0  Powerup.Duration -10 }    // :7844  = 10 s
Actor WVileResist : PowerProtection   { DamageFactor 0.5                   // :7850
                                        Powerup.Duration -8 }              //  = 8 s
Actor WVileEXSpeedNerf : PowerSpeed   { Speed 0.25 Powerup.Duration -10 }  // :7856  = 10 s
```

**`TIMESUP` / `TIMESUP2` — the expiry payload, `14_WX.txt:383-416`** (the
half of the engine that lives in DECORATE, quoted because the ACS is
meaningless without it):

```
	TIMESUP:
		LMWX A 0 A_GiveInventory("TimeSlowMOT2",1)
		LMWX A 0 A_GiveInventory("TimeSlowMOT3",1,AAPTR_TARGET)
		LMWX A 0 A_ScaleVelocity(0,AAPTR_TARGET)
		LMWX A 0 A_playsound("Forgotten/Attack",0,255,0,0)
		LMWX A 0 A_changeflag(NOPAIN,TRUE)
		...                                              // fade out, :389-395
		LMWX A 10 bright A_Warp(AAPTR_TARGET,-80,0,0,random(0,360),WARPF_NOCHECKPOSITION)
		...                                              // fade in, :397-410
	TIMESUP2:
		LMWX AAAA 2 bright A_CustomMissile("TimeShockMOT_C",42,0,random(-10,10))
		LMWX A 0 A_GiveInventory("TimeSlowMOT2",1)
		LMWX A 0 A_GiveInventory("TimeSlowMOT3",1,AAPTR_TARGET)
		LMWX A 0 A_CheckFlag("CORPSE","Idle",AAPTR_TARGET)
		Loop
```

So on expiry: world time freezes for 60 s (refreshed every loop), the player's
`PowerSpeed` is pinned to `Speed 0` for 10 s (refreshed every loop), the
player's momentum is zeroed, the boss teleports 80 units behind the player and
fires four `TimeShockMOT_C` every 2 tics forever. The boss is
`+NOTIMEFREEZE` (`14_WX.txt:32`), so it alone moves.

`WVileResist` (8 s at half damage taken) is handed to the boss on entry to
`ScreamofTime` (`14_WX.txt:238`) and to `ENDOFTIME` (`:369`) — it is the
"don't interrupt the ritual" armour, not part of the timer.

---

### 2.8 WHAT STARTS THE ENGINE — full trigger chain, `14_WX.txt`

```
	Missile:
		LMWX A 0 A_JumpIfHealthLower(12500,"ShouldI")            // :198
	Missile2:
		...
		LMWX A 0 A_JumpIfInventory("TIMESUPMOT",1,"TIMESUP")     // :208
	...
	ShouldI:
		LMWX A 0 A_JumpIf(user_endoftime>0,"Missile2")           // :358
		LMWX A 0 A_Jump(16,"ENDOFTIME")                          // :359  16/256 = 6.25%
		Goto Missile2                                            // :360
	ENDOFTIME:
		...
		LMWX A 0 A_changeflag(NOPAIN,TRUE)                       // :368
		LMWX A 0 A_GiveInventory("WVileResist",1)                // :369
		LMWX A 0 A_playsound("WVEXSIGT",0,255,0,0)               // :370
		LMWX AA 10 bright A_VileTarget("TIMESTEALMOT_C")         // :372
		LMWX A 0 radius_quake(180,180,0,900,0)                   // :373
		LMWX AAA 10 bright A_VileTarget("TIMESTEALMOT_C")        // :374
		LMWX A 0 A_playsound("Wvile/scream",0,255,0,0)           // :375
		LMWX QRSTUQRSTUQRSTU 4 bright A_VileTarget("TIMESTEALMOT_C")   // :376
		LMWX U 0 ACS_NamedExecute("WVileEXTimer_C",0,0,0,0)      // :377
		LMWX U 40 bright ACS_NamedExecute("WVileEXTimer2_C",0,0,0,0)   // :378
		LMWX A 0 a_setuservar("user_hoho",user_endoftime=1)      // :379  BUG, see 2.6-C
		LMWX E 2 A_setuservar("User_courage",user_courage-150)   // :380
		LMWX A 0 A_changeflag(NOPAIN,FALSE)                      // :381
		Goto CloneofTime                                         // :382
```

Note `radius_quake(180,180,0,900,0)` at `:373` — intensity 180, 180 tics. That
is the only *damaging-scale* shake in the sequence and it is in DECORATE, not
in the ACS.

**Ends:** by the boss dying (`Death`, `:447` → `TimeStop` + `Terminate`), or by
the clock expiring (`Timer2` → invulnerable + `TIMESUPMOT` → `TIMESUP`).
There is no third exit and no way to disarm it.

---

## 3. `CHACS2.acs` — 30 scripts, 30 gameplay, zero filler

```c
#library "CHACS2"                 // CHACS2.acs:1
#include "zcommon.acs"            // :2
#import "miscFuncs2.acs"          // :3
```

Every one of the 30 scripts is a thin, tier-parameterised wrapper around
**one** library call, `ProjInt_Brute` (§5.1) — the lead-fire / intercept
solver. **This is the file rs_19 called "the densest gameplay file here," and
that is right, but the density is 30 sets of constants around a single
mechanic, not 30 mechanics.**

`ProjInt_Brute`'s parameter order (`miscFuncs2.acs:6`), needed to read any of
these lines:

```
ProjInt_Brute(stid, ttid, spd, ptid, xoff, yoff, zoff, ptype,
              axoff, ayoff, azoff, angoff, rand, input_t)
```

### 3.1 `CybMissile_<X>` — 15 scripts, `CHACS2.acs:5-127`

**Full body — `_C`, `CHACS2.acs:5-11`:**

```c
script "CybMissile_C" (int rand)
{
  int speed = 20.0;
  if(!rand){ ProjInt_Brute(0,0,speed,0,-25.0,1.0,60.0,"Rocket_C",0,0,0,0,0,0); }
  else{ ProjInt_Brute(0,0,speed,0,-25.0,1.0,60.0,"Rocket_C",0,0,0,0,1,0); }
  SetResultValue(0);
}
```

**What it does.** Fires one lead-aimed rocket from a muzzle 25 units to the
Cyberdemon's **right**, 1 unit forward and 60 units up, aimed at where the
target will be when a projectile of `speed` arrives, targeting a point 36
units above the target's feet (`miscFuncs2.acs:55`). Changes no property and
no inventory — it is pure aim-and-spawn. `SetResultValue(0)` means the
DECORATE `ACS_NamedExecuteWithResult` always sees 0.

Every copy is byte-identical except `speed` and the projectile class. `_F` is
the one structural outlier and is quoted in full below.

| script | line | `speed` | projectile | shape |
|---|---|---|---|---|
| `_C` | 5 | 20.0 | `Rocket_C` | single |
| `_G` | 13 | 22.5 | `Rocket_G` | single |
| `_B` | 21 | 25.0 | `Rocket_B` | single |
| `_P` | 29 | 30.0 | `Rocket_P` | single |
| `_Y` | 37 | 35.0 | `Rocket_Y` | single |
| `_R` | 45 | 40.0 | `Rocket_R` | single |
| `_K` | 53 | 60.0 | `Rocket_K` | single |
| `_W` | 61 | 90.0 | `Rocket_W` | single |
| `_KX` | 69 | 60.0 | `Rocket_KX` | single |
| `_WX` | 77 | 90.0 | `Rocket_WX` | single |
| `_A` | 85 | 60.0 | `Rocket_A` | single |
| `_BR` | 93 | 15.0 | `Rocket_BR` | single |
| `_CY` | 101 | 40.0 | `Rocket_CY` | single |
| `_F` | 109 | 20.0 | `Rocket_F` | **TRIPLE, ±7.69° spread** |
| `_GY` | 121 | 10.0 | `Rocket_GY` | single |

**Full body — `_F`, `CHACS2.acs:109-119`:**

```c
script "CybMissile_F" (int rand)
{
  int speed = 20.0;
  if(!rand){ ProjInt_Brute(0,0,speed,0,-25.0,1.0,60.0,"Rocket_F",-1400,0,0,-1400,0,0);
			 ProjInt_Brute(0,0,speed,0,-25.0,1.0,60.0,"Rocket_F",1400,0,0,1400,0,0);
			 ProjInt_Brute(0,0,speed,0,-25.0,1.0,60.0,"Rocket_F",0,0,0,0,0,0); }
  else{ ProjInt_Brute(0,0,speed,0,-25.0,1.0,60.0,"Rocket_F",-1400,0,0,-1400,1,0);
		ProjInt_Brute(0,0,speed,0,-25.0,1.0,60.0,"Rocket_F",1400,0,0,1400,1,0);
		ProjInt_Brute(0,0,speed,0,-25.0,1.0,60.0,"Rocket_F",0,0,0,0,1,0); }
  SetResultValue(0);
}
```

`angoff = ±1400` in ACS fixed point = `1400/65536 x 360° = ±7.690°`.
`axoff = ±1400` in the same raw units is `±0.021 map units` — i.e. **nothing**,
almost certainly the angle value pasted into the wrong slot. See §5.1-C for
the angle-doubling bug that makes the *actual* travel spread `±15.38°`.

**WHO CALLS IT.** Exactly **one** call site per script, all in
`CHP/DECORATE/17/17_C.txt` (Cyberdemon, family 17, tier code `C` = T00 file
holding all 15 spawn colours). The `_C` copy, `17_C.txt:29-39`:

```
	Missile:
		CYBR E 6 A_FaceTarget
		CYBR F 12 Bright A_Custommissile("Rocket_C",42,-9,random(-1,1))
		CYBR E 12 A_FaceTarget
		CYBR F 12 Bright A_Custommissile("Rocket_C",42,-9,random(-2,2))
		CYBR E 12 A_FaceTarget
		CYBR E 0 A_JumpIf(CallACS("CH_Intercept") == true,"Miss2")
		CYBR F 12 Bright ACS_NamedExecuteWithResult("CybMissile_C",1)
		Goto See
	Miss2:
		CYBR F 12 Bright A_Custommissile("Rocket_C",42,-9,random(-4,4))
```

Caller actor `CommonCommonCybie` (`17_C.txt:36`). The other 14 suffixes are
the same line inside the same file at `:99, 162, 225, 288, 351, 414, 477, 541,
605, 674, 738, 806, 877, 943`.

**Note the inverted jump.** `A_JumpIf(CallACS("CH_Intercept") == true, "Miss2")`
sends the monster to the **dumb-fire** branch when the CVar is TRUE. And
`CH_Intercept` defaults to **false** (`CH/CVARINFO.txt:2`,
`server bool CH_Intercept = false;`; the script that reads it is
`CHP/source/CHSett2.acs:232-234`, body
`SetResultValue(GetCVar("CH_Intercept"));`). So **on default settings the
Cyberdemon's third shot IS the lead-fire**, and turning the option on disables
it. Either the option is inverted or its name means "use simple intercept."
Whichever, a port must not treat the lead shot as opt-in.

### 3.2 `BaronMissile_<X>` — 15 scripts, `CHACS2.acs:129-281`

**Full body — `_C`, `CHACS2.acs:129-137`:**

```c
script "BaronMissile_C" (int rand)
{
  int speed;
  if(GetCVar("sv_fastmonsters")){ speed = 20.0; }
  else{ speed = 15.0; }
  if(rand == 1){ ProjInt_Brute(0,0,speed,0,0,1.0,32.0,"BaronBall_C",0,0,0,0,0,0); }
  else{ ProjInt_Brute(0,0,speed,0,0,1.0,32.0,"BaronBall_C",0,0,0,0,1,0); }
  SetResultValue(0);
}
```

**What it does.** Same solver, different muzzle (**no lateral offset**, 1 unit
forward, 32 up) and a **`sv_fastmonsters` speed switch** the Cyberdemon family
does not have: the projectile is 33% faster when fast monsters are on, which
also makes the lead angle tighter. Changes no property, no inventory.

| script | line | `speed` fast | `speed` normal | projectile | shape |
|---|---|---|---|---|---|
| `_C` | 129 | 20.0 | 15.0 | `BaronBall_C` | single |
| `_G` | 139 | 22.5 | 16.9 | `BaronBall_G` | single |
| `_B` | 149 | 25.0 | 18.8 | `BaronBall_B` | single |
| `_P` | 159 | 30.0 | 22.5 | `BaronBall_P` | single |
| `_Y` | 169 | 35.0 | 26.3 | `BaronBall_Y` | single |
| `_R` | 179 | 40.0 | 30.0 | `BaronBall_R` | single |
| `_K` | 189 | 60.0 | 45.0 | `BaronBall_K` | single |
| `_W` | 199 | 90.0 | 67.5 | `BaronBall_W` | single |
| `_KX` | 209 | 60.0 | 45.0 | `BaronBall_KX` | single |
| `_WX` | 219 | 90.0 | 67.5 | `BaronBall_WX` | single |
| `_A` | 229 | 60.0 | 45.0 | `BaronBall_A` | single |
| `_BR` | 239 | 15.0 | 11.3 | `BaronBall_BR` | single |
| `_CY` | 249 | 40.0 | 30.0 | `BaronBall_CY` | single |
| `_F` | 259 | 20.0 | 15.0 | `BaronBall_F` | **TRIPLE, ±7.69°** |
| `_GY` | 273 | 10.0 | 7.5 | `BaronBall_GY` | single |

**Full body — `_F`, `CHACS2.acs:259-271`:**

```c
script "BaronMissile_F" (int rand)
{
  int speed;
  if(GetCVar("sv_fastmonsters")){ speed = 20.0; }
  else{ speed = 15.0; }
  if(rand == 1){ ProjInt_Brute(0,0,speed,0,0,1.0,32.0,"BaronBall_F",-1400,0,0,-1400,0,0);
				 ProjInt_Brute(0,0,speed,0,0,1.0,32.0,"BaronBall_F",1400,0,0,1400,0,0);
				 ProjInt_Brute(0,0,speed,0,0,1.0,32.0,"BaronBall_F",0,0,0,0,0,0); }
  else{ ProjInt_Brute(0,0,speed,0,0,1.0,32.0,"BaronBall_F",-1400,0,0,-1400,1,0);
		ProjInt_Brute(0,0,speed,0,0,1.0,32.0,"BaronBall_F",1400,0,0,1400,1,0);
		ProjInt_Brute(0,0,speed,0,0,1.0,32.0,"BaronBall_F",0,0,0,0,1,0); }
  SetResultValue(0);
}
```

**WHO CALLS IT — five call sites per script, across FOUR families.** This is
the finding rs_19 missed: `BaronMissile` is not the Baron's script. It is
shared, and the biggest user is the **Lost Soul**.

| caller file | actor (`_C` copy) | line | tier | gated by `CH_Intercept`? | `rand` arg |
|---|---|---|---|---|---|
| `CHP/DECORATE/05/05_W.txt` | `CommonWhiteLSoul2` | 102 | 05 LostSoul T12 | **NO** | omitted (=0) |
| `CHP/DECORATE/05/05_WX.txt` | `CommonWhiteLSoulEX2` (HK form) | 160 | 05 LostSoul TEX | **NO** | omitted (=0) |
| `CHP/DECORATE/05/05_WX.txt` | `CommonWhiteLSoulEX2` (Baron form) | 188 | 05 LostSoul TEX | **NO** | omitted (=0) |
| `CHP/DECORATE/11/11_G.txt` | `CommonGreenHK` | 29 | 11 HellKnight T01 | yes (`:28`) | omitted (=0) |
| `CHP/DECORATE/15/15_C.txt` | `CommonCommonBaron` | 30 | 15 Baron T00 | yes (`:29`) | **1** |

The other 14 suffixes sit at the same offsets in the same files (verified by
count: 5 call sites for every one of the 15 suffixes).

`05_W.txt:102` in context (`:100-104`):

```
		BOSS G 7 A_CustomComboAttack("BaronBall_C",32,10 * random(1,8),"baron/melee")
		BOSS PQ 5 A_FaceTarget
		BOSS R 5 ACS_NamedExecuteWithResult("BaronMissile_C")
		BOSS EF 5 A_FaceTarget
		BOSS G 5 A_Custommissile("Spspit2_C",32,5,random(-1,1))
```

**The `rand` argument is inverted between the two families.** `CybMissile`
tests `if(!rand)` (`:8`), `BaronMissile` tests `if(rand == 1)` (`:134`). With
the actual call arguments above, **every live call site in CHP ends up on the
`ProjInt_Brute rand = 1` branch** — the Cyberdemon because it passes 1 into
`!rand`, the Barons/HK/Lost Souls because they pass nothing into `== 1`. The
only caller that would take the `rand = 0` branch is `15_C.txt:30`
(`…("BaronMissile_C",1)`). So in practice the speed-normalised solve (§5.1) is
what CHP ships. (`ProjInt_Brute`'s `rand` does **not** randomise anything —
§5.1-B.)

### 3.3 PROPOSED ZSCRIPT SHAPE for all 30

**One inline helper plus a data table.** There is no per-script behaviour to
model: the 30 scripts are (`projectile`, `speed`, `muzzle offset`, `fan
count`) and nothing else. `RS_MonsterAim.GetLeadAngle` already computes the
angle (`zscript/systems/RS_MonsterAim.zs:87`), and
`RS_MonsterMaster.zs:346` already calls it. What is left is exactly the
rs_21 §5 socket work: one `RS_AttackProfile` entry per tier carrying the four
numbers, fired from the state through the slot. **Do not create 30 classes.**

The existing port comments at `RS_Baron.zs:247-248`, `RS_Cyberdemon.zs:264`,
`RS_HellKnight.zs:254` and `RS_LostSoul.zs:67,926,1195,1224` already name
these correctly; `RS_LostSoul.zs:926` and `:1224` record it as **RESTORED**.

---

## 4. WHERE THE CALLERS ARE — the "who calls what" summary

| script family | # scripts | callers | verdict |
|---|---|---|---|
| `WVileEXArmorSteal_*` | 16 | 15 x 1 call, all `14_WX.txt` | 15 live, **1 DEAD** (`_E`) |
| `WVileEXTimer_*` | 16 | 15 x 2 (execute + terminate), all `14_WX.txt` | 15 live, **1 DEAD** (`_E`) |
| `WVileEXTimer2_*` | 16 | 15 x 1 call, all `14_WX.txt` | 15 live, **1 DEAD** (`_E`) |
| `WVileEXTimeStop` | 1 | 15 call sites, all `14_WX.txt` | live, but a no-op in ZScript |
| `CybMissile_*` | 15 | 1 each, all `17_C.txt` | all live |
| `BaronMissile_*` | 15 | 5 each: `05_W`, `05_WX` x2, `11_G`, `15_C` | all live |

**79 gameplay scripts. 3 dead.**

---

## 5. THE FUNCTION LIBRARIES

### 5.0 The import graph — measured, and smaller than it looks

```
CHP/LOADACS.txt:   Bosses  CHACS2  CHSett2  NICEICE  WVileEX

Bosses.acs   : #include zcommon                          -- no library use
CHSett2.acs  : #include zcommon                          -- no library use
NICEICE.acs  : #include zcommon                          -- no library use
WVileEX.acs  : #include zcommon                          -- no library use
CHACS2.acs   : #import "miscFuncs2.acs"   <-- THE ONLY CONSUMER
                 miscFuncs2.acs : #import commonFuncs2.acs, mathfuncs2.acs
```

Only `CHACS2.acs` touches the library chain, and it calls exactly one
function from it: `ProjInt_Brute`. Everything else in all three library files
is reachable only if `ProjInt_Brute` calls it.

**`ProjInt_Brute` calls exactly three library functions:**
`abs` (`miscFuncs2.acs:104` → `commonFuncs2.acs:40`),
`sq` (`:127, :156` → `mathFuncs2.acs:20`),
`FixedAngMod` (`:31,34,141,144,155,157` → `mathFuncs2.acs:30`).

Everything else it uses (`FixedMul`, `FixedDiv`, `FixedSqrt`, `VectorLength`,
`VectorAngle`, `cos`, `sin`, `random`, `UniqueTID`, `ThingCount`,
`Thing_ChangeTID`, `SetActivator`, `ActivatorTID`, `GetActor*`,
`SpawnProjectile`, `SetPointer`, `SetActorPosition/Angle/Velocity`,
`CheckFlag`) is **stock `zcommon.acs`**, not CHP code.

**Therefore: of the ~90 functions in `commonFuncs2.acs` (1238 lines, 25 KB),
exactly ONE — `abs` — is reachable from anything CHP loads.** The rest is a
dormant personal utility library shipped with the mod. It is still listed
below in full, because "I could not find a caller" is only trustworthy if the
list is complete.

---

### 5.1 `miscFuncs2.acs` — 174 lines, ONE function

```c
#library "miscfuncs2"          // :1
#include "zcommon.acs"         // :2
#import "commonFuncs2.acs"     // :3
#import "mathfuncs2.acs"       // :4
```

#### `function int ProjInt_Brute(int stid, int ttid, int spd, int ptid, int xoff, int yoff, int zoff, str ptype, int axoff, int ayoff, int azoff, int angoff, int rand, int input_t)` — `miscFuncs2.acs:6-174`

**What it computes.** A brute-force projectile intercept. It steps a candidate
flight time `t` through six refinement passes (coarse 10.0 → 1.0 → 0.1 → 0.01
→ 0.001 → 1 raw unit), each pass keeping the `t` whose implied projectile
speed is closest to the requested `spd` (`:104-107`), then converts that `t`
into a velocity vector, spawns `ptype` at the offset muzzle and stamps the
velocity on it directly.

**STATUS: ALREADY REPLACED IN THIS PROJECT.**
`zscript/systems/RS_MonsterAim.zs:34` `PredictInterceptPoint` and `:87`
`GetLeadAngle` do this analytically. Consumer at
`zscript/monsters/RS_MonsterMaster.zs:346`. **No port required.** What follows
is for fidelity-checking the replacement, not for rebuilding.

**Full body: `miscFuncs2.acs:6-174`.** Structure, with the parts that matter:

```c
  if(!stid || ThingCount(T_NONE,stid) > 1){          // :16   TID JUGGLING
    stid_z = 1; oldstid = ActivatorTID();
    stid = UniqueTID(); Thing_ChangeTID(0, stid); }
  ...
  sZ += zoff;                                        // :28   muzzle height
  if(xoff > 0){ sX += FixedMul(cos(FixedAngMod(s_ang - 0.25)),xoff);   // :30-32
                sY += FixedMul(sin(FixedAngMod(s_ang - 0.25)),xoff); }
  else if(xoff < 0){ sX += FixedMul(cos(FixedAngMod(s_ang + 0.25)),xoff);  // :33-35
                     sY += FixedMul(sin(FixedAngMod(s_ang + 0.25)),xoff); }
  ...
  tZ += 36.0;                                        // :55   aim at chest height
  if(!CheckFlag(ttid,"NOGRAVITY")){ tVelZ = 0; }     // :62   ignore falling targets' Z vel
  while(check){ ... }                                // :64-110  the six-pass search
  if(input_t){ t = input_t; }                        // :112
  else{ if(rand){ random(1, sml_t); }                // :114  RESULT DISCARDED
        else{ t = sml_t; }}                          // :115
  ...
  SpawnProjectile (stid, ptype, 0, 0, 0, 0, ptid);   // :162
  SetActivator(ptid);
  SetPointer(AAPTR_TARGET, stid); //so doesn't collide with it   // :164
  SetPointer(AAPTR_TRACER, ttid);                    // :165
  SetActorPosition(ptid, sX, sY, sZ, 0);             // :166
  SetActorAngle(ptid, p_ang);                        // :167
  SetActorVelocity(ptid,X_spd,Y_spd,Z_spd,0,0);      // :168
  if(stid_z){ Thing_ChangeTID(stid, oldstid); }      // :171  undo the juggling
  if(ttid_z){ Thing_ChangeTID(ttid, oldttid); }      // :172
```

**Four defects worth recording so the ZScript version is not "corrected" back
into them:**

**A. `T_S_z` is declared and never assigned.** `miscFuncs2.acs:10` declares it;
`:99` is its only other appearance:
```c
      Z_spd_t = FixedDiv((T_S_z + tVelZ_t), t);
```
It is therefore always 0, so **the flight-time search ignores the vertical
separation between shooter and target entirely.** The final velocity (`:125`
or `:131`) does use the real Z difference, so the shot still connects — but the
`t` it was solved for is the wrong one whenever the target is above or below.

**B. `rand` does not randomise.** `:114` calls `random(1, sml_t)` and **throws
the return value away**; `t` is never assigned in that branch. Tracing the
search loop, `t` at that point is `sml_t - (t_inc/2)` from `:65` with
`t_inc == 1` raw (set at `:85`), i.e. `t == sml_t` — identical to the `else`
branch. So `rand`'s *only* real effect is selecting the alternate velocity
solve at `:124-129`, which forces `|velocity| == spd` exactly
(`XY_spd = FixedSqrt(sq(spd) - sq(Z_spd))`) instead of the
displacement-over-time solve at `:130-134`. Given §3.2, **that normalised
branch is what every CHP call site actually uses.**

**C. `angoff` is applied TWICE to the velocity and ONCE to the sprite.**
`:154-158`:
```c
  if(angoff != 0){
    p_ang = FixedAngMod(p_ang + angoff);
    XY_spd = FixedSqrt(sq(X_spd) + sq(Y_spd));
    X_spd = FixedMul(cos(FixedAngMod(p_ang + angoff)), XY_spd);
    Y_spd = FixedMul(sin(FixedAngMod(p_ang + angoff)), XY_spd); }
```
`p_ang` already contains one `angoff`, so the velocity gets `base + 2*angoff`
while `SetActorAngle(ptid, p_ang)` at `:167` sets `base + 1*angoff`. For the
`_F` triple shots (§3.1, §3.2) that means **the outer rockets travel at
±15.38° but face ±7.69°** — they visibly fly sideways. Reproduce the ±15.38°
spread if fidelity is wanted; do not reproduce the sprite/velocity mismatch.

**D. The `xoff` / `yoff` sign branches are redundant — both signs go the same
way.** For `xoff > 0` (`:30-32`) the offset resolves to `(sinθ, -cosθ) * xoff`;
for `xoff < 0` (`:33-35`) it resolves to `(sinθ, -cosθ) * |xoff|`. **Both
displace to the actor's RIGHT.** Same for `yoff` (`:37-42`): both signs move
**forward**. The post-spawn `axoff` (`:140-145`) *is* correctly signed
(positive → left) and therefore uses the opposite convention to `xoff`, while
`ayoff` (`:147-152`) repeats the `yoff` bug. Consequence for the port: the
Cyberdemon's `xoff = -25.0` (`CHACS2.acs:8`) puts the muzzle **25 units to its
right**, not its left.

Also `:160`, `if(!ptid || ThingCount(T_NONE,stid) > 1){ ptid = UniqueTID(); }`
tests **`stid`** where it means `ptid` — harmless only because every caller
passes `ptid = 0`.

---

### 5.2 `mathFuncs2.acs` — 38 lines, 6 functions

```c
#library "mathfuncs2"  #include "zcommon.acs"  #import "commonfuncs2.acs"   // :1-3
```

| function | line | computes | port? |
|---|---|---|---|
| `int arcsin(int x)` | 5 | `VectorAngle(sqrt(1-x²), x)` — arcsine via ACS's vector-angle builtin | **NO PORT** — ZScript has `asin()`. Also **unreachable**: nothing calls it. |
| `int arccos(int x)` | 10 | arccosine, same trick | **NO PORT** — `acos()`. Unreachable. |
| `int arctan(int x)` | 15 | `VectorAngle(1.0, x)` | **NO PORT** — `atan()`. Unreachable. |
| `int sq(int x)` | 20 | `FixedMul(x,x)` — fixed-point square | **NO PORT** — `x*x` on a `double`. Used by `ProjInt_Brute:127,156`. |
| `int t_ang(int x)` | 25 | `abs(x % 0.5)` — folds an ACS angle into a half-turn | **NO PORT.** Unreachable. |
| `int FixedAngMod(int fAngle)` | 30 | wraps a fixed-point angle into `[0, 1.0)` | **NO PORT** — pure ACS fixed-point-angle workaround; ZScript angles are `double` degrees and `Normalize180`/`+= 360` handles it. Used by `ProjInt_Brute` x6. |

**Every function in mathFuncs2 is either an ACS-fixed-point workaround or an
inverse trig function ZScript has natively. Nothing here needs porting.**

---

### 5.3 `commonFuncs2.acs` — 1238 lines, ~90 functions

Header comment, `commonFuncs2.acs:4-5`: *"A bunch of functions that I've built
up / They come in handy :>"*. It is a personal standard library, not CH
gameplay code. Constants at `:7-14`, string/colour tables at `:16-35`.

**Reachability: only `abs` (`:40`) is called by anything CHP loads.** All the
rest are listed for completeness and are marked `unreachable`.

| function | line | computes | port verdict |
|---|---|---|---|
| `int itof(int x)` | 37 | `x << 16` — int → fixed | **NO PORT** — fixed-point workaround |
| `int ftoi(int x)` | 38 | `x >> 16` — fixed → int | **NO PORT** — fixed-point workaround |
| `int abs(int x)` | 40 | absolute value | **NO PORT** — ZScript `abs()`. *(the one reachable function)* |
| `int sign(int x)` | 46 | −1 if negative else **+1 (returns +1 for 0)** | **NO PORT** — trivial; note the 0 case if ever reused. unreachable |
| `int randSign(void)` | 52 | `2*random(0,1)-1` | **NO PORT** — trivial. unreachable |
| `int mod(int x, int y)` | 57 | Euclidean modulo (always non-negative) | **NO PORT** — trivial. unreachable |
| `int pow(int x, int y)` | 64 | integer power by repeated multiply | **NO PORT** — unreachable |
| `int powFloat(int x, int y)` | 71 | fixed-point power | **NO PORT** — fixed-point workaround. unreachable |
| `int gcf(int a, int b)` | 78 | greatest common factor, Euclid | **NO PORT** — unreachable |
| `int min(int x, int y)` | 92 | minimum | **NO PORT** — ZScript `min()`. unreachable |
| `int max(int x, int y)` | 98 | maximum | **NO PORT** — ZScript `max()`. unreachable |
| `int middle(int x,int y,int z)` | 104 | clamp-ish median of three | **NO PORT** — `clamp()`. unreachable |
| `int percFloat(int,int)` | 110 | builds a fixed-point number from int + hundredths | **NO PORT** — fixed-point workaround. unreachable |
| `int percFloat2(int,int,int)` | 115 | same, to ten-thousandths | **NO PORT** — fixed-point workaround. unreachable |
| `int keyUp(int key)` | 120 | all bits of `key` released this tic | **NO PORT** — player-input plumbing, not monster code. unreachable |
| `int keyUp_any(int key)` | 128 | any bit released | **NO PORT** — unreachable |
| `int keyDown(int key)` | 136 | all bits held | **NO PORT** — unreachable |
| `int keyDown_any(int key)` | 144 | any bit held | **NO PORT** — unreachable |
| `int keysPressed(void)` | 152 | edge mask: newly-pressed buttons | **NO PORT** — unreachable |
| `int keyPressed(int key)` | 161 | all bits newly pressed | **NO PORT** — unreachable |
| `int keyPressed_any(int key)` | 167 | any bit newly pressed | **NO PORT** — unreachable |
| `int inputUp / _any / Down / Down_any` | 173,181,189,197 | as above against `MODINPUT_BUTTONS` | **NO PORT** — unreachable |
| `int inputsPressed / inputPressed / _any` | 205,214,220 | edge masks on `MODINPUT_BUTTONS` | **NO PORT** — unreachable |
| `int adjustBottom(int,int,int)` | 226 | slides a range's low end to contain `i` | **NO PORT** — unreachable |
| `int adjustTop(int,int,int)` | 239 | slides a range's high end to contain `i` | **NO PORT** — unreachable |
| `int adjustShort(int,int,int)` | 252 | both ends, returned packed into one int | **NO PORT** — int-packing workaround. unreachable |
| `int sqrt_i(int number)` | 276 | integer sqrt, Newton (wiki-sourced, `:274`) | **NO PORT** — ZScript `sqrt()`. unreachable |
| `int zan_sqrt(int number)` | 293 | fixed-point sqrt, 15 fixed iterations from 150.0 | **NO PORT** — fixed-point workaround. unreachable |
| `int magnitudeTwo(int,int)` | 303 | integer 2-D length | **NO PORT** — `Vector2.Length()`. unreachable |
| `int magnitudeTwo_f(int,int)` | 308 | fixed 2-D length via `VectorAngle` + sin/cos | **NO PORT** — fixed-point workaround. unreachable |
| `int magnitudeThree(int,int,int)` | 319 | integer 3-D length | **NO PORT** — `Vector3.Length()`. unreachable |
| `int magnitudeThree_f(int,int,int)` | 324 | fixed 3-D length, two-stage | **NO PORT** — fixed-point workaround. unreachable |
| `int quadPos / quadNeg(a,b,c)` | 340,349 | the two quadratic roots | **NO PORT** — unreachable. *(the analytic intercept `ProjInt_Brute` brute-forces is exactly this — CH shipped the solver and never used it)* |
| `int quad(a,b,c,y)` | 359 | evaluates `ay²+by+c+y` (**note the stray `+ y`**) | **NO PORT** — unreachable |
| `int quadHigh / quadLow(a,b,c,x)` | 364,369 | roots of `…= x` | **NO PORT** — unreachable |
| `int inRange(low,high,x)` | 374 | `low <= x < high` | **NO PORT** — unreachable |
| `void AddAmmoCapacity(type,add)` | 379 | raises an ammo cap by `add` | **NO PORT** — unreachable |
| `int packShorts(left,right)` | 384 | two 16-bit values into one int | **NO PORT** — ACS storage workaround. unreachable |
| `int leftShort / rightShort(packed)` | 389,390 | unpack | **NO PORT** — workaround. unreachable |
| `int cleanString(string)` | 395 | strips control chars and `\c` colour escapes | **NO PORT** — HUD text. unreachable |
| `int cvarFromString(prefix,newname)` | 423 | builds a legal CVar name from arbitrary text | **NO PORT** — unreachable |
| `int padStringR / padStringL` | 449,471 | right/left pad to length | **NO PORT** — unreachable |
| `int changeString(string,repl,where)` | 493 | overwrite a substring | **NO PORT** — unreachable |
| `int sliceString(string,start,end)` | 520 | Python-style slice with negative indices | **NO PORT** — unreachable |
| `int zand_strcmp(str1,str2)` | 547 | lexicographic compare → −1/0/1 | **NO PORT** — unreachable |
| `int strstr(string,from,to)` | 567 | find-and-replace | **NO PORT** — unreachable |
| `int unusedTID(start,end)` | 627 | first free TID in a range | **NO PORT** — **pure TID juggling**. unreachable |
| `int getMaxHealth(void)` | 645 | `APROP_SpawnHealth`, defaulting players to 100 | **NO PORT** — `SpawnHealth()`. unreachable |
| `int giveHealth(amount)` | 657 | heal up to spawn health | **NO PORT** — unreachable |
| `int giveHealthFactor(amount,maxFactor)` | 662 | heal up to `spawnHealth * factor` | **NO PORT** — unreachable |
| `int giveHealthMax(amount,maxHP)` | 667 | heal, clamped, returns actual gain | **NO PORT** — unreachable |
| `int isDead(tid)` | 685 | health <= 0 | **NO PORT** — unreachable |
| `int isSinglePlayer / isLMS / isCoop / isInvasion / isFreeForAll / isTeamGame` | 690,695,700,708,713,726 | game-mode predicates from CVars | **NO PORT** — Zandronum multiplayer modes this project does not have. unreachable |
| `int spawnDistance(item,dist,tid)` | 732 | spawn `item` `dist` units along the activator's aim | **NO PORT** — `A_SpawnItemEx`. unreachable |
| `void SetInventory(item,amount)` | 748 | force an inventory count to an exact value | **NO PORT** — unreachable |
| `int ToggleInventory(inv)` | 764 | have→take-all, not-have→give 1 | **NO PORT** — unreachable |
| `void GiveAmmo(type,amount)` | 776 | give ammo, honouring `sv_doubleammo` | **NO PORT** — unreachable |
| `void GiveActorAmmo(tid,type,amount)` | 792 | as above, on another actor | **NO PORT** — unreachable |
| `int cond / condTrue / condFalse` | 808,814,820 | ternary substitutes (ACS has no `?:`) | **NO PORT** — language workaround. unreachable |
| `void saveCVar(cvar,val)` | 826 | `set` + `archivecvar` via `ConsoleCommand` | **NO PORT** — unreachable |
| `int defaultCVar(cvar,defaultVal)` | 833 | read, writing the default back if unset | **NO PORT** — CVARINFO does this. unreachable |
| `int onGround(tid)` | 842 | `z == floorz` | **NO PORT** — `pos.z == floorz`. unreachable |
| `int ThingCounts(start,end)` | 847 | sum `ThingCount` over a TID range | **NO PORT** — **TID juggling**. unreachable |
| `int PlaceOnFloor(tid)` | 857 | snap an actor to its floor | **NO PORT** — unreachable |
| `int getDirection(void)` | 874 | 8-way movement direction from held keys (`DIR_*` at `:865-872`) | **NO PORT** — unreachable |
| `int isInvulnerable(void)` | 914 | `APROP_Invulnerable` or `PowerInvulnerable` | **NO PORT** — unreachable |
| `void saveStringCVar(string,cvarname)` | 922 | writes a string one char per CVar | **NO PORT** — ACS has no string storage; a pure workaround. unreachable |
| `int loadStringCVar(cvarname)` | 945 | reads it back | **NO PORT** — workaround. unreachable |
| `int defaultTID(def)` | 964 | ensure the activator has a unique TID | **NO PORT** — **pure TID juggling**. unreachable |
| `int _defaulttid(def,alwaysPropagate)` | 969 | the implementation; random 12–220 x100 TID blocks | **NO PORT** — TID juggling. unreachable |
| `int HeightFromJumpZ(jumpz,gravFactor)` | 993 | apex height from jump velocity | **NO PORT** — unreachable |
| `int JumpZFromHeight(height,gravFactor)` | 999 | inverse of the above | **NO PORT** — unreachable |
| `int roundZero(toround)` | 1004 | truncate toward zero, to int | **NO PORT** — unreachable |
| `int roundAway(toround)` | 1010 | round away from zero, to int | **NO PORT** — unreachable |
| `int intFloat(toround)` | 1018 | strip the fraction, stay fixed | **NO PORT** — fixed-point workaround. unreachable |
| `int distance(x1..z2)` | 1023 | 3-D distance between two points | **NO PORT** — vector subtraction. unreachable |
| `int distance_tid(tid1,tid2)` | 1028 | 3-D distance between two actors | **NO PORT** — `Distance3D()`. unreachable |
| `int distance_ftoi(...)` | 1041 | the above, as an int | **NO PORT** — unreachable |
| `void printDebugInfo(void)` | 1046 | dumps activator state to the log | **NO PORT** — debug. unreachable |
| `int PlayerTeamCount(teamNo)` | 1074 | players on a team | **NO PORT** — team modes. unreachable |
| `int lower / upper(chr)` | 1084,1090 | ASCII case flip | **NO PORT** — unreachable |
| `int strLower / strUpper(string)` | 1096,1110 | whole-string case | **NO PORT** — `String.MakeLower()`. unreachable |
| `int AddActorProperty(tid,prop,amount)` | 1124 | read-modify-write an actor property | **NO PORT** — direct field access. unreachable |
| `int ClientCount(void)` | 1131 | players + spectators | **NO PORT** — unreachable |
| `int HasRoom(actorname,x,y,z)` | 1143 | test-spawn then remove, to probe fit | **NO PORT** — `TestMobjLocation()`. unreachable |
| `int RealPlayerCount(void)` | 1153 | in-game non-bot players | **NO PORT** — unreachable |
| `int quadSlope(orgX,orgY,pntX,pntY,floatY)` | 1165 | a signed "slope" via `zan_sqrt` then squared | **NO PORT** — unreachable |
| `int actorVelMagnitude(tid)` | 1189 | speed of an actor | **NO PORT** — `vel.Length()`. unreachable |
| `int isAmmo(name)` | 1194 | `GetAmmoCapacity > 0` | **NO PORT** — unreachable |
| `int intcmp(x,y)` | 1199 | −1/0/1 compare | **NO PORT** — unreachable |
| `int RaiseAmmoCapacity(ammoname,newcapacity,raiseammo)` | 1207 | raise a cap and optionally top up. **Returns `CheckInventory(ammo)` — passing the *count* where a name is expected (`:1223`); the return value is garbage.** | **NO PORT** — unreachable |
| `int Zand_GetCVarFixed(cvarname)` | 1226 | reads a float CVar by round-tripping through `eval` and a temp CVar | **NO PORT** — the purest ACS workaround in the file. unreachable |

### 5.4 THE ANSWER TO "WHICH LIBRARY FUNCTIONS NEED NO PORT"

**All of them.** Precisely:

1. **`ProjInt_Brute`** (`miscFuncs2.acs:6`) — the only library function with
   gameplay meaning, and it is **already replaced** by
   `RS_MonsterAim.GetLeadAngle` / `PredictInterceptPoint`
   (`zscript/systems/RS_MonsterAim.zs:34,87`).
2. **All 6 of `mathFuncs2.acs`** — fixed-point-angle wrapping and inverse trig
   that ZScript has natively.
3. **All ~90 of `commonFuncs2.acs`** — split into four kinds, none portable:
   * **fixed-point arithmetic workarounds** — `itof`, `ftoi`, `powFloat`,
     `zan_sqrt`, `magnitude*_f`, `percFloat*`, `intFloat`, `Zand_GetCVarFixed`.
     ZScript uses `double`; these have no referent.
   * **TID juggling** — `unusedTID`, `defaultTID`, `_defaulttid`,
     `ThingCounts`, and the `Thing_ChangeTID` dance inside `ProjInt_Brute`
     itself (`miscFuncs2.acs:16-21, 44-50, 171-172`). ZScript holds actor
     pointers; there is nothing to juggle.
   * **language workarounds** — `cond`/`condTrue`/`condFalse` (no `?:` in ACS),
     `packShorts`/`leftShort`/`rightShort` (no structs),
     `saveStringCVar`/`loadStringCVar` (no string storage), the whole string
     module (no `String` type).
   * **Zandronum multiplayer plumbing** — `isCoop`, `isLMS`, `isTeamGame`,
     `isFreeForAll`, `isInvasion`, `PlayerTeamCount`, `ClientCount`,
     `RealPlayerCount`, and all 14 `key*`/`input*` functions.

There is **no `Warp()` line-of-sight fake** anywhere in these three libraries;
the only `A_Warp` in the engine is real teleport behaviour in DECORATE
(`14_WX.txt:271, 396`) and must be ported as movement.

---

## 6. CORRECTIONS TO THE EXISTING PORT COMMENTS

Both claims the brief asked to check were tested against the source.

**CLAIM 1 — `RS_Archvile.zs:90-92`:**
> *"CHP sets it from ACS ("WVileEXTimer2_C", Delay(10500) = exactly 300
> seconds)"*

**CONFIRMED, exactly.** `WVileEX.acs:2132` is `Delay(10500)`; 10500 / 35 =
300.0 s. The parallel `WVileEXTimer_C` (`WVileEX.acs:199-318`) reaches the
same 10500 as **39 separate delays** (29 x 350 + 10 x 35), verified by summing
the literals. So "a `Delay(10500)`" is right about `Timer2` and would be wrong
about `Timer` — worth a word if that comment is ever rewritten.

**Two additions the comment does not carry, both load-bearing:**
* `10500` is not a constant, it is `SpawnHealth x 105 / 208`. All 15 live
  variants obey it (§2.4). Hard-coding 10500 silently welds the Archvile to
  one spawn colour.
* `Timer2` does two things, not one: the token **and**
  `SetActorProperty(0, APROP_INVULNERABLE, TRUE)` (`WVileEX.acs:2133`), which
  is never cleared. `RS_Archvile.zs:1709-1711` already records the
  invulnerability; `:90-92` does not.

**CLAIM 2 — `RS_Archvile.zs:1983-1985`:**
> *"CHP finishes this with an ACS script that strips the player's armour and
> slows them; the ACS is stripped, so the two things it actually DID are done
> here directly."*

**CONFIRMED AND HONEST, but it undercounts by three.** `WVileEXArmorSteal_C`
(`WVileEX.acs:5-15`) does **five** things: armour strip, 10 s speed nerf to
25%, **20 direct damage**, **`AmbientSound("WVEXTAKE",255)`**, and **an instant
opaque white full-screen blind with a 1-second fade-out** (`:8` and `:14`).
The implementation at `RS_Archvile.zs:1995-2002` already covers the first
four. **The only genuine gap is the screen flash.** The comment's phrase "the
two things it actually DID" should read *five*, since the code beneath it
already does four of them.

This is the good kind of comment — it described the gap accurately enough that
checking it took one file open. Contrast the "porting it imports nothing"
class of comment, which is what hid this engine for three sessions.

---

## 7. WHAT A REBUILD WOULD ACTUALLY COST

| piece | scripts | real content | shape |
|---|---|---|---|
| WVileEX countdown presentation | 16 `Timer_*` | one 40-line Thinker + a derived duration | Thinker |
| WVileEX expiry | 16 `Timer2_*` | 2 lines + a deadline field | field + state branch |
| WVileEX armour steal | 16 `ArmorSteal_*` | 5 verbs, 4 already built | inline helper |
| WVileEX sound stop | 1 `TimeStop` | nothing | delete |
| Cyberdemon lead-fire | 15 `CybMissile_*` | 4 numbers x 15 | `RS_AttackProfile` rows |
| Baron/HK/LostSoul lead-fire | 15 `BaronMissile_*` | 5 numbers x 15 | `RS_AttackProfile` rows |
| the whole library chain | — | already replaced | none |
| the `_E` set | 3 | **DEAD** | none |

**79 scripts, 3 dead, and after collapsing the recolour axis (rs_21 §1) the
`Common`-only work is: one Thinker, one deadline field, one inline helper, and
two `RS_AttackProfile` rows.**
