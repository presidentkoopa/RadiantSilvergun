// RS_VP_Chaingun -- "Minigun", the Vanilla+ chaingun.
// ---------------------------------------------------------------------
// Real data: dmg 5, 1 bullet, magazine 150, sprites VLCN/CHAF/MNIG.
// Sound is the HQ vanilla pistol -- the same reuse real vanilla Doom
// does (A_FireCGun plays sfx_pistol; the Chaingun has no distinct fire
// sound of its own), matching how the main arsenal's Chaingun is wired.
//
// The source draws reserve from its own custom "Nato" pickup class,
// which isn't ported -- vanilla Clip instead, same reasoning as ARifle.
// =====================================================================
class RS_VP_Chaingun : RS_VP_Weapon
{
	Default
	{
		Tag "Minigun";
		Weapon.SelectionOrder 4000;
		Weapon.SlotNumber 4;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 50;
		Weapon.AmmoType1 "Clip";
		Weapon.AmmoType2 "RS_VP_ChaingunLoaded";
		+WEAPON.NOHANDSWITCH;
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 5;
			Accuracy      = 58;
			Velocity      = 8000;
			CritChance    = 0.01;
			Capacity      = 150;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(4, 7 + idx);
			Accuracy      = RS_Roll.RollDouble(52, 66);
			Velocity      = RS_Roll.RollDouble(7000, 9000);
			CritChance    = RS_Roll.RollDouble(0.008, 0.015 + idx * 0.004);
			Capacity      = 150;
		}

		RateOfFire      = 14;
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
		MNIG A -1;
		Stop;

	Ready:
		VLCN A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		VLCN A 1 A_Lower;
		Loop;

	Select:
		VLCN A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		VLCN B 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_Fire("rs_vp_minigun_fire", true, "RS_CasingRifle");
		VLCN C 1;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("rs_vp_minigun_reload", CHAN_AUTO);
		VLCN ABCD 3;
		TNT1 A 0 A_RS_VP_DropMag();
		VLCN ABCD 3;
		VLCN A 3 A_RS_VP_MagLoad();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		CHAF A 1 Bright A_Light2();
		CHAF B 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_VP_Chaingun2 : RS_VP_Chaingun
{
	Default
	{
		Tag "Minigun (Off-Hand)";
		Weapon.SelectionOrder 3999;
		Weapon.SlotNumber 4;
		Weapon.AmmoType2 "RS_VP_ChaingunLoaded2";
		+WEAPON.OFFHANDWEAPON;
	}
}
