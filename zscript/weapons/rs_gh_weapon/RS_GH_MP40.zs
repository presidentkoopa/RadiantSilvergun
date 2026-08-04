// RS_GH_MP40 -- GunstarHeroes set, imported from the source arsenal pack.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBMP + MP4R), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 4, ballistic, 1 pellet(s), 3.0 degree cone,
// fireDelay 4 (~8 shots/sec).
//
// NOT taken: the source pack's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_MP40 : RS_Weapon
{
	Default
	{
		Tag "Gunstar MP40";
		Weapon.SelectionOrder 1610;
		Weapon.SlotNumber 4;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Clip";
		Weapon.AmmoType2 "RS_GH_MP40Loaded";
		Inventory.Icon "HBMPA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override string GetBaseKeywords()
	{
		return "archetype:smg trigger:fullauto delivery:bullet payload:single feed:atomic-fill reserve:clip element:kinetic promotion:pellet set:gunstarheroes";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_MP40(),
			spreadScale: 0.05,
			usesCadence: false,
			ammoCost: 1,
			casing: "RS_CasingSmall",
			bigMuzzle: true,
			proj: RS_Catalog.PROJ_Ballistic(),
			profName: "Gunstar MP40"));
	}

	// Source anchor: 15-15 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH MP40 is a rolled weapon
	// like everything else instead of a fixed statline.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(12, 18);
				Accuracy      = RS_Roll.RollDouble(63, 73);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.010, 0.020);
				Capacity      = 32;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(14, 21);
				Accuracy      = RS_Roll.RollDouble(65, 75);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 32;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(17, 25);
				Accuracy      = RS_Roll.RollDouble(67, 77);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 32;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(20, 29);
				Accuracy      = RS_Roll.RollDouble(69, 79);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 32;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(22, 33);
				Accuracy      = RS_Roll.RollDouble(71, 81);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 32;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(25, 37);
				Accuracy      = RS_Roll.RollDouble(73, 83);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 32;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(21, 28);
					CritChance    = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(6, 11);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(53, 65);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 32;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(15, 22);
				Accuracy      = RS_Roll.RollDouble(57, 69);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.050);
				Capacity      = 32;
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

		RateOfFire      = 8;
		ReloadSpeed     = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		PelletCount     = 1;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(1, 100);

		bStatsRolled = true;
	}


	States
	{
	Spawn:
		HBMP A -1;
		Stop;

	Ready:
		HBMP A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		HBMP A 1 A_Lower;
		Loop;

	Select:
		HBMP A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		HBMP B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBMP C 2;
		HBMP D 2;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		MP4R ABCDEFG 1;
		TNT1 A 0 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBMP B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_MP402 : RS_GH_MP40
{
	Default
	{
		Tag "Gunstar MP40 II";
		Weapon.SelectionOrder 1609;
		Weapon.AmmoType2 "RS_GH_MP40Loaded2";
	}
}

class RS_GH_MP403 : RS_GH_MP40
{
	Default
	{
		Tag "Gunstar MP40 III";
		Weapon.SelectionOrder 1608;
		Weapon.AmmoType2 "RS_GH_MP40Loaded3";
	}
}

class RS_GH_MP404 : RS_GH_MP40
{
	Default
	{
		Tag "Gunstar MP40 IV";
		Weapon.SelectionOrder 1607;
		Weapon.AmmoType2 "RS_GH_MP40Loaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_MP405 : RS_GH_MP40
{
	Default
	{
		Tag "Gunstar MP40 V";
		Weapon.SelectionOrder 1606;
		Weapon.AmmoType2 "RS_GH_MP40Loaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_MP406 : RS_GH_MP40
{
	Default
	{
		Tag "Gunstar MP40 VI";
		Weapon.SelectionOrder 1605;
		Weapon.AmmoType2 "RS_GH_MP40Loaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
