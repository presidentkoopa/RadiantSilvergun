// RS_GH_Unmaker -- GunstarHeroes set, imported from HF_HB_Unmaker.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBUM), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 7, projectile, 1 pellet(s), 1.0 degree cone,
// fireDelay 4 (~8 shots/sec).
//
// NOT taken: HF_Weapon's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_Unmaker : RS_Weapon
{
	Default
	{
		Tag "Gunstar Unmaker";
		Weapon.SelectionOrder 920;
		Weapon.SlotNumber 7;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Cell";
		Inventory.Icon "HBUMA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override string GetBaseKeywords()
	{
		return "archetype:energy trigger:fullauto delivery:heavy payload:single feed:pool reserve:cell element:melt promotion:pellet set:gunstarheroes";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeHeavy(
			proj: RS_Catalog.PROJ_GH_UnmakerShot(),
			fireSnd: RS_Catalog.SND_GH_Unmaker(),
			ammoCost: 1,
			ammo: "Cell",
			bigMuzzle: true,
			profName: "Gunstar Unmaker"));
	}

	// Source anchor: 10-10 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH Unmaker is a rolled weapon
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
				Capacity      = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(9, 14);
				Accuracy      = RS_Roll.RollDouble(71, 81);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(11, 17);
				Accuracy      = RS_Roll.RollDouble(73, 83);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(13, 19);
				Accuracy      = RS_Roll.RollDouble(75, 85);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(15, 22);
				Accuracy      = RS_Roll.RollDouble(77, 87);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(17, 25);
				Accuracy      = RS_Roll.RollDouble(79, 89);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 0;
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
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(10, 15);
				Accuracy      = RS_Roll.RollDouble(63, 75);
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

		RateOfFire      = 8;
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
		HBUM A -1;
		Stop;

	Ready:
		HBUM A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		HBUM A 1 A_Lower;
		Loop;

	Select:
		HBUM A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Cell") > 0, "Shoot");
		Goto OutOfAmmo;

	Shoot:
		HBUM B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBUM C 2;
		HBUM D 2;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBUM B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_Unmaker2 : RS_GH_Unmaker
{
	Default
	{
		Tag "Gunstar Unmaker II";
		Weapon.SelectionOrder 919;
	}
}

class RS_GH_Unmaker3 : RS_GH_Unmaker
{
	Default
	{
		Tag "Gunstar Unmaker III";
		Weapon.SelectionOrder 918;
	}
}

class RS_GH_Unmaker4 : RS_GH_Unmaker
{
	Default
	{
		Tag "Gunstar Unmaker IV";
		Weapon.SelectionOrder 917;
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Unmaker5 : RS_GH_Unmaker
{
	Default
	{
		Tag "Gunstar Unmaker V";
		Weapon.SelectionOrder 916;
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Unmaker6 : RS_GH_Unmaker
{
	Default
	{
		Tag "Gunstar Unmaker VI";
		Weapon.SelectionOrder 915;
		+WEAPON.OFFHANDWEAPON;
	}
}
