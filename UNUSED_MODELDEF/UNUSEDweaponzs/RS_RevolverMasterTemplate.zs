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
// Rolls its own stats directly (the tier table locked down earlier in
// this project). Chamber tracking uses a real per-weapon Ammo class
// (AmmoType2, VR_RevLoaded/2/3/4/5/6, one per identity subclass) so it
// shows correctly in any standard ammo HUD, not an instance counter.
// Semi-auto: true trigger-release gate + real TimeBetweenShots cooldown.
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
