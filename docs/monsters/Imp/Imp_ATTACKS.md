# IMP — MONSTER ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Shape words are the CLOSED
set from spec §3. No word outside that set appears in a `shape` field.

## DENOMINATOR — what was actually read

    source files      2   zscript/monsters/imp/RS_Imp.zs        (2,296 lines, read whole)
                          zscript/monsters/imp/RS_ImpFX.zs      (1,355 lines, read whole)
    classes read     73   28 in RS_Imp.zs + 45 in RS_ImpFX.zs
    state labels    212   in RS_Imp.zs, comment-stripped count
    call sites      174   159 A_CustomMissile, 10 A_CustomMeleeAttack,
                          2 A_VileTarget, 1 A_CustomRailgun, 1 A_TroopAttack,
                          1 A_RadiusGive, 1 A_RadiusThrust, 1 A_Explode
                          (comment-stripped; A_SpawnItemEx sites counted per row)
    monsters         14   classes that carry an attack
    non-attack       14   2 RandomSpawners, 7 cvar-gated spawn stubs,
                          5 ghost subclasses (attacks inherited, See overridden)
    ATTACK ROWS      54   incl. 6 SECONDARY rows (payloads that are themselves
                          attacks) and 1 SHARED row (identical across 9 monsters)

External payload classes opened (they live in other families' FX files, and
several of them carry the impact FX that the imp attack rows depend on):
`RS_ChaingunnerFX.zs` (RS_CGNail, RS_CGthing3, RS_PuffCybieRed, RS_SpiralSaw5,
RS_GroundRedCyb), `RS_ShotgunnerFX.zs` (RS_RedMessImp2, RS_RedMessImp,
RS_SparkPuff1, RS_CHBSTarget, RS_CH_Cirno), `RS_ZombiemanFX.zs`
(RS_SplashAbyss, RS_SplashAbyss2, RS_FireSGguy2, RS_RedThingsHK,
RS_HKRedDeath, RS_AbyssShotIdentifier).

## CH VERIFICATION

Our tree was diffed against CH state-by-state for all 14 attacking monsters.
**Every attack state matches CH's `Imps.txt` exactly** — same payload classes,
same counts, same angles, same tics, same damage rolls, same arg order
(including CH's own arg-order scramble in `WhiteImp2.Megaball`, carried
verbatim). No disagreement to flag. Sites checked: CH `Imps.txt` 40–183
(BrownImp2), 297–463 (CyanImp2), 514–637 (AbyssImp2), 726–835 (FireBluImp2),
854–961 (GrayImp2), 987–1072 (CommonImp), 1072–1207 (GreenImp), 1207–1363
(BlueImp), 1363–1535 (PurpleImp), 1535–1662 (YellowImp), 1688–1803 (RedImp),
2085–2263 (BlackImpEX), 2300–2437 (BlackImp1), 2776–2981 (WhiteImp2).

**CH was read at `E:\New folder\ART SOURCE\CH\decorate\Imps.txt`.** The path the
spec and CLAUDE.md both name — `C:\Users\Command\Desktop\CH` — **does not exist
on this machine.** Desktop holds `CHP` and no `CH`. See UNRESOLVED.

## CONVENTIONS USED IN THIS FILE (stated so a composer can re-derive them)

1. **`file` cites the first attack LINE**, per spec §2. Where a state label sits
   a few lines above its first attack line they differ; the label is named in
   `ATTACK`, so nothing is lost. (The spec's own worked example cites the label
   line, 421, not the first attack line, 424. Rule followed over example.)
2. **MULTI is used iff the attack fires two or more DAMAGING payload classes.**
   Cosmetic co-spawns that cannot hurt anything (`RS_SparkPuff1`, `RS_EffectHK`,
   `RS_BaronRing`, `RS_BlackImpEXcharge`) do NOT make an attack MULTI; they are
   listed in `payload` marked `(cosmetic)`. Where MULTI and a geometric word
   both apply, MULTI wins in `shape` and the geometry is recorded in `arc` and
   `notes`. This is the literal reading of §3 and is applied without exception.
3. **`A_SpawnItemEx` does not play a SeeSound; `A_CustomMissile` does.** Rows
   where the same class is delivered both ways are therefore half-silent, and
   that is recorded rather than averaged away.
4. **A bare `Damage n` on a projectile is an engine roll**, `n × random(1,8)`.
   Recorded as written plus the resolved band, never flattened.
5. **A frame-run fires its action once per FRAME.** `GG 1 A_CustomMissile(...)`
   is TWO shots, `RIP1 ABCABCABCBA 12 A_Explode(...)` is ELEVEN explosions.
   Counts below are frame counts, not line counts.
6. **SECONDARY rows** are payloads that are themselves attacks (spec §4). Their
   `ATTACK` id is `<PayloadClass>.<StateLabel>` and `trigger` names the beat of
   the payload, not of a monster.

---

# TIER 13 — RS_BrownImp2 ("medium evil imp")

`zscript/monsters/imp/RS_Imp.zs:198`. Attack states reached from Missile:
`FireSpike` (fallthrough), `Scatter` (via `A_CheckProximity`), `MaybeParry3`
→ `Parry` (via `A_Jump(32)`). Parry is ALSO reached from See
(`MaybeParry`/`MaybeParry2`, `A_JumpIfInTargetLOS` 200..1200) and from Pain
(`A_Jump(64)`). Death/XDeath drop `RS_WarlordMace` + `RS_WarlordShield` — both
`BounceType "Doom"` props with no Damage, no A_Explode: **not attacks**.

    ATTACK   RS_BrownImp2.Melee
    file     zscript/monsters/imp/RS_Imp.zs:265
    shape    MELEE
    payload  --   (A_CustomMeleeAttack, no projectile)
    arc      --
    timing   6,4,5   (15 tics; the hit lands on the third beat)
    damage   random(1,8)*7      -> 7..56
    type     --   (A_CustomMeleeAttack's default, untyped)
    sound    "skeleton/melee" on hit; A_SkelWhoosh (RS_Imp.zs:262) plays
             "skeleton/swing" on the windup. Miss sound is the literal
             string "none" -- CH's idiom for silence, not a sound name.
    impact   --
    trigger  Melee
    range    ..MeleeRange (Actor default 64; this monster sets none)
    mirrored no
    inherit  --
    profile  MakeMelee(range:64, fireSnd:"skeleton/melee", dmgMult:1.0,
                       profName:"Warlord Swing")
    notes    The only imp melee with a two-part sound (whoosh then hit) and
             the only one whose damage is a MULTIPLIED roll rather than a
             flat band. 7..56 in steps of 7 -- the spread is chunky, not
             smooth, and a factory that writes random(7,56) is NOT the same
             distribution. Preserve the *7 form.

    ATTACK   RS_BrownImp2.FireSpike
    file     zscript/monsters/imp/RS_Imp.zs:279
    shape    SCATTER
    payload  RS_FatsoSpikes2 x4
    arc      10   (three lobbed at frandom(-5,-2) / frandom(-1,1) /
                   frandom(2,5); one aimed dead-on)
    timing   one tic   (all four on the same tic, after a 3+6+3 = 12-tic windup)
    damage   DamageFunction (random(10,40))
    type     Melee   (yes -- a projectile with DamageType "Melee";
                      RS_BrownImp2 itself has DamageFactor "Melee", 0.5)
    sound    "monster/dknmsl" -- but ONCE, not four times. Only the single
             A_CustomMissile spike (RS_Imp.zs:281) plays the SeeSound; the
             three A_SpawnItemEx spikes (:279, :280, :282) are silent.
    impact   BounceSound "fire/fire3", DeathSound "weapons/boom1", then
             `RIP1 ABCABCABCBA 12 A_Explode(random(1,4),8)` --
             ELEVEN separate A_Explode calls over 132 tics. A lingering
             damage patch, not one detonation. Do not collapse to one.
    trigger  Missile
    range    --
    mirrored no
    notes-b  Three spikes are A_SpawnItemEx (xofs 12, yofs 8, zofs 28,
             forward vel random(20,45), zvel random(-1,2)) and one is
             A_CustomMissile(32,12,0). The spawned three inherit NO aim --
             they are thrown, and RS_FatsoSpikes2 is -NOGRAVITY with
             Gravity 0.1 and Speed 5, so they arc. The A_CustomMissile one
             is aimed but travels at Speed 5, i.e. crawls.
    inherit  --
    profile  MakeVolley(proj:"RS_FatsoSpikes2", count:4, arc:10,
                        fireSnd:"monster/dknmsl", pitchJitter:3,
                        profName:"Spike Toss")
    notes    Reached by fallthrough from Missile AND as the tail of Scatter
             (RS_Imp.zs:293, `Goto FireSpike`), so the war-cry always ends in
             a spike volley. The three thrown spikes get their velocity from
             the SPAWN, not from Speed -- a factory that only sets an angle
             will produce four identical slow spikes, which is wrong. Record
             the split delivery.

    ATTACK   RS_BrownImp2.Scatter
    file     zscript/monsters/imp/RS_Imp.zs:291
    shape    UNCLASSIFIED
    payload  RS_BrownImpCommand x1 (CustomInventory, given by radius, not fired)
    arc      360   (A_RadiusGive is omnidirectional)
    timing   3,18,12,3   (36 tics; the give lands at t=21)
    damage   --   (this attack does no damage at all)
    type     --
    sound    "imp/sight" x3 (RS_Imp.zs:289, `WARI OOO 6` -- three frames,
             three plays, a stuttered war-cry)
    impact   Each recipient spawns RS_BrownImpBuffCtl (RS_ImpFX.zs:80) which
             for 300 tics sets +ALWAYSFAST, halves DamageFactor to 0.5, and
             shoves the ally at a random angle (vel += random(1,12) units)
             and vertically (random(1,12) quarter-units, up or down) --
             then reverts both. Native rebuild of CH's ACS pack-buff.
    trigger  Missile   (via A_CheckProximity("Scatter","DoomImp",200,1,
                        CPXF_ANCESTOR|CPXF_CHECKSIGHT) at RS_Imp.zs:272)
    range    --   (the GATE is on ally proximity, not target distance:
                   >=1 DoomImp-descendant within 200u and in sight)
    mirrored no
    inherit  --
    profile  MakeRadial(radius:200, damage:0, heal:0, hitsAllies:true,
                        fireSnd:"imp/sight", profName:"War Cry")
             -- IMPERFECT. MakeRadial can only express damage or heal.
             The buff (speed + damage resistance + shove) has no field.
             Closest honest build is MakeRadial for the shape plus
             MakeSelfBuff(speedMult:>1, damageMult:0.5, duration:300)
             applied to recipients; the factory has no ally-buff mode.
    notes    UNCLASSIFIED because no §3 word covers "grant an ally buff in a
             radius". Not coining one. This is the family's only support
             attack. The RGF_EXFILTER excludes RS_BrownImp2 itself and
             species "Imp" -- read the arg order: A_RadiusGive(item, dist,
             flags, amount, filter, species). Filter "RS_BrownImp2" +
             EXFILTER means OTHER brown imps are excluded, so a pack of
             brown imps does not stack the buff on each other.

    ATTACK   RS_BrownImp2.Parry
    file     zscript/monsters/imp/RS_Imp.zs:305
    shape    UNCLASSIFIED
    payload  RS_BrownImpShieldMini x1 (cosmetic -- no Damage, see notes)
    arc      360   (the pull is radial)
    timing   3,3,3,3,1,3,12,12,3,3,3,3   (52 tics; shield at t=13,
             pull at t=16, then a 24-tic recovery)
    damage   --   (A_RadiusThrust carries RTF_NOIMPACTDAMAGE: zero damage)
    type     --
    sound    "HEALSIEL" -- played by the SHIELD (RS_ImpFX.zs:164), not by
             the imp. The Parry state itself is silent.
    impact   A_RadiusThrust(-420, 252, RTF_NOIMPACTDAMAGE|RTF_THRUSTZ|
             RTF_NOTMISSILE, 128). NEGATIVE force = an inward PULL, 252-unit
             radius, vertical included, full thrust within 128 units.
             Everything in range is yanked toward the imp and up/down.
    trigger  Pain   (A_Jump(64) at RS_Imp.zs:297) -- also Missile (A_Jump(32)
                     -> MaybeParry3, :270) and Walk (MaybeParry /
                     MaybeParry2 out of See, :245 and :248)
    range    200..1200   (the See and Missile entries gate on
                          A_JumpIfInTargetLOS(...,1200,200); the Pain entry
                          does NOT gate -- it can parry point-blank)
    mirrored no
    inherit  --
    profile  MakeRadial(radius:252, damage:0, heal:0, hitsAllies:false,
                        fireSnd:"HEALSIEL", profName:"Vacuum Parry")
             -- IMPERFECT: MakeRadial has no "thrust" axis, and this attack
             is thrust-only with damage explicitly suppressed. Buildable
             shape, wrong verb. Flagged, not fudged.
    notes    UNCLASSIFIED: a damageless inward pull is not any §3 word.
             THE SHIELD DOES NO DAMAGE. RS_BrownImpShieldMini
             (RS_ImpFX.zs:129) is a Monster with Health 100 and NO Damage
             property, so its A_SkullAttack(4) ram deals damage*random(1,8)
             = 0. It exists to look like a parry, damages ITSELF 50
             (A_DamageSelf, :165) and dies after 24 tics. Anyone reading
             "A_SkullAttack" and writing CHARGE here would be wrong.
             Spawned with SXF_TRANSFERPOINTERS so it inherits the target.

---

# TIER 12 — RS_CyanImp2 ("Cyanide Imp")

`zscript/monsters/imp/RS_Imp.zs:347`. **This is the monster the spec's worked
example calls `RS_FrostImp`. No class of that name exists in this tree** — see
UNRESOLVED. `Melee` falls THROUGH into `Missile` (no `Goto See`), so a claw is
always followed by the ranged routine. `Jumpy` (:411) is a leap, not an attack.

    ATTACK   RS_CyanImp2.Melee
    file     zscript/monsters/imp/RS_Imp.zs:443
    shape    MELEE
    payload  --
    arc      --
    timing   8,8,6   (22 tics)
    damage   random(10,38)
    type     Ice   (4th arg of A_CustomMeleeAttack)
    sound    "imp/melee"
    impact   --
    trigger  Melee
    range    ..MeleeRange (Actor default 64)
    mirrored no
    inherit  --
    profile  MakeMelee(range:64, fireSnd:"imp/melee", profName:"Frost Claw")
    notes    The only TYPED melee in the family. Falls through into Missile
             at RS_Imp.zs:444 -- clawing does not end the beat, it chains
             into IceWeave or Missile2.

    ATTACK   RS_CyanImp2.IceWeave
    file     zscript/monsters/imp/RS_Imp.zs:424
    shape    FAN
    payload  RS_FrostLong2 x11
    arc      20   (-10..+10, even 2-degree step)
    timing   3,2,3,2,3,2,3,2,3,2,3   (28 tics total)
    damage   DamageFunction (random(3,9))
    type     Ice
    sound    --   (fires SILENT; RS_FrostLong2's parent has no SeeSound, and
                   the child's Spawn override deletes the "Ice/Fly" play too)
    impact   PUFI A-H frost puff + DeathSound "Ice/Hit2" -- BOTH INHERITED
    trigger  Missile   (via A_JumpIfCloser(600) from Missile, RS_Imp.zs:446)
    range    ..600
    mirrored yes  (OtherB, RS_Imp.zs:462, runs +10..-10 with A_SetScale(-1.0,1.0))
    inherit  RS_FrostLong (RS_ImpFX.zs:246). Child overrides Spawn ONLY:
             strips +SEEKERMISSILE, re-rolls damage 5..12 -> 3..9. It
             inherits Speed 76, DamageType Ice, DeathSound "Ice/Hit2", the
             PUFI death puff, RenderStyle Add, Alpha 0.85, Scale 0.3. The
             overridden Spawn (`KIRC ABCD 1 Bright`) also removes
             A_SeekerMissile, A_Weave AND A_PlaySound("Ice/Fly") -- so the
             child does not home, does not weave, and is silent in flight.
    profile  MakeBurst(proj:"RS_FrostLong2", count:11, delayTics:3, arc:20)
    notes    Uneven ripple 3/2 has no exact form -- BurstDelayTics is uniform.
             3 tics = 33 total vs CH's 28. Recorded, not silently rounded.
             OPENS WITH AN ABORT: A_Jump(102,"Missile2") at RS_Imp.zs:422 --
             102/256 (~40%) of IceWeave entries never fire the fan at all
             and do the two-ball attack instead. The fan is therefore the
             minority outcome at close range, which the range band alone
             does not tell you. Ends with a 128/256 mirror roll into
             OtherB, then a backflip (ThrustThingZ 64 + ThrustThing -180).

    ATTACK   RS_CyanImp2.Missile2
    file     zscript/monsters/imp/RS_Imp.zs:450
    shape    BURST
    payload  RS_CyanImpBall x2
    arc      15   (shot 1 dead-on; shot 2 at random(1,15), or random(-15,-1)
                   on the mirror)
    timing   shot 1 at t=9, shot 2 at t=21   (12 tics apart, 24-tic total)
    damage   DamageFunction (random(2,20))
    type     Ice
    sound    "imp/attack" (RS_CyanImpBall SeeSound) -- once per shot
    impact   DeathSound "Ice/Hit2", A_Scream, 15 cyan particles, AND SEVEN
             LIVE RS_FrostLong2 at random(0,359) -- see the SECONDARY row
             below. The impact is a bigger attack than the shot.
    trigger  Missile   (the >=600 branch, i.e. the fallthrough when
                        A_JumpIfCloser fails; also the abort target of
                        IceWeave's A_Jump(102))
    range    600..
    mirrored yes  (OtherS, RS_Imp.zs:457, is the same shot at random(-15,-1);
                   coin-flipped by A_Jump(128) at :453)
    inherit  --
    profile  MakeBurst(proj:"RS_CyanImpBall", count:2, delayTics:12, arc:15,
                       fireSnd:"imp/attack", profName:"Cyanide Double")
    notes    A_SetScale(-1.0,1.0) at :451 flips the SPRITE between shots --
             animation, not shape. Stripped per spec §4.

    ATTACK   RS_CyanImpBall.Death            [SECONDARY]
    file     zscript/monsters/imp/RS_ImpFX.zs:541
    shape    RING
    payload  RS_FrostLong2 x7
    arc      360   (random(0,359) -- the tell)
    timing   one tic   (all seven on the same 0-tic frame run)
    damage   DamageFunction (random(3,9))   each
    type     Ice
    sound    A_Scream plays RS_CyanImpBall's DeathSound "Ice/Hit2"
    impact   each shard carries the inherited PUFI puff + "Ice/Hit2"
    trigger  Death   (of the payload, not of a monster)
    range    --
    mirrored no
    inherit  RS_FrostLong (via RS_FrostLong2) -- same chain as IceWeave
    profile  MakeVolley(proj:"RS_FrostLong2", count:7, arc:360,
                        pitchJitter:20, profName:"Frost Burst")
    notes    CMF_OFFSETPITCH with random(-25,-5) throws all seven UPWARD
             relative to the ball's flight, so they fountain rather than
             spray flat -- pitchJitter alone does not capture the bias.
             This is the spec's named example of an impact that is itself an
             attack. Worth noting the arithmetic: one Missile2 beat can put
             2 balls + 14 shards in the air, i.e. 16 hits from 2 shots.

---

# TIER 9 — RS_AbyssImp2

`zscript/monsters/imp/RS_Imp.zs:516`. `Melee` falls THROUGH into `Missile`.
`HM` (:584) is a coin-flip router, not a row: 64/256 to HM2, else
`Goto Missile+3` (the ball volley). See spawns cosmetic RS_SplashAbyss only.

    ATTACK   RS_AbyssImp2.Melee
    file     zscript/monsters/imp/RS_Imp.zs:573
    shape    MULTI
    payload  --   (A_CustomMeleeAttack) + RS_SplashAbyss2 x8
    arc      30   (the eight droplets at random(-15,15))
    timing   6,6,5 then the 8 droplets on one tic   (17 tics)
    damage   melee random(16,42); each droplet DamageFunction (random(1,9))
    type     melee untyped; droplets Ice
    sound    "imp/melee" on the claw. The droplets are SILENT --
             RS_SplashAbyss2 inherits RS_SplashAbyss, which sets no SeeSound.
    impact   droplets: BAL7 CDE flash, no explosion, no DeathSound
    trigger  Melee
    range    ..MeleeRange 68 (set explicitly, RS_Imp.zs:553)
    mirrored no
    inherit  RS_SplashAbyss (RS_ZombiemanFX.zs:707). The child adds
             DamageFunction (random(1,9)) + DamageType Ice + -THRUACTORS;
             the PARENT is harmless (no Damage at all). Reading the parent
             and stopping would report this melee's spray as cosmetic. It
             is not.
    profile  MakeMelee(range:68, fireSnd:"imp/melee") then
             MakeVolley(proj:"RS_SplashAbyss2", count:8, arc:30,
                        pitchJitter:20, profName:"Abyss Splash")
             -- a 2-entry pair; no single factory fires a melee and a volley.
    notes    MULTI by convention 2: a melee hit plus a damaging projectile
             class. CMF_OFFSETPITCH random(-25,-5) again throws the droplets
             upward. Falls through into Missile at :575, so a claw is always
             chased by the ball volley or the flood.

    ATTACK   RS_AbyssImp2.Missile
    file     zscript/monsters/imp/RS_Imp.zs:580
    shape    BURST
    payload  RS_AbyssBallCH x3
    arc      18   (shot 1 at random(-1,1); shots 2-3 at random(-9,9))
    timing   shot 1 at t=16, shots 2 and 3 at t=28 and t=29
             (`ROAC GG 1` is TWO frames = TWO shots, one tic apart)
    damage   DamageFunction (random(5,40))
    type     Plasma
    sound    "Roach/Fire" (SeeSound) -- once per shot, 3 plays
    impact   DeathSound "imp/shotx"; A_SetScale(1.2), SEVEN RS_SplashAbyss2
             at random(-180,180) with CMF_OFFSETPITCH random(-25,-5), then
             `RCHB CDE 4 A_Explode(random(1,9),56)` -- THREE frames, so
             three separate explosions. In flight it also sheds
             RS_AbyssShotIdentifier (a cvar-gated marker, harmless) and
             6 RS_SplashAbyss2 per Fly loop.
    trigger  Missile
    range    700..   (A_JumpIfCloser(700,"HM") at :578 diverts closer targets;
                      but HM sends 192/256 of those BACK here via
                      `Goto Missile+3`, so this volley is the common case at
                      every range)
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_AbyssBallCH", count:3, delayTics:6, arc:18,
                       fireSnd:"Roach/Fire", profName:"Abyss Volley")
    notes    The 12-tic gap between shot 1 and shot 2 and the 1-tic gap
             between 2 and 3 is a 1+2 rhythm that a uniform delayTics cannot
             reproduce. delayTics:6 averages it. Recorded, not hidden.
             The in-flight RS_SplashAbyss2 shedding means this ball leaves a
             damaging wake, not just an impact.

    ATTACK   RS_AbyssImp2.HM2
    file     zscript/monsters/imp/RS_Imp.zs:594
    shape    RAIN
    payload  RS_SplashAbyss2 x91   (46 + 45, two waves)
    arc      --   (positional, not angular -- see notes)
    timing   wave 1 at t=27, wave 2 at t=35   (each wave on one tic;
             48-tic total including a 9-tic windup and the lunge)
    damage   DamageFunction (random(1,9))   each
    type     Ice
    sound    --   (SILENT: A_SpawnItemEx plays no SeeSound, and
                   RS_SplashAbyss2 has none anyway)
    impact   BAL7 CDE flash, no explosion. 91 x 1..9 = a carpet, not a hit.
    trigger  Missile   (A_JumpIfCloser(700,"HM") -> A_Jump(64,"HM2"));
                       ALSO Pain (A_Jump(64,"HM2") at RS_Imp.zs:606)
    range    ..700   from Missile; UNGATED from Pain
    mirrored no
    inherit  RS_SplashAbyss (see the Melee row)
    profile  MakeVolley(proj:"RS_SplashAbyss2", count:91, arc:360,
                        pitchJitter:0, profName:"Abyss Flood")
             -- IMPERFECT: MakeVolley spreads by ANGLE, this spreads by
             POSITION. A 91-round 360 ring is not the same picture as a
             carpet laid across a 256x504 footprint. Flagged.
    notes    RAIN chosen as the least-wrong §3 word: these are positionally
             spawned and not aimed. TWO DEVIATIONS from RAIN's definition,
             recorded rather than papered over -- they spawn around the
             SHOOTER (not the target) and they RISE (zvel +2) rather than
             fall. Wave 1 footprint: random(32,256) forward x random(-252,252)
             lateral, z random(6,16). Wave 2: random(-128,328) x
             random(-178,178). The state also LUNGES first --
             ThrustThingZ(0,16) + ThrustThing(angle,42) at :589-590 -- so
             the imp is inside its own carpet. Ends with `Goto Missile`, so
             a flood is always followed by a ball volley.

---

# TIER 8 — RS_GrayImp2 ("Stoned Imp")

`zscript/monsters/imp/RS_Imp.zs:759`. `Melee:` is a bare label immediately
above `Missile:` — **the gray imp has no melee attack at all**, it fires the
nail rings at any range. Pain has a 128/256 jump straight back to Missile.

    ATTACK   RS_GrayImp2.Missile
    file     zscript/monsters/imp/RS_Imp.zs:814
    shape    RING
    payload  RS_CGNail x13   (wave 1 x5, wave 2 x8)
    arc      360
    timing   wave 1 on one tic at t=22; wave 2 on one tic at t=39
             (17 tics apart)
    damage   DamageFunction (random(1,5))   each
    type     Melee   (RS_CGNail's DamageType -- a nail typed as melee)
    sound    --   for the launch. RS_CGNail has no SeeSound. It carries
             AttackSound "moloch/nailhitbleed" (+SPAWNSOUNDSOURCE) and
             DeathSound "weapons/firex4", both on ARRIVAL. The volley
             itself is silent, which on a 13-nail ring is very loud
             silence -- correct for a profile slot, a defect on a monster.
    impact   A_PlaySound("moloch/nailhit"), then
             `6PUF ABCDEF 1 A_Explode(random(1,3),16)` (6 frames = 6
             explosions) + `FBL1 EFG 1 A_Explode(random(1,3),16)` (3 more)
             = NINE A_Explode per nail, then a RS_PuffCybieRed.
             13 nails x 9 = up to 117 explosion ticks per Missile beat.
             +BLOODSPLATTER +EXTREMEDEATH, Decal "BulletChip".
    trigger  Missile   (== Melee); ALSO Pain (A_Jump(128,"Missile") at :848)
    range    --
    mirrored no
    inherit  --   (RS_CGNail is shared, defined at
                   zscript/monsters/chaingunner/RS_ChaingunnerFX.zs:423)
    profile  MakeVolley(proj:"RS_CGNail", count:5, arc:360) THEN
             MakeVolley(proj:"RS_CGNail", count:8, arc:360)
             -- a 2-entry rotation 17 tics apart, not one call.
    notes    THE ANGLES ARE NOT EVENLY SPACED and MakeVolley's even arc will
             not reproduce them. Wave 1: 0, 45, 135, 225, 315 -- note the
             MISSING 90/180/270, gaps of 45,90,90,90,45. Wave 2: 15, 75,
             105, 165, 195, 255, 285, 345 -- eight nails that BRACKET wave
             1's four diagonals (15/75 straddle 45, 105/165 straddle 135,
             etc). The two waves interlock; fired evenly they do not. This
             is CH's exact geometry, verified at CH Imps.txt:906-925.

    ATTACK   RS_GrayImp2.Death
    file     zscript/monsters/imp/RS_Imp.zs:855
    shape    RING
    payload  RS_CGthing3 x1  ->  RS_CGNail x12
    arc      360   (15, 45, 75, 105, 135, 165, 195, 225, 255, 285, 315, 345
                    -- an EVEN 30-degree ring, unlike the Missile waves)
    timing   one tic   (RS_CGthing3 is Speed 0 +NOCLIP and goes straight to
                        Death, so the ring lands on the frame it spawns)
    damage   DamageFunction (random(1,5))   each nail
    type     Melee
    sound    --   (RS_CGthing3 has no SeeSound or DeathSound)
    impact   as the Missile row -- 9 A_Explode per nail
    trigger  Death
    range    --
    mirrored no
    inherit  --   (RS_CGthing3 at RS_ChaingunnerFX.zs:391)
    profile  MakeVolley(proj:"RS_CGNail", count:12, arc:360,
                        profName:"Nail Corpse")
    notes    A corpse bomb: killing a gray imp at close range costs you a
             12-nail even ring. RS_CGthing3 is a pure delivery shell --
             Speed 0, +NOCLIP, Spawn -> Death immediately.

---

# TIER 7 — RS_FireBluImp2 ("Now THATS ugly")

`zscript/monsters/imp/RS_Imp.zs:643`. Subclasses `DoomImp`. `Pain.fire` (:723)
is a shortened pain with no attack.

    ATTACK   RS_FireBluImp2.Melee
    file     zscript/monsters/imp/RS_Imp.zs:692
    shape    MELEE
    payload  --
    arc      --
    timing   8,8,6   (22 tics)
    damage   random(10,29)
    type     --
    sound    "imp/melee"
    impact   --
    trigger  Melee
    range    ..MeleeRange 64 (set explicitly, RS_Imp.zs:675)
    mirrored no
    inherit  --
    profile  MakeMelee(range:64, fireSnd:"imp/melee")
    notes    --

    ATTACK   RS_FireBluImp2.Missile
    file     zscript/monsters/imp/RS_Imp.zs:697
    shape    MULTI
    payload  RS_RedBBall x1 + RS_BluBBall x1
    arc      6+6   (red at random(-5,1) -- biased LEFT;
                    blue at random(-1,5) -- biased RIGHT. Not symmetric.)
    timing   red at t=14, blue at t=35   (21 tics apart)
    damage   DamageFunction (random(10,50))   both
    type     Plasma   both
    sound    "weapons/firbfi" (SeeSound) -- once per shot
    impact   DeathSound "weapons/hellex"; `ARCB K 3 A_Explode(random(5,20),
             128,0)` -- one explosion, r128, flag 0 = the shooter IS hurt by
             it. In flight, a RS_CrackoBallTrail per Fly loop.
    trigger  Missile
    range    --
    mirrored no   (the two shots lean OPPOSITE ways by design, but that is
                   two payloads, not a mirror of one attack)
    inherit  RS_BluBBall : RS_RedBBall (RS_ImpFX.zs:476) -- a ONE-LINE
             subclass that changes ONLY Translation "0:255=196:207".
             Identical Speed 25, damage random(10,50), DamageType Plasma,
             SeeSound, DeathSound, A_Explode, DontHurtShooter true,
             Species "BaronOfHell", +DONTHARMCLASS/+DONTHARMSPECIES.
             THE TWO SHOTS ARE THE SAME PROJECTILE IN TWO COLOURS.
    profile  MakeBurst(proj:"RS_RedBBall", count:1, delayTics:0, arc:6) THEN
             MakeBurst(proj:"RS_BluBBall", count:1, delayTics:0, arc:6)
             -- a 2-entry alternation 21 tics apart.
    notes    MULTI by convention 2 (two damaging classes) even though they
             are mechanically identical -- the classes ARE different and the
             parts bin should see both. `A_CheckSight("See")` at :698 aborts
             the blue shot if the target breaks LOS, so the second half is
             not guaranteed. `DontHurtShooter true` is the property form
             (CLAUDE.md); the A_Explode flag 0 does NOT protect the shooter,
             so those two interact -- the direct hit spares the firer, the
             blast does not.

    ATTACK   RS_FireBluImp2.XDeath
    file     zscript/monsters/imp/RS_Imp.zs:741
    shape    RING
    payload  RS_FireSGguy2 x12   (10 ringed + 2 aimed at +/-7)
    arc      360   (random(-359,359) on the ten -- the tell)
    timing   A_Explode at t=0, the 12 flames at t=12   (18-tic total)
    damage   A_Explode(random(12,44), r84) at the corpse;
             each flame DamageFunction (random(5,15))
    type     corpse blast untyped; flames Fire
    sound    "weapons/rocklx" at t=0 (channel 7, volume 1);
             "imp/attack" x2 -- only the TWO A_CustomMissile flames
             (RS_Imp.zs:746, :747) play a SeeSound. The ten A_SpawnItemEx
             flames are silent.
    impact   per flame: DeathSound "imp/shotx", then
             `FIRE CDEEDCDE 5 A_Explode(random(3,9),64)` (EIGHT frames =
             eight explosions) + `FIRE FGH 4 A_Explode(random(5,15),64)`
             (three more) = ELEVEN A_Explode per flame. 12 flames = up to
             132 explosion ticks off one corpse.
    trigger  XDeath
    range    --
    mirrored no
    inherit  --   (RS_FireSGguy2 at RS_ZombiemanFX.zs:785)
    profile  MakeVolley(proj:"RS_FireSGguy2", count:12, arc:360,
                        fireSnd:"weapons/rocklx", profName:"Fireblu Cook-off")
    notes    RING not MULTI -- one payload class; the A_Explode is not a
             class. Also A_Quake(20,12,0,64,0) at :742. The ten spawned
             flames get forward vel random(3,9) and zvel 1, so they crawl
             outward at ankle height. The two aimed ones fly at Speed 17.
             The `ZOMG T` carriers at :746-747 are 0-tic and deliberately
             held (see the file header) -- animation, stripped per spec §4.

---

# TIER 1 — RS_CommonImp

`zscript/monsters/imp/RS_Imp.zs:872`. Subclasses `DoomImp`. `Melee:` is a bare
label above `Missile:` — one attack covers both. `Grow` (:950) promotes to
RS_GreenImp on resurrection with RS_GrowRaisin: **not an attack**.

    ATTACK   RS_CommonImp.Missile
    file     zscript/monsters/imp/RS_Imp.zs:903
    shape    COMBO
    payload  RS_DoomImpBall2 x1   (far)  |  -- (near, a claw)
    arc      --
    timing   8,8,6   (22 tics; the attack resolves on the third beat)
    damage   near: random(1,8)*3  -> 3..24
             far:  Damage 3, engine-rolled 3 x random(1,8)  -> 3..24
    type     near untyped; far Fire
    sound    near "imp/melee"; far "imp/attack" (RS_DoomImpBall2 SeeSound)
    impact   DeathSound "imp/shotx", BAL1 CDE flash. No A_Explode -- the
             ONLY imp projectile in the family with a purely cosmetic impact.
    trigger  Missile   (== Melee)
    range    ..MeleeRange for the claw branch, else unlimited
    mirrored no
    inherit  --   (but RS_DoomImpBall2 `replaces DoomImpBall`, RS_ImpFX.zs:582,
                   so A_TroopAttack's hardcoded DoomImpBall resolves to it)
    profile  MakeMelee(range:64, fireSnd:"imp/melee") +
             MakeHeavy(proj:"RS_DoomImpBall2", fireSnd:"imp/attack")
             -- a 2-entry pair; there is no combo factory.
    notes    COMBO by §3 semantics (melee if close, missile if not) even
             though the call is A_TroopAttack, not A_CustomComboAttack.
             Recorded because the word choice is a judgement call.
             THE REPLACEMENT IS THE WHOLE POINT: vanilla A_TroopAttack names
             "DoomImpBall" in engine code, and CH swaps that class out for a
             Fire-typed one globally. Both bands are 3..24, so tier 1 is
             genuinely vanilla-strength -- the only imp in the family that is.

---

# TIER 2 — RS_GreenImp

`zscript/monsters/imp/RS_Imp.zs:961`. `Grow` (:1062) promotes to RS_BlueImp.

    ATTACK   RS_GreenImp.Melee
    file     zscript/monsters/imp/RS_Imp.zs:1003
    shape    MELEE
    payload  --
    arc      --
    timing   8,8,6   (22 tics)
    damage   random(6,16)
    type     --
    sound    "imp/melee"
    impact   --
    trigger  Melee
    range    ..MeleeRange (Actor default 64)
    mirrored no
    inherit  --
    profile  MakeMelee(range:64, fireSnd:"imp/melee")
    notes    Weakest melee in the family.

    ATTACK   RS_GreenImp.Missile
    file     zscript/monsters/imp/RS_Imp.zs:1008
    shape    SINGLE
    payload  RS_GreenIBall x1
    arc      --   (no angle argument -- dead-on)
    timing   8,8,6   (22 tics)
    damage   DamageFunction (random(5,23))
    type     Plasma
    sound    "imp/attack"
    impact   DeathSound "imp/shotx",
             `BAL1 CDE 6 A_Explode(random(1,7),32)` -- THREE frames, three
             explosions, r32.
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeHeavy(proj:"RS_GreenIBall", fireSnd:"imp/attack",
                       profName:"Green Seeker")
    notes    HOMES. +SEEKERMISSILE with A_SeekerMissile(1,1) every Spawn
             frame -- a slow 1-degree-per-frame correction, so it curves
             gently rather than tracking hard. FastSpeed 26 vs Speed 14:
             on -fast/Nightmare it nearly doubles. That doubling is invisible
             in the state code and belongs on any profile built from it.

---

# TIER 3 — RS_BlueImp

`zscript/monsters/imp/RS_Imp.zs:1073`. `Grow` (:1176) promotes to RS_PurpleImp.
XDeath spawns 5 RS_Blutrail1 + "weapons/plasmax" — RS_Blutrail1 is
`+NOINTERACTION` with no Damage: **cosmetic, not an attack**.

    ATTACK   RS_BlueImp.Melee
    file     zscript/monsters/imp/RS_Imp.zs:1118
    shape    MELEE
    payload  --
    arc      --
    timing   8,8,6   (22 tics)
    damage   random(7,19)
    type     --
    sound    "imp/melee"
    impact   --
    trigger  Melee
    range    ..MeleeRange (Actor default 64)
    mirrored no
    inherit  --
    profile  MakeMelee(range:64, fireSnd:"imp/melee")
    notes    --

    ATTACK   RS_BlueImp.Missile
    file     zscript/monsters/imp/RS_Imp.zs:1123
    shape    SINGLE
    payload  RS_Blufier1 x1
    arc      2   (random(-1,1))
    timing   8,8,6   (22 tics)
    damage   DamageFunction (random(17,38))
    type     Plasma
    sound    "imp/attack"
    impact   DeathSound "weapons/plasmax", PLSE CDE flash. NO A_Explode --
             a pure single-target hit.
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeHeavy(proj:"RS_Blufier1", fireSnd:"imp/attack",
                       profName:"Blue Bolt")
    notes    HIGHEST FLOOR IN THE LOW TIERS: 17..38 vs green's 5..23. A
             tier-3 monster whose worst roll beats a tier-2's average. Big
             hitbox too -- Radius 17, Height 15, Scale 1.3, so it is hard
             to dodge. Sheds a RS_Blutrail1 every Spawn frame (cosmetic).

---

# TIER 4 — RS_PurpleImp ("pImp")

`zscript/monsters/imp/RS_Imp.zs:1187`. XDeath spawns RS_CHgold_teeth —
`Damage 0`: **not an attack**.

    ATTACK   RS_PurpleImp.Melee
    file     zscript/monsters/imp/RS_Imp.zs:1235
    shape    MELEE
    payload  --
    arc      --
    timing   8,8,6   (22 tics)
    damage   random(10,29)
    type     --
    sound    "imp/melee"
    impact   --
    trigger  Melee
    range    ..MeleeRange 64 (set explicitly, RS_Imp.zs:1218)
    mirrored no
    inherit  --
    profile  MakeMelee(range:64, fireSnd:"imp/melee")
    notes    --

    ATTACK   RS_PurpleImp.Missile
    file     zscript/monsters/imp/RS_Imp.zs:1240
    shape    BURST
    payload  RS_Bounc11 x2
    arc      2 then 18   (random(-1,1), then random(-9,9))
    timing   shot 1 at t=16, shot 2 at t=39   (23 tics apart)
    damage   DamageFunction (random(5,35))
    type     Fire
    sound    "imp/attack" per shot
    impact   see the SECONDARY row -- this projectile detonates on every
             BOUNCE, not only on death.
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_Bounc11", count:2, delayTics:23, arc:18,
                       fireSnd:"imp/attack", profName:"Bouncing Bomb")
    notes    `A_CheckSight("See")` at :1241 aborts shot 2 on LOS break.
             The second shot's cone is 9x wider than the first -- a
             deliberate aimed-then-sprayed pair, not two identical rounds.

    ATTACK   RS_PurpleImp.Missile2
    file     zscript/monsters/imp/RS_Imp.zs:1248
    shape    BURST
    payload  RS_Bounc11 x2
    arc      26   (random(-13,13), the widest cone this projectile gets)
    timing   shot 1 at t=18, shot 2 at t=20   (2 tics apart; 22-tic total)
    damage   DamageFunction (random(5,35))
    type     Fire
    sound    "imp/attack" x2
    impact   as above -- see the SECONDARY row
    trigger  Pain   (via Pain.fire, A_Jump(64,"Missile2") at RS_Imp.zs:1275)
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_Bounc11", count:2, delayTics:2, arc:26,
                       fireSnd:"imp/attack", trigger:RS_FIRE_PAIN,
                       profName:"Scorched Retort")
    notes    **NOT AIMED AT THE TARGET.** `A_FaceMovementDirection` at
             RS_Imp.zs:1247 turns the imp to face where it is MOVING, then
             fires. A profile that aims at the player reproduces the wrong
             attack. This is the only attack in the family that does this.
             Reachable ONLY by taking Fire damage (Pain.fire), so it is a
             fire-retaliation, not a general pain response. `TROO GG 2` is
             two frames = two shots.

    ATTACK   RS_Bounc11.Bounce                [SECONDARY]
    file     zscript/monsters/imp/RS_ImpFX.zs:720
    shape    SINGLE
    payload  --   (A_Explode, no projectile)
    arc      --
    timing   2,2 per bounce, up to 4 bounces
    damage   A_Explode(15, r25) x2 per bounce (`BAL1 CD 2` is TWO frames)
             -> up to 8 blasts of a flat 15 before it ever lands;
             then Death `BAL1 CDE 3 A_Explode(random(2,10),42)` x3 frames
    type     Fire
    sound    BounceSound "Bomb/bounce" per bounce;
             DeathSound "weapons/plasmax"
    impact   in flight it also sheds RS_Bounc22 sparks every Spawn frame
             (DamageFunction random(1,3), tiny, Scale 0.2)
    trigger  Death   (and Bounce -- the engine's USEBOUNCESTATE path)
    range    --
    mirrored no
    inherit  RS_WimpBall5 (RS_ImpFX.zs:1271) INHERITS THIS whole behaviour
             from RS_Bounc11 with BounceCount cut 4 -> 1 and Scale 0.8.
             The Imp Master's fifth colour ball is a purple imp bomb.
    profile  MakeHeavy(proj:"RS_Bounc11", fireSnd:"imp/attack",
                       profName:"Bouncing Bomb")
             -- the bounce chain is inside the projectile class; no profile
             field expresses it. It comes along with the class for free.
    notes    A FLAT 15, NOT A ROLL, on the bounce -- and it is a roll
             (random(2,10)) on death. The asymmetry is CH's, verified at
             CH Imps.txt:1479-1512. Do not "harmonise" them.
             BounceType "Hexen", BounceFactor 0.7, WallBounceFactor 0.7,
             BounceCount 4. Worst case one bomb delivers 8x15 + 3x(2..10)
             = 150 damage before the direct hit is even counted.

---

# TIER 5 — RS_YellowImp ("Orange Imp")

`zscript/monsters/imp/RS_Imp.zs:1308`. `Melee` falls THROUGH into `Missile`.
`Dodger` (:1360) is a fast-chase variant, not an attack. XDeath spawns a
vanilla `ArchvileFire` (:1424) — with no vile attached it deals no damage:
**not an attack**, see UNRESOLVED.

    ATTACK   RS_YellowImp.Melee
    file     zscript/monsters/imp/RS_Imp.zs:1369
    shape    MELEE
    payload  --
    arc      --
    timing   8,8,6   (22 tics)
    damage   random(10,32)
    type     --
    sound    "imp/melee"
    impact   --
    trigger  Melee
    range    ..MeleeRange 68 (set explicitly, RS_Imp.zs:1344)
    mirrored no
    inherit  --
    profile  MakeMelee(range:68, fireSnd:"imp/melee")
    notes    Falls through into Missile at :1370.

    ATTACK   RS_YellowImp.Missile
    file     zscript/monsters/imp/RS_Imp.zs:1373
    shape    SINGLE
    payload  RS_SpitFireImp x1
    arc      2   (random(-1,1))
    timing   8,8,6   (22 tics)
    damage   DamageFunction (random(2,42))
    type     Fire
    sound    "Imp/Attack"
    impact   DeathSound "Fire/fire5"; `BBOM ABC 2 A_SetScale(0.7)` then
             `BBOM DEFG 3 A_Explode(random(2,13),64)` -- FOUR frames, four
             explosions, r64.
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeHeavy(proj:"RS_SpitFireImp", fireSnd:"Imp/Attack",
                       profName:"Fire Spit")
    notes    WIDEST SPREAD IN THE FAMILY: 2..42, a 21x ratio. Some hits are
             a scratch, some are half a tier-1 imp's health. That variance
             IS the identity -- never flatten it.

    ATTACK   RS_YellowImp.Firey
    file     zscript/monsters/imp/RS_Imp.zs:1402
    shape    SINGLE
    payload  RS_Firespe1 x1
    arc      720   (random(-360,360) -- completely undirected; see notes)
    timing   5,6   (11 tics)
    damage   --   the ember itself has NO Damage property and is not
                  Projectile-flagged, so contact does nothing. ALL the
                  damage is in its Death -- see the SECONDARY row.
    type     Fire
    sound    "Fire/fire1" (SeeSound)
    impact   see the SECONDARY row below
    trigger  Pain   (A_Jump(64,"Firey") at RS_Imp.zs:1395)
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_Firespe1", count:1, arc:360,
                        fireSnd:"Fire/fire1", profName:"Panic Ember")
    notes    SINGLE, not RING -- one projectile. But its angle is
             random(-360,360), i.e. uniformly anywhere, so it is a single
             shot with NO aim at all. arc 720 is written literally because
             that is the argument; the effective spread is a full circle.
             +TOUCHY (dies on contact with anything), Gravity 0.4,
             BounceType "Heretic", and its Spawn rolls A_Jump(84,"Death")
             every 4 tics -- so it self-detonates within roughly 12 tics
             whether it hits anything or not. It is a fire-field seeder
             lobbed in a random direction, not a shot.

    ATTACK   RS_Firespe1.Death               [SECONDARY]
    file     zscript/monsters/imp/RS_ImpFX.zs:316
    shape    SCATTER
    payload  RS_Firespe2 x6
    arc      --   (positional: random(-32,32) x random(-32,32) around the
                   ember, z 2)
    timing   A_Explode at t=5; the six flames at t=9, all on one tic
    damage   A_Explode(7, r64) -- a FLAT 7, not a roll;
             then each RS_Firespe2 does A_Explode(random(1,2),41) on
             EVERY FRAME of a 6-frame loop it can repeat several times
    type     Fire
    sound    --   (no DeathSound on RS_Firespe1)
    impact   RS_Firespe2 is the lingering fire: Gravity 1.5, +SLIDESONWALLS,
             `FLUM FGHIJK 3 A_Explode(random(1,2),41)` = 6 explosions per
             loop, then a 32/256 branch to A1 (which explodes 6 more times
             AND shoves itself with ThrustThing three times, so it crawls),
             and only a 14/256-then-20/256 chance to expire. A single flame
             routinely lands 20-40 A_Explode calls before it fades.
    trigger  Death   (of the payload)
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_Firespe2", count:6, arc:360,
                        profName:"Fire Field")
    notes    THIS IS THE REAL ATTACK. Reading Firey alone reports "one
             harmless ember". One Pain beat plants a six-flame crawling fire
             field that keeps ticking for hundreds of tics. The multi-frame
             A_Explode here is DELIBERATE (it is on the project's known
             lingering-fire list) and must not be converted to a single call.

---

# TIER 6 — RS_RedImp

`zscript/monsters/imp/RS_Imp.zs:1438`. `Melee` falls THROUGH into `Missile`.

    ATTACK   RS_RedImp.Melee
    file     zscript/monsters/imp/RS_Imp.zs:1488
    shape    MELEE
    payload  --
    arc      --
    timing   8,8,6   (22 tics)
    damage   random(10,38)
    type     --
    sound    "imp/melee"
    impact   --
    trigger  Melee
    range    ..MeleeRange (Actor default 64)
    mirrored no
    inherit  --
    profile  MakeMelee(range:64, fireSnd:"imp/melee")
    notes    Monster carries DamageFactor "Melee", 2 -- it takes DOUBLE from
             melee. Falls through into Missile at :1489.

    ATTACK   RS_RedImp.Missile
    file     zscript/monsters/imp/RS_Imp.zs:1493
    shape    SALVO
    payload  RS_RedMessImp2 x5
    arc      0   (ALL FIVE at angle 0 -- the spread is SPATIAL, not angular)
    timing   one tic   (all five on the same 0-tic frame run, at t=11)
    damage   DamageFunction (random(2,19))   each
    type     Fire
    sound    "imp/attack" x5 -- five plays on one tic
    impact   DeathSound "weapons/firex4"; `BAL1 CDE 1 A_SetTranslucent(0.35)`
             -- a fade, NO explosion. All the damage is the direct hit.
    trigger  Missile
    range    --
    mirrored no
    inherit  --   (RS_RedMessImp2 at RS_ShotgunnerFX.zs:313)
    profile  MakeVolley(proj:"RS_RedMessImp2", count:5, arc:0,
                        fireSnd:"imp/attack", profName:"Red Swarm")
    notes    THE FIVE MUZZLE POINTS ARE THE SHAPE. Spawn heights and lateral
             offsets are (32,12), (32,4), (32,20), (22,12), (42,12) -- a
             plus-sign of launch points, all aimed dead-on. Because every
             round is +SEEKERMISSILE (A_SeekerMissile(3,5) every frame) plus
             A_Weave(1,1,2,1), they immediately diverge and re-converge on
             the target: five weaving homing rounds from one salvo. A
             factory that only sets count and arc gets a shotgun blast, not
             a swarm. Each round also drops a RS_RedMessImp cosmetic mote at
             random(-180,180) every Spawn loop.

    ATTACK   RS_RedImp.Pain
    file     zscript/monsters/imp/RS_Imp.zs:1518
    shape    UNCLASSIFIED
    payload  --
    arc      --
    timing   3,3,3,2,2,2   (15 tics)
    damage   --   (this attack does no damage; it changes the monster)
    type     --
    sound    "imp/pain" (an EXTRA play at :1520, on top of A_Pain's own)
    impact   --
    trigger  Pain
    range    --
    mirrored no
    inherit  --
    profile  MakeSelfBuff(speedMult:1.4, damageMult:1.0, duration:0,
                          noPain:true, fireSnd:"imp/pain",
                          profName:"Enrage")
    notes    PERMANENT, NOT TIMED. Sets bNOPAIN = true, bMISSILEEVENMORE =
             true and A_SetSpeed(14) (from Speed 10, so x1.4) and NEVER
             REVERTS. `duration:0` is written deliberately -- MakeSelfBuff's
             duration field cannot say "forever", and writing a number here
             would be a lie. Once hurt, a red imp is permanently faster,
             flinchless and firing far more often. UNCLASSIFIED because §3
             has no word for a self-buff; MakeSelfBuff is the factory that
             exists for it, so the row is buildable even though the shape is
             not nameable.

    ATTACK   RS_RedImp.Death
    file     zscript/monsters/imp/RS_Imp.zs:1529
    shape    SINGLE
    payload  RS_HKRedDeath x1
    arc      --
    timing   one tic, at t=0 of Death
    damage   A_Explode(random(5,10), r42) once
    type     Fire
    sound    "world/barrelx" x2 (once in Spawn at RS_ZombiemanFX.zs:859,
             once at :863) + DeathSound "world/barrelx"
    impact   `MISL D 3 A_Burst("RS_RedThingsHK")` -- harmless red debris
    trigger  Death
    range    --
    mirrored no
    inherit  --   (RS_HKRedDeath at RS_ZombiemanFX.zs:844)
    profile  MakeHeavy(proj:"RS_HKRedDeath", fireSnd:"world/barrelx",
                       profName:"Red Corpse Pop")
    notes    A barrel, essentially. +DONTGIB +NOGRAVITY, Height 42.

    ATTACK   RS_RedImp.XDeath
    file     zscript/monsters/imp/RS_Imp.zs:1539
    shape    SCATTER
    payload  RS_HKRedDeath x4
    arc      30   (one at 0; three at random(-15,15))
    timing   t=0 (one), then t=25, t=30, t=35 (`PRIM RST 5` = THREE frames,
             three more) -- 40-tic total
    damage   A_Explode(random(5,10), r42)   per pop, so 4 pops
    type     Fire
    sound    "world/barrelx" per pop
    impact   red debris per pop
    trigger  XDeath
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_HKRedDeath", count:4, delayTics:8, arc:30,
                       fireSnd:"world/barrelx", trigger:RS_FIRE_XDEATH,
                       profName:"Red Chain Pop")
    notes    Gibbing a red imp costs FOUR blasts, not one -- the three extra
             also get random spawn heights random(12,46), so they pop at
             ankle and head height. `PRIM RST 5 A_CustomMissile(...)` looks
             like one line and is three calls.

---

# TIER 10 — RS_BlackImpEX ("Smoking Black Imp EX")

`zscript/monsters/imp/RS_Imp.zs:1557`. Health 8600, `+BOSS`. `Melee:` is a bare
label above `Missile:` — **the EX has no melee**; it runs the ranged routine at
any range. Missile routes: `A_JumpIfCloser(1300,"Choice")` → 5-way; else a
2-way (`Kamehameha`, `SmokeOut`) only.

    ATTACK   RS_BlackImpEX.Kamehameha
    file     zscript/monsters/imp/RS_Imp.zs:1654
    shape    HITSCAN
    payload  RS_BlackImpBeam1 (puff) + RS_BlackImpBeam2 (trail spawnclass,
             one every 0.4 units of the trace)
    arc      --   (a rail trace; spread_xy 0, spread_z 0)
    timing   2,2,18,8 windup then the shot at t=30, then 16 tics recovery
             (48-tic total)
    damage   random(20,80)   on the rail itself
    type     --   on the rail; RS_BlackImpBeam2 carries Fire,
                  RS_BlackImpBeam1 carries Plasma
    sound    "agaures/sight" at channel 7, volume 2, **ATTN_NONE** --
             audible across the entire map. The telegraph is global.
    impact   the trail is the attack: see the SECONDARY row
    trigger  Missile   (2-way at any range, 5-way inside 1300)
    range    --   (available at ALL ranges; the only two that are)
    mirrored no
    inherit  --
    profile  MakeHitscan(fireSnd:"agaures/sight", spreadScale:0.0,
                         impactPuff:"RS_BlackImpBeam1",
                         profName:"Kamehameha")
             -- IMPERFECT: MakeHitscan has no field for a spawnclass laid
             along the trace, which is where nearly all the damage is.
    notes    Full call: A_CustomRailgun(random(20,80), -20, "white", "white",
             RGF_NOPIERCING, 0, 0, "RS_BlackImpBeam1", 0, 0, 0, 0, 0.4, 1.0,
             "RS_BlackImpBeam2", 1). Read positionally: sparsity 0.4,
             driftspeed 1.0, spawnclass RS_BlackImpBeam2, spawnofs_z 1.
             RGF_NOPIERCING = it stops at the first thing it hits.
             30-tic windup with two RS_BlackImpEXcharge orbs (cosmetic) at
             +/-32 lateral -- the animation tell.

    ATTACK   RS_BlackImpBeam2.Fly            [SECONDARY]
    file     zscript/monsters/imp/RS_ImpFX.zs:864
    shape    SINGLE
    payload  --   (A_Explode from a stationary trail segment)
    arc      --
    timing   explosions at t=6, t=12, t=18, t=24 of each segment's life
    damage   DamageFunction (random(10,20)) on contact, PLUS
             A_Explode(random(5,30), r64, 0) x4 -- FOUR separate calls at
             RS_ImpFX.zs:864, :867, :870, :873
    type     Fire
    sound    --
    impact   ends by spawning 2 RS_DeathBreathDI
    trigger  Spawn   (of the payload -- it detonates where the rail put it)
    range    --
    mirrored no
    inherit  --
    profile  MakeHeavy(proj:"RS_BlackImpBeam2", profName:"Beam Segment")
    notes    THE RAIL'S 20..80 IS THE SMALL HALF. sparsity 0.4 means a
             segment every 0.4 map units along the trace, and each one
             delivers four r64 blasts of 5..30. A trace of even 100 units
             lays 250 segments. This is the single most dangerous thing in
             the imp family and it is invisible from the attack site --
             the monster line only names the class. Flag: the exact live
             segment count is engine-side (A_CustomRailgun's sparsity
             behaviour) and was not measured in-game; see UNRESOLVED.
             The puff RS_BlackImpBeam1 (RS_ImpFX.zs:813) separately does
             A_Explode(random(2,20),128) x5 frames + 14 RS_DeathBreathDI.

    ATTACK   RS_BlackImpEX.SmokeOut
    file     zscript/monsters/imp/RS_Imp.zs:1663
    shape    RAIN
    payload  RS_CHBSTarget x1 (telegraph, harmless) then
             RS_BlackImpSmokeOut x1  ->  RS_DeathBreathDI, continuously
    arc      --   (placed AT the target, not aimed)
    timing   marker at t=5; smoke at t=32   (27 tics of warning);
             55-tic total
    damage   the smoke itself does none; RS_DeathBreathDI is
             `Damage 1` -> engine-rolled 1 x random(1,8) -> 1..8, and it
             fires A_Explode(random(0,2),42) or (random(1,2),42) on
             TWENTY-SIX separate frames before dying
    type     DIMp
    sound    "Fire/fire3" (RS_BlackImpSmokeOut SeeSound); the marker plays
             "prox/beep" at ATTN_NONE three times -- a global countdown
    impact   RS_BlackImpSmokeOut is +FLOORHUGGER +NOINTERACTION and spawns
             RS_DeathBreathDI on 40 of its 52 frames. It floods the floor
             where the player was standing.
    trigger  Missile
    range    --   (available at all ranges)
    mirrored no
    inherit  --
    profile  MakeRadial(radius:64, damage:4, heal:0,
                        fireSnd:"Fire/fire3", profName:"Smoke Out")
             -- IMPERFECT: this is a placed, persistent field, and MakeRadial
             is an instantaneous pulse at the caster. No factory expresses
             "drop a hazard at the target's feet".
    notes    RAIN chosen as the least-wrong §3 word (spawned at/around the
             target, not aimed). DEVIATION: it hugs the FLOOR rather than
             falling from above. A_VileTarget is the delivery -- it places
             the actor at the target's CURRENT position, so moving after the
             beep is the counterplay, and the 27 tics between marker and
             smoke is exactly that window. **THE DAMAGE TYPE IS THE TRAP:**
             DIMp is the type every CH monster carries
             `DamageFactor "DIMp", 0` against, so this hurts the player and
             nothing else -- and RS_DeathBreathDI additionally
             A_RadiusGive("Health",64,...) to RS_BlackImp1 four times, so
             the field HEALS the black imp's kin while it burns you.
             `A_CheckSight("See")` at :1667 can abort before the smoke lands.

    ATTACK   RS_BlackImpEX.OneShot
    file     zscript/monsters/imp/RS_Imp.zs:1674
    shape    SCATTER
    payload  RS_BlackImpEXBall1 x30
    arc      60 -> 30 -> 14 -> 2   (four waves: 12 at random(-30,30),
             9 at random(-15,15), 6 at random(-7,7), 3 at random(-1,1))
    timing   24-tic windup, then 12x1, 9x2, 6x3, 3x4   (60 firing tics,
             84 total)
    damage   DamageFunction (random(5,40))   each
    type     Fire
    sound    "imp/attack" x30
    impact   DeathSound "imp/shotx";
             `BLVB CDEF 2 A_SpawnItemEx("RS_DeathBreathDI",...)` -- FOUR
             frames, so every ball leaves 4 smoke clouds where it lands.
             30 balls = 120 clouds of DIMp damage.
    trigger  Missile   (5-way Choice only)
    range    ..1300
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_BlackImpEXBall1", count:30, delayTics:2,
                       arc:60, fireSnd:"imp/attack", profName:"EX Stream")
             -- IMPERFECT: one arc and one delay cannot express a cone that
             tightens 60->2 while the cadence slows 1->4 tics. That
             inversion IS the attack's character. Four MakeBurst entries in
             rotation is the honest build:
               MakeBurst(count:12, delayTics:1, arc:60)
               MakeBurst(count:9,  delayTics:2, arc:30)
               MakeBurst(count:6,  delayTics:3, arc:14)
               MakeBurst(count:3,  delayTics:4, arc:2)
    notes    THE CONE TIGHTENS AS THE CADENCE SLOWS -- a spray that walks
             onto you. Each ball also rolls A_Jump(255,"A1","A2","A3") on
             spawn to pick a weave direction (+2, -2, or none), so the
             stream braids. WeaveIndexXY 54 is set so they do not all weave
             in phase. A_FaceTarget is re-issued between every wave, so a
             moving target is re-tracked three times mid-stream.

    ATTACK   RS_BlackImpEX.BigShot
    file     zscript/monsters/imp/RS_Imp.zs:1694
    shape    SINGLE
    payload  RS_BlackImpExBigOne x1 + RS_EffectHK x3 (cosmetic)
    arc      --
    timing   12,12 windup, 2,2,2 sparks, 1, then the shot at t=32;
             14 tics recovery (46-tic total)
    damage   DamageFunction (random(50,120))
    type     Plasma
    sound    "Spell/SpellCast1" (SeeSound)
    impact   DeathSound "Fire/Fire4"; 12 RS_DeathBreathDI, A_SetScale(4.0),
             then `SPIR ABCDEDCBA 5 A_Explode(random(5,50),256)` -- NINE
             frames, nine r256 explosions of 5..50. Plus in flight:
             `RED9 B 1 A_Explode(random(4,10),128)` on EVERY loop of a
             2-state Spawn, i.e. it damages continuously as it travels.
    trigger  Missile   (5-way Choice only); also chained from OneShot
                       (A_Jump(24), :1681) and SpamShotRain (A_Jump(24), :1708)
    range    ..1300
    mirrored no
    inherit  --
    profile  MakeHeavy(proj:"RS_BlackImpExBigOne", fireSnd:"Spell/SpellCast1",
                       bigMuzzle:true, spawnHeight:64,
                       profName:"EX Big One")
    notes    SINGLE, not MULTI -- RS_EffectHK does no damage (it is a
             Speed 0 +NOINTERACTION shell whose Death is A_Burst of harmless
             RS_RedThingsHK debris). +SEEKERMISSILE with A_SeekerMissile(2,2)
             at Speed 9: it is slow AND it follows you. Scale 2.35 growing
             to 4.0 on detonation. Two RS_BlackImpEXcharge orbs at +/-32
             during the windup are the tell. Note this is the ONLY attack in
             the family that can be reached from two other attacks.

    ATTACK   RS_BlackImpEX.SpamShotRain
    file     zscript/monsters/imp/RS_Imp.zs:1700
    shape    SCATTER
    payload  RS_BlackImpExBall2 x44
    arc      30 / 20 / 10   (groups at random(-15,15), random(-10,10),
                             random(-5,5), interleaved with random(-15,15))
    timing   16-tic windup, then 5x1, 7x0, 1, 4x2, 11x0, 1, 3x3, 14x0
             (24 firing tics for 44 rounds -- 40 total)
    damage   DamageFunction (random(1,10))   each
    type     Fire
    sound    "imp/attack" x44
    impact   DeathSound "imp/shotx"; A_SetScale(2,2) then
             `BLVB CDEF 4 A_Explode(random(1,8),32)` -- FOUR frames,
             four r32 explosions per round. 44 rounds = 176 blasts.
    trigger  Missile   (5-way Choice only)
    range    ..1300
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_BlackImpExBall2", count:44, delayTics:1,
                       arc:30, fireSnd:"imp/attack",
                       profName:"EX Shot Rain")
    notes    **SPAWN HEIGHT random(70,90)** -- far above the imp's 56-unit
             height. Combined with `-NOGRAVITY` + `Gravity 0.02` the rounds
             arc UP and come DOWN: this is the "rain" in the state name and
             it is entirely in the spawn height, not in any state. A profile
             that spawns at muzzle height reproduces a flat spray.
             Each round is also +SEEKERMISSILE with
             A_SeekerMissile(random(2,8), random(2,10)) -- a RANDOM turn
             rate per frame, so tracking is erratic -- and BounceType
             "Hexen" with BounceFactor 1.25 and BounceCount 4, and its
             Bounce state ThrustThingZ(0,9) so each bounce kicks it upward.
             They keep coming after they land.

    ATTACK   RS_BlackImpEX.Warp
    file     zscript/monsters/imp/RS_Imp.zs:1720
    shape    UNCLASSIFIED
    payload  RS_DeathBreathDI x86   (43 before, 43 after)
    arc      --   (spawned at the imp, zvel random(1,12), random(-359,359))
    timing   10 tics of A_Wander at Speed 99, bracketed by the two
             43-cloud bursts
    damage   the clouds: `Damage 1` -> 1..8 each, DamageType DIMp
    type     DIMp
    sound    --
    impact   each cloud runs 26 A_Explode frames -- see the smoke row below
    trigger  Pain   (A_Jump(64,"Warp") at RS_Imp.zs:1715)
    range    --
    mirrored no
    inherit  --
    profile  MakeSelfBuff(speedMult:5.2, damageMult:1.0, duration:10,
                          noPain:true, profName:"Smoke Warp")
             + MakeVolley(proj:"RS_DeathBreathDI", count:86, arc:360)
    notes    UNCLASSIFIED: an escape that is also an area attack. Speed
             19 -> 99 (x5.2) with bNOPAIN for ten tics of A_Wander, then
             both revert -- this one DOES revert, unlike RS_RedImp.Pain.
             The two 43-cloud bursts mean the imp leaves a wall of damaging
             smoke where it was and arrives inside another one.

    ATTACK   RS_BlackImpEX.See                              [SHARED SITE]
    file     zscript/monsters/imp/RS_Imp.zs:1627
    shape    RAIN
    payload  RS_DeathBreathDI x12 per chase cycle
    arc      --   (positional: xofs -1..-4, yofs random(-18,18),
                   z random(2,32), vel random(1,5), angle random(90,270)
                   -- i.e. BEHIND and BESIDE, never in front)
    timing   3 clouds per quarter-cycle, 4 quarters per See loop (32 tics)
    damage   `Damage 1` -> engine-rolled 1 x random(1,8) -> 1..8 on contact,
             plus per cloud: A_Explode(random(0,2),42) on 5 frames,
             (random(1,2),42) on 5, (random(0,1),42) on 6,
             (random(1,2),42) on 6, (random(0,1),42) on 5, and
             (random(1,2),32) on 2 in Death -- 29 A_Explode calls, r42/r32
    type     DIMp
    sound    --
    impact   A_RadiusGive("Health", 64, RGF_MONSTERS|RGF_EXFILTER, 3 or 5,
             "RS_BlackImp1") FOUR times per cloud -- the smoke HEALS
             black imps in a 64-unit radius while it damages the player
    trigger  Walk
    range    --
    mirrored no
    inherit  --   (RS_DeathBreathDI at RS_ImpFX.zs:1147)
    profile  MakeRadial(radius:42, damage:2, heal:4, hitsAllies:true,
                        profName:"Death Breath")
             -- the closest single call. The persistent-field nature is not
             expressible; MakeVolley(proj:"RS_DeathBreathDI", count:12,
             arc:360) plus this radial is the honest pair.
    notes    ONE ROW, SEVEN SITES, all RS_DeathBreathDI, all the same
             behaviour. Collapsed per spec §1. Sites:
               RS_BlackImpEX.See      RS_Imp.zs:1627, :1630, :1633, :1636  (12)
               RS_BlackImpEX.Missile  RS_Imp.zs:1640                       (3)
               RS_BlackImpEX.Kamehameha RS_Imp.zs:1656                     (3)
               RS_BlackImpEX.SmokeOut RS_Imp.zs:1664, :1665, :1666         (16)
               RS_BlackImpEX.Pain     RS_Imp.zs:1713                       (9)
               RS_BlackImpEX.Death    RS_Imp.zs:1733                       (43)
               RS_BlackImp1.Melee     RS_Imp.zs:1810                       (3)
               RS_BlackImp1.Missile   RS_Imp.zs:1814                       (3)
             THE EX LEAVES A DAMAGING TRAIL JUST BY WALKING and 43 clouds
             when it dies. RS_BlackImp1 does NOT do this on See -- only on
             Melee and Missile. That difference between the two tier-10
             black imps is real and easy to miss.
             DIMp is the type all CH monsters are immune to
             (`DamageFactor "DIMp", 0` on every imp in this file), so this
             is a player-only hazard that doubles as a kin heal.

---

# TIER 10 — RS_BlackImp1 ("Smoking Black Imp")

`zscript/monsters/imp/RS_Imp.zs:1739`. Health 3800, `+BOSS`. The non-EX
variant: no railgun, no smoke-out, no walking smoke trail.

    ATTACK   RS_BlackImp1.Melee
    file     zscript/monsters/imp/RS_Imp.zs:1809
    shape    MELEE
    payload  --   (+ RS_DeathBreathDI x3, see the shared smoke row)
    arc      --
    timing   6,6,6   (18 tics)
    damage   random(20,65)
    type     --
    sound    "agaures/swing" on hit; miss sound the literal string "none".
             MeleeSound "agaures/scratch" is set in Default but
             A_CustomMeleeAttack's own arg wins.
    impact   --
    trigger  Melee
    range    ..MeleeRange (Actor default 64)
    mirrored no
    inherit  --
    profile  MakeMelee(range:64, fireSnd:"agaures/swing",
                       profName:"Agaures Claw")
    notes    Hardest melee in the family (20..65). `A_Jump(88,"Missile")` at
             :1811 -- 88/256 to chain straight into a ranged attack after
             clawing. The EX has no melee at all; this one does.

    ATTACK   RS_BlackImp1.OneShot
    file     zscript/monsters/imp/RS_Imp.zs:1821
    shape    SCATTER
    payload  RS_AgauresBall1 x4
    arc      50   (one dead-on, then random(-15,15), random(-25,25),
                   random(-15,15))
    timing   24-tic windup, shot 1 at t=24, shots 2-4 on one tic at t=30
    damage   DamageFunction (random(5,40))   each
    type     Fire
    sound    "imp/attack" x4
    impact   DeathSound "imp/shotx";
             `BLVB CDEF 2 A_SpawnItemEx("RS_DeathBreathDI",...)` -- FOUR
             frames, four DIMp clouds per ball
    trigger  Missile   (A_Jump(256,"OneShot","SpamShots","BigShot"), :1817)
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_AgauresBall1", count:4, arc:50,
                        fireSnd:"imp/attack", profName:"Agaures Spread")
    notes    **IT CAN LOOP ITSELF.** `A_Jump(128,"OneShot")` at :1825 --
             128/256 to restart the whole state, unbounded; then
             `A_Jump(128,"SpamShots")` at :1826 to chain the other attack.
             Expected repeats are 2, but the tail is long. Each ball also
             rolls A_Jump(24,"Death") every Spawn loop (RS_ImpFX.zs:1090) --
             a ~9% chance per 6 frames of self-detonating in mid-air, so
             the volley thins as it travels. That self-kill is NOT in the
             attack state and is invisible from the monster file.

    ATTACK   RS_BlackImp1.BigShot
    file     zscript/monsters/imp/RS_Imp.zs:1833
    shape    SINGLE
    payload  RS_DIBigOne x1 + RS_EffectHK x3 (cosmetic)
    arc      --
    timing   12,12 windup, 2,2,2 sparks, then the shot at t=30;
             14 tics recovery
    damage   DamageFunction (random(40,125))
    type     Plasma
    sound    "Spell/SpellCast1"
    impact   DeathSound "Fire/Fire4"; 4 RS_DeathBreathDI, then
             `SPIR ABCDEDCBA 5 A_Explode(random(5,30),178)` -- NINE frames,
             nine r178 explosions
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeHeavy(proj:"RS_DIBigOne", fireSnd:"Spell/SpellCast1",
                       bigMuzzle:true, spawnHeight:38,
                       profName:"DI Big One")
    notes    **`DamageFunction (random(40,125))` -- THIS IS THE ROLL
             CLAUDE.md NAMES.** It once shipped flattened to `Damage 60` and
             sat wrong through three lanes. It is a roll here
             (RS_ImpFX.zs:1045) and must stay one. Recorded verbatim.
             Speed 7 -- the slowest projectile in the family, and it does
             not seek. It is meant to be walked around; the danger is what
             it does on the way (see the SECONDARY row).

    ATTACK   RS_DIBigOne.Spawn                [SECONDARY]
    file     zscript/monsters/imp/RS_ImpFX.zs:1056
    shape    MULTI
    payload  RS_SpiralSaw5 x2 + RS_GroundRedCyb x1 + RS_AgauresBall1 x1
             -- PER LOOP of a 5-state Spawn, continuously, for the whole
             flight
    arc      360   (the AgauresBall1 at CMF_AIMOFFSET random(0,360)
                    horizontal and vertical)
    timing   one full loop is 3 tics; at Speed 7 a 500-unit flight is
             ~70 tics = ~23 loops
    damage   per loop: A_Explode(random(4,10), r128) once (RS_ImpFX.zs:1059);
             RS_SpiralSaw5 does A_Explode(random(2,10),88) on 5 frames each,
             so 10 more; RS_GroundRedCyb does A_Explode(random(2,10),128)
             on 6 frames; RS_AgauresBall1 is a live random(5,40) Fire round
    type     Plasma (the parent), Fire (GroundRedCyb / AgauresBall1),
             Plasma (SpiralSaw5)
    sound    "imp/attack" per shed AgauresBall1
    impact   RS_GroundRedCyb is +FLOORHUGGER +BOUNCEONWALLS with
             BounceCount 999 and WallBounceFactor 1.5 -- it ricochets
             around the room getting FASTER, exploding six times as it goes
    trigger  Spawn   (of the payload -- this is in-flight behaviour,
                      not impact)
    range    --
    mirrored no
    inherit  --   (RS_SpiralSaw5 and RS_GroundRedCyb at
                   RS_ChaingunnerFX.zs:175 and :197)
    profile  MakeHeavy(proj:"RS_DIBigOne", profName:"DI Big One")
             -- the whole cascade is inside the class. A profile that wears
             RS_DIBigOne gets all of it. That is the point of MakeHeavy
             owning the projectile's own arrival (RS_AttackProfile.zs:136).
    notes    THE BIG ONE IS A MOVING WEAPONS PLATFORM, NOT A SHELL. Over a
             typical flight it lays ~23 r128 blasts along its path, ~46
             r88 saw blasts, ~23 floor-hugging ricochets, and ~23 live
             homing fire rounds -- before it ever detonates. Reading the
             BigShot state alone reports "one slow 40..125 projectile",
             which is wrong by an order of magnitude. This is exactly the
             failure mode spec §4 warns about.

    ATTACK   RS_BlackImp1.SpamShots
    file     zscript/monsters/imp/RS_Imp.zs:1839
    shape    BURST
    payload  RS_AgauresBall2 x12
    arc      10 / 0 / 20 / 30   (five groups: (-5,0,5), then three singles
                                 at 0, then (-10,0,10), then (-15,0,15))
    timing   16-tic windup, then group 1 on one tic, +9 tics single,
             +7 single, +3 single, +8 group of 3, +5 group of 3
             (~60-tic total, five distinct volleys)
    damage   DamageFunction (random(5,25))   each
    type     Fire
    sound    "imp/attack" x12
    impact   DeathSound "imp/shotx"; A_SetScale(2,2) then
             `BLVB CDEF 4 A_Explode(random(1,10),64)` -- FOUR frames,
             four r64 explosions per round
    trigger  Missile   (3-way jump at :1817; also chained from OneShot
                        via A_Jump(128,"SpamShots") at :1826)
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_AgauresBall2", count:12, delayTics:5,
                       arc:20, fireSnd:"imp/attack",
                       profName:"Agaures Spam")
             -- IMPERFECT: the real shape is five volleys whose arcs WIDEN
             (10 -> 0 -> 20 -> 30) while the gaps SHORTEN. Honest build is
             a 5-entry rotation:
               MakeVolley(count:3, arc:10)   MakeVolley(count:1, arc:0) x3
               MakeVolley(count:3, arc:20)   MakeVolley(count:3, arc:30)
    notes    Inverse of the EX's OneShot: this one OPENS tight and WIDENS.
             FOUR `A_CheckSight("See")` gates (:1842, :1845, :1848, :1851,
             :1856) -- break line of sight and the sequence aborts at the
             next gate, so it rarely runs to completion in cover.
             The two closing volleys' angles are EXACT (-15, 0, +15 and
             -10, 0, +10), not random -- a real fan, not a scatter.

---

# TIER 11 — RS_WhiteImp2 ("Imp Master")

`zscript/monsters/imp/RS_Imp.zs:2091`. Health 6666, `+BOSS`. No Melee state at
all. `See2` (:2176) is a fast-chase variant, not an attack.

    ATTACK   RS_WhiteImp2.Spawn
    file     zscript/monsters/imp/RS_Imp.zs:2151
    shape    UNCLASSIFIED
    payload  RS_SpecialImp2 x8   (a RandomSpawner -> ghost imps 3..7)
    arc      --   (placed at +/-5 units around the master)
    timing   0,1,0,1,0,1,0,1   (4 tics; before the monster ever sees you)
    damage   --   directly; the ghosts carry their parents' full attack sets
    type     --
    sound    --
    impact   each spawn rolls RS_SpecialImp2's table: SpecialImp4 (green,
             100), SpecialImp3 (blue, 80), SpecialImp5 (purple, 60),
             SpecialImp6 (yellow, 40), SpecialImp7 (red, 20). All are
             Health 80, `+NOCLIP`, `-COUNTKILL`, RenderStyle Add, and warp
             back to the master with A_Warp when >800 units away.
    trigger  Spawn
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_SpecialImp2", count:8, cap:8,
                        tierOffset:-6, profName:"Imp Guard")
    notes    UNCLASSIFIED: §3 has no summon word; MakeSummon is the factory
             that exists for it. NOT capped in CH -- MakeSummon's cap is a
             live-pack cap this attack does not have; `cap:8` is this
             catalog's reading of intent, not a value read off the state.
             Flagged. tierOffset -6 is derived from the tier tokens: the
             master is `RS_Zom.SetTier(self, 11)` and the ghosts are
             `SetTier(self, 0)` (minions carry no tier), so -6 is a guess
             at the SOURCE tier, not a fact. Flagged.

    ATTACK   RS_WhiteImp2.ColorBs
    file     zscript/monsters/imp/RS_Imp.zs:2191
    shape    MULTI
    payload  RS_WimpBall1 x3 + RS_WimpBall2 x3 + RS_WimpBall3 x3 +
             RS_WimpBall4 x3 + RS_WimpBall5 x3   (15 total, cycling 1-5)
    arc      24   (random(-12,12) per round) + random(-12,12) lateral
             spawn offset + random(15,40) spawn height
    timing   1,2,1,2,1,2,1,1,2,1,2,2,1,2,1   (22 firing tics after a
             39-tic windup)
    damage   ball1 random(5,25) | ball2 random(4,32) | ball3 random(2,24) |
             ball4 random(3,31) | ball5 random(5,35)
    type     ball1-4 Plasma; ball5 Fire (it inherits RS_Bounc11)
    sound    "monster/hlnsit" once on the windup (RS_Imp.zs:2189);
             "imp/attack" x15 from the balls
    impact   ball1: `BAL1 CDE 6 A_Explode(random(1,7),32)` x3 frames
             ball2: PLSE CDE flash, NO explosion
             ball3: `BAL1 CDE 6 A_Explode(random(1,12),64)` x3 frames
             ball4: inherits ball1's -> 3x A_Explode(random(1,7),32)
             ball5: inherits RS_Bounc11 -> A_Explode(15,25) x2 on ONE
                    bounce (BounceCount 1) + 3x A_Explode(random(2,10),42)
             FIVE DIFFERENT IMPACTS FROM ONE ATTACK.
    trigger  Missile   (A_Jump(255,"ColorBs","Megaball","Summon"), :2186)
    range    --
    mirrored no
    inherit  RS_WimpBall2/3/4 : RS_WimpBall1 (RS_ImpFX.zs:1213, :1230, :1253)
             -- 2 and 4 override Death/Spawn respectively; 4 also ADDS
             +SEEKERMISSILE. RS_WimpBall5 : RS_Bounc11 (:1271) -- a
             DIFFERENT LINEAGE entirely: it is the purple imp's bouncing
             bomb re-skinned, and it is the only one that is Fire-typed and
             bounces. Reading only RS_WimpBall1's body reports five Plasma
             balls; one of them is not.
    profile  a 5-entry rotation, one per class:
             MakeVolley(proj:"RS_WimpBall1", count:1, arc:24, pitchJitter:13)
             ... same for 2, 3, 4, 5. Fired round-robin, 1-2 tics apart.
    notes    MULTI by convention 2 -- five damaging classes, the family's
             widest. `random(-4,9)` pitch is BIASED UPWARD (9 up vs 4 down),
             so the stream drifts high. The spawn point itself jitters:
             height random(15,40) and lateral random(-12,12) per round, so
             they leave from all over the body. Ends with A_Jump(84) into
             NopeNopeNo2.

    ATTACK   RS_WhiteImp2.Megaball
    file     zscript/monsters/imp/RS_Imp.zs:2221
    shape    MULTI
    payload  RS_HellionBall x1 + RS_Hel2 x1 + RS_SparkPuff1 x30 (cosmetic)
    arc      --   (the two balls at angle 5 and angle 2, near dead-on)
    timing   36 tics of sparks, 10 tics of aim, then both balls at t=52
             and t=58   (60-tic total)
    damage   DamageFunction (random(10,60))   both
    type     Fire   both
    sound    "Monster/hlnatk" x2 (SeeSound)
    impact   DeathSound "Monster/hlnexp"; `HLBL JKLMN 3` flash, NO A_Explode
             -- all the damage is the direct hit. Decal "DoomImpScorch".
             In flight both shed RS_HellionPuff every other frame.
    trigger  Missile
    range    --
    mirrored no
    inherit  RS_Hel2 : RS_HellionBall (RS_ImpFX.zs:1321) -- overrides Spawn
             ONLY, swapping A_SeekerMissile(7,5) for (5,7) and
             A_Weave(1,1,1,10) for (1,1,1,1). Same damage, same sounds,
             same everything else. Two homing rounds with DIFFERENT turn
             biases fired 6 tics apart -- one leads horizontally, the other
             vertically, and they converge from two directions.
    profile  MakeVolley(proj:"RS_HellionBall", count:1, arc:0, pitchJitter:2)
             + MakeVolley(proj:"RS_Hel2", count:1, arc:0, pitchJitter:5)
             -- a 2-entry pair 6 tics apart.
    notes    MULTI by convention 2. THE 30 SPARKS ARE THE TELL AND THE TRAP:
             `A_CustomMissile("RS_SparkPuff1",74,0,CMF_AIMOFFSET,
             random(0,360),random(0,360))` puts **CMF_AIMOFFSET in the ANGLE
             slot (value 4) and random(0,360) in the FLAGS slot** -- so a
             random integer becomes a CMF_* bit field every call.
             **THIS IS CH'S OWN ARG ORDER, CARRIED VERBATIM** (verified
             CH Imps.txt:2892-2901). It is NOT a port error and must not be
             "corrected". Compare NopeNopeNo/NopeNopeNo2 (:2236, :2240),
             which use the sane order. RS_SparkPuff1 is +NOINTERACTION and
             harmless, so the scrambled flags do no damage either way.

    ATTACK   RS_WhiteImp2.Summon
    file     zscript/monsters/imp/RS_Imp.zs:2232
    shape    UNCLASSIFIED
    payload  RS_SpecialImp2 x5 + RS_BaronRing x2 (cosmetic)
    arc      --   (placed at random(-88,88) x random(-88,88), z 6)
    timing   11,9,10,8,6,5 windup, then 5 spawns at 3 tics apart
             (49 + 15 = 64-tic total)
    damage   --   directly
    type     --
    sound    "Fire/fire3" x2 (RS_BaronRing SeeSound); A_Pain x4 plays
             PainSound "monster/hlnpai" four times -- the Imp Master
             screams while summoning
    impact   as the Spawn row -- the RandomSpawner rolls a ghost imp
    trigger  Missile   (3-way at :2186); ALSO Walk (A_Jump(8,"Summon") out
                        of See at RS_Imp.zs:2174 -- it summons while
                        patrolling, before combat)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_SpecialImp2", count:5, cap:8,
                        tierOffset:-6, fireSnd:"monster/hlnpai",
                        profName:"Imp Call")
    notes    UNCLASSIFIED, same reasoning as the Spawn row. `cap:8` and
             `tierOffset:-6` are this catalog's reading, not values in the
             state -- CH caps nothing, so a long fight accumulates ghosts
             without limit. That unboundedness is the finding; the cap is
             the profile layer's addition. Ends with A_Jump(84) into
             NopeNopeNo2.

    ATTACK   RS_WhiteImp2.NopeNopeNo
    file     zscript/monsters/imp/RS_Imp.zs:2237
    shape    RING
    payload  RS_Hel2 x9   (+ RS_SparkPuff1 x9, cosmetic)
    arc      360   (random(0,360) -- the tell)
    timing   9 tics of sparks, then 9 balls one per tic   (18 tics)
    damage   DamageFunction (random(10,60))   each
    type     Fire
    sound    "Monster/hlnatk" x9
    impact   DeathSound "Monster/hlnexp", HLBL JKLMN flash, no explosion
    trigger  Pain   (A_Jump(84,"NopeNopeNo") at RS_Imp.zs:2276)
    range    --
    mirrored no
    inherit  RS_Hel2 : RS_HellionBall -- see the Megaball row
    profile  MakeBurst(proj:"RS_Hel2", count:9, delayTics:1, arc:360,
                       fireSnd:"Monster/hlnatk", trigger:RS_FIRE_PAIN,
                       profName:"Panic Ring")
    notes    RING, not MULTI -- RS_SparkPuff1 does no damage (convention 2).
             NINE HOMING 10..60 ROUNDS IN ALL DIRECTIONS off one pain hit.
             They are +SEEKERMISSILE, so "all directions" resolves back onto
             the player within a second or two. 9 x up to 60 = 540 potential
             damage from being hit once. This is the Imp Master's real
             threat and it lives in a Pain state, not a Missile state --
             exactly the class of attack a `Missile:` name filter drops.
             Here the arg order is the SANE one (angle random(0,360),
             flags CMF_AIMOFFSET) -- compare Megaball.

    ATTACK   RS_WhiteImp2.NopeNopeNo2
    file     zscript/monsters/imp/RS_Imp.zs:2241
    shape    MULTI
    payload  RS_WimpBall1 x6 + RS_WimpBall2 x6 + RS_WimpBall3 x6 +
             RS_WimpBall4 x6 + RS_WimpBall5 x6   (30 total)
             (+ RS_SparkPuff1 x9, cosmetic)
    arc      360   (random(0,360) each -- a full ring)
    timing   9 tics of sparks, then ALL 30 within 1 tic
             (:2241 is `HELN H 1`, :2242-:2270 are all `HELN H 0`)
    damage   ball1 random(5,25) | ball2 random(4,32) | ball3 random(2,24) |
             ball4 random(3,31) | ball5 random(5,35)
    type     ball1-4 Plasma; ball5 Fire
    sound    "imp/attack" x30 on one tic
    impact   five different impacts -- see the ColorBs row
    trigger  Pain   (via ColorBs :2206, Megaball :2223 and Summon :2233,
                     each A_Jump(84,"NopeNopeNo2"); reached from an
                     ATTACK's tail rather than from Pain directly)
    range    --
    mirrored no
    inherit  as the ColorBs row -- ball5 is a RS_Bounc11 descendant
    profile  a 5-entry set fired simultaneously:
             MakeVolley(proj:"RS_WimpBall1", count:6, arc:360) ... x5
    notes    MULTI by convention 2 (five damaging classes); the geometry is
             a full 360 ring of 30 and is recorded in `arc`. **THE FAMILY'S
             LARGEST SINGLE-TIC ATTACK.** Every one of the three Missile
             branches has an 84/256 (~33%) chance of ending in this, so it
             fires roughly every third attack, not rarely. Worst-case
             instantaneous output is 6x(25+32+24+31+35) = 882.
             RS_WimpBall4 is +SEEKERMISSILE and RS_WimpBall5 bounces, so
             the ring does not simply disperse.

---

# SHARED ACROSS THE FAMILY

    ATTACK   RS_CyanImp2.Pain.AbyssPE
    file     zscript/monsters/imp/RS_Imp.zs:484
    shape    RING
    payload  RS_SplashAbyss x94   (two 47-frame runs)
    arc      360   (random(-359,359) -- the tell)
    timing   two bursts on consecutive tics, 40 tics into a 91-tic sequence
    damage   --   **NONE.** RS_SplashAbyss (RS_ZombiemanFX.zs:707) has no
                  Damage property at all. Its DAMAGING sibling
                  RS_SplashAbyss2 is NOT used here.
    type     --
    sound    "AbyssForm" once (RS_Imp.zs:482)
    impact   BAL7 CDE flash per droplet, nothing else
    trigger  Pain
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_SplashAbyss", count:94, arc:360,
                        pitchJitter:8, fireSnd:"AbyssForm",
                        profName:"Abyss Form")
    notes    ONE ROW, NINE IDENTICAL SITES. Byte-identical `Pain.AbyssPE`
             blocks at RS_Imp.zs:478 (CyanImp2), :702 (FireBluImp2), :830
             (GrayImp2), :930 (CommonImp), :1010 (GreenImp), :1125
             (BlueImp), :1250 (PurpleImp), :1375 (YellowImp), :1499
             (RedImp). Collapsed per spec §1.
             IT IS A TRANSFORMATION, NOT A KILL: the state ends by spawning
             RS_AbyssImp2 (tier 9) at :486 and then A_Die -- the imp is
             REPLACED by a tier-9 abyss imp. As a parts-bin entry it is a
             94-piece cosmetic shed, which is a legitimate profile even
             though it does no damage.
             **UNREACHABLE FROM WITHIN THIS FAMILY.** Entry requires taking
             damage of DamageType "AbyssPE", and nothing in RS_Imp.zs or
             RS_ImpFX.zs deals that type. The trigger is outside the imp
             family; whatever deals AbyssPE was not traced. See UNRESOLVED.
             `RS_GrayImp2`'s copy (:830) is the only one that does NOT set
             bNOPAIN -- a one-line divergence, present in CH too
             (CH Imps.txt:923 has no `A_changeflag("Nopain",true)`).

---

# GHOST IMPS — ATTACKS INHERITED, NO NEW ROWS

`RS_SpecialImp3` … `RS_SpecialImp7` (RS_Imp.zs:2052, :2013, :1974, :1935,
:1896) each override **`See` only**. Every Melee, Missile, Pain and Death
attack is inherited verbatim from the parent, so they add no rows:

    RS_SpecialImp7 : RS_RedImp      -> RedImp.Melee, .Missile (SALVO x5),
                                       .Pain (enrage), .Death, .XDeath
    RS_SpecialImp6 : RS_YellowImp   -> YellowImp.Melee, .Missile, .Firey
    RS_SpecialImp5 : RS_PurpleImp   -> PurpleImp.Melee, .Missile, .Missile2
    RS_SpecialImp4 : RS_GreenImp    -> GreenImp.Melee, .Missile
    RS_SpecialImp3 : RS_BlueImp     -> BlueImp.Melee, .Missile

All five are Health 80, `+NOCLIP`, `-COUNTKILL`, `+NOTRIGGER`,
RenderStyle "Add" Alpha 0.95, and warp to their master when >800 units away.
**They keep their parents' full damage rolls at 80 health** — a ghost red imp
fires the same 5-round seeking salvo as a 200-health red imp. Their overridden
`See` states carry no attack.

---

# UNRESOLVED

1. **CH's canonical path in CLAUDE.md and in the spec does not exist.**
   `C:\Users\Command\Desktop\CH` is absent — that Desktop holds `CHP`,
   `elites`, `GlowInTheDark_*` and no `CH`. All CH verification in this file
   was done against `E:\New folder\ART SOURCE\CH\decorate\Imps.txt`, which
   CLAUDE.md separately names as the whole-monster source of truth. If those
   are not the same pack, every "matches CH" claim above is against the wrong
   tree. **The owner should confirm which path is CH.** Not resolved by me.

2. **The spec's worked example names a class that does not exist.** Spec §2
   gives `ATTACK RS_FrostImp.IceWeave` at `RS_Imp.zs:421`. Line 421 is the
   `IceWeave:` label and the class containing it is **`RS_CyanImp2`**. No
   `RS_FrostImp` exists anywhere in `zscript/` (case-insensitive grep). I
   catalogued it as `RS_CyanImp2.IceWeave`. If the other sixteen files are
   keyed to the spec's name, this row will not join.

3. **`file` line convention.** Spec §2 says "line of the first attack line";
   the spec's own example cites the state LABEL (421) not the first attack
   line (424). I followed the written rule. Sixteen other files may have
   followed the example. Mechanical, but it will show up as a diff.

4. **`Pain.AbyssPE`'s trigger was not traced.** Nine imps carry it; entry
   requires `DamageType "AbyssPE"`, and nothing in the imp family deals it.
   I did not search the other sixteen families for the source, because that
   is another agent's tree. Recorded as a dangling inbound edge.

5. **`A_CustomRailgun` sparsity was not measured.** The Kamehameha lays
   `RS_BlackImpBeam2` every 0.4 units along the trace, and each segment does
   four `A_Explode(random(5,30),64)`. I computed segment counts from the
   sparsity argument, not from a running game. The real number depends on
   engine-side rail behaviour (and on whether `RGF_NOPIERCING` truncates the
   trace before the spawnclass loop runs). **The claim "this is the most
   dangerous attack in the family" is a reading, not a measurement.**

6. **`MakeSummon`'s `cap` and `tierOffset` are invented, not read.** CH caps
   the Imp Master's ghost summons at nothing — `Spawn` places 8 and `Summon`
   places 5 more per cast, unbounded. `cap:8` and `tierOffset:-6` in those two
   rows are this catalog's proposal for the profile layer, not values present
   in any state. Flagged so nobody later cites them as CH behaviour.

7. **Four rows have no adequate factory** and say so in their `profile` line:
   `RS_BrownImp2.Scatter` (ally buff in a radius — no ally-buff mode),
   `RS_BrownImp2.Parry` (radial thrust with damage suppressed — no thrust
   axis), `RS_AbyssImp2.HM2` (positional carpet — `MakeVolley` spreads by
   angle), `RS_BlackImpEX.SmokeOut` (a hazard placed at the target — no
   placement mode). These are buildable approximations, not equivalents.
   Whoever builds the factory layer should read those four before adding
   fields.

8. **`RS_YellowImp.XDeath` spawns a vanilla `ArchvileFire`** (RS_Imp.zs:1424)
   and I ruled it NOT an attack, because `ArchvileFire` with no vile attached
   runs `A_Fire` (repositioning only) and deals no damage — the archvile's
   damage is in `A_VileAttack`, which is not called here. If that reading is
   wrong, this is a missing row. Same call for `RS_CyanImp2.Death`'s
   `RS_CH_Cirno` (`Damage 0`), `RS_PurpleImp.XDeath`'s `RS_CHgold_teeth`
   (`Damage 0`), `RS_BlueImp.XDeath`'s `RS_Blutrail1` (`+NOINTERACTION`),
   `RS_BrownImp2`'s `RS_WarlordMace`/`RS_WarlordShield` (no Damage, no
   A_Explode) and `RS_BrownImpShieldMini` (no Damage, so its `A_SkullAttack`
   ram resolves to 0). **All six were opened and confirmed harmless**, but
   they are all things a faster pass would have written down as attacks.

9. **Sound lumps were not verified end-to-end.** This catalog records what
   each attack *names* — `"skeleton/melee"`, `"agaures/swing"`,
   `"moloch/nailhit"`, `"HEALSIEL"`, `"prox/beep"`, `"Ice/Hit2"` and the
   rest. Per CLAUDE.md an unresolved sound name is completely inert, so a
   named sound is not evidence of an audible one. **No `SNDINFO` or `sounds/`
   check was done** — out of scope for an attack catalog, but it means the
   `sound` fields are claims about the code, not about the game.
