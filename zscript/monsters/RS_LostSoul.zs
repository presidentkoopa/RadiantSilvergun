// =====================================================================
// RS_LostSoul -- on RS_MonsterMaster directly. Replaces LostSoul.
// =====================================================================

class RS_LostSoul : RS_MonsterMaster replaces LostSoul
{
	Default
	{
		Health 100;
		Radius 16;
		Height 56;
		Mass 50;
		Speed 8;
		Damage 3;
		PainChance 256;
		Monster;
		+FLOAT +NOGRAVITY +MISSILEMORE +DONTFALL +NOICEDEATH
		+FLOORCLIP
		AttackSound "skull/melee";
		PainSound "skull/pain";
		DeathSound "skull/death";
		ActiveSound "skull/active";
		Obituary "$OB_SKULL";
		Tag "Lost Soul";
		RenderStyle "SoulTrans";
	}

	override string BodyTable()
	{
		// T09 is BAL1 -- the vanilla fireball sprite, which lives in the
		// IWAD rather than in ART SOURCE. It is not missing.
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "SKUL SKUL SKUL LFX1 SKUL FRGO BST7 SKUL BOSF BAL1 FRGO WASP ETHS";
	}

	override string TintTable()
	{
		return "- rs_soul_t01 rs_soul_t02 rs_soul_t03 rs_soul_t04 rs_soul_t05 "
		       "- rs_soul_t07 - rs_soul_t09 rs_soul_t10 - -";
	}

	override string GetBaseKeywords()
	{
		return "species:lostsoul role:skirmisher delivery:melee element:thermal mobility:flying";
	}

	// -----------------------------------------------------------------
	// THE SHIFTER -- the most interesting thing in the whole survey.
	// CHP's white lost soul plays OTHER monsters' attacks: it stops
	// charging and throws a revenant missile, or a baron star, or a
	// cacodemon ball. Below a health gate it only knows a few; past it,
	// the rest unlock.
	//
	// This is exactly what the attack-profile layer is for. Borrowing a
	// moveset is just building a rotation out of another family's
	// catalogued projectiles -- no state copying, no duplication.
	// -----------------------------------------------------------------
	const RS_SOUL_TIER_SHIFT = 8;
	const RS_SOUL_UNLOCK_SLOT = 0;

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		if (t < RS_SOUL_TIER_SHIFT)
			return null;

		let slot = RS_AttackSlot(new("RS_AttackSlot"));

		// The starting three borrowed forms.
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_CacoBall(), 1, 0.0,
			"caco/attack", 1.0, 0.0, "Borrowed: Cacodemon"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronStar(), 2, 20.0,
			"baron/attack", 1.0, 0.0, "Borrowed: Baron"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_VileBolt(), 1, 0.0,
			"vile/firecrkl", 1.0, 0.0, "Borrowed: Archvile"));

		// Past the halfway gate it remembers three more, including a
		// full ring -- the fight visibly widens rather than just hitting
		// harder.
		if (ThresholdFired(RS_SOUL_UNLOCK_SLOT))
		{
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_PainStorm(), 3, 34.0,
				"pain/attack", 1.0, 0.0, "Borrowed: Pain Elemental"));
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_CacoIce(), 1, 0.0,
				"caco/attack", 1.2, 0.0, "Borrowed: Ice"));
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_BaronRing(), 12, 360.0,
				"baron/attack", 1.0, 5.0, "Borrowed: Hell Ring"));
		}

		return slot;
	}

	States
	{
	Spawn:
		"SKUL" AB 10  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"SKUL" AB 6  { RS_WearBody(); A_Chase(); }
		Loop;
	Missile:
		TNT1 A 0
		{
			// High tier stops charging and starts casting.
			if (Tier >= RS_SOUL_TIER_SHIFT)
				return ResolveState("Borrow");
			return ResolveState(null);
		}
		"SKUL" C 10  { RS_WearBody(); A_FaceTarget(); }
		"SKUL" D 4  Bright { RS_WearBody(); A_SkullAttack(); }
		"SKUL" CD 4  Bright { RS_WearBody(); }
		Goto Missile + 3;
	Borrow:
		"SKUL" C 8  Bright { RS_WearBody(); A_FaceTarget(); }
		"SKUL" D 10  Bright { RS_WearBody(); A_RS_MonsterFire(); }
		Goto See;
	Pain:
		"SKUL" E 3 { RS_WearBody(); }
		"SKUL" E 3  { RS_WearBody(); A_Pain(); }
		TNT1 A 0
		{
			// Halfway: remembers the rest of what it can imitate.
			if (Tier >= RS_SOUL_TIER_SHIFT && CheckThreshold(RS_SOUL_UNLOCK_SLOT, 0.5))
			{
				BuildAttacksForTier(-1);
				BuildAttacksForTier(Tier);
				A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
			}
		}
		Goto See;
	Death:
		"SKUL" F 6  Bright { RS_WearBody(); }
		"SKUL" G 6  Bright { RS_WearBody(); A_Scream(); }
		"SKUL" H 6  Bright { RS_WearBody(); }
		"SKUL" I 6  Bright { RS_WearBody(); A_NoBlocking(); }
		"SKUL" J 6 { RS_WearBody(); }
		Stop;
	}
}
