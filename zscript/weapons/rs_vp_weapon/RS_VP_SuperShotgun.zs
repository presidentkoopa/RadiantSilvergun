// RS_VP_SuperShotgun -- "Double-Barrel Shotgun", the Vanilla+ SSG.
// ---------------------------------------------------------------------
// Real data: dmg 6, 20 pellets, magazine 2 (both barrels), sprites
// PKS2/DBLF/DBBL. Fires both barrels together and consumes 2 rounds,
// same as the source and same as the main arsenal's own SSG.
// Break-action reload uses the HQ vanilla open/load/close trio.
// =====================================================================
class RS_VP_SuperShotgun : RS_VP_Weapon
{
	Default
	{
		Tag "Double-Barrel Shotgun";
		Weapon.SelectionOrder 400;
		Weapon.SlotNumber 3;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 6;
		Weapon.AmmoType1 "Shell";
		Weapon.AmmoType2 "RS_VP_SuperShotgunLoaded";
		+WEAPON.NOHANDSWITCH;
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 6;
			Accuracy      = 45;
			Velocity      = 6500;
			CritChance    = 0.015;
			Capacity      = 2;
			PelletCount   = 20;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(4, 8 + idx);
			Accuracy      = RS_Roll.RollDouble(40, 55);
			Velocity      = RS_Roll.RollDouble(6000, 7500);
			CritChance    = RS_Roll.RollDouble(0.01, 0.02 + idx * 0.005);
			Capacity      = 2;
			PelletCount   = 20;
		}

		RateOfFire      = 1;
		ReloadSpeed     = 1.0;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = 100.0;

		bStatsRolled = true;
	}

	// Both barrels at once: 2 rounds consumed per trigger pull, so this
	// takes an extra round beyond the shared fire path's single one.
	action void A_RS_VP_FireBothBarrels()
	{
		A_RS_VP_Fire("rs_vp_ssg_fire", false, "RS_CasingShell");
		TakeInventory(invoker.AmmoType2, 1);
	}

	States
	{
	Spawn:
		DBBL A -1;
		Stop;

	// PKS2's real frame range is G-T only -- there are no A-F frames in
	// this sprite set. T is the idle pose; G-L is the fire cycle; M-S plus
	// the SH2R trio cover the break-action reload.
	Ready:
		PKS2 T 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		PKS2 T 1 A_Lower;
		Loop;

	Select:
		PKS2 T 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= 2, "Shoot");
		Goto Reload;

	Shoot:
		PKS2 G 2;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_FireBothBarrels();
		PKS2 HI 2;
		PKS2 JK 3;
		PKS2 L 3;
		PKS2 T 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Shell") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("rs_vp_ssg_opn", CHAN_BODY);
		PKS2 M 3;
		PKS2 NOPQ 3;
		TNT1 A 0 A_PlaySound("rs_vp_ssg_load", CHAN_AUTO);
		SH2R ABC 3;
		TNT1 A 0 A_PlaySound("rs_vp_ssg_cls", CHAN_BODY);
		PKS2 RS 3 A_RS_VP_MagLoad();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		DBLF A 1 Bright A_Light2();
		DBLF B 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_VP_SuperShotgun2 : RS_VP_SuperShotgun
{
	Default
	{
		Tag "Double-Barrel Shotgun (Off-Hand)";
		Weapon.SelectionOrder 399;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "RS_VP_SuperShotgunLoaded2";
		+WEAPON.OFFHANDWEAPON;
	}
}
