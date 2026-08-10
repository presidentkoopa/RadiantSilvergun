# Engine asks — hit-location scoring

Brief for the native side of the fork (`E:\UZDXREMA`). Written 2026-08-09.

Consumer is `zscript/systems/weapon/RS_Headshot.zs`, which **works today
without either of these**. Neither is a blocker. Ask 2 is small and worth
doing; ask 1 turned out to be much bigger than it first looked, and the
reason why is written down here so nobody re-derives it.

Every line number below was read on disk before this file was written,
not recalled. Verify anyway — that is this project's whole rule.

---

## Ask 2 first, because it is the one worth doing

### `TexMan.CheckRealBounds` — the mirror of a function that already exists

**What the mod needs.** Where the drawn content of a sprite actually
sits inside its canvas: top, bottom, left and right. Today it can only
learn the bottom.

**Why.** `RS_Headshot` measures a monster's head off the sprite being
drawn this frame, rather than off the collision box. That is the whole
design — it is what makes the system work on every monster with no
per-class table. But it can only ask for one of the four edges, so the
head box is currently derived proportionally (`headfrac` of the drawn
height, `HEAD_WIDTH_FRAC` of the full canvas width). Proportional is
good enough to ship and is already far better than a collision box. It
is not exact, and it cannot be until the other three edges are readable.

**Second thing it unlocks, which is bigger than the head box.** With the
real bounds you can tell that a shot passed through *empty canvas* —
the gap under a Revenant's raised arm, the space between a Mancubus's
legs. Every hitscan in this engine currently connects with that empty
space, because the hit test is a box. This is the cheap 80% of
pixel-accurate hit detection.

**The existing function to mirror.** `FTexture::CheckRealHeight()`,
`src/common/textures/texture.cpp:98`:

```cpp
int FTexture::CheckRealHeight()
{
    auto pixels = Get8BitPixels(false);

    for(int h = GetHeight()-1; h>= 0; h--)
    {
        for(int w = 0; w < GetWidth(); w++)
        {
            if (pixels[h + w * GetHeight()] != 0)
            {
                return h;
            }
        }
    }
    return 0;
}
```

Two things in there that a mirror has to keep:

- **The pixel buffer is column-major.** `pixels[h + w * GetHeight()]`.
  Indexing it row-major will appear to work on square sprites and be
  wrong on every other one.
- **Index 0 is the transparency key** in the 8-bit representation, which
  is what `!= 0` is testing.

**The four files to touch**, all verified present:

| file | line | what is there now |
|---|---|---|
| `src/common/textures/texture.cpp` | 98 | the pixel loop |
| `src/common/textures/textures.h` | 313 | `int CheckRealHeight();` |
| `src/common/textures/gametexture.h` | 273 | scale-aware wrapper — `xs_RoundToInt(Base->CheckRealHeight() / ScaleY)` |
| `src/common/scripting/interface/vmnatives.cpp` | 552–563 | the VM export |
| `wadsrc/static/zscript/engine/base.zs` | 322 | `native static int CheckRealHeight(TextureID tex);` |

**Suggested shape.** One pass, four edges, so the pixels are walked once
rather than four times:

```
native static void, int, int, int, int CheckRealBounds(TextureID tex);
                    // left, top, right, bottom  (inclusive, texel space)
```

Note `gametexture.h:273` divides by `ScaleY` — the width edges need the
matching `ScaleX` treatment, not a copy-paste of the Y one.

**Caching.** `CheckRealHeight` recomputes on every call and decodes the
texture to do it. RS_Headshot calls this once per damage event, which is
rare, so it is fine either way — but if it is ever called per frame the
result wants caching on the texture. Worth a one-line note in the
implementation rather than a surprise later.

**Verification that it works, not that it compiles.** Point it at a
sprite with known empty margins and check the numbers against the PNG in
an image editor. A bounds function that returns the full canvas for
everything passes every automated check and is completely useless.

---

## Ask 1 — bigger than advertised. Read before starting.

### Letting a mod change damage as it is dealt

**What was originally proposed, and why it is wrong.**

The proposal was: `WorldEvent` already carries a non-readonly
`NewDamage` field (`src/events.h:400`) and it is already honoured — but
only on the sector and line damage paths (`src/events.cpp:2030` and
`:2053`). So "just wire the thing-damaged path to honour it too."

**That does not work, and the engine says so in its own comment.**
`DoDamageMobj`, `src/playsim/p_interaction.cpp:1602`:

```cpp
static int DoDamageMobj(AActor *target, ...)
{
    bool needevent = true;
    int realdamage = DamageMobj(target, inflictor, source, damage, mod, flags, angle, needevent);
    if (realdamage >= 0)
        ReactToDamage(target, inflictor, source, realdamage, mod, flags, damage);

    if (realdamage > 0 && needevent)
    {
        // [ZZ] event handlers only need the resultant damage (they can't do anything about it anyway)
        target->Level->localEventManager->WorldThingDamaged(...realdamage...);
    }
    return max(0, realdamage);
}
```

The event fires **after** `DamageMobj` has already run and subtracted the
health. `realdamage` is the *result*, not a proposal. The other call site
(`:1594`) is later still — it is inside the death branch, after
`CallDie`. Returning a modified number from either would change nothing;
the monster is already hurt, or already dead.

So this is not "switch on an existing field". It is **a new event that
fires before damage is applied**, which means:

- a new hook inside `DamageMobj` itself, ahead of the health write
- a new event type, its `WorldEvent` fields, its VM plumbing, and its
  registration
- deciding chaining semantics for several handlers modifying one number
- and a real compatibility question, because a pre-damage hook that can
  veto or rewrite damage is reachable by every mod, not just this one

**What it would buy.** Right now the only in-engine hook that can alter
incoming damage on an arbitrary actor is `ModifyDamage` on an Inventory
item the victim is already carrying. That is why every mod of this kind
attaches an item to every monster on spawn — and those items tick. A
pre-damage event would delete that pattern from every such system at
once, not just this one.

**What RS_Headshot does instead, today.** Deals the bonus as a second
`DamageMobj` call under damage type `'RS_Headshot'`, which doubles as the
recursion guard. Zero per-monster state, no items, no ticks. The one
visible consequence: the original hit's pain chance rolls against the
base figure rather than the boosted one.

`ApplyBonus()` in `RS_Headshot.zs` is written so that if a pre-damage
hook ever lands, it collapses to a single assignment and the second
`DamageMobj` goes away. One function changes.

**Recommendation: do not do ask 1 for this feature.** The mod-side
workaround is cheap and the behaviour is nearly identical. If a
pre-damage event gets built it should be because several systems want
it, designed on its own terms — not bolted on for headshots.

---

## Not asked for, noted for later

True pixel-accurate hit resolution — returning the sprite `(u,v)` the
trace crossed, so the hit resolves against the drawn texel rather than a
box. That is the full version of what ask 2 approximates.

Worth knowing how far the current hit test is from it. The actor branch
of the trace, `src/playsim/p_trace.cpp:695`:

```cpp
if (fabs(hit.X - in->d.thing->X()) > in->d.thing->radius ||
    fabs(hit.Y - in->d.thing->Y()) > in->d.thing->radius) return true;
```

That is an **axis-aligned square**, not even a cylinder. And
`FLineTraceData` (`wadsrc/static/zscript/actors/actor.zs:36`) exposes
`HitActor`, `HitLocation`, `HitDir`, `Distance` — a world point on a box.
There is no bone API, no submesh API, and no sprite-space anything in the
tree, so models are a separate and larger job again.

Ask 2 gets most of the benefit for a fraction of the work. Start there.
