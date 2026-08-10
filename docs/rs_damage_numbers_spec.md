# Damage numbers — spec

Written 2026-08-10. Design only; nothing built.

Prompted by looking at DamNums (Xaser Acheron). The conclusion was **build
RS-native rather than import**, and the reason is not performance — it is
that RS already measures things a generic damage-number mod has no way to
know, and those measurements are currently invisible.

---

## The point

RS has two systems whose entire purpose is *how good was that hit*:

- **Headshots** produce a quality from 0 to 1 — the distance from the
  centre of the head. A graze and a perfect shot are different numbers.
- **Crits** roll `CritChance` against `CritMult`, both rolled weapon
  stats, so a crit's size varies per gun.

Neither shows the player anything but a flash and a faster death. A
number is the natural readout, and RS is unusually well placed to make
one that means something.

**Everything below reads state RS already has.** Nothing here needs a new
measurement, a new hook, or an engine change.

---

## What RS knows that a generic mod does not

| Source | What it gives |
|---|---|
| `RS_HeadshotUtil.Resolve` | hit quality 0..1 |
| `RS_Weapon.RS_ShotWasCrit` | did this pull crit |
| `RS_Weapon.CritMult` | how hard, per gun |
| `RS_Weapon.RS_CritStreak` | Momentum, consecutive crits |
| `bOffhandWeapon` | which hand landed it |
| `RS_SystemsMaster` / elites | tier, elite colour |
| `RS_Score` | the scoring layer this feeds |
| `RS_CurseLedger` | blind curses already hide bars and bits |
| real projectiles | a hit has a **direction**, not just a location |

---

## Layer 1 — what the number says

### Size is SIGNIFICANCE, not magnitude

The single most valuable idea here, and the one no damage-number mod
does.

Scale the number by damage **as a fraction of that monster's remaining
health**, not by its absolute value. 50 damage to a zombieman is the
whole monster; 50 to a Cyberdemon is a rounding error. A mod that sizes
by raw number tells you how big your gun is — which you already know.
Sizing by fraction tells you **how much that shot mattered**, which you
cannot otherwise see.

Consequence worth wanting: chip damage on a boss stays visually quiet,
and the shot that takes a third of something's health is enormous. The
display teaches the fight.

### The killing blow is a different event

The last number lingers, punches harder, and stops moving. Overkill is
shown separately and dimmed — `247` in full colour with a faint `+88`
trailing it. You learn how much you are wasting, which is real
information for a mod with weapon degradation and ammo economy.

---

## Layer 2 — the life

This is the part that is asked for and the part that is usually missing.
A number that fades straight up is a debug readout. A number with weight
is feedback.

### It gets knocked the way the bullet went

RS fires **real projectiles**, so every hit has a genuine direction.
Carry the round's velocity into the number: a shot from below throws it
up and away, a shot from behind pushes it through and out. The number
inherits the physics of the thing that caused it.

This is free — the projectile's `Vel` is right there at impact — and it
is the single biggest difference between "a number appeared" and
"something hit that."

### Punch on spawn

Scale overshoots and settles: 1.4x on frame one, down to 1.0 across
three or four tics. Standard, cheap, and its absence is why most damage
numbers feel dead.

### Weight follows significance

A big-fraction hit produces a heavy number: it arcs higher, falls
slower, lingers. A chip hit is light and gone quickly. Same physics, two
different masses, driven off the same fraction that set the size — so
the motion and the size can never disagree.

### Crits and headshots move differently

- A **crit** kicks harder and further, matching the teal round the
  player just watched fly.
- A **perfect headshot** barely moves. It snaps into place and holds,
  because stillness reads as precision where a scatter reads as force.

That contrast is the whole grammar: force moves, precision doesn't.

---

## Layer 3 — colour and identity

Colour is carried by the same numbers that set everything else, so it
never contradicts them.

| Hit | Colour |
|---|---|
| ordinary | bone white |
| **crit** | **teal** — the same `rs_crit_teal` the round wore |
| **headshot** | gold, saturating with quality — a graze is pale, a centre hit is bright |
| **crit + headshot** | white-hot, its own tier, deliberately rare |
| killing blow | the monster's own tier or elite colour |

The crit teal matching the projectile is the important one. The player
sees a teal round leave the barrel and a teal number come off the
target. Two halves of one event rather than two unrelated effects.

---

## Layer 4 — readability, which is where these usually fail

### One number per hit. The shower IS the feature.

**Owner ruling 2026-08-10: "the damage numbers flying off is what we
want".** Every hit gets its own number, and they scatter. This is the
default and it is not a fallback.

An earlier draft of this spec made ACCUMULATE the default -- one number
per monster that grows and re-punches with each hit rather than spawning
a new one. That is the conventional answer, it is what most mods do, and
it was the wrong call here: it optimises for a tidy screen at the cost
of the exact thing that makes this fun. A chaingun emptying into a
Baron SHOULD throw a fistful of numbers. That is the readout of a
sustained burst and it is why anyone wants damage numbers at all.

What keeps a shower legible is not merging it -- it is the rest of this
spec doing its job:

* **Significance sizing** means most of a burst is small. Twenty chip
  hits are twenty small numbers, and the one that landed a third of the
  monster's health towers over them without anything being merged.
* **Hit-direction momentum** scatters them along different vectors
  instead of stacking them in one column, so they separate themselves.
* **Short lives.** Under a second each. The screen clears itself.
* **The cap** (see VR below) bounds the worst case without changing the
  behaviour in the normal one.

Accumulate stays available as a cvar for anyone who wants the tidy
version, defaulted OFF. It is a preference, not the design.

### Distance compensation

Scale up slightly with distance so a number stays readable across a
room. Without this the numbers that matter most — the long shots you are
proudest of — are the ones you cannot read.

### A floor

Nothing below a threshold draws at all. Poison ticks, fire, chip
effects: they make the screen noise and none of them are decisions.

---

## VR specifics

**They are world-space and that is not negotiable.** Screen-space
numbers pinned to the view have no depth and sit on your face. This is
the same argument that made health bars world-space, and it is written
down in `RS_HealthBars.zs` already.

**Per-hand tint.** Dual wield means two guns firing at once, and there
is currently no way to tell which hand landed a hit. A subtle warm/cool
bias on the number, read off `bOffhandWeapon`, gives that away for free.
Genuinely useful, impossible in a flat game where you only have one gun.

**Billboard toward the viewer, always.** A number readable only from one
angle is a bug in a headset.

**Cap the count.** A dozen floating numbers in stereo is nauseating in a
way it is not on a monitor. Hard limit, oldest recycled first.

---

## What not to build

- **No font zoo.** DamNums ships sixteen. RS wants one that matches its
  own type and nothing else.
- **No damage-type colour table.** RS colours by *what kind of hit it
  was*, which is more informative and is data RS already owns.
- **No per-monster ticking thinker.** DamNums watches every monster's
  health every tic. RS does not need to — the headshot and crit paths
  already know the exact moment and the exact figure. Spawn from there,
  cost nothing the rest of the time.
- **No numbers for the player's own damage taken.** That is a HUD
  concern and it is already handled elsewhere.

---

## Cost

Roughly 150 lines and one sprite font. No per-tic work anywhere: numbers
are spawned by the hit that caused them and tick only while alive, which
is under a second each.

The one piece of real work is plumbing: the headshot's quality and the
crit flag both need to reach the spawn point. The crit flag is already
on the weapon (`RS_ShotWasCrit`); the headshot quality currently lives
only inside `RS_HeadshotBrain.ModifyDamage` and would need to be handed
out rather than consumed on the spot.

---

## Open questions for the owner

1. **Does this feed the score system, or stay cosmetic?** Significance
   sizing makes it a de facto scoring readout, and RS_Score already
   exists — worth deciding before rather than bolting on after.
2. **Should a blind curse hide damage numbers?** `RS_CurseLedger`
   already hides health bars on mainhand-blind and bit drops on
   offhand-blind. This is the obvious third thing, and the precedent
   says it should probably be one of them rather than a new curse.
3. ~~Accumulate or spray, as the default?~~ **Answered 2026-08-10:
   spray.** One number per hit, they fly. Accumulate survives only as an
   off-by-default cvar.

4. **How hard is the cap?** The shower is the point, so the cap should
   be high enough never to bite in normal play and only exist to stop a
   BFG into a crowd from putting four hundred numbers in a headset at
   once. Wants a real number from play, not a guess here.

---

# Addendum — motion, glow, variety, and the font question

Added 2026-08-10.

## Scale is the life, not the colour

### Squash and stretch

The number stretches along its direction of travel while it is moving
fast, and relaxes back to round as it slows. When it stops, one quick
squash, like it landed. This single technique does more for "alive" than
every colour rule in this document.

**Non-uniform scale IS available here.** CLAUDE.md records that
non-uniform scale is impossible in a `Default` block -- that is true and
it is about the Default block only. Assigning `Scale.X` and `Scale.Y`
separately at runtime works fine, and is exactly what that note tells
you to do instead.

### Roll it along its flight

`+ROLLSPRITE +ROLLCENTER`, which `RS_HeadshotSpark` already uses. Tilt
the number to line up with its velocity so the stretch runs ALONG the
travel rather than always vertically. It tips as it arcs and straightens
as it settles.

### The life of one number

| phase | tics | scale |
|---|---|---|
| born | 0-4 | 0.3 -> 1.4 -> 1.0, fast |
| flying | 4-25 | stretched along velocity, easing to round as it slows |
| landing | ~2 | one squash |
| gone | last 8 | shrinks toward nothing while fading |

**Shrink out, never fade out alone.** Something that shrinks reads as
leaving; something that only goes transparent reads as a bug.

**Never grow on death.** In a headset a growing sprite reads as coming
at your face.

### Scale carrying meaning

* a **crit** stretches harder, because it was thrown harder
* a **perfect headshot** barely stretches -- it snaps to size and holds
  dead still
* a **big-significance** hit decays slower and hangs longer

Force stretches. Precision doesn't. That contrast is the whole grammar
and it costs nothing, because all three numbers already exist.

## Glow -- two different things, one of them free

### The free one, and it is the one wanted

"The number looks like it emits light" is just additive rendering:

* `RenderStyle "Add"` -- as `RS_HeadshotSpark` already does
* **a soft halo sprite behind the digits** -- blurred blob, additive,
  larger, low alpha. This is the trick that actually sells "emissive".
  One extra sprite draw.
* **a brightmap on the digit font** so the glyph stays crisp and full
  bright while the halo does the bleed. The repo already ships 221
  brightmaps, so that pipeline exists.

Stack the three and hundreds can be on screen.

### The expensive one, and it is probably wrong anyway

"The number lights the wall behind it" needs a real dynamic light. For
damage numbers that is arguably incorrect regardless of cost -- a number
is UI floating in the world, not an object in it, and a shower of them
casting light on geometry reads as a bug.

Where a light DOES earn its keep is the rare hit: a crit AND headshot
together, or a killing blow that mattered. Those are infrequent by
definition, so the room flashing teal for an instant means something.

### The cap, and why it is not the existing one

`RS_HiFiFX.SpawnMuzzleLight` already solves "too many dynamic lights",
capped by `rs_fx_maxmuzzlelights`. Reuse the SHAPE, not the code: it
counts by walking a ThinkerIterator on every spawn, which is fine at a
few shots per second and wrong at damage-number rates, where the scan
would cost more than the thing it protects.

Keep a plain counter on the handler instead -- increment on spawn,
decrement in OnDestroy. Constant time, same ceiling.

| tier | cost | default |
|---|---|---|
| additive + halo + brightmap | ~free | ON |
| dynamic light, rare hits only, capped | small | off |
| dynamic light on every hit | bad | never |

## Variety -- roll everything

Owner ruling 2026-08-10: roll a lot of these for variety. No two numbers
should be identical twins. Everything below is a per-spawn `FRandom`,
all of it free:

* **roll angle** -- a few degrees of tilt either side of its flight line
* **launch speed and spread** -- so a burst fans out instead of stacking
  in one column
* **lifetime jitter** -- +/- 20%, so they do not all vanish on the same
  tic, which is what makes a shower look mechanical
* **birth punch overshoot** -- 1.3 to 1.5 rather than a fixed 1.4
* **settle scale** -- +/- 8%
* **hue jitter** -- a few degrees within the hit's colour band, so ten
  white numbers are not one flat white
* **halo alpha** -- so the glow breathes across a volley

The rule: jitter presentation freely, never jitter MEANING. Size comes
from significance and colour comes from hit type, and neither may be
randomised -- the moment they are, the display stops being information.

## The font question

The repo holds **42 SDF atlases** (`sdffonts/sdf00`-`sdf41`, 1536x576,
95 glyphs each, listed in `sdffonts/MANIFEST.txt`) and two real FON2
fonts, `RSSCRFN1` (12px) and `RSSCRFN2` (7px), used by the score HUD
through `Font.GetFont`.

**None of them can be drawn directly in world space, and that is an
engine fact rather than a gap in this repo.** A GZDoom `Font` renders
only through `Screen.DrawText` (screen space) or `Canvas.DrawText` (into
a canvas texture). There is no world-space text call. Damage numbers are
world-space by requirement (see the VR section), so a Font is not
reachable.

Three ways out, with the honest cost of each:

### A. Digit sprites -- recommended

Ten sprites per typeface, generated from one of the 42 faces already
chosen for this project. Classic, and what every damage-number mod does,
because it is the only option with no per-number rendering cost at all.

* unlimited simultaneous numbers
* per-digit brightmap for the glow tier above
* one baked look per face; switching face at runtime means shipping
  another ten sprites, which is cheap

### B. Pooled canvas textures

Draw the number's text into a canvas with a real Font, display the
canvas on the world sprite. This is the machinery `RS_Panel` and
`RS_EliteDrop` already use (`TexMan.GetCanvas`).

* **any** of the 42 faces, switchable at runtime, no new art
* but a canvas is a render target, so the pool must be small and fixed
  -- claim one per number, release on death
* which caps simultaneous numbers at the pool size. Acceptable ONLY
  because a cap is wanted anyway for VR, but it hard-limits the shower,
  and the shower is the feature

### C. Slice an SDF atlas with TEXTURES

Mechanically possible -- a `TEXTURES` entry can crop a sub-rectangle of
a larger graphic, so ten entries per face would carve digits out of an
atlas with no code and no new art.

**But an SDF atlas is not a picture of the glyph.** It stores a distance
field, and it needs a shader to threshold into crisp text. Blitted
directly as a sprite it comes out as a soft blurry blob. The billboard
work already deferred SDF for this reason.

Worth noting the accident: that soft blob is close to the HALO layer
described above. The atlases may be usable for the glow behind the
digits even though they are not usable for the digits.

### Recommendation

**A for the digits, generated from one of the 42 faces. C for the halo,
if the experiment pans out.** B stays in the drawer for the day someone
wants runtime font switching more than they want an uncapped shower.

## Open question added

5. **Which of the 42 faces?** `sdf19` (Karmatic Arcade), `sdf02`
   (ArcadeClassic) and `sdf37` (StartSignal) are the arcade-legible
   candidates on name alone -- but this project's own rule is not to
   trust a name over the file. They want looking at before one is
   picked.

---

# Addendum 2 — the flight, verified against the engine

Added 2026-08-10, answering: "they spawn facing me, follow their
trajectory, and fall over flat as they hit the floor? or can they do
anything?"

**Yes, exactly that, and it needs no engine change.** Every flag below
was read out of `E:\UZDXREMA` before this was written.

## The render types are a switchable field

`src/playsim/actor.h:474-478`:

```
RF_SPRITETYPEMASK = 0x7000,   // three-bit field
RF_FACESPRITE     = 0x0000,   // billboard, faces the viewer  (default)
RF_WALLSPRITE     = 0x1000,   // fixed vertical, turns with angle
RF_FLATSPRITE     = 0x2000,   // lies flat, parallel to the floor
```

It is a FIELD, not a set of independent bits -- an actor is exactly one
of these at a time, and it can be changed while alive.

**Runtime switching is proven in the engine's own ZScript**, not
theorised: `wadsrc/static/zscript/actors/shared/sharedmisc.zs:186` does
`if (cstat & 32) bFlatSprite = true;`. So `bFlatSprite = true` mid-life
is a supported thing an actor may do to itself.

Supporting flags, all real `DEFINE_FLAG` entries at
`src/scripting/thingdef_data.cpp:367-377`:

| flag | line | what it buys here |
|---|---|---|
| `+ROLLSPRITE` | 367 | the number can roll |
| `+FLATSPRITE` | 368 | lie flat on the ground |
| `+ROLLCENTER` | 371 | roll about its middle, not its offset corner |
| `+INTERPOLATEANGLES` | 377 | **angle/pitch/roll interpolate between tics** -- this is what makes a tumble smooth instead of stepping at 35Hz |

`+INTERPOLATEANGLES` is the one that matters most and is easiest to
forget. Without it a tumbling number ticks over in visible increments.

## The default flight, start to finish

1. **Spawn** -- FACESPRITE. Billboarded, square to the player, fully
   readable the instant it appears. This is the default sprite type, so
   it is free.
2. **Punch** -- scale overshoots and settles (Addendum 1).
3. **Launch** -- velocity inherited from the round that caused the hit.
4. **Tumble** -- `+ROLLSPRITE +ROLLCENTER +INTERPOLATEANGLES`, roll
   driven off horizontal speed so it spins faster when thrown harder and
   settles as it slows. Stretch runs along the roll axis.
5. **Land** -- on floor contact, `bFlatSprite = true`. The number is now
   lying on the ground. Squash on impact, kill the roll rate, keep the
   final roll angle so it lands askew rather than neatly aligned.
6. **Settle** -- it lies there for a beat. This is the payoff: a floor
   littered with the numbers you just did.
7. **Gone** -- shrink and fade together.

## Honest limits

**There is no smooth tip-over.** FACESPRITE and FLATSPRITE are different
values of one field; you cannot interpolate between them, so the moment
of landing is a hard switch. Two ways to hide it, both cheap:

* switch on the frame the impact squash plays -- the squash covers it
* or roll the sprite toward flat over the last few tics of the fall so
  the eye is already reading it as tipping when the swap happens

Do not attempt to fake it with pitch. Pitch does nothing useful on a
FACESPRITE.

**A landed number is readable from above, not from eye level.** Lying
flat means exactly that. In VR, looking down at your own carnage is the
intended read, and it works -- but a number that lands far away is edge
on and effectively gone. That is acceptable and arguably correct; it
also means the landed state is decoration, and all the INFORMATION has
to have been delivered during the flight.

**Cap still applies.** Landed numbers persist longer than flying ones,
so they dominate the cap. Age them out faster than the ceiling suggests.

## So: can they do anything?

Within the three render types, close to it. The set worth building:

| trajectory | when | behaviour |
|---|---|---|
| **ballistic** | default | thrown, gravity, tumbles, lands flat |
| **kick** | crit | launched hard and far, fast roll, long travel |
| **snap** | perfect headshot | no travel at all -- appears, holds dead still, fades. Precision does not scatter |
| **float** | chip damage | drifts up gently, no gravity, never lands |
| **bounce** | heavy hits | one floor bounce before it settles |
| **absorb** | killing blow | see below |

### Absorb -- the one that is RS's and nobody else's

On a killing blow the number does not land. It arcs toward the player's
score readout and is drawn into it, and the score ticks up as it
arrives.

RS already has `RS_Score` and a HUD for it. Nothing currently connects
"I hit that thing" to "my score moved" -- they are two unrelated pieces
of feedback. This closes that loop with a single trajectory, and it is
only possible because the score display and the world are both things
this mod owns.

Worth flagging: the number is world-space and the score readout is
screen-space, so the last leg is a projection, not a world path. Fly it
in the world until it is near the player, then hand it to a HUD-space
sprite for the final absorb. That handoff is the only fiddly part of
this entire document.

---

# Addendum 3 — heat, shake, and per-number variety

Owner ideas, 2026-08-10: "random fonts, random size, react to proximity
to player, or projectile type, dynamic colour: hot on exit wound, cools
en route to floor, coloured according to damage severity, crit numbers
shaking and explosive".

Most of this is free. One item conflicts with a load-bearing decision and
is called out rather than quietly dropped.

## HEAT — the best idea in this document

**A number leaves the wound hot and cools as it falls.**

It spawns white-hot, cools through yellow to orange to a dull red as it
arcs, and is nearly ember-dark by the time it lies on the floor. Exactly
like something struck off molten metal.

This is a colour lerp over the number's own lifetime. It costs one
interpolation per tic and it does more for "alive" than anything else
here, because it means the number is CHANGING the whole time you can see
it rather than being a static thing that moves.

### Heat reconciles severity with hit type

Two of the ideas above look like they collide -- colour by hit type
(Layer 3) versus colour by damage severity. They do not, if they are put
on different axes:

* **HUE is the hit type.** White ordinary, teal crit, gold headshot. That
  is identity and it must stay readable.
* **TEMPERATURE is the severity.** How hot it starts, and how long it
  takes to cool.

So a chip hit spawns dull and is already cold when it lands. A massive
hit spawns blinding white-hot, holds that heat for most of its flight,
and is still glowing when it hits the floor. Same hue family, wildly
different life.

That gives severity a channel of its own without touching identity, and
the two can never contradict each other because they are not on the same
axis.

**The heat also drives the glow.** Halo alpha and size ride the same
temperature, so a big hit's bloom is fierce at birth and gone by
landing. One number, four outputs -- colour, brightness, halo, and
lifetime.

## CRIT: SHAKE AND EXPLODE

A crit number does not just fly further. It:

* **shakes** -- small per-tic positional jitter, a couple of units,
  decaying as it slows. Reads as barely-contained energy.
* **explodes outward** -- launches with a burst rather than a throw, and
  may shed a few spark particles at birth.
* **runs hotter for longer** -- the heat curve above, biased.

Contrast this against the perfect headshot, which does the opposite:
dead still, no shake, no travel, snaps to full size and holds. **Force is
loud and messy. Precision is silent and exact.** That opposition is the
whole reason both exist.

## REACT TO WHAT HIT IT

The inflictor's class is available at emit time, so the number can
inherit the character of the weapon that made it:

| round | number behaves |
|---|---|
| bullet | small, fast, sharp arc, cools quickly |
| shotgun pellet | many small ones, wide scatter |
| rocket / heavy | big, slow, heavy arc, stays hot a long time |
| plasma / energy | cooler hue bias, floats rather than falls, longer hang |
| melee | short violent throw, lands close |

Free, and it means a shotgun blast and a rocket produce visibly
different-feeling showers without anyone authoring two systems.

## REACT TO PROXIMITY

Distance to the player already drives scale compensation (Layer 4).
Extend it:

* **close hits** are more energetic -- wider scatter, shorter life, so
  they clear your face fast. Numbers hanging a foot from your eyes in a
  headset is the fastest way to make this feature hated.
* **far hits** are calmer and live longer, so a distant kill is still
  readable by the time you look at it.

This is a VR requirement dressed as a flourish. Do not skip it.

## RANDOM FONTS

Roll a typeface per number from the 42 in `sdffonts/`. Presentation, not
meaning, so it is allowed and it is cheap -- each face is ten more digit
sprites generated by the same script.

Two cautions:

* **Not per DIGIT.** Per NUMBER. Mixed typefaces inside one number reads
  as a rendering bug, not as variety.
* Some of the 42 are decorative to the point of being unreadable at
  speed. Curate a shortlist of legible faces to roll from rather than
  rolling all 42; the whole set is available for the ones a player picks
  deliberately.

Ships behind `rs_dn_fontroll`, default off -- one deliberate face is the
cleaner default and the roll is the toy.

## RANDOM SIZE -- THE ONE CONFLICT

**This one cannot be taken at face value, and it is the only idea here
that gets pushed back on.**

Size is currently the ONLY channel carrying "how much did that hit
matter". If size is randomised, that information is destroyed and the
numbers become decoration -- a big number would no longer mean a big
hit, so nobody could read the display at all.

What is already in and gives most of the feel wanted:

* **+/- 8% settle jitter** so no two numbers are identical twins
* **significance sizing** which already produces enormous variation
  naturally, because hits genuinely vary

If genuinely random size is wanted anyway, it belongs as
`rs_dn_significance = off` -- turning significance sizing OFF and letting
size roll freely. That is a legitimate preference and it is one toggle.
It must be a CHOICE though, not the default, because the default has to
mean something.

**Owner decides. Flagged rather than silently ignored.**

## New cvars implied

`rs_dn_heat` (on), `rs_dn_shake` (on), `rs_dn_weapontype` (off),
`rs_dn_proximity` (ON -- VR safety, not a flourish), `rs_dn_fontroll`
(off).

---

# Addendum 4 — EVERY ELEMENT IS ITS OWN TOGGLE

**Owner ruling 2026-08-10: "each one of those individual elements is in
the options list, ok? per-tic jitter, burst launch, run hot longer,
maintain attack momentum, etc, etc".**

This supersedes the coarser toggle grouping in Addendum 1 and the seven
row menu sketch earlier in this document. Behaviours do not ship bundled
into a "Crit Motion" switch. Each atomic behaviour gets its own cvar and
its own row.

## Reconciling this with "no nightmare menu"

The same owner also said, of the reference mod's options page, that he
did not want a nightmare menu. Both are satisfiable and neither is
negotiable, so:

* **A PRESET row sits at the top of the page** -- Off / Simple / Full.
  Selecting one writes the whole toggle set underneath. A player who
  wants this to just work never scrolls past line one.
* **The granular toggles sit below it, in labelled sections.** Someone
  tuning feel can reach any single behaviour without it being welded to
  four others.

A long list is only a nightmare when you are FORCED to read it. Behind a
preset, it is a workshop.

## The atomic list

Every row below is one cvar and one behaviour. Nothing here controls two
things.

### Core
| cvar | row | default |
|---|---|---|
| `rs_dn_enable` | Damage Numbers | ON |
| `rs_dn_preset` | Preset (Off / Simple / Full) | Simple |
| `rs_dn_max` | Max On Screen | slider |
| `rs_dn_lifetime` | Lifetime | slider |
| `rs_dn_scale` | Base Size | slider |
| `rs_dn_minimum` | Hide Damage Below | slider |

### Motion -- each independent
| cvar | row | default |
|---|---|---|
| `rs_dn_momentum` | Inherit Shot Direction | ON |
| `rs_dn_gravity` | Ballistic Arc | ON |
| `rs_dn_tumble` | Tumble In Flight | off |
| `rs_dn_landflat` | Fall Flat On Floor | off |
| `rs_dn_bounce` | Bounce On Landing | off |
| `rs_dn_shake` | Per-Tic Shake | off |
| `rs_dn_burst` | Burst Launch (crits) | off |
| `rs_dn_snap` | Headshots Hold Still | off |
| `rs_dn_float` | Chip Damage Floats | off |
| `rs_dn_absorb` | Killing Blow Flies To Score | off |

### Scale -- each independent
| cvar | row | default |
|---|---|---|
| `rs_dn_punch` | Birth Punch | ON |
| `rs_dn_stretch` | Squash And Stretch | off |
| `rs_dn_shrink` | Shrink Out | ON |
| `rs_dn_significance` | Size By Significance | off |
| `rs_dn_sizejitter` | Size Variation | off |

### Colour -- each independent
| cvar | row | default |
|---|---|---|
| `rs_dn_colour` | Colour By Hit Type | off |
| `rs_dn_heat` | Heat (hot at wound, cools as it falls) | off |
| `rs_dn_heatseverity` | Bigger Hits Run Hotter Longer | off |
| `rs_dn_huejitter` | Hue Variation | off |
| `rs_dn_perhand` | Per-Hand Tint | off |

### Glow -- each independent
| cvar | row | default |
|---|---|---|
| `rs_dn_glow` | Glow Halo | ON |
| `rs_dn_glowheat` | Halo Follows Heat | off |
| `rs_dn_dynlight` | Dynamic Light On Big Hits | off |
| `rs_dn_dynlightmax` | Max Dynamic Lights | slider |

### Reactions -- each independent
| cvar | row | default |
|---|---|---|
| `rs_dn_weapontype` | React To Weapon Type | off |
| `rs_dn_proximity` | React To Distance From You | **ON** |
| `rs_dn_fontroll` | Random Typeface Per Number | off |
| `rs_dn_distance` | Distance Scaling | ON |

### Readout -- each independent
| cvar | row | default |
|---|---|---|
| `rs_dn_overkill` | Show Overkill | off |
| `rs_dn_accumulate` | Tidy Mode (merge hits) | off |

## Defaults are deliberate

ON by default is only: the number exists, it flies the way the shot
went, it arcs, it punches in, it shrinks out, it glows, it scales with
distance, and it calms down near your face. That is a complete, pleasant,
plain damage number and nothing more.

**Everything expressive is OFF and waits to be switched on one at a
time.** That is the owner's stated way of working with this -- turn one
on, play, decide. A default that arrives with twenty behaviours running
cannot be evaluated.

`rs_dn_proximity` is ON despite being a "reaction" because it is a VR
comfort requirement, not a flourish.

## Implementation note

Every one of these must be a genuine independent branch. The temptation
is to implement "crit behaviour" as one block that does burst AND shake
AND extra heat together, then have three cvars gate the same block --
which silently makes them one toggle wearing three names, and is exactly
what this ruling exists to prevent.

Read each cvar at its own decision point.

---

# Addendum 5 — named profiles, and the archetype future

**Owner, 2026-08-10: "we will eventually tie them to weapon archetypes,
or attack profiles, etc" and "create a few random profiles in a menu,
including 'none' for people who want to turn it off".**

These two are one instruction, and taking them separately is how this
gets built wrong.

## THE ARCHITECTURAL POINT, AND IT MUST LAND FIRST

A profile is **a named set of values that something can be evaluated
against**, not a button that writes a pile of globals.

The obvious build is: the menu picks a preset, the preset assigns
twenty-eight cvars, the number reads the cvars. That works today and it
makes the archetype tie-in a REWRITE, because there is only ever one
active set of values in the whole game and no way for a shotgun and a
railgun to disagree.

Build it instead as: **a profile is a data object. The emitter resolves
WHICH profile applies, then reads its fields.** Today the resolver always
answers "the one the player picked in the menu". Later it can answer "the
one this weapon's archetype specifies, falling back to the player's
choice" -- and that is a change to ONE function, not to the twenty-eight
read sites.

This mirrors how `RS_AttackProfile` already works in this tree: weapons
hold profiles and the dispatch reads them, rather than every weapon
setting global state. Same pattern, same reason.

The granular cvars from Addendum 4 do not go away. They populate the
CUSTOM profile. Every other profile is a preset object.

## The profiles

Selected by `rs_dn_profile`. Names are placeholders; the owner names
them.

### None
Off. Nothing spawns, nothing ticks, no cost. Present because a player who
does not want damage numbers should not have to find eight toggles.

### Plain
The number, the arc, the shrink. No colour coding, no heat, no shake.
For someone who wants the information and none of the theatre.

### Arcade
Punchy and readable. Birth punch exaggerated, colour by hit type on,
distance scaling on, bright halo. Short lives, fast clear. The default
recommendation.

### Molten
The heat idea taken all the way. Numbers leave the wound white-hot, cool
through yellow and orange as they arc, land as dull embers and lie on
the floor. Tumble and land-flat on, halo follows heat. Slower and heavier
than Arcade -- longer lifetimes so the cooling is actually visible.

### Brutal
Everything loud. Shake, burst launch, bounce, hue jitter, overkill shown,
dynamic light on big hits. Chaotic on purpose.

### Precision
The opposite. Snap on, momentum off, shake off, minimal motion. Numbers
appear where they landed and hold still. Significance sizing ON, because
this profile is for reading the fight rather than feeling it. Headshots
and crits distinguished by colour alone.

### Custom
Reads the granular cvars from Addendum 4. Touching any of them from any
other profile switches the selection to Custom rather than silently
diverging from the preset the menu still claims is active -- a menu that
lies about which preset is running is worse than no presets.

## Menu shape

```
Combat Options -> Damage Numbers
  Profile .................... Arcade      <- one row, most players stop here
  ---
  Customise (sets Profile to Custom)
    > Core
    > Motion
    > Scale
    > Colour
    > Glow
    > Reactions
    > Readout
```

One row for the many, everything reachable for the few.

## The archetype tie-in, when it comes

RS already knows a weapon's archetype (`GetPaletteArchetype`,
`RS_Catalog.ScaleForArchetype`) and already carries per-shot
`RS_AttackProfile` objects. So the eventual resolver is:

1. does this shot's attack profile name a damage-number profile? use it
2. else does this weapon's archetype have one? use it
3. else use the player's menu selection

Shotguns throwing a wide scatter of small fast numbers while a railgun
produces one enormous slow one is then authoring, not code.

**Nothing about that is being built now.** It is written down so that the
profile object exists from day one and step 3 is the only branch
implemented. Adding steps 1 and 2 later must not require touching the
number actor at all.

---

# Addendum 6 — a typeface per monster family (LATER, not now)

**Owner, 2026-08-10: "for later, i was hoping for 17 to cover each
monster type".**

Seventeen faces, one per CH monster family, so the numbers coming off a
Baron read differently from the numbers coming off a Zombieman.

## It is reachable, and without shipping anything broken

Eleven faces ship today. The font pass evaluated all 42 and rejected the
rest in two very different buckets, and only one of them is a wall:

**Genuinely unusable — stays rejected.** Artilux Dots (renders as
near-nothing, would have shipped INVISIBLE), Nexmod Outline
(structurally cannot reach opaque white at any size, so runtime tinting
breaks), NoiseBlock, Westerngames, Bitova, GlyphGalaxy, GothicByte,
Pixtile, Altrobyte, StartSignal, Script Screen, the Artilux Ink/Regular/
Text group, Cairopixel, akaArcade. These fail on digit confusion or on
rendering, and no assignment scheme makes that acceptable.

**Legible but cut for REDUNDANCY — recoverable.** Lazarus, Rasteron,
Pixeloid Sans, Pixeloid Sans Bold, MatrixType Display, MatrixType
Display Regular, MatrixType Regular, Steve, Steven, Nexmod. Ten faces,
all readable, dropped only because they overlapped a face already kept.

**11 + 6 of those = 17.** No compromise on legibility required.

## Why redundancy stops mattering here

A curated general-purpose set wants maximum spread, because the player
is choosing one face to look at all the time and near-twins waste a
slot.

A per-family assignment is the opposite problem. Nobody has to identify
the family FROM the typeface -- the monster is right there. The face is
flavour riding along with information the player already has, so two
similar faces on two different families costs nothing.

## Ordering note

Which face goes to which family is a taste call and belongs to the
owner, not to whoever implements it. Some pairings suggest themselves --
the heaviest block face on the Cyberdemon, the dot-matrix on the
Arachnotron, the thin technical one on the Lost Soul -- but that is a
suggestion, not a spec.

## Build cost

The generator is already parameterised: its `FACES` table carries a
per-face isoline, so adding six entries and re-running is a one-line
change each. Roughly 120 more files.

**Do not build this before the core system boots and is liked.** A
seventeen-face table is worthless if the numbers themselves are still
being reshaped.
