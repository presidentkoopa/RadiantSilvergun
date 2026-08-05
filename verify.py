import io,re,os,glob,json,sys
idx=json.load(io.open('art_index.json',encoding='utf-8'))
ALL={k:set(v['frames']) for k,v in idx.items()}
# repo sprites too
for d,_,fs in os.walk('sprites'):
    for f in fs:
        b=os.path.splitext(f)[0]
        if len(b)<5: continue
        s=ALL.setdefault(b[:4].upper(),set()); s.add(b[4].upper())
        if len(b)>=7: s.add(b[6].upper())
VAN={'POSS':'ABCDEFGHIJKLMNOPQRSTU','SPOS':'ABCDEFGHIJKLMNOPQRSTU','CPOS':'ABCDEFGHIJKLMNOPQRST',
'TROO':'ABCDEFGHIJKLMNOPQRSTU','SARG':'ABCDEFGHIJKLMN','HEAD':'ABCDEFGHIJKL','SKUL':'ABCDEFGHIJK',
'PAIN':'ABCDEFGHIJKLM','BOSS':'ABCDEFGHIJKLMN','BOS2':'ABCDEFGHIJKLMN','FATT':'ABCDEFGHIJKLMNOPQRS',
'SKEL':'ABCDEFGHIJKLMNOPQRST','VILE':'ABCDEFGHIJKLMNOPQRSTUVWXYZ','BSPI':'ABCDEFGHIJKL',
'SPID':'ABCDEFGHIJKLMNOPQR','CYBR':'ABCDEFGHIJKLMNOP','PLAY':'ABCDEFGHIJKLMNOPQRSTUVW','TNT1':'A',
'MISL':'ABCDE','BAL1':'ABCDE','BAL2':'ABCDE','BAL7':'ABCDE','FATB':'ABCDE','FBXP':'ABC','MANF':'AB',
'BOSF':'ABCD',
'APLS':'AB','APBX':'ABCDE','PUFF':'ABCD','BLUD':'ABC','TFOG':'ABCDEFGHIJ','FIRE':'ABCDEFGH',
'BFE1':'ABCDEF','BFE2':'ABCDE','BFS1':'ABCD','PLSS':'AB','PLSE':'ABCDE','BAR1':'ABCD','HMIS':'AB',
# SHOT = the IWAD shotgun pickup lump (single frame); CH's MineShotgun reuses it as a thrown mine.
# NOTE: this table is for REAL IWAD lumps only. 'GRND':'A' used to live here and is not a Doom
# sprite -- it was invented to silence a broken reference. Copy art into sprites/ instead.
'SHOT':'A'}
for k,v in VAN.items(): ALL.setdefault(k,set()).update(set(v))
defined=set()
for f in glob.glob('zscript/**/*.zs',recursive=True)+glob.glob('zscript/**/*.zsc',recursive=True):
    defined|=set(x.lower() for x in re.findall(r'^\s*class\s+(\w+)',io.open(f,encoding='utf-8',errors='ignore').read(),re.M))
STOCK={'BaronBall','DoomImpBall','CacodemonBall','RevenantTracer','ArachnotronPlasma','FatShot',
'BulletPuff','Blood','RocketSmokeTrail','TeleportFog','LostSoul','DoomImp','ArchvileFire'}
defined|=set(x.lower() for x in STOCK)
BASE={'See','Spawn','Missile','Melee','Pain','Death','XDeath','Raise','Heal','Burn','Crash','Wound','Idle','Look'}
bad=0
for name in sys.argv[1:]:
    p=f'zscript/monsters/{name}.zs'
    if not os.path.exists(p): print(name,'MISSING FILE'); bad+=1; continue
    src=io.open(p,encoding='utf-8').read(); probs=[]
    # Sprite scan runs on comment-stripped source and is NOT anchored to line
    # start: most state blocks here are written inline (States { Spawn: ...; }),
    # and an ^-anchored scan walked straight past every one of them.
    code=re.sub(r'/\*.*?\*/','',re.sub(r'//[^\n]*','',src),flags=re.S)
    for tok,fr in re.findall(r'(?<![A-Za-z0-9_])"?([A-Z0-9]{4})"?\s+([A-Z]+)\s+-?\d',code):
        # NOTE: vanilla tokens are checked, not skipped. A `if tok in VAN:
        # continue` used to live here, added because the hand-written frame
        # lists gave false failures (FATT T is real and was missing from the
        # table). But skipping is pure loss: PUFF is in VAN, so `PUFF DE` --
        # vanilla PUFF has no E -- became invisible, and that is exactly the
        # typo this lint exists to catch. The frames below are the UNION of
        # VAN + repo sprites + art_index, so a vanilla token extended by repo
        # art already passes: MISL X/Y/Z are used on 19 lines across 5 files
        # and are shipped in sprites/monsters/fx/. Fix the table, keep looking.
        h=ALL.get(tok)
        if h is None: probs.append(f'sprite {tok} NOT FOUND'); continue
        m=sorted(set(fr)-h)
        if m: probs.append(f'{tok} missing {"".join(m)}')
    # EVERY check below reads `code`, not `src`. The sprite scan above was
    # already comment-stripped; the label and class checks were not, so a
    # comment QUOTING DECORATE -- e.g. explaining that CH writes
    # A_JumpIf(CallACS("CH_Intercept") == true,"Miss2") -- registered
    # "CH_Intercept" and "Miss2" as real jump targets and reported both
    # UNRESOLVED. Same disease as the ^-anchored sprite scan this file was
    # opened to fix, and the same fix: read code, not prose.
    for c in set(re.findall(r'"([A-Z]\w+)"',code)):
        if (c.startswith('RS_') or c in STOCK) and c.lower() not in defined: probs.append(f'class {c} UNDEFINED')
    # Labels are NOT always alone on their line -- `A5: TCLK E 10 {...} Loop;`
    # is common. Requiring end-of-line missed every inline one. (?!:) keeps the
    # Super:: scope qualifier from registering as a label named Super.
    labels=set(re.findall(r'^\s*([A-Za-z][\w.]*):(?!:)',code,re.M))
    tg=set()
    # `Goto Super::Spawn + 1` targets the PARENT's Spawn. Super:: is a scope
    # qualifier, not a label -- strip it or every such line reads as broken.
    for t in re.findall(r'Goto\s+((?:\w+::)?[A-Za-z][\w.]*)',code): tg.add(t.split('::')[-1])
    # The label is NOT always the first quoted argument, and assuming so made
    # every A_JumpIfInventory in the project look broken:
    #   A_JumpIfInventory("RS_WhiteSoulAdsOff", 1, "See")  <- arg 1 is an ITEM
    #                                                         CLASS; the label
    #                                                         is the LAST arg.
    #   A_Jump(chance, "A", "B", "C")                      <- ALL are labels.
    #   ResolveState / A_CheckSight / A_MonsterRefire      <- first is right.
    for fn,args in re.findall(r'\b(ResolveState|A_Jump\w*|A_CheckSight|A_MonsterRefire)\s*\(([^)]*)\)',code):
        q=re.findall(r'"([A-Za-z][\w.:]*)"',args)
        if not q: continue
        if fn=='A_Jump': tg|=set(q)
        elif fn.startswith('A_JumpIf'): tg.add(q[-1])
        else: tg.add(q[0])
    for t in tg:
        b=t.split('+')[0].split('::')[-1].strip()
        if b and b not in labels and b not in BASE: probs.append(f'label {t} UNRESOLVED')
    if 'RS_WearBody()' in src: probs.append('RS_WearBody callsite')
    if re.search(r'\{\s*A_[A-Za-z]\w*\s*;',src): probs.append('bare action call')
    if 'GetSpriteIndex' in src: probs.append('runtime GetSpriteIndex')
    if probs: bad+=1
    print(f'{name:22s} {"OK" if not probs else "PROBLEMS"}')
    for x in sorted(set(probs))[:10]: print('   ',x)
sys.exit(1 if bad else 0)
