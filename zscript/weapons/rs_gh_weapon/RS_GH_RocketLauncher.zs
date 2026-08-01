// RS_GH_RocketLauncher -- GunstarHeroes set, imported from HF_HB_RocketLauncher.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBRL + MISR), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 5, projectile, 1 pellet(s), 1.0 degree cone,
// fireDelay 9 (~3 shots/sec).
//
// NOT taken: HF_Weapon's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_RocketLauncher : RS_Weapon
{
	Default
	{
		Tag "Gunstar Rocket Launcher";
		Weapon.SelectionOrder 1300;
		Weapon.SlotNumber 5;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "RocketAmmo";
		Weapon.AmmoType2 "RS_GH_RocketLauncherLoaded";
		Inventory.Icon "HBRLA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override string GetBaseKeywords()
	{
		return "archetype:launcher trigger:semiauto delivery:heavy payload:single feed:atomic-fill reserve:rocket element:kinetic promotion:pellet set:gunstarheroes";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeHeavy(
			proj: "RS_EnhancedRocket",
			fireSnd: RS_Catalog.SND_GH_RocketLauncher(),
			ammoCost: 1,
			bigMuzzle: true,
			profName: "Gunstar Rocket Launcher"));
	}

	// Source anchor: 10-10 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH RocketLauncher is a rolled weapon
	// like everything else instead of a fixed statline.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(8, 12);
				Accuracy      = RS_Roll.RollDouble(69, 79);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.010, 0.020);
				Capacity      = 6;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(9, 14);
				Accuracy      = RS_Roll.RollDouble(71, 81);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 6;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(11, 17);
				Accuracy      = RS_Roll.RollDouble(73, 83);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 6;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(13, 19);
				Accuracy      = RS_Roll.RollDouble(75, 85);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 6;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(15, 22);
				Accuracy      = RS_Roll.RollDouble(77, 87);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 6;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(17, 25);
				Accuracy      = RS_Roll.RollDouble(79, 89);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 6;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(14, 19);
					CritChance    = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(4, 7);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(59, 71);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 6;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(10, 15);
				Accuracy      = RS_Roll.RollDouble(63, 75);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.050);
				Capacity      = 6;
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

		RateOfFire      = 3;
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
		HBRL A -1;
		Stop;

	Ready:
		HBRL A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		HBRL A 1 A_Lower;
		Loop;

	Select:
		HBRL A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		HBRL B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBRL C 2;
		HBRL D 2;
		HBRL A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("RocketAmmo") <= 0, "OutOfAmmo");
		MISR ABCDEFGHIJKLMNOPQR 1;
		TNT1 A 0 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBRL B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_RocketLauncher2 : RS_GH_RocketLauncher
{
	Default
	{
		Tag "Gunstar Rocket Launcher II";
		Weapon.SelectionOrder 1299;
		Weapon.AmmoType2 "RS_GH_RocketLauncherLoaded2";
	}
}

class RS_GH_RocketLauncher3 : RS_GH_RocketLauncher
{
	Default
	{
		Tag "Gunstar Rocket Launcher III";
		Weapon.SelectionOrder 1298;
		Weapon.AmmoType2 "RS_GH_RocketLauncherLoaded3";
	}
}

class RS_GH_RocketLauncher4 : RS_GH_RocketLauncher
{
	Default
	{
		Tag "Gunstar Rocket Launcher IV";
		Weapon.SelectionOrder 1297;
		Weapon.AmmoType2 "RS_GH_RocketLauncherLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_RocketLauncher5 : RS_GH_RocketLauncher
{
	Default
	{
		Tag "Gunstar Rocket Launcher V";
		Weapon.SelectionOrder 1296;
		Weapon.AmmoType2 "RS_GH_RocketLauncherLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_RocketLauncher6 : RS_GH_RocketLauncher
{
	Default
	{
		Tag "Gunstar Rocket Launcher VI";
		Weapon.SelectionOrder 1295;
		Weapon.AmmoType2 "RS_GH_RocketLauncherLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
