// RS_VP_Pistol -- "Beretta", the Vanilla+ sidearm.
// ---------------------------------------------------------------------
// Real data from the source: dmg 7, 1 bullet, magazine 11 (10 + 1
// chambered), sprites BRTT/BRLD/CHLD/BRTF/PIST. Sound is the source's own
// three-take fire set plus its real reload cues.
//
// Departures from the source, all deliberate:
//   - A_FireBullets replaced with the shared ballistic-projectile path
//     (no hitscan in a VR game). Its two spread pairs become one Accuracy
//     stat plus a per-mode spreadMult -- see RS_VP_Weapon.A_RS_VP_Fire.
//   - A_ZoomFactor screen-zoom and A_WeaponOffset hand choreography
//     dropped -- both are flat-screen effects; in VR your head and
//     controller do that work.
//   - Punch-interrupt (DoPunch/PunchDone) and the dead-gun GRAB animation
//     dropped -- see docs/DIRECTIVE_GNRC_REIMPORT.md section 2.
//
// Restored in this pass (was missing from the first import):
//   - AltFire: the source's real 3-round burst, including its two
//     short-magazine fallbacks.
//   - The two-branch reload. The source distinguishes reloading with a
//     round still chambered (CHLD sprites, tops out at 11) from reloading
//     a completely empty gun (BRLD sprites, slide-lock, tops out at 10).
//     That distinction is the reason Capacity is 11 rather than 10.
//   - PCIN / PSNAP / foley reload cues, all of which were already staged
//     in SNDINFO but called by nothing.
// =====================================================================
class RS_VP_Pistol : RS_VP_Weapon replaces Pistol
{
	Default
	{
		Tag "Beretta";
		Weapon.SelectionOrder 1900;
		Weapon.SlotNumber 2;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 20;
		Weapon.AmmoType1 "Clip";
		Weapon.AmmoType2 "RS_VP_PistolLoaded";
		Weapon.UpSound "rs_vp_pistol_equip";
		Inventory.PickupMessage "You got the Pistol!";
		Inventory.PickupSound "rs_vp_pistol_slide";
		+WEAPON.NOHANDSWITCH;
	}

	// Damage and pellet count are the source's exact values. Accuracy is
	// expressed in this project's own 0-100 scale rather than copying the
	// source's A_FireBullets degree spreads, which use a different unit
	// convention -- a tight sidearm reads high here.
	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 7;
			Accuracy      = 78;
			Velocity      = 8000;
			CritChance    = 0.02;
			Capacity      = 11;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(5, 9 + idx);
			Accuracy      = RS_Roll.RollDouble(72, 84);
			Velocity      = RS_Roll.RollDouble(7000, 9000);
			CritChance    = RS_Roll.RollDouble(0.015, 0.02 + idx * 0.005);
			Capacity      = 11;
		}

		RateOfFire      = 4;
		ReloadSpeed     = 1.0;
		PelletCount     = 1;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = 100.0;

		bStatsRolled = true;
	}

	// Burst rounds are deliberately looser than aimed single fire, matching
	// the source's wider burst spread pair (3.5/2.75 vs 2.25/1.5).
	action void A_RS_VP_PistolBurst()
	{
		A_RS_VP_Fire("rs_vp_pistol_fire", false, "RS_CasingSmall", 1.5);
	}

	override Class<Weapon> GetOffhandClass()
	{
		return "RS_VP_Pistol2";
	}

	States
	{
	Spawn:
		PIST A -1;
		Stop;

	Ready:
		BRTT A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		TNT1 A 0 A_PlaySound("rs_vp_pistol_holster", CHAN_AUTO);
		BRTT A 1 A_Lower;
		Loop;

	Select:
		BRTT A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		BRTT B 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_Fire("rs_vp_pistol_fire", false, "RS_CasingSmall");
		BRTT C 1;
		BRTT D 1;
		BRTT E 1;
		BRTT D 1;
		BRTT B 1;
		BRTT A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	// --- 3-round burst -------------------------------------------------
	// The source guards each stage on remaining magazine: a 1-round mag
	// falls through to ordinary single fire, a 2-round mag skips straight
	// to the final two shots rather than dry-firing the third.
	AltFire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Burst1");
		Goto Reload;

	Burst1:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) == 1, "Shoot");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) == 2, "Burst2");
		BRTT B 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_PistolBurst();
		BRTT C 1;
		BRTT C 1;

	Burst2:
		BRTT B 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_PistolBurst();
		BRTT C 1;
		BRTT C 1;

	Burst3:
		BRTT B 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_PistolBurst();
		BRTT C 1;
		BRTT D 1;
		BRTT E 1;
		BRTT D 1;
		BRTT B 1;
		BRTT A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	// --- Reload --------------------------------------------------------
	// Branches on whether a round is still chambered. Capacity is 11
	// (10 + chamber); the empty-gun branch reloads to 10 via the -1
	// offset, since there's nothing in the chamber to keep.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "ReloadChambered");
		Goto ReloadEmpty;

	// Slide locked back -- no chambered round, so the slide has to be
	// released at the end (PSNAP) before the gun can fire again.
	ReloadEmpty:
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		BRLD S 2;
		BRLD AB 1;
		TNT1 A 0 A_PlaySound("rs_vp_pistol_cout", CHAN_AUTO);
		BRLD CDE 1;
		TNT1 A 0 A_RS_VP_DropMag();
		BRLD E 1;
		BRLD F 3;
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		BRLD G 1;
		TNT1 A 0 A_PlaySound("rs_vp_pistol_cin", CHAN_AUTO);
		BRLD HHHII 1;
		BRLD JJKKKLL 1;
		TNT1 A 0 A_PlaySound("rs_vp_pistol_snap", CHAN_AUTO);
		BRLD M 2 A_RS_ReloadAtomic(-1);
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		BRLD NNOOPQR 1;
		Goto Ready;

	// Round still chambered -- mag swap only, no slide release, and the
	// magazine tops out one higher.
	ReloadChambered:
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		BRLD R 2;
		CHLD AB 1;
		TNT1 A 0 A_PlaySound("rs_vp_pistol_cout", CHAN_AUTO);
		CHLD CMG 1;
		TNT1 A 0 A_RS_VP_DropMag();
		CHLD G 1;
		CHLD F 3;
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		CHLD G 1;
		TNT1 A 0 A_PlaySound("rs_vp_pistol_cin", CHAN_AUTO);
		CHLD HHHII 1;
		CHLD JJKKKLL 1;
		BRLD M 2 A_RS_ReloadAtomic();
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		BRLD NNOOPQR 1;
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		BRTF B 1 Bright A_Light2();
		BRTF A 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_VP_Pistol2 : RS_VP_Pistol
{
	Default
	{
		Tag "Beretta (Off-Hand)";
		Weapon.SelectionOrder 1899;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "RS_VP_PistolLoaded2";
		+WEAPON.OFFHANDWEAPON;
	}
}
