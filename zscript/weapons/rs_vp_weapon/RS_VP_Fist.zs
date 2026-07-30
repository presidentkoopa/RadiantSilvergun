// RS_VP_Fist -- "Brass Knuckle", the Vanilla+ melee baseline.
// ---------------------------------------------------------------------
// Real data: melee punch, dmg 4 normal / 40 with Berserk, sprites
// PKFS (ready) / PUNP (world pickup).
//
// No ammo, no projectile, no casings -- so no AmmoType2, no
// ProjectileClass involvement, and no CasingEject. Sound is the HQ
// vanilla punch.
// =====================================================================
class RS_VP_Fist : RS_VP_Weapon
{
	Default
	{
		Tag "Brass Knuckle";
		Weapon.SelectionOrder 3700;
		Weapon.SlotNumber 1;
		Weapon.AmmoUse 0;
		Weapon.Kickback 100;
		+WEAPON.WIMPY_WEAPON
		+WEAPON.MELEEWEAPON
		+WEAPON.NOHANDSWITCH
		+INVENTORY.UNDROPPABLE
		Obituary "$OB_MPFIST";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 4;
			Accuracy      = 100;
			Velocity      = 0;
			CritChance    = 0.0;
			Capacity      = 0;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(3, 6 + idx);
			Accuracy      = 100;
			Velocity      = 0;
			CritChance    = RS_Roll.RollDouble(0.0, 0.03);
			Capacity      = 0;
		}

		RateOfFire      = 3;
		ReloadSpeed     = 1.0;
		PelletCount     = 1;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = 100.0;

		bStatsRolled = true;
	}

	// Berserk multiplies the punch the same way the source does (4 -> 40),
	// derived from the rolled DamagePerShot rather than a fixed number so
	// a non-purist roll still scales correctly.
	action void A_RS_VP_Punch()
	{
		int dmg = invoker.DamagePerShot;
		if (CountInv("PowerStrength"))
			dmg *= 10;

		A_CustomPunch(dmg, false, 0, "BulletPuff", 64);
		A_PlaySound("rs_vp_fist_punch", CHAN_WEAPON);
		A_RS_MarkFired();
	}

	States
	{
	Spawn:
		PUNP A -1;
		Stop;

	Ready:
		PKFS A 1 A_WeaponReady();
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		PKFS A 1 A_Lower;
		Loop;

	Select:
		PKFS A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		PKFS B 2;
		PKFS C 2;
		TNT1 A 0 A_RS_VP_Punch();
		PKFS D 3;
		PKFS C 2;
		PKFS B 2;
		PKFS A 1 A_ReFire();
		Goto Ready;
	}
}

class RS_VP_Fist2 : RS_VP_Fist
{
	Default
	{
		Tag "Brass Knuckle (Off-Hand)";
		Weapon.SelectionOrder 3699;
		Weapon.SlotNumber 1;
		+WEAPON.OFFHANDWEAPON
	}
}
