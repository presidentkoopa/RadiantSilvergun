# RS_Main Handoff — Part 4

Continues from [`docs/HANDOFF.md`](HANDOFF.md) (Part 1),
[`docs/HANDOFF_2.md`](HANDOFF_2.md) (Part 2), and
[`docs/HANDOFF_3.md`](HANDOFF_3.md) (Part 3). All three still hold. None of
that is repeated here.

This part covers: the RS-flavored card menu system (level-up, status,
Weapon Selection, Player dashboard), a new main-arsenal melee weapon
(`VR_Chainsaw`), two real animation bugs found and fixed (SMG frozen fire,
an offhand-pickup arbitration bug), the GNRC_REIMPORT directive's actual
completion status, and the Promotion system — a design conversation that's
now correctly scoped but not started.

## START HERE — open the next session with this, don't wait to be asked

The user asked directly for this: whoever picks this project back up should
lead with the following, not bury it in the open-issues list at the bottom.

1. **Check `bonsai_upgrade_choices_per_gun_level`'s actual default in
   `CVARINFO.txt`.** This was mid-flight when this session ended — the
   check itself, not a decision. Do it first, it's small.
2. **Bring up the Promotion system design conversation.** Not code yet —
   the user's own words were "talk through it." See the Promotion section
   below for what's actually in code (almost nothing) versus what
   `docs/rs_00_overview.txt` says it's supposed to be (the stated answer
   to "what makes the strongest weapon in this game"). This is the
   headline item, not a side quest.

After those two, the natural next layer (see "Open issues carried
forward" for full detail): LevelUpTemplate Card 1 (raw stat pick, already
scoped), CardTemplate's floor-weapon HUD overlay (approved, unbuilt), and
two decisions nobody's made yet — `RS_Main.zip` (third handoff carrying
it) and whether Card 2 (socket → passive trait) is even wanted before
it's designed.

Everything landed in one commit: `c88a03e` (892 files, +4202/-724). That
commit bundles three things that happened in parallel and were all sitting
uncommitted at once: this session's own work, a large asset-folder
reorganization, and a full Vanilla+ weapon rebuild — see the GNRC_REIMPORT
section below for why that matters. Still no compiler on this machine;
everything below was verified statically (duplicate-class grep, brace/paren
balance, and — new this session — direct signature-checking against the
engine source at `E:\DXR2\wadsrc\static\zscript`, not just reading this
project's existing call sites).

## RS card menu system

Four GunBonsai-adjacent screens were built, all sharing one drawing
toolkit. None of this has run in-game yet (no compiler) — it's statically
verified against real engine signatures, not guessed, but "verified"
here means "matches the API," not "confirmed on screen."

### `RS_UIKit.zs` — shared toolkit, everything else calls into this

Plain static utility class (not a `Menu`). Every fill/border/text/wrap/
icon call across all four screens goes through here instead of being
duplicated per-file. Built from verified engine constraints, some of them
new corrections to what Part 3 left as open questions:

- **The automap question from Part 3 is answered: no.** `DoDrawAutomapHUD`
  is a `protected native` method on `BaseStatusBar`, callable only from a
  status bar's own `DrawAutomapHUD` override — there is no `class Automap`
  exposed to ZScript at all, and no way to render it into an arbitrary
  menu's sub-rectangle. A planned minimap panel was cut cleanly rather
  than faked. Don't revisit without new engine information.
- **`Color`'s 3-arg constructor defaults alpha to 0** — a real footgun
  (`Color(int red, int green, int blue) // Alpha is 0 if omitted`, straight
  from the engine source comment). Every color in this project's UI code
  is a plain `uint` ARGB hex literal instead, matching GunBonsai's own
  `HUD.zsc` convention (`uint colour` params) exactly. Never use the
  `Color` struct for UI tinting here.
- **`DTA_FillColor` needs `DTA_AlphaChannel, true` alongside it** to treat
  the source texture's own alpha/luminance as a mask — confirmed from the
  engine's own doc comment on the flag, not assumed.
- **`CountInv` is `clearscope`** — confirmed proof that reading play-scope
  actor data (inventory counts, weapon pointers) directly from `ui`-scope
  menu code is engine-sanctioned, not a violation. This is why
  `RS_WeaponSelect.zs` can walk `pawn.inv` and read `RS_Weapon` fields
  directly from a `Drawer()` call.
- Everything from Part 3's constraint list (`Screen.Dim` no `DTA_*`,
  `DTA_VirtualWidth/Height` mandatory, `DTA_Color` + `CR_WHITE` base,
  no line/circle primitive) still holds and is now implemented in
  `RS_UIKit.FillRect`/`BorderRect`/`DrawTextAt`/`DrawTextCentered`.

New primitives beyond Part 3's list: `WrapText`/`DrawWrapped` (measures
before drawing, used to vertically center text blocks in cards instead of
pinning to the top with dead space below), `DrawIconFit` (fits an
irregular-aspect-ratio icon into a box, preserving aspect, for the weapon
icons), `DrawToggleGrid` (a row of small boxes showing level + enabled
state, no cursor of its own — used by three of the four screens below).

### `RS_LevelUpCards.zs` — the level-up picker, replaces GunBonsai's text list

Hooks in via MENUDEF repoint only — `GunBonsaiWeaponLevelUpMenu` and
`GunBonsaiPlayerLevelUpMenu`'s `class` lines now point at
`RS_Menu_WeaponLevelUpCards`/`RS_Menu_PlayerLevelUpCards` instead of
`TFLV_Menu_WeaponLevelUpMenu`/`TFLV_Menu_PlayerLevelUpMenu`. **Zero
GunBonsai source files touched for this.** GunBonsai's own candidate
generation, XP, and upgrade application are completely untouched — this
only replaces what draws the picker, reading `giver.candidates[i]` via
`GetName()`/`GetDesc()` exactly like the old menu did.

Up to 8 cards, 4×2 grid (halves card height once past 4). Card titles/
descriptions are vertically centered in the available space instead of
pinned to the top (a polish-pass fix — the first version left dead space
under short descriptions). Card accent colors are slot-indexed (an 8-color
wheel by position), not meaning-indexed — matches the explicit "not
color-coded by element" requirement from Part 3.

**Card count is currently capped client-side at 8, but the actual
candidate count GunBonsai *generates* is controlled by
`bonsai_upgrade_choices_per_gun_level`, and its real current value hasn't
been checked.** The MENUDEF slider allows `-1` to `50`
(`MENUDEF.txt`, `ScaleSlider "$TFLV_OPT_NAME_UPGRADE_CHOICES_PER_GUN_LEVEL"`),
so the range isn't the limiter — but the user's recollection is that it's
effectively capped around 4 in practice, and that needs verifying against
`CVARINFO.txt`'s actual default before the 8-slot grid is doing anything
the game doesn't already support. **This is an explicit unfinished
action item, not resolved in this session.**

### `RS_StatusCards.zs` — replaces GunBonsai's plain-text status screen

Retargets `GunBonsaiStatusDisplay`'s second MENUDEF declaration (the one
that overrides `Class` to the offhand-aware `TFLV_Menu_UnifiedStatusDisplay`)
to `RS_Menu_StatusCards`. Three sections — PLAYER STATUS, WEAPON STATUS,
OFFHAND WEAPON — each a toggle-box grid (via `RS_UIKit.DrawToggleGrid`)
plus one shared description panel. Controls: ←→ select within a section,
↑↓ tune the highlighted upgrade's level, Enter toggles it, PgUp/PgDn
switches sections. All three route through GunBonsai's real, pre-existing
`bonsai-toggle-upgrade`/`bonsai-tune-upgrade` netevents — same bag-index
convention as upstream (0=player, 1=weapon, 2=offhand), including
upstream's own known bug where offhand toggles actually land on bag 1
server-side (`EventHandler.zsc`'s `evt.args[0] != 0` collapses 1 and 2).
Not fixed here; not this session's bug to fix.

Data is reloaded fresh every `Drawer()` call rather than cached, because
toggle/tune go through a netevent — the change lands a tic or two later,
not instantly. Matches how `TFLV_Menu_UpgradeToggle`'s own `Draw()`
override already re-reads live state every call.

The description panel's Y position floats to just below whatever's
actually drawn above it (`clamp(y + gap, 0.45*fbh, 0.80*fbh)`) instead of
being pinned at a fixed 80% — a polish-pass fix for the dead-gap problem
that showed up with only a couple of upgrades rolled.

### `RS_WeaponSelect.zs` — new, no GunBonsai equivalent

Not a retarget — GunBonsai has nothing like this. Answers the "which of
my 3 rolled revolvers do I actually want" comparison problem, and (new
capability) actually lets you **equip** what you're looking at, live,
both hands, no pause.

- Left column: MAIN and OFFHAND rows of owned-weapon icon cards (using
  the 11 weapon-archetype icons — see Assets below), border colored by
  tier (`TierAccent(EVR_Tier)`, an invented ramp — grey→silver→green→
  blue→purple→gold→orange-red — not pulled from any existing convention,
  open to change).
- Right column: two stat panels (MAIN's and OFFHAND's currently-focused
  card, shown simultaneously regardless of input focus), full stat block
  — DMG/RoF/DPS/Acc/Vel/Crit/Cyl(capacity)/Pellets/BonSoc/CND — in the
  **locked palette from Part 3** (`DMG #FF4040`, `RoF #FFD040`,
  `DPS #40FF60`, `Acc #FF8030`, `Vel #C060FF`, `Cyl #40FFF0`,
  `Pellets #4090FF`, `BonSoc #FF6060`, `CND #40C0A0`, `Crit` uses the
  palette's `(spare) #FFF040` slot), plus a weapon icon and a read-only
  upgrade-count summary (no toggle — see below for why).
- Enter equips the highlighted card into that hand, **for real**, in
  both hands — not just the mainhand.

**Weapon selection is real, both hands, via a narrow mechanism — not the
general hand-registry system.** `RS_MenuActionHandler` (`RS_MenuActions.zs`)
got two new play-scope functions: `SelectMainWeaponByIndex` (sets
`PendingWeapon`, a normal weapon switch) and `SelectOffhandWeaponByIndex`
(sets `player.OffhandWeapon` directly — there's no engine
`PendingWeapon`-equivalent for the offhand, it's a fork-level construct,
so this is a direct pointer swap, same as what the disabled
`RS_OffhandSeat.zs` already did). Both re-scan `pawn.inv` by the same
deterministic order the UI used to pick the index, since
`SendNetworkEvent` only carries ints — there's no serializable weapon
identity to pass otherwise.

**What this does NOT solve, on purpose:** a fresh floor pickup of an
offhand-flagged weapon can still silently override a deliberate choice
made here — see the `RS_Weapon.zs` fix below, which narrows but doesn't
eliminate this. The *general* re-seat system from `rs_02_weaponselect_v01.txt`
Part 2 (full arbitration against acquisition-time writers, boot-time
race safety, VP `TryPickup` morph safety) was **not built**. What exists
is the narrow "pick among what you already own" case only.

Upgrade toggling was deliberately **not** duplicated here — GunBonsai's
toggle netevents only address the *currently equipped* weapon in a hand,
not an arbitrary browsed-but-not-equipped one (no serializable weapon ID
exists for that — same limitation noted in `rs_02` Part 3J, item J6).
Manage upgrades from the Status screen; compare and switch from here.

Reachable via the **O** key (new KEYCONF bind, `rs_open_weaponselect`),
via the unified **I** key cycle (below), or Options → Radiant Silvergun
Options → Weapon Selection.

### `RS_PlayerDashboard.zs` — new, no GunBonsai equivalent

Top area shows a **MAIN vs OFFHAND comparison strip** — icon, tier, DPS,
Condition for whatever's currently *equipped* in each hand (not browsed,
unlike Weapon Select), with a "STRONGER" tag on whichever hand's DPS is
actually higher right now. This was the single idea Part 3's post-mortem
flagged as worth keeping ("which of these two do I keep" — dual-wield is
the whole premise, nothing answered it). Bottom area is a working
player-attribute toggle/tune grid, same pattern as Status's PLAYER STATUS
section, against the real player upgrade bag (bag 0).

Reachable via the unified I key cycle or Options → Radiant Silvergun
Options → Player. No dedicated keybind of its own.

### The unified "I" key — one button reaches everything

`gboh-unified-info` (Part 3's fork addition) still does exactly what it
did before for pending level-ups (offhand → mainhand → player, in that
priority order, unchanged). What changed is its fallback tail: GunBonsai's
own `ShowInfo()` used to hardcode `Menu.SetMenu("GunBonsaiStatusDisplay")`
when nothing was pending. That one line now calls
`RS_MenuActionHandler.CycleBrowseMenu(p)` instead, which advances a
per-player `user` cvar (`rs_ui_lastbrowsemenu`, new in `CVARINFO.txt`,
default `-1` specifically so the *first* press lands on Status, not
Weapon Select — got this wrong once with a default of `0`, caught it by
tracing the modulo math before shipping it) and cycles
Status → Weapon Selection → Player → Status on repeat presses. This is a
**one-line, surgical edit to GunBonsai's own `EventHandler.zsc`** — the
one deliberate exception to the "repoint via MENUDEF, don't touch
GunBonsai source" pattern this session, justified because the fallback
logic lives inside a function this session needed to extend, not replace.

Rationale: VR controller button budget is tight. One key now reaches all
three browse screens plus the level-up flow; **O** still exists as a
direct-jump shortcut to Weapon Select and costs nothing if left unbound
on a VR controller.

### Assets

- `textures/RS_UI/RS_Fill.png` — 8×8 opaque white PNG, the fill-rectangle
  primitive every `FillRect`/`BorderRect` call blits (GZDoom has no flat-
  color-rectangle primitive, per Part 3's `Screen.Dim` finding).
- `textures/RS_UI/icons/` — 11 weapon-archetype icons the user supplied
  (`BFUGA0`/`CSAWA0`/`LAUNA0`/`MGUNA0`/`PISTA0`/`PLASA0`/`REVOQ0`/
  `RIFPA0`/`SGN2A0`/`SHOTA0`/`SMGZA0`). Two (`REVOQ0`, `RIFPA0`) were
  missing their `.png` extension on export — fixed on copy. One icon per
  *archetype*, shared across both weapon sets where the archetype exists
  in both (matches the keyword system's stated direction: organize by
  attack type, not by owning mod). No Fist icon — melee stays iconless.
  Deliberately placed outside `sprites/` to avoid any risk of colliding
  with the real in-world pickup/voxel sprite namespace.

## VR_Chainsaw — the main-arsenal's first melee weapon

`RS_Chainsaw.zs`, 6 identities (`VR_Chainsaw` "Sawtooth" /
`VR_Chainsaw2` "Ripsaw" / `VR_Chainsaw3` "Hacksaw" — mainhand;
`VR_Chainsaw4` "Bonesaw" / `VR_Chainsaw5` "Timber" / `VR_Chainsaw6`
"Ripper" — offhand). Full `RS_Weapon` architecture (RollStats/Tier/
Condition/GunBonsai sockets), same as every ranged main-arsenal weapon,
adapted for melee: no ammo, `AmmoUse 0`, no `AmmoType1`/`AmmoType2`.

**Assets were already 90% staged before this session touched it** —
someone had already copied the model (`Models/Weapons/Hud/VR_Chainsaw/
chainsaw.md3`+`.png`, renamed to match this project's per-weapon-folder
convention), the sprites (`sprites/weapons/rs_weapon/vr_saw/SAWGA0`
through `SAWGP0`, raw Doom-format lumps, correctly extensionless — not
broken like the icon files above), and the sounds
(`sounds/rs_weapon/vr_saw/CSAWDRAW`/`CSAWLOOP`/`CSAWREDY`/`CSAWSTOP`/
`CSAWSTRT`, valid WAVs) — matching filenames from the source pack
(`1.0b_Weapons_VanillaVRPlus_v1.2`, on the user's D: drive Steam library)
exactly, but none of it was ever registered or wired to a weapon class.
This session finished that: `SNDINFO` entries (`sawdraw`/`sawloop`/
`sawredy`/`sawstop`/`sawstrt`, bare names matching the main-arsenal
convention, not `rs_`-prefixed), `MODELDEF` blocks (one per identity,
same shared-model-per-class pattern as SMG/Chaingun, using the source
pack's own verified frame indices — `SAWG A/B/C/D` → model frames
`0/3/5/7`, `Scale -1.5 1.5 1.5`, `Offset 0.0 14.0 0.0` — not guessed),
and the actual weapon class.

Idles wobbling A↔B, attacks wobbling C↔D — matches the source pack's own
4-frame model and vanilla Doom's own two-idle/two-attack chainsaw frame
convention. `RateOfFire` set to 9 (not a round number) specifically to
match the real 4-tic swing animation length, so the Weapon Selection
screen's DPS math stays honest instead of overstating a rate the
animation can't actually sustain.

**Deliberately not wired into any spawn loadout, give-command, or loot
path.** The only way to get it right now is `give VR_Chainsaw` from the
console. This was the user's explicit ask ("allow only max of 2 for dual
classes for now") — satisfied by construction (nothing automatic exists
yet, so nothing exceeds whatever's manually typed), not by building and
then gating a limit. If a menu/give-command exposing one pair is wanted
later, that's unbuilt, not just unbound.

## Two real animation bugs found and fixed

### SMG: the gun body was frozen during fire

`RS_SMG.zs`'s `Shoot:` state held a static `SMGG A` frame for the entire
fire cycle and only showed the real recoil frames (`SMGF A/B/C`, fully
bound in MODELDEF at frames 4/5/6) on a separate flash-overlay psprite
layer — meaning the actual gun model never visibly moved. There was an
existing comment claiming this was "confirmed against the original
working reference." It wasn't — the user's own reference file (`old
VR_SMG.zs`, a pre-`RS_Weapon`-architecture version built on a different
`HF_Weapon` base) clearly steps the main sprite through `SMGF A→B→C` as
the real recoil animation, with `SMGG A` used only as a one-frame
transitional "settle" beat between bursts.

Fixed: `Shoot:` now plays `SMGF A/B/C` on the main sprite (the actual
fix), leaving `Ready`/`Deselect`/`Select` on `SMGG` unchanged (verified
correct — current `MODELDEF` has zero `FrameIndex SMGS` bindings for any
of the 6 identities; the sprite files exist on disk as flat 2D leftovers
but were never given a 3D binding). **Explicitly did not restore the old
reference's `SMGS`-based idle pose** — it would render as a flat 2D
sprite popping in against an otherwise-fully-3D weapon, and the user
plays in VR specifically, where a flat sprite reads far worse than on a
flat screen. Confirmed this was the right call before touching it, not
assumed.

Chaingun was checked for the same pattern and does **not** have it —
`MODELDEF` only ever defines two frames for it (`CHGG A`/`B`, frames
4/10) and the existing `Shoot:` state already alternates between both.
Nothing bound-but-unused, unlike the SMG. No fix needed.

### Offhand pickup arbitration — narrow fix, not the full system

`RS_Weapon.zs`'s `AttachToOwner` used to unconditionally overwrite
`player.OffhandWeapon` on *any* offhand-flagged pickup — meaning a
deliberate choice (via `RS_WeaponSelect.zs`, above) could be silently
undone by walking over any dropped offhand-flagged weapon. Fixed with a
guard: only auto-seat if the offhand is currently empty *or* currently
holds the melee filler (`VR_Fist2`/`RS_VP_Fist2`, exempted by name —
every class's `Player.StartItem` list grants the fist filler before the
real starting weapon specifically so it gets bumped immediately at spawn,
verified against `VR_PlayerClasses.zs` before shipping this, since a
naive "don't overwrite if occupied" version would have made every class
spawn holding a fist instead of their real starting weapon).

**This is the narrow fix, not `rs_02_weaponselect_v01.txt` Part 2's full
hand-registry system.** R1 (re-seat on demand) is now solved, via Weapon
Select above. R2 (this fix) only covers "don't clobber an already-seated
real weapon" — first-pickup-ever and spawn-time behavior are unchanged.
R3 (boot-time race) and R4 (VP `TryPickup` morph safety) were reasoned
through and don't interact with this specific fix, but were not
independently tested.

## GNRC_REIMPORT directive — actually complete, corrected the doc

`docs/DIRECTIVE_GNRC_REIMPORT.md` (new this session, previously only seen
as a comment reference in `SNDINFO`'s header) turned out to already be
**fully executed**, despite its own header still reading "approved, not
yet executed" — a stale status line from before the work landed, not a
gap. **This was a real mistake worth naming**: told the user it wasn't
done, based on trusting the document's self-reported status instead of
checking the code. The user's memory was right; corrected it by diffing
`64b7d45..c88a03e` per weapon file instead of continuing to guess.

Both halves are done:

1. **Asset folder layout** — sounds and sprites relocated into
   `rs_weapon/vr_<weapon>/` / `rs_vp_weapon/vp_<weapon>/` per-weapon
   folders, shared effects into `weapons/fx/<category>/`, hundreds of
   old scattered-location files removed, `SNDINFO` rewritten to document
   and follow the convention.
2. **The actual Vanilla+ weapon rebuild** — real source-accurate
   alt-fires (Pistol's 3-round burst, restored with its own short-
   magazine fallbacks; Plasma's rail beam), real multi-stage reloads
   (Pistol's chambered-vs-empty two-branch reload, `CHLD`/`BRLD` sprite
   sets, why `Capacity` is 11 not 10), all real sounds registered and
   called. Verified via `git diff --stat` across all 8 rebuilt files,
   not assumed from the commit existing: Pistol +112/-11, Shotgun
   +108/-11, SuperShotgun +140/-22, Chaingun +130/-18, RocketLauncher
   +50/-11, PlasmaRifle +143/-7, BFG9000 +75/-12, ARifle +91/-5.

Doc status line updated to reflect this. **Not independently
re-verified**: the directive's "no dangling lump names" guarantee (every
relocated asset's references fixed in the same pass) — looked consistent
everywhere it was actually checked, but that's not the same as a
file-by-file audit of the whole reorg.

## Promotion — the real design conversation, not started

Two user-supplied mockups (`zscript/CardTemplate.txt`,
`zscript/LevelUpTemplate.txt` — note: sitting directly in `zscript/`, an
odd location for pure design text, not `.zs` code; worth relocating to
`docs/` at some point) triggered this. `LevelUpTemplate.txt`'s "Card 3
(PROMO)" was initially and **wrongly** called "nearly free, already
works" based on seeing `ApplyUpgradeCard` exist with real-looking logic
inside it, without checking whether anything calls it. It doesn't.
`grep -r ApplyUpgradeCard` across the whole project turns up the virtual
declaration (`RS_Weapon.zs:335`) and an override on all 11 main-arsenal
weapons — and zero callers, anywhere. Dead code, same category as
`GunBonaiSockets` (Part-3-adjacent finding: write-only, read by nothing).

**What Promotion actually is**, per `docs/rs_00_overview.txt` (the
project's own founding design doc, not fully read until this session —
should have been read much earlier): borrowed from Shining Force 2. Build
a weapon to Prototype, then promote it back to Basic. Current stats take
a real cut, but *every level after that promotion rolls higher than it
would have pre-promotion, permanently* — and it's repeatable, each
promotion raising the ceiling further. The doc's own stated thesis for
"what makes the strongest weapon in this game": not tier, not rarity — a
several-times-promoted weapon at a *lower* tier can outclass a fresh,
unpromoted Prototype. This is framed as the central end-game answer for
the whole project, not a side mechanic.

**What exists in code covers a small fraction of that.** Only 2 of 11
weapons (SMG, Revolver) have any special case at all in their
`ApplyUpgradeCard` override, and it's a one-time boolean
(`Tier==Prototype && newTier==Basic`) granting a flat `+1 PelletCount`.
No rank/times-promoted tracking field exists anywhere on `RS_Weapon`. No
mechanism scales `RollStats`' roll ranges based on promotion history —
Basic-tier rolls the same fixed range every time regardless. No explicit
stat-reduction penalty beyond just re-rolling at the lower tier's
naturally lower range. The other 9 weapons (including brand-new
`VR_Chainsaw`) have zero promotion-specific logic.

**User's decision: talk through the design before writing any code.**
This is base-architecture work (a new persistent field, `RollStats`
restructuring to scale by rank at every tier — the doc's own "Uncommon
weapon obliterating tier 3-4" example requires the boost to apply below
Prototype too, not just at the sacrifice point) plus a real design
decision per weapon archetype (the doc says "+X pellet for shot-weapons,"
implying non-pellet weapons need their own distinct reward — completely
undefined for the other 9 weapons). **Do not start building this without
that conversation happening first — it was explicitly deferred, not
approved.**

### The two mockups' other open items (also deferred, not built)

- **`CardTemplate.txt`** — a 3-column comparison (offhand / weapon on the
  floor / mainhand), full stat block, double-tap-to-apply-offhand /
  hold-to-apply-mainhand interaction. User decision: show automatically
  near *any* dropped weapon, accepting the risk that this may be noisy
  for irrelevant floor weapons, tunable later. **Architecturally
  different from every menu above** — this is a HUD overlay triggered by
  world proximity + a fire-cooldown gate (RS_Weapon already stamps a
  last-fired tic via `A_RS_MarkFired()` on every shot, so "hasn't fired
  in 3 seconds" is cheap), meaning it needs `RenderOverlay`
  (GunBonsai's own HUD pattern), not another `OptionMenu` subclass. Not
  started. Also flagged, not yet resolved: `RATE FIRE` and `TIME SHOTS`
  are the same number in two units in the current stat model
  (`RateOfFire` vs `1/RateOfFire`) — redundant unless one is meant to be
  something else (a post-Condition-penalty effective rate, maybe).
- **`LevelUpTemplate.txt` Card 1** (raw stat pick, e.g. "+1 BASE DAMAGE")
  — this is Part 3's already-scoped "level up a raw stat doesn't exist
  yet" gap, with a recommended fix already written down (small
  `TFLV_Upgrade_BaseUpgrade` subclasses registered in BONSAIRC so they
  ride GunBonsai's existing candidate list). Real, medium-sized, not
  started. Open question raised, not answered: does a flat numeric pick
  compete fairly for a card slot against a real GunBonsai affix, or does
  it read as filler every time?
- **`LevelUpTemplate.txt` Card 2** (GunBonsai socket → unlocked passive
  trait) — `GunBonaiSockets` is a real, rolled field
  (`RS_Roll.SocketsForTier`) that nothing in the project reads. Building
  this literally means designing and building a whole passive-trait-slot
  system from nothing, which is worth naming as being in real tension
  with this project's own stated anti-scope-creep principle ("curated
  vocabulary... not Borderlands-style procedural gun soup," Part 3). Not
  scoped as "big, do it last" — flagged as needing its own "do we even
  want this" conversation before it's scoped at all.
- Card count: confirmed the existing up-to-8, 4×2 grid stays (3 in the
  mockup was just what that particular example had, not a literal
  target) — but see the `bonsai_upgrade_choices_per_gun_level` open item
  above; the grid supporting 8 doesn't mean the game currently generates
  that many.

## Open issues carried forward

Still open from Parts 1–3 (unchanged, not touched this session):

- Infinite ammo on the 3 main-arsenal heavy weapons.
- `RS_BallisticTracer` architecture debt.
- The "locked stat" system (`LockedDamage` etc.) still does nothing.
- Condition/backfire still fully disabled
  (`RS_Roll.GetConditionEffects()` wrapped in `if (false)`).
- `RedFlash.png` still missing.
- `zscript/monsters/RS_TEX_*.zs` still unwired.
- UI sprawl review — still not done, still explicitly on hold pending a
  dedicated pass (note: `RS_MainOptions` grew by two more branches this
  session — Weapon Selection, Player — on top of the six Part 3 flagged;
  worth remembering when that review finally happens).

New this session:

- **`bonsai_upgrade_choices_per_gun_level`'s actual current value is
  unchecked.** Explicit next action, was about to happen when the
  conversation moved to the commit/asset-reorg question instead.
- **Promotion system** — see above. Design conversation is the next
  step, not code.
- **`CardTemplate.txt`'s floor-weapon HUD overlay** — approved in
  concept (always-show), zero code written. Different architecture
  (`RenderOverlay`) from everything else in this handoff.
- **`LevelUpTemplate.txt` Cards 1 and 2** — Card 1 medium/scoped, Card 2
  needs a design decision before it needs a design.
- **`RS_Main.zip` (52 MB)** — still untracked, still no decision, still
  not gitignored. Third handoff in a row carrying this forward.
- **The general offhand hand-registry system** (`rs_02_weaponselect_v01.txt`
  Part 2, R2–R4 beyond what this session's narrow fix covers) — still
  not built. Floor-pickup arbitration is narrowed but not solved for the
  first-ever-pickup and boot-race cases.
- `zscript/CardTemplate.txt` and `zscript/LevelUpTemplate.txt` sitting in
  `zscript/` rather than `docs/` — cosmetic, low priority, noted above.

## Working agreements (learned the hard way this session)

- **A confident-sounding comment or doc status is a claim, not a fact —
  check the code or the diff before repeating it.** Two separate
  mistakes this session came from exactly this: the SMG's "confirmed
  against the original reference" comment (wrong), and
  `DIRECTIVE_GNRC_REIMPORT.md`'s "not yet executed" header (stale). Both
  were caught by going back to source (the user's reference file; `git
  diff`) instead of taking the written claim at face value.
- **A method existing with real-looking logic inside it is not the same
  as the system working.** `ApplyUpgradeCard` looked like a working
  feature until `grep` showed zero callers. Check for callers, not just
  for a plausible implementation.
- **Read the project's own founding design doc before assuming you
  understand a named system.** `docs/rs_00_overview.txt` should have
  been read at the start of this session, not near the end after
  mischaracterizing Promotion. It directly defines Bits, the tier
  ladder, GunBonsai sockets, and Promotion in the author's own words —
  all of which this session touched or discussed before reading it.
- **When the user pushes back with "do you understand X," the honest
  answer is sometimes no — say so and go verify, don't defend the
  earlier claim.**
- Communication preference, reconfirmed hard this session: short,
  direct, no hedging paragraphs, no restating what was already said. Get
  to the point, especially when correcting a mistake.

## Read order for the next session: this doc → SUPPLEMENTAL → RS_BLOCKS

`docs/HANDOFF_4_SUPPLEMENTAL.md` — written by a parallel session that ran
alongside this one, covering the asset-naming pass, the Vanilla+ weapon
rebuild's verification, the effect catalog, and real compile errors it
found and fixed in files this session touched (`RS_StatusCards.zs`,
`RS_MenuActions.zs`, `RS_VP_PlasmaRifle.zs`). Also documents its own
mistakes (over-broad renames, a global rewrite script that corrupted two
files and had to be reverted via git, case-sensitivity misses) — read
those before running any similar rename/reorg pass again. It ends by
pointing at the same next document:

`docs/DIRECTIVE_RS_BLOCKS.md` — concept-only, no code. Proposes
**replacing `RS_Menu_WeaponSelect`** (this session's own Weapon Selection
screen, above) with a different shape, on the stated reasoning that the
current one "answered the right question with the wrong shape — a text
stat dump with no visual identity, no offhand parity, and no relationship
to the card templates the rest of the project is built around." The
supplemental also independently found a real layout bug in the current
screen (icon box height wrongly derived from panel width, pushing stat
rows outside the panel) and declined to patch it for the same reason:
this screen is getting replaced. Read `DIRECTIVE_RS_BLOCKS.md` before
touching Weapon Select again, and before assuming this session's version
is the settled design. Its first open decision: paused menu or live
overlay — that choice shapes the whole rebuild.
