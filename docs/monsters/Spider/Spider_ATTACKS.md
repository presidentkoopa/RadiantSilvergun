# SPIDER (Arachnotron) — MONSTER ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Field order is fixed and
the shape vocabulary is the spec's closed set. No word here is coined.

## DENOMINATORS — what was actually read

| Thing | Count | Note |
|---|---|---|
| Classes in `zscript/monsters/spider/RS_Spider.zs` | **27, all read** | 19 carry `Monster;`; 8 are cvar-gate / spawner stubs with no combat |
| Classes in `zscript/monsters/spider/RS_SpiderFX.zs` | **80, all read** | projectiles, trails, overlays, 4 RandomSpawners, 3 inventory tokens |
| External classes opened to resolve payloads | **16** | in 9 other families' FX files — listed under "External payloads" below |
| Attack-bearing state labels | **57** | in `RS_Spider.zs` |
| Router / windup / reposition labels followed | **20** | `Missile:` routers, `Choice1/2`, `Missin`, `Voidi`, `Breath`, `Set2`, `ChoicesMore`, `Miss33`, `Jumps`, `Warp`, `IStuck` |
| Attack call sites, **as written**, comments stripped | **276** | `A_CustomMissile` 232, `A_CustomRailgun` 24, `A_PainAttack` 7, `A_DualPainAttack` 4, `A_CustomBulletAttack` 3, `A_VileAttack` 2, `A_MeleeAttack` 1, `A_CustomMeleeAttack` 1, `A_BspiAttack` 1, `A_Burst` 1 |
| Attack call sites, **as fired** (frame-letter repeats fire once per frame) | **338** | `A_CustomMissile` 247, `A_CustomRailgun` 24, `A_SpawnItemEx` of a live payload 53, `A_PainAttack` 7, `A_DualPainAttack` 4, `A_CustomBulletAttack` 3 |
| Refire loop controls | **14** | `A_SpidRefire` 8, `A_MonsterRefire` 6 |
| Monsters with attacks | **19** | 13 tier ladder + EX + 3 white split-forms + 2 minions |
| **ATTACK ROWS WRITTEN** | **62** | 56 monster rows + 6 secondary (payload-is-an-attack) rows |

Counts are over `sed 's|//.*||'`-stripped source, per CLAUDE.md. The two
call-site numbers differ because `BSPI GG 2 Bright A_CustomMissile(...)` is one
written line and two firings; both denominators are given so neither is a lie.

## SHAPE-ASSIGNMENT RULES USED (so seventeen files compose)

The closed set leaves three genuine ambiguities. These are the rules applied
here, stated so a reader can re-derive every classification:

1. **Literal stepped angles → FAN. One shared rolled cone → SCATTER.**
   `A_CustomMissile(...,-15)` … `(...,15)` is FAN. Ten shots all at
   `random(-7,7)` is SCATTER.
2. **Deliberately different *centres*, even if each is a roll, → FAN.**
   Brown's `random(-1,1)` / `random(-7,-2)` / `random(2,7)` is three bands, so
   FAN — not SCATTER.
3. **A shared centre with a roll of ≤ ±3° is aim jitter, not a spread → BURST**
   (or SINGLE at n=1). The roll is still recorded verbatim in `arc`.
4. **Two or more distinct payload *classes* in one attack → MULTI**, applied
   literally per the spec, with the geometric sub-shape named in `notes`. This
   catches palette-variant pairs (`RS_PlasmaBallSPFB3`/`FB4`) as MULTI; that is
   the literal reading and it composes.
5. `spawnofs_xy` (arg 3 of `A_CustomMissile`) is a **lateral muzzle offset**,
   not an angle. It never contributes to `arc`; it is recorded separately.

## THE FAMILY'S SIGNATURE, AND WHAT BOUNDS ITS LOOPS

Eight of these attacks are a **BURST from a self-looping refire state**. There
is no shot count anywhere in this family — the loop is bounded by an engine
refire call and, on six of them, an additional explicit `A_Jump` bail. What is
recorded per row is the **cycle period in tics** and the **literal exit
condition**, never a guessed round count.

| Loop | Cycle | Explicit bail | Other exit |
|---|---|---|---|
| `RS_CommonSP1.Missile` | 9 tics | — | `A_SpidRefire` |
| `RS_GreenSP1.Missile` | 16 tics, 2 rounds | `A_Jump(128,"Missile")` — 50 % to repeat | falls to `See` |
| `RS_BlueSP1.Missile` | **7 tics** | — | `A_MonsterRefire(128,"See")` |
| `RS_PurpleSP1.Missile` | 5 tics | — | `A_MonsterRefire(200,"See")` |
| `RS_YellowSP1.Psyche1` | 4 tics | `A_Jump(42,"See")` ≈ 16.4 % | `A_SpidRefire` |
| `RS_RedSP1.Missile` | 8 tics, 2 rounds | — | `A_SpidRefire` |
| `RS_CyanSP2.IceBombing` | 8 tics | — | `A_CheckSight("See")` + `A_SpidRefire` |
| `RS_FireBluSP2.Psyche1` | 8 tics, 22 rounds | `A_Jump(32,"See")` ≈ 12.5 % | `A_SpidRefire` |
| `RS_FireBluSP2.Psyche2` | 10 tics, 4 rounds | — | `A_MonsterRefire(128,"See")` |
| `RS_AbyssSP2.Miss2` | 6 tics | — | `A_SpidRefire` |
| `RS_AbyssSP2.Voidi2` | **107 tics** | `A_Jump(16,"See")` ≈ 6.25 % | `A_SpidRefire` |
| `RS_AbyssSP2.Breath2` | 10 tics, 7 rounds | `A_Jump(32,"Warp")` ≈ 12.5 % | `A_SpidRefire` |
| `RS_BlackSP2.Miss1` | 8 tics, 2 rounds | `A_Jump(12,"Miss3")` ≈ 4.7 % escalate | `A_MonsterRefire(128,"See")` |
| `RS_BlackSPEX.Miss1` | 8 tics, 2 rounds | `A_Jump(12,"Miss3")` ≈ 4.7 % escalate | `A_MonsterRefire(128,"See")` |
| `RS_BlackSPEX.Miss6` | 20 tics, 6 rounds | — | `A_MonsterRefire(128,"See")` |

**`RS_BlueSP1.Missile` at 7 tics is the tightest sustained round in the family**
and is the closest thing here to a player plasma rifle. It is the reference
BURST profile.

## EXTERNAL PAYLOADS — every off-file class opened

| Class | Defined at | Used by |
|---|---|---|
| `RS_PlasmaBallSP3` | `zscript/monsters/zombieman/RS_ZombiemanFX.zs:871` | Blue |
| `RS_IceOrbCyanAra1` | `zscript/monsters/painelemental/RS_PainElementalFX.zs:496` | Cyan |
| `RS_IceOrbCyanAra2` | `zscript/monsters/painelemental/RS_PainElementalFX.zs:537` | Cyan |
| `RS_FatsoSpikes2` | `zscript/monsters/imp/RS_ImpFX.zs:216` | Gray |
| `RS_CHBSTarget` | `zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:807` | Gray (marker) |
| `RS_RedDotSGPuff` | `zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:429` | White Atk2 |
| `RS_WhiteFatRB` | `zscript/monsters/fatso/RS_FatsoFX.zs:1468` | White Atk2 |
| `RS_WhiteFatRB2` | `zscript/monsters/fatso/RS_FatsoFX.zs:1564` | White Atk2 |
| `RS_SlimeBall1`–`5` | `zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:1139,1166-1169` | White Atk4 |
| `RS_MediCacoBrown` | `zscript/monsters/spectre/RS_SpectreFX.zs:123` | Brown (heal) |
| `RS_ZapFFAT` | `zscript/monsters/revenant/RS_RevenantFX.zs:2003` | Brown orb death |
| `RS_FrostWingBaron` | `zscript/monsters/baron/RS_BaronFX.zs:667` | Cyan bomb trail |
| `RS_BaronStar3` | `zscript/monsters/hellknight/RS_HellKnightFX.zs:833` | `RS_BBSP1` |
| `RS_RedMessImp` | `zscript/monsters/shotgunner/RS_ShotgunnerFX.zs:287` | `RS_RedBombSP` trail |
| `RS_Trail12` | `zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:111` | `RS_Spspit` trail |
| `RS_EXPLOSIONSCGuyEXDelayd` | `zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:835` | spiral shot death |
| `RS_HomingRocketTrailFatso` | `zscript/monsters/lostsoul/RS_LostSoulFX.zs:2705` | SpRocket4/4EX trail |
| `RS_SplashAbyss2` | `zscript/monsters/zombieman/RS_ZombiemanFX.zs:735` | abyss breath death |

`RS_ArachnotronPlasma2` (`RS_SpiderFX.zs:614`) is reached **only** through
`replaces ArachnotronPlasma` — no source line names it. A grep-by-name for the
Common spider's payload returns nothing; that is not a missing payload.

---

# ROWS

## Tier 1 — RS_CommonSP1 ("Arachnotron")

```
ATTACK   RS_CommonSP1.Missile
file     zscript/monsters/spider/RS_Spider.zs:244
shape    BURST
payload  RS_ArachnotronPlasma2 x1 per round, unbounded rounds
arc      --   (A_BspiAttack applies the engine's own aim, no author spread)
timing   9-tic cycle (4 fire / 4 / 1 refire); 20-tic A_FaceTarget on entry only
damage   Damage 5   (bare int: the engine rolls it 5..40 -- FX header says so at RS_SpiderFX.zs:870)
type     Plasma
sound    --   (state plays nothing; the payload's SeeSound "baby/attack" fires on spawn)
impact   APBX ABCDE 5 Bright, no A_Explode; DeathSound "baby/shotx"
trigger  Missile
range    --
mirrored no
inherit  --   (payload is a bare Actor; nothing inherited)
profile  MakeBurst(proj:"RS_ArachnotronPlasma2", count:3, delayTics:9, fireSnd:"baby/attack")
notes    THE ONLY ATTACK IN THIS FAMILY THAT NAMES NO PAYLOAD IN SOURCE. A_BspiAttack
         fires the vanilla ArachnotronPlasma, which RS_ArachnotronPlasma2 replaces
         (RS_SpiderFX.zs:614). Loop re-enters at Missile+1, i.e. the 20-tic windup is
         paid once. count:3 in the profile is an authored default, NOT a measured
         round count -- the loop has none; see the loop table above.
```

## Tier 2 — RS_GreenSP1 ("Green Arachnotron")

```
ATTACK   RS_GreenSP1.Missile
file     zscript/monsters/spider/RS_Spider.zs:361
shape    BURST
payload  RS_Spspit x2 per pass
arc      --   (shot 1 dead-on, shot 2 random(-1,1) -- aim jitter, rule 3)
timing   7,7 tics; 8-tic A_FaceTarget windup; 2-tic tail
damage   DamageFunction (random(8,50))
type     Plasma
sound    --   (state silent; payload SeeSound "baron/attack")
impact   BAL7 CD, then a 12-gob RING -- see RS_Spspit.Death row; DeathSound "weapons/plasmax"
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_Spspit", count:2, delayTics:7, fireSnd:"baron/attack")
notes    A_Jump(128,"Missile") at the tail re-runs the WHOLE state including the
         8-tic windup -- a 50%-per-pass repeat, not a tight refire. Payload also
         lays an RS_Trail12 every 3 tics.
```

```
ATTACK   RS_Spspit.Death   (SECONDARY -- the payload is itself an attack)
file     zscript/monsters/spider/RS_SpiderFX.zs:742
shape    RING
payload  RS_SSpit2 x12
arc      360   (four quadrant bands of 3: random(0,89) / (90,179) / (180,269) / (270,359))
timing   one tic -- all 12 on a single 0-tic frame
damage   DamageFunction (random(1,4))
type     Plasma
sound    --   (RS_SSpit2 SeeSound is the literal string "None")
impact   BOGY DEF 4 Bright + A_NoGravity; DeathSound "weapons/plasmax"
trigger  Death   (of the parent projectile)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_SSpit2", count:12, arc:360)
notes    RS_SSpit2 is -NOGRAVITY, so the ring ARCS AND FALLS -- it is a ground
         spray, not a horizontal ring. Speed 14. This is the whole reason the
         green spider's plasma is dangerous at low damage.
```

## Tier 3 — RS_BlueSP1 ("Blue Arachnotron") — THE REFERENCE BURST

```
ATTACK   RS_BlueSP1.Missile
file     zscript/monsters/spider/RS_Spider.zs:478
shape    BURST
payload  RS_PlasmaBallSP3 x1 per round, unbounded rounds
arc      --   (random(-1,1) aim jitter, rule 3)
timing   7-tic cycle (4 fire / 3 refire); 20-tic A_FaceTarget on entry only
damage   Damage 5   (bare int: engine rolls 5..40)
type     Plasma
sound    --   (payload SeeSound "weapons/plasmaf")
impact   PLSE ABCDE 4 Bright, no A_Explode; DeathSound "weapons/plasmax"
trigger  Missile
range    --
mirrored no
inherit  --   (RS_PlasmaBallSP3 is a bare Actor, zombieman FX:871)
profile  MakeBurst(proj:"RS_PlasmaBallSP3", count:4, delayTics:7, fireSnd:"weapons/plasmaf")
notes    THE FAMILY'S SIGNATURE SUSTAINED PLASMA BURST, and the tightest loop
         here. Bounded by A_MonsterRefire(128,"See") -- NO fixed round count.
         `Goto Missile+1` lands on the 0-tic tier-icon frame, so the effective
         cycle is exactly 4+3 tics. count:4 is an authored default for the
         profile, not a measured value.
```

## Tier 4 — RS_PurpleSP1 ("Purple Arachnotron")

```
ATTACK   RS_PurpleSP1.Missile
file     zscript/monsters/spider/RS_Spider.zs:595
shape    HITSCAN
payload  A_CustomBulletAttack -- default BulletPuff, random(1,4) bullets per round
arc      12 h x 8 v   (spread args 6 and 4 = +-6 horizontal, +-4 vertical)
timing   5-tic cycle (3 fire / 2 refire); 20-tic A_FaceTarget on entry only
damage   random(1,3) per bullet, as written
type     --   (no damagetype arg; default)
sound    A_PlaySound("grunt/attack") on a 0-tic frame -- SEE NOTES, this is silent
impact   default BulletPuff (no puff class passed)
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeHitscan(fireSnd:"grunt/attack", spreadScale:6.0)   // pellets random(1,4) is not expressible in one arg
notes    THE ONLY HITSCAN ON THE TIER LADDER. "grunt/attack" IS DEFINED NOWHERE
         IN CH's SNDINFO and matches no lump -- silent in CH too; kept verbatim
         (RS_SpiderFX.zs:50-52). A_MonsterRefire's 200 is the engine's refire
         parameter, not a round count. The engine may apply its own damage
         multiplier to damageperbullet unless CBAF_NORANDOM -- see UNRESOLVED.
```

## Tier 5 — RS_YellowSP1 ("Orange Brainchoton")

Missile at `:713` is a pure router: `A_JumpIfCloser(1300,"Psyche1")`, else
`A_Jump(255,"Psyche2")`. It is not a row.

```
ATTACK   RS_YellowSP1.Melee
file     zscript/monsters/spider/RS_Spider.zs:711
shape    MELEE
payload  --
arc      --
timing   5,5 tics windup, 6-tic strike
damage   MeleeDamage 6   (engine applies its own hit-dice roll -- see UNRESOLVED)
type     --
sound    MeleeSound "aracnorb/melee"   (played by A_MeleeAttack, not by the state)
impact   --
trigger  Melee
range    --   (engine melee range)
mirrored no
inherit  --
profile  MakeMelee(fireSnd:"aracnorb/melee")
notes    The only true A_MeleeAttack in the family. HitObituary "%o had %p skull
         chewed up by the yellow arachno".
```

```
ATTACK   RS_YellowSP1.Psyche1
file     zscript/monsters/spider/RS_Spider.zs:751
shape    BURST
payload  RS_AracnorbBall x1 per round, unbounded rounds
arc      --   (random(-3,3) aim jitter, rule 3)
timing   4-tic cycle (2 fire / 2 / 0 / 0)
damage   DamageFunction (random(10,50))
type     --   (NO DamageType set on RS_AracnorbBall -- normal damage)
sound    --   (payload SeeSound "baby/attack")
impact   ACNF CDEFG 5 Bright, no A_Explode; DeathSound "baby/shotx"
trigger  Missile   (via A_JumpIfCloser(1300) from Missile)
range    ..1300
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_AracnorbBall", count:4, delayTics:4, fireSnd:"baby/attack")
notes    Payload is +SEEKERMISSILE +STRIFEDAMAGE at Speed 11 with
         A_BishopMissileWeave -- slow, weaving, homing. Exit is A_Jump(42,"See")
         (~16.4%) then A_SpidRefire.
```

```
ATTACK   RS_YellowSP1.Psyche2
file     zscript/monsters/spider/RS_Spider.zs:721
shape    VILE
payload  A_VileAttack -- no travelling round. 7 damage-0 A_CustomRailgun beams telegraph it.
arc      --
timing   ~118-tic cycle. Rails at +13/+4/+13/+4/+9/+13 tic gaps over ~101 tics,
         then 2 x A_VileTarget, then the 12-tic A_VileAttack, then 5-tic tail.
damage   A_VileAttack initialdmg random(40,80); blastdmg 0, blastradius 0, thrustfac 0
type     getoutofmyheadcharles
sound    A_VileAttack snd "electricplasma/hit"; A_PlaySound("Vile/Active",7,2,false,ATTN_NONE) x2 at ATTN_NONE (map-wide)
impact   none in flight -- there is no flight. Rails spawn RS_PsychicAra puffs
         (RS_SpiderFX.zs:782, NO Damage set) and RS_PsychicPulse trail actors
         (RS_SpiderFX.zs:871, no Damage) at sparsity 0.8. BOTH DEAL ZERO DAMAGE.
trigger  Missile   (the >1300 branch: A_Jump(255,"Psyche2"))
range    1300..
mirrored no
inherit  --
profile  MakeHitscan(fireSnd:"electricplasma/hit", profName:"psychic-burn")
notes    THE SEVEN RAILGUNS DO NOTHING. A_CustomRailgun's first arg is 0, and
         neither the pufftype nor the spawnclass carries damage -- the entire
         3.5-second rail sequence is a telegraph, and every point of damage
         lands in the single A_VileAttack at the end. Classified VILE, not
         MULTI, for that reason; the rails are wind-up, not payload.
         Loops back through Missile, so range is re-checked each pass.
```

## Tier 6 — RS_RedSP1 ("Red Rage Arachnotron")

```
ATTACK   RS_RedSP1.Missile
file     zscript/monsters/spider/RS_Spider.zs:860
shape    BURST
payload  RS_RedBombSP x2 per round, unbounded rounds
arc      --   (no angle arg at all -- both shots dead-on)
timing   8-tic cycle: fire L (2) / 2 / fire R (2) / 2 refire. 25-tic entry windup.
damage   DamageFunction (random(5,40))
type     Plasma
sound    --   (payload SeeSound "weapons/hominglaunch")
impact   5-shard cluster -- see RS_RedBombSP.Death row; DeathSound "weapons/firex4"
trigger  Missile
range    --
mirrored yes   (alternates spawnofs_xy -12 / +12 -- opposite shoulders, same aim)
inherit  --
profile  MakeBurst(proj:"RS_RedBombSP", count:4, delayTics:4, fireSnd:"weapons/hominglaunch")
notes    The +-12 is spawnofs_xy, a LATERAL MUZZLE OFFSET, not an angle (rule 5) --
         both bombs fly straight at the target from opposite shoulders. Payload is
         +SEEKERMISSILE with A_SeekerMissile(3,5) and A_Weave(1,1,2,1). Sets NOPAIN
         for the whole attack (a 5-tic frame at :859) and clears it in See.
```

```
ATTACK   RS_RedBombSP.Death   (SECONDARY)
file     zscript/monsters/spider/RS_SpiderFX.zs:1000
shape    SCATTER
payload  RS_SPShard x5
arc      see notes -- the arg slots are shifted, this is NOT a clean 360
timing   1,1,1,1,1 tics (frames C,D,D,E,E)
damage   DamageFunction (random(5,10))
type     DImp
sound    --   (payload SeeSound "imp/attack")
impact   BAL1 CDE 1 A_SetTranslucent(0.35); DeathSound "weapons/firex4"
trigger  Death   (of the parent bomb)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_SPShard", count:5, arc:0, pitchJitter:360)
notes    ARG-ORDER ODDITY, PRESERVED FROM CH VERBATIM (CH Spiders.txt:2458 is
         byte-identical to ours). A_CustomMissile("RS_SPShard",5,0,CMF_AIMOFFSET,
         random(0,360),random(0,360)) puts CMF_AIMOFFSET in the ANGLE slot (a
         small constant yaw), the first random(0,360) in the FLAGS slot (a
         garbage bitmask), and the second in PITCH. The intent was almost
         certainly (...,random(0,360),CMF_AIMOFFSET,random(0,360)). Net effect:
         the shards spray by PITCH at a near-fixed yaw. Do not "fix" this when
         rebuilding -- record it. Shards are +SEEKERMISSILE at Speed 32.
```

## Tier 13 — RS_BrownSP2 ("Brown Recluse")

```
ATTACK   RS_BrownSP2.Missile
file     zscript/monsters/spider/RS_Spider.zs:983
shape    FAN
payload  RS_BrownOrbSpiderCH x8   [+ 5x RS_MediCacoBrown healing motes, no damage]
arc      14   (four bands of 2: random(-1,1), random(-7,-2), random(2,7), random(-1,1) -- rule 2)
timing   2,2,2,2,2,2,2,2 tics (16 tics of fire); 8-tic A_FaceTarget windup
damage   Damage 0   (!!)  -- see notes
type     Plasma
sound    --   (payload SeeSound "baby/attack")
impact   RIP1 DEFGH 3 Bright A_Explode(random(2,8),64) on FIVE consecutive frames
         (5 separate blasts), + 4x RS_ZapFFAT; DeathSound "Litn/litn3".
         Payload also has an XDeath branch -- see the RS_BrownOrbSpiderCH.XDeath row.
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_BrownOrbSpiderCH", count:8, arc:14, fireSnd:"baby/attack")
notes    THE ORB'S DIRECT DAMAGE IS ZERO -- all of it lands as five stacked
         A_Explode(random(2,8),64) on impact. This is a support monster: the same
         state also fires A_RadiusGive("Health",320,RGF_MONSTERS,200) at :981
         (heals every monster within 320 for 200) and spits 5 RS_MediCacoBrown.
         Orb is +MTHRUSPECIES +THRUGHOST +HITTARGET, Speed 28, A_BishopMissileWeave,
         lays RS_TrailBrownSP. The heal is a separate profile:
         MakeRadial(radius:320, heal:200, hitsAllies:true).
```

```
ATTACK   RS_BrownOrbSpiderCH.XDeath   (SECONDARY)
file     zscript/monsters/spider/RS_SpiderFX.zs:106
shape    VILE
payload  A_VileTarget("RS_TrailBrownSP") marker, then A_VileAttack
arc      --
timing   1 tic marker, 1 tic burn
damage   A_VileAttack initialdmg random(10,30), blastdmg random(10,30), blastradius 64, thrustfac 4
type     Plasma
sound    A_VileAttack snd "weapons/bfgx"
impact   4x RS_ZapFFAT (revenant FX:2003), then A_Die
trigger  XDeath   (of the projectile)
range    --
mirrored no
inherit  --
profile  MakeRadial(radius:64, damage:30, fireSnd:"weapons/bfgx")
notes    Branches on A_CheckFlag("ismonster","Nah",AAPTR_TARGET): a NON-monster
         target routes to "Nah" (RS_SpiderFX.zs:111), which is the HEAL instead --
         A_RadiusGive("Health",320,RGF_MONSTERS,200) + 5 RS_MediCacoBrown. So the
         same orb burns monsters and heals around non-monsters.
         WHETHER A PROJECTILE EVER REACHES `XDeath` (vs Death.Extreme) IS NOT
         SETTLED HERE -- see UNRESOLVED.
```

## Tier 12 — RS_CyanSP2 ("Cyan Flying Spider")

`Melee:` at `:1130` FALLS THROUGH into `Missile:` at `:1131` — this monster has
no melee attack; the melee trigger runs the ranged router. Router is
`A_Jump(255,"IceBombing","IceOrbs")`, an even 50/50.

```
ATTACK   RS_CyanSP2.IceBombing
file     zscript/monsters/spider/RS_Spider.zs:1139
shape    BURST
payload  RS_SpiderCyanBomb x1 per round, unbounded rounds
arc      --   (random(-1,1) aim jitter, rule 3)
timing   8-tic cycle (3 face / 3 fire / 2 refire)
damage   DamageFunction (random(11,44))
type     Ice
sound    --   (payload SeeSound "Spell/SpellCast1")
impact   IN-FLIGHT: A_Explode(random(2,12),32,0) EVERY 5-tic Fly loop -- the bomb
         damages continuously as it travels. On arrival: SPIR A-E, NO A_Explode;
         DeathSound "Fire/Fire4". Trails RS_FrostWingBaron.
trigger  Missile / Melee   (both routers land here)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_SpiderCyanBomb", count:4, delayTics:8, fireSnd:"Spell/SpellCast1")
notes    MULTI-FRAME A_EXPLODE, DELIBERATE -- the in-flight blast is the attack's
         real damage source, not a bug (cf. CLAUDE.md / the 219-site note).
         Payload is +SEEKERMISSILE at Speed 45 with A_SeekerMissile(1,1).
         Exit is A_CheckSight("See") then A_SpidRefire.
```

```
ATTACK   RS_CyanSP2.IceOrbs
file     zscript/monsters/spider/RS_Spider.zs:1146
shape    MULTI
payload  RS_IceOrbCyanAra1 x1 + RS_IceOrbCyanAra2 x1
arc      --   (both straight; orb 1 carries pitch random(-3,3))
timing   0,4 tics -- effectively together; 18-tic windup, 6-tic tail
damage   orb1 DamageFunction (random(10,45)); orb2 DamageFunction (random(10,50))
type     Ice (both)
sound    --   (both SeeSound "ice/Cast")
impact   both: ICEY FGHI 5 Bright A_Explode(random(5,12),32) on FOUR frames;
         DeathSound "Ice/Hit2", BounceSound "Ice/Splode"
trigger  Missile / Melee
range    --
mirrored no
inherit  --   (both are bare Actors in the pain-elemental lane)
profile  MakeVolley(proj:"RS_IceOrbCyanAra1", count:1, pitchJitter:3)
         + MakeVolley(proj:"RS_IceOrbCyanAra2", count:1)   // two profiles, fired together
notes    THE TWO ORBS BEHAVE COMPLETELY DIFFERENTLY and that is the point.
         Orb1: +SEEKERMISSILE, BounceType Doom, BounceCount 7, BounceFactor 1.25,
         WallBounceFactor 1.25, Gravity 0.5, A_Weave -- a homing bouncer that
         gains speed. Orb2: no seeker, no bounce, but A_Jump(32,"A1") into
         ThrustThing(random(0,255),random(1,12)) -- it randomly lurches sideways.
         Fired on one beat, so a player weapon needs both rounds in one shot.
```

## Tier 7 — RS_FireBluSP2 ("Ugly floater")

Missile at `:1247` is a router: `A_JumpIfCloser(1300,"Psyche1")`, else `A_Jump(255,"Psyche2")`.

```
ATTACK   RS_FireBluSP2.Psyche1
file     zscript/monsters/spider/RS_Spider.zs:1263
shape    MULTI
payload  RS_PlasmaBallSPFB1 x6 + RS_PlasmaBallSPFB2 x6 + RS_PlasmaBallSPFB3 x5 + RS_PlasmaBallSPFB4 x5  = 22
arc      360 (the ring) + 240 (the scatter) + 24 (the pair)
timing   ONE TIC -- 21 of the 22 sit on 0-tic frames, the 22nd on a 1-tic frame.
         Then 5 + 2 tic tail, then the loop.
damage   FB1..FB4 all Damage 5   (bare int: engine rolls 5..40 each)
type     Plasma (all four)
sound    --   (all four SeeSound "fire/fire3")
impact   all four: PLSE ABCDE 4 Bright, no A_Explode; DeathSound "weapons/plasmax"
trigger  Missile   (via A_JumpIfCloser(1300))
range    ..1300
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_PlasmaBallSPFB1", count:12, arc:360)
         + MakeVolley(proj:"RS_PlasmaBallSPFB3", count:8,  arc:240)
         + MakeVolley(proj:"RS_PlasmaBallSPFB3", count:2,  arc:24)
notes    THE BIGGEST SINGLE-TIC OUTPUT IN THE FAMILY: 22 rounds on one tic, on an
         8-tic loop. Three geometries stacked --
           (a) RING: 12 balls at LITERAL 15,45,75,...,345 (30-degree steps, full
               360), alternating FB1/FB2, from RS_Spider.zs:1263-1274;
           (b) SCATTER: 8 balls at random(-120,120), alternating FB3/FB4, :1275-1282;
           (c) 2 near-aimed at random(-12,12), :1283-1284.
         FB1/FB2 are Speed 20 and +SEEKERMISSILE with A_BishopMissileWeave -- the
         RING HOMES. FB3/FB4 are Speed 33 and do not. FB2 and FB3 carry a palette
         Translation the others lack; that is the ONLY difference within each pair.
         Loop exit: A_Jump(32,"See") ~12.5% then A_SpidRefire.
```

```
ATTACK   RS_FireBluSP2.Psyche2
file     zscript/monsters/spider/RS_Spider.zs:1255
shape    MULTI
payload  RS_PlasmaBallSPFB3 x2 + RS_PlasmaBallSPFB4 x2 per round, unbounded rounds
arc      --   (all four at literal angle 0)
timing   1,1,2,2 tics; 2-tic windup, 2-tic refire = 10-tic cycle
damage   Damage 5 each   (engine rolls 5..40)
type     Plasma
sound    --   (SeeSound "fire/fire3")
impact   PLSE ABCDE 4 Bright, no A_Explode; DeathSound "weapons/plasmax"
trigger  Missile   (the >1300 branch)
range    1300..
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_PlasmaBallSPFB3", count:4, delayTics:2, fireSnd:"fire/fire3")
notes    MULTI only by the letter of rule 4 -- FB3 and FB4 differ only in a
         palette Translation. Geometrically this is a straight BURST of 4 at
         Speed 33, non-homing. Bounded by A_MonsterRefire(128,"See").
```

## Tier 8 — RS_GraySP2 ("Metal Spider?")

```
ATTACK   RS_GraySP2.Missile
file     zscript/monsters/spider/RS_Spider.zs:1398   (rockets at :1402)
shape    BURST
payload  RS_SpiderStoneRocket x3   [+ 2x RS_CHBSTarget beacon, no damage]
arc      --   (2 at random(-2,2) aim jitter, 1 at literal 0 -- rule 3)
timing   48-TIC TELEGRAPH (8 face + 11 beacon + 11 face + 11 beacon + 7), then 2,2,2
damage   DamageFunction (random(60,95))   -- the hardest single round on the ladder
type     Melee   (CH's choice, not a typo on our side; verbatim)
sound    --   (payload SeeSound "fire/fire3")
impact   6 A_SetScale beats (nogravity cleared -- the dud DROPS), A_Scream, then
         MISL BCD 5 Bright A_Explode(random(20,60),128) on THREE frames;
         DeathSound "fire/fire1"
trigger  Missile   (the >500 branch; A_JumpIfCloser(500,"Scrap") takes the close case)
range    500..
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_SpiderStoneRocket", count:3, delayTics:2, fireSnd:"fire/fire3")
notes    THE TELEGRAPH IS THE ATTACK'S CHARACTER. Two A_VileTarget("RS_CHBSTarget")
         calls plant a laser-designator beacon on the target that beeps
         "prox/beep" at ATTN_NONE (shotgunner FX:807) -- ZERO damage, pure warning,
         48 tics of it before the first rocket. Rocket is Speed 83, +NOGRAVITY
         +ROCKETTRAIL. Sprite: ours renders HGRN; CH writes SGRN, which ships
         NOWHERE in CH -- invisible there. Fixed in our tree 2026-08-06 on the
         owner's "nothing invisible" call (RS_SpiderFX.zs:598). RECORDED AS A
         KNOWN TREE/CH DIVERGENCE.
```

```
ATTACK   RS_GraySP2.Scrap
file     zscript/monsters/spider/RS_Spider.zs:1410
shape    SCATTER
payload  RS_FatsoSpikes2 x27
arc      26   (widest band; per-group rolls frandom(-9,9),(-5,5),(-13,13),(-9,9),(-5,5),(-11,11),(-5,5))
timing   1,1,1,1,1 / 0,0,0 / 1,1,1,1,1 / 0,0,0 / 1,1,1,1 / 0,0,0 / 1,1,1,1
         = 18 tics of fire; 10-tic windup, 6-tic tail
damage   DamageFunction (random(10,40)) each
type     Melee
sound    --   (payload SeeSound "monster/dknmsl")
impact   RIP1 ABCABCABCBA 12 A_Explode(random(1,4),8) on ELEVEN frames = a 132-tic
         lingering ground hazard per spike; DeathSound "weapons/boom1",
         BounceSound "fire/fire3"
trigger  Missile   (via A_JumpIfCloser(500,"Scrap"))
range    ..500
mirrored yes   (alternates spawnofs_xy -21 / +21 -- left and right shoulders)
inherit  --   (RS_FatsoSpikes2 is a bare Actor, imp FX:216)
profile  MakeBurst(proj:"RS_FatsoSpikes2", count:27, delayTics:1, arc:26)
notes    FIRED WITH A_SpawnItemEx, NOT A_CustomMissile -- the spikes are NOT aimed
         at the target. They inherit the monster's facing plus an explicit
         xvel random(12,33) / zvel random(1,3) / angle frandom(+-n), from
         (12, -21, 24) and (12, +21, 24). Payload is -NOGRAVITY with Gravity 0.1
         and Speed 5, so they arc, land, and burn for 132 tics. This is a
         short-range area-denial shotgun, not a volley.
         27 SPIKES FROM 7 WRITTEN LINES -- the frame-letter repeats are the count.
```

## Tier 9 — RS_AbyssSP2 ("Eye see")

Two-level router. `Missile:` at `:1555` does `A_JumpIfCloser(450,"Choice1",true)`
else `A_Jump(255,"Choice2")`; `Choice1` picks Breath/Missin 50-50, `Choice2`
picks Voidi/Missin 50-50. `Missin` (`:1570`) is an 8-tic windup that falls
through into `Miss2`. `Voidi` (`:1589`) and `Breath` (`:1649`) are likewise
windups falling into `Voidi2` / `Breath2`.

```
ATTACK   RS_AbyssSP2.Miss2
file     zscript/monsters/spider/RS_Spider.zs:1585
shape    BURST
payload  RS_AbyssSPBolt x1 per round, unbounded rounds
arc      --   (random(-1,1) aim jitter, rule 3)
timing   6-tic cycle (2 face / 3 fire / 1 refire); 8-tic Missin windup on entry
damage   DamageFunction (random(35,90))
type     Plasma
sound    --   (payload SeeSound "holy3/holy3")
impact   PLSE ABCDE 4 Bright, no A_Explode; DeathSound "holy2/holy2".
         IN-FLIGHT: lays RS_AbyssSPTrail every 3 tics on 8 frames -- and that trail
         is a +RIPPER PROJECTILE with DamageFunction (random(2,12)), Plasma
         (RS_SpiderFX.zs:221). The bolt leaves a damaging wake.
trigger  Missile   (both range bands reach it, 50% each)
range    --   (reachable at any range)
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_AbyssSPBolt", count:5, delayTics:6, fireSnd:"holy3/holy3")
notes    Speed 32, +MTHRUSPECIES +DONTHARMCLASS. Bounded by A_SpidRefire alone --
         no jump bail on this one. The trail is the reason this attack is
         disproportionately dangerous in corridors.
```

```
ATTACK   RS_AbyssSP2.Voidi2
file     zscript/monsters/spider/RS_Spider.zs:1605
shape    VILE
payload  A_VileAttack + a RS_PsychicAbyssSP ground bomb. 7 damage-0 rail beams telegraph it.
arc      --
timing   ~107-tic cycle, LOOPING. 7 rails, then 2x A_VileTarget("RS_PsychicAra"),
         then A_VileTarget("RS_PsychicAbyssSP"), then the 8-tic A_VileAttack.
damage   A_VileAttack initialdmg random(60,120); blastdmg 0, blastradius 0, thrustfac 0.
         Plus RS_PsychicAbyssSP: DamageFunction (random(2,15)) direct,
         A_Explode(random(10,32),64,0) on death.
type     getoutofmyheadcharles (both)
sound    A_VileAttack snd "electricplasma/hit"; A_PlaySound("Vile/Active",7,2,false,ATTN_NONE)
impact   RS_PsychicAbyssSP (RS_SpiderFX.zs:191) is planted AT THE TARGET'S FEET by
         A_VileTarget and detonates: BBOM C 2 Bright A_Explode(random(10,32),64,0).
         SeeSound "holy3/holy3", DeathSound "holy2/holy2". Rails' own puff
         (RS_PsychicAra) and trail (RS_PsychicPulse) deal ZERO.
trigger  Missile   (the >450 branch, then A_Jump(255,"Voidi","Missin"))
range    450..
mirrored no
inherit  --
profile  MakeHitscan(fireSnd:"electricplasma/hit", profName:"abyss-psychic-burn")
notes    THE YELLOW SPIDER'S PSYCHE2 ESCALATED, AND IT LOOPS. Same 7-rail +
         A_VileAttack chain, but random(60,120) instead of random(40,80), an extra
         RS_PsychicAbyssSP bomb, and `Goto Voidi2` -- so it re-runs the WHOLE
         107-tic chain with only A_Jump(16,"See") (~6.25%) and A_SpidRefire to
         stop it. Eight A_CheckSight("See") calls inside the chain are the real
         escape hatch: break line of sight and it drops out mid-sequence.
```

```
ATTACK   RS_AbyssSP2.Breath2
file     zscript/monsters/spider/RS_Spider.zs:1669
shape    SCATTER
payload  RS_AbyssSPBreath x7 per round, unbounded rounds
arc      44   (2 at random(-12,12), then 5 at random(-22,22))
timing   1 tic each, 7 tics of fire; 2-tic face + 1-tic refire = 10-tic cycle.
         21-tic Breath windup on entry.
damage   DamageFunction (random(5,12)) direct
type     Ice
sound    --   (payload SeeSound "ice/Breath")
impact   A GAS CLOUD, NOT AN IMPACT. +THRUACTORS, so it passes through everything.
         Spawn state runs A_Explode(random(5,15),30) on FOUR frames (PUFI AB, PUFI CD)
         while travelling, then Death runs it on FOUR MORE (PUFI EF 4, PUFI GH 5),
         growing scale 0.75 -> 0.9 -> 1.1 -> 1.25. Eight blasts per puff.
         Ends with 6x RS_SplashAbyss2. DeathSound "Ice/Splode".
trigger  Missile   (the <=450 branch, then A_Jump(255,"Breath","Missin"))
range    ..450
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_AbyssSPBreath", count:7, delayTics:1, arc:44, fireSnd:"ice/Breath")
notes    MULTI-FRAME A_EXPLODE, DELIBERATE -- this is a lingering breath weapon and
         the eight stacked blasts ARE the damage; the direct random(5,12) is
         almost incidental. Speed 24. Seven puffs x eight blasts = 56 A_Explode
         events per round, each random(5,15) at radius 30.
         Exit: A_Jump(32,"Warp") ~12.5% (teleport-wander), then A_SpidRefire.
```

## Tier 10 — RS_BlackSP2 ("Macross Missile Spam")

`Missile:` at `:1786` is `A_Jump(256,"Miss1","Miss2","Miss3","Miss4")` — even
4-way. **`Pain:` at `:1850` also does `A_Jump(128,"Miss4","Miss3")`** — a 50 %
chance that being hurt fires Miss3 or Miss4. Both rows carry that second trigger.

```
ATTACK   RS_BlackSP2.Miss1
file     zscript/monsters/spider/RS_Spider.zs:1792
shape    BURST
payload  RS_SpRocket3 x2 per round, unbounded rounds
arc      --   (random(-2,2) then random(-6,6) -- aim jitter, rule 3)
timing   8-tic cycle (2 / 2 face / 2 / 2 refire); 20-tic windup on entry only
damage   DamageFunction (random(10,45))
type     Fire
sound    --   (payload SeeSound "fire/fire3")
impact   MISL BCD 8 Bright A_Explode(random(5,20),128) on THREE frames;
         DeathSound "fire/fire1"
trigger  Missile
range    --
mirrored yes   (spawnofs_xy -12 / +12, opposite shoulders)
inherit  --
profile  MakeBurst(proj:"RS_SpRocket3", count:4, delayTics:4, fireSnd:"fire/fire3")
notes    Speed 37, +ROCKETTRAIL. `A_Jump(12,"Miss3")` on the tail (~4.7%) lets the
         cheap attack ESCALATE INTO THE 20-MISSILE SWARM. Bounded by
         A_MonsterRefire(128,"See"). Same SGRN/HGRN sprite divergence as the gray
         spider's rocket (RS_SpiderFX.zs:1655).
```

```
ATTACK   RS_BlackSP2.Miss2
file     zscript/monsters/spider/RS_Spider.zs:1801
shape    BURST
payload  RS_SpRocket4 x6
arc      --   (rolls random(-6,6), random(-3,9), random(-9,3), random(-2,2) around 0)
timing   11-tic beats (2 face + 9 fire) x4, then 0 + 9 for the last pair.
         6-tic entry. ~53 tics total.
damage   DamageFunction (random(10,50))
type     Fire
sound    --   (payload SeeSound "weapons/hominglaunch")
impact   MISL B 2 Bright A_Explode(random(50,90),158); DeathSound "weapons/homingexplode"
trigger  Missile
range    --
mirrored yes   (spawnofs_xy -34/-64/+34/+64/-14/+14, launch heights 80/60/80/60/90/90)
inherit  --
profile  MakeBurst(proj:"RS_SpRocket4", count:6, delayTics:11, fireSnd:"weapons/hominglaunch")
notes    THE MACROSS LAUNCH. Payload Speed is **1** -- the rocket HANGS for 12 tics
         (MSLH A 12) and then A_ScaleVelocity(random(12,83)) throws it forward at a
         randomised speed. That pause is the whole visual identity of this monster
         and any rebuild that skips it loses the attack. All six fly nearly
         parallel; the spread is entirely lateral launch offsets (rule 5), up to
         +-64 units wide.
```

```
ATTACK   RS_BlackSP2.Miss3
file     zscript/monsters/spider/RS_Spider.zs:1818
shape    MULTI
payload  RS_SPMM1 x4 + RS_SPMM2 x5 + RS_SPMM3 x5 + RS_SPMM4 x4 + RS_SPMM5 x2  = 20
arc      122 max   (per-shot rolls from random(-9,9) up to random(-61,61); two are
                    ASYMMETRIC: random(-61,6) and random(-9,41))
timing   1 tic each, 20 consecutive tics. 18-tic windup (10 face + 8 leap).
damage   SPMM1 random(20,65) / SPMM2 random(20,65) / SPMM3 random(20,85)
         / SPMM4 random(30,65) / SPMM5 random(30,65)
type     SPMM1 Fire, SPMM2 Fire, SPMM3 Plasma, SPMM4 "Meelee" (CH's own typo, last
         DamageType wins -- kept verbatim), SPMM5 Fire
sound    --   (all five SeeSound "monster/brufir")
impact   all five: BAL3 C/D/E 6 Bright with A_Explode on the D frame --
         SPMM1/SPMM2 random(20,75) at 128, SPMM3/SPMM4/SPMM5 random(30,75) at 128.
         DeathSound "weapons/hellex". Decal "Scorch". All carry DontHurtShooter true.
trigger  Missile, and Pain (A_Jump(128,"Miss4","Miss3") at :1850)
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_SPMM1", count:20, arc:122, fireSnd:"monster/brufir")
         // five classes -- the rebuild picks one, or five profiles fired together
notes    THE SIGNATURE ATTACK OF THE BLACK BOSS. Opens with ThrustThingZ(0,100,0,0)
         -- IT LEAPS -- and sets FLOAT/NOGRAVITY/NOPAIN for the duration, clearing
         all three at the end (:1838-1840). The five payloads differ in a way that
         matters:
           SPMM1 Speed 26, A_SeekerMissile(3,8),  A_Weave(1,1,1,1)
           SPMM2 Speed 22, A_SeekerMissile(7,14), A_Weave(2,1,3,1)   <- hardest tracker
           SPMM3 Speed 24, NO SEEKER at all                          <- the only dumb one
           SPMM4 Speed 20, A_SeekerMissile(1,4),  A_Weave(3,6,7,3)
           SPMM5 Speed 28, A_SeekerMissile(1,4),  A_Weave(5,4,4,8)
         Each also lays its own coloured trail (RS_SPMMTrail1..5, palette-only
         variants of the same PLSE burst).
```

```
ATTACK   RS_BlackSP2.Miss4
file     zscript/monsters/spider/RS_Spider.zs:1844
shape    SINGLE
payload  RS_BBSP1 x1
arc      128   (angle random(-64,64) -- a wildly unaimed single, NOT jitter)
timing   one tic; 9-tic face windup, 8-tic frame
damage   DamageFunction (random(20,75))
type     Fire
sound    --   (payload SeeSound "fire/fire3")
impact   IN-FLIGHT: A_Explode(random(10,30),128) every 6-tic Spawn loop while it
         bounces. On death: MISL B 8 A_Explode(random(20,50),128) + ~14
         RS_BaronStar3 seekers scattered to +-280. DeathSound "fire/fire1",
         BounceSound "fire/fire2".
trigger  Missile, and Pain (A_Jump(128,"Miss4","Miss3") at :1850)
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_BBSP1", fireSnd:"fire/fire3", spawnHeight:46.0)
notes    A BOUNCING AREA-DENIAL GRENADE. -NOGRAVITY, Gravity 0.29, BounceType Doom,
         BounceCount 19, BounceFactor 1.15, WallBounceFactor 0.95 -- it keeps
         bouncing for a long time and A_Explodes on a loop the whole way. It also
         has a 12/256 chance per loop to ThrustThing itself in a random direction
         (RS_SpiderFX.zs:1274-1279), so its path is genuinely unpredictable.
         Launch args are all rolled: height random(12,80), lateral random(-60,60),
         angle random(-64,64).
```

## Tier 10 EX — RS_BlackSPEX ("Macross Missile Spam EX")

`Missile:` at `:1953` gates on health: **`A_JumpIfHealthLower(7000,"ChoicesMore")`**
(of 12000 max) picks `Miss5..Miss9`; above 7000 it is `A_Jump(256,"Miss1"..
"Miss4")`. `Pain:` at `:2144` again does `A_Jump(128,"Miss4","Miss3")`.
`Miss33:` at `:2042` is a one-line trampoline into `Miss3+5`.

```
ATTACK   RS_BlackSPEX.Miss1
file     zscript/monsters/spider/RS_Spider.zs:2047
shape    BURST
payload  RS_ExSpideLaser1 x2 per round, unbounded rounds
arc      --   (random(-2,2) both -- aim jitter, rule 3)
timing   8-tic cycle (2 / 2 face / 2 / 2 refire); 20-tic entry windup
damage   DamageFunction (random(10,50))
type     Plasma
sound    --   (payload SeeSound "weapons/plasmaf")
impact   RCHB CD 3, then RCHB E 3 Bright A_Explode(random(10,40),64,0);
         DeathSound "weapons/plasmax", BounceSound "" (deliberately silent)
trigger  Missile   (health > 7000)
range    --
mirrored yes   (spawnofs_xy -12 / +12)
inherit  --
profile  MakeBurst(proj:"RS_ExSpideLaser1", count:4, delayTics:4, fireSnd:"weapons/plasmaf")
notes    Structurally identical to RS_BlackSP2.Miss1 but the payload BOUNCES:
         +BOUNCEONWALLS, BounceType Doom, BounceCount 2, Speed 38. Two wall
         bounces means it comes round corners. Lays RS_SpideEXTrail.
         Same A_Jump(12,"Miss3") escalation to the 34-missile swarm.
```

```
ATTACK   RS_BlackSPEX.Miss2
file     zscript/monsters/spider/RS_Spider.zs:2069
shape    MULTI
payload  RS_SpRocket4 x11 + RS_SpRocket4EX x6  = 17
arc      --   (rolls random(-6,6), random(-3,9), random(-9,3), random(-2,2) around 0)
timing   three waves. Wave 1: 5 rockets at 2 tics apart. 4-tic face.
         Wave 2: 3 rockets 2 tics apart. 4-tic face. Wave 3: 3 rockets.
         12-tic face, then 6 EX rockets, 5 of them on one tic. ~62 tics.
damage   SpRocket4 random(10,50); SpRocket4EX random(20,80)
type     Fire (both)
sound    --   (both SeeSound "weapons/hominglaunch")
impact   SpRocket4:   A_Explode(random(50,90),158)
         SpRocket4EX: A_SetScale(1.75) + A_Explode(random(50,120),232)
         both DeathSound "weapons/homingexplode"
trigger  Missile   (health > 7000)
range    --
mirrored yes   (offsets -34,-14,0,+14,+34 then -58,-78,-86 then +58,+78,+86,
                then EX at -24,+24,-24,+24,-20,+20)
inherit  --
profile  MakeBurst(proj:"RS_SpRocket4", count:11, delayTics:2, fireSnd:"weapons/hominglaunch")
         + MakeVolley(proj:"RS_SpRocket4EX", count:6)
notes    THE 232-RADIUS BLAST ON SpRocket4EX IS THE LARGEST NON-SCRIPTED EXPLOSION
         IN THE FAMILY. Both rockets Speed 1 into A_ScaleVelocity (random(12,83)
         plain, random(20,83) EX); the EX one additionally weaves with
         A_BishopMissileWeave. The 11 plain rockets sweep a fan of LAUNCH POSITIONS
         from -86 to +86 units while all flying nearly straight (rule 5).
```

```
ATTACK   RS_BlackSPEX.Miss3
file     zscript/monsters/spider/RS_Spider.zs:2096
shape    MULTI
payload  RS_SPMM1 x6 + RS_SPMM2 x8 + RS_SPMM3 x8 + RS_SPMM4 x8 + RS_SPMM5 x4  = 34
arc      122 max   (same per-shot roll table as RS_BlackSP2.Miss3, run 1.7x longer)
timing   1,1,1,0 repeating -- 34 rounds in ~26 tics. 18-tic windup (10 face + 8 leap).
damage   as RS_BlackSP2.Miss3 (SPMM1/2 random(20,65), SPMM3 random(20,85),
         SPMM4/5 random(30,65))
type     Fire / Fire / Plasma / "Meelee" / Fire
sound    --   (all SeeSound "monster/brufir")
impact   as RS_BlackSP2.Miss3 -- A_Explode(random(20..30,75),128) on the BAL3 D frame
trigger  Missile (health > 7000), Pain (A_Jump(128,"Miss4","Miss3")),
         and Miss5's A_Jump(64,"Miss33") -> Miss3+5
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_SPMM2", count:34, arc:122, fireSnd:"monster/brufir")
notes    THE BLACK BOSS'S SWARM, 34 ROUNDS INSTEAD OF 20, AND 30% FASTER --
         the EX version puts every fourth missile on a 0-TIC frame, so pairs
         arrive together. Same leap and same FLOAT/NOGRAVITY/NOPAIN window.
         Reachable three ways, which is why it is the attack players remember.
         Miss33 (:2042) enters at Miss3+5, i.e. SKIPPING THE LEAP -- a mid-air
         re-entry from Miss5.
```

```
ATTACK   RS_BlackSPEX.Miss4
file     zscript/monsters/spider/RS_Spider.zs:2136
shape    FAN
payload  RS_YellowBombEXSpidie x3
arc      36   (three deliberate bands: random(-18,-4), random(0,0), random(4,18) -- rule 2)
timing   8,8,8 tics; 18-tic face windup
damage   DamageFunction (random(20,80)) direct -- but see the impact row, it is dwarfed
type     Fire
sound    --   (payload SeeSound "spit/spit")
impact   AN EIGHT-STAGE ESCALATING DETONATION -- see the RS_YellowBombEXSpidie.Death
         row. DeathSound "spit/spit2".
trigger  Missile (health > 7000), and Pain (A_Jump(128,"Miss4","Miss3"))
range    --
mirrored no
inherit  --
profile  MakeVolley(proj:"RS_YellowBombEXSpidie", count:3, arc:36, fireSnd:"spit/spit")
notes    Launch args rolled: height random(34,50), lateral random(-40,40).
         Speed 38, +RANDOMIZE +DONTHARMCLASS, A_CStaffMissileSlither in flight.
```

```
ATTACK   RS_YellowBombEXSpidie.Death   (SECONDARY -- the single largest payload here)
file     zscript/monsters/spider/RS_SpiderFX.zs:1123
shape    UNCLASSIFIED
payload  self-detonation in 8 escalating stages + RS_BlackSpideEXScrap x24
arc      360   (scrap in three 120-degree bands, twice: random(0,120)/(120,240)/(240,360))
timing   2 tics per stage, ~30 tics total, then a 20-tic A_FadeOut tail
damage   A_Explode(random(10,20),32) -> (random(10,30),64) -> (random(20,60),74)
         -> (random(20,80),128) -> (random(30,90),176) -> (random(30,90),256)
         -> (random(30,90),256) -> (random(30,90),312)
         scrap: DamageFunction (random(1,8)) each
type     Fire
sound    A_PlaySound("spell/Impact1",0) at stage 0, A_PlaySound("Bomb/boom",0) at the 176 stage
impact   scale ramps 0.5 -> 0.75 -> 1.25 -> 2.0 -> 2.5 -> 3.0 -> 3.5 -> 4.0 over the
         eight stages, so the fireball visibly grows with each blast
trigger  Death   (of the bomb)
range    --
mirrored no
inherit  --
profile  MakeRadial(radius:312, damage:60, fireSnd:"Bomb/boom")   // one stage only; see notes
notes    SHAPE IS UNCLASSIFIED AND THAT IS DELIBERATE -- the closed set has no word
         for "one detonation that grows through eight radii". Do not coin one.
         The profile above collapses it to the final stage; a faithful rebuild
         needs eight timed MakeRadial calls, or a new mode.
         The 24 RS_BlackSpideEXScrap are +BOUNCEONFLOORS, BounceType Hexen,
         BounceCount 5, BounceFactor 0.75 -- bouncing embers that keep burning
         after the blast (RS_SpiderFX.zs:1150).
```

```
ATTACK   RS_BlackSPEX.Miss5
file     zscript/monsters/spider/RS_Spider.zs:1968
shape    SCATTER
payload  RS_ExSpideLaser1 x34
arc      widens 4 -> 34   (rolls: +-2,+-2,+-5,+-5,+-8,+-8,+-5,+-5,+-3,+-3, face,
                           then +-3 x6, +-6,+-6, +-9,+-9, +-13, +-17,+-17, then
                           the +-9/+-13/+-17/+-17 group repeated four times)
timing   1 tic each, several on 0-tic frames -- 34 rounds in ~28 tics.
         18-tic windup (10 face + 8 leap) + a 2-tic face.
damage   DamageFunction (random(10,50)) each
type     Plasma
sound    --   (SeeSound "weapons/plasmaf")
impact   RCHB E 3 Bright A_Explode(random(10,40),64,0); DeathSound "weapons/plasmax"
trigger  Missile   (health < 7000 only)
range    --
mirrored yes   (strictly alternating spawnofs_xy -12 / +12 -- left, right, left, right)
inherit  --
profile  MakeBurst(proj:"RS_ExSpideLaser1", count:34, delayTics:1, arc:34, fireSnd:"weapons/plasmaf")
notes    THE ENRAGE ATTACK. Leaps (ThrustThingZ(0,100,0,0)), goes FLOAT/NOGRAVITY/
         NOPAIN, and empties 34 bouncing plasma bolts in under a second, with the
         cone OPENING as it goes -- tight at the start, +-17 by the end. Ends on
         `A_Jump(64,"Miss33")`: A 25% CHANCE TO CHAIN STRAIGHT INTO THE 34-MISSILE
         SWARM, mid-air, without landing. That chain is the hardest moment in the
         family. Flags cleared at :2006-2008 only on the non-chaining path.
```

```
ATTACK   RS_BlackSPEX.Miss6
file     zscript/monsters/spider/RS_Spider.zs:2056
shape    BURST
payload  RS_SpRocket4EX x6 per round, unbounded rounds
arc      --   (random(-2,2) on all six -- aim jitter, rule 3)
timing   20-tic cycle: 3 rockets on the left beat (0,0,2), 12-tic swing,
         3 on the right beat (0,0,2), 2-tic refire. 20-tic entry windup.
damage   DamageFunction (random(20,80))
type     Fire
sound    --   (SeeSound "weapons/hominglaunch")
impact   A_SetScale(1.75) + A_Explode(random(50,120),232); DeathSound "weapons/homingexplode"
trigger  Missile   (health < 7000 only)
range    --
mirrored yes   (left triple at offsets -14,-14,-10; right triple at +14,+14,+10)
inherit  --
profile  MakeBurst(proj:"RS_SpRocket4EX", count:6, delayTics:10, fireSnd:"weapons/hominglaunch")
notes    A LEFT-THEN-RIGHT TRIPLE, ON A LOOP. Bounded by A_MonsterRefire(128,"See").
         Six 232-radius blasts per cycle makes this the highest sustained area
         damage in the family. Payload Speed 1 -> A_ScaleVelocity(random(20,83)),
         then A_BishopMissileWeave.
```

```
ATTACK   RS_BlackSPEX.Miss7
file     zscript/monsters/spider/RS_Spider.zs:2030
shape    SINGLE
payload  RS_BlackSpideSpiralShot x1
arc      --   (literal angle 0)
timing   one shot; 16-tic windup, 12-tic tail
damage   DamageFunction (random(20,80)) direct
type     Plasma
sound    --   (payload SeeSound "Spell/SpellCast1")
impact   IN-FLIGHT: A_Explode(random(10,50),64,0) THREE TIMES per ~40-tic Fly loop,
         while A_SetRoll steps the sprite 70 -> 140 -> 210 -> 285 -> 360 and
         A_SetScale pulses 0.75/0.5/0.75. On death: GRFZ K 3 A_Explode(random(33,99),
         128,0) + 17x RS_EXPLOSIONSCGuyEXDelayd + red particles.
         DeathSound "Fire/Fire4".
trigger  Missile   (health < 7000 only)
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_BlackSpideSpiralShot", fireSnd:"Spell/SpellCast1", spawnHeight:32.0)
notes    A SPINNING DRILL THAT PASSES THROUGH ACTORS. +THRUACTORS +ROLLSPRITE
         +DONTHARMCLASS at Speed 15 -- it cannot be blocked by bodies and cannot
         be stopped short, so it grinds through a whole corridor at
         random(10,50) per pulse until it hits geometry. One shot, and it is the
         reason this boss beats crowds.
```

```
ATTACK   RS_BlackSPEX.Miss8
file     zscript/monsters/spider/RS_Spider.zs:2014
shape    BURST
payload  RS_YellowBombEXSpidie x6   [+ 6 damage-0 A_CustomRailgun tracers]
arc      --   (random(-3,3) -- aim jitter, rule 3)
timing   six blue tracer rails at 6 tics apart (36 tics of telegraph, each with an
         A_FaceTarget between), then six bombs at 10 tics apart (60 tics)
damage   DamageFunction (random(20,80)) direct, then the 8-stage detonation
type     Fire
sound    --   (payload SeeSound "spit/spit"; the rails are RGF_SILENT)
impact   see the RS_YellowBombEXSpidie.Death row -- eight stages to radius 312, plus
         24 bouncing embers, PER BOMB. Six bombs.
trigger  Missile   (health < 7000 only)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_YellowBombEXSpidie", count:6, delayTics:10, fireSnd:"spit/spit")
notes    THE RAILGUNS DO NOTHING -- A_CustomRailgun(0,0,"none","Blue",
         RGF_NOPIERCING|RGF_SILENT) with damage 0, no pufftype and no spawnclass.
         Six silent blue tracer lines, purely a "get out of the open" warning.
         The state OPENS with `A_Jump(128,"Miss1","Miss2","Miss3","Miss4")` -- a
         50% chance it never runs at all and diverts into the above-7000 set,
         which is why this attack is rarely seen. Launch lateral random(-10,10),
         height random(34,50).
```

```
ATTACK   RS_BlackSPEX.Miss9
file     zscript/monsters/spider/RS_Spider.zs:2036
shape    BURST
payload  RS_SpRocket4EX x3
arc      --   (random(-2,2) on all three -- aim jitter, rule 3)
timing   0,0,8 tics -- two on one tic, third 8 tics later. 12-tic windup, 6-tic tail.
damage   DamageFunction (random(20,80))
type     Fire
sound    --   (SeeSound "weapons/hominglaunch")
impact   A_SetScale(1.75) + A_Explode(random(50,120),232); DeathSound "weapons/homingexplode"
trigger  Missile   (health < 7000 only)
range    --
mirrored yes   (offsets +15 / -15 on the pair, 0 on the third)
inherit  --
profile  MakeBurst(proj:"RS_SpRocket4EX", count:3, delayTics:4, fireSnd:"weapons/hominglaunch")
notes    The cheapest of the five enrage attacks -- a three-rocket poke with no
         refire and no chain. Does not loop; `Goto See`.
```

## Tier 11 — RS_WhiteSP11 ("White Spider")

`Missile:` at `:2227` gates on health: **`A_JumpIfHealthLower(4000,"Set2")`** (of
7000). Above 4000 the pool is `Atk1, Atk2, Web, Atk5, Atk6, Atk7`; below, `Set2`
adds `Atk3` and `Atk8`. **`Atk4` is unreachable from the router** — it is entered
only from `Atk2`'s `A_JumpIfCloser(400,"Atk4",true)`. `SpawnSpiders` is likewise
never in the router; six other attacks chain into it with `A_Jump(64,...)`.

```
ATTACK   RS_WhiteSP11.Web
file     zscript/monsters/spider/RS_Spider.zs:2239
shape    BURST
payload  RS_WHITESPIDERWEBSHOTNOTLEWD x2
arc      36   (shot 1 random(-1,1); shot 2 randompick(-18,-12,12,18) -- a deliberate flank)
timing   17 tics apart (5 fire + 12 face); 12-tic entry, 24-tic tail
damage   DamageFunction (random(1,5))   -- almost none; this is a control attack
type     Melee
sound    --   (payload SeeSound "phantom/bomb")
impact   A SLOW FIELD -- see the RS_WHITESPIDERWEBSHOTNOTLEWD.Death row.
         DeathSound "phantom/explode".
trigger  Missile   (in both health pools)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_WHITESPIDERWEBSHOTNOTLEWD", count:2, delayTics:17, arc:36)
notes    THE DAMAGE NUMBER IS A DECOY. random(1,5) is nothing; the attack exists to
         plant the web field. Payload Speed 35, lays RS_WhiteSPWebTrail the whole
         way. Shot 2's randompick means it deliberately lands OFF to one side, so
         the two webs bracket the player rather than stacking.
```

```
ATTACK   RS_WHITESPIDERWEBSHOTNOTLEWD.Death   (SECONDARY)
file     zscript/monsters/spider/RS_SpiderFX.zs:1746
shape    SCATTER
payload  RS_WhiteSPWebTrail x27 + RS_WhiteSPWebWeb x7
arc      --   (placed by offset, not angle: random(+-32) trails, random(+-26) and
               random(+-48) web patches)
timing   one tic -- all 34 on 0-tic frames, then PLSE BCDE 1
damage   0   (NOTHING in this payload deals damage)
type     --
sound    --
impact   A_RadiusGive("RS_WHITESPSlowdown",64,RGF_PLAYERS|RGF_CUBE,1) fires ONCE at
         detonation, then EACH of the 7 RS_WhiteSPWebWeb patches re-applies it FOUR
         MORE TIMES over 48 tics (RS_SpiderFX.zs:1786-1802). RS_WHITESPSlowdown is
         a PowerSpeed with Speed 0.2 and Powerup.Duration 15 (RS_SpiderFX.zs:1757).
trigger  Death   (of the web shot)
range    --
mirrored no
inherit  RS_WHITESPSlowdown : PowerSpeed   (the only inheritance in the family that changes behaviour)
profile  MakeRadial(radius:64, damage:0)   // the slow itself has no factory yet
notes    THE ONLY NON-DAMAGE ATTACK IN THE FAMILY, AND THE MOST DANGEROUS THING THE
         WHITE SPIDER DOES. A player standing in the field is held at 20% speed for
         as long as any patch survives -- 8 web patches x 4 reapplications x 15 tics.
         RS_WhiteSPWebWeb is +NOCLIP +DONTTHRUST +DONTBLAST, so it cannot be pushed
         off or blown up. NO EXISTING FACTORY EXPRESSES THIS; a rebuild needs a
         "field that applies a powerup" mode.
```

```
ATTACK   RS_WhiteSP11.SpawnSpiders
file     zscript/monsters/spider/RS_Spider.zs:2249
shape    FAN
payload  RS_MiniSP1 x3   (LIVE MONSTERS, launched as missiles)
arc      90   (A_PainAttack straight ahead + A_DualPainAttack at +-45)
timing   8 tics then 4 tics; 12-tic face windup
damage   --   (the minion carries its own melee, see RS_MiniSP1.Melee)
type     --
sound    --
impact   the minions land and chase; RS_MiniSP1 is Health 15, Speed 28, Scale 0.20
trigger  Missile   (NEVER from the router -- reached only via A_Jump(64,"SpawnSpiders")
                    from Atk1, Atk2, Atk3, Atk4, Atk5 and Atk8)
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_MiniSP1", count:3, cap:12, tierOffset:-2)
notes    UNREACHABLE FROM `Missile:` -- this attack has no entry of its own. Six
         other attacks each roll a 25% chance to chain into it, which is what makes
         the fight fill with minions over time rather than in a burst.
         A_PainAttack/A_DualPainAttack launch the minion as a missile (lost-soul
         mechanics), so the three arrive airborne at +-45 degrees.
```

```
ATTACK   RS_WhiteSP11.Atk1
file     zscript/monsters/spider/RS_Spider.zs:2261
shape    FAN
payload  RS_WhiteSpiderPBolt x6   (two volleys of 3)
arc      24   (three bands, rule 2: random(-1,1), random(3,12), random(-12,-3))
timing   5,5,5 tics -- 20-tic face -- 5,5,5 tics. ~20-tic entry (leap+lunge), 24-tic tail
damage   DamageFunction (random(35,90))
type     Plasma
sound    --   (payload SeeSound "holy3/holy3")
impact   PLSE ABCDE 4 Bright, no A_Explode; DeathSound "holy2/holy2".
         Lays RS_WhiteSpidBoltTrail (BLST fade, no damage).
trigger  Missile   (in both health pools)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_WhiteSpiderPBolt", count:6, delayTics:5, arc:24, fireSnd:"holy3/holy3")
notes    OPENS WITH A LEAP AND A LUNGE: ThrustThingZ(0,40,0,0) then
         ThrustThing(int(angle),32,0,0) -- it hops AND charges forward while
         FLOAT/NOGRAVITY/NOPAIN are set (:2254-2256), clearing them at :2268-2270.
         Payload Speed 8 then A_ScaleVelocity(random(2,4)) on the second frame --
         EFFECTIVE SPEED 16..32, ROLLED PER BOLT, so the six arrive out of order.
         Ends A_Jump(64,"Web","SpawnSpiders") -- 25% to chain.
```

```
ATTACK   RS_WhiteSP11.Atk2
file     zscript/monsters/spider/RS_Spider.zs:2277
shape    HITSCAN
payload  A_CustomRailgun -- 3 damage-0 red-dot rails, then ONE live rail
arc      --   (aim = 1, so the live rail is target-locked)
timing   3 sight rails at 6 tics with 12-tic pauses (~66 tics of telegraph), then
         the 12-tic live rail, then a 32-tic recovery
damage   random(40,90) on the live rail itself, PLUS the puff and spawnclass below
type     Plasma (via the puff and spawnclass)
sound    A_PlaySound("SHARPST1",7,2,false,ATTN_NONE) between sight rails;
         A_PlaySound("kawai/sight",0) on recovery. The rails are RGF_SILENT.
impact   pufftype RS_WhiteFatRB (fatso FX:1468): DamageFunction (random(30,95)) Plasma,
         Death runs A_Scream + BFE1 C 8 A_Explode(random(50,125),252) + Radius_Quake(15,15,0,40,0),
         DeathSound "NETHERDE".
         spawnclass RS_WhiteFatRB2 (fatso FX:1564): DamageFunction (random(30,50)) Plasma,
         laid ALONG THE BEAM at sparsity 0.4, each running A_Explode(random(15,30),128)
         TWICE. DeathSound "Crack/death".
         The three sight rails use RS_RedDotSGPuff (shotgunner FX:429), +PAINLESS
         +NOBLOOD, damage 0.
trigger  Missile   (in both health pools)
range    400..   (A_JumpIfCloser(400,"Atk4",true) diverts the close case)
mirrored no
inherit  RS_RedDotSGPuff : BulletPuff   (impact frames and +ALWAYSPUFF come from the parent)
profile  MakeHitscan(fireSnd:"SHARPST1", spreadScale:0.0, impactPuff:"RS_WhiteFatRB")
notes    THE SNIPER. Three red laser-sight passes (damage 0, duration 15,
         sparsity 0.5, driftspeed 0.5, spawnofs_z -12 -- a dot that hovers below
         the crosshair) telegraph it for over a second, then one shot lands
         random(40,90) rail damage AND a 252-radius, screen-shaking blast AND a
         line of exploding orbs down the entire beam. Fired at aim=1 so it does
         not miss. This is the single highest-damage event in the family.
         Ends A_Jump(64,"SpawnSpiders") -- 25% to chain.
```

```
ATTACK   RS_WhiteSP11.Atk3
file     zscript/monsters/spider/RS_Spider.zs:2368
shape    UNCLASSIFIED
payload  RS_WhiteSpidegg x3   (LIVE MONSTERS, launched as missiles)
arc      --   (A_PainAttack, straight ahead each time)
timing   5, then 8+1, tics of laying -- separated by ~19-tic A_Wander runs
damage   --   (the eggs carry their own; see the RS_WhiteSpidegg rows)
type     --
sound    --
impact   each egg is Health 50, +FLOAT +FLOATBOB +NOGRAVITY +NOTARGET, Scale 2,
         DeathSound "weapons/rocklx"
trigger  Missile   (health < 4000 ONLY)
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_WhiteSpidegg", count:3, cap:6, tierOffset:-2)
notes    SHAPE UNCLASSIFIED -- the vocabulary has no word for "run away while
         planting mines," and the running is not incidental: A_SetSpeed(45) (up
         from 28), NOPAIN on, then 13 A_Wander frames between each egg, restored
         at :2376-2377. The eggs are laid where it has fled to, not at the player.
         Ends A_Jump(64,"SpawnSpiders").
```

```
ATTACK   RS_WhiteSP11.Atk4
file     zscript/monsters/spider/RS_Spider.zs:2348
shape    MULTI
payload  RS_SlimeBall1 x2 + RS_SlimeBall2 x2 + RS_SlimeBall3 x2 + RS_SlimeBall4 x2 + RS_SlimeBall5 x2  = 10
arc      24   (5 at random(-10,10); then random(-12,-10), random(-10,-8),
               random(-10,10), random(8,10), random(10,12))
timing   ONE TIC -- all ten on 0-tic WORM F frames. 29-tic windup, 24-tic tail.
damage   Damage 4 each   (bare int: engine rolls 4..32)  PLUS PoisonDamage 15
type     --  direct;  PoisonDamageType "Poison" for the DoT
sound    --   (inherits DoomImpBall's SeeSound)
impact   BOGY DEF 4 Bright + A_NoGravity; DeathSound "slimeball/splat";
         Decal "PlasmaScorchLower"
trigger  Missile   (ONLY via Atk2's A_JumpIfCloser(400,"Atk4",true))
range    ..400
mirrored no
inherit  RS_SlimeBall1 : DoomImpBall  (SeeSound, +RANDOMIZE and the Spawn/Death
         frame structure come from the vanilla parent -- reading the child alone
         reports no sound);  RS_SlimeBall2..5 : RS_SlimeBall1 (Speed only: 16/18/20/22)
profile  MakeVolley(proj:"RS_SlimeBall1", count:10, arc:24, pitchJitter:30)
notes    THE ONLY POISON DAMAGE IN THE FAMILY. All ten are fired with
         flags = 2 (CMF_AIMDIRECTION) and a PITCH roll of random(10,20) on the
         first five and random(13,30) on the second five -- they are lobbed, and
         they are -NOGRAVITY OFF, so they arc and fall. Five distinct classes at
         five distinct speeds (14/16/18/20/22) means the ten land in a spreading
         column over time from a single tic of fire. This is the close-range
         panic button, reachable only by walking into the sniper.
         Ends A_Jump(64,"Web","SpawnSpiders").
```

```
ATTACK   RS_WhiteSP11.Atk5
file     zscript/monsters/spider/RS_Spider.zs:2293
shape    SCATTER
payload  RS_WhiteSpiderPBolt x10   (4, then 6)
arc      widens 2 -> 14, then resets   (random(-1,1),(-3,3),(-5,5),(-7,7) --
         then (-1,1),(-2,2),(-3,3),(-1,1),(-2,2),(-3,3))
timing   5 tics each; a 20-tic face between the two runs. 16-tic entry.
damage   DamageFunction (random(35,90))
type     Plasma
sound    --   (SeeSound "holy3/holy3")
impact   PLSE ABCDE 4 Bright, no A_Explode; DeathSound "holy2/holy2"
trigger  Missile   (in both health pools)
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_WhiteSpiderPBolt", count:10, delayTics:5, arc:14, fireSnd:"holy3/holy3")
notes    A WIDENING SWEEP THEN A TIGHTENING ONE. There is a 25% bail
         (A_Jump(64,"Web")) BETWEEN the two runs at :2297, so the second six often
         never fire. Same random-per-bolt A_ScaleVelocity(random(2,4)) speed
         scatter as Atk1. Ends A_Jump(64,"Web","SpawnSpiders").
```

```
ATTACK   RS_WhiteSP11.Atk6
file     zscript/monsters/spider/RS_Spider.zs:2310
shape    FAN
payload  RS_WhiteSpiderPBolt x10
arc      30   (LITERAL angles -15,-11,-7,-3,-1,1,3,7,11,15 -- uneven steps 4,4,4,2,2,2,4,4,4)
timing   2 tics each = 20 tics of sweep; 20-tic entry
damage   DamageFunction (random(35,90))
type     Plasma
sound    --   (SeeSound "holy3/holy3")
impact   PLSE ABCDE 4 Bright, no A_Explode; DeathSound "holy2/holy2"
trigger  Missile   (in both health pools; Atk7 is separately in the pool too)
range    --
mirrored yes   (Atk7 at :2325 is the SAME TEN LITERAL ANGLES IN REVERSE:
                15,11,7,3,1,-1,-3,-7,-11,-15 -- a right-to-left sweep. Per spec
                section 1 that is not a second row.)
inherit  --
profile  MakeBurst(proj:"RS_WhiteSpiderPBolt", count:10, delayTics:2, arc:30, fireSnd:"holy3/holy3")
notes    THE ONLY LITERAL-ANGLE FAN IN THE FAMILY and the cleanest thing here to
         rebuild -- a 30-degree wall of bolts swept across in 20 tics.
         THE STEP IS NOT EVEN: it is dense in the middle (-3,-1,1,3) and coarse at
         the edges. MakeBurst's arc is uniform, so a faithful rebuild loses that.
         Atk6 ends A_Jump(64,"Web","Atk7"); Atk7 ends A_Jump(64,"Web","Atk6") --
         they chain into each other, so a left sweep is often answered by a right.
```

```
ATTACK   RS_WhiteSP11.Atk8
file     zscript/monsters/spider/RS_Spider.zs:2340
shape    SINGLE
payload  RS_WhiteSpiderHomer x1
arc      --   (literal angle 0)
timing   one shot on a 0-tic frame; 29-tic windup, 24-tic tail
damage   DamageFunction (random(35,90))
type     Plasma
sound    --   (SeeSound "holy3/holy3")
impact   MISL BC D 4 Bright with A_Explode(random(10,40),64,0) on the C frame,
         then 9 white particles and 8x RS_WhiteSPWebWeb -- IT LEAVES A SLOW FIELD
         WHERE IT LANDS. DeathSound "holy2/holy2".
trigger  Missile   (health < 4000 ONLY)
range    --
mirrored no
inherit  --
profile  MakeHeavy(proj:"RS_WhiteSpiderHomer", fireSnd:"holy3/holy3", spawnHeight:28.0)
notes    THE INESCAPABLE ONE. Speed 6 -- slower than a walking player -- but
         A_SeekerMissile(72,72,SMF_PRECISE) turns SEVENTY-TWO DEGREES PER CALL,
         twice per 12-tic loop, with SMF_PRECISE. It cannot be outturned; it can
         only be outrun or shot down, and its landing lays eight web patches to
         stop you outrunning it. +DONTHARMCLASS. Ends A_Jump(64,"SpawnSpiders").
```

## The white boss's egg — RS_WhiteSpidegg (minion, no tier token)

```
ATTACK   RS_WhiteSpidegg.See
file     zscript/monsters/spider/RS_Spider.zs:2435
shape    SCATTER
payload  RS_WhiteSPWebWeb x12   (3 at each of four points in the cycle)
arc      --   (placed by offset: random(12,64) or random(12,82) forward,
               random(-28,28) lateral, random(1,8) up)
timing   ~54-tic cycle x4: 16 + 12 + 43 A_Wander frames, then A_FaceTarget and 3 webs
damage   0
type     --
sound    --
impact   each patch runs A_RadiusGive("RS_WHITESPSlowdown",64,RGF_PLAYERS|RGF_CUBE,1)
         FOUR TIMES over 48 tics -- see the web row above
trigger  Walk   (this IS the See state; the egg never has a Missile state)
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_WhiteSPWebWeb", count:3, cap:12)
         // a field emitter, not a summon -- no factory fits; see notes
notes    A WANDERING SLOW-FIELD MINE LAYER. It A_FaceTargets before each drop but
         the webs are placed by OFFSET, ahead of itself, not at the player.
         `Goto Death` at :2452: IT SELF-DESTRUCTS after four cycles (~216 tics)
         whether or not anything killed it. +NOTARGET +LOOKALLAROUND, Speed 7.
         MakeSummon is the closest existing factory and it is a poor fit -- the
         payload is not a monster.
```

```
ATTACK   RS_WhiteSpidegg.Death
file     zscript/monsters/spider/RS_Spider.zs:2456
shape    RAIN
payload  A_Explode + RS_WhiteSPWebWeb x8
arc      --   (webs at random(-64,64) / random(-64,64) / random(-8,26))
timing   4,4,4 tics of MISL, then 9 particle tics, then the webs on one tic
damage   A_Explode(random(10,80),64,0)
type     --
sound    DeathSound "weapons/rocklx" (via A_ScreamAndUnblock)
impact   8 more slow patches thrown to +-64 in every direction
trigger  Death   (reached both from damage and from the See timeout)
range    --
mirrored no
inherit  --
profile  MakeRadial(radius:64, damage:45, fireSnd:"weapons/rocklx")
notes    Shape RAIN because the eight patches are placed AROUND the corpse rather
         than aimed. Killing the egg does not remove the hazard -- it doubles it.
```

## Tier 11 legacy — RS_WhiteSP11Old

Unreferenced by any spawner in CH (the gate points at `RS_WhiteSP11`); imported
whole so nothing is silently dropped. Rows recorded because the attacks are
distinct and reusable. `Missile:` at `:2532` is `A_Jump(256,"Atk1","Atk2","Atk3")`.

```
ATTACK   RS_WhiteSP11Old.Atk1
file     zscript/monsters/spider/RS_Spider.zs:2538
shape    FAN
payload  RS_MiniSP1 x3   (live monsters)
arc      90   (A_PainAttack + A_DualPainAttack at +-45)
timing   4 tics then 2 tics; 2-tic face windup
damage   --
type     --
sound    --
impact   see RS_MiniSP1 rows
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_MiniSP1", count:3, cap:12, tierOffset:-2)
notes    RS_WhiteSP11.SpawnSpiders at half the frame times (4/2 vs 8/4).
```

```
ATTACK   RS_WhiteSP11Old.Atk2
file     zscript/monsters/spider/RS_Spider.zs:2544
shape    HITSCAN
payload  A_CustomBulletAttack x2 -- 1 bullet each, puff RS_SPWht
arc      --   (spread 0,0 -- pinpoint)
timing   2 tics, 1-tic face, 2 tics; 9-tic entry
damage   random(3,9) per bullet, as written
type     --
sound    --   (RS_SPWht SeeSound "Vile/Active" plays on the puff)
impact   RS_SPWht spawns 3 RS_MiniSP1 PER HIT -- see the RS_SPWht row
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeHitscan(fireSnd:"Vile/Active", spreadScale:0.0, impactPuff:"RS_SPWht")
notes    A PINPOINT HITSCAN THAT SPAWNS MONSTERS WHERE IT LANDS. Two shots, six
         minions. Engine may apply its own multiplier to damageperbullet unless
         CBAF_NORANDOM -- see UNRESOLVED.
```

```
ATTACK   RS_SPWht   (SECONDARY -- the puff is an attack)
file     zscript/monsters/spider/RS_SpiderFX.zs:2068
shape    MULTI
payload  A_Explode + RS_MiniSP1 x3
arc      --   (minions at random(-128,128) / random(-128,128) / random(8,56))
timing   1,1 tics (2 explodes), then 1,1,1 tics (3 minions)
damage   A_Explode(5,32) on TWO frames
type     --
sound    SeeSound "Vile/Active"
impact   --   (this IS the impact)
trigger  Spawn   (the puff's own Spawn state)
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_MiniSP1", count:3, cap:24)
notes    `Spawn:` FALLS THROUGH INTO `Melee:` -- there is no Stop between them
         (RS_SpiderFX.zs:2067-2071), so the three minions spawn on EVERY hit, not
         only in melee range. Confirmed by reading the state chain, not by
         assuming engine puff semantics. Also +PUFFONACTORS +ALLOWPARTICLES,
         Scale 2, RenderStyle Add.
```

```
ATTACK   RS_WhiteSP11Old.Atk3
file     zscript/monsters/spider/RS_Spider.zs:2551
shape    SCATTER
payload  RS_SPWHI2 x6
arc      34 max   (random(-1,1), random(3,12), random(-12,-3), random(-7,7),
                   random(-17,17), random(-12,12))
timing   5,0,0 tics (three on one beat), then 5,3,1 tics; 9-tic entry
damage   DamageFunction (random(10,75))
type     Melee
sound    --   (SeeSound "phantom/bomb")
impact   PLSE BCDE 8 Bright A_Explode(random(5,20),128) on FOUR frames, plus
         A_SpawnItemEx("RS_MiniSP1",...) -- ONE MINION PER BOLT.
         DeathSound "phantom/explode".
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeBurst(proj:"RS_SPWHI2", count:6, delayTics:2, arc:34, fireSnd:"phantom/bomb")
notes    Payload Speed 23 with A_Weave(1,1,2,1). Six bolts, four blasts each, and
         six new minions if they all connect.
```

```
ATTACK   RS_WhiteSP11Old.Pain
file     zscript/monsters/spider/RS_Spider.zs:2563
shape    SCATTER
payload  RS_MiniSP1 x3   (live monsters, A_SpawnItemEx not A_PainAttack)
arc      --   (placed at random(-128,128) / random(-128,128) / random(8,56),
               velocities random(0,3) on all three axes, angle random(0,64))
timing   1,1,1 tics
damage   --
type     --
sound    PainSound "kawai/pain" -- SEE NOTES, this is silent
impact   --
trigger  Pain
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_MiniSP1", count:3, cap:24, tierOffset:-2)
         // trigger: RS_FIRE_PAIN
notes    RETALIATION SUMMON -- every pain state adds three minions, uncapped.
         "kawai/pain" IS DEFINED NOWHERE IN CH's SNDINFO: CH defines Kawai/sight,
         Kawai/hurt, Kawai/death and Kawai/active, never Kawai/pain. Silent in CH,
         kept verbatim across all five white spiders (RS_SpiderFX.zs:53-56).
```

```
ATTACK   RS_WhiteSP11Old.Death
file     zscript/monsters/spider/RS_Spider.zs:2570
shape    MULTI
payload  A_Explode + RS_WhiteSP2 x2   (live monsters)
arc      --   (the two halves placed at random(0,128) and random(-128,0))
timing   10,10,10 tics of MISL -- A_Explode fires on ALL THREE FRAMES
damage   A_Explode(50,128) x3
type     --
sound    DeathSound "kawai/death" (via A_ScreamAndUnblock)
impact   --
trigger  Death
range    --
mirrored yes   (one half to +x/+y, one to -x/-y)
inherit  --
profile  MakeRadial(radius:128, damage:50, fireSnd:"kawai/death")
         + MakeSummon(summonCls:"RS_WhiteSP2", count:2, cap:2)
notes    MULTI-FRAME A_EXPLODE, DELIBERATE -- three separate 50-damage blasts at
         radius 128, one per MISL frame. THE BOSS SPLITS: two RS_WhiteSP2 at 1250
         HP each. Killing it is a phase change, not an end.
```

## Tier 11 — RS_WhiteSP2 ("White Spider and half")

`Missile:` at `:2634` is `A_Jump(256,"Atk1","Atk3")`.

```
ATTACK   RS_WhiteSP2.Atk1
file     zscript/monsters/spider/RS_Spider.zs:2640
shape    FAN
payload  RS_MiniSP1 x3   (live monsters)
arc      90   (A_PainAttack + A_DualPainAttack at +-45)
timing   8 tics then 4 tics; 6-tic face windup
damage   --
type     --
sound    --
impact   see RS_MiniSP1 rows
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_MiniSP1", count:3, cap:12, tierOffset:-2)
notes    Identical to RS_WhiteSP11.SpawnSpiders, but here it is HALF THE ROUTER --
         this form spends 50% of its attacks summoning.
```

```
ATTACK   RS_WhiteSP2.Atk3
file     zscript/monsters/spider/RS_Spider.zs:2646
shape    FAN
payload  RS_SPWHI3 x3
arc      48   (three bands, rule 2: random(-1,1), random(8,24), random(-24,-8))
timing   ONE TIC -- 5,0,0, so all three effectively together. 13-tic entry.
damage   DamageFunction (random(10,75))
type     Melee
sound    --   (SeeSound "phantom/bomb")
impact   PLSE BCDE 8 Bright A_Explode(random(5,20),128) on FOUR frames, plus
         A_SpawnItemEx("RS_MiniSP1",...) -- ONE MINION PER BOLT.
         DeathSound "phantom/explode".
trigger  Missile
range    --
mirrored yes   (the two flanking bands are exact mirrors: +8..+24 and -24..-8)
inherit  --
profile  MakeVolley(proj:"RS_SPWHI3", count:3, arc:48, fireSnd:"phantom/bomb")
notes    A WIDE THREE-WAY WITH A DELIBERATE HOLE -- nothing is fired between
         +-1 and +-8, so strafing INTO the centre is safer than strafing out.
         Payload is +SEEKERMISSILE at Speed 29 with A_SeekerMissile(1,2), which
         partially closes that hole over distance.
```

```
ATTACK   RS_WhiteSP2.Pain
file     zscript/monsters/spider/RS_Spider.zs:2654
shape    SCATTER
payload  RS_MiniSP1 x2   (live monsters)
arc      --   (random(-128,128) / random(-128,128) / random(8,56))
timing   1,1 tics
damage   --
type     --
sound    PainSound "kawai/pain" -- undefined in CH, silent
impact   --
trigger  Pain
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_MiniSP1", count:2, cap:24, tierOffset:-2)
         // trigger: RS_FIRE_PAIN
notes    Two per pain instead of the legacy boss's three.
```

```
ATTACK   RS_WhiteSP2.Death
file     zscript/monsters/spider/RS_Spider.zs:2659
shape    MULTI
payload  A_Explode + RS_WhiteSP3 x2   (live monsters)
arc      --
timing   10,10,10 tics -- A_Explode on ALL THREE frames
damage   A_Explode(30,88) x3
type     --
sound    DeathSound "kawai/death"
impact   --
trigger  Death
range    --
mirrored yes
inherit  --
profile  MakeRadial(radius:88, damage:30, fireSnd:"kawai/death")
         + MakeSummon(summonCls:"RS_WhiteSP3", count:2, cap:2)
notes    SPLITS AGAIN -- two RS_WhiteSP3 at 500 HP. Note this form does NOT call
         A_BossDeath, unlike RS_WhiteSP11Old. Multi-frame A_Explode, deliberate.
```

## Tier 11 — RS_WhiteSP3 ("White Spider and 1/4")

```
ATTACK   RS_WhiteSP3.Missile
file     zscript/monsters/spider/RS_Spider.zs:2725
shape    FAN
payload  RS_MiniSP1 x3   (live monsters)
arc      90   (A_PainAttack + A_DualPainAttack at +-45)
timing   8 tics then 4 tics; 6-tic face windup
damage   --
type     --
sound    --
impact   see RS_MiniSP1 rows
trigger  Missile
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_MiniSP1", count:3, cap:12, tierOffset:-2)
notes    ITS ONLY ATTACK -- no router, no alternative. This form is a pure
         spawner.
```

```
ATTACK   RS_WhiteSP3.Pain
file     zscript/monsters/spider/RS_Spider.zs:2732
shape    SINGLE
payload  RS_MiniSP1 x1   (live monster)
arc      --   (random(-128,128) / random(-128,128) / random(8,56))
timing   1 tic
damage   --
type     --
sound    PainSound "kawai/pain" -- undefined in CH, silent
impact   --
trigger  Pain
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_MiniSP1", count:1, cap:24, tierOffset:-2)
         // trigger: RS_FIRE_PAIN
notes    One per pain.
```

```
ATTACK   RS_WhiteSP3.Death
file     zscript/monsters/spider/RS_Spider.zs:2737
shape    MULTI
payload  A_Explode + A_Burst("RS_MiniSP1")
arc      360   (A_Burst throws its chunks in every direction)
timing   10,10,10 tics of MISL with A_Explode on ALL THREE, then A_Burst on a 0-tic frame
damage   A_Explode(30,88) x3
type     --
sound    DeathSound "kawai/death"
impact   --
trigger  Death
range    --
mirrored no
inherit  --
profile  MakeSummon(summonCls:"RS_MiniSP1", count:24, cap:64)
         // count is a floor, not the measured value -- see notes
notes    A_Burst SPAWNS A LOT. The engine derives its chunk count from the actor's
         radius and height, and this actor is Radius 42 / Height 42, which puts
         the count well above A_Burst's own floor of 24. THE EXACT FORMULA COULD
         NOT BE VERIFIED THIS SESSION (see UNRESOLVED), so `count:24` above is
         recorded as a FLOOR, not a measurement. Do not treat it as the answer.
         Byte-identical to CH (Spiders.txt:4330).
```

## The white boss's minion — RS_MiniSP1 (no tier token)

```
ATTACK   RS_MiniSP1.Melee
file     zscript/monsters/spider/RS_Spider.zs:2813
shape    MELEE
payload  --
arc      --
timing   4-tic face, 2-tic strike
damage   random(3,12)   (literal arg to A_CustomMeleeAttack -- NOT a hit-dice roll)
type     --   (damagetype arg is the literal string "None")
sound    "bite/bite4"   (hit sound arg); miss sound is the literal "None"
impact   --
trigger  Melee
range    --   (engine melee range)
mirrored no
inherit  --
profile  MakeMelee(fireSnd:"bite/bite4", dmgMult:1.0)
notes    THE ONLY A_CustomMeleeAttack IN THE FAMILY, and the only attack here
         whose damage roll is unambiguous -- A_CustomMeleeAttack takes literal
         damage, no engine multiplier. Its See state is
         A_Chase("Melee",null,CHF_STOPIFBLOCKED) -- MELEE ONLY, no missile branch,
         so it must close. A_CheckBlock("IStuck",CBF_DROPOFF) gives it a
         noclip-and-wander unstick at :2787/:2789.
```

```
ATTACK   RS_MiniSP1.Death
file     zscript/monsters/spider/RS_Spider.zs:2821
shape    RAIN
payload  A_Explode
arc      --
timing   20-tic scream, then 10,10,10 tics -- A_Explode on ALL THREE MISL frames
damage   A_Explode(random(1,9),32) x3
type     --
sound    DeathSound "kawai/death" (via A_ScreamAndUnblock)
impact   --
trigger  Death
range    --
mirrored no
inherit  --
profile  MakeRadial(radius:32, damage:5, fireSnd:"kawai/death")
notes    Tiny, but every minion does it, and the white boss makes them by the
         dozen. Multi-frame A_Explode, deliberate.
```

---

# UNRESOLVED

Honest gaps. Nothing below was guessed into a row.

### 1. CH IS NOT AT THE PATH THE SPEC AND CLAUDE.md NAME

`C:\Users\Command\Desktop\CH` **does not exist on this machine.** `Desktop`
contains `CHP`, not `CH`. Every CH citation in this file was made against
**`E:\New folder\ART SOURCE\CH\decorate\Spiders.txt`**, which CLAUDE.md's
"IMPORTING A MONSTER MEANS THE WHOLE MONSTER" section also names as the source
of truth, and which is 4,574 lines — matching exactly what `RS_Spider.zs`'s own
header says it was transcribed from. I am confident it is the same pack, but
**the path in rs_35 and in CLAUDE.md's "GROUND TRUTH" paragraph is stale** and
the owner should say which one is canonical.

### 2. TREE vs CH DIVERGENCES FOUND (both recorded, neither "fixed")

Every attack call site in `RS_Spider.zs` was diffed against CH line-by-line —
angles, tic counts, jump chances, range gates, payload names, refire arguments.
**They match, without exception.** Two known non-attack divergences:

* **`SGRN` -> `HGRN` sprite prefix**, `RS_SpiderStoneRocket` (`RS_SpiderFX.zs:594-603`)
  and `RS_SpRocket3` (`:1655-1656`). CH writes `SGRN`, which ships nowhere in the
  CH tree — both rockets fly invisible in CH. Our tree renders `HGRN`, changed
  2026-08-06 on the owner's "nothing invisible" call, with a `// CH:` note on
  every line. **This is a deliberate, documented divergence, not drift.**
* **`A_CustomRailgun` spawnclass**, `RS_WhiteSP11.Atk2` (`RS_Spider.zs:2277`).
  CH passes the empty string `""`; ours passes `null`. Semantically the same
  "no spawnclass", but they are not the same token. Recorded, not touched.

### 3. FOUR ENGINE SEMANTICS COULD NOT BE SETTLED FROM SOURCE

**`E:\DXR2` does not exist on this machine either** — only C:, D: and E: are
mounted and there is no `DXR2` on E:. CLAUDE.md says the engine source is the
authority on questions like these and that it lives there; it does not, right
now. These four are therefore recorded as open, and no row leans on a guess:

* **`A_MonsterRefire(prob, state)` and `A_SpidRefire` — which way does the roll
  run?** Six `A_MonsterRefire` and eight `A_SpidRefire` calls bound this family's
  loops. Every row states the literal call and the cycle period in tics and
  **stops there**; no row converts a `prob` into an expected round count. If the
  roll gates *continuing* rather than *bailing*, then a live visible target means
  the loop never exits on its own, which would change how a rebuilt profile must
  be capped. **This is the single most load-bearing open question in the file.**
* **`MeleeDamage 6` (`RS_YellowSP1`) — is a hit-dice multiplier applied?** The
  Doom convention would make it 6..48. Recorded verbatim as `MeleeDamage 6`.
* **`A_CustomBulletAttack` `damageperbullet` — is an engine roll applied unless
  `CBAF_NORANDOM`?** Affects `RS_PurpleSP1.Missile` (`random(1,3)`) and
  `RS_WhiteSP11Old.Atk2` (`random(3,9)`). Both recorded as written.
* **`A_Burst` chunk count** (`RS_WhiteSP3.Death`). Believed to derive from
  radius x height with a floor of 24; for Radius 42 / Height 42 that would be
  well over 24. The profile records **24 as a floor** and says so.

### 4. `RS_BrownOrbSpiderCH.XDeath` — DOES A PROJECTILE EVER REACH IT?

`RS_SpiderFX.zs:103-116` gives this projectile a full `XDeath` branch (the
mind-flag check, `A_VileTarget`, `A_VileAttack("weapons/bfgx",...)`, four
`RS_ZapFFAT`). Whether GZDoom routes an exploding missile to `XDeath` or to
`Death.Extreme` is exactly the kind of question the engine source would settle,
and it is absent (see 3). CH is byte-identical here, so this is CH's structure,
not an import error. **If the branch is dead, the brown recluse's orb is a
zero-damage projectile whose only output is the five stacked
`A_Explode(random(2,8),64)` in `Death`.** That is a large behavioural
difference and it is not resolved. The row is written; it is flagged here.

### 5. `A_CustomMissile` PITCH SIGN

`RS_WhiteSP11.Atk4` passes `pitch` values of `random(10,20)` and `random(13,30)`
with `flags = 2` (`CMF_AIMDIRECTION`). Whether positive pitch aims up or down in
`A_CustomMissile` was not verified (see 3). The row records the arguments
verbatim and describes the slimeballs as "lobbed" on the strength of
`-NOGRAVITY` being cleared on `RS_SlimeBall1`, which is independent evidence —
but the pitch direction itself is unconfirmed. Same caveat applies to
`RS_GraySP2.Missile` (`random(-1,1)`) and `RS_CyanSP2.IceOrbs` (`random(-3,3)`),
where the magnitude is small enough not to matter.

### 6. SIX FX CLASSES ARE ORPHANS — IN CH TOO, VERIFIED

No source line in our tree or in CH's `decorate/` names these. They are not
missing payloads and no attack row depends on them; they are dead code that CH
shipped and the import faithfully carried:

| Class | Ours | Referenced in CH? |
|---|---|---|
| `RS_SPWHII3` | `RS_SpiderFX.zs:1668` | no |
| `RS_SPWHII2` | `RS_SpiderFX.zs:1697` | no |
| `RS_SPWht2` | `RS_SpiderFX.zs:1858` | no |
| `RS_BlackSpideEXShade` | `RS_SpiderFX.zs:1065` | no |
| `RS_EyeSeePsychic1/2/3` | `RS_SpiderFX.zs:814/833/852` | no |

`RS_SPWHII3` and `RS_SPWHII2` are near-duplicates of the live `RS_SPWHI3` /
`RS_SPWHI2` with different damage rolls — `random(10,60)` instead of
`random(10,75)`, and no `RS_MiniSP1` spawn on death. **If a rebuild ever wants a
"white bolt without the minion rider", they are already written.**
`RS_EyeSeePsychic1/2/3` are the three mind-control tokens; their only content was
`ACS_NamedExecuteAlways("DirectionMind1..3")`, stripped per the standing ACS
rule, so they are live pickups that do nothing — exactly as an unresolved ACS
name would behave in CH.

### 7. TWO SHAPES ARE `UNCLASSIFIED` AND NO WORD WAS COINED

* **`RS_YellowBombEXSpidie.Death`** — one detonation that escalates through eight
  radii (32 -> 64 -> 74 -> 128 -> 176 -> 256 -> 256 -> 312) over ~30 tics while
  its scale ramps 0.5 -> 4.0. The closed set has RAIN and MULTI; neither is this.
* **`RS_WhiteSP11.Atk3`** — flee at `A_SetSpeed(45)` with `NOPAIN`, laying three
  live egg-mines *where it has run to*, then restore speed. The movement is the
  attack, and no shape word covers that.

Both are described in full in `notes`. Per spec section 3, no new word was
invented for either.

### 8. THREE THINGS NO EXISTING FACTORY EXPRESSES

Not gaps in the reading — gaps in `RS_AttackProfile`, recorded so the rebuild
does not silently drop them:

* **A field that applies a powerup.** `RS_WHITESPIDERWEBSHOTNOTLEWD.Death` plants
  `RS_WhiteSPWebWeb` patches whose entire function is
  `A_RadiusGive("RS_WHITESPSlowdown",...)` — a `PowerSpeed` at `Speed 0.2`. There
  is no damage anywhere in that chain. `MakeRadial(damage:0)` records the shape
  and loses the effect.
* **Uneven fan steps.** `RS_WhiteSP11.Atk6` fires at -15,-11,-7,-3,-1,1,3,7,11,15
  — dense in the middle, coarse at the edges. `MakeBurst`'s `arc` is uniform, so
  a faithful rebuild flattens it. Same class of loss the spec's own Frost Imp
  example flagged for `BurstDelayTics`.
* **Damage while travelling.** Four payloads run `A_Explode` on their *flight*
  frames, not only on death: `RS_SpiderCyanBomb` (every 5-tic loop),
  `RS_AbyssSPBreath` (four flight frames plus four death frames),
  `RS_BBSP1` (every 6-tic bounce loop), `RS_BlackSpideSpiralShot` (three times
  per spin). Every one is deliberate — these are gas, lingering fire and
  bouncing hazards, exactly the ~55 sites CLAUDE.md's multi-frame-`A_Explode`
  note says must not be converted. No factory field carries it.

### 9. WHAT WAS *NOT* CLASSIFIED AS AN ATTACK, AND WHY

Recorded so a later pass does not "find" these as missing rows:

* **`Pain.AbyssPE`** — present on 10 of the 19 monsters, identical every time.
  It is a *morph*: 45 tics of `AYPB` frames, ~90 `RS_SplashAbyss` particles, then
  `A_SpawnItemEx("RS_AbyssSP2")` and `A_Die()`. It replaces the monster with the
  abyss spider. Not an attack.
* **`RS_CyanSP2.Jumps`** (`:1123`), **`RS_AbyssSP2.Warp`** (`:1683`),
  **`RS_MiniSP1.IStuck`** (`:2791`) — repositioning (`A_Wander`), no payload.
* **`XDeath`** on the six ladder spiders — `RS_AraBoom1/2/3` and
  `RS_HomingRocketTrailFatso` gib visuals. `RS_AraBoom1/2/3` have **no
  `A_Explode` and no damage** (`RS_SpiderFX.zs:644/666/689`); they are pure FX.
* **`RS_BrownSP2`'s heal** (`:981`) — `A_RadiusGive("Health",320,RGF_MONSTERS,200)`
  plus five `RS_MediCacoBrown`. Folded into the Brown Missile row's `notes` with
  its own suggested `MakeRadial(radius:320, heal:200, hitsAllies:true)` rather
  than given a row, since it fires as part of the missile state.
* **`RS_WhiteSP11`'s `Damage 5`** (`:2194`) — the actor has **no `Melee` state**,
  so this property is inert. Recorded because "a `Damage` on a monster" reads
  like an attack and is not one.
* **The eight cvar-gate stubs** (`RS_Colourset9`, `RS_BrownSP1`, `RS_CyanSP1`,
  `RS_AbyssSP1`, `RS_FireBluSP1`, `RS_GraySP1`, `RS_BlackSP1`, `RS_WhiteSP1`) —
  `TNT1` spawner logic only.
