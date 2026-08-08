// RS_PS_Chaingun -- MeatGrinder set. Source: ChaingunCannon (MGUG A-D /
// MGUF A-B, Chaingun model). Slot 4, full-auto, Bullet1 damage 20.
// Source spins down through MGUG cycles after the trigger releases --
// that wind-down is kept.
// =====================================================================
class RS_PS_Chaingun : RS_Weapon
{
	Default
	{
		Tag "Grinder Cannon";
		Weapon.SelectionOrder 1520;
		Weapon.SlotNumber 4;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Clip";
		Inventory.Icon "WPPID0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_Chaingun; }

	override string GetBaseKeywords()
	{
		return "archetype:chaingun trigger:fullauto delivery:bullet delivery:heavy payload:single feed:pool reserve:clip element:kinetic promotion:pellet set:meatgrinder";
	}

	override void BuildAttackProfiles()
	{
		let primary = RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_PS_Chaingun(),
			spreadScale: 0.06,
			usesCadence: false,
			ammoCost: 1,
			casing: RS_Catalog.CASING_PS_Rifle(),
			bigMuzzle: true,
			proj: RS_Catalog.PROJ_Ballistic2(),
			profName: "Suppress");
		primary.AmmoClass = "Clip";
		primary.ImpactPuff = RS_Catalog.PUFF_PS_Hit();
		PrimarySlot.Append(primary);
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(16, 24);
				Accuracy = RS_Roll.RollDouble(58, 68);
				Velocity = RS_Roll.RollDouble(6500, 8500);
				CritChance = RS_Roll.RollDouble(0.010, 0.020);
				Capacity = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(19, 29);
				Accuracy = RS_Roll.RollDouble(60, 70);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.014, 0.027);
				Capacity = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(23, 34);
				Accuracy = RS_Roll.RollDouble(62, 72);
				Velocity = RS_Roll.RollDouble(6500, 9500);
				CritChance = RS_Roll.RollDouble(0.018, 0.034);
				Capacity = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(26, 39);
				Accuracy = RS_Roll.RollDouble(64, 74);
				Velocity = RS_Roll.RollDouble(6500, 10000);
				CritChance = RS_Roll.RollDouble(0.022, 0.041);
				Capacity = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(30, 44);
				Accuracy = RS_Roll.RollDouble(66, 76);
				Velocity = RS_Roll.RollDouble(6500, 10500);
				CritChance = RS_Roll.RollDouble(0.026, 0.048);
				Capacity = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(34, 50);
				Accuracy = RS_Roll.RollDouble(68, 78);
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
				Accuracy = RS_Roll.RollDouble(48, 60);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(21, 30);
				Accuracy = RS_Roll.RollDouble(52, 64);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.030, 0.050);
				Capacity = 0;
				break;
		}

		if (t == VRT_Cursed) { LockedDamage = true; LockedCritChance = true; }
		else { LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false; }

		RateOfFire = 14;
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
		WPPI D -1;
		Stop;

	Ready:
		MGUG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		MGUG A 1 A_Lower;
		Loop;

	Select:
		MGUG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") > 0, "Shoot");
		Goto OutOfAmmo;

	Shoot:
		MGUF A 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		MGUF B 1 Bright;
		TNT1 A 0 A_ReFire();
		Goto SpinDown;

	// Source wind-down: three MGUG cycles at increasing tic length.
	SpinDown:
		MGUG ABCDABCDABCD 1 A_WeaponReady(WRF_ALLOWRELOAD);
		MGUG ABCDABCD 2 A_WeaponReady(WRF_ALLOWRELOAD);
		MGUG ABCD 2 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		MGUF A 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_PS_Chaingun2 : RS_PS_Chaingun
{ Default { Tag "Grinder Cannon II"; Weapon.SelectionOrder 1519; } }

class RS_PS_Chaingun3 : RS_PS_Chaingun
{ Default { Tag "Grinder Cannon III"; Weapon.SelectionOrder 1518; } }

class RS_PS_Chaingun4 : RS_PS_Chaingun
{ Default { Tag "Grinder Cannon IV"; Weapon.SelectionOrder 1517; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_Chaingun5 : RS_PS_Chaingun
{ Default { Tag "Grinder Cannon V"; Weapon.SelectionOrder 1516; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_Chaingun6 : RS_PS_Chaingun
{ Default { Tag "Grinder Cannon VI"; Weapon.SelectionOrder 1515; +WEAPON.OFFHANDWEAPON; } }
