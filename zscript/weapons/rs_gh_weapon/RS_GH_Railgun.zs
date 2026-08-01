// RS_GH_Railgun -- GunstarHeroes set, imported from HF_HB_Railgun.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBRA + RAIR), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 6, ballistic, 1 pellet(s), 0.0 degree cone,
// fireDelay 14 (~2 shots/sec).
//
// NOT taken: HF_Weapon's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_Railgun : RS_Weapon
{
	Default
	{
		Tag "Gunstar Railgun";
		Weapon.SelectionOrder 1120;
		Weapon.SlotNumber 6;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Cell";
		Weapon.AmmoType2 "RS_GH_RailgunLoaded";
		Inventory.Icon "HBRAA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override string GetBaseKeywords()
	{
		return "archetype:railgun trigger:semiauto delivery:bullet payload:single feed:atomic-fill reserve:cell element:kinetic promotion:pellet set:gunstarheroes";
	}

	override void BuildAttackProfiles()
	{
		// Primary: coiled double-helix bolt.
		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_Railgun(),
			spreadScale: 0.0,
			usesCadence: true,
			ammoCost: 10,
			bigMuzzle: false,
			proj: RS_Catalog.PROJ_RailBolt(),
			profName: "Gunstar Railgun"));

		// Secondary: BD-faithful straight bolt, same cost/cadence.
		SecondarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_Railgun(),
			spreadScale: 0.0,
			usesCadence: true,
			ammoCost: 10,
			bigMuzzle: false,
			proj: RS_Catalog.PROJ_RailBoltStraight(),
			profName: "Straight Bolt"));
	}

	// Source anchor: 400-400 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH Railgun is a rolled weapon
	// like everything else instead of a fixed statline.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(320, 480);
				Accuracy      = RS_Roll.RollDouble(72, 82);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.010, 0.020);
				Capacity      = 50;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(392, 584);
				Accuracy      = RS_Roll.RollDouble(74, 84);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 50;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(464, 688);
				Accuracy      = RS_Roll.RollDouble(76, 86);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 50;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(536, 792);
				Accuracy      = RS_Roll.RollDouble(78, 88);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 50;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(608, 896);
				Accuracy      = RS_Roll.RollDouble(80, 90);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 50;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(680, 1000);
				Accuracy      = RS_Roll.RollDouble(82, 92);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 50;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(560, 760);
					CritChance    = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(180, 300);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(62, 74);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 50;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(420, 600);
				Accuracy      = RS_Roll.RollDouble(66, 78);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.050);
				Capacity      = 50;
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
		HBRA A -1;
		Stop;

	Ready:
		HBRA A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		HBRA A 1 A_Lower;
		Loop;

	Select:
		HBRA A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= 10, "Shoot");
		Goto Reload;

	Shoot:
		HBRA B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBRA C 2;
		HBRA D 2;
		HBRA A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	// Straight-bolt secondary, same 10-cell cost as primary.
	AltFire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= 10, "ShootAlt");
		Goto Reload;

	ShootAlt:
		HBRA B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(1);
		HBRA C 2;
		HBRA D 2;
		HBRA A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Cell") <= 0, "OutOfAmmo");
		RAIR ABCDEFGHIJKLMNOPQRSTUVWX 1;
		TNT1 A 0 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBRA B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_Railgun2 : RS_GH_Railgun
{
	Default
	{
		Tag "Gunstar Railgun II";
		Weapon.SelectionOrder 1119;
		Weapon.AmmoType2 "RS_GH_RailgunLoaded2";
	}
}

class RS_GH_Railgun3 : RS_GH_Railgun
{
	Default
	{
		Tag "Gunstar Railgun III";
		Weapon.SelectionOrder 1118;
		Weapon.AmmoType2 "RS_GH_RailgunLoaded3";
	}
}

class RS_GH_Railgun4 : RS_GH_Railgun
{
	Default
	{
		Tag "Gunstar Railgun IV";
		Weapon.SelectionOrder 1117;
		Weapon.AmmoType2 "RS_GH_RailgunLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Railgun5 : RS_GH_Railgun
{
	Default
	{
		Tag "Gunstar Railgun V";
		Weapon.SelectionOrder 1116;
		Weapon.AmmoType2 "RS_GH_RailgunLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Railgun6 : RS_GH_Railgun
{
	Default
	{
		Tag "Gunstar Railgun VI";
		Weapon.SelectionOrder 1115;
		Weapon.AmmoType2 "RS_GH_RailgunLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
