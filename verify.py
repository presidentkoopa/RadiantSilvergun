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
        # Vanilla IWAD tokens: we have no IWAD to read, so asserting frame
        # ranges from memory produced two false failures already (PAIN M,
        # FATT T -- both real vanilla frames). Only existence is checked
        # for those; GZDoom reports a genuinely missing frame at load.
        if tok in VAN: continue
        h=ALL.get(tok)
        if h is None: probs.append(f'sprite {tok} NOT FOUND'); continue
        m=sorted(set(fr)-h)
        if m: probs.append(f'{tok} missing {"".join(m)}')
    for c in set(re.findall(r'"([A-Z]\w+)"',src)):
        if (c.startswith('RS_') or c in STOCK) and c.lower() not in defined: probs.append(f'class {c} UNDEFINED')
    labels=set(re.findall(r'^\s*([A-Za-z][\w.]*):\s*$',src,re.M))
    tg=set(re.findall(r'Goto\s+([A-Za-z][\w.]*)',src))|set(re.findall(r'(?:ResolveState|A_Jump\w*|A_CheckSight|A_MonsterRefire)\([^)]*?"([A-Za-z][\w.]*)"',src))
    for t in tg:
        b=t.split('+')[0].strip()
        if b not in labels and b not in BASE: probs.append(f'label {t} UNRESOLVED')
    if 'RS_WearBody()' in src: probs.append('RS_WearBody callsite')
    if re.search(r'\{\s*A_[A-Za-z]\w*\s*;',src): probs.append('bare action call')
    if 'GetSpriteIndex' in src: probs.append('runtime GetSpriteIndex')
    if probs: bad+=1
    print(f'{name:22s} {"OK" if not probs else "PROBLEMS"}')
    for x in sorted(set(probs))[:10]: print('   ',x)
sys.exit(1 if bad else 0)
