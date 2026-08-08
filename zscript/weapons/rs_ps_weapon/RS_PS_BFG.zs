// RS_PS_BFG -- MeatGrinder set. Source: BFG9K (BFGN A / BFGC A-D /
// BFGA A-F, BFG model). Slot 7, BFGBall2 damage 100, 40 cells a shot.
// Fires the pack's own BFG ball (RSPA in flight, RSEA detonation,
// RSEB spray) rather than the vanilla-derived Enhanced skin.
// =====================================================================
class RS_PS_BFG : RS_Weapon
{
	Default
	{
		Tag "Grinder BFG";
		Weapon.SelectionOrder 900;
		Weapon.SlotNumber 7;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Cell";
		Inventory.Icon "BFUGA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_BFG; }

	override string GetBaseKeywords()
	{
		return "archetype:bfg trigger:semiauto delivery:heavy payload:single feed:pool reserve:cell element:kinetic promotion:pellet set:meatgrinder";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeHeavy(
			proj: RS_Catalog.PROJ_PS_BFGShot(),
			fireSnd: RS_Catalog.SND_PS_BFG(),
			ammoCost: 40,
			ammo: "Cell",
			bigMuzzle: true,
			profName: "Wide Bloom"));
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(80, 120);
				Accuracy = RS_Roll.RollDouble(69, 79);
				Velocity = RS_Roll.RollDouble(6500, 8500);
				CritChance = RS_Roll.RollDouble(0.010, 0.020);
				Capacity = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(95, 145);
				Accuracy = RS_Roll.RollDouble(71, 81);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.014, 0.027);
				Capacity = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(113, 170);
				Accuracy = RS_Roll.RollDouble(73, 83);
				Velocity = RS_Roll.RollDouble(6500, 9500);
				CritChance = RS_Roll.RollDouble(0.018, 0.034);
				Capacity = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(133, 197);
				Accuracy = RS_Roll.RollDouble(75, 85);
				Velocity = RS_Roll.RollDouble(6500, 10000);
				CritChance = RS_Roll.RollDouble(0.022, 0.041);
				Capacity = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(152, 225);
				Accuracy = RS_Roll.RollDouble(77, 87);
				Velocity = RS_Roll.RollDouble(6500, 10500);
				CritChance = RS_Roll.RollDouble(0.026, 0.048);
				Capacity = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(172, 253);
				Accuracy = RS_Roll.RollDouble(79, 89);
				Velocity = RS_Roll.RollDouble(6500, 11000);
				CritChance = RS_Roll.RollDouble(0.030, 0.055);
				Capacity = 0;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(140, 190);
					CritChance = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(45, 75);
					CritChance = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(59, 71);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(105, 155);
				Accuracy = RS_Roll.RollDouble(63, 75);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.030, 0.050);
				Capacity = 0;
				break;
		}

		if (t == VRT_Cursed) { LockedDamage = true; LockedCritChance = true; }
		else { LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false; }

		RateOfFire = 1;
		ReloadSpeed = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		CritMult          = RS_Roll.RollDouble(1.4 + idx * 0.15, 1.6 + idx * 0.4);
		PelletCount = 1;
		Choke = RS_Roll.RollDouble(0.2 + idx * 0.03, 0.4 + idx * 0.04);
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled) Condition = RS_Roll.RollDouble(RS_Roll.STARTING_CONDITION_MIN, 100);
		bStatsRolled = true;
	}

	States
	{
	Spawn:
		BFUG A -1;
		Stop;

	Ready:
		BFGN A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		BFGN A 1 A_Lower;
		Loop;

	Select:
		BFGN A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Cell") > 39, "Shoot");
		Goto OutOfAmmo;

	// Source charge-up: 12 frames of BFGC before the ball leaves.
	Shoot:
		BFGC ABCDABCDABCD 1 Bright;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		BFGA ABCDEF 1 Bright;
		BFGN A 5;
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		BFGA A 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_PS_BFG2 : RS_PS_BFG
{ Default { Tag "Grinder BFG II"; Weapon.SelectionOrder 899; } }

class RS_PS_BFG3 : RS_PS_BFG
{ Default { Tag "Grinder BFG III"; Weapon.SelectionOrder 898; } }

class RS_PS_BFG4 : RS_PS_BFG
{ Default { Tag "Grinder BFG IV"; Weapon.SelectionOrder 897; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_BFG5 : RS_PS_BFG
{ Default { Tag "Grinder BFG V"; Weapon.SelectionOrder 896; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_BFG6 : RS_PS_BFG
{ Default { Tag "Grinder BFG VI"; Weapon.SelectionOrder 895; +WEAPON.OFFHANDWEAPON; } }
