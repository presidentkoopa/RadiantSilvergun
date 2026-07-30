// RS_RocketLauncherMasterTemplate -- fires real vanilla Rocket.
// ---------------------------------------------------------------------
// Real frames: MISG B(6,gunflash)/B(0,sound)/B(4,shoot). Real sound:
// rocklf. Real ammo: RocketAmmo (vanilla). Semi-auto, release-gated.
// Damage is vanilla Rocket's own built-in damage -- NOT yet tier-scaled
// through DamagePerShot (see chat, needs a custom projectile subclass).
// =====================================================================
class RS_RocketLauncherMasterTemplate : RS_Weapon abstract
{
	Default
	{
		Weapon.SelectionOrder 1891;
		Weapon.AmmoUse 1;
		Weapon.AmmoGive1 4;
		Weapon.AmmoType1 "RocketAmmo";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		DamagePerShot = RS_Roll.RollInt(80 + idx * 15, 120 + idx * 20); // tracked, not yet applied -- see file header
		Accuracy      = RS_Roll.RollDouble(85, 95);
		Velocity      = RS_Roll.RollDouble(3000, 4500);
		CritChance    = RS_Roll.RollDouble(0.02, 0.05);
		Capacity      = 1;

		if (t == VRT_Cursed)
		{
			LockedDamage     = true;
			LockedCritChance = true;
		}
		else
		{
			LockedDamage = LockedAccuracy = LockedVelocity = LockedCritChance = LockedCapacity = false;
		}

		RateOfFire       = 1;   // real cadence, fixed
		ReloadSpeed       = 1.0; // no separate reload -- AmmoUse-based
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

	action void A_RS_FireRocket()
	{
		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		if (backfireChance > 0 && FRandom(0, 1) < backfireChance)
		{
			A_RS_Backfire();
			A_RS_MarkFired();
			return;
		}

		A_FireProjectile("Rocket", 0, 0, 0, 0, FPF_NOAUTOAIM, 0);
		A_PlaySound("rocklf", CHAN_WEAPON);
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
		RLP1 A -1;
		Stop;

	Ready:
		MISG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		MISG A 1 A_Lower;
		Loop;

	Select:
		MISG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("RocketAmmo") > 0, "Shoot");
		Goto OutOfAmmo;

	Shoot:
		MISG B 6 A_GunFlash();
		TNT1 A 0 A_RS_FireRocket();
		MISG B 4;
		MISG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Flash:
		MISF A 3 Bright A_Light1();
		MISF B 4 Bright;
		MISF CD 4 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}
