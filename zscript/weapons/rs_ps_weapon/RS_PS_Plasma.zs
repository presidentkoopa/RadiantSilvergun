// RS_PS_Plasma -- MeatGrinder set, the Bolter.
// ---------------------------------------------------------------------
// Source: PlasmaThrower (PLSC A-C / PLSF A, Bolter model). Slot 6,
// full-auto, two bolts per cycle, PlasmaBall44 damage 5.
//
// Fires RS_PS_PlasmaShot -- the pack's OWN plasma ball on its own imported
// sprites (RSP8 in flight, RSP9 on impact), not the vanilla-derived
// RS_EnhancedPlasmaBall. The Bolter model is bound by class name in
// MODELDEF, so it can be reused on any other weapon by adding one block.
// =====================================================================
class RS_PS_Plasma : RS_Weapon
{
	Default
	{
		Tag "Bolter";
		Weapon.SelectionOrder 1100;
		Weapon.SlotNumber 6;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Cell";
		Inventory.Icon "PLASA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_Energy; }

	override string GetBaseKeywords()
	{
		return "archetype:energy trigger:fullauto delivery:heavy payload:single feed:pool reserve:cell element:kinetic promotion:pellet set:meatgrinder";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeHeavy(
			proj: RS_Catalog.PROJ_PS_PlasmaShot(),
			fireSnd: RS_Catalog.SND_PS_Plasma(),
			ammoCost: 1,
			ammo: "Cell",
			bigMuzzle: true,
			profName: "Bolt Stream"));
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(4, 7);
				Accuracy = RS_Roll.RollDouble(69, 79);
				Velocity = RS_Roll.RollDouble(6500, 8500);
				CritChance = RS_Roll.RollDouble(0.010, 0.020);
				Capacity = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(5, 8);
				Accuracy = RS_Roll.RollDouble(71, 81);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.014, 0.027);
				Capacity = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(6, 10);
				Accuracy = RS_Roll.RollDouble(73, 83);
				Velocity = RS_Roll.RollDouble(6500, 9500);
				CritChance = RS_Roll.RollDouble(0.018, 0.034);
				Capacity = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(7, 11);
				Accuracy = RS_Roll.RollDouble(75, 85);
				Velocity = RS_Roll.RollDouble(6500, 10000);
				CritChance = RS_Roll.RollDouble(0.022, 0.041);
				Capacity = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(8, 13);
				Accuracy = RS_Roll.RollDouble(77, 87);
				Velocity = RS_Roll.RollDouble(6500, 10500);
				CritChance = RS_Roll.RollDouble(0.026, 0.048);
				Capacity = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(9, 15);
				Accuracy = RS_Roll.RollDouble(79, 89);
				Velocity = RS_Roll.RollDouble(6500, 11000);
				CritChance = RS_Roll.RollDouble(0.030, 0.055);
				Capacity = 0;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(8, 11);
					CritChance = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(2, 4);
					CritChance = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(59, 71);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(5, 9);
				Accuracy = RS_Roll.RollDouble(63, 75);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.030, 0.050);
				Capacity = 0;
				break;
		}

		if (t == VRT_Cursed) { LockedDamage = true; LockedCritChance = true; }
		else { LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false; }

		RateOfFire = 17;
		ReloadSpeed = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		PelletCount = 1;
		Choke = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled) Condition = RS_Roll.RollDouble(1, 100);
		bStatsRolled = true;
	}

	States
	{
	Spawn:
		PLAS A -1;
		Stop;

	Ready:
		PLSC A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		PLSC A 1 A_Lower;
		Loop;

	Select:
		PLSC A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Cell") > 0, "Shoot");
		Goto OutOfAmmo;

	// Source cadence: two bolts per pull (PLSF A, PLSC B, PLSF A, PLSC B).
	Shoot:
		PLSF A 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		PLSC B 1;
		TNT1 A 0 A_ReFire();
		PLSC B 1;
		PLSC C 1;
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		PLSF A 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_PS_Plasma2 : RS_PS_Plasma
{ Default { Tag "Bolter II"; Weapon.SelectionOrder 1099; } }

class RS_PS_Plasma3 : RS_PS_Plasma
{ Default { Tag "Bolter III"; Weapon.SelectionOrder 1098; } }

class RS_PS_Plasma4 : RS_PS_Plasma
{ Default { Tag "Bolter IV"; Weapon.SelectionOrder 1097; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_Plasma5 : RS_PS_Plasma
{ Default { Tag "Bolter V"; Weapon.SelectionOrder 1096; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_Plasma6 : RS_PS_Plasma
{ Default { Tag "Bolter VI"; Weapon.SelectionOrder 1095; +WEAPON.OFFHANDWEAPON; } }
