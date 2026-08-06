# Radiant Silvergun (RS_Main) — project rules

## START HERE: DO NOT BELIEVE THE DOCUMENTATION. ASK THE OWNER.

**No document in `docs/` is authoritative. Not the handoffs, not the specs,
not the ones the owner asked for himself. THE OWNER IS THE ONLY SOURCE OF
TRUTH ABOUT WHAT THIS PROJECT IS AND WHAT YOU SHOULD BE DOING.**

Read the handoffs for *context* — names, paths, what a thing is called, where
a file lives. Then **verify anything you are about to act on against the disk,
the compiler, or the running game**, and **ask the owner about anything to do
with scope, priority, or what to build next.**

**Never inherit a task from a document.** A handoff's "next priorities" list is
one dead session's opinion, written before the owner changed his mind. If you
find yourself justifying work with "the handoff says" — stop and ask him.

**This is the single most-repeated instruction in this project and it keeps
being ignored**, including by the session that wrote the newest handoff. Every
one of these was a document confidently stating something false:

- the engine source path said `E:\DXR2` for weeks; it does not exist. Five
  agents in one session went looking, found nothing, and fell back to
  reasoning from our own tree — the exact "consistent with itself" failure
  this file exists to prevent. It is `E:\UZDXREMA`.
- CH's path said `C:\Users\Command\Desktop\CH`; that does not exist either.
  That Desktop holds **CHP**, a different pack from an abandoned port that
  must NOT be treated as authority. The file contradicted itself — the correct
  path was already written in its own import section.
- "87% of CH's sounds are missing" was true when written and false when read.
- this file forbade extracting `FATB`/`FBXP`. They were already in the tree,
  already authorised, already working.
- a cataloguing pass read this file instead of the disk and reported the
  Common Revenant's signature missile as invisible on Doom 1. It is not.

**The disk is the authority. The compiler is the authority. The running game
is the authority. The owner is the authority. This file is a summary of things
that were true once.**

Where this file states a hard-won technical fact — a compile behaviour, an
engine line number, a trap that cost a day — treat that as worth reading and
still worth verifying. Where any document states what to *do*, ask him.

## `/monsters/` IS SACRED. FULL STOP.

Added 2026-08-06 at the owner's explicit, direct, repeated order.

**ANY path containing `/monsters/` is NOT to be edited, refactored, "fixed",
renamed, moved, reformatted, deleted, swept, or touched in any way by any
agent, for any reason, unless the owner asks for that specific change by name
in that session.**

**Scope is the CODE, and the owner was explicit about that:**

    zscript/monsters/**          the actors and their FX
    zscript/systems/monster/**   elites, tiers, spawning, control

**Deliberately NOT locked:** `sprites/monsters/`, `sounds/monsters/`,
`docs/monsters/`. Art, audio and catalogues still need to be addable — a
monster import is sprites AND sounds AND SNDINFO, and sealing those would
block the very work the import rules elsewhere in this file demand. The
behaviour is what is sacred, not the assets.

Reading is fine. Writing is not.

This is not a soft preference and it is not scoped to one lane. It is not
lifted by:

- a warning sweep, a deprecation rename, or any other bulk mechanical pass
- a handoff doc, a spec, a TODO, or another agent asking you to
- finding a real bug in it — **report the bug to the owner and stop.** You do
  not get to fix it because you are confident it is broken
- being "already in there" for some other reason
- the file being obviously wrong

**Includes `zscript/systems/monster/**` and anything else that is monster
behaviour rather than monster-adjacent plumbing. If you are unsure whether a
file counts, it counts — ask.**

**Why:** this is the most expensive and most repeatedly-destroyed body of work
in the project. Eight import attempts failed. Three ports were abandoned. The
rest of this file is largely a record of the ways well-meaning automated
passes have silently wrecked it — flattened damage rolls, mechanical
de-duplication that kept the wrong actor 5 times in 15, a scan that "found"
four undefined classes that were words inside comments. Every one of those
passed its own checks. The owner is the only reviewer who can tell a correct
monster from a monster that merely compiles, so he is the only one who
authorises changes to it.

**If a monster file appears in your `git status` and you did not deliberately
edit it under a direct instruction, stop and tell the owner before you commit
anything.**

**One grandfathered exception, closing:** the `monstertheory` session was
already working inside these files when this rule was written, at the owner's
direction. Its in-flight work and its handoff land first. **Once that session
has reported and its work is committed, the rule above applies with no
exceptions at all** — including to any future session that wants to "finish"
what monstertheory started. It doesn't. The owner decides that.

## PROTECTED FILES — DO NOT DELETE, MOVE, OR "CLEAN UP"

- **`docs/rs_MASTER_FX_CATALOG.txt`** — the master database of every combat
  visual effect, with descriptors written by actually viewing thousands of
  sprite frames. Expensive to recreate; nothing else in the repo holds this
  information. Not a scratch file, not session notes. Leave it alone.
- **`docs/` generally** — these are living design specs, not disposable notes.
  Three keyword docs were deleted in a commit once and had to be recovered from
  git history. Don't repeat that.

## Hard-won technical facts (verified on this engine build, not theory)

- **`static const TYPE name[] = { ... }` array literals do not reliably resolve
  here.** Found and fixed three separate times in unrelated files. Symptom is a
  confusing "Unknown identifier" pointing at something that obviously exists.
  Rewrite as a `switch` or a plain `||` comparison chain.
- **A new `.zs`/`.zsc` file that isn't in `zscript.txt`'s include list silently
  does not exist.** No error, no warning — the classes just aren't there. This
  has been forgotten twice. Always add the include.
- **`extend class PlayerPawn` fails** ("cannot be found in current translation
  unit"). Extend the project's own `VR_DualClassBase` instead.
- **`GetClassName()` returns a `Name`, not a `String`** — pairing it with a
  string literal in a ternary is a type error. Concatenate `..""` first.
- Destructive shell commands (`rm -rf`, `Remove-Item -Recurse -Force`) are
  blocked by a permission layer regardless of user consent. Single-file `rm`,
  `mv`, and `rmdir` on already-empty dirs work.
- **ALWAYS `grep -i` against CH/CHP decorate, and against ZScript class
  names.** Two separate traps, same root cause:
  1. CH and CHP mix `Actor` and `ACTOR` freely. A search for `^ACTOR Foo`
     returns nothing for a file that opens `Actor Foo`, and you conclude the
     actor doesn't exist. This produced four confident false negatives in one
     session — including "VBtrail is defined nowhere", when it is sitting at
     `CH/decorate/Archviles.txt:4518`.
  2. **ZScript itself is case-insensitive.** `RS_FireHand1` and
     `RS_Firehand1` are the SAME class, and defining both is a fatal
     redefinition that stops the mod compiling. A case-sensitive grep says
     they're two different classes. The COMPILER catches this — it is a hard
     error naming both sites, and it is what caught a base-class field
     colliding with two subclasses' on 2026-08-04. Build; don't script it.
     The same applies to a subclass field shadowing a base field: ZScript has
     no shadowing, so that is a redefinition too.
- **A passing check is not a correct result — know what it actually proves.**
  A duplicate-name check proves no name is defined twice. It does NOT prove the
  surviving copy is the right actor. A mechanical de-duplication that keeps
  whichever definition comes first in load order got 5 of 15 wrong here, and
  every one of those five passed every check in the repo. The sharpest was
  `RS_ZAPFFAT2`, whose surviving copy had `A_Explode` on a *looping* state —
  unbounded damage, forever, silently. When two definitions collide, open
  both and diff them against CH/CHP; don't let position decide.
  This is the general disease, not an anecdote: **a green check here has
  repeatedly meant "consistent with itself", never "correct".**
- **Correct a body in place; don't move a definition between files.** When a
  class is wrong, edit it where it lives. Relocating it to a "better" file
  produces a diff no human can read and makes every later merge harder to
  reason about — which matters because several sessions work this repo at
  once. Two separate lanes independently reached this conclusion after
  merging the same fix done both ways.
- **Never flatten a damage roll to a constant.** `Damage (random(40,125))`
  becoming `Damage 60` is not a simplification, it is data loss that hides
  itself: there is no `random(` left for any later sweep to find, so no tool
  and no reader can tell a spread was ever there. `RS_DIBigOne` sat flattened
  through three lanes reading the same file. Rolls belong in
  `DamageFunction (random(a,b))` — a ZScript `Default` block does NOT require
  a constant `Damage`, despite comments in this repo that once claimed so.
  If a roll ever must be flattened, record the original on the same line
  (`// CH: random(40,125)`) in the same commit. Cheap now, impossible later.
- **`Damage (random(a,b))` in a `Default` block does not compile** — that is the
  `damage: non-constant parameter` error. `Damage` takes a constant; a roll goes
  through **`DamageFunction (random(a,b))`**, which compiles and keeps the
  spread. Two file headers used to assert ZScript "requires" a constant, and an
  early pass flattened CH's rolls to single numbers on the strength of that. It
  was wrong, and it cost this a second rediscovery. Never flatten a roll to make
  it build.
- **The compiler reports one instance of a whole-tree defect and stops.** The
  same `damage:` error was reported as two lines; it was 63 across 12 files.
  When an error is a *class* of defect, grep the whole tree before believing a
  count.
- **Don't line-anchor a search over this codebase.** Most of monsterfx is inline
  `States { Spawn: ...; Death: ...; }` on one line, so `^\s*THING` silently
  matches almost nothing. Also strip `//` lines before any bulk pass, or it
  reads prose as code — a scan that skipped this "found" four undefined classes
  that were words inside comments, and a second one invented a defect by
  matching `Death.T08` inside `XDeath.T08`. **This bites hardest right after
  you fix something**, because the fix leaves a `// CH: <OLDTHING>` comment
  behind: a follow-up count then reports the defect still present when it is
  gone. Strip comments before every count, including the one that verifies
  your own work.

### DECORATE-isms that are NOT ZScript (all four cost a failed boot, 2026-08-06)

The CH import transcribed these faithfully from DECORATE and they are all
compile errors here. 254 of them in one build. If another pack is ever
imported, sweep for these FIRST rather than discovering them at load:

- **`Game "Doom";` does not exist in ZScript.** DECORATE-only property. 234
  instances. Just delete the line; it filters nothing here.
- **`DontHurtShooter` IS REAL — but it is a PROPERTY, not a flag.** The engine
  declares it at `wadsrc/static/zscript/actors/actor.zs:310`
  (`Property DontHurtShooter: DontHurtShooter`). So `+DONTHURTSHOOTER` and a
  bare `DontHurtShooter;` both fail; it needs a value: `DontHurtShooter true;`.
  **Do not "fix" it by deleting it** — that silently un-protects 13 bouncing
  projectiles that are meant not to hurt the firer.
- **NON-UNIFORM SCALE IS IMPOSSIBLE IN A `Default` BLOCK.** The engine's
  `DEFINE_PROPERTY(scale, F, Actor)` takes ONE float and assigns X and Y
  together, and there is no `Scale.X` / `Scale.Y` Default property at all. A
  stretched actor must set `Scale = (x, y);` in `BeginPlay`. Flattening it to a
  uniform value to make it compile is silent data loss.
- **`SpawnID` is not a ZScript Default property.** Delete it.

- **The engine source is the authority on flags and properties, and it is on
  this machine.** `E:\UZDXREMA` — `src/scripting/thingdef_properties.cpp` holds
  the real deprecation mapping and `wadsrc/static/zscript/actors/actor.zs` holds
  the property list. **This paragraph said `E:\DXR2` until 2026-08-06; that path
  does not exist.** Five agents in one session went looking, found nothing, and
  each fell back to reasoning from our own tree — the exact "consistent with
  itself" failure the rest of this file exists to prevent. Both files were
  verified present at the corrected path before this edit. Reading it settled four questions in one session that guessing
  would have got wrong. Deprecated flags are RENAMES, not removals:
  `+DONTHURTSPECIES` → `+DONTHARMCLASS`, `+LOWGRAVITY` → `Gravity 0.125`,
  `+SHORTMISSILERANGE` → `MaxTargetRange 896`, `+DOOMBOUNCE`/`+HEXENBOUNCE` →
  `BounceType`, and `+EXPLODEONDEATH` is a **dummy flag that does nothing** so
  it can just go.

- **CORRECTED 2026-08-06 — `MISSILEMORE` / `MISSILEEVENMORE` /
  `SHORTMISSILERANGE` **CAN** BE FIXED. This file said the opposite for weeks
  and was wrong.**

  It claimed they "set native fields with no `Property` binding", that "~256
  warnings in this tree are that, permanently", and instructed every session:
  "Don't try." **All false.** The real mapping, every part verified in-tree
  before this edit:

      +MISSILEMORE        →  MissileChanceMult 0.5
      +MISSILEEVENMORE    →  MissileChanceMult 0.125
      both together       →  MissileChanceMult 0.0625
      +SHORTMISSILERANGE  →  MaxTargetRange 896

  Evidence: `actor.zs:352` declares `property MissileChanceMult:
  MissileChanceMult;`, `actor.zs:344` declares `property MaxTargetRange:
  MaxTargetRange;`, **`archvile.zs:18` already uses `MaxTargetRange 896`**, and
  the engine sets its own deprecation string at `thingdef_data.cpp:930` to
  literally *"Use missilechancemult property instead."* The engine has been
  telling us the answer in every one of those 256 warnings.

  **This paragraph also contradicted itself four lines up**, which is how it
  should have been caught: line 220 lists `+SHORTMISSILERANGE` → `MaxTargetRange
  896` as a working rename while the old text called the same flag unfixable.
  Both statements sat in the same bullet for weeks and nobody read them
  together.

  **Why this one is the worst entry this file has ever carried:** it is not a
  stale path or an out-of-date count — those merely mislead. This actively
  ORDERED every future session not to look, inside the very section warning
  about "consistent with itself" failures. A document that forbids checking is
  worse than one that is merely wrong.

  ⚠️ **Most of those 256 sites are under `zscript/monsters/**`, which is
  SACRED.** Knowing the fix does NOT authorise a sweep. That rule is at the top
  of this file and it is not lifted by having a correct mapping.

## THE REPO'S OWN CHECKING TOOLS ARE GONE. READ THIS BEFORE WRITING ANOTHER.

`verify.py`, `verify_all.py`, `dedupe_check.py`, `crosscheck.py` and
`build_art_index.py` were **deleted by the owner on 2026-08-04**, after the
third failed port, and they are not to be reinstated in the same shape.

**Why: every one of them compared this tree against itself.** A lint that reads
our code, or a table someone typed by hand, can only report that our code agrees
with itself — which is a property all three broken ports also had. That is not a
gap in those scripts, it is what they were.

Their measured record:
- `verify.py`'s sprite check was `^`-anchored and reported OK on files it never
  opened. Its label check read raw source including comments. Both were found
  *after* they had signed off on work.
- `dedupe_check.py` proved no class name was defined twice. The compiler proves
  the same thing, fatally, in one second — it is what caught `rsEnraged`.
- `art_index.json` is a catalogue of art that *could be copied in* from
  `E:\New folder\ART SOURCE` — not what the mod ships and not the IWAD. Three
  lanes read a not-found from it and started replacing real sprites (`SHOT`,
  `GRND`, `HMIS` are all genuine). A token resolving *only* through art_index is
  a file that was never copied in: it passes a lint and still fails at load.

**THE GROUND TRUTH IS `E:\New folder\ART SOURCE\CH\` AND THE GAME.** That is the
pack this project's monsters were rebuilt from, and the only source any decision
about them may cite.

  **This paragraph said `C:\Users\Command\Desktop\CH` until 2026-08-06. That
  path does not exist** — that Desktop holds **CHP**, a different pack from an
  earlier abandoned port, and CHP is precisely what must NOT be read as
  authority. Six agents hit the dead path in one session; each found CH on its
  own at the corrected path, which is the one this file's own "IMPORTING A
  MONSTER" section names. The file contradicted itself and only one of the two
  resolved. Verified on disk before this edit. If a tool is written again it must be a **differ against
CH**, not a lint over us — it must be able to say "CH's actor does X, ours does
Y" and cite both. Anything that can only inspect our own tree tells you nothing
you did not already believe.

**DO NOT CONSULT ANYTHING ELSE IN `ART SOURCE` FOR WHAT OUR CODE SHOULD SAY.**
This paragraph used to name a different, much larger pack as authoritative,
left over from earlier abandoned ports. **This project does not contain that
pack and never has.** On 2026-08-06 that instruction sent several agents to read
it as a source of truth; the owner caught it. Removed at his order. If you find
yourself about to justify an edit with any source other than CH or the running
game — stop and ask the owner.

Between the compiler, a boot, and CH's own files, everything those five scripts
claimed to cover is covered by something that cannot flatter us.

## One repo, one branch — consolidated 2026-08-05

**`main` is the only branch and `E:\RS_Main` is the only worktree.** The owner
consolidated on 2026-08-05: everything merged to `main`, pushed, and the lane
branches and their worktrees deleted. Work directly on `main`. Do not create a
branch or a worktree unless the owner asks for one.

Rules that outlived the multi-lane setup, because they cost real time:

- **Never `git add -A`.** A lane once swept another's in-flight edits into its
  own commits, so `git log` blamed it for files it never wrote. Stage explicit
  paths. Still right with one lane — it keeps a commit's message honest about
  what is in it.
- **Merge, don't rebase, once something is pushed.** Rebasing rewrites
  published history. Rebase is right only while unpushed.
- **Breakage is found by building, not by a script.** `crosscheck.py` used to
  claim it projected every lane onto `main` and reported union-only breakage.
  It went with the rest of the tooling on 2026-08-04. Duplicate class names, a
  class one change deletes that another calls, and a file missing from
  `zscript.txt` are all things the compiler reports at once, by name, with the
  line — and unlike the script, it cannot be wrong about them.

**If the owner ever runs two sessions at once again, use worktrees — do not
share `E:\RS_Main`.** That failure mode is recorded above because it happened.

## Design rules that keep getting re-derived — don't re-litigate

- **Never duplicate a design space another mechanic already owns as its reward.**
  Promotion owns permanent pellet-count growth. An affix may *redistribute*
  along that axis (more pellets, proportionally less damage each — a real wash)
  but must never *grow* it for free. Where an effect can't avoid that on some
  weapons, the fix is an eligibility gate, not a price adjustment.
- **`null` is a crash-safety net, not a design choice.** A profile that leans on
  every default at once is hollow, not "valid." See
  `docs/rs_05_bullet_attack_pack.txt`.
- **Verify before categorizing files.** Sprite filenames here are cryptic and
  actively misleading — 40 sprites were once assumed to be revolver muzzle
  flashes from the name prefix alone and were unrelated voxel-pack content.
  Look at the file; don't pattern-match the name.

## IMPORTING A MONSTER MEANS THE WHOLE MONSTER, NOT THE ACTOR TEXT

Added 2026-08-05, after the owner had to ask for it out loud.

A monster is not its DECORATE block. It is the actor **plus its sprites,
its sounds, its SNDINFO entries, its translations, its drop items, and its
icons**. Eight import attempts transcribed the actor text and stopped, and
every one of them shipped monsters that were partly missing.

The sound case is the sharpest, and it is why this rule exists:
**87% of CH's sound library had never been imported.** 693 of 785 lumps
absent, 804 SNDINFO definitions absent. Every pass copied CH's sound
*strings* onto the actors correctly — `SeeSound "gen/see"` — and nobody
ever copied the sounds.

**THAT GAP IS NOW CLOSED: 785 of 785 CH lumps are present**, verified
file-by-file against CH's own `sounds/` on 2026-08-06 (693 in `sounds/ch/`,
92 re-homed into `sounds/monsters/`, 0 absent). The history above stays
because the FAILURE MODE has not gone anywhere — it is why the rule exists,
not a live defect. What that same audit did find, and what proves the point
better than the old number: **all 52 sound names of the Streak weapon set
have never played.** 48 SNDINFO lines read `rs_st_weapon/FOO.ogg` where the
other 270 path-form lines in the file read `Sounds/...`. The files are all
on disk. One missing word per line, inaudible, no error, no log line.

It survived eight passes because **an unresolved sound name is completely
inert.** No error, no warning, no log line. The compiler passes, the game
runs, the monster is just silent. There is no check that can fail. The
only detector is a human who already knows what the monster should sound
like, listening for a noise that never comes.

So, before any family is called imported, each of these gets a count with
a denominator:

  * sprites   -- every prefix the actor names, present in `sprites/`
  * sounds    -- every sound name resolves to a real lump, END TO END.
                 `$random Foo { A B }` is only as good as A and B; follow
                 the chain to the lump. A missing lump is silent, not an
                 error.
  * SNDINFO   -- CH's own entries, INCLUDING the `$` directives.
                 `$random`/`$alias` DEFINE names. A first pass here
                 filtered out every line starting with `$` and dropped 88
                 definitions while believing it was done.
  * drops     -- CH's DropItem lines. Where the pickup class does not
                 exist here yet, itemise it with its CH line so it is
                 restorable; do not silently ship a gutted table.
  * TRNSLATE  -- the palette remap, where CH sets one
  * icons/fx  -- the tier icons and death effects are CH content too

Source of truth for all of it: `E:\New folder\ART SOURCE\CH\` — its
`sounds/`, `sprites/`, `SNDINFO.txt`, `TRNSLATE.txt` and `DECORATE.txt`,
not just `decorate/*.txt`.

## THE DOOM 1 COMPAT SET — A ONE-TIME, OWNER-AUTHORISED IWAD EXTRACTION

Added 2026-08-06. **Do not revert this, and do not read it as licence to
extract anything else.**

Standing rule, unchanged: RS never ships art lifted out of a commercial IWAD.
Monsters must stand alone — every sprite resolves from the repo's own
`sprites/` tree or from the IWAD *the player already owns and is running*
(see "Monsters must stand alone"). That is still the rule for everything.

**The one exception the owner granted, out loud, on 2026-08-06.** Ten of the
seventeen CH families draw vanilla sprite prefixes that exist only in
`doom2.wad`. On `doom.wad` (Ultimate Doom) those monsters spawn, move and
kill you while rendering **nothing** — a silent, total invisibility with no
error and no log line. The owner **asserted legal ownership of the game** and
directed a one-time extraction from his own copy at
`D:\SteamLibrary\steamapps\Common\DooM VR\___Sourceport\doom2.wad`.

What was taken, and only this:

  * **317 lumps, four prefixes — `CPOS`, `PAIN`, `FATT`, `VILE`** — copied
    byte-for-byte out of the `S_START`/`S_END` range into
    **`sprites/rs_doom1compat/`** as raw Doom patches with a `.lmp`
    extension. No PNG conversion: the offsets live in the patch header, and
    re-encoding risks palette and offset damage. Verified byte-identical to
    the IWAD after writing, 317/317.

**`BOS2`, `SKEL` and `BSPI` were deliberately NOT extracted, and must not
be.** The repo already ships all 181 of those lumps — CH's own `doom1fix`
set, already imported, and verified byte-identical to `doom2.wad`. Adding
them again would create duplicate lump names, where one copy silently wins
by directory order. `BOS2` also carries 24 CH-authored frames (`P`/`Q`/`R`)
that are **not** in any IWAD; a vanilla "completion" pass would be a
regression. `FATTT0` was skipped for the same reason — it already ships as
a PNG under `sprites/monsters/Mancubus/T00/`.

**`FATB` AND `FBXP` ARE IN THE TREE, AND THE OWNER HAS RATIFIED THEM.**
Updated 2026-08-06. This paragraph used to say they were "left alone" and
outside the granted scope. They are not: `sprites/rs_doom1compat/` holds
**330 lumps in 6 prefixes, not 317 in 4** — `FATB` (10, the Mancubus
fireball) and `FBXP` (3, its explosion) are present, with the same mtime as
the other 317, so they went in during the same operation. Two independent
audits found them on disk; the owner was shown the finding and answered
"make sure that's enabled". So: authorised, keep them.

Verified enabled the same day, because a present file is not a loaded one:
no competing copy of either prefix exists anywhere else under `sprites/`
(so neither can lose a load-order race), `filter/` carries only
`GLDEFS.brightmaps` per IWAD and does not scope sprites, nothing excludes
the folder, and all 330 lumps are genuine raw Doom patches by magic byte.
The Mancubus fireball and its explosion render on Ultimate Doom.

**Do not let a stale doc talk you out of shipped art.** A cataloguing pass
this same day read THIS paragraph instead of the disk and reported the
Common Revenant's signature missile as invisible on Doom 1. It is not. The
disk is the authority; this file is a summary of it and can go stale.

Technical fact worth keeping: a sprite frame can be the character `\`
(frame index 27), which is legal in a lump name and illegal in a Windows
filename. **GZDoom's escape is `^`** — so `VILE\1` ships as `VILE^1.lmp`.
This is not a typo and must not be "corrected". The engine's own
`brightmaps.pk3` ships `brightmaps/strife/ROB3^0.png` on the same
convention. The rip at `ART SOURCE\SPRITES\archvile\` shows the failure
mode: its `\` frames were flattened by a path-splitting extractor into
eight files named `1.png`…`8.png`.

A `sprites/` folder needs no wiring — GZDoom picks it up automatically.
Nothing in `zscript.txt` or any lump list references this folder.

## Prefer additive changes

Superseded 2026-08-05: this used to describe several sessions running at once.
See "One repo, one branch" above — there is one lane now. What survives is the
habit that was worth having anyway: check `git status` before large edits, and
prefer additive changes over restructuring shared files. A restructure of a
file several systems read is expensive to review and easy to get subtly wrong,
regardless of who else is working.
