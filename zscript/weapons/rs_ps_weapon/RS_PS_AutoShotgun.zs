// RS_PS_AutoShotgun -- MeatGrinder set. Source: AutoShotgun (SHTG A-D,
// Shotgun model). Slot 3, full-auto. Source fires 4 spread rounds plus 1
// centred round = 5 pellets, Bullet2 damage 20 each.
// =====================================================================
class RS_PS_AutoShotgun : RS_Weapon
{
	Default
	{
		Tag "Grinder Auto-Shotgun";
		Weapon.SelectionOrder 1690;
		Weapon.SlotNumber 3;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Shell";
		Inventory.Icon "WPPIC0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_Shotgun; }

	override string GetBaseKeywords()
	{
		return "archetype:shotgun trigger:fullauto delivery:bullet payload:multi feed:pool reserve:shell element:kinetic promotion:pellet set:meatgrinder";
	}

	override void BuildAttackProfiles()
	{
		let primary = RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_PS_AutoShotgun(),
			spreadScale: 0.1,
			usesCadence: false,
			ammoCost: 1,
			casing: RS_Catalog.CASING_PS_Shell(),
			bigMuzzle: true,
			proj: RS_Catalog.PROJ_Ballistic2(),
			profName: "Auto Buck");
		primary.AmmoClass = "Shell";
		primary.ImpactPuff = RS_Catalog.PUFF_PS_Hit();
		PrimarySlot.Append(primary);
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(16, 24);
				Accuracy = RS_Roll.RollDouble(54, 64);
				Velocity = RS_Roll.RollDouble(6500, 8500);
				CritChance = RS_Roll.RollDouble(0.010, 0.020);
				Capacity = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(19, 29);
				Accuracy = RS_Roll.RollDouble(56, 66);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.014, 0.027);
				Capacity = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(23, 34);
				Accuracy = RS_Roll.RollDouble(58, 68);
				Velocity = RS_Roll.RollDouble(6500, 9500);
				CritChance = RS_Roll.RollDouble(0.018, 0.034);
				Capacity = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(26, 39);
				Accuracy = RS_Roll.RollDouble(60, 70);
				Velocity = RS_Roll.RollDouble(6500, 10000);
				CritChance = RS_Roll.RollDouble(0.022, 0.041);
				Capacity = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(30, 44);
				Accuracy = RS_Roll.RollDouble(62, 72);
				Velocity = RS_Roll.RollDouble(6500, 10500);
				CritChance = RS_Roll.RollDouble(0.026, 0.048);
				Capacity = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(34, 50);
				Accuracy = RS_Roll.RollDouble(64, 74);
				Velocity = RS_Roll.RollDouble(6500, 11000);
				CritChance = RS_Roll.RollDouble(0.030, 0.055);
				Capacity = 0;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(28, 38);
					CritChance = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(9, 15);
					CritChance = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(44, 56);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(21, 30);
				Accuracy = RS_Roll.RollDouble(48, 60);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.030, 0.050);
				Capacity = 0;
				break;
		}

		if (t == VRT_Cursed) { LockedDamage = true; LockedCritChance = true; }
		else { LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false; }

		RateOfFire = 5;
		ReloadSpeed = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		CritMult          = RS_Roll.RollDouble(1.4 + idx * 0.15, 1.6 + idx * 0.4);
		PelletCount = 5;
		Choke = RS_Roll.RollDouble(0.2 + idx * 0.03, 0.4 + idx * 0.04);
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled) Condition = RS_Roll.RollDouble(RS_Roll.STARTING_CONDITION_MIN, 100);
		bStatsRolled = true;
	}

	States
	{
	Spawn:
		WPPI C -1;
		Stop;

	Ready:
		SHTG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		SHTG A 1 A_Lower;
		Loop;

	Select:
		SHTG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Shell") > 0, "Shoot");
		Goto OutOfAmmo;

	Shoot:
		SHTG B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		SHTG C 2;
		SHTG D 2;
		SHTG A 2;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		SSGF A 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_PS_AutoShotgun2 : RS_PS_AutoShotgun
{ Default { Tag "Grinder Auto-Shotgun II"; Weapon.SelectionOrder 1689; } }

class RS_PS_AutoShotgun3 : RS_PS_AutoShotgun
{ Default { Tag "Grinder Auto-Shotgun III"; Weapon.SelectionOrder 1688; } }

class RS_PS_AutoShotgun4 : RS_PS_AutoShotgun
{ Default { Tag "Grinder Auto-Shotgun IV"; Weapon.SelectionOrder 1687; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_AutoShotgun5 : RS_PS_AutoShotgun
{ Default { Tag "Grinder Auto-Shotgun V"; Weapon.SelectionOrder 1686; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_AutoShotgun6 : RS_PS_AutoShotgun
{ Default { Tag "Grinder Auto-Shotgun VI"; Weapon.SelectionOrder 1685; +WEAPON.OFFHANDWEAPON; } }
