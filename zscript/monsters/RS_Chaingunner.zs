// =====================================================================
// RS_Chaingunner -- per-tier state rebuild
// (docs/rs_09_monster_rebuild_spec.txt). Replaces ChaingunGuy.
//
// THIRTEEN REAL CREATURES. Each tier is its own state cluster with
// literal sprites and Colourful Hell's own attack for that colour,
// ported from CH decorate/Chaingunners.txt via the proven HF port.
// Every tier keeps the chaingunner's defining shape -- a sustained
// A_CPosRefire loop -- but what comes OUT of the gun changes:
//
//   T00 CPOS vanilla chaingun     T01 CPOS+tint faster cadence
//   T02 CPOS+tint tracer + puff   T03 CPS2 frost rounds
//   T04 CPOS+tint fast chaingun   T05 PZOW plasma bolts
//   T06 PZOW twin abyss shots     T07 PZOW fire rounds
//   T08 CZV1 bullet + brown orb   T09 PZOW heavy slug cadence
//   T10 CPS2 rapid heavy rounds   T11 BFGZ rapid, or artillery+shield
//   T12 FSZS apex: needle storm, or poison puddles
//
// RS mechanic preserved: the T08+ post-threshold CallHelp summon,
// rolled in the Missile DISPATCHER so every tier inherits it.
// =====================================================================

class RS_Chaingunner : RS_HumanMonster replaces ChaingunGuy
{
	Default
	{
		Health 70;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 170;
		Monster;
		+FLOORCLIP
		SeeSound "chainguy/sight";  PainSound "chainguy/pain";
		DeathSound "chainguy/death"; ActiveSound "chainguy/active";
		AttackSound "chainguy/attack";
		Obituary "$OB_CHAINGUY";
		Tag "Chaingunner";
		DropItem "Chaingun";
	}

	// Audit data -- the clusters below are the live implementation.
	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "CPOS CPOS CPOS CPS2 CPOS PZOW PZOW PZOW CZV1 PZOW CPS2 BFGZ FSZS";
	}

	override string TintTable()
	{
		return "- rs_cgun_t01 rs_cgun_t02 rs_cgun_t03 rs_cgun_t04 rs_cgun_t05 "
		       "rs_cgun_t06 rs_cgun_t07 rs_cgun_t08 rs_cgun_t09 - - -";
	}

	override string GetBaseKeywords()
	{
		return "species:chaingunner role:skirmisher delivery:bullet element:kinetic mobility:ground";
	}

	// -----------------------------------------------------------------
	// CHP's white chaingunner enrages at ~2/3 health and PERMANENTLY
	// gains a summon it did not have before -- the second half of the
	// fight is a different fight. That's the mechanic worth keeping.
	// -----------------------------------------------------------------
	const RS_CG_RAGE_SLOT  = 0;
	const RS_CG_TIER_PHASE = 8;

	override bool MinionsDieWithMe() { return true; }

	// Fires the one-shot rage gate. Called from Pain so the threshold is
	// checked whenever it actually takes damage.
	void RS_CheckRage()
	{
		if (Tier >= RS_CG_TIER_PHASE && CheckThreshold(RS_CG_RAGE_SLOT, 0.66))
		{
			Enrage(1.2);
			A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
		}
	}

	States
	{
	// ===== dispatchers: family-wide rolls happen here =====
	Missile:
		TNT1 A 0
		{
			// Only reachable AFTER the rage threshold has fired.
			if (Tier >= RS_CG_TIER_PHASE && ThresholdFired(RS_CG_RAGE_SLOT)
			    && random(0, 255) < 60)
				return ResolveState("CallHelp");
			return TierState("Missile");
		}
		Goto See;
	CallHelp:
		// Bare #### keeps this tier's body; E/F exist on every one.
		#### E 10 { A_FaceTarget(); }
		#### F 12 Bright
		{
			if (SummonPack("RS_Imp", 2, 4, -2, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}
		Goto See;
	Pain:
		TNT1 A 0
		{
			RS_CheckRage();
			return TierState("Pain");
		}
		Goto See;

	// ===== CPOS body: T00 T01 T02 T04 =====
	Spawn.T00:
	Spawn.T01:
	Spawn.T02:
	Spawn.T04:
		"CPOS" AB 10 { A_Look(); }
		Loop;
	See.T00:
	See.T01:
	See.T02:
	See.T04:
		"CPOS" AABBCCDD 3 { A_Chase(); }
		Loop;
	Pain.T00:
	Pain.T01:
	Pain.T02:
	Pain.T04:
		"CPOS" G 3;
		"CPOS" G 3 { A_Pain(); }
		Goto See;
	Death.T00:
	Death.T01:
	Death.T02:
	Death.T04:
		"CPOS" H 5;
		"CPOS" I 5 { A_Scream(); }
		"CPOS" J 5 { A_NoBlocking(); }
		"CPOS" KLM 5;
		"CPOS" N -1;
		Stop;
	XDeath.T00:
	XDeath.T01:
	XDeath.T02:
	XDeath.T04:
		"CPOS" O 5;
		"CPOS" P 5 { A_XScream(); }
		"CPOS" Q 5 { A_NoBlocking(); }
		"CPOS" RS 5;
		"CPOS" T -1;
		Stop;
	Raise.T00:
	Raise.T01:
	Raise.T02:
	Raise.T04:
		"CPOS" NMLKJIH 5;
		Goto See;

	// T00 -- vanilla chaingun burst
	Missile.T00:
		"CPOS" E 10 { A_FaceTarget(); }
	Missile.T00.Loop:
		"CPOS" F 4 Bright { A_CPosAttack(); }
		"CPOS" E 4 { A_CPosRefire(); }
		Goto Missile.T00.Loop;

	// T01 GREEN -- same gun, tighter cadence
	Missile.T01:
		"CPOS" E 8 { A_FaceTarget(); }
	Missile.T01.Loop:
		"CPOS" F 3 Bright { A_CPosAttack(); }
		"CPOS" E 3 { A_CPosRefire(); }
		Goto Missile.T01.Loop;

	// T02 BLUE -- single tracer rounds trailing a charged puff
	Missile.T02:
		"CPOS" E 8 { A_FaceTarget(); }
	Missile.T02.Loop:
		"CPOS" F 3 Bright { A_CustomBulletAttack(5.6, 0, 1, random(3, 9), "BulletPuff"); }
		"CPOS" F 0 Bright { A_SpawnProjectile("RS_BlueChainPuff3", 16, 0, 0); }
		"CPOS" E 3 { A_CPosRefire(); }
		Goto Missile.T02.Loop;

	// T04 PURPLE -- fast chaingun
	Missile.T04:
		"CPOS" E 8 { A_FaceTarget(); }
	Missile.T04.Loop:
		"CPOS" F 3 Bright { A_CPosAttack(); }
		"CPOS" E 3 { A_CPosRefire(); }
		Goto Missile.T04.Loop;

	// ===== CPS2 body: T03 (frost) and T10 (red rapid) =====
	Spawn.T03:
	Spawn.T10:
		"CPS2" AB 10 { A_Look(); }
		Loop;
	See.T03:
	See.T10:
		"CPS2" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T03:
		"CPS2" E 8 { A_FaceTarget(); }
	Missile.T03.Loop:
		"CPS2" F 5 Bright { A_SpawnProjectile("RS_IceZombieShot2", 24, 0, random(-5, 5)); }
		"CPS2" E 4 { A_CPosRefire(); }
		Goto Missile.T03.Loop;
	Missile.T10:
		"CPS2" E 6 { A_FaceTarget(); }
	Missile.T10.Loop:
		"CPS2" F 2 Bright { A_CustomBulletAttack(4.6, 0, 1, random(8, 18), "BulletPuff"); }
		"CPS2" E 2 { A_CPosRefire(); }
		Goto Missile.T10.Loop;
	Pain.T03:
	Pain.T10:
		"CPS2" G 3;
		"CPS2" G 3 { A_Pain(); }
		Goto See;
	Death.T03:
	Death.T10:
		"CPS2" H 5;
		"CPS2" I 5 { A_Scream(); }
		"CPS2" J 5 { A_NoBlocking(); }
		"CPS2" KLM 5;
		"CPS2" N -1;
		Stop;
	XDeath.T03:
	XDeath.T10:
		"CPS2" O 5;
		"CPS2" P 5 { A_XScream(); }
		"CPS2" Q 5 { A_NoBlocking(); }
		"CPS2" RS 5;
		"CPS2" T -1;
		Stop;

	// ===== PZOW body: T05 plasma, T06 abyss, T07 fire, T09 slug =====
	Spawn.T05:
	Spawn.T06:
	Spawn.T07:
	Spawn.T09:
		"PZOW" AB 10 { A_Look(); }
		Loop;
	See.T05:
	See.T06:
	See.T07:
	See.T09:
		"PZOW" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T05:
		"PZOW" E 8 { A_FaceTarget(); }
	Missile.T05.Loop:
		"PZOW" F 4 Bright { A_SpawnProjectile("RS_PlasmaBallSP3", 24, 0, random(-4, 4)); }
		"PZOW" E 4 { A_CPosRefire(); }
		Goto Missile.T05.Loop;
	Missile.T06:
		"PZOW" E 8 { A_FaceTarget(); }
	Missile.T06.Loop:
		"PZOW" F 4 Bright { A_SpawnProjectile("RS_AbyssZShotCH3", 24, 0, random(-5, 5)); }
		"PZOW" F 4 Bright { A_SpawnProjectile("RS_AbyssZShotCH3", 24, 0, random(-5, 5)); }
		"PZOW" E 4 { A_CPosRefire(); }
		Goto Missile.T06.Loop;
	Missile.T07:
		"PZOW" E 8 { A_FaceTarget(); }
	Missile.T07.Loop:
		"PZOW" F 4 Bright { A_SpawnProjectile("RS_FireBCGguy", 24, 0, random(-5, 5)); }
		"PZOW" E 4 { A_CPosRefire(); }
		Goto Missile.T07.Loop;
	Missile.T09:
		"PZOW" E 8 { A_FaceTarget(); }
	Missile.T09.Loop:
		"PZOW" F 3 Bright { A_CustomBulletAttack(5.6, 0, 1, random(10, 22), "BulletPuff"); }
		"PZOW" E 3 { A_CPosRefire(); }
		Goto Missile.T09.Loop;
	Pain.T05:
	Pain.T06:
	Pain.T07:
	Pain.T09:
		"PZOW" G 3;
		"PZOW" G 3 { A_Pain(); }
		Goto See;
	Death.T05:
	Death.T06:
	Death.T07:
	Death.T09:
		"PZOW" H 5;
		"PZOW" I 5 { A_Scream(); }
		"PZOW" J 5 { A_NoBlocking(); }
		"PZOW" KLM 5;
		"PZOW" N -1;
		Stop;
	XDeath.T05:
	XDeath.T06:
	XDeath.T07:
	XDeath.T09:
		"PZOW" O 5;
		"PZOW" P 5 { A_XScream(); }
		"PZOW" Q 5 { A_NoBlocking(); }
		"PZOW" RS 5;
		"PZOW" T -1;
		Stop;

	// ===== T08 BROWN -- bullet plus a lobbed orb (CZV1) =====
	// CZV1 ships A-S then U (no T on disk) -- XDeath ends on S.
	Spawn.T08:
		"CZV1" AB 10 { A_Look(); }
		Loop;
	See.T08:
		"CZV1" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T08:
		"CZV1" E 8 { A_FaceTarget(); }
	Missile.T08.Loop:
		"CZV1" F 3 Bright { A_CustomBulletAttack(5.6, 0, 1, random(4, 10), "BulletPuff"); }
		"CZV1" F 3 Bright { A_SpawnProjectile("RS_BrownOrbCguy", 24, 0, random(-6, 6)); }
		"CZV1" E 4 { A_CPosRefire(); }
		Goto Missile.T08.Loop;
	Pain.T08:
		"CZV1" G 3;
		"CZV1" G 3 { A_Pain(); }
		Goto See;
	Death.T08:
		"CZV1" H 5;
		"CZV1" I 5 { A_Scream(); }
		"CZV1" J 5 { A_NoBlocking(); }
		"CZV1" KLM 5;
		"CZV1" N -1;
		Stop;
	XDeath.T08:
		"CZV1" O 5;
		"CZV1" P 5 { A_XScream(); }
		"CZV1" Q 5 { A_NoBlocking(); }
		"CZV1" R 5;
		"CZV1" S -1;
		Stop;

	// ===== T11 BLACK -- rapid fire, or artillery with a shield (BFGZ) =====
	Spawn.T11:
		"BFGZ" AB 10 { A_Look(); }
		Loop;
	See.T11:
		"BFGZ" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T11:
		TNT1 A 0 A_Jump(80, "Missile.T11.Big");
		"BFGZ" E 6 { A_FaceTarget(); }
	Missile.T11.Loop:
		"BFGZ" F 2 Bright { A_CustomBulletAttack(5.6, 0, 1, random(12, 26), "BulletPuff"); }
		"BFGZ" E 1 { A_CPosRefire(); }
		Goto Missile.T11.Loop;
	Missile.T11.Big:
		"BFGZ" E 10 { A_FaceTarget(); }
		"BFGZ" F 8 Bright { A_SpawnProjectile("RS_CGBigOne", 24, 0, 0); }
		"BFGZ" F 4 Bright { A_SpawnProjectile("RS_GenShield", 16, 0, 0); }
		"BFGZ" E 8;
		Goto See;
	Pain.T11:
		"BFGZ" G 3;
		"BFGZ" G 3 { A_Pain(); }
		Goto See;
	Death.T11:
		"BFGZ" H 5;
		"BFGZ" I 5 { A_Scream(); }
		"BFGZ" J 5 { A_NoBlocking(); }
		"BFGZ" KLM 5;
		"BFGZ" N -1;
		Stop;
	XDeath.T11:
		"BFGZ" O 5;
		"BFGZ" P 5 { A_XScream(); }
		"BFGZ" Q 5 { A_NoBlocking(); }
		"BFGZ" RS 5;
		"BFGZ" T -1;
		Stop;

	// ===== T12 WHITE -- the needle boss (FSZS). Storm or puddles =====
	Spawn.T12:
		"FSZS" AB 10 { A_Look(); }
		Loop;
	See.T12:
		"FSZS" AABBCCDD 3 { A_Chase(); }
		Loop;
	Missile.T12:
		TNT1 A 0 A_Jump(96, "Missile.T12.Puddle");
		"FSZS" E 6 { A_FaceTarget(); }
	Missile.T12.Loop:
		"FSZS" F 2 Bright { A_SpawnProjectile("RS_NeedlesCg1", 24, 0, random(-8, 8)); }
		"FSZS" F 2 Bright { A_SpawnProjectile("RS_NeedlesCg2", 24, 0, random(-8, 8)); }
		"FSZS" E 2 { A_CPosRefire(); }
		Goto Missile.T12.Loop;
	Missile.T12.Puddle:
		"FSZS" E 8 { A_FaceTarget(); }
		"FSZS" F 6 Bright { A_SpawnProjectile("RS_Puddle1", 24, 0, random(-12, 12)); }
		"FSZS" F 6 Bright { A_SpawnProjectile("RS_Puddle1", 24, 0, random(-12, 12)); }
		"FSZS" E 8;
		Goto See;
	Pain.T12:
		"FSZS" G 3;
		"FSZS" G 3 { A_Pain(); }
		Goto See;
	Death.T12:
		"FSZS" H 5;
		"FSZS" I 5 { A_Scream(); }
		"FSZS" J 5 { A_NoBlocking(); }
		"FSZS" KLM 5;
		"FSZS" N -1;
		Stop;
	XDeath.T12:
		"FSZS" O 5;
		"FSZS" P 5 { A_XScream(); }
		"FSZS" Q 5 { A_NoBlocking(); }
		"FSZS" RS 5;
		"FSZS" T -1;
		Stop;
	}
}
