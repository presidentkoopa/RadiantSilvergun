// RS_VP_RocketLauncher -- "Rocket Launcher", the Vanilla+ RL.
// ---------------------------------------------------------------------
// Real data: magazine 5, sprites LNCH/LNFI/LODE/LAWN. The source has no
// dedicated flash sprite (its Flash state is bare TNT1 + A_Light), so
// this keeps that and just adds the shared dynamic muzzle light.
//
// Fires the vanilla Rocket class, which RS_EnhancedFX transparently
// replaces with RS_EnhancedRocket -- so the enhanced trail/debris comes
// through here for free, no per-weapon wiring.
//
// No alt-fire: the source's grenade mode is explicitly out of scope --
// see docs/DIRECTIVE_GNRC_REIMPORT.md section 2.
//
// Restored in this pass:
//   - The LNFI bright fire frames (the launcher visibly flares and the
//     tube cycles) and the real recoil/cycle timing, in place of two
//     static LNCH frames.
//   - The full LODE reload: tube open, spent pack ejected as a physical
//     RS_MagDrop, fresh rockets in, tube cycled shut -- with the
//     rs_vp_rocket_cin/cycle cues that were staged but never called.
// =====================================================================
class RS_VP_RocketLauncher : RS_VP_Weapon replaces RocketLauncher
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
		Weapon.UpSound "rs_vp_rocket_equip";
		Inventory.PickupMessage "You got the Rocket Launcher!";
		Inventory.PickupSound "rs_vp_rocket_pickup";
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

	override Class<Weapon> GetOffhandClass()
	{
		return "RS_VP_RocketLauncher2";
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
		TNT1 A 0 A_PlaySound("rs_vp_rocket_deselect", CHAN_AUTO);
		LNCH A 1 A_Lower;
		Loop;

	Select:
		LNCH A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	// LNFI is the bright firing sequence; LNCH A/B are the idle and
	// recoiled tube. The launcher cycles a fresh rocket at the end, which
	// is what rs_vp_rocket_cycle is for.
	Shoot:
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_FireRocket();
		LNFI A 1 Bright;
		LNFI A 1 Bright;
		LNFI B 1 Bright;
		LNFI C 1 Bright;
		LNFI D 1 Bright;
		LNCH B 1;
		LNCH B 1;
		LNCH A 1;
		LNCH A 1;
		TNT1 A 0 A_PlaySound("rs_vp_rocket_cycle", CHAN_BODY);
		LNFI E 1;
		LNFI F 1;
		LNFI G 1;
		LNCH AA 1;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	// --- Reload --------------------------------------------------------
	// Break the tube open, drop the spent pack, feed fresh rockets, cycle
	// it shut. The spent pack is a real physical drop, same as every
	// other magazine in the set.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("RocketAmmo") <= 0, "OutOfAmmo");
		TNT1 A 0 A_ClearReFire();
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		LODE ABCDE 2;
		TNT1 A 0 A_PlaySound("rs_vp_rocket_cout", CHAN_AUTO);
		TNT1 A 0 A_RS_VP_DropMag();
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		LODE FGHIJKLMN 2;
		LODE OPQ 2 A_RS_ReloadAtomic();
		TNT1 A 0 A_PlaySound("rs_vp_rocket_cin", CHAN_AUTO);
		LODE RST 2;
		TNT1 A 0 A_PlaySound("rs_vp_rocket_cycle", CHAN_BODY);
		LNCH A 2;
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		TNT1 A 1 Bright A_Light2();
		TNT1 A 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
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
