// RS_VP_BFG9000 -- "BFG", the Vanilla+ big gun.
// ---------------------------------------------------------------------
// Real data: magazine 160, 40 per shot, sprites LBFG/BFGX/BFUG.
//
// Fires the vanilla BFGBall class, which RS_EnhancedFX transparently
// replaces with RS_EnhancedBFGBall -- the enhanced BFG trail comes
// through for free with no per-weapon wiring.
// =====================================================================
class RS_VP_BFG9000 : RS_VP_Weapon
{
	Default
	{
		Tag "BFG";
		Weapon.SelectionOrder 2000;
		Weapon.SlotNumber 7;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 40;
		Weapon.AmmoType1 "Cell";
		Weapon.AmmoType2 "RS_VP_BFGLoaded";
		+WEAPON.NOHANDSWITCH;
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 100;
			Accuracy      = 100;
			Velocity      = 25000;
			CritChance    = 0.0;
			Capacity      = 160;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(80, 140 + idx * 5);
			Accuracy      = 100;
			Velocity      = RS_Roll.RollDouble(20000, 28000);
			CritChance    = RS_Roll.RollDouble(0.0, 0.02);
			Capacity      = 160;
		}

		RateOfFire      = 1;
		ReloadSpeed     = 1.0;
		PelletCount     = 1;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = 100.0;

		bStatsRolled = true;
	}

	// 40 rounds per shot, matching the source's AmmoUse 40.
	override Class<Actor> GetHeavyProjectile()
	{
		return "RS_EnhancedBFGBall";
	}

	action void A_RS_VP_FireBFG()
	{
		A_RS_FireHeavyProjectile(1);
		A_PlaySound("rs_vp_bfg_fire", CHAN_WEAPON);
		RS_HiFiFX.MuzzleEffects(self, true);
		TakeInventory(invoker.AmmoType2, 40);
		A_RS_MarkFired();
	}

	States
	{
	Spawn:
		BFUG A -1;
		Stop;

	Ready:
		LBFG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		LBFG A 1 A_Lower;
		Loop;

	Select:
		LBFG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= 40, "Shoot");
		Goto Reload;

	Shoot:
		LBFG A 11;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_FireBFG();
		LBFG B 6;
		LBFG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Cell") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("rs_vp_bfg_cout", CHAN_AUTO);
		LBFG A 5;
		TNT1 A 0 A_RS_VP_DropMag();
		LBFG A 5;
		LBFG A 5 A_RS_VP_MagLoad();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		BFGX H 1 Bright A_Light2();
		BFGX G 1 Bright A_Light2();
		BFGX F 1 Bright A_Light1();
		BFGX E 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_VP_BFG90002 : RS_VP_BFG9000
{
	Default
	{
		Tag "BFG (Off-Hand)";
		Weapon.SelectionOrder 1999;
		Weapon.SlotNumber 7;
		Weapon.AmmoType2 "RS_VP_BFGLoaded2";
		+WEAPON.OFFHANDWEAPON;
	}
}
