// VR_Chaingun -- the Chaingun weapon type.
// ---------------------------------------------------------------------
// Real data: dmg anchor 5-9, belt-fed directly from VR_ChaingunAmmo
// (custom reserve, no chamber/reload at all -- confirmed, the old file
// has no Reload state for this weapon). Real fire: two shots per cycle,
// CHGG A(2)/B(2). Real sound: chngun. Full-auto via A_ReFire, hard
// cooldown gate (no release-required soft penalty -- full-auto's rate
// IS its cadence).
// =====================================================================
class VR_Chaingun : RS_Weapon
{
	Default
	{
		Tag "Meat Grinder";
		Weapon.SelectionOrder 1838;
		Weapon.SlotNumber 2;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 40;
		Weapon.AmmoType1 "VR_ChaingunAmmo";
		+WEAPON.NOHANDSWITCH;
	}

	override EVR_Family GetFamily() { return EVR_Family_Chaingun; }

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(5, 9);
				Accuracy      = RS_Roll.RollDouble(50, 62);
				Velocity      = RS_Roll.RollDouble(7500, 9500);
				CritChance    = RS_Roll.RollDouble(0.01, 0.02);
				Capacity      = 40; // reserve pool size reference, no true chamber
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(6, 11);
				Accuracy      = RS_Roll.RollDouble(52, 64);
				Velocity      = RS_Roll.RollDouble(7500, 9500);
				CritChance    = RS_Roll.RollDouble(0.012, 0.025);
				Capacity      = 40;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(7, 13);
				Accuracy      = RS_Roll.RollDouble(54, 66);
				Velocity      = RS_Roll.RollDouble(7500, 9500);
				CritChance    = RS_Roll.RollDouble(0.014, 0.03);
				Capacity      = 40;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(9, 15);
				Accuracy      = RS_Roll.RollDouble(56, 68);
				Velocity      = RS_Roll.RollDouble(7500, 10000);
				CritChance    = RS_Roll.RollDouble(0.016, 0.035);
				Capacity      = 40;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(11, 17);
				Accuracy      = RS_Roll.RollDouble(58, 70);
				Velocity      = RS_Roll.RollDouble(7500, 10500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.04);
				Capacity      = 60;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(13, 19);
				Accuracy      = RS_Roll.RollDouble(60, 72);
				Velocity      = RS_Roll.RollDouble(7500, 11000);
				CritChance    = RS_Roll.RollDouble(0.02, 0.045);
				Capacity      = 60;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(12, 17);
					CritChance    = RS_Roll.RollDouble(0.04, 0.06);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(3, 6);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(40, 53);
				Velocity = RS_Roll.RollDouble(7000, 9000);
				Capacity = 40;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(8, 13);
				Accuracy      = RS_Roll.RollDouble(45, 60);
				Velocity      = RS_Roll.RollDouble(7500, 10000);
				CritChance    = RS_Roll.RollDouble(0.03, 0.05);
				Capacity      = 40;
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

		RateOfFire       = 17;  // real cadence, fixed -- ~2 tics/shot from the real animation
		ReloadSpeed       = 1.0; // no reload exists for this weapon, field unused but present for consistency
		PelletCount       = 1;
		Choke             = 0;
		GunBonaiSockets   = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(1, 100);

		bStatsRolled = true;
	}

	override void ApplyUpgradeCard(EVR_Tier newTier)
	{
		RollStats(newTier);
	}

	// The one hitscan weapon in the arsenal -- belt-fed straight from
	// VR_ChaingunAmmo (its AmmoType1), no magazine, so the pool is named
	// explicitly rather than falling through to AmmoType2. Full-auto, so
	// no cadence-overshoot penalty.
	//
	// KNOWN GAP (pre-existing, not introduced here): a hitscan trace
	// spawns no projectile, so nothing carries the master pointer
	// GunBonsai reads for XP attribution. This fork has no CreditShot
	// equivalent to call instead -- verified, not assumed.
	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeHitscan(
			fireSnd: "chngun",
			spreadScale: 0.05,
			ammoCost: 1,
			ammo: "VR_ChaingunAmmo",
			casing: "RS_CasingRifle",
			bigMuzzle: true,
			profName: "Belt Fed"));
	}

	States
	{
	Spawn:
		CHGG A -1;
		Stop;

	Ready:
		CHGG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		CHGG A 1 A_Lower;
		Loop;

	Select:
		CHGG A 1 A_Raise;
		Loop;

	// Real exact frame sequence: two shots per cycle.
	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("VR_ChaingunAmmo") > 0, "Shoot");
		Goto OutOfAmmo;

	Shoot:
		CHGG A 2 A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		TNT1 A 0 A_JumpIf(CountInv("VR_ChaingunAmmo") <= 0, "Ready");
		CHGG B 2 A_GunFlash();
		TNT1 A 0 A_RS_FireSlot(0);
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		CHGG A 2 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class VR_Chaingun2 : VR_Chaingun
{
	Default
	{
		Tag "Buzzsaw";
		Weapon.SelectionOrder 1837;
		Weapon.SlotNumber 2;
	}
}

class VR_Chaingun3 : VR_Chaingun
{
	Default
	{
		Tag "Wood Chipper";
		Weapon.SelectionOrder 1836;
		Weapon.SlotNumber 3;
	}
}

class VR_Chaingun4 : VR_Chaingun
{
	Default
	{
		Tag "Lawnmower";
		Weapon.SelectionOrder 1835;
		Weapon.SlotNumber 3;
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_Chaingun5 : VR_Chaingun
{
	Default
	{
		Tag "Garbage Disposal";
		Weapon.SelectionOrder 1834;
		Weapon.SlotNumber 4;
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_Chaingun6 : VR_Chaingun
{
	Default
	{
		Tag "Paper Shredder";
		Weapon.SelectionOrder 1833;
		Weapon.SlotNumber 4;
		+WEAPON.OFFHANDWEAPON;
	}
}
