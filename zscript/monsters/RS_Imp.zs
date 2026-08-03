// =====================================================================
// RS_Imp -- on RS_MonsterMaster directly (no shared family base; the
// imp's frame layout is its own). Replaces DoomImp.
// =====================================================================

class RS_Imp : RS_MonsterMaster replaces DoomImp
{
	Default
	{
		Health 60;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 200;
		Monster;
		+FLOORCLIP
		SeeSound "imp/sight";   PainSound "imp/pain";
		DeathSound "imp/death"; ActiveSound "imp/active";
		HitObituary "$OB_IMPHIT";
		Obituary "$OB_IMP";
		Tag "Imp";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "TROO TROO TROO CIMP TROO TRO4 ROAC TROO WARI GIMP PRIM AGUR HELN";
	}

	override string TintTable()
	{
		return "- rs_imp_t01 rs_imp_t02 rs_imp_t03 rs_imp_t04 rs_imp_t05 "
		       "- rs_imp_t07 - rs_imp_t09 - - rs_imp_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:imp role:fodder delivery:melee delivery:heavy element:thermal mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE IMP MASTER. CHP's white imp dumps a whole pack at once rather
	// than trickling them -- the shock of seven imps appearing is the
	// point. Scaled by tier so it stays a shock and not a slideshow.
	// Plus the black imp's warp-dash: a hit sends it skidding sideways
	// instead of flinching.
	// -----------------------------------------------------------------
	const RS_IMP_TIER_PACK = 7;
	const RS_IMP_TIER_WARP = 5;

	override bool MinionsDieWithMe() { return false; }

	void RS_ImpPack()
	{
		if (Tier < RS_IMP_TIER_PACK)
			return;
		int n   = (Tier >= 11) ? 4 : 2;
		int cap = (Tier >= 11) ? 7 : 4;
		if (SummonPack("RS_Imp", n, cap, -4, 104.0) > 0)
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	States
	{
	Spawn:
		"####" AB 10 A_Look;
		Loop;
	See:
		"####" AABBCCDD 3 A_Chase;
		Loop;
	Melee:
	Missile:
		TNT1 A 0
		{
			if (Tier >= RS_IMP_TIER_PACK && random(0, 255) < 44)
				return ResolveState("SummonPack");
			return ResolveState(null);
		}
		"####" EF 8 A_FaceTarget;
		"####" G 6 A_TroopAttack;
		Goto See;
	SummonPack:
		"####" E 10 A_FaceTarget;
		"####" F 14 Bright { RS_ImpPack(); }
		Goto See;
	Pain:
		"####" H 2;
		"####" H 2 A_Pain;
		TNT1 A 0
		{
			// Skids away instead of standing there taking it.
			if (Tier >= RS_IMP_TIER_WARP && random(0, 255) < 64)
				PhaseDodge(24, 5.0, 0.45);
		}
		Goto See;
	Death:
		"####" I 8;
		"####" J 8 A_Scream;
		"####" K 6;
		"####" L 6 A_NoBlocking;
		"####" M -1;
		Stop;
	XDeath:
		"####" N 5;
		"####" O 5 A_XScream;
		"####" P 5;
		"####" Q 5 A_NoBlocking;
		"####" RST 5;
		"####" U -1;
		Stop;
	Raise:
		"####" MLKJI 8;
		Goto See;
	}
}
