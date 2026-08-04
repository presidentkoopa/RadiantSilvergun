import io,os,re,glob,subprocess,sys
FAMS=['RS_Zombieman','RS_Shotgunner','RS_Chaingunner','RS_Imp','RS_Demon','RS_Spectre',
 'RS_LostSoul','RS_Cacodemon','RS_PainElemental','RS_Baron','RS_HellKnight','RS_Revenant',
 'RS_Mancubus','RS_Arachnotron','RS_Archvile','RS_Mastermind','RS_Cyberdemon',
 'RS_Minions','RS_MonsterStages','RS_ExBosses']
print('='*62); print('WHOLE-SET VERIFICATION'); print('='*62)

# 1 per-family static check
present=[f for f in FAMS if os.path.exists(f'zscript/monsters/{f}.zs')]
missing=[f for f in FAMS if f not in present]
r=subprocess.run([sys.executable,'verify.py']+present,capture_output=True,text=True)
print(r.stdout.strip())
if missing: print('\nFILES NOT YET WRITTEN: '+', '.join(missing))

# 2 forbidden-source residue
print('\n--- HF / legacy residue ---')
bad=0
mon=glob.glob('zscript/monsters/**/*.zs',recursive=True)+glob.glob('zscript/systems/RS_Monster*.zs')
for f in mon:
    s=io.open(f,encoding='utf-8',errors='ignore').read()
    for pat,label in [(r'\bHF_','HF_ reference'),(r'RadiantSilvergun','HF path'),
                      (r'GetSpriteIndex','runtime sprite lookup'),(r'RS_WearBody\(\)','skin-system call')]:
        if re.search(pat,s): print(f'  {f}: {label}'); bad+=1
if not bad: print('  clean')

# 3 zscript.txt includes
print('\n--- zscript.txt includes ---')
inc=io.open('zscript.txt',encoding='utf-8',errors='ignore').read()
for f in present:
    if f'{f}.zs' not in inc: print(f'  MISSING INCLUDE: {f}.zs'); bad+=1
else: print('  all present files are included' if all(f'{f}.zs' in inc for f in present) else '')

# 4 per-tier sprite folders
print('\n--- sprite coverage ---')
for f in present:
    fam=f.replace('RS_','')
    d=f'sprites/monsters/{fam}'
    if not os.path.isdir(d): continue
    n=sum(len(fs) for _,_,fs in os.walk(d))
    tiers=sorted(x for x in os.listdir(d) if os.path.isdir(os.path.join(d,x)))
    print(f'  {fam:16s} {n:5d} files  {len(tiers):2d} tier dirs')
print('\n'+('='*62))
print('RESULT: '+('PROBLEMS ABOVE' if (bad or missing or 'PROBLEMS' in r.stdout) else 'ALL CLEAN'))
