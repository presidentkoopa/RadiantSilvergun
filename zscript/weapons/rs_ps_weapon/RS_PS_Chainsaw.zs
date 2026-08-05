// RS_PS_Chainsaw -- MeatGrinder set. Source: SuperSaw (SAWG/SAWF, Saw
// model). Slot 1, melee, A_Saw damage 2 per bite at high rate.
// =====================================================================
class RS_PS_Chainsaw : RS_Weapon
{
	Default
	{
		Tag "Grinder Saw";
		Weapon.SelectionOrder 2200;
		Weapon.SlotNumber 1;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Inventory.Icon "CSAWA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_Melee; }

	override string GetBaseKeywords()
	{
		return "archetype:melee trigger:fullauto delivery:melee payload:single feed:none reserve:none element:kinetic promotion:pellet set:meatgrinder";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeMelee(
			range: 64.0,
			fireSnd: RS_Catalog.SND_PS_Chainsaw(),
			puff: "RS_PS_SawPuff",
			profName: "Grind"));
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(4, 6);
				Accuracy = RS_Roll.RollDouble(69, 79);
				Velocity = RS_Roll.RollDouble(6500, 8500);
				CritChance = RS_Roll.RollDouble(0.010, 0.020);
				Capacity = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(4, 7);
				Accuracy = RS_Roll.RollDouble(71, 81);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.014, 0.027);
				Capacity = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(5, 8);
				Accuracy = RS_Roll.RollDouble(73, 83);
				Velocity = RS_Roll.RollDouble(6500, 9500);
				CritChance = RS_Roll.RollDouble(0.018, 0.034);
				Capacity = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(6, 9);
				Accuracy = RS_Roll.RollDouble(75, 85);
				Velocity = RS_Roll.RollDouble(6500, 10000);
				CritChance = RS_Roll.RollDouble(0.022, 0.041);
				Capacity = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(7, 11);
				Accuracy = RS_Roll.RollDouble(77, 87);
				Velocity = RS_Roll.RollDouble(6500, 10500);
				CritChance = RS_Roll.RollDouble(0.026, 0.048);
				Capacity = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(8, 12);
				Accuracy = RS_Roll.RollDouble(79, 89);
				Velocity = RS_Roll.RollDouble(6500, 11000);
				CritChance = RS_Roll.RollDouble(0.030, 0.055);
				Capacity = 0;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(7, 9);
					CritChance = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(2, 3);
					CritChance = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(59, 71);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(5, 7);
				Accuracy = RS_Roll.RollDouble(63, 75);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.030, 0.050);
				Capacity = 0;
				break;
		}

		if (t == VRT_Cursed) { LockedDamage = true; LockedCritChance = true; }
		else { LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false; }

		RateOfFire = 15;
		ReloadSpeed = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		CritMult          = RS_Roll.RollDouble(1.4 + idx * 0.15, 1.6 + idx * 0.4);
		PelletCount = 1;
		Choke = RS_Roll.RollDouble(0.2 + idx * 0.03, 0.4 + idx * 0.04);
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled) Condition = RS_Roll.RollDouble(1, 100);
		bStatsRolled = true;
	}

	States
	{
	Spawn:
		CSAW A -1;
		Stop;

	Ready:
		SAWG C 4 A_WeaponReady(WRF_ALLOWRELOAD);
		SAWG D 4 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		SAWG C 1 A_Lower;
		Loop;

	Select:
		SAWG D 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		Goto Shoot;

	Shoot:
		SAWF A 1 A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		SAWF B 1;
		SAWF C 1;
		SAWF D 1;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_PS_Chainsaw2 : RS_PS_Chainsaw
{ Default { Tag "Grinder Saw II"; Weapon.SelectionOrder 2199; } }

class RS_PS_Chainsaw3 : RS_PS_Chainsaw
{ Default { Tag "Grinder Saw III"; Weapon.SelectionOrder 2198; } }

class RS_PS_Chainsaw4 : RS_PS_Chainsaw
{ Default { Tag "Grinder Saw IV"; Weapon.SelectionOrder 2197; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_Chainsaw5 : RS_PS_Chainsaw
{ Default { Tag "Grinder Saw V"; Weapon.SelectionOrder 2196; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_Chainsaw6 : RS_PS_Chainsaw
{ Default { Tag "Grinder Saw VI"; Weapon.SelectionOrder 2195; +WEAPON.OFFHANDWEAPON; } }
