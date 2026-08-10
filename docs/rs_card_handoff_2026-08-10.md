# Drop card — state at 2026-08-10

**The card does not appear. It never appeared once during this session.**
Everything below is written so the next session does not re-run the same
six wrong guesses. Verify anything you act on; ask the owner about scope.

## What is confirmed working

- The **drop, marker and glow** are fine. The gold diamond is visible in
  the owner's screenshots at range. `RS_DropBeacon` (tapering shaft),
  `RS_DropGlyph` (diamond = weapon, circle = imprint) and `RS_DropHalo`
  all render.
- The **engine side is built and verified**: multi-line `BB_TEXT`, the
  42-font roster, per-billboard font slots. Compiled clean, committed and
  pushed on `mine/neon-text`.
- The card **is built at least once** — the renderer printed
  `BB_TEXT: first SDF draw -- "THE DROP" ... scale 0.0001`, and only the
  card produces that string.

## What is NOT confirmed

Whether the card is ever POSITIONED, SIZED or DRAWN visibly. No trace of
it has been seen on screen at any distance.

## Two real bugs fixed — neither resolved it

1. `RS_Panel.SyncBackend` laid the card out at `mWidth`, the panel's
   CURRENT size. The approach ramp shrinks that to `rs_drop_cardminscale`
   (0.02) before the first layout runs, so the compositor captured a
   2%-size card as its BASE. `Rescale(1.0)` then returned 100% of 2%.
   Fixed with `mBaseW`/`mBaseH` — layout size kept separate from drawn
   size.
2. `RS_BBComposedPanel.ReleaseAll` cleared the parts but kept `mBaseW`,
   `mBaseH` and `mScale`. A rebuild therefore resized against a stale
   table, and `Rescale`'s `f == mScale` early-out skipped the first call
   entirely. Fixed.

Both are correct fixes. Neither made a card appear.

## SIX WRONG DIAGNOSES — do not repeat these

| Claimed | Reality |
|---|---|
| Card fragments visible in-world | That was the GunBonsai HUD |
| Aspect ratio was wrong, go portrait | Mockup is 520px wide with a 150px column = the `w*0.30` already in code. Reverted |
| 4,692 lines had never compiled | They compiled at the 09:00 boot |
| The assembly is never registered | It is, at `RS_EliteDrop.zs:1520` |
| Spawn distance was the whole problem | Contributing, not causal |
| Owner ignored the diagnostic | He never got a clean boot to run it in |

Every one of these came from reasoning off a screenshot or a partial
read instead of instrumenting. **Do not diagnose this from a
screenshot.**

## The trace, added at the end of the session

`rs_card_trace` (default true) narrates the chain, one line per stage,
in the order a card comes into being. Wherever the output stops is where
the card dies:

```
considering drop: dist N radius N IN RANGE   RS_EliteDrop.ConsiderDrop
RaiseCard: building for <class>              RS_EliteDrop.RaiseCard
Build OK: N panel(s)                         RS_DropTriptych.Build
registered for solving, slot N               RegisterAssembly
laid out '<heading>' at WxH -> N part(s)     RS_Panel.SyncBackend
placed at (x,y,z) drawn size WxH scale S     RS_Panel.SyncBackend
```

Plus `[CARD]` once a second from `TrackCard` with `cardpos` vs
`droppos` — if those disagree the card is being drawn somewhere the
player is not standing.

**All trace calls are temporary and come out once a card is confirmed.**

## Traps that cost hours today

- **`build-dxr`, not `build-clean`.** The owner runs
  `E:/UZDXREMA/build-dxr/RelWithDebInfo/doomxr.exe`. One source tree,
  two output folders; a whole day of engine work went into the exe he
  never launches. `build-clean` should probably be deleted.
- **QZDoom is not the fork.** A boot log starting `QZDoom version ...`
  cannot run billboards at all — every `BBF_*` is fork-only.
- `bNOSECTOR` / `bNOBLOCKMAP` are **read-only**; use
  `A_ChangeLinkFlags`.
- The class enumeration global is **`AllActorClasses`**, not
  `AllClasses`.
- A class with no scope qualifier is **DATA**. Four files needed `play`
  in two days.

## Vocabulary

`RS_DropTriptych` is a THREE-CARD comparison view the owner rejected.
`rs_panel_solo` (default true) builds only the middle card, but the
class is still named for the discarded design and the owner has said
plainly that talking about his card in that vocabulary is not
acceptable. **It is one card.** Renaming the class is worth doing.

## Distances

`rs_drop_cardnear 10`, `rs_drop_cardramp 24` — the card blooms at 34
map units and is full size at 10 (~0.3 m). That is the owner's stated
spec. For iterating, `120` / `200` makes it visible across a room; set
back before judging feel.
