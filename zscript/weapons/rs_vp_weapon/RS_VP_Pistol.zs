// RS_VP_Pistol -- "Beretta", the Vanilla+ sidearm.
// ---------------------------------------------------------------------
// Real data from the source: dmg 7, 1 bullet, magazine 11 (10 + 1
// chambered), sprites BRTT/BRLD/BRTF/PIST. Sound is the HQ vanilla
// pistol -- that pack is exactly the right fit for this set.
//
// Departures from the source, all deliberate:
//   - A_FireBullets replaced with the shared ballistic-projectile path
//     (no hitscan in a VR game).
//   - A_ZoomFactor screen-zoom and A_WeaponOffset hand choreography
//     dropped -- both are flat-screen effects; in VR your head and
//     controller do that work.
//   - Burst alt-fire dropped for now; alt-fires get their own pass.
//   - Reload simplified to the shared A_RS_VP_MagLoad -- the source's
//     two-branch chamber-check depended on ACS scripts not ported here.
// =====================================================================
class RS_VP_Pistol : RS_VP_Weapon
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
		BRTT B 1;
		BRTT A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("rs_vp_pistol_cout", CHAN_AUTO);
		BRLD ABCDE 2;
		TNT1 A 0 A_RS_VP_DropMag();
		BRLD FG 2;
		BRLD HIJKL 2;
		BRLD M 2;
		BRLD NOPQR 2 A_RS_VP_MagLoad();
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
