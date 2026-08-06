# CYBERDEMON (CH "CYBIES") — ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Field order and shape
vocabulary are the spec's; nothing here coins a word.

## Denominator — what was actually read

| | |
|---|---|
| Family | Cyberdemon / CH `CYBIES` |
| Source (monsters) | `zscript/monsters/cyberdemon/RS_Cyberdemon.zs` — 3,018 lines, read whole |
| Source (payloads) | `zscript/monsters/cyberdemon/RS_CyberdemonFX.zs` — 3,439 lines, read whole |
| Classes in the monster file | 24 (16 with states of their own, 7 cvar gates, 1 RandomSpawner) |
| Classes in the FX file | 100 |
| State labels read | 452 total — 245 in the monster file, 207 in the FX file |
| Monsters carrying attacks | 14 with attacks defined here + 2 escort minions whose attacks are wholly inherited from other families = 16 |
| **Attack rows written** | **80** |
| External classes opened to resolve payloads | 27, in 10 other family files (list at the end) |
| CH cross-check | `CH/decorate/CYBIES.txt`, 6,285 lines |

State labels were counted with `//` comments stripped. Every payload class named
by an attack was opened, including the ones our tree hosts in another family's
file, and including every parent class.

## Two conventions used throughout, declared so the composer can normalise

1. **MULTI wins on payload diversity; geometry goes in `arc` + `notes`.** The
   spec defines MULTI as "one attack that fires two or more DIFFERENT payload
   classes", which is a claim about payloads, while FAN/RING/BURST are claims
   about geometry. Where both apply the row says MULTI and the geometry word
   appears in `notes`. Pure decoration (muzzle flares, trails, tier icons,
   splash puffs) is **not** counted as a second payload — those are listed in
   `notes` with "deco, 0 damage" and the class was opened to prove it.
2. **`profile` factory names are derived mechanically from the shape word** —
   `MakeSingle / MakeFan / MakeBurst / MakeSalvo / MakeRing / MakeScatter /
   MakeMelee / MakeHitscan / MakeCharge / MakeVile / MakeCombo / MakeRain /
   MakeMulti`. The spec gives exactly one worked example (`MakeBurst`), so the
   rest are extrapolated on its parameter style (`proj:`, `count:`,
   `delayTics:`, `arc:`). If the real `RS_AttackProfile` factory names differ,
   a rename is mechanical; the arguments are the load-bearing part.

## Family-wide facts that would otherwise be repeated on every row

- **`A_CustomMissile` fires once per FRAME, not once per line.** `MMDR HI 4
  A_CustomMissile(...)` is TWO rockets. Every count below is frame-expanded;
  the raw line count is roughly half for the White Cybie's rocket chains.
- **`Rocket` resolves to `RS_Rocket2`.** `RS_Rocket2 : Actor replaces Rocket`
  (`RS_CyberdemonFX.zs:1309`) — CH's global rocket replacement. Anything below
  that says `Rocket` gets `Damage 20`, `Speed 20`, `+DEHEXPLOSION`,
  `+ROCKETTRAIL`, and a `DamageType` that flips `Fire`→`Normal` when
  `rs_ch_rawket == 1` (CH's default).
- **The five `Cyberdemon`-descended tiers share one melee.**
  `A_CustomMeleeAttack(random(35,90),"skeleton/melee","none")` +
  `A_VileAttack("bomb/boom",5,5,128,1.75)` + `A_RadiusThrust(3040,400)`.
  Purple raises the roll to `random(45,90)` and the vile blast to `10,10`;
  Blue lowers the vile thrust factor to `1.65` and raises the radius thrust to
  `8040`. It is one punch, one concussive burn, one shove — recorded as MELEE
  with the vile component spelled out, not split into two rows.
- **Tier-icon spawns are never attacks.** `RS_ColorTierIconCH*`, `RS_Splash11`,
  `RS_SplashAbyss`, `RS_SplashAbyss2`, `RS_SplashAbyssBubbleDemon`,
  `RS_RedThingsLS`, `RS_SparkPuff1`, `RS_Trail12`, `RS_GreeniesBR`,
  `RS_AbyssShotIdentifier`, `RS_CyanCybieHower`, `RS_AbyssCybieDecoFlame`,
  `RS_GlowBack`, `RS_RedSmoke`, `RS_PuffCybieRed`, `RS_RedPuff2`,
  `RS_CircleDrawMeteorCH*` — all opened, all carry no `Damage`,
  no `DamageFunction` and no `A_Explode`.

---

# TIER 13 — RS_BrownCybie2 ("ComposterDemon")

`zscript/monsters/cyberdemon/RS_Cyberdemon.zs:289` · CH `CYBIES.txt:69`
Health 7557 · Speed 17 · `+MISSILEMORE` · no `MeleeRange`/`MeleeThreshold` set
(engine default 64), so the `Melee` label is really a mid-range gate.

Range router: `Missile` → `A_JumpIfCloser(1200,"FirstChoice")`, else
`ClassicShot`. `FirstChoice` → `A_JumpIfCloser(600,"BigBoom")`, else
`A_Jump(255,"PoolOfGoo","PoolOfDrill","ClassicShot")`.

    ATTACK   RS_BrownCybie2.ClassicShot
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:366
    shape    MULTI
    payload  RS_BrownCybBasic x3  +  RS_GreenBalb2 x9 (aimed)  +  RS_GreenBalb2 x12 (lobbed)
    arc      heavy shot walks out: random(-1,1), random(-4,4), random(-12,12);
             globs random(-12,12) aimed / random(-15,15) lobbed
    timing   3 identical beats: [3 globs t0] [4 globs t0] [1 heavy] at 10, 8, 8 tics
    damage   RS_BrownCybBasic DamageFunction (random(60,120));
             RS_GreenBalb2 DamageFunction (random(15,30))
    type     Plasma (both)
    sound    "BROCYBA1" once at the start
    impact   BrownCybBasic: 3x A_Explode(random(10,80),128) over MISL B-D, plus
             6x RS_Gas14 poison cloud (Gas14 itself A_Explode(random(4,8)) x2),
             DeathSound "shadowbeast/pr1death".
             GreenBalb2: A_Explode(random(12,24),32) over BAL2 C-E,
             DeathSound "spit/spit2"
    trigger  Missile   (default branch >1200, and one of three at 600..1200)
    range    1200..  direct; also 600..1200 via FirstChoice's A_Jump(255)
    mirrored no
    inherit  --   (both payloads are direct Actor children)
    profile  MakeMulti(parts:[ MakeBurst(proj:"RS_BrownCybBasic", count:3, delayTics:8, spread:[1,4,12]),
                               MakeSalvo(proj:"RS_GreenBalb2", count:3, spread:12, ofsFwd:random(61,63), ofsSide:random(-10,-7), pitch:random(-3,3)),
                               MakeSalvo(proj:"RS_GreenBalb2", count:4, spread:15, placed:true, velFwd:random(8,33), velUp:random(1,4)) ], repeat:3)
    notes    The 12 lobbed globs are A_SpawnItemEx, not A_CustomMissile — thrown
             with velocity, Gravity 0.5, no aim. They are a real damage source,
             not gore. `8CYB FFF/FFFF 0` = 3 and 4 spawns per line.
             RS_GreenBalb also exists (random(10,30), bigger blast) but is only
             reached from the acid puddle's death, never from an attack state.

    ATTACK   RS_BrownCybie2.PoolOfGoo
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:391
    shape    RAIN
    payload  RS_BCybAcidPuddle x1  (via A_VileTarget — spawned ON the target)
    arc      --
    timing   one tic, after a 2+2+30 tic wind-up
    damage   puddle itself has no Damage; it damages entirely by A_Explode:
             A_Explode(random(1,8),64,0) x2 on the parent puddle, and each
             RS_BCybAcidPuddle2 satellite repeats A_Explode(random(1,8),64,0) x2
    type     Plasma
    sound    "BROCYBA2" at the start; puddle plays "brownCybie/DeepShot" and
             "monster/tenpn2" as it spreads
    impact   the puddle IS the impact: 14 RS_BCybAcidPuddle2 satellites at fixed
             offsets out to 182 units, then 9 live RS_GreenBalb bomblets
             (DamageFunction random(10,30), A_Explode(random(15,65),64)) thrown
             at random(0,359) on the puddle's own death
    trigger  Missile   (one of three via A_Jump(255) from FirstChoice)
    range    600..1200
    mirrored no
    inherit  --   (RS_BCybAcidPuddle2 is a sibling class, not a child)
    profile  MakeRain(proj:"RS_BCybAcidPuddle", count:1, atTarget:true, floorHug:true,
                      secondary:"RS_BCybAcidPuddle2", secondaryCount:14, tertiary:"RS_GreenBalb", tertiaryCount:9)
    notes    VOCABULARY DEVIATION, FLAGGED: A_VileTarget places the actor AT the
             target, it does not fall. RAIN is the only closed-set shape that
             covers spawn-placement delivery ("spawned above/around the target
             ... not aimed"), so it is used here with `atTarget:true` to
             distinguish it from the genuinely-falling RAINs below. See
             UNRESOLVED #4.

    ATTACK   RS_BrownCybie2.PoolOfDrill
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:397
    shape    MULTI
    payload  RS_BCybieGreenWave x1 (floor disc at own feet)  +  RS_BCybSlimeSet x5
    arc      slime spread ~90 total: 0, random(12,20), random(-20,-12),
             random(20,45), random(-45,-20)
    timing   wave at t=2+2 then 10 tics; the five slimes all on one tic after
             a further 20; 8-tic recover
    damage   RS_BCybieGreenWave DamageFunction (random(9,39));
             RS_BCybSlimeSet DamageFunction (random(11,33))
    type     Plasma (both)
    sound    "BROCYBA1"
    impact   BCybSlimeSet has no Death FX at all (Death is `TNT1 A 0; Stop;`) —
             it damages while alive by shedding RS_BCybSlimeSpi crawlers, each
             A_Explode(random(12,24),32,0) x6 on its own frames. On XDeath it
             throws 5 more crawlers at random(±32).
             BCybieGreenWave is a stationary GR3P disc, +FLATSPRITE +FLOORHUGGER,
             13 frames x 3 tics then scales to 2.5 and fades. SeeSound/DeathSound
             both explicitly "" — silent by design.
    trigger  Missile   (one of three via A_Jump(255)); also one of two after
             BigBoom fails its A_RadiusGive check
    range    600..1200
    mirrored yes   (the five slime angles are two mirrored pairs plus a centre)
    inherit  --
    profile  MakeMulti(parts:[ MakeSingle(proj:"RS_BCybieGreenWave", atSelf:true, ofsUp:8),
                               MakeFan(proj:"RS_BCybSlimeSet", count:5, arc:90, ofsFwd:32, jitter:true) ])
    notes    Half of each BCybSlimeSet becomes a seeker (A_Jump(128,"A1") →
             +SEEKERMISSILE, A_SeekerMissile(3,3)); the other half wanders
             (A_Wander x3 per loop). Same class, coin flip on spawn.

    ATTACK   RS_BrownCybie2.YesBoom
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:415
    shape    MULTI
    payload  RS_BCybExplosionSet x1 + RS_BCybExplosionSet2 x1 (counter-rotating
             spiral arms) + RS_BCybExplosionSet3 x4 (straight rays at 0/90/180/270)
             + RS_BCybieGreenWave x1 + RS_BCybieGreenExpand x4 (deco, 0 damage)
    arc      360 — two arms sweep +12/-12 degrees per tic while walking outward
             +12 units per tic to a 512 cap; four rays go straight out at speed 18
    timing   very long: 5+5x5 charge, 5x5 translation cycle, 3+9, then all six
             emitters on one tic, then 10+10+10+10+8x4+15 recover (~180 tics)
    damage   every emitter's damage is delivered by the RS_BCybieGreenWave2 nodes
             they shed: DamageFunction (random(6,35)) + A_Explode(random(5,50),
             128/96/64) on 13 frames each. RS_BCybieGreenWave DamageFunction
             (random(9,39)). The ExplosionSet actors themselves carry no Damage.
    type     Plasma
    sound    "BROCYBA2" + "brownCybie/DeepShot"; each GreenWave2 plays
             "weapons/rocklx" on spawn (SeeSound AND DeathSound AND an explicit
             NoDelay A_PlaySound — three copies of the same cue, as CH wrote it)
    impact   nodes explode where they land; the two spiral arms warp to master
             (SXF_SETMASTER) so the whole pattern tracks the monster
    trigger  Melee   (label `Melee:` falls through to `BigBoom:`)
    range    ..600, AND ONLY IF the target is inside 500 units without needing
             sight — A_RadiusGive("RS_BrCybCheck",500,RGF_PLAYERS|RGF_NOSIGHT,1)
             then A_JumpIfInTargetInventory. Fails → A_Jump(255) to PoolOfDrill
             or ClassicShot.
    mirrored yes   (ExplosionSet vs ExplosionSet2 are the same actor with the
                    angle step negated — that is the whole difference)
    inherit  --   (Set2 and Set3 are siblings of Set, not children; CH wrote all
                   three out in full)
    profile  MakeMulti(parts:[ MakeRing(proj:"RS_BCybExplosionSet", count:1, spinDeg:12, growPerTic:12, maxRadius:512, node:"RS_BCybieGreenWave2"),
                               MakeRing(proj:"RS_BCybExplosionSet2", count:1, spinDeg:-12, growPerTic:12, maxRadius:512, node:"RS_BCybieGreenWave2"),
                               MakeRing(proj:"RS_BCybExplosionSet3", count:4, arc:360, speed:18, node:"RS_BCybieGreenWave2"),
                               MakeSingle(proj:"RS_BCybieGreenWave", atSelf:true) ])
    notes    `bNOPAIN = true` for the whole cast and back to false at the end —
             this is the family's only true uninterruptible attack.
             Five A_SetTranslation calls name BRCybGren01..05 and BBCybGren06;
             those translations are defined in CH's TRNSLATE.txt but are NOT in
             this repo's, so the recolour does not happen here. BBCybGren06 is
             CH's own typo for BRCybGren06. Cosmetic only.

    ATTACK   RS_BrownCybie2.Death
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:455
    shape    SCATTER
    payload  RS_BCybieGreenWave2 x23  +  RS_GreenBalb2 x4
    arc      nodes at random(-16,16) x random(-16,16) around the corpse, z
             random(8,78); the four globs at random(0,359)
    timing   4 nodes @8t, 8 nodes @7t, 11 nodes @3t (≈121 tics of decay), then
             4 globs @6t
    damage   RS_BCybieGreenWave2 DamageFunction (random(6,35)) +
             A_Explode(random(5,50),128|96|64) per frame x13;
             RS_GreenBalb2 DamageFunction (random(15,30))
    type     Plasma
    sound    A_Scream → DeathSound "BROCYBDD"; each node "weapons/rocklx"
    impact   as above — the nodes ARE the impact
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  MakeScatter(proj:"RS_BCybieGreenWave2", count:23, radius:16, zRange:[8,78], delayTics:[8,7,3])
    notes    This is a substantial posthumous area denial, not gore — 23 nodes
             x 13 explode frames. It is the reason the corpse is dangerous.
             A_KillMaster fires mid-Death, so the spawn gate dies with it.

---

# TIER 12 — RS_CyanCybie2 ("Akinator")

`RS_Cyberdemon.zs:469` · CH `CYBIES.txt:788`
Health 8083 · Speed 31 · floats once it sees you · no Melee label.

Range router: `Missile` → `A_JumpIfCloser(1500,"MissileBarrage")`, else
`Sprayit`. **Note the polarity: the fine spray is the LONG-range attack and the
heavy ice is the CLOSE one.** That is CH's, verified at `CYBIES.txt:855`.

    ATTACK   RS_CyanCybie2.Sprayit
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:584
    shape    SCATTER
    payload  RS_CyanCybieSprayIce x88
    arc      8 wide (random(-4,4)) for the first 48, 4 wide (random(-2,2)) for
             the last 40; pitch jitter random(-4,4) on every shard,
             CMF_OFFSETPITCH|CMF_SAVEPITCH
    timing   4 lines of 12 at 1,0,1,0 tics; then 4 lines of 10 at 1,0,1,0 tics
             (≈4 tics of actual fire time, 88 shards)
    damage   DamageFunction (random(3,12))
    type     Ice
    sound    --   (SILENT. The shard declares DeathSound "" and no SeeSound;
                   only the one-off RS_CyanCybieGunFlare precedes it, and that
                   flare is +NOINTERACTION with no sound either.)
    impact   RIP1 C-B-A-C-B-A x6 frames, A_Explode(random(3,9),6) per frame —
             a six-tick 6-unit freeze burst. Gravity 1.5 is re-enabled on death
             (`bNOGRAVITY = false`) so the death FX drops.
    trigger  Missile   (default branch), and A_Jump(32) out of MissileBarrage
    range    1500..
    mirrored no   (symmetric jitter, not a mirrored pair)
    inherit  --
    profile  MakeScatter(proj:"RS_CyanCybieSprayIce", count:88, cone:8, pitchCone:8,
                         delayTics:1, ofsFwd:72, ofsSide:-30, speed:42)
    notes    Speed 42 with Gravity 1.5 — a fast, heavily-dropping stream, not a
             flat cone. Scale 0.33. This is the family's best candidate for a
             "sustained beam of chaff" weapon profile.
             The muzzle flare RS_CyanCybieGunFlare (revenant lane,
             `RS_RevenantFX.zs:2064`) is deco: no Damage, +NOINTERACTION.

    ATTACK   RS_CyanCybie2.MissileBarrage
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:598
    shape    MULTI
    payload  RS_CyanCybieBigIce2 x1 (speed 20), RS_CyanCybieBigIce x2 (speed 30),
             RS_CyanCybieBigIce3 x1 (speed 40)
    arc      0, randompick(-5,5), randompick(-15,15,7,0,-7), randompick(-15,15,7,0,-7)
    timing   (3 flare + 3 aim + 8 fire) x4 = 56 tics
    damage   DamageFunction (random(20,80))  — declared once on the base class
    type     Ice
    sound    SeeSound "weapons/rocklf" per shot
    impact   A_Scream, scale to (1.33,1.0), SSBL A-H, A_Explode(random(20,120),128),
             then 36 RS_SpikeCyanRev ice needles thrown in four 90-degree
             quadrants at random(16,60) forward velocity. DeathSound "Bomb/boom".
             ALL OF THIS IS INHERITED — BigIce2 and BigIce3 override nothing but
             `Speed`.
    trigger  Missile   (A_JumpIfCloser(1500) branch)
    range    ..1500
    mirrored no
    inherit  RS_CyanCybieBigIce  (`RS_CyberdemonFX.zs:745-746` — the two
             variants are one-line `{ Default { Speed 20; } }` subclasses; every
             FX, sound and the whole 36-needle death burst comes from the parent)
    profile  MakeBurst(proj:["RS_CyanCybieBigIce2","RS_CyanCybieBigIce","RS_CyanCybieBigIce","RS_CyanCybieBigIce3"],
                       count:4, delayTics:14, spread:15, ofsFwd:72, ofsSide:-30)
    notes    Deliberately staggered SPEED, not angle — three shells arriving out
             of order. That is the mechanic; flattening to one class loses it.
             A_Jump(32,"Sprayit") sits between shot 3 and shot 4.
             The 36 needles do almost nothing (A_Explode(random(0,1)) — checked
             at `RS_DemonFX.zs:153); they are a visual shatter.

    ATTACK   RS_CyanCybie2.Death
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:618
    shape    SINGLE
    payload  --   (bare A_Explode, no actor)
    arc      --
    timing   one tic, 32 tics into the death animation
    damage   A_Explode with no arguments = 128 damage, 128 radius (engine default)
    type     --   (A_Explode's default damagetype is 'none' → the actor's own)
    sound    A_Scream → DeathSound "cyber/death"
    impact   --
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  MakeSingle(explodeOnly:true, damage:128, radius:128)
    notes    Recorded because blank and absent must not look the same. Also
             spawns RS_CH_Cirno at the very end — a pickup, not an attack.

---

# TIER 9 — RS_AbyssCybie2 ("Unholy diver")

`RS_Cyberdemon.zs:629` · CH `CYBIES.txt:1112`
Health 12000 · Speed 15 · `+NOPAIN` from the start · no Melee label.

**Router quirk worth knowing before reading the rows.** `Missile` begins
`TERM E 0 A_Jump(255,"Bubble")` (`:741`) — 255/256. The `A_JumpIfCloser(300,
"Wave")` and `A_JumpIfCloser(1500,"Choices")` lines below it are reached
1 time in 256. The other three attacks are effectively reached only through
`Choices` (`A_Jump(255,"Bubble","Rocket","RedDed","Wave")`, itself reached from
Bubble's own `A_Jump(32)`) and from Wave's/RedDed's tail jumps. Verified
identical in CH at `CYBIES.txt:1218`. Recorded, not corrected.

    ATTACK   RS_AbyssCybie2.RedDed
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:747
    shape    HITSCAN
    payload  A_CustomRailgun — puff RS_WhiteFatRB3, spawnclass RS_WhiteFatRB4
    arc      --   (spread_xy 0, spread_z 0; lateral spawn offset -20)
    timing   1 + 18 aim, 8-tic fire, 6 recover
    damage   random(20,80) on the rail itself
    type     --   (railgun default; the puff carries DamageType "Plasma")
    sound    "AbyCyb/Atk" at volume 2, ATTN_NONE — audible map-wide
    impact   RS_WhiteFatRB3 (`RS_FatsoFX.zs:1499`): +ALWAYSPUFF,
             DamageFunction (random(30,95)), A_Explode(random(30,95),128),
             Radius_Quake(9,9,0,30,0), DeathSound "NETHERDE".
             RS_WhiteFatRB4 (`:1530`) is the trail bead:
             DamageFunction (random(15,30)) + A_Explode(random(10,20),88) x2,
             sparsity 0.4 / driftspeed 1.0 so the beam is a dense damaging line.
    trigger  Missile   (via Choices, or the 1-in-256 fallthrough)
    range    1500..  (fallthrough past both A_JumpIfCloser gates)
    mirrored no
    inherit  --
    profile  MakeHitscan(damage:random(20,80), puff:"RS_WhiteFatRB3", beadClass:"RS_WhiteFatRB4",
                         sparsity:0.4, driftSpeed:1.0, ofsSide:-20, pierce:false)
    notes    The ONLY railgun in the whole family — one A_CustomRailgun call in
             6,285 lines of CH CYBIES. `RGF_NOPIERCING` is set, so it stops at
             the first target. Both puff classes belong to the fatso lane and
             were opened there; neither is defined here.
             Tails into Rocket on A_Jump(64).

    ATTACK   RS_AbyssCybie2.Wave
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:754
    shape    FAN
    payload  RS_AbyCybWave x8  (two volleys of 4)
    arc      volley 1: random(5,25) / random(-1,1) / random(-25,-5) / random(-7,7)
             volley 2: random(10,30) / random(-5,5) / random(-30,-10) / random(-10,10)
             — a stepped ±30 fan with jitter, side offsets +30/0/-30/0
    timing   1+3+3, four shots at 1 tic each, 2 recover; repeat; 2 recover
    damage   DamageFunction (random(10,40))
    type     Melee   (yes — DamageType "Melee" on a projectile, CH's own)
    sound    "AbyCyb/Atk"; each wave SeeSound "holy3/holy3"
    impact   DeathSound "holy2/holy2", SSBL I-J for 12 tics each. In flight it
             sheds 18 RS_AbyCybWave2 (DamageFunction random(4,16), same Melee
             type) BEHIND itself at velocity 16 — the wave leaves a damaging
             wake, so the real footprint is much wider than the 8 heads.
    trigger  Missile   (A_JumpIfCloser(300) branch, or via Choices)
    range    ..300
    mirrored yes   (volley 2 mirrors volley 1's side offsets and angle signs)
    inherit  --   (AbyCybWave2 is a sibling, spawned not inherited)
    profile  MakeFan(proj:"RS_AbyCybWave", count:4, arc:60, delayTics:1, jitter:true,
                     wake:"RS_AbyCybWave2", wakeCount:18, repeat:2, mirrorRepeat:true)
    notes    `ProjectileKickBack 7000` — enormous knockback, the defining feel of
             this attack. Species "Cybie" + `+DONTHARMCLASS`.

    ATTACK   RS_AbyssCybie2.Rocket
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:774
    shape    BURST
    payload  RS_AbyssCybRocket x3
    arc      0, random(-8,8), random(-15,15) — widening
    timing   8 aim + 8 fire, three times (48 tics)
    damage   Damage 20   (bare constant, as CH wrote it)
    type     Fire
    sound    --   (no A_PlaySound in the state; the rocket's own
                   SeeSound "weapons/rocklf" is the only cue)
    impact   A_Explode (default 128/128) on MISL B, DeathSound "weapons/rocklx",
             then 33 RS_SplashAbyss2 sprays out to random(±252) and 2
             RS_SplashAbyssBubbleDemon — both deco, 0 damage, checked.
             Also 5x RS_SplashAbyssVile2 at random(±528) — that class is the
             ARCHVILE lane's (`RS_ArchvileFX.zs:1189`) and it exists.
    trigger  Missile   (via Choices, or A_Jump(64) out of RedDed)
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_AbyssCybRocket", count:3, delayTics:16, spread:[0,8,15],
                       ofsFwd:38, ofsSide:15)
    notes    `+SEEKERMISSILE` with A_SeekerMissile(2,2) every other tic — a weak
             but real homer, easy to miss when reading the state alone.

    ATTACK   RS_AbyssCybie2.Bubble
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:785
    shape    BURST
    payload  RS_AbyCybBubProj x2 per cycle, looping
    arc      pitch random(-9,0) then random(0,9) — a vertical, not lateral, pair
    timing   2 aim + 1 fire + 1, 2 aim + 1 fire + 1, then A_SpidRefire; loops
    damage   DamageFunction (random(1,12))
    type     Plasma
    sound    "AbyCyb/Atk" twice per cycle
    impact   the carrier has NO death FX (`Death: TNT1 A 0; Stop;`). It damages
             by shedding 4 RS_AbyCybBub per tic sideways at random(±64), each
             DamageFunction (random(1,8)) + A_Explode(random(5,10),32,0). It is
             a corridor-filler, not a bolt.
    trigger  Missile   (the 255/256 default branch)
    range    --   (no gate — this is what the abyss cybie almost always does)
    mirrored yes   (the two shots are a mirrored pitch pair, and the shed bubbles
                    alternate random(2,64) / random(-64,-2))
    inherit  --
    profile  MakeBurst(proj:"RS_AbyCybBubProj", count:2, delayTics:3, pitchPair:9,
                       ofsFwd:38, ofsSide:15, loop:"A_SpidRefire",
                       shed:"RS_AbyCybBub", shedPerTic:4, shedSpread:64)
    notes    +THRUACTORS on the carrier — it passes through everything and only
             its shed bubbles collide.

    ATTACK   RS_AbyssCybie2.Splash
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:723
    shape    UNCLASSIFIED
    payload  RS_SplashAbyssBubbleDemon x2  — 0 damage, verified
    arc      random(-8,128) x random(-8,128), angle random(-359,359)
    timing   one tic
    damage   --   (none)
    type     --
    sound    --
    impact   --   (deco)
    trigger  Walk   (the `Splash:` label; entered on water contact)
    range    --
    mirrored no
    inherit  --
    profile  --   (NOT a weapon profile — no damage anywhere in the chain)
    notes    Recorded ONLY so that a later reader does not have to re-derive
             that this is not an attack. It does contain
             `A_Jump(64,"Missile")`, so it is a real route INTO the attack
             router — which is why it is here rather than omitted.

    (No Death attack row. The Abyss Cybie's death throws RS_TerminatorHead,
     RS_TerminatorShoulder and RS_TerminatorArm. All three were opened
     (`RS_CyberdemonFX.zs:971/994/1019`): BounceType "Doom", two of them carry
     `+MISSILE`, and NONE of them declares `Damage`, so all three do 0. Gore.)

---

# TIER 8 — RS_GrayCybie2 ("Stoner Cybie")

`RS_Cyberdemon.zs:815` · CH `CYBIES.txt:1576`
Health 8888 · Speed 13 · `+NOPAIN` · no Melee label.

Router: `Missile` → `A_JumpIfHealthLower(3500,"BuffUP")`, then
`A_Jump(64,"Missiles1")`, then `A_Jump(64,"Missiles2")`, else the airstrike.

    ATTACK   RS_GrayCybie2.Missile   (the rockslide airstrike)
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:887
    shape    RAIN
    payload  RS_RockSlideCH1 x1 → RS_RockSlideDropCH x12+ → RS_RockSlideCHRand
             → one of RS_RockSlideCH2 / CH3 / CH4 / CH5 (equal 33 weights)
    arc      drops at random(-32,32) x random(-32,32) around the target, from
             z random(128,528) above it
    timing   6 aim + 8 "CybLow" + 8+8 marker + 2 + 12 to launch; the spawner then
             runs 2/1/1/1 tic beats, 3 drops per beat, with A_Jump(40,"Death")
             each loop — so length is random, ~4-15 beats
    damage   RS_RockSlideCH2 DamageFunction (random(75,155))
             RS_RockSlideCH3 DamageFunction (random(55,105))
             RS_RockSlideCH4 DamageFunction (random(45,90))
             RS_RockSlideCH5 DamageFunction (random(40,80))
    type     Melee   (all four)
    sound    "CybLow" on the wind-up; each rock SeeSound "monster/hamflr",
             DeathSound "moloch/thud"; RS_CHBSTarget beeps "prox/beep" twice
             at ATTN_NONE as the warning
    impact   CH2 and CH3 also A_Explode (random(60,90),52 and random(30,75),42)
             and throw 2-3 RS_WDRock4 pebbles (deco). CH4 and CH5 land dead.
             All four: Gravity 1.25, BounceType "Hexen", BounceCount 1,
             BounceFactor 0.7, +TOUCHY — one bounce, then they detonate on
             anything they touch.
    trigger  Missile   (default branch, ~1 in 4 after two A_Jump(64) gates)
    range    --   (A_CheckSight("See") aborts it if sight is lost mid-cast)
    mirrored no
    inherit  --   (the four rocks are four separate classes, not a hierarchy)
    profile  MakeRain(proj:"RS_RockSlideCHRand", count:"3 per beat, 4+ beats",
                      spawnZ:random(128,528), spread:32, atTarget:true,
                      table:["RS_RockSlideCH2","RS_RockSlideCH3","RS_RockSlideCH4","RS_RockSlideCH5"])
    notes    RS_CHBSTarget (`RS_ShotgunnerFX.zs:807`) is A_VileTarget'd TWICE
             before the real spawner — it is a telegraph marker, +NOINTERACTION,
             0 damage. Do not count it as a payload; DO keep it in a profile,
             because a beeping marker before a delayed strike is the whole
             readability of this attack.
             RS_RockSlideCH1 tracks the target by A_Warp(AAPTR_TRACER) every
             2 tics, so the strike zone follows a moving player.

    ATTACK   RS_GrayCybie2.Missiles1
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:893
    shape    FAN
    payload  RS_BaronOfDirtCH3 x3
    arc      4 total: 0, -4, +4  (side offsets -45, -48, -42)
    timing   6 aim + 9, then all three on one tic
    damage   DamageFunction (random(75,155))
    type     Melee
    sound    --   (state is silent; the boulder's SeeSound "monster/hamflr"
                   and repeated "Ice/Fly" in flight are the only cues)
    impact   DeathSound "moloch/thud", 12 dirt clods (deco). BounceType "Hexen",
             BounceCount 10, BounceFactor 0.95, Gravity 0.8 — it bounces down a
             corridor ten times at nearly full energy. Very high damage per hit.
    trigger  Missile   (A_Jump(64) branch)
    range    --
    mirrored yes   (-4/+4 with matching -48/-42 side offsets)
    inherit  --   (class lives in the BARON lane, `RS_BaronFX.zs:1108`)
    profile  MakeFan(proj:"RS_BaronOfDirtCH3", count:3, arc:8, delayTics:0, ofsFwd:54, ofsSide:-45)
    notes    A three-round tight cluster of long-lived bouncing boulders. The
             tightest arc in the family that still fires three things.

    ATTACK   RS_GrayCybie2.Missiles2
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:901
    shape    RING
    payload  RS_VileGroundSpike x7  →  RS_VileGroundSpikes2 (the damage)
    arc      absolute angles 0, 45, 90, 135, 215, 260, 305 (CMF_ABSOLUTEANGLE).
             **CH skips 180 and uses 215 rather than 180/225** — a lopsided
             seven-spoke ring, not eight. Verified in CH at CYBIES.txt:1650.
    timing   6 tics, then all seven on one tic, 8 recover
    damage   RS_VileGroundSpike itself: NONE (Alpha 0.01, no Damage — it is an
             invisible tracer). All damage is RS_VileGroundSpikes2:
             DamageFunction (random(1,10)) contact, plus
             **A_Explode(random(60,100),32,0) x3** as it erupts.
    type     Melee
    sound    "CybieLow" — **PROVEN MISSING IN CH.** CH's SNDINFO defines
             "CybLow" (SNDINFO.txt:453) and nothing else; the "CybieLow"
             spelling occurs at this one call site only. Silent in CH too.
    impact   the spike line lays a spike every 4 tics as it travels at speed 24;
             each spike waits (A_Jump(128,"WaitMore") → 30 or 45+ tics), scales
             up, then erupts for three 60-100 blasts. A delayed minefield.
    trigger  Missile   (A_Jump(64) branch, after Missiles1's gate)
    range    --
    mirrored no
    inherit  --   (both classes live in the ARCHVILE lane,
                   `RS_ArchvileFX.zs:1297` and `:1363`)
    profile  MakeRing(proj:"RS_VileGroundSpike", count:7, angles:[0,45,90,135,215,260,305],
                      absolute:true, floorHug:true, mine:"RS_VileGroundSpikes2", mineDelay:random(30,90))
    notes    THE HEAVIEST DAMAGE-PER-SECOND IN THE FAMILY and it is completely
             invisible until it erupts. Reading only the attack state reports
             "seven zero-damage tracers"; the damage is two classes deep and in
             another file.

    ATTACK   RS_GrayCybie2.Death
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:930
    shape    SCATTER
    payload  RS_HKRedDeath x27  (+ 5 Blood, gore)
    arc      the last 22 at random(1,50) fwd / random(-10,30) side /
             random(0,180) angle; the first 5 at fixed offsets
    timing   5 singles spread over ~40 tics, then 22 on consecutive 1-tic frames
    damage   A_Explode(random(5,10),42) each — RS_HKRedDeath declares no Damage
    type     Fire
    sound    "superdemon/snarl", A_Scream → DeathSound "superdemon/death",
             "superdemon/crash"; each burst "world/barrelx"
    impact   A_Burst("RS_RedThingsHK") shrapnel, deco
    trigger  Death
    range    --
    mirrored no
    inherit  --   (class lives in the ZOMBIEMAN lane, `RS_ZombiemanFX.zs:844`)
    profile  MakeScatter(proj:"RS_HKRedDeath", count:27, cone:180, delayTics:1, damage:random(5,10), radius:42)
    notes    27 small barrel-pops, not one big one. Same construct on the Yellow
             and White Cybies' deaths (rows below) — one shared profile serves
             all three, at counts 27 / 5 / 8.

---

# TIER 7 — RS_FireBluCybie2

`RS_Cyberdemon.zs:952` · CH `CYBIES.txt:1947`
Health 7777 · Speed 19 · MeleeThreshold 200 · MeleeRange 75 ·
`DamageFunction (random(15,70))` on the actor — this is its ram/contact damage
and it is what `Missile2`'s A_SkullAttack delivers.

Router: `Missile` → `A_JumpIfCloser(900,"Maybe")` else `Missile1`;
`Maybe` → `A_Jump(256,"Missile1","Missile2")`.

    ATTACK   RS_FireBluCybie2.Melee
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1035
    shape    MELEE
    payload  --   (A_CustomMeleeAttack + A_VileAttack + A_RadiusThrust)
    arc      --
    timing   8 wind-up, 8 punch, 1 blast, 2 shove; falls through to Splash
    damage   A_CustomMeleeAttack(random(35,90))  — melee hit
             A_VileAttack("bomb/boom",5,5,128,1.75) — 5 direct + 5 blast at
             radius 128, thrust factor 1.75
    type     --   (CustomMeleeAttack damagetype "none"; VileAttack default)
    sound    "skeleton/melee" (miss sound "none"), "bomb/boom" on the blast
    impact   A_RadiusThrust(3040,400) launches everything in a 400 radius,
             including the player's own corpse arc
    trigger  Melee   (MeleeRange 75, MeleeThreshold 200)
    range    ..75
    mirrored no
    inherit  --
    profile  MakeMelee(damage:random(35,90), sound:"skeleton/melee",
                       blast:{damage:5, splash:5, radius:128, thrust:1.75, sound:"bomb/boom"},
                       knockback:{force:3040, radius:400})
    notes    Chains into Splash (below) unconditionally. This exact melee is
             shared by Common, Green, Blue, FireBlu and Purple — see the
             family-wide note; only the numbers differ.

    ATTACK   RS_FireBluCybie2.Missile2
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1047
    shape    CHARGE
    payload  the monster itself (A_SkullAttack(30)) + RS_FireBluCacoBall2 x6
             shed along the flight path
    arc      --
    timing   2 wind-up, 2 launch, then 6 shed frames at 1 tic each, 2 recover
    damage   ram: the actor's own DamageFunction (random(15,70));
             shed fire: RS_FireBluCacoBall2 DamageFunction (random(5,23))
    type     ram --; shed fire = Fire
    sound    --   (state is silent; each shed ball SeeSound "imp/attack")
    impact   each shed ball A_Explode(random(3,10),64) on ELEVEN frames as it
             burns out — a lingering 64-unit fire trail behind the charge.
             DeathSound "imp/shotx".
    trigger  Missile   (A_JumpIfCloser(900) → A_Jump(256) coin flip)
    range    ..900
    mirrored no
    inherit  --   (RS_FireBluCacoBall2 is the CACODEMON lane's,
                   `RS_CacodemonFX.zs:724`)
    profile  MakeCharge(speed:30, ramDamage:random(15,70), trail:"RS_FireBluCacoBall2",
                        trailCount:6, trailDelayTics:1)
    notes    A_SkullAttack(30) means speed 30 toward the target. The 6 shed
             balls are spawned at the monster's own position on consecutive
             tics, so they lay a burning line exactly along the charge.

    ATTACK   RS_FireBluCybie2.Missile1
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1058
    shape    SINGLE
    payload  RS_FireBluCybMiss x1
    arc      random(-1,1)
    timing   6 aim, 12 fire
    damage   DamageFunction (random(20,90))
    type     Plasma
    sound    SeeSound "Spell/spellCast1"
    impact   A_Explode(random(5,50),256) TWICE (radius 256 — the widest single
             blast in the family), plus a RING of 12 RS_FireSGguy2 fire gouts at
             30-degree steps, each DamageFunction (random(5,15)) + A_Explode
             (random(3,9),64) x8 and (random(5,15),64) x3.
             DeathSound "Crack/death".
    trigger  Missile   (default branch beyond 900, or the coin flip inside 900)
    range    900..  direct, ..900 via Maybe
    mirrored no
    inherit  --   (RS_FireSGguy2 is the ZOMBIEMAN lane's,
                   `RS_ZombiemanFX.zs:785`)
    profile  MakeSingle(proj:"RS_FireBluCybMiss", spread:1, ofsFwd:42, ofsSide:-9,
                        impactRing:{proj:"RS_FireSGguy2", count:12, arc:360})
    notes    `+SEEKERMISSILE`, A_SeekerMissile(5,2) every other tic, and it
             sheds RS_FireBluCacoBall2 on the alternate frames — so the missile
             ALSO lays a fire trail on the way in. Scale 1.5, Alpha 0.95.
             The single biggest "one shot, big consequences" payload in the
             family and the best candidate for a rocket-class profile.

    ATTACK   RS_FireBluCybie2.Splash
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1062
    shape    RING
    payload  RS_FireBluCacoBall x3
    arc      360 — angle offsets 0, 120, 240 (relative to facing)
    timing   5 wind-up, all three on one tic, 3 recover
    damage   DamageFunction (random(5,40))
    type     Plasma
    sound    --   (state is silent; each ball SeeSound "imp/attack")
    impact   A_Explode(random(5,15),128) on THREE frames. BounceType "Hexen",
             BounceCount 4, BounceFactor 0.9, and a 1-in-8 chance per loop of
             A_Stop + a random ±60 turn + a 8-unit re-thrust — it caroms
             unpredictably. DeathSound "imp/shotx".
    trigger  Melee (fallthrough from the Melee state) AND Pain (A_Jump(128))
    range    --
    mirrored no
    inherit  --   (CACODEMON lane, `RS_CacodemonFX.zs:684`)
    profile  MakeRing(proj:"RS_FireBluCacoBall", count:3, arc:360, delayTics:0)
    notes    Reached from TWO triggers — it is both the melee follow-through and
             a coin-flip pain response. A three-way bouncing burst is a good
             "get off me" profile.

---

# TIER 1 — RS_CommonCybie

`RS_Cyberdemon.zs:1088` · CH `CYBIES.txt:2150` · `class RS_CommonCybie : Cyberdemon`
Health/Damage inherited from the engine's Cyberdemon. MeleeThreshold 200 ·
MeleeRange 75 · Scale 1.1. **No Death state of its own — it inherits
Cyberdemon's.**

    ATTACK   RS_CommonCybie.Melee
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1134
    shape    MELEE
    payload  --
    arc      --
    timing   8 wind-up, 8 punch, 1 blast, 2 shove; then `Goto Missile+7`
    damage   A_CustomMeleeAttack(random(35,90));
             A_VileAttack("bomb/boom",5,5,128,1.75)
    type     --
    sound    "skeleton/melee", "bomb/boom"
    impact   A_RadiusThrust(3040,400,RTF_NOTMISSILE)
    trigger  Melee
    range    ..75
    mirrored no
    inherit  Cyberdemon (engine)
    profile  MakeMelee(damage:random(35,90), sound:"skeleton/melee",
                       blast:{damage:5, splash:5, radius:128, thrust:1.75, sound:"bomb/boom"},
                       knockback:{force:3040, radius:400, notMissile:true})
    notes    `Goto Missile+7` lands on the cvar check + the final rocket, not on
             the top of Missile. Frame-indexed, and `TNT1 AA 0` at Missile+1
             counts as TWO — that is why the offset is 7 and not 5.

    ATTACK   RS_CommonCybie.Missile
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1141
    shape    BURST
    payload  Rocket x3   (→ RS_Rocket2, see the family-wide note)
    arc      random(-1,1), random(-2,2), then 0
    timing   6 aim, 12 fire, 12 aim, 12 fire, 12 aim, 12 fire
    damage   Damage 20  (bare constant on RS_Rocket2, as CH wrote it)
    type     Fire, flipped to Normal when rs_ch_rawket == 1 (CH's default)
    sound    --   (the rocket's SeeSound "weapons/rocklf" only)
    impact   A_Explode (default, +DEHEXPLOSION) on MISL B; DeathSound
             "weapons/rocklx"; +ROCKETTRAIL
    trigger  Missile
    range    --   (no range gate at all)
    mirrored no
    inherit  RS_Rocket2 : Actor replaces Rocket  (`RS_CyberdemonFX.zs:1309`)
    profile  MakeBurst(proj:"Rocket", count:3, delayTics:24, spread:[1,2,0],
                       ofsFwd:[42,42,60], ofsSide:[-9,-9,-25])
    notes    **KNOWN FINDING, SETTLED — DO NOT RE-LITIGATE.** The third shot
             replaces CH's `ACS_NamedExecuteWithResult("CybMissile",1)`.
             CH's own ACS source (`CHACS.acs:9` → `miscFuncs.acs:112-115`)
             reads `if(rand){ random(1, sml_t); }` and DISCARDS the result, so
             the lead time stays 0 and every lead term collapses onto the
             target's current position. **CH's cyberdemon does not lead.** A
             plain aimed `A_CustomMissile("Rocket",60,-25,0)` at CH's own
             offsets is FAITHFUL, not a substitution. The full derivation is in
             the comment at the call site.
             Line-count check against CH: CH has 3 literal
             `A_CustomMissile("Rocket")` and ours has 4; the 4th is exactly this
             resolved ACS call. Expected and accounted for.

    ATTACK   RS_CommonCybie.Miss2
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1173
    shape    SINGLE
    payload  Rocket x1   (→ RS_Rocket2)
    arc      random(-4,4)
    timing   12 tics
    damage   Damage 20
    type     Fire / Normal per rs_ch_rawket
    sound    --
    impact   as above
    trigger  Missile   (only when `rs_ch_intercept == 1`; CH: CallACS("CH_Intercept"))
    range    --
    mirrored no
    inherit  RS_Rocket2
    profile  MakeSingle(proj:"Rocket", spread:4, ofsFwd:42, ofsSide:-9)
    notes    The cvar branch. Default is 0, so this is the branch a stock game
             never takes. It exists to make the third shot a wide unaimed shot
             instead of the intercept attempt.

---

# TIER 2 — RS_GreenCybie

`RS_Cyberdemon.zs:1181` · CH `CYBIES.txt:2213` · `: Cyberdemon`
Health 5000 · Speed 16 · MeleeThreshold 200 · MeleeRange 75.

    ATTACK   RS_GreenCybie.Melee
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1237
    shape    MELEE
    payload  --
    arc      --
    timing   8 + 8 + 1 + 2; then `Goto Missile+6`
    damage   A_CustomMeleeAttack(random(35,90)); A_VileAttack("bomb/boom",5,5,128,1.75)
    type     --
    sound    "skeleton/melee", "bomb/boom"
    impact   A_RadiusThrust(3040,400,RTF_NOTMISSILE)
    trigger  Melee
    range    ..75
    mirrored no
    inherit  Cyberdemon (engine)
    profile  MakeMelee(damage:random(35,90), sound:"skeleton/melee",
                       blast:{damage:5, splash:5, radius:128, thrust:1.75, sound:"bomb/boom"},
                       knockback:{force:3040, radius:400, notMissile:true})
    notes    `Missile+6` is the twin-rocket finisher, not the top of Missile.

    ATTACK   RS_GreenCybie.Missile
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1244
    shape    BURST
    payload  RS_SplashRocket x4
    arc      random(-1,1) @12t, random(-4,4) @12t, then a mirrored PAIR on one
             tic: random(1,13) and random(-13,-1)
    timing   6 aim, 12, 10 aim, 12, 10 aim, 12, then the pair at t0
    damage   Damage 17  (bare constant)
    type     Fire
    sound    --
    impact   A_Explode (default, +DEHEXPLOSION) + DeathSound "weapons/rocklx",
             then 7 RS_Gas14 poison clouds thrown at random(±359), each
             A_Explode(random(4,8)) x2. +ROCKETTRAIL, and it lays a Gas14 every
             3 tics IN FLIGHT as well.
    trigger  Missile
    range    --
    mirrored yes   (the last two shots are an explicit ±13 mirrored pair)
    inherit  --   (RS_Gas14 is the SHOTGUNNER lane's, `RS_ShotgunnerFX.zs:260`)
    profile  MakeBurst(proj:"RS_SplashRocket", count:4, delayTics:22, spread:[1,4,13],
                       finalPairMirrored:true, ofsFwd:42, ofsSide:-9,
                       trail:"RS_Gas14", impactCloud:{proj:"RS_Gas14", count:7})
    notes    A three-beat rocket burst that ends on a fork. The gas cloud is the
             point of the variant — a rocket that leaves area denial where it
             lands.

---

# TIER 3 — RS_BlueCybie

`RS_Cyberdemon.zs:1271` · CH `CYBIES.txt:2357` · `: Cyberdemon`
Health 5800 · Speed 18 · MeleeThreshold 200 · MeleeRange 75.
Carries an ammo counter: `RS_SpamComboCB` (Inventory, MaxAmount 9).

    ATTACK   RS_BlueCybie.Melee
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1332
    shape    MELEE
    payload  --
    arc      --
    timing   8 + 8 + 1 + 2; then `Goto Missile`
    damage   A_CustomMeleeAttack(random(35,90)); A_VileAttack("bomb/boom",5,5,128,1.65)
    type     --
    sound    "skeleton/melee", "bomb/boom"
    impact   A_RadiusThrust(**8040**,400,RTF_NOTMISSILE) — more than double the
             family's usual 3040
    trigger  Melee
    range    ..75
    mirrored no
    inherit  Cyberdemon (engine)
    profile  MakeMelee(damage:random(35,90), sound:"skeleton/melee",
                       blast:{damage:5, splash:5, radius:128, thrust:1.65, sound:"bomb/boom"},
                       knockback:{force:8040, radius:400, notMissile:true})
    notes    The launcher variant of the family melee: lower burn thrust, far
             higher physical shove.

    ATTACK   RS_BlueCybie.Missile
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1348
    shape    BURST
    payload  RS_SwooshCB x3   (+ RS_BluCybFX x7 — DECO, 0 damage, verified)
    arc      random(-4,4), random(-7,7), random(-1,1)
    timing   4 flares at 3,3,3,4; then aim 3 + 1, and three shots at 2 tics with
             5-tic gaps
    damage   DamageFunction (random(10,60))
    type     Plasma
    sound    "Spell/Lightn" at vol 2.7, then "Litn/litn2" on channel 1 at vol 2.5
    impact   BFE1 A-F, A_Explode(random(10,60),124), DeathSound "weapons/bfgx".
             In flight it lays RS_SwooshCBTR (hellknight lane,
             `RS_HellKnightFX.zs:707`), which itself A_Explode(random(5,20),32)
             and spawns RS_SwooshCBTR2 for another A_Explode(random(5,15),32) —
             so the beam has a damaging wake, two classes deep.
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_SwooshCB", count:3, delayTics:7, spread:[4,7,1],
                       ofsFwd:30, ofsSide:-9, muzzle:"RS_BluCybFX", muzzleCount:7,
                       wake:"RS_SwooshCBTR")
    notes    **RS_BluCybFX IS NOT A PAYLOAD.** It is fired with A_CustomMissile,
             which reads like an attack, but the class (`RS_HellKnightFX.zs:761`)
             has Speed 1, no Damage, and a 6-frame PLSE animation. It is a muzzle
             flare. Seven of the ten A_CustomMissile calls in this state are it.
             The state loops via `Goto Missile+8` (frame index 8 = the aim
             before the first swoosh) after A_MonsterRefire(80,"See"), banking
             one RS_SpamComboCB per pass; at 7 it goes to Finish.

    ATTACK   RS_BlueCybie.Art
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1369
    shape    SINGLE
    payload  RS_BluCybArt x1   (+ RS_BluCybFX x9 — deco)
    arc      random(-20,20)
    timing   nine flares at 0,6,5,4,3,3,2,2 tics (accelerating charge), the ball
             on t0, then 16 + 6 recover
    damage   DamageFunction (random(10,60))
    type     Plasma
    sound    --   (the state plays nothing; SeeSound "Litn/litn3" on the ball)
    impact   BFE1 A-F, A_Explode(random(20,60),102), DeathSound "weapons/bfgx"
    trigger  Missile   (A_Jump(82) out of the Missile loop)
    range    --
    mirrored no
    inherit  --
    profile  MakeSingle(proj:"RS_BluCybArt", spread:20, ofsFwd:64, ofsSide:-9,
                        chargeFlares:{proj:"RS_BluCybFX", count:9, delayTics:[6,5,4,3,3,2,2]})
    notes    `+SEEKERMISSILE` (A_SeekerMissile(3,1) in Spawn, tightening to
             (6,3) in Bounce), `+BOUNCEONWALLS`, `+USEBOUNCESTATE`,
             BounceType Hexen, BounceCount 2, **BounceFactor 1.5** — it
             ACCELERATES off walls and homes harder afterwards. `+EXTREMEDEATH`.
             The accelerating flare ramp is the telegraph; keep it in the profile.

    ATTACK   RS_BlueCybie.Finish
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1390
    shape    SINGLE
    payload  RS_SwooshCB2 x1   (+ RS_BluCybFX x5 — deco)
    arc      0
    timing   2 + 11 + 9 aim, then flares at 6,6,10,6,6, then the shot at 2
    damage   DamageFunction (random(20,70))
    type     Plasma
    sound    "cyber/sight", then "Spell/Lightn" at vol 3 and again at 2.7
    impact   A_Explode(random(20,70),124), DeathSound "weapons/bfgx"
    trigger  Missile   (only at RS_SpamComboCB >= 7)
    range    --
    mirrored no
    inherit  --
    profile  MakeSingle(proj:"RS_SwooshCB2", ofsFwd:30, ofsSide:-9,
                        spray:{proj:"RS_PlasmaBallSP5", count:18, perLoop:true, arc:360})
    notes    **This is a charged finisher gated on 7 banked shots** — the only
             ammo-metered attack in the family, and the best template for a
             "spend your stacks" weapon profile. `A_TakeInventory("RS_SpamComboCB",7)`
             pays for it.
             IN FLIGHT the projectile sprays **18 RS_PlasmaBallSP5 per Spawn
             loop iteration** at random(0,360) angle and pitch — a continuously
             shedding orb, not a bolt. `A_ChangeFlag("Painless",TRUE)` brackets
             it; PAINLESS is not a real GZDoom flag, so the call is a logged
             no-op in CH too. Not "fixed" — fixing it would invent behaviour.

    ATTACK   RS_BlueCybie.Shockwave
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1400
    shape    RING
    payload  RS_PlasmaBallSP5 x140
    arc      360 in both axes — angle random(0,360) with CMF_AIMDIRECTION,
             pitch random(0,360)
    timing   ONE TIC. All 140 on a single 0-tic frame run, then 4 tics recover.
    damage   DamageFunction (random(3,7))  — INHERITED
    type     Plasma  — INHERITED
    sound    --
    impact   PLSE A-E, DeathSound "weapons/plasmax" — INHERITED
    trigger  Pain   (A_Jump(64) from the Pain state)
    range    --
    mirrored no
    inherit  **RS_PlasmaBallSP5 : RS_PlasmaBallSP4** (`RS_CacodemonFX.zs:160`).
             The child adds ONLY `Species "Cybie"` and `+DONTHARMCLASS`.
             Every number above — damage, type, speed 9, scale 0.25, the death
             frames, the death sound — is on the parent at
             `RS_CacodemonFX.zs:132`. Reading the child alone reports a
             projectile with no damage and no impact.
    profile  MakeRing(proj:"RS_PlasmaBallSP5", count:140, arc:360, pitchArc:360,
                      delayTics:0, ofsFwd:53, ofsSide:random(-12,12))
    notes    The single largest projectile count in the family and a pure
             spherical burst. Frame count verified 140 in BOTH trees
             (CH CYBIES.txt:2477). Cheap per-ball, enormous in aggregate — this
             is the "get hit, explode outward" profile.

---

# ESCORT — RS_SpecialHK (Purple Cybie's guard, no tier token)

    ATTACK   RS_SpecialHK.*
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1419
    shape    UNCLASSIFIED
    payload  RS_HKBolt2, RS_PurpFire2  (all from the parent)
    arc      see the HELLKNIGHT family catalog
    timing   see the HELLKNIGHT family catalog
    damage   see the HELLKNIGHT family catalog
    type     see the HELLKNIGHT family catalog
    sound    see the HELLKNIGHT family catalog
    impact   see the HELLKNIGHT family catalog
    trigger  Missile, Melee
    range    --
    mirrored --
    inherit  **RS_PurpleHK** (`zscript/monsters/hellknight/RS_HellKnight.zs:1264`)
    profile  --   (belongs to the Hell Knight catalog, not this one)
    notes    THIS CLASS OVERRIDES ONLY `See`. It changes Health to 500, Speed to
             11, strips `-BOSSDEATH`/`-COUNTKILL`, and adds a leash
             (`A_JumpIfMasterCloser(1000)` → `A_Warp(AAPTR_MASTER,...)`).
             Its `Melee`, `Missile`, `Bolt3`, `Bolt4`, `Fire3` and `Fbreath`
             states are 100% RS_PurpleHK's. Cataloguing them here would create
             duplicate rows when the seventeen files compose. Recorded as a
             pointer, deliberately.
             Spawned x4 by RS_PurpleCybie's `KillIt` state on first spawn.

---

# TIER 4 — RS_PurpleCybie

`RS_Cyberdemon.zs:1453` · CH `CYBIES.txt:2699` · `: Cyberdemon`
Health 6400 · Speed 13 · MeleeThreshold 200 · MeleeRange 86 · Scale 1.33.

Router: `Missile` → `A_JumpIfCloser(1200,"BarrageOr")` else `LongSpam`;
`BarrageOr` → `A_Jump(255,"Barrage","RocketCombo")`.

    ATTACK   RS_PurpleCybie.Melee
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1520
    shape    MELEE
    payload  --
    arc      --
    timing   8 + 8 + 1 + 2; then `Goto RocketCombo`
    damage   A_CustomMeleeAttack(random(45,90));
             A_VileAttack("bomb/boom",**10,10**,128,1.75)
    type     --
    sound    "skeleton/melee", "bomb/boom"
    impact   A_RadiusThrust(3040,400,RTF_NOTMISSILE)
    trigger  Melee
    range    ..86
    mirrored no
    inherit  Cyberdemon (engine)
    profile  MakeMelee(damage:random(45,90), sound:"skeleton/melee",
                       blast:{damage:10, splash:10, radius:128, thrust:1.75, sound:"bomb/boom"},
                       knockback:{force:3040, radius:400, notMissile:true})
    notes    The heaviest of the five shared melees: higher floor on the punch
             and double the vile blast. Chains straight into a rocket.

    ATTACK   RS_PurpleCybie.Barrage
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1536
    shape    SCATTER
    payload  RS_CBWave x34   (two identical volleys of 17)
    arc      opens at random(-15,15) with pitch random(-15,15) x4, then a
             centred random(-1,1), then MIRRORED PAIRS widening
             ±5, ±9, ±13, ±15, ±15, ±25 (2 shots each)
    timing   per volley: 4 aim, 4 on t0, 1 @6t, then 6 pairs at 1 tic each,
             8 recover; then repeat
    damage   DamageFunction (random(10,30))
    type     Fire
    sound    "Spell/SpellCast1" on channel 4 at vol 3.1, once per volley;
             each wave SeeSound "Fire/fire4"
    impact   BAL2 C-E with A_SetScale(1.1), A_SetTranslucent(0.4),
             A_Explode(random(5,20),88), DeathSound "Spell/Impact1"
    trigger  Missile   (via BarrageOr's A_Jump(255))
    range    ..1200
    mirrored yes   (twelve of the seventeen shots are six explicit mirrored pairs)
    inherit  --
    profile  MakeScatter(proj:"RS_CBWave", count:17, cone:50, delayTics:1,
                         widening:[15,1,5,9,13,15,15,25], ofsFwd:42, ofsSide:-9, repeat:2)
    notes    **Speed 4, FastSpeed 4, +FLOATBOB, and A_ScaleVelocity(1.5) on
             every one of its four Spawn frames.** These are slow drifting fire
             blobs that accelerate as they travel, not fast shots — the
             widening pattern makes an expanding curtain the player has to walk
             around. `+EXPLODEONWATER`. The acceleration is the mechanic; a
             profile that fires them at a fixed speed is a different weapon.

    ATTACK   RS_PurpleCybie.LongSpam
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1559
    shape    MULTI
    payload  RS_OrbCB x6  +  RS_PurpleWorryCB x1 (A_VileTarget, at the target)
    arc      orbs at -3, +15, -15, +11, -11, +3 — three mirrored pairs opening
             from centre then closing
    timing   22 aim; orbs at 3,2,2,1,1,1; 4 + 10 + 8 + 4; the bomb at 8;
             8 for A_MonsterRefire(64,"See"); loops
    damage   RS_OrbCB DamageFunction (random(5,15));
             RS_PurpleWorryCB has NO Damage — it damages by
             A_Explode(random(40,90),128) on its Death
    type     orbs Plasma (inherited default); bomb --
    sound    "Spell/SpellCast1" channel 4, vol 3.1; the bomb SeeSound "gas/gas1"
    impact   OrbCB: DeathSound "Fire/fire5", BAL1 C-E. It sheds RS_OrbCB2 every
             tic (a second seeker at Speed 128, no damage of its own).
             PurpleWorryCB: hovers 56 tics (SBFX HIJK x2 at 7 tics), then
             A_Scream, A_SetScale(3,0.45), A_Explode(random(40,90),128).
    trigger  Missile   (default branch beyond 1200)
    range    1200..
    mirrored yes   (the six orbs are three mirrored pairs)
    inherit  --
    profile  MakeMulti(parts:[ MakeFan(proj:"RS_OrbCB", count:6, arc:30, delayTics:[3,2,2,1,1,1], ofsFwd:42, ofsSide:-9),
                               MakeRain(proj:"RS_PurpleWorryCB", count:1, atTarget:true, fuseTics:56) ])
    notes    **RS_OrbCB is Speed 125** with `+SEEKERMISSILE` (A_SeekerMissile(8,8))
             and A_Weave(1,1,2,1) — the fastest projectile in the family, and it
             weaves AND homes. `+MTHRUSPECIES`.
             `A_CheckSight("See")` appears twice mid-cast, so losing sight
             cancels the delayed bomb. The bomb is a 56-tic-fused area denial
             placed on the player — the "sticky grenade" of the family.

    ATTACK   RS_PurpleCybie.RocketCombo
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1574
    shape    SINGLE
    payload  RS_Propane x1
    arc      random(-4,4)
    timing   6 aim, 8 fire
    damage   Damage 18  (bare constant)
    type     Fire
    sound    SeeSound "weapons/rocklf"
    impact   A_Explode(**random(64,128),128**) — the largest explicit blast roll
             on any single projectile here. DeathSound "weapons/rocklx".
    trigger  Missile (via BarrageOr) AND Melee (fallthrough from Melee)
    range    ..1200
    mirrored no
    inherit  --
    profile  MakeSingle(proj:"RS_Propane", spread:4, ofsFwd:42, ofsSide:-9)
    notes    `+SEEKERMISSILE` with A_SeekerMissile(4,4) EVERY tic — a hard homer
             at rocket speed 20. `+DEHEXPLOSION` and `+ROCKETTRAIL` as well, so
             it takes the DeHackEd explosion values on top of the explicit
             A_Explode. Two triggers, one row.

---

# TIER 5 — RS_YellowCybie ("Less cyber yellow Cybie")

`RS_Cyberdemon.zs:1600` · CH `CYBIES.txt:2991`
Health 7777 · Speed 19 · `+NOPAIN` · RenderStyle SoulTrans · no Melee label.

Router: `Missile` → `A_JumpIfHealthLower(3500,"BuffUP")`, then
`A_JumpIfCloser(800,"RainOffire")`, else `A_Jump(255,"Missiles1")`.
After the buff, `Nah` and `Ormaybe` re-route with a 700-unit gate.

    ATTACK   RS_YellowCybie.RainOffire
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1674
    shape    RAIN
    payload  RS_CybieRain x22 (direct, falling)  +  RS_CybieRainMaker x2
             (ceiling emitters that spawn more)  + RS_SparkPuff1 x10 (deco)
    arc      spawned at z **552** above the monster, forward random(64,128) →
             randompick(528,725,912,1028) as the barrage walks OUT, lateral
             random(-64,64) → random(-94,94), angle jitter ±15 to ±33, forward
             velocity random(1,15), vertical velocity random(-12,1)
    timing   6 aim, 8 "cyber/sight", 10 sparks @1t, 8, 12 for the first
             RainMaker, then 22 rain spawns over 8 frames at 0/1 tics, 8 recover
    damage   RS_CybieRain DamageFunction (random(15,50));
             RS_CybieRainMaker DamageFunction (random(5,40))
    type     Fire (both)
    sound    "cyber/sight"; each drop SeeSound "caco/attack",
             DeathSound "fire/fire5"
    impact   BBOM A-G with A_Explode(random(10,30),108) and (random(5,30),108) —
             two explode passes, 108 radius, per drop.
    trigger  Missile   (A_JumpIfCloser(800), and one of two via Ormaybe after
             the buff)
    range    ..800   (..700 branch via Nah/Ormaybe)
    mirrored no
    inherit  --
    profile  MakeRain(proj:"RS_CybieRain", count:22, spawnZ:552,
                      forwardWalk:[64,1028], lateral:94, velFwd:random(1,15),
                      velUp:random(-12,1), delayTics:1,
                      emitter:"RS_CybieRainMaker", emitterCount:2)
    notes    **THE FAMILY'S RAIN.** Two delivery systems at once:
             (a) the 22 direct spawns, which walk outward from 64 to 1028 units
                 in front of the monster — a rolling carpet, not a circle;
             (b) two RS_CybieRainMaker, which are +CEILINGHUGGER +INVISIBLE
                 Gravity-7 emitters that then spawn RS_CybieRain at
                 random(±400) and random(±700) around THEMSELVES, on a loop,
                 for as long as they live. The barrage keeps going after the
                 state ends.
             Every RS_CybieRain is `+SEEKERMISSILE` with A_SeekerMissile(3,3) —
             falling AND homing. Gravity 5.
             The 10 RS_SparkPuff1 are deco (`RS_ShotgunnerFX.zs:209`, no damage).

    ATTACK   RS_YellowCybie.Missiles1
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1689
    shape    MULTI
    payload  RS_Vollrey x1 (seeker, centre) + RS_Vollrey2 x2 (dumb, flanks)
    arc      0, -2, +2  (side offsets -45, -48, -42)
    timing   6 aim, 9, all three on one tic
    damage   RS_Vollrey DamageFunction (random(10,50));
             RS_Vollrey2 DamageFunction (random(10,60))
    type     Fire (both)
    sound    --   (state silent; both SeeSound "Forgotten/Attack")
    impact   BBOM A-G, A_Explode(random(5,25),148) then (random(5,20),148),
             DeathSound "spell/Impact1"
    trigger  Missile   (A_Jump(255) default branch, and via Nah/Ormaybe)
    range    800..  direct; any range via Nah
    mirrored yes   (-2/+2 with matching -48/-42 side offsets)
    inherit  --   (Vollrey and Vollrey2 are siblings; Vollrey adds
                   +SEEKERMISSILE and rolls 10 lower on the top end)
    profile  MakeMulti(parts:[ MakeSingle(proj:"RS_Vollrey", ofsFwd:54, ofsSide:-45),
                               MakeFan(proj:"RS_Vollrey2", count:2, arc:4, ofsFwd:54, ofsSide:[-48,-42]) ])
    notes    The escort geometry — one hard homer (A_SeekerMissile(12,18), the
             most aggressive tracking in the family) flanked by two dumb rounds
             that arrive at the same time. Both trail RS_GlowBack (deco).
             **The seeker rolls LOWER damage than the dumb rounds**; that is
             CH's, verified.

    ATTACK   RS_YellowCybie.BuffUP
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1696
    shape    MULTI
    payload  RS_CybieRainMaker x1  +  RS_YellowHK x2 (summons)
    arc      --   (the emitter fires straight ahead; the escorts spawn at ±65)
    timing   8 "cyber/sight", 12 emitter, 12 flag, 2, 1+1 summons, 24 pause, 2+1
    damage   RS_CybieRainMaker DamageFunction (random(5,40)) plus its own
             A_Explode(random(10,40),108) and (random(10,45),108)
    type     Fire
    sound    "cyber/sight"
    impact   the emitter rains RS_CybieRain (random(15,50) Fire) at random(±400)
             and random(±700) around itself, indefinitely
    trigger  Missile   (A_JumpIfHealthLower(3500), ONCE — `User_Doner` gate)
    range    --
    mirrored yes   (the two escorts spawn at (0,-65,+66) and (0,+65,-66))
    inherit  --   (RS_YellowHK is the HELLKNIGHT lane's,
                   `RS_HellKnight.zs:1393`)
    profile  MakeMulti(parts:[ MakeRain(proj:"RS_CybieRainMaker", count:1, emitter:true),
                               MakeSummon(cls:"RS_YellowHK", count:2, ofsSide:65) ])
    notes    A one-shot enrage: `+MISSILEEVENMORE`, `+THRUACTORS` for the summon
             frames only, and `User_Doner += 1` so it can never fire twice.
             It is an attack AND a phase change — the RainMaker is live damage,
             not a flourish.

    ATTACK   RS_YellowCybie.Death
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1718
    shape    SCATTER
    payload  RS_HKRedDeath x5   (+ RS_SuperDemonArm x1 and 5 Blood — gore)
    arc      fixed offsets (90,-10), (20,30), (70,10), (20,50), (10,-10),
             all CMF_AIMOFFSET with pitch 10
    timing   spread over the ~50-tic death animation
    damage   A_Explode(random(5,10),42) each
    type     Fire
    sound    "superdemon/snarl", A_Scream → "superdemon/death",
             "superdemon/crash"; each burst "world/barrelx"
    impact   A_Burst("RS_RedThingsHK") shrapnel, deco
    trigger  Death
    range    --
    mirrored no
    inherit  --   (ZOMBIEMAN lane, `RS_ZombiemanFX.zs:844`)
    profile  MakeScatter(proj:"RS_HKRedDeath", count:5, cone:60, delayTics:6, damage:random(5,10), radius:42)
    notes    RS_SuperDemonArm (`RS_CyberdemonFX.zs:1843`) has `Damage 1` and
             Gravity 0.125 (CH's `+LOWGRAVITY`) — a flying limb that technically
             does 1 point. Recorded as gore, not a payload.

---

# TIER 6 — RS_RedCybie ("Red Overlord")

`RS_Cyberdemon.zs:1739` · CH `CYBIES.txt:3308`
Health 10000 · Speed 20 · `Damage 20` bare (contact) · MeleeRange 68 ·
MeleeThreshold 128 · `+QUICKTORETALIATE` · `+NOTARGET`.

Router: `Missile` → `A_JumpIf(User_PhaseIt >= 1,"Phase2Jumps")`, then
`A_JumpIfHealthLower(5000,"Phase2")`, then
`A_Jump(256,"Missile1","Missile3","Missile2")`.
`Phase2Jumps` → `A_Jump(256,"Missile5","Missile3","Missile2","Missile4")`.

    ATTACK   RS_RedCybie.Melee
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1843
    shape    RING
    payload  RS_MolochQuake x35
    arc      360 in 10-degree steps: 0,10,…,160 then 180,190,…,350.
             **170 IS SKIPPED** — 35 spokes, not 36. Verified byte-for-byte in
             CH (CYBIES.txt:3400+). Do not "complete" the ring.
    timing   10 aim, 4 for Radius_Quake(40,60,0,40,0), 2 for "moloch/thud",
             then all 35 on one tic, 2 + 4 recover
    damage   DamageFunction (random(5,27)) contact, plus
             **A_Explode(random(7,28),128) on NINE consecutive frames** as the
             ray travels (`IDGA CCAABBCCC 10`), plus one more on Death
    type     Melee
    sound    "moloch/thud"; each ray SeeSound "moloch/thud"
    impact   the ray IS the impact — it is `+RIPPER +FLOORHUGGER
             +FORCERADIUSDMG +BLOODLESSIMPACT`, Alpha 0.1, and it rips through
             everything for 90 tics
    trigger  Melee
    range    ..68  (MeleeRange 68, MeleeThreshold 128)
    mirrored no
    inherit  --   (RS_MolochQuake is the DEMON lane's, `RS_DemonFX.zs:65`)
    profile  MakeRing(proj:"RS_MolochQuake", count:35, arc:360, step:10, skip:[170],
                      delayTics:0, ofsSide:-48, quake:{intensity:40, duration:60, radius:40})
    notes    A floor-level omnidirectional ripper. The per-frame A_Explode is
             DELIBERATE (CH's lingering quake — see the project's multi-frame
             A_Explode note); do NOT collapse it to one call. Also reached from
             Pain via `A_Jump(74,"Melee")` and from Phase2's tail.

    ATTACK   RS_RedCybie.Phase2
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1896
    shape    RING
    payload  RS_VolcanoBall1 x9
    arc      360 in both axes — CMF_AIMOFFSET with angle random(0,360) and
             pitch random(0,360); spawn offsets random(20,80) fwd,
             random(-40,40) side
    timing   1 + 10 + 12 + 2 for the roar and flags, then 9 balls at 5 tics
             each (45 tics), 12 + 8 + 2; then `Goto Melee`
    damage   DamageFunction (random(5,35))
    type     Fire
    sound    "moloch/phase2" on channel 0 at vol 4
    impact   BAL3 C-E, A_Explode(random(5,10),88), DeathSound "moloch/emberexp"
    trigger  Missile   (A_JumpIfHealthLower(5000), ONCE — `User_PhaseIt` gate)
    range    --
    mirrored no
    inherit  --
    profile  MakeRing(proj:"RS_VolcanoBall1", count:9, arc:360, pitchArc:360,
                      delayTics:5, ofsFwd:random(20,80), ofsSide:random(-40,40))
    notes    The enrage: `bNOPAIN = true`, `bMISSILEEVENMORE = true`,
             A_SetSpeed(28), `User_PhaseIt += 1`, then straight into the quake
             ring. The 9 balls bounce (BounceType Doom, BounceCount 4,
             BounceFactor 0.85) and carry `DontHurtShooter true`.
             A slow 9-round spherical scatter, not a nova.

    ATTACK   RS_RedCybie.Missile1
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1904
    shape    SINGLE
    payload  RS_SoulBomb4 x1
    arc      0
    timing   14 + 14 aim, 10 fire
    damage   DamageFunction (random(10,70))
    type     Melee
    sound    "moloch/attack"; the bomb SeeSound "Spell/SpellCast1"
    impact   SPIR A-E-A over 9 frames, spawning **9 RS_RedCybieSouls at
             random(±128)** — each A_Explode(random(5,15),32) x4 and then
             **spawns a live RS_MolochWraith monster**. DeathSound "Fire/Fire4".
    trigger  Missile   (1 of 3 in phase 1)
    range    --
    mirrored no
    inherit  --
    profile  MakeSingle(proj:"RS_SoulBomb4", ofsFwd:65,
                        impactSpawn:{proj:"RS_RedCybieSouls", count:9, spread:128, summons:"RS_MolochWraith"})
    notes    **IMPACT IS ITSELF AN ATTACK AND A SUMMON.** One projectile becomes
             nine soul bursts becomes up to nine wraiths. In flight it lays
             RS_SpiralSaw5 (A_Explode(random(2,10),88), chaingunner lane) every
             other tic AND fires RS_GroundRedCyb (A_Explode(random(2,10),128),
             chaingunner lane) forward every loop — so it damages continuously
             along its path. `+SEEKERMISSILE`, A_SeekerMissile(1,1).
             The wraith gets its own rows below.

    ATTACK   RS_RedCybie.Missile2
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1911
    shape    MULTI
    payload  RS_VolcanoBall3 x5 + RS_VolcanoBall2 x1 + RS_RedCybieVolcano1 x2
    arc      balls at random(-13,13); the two crawlers at random(-30,30) with
             pitch random(-15,20)
    timing   12 aim, 5 balls at 2 tics, the seeker on t0, 12 aim, 4 for
             "moloch/sight", 2 crawlers at 6 tics each
    damage   VolcanoBall3 and VolcanoBall2 DamageFunction (random(10,40));
             RS_RedCybieVolcano1 has NO Damage — it is a delivery shell
    type     Fire (all three)
    sound    "moloch/attack" then "moloch/sight"; each ball SeeSound "imp/attack"
    impact   Ball3: A_Explode(random(12,45),108), DeathSound "moloch/emberexp".
             Ball2: same but `+SEEKERMISSILE` with A_SeekerMissile(4,8) and
             A_Explode(random(11,33),108).
             RedCybieVolcano1: `+INVISIBLE`, floor-hugging, A_Wander with a
             1-in-11 death roll per loop, then spawns **3 RS_RedCybieVolcano2**
             at random(±328) — each of which erupts RS_VolcanoBall1 twice per
             6-tic beat for up to 33 beats, then A_Explode(random(20,80),128).
    trigger  Missile   (1 of 3 in phase 1, 1 of 4 in phase 2)
    range    --
    mirrored no
    inherit  --   (Ball1/2/3 are three sibling classes, not a hierarchy —
                   opened all three)
    profile  MakeMulti(parts:[ MakeBurst(proj:"RS_VolcanoBall3", count:5, delayTics:2, spread:13, ofsFwd:60),
                               MakeSingle(proj:"RS_VolcanoBall2", spread:13, ofsFwd:60, seeker:true),
                               MakeRain(proj:"RS_RedCybieVolcano1", count:2, crawler:true,
                                        secondary:"RS_RedCybieVolcano2", secondaryCount:3, spread:328) ])
    notes    Three delivery systems in one state: a five-round burst, one homer
             hidden in it, and two invisible crawlers that seed a persistent
             field of erupting vents up to 328 units away. `A_CheckSight("See")`
             aborts at the top. This is the family's best "area denial that
             keeps working" template.

    ATTACK   RS_RedCybie.Missile3
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1922
    shape    BURST
    payload  RS_MolochNail x2 per cycle, looping
    arc      random(-3,3) then random(-9,9); side offset random(-10,10) both
    timing   25 aim, then (1 aim + 1 fire) x2, A_Jump(10) out, A_SpidRefire;
             loops to `Missile3+5`
    damage   DamageFunction (random(10,30))
    type     Fire
    sound    "moloch/attack", then "moloch/nail" after each shot
    impact   AttackSound "moloch/nailhitbleed" (`+SPAWNSOUNDSOURCE`),
             "moloch/nailhit" on death, then A_Explode(random(2,10),64) on SIX
             frames and (random(5,20),64) on three more — nine explode frames.
             `+EXTREMEDEATH +BLOODSPLATTER +ROCKETTRAIL`, Decal "BulletChip".
             DeathSound "weapons/firex4".
    trigger  Missile   (1 of 3 in phase 1, 1 of 4 in phase 2)
    range    --
    mirrored no
    inherit  --   (CACODEMON lane, `RS_CacodemonFX.zs:169`)
    profile  MakeBurst(proj:"RS_MolochNail", count:2, delayTics:2, spread:[3,9],
                       ofsFwd:55, ofsSide:random(-10,10), loop:"A_SpidRefire")
    notes    Speed 30, Scale 1.1, a bladed spike — the family's only true
             machine-gun cadence (2 tics between rounds, indefinite via
             A_SpidRefire). The per-frame A_Explode is CH's deliberate nail
             burn; do not collapse it.

    ATTACK   RS_RedCybie.Missile4
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1935
    shape    RAIN
    payload  RS_SummonPortalCybie x2   (a summoner monster, not a projectile)
    arc      random(-128,128) x random(-128,128), z 50
    timing   14 + 14 aim, A_CheckSight, 5, both portals on one tic, 5
    damage   the portal itself does none. It is Health 50, `+NOPAIN +NOTARGET
             +FLOAT +FLOATBOB`, and on a 12/256 roll per See loop it runs
             `A_PainAttack("RS_PortalSummons",0,PAF_NOSKULLATTACK)`.
    type     --
    sound    "moloch/attack"; the portal SeeSound "holy2/holy4" (PROVEN MISSING
             in CH's SNDINFO — silent there too), DeathSound "wraith/wraith5"
    impact   RS_PortalSummons is a RandomSpawner (`RS_CacodemonFX.zs:316`)
             weighted toward RS_MolochWraith (800) with red variants of the
             revenant, lost soul, zombie, shotgunner, chaingunner, imp, demon
             and caco behind it
    trigger  Missile   (1 of 4, phase 2 only)
    range    --
    mirrored no
    inherit  --   (CACODEMON lane, `RS_CacodemonFX.zs:337`)
    profile  MakeRain(proj:"RS_SummonPortalCybie", count:2, spread:128, spawnZ:50, summoner:true)
    notes    Recorded as an attack because it is a Missile-state branch that
             places hostile actors on the battlefield — the profile equivalent
             is a turret/deployable, not a projectile. Zero direct damage;
             that is the finding, not an omission.

    ATTACK   RS_RedCybie.Missile5
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:1943
    shape    FAN
    payload  RS_SoulBomb4 x3
    arc      18 total: -9, 0, +9
    timing   14 + 14 aim, 10, all three on one tic
    damage   DamageFunction (random(10,70))
    type     Melee
    sound    "moloch/attack"; each bomb SeeSound "Spell/SpellCast1"
    impact   as Missile1 — each of the three spawns 9 RS_RedCybieSouls, so up to
             **27 soul bursts and 27 RS_MolochWraith summons** from one cast
    trigger  Missile   (1 of 4, phase 2 only)
    range    --
    mirrored yes   (-9/+9 around a centre shot)
    inherit  --
    profile  MakeFan(proj:"RS_SoulBomb4", count:3, arc:18, delayTics:0, ofsFwd:65)
    notes    The phase-2 upgrade of Missile1. Same payload, three at once. This
             is the family's highest summon throughput and its most expensive
             single cast.

---

# MINION — RS_MolochWraith (Red Cybie's soul, no tier token)

`RS_Cyberdemon.zs:1981` · CH `CYBIES.txt:3692`
Health 20 · Speed 15 · `Damage 3` bare · `+MISSILEMORE` · phases through walls
(`bNOCLIP = true`) every 20 chase ticks.

    ATTACK   RS_MolochWraith.Missile
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2033
    shape    CHARGE
    payload  the wraith itself (A_SkullAttack(45))
    arc      --
    timing   10 aim, 4 launch, 4+4 coast; loops back to `Missile+1` forever
    damage   Damage 3   (bare constant, the ram)
    type     --   (no DamageType; DamageFactor "Moloch" 0.01 makes it nearly
                   immune to its own kind)
    sound    AttackSound "moloch/wraithattack" (A_SkullAttack plays AttackSound)
    impact   --   (contact only; the wraith survives the hit and re-charges)
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeCharge(speed:45, ramDamage:3, repeat:true)
    notes    `bNOCLIP = false` and `user_letmeget = 1` at the top — it drops out
             of phase to attack, so the charge is the only window it is
             solid. A cheap, relentless, wall-ignoring rammer.

    ATTACK   RS_MolochWraith.Melee
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2041
    shape    MELEE
    payload  --
    arc      --
    timing   5 aim, 5 strike
    damage   A_CustomMeleeAttack(9, ..., "Moloch")
    type     Moloch
    sound    "moloch/wraithmelee" — **PROVEN MISSING IN CH.** CH defines
             moloch/wraith, /wraithattack and /wraithdie and never /wraithmelee.
             Silent in CH too; kept verbatim.
    impact   --
    trigger  Melee
    range    --   (engine default MeleeRange 64)
    mirrored no
    inherit  --
    profile  MakeMelee(damage:9, type:"Moloch", sound:"moloch/wraithmelee")
    notes    DamageType "Moloch" exists so the Red Cybie and its wraiths cannot
             hurt each other (Red has DamageFactor "Moloch", 0). If this becomes
             a player profile the damage type must be renamed or the player will
             be immune to their own weapon in exactly one situation.

---

# TIER 10 — RS_BlackCybie2 ("He Will Smith You")

`RS_Cyberdemon.zs:2058` · CH `CYBIES.txt:4082`
Health 14500 · Speed 17 · `Damage 30` bare · MeleeDamage 20 · MeleeRange 86 ·
`+MISSILEEVENMORE` from the start.

Router: `Missile` → `A_JumpIfCloser(650,"Charge")`, `User_DumDum -= 1`,
`A_JumpIfHealthLower(8000,"Phase2")`,
`A_Jump(256,"Missile1","Missile2","LightningCall")`, else `Goto Charge`.
`PH2` (after the phase flag) → `A_Jump(256,"BigHell","HammerMega",
"LightningCall","Summons")`.

    ATTACK   RS_BlackCybie2.Charge
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2203
    shape    CHARGE
    payload  the monster itself (A_SkullAttack(35)) + RS_SmithGhost2 x8
    arc      --
    timing   1 + 2 wind-up, 12-tic launch, then 8 afterimages at 1 tic each,
             1 + 1 to stop; then `Goto Melee`
    damage   ram: `Damage 30` bare;
             each afterimage DamageFunction (random(12,34))
    type     ram --; afterimages Melee
    sound    "weapons/suldth"
    impact   RS_SmithGhost2 (`RS_CyberdemonFX.zs:2267`) is Radius 40 Height 70,
             sits for 35 tics then fades out over ~20 more — a persistent
             damaging silhouette left along the charge path. `Projectile`,
             Alpha 0.5, RenderStyle Translucent.
    trigger  Missile   (A_JumpIfCloser(650), and the fallthrough at the bottom
                        of Missile)
    range    ..650
    mirrored no
    inherit  --
    profile  MakeCharge(speed:35, ramDamage:30, ghost:"RS_SmithGhost2", ghostCount:8,
                        ghostDelayTics:1, invulnDuringCharge:true, thruActors:true)
    notes    **A_SetReflectiveInvulnerable for the whole charge** and
             `bTHRUACTORS = true`, cleared afterwards — it is untouchable and
             passes through everything while ramming. A `User_DumDum` budget
             (+5 per charge, -2 on refusal, -6 on Reposition) stops it charging
             forever; at >= 11 it takes `NoFire` instead.
             Chains unconditionally into Melee (below).
             Sibling class RS_SmithGhost1 is DEAD CODE with a missing sprite —
             nothing anywhere spawns it, documented at its definition.

    ATTACK   RS_BlackCybie2.Melee
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2290
    shape    MULTI
    payload  A_CustomMeleeAttack + RS_PentaLine1 x5 + RS_MolochQuake x35
    arc      pentagram lines at -72, -144, -216, -288, 0 (a five-pointed star);
             quake rays 360 in 10-degree steps, 170 skipped
    timing   6 aim, 1 + 5 wind-up, 5 punch, then the star and the quake ring on
             one tic, and a 70-tic hold on the last ray
    damage   melee: A_CustomMeleeAttack(random(50,125));
             RS_PentaLine1: no Damage — it is a Speed 200 invisible tracer that
             forks into RS_PentaLine2, which drops RS_PentaFire every tic for
             16 tics; **RS_PentaFire is the damage: A_Explode(1,32,1) on 14
             frames and A_Explode(2,32,1) on 3 more, per fire**, looping on
             ReactionTime 2;
             RS_MolochQuake DamageFunction (random(5,27)) +
             A_Explode(random(7,28),128) x10
    type     melee --; pentagram fire; quake Melee
    sound    "monster/hamswg" then "monster/hamflr"; PentaLine SeeSound
             "weapons/diasht"; PentaFire tries "weapons/onfire" which is
             **PROVEN MISSING IN CH** — silent there too
    impact   the star burns on the floor for the fire's whole ReactionTime loop
    trigger  Melee   (MeleeRange 86), and the tail of every Charge
    range    ..86
    mirrored no
    inherit  --
    profile  MakeMulti(parts:[ MakeMelee(damage:random(50,125)),
                               MakeRing(proj:"RS_PentaLine1", count:5, angles:[-72,-144,-216,-288,0], fire:"RS_PentaFire"),
                               MakeRing(proj:"RS_MolochQuake", count:35, arc:360, step:10, skip:[170], ofsSide:-48) ])
    notes    **The actor declares `MeleeSound "monster/hamhit"` and never plays
             it.** MeleeSound is consumed by A_MeleeAttack; this actor uses
             A_CustomMeleeAttack with no sound argument, which defaults to "".
             Same in CH — faithful, but the hit itself is silent and the two
             hammer sounds are the swing and the floor slam.
             A_SetReflectiveInvulnerable fires mid-swing and is only cleared
             back in `See`.

    ATTACK   RS_BlackCybie2.Missile1
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2220
    shape    FAN
    payload  RS_Hellshot2 x6   (two volleys of 3)
    arc      volley 1: 0, +8, -8;  volley 2: 0, +14, -14 (widening)
    timing   6 aim, 6 swing, then 3 on one tic + 12; A_CheckSight; 6 + 6 + 6 + 1,
             then 3 on one tic + 11
    damage   DamageFunction (random(40,120))
    type     Fire
    sound    "monster/hamswg" + "weapons/hellfi" per volley
    impact   HELX A, then a RING of 8 RS_HellBoom at 45-degree steps, then
             A_Explode(random(20,80),128), then it spawns **RS_HellWaver** —
             a 25-speed follow-on that fires 24 RS_STracer in a full 360 ring
             every 12 tics and re-loops on A_Jump(128). Each RS_HellBoom drops
             5 RS_HellFX, each A_Explode(random(5,40),96,0). Each RS_STracer is
             DamageFunction (random(11,33)) + A_Explode(random(5,15),64).
             DeathSound "weapons/hellex".
    trigger  Missile   (1 of 3 in phase 1); also A_Jump(128) out of BigHell
    range    650..
    mirrored yes   (both volleys are ± pairs around a centre shot)
    inherit  --
    profile  MakeFan(proj:"RS_Hellshot2", count:3, arc:16, delayTics:0, ofsFwd:52,
                     repeat:2, repeatArc:28,
                     impact:{ring:"RS_HellBoom", ringCount:8, followOn:"RS_HellWaver"})
    notes    THE IMPACT IS THE ATTACK. One hit becomes 8 boom rays + 40 HellFX
             + a persistent HellWaver throwing 24 tracers per cycle. Reading
             only the fan reports "6 fire bolts"; the real footprint is two
             classes and one follow-on deep. `DontHurtShooter true`.

    ATTACK   RS_BlackCybie2.Missile2
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2235
    shape    BURST
    payload  RS_HammerShot x2
    arc      random(-8,8) then random(-14,14)
    timing   6 aim, 1 swing, 2, 3 fire, 5 aim, 10 floor, 6 fire
    damage   DamageFunction (random(30,140))
    type     Fire
    sound    "monster/hamswg", "monster/hamflr"; the shot plays "Ice/Fly"
             repeatedly in flight
    impact   FHFX I-R, A_Explode(random(2,14),128) on TEN frames,
             DeathSound "weapons/hellex", Decal "Scorch"
    trigger  Missile   (1 of 3 in phase 1)
    range    650..
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_HammerShot", count:2, delayTics:18, spread:[8,14], ofsFwd:52)
    notes    **The projectile steers itself.** 1-in-4 per loop it enters `Swoop`
             (A_Stop, A_SetAngle(±60), re-thrust at 9), and 1-in-8 it enters
             `Reverse` (A_ChangeVelocity(-25,0,-vel.z,CVF_RELATIVE|CVF_REPLACE))
             — it can turn around and come back. Speed 32, Scale 1.45. That
             erratic flight is the whole character of the attack.

    ATTACK   RS_BlackCybie2.HammerMega
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2182
    shape    BURST
    payload  RS_HammerShot x5   (2 then 3)
    arc      random(-8,8) x2, then random(-14,14) x3
    timing   6 aim, 1 swing, 2, 2 shots at 3 tics, 5 aim, 8 floor,
             3 shots at 4 tics
    damage   DamageFunction (random(30,140))
    type     Fire
    sound    "monster/hamswg", "monster/hamflr"
    impact   as Missile2
    trigger  Missile   (1 of 4, phase 2 only, via PH2)
    range    650..
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_HammerShot", count:5, delayTics:[3,3,4,4,4], spread:[8,8,14,14,14], ofsFwd:52)
    notes    The phase-2 version of Missile2 — 5 shots instead of 2, and the
             lines are `BSMT NN` and `BSMT III`, so the frame-repeat is doing
             the multiplying. Counting lines gives 2; counting frames gives 5.

    ATTACK   RS_BlackCybie2.BigHell
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2191
    shape    SINGLE
    payload  RS_BigHellshot x1
    arc      0
    timing   12 aim, 6 swing, 1, 11 fire
    damage   DamageFunction (random(40,180))
    type     Fire
    sound    "monster/hamswg" then "weapons/hellfi"
    impact   the same 8-ray RS_HellBoom ring + A_Explode(random(20,80),128) as
             Missile1, but the follow-on is **RS_HellWaver2**, which fires the
             24-tracer ring THREE times per loop instead of once and re-loops on
             A_Jump(128). DeathSound "weapons/hellex".
    trigger  Missile   (1 of 4, phase 2 only)
    range    650..
    mirrored no
    inherit  --
    profile  MakeSingle(proj:"RS_BigHellshot", ofsFwd:52,
                        impact:{ring:"RS_HellBoom", ringCount:8, followOn:"RS_HellWaver2"})
    notes    **The projectile fires 24 RS_STracer in a 360 ring EVERY Spawn loop
             while it is still travelling**, at Speed 7 and Scale 1.75 — a slow
             flying shredder that carpets the floor as it comes. That in-flight
             ring is easy to miss reading the attack state; it is at
             `RS_CyberdemonFX.zs:2605-2628`. Then A_Jump(128,"Missile1").

    ATTACK   RS_BlackCybie2.LightningCall
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2249
    shape    RAIN
    payload  RS_ZappersCB x2   (+ RS_Zap88 x4 — **DECO, 0 damage, verified**)
    arc      the two emitters at random(-180,180) angle, side offset
             random(-2,28)
    timing   8 + 6 aim, 8 flash, then 1-tic beats for the rest (≈14 tics)
    damage   RS_ZappersCB DamageFunction (random(5,35)) +
             A_Explode(random(3,21),108) x2 on its own death
    type     Plasma
    sound    "Crack/death" three times
    impact   RS_ZappersCB is `+CEILINGHUGGER +FLOAT +NOGRAVITY +INVISIBLE`,
             Gravity 7 — it rides the ceiling and drops **RS_CybieZappy** at
             random(±400) then random(±700) around itself on a loop.
             Each RS_CybieZappy (revenant lane, `RS_RevenantFX.zs:2089`) is a
             Gravity-0.4 falling bolt that A_Explode(random(5,20),32) and then
             throws 5 RS_ZapZapCB crawlers, each A_Explode(random(1,8),64) on
             18 frames. Three classes deep.
    trigger  Missile   (1 of 3 in phase 1, 1 of 4 in phase 2)
    range    650..
    mirrored no
    inherit  --
    profile  MakeRain(proj:"RS_ZappersCB", count:2, emitter:true, ceilingHug:true,
                      drop:"RS_CybieZappy", dropSpread:[400,700], crawler:"RS_ZapZapCB")
    notes    **FOUR OF THE SIX A_CustomMissile CALLS IN THIS STATE ARE PURE FX.**
             RS_Zap88 (`RS_CacodemonFX.zs:66`) has no Damage and
             `+NOINTERACTION` — it is the lightning graphic. A row that counted
             all six as payloads would triple this attack's reported output.
             The real attack is two invisible ceiling emitters.

    ATTACK   RS_BlackCybie2.Summons
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2176
    shape    RAIN
    payload  RS_PortalSummons x4   (RandomSpawner → live monsters)
    arc      random(-178,178) x random(-178,178), z random(5,64)
    timing   12 + 4 beats at 9 tics
    damage   --   (none; the spawned monsters carry their own)
    type     --
    sound    "monster/fihoof"
    impact   --
    trigger  Missile   (1 of 4, phase 2 only)
    range    650..
    mirrored no
    inherit  --   (CACODEMON lane, `RS_CacodemonFX.zs:316`)
    profile  MakeRain(proj:"RS_PortalSummons", count:4, spread:178, zRange:[5,64], summoner:true)
    notes    Zero direct damage. Recorded so the gap is explicit.

    ATTACK   RS_BlackCybie2.Phase2
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2171
    shape    RAIN
    payload  RS_PortalSummons x6
    arc      random(-178,178) x random(-178,178), z random(5,64)
    timing   12 aim, 8 for the flag, 6 beats at 8 tics, 2
    damage   --
    type     --
    sound    --
    impact   --
    trigger  Missile   (A_JumpIfHealthLower(8000), ONCE — `User_OH1` gate)
    range    650..
    mirrored no
    inherit  --
    profile  MakeRain(proj:"RS_PortalSummons", count:6, spread:178, zRange:[5,64], summoner:true)
    notes    The phase flip: `bMISSILEEVENMORE = true`, `User_OH1 += 1`, six
             portals at once. Afterwards every Missile goes through PH2 and the
             attack roster changes entirely.

    ATTACK   RS_BlackCybie2.Death
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2336
    shape    MULTI
    payload  RS_PentaLine3 x5 (→ RS_PentaFire2) + RS_SmithDFSpawner x1
             + RS_SmithHammer x1 + RS_SmithFire x4
    arc      pentagram at -72, -144, -216, -288, 0; the death-fire spawner
             fires straight up (pitch 90)
    timing   the star and the quake on one tic, then a **250-TIC** hold on the
             spawner frame, then 6 + 6 + 6x3 + 6 + 6x2
    damage   RS_PentaFire2: A_Explode(1,32,1) on 14 frames + A_Explode(1,32,1)
             on 3 more, looping on ReactionTime 7 (7x longer than the melee
             version's ReactionTime 2);
             RS_SmithDeathFire: `Damage 1`, one per tic for 300 tics;
             RS_SmithFire: `Damage 0` — pure FX;
             RS_SmithHammer: `Damage 0` — the falling maul, gore
    type     fire
    sound    A_Scream → DeathSound "monster/smithd";
             RS_SmithFire SeeSound "Weapons/hellex";
             RS_SmithHammer DeathSound "monsters/hamflr" — **PROVEN MISSING**,
             a CH typo for its own "monster/hamflr" (singular). Silent in CH.
    impact   Radius_Quake(6,250,2,64,8) — a 250-tic tremor
    trigger  Death
    range    --
    mirrored no
    inherit  --
    profile  MakeMulti(parts:[ MakeRing(proj:"RS_PentaLine3", count:5, angles:[-72,-144,-216,-288,0], fire:"RS_PentaFire2", fuseLoops:7),
                               MakeRain(proj:"RS_SmithDFSpawner", count:1, dropsPerTic:1, drop:"RS_SmithDeathFire", durationTics:300) ])
    notes    A 300-tic burning pentagram on the corpse. Low per-tick, enormous
             in total, and it holds ground for five seconds after the boss dies.
             `Death.Telefrag` (`:2356`) has NO attack — 7 frames of scream and
             out. Recorded so the absence is explicit.

---

# ESCORT — RS_RomeroBaronsCH (White Cybie's guard, no tier token)

    ATTACK   RS_RomeroBaronsCH.*
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2372
    shape    UNCLASSIFIED
    payload  see the BARON family catalog
    arc      see the BARON family catalog
    timing   see the BARON family catalog
    damage   see the BARON family catalog
    type     see the BARON family catalog
    sound    see the BARON family catalog
    impact   see the BARON family catalog
    trigger  Missile, Melee
    range    --
    mirrored --
    inherit  **RS_CommonBaron** (`zscript/monsters/baron/RS_Baron.zs:1101`)
    profile  --   (belongs to the Baron catalog, not this one)
    notes    THIS CLASS HAS NO `States` BLOCK AT ALL. It changes Species to
             "Daikatana", Speed to 11, and adds `+NOTRIGGER +NOCLIP
             +DONTHARMCLASS +DONTHARMSPECIES +NOINFIGHTING`. Every attack it
             has is RS_CommonBaron's, unmodified. Recorded as a pointer to
             avoid duplicate rows at compose time.
             Spawned x2 by Phase2 and BaronsPlease, x2 more by BaronMore.

---

# TIER 11 — RS_WhiteCybie2 ("It runs doom")

`RS_Cyberdemon.zs:2389` · CH `CYBIES.txt:5235`
Health 21000 · Speed 18 · `+MISSILEEVENMORE` · Species "Daikatana" ·
41 state labels, the largest single monster in the family.

Three-layer router:
`Missile` → `A_JumpIfHealthLower(8000,"Phase3")` → `(15000,"Phase2")` →
`MissileSet` → `A_JumpIfCloser(200,"Dukie",true)` /
`(720,"Close",true)` / `(1500,"Med",true)` → then a phase-gated `A_Jump(256)`
over a different roster at each of `MissileSet`/`MissileSet2`/`MissileSet3`,
`Med`/`Med2`/`Med3`, `Close`/`Close2`/`Close3`.
`user_phase` (0/2/3) selects the roster; `A_JumpIfCloser(..., true)` means the
range test also requires line of sight.

    ATTACK   RS_WhiteCybie2.ID
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2626
    shape    SALVO
    payload  RS_RomeroGroundCH x24
    arc      a placed FORWARD GRID, not a ring: x = 128/192/256/320 and
             350/414/478/542, y = -128 / 0 / +64…+128. All 24 on 0-tic frames.
    timing   5x4 aim + 5 + 13 telegraph frames at 1 tic, then all 24 at once,
             3 recover; then `Goto FrontWinder`
    damage   DamageFunction (random(20,100))
    type     Plasma
    sound    "Rome/ATK1"; each burst DeathSound "weapons/rocklx"
    impact   the actor's Spawn is `TNT1 A 0; Goto Death;` — it detonates
             instantly where placed: A_ScreamAndUnblock, BRBA O-K with
             A_Explode(random(10,80),64,0) per frame (5 frames), then BRBA A-J.
             XScale 2.25 / YScale 0.15 — a flat floor slam.
    trigger  Missile   (Close3, phase 3 only)
    range    ..720 with line of sight, phase 3
    mirrored no
    inherit  --
    profile  MakeSalvo(proj:"RS_RomeroGroundCH", count:24, grid:{fwd:[128,542], side:[-128,128]},
                       delayTics:0, placed:true)
    notes    VOCABULARY NOTE: SALVO is used for its defining property —
             24 detonations in one instant — even though they are placed
             rather than fired. RING would be wrong (this is a forward carpet,
             not 360); RAIN would be wrong (nothing falls, and it is centred on
             the shooter, not the target). See UNRESOLVED #4.
             The 13 telegraph frames (`MMDR HIJKJHIKJKHMN 1`) are the tell.

    ATTACK   RS_WhiteCybie2.FrontWinder
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2666
    shape    MULTI
    payload  RS_SpamShotsRomeroCH x2  +  RS_RomeroCHSeekBall x8
    arc      the two heavy shots at side ±30, angle ±1; the eight seekers at
             side +33/+27 with angles ±1, ±3, ±5 — four mirrored pairs
    timing   10 aim, 8 for ThrustThingZ(0,100,0,0) — it hops — 8 aim,
             all ten on one tic + 10, 5 recover; then `Goto Reposition`
    damage   RS_SpamShotsRomeroCH DamageFunction (random(50,150));
             RS_RomeroCHSeekBall DamageFunction (random(20,90))
    type     Plasma (both)
    sound    "Rome/ATK1"; SpamShots SeeSound "weapons/bfgf";
             SeekBall SeeSound "ELECTRO8"
    impact   SpamShots: BFE1 A-F, A_SetScale(1.45), A_Explode(random(25,80),152),
             A_ScreamAndUnblock, DeathSound "weapons/bfgx", and it **drops
             ammo** (Clip 64, Shell 42, RocketAmmo 32, Cell 12 — CH names the
             VANILLA classes here, not its own CH_ set; kept).
             SeekBall: 15 RS_TrailSPRomero shed at random(6,20) in three
             120-degree arcs, each A_Explode(10,32).
    trigger  Missile   (MissileSet3 / Med3 / Close3 — phase 3; also the tail of ID)
    range    phase 3 only
    mirrored yes   (four explicit ± pairs plus a mirrored heavy pair)
    inherit  --
    profile  MakeMulti(parts:[ MakeFan(proj:"RS_SpamShotsRomeroCH", count:2, arc:2, ofsSide:30, mirrored:true),
                               MakeFan(proj:"RS_RomeroCHSeekBall", count:8, arc:10, ofsSide:[33,27], mirrored:true) ],
                       hop:{velZ:100})
    notes    The hop (ThrustThingZ) + `bFLOAT`/`bNOGRAVITY` is part of the
             attack — it fires from the air. Both payloads are
             `+SEEKERMISSILE`; SeekBall A_SeekerMissile(6,12),
             SpamShots A_SeekerMissile(7,6).

    ATTACK   RS_WhiteCybie2.SideWinder
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2682
    shape    SCATTER
    payload  RS_RomeroCHSeekBall x22   **(CH HAS 24 — SEE THE NOTE)**
    arc      strict left/right alternation: side +50 with angle random(20,50),
             side -50 with angle random(-50,-20); pitch random(-3,3) on every
             shot, CMF_OFFSETPITCH|CMF_SAVEPITCH
    timing   10 + 8 aim, then four groups separated by A_FaceTarget:
             6 shots, 4 shots, 6 shots, **6 shots (CH: 8)**, alternating 1 and
             0 tics; then 10 recover
    damage   DamageFunction (random(20,90))
    type     Plasma
    sound    "Rome/ATK1"; SeeSound "ELECTRO8"; DeathSound "Crack/death"
    impact   15 RS_TrailSPRomero in three 120-degree arcs, each A_Explode(10,32);
             the trail itself spawns RS_TrailSP2 (A_Explode(7,32), zombieman lane)
    trigger  Missile   (MissileSet, MissileSet2, MissileSet3, Med2, Med3)
    range    all bands, all phases
    mirrored yes   (the entire attack is one alternating L/R pair sequence)
    inherit  --
    profile  MakeScatter(proj:"RS_RomeroCHSeekBall", count:22, alternateSide:50,
                         cone:30, pitchCone:6, delayTics:1, groups:[6,4,6,6])
    notes    **OUR TREE AND CH DISAGREE — RECORDED, NOT FIXED.**
             CH `CYBIES.txt:5540-5547` gives the fourth group EIGHT shots
             (four L/R pairs). Ours (`RS_Cyberdemon.zs:2701-2706`) has SIX
             (three pairs). Family totals: **CH 32 RomeroCHSeekBall, ours 30**
             — the only genuine divergence found anywhere in this family
             (see the CH cross-check section at the end).
             Everything else about the attack is byte-identical: same offsets,
             same angle ranges, same pitch jitter, same group boundaries.

    ATTACK   RS_WhiteCybie2.ShotgunBreath
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2717
    shape    SALVO
    payload  RS_RomeroCHScatter x24
    arc      angle random(-12,12), pitch random(-13,13) — a 24-wide cone
    timing   4x5 aim, 5, 13 telegraph frames at 3 tics, then **23 on ONE 0-tic
             frame** plus 1 on a 3-tic frame; falls through into DualShots
    damage   DamageFunction (random(20,90))
    type     Plasma
    sound    "Rome/ATK1"; SeeSound "ELECTRO8"; DeathSound "Crack/death"
    impact   15 RS_TrailSPRomero in three 120-degree arcs, each A_Explode(10,32)
    trigger  Missile   (Close, Close2 — phases 1 and 2)
    range    ..720 with line of sight
    mirrored no
    inherit  --
    profile  MakeSalvo(proj:"RS_RomeroCHScatter", count:24, cone:24, pitchCone:26, ofsFwd:60)
    notes    **The purest shotgun in the family** — 24 pellets, one instant,
             ±12 by ±13. Speed 38, Scale 0.95, no homing. Frame count verified
             23+1 in both trees (CH CYBIES.txt:5558).
             It does NOT stop: the state has no Goto, so it runs straight into
             DualShots. One button, two attacks.

    ATTACK   RS_WhiteCybie2.DualShots
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2722
    shape    MULTI
    payload  RS_SpamShotsRomeroCH x10  +  RS_SpamShotsCguy x20   (five waves)
    arc      per wave: heavies at side ±30 with angle ±n, four light shots at
             side ±33 and ±27 with angle ±n; n walks 1, 2, 1, 0, 0
    timing   4x5 aim; then five waves at 10, 8, 6, 4, 2 tics — an accelerating
             ripple; 3+3 recover
    damage   RS_SpamShotsRomeroCH DamageFunction (random(50,150));
             RS_SpamShotsCguy DamageFunction (random(10,60))
    type     Plasma (both)
    sound    "Rome/ATK1"; both SeeSound "weapons/bfgf",
             DeathSound "weapons/bfgx"
    impact   RomeroCH: A_Explode(random(25,80),152), A_ScreamAndUnblock, ammo drop.
             Cguy: A_SetScale(1.15), A_Explode(random(5,45),128).
    trigger  Missile   (MissileSet-family, Med/Med2/Med3, tail of ShotgunBreath,
                        A_Jump(128) out of SideWinder)
    range    all bands, all phases
    mirrored yes   (every wave is symmetric about the centreline)
    inherit  --   (RS_SpamShotsCguy is the CHAINGUNNER lane's,
                   `RS_ChaingunnerFX.zs:967`)
    profile  MakeMulti(parts:[ MakeFan(proj:"RS_SpamShotsRomeroCH", count:2, arc:2, ofsSide:30, mirrored:true),
                               MakeFan(proj:"RS_SpamShotsCguy", count:4, arc:4, ofsSide:[33,27], mirrored:true) ],
                       repeat:5, repeatDelayTics:[10,8,6,4,2])
    notes    The accelerating ripple (10→2 tics) is the mechanic: the last two
             waves arrive almost together. Both payloads are `+SEEKERMISSILE`.
             The heavy pair rolls 50-150; the light four roll 10-60 — a
             two-tier volley, which is why it is MULTI and not one FAN.

    ATTACK   RS_WhiteCybie2.Rush
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2767
    shape    CHARGE
    payload  the monster itself (A_SkullAttack(35)) + RS_RomeroGroundCH x12
    arc      the ground bursts in three 4-point rings at radius 64, 164, 234
             (diagonals only)
    timing   1 + 2 wind-up, 12 charge, 9 tics of translucency flicker,
             1 + 1 stop, then 3 ring beats at 3 tics
    damage   ram: no explicit Damage on the actor (Cyberdemon-class default);
             RS_RomeroGroundCH DamageFunction (random(20,100)) +
             A_Explode(random(10,80),64,0) x5
    type     ram --; ground Plasma
    sound    "Rome/ATK1" then "weapons/suldth"
    impact   ground bursts detonate on placement (Spawn → Goto Death)
    trigger  Missile   (Med / Med3 via `A_JumpIfCloser(1100,"Rush",true)`)
    range    ..1100 with line of sight
    mirrored yes   (all three rings are 4-fold symmetric)
    inherit  --
    profile  MakeCharge(speed:35, invulnDuringCharge:true, thruActors:true,
                        landing:{proj:"RS_RomeroGroundCH", count:12, rings:[64,164,234]})
    notes    A_SetReflectiveInvulnerable + `bTHRUACTORS` for the charge, cleared
             at the end — same construct as the Black Cybie's. Opens with
             `A_Jump(32,"BigLaser")` and `A_Jump(92,"DualShots")`, so it only
             actually charges about half the time.
             If it ends inside 200 units it goes to Dukie instead of the rings.

    ATTACK   RS_WhiteCybie2.Dukie
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2796
    shape    RING
    payload  RS_RomeroGroundCH x24
    arc      360 in three concentric rings — radius 64 (8 points: 4 axial +
             4 diagonal), 164 (8 points), 234 (8 points)
    timing   three beats, each 7 placements on 0-tic frames + 1 on a 3-tic frame
    damage   DamageFunction (random(20,100)) + A_Explode(random(10,80),64,0) x5
    type     Plasma
    sound    --   (the state plays nothing; DeathSound "weapons/rocklx" per burst)
    impact   instant detonation on placement
    trigger  Missile   (`A_JumpIfCloser(200,"Dukie",true)` from MissileSet and
                        from Close; also the Phase2 tail)
    range    ..200 with line of sight
    mirrored yes   (fully 4-fold symmetric)
    inherit  --
    profile  MakeRing(proj:"RS_RomeroGroundCH", count:24, rings:[64,164,234],
                      perRing:8, delayTics:3, placed:true)
    notes    The point-blank panic button — an expanding shockwave of floor
             detonations that clears everything within 234 units. In phase 2+
             it chains into DukieMore.

    ATTACK   RS_WhiteCybie2.DukieMore
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2824
    shape    RING
    payload  RS_RomeroGroundCH x24
    arc      360 in three further rings — radius 314, 394, 464
    timing   three beats, 7 placements at 0 tics + 1 at 2 tics each
    damage   DamageFunction (random(20,100)) + A_Explode(random(10,80),64,0) x5
    type     Plasma
    sound    --
    impact   as Dukie
    trigger  Missile   (chained from Dukie at user_phase >= 2, and from Rush)
    range    ..200 with line of sight (inherits Dukie's gate)
    mirrored yes
    inherit  --
    profile  MakeRing(proj:"RS_RomeroGroundCH", count:24, rings:[314,394,464],
                      perRing:8, delayTics:2, placed:true)
    notes    A separate row, not a repeat: different radii, tighter beats, and
             a different entry condition. Together with Dukie that is 48 floor
             detonations out to 464 units.
             CH bug carried verbatim: Dukie tests `user_phase >= 2` and then
             `>= 3` on the next line, so the second test can never fire. Kept.

    ATTACK   RS_WhiteCybie2.Nukes
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2855
    shape    RAIN
    payload  RS_WhiteFatMark x9   (+ RS_WhiteFatNukeShow x9 — deco pillars)
    arc      random(-1524,1524) x random(-1524,1524) — the whole arena
    timing   10 aim, 9 pillars at 2 tics, 9 markers at 2 tics, 10 recover.
             Each marker then burns **~70 tics** drawing its circle before the
             meteor drops.
    damage   the marker itself does none. The payload is **RS_WhiteFatNuke**
             (`RS_FatsoFX.zs:1385`): DamageFunction (random(100,200)) +
             A_Explode(random(80,155),**326**) — the largest blast radius in
             anything this family fires.
    type     Fire
    sound    "Rome/ATK2"; the marker A_Scream → DeathSound "Juggernaut/Attack";
             the nuke SeeSound "ARCAZAP7", DeathSound "NETHERDE"
    impact   Radius_Quake(15,15,0,40,0) on detonation
    trigger  Missile   (Close, Close2, Med — phases 1 and 2)
    range    ..1500
    mirrored no
    inherit  --   (the whole chain is the FATSO lane's; RS_CircleDrawMeteorCH*
                   are the DEMON lane's, `RS_DemonFX.zs:715-800`, and are deco)
    profile  MakeRain(proj:"RS_WhiteFatMark", count:9, spread:1524, fuseTics:70,
                      warhead:"RS_WhiteFatNuke", spawnZ:random(128,256),
                      damage:random(100,200), blastRadius:326)
    notes    **THE LONGEST FUSE IN THE FAMILY.** The marker spends ~70 tics
             drawing six orbiting RS_CircleDrawMeteorCH rings (all 0 damage,
             pure telegraph) before spawning the warhead at z random(128,256)
             with velz -2. That telegraph is the entire counterplay and must
             survive into any profile.
             `MMDR H 0 A_PlaySound("")` — an empty-string PlaySound, CH's own
             way of cutting the previous cue. Not a missing sound.

    ATTACK   RS_WhiteCybie2.NukieFrontal
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2861
    shape    RAIN
    payload  RS_WhiteFatMark x7   (+ RS_WhiteFatNukeShow x7 — deco)
    arc      random(256,1524) FORWARD x random(-524,524) lateral — a directed
             corridor, not the whole arena
    timing   7 pillars at 1 tic, 7 markers at 1 tic, 10 recover; same ~70-tic
             fuse per marker
    damage   as Nukes — RS_WhiteFatNuke random(100,200), A_Explode(random(80,155),326)
    type     Fire
    sound    as Nukes
    impact   as Nukes
    trigger  Missile   (chained from Nukes at user_phase >= 2)
    range    ..1500
    mirrored no
    inherit  --
    profile  MakeRain(proj:"RS_WhiteFatMark", count:7, forwardWalk:[256,1524], lateral:524,
                      fuseTics:70, warhead:"RS_WhiteFatNuke", damage:random(100,200), blastRadius:326)
    notes    A separate row: fewer warheads, half the delay between spawns, and
             aimed down the player's approach instead of scattered. The phase-2
             upgrade of Nukes.

    ATTACK   RS_WhiteCybie2.ChainMissiles
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2868
    shape    MULTI
    payload  RS_RomeroRocketCH x4 + RS_RomeroRocketCH2 x4 + RS_RomeroRocketCH3 x2
             = **10 rockets** (5 lines x 2 frames each)
    arc      0, random(-3,3), 0, random(-3,3), 0
    timing   10 aim, then 5 double-frames at 4 tics = 40 tics
    damage   DamageFunction (random(20,200))  — all three variants
    type     Fire (all three)
    sound    "Rome/ATK1"; SeeSound "weapons/hominglaunch";
             DeathSound "weapons/rocklx"
    impact   A_SetTranslucent(0.8,1), A_SetScale(1.45,0.95),
             A_Explode(random(80,180),128) — a heavy blast per rocket
    trigger  Missile   (MissileSet, Med, Close — phase 1)
    range    all bands, phase 1
    mirrored no
    inherit  --   (three sibling classes; CH3 is the only `+SEEKERMISSILE` one)
    profile  MakeMulti(parts:[ MakeBurst(proj:"RS_RomeroRocketCH", count:4, delayTics:4),
                               MakeBurst(proj:"RS_RomeroRocketCH2", count:4, delayTics:4),
                               MakeBurst(proj:"RS_RomeroRocketCH3", count:2, delayTics:4) ],
                       ofsFwd:120, ofsSide:-20, interleaved:true)
    notes    **`MMDR HI 4 A_CustomMissile(...)` IS TWO ROCKETS, NOT ONE.** Five
             lines, ten rockets. A line-count read halves this attack.
             The three variants differ ONLY in flight: CH flies straight,
             CH2 has A_Weave(3,3,3,3), CH3 has A_SeekerMissile(4,4). Same
             damage roll, same impact. The mix is the mechanic.
             `A_CheckSight("See")` then `A_Jump(32,"Missile")` to re-roll.

    ATTACK   RS_WhiteCybie2.ChainMissiles2
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2880
    shape    MULTI
    payload  RS_RomeroRocketCH x4 + RS_RomeroRocketCH2 x6 + RS_RomeroRocketCH3 x4
             = **16 rockets** (8 lines x 2)
    arc      0, random(-3,3), 0, random(-3,3), 0, 0, random(-6,6), random(-6,6)
    timing   10 aim, then double-frames at 4,4,3,3,2,2,1,1 — accelerating
    damage   DamageFunction (random(20,200))
    type     Fire
    sound    "Rome/ATK1"
    impact   as ChainMissiles
    trigger  Missile   (MissileSet2, Med2, Close2 — phase 2)
    range    all bands, phase 2
    mirrored no
    inherit  --
    profile  MakeMulti(parts:[…as ChainMissiles, counts 4/6/4…],
                       ofsFwd:120, ofsSide:-20, delayTics:[4,4,3,3,2,2,1,1], interleaved:true)
    notes    Phase-2 upgrade: 16 rockets and the cadence halves twice. The
             widening ±6 on the last two lines is the only angle change.

    ATTACK   RS_WhiteCybie2.ChainMissiles3
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2895
    shape    MULTI
    payload  RS_RomeroRocketCH x4 + RS_RomeroRocketCH2 x6 + RS_RomeroRocketCH3 x4
             = **16 rockets** (8 lines x 2)
    arc      as ChainMissiles2
    timing   10 aim, then double-frames at 2,2,2,2,1,1,1,1 — the fastest
    damage   DamageFunction (random(20,200))
    type     Fire
    sound    "Rome/ATK1"
    impact   as ChainMissiles
    trigger  Missile   (MissileSet3, Med3 — phase 3)
    range    all bands, phase 3
    mirrored no
    inherit  --
    profile  MakeMulti(parts:[…as ChainMissiles2…], delayTics:[2,2,2,2,1,1,1,1], interleaved:true)
    notes    Same rockets as ChainMissiles2, twice the rate. Kept as its own row
             because the cadence is the difference and a profile must pick one.
             Tails into `See2` (the faster chase) rather than `See`.

    ATTACK   RS_WhiteCybie2.LaserRain
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2912
    shape    RAIN
    payload  RS_RomeroSkyCH x1 (A_VileTarget, at the target)
             → RS_RomeroBeamCH x15 + RS_RomeroBeamCHTrail2 x5, falling
    arc      the sky actor spawns beams at random(-64,64) x random(-64,64)
             around the target, angle random(-359,359), pitch-velocity
             random(-33,-1) — i.e. downward
    timing   4x3 + 5x2 + 5x1 aim frames, 3+3 fire; the sky actor then runs
             5 beats at 2 tics and 15 at 1 tic
    damage   RS_RomeroSkyCH DamageFunction (random(20,100));
             RS_RomeroBeamCH DamageFunction (random(20,180)) plus
             **A_Explode(random(10,80),64,0) on FIVE frames per Fly loop** —
             it damages continuously while travelling
    type     Plasma (both)
    sound    "Rome/ATK1"; the beam SeeSound "ELECTRO7",
             DeathSound "weapons/bfgx"
    impact   the beam's Death scales to (3.0,2.5) and A_Explode(random(60,180),
             128,0) — a very heavy terminal blast
    trigger  Missile   (MissileSet2, MissileSet3, Med2, Med3)
    range    all bands, phases 2 and 3
    mirrored no
    inherit  RS_RomeroBeamCHTrail2 : RS_RomeroBeamCHTrail (`RS_CyberdemonFX.zs:3340`
             — one-line subclass, Scale only; all FX from the parent)
    profile  MakeRain(proj:"RS_RomeroSkyCH", count:1, atTarget:true, ceilingHug:true,
                      beam:"RS_RomeroBeamCH", beamCount:15, spread:64)
    notes    The only genuine top-down RAIN on this monster (Nukes fall too, but
             from a placed marker). `+CEILINGHUGGER +NOCLIP +THRUACTORS` on the
             sky actor, so it always finds the ceiling above the player.
             CH's `BRAB L` typo (a transposition of `BRBA`) in the beam's Death
             was corrected to BRBA here on the owner's "nothing invisible" rule;
             flagged so the divergence is on the record.

    ATTACK   RS_WhiteCybie2.BigLaser
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2923
    shape    BURST
    payload  RS_RomeroBeamCH x11
    arc      0 — a straight lance
    timing   4x3 aim + four 5-frame telegraph runs at 3,2,1,1 tics, then 11
             beams on consecutive 1-tic frames
    damage   DamageFunction (random(20,180)) + A_Explode(random(10,80),64,0)
             on 5 frames per Fly loop
    type     Plasma
    sound    "Rome/ATK2" on CHAN_WEAPON, then again on CHAN_AUTO
    impact   A_SetScale up to (3.8,2.15), A_Explode(random(60,180),128,0),
             DeathSound "weapons/bfgx"
    trigger  Missile   (MissileSet, MissileSet2, and A_Jump(32) out of Rush)
    range    all bands, phases 1 and 2
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_RomeroBeamCH", count:11, delayTics:1, arc:0, ofsFwd:60)
    notes    `A_GiveInventory("RS_RomeroCHWeak",1)` at the end — a
             PowerProtection with DamageFactor **1.25** and Duration -3, i.e.
             the boss takes 25% MORE damage for 3 seconds after firing. That
             self-inflicted vulnerability window is part of the attack and must
             carry into any profile that copies it.
             `A_JumpIfCloser(1000,"SweepBeam",true)` diverts to the sweep if the
             target closes during the telegraph.

    ATTACK   RS_WhiteCybie2.BigLaser2
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2935
    shape    BURST
    payload  RS_RomeroBeamCH x20   (11 + 3 + 3 + 3, with re-aims between)
    arc      0, re-aimed three times mid-burst
    timing   4x2 aim + four telegraph runs at 2,1,1,1; then 11 beams, then
             three groups of 3 with an A_FaceTarget before each
    damage   DamageFunction (random(20,180)) + per-frame A_Explode as above
    type     Plasma
    sound    "Rome/ATK2" on CHAN_WEAPON; the second cue is `A_PlaySound("")`
             (CH's deliberate silencer, not a missing sound)
    impact   as BigLaser
    trigger  Missile   (MissileSet3, Med3 — phase 3)
    range    all bands, phase 3
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_RomeroBeamCH", count:20, delayTics:1, arc:0, ofsFwd:60,
                       reaimAfter:[11,14,17])
    notes    The phase-3 lance: nearly twice the beams and it TRACKS three times
             mid-burst instead of committing to one line. Same
             RS_RomeroCHWeak self-debuff at the end.

    ATTACK   RS_WhiteCybie2.SweepBeam
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2952
    shape    BURST
    payload  RS_RomeroBeamCH x26
    arc      0 laterally, but the PITCH steps: -4 for the first 10 shots,
             -3 for the next 8, -2 for the last 8 — the beam walks UP the target
    timing   26 beams, each preceded by its own A_FaceTarget, 1 tic apart
             (52 tics of continuous tracking fire)
    damage   DamageFunction (random(20,180)) + per-frame A_Explode
    type     Plasma
    sound    "Rome/ATK2" (from LaserSweeper's entry)
    impact   as BigLaser
    trigger  Missile   (via LaserSweeper on Med2/Med3/Close2/Close3, and as the
                        close-range diversion from BigLaser / BigLaser2)
    range    ..1000 when entered as the diversion
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_RomeroBeamCH", count:26, delayTics:2, arc:0,
                       pitchWalk:[-4,-3,-2], pitchGroups:[10,8,8], reaimEveryShot:true)
    notes    **A_FaceTarget before EVERY shot** — this is a genuinely tracking
             sweep, not a fixed line. The rising pitch is the tell: it starts at
             your feet and climbs. `LaserSweeper:` is the entry ramp (3 telegraph
             runs at 3/2/1 tics) and falls straight through; recorded as one row
             because the ramp fires nothing.
             Same RS_RomeroCHWeak self-debuff at the end.

    ATTACK   RS_WhiteCybie2.ShieldUp
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2656
    shape    UNCLASSIFIED
    payload  RS_IDShieldWalk x4  +  RS_RomeroCHProtect (inventory)
    arc      the shield orbits: user_angle += 8 per tic, warping to master at
             radius 92, height 64, until user_angle >= 1800 (225 tics)
    timing   5 + 4 frames at 11 tics
    damage   --   **NONE.** RS_IDShieldWalk (`RS_CyberdemonFX.zs:3267`) is a
             Health-999 `+INVULNERABLE +REFLECTIVE +DEFLECT +SHIELDREFLECT`
             monster with no attack and no Damage.
    type     --
    sound    --
    impact   --
    trigger  Missile   (Med2, Close2 — phase 2)
    range    all bands, phase 2
    mirrored no
    inherit  --
    profile  --   (defensive; there is no attack profile here)
    notes    Recorded because it occupies an attack slot in the Missile router
             and a reader would otherwise have to re-derive that it does
             nothing offensive. RS_RomeroCHProtect is a PowerProtection with
             DamageFactor 0.5 and Duration -15 — a 15-second 50% damage
             reduction, gated so it can only be taken once
             (A_JumpIfInventory → back to Missile).

    ATTACK   RS_WhiteCybie2.BaronsPlease / BaronMore
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2534
    shape    UNCLASSIFIED
    payload  RS_RomeroBaronsCH x2 (BaronsPlease) or x4 (chaining into BaronMore)
    arc      spawned at lateral ±128, and ±218 in BaronMore
    timing   10 + 8 + 5 aim, spawns on one tic, 10 hold; BaronMore adds
             2x7 + spawns + 20
    damage   --   (the barons carry their own; see the Baron catalog)
    type     --
    sound    --   (TeleportFog is the only cue)
    impact   --
    trigger  Missile   (MissileSet3, Med3 — phase 3; also A_Jump(64) out of ShieldUp)
    range    all bands, phase 3
    mirrored yes   (always a symmetric ± pair)
    inherit  --
    profile  MakeSummon(cls:"RS_RomeroBaronsCH", count:2, ofsSide:128, extra:{count:2, ofsSide:218})
    notes    Two rows collapsed into one — BaronMore is BaronsPlease's phase-3
             tail, reached by `A_JumpIf(user_phase >= 3,"BaronMore")` inside it,
             and adds two more barons at a wider spacing. Also fired
             unconditionally by Phase2 (`:2513`) as part of the phase flip.

    ATTACK   RS_WhiteCybie2.Death
    file     zscript/monsters/cyberdemon/RS_Cyberdemon.zs:3009
    shape    SCATTER
    payload  RS_HKRedDeath x8
    arc      random(20,100) fwd, random(-30,30) side, CMF_AIMOFFSET, pitch -10
    timing   5 bursts at 10 tics, then 3 more at 10 tics
    damage   A_Explode(random(5,10),42) each
    type     Fire
    sound    A_Scream → DeathSound "Rome/ded"; each burst "world/barrelx"
    impact   A_Burst("RS_RedThingsHK"), deco
    trigger  Death
    range    --
    mirrored no
    inherit  --   (ZOMBIEMAN lane, `RS_ZombiemanFX.zs:844`)
    profile  MakeScatter(proj:"RS_HKRedDeath", count:8, cone:60, delayTics:10, damage:random(5,10), radius:42)
    notes    Third instance of the shared HKRedDeath death burst (Gray x27,
             Yellow x5, White x8). One profile, three counts.

---

# CH CROSS-CHECK — WHAT WAS COMPARED AND WHAT IT FOUND

Method: strip `//` comments from both trees, then compare (a) per-function call
counts, (b) per-payload-class call counts, (c) the state-label set of every
monster, (d) every `Damage(random(a,b))` roll.

| Check | CH | Ours | Verdict |
|---|---|---|---|
| `A_CustomMeleeAttack` | 7 | 7 | match |
| `A_CustomRailgun` | 1 | 1 | match |
| `A_SkullAttack` | 4 | 4 | match |
| `A_VileAttack` | 5 | 5 | match |
| `A_VileTarget` | 5 | 5 | match |
| `A_RadiusGive` | 3 | 3 | match |
| `A_Explode` | 79 | 66 | **13 accounted for** — all inside classes our tree hosts in other family files (Gas14 2, SwooshCBTR 1, SwooshCBTR2 1, SpiralSaw5 1, GroundRedCyb 1, MolochNail 2, MolochQuake 2, CybieZappy 1, ZapZapCB 1, TrailCB 1). Verified class by class. |
| `A_SpawnItemEx` | 415 | 411 | **4 accounted for** — same reason (SwooshCBTR→SwooshCBTR2, CybieZappy→TrailCB and →ZapZapCB, MolochNail→PuffCybieRed) |
| `A_PainAttack` | 1 | 0 | **accounted for** — RS_SummonPortalCybie lives in the cacodemon lane |
| `A_CustomMissile` | 539 | 538 | see below |
| Classes declaring a `random(a,b)` damage roll | 51 | 49 | **2 accounted for** — `MolochNail` and `MolochQuake`, hosted in the cacodemon and demon files; both carry CH's roll unchanged (`random(10,30)`, `random(5,27)`). Every other roll is class-for-class identical. |
| Classes declaring a bare `Damage N` | 14 | 14 | match — bare constants stay bare, per CH |
| Rolls flattened to a constant | — | **0** | compared class by class, both directions; nothing was flattened |
| State labels, all 16 monsters | 193 | 193 | **identical sets, no label missing or added on either side** |

The `A_CustomMissile` payload-name diff resolved to exactly two entries:

- `Rocket` — CH 3, ours 4. **Expected.** The 4th is CH's
  `ACS_NamedExecuteWithResult("CybMissile",1)` resolved to a plain aimed
  `A_CustomMissile("Rocket",60,-25,0)`. Settled finding; see
  RS_CommonCybie.Missile.
- `RomeroCHSeekBall` — **CH 32, ours 30.** A genuine divergence. CH's
  `SideWinder` fourth group is 8 shots (`CYBIES.txt:5540-5547`); ours is 6
  (`RS_Cyberdemon.zs:2701-2706`). Recorded on the row and in UNRESOLVED #1.
  **Not fixed — this catalog does not edit code.**

Everything else in this family matches CH exactly.

## External classes opened to resolve payloads (27, in 10 other family files)

`RS_PlasmaBallSP4/SP5`, `RS_MolochNail`, `RS_PortalSummons`,
`RS_SummonPortalCybie`, `RS_Zap88`, `RS_FireBluCacoBall`,
`RS_FireBluCacoBall2` (cacodemon) · `RS_MolochQuake`, `RS_ZapZapCB`,
`RS_RedThingsLS`, `RS_SpikeCyanRev`, `RS_Splash11`,
`RS_SplashAbyssBubbleDemon`, `RS_CircleDrawMeteorCH`, `RS_WDRock4` (demon) ·
`RS_VileGroundSpike`, `RS_VileGroundSpikes2`, `RS_SplashAbyssVile2` (archvile) ·
`RS_BaronOfDirtCH3`, `RS_GreeniesBR`, `RS_CommonBaron` (baron) ·
`RS_SwooshCBTR`, `RS_SwooshCBTR2`, `RS_BluCybFX`, `RS_PurpleHK`,
`RS_YellowHK` (hellknight) · `RS_WhiteFatNukeShow`, `RS_WhiteFatMark`,
`RS_WhiteFatNuke`, `RS_WhiteFatRB3`, `RS_WhiteFatRB4` (fatso) ·
`RS_SpamShotsCguy`, `RS_SpiralSaw5`, `RS_GroundRedCyb`, `RS_PuffCybieRed`,
`RS_Trail12` (chaingunner) · `RS_CyanCybieGunFlare`, `RS_CybieZappy`,
`RS_TrailCB` (revenant) · `RS_CHBSTarget`, `RS_Gas14`, `RS_SparkPuff1`
(shotgunner) · `RS_HKRedDeath`, `RS_FireSGguy2`, `RS_TrailSP2`,
`RS_AbyssShotIdentifier`, `RS_SplashAbyss`, `RS_SplashAbyss2` (zombieman).

All resolve. None is missing from the tree.

---

# UNRESOLVED

**1. RS_WhiteCybie2.SideWinder fires 22 seek balls here and 24 in CH.**
Ours: `zscript/monsters/cyberdemon/RS_Cyberdemon.zs:2701-2706` (three L/R pairs
in the fourth group). CH: `CYBIES.txt:5540-5547` (four pairs). Family totals 30
vs 32. Everything else about the state is byte-identical. I did not edit the
file — this catalog is documentation only. **Someone with write authority
should decide whether to restore the missing pair.** I have no evidence about
whether the drop was deliberate; nothing in the file header or any comment
mentions SideWinder.

**2. CH is not at the path this task and the spec name.**
Both name `C:\Users\Command\Desktop\CH`. That directory **does not exist** —
`C:\Users\Command\Desktop\` contains `CHP` but no `CH`. I used
`E:\New folder\ART SOURCE\CH\`, which CLAUDE.md's "IMPORTING A MONSTER MEANS
THE WHOLE MONSTER" section names as CH's location for exactly this purpose, and
whose `decorate/CYBIES.txt` is 6,285 lines — matching the count both source
files cite in their headers. **If the owner considers that a different copy,
every CH claim in this file needs re-running against the right one.** I did not
search any drive for it and I did not read anything else under `ART SOURCE`.

**3. Three sounds these attacks call do not exist, in CH either.**
Not a gap in the import — the attacks are silent in CH too, and the code is
verbatim. Listed so no one "fixes" them into existence:
`"CybieLow"` (Gray Cybie Missiles2 — CH defines `CybLow` only, SNDINFO.txt:453),
`"moloch/wraithmelee"` (Moloch Wraith Melee — CH defines `/wraith`,
`/wraithattack`, `/wraithdie` and nothing else),
`"weapons/onfire"` (both pentagram fires),
`"monsters/hamflr"` (Smith hammer death, a plural typo for CH's own singular),
`"holy2/holy4"` (the hell portal's SeeSound).
**Any profile derived from these rows must supply its own sound**, per the
spec's four-rung chain — do not carry the dead name through.

**4. Shape-vocabulary question the composer must settle across all 17 files.**
The closed set has no word for **placement delivery** — `A_VileTarget`, which
spawns a damaging actor AT the target with no travel and no fall. This family
has five: Brown PoolOfGoo, Gray's rockslide, Purple's PurpleWorryCB, White's
LaserRain, and (by `A_SpawnItemEx` rather than VileTarget) White's ID/Dukie
grids. I used **RAIN** for all of them and added `atTarget:true` /
`placed:true` to the profile call, except White's ID where I used **SALVO**
because 24-in-one-instant is its defining property and it is centred on the
shooter, not the target. **I did not coin a word.** If other lanes wrote
`UNCLASSIFIED` for the same construct, the two conventions need reconciling at
compose time — this is the most likely place the seventeen files disagree.

**5. `RS_BlackCybie2` declares `MeleeSound "monster/hamhit"` and never plays it.**
`MeleeSound` is consumed by `A_MeleeAttack`; the actor uses
`A_CustomMeleeAttack(random(50,125))` with no sound argument, which defaults to
`""`. Identical in CH, so it is faithful — but the hammer's actual *hit* is
silent and only the swing and floor-slam are audible. Flagged because a profile
built from that row would otherwise inherit a sound that never fires. **Not
verified in-game**, only from the engine's function signature.

**6. Two payload chains were traced to their end but not observed running.**
Red Cybie's `RS_RedCybieVolcano1` → `RS_RedCybieVolcano2` → repeated
`RS_VolcanoBall1` eruptions, and Black Cybie's `RS_BigHellshot` →
`RS_HellWaver2` → 24-tracer rings on a `A_Jump(128)` loop. Both are bounded in
code (`user_uptime >= 33`; the jump eventually fails), but **the total damage
output of either is a function of random rolls I did not simulate.** The rows
record the per-tick numbers, not a total. Anyone tuning a profile off them
should measure rather than trust an estimate.

**7. Three trigger routes are technically reachable but statistically dead, and
I recorded them as live.**
`RS_AbyssCybie2.Missile` opens with `A_Jump(255,"Bubble")` — 255/256 — so
`Wave`, `Rocket` and `RedDed` are reached from the top of Missile once in 256
casts. They are reached normally through `Choices`, so the rows are real; but
if a reader assumes the range gates below that jump are load-bearing, they are
not. Same construct in CH (`CYBIES.txt:1218`). Similarly `RS_WhiteCybie2.Dukie`
tests `user_phase >= 2` then `>= 3` on the next line — the second test can never
fire. CH's, kept verbatim.

**8. `RS_BluCybFX` is fired by `A_CustomMissile` 21 times across the Blue
Cybie's three attacks and is not a weapon.**
Verified at `zscript/monsters/hellknight/RS_HellKnightFX.zs:761`: Speed 1, no
`Damage`, no `DamageFunction`, a 6-frame `PLSE` animation. Likewise
`RS_Zap88` (4 calls in the Black Cybie's LightningCall) at
`zscript/monsters/cacodemon/RS_CacodemonFX.zs:66`: no `Damage`,
`+NOINTERACTION`. **Both read exactly like payloads at the call site.**
I have excluded them from every payload count. If another lane's file counted
its own equivalents as payloads, the two files will not compose consistently —
worth one grep at compose time.
