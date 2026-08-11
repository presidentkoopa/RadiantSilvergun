BESTIARY â€” PAYLOAD SPAWN TABLE FOR PACK AFFIXES
Compiled from the 7-chunk census plus direct scans of the families the census chunks did not carry in full (revenant, archvile, painelemental, fatso, spider, cyberdemon, mastermind, baron rows). All path:line cites verified against E:/RS_Main.

Headline conclusions:
- 122 concrete monster classes inventoried; **97 are summon-safe** and listed in Section 1.
- Two whole families are structurally excluded: **every cyberdemon variant carries +BOSS** (even RS_CommonCybie, RS_Cyberdemon.zs:1103) and **every mastermind variant carries +BOSS** (RS_GreenMind at RS_Mastermind.zs:1444, family-wide). "2x cyberdemons" is illegal by flag, not just by cost.
- **Pain elementals are excluded family-wide**: every tier's Missile state IS A_PainAttack. **Archviles are excluded family-wide** for a worse reason: raised monsters bypass the summon marker and keep paying rewards â€” a player-owned vile is a reward-duplication engine (RS_SummonMark.zs:80-83).
- The canonical affix "cluster grenade spawning 2x skeletons" costs **30** (2x RS_CommonRevenant @ 15). Budget your grenade tier accordingly.

---

## 1. THE TABLE â€” summon-safe payload roster, sorted by cost

Weight = colourset DropItem weight (0 = not on any dial; reachable but valid to spawn directly). Fly = FLOAT+NOGRAVITY.

| Cost | Class | Family | HP | Wt | Fly | Note |
|---|---|---|---|---|---|---|
| 1 | RS_BlackLSoul2 | lostsoul | 18 | 0 | Y | Only truly -COUNTKILL body (RS_LostSoul.zs:1614). Cheapest legal filler. |
| 2 | RS_CommonZombie | zombieman | 20 | 540 | - | The anchor. |
| 3 | RS_CyanZombie2 | zombieman | 30 | 100 | - | Ice shots. |
| 3 | RS_GreenZombie | zombieman | 40 | 320 | - | |
| 3 | RS_CommonSG | shotgunner | 30 | 600 | - | |
| 4 | RS_BlueZombie | zombieman | 60 | 220 | - | |
| 4 | RS_GreenSG | shotgunner | 45 | 300 | - | |
| 4 | RS_CommonCGuy | chaingunner | 70 | 640 | - | |
| 4 | RS_CommonLSoul | lostsoul | 100 | 429 | Y | +COUNTKILL (re-declared Monster, RS_LostSoul.zs:779) â€” see contract step 8. |
| 5 | RS_CommonImp | imp | 60 | 630 | - | |
| 5 | RS_BrownZombie2 | zombieman | 100 | 100 | - | Bodyguard AI. |
| 5 | RS_BlueSG | shotgunner | 55 | 280 | - | |
| 5 | RS_GreenCGuy | chaingunner | 85 | 460 | - | |
| 5 | RS_GreenLSoul | lostsoul | 120 | 320 | Y | Poison on melee/death. |
| 5 | RS_CyanLSoul2 | lostsoul | 80 | 60 | Y | |
| 6 | RS_GreenImp | imp | 70 | 360 | - | |
| 6 | RS_PurpleZombie | zombieman | 95 | 80 | - | |
| 6 | RS_FireBluZombie2 | zombieman | 70 | 50 | - | Kamikaze â€” thematic grenade payload. |
| 6 | RS_GrayZombie2 | zombieman | 110 | 60 | - | |
| 6 | RS_PurpleSG | shotgunner | 75 | 60 | - | |
| 6 | RS_BlueCGuy | chaingunner | 105 | 200 | - | |
| 6 | RS_BlueLSoul | lostsoul | 145 | 175 | Y | |
| 6 | RS_WHOLETTHEDOGSOUT | demon | 120 | 0 | - | Butcher's hound, standalone-clean (RS_Demon.zs:1769). |
| 7 | RS_BlueImp | imp | 83 | 180 | - | |
| 7 | RS_YellowSG | shotgunner | 85 | 60 | - | |
| 7 | RS_PurpleLSoul | lostsoul | 150 | 50 | Y | |
| 8 | RS_CommonDemon | demon | 150 | 500 | - | Demon anchor. |
| 8 | RS_CommonSpectre | spectre | 150 | 510 | - | |
| 8 | RS_PurpleImp | imp | 105 | 115 | - | Bouncing shots. |
| 8 | RS_YellowZombie | zombieman | 140 | 60 | - | Rockets, capped at 3. |
| 8 | RS_GraySG2 | shotgunner | 155 | 60 | - | |
| 8 | RS_PurpleCGuy | chaingunner | 120 | 100 | - | Grenadier. |
| 8 | RS_CyanCGuy2 | chaingunner | 125 | 130 | - | |
| 8 | RS_FireBluLSoul2 | lostsoul | 175 | 50 | Y | Suicide bomber â€” self-cleaning payload (RS_LostSoul.zs:743-746). |
| 8 | RS_BrownLSoul2 | lostsoul | 125 | 120 | Y | Support cube; hands out RS_CHBoner on melee-death. |
| 9 | RS_GreenDemon | demon | 170 | 400 | - | |
| 9 | RS_GreenSpectre | spectre | 175 | 400 | - | |
| 9 | RS_RedSG | shotgunner | 150 | 33 | - | |
| 9 | RS_BrownSG2 | shotgunner | 155 | 40 | - | |
| 9 | RS_SlimyWorm | chaingunner | 250 | 0 | - | Declips on first See tic â€” validate placement (RS_ChaingunnerFX.zs:1244). |
| 10 | RS_BlueDemon | demon | 205 | 180 | - | |
| 10 | RS_RedZombie | zombieman | 186 | 26 | - | Death nova. |
| 10 | RS_BrownCGuy2 | chaingunner | 250 | 35 | - | Deploys cover. |
| 10 | RS_YellowImp | imp | 145 | 100 | - | Fire area denial. |
| 10 | RS_FireBluImp2 | imp | 125 | 75 | - | |
| 10 | RS_RedLSoul | lostsoul | 240 | 20 | Y | |
| 11 | RS_BlueSpectre | spectre | 210 | 155 | - | |
| 11 | RS_YellowCGuy | chaingunner | 200 | 60 | - | Plasma storms. |
| 11 | RS_FireBluSG2 | shotgunner | 225 | 43 | - | |
| 12 | RS_CommonCaco | cacodemon | 400 | 700 | Y | Caco anchor. |
| 12 | RS_PurpleDemon | demon | 260 | 100 | - | |
| 12 | RS_PurpleSpectre | spectre | 250 | 100 | - | |
| 12 | RS_FireBluDemon2 | demon | 205 | 70 | - | Fire-immune rusher. |
| 12 | RS_CyanImp2 | imp | 125 | 120 | - | Frost spam. |
| 12 | RS_GrayCGuy2 | chaingunner | 275 | 35 | - | |
| 12 | RS_Wakawaka | spectre | 320 | 0 | - | White slug's chomper, standalone-clean (RS_SpectreFX.zs:514). |
| 13 | RS_RedImp | imp | 200 | 55 | - | Death nova â€” friendly-fire hazard near owner. |
| 13 | RS_RedCGuy | chaingunner | 300 | 35 | - | |
| 13 | RS_FireBluSpectre2 | spectre | 205 | 70 | - | |
| 13 | RS_BlackSG2 | shotgunner | 280 | 0 | - | Spec-ops trooper, no boss flag (RS_Shotgunner.zs:1679). |
| 14 | RS_AbyssSG2 | shotgunner | 300 | 50 | - | Conversion product, not vector (no RadiusGive â€” grep negative). |
| 14 | RS_BrownImp2 | imp | 215 | 65 | - | Parry + pack war-cry. |
| 14 | RS_GreenCaco | cacodemon | 450 | 400 | Y | |
| 14 | RS_AbyssLSoul2 | lostsoul | 380 | 40 | Y | Grounds itself on See (RS_LostSoul.zs:464-465). |
| 15 | **RS_CommonRevenant** | revenant | 300 | 500 | - | **The skeleton.** RS_Revenant.zs:880, Health 300 (:889). |
| 15 | RS_GrayImp2 | imp | 265 | 65 | - | |
| 15 | RS_BlueCaco | cacodemon | 480 | 200 | Y | |
| 15 | RS_YellowDemon | demon | 325 | 55 | - | |
| 15 | RS_YellowSpectre | spectre | 320 | 40 | - | |
| 15 | RS_ShotgunShrine | shotgunner | 800 | 0 | - | Static turret; +NOCLIP, mandatory placement validation. |
| 16 | RS_GreenRevenant | revenant | 360 | 360 | - | RS_Revenant.zs:1012. |
| 16 | RS_AbyssImp2 | imp | 300 | 75 | - | |
| 16 | RS_BrownCaco2 | cacodemon | 500 | 130 | Y | Pack healer â€” price up in mixed packs. |
| 16 | RS_CyanDemon2 | demon | 270 | 120 | - | |
| 16 | RS_CyanSpectre2 | spectre | 270 | 100 | - | |
| 16 | RS_FireBluCGuy2 | chaingunner | 450 | 20 | - | Speed 18. |
| 17 | RS_BlueRevenant | revenant | 420 | 150 | - | RS_Revenant.zs:1150. |
| 17 | RS_PurpleCaco | cacodemon | 528 | 60 | Y | |
| 17 | RS_PinkDemon | demon | 500 | 0 | - | Orphan; strip its 4x-backpack drops (RS_Demon.zs:68-76). |
| 18 | RS_CommonSP1 | spider | 500 | 449 | - | Arachnotron anchor (RS_Spider.zs:213). MAP07 note below. |
| 18 | RS_AbyssCGuy2 | chaingunner | 500 | 30 | - | |
| 18 | RS_CyanCaco2 | cacodemon | 500 | 100 | Y | |
| 18 | RS_CyanRevenant2 | revenant | 480 | 120 | - | RS_Revenant.zs:342. |
| 18 | RS_RedDemon | demon | 400 | 40 | - | |
| 18 | RS_BrownDemon2 | demon | 420 | 100 | - | |
| 18 | RS_RedSpectre | spectre | 394 | 33 | - | |
| 19 | RS_PurpleRevenant | revenant | 515 | 75 | - | RS_Revenant.zs:1313. |
| 19 | RS_CommonFatso | fatso | 600 | 400 | - | Inherits Fatso; A_BossDeath at RS_Fatso.zs:945 â€” MAP07 note. |
| 19 | RS_GreenSP1 | spider | 600 | 235 | - | RS_Spider.zs:319. |
| 19 | RS_BrownSP2 | spider | 600 | 60 | - | :931. |
| 19 | RS_GraySP2 | spider | 600 | 45 | - | :1349. |
| 20 | RS_CommonHK | hellknight | 500 | 500 | - | Hellknight anchor. |
| 20 | RS_GrayCaco2 | cacodemon | 650 | 60 | Y | |
| 20 | RS_BrownSpectre2 | spectre | 300 | 100 | - | Priced as pack-support. |
| 20 | RS_GraySpectre2 | spectre | 450 | 45 | - | |
| 21 | RS_GreenFatso | fatso | 750 | 220 | - | RS_Fatso.zs:1000. |
| 21 | RS_CyanFatso2 | fatso | 720 | 90 | - | :383. |
| 21 | RS_BlueSP1 | spider | 700 | 155 | - | :435. |
| 22 | RS_GreenHK | hellknight | 600 | 400 | - | |
| 22 | RS_YellowCaco | cacodemon | 720 | 40 | Y | Void fields. |
| 22 | RS_AbyssDemon2 | demon | 600 | 40 | - | Near-invisible; no self-replication. |
| 22 | RS_BrownRevenant2 | revenant | 666 | 100 | - | RS_Revenant.zs:224. |
| 22 | RS_GrayRevenant2 | revenant | 660 | 100 | - | :765. |
| 22 | RS_CyanSP2 | spider | 777 | 90 | - | :1078. |
| 23 | RS_BlueHK | hellknight | 666 | 150 | - | |
| 23 | RS_FireBluRevenant2 | revenant | 720 | 50 | - | :619. |
| 23 | RS_BlueFatso | fatso | 850 | 130 | - | :1117. |
| 23 | RS_BrownFatso2 | fatso | 850 | 60 | - | :244. |
| 23 | RS_PurpleSP1 | spider | 800 | 65 | - | :550. |
| 23 | RS_YellowSP1 | spider | 777 | 30 | - | :671. |
| 24 | RS_FireBluCaco2 | cacodemon | 800 | 35 | Y | |
| 25 | RS_PurpleHK | hellknight | 730 | 75 | - | |
| 25 | RS_GreyDemon2 | demon | 700 | 45 | - | |
| 25 | RS_PurpleFatso | fatso | 950 | 50 | - | :1252. |
| 26 | RS_RedCaco | cacodemon | 830 | 40 | Y | |
| 26 | RS_RedRevenant | revenant | 830 | 21 | - | :1797. Safe: only abyss-hook (:1889). |
| 26 | RS_GrayFatso2 | fatso | 1000 | 33 | - | :766. |
| 27 | RS_BrownHK2 | hellknight | 700 | 120 | - | |
| 27 | RS_CyanHK2 | hellknight | 700 | 120 | - | |
| 27 | RS_RedSP1 | spider | 1000 | 25 | - | :807. |
| 28 | RS_CommonBaron | baron | 1000 | 500 | - | Baron anchor (RS_Baron.zs:1105). BOSSDEATH note. |
| 28 | RS_SpliceBaron | chaingunner | 1000 | 0 | - | PainChance 0; declip quirk. |
| 28 | RS_AbyssRevenant2 | revenant | 1000 | 30 | - | RS_Revenant.zs:480. |
| 30 | RS_GreenBaron | baron | 1170 | 400 | - | :1210. |
| 30 | RS_YellowHK | hellknight | 999 | 50 | - | |
| 30 | RS_GrayHK2 | hellknight | 800 | 75 | - | PainChance 16. |
| 30 | RS_YellowFatso | fatso | 1250 | 30 | - | :1373. |
| 32 | RS_BlueBaron | baron | 1309 | 220 | - | :1343. |
| 32 | RS_FireBluHK2 | hellknight | 900 | 20 | - | |
| 32 | RS_AbyssCaco2 | cacodemon | 1100 | 40 | Y | |
| 32 | RS_FireBluFatso2 | fatso | 1400 | 20 | - | :635. |
| 34 | RS_PurpleBaron | baron | 1500 | 145 | - | :1464. |
| 35 | RS_CyanBaron2 | baron | 1666 | 135 | - | :366. |
| 35 | RS_RedFatso | fatso | 1600 | 15 | - | :1513. No boss flag. |
| 38 | RS_YellowBaron | baron | 1888 | 50 | - | :1605. |
| 38 | RS_AbyssSP2 | spider | 1850 | 45 | - | :1506. |
| 40 | RS_GrayBaron2 | baron | 2000 | 35 | - | :827. |
| 40 | RS_AbyssFatso2 | fatso | 2150 | 35 | - | :538. |
| 40 | RS_RedBaron1 | baron | 2000 | ~0 | - | Only reachable when rs_ch_nerfredboss is off; spawn directly. :1761. |
| 42 | RS_BrownBaron2 | baron | 2250 | 80 | - | :232. |
| 42 | RS_FireBluBaron2 | baron | 2300 | 35 | - | :973. |
| 45 | RS_AbyssHK2 | hellknight | 1850 | 0 | - | The archvile-priced elite single. |
| 50 | RS_AbyssBaron2 | baron | 3333 | 40 | - | :635. Ceiling of the safe roster. |

Family-wide caveats on this table:
- **MAP07/E1M8 specials**: the whole fatso family calls A_BossDeath on death (RS_Fatso.zs:360, 520, 945, 1076...), the whole spider family carries +BOSSDEATH (RS_Spider.zs:328, 444, 558...), and BaronOfHell-derived tiers keep +BOSSDEATH and call A_BossDeath (RS_Baron.zs:1178, 1312, 1433). A live summoned body of those classes delays tag-666/667 specials, and one dying last can trigger them. The generator should either exclude these three families on maps using those specials or accept the interaction.
- All non-boss tiers in most families carry the four dormant, externally-triggered hooks (Pain.AbyssPE transform, RS_CHAbyssMark death-growth, RS_CHBoner egg, Grow-on-raise) â€” harmless in a payload until the trigger actor exists, but headcount/marking must survive the A_Die-plus-replacement pattern (e.g. RS_Chaingunner.zs:284-290; the replacement spawns after maptime 0, so RS_SummonMarker re-marks it).
- DropItem loot fires on death regardless of PaysRewards â€” see Gap 4.

Unknown / special-purpose (not in the table, not condemned): RS_MrBones (spawn +NOCLIP never verified to declip, RS_Zombieman.zs:2282; vile-raise metamorphosis to RS_CommonRevenant is live, :2358-2362), RS_ShotgunShrine already listed with its caveat, and the unresolved question of what gives RS_CHAbyssMark to shotgunner/chaingunner victims (not located anywhere; only the zombie-species RadiusGive at RS_Zombieman.zs:863 is proven).

---

## 2. THE UNSAFE LIST

**By reason, so the generator can encode the rule, not the list.**

**A. +BOSS flag (and usually boss loot / map-special deaths).** Never payload-legal:
- Entire cyberdemon family â€” every tier including Common: RS_Cyberdemon.zs:1103 (+BOSS on RS_CommonCybie), :1202, :1292, :1473, :1630, :1768, :2078, :2417. Healths 4000-21000.
- Entire mastermind family â€” RS_Mastermind.zs:1444 (GreenMind), :1567, :1740, :1900, :2101, :2356; BrownMind2 :465, CyanMind2 :689, AbyssMind2 :890, GrayMind2 :1154, FireBluMind2 :1320. Healths 4200-12222+. Purple/Yellow also summon (SpecialSpider1s :1772-1775, YellowSP1s :1966-1969).
- All Black/White tiers of every other family (census: RS_BlackZombie1, RS_BlackZombieEX, RS_WhiteZombie1, RS_BlackSG3, RS_WhiteSG2 (+BOSSDEATH â€” fires map specials, RS_Shotgunner.zs:1946), RS_WhiteSGEX, RS_BlackCGuyEX, RS_BlackCGuy2, RS_WhiteCguy2, RS_BlackImp1, RS_BlackImpEX, RS_WhiteImp2, RS_BlackCaco2, RS_BlackCacoEX, RS_WhiteCaco2/REAL, RS_BlackDemon3, RS_WhiteDemon2, RS_BlackSpectre2, RS_WhiteSpectre2, RS_BlackLSoul3, RS_BlackLSoulOld3, RS_WhiteLSoul2/EX, RS_BlackHK2, RS_BlackHKEX, RS_WhiteHK3 (twin-spawns itself, RS_HellKnight.zs:2226), plus revenant: RS_BlackRevenant3 4500hp +BOSS (RS_Revenant.zs:1954,1976) whose death releases phase-2 RS_BlackRev2 2800hp flyer (:2101), RS_BlackRevenantEX 7500 (:2243) chaining into Ex2/Ex3 20000hp (:2446-2451), RS_WhiteRevenant2 8866 +BOSS (:2688,2711) which spawns RS_MrBones and RS_PortalSummons portals (:2826,2836); fatso: RS_BlackFatso2 9001 (:1911,1935), RS_BlackFatsoEX 18000 (:1651,1678), RS_WhiteFatso2 15000 (:2131,2153); spider: RS_BlackSP2 (:1716,1736), RS_BlackSPEX (:1871,1892), all RS_WhiteSP* forms; baron: RS_BlackBaron2 8907 (:2244,2276), RS_WhiteBaron2 13069 (:2649,2675), RS_RedBaron3â†’RedBaron2 phase chain (:1923,1940 / :2073,2087-2089) â€” and the RS_RedBaron gate routes to the boss form BY DEFAULT, so weight 10 "red baron" is a boss.
- RS_GrayPE2 â€” a +BOSS monster hiding at colourset weight 8 (RS_PainElemental.zs:605,621). Also spawns 700hp RS_GreyDemon2s via A_PainAttack (:673) and bees on death (:704).

**B. Minion-makers (headcount escapes the budget).**
- **Pain elementals â€” the whole family, position: hard exclusion.** Every tier's attack is A_PainAttack: Commonâ†’RS_CommonLSoul (RS_PainElemental.zs:839,845), Green (:924,948), Blue (:1030-1051), Purple dual (:1135), Yellowâ†’RS_YellowLSoul (:1226,1253) *which itself death-splits into 3 more*, Red (:1342), Brownâ†’cubes (:273), Cyan (:436,444), Grayâ†’GreyDemon2s (:673), Whiteâ†’MiniSentinelPE turrets (:1622-1670). The spawned souls ARE auto-marked no-pinata (they spawn after maptime 0), but they are +COUNTKILL (family-wide re-declared Monster, RS_LostSoul.zs:779) and unbounded â€” a payload PE inflates the kill target forever. If the owner wants a "spawns souls" fantasy, pay for lost souls directly from the table; they are priceable, a PE is not.
- RS_AbyssZombie2 / RS_AbyssZombie3 â€” active infection: RadiusGive of RS_CHAbyssMark converts zombie-species monsters into more abyss zombies (RS_Zombieman.zs:863, 596-601).
- RS_YellowLSoul (death-split, RS_LostSoul.zs:1134-1136), RS_GrayLSoul2 (bee fountain + SPAWNCEILING, :666,680,632), RS_ThePlanBoner (exists to hatch), RS_CHKeganSurprise (12 queen bosses, :218).
- RS_RedHK â€” spawns 8 imp minions the tic it appears (RS_HellKnight.zs:1567-1574). One payload slot = 9 monsters.
- **RS_YellowRevenant â€” newly ruled unsafe.** Spawns 4x RS_SpecialSoul at spawn (RS_Revenant.zs:1634-1637, SXF_SETMASTER). RS_SpecialSoul is `Monster;` with **no -COUNTKILL anywhere in the file** (grep negative), so each Yellow rev is 5 countable bodies.
- Boss summoners already covered under A (BlackSG3, WhiteCguy2, WhiteImp2, BlackCaco2, queens, shifter, Butcher).

**C. Archviles â€” the whole family, position: hard exclusion, and not for the +BOSS reason.**
Common through Abyss tiers resurrect via A_VileChase (RS_Archvile.zs:1077-1079 Common, :1173-1175 Green, :1277-1279 Blue, :491-493 Cyan, :645-662 Abyss). The kill argument: **an archvile raise does not pass through WorldThingSpawned, so the raised monster keeps paying rewards** (RS_SummonMark.zs:80-83). A player-owned payload vile raising map monsters mints a killâ†’rewardâ†’raiseâ†’kill-again loop â€” it breaks the no-pinata contract in the opposite direction from a loot pinata. On top of that: Purple summons real revenant escorts capped at 8 (RS_SpecialRev spawns, RS_Archvile.zs:1391-1394, 1443); Yellow and Red spawn RS_ArchSpawnerOrbs that drop random monsters up to barons (:1522-1527, 1754, 1873-1878; table at RS_LostSoulFX.zs:1925-1957); Gray and FireBlu summon *cvar-gated colour stubs* of six other families (:873-888, :1015-1030) â€” cvar-dependent identity; Black 7750hp and White 13000hp are +BOSS (:1959, :2122). BrownVile is the one non-resurrector (no A_VileChase in :253-434) but is a 1400hp flying caster â€” if the owner ever wants exactly one vile-family payload, that is the candidate; my position is still no.

**D. Master-tethered escorts â€” undefined without a master, never standalone payloads:** RS_SpecialImp3-7 (+NOCLIP, -COUNTKILL, A_Warp to master, RS_Imp.zs:1896-2070), RS_SpecialRev (-COUNTKILL, RS_ArchvileFX.zs:1810-1832), RS_SpecialSoul (NOCLIP+NOTARGET, RS_Revenant.zs:1505-1515), RS_SpecialVile (RS_Archvile.zs:1616-1627), RS_SpecialHK (RS_Cyberdemon.zs:1419-1433), RS_SpecialSpider1 (RS_Mastermind.zs:1674-1692), RS_MolochWraith (20hp, RS_Cyberdemon.zs:1981-1999), RS_RedMindBomb. Note RS_SpecialRev is 80hp, -COUNTKILL, tier-0 â€” the *profile* is exactly right for a cheap disposable skeleton, but its Species "Vile1" and escort defaults make it wrong as-is; it is the template to copy, not the class to spawn.

**E. Never spawn as payload classes:** any colourset RandomSpawner (13 of them â€” rare tail reaches bosses) and any cvar-gate stub (RS_BrownX/CyanX/.../BlackX/WhiteX in every family) â€” stubs relay with SXF_NOCHECKPOSITION and reroll by user cvar; RS_BlackDemon's off-branch IS the boss (RS_Demon.zs:257), RS_RedBaron's default branch IS the boss (RS_Baron.zs:163-186). Spawn only the concrete class names in Section 1.

---

## 3. THE SPAWN CONTRACT â€” in execution order

1. **Resolve to a concrete class name from the Section 1 table.** Never a vanilla name (CheckReplacement rerolls it through the roster â€” RS_Roster.zs:265-347), never a stub, never a colourset.
2. **Spawn at the candidate point with ONFLOORZ** â€” RS_ReserveSquads.zs:244.
3. **Scatter with a LineTrace clamp, move with SetOrigin, never TryMove** (TryMove crosses lines and can trip walk-over specials) â€” RS_ReserveSquads.zs:253-270.
4. **SnapToFloor for walkers** (RS_ReserveSquads.zs:271, helper :350-354). Flyers (caco/lostsoul families) need air clearance instead; nothing with +SPAWNCEILING is in the safe table.
5. **Final gate: headroom check + TestMobjLocation** â€” RS_ReserveSquads.zs:287, helper :356-369. A detonation point has no designer-approved fallback marker, so rejection means *fewer minions than paid for*; treat 0 as a real answer (:1009-1011).
6. **On rejection: ClearCounters() FIRST, then Destroy()** â€” RS_ReserveSquads.zs:287-291. This order is absolute; violating it permanently breaks 100% kills. Same order for any future despawn/expiry (:984-991).
7. **No-pinata marking is automatic** â€” RS_SummonMarker gives RS_SummonToken to any monster spawned at maptime > 0 (RS_SummonMark.zs:67-86), and both reward systems gate on PaysRewards (RS_Score.zs:512, RS_Bits.zs:128). The spawner does nothing. Do not spawn payloads at maptime 0.
8. **Pick a kill% policy explicitly.** Recommended for payload minions: call ClearCounters() immediately after successful placement â€” otherwise a +COUNTKILL minion raises the kill target while paying nothing, and a survivor at exit deflates the tally screen. (ReserveSquads deliberately chose countable for its reinforcements, RS_ReserveSquads.zs:46-48 â€” payload minions are a different animal.)
9. **Set minion.master to the owning player** (or a chain reaching them in â‰¤8 hops) â€” RS_Score.zs:552-558. A bFRIENDLY minion with no master chain pays *nobody* (HandleNonPlayerKill's !bFriendly gate, RS_Score.zs:642).
10. **Mint a payload membership token** (copy RS_ReserveToken, RS_ReserveSquads.zs:81-89) and enforce a live cap with a ThinkerIterator count (pattern: LiveCount, :1100-1111). Nothing existing caps summons.
11. **Strip the minion's DropItem loot** (see Gap 4) â€” PaysRewards does not cover engine drops.
12. **Wake deliberately:** bAMBUSH=false, target = owner's current enemy or nearest hostile, SetState(SeeState) â€” RS_ReserveSquads.zs:335-343.

---

## 4. GAPS â€” what must be built before payload spawning ships

1. **Lifetime.** No system despawns anything. Smallest work: a timer on the payload token's owner; expiry = ClearCounters-then-Destroy (order per contract step 6). Without it, "temporary minions" don't exist.
2. **Summon cap.** rs_reserve_max_alive counts only RS_ReserveToken carriers (RS_ReserveSquads.zs:1100-1111). Smallest work: per-player counter over the new payload token; refuse spawns at cap.
3. **Attribution default.** The marker records no owner (RS_SummonMark.zs:37-46). Smallest work: set master at spawn (contract step 9) â€” one line in the spawner, but someone has to own writing it; without it friendly-minion kills are worth zero.
4. **DropItem stripping.** Every table entry carries a CH loot table; engine drops ignore PaysRewards. The mod already has a drop-suppression system â€” **RS_NoMonsterDrops.zs** (it has a WorldUnloaded at :243, so it is a live handler); smallest work: extend it to suppress drops from RS_SummonToken (or payload-token) carriers.
5. **The cost table itself.** Nothing in the mod assigns spawn costs. Section 1 IS the table; smallest work: a static classâ†’cost map (or derive from SpawnHealth() the way RS_Score.BasePointsFor does, RS_Score.zs:470-482, with behavior multipliers) plus a hard +BOSS/bBOSS refusal â€” note ReserveSquads gates bosses only for automatic rolls, not explicit deploys (RS_ReserveSquads.zs:672-677, 1047-1051).
6. **Boss-special interaction gate.** Fatso/spider/baron payloads interact with tag-666/667 maps (Section 1 caveat). Smallest work: either a per-map cvar/level-flag check before offering those families, or accept and document it.
7. **Summoner-death / level-exit cleanup.** Nothing links a summon to anything; summons cease at exit with no accounting. Only needed if the design wants it; if built, reuse the lifetime machinery of Gap 1.
8. **The contract is cvar-soft.** rs_summons_pay = true (CVARINFO.txt:1417, RS_SummonMark.zs:58-65) turns every payload minion back into a full payer. Decide whether payload minions honor that cvar or carry a second, non-optional gate.

---

## 5. COST CURVE SANITY

The curve is usable: monotone in effective threat, dense from 2-30, thinning correctly into elites (32-50), with anchors landing where the census pinned them (imp 5, demon 8, caco 12, revenant 15, arachnotron 18, hellknight 20, mancubus 19-21, baron 28).

- **Budget 10:** 5x zombies, or 3x shotgunners+zombie, or 2x imps, or 1x demon + 1x common zombie, or 2x lost souls + zombie, or 1x RedLSoul. Sane trash-tier bundles.
- **Budget 20:** 1x hellknight, or 4x imps, or 2x demons + zombie, or 1x caco + demon, or 1x skeleton (RS_CommonRevenant) + imp, or 1x mancubus (19) + filler, or 10x zombies. Exactly the "2 skeletons or 1 hellknight or 4 imps" shape the owner asked for â€” **except that 2 skeletons cost 30, not 20.** One skeleton + one imp is the budget-20 skeleton bundle.
- **Budget 30:** **2x RS_CommonRevenant â€” the canonical cluster grenade.** Or 1x baron + common zombie, or 6x imps, or 2x hellknights would be 40 â€” no, 1x hellknight + 1x demon + zombie. If "cluster grenade spawning 2x skeletons" is meant to be a mid-tier affix, set the grenade payload budget at 30, not 20.
- **Budget 40:** 2x hellknights, or 1x AbyssFatso2, or 1x RedBaron1-class bruiser, or 2x revenants + 1x caco (42, one over â€” 2x revenants + demon = 38), or 8x imps, or 1x baron + caco (40 exactly). Elite-single vs. squad tradeoffs both exist at every checkpoint, which is what a generator needs.

One deliberate wrinkle to keep: RS_BlackLSoul2 at cost 1 is the only -COUNTKILL body, making it the safe "swarm filler" for any leftover budget â€” 20 of them is legal, cheap, and cannot damage kill% even if the generator's ClearCounters discipline slips.

Confidence notes: costs for the seven families I scanned directly (revenant, archvile, PE, fatso, spider, cyberdemon, mastermind, baron rows) are scaled from Health/flags/summon-behavior greps plus targeted reads, not full attack-state reads â€” same methodology and anchor scale as the census chunks. Per-attack damage numbers were not tabulated anywhere; costs are health-and-behavior priced. Unknowns are stated as unknowns (RS_MrBones declip, the SG/CGuy abyss-mark giver, RS_SpecialSoul's missing -COUNTKILL is grep-proven absent, not read-proven intentional).
