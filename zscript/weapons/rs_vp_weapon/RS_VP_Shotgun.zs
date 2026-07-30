// RS_VP_Shotgun -- "Riot Shotgun", the Vanilla+ pump shotgun.
// ---------------------------------------------------------------------
// Real data: dmg 6, 7 pellets, magazine 8, sprites RIOT/RGSW/BOOF/RIOB.
// Sounds are the HQ vanilla shotgun + shotgun-cock pair.
// =====================================================================
class RS_VP_Shotgun : RS_VP_Weapon
{
	Default
	{
		Tag "Riot Shotgun";
		Weapon.SelectionOrder 1300;
		Weapon.SlotNumber 3;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 8;
		Weapon.AmmoType1 "Shell";
		Weapon.AmmoType2 "RS_VP_ShotgunLoaded";
		+WEAPON.NOHANDSWITCH;
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 6;
			Accuracy      = 60;
			Velocity      = 7000;
			CritChance    = 0.015;
			Capacity      = 8;
			PelletCount   = 7;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(4, 8 + idx);
			Accuracy      = RS_Roll.RollDouble(55, 68);
			Velocity      = RS_Roll.RollDouble(6500, 8000);
			CritChance    = RS_Roll.RollDouble(0.01, 0.02 + idx * 0.005);
			Capacity      = 8;
			PelletCount   = 7;
		}

		RateOfFire      = 2;
		ReloadSpeed     = 1.0;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = 100.0;

		bStatsRolled = true;
	}

	States
	{
	Spawn:
		RIOB A -1;
		Stop;

	Ready:
		RIOT A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		TNT1 A 0 A_RS_ClearTriggerGate();
		Loop;

	Deselect:
		RIOT A 1 A_Lower;
		Loop;

	Select:
		RIOT A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		RIOT B 2;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_Fire("rs_vp_shotgun_fire", false, "RS_CasingShell");
		RIOT C 2;
		RIOT D 3 A_PlaySound("rs_vp_shotgun_pump", CHAN_BODY);
		RIOT E 3;
		RIOT A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Shell") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("rs_vp_shotgun_load", CHAN_AUTO);
		RGSW ABC 2;
		RGSW DEF 2 A_PlaySound("rs_vp_shotgun_pump", CHAN_BODY);
		RGSW ABC 2 A_RS_ReloadAtomic();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		BOOF B 1 Bright A_Light2();
		BOOF A 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_VP_Shotgun2 : RS_VP_Shotgun
{
	Default
	{
		Tag "Riot Shotgun (Off-Hand)";
		Weapon.SelectionOrder 1299;
		Weapon.SlotNumber 3;
		Weapon.AmmoType2 "RS_VP_ShotgunLoaded2";
		+WEAPON.OFFHANDWEAPON;
	}
}
