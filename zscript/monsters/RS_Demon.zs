// =====================================================================
// RS_Demon -- on RS_DemonBase (RS_MonsterMaster.zs). Replaces Demon.
// =====================================================================

class RS_Demon : RS_DemonBase replaces Demon
{
	Default
	{
		Health 150;
		Radius 30;
		Height 56;
		Mass 400;
		Speed 10;
		PainChance 180;
		Monster;
		+FLOORCLIP
		SeeSound "demon/sight";   PainSound "demon/pain";
		DeathSound "demon/death"; ActiveSound "demon/active";
		AttackSound "demon/melee";
		Obituary "$OB_DEMON";
		Tag "Demon";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SARG SARG SARG WORM SARG SRG2 HDOG SARG IFN2 WORM SRG2 BCHR JUGG";
	}

	override string TintTable()
	{
		return "- rs_demon_t01 rs_demon_t02 rs_demon_t03 rs_demon_t04 rs_demon_t05 "
		       "rs_demon_t06 rs_demon_t07 rs_demon_t08 rs_demon_t09 rs_demon_t10 - -";
	}

	override string GetBaseKeywords()
	{
		return "species:demon role:bruiser delivery:melee element:kinetic mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE BUTCHER. Takes hits, and at a count releases the pack -- so
	// the reward for beating on it is more things biting you. Plus a
	// chance each hit to permanently stop flinching, which is what turns
	// a pinky into a freight train mid-fight.
	// -----------------------------------------------------------------
	const RS_DEMON_TIER_PACK = 7;
	const RS_DEMON_PACK_AT   = 8;

	override bool MinionsDieWithMe() { return true; }

	void RS_ButcherHit()
	{
		if (Tier < RS_DEMON_TIER_PACK)
			return;

		AddCharge(1);

		if (ChargeCounter >= RS_DEMON_PACK_AT)
		{
			ResetCharge();
			if (SummonPack(RS_MonsterCatalog.MINION_DemonDog(), 3, 6, -3, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}

		// Permanent, one-way. Guarded by the flag itself.
		if (!bNOPAIN && Tier >= 9 && random(0, 255) < 90)
		{
			bNOPAIN = true;
			MissileChanceMult *= 2.0;
			Speed *= 1.25;
			A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
		}
	}

	States
	{
	Pain:
		"SARG" H 2 { RS_WearBody(); }
		"SARG" H 2  { RS_WearBody(); A_Pain(); }
		TNT1 A 0 { RS_ButcherHit(); }
		Goto See;
	}
}
