// RS_PS_Machinegun -- MeatGrinder set, the TEC-9.
// ---------------------------------------------------------------------
// Source: Machinegun (sprites MGNG A-C / MGNF A-B, TEC9 model). Slot 2,
// full-auto, fires a real travelling round (not hitscan). Source anchor:
// Bullet1 damage 20 flat -- Basic tier centres on that.
//
// Feed is POOL, not atomic-fill: MeatGrinder has no reload mechanic at
// all, so giving this one would be inventing a beat the source never had.
// =====================================================================
class RS_PS_Machinegun : RS_Weapon
{
	Default
	{
		Tag "TEC-9";
		Weapon.SelectionOrder 1900;
		Weapon.SlotNumber 2;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Clip";
		Inventory.Icon "MGNGA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_SMG; }

	override string GetBaseKeywords()
	{
		return "archetype:smg trigger:fullauto delivery:bullet payload:single feed:pool reserve:clip element:kinetic promotion:pellet set:meatgrinder";
	}

	override void BuildAttackProfiles()
	{
		let primary = RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_PS_Machinegun(),
			spreadScale: 0.05,
			usesCadence: false,
			ammoCost: 1,
			casing: RS_Catalog.CASING_PS_Rifle(),
			bigMuzzle: true,
			proj: RS_Catalog.PROJ_Ballistic2(),
			profName: "Spray");
		primary.AmmoClass = "Clip";
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
				Accuracy = RS_Roll.RollDouble(60, 70);
				Velocity = RS_Roll.RollDouble(6500, 8500);
				CritChance = RS_Roll.RollDouble(0.010, 0.020);
				Capacity = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(19, 29);
				Accuracy = RS_Roll.RollDouble(62, 72);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.014, 0.027);
				Capacity = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(23, 34);
				Accuracy = RS_Roll.RollDouble(64, 74);
				Velocity = RS_Roll.RollDouble(6500, 9500);
				CritChance = RS_Roll.RollDouble(0.018, 0.034);
				Capacity = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(26, 39);
				Accuracy = RS_Roll.RollDouble(66, 76);
				Velocity = RS_Roll.RollDouble(6500, 10000);
				CritChance = RS_Roll.RollDouble(0.022, 0.041);
				Capacity = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(30, 44);
				Accuracy = RS_Roll.RollDouble(68, 78);
				Velocity = RS_Roll.RollDouble(6500, 10500);
				CritChance = RS_Roll.RollDouble(0.026, 0.048);
				Capacity = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(34, 50);
				Accuracy = RS_Roll.RollDouble(70, 80);
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
				Accuracy = RS_Roll.RollDouble(50, 62);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(21, 30);
				Accuracy = RS_Roll.RollDouble(54, 66);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.030, 0.050);
				Capacity = 0;
				break;
		}

		if (t == VRT_Cursed)
		{
			LockedDamage = true;
			LockedCritChance = true;
		}
		else
		{
			LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false;
		}

		RateOfFire = 10;
		ReloadSpeed = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		CritMult          = RS_Roll.RollDouble(1.4 + idx * 0.15, 1.6 + idx * 0.4);
		PelletCount = 1;
		Choke = RS_Roll.RollDouble(0.2 + idx * 0.03, 0.4 + idx * 0.04);
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(1, 100);

		bStatsRolled = true;
	}

	States
	{
	Spawn:
		WPPI A -1;
		Stop;

	Ready:
		MGNG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		MGNG A 1 A_Lower;
		Loop;

	Select:
		MGNG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") > 0, "Shoot");
		Goto OutOfAmmo;

	// Source cadence: MGNF A, MGNG BCA, MGNF B, MGNG BCA -- two rounds
	// per cycle. Kept as one A_RS_FireSlot per visible muzzle frame.
	Shoot:
		MGNF A 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		MGNG B 1;
		MGNG C 1;
		MGNG A 1;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		MGNF A 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_PS_Machinegun2 : RS_PS_Machinegun
{
	Default { Tag "TEC-9 II"; Weapon.SelectionOrder 1899; }
}

class RS_PS_Machinegun3 : RS_PS_Machinegun
{
	Default { Tag "TEC-9 III"; Weapon.SelectionOrder 1898; }
}

class RS_PS_Machinegun4 : RS_PS_Machinegun
{
	Default { Tag "TEC-9 IV"; Weapon.SelectionOrder 1897; +WEAPON.OFFHANDWEAPON; }
}

class RS_PS_Machinegun5 : RS_PS_Machinegun
{
	Default { Tag "TEC-9 V"; Weapon.SelectionOrder 1896; +WEAPON.OFFHANDWEAPON; }
}

class RS_PS_Machinegun6 : RS_PS_Machinegun
{
	Default { Tag "TEC-9 VI"; Weapon.SelectionOrder 1895; +WEAPON.OFFHANDWEAPON; }
}
