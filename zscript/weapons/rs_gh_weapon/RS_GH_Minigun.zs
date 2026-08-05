// RS_GH_Minigun -- GunstarHeroes set, imported from the source arsenal pack.
// ---------------------------------------------------------------------
// Taken from the source: sprites (HBMN), the model and its real frame
// indices (see MODELDEF -- copied verbatim from the pack's own
// modeldef.vr_hb_weapons, nothing inferred), the fire sound, and the
// weapon's SHAPE: slot 4, ballistic, 1 pellet(s), 5.0 degree cone,
// fireDelay 1 (~35 shots/sec).
//
// NOT taken: the source pack's firing machinery and its parallel loot /
// rarity / Condition / Divinity systems -- RS_Weapon already owns tier,
// rolled stats, Condition, XP and sockets.
//
// The attack is a CATALOG REFERENCE, not hardcoded here. See
// RS_Catalog and docs/catalog_notes.txt.
// =====================================================================
class RS_GH_Minigun : RS_Weapon
{
	Default
	{
		Tag "Gunstar Minigun";
		Weapon.SelectionOrder 1500;
		Weapon.SlotNumber 4;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Clip";
		Inventory.Icon "HBMNA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_None; }

	override string GetBaseKeywords()
	{
		return "archetype:chaingun trigger:fullauto delivery:bullet payload:single feed:pool reserve:clip element:kinetic promotion:pellet set:gunstarheroes";
	}

	override void BuildAttackProfiles()
	{
		// MakeBullet has no "ammo" named argument (only MakeHitscan/
		// MakeHeavy do) -- set AmmoClass directly on the built profile
		// instead, same as PelletOverride/SpreadBonus elsewhere. This is
		// a real travelling round (RS_BallisticFired), not hitscan.
		let primary = RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_Minigun(),
			spreadScale: 0.05,
			usesCadence: false,
			ammoCost: 1,
			casing: "RS_CasingRifle",
			bigMuzzle: true,
			proj: RS_Catalog.PROJ_Ballistic(),
			profName: "Barrel Spin");
		primary.AmmoClass = "Clip";
		PrimarySlot.Append(primary);

		// Source alt-fire "Overdrive": 2 rounds per tic instead of 1, wider
		// spread, same per-round damage. The 2x rate comes from the
		// Overdrive state chain firing this slot twice per frame, not from
		// anything on the profile itself.
		let overdrive = RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_GH_Minigun(),
			spreadScale: 0.05,
			usesCadence: false,
			ammoCost: 1,
			casing: "RS_CasingRifle",
			bigMuzzle: true,
			proj: RS_Catalog.PROJ_Ballistic(),
			profName: "Overdrive");
		overdrive.AmmoClass = "Clip";
		overdrive.SpreadBonus = 3.0;
		SecondarySlot.Append(overdrive);
	}

	// Source anchor: 16-16 flat damage. That becomes the Basic-tier
	// midpoint, with tiers ramping from it, so a GH Minigun is a rolled weapon
	// like everything else instead of a fixed statline.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(12, 19);
				Accuracy      = RS_Roll.RollDouble(57, 67);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.010, 0.020);
				Capacity      = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(15, 23);
				Accuracy      = RS_Roll.RollDouble(59, 69);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.027);
				Capacity      = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(18, 27);
				Accuracy      = RS_Roll.RollDouble(61, 71);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.034);
				Capacity      = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(21, 31);
				Accuracy      = RS_Roll.RollDouble(63, 73);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.022, 0.041);
				Capacity      = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(24, 35);
				Accuracy      = RS_Roll.RollDouble(65, 75);
				Velocity      = RS_Roll.RollDouble(6500, 10500);
				CritChance    = RS_Roll.RollDouble(0.026, 0.048);
				Capacity      = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(27, 40);
				Accuracy      = RS_Roll.RollDouble(67, 77);
				Velocity      = RS_Roll.RollDouble(6500, 11000);
				CritChance    = RS_Roll.RollDouble(0.030, 0.055);
				Capacity      = 0;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(22, 30);
					CritChance    = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(7, 12);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(47, 59);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(16, 24);
				Accuracy      = RS_Roll.RollDouble(51, 63);
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

		RateOfFire      = 35;
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
		HBMN A -1;
		Stop;

	Ready:
		HBMN A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		HBMN A 1 A_Lower;
		Loop;

	Select:
		HBMN A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") > 0, "Shoot");
		Goto OutOfAmmo;

	Shoot:
		HBMN B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		HBMN C 2;
		HBMN D 2;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	// Source alt-fire "Overdrive": 2 rounds per tic -- fires the slot
	// twice, checking ammo between shots so it can't overdraw the mag.
	AltFire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") > 0, "Overdrive");
		Goto OutOfAmmo;

	Overdrive:
		HBMN B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(1);
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "Ready");
		TNT1 A 0 A_RS_FireSlot(1);
		HBMN D 1 A_ReFire;
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		HBMN B 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_GH_Minigun2 : RS_GH_Minigun
{
	Default
	{
		Tag "Gunstar Minigun II";
		Weapon.SelectionOrder 1499;
	}
}

class RS_GH_Minigun3 : RS_GH_Minigun
{
	Default
	{
		Tag "Gunstar Minigun III";
		Weapon.SelectionOrder 1498;
	}
}

class RS_GH_Minigun4 : RS_GH_Minigun
{
	Default
	{
		Tag "Gunstar Minigun IV";
		Weapon.SelectionOrder 1497;
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Minigun5 : RS_GH_Minigun
{
	Default
	{
		Tag "Gunstar Minigun V";
		Weapon.SelectionOrder 1496;
		+WEAPON.OFFHANDWEAPON;
	}
}

class RS_GH_Minigun6 : RS_GH_Minigun
{
	Default
	{
		Tag "Gunstar Minigun VI";
		Weapon.SelectionOrder 1495;
		+WEAPON.OFFHANDWEAPON;
	}
}
