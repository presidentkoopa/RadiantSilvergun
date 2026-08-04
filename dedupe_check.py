# Repo-wide duplicate-class check. ZScript is CASE-INSENSITIVE, so
# RS_FireHand1 and RS_Firehand1 are the SAME class and defining both is a
# fatal redefinition. Two separate people (me and a subagent) each got
# caught by case here, so this is the single source of truth.
import io,re,glob,collections,os,sys
seen=collections.defaultdict(list)
for f in glob.glob('zscript/**/*.zs',recursive=True)+glob.glob('zscript/**/*.zsc',recursive=True):
    s=io.open(f,encoding='utf-8',errors='ignore').read()
    for m in re.finditer(r'^\s*class\s+([A-Za-z_]\w*)',s,re.M):
        seen[m.group(1).lower()].append((os.path.basename(f),m.group(1)))
d={k:v for k,v in seen.items() if len(v)>1}
if not d:
    print('OK - no duplicate class names'); sys.exit(0)
print(f'FATAL: {len(d)} duplicate class name(s) -- the mod will not compile')
for k,v in sorted(d.items()):
    print(' ',k)
    for f,n in v: print(f'      {n}  in  {f}')
sys.exit(1)
