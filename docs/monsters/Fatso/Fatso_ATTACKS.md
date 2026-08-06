# FATSO (Mancubus) -- ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Field order and the shape
vocabulary are the spec's; nothing here coins a word.

## Denominator -- what was actually read

| thing | count |
|---|---|
| classes in `zscript/monsters/fatso/RS_Fatso.zs` | 22 (read whole, 2391 lines) |
| ... of which carry attacks | **14** |
| ... of which are cvar-gate / spawn stubs with no attack | 8 (`RS_Colourset10`, `RS_BrownFatso`, `RS_CyanFatso`, `RS_AbyssFatso`, `RS_FireBluFatso`, `RS_GrayFatso`, `RS_BlackFatso`, `RS_WhiteFatso`) |
| classes in `zscript/monsters/fatso/RS_FatsoFX.zs` | 50 (read whole, 1596 lines) |
| external payload classes opened in other files | 18 (lostsoul 14, imp 2, revenant 2, chaingunner 1, shotgunner 1 -- listed at the bottom) |
| state labels in `RS_Fatso.zs` | 211 total; **89** survive the boilerplate filter |
| ... attack chains among those 89 | 43 |
| ... pure choosers / range gates (not rows) | 12 |
| ... movement, pain, buff, wind-up (not rows) | 34 |
| attack call SITES (source lines, comments stripped) | `RS_Fatso.zs` 253 = 241 `A_CustomMissile` + 4 `A_CustomRailgun` + 3 `A_FatAttack1/2/3` + 2 `A_VileTarget` + 1 `A_CustomBulletAttack` + 1 `A_SkullAttack` + 1 `A_VileAttack`; `RS_FatsoFX.zs` 36 `A_CustomMissile`. **289 total.** |
| **ATTACK ROWS BELOW** | **49** (43 primary + 6 secondary/impact-is-an-attack) |

A call site is NOT a projectile. `QUEE GGGG…(41 G's) 0 A_CustomMissile` is one
source line and forty-one projectiles. Every row below gives the projectile
count, not the line count.

## Cross-check against CH -- clean, with one path correction

**The brief named CH at `C:\Users\Command\Desktop\CH`. That path does not
exist on this machine** (`Test-Path` -> False; the Desktop holds `CHP`, not
`CH`). CH was read at the path CLAUDE.md itself names for this pack,
**`E:\New folder\ART SOURCE\CH\decorate\Fatsos.txt`**, and identity confirmed
before use: 4,075 lines (matches both file headers' claim) and lines
1175 / 2007 / 2223 / 3442 / 3462 open `CommonFatso` / `YellowFatso` /
`RedFatso` / `WhiteFatso` / `WhiteFatso2`, exactly as our per-actor `// CH:`
citations claim. No other pack was consulted. See UNRESOLVED U1.

Diff performed, comments stripped from both sides, `RS_` prefix normalised,
case-folded, whitespace-stripped, compared as a MULTISET (so counts had to
match, not just membership):

* every `A_CustomMissile` / `A_SpawnItemEx` / `A_CustomBulletAttack` /
  `A_CustomRailgun` / `A_VileAttack` / `A_VileTarget` / `A_SkullAttack` /
  `A_Explode` call in our two files -- **ours-only set is EMPTY**. Every
  attack call we ship exists verbatim in CH with the same argument text and
  the same repetition count.
* CH-only set is 31 lines and is fully accounted for: 7 are the
  `CHRandom_GibGenerator` gore chain (stripped by standing order, `// CH:`
  comment left at each site) and 24 live inside FX classes that ship from
  other families' files -- each of those 24 was opened at its real home and
  matches.
* damage: every `Damage(random(a,b))` in CH reconciles 1:1 with a
  `DamageFunction (random(a,b))` here. **No roll is flattened anywhere in this
  family.** Bare constants (`Damage 8`, `Damage 5`, `Damage 3`, `Damage 2`,
  `Damage 1`, `Damage 0`) are bare in CH too.

**Result: zero behavioural divergence found between our tree and CH for this
family.** Where a row below flags something odd, the oddity is CH's and is
reproduced faithfully -- it is not an import defect. Those are called out in
`notes` as `CH-faithful`.

## Reading the rows

* `A_CustomMissile(cls, spawnheight, spawnofs_xy, angle, flags, pitch)`.
  Argument 3 is a **lateral spawn offset in map units** (the two barrels),
  argument 4 is the **angle in degrees**. They are different axes and the rows
  keep them apart: `arc` is angles only; barrel offsets are stated separately.
* **Timing convention that decides whether a "pair" is a pair.** The action
  fires when the state is *entered*. So `H 0 CM(-21); H 10 CM(+21)` is a
  genuine simultaneous pair (both on the same tic, then a 10-tic hold), while
  `H 10 CM(+13); H 0 CM(-13)` is the two barrels **10 tics apart**. Both
  orderings occur in this family and the difference is audible and visible.
  Every row states which it is.
* Shape ties resolved by one rule, stated here so seventeen files compose:
  **all shots on ONE tic + stepped angles -> FAN; one tic + random angles ->
  SALVO; spread over time + random angles -> SCATTER; spread over time + same
  angle -> BURST.** `MULTI` is used only when two or more *damaging* payload
  classes fire in the same chain (a 0-damage telegraph does not make a row
  MULTI).
* `A_Explode` default flags are `XF_HURTSOURCE`. A row says **self-harming**
  when the call omits the flags argument, and **not self-harming** when it
  passes `0`.
* Sprite frames are stripped per the spec. Tier-icon `A_SpawnItemEx` and
  `RS_Splash11` / `RS_SplashAbyss` decor spawns are stripped: they are the
  family's per-state cosmetic tick, present in every state including non-attack
  ones, and carry no damage.

---
---

# TIER 1 -- RS_CommonFatso ("Mancubus")

    ATTACK   RS_CommonFatso.Missile
    file     zscript/monsters/fatso/RS_Fatso.zs:923
    shape    FAN
    payload  RS_FatShot2 x6   (via A_FatAttack1/2/3 default spawntype "FatShot",
                               which RS_FatShot2 `replaces` -- FatShot never flies)
    arc      22.5 total, in three fixed pairs off the aim line:
             A_FatAttack1 -> 0, +11.25
             A_FatAttack2 -> 0, -11.25
             A_FatAttack3 -> -5.625, +5.625
             (FATSPREAD = 90/8 = 11.25, engine constant, verified in
              qzdoom.pk3 zscript/actors/doom/fatso.zs)
    timing   20 (A_FatRaise wind-up), then 10,5,5 / 10,5,5 / 10,5,5
             -- the three pairs are 20 tics apart; each pair is simultaneous
    damage   Damage 8   (bare constant; engine rolls it as a projectile)
    type     Fire   (RS_FatShot2 adds DamageType "Fire"; vanilla FatShot has none)
    sound    "fatso/raiseguns" on A_FatRaise (the telegraph); "fatso/attack"
             per shot from RS_FatShot2's SeeSound. Both are engine built-ins
             (qzdoom filter/game-doomchex/sndinfo.txt), not repo SNDINFO.
    impact   MISL B/C/D fireball puff, DeathSound "fatso/shotx". No A_Explode --
             this is the only Fatso projectile in the family with no splash.
    trigger  Missile
    range    --
    mirrored no   (the +/- symmetry is the shape, not a mirrored branch)
    inherit  Fatso (engine). Only Missile/Pain/Death/XDeath/Raise/Grow are
             overridden; A_FatAttack1/2/3 are engine code, not repo code.
    profile  MakeBurst(proj:"RS_FatShot2", count:6, delayTics:20, arc:22.5,
                       fireSnd:"fatso/raiseguns")
             // arc is uniform in the factory; CH's true list is the three
             // pairs above. Record, don't round.
    notes    THE ONLY ROW IN THIS FAMILY WITH FIXED ENGINE ANGLES. Every other
             Mancubus here re-rolls its angles per shot. If a weapon wants "the
             Mancubus shot", this is it and the numbers are 11.25 / 5.625.
             Death spawns RS_FatsoArmed (an inert FAT2 I prop, Speed 0,
             -NOGRAVITY, no damage) -- a corpse prop, not an attack.

---

# TIER 2 -- RS_GreenFatso ("Green Mancubus")

    ATTACK   RS_GreenFatso.Missile
    file     zscript/monsters/fatso/RS_Fatso.zs:1035
    shape    SCATTER
    payload  RS_GreenBomb1 x6
    arc      -8..+8 union, re-rolled per shot, six DIFFERENT bands in fixed order:
             1: +13 barrel, random(-5,6)
             2: -13 barrel, random(-6,5)
             3: +13 barrel, random(-7,5)
             4: -13 barrel, random(-5,7)
             5: +13 barrel, random(-8,5)
             6: -13 barrel, random(-5,8)
             The band WIDENS by one degree per pair, and each pair mirrors.
    timing   20 (A_FatRaise), then shots at t=0,10,20,30,40,50 -- 10 tics apart
             throughout. NOT a paired volley: the 10-tic state comes FIRST, so
             the two barrels alternate rather than fire together.
    damage   DamageFunction (random(20,75))
    type     Plasma
    sound    "fatso/raiseguns" (A_FatRaise); "spit/spit" per shot (SeeSound)
    impact   BAL2 CDE, 3 frames x 6 tics, A_Explode(random(8,37),64) on EACH of
             the three -- three explosions, self-harming (flags omitted).
             DeathSound "spit/spit2". Trails RS_Trail12 every 6 tics in flight.
    trigger  Missile
    range    --
    mirrored no   (alternation is inherent, not a branch)
    inherit  Fatso (engine) for the actor; RS_GreenBomb1 defines its own
             Death -- nothing inherited.
    profile  MakeBurst(proj:"RS_GreenBomb1", count:6, delayTics:10, arc:16,
                       fireSnd:"spit/spit")
    notes    Spawn height 20 for all six. RS_GreenBomb1 lives at
             zscript/monsters/lostsoul/RS_LostSoulFX.zs:2360 (CH Fatsos.txt:1437);
             opened and matched. Death spawns RS_FatsoArmed2 (inert prop).

---

# TIER 3 -- RS_BlueFatso ("Blue Mancubus")

Missile (`:1155`) is a 50/50 chooser -- `A_Jump(256,"Waves","Beam")` -- not a row.

    ATTACK   RS_BlueFatso.Waves
    file     zscript/monsters/fatso/RS_Fatso.zs:1160
    shape    SCATTER
    payload  RS_Bluewave1 x6
    arc      -8..+8 union, six bands, WIDENING per pair and swapping which side
             leads:
             1: +21 barrel, random(-6,1)
             2: -21 barrel, random(-1,6)
             3: +21 barrel, random(-1,6)
             4: -21 barrel, random(-6,1)
             5: +21 barrel, random(-5,5)
             6: -21 barrel, random(-8,8)
    timing   17 (A_FatRaise), then t=0, 8, 22, 30, 44, 52.
             Pattern per pair: fire +21 (hold 8), fire -21 (hold 0), then 7+7
             recovery. Barrels are 8 tics apart -- NOT simultaneous.
    damage   DamageFunction (random(10,69))
    type     Plasma
    sound    "fatso/raiseguns"; "fatso/attack" per wave (SeeSound)
    impact   IN FLIGHT it already damages: Fly2 runs
             `DIS1 CFEDB 2 A_Explode(random(7,17),72,0)` -- five frames, five
             explosions, every 10 tics, not self-harming, and it LOOPS. It also
             sheds RS_Bluewave2 (inert, no damage) twice per loop.
             ON DEATH: three A_Explode(random(5,19),72) (self-harming) over
             DIS1 G/H/I, then 18 x RS_PlasmaBallSP4 in three 120-degree arcs
             (random(0,120) / random(120,240) / random(240,359)), each with
             velocity random(15,60) forward and random(-33,33) vertical.
             DeathSound "weapons/bfgx".
    trigger  Missile   (via A_Jump(256,"Waves","Beam") -- 50%)
    range    --
    mirrored no
    inherit  RS_Bluewave1 at zscript/monsters/lostsoul/RS_LostSoulFX.zs:2484
             (CH Fatsos.txt:1699); defines its own Death, nothing inherited.
    profile  MakeBurst(proj:"RS_Bluewave1", count:6, delayTics:8, arc:16,
                       fireSnd:"fatso/attack")
    notes    A ROLLING AoE WAVE, not a bolt -- the in-flight per-frame
             A_Explode is the point of it and is one of the ~55 DELIBERATE
             multi-frame explodes (MEMORY.md). Do NOT collapse it to one
             detonation. Scale is deliberately flat: Scale 0.75, YScale 0.4.

    ATTACK   RS_BlueFatso.Beam
    file     zscript/monsters/fatso/RS_Fatso.zs:1171
    shape    SCATTER
    payload  RS_BlueFT2 x4   (+ RS_BlueFT x1, a 0-damage telegraph flash)
    arc      exactly 0, then random(-4,4), then random(-9,9), then
             random(-16,16). A widening cone that ACCELERATES as it widens.
    timing   telegraph flash at t=0, then 16+7 = 23 tics of wind-up, then
             bolts at t=23, 31, 36, 40 -- gaps 8,5,4,3. The cadence tightens
             while the spread opens.
    damage   DamageFunction (random(10,70))   [RS_BlueFT2]
             Damage 0                         [RS_BlueFT, the telegraph]
    type     Plasma
    sound    "Spell/Lightn" from the RS_BlueFT flash (the tell that the beam is
             coming); "fatso/attack" per bolt.
    impact   RS_BlueFT2: BFE1 A-F over 32 tics with two A_SetScale shrinks and
             NO A_Explode -- a visual-only detonation. DeathSound
             "weapons/bfgx". It trails RS_BlueFT3 (Damage 0, +NOINTERACTION)
             on EVERY flight tic, which is what makes it read as a beam.
             RS_BlueFT itself: Speed 0, Damage 0, five A_SetScale frames. Pure
             telegraph, sits at the barrel.
    trigger  Missile   (via A_Jump(256,"Waves","Beam") -- 50%)
    range    --
    mirrored no
    inherit  RS_BlueFT :2390, RS_BlueFT2 :2449, RS_BlueFT3 :2421 -- all
             zscript/monsters/lostsoul/RS_LostSoulFX.zs. None inherit.
    profile  MakeBurst(proj:"RS_BlueFT2", count:4, delayTics:5, arc:32,
                       fireSnd:"Spell/Lightn")
             // delayTics is uniform in the factory; CH's 8/5/4/3 ramp has no
             // exact form. 5 tics = 15 total vs CH's 17. Recorded, not rounded.
    notes    Ends `A_Jump(128,"Beam","Missile")` -- 50% fires Beam AGAIN
             immediately, 50% re-rolls the whole Waves/Beam coin. So Beam
             chains. NOT MULTI: RS_BlueFT deals zero damage.

---

# TIER 4 -- RS_PurpleFatso ("Purple Mancubus")

Missile (`:1288`) is a three-way gate, not a row:
`A_JumpIfHigherOrLower("Swoosh", null, 32, 0, true)` -> target more than 32
units ABOVE -> Swoosh (there is no "lower" label, so a target below does not
branch); else `A_JumpIfCloser(1550,"Boing1")`; else `A_Jump(255,"Swoosh")`.

    ATTACK   RS_PurpleFatso.Boing1
    file     zscript/monsters/fatso/RS_Fatso.zs:1295
    shape    SCATTER
    payload  RS_PurpleBomb1 x6
    arc      -9..+9 union, six bands, widening:
             1: +13 barrel, random(-5,9)
             2: -13 barrel, random(-9,5)
             3: +13 barrel, random(-9,5)
             4: -13 barrel, random(-5,9)
             5: +13 barrel, random(-9,9)
             6: -13 barrel, random(-9,9)
    timing   17 (A_FatRaise), then t=0, 11, 25, 36, 50, 61 -- barrels 11 tics
             apart (11-tic state first), 7+7 recovery between pairs.
    damage   DamageFunction (random(10,65))
    type     Fire
    sound    "fatso/raiseguns"; "caco/attack" per bomb (SeeSound);
             "Bomb/bounce" on each floor bounce
    impact   A GRENADE, not a bolt. Gravity 0.3, -NOGRAVITY, BounceType Hexen,
             BounceCount 8, BounceFactor 1.25, +EXPLODEONWATER.
             Bounce.Wall: 12 x RS_MiniFatsoPurpleBomb thrown in three
             120-degree arcs (random(0,120)/random(120,240)/random(240,359)),
             then A_Stop, then falls into Death+2.
             Death: SBS4 FGH, three frames, A_Explode(random(5,28),88) on EACH
             -- three explosions, self-harming. DeathSound "Bomb/boom".
             Each mini: DamageFunction (random(5,20)) Fire, Hexen bounce x4,
             8% chance per 6-tic frame to self-detonate, Death =
             A_Explode(random(2,10),42) twice.
    trigger  Missile
    range    ..1550   (and only when the target is NOT >32 above)
    mirrored no
    inherit  RS_PurpleBomb1 :2553, RS_MiniFatsoPurpleBomb :2602 --
             zscript/monsters/lostsoul/RS_LostSoulFX.zs. Neither inherits.
    profile  MakeBurst(proj:"RS_PurpleBomb1", count:6, delayTics:11, arc:18,
                       fireSnd:"caco/attack"); p.MaxRange = 1550
    notes    A wall bounce is a CLUSTER EVENT (12 sub-bombs), a floor bounce is
             not. That asymmetry is the whole character of the weapon.

    ATTACK   RS_PurpleFatso.Swoosh
    file     zscript/monsters/fatso/RS_Fatso.zs:1307
    shape    HITSCAN
    payload  -- (trace; puff class RS_FatsoPuff3)
    arc      spread_xy 15, spread_z 1   (a wide, flat cone)
    timing   5 tics per burst, then `FATT IG 3 A_MonsterRefire(180,"See")`
             (6 tics) -> `Goto Missile+2`, which re-runs the height check and
             can come straight back. Effectively a 11-tic loop.
    damage   A_CustomBulletAttack(15, 1, random(1,8), random(1,3),
                                  "RS_FatsoPuff3", 8000)
             -> numbullets random(1,8), damageperbullet random(1,3).
             No CBAF_NORANDOM is passed (flags argument is absent), so the
             engine's own per-bullet random multiplier applies on top. See
             UNRESOLVED U2 -- the multiplier could not be read from source on
             this machine.
    type     -- (none set; the puff carries no DamageType)
    sound    "Ratata/rata1" at volume 1.9, played on channel 0, one per burst
    impact   RS_FatsoPuff3 -- +NOINTERACTION, +MTHRUSPECIES, Scale 0.5,
             Alpha 0.6, BAL1 CDE. Purely visual; the trace itself does the
             damage. Range 8000 = effectively unlimited.
    trigger  Missile   (the anti-air / long-range branch)
    range    1550..    OR any distance when the target is >32 units ABOVE
    mirrored no
    inherit  RS_FatsoPuff3 at zscript/monsters/revenant/RS_RevenantFX.zs:2036
             (CH Fatsos.txt:1880) -- ceded to the Revenant lane, read-only here.
    profile  MakeHitscan(fireSnd:"Ratata/rata1", spreadScale:0.15,
                         impactPuff:"RS_FatsoPuff3"); p.MinRange = 1550
    notes    THE ONLY HITSCAN ON A FATSO IN THIS FAMILY (the White boss's rails
             are railguns, a different mode). It is also the family's only
             anti-air answer, which is why the height gate fires it
             unconditionally at any range. Pellet count is itself a roll --
             random(1,8) -- so the burst size varies 8x shot to shot.

---

# TIER 5 -- RS_YellowFatso ("Orange Mancubus")

Missile (`:1421`) gates: `A_JumpIfCloser(1750,"Choice")` else Alternative.
Choice (`:1425`) is `A_Jump(255,"Rocketo","Alternative")` -- ~50/50.

    ATTACK   RS_YellowFatso.Rocketo
    file     zscript/monsters/fatso/RS_Fatso.zs:1430
    shape    SCATTER
    payload  RS_RocketShotFatso x8
    arc      -6..+6, alternating tight/loose in a fixed rhythm:
             1: +42 barrel (height 35), random(-3,3)
             2: -39 barrel (height 34), random(-6,6)
             3: -39 barrel (height 34), random(-3,3)
             4: +42 barrel (height 35), random(-6,6)
             5: +42 barrel (height 35), random(-3,3)
             6: -39 barrel (height 34), random(-6,6)
             7: -39 barrel (height 34), random(-3,3)
             8: -39 barrel (height 34), random(-6,6)   <-- see notes
    timing   24 tics of A_FaceTarget wind-up, then t=0, 8, [4 recover],
             14, 22, [4], 28, 36, [4], 44, 52. Rhythm is 8-then-2 per pair
             with a 4-tic re-aim between pairs.
    damage   DamageFunction (random(10,40))
    type     Fire
    sound    "incubus/attack1" once at the start of the chain;
             "weapons/hominglaunch" per rocket (SeeSound)
    impact   MISL B/C/D. A_Explode(random(5,35),88) on the FIRST frame only,
             self-harming. DeathSound "weapons/homingexplode". Trails
             RS_HomingRocketTrailFatso every 2 tics (Alpha 0.33, no damage).
    trigger  Missile
    range    ..1750
    mirrored no
    inherit  RS_RocketShotFatso at
             zscript/monsters/lostsoul/RS_LostSoulFX.zs:2677 (CH :2176);
             RS_HomingRocketTrailFatso :2705. Neither inherits.
    profile  MakeBurst(proj:"RS_RocketShotFatso", count:8, delayTics:6, arc:12,
                       fireSnd:"weapons/hominglaunch"); p.MaxRange = 1750
    notes    CH-FAITHFUL ASYMMETRY: shot 8 fires from the -39/34 barrel where
             the pattern (and every other pair) would put it on +42/35. Our
             tree matches CH exactly; the multiset diff produced no ours-only
             line. Do not "correct" it.
             The class name says homing and the SeeSound says homing, but
             RS_RocketShotFatso has NO +SEEKERMISSILE and no A_SeekerMissile.
             It flies straight at Speed 28. That is CH's, verified.

    ATTACK   RS_YellowFatso.Alternative
    file     zscript/monsters/fatso/RS_Fatso.zs:1446
    shape    SALVO
    payload  RS_FatsoShotYE x6   (three simultaneous pairs)
    arc      random(-3,3) on all six. Barrels -12 and +12, spawn height 72
             (the highest muzzle in the family -- these lob down).
    timing   24 tics of wind-up, then pairs at t=0, 10, 20. Each pair IS
             simultaneous (0-tic state first, then the 5-tic hold), with a
             5-tic re-aim between pairs.
    damage   DamageFunction (random(10,40))
    type     Plasma
    sound    "incubus/attack2" once at the start;
             "spell/spellcast1" per shot (SeeSound)
    impact   +SEEKERMISSILE, and it really does seek: Spawn runs
             A_SeekerMissile(8,12,SMF_PRECISE) every 5 tics while shedding
             RS_SparkPuff1. Death: FIVE A_Explode(random(3,15),115) across
             BBOM B/C/D/E/G -- self-harming, radius 115, a big cluster.
             DeathSound "weapons/flameballexplode".
    trigger  Missile
    range    --   (the DEFAULT branch: fires at any range, and is the only
                   option beyond 1750)
    mirrored no
    inherit  RS_FatsoShotYE at zscript/monsters/lostsoul/RS_LostSoulFX.zs:2639
             (CH :2140). Does not inherit.
    profile  MakeVolley(proj:"RS_FatsoShotYE", count:2, arc:6,
                        fireSnd:"spell/spellcast1")
             // one PAIR. The chain is three of these 10 tics apart:
             // MakeBurst(proj:"RS_FatsoShotYE", count:6, delayTics:10, arc:6)
             // loses the pairing; both forms recorded, neither is exact.
    notes    THE SEEKER of the family. Five stacked explosions at radius 115
             makes a single hit far heavier than its random(10,40) suggests.

---

# TIER 6 -- RS_RedFatso ("Red Horned Mancubus")

    ATTACK   RS_RedFatso.Missile
    file     zscript/monsters/fatso/RS_Fatso.zs:1580
    shape    SALVO
    payload  RS_Shot2Fatso x2
    arc      random(-1,1) on both. Barrels +20 and -20, spawn height 32.
    timing   10 tics of A_FaceTarget, then BOTH on the same tic (two 0-tic
             states), then 5 tics of recovery. The whole attack is 15 tics.
    damage   Damage 8   (bare constant, CH-faithful -- engine rolls 8 x 1d8)
    type     Fire
    sound    -- for the ATTACK itself; "fatso/attack" per shot from the
             projectile's SeeSound. The monster plays nothing.
    impact   BIG. `MISL BC 4 A_Explode(random(10,40),128)` -- two explosions,
             self-harming -- then A_SetScale(2), then 16 x RS_SparkPuff1
             (cosmetic) and 17 x RS_Firespe2 thrown in fixed arcs
             (random(1,180) x5, random(180,359) x5, random(1,359) x7) with
             forward velocity random(2,21) and lift random(-1,3).
             DeathSound "fatso/shotx". In flight it sheds RS_SparkPuff1 every
             3 tics.
    trigger  Missile
    range    700..
    mirrored no
    inherit  RS_Shot2Fatso at zscript/monsters/lostsoul/RS_LostSoulFX.zs:2729
             (CH :2356). Does not inherit.
    profile  MakeVolley(proj:"RS_Shot2Fatso", count:2, arc:2); p.MinRange = 700
    notes    A tight two-shot with a very loud arrival. The DamageType is Fire
             but the impact spray (RS_Firespe2) is a separate bouncing ember
             set defined in the Revenant lane.

    ATTACK   RS_RedFatso.Fires
    file     zscript/monsters/fatso/RS_Fatso.zs:1587
    shape    SALVO
    payload  RS_HBeastShot x2   (+ 5 x RS_SparkPuff1, cosmetic, fired first)
    arc      exactly 0 on both -- no jitter at all. Barrels +20 and -20,
             spawn height 32.
    timing   5 cosmetic spark puffs on tic 0, then 12 tics of A_FaceTarget,
             then BOTH shots on the same tic, then 5 tics recovery.
    damage   -- (RS_HBeastShot sets NO Damage property, so Damage 0. It does
             not damage on contact; ALL of its damage is in its Death.)
    type     Fire
    sound    "horn/attack" per shot (SeeSound)
    impact   THIS IS THE ATTACK -- see the RS_HBeastShot.Death row below.
             +FLOORHUGGER, Speed 23, and Fly is only 3 frames x 6 tics with no
             Loop, so it self-terminates after 18 tics (~414 map units) and
             detonates whether or not it hit anything. A range-limited
             ground-crawling fire mine, not a bolt.
    trigger  Missile
    range    ..700
    mirrored no
    inherit  RS_HBeastShot at zscript/monsters/fatso/RS_FatsoFX.zs:642.
             Does not inherit.
    profile  MakeVolley(proj:"RS_HBeastShot", count:2, arc:0,
                        fireSnd:"horn/attack"); p.MaxRange = 700
    notes    The 5 spark puffs use CH's SHIFTED ARGUMENT FORM -- see UNRESOLVED
             U3. Harmless here (RS_SparkPuff1 is +NOINTERACTION).
             NOT A ROW BUT ADJACENT: RS_RedFatso.Buffs (`:1616`) fires on the
             5th Pain and permanently sets bNOPAIN, bMISSILEEVENMORE and
             A_SetSpeed(16). That is a self-buff, not an attack --
             MakeSelfBuff(speedMult: 2.0, noPain: true) is its shape if it is
             ever wanted.

---

# TIER 7 -- RS_FireBluFatso2 ("Big blob of fireblu")

    ATTACK   RS_FireBluFatso2.Missile
    file     zscript/monsters/fatso/RS_Fatso.zs:693
    shape    BURST
    payload  RS_FireBluFatsoBal1 x10
    arc      ~2 total, and FOUR OF THE TEN ARE EXACTLY 0. The "spread" is
             almost entirely the 40-unit barrel separation, not angle:
             1: +20 barrel, random(-1,1)      6: -20 barrel, random(-1,1)
             2: -20 barrel, random(-1,1)      7: +20 barrel, 0
             3: -20 barrel, 0                 8: -20 barrel, 0
             4: +20 barrel, 0                 9: +20 barrel, 0
             5: +20 barrel, random(-1,1)     10: -20 barrel, 0
             Spawn height 32 throughout.
    timing   10 tics of A_FaceTarget, then t=0,0 / 3,3 / 6,6 / 9,9,9,9.
             Three simultaneous pairs 3 tics apart, then FOUR ON ONE TIC as a
             finisher. 5 tics recovery.
    damage   DamageFunction (random(10,20))
    type     Plasma
    sound    -- for the attack; "imp/attack" per shot (SeeSound)
    impact   `BAL1 CDE 6 Bright A_Explode(random(1,7),32)` -- three small
             explosions, self-harming, radius 32. DeathSound "imp/shotx".
             In flight it emits blue then red particles on alternating frames.
             Scale 0.33, Radius 3 -- these are tiny, fast (Speed 45) tracers.
    trigger  Missile
    range    1800..
    mirrored no
    inherit  RS_FireBluFatsoBal1 at zscript/monsters/fatso/RS_FatsoFX.zs:431.
             Does not inherit.
    profile  MakeBurst(proj:"RS_FireBluFatsoBal1", count:10, delayTics:3,
                       arc:2, fireSnd:"imp/attack"); p.MinRange = 1800
             // the 4-on-one-tic finisher has no form in the factory. Recorded.
    notes    THE LONGEST-RANGED ATTACK IN THE FAMILY and the only one gated at
             1800+. Note the gate reads `A_JumpIfCloser(1800,"Fires")`, so this
             branch is the FAR one and Fires is the near one -- the opposite of
             how the state order reads.

    ATTACK   RS_FireBluFatso2.Fires
    file     zscript/monsters/fatso/RS_Fatso.zs:708
    shape    SALVO
    payload  RS_FireBluFatsoBal2 x2
    arc      exactly 0 on both (angle written explicitly as 0). Barrels +20 and
             -20, spawn height 32.
    timing   12 tics of A_FaceTarget, both shots on the same tic, 5 tics
             recovery. 17 tics total.
    damage   DamageFunction (random(15,50))
    type     Plasma
    sound    "Spell/spellCast1" per shot (SeeSound)
    impact   AN AREA-DENIAL SHELL. Speed 8 (very slow), Scale 1.5, Mass 600.
             IN FLIGHT: drops one RS_FireBluFatGround every 3 tics at
             random(+/-32) horizontal offset -- it lays a burning path.
             ON DEATH: A_SetTranslucent(0.35), then
             A_Explode(random(5,20),176) once, then EIGHT more
             RS_FireBluFatGround scattered at random(+/-128), then
             `MISL DDD 2 A_Explode(random(5,10),178)` -- three more
             explosions. All self-harming. DeathSound "Crack/death".
             RS_FireBluFatGround itself: +FLOORHUGGER +THRUACTORS, Speed 10,
             DamageFunction (random(5,15)) Fire, and its Spawn->Death chain
             runs A_Explode(random(3,15),64) on NINE separate frames while
             A_Wander-ing between them. Long-lived crawling fire.
    trigger  Missile
    range    ..1800
    mirrored no
    inherit  RS_FireBluFatsoBal2 :399, RS_FireBluFatGround :360 --
             zscript/monsters/fatso/RS_FatsoFX.zs. Neither inherits.
    profile  MakeVolley(proj:"RS_FireBluFatsoBal2", count:2, arc:0,
                        fireSnd:"Spell/spellCast1"); p.MaxRange = 1800
    notes    The nine-frame A_Explode on RS_FireBluFatGround is DELIBERATE
             lingering fire (MEMORY.md's ~55 sites). Do not convert it to a
             single detonation.

---

# TIER 8 -- RS_GrayFatso2 ("Big Gray and Ugly")

Miss2 (`:818`) is a pure range gate: `A_JumpIfCloser(1200,"Missile2")` else
`Goto Missile+3` (which lands on the first spike shot). Not a row.

    ATTACK   RS_GrayFatso2.Missile
    file     zscript/monsters/fatso/RS_Fatso.zs:810
    shape    SALVO
    payload  RS_FatsoSpikes x4   (two simultaneous pairs)
    arc      pair 1 -- -21 barrel random(-1,5), +21 barrel random(-5,1)
             pair 2 -- -21 barrel random(-1,1), +21 barrel random(-1,1)
             Spawn height 18. Pair 1 is loose and OUTWARD-biased; pair 2 is
             nearly dead-on.
    timing   20 (A_FatRaise), then pair 1 at t=0 (both same tic, hold 10),
             30 tics of A_FaceTarget + A_CheckSight, pair 2 at t=40 (same tic,
             hold 5), 15 tics recovery.
    damage   DamageFunction (random(28,85))   -- the hardest single projectile
             hit in the non-boss half of the family
    type     Melee   (yes, Melee on a projectile -- CH-faithful; it is what
                      makes the Gray's spikes bypass most elemental resists)
    sound    "fatso/raiseguns"; "monster/dknmsl" per spike (SeeSound)
    impact   `RIP1 A 0 { bNOGRAVITY = false; }` -- the spike DROPS on death --
             then `RIP1 ABCABC 8 A_Explode(random(1,8),16)`: six frames, six
             explosions, self-harming, radius 16, over 48 tics.
             Then a 6-point RING of RS_CGNail at 45, 105, 165, 225, 285, 345
             (exactly 60 degrees apart) -- see the secondary row below.
             DeathSound "weapons/boom1". In flight it sheds RS_FatsoSpikes2
             every 3 tics (each of those is itself a live random(10,40) bomb).
    trigger  Missile
    range    --   (Miss2's 1200 gate only applies on the 36% branch)
    mirrored no
    inherit  RS_FatsoSpikes at zscript/monsters/fatso/RS_FatsoFX.zs:466.
             Does not inherit. RS_FatsoSpikes2 lives at
             zscript/monsters/imp/RS_ImpFX.zs:216 (CH Fatsos.txt:1148).
    profile  MakeBurst(proj:"RS_FatsoSpikes", count:4, delayTics:20, arc:6)
    notes    64% of Missile entries take this branch; 36% jump to Miss2.

    ATTACK   RS_GrayFatso2.Missile2
    file     zscript/monsters/fatso/RS_Fatso.zs:824
    shape    SCATTER
    payload  RS_FatsoSpikes2 x64
    arc      frandom(-5,5) per spike -- a narrow cone. NOTE these are
             A_SpawnItemEx, not A_CustomMissile, so the "angle" is the spawn
             angle offset and the velocity is explicit: forward random(12,33),
             lift random(1,3). They are LOBBED, not fired.
             Barrel alternates -21 / +21 every block; spawn offset is
             (12 forward, +/-21 lateral, 24 up).
    timing   5 tics of A_FaceTarget, then eight blocks of
             [5 spikes on consecutive tics] + [3 spikes on one tic] = 8 per
             block, 64 total, with a 1-tic A_FaceTarget re-aim after block 4.
             Whole storm is ~48 tics. 15+15 recovery.
    damage   DamageFunction (random(10,40))   per spike
    type     Melee
    sound    -- for the attack itself (silent -- the volume comes from 64
             copies of the spike's own "monster/dknmsl" SeeSound)
    impact   RS_FatsoSpikes2: Gravity 0.1, -NOGRAVITY, Speed 5 -- a slow
             lobbed dart. Death is
             `RIP1 ABCABCABCBA 12 A_Explode(random(1,4),8)` -- ELEVEN frames,
             ELEVEN explosions, 12 tics each, radius 8, over 132 tics.
             Self-harming. DeathSound "weapons/boom1".
    trigger  Missile   (via A_Jump(92,"Miss2") ~36%, then A_JumpIfCloser(1200))
    range    ..1200
    mirrored no
    inherit  RS_FatsoSpikes2 at zscript/monsters/imp/RS_ImpFX.zs:216.
             Does not inherit.
    profile  MakeBurst(proj:"RS_FatsoSpikes2", count:64, delayTics:1, arc:10,
                       pitchJitter:2.0); p.MaxRange = 1200
    notes    THE SPIKES HAVE NO SHOOTER. A_SpawnItemEx is called with no
             SXF_SETTARGET / SXF_TRANSFERPOINTERS, so all 64 spikes have a null
             target pointer: they credit no infighting and the Gray takes no
             blame. That is CH's, verified against the multiset diff.
             The eleven-frame A_Explode is DELIBERATE (MEMORY.md).
             64 spikes x up to 11 explosions each is the single largest
             explosion budget in the non-boss half of the family.

---

# TIER 9 -- RS_AbyssFatso2 ("Ralph Bluetawn")

Missile (`:585`) branches 50/50 at `A_Jump(128,"Missile2")` after a shared
wind-up.

    ATTACK   RS_AbyssFatso2.Missile
    file     zscript/monsters/fatso/RS_Fatso.zs:591
    shape    SCATTER
    payload  RS_AbyssFatsoBomb x8
    arc      volley 1 -- +32 barrel, random(-17,4) x4   (LEFT-biased)
             volley 2 -- -32 barrel, random(-4,17) x4   (RIGHT-biased)
             Spawn height 32. The two volleys sweep opposite halves of a
             34-degree cone.
    timing   10 (A_FatRaise) + 10 (A_FaceTarget), then four bombs 7 tics apart,
             10 tics of re-aim, four more 7 tics apart, 10 tics recovery.
    damage   DamageFunction (random(20,85))
    type     Ice
    sound    "horn/attack" ONCE per volley (two plays total, on channel 0)
    impact   A BOUNCING BOMB THAT EXPLODES ON EVERY WALL, NOT JUST ON DEATH.
             +USEBOUNCESTATE +BOUNCEONWALLS, BounceFactor 1.1,
             WallBounceFactor 1.1, BounceCount 3.
             Bounce: A_SetScale(1.5,0.5), 5 x RS_AbyssShotIdentifier,
             `BFE1 C 2 A_Explode(random(10,75),128)` -- self-harming --
             plays "weapons/bfgx", then resumes flight.
             Death: `BFE1 C 5 A_Explode(random(5,75),128)` once, then 21
             RS_SplashAbyss2 laid out in two crossed lines (one along
             random(+/-328) X, one along random(+/-328) Y).
             In flight: 3 RS_SplashAbyss2 + 1 RS_AbyssShotIdentifier every
             4 tics, with the scale pulsing 0.7x0.4 -> 0.4x0.7.
    trigger  Missile   (ALSO re-entered from Pain -- `:611` ends `Goto Missile`,
                        so hurting this monster makes it attack)
    range    --
    mirrored yes   (volley 2 is volley 1 with the barrel and the angle band
                    both negated: +32/random(-17,4) -> -32/random(-4,17))
    inherit  RS_AbyssFatsoBomb at zscript/monsters/fatso/RS_FatsoFX.zs:267.
             Does not inherit.
    profile  MakeBurst(proj:"RS_AbyssFatsoBomb", count:4, delayTics:7, arc:21)
             // one volley. The attack is two of these, mirrored, 10 tics apart.
    notes    Up to 3 bounce-explosions + 1 death-explosion per bomb, x8 bombs
             = up to 32 radius-128 blasts from one attack.
             `Pain -> Missile` makes this monster a punish-on-hit; that is a
             trigger property worth carrying into any profile that copies it.

    ATTACK   RS_AbyssFatso2.Missile2
    file     zscript/monsters/fatso/RS_Fatso.zs:599
    shape    SALVO
    payload  RS_FatAbysswave x10   (two salvos of five)
    arc      salvo 1 (all on ONE tic, +32 barrel):
               random(-18,-10) x2, random(-12,-5) x2, random(-7,4) x1
             salvo 2 (all on ONE tic, 9 tics later):
               random(10,18) x2, random(5,12) x2, and random(-4,7) x1 from
               the -32 barrel
             Union -18..+18. The bands STEP outward-to-inward, so each salvo
             reads as a fan even though every angle is a roll.
             Spawn height is itself rolled: random(16,42) per wave.
    timing   2 tics of wind-up, five waves on tic 0, 9-tic gap, five waves on
             tic 9, 9 tics recovery, 10 tics of re-aim.
    damage   DamageFunction (random(14,60))
    type     Plasma
    sound    "spit/spit2" once at the start; "fatso/attack" per wave (SeeSound)
    impact   DAMAGES THE WHOLE WAY IN, like the Blue's wave. Spawn loops
             `DIS1 CFE 1 A_Explode(random(7,17),88)` -- three frames, three
             explosions, self-harming, every 6 tics of flight -- while
             A_Weave(random(-1,7),random(-1,1),random(-4,4),random(-1,1))
             makes it snake unpredictably.
             Death: A_Explode(random(2,35),128) on each of DIS1 G/H/I -- three
             more. DeathSound "weapons/bfgx". Alpha 1.85, XScale 1.0,
             YScale 0.25 -- a flat blue slab.
    trigger  Missile   (via A_Jump(128,"Missile2") -- 50%; ALSO reachable from
                        Pain, which ends `Goto Missile`)
    range    --
    mirrored yes   (salvo 2 is salvo 1's bands negated; the last wave also
                    swaps barrel +32 -> -32)
    inherit  RS_FatAbysswave at zscript/monsters/fatso/RS_FatsoFX.zs:316.
             Does not inherit.
    profile  MakeVolley(proj:"RS_FatAbysswave", count:5, arc:22,
                        fireSnd:"fatso/attack", pitchJitter:0)
             // one salvo. The attack is two, mirrored, 9 tics apart.
    notes    The per-frame in-flight A_Explode is DELIBERATE (MEMORY.md).
             Spawn HEIGHT being a roll -- random(16,42) -- is unusual in this
             family and makes the salvo vertically ragged as well as wide.

---

# TIER 10 -- RS_BlackFatso2 ("The thing from the swamp")

Choosers, none of them rows:
`Missile :1983` -> `A_JumpIfHealthLower(5500,"Phase2")`; `A_JumpIfCloser(500,"Breath")`;
else `A_Jump(256,"BigBombs","Weave1","Weave2","LongRange")`.
`Phase2 :1989` -> `A_SetSpeed(21)`; `A_JumpIfCloser(500,"Breath")`;
else `A_Jump(256,"GroundSplashes","BiggerBomb","Weave1","LongRange")`.

    ATTACK   RS_BlackFatso2.LongRange
    file     zscript/monsters/fatso/RS_Fatso.zs:1998
    shape    BURST
    payload  RS_BlackFatShotLongRange x3 per cycle
    arc      shot 1 exactly 0; shots 2 and 3
             randompick(-3,3,1,-1,0,-5,5) -- a SEVEN-VALUE DISCRETE PICK, not
             a range. Spawn height 56.
    timing   12 tics of A_FaceTarget, shot 1 (hold 8), 6 tics re-aim, shots 2
             and 3 three tics apart, then 2 tics and an 83% re-loop
             (`A_Jump(212,"LongRange")`). Sustained fire, ~31 tics per cycle.
    damage   DamageFunction (random(20,80))
    type     Fire
    sound    -- for the attack; "fatso/attack" per shot (SeeSound)
    impact   `MISL B 4 A_Explode(random(20,80),128)` -- one explosion,
             self-harming -- then 5 x RS_BlackFatSplash thrown BACKWARD
             (`angle*-1 + random(-15,15)`) at -12 offset with velocity
             random(3,21) and lift random(1,9). DeathSound "fatso/shotx".
             In flight it sheds RS_Trail11 every 4 tics.
             RS_BlackFatSplash: Damage 2 + PoisonDamage 12 (Poison), Hexen
             bounce x7, and on EVERY bounce it thrusts itself at a
             pseudo-random angle and drops an RS_Gas14 cloud. Death drops
             another RS_Gas14 at random(+/-120). A lingering poison field.
    trigger  Missile
    range    1000..   (`A_JumpIfCloser(1000,"Missile")` aborts and re-rolls)
    mirrored no
    inherit  RS_BlackFatShotLongRange :730, RS_BlackFatSplash :975 --
             zscript/monsters/fatso/RS_FatsoFX.zs. Neither inherits.
    profile  MakeBurst(proj:"RS_BlackFatShotLongRange", count:3, delayTics:6,
                       arc:10); p.MinRange = 1000
    notes    The randompick set is NOT symmetric-uniform: -3,3,1,-1,0,-5,5 --
             0 appears once, +/-1 once each, +/-3 once each, +/-5 once each.
             Recorded literally because an even 7-step fan is a different gun.

    ATTACK   RS_BlackFatso2.GroundSplashes
    file     zscript/monsters/fatso/RS_Fatso.zs:2006
    shape    SCATTER
    payload  RS_ShadowSplash x4
    arc      random(-60,60) per shot -- a 120-DEGREE cone, by far the widest
             non-boss spread here. Spawn height 12 (low, at the floor).
    timing   12 tics of a sound cue, 12 tics of A_FaceTarget, then four
             crawlers on CONSECUTIVE TICS (t=0,1,2,3), then 6 tics and a 34%
             jump to Weave1.
    damage   -- (RS_ShadowSplash sets no Damage property -> Damage 0 on
                 contact. All of its damage is A_Explode, below.)
    type     Plasma
    sound    "shadowbeast/sight" as the wind-up cue; "Fire/fire3" per crawler
             (SeeSound)
    impact   A WANDERING GROUND MINE. +FLOORHUGGER +THRUACTORS +BOUNCEONWALLS,
             BounceType Doom, BounceCount 999, WallBounceFactor 1.25.
             Spawn LOOPS: `BDP2 EE 1 A_Wander` then
             `BDP2 FG 1 A_Explode(random(10,35),128)` -- two explosions
             (self-harming, radius 128) every 4 tics, FOREVER, with a 2.3%
             chance per loop to detonate.
             Death: A_SetScale(1.8) then
             `BDP2 GHH 4 A_Explode(random(10,80),252)` -- three explosions at
             radius 252. DeathSound "shadowbeast/pr1death".
    trigger  Missile   (Phase2 only, i.e. health < 5500)
    range    ..2000 effectively (Phase2 is entered from Missile; the 500 gate
             sends it to Breath first)
    mirrored no
    inherit  RS_ShadowSplash at zscript/monsters/fatso/RS_FatsoFX.zs:760.
             Does not inherit.
    profile  MakeBurst(proj:"RS_ShadowSplash", count:4, delayTics:1, arc:120,
                       fireSnd:"Fire/fire3")
    notes    UNBOUNDED AoE BY DESIGN, and the reason CLAUDE.md's `RS_ZapFFAT2`
             warning exists in a nearby class. This one IS a legitimate
             looping A_Explode -- BounceCount 999 plus a 6/256 per-loop
             self-kill means it terminates statistically, and CH wrote it that
             way. Verified identical to CH. Do not "fix" it.
             The third frame is `H` twice (`BDP2 GHH`): CH wrote `BDP2 GHI`
             and no BDP2 `I` lump exists anywhere. Held H, the final and
             largest blast frame, for I's 4 tics. Three frames, 12 tics, three
             A_Explode calls -- all unchanged. Documented at the site.

    ATTACK   RS_BlackFatso2.BiggerBomb
    file     zscript/monsters/fatso/RS_Fatso.zs:2012
    shape    SINGLE
    payload  RS_ShadowBombBig x1
    arc      --   (angle exactly 0, spawn height 56)
    timing   12 tics of A_FaceTarget, one shot, 8 tics, sight check, 2 tics,
             then a 68% chain into BigBombs (`A_Jump(174,"BigBombs")`); the
             other 32% falls through into BigBombs anyway (no Goto), so
             BigBombs ALWAYS follows.
    damage   DamageFunction (random(20,90))
    type     Plasma
    sound    "shadowbeast/pr1sight" (SeeSound, +SPAWNSOUNDSOURCE)
    impact   See the RS_ShadowBombBig secondary row below -- it damages
             continuously in flight and sprays a second projectile class.
             Death: `BDP2 DE 4 A_Explode(random(10,40),162)` x2 then
             `BDP2 FGH 3 A_Explode(random(10,30),128)` x3 -- FIVE explosions,
             all self-harming. DeathSound "shadowbeast/pr1death".
             Speed 8, Scale 1.8. Slow and huge.
    trigger  Missile   (Phase2 only)
    range    --
    mirrored no
    inherit  RS_ShadowBombBig at zscript/monsters/fatso/RS_FatsoFX.zs:837.
             Does not inherit.
    profile  MakeHeavy(proj:"RS_ShadowBombBig", fireSnd:"shadowbeast/pr1sight",
                       spawnHeight:56)
    notes    The 32% "miss" on A_Jump(174) is a no-op -- BigBombs is the next
             state either way. Recording it because it looks like a branch and
             is not.

    ATTACK   RS_BlackFatso2.BigBombs
    file     zscript/monsters/fatso/RS_Fatso.zs:2018
    shape    SCATTER
    payload  RS_ShadowBeast_Ball1 x10
    arc      the ONLY attack in this monster with fixed angles in it:
             t=0  -> -8 and +8 SIMULTANEOUSLY (two 0-tic states)
             t=6  -> 0
             t=15 -> random(-14,-7), random(-14,-7), random(7,14)  (one tic)
             t=20 -> random(7,14), random(-26,26) x3               (one tic)
             Spawn height 56 throughout. Union -26..+26.
    timing   6 tics A_FaceTarget, shots at t=0,0,6, sight check, 8 tics re-aim,
             three at t=15, four at t=20.
    damage   DamageFunction (random(20,50))
    type     Poison
    sound    "shadowbeast/pr1sight" per ball (SeeSound, +SPAWNSOUNDSOURCE)
    impact   `BDP2 DE 4 A_Explode(random(10,40),102)` x2 then
             `BDP2 FGH 3 A_Explode(random(10,30),88)` x3 -- five explosions,
             all self-harming. DeathSound "shadowbeast/pr1death".
             Speed 15, Radius 10. No trail, no seek -- a plain heavy ball.
    trigger  Missile   (both phases)
    range    --
    mirrored no
    inherit  RS_ShadowBeast_Ball1 at zscript/monsters/fatso/RS_FatsoFX.zs:1122.
             Does not inherit.
    profile  MakeBurst(proj:"RS_ShadowBeast_Ball1", count:10, delayTics:5,
                       arc:52, fireSnd:"shadowbeast/pr1sight")
    notes    Structure is: a tight aimed opener (-8/0/+8) that hands off to a
             widening panic spray. Worth keeping as two profile entries in a
             rotation rather than one arc.

    ATTACK   RS_BlackFatso2.Weave1
    file     zscript/monsters/fatso/RS_Fatso.zs:2035
    shape    FAN
    payload  RS_ShadowBeast_Ball2 x6
    arc      -16, -8, 0, +8, +16, +32   -- FIXED 8-DEGREE STEPS, then a
             DOUBLE step to +32 at the end. Asymmetric on purpose.
             Spawn height 56.
    timing   4 tics of A_FaceTarget, then one ball every 4 tics with an
             A_FaceTarget BETWEEN EVERY SHOT. 24 tics total. 50% chain into
             Weave2 at the end.
    damage   DamageFunction (random(10,45))
    type     Plasma
    sound    "shadowbeast/pr2sight" per ball (SeeSound)
    impact   `BDP1 FGHI 3` -- four frames, twelve tics, NO A_Explode. This
             projectile does contact damage only. DeathSound
             "shadowbeast/pr2death". Decal "PlasmaScorchLower".
             In flight: `BDP1 DE 1 A_BishopMissileWeave` on a 2-tic loop --
             it snakes hard the whole way.
    trigger  Missile   (both phases)
    range    --
    mirrored no
    inherit  RS_ShadowBeast_Ball2 at zscript/monsters/fatso/RS_FatsoFX.zs:1150.
             Does not inherit.
    profile  MakeBurst(proj:"RS_ShadowBeast_Ball2", count:6, delayTics:4,
                       arc:48, fireSnd:"shadowbeast/pr2sight")
             // arc 48 = the -16..+32 span. An even 6-step fan across 48 puts
             // the shots at -16,-6.4,3.2,12.8,22.4,32 -- NOT CH's list.
             // CH's list is above; the factory cannot express the double step.
    notes    THE A_FACETARGET BETWEEN EVERY SHOT IS THE ATTACK. The fan is not
             fired from one facing -- it re-aims six times, so a moving target
             gets a SWEEPING fan that tracks, not a static spread. Any profile
             that fires all six off one aim is a different attack.

    ATTACK   RS_BlackFatso2.Breath
    file     zscript/monsters/fatso/RS_Fatso.zs:2058
    shape    BURST
    payload  RS_ShadowBeast_BallFire x13
    arc      random(-8,8) on ALL THIRTEEN -- uniform, no widening.
             (Contrast the EX's Breath, which ramps. See the EX section.)
             Spawn height 56.
    timing   6 tics of A_FaceTarget, then thirteen shots exactly 2 tics apart
             -- 26 tics of continuous stream. 50% chain into Weave1.
    damage   Damage 3   (bare constant; +RIPPER, so it hits repeatedly as it
                         passes through)
    type     Poison
    sound    "shadowbeast/pr1death" per shot (SeeSound -- CH uses the DEATH
             sound as the spawn sound here; CH-faithful)
    impact   `BDP2 DEFGH 5 Bright A_Explode(random(5,20),26)` -- FIVE frames,
             FIVE explosions, radius 26, self-harming, then Death is a bare
             TNT1. +RIPPER +THRUACTORS, Speed 15, Decal "MummyScorch".
             A ripping flamethrower tick, not a bolt.
    trigger  Missile
    range    ..500   (`A_JumpIfCloser(500,"Breath")` in both Missile and
                      Phase2 -- this is the panic-close attack)
    mirrored no
    inherit  RS_ShadowBeast_BallFire at
             zscript/monsters/fatso/RS_FatsoFX.zs:1021. Does not inherit.
    profile  MakeBurst(proj:"RS_ShadowBeast_BallFire", count:13, delayTics:2,
                       arc:16, fireSnd:"shadowbeast/pr1death")
    notes    The five-frame A_Explode is DELIBERATE lingering fire (MEMORY.md).
             13 shots x 5 explosions = 65 radius-26 blasts per breath.

    ATTACK   RS_BlackFatso2.Weave2
    file     zscript/monsters/fatso/RS_Fatso.zs:2076
    shape    FAN
    payload  RS_ShadowBeast_Ball3 x17
    arc      -64, +64, -56, +56, -48, +48, -40, +40, -32, +32, -24, +24,
             -16, +16, -8, +8, 0
             = a PERFECT 128-DEGREE FAN AT AN 8-DEGREE STEP, fired
             outside-in in mirrored pairs, with the centre shot last.
             Spawn height 56.
    timing   16 tics of A_FaceTarget, then ALL SEVENTEEN ON ONE TIC (sixteen
             0-tic states plus a 6-tic final). Then 25% chain to BigBombs.
    damage   DamageFunction (random(20,60))
    type     Plasma
    sound    "shadowbeast/pr2sight" x17 (SeeSound, one per ball)
    impact   `BDP1 FGHI 3` -- four frames, no A_Explode. Contact damage only.
             DeathSound "shadowbeast/pr2death". Decal "PlasmaScorchLower".
             In flight: alternating A_SetTranslucent(0.55/0.7/0.3) with
             A_BishopMissileWeave -- each of the seventeen snakes
             independently, so the wall does not stay a wall.
             Scale 1.4, Speed 20.
    trigger  Missile
    range    --
    mirrored yes   (the list IS mirrored pairs, fired outside-in)
    inherit  RS_ShadowBeast_Ball3 at zscript/monsters/fatso/RS_FatsoFX.zs:1178.
             Does not inherit.
    profile  MakeVolley(proj:"RS_ShadowBeast_Ball3", count:17, arc:128,
                        fireSnd:"shadowbeast/pr2sight")
             // exact: 17 across 128 degrees IS an 8-degree step. This one
             // maps to the factory with no loss.
    notes    THE CLEANEST FAN IN THE WHOLE FAMILY and the best parts-bin
             candidate in it -- 17/128/8 is exactly what MakeVolley expresses.
             `BDP1 D` at :1200 is CH's `BDPI` typo (no BDPI lump ships in CH
             either); invisible there too, kept as BDP1 so no unresolvable
             token remains. Documented at the site.

NOT A ROW: `RS_BlackFatso2.Burp` (`:2050`) fires nothing -- three A_Pain
frames, a face-target and two idle Bright frames -- and then FALLS THROUGH
into Breath. It is a wind-up. **It is also unreachable: nothing in this
class jumps to "Burp".** Verified in CH (`Fatsos.txt` BlackFatso2 block,
Missile lists BigBombs/Weave1/Weave2/LongRange and Phase2 lists
GroundSplashes/BiggerBomb/Weave1/LongRange -- neither names Burp). CH-faithful
dead code, not an import defect.

---

# TIER 10 -- RS_BlackFatsoEX ("The thing from the bog")

Same skeleton as the swamp thing with EX payloads. Choosers:
`Missile :1748` -> Phase2 if health < 5500; Breath if < 500; Choose if < 2000;
else BiggerBomb.
`Choose :1755` -> `A_Jump(256,"BigBombs","Weave1","Weave2")`.
`Phase2 :1758` -> `A_SetSpeed(21)`; Breath if < 500; Choose2 if < 2000;
else BiggerBomb.
`Choose2 :1774` -> `A_Jump(256,"GroundSplashes","BiggerBomb","Weave1","Burp")`.

Rows that are IDENTICAL in shape/arc/timing to the swamp thing's and differ
only in payload class are given in short form; the full geometry is in the
BlackFatso2 section above.

    ATTACK   RS_BlackFatsoEX.LongRange
    file     zscript/monsters/fatso/RS_Fatso.zs:1768
    shape    BURST
    payload  RS_BlackFatShotLongRange x3 per cycle   (same class as the swamp
                                                      thing -- not an EX variant)
    arc      0, then randompick(-3,3,1,-1,0,-5,5) x2
    timing   12, [shot] 8, 6, [shot] 3, [shot] 3, 2, 83% re-loop
    damage   DamageFunction (random(20,80))
    type     Fire
    sound    -- ; "fatso/attack" per shot
    impact   as RS_BlackFatso2.LongRange above (5 x RS_BlackFatSplash poison)
    trigger  Missile
    range    1000..
    mirrored no
    inherit  RS_BlackFatShotLongRange, RS_FatsoFX.zs:730
    profile  MakeBurst(proj:"RS_BlackFatShotLongRange", count:3, delayTics:6,
                       arc:10); p.MinRange = 1000
    notes    **UNREACHABLE IN THIS CLASS.** Neither Missile, Choose, Phase2 nor
             Choose2 names "LongRange"; the only jump to it is its own 83%
             self-loop at `:1772`. Confirmed identical in CH: the EX block's
             Missile jumps to BiggerBomb and Choose/Choose2 list
             BigBombs/Weave1/Weave2 and GroundSplashes/BiggerBomb/Weave1/burp.
             CH-faithful dead code, NOT an import defect. Row kept because the
             attack is fully specified and is a valid parts-bin entry.

    ATTACK   RS_BlackFatsoEX.GroundSplashes
    file     zscript/monsters/fatso/RS_Fatso.zs:1781
    shape    SCATTER
    payload  RS_ShadowSplash x4
    arc      random(-60,60) per shot, 120-degree cone, spawn height 12
    timing   12 (sound cue) + 12 (face) then four on consecutive tics
             (t=0,1,2,3), 6 tics, 34% jump to Weave1
    damage   -- (Damage 0 on contact; all damage is A_Explode)
    type     Plasma
    sound    "shadowbeast/sight" cue; "Fire/fire3" per crawler
    impact   as RS_BlackFatso2.GroundSplashes -- the looping wandering mine,
             two radius-128 explosions every 4 tics, then three radius-252
    trigger  Missile   (Choose2, so Phase2 only)
    range    ..2000
    mirrored no
    inherit  RS_ShadowSplash, RS_FatsoFX.zs:760
    profile  MakeBurst(proj:"RS_ShadowSplash", count:4, delayTics:1, arc:120,
                       fireSnd:"Fire/fire3")
    notes    Byte-identical state chain to the swamp thing's.

    ATTACK   RS_BlackFatsoEX.BiggerBomb
    file     zscript/monsters/fatso/RS_Fatso.zs:1787
    shape    SINGLE
    payload  RS_ShadowBombBigEX x1
    arc      --   (angle exactly 0, spawn height 56)
    timing   12 tics face, one shot, 8 tics, sight check, 2 tics, then
             BigBombs always follows
    damage   DamageFunction (random(50,200))   -- the heaviest single
             projectile in the family bar the White boss's nuke
    type     Plasma
    sound    "shadowbeast/pr1sight" (+SPAWNSOUNDSOURCE)
    impact   See the RS_ShadowBombBigEX secondary row below. Summary: it is a
             +SEEKERMISSILE that pulses A_Explode(random(40,60),128) EVERY TIC
             of flight and sheds 4 ripper fireballs every 3 tics, then dies
             into five radius-258 explosions and 108 more ripper fireballs.
             XScale 2.55, YScale 1.75. DeathSound "shadowbeast/pr1death".
    trigger  Missile   (the DEFAULT at 2000+, and a Choose2 option)
    range    --
    mirrored no
    inherit  RS_ShadowBombBigEX at zscript/monsters/fatso/RS_FatsoFX.zs:798.
             Does not inherit.
    profile  MakeHeavy(proj:"RS_ShadowBombBigEX", fireSnd:"shadowbeast/pr1sight",
                       spawnHeight:56)
    notes    THE SINGLE MOST DANGEROUS PROJECTILE IN THE FAMILY. Everything
             about it is in the projectile, not the firing state -- which is
             exactly what makes it a good weapon part: MakeHeavy and the
             projectile carries its own arrival.

    ATTACK   RS_BlackFatsoEX.BigBombs
    file     zscript/monsters/fatso/RS_Fatso.zs:1793
    shape    SCATTER
    payload  RS_ShadowBeast_Ballex1 x10
    arc      t=0 -> -8 and +8 simultaneously; t=6 -> 0;
             t=15 -> random(-14,-7), random(-14,-7), random(7,14);
             t=20 -> random(7,14), random(-26,26) x3. Spawn height 56.
    timing   6 face, t=0,0,6, sight check, 8 re-aim, three at t=15, four at t=20
    damage   DamageFunction (random(20,50))
    type     Poison
    sound    "shadowbeast/pr1sight" per ball
    impact   `BDP2 DE 4 A_Explode(random(10,40),102)` x2, then FIVE
             RS_BlackFatSplash at random(-359,359), then
             `BDP2 FGH 3 A_Explode(random(10,30),88)` x3. Five explosions plus
             a poison-blob spray -- the EX ball's only difference from
             RS_ShadowBeast_Ball1 is that splash burst.
             DeathSound "shadowbeast/pr1death".
    trigger  Missile   (Choose, both phases)
    range    ..2000
    mirrored no
    inherit  RS_ShadowBeast_Ballex1 at zscript/monsters/fatso/RS_FatsoFX.zs:946.
             Does not inherit -- it is a sibling of RS_ShadowBeast_Ball1, not a
             subclass. Identical Default block; the ONLY difference is the
             5 x RS_BlackFatSplash line in Death.
    profile  MakeBurst(proj:"RS_ShadowBeast_Ballex1", count:10, delayTics:5,
                       arc:52, fireSnd:"shadowbeast/pr1sight")
    notes    --

    ATTACK   RS_BlackFatsoEX.Weave1
    file     zscript/monsters/fatso/RS_Fatso.zs:1810
    shape    FAN
    payload  RS_ShadowBeast_BallEx2 x6
    arc      -16, -8, 0, +8, +16, +32   (fixed 8-degree steps, double step at
                                         the end). Spawn height 56.
    timing   4 face, then one ball every 4 tics with A_FaceTarget BETWEEN
             EVERY SHOT -- a tracking sweep, 24 tics. 50% chain to Weave2.
    damage   DamageFunction (random(16,60))
    type     Plasma
    sound    "shadowbeast/pr2sight" per ball
    impact   `BDP1 FGHI 3 A_Explode(random(10,30),64,0)` -- FOUR frames, FOUR
             explosions, radius 64, NOT self-harming. (The swamp thing's
             Ball2 has no A_Explode at all -- this is the EX upgrade.)
             DeathSound "shadowbeast/pr2death". Decal "PlasmaScorchLower".
             In flight: sheds RS_ShadowBeast_BallFire (a live RIPPER, Damage 3
             Poison) every tic at random(0,-24) offset, and has an 8/256
             per-2-tics chance to THRUST ITSELF sideways
             (`ThrustThing(angle*256/random(1,360),12,0,0)`) -- it jinks.
             Scale 2.5, Radius 16 -- big.
    trigger  Missile   (Choose and Choose2, both phases)
    range    ..2000
    mirrored no
    inherit  RS_ShadowBeast_BallEx2 at zscript/monsters/fatso/RS_FatsoFX.zs:1050.
             Sibling of RS_ShadowBeast_Ball2, not a subclass.
    profile  MakeBurst(proj:"RS_ShadowBeast_BallEx2", count:6, delayTics:4,
                       arc:48, fireSnd:"shadowbeast/pr2sight")
             // even 6-across-48 gives -16,-6.4,3.2,12.8,22.4,32; CH's list is
             // -16,-8,0,8,16,32. Not the same fan. Recorded, not rounded.
    notes    The tracking re-aim between shots is the identity here, as on the
             swamp thing. Note that this projectile SPAWNS ANOTHER DAMAGING
             CLASS in flight -- a weapon wearing it inherits a fire trail.

    ATTACK   RS_BlackFatsoEX.Burp
    file     zscript/monsters/fatso/RS_Fatso.zs:1829
    shape    SCATTER
    payload  RS_BlackFatsoBurp x9
    arc      random(-30,30) per shot -- a 60-degree cone. Spawn height 56.
    timing   12 tics of A_Pain frames (a visible heave), 12 tics of
             A_FaceTarget, 2 tics, then NINE crawlers exactly 3 tics apart,
             then 12 tics recovery.
    damage   -- (RS_BlackFatsoBurp sets no Damage property -> Damage 0 on
                 contact; all of its damage is A_Explode)
    type     Plasma
    sound    "Fire/fire3" per crawler (SeeSound)
    impact   AN AIRBORNE BOMB THAT BECOMES A GROUND CRAWLER. Fly is
             `BDP2 EEFGH 3` (15 tics airborne, +NOGRAVITY) and then it
             flips its own flags -- `bNOGRAVITY = false`, `bFLOORHUGGER = true`
             -- and enters Crawl.
             Crawl LOOPS: 2 x RS_BlackFatSplash (poison blobs, alpha 232) then
             `BDP2 FG 1 A_Explode(random(10,35),128)` x2, self-harming, with a
             2.3% per-loop self-detonate.
             Death: A_SetScale(1.8), then TWENTY-FOUR RS_BlackFatSplash at
             random(-359,359), then `BDP2 GHH 4 A_Explode(random(10,80),252)`
             x3. DeathSound "shadowbeast/pr1death".
             BounceType Doom, BounceCount 999, WallBounceFactor 1.25.
    trigger  Missile   (Choose2, so Phase2 only -- health < 5500)
    range    ..2000
    mirrored no
    inherit  RS_BlackFatsoBurp at zscript/monsters/fatso/RS_FatsoFX.zs:901.
             Does not inherit.
    profile  MakeBurst(proj:"RS_BlackFatsoBurp", count:9, delayTics:3, arc:60,
                       fireSnd:"Fire/fire3")
    notes    THE EX'S BURP IS A REAL ATTACK; the swamp thing's identically
             named state is an unreachable wind-up that fires nothing. Do not
             conflate them.
             The third Death frame is `H` twice (`BDP2 GHH`) -- same CH `BDP2 I`
             absence as RS_ShadowSplash; held the largest frame. Documented at
             the site.
             9 crawlers x an indefinite Crawl loop x 24 splash blobs each on
             death is the largest sustained-AoE attack in the family.

    ATTACK   RS_BlackFatsoEX.Breath
    file     zscript/monsters/fatso/RS_Fatso.zs:1835
    shape    SCATTER
    payload  RS_ShadowBeast_BallFireEX x13
    arc      A RAMP, not a uniform cone -- this is the EX's real difference
             from the swamp thing's Breath:
             random(-8,8), random(-8,8), random(-8,8),
             random(-12,12), random(-12,12),
             random(-15,15),
             random(-25,25),          <-- the peak, shot 7
             random(-15,15),
             random(-12,12), random(-12,12),
             random(-8,8), random(-8,8), random(-8,8)
             The cone OPENS to +/-25 mid-breath and CLOSES again. Spawn
             height 56.
    timing   6 tics of A_FaceTarget, then thirteen shots exactly 2 tics apart
             (26 tics). 50% chain into Weave1.
    damage   Damage 3   (bare constant; +RIPPER)
    type     Poison
    sound    "shadowbeast/pr1death" per shot (SeeSound)
    impact   `BDP2 DEF 5 A_Explode(random(5,20),32)` -- three frames, three
             explosions -- then Death adds A_SetScale(1.25) +
             `BDP2 G 5 A_Explode(random(5,20),46)` and A_SetScale(1.5) +
             `BDP2 H 5 A_Explode(random(5,20),64)`, then TWO
             RS_BlackFatSplash. SIX explosions of GROWING RADIUS
             (32 -> 46 -> 64) per ripper tick, all self-harming.
             +RIPPER +THRUACTORS, Speed 20, Decal "MummyScorch".
    trigger  Missile
    range    ..500
    mirrored no
    inherit  RS_ShadowBeast_BallFireEX at
             zscript/monsters/fatso/RS_FatsoFX.zs:868. Sibling of
             RS_ShadowBeast_BallFire, not a subclass. Differences: Speed
             20 vs 15, and the growing-radius Death chain above (the non-EX
             Death is a bare TNT1).
    profile  MakeBurst(proj:"RS_ShadowBeast_BallFireEX", count:13, delayTics:2,
                       arc:16, fireSnd:"shadowbeast/pr1death")
             // arc 16 is only the FIRST and LAST band. The ramp to 50 in the
             // middle has no form in the factory. Recorded, not averaged.
    notes    THE RAMP IS THE ATTACK. A uniform +/-8 breath and a breath that
             flares to +/-25 at shot 7 play completely differently -- the flare
             is what catches a strafing player. Anything that averages this to
             a single arc has thrown away the whole design.

    ATTACK   RS_BlackFatsoEX.Weave2
    file     zscript/monsters/fatso/RS_Fatso.zs:1853
    shape    FAN
    payload  RS_ShadowBeast_Ballex3 x17
    arc      -64, +64, -56, +56, -48, +48, -40, +40, -32, +32, -24, +24,
             -16, +16, -8, +8, 0
             = 128 degrees, 8-degree step, outside-in mirrored pairs, centre
             last. Spawn height 56.
    timing   16 tics of A_FaceTarget, then ALL SEVENTEEN ON ONE TIC. Then
             25% -> BigBombs, else 50% -> Weave1.
    damage   DamageFunction (random(20,60))
    type     Plasma
    sound    "shadowbeast/pr2sight" x17
    impact   `BDP1 FGHI 3` -- no A_Explode. Contact damage only.
             DeathSound "shadowbeast/pr2death". Decal "PlasmaScorchLower".
             In flight: +SEEKERMISSILE with `A_SeekerMissile(30,30)` once per
             loop PLUS A_BishopMissileWeave -- seventeen HOMING snakes.
             Scale 2.4, Speed 8 (slow, which is what makes seventeen homing
             projectiles survivable).
    trigger  Missile   (Choose, so full-health branch only)
    range    ..2000
    mirrored yes
    inherit  RS_ShadowBeast_Ballex3 at zscript/monsters/fatso/RS_FatsoFX.zs:1084.
             Sibling of RS_ShadowBeast_Ball3. Differences: +SEEKERMISSILE and
             the A_SeekerMissile(30,30) call, Speed 8 vs 20, Scale 2.4 vs 1.4,
             Radius 12 vs 8.
    profile  MakeVolley(proj:"RS_ShadowBeast_Ballex3", count:17, arc:128,
                        fireSnd:"shadowbeast/pr2sight")
             // exact -- 17 across 128 IS an 8-degree step.
    notes    Same clean 17/128/8 geometry as the swamp thing's Weave2 but the
             projectile HOMES. That single flag turns an evadable wall into a
             room-clearer; it is the difference to price if this is worn.
             `BDP1 D` at :1109 is CH's `BDPI` typo, invisible in CH too.

---

# TIER 11 -- RS_WhiteFatso2 ("Angry Mama")

Choosers, none of them rows:
`Missile :2214` -> `A_JumpIfCloser(2000,"Choice1")`, else FALLS THROUGH into
QueenRail. So QueenRail is the beyond-2000 attack.
`Choice1 :2247` -> Zap if < 300; Choice2 if health < 9000;
else `A_Jump(255,"BallBarrage","GroundNuke","SpreadShot")`; the fall-through
tail (`QUEE S 8 A_FaceTarget; Goto See`) is the 1/256 no-op.
`Choice2 :2244` -> `A_Jump(255,"BallBarrage","GroundNuke","RapidRail","SpreadShot")`.

    ATTACK   RS_WhiteFatso2.QueenRail
    file     zscript/monsters/fatso/RS_Fatso.zs:2223
    shape    HITSCAN
    payload  -- (rail trace; puff RS_WhiteFatRB, trail spawn RS_WhiteFatRB2)
    arc      spread_xy 0, spread_z 0 -- PERFECTLY ACCURATE, and aim = 1
             (auto-aimed at the target)
    timing   3 + 3 (telegraph sound) + 45 (QUEE EFEFG x9) + 9 = 60 TICS OF
             WIND-UP, then the shot on one tic, then 3 tics. The 1.7-second
             tell is the whole counterplay.
    damage   A_CustomRailgun(random(40,90), 0, "white", "white",
                             RGF_NOPIERCING, 1, 0, "RS_WhiteFatRB",
                             0, 0, 0, 0, 0.4, 1.0, "RS_WhiteFatRB2", 0)
             -> rail damage random(40,90). Plus the puff and the trail spawns,
             which carry their own damage -- see impact.
    type     -- for the rail itself; RS_WhiteFatRB and RS_WhiteFatRB2 are both
             Plasma
    sound    "WFATATTACK" at volume 2, ATTN_NONE (map-wide -- the telegraph),
             then "WFATCRIT" at volume 2, ATTN_NONE immediately before firing.
             Both on channel 7.
    impact   RS_WhiteFatRB (the puff, +ALWAYSPUFF so it always appears):
             DamageFunction (random(30,95)) Plasma, Scale 2.25, and its Death
             runs A_Scream, `BFE1 C 8 A_Explode(random(50,125),252)` --
             radius 252, self-harming -- plus `Radius_Quake(15,15,0,40,0)`.
             DeathSound "NETHERDE".
             RS_WhiteFatRB2 (spawned along the beam at sparsity 0.4, i.e.
             densely): DamageFunction (random(30,50)) Plasma, Speed 11,
             Scale 2, and Death runs A_Explode(random(15,30),128) TWICE.
             So the beam is a corridor of explosions, not a line.
    trigger  Missile   (the fall-through when the target is NOT closer than 2000)
    range    2000..
    mirrored no
    inherit  RS_WhiteFatRB :1468, RS_WhiteFatRB2 :1564 --
             zscript/monsters/fatso/RS_FatsoFX.zs. Neither inherits.
    profile  MakeHitscan(fireSnd:"WFATATTACK", spreadScale:0.0,
                         impactPuff:"RS_WhiteFatRB"); p.MinRange = 2000
             // the RS_WhiteFatRB2 trail spawn has no factory slot on a
             // hitscan profile (Trail is bullet-mode only, RS_AttackProfile
             // header). Recorded, not silently dropped.
    notes    RGF_NOPIERCING means it stops at the first thing it hits, so the
             corridor of RS_WhiteFatRB2 ends there too.

    ATTACK   RS_WhiteFatso2.RapidRail
    file     zscript/monsters/fatso/RS_Fatso.zs:2232
    shape    HITSCAN
    payload  -- (rail trace x3; puff RS_WhiteFatRB3, trail RS_WhiteFatRB4)
    arc      spread_xy 0, spread_z 0, BUT **aim = 0** -- NOT auto-aimed. It
             fires along the boss's facing, so A_FaceTarget in the preceding
             frame is the entire aim. A strafing target is missed.
    timing   3 + 3 + 15 (QUEE EFEFG x3) + 14, shot 1 (5 tics), 3, 14, shot 2
             (5), 3, 14, shot 3 (5), 6, 6. Three rails, ~22 tics apart, each
             preceded by its own A_FaceTarget and its own sound cue.
    damage   A_CustomRailgun(random(20,40), 0, "white", "white",
                             RGF_NOPIERCING, 0, 0, "RS_WhiteFatRB3",
                             0, 0, 0, 0, 0.4, 1.0, "RS_WhiteFatRB4", 4)
             -> rail damage random(20,40) each, spawn offset z 4.
    type     -- for the rail; RS_WhiteFatRB3 and RS_WhiteFatRB4 are Plasma
    sound    "WFATCRIT", then "WFATATTACK" before rails 1 and 2, "WFATCRIT"
             before rail 3. Default channel and attenuation (NOT the map-wide
             ATTN_NONE that QueenRail uses).
    impact   RS_WhiteFatRB3: DamageFunction (random(30,95)) Plasma, Scale 1.33,
             Death = `BFE1 C 8 A_Explode(random(30,95),128)` +
             `Radius_Quake(9,9,0,30,0)`. DeathSound "NETHERDE".
             RS_WhiteFatRB4: DamageFunction (random(15,30)) Plasma, Speed 11,
             Scale 1.33, a 12-tic scale-pulse Fly, then
             A_Explode(random(10,20),88) TWICE on Death.
             Half the scale and roughly half the blast of the QueenRail set.
    trigger  Missile   (Choice2 only)
    range    ..2000, and only below 9000 health, and only at 300+
    mirrored no
    inherit  RS_WhiteFatRB3 :1499, RS_WhiteFatRB4 :1530 --
             zscript/monsters/fatso/RS_FatsoFX.zs. Neither inherits.
             NOTE: despite the numbering, RB3 is NOT a subclass of RB or RB2 --
             all four are independent Actors with near-duplicate bodies.
    profile  MakeBurst(proj:null, count:3, delayTics:22); // hitscan burst has
             // no factory form -- MakeHitscan is single-shot and MakeBurst is
             // projectile-only. Closest honest expression:
             // MakeHitscan(fireSnd:"WFATATTACK", spreadScale:0.0,
             //             impactPuff:"RS_WhiteFatRB3") x3 in an AttackSlot
             // rotation. Recorded as a gap, see UNRESOLVED U4.
    notes    THE PHASE-2 RAIL. Weaker per shot than QueenRail but three of
             them, and it is the only attack the boss gains on dropping below
             9000 health.

    ATTACK   RS_WhiteFatso2.SpreadShot
    file     zscript/monsters/fatso/RS_Fatso.zs:2258
    shape    SALVO
    payload  RS_WhiteFatScatter x27
    arc      random(-28,28) horizontal AND random(-10,10) vertical, per
             projectile, with CMF_OFFSETPITCH|CMF_SAVEPITCH -- so the pitch is
             added to the aim pitch and the projectile KEEPS it. A true
             56 x 20 degree cone. Spawn height 42.
    timing   6 + 6 + 9 + 6 = 27 tics of wind-up, then ALL TWENTY-SEVEN ON ONE
             TIC, then 9 + 9 recovery. A literal shotgun blast.
    damage   DamageFunction (random(10,30))   per pellet
    type     Melee   (CH-faithful -- as with the Gray's spikes, this bypasses
                      most elemental resists)
    sound    "WFATATTACK" once as the tell; "ILLSHEAR" per pellet (SeeSound)
    impact   `BAL2 C 4 A_SetTranslucent(0.55); BAL2 D 1; BAL2 E 2` -- NO
             A_Explode. Contact damage only, which is why 27 of them is fair.
             DeathSound "spit/spit". XScale 0.77, YScale 0.33 -- flat shards.
             In flight it emits a white particle every 2 tics.
    trigger  Missile   (Choice1 and Choice2)
    range    300..2000
    mirrored no
    inherit  RS_WhiteFatScatter at zscript/monsters/fatso/RS_FatsoFX.zs:1276.
             Does not inherit.
    profile  MakeVolley(proj:"RS_WhiteFatScatter", count:27, arc:56,
                        fireSnd:"WFATATTACK", pitchJitter:20.0)
             // maps almost exactly; the only loss is that CH re-rolls per
             // pellet rather than stepping across the arc.
    notes    "ILLSHEAR" IS SILENT HALF THE TIME, IN CH TOO. CH
             SNDINFO.txt:439-441 declares `$random ILLSHEAR { ILLSHEA1
             ILLSHEA2 }` but ships only ILLSHEA1.ogg. Kept verbatim; this is a
             CH defect faithfully reproduced, not an import gap. The logical
             name DOES resolve in the repo SNDINFO (checked).
             BEST SHOTGUN CANDIDATE IN THE FAMILY -- one tic, no splash,
             pure pellet count, and the factory expresses it losslessly.

    ATTACK   RS_WhiteFatso2.GroundNuke
    file     zscript/monsters/fatso/RS_Fatso.zs:2268
    shape    RAIN
    payload  RS_WhiteFatMark x10   (+ RS_WhiteFatNukeShow x10, cosmetic)
             -> each Mark delivers one RS_WhiteFatNuke from above
    arc      --   NOT AIMED. The marks are placed by A_SpawnItemEx at
             random(-1524,1524) forward and random(-1524,1524) lateral,
             relative to the BOSS's facing, at z 6. A ~3000-unit box centred
             on the boss, ignoring where the target actually is.
    timing   3 + 3 + 10 (QUEE EFEFG x2) + 9 wind-up; then 10 cosmetic beams
             over 20 tics; then 10 marks over 20 tics; 10 tics recovery.
             THEN each mark runs its own ~93-tic telegraph before the nuke
             falls. Total time to first impact ~2.6 seconds after the marks
             land.
    damage   DamageFunction (random(100,200))   [RS_WhiteFatNuke, on contact]
             plus A_Explode(random(80,155),326) [on its death]
    type     Fire   [RS_WhiteFatNuke]
    sound    "WFATCRIT" as the wind-up, "WFATATTACK" as the marks go out.
             Then per mark: "Juggernaut/Attack" (its DeathSound, via A_Scream)
             when the circle starts drawing; "ARCAZAP7" when the nuke spawns
             (its SeeSound); "NETHERDE" on detonation.
    impact   THE MARK IS THE ATTACK -- see the RS_WhiteFatMark secondary row.
             Summary: A_Scream, six RS_CircleDrawMeteorCH* ring-drawers
             attached as children, ~93 tics of CHTA telegraph, then
             RS_WhiteFatNuke spawned at z random(128,256) with zvel -2 and
             -NOGRAVITY (it falls), then A_KillChildren clears the ring.
             The nuke: Mass 8000, XScale 1.2 YScale 2.6, Death =
             A_SetScale(2.5,0.15), A_Scream,
             `BFE1 C 8 A_Explode(random(80,155),326)` -- radius 326,
             self-harming -- plus `Radius_Quake(15,15,0,40,0)`.
             RS_WhiteFatNukeShow is +NOINTERACTION: pure theatre.
    trigger  Missile   (Choice1 and Choice2)
    range    300..2000   (to ENTER; the marks themselves land up to ~1524 out
                          in each axis regardless of where the target is)
    mirrored no
    inherit  RS_WhiteFatMark :1335, RS_WhiteFatNuke :1385,
             RS_WhiteFatNukeShow :1308 -- zscript/monsters/fatso/RS_FatsoFX.zs.
             None inherit. RS_CircleDrawMeteorCH..CH6 are shared, defined by
             an earlier family.
    profile  MakeVolley(proj:"RS_WhiteFatMark", count:10, arc:0)
             // the delay, the falling delivery and the ring telegraph all live
             // inside RS_WhiteFatMark, so a weapon wearing this gets the whole
             // mechanic for free. That is the point of RAIN as a shape.
    notes    THE SIGNATURE OF THE FAMILY. It is an AREA-DENIAL move, not an
             aimed attack: it does not care where the player is at cast time,
             only where they are ~2.6 seconds later. That plus the 326-radius
             blast is what makes it readable and survivable.

    ATTACK   RS_WhiteFatso2.BallBarrage
    file     zscript/monsters/fatso/RS_Fatso.zs:2283
    shape    BURST
    payload  RS_WhiteFatBall1 .. RS_WhiteFatBall7, ONE per iteration, class
             picked at random each time; the barrage repeats at ~91% so the
             expected length is ~11 balls
    arc      random(-5,5) per ball. Spawn height 46.
    timing   4 + 4 + 6 + 3 = 17 tics of wind-up, then 7 tics per ball
             (1 + 1 face + 3 fire + 1 sight check + 1 re-roll), looping at
             `A_Jump(232,...)` = 232/256 continue.
    damage   DamageFunction (random(20,50))   -- inherited by all seven
    type     Fire   -- inherited by all seven
    sound    "WFATATTACK" once at the start of the barrage;
             "imp/attack" per ball (inherited SeeSound)
    impact   `BAL2 C 4; BAL2 D 1 A_Explode(random(10,25),32,0); BAL2 E 2` --
             ONE explosion, radius 32, NOT self-harming.
             DeathSound "imp/shotx". ALL INHERITED by balls 2-7.
             In flight: +SEEKERMISSILE, and a coin-flip on spawn picks
             `A_Weave(2,0,2,0)` or `A_Weave(2,0,-2,0)` -- each ball snakes
             left or right at random while homing. Scale 1.5, +DONTHARMCLASS.
    trigger  Missile   (Choice1 and Choice2)
    range    300..2000
    mirrored yes   (per ball, via the A1/A2 weave coin-flip inside the
                    projectile -- not a state branch on the monster)
    inherit  **RS_WhiteFatBall2..7 : RS_WhiteFatBall1**, at
             zscript/monsters/fatso/RS_FatsoFX.zs:1461-1466 (CH :3951-3956).
             EACH SUBCLASS IS A ONE-LINE BODY THAT OVERRIDES **ONLY `Speed`**:
               RS_WhiteFatBall1  Speed 21   (the parent)
               RS_WhiteFatBall2  Speed 11
               RS_WhiteFatBall3  Speed 33
               RS_WhiteFatBall4  Speed 40
               RS_WhiteFatBall5  Speed 8
               RS_WhiteFatBall6  Speed 16
               RS_WhiteFatBall7  Speed 27
             Everything else -- damage roll, DamageType Fire, Scale 1.5,
             +SEEKERMISSILE, +DONTHARMCLASS, SeeSound, DeathSound, the weave
             coin-flip, the Death A_Explode -- is INHERITED and written
             nowhere near the firing state. Reading A1..A7 alone reports seven
             different projectiles; there is one, at seven speeds.
    profile  MakeBurst(proj:"RS_WhiteFatBall1", count:11, delayTics:7, arc:10,
                       fireSnd:"imp/attack")
             // the random SPEED per ball has no factory slot. That randomised
             // speed is the entire mechanic -- a stream of homing balls
             // arriving out of order. Recorded as a gap, see UNRESOLVED U5.
    notes    RANDOMISED PROJECTILE SPEED IS THE DESIGN. Speeds 8 to 40 is a
             5x range, so a later ball routinely overtakes an earlier one and
             the arrival pattern never repeats. Copying this as seven separate
             profile entries in an AttackSlot rotation reproduces it exactly.

    ATTACK   RS_WhiteFatso2.Zap7
    file     zscript/monsters/fatso/RS_Fatso.zs:2343
    shape    MULTI
    payload  RS_WhiteFatsoGroundZap x176  +  RS_WhiteFatsoAirZap x176
             (352 projectiles in one attack -- the largest in the family)
    arc      FULL 360, in two identical passes:
             PASS 1 (ground, spawn height 0, on ONE TIC):
               12 at FIXED 30-degree steps: 15, 45, 75, 105, 135, 165, 195,
               225, 255, 285, 315, 345
               then 4 x 41 = 164 at random(10,170), random(190,260),
               random(280,340), random(-50,50) -- four weighted arcs, 41 each
             PASS 2 (air, 3 x 3 tics later; spawn height 0 for the first and
               48 for the other eleven, 32 for the random ones):
               the SAME 12 fixed angles and the SAME four random arcs, 41 each
             The four random arcs are deliberately UNEVEN: 160 degrees behind
             (10..170), 70 degrees (190..260), 60 degrees (280..340) and 100
             degrees across the front (-50..50). Density is highest to the
             rear-left and across the player's likely position.
    timing   3 + 3 + 9 (QUEE EFG x3) wind-up; the entire ground pass on ONE
             TIC; 9 tics (QUEE EFG x3); the entire air pass on ONE TIC;
             6 tics recovery.
    damage   DamageFunction (random(10,30))   [RS_WhiteFatsoGroundZap]
             DamageFunction (random(1,2))     [RS_WhiteFatsoAirZap]
    type     Plasma (both)
    sound    "WFATATTACK" once on channel 0 as the tell; then "prieinfu" from
             EVERY ONE of the 352 zaps (NoDelay A_PlaySound on their first
             frame)
    impact   NEITHER ZAP HAS A SEPARATE Death -- `Spawn:` and `Death:` share
             the same label, so the whole actor IS its arrival.
             GroundZap: +FLOORHUGGER +THRUSPECIES +DONTHARMCLASS, Speed 18,
             Translation "Ice", Alpha 1.75, and
             `LITN ABCDEFGOPABCDEFGOPABCDEFGOP 2 A_Explode(random(2,9),64,0)`
             -- TWENTY-SEVEN frames, TWENTY-SEVEN explosions, radius 64, NOT
             self-harming, over 54 tics.
             AirZap: +SEEKERMISSILE +RIPPER +THRUSPECIES, Speed 17, and
             `LITN ABCDEFGOPABCDEFGOPABCDEFGOPABCDEFGOP 2 A_Weave(3,2,5,2)`
             -- 36 frames, NO A_Explode; it rips and weaves for 72 tics.
    trigger  Missile   (via Choice1's `A_JumpIfCloser(300,"Zap")`, then Zap's
                        own 50% coin -- `A_Jump(128,"Zap7")`)
    range    ..300
    mirrored no
    inherit  RS_WhiteFatsoGroundZap :1215, RS_WhiteFatsoAirZap :1245 --
             zscript/monsters/fatso/RS_FatsoFX.zs. Neither inherits.
    profile  MakeVolley(proj:"RS_WhiteFatsoGroundZap", count:176, arc:360)
             +
             MakeVolley(proj:"RS_WhiteFatsoAirZap", count:176, arc:360)
             // two entries, fired 9 tics apart. The uneven arc weighting has
             // no factory form; a flat 360 ring is the closest expression and
             // it is NOT the same attack. Recorded, not rounded.
    notes    MULTI, not RING, per the tie-break rule in the header: two
             damaging payload classes. The geometry IS a ring and is recorded
             above in full.
             THE OTHER HALF OF `Zap` IS A NO-OP: `Zap :2336` is
             `A_Jump(128,"Zap7"); Goto Choice1+3`, and Choice1+3 is
             `QUEE S 8 A_FaceTarget; Goto See`. So half the time the boss
             stands still for 8 tics instead. Offset arithmetic verified
             state-by-state.
             27 explosions x 176 ground zaps = up to 4,752 radius-64
             explosions from one attack. It is not self-harming and it is
             +DONTHARMCLASS, so it only hits the player.

---

# TIER 12 -- RS_CyanFatso2 ("Crystal Fatso")

Missile (`:452`) opens with `A_Jump(128,"Butt")` (50%), then
`A_Jump(102,"MissAlt")` (~40% of the remainder). Butt is a range gate, not a row.

    ATTACK   RS_CyanFatso2.Missile
    file     zscript/monsters/fatso/RS_Fatso.zs:457
    shape    SCATTER
    payload  RS_CyanFatBall x8   (four simultaneous pairs)
    arc      pair 1: -21 barrel random(-1,1), +21 barrel random(-1,1)
             pair 2: -21 random(-3,3), +21 random(-3,3)
             pair 3: -21 random(-3,3), +21 random(-3,3)
             pair 4: -21 random(-5,5), +21 random(-5,5)
             A WIDENING and ACCELERATING volley. Spawn height 18.
    timing   20 (A_FatRaise), then pairs at t=0 (hold 10), t=10 (hold 5),
             then 10 tics of A_FaceTarget + A_CheckSight, t=25 (hold 5),
             t=30 (hold 2), 15 tics recovery.
             Each pair IS simultaneous (0-tic state first).
    damage   DamageFunction (random(10,80))   -- the widest single roll in the
                                                 family
    type     Ice
    sound    "fatso/raiseguns"; "imp/attack" per ball (SeeSound)
    impact   See the RS_CyanFatBall.Death secondary row below -- it bursts into
             SEVEN live frost shards at random(0,359). Also plays A_Scream
             (DeathSound "Ice/Hit2") and throws 15 cyan particles.
             NO A_Explode -- all of the arrival damage is the shard burst.
             In flight: sheds RS_IceFattTrail every 2 tics with a
             pitch-corrected offset (`cos(pitch)*1 / -sin(pitch)*1`) so the
             trail follows the arc rather than the ground plane.
    trigger  Missile
    range    --
    mirrored no
    inherit  RS_CyanFatBall :210, RS_IceFattTrail :240 --
             zscript/monsters/fatso/RS_FatsoFX.zs. Neither inherits.
    profile  MakeBurst(proj:"RS_CyanFatBall", count:8, delayTics:8, arc:10,
                       fireSnd:"imp/attack")
    notes    The Cyan is the family's Ice specialist: DamageFactor "Ice" 0.1
             and PainChance "Ice" 0 on the monster, Ice on every projectile,
             and A_IceGuyDie in its Death.

    ATTACK   RS_CyanFatso2.MissAlt
    file     zscript/monsters/fatso/RS_Fatso.zs:471
    shape    SALVO
    payload  RS_CyanFatBall x6   (two salvos of three)
    arc      salvo 1 -- ALL THREE from the +21 barrel, on ONE tic:
                random(1,11), random(-1,1), random(-11,-1)
                = three non-overlapping bands covering -11..+11
             salvo 2 -- ALL THREE from the -21 barrel, on ONE tic, 8 tics
                later, bands REVERSED: random(-11,1), random(-1,1),
                random(1,11)
             Spawn height 18.
    timing   5 tics of A_FaceTarget, three balls on tic 0 (hold 8), three
             balls on tic 8 (hold 8).
    damage   DamageFunction (random(10,80))
    type     Ice
    sound    "imp/attack" per ball
    impact   as RS_CyanFatso2.Missile above -- seven frost shards per ball, so
             this attack puts up to 42 shards in the air
    trigger  Missile   (via A_Jump(102,"MissAlt") -- ~40% of the non-Butt half)
    range    --
    mirrored yes   (salvo 2 is salvo 1 with the barrel negated and the outer
                    two bands swapped)
    inherit  RS_CyanFatBall, RS_FatsoFX.zs:210
    profile  MakeVolley(proj:"RS_CyanFatBall", count:3, arc:22,
                        fireSnd:"imp/attack")
             // one salvo. The attack is two, mirrored, 8 tics apart.
    notes    THE THREE BANDS DO NOT OVERLAP -- random(1,11) / random(-1,1) /
             random(-11,-1) partition the cone into left, centre and right.
             That is a genuine fan built out of rolls, and it is why this
             reads so differently from Missile's paired jitter.

    ATTACK   RS_CyanFatso2.Butt2
    file     zscript/monsters/fatso/RS_Fatso.zs:483
    shape    CHARGE
    payload  -- (the monster IS the projectile)
    arc      --
    timing   10 tics of A_FaceTarget, A_SkullAttack(50) held 20 tics, A_Stop
             for 10, then A_SetSpeed(10) and `Goto Missile`
    damage   Damage 5   (the monster's own Default property, consumed by the
                         SKULLFLY ram; the engine rolls it)
    type     -- (none set on the monster)
    sound    --   SILENT. A_SkullAttack plays the actor's AttackSound and
                  RS_CyanFatso2 declares none. As a profile slot that is
                  CORRECT -- the gun's own sound fills it.
    impact   Contact only. +LAXTELEFRAGDMG on the monster, Mass 1000.
    trigger  Missile   (via A_Jump(128,"Butt") 50%, then
                        `A_JumpIfCloser(500,"Butt2",true)` -- note the `true`,
                        which is the noz flag: distance is measured in 2D,
                        ignoring height)
    range    ..500 (2D)
    mirrored no
    inherit  -- (Fatso, engine, for the actor; no projectile involved)
    profile  MakeMelee(range:500.0, dmgMult:1.0)
             // CHARGE has no factory of its own. MakeMelee with a long range
             // is the closest existing form and loses the travel entirely.
             // Recorded as a gap, see UNRESOLVED U4.
    notes    `A_SetSpeed(10)` at the end PERMANENTLY drops the monster from
             Speed 11 to 10 -- it never recovers. CH-faithful.
             If the target is 500+ away, Butt falls to `Goto Missile+2`, which
             is A_FatRaise -- i.e. it silently becomes the normal volley.
             Offset verified state-by-state.
             ADJACENT, NOT A ROW: `Jumpy` (`:444`) and `Bon` (`:509`) are
             ThrustThing hops with no damage -- mobility and a pain-hop.

---

# TIER 13 -- RS_BrownFatso2 ("What big hands you got")

    ATTACK   RS_BrownFatso2.Missile
    file     zscript/monsters/fatso/RS_Fatso.zs:309
    shape    MULTI
    payload  RS_ZapFFAT x8  (0 DAMAGE -- see notes)
             + RS_FatsoSoundWave x5  (the entire damage of the attack)
    arc      PHASE 1, eight zaps in four simultaneous pairs:
               -21 barrel, random(-1,5)  /  +21 barrel, random(-5,1)
               -- the same two bands, four times. Spawn height 18.
             PHASE 2, five sound waves ALL ON ONE TIC, spawn height 18:
               -21 barrel, random(-1,6)
               -21 barrel, random(-3,3)
               -21 barrel, random(-13,-6)
               -21 barrel, random(6,13)
               +21 barrel, random(-6,1)
               = four from the LEFT barrel spanning -13..+13, one from the
               right. Deliberately lopsided.
    timing   10 (A_FatRaise), then zap pairs at t=11, 20, 29, 38 (9 tics
             apart: 1 tic of sound + 8 tics of hold), 5 tics of A_FaceTarget,
             then all five waves at t=51, 10 + 15 recovery.
    damage   -- for RS_ZapFFAT (no Damage property at all -> Damage 0)
             DamageFunction (random(10,55)) for RS_FatsoSoundWave
    type     Plasma   [RS_FatsoSoundWave]
    sound    "fatso/raiseguns"; "ELECFATT" on channel 0 before EACH zap pair
             (four plays); "BASSFFAT" on channel 0 before the wave salvo;
             "fatso/attack" per wave (SeeSound)
    impact   RS_ZapFFAT: nothing. Speed 1, no damage, no A_Explode, seven
             LITN frames and Stop. It is a lightning DECAL.
             RS_FatsoSoundWave: ProjectileKickBack 9001, Speed 56, XScale 2.1
             YScale 0.65 (a flat bar). IN FLIGHT it sheds
             RS_FatsoSoundWaveTrail on EVERY frame -- and that trail is
             ITSELF a live projectile, DamageFunction (random(10,55)) Plasma,
             so the wave lays a damaging corridor behind it.
             Wave Death: A_SetScale(2.5,1.2), `GBLL B 6 A_Explode(random(20,80),128,0)`
             (one explosion, NOT self-harming), A_SetScale(3.0,1.5), fade.
             DeathSound "weapons/bfgx".
             Trail Death: A_SetScale(0.15), 4 RS_ZapFFAT, then
             `LITN ABCD 1 A_Explode(random(8,12),64,0)` x4, 4 more ZapFFAT,
             `LITN EFG 1 A_Explode(random(8,12),64,0)` x3 -- SEVEN explosions
             per trail piece, radius 64, not self-harming.
             DeathSound "spit/spit2".
    trigger  Missile
    range    300..   (`A_JumpIfCloser(300,"CloseRaise")` diverts below 300)
    mirrored no
    inherit  RS_FatsoSoundWave :104, RS_FatsoSoundWaveTrail :142 --
             zscript/monsters/fatso/RS_FatsoFX.zs. Neither inherits.
             RS_ZapFFAT is CEDED to the Revenant lane and lives at
             zscript/monsters/revenant/RS_RevenantFX.zs:2003 (CH Fatsos.txt:269).
    profile  MakeVolley(proj:"RS_FatsoSoundWave", count:5, arc:26,
                        fireSnd:"BASSFFAT")
             // PHASE 2 ONLY. Phase 1 is cosmetic and should NOT be modelled
             // as a volley -- it would be a 0-damage profile, which is the
             // "null is a crash-safety net, not a design choice" trap
             // (CLAUDE.md / rs_05). If the look is wanted, it is a muzzle FX
             // slot, not an attack.
    notes    **THE HEADLINE "TESLA VOLLEY" DEALS ZERO DAMAGE.** RS_ZapFFAT
             declares no `Damage`, so it inherits Actor's 0, and its states
             contain no A_Explode. Eight of them fire per Missile and none of
             them can hurt anything. All of the Brown's ranged damage is the
             five RS_FatsoSoundWave and their trails. Verified against CH:
             CH's ZAPFFAT (Fatsos.txt:269) is identical -- this is CH's
             design, not an import loss. A weapon author copying "eight
             lightning bolts" would ship a gun that does nothing.
             The 9-tic zap cadence is `PlaySound(1 tic) + missile(0) +
             missile(8)`, so the SOUND leads the pair by one tic.

    ATTACK   RS_BrownFatso2.CloseRaise
    file     zscript/monsters/fatso/RS_Fatso.zs:283
    shape    MULTI
    payload  RS_ZapFFAT x4 fired (0 damage) + RS_ZapFFAT x18 placed (0 damage)
             + RS_ZapFFAT2 x2 planted on the target (ALL of the damage)
    arc      per block (the block runs TWICE):
               2 fired zaps, simultaneous: -21 barrel random(-1,5),
                 +21 barrel random(-5,1), spawn height 18
               9 placed zaps via A_SpawnItemEx at
                 (random(12,252) forward, random(-12,12) lateral,
                  random(24,42) up) with velocity 3 forward and
                  random(-1,1) vertical -- a WALL of lightning laid out up to
                  252 units ahead, not aimed
               1 x A_VileTarget("RS_ZapFFAT2") -- spawns the fire AT THE
                 TARGET'S FEET and stores it in `tracer`
    timing   3 (face) + 1 (sound) + [pair on one tic] + 8 + [9 placed on one
             tic] + 10 (A_VileTarget), then the whole block again
             (3+1+0+0+10), then 1 tic of A_CheckSight and the range re-test.
             ~54 tics.
    damage   -- for RS_ZapFFAT.
             RS_ZapFFAT2 has no Damage property either, but its Fly state runs
             `A_Explode(random(1,2),32,0)` on ELEVEN separate frames
             (LITN ABCD, LITN EFG, LITN FEDB), radius 32, NOT self-harming,
             and it spawns 12 more RS_ZapFFAT sparks along the way.
    type     Plasma   [RS_ZapFFAT2]
    sound    "ELECFATT" on channel 0, once per block (two plays)
    impact   RS_ZapFFAT2 is planted on the target by A_VileTarget, which also
             sets `fog.target = self` and `fog.tracer = self.target` and calls
             `fog.A_Fire(0)` -- verified in the engine's own
             zscript/actors/doom/archvile.zs. RS_ZapFFAT2 does NOT call A_Fire
             in its own states, so it does not track; it sits where it was
             planted and burns for 11 tics.
    trigger  Missile   (via `A_JumpIfCloser(300,"CloseRaise")`)
    range    ..300
    mirrored no
    inherit  RS_ZapFFAT2 at zscript/monsters/fatso/RS_FatsoFX.zs:180 (CH :245).
             Does not inherit. RS_ZapFFAT ceded to the Revenant lane,
             RS_RevenantFX.zs:2003.
    profile  MakeVolley(proj:"RS_ZapFFAT2", count:1, arc:0, fireSnd:"ELECFATT")
             // there is no factory form for "plant it on the target" --
             // A_VileTarget has no profile analogue. Recorded, U4.
    notes    **RS_ZapFFAT2 IS THE CLASS NAMED IN CLAUDE.md's dedupe warning**
             ("a surviving copy had A_Explode on a *looping* state -- unbounded
             damage, forever, silently"). The copy in the tree today is the
             CORRECT one: its Fly runs eleven bounded frames and ends `Stop;`.
             There is no `Loop`. Verified against CH Fatsos.txt:245 -- identical.
             Recorded here so the next reader does not have to re-derive it.
             Ends `A_JumpIfCloser(300,"CloseRaise2")` else `Goto Missile+10`
             (the third ELECFATT pair -> two more zap pairs -> the wave salvo).
             Offset verified state-by-state.

    ATTACK   RS_BrownFatso2.CloseRaise2
    file     zscript/monsters/fatso/RS_Fatso.zs:300
    shape    VILE
    payload  -- (line-of-sight burn; the fire is the RS_ZapFFAT2 planted by
                 the preceding CloseRaise)
    arc      --
    timing   1 tic of A_FaceTarget, the burn held 10 tics, 10 tics recovery,
             then `Goto Missile+12`
    damage   A_VileAttack("weapons/bfgx", random(32,99), random(2,60), 32, 5,
                          "plasma")
             -> direct hit random(32,99) applied with damagetype 'none'
                (VAF_DMGTYPEAPPLYTODIRECT is NOT set -- the last argument is
                absent, so flags = 0)
             -> blast random(2,60) at radius 32, damagetype "plasma"
             -> upward thrust factor 5 (five times an Archvile's)
    type     plasma   (the BLAST only; the direct hit is typeless -- verified
                       in the engine's own A_VileAttack at
                       zscript/actors/doom/archvile.zs)
    sound    "weapons/bfgx" on CHAN_WEAPON, played by A_VileAttack itself
    impact   The engine moves `tracer` (the RS_ZapFFAT2) to 24 units in FRONT
             of the target and explodes it there. If CloseRaise never ran,
             `tracer` is null and the blast half of the attack silently does
             nothing -- only the direct random(32,99) and the thrust land.
             A_VileAttack aborts entirely if `CheckSight(target, 0)` fails.
    trigger  Missile   (via CloseRaise's `A_JumpIfCloser(300,"CloseRaise2")`)
    range    ..300
    mirrored no
    inherit  -- (engine action; the fire class is RS_ZapFFAT2, RS_FatsoFX.zs:180)
    profile  MakeRadial(radius:32.0, damage:60, fireSnd:"weapons/bfgx")
             // MakeRadial loses the direct hit, the LOS requirement and the
             // thrust. VILE has no factory of its own. Recorded, U4.
    notes    THRUST FACTOR 5 IS THE POINT. The engine computes
             `targ.Vel.z = thrust * 1000 / max(1, targ.Mass)`, so a
             100-mass player is thrown 50 units/tic upward. This is a launcher
             as much as a damage source, and the damage numbers alone do not
             say so.
             `Goto Missile+12` lands on the SECOND HALF of the third zap pair
             (the +21 shot), not on a pair boundary. Offset verified.

---
---

# SECONDARY ROWS -- impacts that are themselves attacks

Spec section 4: "IMPACT CAN BE AN ATTACK ... record it in `impact` AND give
the secondary its own row if it is substantial." Six qualify.

    ATTACK   RS_CyanFatBall.Death
    file     zscript/monsters/fatso/RS_FatsoFX.zs:235
    shape    RING
    payload  RS_FrostLong2 x7
    arc      random(0,359) per shard -- FULL 360, the spec's own tell.
             Pitch offset random(-25,-5) via CMF_OFFSETPITCH, i.e. every shard
             is angled 5-25 degrees UPWARD out of the burst.
    timing   all seven on ONE tic, immediately on impact
    damage   DamageFunction (random(3,9))   [RS_FrostLong2]
    type     Ice
    sound    A_Scream -> DeathSound "Ice/Hit2" (the parent ball's)
    impact   RS_FrostLong2 Death is INHERITED from RS_FrostLong:
             `PUFI ABCD 1 A_SetTranslucent(0.4); PUFI EFGH 1` -- an 8-frame
             frost puff -- and DeathSound "Ice/Hit2", also inherited.
             The shard strips +SEEKERMISSILE and overrides Spawn to a plain
             4-frame loop, so it flies straight at Speed 76 (inherited).
    trigger  Death   (of RS_CyanFatBall, which is fired by
                      RS_CyanFatso2.Missile and .MissAlt)
    range    --
    mirrored no
    inherit  **RS_FrostLong2 : RS_FrostLong**, zscript/monsters/imp/RS_ImpFX.zs:278
             and :246 (CH MASTERMINDS.txt:2640 / :2610). The child overrides
             ONLY `-SEEKERMISSILE`, the damage roll, and `Spawn`. Its impact
             puff and DeathSound come from the parent and are written nowhere
             near the burst -- reading the child alone reports "no impact FX".
    profile  MakeVolley(proj:"RS_FrostLong2", count:7, arc:360,
                        pitchJitter:20.0)
    notes    The Cyan's real damage geometry: one aimed ball becomes seven
             upward-angled shards on arrival. Eight balls per Missile = 56
             shards.

    ATTACK   RS_FatsoSpikes.Death
    file     zscript/monsters/fatso/RS_FatsoFX.zs:491
    shape    RING
    payload  RS_CGNail x6
    arc      45, 105, 165, 225, 285, 345 -- EXACTLY 60 DEGREES APART, a full
             ring offset 45 degrees off the spike's facing
    timing   the six A_Explode frames first (48 tics), THEN all six nails on
             one tic (five 0-tic states plus a 1-tic final)
    damage   DamageFunction (random(1,5))   [RS_CGNail]
    type     Melee
    sound    "weapons/boom1" (the spike's DeathSound);
             "moloch/nailhitbleed" is RS_CGNail's AttackSound
    impact   RS_CGNail: Speed 45, Scale 0.5, Decal "BulletChip",
             +SPAWNSOUNDSOURCE +EXTREMEDEATH +BLOODSPLATTER.
             Death: A_PlaySound("moloch/nailhit"), then
             `6PUF ABCDEF 1 A_Explode(random(1,3),16)` x6 and
             `FBL1 EFG 1 A_Explode(random(1,3),16)` x3 -- NINE explosions,
             radius 16, self-harming -- then one RS_PuffCybieRed.
             DeathSound "weapons/firex4".
    trigger  Death   (of RS_FatsoSpikes, fired by RS_GrayFatso2.Missile)
    range    --
    mirrored no
    inherit  RS_CGNail at zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:423
             (CH Chaingunners.txt:798). Does not inherit.
    profile  MakeVolley(proj:"RS_CGNail", count:6, arc:360)
    notes    The 45-degree offset means the ring never fires straight back
             along the spike's path. Four spikes per Gray volley = 24 nails.

    ATTACK   RS_HBeastShot.Death
    file     zscript/monsters/fatso/RS_FatsoFX.zs:670
    shape    FAN
    payload  RS_HBeastFlame x22   (+ one A_Explode)
    arc      TWENTY-TWO FIXED ANGLES, fired in mirrored pairs, in this order:
             -130, +130, -10, +10, -150, +150, -30, +30, -170, +170,
             -50, +50, -60, +60, -70, +70, -80, +80, -95, +95, -110, +110
             Sorted: +/-10, +/-30, +/-50, +/-60, +/-70, +/-80, +/-95, +/-110,
             +/-130, +/-150, +/-170.
             A 340-DEGREE FAN WITH A HOLE DEAD AHEAD AND DEAD BEHIND. The step
             is deliberately uneven: 20 degrees out to +/-50, then 10 degrees
             to +/-80, then 15, then 15/20/20. Denser to the sides than the
             front. Spawn height 1 -- these are at floor level.
    timing   all 22 on ONE tic, then A_Scream, then
             `CFCF Q 1 A_Explode(random(20,50),128,0,1)` -- one explosion,
             radius 128, flags 0 (NOT self-harming), alert = true (wakes
             monsters), then a 27-tic burn animation
    damage   Damage 1 + STRIFEDAMAGE   [RS_HBeastFlame]
             plus A_Explode(random(20,50),128,0,1) from the shot itself
    type     Fire
    sound    "horn/shotx" (the shot's DeathSound); "imp/shotx" per flame
             (SeeSound)
    impact   RS_HBeastFlame: +FLOORHUGGER, Speed 20, Scale 1.25,
             Decal "DoomImpScorch", and its ENTIRE Spawn is
             `CFCF ABCDEFGHIJKLMNOP 2 Bright A_Explode(random(1,5),22)` --
             SIXTEEN frames, SIXTEEN explosions, radius 22, self-harming,
             over 32 tics. Death is a bare TNT1.
             22 flames x 16 = up to 352 radius-22 blasts per shot.
    trigger  Death   (of RS_HBeastShot, fired by RS_RedFatso.Fires --
                      and note the shot SELF-TERMINATES after 18 tics of
                      flight whether or not it hits, so this always happens)
    range    --   (delivered ~414 units out, at floor level)
    mirrored yes   (the list is eleven mirrored pairs)
    inherit  RS_HBeastFlame at zscript/monsters/fatso/RS_FatsoFX.zs:699.
             Does not inherit.
    profile  MakeVolley(proj:"RS_HBeastFlame", count:22, arc:340)
             // an even 22-across-340 gives ~16.2-degree steps. CH's list is
             // above and is NOT even -- 20/20/10/10/10/15/15/20/20. Recorded,
             // not rounded.
    notes    THE BEST "FLOOR NUKE" IN THE FAMILY and the Red's real close
             attack -- the RS_HBeastShot that carries it does zero contact
             damage. The 16-frame A_Explode is DELIBERATE lingering fire
             (MEMORY.md).

    ATTACK   RS_ShadowBombBigEX.Spawn
    file     zscript/monsters/fatso/RS_FatsoFX.zs:820
    shape    SCATTER
    payload  RS_ShadowBeast_BallFire x4 per 3-tic loop, shed continuously
             while the bomb flies
    arc      one at random(120,240) (i.e. BACKWARD), three at random(90,270).
             All spawned with velocity random(9,33) forward and random(-9,9)
             vertical, at -12 offset.
    timing   3 tics per loop, for the whole flight. A_SeekerMissile(12,9) on
             the third frame of every loop.
    damage   `BDP2 A 1 A_Explode(random(40,60),128,0)` on the FIRST FRAME OF
             EVERY LOOP -- the bomb pulses a radius-128 blast every 3 tics
             while travelling. NOT self-harming.
             Damage 3 per shed fireball (+RIPPER).
    type     Plasma (the bomb), Poison (the fireballs)
    sound    "shadowbeast/pr1sight" (+SPAWNSOUNDSOURCE, so it plays from the
             firer); "shadowbeast/pr1death" per shed fireball
    impact   Death: A_SetScale(3.5), `BDP2 DE 4 A_Explode(random(10,50),258,0)`
             x2, then **108** RS_ShadowBeast_BallFire (four lines of 27) at
             random(-359,359), then `BDP2 FGH 3 A_Explode(random(10,50),258,0)`
             x3. FIVE radius-258 explosions plus a 108-projectile burst.
             DeathSound "shadowbeast/pr1death".
    trigger  Missile   (it is the payload of RS_BlackFatsoEX.BiggerBomb)
    range    --
    mirrored no
    inherit  RS_ShadowBombBigEX :798; RS_ShadowBeast_BallFire :1021 --
             zscript/monsters/fatso/RS_FatsoFX.zs. Neither inherits.
    profile  MakeHeavy(proj:"RS_ShadowBombBigEX", spawnHeight:56,
                       fireSnd:"shadowbeast/pr1sight")
             // the pulse-while-flying and the 108-ball death are inside the
             // projectile, so MakeHeavy carries them for free.
    notes    A SEEKING AREA-DENIAL BOMB, not a shell. The per-tic
             A_Explode is DELIBERATE (MEMORY.md) -- it is the mechanic.
             Radius 258 x5 on death is the largest blast in the family apart
             from the White boss's 326.

    ATTACK   RS_ShadowBombBig.Spawn
    file     zscript/monsters/fatso/RS_FatsoFX.zs:858
    shape    SCATTER
    payload  RS_ShadowBeast_Ball2 x1 per 3-tic loop, shed while flying
    arc      **66 degrees, fixed** -- and this is CH's shifted argument form.
             The call is
             `A_CustomMissile("RS_ShadowBeast_Ball2", random(2,12),
                              random(-20,20), CMF_AIMDIRECTION|CMF_SAVEPITCH,
                              random(0,360), random(0,360))`
             so argument 4 (the ANGLE) receives the numeric value of
             CMF_AIMDIRECTION|CMF_SAVEPITCH = 2|64 = **66**, argument 5 (the
             FLAGS) receives `random(0,360)` -- a random CMF bitmask -- and
             argument 6 (the PITCH) receives `random(0,360)`.
             Net effect: every shed ball goes out at a fixed +66 degrees with
             a random vertical angle and a randomly-varying set of aiming
             flags. See UNRESOLVED U3.
    timing   one ball per 3-tic loop, for the whole flight (Speed 8, so a long
             flight)
    damage   `BDP2 A 1 A_Explode(random(10,30),128)` on the first frame of
             every loop -- **self-harming** (flags omitted, unlike the EX).
             DamageFunction (random(10,45)) Plasma per shed ball.
    type     Plasma
    sound    "shadowbeast/pr1sight" (bomb); "shadowbeast/pr2sight" per ball
    impact   Bomb Death: `BDP2 DE 4 A_Explode(random(10,40),162)` x2 then
             `BDP2 FGH 3 A_Explode(random(10,30),128)` x3 -- five explosions,
             self-harming. DeathSound "shadowbeast/pr1death".
             Shed ball: `BDP1 FGHI 3`, no A_Explode, contact only,
             A_BishopMissileWeave in flight, DeathSound "shadowbeast/pr2death".
             Trails RS_Trail11 at +7 lateral every 3 tics.
    trigger  Missile   (payload of RS_BlackFatso2.BiggerBomb)
    range    --
    mirrored no
    inherit  RS_ShadowBombBig :837; RS_ShadowBeast_Ball2 :1150 --
             zscript/monsters/fatso/RS_FatsoFX.zs. Neither inherits.
    profile  MakeHeavy(proj:"RS_ShadowBombBig", spawnHeight:56,
                       fireSnd:"shadowbeast/pr1sight")
    notes    Because the argument shift puts a roll into the FLAGS slot, the
             shed balls' aiming behaviour VARIES PER BALL -- some get
             CMF_ABSOLUTEANGLE, some CMF_AIMOFFSET, some CMF_BADPITCH. The
             result is genuinely chaotic and unreproducible by any clean
             factory call. Verified byte-for-byte against CH; do NOT "fix" it.

    ATTACK   RS_WhiteFatMark.Death
    file     zscript/monsters/fatso/RS_FatsoFX.zs:1352
    shape    RAIN
    payload  RS_WhiteFatNuke x1 per mark
             (+ 8 x RS_CircleDrawMeteorCH..CH6 ring-drawers, cosmetic)
    arc      --   Not aimed. The nuke spawns directly above the mark at
             z random(128,256) with velocity (0,0,-2) and -NOGRAVITY, so it
             falls straight down onto the mark's position.
    timing   THE TELEGRAPH IS THE ATTACK. Counted state by state:
             1 tic (A_Scream) + 6 x 0-tic ring spawns + 4 tics of alternating
             CHTA/TNT1 + EIGHT cycles of (CHTA A 10, TNT1 A 1) = 88 tics.
             **93 tics total, ~2.66 seconds** of visible circle before the
             nuke is spawned. Then A_KillChildren clears the ring.
    damage   DamageFunction (random(100,200))  on contact
             plus A_Explode(random(80,155),326) on detonation -- **the largest
             blast radius in the family**, self-harming
    type     Fire
    sound    "Juggernaut/Attack" via A_Scream when the circle starts;
             "ARCAZAP7" when the nuke spawns (its SeeSound);
             "NETHERDE" on detonation (its DeathSound)
    impact   RS_WhiteFatNuke: Mass 8000, Speed 25, XScale 1.2 YScale 2.6,
             -NOGRAVITY (so it falls under gravity plus its -2 z velocity),
             +DONTHARMCLASS. Death: A_SetScale(2.5,0.15), A_Scream,
             `BFE1 C 8 A_Explode(random(80,155),326)`, then
             `Radius_Quake(15,15,0,40,0)`.
             The circle actors are attached with SXF_SETMASTER precisely so
             A_KillChildren can clean them up at the end.
    trigger  Spawn    (the mark's Spawn falls straight into Death; it is a
                       delayed-fuse actor, not a projectile)
    range    --   (placed at random(+/-1524) in both axes from the boss)
    mirrored no
    inherit  RS_WhiteFatMark :1335, RS_WhiteFatNuke :1385 --
             zscript/monsters/fatso/RS_FatsoFX.zs. Neither inherits.
             RS_CircleDrawMeteorCH..CH6 are shared, defined by an earlier
             family and referenced read-only.
    profile  MakeVolley(proj:"RS_WhiteFatMark", count:1, arc:0)
             // the fuse, the ring and the falling delivery are all inside
             // RS_WhiteFatMark. Anything that fires it gets the whole
             // mechanic. This is the cleanest "wearable mechanic" in the
             // family.
    notes    A 2.66-SECOND TELL FOR A 326-RADIUS BLAST is the entire design
             contract of the White boss's signature. Any profile that
             shortens the fuse changes the fight, not the damage.

---
---

# EXTERNAL PAYLOAD CLASSES -- opened and matched

These are referenced by fatso attacks but ship from other families' files
(correct-in-place rule; a duplicate class name is a fatal compile error).
Every one was opened at its real home for this catalog.

| class | ships at | CH line |
|---|---|---|
| RS_GreenBomb1 | `zscript/monsters/lostsoul/RS_LostSoulFX.zs:2360` | Fatsos.txt:1437 |
| RS_BlueFT | `.../RS_LostSoulFX.zs:2390` | :1611 |
| RS_BlueFT3 | `.../RS_LostSoulFX.zs:2421` | :1641 |
| RS_BlueFT2 | `.../RS_LostSoulFX.zs:2449` | :1666 |
| RS_Bluewave1 | `.../RS_LostSoulFX.zs:2484` | :1699 |
| RS_Bluewave2 | `.../RS_LostSoulFX.zs:2529` | :1742 |
| RS_PurpleBomb1 | `.../RS_LostSoulFX.zs:2553` | :1925 |
| RS_MiniFatsoPurpleBomb | `.../RS_LostSoulFX.zs:2602` | :1971 |
| RS_FatsoShotYE | `.../RS_LostSoulFX.zs:2639` | :2140 |
| RS_RocketShotFatso | `.../RS_LostSoulFX.zs:2677` | :2176 |
| RS_HomingRocketTrailFatso | `.../RS_LostSoulFX.zs:2705` | :2202 |
| RS_Shot2Fatso | `.../RS_LostSoulFX.zs:2729` | :2356 |
| RS_FatsoSpikes2 | `zscript/monsters/imp/RS_ImpFX.zs:216` | :1148 |
| RS_FrostLong2 (: RS_FrostLong :246) | `zscript/monsters/imp/RS_ImpFX.zs:278` | MASTERMINDS.txt:2640 |
| RS_ZapFFAT | `zscript/monsters/revenant/RS_RevenantFX.zs:2003` | :269 |
| RS_FatsoPuff3 | `zscript/monsters/revenant/RS_RevenantFX.zs:2036` | :1880 |
| RS_CGNail | `zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:423` | Chaingunners.txt:798 |
| RS_SparkPuff1 | `zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:209` | Archviles.txt:3045 |

Non-damaging shared decor referenced by these attacks and NOT rowed:
`RS_Trail11`, `RS_Trail12`, `RS_Splash11`, `RS_Gas14`, `RS_SplashAbyss`,
`RS_SplashAbyss2`, `RS_AbyssShotIdentifier`, `RS_Bounc22`, `RS_FireSpe2`,
`RS_PlasmaBallSP4`, `RS_CircleDrawMeteorCH..CH6`, `RS_ColorTierIconCH..CH13`.

---
---

# UNRESOLVED

**U1 -- CH IS NOT AT THE PATH THE BRIEF NAMED.**
The brief and `rs_35`'s section 4 both say CH is at
`C:\Users\Command\Desktop\CH`. **That directory does not exist on this
machine.** `Test-Path` returns False; the Desktop contains `CHP`, `elites`,
`CrashReport`, `GlowInTheDark_*` and `TextureLights_Reignited` -- no `CH`.
I used `E:\New folder\ART SOURCE\CH\`, which is the path CLAUDE.md's own
"IMPORTING A MONSTER MEANS THE WHOLE MONSTER" section names as the source of
truth for this pack, and I confirmed identity before relying on it (4,075
lines, and five spot-checked line numbers open the actors our `// CH:`
citations claim). I did not scan any drive and I consulted no other pack.
**This needs the owner's word:** either the brief's path is stale, or there is
a second CH copy I should have read instead. If a second copy exists and
differs, every "CH-faithful" claim above needs re-running -- the diff is one
command and is documented in the header.

**U2 -- ENGINE SOURCE IS ABSENT, SO THREE NATIVE FUNCTIONS ARE UNVERIFIED.**
CLAUDE.md says the engine source is at `E:\DXR2`. **That directory does not
exist either** (`Test-Path` -> False). I substituted the engine's own shipped
ZScript, read out of
`D:\SteamLibrary\steamapps\Common\DooM VR\___Sourceport\qzdoom-16-RC1-Windows-64bit\qzdoom.pk3`,
and that settled four things exactly:
  * `FATSPREAD = 90/8` and the precise A_FatAttack1/2/3 angle lists
    (`zscript/actors/doom/fatso.zs`)
  * A_VileTarget / A_VileAttack semantics, including that the direct hit is
    typeless without VAF_DMGTYPEAPPLYTODIRECT and that thrust is
    `thrust * 1000 / Mass` (`zscript/actors/doom/archvile.zs`)
  * `CMF_AIMOFFSET = 1`, `CMF_AIMDIRECTION|CMF_SAVEPITCH = 66`
    (`zscript/constants.zs`) -- which is what let me compute U3 below
  * `fatso/attack`, `fatso/raiseguns`, `fatso/shotx` are engine built-ins
    (`filter/game-doomchex/sndinfo.txt`), so their absence from the repo
    SNDINFO is correct, not a gap
**Still unverified**, because they are C++ natives with no ZScript body:
  * `A_CustomBulletAttack`'s damage multiplier. Purple's Swoosh passes
    `damageperbullet = random(1,3)` and no flags argument, so
    `CBAF_NORANDOM` is NOT set (the constant exists at `constants.zs:68`).
    Whether the engine then multiplies by a further 1-3 could not be read.
    The row records the call as written and does not assert a total.
  * `A_MonsterRefire(180,"See")`'s exact branch condition (whether 180 is the
    chance to CONTINUE or to JUMP). The row records the call verbatim.
  * `A_JumpIfHigherOrLower("Swoosh", null, 32, 0, true)` -- I read `null` as
    "no low label, so a target below does not branch". Not source-verified.

**U3 -- CH'S SHIFTED A_CustomMissile ARGUMENT FORM, 5 CALL SITES.**
Five calls pass a `CMF_*` constant into argument 4 (the ANGLE) and a
`random(0,360)` into argument 5 (the FLAGS):
  * `RS_Fatso.zs:1585` (RedFatso.Fires, RS_SparkPuff1 x5)
  * `RS_FatsoFX.zs:663-668` (RS_HBeastShot.Fly, RS_SparkPuff1 x6 lines)
  * `RS_FatsoFX.zs:858` (RS_ShadowBombBig.Spawn, **RS_ShadowBeast_Ball2**)
  * `RS_LostSoulFX.zs:2628, 2633` (RS_MiniFatsoPurpleBomb, RS_Bounc22)
  * `RS_LostSoulFX.zs:2662, 2664, 2748, 2753-2755` (RS_FatsoShotYE and
    RS_Shot2Fatso, RS_SparkPuff1)
Effective angle is therefore 1 degree (CMF_AIMOFFSET) or 66 degrees
(CMF_AIMDIRECTION|CMF_SAVEPITCH), and the flags are a per-call random bitmask.
**All but one are cosmetic** (RS_SparkPuff1 and RS_Bounc22 are
+NOINTERACTION). The exception is `RS_FatsoFX.zs:858`, where a live
`random(10,45)` Plasma projectile is affected.
**I am recording this, not calling it a bug.** It is byte-identical to CH (the
multiset diff produced no ours-only line), it may well be what CH intended,
and CLAUDE.md is explicit that this project does not "correct" CH on its own
authority. **The owner's word is needed before anyone touches it.**

**U4 -- FOUR SHAPES HAVE NO FACTORY FORM.** `RS_AttackProfile` has
MakeBullet / MakeHitscan / MakeHeavy / MakeMelee / MakeVolley / MakeBurst /
MakeSummon / MakeRadial / MakeSelfBuff. Four rows above could not be expressed
without loss and say so at the `profile` line:
  * **CHARGE** (`RS_CyanFatso2.Butt2`) -- no factory. MakeMelee with range 500
    is the closest and drops the travel entirely.
  * **VILE** (`RS_BrownFatso2.CloseRaise2`) -- MakeRadial drops the direct
    hit, the line-of-sight requirement and the thrust factor 5.
  * **A hitscan BURST** (`RS_WhiteFatso2.RapidRail`) -- MakeHitscan is
    single-shot and MakeBurst is projectile-only. Three slot entries in an
    AttackSlot rotation is the honest workaround.
  * **"Plant it on the target"** (A_VileTarget, `RS_BrownFatso2.CloseRaise`) --
    no analogue at all.
Not gaps in this catalog; gaps in the factory, surfaced here because sixteen
other families are likely hitting the same four.

**U5 -- RANDOMISED PROJECTILE SPEED HAS NO PROFILE SLOT.**
`RS_WhiteFatso2.BallBarrage` picks one of seven classes per shot whose ONLY
difference is `Speed` (8 / 11 / 16 / 21 / 27 / 33 / 40). `RS_AttackProfile`
has `VelocityMult` but it is a scalar on the weapon's rolled Velocity, not a
per-shot roll. An AttackSlot holding all seven classes reproduces it exactly;
a single MakeBurst does not. Flagging because "the arrival pattern never
repeats" is the mechanic, not a detail.

**U6 -- TWO CH-FAITHFUL UNREACHABLE ATTACK STATES.** Both confirmed identical
in CH, so neither is an import defect, but neither can fire in game:
  * `RS_BlackFatsoEX.LongRange` (`RS_Fatso.zs:1764`) -- nothing jumps to it
    except its own 83% self-loop. The EX's Missile/Choose/Phase2/Choose2 never
    name it, and CH's EX block is the same.
  * `RS_BlackFatso2.Burp` (`RS_Fatso.zs:2050`) -- nothing jumps to it, and it
    fires nothing anyway (it is a wind-up that falls through into Breath).
    CH's is the same.
Rowed anyway where the attack is fully specified (LongRange), flagged where it
is not (Burp). **Not acted on.**

**U7 -- A FILE COMMENT OVERSTATES UNREACHABILITY (cosmetic, not an attack).**
`RS_Fatso.zs:678, 687, 1564, 1574` each carry a comment saying the
`A_CustomMissile("RS_HBeastSmoke",64,0,0)` line "sits after the Loop above so
it is unreachable". Counting states for the numeric-offset jumps that precede
them, **three of the four ARE reachable**:
  * `:681` `A_Jump(81,11)` from FireBluFatso2.See -> state 11 = the smoke line
  * `:1568` `A_Jump(81,11)` from RedFatso.See -> state 11 = the smoke line
  * `:674` `A_Jump(81,3)` from FireBluFatso2.Spawn -> state 3 = the smoke line
  * `:1560` `A_Jump(81,2)` from RedFatso.Spawn -> state 2 = the tier icon, so
    THIS one really is unreachable
`RS_HBeastSmoke` (`RS_FatsoFX.zs:621`) has Speed 0, no Damage and no
A_Explode, so **no attack row is affected either way** -- it is a decorative
smoke puff. Recorded because a later reader will otherwise re-derive it, and
because "unreachable" is a claim the next person may act on. **Not acted on;
no code touched.**

**U8 -- FATB / FBXP: NOT USED BY THIS FAMILY.** CLAUDE.md's open item (the two
Doom-2-only prefixes left alone pending the owner's word) does **not** touch
the Fatso family. A case-insensitive grep of the whole `zscript/` tree puts
`FATB` and `FBXP` only in `zscript/monsters/archvile/RS_ArchvileFX.zs` and
`zscript/weapons/weaponfx/rs_fx_affixparts.zs`. Neither
`RS_Fatso.zs` nor `RS_FatsoFX.zs` names either prefix; the Mancubus fireball
here renders as **MANF** (`RS_FatShot2`, `RS_Shot2Fatso`,
`RS_BlackFatShotLongRange`, `RS_FireBluFatsoBal2`), which is a Doom 2 prefix
already covered by the family's own sprite set. **Nothing extracted, nothing
touched.**

**U9 -- ROW-SPLIT JUDGEMENT CALLS.** Three places where a different reader
could reasonably have split or merged differently, stated so the seventeen
files can be reconciled rather than silently disagreeing:
  * `RS_BrownFatso2.Missile` is ONE row (MULTI), not two, because the zap
    phase and the wave phase are one uninterrupted chain with no branch --
    and both `Goto Missile+10` and `Goto Missile+12` enter mid-zap-phase and
    still run through to the waves.
  * `RS_CommonFatso.Missile` is ONE row, not three, though it is three engine
    action calls. All three angle lists are in `arc`.
  * `RS_WhiteFatso2.BallBarrage` is ONE row, not seven, though A1..A7 are
    seven state chains -- they differ only in which of seven speed variants
    they fire. The seven speeds are enumerated in `inherit`.

**U10 -- WHAT I DID NOT CHECK.** This catalog is about attack GEOMETRY and
payload behaviour. It does **not** verify sprite presence, sound-lump
resolution end-to-end, drop tables or TRNSLATE entries -- that is the import
checklist in CLAUDE.md, not this document. The one sound thing I did check is
that every logical name an attack plays resolves somewhere: the repo SNDINFO
has `ELECFATT`, `BASSFFAT`, `WFATATTACK`, `WFATCRIT`, `ILLSHEAR`, `prieinfu`,
`ARCAZAP7`, `NETHERDE`, `horn/attack`, `shadowbeast/pr1sight`, `Ratata/rata1`
and `Juggernaut/Attack`; `fatso/attack` and `fatso/raiseguns` are engine
built-ins. **Whether each of those names reaches a real lump was NOT followed
to the end**, and per CLAUDE.md an unresolved sound is completely inert -- no
error, no warning, just silence. `RS_FatsoFX.zs`'s header asserts the family
needs no SNDINFO additions; that assertion is the file's own and I did not
independently confirm it.
