// RS_PS_SSG -- MeatGrinder set. Source: SSG (SSGG A-G / SSGF A-E /
// SSGA A-B, SSG model). Slot 3, semi-auto, 10 pellets.
//
// The source's signature: primary fires BOTH barrels, alt-fire fires ONE
// and sets SSGFireToken so the next pull discharges the second barrel and
// then pumps. That two-stage alt is the interesting mechanic in the whole
// pack and is preserved here via the same token.
// =====================================================================
class RS_PS_SSGFireToken : Inventory
{
	Default { Inventory.MaxAmount 1; +INVENTORY.UNDROPPABLE }
}

class RS_PS_SSG : RS_Weapon
{
	Default
	{
		Tag "Grinder Double Barrel";
		Weapon.SelectionOrder 1680;
		Weapon.SlotNumber 3;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 0;
		Weapon.AmmoType1 "Shell";
		Inventory.Icon "WPPIB0";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_SuperShotgun; }

	override string GetBaseKeywords()
	{
		return "archetype:supershotgun trigger:semiauto delivery:bullet payload:multi feed:pool reserve:shell element:kinetic promotion:pellet set:meatgrinder";
	}

	override void BuildAttackProfiles()
	{
		let both = RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_PS_SSG(),
			spreadScale: 0.1,
			usesCadence: true,
			ammoCost: 2,
			casing: RS_Catalog.CASING_PS_Shell(),
			bigMuzzle: true,
			proj: RS_Catalog.PROJ_Ballistic2(),
			profName: "Both Barrels");
		both.AmmoClass = "Shell";
		both.ImpactPuff = RS_Catalog.PUFF_PS_Hit();
		PrimarySlot.Append(both);

		// One barrel: half the pellets, half the ammo, same per-pellet damage.
		let one = RS_AttackProfile.MakeBullet(
			fireSnd: RS_Catalog.SND_PS_AutoShotgun(),
			spreadScale: 0.1,
			usesCadence: true,
			ammoCost: 1,
			casing: RS_Catalog.CASING_PS_Shell(),
			bigMuzzle: true,
			proj: RS_Catalog.PROJ_Ballistic2(),
			profName: "One Barrel");
		one.AmmoClass = "Shell";
		one.ImpactPuff = RS_Catalog.PUFF_PS_Hit();
		one.PelletOverride = 5;
		SecondarySlot.Append(one);
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(16, 24);
				Accuracy = RS_Roll.RollDouble(40, 50);
				Velocity = RS_Roll.RollDouble(6500, 8500);
				CritChance = RS_Roll.RollDouble(0.010, 0.020);
				Capacity = 0;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(19, 29);
				Accuracy = RS_Roll.RollDouble(42, 52);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.014, 0.027);
				Capacity = 0;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(23, 34);
				Accuracy = RS_Roll.RollDouble(44, 54);
				Velocity = RS_Roll.RollDouble(6500, 9500);
				CritChance = RS_Roll.RollDouble(0.018, 0.034);
				Capacity = 0;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(26, 39);
				Accuracy = RS_Roll.RollDouble(46, 56);
				Velocity = RS_Roll.RollDouble(6500, 10000);
				CritChance = RS_Roll.RollDouble(0.022, 0.041);
				Capacity = 0;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(30, 44);
				Accuracy = RS_Roll.RollDouble(48, 58);
				Velocity = RS_Roll.RollDouble(6500, 10500);
				CritChance = RS_Roll.RollDouble(0.026, 0.048);
				Capacity = 0;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(34, 50);
				Accuracy = RS_Roll.RollDouble(50, 60);
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
				Accuracy = RS_Roll.RollDouble(30, 42);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 0;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(21, 30);
				Accuracy = RS_Roll.RollDouble(34, 46);
				Velocity = RS_Roll.RollDouble(6500, 9000);
				CritChance = RS_Roll.RollDouble(0.030, 0.050);
				Capacity = 0;
				break;
		}

		if (t == VRT_Cursed) { LockedDamage = true; LockedCritChance = true; }
		else { LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false; }

		RateOfFire = 1;
		ReloadSpeed = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		PelletCount = 10;
		Choke = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled) Condition = RS_Roll.RollDouble(1, 100);
		bStatsRolled = true;
	}

	States
	{
	Spawn:
		WPPI B -1;
		Stop;

	Ready:
		SSGG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		SSGG A 1 A_Lower;
		Loop;

	Select:
		SSGG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		// A pending second barrel takes priority over a fresh double blast.
		TNT1 A 0 A_JumpIfInventory("RS_PS_SSGFireToken", 1, "SecondBarrel");
		TNT1 A 0 A_JumpIf(CountInv("Shell") > 1, "Shoot");
		Goto OutOfAmmo;

	Shoot:
		SSGF A 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		SSGF B 1;
		SSGF C 1;
		SSGF D 1;
		SSGF E 1;
		SSGG A 2;
		TNT1 A 0 A_PlaySound(RS_Catalog.SND_PS_ShotgunPump(), CHAN_WEAPON);
		SSGG ABCDDEFGGGFDDCBA 1;
		Goto Ready;

	// Source alt: fire one barrel, leave the second chambered.
	AltFire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIfInventory("RS_PS_SSGFireToken", 1, "SecondBarrel");
		TNT1 A 0 A_JumpIf(CountInv("Shell") > 0, "OneBarrel");
		Goto OutOfAmmo;

	OneBarrel:
		TNT1 A 0 A_GiveInventory("RS_PS_SSGFireToken", 1);
		SSGA A 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(1);
		SSGF B 1;
		SSGF C 1;
		SSGF D 1;
		SSGF E 1;
		Goto Ready;

	// The chambered second barrel -- fires, then pumps both shells clear.
	SecondBarrel:
		TNT1 A 0 A_JumpIf(CountInv("Shell") > 0, "SecondBarrelGo");
		Goto OutOfAmmo;

	SecondBarrelGo:
		SSGA B 1 Bright A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(1);
		SSGF B 1;
		SSGF C 1;
		SSGF D 1;
		SSGF E 1;
		SSGG A 2 A_TakeInventory("RS_PS_SSGFireToken", 1);
		TNT1 A 0 A_PlaySound(RS_Catalog.SND_PS_ShotgunPump(), CHAN_WEAPON);
		SSGG ABCDDEFGGGFDDCBA 1;
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		SSGF A 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_PS_SSG2 : RS_PS_SSG
{ Default { Tag "Grinder Double Barrel II"; Weapon.SelectionOrder 1679; } }

class RS_PS_SSG3 : RS_PS_SSG
{ Default { Tag "Grinder Double Barrel III"; Weapon.SelectionOrder 1678; } }

class RS_PS_SSG4 : RS_PS_SSG
{ Default { Tag "Grinder Double Barrel IV"; Weapon.SelectionOrder 1677; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_SSG5 : RS_PS_SSG
{ Default { Tag "Grinder Double Barrel V"; Weapon.SelectionOrder 1676; +WEAPON.OFFHANDWEAPON; } }

class RS_PS_SSG6 : RS_PS_SSG
{ Default { Tag "Grinder Double Barrel VI"; Weapon.SelectionOrder 1675; +WEAPON.OFFHANDWEAPON; } }
