// =====================================================================
// RS_Revenant -- on RS_MonsterMaster directly. Replaces Revenant.
// Homing-missile attack is stock A_SkelMissile for now -- CH's
// behaviour (and RS_MonsterAim.zs's lead-fire solver) is not wired in
// yet, that's CHP-behaviour work.
// =====================================================================

class RS_Revenant : RS_MonsterMaster replaces Revenant
{
	Default
	{
		Health 300;
		Radius 20;
		Height 56;
		Mass 500;
		Speed 10;
		PainChance 100;
		Monster;
		+FLOORCLIP +MISSILEMORE
		SeeSound "skeleton/sight";   PainSound "skeleton/pain";
		DeathSound "skeleton/death"; ActiveSound "skeleton/active";
		MeleeSound "skeleton/melee";
		Obituary "$OB_UNDEAD";
		HitObituary "$OB_UNDEADHIT";
		Tag "Revenant";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SKEL SKEL SKEL SREV SKEL REVN SKEL SKEL INCA ZKEL RASK DKNT REVW";
	}

	override string TintTable()
	{
		return "- rs_rev_t01 rs_rev_t02 - rs_rev_t04 rs_rev_t05 "
		       "rs_rev_t06 rs_rev_t07 rs_rev_t08 rs_rev_t09 - rs_rev_t11 -";
	}

	override string GetBaseKeywords()
	{
		return "species:revenant role:artillery delivery:heavy delivery:melee element:kinetic mobility:ground trait:homing";
	}

	// -----------------------------------------------------------------
	// THE BLACK KNIGHT CHAIN. CHP's revenant EX does not die once -- it
	// dies into a shade, and the shade brings a shadow bound to it. Kept
	// because it is the clearest "death is a phase change" in the set.
	// -----------------------------------------------------------------
	const RS_REV_TIER_CHAIN = 11;
	const RS_REV_RAGE_SLOT  = 0;

	override Class<Actor> DeathMorphClass()
	{
		return (Tier >= RS_REV_TIER_CHAIN) ? RS_MonsterCatalog.MORPH_RevShade() : null;
	}

	States
	{
	Spawn:
		"SKEL" AB 10  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"SKEL" AABBCCDDEEFF 2  { RS_WearBody(); A_Chase(); }
		Loop;
	Melee:
		"SKEL" G 0  Bright { RS_WearBody(); A_FaceTarget(); }
		"SKEL" G 6  { RS_WearBody(); A_SkelWhoosh(); }
		"SKEL" H 6  { RS_WearBody(); A_FaceTarget(); }
		"SKEL" I 6  { RS_WearBody(); A_SkelFist(); }
		Goto See;
	Missile:
		"SKEL" J 0  Bright { RS_WearBody(); A_FaceTarget(); }
		"SKEL" J 10  Bright { RS_WearBody(); A_FaceTarget(); }
		"SKEL" K 10  { RS_WearBody(); A_SkelMissile(); }
		"SKEL" K 10  { RS_WearBody(); A_FaceTarget(); }
		Goto See;
	Pain:
		"SKEL" L 5 { RS_WearBody(); }
		"SKEL" L 5  { RS_WearBody(); A_Pain(); }
		TNT1 A 0
		{
			// Goes airborne when hurt -- a revenant you cannot outrun on
			// the ground is a different problem entirely.
			if (Tier >= 8 && CheckThreshold(RS_REV_RAGE_SLOT, 0.5))
			{
				bFLOAT = true;
				bNOGRAVITY = true;
				Enrage(1.3);
				A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
			}
			if (Tier >= 6 && random(0, 255) < 70)
				PhaseDodge(30, 4.0, 0.35);
		}
		Goto See;
	Death:
		"SKEL" LM 7 { RS_WearBody(); }
		"SKEL" N 7  { RS_WearBody(); A_Scream(); }
		"SKEL" O 7  { RS_WearBody(); A_NoBlocking(); }
		"SKEL" P 7 { RS_WearBody(); }
		"SKEL" Q -1 { RS_WearBody(); }
		Stop;
	Raise:
		"SKEL" QPONML 5 { RS_WearBody(); }
		Goto See;
	}
}

// =====================================================================
// RS_RevenantShade -- stage two of the revenant chain.
// Airborne, faster, and it brings a bound shadow that dies with it, so
// the player has to work out which one is real.
// =====================================================================

class RS_RevenantShade : RS_MonsterMaster
{
	Default
	{
		Health 420;
		Radius 20;
		Height 56;
		Mass 300;
		Speed 16;
		PainChance 60;
		Monster;
		+FLOAT +NOGRAVITY +MISSILEMORE
		RenderStyle "Add";
		Alpha 0.85;
		SeeSound "skeleton/sight";   PainSound "skeleton/pain";
		DeathSound "skeleton/death"; ActiveSound "skeleton/active";
		Obituary "$OB_UNDEAD";
		Tag "Revenant Shade";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "DKNT DKNT DKNT SREV DKNT REVN DKNT DKNT INCA ZKEL RASK DKNT REVW";
	}

	override string TintTable()
	{
		return "- rs_rev_t01 rs_rev_t02 - rs_rev_t04 rs_rev_t05 "
		       "rs_rev_t06 rs_rev_t07 rs_rev_t08 rs_rev_t09 - rs_rev_t11 -";
	}

	override string GetBaseKeywords()
	{
		return "species:revenant role:artillery delivery:heavy element:kinetic mobility:flying trait:secondstage trait:homing";
	}

	override bool MinionsDieWithMe() { return true; }

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_VileBolt(), 2, 18.0,
			"skeleton/attack", 1.0, 0.0, "Twin Seeker"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronRing(), 10, 360.0,
			"skeleton/attack", 1.0, 5.0, "Bone Ring"));
		return slot;
	}

	States
	{
	Spawn:
		TNT1 A 0 NoDelay
		{
			SummonMinion(RS_MonsterCatalog.MORPH_RevShadow(), 0, 64.0, 0.0);
			A_StartSound(RS_MonsterCatalog.SND_Morph(), CHAN_VOICE);
		}
		"DKNT" AB 8  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"DKNT" AABBCCDDEEFF 2  { RS_WearBody(); A_Chase(); }
		Loop;
	Missile:
		"DKNT" J 8  Bright { RS_WearBody(); A_FaceTarget(); }
		"DKNT" K 10  Bright { RS_WearBody(); A_RS_MonsterFire(); }
		Goto See;
	Pain:
		"DKNT" L 4 { RS_WearBody(); }
		"DKNT" L 4  { RS_WearBody(); A_Pain(); }
		Goto See;
	Death:
		"DKNT" LM 6 { RS_WearBody(); }
		"DKNT" N 6  { RS_WearBody(); A_Scream(); }
		"DKNT" O 6  { RS_WearBody(); A_NoBlocking(); }
		"DKNT" P 6 { RS_WearBody(); }
		"DKNT" Q -1 { RS_WearBody(); }
		Stop;
	}
}

// =====================================================================
// RS_RevenantShadow -- the bound double.
// No pain, dies with its master. It exists to split the player's
// attention, not to be a real threat on its own.
// =====================================================================

class RS_RevenantShadow : RS_MonsterMaster
{
	Default
	{
		Health 200;
		Radius 20;
		Height 56;
		Mass 200;
		Speed 18;
		PainChance 0;
		Monster;
		+FLOAT +NOGRAVITY +NOPAIN +DONTFALL
		RenderStyle "Translucent";
		Alpha 0.4;
		DeathSound "skeleton/death";
		Obituary "$OB_UNDEAD";
		Tag "Revenant Shadow";
	}

	override string BodyTable()
	{
		return "DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT DKNT";
	}

	override string GetBaseKeywords()
	{
		return "species:revenant role:skirmisher delivery:melee element:kinetic mobility:flying trait:summoned";
	}

	States
	{
	Spawn:
		"DKNT" AB 8  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"DKNT" AABBCCDDEEFF 2  { RS_WearBody(); A_Chase(); }
		Loop;
	Melee:
		"DKNT" G 0  Bright { RS_WearBody(); A_FaceTarget(); }
		"DKNT" G 6  { RS_WearBody(); A_SkelWhoosh(); }
		"DKNT" H 6  { RS_WearBody(); A_FaceTarget(); }
		"DKNT" I 6  { RS_WearBody(); A_SkelFist(); }
		Goto See;
	Death:
		"DKNT" LMNOP 4 { RS_WearBody(); }
		"DKNT" Q -1 { RS_WearBody(); }
		Stop;
	}
}
