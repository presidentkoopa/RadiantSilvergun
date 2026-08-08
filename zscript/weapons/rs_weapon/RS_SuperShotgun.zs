// VR_SuperShotgun -- the Super Shotgun weapon type.
// ---------------------------------------------------------------------
// Real data confirmed from the actual old SSG.zs: 20 pellets on the
// main double-barrel fire (dmg anchor 5), 7 pellets on a single-barrel
// alt-fire (also dmg anchor 5), sprites SHT2 (main)/SHTG (alt-fire uses
// the single Shotgun's sprite)/SHT4 (flash)/SGN2 (spawn). Real sounds:
// wpn/shotgun2 (main), wpn/shotgun1 (alt). Real puffs: vrssgpuff (main),
// vrshotpuff (alt). Reload uses real built-in GZDoom SSG actions
// (A_OpenShotgun2/A_LoadShotgun2/A_CloseShotgun2), not custom sounds --
// that's what the real file does, reused directly rather than guessed.
// Alt-fire (single barrel) not built yet -- main double-barrel only.
// =====================================================================
class VR_SuperShotgun : RS_Weapon
{
	Default
	{
		Tag "Both Barrels";
		Weapon.SelectionOrder 1848;
		Weapon.SlotNumber 2;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 4;
		Weapon.AmmoType1 "VR_Shell";
		Weapon.AmmoType2 "VR_SSGLoaded";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_SuperShotgun; }

	override string GetBaseKeywords()
	{
		return "archetype:supershotgun trigger:semiauto delivery:bullet payload:multi feed:atomic-fill reserve:shell element:kinetic set:radiantsilvergun";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(5, 12); // real anchor, per pellet
				Accuracy      = RS_Roll.RollDouble(45, 55);
				Velocity      = RS_Roll.RollDouble(4000, 6000);
				CritChance    = RS_Roll.RollDouble(0.01, 0.02);
				Capacity      = 2; // real: both barrels, 2-shell chamber
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(6, 15);
				Accuracy      = RS_Roll.RollDouble(47, 57);
				Velocity      = RS_Roll.RollDouble(4000, 6000);
				CritChance    = RS_Roll.RollDouble(0.012, 0.025);
				Capacity      = 2;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(8, 18);
				Accuracy      = RS_Roll.RollDouble(49, 59);
				Velocity      = RS_Roll.RollDouble(4000, 6000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.03);
				Capacity      = 2;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(10, 21);
				Accuracy      = RS_Roll.RollDouble(51, 61);
				Velocity      = RS_Roll.RollDouble(4000, 6500);
				CritChance    = RS_Roll.RollDouble(0.016, 0.035);
				Capacity      = 2;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(13, 24);
				Accuracy      = RS_Roll.RollDouble(53, 63);
				Velocity      = RS_Roll.RollDouble(4000, 7000);
				CritChance    = RS_Roll.RollDouble(0.018, 0.04);
				Capacity      = 2;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(16, 27);
				Accuracy      = RS_Roll.RollDouble(55, 65);
				Velocity      = RS_Roll.RollDouble(4000, 7500);
				CritChance    = RS_Roll.RollDouble(0.02, 0.045);
				Capacity      = 2;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(15, 22);
					CritChance    = RS_Roll.RollDouble(0.04, 0.06);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(3, 8);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(35, 48);
				Velocity = RS_Roll.RollDouble(3500, 5500);
				Capacity = 2;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(9, 17);
				Accuracy      = RS_Roll.RollDouble(40, 55);
				Velocity      = RS_Roll.RollDouble(4000, 6500);
				CritChance    = RS_Roll.RollDouble(0.03, 0.05);
				Capacity      = 2;
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

		RateOfFire       = 1;   // real cadence, fixed
		ReloadSpeed       = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		CritMult          = RS_Roll.RollDouble(1.4 + idx * 0.15, 1.6 + idx * 0.4);
		PelletCount       = 20; // real pellet count, both barrels together
		Choke             = RS_Roll.RollDouble(0.3, 0.5);
		GunBonaiSockets   = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(RS_Roll.STARTING_CONDITION_MIN, 100);

		bStatsRolled = true;
	}

	// Both barrels together -- ammoCost 2, consumed on a backfire too
	// (the dispatch spends before it branches, same as the old code did).
	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_SuperShotgun(),
			spreadScale: 0.1,
			usesCadence: true,
			ammoCost: 2,
			casing: RS_Catalog.CASING_Shell(),
			usesChoke: true,
			profName: "Both Barrels"));
	}

	// Break-action reload: refills both chamber slots at once from VR_Shell.
	States
	{
	Spawn:
		SGN2 A -1;
		Stop;

	Ready:
		SHT2 A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		SHT2 A 1 A_Lower;
		Loop;

	Select:
		SHT2 A 1 A_Raise;
		Loop;

	// Fires both barrels together -- needs a full 2-shell chamber.
	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= 2, "Shoot");
		Goto Reload;

	Shoot:
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		SHT2 A 2;
		SHT2 BCDEFGH 2;
		Goto Reload;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("VR_Shell") <= 0, "Ready");
		Goto DoReload;

	// Real exact break-action frame sequence.
	DoReload:
		SHT2 I 2 A_OpenShotgun2();
		SHT2 JKLMNOPQR 3;
		SHT2 S 2 A_LoadShotgun2();
		SHT2 TUV 3 A_RS_ReloadAtomic();
		SHT2 X 2 A_CloseShotgun2();
		SHT2 Y 2;
		SHT2 Y 1;
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		SHT4 AB 1 Bright A_Light2();
		SHT4 CD 1 Bright A_Light1();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class VR_SuperShotgun2 : VR_SuperShotgun
{
	Default
	{
		Tag "Double Tap";
		Weapon.SelectionOrder 1847;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_SSGLoaded2";
	}
}

class VR_SuperShotgun3 : VR_SuperShotgun
{
	Default
	{
		Tag "No Refunds";
		Weapon.SelectionOrder 1846;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_SSGLoaded3";
	}
}

class VR_SuperShotgun4 : VR_SuperShotgun
{
	Default
	{
		Tag "Final Notice";
		Weapon.SelectionOrder 1845;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_SSGLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_SuperShotgun5 : VR_SuperShotgun
{
	Default
	{
		Tag "Last Word";
		Weapon.SelectionOrder 1844;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_SSGLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_SuperShotgun6 : VR_SuperShotgun
{
	Default
	{
		Tag "Full Stop";
		Weapon.SelectionOrder 1843;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_SSGLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
