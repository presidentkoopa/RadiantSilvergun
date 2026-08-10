# MG monster set — import audit

Subject: `E:\New folder\ART SOURCE\hf_mg_monsters.zs` (2,223 lines).
Date: 2026-08-09. **Read-only audit. Nothing outside this file was written.**

Everything below was measured against the disk, the IWADs, or the engine source
at `E:\UZDXREMA`. Where a number could not be established, it says so. Nothing
here is a scope decision — those are the owner's.

---

## 0. Two things to know before reading the sections

### 0.1 The file cannot compile in this repo as written. This is not a risk, it is the current state.

Three independent hard blockers, each verified:

| blocker | count | evidence |
|---|---|---|
| parent class `HF_Monster` does not exist | 1 | zero hits for `HF_Monster` in `zscript/**`; it appears only in `docs/rs_01_promotion_system.txt`, `docs/rs_02_session_handoff.txt`, `docs/rs_04_monstermaster_brief.txt` |
| `A_CustomMissile`/`A_SpawnItem` call sites naming a class that exists nowhere | **484 sites / 52 classes** | see §D |
| the whole `HF_*` tier API it overrides is absent | `HFMT_*`, `HF_TierRow`, `TierData`, `MonIdentity`, `ColorState`, `TierColorLower` — **0 hits** in `zscript/**` | grep |

The engine is explicit that the second one is fatal in ZScript, not a warning.
`E:\UZDXREMA\src\common\scripting\backend\codegen.cpp:12347-12357`:

```
"Unknown class name '%s' of type '%s'"
// When originating from DECORATE this must pass, when in ZScript it's an
// error that must abort the code generation here.
if (!ctx.FromDecorate) { delete this; return nullptr; }
```

The unknown *parent* class is a separate hard `Error()` at
`src/common/scripting/frontend/zcc_compile.cpp:3093`.

### 0.2 A parallel session is already writing this import, right now.

`zscript/mg_staging/` is untracked and grew from **5 files to 18** during this
audit (`rs_mg_base.zs` plus one file per monster). That work renames the set to
`RS_MG*`, is deliberately **not** listed in `zscript.txt`, and its own header
says so. **This audit did not touch it, and every count below is measured against
the ART SOURCE original, not against the staging copies.** Three findings bear on
that lane directly and are flagged where they land (§D.1, §E.4, §G.3).

---

## A. SPRITES

### A.1 What the file actually names

Parsed with comments stripped, all 1,105 state lines, including the quoted
frame list `VILE "[\]"`.

* **18 classes** = 1 base (`HF_MG_Monsters`) + **17 monsters**.
* **53 distinct sprite prefixes** named across all states (excluding `TNT1`)
  = **15 IWAD-vanilla** + **38 custom**.
* **466 distinct (prefix, frame) pairs**; of those **217 are on custom
  prefixes** and resolve to **225 lumps** (some frames are 8-rotation).

### A.2 Custom art — does it exist in ART SOURCE?

**225 / 225 present. 0 absent.**

* **223 / 225** come from `E:\New folder\ART SOURCE\SPRITES\mg`.
* **2 / 225** do **not**: `REVHA0` and `REVHB0` live in
  `...\SPRITES\MONSTERS\REVENANT\GORE\`. A copy of `SPRITES\mg` alone leaves
  the MG Revenant's `XDeath` opening two frames blank.
* **0 / 225** already exist under `E:\RS_Main\sprites` by lump name.

`SPRITES\meatgrinder` (50 files) supplies **0 / 225**. It is not monster art
at all — see §B.4.

### A.3 Per-monster table

`custom` = non-IWAD prefixes. `ART` = lumps found in ART SOURCE.
`RS-vanilla` = whether the IWAD frames the monster needs already resolve in
this repo on **both** `doom2.wad` and `doom.wad`.

| monster | custom prefixes | custom lumps | ART | RS already has | vanilla prefixes | doom1-safe |
|---|---|---|---|---|---|---|
| Zombieman | 6 (+`NULL`) | 26 | 26/26 | 0/26 | POSS | yes |
| Shotgunner | 8 | 45 | 45/45 | 0/45 | SPOS, POSS | yes |
| Chaingunner | 6 | 36 | 36/36 | 0/36 | CPOS, POSS | yes (rs_doom1compat) |
| Imp | 4 | 21 | 21/21 | 0/21 | TROO | yes |
| Demon | 5 | 23 | 23/23 | 0/23 | SARG | yes |
| Spectre | 5 | 23 | 23/23 | 0/23 | SARG | yes |
| LostSoul | 0 | 0 | — | — | SKUL | yes |
| Cacodemon | 3 | 21 | 21/21 | 0/21 | HEAD | yes |
| PainElemental | 0* | 1 (`PAINX0`) | 1/1 | 0/1 | PAIN | yes (rs_doom1compat) |
| Revenant | 4 | 26 | 26/26 | 0/26 | SKEL | yes (monsters/fx) |
| Baron | 3 | 20 | 20/20 | 0/20 | BOSS | yes |
| HellKnight | 3 | 20 | 20/20 | 0/20 | BOSS | yes |
| Mancubus | 6 | 36 | 36/36 | 0/36 | FATT | yes (rs_doom1compat) |
| Arachnotron | 2 | 9 | 9/9 | 0/9 | BSPI | yes (monsters/fx) |
| Archvile | 3 | 21 | 21/21 | 0/21 | VILE | yes (rs_doom1compat) |
| Mastermind | 1 | 1 | 1/1 | 0/1 | SPID | yes |
| Cyberdemon | 1 | 1 | 1/1 | 0/1 | CYBR | yes |

\* PainElemental has no custom *prefix*. It draws **`PAIN X`**, an extra frame
bolted onto the vanilla `PAIN` prefix. `doom2.wad` has `PAIN A–M` only.
`sprites/rs_doom1compat/` has `PAIN A–M` only. **`PAINX0` must be imported or
the Pain Elemental's final `-1` corpse frame renders nothing.** ART SOURCE has
it (`SPRITES\mg\PAINX0.png`, and a `PAINN0` the file does not use).

`CRSH` (the crush pancake, 5 frames used across 12 monsters) is shared, counted
once per monster above.

### A.4 The Doom 1 sprite gap is already closed for this set

Six of the 15 vanilla prefixes are Doom-2-only: `CPOS FATT PAIN VILE SKEL BSPI`.
All six already ship in this repo (`rs_doom1compat/` for four,
`monsters/fx/` for `SKEL`+`BSPI`). **The MG set adds no new Doom-1 sprite gap.**
`VILE [`, `\`, `]` are absent from ART SOURCE (26/29) but present and correct in
`sprites/rs_doom1compat/` (29/29, `VILE^1.lmp` convention) — covered.

### A.5 Two transcription defects found while parsing

* `TNT1 H 0 A_CustomMissile(...)` at **lines 880 and 894** (`HF_MGRevenant`).
  `TNT1` has one frame, `A`. Frame `H` does not exist.
* `NULL A 0;` ×3 at **lines 174–176** (`HF_MGZombieman`, `Death.Melee`).
  There is no `NULL` sprite in the engine (`wadsrc/` has no `NULL*` lump).
  `SPRITES\mg\NULLA0` exists; import it or swap to `TNT1`.

---

## B. COLLISIONS — the most important section

### B.1 Headline: exact lump-name collisions are ZERO, and that is the wrong thing to measure

**0 of 225** MG monster lumps share a name with anything under
`E:\RS_Main\sprites`. A name-collision check passes cleanly.

It passes cleanly and it is wrong. The real failure mode here is **rotation-class
contention**, which produces no duplicate name, no error, and no log line.

### B.2 How the engine actually resolves it (verified, not recalled)

`E:\UZDXREMA\src\r_data\sprites.cpp:108-176`, `R_InstallSpriteLump`:

* a rot-`0` lump fills slots `14,12,…,0` (the eight even slots) **only where
  still unclaimed**, and sets `rotate = false` — but *only inside* the
  `if (!isValid())` branch;
* a rot-`1..8` lump maps to `(rot-1)*2` — **the same even slots** — again only
  if unclaimed, setting `rotate = true`.

So rot-0 and rot-1..8 art for the same frame contend for **identical slots**.
First writer wins per slot; the `rotate` flag follows whoever last claimed one.
Then at `sprites.cpp:210-260`, `rotate == 0` copies `Texture[0]` over all 16
rotations.

Net effect, both directions:

* rotated set loaded first → the rot-0 lump claims nothing and is **silently
  discarded**;
* rot-0 loaded first → the 8-rotation set claims nothing and the frame is
  **flattened to one facing**.

`I_FatalError("… is missing rotations")` at `:257` only fires when a frame ends
up with `rotate == 1` and a genuinely empty slot — which this case never
produces. **There is no error. One of the two sets vanishes by directory order.**

### B.3 The conflicts, by severity

Counted two ways, because the answer differs.

| scope | rotation-class conflicts vs `E:\RS_Main\sprites` |
|---|---|
| only the 225 lumps the MG monsters name | **7** |
| the whole `SPRITES\mg` folder (638 files) | **16** |
| the whole `SPRITES\meatgrinder` folder (50 files) | 0 (but see §B.4) |

**(a) `REVP` frames E F G I J K L — 7 conflicts, inside the MG monsters' own art.**

* MG: `SPRITES\mg\REVPE0.png` … `REVPL0.png`, rot-0, a bloodied Revenant
  plasma-death corpse. Drawn by `HF_MGRevenant`, `Death.Plasma`, lines 885–897.
* RS: `sprites/monsters/Revenant/T04/REVPA1.lmp` … `REVPQ8.lmp` — **101 lumps,
  8-rotation, frames A–Q**, a purple/magenta *living* Revenant body set.
* Pixels differ completely — rendered side by side and confirmed visually: RS's
  is a standing/striding monster, MG's is a torn corpse.
* **Mitigating fact:** `REVP` is referenced by **0** lines of RS ZScript
  (`grep REVP zscript/**` outside `mg_staging` returns nothing). RS's Revenant
  tiers draw `DKNT REVW WRTH AYPB REVN SREV RASK REVB ZKEL INCA`. Those 101
  lumps are shipped-but-dead weight. So the damage lands on the **MG** side, not
  on a live RS monster — but it still lands, silently, on whichever loses.

**(b) `BOS2` frames P Q R — 3 conflicts, and these hit a LIVE RS monster.**

This one is only reachable by a folder-level copy — no MG monster names `BOS2` —
which is exactly the trap CLAUDE.md records for `APLS`/`APBX`: *the set is only
as complete as the list of prefixes someone thought to check.*

* MG: `SPRITES\mg\BOS2P0…V0` (7 rot-0 lumps) — a Hell Knight **gore-death**.
* RS: `sprites/monsters/HellKnight/T00/BOS2P1…R8` — 8-rotation, the CH-authored
  P/Q/R frames CLAUDE.md explicitly protects.
* **RS's Hell Knight draws `BOS2 P`, `Q`, `R` in living attack states:**
  `zscript/monsters/hellknight/RS_HellKnight.zs:759-761` and `:888-890`
  (`BOS2 PQ 5 A_FaceTarget; BOS2 R 5 A_CustomMissile("RS_FireBluHKBall1",…)`).
* Rendered and compared: RS's are a green-flame casting pose; MG's are a gib
  death. Different animations, same lump names.
* **A `cp -r SPRITES\mg sprites\…` either flattens a shipping Hell Knight's
  attack animation to one facing, or is discarded — decided by directory order,
  with no diagnostic.**

**(c) `TRO3` frames A–E — 5 conflicts, same shape, lower stakes.**
MG rot-0 vs `sprites/monsters/Imp/T04/TRO3A1…E8`. `TRO3` is referenced by **0**
lines of RS ZScript, same as `REVP`.

### B.4 `SPRITES\meatgrinder` is not monster art and must not be copied

**49 of its 50 files are exact-name duplicates of `sprites/weapons/rs_ps_weapon/`.**
`FSTZ MGNF MGNG MGUF MGUG PLSC RLNC RLNF SSGF SSGG WPPI BFGN` — first-person
weapon sprites. This pack's weapons are **already imported** as the `RS_PS_` set
(78 sprite files, 5 sounds, 10 weapon classes). `SNDINFO:827` names it outright:
`// MeatGrinder set (RS_PS_)`. Copying the folder would overwrite 49 already-
imported lumps with (mostly) themselves and gain nothing.

### B.5 Prefix-level overlaps that are NOT collisions (verified, so nobody re-derives them)

10 of the 53 MG prefixes already exist under `sprites/`. Seven are benign:

* **`FAT2`** — the one named in the brief. **Frames are disjoint.** RS ships
  `FAT2A0–I0` in `monsters/Mancubus/T00/`, byte-identical (md5) to
  `ART SOURCE\SPRITES\manc\FAT2*.lmp` — that is CH's Mancubus. MG uses
  **`FAT2 K–P`** from `SPRITES\mg`. No shared lump name, no rotation conflict.
  What it *is*: two unrelated Mancubus gore sets sharing one 4-char prefix, with
  frame **`J` as the only free letter between them**. `ART SOURCE\SPRITES\
  MONSTERS\MANCUBUS\GORE\` also holds `FAT2Q0`/`FAT2R0`, so the MG side can grow
  upward. Worth recording so a later pass doesn't extend either set into `J`.
* **`CPOS FATT PAIN VILE`** — RS's copies are in `rs_doom1compat/`, rot-0 for
  the death frames and rot-N for the walk frames exactly as the IWAD has them;
  MG adds no lump to these except `PAINX0` (a new frame, no contention).
* **`SKEL BSPI`** — RS's copies in `monsters/fx/` cover 17/17 and 16/16 of the
  frames MG needs. No MG lump is added.
* **`BOSS`** — RS has only `BOSS P/Q/R`; MG uses `A–O`. Disjoint.
* **`SPID`** — RS ships one lump, `monsters/Mastermind/T00/SPIDS0.png`,
  overriding the IWAD. The MG Mastermind's final corpse frame is `SPID S -1`
  (line 1771), so it will wear RS's replacement. Pre-existing behaviour, not
  MG-introduced, but it means the MG Mastermind's corpse is not the vanilla one.

### B.6 Against the IWAD-standard prefixes

Checked all 15 named in the brief plus `CYBD`/`SSWV`. Read directly from the
owner's `doom2.wad` and `doom.wad` sprite ranges (`S_START`/`S_END`), 1,381 and
764 lumps.

* `CYBD` exists in **neither** IWAD — the Cyberdemon prefix is `CYBR`, which is
  what the file uses. No issue.
* `SSWV` is not used by any MG monster.
* MG never ships a replacement lump for a vanilla prefix except `PAIN X` (new
  frame) — so **no MG monster lump shadows an IWAD lump**. `SPRITES\mg`'s
  `BOS2`/`BLUD` do, but no MG monster names them.

---

## C. SOUNDS

### C.1 The count in the brief is 75. It is 79.

| | count |
|---|---|
| `Default`-block sound properties (`SeeSound`/`AttackSound`/`PainSound`/`DeathSound`/`ActiveSound`/`MeleeSound`) | **75** |
| `A_StartSound("…")` names in state code | **4** |
| **distinct sound names referenced** | **79** |
| total reference sites | 85 |
| families declaring sounds | 17 / 17 |

The four the 75 misses are `ENEMYGUN`, `MGUN2`, `enemysg`, `STGPUMP` — and they
are the only four that do not resolve. This is precisely the failure shape
CLAUDE.md records for the Streak set: the gap is in the names nobody enumerated.

### C.2 Resolution, end to end

Followed `$random`/`$alias` chains through the engine's own SNDINFO
(`wadsrc/static/sndinfo.txt`, 219 names, and
`wadsrc/static/filter/game-doomchex/sndinfo.txt`, 212 names) down to leaf lumps,
then checked each leaf against `doom2.wad`, `doom.wad`, `E:\RS_Main\sounds\` and
ART SOURCE.

* **75 / 79** are engine-defined vanilla monster names (`grunt/sight`,
  `vile/death`, …) and resolve on `doom2.wad`.
* **4 / 79 are defined nowhere.** Not in the engine, not in `E:\RS_Main\SNDINFO`
  (1,280 names). 8 call sites, all silent.
* **0 / 79** are redefined or overridden by `E:\RS_Main\SNDINFO`. The MG monsters
  would sound exactly like vanilla ones.

### C.3 The four undefined names, and whether a lump even exists

| name | sites | lump in ART SOURCE | lump in RS | verdict |
|---|---|---|---|---|
| `ENEMYGUN` | 4 (Zombieman, Shotgunner, Chaingunner, Mastermind) | **yes** — `SOUNDS\ENEMYGUN.ogg` and `SOUNDS\mg\ENEMYGUN.ogg` | no | importable; needs an SNDINFO line |
| `STGPUMP` | 1 (Shotgunner) | yes — `SOUNDS\STGPUMP\`, `SOUNDS\meatgrinder\STGPUMP\` | **yes** — `sounds/rs_ps_weapon/STGPUMP.ogg`, already mapped to `rs_ps/fist_fire` and `rs_ps/shotgun_pump` (`SNDINFO:831,840`) | lump is here; only the bare logical name `STGPUMP` is undefined |
| `MGUN2` | 2 (Zombieman, Chaingunner) | **NOT FOUND** — no file matching `*mgun2*` anywhere under `ART SOURCE\SOUNDS` | **NOT FOUND** | **no source. Cannot be resolved from anything on this machine.** |
| `enemysg` | 2 (Shotgunner, Mastermind) | **NOT FOUND** — no file matching `*enemysg*` | **NOT FOUND** | **no source. Same.** |

`MGUN2` and `enemysg` are the enemy machine-gun and enemy-shotgun report layered
on top of `ENEMYGUN`. Without them every MG hitscan grunt fires with half its
sound. There is nothing to import; the owner has to decide whether to substitute
(`sounds/rs_ps_weapon/MGFIRE.ogg` and `SGFIRE.ogg` are the same pack's weapon
audio and are already here) or drop the layer.

### C.4 A Doom 1 audio gap that `rs_doom1compat` does not cover

`rs_doom1compat` is sprites only. **20 of the 75 vanilla names resolve to lumps
that are absent from `doom.wad` and not shipped by `sounds/`:**

| family | names silent on Ultimate Doom |
|---|---|
| vile | 4 / 4 — `DSVILSIT DSVIPAIN DSVILDTH DSVILACT` |
| skeleton | 5 / 6 — `DSSKESIT DSSKEATK DSSKEDTH DSSKEACT DSSKEPCH` |
| pain | 3 / 4 — `DSPESIT DSPEPAIN DSPEDTH` |
| fatso | 3 / 4 — `DSMANSIT DSMNPAIN DSMANDTH` |
| baby | 3 / 4 — `DSBSPSIT DSBSPDTH DSBSPACT` |
| knight | 2 / 4 — `DSKNTSIT DSKNTDTH` |

This is **new** to the MG set, not an existing condition: RS's CH monsters use
CH's own sound names against `sounds/ch/` (785/785 present), so they are unaffected.
The MG set is the first roster to point at vanilla logical names. On `doom.wad`
these six families are visible (§A.4) and partly **mute**, with no error.

---

## D. DEPENDENCIES

### D.1 The header's three claims

| header claim (lines 19–20, 16–17) | status |
|---|---|
| "`Decorate/meatgrinder_gore.txt`" | **DOES NOT EXIST.** No file of that name anywhere under `E:\New folder\ART SOURCE`; no file anywhere in ART SOURCE contains `FlyingBloodParticleFast`, `CeilingBloodChecker`, `MG_EnemyBullet` or `SmokePillar` except `hf_mg_monsters.zs` itself. |
| "`Decorate/mg_effects.txt`" | **DOES NOT EXIST.** Same search. |
| "REUSE the CH per-color translations (`hfmon_<mon>_<color>`)" | **DOES NOT EXIST**, and `TRNSLATE.txt:6-8` says so in this repo's own words: *"they are not the previous port's `hfmon_zombie_green` style names — those were referenced by code but defined nowhere, so `A_SetTranslation` silently no-opped and the tiers all looked identical."* The MG file builds **16 tint families × 12 colours = 192** such names at runtime. **0 / 192** are defined. Every one no-ops. |

RS's actual scheme is `rs_<family>_t<NN>` — **135 entries across 15 families**
in `TRNSLATE.txt`. `hfmon_` count: **0**.

> This is the exact defect the parallel `mg_staging` session inherits: its
> `RS_MG_Monsters` still extends `HF_Monster` and its base still builds tint keys.
> Flagged, not touched.

### D.2 Every class the file references but does not define

**59 distinct names. 0 of them exist in `E:\RS_Main\zscript`. 484 call sites.**

| group | n | resolution |
|---|---|---|
| engine-native | 1 | `Clip` — real (`E:\UZDXREMA\wadsrc\static\zscript\actors\doom\doomammo.zs:3`). Fine. |
| the missing base class | 1 | `HF_Monster` |
| **has a same-purpose class already in RS under `RS_PS_`** | 5 | `SmokePillar`→`RS_PS_SmokePillar` (`RS_PS_FX.zs:463`, and `RS_Catalog.zs:377` already exposes it); `Explosion`→`RS_PS_Explosion` (:364); `ExplosionFire`→`RS_PS_ExplosionFire` (:271); `MG_Rocket`→`RS_PS_Rocket` (:215); `ExplSmokeParticle`→`RS_PS_BlastSmoke*` (:311-333, *approximate — not a rename, verify the behaviour matches before substituting*) |
| **nothing anywhere** | **52** | below |

The 52 with no counterpart, by kind:

* **XDeath gib spawners — 24**: `XDeath1 XDeath1b XDeath2 XDeath2b XDeath3
  XDeath3b` × the plain/`Blue`/`Green` colour variants, plus `XDeathArm
  XDeathBlackArm XDeathDemonArm XDeathImpArm XDeathImpLeg XDeathSpiderLeg`.
* **blood particles — 8**: `FlyingBloodParticleFast/Big/Huge/Crushed` × plain,
  `Blue`, `Green`.
* **head & body gibs — 13**: `GibHeadPiece GibTeeth GibEyeball`,
  `CyberGib1–4`, `LostSoulGib1–3`, `RevenantGib1–3`.
* **ceiling blood — 3**: `CeilingBloodChecker` × plain, `Blue`, `Green`.
* **limb gibs — 3**: `FatsoArm XShotgunnerLeg XZombiemanLeg`.
* **projectile — 1**: `MG_EnemyBullet` (the hitscan-replacement round for all
  four MG gun monsters). RS has no equivalent; `RS_BallisticType1/2/3` are
  player-side.

Top call-site counts: `XDeath1` ×65, `FlyingBloodParticleFast` ×61,
`FlyingBloodParticleBig` ×57, `XDeath1b` ×51, `XDeath2`/`XDeath3` ×35 each.

**The art for most of these is in ART SOURCE** (`SPRITES\mg` holds `XMT1 XMT2
BSPR XHE2 XHE4 XHE8 XDT1 XDSL LEG1 LEG4 LEG8 LGI1–5 XARM BRIB HND3 HND4 HND8
BNP1–3 GIB*` etc.). **The actors are not.** A complete import means authoring
~52 actor classes against that art, not transcribing them from anywhere.

### D.3 Damage-type channels — do they ever fire?

The set defines `Death.Plasma` (12 monsters), `Death.Saw` (4), `Death.Melee` (1),
`Crush` (12). In this repo:

* `DamageType "Plasma"` — **197 declarations**. Fires often.
* `DamageType "Melee"` — **73**. Fires.
* `DamageType "Saw"` — **2** (`RS_PS_FX.zs:418`, `RS_FX_Puffs.zs:201`). Fires
  only from the MeatGrinder chainsaw and one puff.
* `Crush` — engine-standard.

So the channels are real, not dead weight. Worth knowing that most `Death.Plasma`
triggers today come from **CH monster infighting**, not the player.

---

## E. TIER LADDERS

### E.1 The finding, stated plainly

> **Of the 38 custom sprite prefixes in this set, 37 are corpses. Exactly one
> appears in a living state, and it is not a different-looking monster.**

Measured by cross-referencing every custom prefix against the state label it
appears under:

| | count |
|---|---|
| custom prefixes used in `Spawn`/`See`/`Melee`/`Missile`/`Pain`/`Heal`/`Raise` | **1 / 38** |
| custom prefixes used only in `Death*`/`XDeath`/`Crush` | **37 / 38** |

The one is **`SPSR`** (`HF_MGShotgunner`, `Missile`, line 1915) — a 2-frame
shotgun-pump insert, 10 lumps because it is properly 8-rotation. It is the same
shotgunner pumping his shotgun. It is not a second look.

**Therefore: this set's art supports ZERO additional tier looks.** Every MG
monster at every tier renders the stock IWAD sprite while alive. A tier ladder
here can only be carried by a palette translation, exactly like CH's untranslated
tiers — and the file's own translation names are all undefined (§D.1).

### E.2 What the custom art *is*: alternate deaths, and fewer than the labels suggest

Death branches, and how many are actually distinct and actually reachable:

| monster | death labels | distinct by sprite content | reachability defects |
|---|---|---|---|
| Zombieman | 11 | **9** | `Death4 == Death5` (identical bodies); `XDeath == Death.Saw` |
| Shotgunner | 10 | **9** | `XDeath == Death.Saw` |
| Chaingunner | 10 | **9** | `A_Jump(255)` at :2103 targets only `Death1/2/3` — **`Death4` and `Death5` are unreachable**, and are identical to each other |
| Imp | 9 | **6** | `Death2 == Death4 == Death5`; `XDeath == Death.Saw` |
| Demon | 7 | 6 | — |
| Spectre | 7 | 6 | — |
| Cacodemon | 4 | 4 | **`Death2` is unreachable** — nothing jumps to it, and `Death` does not fall into it. It holds the *vanilla* `HEAD G–L` death; as written the MG Caco **always** plays the `CCD2` gib. Its `A_Jump(160,"XDeath")` at :983 also names a label `HF_MGCaco` does not define. |
| Revenant | 5 | 5 | — |
| Baron / HellKnight | 4 | 4 | — |
| Mancubus | 7 | 7 | — |
| Arachnotron | 3 | 3 | — |
| Archvile | 4 | 4 | — |
| Mastermind | 2 | 2 | — |
| Cyberdemon | 2 | 2 | — |
| LostSoul / PainElemental | 1 | 1 | — |

### E.3 Honest tier capacity, per monster

If "a tier is a look the player can tell apart on sight", and the only available
axis is a palette remap borrowed from RS's own `TRNSLATE.txt`:

| MG monster | `tintFam` in file | RS translation family | tiers available |
|---|---|---|---|
| Zombieman | `zombie` | `rs_zombie` | **10** |
| Shotgunner | `sg` | `rs_sgun` | **10** |
| Chaingunner | `cg` | `rs_cgun` | **9** |
| Imp | `imp` | `rs_imp` | **8** |
| Demon | `demon` | `rs_demon` | **10** |
| Spectre | `spectre` | `rs_spectre` | **1** |
| LostSoul | `lostsoul` | `rs_soul` | **8** |
| Cacodemon | `caco` | `rs_caco` | **10** |
| PainElemental | `pe` | `rs_pain` | **9** |
| Revenant | `rev` | `rs_rev` | **9** |
| Baron | `baron` | `rs_baron` | **12** |
| HellKnight | `hk` | `rs_hk` | **8** |
| Mancubus | `manc` | `rs_manc` | **11** |
| Arachnotron | `spider` | `rs_arach` | **11** |
| Archvile | `archvile` | `rs_vile` | **9** |
| **Mastermind** | `spider` | **none** | **0** |
| **Cyberdemon** | `cyber` | **none** | **0** |

Two things fall out:

* `TRNSLATE.txt` has **no** `rs_cyber` and **no** mastermind family. Those two
  bosses have no colour axis at all in this repo.
* The file assigns `tintFam = "spider"` to **both** the Arachnotron and the
  Mastermind (lines 1514, 1726). Mapped onto RS's scheme that puts the
  Mastermind in the *Arachnotron's* palette. That is a defect in the source, not
  a design.

### E.4 A note for the in-flight staging work

`zscript/mg_staging/rs_mg_revenant.zs:47` currently reads
`override int MGTiers() { return 4; }   // REVH REVP REDX CRSH`.

Those four are, respectively: a torn-open death, a plasma death, a gib death,
and a crush pancake. By §E.1 that is **four corpses, zero looks**. The owner's
own rule — *"a monster gets as many tiers as it HAS… a tier the player cannot
tell apart on sight is not a tier"*, quoted in that lane's own base header — cuts
the other way here. Reporting, not editing.

---

## F. FX HARVEST

`zscript/systems/weapon/RS_FXRegistry.zs` (230 lines): **9 axes**
(`PROJECTILE CASING MUZZLE SMOKE SOUND PUFF SPARKS TRAIL PAYLOAD`),
8 themes, **36 entries**, each a `Class<Actor>` + theme mask + axis mask.
`Add()` skips silently when a class does not resolve.

Two consequences for this harvest:

1. **The registry indexes CLASSES, not sprites.** Nothing here is usable until
   an actor exists. The 52 missing gore classes (§D.2) are the work.
2. **The MG monsters' own 37 custom sequences are all corpse animations** — a
   Mancubus falling apart is not a projectile, a puff or a trail. The harvest is
   *not* in `hf_mg_monsters.zs`. It is in the **46 prefixes in `SPRITES\mg` the
   monsters never name.**

### F.1 Candidates I actually looked at

Rendered from raw Doom patches against `doom2.wad`'s `PLAYPAL` and viewed frame
by frame. CLAUDE.md's rule about not pattern-matching sprite names is why.

| prefix | lumps | what it actually is | axis |
|---|---|---|---|
| `SPKS` | 9 | radial burst of orange spark shards, expanding | **SPARKS**, PAYLOAD, PUFF |
| `EXPZ` | 8 | bright red-white fireball collapsing into a soot ring | **PAYLOAD**, SMOKE, PUFF |
| `FX58` | 10 | wide ember/spark shower drifting outward, large canvas | **SPARKS**, TRAIL, PAYLOAD |
| `TRL1` | 5 | fire flare decaying into grey smoke | **TRAIL**, SMOKE |
| `SMK3` | 13 | dark grey smoke puff dissipating | **SMOKE** |
| `SB17` | 8 | tall rising smoke column (this is the `SmokePillar` art) | **SMOKE** |
| `PRJ1` | 2 | small red plasma orb, tight glow | **PROJECTILE** |
| `PRJ2` | 2 | large red-orange plasma sphere with corona | **PROJECTILE** |
| `PRJ3` | 2 | same family, third size | **PROJECTILE** |
| `BSPR` | 10 | red blood spray burst, fine particulate | PAYLOAD (blood-themed) |
| `XMT1` / `XMT2` | 14 / 15 | red meat-and-blood spray arcs | PAYLOAD (gore) |
| `XDSL` | 9 | tumbling bone/limb, 8 tumble angles | PAYLOAD (gib) |
| `SAGB` | 10 | **a complete unused Baron gib-death animation** — not FX. No MG monster references it. | — (see F.3) |

### F.2 Candidates I did NOT verify

Named here so nobody reads their absence as a negative: `BLHT BNP1 BNP2 BNP3
BRIB CYGA CYGG CYGP CYGT HND3 HND4 HND8 IMPC LEG1 LEG4 LEG8 LGI1–5 MANA PBLE
PBLS SM7K TROG XARM XDT1 XFT3 XHE2 XHE4 XHE8 ZXZ1 ZZD4` — **32 prefixes, ~250
lumps, not viewed.** `XHE2 XHE4 XHE8 XDT1 BNP1 MANA CYGA` failed my patch
decoder (likely PNG-in-`.dat` or a non-patch format) and need eyes another way.

### F.3 Free finding: unused monster art in the same folder

`SAGB` (10 frames) is a finished Baron/bruiser dismemberment death sitting in
`SPRITES\mg` that **no class in `hf_mg_monsters.zs` references**. Same for
`TROG` (5), `ZXZ1` (5), `ZZD4` (3), `XFT3` (4), `IMPC` (7). If the set is
imported, these are additional death branches already paid for.

---

## G. THE NAMING PROBLEM

### G.1 The author's name — one occurrence, and it is genuinely new

**Line 3:** `// template. These are Sergeant Mark IV's Meatgrinder monsters (their states,`

A search of the entire `E:\RS_Main` tree for that name returns **0 files**. This
is the one item in the file that introduces something the repo has never carried.

### G.2 The mod's name — 42 occurrences, and 17 of them are live code

| where | count | live code? |
|---|---|---|
| `MonIdentity()` return strings — `set:meatgrinder` | **17** | **YES** — runtime keyword strings, one per monster, read by the champion/legendary/arcade systems |
| header and section comments | 25 | no |

`set:meatgrinder` is the sharpest case: it is not a comment, it is a keyword the
game's systems match on.

**But the repo has already made a decision here, and it points the other way.**
`MeatGrinder` appears on **41 lines across 17 files** in `E:\RS_Main` today,
outside `docs/` — including `zscript/player/VR_PlayerClasses.zs:523`,
`Player.DisplayName "MeatGrinder"`, which is **player-facing**. The weapon half
of this same pack shipped long ago as the `RS_PS_` set and `SNDINFO:827` labels
it `// MeatGrinder set (RS_PS_)`.

So: whether `set:meatgrinder` is a violation is the owner's call, not mine —
the repo currently treats "MeatGrinder" as an in-house set name. The author's
name (§G.1) is a different matter and has no precedent here.

### G.3 The class prefix

`HF_MG*` on all 18 classes. `HF_` is the previous port's prefix — the one
`TRNSLATE.txt:6` calls out by name and this repo abandoned. The repo's own
established prefix for **this exact pack** is `RS_PS_`
(`sprites/weapons/rs_ps_weapon/`, `sounds/rs_ps_weapon/`, 10 weapon classes,
`RS_PS_Weaponset`). Per the standing rule that these prefixes are a fixed
scheme and are never coined fresh, the set prefix is a question for the owner,
but the repo's existing answer for this pack is `PS`.

*(The in-flight staging lane has chosen `RS_MG*`, which is a third option.
Reporting, not arbitrating.)*

### G.4 Asset path names

* `sprites/mg/`, `sounds/mg/`, `sounds/meatgrinder/` in ART SOURCE — these are
  source-side folder names and only become repo names if copied verbatim.
* **No lump name in the 225-lump manifest encodes the mod name.** They are all
  4-char Doom sprite prefixes. Nothing to rename on the asset side.

---

## Summary of what a complete import requires

| item | quantity | blocker? |
|---|---|---|
| Author the `HF_Monster` / tier-API base the set extends, or reparent it onto RS's own monster base | 1 class + ~6 API members | **hard blocker** |
| Author the missing gore/projectile actors | **52 classes**, 484 call sites | **hard blocker** |
| Substitute or wrap 5 more against existing `RS_PS_` FX | 5 | verify behaviour first |
| Copy custom sprite lumps | **225** (223 from `SPRITES\mg`, 2 from `MONSTERS\REVENANT\GORE`) | — |
| Import `PAINX0` | 1 | else PE corpse invisible |
| Import or replace `NULLA0` | 1 | else a 0-tic no-op |
| Resolve `REVP` E,F,G,I,J,K,L rotation contention | **7 frames** | **silent breakage** |
| Do **not** bulk-copy `SPRITES\mg` — `BOS2 P/Q/R` hits a live RS Hell Knight | 3 frames | **silent breakage** |
| Do **not** copy `SPRITES\meatgrinder` at all | 49/50 already imported as `RS_PS_` | — |
| Define 4 SNDINFO logical names | 4 | 2 of them (`MGUN2`, `enemysg`) **have no source lump anywhere** |
| Provide tier translations | **192** `hfmon_*` names constructed, **0** defined; RS's scheme is `rs_<fam>_t<NN>`, 135 entries / 15 families | Mastermind + Cyberdemon have **no** family at all |
| Fix transcription defects | `TNT1 H` ×2 (lines 880, 894); Caco `Death2` unreachable + jumps to an undefined `XDeath`; Chaingunner `Death4/5` unreachable; `tintFam "spider"` on both Arachnotron and Mastermind | — |
| Accept a new Doom-1 audio gap | **20 / 75** vanilla sound names mute on `doom.wad` | sprites are covered; sounds are not |

**Tier capacity, honestly:** 0 tiers from art, 0–12 per monster from palette
translations, 2 monsters with none.

---

*Everything in this document is a measurement, not a plan. Scope, priority and
naming are the owner's to decide.*
