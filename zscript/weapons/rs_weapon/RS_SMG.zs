// VR_SMG -- the SMG weapon type.
// ---------------------------------------------------------------------
// Real data: dmg anchor 5-11, magazine 30, reload SMGR A(2)/B-T(1 each).
// Real sounds: smgfire/smgclip. Full-auto: no release gate, fires on
// RateOfFire-derived cooldown while trigger held via A_ReFire (see GetTimeBetweenShots() in RS_Weapon).
// =====================================================================
class VR_SMG : RS_Weapon
{
	Default
	{
		Tag "Chatterbox";
		Weapon.SelectionOrder 1878;
		Weapon.SlotNumber 2;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 60;
		Weapon.AmmoType1 "Clip";
		Weapon.AmmoType2 "VR_SMGLoaded";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_SMG; }

	override string GetBaseKeywords()
	{
		return "archetype:smg trigger:fullauto delivery:bullet payload:single feed:atomic-fill reserve:clip element:kinetic promotion:pellet set:radiantsilvergun";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(5, 11);
				Accuracy      = RS_Roll.RollDouble(55, 65);
				Velocity      = RS_Roll.RollDouble(52, 68);
				CritChance    = RS_Roll.RollDouble(0.01, 0.02);
				Capacity      = 30;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(6, 13);
				Accuracy      = RS_Roll.RollDouble(57, 67);
				Velocity      = RS_Roll.RollDouble(52, 68);
				CritChance    = RS_Roll.RollDouble(0.012, 0.025);
				Capacity      = 30;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(7, 15);
				Accuracy      = RS_Roll.RollDouble(59, 69);
				Velocity      = RS_Roll.RollDouble(52, 68);
				CritChance    = RS_Roll.RollDouble(0.014, 0.03);
				Capacity      = 30;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(9, 17);
				Accuracy      = RS_Roll.RollDouble(61, 71);
				Velocity      = RS_Roll.RollDouble(52, 72);
				CritChance    = RS_Roll.RollDouble(0.016, 0.035);
				Capacity      = 30;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(11, 19);
				Accuracy      = RS_Roll.RollDouble(63, 73);
				Velocity      = RS_Roll.RollDouble(52, 76);
				CritChance    = RS_Roll.RollDouble(0.018, 0.04);
				Capacity      = 40;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(13, 21);
				Accuracy      = RS_Roll.RollDouble(65, 75);
				Velocity      = RS_Roll.RollDouble(52, 80);
				CritChance    = RS_Roll.RollDouble(0.02, 0.045);
				Capacity      = 40;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(14, 20);
					CritChance    = RS_Roll.RollDouble(0.04, 0.06);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(3, 7);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(45, 58);
				Velocity = RS_Roll.RollDouble(48, 64);
				Capacity = 30;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(10, 16);
				Accuracy      = RS_Roll.RollDouble(50, 65);
				Velocity      = RS_Roll.RollDouble(52, 72);
				CritChance    = RS_Roll.RollDouble(0.03, 0.05);
				Capacity      = 30;
				break;
		}

		if (t == VRT_Cursed)
		{
			LockedDamage     = true;
			LockedCritChance = true;
		}
		else
		{
			LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false;
		}

		RateOfFire       = 10;  // real cadence, fixed
		ReloadSpeed       = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		CritMult          = RS_Roll.RollDouble(1.4 + idx * 0.15, 1.6 + idx * 0.4);
		PelletCount       = 1;
		Choke             = RS_Roll.RollDouble(0.2 + idx * 0.03, 0.4 + idx * 0.04);
		GunBonaiSockets   = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(RS_Roll.STARTING_CONDITION_MIN, 100);

		bStatsRolled = true;
	}


	// Full-auto: no cadence-overshoot penalty. RateOfFire IS the cadence
	// here, hard-gated by AutoCooldownReady(), so there's nothing to outpace.
	//
	// ================================================================
	// FX PROOF-OF-CONCEPT, added 2026-08-08. NOT a real per-family
	// system -- exists to prove that a weapon's projectile/puff/spark
	// identity can be swapped LIVE, no re-equip, via rs_smg_fxtest.
	// SMG only; every other family is untouched.
	//
	// 0 = stock (whatever MakeBullet already resolved to before this).
	// 1 = the owner's actual request. Held equal to stock until he
	//     names it -- swapping this in is a one-line change once he
	//     does, everything else here already proves the mechanism works.
	// 2, 3 = two combinations picked only to be visibly distinct from
	//     stock and from each other, built entirely from classes that
	//     already exist and were read end to end before being used
	//     here -- no new art, and nothing borrowed that carries baked-in
	//     behaviour that would be wrong on a bullet weapon (RS_ChainsawPuff
	//     hardcodes its own saw sound/debris regardless of material, so
	//     it was left out even though it is visually distinct).
	//
	//   2: RS_EnhancedBulletPuff (RSU1, the base class's own frames --
	//      a different sheet from the stock streak puff) + SPARK_XHeavy
	//      + RS_BallisticType2 (RSB1, currently PS-only, one frame)
	//   3: PUFF_Vanilla (the engine's own BulletPuff, zero custom code)
	//      + SPARK_XNoModel + the stock RS_BallisticType1 body, so 2 and
	//      3 differ from each other on body as well as puff/spark
	//
	// Trail and muzzle smoke are not varied: RS_StreakTrail and
	// RS_SmokeWisp were the only real generic options found when this
	// was built (see docs/rs_MASTER_FX_CATALOG.txt, which is a header
	// with the descriptive sections unwritten -- "(pending inventory
	// pass)" -- so there is nothing else to honestly pick from yet).
	// ================================================================
	int mFXTestVariant;

	override void DoEffect()
	{
		Super.DoEffect();
		let cv = CVar.FindCVar("rs_smg_fxtest");
		int want = cv ? clamp(cv.GetInt(), 0, 3) : 0;
		if (want == mFXTestVariant)
			return;
		mFXTestVariant = want;

		// Mirrors EnsureAttackProfiles()'s own slot-reset exactly, but
		// deliberately skips its bProfilesBuilt guard (which would make
		// a second call a no-op -- this IS the second call, on purpose)
		// and its CaptureGunAxes() (documented there as "immediately
		// after, and never again": it captures the gun's shipped
		// identity for curse/imprint bookkeeping, and re-running it on
		// a debug toggle would corrupt that).
		PrimarySlot   = RS_AttackSlot(new("RS_AttackSlot"));
		SecondarySlot = RS_AttackSlot(new("RS_AttackSlot"));
		BuildAttackProfiles();
	}

	override void BuildAttackProfiles()
	{
		Class<Actor> proj = null, puff = null, spark = null;

		if (mFXTestVariant == 2)
		{
			proj  = "RS_BallisticType2";
			puff  = "RS_EnhancedBulletPuff";
			spark = RS_Catalog.SPARK_XHeavy();
		}
		else if (mFXTestVariant == 3)
		{
			puff  = RS_Catalog.PUFF_Vanilla();
			spark = RS_Catalog.SPARK_XNoModel();
		}
		// 0 and 1 both leave proj/puff/spark null, which is exactly
		// today's stock behaviour -- the four-rung chain in
		// RS_FireProfileBullet falls through to the same catalog
		// defaults it always has.

		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_SMG(),
			spreadScale: 0.05,
			usesCadence: false,
			ammoCost: 1,
			casing: RS_Catalog.CASING_Small(),
			bigMuzzle: true,
			proj: proj,
			impactPuff: puff,
			impactSparks: spark,
			profName: "Auto Burst"));
	}

	States
	{
	Spawn:
		SMP1 A -1;
		Stop;

	Ready:
		SMGG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		SMGG A 1 A_Lower;
		Loop;

	Select:
		SMGG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		// Real frame sequence from the reference file: SMGF A->B->C is the
		// gun body's actual recoil animation, matching MODELDEF's bound
		// frames 4/5/6 (see "Model VR_SMG" / "Model VR_SMG2" etc., the
		// PitchOffset-0.0 blocks). The old comment claiming the body never
		// moves was checked against the wrong reference -- it does move,
		// on the main sprite, not just the flash overlay below.
		SMGF A 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		SMGF B 1;
		SMGF C 1;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	// Real exact frame sequence from the reference file.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("smgclip", CHAN_AUTO);
		SMGR A 2;
		SMGR BCDEFGHIJKLMNOPQRST 1 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		// Full 3-frame flash cycle (matches the reference and the existing
		// MODELDEF bindings, frames 4/5/6) -- this is what actually sells
		// the recoil punch, since the gun body itself holds still.
		SMGF ABC 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class VR_SMG2 : VR_SMG
{
	Default
	{
		Tag "Backtalk";
		Weapon.SelectionOrder 1877;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_SMGLoaded2";
	}
}

class VR_SMG3 : VR_SMG
{
	Default
	{
		Tag "Crosstalk";
		Weapon.SelectionOrder 1876;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_SMGLoaded3";
	}
}

class VR_SMG4 : VR_SMG
{
	Default
	{
		Tag "Smalltalk";
		Weapon.SelectionOrder 1875;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_SMGLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_SMG5 : VR_SMG
{
	Default
	{
		Tag "Doubletalk";
		Weapon.SelectionOrder 1874;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_SMGLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_SMG6 : VR_SMG
{
	Default
	{
		Tag "Sweet Talk";
		Weapon.SelectionOrder 1873;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_SMGLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
