// RS_PS_Fist -- MeatGrinder set, imported from meatgrinderV2C/weapons.txt.
// ---------------------------------------------------------------------
// Source: GrinderFist (sprites FSTZ A-I, Knife model). Slot 1, melee.
// Source anchor: A_Punch, vanilla 2-20 -- Basic tier centres on that.
//
// NOT taken: the source's firing machinery. RS_Weapon owns tier, rolled
// stats, Condition, XP and sockets. The attack is a CATALOG REFERENCE.
// =====================================================================
class RS_PS_Fist : RS_Weapon
{
	// Melee fallback -- loses the hand to a real gun at spawn, so
	// MeatGrinder starts holding its TEC-9s rather than its knives.
	// Inherited by RS_PS_Fist2..6.
	override bool IsHandFiller() { return true; }

	Default
	{
		Tag "Grinder Knife";
		Weapon.SelectionOrder 3700;
		Weapon.SlotNumber 1;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Inventory.Icon "FSTZA0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_Melee; }

	override string GetBaseKeywords()
	{
		return "archetype:melee trigger:semiauto delivery:melee payload:single feed:none reserve:none element:kinetic promotion:pellet set:meatgrinder";
	}

	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeMelee(
			range: 64.0,
			fireSnd: RS_Catalog.SND_PS_Fist(),
			puff: RS_Catalog.PUFF_PS_Hit(),
			profName: "Shank"));
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(9, 14);
				Accuracy = RS_Roll.RollDouble(69, 79);
				Velocity = RS_Roll.RollDouble(52, 68);
				CritChance = RS_Roll.RollDouble(0.010, 0.020);
				Capacity = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(11, 17);
				Accuracy = RS_Roll.RollDouble(71, 81);
				Velocity = RS_Roll.RollDouble(52, 72);
				CritChance = RS_Roll.RollDouble(0.014, 0.027);
				Capacity = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(13, 20);
				Accuracy = RS_Roll.RollDouble(73, 83);
				Velocity = RS_Roll.RollDouble(52, 76);
				CritChance = RS_Roll.RollDouble(0.018, 0.034);
				Capacity = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(16, 23);
				Accuracy = RS_Roll.RollDouble(75, 85);
				Velocity = RS_Roll.RollDouble(52, 80);
				CritChance = RS_Roll.RollDouble(0.022, 0.041);
				Capacity = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(18, 26);
				Accuracy = RS_Roll.RollDouble(77, 87);
				Velocity = RS_Roll.RollDouble(52, 84);
				CritChance = RS_Roll.RollDouble(0.026, 0.048);
				Capacity = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(20, 30);
				Accuracy = RS_Roll.RollDouble(79, 89);
				Velocity = RS_Roll.RollDouble(52, 88);
				CritChance = RS_Roll.RollDouble(0.030, 0.055);
				Capacity = 0;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(16, 22);
					CritChance = RS_Roll.RollDouble(0.040, 0.060);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(5, 9);
					CritChance = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(59, 71);
				Velocity = RS_Roll.RollDouble(48, 64);
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(12, 18);
				Accuracy = RS_Roll.RollDouble(63, 75);
				Velocity = RS_Roll.RollDouble(52, 72);
				CritChance = RS_Roll.RollDouble(0.030, 0.050);
				Capacity = 0;
				break;
		}

		if (t == VRT_Cursed)
		{
			LockedDamage = true;
			LockedCritChance = true;
		}
		else
		{
			LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false;
		}

		RateOfFire = 6;
		ReloadSpeed = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		CritMult          = RS_Roll.RollDouble(1.4 + idx * 0.15, 1.6 + idx * 0.4);
		PelletCount = 1;
		Choke = RS_Roll.RollDouble(0.2 + idx * 0.03, 0.4 + idx * 0.04);
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(RS_Roll.STARTING_CONDITION_MIN, 100);

		bStatsRolled = true;
	}

	States
	{
	Spawn:
		FSTZ A -1;
		Stop;

	Ready:
		FSTZ A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		FSTZ A 1 A_Lower;
		Loop;

	Select:
		FSTZ A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		Goto Shoot;

	// Source swing: FSTZ B (hit), CCDE, F (hit), GGHI. Two strikes per
	// pull is the source's own rhythm -- kept, but only the first drives
	// A_RS_FireSlot so damage stays one roll per trigger pull.
	Shoot:
		FSTZ B 1 A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		FSTZ C 1;
		FSTZ D 1;
		FSTZ E 1;
		FSTZ F 1;
		FSTZ G 1;
		FSTZ H 1;
		FSTZ I 1;
		FSTZ A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_PS_Fist2 : RS_PS_Fist
{
	Default { Tag "Grinder Knife II"; Weapon.SelectionOrder 3699; }
}

class RS_PS_Fist3 : RS_PS_Fist
{
	Default { Tag "Grinder Knife III"; Weapon.SelectionOrder 3698; }
}

class RS_PS_Fist4 : RS_PS_Fist
{
	Default { Tag "Grinder Knife IV"; Weapon.SelectionOrder 3697; +WEAPON.OFFHANDWEAPON; }
}

class RS_PS_Fist5 : RS_PS_Fist
{
	Default { Tag "Grinder Knife V"; Weapon.SelectionOrder 3696; +WEAPON.OFFHANDWEAPON; }
}

class RS_PS_Fist6 : RS_PS_Fist
{
	Default { Tag "Grinder Knife VI"; Weapon.SelectionOrder 3695; +WEAPON.OFFHANDWEAPON; }
}
