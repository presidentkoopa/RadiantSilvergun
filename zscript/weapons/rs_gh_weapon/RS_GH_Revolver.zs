// RS_GH_Revolver -- GunstarHeroes set, imported from the source arsenal pack.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBRV + REVR), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 2, ballistic, 1 pellet(s), 1.5 degree cone,
// fireDelay 14 (~2 shots/sec).
//
// NOT taken: the source pack's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_Revolver : RS_Weapon
{
	Default
	{
		Tag "Gunstar Scattergun Revolver";
		Weapon.SelectionOrder 1850;
		Weapon.SlotNumber 2;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Shell";
		Weapon.AmmoType2 "RS_GH_RevolverLoaded";
		Inventory.Icon "HBRVA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override string GetBaseKeywords()
	{
		return "archetype:revolver trigger:semiauto delivery:bullet payload:single payload:multi feed:atomic-fill reserve:shell element:kinetic promotion:pellet set:gunstarheroes";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_Revolver(),
			spreadScale: 0.05,
			usesCadence: true,
			ammoCost: 1,
			bigMuzzle: false,
			proj: RS_Catalog.PROJ_Ballistic(),
			profName: "Cylinder Spread"));

		// Source alt-fire: close-range 10-pellet scatter, same total damage
		// as one primary round (source: 60 total / 10 pellets = 6 each,
		// i.e. 0.1x per pellet), wide 14-degree cone, still 1 shell.
		let scatter = RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_Revolver(),
			spreadScale: 0.05,
			usesCadence: true,
			ammoCost: 1,
			bigMuzzle: false,
			proj: RS_Catalog.PROJ_Ballistic(),
			dmgMult: 0.1,
			profName: "Scatter Load");
		scatter.PelletOverride = 10;
		scatter.SpreadBonus = 14.0;
		SecondarySlot.Append(scatter);
	}

	// Source anchor: 60-60 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH Revolver is a rolled weapon
	// like everything else instead of a fixed statline.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(48, 72);
				Accuracy      = RS_Roll.RollDouble(67, 77);
				Velocity      = RS_Roll.RollDouble(52, 68);
				CritChance    = RS_Roll.RollDouble(0.010, 0.020);
				Capacity      = 6;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(58, 87);
				Accuracy      = RS_Roll.RollDouble(69, 79);
				Velocity      = RS_Roll.RollDouble(52, 72);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 6;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(69, 103);
				Accuracy      = RS_Roll.RollDouble(71, 81);
				Velocity      = RS_Roll.RollDouble(52, 76);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 6;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(80, 118);
				Accuracy      = RS_Roll.RollDouble(73, 83);
				Velocity      = RS_Roll.RollDouble(52, 80);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 6;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(91, 134);
				Accuracy      = RS_Roll.RollDouble(75, 85);
				Velocity      = RS_Roll.RollDouble(52, 84);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 6;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(102, 150);
				Accuracy      = RS_Roll.RollDouble(77, 87);
				Velocity      = RS_Roll.RollDouble(52, 88);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 6;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(84, 114);
					CritChance    = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(27, 45);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(57, 69);
				Velocity = RS_Roll.RollDouble(48, 64);
				Capacity = 6;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(63, 90);
				Accuracy      = RS_Roll.RollDouble(61, 73);
				Velocity      = RS_Roll.RollDouble(52, 72);
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

		RateOfFire      = 2;
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
		HBRV A -1;
		Stop;

	Ready:
		HBRV A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		HBRV A 1 A_Lower;
		Loop;

	Select:
		HBRV A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		HBRV B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBRV C 2;
		HBRV D 2;
		HBRV A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Shell") <= 0, "OutOfAmmo");
		REVR ABCDEFGHIJKLM 1;
		TNT1 A 0 A_RS_ReloadAtomic();
		Goto Ready;

	// Source alt-fire: close-range 10-pellet scatter, same 1-shell cost as
	// primary.
	AltFire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Spread");
		Goto Reload;

	Spread:
		HBRV B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(1);
		HBRV C 2;
		HBRV A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBRV B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_Revolver2 : RS_GH_Revolver
{
	Default
	{
		Tag "Gunstar Scattergun Revolver II";
		Weapon.SelectionOrder 1849;
		Weapon.AmmoType2 "RS_GH_RevolverLoaded2";
	}
}

class RS_GH_Revolver3 : RS_GH_Revolver
{
	Default
	{
		Tag "Gunstar Scattergun Revolver III";
		Weapon.SelectionOrder 1848;
		Weapon.AmmoType2 "RS_GH_RevolverLoaded3";
	}
}

class RS_GH_Revolver4 : RS_GH_Revolver
{
	Default
	{
		Tag "Gunstar Scattergun Revolver IV";
		Weapon.SelectionOrder 1847;
		Weapon.AmmoType2 "RS_GH_RevolverLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Revolver5 : RS_GH_Revolver
{
	Default
	{
		Tag "Gunstar Scattergun Revolver V";
		Weapon.SelectionOrder 1846;
		Weapon.AmmoType2 "RS_GH_RevolverLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Revolver6 : RS_GH_Revolver
{
	Default
	{
		Tag "Gunstar Scattergun Revolver VI";
		Weapon.SelectionOrder 1845;
		Weapon.AmmoType2 "RS_GH_RevolverLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
