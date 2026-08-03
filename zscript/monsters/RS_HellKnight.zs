// =====================================================================
// RS_HellKnight -- on RS_KnightBase (RS_MonsterMaster.zs). Replaces
// HellKnight.
// =====================================================================

class RS_HellKnight : RS_KnightBase replaces HellKnight
{
	Default
	{
		Health 500;
		Radius 24;
		Height 64;
		Mass 1000;
		Speed 8;
		PainChance 50;
		Monster;
		+FLOORCLIP
		SeeSound "knight/sight";   PainSound "knight/pain";
		DeathSound "knight/death"; ActiveSound "knight/active";
		Obituary "$OB_KNIGHT";
		HitObituary "$OB_KNIGHTHIT";
		Tag "Hell Knight";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "BOS2 BOS2 BOS2 HFRY BOS2 BRUS BRUS BOS2 HWAR BOS2 BRUR BRUC PHAN";
	}

	override string TintTable()
	{
		return "- rs_hk_t01 rs_hk_t02 rs_hk_t03 rs_hk_t04 - "
		       "rs_hk_t06 rs_hk_t07 - rs_hk_t09 - rs_hk_t11 -";
	}

	override string GetBaseKeywords()
	{
		return "species:hellknight role:bruiser delivery:heavy delivery:melee element:thermal mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE GHOST OF E1M8. CHP's white hell knight splits into TWO full
	// -power monsters the instant it spawns -- not a pet, a genuine
	// duplicate. Deliberately not master-linked: killing one does
	// nothing to the other, which is the whole scare.
	//
	// Guarded so the clone doesn't clone: only an original (no master,
	// flag unset) ever splits.
	// -----------------------------------------------------------------
	const RS_HK_TIER_CLONE  = 11;
	const RS_HK_TIER_ESCORT = 7;

	private bool rsIsClone;
	private bool rsSplitDone;

	override bool MinionsDieWithMe() { return false; }

	void RS_Split()
	{
		if (Tier < RS_HK_TIER_CLONE || rsIsClone || rsSplitDone)
			return;
		rsSplitDone = true;

		Vector3 p = (pos.xy + (cos(angle + 90), sin(angle + 90)) * 40.0, pos.z);
		let mo = RS_HellKnight(Spawn("RS_HellKnight", p, ALLOW_REPLACE));
		if (!mo)
			return;

		mo.rsIsClone   = true;     // it will not split again
		mo.rsSplitDone = true;
		mo.SetTier(Tier, true);
		mo.target = target;
		mo.angle  = angle;
		A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	void RS_CallEscort()
	{
		if (Tier < RS_HK_TIER_ESCORT)
			return;
		if (SummonPack("RS_Imp", 2, 4, -3, 96.0) > 0)
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	States
	{
	Spawn:
		TNT1 A 0 NoDelay { RS_Split(); }
		"####" AB 10 A_Look;
		Loop;
	Missile:
		TNT1 A 0
		{
			if (Tier >= RS_HK_TIER_ESCORT && random(0, 255) < 48)
				return ResolveState("CallEscort");
			return ResolveState(null);
		}
		"####" EF 8 A_FaceTarget;
		"####" G 8 A_BruisAttack;
		Goto See;
	CallEscort:
		"####" E 10 A_FaceTarget;
		"####" F 12 Bright { RS_CallEscort(); }
		Goto See;
	// Hell Knight has no BossDeath in vanilla, unlike the shared block.
	Death:
		"####" I 8;
		"####" J 8 A_Scream;
		"####" K 8;
		"####" L 8 A_NoBlocking;
		"####" MN 8;
		"####" N -1;
		Stop;
	}
}
