// RS_SMGMasterTemplate -- the SMG weapon type.
// ---------------------------------------------------------------------
// Real data: dmg anchor 5-11, magazine 30, reload SMGR A(2)/B-T(1 each).
// Real sounds: smgfire/smgclip. Full-auto: no release gate, fires on
// TimeBetweenShots cooldown while trigger held via A_ReFire.
// =====================================================================
class RS_SMGMasterTemplate : RS_Weapon abstract
{
	Default
	{
		Weapon.SelectionOrder 1896;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 60;
		Weapon.AmmoType1 "Clip";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(5, 11);
				Accuracy      = RS_Roll.RollDouble(55, 65);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.01, 0.02);
				Capacity      = 30;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(6, 13);
				Accuracy      = RS_Roll.RollDouble(57, 67);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.012, 0.025);
				Capacity      = 30;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(7, 15);
				Accuracy      = RS_Roll.RollDouble(59, 69);
				Velocity      = RS_Roll.RollDouble(6500, 8500);
				CritChance    = RS_Roll.RollDouble(0.014, 0.03);
				Capacity      = 30;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(9, 17);
				Accuracy      = RS_Roll.RollDouble(61, 71);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.016, 0.035);
				Capacity      = 30;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(11, 19);
				Accuracy      = RS_Roll.RollDouble(63, 73);
				Velocity      = RS_Roll.RollDouble(6500, 9500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.04);
				Capacity      = 40;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(13, 21);
				Accuracy      = RS_Roll.RollDouble(65, 75);
				Velocity      = RS_Roll.RollDouble(6500, 10000);
				CritChance    = RS_Roll.RollDouble(0.02, 0.045);
				Capacity      = 40;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(14, 20);
					CritChance    = RS_Roll.RollDouble(0.04, 0.06);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(3, 7);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(45, 58);
				Velocity = RS_Roll.RollDouble(6000, 8000);
				Capacity = 30;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(10, 16);
				Accuracy      = RS_Roll.RollDouble(50, 65);
				Velocity      = RS_Roll.RollDouble(6500, 9000);
				CritChance    = RS_Roll.RollDouble(0.03, 0.05);
				Capacity      = 30;
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

		RateOfFire       = 10;  // real cadence, fixed
		ReloadSpeed       = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		PelletCount       = 1;
		Choke             = 0;
		GunBonaiSockets   = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(1, 100);

		bStatsRolled = true;
	}

	override void ApplyUpgradeCard(EVR_Tier newTier)
	{
		bool isSacrificeDowngrade = (Tier == VRT_Prototype && newTier == VRT_Basic);
		RollStats(newTier);
		if (isSacrificeDowngrade)
			PelletCount += 1;
	}

	action void A_RS_FireSMG()
	{
		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		if (backfireChance > 0 && FRandom(0, 1) < backfireChance)
		{
			A_RS_Backfire();
			TakeInventory(invoker.AmmoType2, 1);
			A_RS_MarkFired();
			return;
		}

		double dmg = invoker.DamagePerShot * dmgMult;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;

		int pellets = max(1, int(invoker.PelletCount * pelletMult));
		double spread = (100.0 - invoker.Accuracy) * 0.05; // full-auto has no cadence-overshoot penalty, ROF is the cadence

		A_FireBullets(spread, spread, pellets, int(dmg), "bulletpuff", FBF_NORANDOM);
		A_PlaySound("smgfire", CHAN_WEAPON);
		TakeInventory(invoker.AmmoType2, 1);
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

	action void A_RS_MagLoad()
	{
		int needed = invoker.Capacity - CountInv(invoker.AmmoType2);
		int available = CountInv("Clip");
		int toLoad = min(needed, available);
		if (toLoad > 0)
		{
			int clipCost = max(1, toLoad - invoker.GetReloadBonusRounds());
			clipCost = min(clipCost, available);
			TakeInventory("Clip", clipCost);
			GiveInventory(invoker.AmmoType2, toLoad);
		}
	}

	States
	{
	Spawn:
		SMP1 A -1;
		Stop;

	Ready:
		SMGG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		SMGG A 1 A_Lower;
		Loop;

	Select:
		SMGG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		SMGG BC 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_FireSMG();
		TNT1 A 0 A_ReFire();
		Goto Ready;

	// Real exact frame sequence from the reference file.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("smgclip", CHAN_AUTO);
		SMGR A 2;
		SMGR BCDEFGHIJKLMNOPQRST 1 A_RS_MagLoad();
		Goto Ready;

	Flash:
		SMGF A 2 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}
