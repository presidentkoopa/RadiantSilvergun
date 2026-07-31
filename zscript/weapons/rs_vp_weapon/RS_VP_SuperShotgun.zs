// RS_VP_SuperShotgun -- "Double-Barrel Shotgun", the Vanilla+ SSG.
// ---------------------------------------------------------------------
// Real data: magazine 2, sprites PKS2/SHT3/DBRL/SH2R/DBLF/LFTF/RHTF/DBBL.
//
// Restored in this pass -- this weapon has TWO real firing modes, and the
// first import only had one of them:
//   - Fire      = ONE barrel, 1 round, 9 pellets (the source's
//                 FireLedSSGLeft/Right, alternating by which barrel is
//                 still loaded, each with its own muzzle flash sprite).
//   - AltFire   = BOTH barrels, 2 rounds, 20 pellets, wider cone, real
//                 recoil kick (the source's FireLedSSG "kapow").
// Firing one barrel at a time is the entire tactical point of a
// double-barrel: two separate shots or one huge one, player's choice.
//
// Reload is the source's real break-action: crack open, both hulls (or
// one) eject, reload, snap shut -- with a shorter single-shell variant
// when only one barrel was spent.
// =====================================================================
class RS_VP_SuperShotgun : RS_VP_Weapon replaces SuperShotgun
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
		Weapon.UpSound "rs_vp_ssg_cls";
		Inventory.PickupMessage "You got the Double-Barrel Shotgun!";
		Inventory.PickupSound "rs_vp_ssg_opn";
		+WEAPON.NOHANDSWITCH;
	}

	// PelletCount here is the SINGLE-barrel value (the source's 9). The
	// both-barrels alt-fire doubles it at the call site rather than
	// storing a second stat, so tier rolls and GunBonsai only ever have
	// one pellet number to reason about.
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
			PelletCount   = 9;
		}
		else
		{
			int idx = int(t >= VRT_Basic ? t : VRT_Basic);
			DamagePerShot = RS_Roll.RollInt(4, 8 + idx);
			Accuracy      = RS_Roll.RollDouble(40, 55);
			Velocity      = RS_Roll.RollDouble(6000, 7500);
			CritChance    = RS_Roll.RollDouble(0.01, 0.02 + idx * 0.005);
			Capacity      = 2;
			PelletCount   = 9;
		}

		RateOfFire      = 1;
		ReloadSpeed     = 1.0;
		Choke           = 0;
		GunBonaiSockets = RS_Roll.SocketsForTier(t);

		if (!bStatsRolled)
			Condition = 100.0;

		bStatsRolled = true;
	}

	// One barrel: 1 round, the weapon's baseline 9 pellets.
	action void A_RS_VP_FireOneBarrel()
	{
		A_RS_VP_Fire("rs_vp_ssg_single", false, "");
	}

	// Both barrels: 2 rounds and roughly double the pellets in a wider
	// cone, plus real physical recoil -- the source backed this shot with
	// A_Recoil and a quake, and it's the reason to spend both shells.
	// PelletCount is temporarily doubled around the shared fire call so
	// the volley itself is built by the same code path as everything else.
	action void A_RS_VP_FireBothBarrels()
	{
		int basePellets = invoker.PelletCount;
		invoker.PelletCount = basePellets * 2;
		A_RS_VP_Fire("rs_vp_ssg_fire", false, "", 1.4);
		invoker.PelletCount = basePellets;

		TakeInventory(invoker.AmmoType2, 1);
		A_Recoil(0.35);
		A_QuakeEx(2, 2, 2, 12, 0, 96, "none");
	}

	override Class<Weapon> GetOffhandClass()
	{
		return "RS_VP_SuperShotgun2";
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
		TNT1 A 0 A_PlaySound("rs_vp_ssg_opn", CHAN_AUTO);
		PKS2 T 1 A_Lower;
		Loop;

	Select:
		PKS2 T 1 A_Raise;
		Loop;

	// --- Single barrel (primary) ---------------------------------------
	// Two loaded barrels fire the right one first, then the left, each
	// with its own flash sprite -- the source tracked which barrel was
	// spent purely by remaining magazine count, and so does this.
	Fire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= 2, "ShootRight");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) == 1, "ShootLeft");
		Goto Reload;

	ShootRight:
		SHT3 A 1;
		TNT1 A 0 A_GunFlash("RightFlash");
		TNT1 A 0 A_RS_VP_FireOneBarrel();
		Goto ShootRecover;

	ShootLeft:
		SHT3 A 1;
		TNT1 A 0 A_GunFlash("LeftFlash");
		TNT1 A 0 A_RS_VP_FireOneBarrel();
		Goto ShootRecover;

	ShootRecover:
		SHT3 A 1;
		SHT3 A 1;
		SHT3 A 1;
		PKS2 T 1;
		PKS2 T 1;
		PKS2 T 1;
		PKS2 T 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	// --- Both barrels (alt-fire) ---------------------------------------
	// Needs both chambers loaded; with only one it falls through to the
	// ordinary single shot rather than wasting the trigger pull.
	AltFire:
		TNT1 A 0 A_JumpIf(!invoker.CanFireSemiAuto(), "Ready");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= 2, "ShootDouble");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) == 1, "ShootLeft");
		Goto Reload;

	ShootDouble:
		PKS2 T 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_FireBothBarrels();
		SHT3 A 1;
		SHT3 A 1;
		SHT3 A 1;
		PKS2 T 1;
		PKS2 T 1;
		PKS2 T 1;
		PKS2 T 1;
		PKS2 T 1;
		PKS2 T 1 A_WeaponReady(WRF_ALLOWRELOAD);
		Goto Ready;

	// --- Break-action reload -------------------------------------------
	// Both barrels spent gets the full crack-open with two hulls ejected;
	// a single spent barrel gets the source's shorter one-shell variant.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Shell") <= 0, "OutOfAmmo");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) == 1, "ReloadSingle");
		Goto ReloadDouble;

	ReloadDouble:
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		DBRL ABC 1;
		DBRL D 2;
		DBRL E 2;
		DBRL F 3;
		DBRL G 3 A_PlaySound("rs_vp_ssg_opn", CHAN_BODY);
		TNT1 A 0 A_RS_VP_EjectCasing("RS_CasingShell", -6.0, -4.0);
		TNT1 A 0 A_RS_VP_EjectCasing("RS_CasingShell", -2.0, -2.0);
		PKS2 GHI 2;
		PKS2 JK 2;
		Goto ReloadFinish;

	ReloadSingle:
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		PKS2 SS 1;
		DBRL AAAAA 1;
		SHT2 D 4 A_PlaySound("rs_vp_ssg_opn", CHAN_BODY);
		TNT1 A 0 A_RS_VP_EjectCasing("RS_CasingShell", -2.0, -2.0);
		PKS2 G 2;
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		SH2R ABC 2;
		Goto ReloadFinish;

	ReloadFinish:
		PKS2 L 4 A_PlaySound("rs_vp_ssg_load", CHAN_AUTO);
		PKS2 M 2 A_RS_ReloadAtomic();
		PKS2 NOPQ 2;
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		PKS2 R 3 A_PlaySound("rs_vp_ssg_cls", CHAN_BODY);
		PKS2 S 3;
		PKS2 T 1 A_ReFire();
		Goto Ready;

	Flash:
		TNT1 A 0 A_RS_MuzzleFlash();
		DBLF A 1 Bright A_Light2();
		DBLF B 1 Bright A_Light1();
		Goto LightDone;

	LeftFlash:
		TNT1 A 0 A_RS_MuzzleFlash();
		LFTF B 1 Bright A_Light2();
		LFTF A 1 Bright A_Light1();
		Goto LightDone;

	RightFlash:
		TNT1 A 0 A_RS_MuzzleFlash();
		RHTF B 1 Bright A_Light2();
		RHTF A 1 Bright A_Light1();
		Goto LightDone;

	OutOfAmmo:
		TNT1 A 0 A_PlaySound("rs_fx_weapon_empty", CHAN_AUTO);
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
