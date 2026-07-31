// RS_VP_BFG9000 -- "BFG", the Vanilla+ big gun.
// ---------------------------------------------------------------------
// Real data: magazine 160, 40 per shot, sprites
// LBFG/BFGN/BFGO/BFGE/BFGR/BFGX/BFGY/BFUG.
//
// Fires the vanilla BFGBall class, which RS_EnhancedFX transparently
// replaces with RS_EnhancedBFGBall -- the enhanced BFG trail comes
// through for free with no per-weapon wiring.
//
// No alt-fire: the source has none for this weapon.
//
// Restored in this pass:
//   - The real CHARGE-UP. The BFG doesn't just fire: it spins up over
//     roughly a second and a half with its own three-stage audio
//     (charge / overcharge / pre-fire) before the ball leaves. That wind-up
//     is the weapon's entire risk-reward, and it was previously an
//     11-tic pause with one sound.
//   - Physical recoil on discharge, and the long BFGN recovery.
//   - The full BFGO/BFGE/BFGR reload -- casing open, cell pack ejected,
//     fresh pack, casing shut -- with the bfg_opn/cls cues that were
//     staged in SNDINFO and called by nothing.
// =====================================================================
class RS_VP_BFG9000 : RS_VP_Weapon replaces BFG9000
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
		Weapon.UpSound "rs_vp_bfg_up";
		Inventory.PickupMessage "You got the BFG 9000! Hell yes!";
		Inventory.PickupSound "rs_vp_bfg_pickup";
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
		A_AlertMonsters();
		A_Recoil(7.5);
		A_RS_MarkFired();
	}

	override Class<Weapon> GetOffhandClass()
	{
		return "RS_VP_BFG90002";
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
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= 40, "Charge");
		Goto Reload;

	// --- Charge-up -----------------------------------------------------
	// ~1.5s of spin-up before anything leaves the barrel. Three audio
	// stages layered over a shaking LBFG B: charge, overcharge, then the
	// pre-fire tone that tells you it's about to let go.
	Charge:
		TNT1 A 0 A_PlaySound("rs_vp_bfg_charge", CHAN_AUTO);
		TNT1 A 0 A_PlaySound("rs_vp_bfg_overcharge", CHAN_7);
		LBFG BBBBB 1;
		LBFG BBBBB 1;
		TNT1 A 0 A_PlaySound("rs_vp_bfg_prefire", CHAN_AUTO);
		LBFG BBBBB 1;
		LBFG BBBBB 1;
		LBFG BB 1;
		Goto Shoot;

	Shoot:
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_FireBFG();
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		BFGN A 1;
		LBFG A 1;
		LBFG A 1;
		LBFG A 1;
		LBFG A 21;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	// --- Reload --------------------------------------------------------
	// Crack the casing open, eject the spent cell pack, seat a fresh one,
	// close it up.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Cell") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("rs_vp_bfg_opn", CHAN_BODY);
		BFGO FEDCBA 1;
		TNT1 A 0 A_PlaySound("rs_vp_bfg_cout", CHAN_AUTO);
		BFGE ABCDEFG 1;
		TNT1 A 0 A_RS_VP_DropMag();
		BFGO A 5;
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		BFGR ABCDEFG 1;
		BFGR H 4 A_RS_ReloadAtomic();
		BFGR IJKLM 2;
		TNT1 A 0 A_PlaySound("rs_vp_bfg_cls", CHAN_BODY);
		BFGO ABCDEF 1;
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		BFGX HGFE 1 Bright A_Light2();
		BFGX DCBA 1 Bright A_Light1();
		TNT1 A 0 A_Light0();
		BFGY ABCDE 1 Bright;
		BFGY FGHIJKL 1;
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
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
