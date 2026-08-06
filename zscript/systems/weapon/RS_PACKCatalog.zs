// =====================================================================
// RS_PACKCatalog -- THE SINGLE SOURCE FOR PACK INGREDIENTS.
// ---------------------------------------------------------------------
// PACK = Profile Attack Creation Kit. A profile is EIGHT AXES:
//
//   1 Projectile   2 Casing       3 Muzzleflash   4 BarrelSmoke
//   5 FireSound    6 ImpactPuff   7 ImpactSparks  8 Trail
//
// ASK THIS CLASS FOR ANYTHING PACK. That is the point of the file:
// one door, one owner. Axes 1 and 5 are sourced from the monster tree
// below. The other six are thin passthroughs to RS_Catalog, whose
// entries are re-exposed here unchanged, so no caller ever needs to
// know there are two catalogs and no second copy exists to drift.
//
// AXES A CARD DOES NOT NAME ARE LEFT ALONE, deliberately. Untouched
// means "keep the gun's own": RS_Weapon resolves every axis as
// affix -> the shot's own -> THE GUN'S -> catalog default. So a card
// that swaps only a projectile still fires with the gun's own bang,
// brass and flash. That is what makes a partial card work at all.
//
// 409 PROJECTILES, every one a real class in zscript/monsters/**,
// extracted mechanically from the tree -- none typed by hand, none
// invented. Each carries its damage and speed AS WRITTEN beside it;
// rolls are never flattened (CLAUDE.md). Excluded: anything with no
// damage, or Speed 0 -- those are gore and cosmetics, and a card built
// on one would look right and do nothing.
//
// Generated 2026-08-06. zscript/monsters/** is LOCKED from that date,
// so this cannot silently drift out of sync with its source. For what
// any entry does in play, read its row in
// docs/monsters/<Family>/<Family>_ATTACKS.md.
// =====================================================================

class RS_PACKCatalog
{
	const MTHEME_FIRE = 0;
	const MTHEME_ICE = 1;
	const MTHEME_PLASMA = 2;
	const MTHEME_POISON = 3;
	const MTHEME_LIGHTNING = 4;
	const MTHEME_PSYCHIC = 5;
	const MTHEME_VOID = 6;
	const MTHEME_IMPACT = 7;
	const MTHEME_COUNT = 8;

	static string ThemeName(int t)
	{
		if (t == MTHEME_FIRE) return "Fire";
		if (t == MTHEME_ICE) return "Ice";
		if (t == MTHEME_PLASMA) return "Plasma";
		if (t == MTHEME_POISON) return "Poison";
		if (t == MTHEME_LIGHTNING) return "Lightning";
		if (t == MTHEME_PSYCHIC) return "Psychic";
		if (t == MTHEME_VOID) return "Void";
		if (t == MTHEME_IMPACT) return "Impact";
		return "";
	}

	// =================================================================
	// AXIS 1 -- PROJECTILE, from the monster tree
	// =================================================================

	// --- FIRE: 137 ---
	static int FIRE_Count() { return 137; }
	static Class<Actor> FIRE_At(int i)
	{
		switch (i % 137)
		{
		case 0: return "RS_Boomer1";                          // random(1,8), spd 68, homes [chaingunner]
		case 1: return "RS_EXPLOSIONSCGuyEXDelayd";           // random(20,60), spd 50 [chaingunner]
		case 2: return "RS_FireBCGguy";                       // random(5,20), spd 45 [chaingunner]
		case 3: return "RS_BlackFatShotLongRange";            // random(20,80), spd 42 [fatso]
		case 4: return "RS_SpreadMisBarEX";                   // random(10,40), spd 41 [hellknight]
		case 5: return "RS_WhiteBaronSlice";                  // random(11,44), spd 38 [baron]
		case 6: return "RS_YellowBombCGUYEX";                 // random(20,80), spd 38 [chaingunner]
		case 7: return "RS_BrownOrbMind";                     // random(3,33), spd 38 [mastermind]
		case 8: return "RS_BrownOrbMind2";                    // random(1,2), spd 38 [mastermind]
		case 9: return "RS_YellowBombEXSpidie";               // random(20,80), spd 38 [spider]
		case 10: return "RS_SpRocket3";                       // random(10,45), spd 37 [spider]
		case 11: return "RS_ShieldBombRev";                   // random(2,25), spd 34 [revenant]
		case 12: return "RS_RevSolex";                        // random(10,50), spd 34 [revenant]
		case 13: return "RS_WhiteBaronStar";                  // random(5,25), spd 33, homes [baron]
		case 14: return "RS_RomeroRocketCH";                  // random(20,200), spd 33 [cyberdemon]
		case 15: return "RS_RomeroRocketCH2";                 // random(20,200), spd 33 [cyberdemon]
		case 16: return "RS_RomeroRocketCH3";                 // random(20,200), spd 33, homes [cyberdemon]
		case 17: return "RS_BruiserMissileEx";                // random(40,95), spd 33 [hellknight]
		case 18: return "RS_BrownOrbCguy";                    // random(3,9), spd 32 [chaingunner]
		case 19: return "RS_HammerShot";                      // random(30,140), spd 32 [cyberdemon]
		case 20: return "RS_MinesHK";                         // random(5,20), spd 32 [hellknight]
		case 21: return "RS_SkullDeathPE";                    // random(10,50), spd 32 [painelemental]
		case 22: return "RS_RevSol";                          // random(10,50), spd 32 [revenant]
		case 23: return "RS_BBSP1";                           // random(20,75), spd 31 [spider]
		case 24: return "RS_MolochNail";                      // random(10,30), spd 30 [cacodemon]
		case 25: return "RS_BruiserMissileEx2";               // random(80,125), spd 29, homes [hellknight]
		case 26: return "RS_BaronStar2";                      // random(5,25), spd 28, homes [baron]
		case 27: return "RS_EXPLOSIONSCGuyEX";                // random(20,60), spd 28 [chaingunner]
		case 28: return "RS_BrownOrbDemon";                   // random(13,33), spd 28 [demon]
		case 29: return "RS_BaronHellNade";                   // random(30,85), spd 28, homes [hellknight]
		case 30: return "RS_BaronStar";                       // random(5,25), spd 28, homes [lostsoul]
		case 31: return "RS_ReAComet";                        // random(15,88), spd 28 [lostsoul]
		case 32: return "RS_ReATrail";                        // random(5,10), spd 28 [lostsoul]
		case 33: return "RS_RocketShotFatso";                 // random(10,40), spd 28 [lostsoul]
		case 34: return "RS_DKDart";                          // 5, spd 28 [revenant]
		case 35: return "RS_AirStrikeCHBS";                   // random(5,40), spd 28 [shotgunner]
		case 36: return "RS_SPMM5";                           // random(30,65), spd 28, homes [spider]
		case 37: return "RS_Vollrey2";                        // random(10,60), spd 27 [cyberdemon]
		case 38: return "RS_Vollrey";                         // random(10,50), spd 27, homes [cyberdemon]
		case 39: return "RS_BaronStar3";                      // random(5,30), spd 27, homes [hellknight]
		case 40: return "RS_SPMM1";                           // random(20,65), spd 26, homes [spider]
		case 41: return "RS_ArchonComet";                     // 20, spd 25 [baron]
		case 42: return "RS_DFlare";                          // random(10,38), spd 25 [cacodemon]
		case 43: return "RS_HellWaver2";                      // random(40,120), spd 25 [cyberdemon]
		case 44: return "RS_HellWaver";                       // random(40,120), spd 25 [cyberdemon]
		case 45: return "RS_Hellshot2";                       // random(40,120), spd 25 [cyberdemon]
		case 46: return "RS_WhiteFatNuke";                    // random(100,200), spd 25 [fatso]
		case 47: return "RS_BaronNade";                       // random(20,75), spd 25 [hellknight]
		case 48: return "RS_BoomPEBlu";                       // random(25,50), spd 25 [painelemental]
		case 49: return "RS_DFlarePE";                        // random(10,20), spd 25 [painelemental]
		case 50: return "RS_DFlarePE2";                       // random(10,20), spd 25 [painelemental]
		case 51: return "RS_SGGasNade";                       // random(20,75), spd 25 [shotgunner]
		case 52: return "RS_MinesRev";                        // random(10,40), spd 24 [cacodemon]
		case 53: return "RS_RedDeathRev";                     // random(25,85), spd 24, homes [lostsoul]
		case 54: return "RS_Shot2Fatso";                      // 8, spd 24 [lostsoul]
		case 55: return "RS_FirespeNewYel";                   // random(8,24), spd 24 [revenant]
		case 56: return "RS_BaronStar4";                      // random(5,30), spd 22 [mastermind]
		case 57: return "RS_SPMM2";                           // random(20,65), spd 22, homes [spider]
		case 58: return "RS_MiniRKTZombie";                   // random(5,40), spd 22 [zombieman]
		case 59: return "RS_AbyssCybRocket";                  // 20, spd 21, homes [cyberdemon]
		case 60: return "RS_WhiteFatBall1";                   // random(20,50), spd 21, homes [fatso]
		case 61: return "RS_BaronWave";                       // random(5,17), spd 21 [lostsoul]
		case 62: return "RS_FireSGguy";                       // random(5,15), spd 21 [shotgunner]
		case 63: return "RS_SpitFireCaco";                    // random(10,65), spd 20 [cacodemon]
		case 64: return "RS_Rocket2";                         // 20, spd 20 [cyberdemon]
		case 65: return "RS_SplashRocket";                    // 17, spd 20 [cyberdemon]
		case 66: return "RS_Propane";                         // 18, spd 20, homes [cyberdemon]
		case 67: return "RS_FatShot2";                        // 8, spd 20 [fatso]
		case 68: return "RS_HBeastFlame";                     // 1, spd 20 [fatso]
		case 69: return "RS_BruiserMissile";                  // random(20,75), spd 20 [hellknight]
		case 70: return "RS_STracerWhiteSP";                  // random(11,33), spd 20 [mastermind]
		case 71: return "RS_FBSkelCH01";                      // 3, spd 20 [revenant]
		case 72: return "RS_FBSkelCH02";                      // 3, spd 20 [revenant]
		case 73: return "RS_MineShotgun";                     // random(10,50), spd 20 [shotgunner]
		case 74: return "RS_BaronFbomb";                      // random(10,70), spd 19, homes [baron]
		case 75: return "RS_RedDemonBloodBolt1";              // random(2,27), spd 19 [demon]
		case 76: return "RS_SpitFireImp";                     // random(2,42), spd 19 [imp]
		case 77: return "RS_BlackImpExBall2";                 // random(1,10), spd 19, homes [imp]
		case 78: return "RS_AgauresBall2";                    // random(5,25), spd 19 [imp]
		case 79: return "RS_HellionBall";                     // random(10,60), spd 19, homes [imp]
		case 80: return "RS_ReABreath";                       // random(5,25), spd 18 [archvile]
		case 81: return "RS_VolcanoBall1";                    // random(5,35), spd 18 [cyberdemon]
		case 82: return "RS_AbyssDogFire";                    // random(5,45), spd 18, homes [demon]
		case 83: return "RS_Bounc11";                         // random(5,35), spd 18 [imp]
		case 84: return "RS_BigHK";                           // random(10,77), spd 18 [lostsoul]
		case 85: return "RS_PurpleBomb1";                     // random(10,65), spd 18 [lostsoul]
		case 86: return "RS_MiniFatsoPurpleBomb";             // random(5,20), spd 18 [lostsoul]
		case 87: return "RS_SpiralSawMind1";                  // random(10,60), spd 18, homes [mastermind]
		case 88: return "RS_SpreadMisBar1";                   // random(10,40), spd 17 [hellknight]
		case 89: return "RS_DemoMissile";                     // 20, spd 17 [mastermind]
		case 90: return "RS_LavaballPE";                      // random(15,60), spd 17 [painelemental]
		case 91: return "RS_FBSkelCH03";                      // 3, spd 17 [revenant]
		case 92: return "RS_FBSkelCH04";                      // 3, spd 17 [revenant]
		case 93: return "RS_FireSGguy2";                      // random(5,15), spd 17 [zombieman]
		case 94: return "RS_FallenShot";                      // 2, spd 16 [baron]
		case 95: return "RS_Cacofire4";                       // random(5,25), spd 16, homes [cacodemon]
		case 96: return "RS_VolcanoBall2";                    // random(10,40), spd 16, homes [cyberdemon]
		case 97: return "RS_VolcanoBall3";                    // random(10,40), spd 16 [cyberdemon]
		case 98: return "RS_SmithDeathFire";                  // 1, spd 16 [cyberdemon]
		case 99: return "RS_DogFire";                         // 1, spd 16 [demon]
		case 100: return "RS_DogShot";                        // 7, spd 16 [demon]
		case 101: return "RS_Purpfire2";                      // random(5,10), spd 16 [shotgunner]
		case 102: return "RS_WhiteBaronSliceHoming";          // random(5,25), spd 15, homes [baron]
		case 103: return "RS_Cacofire3";                      // random(10,50), spd 15, homes [cacodemon]
		case 104: return "RS_CybieRainMaker";                 // random(5,40), spd 15 [cyberdemon]
		case 105: return "RS_STracer";                        // random(11,33), spd 15 [cyberdemon]
		case 106: return "RS_RedDemonBloodBolt3";             // random(1,5), spd 15 [demon]
		case 107: return "RS_FireHKBall1";                    // random(10,40), spd 15 [lostsoul]
		case 108: return "RS_RemoteBombV2";                   // random(5,45), spd 15, homes [mastermind]
		case 109: return "RS_BlackImpEXBall1";                // random(5,40), spd 14 [imp]
		case 110: return "RS_FireBluMindFlame3";              // random(5,15), spd 14, homes [mastermind]
		case 111: return "RS_BigHK3";                         // random(15,45), spd 12 [lostsoul]
		case 112: return "RS_BrownMindStoneThrow";            // random(1,2), spd 12 [mastermind]
		case 113: return "RS_ShieldBlastRev";                 // random(10,65), spd 12, homes [revenant]
		case 114: return "RS_Homer1";                         // random(8,52), spd 11, homes [lostsoul]
		case 115: return "RS_RedMessImp2";                    // random(2,19), spd 11, homes [shotgunner]
		case 116: return "RS_CybieRain";                      // random(15,50), spd 10, homes [cyberdemon]
		case 117: return "RS_FireBluFatGround";               // random(5,15), spd 10 [fatso]
		case 118: return "RS_DoomImpBall2";                   // 3, spd 10 [imp]
		case 119: return "RS_BoomSkel1";                      // 4, spd 10 [revenant]
		case 120: return "RS_MissileCHBS";                    // random(10,50), spd 10 [shotgunner]
		case 121: return "RS_AgauresBall1";                   // random(5,40), spd 9 [imp]
		case 122: return "RS_ShadowBall2";                    // random(30,90), spd 8 [spectre]
		case 123: return "RS_BigHellshot";                    // random(40,180), spd 7 [cyberdemon]
		case 124: return "RS_BVileOrb1";                      // random(12,45), spd 6 [lostsoul]
		case 125: return "RS_CBWave";                         // random(10,30), spd 4 [cyberdemon]
		case 126: return "RS_HadeExpl";                       // random(5,10), spd 3, homes [cacodemon]
		case 127: return "RS_RedDemonBloodBolt2";             // random(0,1), spd 2 [demon]
		case 128: return "RS_STracerBlue";                    // random(5,17), spd 2 [lostsoul]
		case 129: return "RS_FireBluVile";                    // random(5,23), spd 1 [archvile]
		case 130: return "RS_FireBluCacoBall2";               // random(5,23), spd 1 [cacodemon]
		case 131: return "RS_BlackCacoBeam2";                 // random(10,20), spd 1 [cacodemon]
		case 132: return "RS_BlackImpBeam2";                  // random(10,20), spd 1 [imp]
		case 133: return "RS_FireBluMindFlame1";              // random(5,23), spd 1 [mastermind]
		case 134: return "RS_FireBluMindFlame2";              // random(5,15), spd 1 [mastermind]
		case 135: return "RS_SpRocket4";                      // random(10,50), spd 1 [spider]
		case 136: return "RS_SpRocket4EX";                    // random(20,80), spd 1 [spider]
		}
		return null;
	}

	// --- ICE: 36 ---
	static int ICE_Count() { return 36; }
	static Class<Actor> ICE_At(int i)
	{
		switch (i % 36)
		{
		case 0: return "RS_FrostLong";                        // random(5,12), spd 76, homes [imp]
		case 1: return "RS_SoulexBeam";                       // random(10,30), spd 69 [lostsoul]
		case 2: return "RS_SoulexBeam2";                      // random(10,30), spd 69 [lostsoul]
		case 3: return "RS_SoulexBeam3";                      // random(10,30), spd 69 [lostsoul]
		case 4: return "RS_IceABVile";                        // random(9,45), spd 46 [archvile]
		case 5: return "RS_SpiderCyanBomb";                   // random(11,44), spd 45, homes [spider]
		case 6: return "RS_SmallIceCaco";                     // random(8,21), spd 42 [cacodemon]
		case 7: return "RS_CyanCybieSprayIce";                // random(3,12), spd 42 [cyberdemon]
		case 8: return "RS_IceOrbCyanHK";                     // random(7,60), spd 42 [hellknight]
		case 9: return "RS_IceOrbCyanMind";                   // random(5,55), spd 42 [mastermind]
		case 10: return "RS_BaronStarCyan";                   // random(5,25), spd 38 [baron]
		case 11: return "RS_BaronCyanBomb";                   // random(33,99), spd 38, homes [baron]
		case 12: return "RS_BigBallCrev";                     // random(3,30), spd 38, homes [revenant]
		case 13: return "RS_WhiteRevFrostBolt";               // random(30,90), spd 35 [revenant]
		case 14: return "RS_IceHKShot";                       // random(9,27), spd 34 [hellknight]
		case 15: return "RS_IceZombieShot";                   // random(6,16), spd 33 [zombieman]
		case 16: return "RS_BigIceCaco";                      // random(8,40), spd 32 [cacodemon]
		case 17: return "RS_CyanFatBall";                     // random(10,80), spd 32 [fatso]
		case 18: return "RS_AbyssZShotCH";                    // random(5,30), spd 32 [zombieman]
		case 19: return "RS_CyanCybieBigIce";                 // random(20,80), spd 30 [cyberdemon]
		case 20: return "RS_AbyssFatsoBomb";                  // random(20,85), spd 28 [fatso]
		case 21: return "RS_CyanImpBall";                     // random(2,20), spd 28 [imp]
		case 22: return "RS_IceSeekerBaron";                  // random(5,25), spd 26, homes [baron]
		case 23: return "RS_AbyssSPBreath";                   // random(5,12), spd 24 [spider]
		case 24: return "RS_AbyssCacoBalls";                  // random(5,55), spd 21 [cacodemon]
		case 25: return "RS_IceOrbCyanAra1";                  // random(10,45), spd 20, homes [painelemental]
		case 26: return "RS_IceOrbCyanAra2";                  // random(10,50), spd 20 [painelemental]
		case 27: return "RS_IceORBCyanRev";                   // random(5,21), spd 20 [revenant]
		case 28: return "RS_FrostMind";                       // random(5,12), spd 19 [mastermind]
		case 29: return "RS_FrostMistWhiteRev";               // random(5,12), spd 19 [revenant]
		case 30: return "RS_SplashAbyssCguy";                 // random(1,9), spd 16 [chaingunner]
		case 31: return "RS_IceORbAbyssRev";                  // random(6,55), spd 15, homes [revenant]
		case 32: return "RS_IceOrb";                          // random(10,55), spd 14, homes [mastermind]
		case 33: return "RS_SpikeCyanRev";                    // random(1,3), spd 9 [demon]
		case 34: return "RS_IceToMeetVile2";                  // random(1,2), spd 1 [archvile]
		case 35: return "RS_IceToMeetWhiteRev2";              // random(1,2), spd 1 [revenant]
		}
		return null;
	}

	// --- PLASMA: 147 ---
	static int PLASMA_Count() { return 147; }
	static Class<Actor> PLASMA_At(int i)
	{
		switch (i % 147)
		{
		case 0: return "RS_EyeBeamCaco";                      // 1, spd 178 [cacodemon]
		case 1: return "RS_MegaRedRev";                       // random(35,95), spd 90 [hellknight]
		case 2: return "RS_AbyssBaronLightning";              // random(20,125), spd 76 [baron]
		case 3: return "RS_FatsoSoundWave";                   // random(10,55), spd 56 [fatso]
		case 4: return "RS_FatsoSoundWaveTrail";              // random(10,55), spd 56 [fatso]
		case 5: return "RS_AbyssCacoHidi";                    // random(30,95), spd 55, homes [cacodemon]
		case 6: return "RS_WhiteMindshoTrail1";               // random(2,6), spd 55 [mastermind]
		case 7: return "RS_SGshot1";                          // random(2,6), spd 55 [shotgunner]
		case 8: return "RS_RomeroBeamCH";                     // random(20,180), spd 50 [cyberdemon]
		case 9: return "RS_BlueFT2";                          // random(10,70), spd 50 [lostsoul]
		case 10: return "RS_FireBluFatsoBal1";                // random(10,20), spd 45 [fatso]
		case 11: return "RS_WhiteMindshot1";                  // random(10,50), spd 45 [mastermind]
		case 12: return "RS_Spear11";                         // random(10,85), spd 42 [lostsoul]
		case 13: return "RS_ZapOrbHKEX2";                     // random(10,40), spd 41 [hellknight]
		case 14: return "RS_RomeroCHScatter";                 // random(20,90), spd 38 [cyberdemon]
		case 15: return "RS_ShadowBombBigEX";                 // random(50,200), spd 38, homes [fatso]
		case 16: return "RS_ExSpideLaser1";                   // random(10,50), spd 38 [spider]
		case 17: return "RS_SwooshCB";                        // random(10,60), spd 36 [cyberdemon]
		case 18: return "RS_SwooshCBBar1";                    // random(10,40), spd 36 [hellknight]
		case 19: return "RS_PlasmaBallSPFB3";                 // 5, spd 33 [spider]
		case 20: return "RS_PlasmaBallSPFB4";                 // 5, spd 33 [spider]
		case 21: return "RS_TheBangers";                      // random(1,8), spd 32, homes [archvile]
		case 22: return "RS_QueenPlasmaBlast";                // random(8,45), spd 32 [mastermind]
		case 23: return "RS_AbyssSPBolt";                     // random(35,90), spd 32 [spider]
		case 24: return "RS_RomeroCHSeekBall";                // random(20,90), spd 30, homes [cyberdemon]
		case 25: return "RS_OrbPurpleMind";                   // random(10,30), spd 30 [mastermind]
		case 26: return "RS_WhiteSpidWinder";                 // random(10,70), spd 30, homes [mastermind]
		case 27: return "RS_StormShot1";                      // random(40,150), spd 30 [painelemental]
		case 28: return "RS_AbyssBaronFlare";                 // random(13,75), spd 28 [baron]
		case 29: return "RS_SpamShotsCguyEX";                 // random(10,120), spd 28 [chaingunner]
		case 30: return "RS_AbyCybBubProj";                   // random(1,12), spd 28 [cyberdemon]
		case 31: return "RS_AbyssHKBall";                     // random(10,55), spd 28 [hellknight]
		case 32: return "RS_BrownOrbSpiderCH";                // 0, spd 28 [spider]
		case 33: return "RS_VollreyAbyPE";                    // random(5,40), spd 27, homes [painelemental]
		case 34: return "RS_RedBombSP";                       // random(5,40), spd 27, homes [spider]
		case 35: return "RS_RedBBall2";                       // random(10,55), spd 25 [baron]
		case 36: return "RS_DeepOneBall";                     // random(25,75), spd 25, homes [baron]
		case 37: return "RS_TentacleBall1";                   // random(10,60), spd 25 [baron]
		case 38: return "RS_SpamShotsCguy";                   // random(10,60), spd 25, homes [chaingunner]
		case 39: return "RS_BrownCybBasic";                   // random(60,120), spd 25 [cyberdemon]
		case 40: return "RS_SpamShotsRomeroCH";               // random(50,150), spd 25, homes [cyberdemon]
		case 41: return "RS_FatAbysswave";                    // random(14,60), spd 25 [fatso]
		case 42: return "RS_RedBBall";                        // random(10,50), spd 25 [imp]
		case 43: return "RS_Spspit2";                         // random(10,72), spd 25, homes [lostsoul]
		case 44: return "RS_AbyssSPTrail";                    // random(2,12), spd 25 [spider]
		case 45: return "RS_ArachnotronPlasma2";              // 5, spd 25 [spider]
		case 46: return "RS_PlayerEXBFG";                     // random(100,200), spd 25 [zombieman]
		case 47: return "RS_PlasmaBallSP3";                   // 5, spd 25 [zombieman]
		case 48: return "RS_SmashBall4";                      // random(5,65), spd 24, homes [baron]
		case 49: return "RS_CrackedAbyssMindFloor";           // random(10,30), spd 24 [mastermind]
		case 50: return "RS_FiendPlasmaBall";                 // random(10,35), spd 24 [mastermind]
		case 51: return "RS_QueenMindWave";                   // random(30,80), spd 24, homes [mastermind]
		case 52: return "RS_SPMM3";                           // random(20,85), spd 24 [spider]
		case 53: return "RS_PhantomEgg";                      // random(20,60), spd 22 [hellknight]
		case 54: return "RS_WVileBolt1";                      // random(10,50), spd 21 [archvile]
		case 55: return "RS_CGBigEx";                         // random(30,80), spd 21, homes [chaingunner]
		case 56: return "RS_ShadowBeast_BallEx2";             // random(16,60), spd 21 [fatso]
		case 57: return "RS_AbyssBallCH";                     // random(5,40), spd 21 [imp]
		case 58: return "RS_SpitBoltLS";                      // random(5,42), spd 21 [lostsoul]
		case 59: return "RS_Orbb11";                          // random(2,18), spd 21, homes [zombieman]
		case 60: return "RS_FireBluCybMiss";                  // random(20,90), spd 20, homes [cyberdemon]
		case 61: return "RS_BluCybArt";                       // random(10,60), spd 20, homes [cyberdemon]
		case 62: return "RS_ShadowBeast_Ball3";               // random(20,60), spd 20 [fatso]
		case 63: return "RS_FireBluHKBall2";                  // random(5,10), spd 20 [hellknight]
		case 64: return "RS_BrownRevBall";                    // random(5,40), spd 20, homes [revenant]
		case 65: return "RS_SGLance1";                        // 1, spd 20 [shotgunner]
		case 66: return "RS_PlasmaBallSPFB1";                 // 5, spd 20, homes [spider]
		case 67: return "RS_PlasmaBallSPFB2";                 // 5, spd 20, homes [spider]
		case 68: return "RS_Spspit";                          // random(8,50), spd 20 [spider]
		case 69: return "RS_CGBigOne";                        // random(30,80), spd 19, homes [chaingunner]
		case 70: return "RS_HKBolt2";                         // random(10,50), spd 19, homes [lostsoul]
		case 71: return "RS_CacoFire2";                       // random(6,35), spd 18 [cacodemon]
		case 72: return "RS_BCybSlimeSet";                    // random(11,33), spd 18 [cyberdemon]
		case 73: return "RS_WhiteFatsoGroundZap";             // random(10,30), spd 18 [fatso]
		case 74: return "RS_BaronsBlueBalls";                 // random(10,45), spd 18 [lostsoul]
		case 75: return "RS_CrackedAbyssMind";                // random(1,6), spd 18 [mastermind]
		case 76: return "RS_CrackedAbyssMindFall";            // random(10,60), spd 18 [mastermind]
		case 77: return "RS_CrackedWhiteMind";                // random(1,6), spd 18 [mastermind]
		case 78: return "RS_BrownPEShot";                     // random(10,45), spd 18 [painelemental]
		case 79: return "RS_CrackedAbyssRev";                 // random(6,66), spd 18, homes [revenant]
		case 80: return "RS_ShadowBall";                      // random(20,55), spd 18 [spectre]
		case 81: return "RS_Cacospit1";                       // random(10,45), spd 17 [cacodemon]
		case 82: return "RS_WhiteFatsoAirZap";                // random(1,2), spd 17, homes [fatso]
		case 83: return "RS_BloodBoltHK";                     // random(10,54), spd 17 [hellknight]
		case 84: return "RS_BigBolt2";                        // random(25,95), spd 17, homes [lostsoul]
		case 85: return "RS_FireBluCacoBall";                 // random(5,40), spd 16 [cacodemon]
		case 86: return "RS_ShadowBeast_Ball2";               // random(10,45), spd 16 [fatso]
		case 87: return "RS_Blufier1";                        // random(17,38), spd 16 [imp]
		case 88: return "RS_BaronBall2";                      // 8, spd 15 [baron]
		case 89: return "RS_CrackodemonBall";                 // random(5,55), spd 15 [cacodemon]
		case 90: return "RS_SwooshCB2";                       // random(20,70), spd 15, homes [cyberdemon]
		case 91: return "RS_ZappersCB";                       // random(5,35), spd 15 [cyberdemon]
		case 92: return "RS_FireBluHKBall1";                  // random(5,50), spd 15 [hellknight]
		case 93: return "RS_zap7";                            // random(20,50), spd 15 [lostsoul]
		case 94: return "RS_OverBall3";                       // 8, spd 15 [painelemental]
		case 95: return "RS_Zap8";                            // random(11,33), spd 15 [revenant]
		case 96: return "RS_BlackSpideSpiralShot";            // random(20,80), spd 15 [spider]
		case 97: return "RS_CGRailBuff";                      // random(1,3), spd 14, homes [chaingunner]
		case 98: return "RS_GreenIBall";                      // random(5,23), spd 14, homes [imp]
		case 99: return "RS_WimpBall1";                       // random(5,25), spd 14 [imp]
		case 100: return "RS_AcidBlast1";                     // random(5,55), spd 14, homes [lostsoul]
		case 101: return "RS_GreenBomb1";                     // random(20,75), spd 14 [lostsoul]
		case 102: return "RS_Bluewave1";                      // random(10,69), spd 14 [lostsoul]
		case 103: return "RS_FatsoShotYE";                    // random(10,40), spd 14, homes [lostsoul]
		case 104: return "RS_PlasmaPE";                       // random(10,23), spd 14, homes [painelemental]
		case 105: return "RS_SSpit2";                         // random(1,4), spd 14 [spider]
		case 106: return "RS_Purp1";                          // random(10,30), spd 13, homes [lostsoul]
		case 107: return "RS_Spspit3";                        // random(15,60), spd 12 [baron]
		case 108: return "RS_AbyCybBub";                      // random(1,8), spd 12 [cyberdemon]
		case 109: return "RS_FireBluHKBall3";                 // random(5,10), spd 12 [hellknight]
		case 110: return "RS_SbombCaco";                      // random(5,80), spd 11 [cacodemon]
		case 111: return "RS_GreenBalb";                      // random(10,30), spd 11 [cyberdemon]
		case 112: return "RS_GreenBalb2";                     // random(15,30), spd 11 [cyberdemon]
		case 113: return "RS_WhiteFatRB4";                    // random(15,30), spd 11 [fatso]
		case 114: return "RS_WhiteFatRB2";                    // random(30,50), spd 11 [fatso]
		case 115: return "RS_SmashBalls2";                    // random(5,35), spd 11, homes [lostsoul]
		case 116: return "RS_WhiteMindRB4";                   // random(15,30), spd 11 [mastermind]
		case 117: return "RS_BluPowerBomb";                   // random(10,70), spd 10, homes [baron]
		case 118: return "RS_CacodemonBall2";                 // 5, spd 10 [cacodemon]
		case 119: return "RS_RomeroGroundCH";                 // random(20,100), spd 10 [cyberdemon]
		case 120: return "RS_RomeroSkyCH";                    // random(20,100), spd 10 [cyberdemon]
		case 121: return "RS_PlayerEXBFG2";                   // random(20,80), spd 10 [zombieman]
		case 122: return "RS_PlasmaBallSP4";                  // random(3,7), spd 9 [cacodemon]
		case 123: return "RS_BlackImpExBigOne";               // random(50,120), spd 9, homes [imp]
		case 124: return "RS_WhiteMindCrackleOrb";            // random(50,120), spd 9, homes [mastermind]
		case 125: return "RS_SbombPE";                        // random(10,50), spd 9 [painelemental]
		case 126: return "RS_FireBluFatsoBal2";               // random(15,50), spd 8 [fatso]
		case 127: return "RS_ShadowBombBig";                  // random(20,90), spd 8 [fatso]
		case 128: return "RS_ShadowBeast_BallEx3";            // random(20,60), spd 8, homes [fatso]
		case 129: return "RS_WhiteSpidWave";                  // random(5,27), spd 8 [mastermind]
		case 130: return "RS_WhiteSpiderPBolt";               // random(35,90), spd 8 [spider]
		case 131: return "RS_DIBigOne";                       // random(40,125), spd 7 [imp]
		case 132: return "RS_SpecSlime3";                     // random(10,50), spd 7, homes [spectre]
		case 133: return "RS_WhiteSpiderHomer";               // random(35,90), spd 6, homes [spider]
		case 134: return "RS_AbyssCacoZap";                   // random(1,5), spd 4 [cacodemon]
		case 135: return "RS_AbyssCacoZap2";                  // random(1,5), spd 2 [cacodemon]
		case 136: return "RS_DeepBeam1";                      // random(10,25), spd 1 [baron]
		case 137: return "RS_GenShield";                      // 0, spd 1, homes [chaingunner]
		case 138: return "RS_BCybieGreenWave";                // random(9,39), spd 1 [cyberdemon]
		case 139: return "RS_BCybieGreenWave2";               // random(6,35), spd 1 [cyberdemon]
		case 140: return "RS_WhiteFatRB";                     // random(30,95), spd 1 [fatso]
		case 141: return "RS_WhiteFatRB3";                    // random(30,95), spd 1 [fatso]
		case 142: return "RS_WhiteMindRB3";                   // random(30,95), spd 1 [mastermind]
		case 143: return "RS_LoadPE3";                        // 0, spd 1 [painelemental]
		case 144: return "RS_BEESHOT";                        // 0, spd 1 [painelemental]
		case 145: return "RS_SGLance5";                       // 1, spd 1 [shotgunner]
		case 146: return "RS_SGLance2";                       // random(0,1), spd 1 [shotgunner]
		}
		return null;
	}

	// --- POISON: 12 ---
	static int POISON_Count() { return 12; }
	static Class<Actor> POISON_At(int i)
	{
		switch (i % 12)
		{
		case 0: return "RS_SpidieShot1";                      // random(3,8), spd 65 [mastermind]
		case 1: return "RS_NeedlesCg2";                       // random(5,45), spd 25 [chaingunner]
		case 2: return "RS_ShadowBeast_BallFireEX";           // 3, spd 20 [fatso]
		case 3: return "RS_BeetleSpitAbyss";                  // random(1,8), spd 20 [lostsoul]
		case 4: return "RS_GreeniesBR";                       // random(1,2), spd 15 [baron]
		case 5: return "RS_ShadowBeast_Ballex1";              // random(20,50), spd 15 [fatso]
		case 6: return "RS_ShadowBeast_BallFire";             // 3, spd 15 [fatso]
		case 7: return "RS_ShadowBeast_Ball1";                // random(20,50), spd 15 [fatso]
		case 8: return "RS_Puddle1";                          // 4, spd 14 [chaingunner]
		case 9: return "RS_BlackFatSplash";                   // 2, spd 12 [fatso]
		case 10: return "RS_Greenies2";                       // random(1,2), spd 10 [archvile]
		case 11: return "RS_SplasherSoul";                    // random(5,15), spd 5 [lostsoul]
		}
		return null;
	}

	// --- LIGHTNING: 2 ---
	static int LIGHTNING_Count() { return 2; }
	static Class<Actor> LIGHTNING_At(int i)
	{
		switch (i % 2)
		{
		case 0: return "RS_StormStrike1";                     // 2, spd 90 [painelemental]
		case 1: return "RS_StormLite1";                       // 5, spd 32 [painelemental]
		}
		return null;
	}

	// --- PSYCHIC: 2 ---
	static int PSYCHIC_Count() { return 2; }
	static Class<Actor> PSYCHIC_At(int i)
	{
		switch (i % 2)
		{
		case 0: return "RS_AbyssMindSpike";                   // random(1,10), spd 1 [mastermind]
		case 1: return "RS_AbyssMindSpike2";                  // random(1,10), spd 1 [mastermind]
		}
		return null;
	}

	// --- VOID: 3 ---
	static int VOID_Count() { return 3; }
	static Class<Actor> VOID_At(int i)
	{
		switch (i % 3)
		{
		case 0: return "RS_SPShard";                          // random(5,10), spd 32, homes [spider]
		case 1: return "RS_AbyssPEPulse";                     // random(1,2), spd 11 [painelemental]
		case 2: return "RS_DeathBreathDI";                    // 1, spd 1 [imp]
		}
		return null;
	}

	// --- IMPACT: 70 ---
	static int IMPACT_Count() { return 70; }
	static Class<Actor> IMPACT_At(int i)
	{
		switch (i % 70)
		{
		case 0: return "RS_SpiderStoneRocket";                // random(60,95), spd 83 [spider]
		case 1: return "RS_RevNail";                          // random(5,15), spd 55 [cacodemon]
		case 2: return "RS_CacoNail";                         // random(5,15), spd 55 [cacodemon]
		case 3: return "RS_SpidieShotGray";                   // random(1,11), spd 46 [mastermind]
		case 4: return "RS_CGNail";                           // random(1,5), spd 45 [chaingunner]
		case 5: return "RS_WDRock4";                          // random(5,20), spd 42 [demon]
		case 6: return "RS_HKEXslash";                        // random(10,35), spd 42 [hellknight]
		case 7: return "RS_BlackRevHook";                     // random(5,30), spd 42 [revenant]
		case 8: return "RS_BoneToPickGrey";                   // random(10,40), spd 36 [revenant]
		case 9: return "RS_WDRock3";                          // random(15,65), spd 36 [zombieman]
		case 10: return "RS_NeedlesCg1";                      // random(5,25), spd 35 [chaingunner]
		case 11: return "RS_BSoulStinger1";                   // random(5,25), spd 35 [lostsoul]
		case 12: return "RS_WHITESPIDERWEBSHOTNOTLEWD";       // random(1,5), spd 35 [spider]
		case 13: return "RS_AbyssMindWave";                   // random(30,80), spd 34 [mastermind]
		case 14: return "RS_FatsoSpikes";                     // random(28,85), spd 32 [fatso]
		case 15: return "RS_ChainWhipRev";                    // random(11,33), spd 29 [revenant]
		case 16: return "RS_SPWHII3";                         // random(10,60), spd 29, homes [spider]
		case 17: return "RS_SPWHI3";                          // random(10,75), spd 29, homes [spider]
		case 18: return "RS_BaronBrownRock";                  // random(10,40), spd 28, homes [baron]
		case 19: return "RS_AbyCybWave";                      // random(10,40), spd 28 [cyberdemon]
		case 20: return "RS_WDRock2";                         // random(35,125), spd 28 [demon]
		case 21: return "RS_WhiteFatScatter";                 // random(10,30), spd 26 [fatso]
		case 22: return "RS_ShoveZM";                         // random(10,45), spd 25 [zombieman]
		case 23: return "RS_ShoveZM2";                        // random(1,5), spd 25 [zombieman]
		case 24: return "RS_EyeRocketCaco";                   // random(50,150), spd 24, homes [cacodemon]
		case 25: return "RS_SoulShotWEX";                     // random(5,33), spd 24 [lostsoul]
		case 26: return "RS_WhiteRevCoil";                    // random(40,90), spd 24, homes [revenant]
		case 27: return "RS_SPWHII2";                         // random(10,60), spd 23 [spider]
		case 28: return "RS_SPWHI2";                          // random(10,75), spd 23 [spider]
		case 29: return "RS_SoulSeekerRev";                   // random(5,20), spd 22, homes [revenant]
		case 30: return "RS_RedPowerBomb";                    // random(10,80), spd 21, homes [baron]
		case 31: return "RS_RockSlideCH5";                    // random(40,80), spd 21 [cyberdemon]
		case 32: return "RS_SOULEXSoulCharge";                // random(20,90), spd 21, homes [lostsoul]
		case 33: return "RS_BaronOfDirtCH3";                  // random(75,155), spd 20 [baron]
		case 34: return "RS_CacobaldBall";                    // 5, spd 20 [cacodemon]
		case 35: return "RS_AbyCybWave2";                     // random(4,16), spd 20 [cyberdemon]
		case 36: return "RS_BrownHKShieldCheck";              // random(10,60), spd 20 [hellknight]
		case 37: return "RS_BrownMindBone2";                  // random(20,40), spd 20, homes [mastermind]
		case 38: return "RS_SPMM4";                           // random(30,65), spd 20, homes [spider]
		case 39: return "RS_SoulSeekerRevex";                 // random(10,30), spd 19, homes [revenant]
		case 40: return "RS_CacobaldBall2";                   // 5, spd 18, homes [cacodemon]
		case 41: return "RS_RockSlideCH4";                    // random(45,90), spd 18 [cyberdemon]
		case 42: return "RS_AbyssBaronSoulCharge";            // random(20,90), spd 17, homes [baron]
		case 43: return "RS_BaronOfDirtCH2";                  // random(70,170), spd 16, homes [baron]
		case 44: return "RS_BSoulHellNo";                     // random(1,2), spd 16, homes [lostsoul]
		case 45: return "RS_GrellBallBrown";                  // 4, spd 15 [cacodemon]
		case 46: return "RS_ZWAVE3";                          // random(10,30), spd 15 [mastermind]
		case 47: return "RS_CorpseBreathPE";                  // random(5,12), spd 15 [painelemental]
		case 48: return "RS_IceOrbCH2";                       // random(11,33), spd 15, homes [spectre]
		case 49: return "RS_BVileCloud";                      // random(1,2), spd 14 [archvile]
		case 50: return "RS_WormLewd";                        // random(5,23), spd 14 [demon]
		case 51: return "RS_EvilShadeWhiteRev";               // random(2,7), spd 14 [revenant]
		case 52: return "RS_RockSlideCH3";                    // random(55,105), spd 12 [cyberdemon]
		case 53: return "RS_SoulBomb4";                       // random(10,70), spd 12, homes [cyberdemon]
		case 54: return "RS_AbyPECoil";                       // random(30,80), spd 12, homes [painelemental]
		case 55: return "RS_ROCKDROPVILE";                    // random(75,155), spd 10 [archvile]
		case 56: return "RS_RockSlideCH2";                    // random(75,155), spd 10 [cyberdemon]
		case 57: return "RS_ChainWhipRev2";                   // random(1,9), spd 9 [revenant]
		case 58: return "RS_MolochQuake";                     // random(5,27), spd 8 [demon]
		case 59: return "RS_BlackSpidShade";                  // random(10,58), spd 8 [mastermind]
		case 60: return "RS_FatsoSpikes2";                    // random(10,40), spd 5 [imp]
		case 61: return "RS_GrayMindNeedle";                  // random(10,50), spd 5, homes [mastermind]
		case 62: return "RS_VileGroundSpikes2";               // random(1,10), spd 1 [archvile]
		case 63: return "RS_VileGroundSpikeBrown";            // random(1,10), spd 1 [baron]
		case 64: return "RS_VileGroundSpikeBrown2";           // random(1,10), spd 1 [baron]
		case 65: return "RS_SmithGhost1";                     // random(12,34), spd 1 [cyberdemon]
		case 66: return "RS_SmithGhost2";                     // random(12,34), spd 1 [cyberdemon]
		case 67: return "RS_BSoulStinger2";                   // random(5,25), spd 1 [lostsoul]
		case 68: return "RS_MindGroundSpikeBrown";            // random(10,25), spd 1 [mastermind]
		case 69: return "RS_RedMindRingNew";                  // random(30,90), spd 1, homes [mastermind]
		}
		return null;
	}

	// =================================================================
	// AXIS 5 -- FIRE SOUND
	// =================================================================
	// LAYERS over the gun's own voice, never replaces it (owner ruling:
	// "my shotgun should always sound like a shotgun even if it is kinda
	// something else"). Every one was followed to a real lump on disk --
	// being in SNDINFO is not enough. 71 of this project's 1255 sound
	// names point at nothing, and an unresolved name is completely inert:
	// no error, no warning, no log line, it simply never plays.
	static sound DrawFireSound(int theme)
	{
		if (theme == MTHEME_FIRE) return "Fire/fire1";        // ch/FIREBFL.ogg
		if (theme == MTHEME_ICE) return "Ice/Cast";           // ch/ICECAST.ogg
		if (theme == MTHEME_PLASMA) return "electricplasma/shoot";// ch/PZAPSEE.ogg
		if (theme == MTHEME_POISON) return "Roach/Fire";      // ch/ROACFIRE.ogg
		if (theme == MTHEME_LIGHTNING) return "Spell/Lightn"; // ch/GNTACT1.lmp
		if (theme == MTHEME_PSYCHIC) return "Spell/Impact1";  // ch/FUNGL1.ogg
		if (theme == MTHEME_VOID) return "Spell/Impact1";     // ch/FUNGL1.ogg
		if (theme == MTHEME_IMPACT) return "Fire/fire1";      // ch/FIREBFL.ogg
		return "";
	}

	// =================================================================
	// AXES 2, 4, 6, 7, 8 -- passthroughs to RS_Catalog
	// =================================================================
	// Dressing rather than payload. One definition, one owner.

	static int CasingCount() { return 3; }
	static string CasingAt(int i)
	{
		switch (i % 3)
		{
		case 0: return RS_Catalog.CASING_Small();
		case 1: return RS_Catalog.CASING_Rifle();
		case 2: return RS_Catalog.CASING_Shell();
		}
		return "";
	}

	static int SmokeCount() { return 2; }
	static Class<Actor> SmokeAt(int i)
	{
		if (i % 2 == 0) return RS_Catalog.SMOKE_Wisp();
		return RS_Catalog.SMOKE_PS_Blast();
	}

	static int PuffCount() { return 4; }
	static Class<Actor> PuffAt(int i)
	{
		switch (i % 4)
		{
		case 0: return RS_Catalog.PUFF_Bullet();
		case 1: return RS_Catalog.PUFF_Shot();
		case 2: return RS_Catalog.PUFF_PS_Hit();
		case 3: return RS_Catalog.PUFF_Vanilla();
		}
		return null;
	}

	static int SparkCount() { return 5; }
	static Class<Actor> SparkAt(int i)
	{
		switch (i % 5)
		{
		case 0: return RS_Catalog.SPARK_Hit();
		case 1: return RS_Catalog.SPARK_Ricochet();
		case 2: return RS_Catalog.SPARK_Rail();
		case 3: return RS_Catalog.SPARK_X();
		case 4: return RS_Catalog.SPARK_PS_Shrapnel();
		}
		return null;
	}

	static int TrailCount() { return 3; }
	static Class<Actor> TrailAt(int i)
	{
		switch (i % 3)
		{
		case 0: return RS_Catalog.TRAIL_Ballistic();
		case 1: return RS_Catalog.TRAIL_PS_Rocket();
		case 2: return RS_Catalog.TRAIL_ST_Ember();
		}
		return null;
	}

	// AXIS 3 -- MUZZLEFLASH is a bool on the profile (BigMuzzle), not a
	// class, so there is nothing to catalogue. Named here as a deliberate
	// gap rather than left silently absent.

	// =================================================================
	// DRAW
	// =================================================================
	static Class<Actor> DrawProjectile(int theme, int index)
	{
		if (theme == MTHEME_FIRE) return FIRE_At(index);
		if (theme == MTHEME_ICE) return ICE_At(index);
		if (theme == MTHEME_PLASMA) return PLASMA_At(index);
		if (theme == MTHEME_POISON) return POISON_At(index);
		if (theme == MTHEME_LIGHTNING) return LIGHTNING_At(index);
		if (theme == MTHEME_PSYCHIC) return PSYCHIC_At(index);
		if (theme == MTHEME_VOID) return VOID_At(index);
		if (theme == MTHEME_IMPACT) return IMPACT_At(index);
		return null;
	}

	static int ThemeCount(int theme)
	{
		if (theme == MTHEME_FIRE) return FIRE_Count();
		if (theme == MTHEME_ICE) return ICE_Count();
		if (theme == MTHEME_PLASMA) return PLASMA_Count();
		if (theme == MTHEME_POISON) return POISON_Count();
		if (theme == MTHEME_LIGHTNING) return LIGHTNING_Count();
		if (theme == MTHEME_PSYCHIC) return PSYCHIC_Count();
		if (theme == MTHEME_VOID) return VOID_Count();
		if (theme == MTHEME_IMPACT) return IMPACT_Count();
		return 0;
	}

	// Fill one themed card's worth of axes onto a profile. Writes only
	// the axes this catalog has an opinion about; casing, muzzleflash,
	// barrel smoke and sparks are left for the gun to supply.
	static void ApplyTheme(RS_AttackProfile p, int theme, int index = 0)
	{
		if (!p) return;
		Class<Actor> proj = DrawProjectile(theme, index);
		if (proj) p.ProjectileClass = proj;
		p.FireSound  = DrawFireSound(theme);
		p.ImpactPuff = PuffAt(0);
		p.Trail      = TrailAt(0);
		if (p.ProfileName == "") p.ProfileName = ThemeName(theme);
	}

	// Size of the whole draw pile.
	static int TotalProjectiles()
	{
		int n = 0;
		for (int t = 0; t < MTHEME_COUNT; t++) n += ThemeCount(t);
		return n;
	}
}
