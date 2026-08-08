# Radiant Silvergun

A VR dual-wield roguelite for GZDoom.

Every number below was read out of the source, not out of a design doc.

---

## What this mod is

**Two guns, two hands, tracked independently.** Not a weapon with an
alt-fire — two complete weapons, each with its own ammunition, its own
reload, its own rolled statline, its own wear, and its own upgrades. The
left hand does not know what the right hand is doing. You aim them
separately because the engine gives each controller a real pose, and the
mod uses it: a shot leaves from where the gun actually is.

On top of that sits a roguelite. **Weapons are rolled, not picked up.**
Two Revolvers are not the same Revolver — they differ in damage,
accuracy, crit chance and mechanical condition, and one of them may be
cursed in a way you cannot see until you pay to find out.

**Nine playable classes.** Seven dual-wield identities built around a
weapon family, plus two full arsenal sets.

It runs on Doom and Doom II. Ten of the monster families draw sprites
that only exist in `doom2.wad`, so the repo ships a compatibility set —
they render correctly on Ultimate Doom instead of being invisible.

---

## The gameplay loop

```
kill monsters  →  Elites appear  →  reveal them  →  they drop a weapon card
      ↑                                                       ↓
      │                                          take it: your class weapon
      │                                                       ↓
      └──────  Promotion  ←  own all six  ←  higher tiers unlock  ←────┘
```

**Elites are the engine of progression.** A hidden elite reveals itself
at 50% health — kill it before that and it drops nothing, ever. Reveal
it and it offers a card.

**Six weapons per class.** Until you own all six, drops are capped at the
junk end of the ladder. Complete the set and the whole tier range opens
up.

**Then Promotion, which is the interesting part.** Take a maxed-out
Prototype and spend it on a Basic. Your stats are *cut*. In exchange the
ceiling on every future level-up rises, and the weapon gains a permanent
pellet. A one-pellet pistol that has been promoted three times will
outperform anything you found, and it will look worse on paper the whole
way.

The tier ladder is eight rungs: **Cursed, Trash, Basic, Common, Uncommon,
Advanced, Designer, Prototype.**

---

## What makes the monster system stand out

**1,494 monster actor classes across 17 families.** That is not one
monster with a difficulty multiplier — each family has a ladder of
15–19 distinct variants, and a variant is its own actor with its own
sprites, sounds, attacks and behaviour.

A tier-1 Archvile and a tier-13 Archvile are different monsters that
happen to share a silhouette.

**You can read the room.** Every variant carries a colour tier token and
flashes its icon on wake. Learn the colours and you know what you walked
into before it reaches you.

**Elites are a second axis, not a bigger number.** Seventeen elite
colours, each a distinct mechanic rather than a stat boost — one comes
back unless you destroy the corpse it leaves, one cannot be raised by
other monsters' resurrectors, one doubles its own damage on reveal.
Elite and tier compose: a tier-11 body with an elite colour is a
different fight from either alone.

**Hitscan is optional.** A converter turns monster bullets into visible,
dodgeable projectiles, on by default, with speed and visibility on
sliders. It changes what a room full of Chaingunners *is*.

**Reinforcements exist.** A director remembers where the map originally
put monsters and can send fresh squads back to those exact validated
spots — tier-banded, elite-aware, escalating over waves.

**1,266 sound lumps.** A monster is not its behaviour text; it is sprites
*and* sounds *and* SNDINFO entries *and* drops *and* icons. The whole
thing ships or it isn't imported.

---

## What makes the weapon system stand out

**Twelve stats per weapon, most of them rolled.** Damage, accuracy,
velocity, crit chance, crit multiplier, capacity, rate of fire, reload
speed, pellet count, upgrade sockets, condition and choke.

**Weapons wear out, and worn weapons get interesting.** Condition
degrades when you take damage. Above 80% nothing happens. Below that,
performance drops — and below 50%, the weapon starts *rolling well*
instead: more damage, more pellets, and a real chance of blowing up in
your hands. A dying gun is a gamble, not just a worse gun.

Repair is automatic. Every ten repair bits you pick up quietly fixes a
point on both weapons. There is no shop.

**Attack profiles.** A weapon is not one attack — each hand has slots
holding profiles that rotate as you fire, in seven modes (bullet,
hitscan, heavy, melee, radial, summon, self-buff). This is what makes a
weapon feel like a specific weapon rather than a damage number.

**409 catalogued monster projectiles are draftable.** Every projectile
in `zscript/monsters/**` is indexed and can be assembled into a player
weapon's attack profile. The thing that was shooting at you becomes the
thing you shoot.

**Two kinds of curse, from two different places.**

*Weapon curses* come from Promotion. They halve a stat, hide its real
value behind `???`, and stack. While cursed, the weapon refuses any
elite card above its current tier — curses gate your climb, they do not
cap it. Lifting one restores the stat to its true pre-curse value, pays
an escalating bonus, raises the weapon's ceiling by the same amount, and
tiers it up.

*Player curses* come from **death** — specifically, the moment a save
spends your last life. Eight flaws, scoped per hand, so
`mainhand-jam-prone` and `offhand-jam-prone` are separate problems. They
follow you across every weapon you pick up. A jamming hand, a hand that
eats double ammo, a hand that slows you down, bits that flee from you,
ears that ring after every shot.

Cure ten curses of either kind and you become **Divine**: no curse ever
takes hold again.

**A grappling hook, always available.** Hit a wall and you're pulled to
it; hit a monster and it's pulled to you. Every shot sweeps loose pickups
toward you — which is also, coincidentally, the answer to the curse that
pushes them away.

---

## How the systems build on each other

The point is that nothing is a silo. Almost every system is another
system's input.

**Kills fund everything.** A dead monster drops weighted bits: health,
armour, ammo, repair, gold, curse. Repair bits fix weapon condition.
Gold buys upgrade rerolls. Curse bits lift curses. One drop table feeds
three unrelated economies, and the weights are all sliders.

**Damage taken is a weapon stat.** Getting hit degrades both guns. Worn
guns roll wild. So a bad fight doesn't just cost health — it changes how
your weapons behave for the next one.

**Death is a currency exchange.** A banked life absorbs a lethal hit and
throws a cone of fire. Both weapons lose condition. Spend your *last*
one and you take a permanent curse. Which curse depends on **which gun
you fired last**.

**Elites are the loot table, the difficulty curve, and the pacing.** They
gate weapon drops, they can trigger reinforcements, and their reveal
mechanic means the decision to engage one is a real decision.

**Promotion feeds curses feeds Divine.** Promoting rolls curse chances,
and the count escalates with each promotion. Curses need curse bits.
Curse bits come from kills. Cures accumulate toward Divine, which shuts
the whole cycle off permanently. The endgame is a loop that consumes
itself.

**In-world UI instead of menus.** Drop cards, weapon sheets and the
level-up picker render as oriented panels in the world — you walk up to
a card, point at a row with a controller, and take it. The hand you
point with is the hand that receives the weapon. There is no rule to
memorise, because the gesture *is* the rule.

Under that sit three interchangeable rendering backends — an actor-based
flat quad, a single engine billboard, or a panel composed from primitive
payloads that costs no texture at all. Anchored screens use one,
view-locked screens use another, and callers don't know the difference.

---

## Status

Actively built. Systems described above are implemented in source; the
project is pre-release and unproven in play. Documentation in `docs/` is
historical and is not authoritative — the code is.
