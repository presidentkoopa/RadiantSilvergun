// =====================================================================
// RS_Mancubus -- on RS_MonsterMaster directly. Replaces Fatso.
// =====================================================================

class RS_Mancubus : RS_MonsterMaster replaces Fatso
{
	Default
	{
		Health 600;
		Radius 48;
		Height 64;
		Mass 1000;
		Speed 8;
		PainChance 80;
		Monster;
		+FLOORCLIP +BOSSDEATH
		SeeSound "fatso/sight";   PainSound "fatso/pain";
		DeathSound "fatso/death"; ActiveSound "fatso/active";
		Obituary "$OB_FATSO";
		Tag "Mancubus";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "FATT FATT FATT FATT FATT INCB UNMB HBST FFAT FATT HBST BDEM QUEE";
	}

	override string TintTable()
	{
		return "- rs_manc_t01 rs_manc_t02 rs_manc_t03 rs_manc_t04 rs_manc_t05 "
		       "rs_manc_t06 rs_manc_t07 rs_manc_t08 rs_manc_t09 rs_manc_t10 - rs_manc_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:mancubus role:artillery delivery:heavy payload:multi element:thermal mobility:ground";
	}

	// -----------------------------------------------------------------
	// THE SHADOW BEAST. A hard phase change at ~60% that swaps its whole
	// attack pool rather than just buffing it, plus a close-range panic
	// button: get inside its guard and it detonates a full ring.
	// -----------------------------------------------------------------
	const RS_MANC_TIER_PHASE  = 7;
	const RS_MANC_PHASE_SLOT  = 0;
	const RS_MANC_PANIC_RANGE = 220.0;

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		if (t < RS_MANC_TIER_PHASE)
			return null;

		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_MancFire(), 3, 24.0,
			"fatso/attack", 1.0, 0.0, "Triple Lob"));

		// Phase two replaces the pool -- denser and wider, not just
		// bigger numbers on the same attack.
		if (ThresholdFired(RS_MANC_PHASE_SLOT))
		{
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_MancFire(), 8, 90.0,
				"fatso/attack", 1.0, 4.0, "Weave"));
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_MancFire(), 16, 360.0,
				"fatso/attack", 1.0, 6.0, "Full Bloom"));
		}
		return slot;
	}

	States
	{
	Spawn:
		"FATT" AB 15  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"FATT" AABBCCDDEEFF 4  { RS_WearBody(); A_Chase(); }
		Loop;
	Missile:
		TNT1 A 0
		{
			// Panic button: too close, and it clears the room instead of
			// lobbing over your head.
			if (Tier >= RS_MANC_TIER_PHASE && target
			    && Distance3D(target) < RS_MANC_PANIC_RANGE)
				return ResolveState("Panic");
			if (Tier >= RS_MANC_TIER_PHASE)
				return ResolveState("Barrage");
			return ResolveState(null);
		}
		"FATT" G 20  { RS_WearBody(); A_FatRaise(); }
		"FATT" H 10  Bright { RS_WearBody(); A_FatAttack1(); }
		"FATT" IG 5  { RS_WearBody(); A_FaceTarget(); }
		"FATT" H 10  Bright { RS_WearBody(); A_FatAttack2(); }
		"FATT" IG 5  { RS_WearBody(); A_FaceTarget(); }
		"FATT" H 10  Bright { RS_WearBody(); A_FatAttack3(); }
		"FATT" IG 5  { RS_WearBody(); A_FaceTarget(); }
		Goto See;
	Barrage:
		"FATT" G 14  { RS_WearBody(); A_FatRaise(); }
		"FATT" H 10  Bright { RS_WearBody(); A_RS_MonsterFire(); }
		"FATT" IG 5  { RS_WearBody(); A_FaceTarget(); }
		"FATT" H 10  Bright { RS_WearBody(); A_RS_MonsterFire(); }
		Goto See;
	Panic:
		"FATT" G 12  { RS_WearBody(); A_FatRaise(); }
		"FATT" H 12  Bright
		{
			RS_WearBody();
			FireProfile(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_MancFire(), 20, 360.0,
				"fatso/attack", 1.0, 8.0, "Panic Ring"));
		}
		"FATT" I 12 { RS_WearBody(); }
		Goto See;
	Pain:
		"FATT" J 3 { RS_WearBody(); }
		"FATT" J 3  { RS_WearBody(); A_Pain(); }
		TNT1 A 0
		{
			if (Tier >= RS_MANC_TIER_PHASE && CheckThreshold(RS_MANC_PHASE_SLOT, 0.6))
			{
				Enrage(1.25);
				BuildAttacksForTier(-1);
				BuildAttacksForTier(Tier);
				A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
			}
		}
		Goto See;
	Death:
		"FATT" K 6 { RS_WearBody(); }
		"FATT" L 6  { RS_WearBody(); A_Scream(); }
		"FATT" M 6  { RS_WearBody(); A_NoBlocking(); }
		"FATT" NOPQRS 6 { RS_WearBody(); }
		"FATT" T -1  { RS_WearBody(); A_BossDeath(); }
		Stop;
	Raise:
		"FATT" R 5 { RS_WearBody(); }
		"FATT" QPONMLK 5 { RS_WearBody(); }
		Goto See;
	}
}
