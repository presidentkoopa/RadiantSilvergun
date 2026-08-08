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

# Zombieman — family 01

First family ported under `docs/rs_21_port_law.txt`. Everything CHP's
family 01 does, where it came from, and what our tree does about it.

CHP source: `E:\New folder\ART SOURCE\CHP\DECORATE\01\01_*.txt`
CH parents: `E:\New folder\ART SOURCE\CH\decorate\Zombies.txt`
Code: `zscript/monsters/RS_Zombieman.zs`, `zscript/monsters/Zombieman/attacks/`

---

## The documents

| file | what it is |
|---|---|
| `CATALOG.md` | **Every attack**, rs_21 §4 format — `kind:` first, so it can be chosen from a list without opening code. 32 entries. |
| `README.txt` | Tier-by-tier prose, the sub-variant table, every ACS script quoted, and the gap list. |
| `Zombieman_T00-T04.md` | Full state transcription, T00–T04. Every sprite, frame, tic and argument. |
| `Zombieman_T05-T09.md` | Same, T05–T09. |
| `Zombieman_T10-TEX.md` | Same, T10–TEX, including all ten Undertaker missile branches and Player X's twenty states. |
| `Zombieman_ACS_GAPS.md` | The ACS audit and the line-by-line diff against our code. |

Written by five independent readers. Where two disagreed the disagreement
is recorded rather than reconciled — that is the point of having read it
twice.

---

## The tiers

| tier | CHP file | body | what it is |
|---|---|---|---|
| T00 | `01_C` | POSS | vanilla zombieman |
| T01 | `01_G` | ZOMG | gas rifle — poison cloud on impact |
| T02 | `01_B` | ZOMB | triple burst |
| T03 | `01_CY` | CYNT | ice bolt |
| T04 | `01_P` | BPOS | purple burst + seeker orbs |
| T05 | `01_Y` | CZOW | walking burst, jamming rocket |
| T06 | `01_A` | ABTR | abyss pincer bolts, mark aura |
| T07 | `01_F` | ZOMF | suicide hug, burning wake |
| T08 | `01_BR` | SGAR | sniper — bodyguard variant |
| T09 | `01_GY` | SHDT | stone volley, shrapnel burst |
| T10 | `01_R` | ZUNM | Unmaker zombie |
| T11 | `01_K` | ZOMK | "Player 9" |
| T12 | `01_W` | MAGE | **THE UNDERTAKER** — bone mage, skeleton economy |
| TEX | `01_KX` | ZMKX | **"Player X"** — SSG with a real reload, plasma, chaingun by range, gloats over corpses |

**There is no White-EX.** `01_WX.txt` is two bytes (`//`) and *is*
included; CHP stubs all 15 spawn colours to `Nothin`. Family 01 has
exactly one EX tier.

---

## What was restored in this pass

- **The Undertaker's whole economy.** The Plan marks the level; every marked
  corpse hatches a skeleton; killing a skeleton heals the boss
  `random(12,128)` and advances its ladder. `RS_MrBones` existed in this
  tree and nothing ever spawned it.
- **The ladder itself** — was fed from `Pain` (damage *taken*), gated at
  T6, and compounded multiplicatively. Now fed from skeleton deaths,
  gated to T12, and sets absolute values (Speed 16/21/28).
- **The bone tornado** — seven distinct orbiter rings advancing 8°/tic,
  against our one static `frandom` cloud.
- **The abyss conversion** (`Pain.AbyssPE`) on all ten tiers that inherit
  it, plus its trigger: `RS_AbyssPEPulse` was typed `Plasma`, so the
  chain was unreachable from either end.
- **Seven flattened damage rolls** and the green zombie's gas blast
  (`A_Explode(24,48)` → `A_Explode(random(1,8),32)`).
- **Attack profiles** for the five projectile tiers, plus ten catalog
  accessors so no new call names a raw class inline.

## The CH parent properties — 2026-08-05, and this is what finished it

The states were right all along; they are only half of a CHP actor.
`ACTOR CommonRedZombie : RedZombie` — CHP carries the STATES, but every
combat PROPERTY lives on the CH parent in `Zombies.txt`, and four porting
passes never opened it. All fourteen tiers ran one identical property set
with only hp/speed/painChance varying, which is why fourteen different
creatures all played like a plain zombieman.

Restored, per tier, with the parent name and line number on every case:

- **`+MISSILEMORE` on the ten tiers CH gives it.** Halves the "don't fire"
  distance roll. Its absence made every tier fire on the timid vanilla
  schedule. CH's ladder is a CONTRAST — T00/T06/T08/T10 cautious, the rest
  aggressive — and we had flattened all fourteen to cautious.
- **`+AVOIDMELEE` on the nine that have it.** They hold range instead of
  walking into your face.
- **A base-class defect that compounded both:** the dispatcher declared
  `Melee:` for every monster, so `MeleeState` was non-null even on tiers
  with no melee. That cost them the engine's own
  `if (MeleeState == NULL) dist -= 128; // no melee attack, so fire more`,
  AND trapped them at point-blank, where `A_Chase` checks melee first and
  returns. `ApplyTier` now re-points `MeleeState`/`MissileState` per tier.
- Species and the infighting model, per-tier damage factors, per-tier
  body size/mass/scale, `GibHealth`, and the three bosses' full flag set.

Owner confirmed in game: **the tiers now read as fourteen creatures.**
Mechanism and the plan for families 02–17 are in
`docs/rs_24_ch_parent_properties.txt`.

## What is knowingly NOT done

- **Hitscan tiers have no attack profile.** `MakeHitscan` carries no
  bullet-count field. Faking one would claim a fidelity it does not have.
- **The tier states still fire their own attacks.** The profiles describe
  them; they do not yet drive them. `MakeVolley` fires its whole count on
  one tic, so double-taps, refire loops and walking bursts cannot be
  expressed — rs_17 §4.
- **Four attacks fire from `Pain`, `XDeath` or the walk cycle.** The slot
  has no hook for those at all.
- **`element:` has no value for cold or poison.** T03 and T01 are
  described without one rather than inventing an axis. An rs_17 decision.
- **The spawn-colour axis.** 15 sub-variants per tier, each a
  `Translation` plus scaled stats. The table is byte-for-byte identical
  across all fourteen tiers, so it is one table of 14 strings for the
  whole family — recorded in `README.txt`, not built.
- **Two audio assets.** `AbyssForm` and `HEHEEENH` are called by CHP and
  ship in neither pack in a form the Common tier can reach. See the notes
  at those sites.

## CHP bugs found, and what we did

| bug | ours |
|---|---|
| `misc/gibbed/c` undefined — 11 call sites in this family. A letter-substitution pass mangled the word: `Gibbed/G`, `Bibbed/B`, `Pibbed/P`, `Yibbed/Y`, `Ribbed/R`, `Kibbed/K`. Only `/g` survived. | not reproduced |
| `AttackSound "grunt/attack"` declared on five tiers, played by no state — CH used `A_PosAttack` (which plays it), CHP swapped to `A_CustomBulletAttack` (which doesn't) | recorded |
| Bone tornado passes `CMF_AIMOFFSET` as an *angle* and `random(0,360)` as *flags*, relighting a random bitfield every call | we fire what it meant |
| `HEHEEENH` has 14 colour suffixes and no plain token — Player X is silent in CHP too | matched |
| T12's buff guard sits *after* two side effects, so it respawns its HUD icon every chase loop | not reproduced |
