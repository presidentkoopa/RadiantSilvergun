// =====================================================================
// RS_Cacodemon -- the decoy. Replaces Cacodemon.
// ---------------------------------------------------------------------
// Picked as the fourth flagship precisely because it is NOT another
// summoner. CHP's white cacodemon is a deception: the thing floating at
// you is a shell that fakes its own death, and only its real death
// releases what was inside.
//
// What's kept:
//   * PLAY DEAD -- on taking pain at high tier it can drop, go limp and
//     briefly untargetable, then come back. The player learns not to
//     trust a downed caco.
//   * THE REVEAL -- its true death spawns the real thing, which is
//     faster, angrier, and fires patterns the shell never had.
//
// TIER GATING:
//   T00-T05  vanilla cacodemon.
//   T06+     ring bursts join the rotation.
//   T09+     can play dead on pain.
//   T11+     death is a phase change into the true form.
// =====================================================================

class RS_Cacodemon : RS_MonsterMaster replaces Cacodemon
{
	const RS_CACO_TIER_RING   = 6;
	const RS_CACO_TIER_POSSUM = 9;
	const RS_CACO_TIER_REAL   = 11;

	// Guards the play-dead so it can't chain-loop into being permanently
	// untouchable. One per life is a scare; three is a joke.
	private int rsPossumsUsed;

	Default
	{
		Health 400;
		Radius 31;
		Height 56;
		Mass 400;
		Speed 8;
		PainChance 128;
		Monster;
		+FLOAT +NOGRAVITY +FLOORCLIP
		SeeSound "caco/sight";   PainSound "caco/pain";
		DeathSound "caco/death"; ActiveSound "caco/active";
		Obituary "$OB_CACO";
		HitObituary "$OB_CACOHIT";
		Tag "Cacodemon";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "HEAD HEAD HEAD HELE HEAD CALI VCCM HEAD GREL HEAD HED9 HELE HELE";
	}

	override string TintTable()
	{
		return "- rs_caco_t01 rs_caco_t02 rs_caco_t03 rs_caco_t04 rs_caco_t05 "
		       "rs_caco_t06 rs_caco_t07 - rs_caco_t09 rs_caco_t10 rs_caco_t11 -";
	}

	override string GetBaseKeywords()
	{
		return "species:cacodemon role:artillery delivery:heavy element:thermal mobility:floating";
	}

	override Class<Actor> DeathMorphClass()
	{
		return (Tier >= RS_CACO_TIER_REAL) ? RS_MonsterCatalog.MORPH_CacoReal() : null;
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		if (t < RS_CACO_TIER_RING)
			return null;

		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_CacoBall(), 1, 0.0,
			"caco/attack", 1.0, 0.0, "Spit"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_CacoFire(), 3, 26.0,
			"caco/attack", 1.0, 0.0, "Fire Spread"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_CacoBall(),
			t >= 12 ? 14 : 9, 360.0,
			"caco/attack", 1.0, 5.0, "Spit Ring"));
		return slot;
	}

	bool CanPlayDead()
	{
		return Tier >= RS_CACO_TIER_POSSUM && rsPossumsUsed < 1;
	}

	States
	{
	Spawn:
		"HEAD" A 10  { RS_WearBody(); A_Look(); }
		Loop;

	See:
		"HEAD" A 3  { RS_WearBody(); A_Chase(); }
		Loop;

	Missile:
		"HEAD" B 5  { RS_WearBody(); A_FaceTarget(); }
		"HEAD" C 5  { RS_WearBody(); A_FaceTarget(); }
		"HEAD" D 5  Bright
		{
			RS_WearBody();
			if (Tier >= RS_CACO_TIER_RING)
				A_RS_MonsterFire();
			else
				A_HeadAttack();
		}
		Goto See;

	Pain:
		"HEAD" E 3 { RS_WearBody(); }
		"HEAD" E 3  { RS_WearBody(); A_Pain(); }
		TNT1 A 0
		{
			if (CanPlayDead() && random(0, 255) < 60)
				return ResolveState("PlayDead");
			return ResolveState(null);
		}
		"HEAD" F 6 { RS_WearBody(); }
		Goto See;

	// The fake. Drops, stops being a valid target, waits, then comes
	// back up shooting. Uses the real death frames so it reads as a
	// genuine kill right up until it moves again.
	PlayDead:
		TNT1 A 0
		{
			rsPossumsUsed++;
			bSHOOTABLE = false;
			bNOPAIN    = true;
			A_StartSound("caco/death", CHAN_VOICE);
		}
		"HEAD" G 8 { RS_WearBody(); }
		"HEAD" H 8 { RS_WearBody(); }
		"HEAD" I 8 { RS_WearBody(); }
		"HEAD" JK 8 { RS_WearBody(); }
		"HEAD" L 60 { RS_WearBody(); }            // lies there long enough to be believed
		TNT1 A 0
		{
			bSHOOTABLE = true;
			bNOPAIN    = false;
			// Gets up angry -- a brief spike so the punish for walking
			// past it is real.
			PulseStats(1.6, 1.25, 140, false);
			A_StartSound("caco/sight", CHAN_VOICE);
		}
		"HEAD" KJIHG 5 { RS_WearBody(); }
		Goto See;

	Death:
		"HEAD" G 8 { RS_WearBody(); }
		"HEAD" H 8  { RS_WearBody(); A_Scream(); }
		"HEAD" I 8 { RS_WearBody(); }
		"HEAD" J 8 { RS_WearBody(); }
		"HEAD" K 8  { RS_WearBody(); A_NoBlocking(); }
		"HEAD" L -1  { RS_WearBody(); A_SetFloorClip(); }
		Stop;

	Raise:
		"HEAD" L 8  { RS_WearBody(); A_UnSetFloorClip(); }
		"HEAD" KJIHG 8 { RS_WearBody(); }
		Goto See;
	}
}

// =====================================================================
// RS_CacodemonReal -- what was actually inside.
// ---------------------------------------------------------------------
// Stage two. Smaller, much faster, and it opens with a summon the shell
// never had -- the reveal should change the shape of the fight, not
// just extend it.
// =====================================================================

class RS_CacodemonReal : RS_MonsterMaster
{
	const RS_CACOREAL_RAGE_SLOT = 0;

	Default
	{
		Health 500;
		Radius 24;
		Height 44;
		Mass 300;
		Speed 14;
		PainChance 60;
		Monster;
		+FLOAT +NOGRAVITY +MISSILEMORE
		RenderStyle "Add";
		Alpha 0.95;
		SeeSound "caco/sight";   PainSound "caco/pain";
		DeathSound "caco/death"; ActiveSound "caco/active";
		Obituary "$OB_CACO";
		Tag "Cacodemon (True Form)";
	}

	override string BodyTable()
	{
		//      T00  T01  T02  T03  T04  T05  T06  T07  T08  T09  T10  T11  T12
		return "HELE HELE HELE HELE HELE CALI VCCM HELE GREL HELE HED9 HELE HELE";
	}

	override string TintTable()
	{
		return "- rs_caco_t01 rs_caco_t02 rs_caco_t03 rs_caco_t04 rs_caco_t05 "
		       "rs_caco_t06 rs_caco_t07 - rs_caco_t09 rs_caco_t10 rs_caco_t11 -";
	}

	override string GetBaseKeywords()
	{
		return "species:cacodemon role:artillery delivery:heavy element:thermal mobility:floating trait:secondstage";
	}

	override bool MinionsDieWithMe()
	{
		return true;
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_CacoFire(), 2, 16.0,
			"caco/attack", 1.0, 0.0, "Twin Fire"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_CacoIce(), 1, 0.0,
			"caco/attack", 1.2, 0.0, "Ice Lance"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_CacoBall(), 16, 360.0,
			"caco/attack", 1.0, 6.0, "Full Ring"));
		return slot;
	}

	States
	{
	Spawn:
		// Announces itself. The shell died quietly; this doesn't.
		"HELE" A 8  Bright { RS_WearBody(); A_StartSound("caco/sight", CHAN_VOICE); }
		"HELE" A 10  { RS_WearBody(); A_Look(); }
		Loop;
	See:
		"HELE" A 3  { RS_WearBody(); A_Chase(); }
		Loop;
	Missile:
		"HELE" B 4  { RS_WearBody(); A_FaceTarget(); }
		"HELE" C 4  { RS_WearBody(); A_FaceTarget(); }
		"HELE" D 5  Bright { RS_WearBody(); A_RS_MonsterFire(); }
		Goto See;
	Pain:
		"HELE" E 3 { RS_WearBody(); }
		"HELE" E 3  { RS_WearBody(); A_Pain(); }
		TNT1 A 0
		{
			if (CheckThreshold(RS_CACOREAL_RAGE_SLOT, 0.45))
			{
				Enrage(1.4);
				A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
			}
		}
		"HELE" F 5 { RS_WearBody(); }
		Goto See;
	Death:
		"HELE" G 6 { RS_WearBody(); }
		"HELE" H 6  { RS_WearBody(); A_Scream(); }
		"HELE" I 6 { RS_WearBody(); }
		"HELE" J 6 { RS_WearBody(); }
		"HELE" K 6  { RS_WearBody(); A_NoBlocking(); }
		"HELE" L -1 { RS_WearBody(); }
		Stop;
	}
}
