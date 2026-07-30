// RS_VP_ARifle -- "Assault Rifle", the Vanilla+ set's bonus 10th weapon.
// ---------------------------------------------------------------------
// The one weapon in the source with no `replaces` -- an addition rather
// than a classic-Doom replacement, and distinct from the main arsenal's
// own RS_Rifle. Real data: dmg 7, magazine 31 (30 + 1 chambered), full
// auto, sprites ASLT/RIFG/RFLF/RIFL.
//
// The source draws reserve from its own custom "RifleAmmo" pickup class.
// That's not ported (it would need its own world pickup actor), so this
// uses vanilla Clip -- the honest Vanilla+ choice rather than inventing
// a new ammo economy.
// =====================================================================
class RS_VP_ARifle : RS_VP_Weapon
{
	Default
	{
		Tag "Assault Rifle";
		Weapon.SelectionOrder 2500;
		Weapon.SlotNumber 2;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 30;
		Weapon.AmmoType1 "Clip";
		Weapon.AmmoType2 "RS_VP_ARifleLoaded";
		+WEAPON.NOHANDSWITCH;
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 7;
			Accuracy      = 82;
			Velocity      = 9000;
			CritChance    = 0.02;
			Capacity      = 31;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(5, 9 + idx);
			Accuracy      = RS_Roll.RollDouble(76, 88);
			Velocity      = RS_Roll.RollDouble(8000, 10000);
			CritChance    = RS_Roll.RollDouble(0.015, 0.02 + idx * 0.005);
			Capacity      = 31;
		}

		RateOfFire      = 10;
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
		RIFL A -1;
		Stop;

	Ready:
		ASLT A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		ASLT A 1 A_Lower;
		Loop;

	Select:
		ASLT A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		ASLT B 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_Fire("rs_vp_arifle_fire", true, "RS_CasingRifle");
		ASLT C 1;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("rs_vp_arifle_cout", CHAN_AUTO);
		ASLR ABCD 2;
		TNT1 A 0 A_RS_VP_DropMag();
		ASLR GHIJ 2;
		ASLR KLMN 2 A_RS_VP_MagLoad();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		RFLF B 1 Bright A_Light2();
		RFLF A 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_VP_ARifle2 : RS_VP_ARifle
{
	Default
	{
		Tag "Assault Rifle (Off-Hand)";
		Weapon.SelectionOrder 2499;
		Weapon.SlotNumber 2;
		Weapon.AmmoType2 "RS_VP_ARifleLoaded2";
		+WEAPON.OFFHANDWEAPON;
	}
}
