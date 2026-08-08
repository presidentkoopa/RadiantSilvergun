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

# SHOTGUNNER — MONSTER ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Closed shape vocabulary,
fixed field order, `--` for genuinely-absent, never a blank.

## Denominator — what was actually read

| | count | note |
|---|---|---|
| source files read whole | 2 | `RS_Shotgunner.zs` (2,312 lines), `RS_ShotgunnerFX.zs` (1,319 lines) |
| classes opened | 80 | 23 in `RS_Shotgunner.zs` + 49 in `RS_ShotgunnerFX.zs` + 8 cross-file payloads opened in `RS_Zombieman.zs` / `RS_ZombiemanFX.zs` |
| classes that are combat monsters | **15** | 13 tier monsters + 2 Benellus forms. The brief said 14; see UNRESOLVED #1. |
| classes that are summoned emplacements and attack | 5 | `RS_ShotgunShrine`, `RS_ShotgunPunish`, `RS_ShotgunPunish2`, `RS_ShotgunPunishnerf`, `RS_ShotgunPunishnerf2` — all in the FX file, all `Monster;` |
| spawn-dial / cvar stub classes (no attacks) | 8 | `RS_ShotgunnerColourset` + 7 `RS_*SG` gates |
| attack-bearing state labels followed | 34 | of which **17 are NOT named `Missile:` or `Melee:`** — see the jump map below |
| attack call sites, comments stripped | 117 source lines | `A_CustomBulletAttack` 32, `A_CustomMissile` 80, `A_CustomRailgun` 7, `A_VileTarget` 5, `A_SkullAttack` 2, `A_SPosAttack*` 1. Source LINES — per-frame expansion is far higher (see `RS_WhiteSGEX.FocusedFire`: 32 lines, **224** calls). |
| **ATTACK ROWS WRITTEN** | **42** | |

Absolute paths:
`E:\RS_Main\zscript\monsters\shotgunner\RS_Shotgunner.zs`,
`E:\RS_Main\zscript\monsters\shotgunner\RS_ShotgunnerFX.zs`.
`file` lines below are repo-relative, per the spec's worked example.

## Verification against CH

Every attack call site in our tree was diffed against CH's own
`decorate/Shotgunners.txt` (3,047 lines). **All 117 match verbatim** —
same function, same arguments, same rolls, same order. Our tree is a
faithful transcription of CH on the attack axis. Where numbers below
look strange (`random(-1,-1)`, `random(5,180)`, a spread that can be
negative), they are strange **in CH too** and are recorded as written.

CH was read at `E:\New folder\ART SOURCE\CH\decorate\Shotgunners.txt` —
`C:\Users\Command\Desktop\CH` does not exist on this machine. See
UNRESOLVED #2.

## Two FX classes derive from vanilla `BulletPuff` — they are IMPACT PUFFS, NOT PAYLOADS

* **`RS_RedDotSGPuff`** — `RS_ShotgunnerFX.zs:429`. The Gray sniper's
  laser-sight dot. `+PAINLESS +NOBLOOD`, red translation, `PUFF A 6`.
  Carried by a **damage-0** `A_CustomRailgun`. No damage, ever.
* **`RS_CyanSGPuff`** — `RS_ShotgunnerFX.zs:450`. The Cyan sergeant's
  frost impact. `DeathSound "Ice/Hit2"` plus a cyan particle spray. Its
  *damage* comes from the `A_CustomBulletAttack` that spawned it, not
  from the puff.

Neither is counted as a payload anywhere below. They appear only in
`impact` lines. Three OTHER puff classes in this family **are**
substantial and DO carry their own damage — `RS_DetoPuffCG` (explodes,
`A_Explode(random(2,6),42)`), `RS_DetoPuffCG2` (`A_Explode(random(12,36),42)`
+ `A_Burst`), and `RS_SplashAbyss2` (`DamageFunction (random(1,9))`,
DamageType Ice) — none of which derive from `BulletPuff`.

## Jump map — the states a name filter would miss

A filter on `Missile:`/`Melee:` finds **17 of 34** attack states here.
The other 17 are reached through:

```
RS_BrownSG2.Missile   -A_JumpIfCloser(400)-------------> Fire1
                      -A_JumpIfInTargetLOS(1200,700)---> Fire1
                      -A_Jump(255)---------------------> GetCloser
RS_CyanSG2.Missile    -A_Jump(128)---------------------> Proj
RS_GraySG2.Missile    -A_JumpIfCloser(800)-------------> Fire1
                      -A_Jump(255)---------------------> GetReady -A_JumpIf(user_ready>=1)-> Fire2
RS_AbyssSG2.Missile   -A_JumpIfCloser(800)-------------> Jumper
RS_BlueSG.Missile     -A_JumpIfCloser(350)-------------> Lance
RS_PurpleSG.Missile   -A_JumpIfCloser(300)-------------> Fire1 -A_JumpIfCloser(300)-> Fire2
                      -A_Jump(255)---------------------> GetCloser
RS_YellowSG.Missile   -A_JumpIfInventory(ASGZAmmo,16)--> Reload
RS_RedSG.Missile      -A_JumpIfCloser(650)-------------> Shotgunned -A_JumpIfInventory-> Jammed
RS_BlackSG3.Missile   -A_JumpIfCloser(500)-------------> Shotgunned -A_Jump(64)-> Nadetoss
                      -A_Jump(128)/(255)---------------> Summon | AirStrike | Snipe
RS_BlackSG2 (troop)   -RS_ZSpecOpsSGSitRep stance roll-> AggressiveMissile | CreepMissile | BerserkMissile
                      -A_Chase(null,"<state>")---------> (all three are A_Chase missilestate args, not labels)
                      -A_Jump(64)---------------------> NadeToss
RS_WhiteSG2.Missile   -A_Jump(256,3-way)--------------> SG | Gifts | Punisher
RS_WhiteSGEX.Missile  -A_JumpIfCloser(1500)-----------> OtherM -A_Jump(256,4-way)-> SG|Gifts|FocusedFire|ShotgunRounded
                      -A_Jump(128)-------------------> FocusedHitScan
                      -fallthrough-------------------> ShotgunRounded
RS_WhiteSGEX.Pain     -(direct spawn)----------------> RS_ShotgunShrine (a live 800hp turret)
RS_WhiteSG*.Death     -(direct)----------------------> 9x RS_HKRedDeath
```

`RS_BlackSG2`'s three missile states are especially invisible: they are
never `Goto`-ed. They arrive as the **second argument to `A_Chase`**
(`A_Chase(null,"AggressiveMissile")`, `RS_Shotgunner.zs:1759`), which no
label scan and no `Goto` scan will find.

---

# ROWS

Grouped by monster, ascending CH tier.

---

## RS_CommonSG — tier 1

```
ATTACK   RS_CommonSG.Missile
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:867
shape    HITSCAN
payload  BulletPuff x3   (vanilla engine puff)
arc      22.5 horizontal / 5.625 vertical   (engine constants inside A_SPosAttackUseAtkSound)
timing   10 tics face -> fire on 1 tic -> 10 tics recover   (21 tics, one shot)
damage   random(1,5) * 3  per pellet   (3..15 each, 9..45 total)
type     --   (engine default 'Hitscan')
sound    AttackSound -- inherited "shotguy/attack" from ShotgunGuy; the
         engine function plays it, which is the whole point of the
         UseAtkSound variant over plain A_SPosAttack
impact   vanilla BulletPuff; blood on actors
trigger  Missile
range    --
mirrored no
inherit  ShotgunGuy (AttackSound, Health 70, Speed 8, all vanilla stats)
profile  MakeHitscan(fireSnd:"shotguy/attack", profName:"sg_t01_buckshot");
         p.PelletOverride = 3; p.SpreadBonus = 22.5;
notes    The family's baseline and the ONLY row here delivered by an
         engine-native function rather than an explicit A_CustomBulletAttack.
         CH:839 is identical. Damage/spread are engine constants, not
         written anywhere in our tree or CH's -- so they are the one set
         of numbers in this file NOT verified against a file on disk.
         See UNRESOLVED #3.
```

---

## RS_GreenSG — tier 2

```
ATTACK   RS_GreenSG.Missile
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:976
shape    FAN
payload  RS_SGshot1 x7
arc      6   (angles +1, 0, -1, +2, -2, +3, -3 -- a 1-degree step over -3..+3)
timing   all 7 on ONE tic (seven 0-tic frames), after 12 tics face and a
         5-tic flash; 9-tic recover. 26 tics total.
damage   DamageFunction (random(2,6))   per bolt
type     Plasma
sound    "shotguy/attack" (explicit A_PlaySound on the frame before the fan)
impact   BAL1 CDE 6 Bright, DeathSound "imp/shotx". No explode, no splash.
trigger  Missile
range    --
mirrored no
inherit  ShotgunGuy (stats overridden wholesale); RS_SGshot1 is a flat Actor
profile  MakeVolley(proj:"RS_SGshot1", count:7, arc:6,
                    fireSnd:"shotguy/attack", profName:"sg_t02_plasmafan")
notes    Speed 55 / FastSpeed 80, Scale 0.15 -- these are tiny fast pellets,
         a plasma buckshot rather than seven fireballs. The angle ORDER
         (1,0,-1,2,-2,3,-3) is CH's, not sorted; irrelevant on one tic but
         recorded so nobody "tidies" it.
         DISCREPANCY vs docs/monsters/Shotgunner/CATALOG.md entry 2, which
         says the 7th bolt leaves on the lowering frame. It does not --
         all seven are 0-tic. Our tree and CH:943-949 agree with each other.
```

---

## RS_BlueSG — tier 3

```
ATTACK   RS_BlueSG.Missile
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1093
shape    HITSCAN
payload  -- (instant trace, no puff: pufftype is the string "none" on all three)
arc      0 aimed; autoaim tolerance maxdiff 25 / 12 / 33 on the three beams
timing   three 0-tic frames -- all three beams on ONE tic, after a 10-tic
         face and a 5-tic wind. 24 tics total.
damage   random(2,8) per beam   (6..24 across the three)
type     --
sound    -- (RGF_SILENT is NOT set, so the engine's default railgun sound
         plays; nothing in our tree or CH names one)
impact   none -- pufftype "none". Only the beam trail: White/sparsity 3,
         Blue/sparsity 1, White/sparsity 1.
trigger  Missile
range    ..  (this is the FAR branch: taken when A_JumpIfCloser(350) fails)
mirrored no
inherit  ShotgunGuy
profile  MakeHitscan(profName:"sg_t03_railvolley"); p.PelletOverride = 3;
         p.MinRange = 350;
notes    Delivered by A_CustomRailgun, NOT A_CustomBulletAttack. The shape
         vocabulary names only the latter two functions under HITSCAN --
         classified HITSCAN because it is an instant line attack with no
         travelling actor, which is what a weapon rebuilds. Flagged in
         UNRESOLVED #4 rather than coining a word.
         RGF_NOPIERCING is set on all three: CH deliberately turns rail
         pierce OFF. Do not "restore" it.
```

```
ATTACK   RS_BlueSG.Lance
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1100
shape    SINGLE
payload  RS_SGLance1 x1
arc      --
timing   2-tic face -> fire on a 4-tic frame -> 9-tic recover. 15 tics.
damage   Damage 1  +STRIFEDAMAGE +RIPPER
type     Plasma
sound    SeeSound "weapons/plasmax" (on the projectile, not the attack)
impact   PLSE E 1 Bright -> spawns RS_SGLance5, which A_Explode(random(2,8),32).
         DeathSound "weapons/plasmax".
trigger  Missile   (via A_JumpIfCloser(350) from Missile)
range    ..350
mirrored no
inherit  RS_SGLance1 is a flat Actor; its TRAIL children chain
         RS_SGLance2 : RS_SGLance1 -> RS_SGLance3 : RS_SGLance2 ->
         RS_SGLance4 : RS_SGLance2. THE ATTACK IS THE CHAIN, not the head.
profile  MakeHeavy(proj:"RS_SGLance1", fireSnd:"weapons/plasmax",
                   spawnHeight:34, profName:"sg_t03_lance");
         p.MaxRange = 350;
notes    +RIPPER and Damage 1 with +STRIFEDAMAGE: the engine rolls
         Strife-style, so a single Damage 1 is NOT one point -- and the
         ripper means it hits repeatedly along its path. The real damage
         is the trail: SGLance1 spawns SGLance2 five times in flight,
         each of which spawns SGLance3 three times, each of which spawns
         SGLance4 three times. SGLance2/3 carry
         DamageFunction (random(0,1)) each. Up to 5 + 15 + 45 = 65
         trail actors from one shot.
         The `PLSS C D E` frames CH wrote do not exist (PLSS ships A,B
         only); our tree holds the A/B flicker with the tic and spawn
         counts unchanged -- see the FX file header. Cosmetic only.
```

---

## RS_PurpleSG — tier 4

```
ATTACK   RS_PurpleSG.GetCloser
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1211
shape    CHARGE
payload  -- (the monster IS the projectile)
arc      --
timing   A_PlaySound on a 0-tic frame, then two 3-tic frames = 6 tics of
         launch; the charge itself runs until impact or wall
damage   -- (A_SkullAttack deals the actor's own melee-on-contact damage;
         no Damage/DamageFunction is set on RS_PurpleSG, so this is the
         engine's Lost-Soul contact roll)
type     --
sound    "gas/gas1"
impact   contact damage; no puff, no spawn
trigger  Missile   (via A_Jump(255) when A_JumpIfCloser(300) fails)
range    300..
mirrored no
inherit  ShotgunGuy
profile  MakeMelee(range:64, fireSnd:"gas/gas1", profName:"sg_t04_rush");
         p.MinRange = 300;
notes    A_SkullAttack(12) -- speed 12. The ONLY tier below 13 that
         answers distance with movement instead of a bigger gun.
         CH:1312 identical. As a player profile this is a lunge, not a
         projectile; MakeMelee is the closest honest factory and the
         "charge" motion is not representable -- see UNRESOLVED #5.
```

```
ATTACK   RS_PurpleSG.Fire2
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1219
shape    BURST
payload  RS_Purpfire2 x3
arc      0   (see notes -- the roll is degenerate)
timing   2,1,2,1,2,1 -- face 2, fire 1, face 2, fire 1, face 2, fire 1.
         3 tics between shots. 9 tics, then a 2-tic A_MonsterRefire(180).
damage   DamageFunction (random(5,10))   per bolt
type     Fire
sound    SeeSound "fire/fire1" (on the projectile); AttackSound is the
         literal string "none" on this monster -- the ATTACK is silent
impact   PFIR EFFG 5 Bright with A_Explode(random(3,10),20) ON EVERY FRAME
         -- 4 frames, so FOUR explosions, plus 4 more from the Spawn state
         (PFIR ABCD 5 also carries A_Explode). DeathSound "Imp/shotx".
trigger  Missile   (via A_JumpIfCloser(300) TWICE: Missile -> Fire1 -> Fire2)
range    ..300
mirrored no
inherit  ShotgunGuy
profile  MakeBurst(proj:"RS_Purpfire2", count:3, delayTics:3,
                   profName:"sg_t04_flameburst"); p.MaxRange = 300;
notes    THE ANGLE ROLL IS `random(-1,-1)` -- a degenerate range that can
         only return -1. Verbatim from CH:1320-1324. It is NOT spread;
         it is a constant -1 degree offset wearing a random() costume.
         Recorded as written; do not simplify it to -1 without a
         `// CH: random(-1,-1)` note, and do not widen it to random(-1,1).
         RS_Purpfire2 explodes CONTINUOUSLY in flight (A_Explode on all
         four Spawn frames), so it is an area-denial bolt, not a bullet.
         Refire loop: Fire2 ends A_MonsterRefire(180,"See") then Goto
         Fire1, so it re-checks range and keeps burning while you stay in.
```

---

## RS_YellowSG — tier 5

```
ATTACK   RS_YellowSG.Missile
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1336
shape    HITSCAN
payload  BulletPuff x3   per shot
arc      5 horizontal / 4 vertical
timing   PER SHOT: 5-tic face -> fire on 5-tic frame -> 7-tic recover ->
         5-tic A_CPosRefire. 22 tics/shot, four shots per pass = 88 tics.
         THEN Reload: 60 tics standing + 8 tics. 68-tic window.
damage   3   (flat, per pellet -- one of only two flat damages in the family)
type     --
sound    A_PlaySound("asgguy/asgld1") between shots; AttackSound
         "asgguy/asgfir"; reload plays "asgguy/asgout" then "asgguy/asgin"
impact   vanilla BulletPuff
trigger  Missile
range    --
mirrored no
inherit  flat Actor (does NOT inherit ShotgunGuy)
profile  MakeHitscan(fireSnd:"asgguy/asgfir", ammoCost:1,
                     profName:"sg_t05_autoshotgun");
         p.PelletOverride = 3; p.SpreadBonus = 5;
notes    ONE row, not four: the four A_CustomBulletAttack lines are four
         pulls of the same trigger, identical in every argument. What
         varies is the MAGAZINE, and that is the attack's real shape --
         a 16-round `RS_ASGZAmmo` counter (`RS_ShotgunnerFX.zs:1257`,
         MaxAmount 16) checked five times per pass.
         THE RELOAD IS THE FIGHT'S WINDOW: `bNOPAIN = true` for the whole
         68 tics, so it cannot be flinched out of it, and it does not move.
         A_CPosRefire between shots means it drops the burst if you break
         line of sight -- the magazine is not a commitment.
         Neither the magazine nor the reload is representable in
         RS_AttackProfile. See UNRESOLVED #6.
         CH:1450-1484 identical, including CH's `A_ChangeFlag("NoPain",1)`
         which our tree writes as `{ bNOPAIN = true; }`.
```

---

## RS_RedSG — tier 6

```
ATTACK   RS_RedSG.Missile
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1471
shape    SALVO
payload  RS_RedMessImp3 x5
arc      0  -- ALL FIVE FIRE AT ANGLE 0. See notes.
timing   all 5 on ONE tic (five 0-tic frames), after a 10-tic face;
         8-tic recover. 18 tics.
damage   DamageFunction (random(2,19))   per bolt, inherited from RS_RedMessImp2
type     Fire   (inherited)
sound    SeeSound "imp/attack" (on the projectile); AttackSound "SSGUNER/SSG"
impact   BAL1 CDE 1 A_SetTranslucent(0.35), DeathSound "weapons/firex4"
         -- AND 15 x RS_RedMessImp sparks sprayed at random(-180,180) on
         a 0-tic frame at death (RS_ShotgunnerFX.zs:359). ALL INHERITED
         except the 15-spark line, which RS_RedMessImp3 adds.
trigger  Missile   (taken when A_JumpIfCloser(650) fails)
range    650..
mirrored no
inherit  RS_RedMessImp3 : RS_RedMessImp2 : Actor. Damage, DamageType,
         SeeSound, DeathSound, Translation and +SEEKERMISSILE all come
         from RS_RedMessImp2 (RS_ShotgunnerFX.zs:313) and are written
         nowhere near the attack.
profile  MakeVolley(proj:"RS_RedMessImp3", count:5, arc:0,
                    fireSnd:"SSGUNER/SSG", profName:"sg_t06_redmess");
         p.MinRange = 650;
notes    THE FIVE NUMBERS ARE NOT ANGLES. A_CustomMissile's signature is
         (type, spawnHEIGHT, spawnOFS_XY, angle, flags, pitch). The five
         calls are (42,12,0) (32,random(4,8),0) (22,random(14,26),0)
         (22,12,0) (42,random(6,18),0) -- so heights 42/32/22/22/42 and
         LATERAL SPAWN OFFSETS 12 / 4-8 / 14-26 / 12 / 6-18, with angle 0
         on every one. Five parallel streams from five muzzle points, all
         aimed dead ahead, not a spread.
         DISCREPANCY vs CATALOG.md entry 18, which reads those values as
         angles. Our tree and CH:1604-1608 agree with each other.
         RS_RedMessImp3 DOES NOT HOME, despite inheriting +SEEKERMISSILE:
         it overrides Spawn and drops the parent's A_SeekerMissile(3,5)
         call. The flag without the call does nothing. Speed 48 (vs the
         parent's 11) -- it trades homing for velocity.
```

```
ATTACK   RS_RedSG.Shotgunned
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1482
shape    HITSCAN
payload  BulletPuff x random(15,20)
arc      11.2 horizontal / 7.1 vertical
timing   5-tic face, 5-tic face, fire on an 8-tic frame, 8-tic recover.
         26 tics. THEN THE GUN JAMS.
damage   random(1,3)   per pellet   (15..60 total)
type     --
sound    AttackSound "SSGUNER/SSG"; the jam plays "weapons/sshotl"
impact   vanilla BulletPuff
trigger  Missile   (via A_JumpIfCloser(650) from Missile)
range    ..650
mirrored no
inherit  flat Actor
profile  MakeHitscan(fireSnd:"SSGUNER/SSG", profName:"sg_t06_ssg");
         p.PelletOverride = 17; p.SpreadBonus = 11.2; p.MaxRange = 650;
notes    ONE SPRAY, THEN A FREE WINDOW. It takes RS_ShotgunWhere
         (RS_Zombieman.zs:1822, MaxAmount 1) after firing; the next
         Shotgunned entry sees the token and diverts to Jammed
         (RS_Shotgunner.zs:1502), which burns 8 + 2 + 10 = 20 tics racking
         the gun before returning to Missile. So the close attack is
         literally every-other-time.
         PelletOverride 17 above is the midpoint of a random(15,20) roll
         the profile system cannot express; the roll is the truth --
         see UNRESOLVED #6.
```

---

## RS_FireBluSG2 — tier 7

```
ATTACK   RS_FireBluSG2.Missile
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:782
shape    FAN
payload  RS_FireSGguy x5
arc      26   (angles 0, +8, +13, -13, -8; lateral offsets -2, 6, 9, -13, -10)
timing   four on 0-tic frames + the fifth on an 8-tic frame -- the action
         runs at frame START, so all five leave on ONE tic. 10-tic face
         before, 8+8 tics of flash after. 26 tics.
damage   DamageFunction (random(5,15))   per flame
type     Fire
sound    SeeSound "imp/attack" (on the projectile); AttackSound "SSGUNER/SSG"
impact   FIRE CDEEDCDE 3 then FIRE FGH 3, with A_Explode(random(3,15),64)
         ON EVERY ONE OF THOSE 11 FRAMES -- eleven explosions per flame,
         five flames = up to 55 blasts. DeathSound "imp/shotx".
trigger  Missile
range    --
mirrored no
inherit  flat Actor; RS_FireSGguy is a flat Actor (RS_ShotgunnerFX.zs:365)
profile  MakeVolley(proj:"RS_FireSGguy", count:5, arc:26,
                    fireSnd:"SSGUNER/SSG", profName:"sg_t07_flamefan")
notes    The angles are ASYMMETRIC (0,+8,+13,-13,-8) -- the fan leans
         right of centre by one bolt. Verbatim from CH:731-735.
         +THRUACTORS: these pass through other monsters and only stop on
         geometry or the player, so the fan does not get eaten by a crowd.
         The multi-frame A_Explode is DELIBERATE lingering fire (see
         CLAUDE.md / the multi-frame-A_Explode note): do not convert it
         to a single call.
         Pain sets `bNOPAIN = true` permanently (line 809) -- hurt it
         once and it never flinches again for the rest of its life.
```

---

## RS_GraySG2 — tier 8 (the sniper)

```
ATTACK   RS_GraySG2.Fire1
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:532
shape    HITSCAN
payload  BulletPuff x random(1,2)   (pufftype omitted -> engine default)
arc      random(-1,1) horizontal / 0 vertical   -- see notes
timing   8-tic face -> fire on an 8-tic frame. 16 tics, no recovery state.
damage   random(1,9)   per pellet
type     --
sound    AttackSound "SNPRFIRE"
impact   vanilla BulletPuff
trigger  Missile   (via A_JumpIfCloser(800) from Missile)
range    ..800
mirrored no
inherit  ShotgunGuy
profile  MakeHitscan(fireSnd:"SNPRFIRE", profName:"sg_t08_closeshot");
         p.PelletOverride = 1; p.SpreadBonus = 1; p.MaxRange = 800;
notes    THE SPREAD IS ITSELF A ROLL, AND IT CAN BE NEGATIVE:
         `A_CustomBulletAttack(random(-1,1),0,...)`. Whatever the engine
         does with a negative spread_xy, the magnitude never exceeds 1
         degree, so this is a near-perfect shot either way. Recorded as
         written; do NOT normalise it to `1`. CH:417 identical.
         Range parameter is OMITTED, so this is the engine default
         (MISSILERANGE), not an extended reach.
         DISCREPANCY vs CATALOG.md entry 16, which asserts
         `A_CustomBulletAttack(1, 0, 1, random(5,20), BulletPuff, 16000)`.
         Neither the damage, the pellet count, nor the 16000 range appear
         in our tree OR in CH. Our tree wins.
```

```
ATTACK   RS_GraySG2.Fire2
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:553  (the shot)
         zscript/monsters/shotgunner/RS_Shotgunner.zs:546  (first laser sweep)
         zscript/monsters/shotgunner/RS_Shotgunner.zs:534  (GetReady, the dig-in)
shape    HITSCAN
payload  BulletPuff x1
arc      0 / 0   -- PERFECT ACCURACY, no spread at all
timing   THE TELEGRAPH IS THE ATTACK: 6 face / 6 laser / 5 face / 5 laser /
         4 face / 4 laser / 3 face / 3 laser -> fire on a 6-tic frame ->
         2 face -> 24 idle -> 2-tic A_MonsterRefire(180). 70 tics/cycle,
         of which 36 are a visible red laser walking onto you.
damage   random(5,20)   -- the family's hardest single bullet
type     --
sound    AttackSound "SNPRFIRE". The four laser sweeps are RGF_SILENT.
impact   the SHOT: vanilla BulletPuff.
         the LASERS: RS_RedDotSGPuff (RS_ShotgunnerFX.zs:429) -- a
         +PAINLESS +NOBLOOD red-translated PUFF A 6. DAMAGE 0. It is a
         sight, not a weapon.
trigger  Missile   (via A_Jump(255)->GetReady->A_JumpIf(user_ready>=1)->Fire2)
range    800..
mirrored no
inherit  ShotgunGuy
profile  MakeHitscan(fireSnd:"SNPRFIRE", profName:"sg_t08_sniper");
         p.PelletOverride = 1; p.SpreadBonus = 0; p.MinRange = 800;
notes    THE DIG-IN IS PERMANENT AND ONE-WAY. GetReady (line 534) runs
         ONCE -- it squashes the sprite over three steps
         (1.0,0.7 -> 1.25,0.5 -> 1.5,0.3), drops Speed to 2, sets
         `bNOPAIN = true`, and increments `user_ready`. NOTHING EVER
         RESETS ANY OF IT. From then on Missile goes straight to Fire2.
         The monster has become a turret for the rest of its life.
         Four A_CustomRailgun calls with damage 0, duration 15,
         sparsity 0.5, driftspeed 0.5, spawnofs_z -12. Purely a laser
         sight; the damage comes from the A_CustomBulletAttack after them.
         DISCREPANCY vs CATALOG.md entry 17, which omits the laser sweeps
         entirely and gives a 16000 range that is in neither tree.
```

---

## RS_AbyssSG2 — tier 9

```
ATTACK   RS_AbyssSG2.Missile
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:665
shape    BURST
payload  RS_AbyssZShotCH2 x3
arc      4 jitter   (angle random(-2,2), rolled independently per shot)
timing   3 frames x 2 tics -- the action fires once PER FRAME, so three
         bolts 2 tics apart. 6 tics of fire after a 5-tic face; 1+1 tics
         of approach checks before. 13 tics.
damage   DamageFunction (random(5,30))   per bolt, inherited
type     Ice   (inherited)
sound    SeeSound "imp/attack" (on the projectile); AttackSound "asgguy/asgfir"
impact   BAL7 CDE 4 Bright with A_Explode(random(1,8),42) on all THREE
         frames. DeathSound "imp/shotx". BOTH INHERITED from
         RS_AbyssZShotCH (RS_Zombieman.zs:763) -- nothing about the impact
         is written near this attack or in this file.
trigger  Missile   (taken when A_JumpIfCloser(800) fails)
range    800..
mirrored no
inherit  RS_AbyssZShotCH2 : RS_AbyssZShotCH. The child overrides ONLY
         Radius/Height/Speed/XScale/YScale -- damage, type, sounds,
         translation, +DONTHARMCLASS, the A_Weave flight and the entire
         Death state come from the parent, in a different file.
profile  MakeBurst(proj:"RS_AbyssZShotCH2", count:3, delayTics:2, arc:4,
                   fireSnd:"asgguy/asgfir", profName:"sg_t09_abyssbolt");
         p.MinRange = 800;
notes    Classified BURST (3 rounds, 2 tics apart) rather than SCATTER,
         because the timing is the attack's identity and the +/-2 degree
         jitter is noise. Both facts are in the row.
         The bolt weaves in flight (A_Weave(2,1,2,0.1)) and drops a
         RS_AbyssShotIdentifier marker every other frame -- the marker is
         cosmetic/telegraph, not damage.
```

```
ATTACK   RS_AbyssSG2.Jumper (beat 1 of 3 -- the volley)
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:669
shape    HITSCAN
payload  RS_SplashAbyss2 x random(2,4)   (as the PUFF class -- see notes)
arc      6 horizontal / 7 vertical
timing   5-tic face -> fire on a 5-tic frame. Runs THREE TIMES per Jumper
         entry, at lines 669, 677 and 685.
damage   1  on pass 1;  2  on passes 2 and 3
type     --  on the bullet; the puff carries DamageType "Ice"
sound    AttackSound "asgguy/asgfir"
impact   RS_SplashAbyss2 (RS_ZombiemanFX.zs:735) -- NOT a BulletPuff
         subclass. DamageFunction (random(1,9)), DamageType Ice, Speed 34,
         gravity ON, +MTHRUSPECIES +DONTHARMCLASS. THE PUFF IS A LIVE
         DAMAGING PROJECTILE. BAL7 C/CDE death. No sound.
trigger  Missile   (via A_JumpIfCloser(800) from Missile)
range    ..800
mirrored no
inherit  RS_SplashAbyss2 : RS_SplashAbyss -- the Spawn/Death states,
         translation and +RANDOMIZE come from the parent at
         RS_ZombiemanFX.zs:707, in the zombieman's file.
profile  MakeHitscan(fireSnd:"asgguy/asgfir",
                     impactPuff:"RS_SplashAbyss2", profName:"sg_t09_jumpshot");
         p.PelletOverride = 3; p.SpreadBonus = 6; p.MaxRange = 800;
notes    Written per-beat rather than as one row because the three beats
         of Jumper are three different SHAPES with three different
         profiles; they are one state chain and are cross-referenced here.
         The bullet damage of 1-2 is almost irrelevant -- the payload is
         the puff, which rolls random(1,9) on its own.
         Damage differs between pass 1 (damage 1) and passes 2-3
         (damage 2). CH:605/613/621 identical.
```

```
ATTACK   RS_AbyssSG2.Jumper (beat 2 of 3 -- the lob)
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:670
shape    SCATTER
payload  RS_SplashAbyss2 x8
arc      30   (angle random(-15,15)); pitch random(-25,-5) via CMF_OFFSETPITCH
timing   all 8 on ONE tic (eight 0-tic TNT1 frames). Runs three times per
         Jumper entry (lines 670, 678, 686).
damage   DamageFunction (random(1,9))   per droplet
type     Ice
sound    --   (the 0-tic frames play nothing; the volley's "asgguy/asgfir"
         on the preceding frame covers it)
impact   BAL7 C 1 A_SetScale(0.6) then BAL7 CDE 4 Bright. No explode,
         no sound. Inherited from RS_SplashAbyss.
trigger  Missile   (via A_JumpIfCloser(800))
range    ..800
mirrored no
inherit  RS_SplashAbyss2 : RS_SplashAbyss (RS_ZombiemanFX.zs:707/735)
profile  MakeVolley(proj:"RS_SplashAbyss2", count:8, arc:30,
                    pitchJitter:20, profName:"sg_t09_lob")
notes    CMF_OFFSETPITCH with a NEGATIVE pitch range: -25..-5 is UPWARD.
         These are lobbed over cover, not fired at you. Gravity is on
         (-NOGRAVITY inherited), so they arc and land -- this is the
         mortar half of the attack.
```

```
ATTACK   RS_AbyssSG2.Jumper (beat 3 of 3 -- the carpet)
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:672
shape    RAIN
payload  RS_SplashAbyss2 x45
arc      --  (not aimed: placed over a rectangle around the monster)
timing   all 45 on ONE tic (45 0-tic frames on one line). Runs TWICE per
         Jumper entry (lines 672 and 680) -- 90 droplets total. The third
         pass has no carpet.
damage   DamageFunction (random(1,9))   per droplet
type     Ice
sound    --
impact   BAL7 C/CDE, silent. Inherited.
trigger  Missile   (via A_JumpIfCloser(800))
range    ..800
mirrored no
inherit  RS_SplashAbyss2 : RS_SplashAbyss
profile  MakeRadial(radius:328, damage:5, profName:"sg_t09_carpet")
notes    A_SpawnItemEx, NOT A_CustomMissile -- placed, not fired.
         Footprint random(-128,328) x-forward by random(-178,178) lateral,
         height random(6,16), velocity z=2. That x-range is ASYMMETRIC:
         it reaches 328 units in FRONT and only 128 BEHIND. It carpets
         the ground you are standing on.
         Between beat 3 and the next volley the monster hops BACKWARD --
         ThrustThingZ(0,12,0,0) + ThrustThing(angle+180, 32) on pass 1,
         then angle-180 on pass 2. It fires, floods the floor, and
         retreats. Twice. The most spatially complex attack in the family.
         MakeRadial is the nearest factory and is NOT a good fit -- a
         radial pulse is instant and centred; this is 45 gravity-bound
         actors over an off-centre rectangle. See UNRESOLVED #5.
```

---

## RS_BlackSG3 — tier 10 (Shotgun Crew Commander)

```
ATTACK   RS_BlackSG3.Shotgunned
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1636
shape    HITSCAN
payload  RS_DetoPuffCG x random(3,9)
arc      random(1,12) horizontal / random(1,12) vertical -- THE SPREAD IS ROLLED
timing   three 4-tic faces -> fire on a 2-tic frame -> two 2-tic faces ->
         2-tic sight check. 22 tics.
damage   random(1,8)   per pellet, PLUS the puff's own A_Explode(random(2,6),42)
type     --  on the bullet; the puff carries DamageType "Fire"
sound    A_PlayWeaponSound("Weapons/ShotGF") on the frame before
impact   RS_DetoPuffCG (RS_ShotgunnerFX.zs:231) -- an EXPLODING puff, not
         a BulletPuff subclass. +ALWAYSPUFF +PUFFONACTORS, RenderStyle Add,
         SeeSound "weapons/firex4", MISL B/C then A_Explode(random(2,6),42).
         Every pellet that lands detonates.
trigger  Missile   (via A_JumpIfCloser(500) from Missile)
range    ..500
mirrored no
inherit  flat Actor
profile  MakeHitscan(fireSnd:"Weapons/ShotGF",
                     impactPuff:"RS_DetoPuffCG", profName:"sg_t10_detoburst");
         p.PelletOverride = 6; p.SpreadBonus = 6; p.MaxRange = 500;
notes    THE SPREAD ITSELF IS ROLLED, not just the damage: the same
         attack is a tight burst one time and a 12-degree wash the next.
         That is the row's whole character -- do not average it to 6.
         Branches to Nadetoss on A_Jump(64) (1-in-4) immediately after
         firing, and re-enters Missile if you are still within 450.
```

```
ATTACK   RS_BlackSG3.Summon
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1628
shape    UNCLASSIFIED
payload  RS_BlackSG2 x4   (live monsters, not projectiles)
arc      --   (placed at fixed offsets 0,-5 / 0,+5 / +5,-5 / -5,+5)
timing   three 3-tic map-wide callouts -> 9-tic face -> 0,1,1,1 tics of
         spawning. 22 tics.
damage   --
type     --
sound    "ZSpecOps/Sight" x3 at ATTN_NONE -- HEARD ACROSS THE WHOLE MAP,
         played on channel 7 volume 2. The summon announces itself.
impact   four RS_BlackSG2 troopers with SXF_SETMASTER, each of which runs
         its own five-stance brain (see the trooper's rows below)
trigger  Missile   (via A_Jump(255,"Summon","AirStrike","Snipe"), and NOT
         reachable from the A_Jump(128,"AirStrike","Snipe") line above it)
range    500..
mirrored no
inherit  flat Actor
profile  MakeSummon(summonCls:"RS_BlackSG2", count:4, cap:4, tierOffset:0,
                    fireSnd:"ZSpecOps/Sight", profName:"sg_t10_summon")
notes    shape UNCLASSIFIED because the closed vocabulary has no summon
         word -- while RS_AttackProfile HAS a summon mode. That mismatch
         is a real gap, flagged in UNRESOLVED #7; a word was NOT coined.
         Two more troopers are spawned in Spawn: (lines 1596-1597), so a
         fresh commander already has an escort of 2 before it ever
         summons. Species "BlackSG" + +THRUSPECIES + +DONTHARMSPECIES on
         both means the squad never infights or blocks itself.
         cap:4 above is a design choice for the player-side profile, NOT
         a fact about the monster -- the monster has NO cap and can
         summon 4 more every time the roll comes up.
```

```
ATTACK   RS_BlackSG3.Snipe
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1649
shape    VILE
payload  RS_DetoPuffCG2 x1   (spawned ON the target, no travel)
arc      --
timing   three 8-tic faces -> 1-tic sight check -> 5-tic map-wide callout
         -> 1-tic sight check -> 1-tic face -> fire on a 4-tic frame.
         36 tics, with TWO abort points.
damage   A_Explode(random(12,36),42) at the target's feet
type     Fire
sound    "ZSpecOps/Sight" at ATTN_NONE (map-wide) during the wind-up;
         A_PlayWeaponSound("Weapons/ShotGF") on the fire frame;
         SeeSound "weapons/firex4" on the payload
impact   MISL B/C 1 Bright then MISL D 4 A_Explode(random(12,36),42) then
         MISL D 4 A_Burst("RS_PufFCHBS") -- the burst sprays smoke pufflets
         (RS_PufFCHBS, RS_ShotgunnerFX.zs:785, DamageFunction (random(0,1)))
trigger  Missile   (via A_Jump(128 or 255) from Missile)
range    500..
mirrored no
inherit  flat Actor
profile  MakeRadial(radius:42, damage:24, fireSnd:"Weapons/ShotGF",
                    profName:"sg_t10_snipemark"); p.MinRange = 500;
notes    Delivered by A_VileTarget, not A_VileAttack -- same family
         (line of sight required, payload materialises AT the target,
         nothing travels), so VILE is the honest shape. Flagged in
         UNRESOLVED #4 alongside the railgun.
         TWO A_CheckSight("See") aborts inside the wind-up (lines 1644
         and 1646). Break line of sight during the map-wide callout and
         it does not land. That is the counterplay and it is the reason
         the callout is at ATTN_NONE.
```

```
ATTACK   RS_BlackSG3.AirStrike
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1653  (the marker)
         zscript/monsters/shotgunner/RS_Shotgunner.zs:1655  (the carrier)
shape    RAIN
payload  RS_CHBSTarget x1 (marker, harmless) + RS_AirStrikeCHBS x1
         (carrier) -> RS_MissileCHBS xN (the ordnance)
arc      --   (the carrier flies at the marker; the ordnance falls)
timing   two 6-tic faces -> 8-tic marker plant -> 5+5 tics -> 4-tic
         carrier launch -> 2 tics. 36 tics before the carrier even leaves.
damage   carrier RS_AirStrikeCHBS: DamageFunction (random(5,40));
         each RS_MissileCHBS: DamageFunction (random(10,50))
type     Fire  (both)
sound    marker: "prox/beep" x2 at ATTN_NONE while it sits -- the strike
         is audible map-wide before it lands.
         carrier SeeSound "caco/attack", DeathSound "fire/fire5";
         ordnance SeeSound "weapons/hominglaunch",
         DeathSound "weapons/homingexplode"
impact   carrier death: BBOM A-G with A_Explode(random(10,40),108) x2
         frames then A_Explode(random(10,45),108) x3 frames -- FIVE blasts.
         ordnance death: A_Explode(random(5,40),98) + A_Burst("RS_PufFCHBS")
         + DropItem "Shell", 12 (it drops ammo where it lands).
trigger  Missile   (via A_Jump(128 or 255) from Missile)
range    500..
mirrored no
inherit  all three payloads are flat Actors (RS_ShotgunnerFX.zs:718/754/807)
profile  MakeHeavy(proj:"RS_AirStrikeCHBS", fireSnd:"caco/attack",
                   spawnHeight:64, profName:"sg_t10_airstrike");
         p.MinRange = 500;
notes    TWO-STAGE, AND THE MARKER IS THE COUNTERPLAY. A_VileTarget plants
         RS_CHBSTarget ON YOU; the carrier is then fired at where the
         marker is. Move after the marker lands and the strike misses.
         The carrier is +CEILINGHUGGER +FLOAT +NOGRAVITY at Speed 28 and
         sprays RS_MissileCHBS continuously in flight -- 2 per 2-tic frame
         then 2 per 3-tic frame, LOOPING, scattered over
         random(-80,80) then random(-200,200). The ordnance count is
         UNBOUNDED and depends on flight time. That is why this row is
         RAIN and not SINGLE.
```

```
ATTACK   RS_BlackSG3.Nadetoss
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1661
shape    SINGLE
payload  RS_SGGasNade x1
arc      6   (angle random(-3,3)); pitch random(3,12) -- a LOB
timing   8-tic face -> 2-tic sound -> throw on a 4-tic frame. 14 tics.
damage   DamageFunction (random(20,75))  on direct contact
type     Fire  (the nade); Poison (the gas cloud it leaves)
sound    "fire/fire4" on the throw.
         The nade's OWN three sounds -- SeeSound "weapons/grenlf",
         DeathSound "weapons/grenlx", BounceSound "weapons/grbnce" --
         ARE UNDEFINED IN CH'S SNDINFO AND SILENT IN CH TOO. Recorded as
         a finding, not a defect. (CLAUDE.md: an unresolved sound name is
         completely inert -- no error, no warning, no log line.)
impact   A_Explode(random(20,50),128), then FOURTEEN RS_Gas14 clouds
         spawned over random(-180,180) / random(-220,220) / random(-280,280)
         (RS_ShotgunnerFX.zs:685-687). Each cloud
         (RS_ShotgunnerFX.zs:260) runs A_Explode(random(4,8),42) on EVERY
         FRAME of a LOOPING 8-frame Spawn state with a 180/256 exit roll,
         and again on all 7 frames of Death. DamageType Poison.
trigger  Missile   (via A_Jump(64) from Shotgunned)
range    ..500   (inherits Shotgunned's band -- it is a branch off it)
mirrored no
inherit  flat Actor
profile  MakeHeavy(proj:"RS_SGGasNade", fireSnd:"fire/fire4",
                   spawnHeight:48, profName:"sg_t10_gasnade");
         p.MaxRange = 500;
notes    THE PITCH ROLL IS AN ARC, NOT SPREAD. random(3,12) upward with
         Gravity 0.29 and BounceType "Doom" (BounceFactor default) means
         this is lobbed and BOUNCES -- cover does not stop it.
         The looping A_Explode on RS_Gas14 is DELIBERATE lingering gas
         (CLAUDE.md's multi-frame-A_Explode note names gas explicitly as
         one of the ~55 sites that must NOT be converted to a single call).
         The gas is the real attack; the nade is the delivery.
         The `SGRN` sprite CH names ships nowhere in CH -- the nade is
         invisible in flight in CH too, and its GRENADETRAIL smoke is the
         only visual. Our tree holds `HGRN` (a real grenade sprite) so
         nothing is invisible here; the divergence is deliberate and
         documented in the FX file header.
```

---

## RS_BlackSG2 — tier 10 troop (spec-ops)

```
ATTACK   RS_BlackSG2.AggressiveMissile / CreepMissile / BerserkMissile
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1818  (Aggressive)
         zscript/monsters/shotgunner/RS_Shotgunner.zs:1884  (Creep)
         zscript/monsters/shotgunner/RS_Shotgunner.zs:1901  (Berserk)
shape    HITSCAN
payload  RS_DetoPuffCG x7
arc      8 horizontal / 6 vertical
timing   Aggressive: 3x4-tic face -> fire on a 2-tic frame -> 3x2-tic face.
         Creep:      identical, no nade branch.
         Berserk:    2x4-tic face -> fire -> 3x2-tic face, then
                     A_Jump(192,"BerserkSee") and A_MonsterRefire(40) LOOP.
damage   4   (flat, per pellet) + the puff's A_Explode(random(2,6),42)
type     --  on the bullet; puff carries DamageType "Fire"
sound    A_PlayWeaponSound("Weapons/ShotGF")
impact   RS_DetoPuffCG -- exploding puff, same as the commander's
trigger  Missile   (never Goto'd -- see notes)
range    --   (Creep enters via A_Chase(..., 2) meleerange multiplier;
         Aggressive/Berserk have no band on the attack itself)
mirrored no
inherit  flat Actor
profile  MakeHitscan(fireSnd:"Weapons/ShotGF",
                     impactPuff:"RS_DetoPuffCG", profName:"sg_t10_troopshot");
         p.PelletOverride = 7; p.SpreadBonus = 8;
notes    ONE ROW, THREE ENTRY POINTS. All three states carry the IDENTICAL
         call `A_CustomBulletAttack(8,6,7,4,"RS_DetoPuffCG")`. What differs
         is the wrapper, and the wrapper is not the attack:
           * Aggressive -- A_Jump(64) into NadeToss after firing
           * Creep      -- no nade, +MISSILEMORE +AVOIDMELEE set on entry
           * Berserk    -- +MISSILEMORE +MISSILEEVENMORE +NOPAIN, and it
                           LOOPS on A_MonsterRefire(40) instead of leaving
         THESE STATES ARE NOT REACHABLE BY ANY Goto. They arrive as the
         second argument to A_Chase -- e.g. `A_Chase(null,"AggressiveMissile")`
         at line 1759. A label scan or a Goto scan finds none of them.
         Sprint and Wander stances have NO missile state at all: a
         sprinting or wandering trooper is unarmed until it re-rolls.
         The stance is re-rolled on EVERY See re-entry by
         RS_ZSpecOpsSGSitRep (RS_ShotgunnerFX.zs:1261), off health<50,
         line of sight, and range 384/768. Every leaf is a 2- or 3-way
         coin flip, so two troopers in the same situation diverge.
```

```
ATTACK   RS_BlackSG2.NadeToss
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:1825
shape    SINGLE
payload  RS_SGGasNade x1
arc      6   (angle random(-3,3)); pitch random(3,12)
timing   8-tic face -> 2-tic sound -> throw on a 4-tic frame. 14 tics.
damage   DamageFunction (random(20,75))
type     Fire (nade) / Poison (cloud)
sound    "fire/fire4"; the nade's own three sounds are undefined in CH
impact   identical to the commander's -- A_Explode(random(20,50),128)
         plus 14 RS_Gas14 poison clouds
trigger  Missile   (via A_Jump(64) from AggressiveMissile ONLY -- Creep
         and Berserk never reach it)
range    --
mirrored no
inherit  flat Actor
profile  MakeHeavy(proj:"RS_SGGasNade", fireSnd:"fire/fire4",
                   spawnHeight:48, profName:"sg_t10_gasnade")
notes    Byte-identical to RS_BlackSG3.Nadetoss (same class, same six
         arguments). Given its own row because it is a DIFFERENT
         monster's attack with a different gate -- one row per monster is
         what makes the family table composable. If the composer
         de-duplicates by payload, these two collapse to one profile and
         nothing is lost.
```

---

## RS_BrownSG2 — tier 13 (muddy guy)

```
ATTACK   RS_BrownSG2.GetCloser
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:268
shape    CHARGE
payload  --  (the monster IS the projectile)
arc      --
timing   0-tic sound -> 3-tic launch. Then 6+6+6 tics of dirt-throwing
         recovery, a 2-tic A_Stop, an LOS re-check, and A_SetSpeed(9).
damage   --  (engine contact roll; no Damage set on RS_BrownSG2)
type     --
sound    "gas/gas1"
impact   contact. Throws RS_Drt3/RS_Drt2/RS_Drt1 (Damage 0, cosmetic dirt)
         through the whole recovery -- 4 clods, none of them harmful.
trigger  Missile   (via A_Jump(255) after BOTH range gates fail)
range    1200..   (or 700..1200 with no line of sight -- see the Fire1 row)
mirrored no
inherit  ShotgunGuy
profile  MakeMelee(range:64, fireSnd:"gas/gas1", profName:"sg_t13_mudrush");
         p.MinRange = 1200;
notes    A_SkullAttack(28) -- MORE THAN TWICE the Purple's 12. This is the
         fastest charge in the family. CH:94 identical.
         RS_Drt1/2/3 are Damage 0 (RS_ShotgunnerFX.zs:181,
         RS_ZombiemanFX.zs:623/651): dirt, not shrapnel. Not payloads.
         The same dirt is thrown while merely walking (See:, lines 254/257).
```

```
ATTACK   RS_BrownSG2.Fire1
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:284
shape    MULTI
payload  RS_BrownSGshot x20  +  BulletPuff x random(7,17) (hitscan)
arc      30   (angle random(-15,15) on every pellet);
         pitch band 1 random(-9,1), pitch band 2 random(-1,9)
timing   10-tic face -> 4-tic flash -> 20 pellets on TWO 0-tic lines (all
         on one tic) -> hitscan on the next 1-tic frame -> 4-tic flash ->
         2-tic face. 21 tics.
damage   pellets: DamageFunction (random(1,5)) each
         hitscan: random(1,3) per bullet, random(7,17) bullets
type     --  (both untyped)
sound    A_PlaySound("SSGUNER/SSG") AFTER the hitscan, not before it --
         the report lands one frame late. AttackSound "SSGUNER/SSG".
impact   pellets: A_Stop, PUFF C 6 Bright, then
         A_Blast(BF_NOIMPACTDAMAGE, 128, 32, 20.0) -- IT SHOVES YOU
         WITHOUT DAMAGING YOU -- then PUFF DD 6. DeathSound "imp/shotx".
         hitscan: vanilla BulletPuff.
trigger  Missile   (via A_JumpIfCloser(400) OR
         A_JumpIfInTargetLOS(1200,700) with JLOSF_DEADNOJUMP|JLOSF_CLOSENOSIGHT)
range    ..1200  (unconditional under 700; 700..1200 requires line of sight)
mirrored no
inherit  ShotgunGuy; RS_BrownSGshot is a flat Actor (RS_ShotgunnerFX.zs:399)
profile  MakeVolley(proj:"RS_BrownSGshot", count:20, arc:30, pitchJitter:10,
                    fireSnd:"SSGUNER/SSG", profName:"sg_t13_mudspray")
         + MakeHitscan(profName:"sg_t13_mudshot"); p.PelletOverride = 12;
notes    MULTI because it fires two genuinely different payload classes
         on consecutive tics: 20 travelling RS_BrownSGshot AND a
         random(7,17)-pellet instant hitscan. Neither alone is the attack.
         TWO OPPOSITE PITCH BANDS, BACK TO BACK: random(-9,1) then
         random(-1,9). The cloud is TALL rather than wide -- ducking does
         not help, strafing does.
         A_Blast on the pellet impact is the row's real character. The
         pellets barely hurt (1-5) but they PUSH, at strength 20.0 over a
         128-unit radius. Twenty of them arriving together is a shove out
         of cover, and the hitscan is what actually kills.
         DISCREPANCY vs CATALOG.md entry 14, which gives the gate as
         "closer than 500" and omits the hitscan entirely. Our tree's
         gate is 400 + an LOS band to 1200, and the hitscan is at
         line 286. CH:87/112 agree with our tree.
```

---

## RS_CyanSG2 — tier 12 (ice trooper)

```
ATTACK   RS_CyanSG2.Missile
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:412
shape    HITSCAN
payload  RS_CyanSGPuff x6 across five calls
arc      four EXACT corners at (+4,+4) (-4,-4) (+4,-4) (-4,+4)
         plus one true random spread of 5 / 5
timing   all five calls on 0-tic frames -- ONE TIC. 3x4-tic face before,
         2-tic flash + 2x2-tic face + 2-tic sight check after. 22 tics.
damage   random(1,5) / random(1,4) / random(1,2) x2 bullets /
         random(1,4) / random(1,5)
type     --  on the bullets; the puff plays "Ice/Hit2"
sound    A_PlayWeaponSound("Weapons/ShotGF") on the frame before
impact   RS_CyanSGPuff (RS_ShotgunnerFX.zs:450) -- a BulletPuff SUBCLASS,
         i.e. an IMPACT PUFF, NOT A PAYLOAD. DeathSound "Ice/Hit2" plus
         three cyan A_SpawnParticle sprays. Carries no damage of its own.
trigger  Missile   (taken when A_Jump(128,"Proj") fails -- a true coin flip)
range    --   (but RANGE 8000 on four of the five calls, see notes)
mirrored no
inherit  flat Actor (does NOT inherit ShotgunGuy)
profile  MakeHitscan(fireSnd:"Weapons/ShotGF",
                     impactPuff:"RS_CyanSGPuff", profName:"sg_t12_frostcross");
         p.PelletOverride = 6; p.SpreadBonus = 4;
notes    FOUR OF THE FIVE CALLS SET CBAF_EXPLICITANGLE. With that flag the
         spread arguments stop being a random cone and become EXACT angle
         offsets -- so (4,4) is precisely +4 horizontal, +4 vertical, every
         time. The four form a fixed X: upper-right, lower-left,
         lower-right, upper-left.
         THE MIDDLE CALL IS DIFFERENT AND IT IS EASY TO MISS:
         `A_CustomBulletAttack(5,5,2,random(1,2),"RS_CyanSGPuff")` has
         NEITHER the flag NOR the range -- it is 2 bullets of genuine
         random 5/5 spread at the engine default range, down the centre.
         So the pattern is a fixed cross plus a scattered pair.
         RANGE 8000 on the four cross bullets is roughly FOUR TIMES the
         engine default. This tier shoots across any map.
         Ends A_CheckSight("See") then A_Jump(102,"Missile") -- ~40% to
         re-engage immediately rather than resetting.
```

```
ATTACK   RS_CyanSG2.Proj
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:423
shape    MULTI
payload  RS_IceZombieShot2 x5  +  RS_CyanSGPuff x1 (hitscan)
arc      10 on the shots (angle random(-5,5)), pitch random(-2,2);
         the hitscan is an EXACT (-2,+2) via CBAF_EXPLICITANGLE
timing   all 5 shots on ONE tic (five 0-tic frames), hitscan on the next
         0-tic frame -- effectively simultaneous. Same 3x4-tic face
         before and 2+2+2+2 recovery after. 22 tics.
damage   shots: DamageFunction (random(4,14)) each -- INHERITED
         hitscan: random(1,6), 1 bullet
type     Ice (the shots)
sound    A_PlayWeaponSound("Weapons/ShotGF") on the frame before
impact   shots: ICEY FGHI 5 Bright; SeeSound "Ice/Hit2";
         DeathSound "spike/spiked" -- UNDEFINED IN CH'S OWN SNDINFO,
         silent there too. BOTH INHERITED from RS_IceZombieShot
         (RS_Zombieman.zs:369), a different file.
         hitscan: RS_CyanSGPuff, an impact puff.
trigger  Missile   (via A_Jump(128,"Proj") -- a true 50/50 against the row above)
range    --   (range 8000 on the hitscan)
mirrored no
inherit  RS_IceZombieShot2 : RS_IceZombieShot -- the child overrides only
         Radius/XScale/YScale/Speed/DamageFunction. Sprites, sounds,
         RenderStyle and both states come from the parent.
profile  MakeVolley(proj:"RS_IceZombieShot2", count:5, arc:10,
                    pitchJitter:4, fireSnd:"Weapons/ShotGF",
                    profName:"sg_t12_iceshots")
notes    MULTI: five travelling ice shards AND one instant hitscan, two
         different payload classes on the same tic.
         The shards are stretched flat -- XScale 0.95 / YScale 0.1 -- so
         they read as horizontal slivers, not balls. NON-UNIFORM SCALE:
         see CLAUDE.md; this is a `Default` XScale/YScale pair, which is
         legal, unlike a `Scale.X`/`Scale.Y` pair.
NOT A ROW  RS_CyanSG2.Jumpy (line 397) and .Jump (line 446) fire NOTHING.
         They are pure displacement: ThrustThingZ(0,48) +
         ThrustThing(angle - randompick(130,180,230), 12), then a second
         smaller hop forward. Entered from See on a 232/256 roll gated by
         A_JumpIfInTargetLOS(750,300), and from Pain on a 96/256 roll.
         Excluded per the spec ("an attack is any state chain ... that
         FIRES something"). Recorded here because CATALOG.md entry 7
         lists it as an attack and a composer may expect it.
         Jumpy is cvar-gated: `rs_ch_cyanbounce == 1` diverts to See2 and
         suppresses the hop entirely (line 399).
```

---

## RS_WhiteSG2 — tier 11 (BENELLUS, GOD OF SHOTGUNS)

```
ATTACK   RS_WhiteSG2.SG
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:2047
shape    HITSCAN
payload  BulletPuff -- 17 SEPARATE VOLLEYS per cycle, see timing
arc      random(5,180) horizontal / random(0,50) vertical on 15 volleys;
         22.5 / 0 on the other 2
timing   2-tic face -> 3x7-tic cocking callout -> SEVEN volleys on
         `BENE KBJCGDF 6` (7 frames x 6 tics, action fires ONCE PER FRAME)
         -> 2 sight/range aborts -> TWO tight volleys on `BENE KB 2`
         -> EIGHT more wild volleys on `BENE EAHBICLD 6` -> 1-tic
         A_MonsterRefire(128) -> Goto SG. 42+4+48 = 94 tics of firing
         per cycle, and it loops.
damage   wild volleys: random(1,3) per pellet, random(5,30) pellets
         tight volleys: random(1,5) per pellet, random(5,18) pellets
type     --
sound    "DSSGCOCK" x3 at ATTN_NONE (map-wide) as the wind-up;
         AttackSound "shotguy/attack"
impact   vanilla BulletPuff
trigger  Missile   (via A_Jump(256,"SG","Gifts","Punisher") -- even 3-way)
range    ..1250   (A_CheckRange(1250,"See") aborts mid-attack past that)
mirrored no
inherit  flat Actor
profile  MakeHitscan(fireSnd:"DSSGCOCK", profName:"sg_t11_godshotgun");
         p.PelletOverride = 17; p.SpreadBonus = 90; p.MaxRange = 1250;
notes    `random(5,180)` IS A HORIZONTAL SPREAD OF UP TO 180 DEGREES.
         At the top of that roll the pellets go in EVERY direction,
         including behind it. This is not a typo and not a mis-read --
         CH:2451 and :2455 are identical. It is why the attack works at
         all as a 15-volley sustained burst: most of it misses by design,
         and the two `BENE KB` volleys at a tight 22.5 are the ones that
         actually aim.
         MULTI-FRAME ACTION: `BENE KBJCGDF 6` is SEVEN frames, and
         A_CustomBulletAttack runs once per frame -- seven volleys, not
         one. Same for `BENE EAHBICLD 6` (eight) and `BENE KB 2` (two).
         Reading these as single calls undercounts the attack by 15x.
         A_CheckSight and A_CheckRange(1250) sit BETWEEN the wild burst
         and the tight one, so breaking LOS mid-attack cancels the
         accurate half.
```

```
ATTACK   RS_WhiteSG2.Gifts
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:2037
shape    SCATTER
payload  RS_MineShotgun x4
arc      40   (angle random(-20,20)); lateral offset random(-15,15);
         spawn height random(20,60)
timing   8-tic callout -> 8-tic callout -> four 1-tic frames, one mine
         each. 20 tics.
damage   DamageFunction (random(10,50))  on contact
type     Fire
sound    "DSDBLOAD" then "DSDBCLS", both at ATTN_NONE (map-wide)
impact   MISL BCD 5 Bright with A_Explode(random(5,50),128) on ALL THREE
         frames -- three blasts at radius 128 per mine.
         SeeSound and BounceSound "weapons/sshotl";
         DeathSound "weapons/rockx" is UNDEFINED IN CH'S SNDINFO and
         silent there too.
trigger  Missile   (via A_Jump(256, 3-way))
range    --
mirrored no
inherit  flat Actor; RS_MineShotgun is a flat Actor (RS_ShotgunnerFX.zs:841)
profile  MakeBurst(proj:"RS_MineShotgun", count:4, delayTics:1, arc:40,
                   fireSnd:"DSDBLOAD", profName:"sg_t11_mines")
notes    AREA DENIAL, NOT AIMED DAMAGE. BounceCount 11, BounceFactor 0.75,
         WallBounceFactor 1.2 (>1 -- walls ADD energy), Gravity 0.9, and
         a 6/256 self-detonate roll plus a 32/256 re-thrust roll on every
         2-tic Spawn frame. These mines wander the room for a long time.
         The two map-wide sounds are the tell: you hear the gift before
         you see it.
```

```
ATTACK   RS_WhiteSG2.Punisher
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:2042
shape    VILE
payload  RS_Shotgunpunishernerfed x1 -> RS_ShotgunPunishnerf +
         RS_ShotgunPunishnerf2 (a mirrored PAIR of emplacements)
arc      --   (placed at the target's position, +128 and -128 lateral)
timing   10-tic map-wide callout -> 8 tics -> 2-tic cast. 20 tics.
         The emplacements then take 36 tics to inflate before firing.
damage   -- (the cast itself); see the emplacement's own row below
type     --
sound    "DSDSHTGN" at ATTN_NONE (map-wide)
impact   two 300hp `Monster;` +NOCLIP emplacements, one on each side of
         you, each of which racks and fires once and then self-destructs
         with A_Explode(random(5,15),64)
trigger  Missile   (via A_Jump(256, 3-way))
range    --
mirrored no   (the PAIR is mirrored -- see the emplacement row)
inherit  flat Actor
profile  MakeSummon(summonCls:"RS_ShotgunPunishnerf", count:2, cap:2,
                    tierOffset:0, fireSnd:"DSDSHTGN",
                    profName:"sg_t11_punisher")
notes    VILE by delivery (A_VileTarget: line of sight, materialises at
         the target, nothing travels) but a SUMMON by outcome -- the
         shape vocabulary cannot say both. Flagged in UNRESOLVED #4/#7.
         "nerfed" is CH's own word and it is accurate: this pair rolls
         random(1,7) pellets for random(1,5) each, where the EX form's
         un-nerfed pair (RS_ShotgunPunish, on RS_WhiteSGEX) rolls
         random(3,10) for random(1,6). Same class shape, weaker numbers.
         RS_Shotgunpunishernerfed is a 1-tic +NOCLIP carrier that spawns
         the pair with SXF_TRANSFERPOINTERS (so they inherit YOU as
         target) and then A_Die. It is plumbing, not a payload.
```

```
ATTACK   RS_WhiteSG2.Death
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:2057
shape    SCATTER
payload  RS_HKRedDeath x9
arc      --   (see notes -- the argument in the angle slot is a constant)
timing   6x1-tic A_Scream -> 8-tic A_Fall -> `BENE AAABCDDDD 6` = NINE
         frames x 6 tics, one barrel per frame. 54 tics of detonations.
damage   A_Explode(random(5,10),42) per barrel
type     Fire
sound    "world/barrelx" twice per barrel; DeathSound "world/barrelx"
impact   MISL B 8 A_Explode(random(5,10),42) -> MISL C 6 sound ->
         MISL D 3 A_Burst("RS_RedThingsHK")
trigger  Death
range    --
mirrored no
inherit  RS_HKRedDeath is a flat Actor at RS_ZombiemanFX.zs:844 -- in the
         ZOMBIEMAN's file. Nothing about this payload is in either
         shotgunner file.
profile  MakeBurst(proj:"RS_HKRedDeath", count:9, delayTics:6,
                   trigger:RS_FIRE_DEATH, profName:"sg_t11_deathburst")
notes    THE ARGUMENTS ARE SHIFTED AND THAT IS CH'S, NOT OURS.
         `A_CustomMissile("RS_HKRedDeath", random(0,80), random(-30,50),
         CMF_AIMOFFSET, 2, -10)` -- A_CustomMissile's 4th parameter is
         ANGLE and its 5th is FLAGS, so the named flag constant
         CMF_AIMOFFSET lands in the ANGLE slot and a bare literal `2`
         lands in flags. CH:2461 is byte-identical. Whether CH meant it
         is unknowable; it is recorded verbatim and MUST NOT be "fixed"
         on the strength of this document. `arc` is left as `--` because
         asserting a degree value would require asserting the enum's
         numeric value, which could not be verified (UNRESOLVED #3).
         Also on Death, and NOT a row: 40 `Shotgun` pickups scattered
         over +/-80 in every axis, a Radius_Quake(40,60,0,40,0), and
         RS_CH_Cactus. Loot and spectacle, no damage.
```

---

## RS_WhiteSGEX — tier 11 EX (BENELLUS, ANGRIER)

```
ATTACK   RS_WhiteSGEX.SG
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:2292
shape    HITSCAN
payload  BulletPuff -- 17 volleys per cycle
arc      random(5,180) / random(0,50) on 15 volleys; 22.5 / 0 on 2
timing   2-tic face -> SEVEN volleys on `BENE KBJCGDF 4` -> aborts ->
         TWO on `BENE KB 2` -> EIGHT on `BENE EAHBICLD 4` -> 1-tic
         A_MonsterRefire(128) -> Goto SG. 28+4+32 = 64 tics per cycle.
damage   wild: random(1,3) x random(5,30); tight: random(1,5) x random(5,18)
type     --
sound    AttackSound "shotguy/attack". NO "DSSGCOCK" WIND-UP -- the EX
         form drops the 21-tic cocking callout the base form has.
impact   vanilla BulletPuff
trigger  Missile   (via A_JumpIfCloser(1500) -> OtherM -> A_Jump(256, 4-way))
range    ..1500 to enter OtherM;  ..1250 to sustain (A_CheckRange abort)
mirrored no
inherit  flat Actor
profile  MakeHitscan(fireSnd:"shotguy/attack", profName:"sg_t11ex_godshotgun");
         p.PelletOverride = 17; p.SpreadBonus = 90; p.MaxRange = 1250;
notes    IDENTICAL TO RS_WhiteSG2.SG IN EVERY ARGUMENT. The only
         differences are the frame durations (4 tics vs 6) and the
         missing wind-up -- so the EX form fires the same 17 volleys
         ~32% faster and with no telegraph. That is the whole "angrier".
         CH:2761-2766 vs CH:2451-2456 confirm both.
```

```
ATTACK   RS_WhiteSGEX.Gifts
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:2288
shape    SCATTER
payload  RS_MineShotgun x4
arc      40   (angle random(-20,20))
timing   four 1-tic frames. 4 TICS TOTAL -- no callout at all.
damage   DamageFunction (random(10,50))
type     Fire
sound    --   THE EX FORM'S MINE THROW IS COMPLETELY SILENT. The base
         form's two map-wide "DSDBLOAD"/"DSDBCLS" callouts are gone.
         This is a FINDING, not a blank: on a monster it is a stealth
         buff; as a profile slot it is correct, because the gun's own
         sound fills it.
impact   3 x A_Explode(random(5,50),128); bouncing, 11 bounces
trigger  Missile   (via OtherM's 4-way jump; NEVER from the far branch)
range    ..1500
mirrored no
inherit  flat Actor
profile  MakeBurst(proj:"RS_MineShotgun", count:4, delayTics:1, arc:40,
                   profName:"sg_t11ex_mines"); p.MaxRange = 1500;
notes    Same four mines as the base form, dropped from 20 tics to 4 and
         from two map-wide announcements to silence. CH:2757 has no sound
         lines either.
```

```
ATTACK   RS_WhiteSGEX.FocusedHitScan
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:2197
shape    HITSCAN
payload  BulletPuff x random(3,12) per volley, SEVEN volleys
arc      2 horizontal / 2 vertical -- TIGHT, and fixed, not rolled
timing   1-tic face -> 5 cosmetic sparks -> 6 more on 1-tic frames ->
         8-tic face -> SEVEN volleys on `BENE KBJCGDF 5` (7 frames x 5
         tics, one volley per frame) -> `BENE KD 3` recover. 35 tics of
         fire.
damage   random(1,6)   per pellet
type     --
sound    --   NO SOUND ON THE ATTACK AT ALL. AttackSound
         "shotguy/attack" is set on the actor but nothing plays it in
         this state, and no A_PlaySound appears. Silent aimed fire.
impact   vanilla BulletPuff
trigger  Missile   (A_Jump(128) when A_JumpIfCloser(1500) FAILS -- this is
         the LONG-range branch)
range    1500..
mirrored no
inherit  flat Actor
profile  MakeHitscan(profName:"sg_t11ex_focused"); p.PelletOverride = 7;
         p.SpreadBonus = 2; p.MinRange = 1500;
notes    THE OPPOSITE OF THE SG ROW. Where SG rolls a 5..180 degree
         spread and mostly misses, this is a fixed 2-degree cone --
         essentially a rifle. It is the FAR branch, so distance is not an
         answer to this tier; backing off swaps a wild spray for an
         accurate one.
         The RS_SparkPuff1 spawns around it are COSMETIC: +NOINTERACTION,
         no Projectile, no Damage (RS_ShotgunnerFX.zs:209). They are not
         payloads and are not counted.
         DISCREPANCY vs CATALOG.md entry 29, which gives this an
         8000-unit range and an A_Jump(170) gate. Neither appears in our
         tree; the gate is A_Jump(128) and no range argument is passed.
         CH:2637-2638 and :2658 agree with our tree.
```

```
ATTACK   RS_WhiteSGEX.FocusedFire
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:2247  (first of 32 lines)
shape    SCATTER
payload  RS_SparkFireBen x224
arc      2 to 24, varying line by line: random(-1,1), random(-5,5),
         random(-8,8), random(-12,12) -- four cone widths interleaved
timing   6 cosmetic sparks + 44 shield orbs on 0-tic frames -> 6-tic face
         -> 56 shots (8 lines x 7 frames x 1 tic) -> 6-tic face -> 56 ->
         8-tic face -> 56 -> 8-tic face -> 56 -> 10-tic tail.
         ~262 TICS. SEVEN AND A HALF SECONDS OF CONTINUOUS FIRE.
damage   DamageFunction (random(6,12))   per spark
type     --
sound    --   silent on the attack; DeathSound "imp/shotx" per spark
impact   12 x RS_SparkPuff1 sprayed on a 0-tic frame at each spark's
         death (RS_ShotgunnerFX.zs:949). Cosmetic -- the sparks
         themselves are the damage.
trigger  Missile   (via A_JumpIfCloser(1500) -> OtherM -> A_Jump(256, 4-way))
range    ..1500
mirrored no
inherit  flat Actor; RS_SparkFireBen is a flat Actor (RS_ShotgunnerFX.zs:927)
profile  MakeBurst(proj:"RS_SparkFireBen", count:224, delayTics:1, arc:24,
                   pitchJitter:18, profName:"sg_t11ex_sparkstorm");
         p.MaxRange = 1500;
notes    THE LARGEST ATTACK IN THE FAMILY BY AN ORDER OF MAGNITUDE, and
         it is invisible to any per-line count: 32 source lines, each
         `BENE KBJCGDF 1` = SEVEN frames, and A_CustomMissile fires once
         per frame. 32 x 7 = 224 projectiles. A line count says 32.
         The pitch handling varies line to line between CMF_ABSOLUTEPITCH,
         CMF_AIMOFFSET and no flag at all, with ranges from random(-9,9)
         to random(1,5). Transcribed verbatim from CH:2708-2742; the
         variety is deliberate churn, not a pattern worth reducing.
         The 44 RS_SparkShieldBen spawned first (lines 2202-2245) are
         COSMETIC: +NOINTERACTION, no Projectile, no Damage
         (RS_ShotgunnerFX.zs:905). They form a visual cage at +/-62 and
         +/-75 units. Not armour, not payloads -- they do nothing but
         render for 80 tics and fade.
         Speed 55 / FastSpeed 80 and +MTHRUSPECIES: the sparks pass
         through its own kind, so a Benellus in a crowd still hits you.
```

```
ATTACK   RS_WhiteSGEX.ShotgunRounded / .Shrines
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:2183  (Punisher branch)
         zscript/monsters/shotgunner/RS_Shotgunner.zs:2188  (Shrines branch)
shape    VILE
payload  RS_Shotgunpunisher -> 2x RS_ShotgunPunish  (192/256 of the time)
         RS_Shotgunpunisher2 -> 2x RS_ShotgunShrine (64/256 of the time)
         PLUS 2x RS_ShotgunShrine placed directly, on BOTH branches
arc      --   (placed: +/-128 lateral on the punisher pair; the direct
         shrines at random(-128,128) forward by random(-1,178) and
         random(-178,1) lateral -- one on each side of you)
timing   4x2-tic pose -> 20 cosmetic sparks on 1-tic frames -> 9 more on
         0-tic -> 2-tic branch roll -> 2-tic cast -> 3+3 tics of shrine
         placement. ~40 tics.
damage   --  (the cast); see the emplacement rows below
type     --
sound    --   silent cast. The emplacements carry SeeSound "weapons/sshotl".
impact   EITHER two 300hp one-shot punisher guns flanking you, OR two
         800hp shrine turrets -- and in BOTH cases two MORE shrines are
         planted behind you regardless of the roll
trigger  Missile   (the FALLTHROUGH branch: reached when
         A_JumpIfCloser(1500) fails AND A_Jump(128,"FocusedHitScan")
         fails; ALSO reachable inside 1500 via OtherM's 4-way jump)
range    --   (reachable at both bands -- the only attack here that is)
mirrored yes  (the punisher pair is one +X-scale and one -X-scale copy;
         the two direct shrines are placed on opposite lateral signs)
inherit  flat Actor
profile  MakeSummon(summonCls:"RS_ShotgunShrine", count:2, cap:4,
                    tierOffset:0, profName:"sg_t11ex_shrines")
notes    IT BUILDS THE ARENA WHILE IT FIGHTS. Two shrines go down BEHIND
         you, on both sides, on every pass, whichever way the A_Jump(64)
         lands. Over a long fight the room fills with turrets.
         The 20 + 9 RS_SparkPuff1 are COSMETIC (+NOINTERACTION, no
         damage). CATALOG.md entry 28 counts them as a "forty-spark
         barrage"; they cannot hurt anything.
         Note the naming trap: RS_Shotgunpunisher2 spawns SHRINES, not
         punishers. Only RS_Shotgunpunisher spawns RS_ShotgunPunish.
```

```
ATTACK   RS_WhiteSGEX.Pain
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:2165
shape    UNCLASSIFIED
payload  RS_ShotgunShrine x1   (a live 800hp turret)
arc      --   (placed at random(-128,128) x random(-128,128))
timing   2-tic Shell spawn -> 2-tic shrine spawn -> 2-tic A_Pain ->
         2-tic A_Jump(128,"Tele"). 8 tics.
damage   --  directly; the shrine then fires on its own
type     --
sound    PainSound "weapons/sshotf"
impact   an 800hp +NOCLIP +THRUSPECIES turret that immediately begins
         its own Missile -> Nuts loop (see the RS_ShotgunShrine row)
trigger  Pain
range    --
mirrored no
inherit  flat Actor
profile  MakeSummon(summonCls:"RS_ShotgunShrine", count:1, cap:4,
                    tierOffset:0, profName:"sg_t11ex_painshrine");
         p.FireTrigger = RS_FIRE_PAIN;
notes    HURTING IT IS HOW YOU BUILD ITS ARMY. One shrine per pain event,
         with PainChance 14 -- so roughly 1 in 18 hits plants a turret.
         It also drops a `Shell` pickup on the same beat, so the pain
         state gives you ammo and gives it a gun.
         shape UNCLASSIFIED for the same reason as RS_BlackSG3.Summon --
         no summon word exists in the closed set. UNRESOLVED #7.
         Also on Pain: A_Jump(128,"Tele") -> 4 tics of A_Wander. That is
         a displacement beat, fires nothing, and is not a row.
NOT A ROW  RS_WhiteSGEX.See (lines 2152/2154) fires 10 RS_SparkPuff1 per
         chase cycle. They are +NOINTERACTION cosmetics with no damage --
         an aura, not a Walk-trigger attack.
```

```
ATTACK   RS_WhiteSGEX.Death
file     zscript/monsters/shotgunner/RS_Shotgunner.zs:2302
shape    SCATTER
payload  RS_HKRedDeath x9
arc      --   (same shifted-argument caveat as RS_WhiteSG2.Death)
timing   nine 6-tic frames. 54 tics.
damage   A_Explode(random(5,10),42) per barrel
type     Fire
sound    "world/barrelx"
impact   MISL B/C/D chain, A_Burst("RS_RedThingsHK")
trigger  Death
range    --
mirrored no
inherit  RS_HKRedDeath at RS_ZombiemanFX.zs:844
profile  MakeBurst(proj:"RS_HKRedDeath", count:9, delayTics:6,
                   trigger:RS_FIRE_DEATH, profName:"sg_t11ex_deathburst")
notes    Byte-identical to RS_WhiteSG2.Death (CH:2771 vs CH:2461). Given
         its own row per the one-row-per-monster rule; collapses cleanly
         if the composer de-duplicates by payload.
```

---

## RS_ShotgunShrine — summoned turret (FX file)

`Monster;` with Health 800, +NOCLIP +NOTRIGGER +THRUSPECIES
+DONTHARMCLASS +DONTHARMSPECIES, Species "BENE". Summoned by
`RS_WhiteSGEX.ShotgunRounded`, `.Shrines` and `.Pain`, and by
`RS_Shotgunpunisher2`.

```
ATTACK   RS_ShotgunShrine.Nuts
file     zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:997
shape    BURST
payload  RS_SparkFireBen x8 per cycle
arc      6   (angle random(-3,3)); spawn height 84
timing   6-tic face -> 6-tic charge -> 1-tic sound -> EIGHT shots on
         `BENE QRQRQRQR 1` (8 frames x 1 tic) -> 0-tic A_DamageSelf(50)
         -> Loop. 9 tics per cycle after the 12-tic entry.
damage   DamageFunction (random(6,12))   per spark
type     --
sound    "shotguy/attack" on the frame before each burst
impact   12 x RS_SparkPuff1 (cosmetic) per spark; DeathSound "imp/shotx"
trigger  Missile
range    --
mirrored no
inherit  flat Actor; RS_SparkFireBen is a flat Actor (RS_ShotgunnerFX.zs:927)
profile  MakeBurst(proj:"RS_SparkFireBen", count:8, delayTics:1, arc:6,
                   fireSnd:"shotguy/attack", profName:"sg_shrine_nuts")
notes    IT KILLS ITSELF FIRING. `A_DamageSelf(50)` on a LOOPING state,
         with Health 800 -- so it fires at most 16 cycles (128 sparks)
         before it dies of its own attack, and less if you shoot it.
         That is the shrine's whole design: a timed threat you can either
         out-wait or shorten. Our tree writes `A_DamageSelf(50)` where CH
         has `damagething(50)` (CH:2821); same effect, and the divergence
         is a DECORATE-to-ZScript translation, noted at the call site.
         The turret ALSO chases: Idle: `BENE MNOP 6 A_Chase`, and it is
         +NOCLIP, so it drifts through walls toward you.
```

```
ATTACK   RS_ShotgunShrine.Death
file     zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:1008
shape    MULTI
payload  A_Explode x3  +  RS_MineShotgun x2
arc      40   (on the mines: angle random(-20,20))
timing   4x2-tic collapse -> 3x5-tic explosion -> 2 mines on one 0-tic
         frame. 23 tics.
damage   A_Explode(random(5,15),128) on EACH of three frames;
         mines DamageFunction (random(10,50))
type     Fire (mines)
sound    A_Scream -> DeathSound "weapons/rockx" -- UNDEFINED IN CH'S
         SNDINFO, silent there too
impact   the mines bounce 11 times and each detonates for
         3 x A_Explode(random(5,50),128)
trigger  Death
range    --
mirrored no
inherit  flat Actor
profile  MakeBurst(proj:"RS_MineShotgun", count:2, delayTics:0, arc:40,
                   trigger:RS_FIRE_DEATH, profName:"sg_shrine_death")
         + MakeRadial(radius:128, damage:10, profName:"sg_shrine_blast")
notes    MULTI: a three-frame radial blast AND two travelling mines.
         KILLING THE SHRINE IS NOT FREE -- it leaves two bouncing mines
         behind, and it dies on its own after 16 cycles anyway. Shooting
         it converts a predictable spark turret into unpredictable
         area denial.
         DropItem gives 1 shell + 3 Shotguns on death.
```

---

## RS_ShotgunPunish / RS_ShotgunPunish2 — summoned one-shot gun (full)

```
ATTACK   RS_ShotgunPunish.Shoot
file     zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:1066
         (mirror: RS_ShotgunnerFX.zs:1111)
shape    HITSCAN
payload  BulletPuff x random(3,10)
arc      7 horizontal / 5 vertical
timing   6 frames of inflation (2,2,4,4,4,3 = 19 tics) -> 0-tic face ->
         13-tic hold -> 4-tic rack sound -> 4-tic squash -> FIRE on a
         6-tic frame -> 4-tic reset -> Death. ~50 tics, and it fires
         EXACTLY ONCE in its life.
damage   random(1,6)   per pellet
type     --
sound    "weapons/sshotf" on the frame before firing;
         SeeSound "weapons/sshotl" on spawn
impact   vanilla BulletPuff. On its own death: MISL BCD 5 Bright with
         A_Explode(random(5,15),64) on all three frames.
trigger  Spawn   (its Spawn state falls straight through to Shoot -- it
         has no Missile state and never chases)
range    --
mirrored yes  (RS_ShotgunPunish2, RS_ShotgunnerFX.zs:1081, is the same
         class with every A_SetScale X negated: -0.8, -1.3, -1.6, -1.2,
         -1.0. Spawned as a PAIR at +128 and -128 lateral, so they
         flank you.)
inherit  flat Actor. RS_ShotgunPunish2 is NOT a subclass of
         RS_ShotgunPunish -- CH duplicated the whole body. The two are
         identical except for the scale signs and one dropped
         A_SetScale(1.0,1.0) in RS_ShotgunPunish2's Death.
profile  MakeHitscan(fireSnd:"weapons/sshotf", profName:"sg_punisher_shot");
         p.PelletOverride = 6; p.SpreadBonus = 7; p.FireTrigger = RS_FIRE_SPAWN;
notes    Summoned by RS_Shotgunpunisher (RS_ShotgunnerFX.zs:1125), which
         RS_WhiteSGEX casts. 300hp, `Monster;` +NOCLIP -COUNTKILL, so it
         can be shot down during its 36-tic inflation -- and killing it
         still triggers the A_Explode. There is no way to make it silent.
         The 13-tic hold plus the "weapons/sshotf" rack is a genuine
         telegraph: you get about half a second between the sound and
         the pellets.
```

## RS_ShotgunPunishnerf / RS_ShotgunPunishnerf2 — summoned one-shot gun (nerfed)

```
ATTACK   RS_ShotgunPunishnerf.Shoot
file     zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:1176
         (mirror: RS_ShotgunnerFX.zs:1220)
shape    HITSCAN
payload  BulletPuff x random(1,7)
arc      7 horizontal / 5 vertical
timing   6 frames of inflation at 6 tics each (36 tics -- nearly DOUBLE
         the un-nerfed version's 19) -> 0-tic face -> 18-tic hold ->
         4-tic rack -> 4-tic squash -> FIRE on a 6-tic frame -> 4-tic
         reset. ~72 tics, fires once.
damage   random(1,5)   per pellet
type     --
sound    "weapons/sshotf"; SeeSound "weapons/sshotl"
impact   vanilla BulletPuff; death A_Explode(random(5,15),64) x3 frames
trigger  Spawn
range    --
mirrored yes  (RS_ShotgunPunishnerf2, RS_ShotgunnerFX.zs:1191, all
         A_SetScale X negated; spawned as a flanking pair at +/-128)
inherit  flat Actor; again a full duplicate, not a subclass
profile  MakeHitscan(fireSnd:"weapons/sshotf",
                     profName:"sg_punisher_shot_nerf");
         p.PelletOverride = 4; p.SpreadBonus = 7;
         p.FireTrigger = RS_FIRE_SPAWN;
notes    Summoned by RS_Shotgunpunishernerfed, which RS_WhiteSG2 (the
         BASE Benellus) casts. Three differences from the full version,
         all in the same direction: fewer pellets (random(1,7) vs
         random(3,10)), less damage (random(1,5) vs random(1,6)), and a
         much longer wind-up (36+18 tics vs 19+13). It is the same gun
         with the volume turned down.
         Note also: RS_ShotgunPunishnerf/2 do NOT set -COUNTKILL, unlike
         RS_ShotgunPunish/2 which do. Verbatim from CH:2959/3001 vs
         :2856/2899 -- so the nerfed pair counts toward the map's kill
         total and the full pair does not. Almost certainly a CH
         oversight; recorded, NOT fixed.
```

---

# UNRESOLVED

An honest gap is worth more than a confident guess.

**1. The monster count is 15, not 14.** The brief said 14. I count 15
classes that carry attacks and are placed as monsters: `RS_CommonSG`,
`RS_GreenSG`, `RS_BlueSG`, `RS_PurpleSG`, `RS_YellowSG`, `RS_RedSG`,
`RS_FireBluSG2`, `RS_GraySG2`, `RS_AbyssSG2`, `RS_CyanSG2`,
`RS_BrownSG2`, `RS_BlackSG3`, `RS_BlackSG2`, `RS_WhiteSG2`,
`RS_WhiteSGEX`. Plus 5 summoned emplacements that also attack and are
also `Monster;`. I do not know which one the brief's 14 excludes —
most likely `RS_BlackSG2` (a squad minion with no tier icon) or
`RS_WhiteSGEX` (an EX variant of an existing tier). Both are catalogued
here; drop whichever the composer's denominator wants.

**2. `C:\Users\Command\Desktop\CH` does not exist on this machine.**
CLAUDE.md and rs_35 both name it as the ground truth. CH was read
instead at **`E:\New folder\ART SOURCE\CH\decorate\Shotgunners.txt`**,
which CLAUDE.md's own "IMPORTING A MONSTER" section names as the CH
source of truth. Same pack, different path — but I cannot prove the two
copies are identical, and there is one measurable difference already:
**our file header claims CH's `Shotgunners.txt` is 3,102 lines; the copy
I read is 3,047.** All 117 attack call sites matched regardless. Someone
with access to both should confirm they are the same file.

**3. Three numbers in this catalog were NOT verified against a file on
disk**, because `E:\DXR2` (the engine source CLAUDE.md names as the
authority on flags and properties) **does not exist on this machine**:
* the damage and spread constants inside `A_SPosAttackUseAtkSound`
  (`RS_CommonSG.Missile`) — reported as 3 pellets / 22.5 / 5.625 /
  `random(1,5)*3` from general GZDoom knowledge, not from source;
* the default `range` when `A_CustomBulletAttack`'s range argument is
  0 or omitted — reported as MISSILERANGE;
* the numeric value of `CMF_AIMOFFSET`, which is why
  `RS_WhiteSG2.Death`'s `arc` is `--` rather than a degree figure.
Everything else in this file was read out of our tree or CH.

**4. Two shapes are stretched, and I did not coin a word.**
* `A_CustomRailgun` (`RS_BlueSG.Missile`, `RS_GraySG2.Fire2`) is
  classified **HITSCAN**. The vocabulary names only
  `A_CustomBulletAttack`/`A_FireBullets`. It is an instant line attack
  with no travelling actor, which is what a weapon rebuilds, so HITSCAN
  is the useful answer — but a composer who wants a strict reading
  should treat these two rows as UNCLASSIFIED.
* `A_VileTarget` (`RS_BlackSG3.Snipe`, `RS_WhiteSG2.Punisher`,
  `RS_WhiteSGEX.ShotgunRounded`/`.Shrines`) is classified **VILE**. The
  vocabulary names `A_VileAttack`. Same family — LOS-gated, payload
  materialises at the target, nothing travels — but not the same
  function. Four rows affected.

**5. Three attacks have no honest factory call.** The `profile` line is
the deliverable, and for these it is a placeholder that loses the
attack:
* `RS_PurpleSG.GetCloser` and `RS_BrownSG2.GetCloser` — `A_SkullAttack`
  is *the monster becoming the projectile*. `MakeMelee` gives a lunge
  with a 64-unit reach; the actual behaviour is a ballistic body-slam
  at speed 12 / 28 that crosses a room. Nothing in RS_AttackProfile
  moves the shooter.
* `RS_AbyssSG2.Jumper` beat 3 (the carpet) — 45 gravity-bound actors
  placed over an *off-centre rectangle* (`random(-128,328)` forward by
  `random(-178,178)` lateral). `MakeRadial` is instant and centred.
  The mismatch is large enough that the profile is wrong, not merely
  approximate.
* The whole of `RS_AbyssSG2.Jumper` — I split it into three rows so each
  beat gets a clean shape and a clean profile. That is a judgement call.
  It is ONE state chain, ONE gate, ONE trigger, and the monster hops
  backward twice inside it. If the composer wants one row per state
  chain, these three collapse and the hop needs recording somewhere.

**6. HITSCAN rows are the most valuable rows here and the profile system
cannot hold them.** `MakeHitscan` has no pellet-count and no damage
parameter. `PelletOverride` exists as a field but takes an int, and
**9 of the 15 HITSCAN rows roll their pellet count** — plus the hitscan
half of `RS_BrownSG2.Fire1`, which is filed MULTI, for 10 rolled counts
in all: `random(15,20)`, `random(1,2)`, `random(2,4)`, `random(3,9)`,
`random(5,30)` + `random(5,18)` (twice, both Benellus `SG` rows),
`random(3,12)`, `random(3,10)`, `random(1,7)`, `random(7,17)`. Every
`PelletOverride`
value I wrote is a midpoint I chose; **the roll in the `damage`/`payload`
lines is the truth and the profile line is the lossy part**. Three rows
also roll the *spread itself* (`RS_BlackSG3.Shotgunned`
`random(1,12)`, `RS_GraySG2.Fire1` `random(-1,1)`, both Benellus `SG`
rows `random(5,180)`), which `SpreadBonus` cannot express at all. Do
not read a `PelletOverride` number back out of this file as a fact
about the monster.

**7. The shape vocabulary has no summon word; the factory has a summon
mode.** `RS_BlackSG3.Summon` and `RS_WhiteSGEX.Pain` are written
`shape UNCLASSIFIED` with a `MakeSummon` profile, which is internally
contradictory but honest — the alternative was coining SUMMON, which
rs_35 forbids in bold. Four more rows have the same tension one level
down (the three `A_VileTarget` casts and `RS_ShotgunShrine`'s existence
at all). If the vocabulary gets a 14th word, these six are the ones
that want it.

**8. `RS_ShotgunPunishnerf`/`nerf2` are missing `-COUNTKILL` where
`RS_ShotgunPunish`/`2` have it.** Verbatim from CH (`:2959`/`:3001` vs
`:2856`/`:2899`). The consequence is that the *base* Benellus's summoned
guns inflate the map's kill total and the *EX* Benellus's do not. This
looks like a CH oversight rather than intent, but I have no way to
establish that, so it is recorded and not fixed. Owner's call.

**9. The existing deep-read at `docs/monsters/Shotgunner/CATALOG.md`
disagrees with our tree in six places and should not be trusted.** It
describes CHP, a different pack. Where checked, our tree and CH agree
with each other and CATALOG.md is the odd one out:

| CATALOG.md says | our tree + CH say | rows affected |
|---|---|---|
| entry 1: `A_CustomBulletAttack(22.5,0,3,random(1,5)*3,...,CBAF_NORANDOM)` | `A_SPosAttackUseAtkSound` — an engine-native call, no explicit arguments at all | `RS_CommonSG.Missile` |
| entry 2: the 7th green bolt leaves on the lowering frame | all seven are 0-tic; they leave together | `RS_GreenSG.Missile` |
| entry 16/17: Gray fires `(1,0,1,random(5,20),BulletPuff,16000)` | Fire1 is `(random(-1,1),0,random(1,2),random(1,9))`; Fire2 is `(0,0,1,random(5,20))`. No `16000` anywhere, in either tree | `RS_GraySG2.Fire1`, `.Fire2` |
| entry 17 omits the laser sight | Fire2 fires **four** damage-0 `A_CustomRailgun` sweeps with `RS_RedDotSGPuff` before the shot — a 36-tic telegraph | `RS_GraySG2.Fire2` |
| entry 18: the Red's five values are angles | they are `spawnofs_xy` (arg 3); **all five angles are 0** | `RS_RedSG.Missile` |
| entry 14: Brown gate is "closer than 500", 20 mud pellets only | gate is `A_JumpIfCloser(400)` **plus** an LOS band to 1200; and there is a `random(7,17)`-pellet hitscan at line 286 the entry does not mention | `RS_BrownSG2.Fire1` |
| entry 20: summons `RS_BlackSGTrooper` from `zscript/monsters/RS_BlackSGTrooper.zs` | that class and that file **do not exist in our tree**; the commander summons `RS_BlackSG2`, defined at `RS_Shotgunner.zs:1679` | `RS_BlackSG3.Summon` |
| entry 28: a "forty-spark barrage" | `RS_SparkPuff1` is `+NOINTERACTION` with no `Projectile` and no `Damage` — the sparks cannot hurt anything | `RS_WhiteSGEX.ShotgunRounded` |
| entry 29: 8000-unit range, `A_Jump(170)` gate | no range argument is passed; the gate is `A_Jump(128)` | `RS_WhiteSGEX.FocusedHitScan` |

I did not check every CATALOG.md entry — only the ones that touched a
row I was writing. **Assume the rest is equally unreliable.**

**10. Not catalogued, deliberately.** `RS_SGBurst`
(`RS_ShotgunnerFX.zs:884`) is a Benellus **DropItem**, not an attack —
it scatters 52 `Shotgun` pickups on a 1-tic loop plus an `A_Burst`. No
damage, no `Projectile`. `RS_CH_Cactus` and `RS_CH_Cirno` are
`Damage 0` keepsake props. `RS_Drt1`/`2`/`3` are `Damage 0` dirt.
`RS_SparkPuff1` and `RS_SparkShieldBen` are `+NOINTERACTION` cosmetics.
`RS_CHBSTarget` is a beeping marker with no damage. All appear in
`impact`/`notes` lines where relevant and none is counted as a payload.

**11. Sounds I could not follow to a lump.** rs_35 does not ask for the
sound audit, and I did not do one — but four names are flagged in our
own source as **undefined in CH's SNDINFO and silent in CH itself**:
`weapons/grenlf`, `weapons/grenlx`, `weapons/grbnce` (all on
`RS_SGGasNade`) and `weapons/rockx` (on `RS_MineShotgun`,
`RS_ShotgunShrine`, and all four punisher classes). A fifth,
`spike/spiked` on `RS_IceZombieShot`, is flagged the same way in the
zombieman file. I took those annotations at face value and did **not**
verify them against `E:\New folder\ART SOURCE\CH\SNDINFO.txt`. Every
other `sound` line in this catalog is the name as written in our tree,
with no claim that the lump resolves.
