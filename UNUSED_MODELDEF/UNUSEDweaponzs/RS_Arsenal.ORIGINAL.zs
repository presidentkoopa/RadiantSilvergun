// =====================================================================
// RS_Arsenal -- the complete weapon roster in one file.
// ---------------------------------------------------------------------
// All ten weapon types (Revolver, Pistol, SMG, Rifle, Shotgun,
// SuperShotgun, Chaingun, RocketLauncher, PlasmaRifle, BFG9000): each a
// MasterTemplate inheriting RS_Weapon, then its six identity subclasses
// (3 mainhand, 3 offhand), then real per-weapon Ammo classes where a
// chamber/magazine actually exists.
//
// Real data throughout: exact frame sequences, exact damage anchors,
// exact ammo/sound names pulled from the original reference files
// (sprites/sounds/frame-counts only -- no old architecture, no HF_
// naming). Every mechanic (Condition, backfire, true semi-auto release
// gate, cadence-overshoot accuracy penalty, ReloadSpeed, full-auto hard
// cooldown) is built fresh on RS_Weapon/RS_Roll.
// =====================================================================


// RS_RevolverMasterTemplate -- the Revolver weapon type.
// ---------------------------------------------------------------------
// Rolls its own stats directly, inline, the same way every other
// weapon in this arsenal does -- there is no shared per-type roll
// function anymore. The tier table below was locked down earlier in
// this project through direct back-and-forth on real numbers, same as
// it would be for any weapon type.
// Chamber tracking uses a real per-weapon Ammo class
// (AmmoType2, VR_RevLoaded/2/3/4/5/6, one per identity subclass) so it
// shows correctly in any standard ammo HUD, not an instance counter.
// Semi-auto: true trigger-release gate + RateOfFire-derived cooldown (see GetTimeBetweenShots() in RS_Weapon -- not a stored field).
//
// Sprite names (REVL/REVO/REVF) match the real model/sprite set and
// MODELDEF exactly, frame-for-frame.
// =====================================================================
class RS_RevolverMasterTemplate : RS_Weapon abstract
{
	Default
	{
		Weapon.SelectionOrder 1898;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 48;
		Weapon.AmmoType1 "Clip"; // reserve, converts 1:1 into the chambered-round Ammo item
		// AmmoType2 (the chambered-round class, e.g. VR_RevLoaded) is set per identity subclass.
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(5, 15);
				Accuracy      = RS_Roll.RollDouble(65, 75);
				Velocity      = RS_Roll.RollDouble(6000, 8000);
				CritChance    = RS_Roll.RollDouble(0.01, 0.03);
				Capacity      = 6;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(9, 19);
				Accuracy      = RS_Roll.RollDouble(68, 78);
				Velocity      = RS_Roll.RollDouble(5500, 8500);
				CritChance    = RS_Roll.RollDouble(0.015, 0.035);
				Capacity      = 6;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(13, 23);
				Accuracy      = RS_Roll.RollDouble(71, 81);
				Velocity      = RS_Roll.RollDouble(5000, 9000);
				CritChance    = RS_Roll.RollDouble(0.02, 0.04);
				Capacity      = 6;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(18, 28);
				Accuracy      = RS_Roll.RollDouble(74, 84);
				Velocity      = RS_Roll.RollDouble(5000, 9500);
				CritChance    = RS_Roll.RollDouble(0.025, 0.045);
				Capacity      = 6;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(23, 33);
				Accuracy      = RS_Roll.RollDouble(77, 87);
				Velocity      = RS_Roll.RollDouble(4500, 10000);
				CritChance    = RS_Roll.RollDouble(0.03, 0.05);
				Capacity      = 7;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(29, 39);
				Accuracy      = RS_Roll.RollDouble(80, 90);
				Velocity      = RS_Roll.RollDouble(4000, 11000);
				CritChance    = RS_Roll.RollDouble(0.035, 0.055);
				Capacity      = 7;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(20, 30);
					CritChance    = RS_Roll.RollDouble(0.05, 0.08);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(3, 8);
					CritChance    = RS_Roll.RollDouble(0.01, 0.02);
				}
				Accuracy = RS_Roll.RollDouble(55, 70);
				Velocity = RS_Roll.RollDouble(5500, 7500);
				Capacity = 6;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(15, 25);
				Accuracy      = RS_Roll.RollDouble(65, 80);
				Velocity      = RS_Roll.RollDouble(5000, 9000);
				CritChance    = RS_Roll.RollDouble(0.04, 0.07);
				Capacity      = 6;
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

		RateOfFire       = 2;   // 2 shots/sec real cadence, fixed by the fire animation length
		ReloadSpeed      = RS_Roll.RollDouble(0.8 + int(t) * 0.03, 1.0 + int(t) * 0.05); // rolled, tier-scaled
		PelletCount      = 1;
		Choke            = 0;
		GunBonaiSockets  = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(1, 100);

		bStatsRolled = true;
	}

	// A deliberate Prototype -> Basic downgrade grants +1 permanent pellet.
	override void ApplyUpgradeCard(EVR_Tier newTier)
	{
		bool isSacrificeDowngrade = (Tier == VRT_Prototype && newTier == VRT_Basic);
		RollStats(newTier);
		if (isSacrificeDowngrade)
			PelletCount += 1;
	}

	action void A_RS_FireRevolver()
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
		int overshoot = invoker.GetCadenceOvershoot(); // tics fired early, if any
		double spread = (100.0 - invoker.Accuracy) * 0.05 + (overshoot * 0.15); // outpacing cadence widens spread

		A_FireBullets(spread, spread, pellets, int(dmg), "bulletpuff", FBF_NORANDOM);
		A_PlaySound("revolver", CHAN_WEAPON);
		TakeInventory(invoker.AmmoType2, 1);
		A_RS_MarkFired();
	}

	// Backfire: same DamagePerShot + crit roll every normal shot gets.
	action void A_RS_Backfire()
	{
		A_PlaySound("AKEMPT", CHAN_WEAPON);
		double dmg = invoker.DamagePerShot;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;
		player.mo.DamageMobj(invoker, player.mo, int(dmg), 'BackfireDamage');
	}

	// Speed loader: fills every empty chamber at once from reserve Clip.
	action void A_RS_SpeedLoad()
	{
		int needed = invoker.Capacity - CountInv(invoker.AmmoType2);
		int available = CountInv("Clip");
		int toLoad = min(needed, available);
		if (toLoad > 0)
		{
			// ReloadSpeed efficiency: a faster-rolling weapon costs less
			// reserve Clip per chambered round, rather than exceeding
			// Capacity (which is a hard chamber limit either way).
			int clipCost = max(1, toLoad - invoker.GetReloadBonusRounds());
			clipCost = min(clipCost, available);
			TakeInventory("Clip", clipCost);
			GiveInventory(invoker.AmmoType2, toLoad);
		}
	}

	States
	{
	Spawn:
		REVO A -1;
		Stop;

	Ready:
		REVL A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		REVL A 1 A_Lower;
		Loop;

	Select:
		REVL A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		REVL BCD 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_FireRevolver();
		REVL EF 2;
		REVL GHIJKLMNOP 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("9mmclip1", CHAN_AUTO);
		REVO QRSTUVWXYZ 2;
		REVO A 1 A_PlaySound("9mmclip2", CHAN_AUTO);
		REVO BCDEFGH 2;
		TNT1 A 0 A_PlaySound("9mmslide", CHAN_AUTO);
		REVO IJKL 1;
		REVL A 1 A_RS_SpeedLoad();
		Goto Ready;

	Flash:
		REVF BCD 1 Bright A_Light2();
		REVF EFGH 1 Bright A_Light1();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

// RS_PistolMasterTemplate -- the Pistol weapon type.
// ---------------------------------------------------------------------
// Real data pulled from the old reference file (sprites/sounds/frame
// sequences/damage only -- no old architecture): dmg anchor 4-10,
// magazine 12, reload frames PISG F-R / S-W / X-Y exactly. Real sounds:
// 9mmshoot/9mmclip1/9mmclip2/9mmslide/AKEMPT. True semi-auto: trigger
// release required, cadence overshoot costs Accuracy, not blocked.
// =====================================================================
class RS_PistolMasterTemplate : RS_Weapon abstract
{
	Default
	{
		Weapon.SelectionOrder 1897;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 48;
		Weapon.AmmoType1 "Clip";
		// AmmoType2 (VR_PistolLoaded/2/3/4/5/6) set per identity subclass.
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(4, 10); // real vanilla anchor
				Accuracy      = RS_Roll.RollDouble(70, 80);
				Velocity      = RS_Roll.RollDouble(7000, 9000);
				CritChance    = RS_Roll.RollDouble(0.01, 0.03);
				Capacity      = 12; // real magazine size
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(6, 13);
				Accuracy      = RS_Roll.RollDouble(72, 82);
				Velocity      = RS_Roll.RollDouble(7000, 9000);
				CritChance    = RS_Roll.RollDouble(0.015, 0.035);
				Capacity      = 12;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(8, 16);
				Accuracy      = RS_Roll.RollDouble(74, 84);
				Velocity      = RS_Roll.RollDouble(7000, 9000);
				CritChance    = RS_Roll.RollDouble(0.02, 0.04);
				Capacity      = 12;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(11, 19);
				Accuracy      = RS_Roll.RollDouble(76, 86);
				Velocity      = RS_Roll.RollDouble(7000, 9500);
				CritChance    = RS_Roll.RollDouble(0.025, 0.045);
				Capacity      = 12;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(14, 22);
				Accuracy      = RS_Roll.RollDouble(78, 88);
				Velocity      = RS_Roll.RollDouble(7000, 10000);
				CritChance    = RS_Roll.RollDouble(0.03, 0.05);
				Capacity      = 15;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(17, 25);
				Accuracy      = RS_Roll.RollDouble(80, 90);
				Velocity      = RS_Roll.RollDouble(7000, 10500);
				CritChance    = RS_Roll.RollDouble(0.035, 0.055);
				Capacity      = 15;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(12, 18);
					CritChance    = RS_Roll.RollDouble(0.05, 0.08);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(2, 6);
					CritChance    = RS_Roll.RollDouble(0.01, 0.02);
				}
				Accuracy = RS_Roll.RollDouble(55, 70);
				Velocity = RS_Roll.RollDouble(6500, 8500);
				Capacity = 12;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(9, 15);
				Accuracy      = RS_Roll.RollDouble(65, 80);
				Velocity      = RS_Roll.RollDouble(7000, 9500);
				CritChance    = RS_Roll.RollDouble(0.04, 0.07);
				Capacity      = 12;
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

		RateOfFire       = 4;   // real cadence, fixed by the fire animation
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

	action void A_RS_FirePistol()
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
		double spread = (100.0 - invoker.Accuracy) * 0.05 + (overshoot * 0.15);

		A_FireBullets(spread, spread, pellets, int(dmg), "bulletpuff", FBF_NORANDOM);
		A_PlaySound("9mmshoot", CHAN_WEAPON);
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
		PSP1 A -1;
		Stop;

	Ready:
		PISG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		PISG A 1 A_Lower;
		Loop;

	Select:
		PISG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		PISG B 2;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_FirePistol();
		PISG C 2;
		PISG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	// Real exact frame sequence from the reference file.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("9mmclip1", CHAN_AUTO);
		PISG FGHIJKLMNOPQR 1;
		TNT1 A 0 A_PlaySound("9mmclip2", CHAN_AUTO);
		PISG STUVW 1;
		TNT1 A 0 A_PlaySound("9mmslide", CHAN_AUTO);
		PISG XY 1 A_RS_MagLoad();
		Goto Ready;

	Flash:
		PISF A 2 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

// RS_SMGMasterTemplate -- the SMG weapon type.
// ---------------------------------------------------------------------
// Real data: dmg anchor 5-11, magazine 30, reload SMGR A(2)/B-T(1 each).
// Real sounds: smgfire/smgclip. Full-auto: no release gate, fires on
// RateOfFire-derived cooldown while trigger held via A_ReFire (see GetTimeBetweenShots() in RS_Weapon).
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

// RS_RifleMasterTemplate -- the Rifle weapon type.
// ---------------------------------------------------------------------
// Real data: dmg anchor 8-16, magazine 20, reload frames RIFL L-N/O-Y +
// RIFK A-I/J-L/M-O exactly. Real sounds: m16shoot fire; the old file
// itself reused the pistol's 9mmclip1/9mmclip2/9mmslide for rifle
// reload, so that's not an invention here, it's sourced. True
// semi-auto: release gate + accuracy penalty for outpacing cadence.
// =====================================================================
class RS_RifleMasterTemplate : RS_Weapon abstract
{
	Default
	{
		Weapon.SelectionOrder 1895;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 40;
		Weapon.AmmoType1 "Clip";
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;
		int idx = int(t >= VRT_Basic ? t : VRT_Basic);

		switch (t)
		{
			case VRT_Basic:
				DamagePerShot = RS_Roll.RollInt(8, 16);
				Accuracy      = RS_Roll.RollDouble(78, 88);
				Velocity      = RS_Roll.RollDouble(8500, 11000);
				CritChance    = RS_Roll.RollDouble(0.03, 0.06);
				Capacity      = 20;
				break;
			case VRT_Common:
				DamagePerShot = RS_Roll.RollInt(11, 20);
				Accuracy      = RS_Roll.RollDouble(80, 90);
				Velocity      = RS_Roll.RollDouble(8500, 11000);
				CritChance    = RS_Roll.RollDouble(0.035, 0.065);
				Capacity      = 20;
				break;
			case VRT_Uncommon:
				DamagePerShot = RS_Roll.RollInt(14, 24);
				Accuracy      = RS_Roll.RollDouble(82, 92);
				Velocity      = RS_Roll.RollDouble(8500, 11000);
				CritChance    = RS_Roll.RollDouble(0.04, 0.07);
				Capacity      = 20;
				break;
			case VRT_Advanced:
				DamagePerShot = RS_Roll.RollInt(18, 28);
				Accuracy      = RS_Roll.RollDouble(84, 94);
				Velocity      = RS_Roll.RollDouble(8500, 11500);
				CritChance    = RS_Roll.RollDouble(0.045, 0.075);
				Capacity      = 20;
				break;
			case VRT_Designer:
				DamagePerShot = RS_Roll.RollInt(22, 32);
				Accuracy      = RS_Roll.RollDouble(86, 96);
				Velocity      = RS_Roll.RollDouble(8500, 12000);
				CritChance    = RS_Roll.RollDouble(0.05, 0.08);
				Capacity      = 25;
				break;
			case VRT_Prototype:
				DamagePerShot = RS_Roll.RollInt(26, 36);
				Accuracy      = RS_Roll.RollDouble(88, 98);
				Velocity      = RS_Roll.RollDouble(8500, 12500);
				CritChance    = RS_Roll.RollDouble(0.055, 0.09);
				Capacity      = 25;
				break;
			case VRT_Trash:
				if (RS_Roll.RollDouble(0, 1) < 0.05)
				{
					DamagePerShot = RS_Roll.RollInt(24, 32);
					CritChance    = RS_Roll.RollDouble(0.06, 0.09);
				}
				else
				{
					DamagePerShot = RS_Roll.RollInt(5, 12);
					CritChance    = RS_Roll.RollDouble(0.01, 0.03);
				}
				Accuracy = RS_Roll.RollDouble(65, 80);
				Velocity = RS_Roll.RollDouble(8000, 10500);
				Capacity = 20;
				break;
			case VRT_Cursed:
				DamagePerShot = RS_Roll.RollInt(16, 26);
				Accuracy      = RS_Roll.RollDouble(75, 90);
				Velocity      = RS_Roll.RollDouble(8500, 11500);
				CritChance    = RS_Roll.RollDouble(0.06, 0.09);
				Capacity      = 20;
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

		RateOfFire       = 3;   // real cadence, fixed
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

	action void A_RS_FireRifle()
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
		double spread = (100.0 - invoker.Accuracy) * 0.05 + (overshoot * 0.15);

		A_FireBullets(spread, spread, pellets, int(dmg), "bulletpuff", FBF_NORANDOM);
		A_PlaySound("m16shoot", CHAN_WEAPON);
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
		RIFK A -1;
		Stop;

	Ready:
		RIFL A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		RIFL A 1 A_Lower;
		Loop;

	Select:
		RIFL A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		RIFL BC 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_FireRifle();
		RIFL A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	// Real exact frame sequence from the reference file.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("9mmclip1", CHAN_AUTO);
		RIFL LMN 2;
		RIFL OPQRSTUVWXY 1;
		TNT1 A 0 A_PlaySound("9mmclip2", CHAN_AUTO);
		RIFK ABCDEFGHI 2;
		RIFK JKL 1;
		TNT1 A 0 A_PlaySound("9mmslide", CHAN_AUTO);
		RIFK MNO 2 A_RS_MagLoad();
		Goto Ready;

	Flash:
		RIFL D 2 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

// RS_ShotgunMasterTemplate -- the Shotgun weapon type.
// ---------------------------------------------------------------------
// Real data: dmg anchor 5-15 per pellet, 7 pellets, capacity 8, reserve
// ammo VR_Shell (custom, not vanilla). Real fire frames SHTG B-E/F-T
// exactly. Real reload: the fire animation's ejection frames played
// backwards per shell (T/S-N/M-G/F), one shell loaded per pass, looped
// until full or out -- genuinely different from a speed-loader. Real
// sounds: shotgf/shotpump/shotcycle/shotload/shotload2.
// =====================================================================
class RS_ShotgunMasterTemplate : RS_Weapon abstract
{
	Default
	{
		Weapon.SelectionOrder 1894;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 16;
		Weapon.AmmoType1 "VR_Shell";
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

		A_FireBullets(spread, spread, pellets, int(dmg), "bulletpuff", FBF_NORANDOM);
		A_PlaySound("shotgf", CHAN_WEAPON);
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

	// Loads one shell per call -- caller loops this per reversed-frame pass.
	action void A_RS_LoadOneShell()
	{
		if (CountInv(invoker.AmmoType2) < invoker.Capacity && CountInv("VR_Shell") > 0)
		{
			GiveInventory(invoker.AmmoType2, 1);
			TakeInventory("VR_Shell", 1);
			// ReloadSpeed bonus: a chance per shell to load a second one free.
			if (invoker.GetReloadBonusRounds() > 0 && FRandom(0, 1) < 0.25
				&& CountInv(invoker.AmmoType2) < invoker.Capacity && CountInv("VR_Shell") > 0)
			{
				GiveInventory(invoker.AmmoType2, 1);
				TakeInventory("VR_Shell", 1);
			}
		}
	}

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
		SHTG F 1 A_RS_LoadOneShell();
		Goto ReloadFeed;

	Flash:
		SHTF ABCDEF 1 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

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

		A_FireBullets(spread, spread, pellets, int(dmg), "bulletpuff", FBF_NORANDOM);
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

	// Real exact break-action frame sequence.
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

// RS_ChaingunMasterTemplate -- the Chaingun weapon type.
// ---------------------------------------------------------------------
// Real data: dmg anchor 5-9, belt-fed directly from VR_ChaingunAmmo
// (custom reserve, no chamber/reload at all -- confirmed, the old file
// has no Reload state for this weapon). Real fire: two shots per cycle,
// CHGG A(2)/B(2). Real sound: chngun. Full-auto via A_ReFire, hard
// cooldown gate (no release-required soft penalty -- full-auto's rate
// IS its cadence).
// =====================================================================
class RS_ChaingunMasterTemplate : RS_Weapon abstract
{
	Default
	{
		Weapon.SelectionOrder 1892;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 40;
		Weapon.AmmoType1 "VR_ChaingunAmmo";
	}

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

	action void A_RS_FireChaingun()
	{
		double dmgMult, pelletMult, backfireChance;
		RS_Roll.GetConditionEffects(invoker.Condition, dmgMult, pelletMult, backfireChance);

		if (backfireChance > 0 && FRandom(0, 1) < backfireChance)
		{
			A_RS_Backfire();
			TakeInventory("VR_ChaingunAmmo", 1);
			A_RS_MarkFired();
			return;
		}

		double dmg = invoker.DamagePerShot * dmgMult;
		if (FRandom(0, 1) < invoker.CritChance)
			dmg *= 2.0;

		int pellets = max(1, int(invoker.PelletCount * pelletMult));
		double spread = (100.0 - invoker.Accuracy) * 0.05;

		A_FireBullets(spread, spread, pellets, int(dmg), "bulletpuff", FBF_NORANDOM);
		A_PlaySound("chngun", CHAN_WEAPON);
		TakeInventory("VR_ChaingunAmmo", 1);
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
		TNT1 A 0 A_RS_FireChaingun();
		TNT1 A 0 A_JumpIf(CountInv("VR_ChaingunAmmo") <= 0, "Ready");
		CHGG B 2 A_GunFlash();
		TNT1 A 0 A_RS_FireChaingun();
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Flash:
		CHGG A 2 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

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

// RS_PlasmaRifleMasterTemplate -- fires real vanilla PlasmaBall.
// ---------------------------------------------------------------------
// Old projType (VR_HFPlasma) doesn't exist in our clean codebase --
// substituted real vanilla PlasmaBall. Real frames: PLSG A(2,gunflash)/
// B(0,sound+shoot)/B(2,refire). Real sound: weapons/plasma/fire. Real
// ammo: Cell. Full-auto, hard cooldown gate. Damage is vanilla
// PlasmaBall's own built-in damage -- not yet tier-scaled (see chat).
// =====================================================================
class RS_PlasmaRifleMasterTemplate : RS_Weapon abstract
{
	Default
	{
		Weapon.SelectionOrder 1890;
		Weapon.AmmoUse 1;
		Weapon.AmmoGive1 40;
		Weapon.AmmoType1 "Cell";
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

		A_FireProjectile("PlasmaBall", 0, 0, 0, 0, FPF_NOAUTOAIM, 0);
		A_PlaySound("weapons/plasma/fire", CHAN_WEAPON);
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
		PLSF A 4 Bright A_Light1();
		PLSF B 4 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

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

// =====================================================================
// RS_Ammo -- every per-weapon chambered/magazine Ammo class.
// ---------------------------------------------------------------------
// Only weapon types with a real chamber/magazine concept (confirmed
// from the old reference files) get these: Revolver, Pistol, SMG,
// Rifle, Shotgun, SuperShotgun. Chaingun/Rocket/Plasma/BFG have no
// chamber in the old files either -- they consume their reserve pool
// (VR_ChaingunAmmo/RocketAmmo/Cell) directly, no separate class needed.
//
// VR_Shell is the shared reserve type for Shotgun and SuperShotgun
// (real name from the old files, not vanilla). VR_ChaingunAmmo is the
// Chaingun's real reserve type, also not vanilla.
// =====================================================================

class VR_Shell : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 50;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 50;
	}
}

class VR_ChaingunAmmo : Ammo
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 200;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 200;
	}
}


class VR_RevLoadedBase : Ammo abstract
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 6;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 6;
	}
}

class VR_RevLoaded : VR_RevLoadedBase {}
class VR_RevLoaded2 : VR_RevLoadedBase {}
class VR_RevLoaded3 : VR_RevLoadedBase {}
class VR_RevLoaded4 : VR_RevLoadedBase {}
class VR_RevLoaded5 : VR_RevLoadedBase {}
class VR_RevLoaded6 : VR_RevLoadedBase {}


class VR_PistolLoadedBase : Ammo abstract
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 12;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 12;
	}
}

class VR_PistolLoaded : VR_PistolLoadedBase {}
class VR_PistolLoaded2 : VR_PistolLoadedBase {}
class VR_PistolLoaded3 : VR_PistolLoadedBase {}
class VR_PistolLoaded4 : VR_PistolLoadedBase {}
class VR_PistolLoaded5 : VR_PistolLoadedBase {}
class VR_PistolLoaded6 : VR_PistolLoadedBase {}


class VR_SMGLoadedBase : Ammo abstract
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 30;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 30;
	}
}

class VR_SMGLoaded : VR_SMGLoadedBase {}
class VR_SMGLoaded2 : VR_SMGLoadedBase {}
class VR_SMGLoaded3 : VR_SMGLoadedBase {}
class VR_SMGLoaded4 : VR_SMGLoadedBase {}
class VR_SMGLoaded5 : VR_SMGLoadedBase {}
class VR_SMGLoaded6 : VR_SMGLoadedBase {}


class VR_RifleLoadedBase : Ammo abstract
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 20;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 20;
	}
}

class VR_RifleLoaded : VR_RifleLoadedBase {}
class VR_RifleLoaded2 : VR_RifleLoadedBase {}
class VR_RifleLoaded3 : VR_RifleLoadedBase {}
class VR_RifleLoaded4 : VR_RifleLoadedBase {}
class VR_RifleLoaded5 : VR_RifleLoadedBase {}
class VR_RifleLoaded6 : VR_RifleLoadedBase {}


class VR_ShotLoadedBase : Ammo abstract
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 8;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 8;
	}
}

class VR_ShotLoaded : VR_ShotLoadedBase {}
class VR_ShotLoaded2 : VR_ShotLoadedBase {}
class VR_ShotLoaded3 : VR_ShotLoadedBase {}
class VR_ShotLoaded4 : VR_ShotLoadedBase {}
class VR_ShotLoaded5 : VR_ShotLoadedBase {}
class VR_ShotLoaded6 : VR_ShotLoadedBase {}


class VR_SSGLoadedBase : Ammo abstract
{
	Default
	{
		Inventory.Amount 0;
		Inventory.MaxAmount 2;
		Ammo.BackpackAmount 0;
		Ammo.BackpackMaxAmount 2;
	}
}

class VR_SSGLoaded : VR_SSGLoadedBase {}
class VR_SSGLoaded2 : VR_SSGLoadedBase {}
class VR_SSGLoaded3 : VR_SSGLoadedBase {}
class VR_SSGLoaded4 : VR_SSGLoadedBase {}
class VR_SSGLoaded5 : VR_SSGLoadedBase {}
class VR_SSGLoaded6 : VR_SSGLoadedBase {}


// =====================================================================
// Identity subclasses -- one file, all ten weapon types, six each
// (3 mainhand, 3 offhand). Each sets AmmoType2 to its own Loaded ammo
// class where the weapon type has a real chamber; the four
// reserve-pool-only types (Chaingun/Rocket/Plasma/BFG) don't set one.
// =====================================================================


class VR_Revolver : RS_RevolverMasterTemplate
{
	Default
	{
		Tag "Moonlight Magnum";
		Weapon.SelectionOrder 1898;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_RevLoaded";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Revolver2 : RS_RevolverMasterTemplate
{
	Default
	{
		Tag "Sunset Cannon";
		Weapon.SelectionOrder 1897;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_RevLoaded2";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Revolver3 : RS_RevolverMasterTemplate
{
	Default
	{
		Tag "Ashwood Sentinel";
		Weapon.SelectionOrder 1896;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_RevLoaded3";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Revolver4 : RS_RevolverMasterTemplate
{
	Default
	{
		Tag "Crimson Vow";
		Weapon.SelectionOrder 1895;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_RevLoaded4";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Revolver5 : RS_RevolverMasterTemplate
{
	Default
	{
		Tag "Widow's Chime";
		Weapon.SelectionOrder 1894;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_RevLoaded5";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Revolver6 : RS_RevolverMasterTemplate
{
	Default
	{
		Tag "Iron Requiem";
		Weapon.SelectionOrder 1893;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_RevLoaded6";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Pistol : RS_PistolMasterTemplate
{
	Default
	{
		Tag "Pickpocket";
		Weapon.SelectionOrder 1888;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_PistolLoaded";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Pistol2 : RS_PistolMasterTemplate
{
	Default
	{
		Tag "Grifter";
		Weapon.SelectionOrder 1887;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_PistolLoaded2";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Pistol3 : RS_PistolMasterTemplate
{
	Default
	{
		Tag "Cutpurse";
		Weapon.SelectionOrder 1886;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_PistolLoaded3";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Pistol4 : RS_PistolMasterTemplate
{
	Default
	{
		Tag "Highwayman";
		Weapon.SelectionOrder 1885;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_PistolLoaded4";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Pistol5 : RS_PistolMasterTemplate
{
	Default
	{
		Tag "Knave";
		Weapon.SelectionOrder 1884;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_PistolLoaded5";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Pistol6 : RS_PistolMasterTemplate
{
	Default
	{
		Tag "Scoundrel";
		Weapon.SelectionOrder 1883;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_PistolLoaded6";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_SMG : RS_SMGMasterTemplate
{
	Default
	{
		Tag "Chatterbox";
		Weapon.SelectionOrder 1878;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_SMGLoaded";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_SMG2 : RS_SMGMasterTemplate
{
	Default
	{
		Tag "Backtalk";
		Weapon.SelectionOrder 1877;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_SMGLoaded2";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_SMG3 : RS_SMGMasterTemplate
{
	Default
	{
		Tag "Crosstalk";
		Weapon.SelectionOrder 1876;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_SMGLoaded3";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_SMG4 : RS_SMGMasterTemplate
{
	Default
	{
		Tag "Smalltalk";
		Weapon.SelectionOrder 1875;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_SMGLoaded4";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_SMG5 : RS_SMGMasterTemplate
{
	Default
	{
		Tag "Doubletalk";
		Weapon.SelectionOrder 1874;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_SMGLoaded5";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_SMG6 : RS_SMGMasterTemplate
{
	Default
	{
		Tag "Sweet Talk";
		Weapon.SelectionOrder 1873;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_SMGLoaded6";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Rifle : RS_RifleMasterTemplate
{
	Default
	{
		Tag "Etiquette";
		Weapon.SelectionOrder 1868;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_RifleLoaded";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Rifle2 : RS_RifleMasterTemplate
{
	Default
	{
		Tag "Pardon Me";
		Weapon.SelectionOrder 1867;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_RifleLoaded2";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Rifle3 : RS_RifleMasterTemplate
{
	Default
	{
		Tag "Manners";
		Weapon.SelectionOrder 1866;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_RifleLoaded3";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Rifle4 : RS_RifleMasterTemplate
{
	Default
	{
		Tag "Decorum";
		Weapon.SelectionOrder 1865;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_RifleLoaded4";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Rifle5 : RS_RifleMasterTemplate
{
	Default
	{
		Tag "Propriety";
		Weapon.SelectionOrder 1864;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_RifleLoaded5";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Rifle6 : RS_RifleMasterTemplate
{
	Default
	{
		Tag "Civility";
		Weapon.SelectionOrder 1863;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_RifleLoaded6";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Shotgun : RS_ShotgunMasterTemplate
{
	Default
	{
		Tag "Knock Knock";
		Weapon.SelectionOrder 1858;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_ShotLoaded";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Shotgun2 : RS_ShotgunMasterTemplate
{
	Default
	{
		Tag "One-Two";
		Weapon.SelectionOrder 1857;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_ShotLoaded2";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Shotgun3 : RS_ShotgunMasterTemplate
{
	Default
	{
		Tag "Doorbell";
		Weapon.SelectionOrder 1856;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_ShotLoaded3";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Shotgun4 : RS_ShotgunMasterTemplate
{
	Default
	{
		Tag "House Call";
		Weapon.SelectionOrder 1855;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_ShotLoaded4";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Shotgun5 : RS_ShotgunMasterTemplate
{
	Default
	{
		Tag "Landlord";
		Weapon.SelectionOrder 1854;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_ShotLoaded5";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Shotgun6 : RS_ShotgunMasterTemplate
{
	Default
	{
		Tag "Eviction";
		Weapon.SelectionOrder 1853;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_ShotLoaded6";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_SuperShotgun : RS_SuperShotgunMasterTemplate
{
	Default
	{
		Tag "Both Barrels";
		Weapon.SelectionOrder 1848;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_SSGLoaded";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_SuperShotgun2 : RS_SuperShotgunMasterTemplate
{
	Default
	{
		Tag "Double Tap";
		Weapon.SelectionOrder 1847;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "VR_SSGLoaded2";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_SuperShotgun3 : RS_SuperShotgunMasterTemplate
{
	Default
	{
		Tag "No Refunds";
		Weapon.SelectionOrder 1846;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_SSGLoaded3";
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_SuperShotgun4 : RS_SuperShotgunMasterTemplate
{
	Default
	{
		Tag "Final Notice";
		Weapon.SelectionOrder 1845;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "VR_SSGLoaded4";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_SuperShotgun5 : RS_SuperShotgunMasterTemplate
{
	Default
	{
		Tag "Last Word";
		Weapon.SelectionOrder 1844;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_SSGLoaded5";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_SuperShotgun6 : RS_SuperShotgunMasterTemplate
{
	Default
	{
		Tag "Full Stop";
		Weapon.SelectionOrder 1843;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "VR_SSGLoaded6";
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Chaingun : RS_ChaingunMasterTemplate
{
	Default
	{
		Tag "Meat Grinder";
		Weapon.SelectionOrder 1838;
		Weapon.SlotNumber 2;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Chaingun2 : RS_ChaingunMasterTemplate
{
	Default
	{
		Tag "Buzzsaw";
		Weapon.SelectionOrder 1837;
		Weapon.SlotNumber 2;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Chaingun3 : RS_ChaingunMasterTemplate
{
	Default
	{
		Tag "Wood Chipper";
		Weapon.SelectionOrder 1836;
		Weapon.SlotNumber 3;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Chaingun4 : RS_ChaingunMasterTemplate
{
	Default
	{
		Tag "Lawnmower";
		Weapon.SelectionOrder 1835;
		Weapon.SlotNumber 3;
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Chaingun5 : RS_ChaingunMasterTemplate
{
	Default
	{
		Tag "Garbage Disposal";
		Weapon.SelectionOrder 1834;
		Weapon.SlotNumber 4;
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_Chaingun6 : RS_ChaingunMasterTemplate
{
	Default
	{
		Tag "Paper Shredder";
		Weapon.SelectionOrder 1833;
		Weapon.SlotNumber 4;
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_RocketLauncher : RS_RocketLauncherMasterTemplate
{
	Default
	{
		Tag "Iron Fist";
		Weapon.SelectionOrder 1828;
		Weapon.SlotNumber 5;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_RocketLauncher2 : RS_RocketLauncherMasterTemplate
{
	Default
	{
		Tag "Backblast";
		Weapon.SelectionOrder 1827;
		Weapon.SlotNumber 5;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_RocketLauncher3 : RS_RocketLauncherMasterTemplate
{
	Default
	{
		Tag "Overkill";
		Weapon.SelectionOrder 1826;
		Weapon.SlotNumber 5;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_RocketLauncher4 : RS_RocketLauncherMasterTemplate
{
	Default
	{
		Tag "Last Resort";
		Weapon.SelectionOrder 1825;
		Weapon.SlotNumber 5;
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_RocketLauncher5 : RS_RocketLauncherMasterTemplate
{
	Default
	{
		Tag "No Survivors";
		Weapon.SelectionOrder 1824;
		Weapon.SlotNumber 5;
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_RocketLauncher6 : RS_RocketLauncherMasterTemplate
{
	Default
	{
		Tag "Scorched Earth";
		Weapon.SelectionOrder 1823;
		Weapon.SlotNumber 5;
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_PlasmaRifle : RS_PlasmaRifleMasterTemplate
{
	Default
	{
		Tag "Blue Streak";
		Weapon.SelectionOrder 1818;
		Weapon.SlotNumber 6;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_PlasmaRifle2 : RS_PlasmaRifleMasterTemplate
{
	Default
	{
		Tag "Static Shock";
		Weapon.SelectionOrder 1817;
		Weapon.SlotNumber 6;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_PlasmaRifle3 : RS_PlasmaRifleMasterTemplate
{
	Default
	{
		Tag "Short Circuit";
		Weapon.SelectionOrder 1816;
		Weapon.SlotNumber 6;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_PlasmaRifle4 : RS_PlasmaRifleMasterTemplate
{
	Default
	{
		Tag "Live Wire";
		Weapon.SelectionOrder 1815;
		Weapon.SlotNumber 6;
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_PlasmaRifle5 : RS_PlasmaRifleMasterTemplate
{
	Default
	{
		Tag "Ground Fault";
		Weapon.SelectionOrder 1814;
		Weapon.SlotNumber 6;
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_PlasmaRifle6 : RS_PlasmaRifleMasterTemplate
{
	Default
	{
		Tag "Surge Protector";
		Weapon.SelectionOrder 1813;
		Weapon.SlotNumber 6;
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_BFG9000 : RS_BFG9000MasterTemplate
{
	Default
	{
		Tag "The Big One";
		Weapon.SelectionOrder 1808;
		Weapon.SlotNumber 7;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_BFG90002 : RS_BFG9000MasterTemplate
{
	Default
	{
		Tag "The Other Big One";
		Weapon.SelectionOrder 1807;
		Weapon.SlotNumber 7;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_BFG90003 : RS_BFG9000MasterTemplate
{
	Default
	{
		Tag "Last Argument";
		Weapon.SelectionOrder 1806;
		Weapon.SlotNumber 7;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_BFG90004 : RS_BFG9000MasterTemplate
{
	Default
	{
		Tag "Case Closed";
		Weapon.SelectionOrder 1805;
		Weapon.SlotNumber 7;
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_BFG90005 : RS_BFG9000MasterTemplate
{
	Default
	{
		Tag "Final Answer";
		Weapon.SelectionOrder 1804;
		Weapon.SlotNumber 7;
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}

class VR_BFG90006 : RS_BFG9000MasterTemplate
{
	Default
	{
		Tag "The End";
		Weapon.SelectionOrder 1803;
		Weapon.SlotNumber 7;
		+WEAPON.OFFHANDWEAPON;
		+WEAPON.NOHANDSWITCH;
	}
}
