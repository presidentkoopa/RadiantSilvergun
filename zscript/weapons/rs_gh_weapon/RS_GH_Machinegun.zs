// RS_GH_Machinegun -- GunstarHeroes set, imported from HF_HB_Machinegun.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBMG), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 4, ballistic, 1 pellet(s), 4.0 degree cone,
// fireDelay 3 (~11 shots/sec).
//
// NOT taken: HF_Weapon's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_Machinegun : RS_Weapon
{
	Default
	{
		Tag "Gunstar Machine Gun";
		Weapon.SelectionOrder 1520;
		Weapon.SlotNumber 4;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Clip";
		Inventory.Icon "HBMGA0";
		Scale 0.7;
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_Machinegun(),
			spreadScale: 0.05,
			usesCadence: false,
			ammoCost: 1,
			casing: "RS_CasingRifle",
			ammo: "Clip",
			bigMuzzle: true,
			proj: RS_Catalog.PROJ_Ballistic(),
			profName: "Gunstar Machine Gun"));
	}

	// Source anchor: 20-20 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH Machinegun is a rolled weapon
	// like everything else instead of a fixed statline.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(16, 24);
				Accuracy      = RS_Roll.RollDouble(60, 70);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.010, 0.020);
				Capacity      = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(19, 29);
				Accuracy      = RS_Roll.RollDouble(62, 72);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(23, 34);
				Accuracy      = RS_Roll.RollDouble(64, 74);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(26, 39);
				Accuracy      = RS_Roll.RollDouble(66, 76);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(30, 44);
				Accuracy      = RS_Roll.RollDouble(68, 78);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(34, 50);
				Accuracy      = RS_Roll.RollDouble(70, 80);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 0;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(28, 38);
					CritChance    = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(9, 15);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(50, 62);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(21, 30);
				Accuracy      = RS_Roll.RollDouble(54, 66);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.050);
				Capacity      = 0;
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

		RateOfFire      = 11;
		ReloadSpeed     = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		PelletCount     = 1;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(1, 100);

		bStatsRolled = true;
	}

	override void ApplyUpgradeCard(EVR_Tier newTier)
	{
		bool isSacrificeDowngrade = (Tier == VRT_Prototype && newTier == VRT_Basic);
		RollStats(newTier);
		if (isSacrificeDowngrade)
			PelletCount += 1;
	}

	States
	{
	Spawn:
		HBMG A -1;
		Stop;

	Ready:
		HBMG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		HBMG A 1 A_Lower;
		Loop;

	Select:
		HBMG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") > 0, "Shoot");
		Goto OutOfAmmo;

	Shoot:
		HBMG B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBMG C 2;
		HBMG D 2;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBMG B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_Machinegun2 : RS_GH_Machinegun
{
	Default
	{
		Tag "Gunstar Machine Gun II";
		Weapon.SelectionOrder 1519;
	}
}

class RS_GH_Machinegun3 : RS_GH_Machinegun
{
	Default
	{
		Tag "Gunstar Machine Gun III";
		Weapon.SelectionOrder 1518;
	}
}

class RS_GH_Machinegun4 : RS_GH_Machinegun
{
	Default
	{
		Tag "Gunstar Machine Gun IV";
		Weapon.SelectionOrder 1517;
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Machinegun5 : RS_GH_Machinegun
{
	Default
	{
		Tag "Gunstar Machine Gun V";
		Weapon.SelectionOrder 1516;
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Machinegun6 : RS_GH_Machinegun
{
	Default
	{
		Tag "Gunstar Machine Gun VI";
		Weapon.SelectionOrder 1515;
		+WEAPON.OFFHANDWEAPON;
	}
}
