// VR_PlasmaRifle -- fires real vanilla PlasmaBall.
// ---------------------------------------------------------------------
// Old projType (VR_HFPlasma) doesn't exist in our clean codebase --
// substituted real vanilla PlasmaBall. Real frames: PLSG A(2,gunflash)/
// B(0,sound+shoot)/B(2,refire). Real sound: weapons/plasma/fire. Real
// ammo: Cell. Full-auto, hard cooldown gate. Damage is vanilla
// PlasmaBall's own built-in damage -- not yet tier-scaled (see chat).
// =====================================================================
class VR_PlasmaRifle : RS_Weapon
{
	Default
	{
		Tag "Blue Streak";
		Weapon.SelectionOrder 1818;
		Weapon.SlotNumber 6;
		Weapon.AmmoUse 1;
		Weapon.AmmoGive1 40;
		Weapon.AmmoType1 "Cell";
		+WEAPON.NOHANDSWITCH;
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		DamagePerShot = RS_Roll.RollInt(8 + idx * 2, 14 + idx * 3); // tracked, not yet applied -- see file header
		Accuracy      = RS_Roll.RollDouble(70 + idx * 2, 80 + idx * 2);
		Velocity      = RS_Roll.RollDouble(7000, 9000);
		CritChance    = RS_Roll.RollDouble(0.02, 0.04 + idx * 0.01);
		Capacity      = 40;

		if (t == VRT_Cursed)
		{
			LockedDamage     = true;
			LockedCritChance = true;
		}
		else
		{
			LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false;
		}

		RateOfFire       = 9;   // real cadence, fixed
		ReloadSpeed       = 1.0;
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

	override Class<Actor> GetHeavyProjectile()
	{
		return "RS_EnhancedPlasmaBall";
	}

	action void A_RS_FirePlasma()
	{
		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		if (backfireChance > 0 && FRandom(0, 1) < backfireChance)
		{
			A_RS_Backfire();
			A_RS_MarkFired();
			return;
		}

		A_RS_FireHeavyProjectile();
		A_PlaySound("weapons/plasma/fire", CHAN_WEAPON);
		RS_HiFiFX.MuzzleEffects(self, true);
		A_RS_MarkFired();
	}

	action void A_RS_Backfire()
	{
		A_PlaySound("AKEMPT", CHAN_WEAPON);
		double dmg = invoker.DamagePerShot;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;
		player.mo.DamageMobj(invoker, player.mo, int(dmg), 'BackfireDamage');
	}

	States
	{
	Spawn:
		PLP1 A -1;
		Stop;

	Ready:
		PLSG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		PLSG A 1 A_Lower;
		Loop;

	Select:
		PLSG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Cell") > 0, "Shoot");
		Goto OutOfAmmo;

	Shoot:
		PLSG A 2 A_GunFlash();
		TNT1 A 0 A_RS_FirePlasma();
		PLSG B 2 A_ReFire();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		PLSF A 4 Bright A_Light1();
		PLSF B 4 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

class VR_PlasmaRifle2 : VR_PlasmaRifle
{
	Default
	{
		Tag "Static Shock";
		Weapon.SelectionOrder 1817;
		Weapon.SlotNumber 6;
	}
}

class VR_PlasmaRifle3 : VR_PlasmaRifle
{
	Default
	{
		Tag "Short Circuit";
		Weapon.SelectionOrder 1816;
		Weapon.SlotNumber 6;
	}
}

class VR_PlasmaRifle4 : VR_PlasmaRifle
{
	Default
	{
		Tag "Live Wire";
		Weapon.SelectionOrder 1815;
		Weapon.SlotNumber 6;
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_PlasmaRifle5 : VR_PlasmaRifle
{
	Default
	{
		Tag "Ground Fault";
		Weapon.SelectionOrder 1814;
		Weapon.SlotNumber 6;
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_PlasmaRifle6 : VR_PlasmaRifle
{
	Default
	{
		Tag "Surge Protector";
		Weapon.SelectionOrder 1813;
		Weapon.SlotNumber 6;
		+WEAPON.OFFHANDWEAPON;
	}
}
