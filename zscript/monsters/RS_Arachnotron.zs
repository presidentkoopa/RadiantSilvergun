// =====================================================================
// RS_Arachnotron -- on RS_MonsterMaster directly. Replaces Arachnotron.
// =====================================================================

class RS_Arachnotron : RS_MonsterMaster replaces Arachnotron
{
	Default
	{
		Health 500;
		Radius 64;
		Height 64;
		Mass 600;
		Speed 12;
		PainChance 128;
		Monster;
		+FLOORCLIP +BOSSDEATH
		SeeSound "baby/sight";   PainSound "baby/pain";
		DeathSound "baby/death"; ActiveSound "baby/active";
		Obituary "$OB_BABY";
		Tag "Arachnotron";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "BSPI BSPI BSPI ACNB BSPI ACNB ABSP ACNB BSPI BSPI BSP2 BSP2 TRIT";
	}

	override string TintTable()
	{
		return "- rs_arach_t01 rs_arach_t02 rs_arach_t03 rs_arach_t04 rs_arach_t05 "
		       "- rs_arach_t07 rs_arach_t08 rs_arach_t09 rs_arach_t10 "
		       "rs_arach_t11 rs_arach_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:arachnotron role:artillery delivery:heavy element:plasma mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE SHRINKING CHAIN. CHP's white arachnotron EX dies into a
	// smaller copy of itself, twice, keeping the same attack kit at
	// reduced scale before shattering. Kept because it reads instantly:
	// the thing is visibly diminishing and you can see how close you are
	// to finishing it.
	//
	// Also the hover-barrage: it lifts off and stops flinching for the
	// duration of a big volley, so interrupting it is a timing problem
	// rather than a damage race.
	// -----------------------------------------------------------------
	const RS_ARACH_TIER_CHAIN = 11;
	const RS_ARACH_TIER_HOVER = 7;
	const RS_ARACH_HOVER_SLOT = 0;

	override Class<Actor> DeathMorphClass()
	{
		return (Tier >= RS_ARACH_TIER_CHAIN) ? RS_MonsterCatalog.MORPH_ArachStage2() : null;
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		if (t < RS_ARACH_TIER_HOVER)
			return null;

		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_ArachPlasma(), 3, 20.0,
			"baby/attack", 1.0, 0.0, "Plasma Spread"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_ArachPlasma(),
			t >= 11 ? 20 : 12, 360.0,
			"baby/attack", 1.0, 5.0, "Plasma Ring"));
		return slot;
	}

	// Lift off, stop flinching, unload. Reverts itself via PulseStats.
	void RS_HoverBarrage()
	{
		bFLOAT = true;
		bNOGRAVITY = true;
		PulseStats(1.0, 1.0, 70, true);   // noPain for the volley
	}

	States
	{
	Spawn:
		"####" AB 10 A_Look;
		Loop;
	See:
		"####" A 20;
		"####" AABBCCDDEEFF 3 A_BabyMetal;
		Loop;
	Missile:
		TNT1 A 0
		{
			if (Tier >= RS_ARACH_TIER_HOVER && random(0, 255) < 90)
				return ResolveState("Hover");
			return ResolveState(null);
		}
		"####" A 20 Bright A_FaceTarget;
		"####" G 4 Bright A_BspiAttack;
		"####" H 4 Bright;
		"####" H 1 Bright A_SpidRefire;
		Goto Missile + 2;
	Hover:
		"####" A 14 Bright A_FaceTarget;
		TNT1 A 0 { RS_HoverBarrage(); }
		"####" G 8 Bright { A_RS_MonsterFire(); }
		"####" H 8 Bright;
		"####" G 8 Bright { A_RS_MonsterFire(); }
		"####" H 10 Bright;
		Goto See;
	Pain:
		"####" I 3;
		"####" I 3 A_Pain;
		Goto See;
	Death:
		"####" J 20 A_Scream;
		"####" K 7 A_NoBlocking;
		"####" LMNO 7;
		"####" P -1 A_BossDeath;
		Stop;
	Raise:
		"####" PONMLKJ 5;
		Goto See;
	}
}
