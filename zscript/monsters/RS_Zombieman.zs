// =====================================================================
// RS_Zombieman -- on RS_HumanMonster (RS_MonsterMaster.zs).
// Sprites and TRNSLATE names verified against Colourful Hell's own
// decorate and against ART SOURCE. Replaces Zombieman.
// =====================================================================

class RS_Zombieman : RS_HumanMonster replaces Zombieman
{
	Default
	{
		Health 20;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 200;
		Monster;
		+FLOORCLIP
		SeeSound "grunt/sight";  PainSound "grunt/pain";
		DeathSound "grunt/death"; ActiveSound "grunt/active";
		AttackSound "grunt/attack";
		Obituary "$OB_ZOMBIE";
		Tag "Zombieman";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "POSS POSS POSS CYNT POSS CZOW ABTR POSS SGAR SHDT ZUNM PLAY MAGE";
	}

	override string TintTable()
	{
		return "- rs_zombie_t01 rs_zombie_t02 rs_zombie_t03 rs_zombie_t04 "
		       "rs_zombie_t05 rs_zombie_t06 rs_zombie_t07 - rs_zombie_t09 "
		       "- rs_zombie_t11 rs_zombie_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:zombieman role:fodder delivery:bullet element:kinetic mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE UNDERTAKER'S LADDER. CHP's white zombieman tracks a counter and
	// steps permanently harder at fixed marks -- not a single enrage but
	// a staircase, so a zombieman that survives a long fight becomes a
	// genuinely different problem. Rebuilt on the charge counter.
	//
	// Charge rises on every hit it takes. Steps at 5 / 9 / 12.
	// -----------------------------------------------------------------
	const RS_ZM_TIER_LADDER = 6;
	const RS_ZM_STEP1 = 5;
	const RS_ZM_STEP2 = 9;
	const RS_ZM_STEP3 = 12;

	private int rsStep;

	void RS_ClimbLadder()
	{
		if (Tier < RS_ZM_TIER_LADDER)
			return;

		AddCharge(1);

		if (rsStep < 1 && ChargeCounter >= RS_ZM_STEP1)
		{
			rsStep = 1;
			Speed *= 1.3;
			MissileChanceMult *= 2.0;
			A_SetScale(Scale.X * 1.08);
			A_StartSound("grunt/sight", CHAN_VOICE);
		}
		else if (rsStep < 2 && ChargeCounter >= RS_ZM_STEP2)
		{
			rsStep = 2;
			Speed *= 1.25;
			A_SetScale(Scale.X * 1.10);
			A_StartSound("grunt/sight", CHAN_VOICE);
		}
		else if (rsStep < 3 && ChargeCounter >= RS_ZM_STEP3)
		{
			// Final form: stops flinching entirely.
			rsStep = 3;
			bNOPAIN = true;
			Speed *= 1.2;
			A_SetScale(Scale.X * 1.12);
			A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
		}
	}

	States
	{
	Missile:
		"####" E 10 A_FaceTarget;
		"####" F 8 Bright
		{
			// The ladder pays off in shots, not just stats: each step
			// adds a round to the burst.
			RS_TierBullets(1 + rsStep, 5.6, 3, 15);
		}
		"####" E 8;
		Goto See;
	Pain:
		"####" G 3;
		"####" G 3 A_Pain;
		TNT1 A 0 { RS_ClimbLadder(); }
		Goto See;
	}
}
