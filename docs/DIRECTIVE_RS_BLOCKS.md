# DIRECTIVE: RS Blocks — a weapon selector of our own

Status: **concept document.** No code written. This exists to start the
design conversation, not to be implemented from as-is.

Replaces: `RS_Menu_WeaponSelect` (`zscript/systems/RS_WeaponSelect.zs`).
That screen answered the right question with the wrong shape — a text stat
dump with no visual identity, no offhand parity, and no relationship to the
card templates the rest of the project is built around.

---

## 1. What Gearbox proved, and what we take from it

[Gearbox](https://github.com/mmaulwurff/gearbox) (mmaulwurff, GPLv3) has a
"blocks" display mode: small numbered boxes in a row, the active group drawn
large, corner brackets on the current pick, thin fill bars for ammo. It reads
instantly and it looks like a thing rather than a spreadsheet.

**The idea is what we're taking. Not the code.**

Three techniques are worth understanding and re-deriving in our own terms:

1. **One texture, tinted at draw time.** A single white/alpha block asset
   drawn with a fill colour renders in *any* colour. No per-variant art,
   ever. For us this is the difference between "eight tier colours needs
   eight sets of block art" and "eight tier colours is free."
2. **Model/view separation.** Build the data once; let any number of
   presentations render it. Blocks today, something else later, same model.
3. **The visual grammar itself** — small/large box hierarchy, brackets for
   the live selection, bars for quantities.

## 2. The "don't copy the homework" rule

**Non-negotiable, applies to everything in this directive:**

- **No Gearbox source is copied, adapted, or transliterated into RS.** Not
  functions, not class shapes, not their `gb_ViewModel` field layout. We
  read it, we understood it, we close the tab and write our own.
- **Our naming always wins.** Nothing carries a `gb_` prefix or a Gearbox
  class name. RS conventions govern: `RS_` prefix, `RS_Menu_*` for screens,
  drawing primitives live in `RS_UIKit`, files under `zscript/systems/`.
- **Our data model governs the design, not theirs.** Gearbox's model answers
  *"which of my nine classic slots?"* Ours answers *"which of my three
  rolled Revolvers, in which hand?"* Those are different problems. Any place
  where mimicking Gearbox would bend our model out of shape, our model wins
  and the visual gets redesigned to fit.
- **Practical consequence:** Gearbox is GPLv3. A clean rebuild from concept
  carries no licence obligation; copied code would. Since our data layer has
  to be written from scratch regardless, clean-room is both the better
  engineering call and the simpler licensing one. This is a rule, not a
  preference.

If a future contributor asks "why didn't you just port Gearbox," this
section is the answer.

## 3. What we have that Gearbox never did

Gearbox shows: icon, tag, slot number, up to two ammo bars. That's the
ceiling of its data model.

Every `RS_Weapon` carries, live and per-instance:

| Data | Why blocks can show it better than text |
|---|---|
| `Tier` (Cursed→Prototype) | `TierAccent` already maps 8 tiers to 8 colours — colour the block, read the roll at a glance |
| `Condition` (100→0, degrades) | Structural wear on the block itself: border integrity, desaturation, damage tint |
| `AmmoType2` / `AmmoType1` | Magazine and reserve as two fill bars — an exact fit for the two-bar pattern |
| `GunBonaiSockets` | Socket pips, filled by affix element colour once affixes exist |
| `DamagePerShot`, `Accuracy`, `Velocity`, `CritChance`, `PelletCount`, `RateOfFire` | The comparison payload — see §5 |
| `XP` / `Level` | Progress ring or bar on the block |
| `bOffhandWeapon` | The second axis Gearbox has no concept of — see §4 |

Two rolled Revolvers can share a class, a slot, and an icon, and differ only
in invisible numbers. **That is the entire reason this screen exists**, and
it's precisely the case Gearbox cannot represent.

## 4. Main and offhand as a first-class axis

Gearbox is one-dimensional: slots left-to-right, weapons stacked within a
slot. RS is dual-wield, so hand is not a filter — it's a structural axis.

Target shape, per the user's spec:

```
   LEFT SIDE                          RIGHT SIDE
   ┌──────────────────────┐           ┌───────────────────────────┐
   │ MAIN                 │           │                           │
   │ [▪][▪][█][▪][▪]      │           │   live stat panel for     │
   ├──────────────────────┤           │   whichever block the     │
   │ OFFHAND              │           │   cursor is on            │
   │ [▪][█][▪]            │           │                           │
   └──────────────────────┘           └───────────────────────────┘
```

- Two block series, stacked vertically, both on the left.
- One stat panel on the right, tracking the focused block **live** as the
  cursor moves — not a static dump of the equipped weapon.
- Moving between hands is a real navigation axis, not a mode toggle.

## 5. Tie-in to the card templates

`zscript/CardTemplate.txt` and `zscript/LevelUpTemplate.txt` already define
the project's visual language for weapon data. **RS Blocks must share that
vocabulary, not invent a second one.**

From `CardTemplate.txt`, the canonical stat order is already settled — this
is the authority, and the block screen's stat panel should follow it rather
than the ad-hoc order the old screen used:

```
DAMAGE · RATE FIRE · TIME SHOTS · DPS · ACCURACY · VELOCITY
CRIT CH · MAG CAP · SOCKETS · CONDITION · PELLETS · RESERVED
```

Also inherited from the card template:

- **Tier drives panel colour** (the template labels each card by tier colour).
- **Three-panel comparison shape** — `OFFHAND | NEW DROP | MAINHAND`. The
  block screen is the *browsing* view; the card is the *decision* view. They
  should feel like the same product.
- **`RESERVED`** is an existing placeholder slot in the stat list. Note: the
  old build displayed a `Divinity` field here, but per `docs/rs_00_overview.txt`
  that system was removed — the slot stays reserved and empty until something
  real claims it. Do not resurrect a dead stat to fill space.

From `LevelUpTemplate.txt`: the promo/rank star display (`★★☆☆☆`) and socket
unlock concept should have a home on the block itself, so a promoted weapon
is visibly promoted in the grid.

## 6. Proposed architecture

Names are provisional but follow RS convention and supersede anything
Gearbox-shaped.

| Piece | Responsibility |
|---|---|
| `RS_WeaponEntry` | One typed object per weapon: ref, hand, tier, live stats, sockets, XP, equipped flag. Replaces parallel-array style outright. |
| `RS_WeaponGrid` | Builds and orders entry lists per hand. Pure data, zero drawing. |
| `RS_BlockView` | Renders one block: tint, fill bars, socket pips, wear state, selection brackets. |
| `RS_Menu_WeaponBlocks` | The screen. Two series left, live stat panel right. |
| `RS_UIKit` (extend) | Block primitives live here with the existing drawing vocabulary — not in a parallel toolkit. |

## 7. Open questions for the design conversation

1. **Menu or live overlay?** Gearbox draws during play with no pause. Every
   RS screen so far is a paused `OptionMenu`. For VR, an unpaused quick-swap
   is arguably far better; deep stat comparison wants a paused screen.
   Possibly both. **This choice shapes everything downstream.**
2. **Does the block grid group by slot, by weapon class, or flat by hand?**
   Three rolled Revolvers — one block each, or one block with a depth
   indicator?
3. **How much does a block show before it's noise?** Tier colour + condition
   + two ammo bars + socket pips + XP ring is a lot in a small box. What's
   the minimum that still answers "which one do I want?"
4. **Does this screen bind weapons, or only preview them?** The card template
   has explicit bind gestures (double-tap → offhand, hold → mainhand). Should
   blocks use the same gestures for consistency?
5. **Affix display** — once dozens of custom affixes exist, is the block the
   right place to surface them, or does that belong solely to the card view?
