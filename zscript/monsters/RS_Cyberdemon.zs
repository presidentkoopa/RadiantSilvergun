// =====================================================================
// RS_Cyberdemon -- rebuilt from Colourful Hell Plus family 17, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\17\17_<code>.txt
// One CHP file per colour; the FIRST actor in each file is the creature
// (Common<Colour>Cybie). Every tier below was read out of its own CHP
// file -- separate sprite set, separate stats, separate attack kit.
// CH (decorate\CYBIES.txt) was consulted only where CHP leaves a state
// undefined; CHP defines all of them for this family, so nothing here
// is inherited behaviour.
//
//   tier CHP    parent (CH)    body   HP     what it actually is
//   T00  17_C   CommonCybie    CYBR    4000  vanilla cybie: rockets + stomp
//   T01  17_G   GreenCybie     CYBG    5000  green: splash rockets, wide fan
//   T02  17_B   BlueCybie      CYBB    5800  blue: lightning combo, art beam,
//                                            pain shockwave, 7-hit finisher
//   T03  17_CY  CyanCybie2     CARD    5280  cyan: hovers, ice spray / big ice,
//                                            phases out of pain
//   T04  17_P   PurpleCybie    CYBP    6400  royal: wave barrage, orb spam,
//                                            propane rocket, worry bomb
//   T05  17_Y   YellowCybie    SUPR    7777  legendary: rain of fire, volley,
//                                            disaster shower, HK escort
//   T06  17_A   AbyssCybie2    TERM   12000  liquidator: bubbles, waves,
//                                            railgun, abyss rockets
//   T07  17_F   FireBluCybie2  ANNI    6561  fireblu: twin missiles + dash,
//                                            pain splash
//   T08  17_BR  Browncybie2    8CYB    6001  composter: acid pools, slime
//                                            drills, the green detonation
//   T09  17_GY  Graycybie2     CYGY    8888  stone: rockslide, dirt volley,
//                                            ground wave, one buff
//   T10  17_R   RedCybie       MOLO   10000  Moloch: quake stomp, volcano
//                                            balls, nails, soul bombs, phase 2
//   T11  17_K   BlackCybie2    BSMT   16500  the Smith: hammer, hellshots,
//                                            lightning call, charge, summons
//   T12  17_W   WhiteCybie2    MMDR   21000  ROMERO: three phases, beams,
//                                            chain missiles, nukes, barons
//   TEX  17_KX  (none)         HSMI   24000  OBSIDIAN TYRANT: the Smith's EX
//                                            form. Three health phases, a
//                                            reflective charge, a healing
//                                            pentagram, and BigHell -- an
//                                            invulnerable eight-second wind-up
//                                            into the biggest single hit in
//                                            the family
//
// Tier stats are CHP's own Health/Speed/PainChance per file, applied
// through TierData below as multipliers off this class's Default.
//
// CHP CRUFT STRIPPED: NewIcon* spawns, the ACS Announce/Scripted states,
// CallACS/ACS_NamedExecute* (including the Death.Telefrag variants,
// which differ from Death only by an ACS call), A_GivetoChildren
// ("GoAway")/A_KillMaster/A_KillChildren (RS types its minions --
// ReleaseMinions() does that job), RandomLetterSpawner, A_SpawnParticle
// walls, A_SetTranslation calls into CH TRNSLATE names (every tier here
// ships bespoke art and sets Translation None anyway), and the CHP
// inventory tokens used as self-latches (now private int fields).
//
// DELIBERATE REDUCTIONS (cosmetic only, no attack dropped):
//   T00 the ACS "CH_Intercept" branch fires the same rocket the Miss2
//       branch does, so the third shot is simply that rocket.
//   T03 CyanCybieHover motes and the CH_Cirno death gag.
//   T06/T08/T10 splash/particle litter folded into the actors' own
//       animations in RS_cyberdemon_projectiles.zs.
//   T12 the RomeroCHWeak token (commented out in CHP itself).
// =====================================================================

class RS_Cyberdemon : RS_MonsterMaster replaces Cyberdemon
{
	// CHP user vars / inventory latches, rewritten as fields.
	private int rsSpamCombo;   // T02 SpamComboCB
	private int rsDoner;       // T05 + T09 User_Doner
	private int rsNoMore;      // T06 one-shot hardening below 6000
	private int rsPhaseIt;     // T10 User_PhaseIt
	private int rsDumDum;      // T11 User_DumDum (charge budget)
	private int rsOh1;         // T11 User_OH1
	private int rsPhase;       // T12 user_phase
	private int rsRomeroShield;// T12 RomeroCHProtect
	private int rsSupersmith;  // TEX User_Supersmith (the third-phase latch)
	// CHP's DewzanToken, used by two different tiers for two different
	// counters -- TEX's BigHell wind-up and T14's OVERDRIVE budget. One
	// field is safe: a monster is only ever one tier at a time, and both
	// users zero it on entry.
	private int rsDewzan;
	private int rsGlitchShield;// T14 RomeroCHProtect2 (one shield at a time)
	private int rsGlitchRound; // T14 glitch/winder round counter

	// Called by RS_RomeroEXShield when it expires, so the boss can cast
	// another one -- CHP does the same thing by taking RomeroCHProtect2
	// back off its master.
	void RS_ClearGlitchShield() { rsGlitchShield = 0; }

	// CHP writes T14's BFG volley out six shots at a time, dozens of
	// times over. Same six shots, one call.
	private void RS_BFGVolley(int spread)
	{
		A_SpawnProjectile("RS_RomeroEXSpamShots",  52,  30, spread);
		A_SpawnProjectile("RS_RomeroEXSpamShots2", 52,  30, spread);
		A_SpawnProjectile("RS_RomeroEXSpamShots2", 52,  30, spread);
		A_SpawnProjectile("RS_RomeroEXSpamShots2", 52, -30, spread);
		A_SpawnProjectile("RS_RomeroEXSpamShots2", 52, -30, -spread);
		A_SpawnProjectile("RS_RomeroEXSpamShots",  52, -30, -spread);
	}

	// The four wide random shots phase 2 prefixes every volley with.
	private void RS_BFGWide()
	{
		A_SpawnProjectile("RS_RomeroEXSpamShots",  52,  30, random(-15, 15));
		A_SpawnProjectile("RS_RomeroEXSpamShots2", 52,  30, random(-15, 15));
		A_SpawnProjectile("RS_RomeroEXSpamShots",  52, -30, random(-15, 15));
		A_SpawnProjectile("RS_RomeroEXSpamShots2", 52, -30, random(-15, 15));
	}

	Default
	{
		Health 4000;
		Radius 40;
		Height 110;
		Mass 1000;
		Speed 16;
		PainChance 20;
		Monster;
		Species "Cybie";
		RadiusDamageFactor 0.25;
		+BOSS +FLOORCLIP +BOSSDEATH MissileChanceMult 0.5;
		+DONTMORPH +DONTHARMSPECIES +NOFEAR
		-NORADIUSDMG
		SeeSound "cyber/sight";   PainSound "cyber/pain";
		DeathSound "cyber/death"; ActiveSound "cyber/active";
		Obituary "$OB_CYBORG";
		Tag "Cyberdemon";
	}

	// CHP's real per-colour numbers, read out of 17_*.txt. Converted to
	// multipliers off the Default block (Health 4000, Speed 16).
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 20; r.dmgMul = 1.0;
		int hp = 4000; int spd = 16;
		switch (t)
		{
			case 0:  hp = 4000;  spd = 16; r.painChance = 20; r.dmgMul = 1.0; break;
			case 1:  hp = 5000;  spd = 16; r.painChance = 16; r.dmgMul = 1.1; break;
			case 2:  hp = 5800;  spd = 18; r.painChance = 12; r.dmgMul = 1.2; break;
			case 3:  hp = 5280;  spd = 31; r.painChance = 32; r.dmgMul = 1.3; break;
			case 4:  hp = 6400;  spd = 13; r.painChance = 16; r.dmgMul = 1.4; break;
			// PainChance 0, NOT 20. Neither CommonYellowCybie (17_Y.txt:1)
			// nor its CH parent Yellowcybie (CYBIES.txt:2991) states
			// PainChance at all, so CHP's effective value is the engine
			// default 0. The 20 was this class's own Default leaking
			// through the row.
			case 5:  hp = 7777;  spd = 19; r.painChance = 0;  r.dmgMul = 1.5; break;
			case 6:  hp = 12000; spd = 15; r.painChance = 8;  r.dmgMul = 1.8; break;
			case 7:  hp = 6561;  spd = 19; r.painChance = 16; r.dmgMul = 1.5; break;
			case 8:  hp = 6001;  spd = 17; r.painChance = 12; r.dmgMul = 1.5; break;
			case 9:  hp = 8888;  spd = 13; r.painChance = 0;  r.dmgMul = 1.6; break;
			case 10: hp = 10000; spd = 20; r.painChance = 15; r.dmgMul = 2.0; break;
			case 11: hp = 16500; spd = 17; r.painChance = 16; r.dmgMul = 2.5; break;
			case 12: hp = 21000; spd = 18; r.painChance = 20; r.dmgMul = 3.0; break;
			// TEX (13) -- 17_KX's own numbers, not an extrapolation.
			case 13: hp = 24000; spd = 20; r.painChance = 10; r.dmgMul = 3.5; break;
			// T14 -- 17_WX, absolute (r.hp / r.speed). 32767 is CHP's real
			// number: one short of a signed 16-bit overflow, which is the
			// joke. PainChance 0 -- it does not flinch.
			case 14: r.hp = 32767; r.speed = 24; r.painChance = 0; r.dmgMul = 4.0; return true;
			default: return false;
		}
		r.hpMul  = double(hp) / 4000.0;
		r.spdMul = double(spd) / 16.0;
		return true;
	}

	// CHP ships two cyberdemons above the thirteen CH colours.
	override int MaxTier() { return 14; }

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12  TEX  T14
		return "CYBR CYBG CYBB CARD CYBP SUPR TERM ANNI 8CYB CYGY MOLO BSMT MMDR HSMI MMDG";
	}

	// Bespoke artwork per colour -- no palette remap wanted. T14 is the
	// closest thing to an exception (MMDG is a corrupted MMDR), but CHP
	// ships it as its OWN sprite set rather than a Translation on the T12
	// body, so "-" is correct here too.
	override string TintTable()
	{
		return "- - - - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:cyberdemon role:boss delivery:heavy element:thermal mobility:ground";
	}

	// T11's portal roster (CHP PortalSummons_C) and T10's SummonPortalCybie.
	// Comparison chain, not a static const array -- those do not resolve
	// reliably on this build.
	private Class<Actor> CybiePortalPick(int i)
	{
		if (i <= 0) return "RS_HellKnight";
		if (i == 1) return "RS_Imp";
		if (i == 2) return "RS_Demon";
		if (i == 3) return "RS_CG_C0001";
		if (i == 4) return "RS_LostSoul";
		return "RS_Baron";
	}

	private void RS_GroundStance()
	{
		bFLOAT = false; bFLOATBOB = false; bNOGRAVITY = false;
	}

	// TEX is the only tier in this family that carries its own Scale and
	// MeleeRange (0.93 / 128, straight out of 17_KX's Default block).
	// MeleeRange is not cosmetic here -- the charge converts into the
	// hammer swing via A_JumpIfTargetInsideMeleeRange, so at the engine
	// default the Tyrant's signature attack would mostly whiff. Applied
	// from OnTierApplied rather than Spawn so the dial can reach TEX
	// mid-fight, and read back off the class defaults on the way out.
	override void OnTierApplied(int t)
	{
		let def = GetDefaultByType(GetClass());
		if (t == 13)   // TEX
		{
			A_SetScale(0.93, 0.93);
			meleerange = 128.0;
		}
		else if (t == 14)   // T14 -- 17_WX Scale 1.25, no melee of its own
		{
			A_SetScale(1.25, 1.25);
			meleerange = def.meleerange;
		}
		else
		{
			A_SetScale(def.scale.x, def.scale.y);
			meleerange = def.meleerange;
		}
	}

	States
	{
	// ================= T00 COMMON (17_C) =================
	// Vanilla cybie: three rockets and a hoof-stomp melee.
	Spawn.T00:
		"CYBR" AB 10 { A_Look(); }
		Loop;
	See.T00:
		TNT1 A 0 { RS_GroundStance(); }
		"CYBR" A 0 { A_Chase(); }
		"CYBR" A 3 { A_Hoof(); }
		"CYBR" ABBCC 3 { A_Chase(); }
		"CYBR" A 0 { A_Chase(); }
		"CYBR" D 3 { A_Metal(); }
		"CYBR" D 3 { A_Chase(); }
		Loop;
	Melee.T00:
		"CYBR" G 8;
		"CYBR" E 8 { A_CustomMeleeAttack(random(35, 90), "skeleton/melee", "none"); }
		"CYBR" E 1 { A_VileAttack("bomb/boom", 5, 5, 128, 1.75); }
		"CYBR" E 2 { A_RadiusThrust(3040, 400, RTF_NOTMISSILE); }
		Goto Missile.T00.Third;
	Missile.T00:
		"CYBR" E 6 { A_FaceTarget(); }
		"CYBR" F 12 Bright { A_SpawnProjectile("RS_Rocket", 42, -9, random(-1, 1)); }
		"CYBR" E 12 { A_FaceTarget(); }
		"CYBR" F 12 Bright { A_SpawnProjectile("RS_Rocket", 42, -9, random(-2, 2)); }
		"CYBR" E 12 { A_FaceTarget(); }
	Missile.T00.Third:
		// RESTORED (rs_19 / L5). CHP 17_C.txt:35-36 gates the THIRD rocket
		// behind CH_Intercept and fires CybMissile -- a ProjInt_Brute LED
		// shot. The import kept only the fallback, so the Cyberdemon has
		// always fired three dumb rockets instead of two dumb and one that
		// solves for where you are going.
		// CH spawns the led rocket from a DIFFERENT point than the other
		// two -- zoff 60 / xoff -25 against 42 / -9 for the dumb pair --
		// and that difference is CH's, kept rather than normalised.
		"CYBR" E 0
		{
			if (!FireLeadShot("RS_Rocket", 60.0, -25.0))
				return ResolveState("Missile.T00.Miss2");
			return ResolveState(null);
		}
		"CYBR" F 12 Bright;
		Goto See;
	Missile.T00.Miss2:
		"CYBR" F 12 Bright { A_SpawnProjectile("RS_Rocket", 42, -9, random(-4, 4)); }
		Goto See;
	Pain.T00:
		"CYBR" G 10 { A_Pain(); }
		Goto See;
	Death.T00:
		"CYBR" H 10;
		"CYBR" I 10 { A_Scream(); }
		"CYBR" JKL 10;
		"CYBR" M 10 { A_NoBlocking(); }
		"CYBR" NO 10;
		"CYBR" P 30;
		"CYBR" P -1 { A_BossDeath(); }
		Stop;

	// ================= T01 GREEN (17_G) =================
	// Splash rockets, ending in a two-rocket spread.
	Spawn.T01:
		"CYBG" AB 10 { A_Look(); }
		Loop;
	See.T01:
		TNT1 A 0 { RS_GroundStance(); }
		"CYBG" A 0 { A_Chase(); }
		"CYBG" A 3 { A_Hoof(); }
		"CYBG" ABBCC 3 { A_Chase(); }
		"CYBG" A 0 { A_Chase(); }
		"CYBG" D 3 { A_Metal(); }
		"CYBG" D 3 { A_Chase(); }
		Loop;
	Melee.T01:
		"CYBG" G 8;
		"CYBG" E 8 { A_CustomMeleeAttack(random(35, 90), "skeleton/melee", "none"); }
		"CYBG" E 1 { A_VileAttack("bomb/boom", 5, 5, 128, 1.75); }
		"CYBG" E 2 { A_RadiusThrust(3040, 400, RTF_NOTMISSILE); }
		Goto Missile.T01.Fan;
	Missile.T01:
		"CYBG" E 6 { A_FaceTarget(); }
		"CYBG" F 12 Bright { A_SpawnProjectile("RS_SplashRocket", 42, -9, random(-1, 1)); }
		"CYBG" E 10 { A_FaceTarget(); }
		"CYBG" F 12 Bright { A_SpawnProjectile("RS_SplashRocket", 42, -9, random(-4, 4)); }
		"CYBG" E 10 { A_FaceTarget(); }
	Missile.T01.Fan:
		"CYBG" F 12 Bright;
		"CYBG" F 0 { A_SpawnProjectile("RS_SplashRocket", 42, -9, random(1, 13)); }
		"CYBG" F 0 { A_SpawnProjectile("RS_SplashRocket", 42, -9, random(-13, -1)); }
		Goto See;
	Pain.T01:
		"CYBG" G 10 { A_Pain(); }
		Goto See;
	Death.T01:
		"CYBG" H 10;
		"CYBG" I 10 { A_Scream(); }
		"CYBG" JKL 10;
		"CYBG" M 10 { A_NoBlocking(); }
		"CYBG" NO 10;
		"CYBG" P 30;
		"CYBG" P -1 { A_BossDeath(); }
		Stop;

	// ================= T02 BLUE (17_B) =================
	// Lightning combo. Seven combo hits unlock the Finish burst; pain
	// has a one-in-four chance of a 160-bolt omnidirectional shockwave.
	Spawn.T02:
		"CYBB" AB 10 { A_Look(); }
		Loop;
	See.T02:
		TNT1 A 0 { RS_GroundStance(); }
		"CYBB" A 0 { A_Chase(); }
		"CYBB" A 3 { A_Hoof(); }
		"CYBB" ABBCC 3 { A_Chase(); }
		"CYBB" A 0 { A_Chase(); }
		"CYBB" D 3 { A_Metal(); }
		"CYBB" D 3 { A_Chase(); }
		Loop;
	Melee.T02:
		"CYBB" G 8;
		"CYBB" E 8 { A_CustomMeleeAttack(random(35, 90), "skeleton/melee", "none"); }
		"CYBB" E 1 { A_VileAttack("bomb/boom", 5, 5, 128, 1.65); }
		"CYBB" E 2 { A_RadiusThrust(8040, 400, RTF_NOTMISSILE); }
		Goto Missile.T02;
	Missile.T02:
		"CYBB" E 6 { A_FaceTarget(); }
		"CYBB" F 0 { A_StartSound("Spell/Lightn", CHAN_WEAPON, CHANF_DEFAULT, 1.0, 2.7); }
		"CYBB" F 3 Bright { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
		"CYBB" F 3 Bright { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
		"CYBB" F 0 { A_StartSound("Litn/litn2", CHAN_VOICE, CHANF_DEFAULT, 1.0, 2.5); }
		"CYBB" F 3 Bright { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
		"CYBB" F 5 Bright { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
	Missile.T02.Combo:
		"CYBB" E 5 { A_FaceTarget(); }
		"CYBB" F 1 Bright { A_FaceTarget(); }
		"CYBB" F 0 { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
		"CYBB" F 2 Bright { A_SpawnProjectile("RS_SwooshCB", 60, -17, random(-4, 4)); }
		"CYBB" F 5 Bright { A_FaceTarget(); }
		"CYBB" F 0 { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
		"CYBB" F 2 Bright { A_SpawnProjectile("RS_SwooshCB", 60, -17, random(-7, 7)); }
		"CYBB" F 5 Bright { A_FaceTarget(); }
		"CYBB" F 0 { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
		"CYBB" F 2 Bright { A_SpawnProjectile("RS_SwooshCB", 60, -17, random(-1, 1)); }
		"CYBB" F 0 { if (rsSpamCombo >= 7) return ResolveState("Missile.T02.Finish"); return ResolveState(null); }
		"CYBB" F 0 { rsSpamCombo++; }
		"CYBB" F 1 Bright A_MonsterRefire(80, "See");
		TNT1 A 0 A_Jump(82, "Missile.T02.Art");
		Goto Missile.T02.Combo;
	Missile.T02.Art:
		"CYBB" F 0 { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
		"CYBB" F 6 Bright { A_SpawnProjectile("RS_BluCybFX", 66, -15, 0); }
		"CYBB" F 4 Bright { A_SpawnProjectile("RS_BluCybFX", 72, -13, 0); }
		"CYBB" G 3 Bright { A_SpawnProjectile("RS_BluCybFX", 78, -11, 0); }
		"CYBB" G 10 Bright { A_SpawnProjectile("RS_BluCybFX", 84, -9, 0); }
		"CYBB" G 0 { A_SpawnProjectile("RS_BluCybArt", 60, -17, random(-20, 20)); }
		"CYBB" G 8 Bright { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
		"CYBB" F 6 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T02.Finish:
		"CYBB" G 0 { bNOPAIN = true; }
		"CYBB" G 2 { A_StartSound("cyber/sight", CHAN_VOICE); }
		"CYBB" G 6 { A_SpawnProjectile("RS_BluCybFX", 54, -17, 0); }
		"CYBB" E 6 { A_FaceTarget(); }
		"CYBB" F 0 { A_StartSound("Spell/Lightn", CHAN_WEAPON, CHANF_DEFAULT, 1.0, 3); }
		"CYBB" F 4 Bright { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
		"CYBB" F 4 Bright { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
		"CYBB" F 6 Bright { A_FaceTarget(); }
		"CYBB" F 0 { A_StartSound("Spell/Lightn", CHAN_WEAPON, CHANF_DEFAULT, 1.0, 2.7); }
		"CYBB" F 4 Bright { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
		"CYBB" F 4 Bright { A_SpawnProjectile("RS_BluCybFX", 60, -17, 0); }
		"CYBB" F 2 Bright { A_SpawnProjectile("RS_SwooshCB2", 60, -17, 0); }
		"CYBB" F 0 { rsSpamCombo = 0; }
		"CYBB" G 0 { bNOPAIN = false; }
		Goto See;
	Pain.T02:
		"CYBB" G 10 { A_Pain(); }
		"CYBB" G 0 A_Jump(64, "Pain.T02.Shockwave");
		Goto See;
	Pain.T02.Shockwave:
		"CYBB" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_PlasmaBallSP5", 53, random(-12, 12), random(0, 360), CMF_AIMDIRECTION, random(0, 360)); }
		"CYBB" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_PlasmaBallSP5", 53, random(-12, 12), random(0, 360), CMF_AIMDIRECTION, random(0, 360)); }
		"CYBB" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_PlasmaBallSP5", 53, random(-12, 12), random(0, 360), CMF_AIMDIRECTION, random(0, 360)); }
		"CYBB" GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG 0 { A_SpawnProjectile("RS_PlasmaBallSP5", 53, random(-12, 12), random(0, 360), CMF_AIMDIRECTION, random(0, 360)); }
		"CYBB" G 4;
		Goto See;
	Death.T02:
		"CYBB" H 10;
		"CYBB" I 10 { A_Scream(); }
		"CYBB" JKL 10;
		"CYBB" M 10 { A_NoBlocking(); }
		"CYBB" NO 10;
		"CYBB" P 30;
		"CYBB" P -1 { A_BossDeath(); }
		Stop;

	// ================= T03 CYAN (17_CY) =================
	// Akinator: hovers, sprays ice at range, lobs big ice up close, and
	// phases backwards out of every pain state.
	Spawn.T03:
		"CARD" AB 4 Bright { A_Look(); }
		Loop;
	See.T03:
		TNT1 A 0 { bFLOAT = true; bFLOATBOB = true; bNOGRAVITY = true; }
	See.T03.Chase:
		"CARD" AB 4 { A_Chase(); }
		"CARD" A 0 A_Jump(12, "See.T03.Dodge");
		"CARD" AB 4 { A_Chase(); }
		"CARD" A 0 A_Jump(12, "See.T03.Dodge");
		Goto See.T03.Chase;
	See.T03.Dodge:
		"CARD" AB 3 { A_FastChase(); }
		"CARD" AB 3 { A_FastChase(); }
		Goto See.T03.Chase;
	See.T03.PhaseBack:
		"CARD" AAAAAAAAAA 0 { A_SpawnItemEx("RS_BaronCyanBombTrail", 0, 0, 32, random(4, 33), 0, random(-25, 25), random(0, 135), SXF_NOCHECKPOSITION); }
		"CARD" AAAAAAAAAA 0 { A_SpawnItemEx("RS_BaronCyanBombTrail", 0, 0, 32, random(4, 33), 0, random(-25, 25), random(135, 270), SXF_NOCHECKPOSITION); }
		"CARD" AAAAAAAAAA 0 { A_SpawnItemEx("RS_BaronCyanBombTrail", 0, 0, 32, random(4, 33), 0, random(-25, 25), random(270, 359), SXF_NOCHECKPOSITION); }
		"CARD" D 8 { double a = angle - randompick(180, 200, 160); A_ChangeVelocity(cos(a) * 20, sin(a) * 20, 0, CVF_REPLACE); }
		"CARD" D 8 { double a = angle - random(120, 240); A_ChangeVelocity(cos(a) * 20, sin(a) * 20, 0, CVF_REPLACE); }
		"CARD" D 8 { double a = angle - random(80, 280); A_ChangeVelocity(cos(a) * 20, sin(a) * 20, 0, CVF_REPLACE); }
		"CARD" D 8 { double a = angle - randompick(20, 0, 40); A_ChangeVelocity(cos(a) * 8.5, sin(a) * 8.5, 0, CVF_REPLACE); }
		"CARD" D 6 { bNOPAIN = true; }
		Goto See.T03.Chase;
	Missile.T03:
		"CARD" B 0 A_JumpIfCloser(1000, "Missile.T03.Barrage");
	Missile.T03.Spray:
		"CARD" C 6 { A_FaceTarget(); }
		"CARD" C 4 { A_SpawnProjectile("RS_CyanCybieGunFlare", 72, -30, 0); }
		"CARD" C 1 { A_FaceTarget(); }
		"CARD" DDDDDDDDDDDD 1 { A_SpawnProjectile("RS_CyanCybieSprayIce", 72, -30, random(-4, 4), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-2, 2)); }
		"CARD" DDDDDDDDDDDD 0 { A_SpawnProjectile("RS_CyanCybieSprayIce", 72, -30, random(-4, 4), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-2, 2)); }
		"CARD" DDDDDDDDDDDD 1 { A_SpawnProjectile("RS_CyanCybieSprayIce", 72, -30, random(-4, 4), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-2, 2)); }
		"CARD" DDDDDDDDDDDD 0 { A_SpawnProjectile("RS_CyanCybieSprayIce", 72, -30, random(-4, 4), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-2, 2)); }
		"CARD" C 1 { A_FaceTarget(); }
		"CARD" DDDDDDDDDD 1 { A_SpawnProjectile("RS_CyanCybieSprayIce", random(69, 75), -30, random(-2, 2), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-2, 2)); }
		"CARD" DDDDDDDDDD 0 { A_SpawnProjectile("RS_CyanCybieSprayIce", random(69, 75), -30, random(-2, 2), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-2, 2)); }
		"CARD" DDDDDDDDDD 1 { A_SpawnProjectile("RS_CyanCybieSprayIce", random(69, 75), -30, random(-2, 2), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-2, 2)); }
		"CARD" DDDDDDDDDD 0 { A_SpawnProjectile("RS_CyanCybieSprayIce", random(69, 75), -30, random(-2, 2), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-2, 2)); }
		"CARD" D 0 { bNOPAIN = false; }
		Goto See;
	Missile.T03.Barrage:
		"CARD" C 3 { A_FaceTarget(); }
		"CARD" C 3 { A_SpawnProjectile("RS_CyanCybieGunFlare", 72, -30, 0); }
		"CARD" D 8 { A_SpawnProjectile("RS_CyanCybieBigIce2", 72, -30, 0); }
		"CARD" C 3 { A_FaceTarget(); }
		"CARD" C 3 { A_SpawnProjectile("RS_CyanCybieGunFlare", 72, -30, 0); }
		"CARD" D 8 { A_SpawnProjectile("RS_CyanCybieBigIce", 72, -30, randompick(-5, 5)); }
		"CARD" C 3 { A_FaceTarget(); }
		"CARD" C 3 { A_SpawnProjectile("RS_CyanCybieGunFlare", 72, -30, 0); }
		"CARD" D 8 { A_SpawnProjectile("RS_CyanCybieBigIce", 72, -30, randompick(-15, 15, 7, 0, -7)); }
		"CARD" A 0 A_Jump(32, "Missile.T03.Spray");
		"CARD" C 3 { A_FaceTarget(); }
		"CARD" C 3 { A_SpawnProjectile("RS_CyanCybieGunFlare", 72, -30, 0); }
		"CARD" D 8 { A_SpawnProjectile("RS_CyanCybieBigIce3", 72, -30, randompick(-15, 15, 7, 0, -7)); }
		"CARD" D 0 { bNOPAIN = false; }
		Goto See;
	Pain.T03:
		"CARD" A 2;
		"CARD" A 2 { A_Pain(); }
		"CARD" A 2;
		Goto See.T03.PhaseBack;
	Death.T03:
		"CARD" E 0 { bFLOATBOB = false; ReleaseMinions(); }
		"CARD" E 8 Bright;
		"CARD" F 8 Bright { A_Scream(); }
		"CARD" G 8 Bright { A_NoBlocking(); }
		"CARD" HIJK 8 Bright;
		"CARD" L 8 Bright { A_BossDeath(); }
		Stop;

	// ================= T04 PURPLE (17_P) =================
	// Royal Cyber King: a two-round wave barrage, a long-range orb spam
	// that finishes with a worry bomb, and a propane rocket combo.
	Spawn.T04:
		"CYBP" AB 10 { A_Look(); }
		Loop;
	See.T04:
		TNT1 A 0 { RS_GroundStance(); }
		"CYBP" A 0 { A_Chase(); }
		"CYBP" A 3 { A_Hoof(); }
		"CYBP" ABBCC 3 { A_Chase(); }
		"CYBP" A 0 { A_Chase(); }
		"CYBP" D 3 { A_Metal(); }
		"CYBP" D 3 { A_Chase(); }
		Loop;
	Melee.T04:
		"CYBP" G 8;
		"CYBP" E 8 { A_CustomMeleeAttack(random(45, 90), "skeleton/melee", "none"); }
		"CYBP" E 1 { A_VileAttack("bomb/boom", 10, 10, 128, 1.75); }
		"CYBP" E 2 { A_RadiusThrust(3040, 400, RTF_NOTMISSILE); }
		Goto Missile.T04.RocketCombo;
	Missile.T04:
		"CYBP" E 6 { A_FaceTarget(); }
		"CYBP" E 0 A_JumpIfCloser(1200, "Missile.T04.BarrageOr");
		"CYBP" E 0 A_Jump(255, "Missile.T04.LongSpam");
		Goto See;
	Missile.T04.BarrageOr:
		"CYBP" E 0 A_Jump(255, "Missile.T04.Barrage", "Missile.T04.RocketCombo");
		Goto See;
	Missile.T04.Barrage:
		"CYBP" F 4 Bright { A_FaceTarget(); }
		"CYBP" F 0 { A_StartSound("Spell/SpellCast1", CHAN_5, CHANF_DEFAULT, 1.0, 3.1); }
		"CYBP" FFFF 0 { A_SpawnProjectile("RS_CBWave", 38, -8, random(-15, 15), 0, random(-15, 15)); }
		"CYBP" F 12 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-1, 1)); }
		"CYBP" FF 2 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-5, 5)); }
		"CYBP" FF 2 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-9, 9)); }
		"CYBP" FF 2 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-13, 13)); }
		"CYBP" FF 1 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-15, 15)); }
		"CYBP" FF 1 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-15, 15)); }
		"CYBP" FF 1 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-25, 25)); }
		"CYBP" G 8;
		"CYBP" E 12 { A_FaceTarget(); }
		"CYBP" F 0 { A_StartSound("Spell/SpellCast1", CHAN_5, CHANF_DEFAULT, 1.0, 3.1); }
		"CYBP" FFFF 0 { A_SpawnProjectile("RS_CBWave", 38, -8, random(-15, 15), 0, random(-15, 15)); }
		"CYBP" F 12 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-1, 1)); }
		"CYBP" FF 2 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-5, 5)); }
		"CYBP" FF 2 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-9, 9)); }
		"CYBP" FF 2 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-13, 13)); }
		"CYBP" FF 1 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-15, 15)); }
		"CYBP" FF 1 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-15, 15)); }
		"CYBP" FF 1 Bright { A_SpawnProjectile("RS_CBWave", 38, -8, random(-25, 25)); }
		Goto Missile.T04.RocketCombo;
	Missile.T04.LongSpam:
		"CYBP" E 0 A_JumpIfCloser(1200, "Missile.T04.RocketCombo");
		"CYBP" E 22 { A_FaceTarget(); }
		"CYBP" F 0 { A_StartSound("Spell/SpellCast1", CHAN_5, CHANF_DEFAULT, 1.0, 3.1); }
		"CYBP" F 3 Bright { A_SpawnProjectile("RS_OrbCB", 38, -8, -3); }
		"CYBP" F 2 Bright { A_SpawnProjectile("RS_OrbCB", 38, -8, 15); }
		"CYBP" F 2 Bright { A_SpawnProjectile("RS_OrbCB", 38, -8, -15); }
		"CYBP" F 1 Bright { A_SpawnProjectile("RS_OrbCB", 38, -8, 11); }
		"CYBP" F 1 Bright { A_SpawnProjectile("RS_OrbCB", 38, -8, -11); }
		"CYBP" F 1 Bright { A_SpawnProjectile("RS_OrbCB", 38, -8, 3); }
		"CYBP" E 4 Bright A_CheckSight("See");
		"CYBP" G 10;
		"CYBP" E 8 Bright { A_FaceTarget(); }
		"CYBP" E 4 Bright A_CheckSight("See");
		"CYBP" F 8 Bright { A_VileTarget("RS_PurpleWorryCB"); }
		"CYBP" E 8 A_MonsterRefire(64, "See");
		Goto Missile.T04.LongSpam;
	Missile.T04.RocketCombo:
		"CYBP" E 6 { A_FaceTarget(); }
		"CYBP" F 8 { A_SpawnProjectile("RS_Propane", 38, -8, random(-4, 4)); }
		Goto See;
	Pain.T04:
		"CYBP" G 10 { A_Pain(); }
		Goto See;
	Death.T04:
		"CYBP" H 10;
		"CYBP" I 10 { A_Scream(); }
		"CYBP" JKL 10;
		"CYBP" M 10 { A_NoBlocking(); }
		"CYBP" NO 10;
		"CYBP" P 30;
		"CYBP" P -1 { A_BossDeath(); }
		Stop;

	// ================= T05 YELLOW (17_Y) =================
	// Legendary Yellow: a sky-wide rain of fire, a triple-rocket volley,
	// a targeted disaster shower, and one panic escort of two hell
	// knights below 3500 HP.
	Spawn.T05:
		"SUPR" AB 10 { A_Look(); }
		Loop;
	See.T05:
		TNT1 A 0 { RS_GroundStance(); }
		"SUPR" A 0 { A_Chase(); }
		"SUPR" A 3 { A_Hoof(); }
		"SUPR" ABBCC 3 { A_Chase(); }
		"SUPR" A 0 { A_Chase(); }
		"SUPR" D 3 { A_Hoof(); }
		"SUPR" D 3;
		Loop;
	Missile.T05:
		"SUPR" E 1 A_JumpIfHealthLower(3500, "Missile.T05.BuffUp");
	Missile.T05.Pick:
		"SUPR" E 1 A_JumpIfCloser(800, "Missile.T05.RainOfFire");
		"SUPR" E 1 A_JumpIfCloser(1700, "Missile.T05.Missiles1");
		"SUPR" E 1 A_Jump(255, "Missile.T05.Disaster");
		Goto See;
	Missile.T05.RainOfFire:
		"SUPR" E 6 { A_FaceTarget(); }
		"SUPR" E 8 { A_StartSound("cyber/sight", CHAN_VOICE); }
		"SUPR" GGGGGGGGGG 1 { A_SpawnProjectile("RS_SparkPuff1", 68, -49, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SUPR" E 8;
		"SUPR" G 12 { A_SpawnProjectile("RS_CybieRainMaker", 100, 0, 0); }
		"SUPR" G 0 { A_SpawnProjectile("RS_CybieRainMaker", 100, 0, randompick(-30, 30)); }
		TNT1 AAA 0 { A_SpawnItemEx("RS_CybieRain", random(64, 128), random(-64, 64), 552, random(1, 15), 0, random(-12, 1), random(-15, 15)); }
		"SUPR" GG 1 { A_SpawnItemEx("RS_CybieRain", random(64, 256), random(-64, 64), 552, random(1, 15), 0, random(-12, 1), random(-33, 33)); }
		"SUPR" GG 1 { A_SpawnItemEx("RS_CybieRain", random(64, 176), random(-84, 84), 552, random(1, 15), 0, random(-12, 1), random(-15, 15)); }
		"SUPR" GGG 1 { A_SpawnItemEx("RS_CybieRain", random(128, 526), random(-88, 88), 552, random(1, 15), 0, random(-12, 1), random(-21, 21)); }
		"SUPR" GGG 1 { A_SpawnItemEx("RS_CybieRain", random(252, 728), random(-94, 94), 552, random(1, 15), 0, random(-12, 1), random(-26, 26)); }
		"SUPR" GG 1 { A_SpawnItemEx("RS_CybieRain", random(252, 528), random(-84, 84), 552, random(1, 15), 0, random(-12, 1), random(-15, 15)); }
		"SUPR" GGGG 1 { A_SpawnItemEx("RS_CybieRain", randompick(252, 528, 725, 912), random(-64, 64), 552, random(1, 15), 0, random(-12, 1), random(-15, 15)); }
		"SUPR" GGG 1 { A_SpawnItemEx("RS_CybieRain", randompick(528, 725, 912, 1028), random(-64, 64), 552, random(1, 15), 0, random(-12, 1), random(-15, 15)); }
		"SUPR" A 8;
		Goto See;
	Missile.T05.Missiles1:
		"SUPR" E 6 { A_FaceTarget(); }
		"SUPR" F 9;
		"SUPR" F 0 { A_SpawnProjectile("RS_Vollrey", 51, -45, 0); }
		"SUPR" F 0 { A_SpawnProjectile("RS_Vollrey2", 51, -48, -2); }
		"SUPR" F 0 { A_SpawnProjectile("RS_Vollrey2", 51, -42, 2); }
		Goto See;
	Missile.T05.Disaster:
		"SUPR" E 6 { A_FaceTarget(); }
		"SUPR" E 8 { A_StartSound("cyber/sight", CHAN_VOICE); }
		"SUPR" GGGGGGGGGG 1 { A_SpawnProjectile("RS_SparkPuff1", 68, -49, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SUPR" E 8;
		"SUPR" G 10 { A_VileTarget("RS_ShoweringCB"); }
		"SUPR" A 8;
		Goto See;
	Missile.T05.Disaster2:
		"SUPR" E 6 { A_FaceTarget(); }
		"SUPR" E 8 { A_StartSound("cyber/sight", CHAN_VOICE); }
		"SUPR" GGGGGGGGGG 1 { A_SpawnProjectile("RS_SparkPuff1", 68, -49, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SUPR" E 8;
		"SUPR" G 10 { A_VileTarget("RS_ShoweringCB"); }
		"SUPR" A 8;
		"SUPR" A 0 A_Jump(128, "Missile.T05.Disaster2");
		Goto See;
	Missile.T05.FirePower:
		"SUPR" E 6 { A_FaceTarget(); }
		"SUPR" E 8 { A_StartSound("cyber/sight", CHAN_VOICE); }
		"SUPR" GGGGGGGGGGGGGGGGGGGG 1 { A_SpawnProjectile("RS_SparkPuff1", 68, -49, random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"SUPR" E 6 { A_FaceTarget(); }
		"SUPR" F 9;
		"SUPR" F 0 { A_SpawnProjectile("RS_BBSP1", 54, -45, random(-12, 12)); }
		Goto Missile.T05.Missiles1;
	Missile.T05.BuffUp:
		"SUPR" E 0 { if (rsDoner >= 1) return ResolveState("Missile.T05.Nah"); return ResolveState(null); }
		"SUPR" E 8 { A_StartSound("cyber/sight", CHAN_VOICE); }
		"SUPR" G 12 { A_SpawnProjectile("RS_CybieRainMaker", 100, 0, 0); }
		"SUPR" G 12 { bMISSILEEVENMORE = true; }
		"SUPR" B 2 { bTHRUACTORS = true; }
		"SUPR" G 1 { SummonMinion("RS_HellKnight", 0, 88.0); }
		"SUPR" G 1 { SummonMinion("RS_HellKnight", 0, 88.0); }
		"SUPR" B 24;
		"SUPR" B 2 { bTHRUACTORS = false; }
		"SUPR" G 1 { rsDoner++; }
		Goto See;
	Missile.T05.Nah:
		"SUPR" E 0 A_JumpIfCloser(700, "Missile.T05.OrMaybe");
		"SUPR" E 0 A_JumpIfCloser(1500, "Missile.T05.Missiles1");
		"SUPR" E 0 A_Jump(255, "Missile.T05.Disaster2");
		Goto Missile.T05.Pick;
	Missile.T05.OrMaybe:
		"SUPR" E 0 A_Jump(255, "Missile.T05.RainOfFire", "Missile.T05.Missiles1", "Missile.T05.FirePower");
		Goto Missile.T05.Pick;
	// CHP 17_Y gives the yellow cybie no Pain cluster -- it does not
	// flinch. Kept as a zero-tic pass-through.
	Pain.T05:
		"SUPR" E 0;
		Goto See;
	Death.T05:
		"SUPR" A 0 { ReleaseMinions(); }
		"SUPR" H 6 { A_StartSound("superdemon/snarl", CHAN_VOICE); }
		"SUPR" H 0 { A_SpawnProjectile("RS_HKRedDeath", 90, -10, 0, CMF_AIMOFFSET, 10); }
		"SUPR" H 6;
		"SUPR" H 0 { A_SpawnProjectile("RS_HKRedDeath", 20, 30, 0, CMF_AIMOFFSET, 10); }
		"SUPR" I 6 { A_Scream(); }
		"SUPR" I 6;
		"SUPR" I 0 { A_SpawnProjectile("RS_HKRedDeath", 70, 10, 0, CMF_AIMOFFSET, 10); }
		"SUPR" J 6 { A_SpawnProjectile("RS_SuperDemonArm", 51, -50, -50); }
		"SUPR" J 0 { A_SpawnProjectile("RS_HKRedDeath", 20, 50, 0, CMF_AIMOFFSET, 10); }
		"SUPR" KL 6;
		"SUPR" L 0 { A_SpawnProjectile("RS_HKRedDeath", 10, -10, 0, CMF_AIMOFFSET, 10); }
		"SUPR" M 6 { A_StartSound("superdemon/crash", CHAN_VOICE); }
		"SUPR" N 6;
		"SUPR" O 6 { A_NoBlocking(); }
		"SUPR" O -1 { A_BossDeath(); }
		Stop;

	// ================= T06 ABYSS (17_A) =================
	// Unruly Liquidator: bubble volleys, twin abyss waves, a white
	// railgun and a three-rocket run. Below 6000 HP it stops flinching,
	// speeds up and gains MISSILEEVENMORE -- once.
	Spawn.T06:
		"TERM" AB 10 { A_Look(); }
		Loop;
	See.T06:
		TNT1 A 0 { RS_GroundStance(); }
		"TERM" A 0 { A_StartSound("AbyCyb/step", CHAN_BODY); }
		"TERM" A 4 { A_Chase(); }
		"TERM" A 0 { A_SpawnItemEx("RS_AbyssCybieDecoFlame", random(-16, 16), random(-16, 16), random(42, 66), random(1, 2), 0, random(1, 9), random(-359, 359)); }
		"TERM" A 4 { A_Chase(); }
		"TERM" AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(12, 76), random(1, 6), 0, random(1, 3), random(-359, 359)); }
		"TERM" B 4 { A_Chase(); }
		"TERM" A 0 { A_SpawnItemEx("RS_AbyssCybieDecoFlame", random(-16, 16), random(-16, 16), random(42, 66), random(1, 2), 0, random(1, 9), random(-359, 359)); }
		"TERM" B 4 { A_Chase(); }
		"TERM" AAA 0 { A_SpawnItemEx("RS_SplashAbyss", random(-8, 8), random(-8, 8), random(12, 76), random(1, 6), 0, random(1, 3), random(-359, 359)); }
		"TERM" C 0 { A_StartSound("AbyCyb/step", CHAN_BODY); }
		"TERM" C 4 { A_Chase(); }
		"TERM" A 0 { A_SpawnItemEx("RS_AbyssCybieDecoFlame", random(-16, 16), random(-16, 16), random(42, 66), random(1, 2), 0, random(1, 9), random(-359, 359)); }
		"TERM" C 4 { A_Chase(); }
		"TERM" D 4 { A_Chase(); }
		"TERM" D 4 { A_Chase(); }
		"TERM" A 0 A_Jump(64, "See.T06.Splash");
		Loop;
	See.T06.Splash:
		"TERM" A 0 A_CheckSight("See");
		"TERM" AA 0 { A_SpawnItemEx("RS_SplashAbyssBubbleDemon", random(-8, 128), random(-8, 128), random(5, 32), 11, 0, 2, random(-359, 359), SXF_NOCHECKPOSITION); }
		"TERM" A 0 A_Jump(64, "Missile.T06");
		Goto See;
	Missile.T06:
		"TERM" AAA 0 { A_SpawnItemEx("RS_SplashAbyssBubbleDemon", random(64, 1028), random(-128, 128), random(5, 32), 11, 0, 2, random(-90, 90), SXF_NOCHECKPOSITION); }
		"TERM" E 0 A_Jump(256, "Missile.T06.Bubble");
		"TERM" A 0 A_JumpIfCloser(300, "Missile.T06.Wave");
		"TERM" A 0 A_JumpIfCloser(1500, "Missile.T06.Choices");
	Missile.T06.RedDed:
		"TERM" J 1 { A_StartSound("AbyCyb/Atk", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"TERM" J 18 Bright { A_FaceTarget(); }
		"TERM" K 0 { A_StartSound("weapons/railgf", CHAN_WEAPON); }
		"TERM" K 8 Bright { A_CustomRailgun(random(20, 80), -20, "White", "White", RGF_NOPIERCING | RGF_SILENT, 1, 0, "RS_WhiteFatRB3", 0, 0, 0, 0, 0.4, 1.0, "RS_WhiteFatRB4", 1); }
		"TERM" J 6;
		"TERM" J 1 A_Jump(64, "Missile.T06.Rocket");
		Goto See;
	Missile.T06.Choices:
		"TERM" E 0 A_Jump(256, "Missile.T06.Bubble", "Missile.T06.Rocket", "Missile.T06.RedDed", "Missile.T06.Wave");
		Goto See;
	Missile.T06.Wave:
		"TERM" E 1 { A_StartSound("AbyCyb/Atk", CHAN_VOICE); }
		"TERM" EF 3 { A_FaceTarget(); }
		"TERM" F 1 Bright { A_SpawnProjectile("RS_AbyCybWave", 32, 30, random(5, 25)); }
		"TERM" F 1 Bright { A_SpawnProjectile("RS_AbyCybWave", 44, 0, random(-1, 1)); }
		"TERM" F 1 Bright { A_SpawnProjectile("RS_AbyCybWave", 30, -30, random(-25, -5)); }
		"TERM" F 1 Bright { A_SpawnProjectile("RS_AbyCybWave", 24, 0, random(-7, 7)); }
		"TERM" AAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(12, 32), random(-12, 12), random(12, 42), 11, 0, 4, random(-15, 15), SXF_NOCHECKPOSITION); }
		"TERM" EF 2;
		"TERM" JK 3 { A_FaceTarget(); }
		"TERM" K 1 Bright { A_SpawnProjectile("RS_AbyCybWave", 32, -30, random(10, 30)); }
		"TERM" K 1 Bright { A_SpawnProjectile("RS_AbyCybWave", 44, 0, random(-5, 5)); }
		"TERM" K 1 Bright { A_SpawnProjectile("RS_AbyCybWave", 32, 30, random(-30, -10)); }
		"TERM" K 1 Bright { A_SpawnProjectile("RS_AbyCybWave", 24, 0, random(-10, 10)); }
		"TERM" AAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(12, 32), random(-12, 12), random(12, 42), 11, 0, 4, random(-15, 15), SXF_NOCHECKPOSITION); }
		"TERM" KJ 2;
		"TERM" J 1 A_Jump(64, "Missile.T06.Choices");
		Goto See;
	Missile.T06.Rocket:
		"TERM" E 8 { A_FaceTarget(); }
		"TERM" F 8 Bright { A_SpawnProjectile("RS_AbyssCybRocket", 38, 15, 0, 0); }
		"TERM" AA 0 { A_SpawnItemEx("RS_SplashAbyssBubbleDemon", random(32, 528), random(-68, 68), random(5, 32), 11, 0, 2, random(-15, 15), SXF_NOCHECKPOSITION); }
		"TERM" E 8 { A_FaceTarget(); }
		"TERM" F 8 Bright { A_SpawnProjectile("RS_AbyssCybRocket", 38, 15, random(-8, 8), 0); }
		"TERM" AA 0 { A_SpawnItemEx("RS_SplashAbyssBubbleDemon", random(64, 528), random(-68, 68), random(5, 32), 11, 0, 2, random(-45, 45), SXF_NOCHECKPOSITION); }
		"TERM" E 8 { A_FaceTarget(); }
		"TERM" F 8 Bright { A_SpawnProjectile("RS_AbyssCybRocket", 38, 15, random(-15, 15), 0); }
		"TERM" AA 0 { A_SpawnItemEx("RS_SplashAbyssBubbleDemon", random(128, 756), random(-68, 68), random(5, 32), 11, 0, 2, random(-65, 65), SXF_NOCHECKPOSITION); }
		Goto See;
	Missile.T06.Bubble:
		"TERM" G 2 { A_FaceTarget(); }
	Missile.T06.BubbleLoop:
		"TERM" H 1 Bright { A_SpawnProjectile("RS_AbyCybBubProj", 38, 15, random(-9, 0)); }
		"TERM" H 1 Bright { A_StartSound("AbyCyb/Atk", CHAN_VOICE); }
		"TERM" G 2 { A_FaceTarget(); }
		"TERM" I 1 Bright { A_SpawnProjectile("RS_AbyCybBubProj", 38, 15, random(0, 9)); }
		"TERM" AAAA 0 { A_SpawnItemEx("RS_SplashAbyss2", random(12, 1028), random(-12, 12), random(5, 32), 11, 0, 3, random(-32, 32), SXF_NOCHECKPOSITION); }
		"TERM" I 1 Bright { A_StartSound("AbyCyb/Atk", CHAN_VOICE); }
		"TERM" G 0 A_Jump(32, "Missile.T06.Choices");
		"TERM" G 1 A_SpidRefire;
		Goto Missile.T06.BubbleLoop;
	Pain.T06:
		"TERM" L 3 A_JumpIfHealthLower(6000, "Pain.T06.NoMore");
		"TERM" L 3 { A_Pain(); }
		"TERM" L 3;
		Goto See;
	Pain.T06.NoMore:
		TNT1 A 0 { if (rsNoMore >= 1) return ResolveState("See"); return ResolveState(null); }
		"TERM" L 2;
		"TERM" L 2 { bNOPAIN = true; }
		"TERM" L 2 { A_SetSpeed(20); }
		"TERM" L 2 { bMISSILEEVENMORE = true; rsNoMore = 1; }
		Goto See;
	Death.T06:
		"TERM" M 6 { A_Scream(); }
		"TERM" N 7;
		"TERM" OPQ 7 Bright;
		"TERM" R 0 { A_FaceTarget(); }
		"TERM" R 0 { A_SpawnItemEx("RS_TerminatorHead", 15, 0, 125, 10, 0, 0, -170, SXF_NOCHECKPOSITION); }
		"TERM" R 0 { A_SpawnItemEx("RS_TerminatorShoulder", 60, 0, 100, 8, 0, 0, -70, SXF_NOCHECKPOSITION); }
		"TERM" R 7 Bright { A_SpawnItemEx("RS_TerminatorArm", 60, 0, 0, 3, 0, 0, -90, SXF_NOCHECKPOSITION); }
		"TERM" STUV 7 Bright;
		"TERM" W 7;
		"TERM" X 7 { A_Fall(); }
		"TERM" YZ 7;
		"TERM" [ -1 { A_BossDeath(); }
		Stop;

	// ================= T07 FIREBLU (17_F) =================
	// A twin fireblu missile as the staple, a dash that trails caco
	// balls up close, and a three-way splash on pain.
	Spawn.T07:
		"ANNI" AB 10 { A_Look(); }
		Loop;
	See.T07:
		TNT1 A 0 { RS_GroundStance(); }
		"ANNI" A 3 { A_StartSound("monster/anhoof", CHAN_BODY); }
		"ANNI" ABBCC 3 { A_Chase(); }
		"ANNI" D 3 { A_StartSound("monster/anhoof", CHAN_BODY); }
		"ANNI" D 3 { A_Chase(); }
		Loop;
	Melee.T07:
		"ANNI" G 8;
		"ANNI" E 7 { A_CustomMeleeAttack(random(70, 180), "skeleton/melee", "none"); }
		"ANNI" E 1 { A_VileAttack("bomb/boom", 5, 5, 128, 1.75); }
		"ANNI" E 2 { A_RadiusThrust(3040, 400); }
		Goto Missile.T07.One;
	Missile.T07:
		"ANNI" E 0 A_JumpIfCloser(900, "Missile.T07.Maybe");
		Goto Missile.T07.One;
	Missile.T07.Maybe:
		"ANNI" E 0 A_Jump(256, "Missile.T07.One", "Missile.T07.Two");
		Goto Missile.T07.One;
	Missile.T07.Two:
		"ANNI" G 0 A_JumpIfCloser(250, "Missile.T07.One");
		"ANNI" G 2 Bright { A_FaceTarget(); }
		"ANNI" G 0 { A_StartSound("Ice/Fly", CHAN_WEAPON); }
		"ANNI" G 2 Bright { A_Recoil(-72); }
		"ANNI" GGGGG 1 Bright { A_SpawnItemEx("RS_FireBluCacoBall2", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"ANNI" G 3 Bright { A_SpawnItemEx("RS_FireBluCacoBall2", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Goto Missile.T07.One;
	Missile.T07.One:
		"ANNI" E 6 { A_FaceTarget(); }
		"ANNI" F 0 { A_SpawnProjectile("RS_FireBluCybMiss", 42, 16, random(-1, 1)); }
		"ANNI" F 12 Bright { A_SpawnProjectile("RS_FireBluCybMiss", 42, -16, random(-1, 1)); }
		Goto See;
	Missile.T07.Splash:
		"ANNI" E 5 Bright;
		"ANNI" G 0 { A_SpawnProjectile("RS_FireBluCacoBall", 0, 0, 0); }
		"ANNI" G 0 { A_SpawnProjectile("RS_FireBluCacoBall", 0, 0, 120); }
		"ANNI" G 0 { A_SpawnProjectile("RS_FireBluCacoBall", 0, 0, 240); }
		"ANNI" G 3 Bright;
		Goto See;
	Pain.T07:
		"ANNI" G 10 { A_Pain(); }
		"ANNI" G 1 A_Jump(128, "Missile.T07.Splash");
		Goto See;
	Death.T07:
		"ANNI" H 10;
		"ANNI" I 10 { A_Scream(); }
		"ANNI" JKL 10;
		"ANNI" M 10 { A_NoBlocking(); }
		"ANNI" NO 10;
		"ANNI" P 30;
		"ANNI" P -1 { A_BossDeath(); }
		Stop;

	// ================= T08 BROWN (17_BR) =================
	// Composter Demon: a classic slime volley, an acid pool, a spread of
	// homing slime drills, and -- if you are close enough for it to feel
	// you -- the green detonation.
	Spawn.T08:
		"8CYB" AB 10 { A_Look(); }
		Loop;
	See.T08:
		TNT1 A 0 { RS_GroundStance(); }
		"8CYB" A 3 { A_StartSound("brownCybie/step", CHAN_BODY); }
		"8CYB" AA 0 { A_SpawnItemEx("RS_Splash11", random(-12, 12), random(-8, 8), random(24, 82)); }
		"8CYB" ABBCC 3 { A_Chase(); }
		"8CYB" AA 0 { A_SpawnItemEx("RS_Splash11", random(-12, 12), random(-8, 8), random(24, 82)); }
		"8CYB" D 3 { A_StartSound("brownCybie/step", CHAN_BODY); }
		"8CYB" D 3 { A_Chase(); }
		"8CYB" AA 0 { A_SpawnItemEx("RS_Splash11", random(-12, 12), random(-8, 8), random(24, 82)); }
		Loop;
	Missile.T08:
		"8CYB" A 1 A_JumpIfCloser(1200, "Missile.T08.FirstChoice");
	Missile.T08.Classic:
		"8CYB" A 0 A_Jump(32, "Missile.T08.PoolOfGoo");
		"8CYB" E 2 { A_StartSound("BROCYBA1", CHAN_WEAPON); }
		"8CYB" FFF 0 { A_SpawnItemEx("RS_Splash11", random(-8, 8), random(2, 8), random(48, 64), random(2, 9), 0, random(-3, 3), random(-25, 25)); }
		"8CYB" E 10 { A_FaceTarget(); }
		"8CYB" FFF 0 { A_SpawnProjectile("RS_GreenBalb2", random(61, 63), random(-10, -7), random(-12, 12), 0, random(-3, 3)); }
		"8CYB" FFFF 0 { A_SpawnItemEx("RS_GreenBalb2", random(-8, 8), random(12, 18), random(48, 64), random(8, 33), 0, random(1, 4), random(-15, 15)); }
		"8CYB" F 10 Bright { A_SpawnProjectile("RS_BrownCybBasic", 66, -15, random(-1, 1)); }
		"8CYB" E 5 { A_FaceTarget(); }
		"8CYB" FFF 0 { A_SpawnProjectile("RS_GreenBalb2", random(61, 63), random(-10, -7), random(-12, 12), 0, random(-3, 3)); }
		"8CYB" FFFF 0 { A_SpawnItemEx("RS_GreenBalb2", random(-8, 8), random(12, 18), random(48, 64), random(8, 33), 0, random(1, 4), random(-15, 15)); }
		"8CYB" F 8 Bright { A_SpawnProjectile("RS_BrownCybBasic", 66, -15, random(-4, 4)); }
		"8CYB" E 5 { A_FaceTarget(); }
		"8CYB" FFF 0 { A_SpawnProjectile("RS_GreenBalb2", random(61, 63), random(-10, -7), random(-12, 12), 0, random(-3, 3)); }
		"8CYB" FFFF 0 { A_SpawnItemEx("RS_GreenBalb2", random(-8, 8), random(12, 18), random(48, 64), random(8, 33), 0, random(1, 4), random(-15, 15)); }
		"8CYB" F 8 Bright { A_SpawnProjectile("RS_BrownCybBasic", 66, -15, random(-12, 12)); }
		"8CYB" EA 12;
		Goto See;
	Missile.T08.FirstChoice:
		TNT1 A 0 A_JumpIfCloser(600, "Missile.T08.BigBoom");
		TNT1 A 0 A_Jump(255, "Missile.T08.PoolOfGoo", "Missile.T08.PoolOfDrill", "Missile.T08.Classic");
		Goto See;
	Missile.T08.PoolOfGoo:
		"8CYB" A 2 { A_FaceTarget(); }
		"8CYB" E 2 { A_StartSound("BROCYBA2", CHAN_WEAPON); }
		"8CYB" FGI 10 Bright;
		"8CYB" FFFFFFFFFFFFF 0 { A_SpawnItemEx("RS_Splash11", random(4, 8), random(-8, 8), random(48, 128), random(2, 9), 0, random(1, 7), random(-25, 25)); }
		"8CYB" FFFFFFFFFFFFF 0 { A_SpawnItemEx("RS_Splash11", random(4, 8), random(-8, 8), random(48, 128), random(2, 9), 0, random(1, 7), random(-5, 5)); }
		"8CYB" A 0 { A_VileTarget("RS_BCybAcidPuddle"); }
		"8CYB" HE 8 Bright;
		Goto See;
	Missile.T08.PoolOfDrill:
		"8CYB" A 2 { A_FaceTarget(); }
		"8CYB" E 2 { A_StartSound("BROCYBA1", CHAN_WEAPON); }
		"8CYB" F 10 Bright { A_SpawnItemEx("RS_BCybieGreenWave", 0, 0, 8, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"8CYB" GI 10 Bright;
		"8CYB" K 0 { A_SpawnProjectile("RS_BCybSlimeSet", 32, 0, 0); }
		"8CYB" K 0 { A_SpawnProjectile("RS_BCybSlimeSet", 32, 0, random(12, 20)); }
		"8CYB" K 0 { A_SpawnProjectile("RS_BCybSlimeSet", 32, 0, random(-20, -12)); }
		"8CYB" K 0 { A_SpawnProjectile("RS_BCybSlimeSet", 32, 0, random(20, 45)); }
		"8CYB" K 0 { A_SpawnProjectile("RS_BCybSlimeSet", 32, 0, random(-45, -20)); }
		"8CYB" HE 8 Bright;
		Goto See;
	Melee.T08:
	Missile.T08.BigBoom:
		// CHP checks a RadiusGive token to see whether anyone is inside
		// the blast; the check is the distance test itself here.
		"8CYB" A 1 A_JumpIfCloser(500, "Missile.T08.YesBoom");
		"8CYB" A 0 A_Jump(255, "Missile.T08.PoolOfDrill", "Missile.T08.Classic");
		Goto Missile.T08;
	Missile.T08.YesBoom:
		"8CYB" A 5 { A_FaceTarget(); }
		"8CYB" A 0 { A_StartSound("BROCYBA2", CHAN_WEAPON); }
		"8CYB" A 0 { A_SpawnItemEx("RS_BCybieGreenExpand", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERSCALE); }
		"8CYB" GHIJK 5 Bright;
		"8CYB" A 0 { A_SpawnItemEx("RS_BCybieGreenExpand", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERSCALE); }
		"8CYB" K 1 Bright { bNOPAIN = true; }
		"8CYB" KKKK 5 Bright;
		"8CYB" A 0 { A_SpawnItemEx("RS_BCybieGreenExpand", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERSCALE); }
		"8CYB" K 3 Bright { A_SpawnItemEx("RS_BCybieGreenWave", 0, 0, 8, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"8CYB" K 9 Bright { A_FaceTarget(); }
		"8CYB" A 0 { A_StartSound("brownCybie/DeepShot", CHAN_WEAPON); }
		"8CYB" K 0 { A_SpawnItemEx("RS_BCybExplosionSet2", 32, 0, 16, 0, 0, 0, 0, SXF_SETMASTER); }
		"8CYB" K 0 { A_SpawnItemEx("RS_BCybExplosionSet", 32, 0, 16, 0, 0, 0, 0, SXF_SETMASTER); }
		"8CYB" K 0 { A_SpawnProjectile("RS_BCybExplosionSet3", 32, 0, 0, CMF_AIMDIRECTION, 0); }
		"8CYB" K 0 { A_SpawnProjectile("RS_BCybExplosionSet3", 32, 0, 90, CMF_AIMDIRECTION, 0); }
		"8CYB" K 0 { A_SpawnProjectile("RS_BCybExplosionSet3", 32, 0, 180, CMF_AIMDIRECTION, 0); }
		"8CYB" K 0 { A_SpawnProjectile("RS_BCybExplosionSet3", 32, 0, 270, CMF_AIMDIRECTION, 0); }
		"8CYB" A 0 { A_SpawnItemEx("RS_BCybieGreenExpand", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION | SXF_TRANSFERSCALE); }
		"8CYB" KKKK 10 Bright;
		"8CYB" JIHG 8 Bright;
		"8CYB" A 15 Bright { bNOPAIN = false; }
		"8CYB" A 0 A_Jump(64, "Missile.T08.PoolOfGoo", "Missile.T08.PoolOfDrill", "Missile.T08.Classic");
		Goto See;
	Pain.T08:
		"8CYB" A 15 { A_Pain(); }
		Goto See;
	Death.T08:
		"8CYB" A 0 { bDONTBLAST = true; bDONTTHRUST = true; ReleaseMinions(); }
		"8CYB" G 1 { A_NoBlocking(); }
		"8CYB" HHHH 8 { A_SpawnItemEx("RS_BCybieGreenWave2", random(-16, 16), random(-16, 16), random(8, 78), 0, 0, 0, 0); }
		"8CYB" IIIIJJJJ 7 { A_SpawnItemEx("RS_BCybieGreenWave2", random(-16, 16), random(-16, 16), random(8, 78), 0, 0, 0, 0); }
		"8CYB" KKKKKKKKKKK 3 { A_SpawnItemEx("RS_BCybieGreenWave2", random(-16, 16), random(-16, 16), random(8, 78), 0, 0, 0, 0); }
		"8CYB" A 0 { A_Scream(); }
		"8CYB" LMNO 6 { A_SpawnItemEx("RS_GreenBalb2", random(-8, 8), random(-8, 8), random(48, 64), random(2, 9), 0, random(1, 4), random(0, 359)); }
		"8CYB" P -1 { A_BossDeath(); }
		Stop;

	// ================= T09 GRAY (17_GY) =================
	// Stone Cybie: a marked rockslide, a dirt-rocket volley, a ground
	// wave sweep, and one speed/fire-rate buff below 3500 HP.
	Spawn.T09:
		"CYGY" AB 10 { A_Look(); }
		Loop;
	See.T09:
		TNT1 A 0 { RS_GroundStance(); }
		"CYGY" A 3 { A_Hoof(); }
		"CYGY" ABBCC 3 { A_Chase(); }
		"CYGY" D 3 { A_Hoof(); }
		"CYGY" D 3 { A_Chase(); }
		Loop;
	Missile.T09:
		"CYGY" E 1 A_JumpIfHealthLower(3500, "Missile.T09.BuffUp");
	Missile.T09.Pick:
		"CYGY" E 1 A_Jump(85, "Missile.T09.Missiles1");
		"CYGY" E 1 A_Jump(85, "Missile.T09.Missiles2");
		"CYGY" E 6 { A_FaceTarget(); }
		"CYGY" E 8 { A_StartSound("CybLow", CHAN_VOICE); }
		"CYGY" EG 8 { A_VileTarget("RS_CHBSTarget"); }
		"CYGY" G 2 { A_FaceTarget(); }
		"CYGY" G 0 A_CheckSight("See");
		"CYGY" G 12 { A_VileTarget("RS_RockSlideCH1"); }
		"CYGY" A 8;
		Goto See;
	Missile.T09.Missiles1:
		"CYGY" E 6 { A_FaceTarget(); }
		"CYGY" F 9;
		"CYGY" F 0 { A_SpawnProjectile("RS_BaronOfDirtCH3", 54, -45, 0); }
		"CYGY" F 0 { A_SpawnProjectile("RS_BaronOfDirtCH3", 54, -48, -8); }
		"CYGY" F 0 { A_SpawnProjectile("RS_BaronOfDirtCH3", 54, -42, 8); }
		"CYGY" F 0 A_Jump(128, "Missile.T09.Missiles1", "Missile.T09.Missiles2");
		Goto See;
	Missile.T09.Missiles2:
		"CYGY" F 6;
		"CYGY" EEEEEEEEE 0 { A_SpawnProjectile("RS_WhiteBaronGround", 32, 0, randompick(72, 56, 40, 32, 24, 16, 8, 0, -8, -16, -24, -32, -40, -56, -72)); }
		"CYGY" E 8;
		Goto See;
	Missile.T09.BuffUp:
		"CYGY" E 0 { if (rsDoner >= 1) return ResolveState("Missile.T09.Pick"); return ResolveState(null); }
		"CYGY" E 8 { A_StartSound("CybLow", CHAN_VOICE); }
		"CYGY" G 12 { A_Quake(8, 90, 256, 528); }
		"CYGY" G 12 { bMISSILEEVENMORE = true; }
		"CYGY" B 24;
		"CYGY" B 2 { A_SetSpeed(19); }
		"CYGY" G 1 { rsDoner++; }
		Goto See;
	Pain.T09:
		"CYGY" G 10 { A_Pain(); }
		Goto See;
	Death.T09:
		"CYGY" H 6 { A_StartSound("superdemon/snarl", CHAN_VOICE); }
		"CYGY" H 0 { A_SpawnProjectile("RS_HKRedDeath", 90, -10, 0, CMF_AIMOFFSET, 10); }
		"CYGY" H 6;
		"CYGY" H 0 { A_SpawnProjectile("RS_HKRedDeath", 20, 30, 0, CMF_AIMOFFSET, 10); }
		"CYGY" I 6 { A_Scream(); }
		"CYGY" I 6;
		"CYGY" I 0 { A_SpawnProjectile("RS_HKRedDeath", 70, 10, 0, CMF_AIMOFFSET, 10); }
		"CYGY" J 0 { A_SpawnProjectile("RS_HKRedDeath", 20, 50, 0, CMF_AIMOFFSET, 10); }
		"CYGY" KL 6;
		"CYGY" L 0 { A_SpawnProjectile("RS_HKRedDeath", 10, -10, 0, CMF_AIMOFFSET, 10); }
		"CYGY" M 6 { A_StartSound("superdemon/crash", CHAN_VOICE); }
		"CYGY" N 6;
		"CYGY" OOOOOOOOOOOOOOOOOOOOOO 1 { A_SpawnProjectile("RS_HKRedDeath", random(1, 50), random(-10, 30), random(0, 180), CMF_AIMOFFSET, 10); }
		"CYGY" O 1 { A_NoBlocking(); }
		"CYGY" O -1 { A_BossDeath(); }
		Stop;

	// ================= T10 RED (17_R) =================
	// Moloch: a 36-ray quake stomp for melee, soul bombs, a volcano
	// volley, nail spam and a portal summon. Below 5000 HP it erupts
	// into phase 2 and never leaves it.
	Spawn.T10:
		"MOLO" AB 10 { A_Look(); }
		Loop;
	See.T10:
		TNT1 A 0 { RS_GroundStance(); }
		"MOLO" AA 4 { A_Chase(); }
		"MOLO" AA 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(15, 80), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"MOLO" B 0 { A_StartSound("moloch/step", CHAN_BODY); }
		"MOLO" BB 4 { A_Chase(); }
		"MOLO" BB 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(15, 80), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"MOLO" CC 4 { A_Chase(); }
		"MOLO" CC 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(15, 80), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"MOLO" D 0 { A_StartSound("moloch/step", CHAN_BODY); }
		"MOLO" DD 4 { A_Chase(); }
		"MOLO" DD 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(15, 80), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		Loop;
	Melee.T10:
		"MOLO" H 10 { A_FaceTarget(); }
		"MOLO" J 4 { A_Quake(40, 60, 0, 40); }
		"MOLO" N 2 { A_StartSound("moloch/thud", CHAN_WEAPON); }
		"MOLO" N 0 { for (int i = 0; i < 18; i++) A_SpawnProjectile("RS_MolochQuake", 0, -48, i * 10); }
		"MOLO" J 2 { for (int i = 18; i < 36; i++) A_SpawnProjectile("RS_MolochQuake", 0, -48, i * 10); }
		"MOLO" A 4;
		Goto See;
	Missile.T10:
		"MOLO" A 0 { A_FaceTarget(); }
		TNT1 A 0 { if (rsPhaseIt >= 1) return ResolveState("Missile.T10.Phase2Jumps"); return ResolveState(null); }
		"MOLO" A 0 A_JumpIfHealthLower(5000, "Missile.T10.Phase2");
		"MOLO" A 0 A_Jump(256, "Missile.T10.One", "Missile.T10.Three", "Missile.T10.Two");
		Goto See;
	Missile.T10.Phase2Jumps:
		"MOLO" A 0 A_Jump(256, "Missile.T10.Five", "Missile.T10.Three", "Missile.T10.Two", "Missile.T10.Four");
		Goto See;
	Missile.T10.Phase2:
		"MOLO" H 1 { bNOPAIN = true; }
		"MOLO" H 10 { A_StartSound("moloch/phase2", CHAN_VOICE, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"MOLO" H 12 { bMISSILEEVENMORE = true; }
		"MOLO" H 2 { rsPhaseIt++; }
		"MOLO" HHHHHHHHH 5 { A_SpawnProjectile("RS_VolcanoBall1", random(20, 80), random(-40, 40), random(0, 360), CMF_AIMOFFSET, random(0, 360)); }
		"MOLO" I 12 Bright;
		"MOLO" I 8 { A_SetSpeed(28); bNOPAIN = false; }
		"MOLO" H 2;
		Goto Melee.T10;
	Missile.T10.One:
		"MOLO" H 0 { A_StartSound("moloch/attack", CHAN_WEAPON); }
		"MOLO" HH 14 { A_FaceTarget(); }
		"MOLO" I 10 { A_SpawnProjectile("RS_SoulBomb4", 55, 0, 0, 0); }
		"MOLO" I 0 A_Jump(70, "Missile.T10.One", "Missile.T10.Two", "Missile.T10.Three", "See");
		Goto See;
	Missile.T10.Two:
		TNT1 A 0 A_CheckSight("See");
		"MOLO" F 0 { A_StartSound("moloch/attack", CHAN_WEAPON); }
		"MOLO" F 12 { A_FaceTarget(); }
		"MOLO" EEEEE 2 { A_SpawnProjectile("RS_VolcanoBall3", 60, 0, random(-13, 13)); }
		"MOLO" E 0 { A_SpawnProjectile("RS_VolcanoBall2", 60, 0, random(-13, 13)); }
		"MOLO" H 12 { A_FaceTarget(); }
		"MOLO" H 4 { A_StartSound("moloch/sight", CHAN_VOICE); }
		"MOLO" II 6 { A_SpawnProjectile("RS_RedCybieVolcano1", 10, 0, random(-30, 30), CMF_AIMDIRECTION, random(-15, 20)); }
		"MOLO" F 0 A_Jump(70, "Missile.T10.One", "Missile.T10.Two", "Missile.T10.Three", "See");
		Goto See;
	Missile.T10.Three:
		"MOLO" F 0 { A_StartSound("moloch/attack", CHAN_WEAPON); }
		"MOLO" F 25 { A_FaceTarget(); }
	Missile.T10.ThreeLoop:
		"MOLO" E 1 { A_FaceTarget(); }
		"MOLO" G 1 { A_SpawnProjectile("RS_MolochNail", 55, random(-10, 10), random(-3, 3), 0); }
		"MOLO" G 0 { A_StartSound("moloch/nail", CHAN_WEAPON); }
		"MOLO" E 1 { A_FaceTarget(); }
		"MOLO" G 1 { A_SpawnProjectile("RS_MolochNail", 55, random(-10, 10), random(-9, 9), 0); }
		"MOLO" G 0 { A_StartSound("moloch/nail", CHAN_WEAPON); }
		"MOLO" G 0 A_Jump(10, "Missile.T10.One", "Missile.T10.Two", "Missile.T10.Three", "See");
		"MOLO" G 1 A_SpidRefire;
		Goto Missile.T10.ThreeLoop;
	Missile.T10.Four:
		"MOLO" H 0 { A_StartSound("moloch/attack", CHAN_WEAPON); }
		"MOLO" HH 14 { A_FaceTarget(); }
		TNT1 A 0 A_CheckSight("See");
		"MOLO" I 5 { A_FaceTarget(); }
		"MOLO" II 0 { SummonMinion(CybiePortalPick(random(0, 5)), -3, random(64, 128)); }
		"MOLO" I 5 { A_FaceTarget(); }
		"MOLO" I 0 A_Jump(70, "Missile.T10.Five", "Missile.T10.Two", "Missile.T10.Three", "Missile.T10.Four", "See");
		Goto See;
	Missile.T10.Five:
		"MOLO" H 0 { A_StartSound("moloch/attack", CHAN_WEAPON); }
		"MOLO" HH 14 { A_FaceTarget(); }
		"MOLO" I 10;
		"MOLO" I 0 { A_SpawnProjectile("RS_SoulBomb4", 55, 0, -9, 0); }
		"MOLO" I 0 { A_SpawnProjectile("RS_SoulBomb4", 55, 0, 0, 0); }
		"MOLO" I 0 { A_SpawnProjectile("RS_SoulBomb4", 55, 0, 9, 0); }
		"MOLO" I 0 A_Jump(70, "Missile.T10.Five", "Missile.T10.Two", "Missile.T10.Three", "Missile.T10.Four", "See");
		Goto See;
	Pain.T10:
		"MOLO" H 0 { A_Pain(); A_Quake(15, 15, 0, 40); }
		"MOLO" HHHHH 0 { A_SpawnItemEx("RS_RedThingsLS", random(-40, 40), random(-40, 40), random(10, 80), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"MOLO" H 10 A_Jump(74, "Melee.T10");
		Goto See;
	Death.T10:
		"MOLO" A 0 { ReleaseMinions(); }
		"MOLO" J 14 { A_ScreamAndUnblock(); }
		"MOLO" K 14;
		"MOLO" L 14;
		"MOLO" MNONMNONMNO 7 { A_SpawnItemEx("RS_RedThingsLS", random(-60, 60), random(-60, 60), random(5, 60), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"MOLO" PQ 6;
		"MOLO" Q 0 { A_Quake(40, 60, 0, 40); A_StartSound("moloch/thud", CHAN_WEAPON); }
		"MOLO" R -1 { A_BossDeath(); }
		Stop;

	// ================= T11 BLACK (17_K) =================
	// He Will Smith You: hammer swings, hellshot fans, a lightning call,
	// a reflective charge on a budget, a repositioning blink, and the
	// pentagram-and-quake melee. Below 10000 HP it opens portals once.
	Spawn.T11:
		"BSMT" AB 10 { A_Look(); }
		Loop;
	See.T11:
		TNT1 A 0 { RS_GroundStance(); bTHRUACTORS = false; A_UnSetReflectiveInvulnerable(); A_ScaleVelocity(1); A_SetSpeed(18); }
		"BSMT" A 0 A_CheckBlock("Pain.T11.Reposition", CBF_NOLINES);
		"BSMT" A 3 { A_StartSound("monster/fihoof", CHAN_5); }
		"BSMT" ABB 3 { A_Chase(); }
		"BSMT" C 3 { A_StartSound("monster/fihoof", CHAN_6); }
		"BSMT" CDD 3 { A_Chase(); }
		Loop;
	Missile.T11:
		"BSMT" A 0 A_Jump(128, "Missile.T11.Pick2");
		"BSMT" A 0 A_JumpIfCloser(650, "Missile.T11.Charge");
		"BSMT" A 0 { rsDumDum = max(0, rsDumDum - 1); }
		"BSMT" A 0 A_JumpIfHealthLower(10000, "Missile.T11.Phase2");
		"BSMT" A 0 A_Jump(256, "Missile.T11.One", "Missile.T11.Two", "Missile.T11.Lightning");
		Goto Missile.T11.Charge;
	Missile.T11.Pick2:
		"BSMT" A 0 A_Jump(128, "Missile.T11.One");
		Goto Missile.T11.Two;
	Missile.T11.Ph2:
		"BSMT" A 0 A_Jump(256, "Missile.T11.BigHell", "Missile.T11.HammerMega", "Missile.T11.Lightning", "Missile.T11.Summons");
		Goto See;
	Missile.T11.Phase2:
		TNT1 A 0 { if (rsOh1 >= 1) return ResolveState("Missile.T11.Ph2"); return ResolveState(null); }
		"BSMT" J 12 { A_FaceTarget(); }
		"BSMT" J 8 { bMISSILEMORE = true; }
		"BSMT" JJJJJJ 8 { SummonMinion(CybiePortalPick(random(0, 5)), -3, random(64, 178)); }
		"BSMT" J 2 { rsOh1++; }
		Goto See;
	Missile.T11.Summons:
		"BSMT" J 12 { A_StartSound("monster/fihoof", CHAN_5); }
		"BSMT" JJJJ 9 { SummonMinion(CybiePortalPick(random(0, 5)), -3, random(64, 178)); }
		Goto See;
	Missile.T11.HammerMega:
		"BSMT" J 6 { A_FaceTarget(); }
		"BSMT" K 1 { A_StartSound("monster/hamswg", CHAN_WEAPON); }
		"BSMT" M 2;
		"BSMT" NNNNNN 1 { A_SpawnProjectile("RS_HammerShot", 52, 0, random(-8, 8)); }
		"BSMT" K 5 { A_FaceTarget(); }
		"BSMT" L 8 { A_StartSound("monster/hamflr", CHAN_WEAPON); }
		"BSMT" IIIIIIIII 1 { A_SpawnProjectile("RS_HammerShot", 52, 0, random(-14, 14)); }
		Goto See;
	Missile.T11.BigHell:
		"BSMT" J 12 { A_FaceTarget(); }
		"BSMT" M 6 { A_StartSound("monster/hamswg", CHAN_WEAPON); }
		"BSMT" N 11 { A_SpawnProjectile("RS_BigHellshot", 52, 0, 0); }
		"BSMT" N 0 A_Jump(128, "Missile.T11.One");
		Goto See;
	Missile.T11.NoFire:
		"BSMT" O 0 { rsDumDum = max(0, rsDumDum - 2); }
		Goto Missile.T11.Pick2;
	Missile.T11.Charge:
		TNT1 A 0 { if (rsDumDum >= 11) return ResolveState("Missile.T11.NoFire"); rsDumDum += 5; return ResolveState(null); }
		"BSMT" O 1 { A_StartSound("weapons/suldth", CHAN_VOICE); }
		"BSMT" O 2 { A_SetReflectiveInvulnerable(); bTHRUACTORS = true; }
		"BSMT" O 12 { A_SkullAttack(35); }
		"BSMT" OOOOOOOO 1 { A_SpawnItemEx("RS_SmithGhost2", 0, 0, 0, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"BSMT" O 1 { A_SetSpeed(0); }
		"BSMT" O 1 { A_ScaleVelocity(0.05); bTHRUACTORS = false; }
		Goto Melee.T11;
	Missile.T11.One:
		"BSMT" E 6 { A_FaceTarget(); }
		"BSMT" H 6 { A_StartSound("monster/hamswg", CHAN_WEAPON); }
		"BSMT" I 0 { A_SpawnProjectile("RS_Hellshot2", 52, 0, 0); }
		"BSMT" I 0 { A_SpawnProjectile("RS_Hellshot2", 52, 0, 8); }
		"BSMT" I 12 { A_SpawnProjectile("RS_Hellshot2", 52, 0, -8); }
		"BSMT" B 6 A_CheckSight("See");
		"BSMT" J 6 { A_FaceTarget(); }
		"BSMT" M 6 { A_StartSound("monster/hamswg", CHAN_WEAPON); }
		"BSMT" N 0 { A_SpawnProjectile("RS_Hellshot2", 52, 0, 0); }
		"BSMT" N 0 { A_SpawnProjectile("RS_Hellshot2", 52, 0, 14); }
		"BSMT" N 11 { A_SpawnProjectile("RS_Hellshot2", 52, 0, -14); }
		Goto See;
	Missile.T11.Two:
		"BSMT" J 6 { A_FaceTarget(); }
		"BSMT" K 1 { A_StartSound("monster/hamswg", CHAN_WEAPON); }
		"BSMT" M 2;
		"BSMT" NNN 1 { A_SpawnProjectile("RS_HammerShot", 52, 0, random(-8, 8)); }
		"BSMT" K 5 { A_FaceTarget(); }
		"BSMT" L 10 { A_StartSound("monster/hamflr", CHAN_WEAPON); }
		"BSMT" III 2 { A_SpawnProjectile("RS_HammerShot", 52, 0, random(-14, 14)); }
		Goto See;
	Missile.T11.Lightning:
		"BSMT" P 8 { A_StartSound("Crack/death", CHAN_VOICE); }
		"BSMT" J 6 { A_FaceTarget(); }
		"BSMT" J 8 { A_SpawnProjectile("RS_Zap88", 100, -14, 0); }
		"BSMT" J 0 { A_StartSound("Crack/death", CHAN_VOICE); }
		"BSMT" J 1 { A_SpawnProjectile("RS_Zap88", 120, random(-28, 8), 0); }
		"BSMT" J 1 { A_SpawnProjectile("RS_Zap88", 135, random(-28, 8), 0); }
		"BSMT" J 0 { A_StartSound("Crack/death", CHAN_VOICE); }
		"BSMT" J 1 { A_SpawnProjectile("RS_Zap88", 150, random(-28, 8), 0); }
		"BSMT" J 1 { A_SpawnProjectile("RS_ZappersCB", 78, random(-2, 28), random(-180, 180)); }
		"BSMT" J 1 { A_SpawnProjectile("RS_ZappersCB", 78, random(-2, 28), random(-180, 180)); }
		Goto See;
	Melee.T11:
		"BSMT" E 0 { A_SetSpeed(18); }
		"BSMT" E 6 { A_FaceTarget(); }
		"BSMT" F 1 { A_StartSound("monster/hamswg", CHAN_WEAPON); }
		"BSMT" F 5 { A_FaceTarget(); }
		"BSMT" G 5 { A_CustomMeleeAttack(random(100, 250)); }
		"BSMT" E 0 { A_SetReflectiveInvulnerable(); A_Quake(40, 60, 0, 40); }
		"BSMT" F 0 { A_SpawnProjectile("RS_PentaLine1", 0, 0, -72, CMF_AIMDIRECTION); }
		"BSMT" F 0 { A_SpawnProjectile("RS_PentaLine1", 0, 0, -144, CMF_AIMDIRECTION); }
		"BSMT" F 0 { A_SpawnProjectile("RS_PentaLine1", 0, 0, -216, CMF_AIMDIRECTION); }
		"BSMT" F 0 { A_SpawnProjectile("RS_PentaLine1", 0, 0, -288, CMF_AIMDIRECTION); }
		"BSMT" F 0 { A_SpawnProjectile("RS_PentaLine1", 0, 0, 0, CMF_AIMDIRECTION); }
		"BSMT" G 1 { A_StartSound("monster/hamflr", CHAN_WEAPON); }
		"BSMT" N 0 { for (int i = 0; i < 18; i++) A_SpawnProjectile("RS_MolochQuake", 0, -48, i * 10); }
		"BSMT" N 0 { for (int i = 18; i < 36; i++) A_SpawnProjectile("RS_MolochQuake", 0, -48, i * 10); }
		"BSMT" GGGGGGGGGG 7;
		Goto See;
	Pain.T11:
		"BSMT" P 0 { A_SetSpeed(18); A_ScaleVelocity(1); }
		"BSMT" P 8 { A_Pain(); }
		"BSMT" P 0 A_Jump(64, "Pain.T11.Reposition", "Missile.T11");
		Goto See;
	Pain.T11.Reposition:
		"BSMT" O 0 { bNOPAIN = true; }
		"BSMT" P 12 { A_Quake(6, 100, 2, 64); }
		"BSMT" P 1 { A_SetTranslucent(0.5); }
		"BSMT" P 1 { A_SetTranslucent(0.3); }
		"BSMT" P 1 { A_SetTranslucent(0.1); }
		"BSMT" P 1 { A_SetTranslucent(0); }
		"BSMT" O 0 { bFLOAT = true; bTHRUACTORS = true; A_SetFloatSpeed(42); A_SetSpeed(42); }
		"BSMT" OOOOOO 1 { A_Wander(); }
		"BSMT" O 0 { bFLOAT = false; bTHRUACTORS = false; A_SetFloatSpeed(18); A_SetSpeed(18); }
		"BSMT" P 1 { A_SetTranslucent(0.1); }
		"BSMT" P 1 { A_Quake(6, 100, 2, 64); }
		"BSMT" P 1 { A_SetTranslucent(0.3); }
		"BSMT" P 1 { A_SetTranslucent(0.5); }
		"BSMT" P 1 { A_SetTranslucent(0.7); }
		"BSMT" P 1 { A_SetTranslucent(1); }
		"BSMT" P 8 { rsDumDum = max(0, rsDumDum - 6); bNOPAIN = false; }
		Goto See;
	Death.T11:
		TNT1 A 0 { ReleaseMinions(); }
		"BSMT" F 0 { A_SpawnProjectile("RS_PentaLine3", 0, 0, -72, CMF_AIMDIRECTION); }
		"BSMT" F 0 { A_SpawnProjectile("RS_PentaLine3", 0, 0, -144, CMF_AIMDIRECTION); }
		"BSMT" F 0 { A_SpawnProjectile("RS_PentaLine3", 0, 0, -216, CMF_AIMDIRECTION); }
		"BSMT" F 0 { A_SpawnProjectile("RS_PentaLine3", 0, 0, -288, CMF_AIMDIRECTION); }
		"BSMT" F 0 { A_SpawnProjectile("RS_PentaLine3", 0, 0, 0, CMF_AIMDIRECTION); }
		"BSMT" F 0 { A_Quake(6, 250, 2, 64); }
		"BSMT" P 250 { A_SpawnProjectile("RS_SmithDFSpawner", 0, 0, 0, 0); }
		"BSMT" Q 6 { A_SpawnProjectile("RS_SmithHammer", 128, -40, -30, 0); }
		"BSMT" Q 0 { A_SpawnProjectile("RS_SmithFire", 0, 0, 0, CMF_AIMDIRECTION); }
		"BSMT" R 6 { A_Scream(); }
		"BSMT" R 0 { A_SpawnProjectile("RS_SmithFire", 0, 0, 0, CMF_AIMDIRECTION); }
		"BSMT" STU 6;
		"BSMT" V 0 { A_SpawnProjectile("RS_SmithFire", 0, 0, 0, CMF_AIMDIRECTION); }
		"BSMT" V 6 { A_NoBlocking(); }
		"BSMT" VX 6;
		TNT1 A 0 { A_BossDeath(); }
		"BSMT" X 0 { A_SpawnProjectile("RS_SmithFire", 0, 0, 0, CMF_AIMDIRECTION); }
		"BSMT" Y -1;
		Stop;

	// ================= T12 WHITE (17_W) =================
	// "It runs doom": Romero. Three phases gated on health, a wall of
	// ground explosions at knife range, chain missiles, seeker fans, a
	// sweeping beam, orbital nukes, a shield, and baron escorts.
	Spawn.T12:
		"MMDR" E 10 { A_Look(); }
		Loop;
	See.T12:
		TNT1 A 0 { RS_GroundStance(); bTHRUACTORS = false; A_UnSetReflectiveInvulnerable(); A_ScaleVelocity(1); A_SetTranslucent(1); A_SetSpeed(18); }
		"MMDR" A 0 A_CheckBlock("Missile.T12.Reposition");
		"MMDR" AABBCCDD 3 { A_Chase(); }
		Loop;
	See.T12.Fast:
		TNT1 A 0 { bTHRUACTORS = false; A_UnSetReflectiveInvulnerable(); A_ScaleVelocity(1); A_SetTranslucent(1); A_SetSpeed(25); }
		"MMDR" A 0 A_CheckBlock("Missile.T12.Reposition");
		"MMDR" AABB 3 { A_Chase(); }
		TNT1 A 0 A_Jump(82, "See.T12.Oi");
		"MMDR" CCDD 3 { A_Chase(); }
		Loop;
	See.T12.Oi:
		"MMDR" CCDD 3 { A_FastChase(); }
		Goto See.T12.Fast;
	Missile.T12:
		TNT1 A 0 A_JumpIfHealthLower(8000, "Missile.T12.Phase3");
		TNT1 A 0 A_JumpIfHealthLower(15000, "Missile.T12.Phase2");
	Missile.T12.Set:
		TNT1 A 0 A_JumpIfCloser(200, "Missile.T12.Dukie", true);
		TNT1 A 0 A_JumpIfCloser(720, "Missile.T12.Close", true);
		TNT1 A 0 A_JumpIfCloser(1500, "Missile.T12.Med", true);
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("Missile.T12.Set3"); if (rsPhase >= 2) return ResolveState("Missile.T12.Set2"); return ResolveState(null); }
		"MMDR" E 0 A_Jump(256, "Missile.T12.ChainMissiles", "Missile.T12.BigLaser", "Missile.T12.SideWinder");
		Goto See;
	Missile.T12.Set2:
		"MMDR" E 0 A_Jump(256, "Missile.T12.ChainMissiles2", "Missile.T12.BigLaser", "Missile.T12.LaserRain", "Missile.T12.Reposition", "Missile.T12.SideWinder");
		Goto See;
	Missile.T12.Set3:
		"MMDR" E 0 A_Jump(256, "Missile.T12.ChainMissiles3", "Missile.T12.BigLaser2", "Missile.T12.LaserRain", "Missile.T12.FrontWinder", "Missile.T12.BaronsPlease");
		Goto See;
	Missile.T12.Phase2:
		TNT1 A 0 { if (rsPhase >= 2) return ResolveState("Missile.T12.Set"); return ResolveState(null); }
		"MMDR" E 0 { A_StartSound("Rome/PH2", CHAN_WEAPON, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"MMDR" E 10 Bright { A_FaceTarget(); }
		"MMDR" Z 8 Bright { A_FaceTarget(); }
		"MMDR" Y 5 Bright { A_FaceTarget(); }
		"MMDR" Y 0 { A_SpawnItemEx("TeleportFog", 0, 128, 18, 0, 0, 1, 0, SXF_NOCHECKPOSITION); }
		"MMDR" Y 0 { A_SpawnItemEx("TeleportFog", 0, -128, 18, 0, 0, 1, 0, SXF_NOCHECKPOSITION); }
		"MMDR" Y 0 { SummonMinion("RS_Baron", -2, 128.0); }
		"MMDR" Y 0 { SummonMinion("RS_Baron", -2, 128.0); }
		"MMDR" Y 20 Bright { A_FaceTarget(); }
		"MMDR" E 8 Bright { rsPhase = 2; }
		Goto Missile.T12.Dukie;
	Missile.T12.Phase3:
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("Missile.T12.Set"); return ResolveState(null); }
		"MMDR" E 0 { A_StartSound("Rome/PH3", CHAN_WEAPON, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"MMDR" E 10 Bright { A_FaceTarget(); }
		"MMDR" G 8 Bright { A_FaceTarget(); }
		"MMDR" I 5 Bright { A_FaceTarget(); }
		"MMDR" EIEGGIEGIGEIG 3 Bright { A_FaceTarget(); }
		"MMDR" E 3 { A_Quake(15, 15, 0, 40); }
		"MMDR" E 8 Bright { rsPhase = 3; }
		Goto Missile.T12.Reposition;
	Missile.T12.BaronsPlease:
		"MMDR" E 10 Bright { A_FaceTarget(); }
		"MMDR" Z 8 Bright { A_FaceTarget(); }
		"MMDR" Y 5 Bright { A_FaceTarget(); }
		"MMDR" Y 0 { A_SpawnItemEx("TeleportFog", 0, 128, 18, 0, 0, 1, 0, SXF_NOCHECKPOSITION); }
		"MMDR" Y 0 { A_SpawnItemEx("TeleportFog", 0, -128, 18, 0, 0, 1, 0, SXF_NOCHECKPOSITION); }
		"MMDR" Y 0 { SummonMinion("RS_Baron", -2, 128.0); }
		"MMDR" Y 0 { SummonMinion("RS_Baron", -2, 128.0); }
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("Missile.T12.BaronMore"); return ResolveState(null); }
		"MMDR" Y 10 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T12.BaronMore:
		"MMDR" YY 7 Bright { A_FaceTarget(); }
		"MMDR" Y 0 { A_SpawnItemEx("TeleportFog", 0, 218, 18, 0, 0, 1, 0, SXF_NOCHECKPOSITION); }
		"MMDR" Y 0 { A_SpawnItemEx("TeleportFog", 0, -218, 18, 0, 0, 1, 0, SXF_NOCHECKPOSITION); }
		"MMDR" Y 0 { SummonMinion("RS_Baron", -2, 218.0); }
		"MMDR" Y 0 { SummonMinion("RS_Baron", -2, 218.0); }
		"MMDR" Y 20 Bright { A_FaceTarget(); }
		Goto See.T12.Fast;
	Missile.T12.Reposition:
		"MMDR" O 0 { bNOPAIN = true; }
		"MMDR" E 12 { A_Quake(6, 100, 2, 64); }
		"MMDR" E 1 { A_SetTranslucent(0.5); }
		"MMDR" E 1 { A_SetTranslucent(0.3); }
		"MMDR" E 1 { A_SetTranslucent(0.1); }
		"MMDR" E 1 { A_SetTranslucent(0); }
		"MMDR" O 0 { bFLOAT = true; bNOGRAVITY = true; bTHRUACTORS = true; A_SetFloatSpeed(68); A_SetSpeed(68); }
		"MMDR" EEEEEEEE 3 { A_Wander(); }
		"MMDR" EEEEEEEE 2 { A_Wander(); }
		"MMDR" EEEEEEEE 1 { A_Wander(); }
		"MMDR" O 0 { bFLOAT = false; bNOGRAVITY = false; bTHRUACTORS = false; A_SetFloatSpeed(18); A_SetSpeed(18); }
		"MMDR" E 1 { A_SetTranslucent(0.1); }
		"MMDR" E 1 { A_Quake(6, 100, 2, 64); }
		"MMDR" E 1 { A_SetTranslucent(0.3); }
		"MMDR" E 1 { A_SetTranslucent(0.5); }
		"MMDR" E 1 { A_SetTranslucent(0.7); }
		"MMDR" E 9 { A_SetTranslucent(1); bNOPAIN = false; }
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("See.T12.Fast"); return ResolveState(null); }
		Goto See;
	Missile.T12.Med:
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("Missile.T12.Med3"); if (rsPhase >= 2) return ResolveState("Missile.T12.Med2"); return ResolveState(null); }
		TNT1 A 0 A_JumpIfCloser(1100, "Missile.T12.Rush", true);
		"MMDR" E 0 A_Jump(256, "Missile.T12.ChainMissiles", "Missile.T12.DualShots", "Missile.T12.Nukes");
		Goto See;
	Missile.T12.Med2:
		"MMDR" E 0 A_Jump(256, "Missile.T12.ChainMissiles2", "Missile.T12.DualShots", "Missile.T12.Nukes", "Missile.T12.SideWinder", "Missile.T12.Shield", "Missile.T12.LaserSweeper", "Missile.T12.LaserRain");
		Goto See;
	Missile.T12.Med3:
		TNT1 A 0 A_JumpIfCloser(1100, "Missile.T12.Rush", true);
		"MMDR" E 0 A_Jump(256, "Missile.T12.ChainMissiles3", "Missile.T12.DualShots", "Missile.T12.SideWinder", "Missile.T12.LaserSweeper", "Missile.T12.BigLaser2", "Missile.T12.BaronsPlease", "Missile.T12.FrontWinder", "Missile.T12.LaserRain");
		Goto See;
	Missile.T12.Close:
		TNT1 A 0 A_JumpIfCloser(200, "Missile.T12.Dukie", true);
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("Missile.T12.Close3"); if (rsPhase >= 2) return ResolveState("Missile.T12.Close2"); return ResolveState(null); }
		"MMDR" E 0 A_Jump(256, "Missile.T12.Nukes", "Missile.T12.ShotgunBreath", "Missile.T12.ChainMissiles");
		Goto See;
	Missile.T12.Close2:
		"MMDR" E 0 A_Jump(256, "Missile.T12.Nukes", "Missile.T12.ShotgunBreath", "Missile.T12.ChainMissiles2", "Missile.T12.Shield", "Missile.T12.LaserSweeper");
		Goto See;
	Missile.T12.Close3:
		"MMDR" E 0 A_Jump(256, "Missile.T12.Reposition", "Missile.T12.LaserSweeper", "Missile.T12.FrontWinder", "Missile.T12.ID");
		Goto See;
	Missile.T12.ID:
		"MMDR" E 0 { A_StartSound("Rome/ATK1", CHAN_WEAPON); }
		"MMDR" EEEE 5 { A_FaceTarget(); }
		"MMDR" E 5 Bright { A_FaceTarget(); }
		"MMDR" HIJKJHIKJKHMN 1 Bright { A_FaceTarget(); }
		TNT1 A 0 { for (int i = 0; i < 4; i++) { A_SpawnItemEx("RS_RomeroGroundCH", 128 + i * 64, -128, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		                                        A_SpawnItemEx("RS_RomeroGroundCH", 128 + i * 64, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		                                        A_SpawnItemEx("RS_RomeroGroundCH", 128 + i * 64, 128, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); } }
		TNT1 A 0 { for (int i = 0; i < 4; i++) { A_SpawnItemEx("RS_RomeroGroundCH", 350 + i * 64, -128, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		                                        A_SpawnItemEx("RS_RomeroGroundCH", 350 + i * 64, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		                                        A_SpawnItemEx("RS_RomeroGroundCH", 350 + i * 64, 128, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); } }
		"MMDR" O 3 Bright;
		Goto Missile.T12.FrontWinder;
	Missile.T12.Shield:
		"MMDR" E 5 Bright;
		TNT1 A 0 { if (rsRomeroShield >= 1) return ResolveState("Missile.T12"); rsRomeroShield = 1; return ResolveState(null); }
		"MMDR" EEEE 11 Bright { A_SpawnItemEx("RS_IDShieldWalk", 0, 4, 64, 0, 0, 0, 0, SXF_SETMASTER); }
		TNT1 A 0 A_Jump(64, "Missile.T12.BaronsPlease");
		Goto See;
	Missile.T12.FrontWinder:
		"MMDR" E 0 { A_StartSound("Rome/ATK1", CHAN_WEAPON); }
		"MMDR" E 10 Bright { A_FaceTarget(); }
		"MMDR" E 8 Bright { A_ChangeVelocity(0, 0, 25, CVF_REPLACE); }
		"MMDR" E 0 { bFLOAT = true; bNOGRAVITY = true; }
		"MMDR" E 8 Bright { A_FaceTarget(); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsRomeroCH", 52, 30, 1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 52, 33, 1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 52, 33, -1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 52, 27, 1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 52, 27, -1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 52, 27, 3); }
		"MMDR" F 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 52, 27, -3); }
		"MMDR" F 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 52, 27, 5); }
		"MMDR" F 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 52, 27, -5); }
		"MMDR" F 10 Bright { A_SpawnProjectile("RS_SpamShotsRomeroCH", 52, -30, -1); }
		"MMDR" E 5 { A_FaceTarget(); }
		Goto Missile.T12.Reposition;
	Missile.T12.SideWinder:
		"MMDR" E 0 { A_StartSound("Rome/ATK1", CHAN_WEAPON); }
		"MMDR" E 10 Bright { A_FaceTarget(); }
		"MMDR" Z 8 Bright { A_FaceTarget(); }
		"MMDR" Z 1 Bright { A_SpawnProjectile("RS_RomeroCHSeekBall", 61, 50, random(20, 50), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 61, -50, random(-50, -20), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Z 1 Bright { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, 50, random(20, 50), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, -50, random(-50, -20), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Z 1 Bright { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, 50, random(20, 50), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, -50, random(-50, -20), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Z 1 Bright { A_FaceTarget(); }
		"MMDR" Y 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, 50, random(20, 50), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 1 Bright { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, -50, random(-50, -20), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, 50, random(20, 50), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 1 Bright { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, -50, random(-50, -20), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 1 Bright { A_FaceTarget(); }
		"MMDR" Y 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, 50, random(20, 50), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 1 Bright { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, -50, random(-50, -20), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, 50, random(20, 50), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 1 Bright { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, -50, random(-50, -20), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 1 Bright { A_FaceTarget(); }
		"MMDR" Y 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, 50, random(20, 50), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 1 Bright { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, -50, random(-50, -20), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 0 { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, 50, random(20, 50), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 1 Bright { A_SpawnProjectile("RS_RomeroCHSeekBall", 60, -50, random(-50, -20), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDR" Y 1 Bright { A_FaceTarget(); }
		"MMDR" YZE 10 Bright { A_FaceTarget(); }
		TNT1 A 0 A_Jump(128, "Missile.T12.DualShots");
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("See.T12.Fast"); return ResolveState(null); }
		Goto See;
	Missile.T12.ShotgunBreath:
		"MMDR" E 0 { A_StartSound("Rome/ATK1", CHAN_WEAPON); }
		"MMDR" EEEE 5 { A_FaceTarget(); }
		"MMDR" E 5 Bright { A_FaceTarget(); }
		"MMDR" HIJKJHIKJKHMN 3 Bright { A_FaceTarget(); }
		"MMDR" OOOOOOOOOOOOOOOOOOOOOOO 0 { A_SpawnProjectile("RS_RomeroCHScatter", 60, 0, random(-12, 12), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-13, 13)); }
		"MMDR" O 3 Bright { A_SpawnProjectile("RS_RomeroCHScatter", 60, 0, random(-12, 12), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-13, 13)); }
	Missile.T12.DualShots:
		"MMDR" E 0 { A_StartSound("Rome/ATK1", CHAN_WEAPON); }
		"MMDR" EEEE 5 { A_FaceTarget(); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsRomeroCH", 52, 30, 1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 33, 1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 33, -1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 27, 1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 27, -1); }
		"MMDR" F 10 Bright { A_SpawnProjectile("RS_SpamShotsRomeroCH", 52, -30, -1); }
		"MMDR" E 5 { A_FaceTarget(); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsRomeroCH", 52, 30, 2); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 33, 2); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 33, -2); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 27, 2); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 27, -2); }
		"MMDR" F 8 Bright { A_SpawnProjectile("RS_SpamShotsRomeroCH", 52, -30, -2); }
		"MMDR" E 4 { A_FaceTarget(); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsRomeroCH", 52, 30, 1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 33, 1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 33, -1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 27, 1); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 27, -1); }
		"MMDR" F 6 Bright { A_SpawnProjectile("RS_SpamShotsRomeroCH", 52, -30, -1); }
		"MMDR" E 3 { A_FaceTarget(); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsRomeroCH", 52, 30, 0); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 33, 0); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 33, 0); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 27, 0); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 27, 0); }
		"MMDR" F 4 Bright { A_SpawnProjectile("RS_SpamShotsRomeroCH", 52, -30, 0); }
		"MMDR" E 2 { A_FaceTarget(); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsRomeroCH", 52, 30, 0); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 33, 0); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 33, 0); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 27, 0); }
		"MMDR" F 0 { A_SpawnProjectile("RS_SpamShotsCguy", 52, 27, 0); }
		"MMDR" F 2 Bright { A_SpawnProjectile("RS_SpamShotsRomeroCH", 52, -30, 0); }
		"MMDR" GG 3 Bright { A_FaceTarget(); }
		TNT1 A 0 A_Jump(32, "Missile.T12");
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("See.T12.Fast"); return ResolveState(null); }
		Goto See;
	Missile.T12.Rush:
		TNT1 A 0 A_Jump(32, "Missile.T12.BigLaser");
		TNT1 A 0 A_Jump(92, "Missile.T12.DualShots");
		"MMDR" E 0 { A_StartSound("Rome/ATK1", CHAN_WEAPON); }
		"MMDR" E 1 { A_StartSound("weapons/suldth", CHAN_VOICE); }
		"MMDR" E 2 { A_SetReflectiveInvulnerable(); bTHRUACTORS = true; }
		"MMDR" E 12 { A_SkullAttack(35); }
		"MMDR" E 1 { A_SetTranslucent(0.8); }
		"MMDR" E 1 { A_SetTranslucent(0.5); }
		"MMDR" E 1 { A_SetTranslucent(0.2); }
		"MMDR" E 1 { A_SetTranslucent(0.5); }
		"MMDR" E 1 { A_SetTranslucent(0.8); }
		"MMDR" E 1 { A_SetTranslucent(1); }
		"MMDR" E 1 { A_SetSpeed(0); }
		"MMDR" E 1 { A_ScaleVelocity(0.05); bTHRUACTORS = false; }
		TNT1 A 0 A_JumpIfCloser(200, "Missile.T12.Dukie", true);
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", -64, -64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", 64, -64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", -64, 64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 3 { A_SpawnItemEx("RS_RomeroGroundCH", 64, 64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", -164, -164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", 164, -164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", -164, 164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 3 { A_SpawnItemEx("RS_RomeroGroundCH", 164, 164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", -234, -234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", 234, -234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", -234, 234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 3 { A_SpawnItemEx("RS_RomeroGroundCH", 234, 234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("Missile.T12.DukieMore"); return ResolveState(null); }
		Goto See;
	Missile.T12.Dukie:
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", -64, -64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 64, -64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", -64, 64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 0, -64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 3 { A_SpawnItemEx("RS_RomeroGroundCH", 0, 64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", -64, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 64, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 64, 64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", 0, -164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 0, 164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", -164, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 164, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 3 { A_SpawnItemEx("RS_RomeroGroundCH", -164, -164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 164, -164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", -164, 164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 164, 164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", 0, -234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 0, 234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", -234, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 234, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 3 { A_SpawnItemEx("RS_RomeroGroundCH", -234, -234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 234, -234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", -234, 234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 234, 234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { if (rsPhase >= 2) return ResolveState("Missile.T12.DukieMore"); return ResolveState(null); }
		Goto See;
	Missile.T12.DukieMore:
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", 0, -314, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 0, 314, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", -314, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 314, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 2 { A_SpawnItemEx("RS_RomeroGroundCH", -314, -314, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 314, -314, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", -314, 314, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 314, 314, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", 0, -394, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 0, 394, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", -394, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 394, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 2 { A_SpawnItemEx("RS_RomeroGroundCH", -394, -394, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 394, -394, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", -394, 394, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 394, 394, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 0 { A_SpawnItemEx("RS_RomeroGroundCH", 0, -464, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 0, 464, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", -464, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 464, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" E 2 { A_SpawnItemEx("RS_RomeroGroundCH", -464, -464, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 464, -464, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", -464, 464, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		             A_SpawnItemEx("RS_RomeroGroundCH", 464, 464, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("See.T12.Fast"); return ResolveState(null); }
		Goto See;
	Missile.T12.Nukes:
		"MMDR" E 0 { A_StartSound("Rome/ATK2", CHAN_WEAPON); }
		"MMDR" E 10 Bright { A_FaceTarget(); }
		"MMDR" EEEEEEEEE 2 Bright { A_SpawnItemEx("RS_WhiteFatNukeShow", random(-24, 24), random(-24, 24), 64, 0, 0, 12, 0, SXF_NOCHECKPOSITION); }
		"MMDR" EEEEEEEEE 2 Bright { A_SpawnItemEx("RS_WhiteFatMark", random(-1524, 1524), random(-1524, 1524), 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		TNT1 A 0 { if (rsPhase >= 2) return ResolveState("Missile.T12.NukieFrontal"); return ResolveState(null); }
		"MMDR" A 10 A_Jump(128, "Missile.T12.DualShots", "Missile.T12.ChainMissiles");
		Goto See;
	Missile.T12.NukieFrontal:
		"MMDR" EEEEEEE 1 Bright { A_SpawnItemEx("RS_WhiteFatNukeShow", random(-24, 24), random(-24, 24), 64, 0, 0, 12, 0, SXF_NOCHECKPOSITION); }
		"MMDR" EEEEEEE 1 Bright { A_SpawnItemEx("RS_WhiteFatMark", random(256, 1524), random(-524, 524), 6, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDR" A 10 A_Jump(128, "Missile.T12.DualShots", "Missile.T12.ChainMissiles2", "Missile.T12.SideWinder");
		Goto See;
	Missile.T12.ChainMissiles:
		"MMDR" E 0 { A_StartSound("Rome/ATK1", CHAN_WEAPON); }
		"MMDR" E 10 { A_FaceTarget(); }
		"MMDR" HI 4 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 0); }
		"MMDR" HI 4 Bright { A_SpawnProjectile("RS_RomeroRocketCH2", 120, -20, random(-3, 3)); }
		"MMDR" HI 4 Bright { A_SpawnProjectile("RS_RomeroRocketCH2", 120, -20, 0); }
		"MMDR" HI 4 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-3, 3)); }
		"MMDR" HI 4 Bright { A_SpawnProjectile("RS_RomeroRocketCH3", 120, -20, 0); }
		TNT1 A 0 A_CheckSight("See");
		TNT1 A 0 A_Jump(32, "Missile.T12");
		Goto See;
	Missile.T12.ChainMissiles2:
		"MMDR" E 0 { A_StartSound("Rome/ATK1", CHAN_WEAPON); }
		"MMDR" E 10 { A_FaceTarget(); }
		"MMDR" HI 4 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 0); }
		"MMDR" HI 4 Bright { A_SpawnProjectile("RS_RomeroRocketCH2", 120, -20, random(-3, 3)); }
		"MMDR" HI 3 Bright { A_SpawnProjectile("RS_RomeroRocketCH2", 120, -20, 0); }
		"MMDR" HI 3 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-3, 3)); }
		"MMDR" HI 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH3", 120, -20, 0); }
		"MMDR" HI 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH3", 120, -20, 0); }
		"MMDR" HI 1 Bright { A_SpawnProjectile("RS_RomeroRocketCH2", 120, -20, random(-6, 6)); }
		"MMDR" HI 1 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-6, 6)); }
		TNT1 A 0 A_CheckSight("See");
		TNT1 A 0 A_Jump(64, "Missile.T12");
		Goto See;
	Missile.T12.ChainMissiles3:
		"MMDR" E 0 { A_StartSound("Rome/ATK1", CHAN_WEAPON); }
		"MMDR" E 10 { A_FaceTarget(); }
		"MMDR" HI 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 0); }
		"MMDR" HI 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH2", 120, -20, random(-3, 3)); }
		"MMDR" HI 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH2", 120, -20, 0); }
		"MMDR" HI 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-3, 3)); }
		"MMDR" HI 1 Bright { A_SpawnProjectile("RS_RomeroRocketCH3", 120, -20, 0); }
		"MMDR" HI 1 Bright { A_SpawnProjectile("RS_RomeroRocketCH3", 120, -20, 0); }
		"MMDR" HI 1 Bright { A_SpawnProjectile("RS_RomeroRocketCH2", 120, -20, random(-6, 6)); }
		"MMDR" HI 1 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-6, 6)); }
		TNT1 A 0 A_CheckSight("See.T12.Fast");
		TNT1 A 0 A_Jump(64, "Missile.T12");
		Goto See.T12.Fast;
	Missile.T12.LaserRain:
		"MMDR" E 0 { A_StartSound("Rome/ATK1", CHAN_WEAPON); }
		"MMDR" EEEE 3 { A_FaceTarget(); }
		"MMDR" JKLKJ 2 Bright { A_FaceTarget(); }
		"MMDR" JKLKJ 1 Bright { A_FaceTarget(); }
		"MMDR" MO 3 Bright;
		"MMDR" O 3 Bright { A_VileTarget("RS_RomeroSkyCH"); }
		Goto Missile.T12;
	Missile.T12.BigLaser:
		"MMDR" EEEE 3 { A_FaceTarget(); }
		"MMDR" E 0 { A_StartSound("Rome/ATK2", CHAN_WEAPON, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"MMDR" JKLKJ 3 Bright { A_FaceTarget(); }
		"MMDR" JKLKJ 2 Bright { A_FaceTarget(); }
		"MMDR" JKLKJJKLKJ 1 Bright { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(1000, "Missile.T12.SweepBeam", true);
		"MMDR" M 0 { A_StartSound("Rome/ATK2", CHAN_AUTO, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"MMDR" MNOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0); }
		Goto See;
	Missile.T12.BigLaser2:
		"MMDR" EEEE 2 { A_FaceTarget(); }
		"MMDR" E 0 { A_StartSound("Rome/ATK2", CHAN_WEAPON, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"MMDR" JKLKJ 2 Bright { A_FaceTarget(); }
		"MMDR" JKLKJJKLKJJKLKJ 1 Bright { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(1000, "Missile.T12.SweepBeam", true);
		"MMDR" MNOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" OOO 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" OOO 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" OOO 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0); }
		Goto See;
	Missile.T12.LaserSweeper:
		"MMDR" EEE 2 { A_FaceTarget(); }
		"MMDR" E 0 { A_StartSound("Rome/ATK2", CHAN_WEAPON, CHANF_DEFAULT, 1.0, ATTN_NONE); }
		"MMDR" JKLKJ 3 Bright { A_FaceTarget(); }
		"MMDR" JKLKJ 2 Bright { A_FaceTarget(); }
		"MMDR" JKLKJ 1 Bright { A_FaceTarget(); }
	Missile.T12.SweepBeam:
		"MMDR" M 1 Bright { A_FaceTarget(); }
		"MMDR" M 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -4); }
		"MMDR" N 1 Bright { A_FaceTarget(); }
		"MMDR" N 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -4); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" O 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -4); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" O 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -4); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" O 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -4); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" O 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -4); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" O 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -3); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" O 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -3); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" O 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -3); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" O 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -3); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" O 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -2); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" O 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -2); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" O 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -2); }
		"MMDR" O 1 Bright { A_FaceTarget(); }
		"MMDR" O 1 Bright { A_SpawnProjectile("RS_RomeroBeamCH", 60, 0, 0, 0, -2); }
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("See.T12.Fast"); return ResolveState(null); }
		Goto See;
	Pain.T12:
		"MMDR" E 3;
		"MMDR" E 3 { A_Pain(); }
		Goto See;
	Death.T12:
		TNT1 A 0 { A_SetTranslucent(1); ReleaseMinions(); }
		"MMDR" P 10 Bright { A_Scream(); }
		"MMDR" PPPPP 10 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"MMDR" QRS 10 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"MMDR" T 10 Bright { A_NoBlocking(); }
		"MMDR" UV 10 Bright;
		TNT1 A 0 { A_BossDeath(); }
		"MMDR" W -1;
		Stop;

	// ================= TEX BLACK EX (17_KX) =================
	// THE OBSIDIAN TYRANT. The Smith's EX form, and the only monster in
	// the family with three real health phases rather than one gate:
	//
	//   >14000  PH1 -- hellshot combo / lightning call / homing hell /
	//                  flame blast, plus the reflective charge on a budget
	//   <14000  Phase2 -- opens portals ONCE (rsOh1), then PH2: the pool
	//                  gains BigHell, Summons and the healing pentagram
	//   < 4000  Phase3 -- opens portals AGAIN and becomes SUPERSMITH
	//                  (rsSupersmith): walk speed up, unlimited charging,
	//                  lightning upgrades to the thrown bolt, and HealUP
	//                  unlocks
	//
	// The charge runs on rsDumDum, a budget that goes UP by 2 per charge
	// and DOWN by 1 per ranged pick and by 6 per reposition -- so a boss
	// that keeps closing runs out of charges and has to fight at range.
	// Supersmith ignores the budget entirely.
	//
	// CHP FILL: 17_KX's Charge branches to "NoFire" but never defines it
	// (CommonBlackCybieEX2 has no parent to inherit it from -- CHP's own
	// omission). Filled from 17_K's Smith, which is the same state in the
	// non-EX version: refund 2 budget and re-enter the attack roll.
	Spawn.TEX:
		"HSMI" A 0 { A_SetScale(0.93, 0.93); }
	Spawn.TEX.Look:
		"HSMI" AB 10 { A_Look(); }
		Loop;
	See.TEX:
		TNT1 A 0 { if (rsSupersmith >= 1) return ResolveState("See.TEX.Fast"); return ResolveState(null); }
		TNT1 A 0 { RS_GroundStance(); bTHRUACTORS = false; A_UnSetReflectiveInvulnerable(); A_ScaleVelocity(0); A_SetSpeed(20); }
		"HSMI" A 0 A_CheckBlock("Pain.TEX.Reposition", CBF_NOLINES);
		"HSMI" A 0 { A_StartSound("cyber/hoof", CHAN_5); }
		"HSMI" AABB 3 { A_Chase(); }
		"HSMI" C 0 { A_StartSound("cyber/hoof", CHAN_6); }
		"HSMI" CCDD 3 { A_Chase(); }
		"HSMI" D 0 A_Jump(2, "Pain.TEX.Reposition");
		Loop;
	// Supersmith walk -- same choreography, one third faster.
	See.TEX.Fast:
		TNT1 A 0 { RS_GroundStance(); bTHRUACTORS = false; A_UnSetReflectiveInvulnerable(); A_ScaleVelocity(0); A_SetSpeed(20); }
		"HSMI" A 0 A_CheckBlock("Pain.TEX.Reposition", CBF_NOLINES);
		"HSMI" A 0 { A_StartSound("cyber/hoof", CHAN_5); }
		"HSMI" AABB 2 { A_Chase(); }
		"HSMI" C 0 { A_StartSound("cyber/hoof", CHAN_6); }
		"HSMI" CCDD 2 { A_Chase(); }
		"HSMI" D 0 A_Jump(2, "Pain.TEX.Reposition");
		Loop;
	// The blink. Goes invulnerable, fades out, wanders at speed 99, fades
	// back in -- and refunds 6 charge budget on the way out.
	Pain.TEX.Reposition:
		"HSMI" O 0 { bNOPAIN = true; }
		"HSMI" O 6 { A_Quake(6, 100, 2, 64); }
		TNT1 A 0 { A_SetInvulnerable(); }
		"HSMI" O 1 { A_SetTranslucent(0.5); }
		"HSMI" O 1 { A_SetTranslucent(0.3); }
		"HSMI" O 1 { A_SetTranslucent(0.1); }
		"HSMI" O 1 { A_SetTranslucent(0); }
		"HSMI" O 0 { bFLOAT = true; bTHRUACTORS = true; A_SetFloatSpeed(99); A_SetSpeed(99); }
		"HSMI" OOOOOOOOOOOO 1 { A_Wander(); }
		"HSMI" O 0 { bFLOAT = false; bTHRUACTORS = false; A_SetFloatSpeed(20); A_SetSpeed(20); }
		"HSMI" O 1 { A_SetTranslucent(0.1); }
		"HSMI" O 1 { A_Quake(6, 100, 2, 64); }
		"HSMI" O 1 { A_SetTranslucent(0.3); }
		"HSMI" O 1 { A_SetTranslucent(0.5); }
		"HSMI" O 1 { A_SetTranslucent(0.7); }
		TNT1 A 0 { A_UnSetInvulnerable(); }
		"HSMI" O 1 { A_SetTranslucent(1); }
		"HSMI" O 4 { rsDumDum = max(0, rsDumDum - 6); }
		"HSMI" O 0 { bNOPAIN = false; }
		Goto See;
	// THE HAMMER. One swing for up to 250, then the pentagram, then a
	// 35-spoke quake ring and a 17-shot tracer fan along the floor.
	Melee.TEX:
		"HSMI" L 0 { A_ScaleVelocity(0.01); A_SetSpeed(20); }
		"HSMI" L 3 { A_FaceTarget(); }
		"HSMI" M 0 { A_StartSound("monster/hamswg", CHAN_WEAPON); }
		"HSMI" M 3 { A_FaceTarget(); }
		"HSMI" N 3 { A_CustomMeleeAttack(random(100, 250), "monster/hamhit"); }
		"HSMI" N 0 { A_SetReflectiveInvulnerable(); A_Quake(40, 60, 0, 40); }
		"HSMI" N 0 { A_SpawnProjectile("RS_PentaLine1", 0, 0, -72, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_PentaLine1", 0, 0, -144, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_PentaLine1", 0, 0, -216, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_PentaLine1", 0, 0, -288, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_PentaLine1", 0, 0, 0, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_StartSound("monster/hamflr", CHAN_WEAPON); }
		// CHP walks 0..160 then 180..350 in tens -- 170 is genuinely absent
		// from the source, so the ring has one gap in it. Kept.
		"HSMI" N 0 { for (int i = 0; i <= 16; i++) A_SpawnProjectile("RS_MolochQuake", 0, -48, i * 10); }
		"HSMI" N 0 { for (int i = 18; i <= 35; i++) A_SpawnProjectile("RS_MolochQuake", 0, -48, i * 10); }
		"HSMI" N 0 { for (int i = 0; i <= 8; i++) A_SpawnProjectile("RS_STracerEX", 0, 0, i * 5, 0); }
		"HSMI" N 0 { for (int i = 1; i <= 8; i++) A_SpawnProjectile("RS_STracerEX", 0, 0, -i * 5, 0); }
		"HSMI" NN 7;
		"HSMI" N 0 A_Jump(160, "Missile.TEX.Charge", "Missile.TEX.PH1");
		"HSMI" NNNNNN 7;
		Goto See;
	Missile.TEX:
		"HSMI" A 0 A_JumpIfHealthLower(4000, "Missile.TEX.Phase3");
	Missile.TEX.Retry:
		"HSMI" A 0 A_JumpIfHealthLower(14000, "Missile.TEX.Phase2");
		"HSMI" A 0 A_Jump(128, "Missile.TEX.Budget");
		"HSMI" A 0 A_JumpIfCloser(650, "Missile.TEX.Charge");
	Missile.TEX.Budget:
		"HSMI" A 0 { rsDumDum = max(0, rsDumDum - 1); }
	Missile.TEX.PH1:
		"HSMI" A 0 { A_UnSetReflectiveInvulnerable(); }
		"HSMI" A 0 { A_StartSound("hellsmith/laugh", CHAN_7, 0, 1.0, 0.6); }
		"HSMI" A 0 A_Jump(256, "Missile.TEX.HellShotCombo", "Missile.TEX.LightningCall", "Missile.TEX.HomingHell", "Missile.TEX.FlameBlast");
		Goto See;
	// Third phase: at knife range it prefers to charge, otherwise it drops
	// into the second-phase pool.
	Missile.TEX.PH3:
		"HSMI" A 0 A_JumpIfCloser(1250, "Missile.TEX.PH3Close");
		Goto Missile.TEX.PH2;
	Missile.TEX.PH3Close:
		"HSMI" N 0 A_Jump(160, "Missile.TEX.Charge");
		Goto Missile.TEX.PH2;
	Missile.TEX.PH2:
		"HSMI" A 0 A_Jump(128, "Missile.TEX.PH2Budget");
		"HSMI" A 0 A_JumpIfCloser(650, "Missile.TEX.Charge");
	Missile.TEX.PH2Budget:
		"HSMI" A 0 { rsDumDum = max(0, rsDumDum - 1); }
		"HSMI" A 0 { A_UnSetReflectiveInvulnerable(); }
		"HSMI" A 0 { A_StartSound("hellsmith/laugh", CHAN_7, 0, 1.0, 0.6); }
		"HSMI" A 0 A_Jump(80, "Missile.TEX.BigHell", "Missile.TEX.Summons", "Missile.TEX.LightningCall");
		"HSMI" A 0 A_JumpIfCloser(1500, "Missile.TEX.PH2Pool");
		"HSMI" A 0 A_Jump(112, "Missile.TEX.FlameBlast");
	Missile.TEX.PH2Pool:
		"HSMI" A 0 A_Jump(256, "Missile.TEX.HellShotCombo", "Missile.TEX.LightningThrow", "Missile.TEX.HomingHell", "Missile.TEX.FlameBlast", "Missile.TEX.HealUP");
		Goto See;
	// GATE 1 -- 14000 of 24000. Fires once, then PH2 forever.
	Missile.TEX.Phase2:
		TNT1 A 0 { if (rsOh1 >= 1) return ResolveState("Missile.TEX.PH2"); return ResolveState(null); }
		"HSMI" L 0 { A_StartSound("hellsmith/laugh", CHAN_VOICE, 0, 1.0, ATTN_NONE); }
		"HSMI" L 12 { A_FaceTarget(); }
		"HSMI" LLLLLL 8 { SummonMinion(CybiePortalPick(random(0, 5)), -3, random(64, 178)); }
		"HSMI" L 2 { rsOh1++; }
		Goto See;
	// GATE 2 -- 4000 of 24000, and it will not skip gate 1 to get here.
	Missile.TEX.Phase3:
		TNT1 A 0 { if (rsOh1 >= 1) return ResolveState("Missile.TEX.Phase3Go"); return ResolveState(null); }
		Goto Missile.TEX.Phase2;
	Missile.TEX.Phase3Go:
		TNT1 A 0 { if (rsSupersmith >= 1) return ResolveState("Missile.TEX.PH3"); return ResolveState(null); }
		"HSMI" L 0 { A_StartSound("hellsmith/laugh", CHAN_VOICE, 0, 1.0, ATTN_NONE); }
		"HSMI" L 12 { A_FaceTarget(); }
		"HSMI" LLLLLLLL 6 { SummonMinion(CybiePortalPick(random(0, 5)), -3, random(64, 178)); }
		"HSMI" L 2 { rsSupersmith++; }
		Goto See;
	// CHP fill from 17_K -- the budget-exhausted branch 17_KX forgot.
	Missile.TEX.NoFire:
		"HSMI" O 0 { rsDumDum = max(0, rsDumDum - 2); }
		Goto Missile.TEX.Retry;
	// THE CHARGE. Reflective-invulnerable and THRUACTORS for the ride, so
	// it cannot be shot out of it and cannot be body-blocked. Costs 2
	// budget; at 11 it is refused. Supersmith pays nothing.
	Missile.TEX.Charge:
		TNT1 A 0 { if (rsSupersmith >= 1) return ResolveState("Missile.TEX.ChargeGo"); return ResolveState(null); }
		TNT1 A 0 { if (rsDumDum >= 11) return ResolveState("Missile.TEX.NoFire"); return ResolveState(null); }
		"HSMI" G 0 { rsDumDum += 2; }
	Missile.TEX.ChargeGo:
		"HSMI" G 8 { A_FaceTarget(); }
		"HSMI" G 1 { A_StartSound("weapons/suldth", CHAN_VOICE); }
		"HSMI" G 2 { A_SetReflectiveInvulnerable(); }
		"HSMI" G 0 { bTHRUACTORS = true; }
		"HSMI" H 0 { A_SkullAttack(35); }
		"HSMI" HHHHHHHH 1 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 1 { A_SpawnItemEx("RS_HSGhostEX", 0, 0, 0, 0, 0, 0, 0, 128); }
		"HSMI" H 0 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 1 { A_SpawnItemEx("RS_HSGhostEX", 0, 0, 0, 0, 0, 0, 0, 128); }
		"HSMI" H 0 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 1 { A_SpawnItemEx("RS_HSGhostEX", 0, 0, 0, 0, 0, 0, 0, 128); }
		"HSMI" H 0 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 1 { A_SpawnItemEx("RS_HSGhostEX", 0, 0, 0, 0, 0, 0, 0, 128); }
		"HSMI" H 0 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 1 { A_SpawnItemEx("RS_HSGhostEX", 0, 0, 0, 0, 0, 0, 0, 128); }
		"HSMI" H 0 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 1 { A_SpawnItemEx("RS_HSGhostEX", 0, 0, 0, 0, 0, 0, 0, 128); }
		"HSMI" H 0 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 1 { A_SpawnItemEx("RS_HSGhostEX", 0, 0, 0, 0, 0, 0, 0, 128); }
		"HSMI" H 0 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 1 { A_SpawnItemEx("RS_HSGhostEX", 0, 0, 0, 0, 0, 0, 0, 128); }
		"HSMI" H 0 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 1 { A_SpawnItemEx("RS_HSGhostEX", 0, 0, 0, 0, 0, 0, 0, 128); }
		"HSMI" H 0 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 1 { A_SpawnItemEx("RS_HSGhostEX", 0, 0, 0, 0, 0, 0, 0, 128); }
		"HSMI" H 0 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 1 { A_SpawnItemEx("RS_HSGhostEX", 0, 0, 0, 0, 0, 0, 0, 128); }
		"HSMI" H 0 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 1 { A_SpawnItemEx("RS_HSGhostEX", 0, 0, 0, 0, 0, 0, 0, 128); }
		"HSMI" H 0 A_JumpIfTargetInsideMeleeRange("Melee.TEX");
		"HSMI" H 0 { A_SetSpeed(0); }
		"HSMI" H 1 { A_ScaleVelocity(0.01); }
		"HSMI" H 0 { bTHRUACTORS = false; }
		TNT1 A 0 { if (rsSupersmith >= 1) return ResolveState("Missile.TEX.Again"); return ResolveState(null); }
		"HSMI" H 0 A_Jump(96, "Missile.TEX.Charge");
		Goto Melee.TEX;
	// Supersmith does not have to finish a charge with the hammer -- it
	// can simply charge again, or peel off and shoot.
	Missile.TEX.Again:
		"HSMI" H 0 A_Jump(192, "Missile.TEX.Charge");
		Goto Missile.TEX.PH1;
	// Three hellshots off the left shoulder, then the sprite MIRRORS and
	// three more off the right. Chains into itself, or ends in melee.
	Missile.TEX.HellShotCombo:
		"HSMI" I 12 { A_FaceTarget(); }
		"HSMI" J 0 { A_SpawnProjectile("RS_HellShotEX", 72, -24, 0); }
		"HSMI" J 0 { A_SpawnProjectile("RS_HellShotEX", 72, -24, 10); }
		"HSMI" J 12 Bright { A_SpawnProjectile("RS_HellShotEX", 72, -24, 20); }
		"HSMI" K 12 { A_FaceTarget(); }
		"HSMI" K 0 A_CheckSight("See");
		"HSMI" I 0 { A_SetScale(-0.93, 0.93); }
		"HSMI" I 12 { A_FaceTarget(); }
		"HSMI" J 0 { A_SpawnProjectile("RS_HellShotEX", 72, 24, 0); }
		"HSMI" J 0 { A_SpawnProjectile("RS_HellShotEX", 72, 24, -10); }
		"HSMI" J 12 Bright { A_SpawnProjectile("RS_HellShotEX", 72, 24, -20); }
		"HSMI" K 12 { A_FaceTarget(); }
		"HSMI" K 0 { A_SetScale(0.93, 0.93); }
		"HSMI" K 0 A_Jump(80, "Missile.TEX.HellShotCombo");
		"HSMI" K 0 A_CheckSight("Melee.TEX");
		Goto Melee.TEX;
	// Four ground zaps walked out to 150 units, then two loose zappers.
	// Supersmith follows it with the thrown bolt.
	Missile.TEX.LightningCall:
		"HSMI" A 0 A_JumpIfCloser(1000, "Missile.TEX.LightningGo");
		Goto Missile.TEX.PH1;
	Missile.TEX.LightningGo:
		"HSMI" A 0 A_Jump(88, "Missile.TEX.PH1");
		"HSMI" O 8 Bright { A_StartSound("Crack/death", CHAN_VOICE); }
		"HSMI" L 2 { A_FaceTarget(); }
		"HSMI" L 3 Bright { A_SpawnProjectile("RS_Zap88", 100, -14, 0); }
		"HSMI" L 0 { A_StartSound("Crack/death", CHAN_VOICE); }
		"HSMI" L 2 { A_SpawnProjectile("RS_Zap88", 120, random(-28, 8), 0); }
		"HSMI" L 1 Bright { A_SpawnProjectile("RS_Zap88", 135, random(-28, 8), 0); }
		"HSMI" L 0 { A_StartSound("Crack/death", CHAN_VOICE); }
		"HSMI" L 1 Bright { A_SpawnProjectile("RS_Zap88", 150, random(-28, 8), 0); }
		"HSMI" LLL 1 { A_SpawnProjectile("RS_ZappersCB", 78, random(-2, 28), random(-180, 180)); }
		TNT1 A 0 { if (rsSupersmith >= 1) return ResolveState("Missile.TEX.LightningThrow"); return ResolveState(null); }
		Goto See;
	Missile.TEX.HomingHell:
		"HSMI" A 0 A_Jump(44, "Missile.TEX.PH1");
		"HSMI" I 8 { A_FaceTarget(); }
		"HSMI" J 8 Bright { A_SpawnProjectile("RS_HSHomer", 72, -24, 0); }
		"HSMI" J 0 A_CheckSight("See");
		"HSMI" I 8 { A_FaceTarget(); }
		"HSMI" J 8 Bright { A_SpawnProjectile("RS_HSHomer", 72, -24, 0); }
		"HSMI" J 0 A_CheckSight("See");
		"HSMI" J 0 A_Jump(224, "Missile.TEX.HomingHell");
		Goto Missile.TEX.Charge;
	// Long-range only, and it refuses to fire in a low room -- the blast
	// needs headroom. Loops almost every time, then blinks out.
	Missile.TEX.FlameBlast:
		"HSMI" E 0 A_JumpIfCloser(1000, "Missile.TEX.PH1");
		TNT1 A 0 { if (ceilingz - floorz <= 140) return ResolveState("Missile.TEX.PH1"); return ResolveState(null); }
		"HSMI" E 10 { A_FaceTarget(); }
	Missile.TEX.FlameBlast2:
		"HSMI" E 0 A_JumpIfCloser(1000, "Missile.TEX.PH1");
		"HSMI" E 4 { A_FaceTarget(); }
		"HSMI" F 0 { A_SpawnProjectile("RS_HSFlameBlast", 128, 24, 0); }
		"HSMI" F 4 Bright { A_SpawnProjectile("RS_HSFlameBlast", 128, -24, 0); }
		"HSMI" E 0 A_CheckSight("See");
		"HSMI" E 4 { A_FaceTarget(); }
		"HSMI" F 0 { A_SpawnProjectile("RS_HSFlameBlast", 128, 24, 0); }
		"HSMI" F 4 Bright { A_SpawnProjectile("RS_HSFlameBlast", 128, -24, 0); }
		"HSMI" E 0 A_CheckSight("See");
		"HSMI" E 0 A_Jump(250, "Missile.TEX.FlameBlast2");
		Goto Pain.TEX.Reposition;
	Missile.TEX.Summons:
		"HSMI" L 12 { A_StartSound("cyber/hoof", CHAN_5); }
		"HSMI" LLLLL 7 { SummonMinion(CybiePortalPick(random(0, 5)), -3, random(64, 178)); }
		Goto See;
	// The thrown bolt: a bouncing seeker that detonates like a BFG ball.
	Missile.TEX.LightningThrow:
		"HSMI" O 2 Bright { A_StartSound("Crack/death", CHAN_VOICE); }
		"HSMI" O 3;
		"HSMI" O 6 Bright;
		"HSMI" O 4;
		"HSMI" O 1 Bright;
		"HSMI" O 2;
		"HSMI" O 5 Bright;
		"HSMI" M 4 { A_FaceTarget(); }
		"HSMI" L 4 Bright { A_FaceTarget(); }
		"HSMI" M 4 { A_SpawnProjectile("RS_ZapCybEX", 72, random(-28, 28), random(-40, 40)); }
		Goto Pain.TEX.Reposition;
	// BIGHELL. Goes flat invulnerable, plants a growing orb, and stomps a
	// quake ring once a second for twelve seconds while it builds. The orb
	// becomes RS_BigHellCybEX2 -- the single biggest hit in the family.
	// Nothing you do to the Tyrant during the wind-up matters; the answer
	// is to not be in the lane.
	Missile.TEX.BigHell:
		"HSMI" A 0 { A_StartSound("hellsmith/laugh", CHAN_7, 0, 1.0, ATTN_NONE); }
		"HSMI" L 0 { A_SetInvulnerable(); rsDewzan = 0; }
		"HSMI" LLLLLLLLLL 2 { A_FaceTarget(); }
		"HSMI" L 0 { A_SpawnItemEx("RS_BigHellCybEX", 64, 0, 40, 0, 0, 0, 0, SXF_SETTARGET); }
	Missile.TEX.BigHell2:
		TNT1 A 0 { if (rsDewzan >= 12) return ResolveState("Missile.TEX.BigHellDone"); return ResolveState(null); }
		"HSMI" LM 4;
		"HSMI" N 0 { A_SpawnProjectile("RS_MolochQuake", 0, 0, 0, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_MolochQuake", 0, 0, 45, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_MolochQuake", 0, 0, 90, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_MolochQuake", 0, 0, 135, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_MolochQuake", 0, 0, 180, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_MolochQuake", 0, 0, 225, CMF_AIMDIRECTION); }
		// 280, not 270 -- CHP's own number, kept.
		"HSMI" N 0 { A_SpawnProjectile("RS_MolochQuake", 0, 0, 280, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_MolochQuake", 0, 0, 315, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_StartSound("monster/hamflr", CHAN_5); }
		"HSMI" N 4 { A_StartSound("Fire/fire3", CHAN_6); }
		"HSMI" N 0 { rsDewzan++; }
		Loop;
	Missile.TEX.BigHellDone:
		"HSMI" N 0 { rsDewzan = 0; }
		"HSMI" N 100 { A_UnSetInvulnerable(); }
		Goto Pain.TEX.Reposition;
	// SUPERSMITH ONLY. The hammer swing again, but the pentagram is a
	// healing one and the stomp restores 1000 health.
	Missile.TEX.HealUP:
		TNT1 A 0 { if (rsSupersmith >= 1) return ResolveState("Missile.TEX.HealUPGo"); return ResolveState(null); }
		Goto Missile.TEX.PH1;
	Missile.TEX.HealUPGo:
		"HSMI" L 3 { A_FaceTarget(); }
		"HSMI" M 0 { A_StartSound("monster/hamswg", CHAN_WEAPON); }
		"HSMI" MN 3 { A_FaceTarget(); }
		"HSMI" N 0 { A_SetReflectiveInvulnerable(); A_Quake(40, 60, 0, 40); }
		"HSMI" N 0 { A_SpawnProjectile("RS_PentaHealCybEX", 0, 0, -72, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_PentaHealCybEX", 0, 0, -144, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_PentaHealCybEX", 0, 0, -216, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_PentaHealCybEX", 0, 0, -288, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_SpawnProjectile("RS_PentaHealCybEX", 0, 0, 0, CMF_AIMDIRECTION); }
		"HSMI" N 0 { A_StartSound("monster/hamflr", CHAN_WEAPON); }
		"HSMI" N 0 { for (int i = 0; i <= 16; i++) A_SpawnProjectile("RS_MolochQuake", 0, -48, i * 10); }
		"HSMI" N 0 { for (int i = 18; i <= 35; i++) A_SpawnProjectile("RS_MolochQuake", 0, -48, i * 10); }
		// CHP: HealThing(1000,24000). Written against SpawnHealth() so the
		// cap follows the tier's own maximum instead of a hardcoded 24000.
		"HSMI" N 0 { A_SetHealth(min(health + 1000, SpawnHealth())); }
		"HSMI" NNNNNNNNNNNNNN 7;
		Goto See;
	Pain.TEX:
		"HSMI" O 0 { A_SetScale(0.93, 0.93); A_SetSpeed(20); }
		"HSMI" O 4 { A_ScaleVelocity(0); }
		"HSMI" O 4 { A_Pain(); }
		"HSMI" O 0 A_Jump(64, "Pain.TEX.Reposition", "Missile.TEX.PH1");
		Goto See;
	Death.TEX:
		TNT1 A 0 { ReleaseMinions(); }
		"HSMD" A 0 { A_SpawnProjectile("RS_PentaLine3", 0, 0, -72, CMF_AIMDIRECTION); }
		"HSMD" A 0 { A_SpawnProjectile("RS_PentaLine3", 0, 0, -144, CMF_AIMDIRECTION); }
		"HSMD" A 0 { A_SpawnProjectile("RS_PentaLine3", 0, 0, -216, CMF_AIMDIRECTION); }
		"HSMD" A 0 { A_SpawnProjectile("RS_PentaLine3", 0, 0, -288, CMF_AIMDIRECTION); }
		"HSMD" A 0 { A_SpawnProjectile("RS_PentaLine3", 0, 0, 0, CMF_AIMDIRECTION); }
		"HSMD" A 7 Bright { A_SpawnProjectile("RS_SmithDFSpawner", 0, 0, 0, 0); }
		"HSMD" B 0 { A_Scream(); }
		"HSMD" B 7 Bright { A_SpawnItemEx("RS_HSHammer", 50, 50, 110, 2, 2, 0, 25); }
		"HSMD" C 8 Bright;
		"HSMD" D 9 Bright { A_NoBlocking(); }
		"HSMD" EFGHIFGHIFGHIFGHJKLMNO 9 Bright;
		"HSMD" PQRS 9;
		"HSMD" T -1 { A_BossDeath(); }
		Stop;
	XDeath.TEX:
		Goto Death.TEX;

	// ================= T14 WHITE EX (17_WX) =================
	// "IT CRASHES DOOM II" -- Romero's glitch, and the largest single actor
	// in CHP (1601 lines). Two independent axes decide every attack:
	//
	//   PHASE (rsPhase, health-gated, one-way):
	//     1  >24576   the plain kit
	//     2  <24576   Phase2 fires ONCE: two glitch-barons walk out of
	//                 teleport fog and the pool roughly doubles
	//     3  < 8192   Phase3 fires ONCE: See2 turns on NOCLIP and
	//                 MISSILEMORE -- it stops respecting geometry -- and
	//                 OVERDRIVE unlocks
	//
	//   RANGE BAND (checked first, every time):
	//     <200   Dukie    -- a carpet of floor detonations centred on ITSELF
	//     <720   Close    -- glitch shots, BFG spam, the fourth wall
	//     <1500  Med      -- adds rockets, code leakage, traps, shields
	//     else   MissileSet -- seizure rockets, winders, lasers, mines
	//
	// So the fight is a 3x4 grid of pools, not a ladder. OVERDRIVE is the
	// exception: a meta-attack that rolls one of seven sub-attacks, then
	// rolls again, chaining until a 16-count budget (rsDewzan) runs out.
	//
	// Health is CHP's literal 32767 -- one short of a signed 16-bit
	// overflow, which is the joke.
	Spawn.T14:
		"MMDG" A 0 { A_SetScale(1.25, 1.25); }
		TNT1 AAAA 0 { A_SpawnItemEx("RS_RomeroEXGlitch", random(-20, 20), random(-20, 20), random(0, 128), 0, 0, 0, 0, SXF_SETMASTER); }
	Spawn.T14.Look:
		"MMDG" E 10 { A_Look(); }
		Loop;
	See.T14:
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("See.T14.Fast"); return ResolveState(null); }
		TNT1 A 0 { bTHRUACTORS = false; RS_GroundStance(); A_UnSetReflectiveInvulnerable(); A_ScaleVelocity(1); }
		TNT1 A 0 { if (rsPhase < 2) A_SetTranslucent(1.0); }
		"MMDG" A 0 { A_SetSpeed(24); }
		"MMDG" A 0 A_CheckBlock("Pain.T14.Reposition");
		"MMDG" AABBCCDD 3 { A_Chase(); }
		"MMDG" A 0 A_Jump(32, "See.T14.Oops");
		Loop;
	// Phase 3 walk: NOCLIP and MISSILEMORE on, slower but unstoppable.
	See.T14.Fast:
		"MMDG" O 0 { bNOCLIP = true; bMISSILEMORE = true; }
		TNT1 A 0 { bTHRUACTORS = false; RS_GroundStance(); A_UnSetReflectiveInvulnerable(); A_ScaleVelocity(1); }
		"MMDG" A 0 { A_SetSpeed(18); }
		"MMDG" A 0 A_CheckBlock("Pain.T14.Reposition");
		"MMDG" AAAA 3 { A_Chase(); }
		"MMDG" A 0 A_Jump(82, "See.T14.Oi");
		"MMDG" AAAA 3 { A_Chase(); }
		"MMDG" A 0 A_Jump(32, "See.T14.Oops");
		Loop;
	See.T14.Oops:
		"MMDG" AAAAAAAAAAAAAAAA 0 { A_Wander(); }
		Goto See;
	See.T14.Oi:
		"MMDG" AAAA 3 { A_FastChase(); }
		Goto See;
	// The blink. CHP has two copies of this, identical except that the
	// phase-2+ one fades ADDITIVELY; folded to one label with that check.
	Pain.T14.Reposition:
		"MMDG" O 0 { bNOPAIN = true; }
		"MMDG" E 12 { A_Quake(6, 100, 0, 64); }
		"MMDG" E 1 { A_SetTranslucent(0.5, rsPhase >= 2 ? 1 : 0); }
		"MMDG" E 1 { A_SetTranslucent(0.3, rsPhase >= 2 ? 1 : 0); }
		"MMDG" E 1 { A_SetTranslucent(0.1, rsPhase >= 2 ? 1 : 0); }
		"MMDG" E 1 { A_SetTranslucent(0); }
		"MMDG" O 0 { bFLOAT = true; bNOGRAVITY = true; bTHRUACTORS = true; A_SetFloatSpeed(68); A_SetSpeed(68); }
		"MMDG" EEEEEEEE 3 { A_Wander(); }
		"MMDG" EEEEEEEE 2 { A_Wander(); }
		"MMDG" EEEEEEEE 1 { A_Wander(); }
		"MMDG" O 0 { bFLOAT = false; bNOGRAVITY = false; bTHRUACTORS = false; A_SetFloatSpeed(24); A_SetSpeed(24); }
		"MMDG" E 1 { A_SetTranslucent(0.1, rsPhase >= 2 ? 1 : 0); }
		"MMDG" E 1 { A_Quake(6, 100, 0, 64); }
		"MMDG" E 1 { A_SetTranslucent(0.3, rsPhase >= 2 ? 1 : 0); }
		"MMDG" E 1 { A_SetTranslucent(0.5, rsPhase >= 2 ? 1 : 0); }
		"MMDG" E 1 { A_SetTranslucent(0.7, rsPhase >= 2 ? 1 : 0); }
		"MMDG" E 9 { A_SetTranslucent(1.0, rsPhase >= 2 ? 1 : 0); }
		"MMDG" O 0 { bNOPAIN = false; }
		Goto See;
	// GATE 1 -- 24576 of 32767. Fires once; afterwards this label is just
	// the door to the phase-2 pool.
	Missile.T14.Phase2:
		TNT1 A 0 { if (rsPhase >= 2) return ResolveState("Missile.T14.Set"); return ResolveState(null); }
		"MMDG" E 0 { A_StartSound("RomeEX/PH2", CHAN_WEAPON, 0, 1.0, ATTN_NONE); }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" Z 8 Bright { A_FaceTarget(); }
		"MMDG" Y 5 Bright { A_FaceTarget(); }
		"MMDG" Y 0 { A_SpawnItemEx("TeleportFog", 0, 128, 18, 0, 0, 1, 0, SXF_NOCHECKPOSITION); }
		"MMDG" Y 0 { A_SpawnItemEx("TeleportFog", 0, -128, 18, 0, 0, 1, 0, SXF_NOCHECKPOSITION); }
		"MMDG" Y 0 { SummonMinion("RS_GlitchBaron", -1, 128.0); }
		"MMDG" Y 0 { SummonMinion("RS_GlitchBaron", -1, 128.0); }
		"MMDG" Y 20 Bright { A_FaceTarget(); }
		"MMDG" Y 0 { A_SetTranslucent(1.0, 1); }
		"MMDG" E 8 Bright { rsPhase = 2; }
		Goto Pain.T14.Reposition;
	// GATE 2 -- 8192 of 32767.
	Missile.T14.Phase3:
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("Missile.T14.Set"); return ResolveState(null); }
		"MMDG" E 0 { A_StartSound("RomeEX/PH3", CHAN_WEAPON, 0, 1.0, ATTN_NONE); }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" G 8 Bright { A_FaceTarget(); }
		"MMDG" I 5 Bright { A_FaceTarget(); }
		"MMDG" EIEGGIEGIGEIG 3 Bright { A_FaceTarget(); }
		"MMDG" E 3 { A_Quake(15, 15, 0, 40); }
		"MMDG" E 8 Bright { rsPhase = 3; }
		Goto Pain.T14.Reposition;
	Missile.T14.FatalBarons:
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" Z 8 Bright { A_FaceTarget(); }
		"MMDG" Y 5 Bright { A_FaceTarget(); }
		"MMDG" Y 0 { A_SpawnItemEx("TeleportFog", 0, 128, 18, 0, 0, 1, 0, SXF_NOCHECKPOSITION); }
		"MMDG" Y 0 { A_SpawnItemEx("TeleportFog", 0, -128, 18, 0, 0, 1, 0, SXF_NOCHECKPOSITION); }
		"MMDG" Y 0 { SummonMinion("RS_GlitchBaron", -1, 128.0); }
		"MMDG" Y 0 { SummonMinion("RS_GlitchBaron", -1, 128.0); }
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("Missile.T14.BaronMore"); return ResolveState(null); }
		"MMDG" Y 10 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T14.BaronMore:
		"MMDG" YY 7 Bright { A_FaceTarget(); }
		"MMDG" Y 0 { A_SpawnItemEx("TeleportFog", 0, 218, 18, 0, 0, 1, 0, SXF_NOCHECKPOSITION); }
		"MMDG" Y 0 { A_SpawnItemEx("TeleportFog", 0, -218, 18, 0, 0, 1, 0, SXF_NOCHECKPOSITION); }
		"MMDG" Y 0 { SummonMinion("RS_GlitchBaron", -1, 218.0); }
		"MMDG" Y 0 { SummonMinion("RS_GlitchBaron", -1, 218.0); }
		"MMDG" Y 20 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T14:
		"MMDG" O 0 { bNOCLIP = false; }
		"MMDG" A 0 A_Jump(192, "Missile.T14.Gates");
		"MMDG" A 0 { A_FaceTarget(); }
		// CHP: ThrustThingZ(0,30) + ThrustThing(angle,100) -- a lunge onto
		// the target before it commits to a pattern.
		"MMDG" A 0 { vel.z = 3.75; }
		"MMDG" A 0 { Thrust(100.0, angle); }
	Missile.T14.Gates:
		"MMDG" A 0 A_JumpIfHealthLower(8192, "Missile.T14.Phase3");
		"MMDG" A 0 A_JumpIfHealthLower(24576, "Missile.T14.Phase2");
	// THE RANGE BANDS. Checked before anything else, every time.
	Missile.T14.Set:
		"MMDG" A 0 A_JumpIfCloser(200, "Missile.T14.Dukie", true);
		"MMDG" A 0 A_JumpIfCloser(720, "Missile.T14.Close", true);
		"MMDG" A 0 A_JumpIfCloser(1500, "Missile.T14.Med", true);
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("Missile.T14.Set3"); return ResolveState(null); }
		TNT1 A 0 { if (rsPhase >= 2) return ResolveState("Missile.T14.Set2"); return ResolveState(null); }
		"MMDG" E 0 A_Jump(256, "Missile.T14.MissileSeizure", "Missile.T14.GlitchWinder", "Missile.T14.GlitchLaser");
		Goto See;
	Missile.T14.Set2:
		"MMDG" E 0 A_Jump(256, "Missile.T14.GlitchWinder2", "Missile.T14.GlitchLaser2", "Missile.T14.LaserRain", "Pain.T14.Reposition", "Missile.T14.GlitchMines");
		Goto See;
	Missile.T14.Set3:
		"MMDG" E 0 A_Jump(256, "Missile.T14.GlitchWinder3", "Missile.T14.GlitchLaser3", "Missile.T14.LaserRain2", "Missile.T14.GlitchMines2", "Missile.T14.FatalBarons");
		Goto See;
	Missile.T14.Med:
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("Missile.T14.Med3"); return ResolveState(null); }
		TNT1 A 0 { if (rsPhase >= 2) return ResolveState("Missile.T14.Med2"); return ResolveState(null); }
		"MMDG" A 0 A_Jump(64, "Missile.T14.Rush");
		"MMDG" E 0 A_Jump(256, "Missile.T14.MissileSeizure", "Missile.T14.BFGSpam", "Missile.T14.FourthWall");
		Goto See;
	Missile.T14.Med2:
		"MMDG" E 0 A_Jump(256, "Missile.T14.MissileSeizure2", "Missile.T14.BFGSpam2", "Missile.T14.CodeLeakage", "Missile.T14.FourthWall2", "Missile.T14.GlitchTrap", "Missile.T14.GlitchWinder2", "Missile.T14.GlitchShields", "Missile.T14.GlitchLaser2", "Missile.T14.GlitchMines", "Missile.T14.LaserRain");
		Goto See;
	Missile.T14.Med3:
		"MMDG" A 0 A_Jump(64, "Missile.T14.Rush");
		"MMDG" E 0 A_Jump(256, "Missile.T14.BFGSpam3", "Missile.T14.CodeLeakage2", "Missile.T14.FourthWall3", "Missile.T14.GlitchTrap2", "Missile.T14.GlitchWinder3", "Missile.T14.GlitchLaser2", "Missile.T14.GlitchMines2", "Missile.T14.FatalBarons", "Missile.T14.BFGHeck", "Missile.T14.Overdrive");
		Goto See;
	Missile.T14.Close:
		"MMDG" A 0 A_JumpIfCloser(200, "Missile.T14.Dukie", true);
		TNT1 A 0 { if (rsPhase >= 3) return ResolveState("Missile.T14.Close3"); return ResolveState(null); }
		TNT1 A 0 { if (rsPhase >= 2) return ResolveState("Missile.T14.Close2"); return ResolveState(null); }
		"MMDG" E 0 A_Jump(256, "Missile.T14.Glitches", "Missile.T14.BFGSpam", "Missile.T14.FourthWall");
		Goto See;
	Missile.T14.Close2:
		"MMDG" E 0 A_Jump(256, "Missile.T14.Glitches2", "Missile.T14.BFGSpam2", "Missile.T14.FourthWall2", "Missile.T14.GlitchTrap", "Missile.T14.CodeLeakage", "Missile.T14.GlitchShields", "Missile.T14.GlitchLaser2");
		Goto See;
	Missile.T14.Close3:
		"MMDG" E 0 A_Jump(256, "Pain.T14.Reposition", "Missile.T14.Glitches3", "Missile.T14.BFGSpam3", "Missile.T14.MissileSeizure3", "Missile.T14.BFGHeck", "Missile.T14.Overdrive");
		Goto See;
	// DUKIE -- the knife-range answer. A carpet of twice-detonating floor
	// tiles in expanding rings centred on ITSELF, not on you.
	Missile.T14.Dukie:
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" E 3
		{
			A_SpawnItemEx("RS_RomeroEXGround", -64, -64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 64, -64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -64, 64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 0, -64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 0, 64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -64, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 64, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 64, 64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		}
		"MMDG" E 3
		{
			A_SpawnItemEx("RS_RomeroEXGround", 0, -164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 0, 164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -164, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 164, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -164, -164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 164, -164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -164, 164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 164, 164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		}
		"MMDG" E 3
		{
			A_SpawnItemEx("RS_RomeroEXGround", 0, -234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 0, 234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -234, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 234, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -234, -234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 234, -234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -234, 234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 234, 234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		}
		TNT1 A 0 { if (rsPhase >= 2) return ResolveState("Missile.T14.DukieMore"); return ResolveState(null); }
		Goto See;
	Missile.T14.DukieMore:
		"MMDG" E 2
		{
			A_SpawnItemEx("RS_RomeroEXGround", 0, -314, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 0, 314, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -314, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 314, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -314, -314, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 314, -314, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -314, 314, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 314, 314, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		}
		"MMDG" E 2
		{
			A_SpawnItemEx("RS_RomeroEXGround", 0, -394, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 0, 394, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -394, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 394, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -394, -394, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 394, -394, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -394, 394, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 394, 394, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		}
		"MMDG" E 2
		{
			A_SpawnItemEx("RS_RomeroEXGround", 0, -464, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 0, 464, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -464, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 464, 0, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -464, -464, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 464, -464, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -464, 464, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 464, 464, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		}
		Goto See;
	// A reflective skull-charge that ends in its own three rings of floor
	// tiles, and can chain straight back into itself.
	Missile.T14.Rush:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
	Missile.T14.RushGo:
		"MMDG" E 1 { A_StartSound("weapons/suldth", CHAN_WEAPON); }
		"MMDG" E 2 { A_SetReflectiveInvulnerable(); }
		"MMDG" E 0 { bTHRUACTORS = true; }
		"MMDG" E 20 { A_SkullAttack(48); }
		"MMDG" E 1 { A_SetSpeed(0); }
		"MMDG" E 1 { A_ScaleVelocity(0.05); }
		"MMDG" E 0 { bTHRUACTORS = false; }
		TNT1 A 0 A_JumpIfCloser(200, "Missile.T14.Dukie", true);
		"MMDG" E 3
		{
			A_SpawnItemEx("RS_RomeroEXGround", -64, -64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 64, -64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -64, 64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 64, 64, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		}
		"MMDG" E 3
		{
			A_SpawnItemEx("RS_RomeroEXGround", -164, -164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 164, -164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -164, 164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 164, 164, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		}
		"MMDG" E 3
		{
			A_SpawnItemEx("RS_RomeroEXGround", -234, -234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 234, -234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", -234, 234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
			A_SpawnItemEx("RS_RomeroEXGround", 234, 234, 0, 0, 1, 0, 0, SXF_NOCHECKPOSITION);
		}
		"MMDG" E 0 A_Jump(128, "Missile.T14.RushGo");
		Goto See;
	// GLITCHES -- twelve rounds of six bouncing texture-blocks. Phase 2
	// widens the burst; phase 3 laces every round with two mega-blocks and
	// can teleport-wander mid-attack.
	Missile.T14.Glitches:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); rsGlitchRound = 0; }
		"MMDG" EE 5 { A_FaceTarget(); }
	Missile.T14.GlitchesLoop:
		"MMDG" FF 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, 30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" F 3 Bright { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" EE 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, 30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" E 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" E 3 Bright { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" E 0 { A_FaceTarget(); }
		"MMDG" E 0 { if (++rsGlitchRound < 12) return ResolveState("Missile.T14.GlitchesLoop"); return ResolveState(null); }
		"MMDG" GG 3 Bright { A_FaceTarget(); }
		"MMDG" A 0 A_Jump(32, "Missile.T14");
		Goto See;
	Missile.T14.Glitches2:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); rsGlitchRound = 0; }
		"MMDG" EE 5 { A_FaceTarget(); }
	Missile.T14.Glitches2Loop:
		"MMDG" FFF 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, 30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" FF 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" F 3 Bright { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" EEE 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, 30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" EE 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" E 3 Bright { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" E 0 { A_FaceTarget(); }
		"MMDG" E 0 { if (++rsGlitchRound < 12) return ResolveState("Missile.T14.Glitches2Loop"); return ResolveState(null); }
		"MMDG" GG 3 Bright { A_FaceTarget(); }
		"MMDG" A 0 A_Jump(32, "Missile.T14");
		Goto See;
	Missile.T14.Glitches3:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); rsGlitchRound = 0; }
		"MMDG" EE 5 { A_FaceTarget(); }
	Missile.T14.Glitches3Loop:
		"MMDG" FFF 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, 30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXMegaGlitchShot", 52, 30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" FF 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXMegaGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" F 3 Bright { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" EEE 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, 30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" EE 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" E 3 Bright { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" E 0 { A_FaceTarget(); }
		"MMDG" E 0 { if (++rsGlitchRound < 12) return ResolveState("Missile.T14.Glitches3Loop"); return ResolveState(null); }
		"MMDG" A 0 A_Jump(128, "Missile.T14.Glitches4");
		"MMDG" A 0 A_Jump(32, "Missile.T14");
		Goto See;
	Missile.T14.Glitches4:
		"MMDG" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_Wander(); }
		Goto Missile.T14.Glitches3Loop;
	// THE FOURTH WALL. A 64x110 seeking slab. Phase 3 fires ten of them in
	// a fan and there is nowhere in the room that is not one of them.
	Missile.T14.FourthWall:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
		"MMDG" EEEE 3 { A_FaceTarget(); }
		"MMDG" JKLKJ 2 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 1 Bright { A_FaceTarget(); }
		"MMDG" MO 3 Bright;
		"MMDG" O 12 Bright { A_SpawnProjectile("RS_RomeroEXFourthWall", 52); }
		TNT1 A 0 A_Jump(32, "Missile.T14");
		Goto See;
	Missile.T14.FourthWall2:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
		"MMDG" EEEE 3 { A_FaceTarget(); }
		"MMDG" JKLKJ 2 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 1 Bright { A_FaceTarget(); }
		"MMDG" MO 3 Bright;
		"MMDG" OOO 12 Bright { A_SpawnProjectile("RS_RomeroEXFourthWall", 52); }
		TNT1 A 0 A_Jump(32, "Missile.T14");
		Goto See;
	Missile.T14.FourthWall3:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
		"MMDG" EEEE 3 { A_FaceTarget(); }
		"MMDG" JKLKJ 2 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 1 Bright { A_FaceTarget(); }
		"MMDG" MO 3 Bright;
		"MMDG" O 0 { for (int i = 0; i < 9; i++) A_SpawnProjectile("RS_RomeroEXFourthWall", 52, 0, -90 + i * 20); }
		"MMDG" O 12 Bright { A_SpawnProjectile("RS_RomeroEXFourthWall", 52, 0, 90); }
		TNT1 A 0 A_Jump(32, "Missile.T14");
		Goto See;
	// MISSILE SEIZURE -- rocket volleys that re-fire out of a blink-wander.
	// Phase 2 rolls two patterns, phase 3 rolls four (adding the two
	// sweeping fans) and fires them faster.
	Missile.T14.MissileSeizure:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
	Missile.T14.MissileSeizureGo:
		"MMDG" E 10 { A_FaceTarget(); }
		"MMDG" HI 4 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20); }
		"MMDG" HI 4 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-3, 3)); }
		"MMDG" HI 4 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20); }
		"MMDG" HI 4 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-3, 3)); }
		"MMDG" HI 4 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20); }
		"MMDG" E 10 { A_FaceTarget(); }
		"MMDG" A 0 A_Jump(128, "Missile.T14.SeizureRefire");
		TNT1 A 0 A_CheckSight("See");
		TNT1 A 0 A_Jump(32, "Missile.T14");
		Goto See;
	Missile.T14.SeizureRefire:
		"MMDG" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_Wander(); }
		Goto Missile.T14.MissileSeizureGo;
	Missile.T14.MissileSeizure2:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
	Missile.T14.MissileSeizure2Go:
		"MMDG" E 8 { A_FaceTarget(); }
		"MMDG" H 0 A_Jump(256, "Missile.T14.Pattern1", "Missile.T14.Pattern2");
	Missile.T14.Pattern1:
		"MMDG" HI 3 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20); }
		"MMDG" HI 3 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-3, 3)); }
		"MMDG" HI 3 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20); }
		"MMDG" HI 3 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-3, 3)); }
		"MMDG" HI 3 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20); }
		Goto Missile.T14.Seizure2Check;
	Missile.T14.Pattern2:
		"MMDG" HIHIHIHIHI 3 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-64, 64)); }
		Goto Missile.T14.Seizure2Check;
	Missile.T14.Seizure2Check:
		"MMDG" E 8 { A_FaceTarget(); }
		"MMDG" A 0 A_Jump(160, "Missile.T14.Seizure2Refire");
		TNT1 A 0 A_CheckSight("See");
		TNT1 A 0 A_Jump(32, "Missile.T14");
		Goto See;
	Missile.T14.Seizure2Refire:
		"MMDG" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_Wander(); }
		Goto Missile.T14.MissileSeizure2Go;
	Missile.T14.MissileSeizure3:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
	Missile.T14.MissileSeizure3Go:
		"MMDG" E 6 { A_FaceTarget(); }
		"MMDG" H 0 A_Jump(256, "Missile.T14.Pattern3", "Missile.T14.Pattern4", "Missile.T14.Pattern5", "Missile.T14.Pattern6");
	Missile.T14.Pattern3:
		"MMDG" HI 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20); }
		"MMDG" HI 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-3, 3)); }
		"MMDG" HI 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20); }
		"MMDG" HI 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-3, 3)); }
		"MMDG" HI 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20); }
		Goto Missile.T14.Seizure3Check;
	Missile.T14.Pattern4:
		"MMDG" HIHIHIHIHI 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-64, 64)); }
		Goto Missile.T14.Seizure3Check;
	// The two sweeping fans -- left-to-right and back again.
	Missile.T14.Pattern5:
		"MMDG" H 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, -54); }
		"MMDG" I 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, -42); }
		"MMDG" H 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, -30); }
		"MMDG" I 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, -18); }
		"MMDG" H 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, -6); }
		"MMDG" I 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 6); }
		"MMDG" H 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 18); }
		"MMDG" I 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 30); }
		"MMDG" H 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 42); }
		"MMDG" I 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 54); }
		Goto Missile.T14.Seizure3Check;
	Missile.T14.Pattern6:
		"MMDG" H 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 54); }
		"MMDG" I 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 42); }
		"MMDG" H 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 30); }
		"MMDG" I 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 18); }
		"MMDG" H 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, 6); }
		"MMDG" I 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, -6); }
		"MMDG" H 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, -18); }
		"MMDG" I 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, -30); }
		"MMDG" H 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, -42); }
		"MMDG" I 2 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, -54); }
		Goto Missile.T14.Seizure3Check;
	Missile.T14.Seizure3Check:
		"MMDG" E 6 { A_FaceTarget(); }
		"MMDG" A 0 A_Jump(192, "Missile.T14.Seizure3Refire");
		TNT1 A 0 A_CheckSight("See");
		TNT1 A 0 A_Jump(32, "Missile.T14");
		Goto See;
	Missile.T14.Seizure3Refire:
		"MMDG" AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 0 { A_Wander(); }
		Goto Missile.T14.MissileSeizure3Go;
	// THE LASER. Inside 1000 units it aims DOWNWARD (pitch -4) instead --
	// the sweep variant -- so backing off does not make it safer, it just
	// changes which half of you it hits.
	Missile.T14.GlitchLaser:
		"MMDG" EEEE 3 { A_FaceTarget(); }
		"MMDG" E 0 { A_StartSound("RomeEX/ATK2", CHAN_WEAPON, 0, 1.0, ATTN_NONE); }
		"MMDG" JKLKJ 3 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 2 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 1 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 1 Bright { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(1000, "Missile.T14.SweepBeam", true);
		"MMDG" MNOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0); }
		Goto See;
	Missile.T14.SweepBeam:
		"MMDG" MNOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0, 0, -4); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0, 0, -4); }
		Goto See;
	Missile.T14.GlitchLaser2:
		"MMDG" EEEE 3 { A_FaceTarget(); }
		"MMDG" E 0 { A_StartSound("RomeEX/ATK2", CHAN_WEAPON, 0, 1.0, ATTN_NONE); }
		"MMDG" JKLKJ 3 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 2 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 1 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 1 Bright { A_FaceTarget(); }
		"MMDG" AAAAAAAAAAAAAAAA 0 { A_Wander(); }
		TNT1 A 0 A_JumpIfCloser(1000, "Missile.T14.SweepBeam2", true);
		"MMDG" MNOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0); }
		Goto See;
	Missile.T14.SweepBeam2:
		"MMDG" MNOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0, 0, -4); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0, 0, -4); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0, 0, -4); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0, 0, -4); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0, 0, -4); }
		Goto See;
	// Phase 3: the beam no longer points -- it SWEEPS, five times, each
	// sweep walking the angle out to +-10 and back.
	Missile.T14.GlitchLaser3:
		"MMDG" EEEE 3 { A_FaceTarget(); }
		"MMDG" E 0 { A_StartSound("RomeEX/ATK2", CHAN_WEAPON, 0, 1.0, ATTN_NONE); }
		"MMDG" JKLKJ 3 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 2 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 1 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 1 Bright { A_FaceTarget(); }
		"MMDG" AAAAAAAAAAAAAAAA 0 { A_Wander(); }
		TNT1 A 0 A_JumpIfCloser(1000, "Missile.T14.SweepBeam3", true);
		"MMDG" MN 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, -10); }
		"MMDG" OOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, random(-8, 8)); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, random(-10, 10)); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, random(-10, 10)); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, random(-10, 10)); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, random(-10, 10)); }
		Goto See;
	Missile.T14.SweepBeam3:
		"MMDG" MN 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, -10, 0, -4); }
		"MMDG" OOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, random(-8, 8), 0, -4); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, random(-10, 10), 0, -4); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, random(-10, 10), 0, -4); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, random(-10, 10), 0, -4); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, random(-10, 10), 0, -4); }
		Goto See;
	// THE WINDER. Lifts off, unloads eight weaving seekers plus two BFG
	// balls, lands. Phase 2 adds a long overhead rain of seekers; phase 3
	// adds a second rain and can chain into BFGSpam3.
	Missile.T14.GlitchWinder:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" E 8 Bright { vel.z = 12.5; }
		"MMDG" E 0 { bFLOAT = true; bNOGRAVITY = true; }
		"MMDG" E 8 Bright { A_FaceTarget(); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 33, 1); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 33, -1); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 1); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -1); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 3); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -3); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 5); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -5); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXSpamShots", 52, 30, 1); }
		"MMDG" F 10 Bright { A_SpawnProjectile("RS_RomeroEXSpamShots", 52, -30, -1); }
		"MMDG" E 0 { bFLOAT = false; bNOGRAVITY = false; }
		"MMDG" E 5 { A_FaceTarget(); }
		"MMDG" A 0 A_Jump(32, "Missile.T14");
		Goto Pain.T14.Reposition;
	Missile.T14.GlitchWinder2:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); rsGlitchRound = 0; }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" E 8 Bright { vel.z = 12.5; }
		"MMDG" E 0 { bFLOAT = true; bNOGRAVITY = true; }
		"MMDG" E 8 Bright { A_FaceTarget(); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 33, 1); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 33, -1); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 1); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -1); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 3); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -3); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 5); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -5); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXSpamShots", 52, 30, 1); }
		"MMDG" F 10 Bright { A_SpawnProjectile("RS_RomeroEXSpamShots", 52, -30, -1); }
		"MMDG" E 0 { bFLOAT = false; bNOGRAVITY = false; }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" Z 8 Bright { A_FaceTarget(); }
	Missile.T14.WinderRain:
		"MMDG" Z 1 Bright { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 60, 50, random(20, 50), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDG" Y 1 Bright { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 60, -50, random(-50, -20), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDG" Y 1 Bright { A_FaceTarget(); }
		"MMDG" Y 0 { if (++rsGlitchRound < 12) return ResolveState("Missile.T14.WinderRain"); return ResolveState(null); }
		"MMDG" YZE 10 Bright { A_FaceTarget(); }
		TNT1 A 0 A_Jump(128, "Missile.T14.BFGSpam2");
		"MMDG" A 0 A_Jump(32, "Missile.T14");
		Goto Pain.T14.Reposition;
	Missile.T14.GlitchWinder3:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); rsGlitchRound = 0; }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" E 8 Bright { vel.z = 12.5; }
		"MMDG" E 0 { bFLOAT = true; bNOGRAVITY = true; }
		"MMDG" E 8 Bright { A_FaceTarget(); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 33, 1); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 33, -1); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 1); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -1); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 3); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -3); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 5); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -5); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXSpamShots", 52, 30, 1); }
		"MMDG" F 10 Bright { A_SpawnProjectile("RS_RomeroEXSpamShots", 52, -30, -1); }
		"MMDG" E 0 { bFLOAT = false; bNOGRAVITY = false; }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" Z 8 Bright { A_FaceTarget(); }
	Missile.T14.WinderRain3:
		"MMDG" Z 1 Bright { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 60, 50, random(20, 50), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDG" Y 1 Bright { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 60, -50, random(-50, -20), CMF_OFFSETPITCH | CMF_SAVEPITCH, random(-3, 3)); }
		"MMDG" Y 1 Bright { A_FaceTarget(); }
		"MMDG" Y 0 { if (++rsGlitchRound < 12) return ResolveState("Missile.T14.WinderRain3"); return ResolveState(null); }
		"MMDG" YZE 10 Bright { A_FaceTarget(); }
		"MMDG" AAAAAAAAAAAAAAAA 0 { A_Wander(); }
		"MMDG" E 8 Bright { A_FaceTarget(); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 33, 4); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 33, -4); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 4); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -4); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 12); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -12); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 20); }
		"MMDG" F 10 Bright { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -20); }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		TNT1 A 0 A_Jump(128, "Missile.T14.BFGSpam3");
		"MMDG" A 0 A_Jump(32, "Missile.T14");
		Goto Pain.T14.Reposition;
	// BFG SPAM -- five volleys that ACCELERATE (10, 8, 6, 4, 2 tics), so
	// the wall of green arrives faster the longer it goes on.
	Missile.T14.BFGSpam:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
		"MMDG" EEEE 5 { A_FaceTarget(); }
		"MMDG" F 10 Bright { RS_BFGVolley(1); }
		"MMDG" E 5 { A_FaceTarget(); }
		"MMDG" F 8 Bright { RS_BFGVolley(2); }
		"MMDG" E 4 { A_FaceTarget(); }
		"MMDG" F 6 Bright { RS_BFGVolley(1); }
		"MMDG" E 3 { A_FaceTarget(); }
		"MMDG" F 4 Bright { RS_BFGVolley(0); }
		"MMDG" E 2 { A_FaceTarget(); }
		"MMDG" F 2 Bright { RS_BFGVolley(0); }
		"MMDG" GG 3 Bright { A_FaceTarget(); }
		TNT1 A 0 A_Jump(32, "Missile.T14");
		Goto See;
	// Phase 2: eight volleys, each prefixed with four wide random shots.
	Missile.T14.BFGSpam2:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
		"MMDG" EEEE 5 { A_FaceTarget(); }
		"MMDG" F 10 Bright { RS_BFGWide(); RS_BFGVolley(1); }
		"MMDG" E 5 { A_FaceTarget(); }
		"MMDG" F 8 Bright { RS_BFGWide(); RS_BFGVolley(2); }
		"MMDG" E 4 { A_FaceTarget(); }
		"MMDG" F 6 Bright { RS_BFGWide(); RS_BFGVolley(1); }
		"MMDG" E 3 { A_FaceTarget(); }
		"MMDG" F 4 Bright { RS_BFGWide(); RS_BFGVolley(0); }
		"MMDG" E 2 { A_FaceTarget(); }
		"MMDG" F 2 Bright { RS_BFGWide(); RS_BFGVolley(0); }
		"MMDG" E 2 { A_FaceTarget(); }
		"MMDG" F 2 Bright { RS_BFGWide(); RS_BFGVolley(0); }
		"MMDG" E 2 { A_FaceTarget(); }
		"MMDG" F 2 Bright { RS_BFGWide(); RS_BFGVolley(0); }
		"MMDG" E 2 { A_FaceTarget(); }
		"MMDG" F 2 Bright { RS_BFGWide(); RS_BFGVolley(0); }
		"MMDG" GG 3 Bright { A_FaceTarget(); }
		TNT1 A 0 A_Jump(32, "Missile.T14");
		Goto See;
	// CHP's BFGSpam3 is a two-line stub that FALLS THROUGH into GlitchTrap
	// -- the wind-up sound and a face-target, then the ring of walls. Kept
	// exactly, fall-through and all.
	Missile.T14.BFGSpam3:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
		"MMDG" EEEE 5 { A_FaceTarget(); }
	// THE TRAP: sixteen solid walls in a ring around you. Not damage --
	// a cage, cast while everything else is still in the air.
	Missile.T14.GlitchTrap:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK2", CHAN_WEAPON, 0, 1.0, ATTN_NONE); }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" I 5 Bright { A_FaceTarget(); }
		"MMDG" EIEGGI 7 Bright { A_FaceTarget(); }
		"MMDG" E 8 Bright { A_VileTarget("RS_RomeroEXGlitchTrap"); }
		Goto See;
	Missile.T14.GlitchTrap2:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK2", CHAN_WEAPON, 0, 1.0, ATTN_NONE); }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" I 5 Bright { A_FaceTarget(); }
		"MMDG" EIEGGI 7 Bright { A_FaceTarget(); }
		"MMDG" E 8 Bright { A_VileTarget("RS_RomeroEXGlitchTrap"); }
		Goto Missile.T14;
	// CODE LEAKAGE: 131 bouncing binary digits (262 in phase 3) sprayed out
	// of a single point above it. Nothing aimed -- just fill.
	Missile.T14.CodeLeakage:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" Z 6 Bright { A_FaceTarget(); }
		"MMDG" Y 8 Bright { A_FaceTarget(); }
		"MMDG" Y 0 { A_SpawnItemEx("RS_RomeroEXCodeLeakage", 0, 0, 64, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDG" Y 8 Bright { A_FaceTarget(); }
		"MMDG" Z 6 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T14.CodeLeakage2:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK1", CHAN_VOICE); }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" Z 6 Bright { A_FaceTarget(); }
		"MMDG" Y 8 Bright { A_FaceTarget(); }
		"MMDG" Y 0 { A_SpawnItemEx("RS_RomeroEXCodeLeakage2", 0, 0, 64, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"MMDG" Y 8 Bright { A_FaceTarget(); }
		"MMDG" Z 6 Bright { A_FaceTarget(); }
		Goto See;
	// The orbiting reflector. One at a time -- rsGlitchShield is the latch,
	// and the shield itself clears it when it expires.
	Missile.T14.GlitchShields:
		TNT1 A 0 { if (rsGlitchShield >= 1) return ResolveState("Missile.T14"); return ResolveState(null); }
		"MMDG" E 5 Bright { rsGlitchShield = 1; }
		"MMDG" EEEE 10 Bright { A_SpawnItemEx("RS_RomeroEXShield", 0, 4, 64, 0, 0, 0, 0, SXF_SETMASTER | SXF_NOCHECKPOSITION); }
		"MMDG" A 0 A_Jump(128, "Missile.T14.FatalBarons", "Missile.T14");
		Goto See;
	// MINES: eight delayed proximity mines scattered across a 12x128 grid.
	// They arm slowly and sit for up to a minute, so they outlive the
	// attack that placed them.
	Missile.T14.GlitchMines:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK2", CHAN_VOICE); }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" EEEEEEEEE 2 Bright { A_SetScale(1.25, frandom(1.0, 1.5)); }
		"MMDG" EE 6 Bright { A_VileTarget("RS_RomeroEXGlitchMineSpawner"); }
		"MMDG" E 0 { A_SetScale(1.25, 1.25); }
		"MMDG" A 10 A_Jump(128, "Missile.T14");
		Goto See;
	Missile.T14.GlitchMines2:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK2", CHAN_VOICE); }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" EEEEEEEEE 2 Bright { A_SetScale(1.25, frandom(1.0, 1.5)); }
		"MMDG" EEE 4 Bright { A_VileTarget("RS_RomeroEXGlitchMineSpawner"); }
		"MMDG" E 0 { A_SetScale(1.25, 1.25); }
		"MMDG" A 10 A_Jump(192, "Missile.T14");
		Goto See;
	// LASER RAIN: drops the beam on you from the sky rather than firing it.
	Missile.T14.LaserRain:
		"MMDG" EEEE 3 { A_FaceTarget(); }
		"MMDG" JKLKJ 2 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 1 Bright { A_FaceTarget(); }
		"MMDG" MO 3 Bright;
		"MMDG" O 2 Bright { A_VileTarget("RS_RomeroEXSkyCH"); }
		Goto Missile.T14;
	Missile.T14.LaserRain2:
		"MMDG" EEEE 3 { A_FaceTarget(); }
		"MMDG" JKLKJ 2 Bright { A_FaceTarget(); }
		"MMDG" JKLKJ 1 Bright { A_FaceTarget(); }
		"MMDG" MO 3 Bright;
		"MMDG" OO 1 Bright { A_VileTarget("RS_RomeroEXSkyCH"); }
		Goto Missile.T14;
	// BFG HECK: eight crawlers that wander the ceiling firing BFG balls at
	// the floor and ceiling until they roll their own deaths.
	Missile.T14.BFGHeck:
		"MMDG" E 0 { A_StartSound("RomeEX/ATK2", CHAN_WEAPON, 0, 1.0, ATTN_NONE); }
		"MMDG" E 10 Bright { A_FaceTarget(); }
		"MMDG" Z 6 Bright { A_FaceTarget(); }
		"MMDG" Y 8 Bright { A_FaceTarget(); }
		"MMDG" YYYYYYYY 0 { A_SpawnItemEx("RS_RomeroEXBFGHeckSpawner"); }
		"MMDG" Y 8 Bright { A_FaceTarget(); }
		"MMDG" Z 6 Bright { A_FaceTarget(); }
		Goto See;
	// ======================= OVERDRIVE (phase 3) =======================
	// The meta-attack. Rolls one of seven sub-attacks, fires it, and then
	// ROLLS AGAIN -- chaining without ever returning to See -- until the
	// 16-count budget runs out and it blinks away. Each branch has a
	// 192/256 chance to skip its own blink-wander and fire immediately.
	Missile.T14.Overdrive:
		"MMDG" E 0 { A_StartSound("RomeEX/PH3", CHAN_WEAPON, 0, 1.0, ATTN_NONE); rsDewzan = 0; }
		"MMDG" E 10 Bright { A_FaceTarget(); }
	Missile.T14.OverdriveRoll:
		"MMDG" E 0 A_Jump(256, "Missile.T14.ODMissiles", "Missile.T14.ODGlitches", "Missile.T14.ODWall", "Missile.T14.ODLaser", "Missile.T14.ODWinder", "Missile.T14.ODBFG", "Missile.T14.ODTrap");
		Goto See;
	Missile.T14.ODMissiles:
		"MMDG" A 0 A_Jump(192, "Missile.T14.ODMissilesGo");
		"MMDG" AAAAAAAAAAAAAAAA 0 { A_Wander(); }
	Missile.T14.ODMissilesGo:
		TNT1 A 0 { if (rsDewzan >= 16) return ResolveState("Pain.T14.Reposition"); rsDewzan++; return ResolveState(null); }
		"MMDG" E 10 { A_FaceTarget(); }
		"MMDG" HIHIHIHIHI 1 Bright { A_SpawnProjectile("RS_RomeroRocketCH", 120, -20, random(-64, 64)); }
		Goto Missile.T14.OverdriveRoll;
	Missile.T14.ODGlitches:
		"MMDG" A 0 A_Jump(192, "Missile.T14.ODGlitchesGo");
		"MMDG" AAAAAAAAAAAAAAAA 0 { A_Wander(); }
	Missile.T14.ODGlitchesGo:
		TNT1 A 0 { if (rsDewzan >= 16) return ResolveState("Pain.T14.Reposition"); rsDewzan++; return ResolveState(null); }
		"MMDG" E 10 { A_FaceTarget(); }
		"MMDG" FFFFFF 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, 30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXMegaGlitchShot", 52, 30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" FFFFF 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXMegaGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" F 3 Bright { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" EEEEEE 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, 30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" EEEEE 0 { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		"MMDG" E 3 Bright { A_SpawnProjectile("RS_RomeroEXGlitchShot", 52, -30, random(-64, 64), CMF_AIMOFFSET, random(-5, 5)); }
		Goto Missile.T14.OverdriveRoll;
	Missile.T14.ODWall:
		"MMDG" A 0 A_Jump(192, "Missile.T14.ODWallGo");
		"MMDG" AAAAAAAAAAAAAAAA 0 { A_Wander(); }
	Missile.T14.ODWallGo:
		TNT1 A 0 { if (rsDewzan >= 16) return ResolveState("Pain.T14.Reposition"); rsDewzan++; return ResolveState(null); }
		"MMDG" E 10 { A_FaceTarget(); }
		"MMDG" O 0 { for (int i = 0; i < 9; i++) A_SpawnProjectile("RS_RomeroEXFourthWall", 52, 0, -90 + i * 20); }
		"MMDG" O 12 Bright { A_SpawnProjectile("RS_RomeroEXFourthWall", 52, 0, 90); }
		Goto Missile.T14.OverdriveRoll;
	Missile.T14.ODLaser:
		"MMDG" A 0 A_Jump(192, "Missile.T14.ODLaserGo");
		"MMDG" AAAAAAAAAAAAAAAA 0 { A_Wander(); }
	Missile.T14.ODLaserGo:
		TNT1 A 0 { if (rsDewzan >= 16) return ResolveState("Pain.T14.Reposition"); rsDewzan++; return ResolveState(null); }
		"MMDG" E 10 { A_FaceTarget(); }
		"MMDG" MNOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0); }
		"MMDG" O 0 { A_FaceTarget(); }
		"MMDG" OOOOOOOOOO 1 Bright { A_SpawnProjectile("RS_RomeroEXBeamCH", 60, 0, 0); }
		Goto Missile.T14.OverdriveRoll;
	Missile.T14.ODWinder:
		"MMDG" A 0 A_Jump(192, "Missile.T14.ODWinderGo");
		"MMDG" AAAAAAAAAAAAAAAA 0 { A_Wander(); }
	Missile.T14.ODWinderGo:
		TNT1 A 0 { if (rsDewzan >= 16) return ResolveState("Pain.T14.Reposition"); rsDewzan++; return ResolveState(null); }
		"MMDG" E 10 { A_FaceTarget(); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 33, 4); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 33, -4); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 4); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -4); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 12); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -12); }
		"MMDG" F 0 { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, 20); }
		"MMDG" F 10 Bright { A_SpawnProjectile("RS_RomeroEXCHSeekBall", 52, 27, -20); }
		Goto Missile.T14.OverdriveRoll;
	Missile.T14.ODBFG:
		"MMDG" A 0 A_Jump(192, "Missile.T14.ODBFGGo");
		"MMDG" AAAAAAAAAAAAAAAA 0 { A_Wander(); }
	Missile.T14.ODBFGGo:
		TNT1 A 0 { if (rsDewzan >= 16) return ResolveState("Pain.T14.Reposition"); rsDewzan++; return ResolveState(null); }
		"MMDG" E 10 { A_FaceTarget(); }
		"MMDG" F 2 Bright { RS_BFGWide(); RS_BFGVolley(0); }
		"MMDG" E 2 { A_FaceTarget(); }
		"MMDG" F 2 Bright { RS_BFGWide(); RS_BFGVolley(0); }
		"MMDG" E 2 { A_FaceTarget(); }
		"MMDG" F 2 Bright { RS_BFGWide(); RS_BFGVolley(0); }
		"MMDG" E 2 { A_FaceTarget(); }
		Goto Missile.T14.OverdriveRoll;
	Missile.T14.ODTrap:
		"MMDG" A 0 A_Jump(192, "Missile.T14.ODTrapGo");
		"MMDG" AAAAAAAAAAAAAAAA 0 { A_Wander(); }
	Missile.T14.ODTrapGo:
		TNT1 A 0 { if (rsDewzan >= 16) return ResolveState("Pain.T14.Reposition"); rsDewzan++; return ResolveState(null); }
		"MMDG" E 10 { A_FaceTarget(); }
		"MMDG" EEEEEEEEEEEEEEE 0 { A_SpawnItemEx("RS_RomeroEXGlitchBarrier", random(-12, 12) * 128, random(-12, 12) * 128); }
		"MMDG" E 8 Bright { A_SpawnItemEx("RS_RomeroEXGlitchBarrier", random(-12, 12) * 128, random(-12, 12) * 128); }
		Goto Missile.T14.OverdriveRoll;
	// PainChance 0 -- this never fires from damage. It is here because
	// RS's own systems can force a Pain state.
	Pain.T14:
		"MMDG" E 3;
		"MMDG" E 3 { A_Pain(); }
		Goto See;
	Death.T14:
		TNT1 A 0 { ReleaseMinions(); A_SetTranslucent(1.0, 1); }
		"MMDG" LMDLHDHNYFIEACKGZJNLBYIFBAFZB 6 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"MMDG" LMDLHDHNYFIEACKGZJNLBYIFBAFZB 3 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"MMDG" LMDLHDHNYFIEACKGZJNLBYIFBAFZB 1 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"MMDG" P 4 Bright { A_Scream(); }
		"MMDG" QRS 4 Bright { A_SpawnProjectile("RS_HKRedDeath", random(20, 100), random(-30, 30), 0, CMF_AIMOFFSET, -10); }
		"MMDG" T 4 Bright { A_NoBlocking(); }
		"MMDG" UV 4 Bright;
		TNT1 A 0 { A_BossDeath(); }
		// It does not end -- "the one behind it all" steps out of the wreck.
		"MMDG" W 0 { A_SpawnItemEx("RS_CyberdemonRomeroStage2", 0, 0, 0, 0, 0, 20, 0, SXF_NOCHECKPOSITION); }
		"MMDG" W -1;
		Stop;
	XDeath.T14:
		Goto Death.T14;
	}
}
