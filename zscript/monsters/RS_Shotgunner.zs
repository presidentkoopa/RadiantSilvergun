// =====================================================================
// RS_Shotgunner -- on RS_HumanMonster (RS_MonsterMaster.zs).
// Sprites and TRNSLATE names verified against Colourful Hell's own
// decorate and against ART SOURCE. Replaces ShotgunGuy.
// =====================================================================

class RS_Shotgunner : RS_HumanMonster replaces ShotgunGuy
{
	Default
	{
		Health 30;
		Radius 20;
		Height 56;
		Mass 100;
		Speed 8;
		PainChance 170;
		Monster;
		+FLOORCLIP
		SeeSound "shotguy/sight";  PainSound "shotguy/pain";
		DeathSound "shotguy/death"; ActiveSound "shotguy/active";
		AttackSound "shotguy/attack";
		Obituary "$OB_SHOTGUY";
		Tag "Shotgun Guy";
		DropItem "Shotgun";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SPOS SPOS SPOS CNSG HMZP ASGZ ABSG GPOS QSZM GRSH GPOS ZSP1 BENE";
	}

	override string TintTable()
	{
		return "- rs_sgun_t01 rs_sgun_t02 rs_sgun_t03 rs_sgun_t04 - "
		       "rs_sgun_t06 rs_sgun_t07 rs_sgun_t08 rs_sgun_t09 "
		       "rs_sgun_t10 rs_sgun_t11 -";
	}

	override string GetBaseKeywords()
	{
		return "species:shotgunner role:fodder delivery:bullet payload:multi element:kinetic mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE CREW COMMANDER. CHP's black shotgunner calls in a squad of its
	// own kind. Summoning its OWN species at a lower tier is the cleanest
	// version of that -- no bespoke minion class, and the squad inherits
	// the whole tier system for free.
	// -----------------------------------------------------------------
	const RS_SG_TIER_SQUAD = 7;

	override bool MinionsDieWithMe() { return false; }

	void RS_CallSquad()
	{
		if (Tier < RS_SG_TIER_SQUAD)
			return;
		int cap = (Tier >= 11) ? 4 : 2;
		if (SummonPack("RS_Shotgunner", 2, cap, -4, 88.0) > 0)
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	States
	{
	Missile:
		TNT1 A 0
		{
			// One attack in five becomes a call for backup.
			if (Tier >= RS_SG_TIER_SQUAD && random(0, 255) < 50)
				return ResolveState("CallSquad");
			return ResolveState(null);
		}
		Goto FireShot;
	CallSquad:
		"SPOS" E 12  { RS_WearBody(); A_FaceTarget(); }
		"SPOS" F 14  Bright { RS_WearBody(); RS_CallSquad(); }
		"SPOS" E 8 { RS_WearBody(); }
		Goto See;
	FireShot:
		"SPOS" E 10  { RS_WearBody(); A_FaceTarget(); }
		// Three pellets baseline, wider cone. Higher tiers tighten it --
		// a Tier 12 shotgunner is dangerous at range, not just tanky.
		"SPOS" F 10  Bright { RS_WearBody(); RS_TierBullets(3, Tier >= 10 ? 7.5 : 11.2, 3, 15); }
		"SPOS" E 10 { RS_WearBody(); }
		Goto See;
	}
}
