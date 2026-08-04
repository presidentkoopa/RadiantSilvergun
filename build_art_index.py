# Rebuilds art_index.json -- the catalogue of sprite art AVAILABLE TO COPY from
# the external ART SOURCE library.
#
# art_index.json is a shopping catalogue, not a dependency list. A token being in
# here means "this art exists somewhere on disk and could be imported"; it does
# NOT mean the mod can load it. Shipping art must be copied into sprites/.
#
# Two things this fixes over the ad-hoc index it replaces:
#   * it walks the WHOLE ART SOURCE tree, not just CH/ and CHP/. The top-level
#     weapon pack was invisible, which is why GRND (a real 10-frame grenade)
#     read as a missing sprite and got papered over in verify.py's vanilla table.
#   * it only accepts sprite-SHAPED image filenames. The old index ingested sound
#     lumps, so e.g. CH/sounds contributed junk tokens that could make a genuinely
#     broken sprite reference resolve by accident.
#
# Project rule: nothing with HF in the name is read or indexed.

import io, os, json, re, sys

ROOT = r'E:\New folder\ART SOURCE'
OUT = 'art_index.json'

IMG = ('.png', '.lmp', '.bmp', '.pcx', '.jpg', '.jpeg', '.gif')
# NAME + frame + rotation, optionally a second frame+rotation for mirrored sprites:
# TROOA1, TROOA2A8, BLADA0 ...
# Frames run past Z into [ \ ] ^ _ (Doom frames 26-31). The Archvile set uses
# them -- rs_15 logs a compile fix for exactly these -- so they must not be
# filtered out as malformed.
FRAME = r'[A-Z\[\\\]^_]'
SHAPE = re.compile(rf'^([A-Z0-9]{{4}})({FRAME})([0-8])(?:({FRAME})([0-8]))?$', re.I)


def is_forbidden(path):
    # CLAUDE.md / project rule: never read anything HF-named.
    return 'hf' in os.path.basename(path).lower().replace('_', '')[:2]


def main():
    index = {}
    scanned = skipped_hf = 0
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if not d.lower().startswith('hf')]
        for fn in filenames:
            base, ext = os.path.splitext(fn)
            if ext.lower() not in IMG:
                continue
            if fn.lower().startswith('hf'):
                skipped_hf += 1
                continue
            m = SHAPE.match(base)
            if not m:
                continue
            scanned += 1
            tok = m.group(1).upper()
            frames = {m.group(2).upper()}
            if m.group(4):
                frames.add(m.group(4).upper())
            # git-bash style path, matching the format the old index used
            d = '/' + dirpath[0].lower() + dirpath[2:].replace('\\', '/')
            e = index.setdefault(tok, {'frames': set(), 'dir': d})
            e['frames'] |= frames

    out = {k: {'frames': ''.join(sorted(v['frames'])), 'dir': v['dir']}
           for k, v in sorted(index.items())}
    with io.open(OUT, 'w', encoding='utf-8') as f:
        json.dump(out, f, indent=0, sort_keys=True)
    print(f'{scanned} sprite files -> {len(out)} tokens  (HF files skipped: {skipped_hf})')


if __name__ == '__main__':
    sys.exit(main())
