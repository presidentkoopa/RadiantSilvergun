// VR_Shotgun -- the Shotgun weapon type.
// ---------------------------------------------------------------------
// Real data: dmg anchor 5-15 per pellet, 7 pellets, capacity 8, reserve
// ammo VR_Shell (custom, not vanilla). Real fire frames SHTG B-E/F-T
// exactly. Real reload: the fire animation's ejection frames played
// backwards per shell (T/S-N/M-G/F), one shell loaded per pass, looped
// until full or out -- genuinely different from a speed-loader. Real
// sounds: shotgf/shotpump/shotcycle/shotload/shotload2.
// =====================================================================
class VR_Shotgun : RS_Weapon
{
	Default
	{
		Tag "Knock Knock";
		Weapon.SelectionOrder 1858;
		Weapon.SlotNumber 2;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 16;
		Weapon.AmmoType1 "VR_Shell";
		Weapon.AmmoType2 "VR_ShotLoaded";
		+WEAPON.NOHANDSWITCH;
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(5, 15); // per pellet
				Accuracy      = RS_Roll.RollDouble(50, 60);
				Velocity      = RS_Roll.RollDouble(4500, 6500);
				CritChance    = RS_Roll.RollDouble(0.01, 0.02);
				Capacity      = 8;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(7, 18);
				Accuracy      = RS_Roll.RollDouble(52, 62);
				Velocity      = RS_Roll.RollDouble(4500, 6500);
				CritChance    = RS_Roll.RollDouble(0.012, 0.025);
				Capacity      = 8;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(9, 21);
				Accuracy      = RS_Roll.RollDouble(54, 64);
				Velocity      = RS_Roll.RollDouble(4500, 6500);
				CritChance    = RS_Roll.RollDouble(0.014, 0.03);
				Capacity      = 8;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(12, 24);
				Accuracy      = RS_Roll.RollDouble(56, 66);
				Velocity      = RS_Roll.RollDouble(4500, 7000);
				CritChance    = RS_Roll.RollDouble(0.016, 0.035);
				Capacity      = 8;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(15, 27);
				Accuracy      = RS_Roll.RollDouble(58, 68);
				Velocity      = RS_Roll.RollDouble(4500, 7500);
				CritChance    = RS_Roll.RollDouble(0.018, 0.04);
				Capacity      = 10;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(18, 30);
				Accuracy      = RS_Roll.RollDouble(60, 70);
				Velocity      = RS_Roll.RollDouble(4500, 8000);
				CritChance    = RS_Roll.RollDouble(0.02, 0.045);
				Capacity      = 10;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(18, 26);
					CritChance    = RS_Roll.RollDouble(0.04, 0.06);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(3, 9);
					CritChance    = RS_Roll.RollDouble(0.005, 0.015);
				}
				Accuracy = RS_Roll.RollDouble(40, 55);
				Velocity = RS_Roll.RollDouble(4000, 6000);
				Capacity = 8;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(10, 20);
				Accuracy      = RS_Roll.RollDouble(45, 60);
				Velocity      = RS_Roll.RollDouble(4500, 7000);
				CritChance    = RS_Roll.RollDouble(0.03, 0.05);
				Capacity      = 8;
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
		PelletCount       = 7;  // real pellet count
		Choke             = RS_Roll.RollDouble(0.4, 0.6); // real stat now, since this weapon has multiple pellets
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

	action void A_RS_FireShotgun()
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
		int overshoot = invoker.GetCadenceOvershoot();
		double spread = (100.0 - invoker.Accuracy) * (1.0 - invoker.Choke * 0.5) * 0.1 + (overshoot * 0.15);

		A_RS_FireBallisticVolley(pellets, spread, int(dmg), invoker.CritChance, invoker.Velocity);
		A_PlaySound("shotgf", CHAN_WEAPON);
		RS_HiFiFX.MuzzleEffects(self, false);
		RS_HiFiFX.CasingEject(self, "RS_CasingShell");
		TakeInventory(invoker.AmmoType2, 1);
		A_RS_MarkFired();
	}

	action void A_RS_Backfire()
	{
		A_PlaySound("rs_fx_weapon_empty", CHAN_WEAPON);
		double dmg = invoker.DamagePerShot;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;
		player.mo.DamageMobj(invoker, player.mo, int(dmg), 'BackfireDamage');
	}

	// Loads one shell per call -- caller loops this per reversed-frame pass.
	States
	{
	Spawn:
		SHTG A -1;
		Stop;

	Ready:
		SHTG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		SHTG A 1 A_Lower;
		Loop;

	Select:
		SHTG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	// Real exact frame sequence -- recoil then pump cycle, all one action.
	Shoot:
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_FireShotgun();
		SHTG BCDE 1;
		SHTG F 1 A_StartSound("shotpump", CHAN_BODY, CHANF_OVERLAP);
		SHTG G 1 A_StartSound("shotcycle", CHAN_5, CHANF_OVERLAP);
		SHTG H 1;
		SHTG IJKLM 1;
		SHTG N 1 A_StartSound("shotload", CHAN_6, CHANF_OVERLAP);
		SHTG OPQRST 1;
		SHTG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("VR_Shell") <= 0, "OutOfAmmo");
		SHTG F 2 A_StartSound("shotpump", CHAN_BODY, CHANF_OVERLAP);
		SHTG G 2;
		Goto ReloadFeed;

	ReloadFeed:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("VR_Shell") <= 0, "Ready");
		Goto ReloadOneShell;

	// Real exact reversed-ejection sequence, one shell loaded per pass.
	ReloadOneShell:
		SHTG T 1 A_StartSound("shotload2", CHAN_5, CHANF_OVERLAP);
		SHTG SRQPON 1;
		SHTG MLKJIHG 1;
		SHTG F 1 A_RS_ReloadIncremental();
		Goto ReloadFeed;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		SHTF ABCDEF 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class VR_Shotgun2 : VR_Shotgun
{
	Default
	{
		Tag "One-Two";
		Weapon.SelectionOrder 1857;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_ShotLoaded2";
	}
}

class VR_Shotgun3 : VR_Shotgun
{
	Default
	{
		Tag "Doorbell";
		Weapon.SelectionOrder 1856;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_ShotLoaded3";
	}
}

class VR_Shotgun4 : VR_Shotgun
{
	Default
	{
		Tag "House Call";
		Weapon.SelectionOrder 1855;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_ShotLoaded4";
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_Shotgun5 : VR_Shotgun
{
	Default
	{
		Tag "Landlord";
		Weapon.SelectionOrder 1854;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_ShotLoaded5";
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_Shotgun6 : VR_Shotgun
{
	Default
	{
		Tag "Eviction";
		Weapon.SelectionOrder 1853;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_ShotLoaded6";
		+WEAPON.OFFHANDWEAPON;
	}
}
