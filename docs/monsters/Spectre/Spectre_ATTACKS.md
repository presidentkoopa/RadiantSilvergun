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

# SPECTRE FAMILY -- ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Field order and shape
vocabulary are that spec's, unchanged.

## DENOMINATORS -- what was actually read

    source files       2   zscript/monsters/spectre/RS_Spectre.zs      (1,486 lines)
                           zscript/monsters/spectre/RS_SpectreFX.zs    (  580 lines)
    classes read      38   20 in RS_Spectre.zs + 18 in RS_SpectreFX.zs
    state labels     185   146 + 39, comments stripped before counting
    actors carrying
      attacks         13   (the brief said 10; the three extra are
                           RS_FireBluSpectre2 -- attacks inherited whole from
                           the demons lane -- RS_CommonSpectre, whose Melee is
                           the engine's, and RS_Wakawaka, a summon that lives
                           in the FX file)
    attack rows       33   (34 attack-bearing state chains; Cyan's `HideMe`
                           re-fires the Missile spike ring with identical
                           parameters and collapses into it per spec sec.1)
    call sites            A_CustomMissile 18, A_CustomMeleeAttack 13,
                          A_SkullAttack 3, A_Explode 2, A_RadiusGive 6,
                          ThrustThing 1  (line counts, comments stripped --
                          NOT firing counts; nine of those lines are
                          multi-frame and fire 2-10 times each, see below)
    distinct damaging
      projectiles      8   RS_IceOrbCH2, RS_SpikeCyanRev, RS_ShadowBall,
                           RS_ShadowBall2, RS_SpecSlime1, RS_SpecSlime2,
                           RS_SpecSlime3, RS_RedDemonBloodBolt3
    external classes
      opened           9   RS_SpikeCyanRev, RS_RedDemonBloodBolt3,
                           RS_RedThingsLS (demons lane), RS_EffectHK,
                           RS_BrownImpCommand (imp lane), RS_FireBluDemon2
                           (demons lane), RS_SplashAbyss, RS_ThePlanBoner,
                           RS_GrowRaisin (zombieman lane)
    engine classes
      opened           2   Demon, Spectre (+ A_SargAttack)

CH cross-check: every attack state and every payload Default block below was
diffed against CH `decorate/spectres.txt` (1,721 lines). **No disagreement was
found anywhere in this family's attack paths.** The two departures that exist
are already-recorded, already-authorised ones and are named in UNRESOLVED.

## HOW `shape` WAS ASSIGNED (stated so it can be audited/re-mapped)

The vocabulary is closed and nothing below coins a word. Where an attack has
more than one component the rule used was:

  * `MELEE` / `HITSCAN` / `CHARGE` / `VILE` -- when contact / trace / body
    damage is the WHOLE attack.
  * the projectile-emission geometry (`SINGLE` `FAN` `BURST` `SALVO` `RING`
    `SCATTER`) -- when the attack emits projectiles, even if it also lands a
    bite. The bite is then carried in `payload` / `damage` / `notes`, never
    dropped.
  * `MULTI` -- when two or more DIFFERENT payload classes are emitted.
  * `UNCLASSIFIED` -- summons, radial auras, self-buffs, teleport tooling and
    `A_Explode` bursts. The vocabulary has no word for any of these and per
    the spec none was invented. Six rows.

## ANATOMY STRIPPED FROM EVERY ROW

`SARG` / `WORM` / `SLGM` / `SHDW` / `BPBI` / `TRIT` / `SRG2` / `EWRM` are
spectre animation and contribute only their TIC counts. `TNT1 A 0
A_SpawnItemEx("RS_ColorTierIconCH<n>",...)` appears in almost every state --
it is the tier-badge cosmetic, spawns nothing that flies or damages, and is
not recorded per-row.

## THREE ENGINE FACTS THIS FAMILY DEPENDS ON (read from source, not assumed)

1. **`A_SpawnItemEx` velocity is rotated by `angle + self.Angle`** and the
   spawned actor's own `Angle` is then set to that same direction
   (`wadsrc/static/zscript/actors/attacks.zs:435-547`). So Cyan's four
   quadrant lines really do produce a 360-degree ring relative to facing, and
   the `xvel`/`zvel` numbers are literal map-units-per-tic -- there is no
   `SXF_MULTIPLYSPEED` on any call here, so the payload's own `Speed` is NOT
   applied.
2. **`A_SkullAttack` deals no damage itself.** It sets `bSkullfly` and flies;
   damage happens on collision in `AActor::Slam`, which is
   `GetMissileDamage(7,1)` = `random(1,8) * <the monster's own Damage
   property>`, DamageType `Melee` (`src/playsim/p_mobj.cpp:3358-3374`,
   `src/playsim/p_map.cpp:1553`). An actor with no `Damage` property gets
   **zero**. See RS_BlueSpectre.Rush.
3. **`MeleeThreshold` gates the MISSILE attack, not the melee** --
   `P_CheckMissileRange` returns false while `dist < meleethreshold`
   (`src/playsim/p_enemy.cpp:373`). That is the real source of three `range`
   bands below. `A_CheckSight` / `A_CheckRange` both jump when the actor is
   NOT seen / NO player is in range (`actors/checks.zs:132,142`).

---

# TIER 13 -- RS_BrownSpectre2 ("Brown hide")

    ATTACK   RS_BrownSpectre2.Melee
    file     zscript/monsters/spectre/RS_Spectre.zs:287
    shape    MELEE
    payload  --  (A_CustomMeleeAttack, no projectile)
    arc      --
    timing   12 tics windup (BPBI AB 6), hit on tic 12, 6 tics recovery
    damage   random(1,10) * 8 + random(1,10)   (9..110 -- the widest melee
             roll in the family; it is TWO rolls, do not collapse)
    type     Melee   (4th arg of A_CustomMeleeAttack, explicit)
    sound    "BPinky/Bite" (BPBITE, played on the 0-tic pre-frame,
             RS_Spectre.zs:284) + "Bite/bite4" (BITE4) as the melee sound
    impact   --  (A_CustomMeleeAttack does DamageMobj + TraceBleed directly;
             it spawns no puff and has no impact actor)
    trigger  Melee
    range    ..64   (MeleeRange 64)
    mirrored no
    inherit  --  (own state, Actor base)
    profile  MakeMelee(range:64, fireSnd:"Bite/bite4", profName:"Brown Bite")
    notes    Miss sound is "" (arg 3), so a whiff is silent. DamageType Melee
             matters: Cyan (2.0), Black (2.5) and White (2) all carry
             DamageFactor "Melee", so this bite is amplified against its own
             family.

    ATTACK   RS_BrownSpectre2.Scatter
    file     zscript/monsters/spectre/RS_Spectre.zs:290
    shape    UNCLASSIFIED
    payload  RS_MediCacoBrown x6  (cosmetic heal motes)
             + RS_BrownImpCommand and RS_SpeedBuffPE radius-given as tokens
             + Health 200 radius-given
    arc      --   (motes at random(0,359), but placed by random(-164,164)
             x/y OFFSET, not aimed by angle -- they are decoration on a
             radius effect, not a volley)
    timing   0 tics for all four A_RadiusGive; motes at 3-tic frames over
             tics 0..18; 48 tics total (6+3+3+12+24)
    damage   --   (ZERO damage anywhere in this state -- it is pure support)
    type     --
    sound    "BPinky/Sight" (BPSEE) twice, at the start and at tic 24, both
             on channel 0
    impact   RS_MediCacoBrown (RS_SpectreFX.zs:123) each spawns 4x
             RS_MediCacoBrown2 (:155) then fades -- BAL1 sprites, Add 0.33,
             +THRUACTORS, no damage on either. Cosmetic only.
    trigger  Walk   (See -> A_Jump(16,"CheckFriends") at :273 -> A_CheckSight
             then two A_CheckProximity)
    range    --   (self-centred; gated on an ALLY within 300, not a target)
    mirrored no
    inherit  --
    profile  MakeRadial(radius:1200, damage:0, heal:200, hitsAllies:true,
                        fireSnd:"BPinky/Sight", profName:"Pack Rally")
             -- second component has no single call: MakeSelfBuff(speedMult:
             1.0, ...) cannot express "buff my allies", see UNRESOLVED
    notes    THIS IS TWO RADII, not one. The buff tokens go out at 320 with
             RGF_EXFILTER on "RS_BrownSpectre2" (the marshal excludes itself);
             the 200 Health goes out at 1200 with filter null (it DOES heal
             itself). Each pair is run twice, once for species "Demon1" and
             once for species "Spectre" -- and **the "Spectre" pass matches
             nothing in this family**, because every member that sets a
             species sets "Demon1". Verbatim from CH (spectres.txt:96-99),
             flagged, not fixed.
             RS_SpeedBuffPE (RS_SpectreFX.zs:62) -> RS_PESpeedCtl (:80):
             +10 Speed and forced bALWAYSFAST for 600 tics, skipped on
             bosses, then reverted.
             Entry is gated by A_CheckProximity(...,"Demon"/"Spectre",300,1,
             CPXF_ANCESTOR|CPXF_CHECKSIGHT) at :276-277 -- no allied demon
             within 300 means this attack never fires.

---

# TIER 12 -- RS_CyanSpectre2 ("Ice Worm II")

    ATTACK   RS_CyanSpectre2.Missile
    file     zscript/monsters/spectre/RS_Spectre.zs:413
    shape    RING
    payload  RS_SpikeCyanRev x12
    arc      360   (four lines of 3, quadrants random(0,90) / random(89,180) /
             random(181,270) / random(271,359), relative to facing)
    timing   6 tics of rise (three A_SetScale steps), then ALL 12 ON ONE TIC
             (the spawn frames are TNT1 AAA 0), then 8 tics recovery
    damage   DamageFunction (random(1,3))  per spike -- RS_DemonFX.zs:161
    type     Ice
    sound    --   FIRES SILENT. No A_PlaySound in the state, and
             RS_SpikeCyanRev sets no SeeSound. Correct as a profile slot.
    impact   RIP1 CBA 6 + A_Explode(random(0,1),6) -- and that is a THREE-
             FRAME line, so it explodes 3x (RS_DemonFX.zs:178).
             `DeathSound ""` is set EXPLICITLY -- the spike is deliberately
             silent on arrival, not accidentally.
    trigger  Missile
    range    --   (no MeleeThreshold on this actor)
    mirrored no
    inherit  RS_SpikeCyanRev is the demons lane's class (RS_DemonFX.zs:153,
             CH Revenants.txt:446), referenced not defined here
    profile  MakeVolley(proj:"RS_SpikeCyanRev", count:12, arc:360,
                        pitchJitter:27, profName:"Spike Burrow")
    notes    THE SPIKES ARE LOBBED, NOT FIRED FLAT. Each carries xvel
             random(12,20) and zvel random(15,25) with `-NOGRAVITY` and
             `Gravity 1.5` -- launch elevation ~37..64 degrees up, then they
             rain back down. `pitchJitter:27` above captures the SPREAD; the
             ~50-degree upward CENTRE has no field in RS_AttackProfile (see
             UNRESOLVED). Velocities are literal, not multiplied by the
             payload's Speed 9 -- no SXF_MULTIPLYSPEED.
             Also a SALVO by timing (all 12 on one tic); RING is used because
             the spec names the full-360 spread as the tell.
             THE SAME 12-SPIKE RING FIRES A SECOND TIME at
             RS_Spectre.zs:425-428, in `HideMe` -- identical four lines,
             identical randoms. Not a second row (spec sec.1). HideMe is
             reached from See by A_Jump(64) x2 (:398, :401), from Pain by
             A_Jump(232) (:466), and by FALL-THROUGH from this state when
             both A_JumpIfCloser checks fail. HideMe then flattens to
             YScale 0.1, sprints at Speed 77 for 24 tics of A_Wander, and
             drops back to 25.

    ATTACK   RS_CyanSpectre2.Melee
    file     zscript/monsters/spectre/RS_Spectre.zs:438
    shape    SCATTER
    payload  RS_SpikeCyanRev x20  (+ a contact bite, no projectile class)
    arc      18 outer / 8 inner   (10 at frandom(-9,9) from z+24, then 10 at
             frandom(-4,4) from z+29 -- two nested cones, both from x+16)
    timing   1 tic + 8 tics face; all 20 spikes ON ONE TIC (TNT1 HHHHHHHHHH 0
             x2); bite 4 tics later. 13 tics total.
    damage   spikes DamageFunction (random(1,3)) each;
             bite random(25,75)
    type     spikes Ice; bite untyped (A_CustomMeleeAttack arg 4 omitted ->
             "none")
    sound    "slimeworm/melee" (DSWORMAT) on the bite. The 20-spike spray
             itself is silent.
    impact   spikes as above (3x A_Explode(random(0,1),6), DeathSound "");
             bite has no impact actor
    trigger  Melee
    range    ..72 in practice   (entered from Missile via
             A_JumpIfCloser(72,"Melee") at :418, and from A_Chase at
             MeleeRange 64)
    mirrored no
    inherit  RS_SpikeCyanRev -- see above
    profile  MakeVolley(proj:"RS_SpikeCyanRev", count:20, arc:18,
                        pitchJitter:20, fireSnd:"slimeworm/melee",
                        profName:"Spike Spray")
             + MakeMelee(range:64, dmgMult:1.0) as a second slot entry --
             one profile cannot hold both a volley and a bite
    notes    Second cone is inside the first, not beside it -- a dense core
             (+/-4) inside a wider spray (+/-9). Spikes spawn 16 units
             FORWARD and 24/29 units UP, so they clear the worm's own body.
             zvel random(3,9) / random(4,12) -- a much flatter lob than the
             ring above, near-flat at the low end.

    ATTACK   RS_CyanSpectre2.Hiss
    file     zscript/monsters/spectre/RS_Spectre.zs:444
    shape    CHARGE
    payload  --   (the monster IS the projectile)
    arc      --
    timing   8 tics face (WORM EF 4), then A_SkullAttack(40) on an 8-tic frame
    damage   random(1,8) * 3   (3..24 -- `Damage 3` on the actor,
             RS_Spectre.zs:366, multiplied by the engine's Slam roll)
    type     Melee   (NAME_Melee, hardcoded in AActor::Slam)
    sound    AttackSound "slimeworm/melee" -- A_SkullAttack plays AttackSound
             on CHAN_VOICE itself; there is no A_PlaySound in the state
    impact   --   (the charge ends on contact; no puff, no spawn)
    trigger  Missile   (via A_JumpIfCloser(700,"Hiss") at :419, which is only
             reached when A_JumpIfCloser(72,"Melee") already failed)
    range    72..700
    mirrored no
    inherit  --
    profile  --   NO FACTORY EXPRESSES CHARGE. See UNRESOLVED.
    notes    Skull speed 40 is the fastest charge in the family (Blue and
             Purple use 25, FireBlu 20). +THRUSPECIES and +DONTHARMSPECIES
             mean the ram passes through its own kind.

---

# TIER 11 -- RS_WhiteSpectre2 ("Tentacle monster?")

    ATTACK   RS_WhiteSpectre2.Melee
    file     zscript/monsters/spectre/RS_Spectre.zs:1429
    shape    MELEE
    payload  --
    arc      --
    timing   6 tics of rise (SLGM IJKLMN 1), then **THREE BITES, 4 tics
             apart** -- `SLGM OOO 4` is a three-frame line and
             A_CustomMeleeAttack fires once per frame. 6 tics of retract.
    damage   random(20,50) PER BITE -- 60..150 across the three
    type     Normal   (arg 4 is the literal name "Normal")
    sound    "slgmbite" (SLGMBITE) as BOTH the hit and the miss sound (args 2
             and 3 are the same string), so it is audible either way -- the
             only attack in the family with a miss sound
    impact   --
    trigger  Melee
    range    ..64   (MeleeRange 64)
    mirrored no
    inherit  --
    profile  MakeBurst(proj:null, count:3, delayTics:4,
                       fireSnd:"slgmbite", trigger:RS_FIRE_MELEE,
                       profName:"Slug Chomp")
             -- but MakeBurst is a projectile factory; melee mode has no
             count/delay. See UNRESOLVED.
    notes    Multi-frame action, the case CLAUDE.md records: three separate
             DamageMobj calls, not one. `bleed` is explicitly `true` (arg 5).
             The state also clears NOTARGET and A_UnsetInvulnerable first --
             the slug is INVULNERABLE while burrowed and only becomes
             damageable during an attack or a PeekUp.

    ATTACK   RS_WhiteSpectre2.Atk1
    file     zscript/monsters/spectre/RS_Spectre.zs:1441
    shape    FAN
    payload  RS_SpecSlime1 x3
    arc      14   (+7, -7, 0 -- ordered outside-in, centre last)
    timing   5 tics face, then ALL THREE ON ONE TIC (the first two frames are
             0-tic; the third holds 5), 6 tics of retract
    damage   DamageFunction (random(10,70)) + PoisonDamage 15 per glob
             (RS_SpectreFX.zs:414-415)
    type     --   (no DamageType set -> untyped/normal; the poison is a
             separate PoisonDamage channel with no PoisonDamageType)
    sound    SeeSound "Shadow/attack" (SHDATTAK), played by the projectile on
             spawn, x3. The state itself plays nothing.
    impact   BOGY DEF 4 + 12 green A_SpawnParticle;
             DeathSound "imp/shotx" (vanilla DSFIRXPL).
             ALSO BOUNCES FIRST: +BOUNCEONWALLS, BounceCount 3,
             WallBounceFactor 1 -- these globs ricochet up to three times
             before they are allowed to die.
    trigger  Missile   (one of three, A_Jump(255,"Atk1","Atk2","Atk3") at
             :1438)
    range    300..   (MeleeThreshold 300 blocks all missile attacks inside
             300; +MISSILEMORE makes it fire more often outside that)
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_SpecSlime1", count:3, arc:14,
                        profName:"Slime Trident")
    notes    Even thirds between Atk1/2/3. A_Jump(255) fails 1-in-256 and
             falls through to Atk1, which is the next state, so Atk1 is
             marginally favoured (~33.5% vs ~33.2%).

    ATTACK   RS_WhiteSpectre2.Atk2
    file     zscript/monsters/spectre/RS_Spectre.zs:1448
    shape    SCATTER
    payload  RS_SpecSlime2 x6
    arc      24 max, VARYING PER SHOT: random(-1,1), random(-12,12),
             random(-12,12), random(-1,1), random(-6,6), random(-6,6)
             -- tight, wide, wide, tight, mid, mid
    timing   5 tics face, then fires at t=0,3,5,8,10,13 (deltas 3,2,3,2,3),
             with an A_FaceTarget re-aim slotted in at t=4 and t=9.
             16-tic emission span, 6 tics of retract.
    damage   DamageFunction (random(10,40)) + PoisonDamage 5 per glob
             (RS_SpectreFX.zs:454-455)
    type     --
    sound    SeeSound "Shadow/attack" x6 (per projectile)
    impact   BOGY DEF 4, DeathSound "imp/shotx". No bounce on this one --
             SpecSlime2 is the plain fast glob, Speed 24, Scale 0.4.
    trigger  Missile
    range    300..   (MeleeThreshold 300)
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_SpecSlime2", count:6, delayTics:3, arc:24,
                       profName:"Slime Spray")
    notes    THE RIPPLE IS 3/2/3/2/3 AND BurstDelayTics IS UNIFORM -- exactly
             the Frost Imp problem the spec's worked example names. 3 tics
             gives 18 vs CH's 16. Recorded, not silently rounded.
             The per-shot arc also varies (1/12/12/1/6/6) and VolleyArc is a
             single number; 24 above is the widest pair, so a uniform-arc
             rebuild is LOOSER than CH's for four of the six.
             The two mid-volley A_FaceTarget re-aims mean this tracks a
             strafing player across the burst -- a burst factory fires on a
             frozen angle and will not.

    ATTACK   RS_WhiteSpectre2.Atk3
    file     zscript/monsters/spectre/RS_Spectre.zs:1460
    shape    SINGLE
    payload  RS_SpecSlime3 x1
    arc      --   (no angle arg -- dead on)
    timing   12 tics face (the longest tell in the family), fire, 6 tics
             retract
    damage   DamageFunction (random(10,50))  (RS_SpectreFX.zs:481)
    type     Plasma
    sound    SeeSound "shadowbeast/pr1sight" (BDPS1)
    impact   BDP2 DE 4 + BDP2 FGH 3, DeathSound "shadowbeast/pr1death"
             (BDPD1). **BUT +RIPPER means it does not die on a monster or a
             player** -- it rips through and keeps going; the Death state is
             reached on geometry only.
    trigger  Missile
    range    300..   (MeleeThreshold 300)
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_SpecSlime3", count:1,
                        fireSnd:"shadowbeast/pr1sight",
                        profName:"Ground Ripper")
    notes    THE STRANGEST-SHAPED PAYLOAD IN THE FAMILY, and its shape is
             load-bearing: XScale 0.1, YScale 1.8 -- a tall thin blade --
             plus +FLOORHUGGER (it slides along the floor and cannot rise),
             +SEEKERMISSILE with A_SeekerMissile(5,4)/(3,6)/(12,7) on a 6-tic
             loop (homing that tightens to 12 degrees), and +RIPPER. Radius
             14 / Height 9. Spawned at height 12, not the usual 32.
             Speed is only 7 -- this is a slow, homing, un-killable ground
             saw, not a bolt.

    ATTACK   RS_WhiteSpectre2.FaceSpawn
    file     zscript/monsters/spectre/RS_Spectre.zs:1472
    shape    UNCLASSIFIED
    payload  RS_Wakawaka x1   (a live 320-HP monster, not a projectile)
    arc      --
    timing   4 tics, then the spawn on a 6-tic frame, then 6 tics of retract
    damage   --   (the summon itself does the damage; see its own rows)
    type     --
    sound    --   SILENT. No A_PlaySound anywhere in the state.
    impact   --   (spawned with zvel 4, SXF_SETMASTER, no fog, no flash)
    trigger  Pain   (Pain -> A_Jump(64,"FaceSpawn") at :1467, 25%)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon(summonCls:"RS_Wakawaka", count:1, cap:1,
                        tierOffset:0, profName:"Call the Chomper")
    notes    **CH SETS NO CAP.** `cap:1` above is an invention of this row and
             is flagged as such -- CH's line can be re-run every time the
             boss takes pain, so with 7,500 HP and a 25% pain roll the
             theoretical pack is unbounded. RS_AttackProfile.MakeSummon
             REQUIRES a cap (`max(1,cap)`), so a faithful port is not
             expressible; a chosen one is. Do not read `cap:1` as CH.
             RS_Wakawaka is a summon, not a ladder monster: no tier token,
             consistent with the other families' minions.

---

# TIER 10 -- RS_BlackSpectre2 ("Backstabber")

    ATTACK   RS_BlackSpectre2.Melee
    file     zscript/monsters/spectre/RS_Spectre.zs:1267
    shape    MELEE
    payload  --
    arc      --
    timing   8 tics face (SHDW EF 4), hit on a 2-tic frame -- the fastest
             melee in the family
    damage   random(25,65)
    type     --   (arg 4 omitted -> "none")
    sound    "Shadow/attack" (SHDATTAK)
    impact   --
    trigger  Melee
    range    ..64   (MeleeRange 64)
    mirrored no
    inherit  --
    profile  MakeMelee(range:64, fireSnd:"Shadow/attack",
                       profName:"Rogue Slash")
    notes    Tail-jumps to Teleporter at 12/256 (~4.7%, :1268) -- the rogue
             sometimes blinks out immediately after a hit. The state also
             clears THRUACTORS and forces Alpha 0.45 first: it is solid and
             semi-visible only while attacking.

    ATTACK   RS_BlackSpectre2.Missiles
    file     zscript/monsters/spectre/RS_Spectre.zs:1278
    shape    BURST
    payload  RS_ShadowBall x3
    arc      6   (random(-3,3), a jitter rather than a fan)
    timing   6 + 4 tics of face, then 3 rounds 5 TICS APART (`SHDW GGG 5` is
             a three-frame line -> three firings), then 4 + 2 + 1 tics of
             tail
    damage   DamageFunction (random(20,55))  (RS_SpectreFX.zs:283)
    type     Plasma
    sound    SeeSound "Shadow/attack" per ball; the state plays nothing
    impact   SBAL C 5 + SBAL DEFGH 4, no action;
             DeathSound "imp/shotx"; Decal "DoomImpScorch"
    trigger  Missile   (Missile -> A_Jump(256,"Missiles","Teleporter") at
             :1274 -- a flat 50/50 with the escape)
    range    400..   (MeleeThreshold 400)
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_ShadowBall", count:3, delayTics:5, arc:6,
                       profName:"Shadow Volley")
    notes    Spawn height 32. Each ball sheds RS_ShadowTrail (:387) every 4
             tics in flight -- Add 0.5, +NOCLIP, cosmetic.
             The state LOOPS: A_SpidRefire at :1282 sends it back to Missile,
             so this is a sustained stream, not a one-off. Two escapes out of
             the loop: A_CheckSight("Teleporter") at :1280 (blink out the
             moment it loses sight of you) and A_Jump(82,"BigOne") at :1281
             (~32% per pass).

    ATTACK   RS_BlackSpectre2.BigOne
    file     zscript/monsters/spectre/RS_Spectre.zs:1286
    shape    SINGLE
    payload  RS_ShadowBall2 x1
    arc      6   (random(-3,3))
    timing   8 tics face, fire on an 8-tic frame
    damage   DamageFunction (random(30,90))  (RS_SpectreFX.zs:312)
    type     Fire   (NOT Plasma -- the small ball is Plasma, the big one is
             Fire. Deliberate in CH, verified.)
    sound    SeeSound "Shadow/attack"
    impact   see the RS_ShadowBall2 row below -- its Death is itself an
             attack. DeathSound "imp/shotx", Decal "DoomImpScorch".
    trigger  Missile   (from Missiles via A_Jump(82) at :1281, ~32%)
    range    400..   (MeleeThreshold 400)
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_ShadowBall2", count:1,
                        profName:"Shadow Bomb")
    notes    Speed 8 -- less than HALF the small ball's 18 -- and Scale 1.75.
             A big slow lob that sheds bomblets the whole way. Returns to
             Missiles, so it interleaves with the volley rather than
             replacing it.

    ATTACK   RS_ShadowBall2.Spawn / RS_ShadowBall2.Death
    file     zscript/monsters/spectre/RS_SpectreFX.zs:327
    shape    SCATTER
    payload  RS_ShadowBall x4 per 6-tic flight loop, + x6 on death
    arc      --   SEE NOTES. The `angle` argument is the literal value 1.
    timing   in flight: `SBAL AABB 1` = 4 firings on consecutive tics, every
             6 tics, forever until it dies.
             on death: 1 (SBAL C 5) + 5 (SBAL DEFGH 4) = 6 firings over 25
             tics.
    damage   DamageFunction (random(20,55)) per bomblet
    type     Plasma  (the bomblets; the parent is Fire)
    sound    each bomblet plays SeeSound "Shadow/attack" on spawn -- so a
             single BigOne produces a continuous rattle of them
    impact   each bomblet's own Death: SBAL C 5 + SBAL DEFGH 4,
             DeathSound "imp/shotx"
    trigger  Spawn   (and Death)
    range    --
    mirrored no
    inherit  --
    profile  MakeBurst(proj:"RS_ShadowBall", count:4, delayTics:1,
                       trigger:RS_FIRE_SPAWN, profName:"Bomblet Shed")
             + MakeBurst(..., count:6, delayTics:4,
                         trigger:RS_FIRE_DEATH)
    notes    **THE ARGUMENT LIST IS OFF BY ONE IN CH AND SHIPS THAT WAY.**
             The call is
               A_CustomMissile("RS_ShadowBall",2,0,CMF_AIMOFFSET,
                               random(0,360),random(0,360))
             against the signature
               (missiletype, spawnheight, spawnofs_xy, angle, flags, pitch,
                ptr)
             (`compatibility.zs:131`). So what actually happens is:
               spawnheight = 2
               angle       = CMF_AIMOFFSET, which is the INTEGER 1
                             (`constants.zs:53`) -- a one-degree offset
               flags       = random(0,360) -- A RANDOM BITMASK, re-rolled
                             every firing, over CMF_AIMOFFSET(1) /
                             AIMDIRECTION(2) / TRACKOWNER(4) /
                             CHECKTARGETDEAD(8) / ABSOLUTEPITCH(16) /
                             OFFSETPITCH(32) / SAVEPITCH(64) /
                             ABSOLUTEANGLE(128) / BADPITCH(256)
               pitch       = random(0,360) degrees
             The scatter is EMERGENT from that, chiefly the random pitch and
             the ~50% of rolls that set CMF_ABSOLUTEANGLE. It is verbatim CH
             (spectres.txt:1289,1292,1293) and is NOT an import error -- do
             not "fix" it without the owner. A profile rebuild that fires a
             clean cone will not look like this.
             This is a payload that is itself an attack (spec sec.4), which
             is why it has its own row.

    ATTACK   RS_BlackSpectre2.BACKSTABBUU
    file     zscript/monsters/spectre/RS_Spectre.zs:1257
    shape    MELEE
    payload  --   (x2 -- two separate A_CustomMeleeAttack calls)
    arc      --
    timing   30 tics of tell (GETTO), warp, 6 tics, 11 red particles,
             18 tics face, HIT 1 (8 tics), 12 tics face, HIT 2 (6 tics)
    damage   random(30,70) EACH  (60..140 total)
    type     --   (arg 4 omitted -> "none")
    sound    "Butcher/Melee" (BCHRHIT, $volume 0.7) on each hit; the tell is
             "Shadow/pain" at ATTN_NONE, volume 2, on channel 7 -- **map-wide
             and deliberately un-attenuated**, the player's only warning
    impact   TeleportFog at the arrival point (:1252); 11 red particles
             (A_SpawnParticle, :1255)
    trigger  Walk   (See2 -> A_CheckSight("HMM") -> HMM -> GETTO)
    range    ..1000 to build, then teleports to 38 units BEHIND the target
    mirrored no
    inherit  --
    profile  MakeMelee(range:64, fireSnd:"Butcher/Melee",
                       profName:"Backstab") x2 as consecutive slot entries
             -- the WARP has no mode. See UNRESOLVED.
    notes    THE COUNTER IS THE ATTACK. `user_hm` (:1157) rises +2 each time
             the boss goes unseen while a player is within 1000
             (HMM, :1244), falls -1 each time it is seen (See2, :1238), and
             +3 on every Teleporter use (:1292). At >= 10 it warps
             (A_Warp AAPTR_TARGET, -38, 0, 16, WARPF_ABSOLUTEOFFSET|
             WARPF_INTERPOLATE, :1248) and then spends 5 (:1260). So this is
             a stalk-timer, not a range band: hide from the player long
             enough and it appears behind you. A_CheckRange(1000,"See") at
             :1242 aborts the build if no player is within 1000.
             The 30-tic hold at :1247 before the warp is the whole
             counterplay window.

    ATTACK   RS_BlackSpectre2.Teleporter
    file     zscript/monsters/spectre/RS_Spectre.zs:1289
    shape    UNCLASSIFIED
    payload  RS_TeleporterSpotSH x1   (a beacon, Damage 0)
    arc      --
    timing   2 tics to plant, 8 + 4 + 4 tics, teleport on a 2-tic frame.
             20 tics total.
    damage   --   **ZERO.** RS_TeleporterSpotSH (RS_SpectreFX.zs:234) is
             `Projectile` with no Damage and no DamageFunction; its
             `DamageType "Fire"` therefore types nothing.
    type     --   (Fire is declared but unreachable)
    sound    "Shadow/active" (SHDACT*) at :1290; the beacon plays SeeSound
             "Fire/fire3" on spawn
    impact   the beacon WANDERS: RED8 ABCCCCCCFGHHHHHH 1 Bright A_Wander,
             +FLOORHUGGER, +BOUNCEONWALLS with BounceCount 999 and
             WallBounceFactor 1.5, Speed 128, +INVISIBLE. It rolls around the
             room invisibly at 32/256 chance per loop of stopping and dying.
             **Its Death drops loot**: RS_CH_Shell (102/256), RS_CH_RocketAmmo
             (64), RS_CH_Cell (32), RS_implyingclip (128).
    trigger  Missile   (50% of Missile, :1274) / Melee (12/256, :1268) /
             Pain (88/256, :1299)
    range    --
    mirrored no
    inherit  SpecialSpot   (that is what makes it a valid A_Teleport target)
    profile  --   NO MODE EXPRESSES MOBILITY. See UNRESOLVED.
    notes    Included as a row because it is a beat that fires something and
             is exactly the kind of part the bin wants ("plant a beacon, then
             blink to it"). It is NOT damage. A_Teleport("See",
             "RS_TeleporterSpotSH","TeleportFog",TF_KEEPVELOCITY) at :1293
             jumps to wherever the beacon has rolled to.
             The beacon also sets THRUACTORS true on the boss (:1291) and
             +3 to `user_hm`, so every escape brings the backstab closer.

---

# TIER 8 -- RS_GraySpectre2 ("Uhm")

    ATTACK   RS_GraySpectre2.Missile
    file     zscript/monsters/spectre/RS_Spectre.zs:553
    shape    SINGLE
    payload  RS_IceOrbCH2 x1
    arc      6   (random(-3,3))
    timing   5 tics face, fire on a 4-tic frame. 9 tics total -- fast.
    damage   DamageFunction (random(11,33))  (RS_SpectreFX.zs:192)
    type     Melee   **on a projectile.** Not a transcription slip -- CH
             spectres.txt:474 says `DamageType Melee`. It means the orb is
             amplified by every DamageFactor "Melee" in the family
             (Cyan 2.0, Black 2.5, White 2) and by the player's own.
    sound    SeeSound "ice/Cast" (ICECAST) on spawn; the state plays nothing
    impact   ICEY FGHI 5 Bright A_Explode(random(5,12),32) -- **a FOUR-frame
             line, so it explodes 4 times**, 20..48 splash total over 20
             tics, radius 32. DeathSound "skeleton/melee" (vanilla DSSKESWG).
    trigger  Missile
    range    252..   (MeleeThreshold 252)
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_IceOrbCH2", count:1,
                        fireSnd:"ice/Cast", profName:"Bouncing Ice Orb")
    notes    THE ORB IS THE MOST ELABORATE PAYLOAD IN THE FAMILY:
             +SEEKERMISSILE with A_SeekerMissile(4,4) once per 6-tic loop;
             A_Weave(2,3,5,4) and A_CStaffMissileSlither, so it corkscrews;
             +BOUNCEONFLOORS +USEBOUNCESTATE, BounceType Doom, BounceCount
             **25**, BounceFactor 1.0 and WallBounceFactor 1.0 -- it loses no
             energy and can cross a room 25 times.
             BounceSound "jam/jamd" (CORK) on each bounce, and Bounce.Floor
             (:222) sheds RS_Drt1/2/3 dirt puffs each time.
             ProjectileKickBack 1999 -- a huge shove on hit.
             Spawn height 48 (not the default 32).
             The multi-frame A_Explode is the deliberate-lingering kind
             CLAUDE.md's note covers; it is verbatim CH (spectres.txt:509).

    ATTACK   RS_GraySpectre2.Melee
    file     zscript/monsters/spectre/RS_Spectre.zs:557
    shape    MELEE
    payload  --
    arc      --
    timing   4 tics face, hit on a 2-tic frame. 6 tics.
    damage   random(9,39)
    type     --   (arg 4 omitted -> "none")
    sound    "bite/bite4" (BITE4). Miss sound is the literal string "None",
             i.e. no miss sound.
    impact   --
    trigger  Melee
    range    ..54   (MeleeRange 54)
    mirrored no
    inherit  --
    profile  MakeMelee(range:54, fireSnd:"bite/bite4", profName:"Uhm Bite")
    notes    The 252 MeleeThreshold means this monster has a genuine dead
             band: it will not fire the orb inside 252 and cannot bite
             outside 54.
             Both attack states run `Bright` on the TRIT frames while the
             actor is RenderStyle "Add" at Alpha 0.25 -- it is a faint
             smear that FLARES when it commits. Its GetLow2 state (:544)
             squashes it to XScale 1.40 / YScale 0.40 at Speed 6 whenever it
             is unobserved, so the flare is the tell.

---

# TIER 7 -- RS_FireBluSpectre2 ("FireBluey")

`class RS_FireBluSpectre2 : RS_FireBluDemon2 { Default { +STEALTH } }`
(RS_Spectre.zs:484). **The entire body, including both attacks, is the demons
lane's** (RS_Demon.zs:590, CH spectres.txt:322 -- one line in CH too). Rows
recorded here because the class ships from the spectre file; cite the demon
file when editing. `+STEALTH` is the only difference and it changes nothing
about the attacks except that the monster is invisible until it takes damage.

    ATTACK   RS_FireBluSpectre2.Melee
    file     zscript/monsters/demon/RS_Demon.zs:671
    shape    MELEE
    payload  --
    arc      --
    timing   14 tics face (SARG EF 7 Fast), hit on an 8-tic frame
    damage   random(15,50)
    type     --   (arg 4 omitted -> "none")
    sound    "Demon/melee" (vanilla DSSGTATK)
    impact   --
    trigger  Melee
    range    ..64   (MeleeRange 64)
    mirrored no
    inherit  RS_FireBluDemon2 -> Demon.  Own Melee state, so nothing of the
             engine's A_SargAttack survives here.
    profile  MakeMelee(range:64, fireSnd:"Demon/melee",
                       profName:"FireBlu Bite")
    notes    `Fast` on the windup frames -- 14 tics drops to ~10 on Nightmare
             / -fast.

    ATTACK   RS_FireBluSpectre2.Rush
    file     zscript/monsters/demon/RS_Demon.zs:659
    shape    CHARGE
    payload  --
    arc      --
    timing   **FIVE CHAINED CHARGES**: face 1 tic, A_SkullAttack(20) on a
             3-tic frame, then (face 3 Fast, charge 3) x4. 31 tics.
    damage   random(1,8) * 1 PER SLAM  (1..8 -- `Damage 1` at
             RS_Demon.zs:608; five slams = 5..40 if every one connects)
    type     Melee   (AActor::Slam, hardcoded)
    sound    AttackSound "demon/melee" on each of the five
    impact   --
    trigger  Missile   (via A_JumpIfCloser(800,"Rush") at :638)
    range    ..800
    mirrored no
    inherit  RS_FireBluDemon2 -> Demon
    profile  --   NO FACTORY EXPRESSES CHARGE. See UNRESOLVED.
    notes    THE LOWEST PER-HIT CHARGE DAMAGE AND THE MOST CHARGES. Each
             A_SkullAttack re-faces first, so it can turn between rams --
             this is a stutter-chase, not one lunge. Speed 5 on the actor
             makes the charge the only way it closes.

---

# TIER 6 -- RS_RedSpectre ("Red Spectre")

    ATTACK   RS_RedSpectre.Melee
    file     zscript/monsters/spectre/RS_Spectre.zs:1096
    shape    MULTI
    payload  RS_RedDemonBloodBolt3 x6  +  RS_RedThingsLS x2 (cosmetic)
             (+ a contact bite)
    arc      34   (six bolts at random(-17,17))
    timing   12 tics face (SRG2 EF 6), bite on a 4-tic frame, then 2 blood
             flecks and ALL SIX BOLTS ON ONE TIC (`SRG2 GGGGGG 0`)
    damage   bite random(10,55);
             bolts DamageFunction (random(1,5)) each  (RS_DemonFX.zs:523)
    type     bite untyped ("none"); bolts Fire
    sound    "blooddemon/melee" (DSBLDATK) on the bite. **The six bolts are
             silent** -- RS_RedDemonBloodBolt3 sets no SeeSound.
    impact   BOLTS HAVE NO IMPACT AT ALL. Their Death state is
             `BLUD C 0; Stop;` -- zero tics, one frame, no sound, no spawn
             (RS_DemonFX.zs:537). They also self-expire: the Spawn chain runs
             24+20+7 = 51 tics and then Stops, so an unblocked bolt simply
             vanishes.
             RS_RedThingsLS (RS_DemonFX.zs:115) is Scale 0.15 Add blood
             flecks with Gravity 2 -- no damage.
    trigger  Melee
    range    ..78   (MeleeRange 78 -- the longest reach in the family)
    mirrored no
    inherit  RS_RedDemonBloodBolt3 is CH's own spectres.txt:1031 class but is
             OWNED BY THE DEMONS LANE (Demons.txt:238 fires it too) and
             ships from RS_DemonFX.zs:511 -- see the RS_SpectreFX.zs header.
    profile  MakeMelee(range:78, fireSnd:"blooddemon/melee")
             + MakeVolley(proj:"RS_RedDemonBloodBolt3", count:6, arc:34,
                          profName:"Blood Spatter")
             -- two slot entries; MULTI has no single call
    notes    The bolts are spawned at a RANDOM HEIGHT, random(32,48), not a
             fixed one -- unique in this family.
             `-NOGRAVITY` with `Gravity 0.2` and Speed 15: they drift and sag
             rather than fly. RenderStyle "SoulTrans", Scale 0.95.
             Damage is trivial (6..30 across all six); this is spray, not a
             second attack. Do not size a profile off the bolt count.

    ATTACK   RS_RedSpectre.BuffUP
    file     zscript/monsters/spectre/RS_Spectre.zs:1125
    shape    UNCLASSIFIED
    payload  RS_EffectHK x2   (cosmetic spark shell)
    arc      --
    timing   1 tic, then 12 tics (`SRG2 EF 6` -- two frames, so
             A_CustomMissile fires TWICE), then 5 + 1 + 1
    damage   --   ZERO. RS_EffectHK (RS_ImpFX.zs:365) is `Projectile
             +NOINTERACTION` with Speed 0 and no Damage.
    type     --
    sound    --   SILENT. No A_PlaySound; RS_EffectHK sets no SeeSound.
    impact   RS_EffectHK Death (RS_ImpFX.zs:383): `CBAL A 1
             A_Burst("RS_RedThingsHK")` -- it shatters into chunks in place.
    trigger  Pain   (Pain -> A_Jump(174,"BuffUP") at :1121, ~68% -- the
             likeliest pain reaction in the family)
    range    --
    mirrored no
    inherit  --
    profile  MakeSelfBuff(speedMult:1.5625, damageMult:1.0, duration:0,
                          noPain:true, profName:"Blood Rage")
             (25/16 = 1.5625; `duration:0` because CH's is PERMANENT)
    notes    FOUR PERMANENT CHANGES, none of which revert: Speed 16 -> 25
             (:1124), bNOPAIN = true (:1126 -- it stops flinching for the
             rest of the fight), bSTEALTH = false (:1127) and
             A_SetTranslucent(1) (:1128) -- **it becomes fully visible**.
             That last one is the interesting half: the red spectre TRADES
             its concealment for speed and pain immunity. On a weapon this is
             a real cost/benefit, not just a stat line.
             MakeSelfBuff's `duration` is in tics and reverts; there is no
             "never revert" value. `0` above is a placeholder, see UNRESOLVED.

---

# TIER 5 -- RS_YellowSpectre ("Yellow Spectre")

    ATTACK   RS_YellowSpectre.Melee
    file     zscript/monsters/spectre/RS_Spectre.zs:992
    shape    MELEE
    payload  --
    arc      --
    timing   16 tics face (SRG2 EF 8), hit on an 8-tic frame, then a 1-tic
             bookkeeping frame
    damage   random(13,52)
    type     --   (arg 4 omitted -> "none")
    sound    "blooddemon/melee" (DSBLDATK)
    impact   --
    trigger  Melee
    range    ..64   (MeleeRange 64)
    mirrored no
    inherit  Spectre -> Demon for defaults; own Melee state
    profile  MakeMelee(range:64, fireSnd:"blooddemon/melee",
                       profName:"Yellow Bite")
    notes    The trailing frame at :993 is the CALM LATCH: `User_Calm =
             (User_Calm == 1) ? 1 : 0`, which is CH's
             A_SetUserVar("User_Calm", User_Calm == 1). Biting is what ends
             the sprint -- see the next row.
             **This is the SPG2 -> SRG2 line.** Already resolved 2026-08-06
             (CH spectres.txt:881 mistyped SR as SP; the twin at
             Demons.txt:1516 proves it). Recorded here only so nobody
             re-opens it.

    ATTACK   RS_YellowSpectre.SpeedBuff
    file     zscript/monsters/spectre/RS_Spectre.zs:1018
    shape    UNCLASSIFIED
    payload  --
    arc      --
    timing   3 tics (three 1-tic frames)
    damage   --   ZERO
    type     --
    sound    --   SILENT
    impact   --
    trigger  Pain   (Pain -> A_Jump(128,"SpeedBuff") at :1015, 50%)
    range    --
    mirrored no
    inherit  --
    profile  MakeSelfBuff(speedMult:1.8235, duration:0,
                          profName:"Blood Sprint")
             (31/17 = 1.8235; `duration:0` because it is ended by an EVENT,
             not a timer)
    notes    THE ONLY SELF-BUFF IN THE FAMILY THAT REVERTS, and it reverts on
             a CONDITION, not a clock. SpeedBuff sets Speed 17 -> 31, clears
             bSTEALTH (it becomes visible), and flips `User_Calm` to 1.
             See (:987) then reads `A_JumpIf(User_Calm == 1,"Calm")` every
             lap, and Calm (:1022) restores Speed 17 and bSTEALTH -- but the
             Melee row's trailing frame is what actually latches User_Calm,
             so **the sprint ends when it lands a bite**.
             RS_AttackProfile has no event-terminated buff. A tic duration is
             the nearest and is not the same thing. See UNRESOLVED.

---

# TIER 4 -- RS_PurpleSpectre ("Purple Spectre")

    ATTACK   RS_PurpleSpectre.Melee
    file     zscript/monsters/spectre/RS_Spectre.zs:897
    shape    MELEE
    payload  --
    arc      --
    timing   14 tics face (SARG EF 7 Fast), hit on a 6-tic frame
    damage   random(13,46)
    type     --   (arg 4 omitted -> "none")
    sound    "Demon/melee" (vanilla DSSGTATK)
    impact   --
    trigger  Melee
    range    ..64   (MeleeRange 64)
    mirrored no
    inherit  Spectre -> Demon for defaults; own Melee state
    profile  MakeMelee(range:64, fireSnd:"Demon/melee",
                       profName:"Purple Bite")
    notes    --

    ATTACK   RS_PurpleSpectre.Rush2
    file     zscript/monsters/spectre/RS_Spectre.zs:892
    shape    CHARGE
    payload  --
    arc      --
    timing   1 tic face, A_SkullAttack(25) on a 3-tic frame
    damage   random(1,8) * 3   (3..24 -- `Damage 3` at RS_Spectre.zs:866)
    type     Melee   (AActor::Slam)
    sound    AttackSound "demon/melee"
    impact   --
    trigger  Missile   (and Pain -- see notes)
    range    ..800   (Missile -> A_JumpIfCloser(800,"Rush2") at :888)
    mirrored no
    inherit  Spectre -> Demon for defaults
    profile  --   NO FACTORY EXPRESSES CHARGE. See UNRESOLVED.
    notes    SECOND ENTRY POINT: Pain jumps back into Missile at 100/256
             (~39%, :919), so being hurt can trigger the rush. That is the
             whole difference between this monster and RS_BlueSpectre, whose
             Pain has no such jump.
             +STEALTH and RenderStyle "Add": invisible until damaged, then it
             flickers. `Damage 3` is what makes this charge hurt where Blue's
             does not.

---

# TIER 3 -- RS_BlueSpectre ("Blue Spectre")

    ATTACK   RS_BlueSpectre.Melee
    file     zscript/monsters/spectre/RS_Spectre.zs:795
    shape    MELEE
    payload  --
    arc      --
    timing   14 tics face (SARG EF 7 Fast), hit on a 7-tic frame
    damage   random(15,43)
    type     --   (arg 4 omitted -> "none")
    sound    "Demon/melee" (vanilla DSSGTATK)
    impact   --
    trigger  Melee
    range    ..64   (MeleeRange 64)
    mirrored no
    inherit  Spectre -> Demon for defaults; own Melee state
    profile  MakeMelee(range:64, fireSnd:"Demon/melee",
                       profName:"Blue Bite")
    notes    --

    ATTACK   RS_BlueSpectre.Rush
    file     zscript/monsters/spectre/RS_Spectre.zs:790
    shape    CHARGE
    payload  --
    arc      --
    timing   1 tic face, A_SkullAttack(25) on a 3-tic frame
    damage   **ZERO**  -- random(1,8) * 0.
    type     Melee   (moot at 0 damage)
    sound    AttackSound "demon/melee"
    impact   --
    trigger  Missile   (via A_JumpIfCloser(800,"Rush") at :786)
    range    ..800
    mirrored no
    inherit  Spectre -> Demon.  **Neither sets a `Damage` property, and
             neither does RS_BlueSpectre** (Default block, :749-775).
    profile  --   NO FACTORY EXPRESSES CHARGE. See UNRESOLVED.
    notes    THIS CHARGE DOES NO DAMAGE, AND THAT IS FAITHFUL TO CH.
             AActor::Slam computes GetMissileDamage(7,1) =
             ((random & 7) + 1) * DamageVal, and DamageVal is 0 when no
             `Damage` property is set (`src/playsim/p_mobj.cpp:3309-3316,
             3372`). CH's BlueSpectre (spectres.txt:653-678) has no Damage
             line either -- verified against the CH file directly, so this is
             a CH quirk, NOT an import error. Do not "fix" it by adding a
             Damage line.
             Functionally it is a 25-speed gap-closer: it slams you, stops
             dead, and then bites. The row is kept because the MOVEMENT is
             the attack and that is exactly what a profile would wear.
             Compare Purple (Damage 3) and Cyan (Damage 3), which are the
             same call with a real payload.

---

# TIER 2 -- RS_GreenSpectre ("Green Spectre")

    ATTACK   RS_GreenSpectre.Melee
    file     zscript/monsters/spectre/RS_Spectre.zs:696
    shape    MELEE
    payload  --
    arc      --
    timing   14 tics face (SARG EF 7 Fast), hit on a 7-tic frame
    damage   random(13,40)
    type     --   (arg 4 omitted -> "none")
    sound    "Demon/melee" (vanilla DSSGTATK)
    impact   --
    trigger  Melee
    range    ..54   (MeleeRange 54)
    mirrored no
    inherit  Spectre -> Demon for defaults; own Melee state
    profile  MakeMelee(range:54, fireSnd:"Demon/melee",
                       profName:"Green Bite")
    notes    ONLY ONE ATTACK. Green has no Missile state and Demon defines
             none, so there is nothing inherited to find. RenderStyle "Add"
             at Alpha 0.20 makes it the faintest of the low tiers.

---

# TIER 1 -- RS_CommonSpectre ("Spectre")

    ATTACK   RS_CommonSpectre.Melee
    file     zscript/monsters/spectre/RS_Spectre.zs:596  (class; the state is
             INHERITED -- the body is at
             <gzdoom>/wadsrc/static/zscript/actors/doom/demon.zs:34-36)
    shape    MELEE
    payload  --
    arc      --
    timing   16 tics face (SARG EF 8 Fast), hit on an 8-tic frame
    damage   random(1,10) * 4   (4..40)
    type     Melee   (hardcoded in A_SargAttack:
             `targ.DamageMobj(self, self, damage, "Melee")`, demon.zs:94)
    sound    --   **SILENT.** A_SargAttack (demon.zs:88-97) contains no sound
             call at all. The class inherits `AttackSound "spectre/melee"`
             from Spectre and NOTHING EVER PLAYS IT. This is vanilla Doom
             behaviour, not a defect, and per the spec it is the correct
             shape for a profile slot -- the gun's own sound fills it.
    impact   --   (A_SargAttack does DamageMobj + TraceBleed, no puff)
    trigger  Melee
    range    ..54   (MeleeRange 54 -- overridden from the engine's default 44
             at RS_Spectre.zs:606)
    mirrored no
    inherit  Spectre -> Demon.  **RS_CommonSpectre overrides only Tickles,
             Death, Pain.AbyssPE, Raise and Grow** (:610-649). Spawn, See,
             Melee and Pain all come from Demon untouched -- so the attack is
             literally the 1993 pink demon bite. Reading the class body alone
             reports "no attacks", which is why this row exists.
    profile  MakeMelee(range:54, fireSnd:"", profName:"Spectre Bite")
    notes    A_SargAttack calls CheckMeleeRange() itself and does nothing if
             out of range -- unlike A_CustomMeleeAttack, which the engine
             also range-checks but which takes an explicit damage argument.
             The roll is `random(1,10) * 4`, i.e. a d10 x4, NOT random(4,40):
             it can only land on multiples of 4. Keep the form.

---

# SUMMON -- RS_Wakawaka ("You're not pacman")

Spawned by RS_WhiteSpectre2.FaceSpawn. Not on the tier ladder, no tier token.

    ATTACK   RS_Wakawaka.Missile
    file     zscript/monsters/spectre/RS_SpectreFX.zs:554
    shape    CHARGE
    payload  --   (the monster IS the projectile -- but see notes)
    arc      --
    timing   1 tic face, then ThrustThingZ + ThrustThing on 0-tic frames;
             MidLeap loops 1 tic at a time until A_CheckFloor succeeds
    damage   --   **NO CONTACT DAMAGE.** ThrustThing does not set MF_SKULLFLY,
             so AActor::Slam is never entered and nothing is dealt on impact.
             The actor's own `DamageFunction (random(20,75))` (:527) is
             therefore DECLARED AND NEVER READ -- there is no code path on a
             non-missile, non-skullfly monster that reads it. Kept verbatim
             from CH (`Damage (random(20,75))`, spectres.txt:1670).
    type     --
    sound    --   **SILENT, AND NOT BY DESIGN.** The state calls
             A_PlaySound("Worm/Hurt") at :553. SNDINFO:1158 maps Worm/Hurt to
             lump `HIT`, and no such lump exists in `sounds/` (checked: 693
             CH lumps + 98 monster lumps, absent from both) or in CH's own
             tree. Silent in CH, silent here -- the RS_SpectreFX.zs header
             already records this. An unresolved sound name is completely
             inert: no error, no warning.
    impact   --   (Land, :560, just calls A_Stop)
    trigger  Missile   (Missile first runs A_JumpIfCloser(60,"Melee") at
             :551, so the leap only happens when the target is OUT of melee)
    range    60..
    mirrored no
    inherit  --
    profile  --   NO FACTORY EXPRESSES CHARGE, and this one is not even
             A_SkullAttack. See UNRESOLVED.
    notes    ThrustThingZ(0, random(6,13), 0, 0) then
             ThrustThing(int(angle*256/360), 21, 0, 0) -- a real ballistic
             hop: variable height, fixed forward impulse 21, in BAM-ish
             units (angle*256/360). Our tree adds the `int()` cast CH's
             untyped DECORATE did implicitly (:555); that is the only textual
             difference in this actor and it changes nothing.
             MidLeap polls A_CheckFloor twice per tic and lands the instant
             it touches down.
             CHARGE is used because the monster becomes the projectile, which
             is the shape's definition -- but a rebuild MUST NOT give it
             skullfly damage. It is pure mobility; the damage comes from the
             Melee row it lands into.

    ATTACK   RS_Wakawaka.Melee
    file     zscript/monsters/spectre/RS_SpectreFX.zs:565
    shape    MELEE
    payload  --
    arc      --
    timing   5 tics face, hit on an 11-tic frame -- the longest single melee
             frame in the family
    damage   random(10,45)
    type     None   (arg 4 is the literal name "None"; CH passed `0`)
    sound    --   **SILENT.** Both the melee sound and the miss sound are ""
             (CH passed `0,0`). The actor's AttackSound "EWorm/Bite" (E_BITE,
             which DOES exist) is never played by anything.
    impact   --
    trigger  Melee
    range    ..60   (MeleeRange 60)
    mirrored no
    inherit  --
    profile  MakeMelee(range:60, fireSnd:"", profName:"Chomp")
    notes    `bleed` is explicitly false (arg 5) -- the only no-bleed melee in
             the family, so a hit produces no blood.
             +NEVERTARGET +NOINFIGHTING +DONTHARMSPECIES +DONTHARMCLASS: it
             cannot be targeted by other monsters and cannot hurt its own
             kind. Mass 4000 -- almost unpushable.

    ATTACK   RS_Wakawaka.Death
    file     zscript/monsters/spectre/RS_SpectreFX.zs:576
    shape    UNCLASSIFIED
    payload  --   (A_Explode, no actor)
    arc      --   (radial, 64 units)
    timing   4 + 16 + 8 + 1 tics of death animation, then **A_Explode THREE
             TIMES** -- `MISL BCD 6` is a three-frame line -- 6 tics apart
    damage   random(10,50) PER FIRING  (30..150 total)
    type     --   (A_Explode's default damage type)
    sound    "weapons/rocklx" (vanilla DSBAREXP) on the tic before;
             A_PlaySound("Worm/Death") at :572 is **silent** -- SNDINFO:1157
             maps it to lump `DEATH`, which does not exist anywhere
    impact   MISL BCD sprite (the vanilla rocket explosion)
    trigger  Death
    range    --   (radius 64)
    mirrored no
    inherit  --
    profile  MakeRadial(radius:64, damage:30, fireSnd:"weapons/rocklx",
                        profName:"Chomper Pop")
             -- `damage:30` IS A FLATTENED ROLL AND IS WRONG. See UNRESOLVED.
    notes    The three firings are the multi-frame A_Explode pattern; this
             one is a genuine triple-detonation over 18 tics, not a single
             blast. It kills the summoner's own pack only if they lack
             DONTHARMCLASS -- most of this family has it.

---

# FAMILY-WIDE BEATS THAT ARE **NOT** ATTACKS (checked, not assumed)

  * **`Pain.AbyssPE`** -- appears identically on seven classes
    (RS_Spectre.zs:302, 446, 559, 624, 698, 899, 995). It is the abyss
    TRANSFORM: 90x RS_SplashAbyss, then spawn RS_AbyssDemon2 and A_Die.
    **Zero damage** -- RS_SplashAbyss (RS_ZombiemanFX.zs:707) has no Damage,
    no DamageFunction, and +THRUACTORS. Cosmetic droplets only. Not a row.
  * **`Grow` / `Raise`** -- RS_CommonSpectre :644, RS_GreenSpectre :735,
    RS_BlueSpectre :834. Resurrect-and-promote to the next tier, no emission.
  * **`Tickles`** -- spawns RS_ThePlanBoner (RS_Zombieman.zs:2184), a gag
    death egg gated on RS_CHBoner. No damage.
  * **`RS_ShadowGhostA` and its three children** -- the chain the brief asked
    to resolve. RS_ShadowGhostA (RS_SpectreFX.zs:336) is
    `Radius 4, Height 8, Speed 0, Damage 0, Mass 75, RenderStyle
    "Translucent", Alpha 0.25, Projectile`, Spawn = `SHDW A 10; Stop;`.
    RS_ShadowGhostB (:357), C (:367) and D (:377) each derive from it and
    **override the Spawn state ONLY**, changing the sprite frame to B/C/D and
    nothing else -- so all four inherit Speed 0 and Damage 0.
    **They cannot hurt anything and they do not move.** They are the
    afterimages RS_BlackSpectre2.See sheds every 3 tics of chase
    (:1215-1232, eight spawns per lap). Cosmetic; deliberately NOT a row.
  * **`RS_ShadowTrail`** (:387) -- Speed 0, no Damage, +NOCLIP. Cosmetic.
  * **`RS_MediCacoBrown` / `RS_MediCacoBrown2`** (:123, :155) -- no Damage,
    +THRUACTORS. Cosmetic; recorded in Brown's Scatter row.
  * **`RS_RiseCheck`** (:408) -- an Inventory token gating the white boss's
    one-time rise. Not an actor.
  * **`RS_SpeedBuffPE` / `RS_PESpeedCtl`** (:62, :80) -- the pack speed buff,
    a native rebuild of CHSett.acs:317. Recorded in Brown's Scatter row.

---

# UNRESOLVED

Honest gaps. Nothing below is a guess dressed as a finding.

**A. Six things this family does that RS_AttackProfile cannot express.**
These are gaps in the PARTS BIN, not in the reading. Each is why a `profile`
line above says `--` or carries a caveat.

  1. **There is no CHARGE mode.** `RS_ATK_*` runs BULLET / HEAVY / MELEE /
     HITSCAN / SUMMON / RADIAL / SELFBUFF (RS_AttackProfile.zs:42-68). Nothing
     makes the firer become the projectile. **Five rows need it**:
     RS_CyanSpectre2.Hiss, RS_BlueSpectre.Rush, RS_PurpleSpectre.Rush2,
     RS_FireBluSpectre2.Rush, RS_Wakawaka.Missile. The spec's own frequency
     table puts CHARGE at 13 occurrences across the survey, so this is not a
     spectre-only gap -- expect it in the Lost Soul and Demon files too.
  2. **There is no launch-pitch OFFSET, only `VolleyPitchJitter` (symmetric
     scatter).** RS_CyanSpectre2's ring lobs at ~50 degrees UP; the ripper
     RS_SpecSlime3 is +FLOORHUGGER. Neither centre is expressible.
  3. **`RadialDamage` is an `int`** (RS_AttackProfile.zs:243), so
     `A_Explode(random(10,50),64)` cannot be carried without flattening the
     roll -- which CLAUDE.md forbids. The RS_Wakawaka.Death profile line
     above is marked wrong for exactly this reason and must not be copied
     into code as-is.
  4. **`MakeSelfBuff` has only a tic `duration`.** RS_RedSpectre's BuffUP is
     PERMANENT and RS_YellowSpectre's SpeedBuff ends on an EVENT (landing a
     bite), not a clock. Neither is a duration.
  5. **A radial buff can only target the SELF.** `MakeRadial(hitsAllies:true)`
     covers Brown's 1200-radius heal but not the 320-radius
     "give my allies +10 Speed for 600 tics" half of the same state.
  6. **Melee mode has no count or spacing.** RS_WhiteSpectre2.Melee is three
     bites 4 tics apart and RS_BlackSpectre2.BACKSTABBUU is two 20 tics
     apart. `BurstDelayTics` exists but `MakeBurst` builds `RS_ATK_HEAVY`.
     Also nothing expresses a WARP-then-strike.

**B. `MeleeThreshold` is the only real range gate, and it is a MISSILE gate.**
The `range` fields above distinguish two different things and a reader should
not merge them: `..800` on the charges is an `A_JumpIfCloser` inside the
state, while `252..` / `300..` / `400..` on Gray, White and Black is
`MeleeThreshold` refusing the missile attack at the ENGINE level
(`p_enemy.cpp:373`). Only the first kind is visible in the state text. If
another family's pass read state text only, it will have missed the second
kind entirely.

**C. CH is not at the path the spec names.** The spec and the task both cite
`C:\Users\Command\Desktop\CH`; **that directory does not exist on this
machine.** All CH citations above were made against
`E:\New folder\ART SOURCE\CH\decorate\spectres.txt` (1,721 lines) -- the path
CLAUDE.md names as the whole-monster source of truth, and the file our own
headers cite by line. The two are almost certainly the same pack (every line
number our headers claim resolved correctly there, including
spectres.txt:881 for the SPG2 typo and :1516 in Demons.txt for its twin), but
**this was not proved and someone should confirm which copy is canonical.**

**D. `E:\DXR2` does not exist either.** CLAUDE.md says the engine source is
there. It is not; `E:\` holds `GlowInTheDark` and `UZDXREMA`. The three
engine facts in the header were read from **`E:\UZDXREMA`**
(`wadsrc/static/zscript/`, `src/playsim/`), which is a GZDoom-family source
tree with the expected layout. If that is the wrong tree, facts 1-3 and every
damage figure derived from `AActor::Slam` and `A_SargAttack` need re-checking.
CLAUDE.md's path should be corrected either way.

**E. RS_Wakawaka's `DamageFunction (random(20,75))` appears to be dead.**
Reasoning: the only paths that read `Actor.Damage` are missile impact and
`AActor::Slam` under MF_SKULLFLY; Wakawaka is neither a missile nor ever
skullfly (it leaps with ThrustThing), and its melee passes an explicit
damage argument. **Not proven by test.** It is verbatim CH and must stay --
this is recorded so nobody later "cleans it up" believing it does nothing,
and so somebody with the game running can confirm.

**F. The `RS_ShadowBall2` argument-order finding is reported, not fixed.**
Angle = the integer 1, flags = `random(0,360)` as a bitmask, pitch =
`random(0,360)`. Ours matches CH character for character (CH
spectres.txt:1289, 1292, 1293). It is almost certainly not what CH's author
meant, but the ONLY authorities are our tree and CH and they agree, so it is
recorded as behaviour. **A profile rebuild that fires a clean cone will not
reproduce it, and that difference should be a decision, not an accident.**

**G. Two sounds this family plays resolve to nothing, end to end.**
`Worm/Hurt` -> lump `HIT` and `Worm/Death` -> lump `DEATH` (SNDINFO:1157-1158).
Neither lump exists in `sounds/` (checked every subdirectory: ch/693,
monsters/98, and the seven others) and the RS_SpectreFX.zs header records
them as absent in CH too. Both are on RS_Wakawaka, so its leap and its death
cry are silent. Every other sound named by a spectre attack was followed to a
real lump: BITE4, DSWORMAT, DSBLDATK, SHDATTAK, BCHRHIT, SLGMBITE, ICECAST,
BPBITE, BPSEE, BDPS1, BDPD1, CORK, E_BITE. Four more (`demon/melee`,
`skeleton/melee`, `imp/shotx`, `weapons/rocklx`) are absent from our SNDINFO
because they are the IWAD's own and resolve from the engine.

**H. Two known-and-closed items, listed so they are not re-opened.**
`SPG2` -> `SRG2` (RS_YellowSpectre.Melee) is RESOLVED -- CH's typo, proven by
the twin line in the demon file. `SLGM F` / `SLGM "\"` are RESOLVED as art
(the mirrored `SLGMF0^0` lump); the `SLGM "\"` site remains a TNT1 hold only
because a quoted escaped-backslash frame is a parse error on this engine, and
that is deliberate. Neither affects any row above.

**I. What was NOT checked, so nobody assumes it was.** Sprite-prefix presence
was not re-verified for this pass (that is the import lane's count, and it is
recorded as complete in the family headers). No row below was observed in the
running game; every timing, angle and damage figure is read from source.
