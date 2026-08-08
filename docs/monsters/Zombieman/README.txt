// =====================================================================
// !! DO NOT TRUST THIS DOCUMENT. ASK THE OWNER.
//
// Nothing in docs/ is authoritative -- not the handoffs, not the specs,
// not the ones the owner asked for himself. This file describes what was
// true when somebody wrote it, and this project has repeatedly proven
// that "true when written" and "true now" are different things.
//
// Verify anything you are about to act on against the DISK, the
// COMPILER, or the RUNNING GAME. Ask the owner about anything to do with
// scope, priority, or what to build next. Never inherit a task from a
// document.
//
// Real examples from this repo, every one a document confidently stating
// something false: an engine path that did not exist for weeks; a source
// pack path pointing at the wrong pack; "87% of sounds are missing" that
// was true when written and false when read; a rule forbidding an
// extraction that had already happened; a note that ORDERED sessions not
// to attempt a fix that turned out to be four lines.
//
// Banner added 2026-08-07 at the owner's instruction.
// =====================================================================

================================================================================
  ZOMBIEMAN (CHP family 01) -- WHAT EACH TIER IS, ITS SUB-VARIANTS, ITS ACS,
  AND WHAT OUR TREE IS MISSING.
  Written 2026-08-04 to docs/rs_21_port_law.txt. PHASE 1: documentation only.
  Companion catalog: docs/monsters/Zombieman.md
================================================================================

GROUND TRUTH, and the only thing checked:
    E:\New folder\ART SOURCE\CHP\DECORATE\01\01_*.txt
    E:\New folder\ART SOURCE\CHP\source\*.acs
    E:\New folder\ART SOURCE\CH\decorate\*.txt        (fallback)
Paths below are relative to E:\New folder\ART SOURCE\.

Colour -> tier:  C=T00 G=T01 B=T02 CY=T03 P=T04 Y=T05 A=T06 F=T07
                 BR=T08 GY=T09 R=T10 K=T11 W=T12 KX=TEX WX=TEX2

FOURTEEN TIERS EXIST, NOT FIFTEEN.
  01_WX.txt is ZERO BYTES (0 lines). It is still #included at
  CHP/DECORATE.txt:661, and the actor it would define is stubbed:
      CHP/DECORATE.txt:369   Actor CommonWhiteZombieEX : Nothin {}
  `Nothin` is CHP/DECORATE.txt:11-22 -- +NOCLIP +NOBLOCKMAP +NOGRAVITY,
  Spawn: TNT1 A 0 / Stop. It spawns nothing and vanishes.
  There is no White-EX Zombieman in CHP or in CH. Anything in our tree that
  claims one is inventing it.


================================================================================
1. WHAT EACH TIER IS
================================================================================

T00  COMMON        01_C.txt:1-74     CommonCommonZombie : CommonZombie
     HP 20, Speed 7, PainChance 200, sprite POSS.
     The vanilla grunt, unchanged in every way that matters. Ten tics to
     raise the rifle, one bullet in a 22.5-degree cone for 3/6/9/12/15, eight
     tics to lower it. It flinches at almost anything (PainChance 200) and
     dies to a single shotgun blast. Its only job is to be the thing the rest
     of the ladder is measured against. On death, if the Undertaker has been
     on the map, its corpse hatches a skeleton (01_C.txt:34 -> Tick:).
     It also carries the two promotion chains CH built into every zombie:
     Raise with a GrowRaisin token turns it into a Green (01_C.txt:58-62),
     and dying while carrying CHAbyssMark turns it into an Abyss zombie
     (01_C.txt:63-69).

T01  GREEN         01_G.txt:1-87     CommonGreenZombie : GreenZombie
     HP 30, Speed 9, PainChance 180, sprite ZOMG.
     A zombie that leaks poison gas. Same rifle as T00 but fired TWICE per
     attack pass, with a stationary gas cloud dropped before, between, and
     after each shot. Once it has fired once it never returns to the clean
     walk loop -- CHP sends it to See2 (01_G.txt:23-26), which drops another
     cloud every lap, forever. It also gasses on pain and twice more as it
     dies. Fighting one in a corridor means the corridor becomes unwalkable
     behind it.

T02  BLUE          01_B.txt:1-78     CommonBlueZombie : BlueZombie
     HP 40, Speed 9, PainChance 140, sprite ZOMB.
     The first one that shoots properly. Three rounds on one tic in a tight
     7x7 cone, and it alternates A_Chase with A_FastChase on its walk loop so
     it closes ground while doing it. No gimmick, just a better zombie.

T03  CYAN          01_CY.txt:1-59    CommonCyanZombie : CyanZombie2
     HP 30, Speed 9, PainChance 40, Alpha 0.75 translucent, sprite CYNT.
     A frozen thing that barely flinches. Fires a flat ice shard -- the
     fastest attack cycle in the low tiers (6/4/4 tics) -- and its shard is
     drawn at yScale 0.15, so it is a horizontal sliver that is genuinely
     hard to see coming at you head-on. PainChance 40 means shooting it does
     not interrupt its rhythm. And it has NO ordinary corpse: its Death state
     wobbles for about fifty tics through twelve A_SetScale frames and then
     A_Burst's into ice chunks (01_CY.txt:39-57). It has no XDeath and no
     Raise in either CHP or CH -- CH CyanZombie2 defines neither, verified.

T04  PURPLE        01_P.txt:1-82     CommonPurpleZombie : PurpleZombie
     HP 65, Speed 10, PainChance 120, sprite BPOS.
     A range-switcher. Inside 800 units it does a hitscan double-tap with a
     narrowing cone; beyond that it throws three seeking, weaving plasma orbs
     five tics apart. The two halves want completely different play from you,
     which is the point -- there is no single distance that beats it.

T05  YELLOW        01_Y.txt:1-88     CommonYellowZombie : YellowZombie
     HP 90, Speed 13, PainChance 100, sprite CZOW. Tag "Yellow Zombiewoman".
     Chaingun and rocket launcher, and the launcher JAMS. Inside 550 she
     bursts three chaingun rounds with a widening cone; beyond that she
     coin-flips between more of that and a mini-rocket. She carries exactly
     three rockets. On the fourth attempt she sets +NOPAIN, plants herself in
     the open for eighty tics hammering the stuck weapon, then clears it and
     carries on. That jam is a free window on a 90 HP monster you cannot
     stunlock -- baiting three rockets and then closing is the fight.
     She also has a Dodger walk (01_Y.txt:18-21) she falls into after pain,
     A_FastChase with an 88/256 chance per lap of dropping back to normal.

T06  ABYSS         01_A.txt:1-69     CommonAbyssZombie : AbyssZombie2
     HP 200, GibHealth -100, Speed 14, PainChance 18, sprite ABTR.
     The first heavyweight. Twin dark bolts on diverging arcs five tics apart
     -- deliberately un-dodgeable with one sidestep -- each detonating three
     times where it lands. It sows harmless abyss splash as it walks, so you
     can see where it has been. And HURTING IT IS A TRIGGER: two tics of
     flinch and then forty-five damaging droplets fill a 356x356 box around
     it. At PainChance 18 the flinch costs it nothing. It also marks nearby
     zombies for abyss conversion the instant it spawns (01_A.txt:18-19).

T07  FIREBLU       01_F.txt:1-80     CommonFirebluZombie : FirebluZombie2
     HP 50, GibHealth -5, Speed 12, PainChance 255, sprite ZOMF.
     A kamikaze with no ranged attack whatsoever. CHP's Missile state is one
     blank tic straight back into the walk (01_F.txt:31-33). What it does is
     run at you leaking fire from its footprints, flinching constantly
     (PainChance 255 makes it look harmless), and when it reaches you it
     spends ten tics winding up and then kills ITSELF -- DamageThing(9999) --
     into an 84-unit explosion that also throws seven more fire clouds.
     GibHealth -5 means almost anything overkills it into that same explosion
     from range, which is the counter.

T08  BROWN         01_BR.txt:1-119   CommonBrownZombie : BrownZombie2
     HP 100, Speed 4, PainChance 128, Mass 1000, Radius 24, Height 64,
     sprite SGAR. Tag "GET DOWN MR PRESIDENT".
     A bodyguard, and it is a SUPPORT unit. At Speed 4 it cannot chase you,
     so it plants and snipes: one accurate bullet in a 5-degree cone for a
     flat 10, on a thirty-tic cycle. But half its walk laps it scans 1000
     units for an Archvile, Baron, Hell Knight, Cyberdemon or Chaingunner,
     and if one has line of fire it launches itself into the air, rolls
     bodily between that demon and the shot, and HEALS every monster within
     100 units by 50 on the way through. Killing the bodyguards first is a
     real decision. It also has a FrontJump (01_BR.txt:70-76) that hurls it
     at the player -- pure movement, no damage.

T09  GRAY          01_GY.txt:1-83    CommonGrayZombie : GrayZombie2
     HP 80, Speed 4, PainChance 40, Mass 400, BloodColor Black, sprite SHDT.
     Stationary artillery. Three fast rocks in six tics, then a ten-tic tail;
     rocks are DamageType "Melee", Speed 36, tiny (Scale 0.25), and burst
     into dirt. And gibbing it is punished: the corpse swells and squashes
     for about fifty readable tics and then bursts, throwing THIRTEEN rocks
     in thirteen random directions (01_GY.txt:50-68). The wobble is a
     telegraph, not a gotcha -- you get time to move.

T10  RED           01_R.txt:1-70     CommonRedZombie : RedZombie
     HP 115, GibHealth -100, Speed 8, PainChance 100, sprite ZUNM.
     Tag "Red ZombieUnman". Carries the Unmaker.
     Three times in four it fires one heavy slug -- random(5,15) x random(1,3)
     = up to 45 -- through a +EXTREMEDEATH puff, so kills always gib. The
     other quarter is the Unmaker: sixteen tics of a rising "unpower" charge,
     then FIVE instant rail beams in five tics, fading FF -> CC -> 99 -> 55 ->
     33 red. There is nothing to dodge once it starts; the charge is the whole
     window. A_SentinelRefire loops it back to the FIRST BEAM, not the charge
     (01_R.txt:38), so it sustains with only ten tics between volleys.
     CHP also defines CommonRedZombie2 (01_R.txt:1197-1222), identical except
     that it drops the RandomLetterSpawner_C from Death and XDeath.

T11  BLACK         01_K.txt:1-116    CommonBlackZombie1 : BlackZombie1
     HP 2000, GibHealth -500, Speed 26, PainChance 16, sprite ZOMK.
     Tag "Player 9". Translation "0:0=0:0". +BOSS.
     Not a zombie -- a dead marine with the player's whole loadout and the
     player's own sounds. A range ladder: under 300 the super shotgun, under
     840 plasma spam, beyond that chaingun taps with rockets salted in. The
     SSG holds ONE SHELL: it fires, and the next time it wants the shotgun it
     must spend twenty tics reloading and throwing a spent Shell actor. In
     melee it punches for random(20,80) and then immediately goes to the SSG.
     Announces itself on spawn with an ACS HUD message. No Raise state in
     CHP or CH.

T12  WHITE         01_W.txt:1-187    CommonWhiteZombie1 : WhiteZombie1
     HP 3500, GibHealth -500, Speed 10, PainChance 16, Mass 400, sprite MAGE.
     Tag "UNDERTAKER". Species "UnderTaker". +BOSS +LOOKALLAROUND +NOFEAR.
     A necromancer with a shovel, and the only tier in the family whose
     mechanic reaches every other monster on the map.
     Range picks the attack: inside 550 a three-blade shovel fan that itself
     sheds twenty-plus side blades per swing; 550-1250 a nine-to-twelve bone
     shotgun in a 24-degree cone, every bone +FORCEPAIN; beyond 1250 a
     sustained rapid bone stream on a refire loop.
     THE LOOP: on spawn it does A_Radiusgive("CHWhitePlan", 16383,
     RGF_NOSIGHT|RGF_MONSTERS) -- it marks EVERY MONSTER ON THE MAP, through
     walls. Every marked monster's death then hatches a MrBones skeleton out
     of the corpse. Its bones and blades also leave skeletons where they land
     (2.3% and 50% respectively). And when a MrBones DIES it radius-gives the
     Undertaker random(12,128) health AND one BoneUp token. BoneUp 5, 9 and
     12 are Buff1/Buff2/Buff3: speed 16 -> 21 -> 28, scale 1.1 -> 1.25 ->
     1.45, +MISSILEEVENMORE, then +NOPAIN, bone grade 3, and FinalForm, which
     unlocks the BONE TORNADO -- a wandering vortex that A_Warps seven streams
     of ripping bone around itself.
     So killing its skeletons heals it and levels it up, and not killing them
     lets them raise themselves twice and then turn into REVENANTS. That
     tension IS the boss. No Raise state.

TEX  BLACK-EX      01_KX.txt:1-192   CommonBlackZombieEX2 : BlackZombieEX
     HP 5000, GibHealth -500, Speed 28, PainChance 16, sprite ZMKX.
     Tag "Player X". SeeSound/ActiveSound "HEHEEENH". +BOSS +LAXTELEFRAGDMG.
     Player 9 with everything turned up and two new ideas.
     Same range ladder (SSG / plasma / chaingun) but it MOVES inside it: it
     hops the last of the gap before the SSG, it backpedals-then-strafes
     left or right on a coin flip before a three-rocket barrage, and it
     answers PAIN with that barrage 84/256 of the time -- hurting it makes it
     more dangerous. Its SSG reload does not return to neutral: it commits
     straight into the barrage or the BFG.
     And it has the BFG: twenty-four tics of glowing, motionless, map-audible
     wind-up, then one un-spread ball for random(100,200) that detonates for
     random(45,125) over 156 units, quakes the screen, and blooms twenty-nine
     shrapnel bolts at random(20,80) each. FOUR separate branches can escalate
     into it, so no distance is safe -- only the wind-up.
     It also TAUNTS. Every single attack ends with
     A_CheckFlag("CORPSE","TAUNT",AAPTR_TARGET) -- if its target is a corpse
     it breaks off and spends about a hundred tics laughing at you
     (01_KX.txt:46-66), playing "HEHEEENH" eighteen times. It is the only
     moment in the fight where it stops shooting.

TEX2 WHITE-EX      DOES NOT EXIST. See the header of this file.


================================================================================
2. SUB-VARIANTS -- THE SPAWN-COLOUR AXIS WE ARE NOT PORTING YET
================================================================================

Per rs_21:53-66 we port the `Common*` actor of each tier. The other fourteen
sub-variants per tier are CHP's spawn-colour axis. They are recorded here so
adding the axis later is a table-filling job.

FINDING, AND IT MAKES THE LATER JOB MUCH SMALLER:
  THE TRANSLATION TABLE IS IDENTICAL IN ALL FOURTEEN TIERS. `GreenCommonZombie`,
  `GreenBlueZombie`, `GreenWhiteZombie1` and `GreenBlackZombieEX2` all carry
  byte-for-byte the same Translation string. Checked in all fourteen tier files.
  So this is ONE table of fourteen strings for the whole family -- not fourteen
  tables of fourteen.

EVERY TIER HAS EXACTLY THESE FOURTEEN SUB-VARIANTS, in this order:
  Green, Blue, Purple, Yellow, Red, Black, White, BlackEX, WhiteEX,
  Abyss, Brown, Cyan, Fireblu, Gray
  (naming: <SubVariant><TierColour>Zombie, e.g. GreenCyanZombie)

THE TABLE, verbatim (quoted from 01_C.txt lines 88/165/242/319/396/473/550/
628/706/783/867/951/1028/1108; identical strings verified at the corresponding
lines of 01_G, 01_B, 01_P, 01_Y, 01_A, 01_F, 01_CY, 01_BR, 01_GY, 01_R, 01_K,
01_W, 01_KX):

  Green     Translation "0:255=%[0.00,0.00,0.00]:[0.18,1.32,0.18]"
  Blue      Translation "0:255=%[0.00,0.00,0.00]:[0.47,0.96,1.79]"
  Purple    Translation "0:255=%[0.00,0.00,0.00]:[1.13,0.47,1.79]"
  Yellow    Translation "0:255=%[0.00,0.00,0.00]:[1.32,1.32,0.18]"
  Red       Translation "0:255=%[0.00,0.00,0.00]:[1.56,0.20,0.20]"
  Black     Translation "0:255=%[0.00,0.00,0.00]:[0.60,0.60,0.60]"
  White     Translation "0:255=%[0.00,0.00,0.00]:[1.80,1.80,1.80]"
  BlackEX   Translation "0:255=%[0.00,0.00,0.00]:[0.00,0.00,0.00]"
  WhiteEX   Translation "0:255=%[2.00,2.00,2.00]:[2.00,2.00,2.00]"
  Abyss     Translation "0:255=%[0.00,0.00,0.00]:[0.56,0.76,0.94]"
  Brown     Translation "0:255=%[0.00,0.00,0.00]:[1.13,0.76,0.38]"
  Cyan      Translation "0:255=%[0.00,0.00,0.00]:[1.13,1.88,1.88]"
  Fireblu   Translation "0:31=%[0.34,0.00,0.00]:[2.00,0.00,0.00]","32:63=%[0.00,0.00,0.34]:[0.00,0.00,2.00]","64:95=%[0.34,0.00,0.00]:[2.00,0.00,0.00]","96:127=%[0.00,0.00,0.34]:[0.00,0.00,2.00]","128:159=%[0.34,0.00,0.00]:[2.00,0.00,0.00]","160:191=%[0.00,0.00,0.34]:[0.00,0.00,2.00]","192:223=%[0.34,0.00,0.00]:[2.00,0.00,0.00]","224:255=%[0.00,0.00,0.34]:[0.00,0.00,2.00]"
  Gray      Translation "0:255=%[0.15,0.15,0.15]:[0.75,0.75,0.75]"

  (01_A, 01_F, 01_CY, 01_BR and 01_KX write the Fireblu string with a space
   after each comma; the values are identical. 01_C, 01_G, 01_B, 01_P, 01_Y,
   01_GY, 01_R and 01_W write it without. Cosmetic whitespace only.)

THE `Common` SUB-VARIANT'S OWN TRANSLATION, which is NOT uniform:
  T00 C   01_C.txt      -- no Translation property at all (inherits CH's)
  T01 G   01_G.txt      -- none (inherits CH GreenZombie's palette remap,
                           CH/decorate/Zombies.txt:896)
  T02 B   01_B.txt      -- none (inherits CH BlueZombie's, Zombies.txt:1040)
  T03 CY  01_CY.txt:15  Translation None   <- explicitly CLEARS CH's
  T04 P   01_P.txt      -- none (inherits CH PurpleZombie's, Zombies.txt:1155)
  T05 Y   01_Y.txt      -- none (inherits CH YellowZombie's, Zombies.txt:1307)
  T06 A   01_A.txt:13   Translation None   <- explicitly CLEARS CH's
  T07 F   01_F.txt:14   Translation None   <- explicitly CLEARS CH's
  T08 BR  01_BR.txt     -- none (CH BrownZombie2 declares none either)
  T09 GY  01_GY.txt:15  Translation None   <- explicitly CLEARS CH's
  T10 R   01_R.txt      -- none (CH RedZombie declares none either)
  T11 K   01_K.txt:10   Translation "0:0=0:0"   <- a one-index no-op that
                           still OVERRIDES CH BlackZombie1's remap
                           (Zombies.txt:1913)
  T12 W   01_W.txt      -- none (inherits CH WhiteZombie1's, Zombies.txt:2307)
  TEX KX  01_KX.txt:14  Translation None   <- explicitly CLEARS CH's
                           (CH BlackZombieEX's is Zombies.txt:1636)

  READ THAT AS: the tiers that say `Translation None` are the tiers where CHP
  shipped BESPOKE ARTWORK and does not want CH's palette remap on top of it.
  That is consistent with our tree's existing TintTable() of all dashes, and
  it is the right call -- tinting bespoke art corrupts it.

SUB-VARIANT ACTOR LINE NUMBERS, per tier file (first line of each ACTOR):

  tier   Green Blue  Purp  Yell  Red   Black White BlkEX WhtEX Abyss Brown Cyan  Fireb Gray
  T00 C    76   153   230   307   384   461   538   615   693   771   855   939  1016  1095
  T01 G    89   179   269   359   449   539   629   719   810   901  1009  1117  1207  1319
  T02 B    80   161   242   323   404   485   566   647   729   811   900   989  1070  1159
  T03 CY   61   122   183   244   305   366   427   488   550   612   680   748   809   872
  T04 P    84   169   254   339   424   509   594   679   765   851   954  1057  1142  1246
  T05 Y    90   186   282   378   474   570   666   762   859   956  1070  1184  1280  1384
  T06 A    71   142   213   284   355   426   497   568   640   710   795   880   951  1039
  T07 F    82   164   246   328   410   492   574   656   739   822   916  1009  1092  1183
  T08 BR  122   244   366   488   610   732   854   976  1099  1222  1345  1468  1590  1714
  T09 GY   85   169   253   337   421   505   589   673   758   843   942  1041  1125  1215
  T10 R    72   150   228   306   384   462   540   618   697   776   857   938  1016  1118
  T11 K   118   238   358   478   598   718   838   958  1079  1200  1342  1480  1604  1768
  T12 W   189   382   575   768   961  1154  1361  1554  1748  1942  2155  2368  2561  2786
  TEX KX  194   388   582   776   970  1164  1358  1552  1747  1942  2154  2362  2560  2812

  Note the diagonal: each tier's own colour appears as a sub-variant of
  itself (CyanCyanZombie, BrownBrownZombie, GrayGrayZombie, ...). Those are
  not special -- they carry the same table entry as any other.

WHAT ELSE VARIES BETWEEN SUB-VARIANTS (spot-checked, not exhaustive):
  Health, Speed, PainChance, per-colour sound suffixes ("/g", "/b", ...), and
  the _<COLOUR> suffix on every projectile class it fires (IceZombieShot_G,
  Orbb11_B, BoneProjZM_KX, ...). The STATE STRUCTURE is the same as Common's
  in every sub-variant I opened. That is what makes this a data axis.


================================================================================
3. EVERY ACS SCRIPT ANY ZOMBIEMAN ACTOR CALLS
================================================================================

Method: grepped every ACS_ and CallACS token in CHP/DECORATE/01/*.txt, in the
CH parent actors, and in every effect actor those reach. SIX scripts. All six
were OPENED and are quoted in full below. Nothing here is called "cosmetic"
on inspection of its name.

--------------------------------------------------------------------------------
3.1  "AnnounceBlackZombie_<colour>"        CHP/source/Bosses.acs:635-733
     called from: 01_K.txt:17   (T11 Scripted)
                  01_KX.txt:22  (TEX Scripted -- calls the _C variant)
     Fifteen near-identical scripts, one per sub-variant colour. Body of the
     _C one, verbatim, Bosses.acs:635-640:

         script "AnnounceBlackZombie_C" (void) {
             SetFont("smallfont");
             SetHudSize(640,480,0);
             Hudmessagebold(s:"\c[ColorC]Player 9 joined the server (black zombie spawned)\c-\c-";
             HUDMSG_FADEINOUT | HUDMSG_LOG | HUDMSG_COLORSTRING, 613, "ColorC", 320.4, 160.0, 3.5, 1.0);
         }

     PURELY COSMETIC. It sets a font, sets a HUD size, and prints one line.
     It touches nothing in the world. The only per-colour difference between
     the fifteen is the colour token and the HUD message id (613, 612, 611...).
     VERDICT: cosmetic. Safe to reproduce as a printed message or to drop.

--------------------------------------------------------------------------------
3.2  "AnnounceWhiteZombie_<colour>"        CHP/source/Bosses.acs:2420-2518
     called from: 01_W.txt:17   (T12 Scripted)
     Body, verbatim, Bosses.acs:2420-2425:

         script "AnnounceWhiteZombie_C" (void) {
             SetFont("smallfont");
             SetHudSize(640,480,0);
             Hudmessagebold(s:"\c[ColorC]Are you ready to roll some bones?\c-";
             HUDMSG_FADEINOUT | HUDMSG_LOG | HUDMSG_COLORSTRING, 2313, "ColorC", 320.4, 152.0, 3.5, 1.0);
         }

     PURELY COSMETIC. Same shape as 3.1.
     VERDICT: cosmetic.

     IMPORTANT: the LINE AFTER this call in 01_W.txt IS NOT COSMETIC.
         01_W.txt:18   MAGE A 0 A_Radiusgive("CHWhitePlan",16383,RGF_NOSIGHT|RGF_MONSTERS)
     That is the map-wide skeleton-hatch mark. It sits inside the same
     `Scripted:` state as the announcement and is trivially easy to drop
     alongside it. It is the single most important line in the tier.

--------------------------------------------------------------------------------
3.3  "EXBOSS"                              CHP/source/Bosses.acs:4331-4337
     called from: 01_KX.txt:23  (TEX Scripted)
     Body, verbatim:

         script "EXBOSS" (void) {
             SetFont("smallfont");
             SetHudSize(480,360,0);
             Hudmessagebold(s:"A chill runs down your spine...";
             HUDMSG_TYPEON, 13, CR_GRAY, 240.4, 35.0, 3.5);
             Radius_quake(1,35,0,1200,0);
         }

     NOT PURELY COSMETIC, and this is exactly the kind of script rs_21:68-73
     warns about. It prints a message AND calls Radius_quake(1, 35, 0, 1200, 0)
     -- intensity 1, 35 tics, damage radius 0, tremor radius 1200 (x64 map
     units), tid 0. Damage radius 0 means it deals NO DAMAGE, but it DOES
     shake the screen of every player in a very large area.
     VERDICT: no gameplay damage, but a real world effect. It is the TEX
     tier's arrival cue and dropping it silently removes the tell. Reproduce
     it as A_Quake, or record the drop -- do not call it "just a message".

--------------------------------------------------------------------------------
3.4  "CH_WZPlan"                           CHP/source/CHSett2.acs:74-77
     called from: WhiteZombiePlan_C, 01_W.txt:8939-8941 -- and therefore from
     EVERY tier of this family, because every tier's Death diverts into a
     Tickles/Tick state that spawns WhiteZombiePlan_C once the Undertaker has
     marked the map.
     Body, verbatim:

         Script "CH_WZPlan" (void)
         {
             SetResultValue(GetCVar("CH_WZPlan"));
         }

     BEHAVIOURAL. It is a one-line CVar read, and its RESULT is a three-way
     gate on whether a corpse hatches a skeleton (01_W.txt:8939-8946):
         == 1  ->  "DoIt"    always hatch
         == 2  ->  "Maybe"   A_Jump(85, "DoIt") -- 85/256, about 33%
         == 3  ->  "Death2"  never hatch
     and if the CVar is anything else it falls through to "Maybe" as well.
     VERDICT: this script decides whether the Undertaker's central mechanic
     happens at all. It is a user setting, not a monster behaviour, so the
     right port is a project CVar or a constant -- but it must be a DECISION
     somebody makes, not a line that disappears.

--------------------------------------------------------------------------------
3.5  "CH_BlackBossy"                       CHP/source/CHSett2.acs:187-190
     called from: CHP/DECORATE/MISC/kw_checks.txt:48  (Actor CommonBlackZombie)
                  CHP/DECORATE/MISC/kw_checks.txt:61  (Actor CommonBlackZombieEX)
     Body, verbatim:

         Script "CH_BlackBossy" (void)
         {
             SetResultValue(GetCVar("CH_BlackBoss"));
         }

     BEHAVIOURAL, but it is on the SPAWN WRAPPER, not on the tier actor.
     kw_checks.txt:43-53, verbatim:

         Actor CommonBlackZombie
         {
             States
             {
             Spawn:
                 TNT1 A 0 Nodelay A_JumpIf(CallACS("CH_BlackBossy") == 1,2)
                 TNT1 A 0 A_SpawnitemEx("CHPZombieSpawnerCustom",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION|SXF_TRANSFERSPECIAL|SXF_TRANSFERAMBUSHFLAG)
                 stop
                 TNT1 A 0 A_SpawnitemEx("CommonBlackZombie1",0,0,0,0,0,0,0,SXF_NOCHECKPOSITION|SXF_TRANSFERSPECIAL|SXF_TRANSFERAMBUSHFLAG)
                 stop
             }
         }

     VERDICT: a user setting that decides whether the T11/TEX boss tiers can
     spawn at all. It is OUTSIDE the tier actor, so it does not affect a port
     of the tiers themselves -- RS owns tier selection. Recorded so nobody
     later finds `CommonBlackZombie` and thinks it is a different monster.

--------------------------------------------------------------------------------
3.6  "CH_ExBoss"                           CHP/source/CHSett2.acs:222-225
     Body, verbatim:

         Script "CH_ExBoss" (void)
         {
             SetResultValue(GetCVar("CH_EXBoss"));
         }

     UNCERTAINTY, REPORTED AS UNCERTAINTY: I could NOT find a CHP-side
     Zombieman actor that calls this. CHP's own wrappers (3.5) use only
     CH_BlackBossy. The caller I DID find is CH's dispatcher:
         CH/decorate/Zombies.txt:1580-1582 (Actor BlackZombie)
             TNT1 A 0 A_JumpIf(CallACS("CH_ExBoss") == 1,"EX1")
             TNT1 A 0 A_JumpIf(CallACS("CH_ExBoss") == 2,"EX2")
             TNT1 A 0 A_JumpIf(CallACS("CH_ExBoss") == 3,"EX3")
     which picks between BlackZombie1 (T11) and BlackZombieEX (TEX) at
     1/8, 1/2 and always respectively (A_jump 232 / 128 / none).
     VERDICT: behavioural in CH, and it is how CH decides T11 vs TEX. Whether
     CHP still routes through it, I could not establish. Listed rather than
     omitted.

--------------------------------------------------------------------------------
NOT CALLED BY ANY Common* ZOMBIEMAN ACTOR, checked and excluded:
  CH_BlackSubtier / CH_WhiteSubtier / CH_AbyssSubtier / CH_CyanSubtier /
  CH_BrownSubtier / CH_FirebluSubtier / CH_GraySubtier / CH_BlackEXSubtier /
  CH_WhiteEXSubtier  -- CHP/DECORATE/MISC/op_s_checks.txt. These belong to the
  SUB-VARIANT spawn axis (section 2), not to any tier we are porting.
  "AnnounceBlackZombie" / "AnnounceWhiteZombie" (no colour suffix) --
  CH/source/Announcers.acs, called only by CH's own actors
  (CH/decorate/Zombies.txt:1661, 1935, 2330). CHP's colour-suffixed scripts
  supersede them.


================================================================================
4. GAPS -- WHAT CHP HAS THAT zscript/monsters/RS_Zombieman.zs DOES NOT
================================================================================

Compared line by line against E:\RS_Main\zscript\monsters\RS_Zombieman.zs
(1263 lines, read in full) and the projectile classes it calls in
zscript/monsters/monsterfx/. Findings are grouped, then listed per tier.
Everything cites a CHP line.

--------------------------------------------------------------------------------
G1. EVERY DAMAGE ROLL IN THE PROJECTILES IS FLATTENED TO A CONSTANT.
    SEVERITY: HIGHEST. This is the exact defect CLAUDE.md names as
    "data loss that hides itself" -- there is no `random(` left for any later
    sweep to find, and no `// CH:` comment recording the original.

    Site by site. LEFT is CHP verbatim; RIGHT is our tree:

      RS_human_projectiles.zs:35  RS_IceZombieShot
        CHP 01_CY.txt:939    Damage (random(6,16))     ours: Damage 11
      RS_human_projectiles.zs:41  RS_Orbb11
        CHP 01_P.txt:1339     Damage (random(2,18))    ours: Damage 10
      RS_human_projectiles.zs:47  RS_MiniRKTZombie
        CHP 01_Y.txt:1487     Damage (random(5,40))    ours: Damage 22
      RS_human_projectiles.zs:52  RS_AbyssZshotCH
        CHP 01_A.txt:1211     Damage (random(5,30))    ours: Damage 17
      RS_human_projectiles.zs:58  RS_AbyssZShotCH3
        CHP 01_A.txt:1591-1598 (inherits random(5,30)) ours: Damage 22
      RS_human_projectiles.zs:216 RS_BoneProjZM
        CHP 01_W.txt:6585     Damage (random(4,16))    ours: Damage 10
      RS_human_projectiles.zs:231 RS_BoneProjZM2
        CHP 01_W.txt:6873     Damage (random(8,20))    ours: Damage 14
      RS_human_projectiles.zs:232 RS_BoneProjZM3
        CHP 01_W.txt:6983     Damage (random(12,26))   ours: Damage 19
      RS_human_projectiles.zs:251 RS_ShoveZM
        CHP 01_W.txt:7095     damage (random(10,45))   ours: Damage 20
      RS_imp_projectiles.zs:224   RS_SplashAbyss2
        CHP 03_A.txt:2092     Damage (random(1,9))     ours: Damage 4  (mean is 5)

    Note RS_ShoveZM: random(10,45) has a mean of 27.5 and our constant is 20.
    Note RS_SplashAbyss2: random(1,9) has a mean of 5 and our constant is 4.
    These are not even mid-points. They are guesses.

    THE FIX IS KNOWN AND WRITTEN DOWN: `DamageFunction (random(a,b))` compiles
    in a ZScript Default block and preserves the spread (CLAUDE.md, and
    RS_PlayerEXBFG at RS_human_projectiles.zs:1133 ALREADY DOES IT
    CORRECTLY -- `DamageFunction (random(100, 200))`). So the pattern is in
    the same file, four hundred lines further down. There is no technical
    obstacle; ten sites were simply missed.

--------------------------------------------------------------------------------
G2. THE UNDERTAKER'S ENTIRE MECHANIC IS ABSENT.
    SEVERITY: HIGHEST. T12 in our tree is a monster that throws bones. In CHP
    it is a monster that turns the whole map into a skeleton farm and levels
    itself up off your kills. Five separate pieces, all missing:

    (a) THE MAP-WIDE MARK.  CHP 01_W.txt:18
            MAGE A 0 A_Radiusgive("CHWhitePlan",16383,RGF_NOSIGHT|RGF_MONSTERS)
        Not present anywhere in RS_Zombieman.zs. Our Spawn.T12
        (RS_Zombieman.zs:944-946) is just A_Look. RS_Zombieman.zs:61-62
        records the CHWhitePlan jumps as "CHP cruft stripped per spec" --
        THAT REASON IS WRONG, and rs_21:100-105 is specifically about this
        class of error. CHWhitePlan is not cruft; it is the trigger.

    (b) THE CORPSE HATCH.  CHP 01_W.txt:8930-8961 (WhiteZombiePlan_C)
        plus every tier's hook: 01_C.txt:34, 01_G.txt:46, 01_B.txt:39,
        01_P.txt:50, 01_Y.txt:66, 01_A.txt:48, 01_F.txt:45, 01_BR.txt:86,
        01_GY.txt:43, 01_R.txt:49.
        TEN of our fourteen Death states drop this jump. No equivalent exists.

    (c) SKELETONS FROM BONES AND BLADES.
            CHP 01_W.txt:6608  MISL D 0 A_Spawnitemex("MrBones_C",...,250)
            CHP 01_W.txt:7126  TNT1 A 0 A_Spawnitemex("MrBones_C",...,128)
        Our RS_BoneProjZM Death (RS_human_projectiles.zs:224-229) ends
        `MISL BCD 3; Stop;` -- no spawn. Our RS_ShoveZM Death
        (RS_human_projectiles.zs:~268) ends `TNT1 A 0 A_Explode(12,64); Stop;`
        -- no spawn.
        RS_MrBones EXISTS (RS_rev_projectiles.zs:733) and is spawned only by
        RS_Archvile, RS_Revenant and RS_MonsterStages. Nothing in the
        Zombieman path spawns it. The actor is built and unwired.

    (d) THE FEEDBACK LOOP.  CHP 01_W.txt:3027-3029 (MrBones_C Death)
            SKLT P 0 A_Radiusgive("Health",528,RGF_MONSTERS,random(12,128),"CommonWhiteZombie1")
            SKLT P 0 A_Radiusgive("BoneUp2_C",528,RGF_MONSTERS,1,"CommonWhiteZombie1")
            SKLT P 12 A_Radiusgive("BoneUp",528,RGF_MONSTERS,1,"CommonWhiteZombie1")
        Our RS_MrBones Death (RS_rev_projectiles.zs:774-779) is
        `A_Scream / A_NoBlocking / A_NoBlocking / SKLT P 12 / Goto Vanish`.
        No heal, no BoneUp, no BoneUp2.
        CONSEQUENCE: OUR LADDER IS DRIVEN BY THE WRONG THING. RS_ClimbLadder
        is called from the Pain dispatcher (RS_Zombieman.zs:277) and
        AddCharge(1) on every hit TAKEN. CHP's BoneUp comes from skeletons
        DYING near it. Those are opposite fictions: in CHP you level the boss
        by clearing its adds; in ours you level it by shooting the boss.

    (e) THE SKELETON'S OWN LIFE CYCLE.  CHP 01_W.txt:3030, 3047-3060
            SKLT Q 450 CanRaise               (it lies there raisable for 450 tics)
            Raise: ... A_JumpIf(user_ILive >=2 ,"Revenante")
            Revenante: ... A_Spawnitemex("CommonCommonRevenant",...)
        A skeleton left alone raises itself twice and the third time becomes a
        REVENANT. Our RS_MrBones has no Raise, no CanRaise, no user_ILive.
        Also missing: `IStuck` / `GiveUp` (CHP 01_W.txt:3004-3009, 3032-3036)
        -- the
        skeleton's A_CheckBlock unstick behaviour and its user_IDie counter.
        Our version has +NOCLIP permanently on (RS_rev_projectiles.zs:748)
        where CHP toggles it off on every walk lap (01_W.txt:2996) and back
        on only when stuck (01_W.txt:3006).

--------------------------------------------------------------------------------
G3. `Pain.AbyssPE` IS DROPPED FROM TEN TIERS.
    SEVERITY: HIGH. CH defines it on every zombie parent; NO CHP tier actor
    redefines it, so all ten inherit it live:
        CH/decorate/Zombies.txt:136 (BrownZombie2), 300 (CyanZombie2),
        414 (FireBluZombie2), 546 (GrayZombie2), 813 (CommonZombie),
        927 (GreenZombie), 1064 (BlueZombie), 1190 (PurpleZombie),
        1363 (YellowZombie), 1507 (RedZombie)
    It is a twelve-frame AYPB transformation that sets +NOPAIN, shrinks the
    actor, plays "AbyssForm", throws ninety SplashAbyss, spawns an
    AbyssZombie2 in its place and A_die's the original. It fires when the
    monster is hurt by DamageType "AbyssPE", which is the Abyss Pain
    Elemental's attack (CH/decorate/thepains.txt:874).
    RS_Zombieman.zs has no Pain.AbyssPE at any tier. Consequence: an Abyss
    Pain Elemental hitting our zombies does nothing special.

--------------------------------------------------------------------------------
G4. T06's SPAWN-TIME ABYSS MARK IS MISSING.
    CHP 01_A.txt:18-19
        Fling:
            ABTR A 0 A_Radiusgive("CHAbyssMark",528,RGF_MONSTERS|RGF_NOSIGHT|RGF_EXFILTER,1,"CommonAbyssZombie","Zombie")
    Spawn falls through into Fling on every abyss zombie, marking every
    Species "Zombie" monster within 528 units (excluding other abyss zombies)
    so that THEIR deaths promote them into abyss zombies
    (the AbyssGrow states, e.g. 01_C.txt:63-69).
    Our tree has NO `Fling` state and no AbyssGrow. RS_Zombieman.zs:62 records
    stripping the AbyssGrow chain deliberately because "RS owns tiering" --
    that reason is DEFENSIBLE for the promotion, but the MARK is also the
    thing that makes an abyss zombie feel like an infection vector, and the
    strip removed both without saying so.

--------------------------------------------------------------------------------
G5. THE TEX TAUNT IS SILENT.
    CHP 01_KX.txt:46-66 plays A_Playsound("HEHEEENH", 0) on EIGHTEEN separate
    frames across the taunt.
    Ours, RS_Zombieman.zs:1111-1131, has the frames and the tics and NOT ONE
    SOUND CALL. The state is nineteen frames of a black silhouette silently
    bobbing. The entire content of the taunt is the laugh.

--------------------------------------------------------------------------------
G6. THE BONE TORNADO IS A FRACTION OF CHP's.
    CHP BoneTorn2_C (01_W.txt:4268-4318) is FIFTY lines: A_Wander laps
    interleaved with SEVEN distinct BoneStormer classes spawned dozens of
    times, plus three A_CustomMissile bursts.
    Ours (RS_human_projectiles.zs:310-333) is a nine-line loop spawning ONE
    class, `RS_BoneStormer`, three times per lap.
    MISSING CLASSES, all real and all distinct:
        BoneStormer1_C  01_W.txt:5080-5108   Speed 120, warp (32,0,32), Jump 8
        BoneStormer2_C  01_W.txt:5410-5421   Speed 105, warp (28,0,28), Jump 4
        BoneStormer3_C  01_W.txt:5605-5616   Speed 115, warp (12,0,10), Jump 4
        BoneStormer4_C  01_W.txt:5800-...
        BoneStormer5_C  01_W.txt:5995-...
        BoneStormer6_C  01_W.txt:6190-...
        BoneStormer7_C  01_W.txt:6385-...
    Each warps to a different radius/height around the master and increments
    its own angle by 8 degrees a tic, so CHP's tornado has seven concentric
    counter-phased rings. Ours has one.
    Also: CHP's BoneStormer carries +Ripper and +FORCEPAIN
    (01_W.txt:5089-5090) and Damage (random(1,3)) at 01_W.txt:5085. Not verified present on ours.

--------------------------------------------------------------------------------
G7. PER-TIER STATE / FRAME / TIC DIFFERENCES.
    Listed by tier. Only genuine mismatches; states our tree omits by an
    explicitly-recorded design decision are marked [BY DESIGN].

  T00 (01_C.txt)
    - `Death.Ice:` label shares the Death block (01_C.txt:31-32). Ours has no
      Death.Ice at any tier. Without it, an ice kill uses the engine's generic
      freeze-shatter rather than CHP's chosen corpse.
    - Missing states: Tick (01_C.txt:28-30) [see G2b],
      Grow (01_C.txt:58-62) [BY DESIGN, RS_Zombieman.zs:62],
      AbyssGrow (01_C.txt:63-69) [BY DESIGN],
      Death.Nocorpse (01_C.txt:70-72) [dependent on Grow; drops with it].
    - Puff class: CHP fires "BulletPuff_C" (01_C.txt:25); ours fires stock
      "BulletPuff" (RS_Zombieman.zs:293). BulletPuff_C is an empty subclass
      (01_C.txt:1173-1175) so this is currently harmless -- but it is the
      hook the sub-variant colour axis (section 2) will need.

  T01 (01_G.txt)
    - XDeath tail: CHP uses ZOMG U on its last three lines (01_G.txt:62-64);
      ours substitutes ZOMG T (RS_Zombieman.zs:360-362).
      VERIFIED CORRECT: sprites/monsters/Zombieman/T01/ contains ZOMG A..T
      and no U. Our honest-omission note (RS_Zombieman.zs:68-69) is accurate.
      Recording the verification so it is not re-litigated.
    - Missing: Grow (01_G.txt:71-75) [BY DESIGN],
      AbyssGrow (01_G.txt:76-82) [BY DESIGN],
      Death.Nocorpse (01_G.txt:83-85).
    - The gas projectile is materially weaker than CHP's -- see G8.

  T02 (01_B.txt)
    - XDeath drops CHP's leading `ZOMB M 0` frame (01_B.txt:47). Zero tics, so
      invisible; a token drop, not a behaviour drop.
    - Missing: Grow (01_B.txt:62-66) [BY DESIGN], AbyssGrow (67-73) [BY DESIGN],
      Death.Nocorpse (74-76).

  T03 (01_CY.txt)
    - WRONG FRAME. CHP's shatter is `MISL A 0` twice (01_CY.txt:55-56);
      ours is `MISL X 0` twice (RS_Zombieman.zs:440-441). Both are 0-tic, so
      nothing renders -- but MISL X is a token our tree does not otherwise
      use at T03 and the correct token is A.
    - Correctly ported: no XDeath, no Raise. CH CyanZombie2 defines neither
      (verified: its only state labels are Spawn/See/See2/Missile/
      Pain.AbyssPE/Pain/Death, CH/decorate/Zombies.txt:282-321).

  T04 (01_P.txt)
    - Missing AbyssGrow (01_P.txt:69-75) [BY DESIGN].
    - Death hook uses amount 1 in CHP (01_P.txt:50); dropped [G2b].

  T05 (01_Y.txt)
    - CHP's Death uses `A_Fall` (01_Y.txt:68) and XDeath uses `A_Fall`
      (01_Y.txt:78); ours uses A_NoBlocking. These are the same function in
      ZScript. Not a defect; recorded so a diff reader does not flag it.
    - Missing nothing else. This tier is the closest match in the family.

  T06 (01_A.txt)
    - Missing `Fling` state -- see G4. CHP 01_A.txt:18-19.
    - RS_SplashAbyss2's damage roll flattened -- see G1.

  T07 (01_F.txt)
    - CHP's Melee uses the action special `DamageThing(9999)` (01_F.txt:36);
      ours uses A_DamageSelf(9999) (RS_Zombieman.zs:628). Equivalent effect.
    - `ZOMF U` at 01_F.txt:69-70: VERIFIED PRESENT. sprites/monsters/
      Zombieman/T07/ has ZOMF A..T plus U, X, Y, Z. Ours is correct.
    - Missing: AbyssGrow (01_F.txt:55-61) [BY DESIGN], Grow (77-78 -- CHP's
      is an empty `Stop`, so nothing is lost).
    - The fire cloud is weaker than it should be only if measured against CH;
      against CHP ours is close. See G8.

  T08 (01_BR.txt)
    - `Goto See+3` targets verified: CHP's See block expands to
      [B][C][jump][D][E][jump][checklof], so See+3 is `SGAR D`. Our
      See.T08.Half starts at SGAR D (RS_Zombieman.zs:667). CORRECT.
    - Missing AbyssGrow (01_BR.txt:107-113) [BY DESIGN].
    - CH's parent gives +ROLLSPRITE (CH/decorate/Zombies.txt:57); ours sets
      bROLLSPRITE in OnTierApplied (RS_Zombieman.zs:240). CORRECT.
    - CHP's See uses tic 5 on both SGAR BC and SGAR DE (01_BR.txt:24,26)
      where CH's parent uses 6 (CH/decorate/Zombies.txt:76,83). Ours uses 5.
      CHP wins. CORRECT.

  T09 (01_GY.txt)
    - CHP's Missile tail is `SHDT FEEEE 2` (01_GY.txt:31) -- five frames at
      2 tics. CH's parent instead has `SHDT F 2 / SHDT E 8`
      (CH/decorate/Zombies.txt:543-544). Ours matches CHP. CORRECT.
    - Missing AbyssGrow (01_GY.txt:69-75) [BY DESIGN], Grow (80-81, empty).

  T10 (01_R.txt)
    - Missing the RandomLetterSpawner_C on Death and XDeath
      (01_R.txt:53, 63) [BY DESIGN, RS_Zombieman.zs:63]. Note this makes our
      T10 equivalent to CHP's OWN `CommonRedZombie2` (01_R.txt:1197-1222),
      which is the same actor with those two lines removed. Worth saying out
      loud: the strip landed on a variant CHP itself ships.
    - CHP's Missile2 loop target is `Missile2+1` (01_R.txt:38), i.e. it skips
      the 16-tic charge on every repeat. Ours loops to
      Missile.T10.RailLoop (RS_Zombieman.zs:823), which is the first
      A_StartSound line -- the same position. CORRECT.

  T11 (01_K.txt)
    - Correct throughout, including the deliberate omission of the two
      unreachable lines at 01_K.txt:76-77.
    - Missing: nothing structural. Confirmed no Raise exists in CHP or CH.

  T12 (01_W.txt) -- see G2 and G6 for the substantive gaps. Additionally:
    - Buff numbers diverge. CHP sets ABSOLUTE values:
        Buff1  A_Setspeed(16)  A_SetScale(1.1,1.1)    01_W.txt:124-125
        Buff2  A_Setspeed(21)  A_SetScale(1.25,1.25)  01_W.txt:134-135
        Buff3  A_Setspeed(28)  A_SetScale(1.45,1.45)  01_W.txt:145,147
      Ours multiplies cumulatively (RS_Zombieman.zs:181-201): from base
      Speed 10 that gives 13 / 16.25 / 19.5 against CHP's 16 / 21 / 28, and
      scale 1.08 / 1.188 / 1.331 against CHP's 1.1 / 1.25 / 1.45. The final
      form is 30% slower than CHP's.
    - Buff3's frame timing differs. CHP: `MAGE E 1 A_Setspeed(28)` then
      `MAGE E 7` then SetScale then `MAGE E 12` (01_W.txt:145-148). CH's
      parent uses `MAGE E 8 A_Setspeed(28)` (CH/decorate/Zombies.txt:2456).
      Ours has no frames at all -- the buff is a function call from Pain.
    - Missing the icon swap on each buff (01_W.txt:118, 129, 139:
      NewIconCHP11_T2/T3/T4) [BY DESIGN, RS_Zombieman.zs:59].
    - Missing `A_GivetoChildren("GoAway",1)` at the head of each Buff
      (01_W.txt:117, 128, 138) [BY DESIGN].
    - Missing the `Reset` state (01_W.txt:113-115). Ours guards with
      `rsStep < n` instead, which is equivalent. CORRECT.

  TEX (01_KX.txt) -- see G5. Additionally:
    - CHP's Spawn spawns TWO icons (01_KX.txt:18-19) [BY DESIGN].
    - Everything else matches, including the hop-before-SSG, both barrage
      directions, all four BFG entry points, and the corpse checks.

--------------------------------------------------------------------------------
G8. PROJECTILE BODIES THAT DIVERGE BEYOND THE DAMAGE ROLL.

  RS_Gas11 (RS_human_projectiles.zs:29-34) vs Gas11_C (01_G.txt:1410-1421):
      CHP  Spawn: PSBG CDE 3 Bright / Goto Death
           Death: PSBG FGHI 6 Bright A_Explode(random(1,8),32)
                  -- FOUR frames, four firings, 4 x random(1,8) = 4..32
      ours Spawn: PSBG CDE 4 Bright; Loop;
           Death: PSBG E 4 Bright A_Explode(24,48,...); PSBG FG 4 Bright;
                  -- ONE firing of a flat 24, radius 48
      Three differences at once: the tic count (3 -> 4), the frame set
      (FGHI -> E,FG), and the multi-firing collapsed to a single hit. Note
      also that ours LOOPS the spawn where CHP falls straight into Death, so
      ours is a persistent cloud and CHP's is a 9-tic fuse. Both are
      "lingering gas" but they are not the same object.
      This is the deliberate-multi-frame case from
      `project_rs_multiframe_explode` -- collapsing it was the wrong call here.

  RS_IceZombieShot (RS_human_projectiles.zs:35-39) vs 01_CY.txt:934-957:
      CHP  Spawn ICEY ABC 3 Bright / Death ICEY FGHI 5 Bright, no A_Explode
           at all. xScale 1.15, yScale 0.15 -- the flat-sliver look.
      ours Spawn ICEY AB 3 / Death ICEY C 4 A_Explode(33,40) + ICEY FG 4
           and NO xScale/yScale.
      We ADDED a 33-damage splash CHP does not have, dropped a frame from
      each state, and lost the shape that makes the shard readable.

  RS_Orbb11 (RS_human_projectiles.zs:41-46) vs 01_P.txt:1332-1360:
      CHP  A_Seekermissile(2,3) on frame A and A_weave(5,4,2,1) on frame B --
           two different actions on alternating frames.
      ours A_SeekerMissile(2,2) on BOTH frames; no A_weave at all.
      The corkscrew is gone and the seek threshold is wrong.
      We also added A_Explode(30,40) which CHP does not have, and Scale is
      0.7 against CHP's 0.3.

  RS_MiniRKTZombie (RS_human_projectiles.zs:47-51) vs 01_Y.txt:1481-1507:
      CHP  A_Explode(random(5,15), 58).   ours A_Explode(120, 80).
      Our splash is EIGHT TIMES CHP's mean and the radius is 38% wider.
      Also missing +DEHEXPLOSION (01_Y.txt:1491).

  RS_AbyssZshotCH (RS_human_projectiles.zs:52-56) vs 01_A.txt:1208-1228:
      CHP  Death: TNT1 A 0 A_setscale(0.85) / BAL7 CDE 4 Bright
                  A_Explode(random(1,8),42)  -- THREE firings.
           Spawn: BAL1 A 2 / BAL1 B 2 a_weave(2,1,2,0.1)
      ours Death: BAL7 C 4 A_Explode(51,48) / BAL7 DE 4  -- ONE firing of 51.
           Spawn: BAL7 AB 3, no weave, and the WRONG SPRITE (BAL7 in flight
           where CHP uses BAL1 and reserves BAL7 for the impact).
      Three defects: wrong flight sprite, missing weave, collapsed explode.

  RS_BoneProjZM (RS_human_projectiles.zs:216-230) vs 01_W.txt:6580-6610:
      Missing the MrBones spawn (G2c) and the four DropItem lines
      (01_W.txt:6595-6598: implyingclip 48, CH_Shell 32, CH_Cell 16,
      CH_RocketAmmo 8) -- CHP's bones DROP AMMO where they land. Ours do not.

  RS_ShoveZM (RS_human_projectiles.zs:251-272) vs 01_W.txt:7091-7129:
      CHP  twelve A_CustomMissile lines in Spawn, including four that fire
           BACKWARD at random(-190,-175) with pitch offsets +-6 and +-3
           (01_W.txt:7117-7120). Death ends
           `FBL1 EFG 1 bright A_Explode(random(5,20),64)` (01_W.txt:7125)
           -- THREE firings --
           and then spawns MrBones at failchance 128.
      ours seven A_SpawnProjectile lines, no backward fan, and Death ends
           `TNT1 A 0 A_Explode(12,64)` -- ONE firing of a flat 12 -- with no
           MrBones. The file comment at RS_human_projectiles.zs:248-249 says
           "kept, at reduced count", which is honest, but the missing
           backward spray and the missing summon are not mentioned.

  RS_Rocket (RS_human_projectiles.zs:620-635) vs 17_C.txt:965-989: MATCHES,
      including the bare A_Explode(). Recorded as verified-correct.

  RS_PlayerEXBFG (RS_human_projectiles.zs:1133-1159) vs 01_KX.txt:3007-3035:
      MATCHES, including DamageFunction (random(100,200)), the 29 shrapnel
      spawns, and A_Explode(random(45,125),156). This is the one projectile
      in the family that was ported to the standard rs_21 asks for, and it
      is the proof that the standard is achievable in this file.

--------------------------------------------------------------------------------
G9. NOTHING IN THIS FAMILY IS ROUTED THROUGH RS_AttackProfile.
    All thirty attacks fire inline from state code via A_SpawnProjectile /
    A_CustomBulletAttack / A_CustomRailgun / A_CustomMeleeAttack.
    RS_Zombieman.zs has no BuildTierAttacks override and no attack slot.
    That is exactly the 0.7% measurement in rs_21:180-188, and it means no
    Zombieman attack can currently be reassigned to anything, which is the
    entire point of cataloguing them.
    Section 5 of docs/monsters/Zombieman.md gives a `profile:` line for every
    one of the thirty, plus an explicit note wherever the profile system as
    it stands cannot express the attack (staggered volleys, widening cones,
    wind-ups, railgun pierce, and movement-during-fire).

--------------------------------------------------------------------------------
G10. FILE LAYOUT DOES NOT MATCH rs_21 SECTION 3.
     Required:   zscript/monsters/Zombieman/RS_Zombieman.zs
                 zscript/monsters/Zombieman/attacks/RS_Zombieman_<Attack>.zs
                 zscript/monsters/Zombieman/README.txt
     Actual:     zscript/monsters/RS_Zombieman.zs
                 zscript/monsters/monsterfx/RS_human_projectiles.zs   (shared)
                 zscript/monsters/monsterfx/RS_baron_projectiles.zs   (ZombieRock)
                 zscript/monsters/monsterfx/RS_imp_projectiles.zs     (SplashAbyss)
                 zscript/monsters/monsterfx/RS_hk_projectiles.zs      (HKRedDeath,
                                                                       HomingRocketTrailFatso)
                 zscript/monsters/monsterfx/RS_rev_projectiles.zs     (MrBones)
                 zscript/monsters/monsterfx/RS_archvile_projectiles.zs(FireSGguy2)
                 zscript/monsters/monsterfx/RS_spidermind_projectiles.zs(PlasmaBallSP3)
     Zombieman's own attack actors are scattered across SIX files named for
     other families. Note also that RS_ZombieRock lives in
     RS_baron_projectiles.zs -- named for a family that does not use it.
     Recorded, not acted on: CLAUDE.md's "correct a body in place; don't move
     a definition between files" makes relocating these a decision the owner
     should make deliberately, not a side effect of a documentation pass.

--------------------------------------------------------------------------------
G11. RS_Zombieman.zs's OWN HEADER CONTAINS TWO CLAIMS THAT ARE NOT TRUE.
     Recording these because a wrong reason is more expensive than a missing
     feature (rs_21:100-105), and both of these will mislead the next reader.

     (a) RS_Zombieman.zs:61-62 lists "the CHBoner / CHWhitePlan / GrowRaisin
         inventory jumps" among "CHP cruft stripped per spec". CHWhitePlan is
         not cruft. It is the Undertaker's map-wide skeleton mechanic (G2).
     (b) RS_Zombieman.zs:71-72 says per-tier BloodColor and GibHealth "are
         CH/CHP actor properties with no safe runtime setter here". GibHealth
         IS a settable actor property, and CHP sets it explicitly on four
         tiers: 01_A.txt:4 (-100), 01_F.txt:4 (-5), 01_R.txt:4 (-100),
         01_K.txt:4 / 01_W.txt:4 / 01_KX.txt:4 (-500). The fireblu tier's
         GibHealth -5 is load-bearing -- it is why almost any weapon overkills
         it into its own explosion.

================================================================================
5. COUNTS
================================================================================

  tiers in CHP for family 01 ............ 14   (T00-T12 + TEX-K)
  tiers that do NOT exist ................ 1   (TEX-W / WX -- stubbed to Nothin)
  Common* actors read in full ........... 14
  sub-variant actors listed ............ 196   (14 per tier x 14 tiers)
  distinct Translation strings ........... 14   (one family-wide table)
  distinct attacks catalogued ............ 30
  ACS scripts opened and quoted ........... 6
  projectile / effect actors opened ...... 21
  gap groups .............................. 11
  individual flattened damage rolls ...... 10

================================================================================
