// RS_VP_RocketLauncher -- "Rocket Launcher", the Vanilla+ RL.
// ---------------------------------------------------------------------
// Real data: magazine 5, sprites LNCH/LAWN. The source has no dedicated
// flash sprite (its Flash state is bare TNT1 + A_Light), so this keeps
// that and just adds the shared dynamic muzzle light.
//
// Fires the vanilla Rocket class, which RS_EnhancedFX transparently
// replaces with RS_EnhancedRocket -- so the enhanced trail/debris comes
// through here for free, no per-weapon wiring.
// =====================================================================
class RS_VP_RocketLauncher : RS_VP_Weapon
{
	Default
	{
		Tag "Rocket Launcher";
		Weapon.SelectionOrder 2500;
		Weapon.SlotNumber 5;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 5;
		Weapon.AmmoType1 "RocketAmmo";
		Weapon.AmmoType2 "RS_VP_RocketLoaded";
		+WEAPON.NOHANDSWITCH;
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 20;
			Accuracy      = 100;
			Velocity      = 6400;
			CritChance    = 0.0;
			Capacity      = 5;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(16, 26 + idx);
			Accuracy      = 100;
			Velocity      = RS_Roll.RollDouble(6000, 7500);
			CritChance    = RS_Roll.RollDouble(0.0, 0.02);
			Capacity      = 5;
		}

		RateOfFire      = 2;
		ReloadSpeed     = 1.0;
		PelletCount     = 1;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = 100.0;

		bStatsRolled = true;
	}

	override Class<Actor> GetHeavyProjectile()
	{
		return "RS_EnhancedRocket";
	}

	action void A_RS_VP_FireRocket()
	{
		A_RS_FireHeavyProjectile(7);
		A_PlaySound("rs_vp_rocket_fire", CHAN_WEAPON);
		RS_HiFiFX.MuzzleEffects(self, true);
		TakeInventory(invoker.AmmoType2, 1);
		A_RS_MarkFired();
	}

	States
	{
	Spawn:
		LAWN A -1;
		Stop;

	Ready:
		LNCH A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		LNCH A 1 A_Lower;
		Loop;

	Select:
		LNCH A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	// LNCH has only A and B frames in this sprite set -- A idle, B fired.
	Shoot:
		LNCH B 3;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_FireRocket();
		LNCH B 4;
		LNCH A 4;
		LNCH A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("RocketAmmo") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("rs_vp_rocket_cout", CHAN_AUTO);
		LNCH A 4;
		TNT1 A 0 A_RS_VP_DropMag();
		LNCH A 4;
		LNCH A 4 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		TNT1 A 1 Bright A_Light2();
		TNT1 A 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_VP_RocketLauncher2 : RS_VP_RocketLauncher
{
	Default
	{
		Tag "Rocket Launcher (Off-Hand)";
		Weapon.SelectionOrder 2498;
		Weapon.SlotNumber 5;
		Weapon.AmmoType2 "RS_VP_RocketLoaded2";
		+WEAPON.OFFHANDWEAPON;
	}
}
