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

# HELL KNIGHT FAMILY -- ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Shape words are from
that spec's CLOSED set; none are coined.

## Header

| | |
|---|---|
| Family | HellKnight (Colourful Hell "Colourset8" ladder) |
| Monsters with attacks | **14** (+1 pure inheritor, +3 minions) |
| Attack rows written | **60** primary + **12** secondary (impact-is-an-attack) = **72** |
| Source files | `E:\RS_Main\zscript\monsters\hellknight\RS_HellKnight.zs` (2,309 lines, read whole)<br>`E:\RS_Main\zscript\monsters\hellknight\RS_HellKnightFX.zs` (1,492 lines, read whole) |

### The denominator I actually read

* **68 classes opened in the two family files** -- 23 in `RS_HellKnight.zs`
  (1 RandomSpawner + 7 cvar stubs + 14 attacking monsters + 1 inheritor),
  45 in `RS_HellKnightFX.zs` (1 `play` helper + 44 actors).
* **326 state labels** across those two files (comment-stripped count).
* **175 `A_CustomMissile` call sites**, naming **42 distinct payload
  classes** (comment-stripped, case-insensitive). 485 total attack-ish call
  sites when `A_SpawnItemEx` / `A_Explode` / melee / vile / railgun are
  included.
* **21 external classes opened in 7 other family files**, because a payload
  the Hell Knights fire is frequently owned by another lane:
  `RS_HellionBall`, `RS_EffectHK` (imp) · `RS_HKRedDeath`, `RS_RedThingsHK`,
  `RS_SplashAbyss`, `RS_SplashAbyss2`, `RS_AbyssShotIdentifier` (zombieman) ·
  `RS_SpikeCyanRev`, `RS_HKEXProtect` (demon) · `RS_BaronsBlueBalls`,
  `RS_HKBolt2`, `RS_FireHKBall1`, `RS_BigHK`, `RS_BigHK2`, `RS_BigHK3`,
  `RS_THEBEEHK`, `RS_THEBEEHK2`, `RS_HomingRocketTrailFatso` (lostsoul) ·
  `RS_MolochNail`, `RS_PlasmaBallSP4`, `RS_IceCacoTrail` (cacodemon) ·
  `RS_SparkPuff1`, `RS_Purpfire2`, `RS_CH_Cirno` (shotgunner) ·
  `RS_RedRevLoad`, `RS_CGNail`, `RS_CGRailBuff`, `RS_PuffCybieRed`
  (chaingunner) · `RS_BlueImp` (imp), `RS_CommonSpectre` (spectre).
* **Engine source read** for the six action functions whose argument order
  and defaults decide several rows: `A_CustomMissile`, `A_CustomMeleeAttack`,
  `A_CustomComboAttack`, `A_BruisAttack`, `A_VileAttack`, `A_MeleeAttack`,
  `A_CustomRailgun`. Cited inline where it changes a row.
* **CH cross-check**: every attack call site in
  `E:\New folder\ART SOURCE\CH\decorate\Hellknights.txt` (3,546 lines) was
  listed and compared against ours. **They agree everywhere except the one
  owner-approved departure** recorded at `RS_GreenHK.Missile2` below. See
  UNRESOLVED #1 about the CH path.

---

## HOW THE CLOSED SHAPE WORDS WERE APPLIED

Stated once so the seventeen files compose. Every row below follows this
mechanically -- no judgement calls hidden in individual rows.

| Condition (on the *yaw* argument and the timing) | Shape |
|---|---|
| n == 1, however much random slop it carries | `SINGLE` |
| all shots share one nominal yaw, **all on one tic** | `SALVO` |
| all shots share one nominal yaw, **spread across tics** | `BURST` |
| yaw is a **deterministic step** (15,45,75...) | `FAN`, or `RING` if it closes 360 |
| yaw is `random(...)` / `randompick(...)` / `frandom(...)` | `SCATTER` |
| coverage is a full 360 (`random(0,359)`, or quadrant randoms that tile 360) | `RING` |
| not aimed at all -- placed by XY offset via `A_SpawnItemEx` | `RAIN` (note whether centred on caster or target) |
| `A_CustomMeleeAttack` / `A_MeleeAttack` heads the attack | `MELEE` (projectile secondaries go in `payload`) |
| `A_CustomComboAttack`, or `A_BruisAttack` (same melee-else-missile semantic) | `COMBO` |
| `A_CustomRailgun` (instant trace) | `HITSCAN` |
| `A_VileAttack` | `VILE` |
| **two or more *damaging* payload classes** in one attack | `MULTI` (overrides the above) |
| self-buff / summon / shield -- fires nothing damaging | `UNCLASSIFIED` + note |

**Cosmetic secondaries never make an attack `MULTI`.** A payload with no
`Damage`/`DamageFunction` and no `A_Explode` anywhere in its chain is
recorded in the `payload` field marked `(cosmetic)`. Doing it the other way
round would tell a profile author to build a two-payload weapon where one
half is a muzzle flare. The cosmetic set in this family is:
`RS_SparkPuff1`, `RS_BluCybFX`, `RS_RedRevLoad`, `RS_ZapDecHKex`,
`RS_ZapOrbHKEX`, `RS_CyanHKShade`, `RS_EffectHK`, `RS_RedThingsHK`,
`RS_SplashAbyss` (the parent -- `RS_SplashAbyss2` **does** damage),
`RS_HKSplashDed`, `RS_BruiserTrail`, `RS_SoulSmoke`, `RS_HellWarriorShield`.

**Anatomy is stripped.** `BOS2`/`BRUS`/`BRUR`/`BRUC`/`HWAR`/`HFRY`/`PHAN`
are knight animation and contribute only their **tic counts**. No sprite
letters appear in any row.

---

## THREE ENGINE FACTS THAT DECIDE ROWS

**1. `A_CustomMissile`'s signature is
`(missiletype, spawnheight=32, spawnofs_xy=0, angle=0, flags=0, pitch=0, ptr)`**
(`E:\UZDXREMA\wadsrc\static\zscript\compatibility.zs:131`), and
`CMF_AIMOFFSET == 1` (`constants.zs:53`).

CH writes `A_CustomMissile("X", h, ofs, CMF_AIMOFFSET, random(0,360), random(0,360))`
at a family of sites, meaning to pass the flag in the *flags* slot. As
written it lands in the **angle** slot. So those calls actually fire at a
fixed **1 degree** yaw with **`flags = random(0,360)`** -- a *random
combination of CMF bits every single call* -- and `pitch = random(0,360)`.
Our tree transcribes CH verbatim; **CH and ours are identical here**, and
this is recorded, not corrected.

**Counted: 36 call-site LINES in the two family files, and every single one
puts the flag in the angle slot -- not one of the 36 has it in `flags`.**
Breakdown: `RS_YellowHK.Boom` 8 lines · `RS_BlackHK2.See` 11 ·
`RS_RedHK.Death` 10 (with `flags = 2` fixed rather than random) ·
`RS_BlackHK2.Death` + `RS_BlackHKEX.Death` 6 lines / 11 spawns each
(multi-frame states) · `RS_BloodBoltHK.Spawn` 1. Plus 17 more lines in
`RS_LostSoulFX.zs` and 3 in `RS_ImpFX.zs` belonging to payloads this family
fires (`RS_FireHKBall1.Spawn`, `RS_BigHK.Death`).
Marked `[CMF-SLOT]` in the rows. See UNRESOLVED #3.

**2. `A_VileAttack`'s blast half needs a `tracer`.**
`E:\UZDXREMA\wadsrc\static\zscript\actors\doom\archvile.zs:130` -- the
`blastdmg`/`blastradius` `A_Explode` runs on `Actor fire = tracer`, and is
skipped entirely when `tracer` is null. `RS_BrownHK2` never sets one (neither
does CH). See `RS_BrownHK2.BlastEm`.

**3. `A_CustomMeleeAttack` / `A_CustomComboAttack` substitute `Melee` for an
omitted damagetype** (`src\playsim\p_actionfunctions.cpp:1085` and `:1129`),
so every melee row below is `type Melee` even though no row writes it.
`A_MeleeAttack` is `random(1,8) * MeleeDamage`, type `Melee`
(`actors\attacks.zs:819`). `A_BruisAttack` is `random(1,8) * 10` melee, type
`Melee`, else `BaronBall` (`actors\doom\bruiser.zs:153`).

---
---

# TIER 13 -- `RS_BrownHK2` ("Lion?") -- the parry knight

Health 700, Speed 12, MeleeRange default (44), Radius 24. CH `Hellknights.txt:40`.

```
ATTACK   RS_BrownHK2.Missile
file     zscript/monsters/hellknight/RS_HellKnight.zs:302
shape    SINGLE
payload  RS_HellionBall x1
arc      --   (angle argument omitted -> 0, straight at the target)
timing   18 tics windup (1,1,8,8), shot on a 6-tic state; 24 tics total
damage   DamageFunction (random(10,60))            [RS_ImpFX.zs:1293]
type     Fire
sound    --   (the state is silent; RS_HellionBall's own SeeSound
              "Monster/hlnatk" is what the player hears)
impact   HLBL J-N 15-tic bloom + DeathSound "Monster/hlnexp" + Decal
         "DoomImpScorch". NO A_Explode -- contact damage only.
trigger  Missile
range    88..   (A_JumpIfCloser(radius + 64) = 24+64 = 88 diverts to
              MeleeMaybe BEFORE the shot; this is the far branch)
mirrored no
inherit  --   (RS_HellionBall : Actor, self-contained; imp lane owns it)
profile  MakeVolley(proj:"RS_HellionBall", count:1) + p.MinRange = 88
notes    RS_HellionBall is a SEEKER: A_SeekerMissile(7,5) plus
         A_Weave(1.0,1.0,1.0,10) every 2 tics, so it curves and snakes.
         Speed 19, Scale 1.3, Alpha 0.80, +THRUGHOST.
         A second A_JumpIfCloser(88) AFTER the shot diverts to Melee, so
         one Missile can be immediately followed by a Melee.
```

```
ATTACK   RS_BrownHK2.Melee
file     zscript/monsters/hellknight/RS_HellKnight.zs:328
shape    MELEE
payload  --
arc      --
timing   16 tics windup (8,8), hit on an 8-tic state, 6-tic recover; 30 total
damage   A_CustomMeleeAttack(random(10,60), ...)
type     Melee   (engine substitutes Melee for the omitted damagetype)
sound    "Baron/Melee" on hit; miss sound is the literal string "none"
impact   --   (instant, no projectile)
trigger  Melee
range    ..44   (MeleeRange not overridden -> Actor default 44)
mirrored no
inherit  --
profile  MakeMelee(range:44, fireSnd:"Baron/Melee", dmgMult:1.0)
notes    Third arg "none" is passed as the MISS sound, not as a damagetype.
         Tail A_JumpIfCloser(252,"Rush") chains straight into the dash.
```

```
ATTACK   RS_BrownHK2.Rush
file     zscript/monsters/hellknight/RS_HellKnight.zs:332
shape    MULTI
payload  RS_BrownHKShieldCheck x1  +  RS_HKRedDeath x1
arc      --   (both fired at yaw 0)
timing   12-tic forward lunge, bash on a 3-tic state, detonation on the
         next 1-tic state; 16 tics total
damage   RS_BrownHKShieldCheck: DamageFunction (random(10,60))  [FX:150]
         RS_HKRedDeath: A_Explode(random(5,10), 42)             [zombieman FX:862]
type     Melee (shield check) / Fire (HKRedDeath)
sound    --   (SeeSound, DeathSound and BounceSound on the shield check are
              all explicitly blanked to "" -- FX:156-158)
impact   Shield check: 6-tic life then a silent Death. Its XDeath plays
         "monster/dknswg" -- so it is audible ONLY when it gibs something.
         HKRedDeath: instant barrel-pop -- "world/barrelx" ×2,
         A_Explode(random(5,10),42), then A_Burst("RS_RedThingsHK") gib spray.
trigger  Missile   (via MeleeMaybe, reached by A_JumpIfCloser(88) from
                    Missile; also from Parry via A_JumpIfCloser(252) and
                    from Melee via A_JumpIfCloser(252))
range    ..252
mirrored no
inherit  RS_HKRedDeath -> zombieman FX (RS_ZombiemanFX.zs:844); its
         DeathSound "world/barrelx" and the whole detonation live there,
         nowhere near this site.
profile  MakeVolley(proj:"RS_BrownHKShieldCheck", count:1) then
         MakeVolley(proj:"RS_HKRedDeath", count:1) as a second slot entry
         + p.MaxRange = 252
notes    The lunge itself is ThrustThing(int(angle),32,0,0) -- a 32-unit
         forward shove, our int() wrapper over CH's `thrustthing(angle,...)`.
         RS_BrownHKShieldCheck draws TNT1 -- it is an INVISIBLE melee arc
         (Speed 20, Gravity 0.5, 6-tic life ~= 120 units of reach), not a
         visible projectile, despite carrying Alpha 0.85 / Scale 1.5.
         A_JumpIfCloser(176) between the two payloads diverts to BlastEm, so
         at <176 units the HKRedDeath line is never reached.
```

```
ATTACK   RS_BrownHK2.BlastEm
file     zscript/monsters/hellknight/RS_HellKnight.zs:343
shape    VILE
payload  RS_HKRedDeath x1  (fired one tic before the vile hit)
arc      --
timing   1,1,2,1 -- 5 tics total, the shortest attack in the family
damage   A_VileAttack("bomb/boom", 5, 5, 128, 1.35)
         -> 5 direct, damagetype 'none'
         -> the 5/128 blast NEVER FIRES (see notes)
         + RS_HKRedDeath A_Explode(random(5,10),42)
         + A_RadiusThrust(2040, 400, RTF_NOTMISSILE)
type     none for the direct hit; Fire for the HKRedDeath
sound    "bomb/boom" (the A_VileAttack `snd` argument)
impact   HKRedDeath as above. The vile hit also sets the victim's
         Vel.z = 1.35 * 1000 / mass -- a hard upward punt.
trigger  Missile   (A_JumpIfCloser(176) from Rush; A_JumpIfCloser(128)
                    from Parry)
range    ..176
mirrored no
inherit  RS_HKRedDeath -> zombieman FX
profile  MakeRadial(radius:400, damage:5, hitsAllies:false,
                    fireSnd:"bomb/boom") + p.MaxRange = 176
notes    **THE BLAST HALF IS INERT, IN CH TOO.** A_VileAttack runs its
         blastdmg/blastradius A_Explode on `Actor fire = tracer` and returns
         early if tracer is null (archvile.zs:143-148). RS_BrownHK2 never
         sets a tracer -- no A_VileTarget, no fire actor. So of
         `A_VileAttack("bomb/boom",5,5,128,1.35)` only the **5 direct
         damage and the 1.35 z-thrust land**; the 5-damage / 128-radius
         blast is dead code. Identical at CH Hellknights.txt:152.
         The real area effect here is A_RadiusThrust(2040,400) -- 400 units
         of pure knockback, no damage.
```

```
ATTACK   RS_BrownHK2.Parry
file     zscript/monsters/hellknight/RS_HellKnight.zs:318
shape    UNCLASSIFIED   (defensive: deploys a reflector, deals no damage)
payload  RS_BrownHKShield x1   (deployed at +18 forward, +24 up)
arc      --
timing   13 tics of windup (3,3,3,3,1) then the spawn on a 3-tic state;
         12 more tics of hold, then 12 of recovery; 40 tics if nothing
         interrupts
damage   --   (the shield has no Damage and no A_Explode anywhere)
type     --
sound    "HEALSIEL" -- played by the SHIELD, 5 tics after it spawns
         (RS_HellKnightFX.zs:210), not by the Parry state
impact   --
trigger  See / Pain / Missile -- A_JumpIfInTargetLOS("Parry",0,
         JLOSF_DEADNOJUMP,1200,200) at :286, :289, :292; plus
         A_Jump(84,"Parry") out of Pain at :351
range    ..1200   (dist_max 1200, dist_close 200 as written)
mirrored no
inherit  --
profile  MakeSelfBuff(speedMult:1.0, damageMult:1.0, duration:24,
                      noPain:false, fireSnd:"HEALSIEL")
         -- SelfBuff is the nearest existing factory; a true reflect slot
         does not exist yet, so this is a placeholder, not a translation.
notes    RS_BrownHKShield (FX:174) is Radius 72, Health 999, Species
         "BaronOfHell", +INVULNERABLE +REFLECTIVE +DEFLECT +SHIELDREFLECT
         +NOTARGET +DONTTHRUST +NOGRAVITY +MTHRUSPECIES +THRUSPECIES.
         It **reflects incoming projectiles back at the shooter** for
         ~14 tics of Fly, then fades over 10 tics of Death and A_Die's.
         Scale ramps 0.4 -> 1.25 as it inflates.
         Parry's tail re-gates: A_JumpIfCloser(252) -> Rush,
         A_JumpIfCloser(128) -> BlastEm. So the shield is a *feint* that
         leads into the dash.
         NOT a row: Death spawns RS_HellWarriorShield (FX:224) -- a dropped
         bouncing prop, no damage, purely a corpse decoration.
```

---

# TIER 12 -- `RS_CyanHK2` ("Cyanide HellKnight")

Health 700, Speed 16, +BRIGHT, RenderStyle Add. CH `Hellknights.txt:298`.

```
ATTACK   RS_CyanHK2.Missile
file     zscript/monsters/hellknight/RS_HellKnight.zs:461
shape    SCATTER
payload  RS_IceHKShot x6
arc      per-shot random yaw, WIDENING: 0, ±3, ±1, ±5, ±3, ±7
timing   12-tic windup; firing states 6,6,5,5,3,3; shot-to-shot gaps
         18,14,13,11,9 tics -- an accelerating six-round stream; 80 total
damage   DamageFunction (random(9,27))    [RS_HellKnightFX.zs:256]
type     Ice
sound    --   (states are silent; RS_IceHKShot's SeeSound "Ice/Hit2" is
              what plays per shot)
impact   SEE THE SECONDARY ROW `RS_IceHKShot.Death` BELOW -- a 12-needle
         360 ring. DeathSound "spike/spiked" is a KNOWN VERBATIM HOLE:
         undefined in CH's SNDINFO, so it is silent in CH too.
trigger  Missile   (the 128/256 branch; A_Jump(128,"A1") takes the other half)
range    --   (no gate)
mirrored yes -- A_SetScale(-1.0,1.0) flips before shots 2, 4 and 6 and
         A_SetScale(1.0,1.0) flips back; the knight visibly alternates arms
inherit  --
profile  MakeBurst(proj:"RS_IceHKShot", count:6, delayTics:13, arc:14)
notes    Uniform delayTics:13 vs CH's 18/14/13/11/9 accelerating ramp --
         BurstDelayTics is a single uniform value, so the acceleration has
         no exact form. 6*13 = 78 vs 80 actual. Recorded, not rounded away.
         arc:14 approximates the widening ±1..±7; the ramp is also lost.
         A_CheckSight("See") sits between every pair of shots -- the stream
         aborts the instant LOS breaks.
```

```
ATTACK   RS_CyanHK2.A1
file     zscript/monsters/hellknight/RS_HellKnight.zs:487
shape    MULTI
payload  RS_IceOrbCyanHK x1  +  RS_SpikeCyanRev x30
         (x20 via A_SpawnItemEx at fixed body offsets, x10 via
          A_CustomMissile at randompick(-10,-5,0,5,10))
         + RS_CyanHKShade x2 (cosmetic afterimage, fired BEHIND at yaw 180)
arc      orb: 0.  Fired spikes: randompick(-10,-5,0,5,10) -- a 5-step
         ±10 pick, so effectively a 20-degree quantised fan.
         Spawned spikes: yaw frandom(-5,5) off two shoulder points
         (+12,-21,+24) and (+12,+21,+24), velocity random(12,33) forward
         and random(1,3) up.
timing   8 windup; shades at +8 and +14; orb at +20; all 30 spikes on the
         single tic at +28. 28 tics total.
damage   RS_IceOrbCyanHK: DamageFunction (random(7,60))   [FX:318]
         RS_SpikeCyanRev: DamageFunction (random(1,3))    [demon FX:161]
         RS_CyanHKShade:  none
type     Ice (both damaging payloads)
sound    --   (the state itself is silent; RS_IceOrbCyanHK SeeSound
              "ice/Cast" carries the attack)
impact   SEE `RS_IceOrbCyanHK.Death` BELOW -- A_Explode(random(10,60),128)
         plus a 20-needle 360 ring, DeathSound "Ice/Hit2".
         RS_SpikeCyanRev impact: RIP1 CBA 6 A_Explode(random(0,1),6),
         DeathSound explicitly "" -- silent, and the explode is a rounding
         error. It is a shard-storm for texture, not damage.
trigger  Missile   (A_Jump(128,"A1") at :459)
range    --
mirrored no
inherit  RS_SpikeCyanRev -> demon FX (RS_DemonFX.zs:153). Its DeathSound ""
         and its A_Explode are written there; reading this site alone
         reports "no impact".
profile  MakeVolley(proj:"RS_IceOrbCyanHK", count:1, fireSnd:"ice/Cast")
         + MakeVolley(proj:"RS_SpikeCyanRev", count:30, arc:20) as a second
           slot entry
notes    RS_SpikeCyanRev falls: -NOGRAVITY, Gravity 1.5, Scale 0.25. The
         30 spikes arc and hit the floor -- a hail, not a beam.
         **CH duplicates one spawn line verbatim** (Hellknights.txt:414 and
         :415 are byte-identical, both `12,-21,24`); our :491/:492 keep the
         duplicate. So the LEFT shoulder gets 10 spikes and the right 10.
         The `FATT HHHHH 0` at our :493 / CH :416 is a 0-tic Mancubus
         sprite in the middle of a cyan knight -- invisible, faithful.
         Tail A_Jump(64,"Dodge1","Dodge2") chains into the sidestep row.
```

```
ATTACK   RS_CyanHK2.Melee
file     zscript/monsters/hellknight/RS_HellKnight.zs:500
shape    MELEE
payload  --   + RS_SpikeCyanRev x16 (secondary, on the tic after the hit)
arc      spikes: random(-15,15) yaw, CMF_OFFSETPITCH with pitch
         random(-25,-5) -- a 30-degree cone angled UPWARD
timing   16 windup (8,8), hit on an 8-tic state, 16 spikes on the next
         0-tic state; 24 tics total
damage   A_CustomMeleeAttack(random(20,90), "baron/melee")
         spikes: DamageFunction (random(1,3))
type     Melee (the swing) / Ice (the spikes)
sound    "baron/melee"
impact   spikes as in A1 -- A_Explode(random(0,1),6), silent
trigger  Melee
range    ..44   (MeleeRange not overridden)
mirrored no
inherit  RS_SpikeCyanRev -> demon FX
profile  MakeMelee(range:44, fireSnd:"baron/melee") +
         MakeVolley(proj:"RS_SpikeCyanRev", count:16, arc:30,
                    pitchJitter:20) as a second slot entry
notes    Tail A_Jump(64,"Missile") then A_Jump(64,"Dodge1","Dodge2") --
         the swing can chain into the six-shot stream or the sidestep.
```

```
ATTACK   RS_CyanHK2.Dodge1
file     zscript/monsters/hellknight/RS_HellKnight.zs:506
         (sibling Dodge2 at :511; a third site in Pain at :518)
shape    UNCLASSIFIED   (mobility + decoy; deals no damage)
payload  RS_CyanHKShade x1 (cosmetic)
arc      180   (fired directly BEHIND -- the afterimage is left where the
                knight was)
timing   0-tic spawn, then 1 tic of ThrustThingZ(0,11,0,0) and 1 tic of
         ThrustThing(angle∓90, 29, 0, 0); 2 tics total
damage   --
type     --
sound    --
impact   RS_CyanHKShade (FX:280): 6 tics, scaling 1.0->1.5 while alpha
         steps 0.25 -> 0.20 -> 0.10 -> 0.05. +NOCLIP +NOINTERACTION,
         SeeSound and DeathSound both explicitly "". A pure ghost trail.
trigger  Missile (A1 tail :496) / Melee (:503) / Pain (:518, :520)
range    --
mirrored yes -- Dodge1 thrusts angle-90, Dodge2 angle+90; A_Jump picks
inherit  --
profile  MakeSelfBuff(speedMult:1.0, duration:2, fireSnd:"")
         -- a dodge-hop has no factory; SelfBuff is a placeholder.
notes    An 11-unit hop plus a 29-unit lateral shove. As a weapon part this
         is a **dash with a leave-behind ghost**, which is the interesting
         half. The Pain site (:518) fires the shade one tic BEFORE A_Pain,
         so a hurt cyan knight always drops a decoy.
```

---

# TIER 9 -- `RS_AbyssHK2` ("Abyss Bruiser")

`: HellKnight`. Health 1850, Speed 15, MeleeRange 58, XScale 1.15.
CH `Hellknights.txt:570`.

```
ATTACK   RS_AbyssHK2.Melee
file     zscript/monsters/hellknight/RS_HellKnight.zs:614
shape    MELEE
payload  --   + RS_SplashAbyss2 x16 (secondary)
arc      splash: random(-15,15) yaw, CMF_OFFSETPITCH, pitch random(-25,-5)
timing   8 windup (4,4), hit on a 5-tic state, 16 splashes on the next
         0-tic state, 1-tic tail; 14 tics total
damage   A_CustomMeleeAttack(random(20,90), "baron/melee")
         splash: DamageFunction (random(1,9))   [zombieman FX:741]
type     Melee (swing) / Ice (splash)
sound    "baron/melee"
impact   RS_SplashAbyss2 inherits RS_SplashAbyss's states: BAL1 AB 12,
         A_Jump(32,"Death") each cycle, Death = BAL7 CDE fade. No explode.
trigger  Melee
range    ..58   (MeleeRange 58)
mirrored no
inherit  RS_SplashAbyss2 : RS_SplashAbyss (zombieman FX:735/:707) -- the
         CHILD adds the damage and the Ice type; the PARENT holds every
         state, the -NOGRAVITY (so it falls) and the translation. Reading
         only the child reports "no states".
profile  MakeMelee(range:58, fireSnd:"baron/melee") +
         MakeVolley(proj:"RS_SplashAbyss2", count:16, arc:30, pitchJitter:20)
notes    Tail A_Jump(88,"Missile") -- a swing very often chains into the
         ranged tree.
```

```
ATTACK   RS_AbyssHK2.Balls
file     zscript/monsters/hellknight/RS_HellKnight.zs:630
         (mirror half Balls2 at :636)
shape    SCATTER
payload  RS_AbyssHKBall x1 per pass (2 per full mirror cycle)
arc      random(-1,1) -- a 2-degree jitter, effectively aimed
timing   8-tic windup, shot on a 2-tic state, 1-tic refire check;
         11 tics between shots, sustained by A_MonsterRefire(128,"See")
damage   DamageFunction (random(10,55))   [RS_HellKnightFX.zs:359]
type     Plasma
sound    --   (SeeSound "baron/attack" belongs to the ball)
impact   SEE `RS_AbyssHKBall.Death` BELOW -- 16 splashes, an explode and
         three lingering mists. DeathSound "spit/spit2".
trigger  Missile   (Missile -> A_JumpIfCloser(1500,"Choices");
                    Choices -> A_JumpIfCloser(900,"Choices2");
                    Choices A_Jump(255,"Balls","BallsBar");
                    Choices2 A_Jump(255,"Balls","Mist","BallsBar"))
range    ..1500 for the whole ranged tree; beyond 1500 Missile falls
         straight to Balls with no gate
mirrored yes -- Balls uses the left-arm frames, Balls2 the right; each
         tail A_Jump(64,"CL2"/"CL1") re-gates on A_JumpIfCloser(800)
inherit  --
profile  MakeBurst(proj:"RS_AbyssHKBall", count:2, delayTics:11, arc:2)
         + p.MaxRange = 1500
notes    RS_AbyssHKBall is Speed 28, XScale 1.42 / YScale 1.0 -- a
         STRETCHED disc. Per CLAUDE.md that non-uniform scale cannot live
         in a Default block on some builds; here it is XScale/YScale, which
         does compile. +DONTHARMCLASS, Alpha 1.95 (>1, deliberate over-add).
         Trails RS_AbyssShotIdentifier every 8 tics.
```

```
ATTACK   RS_AbyssHK2.BallsBar
file     zscript/monsters/hellknight/RS_HellKnight.zs:649
shape    SCATTER
payload  RS_AbyssHKBall x7
arc      one aimed at 0, three at random(1,14), three at random(-14,-1)
         -- a 28-degree split cone with a HOLE in the middle ±1
timing   19-tic windup (7,6,6); all seven on ONE tic; 16-tic recovery;
         36 tics total
damage   DamageFunction (random(10,55)) each
type     Plasma
sound    --
impact   as `RS_AbyssHKBall.Death` below, ×7
trigger  Missile   (Choices / Choices2 jump table; also CL1/CL2 via
                    A_JumpIfCloser(800))
range    ..1500 (and preferentially <800 through CL1/CL2)
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_AbyssHKBall", count:7, arc:28)
notes    The centre-hole is real: random(1,14) and random(-14,-1) both
         EXCLUDE 0, so only the single aimed shot occupies the middle.
         MakeVolley's even arc distribution will not reproduce that gap.
```

```
ATTACK   RS_AbyssHK2.Mist
file     zscript/monsters/hellknight/RS_HellKnight.zs:662
shape    MULTI
payload  RS_AbyssHKMist x27  +  RS_SplashAbyss2 x188
arc      --   NEITHER IS AIMED. Mist is placed at random(-256,256) XY,
         Z 6, with velocity random(1,11) forward and yaw random(-359,359).
         Splash is placed at random(-328,328) XY, Z random(6,16), velZ 2.
timing   25-tic wind-up including A_PlaySound; then four 47-splash bursts
         interleaved with 8+10+9 mist ticks and three A_Wander runs
         (7+8+10 tics); 20-tic recovery; ~110 tics total
damage   RS_AbyssHKMist: A_Explode(random(1,9), 46) on EVERY ONE of 12
         Death frames -- 12 explosions over 72 tics per puff
         RS_SplashAbyss2: DamageFunction (random(1,9))
type     Ice (both)
sound    "superbaron/scream" on the 12-tic wind-up state (:656)
impact   Mist has no Spawn damage -- it runs PSBG CDE for 6 tics then
         GOES STRAIGHT TO DEATH, and the Death chain is the weapon.
trigger  Missile   (Choices2 only -- so Mist requires the target inside 900)
range    ..900
mirrored no
inherit  RS_SplashAbyss2 : RS_SplashAbyss (zombieman FX)
profile  MakeVolley(proj:"RS_AbyssHKMist", count:27, arc:360) +
         MakeVolley(proj:"RS_SplashAbyss2", count:188, arc:360)
         -- both centred on the CASTER, so a real build wants a RAIN-style
         placement, which MakeVolley does not have.
notes    While this runs the knight sets bNOPAIN, A_SetTranslucent(0.45),
         A_SetSpeed(99) and A_Wanders -- **it becomes a fast, translucent,
         pain-immune fog bank**. Speed and alpha are restored and bNOPAIN
         cleared at :672-675.
         The per-frame A_Explode on RS_AbyssHKMist is one of the ~55
         deliberate multi-frame explodes flagged in CLAUDE.md -- a
         lingering gas, not a bug. Do not "fix" it to a single blast.
         See UNRESOLVED #4 for the 188 count.
```

```
ATTACK   RS_AbyssHK2.Dodge1
file     zscript/monsters/hellknight/RS_HellKnight.zs:600
         (sibling Dodge2 at :605)
shape    RAIN
payload  RS_SplashAbyss2 x47 (cosmetically also 3x RS_SplashAbyss per
         See2 chase cycle at :592/:595 -- those are the PARENT class and
         carry NO damage)
arc      --   not aimed: random(-328,328) XY around the CASTER,
         Z random(6,16), velZ 2. They then FALL (parent is -NOGRAVITY).
timing   1 tic of ThrustThingZ(0,11), 47 spawns on the same 0-tic state,
         1 tic of ThrustThing(angle∓90, 29); 2 tics total
damage   DamageFunction (random(1,9)) each
type     Ice
sound    --
impact   BAL7 CDE fade, no explode
trigger  See (See2 tail A_Jump(64) at :596) / Pain (:682) / Melee-chain
range    --
mirrored yes -- Dodge1 = angle-90, Dodge2 = angle+90
inherit  RS_SplashAbyss2 : RS_SplashAbyss
profile  MakeVolley(proj:"RS_SplashAbyss2", count:47, arc:360)
         -- placement is XY-offset, not angular; MakeVolley's arc is the
            closest available and is NOT equivalent.
notes    **The See2 drip is NOT an attack.** :592 and :595 spawn
         `RS_SplashAbyss` -- the PARENT -- which has no Damage property at
         all (zombieman FX:707). Only the `2` child damages. That one
         character is the entire difference between decoration and a
         damaging trail, and it is easy to misread.
```

---

# TIER 7 -- `RS_FireBluHK2` ("Knight with clown armor")

Health 900, Speed 13. CH `Hellknights.txt:833`.

```
ATTACK   RS_FireBluHK2.Bolt1
file     zscript/monsters/hellknight/RS_HellKnight.zs:758
shape    SCATTER
payload  RS_FireBluHKBall1 x2 per pass
arc      random(-1,1) then random(-9,9) -- the second shot is deliberately
         much looser
timing   12-tic windup, shot 1 on a 6-tic state, 10-tic re-aim, shot 2 on
         a 5-tic state; 16 tics between shots; A_Jump(76,"Bolt1") reloops
damage   DamageFunction (random(5,50))   [RS_HellKnightFX.zs:425]
type     Plasma
sound    --   (SeeSound "Spell/spellCast1" belongs to the ball)
impact   SEE `RS_FireBluHKBall1.Death` BELOW -- a 14-bolt full-sphere
         RING plus three staged explodes. DeathSound "Crack/death".
trigger  Missile   (A_Jump(255,"Bolt1","Fires5") at :754 -- a coin flip
                    between this and the shotgun)
range    --
mirrored yes -- the second shot runs the opposite-arm frame set
inherit  --
profile  MakeBurst(proj:"RS_FireBluHKBall1", count:2, delayTics:16, arc:18)
notes    RS_FireBluHKBall1 is Radius 20 / Mass 600 / Speed 15 -- a slow,
         fat orb. It trails RS_FireBluHKBall3 (a weaving random(5,10)
         mini-bolt with A_BishopMissileWeave that self-destructs on
         A_Jump(4)) on every 3-tic Spawn frame.
```

```
ATTACK   RS_FireBluHK2.Fires5
file     zscript/monsters/hellknight/RS_HellKnight.zs:766
shape    SCATTER
payload  RS_FireBluHKBall2 x20
arc      random(-25,25) yaw AND random(-15,15) pitch on every shot --
         a 50 x 30 degree cone
timing   12-tic aim; then 6 on tic 0, 4 over 4 tics, 6 more on tic 0, 4
         over 4 tics -- **20 rounds in 8 tics**; 10-tic recovery; 30 total
damage   DamageFunction (random(5,10)) each   [FX:456]
type     Plasma
sound    --
impact   BAL1 CDE 6 A_Explode(random(1,7),128) -- per-frame, so THREE
         explodes per bolt over 18 tics. DeathSound "imp/shotx".
trigger  Melee AND Missile -- **`Melee:` at :763 is a bare label that falls
         straight into `Fires5:`**, so this is BOTH the melee answer and
         half the ranged answer.
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_FireBluHKBall2", count:20, delayTics:0, arc:50,
                   pitchJitter:30)
notes    This is the family's shotgun: 20 x random(5,10) = 100..200 raw,
         plus 60 per-frame explodes if every bolt lands. At melee range it
         is the highest burst in the whole family below the Terminators.
         Note the FireBluHK's Pain.AbyssPE (:773) morphs it into
         RS_AbyssHK2 -- see the shared Pain.AbyssPE row at the end.
```

---

# TIER 8 -- `RS_GrayHK2` ("Gray knight")

Health 800, Speed 15, PainChance 16. CH `Hellknights.txt:1020`.

```
ATTACK   RS_GrayHK2.Bolt3
file     zscript/monsters/hellknight/RS_HellKnight.zs:884
         (mirror half Bolt4 at :889)
shape    SCATTER
payload  RS_MolochNail x1 per pass
arc      random(-1,1)
timing   16-tic windup (8,8), shot on an 8-tic state; 24 tics between
         shots across the Bolt3<->Bolt4 loop (A_Jump 128 / 76)
damage   DamageFunction (random(10,30))   [cacodemon FX:175]
type     Fire
sound    --   (RS_MolochNail has no SeeSound; its AttackSound
              "moloch/nailhitbleed" fires on hit, via +SPAWNSOUNDSOURCE)
impact   6PUF A_PlaySound("moloch/nailhit"), then
         6PUF ABCDEF 1 A_Explode(random(2,10),64) -- SIX per-frame
         explodes -- then FBL1 EFG 1 A_Explode(random(5,20),64) -- THREE
         more -- then RS_PuffCybieRed. DeathSound "weapons/firex4".
         **Nine explosions per nail.** Decal "BulletChip".
trigger  Missile   (A_Jump(255,"Bolt3") -- the far branch;
                    `Melee:` at :860 is a bare label falling into `Missile:`)
range    600..   (Missile A_JumpIfCloser(600,"Fire3") takes the near half)
mirrored yes -- Bolt3/Bolt4 are the two arms
inherit  RS_MolochNail -> cacodemon FX (RS_CacodemonFX.zs:169). The whole
         nine-explode Death chain and the "moloch/nailhit" sound are there.
         Reading this site alone reports a plain nail with no impact.
profile  MakeBurst(proj:"RS_MolochNail", count:2, delayTics:24, arc:2)
         + p.MinRange = 600
notes    "moloch/nailhit" is a KNOWN VERBATIM HOLE -- CH's $random members
         for it are missing lumps (documented at RS_HellKnightFX.zs:44).
         Silent in CH too.
```

```
ATTACK   RS_GrayHK2.Fire3
file     zscript/monsters/hellknight/RS_HellKnight.zs:894
shape    SCATTER
payload  RS_MinesHK x3
arc      random(-1,1), random(-9,9), random(-25,25) -- widening hard
timing   10-tic aim, mine 1 on a 9-tic state, 12-tic re-aim, mine 2 on 9,
         12-tic re-aim, mine 3 on 9; 21 tics between mines; 61 total
damage   DamageFunction (random(5,20)) direct   [RS_HellKnightFX.zs:513]
type     Fire
sound    --   (SeeSound "monster/dknmsl" belongs to the mine)
impact   SEE `RS_MinesHK.Death` BELOW -- a 12-nail 360 RING.
         DeathSound "weapons/boom1".
trigger  Missile   (A_JumpIfCloser(600,"Fire3") at :863; `Melee:` falls
                    into `Missile:` so this is also the melee answer)
range    ..600
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_MinesHK", count:3, delayTics:21, arc:50)
         + p.MaxRange = 600
notes    RS_MinesHK is a BOUNCING mine: BounceType "Doom", BounceCount 25,
         BounceFactor 0.95, **WallBounceFactor 1.1 (it gains energy off
         walls)**, Gravity 0.3, -NOGRAVITY, +BOUNCEONWALLS, +THRUGHOST,
         BounceSound "fire/fire3". It also self-detonates on
         A_Jump(4,"Death") every 12-tic Spawn cycle, so it has a random
         fuse independent of contact. Speed 32, RenderStyle SoulTrans.
```

---

# TIER 1 -- `RS_CommonHK` ("HellKnight")

`: HellKnight`, no Health/Speed override -> vanilla 500 / 8.
CH `Hellknights.txt:1171`.

```
ATTACK   RS_CommonHK.Missile
file     zscript/monsters/hellknight/RS_HellKnight.zs:959
shape    COMBO
payload  BaronBall x1   (vanilla; only when NOT in melee range)
arc      --   (A_BruisAttack uses SpawnMissile, dead-on aimed)
timing   16-tic windup (8,8), the attack on an 8-tic state; 24 total
damage   melee half: random(1,8) * 10  -- i.e. 10..80, in tens
         missile half: BaronBall Damage 8 (a flat 8*random(1,8) applied by
         the engine's missile damage roll)
type     Melee for the melee half; BaronBall carries no DamageType
sound    "baron/melee" on the melee half only; BaronBall's SeeSound
         "baron/attack" on the missile half
impact   BaronBall: BAL7 CDE 6 fade, DeathSound "baron/shotx",
         Decal "BaronScorch". No explode.
trigger  Melee AND Missile -- `Melee:` at :955 is a bare label falling into
         `Missile:`, so A_Chase routes both here and A_BruisAttack picks
range    --   (the melee/missile split is A_BruisAttack's own
              CheckMeleeRange, at the Actor default 44)
mirrored no
inherit  RS_CommonHK : HellKnight -- Health 500, Speed 8, PainChance 50,
         Radius 24, Height 64, Mass 1000 all come from the engine parent
         (E:\UZDXREMA\wadsrc\static\zscript\actors\doom\bruiser.zs:60-90)
profile  MakeVolley(proj:"BaronBall", count:1, fireSnd:"baron/attack")
         + a MakeMelee(range:44, fireSnd:"baron/melee") sibling; RS_ATK has
           no combo mode, so this is two slot entries with a range band
notes    The ONLY unmodified vanilla attack in the family. Everything else
         is CH content. Useful as the family's calibration baseline.
         A_BruisAttack body: bruiser.zs:153-171.
```

---

# TIER 2 -- `RS_GreenHK` ("Green HellKnight")

`: HellKnight`. Health 600, Speed 9. CH `Hellknights.txt:1274`.

```
ATTACK   RS_GreenHK.Missile
file     zscript/monsters/hellknight/RS_HellKnight.zs:1061
shape    COMBO
payload  BaronBall x1 (missile half only)
arc      --
timing   16-tic windup (8,8), attack on an 8-tic state, 2-tic tail; 26 total
damage   A_CustomComboAttack("BaronBall", 32, 11 * random(1,8), "baron/melee")
         -> melee half 11 * random(1,8) = 11..88
         -> missile half is a plain BaronBall (Damage 8)
type     Melee (engine substitutes it for the omitted damagetype)
sound    "baron/melee" (melee half); "baron/attack" (BaronBall SeeSound)
impact   BaronBall: BAL7 CDE fade, "baron/shotx", Decal "BaronScorch"
trigger  Melee AND Missile -- `Melee:` at :1057 falls into `Missile:`
range    --   (split at the Actor default MeleeRange 44)
mirrored no
inherit  RS_GreenHK : HellKnight
profile  MakeVolley(proj:"BaronBall", count:1, fireSnd:"baron/attack")
         + MakeMelee(range:44, fireSnd:"baron/melee", dmgMult:1.1)
notes    Tail A_Jump(164,"Missile2") -- ~64% of the time this chains into
         the LEAD shot below.
```

```
ATTACK   RS_GreenHK.Missile2   *** OWNER-APPROVED DEPARTURE FROM CH ***
file     zscript/monsters/hellknight/RS_HellKnight.zs:1083
shape    SINGLE
payload  BaronBall x1   -- fired by RS_HKLead.FireLead, NOT A_CustomMissile
arc      --   the yaw and pitch are SOLVED, not offset: the projectile is
         aimed at where the target WILL BE
timing   16-tic windup (8,8), the shot on an 8-tic state, 2-tic tail; 26
damage   BaronBall Damage 8 (vanilla)
type     --   (BaronBall sets no DamageType)
sound    --   the state is silent; BaronBall's SeeSound "baron/attack"
              is suppressed here, because RS_HKLead spawns the actor with
              Actor.Spawn + Vel3DFromAngle rather than a missile-spawn
              helper -- see notes
impact   BAL7 CDE 6 fade, DeathSound "baron/shotx", Decal "BaronScorch"
trigger  Missile   (A_Jump(164,"Missile2") from Missile; the Missile2 tail
                    A_Jump(128,"Missile") sends it back)
range    --
mirrored yes -- Missile uses one arm's frames, Missile2 the other
inherit  --
profile  MakeVolley(proj:"BaronBall", count:1) -- the LEAD SOLVE has no
         factory equivalent; a real port needs a `predictive` axis on
         RS_AttackProfile that does not exist yet. Flagged, not faked.
notes    **THIS IS A DELIBERATE DIVERGENCE. DO NOT "CORRECT" IT BACK.**
         Owner ruling, 2026-08-06; the reasoning is written at the site
         (RS_HellKnight.zs:1067-1082) and reproduced here:

         CH calls `ACS_NamedExecuteWithResult("BaronMissile")` with NO
         argument (CH Hellknights.txt:1319 -- verified verbatim this pass).
         CHACS.acs:54 inverts it -- `if(rand == 1)` is false, so the else
         branch runs ProjInt_Brute(..., rand=1, 0). miscFuncs.acs:114 is
         `if(rand){ random(1, sml_t); }` -- **the return value is
         DISCARDED**, so lead time `t` stays 0 and every lead term becomes
         FixedMul(0, targetVel). CH's hell knight therefore does NOT lead;
         it fires at the target's current position and is beaten by
         strafing. CH's baron and lost souls pass a different argument, hit
         the working branch, and DO predict. That asymmetry is a typo, not
         a design -- the author wrote one solver and called it for all
         three. The owner ruled to keep the intended behaviour.

         **OURS LEADS. CH's DOES NOT.** Both recorded, per the spec's
         "record BOTH and flag it".

         RS_HKLead.FireLead (RS_HellKnightFX.zs:97-138) solves the
         intercept quadratic exactly rather than brute-forcing it:
         qa = (v·v) - spd², qb = 2(d·v), qc = d·d, pick the smaller
         positive root. Speed matches CH: 15, or 20 under sv_fastmonsters
         (CHACS.acs:56-58). With no real root it falls back to a straight
         shot -- the same behaviour as CH's rand==1 branch.

         **CH-parity fallback exists and is one cvar away.** `Miss2:` at
         :1087 is `A_CustomComboAttack("BaronBall",32,11*random(1,8),
         "baron/melee")` -- byte-for-byte CH's Miss2 (CH :1323). It is
         reached by `A_JumpIf(RS_Zom.CV('rs_ch_intercept',0) == 1,"Miss2")`
         at :1066, our port of CH's `CallACS("CH_Intercept") == true`
         (CHSett.acs:84, CH default false). **Set `rs_ch_intercept 1` and
         the knight reverts to CH's non-leading combo.** So the departure
         is opt-out at runtime, not baked in.
```

---

# TIER 3 -- `RS_BlueHK` ("Blue HellKnight")

`: HellKnight`. Health 666, Speed 10, MeleeRange 54. CH `Hellknights.txt:1380`.

```
ATTACK   RS_BlueHK.Melee
file     zscript/monsters/hellknight/RS_HellKnight.zs:1191
shape    MELEE
payload  --
arc      --
timing   16-tic windup (8,8), hit on an 8-tic state; 24 total
damage   A_CustomMeleeAttack(random(10,70), "baron/melee")
type     Melee
sound    "baron/melee"
impact   --
trigger  Melee   (a real, separate Melee: label -- not folded into Missile)
range    ..54    (MeleeRange 54)
mirrored no
inherit  RS_BlueHK : HellKnight
profile  MakeMelee(range:54, fireSnd:"baron/melee")
notes    The windup states carry NO A_FaceTarget (unlike every other
         knight's melee) -- the blue knight commits to the swing.
```

```
ATTACK   RS_BlueHK.Missile
file     zscript/monsters/hellknight/RS_HellKnight.zs:1196
shape    SCATTER
payload  RS_BaronsBlueBalls x4
arc      random(-1,1), ±3, ±5, ±7 -- widening
timing   16-tic windup; firing states 8,6,4,3; gaps 20,14,10 -- an
         accelerating, widening four-round burst; 63 tics total
damage   DamageFunction (random(10,45))   [lostsoul FX:2128]
type     Plasma
sound    --   (SeeSound "baron/attack" per ball)
impact   PLSE CDE 3 fade. **NO A_Explode** -- contact damage only.
         DeathSound "weapons/plasmax".
trigger  Missile
range    --
mirrored yes -- alternates arm frame sets between all four shots
inherit  RS_BaronsBlueBalls -> lostsoul FX (RS_LostSoulFX.zs:2120); ceded
         there and diffed identical against CH Hellknights.txt:1491.
profile  MakeBurst(proj:"RS_BaronsBlueBalls", count:4, delayTics:14, arc:14)
notes    Speed 18 / FastSpeed 25, +RANDOMIZE, Alpha 0.85, Add.
         A_CheckSight("See") between shots 1-2 and 2-3 (but NOT 3-4), so
         the last two rounds fire even into a broken LOS.
```

---

# TIER 4 -- `RS_PurpleHK` ("Royal Purple HellKnight")

`: HellKnight`. Health 730, Speed 11, MeleeRange 54, RenderStyle SoulTrans.
CH `Hellknights.txt:1518`.

```
ATTACK   RS_PurpleHK.Melee
file     zscript/monsters/hellknight/RS_HellKnight.zs:1312
shape    MELEE
payload  --
arc      --
timing   16-tic windup (8,8), hit on an 8-tic state; 24 total
damage   A_CustomMeleeAttack(random(20,90), "baron/melee")
type     Melee
sound    "baron/melee"
impact   --
trigger  Melee
range    ..54
mirrored no
inherit  RS_PurpleHK : HellKnight
profile  MakeMelee(range:54, fireSnd:"baron/melee")
notes    Windup carries no A_FaceTarget, same as blue.
```

```
ATTACK   RS_PurpleHK.Bolt3
file     zscript/monsters/hellknight/RS_HellKnight.zs:1321
         (mirror half Bolt4 at :1342)
shape    SCATTER
payload  RS_HKBolt2 x1 per pass
arc      random(-1,1)
timing   16-tic windup, shot on an 8-tic state; 24 tics between shots
         across the Bolt3<->Bolt4 loop (A_Jump 128 / 76)
damage   DamageFunction (random(10,50))   [lostsoul FX:2157]
type     Plasma
sound    --   (SeeSound "caco/attack" per bolt)
impact   BAL2 C 2 SetScale(1.1), D 3 SetTranslucent(0.4),
         E 6 A_Explode(random(5,30), 88). DeathSound "caco/shotx".
trigger  Missile   (A_Jump(255,"Bolt3") -- the far branch)
range    300..    (Missile A_JumpIfCloser(300,"Fire3") takes the near half)
mirrored yes
inherit  RS_HKBolt2 -> lostsoul FX (RS_LostSoulFX.zs:2149); CH
         Hellknights.txt:1642, diffed identical.
profile  MakeBurst(proj:"RS_HKBolt2", count:2, delayTics:24, arc:2)
         + p.MinRange = 300
notes    **RS_HKBolt2 is a SEEKER and a weaver**: A_SeekerMissile(2,2) on
         one Spawn frame, A_Weave(3,1,5,0) on the next, every 6 tics.
         Speed 19 / FastSpeed 38, Scale 0.7. It snakes toward you.
```

```
ATTACK   RS_PurpleHK.Fbreath
file     zscript/monsters/hellknight/RS_HellKnight.zs:1351
shape    SCATTER
payload  RS_Purpfire2 x3 per pass
arc      random(-1,1), ±3, ±5
timing   4-tic aim, then 2,1,1,1,1,1 -- three bolts in 5 tics, then
         A_MonsterRefire(150,"See") reloops via Fire3; 11 tics per pass
damage   DamageFunction (random(5,10)) direct   [shotgunner FX:633]
type     Fire
sound    --   (SeeSound "fire/fire1" per bolt)
impact   **RS_Purpfire2 explodes on EVERY FRAME OF BOTH ITS STATES**:
         PFIR ABCD 5 A_Explode(random(3,10),20) while flying (4 frames)
         and PFIR EFFG 5 A_Explode(random(3,10),20) on death (4 frames)
         -- **8 explodes per bolt over 40 tics**. DeathSound "Imp/shotx".
trigger  Missile   (Missile -> A_JumpIfCloser(300,"Fire3");
                    Fire3 -> A_JumpIfCloser(300,"Fbreath"), i.e. the gate
                    is checked TWICE)
range    ..300
mirrored no
inherit  RS_Purpfire2 -> shotgunner FX (RS_ShotgunnerFX.zs:626); CH
         Shotgunners.txt:1375. Note the CASE: the class is `RS_Purpfire2`,
         the call sites write `RS_PurpFire2`. Same class -- ZScript is
         case-insensitive (CLAUDE.md).
profile  MakeBurst(proj:"RS_Purpfire2", count:3, delayTics:2, arc:10)
         + p.MaxRange = 300
notes    A flamethrower: slow bolts (Speed 16) that damage continuously
         along their path, not just on impact. The per-frame Spawn explode
         is what makes it a breath weapon rather than three bolts.
         `Fire3:` (:1345) is a pure re-gate -- A_JumpIfCloser(300,"Fbreath")
         then A_Jump(255,"See"). Not a row.
```

---

# TIER 5 -- `RS_YellowHK` ("Orange Bruiser")

`: HellKnight`. Health 999, Speed 10, MeleeRange 54, -NORADIUSDMG, +NOFEAR.
CH `Hellknights.txt:1674`.

```
ATTACK   RS_YellowHK.Melee
file     zscript/monsters/hellknight/RS_HellKnight.zs:1447
shape    MELEE
payload  --
arc      --
timing   12-tic windup (6,6), hit on a 6-tic state, 1-tic tail; 19 total
damage   A_CustomMeleeAttack(random(20,90), "baron/melee")
type     Melee
sound    "baron/melee"
impact   --
trigger  Melee
range    ..54
mirrored no
inherit  RS_YellowHK : HellKnight
profile  MakeMelee(range:54, fireSnd:"baron/melee")
notes    Tail A_Jump(88,"Missile") -- ~34% chance of chaining into the
         ranged tree.
```

```
ATTACK   RS_YellowHK.Rapidfire
file     zscript/monsters/hellknight/RS_HellKnight.zs:1457
         (mirror half Rapidfire2 at :1463)
shape    SCATTER
payload  RS_FireHKBall1 x1 per pass
arc      random(-1,1)
timing   8-tic windup (4,4), shot on a 2-tic state, 1-tic refire check;
         **11 tics between shots** -- the fastest sustained cadence of
         any non-boss knight; A_MonsterRefire(128,"See") sustains it
damage   DamageFunction (random(10,40))   [lostsoul FX:2190]
type     Fire
sound    --   (SeeSound "imp/attack" per ball)
impact   BRB2 CDEFGHI 3 A_Explode(random(2,6), 32) -- SEVEN per-frame
         explodes over 21 tics. DeathSound "imp/shotx". Decal "BaronScorch".
trigger  Missile   (A_Jump(255,"Rapidfire","Boom") at :1452 -- coin flip
                    against the Boom row)
range    --
mirrored yes -- Rapidfire / Rapidfire2 are the two arms
inherit  RS_FireHKBall1 -> lostsoul FX (RS_LostSoulFX.zs:2183); CH
         Hellknights.txt:1802, diffed identical.
profile  MakeBurst(proj:"RS_FireHKBall1", count:2, delayTics:11, arc:2)
notes    The ball trails RS_SparkPuff1 on every 6-tic Spawn frame -- via
         `A_CustomMissile("RS_SparkPuff1",1,0,CMF_AIMOFFSET,random(0,360),
         random(0,360))`, which is another **[CMF-SLOT]** site (see the
         engine-facts block). Cosmetic either way.
         The 7-frame Death explode is one of CLAUDE.md's ~55 deliberate
         multi-frame explodes -- a fizzling burst. Do not collapse it.
```

```
ATTACK   RS_YellowHK.Boom
file     zscript/monsters/hellknight/RS_HellKnight.zs:1495
shape    SINGLE
payload  RS_BigHK x1   +  RS_SparkPuff1 x8 (cosmetic)   [CMF-SLOT]
arc      the BigHK is fired at yaw 0, dead on
timing   1-tic face; 12-tic roar; 8 sparks over 4 tics; 24-tic re-aim;
         the BigHK on a 10-tic state; 8-tic recovery; 59 tics total
damage   DamageFunction (random(10,77))   [lostsoul FX:2218]
type     Fire
sound    "superbaron/scream" on the 12-tic wind-up (:1485)
impact   RS_BigHK.Death: three RS_BigHK3 fired at random yaw AND pitch
         (**[CMF-SLOT]** -- see engine facts), then BRB2 FGHI 3
         A_Explode(random(2,6),32) per-frame ×4. DeathSound "weapons/rocklx".
         RS_BigHK3 each: DamageFunction (random(15,45)), Fire, +NOCLIP,
         Speed 12, A_Explode(random(5,21), 88) then a 19-frame bloom.
         RS_BigHK's own TRAIL is RS_BigHK2 (spawned every 2 tics of flight,
         Speed 0, DamageFunction (random(15,45)), A_Explode(random(5,21),
         100)) -- so the shot leaves a **line of detonating mines behind
         it** for its whole flight, not just at impact.
trigger  Missile   (A_Jump(255,"Rapidfire","Boom")) / Pain
         (A_Jump(64,"Boom") at :1501)
range    --
mirrored no
inherit  RS_BigHK / RS_BigHK2 / RS_BigHK3 -> lostsoul FX
         (RS_LostSoulFX.zs:2211 / :2243 / :2269); CH Hellknights.txt
         :1827 / :1856 / :1879. The whole detonation, the trail-mine
         chain and the sounds are all written there. Reading the Boom
         state alone reports a single fireball.
profile  MakeHeavy(proj:"RS_BigHK", fireSnd:"superbaron/scream",
                   bigMuzzle:true, spawnHeight:32)
         + p.FireTrigger = RS_FIRE_PAIN for the Pain-retaliation copy
notes    RS_BigHK is Scale 2 -- the biggest single round the mid-tier
         knights carry. Between the trail mines, the three sub-fireballs
         and the four per-frame explodes, one Boom is worth
         random(10,77) + 3*random(15,45) + a lot of splash.
         The 8 sparks are cosmetic (RS_SparkPuff1 has no Damage,
         +NOINTERACTION -- shotgunner FX:209) and are fired at ±34
         spawnofs_xy, i.e. off both shoulders.
```

---

# TIER 6 -- `RS_RedHK` ("Red Knightmare")

`: HellKnight`. Health 1300, Speed 11, Scale 1.15, MeleeRange 54, Alpha 0.9.
CH `Hellknights.txt:1902`.

```
ATTACK   RS_RedHK.Spawn
file     zscript/monsters/hellknight/RS_HellKnight.zs:1567
shape    UNCLASSIFIED   (escort summon, fires on arrival)
payload  RS_SpecialImp x8
arc      --   spawned at four fixed body offsets (0,∓5,+6) and (∓5,±5,+6),
         each used twice, with SXF_SETMASTER
timing   eight consecutive 1-tic states; 8 tics, once, before Idle
damage   --   (the imps carry their own; see the minion row)
type     --
sound    --
impact   --
trigger  Spawn
range    --
mirrored no
inherit  RS_SpecialImp : RS_BlueImp (imp lane, RS_Imp.zs:1073) --
         its Melee and Missile are the BLUE IMP's, catalogued in the imp
         family, not here.
profile  MakeSummon(summonCls:"RS_SpecialImp", count:8, cap:8,
                    tierOffset:-3)
notes    **The Red Knightmare never fights alone.** The eight imps are
         master-tethered: RS_SpecialImp's See state ends with
         `A_JumpIfMasterCloser(1000,"See")` then
         `A_Warp(AAPTR_MASTER,5,1,6,0,WARPF_NOCHECKPOSITION)` -- if the
         master drifts past 1000 units the imp TELEPORTS back to it every
         2 tics. They cannot be kited away from him.
         RS_SpecialImp: Health 90, -COUNTKILL, +THRUSPECIES,
         +NOTARGETSWITCH, Species "BaronOfHell". FX:615.
```

```
ATTACK   RS_RedHK.Melee
file     zscript/monsters/hellknight/RS_HellKnight.zs:1611
shape    MELEE
payload  --
arc      --
timing   12-tic windup (6,6), hit on a 6-tic state, 1-tic tail; 19 total
damage   A_CustomMeleeAttack(random(20,99), "baron/melee")
type     Melee
sound    "baron/melee"
impact   --
trigger  Melee
range    ..54
mirrored no
inherit  RS_RedHK : HellKnight
profile  MakeMelee(range:54, fireSnd:"baron/melee", dmgMult:1.1)
notes    random(20,99) -- the highest single melee roll below the bosses.
         Tail A_Jump(88,"Missile").
```

```
ATTACK   RS_RedHK.DoT
file     zscript/monsters/hellknight/RS_HellKnight.zs:1623
shape    SINGLE
payload  RS_THEBEEHK x1  +  RS_EffectHK x1 (cosmetic muzzle burst)
arc      --   fired at yaw 0
timing   6-tic face, 16-tic windup (8,8), the bee on a 1-tic state, the
         cosmetic on the following 9-tic state; 32 tics total
damage   DamageFunction (random(1,3)) direct   [lostsoul FX:2302]
         **plus A_Explode(random(1,2), 42) ON EVERY OTHER FLIGHT FRAME**
type     --   (RS_THEBEEHK sets no DamageType; the A_Explode inherits it)
sound    --   (SeeSound "weapons/firmfi" per bee)
impact   CBAL CCDDEEFFGG 1 -- **10 x RS_THEBEEHK2 spawned over 10 tics**,
         each a mini seeker: DamageFunction (random(1,2)), Speed 23,
         Scale 0.35, +SEEKERMISSILE +THRUACTORS +THRUGHOST,
         A_SeekerMissile(32,255,SMF_PRECISE|SMF_LOOK,255) and
         A_Explode(1,22) on every other frame, self-destructing on a
         random A_Jump(12). DeathSound "weapons/firex4".
trigger  Missile   (A_Jump(255,"DoT","BoilBolt") at :1617; also reached
                    from BoilBolt/BoilBolt2 tails via A_Jump(22,"DoT"))
range    --
mirrored no
inherit  RS_THEBEEHK / RS_THEBEEHK2 -> lostsoul FX
         (RS_LostSoulFX.zs:2295 / :2324); CH Hellknights.txt:2131 / :2157.
         **Everything that makes this attack dangerous is written there**:
         the hard seeker, the per-frame graze DoT and the ten-swarm split.
         The DoT state itself reads as a 3-damage pea-shooter.
profile  MakeVolley(proj:"RS_THEBEEHK", count:1, fireSnd:"weapons/firmfi")
notes    **This is the family's damage-over-time round and its name says
         so.** Direct random(1,3) is deliberately trivial; the weapon is
         A_SeekerMissile(32,255,SMF_PRECISE) -- 32 degrees of turn per tic,
         255 max -- which effectively cannot be dodged, combined with a
         1-2 damage explode every other tic of flight, and a ten-way split
         of the same thing on death.
         RS_EffectHK (imp FX:365) is cosmetic: Speed 0, +NOINTERACTION,
         one frame then A_Burst("RS_RedThingsHK") gib spray. Its sprite is
         our correction of CH's `VBAL` typo to `CBAL`.
```

```
ATTACK   RS_RedHK.BoilBolt
file     zscript/monsters/hellknight/RS_HellKnight.zs:1628
         (mirror half BoilBolt2 at :1634)
shape    SCATTER
payload  RS_BloodBoltHK x1 per pass
arc      random(-1,1)
timing   12-tic windup (6,6), shot on a 3-tic state, 2-tic refire, 1-tic
         DoT check; **18 tics between shots**; sustained by
         A_MonsterRefire(128,"See")
damage   DamageFunction (random(10,54))   [RS_HellKnightFX.zs:588]
type     Plasma
sound    --   (SeeSound "Spell/spellCast1" per bolt)
impact   BAL1 C 4 SetTranslucent(0.35), D 5 A_Explode(random(2,14),32),
         E 5 A_Explode(random(2,14),44) -- two staged blasts.
         DeathSound "fire/Fire4".
trigger  Missile   (A_Jump(255,"DoT","BoilBolt"))
range    --
mirrored yes -- BoilBolt / BoilBolt2 are the two arms
inherit  --
profile  MakeBurst(proj:"RS_BloodBoltHK", count:2, delayTics:18, arc:2)
notes    Trails RS_REDTHINGSHK on every 4-tic Spawn frame via
         `A_CustomMissile("RS_REDTHINGSHK",3,0,CMF_AIMOFFSET,random(0,360),
         random(0,360))` -- another **[CMF-SLOT]** site. RS_RedThingsHK
         (zombieman FX:816) is cosmetic: no Damage, +THRUACTORS, Scale 0.2.
         Both BoilBolt tails carry A_Jump(22,"DoT") -- ~9% per shot of
         switching to the bee swarm.
```

```
ATTACK   RS_RedHK.Enrage
file     zscript/monsters/hellknight/RS_HellKnight.zs:1642
shape    UNCLASSIFIED   (one-shot self-buff; fires nothing damaging)
payload  RS_EffectHK x5 (cosmetic -- x2 at +48, x3 at +24)
arc      --
timing   1-tic gate, 1-tic NOPAIN, 12-tic roar, 24 tics of cosmetics
         (12,12), 10-tic flag set, 6 tics (2,2,2), 8-tic tail; 62 total
damage   --
type     --
sound    "superbaron/scream" (:1641)
impact   --
trigger  Missile   (A_JumpIfHealthLower(800,"Enrage") is the FIRST line of
                    Missile at :1615, so it pre-empts the whole ranged tree)
range    --
mirrored no
inherit  --
profile  MakeSelfBuff(speedMult:1.0, damageMult:1.0, duration:-1,
                      noPain:true, fireSnd:"superbaron/scream")
notes    Sets `bNOPAIN = true` and `bMISSILEEVENMORE = true`. **Neither is
         ever cleared** -- the buff is permanent for the rest of the
         monster's life. `user_Rage2` guards it to one use; the guard
         branch `Nah:` (:1647) is a 1-tic no-op that resumes Missile+1.
         MISSILEEVENMORE is one of the deprecated-but-unfixable flags per
         CLAUDE.md -- there is no Property binding, so the flag is the only
         way to set it. Do not try to "modernise" it.
         Duration -1 in the profile line means "permanent"; MakeSelfBuff's
         `duration` field has no permanent sentinel, so this does not port
         cleanly. Flagged.
```

```
ATTACK   RS_RedHK.Death
file     zscript/monsters/hellknight/RS_HellKnight.zs:1664
shape    SCATTER
payload  RS_HKRedDeath x10   [CMF-SLOT]
arc      spawnofs_xy alternates -30, 50, 30, 5, 50, 5, 50, 30, 5, -30;
         **the yaw argument is the literal CMF_AIMOFFSET, i.e. 1 degree,
         for all ten** -- see the engine-facts block. flags = 2
         (CMF_AIMDIRECTION), pitch = -10 / +10 alternating.
         spawnheight cycles 100, 100, 20, 60, 100, 60, 100, 20, 60, 100.
timing   6-tic scream, then detonations on states of 4,2,4,4,4 tics, a
         5-tic A_Fall, then 4,4,4,4,2; 41 tics of continuous detonation,
         then a 21-tic corpse settle
damage   A_Explode(random(5,10), 42) each   [zombieman FX:862]
type     Fire
sound    "world/barrelx" twice per detonation (Spawn and mid-Death),
         over the DeathSound "superbaron/death"
impact   MISL B 8 A_Explode(random(5,10),42), MISL C 6 second barrelx,
         MISL D 3 A_Burst("RS_RedThingsHK") -- a gib spray of the cosmetic
         red motes.
trigger  Death
range    --
mirrored no
inherit  RS_HKRedDeath -> zombieman FX (RS_ZombiemanFX.zs:844)
profile  MakeBurst(proj:"RS_HKRedDeath", count:10, delayTics:4, arc:2,
                   trigger:RS_FIRE_DEATH)
notes    **A death that keeps killing for 41 tics.** Ten separate 42-radius
         blasts around the corpse -- with -NORADIUSDMG cleared on this
         actor, so it damages itself too, though it is already dying.
         Compare RS_BlackHK2.Death / RS_BlackHKEX.Death: same payload,
         same [CMF-SLOT] shape, but those use `random(-30,30)` for the
         spawnofs and `random(20,100)` for the height -- randomised where
         the Red Knightmare's are FIXED literals. Both are SCATTER under
         the mapping table; the fixed-vs-random difference is recorded
         here so it is not lost.
         The corpse then plays TROO QRST / TROO U -- imp frames, because
         BRUR ships no gib set. Faithful to CH.
```

---

# TIER 10 -- `RS_BlackHK2` ("Terminator")

Health 5555, Speed 6, Scale 1.33, +BOSS, MeleeDamage 13, MeleeRange 68,
RadiusDamageFactor 0.25. CH `Hellknights.txt:2290`.

```
ATTACK   RS_BlackHK2.See
file     zscript/monsters/hellknight/RS_HellKnight.zs:1753
shape    UNCLASSIFIED   (spin-up VFX; deals no damage)   [CMF-SLOT]
payload  RS_SparkPuff1 x11 (cosmetic)
arc      spawnheight random(12,66), spawnofs_xy random(-20,20);
         **yaw is the literal CMF_AIMOFFSET = 1 degree**, flags =
         random(0,360), pitch = random(0,360) -- see engine facts
timing   8-tic face, then sparks on states of 5,4,5,3,3,2,2,1,1,1,1 --
         **an accelerating ramp**; 36 tics, once, then See2 forever
damage   --
type     --
sound    --
impact   PUFF ABAB 4 fade. +NOINTERACTION, +NOGRAVITY, VSpeed 4.
trigger  See   (the FIRST time it sees a target; See2 is the steady state
                and never returns here)
range    --
mirrored no
inherit  RS_SparkPuff1 -> shotgunner FX (RS_ShotgunnerFX.zs:209)
profile  MakeVolley(proj:"RS_SparkPuff1", count:11, arc:40) with
         p.FireTrigger = RS_FIRE_SPAWN and dmgMult 0
notes    **A pure telegraph.** The accelerating 5->1 tic ramp reads as a
         machine booting. As a weapon part this is a *spin-up* profile:
         a cosmetic emitter with a ramp, worth having in the bin for
         charge weapons even though it damages nothing.
         See2 also plays "monster/bruwlk" every chase cycle -- footsteps.
```

```
ATTACK   RS_BlackHK2.LaserShot1
file     zscript/monsters/hellknight/RS_HellKnight.zs:1787
shape    SCATTER
payload  RS_SwooshCBBar1 x6 per pass  +  RS_BluCybFX x4 (cosmetic flare)
arc      three beams at random(-7,7), then three at random(-14,14)
timing   4-tic aim; 2 flares over 8 tics; 3 beams 4 tics apart; 2-tic
         re-aim; 2 flares; 3 beams 4 tics apart; 2-tic refire check;
         48 tics per full pass, looping on A_MonsterRefire(128,"See2")
damage   DamageFunction (random(10,40))   [RS_HellKnightFX.zs:682]
type     Plasma
sound    "prox/beep" once at the head of the state (:1784)
impact   SEE `RS_SwooshCBBar1.Death` BELOW -- three per-frame explodes
         and a **ninety-bolt 360 RING**. DeathSound "weapons/bfgx".
trigger  Missile   (only via MisMode2, which requires
                    A_JumpIfInventory("RS_BrusMode",3) -- see the Mode note)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_SwooshCBBar1", count:6, delayTics:4, arc:28,
                   fireSnd:"prox/beep")
notes    RS_SwooshCBBar1 is Speed 36, Scale 0.6, +RANDOMIZE, Add,
         SeeSound "Litn/litn3". It trails RS_SwooshCBTR every tic, which
         trails RS_SwooshCBTR2, and BOTH of those A_Explode on both of
         their two Death frames (random(5,20)/32 and random(5,15)/32) --
         so the beam leaves a **corridor of small blasts** behind it.
         RS_SwooshCBTR / TR2 are CH CYBIES.txt:2618 / :2645 externals that
         ship in our HK FX file (FX:707 / :734).
         **MODE GATE**: A_JumpIfInventory("RS_BrusMode",3,"MisMode2") at
         :1777. RS_BrusMode is an Inventory item, MaxAmount 3 (FX:667),
         given by `Mode1:` and taken by `Mode2:`, both reached from Pain
         (A_Jump(256,"Mode1","Mode2") at :1843) and from See2
         (A_Jump(8,...) at :1772). So the Terminator FLIPS LOADOUTS on
         being hurt: without the item it uses BigMis/ClusterMis/NadeToss,
         with it LaserShot1/DeathBeam/NadeToss.
```

```
ATTACK   RS_BlackHK2.DeathBeam
file     zscript/monsters/hellknight/RS_HellKnight.zs:1799
shape    SINGLE
payload  RS_MegaRedRev x1  +  RS_RedRevLoad x1 (cosmetic charge flare)
arc      random(-1,1)
timing   24-tic lock-on (12,12), 8-tic charge flare, 6-tic re-aim, the
         beam on a 6-tic state, 5-tic tail; 49 tics total
damage   DamageFunction (random(35,95))   [RS_HellKnightFX.zs:791]
type     Plasma
sound    "prox/beep" on the tic before the charge flare (:1796)
impact   BLL9 CDE 6 A_Explode(random(15,55), 64) -- per-frame ×3, so
         **three blasts of up to 55 each**. DeathSound "Litn/litn3".
trigger  Missile   (MisMode2 branch only)
range    --
mirrored no
inherit  RS_MegaRedRev is CH Revenants.txt:2855, shipped here (FX:784).
         RS_RedRevLoad -> chaingunner FX (RS_ChaingunnerFX.zs:230).
profile  MakeHeavy(proj:"RS_MegaRedRev", fireSnd:"prox/beep",
                   bigMuzzle:true, spawnHeight:38)
notes    **Speed 90 -- the fastest projectile in the family.** Scale 1.5,
         Add, Alpha 0.8, SeeSound "Crack/see". It trails RS_RedRevLoad2
         every tic, which itself spawns RS_RedRevLoad -- a double-layer
         cosmetic charge chain (FX:812).
         The state also drops **two `Cell` pickups** at :1800-1801, thrown
         out at (3,3,3) velocity. A boss that pays you ammo for surviving
         its own beam. Faithful to CH:2404-2405.
         Tail A_Jump(60,"LaserShot1") chains into the beam sweep.
```

```
ATTACK   RS_BlackHK2.BigMis
file     zscript/monsters/hellknight/RS_HellKnight.zs:1806
shape    SCATTER
payload  RS_BruiserMissile x3
arc      0, random(-3,3), random(-7,7) -- widening
timing   missile 1 on a 12-tic state, 20-tic re-aim, missile 2 on 7,
         20-tic re-aim, missile 3 on 7; gaps 32 and 27; 67 tics total
damage   DamageFunction (random(20,75))   [RS_HellKnightFX.zs:947]
type     Fire
sound    "prox/beep" before EACH of the three (:1805, :1809, :1813)
impact   BAL3 C 6 SetScale(1.5), D 6 A_Explode(random(20,75),128,0),
         E 6. **flags = 0 means NOT XF_HURTSOURCE -- it will not hurt the
         Terminator.** Reinforced by `DontHurtShooter true` in the Default
         block. DeathSound "weapons/hellex". Decal "Scorch".
trigger  Missile   (default branch: A_Jump(256,"BigMis","ClusterMis",
                    "NadeToss") at :1778, i.e. WITHOUT RS_BrusMode)
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_BruiserMissile", fireSnd:"prox/beep",
                   bigMuzzle:true, spawnHeight:38) x3 as a burst, or
         MakeBurst(proj:"RS_BruiserMissile", count:3, delayTics:30,
                   arc:14, fireSnd:"prox/beep")
notes    `DontHurtShooter true;` is the ZScript PROPERTY form, not a flag
         (engine actor.zs:310) -- see CLAUDE.md. Do not delete it; it is
         what stops the Terminator killing itself at close range.
         Trails RS_BruiserTrail (FX:973, cosmetic PUFF fade) every other
         Spawn tic. +THRUGHOST, Speed 20, Scale 1.15.
         The state also drops a `RocketBox` pickup at :1815.
         Tail A_Jump(60,"ClusterMis").
```

```
ATTACK   RS_BlackHK2.ClusterMis
file     zscript/monsters/hellknight/RS_HellKnight.zs:1819
shape    SCATTER
payload  RS_SpreadMisBar1 x4
arc      random(-5,5), ±14, ±7, ±16 -- alternating tight/wide pairs
timing   9,5 then a 15-tic re-aim then 9,5; gaps 9,20,9; 44 tics total
damage   DamageFunction (random(10,40))   [RS_HellKnightFX.zs:916]
type     Fire
sound    --   (SeeSound "weapons/hominglaunch" per missile)
impact   SEE `RS_SpreadMisBar1.Death` BELOW -- an explode plus four
         RS_MolochNail sub-munitions. DeathSound "weapons/homingexplode".
trigger  Missile   (default branch)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_SpreadMisBar1", count:4, delayTics:11, arc:32)
notes    Despite the "homing" sounds RS_SpreadMisBar1 has NO
         +SEEKERMISSILE -- it flies straight (Speed 17) and self-destructs
         on A_Jump(10,"Death") every 2 tics, so it has a **random fuse**
         and often airbursts short. Trails RS_HomingRocketTrailFatso
         (lostsoul FX, CH Fatsos.txt:2202).
         The state drops three `Shell` pickups at :1825.
         Tail A_Jump(42,"Missile") -- back to the top of the table.
```

```
ATTACK   RS_BlackHK2.NadeToss
file     zscript/monsters/hellknight/RS_HellKnight.zs:1830
shape    SINGLE
payload  RS_BaronNade x1
arc      random(-9,9) yaw, pitch random(3,12) -- **a deliberate downward
         lob** (positive pitch is down in this argument)
timing   14-tic windup (7,7), the throw on a 9-tic state, 1-tic tail; 24
damage   DamageFunction (random(20,75)) direct   [RS_HellKnightFX.zs:876]
type     Fire
sound    --   SeeSound "weapons/grenlf" is a KNOWN VERBATIM HOLE: the
              lump is absent from CH's SNDINFO entirely, so it is silent
              in CH too. BounceSound "prox/beep" DOES play on every bounce.
impact   SEE `RS_BaronNade.Death` BELOW -- an explode plus **fourteen
         seeking RS_BaronStar3**. DeathSound "weapons/grenlx", also a
         missing lump.
trigger  Missile   (present in BOTH branches of the mode table -- the only
                    attack the Terminator keeps in either loadout)
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_BaronNade", bigMuzzle:false, spawnHeight:38)
notes    A real bouncing grenade: BounceType "Doom", BounceCount 15,
         **BounceFactor 1.15 (it gains energy on floor bounces)**,
         WallBounceFactor 0.7, Gravity 0.29, +GRENADETRAIL, -NOGRAVITY.
         Its Spawn loop is A_Jump(12,"Bounce") then A_Jump(4,"Death") every
         3 tics, so it has a **random fuse AND a random re-thrust**: the
         Bounce state is `ThrustThing(int(angle*256/(random(1,360))),12,0,0)`,
         which shoves it at a chaotic angle. Unpredictable by design.
         The `HGRN` sprite is OUR correction of CH's `SGRN` typo (evidence
         at RS_HellKnightFX.zs:58-83). CH and CHP are both still broken
         here. Recorded as a deliberate divergence, art-only.
```

```
ATTACK   RS_BlackHK2.Melee
file     zscript/monsters/hellknight/RS_HellKnight.zs:1836
shape    MELEE
payload  --
arc      --
timing   16-tic windup (8,8), hit on a 6-tic state; 22 total
damage   A_MeleeAttack -> random(1,8) * MeleeDamage = **random(1,8) * 13**
         (engine attacks.zs:819; MeleeDamage 13 set in the Default block)
type     Melee
sound    MeleeSound "baron/melee" (the Default property; A_MeleeAttack
         plays it, the state does not name it)
impact   --
trigger  Melee
range    ..68   (MeleeRange 68)
mirrored no
inherit  --
profile  MakeMelee(range:68, fireSnd:"baron/melee", dmgMult:1.3)
notes    **The damage roll lives in a PROPERTY, not the state.** Anyone
         reading only `BRUC I 6 A_MeleeAttack;` sees no number at all.
         13..104, in thirteens.
         A_MeleeAttack is deprecated ("Use CustomMeleeAttack instead") but
         functional; CH writes it and we transcribe it. Tail
         A_Jump(128,"Missile").
```

```
ATTACK   RS_BlackHK2.Death
file     zscript/monsters/hellknight/RS_HellKnight.zs:1852
shape    SCATTER
payload  RS_HKRedDeath x11   [CMF-SLOT]
arc      spawnheight random(20,100), spawnofs_xy random(-30,30);
         **yaw is the literal CMF_AIMOFFSET = 1 degree**; flags = 2,
         pitch = -10
timing   3 detonations over 12 tics, an 8-tic scream, 6 over 36 tics,
         a 6-tic A_NoBlocking, 2 over 12 tics, 6-tic settle, then a
         permanent A_BossDeath frame; ~80 tics of dying
damage   A_Explode(random(5,10), 42) each
type     Fire
sound    "world/barrelx" ×2 per detonation, under DeathSound
         "monster/brudth"
impact   as RS_RedHK.Death
trigger  Death
range    --
mirrored no
inherit  RS_HKRedDeath -> zombieman FX
profile  MakeBurst(proj:"RS_HKRedDeath", count:11, delayTics:6, arc:2,
                   trigger:RS_FIRE_DEATH)
notes    The final frame is `A_BossDeath` -- this is a +BOSS actor, so its
         death fires map specials. Identical chain in RS_BlackHKEX.Death.
```

---

# TIER 10 EX -- `RS_BlackHKEX` ("Terminator MK II")

Health 11000, Speed 14 (18 after Phase2), XScale 1.25 / YScale 1.5, +BOSS,
RadiusDamageFactor 0.33. CH `Hellknights.txt:2639`.

```
ATTACK   RS_BlackHKEX.See
file     zscript/monsters/hellknight/RS_HellKnight.zs:1937
shape    UNCLASSIFIED   (boot sequence; deals no damage)
payload  RS_ZapDecHKex x8 (cosmetic)
arc      spawnheight random(12,88), spawnofs_xy random(-20,20), yaw 0
timing   8-tic face, then zaps on states of 5,4,5,3,2,1,1,1 -- an
         accelerating ramp -- then 6 tics of flicker; 36 tics, ONCE
damage   --
type     --
sound    --   (SeeSound "BLCKHKEX" fires from the Default block on wake)
impact   RS_ZapDecHKex (FX:1226): LITN ABCDEFGFEDB 1 Bright -- an 11-frame
         lightning flicker, Speed 1, XScale 0.55 / YScale 0.75, no Damage
         at all. Pure decal.
trigger  See   (guarded by `A_JumpIf(user_ready >= 1,"See2")`, so it plays
                exactly once per life)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_ZapDecHKex", count:8, arc:40) with
         p.FireTrigger = RS_FIRE_SPAWN, dmgMult 0
notes    Same "machine booting" ramp as RS_BlackHK2.See, with lightning
         instead of sparks. See2 then plays "BHKEXSTP" footsteps every
         chase cycle. The A_Log("A chill runs down your spine") at :1928 is
         ours in place of CH's stripped ACS announcer.
```

```
ATTACK   RS_BlackHKEX.Phase2
file     zscript/monsters/hellknight/RS_HellKnight.zs:1966
shape    UNCLASSIFIED   (one-shot self-buff)
payload  RS_ZapDecHKex x5 (cosmetic)
arc      as See
timing   6-tic flare then 5 zaps over 10 tics; 16 tics
damage   --
type     --
sound    --
impact   as See
trigger  Missile   (A_JumpIfHealthLower(5000,"Phase2") is the FIRST line
                    of Missile at :1972 -- it pre-empts the whole table)
range    --
mirrored no
inherit  --
profile  MakeSelfBuff(speedMult:1.29, damageMult:1.0, duration:-1)
         (14 -> 18 = 1.286x)
notes    A_SetSpeed(18) and `bMISSILEEVENMORE = true`, **neither ever
         cleared** -- permanent for the rest of the life. `user_rage`
         guards it to one use; the guard branch `Nah:` (:1968) resumes
         Missile+1. user_rage also unlocks the Res2 and Warp2 variants.
         Same permanent-duration porting gap as RS_RedHK.Enrage.
```

```
ATTACK   RS_BlackHKEX.FastBeam
file     zscript/monsters/hellknight/RS_HellKnight.zs:1996
shape    SCATTER
payload  RS_HKEXFastBeam x8 per pass  +  RS_BluCybFX x4 (cosmetic)
arc      one aimed, three at random(-14,14), one aimed, three at
         random(-24,24)
timing   3-tic aim; 2 flares over 6; beam on 1 tic; 3 beams 2 tics apart;
         2-tic re-aim; 2 flares; beam on 1; 3 beams 2 apart; 2-tic refire;
         ~37 tics per pass, looping on A_MonsterRefire(128,"See2")
damage   **NONE DIRECT.** RS_HKEXFastBeam declares no Damage and no
         DamageFunction (RS_HellKnightFX.zs:1169-1185) -- a Projectile's
         default damage is 0. All of its damage is
         `A_Explode(random(5,30), 32)` per-frame ×2 on Death.
type     Plasma
sound    "prox/beep" at the head of the state (:1993)
impact   BFS1 AB 4 A_Explode(random(5,30), 32) ×2 frames.
         DeathSound "Spell/Lightn". +FULLVOLDEATH.
         Its TRAIL is the real weapon: RS_HKEXFastBeamTrail is spawned
         TWICE per flight frame (once at 0, once 21 units BEHIND), and
         **each trail piece A_Explodes twice for random(5,30)/32 on its
         own Death** (FX:1200-1224). The beam lays a detonating corridor.
trigger  Missile   (Mode1 and Mode2 tables; also reached from AccurateBeam)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_HKEXFastBeam", count:8, delayTics:2, arc:48,
                   fireSnd:"prox/beep")
notes    **A zero-direct-damage projectile is a real and unusual part.**
         Contact does nothing; the blast on stopping does everything. If
         this is ported the profile must NOT be given a damage roll --
         the roll belongs to the payload's Death.
         A_Jump(32,"AccurateBeam") after the first triple and
         A_Jump(64,"AccurateBeam") after the second -- so a beam sweep
         escalates into the railgun about half the time.
```

```
ATTACK   RS_BlackHKEX.AccurateBeam
file     zscript/monsters/hellknight/RS_HellKnight.zs:2016
shape    HITSCAN
payload  --   (no projectile actor; RS_CGRailBuff is both the puff AND the
              spawnclass -- see notes)
arc      spread_xy 0, spread_z 0 -- **perfectly accurate**
timing   two railgun shots 6 tics apart, then a 2-tic refire check; 14 tics
damage   A_CustomRailgun(random(1,4), ...) -- **random(1,4) per SHOT**
type     --   (no damagetype argument; the trace deals typeless damage)
sound    --   (the railgun itself is silent; the "prox/beep" belongs to
              FastBeam, which is what reaches this state)
impact   pufftype AND spawnclass are both `RS_CGRailBuff` (chaingunner
         FX:599): a Speed 14 / FastSpeed 26 **+SEEKERMISSILE** mini-bolt,
         DamageFunction (random(1,3)), Plasma, Scale 0.33, whose Death
         A_Explodes twice for random(1,2)/24.
trigger  Missile   (only via A_Jump(32/64,"AccurateBeam") from FastBeam)
range    range argument 0 -> unlimited
mirrored no
inherit  RS_CGRailBuff -> chaingunner FX (CH Chaingunners.txt:1677)
profile  MakeHitscan(fireSnd:"", spreadScale:0.0, ammoCost:0,
                     impactPuff:"RS_CGRailBuff")
notes    Full argument decode against the engine signature
         (E:\UZDXREMA\wadsrc\static\zscript\actors\actor.zs:1208):
           damage random(1,4) · spawnofs_xy 0 · color1 "blue" · color2
           "blue" · flags RGF_FULLBRIGHT|RGF_NORANDOMPUFFZ · aim 0 ·
           maxdiff 0 · pufftype "RS_CGRailBuff" · spread_xy 0 ·
           spread_z 0 · range 0 · duration 66 · sparsity 0.7 ·
           driftspeed 0.9 · spawnclass "RS_CGRailBuff" · spawnofs_z 7 ·
           spiraloffset 10
         **The trace's own damage is trivial (1..4).** The weapon is
         `spawnclass` -- a dense trail of seeking mini-bolts strung along
         the beam at sparsity 0.7, each of which then hunts you. That is
         where the damage is, and it is invisible from the call site
         unless you decode all seventeen arguments.
```

```
ATTACK   RS_BlackHKEX.Homing
file     zscript/monsters/hellknight/RS_HellKnight.zs:2012
shape    SINGLE
payload  RS_BruiserMissileEx2 x1
arc      --   yaw 0, dead on
timing   36 tics of lock-on (9,9,9,9 with two beeps), the missile on a
         9-tic state, 6-tic tail; 51 tics -- **the longest single windup
         in the family**
damage   DamageFunction (random(80,125))   [RS_HellKnightFX.zs:1142]
type     Fire
sound    "prox/beep" ×2, at 0 and 18 tics into the windup
impact   BAL3 C 4, D 6 A_Explode(random(10,40), 128, 0), E 8.
         **flags 0 = NOT XF_HURTSOURCE**, plus `DontHurtShooter true`.
         DeathSound "weapons/hellex". Decal "Scorch".
trigger  Missile   (the >1500-unit branch: A_Jump(256,"Homing","DeathBeam",
                    "BigMiss") at :1977; also from BigMis via
                    A_Jump(64,"Homing"))
range    1500..   (Missile gates A_JumpIfCloser(500,"Mode2") then
                   A_JumpIfCloser(1500,"Mode1") first)
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_BruiserMissileEx2", fireSnd:"prox/beep",
                   bigMuzzle:true, spawnHeight:38)
notes    **The hardest-hitting single round in the family: random(80,125)
         direct, and it SEEKS** -- A_SeekerMissile(12,9) every other
         flight tic, Speed 29, +THRUGHOST. Trails RS_BruiserTrail.
         The 36-tic double-beep telegraph is the counterplay.
```

```
ATTACK   RS_BlackHKEX.DeathBeam
file     zscript/monsters/hellknight/RS_HellKnight.zs:2025
shape    SINGLE
payload  RS_MegaRedRev x1  +  RS_RedRevLoad x1 (cosmetic)
arc      random(-1,1)
timing   18-tic lock-on (9,9), 7-tic charge flare, 5-tic re-aim, beam on
         a 5-tic state, 5-tic tail; 40 tics -- tighter than BlackHK2's 49
damage   DamageFunction (random(35,95))
type     Plasma
sound    "prox/beep"
impact   BLL9 CDE 6 A_Explode(random(15,55), 64) per-frame ×3
trigger  Missile   (Mode1 table; also the >1500 table)
range    --
mirrored no
inherit  as RS_BlackHK2.DeathBeam
profile  MakeHeavy(proj:"RS_MegaRedRev", fireSnd:"prox/beep",
                   bigMuzzle:true, spawnHeight:38)
notes    Same payload as the Mk I's DeathBeam, ~20% faster to fire. Also
         drops two `Cell` pickups (:2026-2027). Tail A_Jump(60,"BigMis").
```

```
ATTACK   RS_BlackHKEX.BigMis
file     zscript/monsters/hellknight/RS_HellKnight.zs:2032
shape    SCATTER
payload  RS_BruiserMissileEx x3
arc      0, random(-7,7), random(-17,17) -- widening, and wider than the
         Mk I's 0/±3/±7
timing   missile 1 on a 9-tic state, 14-tic re-aim, missile 2 on 6,
         14-tic re-aim, missile 3 on 6; gaps 23 and 20; 50 tics
damage   DamageFunction (random(40,95))   [RS_HellKnightFX.zs:1110]
type     Fire
sound    "prox/beep" before each of the three
impact   BAL3 C 4 SetScale(2.5,2.0), D 6 **A_Explode(random(40,95), 208, 0)**,
         E 8. **Radius 208 -- the largest blast in the family.**
         DontHurtShooter true, flags 0. DeathSound "weapons/hellex".
trigger  Missile   (Mode1 table; also reachable from DeathBeam's tail)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_BruiserMissileEx", count:3, delayTics:21,
                   arc:34, fireSnd:"prox/beep")
notes    Speed 33 (vs the Mk I's 20). Trails RS_BruiserTrail every tic
         rather than every other tic. Drops a `RocketBox`. Tails:
         A_Jump(64,"Homing") then A_Jump(60,"MisBar").
```

```
ATTACK   RS_BlackHKEX.MisBar
file     zscript/monsters/hellknight/RS_HellKnight.zs:2046
shape    SCATTER
payload  RS_SpreadMisBarEX x14
arc      2 at random(-5,5) / pitch random(-1,1);
         4 at ±14 / pitch ±3;
         3 at ±14 / pitch ±5;
         5 at ±24 / pitch ±7
         -- **a widening cone in BOTH axes**, via
         CMF_OFFSETPITCH|CMF_SAVEPITCH
timing   2+4 missiles on 2-tic states (12 tics), a 15-tic re-aim, then 3
         on 2-tic states and 5 on 1-tic states (11 tics); 39 tics total
damage   DamageFunction (random(10,40)) each   [RS_HellKnightFX.zs:1083]
type     Fire
sound    --   (SeeSound "weapons/hominglaunch" per missile)
impact   MISL B 2 A_Explode(random(5,35), 88), MISL CD 3.
         **Unlike RS_SpreadMisBar1 it spawns NO sub-munitions** -- the
         MolochNail split is Mk I only. DeathSound "weapons/homingexplode".
trigger  Missile   (Mode1 AND Mode2 tables -- in both loadouts)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_SpreadMisBarEX", count:14, delayTics:2,
                   arc:48, pitchJitter:14)
notes    **14 missiles in 39 tics -- the densest volley in the family.**
         Speed 41. No +SEEKERMISSILE despite the sound, and unlike the
         Mk I version it has NO random self-destruct jump, so every one
         flies to something. Drops three `Shell` pickups. Tail
         A_Jump(42,"Missile").
```

```
ATTACK   RS_BlackHKEX.NadeToss
file     zscript/monsters/hellknight/RS_HellKnight.zs:2057
shape    SINGLE
payload  RS_BaronHellNade x1
arc      random(-9,9) yaw, pitch random(3,12) (downward lob)
timing   14-tic windup (7,7), throw on a 9-tic state, 1-tic tail; 24
damage   DamageFunction (random(30,85)) direct   [RS_HellKnightFX.zs:1253]
type     Fire
sound    --   SeeSound "weapons/grenlf" and DeathSound "weapons/grenlx"
              are both MISSING LUMPS in CH -- silent there and here.
              BounceSound "prox/beep" does play.
impact   SEE `RS_BaronHellNade.Death` BELOW -- **fifty-four seeking
         RS_BaronStar3** over a 258-unit lattice.
trigger  Missile   (Mode1 AND Mode2)
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_BaronHellNade", bigMuzzle:false, spawnHeight:38)
notes    **This nade SEEKS**: +SEEKERMISSILE with A_SeekerMissile(12,12)
         on one of its five Spawn frames, plus A_Weave(4,4,random(-5,5),
         random(-5,5)) and two A_SetScale calls that make it visibly
         pulse (0.75x0.35 -> 0.35x0.75). BounceCount 23, BounceFactor 1.15,
         WallBounceFactor 0.95, Gravity 0.33. A_Jump(12,"Bounce") for the
         chaotic re-thrust; **no random self-destruct jump**, so unlike
         RS_BaronNade it must actually hit something.
```

```
ATTACK   RS_BlackHKEX.BigSlash
file     zscript/monsters/hellknight/RS_HellKnight.zs:2062
shape    SCATTER
payload  RS_HKEXslash x3
arc      random(-12,-4) left, random(4,12) right, 0 centre -- a deliberate
         **three-lane** spread with a gap either side of centre
timing   10-tic windup (5,5); all three on the SAME tic; 5-tic hold,
         1-tic tail; 16 tics total
damage   DamageFunction (random(10,35)) each   [RS_HellKnightFX.zs:1049]
type     Melee
sound    AttackSound "moloch/nailhit" per blade, via +SPAWNSOUNDSOURCE --
         but see notes, the lump is missing
impact   FBL1 EFG 1 A_Explode(random(5,20), 64) per-frame ×3, then
         RS_PuffCybieRed. DeathSound "weapons/firex4".
trigger  Melee AND Missile -- `Melee:` at :2101 is
         `A_Jump(255,"BigSlash")`, and Mode2 (<500 units) also lists it
range    ..500 via Mode2; unlimited via the Melee label
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_HKEXslash", count:3, arc:24)
notes    **A ground shockwave, not a projectile.** +FLOORHUGGER +RIPPER
         +EXTREMEDEATH +BLOODSPLATTER, Speed 42, **YScale 5.2 / XScale
         1.25** -- a tall thin blade that skims the floor and rips through
         everything it touches. Translation "0:255=[53,0,0]:[244,0,0]".
         "moloch/nailhit" is the KNOWN VERBATIM HOLE (CH's $random members
         are missing lumps; flagged at RS_HellKnightFX.zs:44). Silent in
         CH too.
         Sprites BLAD A and FBL1 EFG are `sprites/molochs/` lumps -- the
         evidence trail that resolved the SGRN/HGRN typo (FX:76-78).
```

```
ATTACK   RS_BlackHKEX.Resistance
file     zscript/monsters/hellknight/RS_HellKnight.zs:2070
shape    UNCLASSIFIED   (self-shield; fires nothing damaging)
payload  RS_ZapDecHKex x18 (cosmetic) + RS_ZapOrbHKEX x1 (cosmetic)
         + A_GiveInventory("RS_HKEXProtect", 1)
arc      the 18 zaps are a fixed LATTICE, not a spread: spawnheight steps
         36, 39, 39, 42, 42, 42, 42, 45, 45, 45, 45, 48, 48, 48, 48, 54,
         51, 51 with spawnofs_xy ±2, ±4, ±6, ±9 -- **yaw is 0 on all 18**
timing   9-tic windup (4,5), the 18 zaps over 6 tics, then the orb on a
         6-tic state; ~21 tics
damage   --
type     --
sound    --
impact   RS_HKEXProtect (demon FX:144) is a `PowerProtection` with
         **DamageFactor 0.6** and Powerup.Duration **-7** (7 seconds).
         RS_ZapOrbHKEX (FX:995) is cosmetic: +NOCLIP +NOINTERACTION, it
         A_Warps to AAPTR_TARGET at Z 88 -- i.e. it hangs over YOUR head --
         and spits cosmetic zaps until a random A_Jump(2) kills it.
trigger  Missile   (only via Warp / Warp2, which are reached from See2
                    A_Jump(24,"Warp") and Pain A_Jump(128,"Warp"))
range    --
mirrored no
inherit  RS_HKEXProtect -> demon FX (CH Hellknights.txt:2922)
profile  MakeSelfBuff(speedMult:1.0, damageMult:1.0, duration:245,
                      noPain:false)
         -- 7 seconds = 245 tics. The 0.6 damage-taken factor has no
            field on RS_AttackProfile; flagged.
notes    **A 40%-damage-reduction shield, self-applied, that no other
         knight has.** The eighteen zaps are a visual lattice climbing the
         body 36 -> 54 units, which is why the yaw is 0 on every one.
         `A_JumpIf(user_rage >= 1,"Res2")` at :2090 -- once Phase2 has
         fired, the shield is followed by a counter-attack.
```

```
ATTACK   RS_BlackHKEX.Res2
file     zscript/monsters/hellknight/RS_HellKnight.zs:2097
shape    SCATTER
payload  RS_ZapOrbHKEX2 x3  +  RS_ZapDecHKex x4 (cosmetic)
arc      random(-12,1), random(-1,12), 0 -- left / right / centre, each
         lane 13 degrees wide and OVERLAPPING at 0
timing   22-tic windup (6,8,8), 4 cosmetic zaps over 4 tics, 9 tics of
         posture (3,3,3), then all three orbs within 4 tics; 39 total
damage   DamageFunction (random(10,40)) each   [RS_HellKnightFX.zs:1026]
type     Plasma
sound    --
impact   **NONE.** RS_ZapOrbHKEX2's Death is `TNT1 A 0; Stop;` -- no FX,
         no sound, no explode. The damage is all contact, and it is a
         +RIPPER so it does that damage repeatedly as it passes through.
trigger  Missile   (Resistance tail, gated on user_rage >= 1 -- i.e. only
                    below 5000 health)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_ZapOrbHKEX2", count:3, arc:26)
notes    +RIPPER, Speed 41, Scale 1.1. Trails RS_ZapDecHKex every tic of
         flight. A ripping orb with no impact FX at all is unusual and
         worth keeping in the bin exactly as-is.
         **NOT A ROW: `Warp` / `Warp2` (:2104 / :2128).** They fire nothing.
         They set bNOPAIN, stretch the actor 1.4x1.0 -> 2.6x0.05, set speed
         to 99, A_Wander, then unstretch -- a **teleport-blink**, and the
         only route into Resistance. Recorded here so the jump chain is
         followable; the mobility is real but it is not an attack.
```

```
ATTACK   RS_BlackHKEX.Death
file     zscript/monsters/hellknight/RS_HellKnight.zs:2147
shape    SCATTER
payload  RS_HKRedDeath x11   [CMF-SLOT]
arc      as RS_BlackHK2.Death -- spawnheight random(20,100), spawnofs_xy
         random(-30,30), yaw = the literal CMF_AIMOFFSET = 1, flags 2,
         pitch -10
timing   identical to RS_BlackHK2.Death: 3 / scream / 6 / noblocking /
         2 / settle; ~80 tics
damage   A_Explode(random(5,10), 42) each
type     Fire
sound    "world/barrelx" ×2 per detonation, under "monster/brudth"
impact   as RS_RedHK.Death
trigger  Death
range    --
mirrored no
inherit  RS_HKRedDeath -> zombieman FX
profile  MakeBurst(proj:"RS_HKRedDeath", count:11, delayTics:6, arc:2,
                   trigger:RS_FIRE_DEATH)
notes    Byte-identical to the Mk I's Death chain. Ends on A_BossDeath.
         There is NO `BigMiss:` attack: the Missile jump table at :1977
         names a label CH never defined ("BigMis" is the real one). CH's
         DECORATE treats the bad jump as a no-op and falls through; our
         :1979-1985 reproduce that with an explicit dead branch. **So one
         third of the >1500-unit table does nothing at all**, in CH and
         here. Verified at CH Hellknights.txt:2748 vs :2794 this pass.
```

---

# TIER 11 -- `RS_WhiteHK3` ("Ghost of 1993")

Health 5000, Speed 13, Scale 1.25, Alpha 0.75 Add, Species "WhiteHK",
+BOSS +FLOAT +NOGRAVITY +NOCLIP +THRUSPECIES. CH `Hellknights.txt:3238`.

```
ATTACK   RS_WhiteHK3.GhostBombs
file     zscript/monsters/hellknight/RS_HellKnight.zs:2257
shape    SCATTER
payload  RS_PhantomEgg x2 per pass
arc      random(-5,5) then random(-10,10)
timing   14-tic windup (7,7), egg 1 on an 8-tic state, 14-tic re-aim,
         egg 2 on 8; 22 tics between eggs; 44 per pass, looping on
         A_MonsterRefire(128,"See") and an unconditional `Goto GhostBombs`
damage   DamageFunction (random(20,60))   [RS_HellKnightFX.zs:1371]
type     Plasma
sound    --   (SeeSound "phantom/spirit1" per egg)
impact   **DeathSound is the literal string "none"** -- explicitly
         silenced, faithful to CH's `DEATHSOUND NONE`.
         SEE `RS_PhantomEgg.Death` BELOW -- it HATCHES A LIVE MONSTER.
trigger  Missile   (A_Jump(64,"Summons") first, then
                    A_Jump(256,"GhostBombs","BigBomb") at :2253-2254)
range    --
mirrored yes -- the two eggs use opposite arm frame sets
inherit  --
profile  MakeBurst(proj:"RS_PhantomEgg", count:2, delayTics:22, arc:20)
notes    Speed 22, Scale 1.2, Add, translated green. Trails RS_SoulTrail
         (FX:1449 -- Speed 15, Projectile, DamageType Fire, no Damage
         property so it is cosmetic) every 5 tics.
         **The loop has no exit except A_MonsterRefire and A_CheckSight**,
         so a ghost with clear LOS will throw eggs indefinitely.
```

```
ATTACK   RS_WhiteHK3.Summons
file     zscript/monsters/hellknight/RS_HellKnight.zs:2266
shape    UNCLASSIFIED   (summon; deals no damage itself)
payload  RS_SpecialSpectre2 x4
arc      --   placed at random(-64,64) XY, Z random(5,15), SXF_SETMASTER
timing   16-tic windup (8,8), then one spectre per 4-tic state ×4;
         1-tic tail; 33 tics
damage   --
type     --
sound    "Baron/Sight" on the second 8-tic windup state (:2265)
impact   --
trigger  Missile   (A_Jump(64,"Summons") -- ~25% of every Missile;
                    also from BigBomb's tail A_Jump(64,...))
range    --
mirrored no
inherit  RS_SpecialSpectre2 : RS_CommonSpectre : Spectre
         (RS_HellKnightFX.zs:1311 -> RS_Spectre.zs:596 -> engine).
         **It has NO States block of its own** -- every attack it has is
         the vanilla Spectre's A_SargAttack (random(1,10)*4 melee),
         catalogued in the spectre family. The subclass adds only
         `Monster; +THRUSPECIES +NOCLIP` and a four-line DropItem table
         (RS_CH_Shell 128, RS_implyingclip 174, RS_CH_RocketAmmo 64,
         RS_CH_Cell 32).
profile  MakeSummon(summonCls:"RS_SpecialSpectre2", count:4, cap:4,
                    tierOffset:-4, fireSnd:"Baron/Sight")
notes    +NOCLIP on the summons means they **walk through walls** to reach
         you, matching their master. Tail A_Jump(88,"BigBomb") -- a summon
         usually leads straight into the big attack.
```

```
ATTACK   RS_WhiteHK3.BigBomb
file     zscript/monsters/hellknight/RS_HellKnight.zs:2273
shape    SCATTER
payload  RS_SoulBomb x3
arc      0, random(-8,8), random(-14,14) -- widening
timing   **52 tics of telegraph** (21 facing + 21 of "Baron/Pain" wails
         + 10 re-aim), then bombs on 9, 7 and 5-tic states -- gaps 9 and
         7, an accelerating three-round drop; 8-tic tail; 82 tics total
damage   DamageFunction (random(20,80)) direct   [RS_HellKnightFX.zs:1418]
type     --   (RS_SoulBomb sets no DamageType)
sound    "Baron/Pain" ×3, one per 7-tic wind-up state (:2271)
impact   **FOUR STAGED, DECAYING BLASTS** (FX:1438-1444):
           A_Explode(random(20,70), 200)
           A_Explode(random(15,60), 178)
           A_Explode(random(10,50), 158)
           A_Explode(random(5,40), 128)
         3 tics apart, after A_SetScale(1.8). **A 200-unit opening
         radius -- the largest in the family.** DeathSound
         "phantom/explode". SeeSound "phantom/bomb".
trigger  Missile   (A_Jump(256,"GhostBombs","BigBomb"))
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_SoulBomb", count:3, delayTics:8, arc:28)
notes    Speed 11 -- **the SLOWEST projectile in the family**, and the
         longest telegraph. That pairing is the design: you get 52 tics
         of warning and then three slow, enormous bombs you have to walk
         away from. MissileType "RS_SoulTrail" is set as a Default
         property AND the trail is spawned explicitly on all six Spawn
         frames; the property itself is inert here (nothing calls
         A_Mushroom or A_SpawnDebris).
         Tail A_Jump(64,"GhostBombs","Summons","BigBomb") -- the ghost
         re-rolls its whole table.
```

```
ATTACK   RS_WHITEHK2  (the twin)
file     zscript/monsters/hellknight/RS_HellKnight.zs:2296
shape    --   (no attacks of its own)
payload  --
arc      --
timing   --
damage   --
type     --
sound    --
impact   --
trigger  --
range    --
mirrored no
inherit  RS_WHITEHK2 : RS_WhiteHK3 -- it overrides ONLY `Spawn` and `Idle`
         (to suppress the twin-spawn recursion and the tier token).
         **All three attack rows above apply to it unchanged.**
profile  --
notes    Spawned by RS_WhiteHK3's own Spawn state at :2226,
         `A_SpawnItemEx("RS_WHITEHK2",24,0,...)` -- so **the Ghost of 1993
         always arrives as a PAIR**, 24 units apart, and both throw eggs
         and bombs. Counted as the family's 1 pure inheritor, not as a
         15th monster.
```

---
---

# SECONDARY ROWS -- IMPACT THAT IS ITSELF AN ATTACK

Per the spec: "record it in `impact` AND give the secondary its own row if
it is substantial." Twelve qualify.

```
ATTACK   RS_IceHKShot.Death
file     zscript/monsters/hellknight/RS_HellKnightFX.zs:271
shape    RING
payload  RS_SpikeCyanRev x12
arc      360 -- four quadrant randoms that tile the circle:
         random(0,90) ×3, random(89,180) ×3, random(181,270) ×3,
         random(271,359) ×3
timing   all twelve on one tic, then a 20-tic ICEY FGHI fade
damage   DamageFunction (random(1,3)) each   [demon FX:161]
type     Ice
sound    DeathSound "spike/spiked" -- KNOWN VERBATIM HOLE, undefined in
         CH's SNDINFO, silent in CH too
impact   RIP1 CBA 6 A_Explode(random(0,1), 6), DeathSound ""
trigger  (impact of RS_CyanHK2.Missile)
range    --
mirrored no
inherit  RS_SpikeCyanRev -> demon FX
profile  MakeVolley(proj:"RS_SpikeCyanRev", count:12, arc:360)
notes    Velocity random(12,40) outward, random(5,25) upward, and the
         spikes have Gravity 1.5 -- so it is a **fountain**, not a flat
         ring. Every ice bolt that lands paves the floor around it.
```

```
ATTACK   RS_IceOrbCyanHK.Death
file     zscript/monsters/hellknight/RS_HellKnightFX.zs:337
shape    MULTI
payload  RS_SpikeCyanRev x20  + the orb's own A_Explode
arc      360 -- five per quadrant, same tiling as above
timing   A_SetScale(2.5,1.5), the explode on a 4-tic state, all 20 spikes
         on the next tic, a 9-tic ICEY GHI fade
damage   A_Explode(random(10,60), 128) + 20 × random(1,3)
type     Ice
sound    DeathSound "Ice/Hit2"
impact   as above
trigger  (impact of RS_CyanHK2.A1)
range    --
mirrored no
inherit  RS_SpikeCyanRev -> demon FX
profile  MakeVolley(proj:"RS_SpikeCyanRev", count:20, arc:360) +
         MakeRadial(radius:128, damage:35)
notes    The orb also trails RS_IceCacoTrail (cacodemon FX) twice per
         6-tic flight cycle, once along its pitch vector and once at a
         random spray -- so it leaves a visible freezing wake.
```

```
ATTACK   RS_AbyssHKBall.Death
file     zscript/monsters/hellknight/RS_HellKnightFX.zs:377
shape    MULTI
payload  RS_SplashAbyss2 x16  +  RS_AbyssHKMist x3  + its own A_Explode
arc      splash: 8 at X random(-228,228) / Y ±8, 8 at X ±8 /
         Y random(-228,228) -- **a cross, not a circle**
         mist: random(-156,156) XY
timing   all 16 splashes and the explode on one tic, a 9-tic PLSE CDE
         fade, then the 3 mists
damage   A_Explode(random(8,30), 64, 0) -- flags 0, does NOT hurt the
         source + 16 × random(1,9) + the mists' 12 per-frame
         A_Explode(random(1,9), 46) each
type     Ice (splash and mist) / Plasma (the ball)
sound    DeathSound "spit/spit2"
impact   mist: PSBG FGHIIHGFFGHI 6 A_Explode per frame -- 72 tics of
         lingering gas per puff
trigger  (impact of RS_AbyssHK2.Balls and .BallsBar)
range    --
mirrored no
inherit  RS_SplashAbyss2 : RS_SplashAbyss (zombieman FX)
profile  MakeVolley(proj:"RS_SplashAbyss2", count:16, arc:180) +
         MakeVolley(proj:"RS_AbyssHKMist", count:3, arc:360) +
         MakeRadial(radius:64, damage:19)
notes    **Every abyss ball leaves a gas cloud behind.** Three mists ×
         12 frames × random(1,9) at radius 46, for 72 tics. In a BallsBar
         volley that is 21 clouds. This is the family's area-denial layer
         and it is entirely invisible from the monster's states.
```

```
ATTACK   RS_FireBluHKBall1.Death
file     zscript/monsters/hellknight/RS_HellKnightFX.zs:443
shape    RING
payload  RS_FireBluHKBall2 x14  + three staged A_Explodes
arc      **360 in yaw AND 360 in pitch**: angle random(0,360), pitch
         random(-180,180) -- a full sphere, not a ring in a plane
timing   4-tic dim, the first explode on a 1-tic state, all 14 bolts on
         that same tic, then three more explodes over 6 tics
damage   A_Explode(random(5,20), 128), then
         A_Explode(random(5,10), 128) ×3 per-frame, plus
         14 × DamageFunction (random(5,10))
type     Plasma
sound    DeathSound "Crack/death"
impact   each RS_FireBluHKBall2: BAL1 CDE 6 A_Explode(random(1,7), 128)
         per-frame ×3. **42 further explodes if all fourteen land.**
trigger  (impact of RS_FireBluHK2.Bolt1)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_FireBluHKBall2", count:14, arc:360,
                    pitchJitter:360) + MakeRadial(radius:128, damage:12)
notes    A cluster bomb. Note the pitch is a FULL sphere -- fourteen
         bolts fire in every direction including straight down, so the
         effective yield depends heavily on geometry.
```

```
ATTACK   RS_MinesHK.Death
file     zscript/monsters/hellknight/RS_HellKnightFX.zs:538
shape    RING
payload  RS_CGNail x12
arc      **360 in exact 30-degree steps**: 15, 45, 75, 105, 135, 165,
         195, 225, 255, 285, 315, 345 -- the only fully deterministic
         ring in the family
timing   all twelve on one tic
damage   DamageFunction (random(1,5)) each   [chaingunner FX:429]
type     Melee (RS_CGNail's DamageType)
sound    DeathSound "weapons/boom1" (the mine); each nail then plays
         "moloch/nailhit" on its own impact -- a MISSING LUMP in CH
impact   6PUF ABCDEF 1 A_Explode(random(1,3), 16) per-frame ×6, then
         FBL1 EFG 1 A_Explode(random(1,3), 16) ×3, then RS_PuffCybieRed.
         **Nine explodes per nail, 108 per mine.** DeathSound
         "weapons/firex4". +SPAWNSOUNDSOURCE +EXTREMEDEATH +BLOODSPLATTER.
trigger  (impact of RS_GrayHK2.Fire3)
range    --
mirrored no
inherit  RS_CGNail -> chaingunner FX (CH Chaingunners.txt:798)
profile  MakeVolley(proj:"RS_CGNail", count:12, arc:360)
notes    **This is why the gray knight's mines matter.** The direct hit is
         random(5,20); the payload is a 360 nail ring at Speed 45, each
         nail carrying 108 tiny explodes. The mine bounces up to 25 times
         and gains energy off walls (WallBounceFactor 1.1), so the ring
         can go off anywhere in the room.
         The 30-degree step and the 15-degree offset mean **no nail fires
         along a cardinal axis** -- deliberate, so a mine against a wall
         still sprays into the room.
```

```
ATTACK   RS_SwooshCBBar1.Death
file     zscript/monsters/hellknight/RS_HellKnightFX.zs:700
shape    RING
payload  RS_PlasmaBallSP4 x90  + three per-frame A_Explodes
arc      360 -- three 120-degree arcs, thirty bolts each:
         random(0,120), random(120,240), random(240,359)
timing   the three explodes on 1-tic BFE1 frames, all ninety bolts on the
         last of those tics
damage   A_Explode(random(5,30), 124) ×3 per-frame, plus 90 ×
         RS_PlasmaBallSP4's own damage (cacodemon FX)
type     Plasma
sound    DeathSound "weapons/bfgx"
impact   see the cacodemon family for RS_PlasmaBallSP4 (CH
         Hellknights.txt:2498, ceded there)
trigger  (impact of RS_BlackHK2.LaserShot1)
range    --
mirrored no
inherit  RS_PlasmaBallSP4 -> cacodemon FX (RS_CacodemonFX.zs)
profile  MakeVolley(proj:"RS_PlasmaBallSP4", count:90, arc:360)
notes    **Ninety projectiles per beam, and the Terminator fires six beams
         a pass.** Velocity random(15,60) outward with random(-33,33)
         vertical, offset random(-8,8) X and random(-8,20) Y. This is the
         single largest secondary in the family by count and it is written
         nowhere near the monster.
```

```
ATTACK   RS_SpreadMisBar1.Death
file     zscript/monsters/hellknight/RS_HellKnightFX.zs:933
shape    SCATTER
payload  RS_MolochNail x4  + its own A_Explode
arc      random(-2,2) yaw, random(-4,4) pitch, with
         CMF_AIMDIRECTION|CMF_SAVEPITCH -- so they continue along the
         missile's own flight vector, not toward a target
timing   the explode on a 2-tic state, a 3-tic frame, then 2+2 nails on
         0-tic states, a 3-tic frame
damage   A_Explode(random(5,35), 88) + 4 × DamageFunction (random(10,30))
type     Fire
sound    DeathSound "weapons/homingexplode"
impact   each nail: nine per-frame A_Explodes (see RS_MinesHK.Death)
trigger  (impact of RS_BlackHK2.ClusterMis)
range    --
mirrored no
inherit  RS_MolochNail -> cacodemon FX
profile  MakeVolley(proj:"RS_MolochNail", count:4, arc:4, pitchJitter:8)
         + MakeRadial(radius:88, damage:20)
notes    CMF_AIMDIRECTION is what makes this a **forward-continuing**
         sub-munition rather than a homing one -- the nails keep going in
         the missile's direction. The Mk II's RS_SpreadMisBarEX does NOT
         have this; it is Mk I only.
```

```
ATTACK   RS_BaronNade.Death
file     zscript/monsters/hellknight/RS_HellKnightFX.zs:902
shape    RAIN
payload  RS_BaronStar3 x14  + its own A_Explode
arc      --   not aimed: placed at random(±180,±180), random(±220,±220)
         and random(±280,±280) XY, Z random(1,32), around the DETONATION
         POINT
timing   the explode on an 8-tic state, then 4 stars over 8 tics, 4 more
         over 8, then 6 on one tic
damage   A_Explode(random(20,50), 128) + 14 × DamageFunction (random(5,30))
type     Fire
sound    DeathSound "weapons/grenlx" -- MISSING LUMP in CH, silent
impact   **each star is itself a seeker that explodes five times**:
         A_SeekerMissile(3,3) + A_Weave(4,1,6,0) for 8 tics, then
         BBOM CD 3 A_Explode(random(5,20), 148) ×2 and
         BBOM EFG 6 A_Explode(random(5,30), 148) ×3. Radius 148.
         SeeSound "caco/attack", DeathSound "spell/Impact1". FastSpeed 38.
trigger  (impact of RS_BlackHK2.NadeToss)
range    --
mirrored no
inherit  RS_BaronStar3 is CH Barons.txt:2988, shipped here (FX:833)
profile  MakeVolley(proj:"RS_BaronStar3", count:14, arc:360)
         + MakeRadial(radius:128, damage:35)
         -- placement is XY-offset over a 560-unit box, which MakeVolley
            cannot express.
notes    **Fourteen seeking, five-times-exploding stars over a 560-unit
         area.** One grenade can produce 70 separate 148-radius blasts.
         This is by a wide margin the highest-yield single round the
         Mk I Terminator carries, and none of it is visible at the
         NadeToss call site.
```

```
ATTACK   RS_BaronHellNade.Death
file     zscript/monsters/hellknight/RS_HellKnightFX.zs:1283
shape    RAIN
payload  RS_BaronStar3 x54  + its own A_Explode
arc      --   not aimed. 42 placed randomly across a lattice reaching
         ±258 units, plus **12 at FIXED cardinal and diagonal points**:
         (±250, 0), (0, ±250), (±250, ±250), (±200, ±200) -- a deliberate
         eight-point star pattern layered under the random scatter
timing   the explode on a 5-tic state, then the stars over 6 tics
         (four 1-tic states pace the placement)
damage   A_Explode(random(30,50), 128) + 54 × DamageFunction (random(5,30))
type     Fire
sound    DeathSound "weapons/grenlx" -- MISSING LUMP, silent
impact   as RS_BaronNade.Death -- each star seeks and explodes five times
         at radius 148
trigger  (impact of RS_BlackHKEX.NadeToss)
range    --
mirrored no
inherit  RS_BaronStar3
profile  MakeVolley(proj:"RS_BaronStar3", count:54, arc:360)
         + MakeRadial(radius:128, damage:40)
notes    **Fifty-four seeking stars, up to 270 blasts of radius 148 from
         ONE grenade.** The twelve fixed placements are the tell that this
         was authored as a screen-clearing pattern, not a random spray.
         Counted line by line at FX:1283-1302: 4+4+7+7+3+7+7+3 random,
         12 fixed.
```

```
ATTACK   RS_PhantomEgg.Death
file     zscript/monsters/hellknight/RS_HellKnightFX.zs:1389
shape    UNCLASSIFIED   (a projectile that HATCHES A LIVE MONSTER)
payload  RS_PhantomHatch x1 -> RS_MiniPhantom x1
arc      --
timing   the hatch spawns on a 1-tic state; RS_PhantomHatch then runs
         SPI1 JIHGFE 4 = 24 tics of an egg cracking open, then spawns the
         phantom on a 4-tic state; **28 tics from impact to a live enemy**
damage   --   (the hatch and the egg-shell carry none)
type     --
sound    --   (the egg's DeathSound is the literal "none")
impact   RS_MiniPhantom -- see its own row below
trigger  (impact of RS_WhiteHK3.GhostBombs)
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_MiniPhantom", count:1, cap:8,
                    tierOffset:-5)
         -- a DELAYED summon; MakeSummon has no delay axis, so the 28-tic
            hatch is lost.
notes    **The ghost's main ranged attack is a monster-delivery system.**
         Every egg that lands becomes a chasing suicide bomber 28 tics
         later. With the twin (RS_WHITEHK2) both throwing on a
         self-relooping GhostBombs cycle, the phantom count climbs fast.
         RS_PhantomHatch (FX:1394) has +NOGRAVITY +NOCLIP and no Health --
         it is a 28-tic animation, not an actor you can stop.
```

```
ATTACK   RS_MiniPhantom.Melee
file     zscript/monsters/hellknight/RS_HellKnightFX.zs:1357
shape    CHARGE
payload  --   (the actor IS the payload)
arc      --
timing   SPI1 EFGHIJ 2 = 12 tics of A_Die -- the action is on EVERY one
         of the six frames, so it dies on the first
damage   Death: A_Explode(random(20,50), 88)
type     --
sound    "phantom/explode" on the Death state (:1361)
impact   SPIR FGHIJ 2 -- a 10-tic ghost burst
trigger  Melee   (its See state is its Spawn state; it chases and detonates)
range    ..44   (Actor default MeleeRange; it has no MeleeRange property)
mirrored no
inherit  --
profile  MakeRadial(radius:88, damage:35, fireSnd:"phantom/explode")
         + p.MaxRange = 44
notes    **Not A_SkullAttack, but the same semantic**: a Health 10,
         Speed 14, +FLOAT +NOGRAVITY +NOCLIP flyer that closes and A_Die's.
         CHARGE is the closed word for "the monster IS the projectile"
         and it is used here on that basis; the mechanism is A_Die on a
         Melee state, which is recorded so nobody looks for A_SkullAttack.
         +SHOOTABLE +NOBLOOD, no `Monster;` and no +COUNTKILL -- it does
         not count toward the kill total.
         It trails RS_SoulSmoke twice per 2-tic chase cycle (cosmetic).
         `MissileType "RS_SoulSmoke"` in its Default block is INERT --
         nothing in its states calls A_Mushroom or A_SpawnDebris, the only
         things that read that property. Recorded because it looks like an
         attack and is not.
         See UNRESOLVED #5 about its target acquisition.
```

```
ATTACK   <shared>.Pain.AbyssPE
file     zscript/monsters/hellknight/RS_HellKnight.zs:773 (RS_FireBluHK2)
         also :866 (RS_GrayHK2), :978 (RS_CommonHK), :1090 (RS_GreenHK),
         :1207 (RS_BlueHK), :1324 (RS_PurpleHK), :1467 (RS_YellowHK),
         :1591 (RS_RedHK) -- eight identical copies
shape    UNCLASSIFIED   (a damage-type-triggered TRANSFORMATION)
payload  RS_SplashAbyss x94 (cosmetic -- the PARENT class, no damage)
         + RS_AbyssHK2 x1 (a live Tier-9 monster)
arc      --   splash placed at random(-16,16) XY, Z random(4,32), with
         velocities (16,0,3) and (12,0,8) and yaw random(-359,359)
timing   A_SetScale(0.8,0.8); 15 tics of AYPB AAB; the "AbyssForm" sound
         on a 5-tic state; 30 tics of AYPB BBACDE; both 47-splash bursts
         on one tic; the RS_AbyssHK2 spawn on that same tic; then 9 tics
         of AYPB FGH and 20 tics of shrinking (1,0.75 -> 1,0.05); A_Die.
         ~79 tics of on-screen transformation.
damage   --   (nothing here damages; RS_SplashAbyss is the undamaged parent)
type     --
sound    "AbyssForm" (:777 and the seven siblings)
impact   the spawned RS_AbyssHK2 arrives with SXF_TRANSFERSPECIAL and
         SXF_TRANSFERAMBUSHFLAG -- it inherits the dead knight's map
         special and ambush state
trigger  Pain   -- specifically `Pain.AbyssPE`, i.e. taking DamageType
         "AbyssPE". **The only source of that damage type in the whole
         tree is `RS_AbyssPEPulse`**
         (zscript/monsters/painelemental/RS_PainElementalFX.zs:716), the
         Abyss Pain Elemental's ripping pulse -- DamageFunction
         (random(1,2)), +FORCEPAIN, +RIPPER, +FORCERADIUSDMG. So this is
         reachable, not dead code.
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_AbyssHK2", count:1, cap:1, tierOffset:+4,
                    fireSnd:"AbyssForm") with p.FireTrigger = RS_FIRE_PAIN
         -- a *self-replacing* transform has no factory; MakeSummon plus
            the caller's own A_Die is the closest composition.
notes    **Eight of the fourteen knights can be UPGRADED by the enemy's
         own attack.** Tiers 1, 2, 3, 4, 5, 6, 7 and 8 all carry this;
         the Abyss (9), Cyan (12), Brown (13) and the three bosses do not.
         Getting hit by an Abyss Pain Elemental turns a Tier-1 Common Hell
         Knight (500 HP) into a Tier-9 Abyss Bruiser (1850 HP, three
         ranged attacks and a fog form).
         `bNOPAIN = true` is set on entry and never cleared -- irrelevant,
         since A_Die ends the actor.
         The 94 splashes are `RS_SplashAbyss`, the PARENT. It has no
         Damage property (zombieman FX:707). Only `RS_SplashAbyss2` (:735)
         damages. This is purely a visual dissolve.
```

---
---

# NOT ROWS -- states that look like attacks and are not

Recorded so the jump graph is complete and nobody re-derives them.

| State | file:line | Why it is not a row |
|---|---|---|
| `RS_BrownHK2.MaybeParry` / `MaybeParry2` / `MaybeParry3` | :285, :288, :291 | Pure `A_JumpIfInTargetLOS` gates. Per the spec, a state that only picks between attacks is the range band on the rows it reaches. |
| `RS_BrownHK2.MeleeMaybe` / `MeleeMaybe2` | :305, :310 | Range re-gates into Rush / Melee. |
| `RS_BrownHK2.Death` shield drop | :359 | `A_SpawnItemEx("RS_HellWarriorShield",...)` -- a bouncing corpse prop, no Damage, no explode. Cosmetic. |
| `RS_CyanHK2.SeeMe` / `Jumpy` / `See2` | :438, :441, :450 | Mobility. `Jumpy` is a ThrustThingZ/ThrustThing hop chain gated on `rs_ch_cyanbounce` (our cvar for CH's `CallACS("CH_CyanBounce")`). Fires nothing. |
| `RS_AbyssHK2.Choices` / `Choices2` / `CL1` / `CL2` | :622, :626, :640, :643 | Range and weight tables only. |
| `RS_AbyssHK2.See2` splash drip | :592, :595 | Spawns `RS_SplashAbyss`, the undamaged parent. Decoration. |
| `RS_FireBluHK2` / `RS_GrayHK2` / `RS_CommonHK` bare `Melee:` labels | :763, :860, :955 | Not attacks -- they fall through into `Fires5:` / `Missile:`. Recorded on those rows as dual triggers. |
| `RS_PurpleHK.Fire3` | :1345 | A re-gate: `A_JumpIfCloser(300,"Fbreath")` then `A_Jump(255,"See")`. |
| `RS_RedHK.Dodge1` / `Dodge2` | :1585, :1588 | `ThrustThing(angle*256/360 + 64 / +192, 20, 0, 0)` -- pure sidestep, no payload. Reached from Pain. |
| `RS_RedHK.Nah` / `RS_BlackHKEX.Nah` | :1647, :1968 | One-tic guard branches for the once-only rage buffs. |
| `RS_BlackHK2.Mode1` / `Mode2` | :1845, :1848 | `A_GiveInventory` / `A_TakeInventory` on `RS_BrusMode` -- the loadout flip. Recorded on the LaserShot1 row. |
| `RS_BlackHKEX.Warp` / `Warp2` | :2104, :2128 | Teleport-blink: bNOPAIN, scale stretch to 2.6x0.05, speed 99, `A_Wander`, unstretch. Fires nothing. The only route into `Resistance`. |
| `RS_BlackHKEX.BigMiss` | :1979 | **A dead branch that reproduces a CH typo.** CH's jump table names a label CH never defined. One third of the >1500 table does nothing. |
| `RS_BlackHKEX.Mode1` / `Mode2` | :1986, :1989 | Range-band jump tables (`<500` -> Mode2, `<1500` -> Mode1). |
| `RS_WhiteHK3.See` / `See2` | :2235, :2243 | Chase states; `See` sets `bNOCLIP = true` and `See2` clears it, so the ghost phases through walls half the time. Mobility, not an attack. |
| `RS_WhiteHK3.Spawn` twin | :2226 | Spawns `RS_WHITEHK2`. Recorded on the twin's row. |
| All `Tickles:` states | :353, :684, :794, :905, :966, :1111, :1228, :1363, :1503, :1658 | `RS_CHBoner` gag branch -- spawns `RS_ThePlanBoner` and resumes Death+1. Cosmetic. |
| All `XDeath:` states | :1003, :1132, :1249, :1378 | `RS_HKSplashDed` (a cosmetic `A_XScream` blood burst, FX:554) plus `A_SpawnParticle`. CH's `CHRandom_GibGenerator` gore chain is stripped, with the strip commented at each site. No damage. |
| All `Raise:` states | :366, :696, :806, :917, :994, :1123, :1240, :1375, :1515, :1678 | Resurrection animation. `RS_RedHK.Raise` at :1679 carries our BRUR O-W frame fix; art only, no attack. |
| `RS_CommonHK.Grow` / `RS_GreenHK.Grow` / `RS_BlueHK.Grow` | :998, :1127, :1244 | `RS_GrowRaisin` promotion on resurrection -- Common -> Green -> Blue -> Purple. A progression mechanic, not an attack. |
| The 7 cvar stubs + `RS_Colourset8` | :47, :70, :92, :114, :137, :156, :175, :211 | Spawn dials. `TNT1 A 0` + `A_SpawnItemEx`. No states, no attacks. |

---
---

# UNRESOLVED

Honest gaps. Nothing below is guessed at.

**1. `C:\Users\Command\Desktop\CH` DOES NOT EXIST ON THIS MACHINE.**
The spec and CLAUDE.md both name it as the ground truth. `ls` on
`C:\Users\Command\Desktop` returns `CHP`, `CrashReport`, `GlowInTheDark_*`,
`TextureLights_Reignited`, `elites` and loose files -- **no `CH`**.
CLAUDE.md's "IMPORTING A MONSTER MEANS THE WHOLE MONSTER" section names a
second CH path, `E:\New folder\ART SOURCE\CH\`, and that one exists and its
`decorate\Hellknights.txt` is **3,546 lines -- exactly the count our file
headers cite for the CH source they were transcribed from**. I used it, and
every attack call site matched. But the two paths were not diffed against
each other (one of them is gone), so **I cannot prove the ART SOURCE copy is
the same CH the spec means**. The owner should confirm or repoint the path.
`CHP` was NOT consulted; it is not authoritative.

**2. The lostsoul, demon, cacodemon, chaingunner, shotgunner, imp and
zombieman lanes own 21 of this family's payloads.** Their rows above cite
`file:line` in those files and the CH line each was ceded from, but I did
**not** re-diff those classes against CH -- the ceding comments at
`RS_HellKnightFX.zs:8-32` assert they were diffed identical at cede time and
I took that on trust rather than re-verifying twenty-one classes. If a
payload row's damage looks wrong, that assertion is the thing to re-check.

**3. The `[CMF-SLOT]` sites: identical in CH, but I cannot say whether the
behaviour is intended.** 36 call sites in the two family files (plus 20 more
in the lostsoul and imp files, for payloads this family fires) pass
`CMF_AIMOFFSET` in
`A_CustomMissile`'s **angle** slot, which makes yaw a literal 1 degree and
puts `random(0,360)` (or a fixed `2`) into the **flags** slot. `flags =
random(0,360)` means the projectile gets a *different random combination of
CMF bits on every call* -- CMF_AIMOFFSET, AIMDIRECTION, TRACKOWNER,
CHECKTARGETDEAD, ABSOLUTEPITCH, OFFSETPITCH, SAVEPITCH, ABSOLUTEANGLE and
BADPITCH in unpredictable mixtures. **CH is byte-identical here and our
transcription is faithful**, so there is nothing to fix in the port. What I
could not determine is whether CH's author knew. It changes what a
translated player-weapon should do: reproducing the *written* call gives
chaotic per-shot behaviour; reproducing the *evident intent* gives a clean
random(0,360) spread. **Owner call.** Affected: `RS_YellowHK.Boom`,
`RS_BlackHK2.See`, `RS_RedHK.Death`, `RS_BlackHK2.Death`,
`RS_BlackHKEX.Death`, `RS_BloodBoltHK.Spawn`, plus the lostsoul-owned
`RS_FireHKBall1.Spawn` and `RS_BigHK.Death`.

**4. `RS_AbyssHK2.Mist`'s splash count of 188 is a static line count, not a
runtime count.** The state fires four `TNT1 AAAA...` runs of 47
`A_SpawnItemEx` each (:661, :664, :667, :670). 4 × 47 = 188. But `A_Wander`
runs between them and the whole sequence is ~110 tics, so whether all four
bursts are reached depends on nothing in the state -- there is no jump out.
I believe 188 is correct; I did not run it. Same caveat on the 94 in
`Pain.AbyssPE` (two 47-runs).

**5. `RS_MiniPhantom`'s target acquisition is unverified.** It is spawned by
`RS_PhantomHatch` with plain `A_SpawnItem` -- **no `SXF_SETTARGET`, no
`SXF_SETMASTER`, no pointer transfer at all** (FX:1406). Its `Spawn` label
is also its `See` label, so it goes straight to `A_Chase` with a null
target. `A_Chase` does re-acquire via `LookForPlayers` when the target is
null, so it *should* find you, but the actor has no `Monster;` declaration
and no `+COUNTKILL` -- only `+SHOOTABLE +FLOAT +LOOKALLAROUND +NOBLOCKMONST
+NOGRAVITY +NOBLOOD +NOCLIP`. **Whether it actually hunts, or drifts inert,
was not tested in-game.** This matters: `RS_WhiteHK3.GhostBombs` is a
self-relooping state and the phantoms are its entire payoff. Identical in
CH, so if it is broken it is broken there too.

**6. `A_VileAttack`'s blast half in `RS_BrownHK2.BlastEm` is proven inert by
reading the engine, not by measuring it.** `archvile.zs:143` gates the
blast on `Actor fire = tracer` and RS_BrownHK2 sets no tracer anywhere in
its 137 lines. I am confident, but a live test with `blastdmg` raised would
settle it in one second and I did not run one.

**7. Two profile axes the row set needs and `RS_AttackProfile` does not
have.** Recorded so a port does not silently drop them:
  * **Predictive aim.** `RS_GreenHK.Missile2` solves an intercept
    (`RS_HKLead.FireLead`). There is no `lead`/`predict` field, so
    `MakeVolley` produces a straight shot -- which is exactly the CH bug the
    owner ruled against. Porting that row without a new axis silently
    reverts the owner's decision.
  * **Permanent self-buff.** `RS_RedHK.Enrage` and `RS_BlackHKEX.Phase2`
    both set flags that are never cleared. `MakeSelfBuff`'s `duration` is a
    tic count with no permanent sentinel; I wrote `duration:-1` in those two
    profile lines as a placeholder and it is **not** a real value.
  * (Lesser, same category: `MakeSelfBuff` has no damage-taken-factor field
    for `RS_BlackHKEX.Resistance`'s 0.6, and `MakeSummon` has no delay axis
    for `RS_PhantomEgg`'s 28-tic hatch.)

**8. Area-placed payloads do not fit any factory.** Nine rows place their
payload by XY offset rather than by angle (`RAIN` shape, plus
`RS_AbyssHK2.Mist` and both nade Deaths). I wrote `MakeVolley(..., arc:360)`
on those lines because it is the closest existing call, but **an arc is not
an XY box** and the two are not interchangeable -- `RS_BaronHellNade.Death`
scatters over a 516-unit square with twelve fixed points in it, which no
`arc` value reproduces. Flagged rather than faked.

**9. Two sound holes I confirmed but did not resolve, both inherited from
CH.** `"moloch/nailhit"` (RS_MolochNail, RS_CGNail, RS_HKEXslash) and
`"weapons/grenlf"` / `"weapons/grenlx"` (both nades) are absent from CH's
own SNDINFO chain, per the standing notes at `RS_HellKnightFX.zs:44-49`. I
verified the notes exist and are cited; **I did not re-walk the
`$random`/`$alias` chains to the lumps myself** this pass. Per CLAUDE.md an
unresolved sound name is completely inert -- no error, no warning -- so
these will never fail a build and only a listener will catch them. Also
unresolved the same way: `"spike/spiked"` (RS_IceHKShot DeathSound) and
`"knight/pain"` (RS_BrownHK2 / RS_GreenHK PainSound).

**10. Row-count arithmetic, stated so it can be checked.** 60 primary rows
= Brown 5, Cyan 4, Abyss 5, FireBlu 2, Gray 2, Common 1, Green 2, Blue 2,
Purple 3, Yellow 3, Red 6, BlackHK2 8, BlackHKEX 13, White 3, WHITEHK2 1
(a null row asserting inheritance). Plus 12 secondary rows. **72 total.**
The `Pain.AbyssPE` row is written once and applies to eight monsters; if
the composition step wants one row per monster, that row expands to eight
and the total becomes 81.
