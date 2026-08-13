# Radiant Silvergun

A VR Doom II mod built around one idea: a small, fixed set of class weapons —
one per hand, dual-wielded and tracked independently — that you spec in an
effectively unlimited number of directions rather than swap out for a bigger
gun. The arsenal doesn't grow. What a given gun *is* does.

## What that means in practice

**Weapons.** Every gun is one of a handful of families (pistol, revolver,
rifle, SMG, shotgun, super shotgun, chaingun, the Lance beam weapon, fists),
each rated on a shared tier ladder from Cursed up through Prototype. Tier is
what unlocks affix sockets — a Basic weapon can't take a card at all — so
progression is about *raising* the six weapons you started with, not finding
new ones. What a weapon actually fires is assembled from an eight-axis kit
(projectile, casing, muzzle, smoke, sound, puff, sparks, trail) rather than
hardcoded per gun, which is the mechanism that lets one SMG end up nothing
like another SMG by the end of a run. A locked stat costs currency to lift
and blocks that weapon from advancing until you pay it off, so a cursed gun
isn't just weaker, it's stuck.

**Monsters.** Any eligible spawn can roll elite at a small chance, carrying
extra health with nothing visibly different yet. It reveals automatically at
half that health — full heal, a damage multiplier, and its AI stops
turreting and starts actually closing — which is the moment it becomes worth
fighting and worth fearing. An elite that dies before revealing pays out
nothing. Monster attacks are built from the same eight-axis kit the player
weapons use, catalogued across the full custom monster roster, so the vocabulary
under a revenant's rocket and a player's rocket launcher is the same one,
even though nothing about them looks alike on screen.

**The loop.** Kill things for small currency drops; kill a revealed elite for
a much larger payout and, if it was worth the fight, a rarity token — a real
object on the floor that shows you exactly what it would do to whichever gun
is in your hand before you commit to it. Spending a token raises that
weapon's tier and socket count, which is what lets it take another affix at
the next level-up. Level-ups offer a mix of flat stat cards and whatever your
current sockets can hold. Curses complicate the climb rather than gating it
outright — the game is deciding what's worth paying to fix, then getting
stronger.

## Lineage

Built on GZDoom's ZScript, with a custom monster set forked from **Colourful
Hell** and its **Painslayer** ("MeatGrinder") variant, a heavily reworked
fork of **GunBonsai** (TFLV) for the leveling and affix layer, and an
imported arsenal from the **GunstarHeroes** weapon/sprite pack — its assets
kept, its own loot/rarity/Condition systems replaced outright by RS_Weapon's.

## Requires

- A custom DoomVR client — this is not a mod you point stock GZDoom at.
- Recommended pairing: **UZDXREMA** (the project's own GZDoom fork, developed
  alongside the mod rather than as a separate dependency) plus
  **RadianceControlPanel**.

## Planned

A custom integration of **Champions X LDL** as the arcade backbone for a
forthcoming Smash TV–inspired map pack, plus the continuing UZDXREMA engine
work needed to support extended portals and local gravity manipulation.

## Current state

In its current form, without the maps and without that continuing engine
work, this is gameplay and not yet a game. The systems above are real,
playable, and — per the rest of this session — actively being corrected as
they're found wrong. What's missing is everything that turns a working
gameplay loop into levels someone can walk through.
