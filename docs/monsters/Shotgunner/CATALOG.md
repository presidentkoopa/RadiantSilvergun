# Shotgunner (family 02) — ATTACK CATALOG

Format per `docs/rs_21_port_law.txt` section 4. `kind:` leads, because
that is the line PACK selects on; everything else is evidence.

**Ground truth**, and the only thing checked:

* `E:\New folder\ART SOURCE\CHP\DECORATE\02\02_*.txt` (14 real tier files)
* `E:\New folder\ART SOURCE\CH\decorate\Shotgunners.txt` (parents + squad)
* Our states, diffed tier by tier 2026-08-05 — see `INDEX.md`. All fourteen
  match CHP, so every `fires:` line below is true of BOTH trees.

---

## READ THIS BEFORE USING THE `axes` LINES

Same restriction as family 01: values come only from the vocabulary that
already exists in `GetBaseKeywords()`. Nothing is invented.

```
delivery : bullet heavy melee radial
element  : explosive kinetic melt thermal plasma void ice
payload  : multi single
trigger  : burst fullauto semi semiauto
role     : artillery boss bruiser fodder skirmisher summoner
mobility : ground flying floating
species  : shotgunner
trait    : ex homing resurrector secondstage stealth summoned
behavior : homing piercing
```

`archetype:` is deliberately omitted on every entry — every live
`archetype:` value names a *player weapon class*, and borrowing one for a
monster attack would claim a relationship that does not exist. Family 01
made the same call.

**Axis values this family wants that DO NOT EXIST — flagged, not invented:**

| missing | wanted by | entries |
|---|---|---|
| `element:mud` or similar | T08's twenty earth pellets | 15 |
| `element:abyss` | T06's bolts and splash | 11, 12 |
| a `trigger:` for jam/reload cycles | T05, T10, TEX | 10, 19, 27 |
| a `delivery:` for rail/beam | T02's three stacked beams | 3 |

Entry 3 is the same `behavior:piercing` hole family 01 flagged on the
Unmaker. The string is live at `RS_FX_BallisticFired.zs:140`; no keyword
grants it.

---

## 1. Common Shotgun Blast
```
kind         : three-pellet shotgun blast
axes         : delivery:bullet payload:multi element:kinetic trigger:semi
               role:fodder mobility:ground species:shotgunner
tier(s)      : T00 Common (CommonSG)
chp source   : 02_C.txt Missile
fires        : A_CustomBulletAttack(22.5, 0, 3, random(1,5)*3, BulletPuff,
               0, CBAF_NORANDOM)
damage       : 3 pellets x random(1,5)*3  =  9..45
behaviour    : face 10 tics, fire, 10 tics recovery, back to See. The
               baseline the whole family is measured against.
profile      : MakeHitscan — bullet count not representable, see notes
notes        : CBAF_NORANDOM means the damage roll is the ONLY variance;
               no per-pellet spread randomisation.
```

## 2. Seven-Bolt Plasma Fan
```
kind         : seven-bolt plasma shell fan
axes         : delivery:bullet payload:multi element:plasma trigger:semi
               role:skirmisher mobility:ground species:shotgunner
tier(s)      : T01 Green (GreenSG)
chp source   : 02_G.txt Missile
fires        : 7 x A_SpawnProjectile("RS_SGshot1", 34, -2, <angle>)
               angles 1, 0, -1, 2, -2, 3 on one frame, then -3 on the
               lowering frame
behaviour    : the seventh bolt leaves as the gun comes DOWN, so the fan
               is asymmetric in time as well as angle — sidestepping the
               first six still walks you into the last.
```

## 3. Triple Railgun
```
kind         : three stacked railgun beams
axes         : delivery:bullet payload:multi element:kinetic trigger:burst
               role:skirmisher mobility:ground species:shotgunner
tier(s)      : T02 Blue (BlueSG)
chp source   : 02_B.txt Missile
fires        : 3 x A_CustomRailgun(random(2,8), 1, "", <colour>,
               RGF_NOPIERCING, 1, <maxdiff>, "None", 0,0,0,0, <sparsity>)
               White/25/3, Blue/12/1, White/33/1
damage       : random(2,8) per beam, 6..24 total
notes        : RGF_NOPIERCING — CH deliberately turns the pierce OFF, so
               unlike the Unmaker this one does NOT need behavior:piercing.
               The three differing maxdiff values (25/12/33) are an
               autoaim spread, not a visual.
```

## 4. Seeking Lance
```
kind         : close-range ripping lance
axes         : delivery:heavy payload:single element:kinetic trigger:semi
               role:skirmisher mobility:ground species:shotgunner
               behavior:piercing
tier(s)      : T02 Blue
chp source   : 02_B.txt Lance
gate         : A_JumpIfCloser(350) from Missile
fires        : A_SpawnProjectile("RS_SGLance1", 34, -2)
notes        : SGLance1 is +Ripper (Shotgunners.txt:1145) — this one IS a
               genuine pierce and the axis is real.
```

## 5. Frost Buckshot
```
kind         : five-shot explicit-angle frost spread
axes         : delivery:bullet payload:multi element:ice trigger:burst
               role:skirmisher mobility:ground species:shotgunner
tier(s)      : T03 Cyan (CyanSG2)
chp source   : 02_CY.txt Missile
fires        : 5 x A_CustomBulletAttack with CBAF_EXPLICITANGLE at
               (4,4) (-4,-4) (5,5)x2 (4,-4) (-4,4), range 8000
damage       : random(1,5) / random(1,4) / random(1,2)x2 / random(1,4) /
               random(1,5)
behaviour    : ends A_CheckSight("See") then A_Jump(102) back into
               Missile — it re-engages roughly 40% of the time rather
               than resetting.
notes        : range 8000 is TEN TIMES normal hitscan reach. This tier
               shoots across any map.
```

## 6. Ice Shot Volley
```
kind         : five ice projectiles plus a tracking shot
axes         : delivery:bullet payload:multi element:ice trigger:burst
               role:skirmisher mobility:ground species:shotgunner
tier(s)      : T03 Cyan
chp source   : 02_CY.txt Proj
gate         : A_Jump(128) from Missile — a true coin flip against entry 5
fires        : 5 x A_SpawnProjectile("RS_IceZombieShot2", 32, 0,
               random(-5,5), 0, random(-2,2)) then one explicit-angle
               bullet at (-2,2)
```

## 7. Bunny Hop
```
kind         : lateral leap out of your firing line
axes         : delivery:melee payload:single element:kinetic trigger:semi
               role:skirmisher mobility:ground species:shotgunner
tier(s)      : T03 Cyan
chp source   : 02_CY.txt Jumpy / Jump
fires        : nothing — pure mobility
behaviour    : RS_HopZ(12) then RS_HopDir(angle - randompick(130,180,230),
               12), i.e. up and BACKWARD at one of three angles, then a
               second smaller hop forward. Entered from See on a 232 roll
               via a LOS check at 750/300, and from Pain on a 96 roll.
notes        : CHP gates the See entry behind CallACS("CH_CyanBounce")
               which can SUPPRESS it. We have no ACS, so ours bounces
               MORE than CHP's. Recorded in INDEX.md; deliberate.
               Listed here because PACK should be able to select a
               "displacement" beat even though it deals no damage.
```

## 8. Hazmat Charge
```
kind         : gas-hissing bull rush
axes         : delivery:melee payload:single element:kinetic trigger:semi
               role:bruiser mobility:ground species:shotgunner
tier(s)      : T04 Purple (PurpleSG)
chp source   : 02_P.txt GetCloser
gate         : NOT closer than 300
fires        : A_SkullAttack(12)
behaviour    : lost-soul rush at speed 12, opened with "gas/gas1". It
               closes to burst range rather than shooting from where it
               stands — the only family-02 tier that answers distance
               with movement instead of a bigger gun.
```

## 9. Purple Fire Burst
```
kind         : three-shot purple fire burst with refire
axes         : delivery:bullet payload:multi element:thermal trigger:burst
               role:skirmisher mobility:ground species:shotgunner
tier(s)      : T04 Purple
chp source   : 02_P.txt Fire2
gate         : closer than 300, twice (Missile -> Fire1 -> Fire2)
fires        : 3 x A_SpawnProjectile("RS_PurpFire2", 42, 1, random(-1,1))
behaviour    : ends A_MonsterRefire(180,"See") then Goto Fire1 — it
               re-checks range and keeps firing while you stay close.
```

## 10. Assault Shotgun Magazine
```
kind         : sixteen-round magazine with a real reload window
axes         : delivery:bullet payload:multi element:kinetic
               trigger:fullauto role:bruiser mobility:ground
               species:shotgunner
tier(s)      : T05 Orange (YellowSG)
chp source   : 02_Y.txt Missile / Reload
fires        : 4 x [A_CustomBulletAttack(5,4,3,3,"BulletPuff",0)] per
               pass, each preceded by A_CPosRefire and a round counter
damage       : 3 pellets x 3 per shot
behaviour    : counts to 16 across passes, then Reload: NOPAIN on, 60
               tics standing still, NOPAIN off. THE RELOAD IS THE FIGHT'S
               WINDOW and it cannot be interrupted by pain.
notes        : ours uses an int (rsAsgAmmo) where CHP uses an ASGZAmmo
               inventory item capped at 16. Same mechanic.
```

## 11. Twin Abyss Bolts
```
kind         : twin abyss bolts at range
axes         : delivery:bullet payload:multi element:void trigger:burst
               role:skirmisher mobility:ground species:shotgunner
tier(s)      : T06 Abyss (AbyssSG2)
chp source   : 02_A.txt Missile
gate         : NOT closer than 800
fires        : 3 x A_SpawnProjectile("RS_AbyssZshotCH2", 36, 3,
               random(-2,2))
notes        : wants element:abyss; void is the nearest live value.
```

## 12. Leaping Shotgun and Splash Rain
```
kind         : three-stage leaping shotgun with splash rain
axes         : delivery:bullet payload:multi element:void trigger:burst
               role:bruiser mobility:ground species:shotgunner
tier(s)      : T06 Abyss
chp source   : 02_A.txt Jumper
gate         : closer than 800
fires        : three rounds of [A_CustomBulletAttack(6,7,random(2,4),1..2)
               + 8 x SplashAbyss2 at CMF_OFFSETPITCH + a 47-splash rain
               over a 128..328 x -178..178 footprint], hopping backward
               between them
behaviour    : fires, carpets the ground, hops AWAY, fires again. Twice.
               The most spatially complex attack in the family.
```

## 13. Five-Way Fireblu Shell
```
kind         : five-way fireblu shell
axes         : delivery:bullet payload:multi element:thermal trigger:semi
               role:skirmisher mobility:ground species:shotgunner
tier(s)      : T07 Fireblu (FireBluSG2)
chp source   : 02_F.txt Missile
fires        : 5 x A_SpawnProjectile("RS_FireSGguy", 34, <ofs>, <angle>)
               at (-2,0) (6,8) (9,13) (-13,-13) (-10,-8)
behaviour    : Pain sets NOPAIN permanently — hurt it once and it never
               flinches again.
```

## 14. Twenty Mud Pellets
```
kind         : twenty-pellet mud spray in two pitch bands
axes         : delivery:bullet payload:multi element:kinetic trigger:burst
               role:bruiser mobility:ground species:shotgunner
tier(s)      : T08 Bodyguard (BrownSG2)
chp source   : 02_BR.txt Fire1
gate         : closer than 500
fires        : 10 x BrownSGshot at CMF_OFFSETPITCH random(-9,1), then
               10 more at random(-1,9)
behaviour    : two opposite pitch bands fired back to back, so the cloud
               is tall rather than wide. Opened with "SSGUNER/SSG".
notes        : wants element:mud. Left off rather than invented.
```

## 15. Mud Charge
```
kind         : dirt-trailing bull rush
axes         : delivery:melee payload:single element:kinetic trigger:semi
               role:bruiser mobility:ground species:shotgunner
tier(s)      : T08 Bodyguard
chp source   : 02_BR.txt GetCloser
fires        : A_SkullAttack(24) — twice the hazmat's speed
behaviour    : throws Drt1/Drt2/Drt3 before launching. It also trails
               dirt while merely walking (See).
```

## 16. Sniper Shot
```
kind         : single long-range sniper shot
axes         : delivery:bullet payload:single element:kinetic trigger:semi
               role:artillery mobility:ground species:shotgunner
tier(s)      : T09 Gray (GraySG2)
chp source   : 02_GY.txt Fire1
gate         : closer than 800
fires        : A_CustomBulletAttack(1, 0, 1, random(5,20), BulletPuff, 16000)
damage       : random(5,20) — the family's hardest single bullet
notes        : range 16000, spread 1. Effectively perfect accuracy at any
               distance the map allows.
```

## 17. Dig-In Turret
```
kind         : permanent emplacement that becomes a sniper turret
axes         : delivery:bullet payload:single element:kinetic
               trigger:semiauto role:artillery mobility:ground
               species:shotgunner
tier(s)      : T09 Gray
chp source   : 02_GY.txt GetReady / Fire2
gate         : NOT closer than 800
fires        : A_CustomBulletAttack(1, 0, 1, random(5,20), BulletPuff,
               16000) on a long face-ramp, then A_MonsterRefire(180)
               back into itself
behaviour    : squashes to 0.3 height over three steps, drops Speed to 2,
               sets NOPAIN, and NEVER UNDOES ANY OF IT. Once dug in it is
               a turret for the rest of its life. The face-ramp
               (6,6,5,5,4,4,3,3,3) is a visible wind-up you can leave
               cover during.
notes        : ours uses rsSniperReady where CHP uses User_Ready. Neither
               ever resets — faithful.
```

## 18. Red Mess Volley
```
kind         : five-projectile scattered volley
axes         : delivery:bullet payload:multi element:kinetic trigger:burst
               role:bruiser mobility:ground species:shotgunner
tier(s)      : T10 Red (RedSG)
chp source   : 02_R.txt Missile
gate         : NOT closer than 650
fires        : 5 x A_SpawnProjectile("RS_RedMessImp3", <34..42>,
               <12 / random(4,8) / random(14,26) / 12 / random(6,18)>)
```

## 19. Jamming Spray
```
kind         : fifteen-to-twenty pellet spray that jams the gun
axes         : delivery:bullet payload:multi element:kinetic trigger:burst
               role:bruiser mobility:ground species:shotgunner
tier(s)      : T10 Red
chp source   : 02_R.txt Shotgunned / Jammed
gate         : closer than 650
fires        : A_CustomBulletAttack(11.2, 7.1, random(15,20), random(1,3))
damage       : 15..20 pellets x random(1,3)  =  15..60
behaviour    : ONE spray, then the gun jams. Jammed: 8 tics, a
               "sshotl" rack, 10 more tics. Fire once, free window.
notes        : ours uses rsShotgunJam where CHP uses a ShotgunWhere
               inventory token. Same mechanic.
```

## 20. Squad Summon
```
kind         : four-trooper spec-ops squad
axes         : delivery:radial payload:multi trigger:semi role:summoner
               mobility:ground species:shotgunner trait:summoned
tier(s)      : T11 Crew Commander (BlackSG3)
chp source   : 02_K.txt Summon (:38-47)
fires        : 4 x RS_BlackSGTrooper at +/-5 unit offsets, SXF_SETMASTER
behaviour    : three "ZSpecOps/Sight" calls at ATTN_NONE — heard across
               the whole map — then four troopers materialise on top of
               the commander and fan out under their own five-stance AI.
notes        : THIS WAS THE FAMILY'S BROKEN MECHANIC until 2026-08-05; it
               summoned four T07 fireblu kamikazes. See
               zscript/monsters/RS_BlackSGTrooper.zs. The troopers share
               Species "BlackSG" with the commander so the squad never
               infights itself.
```

## 21. Commander's Burst
```
kind         : detonating-puff burst with a grenade branch
axes         : delivery:bullet payload:multi element:explosive
               trigger:burst role:boss mobility:ground species:shotgunner
tier(s)      : T11 Crew Commander
chp source   : 02_K.txt Shotgunned
gate         : closer than 500
fires        : A_CustomBulletAttack(random(1,12), random(1,12),
               random(3,9), random(1,8), "RS_DetoPuffCG")
behaviour    : the SPREAD ITSELF IS ROLLED, not just the damage — the
               same attack is a tight burst or a wild one. 1-in-4 into
               the gas nade. Re-enters Missile if still within 450.
```

## 22. Sniper Mark
```
kind         : marked detonation on the target
axes         : delivery:radial payload:single element:explosive
               trigger:semi role:boss mobility:ground species:shotgunner
tier(s)      : T11 Crew Commander
chp source   : 02_K.txt Snipe
fires        : A_VileTarget("RS_DetoPuffCG2")
behaviour    : two A_CheckSight aborts and a map-wide "ZSpecOps/Sight"
               call during an 8+1+5+1+1 tic wind-up. Break line of sight
               during the call and it does not land.
```

## 23. Airstrike
```
kind         : called airstrike on a placed marker
axes         : delivery:radial payload:multi element:explosive
               trigger:semi role:artillery mobility:ground
               species:shotgunner
tier(s)      : T11 Crew Commander
chp source   : 02_K.txt AirStrike
fires        : A_VileTarget("RS_CHBSTarget") then
               A_SpawnProjectile("RS_AirStrikeCHBS", 64, 0, 1)
behaviour    : plants a marker ON you, then calls the strike to the
               marker. Moving after the marker lands is the counterplay.
```

## 24. Gas Grenade
```
kind         : arcing gas grenade
axes         : delivery:heavy payload:single element:melt trigger:semi
               role:skirmisher mobility:ground species:shotgunner
tier(s)      : T11 Crew Commander, and RS_BlackSGTrooper (Aggressive)
chp source   : 02_K.txt Nadetoss (:1836-1840 for the trooper)
fires        : A_SpawnProjectile("RS_SGGasNade", 48, 0, random(-3,3), 0,
               random(3,12))
notes        : the pitch roll random(3,12) is an ARC, not spread — the
               grenade is lobbed, so cover does not stop it.
```

## 25. Mine Scatter
```
kind         : four lobbed mines on random arcs
axes         : delivery:heavy payload:multi element:explosive trigger:burst
               role:artillery mobility:floating species:shotgunner
tier(s)      : T12 Benellus, TEX Green Benellus
chp source   : 02_W.txt Gifts / 02_WX.txt Gifts
fires        : 4 x A_SpawnProjectile("RS_MineShotgun", random(20,60),
               random(-15,15), random(-20,20), 0)
behaviour    : area denial rather than aimed damage; opened with two
               map-wide DSDBLOAD / DSDBCLS calls.
```

## 26. Punisher Guns
```
kind         : summoned emplacement that fires on its own
axes         : delivery:bullet payload:multi element:kinetic
               trigger:fullauto role:summoner mobility:floating
               species:shotgunner trait:summoned
tier(s)      : T12 Benellus, TEX
chp source   : 02_W.txt Punisher / 02_WX.txt Rounded
fires        : A_VileTarget("RS_ShotgunPunisher")
notes        : TEX plants TWO RS_ShotgunShrine behind the punisher on the
               same pass (entry 28) — the shrines are the follow-up, not
               an alternative.
```

## 27. Benellus Shotgun
```
kind         : the god's own shotgun
axes         : delivery:bullet payload:multi element:kinetic trigger:semi
               role:boss mobility:floating species:shotgunner
tier(s)      : T12 Benellus, TEX
chp source   : 02_W.txt SG / 02_WX.txt SG
behaviour    : T12 and TEX both hover (+FLOAT +NOGRAVITY +FLOATBOB), so
               every Benellus attack is delivered from the air. TEX was
               WALKING until 2026-08-05 — see INDEX.md.
```

## 28. Spark Storm and Shrines
```
kind         : forty-spark barrage that plants two shrines
axes         : delivery:radial payload:multi element:plasma
               trigger:fullauto role:boss mobility:floating
               species:shotgunner trait:ex
tier(s)      : TEX Green Benellus
chp source   : 02_WX.txt ShotgunRounded / Shrines
fires        : 20 x RS_SparkPuff1 on 1-tic frames + 9 more on 0-tic,
               then EITHER A_Jump(64) to Shrines OR
               A_VileTarget("RS_ShotgunPunisher") — and either way two
               RS_ShotgunShrine at random(-128,128) x random(-1,178) and
               random(-178,1)
behaviour    : the shrines go down BEHIND you, on both sides. It builds
               the arena while it fights.
```

## 29. Focused Volley
```
kind         : aimed 8000-range volley
axes         : delivery:bullet payload:multi element:kinetic trigger:burst
               role:artillery mobility:floating species:shotgunner
               trait:ex
tier(s)      : TEX Green Benellus
chp source   : 02_WX.txt FocusedHitScan / FocusedFire
gate         : NOT closer than 1500, then A_Jump(170)
notes        : same 8000-unit reach as the cyan sergeant's frost buckshot
               (entry 5). Distance is not an answer to this tier.
```

## 30. The Blink
```
kind         : short teleport that breaks your lead
axes         : delivery:melee payload:single trigger:semi role:boss
               mobility:floating species:shotgunner trait:ex
tier(s)      : TEX Green Benellus
chp source   : 02_WX.txt Tele
fires        : nothing — 4 tics of A_Wander
behaviour    : four tics is enough to invalidate a led shot. Entered from
               pain, so punishing it is what triggers it.
```

## 31. Trooper Stance Cycle
```
kind         : five-stance squad AI, re-rolled continuously
axes         : delivery:bullet payload:multi element:explosive
               trigger:burst role:skirmisher mobility:ground
               species:shotgunner trait:summoned
tier(s)      : RS_BlackSGTrooper (summoned by T11)
chp source   : 02_K.txt:1774/1842/1863/1884/1902
               roll at Shotgunners.txt:2241
fires        : A_CustomBulletAttack(8, 6, 7, 4, "RS_DetoPuffCG") in
               Aggressive, Creep and Berserk; Sprint and Wander have NO
               missile state at all
behaviour    : wipes its stance flags on every See entry and re-rolls off
               health-below-50, line of sight, and range 384/768. Every
               leaf is a coin flip or three-way, so two troopers in the
               same situation diverge.
notes        : the closest thing in this family to a data-driven attack
               rotation, and the obvious first candidate if monster
               PACK profiles ever drive states rather than describe them.
```

---

## What this catalog does NOT cover

* **The spawn-colour axis.** 15 sub-variants per tier; the Translation
  table is identical across tiers, same as family 01. Recorded, not built.
* **ACS.** Only one touchpoint was found incidentally — T03's
  `CH_CyanBounce` suppression gate. Nobody has swept `02_*` for the rest,
  so the `acs:` line is omitted rather than asserted as "none".
* **Attack profiles.** No entry above has a real `profile:` line except
  entry 1's placeholder, because `RS_AttackProfile` still cannot express
  bullet counts, jam/reload cycles, or rail beams. Writing profiles that
  drop those would claim a fidelity the system does not have — the same
  call family 01 made on its hitscan tiers.
