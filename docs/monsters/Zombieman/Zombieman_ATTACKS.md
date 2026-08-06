# ZOMBIEMAN — ATTACK CATALOG

Format: `docs/rs_35_monster_attack_catalog_spec.txt`. Field order and the shape
vocabulary are that spec's, unaltered. No shape word here is coined.

**Family** Zombieman (Colourful Hell colour ladder, tiers 1–13)

**Denominator actually read — every line of both files, comments stripped
before every count:**

| thing | count |
|---|---|
| classes read | **108** — 58 in `RS_Zombieman.zs`, 50 in `RS_ZombiemanFX.zs` |
| state labels in the monster file | 278 |
| attack-verb call **lines** (`A_CustomMissile` / `A_CustomBulletAttack` / `A_CustomRailgun` / `A_CustomMeleeAttack` / `A_PosAttack`) | 87 — all 87 in `RS_Zombieman.zs`, 0 in the FX file |
| `A_Explode` lines | 11 — 6 monster file, 5 FX file |
| `A_RadiusGive` lines | 5 — all monster file |
| monsters carrying at least one damaging attack | **16** |
| **ATTACK rows written** | **47** |
| SUPPORT rows written (real profiles, zero damage) | 10 |

Sources: `E:\RS_Main\zscript\monsters\zombieman\RS_Zombieman.zs`,
`E:\RS_Main\zscript\monsters\zombieman\RS_ZombiemanFX.zs`, diffed against CH's
`decorate/Zombies.txt` (see UNRESOLVED §1 for where CH actually is on this
machine — **not** the path the spec names). Engine semantics were read out of
the GZDoom source on this machine, not assumed; see §"Engine facts" below.

---

## WHAT WAS EXCLUDED, AND WHY THAT IS A RESULT

Excluding these correctly is part of the job — counting any of them as a
payload would be a silent error that no check in this repo can catch.

* **76 tier-icon spawn sites are NOT attacks.** `RS_ColorTierIconCH` and its
  **12** subclasses (`…CH2`–`…CH13`, `RS_ZombiemanFX.zs:81–117`) are
  `Radius 1 / Height 1 / +NOINTERACTION` cosmetics whose whole body is
  `TI3R <frame> 30 Bright`, gated behind the `rs_ch_colorblind` cvar and
  **defaulted OFF** (`RS_ZombiemanFX.zs:96`). They carry no `Damage`, no
  `DamageFunction`, no `A_Explode`. 89 lines in the two files mention the
  class family; 13 of those are the class declarations, leaving **76 live
  `A_SpawnItemEx` sites**. All 76 excluded.
* **5 drop classes are NOT attacks.** `RS_CH_Clip`, `RS_CH_Shell`,
  `RS_CH_Cell`, `RS_CH_RocketBox`, `RS_CH_RocketAmmo` all derive from
  `RS_DropBaseAmmo` (`RS_ZombiemanFX.zs:370`), whose only verb is
  `A_SpawnItemEx` of a pickup behind the `rs_ch_ammodrops` cvar. Excluded.
  So are `RS_DropBaseItem` and the seven `RS_CH_*` item/weapon droppers.
* **`RS_BoneStormer1` and its 6 subclasses ARE real attacks** — resolved, not
  assumed. `RS_Zombieman.zs:2711` gives the base
  `DamageFunction (random(1,3))`, `Speed 120`, `+RIPPER`, `+FORCEPAIN`.
  Subclasses 2–7 override only `Speed` and the warp radius/height.
  They are the bone tornado's damage body — see the row
  `RS_BoneStormer1 .. RS_BoneStormer7`.
* **`RS_SplashAbyss` is cosmetic; `RS_SplashAbyss2` is not.** The parent
  (`RS_ZombiemanFX.zs:707`) declares no damage at all — 90 of them are spawned
  in every `Pain.AbyssPE` and they hurt nobody. The child
  (`RS_ZombiemanFX.zs:735`) adds `DamageFunction (random(1,9))` +
  `DamageType "Ice"`. Only the child is rowed.
* **`RS_IceZombieShot2`, `RS_AbyssZShotCH2`, `RS_AbyssZShotCH3` are defined
  here and fired by nobody in this family.** Not dead code: they are
  cross-family payloads, exactly as in CH, which also defines them in
  `Zombies.txt` and fires them from `Chaingunners.txt` / `Shotgunners.txt`.
  Ours are consumed at `zscript/monsters/chaingunner/RS_Chaingunner.zs:416`
  (+11 more), `:561` (+3 more), and
  `zscript/monsters/shotgunner/RS_Shotgunner.zs:423`, `:665`. No zombieman row.
* Not attacks either: `Pain.AbyssPE` (transformation), `Grow` / `AbyssGrow`
  (tier promotion), `CellEject`, `Taunt`, `Raise`, `Vanish`, `IStuck`,
  `Reset`, the eight cvar-gated spawn-dial stubs, `RS_ZombieColourset`,
  `RS_CH_Pantsu`, `RS_SpirZom`/`2`, `RS_AbyssShotIdentifier`,
  `RS_Drt2`/`RS_Drt3`, `RS_RedThingsHK`. Several of these carry real
  behaviour and appear in the SUPPORT section.

---

## ENGINE FACTS THIS CATALOG DEPENDS ON

Read from the GZDoom tree on this machine (`E:\UZDXREMA` — see UNRESOLVED §1),
not from memory. Every damage figure below follows from these.

1. **`A_CustomBulletAttack` multiplies.** `damage = damageperbullet *
   random(1,3)` unless `CBAF_NORANDOM` is set
   (`wadsrc/static/zscript/actors/attacks.zs:47,86-88`). **No call site in
   this family passes a `flags` argument** — the one that looks like it does,
   `A_CustomBulletAttack(22.5,5,8,6,"BulletPuff",0)`, is passing `range=0`
   in the 6th positional slot, not flags. So *every* hitscan damage number in
   this file is `d × random(1,3)`, and writing the bare `d` would be a 3×
   understatement.
2. **`A_CustomBulletAttack`'s `spread_xy` IS the half-cone in degrees.**
   `pangle += spread_xy * Random2()/255.`, and `Random2()` returns
   `(r&255)-(r&255)` ∈ [−255,+255] (`src/common/engine/m_random.h:72-77`).
   Triangular, mode 0. Same for `spread_z` on pitch.
3. **`A_PosAttack` is hardcoded**, not driven by the actor's `AttackSound` or
   properties (`wadsrc/static/zscript/actors/doom/possessed.zs:267-279`):
   1 bullet, `damage = random(1,5)*3` → {3,6,9,12,15}, cone
   `Random2() * 22.5/256` → ±22.4° triangular, puff `BulletPuff`, and it
   plays the literal string `"grunt/attack"` on `CHAN_WEAPON` itself.
4. **`A_CustomMissile(type, spawnheight=32, spawnofs_xy=0, angle=0, flags=0,
   pitch=0, ptr=AAPTR_TARGET)`** (`compatibility.zs:131`). `flags 32` =
   `CMF_OFFSETPITCH`.
5. **`A_SpawnItemEx(…, flags, failchance, tid)`** — the 10th argument is a
   **fail** chance out of 256 (`attacks.zs:412,417`). `failchance 250` means
   the thing spawns **6/256 ≈ 2.3 %** of the time, not 98 %.
6. **`A_MonsterRefire(prob, label)` reads backwards from the obvious.**
   `if (random() < prob) return null` — i.e. `prob/256` is the chance to
   **keep firing unconditionally**; only on the other branch does it break to
   `label`, and then only if the target is dead/lost/friend-blocked
   (`src/playsim/p_actionfunctions.cpp:2866-2886`). `A_MonsterRefire(128,…)`
   is therefore "50 % keep firing no matter what, 50 % keep firing if the
   target is still there" — a *very* sticky loop, not a coin flip.
7. **`A_SentinelRefire`** continues on 30/256 outright, else breaks to `See`
   on target-lost or a further 40/256 roll — ≈ **86 % continue per call**
   with a live target (`wadsrc/static/zscript/actors/strife/sentinel.zs:164`).
8. **Actions fire once per FRAME, not once per line.** `MAGE FFFFFFFFF 0
   A_CustomMissile(...)` is **nine** missiles. Every count below is
   frame-expanded.

## HOW TO READ THE `profile` LINES

`RS_AttackProfile`'s final spread is
`(100 − Accuracy) × SpreadScale × choke + SpreadBonus`
(`zscript/systems/weapon/RS_AttackProfile.zs:648` in `RS_Weapon.zs`). To
reproduce a monster's **exact** degree cone independent of the wearing gun's
rolled Accuracy, the translation is `spreadScale: 0.0` plus
`p.SpreadBonus = <degrees>`. Pellet counts need `p.PelletOverride`, and range
bands need `p.MinRange` / `p.MaxRange`. None of those three are factory
parameters, so rows that need them show the factory call followed by the field
sets. This is stated once here and not repeated per row.

---
---

# ATTACK ROWS

Grouped by monster, in the file's own CH tier order
(1 Common → 13 Brown, then the non-tier bone actors).

---

## TIER 1 — RS_CommonZombie

    ATTACK   RS_CommonZombie.Missile
    file     zscript/monsters/zombieman/RS_Zombieman.zs:927  (class; state INHERITED)
             engine: wadsrc/static/zscript/actors/doom/possessed.zs:33-36
    shape    HITSCAN
    payload  --  (BulletPuff, hardcoded in A_PosAttack)  x1
    arc      ±22.4 horizontal (Random2 x 22.5/256, triangular), 0 vertical
    timing   10,8,8   (26 tics: raise, fire, lower)
    damage   random(1,5)*3   -> {3,6,9,12,15}
    type     Hitscan
    sound    "grunt/attack" -- played by A_PosAttack ITSELF, not by the
             actor's AttackSound property (engine, possessed.zs:274)
    impact   BulletPuff (vanilla), hardcoded
    trigger  Missile
    range    --
    mirrored no
    inherit  ZombieMan -- RS_CommonZombie DELIBERATELY does not override
             Missile. Its Default block is stats + drops + the CH death web
             only. The vanilla state IS the attack.
    profile  MakeHitscan(fireSnd:"grunt/attack", spreadScale:0.0,
                 profName:"zombie rifle"); p.SpreadBonus = 22.4;
                 p.PelletOverride = 1;
    notes    THE BASELINE. Every other rung on this ladder is measured
             against 26 tics for one 3..15 bullet. Nothing in the class body
             names an attack -- a reader who greps RS_CommonZombie for
             A_CustomMissile finds nothing and concludes it has no attack.

---

## TIER 2 — RS_GreenZombie

    ATTACK   RS_GreenZombie.Missile
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1091
    shape    MULTI
    payload  BulletPuff (via A_PosAttack) x2  +  RS_Gas11 x3
    arc      bullets ±22.4 each; gas single, unaimed (angle 0)
    timing   0,10,8,8,10,8,8   (52 tics)
    damage   bullets random(1,5)*3 each;
             gas RS_Gas11 has NO contact damage -- its damage is
             A_Explode(random(1,8),32) on FOUR frames of its Death state
             (RS_Zombieman.zs:1035: PSBG FGHI 6) = 4 separate 1..8 blasts
             in a 32-unit radius over 24 tics.
    type     bullets Hitscan; gas Poison
    sound    "grunt/attack" x2 (from A_PosAttack). The gas is SILENT --
             RS_Gas11 declares no SeeSound and no DeathSound.
    impact   gas cloud is stationary (Speed 0, FastSpeed 0) and ticks four
             times; PSBG C-E spawn -> F-I death, RenderStyle Add, Alpha 0.6
    trigger  Missile
    range    --
    mirrored no
    inherit  RS_Gas11 : Actor (RS_Zombieman.zs:1014) -- self-contained
    profile  two profiles in one slot:
             MakeHitscan(fireSnd:"grunt/attack", spreadScale:0.0,
                 profName:"green rifle"); p.SpreadBonus = 22.4;
             MakeVolley(proj:"RS_Gas11", count:1, profName:"poison cloud")
    notes    The order is gas / aim / SHOOT / gas / aim / SHOOT / gas -- the
             cloud is laid BEFORE the first bullet, so the space in front of
             the zombie is already poisoned when you close. Exits to See2,
             never to See: once it has fired it gasses on every walk lap
             forever.

    ATTACK   RS_GreenZombie.<gas puff>
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1088  (See2, Walk)
             zscript/monsters/zombieman/RS_Zombieman.zs:1117  (Pain)
             zscript/monsters/zombieman/RS_Zombieman.zs:1125  (Death)
    shape    SINGLE
    payload  RS_Gas11 x1
    arc      --
    timing   one tic (0-tic in See2; on the 3-tic Pain frame; on the 5-tic
             Death frame)
    damage   A_Explode(random(1,8),32) x4 frames -- see above
    type     Poison
    sound    --   (RS_Gas11 is silent by declaration; correct as a profile
             slot, the gun's own sound fills it)
    impact   stationary cloud, 24 tics, four 1..8 blasts at radius 32
    trigger  Walk | Pain | Death   -- three beats, identical call
    range    --
    mirrored no
    inherit  --
    profile  ONE shape, THREE profiles differing only in FireTrigger:
             MakeVolley(proj:"RS_Gas11", count:1, profName:"gas puff");
             p.FireTrigger = RS_FIRE_WALK / RS_FIRE_PAIN / RS_FIRE_DEATH
    notes    Collapsed to one row on purpose: the call is byte-identical at
             all three sites, so three rows would be three copies of the same
             part. The BEAT is the only thing that differs and FireTrigger
             carries it. Do not collapse further -- FireBlu's walk and pain
             sheds below have different arguments and are two rows.

    ATTACK   RS_GreenZombie.XDeath
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1152
    shape    FAN
    payload  RS_Gas11 x3
    arc      14  (-7, 0, +7 -- exactly three steps, not a random spread)
    timing   5,0,0   (the centre cloud on a 5-tic frame, the two wings on
             0-tic frames the same tic)
    damage   A_Explode(random(1,8),32) x4 frames, per cloud -- so up to
             twelve 1..8 blasts overlapping
    type     Poison
    sound    --
    impact   three stationary clouds, centre at spawnheight 49, wings at 32
    trigger  XDeath
    range    --
    mirrored no  (the -7/+7 pair is the fan itself, not a mirrored variant)
    inherit  --
    profile  MakeVolley(proj:"RS_Gas11", count:3, arc:14,
                 profName:"death gas fan"); p.FireTrigger = RS_FIRE_XDEATH;
    notes    OUR TREE DIFFERS FROM CH ON THE SPRITE FRAME AND ONLY THAT.
             CH (Zombies.txt:973-975) writes `ZOMG U`; ZOMG ships N-T only
             (7 lumps) in CH itself, so CH's corpse is invisible for the
             5 tics in which it bursts. Ours holds `ZOMG T`
             (RS_Zombieman.zs:1152-1154, fixed 2026-08-06, owner-authorised).
             Frame count, tic count, spawn heights and angles are unchanged.
             Recorded here because the row cites a line that is not
             byte-identical to CH.

---

## TIER 3 — RS_BlueZombie

    ATTACK   RS_BlueZombie.Missile
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1220
    shape    HITSCAN
    payload  BulletPuff x3, all on ONE tic
    arc      ±7 horizontal, ±7 vertical (triangular)
    timing   10,7,8   (25 tics)
    damage   random(1,2) * random(1,3) per bullet -> 1..6 each, 3..18 total
    type     Hitscan
    sound    AttackSound "grunt/attack" -- A_CustomBulletAttack plays the
             ACTOR's AttackSound once per call (attacks.zs:69), so ONE
             report for all three bullets, not three
    impact   BulletPuff (default)
    trigger  Missile
    range    --
    mirrored no
    inherit  ZombieMan (stats), but Missile is fully overridden
    profile  MakeHitscan(fireSnd:"grunt/attack", spreadScale:0.0,
                 profName:"blue triple"); p.PelletOverride = 3;
                 p.SpreadBonus = 7.0;
    notes    A THREE-PELLET SHOTGUN THAT SOUNDS LIKE A RIFLE. Maps onto a
             player gun almost unchanged: one trigger pull, three pellets,
             7-degree cone, 25-tic cycle. Damage is deceptively low --
             `random(1,2)` looks like 1..2 until the engine's x random(1,3)
             is applied (Engine fact 1).

---

## TIER 4 — RS_PurpleZombie

Router: `RS_Zombieman.zs:1370` — `A_JumpIfCloser(800,"Hitscanne")`, else
`A_Jump(255,"Orbb")`.

    ATTACK   RS_PurpleZombie.Hitscanne
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1374
    shape    HITSCAN
    payload  BulletPuff x3 then x2  (5 bullets, two pulls)
    arc      first pull ±9 h / ±9 v; second pull ±7 h / ±7 v
    timing   10,7,4,8   (29 tics per pass, then refires)
    damage   random(1,2) * random(1,3) per bullet -> 1..6 each, 5..30 total
    type     Hitscan
    sound    AttackSound "grunt/attack", once per A_CustomBulletAttack call
             -> TWO reports per pass
    impact   BulletPuff
    trigger  Missile   (via A_JumpIfCloser(800) from Missile)
    range    ..800
    mirrored no
    inherit  ZombieMan (stats only)
    profile  two entries in one slot, fired 4 tics apart:
             MakeHitscan(fireSnd:"grunt/attack", spreadScale:0.0,
                 profName:"purple burst A"); p.PelletOverride = 3;
                 p.SpreadBonus = 9.0; p.MaxRange = 800;
             MakeHitscan(...same...); p.PelletOverride = 2;
                 p.SpreadBonus = 7.0; p.MaxRange = 800;
    notes    The cone TIGHTENS on the follow-up (9 -> 7) while the count
             drops (3 -> 2) -- a deliberate "double-tap, second one aimed".
             Ends on A_MonsterRefire(128,"See"), which per Engine fact 6 is
             a very sticky loop, not a 50/50 exit.

    ATTACK   RS_PurpleZombie.Orbb
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1380
    shape    BURST
    payload  RS_Orbb11 x3
    arc      --  (all three at angle 0, aimed)
    timing   5,5,5,5   (20 tics; the three orbs 5 tics apart)
    damage   DamageFunction (random(2,18)) per orb
    type     Plasma
    sound    SeeSound "Weapons/Plasmaf" per orb (three reports)
    impact   BAL1 CDE 6 Bright, DeathSound "weapons/plasmax". No explosion,
             no splash -- contact damage only.
    trigger  Missile   (via the A_Jump(255,"Orbb") fallthrough at :1371)
    range    800..
    mirrored no
    inherit  RS_Orbb11 : Actor (RS_Zombieman.zs:1285) -- self-contained
    profile  MakeBurst(proj:"RS_Orbb11", count:3, delayTics:5,
                 fireSnd:"Weapons/Plasmaf", profName:"seeker orb burst");
                 p.MinRange = 800;
    notes    THESE HOME. +SEEKERMISSILE plus `A_SeekerMissile(2,3)` on every
             other Spawn frame (:1308) -- 2 degrees of turn, 3 = "chase even
             without line of sight". Also A_Weave(5,4,2,1), so they corkscrew
             while tracking. Speed 21, FastSpeed 32, Scale 0.3.
             The A_Jump(255,...) at :1371 is 255/256, so ~1 pass in 256 at
             long range falls through into Hitscanne instead. Verbatim CH.

---

## TIER 5 — RS_YellowZombie (Orange Zombiewoman)

Router: `:1535` `A_JumpIfCloser(550,"Bullets")`, else `:1536` to `RocketsOr`,
which is `A_Jump(255,"Rockets","Bullets")` — a 50/50 between the two.

    ATTACK   RS_YellowZombie.Bullets
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1543
    shape    HITSCAN
    payload  BulletPuff x1, three times
    arc      WIDENS: ±4, then ±7, then ±9 (h and v equal each time)
    timing   0,3,2,3,2,3,2   (15 tics; the three shots 5 tics apart)
    damage   random(1,3) * random(1,3) per bullet -> 1..9 each
    type     Hitscan
    sound    A_PlaySound("chainguy/attack") ONCE at :1542, plus the
             INHERITED AttackSound "grunt/attack" on each of the three
             A_CustomBulletAttack calls. RS_YellowZombie's own Default block
             sets SeeSound/PainSound/DeathSound/ActiveSound but NOT
             AttackSound -- it takes ZombieMan's. Four sounds per burst.
    impact   BulletPuff
    trigger  Missile   (A_JumpIfCloser(550) or the RocketsOr coin flip)
    range    ..550  (also reachable at any range via RocketsOr)
    mirrored no
    inherit  ZombieMan -- and the missing AttackSound is why it grunts
    profile  three entries, 5 tics apart:
             MakeHitscan(fireSnd:"chainguy/attack", spreadScale:0.0,
                 profName:"walking burst 1"); p.PelletOverride = 1;
                 p.SpreadBonus = 4.0;
             ... same with SpreadBonus 7.0, then 9.0
    notes    THE CONE OPENS AS THE BURST GOES ON -- the opposite of Purple's
             tightening double-tap, and the reason this reads as "spraying".
             A_FaceTarget between shots 1-2 and 2-3 (:1544,:1546) so it
             tracks you mid-burst.

    ATTACK   RS_YellowZombie.Rockets
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1552
    shape    SINGLE
    payload  RS_MiniRKTZombie x1
    arc      random(-2,2) jitter
    timing   0,3,2,2   (7 tics), then refires
    damage   DamageFunction (random(5,40)) on contact,
             + A_Explode(random(5,15),58) on ONE frame of Death (:1466)
    type     Fire
    sound    SeeSound "weapons/rocklf"
    impact   MISL B 8 Bright A_Explode(random(5,15),58) / MISL C 6 /
             MISL D 4, DeathSound "weapons/rocklx". +DEHEXPLOSION so the
             blast follows Dehacked rules; +ROCKETTRAIL for the smoke.
             Scale 0.4 -- a visibly small rocket.
    trigger  Missile
    range    550..  (also reachable at any range via RocketsOr)
    mirrored no
    inherit  RS_MiniRKTZombie : Actor (RS_Zombieman.zs:1443)
    profile  MakeHeavy(proj:"RS_MiniRKTZombie", fireSnd:"weapons/rocklf",
                 profName:"mini rocket"); p.MinRange = 550;
             -- the jam is a SEPARATE support profile, see S-7
    notes    LAUNCHER JAMS AFTER THREE. `A_GiveInventory("RS_RocketCounter",1)`
             at :1553; `A_JumpIfInventory("RS_RocketCounter",3,"Jammed")` at
             :1551. RS_RocketCounter has Inventory.MaxAmount 3
             (:1473). Three rockets, then a 64-tic jam. That cadence is the
             tier's identity and belongs with the rocket, not apart from it.

---

## TIER 6 — RS_RedZombie (ZombieUnman)

Router: `:1688` `A_Jump(64,"Missile2")` — 64/256 = 25 % to the rail barrage.

    ATTACK   RS_RedZombie.Missile
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1690
    shape    HITSCAN
    payload  RS_BloodyPuff x1
    arc      ±2 horizontal, ±2 vertical -- the tightest cone in the family
    timing   15,10,10   (35 tics)
    damage   random(5,25) * random(1,3) -> 5..75 from ONE bullet
    type     Hitscan
    sound    AttackSound "zombie/unmaker"  (resolves: SNDINFO:682 ->
             DSUNMKER, lump present at sounds/monsters/DSUNMKER.wav)
    impact   RS_BloodyPuff (RS_Zombieman.zs:1618) -- DBLD A 4 Bright /
             DBLD BCD 4, +PUFFONACTORS +EXTREMEDEATH. The EXTREMEDEATH is
             the point: this puff GIBS whatever it kills.
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeHitscan(fireSnd:"zombie/unmaker", spreadScale:0.0,
                 impactPuff:"RS_BloodyPuff", profName:"unmaker slug");
                 p.PelletOverride = 1; p.SpreadBonus = 2.0;
    notes    THE HARDEST-HITTING SINGLE BULLET IN THE FAMILY. 5..75 is not
             obvious from the source: `random(5,25)` looks like a 25 cap
             until Engine fact 1 is applied. Slow (35 tics) and pinpoint
             (2 degrees) -- it is a designated marksman, and the puff makes
             every kill a gib.

    ATTACK   RS_RedZombie.Missile2
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1696
    shape    HITSCAN
    payload  --  (instant rail trace; A_CustomRailgun, no projectile actor)
    arc      --  (spread_xy and spread_z both default 0: perfectly straight)
    timing   16,0,1,0,1,0,1,0,1,0,1,10   (31 tics for five beams), then loops
    damage   random(5,20) per beam. NOT multiplied -- A_CustomRailgun takes
             damage directly, unlike A_CustomBulletAttack.
    type     Hitscan (rail default)
    sound    A_PlaySound("zombie/unpower") before EACH of the five beams
             (:1695,1697,1699,1701,1703) -- five reports, one per beam
    impact   default rail puff/trail. color1 fades FF -> CC -> 99 -> 55 -> 33
             red across the five beams; color2 is 0 (black) throughout.
    trigger  Missile   (via A_Jump(64) from Missile, 25 %)
    range    --
    mirrored no
    inherit  --
    profile  MakeHitscan(fireSnd:"zombie/unpower", spreadScale:0.0,
                 profName:"unmaker rail"); p.PelletOverride = 1;
                 p.SpreadBonus = 0.0;
             -- five entries in one slot, 2 tics apart.
             NOTE: RS_AttackProfile has NO rail mode. See UNRESOLVED §4.
    notes    A_CustomRailgun, not A_CustomBulletAttack -- an instant PIERCING
             trace with zero spread. HITSCAN is the right shape word (the
             spec's HITSCAN entry names two functions; this is a third
             instant-trace verb, not a projectile), but a builder must not
             read it as a bullet: rails go through everything in the line.
             The barrage does not stop at five. It ends on A_SentinelRefire
             (:1705) and `Goto Missile2+1`, which skips the 16-tic re-face:
             per Engine fact 7 that is ~86 % continue per pass with a live
             target, so the real attack is a sustained strobing red beam,
             not five shots. spawnofs_xy 4 on every beam.

---

## TIER 7 — RS_FireBluZombie2

    ATTACK   RS_FireBluZombie2.See2
    file     zscript/monsters/zombieman/RS_Zombieman.zs:555, :558
    shape    SINGLE
    payload  RS_FireSGguy2 x1 per half-lap (x2 per full walk lap)
    arc      --  (angle -180: dropped BEHIND itself)
    timing   one tic (0-tic frames inside a 2-tic chase lap)
    damage   contact DamageFunction (random(5,15))
             + A_Explode(random(3,9),64) on EIGHT frames  (:809)
             + A_Explode(random(5,15),64) on THREE frames (:810)
             = ELEVEN separate blasts per flame, over 52 tics
    type     Fire
    sound    SeeSound "imp/attack" per flame
    impact   FIRE A-B 6 Bright -> Death FIRE CDEEDCDE 5 / FIRE FGH 4 Bright.
             DeathSound "imp/shotx". +THRUACTORS, RenderStyle Add,
             Alpha 0.85, Speed 17, and a FIREBLU-palette translation.
    trigger  Walk
    range    --
    mirrored no
    inherit  RS_FireSGguy2 : Actor (RS_ZombiemanFX.zs:785; CH
             Archviles.txt:2285 -- pulled from another CH file, not Zombies)
    profile  MakeVolley(proj:"RS_FireSGguy2", count:1, fireSnd:"imp/attack",
                 profName:"fire wake"); p.FireTrigger = RS_FIRE_WALK;
    notes    THE ELEVEN A_EXPLODE FRAMES ARE DELIBERATE, NOT A BUG. This is
             the lingering-fire pattern -- the flame is a burning patch that
             ticks for ~1.5 seconds, not a single blast. Do not "optimise"
             it to one A_Explode; that is a known trap in this repo.
             `A_SpawnItemEx(...,-6,0,3,-2,0,1,-180)`: offset 6 units BACK,
             velocity -2 (backward), +1 up, facing away. It lays a fire
             trail in its own wake. Missile: (:560) is a one-line stub that
             just routes to See2 -- FireBlu HAS NO RANGED ATTACK. Chasing
             you IS the attack.

    ATTACK   RS_FireBluZombie2.Pain
    file     zscript/monsters/zombieman/RS_Zombieman.zs:582
    shape    SINGLE
    payload  RS_FireSGguy2 x1
    arc      random(0,359)  (full circle, one flame)
    timing   3   (on the first Pain frame)
    damage   as above -- eleven blasts, random(3,9) x8 then random(5,15) x3
    type     Fire
    sound    "imp/attack"
    impact   as above
    trigger  Pain
    range    --
    mirrored no
    inherit  RS_FireSGguy2
    profile  MakeVolley(proj:"RS_FireSGguy2", count:1, fireSnd:"imp/attack",
                 profName:"fire retaliation"); p.FireTrigger = RS_FIRE_PAIN;
    notes    A SEPARATE ROW from the walk shed because the arguments differ
             in every meaningful way: offset +6 (forward, not back),
             velocity +9 (thrown hard, not dribbled), yaw random(0,359)
             (anywhere, not behind). PainChance 255 -- it is hit, it flinches,
             it throws fire. Practically every hit produces one.

    ATTACK   RS_FireBluZombie2.Melee
    file     zscript/monsters/zombieman/RS_Zombieman.zs:563  (Melee entry)
             zscript/monsters/zombieman/RS_Zombieman.zs:605  (the blast)
    shape    RING
    payload  RS_FireSGguy2 x7  (5 at random(-359,359), 2 aimed at -7/+7)
    arc      360 for the five; the pair at exactly -7 and +7
    timing   5,5 (the hug), then 0,6,6,0,0,0,6   (blast at tic 10)
    damage   A_Explode(random(12,44),84) -- ONE frame, one blast, radius 84
             + each of the seven flames: eleven blasts of random(3,9)/
               random(5,15) at radius 64
    type     Fire
    sound    A_PlaySound("weapons/rocklx",7,1) at :604, then A_Quake(20,12,
             0,64,0) at :606
    impact   MISL B/C/D explosion sprite; seven independent burning patches
             left behind
    trigger  Melee  (also entered directly as XDeath when the corpse is
             gibbed -- Melee is `POSS EF 5 Bright A_FaceTarget; Goto XDeath`)
    range    melee range
    mirrored no
    inherit  RS_FireSGguy2
    profile  MakeVolley(proj:"RS_FireSGguy2", count:7, arc:360,
                 fireSnd:"weapons/rocklx", profName:"suicide burn");
                 p.FireTrigger = RS_FIRE_MELEE;
             -- the A_Explode core is NOT expressible through any factory;
                see UNRESOLVED §4.
    notes    IT KILLS ITSELF TO ATTACK. The Melee state is ten tics of
             facing you and then `Goto XDeath` -- there is no melee verb at
             all. Same chain on being gibbed, so overkilling one at close
             range does the same thing to you.
             Five flames at random(-359,359) is the spec's RING tell; the two
             at -7/+7 (:609,:610) are a small aimed pair on top. Recorded as
             one row because it is one event.
             OUR TREE vs CH: CH writes `ZOMG U` on :609-610's frames;
             ZOMG ships N-T, so ours holds `ZOMG T`. 0-tic frames either way,
             so nothing visible changes. Flagged for completeness.

---

## TIER 8 — RS_GrayZombie2

    ATTACK   RS_GrayZombie2.Missile
    file     zscript/monsters/zombieman/RS_Zombieman.zs:685
    shape    BURST
    payload  RS_ZombieRock x3
    arc      random(-2,2) per rock (4 degrees of jitter, NOT a stepped fan)
    timing   10,2,2,2,2,8   (26 tics; the three rocks 2 tics apart)
    damage   DamageFunction (random(1,12)) per rock
    type     Melee  -- INHERITED from RS_WDRock3, and genuinely "Melee" on a
             thrown projectile. Verbatim CH.
    sound    SeeSound "monster/hamflr" per rock (inherited)
    impact   JUBD D death: 4x RS_Drt2 + 4x RS_Drt3 dirt puffs at
             random(-2,2) offsets and random(0,360) yaw
             (RS_ZombiemanFX.zs:700-701). DeathSound "Butcher/melee".
    trigger  Missile
    range    --
    mirrored no
    inherit  RS_ZombieRock : RS_WDRock3 (RS_Zombieman.zs:628).
             THE CHILD OVERRIDES ONLY DamageFunction AND Scale. Speed 36,
             DamageType, both sounds, the whole Death dirt-spawn chain and
             the JUBD ABCD Bright spin all come from RS_WDRock3
             (RS_ZombiemanFX.zs:680, CH Demons.txt:2632). Reading
             RS_ZombieRock's four-line body reports "no impact FX" for an
             attack that has eight dirt spawns and two sounds.
    profile  MakeBurst(proj:"RS_ZombieRock", count:3, delayTics:2,
                 fireSnd:"monster/hamflr", profName:"rock volley");
    notes    Speed 4 -- the slowest walker in the family. It cannot chase, so
             it plants and throws. Scale 0.25 on the child vs 0.7 on the
             parent: these are pebbles, not the Butcher's boulder.

    ATTACK   RS_GrayZombie2.XDeath
    file     zscript/monsters/zombieman/RS_Zombieman.zs:745
    shape    RING
    payload  RS_ZombieRock x13
    arc      360   (random(-359,359) per rock -- the spec's RING tell)
    timing   one tic  (TNT1 AAAAAAAAAAAAA 0 -- thirteen frames, zero tics)
    damage   random(1,12) each; 13..156 if every one connects
    type     Melee
    sound    "monster/hamflr" x13 (all on one tic)
    impact   8 dirt spawns per rock -- 104 RS_Drt2/RS_Drt3 if all land
    trigger  XDeath
    range    --
    mirrored no
    inherit  RS_ZombieRock : RS_WDRock3, as above
    profile  MakeVolley(proj:"RS_ZombieRock", count:13, arc:360,
                 fireSnd:"monster/hamflr", profName:"dying rock ring");
                 p.FireTrigger = RS_FIRE_XDEATH;
    notes    Telegraphed: the corpse squashes and stretches through twelve
             A_SetScale frames (:733-743, tics 6,6,6,4,4,3,3,2,2,1,1) for
             ~44 tics before it bursts. MakeVolley is EXACT here -- all
             thirteen genuinely fire on one tic, which is rare in this file.

---

## TIER 9 — RS_AbyssZombie2 (and RS_AbyssZombie3)

`RS_AbyssZombie3` (`:914`) overrides **only** `Health 140` and `Speed 10`.
Every row below applies to it unchanged.

    ATTACK   RS_AbyssZombie2.Missile
    file     zscript/monsters/zombieman/RS_Zombieman.zs:881
    shape    BURST
    payload  RS_AbyssZShotCH x2
    arc      shot 1 random(-7,+1), shot 2 random(-1,+7) -- a 14-degree
             PINCER, each shot biased to one side
    timing   10,5,5,10   (30 tics; the two bolts 5 tics apart)
    damage   DamageFunction (random(5,30)) contact
             + A_Explode(random(1,8),42) on THREE frames of Death (:794)
    type     Ice
    sound    SeeSound "imp/attack" per bolt
    impact   A_SetScale(0.85) then BAL7 CDE 4 Bright with the three
             A_Explode frames. DeathSound "imp/shotx". +DONTHARMCLASS so
             abyss zombies do not splash each other.
    trigger  Missile
    range    --
    mirrored yes  -- the second bolt's angle band IS the first's reflected
             about 0. Not a separate state, just the mirrored argument.
    inherit  RS_AbyssZShotCH : Actor (RS_Zombieman.zs:763)
    profile  MakeBurst(proj:"RS_AbyssZShotCH", count:2, delayTics:5, arc:14,
                 fireSnd:"imp/attack", profName:"abyss pincer");
    notes    In flight each bolt spawns an RS_AbyssShotIdentifier every
             Fly loop (:789) -- a purely cosmetic marker gated on the
             `rs_ch_abyssmark` cvar, DEFAULT 0, so normally invisible.
             A_Weave(2,1,2,0.1) on the second Fly frame: the bolts wobble.
             Speed 32; XScale 0.5 / YScale 0.2 -- a flat horizontal sliver.
             THE NON-UNIFORM SCALE IS THE REASON this class cannot use a
             `Scale` Default (CLAUDE.md); it uses XScale/YScale, which the
             engine does accept as separate Default properties even though
             `Scale.X`/`Scale.Y` do not exist.

    ATTACK   RS_AbyssZombie2.Pain
    file     zscript/monsters/zombieman/RS_Zombieman.zs:889
    shape    RAIN
    payload  RS_SplashAbyss2 x45
    arc      --  (not angular: 45 droplets at random(-178,178) x AND y
             offsets from SELF, a 356x356 box, each with velz +2)
    timing   one tic  (45 frames at 0 tics)
    damage   DamageFunction (random(1,9)) each
    type     Ice
    sound    --   (RS_SplashAbyss2 inherits no SeeSound and no DeathSound
             from RS_SplashAbyss -- genuinely silent, both in ours and CH's)
    impact   BAL7 C 1 Bright A_SetScale(0.6) then BAL7 CDE 4 Bright.
             -NOGRAVITY, so they arc up on the +2 velz and fall.
             +MTHRUSPECIES and +DONTHARMCLASS: they pass through and do not
             hurt other zombies.
    trigger  Pain
    range    --
    mirrored no
    inherit  RS_SplashAbyss2 : RS_SplashAbyss (RS_ZombiemanFX.zs:735).
             THE CHILD IS FOUR PROPERTY LINES. Its sprites, its Death
             animation, its Translation and its -NOGRAVITY all come from
             the parent at :707. Reading the child alone reports an actor
             with no states at all.
    profile  MakeVolley(proj:"RS_SplashAbyss2", count:45, arc:360,
                 profName:"abyss burst"); p.FireTrigger = RS_FIRE_PAIN;
             -- INEXACT: MakeVolley fires at angles from a point, this
                spawns at random POSITIONS in a box. See UNRESOLVED §4.
    notes    RAIN is the closest word in the closed set ("spawned above/
             around ... and falling, not aimed") and it is not a perfect
             fit: the origin is the zombie, not the target. Recorded rather
             than coined.
             PainChance 18 -- this only happens on ~7 % of hits, which is
             why a 45-projectile retaliation is survivable.

    ATTACK   RS_AbyssZombie2.XDeath
    file     zscript/monsters/zombieman/RS_Zombieman.zs:906
    shape    RAIN
    payload  RS_SplashAbyss2 x4  (ABTR RSTU -- four frames, one spawn each)
    arc      --
    timing   5,5,5,5   (20 tics)
    damage   random(1,9) each
    type     Ice
    sound    --
    impact   as above
    trigger  XDeath
    range    --
    mirrored no
    inherit  RS_SplashAbyss2 : RS_SplashAbyss
    profile  MakeBurst(proj:"RS_SplashAbyss2", count:4, delayTics:5,
                 profName:"abyss death drip"); p.FireTrigger = RS_FIRE_XDEATH;
    notes    THE ARGUMENT ORDER IN THIS CALL IS SCRAMBLED, VERBATIM FROM CH.
             `A_SpawnItemEx("RS_SplashAbyss2", random(-24,24), random(-24,24),
             random(8,64), 0, 0, random(-359,359), 2, SXF_NOCHECKPOSITION)`
             puts random(-359,359) in the **zvel** slot and 2 in the **angle**
             slot. So each droplet is launched vertically at up to +/-359
             units/tic and all four share an angle of 2 degrees.
             CH Zombies.txt:774 is byte-identical. NOT our defect, NOT to be
             "fixed" here -- recorded so nobody rediscovers it as a bug.

---

## TIER 10 — RS_BlackZombieEX ("Player X")

Router: `:1904-1906` — `A_JumpIfCloser(300,"Shotttgun")`,
`A_JumpIfCloser(840,"PlasmaSpammer")`, else `A_Jump(256,"Rawkets")`.

    ATTACK   RS_BlackZombieEX.Melee
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1899
    shape    MELEE
    payload  --
    arc      --
    timing   4,4   (8 tics)
    damage   random(60,120)
    type     none  (A_CustomMeleeAttack's damagetype default)
    sound    "player/fist" on hit; miss sound is the literal string "none"
    impact   bleed = true (default) -- blood, no puff class
    trigger  Melee
    range    melee range
    mirrored no
    inherit  --
    profile  MakeMelee(range:64.0, fireSnd:"player/fist",
                 profName:"player X fist")
    notes    60..120 from a punch. Immediately `Goto Shotttgun` (:1901) --
             the fist is an OPENER, always followed by the SSG. Between
             them, `A_CheckFlag("CORPSE","Taunt",AAPTR_TARGET)`: if the punch
             killed you it stops to gloat (support row S-9).

    ATTACK   RS_BlackZombieEX.Shootmydude
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1938
    shape    HITSCAN
    payload  BulletPuff x8, all on ONE tic
    arc      ±22.5 horizontal, ±5 vertical
    timing   3,1,1,1,10 (the approach) then 0,0,13   (13-tic recovery)
    damage   6 * random(1,3) per pellet -> 6..18 each, 48..144 total
    type     Hitscan
    sound    A_PlaySound("weapons/sshotf") at :1937
    impact   BulletPuff (explicit)
    trigger  Missile   (A_JumpIfCloser(300)); also entered from Melee
    range    ..300
    mirrored no
    inherit  --
    profile  MakeHitscan(fireSnd:"weapons/sshotf", spreadScale:0.0,
                 impactPuff:"BulletPuff", profName:"player X SSG");
                 p.PelletOverride = 8; p.SpreadBonus = 22.5;
                 p.MaxRange = 300;
    notes    A REAL SUPER SHOTGUN WITH A REAL RELOAD. One shot arms
             RS_ShotgunWhere (:1940); the next attempt hits `Jammed`
             (support row S-8), which spends 18 tics reloading, ejects a
             Shell, and then rolls into a rocket barrage or the BFG.
             `A_CustomBulletAttack(22.5,5,8,6,"BulletPuff",0)` -- the
             trailing 0 is `range`, NOT flags. Reading it as flags would say
             CBAF_AIMFACING is off (true but irrelevant) and, worse, would
             lead someone to think NORANDOM might be set. It is not: the
             engine multiplies (Engine fact 1).
             If NOT within 300 when it enters Shotttgun it first LEAPS at
             you -- ThrustThingZ(0,64) + ThrustThing(angle,12) at :1932-33.

    ATTACK   RS_BlackZombieEX.RBarrage
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1958
    shape    BURST
    payload  Rocket (vanilla) x3
    arc      random(-1,1) per rocket -- essentially straight
    timing   1,1,6,1,1,2,4,0,4,0,4   (24 tics; rockets 4 tics apart)
    damage   vanilla Rocket: 20 contact, A_Explode 128 radius 128
    type     vanilla
    sound    vanilla Rocket SeeSound
    impact   vanilla Rocket death
    trigger  Missile   (reached from Jammed at :1947 -- 84/256, and from
             Pain at :2025, and from PlasmaSpammer at :1987)
    range    --
    mirrored yes -- `AltBar` (:1965) is the SAME three rockets after a
             strafe hop the other way: RBarrage hops `angle+90` (:1956),
             AltBar hops `angle-90` (:1967). `A_Jump(128,"AltBar")` at :1954
             picks between them 50/50.
    inherit  vanilla Rocket
    profile  MakeBurst(proj:"Rocket", count:3, delayTics:4,
                 profName:"strafing rocket barrage")
    notes    IT DODGES WHILE IT FIRES. The whole opening is movement:
             ThrustThingZ(0,64) up, ThrustThing(angle-180,12) back, then
             ThrustThingZ(0,64) again and ThrustThing(angle+/-90,12)
             sideways. Three rockets go out from a jumping, strafing target.
             `A_CheckFlag("CORPSE","Taunt")` after each rocket.

    ATTACK   RS_BlackZombieEX.BFGBoi
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1982
    shape    SINGLE
    payload  RS_PlayerEXBFG x1
    arc      --  (angle exactly 0)
    timing   1,1,10,8,6,4,12   (42 tics; 26 of them pure windup)
    damage   DamageFunction (random(100,200)) on contact
             + A_Explode(random(45,125),156) on ONE frame of Death (:1784)
    type     Plasma
    sound    A_PlaySound("weapons/bfgf") TWICE (:1978, :1979) --
             a doubled charge cue
    impact   see the next row; also Radius_Quake(15,15,0,40,0) at :1783
    trigger  Missile   (only from Jammed :1948 64/256, PlasmaSpammer :1996
             34/256, Rawkets :2011 8/256, ActualRawk :2018 34/256 --
             NEVER directly from the Missile router)
    range    --
    mirrored no
    inherit  RS_PlayerEXBFG : Actor (RS_Zombieman.zs:1757)
    profile  MakeHeavy(proj:"RS_PlayerEXBFG", fireSnd:"weapons/bfgf",
                 profName:"player X BFG")
    notes    IT HAS A DAMAGING TRAIL. Every 2 tics of flight it spawns an
             RS_TrailSPCguy at random offsets with velocity 20 and yaw
             random(-270,270) (:1778-79). RS_TrailSPCguy
             (RS_ZombiemanFX.zs:927) itself spawns an RS_TrailSP2 every
             Spawn frame, and BOTH explode on death:
             TrailSPCguy A_Explode(10,32) on FIVE frames (:948),
             TrailSP2 A_Explode(7,32) on FIVE frames (:921).
             A BFG shot therefore leaves a corridor of ~10-per-tick plasma
             blasts behind it. Recorded here, not rowed separately: it is a
             property of the projectile, not an independent attack.
             26 tics of visible windup before the shot is the tell.

    ATTACK   RS_PlayerEXBFG.Death            [SECONDARY -- impact is an attack]
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1785
    shape    RING
    payload  RS_PlayerEXBFG2 x29
    arc      360   (random(-359,359) yaw per ball, plus random(-9,9) zvel)
    timing   one tic  (29 frames at 0 tics, after the 8-tic A_Explode frame)
    damage   DamageFunction (random(20,80)) per ball
    type     Plasma
    sound    DeathSound "weapons/bfgx" (from the parent shot)
    impact   RS_PlayerEXBFG2 (RS_Zombieman.zs:1791): BFS1 A/B alternating
             with A_SetScale(0.55,0.75)/(0.75,0.55) -- it pulses -- and
             `A_Jump(2,"Death")` per loop, so each ball dies on its own
             ~0.8 % per 4 tics. Death is a fade, no blast.
             +DONTHARMCLASS, Speed 10, green translation.
    trigger  Missile   (secondary; fires wherever the BFG lands)
    range    --
    mirrored no
    inherit  RS_PlayerEXBFG (the DeathSound); the ball class is standalone
    profile  MakeVolley(proj:"RS_PlayerEXBFG2", count:29, arc:360,
                 fireSnd:"weapons/bfgx", pitchJitter:9.0,
                 profName:"BFG shrapnel ring")
    notes    ROWED SEPARATELY because it is substantial and independent:
             29 live 20..80 projectiles at random(2,19) speed drifting away
             from the blast point for several seconds. The A_Explode
             (random(45,125), radius 156) happens on the SAME state one
             frame earlier. Between them this is far and away the family's
             biggest single event.

    ATTACK   RS_BlackZombieEX.PlasmaSpammer
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1990
    shape    SCATTER
    payload  RS_PlasmaBallSP3 x4
    arc      WIDENS PER SHOT: ±5, ±15, ±25, ±35
    timing   2,0,3,1,3,1,3,1,0,3   (17 tics; the four balls ~4 tics apart)
    damage   `Damage 5` -- a BARE constant, deliberately. The engine rolls a
             bare integer Damage as random(1,8)*5 -> 5..40. Do NOT rewrite
             this as DamageFunction; the roll is the engine's and matching
             CH depends on leaving it alone (RS_ZombiemanFX.zs:870 says so).
    type     Plasma
    sound    SeeSound "weapons/plasmaf" per ball
    impact   PLSE ABCDE 4 Bright, DeathSound "weapons/plasmax".
             +MTHRUSPECIES, RenderStyle Add, Alpha 0.75, Speed 25.
    trigger  Missile   (A_JumpIfCloser(840))
    range    300..840
    mirrored no
    inherit  RS_PlasmaBallSP3 : Actor (RS_ZombiemanFX.zs:871;
             CH Spiders.txt:1886 -- pulled from another CH file)
    profile  four entries, ~4 tics apart, each with its own cone:
             MakeVolley(proj:"RS_PlasmaBallSP3", count:1, arc:10,
                 fireSnd:"weapons/plasmaf", profName:"plasma spam 1")
             ... arc 30, arc 50, arc 70
    notes    A_FaceTarget between shots 1-2 and 2-3 (:1991,:1993), then NOT
             before shot 4 -- so the last, widest ball is fired at where you
             were, not where you are.
             The state OPENS with `A_Jump(84,"RBarrage")` (:1987), so a
             third of mid-range engagements become a rocket barrage instead.
             `A_Jump(34,"BFGBoi")` before the fourth ball (:1996).
             Ends on A_MonsterRefire(128,"CellEject") -- per Engine fact 6,
             half the time it loops straight back into Missile.

    ATTACK   RS_BlackZombieEX.Rawkets
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2008
    shape    HITSCAN
    payload  BulletPuff x1
    arc      ±5.6 horizontal, 0 vertical (spread_z 0 -- dead flat)
    timing   2,2,2   (6 tics per tap, then refires)
    damage   5 * random(1,3) -> 5..15
    type     Hitscan
    sound    -- (no AttackSound on this class and no A_PlaySound here.
             A_CustomBulletAttack plays the actor's AttackSound, which
             RS_BlackZombieEX does not declare. GENUINELY SILENT.
             As a profile slot that is correct -- the gun's own sound fills
             it -- but on the monster it means an invisible-source chaingun.)
    impact   BulletPuff (explicit)
    trigger  Missile   (the A_Jump(256,"Rawkets") fallthrough)
    range    840..
    mirrored no
    inherit  --
    profile  MakeHitscan(spreadScale:0.0, impactPuff:"BulletPuff",
                 profName:"player X chaingun"); p.PelletOverride = 1;
                 p.SpreadBonus = 5.6; p.MinRange = 840;
    notes    THE STATE IS CALLED "Rawkets" AND IT FIRES A BULLET. The
             rockets are in `ActualRawk`, reached 32/256 of the time
             (:2009). Named for what it usually escalates into, not what it
             does. Loops on A_CPosRefire (:2012), the chaingunner's
             break-off check -- so this is a sustained single-bullet stream
             at long range.

    ATTACK   RS_BlackZombieEX.ActualRawk
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2016
    shape    SINGLE
    payload  Rocket (vanilla) x1
    arc      random(-1,1)
    timing   2,2,2   (6 tics)
    damage   vanilla Rocket
    type     vanilla
    sound    vanilla Rocket SeeSound
    impact   vanilla Rocket death
    trigger  Missile   (A_Jump(32) from Rawkets)
    range    840..
    mirrored no
    inherit  vanilla Rocket
    profile  MakeHeavy(proj:"Rocket", profName:"player X rocket")
    notes    12.5 % of long-range taps. `A_Jump(34,"BFGBoi")` right after
             (:2018) -- a rocket has a 13 % chance of being followed by the
             BFG.

---

## TIER 10 — RS_BlackZombie1 ("Player 9")

Same router (`:2115-2117`), a strictly reduced kit: **no BFG, no rocket
barrage, no pre-shotgun leap, no corpse taunt.**

    ATTACK   RS_BlackZombie1.Melee
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2111
    shape    MELEE
    payload  --
    arc      --
    timing   4,4   (8 tics)
    damage   random(20,80)
    type     none
    sound    "player/fist"
    impact   bleed = true
    trigger  Melee
    range    melee range
    mirrored no
    inherit  --
    profile  MakeMelee(range:64.0, fireSnd:"player/fist",
                 profName:"player 9 fist")
    notes    A THIRD of Player X's punch (20..80 vs 60..120). Also goes
             straight to Shotttgun, but without the corpse check.

    ATTACK   RS_BlackZombie1.Shotttgun
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2123
    shape    HITSCAN
    payload  BulletPuff x8, one tic
    arc      ±22.5 horizontal, ±5 vertical
    timing   3,0,0,13   (16 tics)
    damage   6 * random(1,3) per pellet -> 6..18 each, 48..144 total
    type     Hitscan
    sound    A_PlaySound("weapons/sshotf") at :2122
    impact   BulletPuff
    trigger  Missile   (A_JumpIfCloser(300)); also entered from Melee
    range    ..300
    mirrored no
    inherit  --
    profile  MakeHitscan(fireSnd:"weapons/sshotf", spreadScale:0.0,
                 impactPuff:"BulletPuff", profName:"player 9 SSG");
                 p.PelletOverride = 8; p.SpreadBonus = 22.5;
                 p.MaxRange = 300;
    notes    Numerically IDENTICAL to Player X's, so this is the same part.
             The difference is the approach: no leap, and the jam
             (support S-8) just returns to Missile instead of rolling into a
             barrage or the BFG.

    ATTACK   RS_BlackZombie1.PlasmaSpammer
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2135
    shape    SCATTER
    payload  RS_PlasmaBallSP3 x4
    arc      ±5, ±15, ±25, ±35
    timing   2,0,3,1,3,1,3,1,3   (17 tics)
    damage   `Damage 5` -> engine roll random(1,8)*5 -> 5..40 (see the
             Player X row; do not flatten and do not convert)
    type     Plasma
    sound    SeeSound "weapons/plasmaf" per ball
    impact   PLSE ABCDE 4 Bright, DeathSound "weapons/plasmax"
    trigger  Missile   (A_JumpIfCloser(840))
    range    300..840
    mirrored no
    inherit  RS_PlasmaBallSP3
    profile  as Player X's four entries
    notes    The pure version of the attack: no A_Jump(84,"RBarrage") at the
             top and no A_Jump(34,"BFGBoi") before the fourth ball. All four
             plasma balls always come out. Also ends on
             A_MonsterRefire(128,"CellEject").

    ATTACK   RS_BlackZombie1.Rawkets
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2151
    shape    HITSCAN
    payload  BulletPuff x1
    arc      ±5.6 horizontal, 0 vertical
    timing   2,2,2
    damage   5 * random(1,3) -> 5..15
    type     Hitscan
    sound    --   (no AttackSound declared -- silent, as Player X)
    impact   BulletPuff
    trigger  Missile
    range    840..
    mirrored no
    inherit  --
    profile  MakeHitscan(spreadScale:0.0, impactPuff:"BulletPuff",
                 profName:"player 9 chaingun"); p.PelletOverride = 1;
                 p.SpreadBonus = 5.6; p.MinRange = 840;
    notes    Loops on A_CPosRefire (:2153).

    ATTACK   RS_BlackZombie1.ActualRawk
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2157
    shape    SINGLE
    payload  Rocket (vanilla) x1
    arc      random(-1,1)
    timing   2,2,2
    damage   vanilla Rocket
    type     vanilla
    sound    vanilla Rocket SeeSound
    impact   vanilla Rocket death
    trigger  Missile   (A_Jump(32) from Rawkets, :2152)
    range    840..
    mirrored no
    inherit  vanilla Rocket
    profile  MakeHeavy(proj:"Rocket", profName:"player 9 rocket")
    notes    No BFG follow-up -- it just goes back to Missile.

---

## TIER 11 — RS_WhiteZombie1 (THE UNDERTAKER)

Router (`:2510-2515`): `Melee:` and `Missile:` share one label block.
`A_JumpIf(user_skel1 == 4,"FinalForm")` → `A_JumpIfCloser(550,"Shovel",true)`
→ `A_JumpIfCloser(1250,"MedRange")` → `A_Jump(255,"RapidBone")`.

`user_skel1` is raised by the Buff ladder (support row S-3): **0/2 → 3 → 4**.
It is what selects between the ZM / ZM2 / ZM3 bone tiers. There is no state
where a builder can read the whole ladder in one place, so it is set out here:

| user_skel1 | close (<550) | mid (<1250) | long |
|---|---|---|---|
| 0 or 2 | Shovel | ShotBone (ZM) or RapidBone (ZM) | RapidBone (ZM) |
| 3 | Shovel | ShotBone2 (ZM2) or RapidBone2 (ZM2) | RapidBone2 (ZM2) |
| 4 | Shovel or ShotBone3 | ShotBone3 / BoneTornado / RapidBone3 (all ZM3) | RapidBone3 (ZM3) |

    ATTACK   RS_WhiteZombie1.Shovel
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2583
    shape    FAN
    payload  RS_ShoveZM x3
    arc      10   (-5, 0, +5; spawnofs_xy -3, 0, +3 matched to it)
    timing   7,7,0,0,0,0,6   (20 tics; all three blades on one tic)
    damage   DamageFunction (random(10,45)) per blade on contact
    type     Melee
    sound    A_PlaySound("Spell/SpellCast1") at :2582.
             The blade's own AttackSound is "skelsit4" -- WHICH DOES NOT
             EXIST. Absent from our SNDINFO and absent from CH's own
             SNDINFO.txt. Silent in CH too; kept verbatim (:2885).
    impact   RS_ShoveZM Death (:2907-2913): A_PlaySound("moloch/nailhit")
             -> $RANDOM {ricochet1 ricochet2} -> dsnailr1/dsnailr2, both
             present; then 6PUF ABCDEF 1 Bright; then FBL1 EFG 1 Bright
             with A_Explode(random(5,20),64) on THREE frames; then
             RS_MrBones at failchance 128 = 50 % A SKELETON.
             DeathSound "moloch/nailhitbleed" -> DSNAIIMP, present.
    trigger  Melee | Missile   (both labels enter the same router)
    range    ..550
    mirrored no
    inherit  RS_ShoveZM : Actor (RS_Zombieman.zs:2874)
    profile  MakeVolley(proj:"RS_ShoveZM", count:3, arc:10,
                 fireSnd:"Spell/SpellCast1", profName:"shovel fan")
    notes    THE SHOVEL IS A DELIVERY VEHICLE, NOT A BLADE -- see the next
             row. Also: after firing it rolls again (:2586-2587), so a
             shovel throw is usually chained straight into a bone shot.
             CH difference: none. CH Zombies.txt:2424-2426 is identical.

    ATTACK   RS_ShoveZM.Spawn                [SECONDARY -- in-flight spray]
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2895
    shape    MULTI
    payload  RS_ShoveZM2 x14  +  RS_ShoveZM3 x13   (27 sub-blades)
    arc      most at 0; two pairs at -180 (BACKWARD); four groups at
             random(-190,-175) with pitch offsets -6/+6/-3/+3
    timing   2,2,0,0,0,2,0,0,0,3,0,0,0,0,3,...   -- 12 tics of flight total,
             during which all 27 come out
    damage   RS_ShoveZM2 DamageFunction (random(1,5));
             RS_ShoveZM3 DamageFunction (random(3,12))
    type     Melee (both)
    sound    RS_ShoveZM2 AttackSound "moloch/nailhitbleed"; both have NO
             DeathSound in our tree (CH writes `Deathsound ""` explicitly at
             Zombies.txt:2753 -- same silence, one line shorter here)
    impact   BLAD A frames fading out via A_FadeOut(0.15), then FBL1 G.
             No explosion. Alpha 0.75, Scale 1.8 / 1.55.
    trigger  Missile   (secondary: fires itself all the way to the target)
    range    --
    mirrored yes -- the -180 pair (:2900,:2901) is +3/-3 spawnofs mirrored;
             the random(-190,-175) quad (:2903-2906) is two mirrored pairs
             with mirrored pitch
    inherit  RS_ShoveZM3 : RS_ShoveZM2 (:2947) -- the child overrides Speed,
             damage, DamageType and Scale, and rewrites both states; the
             AttackSound and the +SPAWNSOUNDSOURCE/+EXTREMEDEATH/
             +BLOODSPLATTER flags come from the parent at :2917.
    profile  MakeBurst(proj:"RS_ShoveZM2", count:14, delayTics:1, arc:20,
                 profName:"shovel spray A")  +
             MakeBurst(proj:"RS_ShoveZM3", count:13, delayTics:1, arc:20,
                 profName:"shovel spray B")
             -- two profiles because MULTI is two payload classes and no
                single factory call carries both.
    notes    THE SPAWN STATE FALLS THROUGH INTO Death. There is no Loop and
             no Stop before the `Death:` label (:2907), so after 12 tics of
             flight the shovel DETONATES ON ITS OWN whether or not it hit
             anything. That is the attack: a thrown blade that showers 27
             smaller blades for twelve tics and then explodes for
             random(5,20) three times.
             Several of the sub-blades are fired at -180 and -190..-175,
             i.e. BACKWARD out of the shovel -- so the spray covers the
             ground the shovel has already crossed.

    ATTACK   RS_WhiteZombie1.ShotBone
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2558
    shape    SCATTER
    payload  RS_BoneProjZM x9, all on ONE tic
    arc      24   (random(-12,12) yaw per bone) + random(-3,3) pitch offset
             (CMF_OFFSETPITCH) + random(-5,5) lateral spawn offset
    timing   8,6,0,5   (19 tics)
    damage   DamageFunction (random(4,16)) per bone
    type     none  (no DamageType declared)
    sound    SeeSound "skelatt" x9, all on one tic
    impact   MISL B/C/D at Scale 0.3 with 5 white particles; DeathSound
             "swordhit". THEN: `A_SpawnItemEx("RS_MrBones",...,250)` at
             :2851 -- failchance 250, so **6/256 = 2.3 %** per bone spawns
             a skeleton. Nine bones -> ~19 % chance of a skeleton per shot.
             ALSO drops ammo: DropItem RS_implyingclip 48, RS_CH_Shell 32,
             RS_CH_Cell 16, RS_CH_RocketAmmo 8 (:2837-2840).
    trigger  Missile   (MedRange, A_JumpIfCloser(1250) then A_Jump(255,
             "ShotBone","RapidBone") -- 50/50 with RapidBone)
    range    550..1250
    mirrored no
    inherit  RS_BoneProjZM : Actor (:2821)
    profile  MakeVolley(proj:"RS_BoneProjZM", count:9, arc:24,
                 fireSnd:"skelatt", pitchJitter:3.0,
                 profName:"bone shotgun"); p.MinRange = 550;
                 p.MaxRange = 1250;
    notes    THE PROJECTILE FEEDS THE BOSS. Every bone that lands has a
             2.3 % chance of hatching a skeleton, and every skeleton that
             dies heals and buffs the Undertaker (support rows S-4, S-3).
             That loop is the whole fight.
             `A_JumpIf(user_skel1 == 3,"ShotBone2")` sits on the frame
             BEFORE the volley (:2557), so at buff rung 3 this state is
             never actually reached -- it becomes ShotBone2.

    ATTACK   RS_WhiteZombie1.ShotBone2
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2562
    shape    SCATTER
    payload  RS_BoneProjZM2 x12, one tic
    arc      24 yaw + 6 pitch (identical argument shape to ShotBone)
    timing   0,5   (entered mid-ShotBone, so 8+6 tics of windup precede it)
    damage   DamageFunction (random(8,20)) per bone
    type     none
    sound    SeeSound "skelatt" x12
    impact   as RS_BoneProjZM -- INHERITED. RS_BoneProjZM2 (:2856) overrides
             ONLY DamageFunction and Speed 36. Its sprites, its sounds, its
             particle burst, its 2.3 % MrBones spawn and its entire ammo
             DropItem table all come from the parent.
    trigger  Missile
    range    550..1250
    mirrored no
    inherit  RS_BoneProjZM2 : RS_BoneProjZM
    profile  MakeVolley(proj:"RS_BoneProjZM2", count:12, arc:24,
                 fireSnd:"skelatt", pitchJitter:3.0,
                 profName:"bone shotgun II")
    notes    Buff rung 3 only. 12 bones instead of 9, each 8..20 instead of
             4..16 -- so ~2x the shot. Also ~26 % chance of a skeleton.

    ATTACK   RS_WhiteZombie1.ShotBone3
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2549
    shape    SCATTER
    payload  RS_BoneProjZM3 x11, one tic
    arc      24 yaw + 6 pitch
    timing   8,5,0,5   (18 tics)
    damage   DamageFunction (random(12,26)) per bone
    type     none
    sound    SeeSound "skelatt" x11
    impact   as RS_BoneProjZM -- RS_BoneProjZM3 (:2865) overrides only
             DamageFunction and Speed 40
    trigger  Missile   (FinalForm; also from Close2 :2523 at 50/50 vs Shovel)
    range    ..1250   (FinalForm's Close2 makes it usable inside 550 too)
    mirrored no
    inherit  RS_BoneProjZM3 : RS_BoneProjZM
    profile  MakeVolley(proj:"RS_BoneProjZM3", count:11, arc:24,
                 fireSnd:"skelatt", pitchJitter:3.0,
                 profName:"bone shotgun III")
    notes    Eleven, not twelve -- the count DROPS from ShotBone2 while the
             damage rises. Counted frame by frame off `MAGE FFFFFFFFFFF`.

    ATTACK   RS_WhiteZombie1.RapidBone
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2569
    shape    BURST
    payload  RS_BoneProjZM x2 per pass
    arc      10 yaw (random(-5,5)) + 2 pitch (random(-1,1)) +
             random(-2,2) lateral
    timing   7,1,1,1,0,2   (12 tics for the first pass, 5 per pass after --
             `Goto RapidBone+2` skips the 7-tic re-face)
    damage   random(4,16) per bone
    type     none
    sound    "skelatt" per bone
    impact   as RS_BoneProjZM (skeleton chance, ammo drops)
    trigger  Missile
    range    550..  (MedRange 50/50, and the long-range default)
    mirrored no
    inherit  RS_BoneProjZM
    profile  MakeBurst(proj:"RS_BoneProjZM", count:2, delayTics:1, arc:10,
                 fireSnd:"skelatt", pitchJitter:1.0,
                 profName:"bone stream"); p.MinRange = 550;
    notes    A STREAM, NOT A BURST OF TWO. `A_MonsterRefire(150,"See")` at
             :2571 with Engine fact 6 means ~59 % unconditional continue per
             pass, and the loop re-entry skips the aim frame. Two bones
             every 5 tics for as long as it holds.
             `A_Jump(12,"ShotBone")` at :2570 -- ~5 % per pass it breaks out
             into the 9-bone shotgun instead.

    ATTACK   RS_WhiteZombie1.RapidBone2
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2576
    shape    BURST
    payload  RS_BoneProjZM2 x2 per pass
    arc      6 yaw (random(-3,3)) + 2 pitch + random(-1,1) lateral
    timing   7,1,1,1,0,1   (11 tics first pass, 4 per pass after --
             `Goto RapidBone2+1`)
    damage   random(8,20) per bone
    type     none
    sound    "skelatt" per bone
    impact   inherited from RS_BoneProjZM
    trigger  Missile
    range    550..
    mirrored no
    inherit  RS_BoneProjZM2 : RS_BoneProjZM
    profile  MakeBurst(proj:"RS_BoneProjZM2", count:2, delayTics:1, arc:6,
                 fireSnd:"skelatt", pitchJitter:1.0,
                 profName:"bone stream II"); p.MinRange = 550;
    notes    Buff rung 3. Tighter cone (6 vs 10), faster loop (4 tics vs 5),
             harder bones, and A_MonsterRefire(120,...) instead of 150.
             `A_Jump(12,"ShotBone2")` at :2577.

    ATTACK   RS_WhiteZombie1.RapidBone3
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2543
    shape    BURST
    payload  RS_BoneProjZM3 x3 per pass
    arc      4 yaw (random(-2,2)) + 2 pitch + random(-1,1) lateral
    timing   7,1,1,1,1,1   (12 tics first pass, 5 per pass after --
             `Goto RapidBone3+1`)
    damage   random(12,26) per bone
    type     none
    sound    "skelatt" x3 per pass
    impact   inherited from RS_BoneProjZM
    trigger  Missile
    range    --  (FinalForm's long-range default and one third of MedRange2)
    mirrored no
    inherit  RS_BoneProjZM3 : RS_BoneProjZM
    profile  MakeBurst(proj:"RS_BoneProjZM3", count:3, delayTics:1, arc:4,
                 fireSnd:"skelatt", pitchJitter:1.0,
                 profName:"bone stream III")
    notes    THE LADDER'S END STATE: 3 bones a tic apart, 4-degree cone,
             12..26 each, on a ~5-tic loop with A_MonsterRefire(120,"See").
             Compare RapidBone: 2 bones, 10 degrees, 4..16, 5 tics. The cone
             narrows and the count rises at every rung.

    ATTACK   RS_WhiteZombie1.BoneTornado
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2536
    shape    SINGLE
    payload  RS_BoneTorn2 x1
    arc      random(-64,64)  -- a 128-degree throw; it is NOT aimed at you
    timing   9,7,7,5,5,3,3,5,3,3   (50 tics, 39 of them telegraph)
    damage   none from the tornado itself (no Damage, no DamageFunction)
    type     --
    sound    A_PlaySound("Under/Goodie",7,2,false,ATTN_NONE) at :2530 --
             channel 7, volume 2, ATTN_NONE = AUDIBLE ACROSS THE WHOLE MAP.
             That is the telegraph. Resolves: SNDINFO:687 -> WZMGDI, lump
             present at sounds/monsters/WZMGDI.ogg.
    impact   see the next two rows -- the tornado's whole point is what it
             emits while it lives
    trigger  Missile   (MedRange2 -- FinalForm only, 1 of 3)
    range    550..1250
    mirrored no
    inherit  RS_BoneTorn2 : Actor (:2635)
    profile  MakeHeavy(proj:"RS_BoneTorn2", fireSnd:"Under/Goodie",
                 profName:"bone tornado")
    notes    FINAL FORM ONLY (user_skel1 == 4). The 39-tic windup with
             alternating Bright frames and a map-wide sound is the longest
             telegraph in the family, and it is the only attack the
             Undertaker cannot do until the skeleton economy has fed it
             twelve BoneUps.

    ATTACK   RS_BoneTorn2.Spawn               [SECONDARY -- the tornado body]
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2663
    shape    MULTI
    payload  RS_BoneStormer1..7 x181  +  RS_BoneProjZM3 x16   PER LOOP
    arc      the BoneStormers are not fired at an angle -- see the next row;
             the RS_BoneProjZM3 batches are `A_CustomMissile(...,4,
             random(-20,20), CMF_AIMOFFSET, random(0,360), random(0,360))`
    timing   168 tics per loop  (frame-expanded; 0-tic lines contribute none)
    damage   BoneStormers random(1,3) each, RIPPING;
             BoneProjZM3 random(12,26) each
    type     none
    sound    SeeSound "Fire/fire3" once on spawn; the BoneStormers'
             DeathSound "Ice/Fly" (SNDINFO:1548 -> VORTEX, present) fires on
             every one that expires -- a continuous roar
    impact   RNGG ABCD 4 Bright on death; nothing else
    trigger  Missile   (secondary)
    range    --
    mirrored no
    inherit  --
    profile  MakeSummon-shaped, but it is not a summon. No factory fits;
             see UNRESOLVED §4.
    notes    COUNTS ARE FRAME-EXPANDED (Engine fact 8), NOT LINE COUNTS.
             Per loop, by variant:
               BoneStormer1 x27   BoneStormer2 x22   BoneStormer3 x21
               BoneStormer4 x32   BoneStormer5 x18   BoneStormer6 x32
               BoneStormer7 x29                      -- total 181
               RS_BoneProjZM3 x16  (four `RNGG CCDD 1` lines = 4 each)
             A line-count reading of this state reports 40 spawns. It is 197.
             The loop exits on `A_Jump(8,"Death")` at :2703 -- 8/256 = 3.1 %
             per loop. Mean ~32 loops. It is +INVISIBLE, +FLOORHUGGER,
             +THRUACTORS, +BOUNCEONWALLS with BounceCount 999 and
             WallBounceFactor 1.1, and A_Wanders four times per loop. Nothing
             else kills it. THIS IS A VERY LONG-LIVED HAZARD -- do not
             transcribe the tornado as a projectile with a lifetime.
             The `A_CustomMissile("RS_BoneProjZM3",4,random(-20,20),
             CMF_AIMOFFSET,random(0,360),random(0,360))` calls put the named
             constant CMF_AIMOFFSET (=1) in the **angle** slot and
             random(0,360) in the **flags** slot -- a garbage bitmask.
             CH Zombies.txt:2507 is byte-identical. Verbatim, not our defect.

    ATTACK   RS_BoneStormer1 .. RS_BoneStormer7   [SECONDARY -- the blades]
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2711 (base),
             :2743, :2756, :2769, :2782, :2795, :2808 (the six children)
    shape    UNCLASSIFIED
    payload  self -- each instance IS one orbiting ripper
    arc      each steps its own yaw +8 degrees PER TIC (user_angle += 8),
             so one instance sweeps a full circle every 45 tics
    timing   1 tic per orbit step, until its own A_Jump kills it
    damage   DamageFunction (random(1,3)) -- but +RIPPER, so it damages
             EVERY tic it overlaps you, and +FORCEPAIN staggers you each time
    type     none
    sound    DeathSound "Ice/Fly"
    impact   5 white particles + MISL B/C/D at Scale 0.3
    trigger  Missile   (secondary of the tornado)
    range    --
    mirrored no
    inherit  RS_BoneStormer2..7 : RS_BoneStormer1. The children override
             ONLY `Speed` and the A_Warp offsets. Damage, +RIPPER,
             +FORCEPAIN, +BLOODLESSIMPACT, the translation, the DeathSound
             and the entire Death state all come from the base.
    profile  no factory fits -- see UNRESOLVED §4
    notes    NOT FIRED, WARPED. Each instance runs
             `A_Warp(AAPTR_MASTER, r, 0, z, user_angle, WARPF_ABSOLUTEANGLE|
             WARPF_NOCHECKPOSITION|WARPF_INTERPOLATE)` every tic, so it is
             pinned to the tornado at a fixed radius and height while its
             yaw advances 8 degrees. The seven variants are seven concentric
             shells:
               1: r 32, z 32,  Speed 120, exit A_Jump(8)  (~3.1 %/tic)
               2: r 28, z 28,  Speed 105, exit A_Jump(4)  (~1.6 %/tic)
               3: r 12, z 10,  Speed 115, exit A_Jump(4)
               4: r 44, z 64,  Speed 130, exit A_Jump(4)
               5: r 56, z 88,  Speed 125, exit A_Jump(4)
               6: r 68, z 102, Speed 130, exit A_Jump(4)
               7: r 80, z 128, Speed 155, exit A_Jump(4)
             Radius AND height both climb -- it is a cone of spinning bone
             widening upward, not a flat ring. 181 spawned per 169-tic loop,
             each living a mean ~64 tics (1/0.016), so the steady-state
             population is well over a hundred simultaneous rippers.
             UNCLASSIFIED is deliberate: RING would tell a builder to write
             MakeVolley(count, arc:360), which is a completely different
             thing. Nothing in the closed set describes a warp-orbit, and
             the spec says describe rather than coin.

---

## TIER 12 — RS_CyanZombie2

    ATTACK   RS_CyanZombie2.Missile
    file     zscript/monsters/zombieman/RS_Zombieman.zs:461
    shape    SINGLE
    payload  RS_IceZombieShot x1
    arc      random(-2,2) jitter
    timing   6,4,4   (14 tics -- the fastest attack cycle in the family)
    damage   DamageFunction (random(6,16))
    type     Ice
    sound    SeeSound "Ice/Hit2"
    impact   ICEY FGHI 5 Bright. DeathSound "spike/spiked" --
             **THIS SOUND DOES NOT EXIST.** Absent from our SNDINFO and
             absent from CH's own SNDINFO.txt. Silent in CH too; kept
             verbatim with the comment at :384. A silent impact is a
             finding, not a blank.
    trigger  Missile
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_IceZombieShot", count:1,
                 fireSnd:"Ice/Hit2", profName:"ice shard")
    notes    THEY COME IN THREES. RS_CyanZombie (:73) spawns three
             RS_CyanZombie2 at 90/180 degrees apart (:90-92), so one map
             placement is three shooters on a 14-tic cycle. That cadence is
             the tier, not the shard.
             XScale 1.15 / YScale 0.15 -- a flat horizontal splinter, and
             another class that cannot use a uniform `Scale` Default.
             +THRUSPECIES, so the three never block each other.
             Death is A_IceGuyDie (:499) after a 51-tic squash-and-stretch.

---

## TIER 13 — RS_BrownZombie2

    ATTACK   RS_BrownZombie2.Missile
    file     zscript/monsters/zombieman/RS_Zombieman.zs:272
    shape    HITSCAN
    payload  --  (BulletPuff, hardcoded)  x1
    arc      ±22.4 horizontal, 0 vertical
    timing   10,10,10   (30 tics -- the slowest cycle in the family)
    damage   random(1,5)*3 -> {3,6,9,12,15}
    type     Hitscan
    sound    "grunt/attack" (hardcoded in A_PosAttack). The class also
             declares AttackSound "grunt/attack", which A_PosAttack ignores.
    impact   BulletPuff
    trigger  Missile
    range    --
    mirrored no
    inherit  --  (RS_BrownZombie2 : Actor; the Missile state is written out)
    profile  MakeHitscan(fireSnd:"grunt/attack", spreadScale:0.0,
                 profName:"bodyguard rifle"); p.SpreadBonus = 22.4;
                 p.PelletOverride = 1;
    notes    **THE OLD DEEP-READ IN THIS FOLDER SAYS THIS IS A SNIPER
             RIFLE. IT IS NOT.** `CATALOG.md` entry 13 describes
             `A_CustomBulletAttack(5, 0, 1, 10, "BulletPuff_C", 0,
             CBAF_NORANDOM)` -- a flat-10, 5-degree, no-multiplier bullet
             with AttackSound "SNPRFIRE". That is CHP's family 01, a
             different pack. **Our tree and CH both write plain
             `A_PosAttack`** (RS_Zombieman.zs:272, CH Zombies.txt:92):
             a random(1,5)*3 bullet in a 22.4-degree cone with no special
             sound. Our tree wins. See UNRESOLVED §2.
             Health 100, Speed 8, Mass 1000, Scale 0.9, +ROLLSPRITE,
             +NOINFIGHTING, +AVOIDMELEE, DamageFactor Exorcist 3.0.

---

## THE BONE ACTORS (no tier)

    ATTACK   RS_MrBones.Melee
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2316
    shape    MELEE
    payload  --
    arc      --
    timing   4,4,4,4,4   (20 tics: two face frames, the sound, the hit,
             a recovery face)
    damage   random(1,6)*4 -> {4,8,12,16,20,24}
    type     none
    sound    A_PlaySound("skelatt",CHAN_AUTO) on the frame BEFORE the hit
             (:2315) -- a one-frame wind-up cue. Hit sound "swordhit".
             Miss sound is the literal string "none".
    impact   bleed = true
    trigger  Melee
    range    melee range
    mirrored no
    inherit  --
    profile  MakeMelee(range:64.0, fireSnd:"swordhit",
                 profName:"skeleton swipe")
    notes    THE ONLY THING IT DOES. `A_Chase("Melee", null, CHF_STOPIFBLOCKED)`
             on every See frame (:2297 and three more) with a NULL missile
             state -- it has no ranged attack at all. +NOCLIP by default,
             toggled off when it gets moving, with an A_CheckBlock/A_Wander
             unstick loop (`IStuck`, :2306) and a give-up counter.
             `random(1,6)*4` is a roll -- do not flatten it to 14.

    ATTACK   RS_MrBones.XDeath
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2346
    shape    RING
    payload  RS_BoneGibWhite x16
    arc      360   (angle frandom(-180,180)) -- and velx/vely/velz each
             frandom(-180,180) too, so it is a SPHERE, not a flat ring
    timing   one tic  (16 frames at 0 tics)
    damage   Damage 1 each -- engine-rolled from a bare constant, so
             random(1,8)*1 -> 1..8
    type     none
    sound    A_Scream on the frame before
    impact   BBBN ABCD at random(3,6) tics, bouncing (BounceType "Doom",
             BounceFactor 0.5, BounceCount unset). On Crash/Death, 7-8 white
             particles and nothing else. +DONTHARMCLASS, +MOVEWITHSECTOR,
             +CANNOTPUSH, -NOGRAVITY.
    trigger  XDeath
    range    --
    mirrored no
    inherit  --
    profile  MakeVolley(proj:"RS_BoneGibWhite", count:16, arc:360,
                 pitchJitter:180.0, profName:"skeleton gib burst");
                 p.FireTrigger = RS_FIRE_XDEATH;
    notes    Bouncing 1..8 debris. Gibbing a skeleton denies the Undertaker
             its heal -- the Death state (support row S-4) is where the
             A_RadiusGive lives, and XDeath skips it entirely. THAT IS A
             REAL TACTICAL FACT ABOUT THE BOSS FIGHT and it is only visible
             by reading both death states.

---
---

# SUPPORT ROWS — real RS_AttackProfile parts, zero damage

Kept out of the ATTACK count on purpose. Same field format so they compose.

    S-1  RS_AbyssZombie2.Fling
    file     zscript/monsters/zombieman/RS_Zombieman.zs:863
    shape    UNCLASSIFIED   (A_RadiusGive -- no shape word covers it)
    payload  RS_CHAbyssMark (Inventory) to every "Zombie"-species MONSTER
             within 528 units, amount 55
    arc      360    timing  one tic, ONCE on arrival    damage  --   type  --
    sound    --     impact  every marked zombie's Death jumps to AbyssGrow
             instead of resting, and it becomes an RS_AbyssZombie2/3
    trigger  Spawn
    range    ..528    mirrored no    inherit --
    profile  MakeRadial(radius:528.0, damage:0, heal:0, hitsAllies:true,
                 profName:"abyss mark"); p.FireTrigger = RS_FIRE_SPAWN;
             -- INEXACT: MakeRadial has no "grant an item" axis.
    notes    An aura that converts the map's zombie population into more of
             itself, one death at a time. CH passed `0` for the class filter;
             ZScript wants `null`, which is the one edit on this line
             (comment in source at :863).

    S-2  RS_WhiteZombie1.Scripted
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2490
    shape    UNCLASSIFIED
    payload  RS_CHBoner to EVERY MONSTER ON THE MAP
             (radius 16383, RGF_NOSIGHT|RGF_MONSTERS, no species filter)
    arc      360    timing  one tic, once, on spawn    damage --   type --
    sound    --     impact  every marked corpse hatches an RS_ThePlanBoner,
             which hatches an RS_MrBones (support S-5)
    trigger  Spawn
    range    --     mirrored no    inherit --
    profile  MakeRadial(radius:16383.0, hitsAllies:true,
                 profName:"undertaker mark"); p.FireTrigger = RS_FIRE_SPAWN;
    notes    16383 units with RGF_NOSIGHT is the whole level, through walls.
             The moment an Undertaker exists, EVERY monster on the map is a
             future skeleton. This is the single line that makes the fight
             what it is.

    S-3  RS_WhiteZombie1.Buff1 / Buff2 / Buff3
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2592 / 2601 / 2609
    shape    UNCLASSIFIED
    payload  self
    arc      --   timing  Buff1 7 tics, Buff2 8, Buff3 21   damage --  type --
    sound    A_PlaySound("Under/Goodie",7,2,false,ATTN_NONE) on each --
             map-wide, so you hear every rung
    impact   Buff1 (>=5 BoneUp): Speed 16, Scale 1.1, bMISSILEEVENMORE = true,
                 user_skel1 += 2
             Buff2 (>=9):        Speed 21, Scale 1.25, user_skel1 += 1
             Buff3 (>=12):       Speed 28, Scale 1.45, bNOPAIN = true,
                 user_skel1 += 1
    trigger  Walk   (checked at the head of See, :2497-2499)
    range    --     mirrored no    inherit --
    profile  MakeSelfBuff(speedMult:1.6, duration:-1, profName:"bone buff 1")
             MakeSelfBuff(speedMult:2.1, duration:-1, profName:"bone buff 2")
             MakeSelfBuff(speedMult:2.8, duration:-1, noPain:true,
                 profName:"bone buff 3")
             -- INEXACT: these are PERMANENT. MakeSelfBuff's BuffDuration is
                a tic count and there is no "never revert" value; -1 is a
                guess, not something the code accepts today. UNRESOLVED §4.
    notes    Base Speed is 10. Rung 3 is 2.8x that AND immune to pain AND
             45 % bigger. `Reset` (:2589) guards each rung so it fires once.
             user_skel1 is what promotes every bone attack a tier -- see the
             Undertaker table above. RS_BoneUp caps at 30 (:2367).

    S-4  RS_MrBones.Death
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2328-2330
    shape    UNCLASSIFIED
    payload  Health random(12,128) + RS_BoneUp2 x1 + RS_BoneUp x1, all
             within 528 units, FILTERED TO RS_WhiteZombie1
    arc      360    timing 0,0,12    damage --    type --
    sound    RS_BoneUp2's Pickup state plays A_PlaySound("ice/Cast") on the
             Undertaker and spawns an RS_SpirZom halo (:2380-2381)
    impact   the Undertaker heals 12..128 and climbs one rung of S-3
    trigger  Death   -- and ONLY Death. XDeath (the gib burst row above)
             does not run these lines at all.
    range    ..528    mirrored no    inherit --
    profile  MakeRadial(radius:528.0, damage:0, heal:70, hitsAllies:true,
                 fireSnd:"ice/Cast", profName:"bone tribute");
                 p.FireTrigger = RS_FIRE_DEATH;
             -- heal 70 is the MIDPOINT of random(12,128) and is a LOSS:
                MakeRadial's RadialHeal is an int with no roll. The roll is
                recorded here so it is not lost. UNRESOLVED §4.
    notes    Then `SKLT Q 450 CanRaise` -- the corpse lies there for 450
             tics (12.8 s) able to be raised, and `Raise` has its own
             counter: after two raises it goes to `Revenante` (:2353) and
             tries to spawn an RS_CommonRevenant, which does not exist yet.
             The spawn is guarded by a runtime class lookup (:2362) so it is
             a silent no-op until the revenant family lands.

    S-5  RS_ThePlanBoner.Hatch
    file     zscript/monsters/zombieman/RS_Zombieman.zs:2210
    shape    UNCLASSIFIED   (a summon)
    payload  RS_MrBones x1
    arc      --   timing  38 tics (BBBN BCDABCD 5, then 3)   damage --  type --
    sound    --   impact  15 white particles, then the skeleton
    trigger  Spawn
    range    --   mirrored no   inherit --
    profile  MakeSummon(summonCls:"RS_MrBones", count:1, cap:0,
                 profName:"bone hatch"); p.FireTrigger = RS_FIRE_SPAWN;
             -- cap 0 is wrong; MakeSummon clamps cap to >=1 and there is no
                "uncapped" value. UNRESOLVED §4.
    notes    THERE IS NO CAP IN THE SOURCE. Every marked corpse hatches one,
             and S-2 marks the entire map. Health 45, +FLOAT +FLOATBOB,
             -COUNTKILL. Other paths to a skeleton: RS_BoneProjZM's Death at
             2.3 % (Engine fact 5) and RS_ShoveZM's Death at 50 %.

    S-6  RS_BrownZombie2.GETDOWN / GetDown2 / FrontJump
    file     zscript/monsters/zombieman/RS_Zombieman.zs:275 / 278 / 303
    shape    UNCLASSIFIED
    payload  --
    arc      --   timing  GetDown2 is 26 tics; FrontJump 29
    damage   NONE.  heal NONE.
    type     --   sound  --
    impact   A_Warp(AAPTR_MASTER, randompick(32,48,64), 0,
             randompick(-32,-16,0,16,32), 0, WARPF_COPYVELOCITY|
             WARPF_COPYPITCH) -- it teleports to a position in front of the
             demon it is guarding, mid-roll, having faded to alpha 0.1
    trigger  Walk
    range    ..1000 (A_CheckProximity), then A_CheckLOF(...,800)
    mirrored no   inherit --
    profile  none. There is nothing to build: no damage, no heal, no payload.
    notes    **THE OLD DEEP-READ SAYS THIS HEALS THE PACK FOR 50 IN A
             100-UNIT RADIUS. NEITHER OUR TREE NOR CH HAS ANY SUCH LINE.**
             CH Zombies.txt:98-123 is GetDown2 in full and there is no
             A_RadiusGive in it, or anywhere in CH's BrownZombie2. That heal
             is CHP's. See UNRESOLVED §2.
             It scans for VANILLA class names -- "Archvile", "BaronOfHell",
             "HellKnight", "CyberDemon", "ChainGunGuy" (:258-262) -- with
             CPXF_ANCESTOR. The old doc claims our file already substitutes
             RS_ names "and it is correct"; it does not, and the cited line
             numbers (675-679) point at RS_GrayZombie2's Default block.
             Whether CPXF_ANCESTOR catches our replacements is not something
             this catalog can settle by reading; UNRESOLVED §3.

    S-7  RS_YellowZombie.Jammed
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1556
    shape    UNCLASSIFIED
    payload  --
    arc      --   timing  0,10,18,10,10,10,16,16,0   (90 tics)
    damage   --   type  --
    sound    A_PlaySound("Jam/Jamd",0,1.9) FOUR times at volume 1.9
             (SNDINFO:681 -> CORK, present at sounds/monsters/CORK.lmp)
    impact   bNOPAIN = true for the whole window (:1557), cleared at :1565;
             A_TakeInventory("RS_RocketCounter",3) at :1563 rearms it
    trigger  Missile   (A_JumpIfInventory("RS_RocketCounter",3) at :1551)
    range    --   mirrored no   inherit --
    profile  none -- but see notes; this is worth wearing
    notes    A 90-TIC PUNISH WINDOW THE MONSTER GIVES YOU FOR FREE, and the
             loudest sound it makes. It is also flinch-immune throughout, so
             you cannot stunlock it out of the reload. As a player-weapon
             part this is a complete overheat/jam mechanic with an audible
             tell -- three shots, then 90 tics and four loud clacks.

    S-8  RS_BlackZombieEX.Jammed / RS_BlackZombie1.Jammed
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1942 / 2126
    shape    UNCLASSIFIED
    payload  a Shell pickup, tossed (8,4,32, vel 3,3,1, angle+5)
    arc      --   timing  8,2,8,2   (20 tics)
    damage   --   type  --
    sound    A_PlaySound("weapons/sshotl") -- the vanilla SSG reload
    impact   A_TakeInventory("RS_ShotgunWhere",1) rearms the SSG
    trigger  Missile
    range    --   mirrored no   inherit --
    profile  none
    notes    A real two-shell reload with a real ejected shell you can pick
             up. Player X's version then rolls A_Jump(84,"RBarrage") and
             A_Jump(64,"BFGBoi") (:1947-48) -- the reload is a launchpad
             into its two biggest attacks. Player 9's just returns to
             Missile. That single difference is most of what separates the
             two bosses.

    S-9  RS_BlackZombieEX.Taunt
    file     zscript/monsters/zombieman/RS_Zombieman.zs:1908
    shape    UNCLASSIFIED
    payload  --
    arc      --   timing  ~90 tics
    damage   --   type  --
    sound    A_PlaySound("HEHEEENH",0) x17
    impact   none
    trigger  Melee | Missile  (A_CheckFlag("CORPSE",...,AAPTR_TARGET) after
             almost every attack: :1900, :1939, :1959, :1961, :1963, :1970,
             :1972, :1974, :1984, :1998, :2010, :2017)
    range    --   mirrored no   inherit --
    profile  none
    notes    Twelve separate corpse checks. It stops whatever it is doing to
             gloat over a body. Player 9 has none of these.

    S-10 Pain.AbyssPE  (on 8 classes)
    file     zscript/monsters/zombieman/RS_Zombieman.zs:316, 464, 566, 691,
             955, 1100, 1223, 1385, 1567
    shape    UNCLASSIFIED
    payload  RS_SplashAbyss x90 (COSMETIC -- no damage, see the exclusions)
             + RS_AbyssZombie2 x1
    arc      360   timing  ~50 tics   damage  NONE   type --
    sound    A_PlaySound("AbyssForm",0)
    impact   bNOPAIN = true, the body squashes to nothing over 20 tics, then
             A_Die
    trigger  Pain
    range    --   mirrored no   inherit --
    profile  none -- this is a transformation, not an attack
    notes    Nine identical copies of the same 20-line block. The 90 splash
             droplets are the non-damaging parent class; counting them as a
             payload would report a 90-projectile attack that hurts nobody.
             Reached by a `Pain.AbyssPE` damage-type Pain state, i.e. only
             when hit by something with DamageType "AbyssPE" -- nothing in
             THIS family deals that type.

---
---

# UNRESOLVED

An honest gap is worth more than a confident guess.

### §1 — CH IS NOT WHERE THE SPEC SAYS IT IS

`rs_35_..._spec.txt:155` and `CLAUDE.md` both name
**`C:\Users\Command\Desktop\CH`** as the ground truth. **That path does not
exist on this machine.** `C:\Users\Command\Desktop\` contains `CHP`, `elites`,
two GlowInTheDark folders and `TextureLights_Reignited` — no `CH`.

I used **`E:\New folder\ART SOURCE\CH\`**, which does exist, has
`decorate/Zombies.txt` at 2,785 lines, and is the path CLAUDE.md's "IMPORTING A
MONSTER MEANS THE WHOLE MONSTER" section names for CH's sounds/sprites/SNDINFO.
Every CH citation in this file is to that tree. **If those two are not the same
pack, every CH diff above needs redoing.** I could not verify that they are,
and I did not scan the disk to look for another copy.

Same problem with the engine source: CLAUDE.md names `E:\DXR2`, which does not
exist. I read `E:\UZDXREMA` (a GZDoom source tree with the expected
`wadsrc/static/zscript/` and `src/playsim/` layout). Every "Engine fact" above
cites it. **Ask the owner to confirm both paths before anything is built off
this.**

### §2 — THE EXISTING DEEP-READ IN THIS FOLDER DESCRIBES A DIFFERENT PACK

`CATALOG.md` / `README.txt` / `INDEX.md` / `Zombieman_T*.md` are a read of
**CHP**, not CH, and they disagree with our tree structurally, not in detail:

| | old docs (CHP) | our tree (CH) |
|---|---|---|
| tier numbering | T00–T12 + TEX, 14 tiers | 1–13, CH icon index |
| Brown | T08, **sniper**, `A_CustomBulletAttack(5,0,1,10,…,CBAF_NORANDOM)`, AttackSound "SNPRFIRE" | tier 13, plain `A_PosAttack` |
| Brown dive | heals allies 50 in radius 100 | **no heal anywhere in ours or in CH** |
| Purple body | sprite `BPOS` | sprite `POSS` |
| Player 9 body | sprite `ZOMK` | sprite `PLAY` |
| Player X body | sprite `ZMKX` | sprite `PLAY` |
| Undertaker | T12 | tier 11 |
| code path | `zscript/monsters/Zombieman/attacks/RS_Zombieman_*.zs` | **that directory does not exist** |

Per CLAUDE.md our tree wins and no doc in `docs/` is authoritative. Recorded,
not reconciled. **The two Brown-zombie rows are the sharp one**: anyone
building from `CATALOG.md` entry 13 or 14 would ship a sniper rifle and a pack
heal that this project does not have.

`CATALOG.md` counts 30 attacks; this file counts 47 + 10 support. The
difference is not disagreement about the monsters — it is that the old count
collapses the Undertaker's seven bone states into three and does not row any
secondary (the shovel spray, the BFG shrapnel ring, the tornado body, the
BoneStormers).

### §3 — THINGS I COULD NOT SETTLE BY READING

* **Does `RS_BrownZombie2`'s bodyguard scan find anything?** It calls
  `A_CheckProximity` with `CPXF_ANCESTOR` on the vanilla names `"Archvile"`,
  `"BaronOfHell"`, `"HellKnight"`, `"CyberDemon"`, `"ChainGunGuy"`
  (`:258-262`). Whether this project's replacements are descendants of those
  classes is a question about the other sixteen families, not this one, and I
  did not open them to answer it. If they are not, `GETDOWN` never fires and
  the tier's whole gimmick is inert — silently, with no error. **A boot test
  with a Baron on the map is the only thing that can answer it.**
* **`RS_BoneTorn2`'s real lifetime.** 3.1 % exit per 168-tic loop gives a mean
  of ~32 loops ≈ 90 seconds, but it also bounces (`BounceCount 999`,
  `WallBounceFactor 1.1`) and `A_Wander`s, and I do not know whether a
  `+FLOORHUGGER` projectile in this build dies on a ceiling/step transition.
  I recorded the arithmetic, not a duration.
* **`RS_BoneStormer` steady-state population.** ~181 spawned per loop against a
  ~1.6 %/tic death roll implies well over a hundred live actors at once. I
  computed that; I did not observe it, and I do not know what it does to the
  frame rate.
* **The `+MISSILEMORE` / `+MISSILEEVENMORE` attack-frequency multipliers** are
  set on nine classes here (and `bMISSILEEVENMORE` is set at runtime by
  Buff1). Per CLAUDE.md these are deprecated flags with no `Property` binding
  and cannot be expressed any other way. Their effect on how often each row
  above actually fires is real and is **not captured in any field of this
  format**.
* **Whether every sound cited resolves end to end.** I followed six chains to
  real lumps (`zombie/unmaker`→DSUNMKER, `Jam/Jamd`→CORK, `Under/Goodie`→WZMGDI,
  `Ice/Fly`→VORTEX, `moloch/nailhitbleed`→DSNAIIMP,
  `moloch/nailhit`→$RANDOM{ricochet1,ricochet2}→dsnailr1/dsnailr2) and
  confirmed the two known-silent ones (`spike/spiked`, `skelsit4`) are absent
  from CH's SNDINFO too. **I did not audit all ~30.** The IWAD-sourced names
  (`chainguy/attack`, `weapons/sshot[fl]`, `weapons/bfg[fx]`, `player/fist`,
  `weapons/rockl[fx]`, `weapons/plasma[fx]`, `world/barrelx`) are not in our
  SNDINFO at all and are assumed to come from the IWAD — that assumption is
  untested here.

### §4 — ROWS THE PROFILE SYSTEM CANNOT YET HOLD

Every one of these has a real `profile` line above that is **approximate**, and
each is a gap in `RS_AttackProfile`, not in the reading:

1. **No rail mode.** `RS_RedZombie.Missile2` is `A_CustomRailgun` — instant,
   piercing, zero spread, with two colours. `RS_ATK_HITSCAN` traces but does
   not pierce. Five rows' worth of the tier is approximated.
2. **`A_Explode` has no factory.** `MakeRadial` is a `A_RadiusGive`-shaped
   verb (damage/heal to actors in a radius); `A_Explode`'s damage/distance/
   fulldamagedistance/flags are a different thing. It appears **11 times** in
   this family, including the entire core of `RS_FireBluZombie2.Melee`
   (`random(12,44)` at radius 84) and `RS_PlayerEXBFG.Death`
   (`random(45,125)` at radius 156). Those two rows currently describe only
   their projectile shrapnel.
3. **Multi-frame `A_Explode` cannot be expressed at all.** `RS_FireSGguy2`
   detonates on **eleven** frames; `RS_AbyssZShotCH` on three;
   `RS_TrailSPCguy` and `RS_TrailSP2` on five each. This is the
   lingering-fire/lightning pattern CLAUDE.md warns must not be collapsed to a
   single blast. No field carries "N blasts over M tics".
4. **`MakeRadial` has no "grant an item" axis**, so S-1 and S-2 — the two aura
   lines that define tiers 9 and 11 — cannot be built. `RadialHeal` is also a
   plain `int`, so S-4's `random(12,128)` had to be written as a midpoint;
   **the roll is preserved in the notes and must not be read off the profile
   line.**
5. **`MakeSelfBuff` has no permanent option.** S-3's three rungs never revert.
   `BuffDuration` is a tic count with no sentinel.
6. **`MakeSummon` has no uncapped option** — `SummonCap` is clamped to ≥1 —
   but S-5's skeleton hatch has no cap in the source at all.
7. **Positional scatter has no shape.** `RS_AbyssZombie2.Pain` spawns 45
   droplets at random **positions** in a 356×356 box around itself.
   `MakeVolley`'s `VolleyArc` fires at **angles** from a point. Rowed as RAIN
   with the mismatch flagged in the row.
8. **Warp-orbit has no shape and no factory.** The seven `RS_BoneStormer`
   classes are pinned to a master by `A_Warp` with an incrementing yaw. Rowed
   `UNCLASSIFIED` rather than forcing RING, because RING would tell a builder
   to write `MakeVolley(arc:360)` — a completely different behaviour.
9. **`MULTI` rows need two factory calls.** `RS_GreenZombie.Missile`,
   `RS_ShoveZM.Spawn` and `RS_BoneTorn2.Spawn` each fire two or more payload
   classes; no single factory carries that, so those `profile` lines list two
   or three calls. Whether an `RS_AttackSlot` firing several profiles on the
   same beat is legal is not something I could determine from
   `RS_AttackProfile.zs` alone.

### §5 — VERBATIM-FROM-CH ODDITIES, RECORDED SO THEY ARE NOT "FIXED"

All three were diffed against CH and are byte-identical there. **They are not
our defects and must not be corrected on the strength of this document.**

* `RS_AbyssZombie2.XDeath` (`:906`, CH `Zombies.txt:774`) — `random(-359,359)`
  lands in `A_SpawnItemEx`'s **zvel** slot and `2` in the **angle** slot.
* `RS_BoneTorn2`'s four `A_CustomMissile` lines (`:2669` etc., CH `:2507` etc.)
  — the constant `CMF_AIMOFFSET` (=1) is in the **angle** slot and
  `random(0,360)` is in the **flags** slot, i.e. a garbage bitmask.
* `RS_ShoveZM.Spawn` falls straight through into `Death:` with no `Loop`/`Stop`
  (`:2906→2907`, CH `:2731→2732`) — the shovel self-detonates after 12 tics.

Two more that are **ours and deliberate**, both owner-authorised on
2026-08-06 and both recorded in the source itself:

* `ZOMG U` → `ZOMG T` at `:1152-1154` and `:609-610` (the frame does not exist;
  CH's own corpse is invisible there).
* `ZOMP M` → `ZOMP N` at `:1426` (same defect on a 5-tic state).

Frame counts, tic counts and every attack argument are unchanged by all three.
