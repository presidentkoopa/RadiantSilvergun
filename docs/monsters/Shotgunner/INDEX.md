# Shotgunner — family 02

CHP source: `E:\New folder\ART SOURCE\CHP\DECORATE\02\02_*.txt`
CH parents: `E:\New folder\ART SOURCE\CH\decorate\Shotgunners.txt`
Code: `zscript/monsters/RS_Shotgunner.zs`

---

## The tiers

| tier | CHP file | CH parent | body | what it is |
|---|---|---|---|---|
| T00 | `02_C` | CommonSG | SPOS | vanilla 3-pellet blast |
| T01 | `02_G` | GreenSG | SGUG | seven-bolt plasma shell fan |
| T02 | `02_B` | BlueSG | SGUB | triple railgun, seeking lance inside 350 |
| T03 | `02_CY` | CyanSG2 | CNSG | frost buckshot, bunny-hops out of your line |
| T04 | `02_P` | PurpleSG | HMZP | hazmat: charges in, then a three-shot burst |
| T05 | `02_Y` | YellowSG | ASGZ | assault shotgun, 16 rounds then a real reload |
| T06 | `02_A` | AbyssSG2 | ABSG | leaping shotgun + splash rain, enrages on pain |
| T07 | `02_F` | FirebluSG2 | SGUF | five-way fireblu shell |
| T08 | `02_BR` | BrownSG2 | QSZM | twenty mud pellets, or a charge |
| T09 | `02_GY` | GraySG2 | GRSH | sniper — digs in and becomes a turret |
| T10 | `02_R` | RedSG | GPOS | 15–20 pellet spray that jams, or red mess |
| T11 | `02_K` | BlackSG3 | ZSP2 | **CREW COMMANDER** — airstrike, snipe, gas, squad |
| T12 | `02_W` | WhiteSG2 | BENE | **BENELLUS, GOD OF SHOTGUNS** |
| TEX | `02_WX` | WhiteSGEX | BENE | **GREEN BENELLUS** — the EX tier |

---

## State diff against CHP — done 2026-08-05, and it is CLEAN

This had never been done for family 02. Every tier was opened and compared
against its CHP file. **All fourteen match.** Specifically verified:

- T00–T02: the 3-pellet blast, the seven-bolt fan's exact angles
  (1/0/-1/2/-2/3 then -3 on the lowering frame), and the three stacked
  railgun beams with their per-beam colours and sparsity.
- T03: the bunny-hop, including CHP's `thrustthingz(0,48)` → `RS_HopZ(12)`
  and `thrustthingz(0,28)` → `RS_HopZ(7)` — the n/4 conversion is right in
  every instance.
- T04: `A_SkullAttack(12)` charge and the `Goto Fire1` refire loop.
- T05: the full 16-round ASGZ magazine, `A_CPosRefire` between shots, and
  the 60-tic NOPAIN reload window.
- T06: the double-hop abyss barrage, both 47-splash rains, and PEP —
  hurt it once and it stops flinching permanently.
- T07–T09: the five-way fire shell, the twenty mud pellets (10+10 with
  opposite pitch bands), and the sniper's dig-in (squash to 0.3 height,
  speed 2, NOPAIN, then a permanent turret loop).
- T10: the five-projectile red mess and the one-shell-then-jam shotgun.
- T11/T12/TEX: compared by state-label set, which is what exposed the
  Undertaker's missing economy in family 01. All reachable CHP labels are
  present. CHP's `OtherM` is our `Missile.TEX.Close` — same four-way jump,
  renamed because we enter it through `A_JumpIfCloser(1500)`.

### Two deviations, both deliberate

- **T03 loses CHP's `CallACS("CH_CyanBounce")` gate.** In CHP that call can
  return 1 and SUPPRESS the bounce. Ours has no ACS, so the cyan sergeant
  bounces more often than CHP's does. Documented as a stripped CallACS gate
  in the file header; recorded here because it is a real behavioural
  difference, not a no-op.
- **`Easter:` / `EasterIsOver:` are absent from T12 and TEX, correctly.**
  These play Benellus's theme (`Bene/Song`) once. **The only jump into them
  is commented out in CHP itself** — `02_W.txt:38` and `02_WX.txt:49` both
  read `BENE A 0 //A_jumpifinventory("LDLegendaryMonsterTransformed",1,"Easter")`.
  The branch is dead in Colourful Hell Plus. Our SNDINFO already maps
  `bene/song → BENEFARE`; it sits unused, which is faithful. **Do not
  "fix" this by adding the states.**

---

## The CH parent properties — done 2026-08-05

See `docs/rs_24_ch_parent_properties.txt` for the mechanism. What is
specific to this family:

- **SPECIES IS NOT ONE VALUE.** CH splits the family across `SGuy`
  (T00, T02), `SGuy2` (T04, T08), `SGuy3` (T01), then `BlackSG` (T11) and
  `BENE` (TEX). With `+DONTHARMSPECIES` that is **selective infighting** —
  a green sergeant shreds a purple one and spares its own kind. T09 gray
  gets no Species at all and fights everybody. Do not normalise these.
- `+NOFEAR` on eleven of fourteen. Family 01 has it on bosses only.
- Mass 4200 on the cyan, 5000 on the fireblu and the red, against 110 for
  the rank and file. Those three cannot be shoved by anything.
- T09 is the only tier with BOTH `+AVOIDMELEE` and `+MISSILEMORE` — back
  off and shoot, which is what the turret exists for.
- Both Benellus tiers take 2× fire and 2× melee but only **0.75 from
  untyped damage**. Bullets are the wrong answer; a rocket or a chainsaw
  is the right one.
- Splash taken spans 0.33 (T11) → 1.5 (T12) → 2.0 (TEX).

### Bug found and fixed in the same pass

`OnTierApplied` read `bool floaty = (t == 12)`, so **TEX walked**. CH gives
`WhiteSGEX` (`Shotgunners.txt:2532`) the same `+FLOAT +NOGRAVITY +FLOATBOB`
as `WhiteSG2`. Green Benellus hovers. The hover set now lives in the tier
row for both.

---

## What is knowingly NOT done

- **No attack catalog.** Family 01 has `CATALOG.md` with 32 entries in
  rs_21 §4 format. This family has none.
- **No ACS audit.** Family 01 has `Zombieman_ACS_GAPS.md`. The only ACS
  touchpoint found incidentally is T03's bounce gate, above; nobody has
  swept `02_*` for the rest.
- **No full state transcription.** Family 01 has three files covering
  every sprite, frame, tic and argument. The diff above establishes that
  ours MATCHES CHP; it does not transcribe CHP.
- **No attack profiles and no catalog accessors.**
- **Not moved into its own folder.** rs_23's rule is that a family owns its
  name in `zscript/`, `attacks/`, `sprites/` and `docs/`. Only `docs/` is
  done.
- **T11's squad summon** (`RS_CallSquad`) is RS machinery carried over from
  the previous file, not a CHP transcription. It has not been checked
  against `02_K`.
