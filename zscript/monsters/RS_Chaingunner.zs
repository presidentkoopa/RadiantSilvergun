// =====================================================================
// RS_Chaingunner -- on RS_HumanMonster (RS_MonsterMaster.zs).
// Sprites and TRNSLATE names verified against Colourful Hell's own
// decorate and against ART SOURCE. Replaces ChaingunGuy.
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

	States
	{
	Missile:
		TNT1 A 0
		{
			// Only reachable AFTER the threshold has fired.
			if (Tier >= RS_CG_TIER_PHASE && ThresholdFired(RS_CG_RAGE_SLOT)
			    && random(0, 255) < 60)
				return ResolveState("CallHelp");
			return ResolveState(null);
		}
		Goto FireLoop;
	CallHelp:
		"CPOS" E 10  { RS_WearBody(); A_FaceTarget(); }
		"CPOS" F 12  Bright
		{
			RS_WearBody();
			if (SummonPack("RS_Imp", 2, 4, -2, 96.0) > 0)
				A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
		}
		Goto See;
	FireLoop:
		"CPOS" E 10  { RS_WearBody(); A_FaceTarget(); }
	MissileLoop:
		"CPOS" F 4  Bright { RS_WearBody(); RS_TierBullets(1, 5.6, 3, 15); }
		"CPOS" E 4  { RS_WearBody(); A_CPosRefire(); }
		Goto MissileLoop;
	// Chaingunner's death frames run one letter longer than the shared
	// human block, so it overrides rather than using it.
	Death:
		"CPOS" H 5 { RS_WearBody(); }
		"CPOS" I 5  { RS_WearBody(); A_Scream(); }
		"CPOS" J 5  { RS_WearBody(); A_NoBlocking(); }
		"CPOS" KLM 5 { RS_WearBody(); }
		"CPOS" N -1 { RS_WearBody(); }
		Stop;
	XDeath:
		"CPOS" O 5 { RS_WearBody(); }
		"CPOS" P 5  { RS_WearBody(); A_XScream(); }
		"CPOS" Q 5  { RS_WearBody(); A_NoBlocking(); }
		"CPOS" RS 5 { RS_WearBody(); }
		"CPOS" T -1 { RS_WearBody(); }
		Stop;
	Raise:
		"CPOS" NMLKJIH 5 { RS_WearBody(); }
		Goto See;
	}
}
