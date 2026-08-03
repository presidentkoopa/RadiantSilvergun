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
