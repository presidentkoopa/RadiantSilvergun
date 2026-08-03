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
		"####" AB 15 A_Look;
		Loop;
	See:
		"####" AABBCCDDEEFF 4 A_Chase;
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
		"####" G 20 A_FatRaise;
		"####" H 10 Bright A_FatAttack1;
		"####" IG 5 A_FaceTarget;
		"####" H 10 Bright A_FatAttack2;
		"####" IG 5 A_FaceTarget;
		"####" H 10 Bright A_FatAttack3;
		"####" IG 5 A_FaceTarget;
		Goto See;
	Barrage:
		"####" G 14 A_FatRaise;
		"####" H 10 Bright { A_RS_MonsterFire(); }
		"####" IG 5 A_FaceTarget;
		"####" H 10 Bright { A_RS_MonsterFire(); }
		Goto See;
	Panic:
		"####" G 12 A_FatRaise;
		"####" H 12 Bright
		{
			FireProfile(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_MancFire(), 20, 360.0,
				"fatso/attack", 1.0, 8.0, "Panic Ring"));
		}
		"####" I 12;
		Goto See;
	Pain:
		"####" J 3;
		"####" J 3 A_Pain;
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
		"####" K 6;
		"####" L 6 A_Scream;
		"####" M 6 A_NoBlocking;
		"####" NOPQRS 6;
		"####" T -1 A_BossDeath;
		Stop;
	Raise:
		"####" R 5;
		"####" QPONMLK 5;
		Goto See;
	}
}
