// RS_GH_AssaultShotgun -- GunstarHeroes set, imported from the source arsenal pack.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBAG + A12R), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 3, ballistic, 14 pellet(s), 6.0 degree cone,
// fireDelay 6 (~5 shots/sec).
//
// NOT taken: the source pack's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_AssaultShotgun : RS_Weapon
{
	Default
	{
		Tag "Gunstar Assault Shotgun";
		Weapon.SelectionOrder 1690;
		Weapon.SlotNumber 3;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Shell";
		Weapon.AmmoType2 "RS_GH_AssaultShotgunLoaded";
		Inventory.Icon "HBAGA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override string GetBaseKeywords()
	{
		return "archetype:shotgun trigger:fullauto delivery:bullet payload:multi feed:atomic-fill reserve:shell element:kinetic promotion:pellet set:gunstarheroes";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_AssaultShotgun(),
			spreadScale: 0.1,
			usesCadence: false,
			ammoCost: 1,
			casing: "RS_CasingShell",
			bigMuzzle: true,
			proj: RS_Catalog.PROJ_Ballistic(),
			profName: "Auto Buckshot"));
	}

	// Source anchor: 11-13 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH AssaultShotgun is a rolled weapon
	// like everything else instead of a fixed statline.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(9, 14);
				Accuracy      = RS_Roll.RollDouble(54, 64);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.010, 0.020);
				Capacity      = 20;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(11, 17);
				Accuracy      = RS_Roll.RollDouble(56, 66);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 20;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(13, 20);
				Accuracy      = RS_Roll.RollDouble(58, 68);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 20;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(16, 23);
				Accuracy      = RS_Roll.RollDouble(60, 70);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 20;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(18, 26);
				Accuracy      = RS_Roll.RollDouble(62, 72);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 20;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(20, 30);
				Accuracy      = RS_Roll.RollDouble(64, 74);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 20;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(16, 22);
					CritChance    = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(5, 9);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(44, 56);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 20;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(12, 18);
				Accuracy      = RS_Roll.RollDouble(48, 60);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.050);
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

		RateOfFire      = 5;
		ReloadSpeed     = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		CritMult          = RS_Roll.RollDouble(1.4 + idx * 0.15, 1.6 + idx * 0.4);
		PelletCount     = 14;
		Choke           = RS_Roll.RollDouble(0.2 + idx * 0.03, 0.4 + idx * 0.04);
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(RS_Roll.STARTING_CONDITION_MIN, 100);

		bStatsRolled = true;
	}


	States
	{
	Spawn:
		HBAG A -1;
		Stop;

	Ready:
		HBAG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		HBAG A 1 A_Lower;
		Loop;

	Select:
		HBAG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		HBAG B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBAG C 2;
		HBAG D 2;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Shell") <= 0, "OutOfAmmo");
		A12R ABCDEFGHIJKLMNOPQRSTU 1;
		TNT1 A 0 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBAG B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_AssaultShotgun2 : RS_GH_AssaultShotgun
{
	Default
	{
		Tag "Gunstar Assault Shotgun II";
		Weapon.SelectionOrder 1689;
		Weapon.AmmoType2 "RS_GH_AssaultShotgunLoaded2";
	}
}

class RS_GH_AssaultShotgun3 : RS_GH_AssaultShotgun
{
	Default
	{
		Tag "Gunstar Assault Shotgun III";
		Weapon.SelectionOrder 1688;
		Weapon.AmmoType2 "RS_GH_AssaultShotgunLoaded3";
	}
}

class RS_GH_AssaultShotgun4 : RS_GH_AssaultShotgun
{
	Default
	{
		Tag "Gunstar Assault Shotgun IV";
		Weapon.SelectionOrder 1687;
		Weapon.AmmoType2 "RS_GH_AssaultShotgunLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_AssaultShotgun5 : RS_GH_AssaultShotgun
{
	Default
	{
		Tag "Gunstar Assault Shotgun V";
		Weapon.SelectionOrder 1686;
		Weapon.AmmoType2 "RS_GH_AssaultShotgunLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_AssaultShotgun6 : RS_GH_AssaultShotgun
{
	Default
	{
		Tag "Gunstar Assault Shotgun VI";
		Weapon.SelectionOrder 1685;
		Weapon.AmmoType2 "RS_GH_AssaultShotgunLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
