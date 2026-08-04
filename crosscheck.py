# Cross-land integration check.
#
# More than one Claude session ("land") works this repo at once, each in its own
# git worktree. Every land can be individually clean and the MERGE still be
# broken, because the damage only exists in the union:
#
#   * two lands each add a class with the same name, in different files
#     (ZScript is CASE-INSENSITIVE, so RS_FireHand1 and RS_Firehand1 collide
#     and GZDoom treats that as a fatal redefinition)
#   * one land deletes a class another land still calls
#   * one land adds a .zs that nobody added to zscript.txt -- silently nonexistent
#   * two lands edit the same file and neither knows
#
# None of those are visible from inside a single land. This script builds the
# PROJECTED MERGED TREE -- main, with each land's divergent changes laid over
# the top -- and runs the checks against that.
#
# Everything merges into main, so main's HEAD is the baseline and each land is
# measured by what it changes RELATIVE TO MAIN (three-dot diff, so work main has
# already absorbed is not counted against the land that wrote it).
#
# Read-only. Touches no working tree, creates no commits, merges nothing.
#
#   python crosscheck.py            # report
#   python crosscheck.py -v         # also list every changed file per land
#
# Exit 0 = safe to commit and push. Exit 1 = cross-damage, do not push.

import io, os, re, sys, subprocess, collections

VERBOSE = '-v' in sys.argv or '--verbose' in sys.argv
SRC_EXT = ('.zs', '.zsc')
CAP = 40                      # max lines listed per finding section


def git(repo, *args):
    r = subprocess.run(['git', '-C', repo] + list(args),
                       capture_output=True, text=True, errors='ignore')
    return r.stdout.strip() if r.returncode == 0 else ''


def lands_of(repo):
    """Every worktree. git always lists the main checkout first."""
    out, cur, res = git(repo, 'worktree', 'list', '--porcelain'), {}, []
    for line in out.splitlines() + ['']:
        if not line.strip():
            if cur.get('path'):
                res.append(cur)
            cur = {}
        elif line.startswith('worktree '):
            cur['path'] = line[9:].strip().replace('\\', '/')
        elif line.startswith('HEAD '):
            cur['head'] = line[5:].strip()
        elif line.startswith('branch '):
            cur['branch'] = line[7:].strip().replace('refs/heads/', '')
        elif line.startswith('detached'):
            cur['branch'] = '(detached)'
    return res


def dirty_paths(path):
    """Staged, unstaged and untracked paths in a working tree.

    Porcelain v1 is 'XY PATH'. Slicing a fixed [3:] silently eats the first
    character of the path when the entry is staged ('M ') rather than merely
    modified (' M') -- which made this check miss a genuinely conflicting file.
    Take everything past the two status columns and strip.
    """
    paths = set()
    for line in git(path, 'status', '--porcelain', '-uall').splitlines():
        p = line[2:].strip().strip('"')
        if ' -> ' in p:                                  # rename
            a, b = p.split(' -> ', 1)
            paths.update((a.strip(), b.strip()))
        elif p:
            paths.add(p)
    return paths


def divergent_paths(land, base_rev, is_main):
    """What this land changes relative to main -- committed and uncommitted.

    Three-dot: only commits on the land's own side of the fork. Work that main
    has already merged in is main's now, not a competing edit.
    """
    paths = set(dirty_paths(land['path']))
    if not is_main:
        for p in git(land['path'], 'diff', '--name-only',
                     base_rev + '...HEAD').splitlines():
            if p.strip():
                paths.add(p.strip())
    return paths


def read_at(repo, rev, path):
    r = subprocess.run(['git', '-C', repo, 'show', rev + ':' + path],
                       capture_output=True)
    return None if r.returncode else r.stdout.decode('utf-8', 'ignore')


def read_disk(land_path, path):
    full = os.path.join(land_path, path)
    if not os.path.exists(full):
        return None
    try:
        return io.open(full, encoding='utf-8', errors='ignore').read()
    except Exception:
        return None


def strip_comments(s):
    s = re.sub(r'/\*.*?\*/', '', s, flags=re.S)
    return re.sub(r'//[^\n]*', '', s)


def listing(rows, cap=CAP):
    for r in rows[:cap]:
        print(r)
    if len(rows) > cap:
        print('  ... and %d more' % (len(rows) - cap))


def main():
    here = os.path.abspath(os.path.dirname(__file__))
    lands = lands_of(here)
    if not lands:
        print('not a git repo')
        return 1

    main_land = lands[0]
    root = main_land['path']
    base = main_land['head']

    if len(lands) < 2:
        print('Only one land attached -- nothing to cross-check.')
        return 0

    print('=' * 70)
    print('CROSS-LAND INTEGRATION CHECK')
    print('=' * 70)
    print('baseline: main @ %s  %s'
          % (base[:8], git(root, 'log', '-1', '--format=%s', base)[:48]))
    print()

    # ---- A. inventory --------------------------------------------------
    print('--- lands ---')
    changed = {}
    for l in lands:
        p = l['path']
        is_main = (p == root)
        ch = divergent_paths(l, base, is_main)
        changed[p] = ch
        l['label'] = 'main' if is_main else os.path.basename(p)
        ahead = '0' if is_main else (
            git(p, 'rev-list', '--count', base + '..HEAD') or '0')
        print('  %-26s %-34s %s ahead, %d file(s) vs main'
              % (l['label'], l.get('branch', '?'), ahead, len(ch)))
        if VERBOSE:
            for f in sorted(ch):
                print('        %s' % f)
    label = {l['path']: l['label'] for l in lands}
    print()

    problems = 0

    # ---- B. same file touched by more than one land ---------------------
    print('--- same-file overlap ---')
    owners = collections.defaultdict(list)
    for p, ch in changed.items():
        for f in ch:
            owners[f].append(label[p])
    overlap = {f: o for f, o in sorted(owners.items()) if len(o) > 1}
    if overlap:
        rows = []
        for f, o in overlap.items():
            rows.append('  CONFLICT  %s' % f)
            rows.append('            claimed by: %s' % ', '.join(sorted(o)))
        listing(rows, CAP * 2)
        problems += len(overlap)
    else:
        print('  clean -- no file is being edited from two lands')
    print()

    # ---- build the projected merged tree --------------------------------
    tree = {}
    for line in git(root, 'ls-tree', '-r', '--name-only', base).splitlines():
        f = line.strip()
        if f.endswith(SRC_EXT) or f == 'zscript.txt':
            tree[f] = ('base', root)
    for p, ch in changed.items():
        for f in ch:
            if f.endswith(SRC_EXT) or f == 'zscript.txt':
                tree[f] = ('land', p)

    contents = {}
    for f, (kind, p) in tree.items():
        s = read_disk(p, f) if kind == 'land' else read_at(root, base, f)
        if s is not None:
            contents[f] = s              # absent = deleted in that land

    def who(f):
        src = tree.get(f)
        return label.get(src[1], 'base') if src and src[0] == 'land' else 'base'

    # ---- C. duplicate class names in the projected merge -----------------
    print('--- projected merge: duplicate class names ---')
    seen = collections.defaultdict(list)
    for f, s in contents.items():
        if f.endswith(SRC_EXT):
            for m in re.finditer(r'^\s*class\s+(\w+)', strip_comments(s), re.M):
                seen[m.group(1).lower()].append((f, m.group(1)))
    dupes = {k: v for k, v in sorted(seen.items()) if len(v) > 1}
    if dupes:
        rows = []
        for k, v in dupes.items():
            rows.append('  FATAL  %s -- defined %d times, will not compile'
                        % (k, len(v)))
            for f, n in v:
                rows.append('           %-28s in %s   [%s]' % (n, f, who(f)))
        listing(rows, CAP * 2)
        problems += len(dupes)
    else:
        print('  clean -- %d classes, all names unique' % len(seen))
    print()

    # ---- D. classes a land deleted out from under another ----------------
    # Only NEWLY dangling names count as cross-damage. This repo carries a
    # standing backlog of RS_ names referenced but never written; reporting
    # those every run buries the one line that actually matters.
    print('--- projected merge: newly dangling RS_ references ---')
    # base_defined maps class -> the file that defined it on main, so a
    # vanished class can be blamed on whichever land owns that file now.
    base_defined = {}
    for line in git(root, 'grep', '-nIE', r'^\s*class\s+\w+', base,
                    '--', '*.zs', '*.zsc').splitlines():
        parts = line.split(':', 3)
        if len(parts) < 4:
            continue
        m = re.search(r'class\s+(\w+)', parts[3])
        if m:
            base_defined.setdefault(m.group(1).lower(), parts[1])

    defined = set(seen.keys())
    dangling = collections.defaultdict(set)
    samehand = backlog = 0
    for f, s in contents.items():
        if not f.endswith(SRC_EXT):
            continue
        caller = who(f)
        for c in set(re.findall(r'"(RS_\w+)"', strip_comments(s))):
            if c.lower() in defined:
                continue
            src_file = base_defined.get(c.lower())
            if src_file is None:
                backlog += 1                      # never existed -- backlog
            elif who(src_file) == caller:
                samehand += 1                     # one land's own WIP
            else:
                dangling[c].add((f, caller, who(src_file)))
    if dangling:
        rows = []
        for c, hits in sorted(dangling.items()):
            for f, caller, deleter in sorted(hits):
                rows.append('  BROKEN  %s -- deleted by %s, still called from %s'
                            % (c, deleter, f))
                rows.append('            (caller belongs to %s)' % caller)
        listing(rows, CAP * 2)
        problems += len(dangling)
    else:
        print('  clean -- no land deletes a class another land still calls')
    notes = []
    if samehand:
        notes.append('%d within a single land (that land\'s own work in progress)'
                     % samehand)
    if backlog:
        notes.append('%d never defined anywhere (standing backlog)' % backlog)
    if notes:
        print('  ignored: ' + '; '.join(notes))
    print()

    # ---- E. .zs files missing from zscript.txt ---------------------------
    print('--- projected merge: zscript.txt includes ---')
    inc = contents.get('zscript.txt', '')
    if not inc:
        print('  zscript.txt not found -- skipped')
    else:
        # Follow #include chains -- a file pulled in by an included file is
        # included. Commented-out includes do not count.
        included, queue = set(), ['zscript.txt']
        while queue:
            cur = queue.pop()
            body = contents.get(cur)
            if body is None:
                continue
            for hit in re.findall(r'^\s*#include\s+"([^"]+)"',
                                  strip_comments(body), re.M):
                h = hit.strip().replace('\\', '/').lstrip('./').lower()
                if h not in included:
                    included.add(h)
                    queue.append(hit.strip().replace('\\', '/').lstrip('./'))
        miss = [f for f in sorted(contents)
                if f.endswith(SRC_EXT) and f.startswith('zscript/')
                and f.lower() not in included]
        if miss:
            listing(['  SILENT  %s not included -- its classes will not exist  [%s]'
                     % (f, who(f)) for f in miss])
            problems += len(miss)
        else:
            print('  clean -- every zscript source file is included')
    print()

    # ---- F. forbidden residue --------------------------------------------
    print('--- projected merge: forbidden residue ---')
    rows = []
    for f, s in sorted(contents.items()):
        if not f.endswith(SRC_EXT):
            continue
        body = strip_comments(s)
        for pat, lab in ((r'\bHF_', 'HF_ reference'),
                         (r'RadiantSilvergun', 'E:/RadiantSilvergun path')):
            if re.search(pat, body):
                rows.append('  %s: %s   [%s]' % (f, lab, who(f)))
    if rows:
        listing(rows)
        problems += len(rows)
    else:
        print('  clean')
    print()

    print('=' * 70)
    if problems:
        print('RESULT: %d PROBLEM(S) -- DO NOT COMMIT/PUSH UNTIL RESOLVED' % problems)
    else:
        print('RESULT: ALL CLEAN -- the lands merge without cross-damage')
    print('=' * 70)
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
