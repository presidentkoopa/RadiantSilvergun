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
//
// No alt-fire: the source's was aim-down-sights, which this project does
// not port -- in VR your head and hands do that. See
// docs/DIRECTIVE_GNRC_REIMPORT.md section 2.
//
// Restored in this pass: the real two-branch reload (chambered vs empty,
// 31 vs 30), the full ASLR/ASRL charging-handle animation, and the
// RCIN/RSLAP/RCLCK/foley cues that were staged in SNDINFO but called by
// nothing.
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
		Weapon.UpSound "rs_vp_arifle_equip";
		Inventory.PickupMessage "You got the Assault Rifle!";
		Inventory.PickupSound "rs_vp_arifle_pickup";
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

	// This weapon carries no `replaces`, but it still reaches the floor:
	// RS_VP_Chaingun.PostBeginPlay can substitute one into the world in
	// place of a Chaingun. So it needs the same off-hand morph as every
	// other pickup in the set -- without this, walking over a second
	// substituted rifle silently gives ammo instead of arming the off
	// hand, and the weapon would be the only one in the set that can't
	// be dual-wielded from world pickups.
	override Class<Weapon> GetOffhandClass()
	{
		return "RS_VP_ARifle2";
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
		TNT1 A 0 A_PlaySound("rs_vp_arifle_deselect", CHAN_AUTO);
		TNT1 A 0 A_PlaySound("rs_vp_arifle_foley", CHAN_AUTO);
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
		ASLT A 1;
		TNT1 A 0 A_GunFlash();
		TNT1 A 0 A_RS_VP_Fire("rs_vp_arifle_fire", true, "RS_CasingRifle");
		ASLT A 1;
		ASLT D 1;
		ASLT B 1;
		TNT1 A 0 A_ReFire();
		Goto Ready;

	// --- Reload --------------------------------------------------------
	// Two branches, same shape as the Pistol: a rifle with a round still
	// chambered swaps the magazine only and tops out at 31, while a
	// completely empty one has to run the charging handle (ASRL) and tops
	// out at 30 via the -1 offset.
	Reload:
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) >= invoker.Capacity, "Ready");
		TNT1 A 0 A_JumpIf(CountInv("Clip") <= 0, "OutOfAmmo");
		TNT1 A 0 A_JumpIf(CountInv(invoker.AmmoType2) > 0, "ReloadChambered");
		Goto ReloadEmpty;

	// Bolt locked back: mag swap, then the charging handle cycle (ASRL)
	// with its own click, before the rifle is live again.
	ReloadEmpty:
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		ASLR ABCDMN 1;
		ASLR L 1;
		TNT1 A 0 A_PlaySound("rs_vp_arifle_cout", CHAN_AUTO);
		ASLR KJI 1;
		ASLR G 1;
		TNT1 A 0 A_RS_VP_DropMag();
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		ASLR G 7;
		ASLR HIJK 1;
		TNT1 A 0 A_PlaySound("rs_vp_arifle_cin", CHAN_AUTO);
		ASLR L 1;
		ASLR N 2;
		ASLR N 3;
		ASLR N 1;
		ASLR O 1 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		ASLR PQR 1;
		TNT1 A 0 A_PlaySound("rs_vp_arifle_slap", CHAN_AUTO);
		ASLR S 1;
		ASRL AB 1;
		ASRL C 4;
		TNT1 A 0 A_PlaySound("rs_vp_arifle_click", CHAN_AUTO);
		ASRL D 1;
		ASRL E 6 A_RS_ReloadAtomic(-1);
		ASRL D 1;
		ASRL C 3;
		TNT1 A 0 A_PlaySound("rs_vp_arifle_foley", CHAN_AUTO);
		ASRL BA 3;
		ASLR TU 1;
		Goto Ready;

	// Round still chambered: magazine swap only, no charging handle.
	ReloadChambered:
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		ASLR ABCDMN 1;
		ASLR L 1;
		TNT1 A 0 A_PlaySound("rs_vp_arifle_cout", CHAN_AUTO);
		ASLR KJI 1;
		ASLR G 4;
		TNT1 A 0 A_RS_VP_DropMag();
		TNT1 A 0 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		ASLR G 4;
		ASLR HIJK 1;
		TNT1 A 0 A_PlaySound("rs_vp_arifle_cin", CHAN_AUTO);
		ASLR L 1;
		ASLR N 2;
		ASLR N 3;
		ASLR N 1;
		ASLR O 1 A_PlaySound("rs_fx_foley", CHAN_AUTO);
		ASLR PQR 1;
		TNT1 A 0 A_PlaySound("rs_vp_arifle_slap", CHAN_AUTO);
		ASLR S 1 A_RS_ReloadAtomic();
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
