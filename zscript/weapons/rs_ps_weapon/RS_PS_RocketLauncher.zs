// RS_PS_RocketLauncher -- MeatGrinder set. Source: MultiRocketLauncher
// (RLNC A-D / RLNF A-C, RPG model). Slot 5. Alt-fire is the source's
// signature: a three-rocket fan at -5/0/+5 degrees for three ammo.
// =====================================================================
class RS_PS_RocketLauncher : RS_Weapon
{
	Default
	{
		Tag "Grinder RPG";
		Weapon.SelectionOrder 1300;
		Weapon.SlotNumber 5;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "RocketAmmo";
		Inventory.Icon "WPPIE0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_Launcher; }

	override string GetBaseKeywords()
	{
		return "archetype:launcher trigger:semiauto delivery:heavy payload:single feed:pool reserve:rocket element:kinetic promotion:pellet set:meatgrinder";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeHeavy(
			proj: RS_Catalog.PROJ_PS_Rocket(),
			fireSnd: RS_Catalog.SND_PS_RocketLauncher(),
			ammoCost: 1,
			ammo: "RocketAmmo",
			bigMuzzle: true,
			profName: "Warhead"));

		// Source alt: three rockets in a fan. Modelled as one profile fired
		// three times by the state chain below, so each rocket rolls its own
		// damage rather than one roll being split three ways.
		SecondarySlot.Append(RS_AttackProfile.MakeHeavy(
			proj: RS_Catalog.PROJ_PS_Rocket(),
			fireSnd: RS_Catalog.SND_PS_RocketLauncher(),
			ammoCost: 1,
			ammo: "RocketAmmo",
			bigMuzzle: true,
			profName: "Salvo"));
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(16, 24);
				Accuracy = RS_Roll.RollDouble(69, 79);
				Velocity = RS_Roll.RollDouble(6500, 8500);
				CritChance = RS_Roll.RollDouble(0.010, 0.020);
				Capacity = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(19, 29);
				Accuracy = RS_Roll.RollDouble(71, 81);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.014, 0.027);
				Capacity = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(23, 34);
				Accuracy = RS_Roll.RollDouble(73, 83);
				Velocity = RS_Roll.RollDouble(6500, 9500);
				CritChance = RS_Roll.RollDouble(0.018, 0.034);
				Capacity = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(26, 39);
				Accuracy = RS_Roll.RollDouble(75, 85);
				Velocity = RS_Roll.RollDouble(6500, 10000);
				CritChance = RS_Roll.RollDouble(0.022, 0.041);
				Capacity = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(30, 44);
				Accuracy = RS_Roll.RollDouble(77, 87);
				Velocity = RS_Roll.RollDouble(6500, 10500);
				CritChance = RS_Roll.RollDouble(0.026, 0.048);
				Capacity = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(34, 50);
				Accuracy = RS_Roll.RollDouble(79, 89);
				Velocity = RS_Roll.RollDouble(6500, 11000);
				CritChance = RS_Roll.RollDouble(0.030, 0.055);
				Capacity = 0;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(28, 38);
					CritChance = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(9, 15);
					CritChance = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(59, 71);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(21, 30);
				Accuracy = RS_Roll.RollDouble(63, 75);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.030, 0.050);
				Capacity = 0;
				break;
		}

		if (t == VRT_Cursed) { LockedDamage = true; LockedCritChance = true; }
		else { LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false; }

		RateOfFire = 3;
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
		WPPI E -1;
		Stop;

	Ready:
		RLNC A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		RLNC A 1 A_Lower;
		Loop;

	Select:
		RLNC A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("RocketAmmo") > 0, "Shoot");
		Goto OutOfAmmo;

	Shoot:
		RLNF A 1 Bright A_GunFlash();
		RLNF B 1 Bright;
		TNT1 A 0 A_RS_FireSlot(0);
		RLNC A 3;
		RLNC B 1;
		RLNC C 1;
		RLNC D 1;
		RLNC A 3;
		Goto Ready;

	// Source alt: three rockets fanned. Needs three rounds in reserve.
	AltFire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("RocketAmmo") > 2, "Salvo");
		Goto OutOfAmmo;

	Salvo:
		RLNF A 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(1);
		RLNF B 1 Bright;
		TNT1 A 0 A_RS_FireSlot(1);
		RLNF C 1 Bright;
		TNT1 A 0 A_RS_FireSlot(1);
		RLNC A 5;
		RLNC ABCD 1;
		RLNC ABCD 1;
		RLNC ABCD 1;
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		RLNF A 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_PS_RocketLauncher2 : RS_PS_RocketLauncher
{ Default { Tag "Grinder RPG II"; Weapon.SelectionOrder 1299; } }

class RS_PS_RocketLauncher3 : RS_PS_RocketLauncher
{ Default { Tag "Grinder RPG III"; Weapon.SelectionOrder 1298; } }

class RS_PS_RocketLauncher4 : RS_PS_RocketLauncher
{ Default { Tag "Grinder RPG IV"; Weapon.SelectionOrder 1297; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_RocketLauncher5 : RS_PS_RocketLauncher
{ Default { Tag "Grinder RPG V"; Weapon.SelectionOrder 1296; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_RocketLauncher6 : RS_PS_RocketLauncher
{ Default { Tag "Grinder RPG VI"; Weapon.SelectionOrder 1295; +WEAPON.OFFHANDWEAPON; } }
