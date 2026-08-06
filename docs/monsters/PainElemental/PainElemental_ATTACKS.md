# PAIN ELEMENTAL FAMILY -- ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Field order and the shape
vocabulary are the spec's, unchanged. No shape word is coined here.

## Denominators -- what was actually read

| Thing | Count |
|---|---|
| Source files read whole | 2 (`RS_PainElemental.zs` 1,799 lines, `RS_PainElementalFX.zs` 2,042 lines) |
| Classes defined in those files | **88** (22 bodies/stubs + 66 FX) |
| Classes that carry an attack | **17** (14 tier bodies + 3 summoned minion monsters that live in the FX file) |
| State labels walked | **156** (133 in the tier bodies, 23 in the minion bodies) |
| Distinct `A_CustomMissile` payload classes | **46** |
| Distinct `A_PainAttack` / `A_DualPainAttack` / `A_PainDie` payload classes | **12** |
| Attack call **lines** (comments stripped) | 174 in the body file, 73 in the FX file |
| **Attack rows written** | **61** -- 53 primary (on the 14 tier bodies), 6 impact/secondary rows (marked `SECONDARY`), 2 on the escort drone `RS_MiniSentinelPE` |
| FX classes with **no** attack role (pure gore/decoration) | **24** -- itemised in section G |

Non-attack classes: 1 `RandomSpawner` dial, 7 cvar-gated spawn stubs, 2
`CustomInventory` buffs + 2 buff controllers, 24 gore/decoration actors, 3
orphan classes CH never fires (section H).

Line citations are repo-relative, matching the spec's worked example.
`PE.zs` = `zscript/monsters/painelemental/RS_PainElemental.zs`.
`FX.zs` = `zscript/monsters/painelemental/RS_PainElementalFX.zs`.

**Deliberate row collapse.** `RS_GreenPE.Melee` / `.Death` and
`RS_BluePE.Melee` / `.Death` are byte-identical to `RS_CommonPE.Melee` /
`.Death` apart from the soul class. They are not repeated as rows; each is
named with its own file:line in prose at the head of its monster's section
(`PE.zs:913`, `:948`, `:1020`, `:1051`). That is four attacks accounted for and
not four missing rows. Shapes used: SINGLE 13, SCATTER 10, UNCLASSIFIED 7,
MULTI 7, BURST 5, RING 4, MELEE 4, FAN 4, SALVO 2, RAIN 2, CHARGE 2, HITSCAN 1.
No word outside the spec's closed set appears; `VILE` and `COMBO` are unused
because this family calls neither `A_VileAttack` nor `A_CustomComboAttack`.

## Engine facts this catalog depends on

Read out of the GZDoom source on this machine (see UNRESOLVED U1 for the path
discrepancy), not from memory. They change what several rows mean:

* **`A_PainAttack(cls, addangle, flags, limit)` fires exactly ONE summon**,
  launched with `A_SkullAttack` unless `PAF_NOSKULLATTACK`.
  `wadsrc/static/zscript/actors/doom/painelemental.zs:198`.
* **The only cap is a compat option.** `limit` defaults to `-1`, and
  `A_PainShootSkull` promotes that to 21 *only* when `COMPATF_LIMITPAIN` is
  set (`painelemental.zs:89`). **Nothing in this family passes a `limit`.**
  So on default settings every `A_PainAttack` here is uncapped. The two real
  caps in the family are hand-built and are called out in their rows
  (Purple's `user_slowdownbuddy`, White's `A_CheckProximity`).
* `A_PainShootSkull` also **refuses to spawn** when
  `pos.z + height + 8 > ceilingz` (the PE bobs down instead) and when
  `DamageType == 'Massacre'` (`painelemental.zs:72,77`).
* `A_DualPainAttack` = TWO summons at `angle+45` / `angle-45`
  (`painelemental.zs:207`). `A_PainDie` = `A_NoBlocking` + THREE at
  `+90/+180/+270` (`painelemental.zs:217`).
* **`A_SkullAttack` ram damage = `Damage x random(1,8)`, DamageType `Melee`.**
  `AActor::Slam` -> `GetMissileDamage(7,1)`, `src/playsim/p_mobj.cpp:3372` and
  `:3319`. An actor with no `Damage` property rams for **zero**.
* **`A_MeleeAttack` damage = `MeleeDamage x random(1,8)`**, not `MeleeDamage`.
  `DoAttack`, `wadsrc/static/zscript/actors/attacks.zs:819`.
  `A_CustomMeleeAttack(n)` by contrast deals a **flat** `n`.
* **`A_Explode(dmg)` with no distance uses `distance = dmg`**, not 128 --
  `if (distance <= 0) distance = damage;`, `attacks.zs:712`. Several rows here
  look like huge blasts and are contact-radius.
* **`RGF_EXFILTER` / `RGF_EXSPECIES` are EXCLUSIONS** --
  `DoCheckClass`/`DoCheckSpecies`, `src/playsim/p_actionfunctions.cpp:3701`.
  The White boss's buffs and heals therefore go to everything in radius
  **except** species `"PE"`: it buffs the rest of the horde, never its own
  family.

---

# A. TIER 13 -- RS_BrownPE2 ("Ball of fleshy bits")

`PE.zs:188`. Health 800, Speed 12, Scale 2.0, Species "PE".

    ATTACK   RS_BrownPE2.Melee
    file     zscript/monsters/painelemental/RS_PainElemental.zs:286
    shape    MELEE
    payload  --  (5 discrete hits)
    arc      --
    timing   3,2,2,2,2   (11 tics; 3-frame windup at 3,3 before it)
    damage   A_CustomMeleeAttack(random(8,12)) x5  -- FLAT, not multiplied
    type     Melee  (A_CustomMeleeAttack's default damagetype 'none' resolves to Melee)
    sound    "flesh/melee"  (per hit)
    impact   --  (direct contact only)
    trigger  Melee
    range    --  (MeleeRange default 64)
    mirrored no
    inherit  --
    profile  MakeMelee(range:64, fireSnd:"flesh/melee", profName:"BrownPE bite")
    notes    FIVE hits, not three. `FLSP FE 2 A_CustomMeleeAttack(...)` is TWO
             frames and the action fires ONCE PER FRAME, so the two two-frame
             lines contribute 2 hits each on top of the single `FLSP E 3`.
             8..60 total across the flurry. MakeMelee has no hit-count axis --
             see UNRESOLVED U4.

    ATTACK   RS_BrownPE2.Shot
    file     zscript/monsters/painelemental/RS_PainElemental.zs:278
    shape    SINGLE
    payload  RS_BrownPEShot x1
    arc      --  (angle jitter random(-1,1))
    timing   one tic  (4-tic frame; 8-tic recovery after)
    damage   DamageFunction (random(10,45))   [FX.zs:196]
    type     Plasma
    sound    "baron/attack"  (the projectile's SeeSound; the state plays nothing)
    impact   BAL7 C-E puff + DeathSound "baron/shotx" + FIVE RS_SplashBrownPE2
             sprayed at random(-6,6),random(-6,6),random(8,24) -- see the
             secondary row below, it is the real damage
    trigger  Missile   (A_Jump(176,"Shot") at PE.zs:264 -- 176/256 = 68.75%)
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_BrownPEShot", count:1, fireSnd:"baron/attack",
                        profName:"BrownPE bolt")
    notes    Spawn height 32. The shot trails RS_SplashBrownPE every 4 tics
             (FX.zs:207) -- decoration, zero damage.

    ATTACK   RS_BrownPE2.Missile
    file     zscript/monsters/painelemental/RS_PainElemental.zs:273
    shape    MULTI
    payload  RS_BrownLSoul2 x1 (live monster)  + RS_BrownPEDed x3 (gore)
    arc      --
    timing   one tic  (12-tic frame; ~22 tics of telegraph before it)
    damage   --  (the soul is a monster: Health 125, Speed 15, Damage 3 ram,
                  AttackSound "skelatt")
    type     --
    sound    "ICKYPEBR" x2  (PE.zs:266, PE.zs:271)
    impact   the soul is launched by A_SkullAttack and then behaves as a
             free monster
    trigger  Missile   (the 80/256 = 31.25% branch A_Jump(176,"Shot") does NOT take)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_BrownLSoul2", count:1, cap:0,
                        tierOffset:-2, fireSnd:"ICKYPEBR",
                        profName:"BrownPE birth")
    notes    MULTI because the birth beat also throws three RS_BrownPEDed
             (PE.zs:268-270) -- those are NOINTERACTION gore and deal nothing.
             **cap:0 is deliberate**: CH passes no `limit`, so the engine
             applies none. Any non-zero cap in a rebuilt profile is a design
             decision, not a transcription.

    ATTACK   RS_BrownPE2.Death
    file     zscript/monsters/painelemental/RS_PainElemental.zs:312
    shape    SCATTER
    payload  RS_BrownLSoul2 x3 (live monsters)
    arc      360  (random(0,360), launched at velx random(1,9), velz random(8,15))
    timing   21,21,21   (63 tics; ~130 tics of death animation before it)
    damage   --  (see Missile row)
    type     --
    sound    "ICKYPEBR" x2  (PE.zs:310-311)
    impact   --
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_BrownLSoul2", count:3, delayTics:21, arc:360,
                       trigger:RS_FIRE_DEATH, profName:"BrownPE death brood")
    notes    `TNT1 AAA 21` = 3 frames, action once per frame. Not A_PainAttack
             -- A_SpawnItemEx with explicit velocities, so the ceiling check and
             the A_SkullAttack launch do NOT apply. MakeSummon has no delay or
             arc axis, so MakeBurst is the closer fit even though the payload is
             a monster; flagged in U4.

    ATTACK   RS_SplashBrownPE2  (SECONDARY -- the impact of RS_BrownPE2.Shot)
    file     zscript/monsters/painelemental/RS_PainElementalFX.zs:272
    shape    RAIN
    payload  RS_SplashBrownPE2 x5, each a gravity blob
    arc      --  (random(-6,6) xy from the impact point)
    timing   1,8,8,6,6 then 8 x12 (the blast chain)  -- ~96 tics of hazard
    damage   A_Explode(random(2,12),32,0) x12  -- 12 blasts, radius 32, source safe
    type     none  (A_Explode default)
    sound    "monster/tenpn1" / "monster/tenpn2" x3
    impact   spawns RS_PuffCybieRed x3 five times over the chain
    trigger  Missile  (arrives with the parent shot)
    range    --
    mirrored no
    inherit  RS_SplashBrownPE2 is standalone; the harmless RS_SplashBrownPE
             (FX.zs:216) is a DIFFERENT class -- +CLIENTSIDEONLY, no A_Explode
    profile  MakeBurst(proj:"RS_SplashBrownPE2", count:5, delayTics:0,
                       trigger:RS_FIRE_MISSILE, profName:"BrownPE splash field")
    notes    Zero direct damage; ALL of it is the 12 A_Explode frames. Six
             `BAL7 AB 8` lines x 2 frames each = 12, not 6. +THRUACTORS and
             -NOGRAVITY, so it falls to the floor and never collides -- it self-
             terminates on A_Jump(32,"Death"). A lingering ground hazard, which
             is the interesting thing to lift.

**No attack role:** `RS_BrownPE2.XDeath` (`PE.zs:314-330`). It fires 9
`A_CustomMissile` gib lines AND spawns `RS_FleshSpawnGibs` (FX.zs:314) which
fires the same 9 again -- 18 actors. `RS_Fleshspawngib1` (FX.zs:337) and its
**7 subclasses** (`gib2, gib2B, gib3, gib4, gib4B, gib5, gib6`) declare
`Projectile` with **no `Damage` and no `DamageFunction`**, so every one deals 0.
Pure gore. Recording that is the finding.

---

# B. TIER 12 -- RS_CyanPE2 ("Icey weird Pain elemental")

`PE.zs:337`. Health 963, Speed 17. `Melee:` and `Missile:` are stacked labels
(`PE.zs:402-403`) -- there is no separate melee.

    ATTACK   RS_CyanPE2.Missile
    file     zscript/monsters/painelemental/RS_PainElemental.zs:407
    shape    SINGLE
    payload  RS_IceOrbCyanAra1 x1
    arc      --  (pitch jitter random(-3,3))
    timing   one tic  (5-tic frame, 10-tic windup, 7-tic recovery)
    damage   DamageFunction (random(10,45))   [FX.zs:503]
    type     Ice
    sound    "ice/Cast"  (projectile SeeSound; the state is silent)
    impact   ICEY F-I + A_Explode(random(5,12),32) x4 frames + DeathSound
             "Ice/Hit2"; BounceSound "Ice/Splode"
    trigger  Missile / Melee   (A_Jump(128,"A1") at PE.zs:406 -- the 50% that stays)
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_IceOrbCyanAra1", count:1, fireSnd:"ice/Cast",
                        pitchJitter:3.0, profName:"CyanPE seeking iceorb")
    notes    The interesting orb: +SEEKERMISSILE (A_SeekerMissile(6,6)),
             BounceType Doom / BounceCount 7 / BounceFactor 1.25 (it ACCELERATES
             on each bounce), Gravity 0.5, A_ScaleVelocity(1.5) every 9 tics,
             A_Weave(1,3,random(-1,1),random(-4,4)), and it clears NOGRAVITY
             mid-flight (FX.zs:529). Third-file external: CH defines it in
             Spiders.txt:422, not thepains.txt.

    ATTACK   RS_CyanPE2.A1
    file     zscript/monsters/painelemental/RS_PainElemental.zs:411
    shape    SINGLE
    payload  RS_IceOrbCyanAra2 x1
    arc      --
    timing   one tic  (5-tic frame)
    damage   DamageFunction (random(10,50))   [FX.zs:544]
    type     Ice
    sound    "ice/Cast"
    impact   A_Explode(random(5,12),32) x4 frames + "Ice/Hit2"
    trigger  Missile / Melee   (the other 50%)
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_IceOrbCyanAra2", count:1, fireSnd:"ice/Cast",
                        profName:"CyanPE drunk iceorb")
    notes    NOT a seeker and does not bounce. Instead it has a 32/256 chance
             every 9 tics of entering A1, where `ThrustThing(random(0,255),
             random(1,12),0,0)` kicks it at a RANDOM absolute angle
             (FX.zs:563) -- an orb that lurches off course. Accelerates x1.25
             per cycle either way. CH: Spiders.txt:461.

    ATTACK   RS_CyanPE2.Turtle
    file     zscript/monsters/painelemental/RS_PainElemental.zs:436
    shape    BURST
    payload  RS_CyanLSoul2 x3 per loop (live monsters)
    arc      --
    timing   30,30,30 inside a 360-tic loop, FOREVER
    damage   --  (the soul: Health 80, Speed 8, Damage 2)
    type     --
    sound    --   (SILENT -- the whole Heal/Turtle chain plays nothing)
    impact   each soul is launched by A_SkullAttack
    trigger  Walk   (See does A_VileChase at PE.zs:394; when it resurrects a
                     corpse the engine sends the caller to `Heal:`, PE.zs:419,
                     which falls through into `Turtle:`)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_CyanLSoul2", count:3, cap:0,
                        tierOffset:-2, profName:"CyanPE turtle brood")
    notes    THE STATE A NAME FILTER MISSES. `Turtle` is reached only through
             `Heal`, and `Heal` is reached only by A_VileChase finding a corpse.
             `Turtle:` ends in `Loop;` -- it never returns to See. Once this
             elemental turtles it is a stationary, silent, permanent soul
             fountain. `Heal` first sets bNOPAIN, bNODAMAGETHRUST, bDONTBLAST,
             bDONTTHRUST, clears bNOGRAVITY, and scales up to (2.0,1.5) over 40
             tics (PE.zs:421-429) -- a visible commitment tell. This monster
             also RESURRECTS corpses via that same A_VileChase; there is no
             shape token for resurrection.

    ATTACK   RS_CyanPE2.Death
    file     zscript/monsters/painelemental/RS_PainElemental.zs:444
    shape    RING
    payload  RS_CyanLSoul2 x3
    arc      270  (A_PainDie fires at angle +90 / +180 / +270)
    timing   one tic  (8-tic frame)
    damage   --
    type     --
    sound    "monster/infdth"
    impact   --
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_CyanLSoul2", count:3, cap:0,
                        tierOffset:-2, profName:"CyanPE death brood")
    notes    A_PainDie is fixed at three, at fixed 90-degree steps -- it is the
             family's one hard-coded ring. Also A_IceGuyDie (PE.zs:448, +NOICEDEATH
             notwithstanding) and one RS_CH_Cirno (a Damage 0 gag actor).

---

# C. TIER 9 -- RS_AbyssPE2 ("Spooky Skull!")

`PE.zs:456`. Health 1600, Speed 20, +MISSILEEVENMORE +MISSILEMORE.
The most range-banded monster in the family: `A_JumpIfCloser(400,"Pulse")`
then `A_JumpIfCloser(1500,"Choice1")` (`PE.zs:516-517`), else fall through.

    ATTACK   RS_AbyssPE2.Missile  (the opening pack-buff)
    file     zscript/monsters/painelemental/RS_PainElemental.zs:513
    shape    UNCLASSIFIED
    payload  RS_SpeedBuffPE (an Inventory, given -- not a projectile)
    arc      360  (a radius, not an arc)
    timing   one tic  (1-tic frame, fires before every single attack it makes)
    damage   0
    type     --
    sound    "Ahead/at"  (PE.zs:514, the next tic)
    impact   RS_SpeedBuffPE -> RS_PESpeedCtl on each recipient
    trigger  Missile
    range    ..700  (the give radius, not a target band)
    mirrored no
    inherit  RS_SpeedBuffPE lives in the spectre lane
             (`zscript/monsters/spectre/RS_SpectreFX.zs:62`); CH's own source
             for it is thepains.txt:3046 -- this family's file
    profile  MakeRadial(radius:700, damage:0, heal:0, hitsAllies:true,
                        fireSnd:"Ahead/at", profName:"AbyssPE haste aura")
    notes    UNCLASSIFIED honestly: the closed set has no token for "hand an
             inventory item to every monster in radius". `RGF_MONSTERS` with NO
             filter and NO `RGF_GIVESELF` -- every other monster in 700 units,
             never itself. MakeRadial has heal/damage but no buff-item axis;
             the call above records the geometry and loses the payload. U5.

    ATTACK   RS_AbyssPE2.MissileSpam
    file     zscript/monsters/painelemental/RS_PainElemental.zs:521
    shape    SCATTER
    payload  RS_VollreyAbyPE x2 per beat, refiring
    arc      16  (angle random(-8,8); lateral spawn offset random(-5,5))
    timing   2,2 per beat, ~10 tics per beat, A_SpidRefire loop
    damage   DamageFunction (random(5,40))   [FX.zs:647]
    type     Plasma
    sound    "Forgotten/Attack"  (projectile SeeSound; the state is silent)
    impact   BBOM chain: A_SetScale(1.25), NINETEEN RS_SplashAbyss2 sprayed at
             random(-359,359) with CMF_OFFSETPITCH random(-25,-5), then
             A_Explode(random(2,12),128) x5 frames. DeathSound "spell/Impact1"
    trigger  Missile   (the >=1500 band -- neither A_JumpIfCloser fires)
    range    1500..
    mirrored no
    inherit  --
    profile  p = MakeBurst(proj:"RS_VollreyAbyPE", count:2, delayTics:2, arc:16,
                           fireSnd:"Forgotten/Attack",
                           profName:"AbyssPE volley spam");
             p.MinRange = 1500;
    notes    A_SpidRefire re-enters at `MissileSpam+1`, so the loop is
             face(4) / shoot(2) / shoot(2) / refire(2). Speed 27, FastSpeed 38,
             +SEEKERMISSILE with A_SeekerMissile(12,18) -- a HARD tracker. It
             also drops RS_SplashAbyss2 x2 per 2 tics WHILE FLYING (FX.zs:662),
             each random(1,9) Ice. The 19-droplet death spray is the payload
             that matters.

    ATTACK   RS_AbyssPE2.Souls
    file     zscript/monsters/painelemental/RS_PainElemental.zs:530
    shape    SCATTER
    payload  RS_AbyssBaronSoul x3 (live monsters)
    arc      --  (fixed offsets: (16,0,32), (16,32,0), (16,-32,0))
    timing   6,6,6   (18 tics; 3+8 tics of telegraph before)
    damage   --  (the soul detonates -- see the secondary row)
    type     --
    sound    --   (SILENT; the summoned souls carry AttackSound "vile/active")
    impact   --
    trigger  Missile   (A_Jump(255,"Pulse","Souls","Coil") at PE.zs:526)
    range    400..1500
    mirrored no
    inherit  Third-file external: CH defines the soul in Barons.txt:1252
    profile  MakeSummon(summonCls:"RS_AbyssBaronSoul", count:3, cap:0,
                        tierOffset:-3, profName:"AbyssPE siphon souls")
    notes    Spawned with A_SpawnItemEx, NOT A_PainAttack -- no ceiling check,
             no launch, no cap of any kind. They are -COUNTKILL so they do not
             inflate the map's kill count.

    ATTACK   RS_AbyssBaronSoul.Boom  (SECONDARY -- the summoned soul's attack)
    file     zscript/monsters/painelemental/RS_PainElementalFX.zs:800
    shape    UNCLASSIFIED
    payload  --  (the monster IS the bomb; it dies doing this)
    arc      360
    timing   one tic, then 15 tics of corpse animation
    damage   A_Explode(random(20,80),128)
    type     none  (A_Explode default; the actor's DamageType is Ice)
    sound    "weapons/rocklx"
    impact   A_SetScale(1.1) then MISL B-D, then A_Die
    trigger  Melee   (label `Melee:` at FX.zs:792 -- an empty state that
                      immediately `Goto Boom`) **and** Death (FX.zs:795, same)
    range    --  (MeleeRange default)
    mirrored no
    inherit  --
    profile  MakeRadial(radius:128, damage:50, heal:0, hitsAllies:false,
                        fireSnd:"weapons/rocklx",
                        profName:"AbyssPE soul detonation")
    notes    UNCLASSIFIED: a kamikaze is not CHARGE (no A_SkullAttack -- it just
             A_Chases at Speed 30 with +THRUACTORS until it is in melee range).
             Reaching melee and being killed are the SAME outcome, which is what
             makes the pack dangerous to shoot. MakeRadial cannot express the
             random(20,80) roll -- it takes an int -- so the roll is recorded
             here and lost in the call. U6.

    ATTACK   RS_AbyssPE2.Coil
    file     zscript/monsters/painelemental/RS_PainElemental.zs:537
    shape    SCATTER
    payload  RS_AbyPECoil x3
    arc      36  (angle random(-18,18); lateral spawn offset random(-15,15))
    timing   2,2,2   (6 tics; 3+6 tics of windup, 8x3 recovery)
    damage   DamageFunction (random(30,80))  direct  [FX.zs:603]
             + A_Explode(random(18,28),64) EVERY 4 TICS in flight
             + A_Explode(random(5,25),128) x3 frames on death
    type     Melee   (the projectile's DamageType)
    sound    "baron/attack"  (projectile SeeSound)
    impact   BAL1 C-E, "weapons/rocklx", and A_RadiusGive("Health",128,
             RGF_MONSTERS|RGF_EXFILTER,175,"RS_AbyssPE2") -- **175 health to
             every monster within 128 EXCEPT the Abyss PE itself**
    trigger  Missile
    range    400..1500
    mirrored no
    inherit  --
    profile  p = MakeBurst(proj:"RS_AbyPECoil", count:3, delayTics:2, arc:36,
                           fireSnd:"baron/attack", profName:"AbyssPE coil");
             p.MinRange = 400; p.MaxRange = 1500;
    notes    The nastiest single projectile in the family. +SEEKERMISSILE with
             two alternating seek strengths -- `Fly` uses A_SeekerMissile(4,5),
             `Fly2` uses (1,1), and it flips between them on A_Jump(32)/A_Jump(64)
             (FX.zs:622,629). +THRUACTORS, so it does NOT stop on a body; it
             passes through and keeps blast-ticking. It also lays
             RS_TrailAbyPE1 (FX.zs:675) every 4 tics: a +RIPPER trail worm,
             random(1,10), that A_RadiusGives 5 health to nearby monsters on a
             125 radius. This attack HEALS THE HORDE while it flies.

    ATTACK   RS_AbyssPE2.Pulse
    file     zscript/monsters/painelemental/RS_PainElemental.zs:543
    shape    RING
    payload  RS_AbyssPEPulse x35
    arc      360  (fixed 10-degree steps, 0..160 then 180..350)
    timing   one tic  (all 35 on 0-tic frames; 12-tic recovery, 8+5 windup)
    damage   DamageFunction (random(1,2)) direct   [FX.zs:715]
             + A_Explode(random(1,2),128) x9 frames in flight
             + A_Explode(random(10,30),128) on death
    type     AbyssPE  (a custom type; nothing in this family resists it)
    sound    "moloch/thud"  (projectile SeeSound, x35)
    impact   IDGA C, one final 128-radius blast
    trigger  Missile   (A_JumpIfCloser(400) -- the panic button) **and**
                       A_Jump(32,"Pulse") / A_Jump(255,"Pulse",...) from Choice1
    range    ..400  (via the JumpIfCloser; also reachable in the 400..1500 band)
    mirrored no
    inherit  --
    profile  p = MakeVolley(proj:"RS_AbyssPEPulse", count:35, arc:360,
                            fireSnd:"moloch/thud", profName:"AbyssPE pulse ring");
             p.MaxRange = 400;
    notes    **170 DEGREES IS MISSING.** The list runs 0,10,...,160 then jumps
             to 180. Verified against CH (`thepains.txt:709-710`): CH skips it
             too. 35 pulses, not 36. Do NOT "complete" the ring.
             Each pulse is a slow (Speed 11) +RIPPER +FORCERADIUSDMG +FORCEPAIN
             disc that clears +THRUACTORS on its first Fly tic (FX.zs:737) and
             then radius-nukes for 1-2 every 10 tics, nine times. Individually
             trivial; 35 of them is a wall of forced pain. Alpha 0.1 -- nearly
             invisible. After Pulse, A_Jump(64,"Missile") (PE.zs:579) re-enters
             the whole attack tree.

**No attack role:** `RS_AbyssPE2.Death` (`PE.zs:581-593`) -- A_Stop, A_Scream,
three flag clears so the corpse falls, A_NoBlocking, A_FadeOut. Nothing fires.
`RS_AbyssPEShadow` (FX.zs:578) is +NOINTERACTION afterimage decoration.
`RS_AbyssBaronHandFire` (FX.zs:809) is +NOINTERACTION +NOCLIP hand flame.

---

# D. TIER 8 -- RS_GrayPE2 ("The nasty hive")

`PE.zs:600`. Health 1450, Speed 3, +BOSS, -NORADIUSDMG. **Fires no projectile
at all.** Every attack it has is a summon. This is the family's pure summoner.

    ATTACK   RS_GrayPE2.SoulIt
    file     zscript/monsters/painelemental/RS_PainElemental.zs:665
    shape    SCATTER
    payload  RS_GrayLSoul2 x1 (live monster)
    arc      360  (random(1,359), velx random(8,18), velz random(-25,25))
    timing   one tic  (4-tic frame, 5-tic recovery)
    damage   --  (the soul: Health 50, Speed 2 -- a crawler)
    type     --
    sound    --   (SILENT)
    impact   SXF_TRANSFERPOINTERS -- the soul inherits the hive's target
    trigger  Missile (A_Jump(255,"Bug1","SoulIt","Bug2"), PE.zs:662)
             **and** Pain (A_Jump(128,"SoulIt"), PE.zs:698)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_GrayLSoul2", count:1, cap:0,
                        tierOffset:-2, profName:"GrayPE soul spit")
    notes    Thrown, not A_PainAttacked -- so no ceiling check and no
             A_SkullAttack launch; the velocity IS the launch.
             SXF_TRANSFERPOINTERS is the important bit: it arrives already
             hunting you.

    ATTACK   RS_GrayPE2.Bug1
    file     zscript/monsters/painelemental/RS_PainElemental.zs:673
    shape    SINGLE
    payload  RS_GreyDemon2 x1 (live monster -- Health 700, Speed 16)
    arc      --  (A_PainAttack fires at the hive's facing angle)
    timing   one tic  (4-tic frame, 5-tic recovery)
    damage   --
    type     --
    sound    --   (SILENT)
    impact   launched by A_SkullAttack -- a 700 HP demon arrives ALREADY FLYING
             at you
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_GreyDemon2", count:1, cap:0,
                        tierOffset:-1, profName:"GrayPE demon birth")
    notes    **KNOWN RULING, NOT RE-LITIGATED.** CH writes
             `A_PainAttack("GrayDemon2")` (thepains.txt:988, verified); CH
             spells the body `GreyDemon2` (Demons.txt:881) and defines
             `GrayDemon2` nowhere, so this attack was DEAD in CH. Healed to
             RS_GreyDemon2 at the owner's order, 2026-08-05. **This is the one
             row in the family where our tree deliberately differs from CH.**
             Note what it means for a profile: this is the family's heaviest
             single summon by far -- 700 HP, and the elemental has 1450.

    ATTACK   RS_GrayPE2.Bug2
    file     zscript/monsters/painelemental/RS_PainElemental.zs:677
    shape    SCATTER
    payload  RS_GraySpectre2 x1 (live monster -- Health 450, Speed 20)
    arc      360  (random(1,359), velx random(8,18), velz random(-25,25))
    timing   one tic  (4-tic frame, 5-tic recovery)
    damage   --
    type     --
    sound    --   (SILENT)
    impact   SXF_TRANSFERPOINTERS
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_GraySpectre2", count:1, cap:0,
                        tierOffset:-1, profName:"GrayPE spectre birth")
    notes    Same throw as SoulIt, heavier body. Lives in the spectre lane
             (`zscript/monsters/spectre/RS_Spectre.zs:490`).

    ATTACK   RS_GrayPE2.Death
    file     zscript/monsters/painelemental/RS_PainElemental.zs:704
    shape    MULTI
    payload  RS_BlackLSoul2 x3 (A_PainDie, +90/+180/+270)
             + RS_BlackLSoul2 x3 (scattered to random(-128,128) in x and y)
    arc      270 for the first three; a 128-unit square for the second three
    timing   2 then 2,2,2   (8 tics)
    damage   --  (RS_BlackLSoul2: Health 18, Speed 18 -- fast and fragile)
    type     --
    sound    "wraith/wraith5"
    impact   the second three land with SXF_TRANSFERPOINTERS, already hunting
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_BlackLSoul2", count:6, cap:0,
                        tierOffset:-3, fireSnd:"wraith/wraith5",
                        profName:"GrayPE hive collapse")
    notes    SIX, not three. `MISL CCC 2` is 3 frames on top of the A_PainDie.
             MULTI because the two halves have different geometry AND different
             launch (A_PainDie applies A_SkullAttack; A_SpawnItemEx does not).
             MakeSummon flattens both to one count -- recorded here, lost there.

**Dead state -- flagged, not fixed:** `RS_GrayPE2.Boom1` (`PE.zs:680-683`) is
**unreachable**. Nothing in the class jumps to it, and it draws `TORT` frames
(the Purple/Red elemental sprite) rather than this monster's `INFR`. Verified
against CH `thepains.txt:996-999`: unreachable there too, same TORT frames.
Copy-paste residue that both trees carry faithfully. No row.

---

# E. TIER 7 -- RS_FireBluPE2 ("the fuck is that")

`PE.zs:714`. Health 800, Speed 20, **`Damage 5`** (`PE.zs:730` -- this is the
ram damage, and it is the only body in the family that sets it).
`Melee:` (`PE.zs:769`) is four frames of A_FaceTarget and then `Goto Missile` --
there is no melee attack, only a windup.

    ATTACK   RS_FireBluPE2.Missile
    file     zscript/monsters/painelemental/RS_PainElemental.zs:778
    shape    CHARGE
    payload  --  (A_SkullAttack(30) -- the monster IS the projectile)
    arc      --
    timing   one tic  (5-tic frame; 5+5+4 tics of windup)
    damage   Damage 5 x random(1,8)  =  5..40 per slam
    type     Melee  (AActor::Slam hard-codes NAME_Melee)
    sound    --   (A_SkullAttack plays AttackSound; RS_FireBluPE2 sets none)
    impact   the ram is the impact; velocity clears on contact
    trigger  Missile   (the >=700 band -- A_JumpIfCloser(700,"Breath") did not fire)
    range    700..
    mirrored no
    inherit  --
    profile  MakeMelee(range:0, dmgMult:1.0, profName:"FireBluPE ram")
    notes    Speed 30 charge. **The `Damage 5` roll is the whole attack** --
             `GetMissileDamage(7,1)` = `((rand&7)+1) * DamageVal`. There is no
             CHARGE factory and MakeMelee has no launch-speed axis; this call is
             a placeholder that keeps the damage band and loses the dash. U4.

    ATTACK   RS_FireBluPE2.Breath
    file     zscript/monsters/painelemental/RS_PainElemental.zs:781
    shape    SINGLE
    payload  RS_BoomPEBlu x1
    arc      --
    timing   one tic  (1-tic frame)
    damage   DamageFunction (random(25,50))   [FX.zs:905]
    type     Fire
    sound    --   (SILENT; RS_BoomPEBlu has no SeeSound)
    impact   see the secondary row -- it explodes AND births a soul
    trigger  Missile   (A_JumpIfCloser(700,"Breath"), PE.zs:777)
    range    ..700
    mirrored no
    inherit  --
    profile  p = MakeVolley(proj:"RS_BoomPEBlu", count:1,
                            profName:"FireBluPE bomb");
             p.MaxRange = 700;
    notes    Spawn height 42 -- fired high. One frame, one tic: the fastest
             attack beat in the family.

    ATTACK   RS_FireBluPE2.Death
    file     zscript/monsters/painelemental/RS_PainElemental.zs:786
    shape    SCATTER
    payload  RS_BoomPEBlu x12  (9 sprayed + 3 from A_PainDie)
    arc      360  (random(0,359); velocities random(5,25) / random(-10,50) x2)
    timing   the 9 on ONE TIC; the 3 eight tics later
    damage   A_Explode(random(20,80),64,0) once at PE.zs:786
             + each bomb: random(25,50) direct and A_Explode(random(20,40),64,0) x2
    type     Fire
    sound    "pain/death"
    impact   twelve fire blasts AND up to twelve RS_FireBluLSoul2 (see below)
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  p = MakeVolley(proj:"RS_BoomPEBlu", count:12, arc:360,
                            fireSnd:"pain/death",
                            profName:"FireBluPE death bloom");
             p.FireTrigger = RS_FIRE_DEATH;
    notes    THE BIGGEST DEATH IN THE FAMILY per point of health. `TNT1
             AAAAAAAAA 0` is 9 frames on one tic (PE.zs:788), then A_PainDie
             ("RS_BoomPEBlu") adds 3 at +90/+180/+270 (PE.zs:789). A_PainDie's
             payload is a PROJECTILE here, not a monster -- it still gets
             A_SkullAttack'd, i.e. aimed at the killer. Then A_Die (PE.zs:790).
             The one A_Explode is folded into this row because it is the same
             death beat.

    ATTACK   RS_BoomPEBlu  (SECONDARY -- the payload of both rows above)
    file     zscript/monsters/painelemental/RS_PainElementalFX.zs:917
    shape    MULTI
    payload  A_Explode x2  + RS_FireBluLSoul2 x1 (live monster)
    arc      --
    timing   4,4   (8 tics; the projectile lives 4 tics then always dies)
    damage   A_Explode(random(20,40),64,0) x2 frames -- source safe
    type     Fire
    sound    "weapons/rocklx"
    impact   spawns RS_FireBluLSoul2 (Health 175, Speed 15, Damage 3) carrying
             the bomb's own velocity (SXF_ABSOLUTEMOMENTUM), 128/256 of the time
    trigger  Missile / Death  (whatever fired the parent)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_FireBluLSoul2", count:1, cap:0,
                        tierOffset:-1, fireSnd:"weapons/rocklx",
                        profName:"FireBlu bomb brood")
    notes    **EVERY LANDED BOMB IS A COIN-FLIP SUMMON.** `A_SpawnItemEx(...,
             128)` -- the tenth argument is `failchance`, so 128/256 = 50%.
             Spawn is `MISL B 4 Bright; Goto Death;` -- it self-detonates after
             4 tics WHETHER OR NOT it hits anything, at Speed 25. A short-fuse
             grenade, not a bolt. The full FireBlu death therefore averages
             ~6 new souls on top of 25 blasts.

---

# F. TIERS 1-6 -- the PainElemental-derived bodies

## F1. TIER 1 -- RS_CommonPE ("Pain elemental")  `PE.zs:798`

    ATTACK   RS_CommonPE.Melee
    file     zscript/monsters/painelemental/RS_PainElemental.zs:832
    shape    MELEE
    payload  --
    arc      --
    timing   one tic  (3-tic frame; 4 frames of A_FaceTarget windup at 3 each)
    damage   A_CustomMeleeAttack(random(8,40))  -- FLAT
    type     Melee
    sound    "Bite/bite4"
    impact   --
    trigger  Melee
    range    --
    mirrored no
    inherit  RS_CommonPE : PainElemental (engine class)
    profile  MakeMelee(range:64, fireSnd:"Bite/bite4", profName:"PE bite")
    notes    The family's baseline bite. Identical text in Green (PE.zs:913)
             and Blue (PE.zs:1020) -- one attack, three monsters.

    ATTACK   RS_CommonPE.Missile
    file     zscript/monsters/painelemental/RS_PainElemental.zs:839
    shape    SINGLE
    payload  RS_CommonLSoul x1 (live monster)
    arc      --
    timing   one tic  (1-tic frame; 5+5+4 tics of windup)
    damage   --
    type     --
    sound    --   (SILENT)
    impact   launched by A_SkullAttack
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_CommonLSoul", count:1, cap:0,
                        tierOffset:-2, profName:"PE soul birth")
    notes    The vanilla Pain Elemental beat, uncapped. See the engine note at
             the top: CH passes no `limit`, so `COMPATF_LIMITPAIN` off means
             this monster can fill a map.

    ATTACK   RS_CommonPE.Death
    file     zscript/monsters/painelemental/RS_PainElemental.zs:845
    shape    RING
    payload  RS_CommonLSoul x3
    arc      270  (A_PainDie: +90 / +180 / +270)
    timing   one tic  (8-tic frame)
    damage   --
    type     --
    sound    "pain/death"
    impact   all three launched by A_SkullAttack
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_CommonLSoul", count:3, cap:0,
                        tierOffset:-2, fireSnd:"pain/death",
                        profName:"PE death brood")
    notes    Identical in Green (PE.zs:948), Blue (PE.zs:1051), Yellow
             (PE.zs:1253) with their own soul classes.

**No attack role:** `RS_CommonPE.XDeath` (`PE.zs:848-864`) -- A_SpawnParticle
spam, two A_Pain, two A_SetAngle, one "weapons/rocklx". The `CH_Soul` spawn at
PE.zs:863 is behind a runtime-lookup guard because **`CH_Soul` is defined
nowhere in CH** (only `CH_SoulSphere` exists). Dead in CH, kept dead here.
Same shape in Green (PE.zs:964) and Blue (PE.zs:1067).

## F2. TIER 2 -- RS_GreenPE ("Bad Gas Green Pain elemental")  `PE.zs:868`

Melee = RS_CommonPE.Melee verbatim (`PE.zs:913`). Death = the standard
A_PainDie x3 with RS_GreenLSoul (`PE.zs:948`). Two attacks of its own:

    ATTACK   RS_GreenPE.SoulIt
    file     zscript/monsters/painelemental/RS_PainElemental.zs:924
    shape    SINGLE
    payload  RS_GreenLSoul x1 (Health 120, Speed 8, Damage 3)
    arc      --
    timing   one tic  (1-tic frame; 4-tic Bright windup)
    damage   --
    type     --
    sound    --   (SILENT)
    impact   launched by A_SkullAttack
    trigger  Missile   (A_Jump(255,"SoulIt"), PE.zs:920 -- the >=265 band)
    range    265..
    mirrored no
    inherit  --
    profile  p = MakeSummon(summonCls:"RS_GreenLSoul", count:1, cap:0,
                            tierOffset:-2, profName:"GreenPE soul birth");
             p.MinRange = 265;

    ATTACK   RS_GreenPE.Fart
    file     zscript/monsters/painelemental/RS_PainElemental.zs:928
    shape    RAIN
    payload  RS_Gas13 x9
    arc      --  (placed, not fired: xy random(+-180) x4, random(+-220) x3,
                  random(+-260) x2; z random(1,32) / random(-32,64) / random(-64,88))
    timing   5,4,3,2,1,0,1,2,3   (21 tics; 5-tic lead-in, 4-tic tail)
    damage   per cloud: A_Explode(random(6,12),42) x8 frames while it lives,
             then x7 more on Death.  Up to 15 blasts each, 135 across the field
    type     Poison
    sound    "gas/gas1" on the wind-up (PE.zs:927), "Spell/Impact1" on the
             tail (PE.zs:937)
    impact   the clouds ARE the impact -- Speed 0, they hang where placed
    trigger  Missile   (A_JumpIfCloser(265,"Fart"), PE.zs:919)
    range    ..265
    mirrored no
    inherit  --
    profile  p = MakeBurst(proj:"RS_Gas13", count:9, delayTics:2,
                           fireSnd:"gas/gas1", profName:"GreenPE gas field");
             p.MaxRange = 265;
    notes    RAIN is the nearest token in the closed set and it is not exact:
             CH places these around the **CASTER**, in a random disc up to ~260
             units and z -64..+88, and they do NOT fall (Speed 0, and
             `Projectile` sets NOGRAVITY). "Around, not aimed" fits; "above the
             target and falling" does not. Recorded rather than smoothed.
             The accelerating rhythm 5,4,3,2,1,0 and then back out 1,2,3 is a
             deliberate whoosh and MakeBurst's uniform `delayTics` cannot hold
             it -- 2 tics gives 18 total against CH's 21.
             `RS_Gas13` self-terminates on A_Jump(56,"Death") per 32-tic loop.
             Note it is `Gas13`, not `Gas14` -- Gas14 is the shotgunner lane's
             different actor.

## F3. TIER 3 -- RS_BluePE ("Blue Pain elemental")  `PE.zs:972`

Melee = RS_CommonPE.Melee verbatim (`PE.zs:1020`). Death = A_PainDie x3 with
RS_BlueLSoul (`PE.zs:1051`).

    ATTACK   RS_BluePE.SoulIt
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1030
    shape    BURST
    payload  RS_BlueLSoul x2
    arc      --  (both at the facing angle)
    timing   1 then 24 then 3   (the second soul lands ~25 tics after the first)
    damage   --  (RS_BlueLSoul: Health 145, Speed 9, Damage 3)
    type     --
    sound    --   (SILENT)
    impact   **first soul launched, SECOND SOUL NOT** -- `PAF_NOSKULLATTACK`
             at PE.zs:1032, so it hangs where it spawned and behaves as a free
             monster instead of a thrown one
    trigger  Missile   (A_Jump(255,"SoulIt","Plasma"), PE.zs:1026)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_BlueLSoul", count:2, cap:0,
                        tierOffset:-2, profName:"BluePE twin birth")
    notes    The only PAF_NOSKULLATTACK in the family. Mechanically it means one
             soul is a projectile and the other is a garrison -- a real
             difference a rebuilt profile should not average away. MakeSummon has
             no per-summon launch flag. U5.

    ATTACK   RS_BluePE.Plasma
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1036
    shape    SALVO
    payload  RS_PlasmaPE x5
    arc      --  (ALL at angle 0; spread by SPAWN POSITION, not angle:
                  heights 22/35/12, lateral offsets 0/0/0/-12/+12)
    timing   one tic  (all five on 0-tic frames after a 3-tic Bright frame)
    damage   DamageFunction (random(10,23)) each   [FX.zs:874]
    type     Plasma
    sound    "spell/spellcast1"  (projectile SeeSound, x5)
    impact   PLSE C-E + A_Explode(8,32) x3 frames + DeathSound "weapons/plasmax"
    trigger  Missile   (the other half of A_Jump(255,"SoulIt","Plasma"))
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_PlasmaPE", count:5, arc:0,
                        fireSnd:"spell/spellcast1", profName:"BluePE plasma salvo")
    notes    **A STATE CALLED `Plasma` -- exactly the case the spec warns about.**
             A `Missile:`/`Melee:` name filter never sees it. All five are
             +SEEKERMISSILE with A_SeekerMissile(1,1), so the positional spread
             CONVERGES on the target rather than fanning out: five rounds that
             arrive as a clump. Speed 14, FastSpeed 26 -- slow enough to dodge
             as one object and not as five. `arc:0` in the call is correct and
             is the whole character of the attack.

## F4. TIER 4 -- RS_PurplePE ("Purple Pain elemental")  `PE.zs:1075`

Range band: `A_JumpIfCloser(1200,"Or1")` (`PE.zs:1127`), else Boom2.
**This monster has the family's only self-imposed summon cap.**

    ATTACK   RS_PurplePE.SoulIt
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1135
    shape    FAN
    payload  RS_PurpleLSoul x2 (Health 150, Speed 9, Damage 3)
    arc      90  (A_DualPainAttack is hard-coded to +45 and -45)
    timing   one tic  (7-tic frame, 6-tic recovery)
    damage   --
    type     --
    sound    --   (SILENT)
    impact   both launched by A_SkullAttack
    trigger  Missile (via Or1, PE.zs:1131) **and** Walk (A_Jump(8,"SoulIt")
             straight out of See, PE.zs:1121 -- it summons while chasing)
    range    ..1200
    mirrored no
    inherit  --
    profile  p = MakeSummon(summonCls:"RS_PurpleLSoul", count:2, cap:7,
                            tierOffset:-2, profName:"PurplePE dual birth");
             p.MaxRange = 1200;
    notes    **THE CAP IS REAL AND IS HAND-BUILT.** `int user_slowdownbuddy`
             (PE.zs:1077). `A_JumpIf(user_slowdownbuddy > 6,"Maaybe")` at
             PE.zs:1134 diverts to `Maaybe:` once seven casts have happened;
             each cast does `+= 1` (PE.zs:1137) and **each Pain does `-= 3`**
             (PE.zs:1156). So it is not a live-pack cap at all -- it is a
             CASTING BUDGET THAT REFILLS WHEN YOU HURT IT. Shoot it and it
             summons again. `Maaybe:` (PE.zs:1139) does A_CheckSight("See") then
             `Goto Missile+4`, which is the `A_Jump(255,"Boom2")` line -- so a
             capped-out Purple falls back to its single bomb. `MakeSummon`'s
             `cap` is a LIVE-PACK cap and cannot express a refilling budget:
             `cap:7` is the nearest honest number and the mechanism is here. U5.

    ATTACK   RS_PurplePE.Boom1
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1145
    shape    FAN
    payload  RS_PurplePE2 x3
    arc      4  (angles -2, 0, +2; lateral offsets -8, 0, +8; pitches -2,0,+2)
    timing   one tic  (all three on 0-tic frames after a 5-tic Bright frame)
    damage   DamageFunction (random(5,25)) each   [FX.zs:967]
    type     none
    sound    "Wraith/Wraith3"  (PE.zs:1143)
    impact   SKUL C/D fade only -- **no A_Explode, no spawn**. Direct hit only.
             DeathSound "holy/holy2"
    trigger  Missile (via Or1)
    range    ..1200
    mirrored no
    inherit  --
    profile  p = MakeVolley(proj:"RS_PurplePE2", count:3, arc:4,
                            fireSnd:"Wraith/Wraith3", pitchJitter:2.0,
                            profName:"PurplePE skull triad");
             p.MaxRange = 1200;
    notes    Speed 28 / FastSpeed 50, Gravity 0.3, +RANDOMIZE. The tightest fan
             in the family -- 4 degrees is a shotgun choke, not a spread.
             **`DeathSound "holy/holy2"` IS SILENT.** CH's SNDINFO defines
             `Holy2` and `Holy3` and never `holy/holy2`; kept verbatim. This is
             a real hole, not a blank -- see UNRESOLVED U3.

    ATTACK   RS_PurplePE.Boom2
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1151
    shape    SINGLE
    payload  RS_PurplePE1 x1
    arc      --
    timing   one tic  (5-tic frame)
    damage   DamageFunction (random(10,47))   [FX.zs:933]
    type     none
    sound    "Spell/SpellCast1"  (PE.zs:1150) + "caco/attack" (projectile SeeSound)
    impact   SBS4 D/E fade then A_Explode(random(5,38),88) x3 frames +
             DeathSound "Bomb/boom"
    trigger  Missile   (the >=1200 band; also the fallback out of `Maaybe`)
    range    1200..
    mirrored no
    inherit  --
    profile  p = MakeVolley(proj:"RS_PurplePE1", count:1,
                            fireSnd:"Spell/SpellCast1",
                            profName:"PurplePE seeking bomb");
             p.MinRange = 1200;
    notes    +SEEKERMISSILE with A_SeekerMissile(3,3), Gravity 0.3,
             +EXPLODEONWATER. Speed 24. Three separate 88-radius blasts on
             death, not one -- `SBS4 FGH 6` is 3 frames.

    ATTACK   RS_PurplePE.Death
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1163
    shape    UNCLASSIFIED
    payload  --  (a radius blast, no actor)
    arc      360
    timing   one tic  (8-tic frame)
    damage   A_Explode(random(15,35),64)  -- flags default, so XF_HURTSOURCE
    type     none
    sound    "wraith/wraith5"
    impact   --
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  MakeRadial(radius:64, damage:25, heal:0, hitsAllies:true,
                        fireSnd:"wraith/wraith5", profName:"PurplePE death blast")
    notes    No token in the closed set covers a bare radius blast with no
             payload actor. `-NORADIUSDMG` is NOT set on this body, and the
             third A_Explode argument is omitted, so `XF_HURTSOURCE` applies.
             MakeRadial takes an int, so `random(15,35)` cannot survive the
             call -- the roll is preserved here. U6.

## F5. TIER 5 -- RS_YellowPE ("Volcanic Orange Pain elemental")  `PE.zs:1170`

    ATTACK   RS_YellowPE.Melee
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1237
    shape    MELEE
    payload  --
    arc      --
    timing   one tic  (4-tic frame; 3 windup frames at 3 each)
    damage   A_CustomMeleeAttack(random(9,48))  -- FLAT
    type     Melee
    sound    "Caco/Melee2"
    impact   --
    trigger  Melee
    range    --
    mirrored no
    inherit  RS_YellowPE : PainElemental
    profile  MakeMelee(range:64, fireSnd:"Caco/Melee2", profName:"YellowPE bite")
    notes    The hardest single melee roll in the family. Note `MeleeDamage 8`
             is ALSO set on the body (PE.zs:1182) and is **never used** --
             nothing here calls A_MeleeAttack. Dead property, carried from CH.

    ATTACK   RS_YellowPE.Spawns2
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1226
    shape    SINGLE
    payload  RS_YellowLSoul x1 (Health 180, Speed 12)
    arc      --
    timing   one tic  (5-tic frame; 10 tics of windup)
    damage   --
    type     --
    sound    --   (SILENT)
    impact   launched by A_SkullAttack
    trigger  Walk (A_Jump(8,"Spawns2") out of See, PE.zs:1221)
             **and** Missile (A_Jump(64,"Spawns2"), PE.zs:1233)
             **and** Pain (A_Jump(128,"Spawns2"), PE.zs:1243)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_YellowLSoul", count:1, cap:0,
                        tierOffset:-2, profName:"YellowPE soul birth")
    notes    THREE triggers -- the most-reachable summon in the family. After
             summoning it does A_CheckSight("See") and then `Goto Missile`
             (PE.zs:1227-1228), so a walk-summon chains straight into a lavaball.

    ATTACK   RS_YellowPE.Missile
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1232
    shape    SINGLE
    payload  RS_LavaballPE x1
    arc      --
    timing   one tic  (5-tic frame; 10 tics of windup)
    damage   DamageFunction (random(15,60))   [FX.zs:997]
    type     Fire
    sound    "weapons/firmfi"  (projectile SeeSound)
    impact   A_Explode(random(5,50),88) + BAL3 D/E + DeathSound "weapons/firex3"
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_LavaballPE", count:1, fireSnd:"weapons/firmfi",
                        profName:"YellowPE lavaball")
    notes    BounceType Doom, BounceCount 3, WallBounceFactor 1.25 -- it
             ACCELERATES off walls. `DontHurtShooter true;` (FX.zs:1009) -- a
             PROPERTY, not a flag; deleting it would silently un-protect the
             firer. Trails RS_RedPuff every 4 tics (harmless).

    ATTACK   RS_YellowPE.Death
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1249
    shape    MULTI
    payload  RS_LavaballPE x4  +  RS_YellowLSoul x3
    arc      360 for the lavaballs (45/135/225/315, CMF_AIMDIRECTION so the
             angles are absolute from the body's facing, not aimed at you);
             270 for the souls (A_PainDie +90/+180/+270)
    timing   the four lavaballs on ONE TIC; the souls 8 tics later
    damage   random(15,60) per ball + A_Explode(random(5,50),88) each
    type     Fire (balls) / -- (souls)
    sound    "monster/infdth"
    impact   as the Missile row
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_LavaballPE", count:4, arc:360,
                        fireSnd:"monster/infdth", profName:"YellowPE death cross")
             + MakeSummon(summonCls:"RS_YellowLSoul", count:3, cap:0,
                          tierOffset:-2, profName:"YellowPE death brood")
    notes    MULTI: two different payload classes in one death beat, and no
             single factory holds both -- two calls, recorded as one attack
             because a player experiences one event. The `2` in
             `A_CustomMissile(...,45,2)` is flags = CMF_AIMDIRECTION: the four
             balls form a fixed cross around the corpse regardless of where you
             are standing.

## F6. TIER 6 -- RS_RedPE ("Red rage elemental")  `PE.zs:1260`

Three-band monster: `A_JumpIfCloser(450,"BadBreath")`, `A_JumpIfCloser(900,"Or1")`,
else `Dash` (`PE.zs:1316-1318`).

    ATTACK   RS_RedPE.BadBreath
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1325
    shape    FAN
    payload  RS_CorpseBreathPE x9
    arc      32  (+16 to -16, even 4-degree step, CMF_AIMOFFSET)
    timing   3,3,3,3,3,3,3,3,3   (27 tics; 5-tic lead-in, 5-tic tail, then
             A_MonsterRefire(84,"See") -- 84/256 chance to break off)
    damage   DamageFunction (random(5,12)) direct   [FX.zs:1085]
             + A_Explode(random(5,8)) x15 frames while it tumbles
    type     Melee   (the projectile's DamageType)
    sound    "misc/gibbed"  (SeeSound AND DeathSound)
    impact   the blob keeps blasting for its whole 30-tic life, then fades
    trigger  Missile
    range    ..450
    mirrored no
    inherit  --
    profile  p = MakeBurst(proj:"RS_CorpseBreathPE", count:9, delayTics:3,
                           arc:32, fireSnd:"misc/gibbed",
                           profName:"RedPE corpse breath");
             p.MaxRange = 450;
    notes    NINE, not ten -- the four `TORT C 0 A_FaceTarget` lines interleaved
             at PE.zs:1327/1330/1333/1336 re-aim mid-sweep and fire nothing, so
             the fan TRACKS you as it sweeps. Structurally the twin of the
             spec's worked Frost Imp example, with even spacing.
             **Careful with the blast radius:** `A_Explode(random(5,8))` omits
             `distance`, and `attacks.zs:712` sets `distance = damage` -- these
             are 5-8 unit contact pops, not 128-unit blasts. Fifteen of them,
             counted by FRAME across the Spawn chain (FX.zs:1107-1117).
             -NOGRAVITY, BounceType Doom, BounceCount 3, Gravity 0.24 -- the
             blobs bounce along the floor toward you.

    ATTACK   RS_RedPE.SoulIt
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1342
    shape    SINGLE
    payload  RS_RedLSoul x1 (Health 240, Speed 11, Damage 5)
    arc      --
    timing   one tic  (9-tic frame, 5-tic recovery)
    damage   --
    type     --
    sound    --   (SILENT)
    impact   launched by A_SkullAttack
    trigger  Missile (via Or1, PE.zs:1321) **and** Walk (A_Jump(34,"SoulIt")
             out of See, PE.zs:1310) **and** Pain (A_Jump(128,"SoulIt"), PE.zs:1365)
    range    450..900 for the Missile path; unbanded for Walk and Pain
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_RedLSoul", count:1, cap:0,
                        tierOffset:-1, profName:"RedPE soul birth")
    notes    Three triggers, like Yellow's. The heaviest single soul in the
             tier 1-6 group.

    ATTACK   RS_RedPE.Boom1
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1348
    shape    FAN
    payload  RS_SbombPE x3
    arc      4  (angles -2, 0, +2; lateral offsets -8, 0, +8; heights 32/20/32)
    timing   one tic  (all three on 0-tic frames; 4-tic Bright frame before)
    damage   DamageFunction (random(10,50)) each   [FX.zs:1051]
    type     Plasma
    sound    "Wraith/Wraith3" (PE.zs:1346) + "Spell/spellCast1" (SeeSound)
    impact   A_Explode(random(5,25),88), then **one RS_RedLSoul spawned 34 units
             BELOW the impact** (FX.zs:1073) -- every bomb that lands births a
             soul, at a 32/256 fail chance. DeathSound "Crack/death"
    trigger  Missile (via Or1)
    range    450..900
    mirrored no
    inherit  --
    profile  p = MakeVolley(proj:"RS_SbombPE", count:3, arc:4,
                            fireSnd:"Wraith/Wraith3", pitchJitter:2.0,
                            profName:"RedPE soul bomb triad");
             p.MinRange = 450; p.MaxRange = 900;
    notes    Radius 20 / Height 20 / Scale 2 / Mass 600 at Speed 9 -- a huge slow
             ball. Trails RS_REDTHINGSHK and RS_RedThingsLS every 2 tics.
             The FX.zs:1073 argument tail is CH's, verbatim and scrambled:
             `A_SpawnItemEx("RS_RedLSoul",0,0,-34,0,0,0,0,128,SXF_NOCHECKPOSITION,178)`
             puts `SXF_NOCHECKPOSITION` (32) in the **failchance** slot and 178
             in **tid**. Verified identical at CH thepains.txt:1909. Not ours to
             fix; recorded so nobody "corrects" it into a different behaviour.

    ATTACK   RS_RedPE.Dash
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1354
    shape    CHARGE
    payload  --  (A_SkullAttack(30))
    arc      --
    timing   one tic  (4-tic frame), then A_MonsterRefire(84,"See")
    damage   **ZERO** -- Slam damage is `Damage x random(1,8)` and RS_RedPE
             sets no `Damage` property at all
    type     Melee  (would be, if it dealt any)
    sound    "wraith/wraith2"  (PE.zs:1353)
    impact   the ram stops the monster and nothing else
    trigger  Missile
    range    900..
    mirrored no
    inherit  --
    profile  p = MakeMelee(range:0, fireSnd:"wraith/wraith2", dmgMult:0.0,
                           profName:"RedPE rush");
             p.MinRange = 900;
    notes    **THIS ATTACK DEALS NO DAMAGE, AND THAT IS CH's.** Verified: CH's
             `ACTOR RedPE` Default block (thepains.txt:1769-1800) has no
             `Damage` line, and `AActor::Slam` -> `GetMissileDamage(7,1)` returns
             `((rand&7)+1) * 0`. Compare RS_FireBluPE2, which DOES set
             `Damage 5` for exactly this purpose. So Red's long-range answer is
             a pure closing move: it rushes you to get inside 450 and open with
             BadBreath. `dmgMult:0.0` records that; anyone rebuilding this as a
             player weapon must decide whether to keep the zero, and should know
             it is deliberate-looking but undocumented in CH.

    ATTACK   RS_RedPE.Death
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1371
    shape    UNCLASSIFIED
    payload  --  (a radius blast, no actor)
    arc      360
    timing   one tic  (8-tic frame)
    damage   A_Explode(random(15,65),128)  -- XF_HURTSOURCE by default
    type     none
    sound    "wraith/wraith5"
    impact   --
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  MakeRadial(radius:128, damage:40, heal:0, hitsAllies:true,
                        fireSnd:"wraith/wraith5", profName:"RedPE death blast")
    notes    Twice Purple's radius and roughly twice the damage. Same
             UNCLASSIFIED reason and same lost roll as PurplePE.Death.

---

# G. TIER 10 -- RS_BlackPE2 ("Hell Soul Elemental")

`PE.zs:1380`. Health 5000, +BOSS-adjacent (`-NORADIUSDMG`,
`RadiusDamageFactor 0.33`), MeleeDamage 20, MeleeRange 68.
**Two-phase.** `A_JumpIfHealthLower(2500,"Phase2")` at `PE.zs:1456`:

* Phase 1 (>=2500 HP): `A_Jump(256,"Missile2","Missile3","Missile1")`
* Phase 2 (<2500 HP):  `A_Jump(256,"Missile4","Missile2","Missile5")`

`Missile2` is the only attack common to both phases.

    ATTACK   RS_BlackPE2.Missile1
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1463
    shape    BURST
    payload  RS_SkullBundle3 x2
    arc      20  (angle random(-10,10) each)
    timing   5,5   (10 tics; 16 tics of windup)
    damage   Damage 3 -> engine rolls `3 x random(1,8)` = 3..24 on impact
    type     none
    sound    "brain/spit"  (projectile SeeSound)
    impact   see the secondary row -- each bundle births FOUR random lost souls
    trigger  Missile   (Phase 1 only)
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_SkullBundle3", count:2, delayTics:5, arc:20,
                       fireSnd:"brain/spit", profName:"BlackPE soul cube")
    notes    Also reachable as a tail-out of Missile3 (A_Jump(32,"Missile1"),
             PE.zs:1479) and Missile4 (A_Jump(88,"Missile1"), PE.zs:1499), so
             it fires in Phase 2 as well despite not being in the Phase 2 dial.
             `Damage 3` is a BARE constant and the engine rolls it -- not a flat 3.

    ATTACK   RS_SkullBundle3  (SECONDARY -- the impact of Missile1)
    file     zscript/monsters/painelemental/RS_PainElementalFX.zs:1213
    shape    SCATTER
    payload  RS_BundleRandom3 x4 -> one of RS_CommonLSoul (150) / RS_GreenLSoul
             (125) / RS_BlueLSoul (100) / RS_PurpleLSoul (75) / RS_YellowLSoul
             (50) / RS_RedLSoul (50), rolled per soul
    arc      360  (A_PainAttack(cls, random(-180,180)) -- the addangle IS the spread)
    timing   1,1,1,1   (4 tics, after 12 tics of A_Fire)
    damage   --
    type     --
    sound    "brain/cubeboom" + A_Scream
    impact   all four launched by A_SkullAttack
    trigger  Missile  (arrives with the parent bundle)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_BundleRandom3", count:4, cap:0,
                        tierOffset:-3, fireSnd:"brain/cubeboom",
                        profName:"BlackPE cube brood")
    notes    `FIRE GGHH 1` is FOUR frames -> four A_PainAttack calls, not two.
             So Missile1 delivers up to EIGHT lost souls of random tier per
             cast. The bundle also drops ammo (RS_CH_Shell 128, RS_implyingclip
             176x2, RS_CH_Cell 72, RS_CH_RocketAmmo 128) -- a summon that pays
             you for killing it.

    ATTACK   RS_BlackPE2.Missile2
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1468
    shape    SINGLE
    payload  RS_StormShot1 x1
    arc      --
    timing   one tic  (7-tic frame; 16 tics of windup)
    damage   DamageFunction (random(40,150))   [FX.zs:1492]
    type     Plasma
    sound    "weapons/shock"  (PE.zs:1467)
    impact   see the secondary row -- the cascade is far bigger than the hit
    trigger  Missile   (BOTH phases)
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_StormShot1", count:1, fireSnd:"weapons/shock",
                        profName:"BlackPE storm shot")
    notes    The single hardest direct hit in the family: random(40,150).
             Speed 30, +THRUGHOST, +NODAMAGETHRUST. While flying it sheds TWO
             RS_StormLite1 per 5 tics at absolute angles 90 and 270
             (FX.zs:1506-1507, flags 6 = CMF_AIMDIRECTION|CMF_TRACKOWNER) --
             +RIPPER lightning, Damage 5 rolled to 5..40, Speed 32. It lays a
             corridor of ripping bolts sideways as it travels.

    ATTACK   RS_StormShot1.Death  (SECONDARY -- the impact of Missile2)
    file     zscript/monsters/painelemental/RS_PainElementalFX.zs:1510
    shape    RING
    payload  RS_OverBall3 x60  (via RS_StormShotter3)
    arc      360  (random(0,360) in both the flags and pitch slots -- see notes)
    timing   1 x60   (60 tics, one per tic)
    damage   the shot's own death: A_Explode(16,32,0) x60 frames
             each RS_OverBall3: Damage 8 -> `8 x random(1,8)` = 8..64, plus
             ExplosionDamage 32 / ExplosionRadius 32 fired twice on its own death
    type     Plasma
    sound    "weapons/devexp"
    impact   AFX1 D/E `A_Explode` with no arguments -- reads ExplosionDamage 32
             and ExplosionRadius 32 off the actor (FX.zs:1462-1463)
    trigger  Missile   (arrives with the parent shot)
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_OverBall3", count:60, delayTics:1, arc:360,
                       fireSnd:"weapons/devexp", profName:"BlackPE storm cascade")
    notes    **THE SINGLE LARGEST ATTACK IN THIS FAMILY, AND IT IS AN IMPACT.**
             One landed shot spawns RS_StormShotter3 (FX.zs:1516) whose entire
             Death state is a 60-frame string
             (`LFX1 STUVW` x12) each firing one RS_OverBall3 at a random
             direction -- a one-minute-of-tics fountain -- while the parent's own
             60-frame Death string blasts A_Explode(16,32,0) alongside it.
             **The argument order is CH's and it is wrong-looking**:
             `A_CustomMissile("RS_OverBall3",0,0,CMF_AIMOFFSET,random(0,360),
             random(0,360))` puts the constant in the **angle** slot (so
             angle = 1 degree) and `random(0,360)` in the **flags** slot, i.e.
             a randomised CMF_* bitmask every shot. Verified byte-for-byte
             against CH thepains.txt:2529. Faithful, not ours. Whatever a
             rebuild does, it should not silently "tidy" this into a clean ring:
             the randomised flag word is why the spray looks chaotic.

    ATTACK   RS_BlackPE2.Missile3
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1472
    shape    MULTI
    payload  RS_HadesBall4 x4  +  RS_OverBall3 x2
    arc      6  (angle random(-3,3), pitch random(-3,3) on all six)
             spawn geometry: heights 92/8/92/8 and offsets -40/-40/+40/+40 for
             the Hades balls; height 54, offsets -50/+50 for the Over balls
    timing   all six on ONE TIC, after 8 tics of A_FaceTarget; 4-tic hold,
             7-tic A_SpidRefire, then `Goto Missile3+8` -- a refire loop
    damage   RS_HadesBall4: Damage 8 -> 8..64, Plasma   [FX.zs:1432]
             RS_OverBall3: Damage 8 -> 8..64, Plasma, + ExplosionDamage 32/32
    type     Plasma
    sound    "Monster/hadtel" (HadesBall SeeSound); OverBall is silent in flight
    impact   HadesBall4: HEFX C-H + "Monster/hadsit" + Decal "CacoScorch"
             OverBall3: A_Explode x2 frames at 32/32 + "weapons/devzap"
    trigger  Missile   (Phase 1)
    range    --
    mirrored no
    inherit  RS_HadesBall4 : CacodemonBall (engine class) -- its unlisted
             behaviour comes from there
    profile  MakeVolley(proj:"RS_HadesBall4", count:4, arc:6, pitchJitter:3.0,
                        fireSnd:"Monster/hadtel", profName:"BlackPE hades salvo")
             + MakeVolley(proj:"RS_OverBall3", count:2, arc:6, pitchJitter:3.0,
                          profName:"BlackPE over salvo")
    notes    MULTI: two payload classes on one tic. The wide symmetric spawn
             offsets (+-40, +-50) at two heights make it read as a six-barrel
             broadside rather than a fan; all six converge because the angles are
             only +-3. Loops on A_SpidRefire until it loses sight, with a
             32/256 bail into Missile1.

    ATTACK   RS_BlackPE2.Missile4
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1485
    shape    SALVO
    payload  RS_BEESHOT x12  ->  RS_BlackLSoul2 x24 (live monsters)
    arc      6  (angle random(-3,3), pitch random(-3,3))
    timing   1,1,1,1,1,4 then a 3-tic A_CheckSight and a 4-tic hold, then
             1,1,1,1,1,4 again   (two waves of six; ~35 tics total after
             8 tics of A_FaceTarget and 9 tics of GHG)
    damage   **ZERO from the projectile** -- RS_BEESHOT is `Damage 0` and
             `+INVISIBLE`, Speed 1
    type     Plasma  (declared, never applied)
    sound    --   (SILENT -- no SeeSound, and the state plays nothing)
    impact   each BEESHOT dies on its second tic and spawns TWO RS_BlackLSoul2
             with SXF_SETMASTER at random(-12,12) in x/y/z (FX.zs:1252,
             `LFX1 SS 2` = 2 frames)
    trigger  Missile   (Phase 2)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_BlackLSoul2", count:24, cap:0,
                        tierOffset:-4, profName:"BlackPE swarm")
    notes    **THE BOSS'S REAL SUMMON, AND IT IS INVISIBLE AND SILENT.**
             RS_BEESHOT is a pure delivery shell: Speed 1, Damage 0,
             +INVISIBLE, `Spawn: LFX1 S 1; Goto Death;`. Twelve shells x two
             souls each = **24 Black Lost Souls per cast** (Health 18, Speed 18
             -- fast, fragile, and they arrive as a cloud right in front of the
             boss because Speed 1 means they barely travel). No cap anywhere.
             The 12 shells are two waves of 6, and the A_CheckSight("See")
             between them (PE.zs:1491) means breaking line of sight cancels the
             second wave -- a genuine counterplay window worth preserving.

    ATTACK   RS_BlackPE2.Missile5
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1504
    shape    MULTI
    payload  RS_LoadPE3 x6 (harmless telegraph)  +  RS_SkullDeathPE x6
    arc      RS_LoadPE3: 6 (angle random(-3,3))
             RS_SkullDeathPE: up to 24 -- angles random(-8,8), random(-3,3),
             random(-12,12), random(-3,9), random(-9,9), random(-3,3) and
             pitches random(-8,8), random(-3,3), random(-3,3), random(-9,3),
             random(-3,3), random(-12,12) -- each of the six is jittered
             DIFFERENTLY
    timing   LoadPE3: 1,1,1,1,1,1 then an 8-tic hold and a 4-tic sound beat
             SkullDeathPE: 2,2,2,2,2,2   (~30 tics from first flare to last skull)
    damage   RS_LoadPE3: Damage 0
             RS_SkullDeathPE: DamageFunction (random(10,50))   [FX.zs:1160]
    type     Plasma (LoadPE3, unused) / Fire (SkullDeathPE)
    sound    "monster/ovlsit" between the two halves (PE.zs:1511);
             "Forgotten/Attack" per skull (SeeSound)
    impact   MISL B-D, A_SetScale(1.4), A_Explode(random(10,25),128) then
             A_Explode(random(10,45),128) + DeathSound "spell/Impact1"
    trigger  Missile   (Phase 2)
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_LoadPE3", count:6, delayTics:1, arc:6,
                       profName:"BlackPE charge tell")
             + MakeBurst(proj:"RS_SkullDeathPE", count:6, delayTics:2, arc:24,
                         fireSnd:"monster/ovlsit",
                         profName:"BlackPE skull barrage")
    notes    MULTI, and the two halves have opposite jobs. RS_LoadPE3 is a
             `Damage 0` Speed 1 flare that lives 8 tics and dies -- it is a
             READABLE WIND-UP, six of them from the same six spawn points the
             real skulls will use. Then the skulls: Speed 32 / FastSpeed 38,
             A_Weave(1,1,1,1) so they wobble, trailing RS_CrackoBallTrail, and
             TWO 128-radius blasts each on impact. The per-shot asymmetric
             jitter is deliberate scatter and MakeBurst's single `arc` flattens
             it -- 24 is the widest span, recorded above in full.
             FX.zs:1183 carries a repair: CH writes `MISL E`, and vanilla MISL
             ships A-D only, so the frame is held at D. Tics and actions
             unchanged; noted so nobody reverts it.

    ATTACK   RS_BlackPE2.Melee
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1522
    shape    MELEE
    payload  --
    arc      --
    timing   one tic  (4-tic frame; 12 tics of A_FaceTarget windup)
    damage   **MeleeDamage 20 x random(1,8)  =  20..160**
    type     Melee
    sound    "caco/melee"  (MeleeSound)
    impact   --
    trigger  Melee
    range    ..68  (MeleeRange 68 -- explicitly widened from the 64 default)
    mirrored no
    inherit  --
    profile  MakeMelee(range:68, fireSnd:"caco/melee", dmgMult:1.0,
                       profName:"BlackPE maul")
    notes    **NOT 20.** This is the only `A_MeleeAttack` in the family, and
             `DoAttack` (`attacks.zs:819`) multiplies: `random(1,8) * MeleeDamage`.
             20..160 makes it the hardest hit in the family by a wide margin --
             more than the storm shot. Followed by A_Jump(128,"Missile") so half
             the time a maul chains straight into a ranged attack.

**No attack role:** `RS_BlackPE2.Death` (`PE.zs:1530-1549`). Fifty-eight
`A_CustomMissile` frames of gore: RS_OverFlesh1 x5, OverFlesh2 x5, OverFlesh3-6
x10 each, OverBigArm1/2 x1 each, OverSmallArm1/2 x2 each, OverHorn1/2 x1 each.
`RS_OverFlesh1` (FX.zs:1257) declares `Projectile` with **no `Damage` and no
`DamageFunction`**; its **11 subclasses** (`OverFlesh2..6`, `OverBigArm1/2`,
`OverSmallArm1/2`, `OverHorn1/2`) override only `States`. **All twelve deal
zero.** They are `Gravity 0.125` (the correct ZScript form of the old
`+LOWGRAVITY`) chunks that arc out and lie on the floor. Pure gore, no row.

---

# H. TIER 11 -- RS_WhitePE2 ("Against thee wicked", the Watcher)

`PE.zs:1557`. Health 5000, Speed 28, +BOSS +NOTARGET +NEVERTARGET
+NOINFIGHTING +FRIGHTENED +AVOIDMELEE. A support boss: it buffs, heals,
resurrects, and screens itself behind drones.

    ATTACK   RS_WhitePE2.Eyes
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1622
    shape    BURST
    payload  RS_MiniSentinelPE x12 (live monsters, SXF_SETMASTER)
    arc      --  (all at offset (32,32,12); they orbit by A_Warp afterwards)
    timing   12 x12   (144 tics -- a long, visible deployment)
    damage   --  (each drone: Health 70, PainChance 255, Speed 28)
    type     --
    sound    --   (SILENT -- the drone's own SeeSound and ActiveSound are `""`)
    impact   SXF_SETMASTER binds each drone to the boss; the drone's whole
             movement set is `A_Warp(AAPTR_MASTER,...)` orbits
    trigger  Spawn   (`Eyes:` is the first thing the Watcher does, PE.zs:1620)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_MiniSentinelPE", count:12, cap:12,
                        tierOffset:-3, profName:"Watcher escort")
    notes    **THE FAMILY'S ONE REAL LIVE-PACK CAP, AND IT IS A PROXIMITY CHECK.**
             `A_CheckProximity("ReEye","RS_MiniSentinelPE",128,1,CPXF_LESSOREQUAL)`
             at PE.zs:1634: if **one or fewer** sentinels remain within 128
             units, the boss jumps to `ReEye:` (PE.zs:1639) and deploys twelve
             MORE at 6 tics each. So the cap is not on total spawns -- it is a
             REBUILD TRIGGER on the live escort, exactly the "kill the pack and
             the summoner rebuilds it" semantics MakeSummon's `cap` documents.
             Two more drones go out at the top of every Missile (PE.zs:1653,
             `WATC XX 1`) and three more on every Pain (PE.zs:1670,
             `WATC YYY 3`), so the escort is topped up constantly.

    ATTACK   RS_WhitePE2.DropBuff
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1648
    shape    UNCLASSIFIED
    payload  RS_BufferWhitePE x1 (a beacon that gives one of three buffs)
    arc      --  (placed at random(-64,64) x/y, random(-4,6) z)
    timing   one tic  (5-tic frame; 1+5 tics of animation before)
    damage   0
    type     --
    sound    --   (SILENT)
    impact   the beacon rolls A_Jump(256,"A1","A2","A3") (FX.zs:1772) and then
             A_RadiusGives ONE of RS_RageBuffPE / RS_HulkBuffPE /
             RS_SpeedBuffPE across **526 units**
    trigger  Walk   (A_Jump(32,"DropBuff") straight out of See, PE.zs:1631)
    range    ..526  (the give radius)
    mirrored no
    inherit  --
    profile  MakeRadial(radius:526, damage:0, heal:0, hitsAllies:true,
                        profName:"Watcher pack buff")
    notes    UNCLASSIFIED for the same reason as the Abyss aura -- the closed
             set has no buff token.
             **READ THE FILTER CAREFULLY.** `RGF_MONSTERS|RGF_EXFILTER|
             RGF_EXSPECIES, 1, "RS_WhitePE2", "PE"` and both EX flags are
             EXCLUSIONS (`p_actionfunctions.cpp:3701-3713`), so the buff reaches
             every monster in 526 units that is **neither RS_WhitePE2 nor
             species "PE"**. The Watcher buffs the rest of the horde and
             pointedly never its own family or its own drones.
             The three buffs, rebuilt native from CH ACS at the owner's standing
             order: RAGE = DamageMultiply 1.5 + forced NOPAIN for 600 tics
             (FX.zs:82); HULK = DamageFactor 0.25 taken + QUICKTORETALIATE +
             DONTTHRUST for 600 tics (FX.zs:140); SPEED lives in the spectre lane.

    ATTACK   RS_WhitePE2.Fountains
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1659
    shape    BURST
    payload  RS_HealthFountainWhitePE x2 (live monsters)
    arc      --  (placed at random(-266,266) x/y -- a huge footprint)
    timing   5,5   (10 tics; 12 tics of Missile preamble)
    damage   0
    type     --
    sound    --   (SILENT)
    impact   see the secondary row
    trigger  Missile   (A_Jump(256,"Fountains","Beams"), PE.zs:1656 -- a
                        straight 50/50 with its only damaging attack)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_HealthFountainWhitePE", count:2, cap:0,
                        tierOffset:-4, profName:"Watcher fountains")
    notes    Half of this boss's ATTACK rolls are support, not damage. That is
             the fight.

    ATTACK   RS_HealthFountainWhitePE.See  (SECONDARY -- the summoned fountain)
    file     zscript/monsters/painelemental/RS_PainElementalFX.zs:1821
    shape    UNCLASSIFIED
    payload  --  (two A_RadiusGives and a resurrect chase)
    arc      360
    timing   0,0,6,6,6   (a ~24-tic loop, forever, while it wanders)
    damage   0
    type     --
    sound    --   (SILENT)
    impact   `A_RadiusGive("RS_GrowRaisin",60,RGF_MONSTERS|RGF_CORPSES,1)` and
             `A_RadiusGive("Health",252,RGF_MONSTERS|RGF_EXFILTER|RGF_EXSPECIES,
             25,"RS_WhitePE2","PE")` -- **25 health per loop to every non-PE
             monster within 252** -- and `A_Chase(null,null,CHF_RESURRECT)`,
             which **RAISES CORPSES**
    trigger  Spawn  (its own See loop; it has no Missile state)
    range    ..252 for the heal, ..60 for the raisin
    mirrored no
    inherit  --
    profile  MakeRadial(radius:252, damage:0, heal:25, hitsAllies:true,
                        profName:"Watcher healing fountain")
    notes    UNCLASSIFIED: this is a walking, wandering, self-directed heal and
             RESURRECT aura, and the closed set has no token for either. It has
             Health 100, -COUNTKILL, Speed 15, +NOCLIP, and drops ammo when
             killed. **Killing the fountains is the counterplay to the fight**
             and no row elsewhere in this catalog says so. The resurrect is the
             sharpest part -- `CHF_RESURRECT` on A_Chase means every corpse in
             the arena is on a timer.

    ATTACK   RS_WhitePE2.Beams
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1664
    shape    HITSCAN
    payload  --  (an instant rail trace; RS_DFlarePE is the trail spawnclass)
    arc      0  (spread_xy 0, spread_z 0 -- pinpoint)
    timing   one tic  (5-tic frame; 1+5 tics of aim)
    damage   random(30,60)
    type     none  (pufftype is `null`; CH wrote `""`)
    sound    --   (SILENT -- A_CustomRailgun plays no sound and the state adds none)
    impact   no puff (pufftype null); a red RGF_FULLBRIGHT beam, duration 60,
             sparsity 0.5, driftspeed 0.2, RGF_NOPIERCING, spawning
             RS_DFlarePE actors along the trail at spawnofs_z 3,
             SpiralOffset 30
    trigger  Missile   (the other half of A_Jump(256,"Fountains","Beams"))
    range    --  (range argument 0 = engine default 8192)
    mirrored no
    inherit  --
    profile  MakeHitscan(spreadScale:0.0, profName:"Watcher red rail")
    notes    HITSCAN is the nearest token: the spec names A_CustomBulletAttack
             and A_FireBullets, and this is A_CustomRailgun -- same instant
             trace, no travelling actor, so the shape is right and the function
             is not one of the two listed. Recorded rather than coined.
             **RGF_NOPIERCING** is unusual on a rail: it stops at the first
             thing it hits. The trail class RS_DFlarePE (FX.zs:1686) is itself a
             real projectile -- DamageFunction random(10,20), Fire, Speed 25 --
             but spawned along a rail trail it gets no velocity and dies to
             `Goto Death` after 6 tics, so in practice it is a line of fire
             decoration. `MakeHitscan` has no damage field at all (weapons get
             theirs from the ammo/roll chain), so `random(30,60)` does not
             survive the call. U6.

    ATTACK   RS_WhitePE2.Death
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1677
    shape    SCATTER
    payload  RS_HKRedDeath x21
    arc      100  (the last 17 use offset random(-50,50); the first four are
             fixed at -30, +50, +30, +5; heights random(15,90), pitch
             random(-10,10))
    timing   4,4,4,4 then 4,4,4,4 / 3,3,3,3 / 2,2,2,2 / 1,1,1,1,1
             -- an accelerating 55-tic cascade
    damage   A_Explode(random(5,10),42) per unit, 21 of them
    type     Fire
    sound    "world/barrelx" x2 per unit (FX.zs:859, FX.zs:863) + "Crack/death"
    impact   each unit is a barrel-pop: MISL B-D then A_Burst("RS_RedThingsHK")
    trigger  Death
    range    --
    mirrored no
    inherit  RS_HKRedDeath is the zombieman lane's
             (`zscript/monsters/zombieman/RS_ZombiemanFX.zs:844`)
    profile  MakeBurst(proj:"RS_HKRedDeath", count:21, delayTics:2, arc:100,
                       fireSnd:"world/barrelx", profName:"Watcher death cascade")
    notes    RS_HKRedDeath sets **no `Speed` and no `Projectile`**, so despite
             being fired with A_CustomMissile it does not travel: it appears at
             the spawn offset and detonates on the next frame. The attack is
             therefore 21 stationary blasts scattered around the corpse, tighter
             and faster as it goes. MakeBurst's uniform delay flattens the 4/3/2/1
             acceleration -- 2 tics gives 42 total against CH's ~55.
             The four fixed openers exist to bracket the boss before the random
             ones fill in.
             **Then it spawns RS_WhitePE3** (PE.zs:1687) -- the death is a phase
             transition, not an end. That is not an attack and gets no row, but
             a profile built from this row should know the "death" is a spawn.

## H2. TIER 11 phase 2 -- RS_WhitePE3 ("The Pilot")  `PE.zs:1692`

Health 1000, Speed 46 -- fast and fragile after the shell breaks.

    ATTACK   RS_WhitePE3.Missile
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1769
    shape    MULTI
    payload  RS_DFlarePE2 x9  +  three A_CustomRailgun traces
    arc      18  (the flare triplet is angles 0, random(-3,3), random(-9,9);
                  the rail is pinpoint)
    timing   three identical beats of [5-tic aim, 3 flares on one tic, 5-tic
             rail]   (~35 tics total)
    damage   RS_DFlarePE2: DamageFunction (random(10,20)) each   [FX.zs:1724]
             rail: random(30,60) each, x3
    type     Fire (flares) / none (rail)
    sound    "weapons/firmfi" per flare (SeeSound); the rails are SILENT
    impact   flares: CBAL C-G + DeathSound "weapons/firex4", trailing
             RS_MFlareFX; rail: RGF_NOPIERCING red beam laying RS_DFlarePE at
             spawnofs_z 7
    trigger  Missile
    range    --
    mirrored no
    inherit  RS_DFlarePE2 (FX.zs:1717) is RS_DFlarePE with a LOOPING Spawn --
             that one difference is why it flies and the trail version does not
    profile  MakeBurst(proj:"RS_DFlarePE2", count:9, delayTics:10, arc:18,
                       fireSnd:"weapons/firmfi", profName:"Pilot flare volley")
             + MakeHitscan(spreadScale:0.0, profName:"Pilot red rail")
    notes    MULTI: a projectile spread and an instant trace interleaved three
             times, which is what makes the Pilot hard to trade with -- you
             dodge the flares into the rail. The flare triplet fires on 0-tic
             frames so all three land on one tic; the 10-tic `delayTics` above
             models the beat, not the triplet, and loses the on-tic grouping.
             `AttackSound "";` on the body (PE.zs:1731) is CH's explicit silence.

    ATTACK   RS_WhitePE3.DropBuff
    file     zscript/monsters/painelemental/RS_PainElemental.zs:1761
    shape    UNCLASSIFIED
    payload  RS_BufferWhitePE x1  +  RS_HealthFountainWhitePE x2
    arc      --  (buff beacon at random(+-64); fountains at random(+-266))
    timing   3,4,5 then one tic for both fountains
    damage   0
    type     --
    sound    --   (SILENT)
    impact   as RS_WhitePE2.DropBuff and .Fountains
    trigger  Walk   (A_Jump(24,"DropBuff") out of See, PE.zs:1749)
    range    ..526 / ..252
    mirrored no
    inherit  --
    profile  MakeRadial(radius:526, damage:0, heal:0, hitsAllies:true,
                        profName:"Pilot pack buff")
             + MakeSummon(summonCls:"RS_HealthFountainWhitePE", count:2, cap:0,
                          tierOffset:-4, profName:"Pilot fountains")
    notes    Phase 2 does BOTH support acts in one beat, off a WALK trigger --
             it does not need to be attacking to do them. `TNT1 AA 0` is 2
             frames, so two fountains.

**No attack role:** `RS_WhitePE3.Death` (`PE.zs:1790-1797`) -- A_Scream,
A_NoBlocking, a FLOATBOB clear, A_SetFloorClip, and a `-1` rest frame. The only
body in the family whose death fires nothing at all.

## H3. The escort drone -- RS_MiniSentinelPE  `FX.zs:1834`

A live monster (Health 70, PainChance 255) with its own attack. Twelve of them
are in the air at once.

    ATTACK   RS_MiniSentinelPE.Missile
    file     zscript/monsters/painelemental/RS_PainElementalFX.zs:2019
    shape    SCATTER
    payload  RS_DFlarePE2 x3
    arc      18  (angles 0, random(-3,3), random(-9,9))
    timing   1,1,1   (3 tics; 4-tic aim, 4-tic recovery)
    damage   DamageFunction (random(10,20)) each   [FX.zs:1724]
    type     Fire
    sound    "weapons/firmfi" per flare (SeeSound); the state is silent
    impact   CBAL C-G + "weapons/firex4"
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_DFlarePE2", count:3, delayTics:1, arc:18,
                       fireSnd:"weapons/firmfi", profName:"Sentinel flare burst")
    notes    Identical payload and geometry to one beat of RS_WhitePE3.Missile
             -- the Pilot fires what its drones fire. Reaching this state at all
             requires `A_Jump(8,"Angreh")` out of MoveIt (FX.zs:1874, a 3%
             chance per orbit tic); the rest of the time the drone is running
             one of seven A_Warp orbit patterns and cannot attack.

    ATTACK   RS_MiniSentinelPE.SpawnThing
    file     zscript/monsters/painelemental/RS_PainElementalFX.zs:2038
    shape    SINGLE
    payload  ArchvileFire x1  +  RS_RandomizerArc x1 (a monster RandomSpawner)
    arc      --
    timing   1,2   (3 tics)
    damage   --  (ArchvileFire's own A_Fire chain)
    type     Fire
    sound    "Crack/death"  (the drone's DeathSound)
    impact   RS_RandomizerArc (`zscript/monsters/lostsoul/RS_LostSoulFX.zs:1925`,
             CH Archviles.txt:3388) rolls a monster from the archvile summon
             table and spawns it
    trigger  Death   (A_Jump(32,"SpawnThing"), FX.zs:2034 -- 32/256 = 12.5%)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_RandomizerArc", count:1, cap:0,
                        tierOffset:-2, fireSnd:"Crack/death",
                        profName:"Sentinel death summon")
    notes    **KILLING A DRONE CAN SUMMON A MONSTER**, one time in eight. With
             twelve drones on a rebuild loop this is a steady trickle, and it is
             completely undocumented anywhere except this one A_Jump. The other
             87.5% of the time the drone spawns three RS_DeathBreathDI
             (harmless) and stops.

---

# I. CLASSES WITH NO ATTACK ROLE -- 24 of the 66 FX classes

Confirming this is a finding, not an omission. Each of these was opened and its
parents followed.

**The `RS_OverFlesh1` chain -- 12 classes, all zero damage** (`FX.zs:1257-1426`).
`RS_OverFlesh1` declares `Projectile` and sets no `Damage` and no
`DamageFunction`. Its 11 subclasses -- `RS_OverFlesh2`, `3`, `4`, `5`, `6`,
`RS_OverBigArm1`, `RS_OverBigArm2`, `RS_OverSmallArm1`, `RS_OverSmallArm2`,
`RS_OverHorn1`, `RS_OverHorn2` -- override **only** `States` (sprite frames).
Nothing in the chain adds damage. They are the Black boss's dismemberment.

**The `RS_Fleshspawngib1` chain -- 8 classes, all zero damage**
(`FX.zs:337-488`). Same shape: a damage-less `Projectile` base and 7 subclasses
(`gib2`, `gib2B`, `gib3`, `gib4`, `gib4B`, `gib5`, `gib6`) overriding only
`States`. `gib6` additionally sets `Speed 0`. The Brown PE's XDeath.
`RS_FleshSpawnGibs` (FX.zs:314) is the +NOCLIP dispatcher that fires all seven
and is itself inert.

**Decoration / infrastructure -- 4 more**

| Class | file:line | Why it has no attack role |
|---|---|---|
| `RS_SplashBrownPE` | FX.zs:216 | +CLIENTSIDEONLY, no Damage, Death is 4 fade frames. The **2** variant is the damaging one. |
| `RS_BrownPEDed` | FX.zs:291 | +NOCLIP +NOGRAVITY +NOINTERACTION. HADE I-L fade. |
| `RS_AbyssPEShadow` | FX.zs:578 | +NOINTERACTION afterimage. |
| `RS_AbyssBaronHandFire` | FX.zs:809 | +NOINTERACTION +NOCLIP hand flame. |
| `RS_RedPuff` | FX.zs:1023 | Lavaball trail, no Damage. |
| `RS_LoadPE3` | FX.zs:1127 | `Damage 0`, Speed 1 -- the telegraph half of Missile5. Listed here AND carried in its row because its ROLE is real even though its damage is nil. |
| `RS_BEESHOT` | FX.zs:1232 | `Damage 0`, +INVISIBLE -- pure summon delivery, carried in the Missile4 row for the same reason. |

Also non-attack: `RS_RageBuffPE` / `RS_PERageCtl` / `RS_HulkBuffPE` /
`RS_PEHulkCtl` (FX.zs:64-184, the buff items and their native controllers),
`RS_BundleRandom3` (FX.zs:1219, a RandomSpawner table, no states of its own),
`RS_BufferWhitePE` (FX.zs:1748, the buff beacon -- its effect is carried in the
DropBuff rows).

---

# J. ORPHANS -- imported, never fired, faithful to CH

Three classes in `RS_PainElementalFX.zs` are reachable from nothing:

| Class | file:line | Status |
|---|---|---|
| `RS_StormStrike1` | FX.zs:1543 | Never spawned. Serves only as the parent of StormBolt and StormBolt2. Damage 2, `lightning`, +RIPPER, `A_Explode(64,64,0)` per frame in Spawn -- if anything ever fired it, it would be one of the heaviest things here. |
| `RS_StormBolt` | FX.zs:1572 | Never spawned. A +FLOORHUGGER Hexen-bouncing ground crawler that fires `RS_StormBolt2` five times per loop and A_CountDowns from ReactionTime 35. |
| `RS_StormLite2` | FX.zs:1665 | Never spawned. `RS_StormLite1` with Speed 64 / Damage 10. |

**This is CH's, not ours.** Searched CH's whole decorate tree: `StormStrike1`,
`StormBolt` and `StormLite2` appear only as `ACTOR` definitions
(`thepains.txt:2534`, `:2560`, `:2644`) and in `StormBolt`'s own internal
`A_CustomMissile("StormBolt2",...)` lines. Nothing in CH fires them either.
`RS_StormBolt2` (FX.zs:1612) IS fired -- but only by `RS_StormBolt`, which is
itself dead, so it is dead by inheritance.

A cut ground-lightning attack for the Black boss, imported complete and left
unwired. If a player weapon ever wants a floor-hugging chain-lightning profile,
it is sitting here finished:
`MakeVolley(proj:"RS_StormBolt", count:1, profName:"BlackPE ground storm")`.

---

# UNRESOLVED

**U1 -- CH IS NOT AT THE PATH THE SPEC NAMES, AND THE ENGINE SOURCE IS NOT AT
THE PATH CLAUDE.md NAMES.** Both were used anyway, from the other documented
locations; both should be confirmed by the owner before the next family run.

* The spec (rs_35 section 4) and CLAUDE.md both give CH as
  `C:\Users\Command\Desktop\CH`. **That path does not exist on this machine**
  (`Test-Path` -> False). The CH pack used for every cross-check in this file is
  `E:\New folder\ART SOURCE\CH\`, which CLAUDE.md's "IMPORTING A MONSTER" section
  names as CH's own source. It is the right pack: `decorate\thepains.txt` is
  3,308 lines and **every one of the fourteen CH line citations in our headers
  lands exactly on the matching `ACTOR` declaration** (40 BrownPE2, 471 CyanPE2,
  609 AbyssPE2, 921 GrayPE2, 1045 FireBluPE2, 1156 CommonPE, 1223 GreenPE,
  1351 BluePE, 1481 PurplePE, 1635 YellowPE, 1769 RedPE, 1977 BlackPE2,
  2678 WhitePE2, 2811 WhitePE3). I am confident it is CH. I am not able to
  confirm it is the *same copy* the Desktop path used to hold.
* CLAUDE.md gives the engine source as `E:\DXR2`. **That path does not exist
  either.** The GZDoom source read for every engine fact above is
  `E:\UZDXREMA` (`src/`, `wadsrc/static/zscript/`). It is a GZDoom tree and its
  contents are self-consistent, but **I cannot verify it is the build RS_Main
  actually runs on**, and CLAUDE.md's own warning is that a check agreeing with
  itself proves nothing. Every engine claim in this file cites file:line so it
  can be re-checked against the right tree in one pass.

**U2 -- our tree and CH agree everywhere I checked, and I did not check
everything.** Diffed line-for-line against CH: BrownPE2's entire state block,
AbyssPE2's Pulse (including the missing 170 degrees), GrayPE2's states
(including the unreachable Boom1), RedPE's Default block (confirming no
`Damage`), SbombPE whole, the Purple `user_slowdownbuddy` counter, and every
`CMF_AIMOFFSET` call site. **Zero divergences found** other than the one
deliberate `GrayDemon2` -> `RS_GreyDemon2` heal, which is the recorded owner
ruling. The Cyan ice orbs (CH Spiders.txt:422/461), the Abyss siphon soul (CH
Barons.txt:1252) and RS_HKRedDeath were **not** diffed against their CH files --
they are third-file externals and I only verified our copies are internally
coherent.

**U3 -- three silences I could not follow to a lump.** CLAUDE.md is explicit
that an unresolved sound name is completely inert -- no error, no warning -- so
these are asserted only as "CH's SNDINFO does not define them", not as "they do
not play":
* `"holy/holy2"` (RS_PurplePE2 DeathSound, FX.zs:974). Our file header records
  that CH's SNDINFO defines `Holy2` and `Holy3` and never `holy/holy2`. I did
  not re-verify against SNDINFO.txt myself.
* `"weapons/none"` and `"weapons/gntidl"` (RS_StormBolt, FX.zs:1581-1582) --
  moot, the class is an orphan (section J).
* `"ICKYPEBR"`, `"WHPESEE"`, `"WHPEPAIN"`, `"WHPEACT"`, `"BEDsee"`, `"BEDpain"`,
  `"BEDded"`, `"Ahead/at"`, `"aheadsee"`, `"aheadded"` and the rest of the
  family's sound strings were **not** traced end-to-end to lumps. That is the
  audit CLAUDE.md demands before a family is called imported, and it is not what
  this pass was scoped to do. **No sound in this catalog should be trusted to
  actually play until that count is done with a denominator.**

**U4 -- shapes the closed vocabulary holds but the FACTORY cannot express.**
Recorded in the rows; listed together so they are one decision, not seven:
* **Multi-hit melee.** BrownPE2's five-hit flurry and every `A_CustomMeleeAttack`
  chain. `MakeMelee` has no hit count and no per-hit delay.
* **CHARGE.** FireBluPE2's ram and RedPE's dash. There is no charge factory;
  both are written as `MakeMelee` with the launch speed lost.
* **Non-uniform burst rhythm.** GreenPE's 5,4,3,2,1,0,1,2,3 gas whoosh and
  WhitePE2's 4,4,4,3,3,2,2,1,1 death cascade. `BurstDelayTics` is uniform, so
  both are recorded exact here and rounded in the call.
* **Monsters as burst payloads.** BrownPE2's death brood needs
  `MakeSummon`'s payload with `MakeBurst`'s delay and arc. Written as MakeBurst;
  the profile will treat a monster class as a projectile class.

**U5 -- three mechanics with no axis on RS_AttackProfile at all.** Not gaps in
my reading; gaps in the target format. Somebody has to decide these before the
rows can be built:
1. **Buff-item radius gives.** AbyssPE2's haste aura and the Watcher's
   rage/hulk/speed beacons. `MakeRadial` has `damage` and `heal` and no
   inventory payload.
2. **`PAF_NOSKULLATTACK`.** BluePE summons two souls and launches only the
   first. `MakeSummon` has no per-summon launch flag, so the two collapse.
3. **Purple's refilling cast budget.** `user_slowdownbuddy` is `+1` per cast and
   `-3` per Pain -- a budget that REFILLS WHEN THE MONSTER IS HURT.
   `MakeSummon.cap` is documented as a live-pack cap and is a different thing.
   `cap:7` is written in the row as the nearest honest number and it is not the
   same mechanic.

**U6 -- damage rolls that die at the factory boundary.** `MakeRadial` takes
`int damage`, and `MakeHitscan` takes no damage at all. Every row using them
carries the roll in the `damage` field and a flattened midpoint in the `profile`
call. Affected: PurplePE.Death `random(15,35)`, RedPE.Death `random(15,65)`,
AbyssBaronSoul.Boom `random(20,80)`, WhitePE2.Beams `random(30,60)`,
WhitePE3's three rails `random(30,60)`. **Do not read the flattened numbers in
those five profile lines as the values.** Per CLAUDE.md this is exactly the
"flattened roll that hides itself" failure, so it is named here rather than
left in the calls to be discovered later.

**U7 -- things I classified but am not certain about.**
* **`RS_GreenPE.Fart` as RAIN.** It is placed around the CASTER, is stationary,
  and does not fall. RAIN's definition says "around the target and falling".
  SCATTER's says "random angles inside a cone", which is worse. I picked RAIN
  and wrote out the discrepancy rather than coin a word, but if the seventeen
  files are reconciled and a self-centred-field token is added, this row and
  the two `MakeRadial` UNCLASSIFIED death blasts should move.
* **`RS_WhitePE2.Beams` / `RS_WhitePE3.Missile` as HITSCAN.** A_CustomRailgun is
  not one of the two functions HITSCAN names. Same instant-trace shape.
* **Six rows are UNCLASSIFIED** and each says why: AbyssPE2's haste aura,
  AbyssBaronSoul's detonation, PurplePE.Death, RedPE.Death, WhitePE2.DropBuff,
  HealthFountainWhitePE.See, WhitePE3.DropBuff. Four of those are "a radius
  effect with no projectile", which is one missing token, not four.

**U8 -- CH argument-order damage I did not attempt to resolve.** Three CH call
patterns put constants in the wrong parameter slot, verified byte-identical in
CH and therefore transcribed correctly by this import:
`A_CustomMissile(cls, h, ofs, CMF_AIMOFFSET, random(0,360), random(0,360))` --
the flag lands in `angle` and a random number lands in `flags`, producing a
randomised CMF_* bitmask per shot (FX.zs:1065, FX.zs:1538, and eight sites in
`RS_WhitePE2.Death`); and
`A_SpawnItemEx("RS_RedLSoul",...,128,SXF_NOCHECKPOSITION,178)` where
`SXF_NOCHECKPOSITION` (32) lands in `failchance` (FX.zs:1073). **I recorded what
the arguments actually do under the real signatures, but I did not run the game
to confirm the resulting behaviour**, and a randomised flag word is not
something a static read can fully predict. If any of those three rows is
rebuilt, watch it in-game first.

**U9 -- `RS_CyanPE2.Turtle` never returns.** `Turtle:` ends in `Loop;`
(PE.zs:439) with no exit. Once A_VileChase sends this monster into `Heal:` it
scales up, roots itself, and summons forever. I read this three times and it is
what the code says; CH's is the same. If that is a CH bug rather than a design,
it is not one I can adjudicate, and it materially changes what
"CyanPE.Turtle" is worth as a profile.

**U10 -- call-site count does not match the brief.** The task brief gave 162
call sites for this family; comment-stripped I count 174 attack lines in the
body file and 73 in the FX file. The two numbers are counting different things
(mine is lines, and neither is frames -- `FLSP FE 2 A_CustomMeleeAttack` is one
line, two frames, two hits). **Every row in this catalog counts FRAMES**, which
is what actually fires, and that is why several rows report higher counts than a
line-based read would give: BrownPE2's melee is 5 hits from 3 lines, GrayPE2's
death is 6 souls from 2 lines, SkullBundle3 births 4 souls from 1 line,
SplashBrownPE2 blasts 12 times from 6 lines.
