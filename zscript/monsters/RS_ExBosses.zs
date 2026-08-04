// =====================================================================
// RS_ExBosses -- the EX tier. Set-piece encounters, not ambient spawns.
// ---------------------------------------------------------------------
// Rebuilt from CHP's BlackEX / WhiteEX variants, which the survey found
// are genuinely different animals from the T00-T12 ladder: multi-phase
// bodies, health-gated attack rosters that GROW as the fight goes, and
// squad summons on a hit counter.
//
// These replace the old RS_TEX_* files, which were imported under an
// earlier system and were still prefixed for a foreign class tree --
// they could never have compiled against the current
// template. Removed rather than patched.
//
// WHY TierLocked: an EX boss ignores the ambient tier dial entirely and
// keeps its hand-authored stats. It is a purchased/event encounter, not
// something the room's difficulty knob should be sliding around
// mid-fight. That's the D10 decision from the design brief and it is
// the whole reason TierLocked exists on the base class.
//
// None of these `replaces` anything -- they are summoned deliberately,
// never map-placed by accident.
// =====================================================================

// ---------------------------------------------------------------------
// RS_EX_Archvile -- "the void". CHP's black archvile EX is a two-body
// boss whose attack roster expands at each health gate and which, on
// "death", does not end -- it releases a phantom that counts the hits
// it takes and answers every eighth with a squad.
// ---------------------------------------------------------------------

class RS_EX_Archvile : RS_MonsterMaster
{
	const RS_EXV_GATE1 = 0;   // 66% -- second attack becomes available
	const RS_EXV_GATE2 = 1;   // 33% -- third, and it speeds up

	Default
	{
		Health 2700;
		Radius 24;
		Height 60;
		Mass 1000;
		Speed 18;
		PainChance 24;
		Monster;
		+BOSS +FLOORCLIP +QUICKTORETALIATE +NORADIUSDMG
		+DONTMORPH +NOTARGET
		MaxTargetRange 1400;
		SeeSound "vile/sight";   PainSound "vile/pain";
		DeathSound "vile/death"; ActiveSound "vile/active";
		Obituary "$OB_VILE";
		Tag "Arch-Vile EX";
	}

	override bool TierLocked() { return true; }
	override bool MinionsDieWithMe() { return true; }

	override string BodyTable()
	{
		// Single body -- an EX boss doesn't ride the ladder, so every
		// entry is the same. Kept as a full table rather than empty so
		// the shape stays uniform with every other monster.
		return "LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ";
	}

	override string TintTable()
	{
		return "rs_vile_t12 rs_vile_t12 rs_vile_t12 rs_vile_t12 rs_vile_t12 "
		       "rs_vile_t12 rs_vile_t12 rs_vile_t12 rs_vile_t12 rs_vile_t12 "
		       "rs_vile_t12 rs_vile_t12 rs_vile_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:archvile role:summoner delivery:radial delivery:heavy "
		       "element:thermal mobility:ground trait:resurrector trait:ex";
	}

	// Its death is a phase change, always -- that's what makes it EX.
	override Class<Actor> DeathMorphClass()
	{
		return RS_MonsterCatalog.MORPH_ExVilePhantom();
	}

	// THE GROWING ROSTER. One attack at full health, three by the end.
	// The fight gets wider as it goes, not just harder.
	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));

		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_VileBolt(), 3, 30.0,
			"vile/firecrkl", 1.0, 0.0, "Seeker Fan"));

		if (ThresholdFired(RS_EXV_GATE1))
		{
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_VileBoltHeavy(), 12, 360.0,
				"vile/firecrkl", 1.0, 6.0, "Void Ring"));
		}

		if (ThresholdFired(RS_EXV_GATE2))
		{
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_VileIce(), 8, 120.0,
				"vile/firecrkl", 1.2, 8.0, "Shatter Wave"));
			slot.Append(RS_AttackProfile.MakeSummon(
				"RS_Revenant", 2, 6, -2,
				RS_MonsterCatalog.SND_Summon(), "Call the Dead"));
		}

		return slot;
	}

	private void RS_Gate()
	{
		if (CheckThreshold(RS_EXV_GATE1, 0.66))
		{
			Enrage(1.15);
			A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
			BuildAttacksForTier(-1); BuildAttacksForTier(Tier);
		}
		else if (CheckThreshold(RS_EXV_GATE2, 0.33))
		{
			Enrage(1.2);
			A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
			BuildAttacksForTier(-1); BuildAttacksForTier(Tier);
		}
	}

	States
	{
	Spawn:
		TNT1 A 0 NoDelay
		{
			// Wears the eyes from the outset -- an EX vile is never the
			// quiet kind.
			AttachSatellite(RS_MonsterCatalog.SAT_VileEye(),   0, 46, 52);
			AttachSatellite(RS_MonsterCatalog.SAT_VileEye(), 120, 46, 52);
			AttachSatellite(RS_MonsterCatalog.SAT_VileEye(), 240, 46, 52);
		}
		// LMWZ ships frames A and E-P ONLY (verified on disk; CH's own
		// decorate never touches B-D or Q-Z). Choreography follows CH:
		// walk EF, cast E/F/G/H, pain I, death J-P.
		"LMWZ" EF 10  { A_Look(); }
		Loop;
	See:
		"LMWZ" EEFFGG 2  { A_VileChase(); }
		Loop;
	Missile:
		"LMWZ" E 0  Bright { A_VileStart(); }
		"LMWZ" E 8  Bright { A_FaceTarget(); }
		"LMWZ" F 8  Bright { A_RS_MonsterFire(); }
		"LMWZ" GH 6  Bright { A_FaceTarget(); }
		"LMWZ" G 8  Bright { A_RS_MonsterFire(); }
		"LMWZ" E 14  Bright;
		Goto See;
	Pain:
		"LMWZ" I 4;
		"LMWZ" I 4  { A_Pain(); }
		TNT1 A 0
		{
			RS_Gate();
			if (random(0, 255) < 110)
				PhaseDodge(40, 4.0, 0.25);
		}
		Goto See;
	Death:
		"LMWZ" J 7;
		"LMWZ" K 7  { A_Scream(); }
		"LMWZ" L 7  { A_NoBlocking(); }
		"LMWZ" MNO 7;
		"LMWZ" P -1;
		Stop;
	}
}

// ---------------------------------------------------------------------
// RS_EX_ArchvilePhantom -- what the EX vile leaves behind.
// Intangible-looking, wanders, and counts the hits it takes: every
// eighth answers with a squad. You cannot burn it down without feeding
// the very thing that punishes you.
// ---------------------------------------------------------------------

class RS_EX_ArchvilePhantom : RS_MonsterMaster
{
	const RS_PHANTOM_SQUAD_AT = 8;

	Default
	{
		Health 4166;
		Radius 24;
		Height 60;
		Mass 1000;
		Speed 22;
		PainChance 40;
		Monster;
		+BOSS +FLOAT +NOGRAVITY +MISSILEMORE +NORADIUSDMG +DONTMORPH
		RenderStyle "Translucent";
		Alpha 0.55;
		SeeSound "vile/sight";   PainSound "vile/pain";
		DeathSound "vile/death"; ActiveSound "vile/active";
		Obituary "$OB_VILE";
		Tag "Arch-Vile EX (Void)";
	}

	override bool TierLocked() { return true; }
	override bool MinionsDieWithMe() { return true; }

	override string BodyTable()
	{
		return "LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ LMWZ";
	}

	override string GetBaseKeywords()
	{
		return "species:archvile role:summoner delivery:radial element:void "
		       "mobility:flying trait:secondstage trait:ex";
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_VileBoltHeavy(), 6, 60.0,
			"vile/firecrkl", 1.0, 5.0, "Void Fan"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_VileBoltHeavy(), 18, 360.0,
			"vile/firecrkl", 1.0, 8.0, "Collapse"));
		slot.Append(RS_AttackProfile.MakeRadial(
			320.0, 40, 0, false,
			RS_MonsterCatalog.SND_Enrage(), "Void Pulse"));
		return slot;
	}

	// The hit counter. Answers every eighth hit with a squad, then
	// resets -- so a burst-damage player triggers it faster than a
	// careful one, which is the point.
	private void RS_CountHit()
	{
		AddCharge(1);
		if (ChargeCounter < RS_PHANTOM_SQUAD_AT)
			return;

		ResetCharge();
		int n = SummonPack("RS_Revenant", 2, 8, -1, 120.0);
		n    += SummonPack("RS_Cacodemon", 1, 8, -2, 150.0);
		if (n > 0)
			A_StartSound(RS_MonsterCatalog.SND_Summon(), CHAN_BODY);
	}

	States
	{
	Spawn:
		TNT1 A 0 NoDelay A_StartSound("vile/sight", CHAN_VOICE);
		"LMWZ" EF 8  { A_Look(); }
		Loop;
	See:
		"LMWZ" EEFFGG 2  { A_Chase(); }
		Loop;
	Missile:
		"LMWZ" G 6  Bright { A_FaceTarget(); }
		"LMWZ" H 10  Bright { A_RS_MonsterFire(); }
		"LMWZ" E 10  Bright;
		Goto See;
	Pain:
		"LMWZ" I 3;
		"LMWZ" I 3  { A_Pain(); }
		TNT1 A 0 { RS_CountHit(); }
		Goto See;
	Death:
		"LMWZ" J 6;
		"LMWZ" K 6  { A_Scream(); }
		"LMWZ" L 6  { A_NoBlocking(); }
		"LMWZ" MNO 6;
		"LMWZ" P -1;
		Stop;
	}
}

// ---------------------------------------------------------------------
// RS_EX_Baron -- "the tyrant". The pack boss taken to its conclusion:
// it holds a standing guard, replaces it, and enrages twice.
// ---------------------------------------------------------------------

class RS_EX_Baron : RS_MonsterMaster
{
	const RS_EXB_GATE1 = 0;
	const RS_EXB_GATE2 = 1;
	const RS_EXB_GUARD_INTERVAL = 105;

	private int rsNextGuardCheck;

	Default
	{
		Health 3500;
		Radius 28;
		Height 72;
		Mass 1500;
		Speed 12;
		PainChance 20;
		Monster;
		+BOSS +FLOORCLIP +NORADIUSDMG +DONTMORPH
		SeeSound "baron/sight";   PainSound "baron/pain";
		DeathSound "baron/death"; ActiveSound "baron/active";
		Obituary "$OB_BARON";
		HitObituary "$OB_BARONHIT";
		Tag "Baron of Hell EX";
	}

	override bool TierLocked() { return true; }
	override bool MinionsDieWithMe() { return true; }

	override string BodyTable()
	{
		return "VSTL VSTL VSTL VSTL VSTL VSTL VSTL VSTL VSTL VSTL VSTL VSTL VSTL";
	}

	override string TintTable()
	{
		return "rs_baron_t12 rs_baron_t12 rs_baron_t12 rs_baron_t12 rs_baron_t12 "
		       "rs_baron_t12 rs_baron_t12 rs_baron_t12 rs_baron_t12 rs_baron_t12 "
		       "rs_baron_t12 rs_baron_t12 rs_baron_t12";
	}

	override string GetBaseKeywords()
	{
		return "species:baron role:summoner delivery:heavy delivery:melee "
		       "element:thermal mobility:ground trait:ex";
	}

	override RS_AttackSlot BuildTierAttacks(int t)
	{
		let slot = RS_AttackSlot(new("RS_AttackSlot"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronStar(), 4, 36.0,
			"baron/attack", 1.0, 0.0, "Star Fan"));
		slot.Append(RS_AttackProfile.MakeVolley(
			RS_MonsterCatalog.PROJ_BaronRing(), 20, 360.0,
			"baron/attack", 1.0, 5.0, "Tyrant Ring"));

		if (ThresholdFired(RS_EXB_GATE1))
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_BaronBomb(), 3, 24.0,
				"baron/attack", 1.3, 0.0, "Hellbombs"));

		if (ThresholdFired(RS_EXB_GATE2))
			slot.Append(RS_AttackProfile.MakeVolley(
				RS_MonsterCatalog.PROJ_BaronRing(), 30, 360.0,
				"baron/attack", 1.2, 10.0, "Total Collapse"));

		return slot;
	}

	// A STANDING GUARD, not a burst -- topped up on a throttle so the
	// arena never empties out while the boss is alive.
	private void RS_TickGuard()
	{
		if (health <= 0 || level.time < rsNextGuardCheck)
			return;
		rsNextGuardCheck = level.time + RS_EXB_GUARD_INTERVAL;

		int want = ThresholdFired(RS_EXB_GATE1) ? 6 : 4;
		if (CountLiveMinions() >= want)
			return;

		SummonPack(RS_MonsterCatalog.MINION_BaronRusher(), 1, want, -1, 110.0);
		if (ThresholdFired(RS_EXB_GATE1))
			SummonPack(RS_MonsterCatalog.MINION_BaronRanger(), 1, want, -1, 140.0);
	}

	override void Tick()
	{
		Super.Tick();
		RS_TickGuard();
	}

	States
	{
	Spawn:
		"VSTL" AB 10  { A_Look(); }
		Loop;
	See:
		"VSTL" AABBCCDD 3  { A_Chase(); }
		Loop;
	Melee:
		"VSTL" EF 6  { A_FaceTarget(); }
		"VSTL" G 6  { A_BruisAttack(); }
		Goto See;
	Missile:
		"VSTL" EF 6  { A_FaceTarget(); }
		"VSTL" G 10  Bright { A_RS_MonsterFire(); }
		Goto See;
	Pain:
		"VSTL" H 2;
		"VSTL" H 2  { A_Pain(); }
		TNT1 A 0
		{
			if (CheckThreshold(RS_EXB_GATE1, 0.66) || CheckThreshold(RS_EXB_GATE2, 0.33))
			{
				Enrage(1.2);
				A_StartSound(RS_MonsterCatalog.SND_Enrage(), CHAN_VOICE);
				BuildAttacksForTier(-1); BuildAttacksForTier(Tier);
			}
		}
		Goto See;
	Death:
		"VSTL" I 8;
		"VSTL" J 8  { A_Scream(); }
		"VSTL" K 8;
		"VSTL" L 8  { A_NoBlocking(); }
		"VSTL" MN 8;
		"VSTL" N -1  { A_BossDeath(); }
		Stop;
	}
}
