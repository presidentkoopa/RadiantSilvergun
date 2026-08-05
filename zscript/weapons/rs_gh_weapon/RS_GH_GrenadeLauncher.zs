// RS_GH_GrenadeLauncher -- GunstarHeroes set, imported from the source arsenal pack.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBGL + GLR1), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 5, projectile, 1 pellet(s), 1.0 degree cone,
// fireDelay 14 (~2 shots/sec).
//
// NOT taken: the source pack's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_GrenadeLauncher : RS_Weapon
{
	Default
	{
		Tag "Gunstar Grenade Launcher";
		Weapon.SelectionOrder 1320;
		Weapon.SlotNumber 5;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "RocketAmmo";
		Weapon.AmmoType2 "RS_GH_GrenadeLauncherLoaded";
		Inventory.Icon "HBGLA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override string GetBaseKeywords()
	{
		return "archetype:launcher trigger:semiauto delivery:heavy payload:single feed:atomic-fill reserve:rocket element:explosive promotion:pellet set:gunstarheroes";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeHeavy(
			proj: "RS_GH_GrenadeLaunched",
			fireSnd: RS_Catalog.SND_GH_GrenadeLauncher(),
			ammoCost: 1,
			bigMuzzle: true,
			profName: "Arc Lob"));
	}

	// Source anchor: 10-10 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH GrenadeLauncher is a rolled weapon
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
				Capacity      = 1;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(9, 14);
				Accuracy      = RS_Roll.RollDouble(71, 81);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 1;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(11, 17);
				Accuracy      = RS_Roll.RollDouble(73, 83);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 1;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(13, 19);
				Accuracy      = RS_Roll.RollDouble(75, 85);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 1;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(15, 22);
				Accuracy      = RS_Roll.RollDouble(77, 87);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 1;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(17, 25);
				Accuracy      = RS_Roll.RollDouble(79, 89);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 1;
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
				Capacity = 1;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(10, 15);
				Accuracy      = RS_Roll.RollDouble(63, 75);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.050);
				Capacity      = 1;
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

		RateOfFire      = 2;
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
		HBGL A -1;
		Stop;

	Ready:
		HBGL A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		HBGL A 1 A_Lower;
		Loop;

	Select:
		HBGL A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		HBGL B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBGL C 2;
		HBGL D 2;
		HBGL A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("RocketAmmo") <= 0, "OutOfAmmo");
		GLR1 ABCDEFGHIJKLMNOPQRSTUVWXYZ 1;
		TNT1 A 0 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBGL B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_GrenadeLauncher2 : RS_GH_GrenadeLauncher
{
	Default
	{
		Tag "Gunstar Grenade Launcher II";
		Weapon.SelectionOrder 1319;
		Weapon.AmmoType2 "RS_GH_GrenadeLauncherLoaded2";
	}
}

class RS_GH_GrenadeLauncher3 : RS_GH_GrenadeLauncher
{
	Default
	{
		Tag "Gunstar Grenade Launcher III";
		Weapon.SelectionOrder 1318;
		Weapon.AmmoType2 "RS_GH_GrenadeLauncherLoaded3";
	}
}

class RS_GH_GrenadeLauncher4 : RS_GH_GrenadeLauncher
{
	Default
	{
		Tag "Gunstar Grenade Launcher IV";
		Weapon.SelectionOrder 1317;
		Weapon.AmmoType2 "RS_GH_GrenadeLauncherLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_GrenadeLauncher5 : RS_GH_GrenadeLauncher
{
	Default
	{
		Tag "Gunstar Grenade Launcher V";
		Weapon.SelectionOrder 1316;
		Weapon.AmmoType2 "RS_GH_GrenadeLauncherLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_GrenadeLauncher6 : RS_GH_GrenadeLauncher
{
	Default
	{
		Tag "Gunstar Grenade Launcher VI";
		Weapon.SelectionOrder 1315;
		Weapon.AmmoType2 "RS_GH_GrenadeLauncherLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
