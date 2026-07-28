// RS_SuperShotgunMasterTemplate -- the Super Shotgun weapon type.
// ---------------------------------------------------------------------
// Real data confirmed from the actual old SSG.zs: 20 pellets on the
// main double-barrel fire (dmg anchor 5), 7 pellets on a single-barrel
// alt-fire (also dmg anchor 5), sprites SHT2 (main)/SHTG (alt-fire uses
// the single Shotgun's sprite)/SHT4 (flash)/SGN2 (spawn). Real sounds:
// wpn/shotgun2 (main), wpn/shotgun1 (alt). Real puffs: vrssgpuff (main),
// vrshotpuff (alt). Reload uses real built-in GZDoom SSG actions
// (A_OpenShotgun2/A_LoadShotgun2/A_CloseShotgun2), not custom sounds --
// that's what the real file does, reused directly rather than guessed.
// Alt-fire (single barrel) not built yet -- main double-barrel only.
// =====================================================================
class RS_SuperShotgunMasterTemplate : RS_Weapon abstract
{
	Default
	{
		Weapon.SelectionOrder 1893;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 4;
		Weapon.AmmoType1 "VR_Shell";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(5, 12); // real anchor, per pellet
				Accuracy      = RS_Roll.RollDouble(45, 55);
				Velocity      = RS_Roll.RollDouble(4000, 6000);
				CritChance    = RS_Roll.RollDouble(0.01, 0.02);
				Capacity      = 2; // real: both barrels, 2-shell chamber
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(6, 15);
				Accuracy      = RS_Roll.RollDouble(47, 57);
				Velocity      = RS_Roll.RollDouble(4000, 6000);
				CritChance    = RS_Roll.RollDouble(0.012, 0.025);
				Capacity      = 2;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(8, 18);
				Accuracy      = RS_Roll.RollDouble(49, 59);
				Velocity      = RS_Roll.RollDouble(4000, 6000);
				CritChance    = RS_Roll.RollDouble(0.014, 0.03);
				Capacity      = 2;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(10, 21);
				Accuracy      = RS_Roll.RollDouble(51, 61);
				Velocity      = RS_Roll.RollDouble(4000, 6500);
				CritChance    = RS_Roll.RollDouble(0.016, 0.035);
				Capacity      = 2;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(13, 24);
				Accuracy      = RS_Roll.RollDouble(53, 63);
				Velocity      = RS_Roll.RollDouble(4000, 7000);
				CritChance    = RS_Roll.RollDouble(0.018, 0.04);
				Capacity      = 2;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(16, 27);
				Accuracy      = RS_Roll.RollDouble(55, 65);
				Velocity      = RS_Roll.RollDouble(4000, 7500);
				CritChance    = RS_Roll.RollDouble(0.02, 0.045);
				Capacity      = 2;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(15, 22);
					CritChance    = RS_Roll.RollDouble(0.04, 0.06);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(3, 8);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(35, 48);
				Velocity = RS_Roll.RollDouble(3500, 5500);
				Capacity = 2;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(9, 17);
				Accuracy      = RS_Roll.RollDouble(40, 55);
				Velocity      = RS_Roll.RollDouble(4000, 6500);
				CritChance    = RS_Roll.RollDouble(0.03, 0.05);
				Capacity      = 2;
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

		RateOfFire       = 1;   // real cadence, fixed
		ReloadSpeed       = RS_Roll.RollDouble(0.8 + idx * 0.03, 1.0 + idx * 0.05);
		PelletCount       = 20; // real pellet count, both barrels together
		Choke             = RS_Roll.RollDouble(0.3, 0.5);
		GunBonaiSockets   = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(1, 100);

		bStatsRolled = true;
	}

	override void ApplyUpgradeCard(EVR_Tier newTier)
	{
		RollStats(newTier);
	}

	action void A_RS_FireSSG()
	{
		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		if (backfireChance > 0 && FRandom(0, 1) < backfireChance)
		{
			A_RS_Backfire();
			TakeInventory(invoker.AmmoType2, 2); // both barrels consumed regardless
			A_RS_MarkFired();
			return;
		}

		double dmg = invoker.DamagePerShot * dmgMult;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;

		int pellets = max(1, int(invoker.PelletCount * pelletMult));
		int overshoot = invoker.GetCadenceOvershoot();
		double spread = (100.0 - invoker.Accuracy) * (1.0 - invoker.Choke * 0.5) * 0.1 + (overshoot * 0.15);

		A_FireBullets(spread, spread, pellets, int(dmg), "vrssgpuff", FBF_NORANDOM);
		A_PlaySound("wpn/shotgun2", CHAN_WEAPON);
		TakeInventory(invoker.AmmoType2, 2); // real: both barrels fire together
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

	// Break-action reload: refills both chamber slots at once from VR_Shell.
	action void A_RS_BreakLoad()
	{
		int needed = invoker.Capacity - CountInv(invoker.AmmoType2);
		int available = CountInv("VR_Shell");
		int toLoad = min(needed, available);
		if (toLoad > 0)
		{
			int shellCost = max(1, toLoad - invoker.GetReloadBonusRounds());
			shellCost = min(shellCost, available);
			TakeInventory("VR_Shell", shellCost);
			GiveInventory(invoker.AmmoType2, toLoad);
		}
	}

	States
	{
	Spawn:
		SGN2 A -1;
		Stop;

	Ready:
		SHT2 A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		SHT2 A 1 A_Lower;
		Loop;

	Select:
		SHT2 A 1 A_Raise;
		Loop;

	// Fires both barrels together -- needs a full 2-shell chamber.
	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= 2, "Shoot");
		Goto Reload;

	Shoot:
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_FireSSG();
		SHT2 A 2;
		SHT2 BCDEFGH 2;
		Goto Reload;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("VR_Shell") <= 0, "Ready");
		Goto DoReload;

	// Real exact break-action frame sequence, using the same built-in
	// GZDoom SSG reload actions the actual old file uses.
	DoReload:
		SHT2 I 2 A_OpenShotgun2();
		SHT2 JKLMNOPQR 3;
		SHT2 S 2 A_LoadShotgun2();
		SHT2 TUV 3 A_RS_BreakLoad();
		SHT2 X 2 A_CloseShotgun2();
		SHT2 Y 2;
		SHT2 Y 1;
		Goto Ready;

	Flash:
		SHT4 AB 1 Bright A_Light2();
		SHT4 CD 1 Bright A_Light1();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}
