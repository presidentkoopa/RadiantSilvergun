# Radiant Silvergun

A dual-wield VR overhaul for Doom, built on a GZDoom/QuestZDoom fork. Every gun is a persistent, individually-rolled object with its own rarity, its own leveling arc, and its own place in a bigger loop — not a fixed pickup you find and forget.

## What it is

Radiant Silvergun turns Doom into a two-handed, loot-driven VR shooter. Pick a class — Pistol, Revolver, Rifle, SMG, Shotgun, Super Shotgun, or Chaingun — and you specialize in that weapon on both hands independently. Alongside the class system sit whole imported arsenals (Vanilla+, MeatGrinder, and a third set in progress) for players who want the full spread instead of one specialty. The monster roster is a from-scratch import of a classic community pack, rebuilt with an elite/tier system layered on top, and every piece of UI — comparison cards, loot pedestals, purchase menus — exists as a physical object in the 3D world you point at and interact with, not a 2D screen bolted over the game.

## The loop

Every class weapon exists as six independently-tracked copies: three for your main hand, three for your off hand, each with its own rolled stats, its own condition, its own level. You start with one of each. The rest you find — and here's the part that took real engineering to get right: **every weapon pickup on every map, vanilla Doom's own included, transparently becomes a copy of your own class weapon instead.** Walk up to what would have been a stock shotgun and you get another copy of *your* gun. Elites drop the same thing, gated to whether you're actually playing a class that can use it.

Once you've collected all six, the game doesn't stop rewarding you — it starts offering **Imprints**: rolled stat packages you apply directly to a weapon you already own, letting a well-worn favorite keep growing instead of getting benched by something shinier. The choice between finding a whole new weapon and improving the one in your hand is presented as an honest, side-by-side comparison, not a blind swap.

## Weapon rarity, top to bottom

Every weapon rolls its stats — damage, accuracy, velocity, crit, capacity, condition — inside a range set by its rarity tier, so no two copies of the same gun are quite the same. Climb high enough and a weapon can **Promote**: reset to the bottom of the ladder, lose its earned upgrades, and come back leaner but with stronger rewards waiting on the other side. It's a real choice, not a punishment — cash in a built weapon for the next cycle, or keep riding the one you have.

## Novel monster work

The monster roster isn't a reskin — it's a complete import: sprites, sounds, drop tables, palette translations, the works, verified lump-by-lump rather than assumed correct because it compiled. On top of that sits an elite system that hides its hand: an elite monster looks and fights like a normal one until it crosses 50% health, at which point it reveals itself — a full power-up, a warning, and real loot on the line if you can finish the fight. Compatibility work went deep enough to patch monsters that would otherwise render as invisible on certain IWADs, sourced honestly from the player's own legally-owned game data rather than smuggled in from anywhere else.

## Novel weapon work

Beyond the rarity loop, every weapon can level up through combat and earn **affixes** — real changes to how the gun behaves, not just bigger numbers. An affix can swap a projectile's entire identity, add homing, collapse a shotgun's spread into one heavy slug, or stack with other affixes into combinations nobody explicitly designed but that fall naturally out of the system. A handful of stat-only picks and a much smaller set of genuine identity-changers keep the game honest about which is which.

## How it's built

Almost everything above runs in pure ZScript — no engine changes required for most of it. The in-world UI is the clearest example: physical, pointable panels exist by repurposing an existing engine render flag and a settable texture handle, a trick that needed zero native code to work. Where ZScript genuinely can't reach — true billboard rendering, custom shader-driven UI elements — the project maintains its own engine fork, built incrementally and conservatively, with every native addition treated as a capability the mod layer decides how to use, never a design decision baked into the engine itself.

The project runs on a simple, hard-earned rule: nothing is trusted until it's checked. Not a comment, not a doc, not a "it compiled so it must be right." Every claim about what the game actually does gets verified against the source, the compiler, or the running game itself — because this codebase has a real history of confidently-wrong assumptions costing real time, and of catching them by refusing to take anything on faith.
