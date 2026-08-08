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

# CHAINGUNNER — ATTACK CATALOG

Family: **chaingunner** (Colourful Hell tier ladder, rebuilt native).
Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Field order and the
shape vocabulary are that spec's, unchanged.

## Denominator — what was actually read

| | |
|---|---|
| Source files read whole | 2 (`RS_Chaingunner.zs` 2,067 lines; `RS_ChaingunnerFX.zs` 1,473 lines) |
| Classes in those files | 71 (22 + 49), comment-stripped count |
| Of those, monsters carrying attacks | **14** tier-ladder + **4** summoned minions = 18 |
| Non-combat classes | 1 RandomSpawner, 7 cvar-gate stubs, 3 drop gates |
| State labels (comment-stripped) | 304 (203 + 101) |
| Attack call sites (comment-stripped) | `A_CustomMissile` 115, `A_CustomBulletAttack` 31, `A_CustomRailgun` 20, `A_Explode` 35, `A_VileTarget` 3, `A_PainAttack`/`A_DualPainAttack` 4, `A_CPosAttack` 1, `A_SargAttack` 1, `A_CustomComboAttack` 1 — **211 raw sites** |
| Payload classes named by attacks | 38 fired directly by a monster; 15 more fired by a payload |
| **Attack rows written** | **66** (48 tier-ladder, 11 payload-fired secondaries, 7 minion) |
| Cross-file FX chains resolved | 9 (`RS_IceZombieShot2`, `RS_AbyssZShotCH3`, `RS_PlasmaBallSP3`, `RS_TrailSPCguy`, `RS_HKRedDeath`, `RS_SplashAbyss`, `RS_AbyssShotIdentifier` in zombieman; `RS_SparkPuff1`, `RS_DetoPuffCG`, `RS_CHBSTarget` in shotgunner) |
| Inheritance chains resolved | `RS_Boomer2/3 : RS_Boomer1`; `RS_DetoPuff2/3 : RS_DetoPuffCG`; `RS_SlimeBall2..5 : RS_SlimeBall1 : DoomImpBall`; `RS_SpamShotsCguyEX2 : RS_SpamShotsCguyEX`; `RS_IceZombieShot2 : RS_IceZombieShot`; `RS_AbyssZShotCH3 : RS_AbyssZShotCH`; `RS_BabyCaco : Cacodemon`; `RS_CommonCGuy/Green/Blue/Purple/Red : ChaingunGuy` |
| CH diff | **Every attack call site in our tree matches CH byte-for-byte** (args and tics). Diff run against `E:\New folder\ART SOURCE\CH\decorate\Chaingunners.txt`, 3,169 lines. Deviations listed in UNRESOLVED §U2. |

`A_Jump` / `A_JumpIfCloser` / `A_JumpIfHealthLower` / `A_CheckProximity` /
`A_MonsterRefire` targets were followed. States reached ONLY by a jump and
found this way: `More`, `M1`, `M2`, `M3`, `Missile2`, `Rapids`, `Closer`,
`Spam`, `Spam2`, `YE`, `YellowBomb`, `BigBomb`, `RapidFire`, `RedSpam`,
`SpamShots`, `Shield`, `ShieldBlast`, `BigOne`, `Puddle`, `Puddle2`,
`Darts`, `DartStorm`, `Summon1`, `Summon2`, `Summon3`, `Phase2`, `Nah`.
A `Missile:`/`Melee:` name filter would have found 18 of 45 attack states here.

---

## THREE ENGINE FACTS THAT CHANGE EVERY NUMBER BELOW

Read these before using any `damage` field. All three were verified in the
engine's own zscript, not assumed.

**1. `A_CustomBulletAttack` SECRETLY MULTIPLIES DAMAGE BY `random(1,3)`.**
`zscript/actors/attacks.zs`:
```
int damage = damageperbullet;
if (!(flags & CBAF_NORANDOM))
    damage *= random[cwbullet](1, 3);
```
**No `A_CustomBulletAttack` call in this family passes `CBAF_NORANDOM`.**
So `A_CustomBulletAttack(2,2,1,random(2,9),...)` deals `random(2,9) × random(1,3)`
= 2..27 per bullet, mean ~11, not the 2..9 the source line reads as. Every
hitscan row below records the written roll AND the effective roll.
This matters twice over, because the player-side path
(`RS_Weapon.zs:728`) calls `A_FireBullets(..., FBF_NORANDOM)` — the player
does **not** get the multiplier. Porting a written roll straight across
silently halves the attack.

**2. A CONSTANT `Damage n` ON A PROJECTILE IS ALSO A ROLL: `n × random(1,8)`.**
`DamageFunction (random(a,b))` is literal a..b. A bare `Damage 5` is 5..40.
Both forms appear in this family and they are not interchangeable:
`RS_PlasmaBallSP3` `Damage 5` → **5..40**; `RS_Puddle1`/`RS_Puddle2`
`Damage 4` → **4..32**; `RS_BabyCacoBall` `Damage 3` → **3..24**;
`RS_SlimeBall1..5` `Damage 4` → **4..32**; `RS_GenShield` `Damage 0` → 0.

**3. AN ACTION FIRES ONCE PER *FRAME*, NOT ONCE PER LINE.**
`CPS2 FE 3 A_CustomMissile(...)` is TWO frames and fires **two** missiles,
3 tics apart. `HCPO EEEEEEE 1 A_CustomMissile(...)` fires **seven**.
`SPIR ABCDEDCBA 5 A_Explode(random(5,30),164)` is **nine** explosions.
Reading these as one call each undercounts this family's projectile output
by roughly 2×. Every `payload` count below is the frame-expanded count.

## Conventions used here (stated so seventeen files compose)

* **Shape words are the spec's closed set. None coined.**
* For a **HITSCAN** row the `payload` is the trace; the puff class goes in
  `impact`, per the spec's own field definition. A puff never makes a row
  MULTI.
* **MULTI** is used only where the attack fires two or more different
  *travelling projectile* classes. A harmless telegraph/marker projectile is
  recorded in `notes`, not counted toward MULTI.
* Where one state label holds two genuinely different attacks, the second is
  addressed as `Label[+n]` — the state-offset the `Goto` uses. This is not a
  new label; it is how the code reaches it.
* `A_VileTarget` is filed as **VILE**. The spec's VILE names `A_VileAttack`;
  `A_VileTarget` is the same archvile mechanic's spawn-at-target half and has
  no travel, so it lands in the same bucket rather than needing a new word.
* Spread arguments are **half-angles**. `A_CustomBulletAttack(2,2,...)` means
  ±2° horizontal and ±2° vertical (engine: `spread_xy * Random2()/255`,
  Random2 → −255..255).
* Tier numbers are CH icon indices, as set by `RS_Zom.SetTier`.

---
---

# SECTION 1 — THE TIER LADDER (14 monsters, 48 rows)

## RS_CommonCGuy — tier 1, "Former Captain"

    ATTACK   RS_CommonCGuy.Missile
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:913
    shape    HITSCAN
    payload  hitscan trace x1 per call, x2 per cycle
    arc      +/-22.4 horizontal, 0 vertical (autoaim slope only)
    timing   4,4  then 1-tic refire -- 9-tic sustained cycle, 2 rounds
    damage   random(1,5) * 3   (engine A_CPosAttack: Random[CPosAttack](1,5)*3 = 3,6,9,12,15)
    type     Hitscan
    sound    "chainguy/attack"  (A_CPosAttack plays AttackSound on CHAN_WEAPON; resolves to dsshotgn in the engine's own filtered SNDINFO)
    impact   Bulletpuff (vanilla)
    trigger  Missile
    range    --   (MISSILERANGE, no band gate)
    mirrored no
    inherit  ChaingunGuy (vanilla). A_CPosAttack is engine-native, not authored here.
    profile  MakeHitscan(fireSnd:"chainguy/attack", profName:"Former Captain burst"); p.SpreadScale=0; p.SpreadBonus=22.4; p.PelletOverride=1
    notes    THE BASELINE ROW -- every other hitscan in this family is a
             deliberate departure from it, so it is worth holding in mind.
             `CPOS FE 4` is 2 frames = 2 shots. A_CPosRefire keeps the loop
             alive while the target is visible; `Goto Missile+1` re-enters at
             the icon spawn, so the 10-tic wind-up happens ONCE per
             engagement, not per shot. The ±22.4 cone is enormous compared
             with every custom chaingunner below (the tightest is 0).

## RS_GreenCGuy — tier 2, "Green Chaingunner"

    ATTACK   RS_GreenCGuy.Missile
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1019
    shape    HITSCAN
    payload  hitscan trace, random(1,2) bullets per call, x2 calls per cycle (2..4 rounds)
    arc      +/-random(6,17) horizontal, +/-random(3,13) vertical -- THE CONE ITSELF IS ROLLED
    timing   4,4  then 3-tic refire -- 11-tic sustained cycle
    damage   random(1,8) per bullet  --> EFFECTIVE random(1,8) * random(1,3) = 1..24
    type     Hitscan
    sound    "chainguy/attack"
    impact   RS_Trail11 (RS_ChaingunnerFX.zs:84) -- green add-blend BAL1 C-E puff, +NOINTERACTION, no damage. CH Revenants.txt:1624.
    trigger  Missile
    range    --
    mirrored no
    inherit  ChaingunGuy for Death/Raise; the attack is fully overridden
    profile  MakeHitscan(fireSnd:"chainguy/attack", profName:"Green scatter"); p.SpreadScale=0; p.SpreadBonus=11.5; p.PelletOverride=2
    notes    A ROLLED CONE is the interesting part and the profile layer
             cannot hold it -- SpreadBonus is a constant. 11.5 is the mean of
             random(6,17); the 6..17 swing is lost. Recorded, not silently
             rounded. Vertical spread is independently rolled and SMALLER
             than horizontal, so the burst is a wide flat smear, not a circle
             -- the player-side A_FireBullets(spread, spread, ...) is
             symmetric and cannot express that at all.
             `CPOS FE 4` = 2 frames = 2 calls; each call rolls its own bullet
             count, so a cycle is 2..4 rounds, never a fixed number.

## RS_BlueCGuy — tier 3, "Blue Chaingunner" (railgunner)

Three range bands off `A_JumpIfCloser(600,"Closer")` / `(1200,"M1")`, both
with `noz=false`. `Goto Missile+1` re-tests the band every cycle.

    ATTACK   RS_BlueCGuy.Missile
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1131
    shape    HITSCAN
    payload  rail trace x1 + hitscan trace x1 (fired 0 tics apart, same beat)
    arc      0 -- both traces perfectly on-aim
    timing   3 (charge), 6 (rail), 0 (bullet), 5 (recover), 1 (refire) -- 15-tic cycle
    damage   rail random(1,2) [used raw, NOT x random(1,3)] + bullet random(1,4) --> EFFECTIVE random(1,4)*random(1,3) = 1..12
    type     Hitscan (both)
    sound    "chainguy/attack"  (A_CustomBulletAttack plays AttackSound; A_CustomRailgun also plays it unless RGF_SILENT, which is not set)
    impact   rail -> Bulletpuff (A_CustomRailgun default pufftype) + a blue beam, RGF_NOPIERCING so it stops at the first hit. bullet -> RS_BlueChainPuff2 (RS_ChaingunnerFX.zs:489) SSBL K/I/J add-blend flash, +NOINTERACTION, no damage.
    trigger  Missile
    range    1200..
    mirrored no
    inherit  ChaingunGuy (Death/Raise only)
    profile  MakeHitscan(fireSnd:"chainguy/attack", profName:"Blue rail (long)"); p.SpreadScale=0; p.SpreadBonus=0; p.PelletOverride=2
    notes    A RAIL PAIRED WITH A BULLET IS THE WHOLE IDIOM: the rail is the
             visible beam and pierce behaviour, the bullet is where the real
             damage and the custom puff live. Modelled here as 2 pellets
             because the profile layer has no rail mode; that loses the beam
             and the RGF_NOPIERCING behaviour. The rail's own random(1,2) is
             literal -- A_CustomRailgun does NOT apply the random(1,3)
             multiplier, only A_CustomBulletAttack does.

    ATTACK   RS_BlueCGuy.M1
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1138
    shape    HITSCAN
    payload  rail trace x1 + hitscan trace x1
    arc      0
    timing   3,6,0,5,1 -- 15-tic cycle (identical rhythm to Missile)
    damage   rail random(1,3) + bullet random(2,8) --> EFFECTIVE random(2,8)*random(1,3) = 2..24
    type     Hitscan
    sound    "chainguy/attack"
    impact   Bulletpuff (rail) + RS_BlueChainPuff2 (bullet)
    trigger  Missile   (via A_JumpIfCloser(1200,"M1") from Missile)
    range    600..1200
    mirrored no
    inherit  ChaingunGuy
    profile  MakeHitscan(fireSnd:"chainguy/attack", profName:"Blue rail (mid)"); p.SpreadScale=0; p.SpreadBonus=0; p.PelletOverride=2; p.MinRange=600; p.MaxRange=1200
    notes    Same shape as Missile, double the damage roll. The band ladder
             is the design: closer = harder, which is the opposite of most
             monsters and is what makes this one feel like a sniper you have
             to close on, not away from.

    ATTACK   RS_BlueCGuy.Closer
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1146
    shape    HITSCAN
    payload  hitscan trace x6 on one tic
    arc      +/-15 horizontal, +/-15 vertical
    timing   one tic (all 6 together); 5 charge + 7 marker + 0 blast + 5 recover + 1 refire = 18-tic cycle
    damage   random(2,8) per pellet --> EFFECTIVE random(2,8) * random(1,3) = 2..24 x6
    type     Hitscan
    sound    "prox/beep" (from the marker, 0 tics earlier) then "chainguy/attack" (the blast)
    impact   RS_BlueChainPuff2 x6
    trigger  Missile   (via A_JumpIfCloser(600,"Closer") from Missile)
    range    ..600
    mirrored no
    inherit  ChaingunGuy
    profile  MakeHitscan(fireSnd:"chainguy/attack", profName:"Blue point-blank shotgun"); p.SpreadScale=0; p.SpreadBonus=15; p.PelletOverride=6; p.MaxRange=600
    notes    THIS ONE MAPS ONTO A PLAYER SHOTGUN ALMOST EXACTLY -- 6 pellets,
             symmetric ±15° cone, one tic, explicit range 8000. It is the
             single cleanest 1:1 in the family.
             The `A_CustomMissile("RS_BlueChainPuff3",28,15,0,0,0)` 7 tics
             before it is a TELEGRAPH, not a payload: RS_BlueChainPuff3
             (RS_ChaingunnerFX.zs:514) is +NOINTERACTION with no damage and
             plays "prox/beep" twice before fading. Not counted as MULTI per
             the convention above, but a weapon wearing this profile should
             wear the beep too -- it is the tell that makes the blast fair.
             The range arg 8000 is explicit and far beyond the 600 gate.

## RS_PurpleCGuy — tier 4, "Purple Chaingunner" (seeker boomers)

Three bands off `A_JumpIfCloser(650,"M1")` / `(1300,"M2")`.

    ATTACK   RS_PurpleCGuy.Missile
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1261
    shape    BURST
    payload  RS_Boomer3 x4
    arc      +/-1  (random(-1,1) per shot -- effectively straight)
    timing   5,5,5,5  (21-tic cycle incl. 1-tic refire)
    damage   DamageFunction (random(1,6))  + on-death A_Explode(random(1,8),46) INHERITED
    type     Fire
    sound    --   (AttackSound is set to "" on this monster, deliberately; each RS_Boomer3 plays its own SeeSound "SNPRFIRE" on spawn)
    impact   MISL B/C/D explosion, A_Explode(random(1,8), radius 46) on the B frame, DeathSound "weapons/firex4" -- ALL INHERITED from RS_Boomer1
    trigger  Missile
    range    1300..
    mirrored no
    inherit  RS_Boomer1 (RS_ChaingunnerFX.zs:541). RS_Boomer3 overrides ONLY `-SEEKERMISSILE`, DamageFunction and Spawn. Everything that makes it hurt on arrival is the parent's.
    profile  MakeBurst(proj:"RS_Boomer3", count:4, delayTics:5, arc:2, fireSnd:"")
    notes    RS_BOOMER3 DOES NOT HOME, DESPITE CALLING A_SeekerMissile(7,7).
             Its Default block sets `-SEEKERMISSILE`, so the engine never
             assigns a tracer when it is fired, and A_SeekerMissile has
             nothing to steer toward. CH has exactly this (Chaingunners.txt:
             1499-1507) -- it is CH's own quirk, faithfully imported, NOT an
             import error. Do not "fix" it.
             Two source lines, each `CPOS FE 5` = 2 frames, so FOUR missiles,
             not two.

    ATTACK   RS_PurpleCGuy.M2
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1266
    shape    BURST
    payload  RS_Boomer2 x4
    arc      +/-1
    timing   4,4,5,5  (19-tic cycle incl. refire) -- NOT uniform
    damage   DamageFunction (random(1,7))  + inherited A_Explode(random(1,8),46)
    type     Fire
    sound    --   (see Missile; SeeSound "SNPRFIRE" per shot, inherited)
    impact   as Missile -- INHERITED from RS_Boomer1
    trigger  Missile   (via A_JumpIfCloser(1300,"M2"))
    range    650..1300
    mirrored no
    inherit  RS_Boomer1 -- RS_Boomer2 overrides DamageFunction and Spawn only
    profile  MakeBurst(proj:"RS_Boomer2", count:4, delayTics:4, arc:2); p.MinRange=650; p.MaxRange=1300
    notes    RS_Boomer2 DOES home: A_SeekerMissile(4,4), 4-degree turn cap,
             +SEEKERMISSILE inherited and not cleared. Mid-strength tracking.
             Timing 4,4,5,5 is uneven and BurstDelayTics is uniform; 4 tics
             chosen, so the profile runs 16 tics against CH's 18. Recorded.

    ATTACK   RS_PurpleCGuy.M1
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1271
    shape    BURST
    payload  RS_Boomer1 x4
    arc      +/-1
    timing   4,4,4,4  (17-tic cycle incl. refire)
    damage   DamageFunction (random(1,8))  + A_Explode(random(1,8),46)
    type     Fire
    sound    --   (SeeSound "SNPRFIRE" per shot)
    impact   MISL B/C/D, A_Explode(random(1,8),46), DeathSound "weapons/firex4"
    trigger  Missile   (via A_JumpIfCloser(650,"M1"))
    range    ..650
    mirrored no
    inherit  --   (RS_Boomer1 IS the parent; nothing above it but Actor)
    profile  MakeBurst(proj:"RS_Boomer1", count:4, delayTics:4, arc:2); p.MaxRange=650
    notes    THE BAND LADDER IS INVERTED AND THAT IS THE DESIGN. Closest range
             gets RS_Boomer1: the HARDEST tracking (A_SeekerMissile(8,8)),
             the highest damage roll, and the fastest cadence. Furthest range
             gets the dumb one. Backing away from a Purple Chaingunner is the
             correct play and the numbers say so.

## RS_YellowCGuy — tier 5, "Orange Former Captain"

Five bands off `A_JumpIfCloser` 300 / 750 / 1250 / 1900. This monster has
**no `AttackSound` property at all**, so every attack below is silent at the
muzzle regardless of what the action would have played.

    ATTACK   RS_YellowCGuy.Missile
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1387
    shape    HITSCAN
    payload  rail trace x6 (3 tracer beams + 3 damaging rails, alternating)
    arc      damaging rails: +/-2, then +/-3, then +/-3 (spread_xy arg). Tracers: 0.
    timing   5,5,(4),5,5,(4),5,5,2 -- 40 tics, then Goto See (NO refire loop)
    damage   tracer rails 0 (literally Damage 0). Damaging rails random(1,2) each, used raw.
    type     Hitscan (rail)
    sound    --   SILENT. No AttackSound on the monster; A_CustomRailgun would play it if it existed.
    impact   pufftype RS_CGRailBuff + spawnclass RS_CGRailBuff along the beam (spawnofs_z 7, spiraloffset 10, duration 66, sparsity 0.7, driftspeed 0.9). RS_CGRailBuff (RS_ChaingunnerFX.zs:599): a SEEKING sub-projectile, DamageFunction (random(1,3)) Plasma, +SEEKERMISSILE, Death = 2x A_Explode(random(1,2),24).
    trigger  Missile
    range    1900..
    mirrored no
    inherit  --
    profile  MakeHitscan(profName:"Yellow rail (extreme)"); p.SpreadScale=0; p.SpreadBonus=3; p.PelletOverride=3
    notes    THE RAIL IS A DELIVERY MECHANISM, NOT THE DAMAGE. random(1,2) per
             beam is trivial; the payload is the corkscrew of RS_CGRailBuff
             seekers left along the beam for 66 tics, each of which then
             chases and explodes twice. Reading only the `damage` arg reports
             this attack as harmless. It is not.
             Argument positions (engine signature, `zscript/actors/actor.zs`):
             damage, spawnofs_xy, color1, color2, flags, aim, maxdiff,
             pufftype, spread_xy, spread_z, range, duration, sparsity,
             driftspeed, spawnclass, spawnofs_z, spiraloffset.
             `aim` is 1 here (autoaim on) and 0 in M1 (dead-straight).
             The paired zero-damage `A_CustomRailgun(0,0,"none","Blue",
             RGF_NOPIERCING)` before each real one is a pure visual tracer.

    ATTACK   RS_YellowCGuy.M2
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1398
    shape    HITSCAN
    payload  rail trace x6 (3 tracer + 3 damaging)
    arc      +/-1, then +/-2, then +/-2
    timing   5,4,(3),5,4,(3),5,4,2 -- 35 tics, then Goto See
    damage   random(1,3) per damaging rail, raw
    type     Hitscan
    sound    --   SILENT (no AttackSound on this monster)
    impact   RS_CGRailBuff puff + beam-spawned RS_CGRailBuff seekers, duration 66
    trigger  Missile   (via A_JumpIfCloser(1900,"M2"))
    range    1250..1900
    mirrored no
    inherit  --
    profile  MakeHitscan(profName:"Yellow rail (long)"); p.SpreadScale=0; p.SpreadBonus=2; p.PelletOverride=3; p.MinRange=1250; p.MaxRange=1900
    notes    Tighter and faster than Missile. Same tracer/real alternation.

    ATTACK   RS_YellowCGuy.M1
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1409
    shape    HITSCAN
    payload  rail trace x6 (3 tracer + 3 damaging)
    arc      0 -- spread_xy 0 AND aim 0: dead straight, no autoaim
    timing   5,4,(2),5,4,(2),5,4,2 -- 33 tics, then Goto See
    damage   random(1,4) per damaging rail, raw
    type     Hitscan
    sound    --   SILENT
    impact   RS_CGRailBuff puff + seekers
    trigger  Missile   (via A_JumpIfCloser(1250,"M1"))
    range    750..1250
    mirrored no
    inherit  --
    profile  MakeHitscan(profName:"Yellow rail (mid)"); p.SpreadScale=0; p.SpreadBonus=0; p.PelletOverride=3; p.MinRange=750; p.MaxRange=1250
    notes    `aim` drops to 0 here where the other two bands use 1. At this
             range the monster no longer needs autoaim and fires perfectly
             straight -- the tightest of the three rail bands.

    ATTACK   RS_YellowCGuy.Spam
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1420
    shape    BURST
    payload  RS_PlasmaBallSP3 x9
    arc      +/-1, +/-1, +/-3, +/-2, +/-1, +/-1, +/-1 (per call; the last two lines are 2 frames each)
    timing   4,(2),4,(2),3,(2),3,(2),2,1,1,1,1 -- 28 tics, ACCELERATING
    damage   Damage 5 --> ENGINE ROLL 5 * random(1,8) = 5..40 per ball
    type     Plasma
    sound    --   from the monster. Each ball plays its own SeeSound "weapons/plasmaf".
    impact   PLSE A-E flash, DeathSound "weapons/plasmax". No A_Explode -- contact damage only.
    trigger  Missile   (via A_JumpIfCloser(750,"Spam"))
    range    300..750
    mirrored no
    inherit  --   (RS_PlasmaBallSP3 is a flat Actor, RS_ZombiemanFX.zs:871; CH MASTERMINDS/Spiders.txt:1886)
    profile  MakeBurst(proj:"RS_PlasmaBallSP3", count:9, delayTics:3, arc:2)
    notes    A REAL ACCELERATION: gaps 4,4,3,3,2,1,1,1,1 as it winds up. That
             ramp is the attack -- a uniform 3 makes it 27 tics of even fire
             instead of a spin-up, and the felt difference is total.
             `PZOW FF 1` on the last two lines is 2 frames = 2 balls each, so
             the tail is FOUR balls one tic apart, not two.
             80/256 chance of chaining straight into Spam2 afterward
             (`A_Jump(82,"Spam2")` at :1432).

    ATTACK   RS_YellowCGuy.Spam2
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1436
    shape    FAN
    payload  RS_PlasmaBallSP3 x8
    arc      20 total, swept +3,-3,-6,-3,0,+3,+6,0 -- a ZIGZAG, not a monotone sweep
    timing   1,2,2,3,3,2,2,1  (16 tics; 5-tic aim first)
    damage   Damage 5 --> 5 * random(1,8) = 5..40 per ball
    type     Plasma
    sound    --   (per-ball SeeSound "weapons/plasmaf")
    impact   PLSE A-E, DeathSound "weapons/plasmax", contact only
    trigger  Missile   (via A_JumpIfCloser(300,"Spam2"), and by A_Jump(82) out of Spam)
    range    ..300
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_PlasmaBallSP3", count:8, arc:20); p.BurstDelayTics=2; p.MaxRange=300
    notes    THE ANGLE SEQUENCE IS EXPLICIT, NOT RANDOM, AND IT IS NOT
             MONOTONE: +3,-3,-6,-3,0,+3,+6,0. It crosses the centreline three
             times. VolleyArc produces an even sweep across 20 degrees, which
             is a different-looking attack with the same count. The timing is
             also a slow-fast-slow envelope (1,2,2,3,3,2,2,1). Both are lost.
             Ends `Goto Dodge`, not See -- the monster strafes immediately
             after, which is why the fan reads as a drive-by.

## RS_RedCGuy — tier 6, "Red Chaingunner" (detonating bullets)

Three bands off `A_JumpIfCloser(500,"M1")` / `(1300,"M2")`.
Every band's puff EXPLODES; the bullet damage is the smaller half.

    ATTACK   RS_RedCGuy.Missile
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1556
    shape    HITSCAN
    payload  hitscan trace, random(1,2) bullets per call, x2 calls per cycle (2..4 rounds)
    arc      +/-random(3,14) horizontal, 0 vertical -- horizontal-only, and ROLLED
    timing   4,4  then 1-tic refire -- 9-tic sustained cycle
    damage   random(1,2) per bullet --> EFFECTIVE random(1,2)*random(1,3) = 1..6, PLUS puff A_Explode(random(1,3),32)
    type     Hitscan (trace) + Fire (puff explosion)
    sound    "chainguy/attack" (bullet attack) + "weapons/firex4" per puff (RS_DetoPuffCG SeeSound, inherited)
    impact   RS_DetoPuff3 (RS_ChaingunnerFX.zs:644): MISL B/C spawn at scale 0.2, then on hitting an actor the Melee state runs A_Explode(random(1,3), radius 32)
    trigger  Missile
    range    1300..
    mirrored no
    inherit  RS_DetoPuffCG (zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:231). RS_DetoPuff3 overrides ONLY the States block -- its +PUFFONACTORS, +ALWAYSPUFF, DamageType "Fire", SeeSound "weapons/firex4", Alpha, VSpeed and Mass all come from the parent. Reading RS_DetoPuff3 alone reports a puff with no sound and no damage type.
    profile  MakeHitscan(fireSnd:"chainguy/attack", profName:"Red deto (long)"); p.SpreadScale=0; p.SpreadBonus=8.5; p.PelletOverride=2; p.ImpactPuff="RS_DetoPuff3"
    notes    THE PUFF IS THE WEAPON. Bullet damage is 1..6; the explosion is
             the reason it hurts, and it is radius damage so it ignores cover
             the trace respects. This is the one row in the family where
             `ImpactPuff` on the profile carries most of the payload -- and
             the heavy/bullet paths skip ImpactPuff by design, so it has to
             be a HITSCAN profile to work at all (RS_Weapon.zs:672-681).
             ±random(3,14) horizontal with ZERO vertical is a flat horizontal
             smear; A_FireBullets(spread, spread, ...) is symmetric and
             cannot express it.

    ATTACK   RS_RedCGuy.M2
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1560
    shape    HITSCAN
    payload  hitscan trace, random(1,2) bullets per call, x2 calls (2..4 rounds)
    arc      +/-random(2,11) horizontal, 0 vertical
    timing   4,4 + 1 refire -- 9-tic cycle
    damage   random(1,2) --> EFFECTIVE 1..6, PLUS puff A_Explode(random(1,4),38)
    type     Hitscan + Fire
    sound    "chainguy/attack" + "weapons/firex4" per puff (inherited)
    impact   RS_DetoPuff2 (RS_ChaingunnerFX.zs:631): scale 0.28, Melee state A_Explode(random(1,4), radius 38)
    trigger  Missile   (via A_JumpIfCloser(1300,"M2"))
    range    500..1300
    mirrored no
    inherit  RS_DetoPuffCG -- same as RS_DetoPuff3; States overridden only
    profile  MakeHitscan(fireSnd:"chainguy/attack", profName:"Red deto (mid)"); p.SpreadScale=0; p.SpreadBonus=6.5; p.PelletOverride=2; p.ImpactPuff="RS_DetoPuff2"; p.MinRange=500; p.MaxRange=1300
    notes    Tighter cone and a bigger blast than the long band. The three
             RS_DetoPuff* are a clean size ladder: 32 / 38 / 42 radius,
             random(1,3) / random(1,4) / random(2,6) damage.

    ATTACK   RS_RedCGuy.M1
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1564
    shape    HITSCAN
    payload  hitscan trace, random(1,3) bullets per call, x2 calls (2..6 rounds)
    arc      +/-random(1,8) horizontal, 0 vertical
    timing   4,4 + 1 refire -- 9-tic cycle
    damage   random(2,4) --> EFFECTIVE random(2,4)*random(1,3) = 2..12, PLUS puff A_Explode(random(2,6),42)
    type     Hitscan + Fire
    sound    "chainguy/attack" + "weapons/firex4" per puff
    impact   RS_DetoPuffCG itself (zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:231): scale 0.35, Melee state A_Explode(random(2,6), radius 42)
    trigger  Missile   (via A_JumpIfCloser(500,"M1"))
    range    ..500
    mirrored no
    inherit  --   (RS_DetoPuffCG is the base of the three; lives in the SHOTGUNNER file, not this family's)
    profile  MakeHitscan(fireSnd:"chainguy/attack", profName:"Red deto (close)"); p.SpreadScale=0; p.SpreadBonus=4.5; p.PelletOverride=3; p.ImpactPuff="RS_DetoPuffCG"; p.MaxRange=500
    notes    Up to SIX exploding rounds per 9-tic cycle at point blank, each
             with a 42-radius blast. Tightest cone, most bullets, biggest
             puff -- the ladder resolves at close range, again.

## RS_FireBluCGuy2 — tier 7, "Bad makeup day"

    ATTACK   RS_FireBluCGuy2.Missile
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:817
    shape    SCATTER
    payload  RS_FireBCGguy x11
    arc      aimed shots +/-1 to +/-3; wild flankers +/-15 and +/-35 -- a 70-degree outer cone
    timing   4,1,1,(2),4,(2),3,1,1,(2),3,(2),2,1,1 -- 28 tics, then Goto See (NO refire)
    damage   DamageFunction (random(5,20)) contact, PLUS A_Explode(random(4,15),64) x8 IN FLIGHT and A_Explode(random(5,15),64) x3 on death
    type     Fire
    sound    --   from the monster (no A_PlaySound in the state; AttackSound is not set on this monster either). Each fireball plays SeeSound "imp/attack" on spawn.
    impact   FIRE F/G/H, three frames each running A_Explode(random(5,15), radius 64), DeathSound "imp/shotx"
    trigger  Missile
    range    --   (no band gate at all -- the only mid-tier with none)
    mirrored no
    inherit  --   (RS_FireBCGguy is a flat Actor, RS_ChaingunnerFX.zs:455)
    profile  MakeBurst(proj:"RS_FireBCGguy", count:11, delayTics:2, arc:70)
    notes    THE FLIGHT PATH IS ITSELF AN ATTACK. RS_FireBCGguy's `Fly` state
             is `FIRE CDEEDCDE 3 A_Explode(random(4,15),64)` -- EIGHT frames,
             so eight 64-radius explosions every 24 tics for the whole
             flight, on a LOOPING state. It is a moving damage field, not a
             projectile that explodes at the end. +THRUACTORS means it does
             not stop on contact, so it flies through you still detonating.
             This is one of the ~55 deliberate multi-frame A_Explode sites --
             do not collapse it.
             The firing pattern is a repeated TRIPLET: one aimed shot (±1..3),
             then two wild flankers at ±15 and ±35 one tic apart. Three
             triplets plus two extra aimed shots. A flat SCATTER cone loses
             the aimed/wild structure entirely.

## RS_GrayCGuy2 — tier 8, "That is bad camo" (the sniper)

**The family's sharpest hitscan rhythms live here.** Four bands off
`A_JumpIfCloser` 400 / 800 / 1400. Every band ends `Goto See` — there is no
refire loop, so each engagement is one full 5-round burst and out.

    ATTACK   RS_GrayCGuy2.Missile[+2]   (the target designator)
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:662
    shape    VILE
    payload  RS_CHBSTarget x1, spawned AT the target's feet
    arc      --
    timing   one tic (5-tic frame); it sits inside a 40-tic wind-up (15 aim + 5 paint + 20 aim)
    damage   --   ZERO. It does no damage of any kind.
    type     --
    sound    "prox/beep" x2, played by the marker at ATTN_NONE (audible map-wide) -- RS_ShotgunnerFX.zs:826, :831
    impact   --   (marker only: CHTA A blinking on/off for ~28 tics, +NOINTERACTION +NOCLIP +NOGRAVITY)
    trigger  Missile
    range    --   (fires on EVERY entry to Missile, before any band gate)
    mirrored no
    inherit  --   (RS_CHBSTarget is a flat Actor in zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:807, CH Shotgunners.txt:1813)
    profile  -- no factory fits; this is a marker spawn, not an attack. Nearest honest form: MakeVolley(proj:"RS_CHBSTarget", count:1, fireSnd:"prox/beep") with DamageMult 0.
    notes    RECORDED AS A ROW BECAUSE IT IS THE TELL. Forty tics of wind-up
             and a map-wide beep is what makes a 5-round accelerating burst
             from an invisible-ish sniper survivable. A weapon that wears the
             Gray burst without wearing the designator is a different and
             much nastier weapon. `A_VileTarget` spawns at `target.Pos` and
             calls `fog.A_Fire(0)` once (engine, archvile.zs).

    ATTACK   RS_GrayCGuy2.Missile[+7]   (the long-range burst)
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:667
    shape    HITSCAN
    payload  hitscan trace x5, 1 bullet each
    arc      +/-2 horizontal, +/-2 vertical
    timing   FIRE TICS 5,4,3,2,1 -- inter-shot gaps 9,7,5,3 (aim frames 4,3,2,1 between). 25 tics total.
    damage   random(1,6) per bullet --> EFFECTIVE random(1,6)*random(1,3) = 1..18
    type     Hitscan
    sound    --   from the attack itself: this monster has NO AttackSound property, so A_CustomBulletAttack's A_StartSound(AttackSound) plays nothing. Each puff plays SeeSound "weapons/firex4".
    impact   RS_GrayCGuff (RS_ChaingunnerFX.zs:362) -- see the RING row in Section 2. On hitting an actor: A_Explode(random(1,12), radius 64) AND a 12-nail 360-degree ring.
    trigger  Missile
    range    1400..
    mirrored no
    inherit  --
    profile  MakeHitscan(profName:"Gray sniper (extreme)"); p.SpreadScale=0; p.SpreadBonus=2; p.PelletOverride=1; p.BurstDelayTics=5 /* INERT -- see UNRESOLVED U1 */
    notes    **THE ACCELERATING BURST. THIS IS THE ROW THE WHOLE FAMILY IS
             WORTH.** Five rounds whose gaps close 9 -> 7 -> 5 -> 3 tics. It
             is a gun spinning up, and it is completely inexpressible in the
             current profile layer: BurstDelayTics is a single uniform int,
             and the hitscan dispatch does not read it at all. Written here
             exactly so the ramp survives until something can hold it.
             Note the burst NEVER refires -- 5 rounds, then Goto See, then a
             fresh 40-tic designator wind-up. A player weapon that loops this
             is not the same weapon.

    ATTACK   RS_GrayCGuy2.M1
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:678
    shape    HITSCAN
    payload  hitscan trace x5, 1 bullet each
    arc      +/-1 horizontal, +/-1 vertical
    timing   FIRE TICS 5,4,2,2,1 -- inter-shot gaps 9,7,4,3. 24 tics.
    damage   random(2,9) --> EFFECTIVE random(2,9)*random(1,3) = 2..27
    type     Hitscan
    sound    --   (no AttackSound on this monster; per-puff "weapons/firex4")
    impact   RS_GrayCGuff -- A_Explode(random(1,12),64) + 12-nail ring
    trigger  Missile   (via A_JumpIfCloser(1400,"M1"))
    range    800..1400
    mirrored no
    inherit  --
    profile  MakeHitscan(profName:"Gray sniper (long)"); p.SpreadScale=0; p.SpreadBonus=1; p.PelletOverride=1
    notes    THE RAMP IS IRREGULAR HERE AND THAT IS CH'S, NOT OURS. The third
             shot is 2 tics where the pattern wants 3, so the sequence is
             5,4,2,2,1 rather than 5,4,3,2,1. Verified against CH
             Chaingunners.txt:663-671 -- identical. Do not "correct" it to
             match the other three bands.

    ATTACK   RS_GrayCGuy2.M2
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:689
    shape    HITSCAN
    payload  hitscan trace x5, 1 bullet each
    arc      0 -- perfectly accurate
    timing   FIRE TICS 5,4,3,2,1 -- gaps 9,7,5,3. 25 tics.
    damage   random(3,10) --> EFFECTIVE random(3,10)*random(1,3) = 3..30
    type     Hitscan
    sound    --   (per-puff "weapons/firex4")
    impact   RS_GrayCGuff -- A_Explode(random(1,12),64) + 12-nail ring
    trigger  Missile   (via A_JumpIfCloser(800,"M2"))
    range    400..800
    mirrored no
    inherit  --
    profile  MakeHitscan(profName:"Gray sniper (mid)"); p.SpreadScale=0; p.SpreadBonus=0; p.PelletOverride=1
    notes    Zero spread from 800 units in. Same accelerating ramp.

    ATTACK   RS_GrayCGuy2.M3
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:700
    shape    HITSCAN
    payload  hitscan trace x5, 1 bullet each
    arc      0
    timing   FIRE TICS 5,4,3,2,1 -- gaps 9,7,5,3. 25 tics.
    damage   random(4,12) --> EFFECTIVE random(4,12)*random(1,3) = 4..36
    type     Hitscan
    sound    --   (per-puff "weapons/firex4")
    impact   RS_GrayCGuff -- A_Explode(random(1,12),64) + 12-nail ring
    trigger  Missile   (via A_JumpIfCloser(400,"M3"))
    range    ..400
    mirrored no
    inherit  --
    profile  MakeHitscan(profName:"Gray sniper (close)"); p.SpreadScale=0; p.SpreadBonus=0; p.PelletOverride=1
    notes    The full ladder in one place -- spread 2,1,0,0 and damage
             random(1,6), random(2,9), random(3,10), random(4,12) as range
             closes. Effective peak (x random(1,3), x5 rounds, plus five
             64-radius explosions and five 12-nail rings) is 180+ before the
             rings are counted. This is a boss-grade output on a tier-8.

## RS_AbyssCGuy2 — tier 9, "Abyss Captain"

Fades to 10% translucent while chasing (`Hide`); the Missile state fades it
back in over 3 tics before firing, so the attack is preceded by a reveal.

    ATTACK   RS_AbyssCGuy2.Missile
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:551
    shape    VILE
    payload  RS_SplashAbyssCguy x2, each spawned AT the target's feet
    arc      --   (no travel: A_VileTarget spawns at target.Pos)
    timing   4, (2), 4  -- 6-tic gap between the two; 13-tic wind-up before
    damage   A_Explode(random(2,12), radius 32) per blast. +FORCERADIUSDMG, so cover does not help. DamageFunction (random(1,9)) Ice is on the class but never applies -- it never travels.
    type     Ice
    sound    --   from the attack. The blast actor has no SeeSound or DeathSound.
    impact   BAL7 C/D/E abyss-blue burst at scale 0.5, one RS_AbyssShotIdentifier marker (gated on cvar rs_ch_abyssmark), ThrustThingZ(0,random(1,33)) -- it POPS the victim upward
    trigger  Missile
    range    700..
    mirrored no
    inherit  --   (RS_SplashAbyssCguy is a flat Actor, RS_ChaingunnerFX.zs:331. Distinct from RS_SplashAbyss / RS_SplashAbyss2 in the zombieman file.)
    profile  -- no factory fits (no travel, spawn-at-target). Nearest: MakeRadial(radius:32, damage:7); MinRange 700. Loses the at-target placement and the upward thrust.
    notes    ITS SPAWN STATE IS `TNT1 A 0;` AND FALLS STRAIGHT THROUGH INTO
             `Death:`. There is no Fly state at all -- the actor exists for
             one tic, at your feet, and detonates. Reading it as a
             projectile with Speed 16 reports travel that never happens.
             `A_JumpIfCloser(700,"Rapids",true)` -- the third arg is `noz`,
             so the range test IGNORES height difference. On a stairwell this
             band picks differently than a flat reading suggests.
             `Goto Missile+5` re-enters at the 10-tic FaceTarget, so the
             translucency fade-in happens once per engagement, not per volley.

    ATTACK   RS_AbyssCGuy2.Rapids
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:561
    shape    BURST
    payload  RS_AbyssZShotCH3 x4
    arc      +/-1
    timing   3,(2),3,(2),3,(2),3,(2) -- uniform 5-tic interval, 20 tics
    damage   DamageFunction (random(5,30)) INHERITED, plus on-death A_Explode(random(1,8),42) x3 frames INHERITED
    type     Ice   (INHERITED)
    sound    --   from the monster. Each shot plays SeeSound "imp/attack" (INHERITED).
    impact   BAL7 C/D/E at scale 0.85, THREE frames each running A_Explode(random(1,8), radius 42), DeathSound "imp/shotx" -- ALL INHERITED from RS_AbyssZShotCH
    trigger  Missile   (via A_JumpIfCloser(700,"Rapids",noz:true))
    range    ..700
    mirrored no
    inherit  RS_AbyssZShotCH (zscript/monsters/zombieman/RS_Zombieman.zs:764). RS_AbyssZShotCH3 (:811) overrides ONLY Radius, Height, Speed, XScale, YScale. Its damage, damage type, both sounds, the +DONTHARMCLASS flag, the whole Fly/Death chain and the RS_AbyssShotIdentifier trail are the parent's. Reading the child alone reports a silent, damageless projectile.
    profile  MakeBurst(proj:"RS_AbyssZShotCH3", count:4, delayTics:5, arc:2); p.MaxRange=700
    notes    THE CLEANEST BURST IN THE FAMILY -- 4 rounds, uniform 5-tic
             spacing, ±1 spread, one payload class. It is the one row here
             that MakeBurst can hold exactly as written.
             Its Fly state sheds an RS_AbyssShotIdentifier every 4 tics and
             weaves (A_Weave(2,1,2,0.1)) -- inherited, cosmetic, cvar-gated
             on rs_ch_abyssmark.

## RS_BlackCGuyEX — tier 10, "LET ME SEE YOUR WARFACE"

Boss. `Missile` is a pure picker: `A_JumpIfHealthLower(5000,"Phase2")` then
`A_Jump(255, "RedSpam","YellowBomb","BigBomb","RapidFire")` — 255/256 to
pick one of four uniformly. Phase2 sets `+MISSILEEVENMORE` and `+ALWAYSFAST`
permanently and re-enters the same picker. `YellowBomb` is a range gate
(`A_JumpIfCloser(1200,"YE")`, else re-roll), not a row.

    ATTACK   RS_BlackCGuyEX.YE
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1707
    shape    SINGLE
    payload  RS_YellowBombCGUYEX x1   (preceded by 9 cosmetic RS_SparkPuff1)
    arc      --
    timing   9 spark puffs over ~13 tics (2 on tic 0, then 7 at 1 tic each), then the bomb on a 3-tic frame; 9-tic recovery
    damage   DamageFunction (random(20,80)) on contact, then an EIGHT-STAGE detonation -- see the Section 2 row
    type     Fire
    sound    "spit/spit" (bomb SeeSound). The spark puffs are silent. A_Quake(2,12,0,128) one tic before launch.
    impact   see RS_YellowBombCGUYEX.Death in Section 2 -- 30..90 damage at radius 312 at the top of the cascade
    trigger  Missile   (via A_Jump(255) -> YellowBomb -> A_JumpIfCloser(1200,"YE"))
    range    ..1200
    mirrored no
    inherit  --
    profile  MakeHeavy(proj:"RS_YellowBombCGUYEX", fireSnd:"spit/spit", bigMuzzle:true, spawnHeight:40); p.MaxRange=1200
    notes    THE SPARK CHARGE IS THE TELL, AND IT CARRIES A CH BUG WE KEPT.
             `A_CustomMissile("RS_SparkPuff1",40,0,CMF_AIMOFFSET,random(0,360),random(0,360))`
             passes CMF_AIMOFFSET (=1) in the ANGLE slot and random(0,360) in
             the FLAGS slot. That is CH's own arg-order mistake
             (Chaingunners.txt:1988, :1990), kept verbatim; it compiles and
             only affects a +NOINTERACTION cosmetic puff.
             `HCPO EEEEEEE 1` is SEVEN frames = seven puffs, plus `TNT1 AA 0`
             = two more. Nine, not two.
             The bomb turns off +NOGRAVITY partway through its Fly state
             (RS_ChaingunnerFX.zs:682) -- it flies flat, then drops. That arc
             is the whole aiming problem it poses and no profile field holds it.

    ATTACK   RS_BlackCGuyEX.BigBomb
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1718
    shape    SINGLE
    payload  RS_CGBigEx x1   (preceded by RS_RedRevLoad + RS_SpiralLoadGeneEX charge flares)
    arc      --
    timing   1 aim, flare, 20 aim (Fast), flare, 20 aim (Fast), quake, 3-tic launch, 9 recovery -- 53 tics, the longest wind-up in the family
    damage   DamageFunction (random(30,80)) contact. In flight it sheds RS_SpiralSaw5 and RS_EXPLOSIONSCGuyEX continuously. On death: A_Explode x9 at random(5,30)/164, then random(55,111)/386, then random(66,128)/386, plus ~200 delayed sub-blasts.
    type     Plasma
    sound    "Weapons/BFGF" (RS_RedRevLoad flare), "Spell/SpellCast1" (the shot's SeeSound), A_Quake(2,12,0,128) at launch
    impact   see RS_CGBigEx.Death in Section 2 -- the single largest damage event in this family
    trigger  Missile   (via A_Jump(255))
    range    --
    mirrored no
    inherit  --
    profile  MakeHeavy(proj:"RS_CGBigEx", fireSnd:"Spell/SpellCast1", bigMuzzle:true, spawnHeight:40)
    notes    41 TICS OF TELEGRAPH BEFORE THE SHOT LEAVES. Two separate charge
             flares 20 tics apart, both on `Fast` frames (so they get FASTER
             on higher skill, not slower). That wind-up is the counterplay
             and no profile field records it; a weapon wearing this fires it
             instantly and is a completely different weapon.
             The `HCPO F 0` flare frames are 0 tics -- they spawn the flare
             and pass through; the 20-tic waits are the `HCPO E 20 Fast`
             frames after them.

    ATTACK   RS_BlackCGuyEX.RapidFire
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1727
    shape    HITSCAN
    payload  hitscan trace, random(1,3) bullets per call, x2 calls per cycle (2..6 rounds)
    arc      +/-6 horizontal, +/-5 vertical
    timing   4,4 then 2-tic refire -- 14-tic sustained cycle including a fresh beep each pass
    damage   random(1,4) per bullet --> EFFECTIVE random(1,4)*random(1,3) = 1..12, PLUS puff A_Explode(random(2,6),42)
    type     Hitscan + Fire (puff)
    sound    "prox/beep" ONCE PER CYCLE (A_PlaySound at :1723) + "weapons/firex4" per puff. The monster has no AttackSound, so the bullet attack itself is silent.
    impact   RS_DetoPuffCG (zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:231) -- Melee state A_Explode(random(2,6), radius 42)
    trigger  Missile   (via A_Jump(255))
    range    --
    mirrored no
    inherit  --   (RS_DetoPuffCG is the base class, lives in the shotgunner file)
    profile  MakeHitscan(fireSnd:"prox/beep", profName:"WARFACE rapid"); p.SpreadScale=0; p.SpreadBonus=6; p.PelletOverride=3; p.ImpactPuff="RS_DetoPuffCG"
    notes    A BEEP ON EVERY CYCLE, NOT JUST THE FIRST. `Goto RapidFire+1`
             lands on the A_PlaySound line, so the proximity beep repeats
             every 14 tics for as long as A_MonsterRefire(188) holds the
             loop. That pulsing beep IS the attack's voice -- the gun itself
             is silent.
             The only exploding-hitscan on a boss in this family, and the
             widest deto cone (±6/±5 vs Red's horizontal-only smear).

    ATTACK   RS_BlackCGuyEX.RedSpam
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1738
    shape    MULTI
    payload  RS_SpamShotsCguyEX x6 + RS_SpamShotsCguyEX2 x6  (12 total, alternating in blocks)
    arc      widens per block: +/-5, +/-9, +/-11, +/-13 horizontal; +/-4 vertical throughout
    timing   3,3,3,3,(1),3,3,3,3,(1),3,3,(1),3,3 -- 38 tics
    damage   DamageFunction (random(10,120)) EACH -- the widest single roll in the family
    type     Plasma (EX) / Fire (EX2)
    sound    "weapons/bfgf" per shot (SeeSound), A_Quake(2,12,0,128) at the start; two RS_SpiralLoadGeneEX charge flares 15 tics apart before it
    impact   GRFZ I-P cascade: A_Explode(random(22,88), radius 256), then 3 + 4 RS_EXPLOSIONSCGuyEX spawned in a 128-unit box, then 2 RS_EXPLOSIONSCGuyEXDelayd. See Section 2.
    trigger  Missile   (via A_Jump(255))
    range    --
    mirrored no
    inherit  RS_SpamShotsCguyEX2 : RS_SpamShotsCguyEX (RS_ChaingunnerFX.zs:751) -- it overrides ONLY `DamageType "Fire"`. Everything else, including the entire 256-radius death cascade, is the parent's. The two are visually identical and differ only in damage type.
    profile  MakeBurst(proj:"RS_SpamShotsCguyEX", count:12, delayTics:3, arc:26, pitchJitter:4)  -- loses the EX2 alternation entirely; a true version needs two profiles in a slot rotation [EX,EX,EX,EX,EX2,EX2,EX2,EX2,EX,EX,EX2,EX2]
    profile  MakeBurst(proj:"RS_SpamShotsCguyEX2", count:6, delayTics:3, arc:26, pitchJitter:4)
    notes    THE ALTERNATION IS THE POINT AND IT IS WHAT RS_AttackSlot EXISTS
             FOR. Four EX, four EX2, two EX, two EX2 -- a damage-type cycle,
             which matters against this family's own DamageFactor tables.
             This is the clearest argument in the catalog for a rotation
             rather than a single profile.
             `HCPO FEFE 3` = FOUR frames = four shots. `HCPO FE 3` = two.
             12 total, not 4.
             Twelve rounds of random(10,120) each, every one with a
             256-radius death blast, is 120..1440 contact plus cascades.

    ATTACK   RS_BlackCGuyEX.Death
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1754
    shape    SCATTER
    payload  RS_HKRedDeath x7
    arc      +/-30 horizontal (spawnofs_xy random(-30,30)), spawn height random(20,100), pitch -10, CMF_AIMOFFSET
    timing   5,5,5,5,5,5,5 -- 35 tics of chained explosions
    damage   A_Explode(random(5,10), radius 42) each, plus A_Burst("RS_RedThingsHK") debris
    type     Fire
    sound    "world/barrelx" x2 per blast (Spawn and again on the C frame)
    impact   MISL B/C/D barrel-style explosion; A_Burst throws RS_RedThingsHK shards
    trigger  Death
    range    --
    mirrored no
    inherit  --   (RS_HKRedDeath is a flat Actor, zscript/monsters/zombieman/RS_ZombiemanFX.zs:844, CH Hellknights.txt:2231)
    profile  MakeBurst(proj:"RS_HKRedDeath", count:7, delayTics:5, arc:60, trigger:RS_FIRE_DEATH)
    notes    `HCPO HHHHHHH 5` is SEVEN frames = seven barrel explosions over
             35 tics, walking outward. Killing this boss at melee range is
             lethal and this row is why. FireTrigger RS_FIRE_DEATH exists on
             the profile class for exactly this and is currently read by
             nothing (UNRESOLVED U1).

## RS_BlackCGuy2 — tier 10, "ITS MR GENERAL TO YOU, MAGGOT"

Boss. `Missile` is a pure picker: `A_Jump(256,"SpamShots","ShieldBlast","BigOne")`
— always jumps, uniform 1/3. `Pain` has a 50% chance to jump to `Shield`.

    ATTACK   RS_BlackCGuy2.SpamShots
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1828
    shape    SCATTER
    payload  RS_SpamShotsCguy x9
    arc      widens per block: +/-7, then +/-15, then +/-20
    timing   5,5,5 | 5,5,5 | 5,5,5 -- uniform 5 tics, 45 tics + 14 wind-up + 8 tail
    damage   DamageFunction (random(10,60)) contact + A_Explode(random(5,45), radius 128) on death
    type     Plasma
    sound    "weapons/bfgf" per shot (SeeSound)
    impact   BFE1 A/B/C at scale 1.15, A_Explode(random(5,45), radius 128), DeathSound "weapons/bfgx"
    trigger  Missile   (via A_Jump(256))
    range    --
    mirrored no
    inherit  --   (RS_SpamShotsCguy is a flat Actor, RS_ChaingunnerFX.zs:967)
    profile  MakeBurst(proj:"RS_SpamShotsCguy", count:9, delayTics:5, arc:40)
    notes    RS_SpamShotsCguy CARRIES +SEEKERMISSILE BUT NEVER CALLS
             A_SeekerMissile -- its Spawn is `BFS1 AB 2 Bright; Loop;`. The
             flag makes the engine assign a tracer; nothing ever steers
             toward it. THE BALLS DO NOT HOME. Same trap as RS_GenShield
             below, and the mirror of RS_Boomer3's (which calls the action
             but clears the flag). CH is identical -- not an import error.
             `BFGZ FEF 5` = THREE frames = three shots per line, nine total.
             128/256 chance to loop the whole thing again (:1834).

    ATTACK   RS_BlackCGuy2.Shield[+3]   (the shield deploy)
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1840
    shape    SINGLE
    payload  RS_GenShield x1
    arc      +/-7
    timing   one tic (2-tic frame), then 46 tics of standing still
    damage   Damage 0 -- literally zero, it is not a weapon
    type     Plasma (declared, never applied)
    sound    --   (no SeeSound on RS_GenShield)
    impact   BFS1 A/B/A for 45 tics, then BFE1 A-C shrinking, then it fires 3 RS_TrailSPCguy -- see the Section 2 row
    trigger  Missile   (via A_Jump(256) -> ShieldBlast, or A_Jump(128) from Pain)
    range    --
    mirrored no
    inherit  --
    profile  MakeSelfBuff(speedMult:1.0, duration:50, noPain:true, profName:"General shield") -- the reflective invulnerability is the actual mechanic; the orb is decoration
    notes    THE ORB IS NOT THE ATTACK. `A_SetReflectiveInvulnerable` one tic
             before it and `A_UnSetReflectiveInvulnerable` ~55 tics later is:
             for that window the General is invulnerable AND REFLECTS
             PROJECTILES BACK AT YOU. `bNOPAIN = true` is set and never
             cleared in this state.
             RS_GenShield has +SEEKERMISSILE with no A_SeekerMissile call --
             same inert-homing trap as RS_SpamShotsCguy. It also carries
             `DropItem "Cell"` on a projectile, which is CH's, verbatim.

    ATTACK   RS_BlackCGuy2.Shield[+6]   (the trail volley; also the whole of ShieldBlast)
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1843
    shape    BURST
    payload  RS_TrailSPCguy x6
    arc      +/-7
    timing   3,3,3,3,3,3 -- uniform, 18 tics
    damage   no Damage/DamageFunction -- contact damage is ZERO. All of it is A_Explode(10, radius 32) x5 FRAMES on death = five fixed 10-damage blasts.
    type     Plasma
    sound    --   (no SeeSound on RS_TrailSPCguy)
    impact   APBX A-E, FIVE frames each running A_Explode(10, radius 32). Its Spawn also sheds an RS_TrailSP2 every 2 tics, and RS_TrailSP2's own death is another A_Explode(7,32) x5.
    trigger  Missile   (via ShieldBlast:1848 `Goto Shield+6`, or straight through from the shield deploy, or from Pain)
    range    --
    mirrored no
    inherit  --   (RS_TrailSPCguy is a flat Actor, zscript/monsters/zombieman/RS_ZombiemanFX.zs:927, CH Chaingunners.txt:2418)
    profile  MakeBurst(proj:"RS_TrailSPCguy", count:6, delayTics:3, arc:14)
    notes    TWO ENTRY POINTS, ONE ATTACK. `Shield` deploys the orb and then
             fires this; `ShieldBlast` (`BFGZ E 6; Goto Shield+6`) skips
             straight to it with no shield and no invulnerability. The picker
             at :1825 rolls ShieldBlast, NOT Shield -- the shielded version is
             only ever reached from Pain. So the shield is a RETALIATION and
             the naked volley is the normal attack.
             `BFGZ FEFEFE 3` = SIX frames = six trails.
             A_Explode(10,32) with a literal 10 is one of the few
             non-rolled damage numbers in the whole family.

    ATTACK   RS_BlackCGuy2.BigOne
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1857
    shape    SINGLE
    payload  RS_CGBigOne x1   (preceded by 2 RS_RedRevLoad charge flares)
    arc      --   (spawnofs_xy 8)
    timing   20 aim, 15 aim, flare(5), 8, flare(5), 8, launch(8), 2 -- 71 tics, the longest of any attack here
    damage   DamageFunction (random(30,80)) contact; in flight it lays a bouncing floor-fire trail; on death A_Explode(random(5,30), radius 164) x9 FRAMES
    type     Plasma
    sound    "Weapons/BFGF" x2 (the two RS_RedRevLoad flares), then "Spell/SpellCast1" (the shot's SeeSound)
    impact   see RS_CGBigOne.Death in Section 2 -- nine 164-radius blasts
    trigger  Missile   (via A_Jump(256))
    range    --
    mirrored no
    inherit  --
    profile  MakeHeavy(proj:"RS_CGBigOne", fireSnd:"Spell/SpellCast1", bigMuzzle:true, spawnHeight:32)
    notes    RS_CGBigOne GENUINELY HOMES -- A_SeekerMissile(3,6) with
             +SEEKERMISSILE intact, unlike three other seekers in this family
             that are inert. It is also the only one that lays a ground
             hazard: `A_CustomMissile("RS_GroundRedCyb",0,0)` every loop of
             its Spawn state (Section 2).
             Two RedRevLoad flares 13 tics apart is the tell. 61 tics of
             wind-up before launch.

    ATTACK   RS_BlackCGuy2.Death
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1867
    shape    SCATTER
    payload  RS_HKRedDeath x3
    arc      +/-30 horizontal, spawn height random(20,100), pitch -10, CMF_AIMOFFSET
    timing   8,8,8 -- 24 tics
    damage   A_Explode(random(5,10), radius 42) each + A_Burst("RS_RedThingsHK")
    type     Fire
    sound    "world/barrelx" x2 per blast
    impact   MISL B/C/D barrel explosion + RS_RedThingsHK shards
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_HKRedDeath", count:3, delayTics:8, arc:60, trigger:RS_FIRE_DEATH)
    notes    `BFGZ HHH 8` = three frames. The EX variant of this boss fires
             seven at 5 tics; the General fires three at 8. Same payload,
             different rhythm -- a clean pair for a rotation.

## RS_WhiteCguy2 — tier 11, "The crazy lady scientist"

Boss, 7777 HP. `Missile` picker: `A_JumpIfHealthLower(5555,"Phase2")` then
`A_Jump(256,"Puddle","Summon1","Darts","Summon2")`. `Phase2` fires ONCE
(guarded by `User_Ph2`), then every later entry falls to `Nah`, whose picker
is `A_Jump(256,"Summon1","Puddle2","DartStorm","Summon2","Summon3")` — a
strictly larger and nastier table.

    ATTACK   RS_WhiteCguy2.Puddle
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1976
    shape    SALVO
    payload  RS_Puddle1 x2 on one tic
    arc      +/-60 horizontal, pitch random(10,30), CMF_AIMDIRECTION
    timing   one tic (8 aim + 9 wind-up before)
    damage   Damage 4 --> ENGINE ROLL 4 * random(1,8) = 4..32, PLUS PoisonDamage 15 (PoisonDamageType "Poison") on contact
    type     Poison (via PoisonDamage; the direct hit is untyped)
    sound    --   from the attack. DeathSound "slimeball/splat" on landing.
    impact   BOGY D/E/F -- and each one then fires THREE RS_Puddle2 wandering pools. See the Section 2 row.
    trigger  Missile   (via A_Jump(256))
    range    --
    mirrored no
    inherit  --   (RS_Puddle1 is a flat Actor, RS_ChaingunnerFX.zs:1041)
    profile  MakeVolley(proj:"RS_Puddle1", count:2, arc:120, pitchJitter:20)
    notes    A LOBBED AREA-DENIAL SEED, NOT A PROJECTILE ATTACK. `-NOGRAVITY`
             plus pitch random(10,30) makes it an arc; the ±60° angle is far
             too wide to be aimed at anything. It is meant to land NEAR you
             and then grow.
             `FSZS FF 0` is 2 frames on ZERO tics -- both seeds leave on the
             same tic.
             `Damage 4` is a constant, so the engine rolls it 4..32. Writing
             "4" anywhere downstream loses an 8x spread.

    ATTACK   RS_WhiteCguy2.Puddle2
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1981
    shape    SALVO
    payload  RS_Puddle1 x4 on one tic
    arc      +/-80 horizontal, pitch random(12,35), CMF_AIMDIRECTION
    timing   one tic (8 aim + 9 wind-up before)
    damage   Damage 4 --> 4 * random(1,8) = 4..32 + PoisonDamage 15 each
    type     Poison
    sound    --   ; "slimeball/splat" on landing
    impact   as Puddle, x4 -- twelve RS_Puddle2 wandering pools if all four land
    trigger  Missile   (phase 2 only, via Phase2 -> Nah -> A_Jump(256))
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_Puddle1", count:4, arc:160, pitchJitter:23)
    notes    NAME COLLISION WORTH FLAGGING: the STATE `Puddle2` on the monster
             and the ACTOR CLASS `RS_Puddle2` (RS_ChaingunnerFX.zs:1001) are
             different things. The state fires RS_Puddle1, not RS_Puddle2.
             RS_Puddle2 is what RS_Puddle1 spawns when it lands. A grep for
             "Puddle2" returns both and they are unrelated.
             Phase-2 upgrade of Puddle: double the seeds, wider arc, higher
             lob. `FSZS FFFF 0` = 4 frames, 0 tics.

    ATTACK   RS_WhiteCguy2.Darts
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1986
    shape    SCATTER
    payload  RS_NeedlesCg1 x3
    arc      widening: +/-5, +/-15, +/-25
    timing   1,(1+0),1,(1+0),1 then 2-tic refire -- 3 needles per ~9-tic pass, then A_MonsterRefire(128) loops the WHOLE state including the 6-tic wind-up
    damage   DamageFunction (random(5,25)) contact, PLUS A_Explode(random(2,5),64) x6 frames AND A_Explode(random(2,8),64) x3 frames on death
    type     Melee   (yes -- DamageType "Melee" on a flying needle; CH's, verbatim)
    sound    "Jam/Jamd" per needle (SeeSound); "moloch/nailhit" + "gas/gas1" on impact
    impact   6PUF A-F (six frames, A_Explode(random(2,5),64) each) then FBL1 E/F/G (three frames, A_Explode(random(2,8),64) each) then an RS_Trail12 wisp -- NINE explosions per needle
    trigger  Missile   (via A_Jump(256))
    range    --
    mirrored no
    inherit  --   (RS_NeedlesCg1 is a flat Actor, RS_ChaingunnerFX.zs:1106)
    profile  MakeBurst(proj:"RS_NeedlesCg1", count:3, delayTics:2, arc:50)
    notes    DAMAGE TYPE "Melee" ON A RANGED PROJECTILE IS DELIBERATE IN CH
             AND MATTERS HERE: RS_CyanCGuy2 has `DamageFactor "Melee", 1.5`
             and RS_WhiteCguy2 itself has `DamageFactor "Melee", 3.75`. In
             infighting these needles hit the scientist's own kind for nearly
             quadruple. Do not "correct" the type.
             NINE explosions per needle from two multi-frame A_Explode lines
             is where the real damage is -- contact is random(5,25), the
             impact is up to 15+24=39 more in radius damage.
             `Goto Darts` re-runs the 6-tic wind-up every pass, so the
             sustained rate is 3 needles per ~15 tics, not per 9.

    ATTACK   RS_WhiteCguy2.DartStorm
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:1998
    shape    MULTI
    payload  RS_NeedlesCg1 x8 + RS_NeedlesCg2 x4  (12 total)
    arc      Cg1 at +/-15, +/-35, +/-25, +/-35, +/-15; Cg2 at +/-5 (aimed) and +/-25
    timing   five Cg1 on tic 0 (SALVO), then Cg2 at 1; (6+0); Cg2 at 8 with three Cg1 on tic 0; (6+0); Cg2 at 8 + Cg2 at 0 -- ~36 tics
    damage   Cg1 DamageFunction (random(5,25)) Melee; Cg2 DamageFunction (random(5,45)) Poison + PoisonDamage 15
    type     Melee (Cg1) / Poison (Cg2)
    sound    "Jam/Jamd" per needle (both classes); "moloch/nailhit" + "gas/gas1" on impact
    impact   Cg1: 9 explosions (see Darts). Cg2: 6PUF A-F x6 at A_Explode(random(2,8),64) then FBL1 E/F/G x3 at A_Explode(random(2,12),64) -- NINE explosions, larger rolls. Cg2 also trails RS_Trail14 in flight and sheds RS_Trail14/RS_Trail12 on death.
    trigger  Missile   (phase 2 only, via Phase2 -> Nah -> A_Jump(256))
    range    --
    mirrored no
    inherit  --   (RS_NeedlesCg2 is RS_ChaingunnerFX.zs:1070, a separate flat Actor -- NOT a subclass of Cg1)
    profile  MakeBurst(proj:"RS_NeedlesCg1", count:8, delayTics:2, arc:70)  + MakeBurst(proj:"RS_NeedlesCg2", count:4, delayTics:8, arc:25) as a two-entry rotation
    notes    THE SHAPE IS A CHAFF-AND-SPEAR PATTERN, not a burst: five wild
             Cg1 needles arrive on ONE tic as a scatter screen, then a single
             aimed Cg2 at ±5 comes through the middle of them. That repeats
             three times. Flattening it to one class loses the whole idea.
             Cg2 is the heavy: random(5,45) Poison + 15 poison, versus Cg1's
             random(5,25) Melee.
             Self-loops 128/256 back to DartStorm, then 64/256 to Darts
             (:2015-2016) -- it can chain for a long time.

    ATTACK   RS_WhiteCguy2.Summon1
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:2021
    shape    UNCLASSIFIED
    payload  RS_VolativeCaco x1  (via A_PainAttack -- launched like a Lost Soul)
    arc      --   (A_PainAttack default addangle 0)
    timing   one tic (3 aim + 2 sound before, 4 recovery after)
    damage   none directly -- the minion is the damage. See its rows in Section 3.
    type     --
    sound    "Science/Atk"
    impact   --   (the caco is a live monster from the moment it lands)
    trigger  Missile   (via A_Jump(256))
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_VolativeCaco", count:1, cap:4, fireSnd:"Science/Atk")
    notes    shape UNCLASSIFIED, per the spec's instruction not to coin a
             word: the closed set has no summon shape, and A_PainAttack is
             not any of MELEE/HITSCAN/CHARGE/VILE/COMBO. RS_ATK_SUMMON exists
             on the profile class, so the MODE is expressible even though the
             SHAPE word is not. Flagged in UNRESOLVED U4.
             A_PainAttack LAUNCHES the spawn forward like a Lost Soul rather
             than placing it -- the caco arrives already moving at you. That
             is why this is a summon that reads as an attack.
             RS_VolativeCaco is +TOUCHY and its Melee state is `Goto Death`:
             it is a walking bomb, not a fighter. Section 3.

    ATTACK   RS_WhiteCguy2.Summon2
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:2027
    shape    UNCLASSIFIED
    payload  RS_SlimyWorm x3
    arc      --   (placed at random(-64,64) x/y, z random(5,15), SXF_SETMASTER)
    timing   3,3,3 -- 9 tics
    damage   none directly
    type     --
    sound    "Science/Atk"
    impact   --
    trigger  Missile   (via A_Jump(256))
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_SlimyWorm", count:3, cap:6, fireSnd:"Science/Atk")
    notes    `FSZS FFF 3` = THREE frames = three worms, not one.
             SXF_SETMASTER makes them the scientist's, so +DONTHARMSPECIES /
             Species "Science" keeps the pack from infighting.
             Placed, not launched (A_SpawnItemEx, unlike Summon1's
             A_PainAttack). RS_SlimyWorm spawns with +NOCLIP and clears it on
             its first See loop -- so it can be summoned inside geometry and
             will walk out.

    ATTACK   RS_WhiteCguy2.Summon3
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:2034
    shape    UNCLASSIFIED
    payload  RS_SpliceBaron x1
    arc      --   (random(-64,64) x/y, z random(5,15), SXF_SETMASTER)
    timing   one tic (12+12+12 wind-up, 12+8 recovery -- 56 tics total)
    damage   none directly
    type     --
    sound    "Science/Atk"
    impact   --
    trigger  Missile   (phase 2 only, via Phase2 -> Nah -> A_Jump(256))
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_SpliceBaron", count:1, cap:3, fireSnd:"Science/Atk")
    notes    A 1000-HP arachnotron/baron hybrid, and the slowest cast in the
             family -- 36 tics of wind-up. Phase 2 only.

    ATTACK   RS_WhiteCguy2.Phase2
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:2039
    shape    UNCLASSIFIED
    payload  RS_SpliceBaron x2 on one tic, PLUS a permanent self-buff
    arc      --   (random(-64,64) x/y, SXF_SETMASTER)
    timing   one tic for the barons; 20+8+7+8+12 = 55 tics of transformation before
    damage   none directly
    type     --
    sound    "Science/Enuff"
    impact   --
    trigger  Missile   (A_JumpIfHealthLower(5555) -- fires ONCE, guarded by User_Ph2)
    range    --
    mirrored no
    inherit  --
    profile  MakeSelfBuff(speedMult:19.0/14.0, duration:0, noPain:true, fireSnd:"Science/Enuff") + MakeSummon(summonCls:"RS_SpliceBaron", count:2, cap:3)
    notes    A PHASE GATE, NOT A REPEATABLE ATTACK. `User_Ph2` guards it, so
             the transformation runs exactly once; every later trip to
             Phase2 falls through to `Nah`. What it permanently changes:
             `bNOPAIN = true` (never cleared), `A_SetSpeed(19)` (up from 14),
             and the attack table swaps from 4 options to 5 harder ones.
             The buff is PERMANENT -- BuffDuration 0 is the honest encoding
             and it is also the profile layer's "no duration" default, so the
             two are indistinguishable there.
             `FSZS FF 0` = 2 frames = two barons on one tic.

## RS_CyanCGuy2 — tier 12, "Jetpack Larry"

    ATTACK   RS_CyanCGuy2.Missile
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:416
    shape    SCATTER
    payload  RS_IceZombieShot2 x22
    arc      CONVERGING -- horizontal +/-11 -> 10 -> 9 -> 8 -> 7 -> 6 -> 5 -> 4 -> 3 -> 2 -> 1; vertical +/-5 -> 4 -> 4 -> 3 -> 3 -> 2 -> 2 -> 1 -> 1 -> 0 -> 0
    timing   3 tics between every shot -- 66 tics, uniform, after an 11-tic aim
    damage   DamageFunction (random(4,14)) -- OVERRIDDEN on the child; the parent rolls random(6,16)
    type     Ice   (INHERITED)
    sound    --   from the attack. This monster HAS `AttackSound "chainguy/attack"` but A_CustomMissile never plays AttackSound, so it is never heard. Each shot plays SeeSound "Ice/Hit2" (INHERITED).
    impact   ICEY F/G/H/I ice shatter (INHERITED). DeathSound "spike/spiked" is UNDEFINED in our SNDINFO and undefined in CH's own -- silent in both. No A_Explode: contact damage only.
    trigger  Missile
    range    --   (no gate)
    mirrored no
    inherit  RS_IceZombieShot (zscript/monsters/zombieman/RS_Zombieman.zs:397 for the child, :364 for the parent). RS_IceZombieShot2 overrides Radius, XScale, YScale, Speed and DamageFunction ONLY. Its DamageType, both sounds, RenderStyle, Alpha and the entire Spawn/Death chain are the parent's.
    profile  MakeBurst(proj:"RS_IceZombieShot2", count:22, delayTics:3, arc:22, pitchJitter:5)
    notes    **THE CONVERGING CONE IS THE ATTACK AND NO FIELD CAN HOLD IT.**
             Twenty-two ice shards fired at a steadily TIGHTENING spread --
             it opens as a wall of chaff and ends as a needle on your face.
             VolleyArc is one constant, so the profile fires 22 shots at a
             fixed 22-degree cone: the same count, the opposite feeling.
             This is the strongest single argument in the family for a
             per-shot spread ramp.
             ELEVEN source lines, each `CPS2 FE 3` = 2 frames = TWENTY-TWO
             shots. Reading one per line reports 11 and halves the attack.
             A_CheckSight("See") sits between every line, so breaking line of
             sight aborts mid-cone -- the tighter, deadlier half never fires
             if you break contact early.
             Falls THROUGH into Missile2 (no Goto) if the cone completes.

    ATTACK   RS_CyanCGuy2.Missile2
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:443
    shape    BURST
    payload  RS_IceZombieShot2 x2 per cycle
    arc      0 -- dead centre, no spread argument at all
    timing   3,3 then 1-tic refire and 1-tic re-aim -- 8-tic sustained cycle
    damage   DamageFunction (random(4,14))
    type     Ice   (INHERITED)
    sound    --   (SeeSound "Ice/Hit2" per shot, INHERITED)
    impact   ICEY F-I shatter, DeathSound "spike/spiked" (silent -- undefined in CH too)
    trigger  Missile   (fallen through from Missile, and self-looping via A_MonsterRefire(64))
    range    --
    mirrored no
    inherit  RS_IceZombieShot -- as Missile above
    profile  MakeBurst(proj:"RS_IceZombieShot2", count:2, delayTics:3, arc:0)
    notes    THE PAYOFF OF THE CONVERGENCE. Once the 22-shot cone completes,
             the monster locks into a perfectly accurate 2-shot loop at 8-tic
             intervals for as long as A_MonsterRefire(64) holds. The two
             states are one attack in two movements and should be built as a
             two-entry rotation, not two independent profiles.
             `CPS2 FE 3` = 2 frames = 2 shots per cycle.

## RS_BrownCGuy2 — tier 13, "Brown Noise Maker"

    ATTACK   RS_BrownCGuy2.Missile[+3]   (sandbag cover deploy)
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:252
    shape    SCATTER
    payload  RS_BrownSandBagCGuy x3
    arc      +/-9 horizontal, thrown forward at 32 units with velocity random(3,9) forward / random(3,9) up, y offset random(-32,32)
    timing   10,10,10 -- 30 tics
    damage   none -- the sandbag is COVER, not a weapon. Health 80, +THRUSPECIES, -COUNTKILL, no damage of any kind.
    type     --
    sound    --   (no SeeSound on RS_BrownSandBagCGuy)
    impact   lands, grows over 12 tics via A_SetScale 0.3 -> 1.0, wanders 2 tics, clears +THRUACTORS (so it becomes SOLID), stands 300 tics, then shrinks away
    trigger  Missile
    range    --   (fires before any band gate)
    mirrored no
    inherit  --   (RS_BrownSandBagCGuy is a flat Actor, RS_ChaingunnerFX.zs:254)
    profile  MakeSummon(summonCls:"RS_BrownSandBagCGuy", count:3, cap:6, tierOffset:0, profName:"Deploy cover")
    notes    A DEPLOYABLE-COVER ATTACK, WHICH IS UNIQUE IN THIS FAMILY AND
             RARE ANYWHERE. It spawns three 42-radius blockers between itself
             and you, then shoots from behind them. As a player weapon part
             this is a barricade launcher and it has no analogue in the
             current arsenal.
             `CZV1 UUU 10` = THREE frames = three sandbags, 10 tics apart.
             It clears +THRUACTORS only after landing, so the bags pass
             through actors on the way out and become solid where they stop.
             `Goto Missile+6` from the shooting half re-enters AFTER this, so
             cover is deployed once per engagement, not per burst.

    ATTACK   RS_BrownCGuy2.More
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:263
    shape    SCATTER
    payload  RS_BrownSandBagCGuy x6, in two ranks
    arc      +/-18 horizontal, rank 1 at 32 units / rank 2 at 64 units, y offset random(-64,64), velocity random(3,14) and random(5,14) forward, random(4,14) up
    timing   10,10,10 | 10,10,10 -- 60 tics
    damage   none
    type     --
    sound    --
    impact   as Missile[+3] -- two staggered walls instead of one
    trigger  Missile   (via A_CheckProximity("More","Chaingunguy",128,1,CPXF_ANCESTOR|CPXF_CHECKSIGHT))
    range    --   (gated on ALLIES, not on the player: fires when >=1 ChaingunGuy-descended actor is within 128 units with line of sight)
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_BrownSandBagCGuy", count:6, cap:12, tierOffset:0, profName:"Deploy cover (squad)")
    notes    **THE GATE IS AN ALLY CHECK, NOT A RANGE CHECK, AND THAT IS THE
             ONLY ONE OF ITS KIND IN THIS FAMILY.** A_CheckProximity with
             CPXF_ANCESTOR counts anything descended from ChaingunGuy within
             128 units. When the Brown Chaingunner has friends nearby, it
             builds a bigger, deeper, wider emplacement for the squad. There
             is no profile field for a condition of this kind at all.
             Six bags, two ranks, double the spread of the solo version.
             `Goto Missile+6` -- it then shoots from behind them like the
             solo path.

    ATTACK   RS_BrownCGuy2.Missile[+9]   (the sustained burst)
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:256
    shape    HITSCAN
    payload  hitscan trace x3, 1 bullet each
    arc      WIDENING: +/-2, then +/-4, then +/-6 (both axes)
    timing   5,5,5 then 1 CheckSight + 1 refire -- 17-tic sustained cycle
    damage   random(2,9) per bullet --> EFFECTIVE random(2,9)*random(1,3) = 2..27
    type     Hitscan
    sound    "chainguy/attack"  (AttackSound; A_CustomBulletAttack plays it)
    impact   BulletPuff (vanilla) -- the ONLY custom-chaingunner band in the family that uses the stock puff
    trigger  Missile
    range    1400..   (A_JumpIfCloser(1400,"M1") diverts everything closer)
    mirrored no
    inherit  --
    profile  MakeHitscan(fireSnd:"chainguy/attack", profName:"Brown suppression"); p.SpreadScale=0; p.SpreadBonus=4; p.PelletOverride=3; p.MinRange=1400
    notes    A WIDENING RAMP, THE MIRROR IMAGE OF THE GRAY SNIPER'S
             TIGHTENING ONE. Spread grows 2 -> 4 -> 6 across the three
             rounds while the tic rate stays flat at 5. It is suppressing
             fire from behind sandbags, not marksmanship, and the numbers say
             so. SpreadBonus is one constant, so 4 (the mean) is written and
             the 2->6 walk is lost.
             `Goto Missile+6` skips the sandbag deploy and re-tests the 1400
             gate every cycle.

    ATTACK   RS_BrownCGuy2.M1
    file     zscript/monsters/chaingunner/RS_Chaingunner.zs:270
    shape    BURST
    payload  RS_BrownOrbCguy x4
    arc      +/-5 horizontal, pitch random(-1,5) (mostly DOWNWARD), spawnofs_xy -6 (fired from the left)
    timing   3,3,3,3 -- 19-tic cycle including 5-tic re-aim and 2 tics of checks
    damage   DamageFunction (random(3,9)) contact, PLUS A_Explode(random(1,5), radius 32) x5 FRAMES on death
    type     Fire
    sound    "fire/fire3" per orb (SeeSound); "weapons/boom1" on impact
    impact   RIP1 D-H at scale 1.0, FIVE frames each running A_Explode(random(1,5), radius 32), with A_SetTranslation("BBEASTEX5") applied first
    trigger  Missile   (via A_JumpIfCloser(1400,"M1"))
    range    ..1400
    mirrored no
    inherit  --   (RS_BrownOrbCguy is a flat Actor, RS_ChaingunnerFX.zs:298)
    profile  MakeBurst(proj:"RS_BrownOrbCguy", count:4, delayTics:3, arc:10, pitchJitter:3); p.MaxRange=1400
    notes    A LOBBED GRENADE, NOT A BOLT. `Gravity 0.05` with `-NOGRAVITY`
             means it arcs -- slowly, but it does drop, and the downward
             pitch bias random(-1,5) points it at the floor near you rather
             than at you. It is meant to land and detonate, and at Speed 32
             with five 32-radius blasts it is a mortar.
             Two source lines, each `CZV1 FE 3` = 2 frames, so FOUR orbs.
             `A_SetTranslation("BBEASTEX5")` on the Death state resolves --
             TRNSLATE.txt:268 defines it as `"0:0=0:0"`, a deliberate no-op
             carried over from CH. It is not a missing translation.

---
---

# SECTION 2 — PAYLOAD-FIRED SECONDARIES (11 rows)

The spec's rule: *"IMPACT CAN BE AN ATTACK ... record it in `impact` AND give
the secondary its own row if it is substantial."* These eleven are
substantial. Every one is invisible to anyone reading only the monster file.

    ATTACK   RS_CGthing3.Death   (reached from RS_GrayCGuy2's every hitscan band)
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:407
    shape    RING
    payload  RS_CGNail x12
    arc      360 -- explicit angles 15,45,75,105,135,165,195,225,255,285,315,345 (30-degree step, offset 15)
    timing   one tic (all twelve on 0-tic frames)
    damage   DamageFunction (random(1,5)) DamageType "Melee" per nail, PLUS nine A_Explode blasts each on impact (see next row)
    type     Melee
    sound    "moloch/nailhitbleed" (AttackSound, +SPAWNSOUNDSOURCE) per nail
    impact   see RS_CGNail.Death below
    trigger  Missile   (chain: RS_GrayCGuy2 hitscan -> RS_GrayCGuff puff hits an actor -> its Melee state spawns RS_CGthing3 -> RS_CGthing3's Spawn falls straight into Death)
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_CGNail", count:12, arc:360, fireSnd:"moloch/nailhitbleed")
    notes    **A TWELVE-NAIL 360-DEGREE RING ON EVERY GRAY CHAINGUNNER BULLET
             THAT HITS YOU.** RS_GrayCGuff (:362) is the puff on all four of
             the Gray's hitscan bands; its `Melee:` state (the puff state the
             engine enters when a puff lands on a bleeding actor) runs
             `A_Explode(random(1,12),64)` and spawns RS_CGthing3, which is a
             one-tic ring launcher and nothing else.
             So the Gray's "sniper rifle" is a nail-bomb launcher. Reading
             the monster file alone reports a plain hitscan.
             THE ANGLES ARE EXPLICIT, NOT random(0,359) -- this is a
             deterministic 30-degree ring, so RING is the right word but the
             `random(0,359) is the tell` heuristic in the spec would have
             missed it.
             RS_CGthing3 has Speed 0 and +NOCLIP: it never moves, it exists
             for zero tics.

    ATTACK   RS_CGNail.Death
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:448
    shape    UNCLASSIFIED
    payload  --   (no projectile; nine chained radius blasts in place)
    arc      --
    timing   1,1,1,1,1,1 then 1,1,1 -- 9 tics
    damage   A_Explode(random(1,3), radius 16) x6 frames, then A_Explode(random(1,3), radius 16) x3 frames -- NINE blasts, 9..27 total
    type     Melee   (the nail's DamageType; A_Explode uses the caller's)
    sound    "moloch/nailhit" (A_PlaySound on the first frame) + DeathSound "weapons/firex4"
    impact   6PUF A-F then FBL1 E/F/G, then one RS_PuffCybieRed smoke wisp
    trigger  Missile   (impact of the ring above)
    range    --
    mirrored no
    inherit  --
    profile  MakeRadial(radius:16, damage:18, fireSnd:"moloch/nailhit")
    notes    shape UNCLASSIFIED per the spec: a chained in-place radius burst
             with no projectile and no travel is none of the thirteen words.
             MakeRadial holds the MODE.
             Twelve nails x nine blasts = 108 explosions per Gray Chaingunner
             bullet that connects. Small individually (16 radius, 1..3 each)
             but it is why the Gray hurts so much more than its written
             damage suggests.
             +EXTREMEDEATH and +BLOODSPLATTER: the nails gib.

    ATTACK   RS_Puddle1.Death   (how the scientist's puddle attack actually lands)
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:1064
    shape    SCATTER
    payload  RS_Puddle2 x3
    arc      +/-20 horizontal, spawnheight random(2,16), spawnofs_xy random(-16,16), pitch random(5,15), CMF_SAVEPITCH
    timing   4,4,4 -- 12 tics
    damage   the pools themselves: Damage 4 --> 4 * random(1,8) = 4..32 + PoisonDamage 15
    type     Poison
    sound    "slimeball/splat" (the seed's DeathSound)
    impact   see RS_Puddle2.Spawn below
    trigger  Missile   (chain: RS_WhiteCguy2.Puddle/Puddle2 -> RS_Puddle1 lands -> this)
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_Puddle2", count:3, delayTics:4, arc:40, pitchJitter:10)
    notes    `BOGY DEF 4` is THREE frames = three pools per seed. The Puddle
             attack drops 2 seeds -> 6 pools; Puddle2 drops 4 seeds -> 12
             pools. That is the real output and neither number appears
             anywhere in the monster file.
             `A_NoGravity` is called on the first Death frame so the pools
             spread level rather than falling.

    ATTACK   RS_Puddle2.Spawn   (the wandering pool's sustained spray)
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:1030
    shape    SCATTER
    payload  RS_SlimeBall4, 3 per 6-tic loop, indefinitely
    arc      +/-180 -- fires in ANY direction, random(-180,180)
    timing   2,2,2 per loop; loops until a 16/256 roll ends it (A_Jump(16,"Death") each pass)
    damage   Damage 4 --> 4 * random(1,8) = 4..32 + PoisonDamage 15 per glob; the pool ITSELF is Damage 4 + PoisonDamage 15 on contact
    type     Poison
    sound    "slimeball/splat" per glob on landing
    impact   BOGY D/E/F splat; the globs do not spawn further pools
    trigger  Missile   (chain, two levels deep from the monster)
    range    --
    mirrored no
    inherit  --   (RS_Puddle2 is a flat Actor, RS_ChaingunnerFX.zs:1001. NOT related to the monster state also called Puddle2.)
    profile  MakeBurst(proj:"RS_SlimeBall4", count:3, delayTics:2, arc:360, pitchJitter:35)
    notes    **AREA DENIAL THAT MOVES AND SHOOTS.** The pool is
             +FLOORHUGGER, +BOUNCEONWALLS with BounceCount 999 and
             WallBounceFactor 1.5, and it calls A_Wander -- it crawls around
             the room bouncing off walls, spraying poison globs in random
             directions, until a 1-in-16 roll per loop kills it (mean
             lifetime ~96 tics).
             Twelve of these at once, in phase 2, is the scientist's
             signature and it is entirely invisible from the monster file.
             `BOGY ABC 2` = 3 frames = 3 globs per loop.
             It is +DONTHARMCLASS and +DONTHARMSPECIES with Species "Science",
             so the whole pack wades through its own poison unharmed.

    ATTACK   RS_GenShield.Death
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:962
    shape    SCATTER
    payload  RS_TrailSPCguy x3
    arc      +/-2 horizontal, +/-4 pitch, spawnheight random(-2,2), CMF_AIMDIRECTION|CMF_SAVEPITCH
    timing   8,8,8 -- 24 tics
    damage   zero contact; A_Explode(10, radius 32) x5 frames per trail = 50 fixed
    type     Plasma
    sound    --
    impact   APBX A-E, five frames of A_Explode(10,32) each; each trail also sheds RS_TrailSP2 (another 5 x A_Explode(7,32))
    trigger  Missile   (chain: RS_BlackCGuy2.Shield -> orb expires ~45 tics later -> this)
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_TrailSPCguy", count:3, delayTics:8, arc:4, pitchJitter:4, trigger:RS_FIRE_MISSILE)
    notes    THE SHIELD IS A DELAYED BOMB. It looks defensive for 45 tics and
             then fires three plasma trails on the way out. A player who
             closes in while the General is invulnerable eats it.
             `BFE1 DEF 8` = 3 frames = three trails.

    ATTACK   RS_CGBigOne.Spawn   (the in-flight ground hazard)
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:925
    shape    SINGLE
    payload  RS_GroundRedCyb x1 per 3-tic loop, continuously, plus 2 RS_SpiralSaw5
    arc      --   (angle 0, straight down the flight path)
    timing   one per Spawn loop; the loop is 1+1+1+0 = 3 tics, so ~1 hazard every 3 tics of flight
    damage   RS_GroundRedCyb: A_Explode(random(2,10), radius 128) x6 FRAMES = 12..60 per hazard. RS_SpiralSaw5: A_Explode(random(2,10), radius 88) x5 FRAMES = 10..50 each.
    type     Fire (GroundRedCyb) / Plasma (SpiralSaw5)
    sound    "Fire/fire3" per ground hazard (SeeSound)
    impact   RED8 A/B/C/F/G/H then D -- and it BOUNCES: +FLOORHUGGER, +BOUNCEONWALLS, BounceCount 999, WallBounceFactor 1.5
    trigger  Missile   (chain: RS_BlackCGuy2.BigOne -> the shot's flight)
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_GroundRedCyb", count:8, delayTics:3, arc:0)  -- count is a guess: it is unbounded until the shot lands
    notes    **A TRAIL OF BOUNCING FLOOR FIRE THE WHOLE LENGTH OF THE
             FLIGHT.** Each hazard is a 128-radius blast repeated across six
             frames, and it survives to bounce off walls afterward. The
             corridor the BigOne travels down stays lethal after it passes.
             `RED9 AA 1 A_SpawnItemEx("RS_SpiralSaw5",...)` = 2 frames = two
             saws per loop as well.
             COUNT IS HONESTLY UNKNOWN -- it is one per 3 tics until impact,
             so it depends on flight distance. 8 is a placeholder for a
             mid-range shot, not a measurement.

    ATTACK   RS_CGBigEx.Spawn   (the EX shot's in-flight shedding)
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:777
    shape    SCATTER
    payload  RS_EXPLOSIONSCGuyEX x1 per 3-tic loop + RS_SpiralSaw5 x2 per loop
    arc      spawned at random(-128,24) x, random(-64,64) y, random(-32,32) z, angle random(0,359)
    timing   ~1 per 3 tics of flight, unbounded
    damage   RS_EXPLOSIONSCGuyEX: DamageFunction (random(20,60)) + A_Explode(random(11,77), radius 128). RS_SpiralSaw5: A_Explode(random(2,10),88) x5 frames.
    type     Fire (EXPLOSIONS) / Plasma (SpiralSaw5)
    sound    "weapons/bfgf" per sub-explosion (SeeSound), "weapons/bfgx" on its death
    impact   GRFZ I-P cascade, A_Explode(random(11,77), radius 128) on the K frame, plus 20 red particles
    trigger  Missile   (chain: RS_BlackCGuyEX.BigBomb -> the shot's flight)
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_EXPLOSIONSCGuyEX", count:8, delayTics:3, arc:360)  -- count unbounded, see notes
    notes    Same shape as RS_CGBigOne.Spawn but the shed payload is a
             128-radius, random(11,77)-damage explosion rather than floor
             fire. It also HOMES on the way (A_SeekerMissile(2,4),
             +SEEKERMISSILE intact) at only Speed 21, so it spends a long
             time shedding.
             COUNT UNBOUNDED, as above.

    ATTACK   RS_YellowBombCGUYEX.Death
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:694
    shape    UNCLASSIFIED
    payload  --   (eight escalating in-place blasts, no projectile)
    arc      --
    timing   2,2,2,2,2,2,2,2 across the BBOM A/B/C frames -- ~16 tics, after a 66-tic fade-in
    damage   A_Explode, in order: random(10,20)/r32, random(10,30)/r64, random(20,60)/r74, random(20,80)/r128, random(30,90)/r176, random(30,90)/r256, random(30,90)/r256, random(30,90)/r312
    type     Fire
    sound    "spell/Impact1" at the start of the cascade, "Bomb/boom" at the 176-radius stage, DeathSound "spit/spit2"
    impact   BBOM A/B/C scaling 0.5 -> 4.0, then fading over 20 tics
    trigger  Missile   (chain: RS_BlackCGuyEX.YE)
    range    --
    mirrored no
    inherit  --
    profile  MakeRadial(radius:312, damage:60, fireSnd:"Bomb/boom")  -- collapses eight stages to one; see notes
    notes    **AN EXPANDING SHOCKWAVE BUILT AS EIGHT SEPARATE A_Explode
             CALLS, EACH BIGGER THAN THE LAST.** 32 -> 64 -> 74 -> 128 -> 176
             -> 256 -> 256 -> 312 radius over 16 tics. Standing at the edge
             and running is survivable; standing at the centre is not. That
             gradient is the whole design and MakeRadial has one radius and
             one damage.
             There is also a 66-tic staged fade (GBLL frames, A_SetScale
             1.0 -> 0.25 and back) BEFORE the first blast. The bomb sits
             there visibly swelling. That telegraph is not recorded anywhere
             in the profile layer either.
             The `MISL E` frames that once made four tics of this invisible
             were resolved to `MISL D` on 2026-08-06 -- see the file header.

    ATTACK   RS_SpamShotsCguyEX.Death
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:741
    shape    MULTI
    payload  RS_EXPLOSIONSCGuyEX x7 + RS_EXPLOSIONSCGuyEXDelayd x2, plus a direct blast
    arc      EX spawned in a 128-unit box (random(-64,64) x/y, random(-32,32) z) then a 256-unit box; Delayd at random(-32,32) x/y, random(-64,128) z with velocity random(12,99)
    timing   direct blast at 4; the 7 EX over 9 tics; the 2 Delayd at 4,4 (and Delayd waits 11 more tics before detonating)
    damage   direct A_Explode(random(22,88), radius 256). Each EX: random(20,60) contact + A_Explode(random(11,77),128). Each Delayd: same rolls, 11 tics late.
    type     Plasma (the shot) / Fire (both sub-explosions)
    sound    "weapons/bfgx" (DeathSound) + "weapons/bfgf" per sub-explosion
    impact   GRFZ I-P with 20 red particles per stage
    trigger  Missile   (chain: RS_BlackCGuyEX.RedSpam, 12 of these per volley)
    range    --
    mirrored no
    inherit  RS_SpamShotsCguyEX2 shares this ENTIRE death cascade -- it overrides only DamageType. Twelve shots per RedSpam volley, so 84 EX + 24 Delayd sub-explosions if all connect.
    profile  MakeRadial(radius:256, damage:55) + MakeBurst(proj:"RS_EXPLOSIONSCGuyEX", count:7, delayTics:1, arc:360)
    notes    THE DELAYED HALF IS THE INTERESTING PART.
             RS_EXPLOSIONSCGuyEXDelayd (:835) has `Spawn: TNT1 A 11;` -- it
             flies invisibly for 11 tics at Speed 50 and THEN detonates, so
             the blast lands where you moved to, not where you were. A
             second wave 11 tics behind the first, aimed at your dodge.
             `GRFZ LMN 3` = 3 frames = 3 EX; `TNT1 AAAA 0` = 4 more;
             `GRFZ OP 4` = 2 Delayd. Seven and two.

    ATTACK   RS_CGBigEx.Death
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:783
    shape    UNCLASSIFIED
    payload  ~200 RS_EXPLOSIONSCGuyEXDelayd + 5 RS_EXPLOSIONSCGuyEX, plus 11 direct blasts
    arc      Delayd in tight random(-12,12) x/y boxes with z random(-64,128) and velocity random(12,99), angles split across random(0,180) / random(180,359) / random(0,359) bands
    timing   the SPIR cascade over 45 tics, then GRFZ stages over ~20 more
    damage   A_Explode(random(5,30), radius 164) x9 FRAMES, then A_Explode(random(55,111), radius 386), then A_Explode(random(66,128), radius 386). Each of ~200 Delayd adds random(20,60) + A_Explode(random(11,77),128) eleven tics later.
    type     Plasma (the shot) / Fire (sub-explosions)
    sound    "Fire/Fire4" (DeathSound) + "weapons/bfgf"/"weapons/bfgx" from every sub-explosion
    impact   SPIR A-E-A at scale 1.5 then 3.0, then the GRFZ I-P cascade
    trigger  Missile   (chain: RS_BlackCGuyEX.BigBomb)
    range    --
    mirrored no
    inherit  --
    profile  MakeRadial(radius:386, damage:90, fireSnd:"Fire/Fire4")  -- collapses everything; honestly unrepresentable
    notes    **THE SINGLE LARGEST DAMAGE EVENT IN THIS FAMILY, BY AN ORDER OF
             MAGNITUDE.** `SPIR ABCDEDCBA 5 A_Explode(random(5,30),164)` is
             NINE frames = nine 164-radius blasts, 45..270 damage on its own.
             Then two 386-radius blasts at random(55,111) and random(66,128).
             Then roughly two hundred RS_EXPLOSIONSCGuyEXDelayd spawned
             across eight `TNT1 AAAA...` lines of 25-37 frames each, every
             one of which flies for 11 tics and detonates for
             random(20,60) + A_Explode(random(11,77),128).
             Counted exactly: 34+34+34+33+33+37+25+25 = 255 Delayd spawns.
             This is not a projectile impact, it is a scripted set piece.
             No profile field or combination comes close.

    ATTACK   RS_CGBigOne.Death
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:929
    shape    UNCLASSIFIED
    payload  --   (nine chained in-place blasts)
    arc      --
    timing   5,5,5,5,5,5,5,5,5 -- 45 tics
    damage   A_Explode(random(5,30), radius 164) x9 FRAMES = 45..270
    type     Plasma
    sound    "Fire/Fire4" (DeathSound)
    impact   SPIR A-B-C-D-E-D-C-B-A at scale 2.0, then one final SPIR E frame
    trigger  Missile   (chain: RS_BlackCGuy2.BigOne)
    range    --
    mirrored no
    inherit  --
    profile  MakeRadial(radius:164, damage:135, fireSnd:"Fire/Fire4")
    notes    The General's version of the EX's set piece, without the 386
             stages and the 255 delayed sub-blasts. Still nine 164-radius
             explosions over 45 tics -- a sustained field you must leave, not
             a bang you survive.
             `SPIR ABCDEDCBA 5` is the multi-frame A_Explode idiom at its
             clearest: nine letters, nine explosions. This is one of the ~55
             deliberate sites; collapsing it to one call removes 89% of the
             damage.

---
---

# SECTION 3 — THE SCIENTIST'S MINIONS (4 monsters, 7 rows)

These four live in `RS_ChaingunnerFX.zs`, carry no tier token, and exist only
as `RS_WhiteCguy2` summons. They are outside the "14 monsters" scope this
pass was given, but they are chaingunner-family content with real attacks and
omitting them would be a gap. **Flagged in UNRESOLVED §U5 — strip this
section if the family boundary is meant to exclude them.**

    ATTACK   RS_SlimyWorm.Missile
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:1249
    shape    MULTI
    payload  RS_SlimeBall1 + RS_SlimeBall2 + RS_SlimeBall3 + RS_SlimeBall4 + RS_SlimeBall5, one each, all on one tic
    arc      +/-10 horizontal each, pitch random(10,20), CMF_AIMDIRECTION
    timing   one tic (8 aim + 8 sound wind-up before, 8 recovery after)
    damage   Damage 4 --> ENGINE ROLL 4 * random(1,8) = 4..32 EACH, + PoisonDamage 15 each
    type     Poison
    sound    "SlimeBall/Shoot" (A_PlaySound, 8 tics before the volley)
    impact   BOGY D/E/F splat, DeathSound "slimeball/splat". No A_Explode.
    trigger  Missile
    range    --   (+SHORTMISSILERANGE -- deprecated flag, sets MaxTargetRange 896 natively; see CLAUDE.md, it cannot be replaced declaratively)
    mirrored no
    inherit  RS_SlimeBall2..5 : RS_SlimeBall1 : DoomImpBall (RS_ChaingunnerFX.zs:1139, :1166-1169). The four subclasses override ONE property each -- Speed 16/18/20/22 against the parent's 14. Damage, PoisonDamage, DeathSound, Decal, -NOGRAVITY and the whole state chain are the parent's, and the parent in turn is a DoomImpBall.
    profile  MakeVolley(proj:"RS_SlimeBall1", count:5, arc:20, fireSnd:"SlimeBall/Shoot", pitchJitter:15)  -- collapses the speed ladder; see notes
    notes    **FIVE CLASSES THAT DIFFER ONLY IN SPEED (14/16/18/20/22) FIRED
             ON THE SAME TIC IS A STRING-OUT, NOT A SHOTGUN.** They leave
             together and arrive in sequence, so a single dodge does not
             clear all five. That is the entire mechanic and it is expressed
             purely through five near-identical classes.
             MakeVolley with one class fires five identical globs that arrive
             together -- the same count, a completely different threat.
             The honest form is a 5-entry rotation, one per class, with
             delayTics 0.
             `WORM F 0` x5 on zero tics: all five on the same tic.

    ATTACK   RS_SlimyWorm.Melee
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:1258
    shape    MELEE
    payload  --
    arc      --
    timing   one tic (8+8 wind-up, 8-tic swing)
    damage   A_SargAttack -- engine native: random(1,10) * 4 = 4..40
    type     (default melee)
    sound    "slimeworm/melee" (AttackSound; A_SargAttack plays it)
    impact   --   (no puff; direct hit)
    trigger  Melee
    range    --   (A_SargAttack uses the standard melee range check)
    mirrored no
    inherit  --
    profile  MakeMelee(range:64, fireSnd:"slimeworm/melee")
    notes    Vanilla Demon bite, on a worm. 16 tics of wind-up before the
             swing makes it readable.

    ATTACK   RS_VolativeCaco.Melee
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:1324
    shape    CHARGE
    payload  --   (the monster IS the payload)
    arc      --
    timing   4,4 then straight into Death
    damage   none from the melee itself -- `HEAD BC 4; Goto Death;`
    type     --
    sound    --   (the Death chain's "weapons/rocklx" follows immediately)
    impact   see RS_VolativeCaco.Death below
    trigger  Melee
    range    --
    mirrored no
    inherit  --
    profile  -- no factory fits: a suicide-on-contact charge has no mode. Nearest: MakeRadial(radius:128, damage:40) fired at RS_FIRE_MELEE.
    notes    **THE MELEE STATE IS `Goto Death`. IT IS A WALKING BOMB.**
             +TOUCHY as well, so it also dies (and detonates) on any solid
             contact. CHARGE is the right shape word by the spec's own
             definition -- "the monster IS the projectile" -- even though it
             is not A_SkullAttack.
             Its See state pulses A_SetScale 1.3 -> 1.5 -> 1.3 -> 1.2 as it
             approaches, which is the visual tell that it is about to blow.

    ATTACK   RS_VolativeCaco.Death
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:1334
    shape    MULTI
    payload  A_Explode x2 frames + RS_BabyCaco x5 (2 + 1 + 2 via A_DualPainAttack / A_PainAttack / A_DualPainAttack)
    arc      A_PainAttack/A_DualPainAttack default -- Dual fires at angle +/-90 from facing, single fires straight ahead
    timing   8, 1, 6, 6, 1, 2, 1 -- ~25 tics
    damage   A_Explode(random(20,60), radius 128) on TWO frames (`MISL CD 6`) = 40..120
    type     (untyped explosion) -- the caco has no DamageType set
    sound    "weapons/rocklx" (DeathSound)
    impact   the five RS_BabyCaco are LIVE MONSTERS, 125 HP each -- see the next row
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  MakeRadial(radius:128, damage:40, fireSnd:"weapons/rocklx") + MakeSummon(summonCls:"RS_BabyCaco", count:5, cap:10)
    notes    `MISL CD 6 A_Explode(random(20,60),128)` is TWO frames = two
             128-radius blasts, not one.
             THEN it splits into five baby cacodemons. A_DualPainAttack
             spawns two at once (±90 degrees), A_PainAttack spawns one
             forward: 2 + 1 + 2 = five. Killing it does not end it.
             The three `MISL E` frames here were resolved to `MISL D` on
             2026-08-06 -- the whole 4-tic split burst previously rendered
             nothing. See the file header.

    ATTACK   RS_BabyCaco.Missile / RS_BabyCaco.Melee
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:1453
    shape    COMBO
    payload  RS_BabyCacoBall x1 (ranged) OR a direct melee hit (close)
    arc      --
    timing   one tic (5+5 aim, 5-tic attack frame)
    damage   melee random(1,8) * 3 = 3..24. Ranged: RS_BabyCacoBall `Damage 3` --> ENGINE ROLL 3 * random(1,8) = 3..24.
    type     (default) / (ball untyped)
    sound    "BabyCaco/Melee" on the melee branch only; the ball plays SeeSound "caco/attack"
    impact   BCAB C/D/E, DeathSound "caco/shotx", Decal "HImpScorch". No A_Explode.
    trigger  Missile   (the `Melee:` and `Missile:` labels are stacked on the same state -- one entry point, the engine picks)
    range    --   (A_CustomComboAttack does the range decision internally, spawnheight 17)
    mirrored no
    inherit  Cacodemon (vanilla) -- for Pain/Death/Raise timing and the base behaviour. The attack itself is fully overridden.
    profile  MakeVolley(proj:"RS_BabyCacoBall", count:1, fireSnd:"caco/attack") + MakeMelee(range:64, fireSnd:"BabyCaco/Melee") as a range-banded pair
    notes    THE ONE COMBO IN THE FAMILY. `A_CustomComboAttack("RS_BabyCacoBall",
             17, random(1,8)*3, "BabyCaco/Melee")` -- melee if in range, ball
             if not, one call. `Melee:` and `Missile:` share the same state,
             so both beats enter here.
             The melee damage `random(1,8) * 3` is written in the CALL, not
             on a class, so it is easy to miss when reading actors.

    ATTACK   RS_SpliceBaron.Missile
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:1392
    shape    BURST
    payload  ArachnotronPlasma (vanilla) x1 per cycle
    arc      0
    timing   3, 2, 1 then A_SpidRefire loops to Missile+2 -- 6-tic sustained cycle
    damage   vanilla ArachnotronPlasma: Damage 5 --> 5 * random(1,8) = 5..40
    type     (vanilla, untyped)
    sound    vanilla "baby/attack" (ArachnotronPlasma SeeSound); A_BabyMetal walk clanks in See
    impact   vanilla APBX A-E plasma splash
    trigger  Missile   (via A_Jump(127,"Missile2") failing -- 129/256 stays here)
    range    --
    mirrored no
    inherit  --   (ArachnotronPlasma is engine-vanilla, not authored here)
    profile  MakeVolley(proj:"ArachnotronPlasma", count:1); p.BurstDelayTics=6
    notes    A pure arachnotron loop bolted onto a baron body. 20-tic wind-up
             on first entry, then a 6-tic sustained cycle held by A_SpidRefire.

    ATTACK   RS_SpliceBaron.Missile2
    file     zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:1398
    shape    FAN
    payload  BaronBall (vanilla) x3
    arc      10 total -- explicit angles +5, 0, -5
    timing   5,5,5 -- 15 tics, then Goto See+1
    damage   vanilla BaronBall: Damage 8 --> 8 * random(1,8) = 8..64 EACH
    type     (vanilla, untyped)
    sound    vanilla "baron/attack" per ball
    impact   vanilla BAL7 C/D/E, DeathSound "baron/shotx"
    trigger  Missile   (via A_Jump(127,"Missile2") -- 127/256, roughly half)
    range    --
    mirrored no
    inherit  --   (BaronBall is engine-vanilla)
    profile  MakeVolley(proj:"BaronBall", count:3, arc:10); p.BurstDelayTics=5
    notes    THE ANGLES ARE EXPLICIT AND EVENLY STEPPED (+5, 0, -5), which is
             the one case in this family where VolleyArc reproduces the
             original exactly -- an even 10-degree fan of 3. Every other fan
             here is either rolled or non-monotone.
             Roughly a coin flip between this and the plasma loop each time.

---
---

# UNRESOLVED

Honest gaps. Nothing below is a guess dressed as a finding.

### U1 — THE ENTIRE MONSTER-SIDE HALF OF `RS_AttackProfile` IS DECLARED AND INERT

This is the largest finding of the pass and it affects all seventeen files,
not just this one.

`VolleyCount`, `VolleyArc`, `VolleyPitchJitter`, `BurstDelayTics`,
`FireTrigger`, `MinRange`/`MaxRange` (via `InRange()`/`HasRangeBand()`),
`SummonClass`/`SummonCount`/`SummonCap`/`SummonTierOffset`, `RadialRadius`/
`RadialDamage`/`RadialHeal`/`RadialHitsAllies`, and `BuffSpeedMult`/
`BuffDamageMult`/`BuffDuration`/`BuffNoPain` are **written by the factories,
copied by `Clone()`, and read by nothing.** Verified by grepping the whole
`zscript/` tree: outside `RS_AttackProfile.zs` itself there are zero readers.

The two consumers confirm it:

* `RS_Weapon.zs:672-728` (hitscan) calls
  `A_FireBullets(spread, spread, pellets, dmg, puff, FBF_NORANDOM)` — one
  volley, one tic, symmetric spread. It never looks at VolleyCount or
  BurstDelayTics.
* `RS_Weapon.zs:959-1039` (`RS_FireProfileHeavy`) loops over `pellets`
  (from `PelletOverride`, not `VolleyCount`) with a **hardcoded
  `fanStep = 4.0`**. It never looks at VolleyArc, VolleyCount,
  VolleyPitchJitter or BurstDelayTics.

So **every `profile` line in this catalog — and, if the layer is shared,
in the other sixteen — targets fields the dispatch does not consume.**
The rows are still the right deliverable; the parts bin is correct and the
machine to read it does not exist yet. But nobody should build against
these lines believing `MakeBurst(count:22, delayTics:3)` currently fires
22 anything.

**Checked against in-flight work, not just HEAD.** Both
`RS_AttackProfile.zs` and `RS_Weapon.zs` had uncommitted modifications in
the working tree while this pass ran (+141/−17 lines, another lane's). The
analysis above was performed against the *working-tree* versions, and a diff
of both files shows **no added or removed line mentioning `VolleyCount`,
`VolleyArc`, `VolleyPitchJitter`, `BurstDelayTics`, `FireTrigger`,
`InRange`, `SummonClass`, `RadialRadius` or `BuffSpeedMult`**. The finding
holds against both HEAD and the in-flight state — but it is a snapshot, and
if that lane lands a consumer this section should be re-checked rather than
trusted.

### U2 — CH vs OUR TREE: 4 KNOWN DEVIATIONS, ALL ALREADY DOCUMENTED IN-FILE

Every attack call site matches CH argument-for-argument and tic-for-tic.
The four differences are all mechanical DECORATE→ZScript translations, all
carry a `// CH:` note at the site, and none changes an attack's numbers:

1. `MISL E` → `MISL D` at six sites (`RS_GrayCGuff`, `RS_DetoPuff2`,
   `RS_DetoPuff3`, `RS_VolativeCaco` ×3). Frame E does not exist in either
   IWAD or in CH; CH rendered nothing there too. Tics and actions unchanged.
   Documented at `RS_ChaingunnerFX.zs:16-29`.
2. `CallACS("CH_CyanBounce")` → `RS_Zom.CV('rs_ch_cyanbounce', 0)`
   (`RS_Chaingunner.zs:396`, :404, :409) — cvar gate replacing an ACS call.
   Affects the Cyan's dodge, not any attack.
3. `A_SetUserVar("user_hide", ...)` → a plain ZScript `int` field
   (`RS_Chaingunner.zs:541`, :548, :578). Same values.
4. `ThrustThing(angle*256/360+64,...)` → `ThrustThing(int(angle*256/360+64),...)`
   — an explicit cast ZScript requires. Same arithmetic.

Also worth recording, not a deviation: CH writes `Damage (random(a,b))`
(legal in DECORATE) where we correctly write `DamageFunction (random(a,b))`.
The rolls are identical; the properties are not interchangeable.

### U3 — THE ACCELERATING / CONVERGING RAMPS ARE THE FAMILY'S SIGNATURE AND NOTHING CAN HOLD THEM

Five attacks in this family are built on a ramp, and every one flattens:

| attack | the ramp | what a profile can say |
|---|---|---|
| `RS_GrayCGuy2.Missile[+7]`, `M2`, `M3` | inter-shot gaps 9,7,5,3 | one uniform delay |
| `RS_GrayCGuy2.M1` | gaps 9,7,4,3 (irregular, CH's own) | one uniform delay |
| `RS_CyanCGuy2.Missile` | spread converging ±11→±1 over 22 shots | one constant arc |
| `RS_BrownCGuy2.Missile[+9]` | spread widening ±2→±4→±6 | one constant arc |
| `RS_YellowCGuy.Spam` | gaps 4,4,3,3,2,1,1,1,1 | one uniform delay |
| `RS_YellowCGuy.Spam2` | angles +3,−3,−6,−3,0,+3,+6,0 (non-monotone) | an even sweep |

The shape that is missing is **a per-shot ramp on delay and on spread** —
start value, end value, count. It would cover all six above and it is a
strictly smaller addition than any of them individually. Recorded here as a
finding, not proposed as work.

### U4 — FOUR ATTACKS HAVE NO SHAPE WORD IN THE CLOSED SET

Written as `shape UNCLASSIFIED` per the spec, with the behaviour in `notes`.
No word was coined.

* **Summons.** `RS_WhiteCguy2.Summon1/2/3` and `Phase2`. The set has no
  summon shape. `RS_ATK_SUMMON` exists on the profile class, so the *mode*
  is expressible even though the *shape* is not.
* **In-place chained radius bursts.** `RS_CGNail.Death`,
  `RS_YellowBombCGUYEX.Death`, `RS_CGBigEx.Death`, `RS_CGBigOne.Death`.
  No projectile, no travel, several blasts of growing radius in one spot.
  `MakeRadial` holds the mode; no shape word fits.

If the composer wants these covered, the two candidate words are `SUMMON`
and `RADIAL` — both already exist as `RS_ATK_*` mode constants, so adding
them to the shape vocabulary would not introduce new concepts. **That is a
suggestion for the spec owner, not a change made here.**

### U5 — SCOPE: THE FOUR MINIONS

Section 3 catalogues `RS_SlimyWorm`, `RS_VolativeCaco`, `RS_SpliceBaron` and
`RS_BabyCaco` (7 rows). They are chaingunner-family content — they live in
`RS_ChaingunnerFX.zs`, cite CH `Chaingunners.txt` lines, and are summoned by
`RS_WhiteCguy2` — but they are **not** among the 14 tier-ladder monsters this
pass was scoped to, and they carry no tier token. Included because dropping
seven real attack rows silently is worse than including them clearly marked.
**Delete Section 3 if the family boundary is meant to be the tier ladder.**

### U6 — CH IS NOT AT THE PATH `CLAUDE.md` AND THE SPEC BOTH NAME

`C:\Users\Command\Desktop\CH` **does not exist on this machine.** The Desktop
holds `CHP`, not `CH`. Both `CLAUDE.md` ("THE GROUND TRUTH IS
`C:\Users\Command\Desktop\CH`") and `rs_35`'s §4 ("CH is at
`C:\Users\Command\Desktop\CH`") point there.

The CH pack **is** present at `E:\New folder\ART SOURCE\CH\` — the path
`CLAUDE.md` names in its *other* section ("Source of truth for all of it:
`E:\New folder\ART SOURCE\CH\`"). `decorate\Chaingunners.txt` there is 3,169
lines, exactly matching the line count our file headers cite, and every
attack site matches. **All CH citations in this document are against
`E:\New folder\ART SOURCE\CH\`.**

Two paths for one authority, one of them dead, is exactly the shape of
mistake this project has paid for before. Worth the owner's word on which is
correct before the next family is catalogued. **No file was changed.**

### U7 — ONE SOUND DOES NOT RESOLVE, AND IT IS CH'S GAP TOO

`DeathSound "spike/spiked"` on `RS_IceZombieShot` (inherited by
`RS_IceZombieShot2`, the Cyan Chaingunner's entire payload) is **defined in
neither our `SNDINFO` nor CH's**. Twenty-two ice shards shatter silently.
Already noted verbatim at `RS_Zombieman.zs:372`; recorded here because the
`impact` field of two rows depends on it and a silent sound is inert, not an
error — there is no check that can fail.

Every other attack-level sound in this family resolves:
`chainguy/attack` (engine `filter/game-doomchex/sndinfo.txt` → `dsshotgn`),
`prox/beep`, `Science/Atk`, `Science/Enuff`, `SlimeBall/Shoot`, `Ice/Hit2`,
`Jam/Jamd`, `moloch/nailhit`, `gas/gas1`, `slimeball/splat`, `SNPRFIRE`,
`weapons/firex4`, `fire/fire3`, `spit/spit`, `spell/Impact1`, `Bomb/boom`,
`Spell/SpellCast1`, `Fire/Fire4`, `BabyCaco/Melee`, `weapons/boom1`.
Checked by name against `E:\RS_Main\SNDINFO`; **lump-level end-to-end
resolution was NOT verified** — that is the import rule's job, not this
catalog's, and claiming it would be exactly the kind of check that agrees
with itself.

### U8 — THREE "HOMING" PROJECTILES DO NOT HOME, AND ONE ARG-ORDER BUG IS PRESERVED

All four are CH's, verified against CH, and all four are correct as imported.
Listed so no later pass "fixes" them:

* `RS_Boomer3` (`RS_ChaingunnerFX.zs:584`) — clears `-SEEKERMISSILE` but still
  calls `A_SeekerMissile(7,7)`. No tracer is ever assigned, so nothing
  steers. CH `Chaingunners.txt:1499-1507`, identical.
* `RS_SpamShotsCguy` (`:967`) — has `+SEEKERMISSILE` but its Spawn never calls
  `A_SeekerMissile`. A tracer is assigned and nothing reads it.
* `RS_GenShield` (`:935`) — same as above. Also carries `DropItem "Cell"` on a
  projectile, which is CH's.
* `RS_BlackCGuyEX.YE` (`RS_Chaingunner.zs:1701`, :1703) — passes
  `CMF_AIMOFFSET` in the *angle* slot and `random(0,360)` in the *flags* slot.
  CH's own arg-order error (`Chaingunners.txt:1988`, :1990), kept verbatim.
  It compiles and only affects a `+NOINTERACTION` cosmetic puff.

The ones that DO home: `RS_Boomer1` (8,8), `RS_Boomer2` (4,4),
`RS_CGBigOne` (3,6), `RS_CGBigEx` (2,4), `RS_CGRailBuff` (flag set, steered
by the railgun's own spiral rather than an action).

### U9 — WHAT WAS NOT MEASURED

* **Sprite prefixes were not verified as present.** This catalog names
  `CZV1`, `CPS2`, `PZOW`, `HCPO`, `BFGZ`, `FSZS`, `CPOS`, `WORM`, `CACB`,
  `ARBR`, `HEAD`, `SB4G`, `GBLL`, `BBOM`, `GRFZ`, `RED8`, `RED9`, `SPIR`,
  `BOGY`, `BLAD`, `6PUF`, `FBL1`, `ICEY`, `BAL1`, `BAL7`, `BFS1`, `BFE1`,
  `MISL`, `PLSS`, `PLSE`, `SPPL`, `APBX`, `FIRE`, `SSBL`, `RIP1`, `SMK2`,
  `CHTA`, `A8Y5`, `BCAB`, `CGUG`, `CGUB`, `CGUP`, `AYPB`, `PUFF` only as
  in-file evidence for frame counts. Whether each resolves to a real lump is
  the import rule's denominator, not this one's.
* **Two payload counts are genuinely unbounded**, not unmeasured:
  `RS_CGBigOne.Spawn` and `RS_CGBigEx.Spawn` shed one hazard per 3 tics of
  flight until impact. The `count:8` in those two `profile` lines is a
  placeholder for a mid-range shot and is labelled as such in the rows.
* **`A_MonsterRefire` / `A_CPosRefire` / `A_SpidRefire` continuation odds
  were not converted to expected round counts.** The refire chance is
  recorded per row (64, 128, 150, 188) but the resulting sustained volume
  depends on line of sight and skill level, and any number here would be a
  model rather than a reading.
* **DamageFactor interactions were not modelled.** Several rows note that
  `DamageType "Melee"` on the scientist's needles collides with
  `DamageFactor "Melee", 3.75` on the scientist herself and `1.5` on the
  Cyan Chaingunner. What that means in infighting was not computed.
