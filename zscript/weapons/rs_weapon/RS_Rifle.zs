// VR_Rifle -- the Rifle weapon type.
// ---------------------------------------------------------------------
// Real data: dmg anchor 8-16, magazine 20, reload frames RIFL L-N/O-Y +
// RIFK A-I/J-L/M-O exactly. Real sounds: m16shoot fire; the old file
// itself reused the pistol's 9mmclip1/9mmclip2/9mmslide for rifle
// reload, so that's not an invention here, it's sourced. True
// semi-auto: release gate + accuracy penalty for outpacing cadence.
// =====================================================================
class VR_Rifle : RS_Weapon
{
	Default
	{
		Tag "Etiquette";
		Weapon.SelectionOrder 1868;
		Weapon.SlotNumber 2;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 40;
		Weapon.AmmoType1 "Clip";
		Weapon.AmmoType2 "VR_RifleLoaded";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_Rifle; }

	override string GetBaseKeywords()
	{
		return "archetype:rifle trigger:semiauto trigger:fullauto delivery:bullet payload:single feed:atomic-fill reserve:clip element:kinetic promotion:pellet set:radiantsilvergun";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(8, 16);
				Accuracy      = RS_Roll.RollDouble(78, 88);
				Velocity      = RS_Roll.RollDouble(8500, 11000);
				CritChance    = RS_Roll.RollDouble(0.03, 0.06);
				Capacity      = 20;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(11, 20);
				Accuracy      = RS_Roll.RollDouble(80, 90);
				Velocity      = RS_Roll.RollDouble(8500, 11000);
				CritChance    = RS_Roll.RollDouble(0.035, 0.065);
				Capacity      = 20;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(14, 24);
				Accuracy      = RS_Roll.RollDouble(82, 92);
				Velocity      = RS_Roll.RollDouble(8500, 11000);
				CritChance    = RS_Roll.RollDouble(0.04, 0.07);
				Capacity      = 20;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(18, 28);
				Accuracy      = RS_Roll.RollDouble(84, 94);
				Velocity      = RS_Roll.RollDouble(8500, 11500);
				CritChance    = RS_Roll.RollDouble(0.045, 0.075);
				Capacity      = 20;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(22, 32);
				Accuracy      = RS_Roll.RollDouble(86, 96);
				Velocity      = RS_Roll.RollDouble(8500, 12000);
				CritChance    = RS_Roll.RollDouble(0.05, 0.08);
				Capacity      = 25;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(26, 36);
				Accuracy      = RS_Roll.RollDouble(88, 98);
				Velocity      = RS_Roll.RollDouble(8500, 12500);
				CritChance    = RS_Roll.RollDouble(0.055, 0.09);
				Capacity      = 25;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(24, 32);
					CritChance    = RS_Roll.RollDouble(0.06, 0.09);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(5, 12);
					CritChance    = RS_Roll.RollDouble(0.01, 0.03);
				}
				Accuracy = RS_Roll.RollDouble(65, 80);
				Velocity = RS_Roll.RollDouble(8000, 10500);
				Capacity = 20;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(16, 26);
				Accuracy      = RS_Roll.RollDouble(75, 90);
				Velocity      = RS_Roll.RollDouble(8500, 11500);
				CritChance    = RS_Roll.RollDouble(0.06, 0.09);
				Capacity      = 20;
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

		RateOfFire       = 3;   // real cadence, fixed
		ReloadSpeed       = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		CritMult          = RS_Roll.RollDouble(1.4 + idx * 0.15, 1.6 + idx * 0.4);
		PelletCount       = 1;
		Choke             = RS_Roll.RollDouble(0.2 + idx * 0.03, 0.4 + idx * 0.04);
		GunBonaiSockets   = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(RS_Roll.STARTING_CONDITION_MIN, 100);

		bStatsRolled = true;
	}


	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_Rifle(),
			spreadScale: 0.05,
			usesCadence: true,
			ammoCost: 1,
			casing: RS_Catalog.CASING_Rifle(),
			profName: "5.56"));
	}

	States
	{
	Spawn:
		RIFK A -1;
		Stop;

	Ready:
		RIFL A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		RIFL A 1 A_Lower;
		Loop;

	Select:
		RIFL A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		RIFL BC 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		RIFL A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	// Real exact frame sequence from the reference file.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("9mmclip1", CHAN_AUTO);
		RIFL LMN 2;
		RIFL OPQRSTUVWXY 1;
		TNT1 A 0 A_PlaySound("9mmclip2", CHAN_AUTO);
		RIFK ABCDEFGHI 2;
		RIFK JKL 1;
		TNT1 A 0 A_PlaySound("9mmslide", CHAN_AUTO);
		RIFK MNO 2 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		RIFL D 2 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class VR_Rifle2 : VR_Rifle
{
	Default
	{
		Tag "Pardon Me";
		Weapon.SelectionOrder 1867;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_RifleLoaded2";
	}
}

class VR_Rifle3 : VR_Rifle
{
	Default
	{
		Tag "Manners";
		Weapon.SelectionOrder 1866;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_RifleLoaded3";
	}
}

class VR_Rifle4 : VR_Rifle
{
	Default
	{
		Tag "Decorum";
		Weapon.SelectionOrder 1865;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_RifleLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_Rifle5 : VR_Rifle
{
	Default
	{
		Tag "Propriety";
		Weapon.SelectionOrder 1864;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_RifleLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_Rifle6 : VR_Rifle
{
	Default
	{
		Tag "Civility";
		Weapon.SelectionOrder 1863;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_RifleLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
