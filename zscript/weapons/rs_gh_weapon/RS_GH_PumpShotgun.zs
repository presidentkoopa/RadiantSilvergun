// RS_GH_PumpShotgun -- GunstarHeroes set, imported from the source arsenal pack.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBSG + SSHR), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 3, ballistic, 14 pellet(s), 6.0 degree cone,
// fireDelay 14 (~2 shots/sec).
//
// NOT taken: the source pack's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_PumpShotgun : RS_Weapon
{
	Default
	{
		Tag "Gunstar Pump";
		Weapon.SelectionOrder 1700;
		Weapon.SlotNumber 3;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Shell";
		Weapon.AmmoType2 "RS_GH_PumpShotgunLoaded";
		Inventory.Icon "HBSGA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override string GetBaseKeywords()
	{
		return "archetype:shotgun trigger:semiauto delivery:bullet payload:multi feed:atomic-fill reserve:shell element:kinetic promotion:pellet set:gunstarheroes";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_PumpShotgun(),
			spreadScale: 0.1,
			usesCadence: true,
			ammoCost: 1,
			casing: "RS_CasingShell",
			bigMuzzle: false,
			proj: RS_Catalog.PROJ_Ballistic(),
			profName: "Pump"));
	}

	// Source anchor: 13-13 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH PumpShotgun is a rolled weapon
	// like everything else instead of a fixed statline.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(10, 15);
				Accuracy      = RS_Roll.RollDouble(54, 64);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.010, 0.020);
				Capacity      = 9;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(12, 18);
				Accuracy      = RS_Roll.RollDouble(56, 66);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 9;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(15, 22);
				Accuracy      = RS_Roll.RollDouble(58, 68);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 9;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(17, 25);
				Accuracy      = RS_Roll.RollDouble(60, 70);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 9;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(19, 29);
				Accuracy      = RS_Roll.RollDouble(62, 72);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 9;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(22, 32);
				Accuracy      = RS_Roll.RollDouble(64, 74);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 9;
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
				Accuracy = RS_Roll.RollDouble(44, 56);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 9;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(13, 19);
				Accuracy      = RS_Roll.RollDouble(48, 60);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.050);
				Capacity      = 9;
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
		PelletCount     = 14;
		Choke           = RS_Roll.RollDouble(0.2 + idx * 0.03, 0.4 + idx * 0.04);
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(RS_Roll.STARTING_CONDITION_MIN, 100);

		bStatsRolled = true;
	}


	States
	{
	Spawn:
		HBSG A -1;
		Stop;

	Ready:
		HBSG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		HBSG A 1 A_Lower;
		Loop;

	Select:
		HBSG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		HBSG B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBSG C 2;
		HBSG D 2;
		HBSG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Shell") <= 0, "OutOfAmmo");
		SSHR ABCDEFGHI 1;
		TNT1 A 0 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBSG B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_PumpShotgun2 : RS_GH_PumpShotgun
{
	Default
	{
		Tag "Gunstar Pump II";
		Weapon.SelectionOrder 1699;
		Weapon.AmmoType2 "RS_GH_PumpShotgunLoaded2";
	}
}

class RS_GH_PumpShotgun3 : RS_GH_PumpShotgun
{
	Default
	{
		Tag "Gunstar Pump III";
		Weapon.SelectionOrder 1698;
		Weapon.AmmoType2 "RS_GH_PumpShotgunLoaded3";
	}
}

class RS_GH_PumpShotgun4 : RS_GH_PumpShotgun
{
	Default
	{
		Tag "Gunstar Pump IV";
		Weapon.SelectionOrder 1697;
		Weapon.AmmoType2 "RS_GH_PumpShotgunLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_PumpShotgun5 : RS_GH_PumpShotgun
{
	Default
	{
		Tag "Gunstar Pump V";
		Weapon.SelectionOrder 1696;
		Weapon.AmmoType2 "RS_GH_PumpShotgunLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_PumpShotgun6 : RS_GH_PumpShotgun
{
	Default
	{
		Tag "Gunstar Pump VI";
		Weapon.SelectionOrder 1695;
		Weapon.AmmoType2 "RS_GH_PumpShotgunLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
