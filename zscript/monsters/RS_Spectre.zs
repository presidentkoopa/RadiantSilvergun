// =====================================================================
// RS_Spectre -- on RS_DemonBase (RS_MonsterMaster.zs). Replaces Spectre.
// CH's spectres are the demon body plus a fuzz render style -- SARG,
// not a dedicated sprite set.
// =====================================================================

class RS_Spectre : RS_DemonBase replaces Spectre
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
		+SHADOW
		RenderStyle "OptFuzzy";
		Alpha 0.5;
		SeeSound "spectre/sight";   PainSound "spectre/pain";
		DeathSound "spectre/death"; ActiveSound "spectre/active";
		AttackSound "spectre/melee";
		Obituary "$OB_SPECTRE";
		Tag "Spectre";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SARG SARG SARG WORM SARG SRG2 HDOG SARG BPWA TRIT SRG2 SHDW SLGM";
	}

	override string TintTable()
	{
		// Shares the demon recipes except T12. T09 uses the engine's
		// own built-in "ice" translation, which is a real named
		// translation GZDoom ships -- not one of ours, not a range table.
		return "- rs_demon_t01 rs_demon_t02 rs_demon_t03 rs_demon_t04 rs_demon_t05 "
		       "rs_demon_t06 rs_demon_t07 - ice rs_demon_t10 - rs_spectre_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:spectre role:bruiser delivery:melee element:kinetic mobility:ground trait:stealth";
	}

	// -----------------------------------------------------------------
	// THE ROGUE. Builds a counter while stalking, then warps behind you
	// and opens with a free hit. The counter is what makes it feel like
	// it is waiting for an opening rather than rolling dice every tic.
	// -----------------------------------------------------------------
	const RS_SPEC_TIER_BACKSTAB = 6;
	const RS_SPEC_STAB_AT       = 10;

	void RS_Stalk()
	{
		if (Tier < RS_SPEC_TIER_BACKSTAB)
			return;
		AddCharge(1);
	}

	// Warp to just behind the target. Returns false if there was nowhere
	// to land, so the caller can fall through to a normal approach.
	bool RS_Backstab()
	{
		if (!target || ChargeCounter < RS_SPEC_STAB_AT)
			return false;

		ResetCharge();

		// Behind the target, relative to the way IT is facing.
		double ang = target.angle + 180;
		Vector3 p = (target.pos.xy + (cos(ang), sin(ang)) * 56.0, target.pos.z);

		if (!TeleportMove(p, false))
			return false;

		angle = target.angle;      // facing its back
		A_StartSound("spectre/sight", CHAN_VOICE);
		return true;
	}

	States
	{
	See:
		"SARG" AABBCCDD 2  { RS_WearBody(); A_Chase(); }
		TNT1 A 0
		{
			RS_Stalk();
			if (ChargeCounter >= RS_SPEC_STAB_AT && RS_Backstab())
				return ResolveState("Melee");
			return ResolveState(null);
		}
		Loop;
	}
}
