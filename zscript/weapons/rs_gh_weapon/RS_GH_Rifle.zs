// RS_GH_Rifle -- GunstarHeroes set, imported from the source arsenal pack.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBRI + RIFR), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 4, ballistic, 1 pellet(s), 1.5 degree cone,
// fireDelay 4 (~8 shots/sec).
//
// NOT taken: the source pack's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_Rifle : RS_Weapon
{
	Default
	{
		Tag "Gunstar Rifle";
		Weapon.SelectionOrder 1550;
		Weapon.SlotNumber 4;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Clip";
		Weapon.AmmoType2 "RS_GH_RifleLoaded";
		Inventory.Icon "HBRIA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override string GetBaseKeywords()
	{
		return "archetype:rifle trigger:semiauto delivery:bullet payload:single feed:atomic-fill reserve:clip element:kinetic promotion:pellet set:gunstarheroes";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_Rifle(),
			spreadScale: 0.05,
			usesCadence: true,
			ammoCost: 1,
			casing: "RS_CasingRifle",
			bigMuzzle: false,
			proj: RS_Catalog.PROJ_Ballistic(),
			profName: "Aimed Shot"));

		// Source alt-fire: identical round, but full-auto instead of the
		// primary's semi-auto -- the AltFire state chain below is what
		// makes the difference, not the profile.
		SecondarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_Rifle(),
			spreadScale: 0.05,
			usesCadence: false,
			ammoCost: 1,
			casing: "RS_CasingRifle",
			bigMuzzle: false,
			proj: RS_Catalog.PROJ_Ballistic(),
			profName: "Full Auto"));
	}

	// Source anchor: 20-20 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH Rifle is a rolled weapon
	// like everything else instead of a fixed statline.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(16, 24);
				Accuracy      = RS_Roll.RollDouble(67, 77);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.010, 0.020);
				Capacity      = 31;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(19, 29);
				Accuracy      = RS_Roll.RollDouble(69, 79);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 31;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(23, 34);
				Accuracy      = RS_Roll.RollDouble(71, 81);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 31;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(26, 39);
				Accuracy      = RS_Roll.RollDouble(73, 83);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 31;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(30, 44);
				Accuracy      = RS_Roll.RollDouble(75, 85);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 31;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(34, 50);
				Accuracy      = RS_Roll.RollDouble(77, 87);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 31;
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
				Accuracy = RS_Roll.RollDouble(57, 69);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 31;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(21, 30);
				Accuracy      = RS_Roll.RollDouble(61, 73);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.050);
				Capacity      = 31;
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
		HBRI A -1;
		Stop;

	Ready:
		HBRI A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		HBRI A 1 A_Lower;
		Loop;

	Select:
		HBRI A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		HBRI B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBRI C 2;
		HBRI D 2;
		HBRI A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		RIFR ABCDEFGHIKLMNOPQRST 1;
		TNT1 A 0 A_RS_ReloadAtomic();
		Goto Ready;

	// Source alt-fire: full-auto secondary -- same round as primary, just
	// held-trigger full-auto instead of one-shot-per-pull.
	AltFire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "AltShoot");
		Goto Reload;

	AltShoot:
		HBRI B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(1);
		HBRI C 1;
		HBRI D 2 A_ReFire;
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBRI B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_Rifle2 : RS_GH_Rifle
{
	Default
	{
		Tag "Gunstar Rifle II";
		Weapon.SelectionOrder 1549;
		Weapon.AmmoType2 "RS_GH_RifleLoaded2";
	}
}

class RS_GH_Rifle3 : RS_GH_Rifle
{
	Default
	{
		Tag "Gunstar Rifle III";
		Weapon.SelectionOrder 1548;
		Weapon.AmmoType2 "RS_GH_RifleLoaded3";
	}
}

class RS_GH_Rifle4 : RS_GH_Rifle
{
	Default
	{
		Tag "Gunstar Rifle IV";
		Weapon.SelectionOrder 1547;
		Weapon.AmmoType2 "RS_GH_RifleLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Rifle5 : RS_GH_Rifle
{
	Default
	{
		Tag "Gunstar Rifle V";
		Weapon.SelectionOrder 1546;
		Weapon.AmmoType2 "RS_GH_RifleLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Rifle6 : RS_GH_Rifle
{
	Default
	{
		Tag "Gunstar Rifle VI";
		Weapon.SelectionOrder 1545;
		Weapon.AmmoType2 "RS_GH_RifleLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
