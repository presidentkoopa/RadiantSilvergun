// =====================================================================
// RS_BlackSGTrooper -- the Crew Commander's squad.
//
// PORTED 2026-08-05, because what we had was wrong in kind, not degree.
// RS_Shotgunner's T11 summon called
//     SummonMinion("RS_Shotgunner", -4, 48.0)
// which is T11 minus four = T07, THE FIREBLU KAMIKAZE. Four troopers of
// a completely different creature: wrong body, wrong stats, no squad
// behaviour, and trailing fire.
//
// CHP summons CommonBlackSG2 (CHP/DECORATE/02/02_K.txt:43-46), which is
// a distinct actor -- body ZSP1, Health 280, Speed 13, translucent at
// Alpha 0.65 -- with a FIVE-STANCE TACTICAL AI. This is the family-02
// equivalent of the Undertaker's missing skeleton economy: it compiled,
// it spawned something, and it was not the mechanic.
//
// CH parent: CH/decorate/Shotgunners.txt:1994 (BlackSG2)
// CHP actor: CHP/DECORATE/02/02_K.txt:1742 (CommonBlackSG2)
// Stances:   02_K.txt:1774 / 1842 / 1863 / 1884 / 1902
// The roll:  CH/decorate/Shotgunners.txt:2241 (ZSpecOpsSGSitRep)
//
// HOW THE STANCE SYSTEM WORKS. Every time the trooper enters See it
// wipes its stance flags, rolls a fresh stance off its own situation,
// and jumps into that stance's chase loop. Each loop periodically falls
// back to See, so the stance is re-rolled continuously through a fight
// -- a trooper that gets hurt or loses sight of you changes how it
// fights, on its own, without the commander doing anything.
//
// CH implements the roll as a CustomInventory (ZSpecOpsSGSitRep) whose
// Use state is a jump tree, and the stances as five inventory tokens.
// Ported as one function and an int: the tokens exist only to carry the
// result of a decision made in the same tic, and five Inventory classes
// to express `switch` is CH working around DECORATE.
//
// THE FLAGS ARE THE STANCE. CH sets MissileMore / MissileEvenMore /
// AvoidMelee / NoPain per stance with A_ChangeFlag. Both missile flags
// are deprecated on this engine, so they become MissileChanceMult --
// and the same rs_mon_missilechance_floor valve applies here as in
// RS_MonsterMaster, for the same reason: 0.0625 is a monster that
// stands still and hoses.
// =====================================================================

class RS_BlackSGTrooper : Actor
{
	// CH's five ZSpecOp* inventory tokens, as one value.
	const RS_SG_AGGRESSIVE = 0;
	const RS_SG_SPRINT     = 1;
	const RS_SG_WANDER     = 2;
	const RS_SG_CREEP      = 3;
	const RS_SG_BERSERK    = 4;

	private int rsStance;

	Default
	{
		// CH BlackSG2, Shotgunners.txt:1994-2010, plus CHP's overrides
		// from CommonBlackSG2 at 02_K.txt:1744-1750.
		Health 280;              // 02_K.txt:1744
		Speed 13;                // 02_K.txt:1745
		PainChance 96;           // 02_K.txt:1746
		Radius 20; Height 56;
		Mass 100;
		Monster;
		+FLOORCLIP
		+DONTHARMSPECIES
		+NOINFIGHTING
		+THRUSPECIES
		+NOFEAR
		-ACTIVATEMCROSS
		// CH writes -NoradiusDMG: the squad DOES take splash.
		-NORADIUSDMG
		// Shares the commander's species so the two never infight.
		Species "BlackSG";
		// 02_K.txt:1747-1748
		RenderStyle "Translucent";
		Alpha 0.65;
		// A summoned escort must not make 100% kills impossible.
		-COUNTKILL
		SeeSound "zom2/see";     PainSound "form2/hurt";
		DeathSound "zom2/die";   ActiveSound "form2/active";
		AttackSound "";
		Obituary "$OB_SHOTGUY";
		Tag "Black Shotgunner Troop";
	}

	// CH's per-type DamageFactors live on the class defaults and cannot
	// be set per instance, so they go through the same override the
	// tiered monsters use. Shotgunners.txt:1996-1999.
	override int DamageMobj(Actor inflictor, Actor source, int damage,
	                        Name mod, int flags, double angle)
	{
		double fac = 1.0;
		if (mod == 'Fire')           fac = 0.8;
		else if (mod == 'Plasma')    fac = 0.8;
		else if (mod == 'BFGSplash') fac = 0.7;
		else if (mod == 'Heroic')    fac = 3.0;
		else if (mod == 'DIMp')      return 0;

		if (fac != 1.0)
		{
			damage = int(damage * fac);
			if (damage < 1) damage = 1;
		}
		return Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
	}

	// The missile-rate valve, same contract as RS_MonsterMaster's.
	// The lookup is inlined rather than calling RS_MonsterMaster's
	// helper: that class is `abstract`, and a cross-class static call
	// into an abstract type is not worth gambling a build on for four
	// lines. Same cvar, same default, same contract.
	private void RS_SetMissileRate(double mult)
	{
		double floorMult = 0.125;
		let cv = CVar.FindCVar("rs_mon_missilechance_floor");
		if (cv) floorMult = cv.GetFloat();
		MissileChanceMult = (floorMult > 0) ? max(mult, floorMult) : mult;
	}

	// ZSpecOpsSGSitRep, Shotgunners.txt:2241-2281, as a function.
	//
	// Branches on THREE things, in CH's own order: health below 50,
	// whether it can see its target, and range (384 normally, 768 when
	// hurt). Every leaf is a coin flip or a three-way between stances,
	// so two troopers in identical situations still behave differently.
	private int RS_RollStance()
	{
		bool hurt    = (health < 50);
		bool canSee  = (target && CheckSight(target));
		double dist  = target ? Distance2D(target) : 100000;

		if (hurt)
		{
			// LowHealth
			if (!canSee)
			{
				// LowHealthOutOfSight
				if (dist < 768)   // LowHealthOutOfSightClose
					return random(0, 2) == 0 ? RS_SG_CREEP
					     : (random(0, 1) == 0 ? RS_SG_AGGRESSIVE : RS_SG_BERSERK);
				return random(0, 1) == 0 ? RS_SG_SPRINT : RS_SG_CREEP;
			}
			if (dist < 768)       // LowHealthClose
				return random(0, 1) == 0 ? RS_SG_BERSERK : RS_SG_AGGRESSIVE;
			return random(0, 1) == 0 ? RS_SG_SPRINT : RS_SG_BERSERK;
		}

		if (!canSee)
		{
			// OutOfSight
			if (dist < 384)       // OutOfSightClose
				return random(0, 1) == 0 ? RS_SG_AGGRESSIVE : RS_SG_CREEP;
			int r = random(0, 2);
			return r == 0 ? RS_SG_AGGRESSIVE : (r == 1 ? RS_SG_WANDER : RS_SG_CREEP);
		}

		if (dist < 384)           // Close -- always aggressive
			return RS_SG_AGGRESSIVE;

		// ChecksFailed
		return random(0, 1) == 0 ? RS_SG_AGGRESSIVE : RS_SG_SPRINT;
	}

	// Clear, roll, apply. Returns the state to enter.
	State RS_EnterStance()
	{
		// CH wipes all four flags every time before re-rolling
		// (02_K.txt:1762-1765). Without the wipe the stances accumulate.
		RS_SetMissileRate(1.0);
		bAVOIDMELEE = false;
		bNOPAIN     = false;

		rsStance = RS_RollStance();
		switch (rsStance)
		{
			case RS_SG_AGGRESSIVE:
				RS_SetMissileRate(0.0625);          // MORE + EVENMORE
				return ResolveState("AggressiveSee");
			case RS_SG_SPRINT:
				bNOPAIN = true;                     // runs through fire
				return ResolveState("SprintSee");
			case RS_SG_WANDER:
				A_ClearTarget();                    // breaks off entirely
				return ResolveState("WanderSee");
			case RS_SG_CREEP:
				RS_SetMissileRate(0.5);             // MORE only
				bAVOIDMELEE = true;                 // holds range
				return ResolveState("CreepSee");
			case RS_SG_BERSERK:
				RS_SetMissileRate(0.0625);
				bNOPAIN = true;
				return ResolveState("BerserkSee");
		}
		return ResolveState("AggressiveSee");
	}

	// The leash. CHP: A_JumpIfMasterCloser(1000,"See") then
	// A_Warp(AAPTR_MASTER,...) -- a trooper that strays more than 1000
	// units from the commander teleports back to it.
	// CHP writes the sprite on those two lines as ZPS1, which does not
	// exist; ZSP1 does. Transposition in CHP, corrected here.
	private void RS_Leash()
	{
		if (!master || Distance2D(master) < 1000)
			return;
		Warp(master, 5, 1, 6, 0, WARPF_NOCHECKPOSITION);
	}

	States
	{
	Spawn:
		"ZSP1" AAAAAAAAAABBBBBBBBBB 1 A_Look();
		Loop;

	// Every entry here wipes the stance and rolls a new one, so the
	// trooper re-evaluates continuously through a fight.
	See:
		TNT1 A 0 { RS_Leash(); }
		TNT1 A 0 { return RS_EnterStance(); }
		Goto AggressiveSee;

	AggressiveSee:
		"ZSP1" AABB 3 A_Chase(null, "AggressiveMissile");
		"ZSP1" A 0 A_Jump(192, "AggressiveSee");
		"ZSP1" A 0 A_JumpIfHealthLower(50, "See");
		"ZSP1" A 0 A_Jump(32, "AggressiveSee");
		"ZSP1" A 0 A_JumpIfCloser(768, "AggressiveSee");
		Goto See;
	AggressiveMissile:
		"ZSP1" EEE 4 A_FaceTarget();
		"ZSP1" F 0 Bright { A_StartSound("weapons/shotgf", CHAN_WEAPON); }
		"ZSP1" F 2 Bright { A_CustomBulletAttack(8, 6, 7, 4, "RS_DetoPuffCG"); }
		"ZSP1" F 0 Bright A_Jump(64, "NadeToss");
		"ZSP1" EEE 2 A_FaceTarget();
		Goto AggressiveSee;

	// The only stance with no missile state at all -- it closes.
	SprintSee:
		"ZSP1" AABB 2 A_Chase(null, null);
		"ZSP1" A 0 A_JumpIfCloser(384, "See");
		"ZSP1" CCDD 2 A_Chase(null, null);
		"ZSP1" A 0 A_JumpIfCloser(384, "See");
		Loop;

	// Target cleared. It genuinely loses you and hunts.
	WanderSee:
		"ZSP1" AABB 4 A_Wander();
		"ZSP1" A 0 A_LookEx(10, 0, 0, 0, 360, "See");
		"ZSP1" CCDD 4 A_Wander();
		"ZSP1" A 0 A_LookEx(10, 0, 0, 0, 360, "See");
		Loop;

	CreepSee:
		"ZSP1" A 0 A_CheckSight("CreepSee");
		"ZSP1" A 0 A_JumpIfHealthLower(50, "See");
		"ZSP1" AABBCCDD 4 A_Chase(null, "CreepMissile");
		Loop;
	CreepMissile:
		"ZSP1" EEE 4 A_FaceTarget();
		"ZSP1" F 0 Bright { A_StartSound("weapons/shotgf", CHAN_WEAPON); }
		"ZSP1" F 2 Bright { A_CustomBulletAttack(8, 6, 7, 4, "RS_DetoPuffCG"); }
		"ZSP1" EEE 2 A_FaceTarget();
		Goto CreepSee;

	BerserkSee:
		"ZSP1" AABBCCDD 3 A_Chase(null, "BerserkMissile");
		Loop;
	BerserkMissile:
		"ZSP1" EE 4 A_FaceTarget();
		"ZSP1" F 0 Bright { A_StartSound("weapons/shotgf", CHAN_WEAPON); }
		"ZSP1" F 2 Bright { A_CustomBulletAttack(8, 6, 7, 4, "RS_DetoPuffCG"); }
		"ZSP1" EEE 2 A_FaceTarget();
		"ZSP1" F 0 A_Jump(192, "BerserkSee");
		"ZSP1" F 0 A_MonsterRefire(40, "BerserkSee");
		Loop;

	// Shared with the commander's own nade. 02_K.txt:1836-1840.
	NadeToss:
		"ZSP1" E 8 A_FaceTarget();
		"ZSP1" E 2 { A_StartSound("fire/fire4", CHAN_WEAPON); }
		"ZSP1" E 2 { A_SpawnProjectile("RS_SGGasNade", 48, 0, random(-3, 3), 0, random(3, 12)); }
		"ZSP1" E 2;
		Goto AggressiveSee;

	Pain:
		"ZSP1" G 3;
		"ZSP1" G 3 A_Pain();
		Goto See;
	Death:
		"ZSP1" H 5;
		"ZSP1" I 5 A_Scream();
		"ZSP1" J 5 A_NoBlocking();
		"ZSP1" K 5;
		"ZSP1" L -1;
		Stop;
	}
}
