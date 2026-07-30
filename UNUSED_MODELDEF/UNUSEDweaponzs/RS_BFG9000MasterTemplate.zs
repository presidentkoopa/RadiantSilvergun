// RS_BFG9000MasterTemplate -- fires real vanilla BFGBall.
// ---------------------------------------------------------------------
// Real frames: BFGG A(20,sound)/B(10,gunflash)/B(10,shoot). Real sound:
// bfgf. Real ammo: Cell, 40 per shot (real, expensive -- matches
// vanilla BFG cost). Semi-auto despite the animation's A_ReFire call --
// +WEAPON.NOAUTOFIRE overrides it in the old file; our release gate
// achieves the same real behavior. Damage is vanilla BFGBall's own
// built-in damage -- not yet tier-scaled (see chat).
// =====================================================================
class RS_BFG9000MasterTemplate : RS_Weapon abstract
{
	Default
	{
		Weapon.SelectionOrder 1889;
		Weapon.AmmoUse 1;
		Weapon.AmmoGive1 40;
		Weapon.AmmoType1 "Cell";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		DamagePerShot = RS_Roll.RollInt(150 + idx * 25, 220 + idx * 30); // tracked, not yet applied -- see file header
		Accuracy      = RS_Roll.RollDouble(90, 98);
		Velocity      = RS_Roll.RollDouble(2500, 3500);
		CritChance    = RS_Roll.RollDouble(0.03, 0.06);
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

	action void A_RS_FireBFG()
	{
		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		if (backfireChance > 0 && FRandom(0, 1) < backfireChance)
		{
			A_RS_Backfire();
			A_RS_MarkFired();
			return;
		}

		A_FireProjectile("BFGBall", 0, 0, 0, 0, FPF_NOAUTOAIM, 0);
		A_PlaySound("bfgf", CHAN_WEAPON);
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
		BFP1 A -1;
		Stop;

	Ready:
		BFGG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		BFGG A 1 A_Lower;
		Loop;

	Select:
		BFGG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Cell") >= 40, "Shoot");
		Goto OutOfAmmo;

	Shoot:
		BFGG A 20 A_PlaySound("bfgf", CHAN_WEAPON);
		BFGG B 10 A_GunFlash();
		TNT1 A 0 A_RS_FireBFG();
		BFGG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Flash:
		BFGF A 11 Bright A_Light1();
		BFGF B 6 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}
