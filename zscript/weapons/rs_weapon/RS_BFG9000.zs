// VR_BFG9000 -- fires real vanilla BFGBall.
// ---------------------------------------------------------------------
// Real frames: BFGG A(20,sound)/B(10,gunflash)/B(10,shoot). Real sound:
// bfgf. Real ammo: Cell, 40 per shot (real, expensive -- matches
// vanilla BFG cost). Semi-auto despite the animation's A_ReFire call --
// +WEAPON.NOAUTOFIRE overrides it in the old file; our release gate
// achieves the same real behavior. Damage is vanilla BFGBall's own
// built-in damage -- not yet tier-scaled (see chat).
// =====================================================================
class VR_BFG9000 : RS_Weapon
{
	Default
	{
		Tag "The Big One";
		Weapon.SelectionOrder 1808;
		Weapon.SlotNumber 7;
		Weapon.AmmoUse 1;
		Weapon.AmmoGive1 40;
		Weapon.AmmoType1 "Cell";
		+WEAPON.NOHANDSWITCH;
	}

	override string GetBaseKeywords()
	{
		return "archetype:bfg trigger:semiauto delivery:heavy payload:single feed:pool reserve:cell element:kinetic set:radiantsilvergun";
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
		Choke             = RS_Roll.RollDouble(0.2 + idx * 0.03, 0.4 + idx * 0.04);
		GunBonaiSockets   = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = RS_Roll.RollDouble(RS_Roll.STARTING_CONDITION_MIN, 100);

		bStatsRolled = true;
	}

	override Class<Actor> GetHeavyProjectile()
	{
		return RS_Catalog.PROJ_BFGBall();
	}

	// Fire: gates on CountInv("Cell") >= 40 -- real vanilla BFG cost, now
	// actually spent (was ammoCost 0, the known infinite-ammo gap).
	// AmmoClass explicit for the same reason as RS_RocketLauncher.zs -- no
	// AmmoType2 on this weapon, so the dispatch's default fallback would
	// be null.
	override void BuildAttackProfiles()
	{
		PrimarySlot.Append(RS_AttackProfile.MakeHeavy(
			fireSnd: RS_Catalog.SND_BFG9000(),
			ammoCost: 40,
			ammo: "Cell",
			profName: "BFG Ball"));
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

	// THE DRY-FIRE RACE, closed 2026-08-07.
	//
	// The gate above checks Cell >= 40, then this state winds up for 30
	// tics before A_RS_FireSlot actually spends anything. On a dual-wield
	// mod the OTHER hand draws from the same Cell pool -- an offhand
	// plasma rifle can empty it below 40 during that windup. FireSlot
	// then refuses, and the player gets the full charge sound, the full
	// flash, the full animation, and no ball.
	//
	// Re-checking on the last frame before the shot costs one jump and
	// turns a silent dud into an honest out-of-ammo. The rotation is
	// untouched either way: FireSlot never advances the cursor on a shot
	// it refuses.
	Shoot:
		BFGG A 20 A_PlaySound("bfgf", CHAN_WEAPON);
		BFGG B 10 A_GunFlash();
		TNT1 A 0 A_JumpIf(CountInv("Cell") < 40, "Fizzle");
		TNT1 A 0 A_RS_FireSlot(0);
		BFGG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	// The other hand drained the pool mid-windup.
	Fizzle:
		TNT1 A 0 A_StartSound("rs_fx_weapon_empty", CHAN_WEAPON);
		BFGG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		BFGF A 11 Bright A_Light1();
		BFGF B 6 Bright A_Light2();
		Stop;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
		Goto Ready;
	}
}

class VR_BFG90002 : VR_BFG9000
{
	Default
	{
		Tag "The Other Big One";
		Weapon.SelectionOrder 1807;
		Weapon.SlotNumber 7;
	}
}

class VR_BFG90003 : VR_BFG9000
{
	Default
	{
		Tag "Last Argument";
		Weapon.SelectionOrder 1806;
		Weapon.SlotNumber 7;
	}
}

class VR_BFG90004 : VR_BFG9000
{
	Default
	{
		Tag "Case Closed";
		Weapon.SelectionOrder 1805;
		Weapon.SlotNumber 7;
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_BFG90005 : VR_BFG9000
{
	Default
	{
		Tag "Final Answer";
		Weapon.SelectionOrder 1804;
		Weapon.SlotNumber 7;
		+WEAPON.OFFHANDWEAPON;
	}
}

class VR_BFG90006 : VR_BFG9000
{
	Default
	{
		Tag "The End";
		Weapon.SelectionOrder 1803;
		Weapon.SlotNumber 7;
		+WEAPON.OFFHANDWEAPON;
	}
}
