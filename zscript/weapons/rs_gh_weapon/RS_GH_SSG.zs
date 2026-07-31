// RS_GH_SSG -- GunstarHeroes set, imported from HF_HB_SSG.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBSS + SHTZ), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 3, ballistic, 20 pellet(s), 11.0 degree cone,
// fireDelay 20 (~1 shots/sec).
//
// NOT taken: HF_Weapon's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_SSG : RS_Weapon
{
	Default
	{
		Tag "Gunstar Double Barrel";
		Weapon.SelectionOrder 1680;
		Weapon.SlotNumber 3;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Shell";
		Weapon.AmmoType2 "RS_GH_SSGLoaded";
		Inventory.Icon "HBSSA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_SSG(),
			spreadScale: 0.1,
			usesCadence: true,
			ammoCost: 1,
			casing: "RS_CasingShell",
			bigMuzzle: false,
			proj: RS_Catalog.PROJ_Ballistic(),
			profName: "Gunstar Double Barrel"));
	}

	// Source anchor: 13-13 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH SSG is a rolled weapon
	// like everything else instead of a fixed statline.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(10, 15);
				Accuracy      = RS_Roll.RollDouble(40, 50);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.010, 0.020);
				Capacity      = 2;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(12, 18);
				Accuracy      = RS_Roll.RollDouble(42, 52);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 2;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(15, 22);
				Accuracy      = RS_Roll.RollDouble(44, 54);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 2;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(17, 25);
				Accuracy      = RS_Roll.RollDouble(46, 56);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 2;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(19, 29);
				Accuracy      = RS_Roll.RollDouble(48, 58);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 2;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(22, 32);
				Accuracy      = RS_Roll.RollDouble(50, 60);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 2;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(18, 24);
					CritChance    = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(5, 9);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(30, 42);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 2;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(13, 19);
				Accuracy      = RS_Roll.RollDouble(34, 46);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.050);
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

		RateOfFire      = 1;
		ReloadSpeed     = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		PelletCount     = 20;
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
		HBSS A -1;
		Stop;

	Ready:
		HBSS A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		HBSS A 1 A_Lower;
		Loop;

	Select:
		HBSS A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		HBSS B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBSS C 2;
		HBSS D 2;
		HBSS A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Shell") <= 0, "OutOfAmmo");
		SHTZ ABCDEFGHIJKLMNOPQRSTUVWXYZ 1;
		TNT1 A 0 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBSS B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_SSG2 : RS_GH_SSG
{
	Default
	{
		Tag "Gunstar Double Barrel II";
		Weapon.SelectionOrder 1679;
		Weapon.AmmoType2 "RS_GH_SSGLoaded2";
	}
}

class RS_GH_SSG3 : RS_GH_SSG
{
	Default
	{
		Tag "Gunstar Double Barrel III";
		Weapon.SelectionOrder 1678;
		Weapon.AmmoType2 "RS_GH_SSGLoaded3";
	}
}

class RS_GH_SSG4 : RS_GH_SSG
{
	Default
	{
		Tag "Gunstar Double Barrel IV";
		Weapon.SelectionOrder 1677;
		Weapon.AmmoType2 "RS_GH_SSGLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_SSG5 : RS_GH_SSG
{
	Default
	{
		Tag "Gunstar Double Barrel V";
		Weapon.SelectionOrder 1676;
		Weapon.AmmoType2 "RS_GH_SSGLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_SSG6 : RS_GH_SSG
{
	Default
	{
		Tag "Gunstar Double Barrel VI";
		Weapon.SelectionOrder 1675;
		Weapon.AmmoType2 "RS_GH_SSGLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
