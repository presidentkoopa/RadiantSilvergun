// RS_GH_Fist -- GunstarHeroes set, imported from the source arsenal pack.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBFS), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 1, melee, 1 pellet(s), 1.0 degree cone,
// fireDelay 10 (~3 shots/sec).
//
// NOT taken: the source pack's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_Fist : RS_Weapon
{
	// Melee fallback -- loses the hand to a real gun at spawn.
	// Inherited by RS_GH_Fist2..6.
	override bool IsHandFiller() { return true; }

	Default
	{
		Tag "Gunstar Knuckles";
		Weapon.SelectionOrder 3000;
		Weapon.SlotNumber 1;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Inventory.Icon "HBFSA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override string GetBaseKeywords()
	{
		return "archetype:melee trigger:semiauto delivery:melee payload:single feed:none reserve:none element:kinetic promotion:pellet set:gunstarheroes";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeMelee(
			range: 64.0,
			fireSnd: RS_Catalog.SND_GH_Fist(),
			puff: "BulletPuff",
			profName: "Knuckle"));
	}

	// Source anchor: 20-40 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH Fist is a rolled weapon
	// like everything else instead of a fixed statline.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(24, 36);
				Accuracy      = RS_Roll.RollDouble(69, 79);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.010, 0.020);
				Capacity      = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(29, 43);
				Accuracy      = RS_Roll.RollDouble(71, 81);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(34, 51);
				Accuracy      = RS_Roll.RollDouble(73, 83);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(40, 59);
				Accuracy      = RS_Roll.RollDouble(75, 85);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(45, 67);
				Accuracy      = RS_Roll.RollDouble(77, 87);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(51, 75);
				Accuracy      = RS_Roll.RollDouble(79, 89);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 0;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(42, 57);
					CritChance    = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(13, 22);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(59, 71);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(31, 45);
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

		RateOfFire      = 3;
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
		HBFS A -1;
		Stop;

	Ready:
		HBFS A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		HBFS A 1 A_Lower;
		Loop;

	Select:
		HBFS A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		Goto Shoot;

	Shoot:
		HBFS B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBFS C 2;
		HBFS D 2;
		HBFS A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBFS B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_Fist2 : RS_GH_Fist
{
	Default
	{
		Tag "Gunstar Knuckles II";
		Weapon.SelectionOrder 2999;
	}
}

class RS_GH_Fist3 : RS_GH_Fist
{
	Default
	{
		Tag "Gunstar Knuckles III";
		Weapon.SelectionOrder 2998;
	}
}

class RS_GH_Fist4 : RS_GH_Fist
{
	Default
	{
		Tag "Gunstar Knuckles IV";
		Weapon.SelectionOrder 2997;
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Fist5 : RS_GH_Fist
{
	Default
	{
		Tag "Gunstar Knuckles V";
		Weapon.SelectionOrder 2996;
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Fist6 : RS_GH_Fist
{
	Default
	{
		Tag "Gunstar Knuckles VI";
		Weapon.SelectionOrder 2995;
		+WEAPON.OFFHANDWEAPON;
	}
}
