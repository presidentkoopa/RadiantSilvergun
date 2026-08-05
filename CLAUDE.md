# Radiant Silvergun (RS_Main) — project rules

## Start here

Before doing anything else, read the most recent `docs/rs_0*_session_handoff*.txt`
(check all matching files, use the highest number / latest date) for what the
last session actually built, what's mid-flight, and the ranked next-priority
list. Don't re-derive project state from scratch — it's already written down.

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
  matching `Death.T08` inside `XDeath.T08`.

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

**THE GROUND TRUTH IS `E:\New folder\ART SOURCE\CHP\DECORATE\NN\NN_<code>.txt`,
AND THE GAME.** CHP always wins; CH fills only what CHP leaves undefined. If a
tool is written again it must be a **differ against CHP**, not a lint over us —
it must be able to say "CHP's actor does X, ours does Y" and cite both. Anything
that can only inspect our own tree tells you nothing you did not already believe.

Between the compiler, a boot, and CHP's own files, everything those five scripts
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

## Prefer additive changes

Superseded 2026-08-05: this used to describe several sessions running at once.
See "One repo, one branch" above — there is one lane now. What survives is the
habit that was worth having anyway: check `git status` before large edits, and
prefer additive changes over restructuring shared files. A restructure of a
file several systems read is expensive to review and easy to get subtly wrong,
regardless of who else is working.
