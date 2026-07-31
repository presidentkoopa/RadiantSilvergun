// RS_GH_Pistol -- GunstarHeroes set, imported from HF_HB_Pistol.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBPS + PISR), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 2, ballistic, 1 pellet(s), 1.0 degree cone,
// fireDelay 6 (~5 shots/sec).
//
// NOT taken: HF_Weapon's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_Pistol : RS_Weapon
{
	Default
	{
		Tag "Gunstar Sidearm";
		Weapon.SelectionOrder 1900;
		Weapon.SlotNumber 2;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Clip";
		Weapon.AmmoType2 "RS_GH_PistolLoaded";
		Inventory.Icon "HBPSA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_Pistol(),
			spreadScale: 0.05,
			usesCadence: true,
			ammoCost: 1,
			casing: "RS_CasingSmall",
			bigMuzzle: false,
			proj: RS_Catalog.PROJ_Ballistic(),
			profName: "Gunstar Sidearm"));
	}

	// Source anchor: 14-14 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH Pistol is a rolled weapon
	// like everything else instead of a fixed statline.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(11, 16);
				Accuracy      = RS_Roll.RollDouble(69, 79);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.010, 0.020);
				Capacity      = 16;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(13, 20);
				Accuracy      = RS_Roll.RollDouble(71, 81);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 16;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(16, 24);
				Accuracy      = RS_Roll.RollDouble(73, 83);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 16;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(18, 27);
				Accuracy      = RS_Roll.RollDouble(75, 85);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 16;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(21, 31);
				Accuracy      = RS_Roll.RollDouble(77, 87);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 16;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(23, 35);
				Accuracy      = RS_Roll.RollDouble(79, 89);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 16;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(19, 26);
					CritChance    = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(6, 10);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(59, 71);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 16;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(14, 21);
				Accuracy      = RS_Roll.RollDouble(63, 75);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.050);
				Capacity      = 16;
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
		HBPS A -1;
		Stop;

	Ready:
		HBPS A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		HBPS A 1 A_Lower;
		Loop;

	Select:
		HBPS A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		HBPS B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBPS C 2;
		HBPS D 2;
		HBPS A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		PISR ABCDEFGHIJKLMNOPQR 1;
		TNT1 A 0 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBPS B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_Pistol2 : RS_GH_Pistol
{
	Default
	{
		Tag "Gunstar Sidearm II";
		Weapon.SelectionOrder 1899;
		Weapon.AmmoType2 "RS_GH_PistolLoaded2";
	}
}

class RS_GH_Pistol3 : RS_GH_Pistol
{
	Default
	{
		Tag "Gunstar Sidearm III";
		Weapon.SelectionOrder 1898;
		Weapon.AmmoType2 "RS_GH_PistolLoaded3";
	}
}

class RS_GH_Pistol4 : RS_GH_Pistol
{
	Default
	{
		Tag "Gunstar Sidearm IV";
		Weapon.SelectionOrder 1897;
		Weapon.AmmoType2 "RS_GH_PistolLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Pistol5 : RS_GH_Pistol
{
	Default
	{
		Tag "Gunstar Sidearm V";
		Weapon.SelectionOrder 1896;
		Weapon.AmmoType2 "RS_GH_PistolLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Pistol6 : RS_GH_Pistol
{
	Default
	{
		Tag "Gunstar Sidearm VI";
		Weapon.SelectionOrder 1895;
		Weapon.AmmoType2 "RS_GH_PistolLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
