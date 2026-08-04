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
     they're two different classes. Run `python dedupe_check.py` (repo root)
     after adding any class — it checks this properly.
- **A passing check is not a correct result — know what it actually proves.**
  `dedupe_check.py` proves no name is defined twice. It does NOT prove the
  surviving copy is the right actor. A mechanical de-duplication that keeps
  whichever definition comes first in load order got 5 of 15 wrong here, and
  every one of those five passed every check in the repo. The sharpest was
  `RS_ZAPFFAT2`, whose surviving copy had `A_Explode` on a *looping* state —
  unbounded damage, forever, silently. When two definitions collide, open
  both and diff them against CH/CHP; don't let position decide.
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
  matches almost nothing. `verify.py`'s sprite check had this bug and reported
  OK on files it never read; the sweep script written to fix the damage bug then
  made the identical mistake and missed 21 sites. Also strip `//` lines before a
  bulk rewrite, or it edits prose.

## Parallel lanes

Several sessions run at once, some sharing the `E:\RS_Main` working tree, some
in their own worktrees. Consequences that have already bitten:

- **Never `git add -A` in a shared working tree.** One lane swept another's
  in-flight edits into its own commits, so `git log` blames it for files it
  never wrote. Stage explicit paths.
- **Count against `main`, not your worktree.** A branch that forked days ago
  cannot see what `main` added; every count derived from it is wrong.
- **Merge, don't rebase, once a branch is pushed** — rebasing rewrites published
  history other lanes may have pulled. Rebase is right only while unpushed.
- **Two lanes making the *identical* edit is not a conflict.** Git's three-way
  merge absorbs it. Test with `git merge-tree --write-tree A B` before asking
  anyone to back work out.
- `crosscheck.py` at the repo root projects every lane onto `main` and reports
  the damage that only exists in the union — duplicate class names, classes one
  lane deletes that another calls, files missing from `zscript.txt`.

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

## Parallel work

More than one session may be active on this repo (e.g. weapons/PACK in one,
the Colourful Hell monster set in another). Check `git status` before large
edits, and prefer additive changes over restructuring shared files.
