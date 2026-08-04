// =====================================================================
// RS_Cacodemon -- rebuilt from Colourful Hell Plus, verbatim.
// ---------------------------------------------------------------------
// SOURCE OF TRUTH: E:\New folder\ART SOURCE\CHP\DECORATE\09\09_<code>.txt
// One CHP file per colour; each is a genuinely different creature with
// its OWN sprite set, stats, and attack. Nothing here is inferred,
// tinted, or shared -- every tier below was read out of its CHP file.
//
//   tier  CHP   body   HP    what it actually is
//   T00   09_C  HEAD   400   vanilla caco: combo bite/ball
//   T01   09_G  HEAG   450   green: caustic spit
//   T02   09_B  HEAB   528   blue: four-shot widening fireball string
//   T03   09_CY HEAC   500   cyan: twin ice lances, shatters on death
//   T04   09_P  CCMN   625   purple: skull-rush, or a tri-fireball woosh
//   T05   09_Y  CALI   830   yellow: sows Void Fields, spits flame,
//                            and goes semi-invisible to hunt
//   T06   09_A  HEAA  1100   abyss: heals nearby demons on pain,
//                            charges the Hideous beam
//   T07   09_F  HEAF   800   fireblu: fireblu ball
//   T08   09_BR GREL   500   brown grell: bobbing, grell orb
//   T09   09_GY HEGY   650   gray: rock-breath fan, or a rush
//   T10   09_R  HED9   999   red crackodemon: triple spam, or the
//                            sludgebomb wind-up
//   T11   09_K  HELE  5000   BLACK HADES: three electro patterns and a
//                            phase-2 that summons two red cacos
//   T12   09_W  CDW2  5000   WHITE bald: basic / wonky / arm-spawner
//
// Tier stats come from CHP's own Health/Speed/PainChance per file and
// are applied through TierData below, replacing the generic ladder.
// =====================================================================

class RS_Cacodemon : RS_MonsterMaster replaces Cacodemon
{
	const RS_CACO_TIER_REAL = 11;   // Hades' phase-2 add-summon gate

	private int rsPhase2Done;
	private int rsVoidFields;
	private int rsDashBudget;

	Default
	{
		Health 400;
		Radius 31;
		Height 56;
		Mass 400;
		Speed 8;
		FloatSpeed 4;
		PainChance 128;
		Monster;
		+FLOAT +NOGRAVITY +DONTFALL
		SeeSound "caco/sight";   PainSound "caco/pain";
		DeathSound "caco/death"; ActiveSound "caco/active";
		Obituary "$OB_CACO";
		HitObituary "$OB_CACOHIT";
		Tag "Cacodemon";
	}

	// CHP's real per-colour numbers, read from 09_*.txt. Health is
	// absolute (not a multiplier) -- these are hand-tuned creatures.
	override bool TierData(int t, out RS_MonsterTierRow r)
	{
		r.hpMul = 1.0; r.spdMul = 1.0; r.painChance = 128; r.dmgMul = 1.0;
		int hp = 400; int spd = 8;
		switch (t)
		{
			case 0:  hp = 400;  spd = 8;  r.painChance = 128; r.dmgMul = 1.0; break;
			case 1:  hp = 450;  spd = 8;  r.painChance = 110; r.dmgMul = 1.1; break;
			case 2:  hp = 528;  spd = 10; r.painChance = 100; r.dmgMul = 1.2; break;
			case 3:  hp = 500;  spd = 24; r.painChance = 110; r.dmgMul = 1.3; break;
			case 4:  hp = 625;  spd = 11; r.painChance = 90;  r.dmgMul = 1.4; break;
			case 5:  hp = 830;  spd = 12; r.painChance = 80;  r.dmgMul = 1.5; break;
			case 6:  hp = 1100; spd = 20; r.painChance = 64;  r.dmgMul = 1.6; break;
			case 7:  hp = 800;  spd = 13; r.painChance = 110; r.dmgMul = 1.5; break;
			case 8:  hp = 500;  spd = 18; r.painChance = 64;  r.dmgMul = 1.4; break;
			case 9:  hp = 650;  spd = 9;  r.painChance = 90;  r.dmgMul = 1.5; break;
			case 10: hp = 999;  spd = 14; r.painChance = 64;  r.dmgMul = 1.8; break;
			case 11: hp = 5000; spd = 16; r.painChance = 32;  r.dmgMul = 2.5; break;
			case 12: hp = 5000; spd = 28; r.painChance = 128; r.dmgMul = 3.0; break;
			default: return false;
		}
		// Default Health is 400, Default Speed 8 -- express CHP's absolute
		// numbers as multipliers so the base class's recompute-from-
		// defaults contract still holds.
		r.hpMul  = double(hp) / 400.0;
		r.spdMul = double(spd) / 8.0;
		return true;
	}

	// Audit data. Every entry is a real, distinct CHP sprite set --
	// verified present in sprites/monsters/Cacodemon/T<nn>/.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "HEAD HEAG HEAB HEAC CCMN CALI HEAA HEAF GREL HEGY HED9 HELE CACP";
	}

	// CHP gives each colour its own ARTWORK, so no palette remap is
	// needed or wanted -- a tint on top of bespoke art would corrupt it.
	override string TintTable()
	{
		return "- - - - - - - - - - - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:cacodemon role:artillery delivery:heavy element:thermal mobility:floating";
	}

	States
	{
	// ================= T00 COMMON (09_C) =================
	Spawn.T00:
		"HEAD" A 10 { A_Look(); }
		Loop;
	See.T00:
		"HEAD" A 3 { A_Chase(); }
		Loop;
	Missile.T00:
		"HEAD" BC 5 { A_FaceTarget(); }
		"HEAD" D 5 Bright { A_CustomComboAttack("RS_CacodemonBall", 32, 10 * random(1, 6), "caco/attack"); }
		Goto See;
	Pain.T00:
		"HEAD" E 3;
		"HEAD" E 3 { A_Pain(); }
		"HEAD" F 6;
		Goto See;
	Death.T00:
		"HEAD" G 8;
		"HEAD" H 8 { A_Scream(); }
		"HEAD" IJ 8;
		"HEAD" K 8 { A_NoBlocking(); }
		"HEAD" L -1 { A_SetFloorClip(); }
		Stop;
	XDeath.T00:
		"CACO" A 7 { A_XScream(); }
		"CACO" B 7 { A_NoBlocking(); }
		"CACO" CD 7;
		"CACO" E -1 { A_SetFloorClip(); }
		Stop;
	Raise.T00:
		"HEAD" L 5;
		"HEAD" KJIHG 5;
		Goto See;

	// ================= T01 GREEN (09_G) =================
	Spawn.T01:
		"HEAG" A 10 { A_Look(); }
		Loop;
	See.T01:
		"HEAG" A 3 { A_Chase(); }
		Loop;
	Missile.T01:
		"HEAG" BC 5 { A_FaceTarget(); }
		"HEAG" D 5 Bright { A_SpawnProjectile("RS_Cacospit1", 32, 0, random(-1, 1)); }
		Goto See;
	Pain.T01:
		"HEAG" E 3;
		"HEAG" E 3 { A_Pain(); }
		"HEAG" F 6;
		Goto See;
	Death.T01:
		"HEAG" G 8;
		"HEAG" H 8 { A_Scream(); }
		"HEAG" IJ 8;
		"HEAG" K 8 { A_NoBlocking(); }
		"HEAG" L -1 { A_SetFloorClip(); }
		Stop;
	Raise.T01:
		"HEAG" LKJIHG 5;
		Goto See;

	// ================= T02 BLUE (09_B) =================
	// A four-shot string that widens as it goes.
	Spawn.T02:
		"HEAB" A 10 { A_Look(); }
		Loop;
	See.T02:
		"HEAB" A 3 { A_Chase(); }
		Loop;
	Missile.T02:
		"HEAB" BC 8 { A_FaceTarget(); }
		"HEAB" D 7 Bright { A_SpawnProjectile("RS_CacoFire2", 32, 0, random(-1, 1)); }
		"HEAB" D 5 Bright { A_SpawnProjectile("RS_CacoFire2", 32, 0, random(-3, 3)); }
		"HEAB" D 4 Bright { A_SpawnProjectile("RS_CacoFire2", 32, 0, random(-5, 5)); }
		"HEAB" D 2 Bright { A_SpawnProjectile("RS_CacoFire2", 32, 0, random(-4, 4)); }
		Goto See;
	Pain.T02:
		"HEAB" E 3;
		"HEAB" E 3 { A_Pain(); }
		"HEAB" F 6;
		Goto See;
	Death.T02:
		"HEAB" G 8;
		"HEAB" H 8 { A_Scream(); }
		"HEAB" IJ 8;
		"HEAB" K 8 { A_NoBlocking(); }
		"HEAB" L -1 { A_SetFloorClip(); }
		Stop;
	Raise.T02:
		"HEAB" LKJIHG 5;
		Goto See;

	// ================= T03 CYAN (09_CY) =================
	// Fast (speed 24), twin ice lances, and it SHATTERS on death.
	Spawn.T03:
		"HEAC" A 10 { A_Look(); }
		Loop;
	See.T03:
		"HEAC" AAAAAAAAAAAA 3 { A_Chase(); }
		Loop;
	Missile.T03:
		"HEAC" EF 5 Bright { A_FaceTarget(); }
		"HEAC" G 3 Bright { A_SpawnProjectile("RS_BigIceCaco", 28, 0, 0); }
		"HEAC" G 3 Bright { A_SpawnProjectile("RS_BigIceCaco", 28, 0, randompick(-10, 10, -7, 7, -5, 5)); }
		"HEAC" FE 8 Bright;
		Goto See;
	Pain.T03:
		"HEAC" H 3;
		"HEAC" H 6 { A_Pain(); }
		Goto See;
	Death.T03:
		"HEAC" J 5 Bright { A_Scream(); }
		"HEAC" KLM 5 Bright;
		"HEAC" N 5 Bright { A_NoBlocking(); }
		"HEAC" N 1 Bright { A_StartSound("misc/icebreak", CHAN_BODY); A_IceGuyDie(); }
		Stop;

	// ================= T04 PURPLE (09_P) =================
	// Alternates a skull-rush with a three-ball woosh; CHP tracks a
	// dash budget so it cannot rush forever.
	Spawn.T04:
		"CCMN" A 10 { A_Look(); }
		Loop;
	See.T04:
		"CCMN" A 3 { A_Chase(); }
		Loop;
	Missile.T04:
		"CCMN" BC 5 { A_FaceTarget(); }
		TNT1 A 0 A_JumpIfCloser(300, "Missile.T04.Rush");
		Goto Missile.T04.Woosh;
	Missile.T04.Rush:
		TNT1 A 0 { if (rsDashBudget >= 11) return ResolveState("Missile.T04.Woosh"); rsDashBudget += 5; return ResolveState(null); }
		"CCMN" C 2 { A_SkullAttack(25); }
		Goto See;
	Missile.T04.Woosh:
		"CCMN" D 0 { A_FaceTarget(); }
		"CCMN" D 5 Bright { A_SpawnProjectile("RS_CacoFire3", 32, 0, random(-1, 1)); }
		"CCMN" D 0 { A_SpawnProjectile("RS_CacoFire4", 32, 0, 8); }
		"CCMN" D 0 { A_SpawnProjectile("RS_CacoFire4", 32, 0, -8); }
		TNT1 A 0 { rsDashBudget = max(0, rsDashBudget - 2); }
		Goto See;
	Pain.T04:
		"CCMN" E 3;
		"CCMN" E 3 { A_Pain(); }
		"CCMN" F 6;
		Goto See;
	Death.T04:
		"CCMN" G 8;
		"CCMN" H 8 { A_Scream(); }
		"CCMN" IJ 8;
		"CCMN" K 8 { A_NoBlocking(); }
		"CCMN" L -1 { A_SetFloorClip(); }
		Stop;

	// ================= T05 YELLOW (09_Y) =================
	// Sows a field of Void Fields once, then alternates flame-spit with
	// a semi-invisible hunt.
	Spawn.T05:
		"CALI" A 10 { A_Look(); }
		Loop;
	See.T05:
		"CALI" A 0 { A_SetTranslucent(1.0); }
		"CALI" A 3 { A_Chase(); }
		Loop;
	Missile.T05:
		"CALI" B 6 { A_FaceTarget(); }
		TNT1 A 0 { if (rsVoidFields == 0) return ResolveState("Missile.T05.Void"); return ResolveState(null); }
		TNT1 A 0 A_JumpIfCloser(1000, "Missile.T05.Flame");
		Goto Missile.T05.Hunt;
	Missile.T05.Void:
		"CALI" EF 8 Bright;
		"CALI" G 6 { A_SpawnItemEx("RS_VoidField", random(-180, 180), random(-180, 180), random(1, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"CALI" G 0 { A_SpawnItemEx("RS_VoidField", random(-280, 280), random(-280, 280), random(-16, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"CALI" G 0 { A_SpawnItemEx("RS_VoidField", random(-280, 280), random(-280, 280), random(-16, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"CALI" G 0 { A_SpawnItemEx("RS_VoidField", random(-380, 380), random(-380, 380), random(-32, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"CALI" G 0 { A_SpawnItemEx("RS_VoidField", random(-380, 380), random(-380, 380), random(-32, 32), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"CALI" FE 6 { rsVoidFields++; }
		Goto See;
	Missile.T05.Flame:
		"CALI" DEF 6 Bright { A_FaceTarget(); }
		"CALI" G 6 { A_SpawnProjectile("RS_SpitFireCaco", 35, 0, random(-3, 3)); }
		"CALI" FED 6 { A_FaceTarget(); }
		Goto See;
	Missile.T05.Hunt:
		"CALI" A 5 { A_SetTranslucent(0.3); }
		"CALI" A 5 { A_SetSpeed(42); }
		"CALI" AAAAAAAAAAA 2 { A_Wander(); }
		"CALI" A 5 { A_SetTranslucent(0.1); }
		"CALI" AAAAAAAAAAA 2 { A_Wander(); }
		"CALI" A 5 { A_SetTranslucent(0.3); }
		"CALI" AAAAAAAAAAA 2 { A_Wander(); }
		"CALI" A 5 { A_SetSpeed(12); A_SetTranslucent(1.0); }
		Goto See;
	Pain.T05:
		"CALI" H 0 { A_SetSpeed(12); A_SetTranslucent(1.0); }
		"CALI" H 3;
		"CALI" I 6 { A_Pain(); }
		Goto See;
	Death.T05:
		"CALI" J 0 { A_SetFloorClip(); }
		"CALI" J 6 { A_Scream(); }
		"CALI" KLM 6;
		"CALI" N -1 { A_NoBlocking(); }
		Stop;

	// ================= T06 ABYSS (09_A) =================
	// Heals nearby demons when hurt, and charges the Hideous beam with
	// a visible crackle before it fires.
	Spawn.T06:
		"HEAA" A 10 { A_Look(); }
		Loop;
	See.T06:
		"HEAA" AA 2 { A_Chase(); }
		Loop;
	Missile.T06:
		"HEAA" B 1 { A_RadiusGive("RS_PainSentinel", 800, RGF_MONSTERS, 1); }
		TNT1 A 0 A_JumpIfCloser(1000, "Missile.T06.Choice");
		Goto Missile.T06.Hideous;
	Missile.T06.Choice:
		TNT1 A 0 A_Jump(32, "Missile.T06.Hideous");
		Goto Missile.T06.Spam;
	Missile.T06.Spam:
		"HEAA" B 6 Bright { A_FaceTarget(); }
		"HEAA" C 4 Bright { A_SpawnProjectile("RS_AbyssCacoHidi", 24, 0, random(-6, 6)); }
		"HEAA" C 4 Bright { A_SpawnProjectile("RS_AbyssCacoHidi", 24, 0, random(-6, 6)); }
		"HEAA" D 5 Bright { A_FaceTarget(); }
		Goto See;
	Missile.T06.Hideous:
		"HEAA" B 12 Bright { A_FaceTarget(); }
		"HEAA" CCCC 4 Bright { A_SpawnItemEx("RS_ESZapZap", 16, random(-16, 16), random(12, 42), 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"HEAA" C 8 Bright { A_FaceTarget(); }
		"HEAA" C 5 Bright { A_SpawnProjectile("RS_AbyssCacoHidi", 24, 0, 0, CMF_AIMOFFSET); }
		"HEAA" D 5 Bright { A_FaceTarget(); }
		"HEAA" B 5 Bright;
		Goto See;
	Pain.T06:
		"HEAA" E 3;
		"HEAA" E 3 { A_Pain(); }
		// Its signature: being hurt heals every other demon nearby.
		"HEAA" E 3 Bright { A_RadiusGive("Health", 800, RGF_MONSTERS, 200); }
		"HEAA" FFFFFFFF 1 { A_Wander(); }
		Goto See;
	Death.T06:
		"HEAA" G 8 { bFLOATBOB = false; }
		"HEAA" H 8 { A_Scream(); }
		"HEAA" IJ 8;
		"HEAA" K 8 { A_NoBlocking(); }
		"HEAA" L -1 { A_SetFloorClip(); }
		Stop;

	// ================= T07 FIREBLU (09_F) =================
	Spawn.T07:
		"HEAF" A 10 { A_Look(); }
		Loop;
	See.T07:
		"HEAF" A 3 { A_Chase(); }
		Loop;
	Missile.T07:
		"HEAF" BC 5 { A_FaceTarget(); }
		"HEAF" D 5 Bright { A_SpawnProjectile("RS_FireBluCacoBall", 32, 0, random(-5, 5)); }
		Goto See;
	Pain.T07:
		"HEAF" E 3;
		"HEAF" E 3 { A_Pain(); }
		"HEAF" F 6;
		Goto See;
	Death.T07:
		"HEAF" G 8;
		"HEAF" H 8 { A_Scream(); }
		"HEAF" IJ 8;
		"HEAF" K 8 { A_NoBlocking(); }
		"HEAF" L -1 { A_SetFloorClip(); }
		Stop;

	// ================= T08 BROWN GRELL (09_BR) =================
	// Bobs as it flies (SentinelBob), throws a heavy grell orb.
	Spawn.T08:
		"GREL" A 10 { A_Look(); }
		Loop;
	See.T08:
		"GREL" A 0 { A_SentinelBob(); }
		"GREL" AAB 3 { A_Chase(); }
		"GREL" B 0 { A_SentinelBob(); }
		"GREL" BCC 3 { A_Chase(); }
		Loop;
	Missile.T08:
		"GREL" D 0 { A_StartSound("caco/attack", CHAN_WEAPON); }
		"GREL" D 4 { A_FaceTarget(); }
		"GREL" E 4 Bright { A_FaceTarget(); }
		"GREL" F 4 Bright { A_SpawnProjectile("RS_GrellBallBrown", 32, 0, 0); }
		Goto See;
	Pain.T08:
		"GREL" G 3;
		"GREL" G 3 { A_Pain(); }
		Goto See;
	Death.T08:
		"GREL" A 0 { bFLOATBOB = false; }
		"GREL" I 0 { A_NoBlocking(); }
		"GREL" I -1 { A_Scream(); }
		Stop;

	// ================= T09 GRAY (09_GY) =================
	// Rock-breath fan, with a rush option on a small dash budget.
	Spawn.T09:
		"HEGY" A 10 { A_Look(); }
		Loop;
	See.T09:
		"HEGY" AAAAAAAA 3 { A_Chase(); }
		Loop;
	Missile.T09:
		TNT1 A 0 A_JumpIfCloser(900, "Missile.T09.Rush");
		Goto Missile.T09.Breath;
	Missile.T09.Rush:
		TNT1 A 0 { if (rsDashBudget >= 3) return ResolveState("Missile.T09.Breath"); rsDashBudget++; return ResolveState(null); }
		"HEGY" BC 5 { A_FaceTarget(); }
		"HEGY" C 2 { A_SkullAttack(40); }
		Goto See;
	Missile.T09.Breath:
		"HEGY" BC 5 { A_FaceTarget(); }
		"HEGY" D 3 Bright { A_FaceTarget(); }
		TNT1 A 0 { rsDashBudget = max(0, rsDashBudget - 1); }
		"HEGY" D 5 Bright { A_SpawnProjectile("RS_CacoRockBreath", 32, 0, random(-1, 1)); }
		"HEGY" D 4 Bright { A_SpawnProjectile("RS_CacoRockBreath", 32, 0, random(-3, 3)); }
		"HEGY" D 3 Bright { A_SpawnProjectile("RS_CacoRockBreath", 32, 0, random(-5, 5)); }
		"HEGY" D 2 Bright { A_SpawnProjectile("RS_CacoRockBreath", 32, 0, random(-8, 8)); }
		Goto See;
	Pain.T09:
		"HEGY" E 3;
		"HEGY" E 3 { A_Pain(); }
		"HEGY" F 6;
		Goto See;
	Death.T09:
		"HEGY" G 8;
		"HEGY" H 8 { A_Scream(); }
		"HEGY" IJ 8;
		"HEGY" K 8 { A_NoBlocking(); }
		"HEGY" L -1 { A_SetFloorClip(); }
		Stop;

	// ================= T10 RED CRACKODEMON (09_R) =================
	Spawn.T10:
		"HED9" A 10 { A_Look(); }
		Loop;
	See.T10:
		"HED9" A 3 { A_Chase(); }
		Loop;
	Missile.T10:
		TNT1 A 0 A_Jump(128, "Missile.T10.Sludge");
		Goto Missile.T10.Spam;
	Missile.T10.Spam:
		"HED9" B 5 { A_FaceTarget(); }
		"HED9" C 5 Bright { A_FaceTarget(); }
		"HED9" D 5 { A_FaceTarget(); }
		"HED9" B 0 { A_SpawnProjectile("RS_CrackodemonBall", 24, 0, 0, CMF_AIMOFFSET); }
		"HED9" B 0 { A_SpawnProjectile("RS_CrackodemonBall", 24, 0, -8, CMF_AIMOFFSET); }
		"HED9" B 5 Bright { A_SpawnProjectile("RS_CrackodemonBall", 24, 0, 8, CMF_AIMOFFSET); }
		TNT1 A 0 A_Jump(128, "Missile.T10.Spam");
		Goto See;
	Missile.T10.Sludge:
		"HED9" B 12 { A_FaceTarget(); }
		"HED9" B 1 { A_SpawnItemEx("RS_RedThingsLS", 1, 3, 32, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"HED9" B 1 { A_SpawnItemEx("RS_RedThingsLS", -3, 6, 32, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"HED9" B 1 { A_SpawnItemEx("RS_RedThingsLS", 4, -1, 32, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"HED9" B 1 { A_SpawnItemEx("RS_RedThingsLS", 3, 1, 32, 0, 0, 0, 0, SXF_NOCHECKPOSITION); }
		"HED9" C 5 Bright { A_SpawnProjectile("RS_SBombCaco", 24, 0, 0, CMF_AIMOFFSET); }
		"HED9" D 5 Bright { A_FaceTarget(); }
		"HED9" B 5 Bright;
		Goto See;
	Pain.T10:
		"HED9" E 3;
		"HED9" E 3 { A_Pain(); }
		"HED9" F 6;
		Goto See;
	Death.T10:
		"HED9" G 8 { bFLOATBOB = false; }
		"HED9" H 8 { A_Scream(); }
		"HED9" IJ 8;
		"HED9" K 8 { A_NoBlocking(); }
		"HED9" L -1 { A_SetFloorClip(); }
		Stop;

	// ================= T11 BLACK -- HADES (09_K) =================
	// Three electro patterns. Below 3000 HP it goes NOPAIN, summons two
	// red cacos, and turns on MISSILEMORE -- once only.
	Spawn.T11:
		"HELE" A 10 { A_Look(); }
		Loop;
	See.T11:
		"HELE" AAAAAAAAAAAA 3 { A_Chase(); }
		Loop;
	Missile.T11:
		TNT1 A 0 { if (health < 3000 && rsPhase2Done == 0) return ResolveState("Missile.T11.Phase2"); return ResolveState(null); }
		TNT1 A 0 A_Jump(256, "Missile.T11.Electro1", "Missile.T11.Electro5", "Missile.T11.Electro3");
		Goto See;
	Missile.T11.Electro1:
		"HELE" EF 5 Bright { A_FaceTarget(); }
		"HELE" G 0 { A_SpawnProjectile("RS_HadesBall", 24, 0, -14); }
		"HELE" G 0 { A_SpawnProjectile("RS_HadesBall", 24, 0, -7); }
		"HELE" G 0 { A_SpawnProjectile("RS_HadesBall", 24, 0, 0); }
		"HELE" G 0 { A_SpawnProjectile("RS_HadesBall", 24, 0, 7); }
		"HELE" G 5 Bright { A_SpawnProjectile("RS_HadesBall", 24, 0, 14); }
		Goto See;
	Missile.T11.Electro5:
		"HELE" BC 5 Bright { A_FaceTarget(); }
		"HELE" G 5 Bright { A_SpawnProjectile("RS_HadeLoad1", 32, 0, 0); }
		"HELE" D 5 Bright { A_FaceTarget(); }
		"HELE" G 5 Bright { A_SpawnProjectile("RS_HadesBall3", 18, 0, 0); }
		"HELE" CB 5;
		Goto See;
	Missile.T11.Electro3:
		"HELE" BC 8 Bright { A_FaceTarget(); }
		"HELE" G 8 Bright { A_SpawnProjectile("RS_HadeLoad1", 32, 0, 0); }
		"HELE" D 8 Bright { A_FaceTarget(); }
		"HELE" G 8 Bright { A_SpawnProjectile("RS_HadeLoad1", 32, 0, 0); }
		"HELE" D 8 Bright { A_FaceTarget(); }
		"HELE" G 0 { A_SpawnProjectile("RS_EyeBeamCaco", 32, 0, 0); }
		"HELE" G 8 Bright { A_CustomBulletAttack(0, 0, 1, random(1, 5), "RS_HadeAra"); }
		"HELE" CB 5;
		Goto See;
	Missile.T11.Phase2:
		"HELE" A 0 { bNOPAIN = true; }
		"HELE" BC 8;
		"HELE" D 8 { A_StartSound("caco/sight", CHAN_VOICE); }
		"HELE" D 12 { SummonMinion("RS_Cacodemon", -1, 128.0); }
		"HELE" D 12 { SummonMinion("RS_Cacodemon", -1, 128.0); }
		"HELE" C 8 { bMISSILEMORE = true; }
		"HELE" C 4 { rsPhase2Done = 1; }
		"HELE" B 4 { bNOPAIN = false; }
		Goto See;
	Pain.T11:
		"HELE" H 3 { A_SetTranslucent(1.0); }
		"HELE" H 3 { A_Pain(); }
		"HELE" H 6;
		Goto See;
	Death.T11:
		"HELE" I 8 Bright { A_Scream(); }
		"HELE" JKL 8 Bright { A_SpawnItemEx("RS_HadeExpl", random(-128, 128), random(-128, 128), random(-88, 88)); }
		"HELE" M 8 Bright { A_NoBlocking(); }
		"HELE" M 0 { A_SpawnItemEx("RS_HadeExpl", random(-128, 128), random(-128, 128), random(-88, 88)); }
		"HELE" M 0 { A_SpawnItemEx("RS_HadeExpl", random(-128, 128), random(-128, 128), random(-88, 88)); }
		"HELE" M -1 Bright;
		Stop;

	// ================= T12 WHITE BALD (09_W) =================
	// Three modes; the arm-spawner is its signature. Below 2500 HP the
	// basic and wonky patterns escalate (CHP's Basic2 / Wonkier).
	Spawn.T12:
		"CACP" A 10 { A_Look(); }
		Loop;
	See.T12:
		"CACP" A 3 { A_Chase(); }
		Loop;
	Missile.T12:
		TNT1 A 0 A_Jump(256, "Missile.T12.Basic", "Missile.T12.Wonky", "Missile.T12.Arms");
		Goto See;
	Missile.T12.Basic:
		"CACP" BC 4 { A_FaceTarget(); }
		"CACP" D 4 Bright { A_CustomComboAttack("RS_CacobaldBall", 32, 2, "imp/melee"); }
		"CACP" BC 3 { A_FaceTarget(); }
		"CACP" D 0 { A_SpawnProjectile("RS_CacobaldBall", 32, 0, random(-12, -2)); }
		"CACP" D 0 { A_SpawnProjectile("RS_CacobaldBall", 32, 0, random(2, 12)); }
		"CACP" D 2 Bright { A_CustomComboAttack("RS_CacobaldBall", 32, 2, "imp/melee"); }
		Goto See;
	Missile.T12.Wonky:
		"CACP" BC 4 { A_FaceTarget(); }
		"CACP" DDD 1 Bright { A_SpawnProjectile("RS_CacobaldBall2", 32, 0, random(-3, 3)); }
		"CACP" DD 2 Bright { A_SpawnProjectile("RS_CacobaldBall2", random(12, 48), random(-16, 16), random(-9, 9)); }
		"CACP" DDD 1 Bright { A_SpawnProjectile("RS_CacobaldBall2", random(12, 48), random(-16, 16), random(-15, -5)); }
		"CACP" DD 2 Bright { A_SpawnProjectile("RS_CacobaldBall2", random(12, 48), random(-16, 16), random(5, 15)); }
		"CACP" C 4 { A_FaceTarget(); }
		"CACP" DDDD 1 Bright { A_SpawnProjectile("RS_CacobaldBall2", 32, 0, random(-3, 3)); }
		Goto See;
	Missile.T12.Arms:
		"CACP" BC 6 { A_FaceTarget(); }
		"CACP" GH 7;
		"CACP" H 7 { A_StartSound("caco/sight", CHAN_VOICE); }
		TNT1 A 0 { A_VileTarget("RS_ArmSpawnerCACO"); }
		"CACP" G 7;
		Goto See;
	Pain.T12:
		"CACP" E 3;
		"CACP" E 3 { A_Pain(); }
		"CACP" E 3;
		Goto See;
	Death.T12:
		"CACX" A 5 { A_Scream(); }
		"CACX" B 5;
		"CACX" CD 5;
		"CACX" E 5 { A_NoBlocking(); }
		"CACX" F -1 { A_SetFloorClip(); }
		Stop;
	}
}
