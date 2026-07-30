// RS_VP_PlasmaRifle -- "Plasma Rifle", the Vanilla+ plasma gun.
// ---------------------------------------------------------------------
// Real data: magazine 60, full auto, sprites PLZG/PLZA/PLAS.
//
// Fires the vanilla PlasmaBall class, which RS_EnhancedFX transparently
// replaces with RS_EnhancedPlasmaBall -- the enhanced plasma trail comes
// through for free with no per-weapon wiring.
//
// The source's rail-beam alt-fire is deliberately not ported: alt-fires
// get their own dedicated pass, and a rail attack is a different attack
// type rather than a variant of this one.
// =====================================================================
class RS_VP_PlasmaRifle : RS_VP_Weapon
{
	Default
	{
		Tag "Plasma Rifle";
		Weapon.SelectionOrder 100;
		Weapon.SlotNumber 6;
		Weapon.AmmoUse 0;
		Weapon.AmmoGive1 30;
		Weapon.AmmoType1 "Cell";
		Weapon.AmmoType2 "RS_VP_PlasmaLoaded";
		+WEAPON.NOHANDSWITCH;
	}

	override void RollStats(EVR_Tier t)
	{
		Tier = t;

		if (Purist())
		{
			DamagePerShot = 5;
			Accuracy      = 100;
			Velocity      = 25000;
			CritChance    = 0.0;
			Capacity      = 60;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(4, 8 + idx);
			Accuracy      = 100;
			Velocity      = RS_Roll.RollDouble(20000, 28000);
			CritChance    = RS_Roll.RollDouble(0.0, 0.02);
			Capacity      = 60;
		}

		RateOfFire      = 11;
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
		return "RS_EnhancedPlasmaBall";
	}

	action void A_RS_VP_FirePlasma()
	{
		A_RS_FireHeavyProjectile(6);
		A_PlaySound("rs_vp_plasma_fire", CHAN_WEAPON);
		RS_HiFiFX.MuzzleEffects(self, true);
		TakeInventory(invoker.AmmoType2, 1);
		A_RS_MarkFired();
	}

	States
	{
	Spawn:
		PLAS A -1;
		Stop;

	Ready:
		PLZG A 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Loop;

	Deselect:
		PLZG A 1 A_Lower;
		Loop;

	Select:
		PLZG A 1 A_Raise;
		Loop;

	Fire:
		TNT1 A 0 A_JumpIf(!invoker.AutoCooldownReady(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "Shoot");
		Goto Reload;

	Shoot:
		PLZG A 2;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_FirePlasma();
		PLZG B 2;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Cell") <= 0, "OutOfAmmo");
		TNT1 A 0 A_PlaySound("rs_vp_plasma_cout", CHAN_AUTO);
		PLZG A 4;
		TNT1 A 0 A_RS_VP_DropMag();
		PLZG A 4;
		PLZG A 4 A_RS_VP_MagLoad();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		PLZA D 1 Bright A_Light2();
		PLZA A 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("AKEMPT", CHAN_AUTO);
		Goto Ready;
	}
}

class RS_VP_PlasmaRifle2 : RS_VP_PlasmaRifle
{
	Default
	{
		Tag "Plasma Rifle (Off-Hand)";
		Weapon.SelectionOrder 99;
		Weapon.SlotNumber 6;
		Weapon.AmmoType2 "RS_VP_PlasmaLoaded2";
		+WEAPON.OFFHANDWEAPON;
	}
}
