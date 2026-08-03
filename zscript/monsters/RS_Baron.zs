// =====================================================================
// RS_Baron -- the pack bruiser. Replaces BaronOfHell.
// ---------------------------------------------------------------------
// The most mechanically varied family in the whole survey. What's kept:
//
//   * a TENTACLE PACK with internal structure -- a melee rusher and a
//     ranged caster from the same summon, so the pack pincers instead
//     of forming one blob you can back away from;
//   * a permanent one-shot enrage at half health that also unlocks an
//     attack the Baron simply did not have before, so the second half
//     of the fight is a different fight;
//   * a real two-phase death -- the Baron falls and something faster
//     gets up.
//
// TIER GATING:
//   T00-T04  vanilla Baron. Fireball and claw.
//   T05+     ring bursts join the rotation.
//   T07+     summons the tendril pack.
//   T10+     death is a phase change into the Fallen.
// =====================================================================

class RS_Baron : RS_KnightBase replaces BaronOfHell
{
	const RS_BARON_ENRAGE_SLOT = 0;

	const RS_BARON_TIER_RING   = 5;
	const RS_BARON_TIER_PACK   = 7;
	const RS_BARON_TIER_FALLEN = 10;

	Default
	{
		Health 1000;
		Radius 24;
		Height 64;
		Mass 1000;
		Speed 8;
		PainChance 50;
		Monster;
		+FLOORCLIP +BOSSDEATH
		SeeSound "baron/sight";   PainSound "baron/pain";
		DeathSound "baron/death"; ActiveSound "baron/active";
		Obituary "$OB_BARON";
		HitObituary "$OB_BARONHIT";
		Tag "Baron of Hell";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "BOSS BOSS BOSS LOHS BOSS LOHS AZEW BOS4 STYR BOS4 BOS4 CUTH VSTL";
	}

	override string TintTable()
	{
		return "- rs_baron_t01 rs_baron_t02 rs_baron_t03 rs_baron_t04 rs_baron_t05 "
		       "rs_baron_t06 rs_baron_t07 rs_baron_t08 rs_baron_t09 rs_baron_t10 "
		       "rs_baron_t11 rs_baron_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:baron role:bruiser delivery:heavy delivery:melee element:thermal mobility:ground";
	}

	// The tendrils are part of the Baron, not independent monsters --
	// they go when it goes. Opposite call to the Pain Elemental's
	// escort, deliberately: these exist to pressure you DURING the
	// Baron fight, and leaving them behind would just pad it.
	override bool MinionsDieWithMe()
	{
		return true;
	}

	override Class<Actor> DeathMorphClass()
	{
		return (Tier >= RS_BARON_TIER_FALLEN) ? RS_MonsterCatalog.MORPH_BaronFallen() : null;
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		if (t < RS_BARON_TIER_RING)
			return null;

		let slot = RS_AttackSlot(new("RS_AttackSlot"));

		// Two aimed shots then a ring. The ring is the beat that makes
		// standing still lethal; the aimed shots are what punish you for
		// running in a straight line away from it.
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronStar(), 1, 0.0,
			"baron/attack", 1.0, 0.0, "Star"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronStar(), 3, 30.0,
			"baron/attack", 1.0, 0.0, "Star Fan"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronRing(),
			t >= 11 ? 24 : 14, 360.0,
			"baron/attack", 1.0, 4.0, "Hell Ring"));

		// The enrage unlock. Present in the table only once the gate has
		// actually fired, so the Baron cannot roll it early.
		if (ThresholdFired(RS_BARON_ENRAGE_SLOT))
		{
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_BaronBomb(), 1, 0.0,
				"baron/attack", 1.4, 0.0, "Hellbomb"));
		}

		return slot;
	}

	// Mixed pack: rushers plus one caster. The caster is what stops the
	// pack being solvable by standing on a ledge.
	void RS_SummonPack()
	{
		if (Tier < RS_BARON_TIER_PACK)
			return;

		int cap = (Tier >= 11) ? 6 : 4;
		if (CountLiveMinions() >= cap)
			return;

		int n = SummonPack(RS_MonsterCatalog.MINION_BaronRusher(), 2, cap, -3, 96.0);
		if (Tier >= 9)
			n += SummonPack(RS_MonsterCatalog.MINION_BaronRanger(), 1, cap, -3, 120.0);

		if (n > 0)
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	States
	{
	Spawn:
		"BOSS" AB 10  { RS_WearBody(); A_Look(); }
		Loop;

	See:
		"BOSS" AABBCCDD 3  { RS_WearBody(); A_Chase(); }
		Loop;

	Melee:
		"BOSS" EF 8  { RS_WearBody(); A_FaceTarget(); }
		"BOSS" G 8  { RS_WearBody(); A_BruisAttack(); }
		Goto See;

	Missile:
		TNT1 A 0
		{
			// Roughly one attack in four becomes a summon once the pack
			// is unlocked, so adds arrive between barrages rather than
			// replacing them.
			if (Tier >= RS_BARON_TIER_PACK && random(0, 255) < 64)
				return ResolveState("SummonPack");
			return ResolveState(null);
		}
		"BOSS" EF 8  { RS_WearBody(); A_FaceTarget(); }
		"BOSS" G 8  Bright
		{
			RS_WearBody();
			if (Tier >= RS_BARON_TIER_RING)
				A_RS_MonsterFire();
			else
				A_BruisAttack();
		}
		Goto See;

	SummonPack:
		"BOSS" E 10  { RS_WearBody(); A_FaceTarget(); }
		"BOSS" F 12  Bright { RS_WearBody(); RS_SummonPack(); }
		"BOSS" G 8 { RS_WearBody(); }
		Goto See;

	Pain:
		"BOSS" H 2 { RS_WearBody(); }
		"BOSS" H 2  { RS_WearBody(); A_Pain(); }
		TNT1 A 0
		{
			if (CheckThreshold(RS_BARON_ENRAGE_SLOT, 0.5))
			{
				Enrage(1.3);
				A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
				// Rebuild the rotation so the unlocked attack is
				// actually reachable from here on.
				BuildAttacksForTier(-1);
				BuildAttacksForTier(Tier);
				// It arrives angry, not just stronger.
				RS_SummonPack();
			}
		}
		Goto See;

	Death:
		"BOSS" I 8 { RS_WearBody(); }
		"BOSS" J 8  { RS_WearBody(); A_Scream(); }
		"BOSS" K 8 { RS_WearBody(); }
		"BOSS" L 8  { RS_WearBody(); A_NoBlocking(); }
		"BOSS" MN 8 { RS_WearBody(); }
		"BOSS" N -1  { RS_WearBody(); A_BossDeath(); }
		Stop;

	Raise:
		"BOSS" NMLKJI 8 { RS_WearBody(); }
		Goto See;
	}
}

// =====================================================================
// RS_BaronFallen -- stage two.
// ---------------------------------------------------------------------
// Faster, airborne, and it trades the pack for relentless direct fire.
// The design intent is a chase: the thing that was lumbering at you is
// suddenly quicker than you are.
// =====================================================================

class RS_BaronFallen : RS_MonsterMaster
{
	Default
	{
		Health 600;
		Radius 24;
		Height 56;
		Mass 400;
		Speed 18;
		PainChance 40;
		Monster;
		+FLOAT +NOGRAVITY +MISSILEMORE +DONTFALL
		RenderStyle "Add";
		Alpha 0.9;
		SeeSound "baron/sight";   PainSound "baron/pain";
		DeathSound "baron/death"; ActiveSound "baron/active";
		Obituary "$OB_BARON";
		Tag "Fallen Baron";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "BOS4 BOS4 BOS4 LOHS BOS4 LOHS AZEW BOS4 STYR BOS4 BOS4 CUTH VSTL";
	}

	override string TintTable()
	{
		return "- rs_baron_t01 rs_baron_t02 rs_baron_t03 rs_baron_t04 rs_baron_t05 "
		       "rs_baron_t06 rs_baron_t07 rs_baron_t08 rs_baron_t09 rs_baron_t10 "
		       "rs_baron_t11 rs_baron_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:baron role:artillery delivery:heavy element:thermal mobility:flying trait:secondstage";
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronStar(), 2, 18.0,
			"baron/attack", 1.0, 0.0, "Twin Star"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronBomb(), 1, 0.0,
			"baron/attack", 1.2, 0.0, "Hellbomb"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronRing(), 18, 360.0,
			"baron/attack", 1.0, 5.0, "Hell Ring"));
		return slot;
	}

	States
	{
	Spawn:
		"BOS4" AB 8  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"BOS4" AABBCCDD 2  { RS_WearBody(); A_Chase(); }
		Loop;
	Missile:
		"BOS4" EF 6  { RS_WearBody(); A_FaceTarget(); }
		"BOS4" G 8  Bright { RS_WearBody(); A_RS_MonsterFire(); }
		Goto See;
	Pain:
		"BOS4" H 2 { RS_WearBody(); }
		"BOS4" H 2  { RS_WearBody(); A_Pain(); }
		Goto See;
	Death:
		"BOS4" I 8 { RS_WearBody(); }
		"BOS4" J 8  { RS_WearBody(); A_Scream(); }
		"BOS4" K 8 { RS_WearBody(); }
		"BOS4" L 8  { RS_WearBody(); A_NoBlocking(); }
		"BOS4" MN 8 { RS_WearBody(); }
		"BOS4" N -1 { RS_WearBody(); }
		Stop;
	}
}
