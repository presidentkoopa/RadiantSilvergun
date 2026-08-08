// RS_GH_BFG9000 -- GunstarHeroes set, imported from the source arsenal pack.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBBF), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 7, projectile, 1 pellet(s), 1.0 degree cone,
// fireDelay 30 (~1 shots/sec).
//
// NOT taken: the source pack's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_BFG9000 : RS_Weapon
{
	Default
	{
		Tag "Gunstar BFG9000";
		Weapon.SelectionOrder 900;
		Weapon.SlotNumber 7;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Cell";
		Inventory.Icon "HBBFA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override string GetBaseKeywords()
	{
		return "archetype:bfg trigger:semiauto delivery:heavy payload:single feed:pool reserve:cell element:kinetic promotion:pellet set:gunstarheroes";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeHeavy(
			proj: RS_Catalog.PROJ_GH_BFGShot(),
			fireSnd: RS_Catalog.SND_GH_BFG9000(),
			ammoCost: 1,
			ammo: "Cell",
			bigMuzzle: true,
			profName: "Wide Bloom"));
	}

	// Source anchor: 10-10 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH BFG9000 is a rolled weapon
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

		RateOfFire      = 1;
		ReloadSpeed     = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		CritMult          = RS_Roll.RollDouble(1.4 + idx * 0.15, 1.6 + idx * 0.4);
		PelletCount     = 1;
		Choke           = RS_Roll.RollDouble(0.2 + idx * 0.03, 0.4 + idx * 0.04);
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(RS_Roll.STARTING_CONDITION_MIN, 100);

		bStatsRolled = true;
	}


	States
	{
	Spawn:
		HBBF A -1;
		Stop;

	Ready:
		HBBF A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		HBBF A 1 A_Lower;
		Loop;

	Select:
		HBBF A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Cell") > 0, "Shoot");
		Goto OutOfAmmo;

	Shoot:
		HBBF B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBBF C 2;
		HBBF D 2;
		HBBF A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBBF B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_BFG90002 : RS_GH_BFG9000
{
	Default
	{
		Tag "Gunstar BFG9000 II";
		Weapon.SelectionOrder 899;
	}
}

class RS_GH_BFG90003 : RS_GH_BFG9000
{
	Default
	{
		Tag "Gunstar BFG9000 III";
		Weapon.SelectionOrder 898;
	}
}

class RS_GH_BFG90004 : RS_GH_BFG9000
{
	Default
	{
		Tag "Gunstar BFG9000 IV";
		Weapon.SelectionOrder 897;
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_BFG90005 : RS_GH_BFG9000
{
	Default
	{
		Tag "Gunstar BFG9000 V";
		Weapon.SelectionOrder 896;
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_BFG90006 : RS_GH_BFG9000
{
	Default
	{
		Tag "Gunstar BFG9000 VI";
		Weapon.SelectionOrder 895;
		+WEAPON.OFFHANDWEAPON;
	}
}
